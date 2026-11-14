# Dom Zakonny Sióstr Franciszkanek Służebnic Krzyża (the Franciscan Sisters' house), Piwna 9/11: spec

Site key `church_franciszkanki_piwna` in `game/scripts/landmarks.gd` (`_find_churches` finds it
by the OSM outline under `at`, `_build_church` hands it to `_build_franciszkanki_piwna`): the
sisters' house, the old Augustinian monastery by St Martin's, as one model that replaces the
plain OpenStreetMap block (building 1676). St Martin's tower stands in this block on Piwna and is
the church's own model (`_build_marcin`, `MAR_TU`/`MAR_TV`). Its area is in
`tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from 9 Commons photos
(refs/churches/franciscan_sisters_piwna, reference only, never shipped), the OSM outline and
GUGiK's LoD2.

## 1. Identity
1. A **long ochre front on Piwna** with three rows of windows in stone surrounds.
2. The **arched stone portal** under a cartouche.
3. St Martin's brick-and-white tower rising out of the block (the church's model).

## 2. Massing
Frame: origin (-772.0, -1582.8), the front's north corner on Piwna, u along Piwna on axis
(0.6253, 0.7804), +v into the block. Heights over g.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the whole outline | eaves 10.5 |
| Piwna range roof | u -4.35..25.35, v -0.9..10.1 | hip, rise 4.4 |
| long range roof | u 5.4..20.4, v 8.3..43.7 | hip, rise 4.5 |
| back range roof | u -2.5..5.5, v 26..43.9 | hip, rise 3.5 |

## 3. Facade: Piwna
Three rows of windows (sills 1.6, 4.9, 8.0), the first-floor ones in stone surrounds, none where
the tower stands (u -1.2..7.2). The portal at u 12.85: a stone surround to 4.6, an arched dark
door, a cartouche over it. A stone plinth band. A stone cornice under the eaves.

## 4. The other sides
Windows on three rows on every other wall at least 4 m long (defaults: the courtyards and the
church side are not in the photos).

## 5. Roof
Hipped, in tile (#9a5040): a default, no photo shows the roofs.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e2b86c | M_STONE |
| Portal, surrounds, cornice, plinth | #d8cfbd | M_STONE |
| Roof | #9a5040 | M_STONE |
| Door | #3b3430 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Siostry na Piwnej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 1100 (measured 969, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_franciszkanki_piwna`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 10.5 m | — | #e2b86c | cornice |
| roofs | 3 hips | 29.7 x 11, 15 x 35.4, 8 x 17.9 m | the ranges | #9a5040 | — |
| Piwna front | panes, boxes, door | 29.4 m | -v | #d8cfbd, glass | surrounds, portal, cartouche |
| other windows | panes | 1 x 1.6 m | every wall over 4 m | PAL_GLASS_DARK | 3 rows |
