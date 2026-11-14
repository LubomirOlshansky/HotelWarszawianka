# Dom Księży Misjonarzy (the Missionaries' house), Radna 14: spec

Site key `church_misjonarze_radna` in `game/scripts/landmarks.gd` (`_find_churches` finds it by
the OSM outline under `at`, `_build_church` hands it to `_build_misjonarze_radna`): the house with
the Miraculous Medal chapel as one model that replaces the plain OpenStreetMap block (building
2279), in Powiśle. Its area is in `tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from 7
Commons photos (refs/churches/missionaries_radna_14, reference only, never shipped), the OSM
outline and GUGiK's LoD2.

## 1. Identity
1. A **five-storey cream front** on Radna over a **rusticated ground floor with round-headed windows**.
2. The **portal** in the middle under a **blue niche with the white Virgin** and a balcony.

## 2. Massing
Frame: origin (-53.0, -747.2), the front's east corner, u along Radna on axis (-0.888, 0.459),
v back into the block; the front faces -v. Heights over g.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| front wing | u 0..24.64, v -0.05..12.75 | eaves 18.6, ridge 20.6 |
| back block (the chapel) | u 0.25..24.15, v 12.65..25.15 | 7, flat |

## 3. Facade: Radna
Nine bays. The ground floor rusticated (#cbbd9c) to 4.5 with round-headed windows, a ledge on it;
four floors of windows above, the cornice at 18.2. The portal in the middle bay: a cream surround,
the oak door, the blue niche with the white figure over it, the balcony slab and its dark railing.

## 4. The other sides
Windows on three floors of the front wing's courtyard side over the back block; four tall dark
leaded windows on the back block's back wall for the chapel (photo 07 shows one; their place is
a default).

## 5. Roof
A low gable roof (#6a6460) on the front wing, a flat roof on the back block.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Cream plaster | #e8dcb8 | M_STONE |
| Ground floor | #cbbd9c | M_STONE |
| Cornices, portal | #efe9da | M_STONE |
| Niche | #7fb3c8 | M_STONE |
| Door | #5a3a26 | M_STONE |
| Roof | #6a6460 | M_STONE |
| Windows | PAL_GLASS_DARK, chapel #2f3b3a | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Misjonarze na Radnej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 600 (measured 514, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_misjonarze_radna`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front wing | prism, gable | 24.6 x 12.8 m | on Radna | #e8dcb8, #6a6460 | cornice |
| back block | prism | 23.9 x 12.5 m, 7 m | behind | #e8dcb8 | flat roof |
| front | boxes, panes, doors | 24.6 m | -v | #cbbd9c, glass | rustication, 8 arched windows, 36 windows |
| portal | boxes, door | 3.2 m | middle bay | #efe9da, #7fb3c8, #5a3a26 | niche, Virgin, balcony |
| chapel windows | panes | 1.6 x 3.8 m, 4 | back wall | #2f3b3a | — |
