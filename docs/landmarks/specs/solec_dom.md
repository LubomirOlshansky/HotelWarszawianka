# Dom przy kościele Świętej Trójcy na Solcu (Holy Trinity parish's house, Powiśle) (site `solec_dom`)

Site key `solec_dom` in `game/scripts/landmarks.gd` (found by the OSM outline under
`SLD_AT` in `game/scripts/landmarks/churches.gd`: building 1000, tagged `religious`, unnamed;
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from the OSM outline and the neighbouring model,
Holy Trinity church on Solec (`church_trojca_praga`, SL_*): no open photo within 45 m.
**Provisional.**

## 1. Identity
1. Holy Trinity parish's house on Solec, beside Holy Trinity on Solec, Powiśle, in the colours of the neighbouring model until a photo arrives.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (7 corners, about 29 by 24 m) at 10.9 m.

## 3. Facade
The block's walls in the church's cream plaster (`SL_WALL`; a default); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
The church's grey sheet roof (`SL_ROOF`; a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e2d6bc | skin (M_MONUMENT) |
| Roof | #63696e (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Dom przy kościele Świętej Trójcy na Solcu". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: everything a photo would show: the windows' rhythm, the door, the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | cream plaster, grey roof |
