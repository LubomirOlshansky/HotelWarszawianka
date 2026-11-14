"""Road objects census: every solid thing the car can hit, measured against the lane graph.
    python3 -I tools/road_objects.py [MAP.json] [--json=OUT] [--top=N] [--street=NAME] [--no-service]

Stage 1 of the road-objects pipeline (docs/design/road-objects.md section 3). Reads the finished
map data (default game/map/centrum.json) and the baked prop files in game/data (street_details,
monuments, park_details), so it runs in the cloud with no map pack and no Godot.

For every object class that ends up solid in the game (map_builder.gd `_wall_faces`,
street_details/monuments/park_details SOLID boxes) it samples the object every metre and measures
the gap from the nearest lane's edge (lane centre +- lw/2, ground lanes for ground objects, the
same deck's lanes for deck objects). Bands:
    lane    inside a lane (should be none: bake_structures.clear_carriageways cuts them)
    edge    0-1.0 m past a lane's edge (a car on the lane's outer half touches it)
    kerb    1.0-3.0 m (the kerb and the first metre of pavement: corner cuts, swerves)
    walk    3.0-6.0 m (the pavement the player drives on)
plus `jn`: the sample is within JUNCTION m of a junction node (3+ roads), where turning cars cut
across the corner. Objects past 6 m are counted as off-road.

Prints one table per class and the streets with the most edge+kerb metres; --json writes every
object within 3 m (id, class, kind, x, z, band, gap, street, junction) as the work list for stage 2
(classification). Deterministic. Standard library only.

The service ways (the city objects plan, step 3; docs/design/drivable-city-build.md item 1): 45 % of
the drawn road length is `roads` of kind `service` (yards, car parks, back lanes) that the lane graph
leaves out, so nothing along them was measured. A second pass (`Ways`) measures the same solids
against those ways' edges (the centre line +- w/2) in the same bands, printed after the lane tables
and apart from them, so the lane numbers stay comparable; --json adds them as "service_items".
--no-service skips it. `oid` names an object the same way for tools/drive_report.py's join.
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CELL = 12.0
REACH = 6.0
JUNCTION = 14.0
BANDS = (("lane", 0.0), ("edge", 1.0), ("kerb", 3.0), ("walk", REACH))
# Solid half sizes, from the game scripts (keep in step): street_details.gd, monuments.gd, park_details.gd.
SD_SOLID = {"kiosk": (1.45, 1.1), "stall": (1.2, 0.9), "cart": (0.9, 0.6)}
MON_SOLID = {"statue": (1.2, 1.2), "bust": (0.4, 0.4), "allegory": (0.5, 0.5), "stone": (0.6, 0.4),
             "stele": (0.55, 0.25), "obelisk": (0.9, 0.9), "cross": (0.6, 0.6), "sculpture": (0.7, 0.7)}
PARK_SOLID = {"statue": (0.8, 0.8), "fountain": (3.0, 3.0), "carousel": (2.5, 2.5), "playground": (3.2, 2.8),
              "gazebo": (2.2, 2.2), "sundial": (0.55, 0.55), "ropecourse": (6.0, 4.0)}
SOLID_PLATFORM = 0.5   # map_builder.gd


def pairs(f):
    return list(zip(f[0::2], f[1::2]))


def offset_line(pts, off):
    out = []
    for i in range(len(pts)):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        d = math.dist(a, b)
        out.append(pts[i] if d < 1e-6 else (pts[i][0] - (b[1] - a[1]) / d * off, pts[i][1] + (b[0] - a[0]) / d * off))
    return out


def sample(pts, step=1.0):
    out = []
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.dist(a, b) / step))
        out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(n)]
    if pts:
        out.append(pts[-1])
    return out


def seg_dist(x, z, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    l2 = abx * abx + abz * abz
    t = 0.0 if l2 < 1e-12 else min(max(((x - a[0]) * abx + (z - a[1]) * abz) / l2, 0.0), 1.0)
    return math.hypot(x - a[0] - abx * t, z - a[1] - abz * t)


def box(x, z, yaw, hx, hz):
    """The outline of a box of half sizes (hx, hz) turned by yaw (Basis(UP, yaw))."""
    c, s = math.cos(yaw), math.sin(yaw)
    return [(x + px * c + pz * s, z - px * s + pz * c) for px, pz in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz), (-hx, -hz))]


class Lanes:
    def __init__(self, d):
        self.cells = defaultdict(list)
        g = d["graph"]
        nodes = pairs(g["nodes"])
        deg = defaultdict(set)
        for e in g["edges"]:
            deg[e["a"]].add(e["b"])
            deg[e["b"]].add(e["a"])
        self.junctions = defaultdict(list)
        for i, n in enumerate(nodes):
            if len(deg[i]) >= 3:   # three or more neighbours: a junction
                self.junctions[(math.floor(n[0] / CELL), math.floor(n[1] / CELL))].append(n)
        for e in g["edges"]:
            level = "t" if e.get("tn") is not None else (e.get("dk") if e.get("dk") is not None else "g")
            pts = pairs(e["p"])
            for k in range(e["n"]):
                q = offset_line(pts, e["o"] + e["lw"] * k)
                for a, b in zip(q, q[1:]):
                    item = (a, b, e["lw"] * 0.5, level, e["name"] or "(unnamed " + e["k"] + ")", e["k"])
                    for i in range(math.floor((min(a[0], b[0]) - REACH) / CELL), math.floor((max(a[0], b[0]) + REACH) / CELL) + 1):
                        for j in range(math.floor((min(a[1], b[1]) - REACH) / CELL), math.floor((max(a[1], b[1]) + REACH) / CELL) + 1):
                            self.cells[(i, j)].append(item)

    def gap(self, x, z, level="g"):
        """(gap from the nearest lane's edge, its street, its class) or (inf, '', '')."""
        best = (math.inf, "", "")
        for a, b, half, lv, name, k in self.cells.get((math.floor(x / CELL), math.floor(z / CELL)), ()):
            if lv != level:
                continue
            g = seg_dist(x, z, a, b) - half
            if g < best[0]:
                best = (g, name, k)
        return best

    def at_junction(self, x, z):
        ci, cj = math.floor(x / CELL), math.floor(z / CELL)
        for i in (ci - 1, ci, ci + 1):
            for j in (cj - 1, cj, cj + 1):
                for n in self.junctions.get((i, j), ()):
                    if math.hypot(x - n[0], z - n[1]) < JUNCTION:
                        return True
        return False


class Ways:
    """The drawn service ways (`roads` of kind service, not bridges) as edges +- w/2, in cells."""

    def __init__(self, d):
        self.cells = defaultdict(list)
        self.length = 0.0
        for r in d.get("roads", []):
            if r.get("k") != "service" or r.get("bridge"):
                continue
            pts = pairs(r["p"])
            name = r.get("name") or "(unnamed service)"
            for a, b in zip(pts, pts[1:]):
                self.length += math.dist(a, b)
                item = (a, b, float(r["w"]) * 0.5, name)
                for i in range(math.floor((min(a[0], b[0]) - REACH) / CELL), math.floor((max(a[0], b[0]) + REACH) / CELL) + 1):
                    for j in range(math.floor((min(a[1], b[1]) - REACH) / CELL), math.floor((max(a[1], b[1]) + REACH) / CELL) + 1):
                        self.cells[(i, j)].append(item)

    def gap(self, x, z, level="g"):
        """(gap from the nearest service way's edge, its name, "service") or (inf, '', '')."""
        best = (math.inf, "", "")
        if level != "g":
            return best
        for a, b, half, name in self.cells.get((math.floor(x / CELL), math.floor(z / CELL)), ()):
            g = seg_dist(x, z, a, b) - half
            if g < best[0]:
                best = (g, name, "service")
        return best

    def at_junction(self, x, z):
        return False


def oid(cls, kind, pts):
    """An object's name for joins (tools/drive_report.py): its class, kind and first point."""
    return f"{cls}:{kind}@{pts[0][0]:.1f},{pts[0][1]:.1f}"


def census(d, lanes, only=""):
    """Every object measured against `lanes` (Lanes or Ways): per class, per street, the rows."""
    per_class = defaultdict(lambda: Counter())
    per_street = defaultdict(lambda: Counter())
    rows = []
    for cls, kind, pts, level in objects(d, os.path.join(ROOT, "game", "data")):
        best = (math.inf, "", "")
        metres = Counter()
        jn = False
        for x, z in sample(pts, 1.0):
            g = lanes.gap(x, z, level)
            b = band_of(g[0])
            metres[b] += 1
            if g[0] < best[0]:
                best = g + ((x, z),)
            if b in ("edge", "kerb") and not jn:
                jn = lanes.at_junction(x, z)
        if only and best[1] != only:
            continue
        b = band_of(best[0])
        c = per_class[cls]
        c["n"] += 1
        c["n_" + b] += 1
        for k, v in metres.items():
            c["m_" + k] += v
        if b in ("lane", "edge", "kerb"):
            per_street[best[1]][cls] += metres["lane"] + metres["edge"] + metres["kerb"]
            if jn:
                c["n_jn"] += 1
            x, z = best[3]
            rows.append({"id": oid(cls, kind, pts), "cls": cls, "kind": kind, "x": round(x, 1), "z": round(z, 1), "band": b,
                         "gap": round(best[0], 2), "street": best[1], "road": best[2], "jn": int(jn),
                         "m": metres["lane"] + metres["edge"] + metres["kerb"]})
    return per_class, per_street, rows


def report(per_class, per_street, rows, top, what="lane"):
    head = "in-lane   " if what == "lane" else "on-way    "
    print(f"class           objects  {head}edge(<1m)  kerb(1-3m)  walk(3-6m)  at-junction   metres edge+kerb")
    for cls in sorted(per_class, key=lambda k: -(per_class[k]["m_edge"] + per_class[k]["m_kerb"])):
        c = per_class[cls]
        print(f"{cls:15s} {c['n']:7d}  {c['n_lane']:7d}  {c['n_edge']:9d}  {c['n_kerb']:10d}  {c['n_walk']:10d}  {c['n_jn']:11d}   {c['m_edge'] + c['m_kerb']:8d}")
    print(f"\n{'streets' if what == 'lane' else 'service ways'} with the most solid metres within 3 m of a {what}'s edge (top {top}):")
    for name, cnt in sorted(per_street.items(), key=lambda kv: -sum(kv[1].values()))[:top]:
        print(f"  {sum(cnt.values()):6d} m  {name:32s} " + ", ".join(f"{k} {v}" for k, v in cnt.most_common(4)))
    kinds = Counter((r["cls"], r["kind"]) for r in rows if r["band"] in ("lane", "edge"))
    print(f"\nkinds within 1 m of a {what}'s edge: " + ", ".join(f"{c}/{k} {n}" for (c, k), n in kinds.most_common(20)))


def band_of(g):
    for name, lim in BANDS:
        if g < lim:
            return name
    return "off"


def objects(d, data_dir):
    """Every solid thing as (class, kind, outline points, level)."""
    for ln in d.get("lines", []):
        if ln["k"] != "platform":
            yield "barrier", ln["k"], pairs(ln["p"]), "g"
    for w in d.get("walls", []):
        yield "struct_wall", w["k"], pairs(w["p"]), "t" if w["k"] == "tunnel" else "g"
    for gr in d.get("guards", []):
        yield "guard_rail", "deck" if gr.get("dk") is not None else "ground", pairs(gr["p"]), gr.get("dk", "g") if gr.get("dk") is not None else "g"
    for p in d.get("decks", {}).get("piers", []):
        (cx, cz), (dx, dz), (sx, sz) = p["c"], p["d"], p["s"]
        yield "pier", p.get("k", "pier"), box(cx, cz, math.atan2(dx, dz), sx * 0.5, sz * 0.5), "g"
    for p in d.get("platforms", []):
        if float(p["h"]) >= SOLID_PLATFORM:
            q = pairs(p["p"])
            yield "platform", "rail", q + q[:1], "g"
    pk = d.get("parked", [])
    for i in range(0, len(pk) - 3, 4):
        yield "parked_car", "car", box(pk[i], pk[i + 1], pk[i + 2], 0.9, 2.1), "g"
    sh = d.get("shelters", [])
    for i in range(0, len(sh) - 2, 3):
        yield "shelter", "shelter", box(sh[i], sh[i + 1], sh[i + 2], 2.0, 0.5), "g"
    for b in d.get("buildings", []):
        if b.get("br") or b.get("cutd") or float(b["mh"]) >= 2.0 or float(b["h"]) <= float(b["mh"]):
            continue
        q = pairs(b["p"])
        area = abs(sum(x0 * z1 - x1 * z0 for (x0, z0), (x1, z1) in zip(q, q[1:] + q[:1]))) * 0.5
        kind = b.get("kind") or "yes"
        if kind in ("roof", "steps", "column", "kiosk", "carport", "shed", "service", "toilets", "transformer_tower"):
            cls = "small_building"
        else:
            cls = "small_building" if area < 30.0 else "building"
        yield cls, kind, q + q[:1], "g"
    for fname, solid, cls in (("street_details.json", SD_SOLID, "street_prop"), ("monuments.json", MON_SOLID, "monument"),
                              ("park_details.json", PARK_SOLID, "park_piece")):
        path = os.path.join(data_dir, fname)
        if not os.path.exists(path):
            continue
        for it in json.load(open(path, encoding="utf-8"))["items"]:
            if it[0] in solid:
                hx, hz = solid[it[0]]
                yield cls, it[0], box(it[1], it[2], it[3], hx, hz), "g"


def main():
    args = sys.argv[1:]
    path = next((a for a in args if not a.startswith("--")), os.path.join(ROOT, "game", "map", "centrum.json"))
    out_json = next((a.split("=", 1)[1] for a in args if a.startswith("--json=")), "")
    top = int(next((a.split("=", 1)[1] for a in args if a.startswith("--top=")), "25"))
    only = next((a.split("=", 1)[1] for a in args if a.startswith("--street=")), "")
    d = json.load(open(path, encoding="utf-8"))
    per_class, per_street, rows = census(d, Lanes(d), only)
    report(per_class, per_street, rows, top)
    srows = []
    if "--no-service" not in args:
        ways = Ways(d)
        s_class, s_street, srows = census(d, ways, only)
        print(f"\n--- service ways ({ways.length / 1000:.0f} km drawn, not in the lane graph): the same solids against their edges ---")
        report(s_class, s_street, srows, top, "service")
        print(f"service ways: {sum(1 for r in srows if r['band'] in ('lane', 'edge'))} objects within 1 m of a service way's edge, "
              f"{sum(1 for r in srows if r['band'] == 'lane')} on the way itself")
    if out_json:
        rows.sort(key=lambda r: (r["gap"], r["x"], r["z"]))
        srows.sort(key=lambda r: (r["gap"], r["x"], r["z"]))
        with open(out_json, "w", encoding="utf-8") as f:
            json.dump({"_about": "tools/road_objects.py: solid objects within 3 m of a lane's edge (items) and of a service way's (service_items)",
                       "items": rows, "service_items": srows}, f, ensure_ascii=False, indent=0)
        print(f"\nwrote {len(rows)} rows and {len(srows)} service-way rows to {out_json}")


if __name__ == "__main__":
    main()
