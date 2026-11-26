# Warsztat u Mirka (Grzybowska): spec

Site key `warsztat_mirka` in `game/scripts/landmarks/mirek.gd` (`_find_warsztat_mirka`,
`_build_warsztat_mirka`); the game side (the forecourt, the question, the car screen) in
`garage.gd` and `garage_card.gd`. Written 2026-11-24 from F's ask ("a real garage on Grzybowska,
on an empty plot, really cool, like a pimp-my-ride show, supercars and stripped cars beside it,
something meme-y, lit up; drive up, press enter, buy upgrades; always on the map") and F's phone
shots of the old dashed ring on Twarda. An **invented** business on a real street: no photos of a
real building to match, so the reference is the plot itself (OpenStreetMap: grass, a dozen trees,
no building, between Q22 and the slab at Grzybowska 61) and the genre (a tuning workshop of the
2000s TV makeover shows, Warsaw-style). Card: "Warsztat u Mirka".

## 1. Identity

Mirek's tuning workshop: what makes it read from the isometric camera, in order:

1. **The pink neon WARSZTAT U MIRKA** on a black fascia edged in blue LED over three roller doors.
2. **Two open doors, lit inside**, in blue frames: a blue hatchback up on a yellow two-post lift,
   and on the second lift a stripped shell (no wheels, the engine bay open, a rusty door), under
   strip lights; a blue glowing bay with chevrons on the forecourt in front.
3. **The meme on the roof**: a little cream hatchback parked up there, nose to the street, and
   **ZROBI SIĘ!** ("it'll get done!", every Warsaw mechanic's promise) in yellow neon beside it.
4. **The yard**: two lowered supercars (lime and orange) with pink and cyan underglow in painted
   bays, a stripped car on red axle stands (no wheels, no bonnet, a red door on a primer body, its
   engine on a pallet), tyre stacks and oil drums; **CHIP TUNING** in cyan on the west wall, which
   the traffic coming along Grzybowska sees first.
5. **The Bawarka** (F's meme, 2026-11-24: "BMWs that drink oil"): the game's parody of the
   Bavarian saloon, dark blue with its twin grille, bonnet up, standing in a black puddle beside a
   pyramid of yellow oil cans, under a board with **OLEJ DO BAWARKI** (oil for the Bavarian) in
   yellow neon facing the street.
6. **The Porsza 911** (F, 2026-11-24: "put the Porsche outside on the street"): the game's parody of
   a certain rear-engined coupe, red with twin white stripes, frog-eye lamps and a GT wing, rolled
   out of the right open door with its nose to Grzybowska.
7. **Hazard-striped door frames**, a tagged shutter, a chequered parapet, two floodlight masts.

## 2. Massing

The frame (mirek.gd WM_O, WM_A): u along Grzybowska's eastbound carriageway (west to east), v away
from it into the plot; WM_O is the carriageway's middle at about -1731.8, -253.45.

| Thing | u | v | Height |
| --- | --- | --- | --- |
| Site (zone, no trees, no parked cars) | -31 .. 11 | 9.5 .. 36.5 | |
| Forecourt concrete | -30 .. 10 | 9.8 .. 21 | ground + 0.05 |
| Yard concrete | -30 .. -17 | 21 .. 35.5 | ground + 0.05 |
| Hall | -17 .. 5 (22 m) | 21 .. 35 (14 m) | 6.6 m, parapets to 7.2 |
| Doors (shut, open, open) | -14..-9, -7.5..-2.5, -1..4 | front | 4.4 m |
| Lifts | -5, 1.5 | 28 | car at 1.63 m |
| Bawarka (and its board) | -23.5 | 23.8 (board 21.7) | 1.85 m bonnet up (board 3.4) |
| Bay (where Mirek asks) | -9 .. -3 | 10.6 .. 17.4 | painted, lit |
| Supercars | -26.3, -21.4 | 16.0, 17.2 | 1.2 m |
| Stripped car | -24 | 28.5 | 1.55 m |
| Roof car | -11 | 23.3 | on the roof |
| Porsza 911 | 1.6 | 18.2 (heading 15°) | 1.42 m with the wing |

The forecourt's middle (u -6, v 14) is garage.gd's SPOT; the mapped service stub at u 9 is the
driveway; the footway along Grzybowska crosses the forecourt's front at v 8-10.

## 3. Facade, base to top

The front (facing the road): hazard posts (black and yellow 0.4 m blocks) either side of each door
and a yellow lintel band; the left door a grey roller shutter with slats and three sprayed bands
(pink, cyan, yellow); the middle and right doors open in blue LED frames, the rolled shutters'
drums under the lintels. Over them the black fascia
(4.75-6.25 m) with blue LED edges and the pink neon. The sides: graphite cladding with vertical
ribs every 1.4 m; on the west wall a black board edged in cyan with CHIP TUNING. Inside (seen
through the open doors): a pale lining on the back wall, a blue-grey floor, four strip lights, the
two lifts with the blue hatchback and the stripped shell, a red tool chest, an engine on a stand.

## 4. Roof

Flat, dark grey; a black front parapet 0.6 m tall with a white chequer (0.3 m squares, two rows),
low parapets round the rest; two air-conditioning boxes; the cream hatchback and the ZROBI SIĘ!
board on two posts near the front edge.

## 5. Colour and material

Cladding #2a2d34 with ribs #3a3e48; roof #3b3d42; doors #8d929b with slats #6d727b; hazard
#ffc21a and #141417; fascia #12151d; concrete #6a6b6d; inside lining #c5c9cf, floor #7d8794.
Lights (M_LAMP: their colour by day, glowing at night): the garage blue #5aa0ff (the bay, the
open door's frame, the fascia's edges: the same blue as the map's diamond), pink and cyan
underglow, warm white strips and floodlights, head and tail lamps. Everything is the city's
building surface: no new material, +0 draw calls; the three words are the landmark neon
MultiMesh's (neon_signs.gd LANDMARK_WORDS), night only.

## 6. Ground and night

Everything stands on the concrete; the hall's walls go 0.5 m under the ground's mean so a slope
never shows a gap. The trees in the plot are taken out (tree_free), no parked car stands in it
(parked_free). Solid: the hall, the two supercars, the stripped car, the Bawarka and the Porsza (car colliders); the bay
and the forecourt are free to drive. By night the blue bay, the door frame, the fascia edges,
the strip lights inside, the underglow and the floodlights glow, and the three neon words light.

## 7. Detail level and budget

L3: the hall with its doors, the inside, seven modelled cars and the clutter. Triangle budget 3600 (measured 3,367)
(`check_mesh_quality.gd`), +0 draw calls.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | four wall boxes and a lintel | 22 x 14 x 6.6 m | u -17..5, v 21..35 | graphite cladding, ribs | the workshop's mass |
| doors | shutters, frames, hazard posts | 3 x 5 m by 4.4 m | front, u -14..4 | grey slats, hazard, blue LED | shut and tagged, two open and lit |
| fascia | board with LED edges | 20.4 x 1.5 m | front, 4.75-6.25 m | black, blue M_LAMP | WARSZTAT U MIRKA in pink neon |
| inside | lining, floor, strip lights | 14 x 13 m | behind the open door | pale lining, warm M_LAMP | the lit bay |
| lift_car | two-post lift and a hatchback | 3.7 x 1.6 m car | u -5, v 28, 1.63 m up | yellow posts, blue body | the car being tuned |
| lift_shell | two-post lift and a stripped shell | 3.7 x 1.6 m | u 1.5, v 28, 1.63 m up | primer, a rusty door | the car taken apart |
| bawarka | saloon, twin grille, bonnet up, puddle, oil cans, board | 4.7 x 1.8 m | u -23.5, v 23.8 | dark blue, black oil, yellow cans | OLEJ DO BAWARKI meme |
| roof | slab, chequered parapet, AC boxes | 22.4 x 14.4 m | 6.3-7.2 m | dark grey, black and white | the chequer |
| roof_car | hatchback and a neon board | 3.7 x 1.6 m | u -11, v 23.3, on the roof | cream body | ZROBI SIĘ! meme |
| supercars | wedge body, bubble, wing, fat wheels, underglow | 5 x 2 m each | yard bays, u -26.3 and -21.4 | lime and orange, pink and cyan glow | pimp-my-ride |
| wreck | shell on axle stands, engine on a pallet | 4 x 1.7 m | u -24, v 28.5 | primer, a red door, rust | the stripped car |
| clutter | tyre stacks, oil drums | 0.72 m and 0.58 m across | along the west wall and the yard | black, blue and red | a working yard |
| tuning_sign | board with cyan edges | 8 x 2.1 m | west wall, 2.6-4.9 m | black, cyan M_LAMP | CHIP TUNING in cyan neon |
| masts | two floodlight masts | 7.85 m | the hall's front corners | grey, warm M_LAMP | lit forecourt |
| porsza | rounded tub wider at the hips, fastback glass, stripes, frog eyes, GT wing, tail bar | 4.5 x 1.9 m | u 1.6, v 18.2, heading 15° | red #cf2230, white, black | the 911 parody outside |
| bay | painted outline and chevrons | 6 x 6.8 m | u -6, v 14 | garage blue M_LAMP | where Mirek asks |
