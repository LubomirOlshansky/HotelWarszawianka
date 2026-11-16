# Pawilon sióstr Rodziny Maryi (the low house by the Family of Mary convent, Wola) (site `rodziny_maryi_pawilon`)

Site key `rodziny_maryi_pawilon` in `game/scripts/landmarks.gd` (found by the OSM outline under
`RMP_AT` in `game/scripts/landmarks/churches.gd`: building 10482, tagged `religious`, unnamed;
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from Mapillary photos along the street (2020-2021,
refs/churches/religious_10482, reference only, never shipped). They show the convent's long peach
house and, at the corner, a low pavilion with a green copper hipped roof behind iron railings and
gate pavilions; which outline is that pavilion is read from the cameras' spots, so it is likely, not
certain.

## 1. Identity
1. A **low house** of the Franciscan Sisters of the Family of Mary, at the street corner east of
   their long banded house, in the convent's **peach plaster** under **green copper**.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (13 corners, about 28 by 16 m) at 7.6 m.

## 3. Facade
The block's walls in the convent's warm peach plaster (`RM_WALL`); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
Green copper, as the pavilion in the photos.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6c2a2 | skin (M_MONUMENT) |
| Roof | #7f9e86 | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Pawilon sióstr Rodziny Maryi". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: the hipped roof's shape (the skin colours the block's own roof), the cornice, the barred windows.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | peach plaster, green copper roof |
