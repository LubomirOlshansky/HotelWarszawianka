# Dom pallotynów przy Skaryszewskiej (the Pallottine fathers' house behind Christ the King, Praga) (site `pallotyni_dom`)

Site key `pallotyni_dom` in `game/scripts/landmarks.gd` (found by the OSM outline under
`PDM_AT` in `game/scripts/landmarks/churches.gd`: building 3049, tagged `monastery`, unnamed;
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from the OSM outline and the church model next to it
(`church_chrystusa_krola`). No open photo faces it: one Mapillary photo within 45 m looks away.
**Provisional.**

## 1. Identity
1. The Pallottine fathers' **house**, a tall block at the north corner of the Christ the King
   church's plot on Skaryszewska, in the **parish wings' plaster** of the church model.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (16 corners, about 35 by 33 m) at 17.5 m.

## 3. Facade
The block's walls in the parish wings' plaster (`CK_WING`, the church model's; a default); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
The church block's grey roofs (`CK_TILE`; a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6dcc4 | skin (M_MONUMENT) |
| Roof | #8a8a84 (the church's, a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Dom pallotynów przy Skaryszewskiej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: everything a photo would show: the windows' rhythm, the entrance, the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | parish wings' plaster, grey roof |
