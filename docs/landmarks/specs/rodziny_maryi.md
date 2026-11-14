# Zgromadzenie Sióstr Franciszkanek Rodziny Maryi (the Franciscan Sisters of the Family of Mary): spec

Site key `church_rodziny_maryi` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the
OSM outline under `at`, `_build_church` hands it to `_build_rodziny_maryi`): the sisters' house as
one model that replaces the plain OpenStreetMap block (building 3328). Its area is in
`tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from two Mapillary photos of 2020 on the
street at its north end (refs/rodziny, never shipped), the OSM outline and GUGiK's LoD2.

## 1. Identity
1. A long, low **classicist house in warm peach plaster**, banded all over, on a granite plinth,
   under **dark hipped roofs**.
2. Its **street end** has tall **blind windows** (recessed panels) with small attic windows
   over them.
3. A **taller two-storey middle block** under its own hipped roof, with a low annex on its west
   side.

## 2. Massing
Frame: origin (-2631.6, -759.0), the street end's west corner; u along that end (axis (0.934,
-0.356)), v along the house away from the street. Ground g is the lowest terrain under the
outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| end wings | u 0 to 13.5, v 0 to 13 and 34.5 to 49.4 | eaves 6.4; hipped roofs to 9.4 |
| middle block | u -0.9 to 14.5, v 13 to 34.5 | eaves 9.4; hipped roof to 11.4 |
| west annex | u -4 to -0.9, v 18.7 to 28.3 | 5.4, flat |

LoD2 (absolute, the ground about 14.4 to 14.9): the end wings' eaves 21 and ridges 24, the
middle's eaves 24 and ridge 26, the annex 20.

## 3. Facade: the street end
Bands every 0.55 m from the plinth to the cornice. Five blind windows (1.4 by 3.3 m, recessed
in a darker tone, a sill each) with five small attic windows (0.8 m) over them.

## 4. The other sides
One row of windows on the end wings, two on the middle block, one over the annex (defaults:
the photos show only the street end).

## 5. Roof
Dark grey sheet (#4d5257), hipped on all three blocks.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #e6c2a2 | M_STONE |
| Blind windows | #d9b292 | M_STONE |
| Cornices, sills | #efd9c3 | M_STONE |
| Plinth | #b5a48f | M_STONE |
| Roofs | #4d5257 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Siostry Rodziny Maryi". No floodlights.

## 8. Detail level and budget
L1, triangle budget 720 (measured 622, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_rodziny_maryi`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| end wings | prisms + hips | 13.5 x 13, 13.5 x 14.9 m | v 0..13, 34.5..49.4, y to 9.4 | #e6c2a2, #4d5257 | 2 wings |
| middle | prism + hip | 15.4 x 21.6 m | v 13..34.5, y to 11.4 | #e6c2a2, #4d5257 | 1 block |
| annex | box | 3.1 x 9.6 m | u -4..-0.9, y to 5.4 | #e6c2a2 | 1 annex |
| bands | boxes | 13.5 m | the street end, every 0.55 m | #e6c2a2 | banded plaster |
| blind windows | boxes | 1.4 x 3.3 m | the street end, 5 | #d9b292, #efd9c3 | 5 panels, 5 sills |
| windows | flat panes | 0.8 to 1.2 m | 1 or 2 rows a side | PAL_GLASS_DARK | every side |
