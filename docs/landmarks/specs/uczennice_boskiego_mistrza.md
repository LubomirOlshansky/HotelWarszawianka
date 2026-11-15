# Dom Sióstr Uczennic Boskiego Mistrza (the Sister Disciples of the Divine Master, Ochota): spec

Written 2026-11-15 from seven Mapillary photos taken on the street to the north (2017 and 2025,
refs/churches/uczennice_boskiego_mistrza, CC BY-SA, reference only, never shipped), the OSM outline
and GUGiK's LoD2. The back walls and the chapel's raised block are seen by no photo, so they are
defaults until one arrives (docs/QUESTIONS.md).

Site key `church_uczennice_boskiego_mistrza` in `game/scripts/landmarks/churches.gd`
(`_find_churches` finds it by the OSM outline under `at`, `_build_church` hands it to
`_build_uczennice_boskiego_mistrza`): one model that replaces the plain OpenStreetMap block
(building 2846, `convent`). Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **five-storey red-brick convent** of the 1990s, a T in plan with the long wing to the south.
2. Each column of windows sits in a **cream plaster strip**; wide windows on the ground floor.
3. The **chapel's raised block** with a low hipped roof in the middle of the flat roof.

## 2. Massing
Frame: origin (-2919.2, -669.7), the front's west corner; u along (0.973, -0.231) to the east along
the street, v to the south into the block. Heights over g (LoD2; g about 12).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u 0..37.5, v 0..41.5), the entrance recess at u 16.7..21, v 0..4 | roof 19 |
| chapel block | u 17.2..28.8, v 12.7..25.9 | 21, hip ridge 23 |

## 3. Facade (the street, -v)
Window columns every 3.3 m: cream strips from g+3.8 to the coping, four rows of upper windows
(g+4.6, 8.0, 11.4, 14.8), wide ground-floor windows (g+0.9), a brick band at g+3.4; the
entrance's dark glass doors at the back of the recess; a dark brick coping.

## 4. The other sides
As section 3 on every wall (defaults: no photo of the back).

## 5. Roof
Flat, grey (#6d6a66); the chapel block's low hip in the same grey (a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #a5503a (photos) | M_STONE |
| Window strips | #e9dfc6 (photos) | M_STONE |
| Coping, bands | #7e3d2e | M_STONE |
| Roofs | #6d6a66 (a default) | M_STONE |
| Doors | #3a3533 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Siostry Uczennice Boskiego Mistrza". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1400 (measured 1179, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_uczennice_boskiego_mistrza`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 19 m | — | #a5503a | coping ring |
| strips | boxes | 1.7 m wide | behind each window column | #e9dfc6 | — |
| chapel | prism + hip | 11.6 x 13.2 m, 2 + 2 m | on the roof | #a5503a / #6d6a66 | — |
| entrance | kit door | 2.6 x 2.8 m | in the recess | #3a3533 | — |
