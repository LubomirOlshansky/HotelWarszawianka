# Konkatedra Matki Bożej Zwycięskiej (Our Lady of Victory), Grochowska 365: spec

Site key `church_zwycieska` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_zwycieska`): the co-cathedral as one
model that replaces the kit church (two brick spires it never had). Written 2026-11-14 from 16
Commons photos (refs/churches/our_lady_of_victory_grochowska, reference only, never shipped),
the OSM outline (building 82) and GUGiK's LoD2.

## 1. Identity
1. A **cream-white 1930s modernist church**, no spires.
2. A **tall flat front block** with **pale yellow strips**, a **big round window in a yellow
   frame** under the arms and **three wooden doors**; lower flat-topped wings with slit windows.
3. The nave under a **low red tile roof** between lower aisles.
4. A **tall round apse** with long slit windows; a small **brown-domed chapel** by the front;
   an annex with **yellow-framed arches**.

## 2. Massing
Frame: origin (1970.9, -1373.1), the outline's centre; u from the front (u = -15.2) to the apse
on axis (0.0905, -0.9959), v to its left. Heights over g, the lowest ground under the outline.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| front block | u -15.2..-3, v -10..2 | 26, flat |
| front wings | u -15.2..-3, v 1.8..12.7 and -18..-9.8 | 13, flat |
| nave | u -3.2..34, v -10..2 | eaves 22, ridge 25 |
| aisles | v -16..-9.8 (from u -3.2), 1.8..8 (from u 4) | 15, lean-tos to 17 |
| apse | 16 sides, r 5.5 at u 35.3 | 27, roof 28.2 |
| east blocks | u 33..40 either side of the apse | 20, flat |
| south annex | u 2..16, v -24.5..-17 | 8.4, flat |
| chapel | octagon r 3.6 at (0.5, 6.3) | 6.6, dome to 9.3 |

## 3. Facade: the front on Grochowska
Four yellow strips to 25.6, the round window (frame r 2.9, glass r 2.4) at 14, the arms at 19.6
to 22, a yellow band over three doors (the middle one wider), steps, an iron cross on top; one
slit window in each wing's front.

## 4. The other sides
Clerestory windows over the aisles, tall windows in the aisles, long slits round the apse's east
half, slits on the wings' sides, four yellow-framed arches on the south annex.

## 5. Roof
Red tiles (#b65a3c) on the nave and aisles; flat grey (#8f8b84) on the front block, wings, east
blocks and annex; brown copper (#8b6b58) on the chapel dome.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #ece6d4 | M_STONE |
| Strips, frames, arches | #e4cd84 | M_STONE |
| Doors | #5b3326 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card unchanged. No floodlights.

## 8. Detail level and budget
L2, triangle budget 950 (measured 825, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_zwycieska`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front block | box | 12.2 x 12 m | u -15.2..-3 | #ece6d4, #8f8b84 | 4 strips, round window, arms, 3 doors, cross |
| wings | boxes | 12.2 x 10.9 and 8.2 m | either side | #ece6d4, #8f8b84 | 2 wings, slits |
| nave | prism, gable | 37 x 12 m | u -3.2..34 | #ece6d4, #b65a3c | clerestory |
| aisles | boxes, lean-tos | 6.2 m deep | both sides | #ece6d4, #b65a3c | 2 aisles |
| apse | 16-sided prism, cone | r 5.5 m | u 35.3 | #ece6d4, #8f8b84 | 4 slits, cross |
| east blocks, annex | boxes | 7 m and 14 m | east and south | #ece6d4, #8f8b84 | 4 arches |
| chapel | octagon, frustums | r 3.6 m | by the front | #ece6d4, #8b6b58 | dome, cross |
