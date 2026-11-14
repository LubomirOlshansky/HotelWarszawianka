# Kościół św. Antoniego Padewskiego (St Anthony of Padua), Senatorska 31: spec

Site key `church_antoniego` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_antoniego`): the Franciscans' church as
one model that replaces the kit church. Written 2026-11-14 from 15 Commons photos
(refs/churches/st_anthony_senatorska, reference only, never shipped), the OSM outline (building
12815) and GUGiK's LoD2.

## 1. Identity
1. A **white plastered Baroque church** under **steep orange-red tile roofs**, hipped at the
   chancel and the transept ends.
2. A **slim slate-grey octagonal turret** on the ridge past the crossing, with a **green copper
   double onion** and an open lantern.
3. The **two-storey classicist front** with a porch, a tall arched window and a **pediment with
   an oculus** and a cross, facing the cross square on Senatorska.
4. The **octagonal chapel** north of the front under a red tile roof and a small lantern.
5. Low **cloister wings** with arches and end pavilions closing the square.

## 2. Massing
Frame: origin (-1211.2, -978.4), u along the church from the front (u = -2) to the chancel
(u = 40.5) on axis (0.7251, 0.6886), v to the north. Heights over g, the lowest ground under the
outline (LoD2 relative to it).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave and chancel | u -2..40.5, v -10.5..3.5 | eaves 16, ridge 22.5; hipped east end |
| transept | u 19.5..26.5, v -17.7..7.3 | eaves 16, hipped ridge 20 |
| aisles | v -12.9..-10.5 and 3.5..5.5 | lean-tos 7.6 to 9.6 |
| sacristies | u 26.5..41.7, both sides | lean-tos 6 to 8.2 |
| turret | at u 28.5, v -3.5, octagon r 1.55 | slate to 26.2, onion to 28.9, lantern to 30.5, onion to 32.4, cross to 34.2 |
| link wing | u 0.5..9, v 5.5..19 | 7, hip to 8.8 |
| chapel | octagon r 5.8 at (4.3, 24.3) | 9, roof to 12.8, lantern to 15 |
| cloister wings | v 14.7..18.8 and -25.5..-22, u -24..-0.5 | 5, hip to 6.3 |
| pavilions | u -30.3..-24 at both wings' ends | 6, hip to 8.2 |

## 3. Facade: the front on the cross square
Pilasters on two storeys, a ledge at 9.6, the porch (7 m wide, 3.4 deep, 6.6 tall) with two
Tuscan columns, an arched door and a balustrade, the tall arched window, the pediment (apex
22.1) with an oculus and an iron cross.

## 4. The other sides
Tall round-headed windows over the aisles and on the chancel, big ones in the transept ends,
small square ones at the chancel end, ground-floor windows on the sacristies, aisles, link wing
and chapel; dark arches along the cloister wings on the square side.

## 5. Roof
Orange-red tiles (#c4603d); green copper (#5f8f7e) lean-tos and onions; slate (#4c5156) turret.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #f0ece2 | M_STONE |
| Trim, pilasters, ledges | #e0d9ca | M_STONE |
| Roofs | #c4603d | M_STONE |
| Copper | #5f8f7e | M_STONE |
| Turret | #4c5156 | M_STONE |
| Doors, arches | #3a2f28 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Kościół św. Antoniego Padewskiego". No
floodlights.

## 8. Detail level and budget
L2, triangle budget 1250 (measured 1157, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_antoniego`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism, gable, hip | 42.5 x 14 m | u -2..40.5, y to 16, ridge 22.5 | #f0ece2, #c4603d | 1 nave and chancel |
| transept | prisms, hip | 7 x 25 m | u 19.5..26.5, ridge 20 | #f0ece2, #c4603d | 2 arms |
| aisles, sacristies | boxes, lean-tos | 2 to 8 m deep | both sides | #f0ece2, #5f8f7e | 4 lean-tos |
| turret | octagon, frustums | r 1.55 to 2 m | u 28.5 on the ridge | #4c5156, #5f8f7e | 1 turret, 2 onions, 4 quatrefoils |
| front | ledge, pilasters, pediment, porch | 19 m wide | u -2 | #e0d9ca | 6 pilasters, porch, 2 columns, oculus, cross |
| chapel | octagonal prism, pyramid | r 5.8 m | (4.3, 24.3) | #f0ece2, #c4603d | 1 chapel, lantern |
| cloister | boxes, hips | 4 m deep | both sides of the square | #f0ece2, #c4603d | 2 wings, 2 pavilions, gate wall, dark arches |
