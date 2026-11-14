---
name: bake-map
description: Runs or changes Around Warsaw's map-data bake chain (OpenStreetMap and GUGiK raw data in data/raw, the Python bakes in tools/ into game/map/centrum.json, ao.bin, lights.bin, water.bin, then the prebuilt city.scn) and checks its invariants. Use before editing any tools/bake_*.py, map_builder.gd, lane_graph.gd or anything under game/map/; for roads, bridge decks, ramps, the lane graph, trees, POIs; and before any download of map data.
---

# The map-data bake chain

docs/archive/DEVELOPMENT-full.md "Map data" holds the exact commands; this is the order, the rules and the checks.
If they disagree, DEVELOPMENT.md wins: fix this file.

## Rules

- **Downloads are pre-approved** (the user, 2026-10-30): list each one in the report or PR
  (source URL, size, time, licence, which bakes re-run). The raw data (`data/raw/`, ~5 GB) is gitignored and never committed.
  The public Overpass server is often busy (HTTP 502/504): retry with a back-off.
- Python tools run with `python3 -I` and use the standard library; the orthophoto overlays need
  Pillow (they run without `-I`). Don't install anything without asking.
- Loop 3d-1: the split and the prebuilt sectors (`index.json`, `index.res`, `proxies.scn`,
  `sectors/`, `shared/`) are derived and gitignored, and so are `lod2.*` and `terrain.json`
  (GUGiK's data alone; `tools/setup_map.sh --full` rebuilds them from `data/raw`); commit
  `centrum.json` and the `.bin` maps only (after a `--full` that changes lod2.* or terrain.json:
  `python3 -I tools/map_pack.py make`, publish its release, commit `tools/map_pack.json`; CI and
  the cloud fetch that pack). A fresh clone runs `tools/setup_map.sh` once; steps 7
  and 8 below write `sectors/split.stamp` and `sectors/city.stamp` (their inputs' SHA-256), which
  `check_map_data.py` compares to tell stale files by content.
- Never hand-edit generated files (`centrum.json`, `*.bin`, `index.json`, `sectors/*`, `index.res`,
  `proxies.scn`, `shared/*`). Change the bake, and
  keep exclusions as small, commented lists in the bake (like `GUGIK_NOT_TREES`).
- Licences travel with the data: OpenStreetMap is ODbL (the baked files are derived databases
  under ODbL), GUGiK trees are CC BY 4.0. A new source needs a line in CREDITS.md and the
  in-game credit; ask the user before adding one.

## Order (re-run everything below the step you changed)

Loop 3d-1 (the demo box, docs/archive/DEVELOPMENT-full.md "Map data"): `tools/bake_all.sh` runs the whole chain (~10 min).
It starts with `python3 tools/prepare_demo.py` (the raw downloads cut to `bake_osm.BBOX` into
`data/work/demo/`; `data/raw` is read-only) and `python3 -I tools/bake_terrain.py` (the terrain,
first: bake_osm reads it), runs bake_osm.py before and again after bake_gugik.py (the structures
read the box's LoD2), and the inputs below are `data/work/demo/*` (trees, OSM, ortho, sheets).
`tools/bake_traps.py` places police traps the graph gains. The steps below keep their order.

1. Trees (optional): `tools/bake_trees_gugik.py` → `data/raw/gugik/trees_area.json`.
2. OpenStreetMap: `tools/bake_osm.py` (imports `tools/bake_roads.py`: carriageways, kerbs,
   medians, markings, bridge decks, approaches and pits (`fills`), tunnels, garage doors;
   writes `graph`, the lane graph with each edge's `dk` / `tn`, and `pois`; loop 3b: then
   `tools/bake_structures.py` on the finished data: piers, retaining walls, tunnel walls and
   portals, garage doors, the Poniatowski towers' seats, buildings cut under decks, aprons,
   solid things cleared out of the lanes; loop 3b-2: `tools/bake_banks.py`, built and natural
   banks on `shore`, `sand`, `sandbars`, and `trees3d_crown`, the crowns' scale by the roads;
   then the fix passes (cycle_hang ... object_fixes, bus and tram stops, the content POIs) and,
   last, city objects step 5: `tools/object_types.py`, every wall, fence and hedge's type `ty`,
   sureness `tc`, class `sc`, hazard `hz` and height by setting `hs`, from the finished lines,
   OSM's full barrier tags and the land-use outlines in the raw export; the game reads none of
   it yet; `check_map_data.py` "barrier types" counts it, `verify.sh objecttypes` its selftest)
   → `game/map/centrum.json`. It reads
   `game/map/terrain.json` for the decks and `game/map/lod2.*` for the cuts (bake GUGiK
   first). Loop 3b (R2): the deck solver follows the decks measured in the 0.5 m surface model
   (`data/raw/demo/gugik/nmpt05`, `nmt1`: float32 GeoTIFF, read by `tools/geotiff.py`) when
   it is there; without it the chain solver runs alone.
3. GUGiK buildings and terrain: `tools/fetch_gugik.py` (downloads: list them), `tools/bake_gugik.py`
   → `lod2.bin`, `lod2.json`, `terrain.json`.
4. `tools/bake_ao.py game/map` → `ao.bin` (after 2 and 3).
5. `tools/bake_lights.py game/map` → `lights.bin` (after 2 and 3).
6. `tools/bake_water.py game/map` → `water.bin` (after 2).
7. Loop 3c: the split into 512 m sectors, `python3 -I tools/bake_sectors.py` → `index.json`,
   `sectors/<i>_<j>.json` (~1 s; DEVELOPMENT.md "Sectors and streaming"). A landmark that searches new
   areas in `landmarks.gd` needs its names or area in `bake_sectors.py` `SITE_NAMES` /
   `SITE_AREAS` (bake_city.gd fails otherwise).
8. The prebuilt city, **with a renderer** (`--headless` drops MultiMesh and texture data):
   `godot --path game --resolution 320x180 --script res://tools/bake_city.gd` → the 32
   `sectors/s_<i>_<j>.scn`, `proxies.scn`, `index.res`, `shared/*.res` (~16 s; loop 3d-2b: also
   each sector's pieces `sectors/s_<i>_<j>/<n>.res`, loaded one a frame, and its slices of the
   AO, lamp-light and surface maps inside its scene)
   (also needed after any change to `map_builder.gd`, `chunked_surface.gd`, `landmarks.gd`,
   `neon_signs.gd`, `sector_proxies.gd`; `tools/export_ios.sh` runs 7 and 8). `city.scn` is
   gone (loop 3c).
9. `tools/verify.sh --only=streaming` (a window opens): the sectors built from their files are
   the whole city (`--monolithic`) vertex for vertex, and the streamed city's pixels match it at
   10 spots.

## Invariants after a re-bake

```zsh
python3 -I tools/check_map_data.py      # trees3d 255468 values, trees3d_crown 42578, pois 3548, graph ≥ 95 % connected, palm (in centrum.json and over the sectors), sector files and prebuilt sectors fresh
godot --path game --resolution 320x180 --script res://tools/count_vertices.gd   # vertex budget
```

If the counts change on purpose (the map grows, a POI kind is added), update `EXPECTED` in
`tools/check_map_data.py` and the numbers in DEVELOPMENT.md "Map data" in the same change, and say
in the report what changed and why.

## Checks for roads, decks and the lane graph

- **First, the whole-map check** (loop 3a): `python3 -I tools/check_roads.py` runs rules C1-C10
  of docs/DEMO.md 4.5 (grades, joints, clearance under decks, piers, solids, deck ends, dropped
  tunnels and cuttings, lane steps, buildings through decks, landmarks by lanes) in ~4 s, prints
  every finding with its `--at=`, writes `shots/check_roads.json` and `shots/check_roads.png`
  (over the orthophoto) and exits 1 on a finding that `tools/check_roads_allow.json` doesn't
  allow (every allowed entry: rule, at, r, reason, source). `--map=DIR` checks a bake written
  elsewhere (bake into a scratch folder with `terrain.json`, `lod2.*` copied in), `--rules=`,
  `--all`. It is the `roads` step of `tools/verify.sh` (every rule FAILs since loop 3b). Run
  it before and after any change to the bakes or the height rules, and record the counts.
- The deck solver (bake_roads.py `solve_decks`, `_solve`) works on structure chains; its rules
  and constants (CHAIN_JOIN, EMBANK, BLUR_REACH, BLUR_FREE, TARGET_W, the clearances, DIP_MAX)
  are at the top of the file. `NW_DECK_DEBUG=X,Z,R` prints its nodes near a point
  (height/terrain/lower bound, P = pinned). An R3 failure stops the bake with the list of places.
- **The ground mesh** (loop 3d-2a): `godot --headless --path game --script res://tools/check_ground.gd`
  (`-- --whole` the old ground for a before count, `--sectors`, `--verbose`, `--dump=FILE` for
  `python3 tools/overlay_ground.py FILE OUT.png X Z HALF`, the ground's wireframe over the photo):
  the ground left out under the flat layers that cover it whole, no holes, the mesh on the height
  rule. Anything that changes what lies on the ground (a layer's depth bias or height, a new flat
  layer) must keep it OK; a new opaque layer on the ground can join `_cover_on` in `_build_parts`.
- Approaches and pits are `fills`: the ground corrected under a road's corridor; anything that
  reads heights (`map_builder.terrain_height`, check_roads' `Map.terrain`) must include them.
- In the game: `--debug-roads` draws decks, approaches, tunnels, lane heights and piers round
  the car; `tools/shots.sh --set=roads [--game=DIR] --tag=before|after` renders the road spots
  (`tools/road_spots.txt`).

- Over the aerial photo: `python3 tools/overlay_ortho.py OUT.png X Z HALF` (road areas red,
  kerbs cyan, lane centres magenta); `tools/overlay_landmarks.py` for landmark footprints.
  Write outputs to `shots/`. Coordinates are map metres, +x east, +z south, origin at the
  map's centre.
- In the game, on both city paths: `tools/shots.sh --set=... -- --at=X,Z --heading=DEG`, or
  `cd game && godot --path . --resolution 2532x1170 --fixed-fps 60 -- --nosave --free --at=X,Z
  --shots=240 --out=$PWD/../shots/NAME` (add `--prebuilt`).
- Heights: `map_builder.gd` `ground_height`, `drive_height` (the surface the car is on: a
  deck 5 m overhead is not the road) and `deck_height`. A road, lane or tram line passing
  through solid geometry, or a height jump where a ramp meets the ground, is a bake or
  deck-solver defect: find the class of defect and fix it for the whole map, with a check
  that counts it over the whole map before and after (not just the spot the user saw).
- **The drive check** (loop 3b): `godot --headless --path game --script res://tools/check_drive.gd`
  (`-- --prebuilt`, `--verbose`, `--dump=FILE`, `--debug=X,Z`) sweeps a car and a bus box along
  every lane against the colliders and drives the autopilot over 20 routes across the bridges
  and tunnels (height jumps > 0.3 m a frame); ~10 s. Steps `drive` and `drive-prebuilt` of
  `tools/verify.sh`. A collision is usually something OpenStreetMap puts in a carriageway (a
  fence across a gate, a kiosk, a parked car) or a lane wider than the road's width estimate:
  fix the class in `tools/bake_structures.py`, not the spot.
- Then `tools/verify.sh` (the traffic, race and job runs use the lane graph).

## Report

Which steps ran (with their printed counts), the invariants before → after, the vertex count
before → after, overlay and in-game shots (both paths) you looked at, and every download
made or proposed (source, size, time).
