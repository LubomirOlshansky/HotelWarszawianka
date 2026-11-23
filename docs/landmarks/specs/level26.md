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

## 3. Parts

| id | part | size | material |
| --- | --- | --- | --- |
| L-1 | timber deck | 0.12 m on the 112 m roof | M_STONE #6f5b4b / #7d6754 |
| L-2 | glass railing on the outer edges | 1.25 m, posts every 2 m, steel top rail | M_STONE #cfe2e6, #c9ccd0 |
| L-3 | foot strip of the railing | 0.14 m, both faces | M_LAMP #ff7a2e |
| L-4 | drum glazing | deck to 1.3 m under the top | M_GLASS #34485f |
| L-5 | drum light band | 0.5 m | M_LAMP #ff4a32 |
| L-6 | white fascia | 1.8 m (covers the drum's parapet), 0.3 m proud | M_STONE #c4c8cb |
| L-7 | mast | 10.4 m, red and white, red tip lamp | M_STONE, M_LAMP |
| L-8 | festoon strings and posts | posts 3 m every 8 m of railing | `_pow_festoon` bulbs |
| L-9 | lanterns | two per string, 0.28 to 0.34 m | M_LAMP #ff9446 |
| L-10 | lounge groups | cube table with a candle, three deck chairs | M_STONE #f3f1ea, frame #b08a5e |
| L-11 | birches | white planter, white trunk, light green crown | M_STONE |
| L-12 | DJ stage | platform, desk with a lit front, truss 4.5 m with five coloured heads, two speakers | M_STONE, M_LAMP |
| L-13 | bar | an arc of six counter pieces along the drum, lit front, lit shelves on the drum | M_STONE, M_LAMP |
| L-14 | name | LEVEL 26 in copper on the fascia, towards the round end and away | landmark neon |

## 4. People

crowds.gd: `level_26_lounge` (kind `view`, the deck chairs, 16:00 to 01:00, fuller on Friday and Saturday and in summer, thin in rain) and `level_26` (kind `roof`, the club's curve 22:00 to 03:00: the DJ, then the dance floor and the bar's drinkers from the plan). The parapet ring and the violet band are not used when the plan is there. The door queue at the ground floor is unchanged.

## 5. Budget

L3, one building mesh, +0 draw calls, no new material. Measured 5753 triangles (budget 6900 in check_mesh_quality).
