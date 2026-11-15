# Babka Tower (Rondo Zgrupowania AK "Radosław"): spec

Site key `babka` (a TOWERS entry, new 2026-11-15; `_babka` and `_babka_block` in
`game/scripts/landmarks/skyline.gd`). Written 2026-11-15 in a cloud thread, and revised the same
morning after F's look check, from ten photos (reference only, never shipped): F's six in
`refs/_f/warsaw-needed-photos/top-50/T42/` (the tower over the roundabout from the south, from
the east over the flats block, and from the Palace's terrace) and the four F sent on 2026-11-15
(`refs/_f/babka-f-2026-11-15/`: three from the roundabout, two of them with the older red sign,
and Błękitny's in `blekitny-f-2026-11-15/`). Massing from the OpenStreetMap part "Babka Tower"
(96 m) and the 34 m office block round its foot, both unchanged in `centrum.json`.

## 1. Identity

1. The north's tallest flats tower (2000): pale grey stone throughout, small punched windows in
   a fine grid (all photos; the first build's "grey office glass" was a misreading, F
   2026-11-15).
2. A glazed loggia column down the middle of each face: wide windows in white frames, floor
   after floor (T42 photo 4, F's photo 3).
3. The tower rises out of a 34 m stone office block that wraps its foot in a U round a
   courtyard; the block's rows of blue office windows, its roof garden at the tower's foot (T42
   photo 4, F's photos 1 and 3).
4. The cable firm's name on the top floor and a red lattice mast on the roof (all).

## 2. Massing (the mapped parts)

The tower: one part, 0 to 96 m, a slab about 24 by 40 m with its corners stepped in (fifteen
corners). The block: one U-shaped outline (60 corners), 0 to 34 m, round a courtyard; its centre
lies in the yard, so the site also takes the block's convex hull as a zone, which takes it off
the map's own buildings (nothing else has its centre there). The cream flats block east of it is
the map's.

## 3. Facade, base to top

- **Tower**: the kit's punched skin (S_PUNCHED, 2 by 1.4 m windows every 3.2 m) in stone
  #d9d8d3, ground to roof.
- **Loggia column**: on each face 12 m or longer, the middle 45 % in pale glass in a light grid
  (S_EASTWALL #a9b8c4), 0.1 m proud, from 35.2 m to 3.2 m under the roof.
- **String course**: stone #d9d8d3, 0.3 m out, 34.6 to 35.2 m, where the block's roof meets the
  tower; its underside shaded.
- **Top floor**: stone, 0.1 m proud, the top 3.2 m, the parody name WEKTRA on it in blue.
- **Block**: S_PUNCHED in stone #c9cac7 from the ground to 33.2 m, a stone cornice 0.2 m out from
  33.2 to 34 m.

## 4. Roof

Tower: flat, #9b9794 (mapped), a red mast (#c8322b) 1.4 m square and 12 m tall a little off the
middle, two stone bands, the red lamp on top. Block: the cornice's top is its roof (#8f918f),
with green planters (#5f7f45, 1.8 m square, 1.4 m tall) 3 m out from the tower's corners where
that lands on it.

## 5. Colour and material

Tower stone #d9d8d3 and block stone #c9cac7 (S_PUNCHED skin); loggia glass #a9b8c4 (S_EASTWALL
skin); string course, top floor and cornice #d9d8d3 (building material); roofs #9b9794 and
#8f918f; planters #5f7f45; mast #c8322b; lamp DUSK_RED (M_LAMP); the name in blue
(0.3, 0.45, 1.0). No new material.

## 6. Ground and night

The roundabout, the tram tracks and the cream flats block are the map's. Car collision on the
tower (the parts loop) and round the block (`_collide`). Night: the punched windows lit warm at
random (S_PUNCHED), the name on the top floor, the mast's red lamp and the aviation lights.

## 7. Detail level and budget

L1 (a tower at the map's north edge, seen from Jana Pawła II and the Palace). 637 triangles with
the block, budget 800 (check_mesh_quality BUDGET "babka"); 0 z-fights; no draw call, no shader
change (building.gdshader stays 501 of 505).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | prism | mapped, 0 to 96 m | the mapped part | S_PUNCHED #d9d8d3 | 1 stone tower |
| loggia column | walls | 45 % of each face 12 m or longer, 0.1 m proud | 35.2 to 92.8 m | S_EASTWALL #a9b8c4 | 2 loggia column |
| string course | prism + soffit | ring + 0.3 m, 0.6 m | 34.6 to 35.2 m | #d9d8d3 | 3 block meets tower |
| top floor | prism | ring + 0.1 m, 3.2 m | 92.8 to 96 m | #d9d8d3 | 4 name |
| name | dusk sign | the top floor's height | S and E | blue | 4 name |
| mast | prisms | 1.4 m square, 12 m, two bands | roof | #c8322b, #d9d8d3 | 4 mast |
| lamp | box | 0.4 m | mast head | DUSK_RED (M_LAMP) | 4 mast |
| block | prism | mapped U, 0 to 33.2 m | the `with` outline | S_PUNCHED #c9cac7 | 3 office block |
| cornice | prism | ring + 0.2 m, 0.8 m | 33.2 to 34 m | #d9d8d3, roof #8f918f | 3 office block |
| planters | prisms | 1.8 m square, 1.4 m | block roof by the tower | #5f7f45 | 3 roof garden |

## 9. Not built, and what only the phone can show

- The block's blue window tint (the punched skin's glass is the kit's dark glass), its glazed
  corner, the shop signs at the foot, the loggias' white frames one by one.
- The cream flats block east of the tower stays the map's plain building.
- Phone: the loggia column and the stone reading at the game's zoom; the name at night.
