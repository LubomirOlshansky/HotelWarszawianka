# Pasaż Wiecha at Christmas 2026: spec

Site key `wiecha_swieta` in `game/scripts/landmarks/wiecha_swieta.gd` (`_find_wiecha_swieta`,
`_build_wiecha_swieta`); the pavilions' cafés and signs in `landmarks/centre.gd` (`WIECHA_SHOPS`);
the Y masts in `props.gd` `add_y_mast`; the people in `crowds.gd` (kind `wiecha`) and
`wiecha_life.gd`. Written 2026-11-22 from F's six night photos (IMG_8425, 8429, 8432-8435) and the
seven frames of an Instagram carousel of the opening night; the shops from OpenStreetMap. Refs
(never committed): `/mnt/project-files/refs/pasaz-wiecha-2026/`. Card: "Święta w Pasażu Wiecha".

## 1. Identity

The pasaż behind the Eastern Wall dressed for Christmas: what makes it read, in order:

1. **A pair of shooting stars on every white Y mast**: an eight-petalled white LED star with a gold
   heart, a tail of white strands with warm bulbs falling towards the pole.
2. **The gingerbread man you walk through**: five neon outlines one behind another, blue, green,
   cream, yellow, red, each smaller, on two grated rails.
3. **The neon fir** of crossed fins (yellow tube outside, red inside, pale film between), with an
   orange wire bauble, a gold open bauble and a bench, by Wars.
4. **The purple and gold bauble benches**, the **WARSIK SAWKA JUNIOREK photo frame** (the stores'
   names as the game parodies them everywhere), the **blue tinsel frame**, white LED curtains on
   the stores' back glass, a neon heart, candy cane and bauble ring further south.
5. **The cafés' own lights**: the fronts of Złota 11 lit in their colours under bulb strings.

## 2. Massing: the plan (first_scene.gd's frame: u north along Marszałkowska, v east; stores' backs v 61-62)

| Thing | u, v | Size |
| --- | --- | --- |
| Shooting stars | every PASAZ_MASTS mast, ±1.55 m across | head r 1.05 m at 5.4 m, tail to 2.6 m |
| Photo frame | -83, 65.4 | 3.4 x 4.1 m, across the pasaż |
| Gingerbread tunnel | -27.5, 68.6 | 5.5 m tall, layers 0.7 m apart along u |
| Blue tinsel frame | 13.6, 66.9 | 2.6 x 3.0 m |
| Neon fir | -127, 68.4 | 5.6 m, r 2.1 m |
| Bench, orange ball, gold half | -121.4/66.6, -112.4/64.9, -118.2/63.9 | ball r 1.0, half r 1.05 |
| Bauble benches | -97/75.6, -69.6/83.2 | r 1.75, tipped 24° |
| LED curtains | Sawa -38..-31, 1..9; Junior 73..80; Wars -104.5..-99.5 | 0.4-4.6 m up |
| Flat neon firs on Wars | -109.2, -134 | 4.5 m |
| Heart, cane, ring | -141, -151, -162 | 2.4 m on posts |

## 3. Facade: cafés and signs (parodies, warsaw-tone)

Złota 11's row (outline 0), south to north from OSM: STRYCH (a loft restaurant), WEGE FUD (the
vegan bar), AUREOLA TEA (bubble tea), BLISKI ZACHÓD (the Middle-Eastern grill), SŁOICZEK (the
home-cooking restaurant in jars, green neon), PIEROŻKARNIA (pierogi), the KEBAB 24H hatch at the
real kebab bar. KISIEL SUSHI on Kiseki's pavilion (outline 1). Words on fronts no pavilion owns:
PO CZESKU (the Czech pub under the tower), WŁOSKI ZASTÓJ, KAWIARNIA RELAKS (Scena Relax's strip),
KOSMOSIK (the café on Zgoda). A named shop's bays are always lit in its colour, a string of warm
bulbs under the fascia where the photos show one.

## 4. Roof

None of its own: everything stands in the open pasaż; the pavilions' and stores' roofs stay
`wiecha` and `dtc`. The shooting stars hang under the masts' arms, 2.6 to 6.4 m up.

## 5. Masts (all of them, the year round)

The photos' mast close up: a square white pole 0.44 m on a grey concrete foot, a bar at 6.5 m with
two floodlights across the pasaż (lit undersides), a service hatch and a white no-cycling plate.

## 6. Colour and material

Every light is M_LAMP (its colour by day, glowing at night): LED white #dbeeff, warm bulbs
#ffcc73, gold #ffc24d, purple #8f33ff, navy #0d1242, the tunnel's five tube colours; metal
#2f3340, bronze #5e4a2c, dark channels #1f2430 are M_STONE. No new material: the city's building
surface (+0 draw calls); the shop words are the neon MultiMesh's (night only).

## 7. Ground and night

Feet on the paving: the frames' bronze and gold plinths, the tunnel's two grated rails (0.15 m),
the fir's round dark base ringed in red, the bauble benches' dark platforms; every star's power
cable runs down its mast's face to the foot. By night every M_LAMP part glows (the stars, tubes,
curtains, the cafés' bays); by day the same colours read as painted. Always on until the seasons
plan (S0) switches them after 6 January.

## 8. People

Standing (crowds.gd `wiecha`, up to 44): two or three at each decoration taking photos or posing
in it, pairs at the café fronts. Walking (wiecha_life.gd, up to 20 groups): three paths threaded
round the decorations, the stores' side one through the gingerbread man. Both follow
`Crowds.wiecha_level` (a few from 9:00, fullest 15:30-21:00, thinner to 23:30, a third in rain).

## 9. Detail level and budget

L3 for the hero pieces (the stars, the tunnel, the fir), L1 for the curtains and shapes. Triangle
budget 31000 (measured 26,230; `check_mesh_quality.gd`): an exception to the L3 cap, as Jarmark's,
since it is a whole 250 m street of decorations in one site, 22 stars alone about 14,000; +0 draw
calls.

## 10. Parts table

| id | shape | size | position (u, v) | material | feature |
| --- | --- | --- | --- | --- | --- |
| star | 8 kite petals, gold disc, 6 tail tubes, bulbs | head r 1.05 m, 2.6-6.4 m up | every mast, ±1.55 m across | M_LAMP LED white, gold, warm | the shooting stars |
| frame | navy board on two posts, LED words, rainbow tube | 3.4 x 4.45 m | -83, 65.4 | M_LAMP navy, purple; bronze M_STONE | WARSIK SAWKA JUNIOREK |
| tunnel | five neon outlines on dark channels, two rails | 5.5 m tall, 0.7 m apart | -27.5, 68.6 | M_LAMP five tube colours | the gingerbread man |
| tinsel | blue board in a lavender border, bulbs | 2.6 x 3.0 m | 13.6, 66.9 | M_LAMP | the blue frame |
| fir | eight half-fins, yellow and red tubes, film | 5.6 m, r 2.1 m | -127, 68.4 | M_LAMP | the neon fir |
| baubles | opened striped ball, rim, bench | r 1.75 m, tipped 24° | -97/75.6, -69.6/83.2 | M_LAMP purple and gold | bauble benches |
| curtains | glow quad and LED strands | 5-8 m long, 0.1-4.6 m | stores' glass | M_LAMP | LED curtains |
| shapes | tubes on posts | 2.4 m | -141, -151, -162 | M_LAMP, metal | heart, cane, ring |
