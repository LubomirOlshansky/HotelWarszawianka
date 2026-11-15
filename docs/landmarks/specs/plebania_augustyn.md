# Plebania św. Augustyna (St Augustine's presbytery, Nowolipki): spec

**Provisional, no photo** (2026-11-15). Built from LoD2 and the OSM outline: no street photo of the house is on Mapillary or Panoramax within 45 m, and the church's 11 Commons photos (refs/churches/st_augustine_nowolipki, reference only, never shipped) face the church, so the plaster, the windows and the door are defaults until one does (docs/QUESTIONS.md).

Site key `church_plebania_augustyn` in `game/scripts/landmarks/churches.gd` (`_find_churches`
finds it by the OSM outline under `at`, `_build_church` hands it to `_build_plebania_augustyn`):
one model that replaces the plain OpenStreetMap block (building 1192, `presbytery` "Plebania"),
about 68 m south of the church. Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **two-storey post-war house under a flat roof** with a **raised middle block**.
2. The entrance in a **recess on the west side**.

## 2. Massing
Frame: origin (-2406.0, -1124.2), the house's south corner; u along (0.466, 0.884) to the
north-north-east, v to the west-north-west. Heights over g (LoD2; g about 13).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u -4..14.6, v 0..14.4), the recess at u 4.5..7.4, v 11.3..14.1 | roof 8 |
| middle block | u 0..10, v 4.2..11 | 10 |

## 3. Facade
Two rows of plain windows (g+1.3, g+4.6) round every wall long enough for one; a light coping
and plinth band; the door at the back of the recess (defaults: no photo).

## 4. The other sides
As section 3 on every side (defaults).

## 5. Roof
Flat, grey felt (#77736c), the middle block's top a shade darker, copings round both.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e3dccd (a default) | M_STONE |
| Copings, plinth | #cfc7b6 | M_STONE |
| Roof | #77736c | M_STONE |
| Door | #4a3a2c | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Plebania św. Augustyna". No floodlights.

## 8. Detail level and budget
L1, triangle budget 500 (measured 311, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_plebania_augustyn`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 8 m | — | #e3dccd | coping and plinth rings |
| middle block | prism | 10 x 6.8 m, 2 m | the middle | #e3dccd | coping ring |
| door | kit door | 1.2 x 2.4 m | in the recess | #4a3a2c | — |
