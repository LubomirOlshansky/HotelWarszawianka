# Zamek Królewski, Kubicki's Arcades and the castle gardens: spec

Sites `zamek` (`SKINS` row + `_build_zamek`) and `arkady` (`_find_arkady`, `_build_arkady`) in
`game/scripts/landmarks.gd`. Pass 1 (2026-11-01) was written from the OpenStreetMap outline and
LoD2 alone. **Pass 2 (2026-11-02, F: "Krajobraz's Zamek Królewski project" plus "search other
sources")** comes from:

- Ogród Park Krajobraz's project page (krajobraz.com.pl/projekt/zamek-krolewski): the Upper Garden
  on the arcades' vault, ramps and stairs up to the terraces, a row of tubs with ball trees on the
  terrace edges, multi-season parterres; the Lower Garden's sunken centre framed by hedges, then
  boskets, on one axis from the castle to the Vistula; a south quarter garden.
- News: the Upper Garden restored 2013-2015 (over 20,000 box shrubs, 90 trees in tubs, two
  fountains; eurobuildcee.com), the Lower Garden 2017-2019 (Park-M; dzieje.pl, pik.warszawa.pl),
  the OPK/SARP walk presentation (2021) for the history and the boskets.
- 13 Wikimedia Commons photos (CC BY / BY-SA) and a GUGiK orthophoto (3072 px, 0.12 m/px), kept
  on the Mac in `refs/zamek/` (gitignored) with `SOURCES.md` and `REPORT.md` (measurements in
  game coordinates). No free 3D model of the castle exists (only paid ones; none used).
- OSM tags: the arcades are 7 m, `#c8733f`, brick, 1818-1821; the Vistula risalit's part is
  `#eeeeee` plaster under a green metal roof.

## 1. Identity

1. **The Clock Tower** in the middle of the west front on Plac Zamkowy: salmon shaft with cream
   quoins, dark-blue clock faces with gilt numerals, a green copper onion helm with an open
   lantern, a second onion and a spire with gilt balls (about 56 m here).
2. **Square corner turrets** at both ends of the west front under small green bulbous caps.
3. **One continuous terracotta roof** round the pentagon courtyard.
4. **The cream-white Vistula front**, clearly lighter than the salmon west front, with the oval
   central risalit under a green copper dome and gilt figures.
5. **Kubicki's Arcades** below it: a terracotta wall of round arches, cream-ringed, the white
   portal block in the middle, the Upper Garden on top, the formal Lower Garden in front.

## 2. Massing

The castle's mass stays LoD2's (tallest cell 45 m at (-672, -1520)) in its skin. The model adds:
the Clock Tower's shaft 9.2 m square (0.3 m proud of the mapped 8.6 m one) to 29.5 m and its
helm to 56 m; two turret shafts 4.5 m square from 11 m to 20.5 m, caps to 31 m (the photos say
28-32 m; OSM says 23 m); the Vistula front's skin 0.35 m proud of the outline to the eave at
17 m over the courtyard; the oval risalit as a 12-sided drum, radius 7 m, standing 1.5 m out of
the front at (-597.2, -1566.0). The arcades' wall stands on the mapped outline (190 m long,
15-20 m deep) from the Lower Garden's ground to the terrace: `max(terrace + 0.15, foot + 7.5)`.

## 3. Facade

- West front and tower: the skin's salmon (#cf9580, M_MONUMENT windows). Tower: cream quoins
  0.9 m, two string courses (12.6 m, 19 m), the gate 4 m wide, 5 m high in a cream surround
  5.6 x 6.4 m with a gilt cartouche, an iron balcony at 19.6 m, a dial on each face at 24 m
  (radius 1.7 m), the cornice at 29.5 m and a gilt frieze.
- Vistula front: the outline's east-facing edges (outward x > 0.55, east of x -615): a
  rusticated ground floor (#cbb6a6) to 4.6 m, a cream band, cream-white (#e9e1cf) to the eave,
  both M_MONUMENT; a cream cornice 0.75 m proud at the eave.
- Arcades, east face: terracotta (#c8693f), round-headed arches 6 m wide, 5.5 m high, one per
  12 m of wall (16 on the map's outline), each a cream ring and a dark opening; the portal block's
  edges in white stone (#e4dfd2) with one 7 m arch; a cream cornice 0.7 m and a black iron
  railing (two rails, 0.12 m and 1 m up).

## 4. Roof

Roofs stay the skin's, now terracotta #ad5c3f (photos #c0502e calmed; was #8d6350, which read
brown). Copper (#6f9e86) for the tower helm (onion profile r 4.4-5.0 m from 30.7 to 38.4 m, the
lantern r 1.8 m to 42 m, the second onion to 46.4 m, spire to 55.6 m, gilt balls at 49.6 and
55.6 m, a copper flag), the turret caps (bulb r 2.6 m, lantern, cap, spire, gilt ball) and the
dome (12-sided, eave + 2 m to eave + 7.1 m, a lantern and a gilt ball). The arcades' top: a gravel
walk 3.5 m wide along the edge; where the terrain has no terrace (the cloud's flat ground) the
whole vault gets a lawn (#74a24c).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| West walls (skin) | #cf9580 | M_MONUMENT |
| Roofs (skin) | #ad5c3f | M_STONE |
| Quoins, cornices, lantern | #e6dbc0 | M_STONE |
| Vistula front | #e9e1cf over #cbb6a6 | M_MONUMENT |
| Helms, caps, dome | #6f9e86 | M_STONE |
| Gilt | #d6b04c | M_STONE |
| Dials | #1f2a3a with gilt ticks | M_DIAL + M_GOLD |
| Arcades | #c8693f, white stone #e4dfd2 | M_STONE |
| Plinth | #e2d8c4 | M_STONE |

## 6. Ground and night

- **Gardens** (sites `arkady`, map_builder, park data): the Upper Garden's big tulip fountain on
  the vault at (-556.8, -1585.8) (basin r 3.1 m, water r 2.8 m, a jet); the water in the map's
  basin rings at (-585.5, -1574.5) and (-537.5, -1656.4); 14 tubbed ball trees every 4 m in front of
  the Vistula front and one every 10 m along the arcades' edge (red or green barrels, white rims,
  clipped maples on bare stems); 12 white vases on pedestals round the Lower Garden's sunken lawn
  carpet on the map's round beds. `map_builder.LAWN_CARPETS`: the carpet (OSM tags it paving) is
  grass, #78a84a. `map_builder.GARDEN_RINGS`: inside the gardens a closed `wall` ring under 6 m
  across (fountain basins, the vases' beds, round path nodes) is a 0.45 m stone kerb, not a 1.9 m
  grey drum. The hedges, paths and flowerbeds are the map's own.
- Collision: the Clock Tower's shaft and the arcades' outline (LoD2's for the rest).
- Night: the dials are M_DIAL (lit). Cards: "Zamek Królewski" (kept); "Arkady Kubickiego i ogrody
  zamkowe", PL "Arkady z 1821 roku, na nich Ogród Górny, niżej Ogród Dolny."

## 7. Detail level and budget

L3 (hero landmark, docs/LANDMARKS.md). Budgets in `check_sites.gd`: `zamek` 7900 triangles
(7544 measured after the 2026-11-26 Vistula front), `arkady` 2400 (2300 measured);
`check_mesh_quality.gd` 7900 and 2600, no
z-fighting and no floating parts (the turret shafts start at the ground inside the mass, the
railing has posts). No new material, node, light or MultiMesh: all of
it is merged into the city's one building mesh. Shots (cloud, both paths): from Plac Zamkowy
`--at=-720,-1500 --yaw=250 --pitch=-25 --size=80`, the Vistula front `--at=-690,-1519 --yaw=110
--pitch=-15 --size=70`, the arcades `--at=-540,-1600 --yaw=70 --pitch=-22 --size=90`, top
`--at=-560,-1560 --yaw=0 --pitch=-80 --size=320`, all `--no-ghost --time=day`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | LoD2 skin | the mapped mass, tallest 45 m | the outline | M_MONUMENT | 3 roof ring |
| roofs | LoD2 skin | the mapped roof cells | on the walls | M_STONE | 3 roof ring |
| plinth | wall pieces | 6 m or less long, 3.2 m high, 0.7 m proud | round the outline | M_STONE | 4 Vistula front |
| clock_shaft | box + quoins + courses | 9.2 m square, 29.5 m | (-671.0, -1519.3) | M_MONUMENT | 1 Clock Tower |
| clock_gate | surround + opening + cartouche | 5.6 x 6.4 m, opening 4 x 5 m | tower's west face | M_STONE | 1 Clock Tower |
| clock_dials | `_dial` x 4 | r 1.7 m at 24 m | each face | M_DIAL | 1 Clock Tower |
| clock_helm | 8-sided onion, lantern, onion, spire, balls, flag | 30.7-56 m | tower axis | M_STONE | 1 Clock Tower |
| turrets | shaft + quoins + bulb + lantern + spire | 4.5 m square, 11-31 m | (-675.0, -1476.7), (-669.6, -1565.7) | M_MONUMENT | 2 turrets |
| vistula_front | walls + band + cornice | to the eave, 17 m over the yard | east-facing outline edges | M_MONUMENT | 4 Vistula front |
| dome | 12-sided drum + copper dome + lantern + 3 figures | r 7 m, to eave + 10.3 m | (-597.2, -1566.0) | M_STONE | 4 Vistula front |
| tubs | barrel + rim + stem + ball | 0.9 m barrel, 3 m tall | 14 in front of the front, 1 per 10 m on the arcades | M_STONE | 5 gardens |
| arcade_wall | outline walls + cornice + railing | 190 m, terrace height | the mapped outline | M_STONE | 5 arcades |
| arcade_arches | ring + dark opening | 6 x 5.5 m, the portal 7 m | 1 per 12 m on the east face | M_STONE | 5 arcades |
| upper_fountain | basin + water + tulip bowl + jet | r 3.6 m | (-556.8, -1585.8) on the vault | M_STONE | 5 gardens |
| vases | pedestal + vase | 0.64 m square, 1.85 m | 12 round beds by the lawn carpet | M_STONE | 5 gardens |

## 9. Open *(Mac look check, QUESTIONS)*

- ~~LoD2's tower and the Vistula eave; the gate's side and the dials.~~ F's look check
  (2026-11-03): the gate faces west and there are four dials (kept). LoD2 carried the Clock
  Tower's shaft 3.5 m past the model's cornice and its helm as a salmon mass to 46.7 m: it is cut
  30.0 m over the square inside a 12 m ring (`Landmarks.lod2_tops`, map_builder `_top_lod2`),
  hidden in the cornice. The salmon band over the river front was LoD2's steep roof slopes (the
  skins' 0.7 roof threshold painted them wall) and its walls up to 0.9 m proud of the model's
  front: the skin's `steep` 0.3 tiles them, and its `pale` edges (the outline's river edges,
  3 m) paint those walls cream (map_builder `_skin_run`). The turret caps were clean.
- The arcades against the real terrain: the wall's top meeting the terrace, the gravel walk.
- Not built: the courtyard's fan-pattern setts and the yard walls' colours; the Vistula front's
  two gabled side risalits and loggias; the dormers; the Lower Garden's stairs and boskets beyond
  the map's hedges; the south quarter garden's embroidered parterre; Pałac pod Blachą's model.

## Update 2026-11-26: the Vistula front rebuilt (F: "this green kupol is like off")

From F's garden photo, PAP's aerial and the Google 3D views. `_zamek_river_front` in a frame on
the outline's front line (origin (-609.6, -1596.8), u along (0.347, 0.938), +v out to the river):
the north gabled risalit (u -16..0, v 5.3: pediment, three statues, three bays), a loggia of four
round arches under a balustraded balcony (u 0..18), the convex oval central risalit (centre u
29.6, half axes 11.6 x 6.9, a superellipse so it meets the loggias squarely; arched French
windows, tall windows, oculi), a second loggia (u 41..59), the south risalit (u 59..75.3, v 7.2).
A rusticated ground floor #d8cfbf, warm cream walls #ede6d8 (`ZAMEK_VISTULA`), grey-green glazing
#5e6f6a, cream cornices.

The oval's roof is a bell, not a dome (Fable's critique): a flared eave 0.4 m past the drum, a
concave kick, a convex shoulder to a small cream lantern with eight dark openings, its copper cap
and a thin gilt spire with a ball (about 0.55 of the oval's width tall with the spire), pale
patina #8db8a6, three oculi in the copper and two statues on the rim.

LoD2's walls along this front stood proud of the model in places and drew a second row of window
slits through it: the skin's `pale` now carries a `drop` polygon (the front's frame, u -17..76,
v +-14) inside which map_builder's `_skin_run` drops them, so the model stands alone there.
