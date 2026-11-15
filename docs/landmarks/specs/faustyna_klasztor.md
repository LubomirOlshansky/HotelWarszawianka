# Klasztor przy sanktuarium św. Faustyny (the Sisters of Our Lady of Mercy's houses round the shrine, Żytnia; site `faustyna_klasztor`)

Site key `faustyna_klasztor` in `game/scripts/landmarks.gd` (found by the OSM outlines under
`FKL_AT` in `game/scripts/landmarks/churches.gd`: buildings 4468, 4469 and 10477; its area is in
`tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from two Mapillary photos on Żytnia
(refs/churches/faustyna_klasztor and refs/churches/wola_4469, reference only, never shipped), the
shrine's spec (`miloserdzie.md`) and GUGiK's LoD2. The photos show the shrine's white street
front; the convent ranges behind it are not in any photo.

## 1. Identity
1. The **convent ranges** east and south of the shrine read as **one white plastered house** with
   the church, under the church's **grey roofs**.
2. Before this site they were three unrelated LoD2 blocks (pink tiles, red brick, grey), so the
   shrine stood in a patchwork.

## 2. Massing
LoD2's mass kept as it is (eaves 11 to 14 m; irregular roofs, which is why it is a skin and not a
model).

## 3. Facade
LoD2's walls in white plaster; the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
LoD2's roofs in the church's grey sheet.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ece9e2 | skin (M_MONUMENT) |
| Roofs | #606366 | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
LoD2's collision. Card: "Klasztor przy sanktuarium św. Faustyny". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row) and no turntable
(`tools/turntable.sh` frames sites that build triangles). Checked with a city before/after shot
from above the shrine. Not included: buildings 4473 and 10480 south of the yard (they may belong
to another house; left as they are).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | LoD2 | the three outlines | — | skin | white plaster, grey roofs |
