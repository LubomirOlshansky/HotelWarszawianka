"""road_progress.py: how much of the map's streets the road design system has rebuilt, by area.

The rollout plan (docs/design/road-design-rollout.md) splits the map into areas listed in
docs/plan/road-areas.json: the hand-designed core areas first, then a 500 m grid for everything else.
This measures every street (all OSM road kinds but `service`) in metres of ribbon, assigns each
metre to the first area whose box holds it, and counts a metre done where a design in docs/roads/
covers it (the designed asphalt's footprint, as road_design.py builds it on the map's roads; the
design does not have to be applied to the map). It prints a table and writes an HTML page: the map
with every area coloured by status and its % done, and the list.

Usage:
  python3 -I tools/road_progress.py [--map game/map/centrum.json] [--out build/road_progress.html] [--json]
"""
import html
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import road_design as rd  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
AREAS = os.path.join(ROOT, "docs", "plan", "road-areas.json")
SKIP = ("service",)
MAIN = ("trunk", "primary", "secondary", "tertiary")   # the main streets; the rest are local
STEP = 2.0          # m between the samples along each road
STATUS_COL = {"done": "#2f9e44", "in progress": "#f08c00", "next": "#1c7ed6", "planned": "#adb5bd"}


def opt(argv, name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default


def samples(road):
    pts = rd.pts_of(road["p"])
    out = []
    for a, b in zip(pts, pts[1:]):
        L = math.dist(a, b)
        n = max(1, int(L // STEP))
        for k in range(n):
            out.append((rd.lerp(a, b, (k + 0.5) / n), L / n))
    return out


def grid_areas(plan, roads):
    """The grid cells that hold any street, outside the core boxes, nearest the centre first."""
    g = float(plan.get("grid", 500))
    cx, cz = plan.get("centre", [0, 0])
    cells = set()
    for r in roads:
        for (x, z), _ in samples(r):
            cells.add((int(math.floor(x / g)), int(math.floor(z / g))))
    out = []
    for (i, j) in sorted(cells, key=lambda c: math.hypot((c[0] + 0.5) * g - cx, (c[1] + 0.5) * g - cz)):
        out.append({"id": "g%d_%d" % (i, j), "name": "Grid %d,%d" % (i, j), "status": "planned",
                    "tier": "C", "box": [i * g, j * g, (i + 1) * g, (j + 1) * g]})
    return out


def designed_footprints(roads):
    fps = []
    for f in sorted(os.listdir(rd.SPECS)):
        if not f.endswith(".json"):
            continue
        spec = rd.load_spec(f[:-5])
        if "streets" not in spec:
            continue
        d = rd.Design(spec, roads).build()
        fps.append((f[:-5], rd.Footprint(d.footprint, 0.3)))
    return fps


def measure(plan, roads):
    core = plan["areas"]
    areas = core + grid_areas(plan, roads)
    for a in areas:
        a["total"] = a["done"] = a["main"] = a["main_done"] = 0.0
    fps = designed_footprints(roads)
    for r in roads:
        for (x, z), w in samples(r):
            a = next((a for a in areas if a["box"][0] <= x < a["box"][2] and a["box"][1] <= z < a["box"][3]), None)
            if a is None:
                continue
            hit = any(fp.has(x, z) for _, fp in fps)
            main = r.get("k", "").replace("_link", "") in MAIN
            a["total"] += w
            a["done"] += w if hit else 0.0
            if main:
                a["main"] += w
                a["main_done"] += w if hit else 0.0
    areas = [a for a in areas if a["total"] > 0]
    return areas, [n for n, _ in fps]


def page(areas, specs, total, done):
    xs = [v for a in areas for v in (a["box"][0], a["box"][2])]
    zs = [v for a in areas for v in (a["box"][1], a["box"][3])]
    X0, X1, Z0, Z1 = min(xs), max(xs), min(zs), max(zs)
    W = 900.0
    sc = W / (X1 - X0)
    H = (Z1 - Z0) * sc

    def P(x, z):
        return "%.1f,%.1f" % ((x - X0) * sc, (z - Z0) * sc)

    rects = []
    for a in areas:
        x0, z0, x1, z1 = a["box"]
        pct = 100.0 * a["done"] / a["total"]
        col = STATUS_COL.get(a["status"], "#adb5bd")
        op = 0.18 + 0.6 * pct / 100.0 if a["status"] != "planned" else 0.08
        rects.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="%.2f" '
                     'stroke="%s" stroke-width="%s"><title>%s: %s, %.0f%% of %.1f km</title></rect>' % (
                         (x0 - X0) * sc, (z0 - Z0) * sc, (x1 - x0) * sc, (z1 - z0) * sc, col, op, col,
                         "2" if a.get("tier") != "C" else "0.5", html.escape(a["name"]), a["status"], pct,
                         a["total"] / 1000.0))
        if a.get("tier") != "C":
            rects.append('<text x="%.1f" y="%.1f" class="lbl">%s</text>' % (
                (x0 - X0) * sc + 3, (z0 - Z0) * sc + 12, html.escape(a.get("short", a["id"]))))
    rows = []
    for a in areas:
        if a.get("tier") == "C" and a["done"] == 0:
            continue
        pct = 100.0 * a["done"] / a["total"]
        mp = 100.0 * a["main_done"] / max(a["main"], 1.0)
        rows.append("<tr><td>%s</td><td>%s</td><td><span class=\"st\" style=\"background:%s\">%s</span></td>"
                    "<td class=\"n\">%.1f km</td><td><div class=\"bar\"><i style=\"width:%.0f%%\"></i></div>"
                    "<span class=\"n\">%.0f%%</span></td><td class=\"n\">%.0f%%</td></tr>" % (
                        html.escape(a.get("short", a["id"])), html.escape(a["name"]),
                        STATUS_COL.get(a["status"], "#adb5bd"), a["status"], a["total"] / 1000.0, mp, mp, pct))
    grid = [a for a in areas if a.get("tier") == "C"]
    gt = sum(a["total"] for a in grid)
    gd = sum(a["done"] for a in grid)
    gtm = sum(a["main"] for a in grid)
    gm = sum(a["main_done"] for a in grid)
    rows.append("<tr><td>C</td><td>The rest of the map: %d grid cells of 500 m</td><td><span class=\"st\" "
                "style=\"background:#adb5bd\">planned</span></td><td class=\"n\">%.1f km</td><td><div class=\"bar\">"
                "<i style=\"width:%.0f%%\"></i></div><span class=\"n\">%.0f%%</span></td><td class=\"n\">%.0f%%</td></tr>" % (
                    len(grid), gt / 1000.0, 100 * gm / max(gtm, 1), 100 * gm / max(gtm, 1), 100 * gd / max(gt, 1)))
    core = [a for a in areas if a.get("tier") == "A"]
    ct = sum(a["main"] for a in core)
    cd = sum(a["main_done"] for a in core)
    mt = sum(a["main"] for a in areas)
    md = sum(a["main_done"] for a in areas)
    return """<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Road rebuild progress</title><style>
:root{--bg:#f8f9fa;--fg:#212529;--mut:#868e96;--card:#fff;--line:#dee2e6}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#16181b;--fg:#e9ecef;--mut:#909296;--card:#1f2226;--line:#33373c}}
:root[data-theme=dark]{--bg:#16181b;--fg:#e9ecef;--mut:#909296;--card:#1f2226;--line:#33373c}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif}
.wrap{max-width:960px;margin:0 auto;padding:20px 16px}
h1{font-size:26px;margin:0 0 4px}.sub{color:var(--mut);margin:0 0 18px}
.facts{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin-bottom:18px}
.fact{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:10px 12px}
.fact b{display:block;font-size:24px}.fact span{color:var(--mut);font-size:13px}
.map{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px;overflow:hidden}
svg{width:100%%;height:auto;display:block}.lbl{font:bold 11px system-ui;fill:var(--fg)}
table{width:100%%;border-collapse:collapse;margin-top:18px;background:var(--card);border-radius:10px;overflow:hidden}
th{text-align:left;font-size:12px;color:var(--mut);padding:7px 8px}td{padding:7px 8px;border-top:1px solid var(--line);vertical-align:middle}.n{font-variant-numeric:tabular-nums;white-space:nowrap}
.st{color:#fff;border-radius:6px;padding:1px 7px;font-size:12px;white-space:nowrap}
.bar{display:inline-block;width:90px;height:8px;background:var(--line);border-radius:4px;margin-right:6px;vertical-align:middle}
.bar i{display:block;height:100%%;background:#2f9e44;border-radius:4px}
.legend span{margin-right:12px;font-size:13px;color:var(--mut)}.legend i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:4px}
@media (max-width:600px){td:nth-child(2){display:none}}
</style></head><body><div class="wrap">
<h1>Road rebuild progress</h1>
<p class="sub">Every street on the map (OSM roads except service ways), in metres of ribbon. Done means a design in docs/roads/ covers it. Specs: %s.</p>
<div class="facts"><div class="fact"><b>%.1f%%</b><span>of the map's main streets</span></div>
<div class="fact"><b>%.1f%%</b><span>of all its streets (%.1f of %.0f km)</span></div>
<div class="fact"><b>%.0f%%</b><span>of the core's main streets</span></div>
<div class="fact"><b>%d / %d</b><span>core areas done</span></div></div>
<div class="map"><svg viewBox="0 0 %.0f %.0f" role="img" aria-label="Map of the rollout areas">%s%s</svg></div>
<p class="legend"><span><i style="background:#2f9e44"></i>done</span><span><i style="background:#f08c00"></i>in progress</span><span><i style="background:#1c7ed6"></i>next</span><span><i style="background:#adb5bd"></i>planned</span></p>
<table><tr><th></th><th>Area</th><th>Status</th><th class="n">Streets</th><th>Main streets</th><th class="n">All</th></tr>%s</table>
<p class="sub">Main streets: trunk, primary, secondary and tertiary roads. Local streets (residential, living streets) are done area by area after the main streets, with the seed tool. A metre counts for the first area whose box holds it.</p></div></body></html>""" % (
        html.escape(", ".join(specs) or "none"), 100.0 * md / max(mt, 1), 100.0 * done / total, done / 1000.0, total / 1000.0,
        100.0 * cd / max(ct, 1), sum(1 for a in core if a["status"] == "done"), len(core), W, H,
        "".join(STREETS), "".join(rects), "".join(rows))


STREETS = []


def main(argv):
    m = json.load(open(opt(argv, "--map", rd.MAP), encoding="utf-8"))
    plan = json.load(open(AREAS, encoding="utf-8"))
    roads = [r for r in m["roads"] if r.get("k") not in SKIP and not r.get("dk")]
    areas, specs = measure(plan, roads)
    total = sum(a["total"] for a in areas)
    done = sum(a["done"] for a in areas)
    if "--json" in argv:
        print(json.dumps({"total_m": round(total), "done_m": round(done),
                          "areas": [{k: (round(v) if isinstance(v, float) else v) for k, v in a.items()}
                                    for a in areas if a.get("tier") != "C" or a["done"] > 0]}, ensure_ascii=False))
        return 0
    for a in areas:
        if a.get("tier") != "C" or a["done"] > 0:
            print("%-6s %-44s %-12s %6.1f km  main %5.1f%%  all %5.1f%%" % (
                a.get("short", a["id"]), a["name"][:44], a["status"], a["total"] / 1000.0,
                100.0 * a["main_done"] / max(a["main"], 1.0), 100.0 * a["done"] / a["total"]))
    mt = sum(a["main"] for a in areas)
    md = sum(a["main_done"] for a in areas)
    print("road_progress: main streets %.1f%%, all streets %.1f of %.1f km (%.1f%%), %d areas" % (
        100.0 * md / max(mt, 1), done / 1000.0, total / 1000.0, 100.0 * done / total, len(areas)))
    xs = [a["box"][0] for a in areas] + [a["box"][2] for a in areas]
    zs = [a["box"][1] for a in areas] + [a["box"][3] for a in areas]
    X0, Z0, sc = min(xs), min(zs), 900.0 / (max(xs) - min(xs))
    for r in roads:
        q = rd.pts_of(r["p"])
        w = 1.4 if r.get("k") in ("primary", "secondary", "trunk") else 0.7
        STREETS.append('<polyline points="%s" fill="none" stroke="currentColor" stroke-opacity="0.45" '
                       'stroke-width="%.1f"/>' % (" ".join("%.1f,%.1f" % ((x - X0) * sc, (z - Z0) * sc) for x, z in q), w))
    out = opt(argv, "--out", os.path.join(ROOT, "build", "road_progress.html"))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        f.write(page(areas, specs, total, done))
    print("road_progress: wrote %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
