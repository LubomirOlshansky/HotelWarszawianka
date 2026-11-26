# Kościół Świętych Apostołów Piotra i Pawła (Sts Peter and Paul), Nowogrodzka 51: spec

Site key `church_piotr_pawel` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the
OSM outline under `at`, `_build_church` hands it to `_build_piotr_pawel`): the basilica as one
model that replaces the kit church (whose front was on the wrong end and whose style was
neo-Gothic brick). Written 2026-11-14 from 14 Commons photos
(refs/churches/sts_peter_paul_nowogrodzka, reference only, never shipped), the OSM outline
(building 79) and GUGiK's LoD2.

## Rework 2026-11-26 (3D Tiles)
The first spec guessed the roofs from street-level photos; Google 3D Tiles renders (reference only,
`refs/church_piotr_pawel/3dtiles/`) show otherwise. Changes: (1) every roof is patina green
#86a898, paler and greyer than the copper dome (#6f9e8c, kept for dome, lantern cap, tower domes);
(2) the transept arms are gabled along their own axis (eaves 18.5, ridge 22, pediments kept), the
wings (u -27..-18.8, eaves 11) get green hips rising to 13.5, the apse keeps its half-octagon roof;
(3) walls #e2d8c2, trim #ece5d4; (4) a balustrade ring (plinth, rail, 16 piers, 1.3 m) on the drum's
top and a near-vertical dome foot (r 7.1 to 7.0 over 28.5..31) so it reads as a broad cap, apex
unchanged. Budget 1300 -> 1650 (measured 1500).

## 1. Identity
1. A **sand stucco neo-Renaissance basilica**.
2. A **tall flat front** with **three deep arched porches**, a **rose window** under a gable and
   **two slim corner towers** with arched belfries and small copper domes.
3. A **tall drum with arched windows** and a **green copper dome** with a lantern over the crossing.
4. A low transept with pedimented ends, low wings either side of a **rounded apse**.

## 2. Massing
Frame: origin (-1128.8, 830.2), the outline's centre; u from the apse to the front on axis
(-0.9412, 0.3379), v to its left. Heights over g, the lowest ground under the outline.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave with aisles | u -4.5..24.5, v ±11.3 | eaves 17.5, ridge 23.5 |
| crossing, transept | u -19..-4, v ±11.3; arms u -15..-7 to v ±15.3 | 18.5 flat |
| drum | 16 sides, r 7 at u -11.5 | 28.5 |
| dome, lantern | r 7.1 to 1.0 | 42.4, lantern 45.4, cap 47.2, cross 49 |
| towers | 3.3 x 3.2 m at u 23, v ±9.9 | shaft 23.5, belfry 27.8, dome 29.8 |
| wings | u -27..-18.8, v ±(5.2..15) | 11 flat |
| apse | to u -33, half octagon r 5.5 | 18, roof 22.5 |

## 3. Facade: the front
Four pilasters to 17, a ledge at 9, the middle arched porch (4.2 wide, 8.2 tall) and two side
ones (2.8 wide, 6.6 tall), niches over the side porches, the rose window (r 1.7) at 13.6, the
pediment to 21.9 with an iron cross, steps.

## 4. The other sides
Tall round-headed windows and round ones high on the nave, a tall window in each transept end
with a pediment over it, windows in the wings and round the apse, arched windows in the drum.

## 5. Roof
Patina-green copper roofs (#86a898) on the nave and aisles, transept arms (gabled, ridge 22),
crossing, apse (half-octagon) and wings (hips to 13.5); darker green copper (#6f9e8c) dome,
lantern cap and tower domes. A balustrade ring crowns the drum.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #e2d8c2 | M_STONE |
| Trim | #ece5d4 | M_STONE |
| Roofs | #86a898 | M_STONE |
| Copper | #6f9e8c | M_STONE |
| Porches, belfry openings | #3b3732 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card unchanged. No floodlights.

## 8. Detail level and budget
L2, triangle budget 1650 (measured 1500, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_piotr_pawel`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism, gable | 29 x 22.6 m | u -4.5..24.5 | #e2d8c2, #86a898 | 1 nave |
| crossing | boxes, gable roof | 15 x 30.6 m | u -19..-4, ridge 22 | #e2d8c2, #86a898 | crossing, 2 gabled arms, 2 pediments |
| drum, dome | prism, balustrade ring, frustums | r 7 m | u -11.5 | #e2d8c2, #6f9e8c | 8 windows, lantern, cross |
| towers | boxes, octagons, cones | 3.3 m | front corners | #e2d8c2, #6f9e8c | 2 towers, 8 openings |
| front | pilasters, doors, disc, pediment | 22.6 m wide | u 24.5 | #ece5d4, #3b3732 | 3 porches, rose, 2 niches |
| apse, wings | prism, pyramid, hips | r 5.5 m | u -33..-18.8 | #e2d8c2, #86a898 | 1 apse, 2 wings |
