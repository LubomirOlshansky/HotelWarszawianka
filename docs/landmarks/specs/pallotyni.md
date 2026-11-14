# Dom pallotynów (the Pallottine house), Skaryszewska 12: spec

Site key `church_pallotyni` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_pallotyni`): the Pallottines' house as
one model that replaces the plain OpenStreetMap block (building 3045). Its area is in
`tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from a Mapillary photo of 2019 across
Skaryszewska (refs/pallotyni, never shipped), the OSM outline and GUGiK's LoD2.

## 1. Identity
1. A **1930s modernist block** in a **beige textured render**, flat roofs at four heights.
2. **White-framed ribbon windows**.
3. The low west block with **terraces and planters** along the street under a **setback top
   storey**; the east block's upper floor **oversails** a recessed ground floor.

## 2. Massing
Frame: origin (1748.0, -1711.3), the street front's west corner; u along Skaryszewska east (axis
(0.829, 0.560)), v into the block. Ground g is the lowest terrain under the outline (the street
is about 0.9 above it).

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| west block | the outline's west part, u -7.5 to 29.5 | 9.9, flat |
| setback storey | u 5 to 21, v 8 to 15.5 | 12.4, flat |
| east block | u 29.6 to 51.2, v 0 to 24 | 11.6 over a ground floor set back 0.8 to 4.4 |
| east top storey | u 29.7 to 48.2, v 6.5 to 18 | 13.8, flat |

## 3. Facade: Skaryszewska
A ribbon window in a white frame on the west block's ground floor; planters along its roof
edge; a ribbon on the setback storey. On the east block, a ribbon on the upper floor and one on
the recessed ground floor.

## 4. The other sides
Ribbons on every other side, one or two floors (defaults: the photo shows the street front).

## 5. Roof
Flat roofs in grey (#8c8b86) with white copings.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #d8cba2 | M_STONE |
| Window frames, copings | #f2f0ea | M_STONE |
| Roofs | #8c8b86 | M_STONE |
| Planters | #6d6a62, #5f7a45 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Dom pallotynów". No floodlights.

## 8. Detail level and budget
L1, triangle budget 840 (measured 726, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_pallotyni`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| west block | prism | 37 x 24 m | the outline's west part, y to 9.9 | #d8cba2, #8c8b86 | 1 block |
| setback | box | 16 x 7.5 m | u 5..21, y to 12.4 | #d8cba2, #8c8b86 | 1 storey |
| east block | two prisms | 21.6 x 24 m | u 29.6..51.2, y to 11.6 | #d8cba2, #8c8b86 | 1 block, recessed ground floor |
| east top | box | 18.5 x 11.5 m | y to 13.8 | #d8cba2, #8c8b86 | 1 storey |
| ribbons | frame box + panes | 1.2 to 1.3 m bays | every side | #f2f0ea, PAL_GLASS_DARK | 15 ribbons |
| planters | boxes | 1.2 m | the west roof's street edge | #6d6a62, #5f7a45 | 7 planters |
