"""Rail covers: fake bridges over the railway cutting taken out, and the stretch where the line
really runs under a junction covered (F, 2026-11-16, Plac Zawiszy and Żelazna x Al. Jerozolimskie).

The bug. The bake turns every OpenStreetMap way tagged bridge=yes into a deck, 5 m or more over the
ground, with piers, aprons and walls, and the ground under it is the 10 m terrain grid (GUGiK bare
earth). Two kinds of way come out wrong where a road meets the Ochota cutting:

  "dedeck"  The way is tagged bridge but the grid under it is solid (Żelazna beside the cutting's
            retaining wall: the road runs on the wall's top, no track below the deck). The deck then
            floats 0.1 m over the ground: wing walls, a dark slab and ramps for a road that is flat.
            The deck, its piers and aprons go; the road is a ground road again.
  "cover"   The line runs in a short tunnel under the junction (Plac Zawiszy: the Al. Jerozolimskie
            arm over the cutting, two carriageways, the tram and the pavement all one slab, the
            cutting ending in a retaining wall each side, F's ortho and aerials). The bake found one
            narrow deck for each carriageway and tram, and left the stretch between them as the
            cutting's open pit with the tracks running through it. The decks go, the ground between
            the cutting's two ends is laid up to the street's level (a ground profile, "s" fill,
            map_builder.gd `_fill_height_base`), and trains.gd cuts the rails and builds the mouths
            there (TUNNEL_ZAWISZY_PLAC, PORTALS).

Both leave every road where it was: a way keeps its geometry, loses its `dk`, `bridge` and the
lane graph's `dk` and `br`. The pass is idempotent and stamp-guarded like road_profiles; it reads the grid
(game/map/terrain.json) only to lay the cover.

    python3 -I tools/rail_covers.py [MAP_DIR] [--force]   applies COVERS to game/map/centrum.json
    python3 -I tools/rail_covers.py --check [MAP_DIR]     verify step `railcovers`
    python3 -I tools/rail_covers.py --sweep [MAP_DIR]     every deck over solid ground, and every open
                                                          cutting cell beside a road (the list for F)

tools/bake_osm.py runs `apply` after road_profiles. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import hashlib
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
KEY = "rail_covers"
VERSION = 2

# One entry a place. "group" is the deck group (`decks.pieces[].g`, `dk` on the things on it).
# "cover" entries also give the stretch's axis (the tracks' direction), its centre, the along range
# the decks span (padded by PAD), the level (the decks' own height) and the tunnel polygon's
# half width across.
COVERS = [
    {"id": "zelazna", "kind": "dedeck", "group": 26, "name": "Żelazna by Al. Jerozolimskie"},
    {"id": "zawiszy", "kind": "cover", "group": 14, "name": "Al. Jerozolimskie arm at Plac Zawiszy",
     "centre": [-2410.0, 955.0], "axis": [0.928, -0.372], "pad": 3.0, "across": 46.0, "reach": 60.0},
]

STEP = 6.0           # a cover's ground rows, this far apart along the axis
LOW = 13.6           # the grid under this is the cutting (pit or bank) and is laid up
EDGE = 4.0           # a row runs this far past the last low cell
ROW_HALF = 6.0       # a row's corridor half width (rows overlap)
APRON_NEAR = 10.0    # an apron this near a removed deck's end goes with it
KEYS_ON_DECK = ("roads", "paths", "trams", "kerbs", "medians", "guards", "symbols", "markings", "surfaces",
                "carriage", "lines", "fills")


def _pairs(p):
    return [(p[i], p[i + 1]) for i in range(0, len(p) - 1, 2)]


def _stamp():
    keys = [VERSION, COVERS, STEP, LOW, EDGE, ROW_HALF, APRON_NEAR]
    return hashlib.sha1(json.dumps(keys, sort_keys=True).encode()).hexdigest()[:12]


class Grid:
    """game/map/terrain.json: the 10 m bare-earth grid, bilinear."""

    def __init__(self, map_dir):
        with open(os.path.join(map_dir, "terrain.json"), encoding="utf-8") as f:
            t = json.load(f)
        self.x0, self.z0, self.step, self.nx, self.h = t["x0"], t["z0"], t["step"], t["nx"], t["h"]

    def at(self, x, z):
        gx = (x - self.x0) / self.step
        gz = (z - self.z0) / self.step
        i, j = int(math.floor(gx)), int(math.floor(gz))
        fx, fz = gx - i, gz - j
        g = lambda a, b: self.h[b * self.nx + a]
        return (g(i, j) * (1 - fx) + g(i + 1, j) * fx) * (1 - fz) + (g(i, j + 1) * (1 - fx) + g(i + 1, j + 1) * fx) * fz


def _group_pieces(out, group):
    return [p for p in out["decks"]["pieces"] if p.get("g") == group]


def _undeck(out, c, pieces):
    """Take the deck group out: pieces, piers, aprons, `dk`, `bridge`, the lane graph's `br`."""
    g = c["group"]
    pts = [q for p in pieces for q in _pairs(p["p"])]
    if not pts:
        return {"pieces": 0}
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
    edges = 0
    for e in out["graph"]["edges"]:
        # the lane graph's edges carry the deck group they drive on (`dk`, lane_graph.gd `e_dk`): a
        # lane left on a deck that is gone is read at the ground's level, 6 m under the road
        if e.get("dk", -1) == g:
            del e["dk"]
            e["br"] = 0
            edges += 1
    return {"pieces": len(pieces), "piers": n_piers, "aprons": n_aprons, "items": moved, "edges": edges,
            "box": [round(v, 1) for v in (x0, z0, x1, z1)]}


def _cover(out, c, pieces, grid):
    """The ground between the cutting's two ends laid up to the decks' level; returns the record."""
    ax = c["axis"]
    d = (ax[0], ax[1])
    n = (-d[1], d[0])
    cx, cz = c["centre"]
    along = lambda q: (q[0] - cx) * d[0] + (q[1] - cz) * d[1]
    lo, hi = math.inf, -math.inf
    for p in pieces:
        w = max(p.get("l", 0), p.get("r", 0)) if p["k"] == "road" else 2.0
        for q in _pairs(p["p"]):
            lo = min(lo, along(q) - w)
            hi = max(hi, along(q) + w)
    lo -= c["pad"]
    hi += c["pad"]
    hs = sorted(h for p in pieces if p["k"] == "road" for h in p["h"])
    level = round(hs[len(hs) // 2], 2)
    rows = []
    s = lo
    while s <= hi + 1e-6:
        low_t = [t for t in range(-int(c["reach"]), int(c["reach"]) + 1, 2)
                 if grid.at(cx + d[0] * s + n[0] * t, cz + d[1] * s + n[1] * t) < LOW]
        if low_t:
            a, b = min(low_t) - EDGE, max(low_t) + EDGE
            p0 = (cx + d[0] * s + n[0] * a, cz + d[1] * s + n[1] * a)
            p1 = (cx + d[0] * s + n[0] * b, cz + d[1] * s + n[1] * b)
            rows.append({"p": [round(p0[0], 2), round(p0[1], 2), round(p1[0], 2), round(p1[1], 2)],
                         "h": [level, level], "l": ROW_HALF, "r": ROW_HALF, "k": "road", "s": 1, "rp": "cover_" + c["id"]})
        s += STEP
    out["fills"] += rows
    ends = []
    for s_end, sgn in ((lo, -1.0), (hi, 1.0)):
        ends.append([round(cx + d[0] * s_end, 1), round(cz + d[1] * s_end, 1)])
    return {"rows": len(rows), "level": level, "along": [round(lo, 1), round(hi, 1)], "ends": ends}


def apply(out, map_dir=None, force=False):
    if map_dir is None:
        map_dir = os.path.join(TOOLS, "..", "game", "map")
    old = out.get(KEY, {})
    if not force and old.get("stamp") == _stamp() and all(c["id"] in old.get("covers", {}) for c in COVERS):
        return "%d places (stamp %s: unchanged)" % (len(old["covers"]), old["stamp"])
    grid = None
    rec = {"v": VERSION, "stamp": _stamp(), "covers": {}}
    msgs = []
    out["fills"] = [f for f in out["fills"] if not str(f.get("rp", "")).startswith("cover_")]
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
        info = {}
        if c["kind"] == "cover":
            if grid is None:
                grid = Grid(map_dir)
            info.update(_cover(out, c, pieces, grid))
        info.update(_undeck(out, c, pieces))
        rec["covers"][c["id"]] = info
        msgs.append("%s: %s" % (c["id"], ", ".join("%s %s" % (k, v) for k, v in info.items() if k != "box")))
    out[KEY] = rec
    return "; ".join(msgs)


def check(out, map_dir):
    rec = out.get(KEY, {})
    bad = []
    if rec.get("stamp") != _stamp():
        bad.append("stamp %s is not today's %s" % (rec.get("stamp"), _stamp()))
    for c in COVERS:
        if c["id"] not in rec.get("covers", {}):
            bad.append("%s not applied" % c["id"])
        if _group_pieces(out, c["group"]):
            bad.append("%s: deck group %d still on the map" % (c["id"], c["group"]))
    return bad


def sweep(out, map_dir):
    """Decks over solid ground, and what the cutting leaves open beside roads: the list for F."""
    grid = Grid(map_dir)
    rows = []
    groups = {}
    for p in out["decks"]["pieces"]:
        if p["k"] != "road":
            continue
        groups.setdefault(p["g"], []).append(p)
    names = {}
    for r in out["roads"]:
        if r.get("dk", -1) >= 0 and r.get("name"):
            names.setdefault(r["dk"], r["name"])
    for g, ps in sorted(groups.items()):
        air = []
        for p in ps:
            for q, h in zip(_pairs(p["p"]), p["h"]):
                air.append(h - grid.at(*q))
        n_low = sum(1 for a in air if a < 2.0)
        rows.append((g, names.get(g, ""), len(air), round(max(air), 1), round(sum(air) / len(air), 1),
                     round(n_low / len(air), 2), [round(v) for v in ps[0]["p"][:2]]))
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
        print("group name pts max_air mean_air share_air<2m first_point")
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
