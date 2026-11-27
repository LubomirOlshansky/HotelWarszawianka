# Polskie Radio (Myśliwiecka 3/5/7)

Site key `polskie_radio` in `game/scripts/landmarks/ujazdow.gd` (`_find_polskie_radio`,
`_build_polskie_radio`). Modelling queue v2 row 6 (F, 2026-11-27: buildings with no model first),
Gemini lane; Ujazdów is one of the least modelled districts (8 %). Sources: Google 3D Tiles orbit,
face and top views, 2026-11-27 (`refs/polskie_radio/3dtiles/`), six Street View frames
(`refs/polskie_radio/streetview/`, mostly trees); reference only, gitignored, never copied.
OpenStreetMap: landmark "Polskie Radio" (a long north-south block, about 130 x 18 m with a wider
middle and a short west wing) over buildings 11968, 11969, 11970 (10.9 m, office); find by name.

## Identity

The public radio's headquarters on Myśliwiecka, by Agrykola and the Legia stadium. What makes it
read as itself from the iso camera:
1. A long, plain three-storey block (about 130 m) with pale cream render #d8d0bd and a regular
   rhythm of tall windows, about 2.8 m apart, three rows.
2. A steep grey hipped roof #6c7277 (slate) over the whole length, with a row of small flat dormers
   / skylights along both slopes; the roof is as tall as a storey.
3. The middle steps out (the wider part of the outline) with the main entrance on Myśliwiecka: a
   simple stone surround and a canopy, a flagpole pair, a plain `RADIO` sign over the door (the broadcaster's own logo is not used).
4. A plinth band and a plain cornice; no ornament. Trees all round.

## Massing

The landmark outline, simplified to its straight runs. Ground = `_ground_under`. Plinth 0-0.8 m,
three storeys 0.8-10.9 m (3.35 m each), cornice at 10.9 m, hipped roof rising 3.6 m to a ridge
along the long axis (hip ends at both short ends and on the short west wing). Height to the eaves
matches the map's 10.9 m.

## Facade

Kit parts only. Every long face:
- kit_window_grid: three rows of tall windows (1.3 x 2.0 m, white frames #e6e3db, glass #4a5660),
  bays 2.8 m, skipping the entrance bay.
- kit_ledge plinth band #a9a394 0-0.8 m; kit_cornice_ring at 10.9 m #e3ddcd, 0.4 m proud.
- Entrance (east face on Myśliwiecka, middle of the wider part): kit_door double leaf 2.4 x 3.0 m,
  a stone surround #cfc6b1, a thin flat canopy 2.0 m deep; the word `RADIO` (white, M_LAMP,
  0.7 m letters, common.gd _usign) over it.
- Short ends: the same window grid, two to four bays.

## Roof

A hipped roof (kit or common.gd _hip if present, else sloped prisms) in slate #6c7277, 3.6 m high
over a 10.9 m eave; a row of small flat dormers (1.2 m wide, 0.9 m tall, dark glass) every 5.6 m on
both long slopes; two chimney blocks #8a7f74.

## Colour and material

Render #d8d0bd, plinth #a9a394, cornice #e3ddcd, surround #cfc6b1, frames #e6e3db, glass #4a5660,
roof #6c7277, chimneys #8a7f74, canopy #bfc3c6, sign white. All M_STONE; the sign M_LAMP; no new
material, light or node: one site mesh.

## Ground and night

Collision follows the outline. At night the sign glows white and the entrance glass warm
(M_PAVILION); the office windows stay dark. Leave the trees round the building as they are.

## Detail level and budget

L2 (a well-known institution in the park belt along Agrykola). Budget 3,000 triangles; set
`"polskie_radio": 3000` in both game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pr_body | prism of the simplified outline | 0-10.9 m | landmark outline | M_STONE #d8d0bd | 1 |
| pr_plinth | ledge band | 0.8 m | foot | M_STONE #a9a394 | 4 |
| pr_windows | kit_window_grid, 3 rows | 1.3 x 2.0 m, bays 2.8 m | all faces | M_STONE / #4a5660 | 1 |
| pr_cornice | kit_cornice_ring | 0.4 m proud | 10.9 m | M_STONE #e3ddcd | 4 |
| pr_roof | hipped roof | rise 3.6 m | over the outline | M_STONE #6c7277 | 2 |
| pr_dormers | small flat dormers | 1.2 x 0.9 m every 5.6 m | both long slopes | M_STONE | 2 |
| pr_entrance | kit_door, surround, canopy | 2.4 x 3.0 m door | east face, middle | M_STONE / M_PAVILION | 3 |
| pr_sign | `RADIO` letters | 0.7 m | over the door | M_LAMP | 3 |
| pr_collision | outline | full height | outline | (collider) | 1 |
