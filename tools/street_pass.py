"""Operation Unslop: the street pass. Measures one street's road surface, markings, trees and objects,
writes its record (the score the dev console shows), and fails when a swept street gets worse.

    python3 -I tools/street_pass.py --street=SLUG [--write] [--evidence] [--map=game/map/centrum.json]
    python3 -I tools/street_pass.py --check          # every street with a record; exit 1 if any got worse
    python3 -I tools/street_pass.py --list           # the streets defined in docs/streets/streets.json
    python3 -I tools/street_pass.py --street=SLUG --dump[=BLOCK]   # the auditor's probe: ways, lines, zebras,
                                                     # objects, findings and their causes, in s/t
    python3 -I tools/street_pass.py --street=SLUG --photos         # one evidence pack: newest photos per block
                                                     # side and CHECK object -> docs/streets/SLUG-photos.md
    python3 -I tools/street_pass.py --street=SLUG --spots          # the street's fixed cameras as one game
                                                     # --spots= argument (same cameras before and after)
    python3 -I tools/street_pass.py --apply          # game/data/road_objects.json from the records

A street is a box in its own frame (`s` metres along the street, `t` metres across it) with blocks
between junctions, the areas other threads own (findings there are listed as "owned", never scored)
and the zones that changed after the map data was drawn ("changed": the finding may be the data's
age, not the game's fault; fresh street photos decide). Definitions: docs/streets/streets.json.
Records: docs/streets/<slug>.json (machine) and docs/streets/<slug>.md (people), written by --write.

The checks (docs/design/operation-unslop.md section 4):
  L1 lane step     two consecutive ways of the street, same direction, whose lane count or width
                   jumps (> 1 lane, or > 1.5 m) where they meet: the "odd lane split"
  L2 loose line    a lane line ending in the middle of a block: no junction, stop line, zebra,
                   continuing line or join where the lane count changes within reach of its end
  L3 line on kerb  a lane, edge or centre line crossing a kerb line
  L4 line thru zebra a lane or centre line painted across a zebra crossing (OSM footway=crossing
                   paths, `paths` kind "zebra"): bake_roads `_crossed` cuts lines at roads only
  K1 edge step     two ways of one carriageway meet and the drawn asphalt edge jumps sideways
                   (> 0.3 m): no taper (tools/road_smooth.py tapers them over 20-30 m)
  K2 line jog      a lane, centre, edge or cycle line ends where another of its kind starts just
                   ahead, 0.3-3.6 m aside (road_smooth stitches them with an S-curve)
  T1 tree on road  a scanned tree's trunk on the drawn carriageway (area or visible road strip)
  P1 prop on road  a lamp, bin, bench, rack, column or shelter on the drawn carriageway
  O1 solid at lane a solid (barrier, parked car, shelter, building...) within 1 m of a lane's edge
                   (tools/road_objects.py's census)
Score per block: 100 minus the weighted open findings (WEIGHTS), never below 0.
--apply writes game/data/road_objects.json (the barriers whose verdict changes how they are drawn:
REMOVE, or RETEXTURE / REPLACE with a style) from every record; map_builder.gd reads it.
A street's `decisions` ({id: [verdict, style, why]}) are hand calls from evidence; they win over
the rules ("F: ..." for F's own calls).
--check is a ratchet: a check's open count may never grow over the record's. --evidence adds the
newest street-level photo date per block (Mapillary, needs MAPILLARY_TOKEN; network) to the record.
Standard library only.
"""
import datetime
import json
import math
import os
import sys
from collections import Counter, defaultdict

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import road_objects as RO  # noqa: E402  (the lanes, the solids census)
import road_smooth as RS  # noqa: E402  (the edge steps and line jogs)

DEFS = os.path.join(ROOT, "docs", "streets", "streets.json")
OUT_DIR = os.path.join(ROOT, "docs", "streets")
WEIGHTS = {"L1": 3, "L2": 1, "L3": 2, "L4": 2, "T1": 3, "P1": 2, "O1": 1, "K1": 3, "K2": 1, "F1": 3}
TITLES = {"L1": "lane step", "L2": "loose lane line", "L3": "line on a kerb", "L4": "line through a zebra", "T1": "tree on the road",
          "P1": "prop on the road", "O1": "solid within 1 m of a lane", "K1": "edge step", "K2": "line jog", "F1": "F's flag (a circled screenshot)"}
# Where each check's findings come from (the street-pass skill's cause map): fix the rule, not the place.
CAUSES = {
    "L1": "tools/bake_roads.py bake_lane_lines: each OSM way painted on its own; lane count or width steps at way joins (RS3 tapers)",
    "L2": "tools/bake_roads.py _paint_along/_crossed: a line cut where nothing explains it (a way end, a hidden strip)",
    "L3": "tools/bake_roads.py bake_kerbs vs bake_lane_lines: the kerb and the paint read different widths (`w`, `c`)",
    "L4": "tools/bake_roads.py _crossed: zebras must cut lane and centre lines (ZEBRA_HALF + ZEBRA_GAP)",
    "T1": "the drawn strip covers a real median or pavement (map_builder _build_roads `w`/`c`, carriage areas), rarely a bad tree",
    "P1": "tools/bake_osm.py snap_props / street_details: a prop not snapped clear of the drawn road",
    "O1": "a solid barrier near a lane: verdict by classify() B-rules, style or REMOVE via --apply (road_objects.json)",
    "K1": "tools/road_smooth.py taper_roads/fit_kerbs: a width step at a way join left untapered",
    "K2": "tools/road_smooth.py stitch: a lane line jumping sideways at a way join",
    "F1": "F looked and saw slop the checks don't measure: find the class (a level, a wall, a stub, a behaviour), add a check or a rule for it, then close the flag with `done`",
}
LOOSE_REACH = 2.0      # L2: another line's end this close continues the line
JUNCTION_REACH = 14.0  # L2: a line may end this close to a junction node
STOP_REACH = 5.0       # L2: ...or to a stop line
LANE_JOIN_REACH = 4.0  # L2: ...or to a join where the lane count changes (a lane opens or closes)
ZEBRA_REACH = 5.0      # L2: ...or to a zebra (zebra half 1.8 + gap 0.6 + the stop line and cycle crossing in front of it at signalised crossings)
CELL = 20.0


def pairs(f):
    return [(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]


def seg_dist(p, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    l2 = abx * abx + abz * abz
    t = 0.0 if l2 < 1e-12 else min(max(((p[0] - a[0]) * abx + (p[1] - a[1]) * abz) / l2, 0.0), 1.0)
    return math.hypot(p[0] - a[0] - abx * t, p[1] - a[1] - abz * t), t


def inside(p, poly):
    x, z = p
    c = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi:
            c = not c
        j = i
    return c


def crosses(a, b, c, d):
    def o(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0


class Frame:
    def __init__(self, f):
        self.o, self.s, self.t = f["o"], f["s"], f["t"]

    def st(self, x, z):
        dx, dz = x - self.o[0], z - self.o[1]
        return dx * self.s[0] + dz * self.s[1], dx * self.t[0] + dz * self.t[1]

    def xz(self, s, t):
        return (self.o[0] + self.s[0] * s + self.t[0] * t, self.o[1] + self.s[1] * s + self.t[1] * t)


def in_rect(st, r):
    return r["s"][0] <= st[0] <= r["s"][1] and r["t"][0] <= st[1] <= r["t"][1]


class Surface:
    """The drawn carriageway: mapped areas (`carriage`) and the road strips where no area hides them
    (map_builder.gd _build_roads: the centreline shifted `c` to the right, `w` wide)."""

    def __init__(self, d, near):
        self.areas = []
        for c in d.get("carriage", []):
            poly = pairs(c["p"])
            if c.get("dk") is None and any(near(p) for p in poly[::4]):
                self.areas.append((poly, min(p[0] for p in poly), max(p[0] for p in poly), min(p[1] for p in poly), max(p[1] for p in poly)))
        self.strips = []
        for r in d["roads"]:
            if r.get("bridge") or r.get("dk") is not None:
                continue
            pts = pairs(r["p"])
            if not any(near(p) for p in pts):
                continue
            off = RO.offset_line(pts, float(r.get("c", 0.0))) if r.get("c") else pts
            hide = r.get("hide", [])
            along = 0.0
            for a, b in zip(off, off[1:]):
                L = math.hypot(b[0] - a[0], b[1] - a[1])
                self.strips.append((a, b, r["w"] * 0.5, along, along + L, hide, r.get("name", ""), r["k"]))
                along += L

    def on(self, p):
        for poly, x0, x1, z0, z1 in self.areas:
            if x0 <= p[0] <= x1 and z0 <= p[1] <= z1 and inside(p, poly):
                return "area"
        for a, b, half, s0, s1, hide, name, k in self.strips:
            dist, t = seg_dist(p, a, b)
            if dist < half:
                at = s0 + (s1 - s0) * t
                if not any(h[0] <= at <= h[1] for h in hide):
                    return "strip " + (name or k)
        return ""


def junction_nodes(d):
    g = d["graph"]
    nodes = pairs(g["nodes"])
    deg = defaultdict(set)
    for e in g["edges"]:
        deg[e["a"]].add(e["b"])
        deg[e["b"]].add(e["a"])
    return [nodes[i] for i in deg if len(deg[i]) >= 3]


def measure(d, sd):
    """Every finding of the street: dicts with check, x, z, s, t, block, status, note."""
    fr = Frame(sd["frame"])
    box = {"s": sd["s"], "t": sd["t"]}
    names = set(sd["names"])

    def near(p, pad=8.0):
        s, t = fr.st(*p)
        return box["s"][0] - pad <= s <= box["s"][1] + pad and box["t"][0] - pad <= t <= box["t"][1] + pad

    def here(p):
        return in_rect(fr.st(*p), box)

    out = []

    def add(check, p, note):
        s, t = fr.st(*p)
        out.append({"check": check, "x": round(p[0], 1), "z": round(p[1], 1), "s": round(s, 1), "t": round(t, 1), "note": note})

    # L1: lane steps between consecutive ways of the street, same direction.
    ways = []
    for r in d["roads"]:
        if r.get("name") not in names:
            continue
        pts = pairs(r["p"])
        if not any(here(p) for p in pts):
            continue
        ways.append(r)
    ends = defaultdict(list)
    for r in ways:
        pts = pairs(r["p"])
        ends[(round(pts[0][0], 1), round(pts[0][1], 1))].append(("start", r))
        ends[(round(pts[-1][0], 1), round(pts[-1][1], 1))].append(("end", r))
    lane_joins = []   # where a lane opens or closes: a line may start or end there (L2)
    for key, lst in ends.items():
        ins = [r for kind, r in lst if kind == "end"]
        outs = [r for kind, r in lst if kind == "start"]
        if len(ins) != 1 or len(outs) != 1 or not here(key):
            continue
        a, b = ins[0], outs[0]
        la, lb = int(a.get("lanes") or 0), int(b.get("lanes") or 0)
        if la and lb and la != lb:
            lane_joins.append(key)
        dw = abs(float(a["w"]) - float(b["w"]))
        # The lane lesson (F, 2026-11-05): a lane count change is paint inside a continuous kerb.
        # When road_smooth tapered the drawn width (`wv`) so both ways meet at the same width,
        # the kerb doesn't step here: not a lane step (a lane line may still start, see L2).
        wa, wb = a.get("wv"), b.get("wv")
        if wa and wb and abs(float(wa[-1]) - float(wb[0])) <= 0.5:
            continue
        if (la and lb and abs(la - lb) >= 1) or dw > 1.5:
            add("L1", key, f"{la} -> {lb} lanes, {a['w']:.1f} -> {b['w']:.1f} m wide where two ways meet")

    # K1 + K2 (smooth roads, 2026-11-05): edge steps at the street's joins, line jogs on it.
    named = [r for r in d["roads"] if r.get("name") in names]
    for node, step in RS.edge_steps(named, near=here, every=d["roads"]):
        add("K1", node, f"asphalt edge jumps {step:.1f} m where two ways meet")
    marks = [m for m in d["markings"] if m.get("k") in RS.LINE_KINDS and any(here(p) for p in pairs(m["p"]))]
    for i, last, j, lj, along, side in RS.jogs(marks):
        if abs(side) > RS.STEP_MIN:
            e = pairs(marks[i]["p"])[-1]
            if here(e):
                add("K2", e, f"{marks[i]['k']} line jumps {abs(side):.1f} m sideways")

    # L2 + L3: lane, edge and centre lines.
    lines = [m for m in d["markings"] if m.get("k") in ("lane", "edge", "centre") and any(here(p) for p in pairs(m["p"]))]
    stops = [pairs(m["p"]) for m in d["markings"] if m.get("k") == "stop" and any(near(p, 30) for p in pairs(m["p"]))]
    juncs = [n for n in junction_nodes(d) if near(n, 30)]
    zebras = [pairs(w["p"]) for w in d.get("paths", []) if w.get("k") == "zebra" and any(near(p) for p in pairs(w["p"]))]
    zsegs = [(a, b) for z in zebras for a, b in zip(z, z[1:])]
    endpoints = []
    for i, m in enumerate(lines):
        pts = pairs(m["p"])
        endpoints.append((pts[0], i))
        endpoints.append((pts[-1], i))
    for m_i, m in enumerate(lines):
        if m["k"] != "lane":
            continue
        pts = pairs(m["p"])
        for e in (pts[0], pts[-1]):
            if not here(e):
                continue
            if any(math.hypot(e[0] - n[0], e[1] - n[1]) < JUNCTION_REACH for n in juncs):
                continue
            if any(seg_dist(e, a, b)[0] < STOP_REACH for s in stops for a, b in zip(s, s[1:])):
                continue
            if any(seg_dist(e, a, b)[0] < ZEBRA_REACH for a, b in zsegs):
                continue
            if any(j != m_i and math.hypot(e[0] - q[0], e[1] - q[1]) < LOOSE_REACH for q, j in endpoints):
                continue
            # Smooth roads (2026-11-05): where a lane opens or closes the line between it and its
            # neighbour starts or ends at the join (road_smooth stitches the others across it).
            if any(math.hypot(e[0] - n[0], e[1] - n[1]) < LANE_JOIN_REACH for n in lane_joins):
                continue
            add("L2", e, "lane line ends mid-block")
    kerbs = []
    for k in d["kerbs"]:
        pts = pairs(k["p"])
        for a, b in zip(pts, pts[1:]):
            if near(a) or near(b):
                kerbs.append((a, b))
    grid = defaultdict(list)
    for a, b in kerbs:
        for i in range(math.floor(min(a[0], b[0]) / CELL), math.floor(max(a[0], b[0]) / CELL) + 1):
            for j in range(math.floor(min(a[1], b[1]) / CELL), math.floor(max(a[1], b[1]) / CELL) + 1):
                grid[(i, j)].append((a, b))
    for m in lines:
        pts = pairs(m["p"])
        hit = None
        for a, b in zip(pts, pts[1:]):
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            if not here(mid):
                continue
            for c, e in grid.get((math.floor(mid[0] / CELL), math.floor(mid[1] / CELL)), ()):
                if crosses(a, b, c, e):
                    hit = mid
                    break
            if hit:
                break
        if hit:
            add("L3", hit, f"{m['k']} line crosses a kerb")

    # L4: lane and centre lines through zebras (zsegs from L2 above).
    for m in lines:
        if m["k"] not in ("lane", "centre"):
            continue
        pts = pairs(m["p"])
        hit = None
        for a, b in zip(pts, pts[1:]):
            for c, e in zsegs:
                if crosses(a, b, c, e):
                    mid = ((c[0] + e[0]) / 2, (c[1] + e[1]) / 2)
                    if here(mid):
                        hit = mid
                    break
            if hit:
                break
        if hit:
            add("L4", hit, f"{m['k']} line painted through a zebra")

    # T1 + P1: trees and props on the drawn carriageway.
    surf = Surface(d, near)
    t3 = d.get("trees3d", [])
    for i in range(0, len(t3) - 5, 6):
        p = (t3[i], t3[i + 1])
        if here(p):
            on = surf.on(p)
            if on:
                add("T1", p, f"tree ({t3[i + 2]:.0f} m) on the drawn road ({on})")
    for key, stride in (("lamps", 2), ("bins", 3), ("benches", 3), ("bikes", 3), ("columns", 3), ("shelters", 3)):
        arr = d.get(key, [])
        for i in range(0, len(arr) - stride + 1, stride):
            p = (arr[i], arr[i + 1])
            if here(p):
                on = surf.on(p)
                if on:
                    add("P1", p, f"{key[:-1]} on the drawn road ({on})")

    # O1: solids within 1 m of a lane (the census).
    lanes = RO.Lanes(d)
    data_dir = os.path.join(ROOT, "game", "data")
    for cls, kind, outline, level in RO.objects(d, data_dir):
        if cls in ("platform",) or not any(near(p) for p in outline):
            continue
        best = (math.inf, None)
        for p in RO.sample(outline, 1.0):
            if not here(p):
                continue
            g = lanes.gap(p[0], p[1], level)[0]
            if g < best[0]:
                best = (g, p)
        if best[1] is not None and best[0] < 1.0:
            add("O1", best[1], f"{cls}/{kind} {max(best[0], 0.0):.1f} m from a lane's edge")

    # F1: F's flags (streets.json "flags": a circled screenshot turned into a place and a "should be").
    # They stay open, and cost the score, until the street's definition marks them `done`.
    for fl in sd.get("flags", []):
        if not fl.get("done"):
            add("F1", (fl["x"], fl["z"]), f"{fl['id']}: {fl['what']} -> should: {fl['should']}")

    # Blocks, owned areas, changed zones.
    for f in out:
        st = (f["s"], f["t"])
        f["block"] = next((b["id"] for b in sd["blocks"] if b["s"][0] <= st[0] < b["s"][1]), "-")
        owned = next((o for o in sd.get("owned", []) if in_rect(st, o)), None)
        changed = next((c for c in sd.get("changed", []) if in_rect(st, c)), None)
        f["status"] = "owned" if owned else ("changed" if changed else "open")
        if owned:
            f["note"] += f" [owned by: {owned['by']}]"
        elif changed:
            f["note"] += f" [changed since the data: {changed['what']}]"
    out.sort(key=lambda f: (f["block"], f["check"], f["s"]))
    return out


# The match step (F, 2026-11-05): every classified object gets the library model that draws it
# (tools/model_library.py, docs/models/library.json), or a wanted id when the game has none yet.
MODEL_FOR = {("B1", "guard_rail"): "barrier:guard_rail", ("B13", "shelter"): "instanced:shelter",
             ("B5", "*"): "balustrade", ("B2", "*"): "tram_railing", ("B2b", "*"): "tram_railing", ("B6", "*"): "canopy_posts",
             ("B3", "*"): "yard_gate", ("*", "parked_car"): "instanced:parked", ("B9", "*"): "barrier:hedge"}


def stable_id(cls, kind, pts):
    """road-objects.md 3.2: class, kind and the centre rounded to a 2 m cell, so a re-bake keeps it."""
    cx = sum(p[0] for p in pts) / len(pts)
    cz = sum(p[1] for p in pts) / len(pts)
    return f"{cls}:{kind}:{math.floor(cx / 2 + 0.5) * 2}:{math.floor(cz / 2 + 0.5) * 2}"


def classify(d, sd):
    """Stage S2 of road-objects.md for one street: every solid within 3 m of a lane in the box, with
    an automatic verdict from the rules B1-B15 (the subset that map data alone can decide; the rest
    CHECK). Returns rows: id, cls, kind, gap, len, angle, s, t, rule, verdict, why."""
    fr = Frame(sd["frame"])
    lanes = RO.Lanes(d)
    steps = [pairs(s["p"]) for s in d.get("steps", [])]
    subways = [(p["x"], p["z"]) for p in d.get("pois", []) if p.get("k") == "subway_entrance"]
    juncs = junction_nodes(d)
    tram_segs = []
    for t_ in d.get("trams", []) + d.get("platforms", []):
        q = pairs(t_["p"])
        if t_ in d.get("platforms", []):
            q = q + q[:1]
        for a, b in zip(q, q[1:]):
            if in_rect(fr.st(*a), {"s": [sd["s"][0] - 20, sd["s"][1] + 20], "t": [sd["t"][0] - 20, sd["t"][1] + 20]}):
                tram_segs.append((a, b))
    rows = []
    for cls, kind, outline, level in RO.objects(d, os.path.join(ROOT, "game", "data")):
        pts = [p for p in RO.sample(outline, 1.0) if in_rect(fr.st(*p), sd)]
        if not pts:
            continue
        best = (math.inf, None, "", "")
        for p in pts:
            g, street, road = lanes.gap(p[0], p[1], level)
            if g < best[0]:
                best = (g, p, street, road)
        gap, at, street, road = best
        if gap >= 3.0:
            continue
        length = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(outline, outline[1:]))
        # The angle between the object's main direction and the street's axis (0 = parallel).
        ax, az = outline[-1][0] - outline[0][0], outline[-1][1] - outline[0][1]
        n = math.hypot(ax, az) or 1.0
        ang = math.degrees(math.acos(min(1.0, abs((ax * fr.s[0] + az * fr.s[1]) / n))))
        def near_stair(p, r=8.0):
            return any(math.hypot(p[0] - q[0], p[1] - q[1]) < r for s in steps for q in s) or \
                any(math.hypot(p[0] - q[0], p[1] - q[1]) < r + 2.0 for q in subways)
        # B5 as road-objects.md says it: the barrier wraps the stair (at most 25 m, both ends by it),
        # not any kerb piece that passes a stair (street-unslopper, 2026-11-05: a 59 m kerb rail).
        near_steps = length <= 25.0 and near_stair(outline[0]) and near_stair(outline[-1])
        # B2b: a fence along a tram line or a platform edge is the tram railing.
        by_tram = cls == "barrier" and kind == "fence" and ang < 15.0 and any(
            seg_dist(at, a, b)[0] < 4.0 for a, b in tram_segs) if tram_segs else False
        at_jn = any(math.hypot(at[0] - q[0], at[1] - q[1]) < RO.JUNCTION + 1.0 for q in juncs)
        s, t = fr.st(*at)
        lane_both = lanes.gap(at[0] + fr.t[0] * 6, at[1] + fr.t[1] * 6)[0] < 1.0 and lanes.gap(at[0] - fr.t[0] * 6, at[1] - fr.t[1] * 6)[0] < 1.0
        if cls in ("guard_rail", "struct_wall"):
            rule, verdict, why = "B1", "KEEP", "the road's edge rail; collisions are collision v2's job"
        elif cls == "shelter":
            rule, verdict, why = "B13", "KEEP", "real tram/bus shelter; soften its corner with collision v2"
        elif cls in ("building", "small_building") and kind in ("roof", "carport"):
            rule, verdict, why = "B6", "REPLACE", "canopy drawn as a block: roof on posts"
        elif cls in ("building", "small_building", "platform", "monument", "park_piece", "street_prop"):
            rule, verdict, why = "-", "KEEP", f"{cls}: not a barrier; C5/C10 checks cover it"
        elif cls == "parked_car":
            if at_jn:
                rule, verdict, why = "B7", "REMOVE", "parked within 15 m of a junction"
            else:
                rule, verdict, why = "B8", "KEEP", "parked row; corners SOFTEN with collision v2"
        elif cls == "barrier" and near_steps:
            rule, verdict, why = "B5", "REPLACE", "wall/fence round a stair or metro entrance: balustrade"
        elif cls == "barrier" and length < 4.0:
            rule, verdict, why = "B12", "CHECK", f"{length:.1f} m fragment: REMOVE unless the photos show it"
        elif by_tram:
            rule, verdict, why = "B2b", "RETEXTURE", "railing along the tram bed or platform edge: the tram railing (solid or soft is the B2 A/B)"
        elif cls == "barrier" and kind == "fence" and ang < 15.0 and lane_both:
            rule, verdict, why = "B2", "A/B", "median/tram fence parallel to the lanes: solid or SOFTEN, F decides on the phone"
        elif cls == "barrier" and ang > 45.0 and gap < 3.0:
            rule, verdict, why = "B3", "CHECK", "crosses towards a lane: an open gate (REMOVE) or a yard gate (REPLACE)"
        elif cls == "barrier" and kind in ("hedge",):
            rule, verdict, why = "B9", "SOFTEN", "hedge beside a lane"
        elif cls == "barrier" and gap > 1.0 and ang < 20.0:
            rule, verdict, why = "B11", "KEEP", "parallel wall/fence past the kerb"
        else:
            rule, verdict, why = "-", "CHECK", "no rule decides; needs the orthophoto or a street photo"
        model = MODEL_FOR.get((rule, cls)) or MODEL_FOR.get((rule, "*")) or MODEL_FOR.get(("*", cls))
        if model is None and cls == "barrier":
            model = "barrier:" + kind
        # The drawn style (a placed barrier type, game/data/object_palette.json) a verdict applies, when it has one.
        style = ""
        if model == "tram_railing":
            style = "tram_railing"
        elif model == "balustrade":
            metro = any(math.hypot(at[0] - q[0], at[1] - q[1]) < 12.0 for q in subways)
            style = "balustrade" if metro else "balustrade_rail"
        hand = sd.get("decisions", {}).get(stable_id(cls, kind, outline))
        if hand:
            verdict, style, why = hand[0], hand[1], "hand call: " + hand[2]
            rule = "F" if hand[2].startswith("F:") else "hand"
        if style:
            model = "barrier:" + style   # the drawn style is the library model (tools/model_library.py)
        status = "open"
        st = (s, t)
        if any(in_rect(st, o) for o in sd.get("owned", [])):
            status = "owned"
        elif any(in_rect(st, c) for c in sd.get("changed", [])):
            status = "changed"
        rows.append({"id": stable_id(cls, kind, outline), "cls": cls, "kind": kind, "gap": round(max(gap, 0.0), 2),
                     "len": round(length, 1), "angle": round(ang), "s": round(s), "t": round(t),
                     "x": round(at[0], 1), "z": round(at[1], 1), "street": street, "jn": int(at_jn),
                     "rule": rule, "verdict": verdict, "why": why, "model": model or "", "style": style, "status": status})
    rows.sort(key=lambda r: (r["verdict"] != "CHECK", r["verdict"], r["s"]))
    return rows


def summarise(findings, sd):
    blocks = []
    for b in sd["blocks"]:
        c = Counter(f["check"] for f in findings if f["block"] == b["id"] and f["status"] != "owned")
        score = max(0, 100 - sum(WEIGHTS[k] * n for k, n in c.items()))
        blocks.append({"id": b["id"], "title": b["title"], "counts": dict(sorted(c.items())), "score": score})
    counts = Counter(f["check"] for f in findings if f["status"] != "owned")
    total = round(sum(b["score"] for b in blocks) / max(1, len(blocks)))
    return blocks, dict(sorted(counts.items())), total


def evidence(sd):
    """The newest Mapillary photo per block (date, count within 30 m of the block's middle line)."""
    import street_photos as SP
    fr = Frame(sd["frame"])
    tm = sum(sd["street_t"]) / 2 if sd.get("street_t") else sum(sd["t"]) / 2
    res = []
    for b in sd["blocks"]:
        dates = []
        s = b["s"][0] + 20
        while s < b["s"][1]:
            lat, lon = SP.unproject(*fr.xz(s, tm))
            try:
                dates += [p["date"] for p in SP.mapillary(lat, lon, 30) if p.get("date")]
            except Exception as e:  # network: record what we could
                print(f"street_pass: evidence fetch failed at s={s:.0f}: {e}", file=sys.stderr)
            s += 60
        dates.sort()
        fresh = sd.get("fresh_since", "")
        res.append({"block": b["id"], "photos": len(dates), "newest": dates[-1] if dates else "",
                    "fresh": sum(1 for x in dates if x >= fresh) if fresh else None})
    return res


def dump(d, sd, block=None):
    """--dump[=BLOCK]: everything an auditor needs about a block, in the street's frame (s along, t
    across, metres), so nobody loads the 17 MB map by hand: the ways (direction, lanes, width,
    offset), lane-line ends, zebras, stop lines, junction nodes, objects with verdict and model, and
    the findings with their cause. Plain text, one table per kind."""
    fr = Frame(sd["frame"])
    blocks = [b for b in sd["blocks"] if not block or b["id"] == block]
    if not blocks:
        print(f"street_pass: no block {block} (blocks: {', '.join(b['id'] for b in sd['blocks'])})")
        return 2
    names = set(sd["names"])
    t0, t1 = sd["t"]
    findings = measure(d, sd)
    objs = classify(d, sd)

    def rng(pts):
        ss = [fr.st(*p) for p in pts]
        return min(x[0] for x in ss), max(x[0] for x in ss), sum(x[1] for x in ss) / len(ss)

    for b in blocks:
        s0, s1 = b["s"]

        def inb(p, pad=0.0):
            s, t = fr.st(*p)
            return s0 - pad <= s <= s1 + pad and t0 - pad <= t <= t1 + pad
        print(f"== block {b['id']} {b['title']}  s {s0}..{s1}, t {t0}..{t1}")
        print("ways (name, kind, s range, mean t, dir, lanes, width m, offset c)")
        for r in d["roads"]:
            pts = pairs(r["p"])
            if not any(inb(p, 5) for p in pts):
                continue
            a, z, tm = rng(pts)
            first, last = fr.st(*pts[0]), fr.st(*pts[-1])
            way = "north" if last[0] > first[0] else "south"
            mark = "*" if r.get("name") in names else " "
            print(f" {mark} {r.get('name') or '-':24.24} {r['k']:12.12} s {a:7.1f}..{z:7.1f} t {tm:6.1f} {way:5} "
                  f"lanes {r.get('lanes') or '-':>2} w {float(r['w']):5.2f} c {float(r.get('c', 0) or 0):5.2f}"
                  f"{'  oneway' if r.get('oneway') else ''}")
        print("lines (kind, s range, mean t)  [lane/centre/edge/stop]")
        for m in d["markings"]:
            if m.get("k") not in ("lane", "centre", "edge", "stop"):
                continue
            pts = pairs(m["p"])
            if not any(inb(p) for p in pts):
                continue
            a, z, tm = rng(pts)
            print(f"   {m['k']:6} s {a:7.1f}..{z:7.1f} t {tm:6.1f}")
        print("zebras and crossings (kind, s, t range)")
        for w in d.get("paths", []):
            if w.get("k") not in ("zebra", "cyclecross"):
                continue
            pts = pairs(w["p"])
            if not any(inb(p, 3) for p in pts):
                continue
            ss = [fr.st(*p) for p in pts]
            print(f"   {w['k']:10} s {sum(x[0] for x in ss) / len(ss):7.1f} t {min(x[1] for x in ss):6.1f}..{max(x[1] for x in ss):6.1f}")
        jn = [fr.st(*n) for n in junction_nodes(d) if inb(n)]
        print("junction nodes (s, t): " + ", ".join(f"({s:.0f},{t:.0f})" for s, t in sorted(jn)))
        print("objects within 3 m of a lane (id, s, t, gap m, length m, verdict, model, rule)")
        for o in objs:
            s, t = fr.st(o["x"], o["z"])
            if s0 <= s <= s1:
                print(f"   {o['id']:28} s {s:6.1f} t {t:6.1f} gap {o['gap']:4} len {o['len']:5} {o['verdict']:9} {o.get('model', ''):20} {o.get('rule', '')}")
        print("findings (check, s, t, status, note)")
        for f in findings:
            if f["block"] == b["id"]:
                print(f"   {f['check']} s {f['s']:6.1f} t {f['t']:6.1f} {f['status']:7} {f['note']}")
        used = sorted({f["check"] for f in findings if f["block"] == b["id"]})
        for k in used:
            print(f"cause {k}: {CAUSES[k]}")
    return 0


def photos(sd, slug_prefix, step=60.0, max_per=3):
    """--photos: one evidence pack for the whole street. The newest photos per block (every `step` m
    along both carriageways) and per CHECK object, saved by tools/street_photos.py under
    refs/road-SLUG-*, and docs-ready table docs/streets/SLUG-photos.md (id, place, date, fresh?).
    The auditor then only looks; nobody fetches by hand."""
    import street_photos as SP
    fr = Frame(sd["frame"])
    fresh = sd.get("fresh_since", "")
    t_l, t_r = sd.get("street_t", sd["t"])
    rows = []
    spots = []
    for b in sd["blocks"]:
        s = b["s"][0] + step / 2
        while s < b["s"][1]:
            for side, t in (("west", t_l + 4), ("east", t_r - 4)):
                spots.append((f"{b['id']}-s{int(s)}-{side}", b["id"], s, t))
            s += step
    rec_path = os.path.join(OUT_DIR, sd["slug"] + ".json")
    if os.path.exists(rec_path):
        for o in json.load(open(rec_path, encoding="utf-8")).get("objects", []):
            if o["verdict"] in ("CHECK", "A/B") and o["status"] == "open":
                s, t = fr.st(o["x"], o["z"])
                spots.append((o["id"].replace(":", "_"), "obj", s, t))
    for name, blk, s, t in spots:
        x, z = fr.xz(s, t)
        lat, lon = SP.unproject(x, z)
        got = []
        for fetch in (SP.mapillary, SP.panoramax):
            try:
                got += fetch(lat, lon, 25)
            except Exception as e:
                print(f"street_pass: {fetch.__name__} failed at {name}: {e}", file=sys.stderr)
        got = sorted(got, key=lambda p: p.get("date", ""), reverse=True)[:max_per]
        for p in got:
            rows.append((blk, name, round(s), round(t), f"{p['src']} {p.get('id', '')}", p.get("date", ""),
                         (p.get("date", "") >= fresh) if fresh else None))
        if not got:
            rows.append((blk, name, round(s), round(t), "", "", None))
    out = os.path.join(OUT_DIR, sd["slug"] + "-photos.md")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(f"# Evidence pack: {sd['title']}\n\nWritten by `tools/street_pass.py --street={sd['slug']} --photos` on "
                 f"{datetime.date.today().isoformat()}. Fresh = on or after {fresh or '(no fresh_since)'}; older photos are "
                 "history, not evidence. Fetch the images with `tools/street_photos.py X Z` only for the rows you look at.\n\n"
                 "| Block | Spot | s | t | Photo (source id) | Date | Fresh |\n| --- | --- | --- | --- | --- | --- | --- |\n")
        for r in rows:
            fh.write(f"| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} | {'yes' if r[6] else ('no' if r[6] is False else '-')} |\n")
    gaps = sorted({r[1] for r in rows if not r[5] or r[6] is False} - {r[1] for r in rows if r[6]})
    print(f"street_pass: {len(rows)} photo rows for {len(spots)} spots -> {os.path.relpath(out, ROOT)}")
    print(f"  spots with no fresh photo ({len(gaps)}): " + ", ".join(gaps))
    return 0


def write_record(sd, findings, ev, objs):
    blocks, counts, total = summarise(findings, sd)
    path = os.path.join(OUT_DIR, sd["slug"] + ".json")
    old = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}
    history = old.get("history", [])
    today = datetime.date.today().isoformat()
    snap = {"date": today, "score": total, "counts": counts, "blocks": {b["id"]: b["score"] for b in blocks}}
    if not history or history[-1]["counts"] != counts or history[-1]["score"] != total:
        history.append(snap)
    rec = {"slug": sd["slug"], "title": sd["title"], "updated": today, "stage": sd.get("stage", "baseline"),
           "score": total, "counts": counts, "blocks": blocks, "history": history,
           "baseline": old.get("baseline") or snap,
           "evidence": ev if ev is not None else old.get("evidence", []),
           "owned": sd.get("owned", []), "changed": sd.get("changed", []),
           "verdicts": dict(sorted(Counter(o["verdict"] for o in objs if o["status"] != "owned").items())),
           "findings": findings, "objects": objs}
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(rec, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    md = [f"# Street pass: {sd['title']}", "",
          f"Generated by `python3 -I tools/street_pass.py --street={sd['slug']} --write` on {today}; do not edit by hand.",
          f"Plan: docs/design/operation-unslop.md. Stage: **{rec['stage']}**. Score **{total}/100** "
          f"(baseline {rec['baseline']['score']} on {rec['baseline']['date']}).", "",
          "| Block | Score | " + " | ".join(f"{k} {TITLES[k]}" for k in WEIGHTS) + " |",
          "| --- | --- | " + " | ".join("---" for _ in WEIGHTS) + " |"]
    for b in blocks:
        md.append(f"| {b['id']} {b['title']} | {b['score']} | " + " | ".join(str(b["counts"].get(k, 0)) for k in WEIGHTS) + " |")
    if rec["evidence"]:
        md += ["", "Street-level evidence (Mapillary, newest photo per block; fresh = since " + sd.get("fresh_since", "-") + "):", ""]
        md += [f"- {e['block']}: {e['photos']} photos, newest {e['newest'] or 'none'}, fresh {e['fresh']}" for e in rec["evidence"]]
    if sd.get("owned") or sd.get("changed"):
        md += ["", "Areas:", ""]
        md += [f"- owned by {o['by']}: s {o['s']}, t {o['t']} (findings listed, not scored)" for o in sd.get("owned", [])]
        md += [f"- changed since {c['since']}: {c['what']} (s {c['s']}, t {c['t']}; data and old photos may be outdated)" for c in sd.get("changed", [])]
    vc = Counter(o["verdict"] for o in objs if o["status"] != "owned")
    md += ["", "## Objects within 3 m of a lane (road-objects S2 verdicts)", "",
           "Verdicts: " + ", ".join(f"{k} {v}" for k, v in sorted(vc.items())) + ". The override file applies them by id (stage S8).", "",
           "| Id | Class | Gap m | Length m | Angle | s | Rule | Verdict | Model | Why | Status |", "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    for o in objs:
        md.append(f"| `{o['id']}` | {o['cls']}/{o['kind']} | {o['gap']} | {o['len']} | {o['angle']} | {o['s']} | {o['rule']} | **{o['verdict']}** | `{o['model'] or '-'}` | {o['why']} | {o['status']} |")
    md += ["", "## Findings", "", "| Check | Block | s | t | Status | What | Look |", "| --- | --- | --- | --- | --- | --- | --- |"]
    for f in findings:
        md.append(f"| {f['check']} | {f['block']} | {f['s']:.0f} | {f['t']:.0f} | {f['status']} | {f['note']} | `--at={f['x']:.0f},{f['z']:.0f}` |")
    with open(os.path.join(OUT_DIR, sd["slug"] + ".md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")
    return rec


def spots(sd):
    """--spots: the street's fixed cameras as one `--spots=` argument for the game's shot run. The
    cameras are `cameras` in streets.json (name, x, z, optional h in degrees): every junction F has
    looked at keeps its camera, so every before/after of every round is the same view. Without
    them, one camera per block at its middle on the street centre line."""
    cams = sd.get("cameras")
    if not cams:
        fr = Frame(sd["frame"])
        tc = (sd["street_t"][0] + sd["street_t"][1]) / 2.0
        cams = []
        for b in sd["blocks"]:
            x, z = fr.xz((b["s"][0] + b["s"][1]) / 2.0, tc)
            cams.append({"name": b["id"], "x": round(x, 1), "z": round(z, 1)})
    parts = []
    for c in cams:
        v = f"{c['x']},{c['z']}" + (f",{c['h']}" if "h" in c else "")
        parts.append(f"{c['name']}:{v}")
    print(f'"--spots={";".join(parts)}"')
    return 0


def main():
    args = sys.argv[1:]
    opt = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in args}
    if "-h" in opt or "--help" in opt:
        print(__doc__)
        return 0
    defs = json.load(open(DEFS, encoding="utf-8"))["streets"]
    if "--list" in opt:
        for sd in defs:
            print(f"{sd['slug']:28} {sd['title']}")
        return 0
    map_path = opt.get("--map", os.path.join(ROOT, "game", "map", "centrum.json"))
    if not os.path.exists(map_path):
        print("street_pass: no map data (tools/map_pack.py fetch or tools/setup_map.sh)")
        return 2
    d = json.load(open(map_path, encoding="utf-8"))
    if "--apply" in opt:
        # game/data/road_objects.json: every recorded verdict that changes how a barrier is drawn.
        items = {}
        for sd in defs:
            path = os.path.join(OUT_DIR, sd["slug"] + ".json")
            if not os.path.exists(path):
                continue
            for o in json.load(open(path, encoding="utf-8")).get("objects", []):
                if o["status"] == "owned" or o["cls"] != "barrier":
                    continue
                if o["verdict"] == "REMOVE" or (o["verdict"] in ("RETEXTURE", "REPLACE") and o.get("style")):
                    items[o["id"]] = [o["verdict"], o.get("style", ""), sd["slug"]]
        out = os.path.join(ROOT, "game", "data", "road_objects.json")
        with open(out, "w", encoding="utf-8") as fh:
            json.dump({"_about": "tools/street_pass.py --apply: per-barrier verdicts from the street records (docs/streets/), "
                       "read by city_barriers.gd build_barriers (OBJECT_OVERRIDES). Do not edit by hand: change the street's "
                       "record or its `decisions` in docs/streets/streets.json and re-run.", "items": dict(sorted(items.items()))},
                      fh, ensure_ascii=False, indent=1)
            fh.write("\n")
        print(f"street_pass: {len(items)} barrier overrides -> game/data/road_objects.json")
        return 0
    if "--check" in opt:
        bad = []
        n = 0
        for sd in defs:
            path = os.path.join(OUT_DIR, sd["slug"] + ".json")
            if not os.path.exists(path):
                continue
            n += 1
            rec = json.load(open(path, encoding="utf-8"))
            _, counts, total = summarise(measure(d, sd), sd)
            for k, v in counts.items():
                if v > rec["counts"].get(k, 0):
                    bad.append(f"{sd['slug']}: {k} {TITLES[k]} {rec['counts'].get(k, 0)} -> {v}")
            print(f"street_pass counts: {sd['slug']} score {total} (record {rec['score']}) {counts}")
        if bad:
            print("\n".join(bad))
            for k in sorted({b.split(": ")[1].split()[0] for b in bad}):
                print(f"  {k} rose: suspect the rule, not the street ({CAUSES[k]})")
            print(f"street_pass: FAIL ({len(bad)} checks got worse; a class that rises after a re-bake is a rule bug "
                  "until shown otherwise; fix, or re-record on purpose with --write)")
            return 1
        print(f"street_pass: OK ({n} streets)")
        return 0
    slug = opt.get("--street")
    sd = next((s for s in defs if s["slug"] == slug), None)
    if not sd:
        print("street_pass: --street=SLUG needed (see --list)")
        return 2
    if "--dump" in opt:
        return dump(d, sd, None if opt["--dump"] is True else opt["--dump"])
    if "--photos" in opt:
        return photos(sd, sd["slug"])
    if "--spots" in opt:
        return spots(sd)
    findings = measure(d, sd)
    blocks, counts, total = summarise(findings, sd)
    ev = evidence(sd) if "--evidence" in opt else None
    objs = classify(d, sd)
    vc = Counter(o["verdict"] for o in objs if o["status"] != "owned")
    print(f"  objects within 3 m of a lane: {len(objs)}; verdicts {dict(sorted(vc.items()))}")
    print(f"street_pass: {sd['title']}: score {total}/100, open {counts}")
    for b in blocks:
        print(f"  {b['id']} {b['title']:40} {b['score']:3}  {b['counts']}")
    owned = sum(1 for f in findings if f["status"] == "owned")
    changed = sum(1 for f in findings if f["status"] == "changed")
    print(f"  owned elsewhere {owned}, in changed zones {changed}")
    if ev:
        for e in ev:
            print(f"  evidence {e['block']}: {e['photos']} photos, newest {e['newest']}, fresh {e['fresh']}")
    if "--write" in opt:
        write_record(sd, findings, ev, objs)
        print(f"street_pass: wrote docs/streets/{sd['slug']}.json and .md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
