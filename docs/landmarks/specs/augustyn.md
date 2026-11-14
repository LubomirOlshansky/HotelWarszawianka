# Kościół św. Augustyna (St Augustine's church), ul. Nowolipki 18: spec

Site key `church_augustyn` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_augustyn`): the whole church is one model that replaces the
kit church. Written 2026-11-14 from the church's published description (Wikipedia, "St.
Augustine's Church, Warsaw": the three-nave basilica, the front, the clerestory roses, the
aisle windows, the tower's height and its cross and ball), the OSM outline and GUGiK's LoD2. No
open street photo faces the church from the cloud, and image sites are blocked here, so the
details follow the description, not a picture.

The kit church it replaces (2026-11-01) was a brick box with a pyramid tower, its front at the
north-west end. The real front is the south-east end, with the 70 m tower on its corner.

## 1. Identity
1. The **70 m tower** on the front's corner: a tall red-brick shaft, an arcaded belfry, a
   steep dark spire, a gilded ball and a 5.1 m cross. It was the tallest in Warsaw when built.
2. A **red clinker-brick neo-Romanesque basilica**: a tall nave over lean-to aisles, beige stone
   bands.
3. The **front**: three arcades below, six niches, a great rose, and the gable with a cross.

## 2. Massing
Frame: origin (-2399.2, -1142.5), the front's middle; u along the church to the north-west
apse (axis (-0.4297, -0.9030)), v across; the front faces -u. Ground g is the lowest terrain
under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave and choir | u 0 to 61, v -7 to 7 | eaves 22.5; ridge 26.7 |
| aisles | u 11.2 (and 1) to 59, out to v 15 either side | 9.5; lean-to roofs up to 14 |
| apse | a half ring r 6.8 round (61, 0) | 19; roof to 24 |
| tower | 8 m square round (7, -11) | shaft to 34; stage to 47.6; spire to 63.4; ball and cross to 69.7 |
| chapel annex | u 1 to 11, v 7 to 15 | to 12.3 |
| stair turret | octagon r 1.3 round (50, 6) | 14 to 34; spire to 40 |

LoD2: the tower 68.5 (its shaft 34, the upper stage to 48); the nave 22.5 and 26.5; the aisles
9.5 to 14; the stair turret 40.

## 3. Facade: the front
A portico block with three round arches (2.7 m wide, to 5.2) and a stone cornice at 7.5; six
stone niches over it; the great rose (r 3.2) at 16; the gable with a stone band at 22 and a
cross.

## 4. Facade: the sides and the apse
Eight bays a side: a pair of roses in the clerestory, three round-headed windows in the aisle
and a brick pier between bays. The apse plain under its roof (default).

## 5. Roof and tower
Grey (#5e6266) roofs. The tower: stone bands at 13 and 24, a round window and a tall arched
opening a face, a stone cornice at 34, a narrower stage with three arched openings a face to 47,
four stone pinnacles, the dark spire (#4d5a58), a gilded ball and the cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #9b4632 | M_STONE |
| Stone details | #d7c3a0 | M_STONE |
| Plinth | #8a4a38 | M_STONE |
| Roofs | #5e6266 | M_STONE |
| Spire | #4d5a58 | M_STONE |
| Ball | #c9a64a | M_STONE |
| Windows, roses | PAL_GLASS_DARK, CHURCH_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text names the 70 m tower. No floodlights.

## 8. Detail level and budget
L2 (a 70 m tower seen from across the north-west), triangle budget 1750 (measured 1603, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_augustyn`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism + gable | 61 x 14 m | u 0..61, y to 26.7 | #9b4632, #5e6266 | 1 nave |
| aisles | 2 prisms + lean-tos | 48 to 58 x 8 m | v 7..15 either side, y to 14 | #9b4632, #5e6266 | 2 aisles |
| apse | half ring + frustum | r 6.8 m | u 61, y to 24 | #9b4632, #5e6266 | 1 apse |
| clerestory roses | disc pairs | r 0.85 m | 8 bays a side, y 18 | #d7c3a0, PAL_GLASS_DARK | 32 roses |
| aisle windows | arched panels | 0.7 x 3.8 m | 3 a bay | PAL_GLASS_DARK | 48 windows |
| front | portico, 3 arches, 6 niches, rose, band, cross | 14.6 m wide | u 0 | #9b4632, #d7c3a0 | 1 rose |
| tower | 2 boxes, ledges, arches, 4 pinnacles, spire, ball, cross | 8 m | u 7, v -11, y to 69.7 | #9b4632, #4d5a58 | 1 tower |
| stair turret | octagonal frustums | r 1.3 m | u 50, v 6, y to 40 | #9b4632 | 1 turret |
