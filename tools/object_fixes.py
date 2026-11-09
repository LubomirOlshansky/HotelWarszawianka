"""Street objects unslopped (F, 2026-11-07): the confident verdicts of tools/object_audit.py
applied to the finished map data, so a re-bake keeps them.

    python3 -I tools/object_fixes.py [MAP.json] [--dry]
        rewrites the map in place (idempotent: a map already fixed is left alone);
        --dry prints what it would do and changes nothing.
    python3 -I tools/object_fixes.py --check [MAP.json]
        exit 1 unless the map is fixed and every AUTO rule of object_audit.py has at most
        CHECK_LEFT[rule] findings left (verify.sh step `objects`; a ratchet: lower, never raise).

Verdicts, per object_audit.py rule:

    P1 inside building   REMOVE   (a bin or a parked car poking out of a wall)
    P2 in a carriageway  MOVE     onto the pavement: straight out from the road's centreline to
                                  PAVE m past its edge, when that spot is free (no building, water,
                                  other carriageway, zebra) and at most SHIFT_MAX m away; else REMOVE
    P3 on a zebra        REMOVE
    P4 on tram rails     REMOVE
    P5 in water          REMOVE   (a bridge's lamps are the bake's own deck lamps)
    P6 under a deck      REMOVE   (drawn on the ground in the slab's shade; the deck keeps its own lamps)
    P7 double            REMOVE   the second
    P10 not a bus stop   REPLACE  with a bench (OSM amenity=shelter in a park, a yard or a car park is
                                  a picnic or smoking roof; drawn as a bus shelter it also became a
                                  stop for the ring buses, buses.gd add_shelters)
    P11 parked car       REMOVE
    L1 inside building   TRIM     the parts inside the walls go, the parts outside stay
    L2 stub              REMOVE
    L3 on another        REMOVE   the shorter one
    L4 across a path     GATE     the barrier is cut where the footway or zebra crosses it, as wide as
                                  the path plus GATE_PAD (the gates OSM maps as nodes, which the bake
                                  never read)
    L5 stair wall        RESTYLE  `st` = STAIR_STYLE: the 1 m balustrade instead of the grey slab
    L6 in water          TRIM     the parts of a fence or hedge more than WET_IN m inside the water go
    T1 tree in water     REMOVE   (its crown scale in trees3d_crown goes with it)
    T2 tree on the road  MOVE     to the nearest spot within TREE_SHIFT m whose trunk keeps TREE_CLEAR
                                  m off the drawn asphalt (an island or a median is fine), out of the
                                  water, buildings, tram tracks and zebras; else REMOVE
    P8 on steps, P9 lone signal: CHECK only (an amphitheatre's seats, a mid-block crossing's lights).

Barriers with an Operation Unslop override (game/data/road_objects.json) are never touched, so
their stable ids stay. bake_osm.py calls apply(out) after road_smooth and road_fixes, before
bus_stops (it paints at the shelters this leaves). On a baked map run, in order: this,
tools/bus_stops.py, tools/bake_street_details.py, tools/bake_park_details.py, tools/bake_sectors.py,
then bake_city.gd. Deterministic, standard library only.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import object_audit as oa  # noqa: E402

ROOT = oa.ROOT
VERSION = 2   # 2: L6, T1, T2 (F, 2026-11-08: trees and fences in the Vistula, trees in the lanes)
PAVE = {"lamp": 0.7, "signal": 0.6}
PAVE_OTHER = 0.9
SHIFT_MAX = {"lamp": 4.5, "signal": 4.5}
SHIFT_OTHER = 2.5
GATE_PAD = 0.4
GATE_MIN = 1.6
PASSES = 3
TRIM_MIN = 1.0
TREE_SHIFT = 3.0   # T2: a tree moves at most this far off the road...
TREE_CLEAR = 0.8   # ...to a spot with the asphalt at least this far from its trunk
REMOVE = ("P1", "P3", "P4", "P5", "P6", "P7", "P11")
AUTO = REMOVE + ("P2", "P10", "L1", "L2", "L3", "L4", "L5", "L6", "T1", "T2")
# map_builder.gd BARRIER_STYLE: a concrete upstand with an open rail, 1 m (street_pass B5's look).
STAIR_STYLE = "balustrade_rail"
# Left after the fixes on the demo map (2026-11-07): the ratchet of --check.
CHECK_LEFT = {"P1": 0, "P2": 0, "P3": 0, "P4": 0, "P5": 0, "P6": 0, "P7": 0, "P10": 0, "P11": 0,
              "L1": 0, "L2": 0, "L3": 0, "L4": 0, "L5": 0, "L6": 0, "T1": 0, "T2": 0}


def overridden():
    p = os.path.join(ROOT, "game", "data", "road_objects.json")
    if not os.path.exists(p):
        return set()
    with open(p, encoding="utf-8") as f:
        return set(json.load(f).get("items", {}))


def barrier_id(kind, flat):
    """map_builder.gd barrier_id / street_pass.py stable_id."""
    line = oa.pts(flat)
    cx = sum(p[0] for p in line) / len(line)
    cz = sum(p[1] for p in line) / len(line)
    return f"barrier:{kind}:{math.floor(cx / 2 + 0.5) * 2}:{math.floor(cz / 2 + 0.5) * 2}"


def pave_spot(w, p, base):
    """A free pavement spot straight out of the carriageway p stands in, or None."""
    g, road = w.lane_gap(p)
    if road is None:
        return None
    line = oa.pts(road["p"])
    best = None
    for a, b in zip(line, line[1:]):
        dd, t = oa.seg_d(p, a, b)
        if best is None or dd < best[0]:
            best = (dd, a, b, t)
    dd, a, b, t = best
    fx, fz = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
    nx, nz = p[0] - fx, p[1] - fz
    n = math.hypot(nx, nz)
    if n < 0.05:
        return None   # on the centreline: no side to push to
    nx, nz = nx / n, nz / n
    want = float(road.get("w", 6.0)) * 0.5 + PAVE.get(base, PAVE_OTHER)
    q = (round(fx + nx * want, 1), round(fz + nz * want, 1))
    if math.hypot(q[0] - p[0], q[1] - p[1]) > SHIFT_MAX.get(base, SHIFT_OTHER):
        return None
    g2, _ = w.lane_gap(q)
    if base in ("lamp", "signal") and w.asphalt is not None:
        on, up = w.asphalt
        if on(q[0], q[1]) and not up(q[0], q[1]):
            return None   # check_streets S1: a pole on the drawn asphalt (a tapered band, a carriage area)
    if g2 < 0.2 or w.in_building(q, 0.0) or w.in_water(q) or w.on_line(w.zebras, q, pad=-0.3):
        return None
    return q


def split_gates(flat, cuts):
    """The polyline `flat` with a gap of half width h round each point (x, z, h) of `cuts` that lies
    on it: a list of flat polylines (pieces under 0.3 m dropped)."""
    line = oa.pts(flat)
    # Arc position of every cut on the line.
    acc = [0.0]
    for a, b in zip(line, line[1:]):
        acc.append(acc[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    gaps = []
    for cx, cz, h in cuts:
        best = None
        for k, (a, b) in enumerate(zip(line, line[1:])):
            dd, t = oa.seg_d((cx, cz), a, b)
            if best is None or dd < best[0]:
                best = (dd, acc[k] + t * (acc[k + 1] - acc[k]))
        if best and best[0] < 0.5:
            gaps.append((best[1] - h, best[1] + h))
    if not gaps:
        return [flat]
    gaps.sort()

    def at(s):
        for k in range(len(line) - 1):
            if acc[k + 1] >= s:
                L = acc[k + 1] - acc[k]
                t = 0.0 if L < 1e-9 else (s - acc[k]) / L
                a, b = line[k], line[k + 1]
                return (round(a[0] + (b[0] - a[0]) * t, 2), round(a[1] + (b[1] - a[1]) * t, 2))
        return line[-1]

    pieces = []
    start = 0.0
    for g0, g1 in gaps + [(acc[-1] + 1.0, acc[-1] + 1.0)]:
        end = min(g0, acc[-1])
        if end - start > 0.3:
            pts_ = [at(start)] + [line[k] for k in range(len(line)) if start < acc[k] < end] + [at(end)]
            pieces.append([c for p in pts_ for c in p])
        start = max(start, g1)
    return pieces


def tree_spot(w, p):
    """T2: the nearest spot within TREE_SHIFT m of the tree p (on the road) where its trunk keeps
    TREE_CLEAR m off the drawn asphalt, or None. Rings every 0.25 m, 24 directions."""
    def ok(q):
        return not w.on_road(q)

    def free(q):
        if not ok(q) or w.in_water(q) or w.in_building(q, 0.0) or w.on_track(q) or w.on_line(w.zebras, q, pad=-0.5):
            return False
        return all(ok((q[0] + math.cos(a) * TREE_CLEAR, q[1] + math.sin(a) * TREE_CLEAR))
                   for a in (k * math.pi / 4 for k in range(8)))
    r = 0.25
    while r <= TREE_SHIFT + 1e-6:
        for k in range(24):
            a = k * math.pi / 12
            q = (round(p[0] + math.cos(a) * r, 1), round(p[1] + math.sin(a) * r, 1))
            if free(q):
                return q
        r += 0.25
    return None


def trim_inside(w, flat, step=0.5, gone=None):
    """The parts of the polyline `flat` outside every building at least 2.5 m high (or, with
    `gone`, where gone(point) is false; pieces of at least TRIM_MIN m), keeping its own vertices
    and the points where it enters or leaves a wall."""
    gone = gone or (lambda q: w.in_building(q, 2.5))
    line = oa.pts(flat)
    marks = []   # (x, z, outside, own vertex)
    for a, b in zip(line, line[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / step))
        for k in range(n):
            t = k / n
            q = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            marks.append((q, not gone(q), k == 0))
    marks.append((line[-1], not gone(line[-1]), True))
    pieces = []
    cur = []
    for k, (q, out, own) in enumerate(marks):
        if out:
            edge = not cur or k + 1 == len(marks) or not marks[k + 1][1]
            if own or edge:
                cur.append(q)
        elif cur:
            pieces.append(cur)
            cur = []
    if cur:
        pieces.append(cur)
    res = []
    for pc in pieces:
        if len(pc) >= 2 and oa.line_len(pc) >= TRIM_MIN:
            res.append([round(c, 2) for p in pc for c in p])
    return res


def gate_cuts(w, line):
    """(x, z, half width) where a footway's or zebra's centreline crosses the barrier `line`."""
    cuts = []
    for a, b in zip(line, line[1:]):
        for grid in (w.zebras, w.foot):
            for pl, pw in grid.near_seg(a, b):
                for c, e in zip(pl, pl[1:]):
                    if oa.crosses(a, b, c, e):
                        # Intersection point.
                        d1 = (b[0] - a[0], b[1] - a[1])
                        d2 = (e[0] - c[0], e[1] - c[1])
                        den = d1[0] * d2[1] - d1[1] * d2[0]
                        if abs(den) < 1e-9:
                            continue
                        t = ((c[0] - a[0]) * d2[1] - (c[1] - a[1]) * d2[0]) / den
                        x, z = a[0] + d1[0] * t, a[1] + d1[1] * t
                        # The gap along the barrier: the path's width over the crossing angle's sine.
                        sin = abs(den) / (math.hypot(*d1) * math.hypot(*d2))
                        h = max(GATE_MIN, float(pw) + GATE_PAD) * 0.5 / max(sin, 0.5)
                        cuts.append((x, z, h))
    return cuts


def apply(out, dry=False):
    """Fixes the finished map data in place; returns a one-line summary. Up to PASSES passes, as a
    gate cut can leave a stub or a stair's balustrade piece for the next one."""
    if int(out.get("object_fixes", 0)) >= VERSION:
        return "already fixed"
    if dry:
        return "would: " + _pass(out, True)
    notes = []
    for _ in range(PASSES):
        note = _pass(out, False)
        if not note:
            break
        notes.append(note)
    if any("P10" in n for n in notes):
        # The benches that replaced park shelters face the walk like every other (snap_props G9).
        import snap_props
        t = snap_props.face_benches(out)
        notes.append(f"benches faced {t[0]}")
    out["object_fixes"] = VERSION
    return " | ".join(notes) or "nothing to fix"


def _pass(out, dry):
    """One pass of the verdicts; returns what it did ("" when nothing)."""
    found = oa.audit(out, [])   # street details are placed clear of all this by their own bake
    w = oa.World(out)
    keep_ids = overridden()
    drop = {k: set() for k in oa.STRIDE}
    moves = {k: {} for k in oa.STRIDE}
    benches = []
    tally = {}
    line_drop = set()
    gates = {}
    styles = {}
    trims = {}
    tree_drop = set()
    tree_moves = {}
    for rule, key, idx, kind, x, z, note in found:
        if key == "trees3d":
            if idx in tree_drop or idx in tree_moves:
                continue
            q = tree_spot(w, (x, z)) if rule == "T2" else None
            if q:
                tree_moves[idx] = q
                tally["T2 moved"] = tally.get("T2 moved", 0) + 1
            else:
                tree_drop.add(idx)
                tally[rule + (" removed" if rule == "T2" else "")] = tally.get(rule + (" removed" if rule == "T2" else ""), 0) + 1
            continue
        if key == "lines":
            l = out["lines"][idx]
            if barrier_id(l["k"], l["p"]) in keep_ids or idx in line_drop:
                continue
            if rule in ("L1", "L6"):
                trims[idx] = rule
                tally[rule] = tally.get(rule, 0) + 1
            elif rule in ("L2", "L3"):
                line_drop.add(idx)
                tally[rule] = tally.get(rule, 0) + 1
            elif rule == "L4":
                gates[idx] = True
            elif rule == "L5":
                styles[idx] = STAIR_STYLE
                tally[rule] = tally.get(rule, 0) + 1
            continue
        if idx in drop[key]:
            continue
        if rule in REMOVE:
            drop[key].add(idx)
            moves[key].pop(idx, None)
            tally[rule] = tally.get(rule, 0) + 1
        elif rule == "P2":
            q = pave_spot(w, (x, z), kind)
            if q:
                moves[key][idx] = q
                tally["P2 moved"] = tally.get("P2 moved", 0) + 1
            else:
                drop[key].add(idx)
                tally["P2 removed"] = tally.get("P2 removed", 0) + 1
        elif rule == "P10":
            st = oa.STRIDE[key]
            yaw = out[key][idx * st + 2]
            benches.append((x, z, yaw))
            drop[key].add(idx)
            tally["P10"] = tally.get("P10", 0) + 1
    # Gates.
    new_lines = []
    gated = 0
    for i, l in enumerate(out.get("lines", [])):
        if i in line_drop:
            continue
        if i in styles:
            l = dict(l)
            l["st"] = styles[i]
        if i in trims:
            gone = (lambda q: w.deep_water(q)) if trims[i] == "L6" else None
            for pc in trim_inside(w, l["p"], gone=gone):
                nl = dict(l)
                nl["p"] = pc
                new_lines.append(nl)
            continue
        if i in gates:
            cuts = gate_cuts(w, oa.pts(l["p"]))
            pieces = split_gates(l["p"], cuts)
            if len(pieces) != 1 or pieces[0] != l["p"]:
                gated += 1
            for pc in pieces:
                nl = dict(l)
                nl["p"] = pc
                new_lines.append(nl)
            continue
        new_lines.append(l)
    if gated:
        tally["L4 gates"] = gated
    if dry:
        return ", ".join(f"{k} {v}" for k, v in sorted(tally.items()))
    out["lines"] = new_lines
    for key, st in oa.STRIDE.items():
        lst = out.get(key, [])
        res = []
        for i in range(0, len(lst) - st + 1, st):
            k = i // st
            if k in drop[key]:
                continue
            rec = list(lst[i:i + st])
            if k in moves[key]:
                rec[0], rec[1] = moves[key][k]
            res += rec
        out[key] = res
    for x, z, yaw in benches:
        out["benches"] += [x, z, yaw]
    if tree_drop or tree_moves:
        t = out.get("trees3d", [])
        crowns = out.get("trees3d_crown", [])
        kept, kept_crowns = [], []
        for k in range(len(t) // 6):
            if k in tree_drop:
                continue
            rec = list(t[k * 6:k * 6 + 6])
            if k in tree_moves:
                rec[0], rec[1] = tree_moves[k]
            kept += rec
            if k < len(crowns):
                kept_crowns.append(crowns[k])
        out["trees3d"] = kept
        if crowns:
            out["trees3d_crown"] = kept_crowns
        if tree_moves:
            tally["T2 crowns trimmed by a deck"] = _trim_moved_crowns(out)
    return ", ".join(f"{k} {v}" for k, v in sorted(tally.items()))


def _trim_moved_crowns(out):
    """A tree moved off the road can now stand beside a deck (a footbridge's ramp): its crown is
    trimmed to clear the slab as bake_structures.trim_crowns did for the others (check_roads C9).
    Needs game/map/terrain.json (the map pack); without it nothing is trimmed (-1)."""
    map_dir = os.path.join(ROOT, "game", "map")
    tp = os.path.join(map_dir, "terrain.json")
    if not os.path.exists(tp):
        return -1
    import bake_structures
    import check_roads as cr
    with open(tp, encoding="utf-8") as f:
        terrain = json.load(f)
    return bake_structures.trim_crowns(cr.Map.from_data(map_dir, out, terrain))[0]


def check(path):
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if int(d.get("object_fixes", 0)) < VERSION:
        print("object_fixes: FAIL the map is not fixed: run python3 -I tools/object_fixes.py")
        return 1
    found = oa.audit(d, [])
    keep_ids = overridden()
    left = {}
    for rule, key, idx, kind, x, z, note in found:
        if key == "lines" and barrier_id(d["lines"][idx]["k"], d["lines"][idx]["p"]) in keep_ids:
            continue
        left[rule] = left.get(rule, 0) + 1
    bad = [f"{r} {left.get(r, 0)} > {n}" for r, n in CHECK_LEFT.items() if left.get(r, 0) > n]
    info = ", ".join(f"{r} {n}" for r, n in sorted(left.items()))
    if bad:
        print("object_fixes: FAIL " + "; ".join(bad) + f" (left: {info})")
        return 1
    print(f"object_fixes: OK (left for a person: {info or 'none'})")
    return 0


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    for a in argv:
        if not a.startswith("--"):
            path = a
    if "--check" in argv:
        return check(path)
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    dry = "--dry" in argv
    print("object_fixes: " + apply(d, dry))
    if not dry and d.get("object_fixes"):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
