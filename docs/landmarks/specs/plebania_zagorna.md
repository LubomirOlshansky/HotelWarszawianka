# Plebania przy Zagórnej (Our Lady of Częstochowa's parish house, Powiśle) (site `plebania_zagorna`)

Site key `plebania_zagorna` in `game/scripts/landmarks.gd` (found by the OSM outline under
`PZG_AT` in `game/scripts/landmarks/churches.gd`: building 2197, tagged `presbytery`, unnamed;
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from two Mapillary photos at its south-west corner (2026,
refs/churches/plebania_2197, reference only, never shipped). They show a grey rendered wall with
gold-framed windows, the gilt cross with the Mass times, a stair with red railings down to the lower
floor and the church's green copper edge beside it.

## 1. Identity
1. The parish's **house**, joined to the back of the 1960s church of Our Lady of Częstochowa
   on Zagórna, in the church's **grey render**.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (14 corners, about 35 by 30 m) at 7.6 m.

## 3. Facade
The block's walls in the church's grey render (`MC_WALL`); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
A grey sheet (a default: no photo shows the roof).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #c8c5be | skin (M_MONUMENT) |
| Roof | #6c6a66 (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Plebania przy Zagórnej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: the gold window frames, the Mass-times cross, the stair and its railings.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | grey render, grey roof |
