# Pałac Biskupów Krakowskich (Miodowa 5, corner of Senatorska)

Site key `biskupow_krakowskich` in `game/scripts/landmarks/old_town.gd` (`_find_biskupow_krakowskich`,
`_build_biskupow_krakowskich`). Modelling queue v2 row 20 (F, 2026-11-27: buildings with no model
first), Gemini lane. Today it is the map's plain 14 m prism.

Sources: Google Photorealistic 3D Tiles via Cesium ion, 2026-11-28 (`refs/biskupow_krakowskich/3dtiles/`:
eight orbits at pitch -30, four face views, top-down); Google Street View, 2026-11-28
(`refs/biskupow_krakowskich/streetview/`: the `fVz...` frames show the street front with its
balcony, under scaffolding); Mapillary/Panoramax (`refs/biskupow_krakowskich/street/`). Reference
only, gitignored, never copied. OpenStreetMap: landmark "Pałac Biskupów Krakowskich" (14.0 m,
15 nodes, an L about 48 x 72 m); find it by name.

## Identity

A late-baroque bishops' palace at the corner where Miodowa meets Senatorska, by the W-Z tunnel.
What makes it read as itself from the iso camera:
1. An L of two wings round a courtyard (parking) that opens to the west; the corner of the L
   points east at the crossing.
2. The palace wing (the outline's north-east arm, running west-north-west from the corner):
   three storeys in cream render #eadcbf with white trim #f4f1ea, an ochre rusticated ground
   floor #d9a66a, tall windows with moulded surrounds, a wrought-iron balcony on the first floor
   over the big arched wooden door #6b4a32.
3. Its roof: a tall hipped green copper roof #7fa392 with a row of small round-top dormers on
   each slope, hipped at both ends, wrapping round the corner.
4. The long side wing (the outline's south-west arm, running south-south-west from the corner):
   three storeys in pale cream #e8dcc2 under a red tile roof #b4553f with a long row of white
   dormers on the courtyard slope and smaller ones on the street slope.
5. Plainer courtyard faces, with the windows in a simple grid.

## Massing

The landmark outline; ground = `_ground_under`. Split it into its two arms at the east corner
(about (-808, -1354)); simplify only short wiggles. Work out the street fronts (the outer, convex
sides meeting at the east corner) and the courtyard sides (facing west) from the outline itself.
- Palace wing: ground floor 0-4.8 m (rusticated), two upper storeys to 14.0 m, cornice; hipped
  copper roof 6.0 m tall (ridge about 20 m) with dormers.
- Side wing: three storeys 0-13.0 m, cornice; red tile roof 5.0 m tall, hipped at the far end,
  meeting the palace roof at the corner.
- Corner: the copper roof wraps the corner bay; the red roof starts a few metres along the side
  wing (the top view shows the copper turning the corner).

## Facade

Kit parts only. kit_window_grid on both street fronts (1.3 x 2.4 m windows, white surrounds,
glass #4a5660, bays about 3.4 m); kit_bands rustication on the palace's ground floor; kit_ledge
string courses at the floor lines; kit_cornice_ring at the eaves; kit_door arched (wood #6b4a32)
in the middle of the palace front, with kit_balcony (iron) over it on the first floor; kit_pilaster
pairs either side of the middle three bays; dormers with the kit's dormer part on both roofs.
Courtyard faces: plain kit_panes grid with sill ledges.

## Roof

Palace wing: tall hipped copper roof #7fa392 with small round-top dormers (white) in a row on
each slope. Side wing: red tile roof #b4553f, rows of white dormers, hipped at its far end. Both
roofs solid down to the cornice so the helicopter cannot pass under them.

## Colour and material

Palace render #eadcbf, ground floor #d9a66a, trim #f4f1ea, side wing #e8dcc2, copper #7fa392,
tiles #b4553f, glass #4a5660, door #6b4a32, balcony iron #2e3236. All M_STONE (glass by the kit).
No new material, light or node: one site mesh. No signs, crests, plaques or flags.

## Ground and night

Collision follows the outline. At night the main door glows warm; the rest stays dark. The
courtyard stays open (it is parking).

## Detail level and budget

L3 (a corner palace on Miodowa, seen from the W-Z route and Plac Zamkowy). Budget 5,000
triangles; set `"biskupow_krakowskich": 5000` in both game/tools/check_mesh_quality.gd BUDGET
and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| bk_palace | three storeys, rusticated base, cornice | 0-14.0 m | NE arm | M_STONE #eadcbf / #d9a66a | 2 |
| bk_portal | arched door, iron balcony, pilasters | middle 3 bays | palace street front | M_STONE #6b4a32 / #2e3236 | 2 |
| bk_copper | tall hipped roof with round-top dormers | 6.0 m | palace wing and corner | M_STONE #7fa392 | 3 |
| bk_wing | three storeys, cornice | 0-13.0 m | SW arm | M_STONE #e8dcc2 | 4 |
| bk_tiles | red tile roof with dormer rows | 5.0 m | side wing | M_STONE #b4553f | 4 |
| bk_windows | window grids, surrounds, string courses | 3.4 m bays | all faces | M_STONE / glass | 5 |
| collision | outline | full height | outline | (collider) | 1 |

As built, 2026-11-28: 4,884 triangles (budget 5,000), one site mesh, zero defects. Follows the 3D Tiles views and Street View: added the central attic pediment over the middle three bays of the NNE palace front (`face180`, `h225`), kept the ochre rusticated ground floor on the two street fronts while making the palace's courtyard and west-end ground floors cream (`h045`, `h090`), used `kit_dormer` (the kit's hip-capped dormer) for all 24 roof dormers (14 on the copper roof, 10 on the red tile roof), and paired `kit_window_grid` on the hero street-front storeys and east corner with `kit_panes` + unified white sill/string courses on secondary rows to stay under 5,000 triangles. Registers `replaces_photo_front = "b822"` to suppress the old photo front on the same outline.

