# Kościół Matki Bożej Częstochowskiej (Our Lady of Częstochowa), ul. Zagórna 5: spec

Site key `church_czestochowska` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_czestochowska`): the whole church is one model that replaces
the kit church. Written 2026-11-14 from Mapillary photos of 2026 on Zagórna (the front from 68 m,
straight on; the side wall and the roof's edge close up; refs/czestochowska, never shipped), the
OSM outline and GUGiK's LoD2.

The kit church it replaces (2026-11-01) was a beige box with a pyramid tower. The real church is
a 1960s modernist church: a green copper A-frame with twin concrete pylons before it.

## 1. Identity
1. The **steep green copper A-frame roof** that comes down almost to the ground at the front.
2. The **twin dark concrete pylons** before the front with the bells between them, an emblem and
   the **tall light cross** above them.
3. The **glazed triangular front** with a concrete edge and the doors under a flat canopy.

## 2. Massing
Frame: origin (1142.0, 880.0), the front's middle by the pylons; u back from the front
(south-east, to Zagórna; axis (-0.6402, -0.7682)), v across. Ground g is the lowest terrain under
the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| front A-frame | u -2 to 6.2, v -8.2 to 8.2 | from 0.3 to the ridge at 15 |
| nave | u 6 to 30, v -11 to 11 | walls 6; gable ridge 15.5 |
| back block | u 30 to 41.4, v -9 to 9 | 8, flat |
| entrance | u -3.4 to -2, v -5 to 5 | 3.1, canopy to 3.45 |
| pylons | u -3 to -2, v 0.6 to 1.9 either side | from the canopy to 22.5; cross to 27 |

LoD2: the A-frame's ridge 15 and its slopes falling about 1.8 m a metre to the ground at v 8; the
pylons 22.5; the nave's sides at 5 to 10 out to v 11; the back block 8.

## 3. Facade: the front (Zagórna)
The A-frame's concrete triangle with the dark glass triangle inside; the glazed doors under the
white canopy on a low step; the two pylons rising from the canopy with three bells between them,
the emblem at 11 and the cross.

## 4. Facade: the sides and the back
The nave's grey side walls with two rows of four gold-framed windows; the back block plain with
three tall windows a side (default: no photo of the back).

## 5. Roof
Pale green copper (#7fa290) on the A-frame and the nave; a grey flat top on the back block.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Side walls | #c8c5be | M_STONE |
| Roofs | #7fa290 | M_STONE |
| Pylons, the A-frame's edge | #6f7172 | M_STONE |
| Window frames | #b39a5c | M_STONE |
| Cross, canopy, emblem | #e9e6df | M_STONE |
| Glass | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text names the roof down to the ground. No
floodlights.

## 8. Detail level and budget
L1, triangle budget 620 (measured 551, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_czestochowska`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front A-frame | gable from the ground | 8.2 x 16.4 m | u -2..6.2, y to 15 | #7fa290, #6f7172 | 1 A-frame |
| glass front | gable triangle | 14.6 m wide | u -2.06 | PAL_GLASS_DARK | 1 glass front |
| entrance | box, glass, canopy, step | 10 m wide | u -3.4..-2 | #c8c5be, #e9e6df | 1 entrance |
| nave | prism + gable | 24 x 22 m | u 6..30, y to 15.5 | #c8c5be, #7fa290 | 1 nave |
| side windows | framed boxes | 4 x 1.5 m | 2 rows of 4 a side | #b39a5c, PAL_GLASS_DARK | 16 windows |
| back block | prism | 11.4 x 18 m | u 30..41.4, y to 8 | #c8c5be | 1 back block |
| pylons | 2 boxes, 3 bells, emblem, cross | 1 x 1.3 m each | u -3..-2, y to 27 | #6f7172, #e9e6df | 2 pylons |
