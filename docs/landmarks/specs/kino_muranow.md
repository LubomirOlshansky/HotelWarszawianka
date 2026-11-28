# Kino Muranów (Generała Andersa 5)

Site key `kino_muranow` in `game/scripts/landmarks.gd` (`_find_kino_muranow`, `_build_kino_muranow`).
Sources: F's four photos (2026-11-07, thread "Add arthouse cinema tour quest": a summer day with
the fountain in front, a spring day straight on, a summer night with the festoons, an autumn day
from the steps), kept in the project files `kino-muranow/photos/`, and seven Mapillary street
photos of the terrace and the arch (`refs/kino_muranow/street/`, CC BY-SA 4.0, gitignored). The
cinema is the quest stop of "Kino objazdowe" (docs/design/kino-tour.md).

**v2, 2026-11-27 (Gemini pilot, F's go): the whole building.** v1 built only the cinema pavilion,
the terrace and the arch; the two four-storey blocks above stayed the map's plain prisms. v2 builds
the whole complex at Generała Andersa 3-7 as one site: both residential blocks, the arch block
between them, and the full arcaded podium along the square. Read "v2 changes" first; the sections
below are the v1 spec, still right where v2 does not overrule them. Refs (gitignored, never
committed): `refs/kino_muranow/3dtiles/` (Google 3D Tiles, 8 orbit views, 2026-11-27: h270 and
h315 show the square front with the arcades, h045 the back on Nowolipki/Andersa, h135 the roofs),
F's four photos in the project files `kino-muranow/photos/`.

## v2 changes (what the rebuild adds)

Frame as v1 (KM_O, KM_U along the front, KM_V out to the square). From OpenStreetMap: the north
block (index 2014) runs u -78..-0.6, the south block (index 2904) u -0.8..75, both v -39..-26
(12-13 m deep), height 14.2 m over the ground behind. The terrace (the podium's top, KM_H over the
square) is the level of the street behind: the square in front sits a storey lower.

1. **The two blocks** (socialist-realist housing, 1950s): four storeys over the terrace, 3.2 m a
   storey, a 0.5 m plinth band, a crowning cornice 0.6 m proud at 13.4 m over the terrace and a
   0.9 m parapet over it. Walls a warm grey-beige render (#b5a993), window surrounds and cornice
   paler (#d6ccb8). Bays every 3.3 m along both long faces (square side and back): windows 1.4 x 1.7
   m, `kit_window` FRAMED on floors 1-3, SILL on floor 4, a thin sill band under each floor. Small
   iron balconies (`kit_balcony` IRON, 2.4 m wide) on floors 2-4 in every fourth bay, and on all
   four floors in the two bays either side of the arch block (photo 1). The blocks' far ends
   (u -78, u 75) are plain gable walls with one column of windows. A low hipped roof, grey sheet
   (#8a8e92), rise 1.8 m, with a row of small skylight boxes and chimney stacks along the ridge
   every 9 m (3D Tiles h135). The back faces reach down to the ground behind (terrain), with a
   0.9 m rusticated base band.
2. **The arch block**: as v1 (10.4 m wide at u -3, 1.1 m proud of the block front, round arch r 2.6
   m springing 6.2 m over the terrace, six steps a side) but now part of the whole: it rises 1.6 m
   over the blocks' parapet with its own cornice and a plain attic, its faces paler stone
   (KM_STONE), two narrow windows over the arch on floors 3-4, the passage dark through to the back.
   The same arch face on the back.
3. **The podium**: the whole OSM `commercial` outline (index 2018) is built, not only the cinema's
   30 m: the long north and south wings carry an **arcade** on their square faces: round-headed
   dark openings 2.4 m wide, 3.6 m high, every 3.4 m (3D Tiles h270, h315), in the cream wall
   (KM_WALL) with the grey plinth, the white balustrade along the top as v1. The cinema front
   (doors, posters, MURANÓW, KINO) stays exactly as v1 in the middle.
4. **Keep** everything v1 built on the square: the fountain, the café garden, the festoons, the two
   pillars with balls, the terrace paving, the collision of the pavilion and the fountain.
5. **Removal**: the site's zone must cover both blocks (2014, 2904) and the podium, so the map's
   own prisms, the LoD2 runs and street block blk_141043447 there are not drawn under the model
   (check_sites must show no landmark over a street block; DRESSES_BLOCK may drop the entry).
   Collision: the blocks' outlines.
6. **Night**: windows lit through the facade kit's usual pane flicker (no new lights); the
   letters, doors and festoons as v1.

**Detail level L3, budget 11,000 triangles: an exception** to the L3 range, because the site is
now a 150 m long housing complex with two four-storey blocks, not one pavilion (the v1 parts stay
inside their old 6,000). One site mesh, the shared building material: no new draw call,
material or light.

### v2 parts table (added rows; the v1 table below is kept)

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| km_blocks | two prisms of the OSM outlines | 12-13 m deep, to 14.0 m + parapet over the terrace | OSM 2014, 2904 | M_STONE #b5a993 | v2 1 |
| km_windows | kit_window FRAMED / SILL | 1.4 x 1.7 m, bays 3.3 m, 4 floors | both long faces of both blocks | M_STONE #d6ccb8 | v2 1 |
| km_balconies | kit_balcony IRON | 2.4 m wide | every 4th bay, floors 2-4; all floors by the arch | M_STONE #2c2e30 | v2 1 |
| km_cornice | kit_cornice_ring, parapet | 0.6 m proud, parapet 0.9 m | both blocks, 13.4 m over the terrace | M_STONE #d6ccb8 | v2 1 |
| km_roofs | low hip, skylights, chimneys | rise 1.8 m, boxes every 9 m | both blocks | M_STONE #8a8e92 | v2 1 |
| km_arch_v2 | arch block raised, attic, windows | 10.4 m wide, +1.6 m over the parapet | u -3, both faces | M_STONE KM_STONE | v2 2 |
| km_arcade | round-headed dark openings | 2.4 x 3.6 m every 3.4 m | podium wings' square faces | M_STONE #2a2d30 | v2 3 |

## Identity

1. The red MURANÓW letters over the doors, a white KINO at each end of the front.
2. The cream one-storey pavilion with a grey plinth and poster boards under little lamps.
3. The terrace on its roof: a white balustrade and two tall pillars with dark ball finials.
4. The arch through the socialist-realist block behind, over the fountain.
5. The round fountain up three steps, with the green-bronze putti and the wide upper bowl, on
   the square in front, and at night festoons of warm bulbs and paper lanterns over the café garden.

## Massing

- Pavilion: the OpenStreetMap `commercial` outline under the two `apartments` blocks (index 2018
  in centrum.json, 48 corners), merged with a straight 30 m x 14 m front (KM_FRONT, KM_DEEP) along
  the photo's straight facade; 4.8 m over the square (KM_H): the doors 3.0 m, the letters above.
- The blocks above stay the map's (14.2 m OSM / LoD2). The arch block: 10.4 m wide, 1.1 m proud of
  the block's front at v = -27.3 m, from the terrace to 15.4 m over the courtyard behind.
- The arch: radius 2.6 m, springing 6.2 m over the terrace.

## Facade

- Base: a grey plinth 0.9 m (photo 4), cream above it to a 0.35 m cornice slab proud 0.22 m.
- The front (u from the doors' middle along the street): glass doors u -2.4..2.4, 3.0 m, five
  dark frames and two transoms; poster boards u -8.6..-3.1 and 3.1..8.6 at 0.95-3.45 m, two
  parody posters each (shapes only, no real film), a little lamp on an arm over each poster.
- Words: MURANÓW 0.95 m tall in red pixel blocks, 13 m wide, centred at u -0.6 (read left to right along -u), bottom 3.75 m;
  KINO 0.6 m in white at u -11.6 and 11.3.

## Roof

- The flat roof is the terrace (pale paving), the white balustrade 1.05 m along every edge that
  faces the square, with a coping.
- Two pillars at u -8.6 and 2.6 (KM_ARCH_U ± 5.6), v -19.5: a 0.96 m base, a 0.6 m shaft to 4.6 m,
  a cap, a neck and a dark octagonal ball (the Mapillary photos).
- The arch block: two piers, the round arch in six steps a side, a dark passage behind, a cornice
  at the top and a band over the arch.

## Colour and material

Walls #e7dcb6 (photos 2 and 4, calmed), cornice #efe7cc, plinth #8c8b86, terrace #bdb7aa,
balustrade and pillars #ece8dc, arch stone #d2c5a3, letters red (0.86, 0.13, 0.1), KINO
white, door glass #2e3539 in M_PAVILION (warm-lit at night), fountain bronze #6f9a84, water
#58798a. Everything M_STONE but the doors (M_PAVILION) and the letters, bulbs, lanterns and poster
lamps (M_LAMP: their colour by day, lit at night).

## Ground and night

- The fountain at (u -0.3, v 19.2), on OSM's ring `wall` (the basin; map_builder SITE_WALLS keeps
  it from standing as a 1.9 m drum): a round platform running 1.6 m round a 5.0 m stone basin
  with water, up three steps (0.15 m rise, 0.4 m tread) on the half towards the cinema (photo 4)
  and edged by one low kerb on the other half (F's street photo from Andersa, 2026-11-07); a
  pedestal, four putti round a column, the bowl at 4.1-4.3 m over the platform. Trees are kept
  1 m clear of the bottom step. The steps to the square are the map's (OSM `steps`).
- The square towards Andersa (F's street photo and aerial, 2026-11-07): OSM's four benches by the
  metro stair set in one straight row square to the fountain (map_builder BENCH_ROWS) on a paved
  strip; the metro Ratusz Arsenał stair's walls drawn as a granite parapet with a rail
  (map_builder SITE_WALLS, `balustrade_rail`), the straight wall by the steps low (LOW_WALLS),
  and the walls down the terrace stairs at both ends as the terrace's white balustrade
  (`balustrade_white`).
- The café garden by the left posters: five small tables with two folding chairs each.
- Night (photo 3): a festoon along the front's top between five hooks, festoons from it out to
  four posts and between the posts, six paper lanterns under the front festoon.

## Detail level and budget

L3 (the arthouse quest's finale). Budget 6000 triangles (check_sites.gd BUDGET). One site mesh in
the shared building material: no new draw call, material or light.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| km_body | prism of the merged outline | 30 m front, 4.8 m | OSM 2018 + front rect | M_STONE | 2 |
| km_plinth | prism | 0.9 m | the body's foot | M_STONE | 2 |
| km_cornice | offset prism + terrace top | 0.35 m, +0.22 m | the body's top | M_STONE | 3 |
| km_balustrade | boxes along square-facing edges | 1.05 m x 0.26 m | terrace edge | M_STONE | 3 |
| km_doors | glass quad + frames | 4.8 m x 3.0 m | u -2.4..2.4 | M_PAVILION | 2 |
| km_posters | framed quads | 5.5 m x 2.5 m each | u ±3.1..8.6 | M_STONE | 2 |
| km_letters | pixel blocks | 13 m x 0.95 m | u -0.6, 3.75 m up | M_LAMP | 1 |
| km_kino | pixel blocks | 2.4 m x 0.6 m | u -11.6, 11.3 | M_LAMP | 1 |
| km_pillars | base, shaft, cap, ball | 0.6 m x 5.6 m | u -8.6, 2.6, v -19.5 | M_STONE | 3 |
| km_arch | piers, stepped arch, attic | 10.4 m x 15.4 m | u -3, v -27.3 | M_STONE | 4 |
| km_fountain | steps, basin, pedestal, putti, bowl | r 7.4 m, 4.75 m | u -0.3, v 19.2 | M_STONE | 5 |
| km_garden | tables, chairs | 5 tables | u -12.6..-5.2, v 2.6..6 | M_STONE | 5 |
| km_lights | festoons, posts, lanterns | 4 posts 3.6 m | front and v ~8 | M_LAMP | 5 |
