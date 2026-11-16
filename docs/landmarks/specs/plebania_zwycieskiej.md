# Plebania parafii Matki Boskiej Zwycięskiej (the presbytery by Our Lady of Victory, Praga; site `plebania_zwycieskiej`)

Site key `plebania_zwycieskiej` in `game/scripts/landmarks.gd` (found by the OSM outline under
`PZW_AT` in `game/scripts/landmarks/churches.gd`: building 394, tagged `presbytery`, "Plebania";
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from two Mapillary photos
down the street (2015, refs/churches/plebania_394, reference only, never shipped). They show the
house's end wall over iron railings on a low stone wall, behind old trees: cream plaster, a dark
band under the eaves.

## 1. Identity
1. The parish's **presbytery**, a **cream plastered** two-storey house behind iron railings, 43 m
   from the church of Our Lady of Victory.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (10 corners, about 21 by 37 m) at 7.6 m. The photos
show only one end, so the mass is not reshaped.

## 3. Facade
The block's walls in cream plaster; the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
A grey sheet (a default: no photo shows the roof).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6d9b5 | skin (M_MONUMENT) |
| Roof | #6c6a66 (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Plebania parafii Matki Boskiej Zwycięskiej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: the railings (the map's fence layer), the door, the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | cream plaster, grey roof |
