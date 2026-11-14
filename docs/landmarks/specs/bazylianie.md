# Klasztor Bazylianów (the Basilian monastery's street wing), Miodowa 16: spec

Site key `church_bazylianie` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the
OSM outline under `at`, `_build_church` hands it to `_build_bazylianie`): the monastery's street
wing and its two back wings as one model that replaces the plain OpenStreetMap block (building
1825). Written 2026-11-14 from Mapillary 360s of 2026 along Miodowa (refs/cerkiew, never
shipped), the OSM outline and GUGiK's LoD2. The wing's middle under the pediment and the cross is
the front of the Basilians' church (`church_cerkiew`, spec `cerkiew.md`), whose hall stands in the
courtyard between the two back wings.

## 1. Identity
1. A long **white four-storey wing** along Miodowa under a **grey hipped roof**.
2. The **middle risalit**: four giant pilasters on a rusticated ground floor, **three arched
   doors**, a low **pediment with a cross**.
3. Two back wings under hipped roofs round the church's hall; a low annex behind the west one.

## 2. Massing
Frame: origin (-1047.48, -1518.78), the street front's east corner; u along Miodowa west (axis
(0.822, 0.568)), v out of the front (the building at v < 0). Ground g is the lowest terrain
under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| street wing | u 0 to 39.4, v -6.9 to 0 | eaves 17.4; hipped roof to 20 |
| risalit | u 11.2 to 27, 0.35 out | 17.4, cornice to 17.75; pediment to 19.55 |
| east back wing | u 3.3 to 11, v -22 to -6.9 | 16.8; hipped roof to 19.8 |
| west back wing | u 27.1 to 35.8, v -20 to -6.9 | 16.8; hipped roof to 19.8 |
| end strips | u 0.6 to 3.4 and 35.7 to 39.3, v -9.6 to -6.9 | 16.8, flat |
| annex | u 27.1 to 35, v -24.8 to -20 | 4.4, flat |

LoD2: the wing's eaves about 17.4 and ridge 20; the pediment 19.4; the back wings 16 to 21; the
annex 4.4.

## 3. Facade: Miodowa
Four bays a side at u 1.5 to 9.6 and 28.6 to 37.6; three in the risalit at 14.15, 19.1, 24.05.
Ground floor rusticated (a groove every 0.75 m) to 4.3 under a string course; sills at 5.6, 9.8
and 13.7 (attic storey, lower panes); string courses under each row. In the risalit: pane heads
in trim, three round-headed doors (the middle one wider), the pilasters from 4.6 to the cornice.

## 4. The ends and the back wings
Flat panes in three rows on the wing's two ends and on the back wings' outer walls (defaults:
those walls face neighbours' courtyards and no photo reaches them). The courtyard walls are
hidden by the church's hall.

## 5. Roof
Grey sheet (#5d6268), the church's: hipped over the wing and both back wings; the pediment's
slopes run back into the wing's roof.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #ebe5d7 | M_STONE |
| Pilasters, cornices, frames, pediment | #f5f1e8 | M_STONE |
| Rusticated ground floor | #ddd5c4 | M_STONE |
| Roof | #5d6268 | M_STONE |
| Doors | #4b3c31 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor Bazylianów". No floodlights.

## 8. Detail level and budget
L1, triangle budget 1000 (measured 896, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_bazylianie`.

## 9. Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wing | prism + hipped roof | 39.4 x 6.9 m | u 0..39.4, v -6.9..0, y to 20 | #ebe5d7, #5d6268 | 1 street wing |
| back wings | prisms + hipped roofs | 7.8 x 15.1, 8.7 x 13.1 m | u 3.3..11, 27.1..35.8, y to 19.8 | #ebe5d7, #5d6268 | 2 wings |
| end strips, annex | boxes | 2.8 to 7.9 m | the outline's corners | #ebe5d7 | 3 blocks |
| risalit | box + cornice | 15.8 x 0.35 m | u 11.2..27, y to 17.75 | #ebe5d7, #f5f1e8 | 1 risalit |
| pilasters | boxes | 0.9 m | 4 in the risalit, y 4.6..17.4 | #f5f1e8 | 4 pilasters |
| doors | arched panels | 1.6 to 1.9 x 3.6 m | u 14.15, 19.1, 24.05 | #4b3c31, #f5f1e8 | 3 doors |
| pediment | triangle + slopes | 16.1 x 1.8 m | over the risalit, y 17.75..19.55 | #f5f1e8, #5d6268 | 1 pediment, 1 cross |
| rustication, courses | boxes | full width | y -1..4.6, sills 5.45, 9.65, 13.55 | #ddd5c4, #f5f1e8 | ground floor |
| windows | flat panes | 1.3 to 1.4 m wide | 11 bays x 4 rows; 3 rows on ends and back wings | PAL_GLASS_DARK | 54 panes |
