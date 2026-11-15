# Dom zakonny na Żytniej (the convent range on Żytnia's south side by Wolność, Wola): spec

Written 2026-11-15 from Mapillary photos (2020 and 2025, refs/churches/rodziny_maryi_dom, CC BY-SA,
reference only, never shipped): four along Żytnia and one across the Wolność corner. Also from
the OSM outline and GUGiK's LoD2. The street front and the west end are in the photos; the yard
side is not, so it is a default (docs/QUESTIONS.md).

Site key `church_zytnia_dom_zakonny` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to `_build_zytnia_dom_zakonny`.
It is one model that replaces the plain OpenStreetMap block (building 4473, `religious`, unnamed).
It stands on Żytnia's south side at the Wolność corner, between St Faustina's convent and the
Family of Mary sisters' church. Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **long two-storey range of cream plaster on a red brick plinth** along the street.
2. A **rusticated ground floor with barred windows**, a band, upper windows with sills and small
   caps, a cornice.
3. A grey gable roof.

## 2. Massing
Frame: origin (-2699.1, -732.6), the street front's west corner on Wolność. u runs along
(0.9307, -0.3657), east-south-east along Żytnia; v points south into the block. Heights are over
g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| range | the outline (u 0..39.8, v 0..8.0) | eaves 7.8, gable ridge 9.8 along u |

## 3. Facade (Żytnia, -v)
- A brick plinth up to g+1.0, two grooves in the ground floor's plaster, a band at g+3.6 and a
  cornice under the eaves.
- Window columns about every 3.2 m:
  - ground floor: dark barred windows (g+1.3);
  - upper floor: brown-framed windows (g+4.6), with a sill under each and a cap over it.

## 4. The other sides
The west end on Wolność is as section 3 (photo). The yard side and the east end are as section 3
too, as defaults.

## 5. Roof
A gable in grey sheet (#55585c), the colour seen at the roof's edge in the photos.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e9d8b2 (photos) | M_STONE |
| Plinth | #8b4a36 (photos) | M_STONE |
| Sills, caps, band, cornice | #f1e8d2 | M_STONE |
| Window frames | #6a3f2a (photos) | M_STONE |
| Roof | #55585c (photos) | M_STONE |
| Windows | PAL_GLASS_DARK, PAL_DARK_DOOR bars | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Dom zakonny na Żytniej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 900 (measured 582, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_zytnia_dom_zakonny`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| range | outline prism + gable | 39.8 x 8.0 m | on Żytnia | M_STONE | brick plinth, rusticated ground floor |
