# Plebania katedry św. Floriana (St Florian's cathedral presbytery, Floriańska, Praga): spec

Written 2026-11-15 from five Mapillary photos (2019 and 2020, refs/churches/plebania_florian,
CC BY-SA, reference only, never shipped): two along Floriańska and three from the yard gate on the
west. Also from the OSM outline and GUGiK's LoD2. The roofs are seen by no photo, so their colour
is a default until one arrives (docs/QUESTIONS.md).

Site key `church_plebania_florian` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to `_build_plebania_florian`.
It is one model that replaces the plain OpenStreetMap block (building 899, `presbytery`, named
"Plebania"). Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **range on Floriańska**: three tall storeys of **white plaster over a beige rusticated
   ground floor** with **round-headed windows** and a round-headed door. It has small caps over
   the upper windows and a cornice under a gable roof.
2. A **lower cream wing into the yard**, with plain white-framed windows, ending in a low
   flat-roofed block. Together they make a T in plan.

## 2. Massing
Frame: origin (525.0, -1990.5), the street front's west corner. u runs along (0.9845, 0.1753),
east along Floriańska; v points into the block. Heights are over g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| range on the street | u 0..29.7, v 0..12.8 | eaves 13.9, gable ridge 16.0 along u |
| yard wing | u 7.8..21.3, v 12.8..43.3 | eaves 12.1, gable ridge 13.9 along v |
| low block | u 7.6..21.4, v 43.3..48.1 | flat, 10.8 |

## 3. Facade (Floriańska, -v)
- Window columns about every 2.7 m.
- Ground floor: rusticated beige (three grooves) up to a light band at g+4.4. Round-headed windows g+0.9..3.6.
- Doors: a plain wooden door at u 3 and the round-headed main door at u 9.
- Upper floors: two rows of white-framed windows (g+5.5 and 9.3), each with a cap over it.
- A cornice under the eaves.

## 4. The other sides
- The range's ends and its yard side are as section 3, with square ground-floor windows.
- The wing has three rows of white-framed windows (g+1.2, 4.9, 8.6), seen in the yard photos.
- The low block has two plain rows.

## 5. Roof
Gables, dark sheet (#55504c, a default). The range's ridge runs along the street, and the wing's
runs into the yard, closed at its far end.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Range plaster | #ece6d8 (photos) | M_STONE |
| Rusticated ground floor | #d8c8a6 (photos) | M_STONE |
| Wing plaster | #e8d8ad (photos) | M_STONE |
| Frames, caps, bands, cornice | #f4f1ea | M_STONE |
| Roof | #55504c (a default) | M_STONE |
| Doors | #6a4a30 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Plebania katedry św. Floriana". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1500 (measured 1352, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_plebania_florian`, plus a city shot from above Floriańska.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| range | outline prism + gable | 29.7 x 12.8 m | on Floriańska | M_STONE | rusticated base, round-headed windows |
| wing | outline prism + gable | 13.5 x 30.5 m | into the yard | M_STONE | white-framed windows |
| low | outline prism | 13.8 x 4.8 m | the wing's end | M_STONE | flat roof |
| doors | kit_door | 1.4 and 1.7 m | u 3 and 9 on the street | M_STONE | the main door round-headed |
