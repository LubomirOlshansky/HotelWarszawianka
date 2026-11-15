# Kościół Adwentystów Dnia Siódmego (the Seventh-day Adventist church, Foksal 8; site `adwentysci`)

Site key `adwentysci` in `game/scripts/landmarks.gd` (found by the unnamed OSM outline under
`ADW_AT`, building 5399; its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15
from F's 5 Commons photos (refs/churches/adwentysci_foksal, reference only, never shipped) and
GUGiK's LoD2.

## 1. Identity
1. A **four-storey pale yellow house** set back behind a front garden and a low fence on Foksal.
2. The church's **name in letters over the ground floor**, an **arched gate** at the west end,
   **iron balconies** at the east end.

## 2. Massing
LoD2's mass kept (four storeys, about 14 m), in its skin.

## 3. Facade (the front on Foksal)
The skin's windows; ours: the light arched gate surround with dark brown leaves (photo 03), the
white band over the ground floor where the name runs (the letters are not built), two iron
balconies on the first and second floors at the east end (photos 01, 02).

## 4. The other sides
LoD2's walls in the skin (the courtyard sides are not in the photos).

## 5. Roof
LoD2's roof in grey (#7b7d7f, a default: no photo shows it).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ead9a2 | skin (M_MONUMENT) |
| Roof | #7b7d7f | skin |
| Gate surround, band, balcony slabs | #f2ecd9 | M_STONE |
| Gate leaves | #4a2c22 | M_STONE |
| Balcony rails | #2a2a2c | M_STONE |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision. Card: "Kościół Adwentystów na Foksal". No floodlights.

## 8. Detail level and budget
L1, triangle budget 500 (measured 290, `check_mesh_quality.gd`; the balconies hang on LoD2's wall,
listed as known floats). Shots: the city shot from Foksal.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the outline | — | skin | pale yellow |
| gate | box, arched door | 2.8 x 4 m | front, west end | M_STONE | dark leaves |
| band | ledge | the front less 5 m each end | over the ground floor | M_STONE | the name's place |
| balconies | 2 iron balconies | 2.6 m | front, east end | M_STONE | first and second floors |
