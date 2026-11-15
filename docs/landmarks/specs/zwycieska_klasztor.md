# The monastery block beside Our Lady of Victory (Kamionek, Praga Południe): spec

**Provisional, no photo** (2026-11-15). It is built from LoD2 and the OSM outline only. No open
street photo reaches it (Mapillary and Panoramax: none within 50 m). The plaster, the tiles, the
windows and the door follow the church next door until a photo arrives (docs/QUESTIONS.md).

Site key `church_zwycieska_klasztor` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to `_build_zwycieska_klasztor`.
It is one model that replaces the plain OpenStreetMap block (building 1334, `monastery`,
unnamed). It stands about 45 m east of the co-cathedral (`church_zwycieska`), with Grochowska
about 90 m to the north. Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **five-storey plastered range** under a **red tile gable roof** with two chimneys.
2. A short **projection into the yard** on the south side, under its own small gable.

## 2. Massing
Frame: origin (2016.9, -1370.6), the north front's west corner. u runs along (0.9933, 0.1158),
east along the range; v points south into the yard. Heights are over g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| range | the outline (u 0..35.9, v 0..17.2) | eaves 15.9, gable ridge 17.9 along u |
| yard projection | u 13.3..22.6, v 17.2..18.4 | eaves 15.9, a small gable into the yard |
| chimneys | (22.6, 5.6) and (31.6, 14.3) | to 19.5 and 19.1 |

## 3. Facade (the north front, -v)
- Window columns about every 2.9 m, five rows (g+1.2, 4.3, 7.4, 10.5, 13.6), each window in a light reveal.
- A light band over the ground floor and a darker plinth.
- A cornice under the eaves.
- The door in the middle (u 17.3). Its place is a default.

## 4. The other sides
As section 3 (defaults).

## 5. Roof
Gables in red tile (#b0583b, a default after the church's tiles).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6dfcc (a default, the church's tone) | M_STONE |
| Bands, cornice, reveals | #f2eee3 | M_STONE |
| Roof | #b0583b (a default) | M_STONE |
| Door | #5b3326 (a default) | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor przy Matce Bożej Zwycięskiej".
No floodlights.

## 8. Detail level and budget
L1, triangle budget 1200 (measured 850, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_zwycieska_klasztor`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| range | outline prism + gable | 35.9 x 17.2 m | — | M_STONE | five rows of windows |
| projection | gable | 9.3 x 1.2 m | the yard side | M_STONE | small gable |
| chimneys | box | 1.2 x 2 m | on the roof | M_STONE | from LoD2 |
| door | kit_door | 1.6 m | u 17.3 on the north front | M_STONE | a default |
