# Siostry Szarytki na Tamce (the Sisters of Charity, Tamka 35; site `szarytki`)

Site key `szarytki` in `game/scripts/landmarks.gd` (found by the unnamed OSM outline under
`SZT_AT`, building 12823; its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15
from F's 11 Commons photos (refs/churches/szarytki_tamka, reference only, never shipped) and
GUGiK's LoD2.

## 1. Identity
1. **Long white two-storey ranges** round a courtyard below the escarpment.
2. **Tall dull green copper roofs** with rows of white dormers (photos 01, 02).
3. A **slim green turret with an onion** on the ridge (photos 01, 02).

## 2. Massing
LoD2's mass kept (the ranges, the courtyard, ridges about 14 m over the ground), in its skin.

## 3. Facade
LoD2's walls in white plaster; the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
LoD2's roofs in green copper (`steep` 0.3, so the tall slopes keep the roof colour). The turret
stands on the ridge where the south range meets the west one (its place is a default: photo 02
shows it from the escarpment, not its spot): a square copper base, a white drum with dark
openings, an onion, a cross. Not built: the dormers (the roofs are LoD2's).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e9e7e0 | skin (M_MONUMENT) |
| Roofs, turret | #7c9171 | skin; turret M_STONE |
| Turret openings | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision. Card: "Siostry Szarytki na Tamce". No floodlights.

## 8. Detail level and budget
L1, triangle budget 300 (measured 138, the turret only, `check_mesh_quality.gd`). Shots: the city
shot from the courtyard side (the turntable shows only the turret).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the outline | — | skin | white and green copper |
| turret | box, drum, onion | 2 m base, 6 m tall | on the ridge | M_STONE | cross |
