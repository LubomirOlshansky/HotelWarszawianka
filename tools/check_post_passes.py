"""Are the bake's post-passes a fixed point on the committed map?

The rule (docs/architecture/decisions.md): the map changes only through stamp-guarded, idempotent
post-passes on main's centrum.json, each listed in this file (`passes()` below). A new pass joins
that list in the same change.

Usage: python3 -I tools/check_post_passes.py [MAP_DIR] [--only=a,b] [--verbose]

bake_osm.py ends with passes that each run on a finished map (road_fixes, lane_tapers,
zamek_ramps, object_fixes, ..., lane_links, object_types, parked_thin last) and the same code is re-run on main's map whenever its rules
change. A pass that is not idempotent drifts the map every time it is run, so a re-bake and a
re-run disagree. This runs each pass once, alone, on a fresh copy of MAP_DIR/centrum.json (default
game/map; nothing is written) and fails when the map changed. It needs no raw data, only
centrum.json, terrain.json and lod2.* (tools/map_pack.py fetch). Verify step `postpasses`.
The from-scratch comparison with the raw data (Mac only) is `tools/diff_map.py`, see
docs/changes/2026-11-14-bake-reproduces-main.md.
"""
import copy
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def canon(d):
    return json.dumps(d, sort_keys=True, separators=(",", ":"))


def passes(map_dir):
    import road_fixes, lane_tapers, zamek_ramps, object_fixes, road_profiles, lane_links, parked_thin, object_types
    return [
        ("road_fixes", lambda d: road_fixes.apply(d)),
        ("lane_tapers", lambda d: lane_tapers.apply(d)),
        ("zamek_ramps", lambda d: zamek_ramps.apply(d, map_dir)),
        ("object_fixes", lambda d: object_fixes.apply(d)),
        ("road_profiles", lambda d: road_profiles.apply(d, map_dir)),
        ("lane_links", lambda d: lane_links.apply(d)),
        # W3 of the walls look (TD-25): on a typed map only its v2 fixes run, once (the stamp's v)
        ("object_types", lambda d: object_types.apply(d, map_dir)),
        ("parked_thin", lambda d: parked_thin.apply(d, map_dir)),
    ]


def changed_keys(a, b):
    return [k for k in sorted(set(a) | set(b)) if canon(a.get(k)) != canon(b.get(k))]


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    map_dir = os.path.abspath(args[0] if args else os.path.join(HERE, "..", "game", "map"))
    with open(os.path.join(map_dir, "centrum.json"), encoding="utf-8") as f:
        base = json.load(f)
    only = opt["only"].split(",") if "only" in opt else None
    bad = 0
    for name, run in passes(map_dir):
        if only and name not in only:
            continue
        d = copy.deepcopy(base)
        msg = run(d)
        keys = changed_keys(base, d)
        if opt.get("verbose") and msg:
            print("  %s: %s" % (name, str(msg)[:300]))
        print("%-13s %s" % (name, "fixed point" if not keys else "CHANGES the map: " + ", ".join(keys)))
        bad += bool(keys)
    print("check_post_passes: %s" % ("OK" if not bad else "FAIL (%d passes drift)" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
