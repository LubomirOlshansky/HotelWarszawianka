# Klasztor Ojców Dominikanów (the Dominican priory), Freta 10: spec

Site key `church_dominikanie` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_dominikanie`): the priory's wings round
the cloister garth beside St Hyacinth's (`church_jacek`), one model that replaces the plain
OpenStreetMap block (building 3005). Written 2026-11-14 from a Mapillary photo of 2020 in the
passage by the west wing (refs/dominikanie, never shipped), the OSM outline and GUGiK's LoD2. The
other open photos stop at Freta's tenements; the wings behind them follow LoD2 and that one
photo (defaults in QUESTIONS).

## 1. Identity
1. A long **pale yellow wing** under a **red-brown gable roof**, three storeys, next to the
   church.
2. **Lean-to galleries** along both of its long sides: the outer one with a rusticated ground
   floor and an arched door, the cloister walk on the garth side.
3. The **east wing** running down the slope to the river under its own gable roof, a storey
   more at its low north end.

## 2. Massing
Frame: origin (-989.0, -1957.1), the long wing's west corner by the church; u along the wing
east (axis (0.704, -0.710)), v across to the garth. Heights are LoD2's absolute heights (the
ground falls from about 0 at the church to -4 at the east wing's north end).

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| long wing | u 0 to 62, v 5 to 13.8 | eaves 13; gable roof to 17.3 |
| outer gallery | u 0 to 46.5, v 0 to 5 | 8.6; lean-to to 10.2 |
| cloister walk | u 13 to 46.5, v 13.8 to 21 | 7.4; lean-to to 10.2 |
| west range | u 4.5 to 13, v 13.8 to 31.7 | 5.5 and 4.5, flat |
| east wing | u 46.5 to 61.5, v -21.4 to 34 | eaves 7.8; gable roof along v to 13 |

## 3. Facade: the outer gallery
A rusticated ground floor (a groove every 0.7 m) to 3.6 under a band; panes every 3.4 m in two
rows; an arched door in the middle; the long wing's top storey over the lean-to.

## 4. The other sides
Panes in every bay: three rows on the east wing's low north half, two elsewhere, one on the long
wing over each lean-to. The long wing's west end stands against the church's buildings and has
none.

## 5. Roof
Red-brown sheet (#97594a, St Hyacinth's): gable roofs on both wings, lean-tos on the galleries.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #e6d4a6 | M_STONE |
| Cornices, bands, door frame | #efe4c4 | M_STONE |
| Rusticated ground floor | #d9c590 | M_STONE |
| Roofs | #97594a | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor Dominikanów". No floodlights.

## 8. Detail level and budget
L1, triangle budget 600 (measured 492, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_dominikanie`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| long wing | prism + gable | 62 x 8.8 m | u 0..62, v 5..13.8, y to 17.3 | #e6d4a6, #97594a | 1 wing |
| galleries | prisms + lean-tos | 46.5 x 5, 33.5 x 7.2 m | both long sides, y to 10.2 | #e6d4a6, #97594a | 2 galleries |
| east wing | prism + gable | 15 x 55.4 m | u 46.5..61.5, y to 13 | #e6d4a6, #97594a | 1 wing |
| west range | boxes | 7.7 x 7.2, 8.5 x 10.7 m | u 4.5..13, v 13.8..31.7 | #e6d4a6 | 2 blocks |
| rustication, band | boxes | 46.5 m | the outer gallery, y to 3.9 | #d9c590, #efe4c4 | ground floor |
| door | arched panels | 1.8 x 3 m | u 23 on the outer gallery | #5a4232, #efe4c4 | 1 door |
| windows | flat panes | 1.15 m wide | every 3 to 3.6 m, 1 to 3 rows | PAL_GLASS_DARK | every side but the west end |
