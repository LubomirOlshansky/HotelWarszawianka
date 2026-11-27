# Ufficio Primo (Wspólna 62): spec

Site key `ufficio_primo` (new 2026-11-26; `_find_ufficio_primo` and `_build_ufficio_primo` in
`game/scripts/landmarks/srodmiescie.gd`). The pilot of the new reference sources (F, 2026-11-26):
written in a cloud thread from twelve Google Street View Static images taken round the block
(`refs/ufficio_primo/streetview/`, panoramas of 2021-08, 2022-06 and 2026-06; one west panorama
was a user photosphere in the church garden and showed nothing), Google Photorealistic 3D Tiles
renders (`refs/ufficio_primo/3dtiles/`, six orbit views and the top) and the facts on the
English Wikipedia and the owner's site. Reference only, never shipped or committed. The
orthophoto (GUGiK WMS) is blocked from the cloud; the 3D Tiles top view stands in for it.

The building: the former Presidium of the Government office, Marek Leykam, 1952; renovated
2010-12 as offices. A stone cube with the same front on all four sides, Florentine palazzo
manner: rusticated stone all over, paired narrow windows, a deep classical cornice, a flat roof.
OpenStreetMap maps it at 17.5 m, too low: the photos count six storeys over a basement.

## 1. Identity

1. A pale cream-grey stone cube, the same front on all four sides, horizontal rustication grooves
   over the whole wall (all Street View images).
2. Eight bays of **paired** narrow windows on every face and storey: a low first floor of short
   pairs in a raised frame, three tall storeys of tall pairs, the small square pairs of the top
   storey just under the cornice (east face, 2021; north face, 2022).
3. The deep overhanging classical cornice, about 1.6 m out, under a flat roof (all).
4. From above (the game's camera): a low dark dome 28 m across studded with white bubble
   skylights (a ring of pairs and a cluster at the top), on a pale drum, in a square roof ringed
   by glazed roof lights on all four edges (3D Tiles top view and orbit views; the "before" game already shows LoD2's half-dome here).
5. A tall dark bronze door in a stone frame in the middle of the north and east fronts, a bronze
   statue (Barbara Falender's Guardians, 2015) on a pedestal each side (north 2022, east 2021).

## 2. Massing

The OSM outline (one building, 15 corners) is a square about 42.6 m a side, turned about 20°
from the grid. The site builds from its four corners (game x, z): NW (-1051.4, 810.7),
NE (-1011.3, 796.1), SE (-996.7, 835.9), SW (-1036.9, 850.5); the other eleven corners lie on
those four lines within 0.4 m. One volume, the whole building, from 0.8 m under the ground to
the roof at 24.0 m; the cornice slab is 22.9 to 24.0 m. Heights from the photos: six storeys
(ground 5.2 m, first 3.4 m, three of 4.0 m, the top storey 2.6 m) = 23.2 m to the cornice's foot
(the east face's height to width on the 2021 image is about 0.55, so 23-24 m on 42.6 m).
Fronts: north to Świętej Barbary's car park, east to the service road (Pankiewicza side), south
to Wspólna, west to the church garden.

## 3. Facade, base to top

Every face the same (the north and east add the door). u along a face, 8 bays between 2.2 m
margins at each corner: bay width (42.6 - 4.4) / 8 = 4.78 m.

- **Plinth**: 0 to 0.9 m, a darker stone band 0.12 m proud; a low basement light (0.9 × 0.4 m,
  dark glass) under each ground-floor window.
- **Ground floor** (to 5.2 m): one window per bay, sill 1.5 m, pane 1.2 × 2.6 m, a stone sill.
  On the north and east fronts the two middle bays have no window: the door stands between them.
- **Ledge** at 5.2 m, 0.25 m tall, 0.12 proud.
- **First floor** (5.4 to 8.6 m): a pair per bay, panes 0.8 × 1.5 m 0.4 m apart, sill 6.3 m, in
  one raised stone frame round the pair (0.10 proud).
- **String course** at 8.6 m: the strong one, 0.45 m tall, 0.30 m proud.
- **Storeys 2 to 4** (sills 9.6, 13.6, 17.6 m): a pair per bay, panes 0.75 × 2.4 m, 0.45 m
  apart; a thin sill band (0.15 m, 0.08 proud) under each row.
- **Top storey**: a pair of small square panes per bay, 0.6 × 0.6 m, sill 21.6 m.
- **Rustication**: grooves every 0.75 m from the plinth to the string course, every 1.0 m above
  it to the frieze (the base reads heavier in the photos).
- **Cornice**: kit cornice at 22.9 m, slab 1.1 m tall (deep enough to throw a shadow band), 1.6 m proud, a frieze band under it.
- **Door** (north and east): in the middle of the face, leaf 2.2 × 4.2 m dark bronze grille, a
  stone frame 0.4 m wide and 0.25 m proud round it to 5.0 m.

## 4. Roof

From the 3D Tiles top view and the six orbit views (2026-11-26), the player's main view of this
building. Flat, dark grey membrane (PAL_ROOF_DARK) inside a grey parapet band (1.2 m wide,
PAL_ROOF_PALE) at 24.0 m; the cornice's top is grey sheet metal too (PAL_ROOF_PALE), not stone.

- **Perimeter roof lights**: a ring of rectangular glazed roof lights along all four edges,
  each 4.0 m long (across the edge) × 2.4 m, 0.5 m tall, a tan frame (PAL_SANDSTONE) round
  glass (PAL_GLASS_PALE) inset on top; 11 per side, 2.7 m apart (nearly touching), set 1.6 m in from the parapet,
  their long side pointing at the middle; none where they would hit the drum or a corner square.
- **The drum**: a round wall 28 m across (two thirds of the side), 1.2 m tall, centred on the
  roof, pale concrete, with 24 small pale vent boxes round it.
- **The dome**: a low dome on the drum, slate blue-grey (UP_DOME #707785, dark enough for the white bubbles to read), 7 m rise, as five stacked
  frustums (28 → 25 → 21 → 16 → 10 → 4 m across).
- **Bubble skylights**: white round domes 2.1 m across (PAL_WHITE_STONE, M_STONE): an outer ring
  of 20 pairs at 10 m from the centre on the dome's lower slope, a staggered ring of 12 at 7.2 m,
  and a central cluster of 19
  (1 + 6 + 12, 1.4 m apart) at its top.
- **Ducts**: two short grey ducts (0.6 m square) from the drum out to the north and east roof
  lights. Optional, last.

## 5. Colour and material

Stone UP_STONE #d8d4c9 (the east face in sun, 2021 Street View, calmed to the palette; near
PAL_CREAM_STONE), the plinth and grooves its own darkening, trim (frames, ledges, cornice)
UP_STONE lightened 0.04; glass PAL_GLASS_DARK; door and statues PAL_BRONZE; roof
PAL_ROOF_GRAVEL; the rotunda's glass PAL_GLASS_STEEL. All M_STONE / M_GLASS / M_PANE in the
building material: no new material, no draw call.

## 6. Ground and night

The car park on the north, the paving and trees are the map's. Two stone pedestals (0.9 m
square, 1.2 m tall) 2.6 m out of each door's frame, 3.2 m each side of the middle, each with a
bronze standing figure 2.2 m tall (four figures). Car collision on the cube's ring. Night: the
panes lit at random (M_PANE), nothing else.

## 7. Detail level and budget

L2 (a named office block off Marszałkowska, seen from the drive on Wspólna and Świętej Barbary).
Budget 4400 triangles (check_mesh_quality BUDGET "ufficio_primo"), an exception to L2's 3000:
the roof (dome, 71 bubble skylights, 44 roof lights) is what the player sees from above and is
the building's identity from the game's camera. Window panes as flat quads (`kit_panes`),
surrounds only on the ground floor and the first floor's frames.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| cube | prism | the 4-corner ring | -0.8 to 22.9 m | UP_STONE, M_STONE | 1 stone cube |
| plinth | kit_ledge per face | 0.9 m, 0.12 proud | 0 to 0.9 m | UP_STONE darkened 0.12 | 1 |
| basement_lights | kit_panes | 0.9 × 0.4 m | under each ground window, sill 0.3 m | PAL_GLASS_DARK | 1 |
| rustication | flat quads per face (kit_bands would cost 3,700 triangles) | grooves 0.15 m, UP_STONE darkened 0.2 | every 0.75 m to 8.6, every 1.0 m to 22.4 | UP_STONE | 1 rustication |
| ground_windows | kit_window SILL | 1.2 × 2.6 m | one per bay, sill 1.5 m, none in bays 4-5 on N and E | trim, PAL_GLASS_DARK | 2 |
| ground_ledge | kit_ledge | 0.25 m, 0.12 proud | 5.2 m | trim | 2 |
| first_frames | kit_ledge box per pair | 2.3 × 1.9 m, 0.10 proud | sill 6.15 m, each bay | trim | 2 paired windows |
| first_pairs | kit_panes | 0.8 × 1.5 m, 0.4 apart | sill 6.3 m | PAL_GLASS_DARK | 2 paired windows |
| string_course | kit_ledge | 0.45 m, 0.30 proud | 8.6 m | trim | 2 |
| sill_bands | kit_ledge | 0.15 m, 0.08 proud | 9.4, 13.4, 17.4 m | trim | 2 |
| tall_pairs | kit_panes | 0.75 × 2.4 m, 0.45 apart | sills 9.6, 13.6, 17.6 m | PAL_GLASS_DARK | 2 paired windows |
| top_pairs | kit_panes | 0.6 × 0.6 m | sill 21.6 m | PAL_GLASS_DARK | 2 top storey |
| cornice | kit_cornice | slab 1.1 m, 1.6 proud | 22.9 m | trim | 3 cornice |
| roof | cap | the ring | 24.0 m | PAL_ROOF_DARK | 3 flat roof |
| parapet_band | strip | 1.2 m inside the ring | 24.0 m, 0.3 m up | PAL_ROOF_PALE | 3 |
| roof_lights | boxes | 4.0 × 2.4 × 0.5 m, 11 a side | 1.6 m in from the parapet | PAL_SANDSTONE, PAL_GLASS_PALE | 4 roof lights |
| drum | ring wall | 28 m across, 1.2 m | roof centre | PAL_PALE_CONCRETE, 24 vents PAL_WHITE_STONE | 4 dome |
| dome | 5 frustums | 28 → 4 m, 7 m rise | on the drum | UP_DOME #707785 | 4 dome |
| bubbles | small domes | 2.1 m across, 71 | 20 pairs at r 10 m, 12 at r 7.2 m, 19 at the top | PAL_WHITE_STONE | 4 dome |
| ducts | boxes | 0.6 m square | drum to N and E | PAL_DARK_STEEL | 4 |
| doors | kit_door | 2.2 × 4.2 m leaf | middle of N and E | trim, PAL_BRONZE | 5 door |
| door_frames | kit_ledge box | 3.0 × 5.0 m, 0.25 proud | round each door | trim | 5 door |
| pedestals | box | 0.9 × 0.9 × 1.2 m | 2.6 m out, ±3.2 m from each door | UP_STONE darkened 0.08 | 5 guardians |
| guardians | figure | 2.2 m | on the pedestals | PAL_BRONZE | 5 guardians |
