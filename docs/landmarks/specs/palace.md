# Pałac Kultury i Nauki: spec

Site key `palace` in `game/scripts/landmarks.gd` (`_palace_frame`, `_build_palace`, `_dial`;
the plan constants `P_WINGS`, `P_BLOCKS`, `P_TIER`, `P_CORNERS`, `P_SHAFT`, `P_BAYS`,
`P_COURTS`, `P_HALL`). Written 2026-11-01 in a cloud thread from the OpenStreetMap parts in
`centrum.json` (the Palace is mapped in 3D: the base, the corner pavilions, the north and south
blocks, the entrance block, the Congress Hall, the tower's first tier with its corner towers,
the shaft, the clock tier, the lantern, the crown and the spire, all with heights) and the
earlier model. The reference photos in `refs/` live on the Mac and were not reachable from the
cloud. The Mac's side-by-side photo check (2026-11-01) is applied: no step at the terrace, a
cornice band on the shaft, the Congress Hall's flat stepped metal roof, a 25 m portico, the
spire's gold and its bronze foot. The stone's colour is parked in QUESTIONS.

## 1. Identity

Lev Rudnev's Palace of Culture and Science (1952-1955), the city's tallest building for half a
century and the first thing the opening flight shows. What makes a passer-by say its name:

1. **The stepped tower**: a wedding-cake profile, a wide first tier with four corner towers, a
   ribbed shaft, a narrow clock tier, an arcaded lantern, a crown and a long spire to 237 m.
2. **Pinnacles and attics on every step**: crenellated parapets in the Polish Renaissance
   manner on every roof edge, pinnacles on every corner.
3. **The ribbed shaft with heavy corner piers**: each face's middle bay set back between solid
   corner piers, stone ribs running up it.
4. **The clocks**: a lit dial on each face of the clock tier (Warsaw time).
5. **The low palace round it**: four-storey wings round two courtyards, corner pavilions, the
   Congress Hall's half-round end to the west, the columned entrance on the east.

## 2. Massing

The Palace's own frame (from the clock tier's square, `_palace_frame`): u towards Marszałkowska
(east-north-east), v towards Al. Jerozolimskie (south-south-east), metres from the clock tier's
centre. Heights over the ground under the outline.

| Volume | Plan (u, v) | Heights | Source |
| --- | --- | --- | --- |
| Base | the mapped outline, 217 x 266 m, two courtyards | 0 to 18 m | OSM part h 18 |
| Courtyards | the relation's two inner rings | floor at 4 m | OSM inner rings |
| Corner pavilions | 4 x about 27 x 51 m at u +-54..82, v +-69..121 | 18 to 22.5 m | OSM parts h 22.5 |
| Entrance block | u 28..46, v -11..12 | 18 to 22.5 m | OSM part h 22.5 |
| North and south blocks | u -18..17, from the tower's faces to v +-64..68 | 18 to 30 m | OSM parts h 30 (until now only their outer halves were built) |
| Congress Hall | u -113..-55, v -34..33, half-round west end | 18 to 22.5 m, roof drum to 26 m, vent to 27 m | OSM part h 22.5; roof from the Mac photos |
| Tier one | the shaft's plan with a corner tower on each corner, 64 x 70 m | 18 to 67 m | OSM part h 67 (36 corners) |
| Corner towers | 4 x about 17.6 x 17.7 m | crowns to 73 m, pinnacles to 82 m | OSM corners; crowns as before |
| Shaft | 44 x 44 m, corner piers, middle bays 20 m wide set back 1.3-1.8 m | 67 to 139 m | OSM part h 139 (28 corners) |
| Clock tier | 17 x 17 m on a 25 x 25 m plinth (139-143 m) | 139 to 168 m | OSM part h 168 |
| Lantern | 12.6 x 12.6 m | 168 to 188 m | OSM part h 204 (lantern and crown together) |
| Crown | pyramid 12 m to 4.8 m | 188 to 203 m | OSM part h 210 |
| Spire | bronze foot 3.6 m (200.5-208 m), then 3.2 m to a point | 200.5 to 237 m | OSM part h 237, mh 200.5 |

## 3. Facade, base to top

- **Base, wings, blocks (0-30 m)**: M_MONUMENT (tall windows between piers) in sandstone, a
  crenellated attic on every top (1.2-1.6 m), small pinnacles on the pavilions' and the
  blocks' outer corners. The courtyards' walls slightly darker.
- **East entrance**: six columns 13.5 m high, 4.8 m apart, in front of the entrance (25 m
  wide, from the Mac photos; the column count is medium confidence), an entablature on them.
  The real portico is 17 m deep; the mapped base covers its depth, so only the front row is built.
- **Tier one (18-67 m)**: M_MONUMENT on the mapped plan; each corner tower carries a 2.2 m
  attic, corner pinnacles (only where they stand clear of the shaft) and a small stepped crown
  with a pinnacle.
- **Shaft (67-139 m)**: M_MONUMENT on the mapped plan, so the corner piers stand forward of
  each face's middle bay; five light stone ribs up each middle bay to 136 m, broken by a thin
  cornice band (121.5-123 m, 0.6 m proud) about five storeys under the top. On top a 3 m
  attic, a big pinnacle on each corner pier (14 m) and one smaller in the middle of each side.
  No step at the 30th-floor terrace (114 m): the Mac photos show one width up to the top cornice.
- **Clock tier (139-168 m)**: a 4 m stepped plinth with an attic, the tier with a 6.3 m dial
  on each face (gold rim, hour marks, the hands from the shader), an attic and four pinnacles.
- **Lantern (168-188 m)**: three tall dark arches on each face between stone piers, an attic.

## 4. Roof

Flat roofs (#8f877a) behind the attics everywhere; the courtyards' floors lighter. The Congress
Hall: a flat grey metal roof (#8d9398) in concentric steps, the roof at the wall top, a raised
16-sided drum 48 x 47 m over the auditorium (centre u -86, 22.5-26 m) with a flat top and a 4 m
vent cap to 27 m. The crown is a green patina pyramid (188-203 m) on the grey stone lantern;
the spire rises from a dark bronze foot (200.5-208 m) in gold (#d4a640) with two rings (214
and 225 m).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | sandstone #d8c49c (courtyards 8 % darker) | M_MONUMENT |
| Attics, pinnacles, ribs, columns | light sandstone #e6d6b2 | M_ATTIC, M_STONE |
| Roofs | #8f877a; the Congress Hall's metal #8d9398 | M_STONE |
| Courtyard floors | #a39c90 | M_STONE |
| Hall roof drum | sides #8d9398 12 % darker, top 6 % lighter, vent 20 % darker | M_STONE |
| Lantern arches | #3a3640 | M_STONE |
| Crown | patina #9fbcae | M_STONE |
| Spire's foot | dark bronze #5a4630 | M_STONE |
| Spire and rings | gold #d4a640 | M_GOLD |
| Clock dials | #f4ecd6, rim gold, marks #26232a | M_DIAL, M_GOLD, M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

The base stands on the lowest ground under its outline (walls from 0.4 m below); the car
collides with the base outline; Plac Defilad round it is the map's. At night the M_MONUMENT
windows light up, the dials glow and the Dusk look floodlights the stone gold (the dusk loop).
The opening flight starts over the tower (420 m up): the silhouette's heights are unchanged by
this pass. Card (kept): "Pałac Kultury i Nauki", PL "237 m razem z iglicą. Otwarty w 1955
roku.", EN "237 m with its spire. Opened in 1955."

## 7. Detail level and budget

L3 (the hero: the skyline, the opening flight, the landing's golden-hour shot), triangle budget
3900 (the existing `check_mesh_quality.gd` BUDGET; 3632 measured after this pass, 3202 before).
Mac bench (M4 Pro): no change against main (8.33 ms, 113 draws, 0.55 M tris).
Shots: `--solo=palace --solo-look=sil` and `flat` (the `first` set), then in the city at day,
night and the landing's golden hour.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| base | mapped outline prism with 2 courtyards | 217 x 266 m, 0 to 18 m | the whole site | M_MONUMENT #d8c49c | 5 low palace |
| pavilions | 4 boxes, attic, 4 pinnacles each | about 27 x 51 m, to 22.5 m | the four corners | M_MONUMENT #d8c49c | 5 low palace |
| entrance | box, attic, pinnacles | 18 x 23 m, to 22.5 m | east, u 28..46 | M_MONUMENT #d8c49c | 5 low palace |
| portico | 6 columns and an entablature | 1.3 m columns, 13.5 m, 25.6 m wide | u 53.4, v -12..12 | M_STONE #e6d6b2 | 5 low palace |
| blocks | 2 mapped prisms, attic round the outer end, 4 pinnacles each | 35 m wide, to 30 m | north and south of the tower | M_MONUMENT #d8c49c | 5 low palace |
| hall | mapped prism with the half-round end, attic | 58 x 67 m, to 22.5 m | west, u -113..-55 | M_MONUMENT #d8c49c | 5 low palace |
| hall_roof | 16-sided drum and a vent box | 48 x 47 m, 22.5 to 26 m; vent 4 m to 27 m | u -86 | M_STONE #8d9398 | 5 low palace |
| tier | mapped prism, roof on the corner towers only | 64 x 70 m, 18 to 67 m | the tower | M_MONUMENT #d8c49c | 1 stepped tower |
| corner_crowns | attic, pinnacles, stepped crown, pinnacle | 9 x 9 m crowns to 73 m | the 4 corner towers | M_STONE #e6d6b2 | 2 pinnacles and attics |
| shaft | mapped prism with set-back middle bays | 44 x 44 m, 67 to 139 m | the tower | M_MONUMENT #d8c49c | 3 ribbed shaft |
| ribs | 40 thin boxes | 0.9-1.0 m, 67 to 121.5 and 123 to 136 m | 5 per middle bay | M_STONE #e6d6b2 | 3 ribbed shaft |
| cornice | the shaft's plan offset 0.6 m, top ring | 1.5 m high | 121.5 to 123 m | M_STONE #e6d6b2 | 3 ribbed shaft |
| shaft_top | attic 3 m, 4 big and 4 small pinnacles | 14 m and 8 m pinnacles | the shaft's top | M_ATTIC, M_STONE | 2 pinnacles and attics |
| clock_tier | plinth box and tier box, attic, 4 pinnacles | 25 m and 17 m square, 139 to 168 m | the tower's centre | M_MONUMENT #d8c49c | 1 stepped tower |
| dials | 4 discs with rims and marks | 6.3 m across | 156 m, one per face | M_DIAL #f4ecd6 | 4 clocks |
| lantern | box with 3 dark arches per face, attic | 12.6 m square, 168 to 188 m | the tower's centre | M_STONE #3a3640 | 1 stepped tower |
| crown | square frustum | 12 m to 4.8 m, 188 to 203 m | the tower's centre | M_STONE #9fbcae | 1 stepped tower |
| spire_foot | box | 3.6 m, 200.5 to 208 m | the tower's centre | M_STONE #5a4630 | 1 stepped tower |
| spire | 2 frustums, 2 rings | 3.2 m to a point, 208 to 237 m | the tower's centre | M_GOLD #d4a640 | 1 stepped tower |

## 9. The Blender trial (2026-11-13)

A second build of the Palace, in Blender (`tools/blender/pkin.py`, glb in `game/models/pkin/`),
behind `--palace=blender`; the code model above stays the default. Same plan and heights, from
about 130 Commons photos (`refs/pkin_blender/`, never committed), with what code made awkward:
three-step profiled cornices on every roof edge, pinnacles with a pedestal, an octagonal
obelisk, a ring and a finial, the corner towers' crests and stepped crowns, more pinnacles along
the shaft top and the tier tops, round 12-sided portico columns with bases and capitals, the
Congress Hall's two-step 24-sided drum, real open arches with reveals, a bronze orb and three
rings on the spire. At street level (F: "make the elements near the ground well"): a portico of
four columns with its dark loggia, entablature and attic on each pavilion's outer end and a porch on
each of the eight shallow projections of the pavilions' long sides, the Congress Hall's colonnade of
18 columns under an entablature ring round its half-round end, and three steps before the main
portico. Also from F's close-up from the 30th floor: dark round-headed loggia openings in the
shaft's top storeys.

Photo fix in it: the tier over the shaft is panelled stone to 157 m and then an **arcade of five
round-headed openings per face** to 168 m; the **clocks sit above the arcade** on the 12.6 m
tier (dials at 178 m), under a low flared patina cap. The code model has the clocks under the
arches (sections 2 and 3 above); it keeps that until the trial is decided.

LOD 0 23,084 triangles (code: about 3,600, plus the venues), LOD 1 9,320. Probe at the Palace
(Mac, `--probe --at=-1290,170 --heading=135 --time=day --no-traffic`): 69 main-pass draws both
ways, main pass 0.46 → 0.48 M triangles, shadow 0.31 → 0.33 M; no new material or shader.
