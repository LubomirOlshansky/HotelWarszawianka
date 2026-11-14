# Cerkiew Zaśnięcia Matki Bożej (the Basilians' Greek Catholic church), Miodowa 16: spec

Site key `church_cerkiew` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_cerkiew`): the church hall is one model that replaces the kit
church. Written 2026-11-14 from Mapillary 360s of 2026 along Miodowa (refs/cerkiew, never
shipped), the OSM outline and GUGiK's LoD2. The photos show the monastery's street wing, whose
middle under a pediment and a cross is the church's front on Miodowa; that wing is the
monastery's own building, not this model. The hall stands behind it in the courtyards and no
photo reaches it, so its walls follow the street front's classicist style.

The kit church it replaces (2026-11-01) was an "orthodox" box with an onion dome. The church is
Greek Catholic and classicist and has no onion dome.

## 1. Identity
1. A **tall white hall** under a **grey gable roof**, its ridge (26.4 m) over the street wing's
   roofs, with a **cross** on its west gable.
2. The **polygonal east end** under a low pyramid roof.
3. **Pilasters and tall round-headed windows** along the sides.

## 2. Massing
Frame: origin (-1034.4, -1518.1), the hall's west corner by the street wing; u along the hall
away from Miodowa (axis (0.569, -0.822)), v across; the axis at v 7.9. Ground g is the lowest
terrain under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| hall | u 0 to 18, v 0 to 15.8 | eaves 21; gable along u, ridge 26.4 |
| east end | the outline's six corners from u 18 to 24.4 | 19.9; pyramid roof to 23.5 |

LoD2: the eaves about 21, the ridge 26.4 along the hall, the east end 20 to 23.5; the monastery's street wing 17.4 at the eaves and 20 at its ridge, its pediment 19.4.

## 3. Facade: the west gable
Over the street wing's roof: the gable with a white-framed oculus (r 1.2) and the cross.

## 4. Facade: the sides and the east end
Four pilasters and three round-headed windows (1.6 m wide, 9.5 to 15.6) a side; the east end
plain (unphotographed, default).

## 5. Roof
Grey sheet (#5d6268): the hall's gable and the east end's pyramid.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #ebe5d7 | M_STONE |
| Pilasters, frames, oculus ring | #f5f1e8 | M_STONE |
| Roof | #5d6268 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`); the hall stands in the courtyard. Card text says
Greek Catholic and Basilian (it said Orthodox). No floodlights.

## 8. Detail level and budget
L1, triangle budget 410 (measured 288, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_cerkiew`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | prism + gable | 18 x 15.8 m | u 0..18, y to 26.4 | #ebe5d7, #5d6268 | 1 hall |
| east end | polygon prism + pyramid frustum | 6.4 x 15.5 m | u 18..24.4, y to 23.5 | #ebe5d7, #5d6268 | 1 east end |
| pilasters | boxes | 0.7 m | 4 a side | #f5f1e8 | 8 pilasters |
| windows | arched panels | 1.6 x 5.6 m | 3 a side | PAL_GLASS_DARK, #f5f1e8 | 6 windows |
| west gable | oculus discs, cross | r 1.2 m | u 0, y 23.4 to 28 | #f5f1e8 | 1 cross |
