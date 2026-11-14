# Kościół Chrześcijan Baptystów (the Baptist church), Waliców 25: spec

Site key `church_baptysci` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_baptysci`): the church as one model that
replaces the plain OpenStreetMap block (building 7442). Its area is in `tools/bake_sectors.py`
SITE_AREAS. Written 2026-11-14 from 8 Commons photos (refs/churches/baptist_walicow, reference
only, never shipped), the OSM outline and GUGiK's LoD2.

## 1. Identity
1. A **modernist box**: a **blank light grey concrete upper storey** overhanging a **glazed
   ground floor** set back under it.
2. A **big dark cross** on the front and a **line of lettering** along the foot of the box.

## 2. Massing
Frame: origin (-2255.3, -359.0), the outline's centre; u along the front on axis (0.265, 0.964),
v to its left; the front faces Waliców (-v). Heights over g, the lowest ground under the outline.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| ground floor | u -7..15, v -9..9 | 3.3 |
| box | u -8..16, v -10..10 | 8.6, flat |

## 3. Facade: the front on Waliców
The cross (3.4 m tall) toward the front's right end, the lettering as a dark band at 3.75 to 4.05.

## 4. The other sides
Glazing all round the ground floor in 1.9 m bays; the box blank on every side.

## 5. Roof
Flat, grey (#9a978f), with a thin coping.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Box | #d6d4cc | M_STONE |
| Ground floor, lettering | #8e8b84 | M_STONE |
| Cross | #4e3628 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Kościół Baptystów". No floodlights. The
four-storey extension behind it (a building site in 2025) is left out.

## 8. Detail level and budget
L1, triangle budget 200 (measured 146, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_baptysci`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| ground floor | prism | 22 x 18 m | set back 1 m | #8e8b84 | glazing all round |
| box | prism | 24 x 20 m | over it | #d6d4cc, #9a978f | 1 box |
| cross | 2 boxes | 2.6 x 3.4 m | the front | #4e3628 | 1 cross |
| lettering | box | 21 m | the front's foot | #6a6863 | 1 band |
