"""Rail covers: the two places where a street crosses the Ochota cutting looked wrong in build 11
(F, 2026-11-16, Plac Zawiszy and Żelazna x Al. Jerozolimskie).

The bug. The bake turns every OpenStreetMap way tagged bridge=yes into a deck piece of its own, with
parapets on the sides that face out, and only joins two pieces of one bridge into one slab when they
lie under DECK_JOIN (6 m, map_builder.gd) apart. Two places came out wrong:

  "slab"    Plac Zawiszy: the line runs ~60 m under the junction (two carriageways, the tram and the
            pavements are one slab, the cutting ends in a wall each side). The bake made a narrow deck
            a way, 6-6.5 m apart, so the open pit with its tracks showed between them. Each piece gets
            a wider join reach (`j`, map_builder.gd `_deck_gaps`): the pieces' slabs meet half way
            across the gaps and the whole stretch is one deck from mouth to mouth, and the guard rails mapped
            along each carriageway go (kerbs stay). No ground, rails or lane graph change.
  "dedeck"  Żelazna: the way is tagged bridge, but it runs over the cross-city tunnel's roof just east
            of its west mouth, on solid ground (the grid stands within 0.2 m of the deck). The deck
            floated there with wing walls, parapets and a slab's dark side. The deck, its piers and
            aprons go; the road, its kerbs, paint and lanes are ground things again (`dk` off, the
            lane graph's `dk` and `br` too), and the deck's smooth level
            becomes the ground's there (an "s" fill, so the grid's bumps don't show through). map_builder.gd `_over_tunnel` keeps the cutting's bank
            from digging under a street over a tunnel, which the deck used to hide.

A ground road meets its neighbours differently from a deck road (lane lines cut at junction mouths
and under zebras, lane drops tapered where two ways differed only by `dk`). The passes that do that
(road_fixes, lane_tapers, road_smooth) are stamped and do not run again on a baked map, so `_local`
runs their rules inside the de-decked place's box only: the rest of the map keeps every line it had.

Idempotent and stamp-guarded like road_profiles.

    python3 -I tools/rail_covers.py [MAP_DIR] [--force]   applies COVERS to game/map/centrum.json
    python3 -I tools/rail_covers.py --check [MAP_DIR]     verify step `railcovers`
    python3 -I tools/rail_covers.py --sweep [MAP_DIR]     every road deck group: its air over the grid and
                                                          the widest gap between its pieces (the list for F)

tools/bake_osm.py runs `apply` after road_profiles. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import hashlib
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
KEY = "rail_covers"
VERSION = 7

# One entry a place. "group" is the deck group (`decks.pieces[].g`, `dk` on the things on it).
COVERS = [
    {"id": "zawiszy", "kind": "slab", "group": 14, "join": 8.0, "name": "Al. Jerozolimskie arm at Plac Zawiszy"},
    {"id": "zelazna", "kind": "dedeck", "group": 26, "name": "Żelazna by Al. Jerozolimskie"},
]

APRON_NEAR = 10.0    # an apron this near a removed deck's end goes with it
APRON = 10.0         # a slab end's apron reaches this far onto the street (bake_structures.APRON)...
APRON_IN = 4.0       # ...from this far inside the end (bake_structures.APRON_IN)
KEYS_ON_DECK = ("roads", "paths", "trams", "kerbs", "medians", "guards", "symbols", "markings", "surfaces",
                "carriage", "lines", "fills")


def _pairs(p):
    return [(p[i], p[i + 1]) for i in range(0, len(p) - 1, 2)]


def _stamp():
    keys = [VERSION, COVERS, APRON_NEAR]
    return hashlib.sha1(json.dumps(keys, sort_keys=True).encode()).hexdigest()[:12]


def _group_pieces(out, group):
    return [p for p in out["decks"]["pieces"] if p.get("g") == group]


def _slab(out, c, pieces):
    """One deck from mouth to mouth: each piece widened half way across the gap to its neighbour on
    a side where one lies within c["join"] m (that side no longer outer: no parapet), and marked a
    street's slab (`st`: paved top, map_builder.gd)."""
    widen = [_gaps_lr(p, pieces, c["join"]) for p in pieces]
    for p, (gl, gr) in zip(pieces, widen):
        for side, gap, bit in (("l", gl, 1), ("r", gr, 2)):
            if gap > 0.0:
                p[side] = round(p[side] + gap * 0.5 + 0.15, 2)
                p["o"] = [o & ~bit for o in p["o"]]
        p["st"] = 1
    # The mapped guard rails along each carriageway made every way read as a bridge of its own; on
    # the street over the tunnel there are kerbs only (they stay). The parapets on the slab's two
    # outer edges, over the cutting's mouths, are the deck's own (map_builder.gd) and stay.
    guards = out.get("guards", [])
    keep = [q for q in guards if q.get("dk", -1) != c["group"]]
    out["guards"] = keep
    n_guards = len(guards) - len(keep)
    # The same for the bridge railings in `lines` (object_types' hazard "deck": the tram corridor's
    # railings, a guard rail and a deck railing across the slab): a street over a tunnel has none, and
    # with them the tram tracks read as a fenced stop on a bridge (F, 2026-11-16).
    pts = [q for p in pieces for q in _pairs(p["p"])]
    pad = max(max(p.get("l", 0), p.get("r", 0)) for p in pieces)
    x0, x1 = min(q[0] for q in pts) - pad, max(q[0] for q in pts) + pad
    z0, z1 = min(q[1] for q in pts) - pad, max(q[1] for q in pts) + pad
    lines = out.get("lines", [])
    keep = [q for q in lines if not (q.get("hz") == "deck" and all(
        x0 <= x <= x1 and z0 <= z <= z1 for x, z in _pairs(q["p"])))]
    out["lines"] = keep
    # The slab's ends meet the street on the ground; the widened bands reach past the approaches'
    # corridors, where the cutting's bank dug a notch under the slab's edge and a car beside the
    # carriageway dropped under it (check_drive "under"). An apron per free end, as wide as the
    # widened piece (bake_structures.place_aprons' layout), holds the ground at the end's height
    # and keeps the bank out (map_builder.gd `_near_apron`).
    aprons = [a for a in out.get("aprons", []) if a.get("rc") != c["id"]]
    n_aprons = 0
    for p in pieces:
        pp = _pairs(p["p"])
        if len(pp) < 2:
            continue
        for end in (0, -1):
            ex, ez = pp[end]
            nx, nz = pp[1] if end == 0 else pp[-2]
            L = math.hypot(ex - nx, ez - nz) or 1.0
            ux, uz = (ex - nx) / L, (ez - nz) / L          # outward
            if _held((ex + ux * 1.0, ez + uz * 1.0), pieces, p):
                continue                                    # a joint with the next piece
            l, r = (p["r"], p["l"]) if end == 0 else (p["l"], p["r"])
            aprons.append({"p": [round(ex - ux * APRON_IN, 2), round(ez - uz * APRON_IN, 2),
                                 round(ex + ux * APRON, 2), round(ez + uz * APRON, 2)],
                           "h": round(float(p["h"][end]), 2), "l": round(l, 2), "r": round(r, 2),
                           "i": APRON_IN, "rc": c["id"]})
            n_aprons += 1
    out["aprons"] = aprons
    # Street objects the widened slab now covers (object_audit P6 "under a deck"): object_fixes
    # removes them on a fresh bake, after this pass; on a baked map it is stamped, so they go here.
    sys.path.insert(0, TOOLS)
    import object_audit as oa
    gone = {}
    for rule, key, idx, kind, x, z, note in oa.audit(out, []):
        if rule == "P6" and x0 <= x <= x1 and z0 <= z <= z1 and key in oa.STRIDE:
            gone.setdefault(key, set()).add(idx)
    for key, ids in gone.items():
        st, lst = oa.STRIDE[key], out.get(key, [])
        out[key] = [v for i in range(0, len(lst) - st + 1, st) if i // st not in ids for v in lst[i:i + st]]
    return {"pieces": len(pieces), "widened": [list(w) for w in widen], "guards": n_guards,
            "railings": len(lines) - len(keep), "aprons": n_aprons,
            "under": sum(len(v) for v in gone.values())}


def _undeck(out, c, pieces):
    """Take the deck group out: pieces, piers, aprons, `dk`, `bridge`, the lane graph's `dk` and `br`."""
    g = c["group"]
    pts = [q for p in pieces for q in _pairs(p["p"])]
    pad = 4.0 + max(max(p.get("l", 0), p.get("r", 0)) for p in pieces)
    x0, x1 = min(q[0] for q in pts) - pad, max(q[0] for q in pts) + pad
    z0, z1 = min(q[1] for q in pts) - pad, max(q[1] for q in pts) + pad
    inside = lambda x, z: x0 <= x <= x1 and z0 <= z <= z1
    out["decks"]["pieces"] = [p for p in out["decks"]["pieces"] if p.get("g") != g]
    piers = out["decks"]["piers"]
    keep = [q for q in piers if not inside(*q["c"])]
    n_piers = len(piers) - len(keep)
    out["decks"]["piers"] = keep
    ends = [(p["p"][0], p["p"][1]) for p in pieces] + [(p["p"][-2], p["p"][-1]) for p in pieces]
    aprons = out.get("aprons", [])
    keep = [a for a in aprons if not any(math.hypot(a["p"][0] - e[0], a["p"][1] - e[1]) < APRON_NEAR for e in ends)]
    n_aprons = len(aprons) - len(keep)
    out["aprons"] = keep
    moved = 0
    for key in KEYS_ON_DECK:
        for it in out.get(key, []):
            if isinstance(it, dict) and it.get("dk", -1) == g:
                del it["dk"]
                if "bridge" in it:
                    it["bridge"] = False
                moved += 1
    # The deck's own level, smooth along each way, becomes the ground's there (a ground profile, "s"
    # fill, map_builder.gd `_fill_base`): the 10 m grid's bumps stood through the asphalt in pale
    # wedges where a road that used to ride the deck now lay on the ground.
    out["fills"] = [f for f in out["fills"] if f.get("rc") != c["id"]]
    for p in pieces:
        out["fills"].append({"p": list(p["p"]), "h": list(p["h"]), "l": p["l"], "r": p["r"],
                             "k": p["k"] if p["k"] in ("road", "path", "tram") else "path", "s": 1,
                             "rc": c["id"]})  # not "rp": road_profiles counts every "rp" fill as its own
    edges = 0
    for e in out["graph"]["edges"]:
        # the lane graph's edges carry the deck group they drive on (`dk`, lane_graph.gd `e_dk`): a
        # lane left on a deck that is gone is read at a deck's level that is no longer there
        if e.get("dk", -1) == g:
            del e["dk"]
            e["br"] = 0
            edges += 1
    return {"pieces": len(pieces), "piers": n_piers, "aprons": n_aprons, "items": moved, "edges": edges,
            "ground": len(pieces),
            "box": [round(v, 1) for v in (x0, z0, x1, z1)]}


def _near(m, boxes, slack=6.0):
    q = m.get("p") or []
    for i in range(0, len(q) - 1, 2):
        for b in boxes:
            if b[0] - slack <= q[i] <= b[2] + slack and b[1] - slack <= q[i + 1] <= b[3] + slack:
                return True
    return False


def _local(out, boxes):
    """road_fixes' line cuts at junction mouths, lane_tapers' tapers and road_smooth's cuts under zebras,
    run inside the boxes only (see the module's docstring). Everything outside is left as it was."""
    sys.path.insert(0, TOOLS)
    import road_fixes as RF
    import road_smooth as RS
    import lane_tapers as LT

    def on_markings(fn):
        idx = {i for i, m in enumerate(out["markings"]) if _near(m, boxes)}
        keep = [m for i, m in enumerate(out["markings"]) if i not in idx]
        sub = dict(out)
        sub["markings"] = [out["markings"][i] for i in sorted(idx)]
        fn(sub)
        out["markings"] = keep + sub["markings"]

    all_ribbons = RF.Ribbons(out, lambda r: True)
    main_ribbons = RF.Ribbons(out, lambda r: r["k"] in RF.MAIN)
    mi = RF.MouthIndex(RF.mouths(out, RF.junction_nodes(out), all_ribbons))
    on_markings(lambda sub: RF.cut_lines(sub, mi, main_ribbons))
    saved = (LT.find_joins, LT.build_obstacles, LT.rs.seat_edges, LT.rs.clear_poles, out.get(LT.KEY))
    orig_find = LT.find_joins
    try:
        LT.find_joins = lambda roads, ways, ends: [
            j for j in orig_find(roads, ways, ends)
            if any(b[0] <= j[1][0] <= b[2] and b[1] <= j[1][1] <= b[3] for b in boxes)]
        LT.build_obstacles = lambda o: (RS.Grid(8.0), [])
        LT.rs.seat_edges = lambda o: 0
        LT.rs.clear_poles = lambda o, a: 0
        out[LT.KEY] = 0
        LT.apply(out)
    finally:
        LT.find_joins, LT.build_obstacles, LT.rs.seat_edges, LT.rs.clear_poles = saved[:4]
        if saved[4] is None:
            out.pop(LT.KEY, None)
        else:
            out[LT.KEY] = saved[4]
    on_markings(lambda sub: RS.cut_zebras(sub))


def apply(out, map_dir=None, force=False):
    old = out.get(KEY, {})
    if not force and old.get("stamp") == _stamp() and all(c["id"] in old.get("covers", {}) for c in COVERS):
        return "%d places (stamp %s: unchanged)" % (len(old["covers"]), old["stamp"])
    rec = {"v": VERSION, "stamp": _stamp(), "covers": {}}
    msgs = []
    boxes = []
    for c in COVERS:
        pieces = _group_pieces(out, c["group"])
        if not pieces:
            prev = old.get("covers", {}).get(c["id"])
            if prev:
                rec["covers"][c["id"]] = prev
                msgs.append("%s: kept (deck already gone)" % c["id"])
                continue
            msgs.append("%s: deck group %d not found" % (c["id"], c["group"]))
            continue
        if c["kind"] == "slab":
            info = _slab(out, c, pieces)
        else:
            info = _undeck(out, c, pieces)
            boxes.append(tuple(info["box"]))
        rec["covers"][c["id"]] = info
        msgs.append("%s: %s" % (c["id"], ", ".join("%s %s" % (k, v) for k, v in info.items() if k != "box")))
    if boxes:
        _local(out, boxes)
    out[KEY] = rec
    return "; ".join(msgs)


def check(out, map_dir=None):
    rec = out.get(KEY, {})
    bad = []
    if rec.get("stamp") != _stamp():
        bad.append("stamp %s is not today's %s" % (rec.get("stamp"), _stamp()))
    for c in COVERS:
        if c["id"] not in rec.get("covers", {}):
            bad.append("%s not applied" % c["id"])
        pieces = _group_pieces(out, c["group"])
        if c["kind"] == "dedeck" and pieces:
            bad.append("%s: deck group %d still on the map" % (c["id"], c["group"]))
        if c["kind"] == "slab" and any(p.get("st") != 1 for p in pieces):
            bad.append("%s: deck group %d is not one slab" % (c["id"], c["group"]))
    return bad


def _held(q, ps, skip):
    for b in ps:
        if b is skip:
            continue
        w = max(b.get("l", 0), b.get("r", 0))
        for i in range(0, len(b["p"]) - 3, 2):
            q0, q1 = (b["p"][i], b["p"][i + 1]), (b["p"][i + 2], b["p"][i + 3])
            dx, dz = q1[0] - q0[0], q1[1] - q0[1]
            L2 = dx * dx + dz * dz
            if L2 < 1e-6:
                continue
            u = ((q[0] - q0[0]) * dx + (q[1] - q0[1]) * dz) / L2
            if -0.02 <= u <= 1.02 and math.hypot(q[0] - q0[0] - u * dx, q[1] - q0[1] - u * dz) <= w:
                return True
    return False


def _gaps_lr(a, ps, reach):
    """Piece a's widest gap (m, 0.5 m steps) to another piece of `ps` on its left and on its right, over
    its inner points, counting only gaps up to `reach` (0.0: none)."""
    pts = _pairs(a["p"])
    out = [0.0, 0.0]
    for i in range(1, len(pts) - 1):
        q, p0, p1 = pts[i], pts[i - 1], pts[i + 1]
        L = math.hypot(p1[0] - p0[0], p1[1] - p0[1]) or 1.0
        n = (-(p1[1] - p0[1]) / L, (p1[0] - p0[0]) / L)
        for k, (sgn, w) in enumerate(((-1.0, a.get("l", 0)), (1.0, a.get("r", 0)))):
            t = 0.5
            while t <= reach:
                if _held((q[0] + n[0] * sgn * (w + t), q[1] + n[1] * sgn * (w + t)), ps, a):
                    out[k] = max(out[k], t)
                    break
                t += 0.5
    return tuple(out)


def _side_gaps(a, ps):
    """At each of piece a's points, how far out on each side another piece of its group starts (as
    map_builder.gd `_deck_gaps` looks, 0.5 m steps up to 12 m); the widest such gap over 6 m."""
    def held(q, skip):
        for b in ps:
            if b is skip:
                continue
            w = max(b.get("l", 0), b.get("r", 0))
            for i in range(0, len(b["p"]) - 3, 2):
                q0, q1 = (b["p"][i], b["p"][i + 1]), (b["p"][i + 2], b["p"][i + 3])
                dx, dz = q1[0] - q0[0], q1[1] - q0[1]
                L2 = dx * dx + dz * dz
                if L2 < 1e-6:
                    continue
                u = ((q[0] - q0[0]) * dx + (q[1] - q0[1]) * dz) / L2
                if -0.02 <= u <= 1.02 and math.hypot(q[0] - q0[0] - u * dx, q[1] - q0[1] - u * dz) <= w:
                    return True
        return False

    pts = _pairs(a["p"])
    worst = 0.0
    for i, q in enumerate(pts):
        p0, p1 = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        L = math.hypot(p1[0] - p0[0], p1[1] - p0[1]) or 1.0
        n = (-(p1[1] - p0[1]) / L, (p1[0] - p0[0]) / L)
        for sgn, w in ((-1.0, a.get("l", 0)), (1.0, a.get("r", 0))):
            t = 0.5
            while t <= 12.0:
                if held((q[0] + n[0] * sgn * (w + t), q[1] + n[1] * sgn * (w + t)), a):
                    if t > 6.0:
                        worst = max(worst, t)
                    break
                t += 0.5
    return worst


def sweep(out, map_dir):
    """Per road deck group: air over the grid (a deck on solid ground is a fake bridge), and pieces whose
    nearest neighbour of the group lies between DECK_JOIN and 12 m away (a pit showing between them)."""
    with open(os.path.join(map_dir, "terrain.json"), encoding="utf-8") as f:
        t = json.load(f)

    def at(x, z):
        gx, gz = (x - t["x0"]) / t["step"], (z - t["z0"]) / t["step"]
        i, j = int(math.floor(gx)), int(math.floor(gz))
        fx, fz = gx - i, gz - j
        g = lambda a, b: t["h"][b * t["nx"] + a]
        return (g(i, j) * (1 - fx) + g(i + 1, j) * fx) * (1 - fz) + (g(i, j + 1) * (1 - fx) + g(i + 1, j + 1) * fx) * fz

    groups = {}
    for p in out["decks"]["pieces"]:
        groups.setdefault(p["g"], []).append(p)
    rows = []
    for g, ps in sorted(groups.items()):
        if not any(p["k"] == "road" for p in ps):
            continue
        air = [h - at(*q) for p in ps if p["k"] == "road" for q, h in zip(_pairs(p["p"]), p["h"])]
        open_gaps = sorted({v for v in (_side_gaps(a, ps) for a in ps) if v > 0.0})
        rows.append((g, len(ps), round(max(air), 1), round(sum(air) / len(air), 1), open_gaps,
                     [round(v) for v in ps[0]["p"][:2]]))
    return rows


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    map_dir = os.path.abspath(args[0] if args else os.path.join(TOOLS, "..", "game", "map"))
    path = os.path.join(map_dir, "centrum.json")
    with open(path, encoding="utf-8") as f:
        out = json.load(f)
    if "--check" in argv:
        bad = check(out, map_dir)
        for b in bad:
            print("rail_covers: " + b)
        print("rail_covers: %s" % ("OK" if not bad else "FAIL"))
        return 1 if bad else 0
    if "--sweep" in argv:
        print("group pieces max_air mean_air gaps_6_12m first_point")
        for r in sweep(out, map_dir):
            print(*r)
        return 0
    msg = apply(out, map_dir, "--force" in argv)
    print("rail_covers: " + msg)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
