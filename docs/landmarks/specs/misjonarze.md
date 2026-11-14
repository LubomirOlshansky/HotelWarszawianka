# Dom Księży Misjonarzy (the Missionaries' house), Krakowskie Przedmieście 1/3: spec

Site key `church_misjonarze` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the OSM
outline under `at`, `_build_church` hands it to `_build_misjonarze`): the street wing and the
Karowa wing as one model that replaces the plain OpenStreetMap block (building 7141, tagged as the
University's Faculty of Philosophy, which uses it), by the Holy Cross church. The back wing
(building 5803, "Dom zakonny Księży Misjonarzy") stays the plain block. Its area is in
`tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from 8 Commons photos
(refs/churches/missionaries_krakowskie_przedmiescie_1, reference only, never shipped), the OSM
outline and GUGiK's LoD2.

## 1. Identity
1. A **long ochre front of 17 bays** on Krakowskie Przedmieście, three storeys.
2. A **white rusticated ground floor** with arched gates and shop doors.
3. A **row of white gabled dormers** on a grey roof.

## 2. Massing
Frame: origin (-515.5, -564.0), u toward the church on axis (0.288, 0.958), v to the north-west;
the street front faces -v. The street wing's front is skewed 3.5 degrees, so it has its own frame
from its corners (-469.18, -549.9) by the church and (-483.29, -588.21) at Karowa. Heights over g.

| Part | Plan | Height over g |
| --- | --- | --- |
| walls | the whole outline | eaves 12.5 |
| street wing roof | its own frame, 41 x 14.9 m | ridge 16, gable ends |
| Karowa wing roof | u -14.35..0.15, v -26..18 | hipped, ridge 15.8 |

## 3. Facade: Krakowskie Przedmieście
17 bays. The ground floor white to 4.2 with rustication lines, a ledge on it; arched gates in bays
2, 5, 13 and 16 and the big one in the middle (bay 9), shop windows in the rest. First-floor windows
with white caps, a sill band at 7.9, second-floor windows, the white cornice at 12.1. Eleven white
dormers on the roof, each with its window and a small grey gable.

## 4. The other sides
Windows on three floors on the Karowa side, the courtyard sides and the north end (defaults; the
photos show only the street front and its Karowa corner).

## 5. Roof
Grey (#5b5d60): a gable roof over the street wing, a hipped roof over the Karowa wing.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Ochre plaster | #d7c08a | M_STONE |
| Ground floor, cornice, caps, dormers | #e9e4d6 | M_STONE |
| Roof | #5b5d60 | M_STONE |
| Gates | #4b3a2e | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Dom Księży Misjonarzy". No floodlights.

## 8. Detail level and budget
L1, triangle budget 1150 (measured 1053, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_misjonarze`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 12.5 m | — | #d7c08a | — |
| roofs | gable, hip | 41 x 15 m, 14 x 44 m | the two wings | #5b5d60 | — |
| street front | boxes, panes, doors | 41 m | -v | #e9e4d6, glass | rustication, 5 gates, 51 windows, cornice |
| dormers | boxes, gables | 1.6 x 2.6 m, 11 | street roof | #e9e4d6, #5b5d60 | a window each |
| other windows | panes | — | Karowa, courtyard, north end | PAL_GLASS_DARK | 3 floors |
