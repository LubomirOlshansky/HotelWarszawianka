# Kaplica przy katedrze św. Floriana (the octagonal chapel by St Florian's cathedral, Floriańska, Praga): spec

Site key `church_kaplica_florianska` in `game/scripts/landmarks/churches.gd`. `_find_churches`
finds it by the OSM outline under `at`, and `_build_church` hands it to
`_build_kaplica_florianska`. It is one model that replaces the plain OpenStreetMap block (building
6848, `chapel`, unnamed, 3 m). It stands inside the cathedral's fence at the corner of the close
on Floriańska. Its area is in `tools/bake_sectors.py` SITE_AREAS. Written 2026-11-15 from eight
Mapillary photos on Floriańska (2018-2020, refs/churches/kaplica_florianska, reference only, never
shipped); five show it beside the cathedral's front. GUGiK has no LoD2 for it.

## 1. Identity
1. A **small octagon of red brick**, about 6.3 m across, beside the cathedral's front.
2. A **dark slate bell roof**, taller than the walls, flaring at the eaves and drawn in to a
   small finial.

## 2. Massing
The OSM octagon as it is; walls to g+3.6 (photos: the walls stand about twice the fence), the
roof to g+7.2 and the finial to g+8.0.

## 3. Facade
Plain red brick on a darker brick plinth (to g+0.4) under a darker brick cornice (g+3.15 to 3.6).

## 4. The other sides
As section 3. One arched door on the side towards the cathedral (east) is a default: no photo
shows it (docs/QUESTIONS.md).

## 5. Roof
Three slate frustums (flare 1.12 to 1.0 of the plan, swell to 0.78, draw in to 0.42), a short
pyramid on top, a slim shaft with a small ball.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Brick | #9b4535 | M_STONE |
| Plinth, cornice, door surround | #7e3528 | M_STONE |
| Roof, finial | #3b3d42 | M_STONE |
| Door leaf | #3a2a22 | M_STONE |

No new material, shader instruction or draw call.

## 7. Ground and night
Collides along its outline. Card: "Kaplica przy katedrze św. Floriana". No floodlights.

## 8. Detail level and budget
L1, triangle budget 400 (measured 184, `check_mesh_quality.gd`). Turntable checked from every
side. Not included: windows (none seen on the street sides), the fence (the cathedral's).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the OSM octagon, g-0.8 to g+3.6 | outline | brick | plain |
| plinth, cornice | ring slabs | 1.2 and 0.45 tall | g-0.8, g+3.15 | dark brick | proud 0.06, 0.14 |
| roof | 3 frustums and a pyramid | 3.6 tall | g+3.6 | slate | bell shape |
| finial | 4-sided shaft and ball | 0.9 tall | the top | slate | small ball near the top |
| door | arched panel | 1.1 x 2.3 | east side | dark wood | default |
