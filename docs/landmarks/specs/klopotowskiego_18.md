# Kłopotowskiego 18 (the church house with the "Okno Życia" window of life, Praga): spec

Written 2026-11-15 from eight Mapillary photos along Kłopotowskiego (2020 to 2026,
refs/churches/klopotowskiego_8886, CC BY-SA, reference only, never shipped). The clearest is one
2020 photo facing the door. Also from the OSM outline and GUGiK's LoD2. The roof and the yard
walls are seen by no photo, so they are defaults until one arrives (docs/QUESTIONS.md).

Site key `church_klopotowskiego_18` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to `_build_klopotowskiego_18`.
It is one model that replaces the plain OpenStreetMap block (building 8886, `religious`, unnamed).
Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **four-storey house on Kłopotowskiego**: **white plaster over a cream rusticated ground
   floor** on a grey plinth, with dark brown window frames.
2. The **door (no. 18) in a grey stone surround under a dark canopy**. Beside it is the **window
   of life** under a red band, with an **iron balcony** above it.
3. A hipped roof, and a lower wing into the yard.

## 2. Massing
Frame: origin (531.8, -1805.0), the street front's west corner. u runs along (0.8193, -0.5604),
east-south-east along Kłopotowskiego; v points into the block. Heights are over g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| street range | u 0..21.4, v 0..14.1 | eaves 13.2, hip ridge 17 |
| yard wing | u 15.8..23.2, v 14.1..41.9 | 13.4 flat (LoD2's lean-to, 13 to 15, at its mean) |

## 3. Facade (Kłopotowskiego, -v)
- Ground floor: rusticated cream (three grooves) from g+0.7 to a band at g+3.7, on a grey plinth.
- Five tall dark-framed ground-floor windows (u 2.0, 4.6, 11.4, 14.6, 17.8), each with a light cap.
- The door at u 8 in a grey surround, 2.6 m wide, under a dark canopy at g+3.
- A red band over the window of life (u 11.4), and an iron balcony over it at g+4.6.
- Three upper rows of dark-framed windows (g+4.6, 7.6, 10.6), one about every 3.3 m.
- A cornice under the eaves.

## 4. The other sides
The plinth, the rusticated ground floor and the upper rows go all round; the ground floor has
smaller windows. These are defaults, as no photo shows the yard.

## 5. Roof
Hipped over the street range and flat over the wing, in grey sheet (#5d5f60, a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Upper plaster | #ecebe6 (photos) | M_STONE |
| Rusticated ground floor | #e4dcbc (photos) | M_STONE |
| Plinth | #9b9d9b (photos) | M_STONE |
| Door surround | #a9aba8 (photos) | M_STONE |
| Window frames | #4e3a2c (photos) | M_STONE |
| Caps, bands, cornice | #f5f4f0 | M_STONE |
| Roof | #5d5f60 (a default) | M_STONE |
| Door | #5b3528 (photos) | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Okno Życia na Kłopotowskiego". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1500 (measured 1288, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_klopotowskiego_18`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| range | outline prism + hip | 21.4 x 14.1 m | on Kłopotowskiego | M_STONE | rusticated base, cornice |
| wing | outline prism | 7.4 x 27.8 m | into the yard | M_STONE | flat roof |
| door | kit_door + surround + canopy | 1.3 m | u 8 on the street | M_STONE | no. 18 |
| balcony | kit_balcony IRON | 1.8 x 0.6 m | over u 11.4, g+4.6 | M_STONE | over the window of life |
