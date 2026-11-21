# Jarmark Warszawski 2026 (the Christmas market at the Palace)

Site key `jarmark`, code `game/scripts/landmarks/jarmark.gd`. Asked by F on 2026-11-20 ("make the
map of the market, analyse which elements it has, model each, adjust the area if needed, make it
10 over 10 like for the best trailer", by day and at night). Refs (never shipped, never committed):
`/mnt/project-files/refs/jarmark-2026/` (README there): the organiser's drone reel `Df-KsNxOD-L`
(frames 004 and 008 give the layout), the Palace's reel of the tower carousel `Df9vIk0tGEm`, the
78 opening-day photos from naszemiasto.pl, the PIK article.

The real market: 2nd edition, 20.11.2026 to 6.01.2027, daily 11-22, free; over 200 exhibitors;
Plac Defilad plus part of Plac Centralny; new this year the viewing tower with a chair carousel
(it replaces 2025's Ferris wheel).

## Identity

The second Jarmark Warszawski (20.11.2026 to 6.01.2027, daily 11-22): over 200 white, half-timbered
and red chalets back to back on the Plac Defilad car park under the Palace's east front, the 15 m
LED tree, the Venetian carousel, and on Plac Centralny the new 38 m viewing tower with a chair
carousel. Read from the air (the trailer's drone view) it is a grid of white gables threaded with
warm bulb strings; at night it is the brightest place in the centre.

### Map (MSN frame: u along Marszałkowska to the south-south-east, v towards the Palace)

| Part | Where (u, v) | What |
| --- | --- | --- |
| Main market | u 115-198, v -15..76, on the Defilad car park | rows of chalets back to back (v -11, 22/25.6, 40/43.6, 56/59.6, 72), the yellow-roofed food stalls down the middle (v 33), cross aisles at u 144 and 169.5, zig-zag bulb strings over every aisle |
| Tree plaza | centre (135, 5) | the 15 m LED tree on a 7.5 m round platform with a red rail, yellow benches round it, the snowman, the Santa-hat photo spot, the gold sign |
| Rides and stands | (170, 6), (186.5, 6), (199.5, 10-29), (128, 24) | the Venetian carousel with light strings fanning from its top, the red KIEŁBASKI stand, the glass greenhouse tunnel, the red hexagonal two-storey bar |
| Palace side | (155, 74), (178, 74) | the stage (SCENA), the red GRZANIEC bar |
| Annex | u 40-115, v -15..31 | the rows F photographed going up on 2026-11-15, now finished; the WESOŁYCH ŚWIĄT sign at the Marszałkowska gate, light-up trees, a big star |
| Plac Centralny | (56, 70), (79, 70), (79, 48), (56, 47) | the viewing tower carousel, the teacups, the Christmas-tree carousel, Santa's log cabin |
| Street edge | v -17.5 | the low black fence with white JARMARK WARSZAWSKI banners, open at the gates and round the metro pavilion |

The metro pavilions at u 131-148 and 163-167 by Marszałkowska stay; the Marszałkowska row skips them.

## Massing

Low and wide: chalets 3 by 2.4 m (the big ones 5 by 3 m), 3.0-3.6 m to the ridge, in rows of 10 to
30 back to back, aisles 6-8 m wide. Three tall marks rise out of it: the tree (15 m), the
carousel's canopy (7 m) and the tower carousel (38 m mast, the chair ring at 26 m).

## Facade

Every chalet's long side is a counter: a lit opening 0.9-2.0 m up, the goods on a shelf, a fir
garland with red bows over four in five, a bulb string under the eave on two in three. Kinds
below. Signs are pixel-block words so they read by day (the neon signs only show at night).

- **Chalets** (five kinds): white with black corner posts, plinth and eave; white half-timbered
  (black cross braces under the counter and on the ends); red with white trim; the small dark
  food stall with a yellow roof; the big white chalet. All: gable roof over the counter, the
  counter lit from inside (M_LAMP warm: goods by day, glow at night), goods on the shelf, a fir
  garland with red bows on four in five, a bulb string under the eave on two in three. One in
  four white chalets has a light roof (the drone frames).
- **Tree**: eight fir tiers, big red, gold and white baubles, LED strands round each tier and down
  the cone (M_LAMP + 0.5: green by day, blue at night, as the reels), white bulbs on the rims, a
  gold star seen from both axes.
- **Viewing tower carousel**: 38 m mast in seven rainbow LED bands, orange crown, the gold carrier
  at 26 m with sixteen lit white spokes, chairs swung out on chains at 10 m radius, a lit base
  ring and a red ticket chalet.
- **Venetian carousel**: red plinth, gold posts, twelve white horses on gold poles, the lit
  mirrored drum, a cream-and-red striped canopy with a lit valance and a gold finial, strings
  fanning to poles 15 m round.
- **Signs**: WESOŁYCH ŚWIĄT in gold pixel blocks on an arched gold frame with blue stars (lit at
  night, gold by day); the banners; KIEŁBASKI, GRZANIEC, SCENA, DOM MIKOŁAJA. Sponsor stands of
  the photos (lottery, radio, sausage brands) are not modelled; the words are generic.
- **Ground**: dark asphalt draped over the car park and the annex's east end, the old white bay
  lines faint across it; the parked cars of the rest of the year are cleared (`parked_free`, both
  city paths), and the trees in the rides' way (`tree_free`).

## Roof

Gable roofs over the counter side, dark grey (one in four white chalets light, as the drone
frames show), the food stalls' roofs yellow; the carousel's cream-and-red striped cone with a
gold finial; the hexagonal bar's red hip roof; the stage's flat black roof with the SCENA board.

## Colour and material

White walls JM_WHITE with black trim JM_TRIM, red JM_RED, the yellow food roofs JM_YELLOW, fir
JM_FIR, gold JM_GOLD, asphalt JM_ASPHALT. Counters, bulbs, LED trees and signs are M_LAMP (their
colour by day, glow at night); the big tree is M_LAMP + 0.5 (green by day, blue at night, as the
reels); the greenhouse is M_PAVILION + 0.75 (warm-lit glass). All one mesh, one material set.

## Ground and night

Dark asphalt draped over the car park and the annex's east end, 0.28 m up so no lawn shows
through, the old bay lines faint across it; the year-round parked cars cleared (`parked_free`,
both city paths) and trees in the rides' way removed (`tree_free`). At night every counter, bulb
string, the tree, the tower bands and the carousel glow; the market is open 11-22, so the crowd
is there until 22:00 and gone by the night look's 23:00.

## Detail level and budget

L3, budget 76000 triangles (69,003 built; the rides' turning parts, 3,680, are jarmark_rides.gd). This is an exception to the L3 cap of 8000: the site
is a whole 160 by 90 m market plus Plac Centralny, over 200 stalls and their light strings, built
as one mesh (+0 draw calls over the old site). F asked for it at trailer quality (2026-11-20).

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hut | box body, gable roof, lit counter | 3 x 2.4 x 3.3 m | rows in JM_ROWS | JM_WHITE, JM_TRIM, M_LAMP | the white chalet rows |
| food | box, yellow gable | 3 x 2.4 x 3.0 m | v 33 and the annex v -3 | JM_TRIM, JM_YELLOW, M_LAMP | the food stalls down the middle |
| tree | eight stacked cones on a round platform | 15 m tall, 7.5 m platform | (135, 5) | M_LAMP + 0.5, JM_RED rail | the big LED tree |
| carousel | plinth, poles, horses, striped cone | 12 m wide, 7 m tall | (170, 6) | JM_RED, JM_GOLD, JM_WHITE, M_LAMP | the Venetian carousel |
| tower | banded mast, carrier, chairs on chains | 38 m, ring r 10 m | (56, 70) | JM_RAINBOW in M_LAMP, JM_GOLD | the viewing tower carousel |
| teacups | round deck, six cups | 10 m wide | (79, 70) | JM_RED, JM_WHITE, M_LAMP | the teacups ride |
| santa | log cabin, DOM MIKOŁAJA sign | 6 x 4 m | (56, 47) | JM_TIMBER, M_LAMP | Santa's cabin |
| hexbar | hexagonal two-storey bar, star | 8 m wide, 8 m tall | (128, 24) | JM_RED, M_LAMP | the red hexagonal bar |
| stage | box, SCENA board | 12 x 6 x 5 m | (155, 74) | JM_TRIM, M_LAMP | the stage by the Palace |
| strings | wire with bulb prisms every 1.25 m | 6-30 m spans | over every aisle | JM_WIRE, M_LAMP JM_BULB | the zig-zag bulb strings |
| greeting | gold pixel words on an arched frame | 10.4 m wide | the Marszałkowska gate | JM_GOLD in M_LAMP, JM_BLUE | WESOŁYCH ŚWIĄT |
| fence | thin mesh panels, rails, banners | 1.2 m tall | v -17.5 | JM_TRIM, JM_WHITE | the JARMARK WARSZAWSKI street edge |
| drape | asphalt cells | 4 m cells, +0.28 m | JM_PAVED | JM_ASPHALT | the car park ground |

## Not done (next)

- The elves' labyrinth and the Christmas-tree carousel's exact place on Plac Centralny are guesses
  (no photo shows them from above).
- Moving parts: `jarmark_rides.gd` (a place, one mesh in `shaders/jarmark_rides.gdshader`): the tower's
  carrier turns and runs down to load on a 150 s cycle, the carousel turns with bobbing horses, the
  teacups and the tree carousel turn; riders on all. The turntable shows the static market only.
- People: crowds.gd `jarmark` sites (up to 360 + 150 standing at counters, round the tree, in the
  queues, in pairs at the aisles' sides) and `jarmark_life.gd` (up to 41 strollers in the aisles).
- Not done: market sounds (carousel music, the murmur).
