# Kaplica pw. św. Barbary (St Barbara's chapel), Koszyki: spec

Site key `church_barbara` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_barbara`): the chapel as one model that
replaces the plain OpenStreetMap block (building 1521), by the Sts Peter and Paul church. Its area
is in `tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from 2 Commons photos
(refs/churches/st_barbara_koszyki, reference only, never shipped; trees and the fence hide most
of it), the OSM outline and GUGiK's LoD2.

## 1. Identity
1. A **red brick chapel** under a **steep dark roof**, with **gables at both ends**.
2. A low annex on its north side.

## 2. Massing
Frame: origin (-1102.0, 874.5), the outline's centre; u along the chapel on axis (0.342, 0.940),
v to its left. Heights over g, the lowest ground under the outline.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| chapel | u -7.56..7.7, v -4.67..4.38 | eaves 8.9, ridge 11.9 |
| annex | u -7.5..7.7, v 4.44..7.4 | 3.2, flat |

## 3. Facade: the west gable
A stone-framed arched door, two tall windows, a round window in the gable, an iron cross on top.

## 4. The other sides
Three tall windows on each long side (over the annex on the north), the annex's low windows, two
tall windows and a round one on the east gable. The windows are defaults: no photo shows them.

## 5. Roof
Dark grey (#4b4d50), steep, with gables at both ends.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #a4553f | M_STONE |
| Plinth, cornice, door frame | #cfc6b4 | M_STONE |
| Roof | #4b4d50 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Kaplica św. Barbary". No floodlights.

## 8. Detail level and budget
L1, triangle budget 220 (measured 156, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_barbara`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| chapel | prism, gable | 15.3 x 9 m | the outline | #a4553f, #4b4d50 | plinth, cornice |
| annex | box | 15.2 x 3 m | north side | #a4553f, #4b4d50 | low windows |
| openings | panes, discs, door | — | all sides | PAL_GLASS_DARK | 12 windows, 2 round, 1 door, cross |
