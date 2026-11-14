# Kościół Chrystusa Króla Pokoju and the Our Lady of Częstochowa chapel, Skaryszewska 12: spec

Site key `church_chrystusa_krola` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the
OSM outline under `at`, `_build_church` hands it to `_build_chrystusa_krola`): the Pallottines'
church with its chapel as one model that replaces the plain OpenStreetMap block (building 3051,
"Kaplica pw. Matki Boskiej Częstochowskiej"). Its area is in `tools/bake_sectors.py` SITE_AREAS.
Written 2026-11-14 from 7 Commons photos (refs/churches/pallottines_skaryszewska, reference only,
never shipped), the OSM outline and GUGiK's LoD2. The Pallottines' modernist house beside it is
`church_pallotyni`.

## 1. Identity
1. On the street, the **small cream chapel** with white quoins, a **big dark cross** and a door
   under its gable.
2. A **slim white bell tower** with an arched lantern at the chapel's left corner, and a small
   white turret on its ridge.
3. Behind it, the **square church under a big brown metal pyramid roof** with an **octagonal
   arched lantern**, a dome and two crosses.
4. Low flat-roofed parish wings round it.

## 2. Massing
Frame: origin (1725.1, -1677.5), the outline's centre; u from the street (u = -16.8) into the block
on axis (0.607, 0.795), v to its left. Heights over g, the lowest ground under the outline.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| parish wings | the whole outline | 9.5, flat |
| church | u -5.5..12.5, v -8.5..9.5 | 14.5, pyramid to 20.5 |
| lantern | octagon r 1.6 at (3.5, 0.5) | 22, cap 23.3, cross 25.5 |
| chapel | u -16.8..-8.2, v -4.8..7.1 | eaves 9.6, ridge 12.4 |
| bell tower | 2.7 x 2.3 m at (-15.5, -5.85) | shaft 18.5, lantern 20.8, cap 22 |
| ridge turret | 1.6 m at (-9.2, 1.15) | 14.2, cap 15.2 |

## 3. Facade: the chapel on Skaryszewska
White quoins at the corners, a white cornice under the gable, the door in a white frame, two
small windows over it, the big dark cross to its right, a cross on the gable.

## 4. The other sides
A band of windows round the church above the wings, two rows of windows on the wings' street and
yard sides, arched openings in both lanterns.

## 5. Roof
The church's brown metal pyramid (#7c6a4b); grey (#8a8a84) on the chapel and the flat wings; the
lanterns' caps dark (#3f3c38).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Chapel | #eedfb4 | M_STONE |
| Quoins, tower, turret | #f3f0e8 | M_STONE |
| Wings, church walls | #e6dcc4 | M_STONE |
| Lanterns, cross, door | #3f3c38 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Kościół Chrystusa Króla Pokoju". No
floodlights.

## 8. Detail level and budget
L1, triangle budget 880 (measured 768, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_chrystusa_krola`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | outline prism | 43 x 43 m | the outline | #e6dcc4, #8a8a84 | 6 window rows |
| church | prism, pyramid | 18 m square | u -5.5..12.5 | #e6dcc4, #7c6a4b | window band |
| lantern | octagon, cone | r 1.6 m | the apex | #3f3c38 | 4 openings, 2 crosses |
| chapel | box, gable | 8.6 x 11.9 m | the street | #eedfb4, #8a8a84 | quoins, door, cross |
| tower | box, octagon, cone | 2.7 m | the chapel's left corner | #f3f0e8 | 4 openings, cross |
| turret | box, cone | 1.6 m | the chapel's ridge | #f3f0e8 | cross |
