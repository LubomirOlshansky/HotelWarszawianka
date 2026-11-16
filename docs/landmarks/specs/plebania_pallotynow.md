# Plebania przy Skaryszewskiej (the Pallottines' presbytery of Christ the King, Praga) (site `plebania_pallotynow`)

Site key `plebania_pallotynow` in `game/scripts/landmarks.gd` (found by the OSM outline under
`PPL_AT` in `game/scripts/landmarks/churches.gd`: building 6054, tagged `presbytery`, "Plebania";
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from eight Mapillary photos along Skaryszewska (2026,
refs/churches/plebania_6054, reference only, never shipped). They show the cream chapel's front with
the iron fence and gate beside it; the house stands behind the fence at the west corner of the
church's block (`church_chrystusa_krola`).

## 1. Identity
1. The parish's **presbytery**, a low house in the **parish wings' plaster** beside the Our Lady of
   Częstochowa chapel on Skaryszewska, part of the Pallottines' church block.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (9 corners, about 14 by 15 m) at 7.6 m.

## 3. Facade
The block's walls in the parish wings' plaster (`CK_WING`, the church model's); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
The church block's grey roofs (`CK_TILE`; no photo shows this roof).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e6dcc4 | skin (M_MONUMENT) |
| Roof | #8a8a84 (the church's) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Plebania przy Skaryszewskiej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: the door, the fence (the map's fence layer), the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | parish wings' plaster, grey roof |
