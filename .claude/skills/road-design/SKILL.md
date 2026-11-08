---
name: road-design
description: Rebuilds a stretch of Around Warsaw's streets from zero with the road design system (docs/design/road-design-system.md, tools/road_design.py): measure the real street on the orthophoto and OSM lane tags, write its cross-sections and junctions as a spec in docs/roads/AREA.json, generate kerbs, carriageway, medians, lane lines, arrows, zebras and cycle crossings, and check with flat plots and before/after game shots. Use when a street or junction looks broken (jagged asphalt, lines that stop and restart, kerb jumps, wedges at joins) and patching the OSM ribbons has not fixed it, or when asked to redesign, rebuild or re-lay roads, lanes or crossings.
---

# Road design: a street from its cross-section, not from its OSM ways

Why and how it works: docs/design/road-design-system.md (sections 1-5). The first area was the
Palace of Culture block (`docs/roads/palace.json`, results in docs/design/road-design-palace-results.md).
**F, 2026-11-07: main as base.** Outside the Palace block, keep main's roads and fix only real bugs;
the area 3-7 redesigns lost to main in every scene (they dropped arrows, medians, islands, cycle paths).
A new design needs F's ask and must carry every such OSM detail over. One area per thread and PR. Opus for the measuring and the junctions (map geometry); Sonnet can extend a
spec that already has its pattern (another mid-block stretch, another opening).

## The loop

1. **Needs.** `python3 -I tools/road_design.py AREA --needs OSM.json` (or read the tags of the street's
   ways from `data/raw/` / Overpass): lanes, `turn:lanes`, bus and cycle lanes, `placement`, crossings,
   side streets and U-turn links (`*_link` ways crossing the median). Write them down per street, in
   order along it.
2. **Photo.** The GUGiK orthophoto (0.1 m) is fetched on the Mac (WMS
   `mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/HighResolution`, layer `Raster`, EPSG:4326; the cloud VM is not on the
   allowlist) into `refs/road_design/` with a `tiles.json` of map-metre bounds. Then:
   `python3 -I tools/road_design_plot.py mosaic refs/road_design 0.125 build/ortho.png`.
3. **Axis.** One axis per street: the tram midline, the median's middle or the centre line, as two or
   more map points (x east, z south; map coordinates from `tools/road_design.py`'s LAT0/LON0). A street
   that meets a junction starts or ends exactly at the junction's centre.
4. **Measure.** `python3 -I tools/road_design_plot.py unroll build/ortho.png OUT.png AX,AZ BX,BZ S0 S1 30`
   and read off, every 50-100 m: each carriageway's kerbs (offsets, + is right of the axis), the
   median or tram bed, the cycle lanes, where the section changes, the crossings' s, the stop lines.
   Tall buildings lean over the street in the photo: take those stretches from OSM.
4b. **Seed (faster).** `python3 -I tools/road_design_seed.py --street NAME --box X0,Z0,X1,Z1 --id ID
   [--axis '[[x,z],[x,z]]']` drafts the street from the map's ribbons (carriageways, lane counts,
   tram/island median, zebras). Give it the axis (tram midline etc.) when you have one. A draft, never the
   answer: lane counts double at ribbon joins and junction ribbons bleed in; fix it on the ortho overlay.
   Carriageways closer than 1 m have no island between them, so a median that starts mid-street is two
   carriageways that move apart (the count of carriageways is the same in every section).
5. **Spec.** `docs/roads/AREA.json` (format in the tool's docstring): streets (axis, sections with
   `cw` lanes `d`/`k`/`t`/`w` and `med`, `crossings`, `openings` for side roads and driveways, `gaps`
   for median breaks) and junctions (arms with zebra `x`/`w` and cycle crossing `bx`/`bw`, corner
   radius `r`). Kerbs stay straight; a lane count change is paint (lane lesson, 2026-11-05).
6. **Check.** `python3 -I tools/road_design.py AREA --check` must print `0 problems`. Then on a copy:
   `python3 -I tools/road_design.py AREA --from game/map/centrum.json --out build/after.json` and
   `python3 -I tools/road_design_plot.py flat build/after.json build/after.png X0 Z0 X1 Z1 --ortho build/ortho.png`
   (and once without `--ortho`). Kerbs on the photo's kerbs within ~0.5 m, no old ribbon poking
   through, side roads reaching the new kerb.
7. **Shots.** Before shots on main's map, then apply (`--from`/`--out` onto `game/map/centrum.json`),
   `python3 -I tools/bake_sectors.py`, after shots at the same spots (`--spots=NAME:X,Z,HEADING;...`,
   heading is a compass bearing, recipe in the cloud-godot-shots memory). Same `--yaw`, `--size`,
   `--time=day` for both (traffic on is fine with `--shots=40`).
7b. **Drive.** `godot --headless --path game --fixed-fps 60 --script res://tools/check_lane_drive.gd --
   "--streets=A,B" --box=X0,Z0,X1,Z1 [--route="NAME:x,z>x,z;..."]` on main's map and on the designed
   one: every street both ways plus routes into the side roads and through each junction.
7c. **Continuity (quality gate, F 2026-11-06).** Footways and cycle tracks must stay continuous:
   applying prints `road_design: continuity: N path ends at the road off a crossing` and must say 0
   (`--check-all`, so verify.sh `design`, fails otherwise). Each failure is a path that stops at the
   kerb while it goes on across the road: look at it on the ortho. A painted crossing there goes into
   the spec (`crossings` with `bs` for the cycle crossing); a real dead end goes into the area's
   `open_ends` with a note. Never loosen the check to pass.
8. **Gates.** `python3 -I tools/check_map_data.py` (record new counts on purpose), `tools/verify.sh`
   (`--roads` set); the bench if the area adds many carriage chunks (they are 8 m pieces).

## Rules that keep it clean

- Every area meets the AAA checklist in docs/design/road-design-quality.md (all of F's review
  lessons); its before/after page shows each line.

- Never patch a designed street's output; change the spec and rebuild. Applying twice is refused
  (`road_design` marker in the map); start from main's map.
- Kerbs run continuous past zebras (the renderer lowers them and lays tactile pads there); they break
  only at openings and junction mouths.
- Every side road the old map had needs an opening or a gap, or it ends at a kerb.
- A roundabout is a junction with `ring` (docs/roads/rondo.json): its arms end at the centre, the
  island and the outer circle come from the ring, `mouth` puts the arm medians' noses on the ring.
  Measure it on a polar unroll of the ortho round the centre (lane lines become straight rows).
  Arms that leave the ring sideways (docs/roads/degaulle.json) end on the ring instead: use
  `halves`, a larger `corners` circle where an arm's outer kerb never comes inside `ro`, and tight
  `radii` at the noses between two such arms.
- Every zebra and cycle crossing meets its footway / cycle track at the kerb: apply_design moves
  pavements the wider kerb covers out to it, bends cut paths onto the nearest crossing and paints
  crossings over side-road mouths; a crossing the old map had and the design lacks shows up as a
  continuity failure.
- The AI traffic lane graph is not regenerated yet: shots use `--no-traffic` until it is.
