# Biblioteka Uniwersytecka (BUW): spec

Site key `buw` in `game/scripts/landmarks.gd` (`_find_buw`, `_build_buw`, `_buw_front`,
`_buw_roof`). Written 2026-10-31 in a cloud thread from OpenStreetMap alone: the library's
outline (101 points, its Dobra front traced panel by panel), its eleven building parts with
heights, and the roof garden, which OpenStreetMap maps as 60 park and lawn areas inside the
outline, with the bare roof between them (the glass roofs). Until now the library was a skin:
LoD2's massing in one green. There is no usable free photo (`refs/` holds interiors only), and
the cloud reaches neither Commons nor GUGiK: the values marked *(photo check)* wait for the
Mac (or the user's own photo). **Pass 2, 2026-11-01**: the roof redone from GUGiK's
orthophoto (fetched on the Mac, georeferenced on the game grid in the cloud): the OSM band
between the lawns is the glass field, OSM's 6 m part is the glass pyramid on the mound, its
14 m strip the glass strip on the north-west edge. **Pass 3, 2026-11-01** (the Mac's GUGiK
LoD2 check): the deck at 15 m (64 % of the roof), the glass ridges about 17 m; LoD2's lower
10 m part is the court in the south notch, Collegium Iuridicum II's roof, now part of the
site; the four mapped round parts on the north-east band are the ventilators.
**Pass 4, 2026-11-13** (F's twenty photos, street level, Street View and the air): the
copper screen is a frieze from 10.8 m to over the roof with BIBLIOTEKA UNIWERSYTECKA across its
top and twelve narrower pages under it, a pair of round copper columns in each gap; the band is
a curved green glass vault with dark ribs; the other fronts are off-white concrete with three
storeys of teal windows behind the trellis and ivy; the tall blue glass hall past the copper's
south end; the magenta steel lattice tower (OSM's 15 pink parts) by Lipowa; the round "vents"
are concrete drums to 3 m over the roof with slit tops (four more outside the north front),
the one by the round east corner a lookout with people; the oculus is a ribbed silver-green
glass dome; railings on the walkways, benches, more flower colours; Collegium Iuridicum IV
(Wybrzeże Kościuszkowskie 47) is the grey villa with white stone trim and the glass spire,
built in the same site; a cascade, a pool, three steel trees and beds in the lower garden;
the roof's mapped footways carry walkers 15 m up.

## 1. Identity

Marek Budzyński's and Zbigniew Badowski's library (1999) on Dobra in Powiśle, by the
boulevards. What makes a passer-by say its name:

1. **The copper pages on Dobra**: the front is a row of tall green-patina copper plates
   standing before the glass, covered in lines of old text (Greek, Hebrew, Arabic, Sanskrit,
   old Polish, music, mathematics).
2. **The four philosophers**: four slim columns before the entrance, a statue on each
   (Twardowski, Łukasiewicz, Tarski, Leśniewski) *(photo check: which front they stand at;
   built on Dobra, before the copper pages)*.
3. **The roof garden** (2002): lawns and beds in the mapped shapes over the whole roof, paths
   between them, 15 m up; what the helicopter and the cassette land on.
4. **The glass roofs in the garden**: the flat glass field over the central hall (a fine
   grid, a dark walkway across it) with its tail sweeping along the Dobra side to the south
   corner, a second flat glass roof, the round oculus in a paved ring.
5. **The green band**: a sloped patina-green glass and copper band 6 m wide all round the
   roof's edge, over glass fronts.
6. **The garden's parts**: formal square beds with yellow and orange flowers round a plaza in
   the north, a dark green hill with a small teal glass pyramid in the middle, winding paths
   through shrubs, heather and lawn, white pavilions and small white domes in the south; the
   lower green court with its skylight in the south notch.

## 2. Massing

Plan frame for the front: origin (-15.1, -965.9), the outline's west corner; u along Dobra,
axis (0.667, 0.745), to the south-east; +v out of the front (south-west). Heights above the
site's ground (the lowest terrain under the outline).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Block | the outline, straightened to 0.8 m (about 180 x 130 m, 11,000 m²) | 0 to 15 m | GUGiK LoD2 (the Mac, pass 3): the deck ~15 m over the 84.4 m base |
| Copper screen | 12 plates, u 1.5 to 72.5, 5 m wide, 1 m apart, v 0.2 to 0.6 | 0 to 17.6 m | the outline's zigzag on Dobra (plates every ~6 m) |
| Glass field | 51 x 23 m field, corners (33.6,-958.7) (81,-977.6) (88.8,-955.5) (39.6,-935.5), and its tail from (7,-980) along the Dobra side to (45,-914) (`BUW_FIELD`) | 15 to 16.6 m | the orthophoto (the field is OSM's bare band), LoD2 |
| Second glass roof | 18 x 27 m, the mapped part's hull | 15 to 16.2 m | the mapped part, the orthophoto |
| Oculus, hump | r 8.2 m at (124.3,-947.1) in a 4 m ring path; r 4.1 m at (92.7,-970.4) | 15 to 16.6 and 17.6 m | the mapped round parts, the orthophoto |
| Hill, pyramid | 22 x 34 m ellipse at (99.8,-953), long side across the field's axis; the pyramid on OSM's 6 m part | 15 to 18 m, pyramid to 20 m | the orthophoto, mapped part, the Mac's check |
| NW glass strip | the mapped 4.5 x 34 m part at (78,-998) | 15 to 17.2 m | mapped part, the orthophoto |
| Stair house | the mapped pentagon at (12,-958) | 15 to 18.1 m | mapped part, white in the orthophoto |
| Band | 6 m wide round the straightened outline, 3 m over the notch | 12.5 to 15.6 m | the orthophoto |
| Court | Collegium Iuridicum II's outline in the south notch | 0 to 10 m | LoD2's lower part (6.5 % of the roof) |

## 3. Facade, base to top

- **Dobra (u 0-75)**: the glass wall behind; before it the 12 copper plates from the pavement
  to 17.6 m (2.6 m over the roof). Plates 6 and 7 (u 31.5-42.5) start at 4.5 m: the entrance
  under them, dark glass doors. On each plate's face, lines of text: dark copper strokes 0.25 m
  tall every 0.9 m from 2 m to 16.8 m, each line a different length (a page, not a grid).
- **The other fronts**: glass (M_GLASS: mullions every 1.5 m, a floor every 4 m, lit
  windows at night) in a green tint up to 12.5 m, a patina-green trellis post every 6 m 0.35 m
  out, to 12.8 m.
- **Top**: the band, sloping in and up from the walls' top (12.5 m) to 0.6 m over the roof;
  over the notch narrower (3 m) and greener, heather between it and the deck.

## 4. Roof

From the orthophoto. The deck at 15 m in pale paving (the paths), inside the band. On it:

- **The glass field**: `BUW_FIELD`, nearly flat glass (M_GLASS_ROOF's fine grid) at 16.6 m on
  a 1.6 m copper curb; the walkways (`BUW_WALKS`) dark 2 m slabs over it: the long one from the
  field's west corner (33.6,-958.7) across to the pavilions by the tail (42.4,-933.5), a short
  one over the tail by the stair house.
- **The second glass roof**: the mapped part's hull, flat glass at 16.2 m on a curb.
- **The formal garden** (north-west of the field, along it, to the band): 5 m square beds on a
  6.6 m grid in the field's frame, about one in three yellow or orange flowers, the rest lawn;
  a paved round plaza (r 4.5 m) at (54.5,-989) with a ring of yellow in the middle.
- **The hill** (`BUW_MOUND`): a 22 x 34 m ellipse at (99.8,-953) between the field and the
  oculus, two dark green frustums (#456f3a) to 18 m with a flat top, the small teal glass
  pyramid (OSM's 6 m part) on it to 20 m.
- **The oculus**: r 8.2 m, a 0.6 m curb, a low glass cone to 16.6 m round a dark middle
  (r 2.9 m), a paved ring path 4 m wide round it. **The hump**: r 4.1 m, a planted cone
  with a small glass cone in its middle.
- **The south garden**: four 2.5 m paths (`BUW_PATHS`, the deck showing between the beds):
  the main one from the oculus's ring west along the notch to the south-west corner, a loop
  round the notch's corner, one up to the field's east corner, one round the pavilions. The
  beds they split south of the field are dark shrub, purple-brown heather or lawn.
- **The rest of the garden**: every mapped park and lawn area inside the band over 6 m²,
  kept off all of the above, as beds 0.12 m over the deck; five white pavilions
  (`BUW_PAVILIONS`, rectangles 2.6 m tall, three by the glass tail, one each side of the
  hill); four small white domes on brown rings along the south lawn.
- **The NW glass strip** (OSM's 14 m part): a 0.8 m curb and a glass ridge to 17.2 m. **The
  stair house** by Dobra: white, to 18.1 m. **The ventilators**: the four mapped round parts
  on the north-east band, copper drums (r ~1.6 m) with dark tops to 1.4 m over the deck.
- **The court** (Collegium Iuridicum II, the south notch): glass walls to 10 m, a green roof
  with a paved path and a small glass pyramid skylight at its west end; it collides along its
  outline (`tools/check_roads.py` mirrors it).

The cassette (`cassettes.json` `c01_buw`) lies on the roof's highest flat spot
(`missions.roof_spot`: a 4 m cell whose neighbours are within a metre). The flat glass (the
field, the second roof, the oculus) stays out of the roof grid (`_no_roof`), the rest slopes or
is too small, so the spot is in the garden (checked with PR #115's code after pass 3:
(99, -958), on the hill by the pyramid, 18 m).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Glass walls | #7a978c | M_GLASS |
| Copper plates | #6f9c86, plates vary ±4 % | M_STONE |
| Text strokes | #3e6252 | M_STONE |
| Trellis, curbs, ventilators | #557f6b | M_STONE |
| Band | #5e8a77, over the notch #4f9068 | M_GLASS_ROOF |
| Flowers | #d9c23e, #d9873a | M_STONE |
| Plaza and ring path | #c9c4b4 | M_STONE |
| Walkway, oculus middle | #2f3a38 | M_STONE |
| Pavilions, stair house | #e2e0d6 | M_STONE |
| Deck (paths) | #a9a799 | M_STONE |
| Beds | park #5f8f4a, lawn #78a85a; south: shrub #3f5e36, heather #7b5d6a | M_STONE |
| Hill | #456f3a | M_STONE |
| Dome rings | #7a5a44 | M_STONE |
| Glass roofs | #9cbdb6 | M_GLASS_ROOF |
| Doors | #34423f | M_GLASS |
| Columns | #cfc9b8 | M_STONE |
| Statues | #4a4239 | M_STONE |

Calmer than life; the old skin's green (#7f9e8a) moves to the copper. No new material, no
draw call of its own.

## 6. Ground and night

The pavement on Dobra and the lower garden round the building stay the map's. The car
collides with the outline, the copper plates and the four columns (`tools/check_roads.py`
mirrors the outline). At night the glass walls light floor by floor, the glass roofs glow
from the halls under them, the copper stays dark. Card: "Biblioteka Uniwersytecka", PL
"Otwarta w 1999 roku. Miedziane strony z tekstami, ogród na dachu.", EN "Opened in 1999.
Copper pages of text out front, a garden on the roof."

## 7. Detail level and budget

L2 (a named landmark on the boulevards; the roof garden is a beat of the first ten minutes),
triangle budget 2900 (2431 measured after pass 3, plus about 20 %, in
`check_mesh_quality.gd` BUDGET; the beds and the text strokes are most of it). Shots:
`--solo=buw --solo-look=sil` and `flat` (the `first` set), the roof from the helicopter by
day with the cassette, and Dobra at night.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | outline prism | 180 x 130 m, 0-12.5 m | the outline | M_GLASS #7a978c | 5 green on glass |
| plates | 12 boxes | 5 x 0.4 m, 0-17.6 m | Dobra, u 1.5-72.5 | M_STONE #6f9c86 | 1 copper pages |
| text | quads | 0.25 m lines every 0.9 m | the plates' faces | M_STONE #3e6252 | 1 copper pages |
| doors | wall | 11 x 4 m | Dobra, u 31.5-42.5 | M_GLASS #34423f | 1 copper pages |
| columns | 4 columns + statues | r 0.35 m, 9 m + 2.2 m | Dobra, v 4, u 31-43 | M_STONE #cfc9b8, #4a4239 | 2 philosophers |
| trellis | posts | 0.3 m, every 6 m, to 8.7 m | the other fronts | M_STONE #557f6b | 5 green band |
| band | mitred quads | 6 m wide (3 m over the notch), 12.5-15.6 m | the roof's edge | M_GLASS_ROOF #5e8a77, #4f9068 | 5 green band |
| deck | cap | inside the band | 15 m | M_STONE #a9a799 | 3 roof garden |
| beds | mapped caps | 0.12 m over the deck | the mapped lawns | M_STONE #5f8f4a / #78a85a | 3 roof garden |
| formal | square caps on a grid, plaza | 5 m beds, 6.6 m grid | north-west of the field | M_STONE lawn, #d9c23e, #d9873a | 6 garden parts |
| hill | 2 elliptic frustums + teal pyramid | 22 x 34 m, to 20 m | (99.8,-953) | M_STONE #456f3a, M_GLASS_ROOF | 6 garden parts |
| field | curb + flat glass + walkways | 51 x 23 m + tail, 16.6 m | `BUW_FIELD` | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| light_roof | curb + flat glass | 18 x 27 m, 16.2 m | the mapped part | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| oculus | ring path, curb, glass cone, dark middle | r 8.2 m | (124.3,-947.1) | M_GLASS_ROOF, #c9c4b4, #2f3a38 | 4 glass roofs |
| hump | planted cone + glass cone | r 6 m | (92.7,-970.4) | M_STONE, M_GLASS_ROOF | 6 garden parts |
| strip | curb + glass ridge | 4.5 x 34 m, to 17.2 m | the NW edge | M_GLASS_ROOF #9cbdb6 | 4 glass roofs |
| pavilions | 5 boxes + stair house | 4 x 6 m, 2.6 m | the south half; by Dobra | M_STONE #e2e0d6 | 6 garden parts |
| domes | 4 rings + white domes | r 2.4 m | the south lawn | M_STONE #7a5a44, #e2e0d6 | 6 garden parts |
| paths | the deck between the south beds | 2.5 m | `BUW_PATHS` | M_STONE #a9a799 | 6 garden parts |
| vents | 4 drums | r ~1.6 m | the NE band (mapped) | M_STONE #557f6b | 5 green band |
| court | prism + green cap + skylight | Collegium Iuridicum II, 10 m | the south notch | M_GLASS, M_STONE #5f8f4a, M_GLASS_ROOF | 6 garden parts |
