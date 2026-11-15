# Sala św. Faustyny (the St Faustina hall, St James' parish, Ochota): spec

Site key `church_sala_faustyny` in `game/scripts/landmarks.gd` (`_find_churches` finds it by the
OSM outline under `at`, `_build_church` hands it to `_build_sala_faustyny`): the parish hall as
one model that replaces the plain OpenStreetMap block (building 5693). Its area is in
`tools/bake_sectors.py` SITE_AREAS. Written 2026-11-14 from one Commons photo
(refs/churches/sala_faustyny, reference only, never shipped) and the OSM outline (8 m).

## 1. Identity
1. A **low red brick hall** with a **row of steep gabled bays** between brick piers.
2. A **round-arched porch** with a dark roof over the oak door.

## 2. Massing
Frame: origin (-2794.0, 1570.0), u east (+x), v south (+z). Heights over g.

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| hall | the outline (u -13.4..14, v -7.8..8) | 5 |
| three gabled bays | centres u -10.5, -3.85, 3.9, 6.2 m wide, v -7.4..6.6 | ridges 8 |
| porch | u 9.2..14, v 4.5..8.1 | 4.2, a low gable to 5.2 |

## 3. Facade: the south side to the parish yard
The gables over the piers, a dark louvre in each, a tall narrow window under each bay; the porch
with the arched oak door in a light stone frame.

## 4. The other sides
Plain brick (defaults: the photo shows only the south side).

## 5. Roof
Dark sheet (#4e4f52) on the gables and the porch; the flat parts lighter.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #b0503a | M_STONE |
| Roofs | #4e4f52 | M_STONE |
| Door frame | #c9c1b0 | M_STONE |
| Door | #5a3826 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Sala św. Faustyny". No floodlights.

## 8. Detail level and budget
L1, triangle budget 250 (measured 182, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_sala_faustyny`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | prism | the outline, 5 m | — | #b0503a | flat roof |
| bays | 3 gables | 6.2 x 14 m, 3 m high | over the hall | #b0503a, #4e4f52 | louvre, window |
| porch | box, gable, door | 4.8 x 3.6 m | south-east | #b0503a, #4e4f52 | arched door |
