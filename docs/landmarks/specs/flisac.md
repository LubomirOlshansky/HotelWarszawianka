# Flisac, Tamka 2 (the apartment block by the Świętokrzyski bridge): spec

Site key `flisac` in `game/scripts/landmarks.gd` (`_find_flisac`, `_build_flisac`). Written
2026-11-13 from F's photos (a Hamilton May listing: the Tamka corner from above, the roof garden;
a visualisation with the bridge, the stadium and the church beside it) and the OpenStreetMap
outlines (unnamed: the 14.2 m "office" wings and the 7.6 m block in the elbow, found by point
`FLISAC_AT`, `FLISAC_PODIUM_AT`; `tools/bake_sectors.py` SITE_AREAS lists their box). Photos are
reference only. Open *(photo check)*: the exact floor count, the glass corner loggias, the gold fin
screen on the courtyard side, the real shop names (parodies are used).

## 1. Identity

Ghelamco's Flisac (2022): luxury flats in a V of two wings round the bend where Tamka meets
Wybrzeże Kościuszkowskie, the corner chamfered. Defining: a light stone grid (thick piers and
bands round big dark windows, a copper blind here and there), shops at the foot with a coffee place
under a white canopy on the corner, then two set-back floors behind a glass-railed terrace and a
green roof with a glass pergola, planters and a dark lift core.

## 2. Massing

The mapped wings (14.2 m, about 15 m deep, 55 m on Tamka, 48 m on Wybrzeże, a 19 m chamfer) are
raised to ground 4.6 m + six floors of 3.2 m = 23.8 m, a dark coping to 24.2 m, a glass screen to
25.2 m; the set-back floors (inset 3.6 m on every side) rise to 30.6 m. The 7.6 m block in the
elbow becomes a garden podium (green roof). Ground under the footprint is the lowest corner.

## 3. Facade, base to top

Light stone `#d8d0c0`. Ground floor: shop glass 3.6 m bays between 1.2 m stone piers (dark frame,
pane lit by chance at night), a dark fascia over it. Upper floors: a window in every bay (2.45 x 2.4 m
in a dark frame, 0.55 m above each floor), one bay in seven a loggia (a deep dark opening with a
glass rail), one in five a copper blind over the upper half. The set-back floors: darker stone,
floor-to-ceiling panes (2.6 x 2.5 m). Parody names in neon on the fascia: KAWOBIURKO at the corner
(a coffee chain), KAROLEK further along Tamka (a grocer), WINOSTORY on Wybrzeże (a wine shop).

## 4. Roof

Flat green roofs (`#7b9a55`) at both levels, dark coping `#3d4044`. On the top: a pergola of glass
(pale blue-grey roof plate on slim posts every 3.6 m) along the longest edge, planters of grass
behind it, a dark lift core (6 x 4 x 3.4 m) and two air-conditioning boxes.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Stone walls | #d8d0c0, upper #cdc5b6 | M_STONE |
| Window and shop panes | #43505b, shop #2f3a42 | M_PANE (lit by chance at night) |
| Frames, fascia, coping | #33363a, #3d4044 | M_STONE |
| Copper blinds | #b9733f | M_STONE |
| Glass screen and rails | #a9bcc4 | M_STONE |
| Green roof | #7b9a55 | M_STONE |
| Canopy | #ebe7dd | M_STONE |

No new material; three new neon words (one sign atlas, no new draw call).

## 6. Ground and night

Car stopped by the wings and the podium (two rings). Card "Flisac, Tamka 2". Night: panes are lit
one by one by chance; the neon words glow in the shops' own colours.

## 7. Detail level and budget

L3, 3552 triangles measured, budget 4200 (`check_mesh_quality.gd`, `flisac`; the exception to L3's
usual ceiling is not needed, 4200 is under 8000). Shots: `--at=455,-570 --solo=flisac --size=90`
(from above), and the street view `--at=436,-596 --heading=225`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | prism of the outline | 23.8 m high | the OSM block | M_STONE | 2 massing |
| coping | ring prism | 0.75 m high, 0.1 m proud | 23.4..24.2 m | M_STONE | 3 facade |
| shop glass | quads | 3 x 3.6 m per bay | ground floor | M_PANE | 3 facade |
| fascia | quads | 0.6 m high | 4..4.6 m | M_STONE | 3 facade |
| windows | quads, frame and pane | 2.45 x 2.4 m per bay and floor | floors 1-6 | M_PANE | 3 facade |
| loggias and blinds | quads | 2.7 x 2.5 m, 2.45 x 1.1 m | some bays | M_STONE | 3 facade |
| glass screen | ring prism | 1 m high | 24.2..25.2 m, inset 0.5 m | M_STONE | 4 roof |
| set-back floors | prism and windows | 6.2 m, inset 3.6 m | 24.2..30.6 m | M_STONE, M_PANE | 2 massing |
| podium | prism and windows | 7.6 m | the elbow block | M_STONE | 2 massing |
| canopy | slab, 2 posts, screen, 4 tables | 11 x 3.6 m | the chamfer's middle | M_STONE | 3 facade |
| hedges | boxes | 4 x 1 x 0.9 m | foot of the Tamka front | M_STONE | 3 facade |
| roof pergola | posts and glass plate | 3 m high | the top's longest edge | M_STONE | 4 roof |
| roof boxes | lift core, 2 AC units, planters | 3.4 m, 1.1 m, 0.8 m | the top | M_STONE | 4 roof |
