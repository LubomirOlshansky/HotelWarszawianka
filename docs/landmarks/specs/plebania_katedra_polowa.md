# Plebania Katedry Polowej (the Field Cathedral's presbytery, Długa 13/15): spec

Written 2026-11-15 from two Mapillary photos on Długa (refs/churches/plebania_katedra_polowa,
CC BY-SA, reference only, never shipped), the OSM outline and GUGiK's LoD2. Trees hide the upper
floors and the roof in both photos, so the roof colour, the window rhythm and the balcony are
defaults until a clear photo arrives (docs/QUESTIONS.md).

Site key `church_plebania_katedra_polowa` in `game/scripts/landmarks/churches.gd`
(`_find_churches` finds it by the OSM outline under `at`, `_build_church` hands it to
`_build_plebania_katedra_polowa`): one model that replaces the plain OpenStreetMap block
(building 1833, `presbytery` "Plebania"). Its area is in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **three-storey cream house** standing against the cathedral's north side, its front on
   Długa a step (about 2 m) ahead of the church's.
2. **Framed windows** in pale stucco and an **arched door** with a balcony over it.

## 2. Massing
Frame: origin (-1165.3, -1665.4), the front's corner by the cathedral; u along (0.624, -0.781) to
the north-east along Długa, v to the south-east into the block. Heights over g (LoD2; g about 4.7).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u 0..22.8, v 0..15.2) | eaves 12.8 |
| roof | gable along u, ridge at v 7.6 | ridge 17.3 |

## 3. Facade (Długa, -v)
Seven window columns on three floors (g+1.4, g+5.3 tall, g+9.3), each in a stucco frame; hoods
over the first floor; string courses at g+4.6 and g+8.7; the arched door in a stone portal in
the middle column, a balcony on two brackets over it.

## 4. The other sides
The back and the north-east gable end: three rows of plain windows (defaults). The south-west end
stands against the cathedral: no windows.

## 5. Roof
A gable roof along Długa, green copper like the cathedral's (#6f8d7e, a default), the gable ends in
the wall colour.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e8dcc0 (photos) | M_STONE |
| Window frames, cornice, string courses | #f3ece0 | M_STONE |
| Roof | #6f8d7e (a default) | M_STONE |
| Door | #4a3426 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Plebania Katedry Polowej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 600 (measured 537, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_plebania_katedra_polowa`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 12.8 m | — | #e8dcc0 | cornice and plinth rings |
| roof | gable | 23 x 15.5 m, rise 4.5 | over the walls | #6f8d7e | — |
| front | framed windows, door, balcony | 21 windows | Długa side | #f3ece0 | balcony over the door |
