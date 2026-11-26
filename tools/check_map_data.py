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
# Dworzec Centralny's car park ramp (F, 2026-11-08, tools/centralny_ramp.py): 45,290 trees (2 scanned
# trees whose trunks stood on the way out at the tunnel's mouth taken out). Before: 271752 / 45292.
# Marszałkowska by the art museum (F, 2026-11-08, road design area marsz_defilad): 45,316 trees (+26
# young columnar elms on the green strips either side of the tram track). Before: 271740 / 45290.
# Trees off the water and the roads (F, 2026-11-08, tools/object_fixes.py T1/T2): 44,991 trees (211 scanned
# trees standing in the river or a pond and 114 with no room off the drawn asphalt out; 1,033 more moved
# up to 3 m off it). Before: 271896 / 45316.
# Trees out of the walls (BACKLOG TR-1, 2026-11-09, tools/object_fixes.py T3): 44,862 trees (129 scanned
# trees standing inside a building outline 2.5 m or higher with no free spot within 3 m taken out; 52
# more moved out of the walls). Before: 269946 / 44991.
# Marszałkowska by Sienkiewicza (F, 2026-11-09, road design area marsz_sienkiewicza): 44,872 trees (+10
# young columnar elms on the west green strip between the tram and the southbound lanes). Before: 269172 / 44862.
# Parked cars (the city objects plan, step 8b, 2026-11-15, tools/parked_thin.py): counted from here on,
# 4 values a car (x, z, yaw, paint). 4,821 cars: of main's 4,893, 49 taken out of the pinched rows
# (every other car where the lane's free width is under 3.6 m) and 23 by a junction's mouth (within
# 15 m of a junction node, the box within 1 m of a lane's edge); 25 bays that reached into a lane
# moved 0.2-0.3 m out of it. Before: 19572.
EXPECTED = {"trees3d": 269232, "pois": 4572, "trees3d_crown": 44872, "parked": 19284}
# City objects plan step 5 (2026-11-14, tools/object_types.py): the share of fence metres whose type
# is only the default (`tc: default`) may only go down. The pass run on this map without OSM context
# (map evidence only, cloud 2026-11-14): 31.4 % of 188.2 km; walls 46.8 %, hedges 32.4 %; class km
# H 79.3, S 191.0, R 8.5, G 0; hard fences km deck 2.0, drop 3.3, railway 2.0, water 1.1. The full
# re-bake with tools/object_types.py fetch (Overpass context) should land lower: lower this then.
# W3 of the walls look (2026-11-15, tools/object_types.py v2): main's map, typed with the raw OSM
# export, had 9.1 % of 188.2 km of fence and 11.9 % of all 278.8 km of barrier lines (33.0 km) on
# the default; v2's fixes leave 9.1 % and 11.5 % (31.9 km: the square's planter edges 0.9 km, the
# stadium's perimeter 0.2 km). Both ratchets only go down. The walls doc's aim for W3 was 9 % of all
# lines: the bollard-row rule that was to carry most of it failed its 20-sample check (QUESTIONS).
# W10a, the first wall sweep (2026-11-21, object_types v3: 14 lines typed by id from judged photos,
# docs/streets/streets.json `places`): fence default 9.08 -> 9.04 % of 188.0 km, all three kinds
# 11.47 -> 11.29 % of 278.3 km (31.92 -> 31.41 km: Plac Grzybowski's five default plastered "walls"
# that are planter edges 0.44 km, the bar fence on a low wall by the square 0.08 km; the other eight
# typed lines were context, not default). Lowered on purpose to the new numbers.
FENCE_DEFAULT_MAX = 9.1
ALL_DEFAULT_MAX = 11.3
# W8 of the walls look (2026-11-20, tools/barrier_gates.py): the gates, counted from the lines' own
# `g` and `ge` (recorded on purpose; a change to the rules or the lines changes them): 761 lines;
# 326 gaps (834 m) where a footway crosses a fence, wall or hedge at OSM's gate node (object_fixes L4's
# strict test never saw them; 0 by a service road: clear_carriageways already cut every line out of a
# drive); 556 gate ends at the openings the bake cut, 244 by paths and 312 by service roads, all
# posts: 0 leaves (the photo check put 6 of 20 service openings as gates, under 16; LEAVES is off).
GATES_EXPECTED = {"lines": 761, "gaps": 326, "gap_m": 834.4, "ends": 556, "leaves": 0}
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
               "tools/bake_city.gd", "data/courts.json", "scripts/solidity.gd", "data/object_palette.json",
               "scripts/city_barriers.gd", "scripts/facade_kit.gd", "scripts/panel_rule.gd",
               "scripts/house_types.gd", "data/house_types.json"]
# TD-10 (2026-11-15): and every file of landmarks.gd's base chain, by name (bake_city.gd city_inputs).
CITY_INPUT_DIRS = ["scripts/landmarks"]
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
            print(f"unknown argument {arg!r}; use --trees3d=N, --pois=N, --trees3d_crown=N or --parked=N")
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

    barrier_types(data, report)
    barrier_gates(data, report)

    if gugik_missing():
        report("WARN", "GUGiK outputs", "missing: %s: run tools/setup_map.sh --full (it needs GUGiK's raw data in "
               "data/raw: tools/fetch_demo.py, docs/DEVELOPMENT.md \"Map data\")" % ", ".join(gugik_missing()))
    sectors(data, expected, report)
    print("map data: " + ("OK" if failures == 0 else f"{failures} FAILED"))
    return 0 if failures == 0 else 1


def barrier_types(data, report):
    """City objects plan step 5 (tools/object_types.py): every wall, fence and hedge carries ty, tc
    and sc; the fences' `tc: default` share stays at or under FENCE_DEFAULT_MAX and that of all
    three kinds at or under ALL_DEFAULT_MAX (W3; both only go down); the metres per type and the hard fences by reason are printed. Before the map is baked
    with the pass (its stamp `object_types` missing) this says so and passes."""
    kinds = ("fence", "wall", "hedge")
    bar = [l for l in data.get("lines", []) if l.get("k") in kinds]
    stamp = data.get("object_types")
    if not stamp:
        report("OK", "barrier types", "not in this centrum.json yet: the next full re-bake writes them "
               "(bake_osm.py runs tools/object_types.py); %d barrier lines" % len(bar))
        return
    untyped = sum(1 for l in bar if not all(k in l for k in ("ty", "tc", "sc")))
    metres = {}
    default = {"fence": 0.0, "all": 0.0}
    total = {"fence": 0.0, "all": 0.0}
    hard = {}
    for l in bar:
        p = l["p"]
        L = sum(math.dist((p[i], p[i + 1]), (p[i + 2], p[i + 3])) for i in range(0, len(p) - 3, 2))
        metres[(l["k"], l.get("ty"))] = metres.get((l["k"], l.get("ty")), 0.0) + L
        total["all"] += L
        if l.get("tc") == "default":
            default["all"] += L
        if l["k"] == "fence":
            total["fence"] += L
            if l.get("tc") == "default":
                default["fence"] += L
            if l.get("hz"):
                hard[l["hz"]] = hard.get(l["hz"], 0.0) + L
    share = 100.0 * default["fence"] / max(total["fence"], 1.0)
    report("OK" if untyped == 0 else "FAIL", "barrier types", "%d of %d lines typed (v%s, %s OSM ways, %s context outlines)"
           % (len(bar) - untyped, len(bar), stamp.get("v"), stamp.get("osm"), stamp.get("ctx")))
    report("OK" if share <= FENCE_DEFAULT_MAX else "FAIL", "fence default",
           "%.1f %% of %.1f km with tc default (at most %.1f %%); hard fences km: %s" % (
               share, total["fence"] / 1000, FENCE_DEFAULT_MAX,
               ", ".join("%s %.1f" % (k, v / 1000) for k, v in sorted(hard.items())) or "none"))
    share_all = 100.0 * default["all"] / max(total["all"], 1.0)
    report("OK" if share_all <= ALL_DEFAULT_MAX else "FAIL", "all default",
           "%.1f %% of %.1f km of walls, fences and hedges with tc default (at most %.1f %%; v2 fixes %s)" % (
               share_all, total["all"] / 1000, ALL_DEFAULT_MAX, stamp.get("fixes", "not run")))
    for kind in kinds:
        rows = sorted(((ty, m) for (k, ty), m in metres.items() if k == kind), key=lambda r: -r[1])
        print("     %s km by type: %s" % (kind, ", ".join("%s %.1f" % (ty, m / 1000) for ty, m in rows)))


def barrier_gates(data, report):
    """W8 of the walls look (tools/barrier_gates.py): the gaps and gate ends on the lines, counted from
    the lines themselves, against GATES_EXPECTED; by paths and by service roads from the pass's stamp
    (the line keeps no record of the way), which must add up to the same gaps and ends. Before the map
    has the pass (its stamp `barrier_gates` missing) this says so and passes."""
    stamp = data.get("barrier_gates")
    if not stamp:
        report("OK", "barrier gates", "not in this centrum.json yet (bake_osm.py runs tools/barrier_gates.py)")
        return
    lines = gaps = ends = leaves = 0
    gap_m = 0.0
    for l in data.get("lines", []):
        if "g" not in l and "ge" not in l:
            continue
        lines += 1
        for s, w, leaf in l.get("g", []):
            gaps += 1
            gap_m += w
            leaves += leaf != 0
        for v in l.get("ge", []):
            if v:
                ends += 1
                leaves += abs(v) == 2
    by = stamp.get("by", {})
    got = {"lines": lines, "gaps": gaps, "gap_m": round(gap_m, 1), "ends": ends, "leaves": leaves}
    sums = (by.get("gap_path", 0) + by.get("gap_service", 0) == gaps
            and by.get("open_path", 0) + by.get("open_service", 0) == ends)
    good = got == GATES_EXPECTED and sums
    report("OK" if good else "FAIL", "barrier gates",
           "%d lines, %d gaps %.0f m, %d gate ends, %d with leaves (by %s)%s%s" % (
               lines, gaps, gap_m, ends, leaves, ", ".join("%s %d" % kv for kv in sorted(by.items())),
               "" if got == GATES_EXPECTED else "; expected %s" % GATES_EXPECTED,
               "" if sums else "; the stamp's by does not add up to the gaps and ends"))


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
    changed = [p for p in city_inputs() if stamp.get("inputs", {}).get(p) != sha256_file(os.path.join(ROOT, "game", p))]
    if split_digest and stamp.get("split") != split_digest:
        changed.insert(0, "the sector split")
    if changed:
        return "STALE", "built from another %s: %s" % (", ".join(changed[:4]), rebuild)
    return "OK", "%d sector scenes, index.res and proxies.scn built from today's split, maps and scripts" % len(keys)


def city_inputs():
    """CITY_INPUTS and the .gd files of each CITY_INPUT_DIRS folder, sorted by name."""
    out = list(CITY_INPUTS)
    for d in CITY_INPUT_DIRS:
        folder = os.path.join(ROOT, "game", d)
        if os.path.isdir(folder):
            out += [d + "/" + f for f in sorted(os.listdir(folder)) if f.endswith(".gd")]
    return out


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
    trees, crowns, parked = 0, 0, 0
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
        cars = s.get("parked", [])
        for i in range(0, len(cars) - 3, 4):
            if (math.floor(cars[i] / size), math.floor(cars[i + 1] / size)) == k:
                parked += 1
    if missing:
        report("WARN", "sectors", "missing: %d sector files (%s): %s" % (len(missing), ", ".join(missing[:4]), SETUP))
        return
    report("OK" if trees * 6 == expected["trees3d"] else "FAIL", "sectors trees3d",
           f"{trees * 6} values over {files} sectors (expected {expected['trees3d']})")
    report("OK" if crowns == expected["trees3d_crown"] else "FAIL", "sectors trees3d_crown",
           f"{crowns} over the sectors (expected {expected['trees3d_crown']})")
    report("OK" if parked * 4 == expected["parked"] else "FAIL", "sectors parked",
           f"{parked * 4} values over the sectors (expected {expected['parked']})")
    pois = len(index.get("pois", []))
    report("OK" if pois == expected["pois"] else "FAIL", "index pois", f"{pois} (expected {expected['pois']})")
    report("OK" if index.get("graph", {}).get("edges") and index.get("palm") else "FAIL", "index graph, palm",
           "present" if index.get("graph", {}).get("edges") and index.get("palm") else "missing")
    report("OK" if state == "OK" else "WARN", "sector files", detail)
    state, detail = city_state(keys, digest)
    report("OK" if state == "OK" else "WARN", "prebuilt sectors", detail)


if __name__ == "__main__":
    sys.exit(main())
