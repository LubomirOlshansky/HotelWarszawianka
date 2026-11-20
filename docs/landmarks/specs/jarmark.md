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

## Map (MSN frame: u along Marszałkowska to the south-south-east, v towards the Palace)

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

## Elements

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

## Not done (next)

- The elves' labyrinth and the Christmas-tree carousel's exact place on Plac Centralny are guesses
  (no photo shows them from above).
- No crowds yet; the market reads empty in a still. A crowd zone for the aisles is the next step
  for the trailer.
