# Centrum Praha (Ząbkowska / Markowska, Praga Północ)

Site key `centrum_praha` in `game/scripts/landmarks/praga.gd` (`_find_centrum_praha`,
`_build_centrum_praha`). Modelling queue v2 row 4 (F, 2026-11-27: buildings with no model first),
Gemini lane, built together with `targowa33a` (spec targowa33a.md). Sources: six Google Street View
frames, 2024-08 (`refs/centrum_praha/streetview/`, reference only, gitignored, never copied).
OpenStreetMap: landmark "Centrum Praha" and building 12642 (17.5 m, "public"); find it by name.

## Identity

A new five-storey block in Praga that dresses in old Praga's stone. What makes it itself:
1. Pale sandstone frames: each bay two storeys tall (floors 2-3) is a deep stone frame with a
   recessed panel of vertical sandstone fins (stripes), not glass, over the frieze.
2. A sculpted frieze band at the first-floor line: carved stone faces (portraits of Praga's people)
   in a row of square panels, the block's signature.
3. A glazed ground floor of tall shop windows between dark grey stone piers.
4. The top two storeys step out of the frames: a band of large square windows in thin stone
   surrounds, then a grey zinc mansard storey with big tilted windows (dormer-like) set at an angle.
5. Calm, light, even: no colour but stone, grey zinc and glass.

## Massing

The landmark outline (about 60 x 58 m, four straight faces, the corners slightly cut). Ground =
`_ground_under`. Ground floor 0-4.5 m (glazed, piers), frieze 4.5-6.0 m, framed storeys 6.0-12.0 m,
window storey 12.0-14.8 m, mansard 14.8-17.5 m with its face leaning in 1.2 m at the top. Flat roof
inside the mansard at 17.5 m.

## Facade

Kit parts only. Every face, bays about 6.5 m:
- Ground floor: kit_shop_bay per bay (glass #5d6f74) between dark stone piers #6d6a66 0.9 m wide.
- Frieze: kit_ledge band 1.5 m tall, #d4c8b0, with one carved face per bay as a small relief (a
  0.9 m square panel 0.12 m proud with two eye boxes and a nose box, same stone, a shade darker).
- Framed storeys: kit_pilaster-like deep frames 0.7 m wide, 0.4 m proud, framing each bay two
  storeys tall; inside, kit_bands of vertical fins every 0.5 m (#d9ceb7 over #bfb39c), no glass.
- Window storey: kit_window_grid of square windows (2 per bay) in thin stone surrounds, glass #4a5a63.
- Mansard: grey zinc #6e7378 sloped faces; kit_panes of large windows (2 per bay) tilted with it.
- A kit_cornice_ring at 14.8 m under the mansard.

## Roof

Flat dark membrane #5f6266 inside the mansard ridge at 17.5 m, a 0.5 m zinc cap on the ridge, two
low plant boxes 2 x 4 m.

## Colour and material

Sandstone #d4c8b0 / #d9ceb7 / shadow #bfb39c, piers #6d6a66, zinc #6e7378, glass #4a5a63 and
#5d6f74, roof #5f6266. All M_STONE; shop glass M_PAVILION (glows at night); no new material, light
or node: one site mesh.

## Ground and night

The ground floor meets the pavement at `_ground_under`; collision follows the outline to full
height. At night the shopfronts glow (M_PAVILION); upper windows dark.

## Detail level and budget

L3 (a characteristic Praga block on a street players drive, the carved frieze needs the detail). Budget 4,000 triangles; set
`"centrum_praha": 4000` in both game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| cp_body | prism of the outline | 0-17.5 m | landmark outline | M_STONE #d4c8b0 | 5 |
| cp_shops | kit_shop_bay between piers | 4.5 m, bays 6.5 m | all faces, ground | M_PAVILION / #6d6a66 | 3 |
| cp_frieze | ledge band + face reliefs | 1.5 m, one face per bay | 4.5-6.0 m | M_STONE | 2 |
| cp_frames | deep stone frames, fin panels | 0.7 m frames, fins 0.5 m | 6.0-12.0 m | M_STONE | 1 |
| cp_windows | kit_window_grid square | 2 per bay | 12.0-14.8 m | M_STONE / #4a5a63 | 4 |
| cp_mansard | leaning zinc faces + kit_panes | 2.7 m, lean 1.2 m | 14.8-17.5 m | M_STONE #6e7378 | 4 |
| cp_roof | flat roof, cap, plant boxes | 0.5 m cap | 17.5 m | M_STONE #5f6266 | 5 |
| cp_collision | outline | full height | outline | (collider) | 5 |
