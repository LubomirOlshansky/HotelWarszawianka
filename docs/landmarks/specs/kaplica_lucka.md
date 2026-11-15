# Kaplica przy Łuckiej (the yard chapel behind Łucka 2/4/6, off Żelazna, Wola): spec

**Provisional, no photo** (2026-11-15). It is built from LoD2 and the OSM outline only. No open
street photo reaches the yard (refs/churches/kaplica_zelazna stays empty), so every part is a
default of `_flat_chapel` until a photo arrives (docs/QUESTIONS.md).

Site key `church_kaplica_lucka` in `game/scripts/landmarks/churches.gd`. `_find_churches` finds it
by the OSM outline under `at`, and `_build_church` hands it to `_build_kaplica_lucka`. It is one
model that replaces the plain OpenStreetMap block (building 7458, `chapel`, unnamed). Its area is
in `tools/bake_sectors.py` SITE_AREAS.

## 1. Identity
1. A **small single-storey chapel** (8.8 x 11.4 m) under a **flat roof**, in the yard behind the
   houses on Łucka.
2. It reads as a chapel by its **tall narrow windows**, an **arched door** and a **cross** on the
   roof over the door's end.

## 2. Massing
The OSM outline as it is, walls to g+5.3 (GUGiK's LoD2: the roof about 5 to 5.6 m over the ground,
a slight slope left flat).

## 3. Facade (the door wall, towards Łucka)
Pale plaster on a grey plinth (to g+0.4) under a lighter coping (g+5.0 to 5.45); an arched door
(1.5 x 2.6) in the middle; tall windows (0.9 x 2.6, sill g+1.4) about every 2.6 m beside it.

## 4. The other sides
The same plaster, plinth, coping and tall windows, no door.

## 5. Roof
Flat, pale gravel; an iron cross 1.6 m tall, 1.6 m in from the door wall.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e4dccb (a default) | M_STONE |
| Plinth | PAL_GREY_STONE | M_STONE |
| Roof | PAL_ROOF_GRAVEL | M_STONE |
| Windows | PAL_GLASS_DARK in a darker plaster frame | M_STONE |
| Door, cross | PAL_DARK_DOOR, PAL_IRON | M_STONE |

No new material, shader instruction or draw call.

## 7. Ground and night
Collides along its outline. Card: "Kaplica przy Łuckiej". No floodlights.

## 8. Detail level and budget
L1, triangle budget 300 (measured 112, `check_mesh_quality.gd`). Turntable checked from every
side. Not included: anything a photo would have to show.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| walls | prism | the OSM outline, g-0.8 to g+5.3 | outline | plaster | flat gravel top |
| plinth, coping | ring slabs | 1.2 and 0.45 tall | g-0.8, g+5.0 | stone, light plaster | proud 0.05, 0.12 |
| windows | panes | 0.9 x 2.6 | every 2.6 m on walls over 4 m | glass in a frame | tall and narrow |
| door | arched panel | 1.5 x 2.6 | the wall facing Łucka | dark paint | default |
| cross | two bars | 1.6 tall, 0.9 arm | on the roof by the door wall | iron | default |
