# Lipowa 1A: spec

Site key `lipowa1a` in `game/scripts/landmarks/powisle2.gd` (`_build_lipowa1a`, constants `LP_`). Written 2026-11-20 from F's screenshot of the block (3D view over the University Library's vault) and the Lipowa photos (`C-Lipowa-1-04`), on the OSM outline at (111, -889) (mapped as 10.9 m, which is the default height).

## 1. Identity

1. A white base of three floors with small windows.
2. Four floors of dark glass behind balcony slabs on the Lipowa front, between teal fins.
3. A teal rim round the roof and a planted roof terrace with boxes and a glass pavilion.

## 2. Massing

The mapped outline (simplified 0.6 m) to 22.6 m (seven floors), a 0.9 m teal rim over it. The front is the edge from (117.4, -900.4) to (97.2, -890.0), 22.7 m, facing the street.

## 3. Facade, base to top

Front: three rows of five small windows (1.0 x 1.4 m) from 1.5 m, an entrance in the middle; from 10.8 m a dark glass wall 0.15 m out with balcony slabs every 3 m and five teal fins (0.44 m wide, 1.1 m deep). Other faces: seven rows of small framed windows every 3 m.

## 4. Roof

Brown-green deck, four grey plant boxes, a lift head and a glass pavilion; from the photo, not the orthophoto.

## 5. Colour and material

Plaster #dcdad2, teal #4f9a94, glass #34424a, slabs #cfcdc5, deck #6d6040. The glass is the skin material S_RIBBON; no new material.

## 6. Ground and night

Windows light by chance at night; the pavilion glows (M_PAVILION).

## 7. Detail level and budget

L2, triangle budget 1150 (built 960).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | ring prism | 22.6 m high | the outline | M_STONE | 1 white base |
| base_windows | kit_window SILL | 1.0 x 1.4 m | five axes, three floors | M_STONE | 1 white base |
| glass_wall | wall | 21 x 11.8 m | front, from 10.8 m | M_SKIN S_RIBBON | 2 dark glass |
| slabs | boxes | 1 m deep | each floor of the glass | M_STONE | 2 balcony slabs |
| fins | boxes | 0.44 x 1.1 m | five on the front | M_STONE | 2 teal fins |
| rim | ledge ring | 0.9 m | round the roof | M_STONE | 3 teal rim |
| terrace | boxes | 1.2 to 2.5 m | on the roof | M_STONE, M_PAVILION | 3 roof terrace |
