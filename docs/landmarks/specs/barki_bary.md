# The bar barges, phase C (sites `barka_nowa_falka`, `barka_zanurzenie`, `barka_wirek`, `barka_kalmar`, `barka_barkas`) and the Płyta Desantu beach bars (`plyta_desantu`)

Written 2026-11-19 for the Vistula boulevards phase C. One barge builder (`_build_bbc_barge`, river.gd)
with five styles (`BBC_BARGES`), moored where BOULEVARD-INVENTORY pins them, snapped to the nearest
bank of the river's water outline (the largest `water` area of the bake), parallel to it, 1.5 m off
the edge. Sources: F's aerial photo of the Pawilon (a long barge, ~80 m, a dark long roofed hall, a
sand-coloured deck full of white umbrellas and tables), F's night photo of the steps with a lit bar
barge (string lights, a round lit logo sign, a railing, plants), the inventory's rows 6 to 9, 15, 19,
22 and 24, BOULEVARD-LORE items 14 and 15. Open (QUESTIONS): the pins are estimates good to 30 to 60 m;
which inventory row F's 80 m barge is (the OSM `Marina Warszawa` barge, `barka_marina`, is only 40 m
and sits opposite the Pawilon): built as a new neighbour, NOWA FALKA (the inventory's name for the
Nowa Fala pair), 70 m, 1.5 m clear of it on the Old Town side.

## 1. Identity

Hull with a coloured antifouling band, a gangway to the bank through a gap in the bulwark, a hall
(long and dark on Nowa Falka, a hut on the others), tables under parasols on the open deck, bulbs on
posts, potted plants, a round lit logo on the roof corner and the parody name in neon on the roof edge.
NOWA FALKA: sand deck, white parasols, long dark hall. ZANURZENIE: a canopy over the deck,
pallet sofas, lanterns. WIREK: a timber platform, pallet furniture, leżaki, industrial lamps.
KALMAR: a floating beach, sand over the whole deck, leżaki, palms, a whitewashed bar. BARKAS: a white
flat-topped barge with two stages (dark platforms, backdrop walls with a lit LED panel). Parody
names only (docs/powisle-life.md section 2).

## 2. Massing

| barge | length x width | pin | hall |
| --- | --- | --- | --- |
| NOWA FALKA | 70 x 12 m | 231, -1089 (the Pawilon's front) | u 5 to 60 %, 3.4 m |
| ZANURZENIE | 22 x 7.4 m | 470, -800 | u 0 to 26 %, 2.8 m |
| WIREK | 26 x 8.6 m | 455, -880 | u 0 to 20 %, 2.7 m |
| KALMAR | 38 x 12 m | 592, -712 | u 40 to 58 %, 2.9 m |
| BARKAS | 42 x 10 m | 705, -562 | u 30 to 76 %, 3.0 m |

Hull: the box with raked ends (r = min(1.6, 0.4 x width)), 0.5 m draught, deck 1.0 m over the water
(`BARGE_FREEBOARD`), the band 0.3 m over the water. The hall stands on the river side of the deck
(the side away from the bank), 76 % of the width less 1 m, centred at 55 % of it.

## 3. Facade

Hall: dark or white walls, glass bands 0.5 m above the deck to 0.5 m under the roof on both long
faces (M_PAVILION, lit at night), dark mullions every 2.5 m; a roof slab 0.25 m on a 0.4 m overhang.

## 4. Roof

Flat; the round logo on a 1.6 m pole at the corner nearest the camera (rim, lit disc, dark ring, lit
eye: 10-sided discs); the neon name standing on the edge of the slab.

## 5. Colour and material

Per style in `BBC_BARGES` (hull, band, deck, wall, roof, glass, parasols, table tops, seats, tube).
M_STONE, M_PAVILION, M_LAMP only; no new material, no new draw call.

## 6. Ground and night

Each barge on the lowest ground under its box (the river's drape), car collision on the hull only.
At night the hall glass, the bulbs (`_barge_festoon`), the stage LED panels, the industrial lamps
and the logo glow.

## 7. Detail level and budget

L2, triangle budget 3700 for the long barge (an exception to L2's 3000: one site, 70 m, about 30 table
sets, built 3070); the others in `check_mesh_quality.gd`: barka_zanurzenie 950, barka_wirek 700,
barka_kalmar 1800, barka_barkas 950, plyta_desantu 1900.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hull | 8-gon prism, band | per style | the bank, 1.5 m off | paint | the barge |
| deck | timber top or 0.12 m sand slab | the hull's plan | on the hull | timber, sand | sand deck, floating beach |
| hall | box + overhang roof + glass + mullions | per style | the river side | paint, M_PAVILION | the long dark hall |
| bulwark + gangway | rail ring, ramp | 0.9 m, 1.4 m wide | round the hull, bank side | paint, timber | the way to the bank |
| table set | table, two benches, parasol | 2.5 m round | the open deck, rows | wood, canvas | tables under parasols |
| pallets, leżaki | sofa boxes, `_bulwar_lezak` | 2 m, 0.56 m | open deck | wood, canvas | pallet furniture, loungers |
| canopy | slab + 4 posts + bulbs | 2.8 m high | Zanurzenie's deck | canvas | the canopied bar |
| stages | platform + backdrop + LED quad | 4 x 7 m | Barkas' ends | dark paint, M_LAMP | two stages |
| lamps, bulbs | posts + cones, `_barge_festoon` | 2.7 m | along the bank rail | M_LAMP | industrial lamps, string lights |
| plants | pot + bush, barrel palm | 1.2 to 2.5 m | along the rail | clay, green | potted plants |
| logo | pole + discs | 0.6 to 0.9 m radius | the hall roof corner | M_LAMP | the round lit logo |
| name | neon sign | 3 to 6 m wide | the roof edge | neon | the parody name |
| (Płyta Desantu) hut, deck, tables, leżaki, dock | boxes | 5.6 x 3.4 x 2.9 m hut; 9 x 3.6 deck; 3 sets; 9 leżaki; 3.4 x 14 dock | three spots by the sand | timber, canvas, neon | the beach bars POMOST 411, FALKA, WODNIK |
