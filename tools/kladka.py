#!/usr/bin/env python3
"""Kładka Magdaleny Abakanowicz, the footbridge from Karowa to Port Praski (F, 2026-11-20).

    python3 -I tools/kladka.py [MAP_DIR]          lays it out on game/map/centrum.json (idempotent)
    python3 -I tools/kladka.py --dry [MAP_DIR]    prints what it would do, changes nothing
    python3 -I tools/kladka.py --check [MAP_DIR]  exit 1 unless the map has it (verify.sh step `kladka`)

F (2026-11-20, three photos: the deck at dusk, the competition render, the deck over the river by
day): "model the pedestrian and cycle bridge to Port Praski, with our best approach, so it is alive".
OpenStreetMap maps the bridge (way 527506690, opened 28.03.2024, 452 m) as a living street on a
bridge, so the bake made it a 5.3 m road deck with concrete parapets, a dashed centre line, street
lamps and a bake pier every 25-30 m. The real one (Mapillary 2024-2026, awizonosz, masterofnoroad,
miguel_andrade, inwazjamb; warszawa19115.pl; Schüssler-Plan): a 6.9 m concrete deck on a rust-red
steel box girder ("paint that imitates corten") on seven white concrete supports, widening to 16.3 m
at its two bends where the wooden seating steps are, railings of rust posts and steel mesh under a
steel handrail with LED light, and no street lamps at all.

What this does, on the finished map data (bake_osm.py runs `apply` after defilad_obelisk; the same
code runs on a baked map, and tools/check_post_passes.py runs it again to see it is a fixed point):

- `decks.pieces` of the bridge's group (the one the living street's ways are laid on): tagged
  `kl` (map_builder.gd draws no slab, parapet or underside for them: the landmark site `kladka`,
  landmarks/kladka.gd, draws the whole bridge), the main deck and the north ramp widened to HALF
  each side (6.9 m), the south ramp to RAMP_HALF.
- two more pieces of that group over each bend, on the main deck's line, wider on the bay's side
  (`kl` 2): the bays' paving and steps stand on the deck's ground (the car, the walkers and the
  sitters find the deck there, not the river).
- `roads`: the living street's four ways hidden over their whole length (`hide`), so no asphalt and
  no centre line are drawn; they stay in the data (no lane is laid on them: the traffic never came).
- `decks.piers`: the bake's piers under the bridge go; its seven supports (PIERS, metres along the
  line) take their place, `kl` 1, so the boat race's course (tools/boat_course.py) and the
  boats' physics keep clear of the real ones; the landmark draws them.
- `kladka`: the stamp, with what the landmark reads: the centre line from the Powiśle end to the
  Praga end with the deck's height every few metres (`line`: x, z, y), the south ramp's (`ramp`),
  the bays, the supports and the Warsaw meridian's red line (metres along `line`).

Deterministic, standard library only. After it: tools/bake_sectors.py, bake_city.gd, and
tools/boat_course.py when the piers changed (game/data/boat_race.json).
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, HERE)

KEY = "kladka"
VERSION = 1
# The living street's ends (OpenStreetMap way 527506690 projected): Powiśle (on Wybrzeże
# Kościuszkowskie's pavement by Karowa) and Praga (by the Port Praski park).
WEST = (-25.6, -1247.8)
EAST = (303.9, -1553.9)
FIND = 3.0               # a way of the bridge has an end this near WEST or EAST
HALF = 3.45              # the deck's half width (6.9 m, warszawa19115.pl: "od 6,9 m")
RAMP_HALF = 2.4          # the south ramp down to the boulevard (the Mapillary panoramas: about 4.8 m)
STEP = 4.0               # the stamp's line has a point at least this often
# The bays at the bends (metres along the line from WEST): [s0, s1, side (+1 the right of the line,
# going east: south-east, upstream; -1 the north-west side), how much wider at the middle, seat rows
# (0: a boardwalk)]. The first is over the river's current where the photos have it: 16.3 m at its
# widest (19115), the stepped wooden seating on the south side facing the Old Town, the boardwalk
# with the long benches on the north side. The second at the bend over the Praga bank, about 11 m
# (the OpenStreetMap outline), seats on the north side towards the sunset.
BAYS = [
    [92.0, 192.0, 1, 5.0, 3],
    [92.0, 192.0, -1, 4.4, 0],
    [296.0, 362.0, -1, 3.0, 2],
    [296.0, 362.0, 1, 1.4, 0],
]
TAPER = 26.0             # a bay widens and narrows over this many metres at each end
# The seven supports ("na siedmiu podporach z żelbetu", 19115), metres along the line. Not
# surveyed: three river piers 70 m apart (one under the first bay, as in F's dusk photo, in its ring of
# timber piles), the fourth at the Praga water's edge (s 302 on the map), three on the Praga
# floodplain, so the Warsaw meridian's red line (21°01'39.26" E, s 373) falls between the second and
# third from Praga, as 19115 says it does. The Powiśle end rests on the boulevard (no pier in the river
# by the wall: the water starts at s 32).
PIERS = [90.0, 160.0, 230.0, 300.0, 345.0, 395.0, 430.0]
PIER_SIZE = (3.4, 2.2)   # across the deck, along it (the white columns in the Mapillary photos)
GIRDER = 2.6             # the box girder's depth under the deck's walk (to the pier's head)
CORRIDOR = 9.0           # a bake pier this near the line (between its ends) is the bridge's
MERIDIAN_LON = 21.0 + 1.0 / 60.0 + 39.25697 / 3600.0
LAT0, LON0 = 52.2340, 21.0240
M_PER_DEG_LON = 111320.0 * math.cos(math.radians(LAT0))


def _pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def _flat(pts, nd=2):
    out = []
    for p in pts:
        out.extend(round(v, nd) for v in p)
    return out


def _near(a, b, r):
    return math.hypot(a[0] - b[0], a[1] - b[1]) < r


def group(out):
    """The deck group the bridge's living street lies on (-1: none)."""
    for r in out.get("roads", []):
        if r.get("k") != "living_street" or not r.get("bridge") or int(r.get("dk", -1)) < 0:
            continue
        pts = _pairs(r["p"])
        if any(_near(pts[i], end, FIND) for i in (0, -1) for end in (WEST, EAST)):
            return int(r["dk"])
    return -1


def _length(pts):
    return sum(math.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]) for i in range(len(pts) - 1))


def _pieces(out, g):
    return [pc for pc in out.get("decks", {}).get("pieces", []) if int(pc.get("g", -1)) == g and int(pc.get("kl", 1)) != 2]


def _sample(pts, hs, step):
    """The line through pts with its heights, a point at least every `step` m: [(x, z, y)]."""
    out = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        n = max(1, int(math.ceil(math.hypot(b[0] - a[0], b[1] - a[1]) / step)))
        for k in range(n):
            t = k / n
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, hs[i] + (hs[i + 1] - hs[i]) * t))
    out.append((pts[-1][0], pts[-1][1], hs[-1]))
    return out


def _cum(line):
    c = [0.0]
    for i in range(1, len(line)):
        c.append(c[-1] + math.hypot(line[i][0] - line[i - 1][0], line[i][1] - line[i - 1][1]))
    return c


def at(line, cum, s):
    """(x, z, y, dx, dz) at s metres along the line."""
    s = min(max(s, 0.0), cum[-1])
    k = 0
    while k < len(line) - 2 and cum[k + 1] < s:
        k += 1
    seg = max(cum[k + 1] - cum[k], 1e-6)
    t = (s - cum[k]) / seg
    a, b = line[k], line[k + 1]
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t,
            (b[0] - a[0]) / seg, (b[1] - a[1]) / seg)


def layout(out):
    """The bridge as the map has it: (group, main line [(x, z, y)], south ramp, north ramp piece,
    main piece, south ramp pieces) or None."""
    g = group(out)
    if g < 0:
        return None
    pcs = _pieces(out, g)
    if not pcs:
        return None
    main = max(pcs, key=lambda pc: _length(_pairs(pc["p"])))
    mp = _pairs(main["p"])
    north = None
    south = []
    for pc in pcs:
        if pc is main:
            continue
        pp = _pairs(pc["p"])
        if _near(pp[0], WEST, FIND) and _near(pp[-1], mp[0], FIND):
            north = pc
        else:
            south.append(pc)
    if north is None:
        return None
    npts = _pairs(north["p"])
    line = _sample(npts[:-1] + mp, list(north["h"][:-1]) + list(main["h"]), STEP)
    # The south ramp: its pieces joined end to end, from the boulevard to where it meets the deck.
    south.sort(key=lambda pc: _pairs(pc["p"])[0][0])
    rp, rh = [], []
    for pc in south:
        pp = _pairs(pc["p"])
        if rp and _near(rp[-1], pp[0], 0.5):
            pp, hh = pp[1:], list(pc["h"][1:])
        else:
            hh = list(pc["h"])
        rp.extend(pp)
        rh.extend(hh)
    ramp = _sample(rp, rh, STEP) if len(rp) >= 2 else []
    return g, line, ramp, north, main, south


def meridian_s(line, cum):
    x = (MERIDIAN_LON - LON0) * M_PER_DEG_LON
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        if (a[0] - x) * (b[0] - x) <= 0.0 and a[0] != b[0]:
            return round(cum[i] + (cum[i + 1] - cum[i]) * (x - a[0]) / (b[0] - a[0]), 1)
    return -1.0


def _bay_piece(line, cum, g, bay):
    s0, s1, side, extra, _rows = bay
    pts, hs = [], []
    s = s0
    while s < s1 + 0.01:
        x, z, y, _dx, _dz = at(line, cum, min(s, s1))
        pts.append((x, z))
        hs.append(y)
        s += STEP
    reach = HALF + extra
    return {"p": _flat(pts, 2), "h": [round(h, 2) for h in hs], "l": round(reach if side < 0 else 0.5, 2),
            "r": round(reach if side > 0 else 0.5, 2), "g": g, "k": "path", "o": [3] * len(pts), "kl": 2}


def _corridor(line, cum, p, r):
    """Whether p lies within r of the line, between its ends."""
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        ab = (b[0] - a[0], b[1] - a[1])
        l2 = ab[0] * ab[0] + ab[1] * ab[1]
        if l2 < 1e-9:
            continue
        u = ((p[0] - a[0]) * ab[0] + (p[1] - a[1]) * ab[1]) / l2
        if 0.0 <= u <= 1.0 and math.hypot(p[0] - a[0] - ab[0] * u, p[1] - a[1] - ab[1] * u) < r:
            return True
    return False


def apply(out, map_dir=None, dry=False, terrain=None):
    if out.get(KEY, {}).get("v") == VERSION:
        return "already applied"
    found = layout(out)
    if found is None:
        return "no bridge found (the living street between Karowa and Port Praski)"
    g, line, ramp, north, main, south = found
    cum = _cum(line)
    old = [p for p in out["decks"].get("piers", []) if _corridor(line, cum, p["c"], CORRIDOR)]
    if dry:
        return "would tag %d pieces of group %d, add %d bays, hide 4 ways, put %d supports for %d bake piers" % (
            1 + 1 + len(south), g, len(BAYS), len(PIERS), len(old))
    if terrain is None and map_dir is not None:
        import cycle_hang
        terrain = cycle_hang.terrain_of(map_dir, out)
    for pc in [north, main]:
        pc["l"] = pc["r"] = HALF
        pc["kl"] = 1
    for pc in south:
        pc["l"] = pc["r"] = RAMP_HALF
        pc["kl"] = 1
    out["decks"]["pieces"].extend(_bay_piece(line, cum, g, b) for b in BAYS)
    hidden = 0
    for r in out.get("roads", []):
        if r.get("k") == "living_street" and int(r.get("dk", -1)) == g:
            r["hide"] = [[0.0, round(_length(_pairs(r["p"])) + 1.0, 1)]]
            hidden += 1
    keep = [p for p in out["decks"].get("piers", []) if not _corridor(line, cum, p["c"], CORRIDOR)]
    piers = []
    for s in PIERS:
        x, z, y, dx, dz = at(line, cum, s)
        foot = terrain(x, z) - 1.0 if terrain else y - 12.0
        near = [p for p in old if _near(p["c"], (x, z), 30.0)]
        if near:
            foot = min(foot, min(float(p["y"][0]) for p in near))
        piers.append({"c": [round(x, 2), round(z, 2)], "d": [round(dx, 4), round(dz, 4)],
                      "s": [PIER_SIZE[0], PIER_SIZE[1]], "y": [round(foot, 2), round(y - GIRDER, 2)],
                      "k": "pier", "kl": 1})
    out["decks"]["piers"] = keep + piers
    out[KEY] = {"v": VERSION, "g": g, "line": _flat(line, 2), "ramp": _flat(ramp, 2), "half": HALF,
                "ramp_half": RAMP_HALF, "bays": BAYS, "taper": TAPER, "piers": PIERS,
                "girder": GIRDER, "meridian": meridian_s(line, cum)}
    return "group %d: %d pieces tagged, %d bays, %d ways hidden, %d bake piers -> %d supports, meridian at %.1f m" % (
        g, 2 + len(south), len(BAYS), hidden, len(old), len(PIERS), out[KEY]["meridian"])


def check(out):
    st = out.get(KEY, {})
    if st.get("v") != VERSION:
        return False, "not applied (python3 -I tools/kladka.py)"
    g = int(st["g"])
    pcs = [pc for pc in out.get("decks", {}).get("pieces", []) if int(pc.get("g", -1)) == g]
    tagged = [pc for pc in pcs if pc.get("kl")]
    if len(tagged) != len(pcs):
        return False, "%d of the bridge's %d deck pieces untagged" % (len(pcs) - len(tagged), len(pcs))
    if sum(1 for pc in pcs if pc.get("kl") == 2) != len(BAYS):
        return False, "the bays' pieces are missing"
    ways = [r for r in out.get("roads", []) if r.get("k") == "living_street" and int(r.get("dk", -1)) == g]
    if not ways or any(not r.get("hide") for r in ways):
        return False, "the living street's asphalt is drawn again"
    sup = [p for p in out["decks"].get("piers", []) if p.get("kl")]
    if len(sup) != len(PIERS):
        return False, "%d supports, not %d" % (len(sup), len(PIERS))
    line = [tuple(st["line"][i:i + 3]) for i in range(0, len(st["line"]) - 2, 3)]
    cum = _cum(line)
    stray = [p for p in out["decks"]["piers"] if not p.get("kl") and _corridor(line, cum, p["c"], CORRIDOR)]
    if stray:
        return False, "%d bake piers under the bridge again" % len(stray)
    if not (st["piers"][-3] < st["meridian"] < st["piers"][-2]):
        return False, "the meridian at %.1f m is not between the second and third supports from Praga" % st["meridian"]
    return True, "the footbridge: %d pieces, %d bays, %d supports, %.0f m, the meridian at %.1f m" % (
        len(pcs), len(BAYS), len(sup), cum[-1], st["meridian"])


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    map_dir = os.path.abspath(args[0] if args else os.path.join(ROOT, "game", "map"))
    path = os.path.join(map_dir, "centrum.json")
    with open(path, encoding="utf-8") as f:
        out = json.load(f)
    if "--check" in argv:
        ok, msg = check(out)
        print("%s: %s" % (KEY, msg))
        return 0 if ok else 1
    msg = apply(out, map_dir, dry="--dry" in argv)
    print("%s: %s" % (KEY, msg))
    if "--dry" not in argv and msg != "already applied" and not msg.startswith("no bridge"):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
