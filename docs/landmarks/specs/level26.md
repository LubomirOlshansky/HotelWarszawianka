# Level 26 (the Atlas Tower's rooftop club): spec

Site key `level26_club` in `game/scripts/landmarks.gd`, built by `_build_level26_club` in `game/scripts/landmarks/srodmiescie.gd`, laid out by `level26_plan` / `level26_layout` (the same plan feeds crowds.gd). Rewritten 2026-11-22 in a cloud thread from F's two official photos of the real club (the parody is LEVEL 26, the real one Level 27, on the 27th floor of the Atlas Tower, Al. Jerozolimskie 123A): L-01 the terrace by day at sunset, L-02 the terrace at night from above; plus the aerial of Plac Zawiszy on Wikimedia Commons (2022) for the tower's top. Reference only, never shipped.

## 1. Identity

1. A round club room on the tower's top (the crown drum the map has, 112 to 116 m) with the terrace wrapped round it on the main roof (L-01, L-02, aerial).
2. The glass railing at the tower's edge with white posts; at night it glows orange from its foot (L-02).
3. Festoon strings from the drum out to posts at the railing; orange paper lanterns hung under them (L-01, L-02).
4. White canvas deck chairs on wooden frames round white cube tables, young birches in white planters (L-01).
5. The DJ on a low stage under an aluminium truss, speakers on stands (L-01).
6. The drum: dark glass, a band that glows red at night, a white fascia, the name on it; the red-and-white mast on its roof (L-02, aerial).

## 2. Massing

From the mapped parts in `centrum.json`: the main roof part at 112 m (traced round the drum and the 116 m east block), the drum 112 to 116 m (about 24 m across), the east block to 116 m. The terrace is the main roof's part within 13.5 m of the drum's wall, on the tower's round end side (`L26_ROUND_END`, cut 0.3 drum radii past its centre): about the real 450 m2. The far half of the roof stays the map's plain roof.

## 3. Facade

The tower's body stays the map's building (its blue glass and white frame are not rebuilt here). The drum's face: dark glass from the deck to 1.3 m under its top, a red light band, then a pale fascia 1.8 m tall standing 0.3 m proud that covers the map's parapet, with LEVEL 26 in copper on it (L-02, aerial).

## 4. Roof

The terrace deck on the 112 m main roof, round-end half only; the drum's roof stays the map's flat roof with a dark coping ring at the fascia's top and the red-and-white mast on it. The rest of the main roof stays the map's plain roof (`_no_roof`).

## 5. Colour and material

Landmark material codes only: M_STONE for timber, white, steel and canvas; M_GLASS for the drum's glazing; M_LAMP for the orange railing strip, the red band, lanterns, the bar and the DJ's lights. Colours: deck #6f5b4b / #7d6754, white #c4c8cb, glow #ff7a2e, red band #ff4a32, lanterns #ff9446, copper name, coping and inner wall #3d4247.

## 6. Ground and night

The club sits on the roof, so its ground is the min ground under the roof part plus the deck (map parts stand on the min ground under their own polygon). At night the railing's foot strip glows orange on both faces, the festoons and lanterns light the deck, the drum's band glows red, the bar and DJ truss are lit; the fascia is dim, not white (L-02).

## 7. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| L-1 | timber deck prism | 0.12 m on the 112 m roof | main roof within 13.5 m of the drum, round-end half | M_STONE #6f5b4b / #7d6754 | the terrace (Identity 1) |
| L-2 | glass railing with posts and top rail | 1.25 m, posts every 2 m | the deck's outer edges | M_STONE #cfe2e6, #c9ccd0 | the edge at the tower's face (Identity 2) |
| L-3 | light strip | 0.14 m, both faces | foot of the railing | M_LAMP #ff7a2e | the orange night glow (Identity 2) |
| L-4 | drum glazing ring | deck to 1.3 m under the top | the crown drum's wall | M_GLASS #34485f | the club room (Identity 6) |
| L-5 | light band ring | 0.5 m | drum, above the glazing | M_LAMP #ff4a32 | the red band at night (Identity 6) |
| L-6 | fascia ring with coping | 1.8 m, 0.3 m proud | drum top, over the map's parapet | M_STONE #c4c8cb, #3d4247 | the white fascia (Identity 6) |
| L-7 | segmented mast | 10.4 m, tip lamp | drum roof | M_STONE, M_LAMP | the red-and-white mast (Identity 6) |
| L-8 | festoon strings and posts | posts 3 m every 8 m | drum fascia to the railing | `_pow_festoon` bulbs | the festoons (Identity 3) |
| L-9 | lanterns | two per string, 0.28 to 0.34 m | under the strings | M_LAMP #ff9446 | orange paper lanterns (Identity 3) |
| L-10 | lounge groups | cube table, candle, three deck chairs | 13 groups on a 3.4 m grid on the deck | M_STONE #f3f1ea, frame #b08a5e | white deck chairs (Identity 4) |
| L-11 | birches in planters | about 3 m | between string posts along the railing | M_STONE | young birches (Identity 4) |
| L-12 | DJ stage with truss | platform, desk, truss 4.5 m, five heads, two speakers | the round end (`L26_ROUND_END`) | M_STONE, M_LAMP | the DJ (Identity 5) |
| L-13 | bar arc | six counter pieces, lit shelves | along the drum on the far side | M_STONE, M_LAMP | the bar (Identity 5) |
| L-14 | name sign | two words on the fascia | towards the round end and away | landmark neon, copper | LEVEL 26 (Identity 6) |

## 8. People

crowds.gd: `level_26_lounge` (kind `view`, the deck chairs, 16:00 to 01:00, fuller on Friday and Saturday and in summer, thin in rain) and `level_26` (kind `roof`, the club's curve 22:00 to 03:00: the DJ, then the dance floor and the bar's drinkers from the plan). The parapet ring and the violet band are not used when the plan is there. The door queue at the ground floor is unchanged.

## 9. Detail level and budget

Detail level L3, one building mesh, +0 draw calls, no new material. Triangle budget 6900 (measured 5753, set in check_mesh_quality).
