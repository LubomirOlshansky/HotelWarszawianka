# Siostry Matki Bożej Miłosierdzia, the range on Żytnia (Żytnia 3/9, Wola): spec

Written 2026-11-15 from six Mapillary photos on Żytnia (2020-2021, refs/churches/wola_2785, CC
BY-SA, reference only, never shipped), the OSM outline and GUGiK's LoD2. The roof and the yard side
are seen by no photo, so they are defaults until one arrives (docs/QUESTIONS.md). The convent of
the Sisters of Our Lady of Mercy is St Faustina's (the shrine is `church_miloserdzie`); this is its
range on the street west of the church.

Site key `church_siostry_milosierdzia_zytnia` in `game/scripts/landmarks/churches.gd`
(`_find_churches` finds it by the OSM outline under `at`, `_build_church` hands it to
`_build_siostry_milosierdzia_zytnia`): one model that replaces the plain OpenStreetMap block
(building 2785, an unnamed `religious` building). Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **four-storey red-brick range** on Żytnia over a **pale plinth** with barred basement windows.
2. Each column of windows in a **white strip**.
3. The **white stone portal** in the middle of the front, under a little gable.

## 2. Massing
Frame: origin (-2813.5, -695.3), the front's west corner; u along (0.965, -0.262) to the east along
Żytnia, v to the south into the block. Heights over g (LoD2; g about 13).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u 0..42.8, v -0.5..16.2) | eaves 15.5 |
| roof | gable along u, ridge at v 8.1 | ridge 18 |
| portal | u 18..23.8, v -0.76..0 | 4.6, gable to 6 |

## 3. Facade (Żytnia, -v)
Window columns every 3.3 m, each in a white strip from g+1.6 to under the eaves; four rows of
windows (g+2.0, 5.4, 8.8, 12.1); small barred windows in the plinth (g+0.2); the arched door in
the portal; a dark brick cornice.

## 4. The other sides
As section 3 on every wall (defaults: no photo of the yard side). The gable ends in brick.

## 5. Roof
A low gable along Żytnia, grey sheet (#5f6163, a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #a24f3a (photos) | M_STONE |
| Window strips, portal | #ebe8e1 (photos) | M_STONE |
| Plinth | #c9c8c2 (photos) | M_STONE |
| Roof | #5f6163 (a default) | M_STONE |
| Door | #5b3d2a | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Siostry Matki Bożej Miłosierdzia". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1200 (measured 874, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_siostry_milosierdzia_zytnia`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 15.5 m | — | #a24f3a | plinth and cornice rings |
| roof | gable | 42 x 16.4 m, rise 2.5 | over the walls | #5f6163 | — |
| strips | boxes | 1.6 m wide | behind each window column | #ebe8e1 | — |
| portal | box, arched door, gable | 5.1 x 4.6 m | middle of the front | #ebe8e1 | — |
