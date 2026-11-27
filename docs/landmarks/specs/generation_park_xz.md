# Generation Park X and Z (Towarowa 28 / Prosta 36, Rondo Daszyńskiego)

Site key `gpxz` in `game/scripts/landmarks/wola.gd` (`_find_gpxz`, `_build_gpxz`), registered in
`game/scripts/landmarks.gd` next to the other Wola sites. Modelling queue v2 row 2 (F, 2026-11-27:
"start with the buildings that have no model"), Gemini lane. Generation Park Y, the 140 m tower
between them, keeps its own TOWERS entry `gpy` and is not touched; `gpy` already draws the decked
roof terraces on the X and Z roofs (`terraces`), so this model keeps those roofs at their mapped
heights (37.3, 43.9, 53.8 m) and adds no terraces of its own.

Sources: 12 Google Street View frames, 2026-11-27 (`refs/generation_park_x/streetview/`,
`refs/generation_park_z/streetview/`), and 8 Google 3D Tiles orbit views
(`refs/generation_park/3dtiles/`; their imagery predates Y, so they only confirm X's and Z's
roofs and massing). Reference only, gitignored, never copied. OpenStreetMap outlines in
`game/map/centrum.json`: landmarks "Generation Park X" and "Generation Park Z"; buildings 12183
(X body, 6.6-37.3 m; 12184 is a duplicate of it), 12178 (X first floor, 3.3-7.6 m), 12185 (X ground
floor, 0-4.3 m), 12187 (Z body, 3.3-43.9 m), 12186 (Z top, 42.9-53.8 m), 12188 (Z ground floor).
Find them by a point and height, not by index (indices move on a re-bake).

**As built (2026-11-27), corrections from the Street View headings:** X's 90 m face runs along
Wronia (east), its narrow south end faces Prosta beside Y, and the real name sits on the
south-east corner (Prosta/Wronia), so `cyti` is there, on the south and east faces. Z's two-storey
lobby and canopy wrap its south-west corner on the plaza facing Y, and the café is on Towarowa
(west). The grid was built at a 4.8 m bay with 0.72 m storey bands: the real proportions, and
3 m bays aliased into dashes at iso distance. Where the sections below say otherwise, this wins.

## Identity

Two calm 2017-2019 office blocks by Rondo Daszyńskiego that frame Generation Park Y. What makes
them read as themselves from the iso camera:
1. A light grey stone grid over blue-grey glass: square-ish bays, two panes per bay between
   storey bands, deep reveals (both buildings, Street View frames 1-6).
2. X: a long 11-storey slab along Towarowa (about 90 m) with a wider head at the north end where a
   white name sits high on the corner (the real one is a bank; ours is the parody `cyti`).
3. X's street foot: a dark recessed ground floor with grey garage and service doors, a green-tinted
   glass band on the first floor, and a tall glazed entrance at the south end.
4. Z: a 13-storey block on Prosta stepping to 16 storeys at its west end, the same grid in blue
   glass, a two-storey glazed lobby with a thin flat canopy on the corner, a café in the ground floor.
5. Flat roofs with a parapet; Y's decked terraces (drawn by `gpy`) sit on X's roof and Z's low east
   wing.

## Massing

One frame for both: u = (0.963, -0.268) along Prosta and Z's long face, v = (0.268, 0.963) along
Towarowa and X's slab (world x, z). Ground = `_ground_under` of each outline.

- X: the "Generation Park X" landmark outline (an L: a 30 x 17 m head at the north, a 21-22 m wide
  slab running 90 m south). Ground floor 0-4.3 m set back 1.2 m from the line above; first floor
  4.3-7.6 m flush; nine office storeys 7.6-37.3 m (3.3 m each); roof slab top at exactly 37.3 m.
- Z: the "Generation Park Z" landmark outline (about 62 x 45 m with a notch on the Y side).
  Ground floor 0-4.3 m (lobby double height 0-7.6 m on the south-east corner by Prosta); body to
  43.9 m (12 storeys of 3.3 m over the ground floor); the west part (outline 12186) rises to 53.8 m.
  Roof slab tops exactly at 43.9 m (east wing) and 53.8 m (west part).
- Parapets 1.0 m on every roof edge, above the slab top (Y's terrace decks are 1.5 m in from the
  edge, at the slab top).

## Facade

Kit parts only (facade_kit.gd). Every long face of both buildings:
- The grid: kit_pilaster-style piers (or a kit_wall pier pattern) every 3.0 m, 0.5 m wide, 0.25 m
  proud, full height of the office storeys; a kit_ledge storey band 0.45 m tall at every storey line;
  glass between them as one dark-blue pane strip per storey per bay (kit_panes, 2 panes per bay with a
  thin mullion), so a storey of a 3 m bay costs a handful of triangles, not a framed window each.
- X's ground floor: dark grey (#3d4146) recess with garage doors every 9 m (kit_door, grey leaf)
  and a 6 m tall glazed entrance (kit_shop_bay) at the south end; first floor 4.3-7.6 m a
  green-tinted glass band (#4f6f64) with the piers running through.
- X's north head: the same grid, the white parody name `cyti` (lower case) high on the north-east
  corner, both faces (_crown_signs or _usign from common.gd).
- Z's ground floor: clear glass shopfront (kit_shop_bay) all round, the lobby on the south-east
  corner two storeys tall with a 1.5 m deep, 0.3 m thin flat canopy over its door; a café sign
  (parody, e.g. `KAWKA`) over one bay on Prosta.
- Z's 53.8 m top: the same grid, the glass a shade darker (#2b4560).

## Roof

Flat, light grey membrane (#8d969c, as `gpy` uses), 1.0 m parapet in the facade stone with a thin
cap ledge. Two or three low plant boxes (3 x 6 m, 2.2 m tall, grey #6f767b) on Z's 53.8 m roof and
one on X's head, kept 3 m clear of the terrace points (-2605, 300), (-2654, 268), (-2687, 286).

## Colour and material

Stone grid #d3d4d0 (piers, bands, parapets), glass #33506f (as Y) for X and Z bodies, #2b4560
for Z's top, first-floor band #4f6f64, ground recess #3d4146, doors #5a5f64, roof #8d969c, canopy
#c9ccce, name `cyti` white. Everything M_STONE except the names and lobby glow (M_LAMP, existing
code) and the shopfront glass (M_PAVILION, existing code). No new material, light or node: one site
mesh.

## Ground and night

The ground floors meet the pavement at `_ground_under`; collision follows both buildings' outlines
(X and Z) to full height. At night the lobby and café glass and the name glow (M_LAMP / M_PAVILION
codes already in use), the office glass stays dark. No trees inside the outlines.

## Detail level and budget

L3 (two big office blocks on Rondo Daszyńskiego, seen from the busiest junction in Wola). Budget
12,000 triangles for the site, an exception to the skill's L3 range of 8,000 because the site is
two whole buildings of 11-16 storeys; set `"gpxz": 12000` in both game/tools/check_mesh_quality.gd
BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| x_body | prism of the X landmark outline | 4.3-37.3 m | X outline | M_STONE #d3d4d0 | 2 |
| x_ground | prism inset 1.2 m, doors | 0-4.3 m, doors every 9 m | X outline | M_STONE #3d4146 | 3 |
| x_band1 | glass band | 4.3-7.6 m | all X faces | M_STONE #4f6f64 | 3 |
| x_grid | piers 0.5 m every 3 m, kit_ledge bands, kit_panes | 7.6-37.3 m | all X faces | M_STONE #d3d4d0 / #33506f | 1 |
| x_entrance | kit_shop_bay | 6 m tall, 8 m wide | X south end | M_PAVILION | 3 |
| x_name | parody word `cyti` | 1.6 m letters | X head, top storey, NE corner | M_LAMP white | 2 |
| z_body | prism of the Z landmark outline | 4.3-43.9 m | Z outline | M_STONE #d3d4d0 | 4 |
| z_top | prism of building 12186 | 43.9-53.8 m | Z west part | M_STONE / #2b4560 | 4 |
| z_grid | piers, bands, panes as x_grid | 4.3-53.8 m | all Z faces | M_STONE #d3d4d0 / #33506f | 1 |
| z_ground | kit_shop_bay shopfronts | 0-4.3 m | all Z faces | M_PAVILION | 4 |
| z_lobby | double-height glass + canopy | 7.6 m tall, canopy 1.5 m deep | Z south-east corner | M_PAVILION / #c9ccce | 4 |
| z_cafe | parody sign `KAWKA` | 0.8 m letters | Z Prosta face, one bay | M_LAMP | 4 |
| roofs | flat slabs + parapets + plant boxes | 1.0 m parapet | 37.3, 43.9, 53.8 m | M_STONE #8d969c | 5 |
| collision | outlines | full height | X, Z | (collider) | 5 |
