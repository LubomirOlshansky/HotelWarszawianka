# Kościół Narodzenia NMP na Lesznie (the church of the Nativity of the Virgin Mary), al. Solidarności 80: spec

Site key `church_narodzenia` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_narodzenia`): the whole church is one model that replaces the
kit church. Written 2026-11-14 from Mapillary photos of 2020 and 2022 taken along al.
Solidarności (one straight onto the front from 64 m, one of the east side and the front at an
angle; refs/narodzenia, never shipped), the OSM outline and GUGiK's LoD2.

The kit church it replaces (2026-11-01) was a beige box with a helm tower, its front on the
north end. The real church faces south-south-east to the avenue, and has no tower: a small
copper clock turret stands over its pediment.

## 1. Identity
1. The **salmon-pink Baroque front** in three storeys with **white pilasters**: wide at the
   ground, nave-wide in the middle with a tall round-headed window, an attic with scrolls and a
   pediment.
2. The small **green copper clock turret** over the pediment: a balustrade with urns, a clock a
   side, a little dome, a spire and the cross.
3. **Red tile roofs** over the nave, the lean-to aisles and the lower chancel.

## 2. Massing
Frame: origin (-1971.4, -955.6), the front's south-west corner; u from the front back to the
chancel (axis (-0.4656, -0.8850)), +v across; the church's axis at v 12. Ground g is the lowest
terrain under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave | u 0 to 23, v 4 to 20 | eaves 16.5; gable along u, ridge 22 |
| aisles | u 1.4 to 23, v 0 to 4 and 20 to 24 | 8.3, flat red tops |
| front ground storey | u 0 to 1.4 over the aisles | 10.5 |
| attic and pediment | u 0 to 1, v 6.5 to 17.5 | 16 to 20; pediment to 23 |
| chancel | u 23 to 32.9, v 6.5 to 17.5 | 15; gable ridge 19 |
| back wings | u 23 to 32.9, v 0 to 6.5 and 17.5 to 25.6 | 8 |
| turret | octagon r 1.45 round (2.6, 12) on a 3.8 m base | base 19 to 23; clock stage to 26.5; dome to 28.3; spire 30.3 |

LoD2: the nave's eaves 16.5 and ridge 22; the front's top 23; the turret's top 30 (a 3 m spike
over the front); the aisles 7.5 to 8.5; the chancel 15 to 19; the back wings 7 to 9.

## 3. Facade: the front (the avenue)
Ground storey across the whole front: eight pilasters (paired at the aisle lines), the door with a
triangular pediment, round-headed windows either side, a cornice at 10.5. Middle storey over the
nave: four pilasters, the tall round-headed window (2.6 m wide), a cornice at 16.5. Attic: two
pilasters, a round-headed window between two small ones, a scroll either side, then the
pediment.

## 4. Facade: the sides and the back
Aisles: four pilasters and four round-headed windows a side. Nave over them: five pilasters and
four tall windows a side. Chancel: two windows a side. Back (default, unphotographed): a tall
window and an oculus in the chancel's gable, small windows on the wings.

## 5. Roof and turret
Red tiles (#a3553f) on the nave and chancel gables, a lighter red on the flat aisle and wing tops.
The turret: a pink base, a white balustrade with four urns, a dark green clock stage with an
opening and a white clock on each face, a white cornice, a green copper dome and spire, the cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #d49885 | M_STONE |
| Pilasters, cornices, frames, clocks | #efe7da | M_STONE |
| Roofs | #a3553f | M_STONE |
| Turret copper | #5f8a78 | M_STONE |
| Plinth | #a39a8e | M_STONE |
| Door | #4a3a30 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text names the clock turret. No
floodlights.

## 8. Detail level and budget
L1, triangle budget 1450 (measured 1305, `check_mesh_quality.gd`). Pilasters are single boxes to
keep the count down. Shots: `tools/turntable.sh church_narodzenia`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism + gable | 23 x 16 m | u 0..23, y to 22 | #d49885, #a3553f | 1 nave |
| aisles | 2 prisms + front blocks | 21.6 x 4 m | v 0..4 and 20..24, y to 10.5 | #d49885, #a3553f | 2 aisles |
| front | cornices, 14 pilasters, door, 5 windows | 24 m wide | u 0 | #efe7da, PAL_GLASS_DARK | 1 door |
| attic | box, 3 windows, 2 scrolls, pediment | 11 x 4 m | u 0..1, y 16..23 | #d49885, #efe7da | 1 pediment |
| side windows | arched panels | 1.5 to 1.9 m | aisles, nave, chancel | PAL_GLASS_DARK, #efe7da | 20 windows |
| chancel | prism + gable | 9.9 x 11 m | u 23..32.9, y to 19 | #d49885, #a3553f | 1 chancel |
| back wings | 2 prisms | 9.9 x 6.5 to 8 m | either side of the chancel, y to 8 | #d49885 | 2 wings |
| turret | box, balustrade, 4 urns, octagon, 4 clocks, dome, spire, cross | 3.8 m | u 2.6, y 19..31.4 | #d49885, #5f8a78, #efe7da | 1 turret |
