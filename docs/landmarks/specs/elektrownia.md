# Elektrownia Powiśle: spec

Site key `elektrownia` in `game/scripts/landmarks.gd` (`_build_elektrownia` and the `_elek_*`
helpers). First written 2026-11-01 from the OpenStreetMap outline, rebuilt 2026-11-09 from F's Mac
photos (`powisle/A01-A13`: the gabled turbine hall, the glass lift, four aluminium stacks), and
rebuilt as the whole complex on 2026-11-13 (F: "in detail like in real life, with the fronts" and
"alive: people, summer bars, small squares") from 34 Mapillary street photos taken round the block
in 2019-2021 (`refs/elektrownia-*/street/`, SOURCES.md each; reference only, never shipped).

All parts sit in the turbine hall's frame: origin (245, -740), u along (0.7885, -0.615) from the
Dobra gable (u = -40.8) to the cross wing (u = 22.3), v across it, + towards Zajęcza.

## 1. Identity
1. **A 1904 brick power station** on Dobra, now shops, a food hall and bars: orange brick, tall
   round-arched windows in cream surrounds, a cream string course and cornice.
2. **The turbine hall's Dobra gable**: big steel-grid windows over lit shop glass, black X braces
   under the eaves, bulbs along the gable's edges (the night photo), the glass lift with the blue box.
3. **Four aluminium stacks**, lit bright blue at night (the night photo).
4. **The passages and yards**: granite and multicoloured setts, festoons of bulbs between the
   halls, beer tables, umbrellas, deck chairs, a summer bar, a painted sphere on the lawn.
5. **The new blocks**: a dark glass office on a black-columned arcade of shops, brick fins.

## 2. Massing
- The T of the mapped outline: brick halls 13 m (two rows of arches).
- The turbine hall over the stem: u -40.8..22.3, v ±15.4, eaves 16 m, ridge 25 m.
- The cross wing (u 22..44, v -41..65) under a zinc gable 13 to 17.6 m with a glass lantern.
- The passage block between the hall and the office (OSM, ~280,-719): brick 11.5 m, glass roof.
- The office, Zajęcza 2B (OSM, ~286,-702): a 4.6 m arcade, four storeys of glass to 18.9 m.
- The old wing, Wybrzeże Kościuszkowskie 43C (OSM, ~292,-781): 6.8 m, its Leszczyńska end a
  9.8 m pavilion. Wybrzeże Kościuszkowskie 43B is left to the city (no photo of it after 2020).

## 3. Facade, base to top
- Halls: plinth 0.6 m; ground arches (half-width 1.65 m, sill 0.4, spring 3.6) as shop windows,
  lit warm at night (M_PAVILION) where the face looks onto a yard, passage or plaza; cream string
  course at 5.0-5.45 m; upper arches (half-width 1.4, 6.4 to 9.6 m spring) dark glass in cream
  surrounds; brick pilasters between the bays every 5.5 m; cream cornice 12.1-13 m.
- Dobra gable: two shop fronts (9.2 m wide, 0.4-4.4 m), two steel-grid windows (6.2-13.4 m,
  bars every 1.15 x 1.2 m), a steel band at 4.9 m, X braces 13.9-15.7 m, a glass canopy.
- Passage block front (u -7.3): two lit shop panes, a steel-grid window, X braces, a steel canopy.
- Office: lit shop glass 1.4 m in from the outline behind black columns every ~6 m; brick fins
  every ~2.8 m up the plaza face and the Zajęcza end; dark blue-grey curtain glass.
- Old wing: arched windows every 3.6 m in pale render surrounds, a pale cornice.

## 4. Roof
Turbine hall: zinc gable with a glazed ridge (lit cool at night). Cross wing: zinc gable with a
glass lantern 94 m long. Halls round the T: flat zinc behind the cornice. Passage block: glass on
steel ribs every 3 m. Office: flat grey with a plant box. Old wing and pavilion: flat zinc.

## 5. Colour and material
| Part | Colour | Material code |
| --- | --- | --- |
| Brick | #a35e42 | M_STONE |
| Cream trim | #d9d0bd | M_STONE |
| Steel | #26292c | M_STONE |
| Zinc | #737a7f | M_STONE |
| Stacks | #c3c7ca | M_LAMP + 0.5 (own colour by day, blue at night) |
| Shop glass | #e9b77a | M_PAVILION (lit warm) |
| Roof glass | #9ab9c6 | M_PAVILION + 0.5 (lit cool) |
| Office glass | #3e4d5a | M_GLASS |
| Brick fins | #9c5238 | M_STONE |
| Bulbs | warm (BARGE_BULB) | M_LAMP |

No new material or draw call: everything is the city's one building surface; the names are
landmark neon words (`neon_signs.gd` LANDMARK_WORDS).

## 6. Ground and night
- The passage between the cross wing and the old wing: pale granite, six beer tables with
  benches, eight zigzag festoons wall to wall at 6.2-6.6 m.
- The yard by Leszczyńska: the summer bar ZWARCIE (a red container with a counter and an
  awning), six umbrella tables, six striped deck chairs, five festoons from the hall to posts.
- The plaza by Dobra: multicoloured setts, four café umbrellas, two benches, two festoons.
- The painted sphere on the lawn by the yard.
- People: `crowds.gd` site `elektrownia_garden` (kind jazz_cafe) seats them at the tables,
  umbrellas and deck chairs (`elektrownia_garden_plan()`, 50 seats, café hours);
  `chill_elektrownia` (34) stands on the plaza's footways.
- Names (parodies, warsaw-tone): ELEKTROWNIA on the gable; HALA TURBIN (food hall) and
  BROWAR KOMIN on the yard; ROSOMAK, KAWA 220V, AMPERIK, FAZA on the plaza; BEZPIECZNIK,
  PIEROGARNIA, ZARAZA on the passage; SPOŻYWCZAK and WATOWNIA on the office.
- The car is stopped by the T, the passage block, the office, the old wing and the lift.

## 7. Detail level and budget
L3, triangle budget 7600 (6843 built). Shots: `--solo=elektrownia --solo-look=lit`, then in the
city day and night (the stacks' blue, the bulbs, the lit shop arches).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| halls | prism round the T outline | 13 m | outline | M_STONE | 2 massing |
| arches | arched panels x 2 rows | 5.5 m pitch | every free face | M_PAVILION / M_GLASS | 3 facade |
| pilasters | thin boxes | 0.7 x 0.22 m | between bays | M_STONE | 3 facade |
| cornice | grown ring + course | 0.9 m, 0.45 m | y 12.1, 5.0 | M_STONE | 3 facade |
| hall | prism + gable | 63 x 31 m, 16/25 m | stem | M_STONE | 1 identity |
| gable_front | panes, steel grid, X braces | 9.2 x 7.2 m windows | u -40.8 | M_GLASS / M_PAVILION | 1 identity |
| lift | glass prism + blue boxes | 3.3 x 3 m, 31 m | Dobra porch | M_GLASS | 1 identity |
| stacks | 4 tubes, flared | r 1.3-2.0, 33 m | hall roof | M_LAMP + 0.5 | 1 identity |
| cross_roof | gable + lantern | 102 x 21 m | cross wing | M_STONE / M_PAVILION | 4 roof |
| atrium | brick prism, glass cap, ribs | 11.5 m | passage block | M_PAVILION | 4 roof |
| office | arcade, glass prism, fins | 18.9 m | Zajęcza 2B | M_GLASS | 5 new blocks |
| wing | brick, arches, pavilion | 6.8 / 9.8 m | WK 43C | M_STONE | 2 massing |
| festoons | wire + bulb cards | 7-26 bulbs | passage, yard, plaza, gable | M_LAMP | 4 life |
| garden | tables, umbrellas, deck chairs, bar | 50 seats | passage, yard, plaza | M_STONE | 4 life |
| sphere | stacked frustums | r 1.3 m | lawn by the yard | M_STONE | 4 life |
