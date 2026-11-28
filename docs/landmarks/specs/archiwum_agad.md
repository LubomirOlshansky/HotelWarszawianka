# Archiwum Główne Akt Dawnych (Pałac Raczyńskich, Długa 7)

Site key `archiwum_agad` in `game/scripts/landmarks/old_town.gd` (`_find_archiwum_agad`,
`_build_archiwum_agad`). Modelling queue v2 row 22 (F, 2026-11-27: buildings with no model
first), Gemini lane. Today it is the map's plain 14 m prism.

Sources: Google Photorealistic 3D Tiles via Cesium ion, 2026-11-28 (`refs/archiwum_agad/3dtiles/`:
eight orbits at pitch -30, four face views, top-down); Google Street View, 2026-11-28
(`refs/archiwum_agad/streetview/`: the middle row of the contact sheet shows the palace front on
Długa, the top row the plain yellow rear wing, the bottom row the mauve-pink wing on Kilińskiego);
Mapillary/Panoramax (`refs/archiwum_agad/street/`). Reference only, gitignored, never copied.
OpenStreetMap: landmark "Archiwum Główne Akt Dawnych" (14.0 m, 50 nodes, about 72 x 60 m); find
it by name.

## Identity

The classicist Raczyński palace on Długa, now the state archive of old records, by the Old Town
walls. What makes it read as itself from the iso camera:
1. A ring of wings round a closed courtyard with trees, filling the block between Długa and
   Kilińskiego.
2. The palace front on Długa: three storeys in warm cream render #e2d3a8 over a rusticated ground
   floor #d4c497, a central risalit with six giant engaged columns over two upper storeys carrying
   a wide triangular pediment, a stone balustrade balcony across the risalit on the first floor,
   pedimented first-floor windows.
3. The front wing's big red tile hipped roof #b5583f with small dormers, folding round its corners.
4. The courtyard and rear wings: plain yellow render #d9c48f, three storeys, windows in a simple
   grid, under grey-green metal roofs #8e9a8f on the inner slopes and red tile on the rear block.
5. The wing toward Kilińskiego and the walls: a mauve-pink rebuilt block #b99a95 with a stone
   portal, three storeys, under a pale grey zinc mansard #b8bfc4 with a long row of dormers.

## Massing

The landmark outline; ground = `_ground_under`. Work out the wings from the outline itself (the
courtyard is the hole or the inner concave run; if the outline has no hole, leave a courtyard
about 12-14 m from each outer side, matching the top view); simplify only short wiggles.
- Palace front wing on Długa (the outline's west / south-west side, the one facing the square
  with parked cars): ground floor 0-5.0 m (rusticated), two upper storeys to 15.0 m, cornice;
  central risalit 0.8 m forward with the columns and a pediment 3.5 m over the cornice; red tile
  hipped roof 6.0 m tall.
- Kilińskiego wing (the outline's south-east side, toward the curving street and the red-brick
  walls): 0-13.5 m, cornice, then a pale zinc mansard 4.5 m with dormers.
- Courtyard and rear wings: 0-13.0 m, cornice, roofs 4.0 m (grey-green metal, red tile on the
  north rear block).

## Facade

Kit parts only. Front: kit_bands rustication on the ground floor; kit_portico or kit_column (six
giant engaged columns) on the risalit from 5.0 to 15.0 m; kit_pediment over the risalit;
kit_balcony (stone balustrade) across the risalit at 5.0 m; kit_window_grid (1.3 x 2.4 m windows,
white surrounds, glass #4a5660, bays about 3.6 m) with Win.PEDIMENT on the first floor;
kit_cornice_ring at the eaves; kit_door (wood #6b4a32) in the middle. Kilińskiego wing: kit_window
grid, kit_door with a stone surround, kit_ledge string courses; dormers with the kit's dormer
part. Courtyard and rear faces: plain kit_panes grid with sill ledges.

## Roof

Front wing: red tile hipped roof #b5583f with small dormers. Kilińskiego wing: pale zinc mansard
#b8bfc4 with a long row of dormers on the street slope. Courtyard slopes of the side wings:
grey-green metal #8e9a8f. North rear block: red tile. All roofs solid down to the cornice; the
courtyard stays open with a few trees' worth of dark ground #5d6a55.

## Colour and material

Front render #e2d3a8, ground floor #d4c497, trim and columns #efe6cc, rear #d9c48f, Kilińskiego
wing #b99a95, red tile #b5583f, metal #8e9a8f, zinc #b8bfc4, glass #4a5660, door #6b4a32. All
M_STONE (glass by the kit). No new material, light or node: one site mesh. No signs, plaques,
emblems or flags (the real building has an EU sign and a flag: leave them out).

## Ground and night

Collision follows the outline. At night the main door on Długa glows warm; the rest stays dark.

## Detail level and budget

L3 (a palace front on Długa by the Barbican and the walls). Budget 6,000 triangles; set
`"archiwum_agad": 6000` in both game/tools/check_mesh_quality.gd BUDGET and
game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| ag_front | three storeys, rusticated base, cornice | 0-15.0 m | Długa wing | M_STONE #e2d3a8 / #d4c497 | 2 |
| ag_risalit | six giant columns, pediment, balustrade balcony, door | 5.0-18.5 m | front middle | M_STONE #efe6cc | 2 |
| ag_red | red tile hipped roof with dormers | 6.0 m | front wing, north rear block | M_STONE #b5583f | 3 |
| ag_rear | plain three-storey wings round the courtyard | 0-13.0 m | rest of the ring | M_STONE #d9c48f / #8e9a8f | 4 |
| ag_kilinskiego | mauve-pink block, portal, zinc mansard with dormers | 0-13.5 m + 4.5 m | south-east wing | M_STONE #b99a95 / #b8bfc4 | 5 |
| ag_court | open courtyard, dark ground | inside the ring | courtyard | M_STONE #5d6a55 | 1 |
| collision | outline | full height | outline | (collider) | 1 |

As built, 2026-11-28: 4,842 triangles (budget 6,000), one site mesh, zero defects, registering `replaces_photo_front = "b1828"`. The mapped OSM outline `"Archiwum Główne Akt Dawnych"` (50 nodes, rotated bounding box 71.5 x 60.1 m) is strictly the U-shaped Raczyński Palace (Długa 7 front wing plus the SW and NE yellow courtyard wings); the SE mauve-pink Kilińskiego block with its pale zinc mansard and dormers and the north-east red-tile rear block are separate neighbouring OSM apartment buildings outside this outline and are therefore left to the map so nothing overlaps or z-fights in the city. Following Street View and 3D Tiles, the stepped 13-bay (`3+2+3+2+3`) Długa front uses four giant engaged Tuscan columns under a shallower classical triangular pediment (2.65 m tall with a grey-green metal saddle roof into the red tile hipped roof), four giant pilasters under stone attic balustrades on the two flanking 2-bay intermediate wings, a stone balustrade balcony, white window sashes, shorter mezzanine top-storey windows, and three low courtyard trees on the dark green-grey courtyard ground.
