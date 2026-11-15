# Klasztor Reformatów (the Reformati Franciscans' friary beside St Anthony's, Senatorska 31): spec

**Provisional, no photo** (2026-11-15). Built from LoD2 and the OSM outline: no photo shows the friary's own outer walls, so it takes the church's white plaster and orange-red tiles and plain window rows until one does (docs/QUESTIONS.md).

Site key `church_reformaci_klasztor` in `game/scripts/landmarks/churches.gd` (`_find_churches`
finds it by the OSM outline under `at`, `_build_church` hands it to `_build_reformaci_klasztor`):
the friary on the church's north-east side as one model that replaces the plain OpenStreetMap
block (building 12816, an unnamed `monastery`). Its area is in `tools/bake_sectors.py`
SITE_AREAS. The church's 15 Commons photos (refs/churches/st_anthony_senatorska, reference only,
never shipped) show the complex in white plaster under orange-red tiles and the cloister arcade
(photo 07), not the friary's outer walls.

## 1. Identity
1. A **closed ring of four ranges** round a courtyard, between the church and the street.
2. **Orange-red tile hipped roofs**, matching the church's.

## 2. Massing
Frame: origin (-1193.3, -1001.9), u along (0.6655, -0.7464) to the south-east along the range by
the street, v to the north-east. Heights over g (LoD2; g about 11).

| Part | Plan (u, v) | Height over g |
| --- | --- | --- |
| walls | the outline (u -4..36, v 0..36) | eaves 9 |
| range by the street | u -4..36, v 0..10.5 | ridge 13 |
| range by the church | u -4..36, v 24.5..36 | ridge 13 |
| north-west range | u -4..4, v 10..25 | ridge 12 |
| south-east range | u 22..36, v 0..36 | ridge 13 |
| courtyard | u 4..22, v 10.5..24.5 | open |

## 3. Facade
Two rows of plain windows (g+1.4, g+5.0) round every outer wall and round the courtyard; a light
cornice and plinth band. No door or portal is built (defaults: no photo).

## 4. The other sides
As section 3 on every side (defaults).

## 5. Roof
Hipped tile roofs (#c4603d, the church's), one per range; the flat cap darker.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #f0ece2 (the church's) | M_STONE |
| Cornice, plinth | #e0d9ca | M_STONE |
| Roofs | #c4603d (the church's) | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card: "Klasztor Reformatów". No floodlights.

## 8. Detail level and budget
L1, triangle budget 500 (measured 396, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_reformaci_klasztor`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the outline, 9 m | — | #f0ece2 | courtyard cut out of the top |
| courtyard | inner walls | 18 x 14 m | the middle | #f0ece2 | windows facing in |
| roofs | 4 hips | per range | over the ranges | #c4603d | — |
