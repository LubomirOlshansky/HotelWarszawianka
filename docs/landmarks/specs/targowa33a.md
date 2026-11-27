# Pasaż Handlowy Targowa 33A (Praga Północ)

Site key `targowa33a` in `game/scripts/landmarks/praga.gd` (`_find_targowa33a`, `_build_targowa33a`).
Modelling queue v2 row 4 with `centrum_praha`, Gemini lane. Sources: three Street View frames from
Targowa, 2024 (`refs/targowa33a/streetview/`) and eight Google 3D Tiles orbit views plus a top view,
2026-11-27 (`refs/targowa33a/3dtiles/`); reference only, gitignored, never copied. OpenStreetMap:
landmark "Pasaż Handlowy "Targowa 33A"" and building 12829 (7.6 m, commercial), the low trade podium
that fills the inside of the block behind the 1990s flats on Targowa (buildings 1758, 1760, 1784,
1792, 24.1 m, which stay the map's own and are NOT part of this site).

## Identity

1. A long low two-storey trade podium with a sawtooth front: small shop units stepping along the
   block in a zig-zag (the OSM outline's notches), each with its own glazed front and sign band.
2. A flat grey roof with rooftop vents, skylight strips and a parapet (3D Tiles top view).
3. Pale render #d9d4c8 walls over a dark grey plinth, a white sign band at 3.4 m running along the
   fronts with parody shop names.
4. It sits low among the eight-storey flats; from the iso camera it reads as a grey roofscape
   between the blocks.

## Massing

Building 12829's outline (84 x 79 m). Ground = `_ground_under`. Ground floor 0-3.6 m, upper floor
3.6-7.0 m, parapet to 7.6 m. Where a 24.1 m block stands on the outline, build nothing inside the
block's own outline (pass those outlines as `keep` to _add_site so they stay drawn, and clip the
podium's walls and roof against them).

## Facade

Kit parts only. Along every exposed edge longer than 3 m:
- Ground floor: kit_shop_bay per 4-5 m (glass #50636b, frames #3e4246), a dark plinth 0.4 m.
- Sign band 3.0-3.6 m: white #ecebe6 kit_ledge, with a few parody words (e.g. `SKLEP`, `APTEKA`,
  `KEBAB`, `LOMBARD`) every few units in M_LAMP (common.gd _usign).
- Upper floor: render #d9d4c8 with a kit_window_grid of ribbon windows (glass #4a5a63).
- kit_cornice_ring/parapet at 7.0-7.6 m, light grey #b9b8b3.

## Roof

Flat grey membrane #8a8c8e at 7.0 m inside the parapet; two skylight strips (glass #6f8590, 2 m
wide) along the longest arms; six to ten vent boxes 1 x 1.5 m, 0.8 m tall.

## Colour and material

Render #d9d4c8, plinth #4b4d50, frames #3e4246, sign band #ecebe6, roof #8a8c8e, parapet #b9b8b3,
glass #50636b / #4a5a63 / #6f8590. All M_STONE; shop glass M_PAVILION; words M_LAMP. No new material,
light or node: one site mesh.

## Ground and night

Collision follows the podium outline (minus the kept blocks). At night the shopfronts and the shop
words glow; the upper floor stays dark.

## Detail level and budget

L2 (a Praga shopping strip by Bazar Różyckiego). Budget 3,000 triangles; set `"targowa33a": 3000`
in both game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| tg_body | prism of 12829 minus kept blocks | 0-7.6 m | outline | M_STONE #d9d4c8 | 1 |
| tg_shops | kit_shop_bay | 3.6 m, every 4-5 m | every exposed edge | M_PAVILION / #3e4246 | 1 |
| tg_signs | sign band + parody words | 0.6 m band | 3.0-3.6 m | M_STONE / M_LAMP | 3 |
| tg_upper | kit_window_grid ribbons | 3.6-7.0 m | every exposed edge | M_STONE / #4a5a63 | 3 |
| tg_roof | flat roof, skylights, vents | 7.0 m | inside parapet | M_STONE #8a8c8e | 2 |
| tg_parapet | parapet ring | 0.6 m | 7.0-7.6 m | M_STONE #b9b8b3 | 2 |
| tg_collision | outline minus blocks | full height | outline | (collider) | 1 |
