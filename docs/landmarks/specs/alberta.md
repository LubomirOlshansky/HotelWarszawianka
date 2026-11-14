# Kościół św. Brata Alberta i św. Andrzeja Apostoła (the artists' church), Plac Teatralny: spec

Site key `church_alberta` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_alberta`): the whole frontage is one model that replaces the
kit church. Written 2026-11-14 from Mapillary photos of 2014 to 2022 across Plac Teatralny and
along Senatorska (refs/alberta, never shipped), the OSM outline and GUGiK's LoD2. The back faces
the theatre's yard and is not photographed.

The kit church it replaces (2026-11-01) was a "modern" box with a pyramid roof, its front at the
block's end. The real building is a **classicist frontage** on the square: the church's portico
in the middle of a long white block.

## 1. Identity
1. The **giant portico of four white Corinthian columns** with a pediment over the **yellow**
   church front.
2. Two **white three-storey wings** either side, arcaded on the ground floor.
3. **Red mansard roofs with dormers** on the wings, a grey gable over the middle.

## 2. Massing
Frame: origin (-1087.3, -1107.4), the front's north-west corner; u along the front to the
south-east (axis (0.808, -0.589)), +v out to the square. Ground g is the lowest terrain under the
outline (10.4).

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| north-west wing | u 0 to 14, v -17.4 to 0 | eaves 10; mansard to a flat top at 16.4 |
| middle block | u 14 to 27.5, v -18.2 to 0 | 11.2; gable along v, ridge 15.6, front pediment at v 2.4 |
| south-east wing | u 27.5 to 41.7, v -17.4 to 0 | as the other wing |
| portico | u 14.3 to 27.2, v 0 to 2.4 (steps to 3.4) | columns 0.45 to 10.3, entablature to 11.2 |

LoD2 (ground 10.4): the wings 20 to 21 abs at the eaves and 27 on top (10 and 16.5), the middle
block 24 to 26 (13.5 to 15.5), reaching 1.5 m out over the portico.

## 3. Facade: the square
Middle: three steps, four Corinthian columns (r 0.5), the white entablature and pediment with an
inscription band; behind them the yellow wall with the round-headed portal (2.6 m, to 5), a
round-headed window over it and two niches. Wings: five bays each, an arch on the ground floor
(1.5 m, to 3.35), two rows of windows (1.1 x 1.7 m at 4 and 7), five dormers on the slope.

## 4. Facade: the ends and the back
Ends: two windows a storey. The back (default): the wings' bays and dormers repeated, the yellow
middle block plain under its gable.

## 5. Roof
Red tiles (#9c4a36) on the wings' mansards, darker on the flat tops; grey sheet (#6f7276) on the
middle gable.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Wings | #eeebe3 | M_STONE |
| Church front | #d8c07a | M_STONE |
| Columns, entablature, pediment | #f5f3ee | M_STONE |
| Mansards | #9c4a36 | M_STONE |
| Middle roof | #6f7276 | M_STONE |
| Plinth, steps | #b9b4a8 | M_STONE |
| Windows, arches | PAL_GLASS_DARK, CHURCH_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text names St Andrew and the square. No
floodlights.

## 8. Detail level and budget
L1, triangle budget 950 (measured 818, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_alberta`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | 2 prisms + mansard frustums | 14 x 17.4 m | u 0..14 and 27.5..41.7, y to 16.4 | #eeebe3, #9c4a36 | 2 wings |
| dormers | boxes + panes | 1 x 1.6 m | 5 a slope | #eeebe3 | 3 roofs |
| middle block | prism + gable | 13.5 x 18.2 m | u 14..27.5, y to 15.6 | #d8c07a, #6f7276 | 1 portico |
| portico | steps, 4 columns, entablature | 12.9 x 2.4 m | before the middle, y to 11.2 | #f5f3ee, #b9b4a8 | 1 portico |
| portal, window, niches | arched panels | 0.55 to 1.3 m | the church front | PAL_DARK_DOOR, PAL_GLASS_DARK | 1 portico |
| arcade, windows | arched panels, panes | 1.1 to 1.5 m | wings, front and back | CHURCH_DARK, PAL_GLASS_DARK | 2 wings |
