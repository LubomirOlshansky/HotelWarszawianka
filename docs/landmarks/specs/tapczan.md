# THE TAPCZAN (site `tapczan`)

F's ask (2026-11-24): put The Taps, the craft-beer pub on Sienkiewicza 4, in the game and in the
bar crawl. Refs: F's two photos of the terrace and front and his Google Maps pin
(`/mnt/project-files/refs/the-taps/`, never shipped); address and "three floors, 16 taps" from
In Your Pocket and Warsaw Insider.

## Identity
Parody name THE TAPCZAN (a tapczan is a sofa bed: the pub you end up sleeping on), in the real
sign's form: a black square with a gold bottle-cap ring, THE / TAPCZAN / CRAFT BEER. The real
name and the cola maker on the umbrellas are in `data/brand_denylist.json`; the umbrellas carry
KOLKA-KOLA (kolka: a stitch in the side).

## Massing
The house is LoD2's and stays (Sienkiewicza 4, OSM outline front from -789.1,-46.2 to -763.1,-56.4).
The site dresses its street level from u 0.4 to 12.8 m along that front and puts the terrace on
the pavement in front of it. Nothing is replaced.

## Facade (street level, 4.3 m)
Cream render, a grey plinth, a ledge on top. West to east: a pier with three rough carved stone
panels stacked; a glazed bay (grey frame, two panes, a transom of two louvred vents); the middle
pier with the sign over a carved stone panel; the open bay (doors folded back on the dark bar);
the east pier with two carved panels.

## Roof
None of its own: the house above the street level is LoD2's (its roof and upper floors stay).
The ledge over the glazing caps the dressing at 4.3-4.5 m.

## Ground and night
The terrace on the pavement, below. At night the bays glow warm (M_PAVILION) and the sign's
words are lit neon; no other lights.

### Terrace
A deck of light pine pallets 12.4 x 4.1 m, 0.16 m high, from 2 m off the wall to the kerb.
Seven slatted folding tables in two rows with a pot of herbs each, four black folding chairs
round each, two black square umbrellas (3.8 m, rim 2.35 m, apex 3 m), a long crate bench with a
black cushion along the kerb at the east end, three crate planters with small trees, an A-board
by the open bay. The deck is solid to the car (`_collide`).

## Colour and material
Cream #e6dccb, ledge #efe7d8, stone #8e8b84 / #6f6c66, frame #5c6166, sign black #18181a, gold
#c9a45a, pine #e2c591 / #b99a66, tables #8a6a48, chairs #202124, umbrellas #1c1d20. The glass is
M_PAVILION (warm from inside at night); the sign's words are neon (`neon_signs.gd` atlas).

## Detail level and budget
L3, 4047 triangles (budget 4700), +0 draw calls (the city's building surface; the neon words are
instances in the Neon MultiMesh).

## Bar crawl
Route `kraftowa` (bar_crawl.gd ROUTES): THE TAPCZAN → KRAFTOWNIA (Nowogrodzka) → MACKI I KUFLE
(Poznańska); the stop ring is on Sienkiewicza at the terrace.

## Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| front | box | 12.4 x 4.3 m | street level, u 0.4-12.8 | M_STONE | cream render, plinth, ledge |
| reliefs | slab + bumps | 1-1.9 x 0.9-1 m | the three piers | M_STONE | carved stone panels |
| bays | frame, glass, vents | 3.5 x 3.95 m | u 1.75-5.25, 7.55-11.05 | M_STONE, M_PAVILION | glazing, open doors, louvred transom |
| sign | box, discs, neon | 1.5 x 1.45 m | middle pier, 2.55 m up | M_STONE, neon | bottle cap, THE TAPCZAN |
| deck | prism + boards | 12.4 x 4.1 x 0.16 m | v 2.0-6.1 | M_STONE | pallets |
| tables | slats, X legs | 0.66 x 0.6 m | two rows, 7 | M_STONE | herb pots |
| chairs | seat, back, bars | 0.4 m | 4 per table, 28 | M_STONE | black, folding |
| umbrellas | pyramid, valance, pole | 3.8 m square | u 3.4, 9.5 | M_STONE | KOLKA-KOLA |
| planters | crate, liner, tree | 0.64 m | ends of the deck, 3 | M_STONE | small trees |
| bench | crate + cushion | 1.9 x 0.55 m | kerb side, east | M_STONE | black cushion |
