# Warsaw Trade Tower (Chłodna 51): spec

Site key `wtt` (a TOWERS entry; the mapped parts by colour through `skins`, the crown's slits and
the mast in `game/scripts/landmarks/skyline.gd`). Written 2026-11-15 in a cloud thread, after F
asked whether the tower was detailed with the right textures, from seven photos (reference only,
never shipped): three Wikimedia Commons photos and the GUGiK ortho in `refs/wtt/` (1 from the
west, 2 the overview from the south-east, 3 from the north beside the Spire) and F's three in
`refs/_f/warsaw-needed-photos/top-50/T05/`. Massing from the 22 OpenStreetMap parts inside the
"Warsaw Trade Tower" outline in `centrum.json`, unchanged.

## 1. Identity

1. A 208 m tower (1999): a drum of dark grey glass, straight on its west side and rounded to the
   east, in strong floor bands of dark glass and light spandrels (photos 1, 2, T05).
2. A beige stone slab with punched windows stands against its east side, stepped at about 94,
   115 and 150 m (2, T05).
3. The crown: a plain silver drum from 162 to 184 m with dark horizontal slits round its curved
   side, a flat screen on the west with the insurer's name, and a tall fin at its north edge (1,
   2).
4. The mast: grey, standing just in front of the west screen from about 137 m to 208 m on
   horizontal arms, red and white at the top (1, 2, 3).
5. At its foot a beige stone block, the round grey glass lobby and the glass atrium (2, ortho).

## 2. Massing (the mapped parts)

22 parts, unchanged: the glass drum (0 to 162 m, 58 corners) and its ring to 171 m; the stone
slab strips (to 94, 115 and 150 m) and the 34 m stone block; the crown (162 to 184 m, 61 corners)
and the fin (148 to 184 m); six thin arms (1 m each, 145 to 182 m) along the west face; the mast
(1.4 m, 137 to 208 m); the 17 m lobby and the 30 m atrium.

## 3. Facade, base to top

- **Glass drum** (mapped #2e404e): the kit's ribbon skin (S_RIBBON, light bands at every 3.2 m
  floor) in dark grey glass #36434e.
- **Stone** (mapped #f4d9c6): the kit's punched skin (S_PUNCHED) in warm beige #d8c1a5.
- **Crown** (mapped #839099, from 162 m): plain silver tiles (S_TILE, neutral #c5c6c5), 6 cm proud
  (crown_from). Four dark slits (#3a4248), 0.6 m tall at 170.5, 173.5, 176.5 and 179.5 m, 14 cm
  proud of the cladding, round every edge except the flat west screen.
- **Name**: the parody UNIKWA on the crown's highest part, lit white.
- **Lobby and arms** (mapped #a6abaa): the kit's banded skin (S_BANDS) in grey #9aa3a8.

## 4. Roof

Flat, #8d979c (mapped). The mast (1.2 m square, grey #8e959b steel from its mapped foot at 137 m, the top
14 m in red #c8322b and white #e8e8e4 bands every 3.5 m) carries the red lamp at 208 m.

## 5. Colour and material

Glass #36434e (S_RIBBON skin); stone #d8c1a5 (S_PUNCHED skin); crown #c5c6c5 (S_TILE skin);
lobby and arms #9aa3a8 (S_BANDS skin); slits #3a4248 and the mast's steel, red and white (building
material); lamp DUSK_RED (M_LAMP); the name white. No new material.

## 6. Ground and night

Chłodna, the tram tracks and the forecourt are the map's. Car collision on the parts that stand
on the ground. Night: the drum's floors and the stone's windows lit, the crown floodlit (S_TILE),
the name lit, the mast's red lamp and the aviation lights.

## 7. Detail level and budget

L2 (the third-tallest tower in the map, seen from Rondo ONZ, Wola and the Palace's terrace).
1604 triangles, budget 1900 (check_mesh_quality BUDGET "wtt"); 0 z-fights; no new draw call, no
shader change (building.gdshader stays 501 of 505).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| drum | prisms | mapped, 0 to 171 m | the mapped glass parts | S_RIBBON #36434e | 1 banded glass drum |
| slab | prisms | mapped, to 94, 115 and 150 m | the east strips | S_PUNCHED #d8c1a5 | 2 stone slab |
| crown | prism | mapped + 6 cm, 162 to 184 m | the crown part | S_TILE #c5c6c5 | 3 silver crown |
| slits | walls | 0.6 m tall, 14 cm proud | 170.5 to 180.1 m, the curved side | #3a4248 | 3 slits |
| fin | prism | mapped (3.2 by 0.9 m) | 148 to 184 m, north edge | steel #839099 | 3 fin |
| name | dusk sign | the crown's height | the crown | white | 3 name |
| arms | prisms | mapped, 1 m | 145 to 182 m, west face | S_BANDS #9aa3a8 | 4 arms |
| mast | prisms | 1.2 m square | 137 to 194 m | #8e959b | 4 mast |
| mast top | prisms | 0.9 m square, 3.5 m bands | 194 to 208 m | #c8322b / #e8e8e4 | 4 red and white |
| lamp | box | 0.4 m | 208 m | DUSK_RED (M_LAMP) | 4 mast |
| foot | prisms | mapped, 17 to 34 m | the lobby, atrium and stone block | S_BANDS, S_RIBBON, S_PUNCHED | 5 foot |

## 9. Not built, and what only the phone can show

- The stone slab's tall narrow windows (the kit's punched windows are wider); the atrium's glass
  pyramid; the fin's lattice.
- Phone: the drum's floor bands and the crown's slits at the game's zoom; the name at night.
