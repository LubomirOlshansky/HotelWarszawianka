# Plebania parafii Narodzenia NMP (the presbytery of the Nativity church on Leszno, Wola) (site `plebania_leszno`)

Site key `plebania_leszno` in `game/scripts/landmarks.gd` (found by the OSM outline under
`PLS_AT` in `game/scripts/landmarks/churches.gd`: building 10100, tagged `presbytery`, "Plebania";
its area is in `tools/bake_sectors.py` SITE_AREAS). Written 2026-11-15 from the OSM outline and the neighbouring model,
the Nativity of the Virgin Mary church on Leszno (`church_narodzenia`, NR_*): one Mapillary photo within 45 m faces it at a steep slant from 42 m (2022), too far and too slanted to read.
**Provisional.**

## 1. Identity
1. The presbytery of the Nativity church on Leszno, behind the Nativity church on Leszno, Wola, in the colours of the neighbouring model until a photo arrives.
2. Before this site it was a plain block in the district's default colours.

## 2. Massing
The map's mass kept as it is: the OSM outline (7 corners, about 20 by 17 m) at 7.6 m.

## 3. Facade
The block's walls in the church's salmon-pink plaster (`NR_WALL`; a default); the windows are the skin's.

## 4. The other sides
As section 3.

## 5. Roof
The church's red tiles (`NR_ROOF`; a default).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #d49885 | skin (M_MONUMENT) |
| Roof | #a3553f (a default) | skin |

No new material, shader instruction or draw call.

## 7. Ground and night
The block's collision. Card: "Plebania parafii Narodzenia NMP". No floodlights.

## 8. Detail level and budget
L1, triangle budget 0 (a skin only: no triangles of its own, so no `check_mesh_quality.gd` row)
and no turntable (`tools/turntable.sh` frames sites that build triangles). Checked with a city
before/after shot. Not included: everything a photo would show: the windows' rhythm, the door, the roof shape.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | the map's block | the outline | — | skin | salmon plaster, red tile roof |
