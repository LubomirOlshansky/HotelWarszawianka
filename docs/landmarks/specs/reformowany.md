# Kościół Ewangelicko-Reformowany (the Evangelical Reformed church), al. Solidarności 74: spec

Site key `church_reformowany` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_reformowany`): the whole church is one model that replaces
the kit church. Written 2026-11-14 from Mapillary photos of 2017 to 2025 taken along al.
Solidarności, 55 to 85 m east of the church (refs/reformowany, never shipped), the OSM outline
and GUGiK's LoD2. Every photo is far and at an angle; none is straight onto the front.

The kit church it replaces (2026-11-01) was a brick box with a pyramid roof, its front at the
north-north-west end. The real church faces south-south-east to the avenue with its one tall
tower and openwork spire over the front.

## 1. Identity
1. The **tall octagonal grey spire** over the front, openwork, with a cross: the church's mark
   on the al. Solidarności skyline (52 m).
2. A **cream neo-Gothic hall**: buttresses and tall lancets along both sides, one grey roof.
3. The **front**: a pointed portal, a rose window, the gable with a pinnacle and two slim corner
   turrets.

## 2. Massing
Frame: origin (-1749.5, -1082.9), axis (-0.448, -0.894) from the front (u 1.5) to the chancel,
+v across; the church's axis at v 9.9. Ground g is the lowest terrain under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave | u 1.5 to 41.5, v 0.3 to 19.5 | eaves 13; gable along u, ridge 20.3 |
| chancel | three sides of a ring r 6 round (41.5, 9.9) | walls 12; roof to 16 |
| vestry | u 44 to 48.5, v 1.5 to 18 | 4.5, flat |
| tower | 4.8 x 4.8 m round u 6.75 | shaft from the roof 13 to 30 |
| spire | octagon r 2.2 to 1.5 to a point | 30 to 38 to 51; cross to 52.8 |
| corner turrets | 1.8 m square at v 0.3 and 19.5 | 15.5, pinnacles to 19.5 |

LoD2: the nave's eaves 13 and ridge 20.3; the tower's top 31 and the spire's tip 52; the
chancel 16; the vestry 4.5.

## 3. Facade: the front (the avenue)
A pointed portal 2.5 m wide to 3.6 with a trim frame; a rose window (r 2) at 9; a lancet either
side; a pinnacle on the gable's apex; the two corner turrets with pinnacles.

## 4. Facade: the sides and the chancel
Nine buttresses a side, stepped with a trim cap; seven lancets (1.6 m wide, 3.5 to 9.5) between
them; a plinth and a band under the eaves. Three lancets in the chancel. The north end and the
vestry are default (unphotographed).

## 5. Roof and spire
Grey (#686d72) gable roof over the nave, a low three-sided roof over the chancel. The tower:
belfry lancets on all four faces, a trim ledge at 29.4, four corner pinnacles. The spire is a
two-stage octagonal frustum in grey metal (#8d969c) with four dark slits for the openwork.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls, buttresses, tower | #ddcb98 | M_STONE |
| Frames, pinnacles, rose ring | #ece2c4 | M_STONE |
| Roof | #686d72 | M_STONE |
| Spire | #8d969c | M_STONE |
| Plinth | #9b958a | M_STONE |
| Lancets, rose | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text names the openwork spire. No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1150 (measured 1020, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_reformowany`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism + gable | 40 x 19.2 m | u 1.5..41.5, y to 20.3 | #ddcb98, #686d72 | 1 nave |
| buttresses | boxes, trim caps | 0.8 x 0.9 m | 9 a side | #ddcb98, #ece2c4 | 18 buttresses |
| side lancets | lancet panels | 1.6 x 6 m | 7 a side | PAL_GLASS_DARK, #ece2c4 | 14 lancets |
| chancel | half-hexagon prism + frustum | r 6 m | u 41.5, y to 16 | #ddcb98, #686d72 | 3 lancets |
| vestry | prism | 4.5 x 16.5 m | u 44..48.5, y to 4.5 | #ddcb98 | 1 vestry |
| front | portal, rose, 2 lancets, pinnacle | 2.5 to 4 m | u 1.5 | #ece2c4, PAL_DARK_DOOR | 1 portal, 1 rose |
| turrets | boxes + pinnacles | 1.8 m | v 0.3 and 19.5, y to 19.5 | #ddcb98, #ece2c4 | 2 turrets |
| tower | box, ledge, 8 lancets, 4 pinnacles | 4.8 m | u 6.75, y 13..34 | #ddcb98, #ece2c4 | 1 tower |
| spire | 2 octagonal frustums, 4 slits, cross | r 2.2 m | y 30..52.8 | #8d969c, CHURCH_DARK | 1 spire |
