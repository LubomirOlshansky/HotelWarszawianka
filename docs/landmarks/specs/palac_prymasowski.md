# Pałac Prymasowski (Senatorska 13/15)

Site key `prymasowski` in `game/scripts/landmarks/old_town.gd` (`_find_prymasowski`,
`_build_prymasowski`). Modelling queue v2 row 12 (F, 2026-11-27: buildings with no model first),
Gemini lane. Today it is the map's plain 14 m prism.

Sources: six Google Street View frames, 2026-11-27 (`refs/prymasowski/streetview/`; the three
`..._h*` frames from the courtyard side show the palace, the other three a tenement across the
street); reference only, gitignored, never copied. No 3D Tiles orbit (the day's cap was spent):
the roofs follow the photos and the outline. OpenStreetMap: landmark "Pałac Prymasowski"
(building 771, 14.0 m, 82 nodes, about 110 x 133 m with its wings); find it by name.

## Identity

The Primate's Palace, an 18th-century classical palace set back from Senatorska behind a cour
d'honneur. What makes it read as itself from the iso camera:
1. A three-storey main block (corps de logis) in cream render #e4ddca with white trim #f1eee6,
   tall windows with straight pediments on the first floor, a cornice, and a steep red-tiled
   mansard roof #b4513a with a row of small white dormers.
2. A central risalit on the courtyard front with four giant pilasters (or engaged columns) and a
   triangular pediment over the cornice; the main door in the middle.
3. Two curved single-storey colonnades (quadrant galleries of white columns) sweeping from the
   main block's ends towards Senatorska round the open courtyard.
4. Two small corner pavilions at the street ends of the colonnades, each with a four-column
   portico and pediment and a low hipped roof (grey or red).
5. The open courtyard (lawn and parking) between them, facing Senatorska: the palace is seen
   across it, never hard on the pavement.

## Massing

The landmark outline: find the straight main block (the long run farthest from Senatorska), the
two curved wings (the arcs) and the two end pavilions from the outline itself; simplify only the
straight runs, keep the arcs at least 8 segments each. Ground = `_ground_under`.
- Main block: plinth 0-0.8 m, three storeys to 14.0 m (cornice), mansard 4.0 m (lower slope steep,
  upper slope shallow, or a steep hip with a small flat top).
- Central risalit: steps forward 1.0 m, pilasters full height 0.8-14.0 m, pediment 3.0 m tall.
- Colonnades: a wall 0-6.0 m at the back of each arc with free-standing columns 1.5 m in front,
  every 3.0 m, a flat entablature roof over them at 6.0 m.
- Pavilions: two storeys to 9.0 m, portico of four columns with pediment, hipped roof 2.5 m.

## Facade

Kit parts only. kit_window_grid on the main block (1.3 x 2.4 m windows, white frames #f1eee6, glass
#4a5660, bays about 3.4 m), first-floor windows with pediments (kit_window Win.PEDIMENT if the kit
has it); kit_ledge string courses at each floor; kit_cornice_ring at 14.0 m; kit_pilaster for the
risalit's giant pilasters and pediment (kit_pediment if present); kit_column for the colonnades and
porticos (white #f1eee6); kit_door for the main door (wood #6b4a32) under a small balcony; kit_dormer
on the mansard every second bay.

## Roof

Main block: red-tiled mansard #b4513a with white dormers and two or three chimneys #c9c2b3. Pavilions:
hipped roofs in the same red. Colonnades: flat roofs with a thin parapet #e4ddca.

## Colour and material

Render #e4ddca, trim/columns #f1eee6, plinth #cfc7b5, roof #b4513a, glass #4a5660, door #6b4a32.
All M_STONE. No new material, light or node: one site mesh. No signs, flags or banners.

## Ground and night

Collision follows the outline (the courtyard stays open to drive into). At night the main door
glows warm (M_PAVILION or M_LAMP lamp, existing codes); the rest stays dark.

## Detail level and budget

L3 (one of the great palaces on Senatorska by Plac Teatralny). Budget 7,000 triangles; set
`"prymasowski": 7000` in both game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd
BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pp_main | three-storey block, plinth, string courses, cornice | 0-14.0 m | main run of the outline | M_STONE #e4ddca | 1 |
| pp_windows | kit_window_grid, pedimented first floor | 3.4 m bays | every main-block face | M_STONE / glass | 1 |
| pp_mansard | red mansard, dormers, chimneys | 4.0 m | over the main block | M_STONE #b4513a | 1 |
| pp_risalit | giant pilasters, pediment, door | 0.8-17.0 m | courtyard front, middle | M_STONE #f1eee6 | 2 |
| pp_colonnade | back wall, columns, flat roof | 0-6.0 m | both arcs | M_STONE #f1eee6 | 3 |
| pp_pavilion | two storeys, four-column portico, hipped roof | 0-9.0 m (+2.5 m) | both street ends | M_STONE / #b4513a | 4 |
| collision | outline | full height | outline | (collider) | 5 |
