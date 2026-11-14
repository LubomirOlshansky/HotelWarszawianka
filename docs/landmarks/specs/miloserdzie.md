# Kościół pw. Miłosierdzia Bożego i Świętej Faustyny (Divine Mercy and St Faustina), Żytnia: spec

Site key `church_miloserdzie` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_miloserdzie`): the whole church is one model that replaces
the kit church. Written 2026-11-14 from Mapillary photos along Żytnia (2025-01-05 and 2017-02-27
from the street's east end, both looking along the church's street side; refs/miloserdzie, never
shipped), the OSM outline and GUGiK's LoD2. Nothing faces the south side or the west end.

The kit church it replaces (2026-11-01) was a "modern" box with a pyramid tower. The real church
is a plain **white plastered** church in the convent of the Sisters of Our Lady of Mercy, with a
**slim square bell tower** at the street corner and the sisters' house at its east end.

## 1. Identity
1. **White plaster** all over, a low grey roof.
2. The **slim white bell tower** on the street: a plain shaft, an open arched lantern stage and a
   small grey dome with a cross.
3. The long street wall with the **big mural in white and red**, a low annex in front of it with
   the doors and a little tiled porch roof.
4. The sisters' **three-storey white house** under a dark tiled hip at the east end.

## 2. Massing
Frame: origin at the outline's centre (-2748.8, -692.9), u along the church to the east (axis
(-0.2703, -0.9628)), +v to the south; Żytnia runs along the north side (-v). Ground g is the
lowest terrain under the outline (13.4).

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave | u -19.6 to 11, v -4.8 to 4.5 | eaves 8.3; low gable along u, ridge 10.3 |
| street annex | u -7.15 to 11, v -8.3 to -4.8 | 4.3, flat |
| south annex and porch | u -11 to 11, v 4.5 to 7.2; porch u -0.65 to 3.1 to v 9.25 | 4.3, flat |
| sisters' house | u 11 to 19.7, v -8.3 to 6.4 | 11; hip to 13.4 |
| bell tower | u -11.3 to -7.15, v -8.95 to -5.0 | shaft 18; lantern 18.4 to 21.8; dome to 24.3; cross to 25.9 |

LoD2 (ground 13.75 at the tower): the nave 22 to 24 abs (8.3 to 10.3), the low parts 18 (4.3),
the tower 34 at its edges and 39 at its top (20 to 25), the house 26 to 27 (12.5 to 13.3).

## 3. Facade: the street side (north)
The street annex: a brick plinth to 0.9, two dark doors (1.2 m, to 2.4) and a little porch roof
over the eastern one, four small windows. Over it the nave's wall carries the mural: a pale field
(u -6 to 5, 4.3 to 7.8) with a red band, the dark emblem and a grey field for the figures. The
tower: a plain shaft with a dark round clock face at 16.4 on the street side.

## 4. Facade: the sides and the back
The south wall: five tall windows (1.3 m, 4.9 to 7.4) over the south annex. The west end: a plain
gable (unphotographed, default). The house: two windows a storey on each long side, three storeys
on the east end.

## 5. Roof
Grey sheet (#6a6e72) on the nave, a paler grey on the annexes' flat tops; dark tiles (#4c4644) on
the house's hip; the tower's dome grey (#7c8084), an iron cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ecebe6 | M_STONE |
| Cornices, piers | #f4f3ef | M_STONE |
| Nave roof | #6a6e72 | M_STONE |
| House roof | #4c4644 | M_STONE |
| Dome | #7c8084 | M_STONE |
| Mural red, figures | #c23a3a, #5d5f63 | M_STONE |
| Plinth | #8a5040 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text unchanged. No floodlights.

## 8. Detail level and budget
L1, triangle budget 640 (measured 560, `check_mesh_quality.gd`): a plain church, kept lean. Shots:
`tools/turntable.sh church_miloserdzie`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | box + gable | 30.6 x 9.3 m | u -19.6..11, y to 10.3 | M_STONE #ecebe6, #6a6e72 | 4 nave |
| mural | 4 flat panels | 11 x 3.5 m | street wall, y 4.3..7.8 | #c23a3a, #5d5f63 | 3 mural |
| annexes | 2 prisms | 4.3 m | north and south | M_STONE | 3 mural |
| doors, porch | 2 boxes + slab | 1.2 m | street annex | PAL_DARK_DOOR, #f4f3ef | 3 mural |
| house | box + hip | 8.7 x 14.7 m | u 11..19.7, y to 13.4 | M_STONE, #4c4644 | 4 house |
| tower | box, 4 piers, core, 2 frustums, cross | 4.15 x 3.95 m | u -11.3..-7.15, y to 25.9 | M_STONE, #7c8084 | 2 tower |
| windows | flat panes | 1.1 to 1.3 m | nave south, house, annex | PAL_GLASS_DARK | 4 nave |
