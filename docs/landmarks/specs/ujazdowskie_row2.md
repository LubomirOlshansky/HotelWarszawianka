# Embassy row 2 on al. Ujazdowskie: Pałacyk Wielopolskich, Pałacyk Leszczyńskich, Ambasada Węgier, Kamienica Szelechowa, Ministerstwo Sprawiedliwości

Five sites in `game/scripts/landmarks/ujazdow.gd`: `wielopolskich`, `leszczynskich`,
`ambasada_wegier`, `szelechowa` and `ministerstwo_sprawiedliwosci` (`_find_<key>`, `_build_<key>`).
Modelling queue v2 row 18 (F, 2026-11-27: buildings with no model first), Gemini lane; Ujazdów is
one of the least modelled districts. Today all five are the map's plain prisms on the west side of
al. Ujazdowskie between Chopina and Plac na Rozdrożu; their fronts face the avenue (east, +x).

Sources: Google Street View, 2026-11-28 (`refs/<key>/streetview/`: the frames from the avenue,
headings 228-311, look west at the fronts; trees and a bus hide Wielopolskich and the Ministry), and
Mapillary / Panoramax photos (`refs/<key>/street/`); reference only, gitignored, never copied.
Google 3D Tiles orbits through Cesium ion, 2026-11-28 (`refs/<key>/3dtiles/`: eight orbit views,
four square-on faces and the top for each): where they and the text below disagree on massing,
heights or roof colour, the orbits win. OpenStreetMap landmarks of the same names in `game/map/centrum.json`:
"Pałacyk Wielopolskich" (10.9 m), "Pałacyk Leszczyńskich" (10.9 m), "Ambasada Węgier" (10.9 m),
"Kamienica Szelechowa" (14.2 m; the one at x about 0, z about 1318, not the Mikołaja one far west)
and "Ministerstwo Sprawiedliwości" (24.1 m). Find them by name.

## Identity

What makes each read as itself from the iso camera:
1. Ambasada Węgier (corner of Chopina): a white neo-renaissance palazzo #eeece6, three storeys over
   a rusticated base, the ground floor in deep round arches (doors and windows set back in them),
   stone balustrades under the first-floor windows, a strong cornice and a balustraded attic, a low
   grey roof #7d8286 behind it.
2. Pałacyk Leszczyńskich (next north of it): a cream #e3d8bc classical palace of three storeys,
   a grey stone plinth #b9b3a5, a ground-floor arcade of big round arches (an open loggia in the
   middle of the avenue front), white window surrounds, a balustrade over the cornice, grey roof.
3. Kamienica Szelechowa: a rich four-storey eclectic tenement in warm cream #e0d3ad, round-arched
   first-floor windows, stone balconies on brackets, pilastered corner bays, a heavy cornice, a
   dark grey roof #6f757a.
4. Pałacyk Wielopolskich: a two-storey classical palace in pale cream #e4dcc8 set back among trees,
   a pilastered middle with a low pediment, plain cornice, grey hipped roof #7a8084 (assumed from
   the type; the photos show little through the trees).
5. Ministerstwo Sprawiedliwości (by Plac na Rozdrożu): a large belle-époque block in cream render
   #e4dccb, six storeys over a rusticated ground floor #cfc6b2, rich window surrounds and balconies,
   a rounded or chamfered corner bay, steep grey metal mansards #7c8186 with dormers, and a main
   portal on the avenue (check the orbits for its shape and storeys).
6. All five: collision and ground contact follow the real outlines along the avenue.

## Massing

Each from its landmark outline, simplified to straight runs (only wiggles under 1.5 m);
ground = `_ground_under`; the avenue front is the outline's east (+x) side.
- Ambasada Węgier: base 0-4.5 m (arched, rusticated), two storeys to 13.0 m, cornice, balustraded
  attic 1.0 m, low hipped roof 2.0 m.
- Leszczyńskich: plinth 0-0.8 m, ground floor to 4.5 m with the arcade, two storeys to 13.0 m,
  cornice, balustrade 1.0 m, hipped roof 2.0 m.
- Szelechowa: ground floor 0-4.5 m, three storeys to 16.5 m, cornice, roof 3.0 m.
- Wielopolskich: plinth 0-0.8 m, two storeys to 10.9 m, middle risalit 1.0 m forward with a
  pediment 2.0 m, hipped roof 2.5 m.
- Ministry: rusticated ground floor 0-5.0 m, upper storeys to about 21 m, cornice, grey mansard
  about 4 m with dormers (heights from the orbits); portal on the avenue front.

## Facade

Kit parts only. kit_window_grid or kit_window rows on every face (palaces 1.3 x 2.4 m windows at
about 3.4 m bays, the Ministry 1.3 x 2.0 m at 3.2 m bays; white frames #f1eee6, glass #4a5660);
kit_bands for rusticated bases; kit_ledge string courses; kit_cornice_ring at each eave; kit_attic
balustrades (Ambasada, Leszczyńskich); kit_round_window or arched kit_window / kit_door for the
round-arched ground floors and arcade; kit_balcony stone balconies on Szelechowa; kit_pilaster for
the corner bays and Wielopolskich's middle; kit_pediment for Wielopolskich; kit_door for each main
entrance (wood #6b4a32) and the Ministry portal.

## Roof

Follow the orbits: green copper #7fa392 where they show it (Szelechowa and Wielopolskich roofs and
corner caps), otherwise grey: Ambasada and Leszczyńskich low or flat roofs #7d8286 behind their
balustrades, the Ministry's grey metal mansards #7c8186 with dormers.

## Colour and material

As above; all M_STONE. No new material, light or node: one mesh per site. No signs, flags,
embassy names, crests, plaques or emblems.

## Ground and night

Collision follows each outline. At night the main doors glow warm (M_PAVILION or M_LAMP lamp,
existing codes); the rest stays dark. Leave gardens, fences and trees as they are.

## Detail level and budget

L2 for the four palaces and the tenement (good buildings on the embassy avenue, seen among trees),
L3 for the Ministry (a whole large block on the avenue). Budgets: ambasada_wegier 2,800,
leszczynskich 2,800, szelechowa 2,800, wielopolskich 2,400, ministerstwo_sprawiedliwosci 5,000
triangles; set them in both game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd
BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| aw_body | arched rusticated base, two storeys, cornice, balustraded attic | 0-14.0 m | Ambasada outline | M_STONE #eeece6 | 1 |
| ls_body | plinth, arcaded ground floor, two storeys, balustrade | 0-14.0 m | Leszczyńskich outline | M_STONE #e3d8bc | 2 |
| sz_body | four storeys, arched first floor, balconies, corner bays | 0-16.5 m | Szelechowa outline | M_STONE #e0d3ad | 3 |
| wp_body | two storeys, pilastered middle, pediment | 0-10.9 m (+2.0 m) | Wielopolskich outline | M_STONE #e4dcc8 | 4 |
| ms_body | rusticated base, upper storeys, corner bay, mansard, portal | 0-25.0 m | Ministry outline | M_STONE #d9d4c8 | 5 |
| roofs | hipped and flat roofs, cornices | per building | all five | M_STONE | 1, 2, 3, 4, 5 |
| collision | outlines | full height | all five | (collider) | 6 |
