# Dom Poselski and Stary Dom Poselski (Wiejska 4/6/8, the Sejm complex)

Two sites in `game/scripts/landmarks/ujazdow.gd`: `dom_poselski` (`_find_dom_poselski`,
`_build_dom_poselski`) and `stary_dom_poselski` (`_find_stary_dom_poselski`,
`_build_stary_dom_poselski`). Modelling queue v2 row 8 (F, 2026-11-27: buildings with no model
first), Gemini lane; Ujazdów is one of the least modelled districts (8 %). Today both are only the
map's plain prisms next to the Sejm's own site (`sejm`, a FRONTS entry over "Sejm RP", which this
work does not touch).

Sources: Google 3D Tiles orbits, 2026-11-27 (`refs/dp_new/3dtiles/` for Dom Poselski,
`refs/dp_old/3dtiles/` for Stary Dom Poselski, `refs/dom_poselski/3dtiles/` wide), nine Street View
frames (`refs/dom_poselski/streetview/`, `refs/stary_dom_poselski/streetview/`); reference only,
gitignored, never copied. OpenStreetMap in `game/map/centrum.json`: landmarks "Dom Poselski"
(building 7893, 24.1 m, hotel) and "Stary Dom Poselski" (building 10848, 22.5 m; 10847 is the
drum at its east corner, 22-24.5 m). Find them by name and point, not by index.

## Identity

Two neighbours inside the Sejm complex. What makes them read as themselves from the iso camera:
1. Dom Poselski (the deputies' hotel, 1970s-80s): a stepped, roughly H-shaped grey block of seven
   storeys (24.1 m) in light grey concrete #a9aaa6, with long dark ribbon windows #2e3236 between
   pale spandrel bands on every storey.
2. Dom Poselski: blank, windowless concrete towers (stairs and lifts) at the corners and wing
   ends, a shade lighter #b9b9b4, rising 2-3 m above the roof: they cut the ribbons into short runs.
3. Dom Poselski: flat roofs crowded with plant boxes and vents; no ornament, no sign.
4. Stary Dom Poselski (1930s, built with the Sejm): six storeys of cream stone #ddd6c6 over a
   rusticated two-storey base #cfc7b5, dense vertical windows about 2.6 m apart, white frames,
   deep reveals, a string course over the base and a plain cornice at the top.
5. Stary Dom Poselski: a big rounded corner (a quarter drum, about 9 m radius) at the west end on
   Wiejska, and a smaller round drum at the east corner by the Sejm hall, with a round roof cap.
6. Stary Dom Poselski: a low hipped grey roof #74797b behind the cornice, with small dormers and
   chimney stacks.
7. Both: collision and ground contact follow the real outlines, so the player can drive round
   them along Wiejska and the complex's inner roads.

## Massing

- Dom Poselski: the landmark outline, simplified to its straight runs; ground = `_ground_under`.
  Body 0-24.1 m, seven storeys of 3.3 m over a 1.0 m plinth; the ground floor set back 1.0 m on
  the street faces with dark glass. Three to five service towers (each about 6 x 6 m) on the
  outline's outer corners, 0-26.6 m.
- Stary Dom Poselski: the landmark outline (its round corners stay round, at least 8 segments per
  quarter circle); ground = `_ground_under`. Base 0-7.0 m (rusticated), body to 22.5 m, cornice
  at 22.5 m, hipped roof 2.5 m high. The east drum (building 10847) rises to 24.5 m with a flat
  round cap.

## Facade

Kit parts only (facade_kit.gd).
- Dom Poselski: per storey per face, one dark glass ribbon (kit_panes, about 1.5 m tall, mullions
  every 1.5 m) over a pale spandrel band (kit_ledge or a kit_bands strip, #c3c4bf); the service
  towers plain wall, a thin cap ledge. Ground floor: kit_shop_bay glass on the south face toward
  the Sejm (the entrance), a thin flat canopy 2.5 m deep (#bfc3c6).
- Stary Dom Poselski: kit_window_grid (1.3 x 2.2 m windows, white frames #ece8de, glass #4a5660,
  bays 2.6 m) on every face, including round the curved corners (one window per curved segment);
  kit_bands rustication on the base; kit_ledge string course at 7.0 m; kit_cornice_ring at 22.5 m;
  the entrance on Wiejska (kit_door double leaf 2.4 x 3.2 m with a stone surround).

## Roof

- Dom Poselski: flat, membrane #8d969c, 0.8 m parapet; four to six plant boxes (2 x 4 m, 1.8 m
  tall, #6f767b).
- Stary Dom Poselski: low hipped roof in slate grey #74797b, a dormer every 7.8 m on the street
  slopes, three chimney stacks #8a7f74; the drums get a flat round cap ledge.

## Colour and material

Dom Poselski concrete #a9aaa6, towers #b9b9b4, spandrels #c3c4bf, glass #2e3236, roof #8d969c.
Stary Dom Poselski stone #ddd6c6, base #cfc7b5, frames #ece8de, glass #4a5660, roof #74797b.
All M_STONE; the entrance glass M_PAVILION (existing code). No new material, light or node: one
mesh per site. No signs, no names.

## Ground and night

Collision follows both outlines to full height. At night the entrance glass of both glows warm
(M_PAVILION); the rest stays dark. Leave the trees and the Sejm's courtyards as they are.

## Detail level and budget

L3 for both (they stand in the Sejm complex, one of the city's best-known places, and Stary Dom
Poselski fronts Wiejska right by the Sejm hall). Budgets: Dom Poselski 5,000 triangles (a large
but plain block), Stary Dom Poselski 7,000.
Set `"dom_poselski": 5000` and `"stary_dom_poselski": 7000` in both game/tools/check_mesh_quality.gd
BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| dp_body | prism of the outline | 0-24.1 m | Dom Poselski outline | M_STONE #a9aaa6 | 1 |
| dp_ribbons | kit_panes ribbon + spandrel band per storey | 7 storeys | every face | M_STONE #2e3236 / #c3c4bf | 1 |
| dp_towers | plain boxes | 6 x 6 m, 0-26.6 m | outer corners | M_STONE #b9b9b4 | 2 |
| dp_entrance | kit_shop_bay + canopy | ground floor | south face | M_PAVILION / #bfc3c6 | 1 |
| dp_roof | flat slab, parapet, plant boxes | 0.8 m parapet | 24.1 m | M_STONE #8d969c | 3 |
| sdp_base | rusticated base, string course | 0-7.0 m | Stary outline | M_STONE #cfc7b5 | 4 |
| sdp_body | prism with round corners | 7.0-22.5 m | Stary outline | M_STONE #ddd6c6 | 4, 5 |
| sdp_windows | kit_window_grid | 2.6 m bays | every face, round corners | M_STONE #ece8de / #4a5660 | 4 |
| sdp_cornice | kit_cornice_ring | 22.5 m | outline | M_STONE #ddd6c6 | 4 |
| sdp_roof | low hipped roof, dormers, chimneys | 2.5 m | over the body | M_STONE #74797b | 6 |
| sdp_drum | round drum and cap | to 24.5 m | east corner | M_STONE #ddd6c6 | 5 |
| sdp_door | kit_door + surround | 2.4 x 3.2 m | Wiejska face | M_STONE / M_PAVILION | 4 |
| collision | outlines | full height | both | (collider) | 7 |
