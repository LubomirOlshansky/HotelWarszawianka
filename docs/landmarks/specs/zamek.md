# Zamek Królewski, Kubicki's Arcades and the castle gardens: spec

Sites `zamek` (`SKINS` row with `"model": true` + `_build_zamek` in `game/scripts/landmarks/old_town.gd`)
and `arkady` (`_find_arkady`, `_build_arkady`).

- Pass 1 (2026-11-01): written from the OpenStreetMap outline and LoD2 alone.
- Pass 2 (2026-11-02): the gardens and arcades, from Krajobraz's project, news reports, 13 Commons
  photos and a GUGiK orthophoto on the Mac (`refs/zamek/`).
- 2026-11-26: the Vistula front and the square front's windows were rebuilt (the two update
  sections at the end).
- **Pass 3 (2026-11-26, F: "the castle should be rebuilt with the newest agents and workflow")**:
  the whole castle becomes one model. LoD2 goes entirely: walls, roofs and the courtyard.
  Pass 3 is written from these sources (local refs only, never committed or shared):
  - Google 3D Tiles: `refs/zamek/3dtiles/`, with 8 orbits at -25, 4 square-on faces and the top.
    The Clock Tower is under scaffolding in the tiles, so its look comes from F's photos and pass 2.
  - Street View: `refs/zamek/streetview/`, the square front from the column.
  - LoD2's heights, rasterised at 1 m over the castle's box.
  - Wikipedia (en): five wings round a courtyard, the main front 90 m long, the Clock Tower 60 m.

## 1. Identity

1. **The Clock Tower** in the middle of the west front on Plac Zamkowy. Kept from pass 2, with the
   reviewer's fixes in section 3.
2. **The square corner turrets** at both ends of the west front under small green bulbous caps.
   Kept.
3. **One continuous terracotta roof** round the **pentagonal courtyard**, steep and hipped at the
   outer corners. Its ridges carry rows of small white chimneys, and the yard slopes carry small
   dormers. Pass 3 builds this; before, it was LoD2's.
4. **The salmon fronts**: the square front and the south front, each four storeys of framed
   windows over a plinth. The south front has its stone gate.
5. **The cream-white Vistula front** with the oval risalit under its copper bell roof. Kept from the
   2026-11-26 rebuild. It now stands on the model's own Saxon wing.
6. **Green copper caps** on the smaller towers seen over the roofs:
   - the Grodzka Tower at the courtyard's east corner;
   - a small tower on the north wing;
   - the south-east corner tower over the slope.

## 2. Massing

All points are world x, z in metres (+x east, +z south). Heights are over the yard's ground
(`map.terrain_height` at `ZAMEK_YARD`, about 1.8 m). The ground falls about 2 m to the river side
and 5.7 m at the south-east corner. Walls always go down into the ground.

- **The courtyard** is a pentagon, measured where the LoD2 roofs stop and checked against the
  3D Tiles top:
  - `ZAMEK_COURT` = NW (-658.0, -1549.5), NE (-614.0, -1549.5), E (-604.0, -1528.0),
    SE (-605.0, -1490.0), SW (-658.5, -1490.0).
  - It stays open: the map's ground with no roof.
- **A, the Saxon (Vistula) wing**: one long block, about 24.5 m deep and 87 m long.
  - Quad `ZAMEK_SAXON` = NW (-635.0, -1604.2), NE (-610.6, -1613.5), SE (-578.0, -1528.2),
    SW (-605.0, -1527.0).
  - Its west face continues the courtyard's NE edge; its east face is the river front line.
  - Walls to the eave at **17.0 m** (`ZAMEK_EAVE`, as the river front).
- **B, C, D, E: the U of the other four wings** (north, west, south, east), one ring round the
  courtyard's other sides. Both ends of the U run into A. It is described as two matched
  polylines of 6 points each: the outer one `ZAMEK_U_OUT` and the inner (yard) one `ZAMEK_U_IN`.

  | i | outer (`ZAMEK_U_OUT`) | inner (`ZAMEK_U_IN`) | where |
  | --- | --- | --- | --- |
  | 0 | (-604.0, -1567.8) | (-604.0, -1549.5) | B's east end, under A's ridge |
  | 1 | (-671.7, -1568.0) | (-658.0, -1549.5) | NW corner |
  | 2 | (-677.6, -1474.6) | (-658.5, -1490.0) | SW corner |
  | 3 | (-594.4, -1473.6) | (-605.0, -1490.0) | SE corner |
  | 4 | (-583.4, -1519.7) | (-604.0, -1528.0) | E's north end, the yard's E corner |
  | 5 | (-589.5, -1544.0) | (-601.0, -1544.0) | E's end, under A's ridge |

  - Walls to the eave at **15.9 m**: the square front's eave, 15.5 m over the square, which stands
    0.4 m higher than the yard.
  - The outer walls stand on the mapped outline. The square front and the south front are built
    by the facade pass (section 3), so the U adds no wall there.
- **The SE corner tower** (fix round 1): 9.5 m square, `ZAMEK_SE_TOWER` x -601.7..-592.2, z -1469.9..-1460.4,
  the outline's east and south faces (the west part of the projection stays unbuilt). Its walls rise
  from the low ground (about -3.9 m absolute) to **11.0 m** over the yard. The south wing's outer wall
  east of the south front (x -604.7 to O3) is a shader face.
- **The Grodzka Tower**: a 7.0 m square shaft centred at (-600.5, -1518.0), inside wing E by the
  courtyard's E corner, square to E's walls. Shaft to **25.0 m**.
- **The north wing tower** (fix round 1): a 4.5 m square shaft centred at (-635.5, -1553.5), a cream
  (`ZAMEK_VISTULA`) gabled risalit on B's yard face, rising from inside the roof to **18.9 m**.
- **Kept as they are**: the Clock Tower (shaft 9.2 m square to 29.5 m over the square, helm to 56 m)
  and the two turrets (`ZAMEK_TURRETS`).
- **Collision**: `_collide` each wing's plan, meaning A's quad and the U's quads (outer i, outer i+1,
  inner i+1, inner i for i = 0..4), plus the SE tower, the turrets and the Clock Tower. The
  courtyard stays open.

## 3. Facade

- **The plinth** round the whole outline: unchanged (cream stone, 3.2 m, 0.7 m proud).
- **The square front** (west) and **the south front**: `_zamek_square_front`, kept.
  - Kit windows, cream frames, the white sash cross, grey-green glass, thin string courses, cornice.
    Fix round 1: the square front's bays are **4.7 m** (about 19) in four rows (`ZAMEK_ROWS`); the
    south front's are **5.6 m** (about 13) in THREE rows (`ZAMEK_ROWS_S`: sill 2.9 h 1.6 `FRAMED`;
    sill 6.6 h 2.8 `HOODED`; sill 12.4 h 1.6 `FRAMED`), courses at 5.3 and 10.9 m.
  - The south front's windows run to x -604.7.
  - The south front gets **the gate** at the mapped notch, centre x -636.5 (`ZAMEK_GATE_X`): a round-arched opening 3.6 m wide and 4.6 m high, dark (`ZAMEK_GATE`), in a
    cream stone surround 5.6 x 6.6 m standing 0.25 m proud, with a small cornice over it. No
    window in its bay below the middle row.
  - The reviewer's fixes (art-director, 2026-11-26):
    - the frames 15 % wider, and in `ZAMEK_CREAM` brightened 0.08;
    - the glass `ZAMEK_PANE` towards a deep blue-grey (#334048) so it reads as glass, not holes;
    - the four rows keep visibly different heights (ground 1.9 m, piano nobile 2.8 m hooded,
      second 2.2 m, top 1.5 m, as in `ZAMEK_ROWS`).
- **The Clock Tower's west face** (reviewer's fix): over the gate's cornice, one window per stage
  between the string courses, 1.0 x 2.0 m, framed. The balcony is a cream stone slab
  3.0 m wide, 0.8 m deep, 0.2 m thick, resting on the upper string course (19.45 m), with the iron
  railing over it (`kit_balcony` IRON, slab in ZAMEK_CREAM; F 2026-11-26: the black slab floated).
- **The Vistula front** (A's east face): `_zamek_river_front`, kept unchanged. A's own wall on that
  face stands 0.5 m inside the front line, so it is never coplanar with the front's walls (the
  facade kit's `_wall` cuts coplanar overlaps).
- **E's outer face** (O3 to O4, the river side south of the Vistula front, about 37 m), in the
  Vistula front's colours:
  - a rusticated ground floor (`ZV_RUSTIC`) to 4.6 m, a cream band, then cream `ZAMEK_VISTULA`
    walls to the eave with a cream cornice 0.6 m proud;
  - 10 bays (3.6 m), three rows of kit windows: piano nobile at 5.2 m, 2.6 m tall, `PEDIMENT`;
    second floor at 9.0 m, 2.2 m tall, `SILL_HEAD`; top at 12.4 m, 1.5 m tall, `FRAMED`;
  - all in cream with `ZV_GLASS`, and the ground floor's windows `SILL` at 1.4 m, 1.6 m tall.
- **Cream faces with shader windows** (`M_MONUMENT`, the building shader's window rhythm, no mesh
  per window): A's north end, and A's west face north of B (the outline (-621.0, -1567.7) to
  (-635.0, -1604.2)). They are cream `ZAMEK_VISTULA`, with a cream cornice at the eave.
- **Salmon faces with shader windows** (`M_MONUMENT`, `ZAMEK_PLASTER`); B's yard face is cream
  (`ZAMEK_VISTULA`, fix round 1):
  - B's outer (north) face, O1 to (-621.0, -1567.8);
  - the SE tower's three outer faces;
  - every courtyard face (the inner polyline i = 0..4, plus A's west face along the yard from
    the yard's NE corner to its E corner).
  - Each has a cream cornice at its eave (0.35 m, 0.45 m proud) and the cream plinth band to 1.1 m.
- **Never two window grids on one face**: a face with kit windows is built in `M_STONE` (plain),
  and a face with shader windows has no kit windows. This was the Roesslera lesson.
- **The towers' fronts**:
  - Grodzka: salmon with cream quoins 0.7 m and a cream cornice at 25.0 m; one framed window
    per face at 18 m and 21.5 m (1.0 x 1.8 m).
  - The north wing tower: cream with cream quoins, a cornice at 18.9 m, one small window per face
    at 17.4 m.
  - The SE tower: cream quoins, cornice at 11.0 m.

## 4. Roof

Read from `refs/zamek/3dtiles/zamek_top.png` and the 8 orbits, with heights from LoD2. The tile
roof is `ZAMEK_ROOF` (#a9534a, a coral red since fix round 1), `M_STONE`. A copper part is `ZAMEK_COPPER`.

- **A's roof**: a hip roof, `_frustum` from A's quad with its SW corner at the yard's E corner
  (-604.0, -1528.0), grown 0.4 m out (so the west eave is never more than 0.4 m past the yard's NE to
  E wall), at 17.0 m, to a crest at
  **25.0 m**.
  - The crest is a thin quad 0.2 m wide on the midline from (-618.85, -1598.6) to
    (-595.45, -1537.9), so the hips are about 11 m at each end.
  - The oval's bell, the risalits' gable roofs and the pediments of the river front stand in it,
    as built.
- **The U's roof**: one ring of slopes from the matched polylines, at eave **15.9 m**.
  - The ridge points are R_i = (outer_i + inner_i) / 2 at **22.8 m**.
  - Each wing i (0..4) gets two slopes: the outer one (outer_i, outer_i+1, R_i+1, R_i), with the
    outer edge grown 0.4 m out, and the inner one (inner_i+1, inner_i, R_i, R_i+1), grown
    0.4 m into the yard. Each slope is two triangles, facing up.
  - This gives hips at the NW, SW and SE outer corners and valleys at the courtyard's corners,
    with no overlapping faces.
  - The two end gables (i = 0 and i = 5: outer, inner, R) are closed triangles. Both stand under
    A's roof: R0 at 22.8 m sits on A's midline under its 25.0 m crest. Check this on the
    turntable's top tile; a gable poking out of A's slope is a fail.
- **The SE tower's roof**, copper (fix round 1):
  - a square bell: from the tower's top grown 0.3 m out at 11.0 m, to a 7.2 m square at 13.2 m,
    to a 1.8 m square at 16.0 m;
  - no lantern; a gilt ball r 0.5 m on top with a short spike to 17.2 m.
- **The Grodzka Tower's cap**, copper:
  - a cornice at 25.0 m;
  - a bulb (8 sides, r 3.9 m at 25.6 m, r 4.2 m at 26.8 m, r 1.4 m at 29.0 m);
  - an open lantern r 1.2 m to 31.6 m;
  - a small onion to 33.0 m;
  - a gilt spire with a ball to 35.5 m.
- **The north wing tower's cap**: a copper pyramid from a 5.0 m square at 18.9 m to a point at
  22.0 m (under the 22.8 m ridge), with a small gilt ball.
- **Chimneys**:
  - white boxes (#eeeae0) 0.7 x 1.3 m, standing 1.4 m over the ridge, base 1.5 m under the roof
    surface so none floats;
  - one every 8 m along each ridge: A's crest and the U's ridge segments R1 to R4;
  - each sits 1.2 m off the ridge, on alternating sides;
  - none within 4 m of a tower; about 36 in all.
- **Dormers**, a **new kit part `kit_dormer`**:
  - a box sitting on a slope: front 1.3 m wide, 1.5 m tall; cheeks and a small hip cap in zinc
    grey-green (#7f948b); a framed dark window 0.8 x 1.0 m, lit by chance at night (`_lit`);
  - its base 0.8 m under the slope.
  - Placed on the courtyard slopes of B (north wing) and D (south wing): 9 each, evenly spaced,
    starting 6 m from the wing's ends, at 40 % up the slope. The north wing has 8: the ninth
    falls on the north wing tower and no other spot on that slope is free of the roof's valleys.
  - Mansjonaria's `_mansjonaria_dormer` may move onto it if that is easy; that is not required.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Square and south fronts, courtyard faces, B's north face, the towers' walls | #d98568 (`ZAMEK_PLASTER`) | M_STONE (kit windows) or M_MONUMENT (shader windows) |
| Vistula front, A's north end and north-west face, E's river face | #ede6d8 (`ZAMEK_VISTULA`) | M_STONE or M_MONUMENT, as above |
| Rusticated ground floor (river side) | #d8cfbf (`ZV_RUSTIC`) | M_STONE |
| Quoins, cornices, bands, gate surround, lanterns | #e6dbc0 (`ZAMEK_CREAM`) | M_STONE |
| Plinth | #c9bea8 (`ZAMEK_PLINTH`) | M_STONE |
| Window glass | #334048 (square, south), #5e6f6a (river side) | M_STONE, lit by chance (`_lit`) |
| Tile roofs | #a9534a (`ZAMEK_ROOF`) | M_STONE |
| Copper caps and helms | #6f9e86 (`ZAMEK_COPPER`); the oval keeps #8db8a6 | M_STONE |
| Chimneys | #eeeae0 | M_STONE |
| Dormers | #7f948b | M_STONE |
| Gilt | #d6b04c | M_GOLD |
| Gates | #2f2a26 (`ZAMEK_GATE`) | M_STONE |

No new material, light, node or MultiMesh.

## 6. Ground and night

- The gardens, arcades and tubs (site `arkady`, map_builder's park data, `_zamek_tubs`) are
  unchanged:
  - the Upper Garden's fountain on the vault at (-556.8, -1585.8);
  - the tubbed ball trees in front of the Vistula front and along the arcades;
  - the 12 vases round the Lower Garden's lawn carpet;
  - `LAWN_CARPETS` and `GARDEN_RINGS`.
- The courtyard is the map's open ground; its fan-patterned setts are not built.
- At night the dials are M_DIAL (lit) and the windows light by chance (kit `_lit`, and the
  shader's own on M_MONUMENT faces). No floodlight of its own.
- Cards are unchanged:
  - "Zamek Królewski";
  - "Arkady Kubickiego i ogrody zamkowe", PL "Arkady z 1821 roku, na nich Ogród Górny, niżej
    Ogród Dolny."
- `fronts.gd`: the `zamek` SKINS row gets `"model": true`. Its skin-only branch then stops
  running, and the builder deletes it with its helpers if nothing else calls them:
  - `pale` with `drop`, and `_zamek_river_edges`;
  - `_zamek_tops` and its `lod2_tops` cut.

## 7. Detail level and budget

- L3, the hero landmark (docs/LANDMARKS.md), triangle budget 24500.
- `zamek`: **24500** triangles in `check_mesh_quality.gd` and `check_sites.gd`: 18632 measured,
  17656 before pass 3, tightened from 30000 at the audit. This is a named **exception** to the L3 limit:
  - the castle is the largest building in the Old Town and is seen from every side of the square
    and the river;
  - about 170 kit windows on the square, south and river fronts make most of it;
  - all of it is in the city's one building surface, so no draw call is added.
- `arkady`: 2400 in `check_sites.gd` and 2600 in `check_mesh_quality.gd` (unchanged).
- Mesh check: no z-fighting, no floating parts. Chimneys, dormers and the towers' shafts start
  inside the roof or the mass.
- Shots, all `--no-ghost --time=day`, in the cloud, on both paths:
  - Plac Zamkowy: `--at=-720,-1500 --yaw=250 --pitch=-25 --size=80`;
  - the Vistula front: `--at=-690,-1519 --yaw=110 --pitch=-15 --size=70`;
  - top: `--at=-560,-1560 --yaw=0 --pitch=-80 --size=320`;
  - F's default view over the square: yaw 10.3.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| saxon_walls | wall pieces on A's quad, the river face 0.5 m inside | 87 x 24.5 m, to 17.0 m | `ZAMEK_SAXON` | M_MONUMENT / M_STONE | 5 Vistula front |
| u_walls | wall pieces on the U's outer and inner polylines | to 15.9 m | `ZAMEK_U_OUT`, `ZAMEK_U_IN` | M_MONUMENT | 3 roof ring |
| court | open ground inside the pentagon | 54 x 60 m | `ZAMEK_COURT` | (map ground) | 3 roof ring |
| saxon_roof | `_frustum` hip | 17.0 to 25.0 m, crest 0.2 m | A's quad + 0.4 m | M_STONE | 3 roof ring |
| u_roof | matched-polyline slopes | 15.9 to 22.8 m | the U, ridge R_i | M_STONE | 3 roof ring |
| cornices | cream ring cornice | 0.35 m, 0.45 m out | every eave | M_STONE | 4 fronts |
| square_south_fronts | `_zamek_square_front` kit_window FRAMED / HOODED + sash | 4 rows, 3.6 m bays | west and south outline | M_STONE | 4 fronts |
| south_gate | arched opening in a stone surround | 3.6 x 4.6 m in 5.6 x 6.6 m | south front u 39 | M_STONE | 4 fronts |
| river_e_front | kit_window SILL, PEDIMENT, SILL_HEAD, FRAMED | 10 bays, 4 rows | O3 to O4 | M_STONE | 5 Vistula front |
| vistula_front | `_zamek_river_front` (kept) | u -16..75.3 | `ZV_O`, `ZV_A` | M_STONE | 5 Vistula front |
| clock_tower | `_zamek_clock_tower` (kept) + west windows + kit_balcony IRON | 9.2 m, helm to 56 m | `ZAMEK_CLOCK` | M_STONE | 1 Clock Tower |
| turrets | `_zamek_turret` (kept) | 4.5 m, caps to 31 m | `ZAMEK_TURRETS` | M_STONE | 2 turrets |
| se_tower | outline prism + copper square bell + gilt ball | 9.5 x 9.5 m, to 17.2 m | SE projection | M_MONUMENT / M_STONE | 6 copper caps |
| grodzka_tower | square shaft + quoins + bulb + lantern + onion + spire | 7.0 m, to 35.5 m | (-600.5, -1518.0) | M_STONE | 6 copper caps |
| north_tower | cream square shaft + copper pyramid + ball | 4.5 m, to 22.5 m | (-635.5, -1553.5) | M_STONE | 6 copper caps |
| chimneys | white boxes | 0.7 x 1.3 m, 1.4 m over the ridge | every 8 m along the ridges | M_STONE | 3 roof ring |
| dormers | `kit_dormer` (new kit part) | 1.3 x 1.5 m | 9 on B's and 9 on D's yard slope | M_STONE | 3 roof ring |
| plinth | wall pieces | 3.2 m, 0.7 m proud | round the outline | M_STONE | 4 fronts |
| tubs | barrel + rim + stem + ball (kept) | 0.9 m barrel, 3 m tall | 14 in front of the river front, 1 per 10 m on the arcades | M_STONE | 5 Vistula front |
| arcade_wall | outline walls + cornice + railing (site `arkady`, kept) | 190 m, terrace height | the mapped outline | M_STONE | 5 Vistula front |

## 9. Open

- The arcades against the real terrain: the wall's top meeting the terrace, and the gravel walk.
- Not built:
  - the courtyard's fan-patterned setts and its gates' passages (the car cannot enter);
  - the Lower Garden's stairs and its boskets beyond the map's hedges;
  - the south quarter garden's embroidered parterre;
  - Pałac pod Blachą's model.
- The Clock Tower is under scaffolding in the 3D Tiles, so its helm's proportions are still pass
  2's (F's photos).

## Update 2026-11-26: the Vistula front rebuilt (F: "this green kupol is like off")

Sources: F's garden photo, PAP's aerial and the Google 3D views.

**The frame.** `_zamek_river_front` works in a frame on the outline's front line: origin
(-609.6, -1596.8), u along (0.347, 0.938), +v out to the river.

**The parts, along u:**
- the north gabled risalit (u -16..0, v 5.3): pediment, three statues, three bays;
- a loggia of four round arches under a balustraded balcony (u 0..18);
- the convex oval central risalit: centre u 29.6, half axes 11.6 x 6.9, a superellipse so it
  meets the loggias squarely; arched French windows, tall windows, oculi;
- a second loggia (u 41..59);
- the south risalit (u 59..75.3, v 7.2).

**Colours.** A rusticated ground floor #d8cfbf, warm cream walls #ede6d8 (`ZAMEK_VISTULA`),
grey-green glazing #5e6f6a, cream cornices.

**The oval's roof** is a bell, not a dome (Fable's critique):
- a flared eave 0.4 m past the drum, a concave kick, then a convex shoulder;
- a small cream lantern with eight dark openings, its copper cap, and a thin gilt spire with a
  ball (about 0.55 of the oval's width tall, with the spire);
- pale patina #8db8a6, three oculi in the copper, and two statues on the rim.

## Update 2026-11-26: the square front's windows (F: "those windows look bad")

**The problem.** The windows were a dark pane with a flush cream surround. `_wall`'s coplanar
check cut the surround away, so they read as bare dark holes.

**The fix.** Four storeys from the photos (01_west_square, 02_west_column), in `ZAMEK_ROWS`:

| Storey | Sill | Height | Style |
| --- | --- | --- | --- |
| Ground floor | 1.3 m | 1.9 m | `FRAMED` |
| Piano nobile | 4.7 m | 2.8 m | `HOODED` |
| Second floor | 8.8 m | 2.2 m | `FRAMED` |
| Top floor | 12.2 m | 1.5 m | `FRAMED` |

- Each is a kit window (`kit_window`) in cream, with the white sash cross (its `sash` argument).
- The glass is grey-green #3b4744, lit by chance at night.
- Three thin string courses run at 4.15, 8.3 and 11.75 m (0.22 m tall).
