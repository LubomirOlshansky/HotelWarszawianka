# Teatr Ateneum: spec

Site key `ateneum` in `game/scripts/landmarks/powisle2.gd` (`_build_ateneum`, constants `ATE_`). Written 2026-11-20 from F's four photos (refs `_f/warsaw-needed-photos/powisle/X-Ateneum`: the porch on Jaracza, the curved corner house beside it) and the 20.8 m OSM outline at (581, -382). The porch, the arched band and the letters are `tamka.gd` `_ateneum` (2026-11-09) and stay there.

## 1. Identity

1. A warm grey plaster house with a pale blue-grey plinth on Jaracza.
2. A tall framed window each side of the porch and a round window above each.
3. Three upper floors of framed windows on five axes under a pale cornice.

## 2. Massing

The mapped outline (8 points, simplified to 0.3 m) to 19.4 m, a parapet to 20.8 m, a stage house behind on the roof to 23.2 m. Only the Jaracza edge (from (579.9, -370.5) to (592.1, -386.2), 19.9 m) is free; the other faces stand against neighbours and stay plain.

## 3. Facade, base to top

Plinth 1.5 m (pale blue-grey), a string course at 5.4 m, ground-floor windows 1.4 x 2.4 m at u 2.4 and 17.5, round windows (radius 0.9) at 7.3 m, windows on five axes at sills 9.5, 13.2 and 16.5 m, the middle axis starting at 10.1 m over the porch's crest (9.35 m). Nothing within u 4.5 to 15.4 below 9.4 m (the porch).

## 4. Roof

Flat deck with a 1.4 m parapet, one stage house (12 x 9 m), a lift head and a plant box. The orthophoto was not consulted.

## 5. Colour and material

Plaster #a8a8a2, trim #d2cec2, plinth #98a7ad, roof #6e7072, glass PAL_GLASS_DARK. All M_STONE and the kit's lit panes; no new material.

## 6. Ground and night

The porch and its poster cases are tamka.gd's. Window panes light by chance at night.

## 7. Detail level and budget

L2, triangle budget 800 (built 678).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | ring prism, cornice ring, parapet | 20.8 m high | the outline | M_STONE | 1 grey house |
| plinth | ledge ring | 1.5 m | round the foot | M_STONE | 1 grey house |
| ground_windows | kit_window FRAMED | 1.4 x 2.4 m | u 2.4, 17.5 | M_STONE | 2 windows beside the porch |
| oculi | two stacked discs | radius 0.9 | u 2.4, 17.5, y 7.3 | M_STONE | 2 round windows |
| upper_windows | kit_window SILL_HEAD, SILL | 1.2 x 2.0 m | five axes, three floors | M_STONE | 3 upper floors |
| stage_house | box | 12 x 9 x 4.8 m | behind the front | M_STONE | 1 grey house |
