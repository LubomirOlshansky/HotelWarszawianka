# Teatr Ateneum: spec

Site key `ateneum` in `game/scripts/landmarks/powisle2.gd` (`_build_ateneum`, constants `ATE_`). Rewritten 2026-11-21 from F's photos and aerial (the porch on Jaracza, the curved corner, the vertical ATENEUM sign, the whole block from above). The Ateneum is the whole L-shaped block: the 20.8 m Jaracza house and the map's 47.2 m "hotel" strip (wrong height) are one building of about 23 m, replaced by one hand-set ring (`_ate_ring`) with a true arc at the corner. The porch, the arched band and the letters stay `tamka.gd`'s.

## 1. Identity

1. The L of two wings joined by a rounded corner with a ground-floor colonnade.
2. Pink walls with white pilaster strips, a taupe ground floor, a red and white set-back attic.
3. Tall arched windows over the porch and over the corner, round windows beside the porch.
4. The vertical coloured ATENEUM sign at the far end of the Jaracza wing.

## 2. Massing

The ring: the Wybrzeże wing's outer face from (555.2, -456.5) to (598.1, -403.3), an arc (sagitta 3 m, five bays) to (592.1, -386.2), the Jaracza face to (579.9, -370.5), the courtyard side plain. Cornice at 19.9 m, attic set back 1.6 m to 23.0 m, a stage house on the roof.

## 3. Facade, base to top

Ground floor 5.4 m: taupe with framed windows (stone grey under the corner arcade: cream columns, arched openings), white string course. Four floors of windows at sills 6.7, 10.0, 13.3, 16.6 m every 3.3 m, white pilasters at the ends and every 13 m, a balcony rail along the corner's first floor, tall arched windows over the three middle corner bays and over the porch, round windows at 7.6 m each side of the porch.

## 4. Roof

Flat deck with a 1.4 m parapet, one stage house (12 x 9 m), a lift head and a plant box. The orthophoto was not consulted.

## 5. Colour and material

Plaster #a8a8a2, trim #d2cec2, plinth #98a7ad, roof #6e7072, glass PAL_GLASS_DARK. All M_STONE and the kit's lit panes; no new material.

## 6. Ground and night

The porch and its poster cases are tamka.gd's. Window panes light by chance at night.

## 7. Detail level and budget

L3 for the identity features, triangle budget 5200 (an exception to the L2 range: a whole block of two wings; built 4973).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | ring prism, attic ring | 23 m high | the hand-set ring | M_STONE | 1 the L |
| corner_arc | five wall bays, columns | radius 15 m | junction | M_STONE | 1 the L |
| bays | kit_window grid | 1.2 x 1.9 m | every 3.3 m, four floors | M_STONE | 2 pink walls |
| pilasters | kit_pilaster | 1.1 m wide | ends and every 13 m | M_STONE | 2 pink walls |
| arched_windows | kit_window ARCHED | 1.7 x 6.4 m | over porch and corner | M_STONE | 3 tall windows |
| oculi | stacked discs | radius 0.9 | each side of the porch | M_STONE | 3 round windows |
| sign | seven lit boxes | 1 x 1.3 m each | far end of the Jaracza wing | M_LAMP | 4 ATENEUM sign |