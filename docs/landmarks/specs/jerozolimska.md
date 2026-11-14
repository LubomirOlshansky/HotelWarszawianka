# Kościół Matki Bożej Jerozolimskiej (Our Lady of Jerusalem), Łazienkowska: spec

Site key `church_jerozolimska` in `game/scripts/landmarks.gd` (`_find_churches` finds it and
cuts the bell tower's LoD2 with `_jz_tops`, `_build_church` hands it to `_build_jerozolimska`):
the whole church is one model that replaces the kit church. Written 2026-11-14 from Mapillary
photos along Łazienkowska (2018 to 2024, from both directions and the pavement; refs/jerozolimska,
never shipped), the OSM outline and GUGiK's LoD2. Nothing faces the back yard or the north side.

The kit church it replaces (2026-11-01) was a box with a spire whose front faced north, away
from the street. The real church is a **banded red-and-yellow brick** church in a former
barracks complex, its long street block fronted by a **stone portico**.

## 1. Identity
1. **Red brick with yellow bands**, grey sheet roofs.
2. The long **street block** with a **portico of seven stone columns** on two steps.
3. The **nave's steep gable** rising behind it, the lower chancel and the north apse.
4. The **square brick bell tower** with a cross, 40 m west on the next block.

## 2. Massing
Frame: origin (969.9, 1346.0), the street front's west corner; u along the street to the east
(axis (0.9962, 0.0870)), +v to the street (south). Ground g is the lowest terrain under the
outline (-14.1); the tower stands on its own ground.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| street block | u 0 to 25.3, v -7.5 to 0 | eaves 15; gable along u, ridge 19 |
| nave | u 6.1 to 18.5, v -22.5 to -7.5 | eaves 13.6; gable along v, ridge 19.6 |
| chancel | u 6.3 to 18.3, v -34.6 to -22.5 | eaves 10.3; ridge 17 |
| apse | half octagon r 4.1 round (11.4, -34.6) | 9.5; roof to 13.2 |
| aisles | u 0 to 6.1 and 18.5 to 25.2, v -30 to -7.5 | 6.5, flat |
| west block, north-east block | u -0.5 to 6.3, v -38.2 to -30; u 17.1 to 25.3, v -46.4 to -30 | 7.5; 10 |
| portico | u 3 to 21.6, v 0 to 2.5 | columns to 5.3, entablature to 6.5 |
| bell tower | 8 m square at u -32.5, v -3; base 10 m square | base 16.5; shaft 22.3; roof 23.4; cross 25.5 |

LoD2 (ground -14.1): the street block 0.8 to 4.9 abs (15 to 19), the nave -0.8 to 5.5 (13.3 to
19.6), the chancel to 3.0 (17.1), the aisles -8.8 to -7.4, the tower 2.2 to 2.5 at its base and
8.2 to 9.3 at its top.

## 3. Facade: the street front
Two yellow bands (6.6 and 11.8), five round-headed windows (1.4 m, 8 to 11.1) in yellow brick
surrounds over the portico, a round-headed portal (2.2 m, to 4.4) on the axis and two side doors.
The portico: two stone steps, seven columns (r 0.3), a stone entablature and a brick top.

## 4. Facade: the sides and the back
Clerestory: four round-headed windows a side. Aisles: four small round-headed windows a side.
The chancel's north gable: one round-headed window over the apse. The back blocks plain
(unphotographed, default). The tower: two round-headed openings a side (18.2 to 20.95), a yellow
band at the base's top and a corbelled yellow top.

## 5. Roof
Grey sheet (#767a7e) on all the gables, the apse and the tower's low pyramid; a paler grey on the
flat tops; an iron cross on the tower.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #a9553a | M_STONE |
| Bands, surrounds, corbels | #c99a5e | M_STONE |
| Portico stone | #d8d2c4 | M_STONE |
| Roofs | #767a7e | M_STONE |
| Doors | #3e302a | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`); the tower stands inside the next block, which
keeps its own collider. Card text says the portico and the stadium. No floodlights.

## 8. Detail level and budget
L1, triangle budget 1050 (measured 921, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_jerozolimska` (the tower stands apart, its base from the ground).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| street block | prism + gable | 25.3 x 7.5 m | u 0..25.3, y to 19 | M_STONE #a9553a, #767a7e | 2 street block |
| portico | 2 steps, 7 columns, 2 slabs | 18.6 x 2.5 m | before the front, y to 6.5 | #d8d2c4, #a9553a | 2 street block |
| nave | prism + gable | 12.4 x 15 m | u 6.1..18.5, y to 19.6 | M_STONE, #767a7e | 3 nave |
| chancel, apse | prism + gable, half octagon + roof | 12 x 12.1 m, r 4.1 | north, y to 17 | M_STONE, #767a7e | 3 nave |
| low blocks | 4 prisms | 6.5 to 10 m | round the back yard | M_STONE | 3 nave |
| windows, doors | arched panels | 1.1 to 2.2 m | front, clerestory, aisles | PAL_GLASS_DARK, #3e302a | 2 street block |
| bell tower | base, band, shaft, top, 8 openings, pyramid, cross | 10 / 8 m | u -32.5, v -3, y to 25.5 | M_STONE, #767a7e | 4 tower |
