#!/usr/bin/env python3
"""Check the baked map data and the prebuilt city without opening Godot.

    python3 -I tools/check_map_data.py [--trees3d=N] [--pois=N] [--fresh]

Checks game/map/centrum.json against the counts the last full bake produced (a re-bake
that changes them must say so and update EXPECTED below in the same change), that the
lane graph and the Palm are present. Loop 3c: the same counts over the sectors
(tools/bake_sectors.py: index.json and sectors/<i>_<j>.json; a point thing near a border is in
both sectors' files, so each sector counts the ones standing in its own square), every
sector's file and prebuilt scene there.

Loop 3d-1: the split and the prebuilt sectors (index.json, sectors/*, index.res, proxies.scn,
shared/) are derived and not committed: when they are missing this says "missing: run
tools/setup_map.sh" (a WARN, not a FAIL). Freshness is by content: bake_sectors.py writes
sectors/split.stamp (the SHA-256 of what it read) and bake_city.gd writes sectors/city.stamp
(the split's digest and the SHA-256 of the maps and scripts it builds from); a stamp that
doesn't match today's files is a WARN (stale: re-run, see docs/DEVELOPMENT.md "Sectors and streaming").

--fresh: only the derived files, quietly: exit 0 when the split and the prebuilt sectors are
there and match their inputs, 3 when either is missing or stale (tools/setup_map.sh
--if-needed and tools/verify.sh use it).

Prints one line per check: OK / WARN / FAIL. Exits 1 if any check fails.
Reads only; writes nothing.
"""
import hashlib
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map")

# The counts after the last full bake (loop 1, 2026-10-28): trees3d holds 6 values per
# tree (12,554 trees), pois are hospitals, beaches, parks, kebab stands, addresses, etc.
# Loop 3b-2: trees3d_crown, one crown scale per scanned tree (12,554: 75 by the roads, up to
# 100 in the parks; bake_osm.py crown_scales).
# Loop 3d-1: the demo box (20.1 km² with the east edge at 21.056, docs/DEVELOPMENT.md "Map data"): 42,578
# scanned trees (the GUGiK sheets cover the whole box, so no OSM trees are left), 3,548 pois.
# Before: 75324 / 1020 / 12554 on the first box; 231420 / 3069 / 38570 with the east edge at 21.050.
# Map north (2026-10-31): the box and its north extension (Rondo Radosława, Arkadia, Forest, Andersa
# to Dworzec Gdański; bake_osm.BBOX_NORTH, 1.04 km²): 44,832 scanned trees (+2,254), 3,601 pois (+53:
# addresses 3,332 -> 3,378, a hospital, a kebab place, a park, four squares). Before: 255468 / 3548 / 42578.
# Content POIs (2026-10-31, tools/bake_street_pois.py, appended after the older ones): 4,572 pois
# (+971: convenience 260, subway_entrance 84, bicycle_rental 92, 11 places' addresses, scooter_zone 56,
# scooter 468; tools/check_pois.py checks them). Before: 3601.
# G8 (2026-11-01): 4,571: one lying Leżak at the Centralny stop had no clear spot once its shelter stood on the kerb (tools/snap_props.py).
# Krajobraz places (2026-11-02, tools/planted_trees.py, appended after the scanned trees): 44,854
# trees (+22 young trees in ul. Bracka's woonerf, planted after the scan). Before: 268992 / 44832.
# Krajobraz K5 (2026-11-02, tools/plaza_gardens.py): 44,975 trees (+121 in the plazas of Skyliner,
# Generation Park and Mennica Legacy Tower; 18+21+12 beds in areas, 11 benches). Before: 269124 / 44854.
# Krajobraz K3 (2026-11-02, planted_trees.py PLACE varso): 44,981 (+6 young trees in Chmielna's
# bare beds by Varso Place). Before: 269850 / 44975.
# Krajobraz K2 (2026-11-02, planted_trees.py PLACE chmielna): 45,046 (+65 young trees in ul.
# Chmielna's tree pits, 85 in its band). Before: 269886 / 44981. Then 45,045: the K5 plaza tree
# through a lying scooter by Skyliner taken out (plaza_gardens.py keeps POI_GAP from POIs now).
# Skwer Linearny na Złotej (F, 2026-11-02, tools/car_free.py): 45,081 (+36 young limes on Złota's
# new park). Before: 270270 / 45045.
# Krajobraz K9 (2026-11-02, planted_trees.py PLACE stadion): 45,161 (+80 trees round the Stadion
# Narodowy: avenue rows, pollarded willows). Before: 270486 / 45081.
# Map review C (2026-11-02): 4,572 again: with the one-lane one-way streets at their real width that
# Leżak finds a clear spot by the Centralny stop. 45,159 trees: two young trees on ul. Pereca by the Skyliner
# plaza drop where the two-lane street is 7 m now and their trunks would touch the carriageway.
# Before: 270966 / 4571 / 45161.
# Krajobraz K6 (2026-11-02, planted_trees.py PLACEs norblin and browary): 45,176 trees (+5 candelabra
# planes in Fabryka Norblina's court, +12 lindens, birches and maples in Browary's Central Garden).
# Before: 270954 / 45159.
# Norblin and Browary courts from the Mac's photo reports (2026-11-02, planted_trees.py): 45,192.
# The first K6 pass's 17 trees (5 planes in the wrong block's court, 12 on the yard west of the
# garden) taken out; the court of "Plater" and the west court of "Galwan" carved open (COURTS);
# +4 candelabra planes, +3 on Żelazna, +3 along the glass street, +2 in the west court, +17 in
# Browary's Central Garden (22 with the scan's 5), +4 by Willa Schielego. Before: 271056 / 45176.
# Plac Centralny (F's photos, 2026-11-05, tools/plac_centralny.py): 45,289 trees (+97 young locusts, ginkgos,
# ashes and magnolias on the new square's lawns and axis; 10 beds in surfaces, 6 benches). Before: 271152 / 45192.
# Plac Pięciu Rogów (F's photos + the ortho, 2026-11-06, tools/car_free.py EXTRA_XZ): 45,292 trees (+3
# field maples the scan lacks: one by Zgoda, two at the Krucza end). Before: 271734 / 45289.
EXPECTED = {"trees3d": 271752, "pois": 4572, "trees3d_crown": 45292}
# docs/DEMO.md 7 row 7: the lane graph's strongly connected share at least this.
SCC_SHARE = 0.95

# Loop 3d-1: what tools/bake_sectors.py reads to split the map (map-dir files, and the script
# itself; the same names as its SPLIT_INPUTS), and what tools/bake_city.gd builds the prebuilt
# sectors from besides the split (res:// paths: its CITY_INPUTS; the split itself is covered by
# split.stamp's digest). Shaders are referenced by path, so they need no rebuild.
SPLIT_INPUTS = ["centrum.json", "lod2.bin", "lod2.json"]
CITY_INPUTS = ["map/lod2.bin", "map/terrain.json", "map/ao.bin", "map/lights.bin", "map/water.bin",
               "scripts/map_builder.gd", "scripts/chunked_surface.gd", "scripts/neon_signs.gd",
               "scripts/landmarks.gd", "scripts/sector_proxies.gd", "scripts/models.gd",
               "scripts/pixel_font.gd", "scripts/index_pack.gd", "scripts/city_maps.gd",
               "tools/bake_city.gd", "data/courts.json"]
SETUP = "run tools/setup_map.sh"
# Loop 3d-1 (the user's decision): from GUGiK's data alone, derived like the split: tools/setup_map.sh
# --full rebuilds them from data/raw (tools/fetch_demo.py's downloads and the LoD2 package).
GUGIK_DERIVED = ["lod2.bin", "lod2.json", "terrain.json"]


def main() -> int:
    expected = dict(EXPECTED)
    if "--fresh" in sys.argv[1:]:
        state = freshness()
        print("derived map files: %s" % state[1])
        return 0 if state[0] == "OK" else 3
    for arg in sys.argv[1:]:
        key, _, value = arg.lstrip("-").partition("=")
        if key in expected and value.isdigit():
            expected[key] = int(value)
        else:
            print(f"unknown argument {arg!r}; use --trees3d=N, --pois=N or --trees3d_crown=N")
            return 2
    failures = 0

    def report(status: str, name: str, detail: str) -> None:
        nonlocal failures
        if status == "FAIL":
            failures += 1
        print(f"{status:<4} {name}: {detail}")

    path = os.path.join(MAP, "centrum.json")
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        report("FAIL", "centrum.json", f"can't read {path}: {e}")
        return 1

    for key, want in expected.items():
        got = len(data.get(key, []))
        report("OK" if got == want else "FAIL", key, f"{got} values (expected {want})")

    graph = data.get("graph")
    if isinstance(graph, dict) and graph.get("edges"):
        scc = graph.get("scc", [])
        share = sum(scc) / max(len(scc), 1)
        report("OK" if share >= SCC_SHARE else "FAIL", "graph",
               "%d of %d nodes strongly connected (%.1f %%, at least %.0f %%), %d directed edges, "
               "%d signal controllers, %d portals" % (sum(scc), len(scc), share * 100, SCC_SHARE * 100, len(graph["edges"]),
                                                      len(graph.get("ctrl", [])), len(graph.get("portals", []))))
    else:
        report("FAIL", "graph", "missing or empty (the lane graph: traffic, races and jobs need it)")

    palm = data.get("palm")
    if palm:
        report("OK", "palm", f"present at {palm[0]}, {palm[1]}")
    else:
        report("FAIL", "palm", "missing (bake_osm.py writes it from GUGIK_NOT_TREES)")

    if gugik_missing():
        report("WARN", "GUGiK outputs", "missing: %s: run tools/setup_map.sh --full (it needs GUGiK's raw data in "
               "data/raw: tools/fetch_demo.py, docs/DEVELOPMENT.md \"Map data\")" % ", ".join(gugik_missing()))
    sectors(data, expected, report)
    print("map data: " + ("OK" if failures == 0 else f"{failures} FAILED"))
    return 0 if failures == 0 else 1


def sha256_file(path):
    """The file's SHA-256 (hex), or "" when it isn't there."""
    if not os.path.exists(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def split_state():
    """("OK" | "MISSING" | "STALE", detail, split digest) for index.json and sectors/*.json."""
    index_path = os.path.join(MAP, "index.json")
    if not os.path.exists(index_path):
        return "MISSING", "missing: no game/map/index.json (the sector split): " + SETUP, ""
    stamp = read_json(os.path.join(MAP, "sectors", "split.stamp"))
    if not isinstance(stamp, dict):
        return "STALE", "no sectors/split.stamp (split before loop 3d-1): run python3 -I tools/bake_sectors.py", ""
    now = {f: sha256_file(os.path.join(MAP, f)) for f in SPLIT_INPUTS}
    now["bake_sectors.py"] = sha256_file(os.path.join(ROOT, "tools", "bake_sectors.py"))
    changed = [f for f, h in sorted(now.items()) if stamp.get("inputs", {}).get(f) != h]
    if changed:
        return "STALE", "made from another %s: run python3 -I tools/bake_sectors.py" % ", ".join(changed), ""
    return "OK", "made from today's %s" % ", ".join(sorted(now)), stamp.get("digest", "")


def city_state(keys, split_digest):
    """("OK" | "MISSING" | "STALE", detail) for the prebuilt sectors, index.res, proxies.scn."""
    scenes = [os.path.join(MAP, "sectors", "s_%d_%d.scn" % k) for k in keys]
    scenes += [os.path.join(MAP, "index.res"), os.path.join(MAP, "proxies.scn"), os.path.join(MAP, "shared")]
    absent = [os.path.relpath(p, MAP) for p in scenes if not os.path.exists(p)]
    if absent:
        return "MISSING", "missing: %s%s: %s" % (", ".join(absent[:4]), " and %d more" % (len(absent) - 4) if len(absent) > 4 else "", SETUP)
    rebuild = ("rebuild them with a renderer (godot --path game --resolution 320x180 --script "
               "res://tools/bake_city.gd, never --headless)")
    stamp = read_json(os.path.join(MAP, "sectors", "city.stamp"))
    if not isinstance(stamp, dict):
        return "STALE", "no sectors/city.stamp (built before loop 3d-1): " + rebuild
    changed = [p for p in CITY_INPUTS if stamp.get("inputs", {}).get(p) != sha256_file(os.path.join(ROOT, "game", p))]
    if split_digest and stamp.get("split") != split_digest:
        changed.insert(0, "the sector split")
    if changed:
        return "STALE", "built from another %s: %s" % (", ".join(changed[:4]), rebuild)
    return "OK", "%d sector scenes, index.res and proxies.scn built from today's split, maps and scripts" % len(keys)


def gugik_missing():
    """Loop 3d-1: the GUGiK-only bake outputs (derived, not committed) that aren't there."""
    return [f for f in GUGIK_DERIVED if not os.path.exists(os.path.join(MAP, f))]


def freshness():
    """--fresh: the GUGiK outputs, the split, then the prebuilt sectors."""
    if gugik_missing():
        return "MISSING", "missing: %s: run tools/setup_map.sh --full (it needs GUGiK's raw data)" % ", ".join(gugik_missing())
    state, detail, digest = split_state()
    if state != "OK":
        return state, detail
    index = read_json(os.path.join(MAP, "index.json")) or {}
    keys = [tuple(k) for k in index.get("sectors", {}).get("keys", [])]
    missing = [k for k in keys if not os.path.exists(os.path.join(MAP, "sectors", "%d_%d.json" % k))]
    if not keys or missing:
        return "MISSING", "sector files missing: " + SETUP
    state, detail = city_state(keys, digest)
    return state, ("split OK; " if state == "OK" else "") + detail


def sectors(data, expected, report):
    """Loop 3c: the sector split and the prebuilt sectors (loop 3d-1: derived, maybe missing)."""
    state, detail, digest = split_state()
    if state == "MISSING":
        report("WARN", "sector split", detail)
        return
    index_path = os.path.join(MAP, "index.json")
    index = read_json(index_path)
    if not isinstance(index, dict):
        report("FAIL", "index.json", f"can't read {index_path} (run python3 -I tools/bake_sectors.py)")
        return
    keys = [tuple(k) for k in index.get("sectors", {}).get("keys", [])]
    if not keys:
        report("FAIL", "index.json", "no sector grid (run python3 -I tools/bake_sectors.py)")
        return
    size = float(index["sectors"].get("size", 512.0))
    trees, crowns = 0, 0
    files, missing = 0, []
    for k in keys:
        s = read_json(os.path.join(MAP, "sectors", "%d_%d.json" % k))
        if not isinstance(s, dict):
            missing.append("%d_%d.json" % k)
            continue
        files += 1
        real = s.get("trees3d", [])
        crown = s.get("trees3d_crown", [])
        for i in range(0, len(real) - 5, 6):
            if (math.floor(real[i] / size), math.floor(real[i + 1] / size)) == k:
                trees += 1
                crowns += 1 if i // 6 < len(crown) else 0
    if missing:
        report("WARN", "sectors", "missing: %d sector files (%s): %s" % (len(missing), ", ".join(missing[:4]), SETUP))
        return
    report("OK" if trees * 6 == expected["trees3d"] else "FAIL", "sectors trees3d",
           f"{trees * 6} values over {files} sectors (expected {expected['trees3d']})")
    report("OK" if crowns == expected["trees3d_crown"] else "FAIL", "sectors trees3d_crown",
           f"{crowns} over the sectors (expected {expected['trees3d_crown']})")
    pois = len(index.get("pois", []))
    report("OK" if pois == expected["pois"] else "FAIL", "index pois", f"{pois} (expected {expected['pois']})")
    report("OK" if index.get("graph", {}).get("edges") and index.get("palm") else "FAIL", "index graph, palm",
           "present" if index.get("graph", {}).get("edges") and index.get("palm") else "missing")
    report("OK" if state == "OK" else "WARN", "sector files", detail)
    state, detail = city_state(keys, digest)
    report("OK" if state == "OK" else "WARN", "prebuilt sectors", detail)


if __name__ == "__main__":
    sys.exit(main())
