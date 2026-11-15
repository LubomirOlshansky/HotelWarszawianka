# Klasztor Sióstr Wizytek (the Visitation Sisters' convent, Krakowskie Przedmieście 34): spec

**Provisional, no photo** (2026-11-15). Built from LoD2 and the OSM outline only: no photo shows the convent's outside walls, so the plaster, the roofs and the windows are defaults until one does (docs/QUESTIONS.md).

Site key `church_wizytki_klasztor` in `game/scripts/landmarks.gd` (`_find_churches` finds it by
the OSM outline under `at`, `_build_church` hands it to `_build_wizytki_klasztor`): the convent
behind the Visitationist church as one model that replaces the plain OpenStreetMap block
(building 12626). Its area is in `tools/bake_sectors.py` SITE_AREAS. Written 2026-11-15 from
GUGiK's LoD2 and the OSM outline only: no open street photo shows the convent (Mapillary and
Panoramax: 0 facing photos within 80 m; it stands behind the church and the garden wall; F's 12
Commons photos in refs/churches/wizytki_klasztor show the church front and the interiors, and
one room of the convent with the turning box, but no outside wall), so the
colours and the window rows are defaults, parked in docs/QUESTIONS.md until photos arrive.

## 1. Identity
1. A **closed ring of four two-storey ranges** round a courtyard, behind the church.
2. **Steep hipped tile roofs**, one per range, the long range along Karowa.

## 2. Massing
Frame: origin (-444.1, -813.3), u along (-0.518, -0.856) to the north-west (u 27 is the range on
Karowa), v to the east-north-east, towards the escarpment. Heights over g (LoD2).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u -33..27, v -4..52) | eaves 8 |
| west range, by the church | u 0..27, v 0..15.5 | ridge 14.5 |
| its link south | u -14..0, v 6.6..14.4 | ridge 11.4 |
| south range | u -22..-8, v 14..45 | ridge 14.5 |
| range on Karowa | u 15..27, v 0..52 | ridge 14 |
| garden range | u -31..27, v 38..52 | ridge 14.5 |
| courtyard | u -1..15, v 15.5..38 | open; a flat cloister walk on its west side at the eaves |

## 3. Facade
Two rows of plain windows (g+1.2, g+4.7) round every outer wall and round the courtyard; a white
cornice and plinth band. No door or portal is built (defaults: no photo).

## 4. The other sides
As section 3 on every side (defaults).

## 5. Roof
Hipped tile roofs (#9a5545, a default); the flat cloister walk darker.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e8dcc2 (a default, the church's tone; the convent room in photo 02 is white) | M_STONE |
| Cornice, plinth | #f2ede2 | M_STONE |
| Roofs | #9a5545 (a default) | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor Wizytek". No floodlights.

## 8. Detail level and budget
L1, triangle budget 900 (measured 644, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_wizytki_klasztor`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 8 m | — | #e8dcc2 | courtyard cut out of the top |
| courtyard | inner walls | 16 x 22.5 m | the middle | #e8dcc2 | windows facing in |
| roofs | 5 hips | per range | over the ranges | #9a5545 | — |
