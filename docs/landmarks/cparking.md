# Cyfrowy Parking Novotel (Nowogrodzka 27): log

Site key `cparking` (card "Cyfrowy Parking Novotel"), built by `landmarks.gd` `_find_cparking`, `_build_cparking`,
`_cp_ground`, `_cp_wall_panel`. Outline: the OSM building `parking`, 30.7 m (LoD2's model of it is replaced).

## 2026-11-07: modelled from F's five photos (cloud thread)

- References: F's day photo from the Nowogrodzka/Parkingowa corner, the bar at night (close), and three night photos
  (the wide corner, the long Parkingowa face, the corrugated wall across Nowogrodzka). Plan from centrum.json: an L,
  36 x 44 m on Nowogrodzka and a 14 m wing 87 m long down Parkingowa.
- Massing: ground storey 4.8 m (shop glass 3.3 m, fascia 1.5 m), eight decks at a 3.45 m pitch, each with a 1.75 m
  spandrel (0.65 m under the deck, 1.1 m over it): 4.8 + 0.65 + 7 x 3.45 + 1.1 = 30.7 m, the mapped height.
- Mural: one colour field round the corner (`_cp_mural`): red with darker swirl cells, orange on the lower decks near
  the corner, white roses (two discs), turning green on the upper decks and teal and light blue on the lower ones
  from about 40 m down Parkingowa, the transition falling a deck every 7 m as in the day photo.
- Corner bar: LEJALNIA (Parkingowa) and KLUBOLEJNIA (Nowogrodzka) are parodies of the real names; blue neon tubes, a
  cream pier on the corner and a red-lit one. Entry: dark mouth, pink light, red-and-white barrier, orange post, the
  blue P. Poster boards along the Nowogrodzka foot.
- The next block's blank corrugated wall: a panel on its Nowogrodzka face (LoD2 height 22 m), the red mural head
  rising from the car park side, the wordmark KOLORKI (a parody of the paint brand's) in navy pixels with a rainbow
  swoosh.
- Differs from the photos: the mural is flat colour and white discs (no swirl texture); the far end's blue-grey at
  night and the east and south faces are guessed; shop units and their signs down Parkingowa are generic.

## 2026-11-08: brighter at night (F's ask)

- The spandrels, roses and the corrugated wall use `M_MEMBRANE + 0.5`, a floodlit-paint branch in `building.gdshader` (glow 0.7 of the colour at night, one extra ternary), so the mural reads up the whole facade; the lit core is lighter (#6d7573).
