# Stadion Narodowy's grounds: spec

Written 2026-11-15 in a cloud thread. F sent a street-level view from Brama 5 (July 2018) of the
stadium's perimeter and asked for the lower park round the Narodowy and its fences to look real.
Evidence: that photo, and Mapillary frames of the south and west sides (CC BY-SA, reference only,
kept in the gitignored `refs/narodowy_*`, never shipped). The stadium's own model is
`docs/landmarks/specs/stadium.md`.

## What the photos show

- The park is fenced all round by a **tall black vertical-bar steel fence**, about 2.3 m, on
  square posts about every 1.5 m with two rails, and solid dark panels beside the gates.
- **Gates** sit where the footpaths and service roads meet it: stone-grey piers, black leaves,
  and over the leaf a **red board** on two poles ("Do zobaczenia! See you!" and "Brama 5 Gate"),
  with a number on it.
- Beyond the fence a wide asphalt path, plane and lime trees, the grass embankment rising to the
  stadium's feet, tall double-arm street lamps along the roads, galvanised guard rails along the
  carriageways (the generic road guard rails, not this fence).

## What the game draws

| Thing | Where | How |
| --- | --- | --- |
| Perimeter fence | every OSM `fence` line 195-345 m from the stadium centre whose bake type is mesh panel, chain link or plain fence (`city_barriers.gd` `stadium_fence_line`; about 19 lines, 2.5 km) | the palette's `stadium_fence` railing: 2.3 m, near-black, posts every 1.5 m, hard (in `HARD_RAILS`, never smashes) |
| Left alone | the ball-stop nets round the pitches, the railway's chain link (`hz`), any fence with a mapped height or type | their own looks |
| Gates | each footpath or road under 7 m wide crossing the perimeter fence; one per 15 m, at most 14, numbered clockwise from the north | `praga.gd` `_stadium_gates`: two stone piers 2.95 m, two black leaves with a darker solid panel, a red board 5.8 x 0.85 m on two poles with a pale stripe for the writing and a number plate |

The gate board's writing is stripes: at 10-17 cm a pixel it cannot be read, so it is not
drawn as text.

## Left for later

- Light masts and bollards along the asphalt path; the real path's tone (the ground fills are
  one grey).
- Gate numbers as real digits, if a close view ever needs them.
- Hedge rows and the 127 mapped hedge lines inside the grounds were not touched.
