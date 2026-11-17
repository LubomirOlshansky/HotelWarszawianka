"""The obelisk's semicircle north of the Palace of Culture (F, 2026-11-17, Google Earth shots of
"Obelisk Granitowy 2" by the Palace's north-west fountain, and his helicopter shots of the game:
"here should be the obelisk, not some hole and the parking; remove the unneeded objects and walls").

The real place is level: a paved semicircle between the Palace's north wing and Park
Świętokrzyski, the 1955 granite obelisk at the middle of its straight side, a rectangular lawn
behind it towards ul. Wojciecha Fangory. The map had it as a pit with walls and a car park:
- OpenStreetMap's outline of the semicircle's two arcs and the short wall west of it came in as one
  2 m stone wall loop (`lines` wall_stone) standing round a band of ground;
- a service road ran from Fangory's footway into the band's west leg to a garage door (`garages`,
  `garage_doors`), with a zebra across it;
- the 10 m terrain grid dips about 7 m there (6.9-11.8 m against the square's 13.6-14.9 m), which
  map_builder.gd GRID_HOLD now holds up (the game's side of this fix).

This takes the walls, the ramp's road, its zebra and the garage door off the finished map data, so
the semicircle is open paving at the square's level. The obelisk itself is the landmark site
`obeliski` (landmarks/centre.gd OBELISKS). Nothing new is drawn here. On main's map run this, then
tools/bake_sectors.py and bake_city.gd.

    python3 -I tools/defilad_obelisk.py [MAP_DIR]          fixes game/map/centrum.json in place (idempotent)
    python3 -I tools/defilad_obelisk.py --dry [MAP_DIR]    prints what it would take, changes nothing
    python3 -I tools/defilad_obelisk.py --check [MAP_DIR]  exit 1 unless the map has it (verify.sh step `defiladobelisk`)

tools/bake_osm.py runs `apply` after zamek_ramps. Deterministic, standard library only.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))

KEY = "defilad_obelisk"
VERSION = 1
# The semicircle's centre (a circle fitted to the outer arc of the mapped wall loop) and how far
# its band and the ramp reach.
CENTRE = (-1165.0, 33.5)
WALL_REACH = 28.0    # a stone wall with a point this close to the centre is the loop's or its spur's
RAMP_REACH = 30.5    # a nameless service road wholly this close is the ramp to the garage door
ZEBRA_REACH = 27.0   # a zebra wholly this close crosses the ramp
DOOR_REACH = 20.0    # a garage (door) this close is the ramp's


def _pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def _d(q):
    return math.hypot(q[0] - CENTRE[0], q[1] - CENTRE[1])


def _wall(line):
    return line.get("k") == "wall" and line.get("ty") == "wall_stone" and \
        min(_d(q) for q in _pairs(line["p"])) < WALL_REACH and max(_d(q) for q in _pairs(line["p"])) < 60.0


def _ramp(road):
    return road.get("k") == "service" and not road.get("name") and all(_d(q) < RAMP_REACH for q in _pairs(road["p"]))


def _zebra(path):
    return path.get("k") == "zebra" and all(_d(q) < ZEBRA_REACH for q in _pairs(path["p"]))


def _door(c):
    return _d(c) < DOOR_REACH


def found(out):
    """What the place still holds: {kind: count}."""
    return {
        "walls": sum(1 for l in out.get("lines", []) if _wall(l)),
        "ramp roads": sum(1 for r in out.get("roads", []) if _ramp(r)),
        "zebras": sum(1 for p in out.get("paths", []) if _zebra(p)),
        "garages": sum(1 for g in out.get("garages", []) if _door((g[0], g[1]))),
        "garage doors": sum(1 for g in out.get("garage_doors", []) if _door(g["c"])),
    }


def apply(out, map_dir=None, dry=False):
    del map_dir
    if out.get(KEY, {}).get("v") == VERSION:
        return "already applied"
    left = found(out)
    if dry:
        return "would take " + ", ".join("%d %s" % (n, k) for k, n in left.items())
    out["lines"] = [l for l in out.get("lines", []) if not _wall(l)]
    out["roads"] = [r for r in out.get("roads", []) if not _ramp(r)]
    out["paths"] = [p for p in out.get("paths", []) if not _zebra(p)]
    out["garages"] = [g for g in out.get("garages", []) if not _door((g[0], g[1]))]
    out["garage_doors"] = [g for g in out.get("garage_doors", []) if not _door(g["c"])]
    out[KEY] = {"v": VERSION, "took": left}
    return "took " + ", ".join("%d %s" % (n, k) for k, n in left.items())


def check(out):
    if out.get(KEY, {}).get("v") != VERSION:
        return False, "not applied (python3 -I tools/defilad_obelisk.py)"
    left = {k: n for k, n in found(out).items() if n}
    if left:
        return False, "still on the semicircle: " + ", ".join("%d %s" % (n, k) for k, n in left.items())
    return True, "the obelisk's semicircle is open paving (no walls, ramp or garage door)"


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
    if "--dry" not in argv and msg != "already applied":
        with open(path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
