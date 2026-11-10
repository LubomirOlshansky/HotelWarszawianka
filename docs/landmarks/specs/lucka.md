# Łucka City (ul. Łucka 15, Wola): spec

Site key `lucka` in `game/scripts/landmarks.gd` (`_find_lucka`, `_build_lucka`, `_lucka_sign`).
Rebuilt 2026-11-06 from F's photos (it stands behind Prosta 32 in all ten: the street views from
Prosta, two aerials from the north-east and the south-east, an older photo from the south), the
OSM outline "Łucka City" and its six parts, and GUGiK LoD2 (2018). It was a TOWERS entry in grey
ribbon glass; it is a white residential block. The printer's roof sign is never written: the
board says INTERBRUK, a parody (paving setts instead of print).

## 1. Identity

1. **White and stepped**: white blocks stepping up from Łucka (37, 54, 74 m) and from Prosta (70,
   87 m) to the 100 m tower.
2. **The dark top**: the tower's top storeys, 83 to 100 m, clad dark grey.
3. **The roof board**: INTERBRUK in white on a blue board across the tower, both faces, between two
   red-and-white lattice masts.
4. **White cladding** with punched windows in bands on the tower and the wings.

## 2. Massing

The six mapped parts at their OSM heights (37.3, 53.8, 73.6, 70.3, 86.8 m), the tower (OSM 103.3 m
with its sign, LoD2 97.6 m) to 100 m.

## 3. Facade, base to top

- Tower: M_SKIN S_PUNCHED #e7e7e3 to 83 m, then #62676b to 100 m (punched windows in bands).
- Wings: M_SKIN S_PUNCHED #e7e7e3 (a first try with balcony bands, S_RIBBON, read blue from the
  game's height, where the photos show white).
- A 1 m parapet on every roof (white on the wings, grey on the tower).

## 4. Roof

Light grey #c4c6c6. On the tower: the board 14 x 0.6 x 3.2 m on two steel legs 1.2 m high,
across the tower's long axis (found from its outline's spread), and the masts 12 m high, 2.5 m
beyond each end of the board, red and white in 3 m bands.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tower | #e7e7e3 | M_SKIN S_PUNCHED |
| Dark top | #62676b | M_SKIN S_PUNCHED |
| Wings | #e7e7e3 | M_SKIN S_PUNCHED |
| Roofs | #c4c6c6 | M_STONE |
| Board | #1d4b96 | M_STONE |
| Masts | #c8312b and #eeeeea | M_STONE |

## 6. Ground and night

What stands round it (the school, the Łucka street front) stays the map's. At night the windows
are the skin's; INTERBRUK is a neon word on both faces. Car walls: every part's mapped outline.

## 7. Detail level and budget

L2, triangle budget 850 (683 measured plus 20 %). Shots: `--at=-2415,305 --yaw=0` and `--yaw=80`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tower | prism of the outline | 0..83 m | OSM part of 103 m | M_SKIN S_PUNCHED | 1 stepped |
| top | prism of the outline | 83..100 m | same | M_SKIN S_PUNCHED | 2 dark top |
| wings | 5 prisms | 37..87 m | the other OSM parts | M_SKIN S_PUNCHED | 1 stepped, 4 cladding |
| board | box on legs | 14 x 0.6 x 3.2 m | tower roof, across | M_STONE | 3 board |
| words | 2 neon words | scale 0.95 | both board faces | neon | 3 board |
| masts | 2 beams in 4 bands | 12 m | board ends + 2.5 m | M_STONE | 3 board |
