# Nowy Świat 4A (OSM "Nowy Świat 2.0") and Muzeum Narodowe's roof sign: spec

Site key `ns4a` in `game/scripts/landmarks/srodmiescie.gd` (`_find_ns4a`, `_build_ns4a`); the
museum's sign is `_muzeum_sign` in `game/scripts/landmarks/plac.gd`, its letters
`_serif_word` in `common.gd`. Written 2026-11-26 from F's two night photos from Rondo de Gaulle'a,
Google Street View (2026-08, `tools/streetview_fetch` recipe: Street View Static API) and the
Google 3D Tiles renders (`tools/tiles3d/render.mjs`). References are never committed or shipped.

## Nowy Świat 4A

A 78 m wedge along the lane south of Dom Partii, its west end rounded onto Nowy Świat. Heights
from the mapped parts (min_height 6.6 of the overhang, 16.5-20.8 and 19.8-24.1 parts).

| Piece | Plan | Height | Look |
| --- | --- | --- | --- |
| Lobby | outline 1 m in | 0-6.6 m | glass lit pink-violet at night (M_PAVILION + 0.375), round columns every 9 m |
| Fascia | outline 0.5 m out | 6.6-7.4 m | copper-brown, soffit under it |
| Glass storeys | outline 0.3 m out | 7.4-20.8 m | four storeys of silvery glass (M_GLASS), dark frame band at every floor |
| Fins | 0.42 m out, every 1.6 m | 7.4-20.8 m | light aluminium by day, white glow at night (M_LAMP) |
| Flag band | 0.6 m out | 20.8-22.3 m | red stripe under a white band, terrace on top, glass rail |
| Top storey | outline 1.6 m in | 22.3-24.6 m | darker glass, white parapet |
| Roof | | +3.2 m box, 11 m pole | white plant box near the round end, Polish flag mid-wave (fixed ripple) |

Sign: PGR (parody of PGZ's three letters; "pgz" is on the brand denylist) in navy on the white
band's north face near the round corner, as the photo's sign. The board-game and arcade bar on the
ground floor is PRZEGRYWKI (Zagrywki parody, storefronts.gd venue `bar_przegrywki` at this corner;
F's "zGrywki"). 1,097 triangles, no new draw call.

## Muzeum Narodowe's roof sign

On the west wing's roof over the north end of the front that faces the rondo (the 3D Tiles render
shows the mark there), 1.4 m behind the parapet: a stylised zigzag wave drawn as an outline (not
the real mark) and MUZEUM NARODOWE in built serif capitals, cap height 1.65 m, about 34 m long, on a
dark steel rail and posts. White by day, glowing at night (M_LAMP). About 1,250 triangles.

Open: a Mac/phone look at night (the glow of the fins and letters on the phone), the flag's size.
