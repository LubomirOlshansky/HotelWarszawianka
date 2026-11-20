# Kładka Abakanowicz (the pedestrian and cycle bridge from Karowa to Port Praski; site `kladka`)

Site key `kladka` in `game/scripts/landmarks/kladka.gd` (found by `_find_kladka` from the
`kladka` stamp that `tools/kladka.py` writes into centrum.json). Written 2026-11-20 from F's 3
photos (dusk from the bank, the render, the deck with its seating) and 31 Mapillary street photos
(refs/kladka/street, reference only, never shipped). Opened 28 March 2024, 452 m, the longest
footbridge in Europe over a river when it opened.

## 1. Identity
1. A **long, low, gently curving grey deck** across the Vistula, no cars, no pylon: the
   silhouette is a thin line on white piers.
2. **Wooden seating bays**: the deck widens into steps of timber seats on one side and an orange
   boardwalk with a long bench on the other, twice along the river span.
3. **Rust-red box girder and railing posts**, dark mesh, light steel handrail with a warm LED
   strip under it that lights the deck at dusk.
4. **A red line across the deck**: the Warsaw meridian (21°E), between the second and third
   supports from Praga.

## 2. Massing
One deck line from the Karowa ramp (west, by Bulwary) to the park by Wybrzeże Szczecińskie (east),
8.9 m wide (6.9 m walk + edges), 4.8 m on the ramp; two lens-shaped bays (100 m and 66 m) widen it
by 1.4-5.0 m on a side. A 2.6 m deep box girder under it, 7 supports on the river span.

## 3. Facade, base to top
Supports: white octagonal columns flaring into a cap under the girder, the two river ones in a ring
of timber piles with lit tops. Girder: rust trapezoid, darker soffit. Fascia: a light 0.55 m band.
Railing: rust posts every 3.2 m, dark mesh 0.1-1.0 m, light steel handrail at 1.15 m, LED strip.
Seats: rows 0.42 m high stepping up outward, a back wall at the top; boardwalk with a long bench.

## 4. Roof
The deck is the roof: grey concrete (#bdb8af), the bays' timber (#7b5132 / #8e6140) and boardwalk
(#b27b47), the meridian strip in red (#c3352b).

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Deck | #bdb8af | M_STONE |
| Girder, posts | #8c4c2f / #6f3c26 | M_STONE |
| Mesh | #5f6264 | M_STONE |
| Handrail | #c9ccce | M_STONE |
| LED strip, pile tops, floodlights | #f3d29a | M_LAMP (glows at night) |
| Fascia | #e7e4dd | M_MEMBRANE+0.5 (floodlit) |
| Seats, boardwalk, bench | #7b5132 / #b27b47 / #6d4a2f | M_STONE |
| Piers | #e7e4dd, piles #4c3d2e | M_STONE |
| Meridian | #c3352b | M_STONE |

No new material, shader instruction or draw call: everything lands in the site's existing
material buckets.

## 6. Ground and night
The deck pieces of `decks` give the walk height (bays included, so people and the player can walk
onto the seating); the bake's road ribbon is hidden and its 12 piers replaced by the 7 supports;
map_builder draws no lamps, rails or road bridge structure there. Guard colliders along the edges
where the drop is over 1 m, prop colliders on the seats, span colliders on the supports. The boat
race passes between the supports. At dusk and night the handrail LED and the pile tops glow.
No traffic: the lane graph has no edges on it.

## 7. Detail level and budget
L3, triangle budget 8000 (measured 5944, `check_mesh_quality.gd`). Shots: turntable
(`tools/turntable.sh kladka`), the city shot from the deck by day and at dusk.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| deck | strips every 6 m | 451 m x 8.9 m | Karowa to Port Praski | M_STONE | grey concrete |
| ramp | strips | 4.8 m wide | west end, down to Bulwary | M_STONE | joins the deck |
| bays | lens strips | 100 m and 66 m long | river span, both sides | M_STONE | seating steps, boardwalk |
| seats | stepped rows + back | 0.42 m rows | bay outer edge | M_STONE | timber |
| bench | long box | along the boardwalk | bay | M_STONE | timber |
| girder | sides + soffit | 2.6 m deep | under the deck | M_STONE | rust |
| fascia | band | 0.55 m | deck edge | M_MEMBRANE+0.5 | floodlit |
| railing | posts, mesh, handrail | 1.15 m | both edges (not at seats) | M_STONE | rust posts every 3.2 m |
| led | strip | 0.08 m | under the handrail | M_LAMP | warm at dusk |
| meridian | strip | 0.5 m | s 373 m | M_STONE | red line |
| supports | octagon + flare | 3.4 x 2.2 m | 7 along the span | M_STONE | white |
| piles | ring of posts | 4.2 x 3.0 m ring | 2 river supports | M_STONE, M_LAMP tops | timber, lit |
