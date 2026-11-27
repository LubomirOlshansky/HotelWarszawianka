# Embassy row 1 on al. Ujazdowskie: Pałacyk Rembielińskiego, Willa Raua, Pałacyk Dziewulskich, Pałac pod Karczochem

Four small sites in `game/scripts/landmarks/ujazdow.gd`: `rembielinskiego`, `willa_raua`,
`dziewulskich` and `pod_karczochem` (`_find_<key>`, `_build_<key>`). Modelling queue v2 row 10
(F, 2026-11-27: buildings with no model first), Gemini lane; Ujazdów is one of the least modelled
districts (8 %). Today all four are the map's plain prisms in the villa belt of al. Ujazdowskie,
where the embassies sit.

Sources: Google Street View, 2026-11-27 (`refs/<key>/streetview/`; Pod Karczochem
`refs/pod_karczochem/`, Rembielińskiego `refs/rembielinskiego/`), Google 3D Tiles orbits for Willa
Raua and Dziewulskich (`refs/willa_raua/3dtiles/`, `refs/dziewulskich/3dtiles/`; the day's cap ran
out before the other two); reference only, gitignored, never copied. OpenStreetMap landmarks of the
same names in `game/map/centrum.json`: "Pałacyk Rembielińskiego" (10.9 m), "Willa Raua" (7.6 m),
"Pałacyk Dziewulskich" (7.6 m), "Pałac Pod Karczochem" (17.5 m). Find them by name.

## Identity

What makes each read as itself from the iso camera:
1. Pałacyk Rembielińskiego (al. Ujazdowskie, 1840s): a wide two-storey classical palace in pale
   cream #ddd6c4 with a raised middle and an entrance loggia of columns on the avenue, tall
   ground-floor windows, a balustraded parapet over a cornice, a low grey roof #7a8084.
2. Willa Raua (1860s Italianate villa): two storeys of cream render #e2dccb with rusticated
   corners, round-arched ground-floor door and windows, pedimented first-floor windows, a deep
   bracketed cornice and a low grey hipped roof #6f767b.
3. Pałacyk Dziewulskich: a compact two-storey villa in a garden, white-cream render #e6e1d3, a
   plain cornice and a low roof behind a parapet, a small porch on the avenue side.
4. Pałac pod Karczochem (Wiejska, a palatial 19th-century tenement): five storeys of cream render
   #ddd3bd with iron balconies, window surrounds, a corner turret topped by a stone artichoke
   (the karczoch) and a cornice; shops in the ground floor.
5. All four: collision and ground contact follow the real outlines along the avenue and Wiejska.

## Massing

Each from its landmark outline, simplified to straight runs; ground = `_ground_under`.
- Rembielińskiego: base 0-1.0 m, two storeys to 10.9 m (cornice), the middle third raised 1.5 m
  as an attic; balustrade 1.0 m on the cornice; low hipped roof 2.0 m.
- Willa Raua: plinth 0-0.8 m, two storeys to 7.6 m, cornice 0.6 m deep on brackets, hipped roof
  2.4 m.
- Dziewulskich: plinth 0-0.6 m, two storeys to 7.6 m, parapet 0.8 m, flat-ish roof 1.0 m.
- Pod Karczochem: ground floor 0-4.0 m (shops), four storeys to 17.5 m, cornice; the corner turret
  (about 5 m across) rises 3.0 m above the cornice with a domed cap and the artichoke finial
  (stacked kit or common.gd shapes, about 1.2 m tall).

## Facade

Kit parts only. kit_window_grid or kit_window rows on every face at about 3.0 m bays (villas
1.2 x 2.2 m windows, white frames #ece8de, glass #4a5660); kit_ledge string course between the
storeys; kit_cornice_ring at each eave; kit_pilaster for Rembielińskiego's loggia columns (four,
two storeys tall) and the rusticated corners of Willa Raua (kit_bands); kit_door for each main
entrance (Willa Raua round-arched, wood #6b4a32). Pod Karczochem: kit_shop_bay in the ground floor
on the street faces, small iron balconies (kit balcony part if the kit has one, else thin ledge +
rail) on the first and third floors.

## Roof

Low hipped roofs (`_hip`) in grey: Rembielińskiego #7a8084, Willa Raua #6f767b, Dziewulskich
#8a9094 (very low, behind its parapet), Pod Karczochem flat #7d8286 behind the cornice with the
turret cap #6c7277 and a cream artichoke finial.

## Colour and material

As above; all M_STONE, shop glass M_PAVILION (existing code). No new material, light or node:
one mesh per site. No signs, flags, embassy names or crests.

## Ground and night

Collision follows each outline. At night Pod Karczochem's shops glow (M_PAVILION); the villas'
door lights may glow warm; the rest stays dark. Leave the gardens and trees as they are.

## Detail level and budget

L2 for all four (good villas on the embassy avenue, seen among trees). Budgets: rembielinskiego
2,800, willa_raua 2,000, dziewulskich 1,600, pod_karczochem 2,800 triangles; set them in both
game/tools/check_mesh_quality.gd BUDGET and game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| rb_body | prism + raised middle attic | 0-10.9 m (+1.5 m) | Rembielińskiego outline | M_STONE #ddd6c4 | 1 |
| rb_loggia | four kit_pilaster columns, entablature | two storeys | avenue face, middle | M_STONE | 1 |
| rb_parapet | balustrade over kit_cornice_ring | 1.0 m | eave | M_STONE | 1 |
| wr_body | prism, rusticated corners (kit_bands) | 0-7.6 m | Willa Raua outline | M_STONE #e2dccb | 2 |
| wr_windows | arched ground floor, pedimented first floor | 3.0 m bays | every face | M_STONE / glass | 2 |
| wr_roof | bracketed cornice + hipped roof | 2.4 m | over the body | M_STONE #6f767b | 2 |
| dz_body | prism, plinth, porch | 0-7.6 m | Dziewulskich outline | M_STONE #e6e1d3 | 3 |
| dz_roof | parapet + low roof | 0.8 m + 1.0 m | over the body | M_STONE #8a9094 | 3 |
| pk_body | prism, shopfronts, balconies | 0-17.5 m | Pod Karczochem outline | M_STONE #ddd3bd / M_PAVILION | 4 |
| pk_turret | corner turret, domed cap, artichoke finial | +3.0 m, finial 1.2 m | street corner | M_STONE #6c7277 | 4 |
| roofs | hipped roofs, cornices | per building | all four | M_STONE | 1, 2, 3, 4 |
| collision | outlines | full height | all four | (collider) | 5 |
