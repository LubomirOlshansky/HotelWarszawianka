# Dom zakonny na Żytniej, skrzydło (the long range behind the convent on Żytnia, Wola): spec

**Provisional, no photo** (2026-11-15). It is built from LoD2 and the OSM outline only. No open
photo reaches the yard, so its walls follow the street range in front (`zytnia_dom_zakonny.md`)
until a photo arrives (docs/QUESTIONS.md).

Site key `church_zytnia_dom_zakonny_tyl` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to
`_build_zytnia_dom_zakonny_tyl`. It is one model that replaces the plain OpenStreetMap block
(building 10480, `religious`, unnamed). It stands inside the block south of the convent range on
Żytnia, with its north wall on the yard between them. Its area is in `tools/bake_sectors.py`
SITE_AREAS.

## 1. Identity
1. A **long two-storey range** (66 m) in the street range's **cream plaster on a red brick
   plinth**, under a **low grey roof**.
2. A **lower annex** at the east end.

## 2. Massing
Frame: origin (-2679.6, -701.0), the north wall's west corner. u runs along (0.9514, -0.3084),
east-north-east; v points south. Heights are over g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| range | u -1.4..53.8, v 0..8.5 | eaves 6.4, a low gable ridge 8.0 along u |
| east annex | u 53.8..66.2, v 2.9..8.4 | flat, 5.2 |

## 3. Facade (the yard, -v)
These are defaults after the street range:
- a brick plinth up to g+0.9, two grooves in the ground floor's plaster, a band at g+3.0 and a cornice;
- window columns about every 3.2 m: dark barred windows on the ground floor (g+1.1), and brown-framed upper windows (g+3.7) with sills and caps.

## 4. The other sides
As section 3 (defaults).

## 5. Roof
LoD2 shows a low roof (6.2 to 8 m) and no clear ridge. It is built as a low gable in grey sheet
(#55585c), with the annex flat.

## 6. Colour and material
The street range's constants (`ZYT_*`): plaster #e9d8b2, plinth #8b4a36, trim #f1e8d2, frames
#6a3f2a, roof #55585c, all M_STONE; windows PAL_GLASS_DARK and PAL_DARK_DOOR bars, lit by chance
at night (`_lit`). No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Dom zakonny na Żytniej, skrzydło". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1500 (measured 1299, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_zytnia_dom_zakonny_tyl`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| range | outline prism + gable | 55 x 8.5 m | inside the block | M_STONE | the street range's walls |
| annex | outline prism | 12.4 x 5.5 m | the east end | M_STONE | flat roof |
