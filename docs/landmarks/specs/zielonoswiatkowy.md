# Kościół Zielonoświątkowy (the Pentecostal church), Sienna: spec

Site key `church_zielonoswiatkowy` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_zielonoswiatkowy`): the whole building is one model that
replaces the kit church. Written 2026-11-14 from Mapillary photos of 2021 along Sienna and the side
street (2021-04-18 towards the entrance end with the brick stair block and the oversailing cream
volume; 2021-03-26 towards the far end with the fin groups, the curved corner and the brick ground
floor; refs/zielonoswiatkowy, never shipped), the OSM outline and GUGiK's LoD2.

The kit church it replaces (2026-11-01) was a gabled "modern" church box. The real building is a
**flat-roofed modernist hall** of the 1950s: no tower, no gable.

## 1. Identity
1. A **dark red brick ground floor** under a **cream plastered upper volume** that oversails it.
2. **Groups of three tall cream fins** on the long walls.
3. **Flat roofs** at two heights (the hall 12 m, the lower wing 9.4 m) and a **tall brick stair
   block** by the entrance, with a slit window up it.
4. Rows of square windows in the cream storeys.

## 2. Massing
Frame: origin at the outline's centre (-1890.1, 331.7), u along the building (axis (-0.3881,
0.9216)), +v to the hall's side. Ground g is the lowest terrain under the outline (12.9).

| Block | Plan | Height over g |
| --- | --- | --- |
| hall | the outline where v is over 6 | brick to 4, cream to 12, flat |
| lower wing | the outline where v is under 6 | brick to 3.6, cream to 9.4, flat |
| stair block | u -21.2 to -16.8, v 6 to 10.2 | 14, flat |

LoD2 (ground 13.0): the hall 12 (25 abs) all over its half, the wing 9.2 to 9.5, a 10 m bay and
the 14 m block at the west end.

## 3. Facade: the entrance end
The stair block in brick with a slit window (4.5 to 12.5), the cream volume oversailing the
entrance on a pale pier, dark glazed doors under it.

## 4. Facade: the sides and the back
Every edge longer than 4 m: square windows every 2.6 m on the cream storeys (two rows on the hall,
two on the wing) and one row in the brick ground floor; a fin group at a quarter and three
quarters of every hall edge longer than 9 m. A pale band over the ground floor and a coping at the
top. The curved corner is a chamfer (the outline's).

## 5. Roof
Flat, grey (#8e8f8c), both halves.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #8f4a36 | M_STONE |
| Cream plaster | #e2d6bf | M_STONE |
| Fins, copings, pier | #ece3d0 | M_STONE |
| Roofs | #8e8f8c | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |
| Doors | PAL_DARK_DOOR | M_STONE |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text unchanged. No floodlights.

## 8. Detail level and budget
L1, triangle budget 1000 (measured 919, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_zielonoswiatkowy`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | 2 prisms + 2 ring bands | its half of the outline | y -1..12 | #8f4a36, #e2d6bf | 1 two materials |
| wing | 2 prisms + band | its half of the outline | y -1..9.4 | #8f4a36, #e2d6bf | 1 two materials |
| fins | 4-sided prisms, 3 a group | r 0.24 | hall edges over 9 m, y 4.4..11.5 | #ece3d0 | 2 fins |
| windows | flat panes | 1.2 x 1.5 m | every 2.6 m on long edges | PAL_GLASS_DARK | 4 windows |
| stair block | box + coping + slit | 4.4 x 4.2 m | u -21.2..-16.8, y to 14 | #8f4a36 | 3 stair block |
| entrance | pier + door wall | 0.7 m pier | u -24..-19, y to 4 | #ece3d0, PAL_DARK_DOOR | 3 stair block |
