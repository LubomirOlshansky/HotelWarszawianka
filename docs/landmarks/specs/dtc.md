# Domy Towarowe Centrum (the Eastern Wall's stores): spec

Site key `dtc` in `game/scripts/landmarks.gd` (`_find_dtc`, `_build_dtc`, `_dtc_sign`).
Written 2026-11-01 in a cloud thread (first scene item 3, docs/design/first-scene.md) from
the OpenStreetMap parts in `centrum.json`: each store is mapped in 3D (a glazed ground floor
0 to 5.5 m, the curtain-wall box 5.5 to 17.5 m whose outline is the named landmark, and top
parts to 20.5-23.5 m). The reference photos live on the Mac (`refs/`) and were not reachable
here: values marked *(photo check)* are the ones the side-by-side check should confirm.

**Mac photo check, 2026-11-01 (spec A, start spot `--at=-961.6,95.0 --heading=339.8`)**: the
curtain wall is dark blue-grey reflective glass (#56656e), not green-teal, in a vertical-led grid
(strong dark grey #3f474c mullions every 1.5 m, only a thin spandrel line per floor, new skin
S_EASTWALL); the shop floor is dark and 4-5 m deep under the cantilever; the soffit and fascia
are light aluminium #c9cdcf; the top storey stands back 3 m on the long sides and 8 m at the
ends; its roof lights are small square skylights in pairs and 2 x 2 clusters with curved vents
and a few big plant boxes; Junior's roof is stepped; printed ad banners hang on the faces the
camera sees. The sections below are updated to it.

**Photo pass, 2026-11-08** (thread "Rebuild Rotunda and Eastern Wall stores"): F's photo set
`/mnt/project-files/pkin-surroundings/photos/E1-centre/` (the drone and Varso aerials, the
Marszałkowska front by day and at dusk, Junior's corner, the 2025 Junior front, the Wiecha side by
day and night), F's aerials M015/M016/M023 (`~/Documents/warsaw-other-buildings-part/`), the Mac's
`refs/dt_centrum/` (Commons 1-4, ortho) and Mapillary (Wars's street face 2024-09 straight on, 14
photos; Sawa 9; Junior 8). What the photos changed:
- **The curtain wall is pale blue-grey glass (#7f97a4) in big panes**, a light silver grid (mullions
  every 3 m, four rows of 2.7 m), not dark glass with strong dark mullions: the 2026-11-01 check
  was a dusk view. Skin S_EASTWALL redrawn.
- **The cornice is a light band 0.9 m deep** along the roof edge.
- **The top storey is a light grey louvred screen** (#b4babd, skin S_FINS), not pale panels; it
  carries the shops' boxes on the street face: Junior UNIKAT, Sawa PÓŁ CENY (the off-price store,
  parody), Wars TAK MAKS (`eastern_wall_shops.json`, `top`).
- Not changed (the photos agree): the massing and set-backs, the recessed shop floor under the
  aluminium fascia, the roof's skylights and vents, the banners and shop fronts (from F's photos,
  2026-11-05).
- Still to shoot (only F): Sawa's street face straight on (Mapillary has none since 2021), the
  three stores' east (Wiecha) faces in daylight, the roof from the Metro footbridge.

The sections below are the 2026-11-01 spec; where they differ, the list above wins.

## 1. Identity

Zbigniew Karpiński's three department stores of 1962-1970 on Marszałkowska's east side,
between Świętokrzyska and Aleje Jerozolimskie, opposite the Palace. Junior stands right of
the car at the game's start; Sawa and Wars follow south towards the Rotunda. What makes a
passer-by say "the Eastern Wall's stores":

1. **Long, low glass boxes** (17.5 m) against the Palace and the towers behind them.
2. **The box floats over a recessed glazed shop floor**: the upper floors cantilever over the
   pavement on all sides, an aluminium slab edge over the shop windows.
3. **Dark blue-grey reflective curtain walls** in a vertical grid: strong dark mullions, thin floor lines.
4. **Their names on the roof** in big lit letters, read from far down Marszałkowska.

## 2. Massing

Per store, all from its OSM parts (no frame of its own: the parts are in world plan).

| Volume | Plan | Heights above ground | Source |
| --- | --- | --- | --- |
| Shop floor | the outline drawn in 4.5 m, cut to the largest mapped part with mh 0 and h <= 6.5 (its jogs are the mapped piers) where that is deeper | 0 (from -0.4) to 5.5 m | OSM part h 5.5, #B2E1C7 |
| Fascia | the landmark outline | 5.5 to 6.3 m | the slab edge |
| Curtain wall | the landmark outline | 6.3 to 17.0 m | OSM part h 17.5, mh 5.5, #78B3A1 |
| Cornice and roof | the landmark outline | 17.0 to 17.5 m | |
| Top storey | the outline drawn in 3 m, cut back 8 m from each end along the street (photos: 6-10 m) | 17.5 to 20.5 m | OSM parts h 20.5-23.5, #E4E5DE |
| Junior's raised strip | the top storey's east half | 20.5 to 21.7 m | photo check |

Ground: the lowest terrain under each outline. Junior: 25 x 100 m; Sawa: 27 x 107 m; Wars:
27 x 85 m.

## 3. Facade, base to top

- **Base (0-5.5 m)**: the shop windows all round, glass lit warm from inside at night
  (M_PAVILION), dark by day, set back 4.5 m under the cantilever (more where mapped).
- **Fascia (5.5-6.3 m)**: a plain light aluminium band all round (#c9cdcf), the slab's edge; the
  soffit under the cantilever the same aluminium.
- **Middle (6.3-17 m)**: the curtain wall in dark blue-grey glass, M_SKIN S_EASTWALL (dark grey
  mullions every 1.5 m, a thin spandrel line every 3.8 m, no silver bands), lit windows at night.
- **Banners**: printed ads the curtain wall's height (to 10 m wide, 0.2 m proud of the glass):
  one on each south end, two on each east face (the faces the iso camera sees), each a colour
  with its word in white: PROMOCJA, SAMSONG (parody), LODY, WYPRZEDAZ (R1 of docs/design/start-area-real.md, 2026-11-01, swaps them for the 2025/26 mix: DO WYNAJĘCIA, FROGS XXL, KAPCIE, WYPRZEDAŻ).
- **Shops and ads, 2026-11-05 (F's photos and the trade press):** the banners, the shop fronts and
  the pavement furniture now come from `game/data/eastern_wall_shops.json` (see its `_about`), so the
  shops, which change often, are swapped there. Banners can go on any face, the street (west) face
  too, and on the top storey (`top`); a ray from outside finds the wall, so the jogs of the outlines
  don't matter. Shop fronts: the recessed shop glass tinted the shop's colour
  (M_PAVILION, lit at night) and a lit name board (M_LAMP) hung from the cantilever's edge, 0.3 m
  proud, 4.1 to 6.25 m (on the glass itself the game's high camera never saw it); a
  `two_storey` shop also glows through the curtain wall's first floor. Nov 2026: Junior UNIKAT
  (Zara's old floor), Sawa LUKA bakery and TAK MAKS, Wars TAK MAKS on the south end and the
  street, FROGS XXL two storeys on the south-west corner with green seats and cream parasols,
  KURCZAKI WKRÓTCE beside it. Also from F's aerials: sedum strips (`roof_green`) along the main
  roof's street side (and Wars's back), and TAK MAKS's red portal posts round its doors (`portal`).
- **Cornice (17-17.5 m)**: aluminium, the roof's edge.
- **Top storey (17.5-20.5 m)**: pale panels in M_SKIN S_DARK (a fine dark grid), 3 m in from
  the edge on every side.
- **Sign**: the store's parody name (JUNIOREK, SAWKA, WARSIK: brands only as parodies) on a
  steel frame standing on the cornice over the south end, the face the game's camera sees
  from the street (down Marszałkowska); letters at most 3.2 m tall, the word over 75 % of the
  end; lit by day and night like the other landmark signs (`signs`, the neon atlas). Real
  stores carry their names on the street faces *(photo check)*: the south end is a game
  choice for the iso camera, which sees the stores' street faces only edge-on.

## 4. Roof

Flat at 17.5 m, #4f5559; the top storey's roof at 20.5 m #5d6468. Down its middle every 12 m:
small square skylights (2.2 m, 0.45 m tall, lit at night: M_GLASS_ROOF), alternately a 2 x 2
cluster and a pair, every fourth place a curved half-cylinder vent (2 m across, 4 m long);
two big plant boxes (3.4 m square, 1.9 m tall) at the north end. Junior: a lighter raised strip
(1.2 m) over the east half, a light-blue glazed skylight block on it (10 x 5.2 m, 1.4 m tall,
near the south end), a third plant box; its skylights move onto the lower west half. Optional
A6 (a second parody name on the west top-storey face) is not built: the iso camera never sees
the west faces (parked in QUESTIONS).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shop windows | #6e7f84 | M_PAVILION (+0, warm at night) |
| Fascia, cornice, soffit, sign frame, roof-light kerbs | #c9cdcf (frame darker) | M_STONE |
| Banners | #c8322e, #1f3f8f, #e0a21c, #2c8a57, #252a33, #8a2b7a | M_STONE (words: neon atlas) |
| Vents | #b4babd | M_STONE |
| Junior's strip, glazed block | #848b8f; #a9c6d6 glass | M_STONE; M_PAVILION + 0.5, top M_GLASS_ROOF |
| Curtain wall | #56656e, mullions #3f474c | M_SKIN + S_EASTWALL / 16 |
| Top storey | #dfe1dc | M_SKIN + S_DARK / 16 |
| Roofs | #4f5559, top storey #5d6468 | M_STONE |
| Roof lights | #cfd8dc | M_GLASS_ROOF |
| Air-handling units | #a3aaac, top #8d9497 | M_STONE |
| Sign | tube (1.0, 0.86, 0.55), warm white | neon atlas (LandmarkSigns) |

No new material: everything goes into the city's building surface (+0 draw calls) and the
landmark signs' MultiMesh (+0).

## 6. Ground and night

The car is stopped at the shop floor's outline (not under the cantilever: the pavement is the
footway there). At night the shop floor glows warm, the curtain wall shows lit windows, the
roof lights glow, the names stay lit. The pavement round the stores and the furniture on the
opposite pavement are first-scene items 4-5 (`first_scene.gd`), not this site. Card:
"Domy Towarowe Centrum", PL "Trzy szklane domy towarowe Ściany Wschodniej, 1962–1970. Nazwy
po Warsie i Sawie z legendy.", EN "The Eastern Wall's three glass department stores,
1962–1970, named after the legend's Wars and Sawa."

## 7. Detail level and budget

L2 (facade articulation from the mapped parts), triangle budget 1950 (1439 measured on
2026-11-01 after the Mac photo check, 1767 on 2026-11-05 with the shop fronts, furniture, red portals and green roof strips,
`check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism of the outline drawn in 4.5 m | per store, 5.9 m tall | y -0.4..5.5 | M_PAVILION #6e7f84 | 2 floating box |
| fascia | prism of the outline | 0.8 m tall | y 5.5..6.3 | M_STONE #c9cdcf | 2 floating box |
| soffit | downward cap of the outline | per store | y 5.5 | M_STONE #c9cdcf | 2 floating box |
| wall | prism of the outline | 10.7 m tall | y 6.3..17.0 | M_SKIN S_EASTWALL #56656e | 1 glass box, 3 curtain wall |
| banners | a poster and its top edge, a word | to 10 m wide, 9.9 m tall | 0.2 m proud, south end and east face | M_STONE colours, neon atlas | 3 curtain wall |
| cornice | prism of the outline, roof | 0.5 m tall | y 17.0..17.5 | M_STONE #c9cdcf, roof #4f5559 | 1 glass box |
| top | prism of the outline drawn in 3 m, 8 m off the ends | 3 m tall | y 17.5..20.5 | M_SKIN S_DARK #dfe1dc, roof #5d6468 | 1 glass box |
| lights | square skylights, pairs and 2 x 2 clusters | 2.2 x 2.2 x 0.45 m, every 12 m | the top's middle line | M_STONE sides, M_GLASS_ROOF #cfd8dc | 4 roof |
| vents | half-cylinders | 2 x 4 m | every fourth place | M_STONE #b4babd | 4 roof |
| plant | big boxes | 3.4 x 3.4 x 1.9 m | 2 at the north end (3 on Junior) | M_STONE #a3aaac | 4 roof |
| strip | Junior's raised east half | 1.2 m tall | on the top roof | M_STONE #848b8f | 4 roof |
| glazed | Junior's skylight block | 10 x 5.2 x 1.4 m | on the strip near the south end | M_PAVILION + 0.5, M_GLASS_ROOF | 4 roof |
| frame | two posts and a rail | 0.3 m posts, word width + 0.6 m | the south end, 1 m in from the edge | M_STONE #949795 | 4 names |
| sign | neon word | letters up to 3.2 m | on the frame, facing south | neon atlas | 4 names |
