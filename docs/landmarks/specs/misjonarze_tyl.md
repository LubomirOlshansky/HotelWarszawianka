# Dom zakonny Księży Misjonarzy (the back wing of the Missionaries' house, Krakowskie Przedmieście) (site `misjonarze_tyl`)

Site key `misjonarze_tyl` in `game/scripts/landmarks.gd` (found by the OSM outline under
`MST_AT` in `game/scripts/landmarks/churches.gd`: building 5803, tagged `monastery`, "Dom zakonny Księży Misjonarzy";
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from the OSM outline and the neighbouring model,
the Missionaries' house on Krakowskie Przedmieście (`church_misjonarze`, MS_*): no open photo reaches the yard behind the street wing.
**Provisional.**

## 1. Identity
1. The back wing of the Missionaries' house by Holy Cross, behind the Missionaries' house by Holy Cross, Krakowskie Przedmieście, in the colours of the neighbouring model until a photo arrives.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (28 corners, about 21 by 33 m) at 14.2 m.

## 3. Facade
The block's walls in the house's ochre plaster (`MS_WALL`; a default); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
The house's grey roof (`MS_ROOF`; a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #d7c08a | skin (M_MONUMENT) |
| Roof | #5b5d60 (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Dom zakonny Księży Misjonarzy". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: everything a photo would show: the windows' rhythm, the door, the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | ochre plaster, grey roof |
