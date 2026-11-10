# Zamek Ostrogskich and the Chopin Institute (Tamka 41): spec

Site key `ostrogski` in `game/scripts/landmarks.gd` (`_find_ostrogski`, `_build_ostrogski`).
Written 2026-11-01 in a cloud thread from the two OpenStreetMap outlines in `centrum.json`
("Zamek Ostrogskich" and "Narodowy Instytut Fryderyka Chopina"); no photo, no LoD2 here, so
heights and details are estimates. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

A 17th-century palace complex above the Vistula escarpment, rebuilt after 1945; today the
Fryderyk Chopin Museum has its modern interior inside it. Two blocks round a courtyard.

1. **Cream plaster walls** with a stone plinth and a cornice.
2. **Steep red-brown hipped roofs** with dormers, and cross gables on the castle's middle bays.
3. **A round corner turret** with a cone cap (castle block).
4. **The museum block's door** under a small columned porch on the courtyard side.

## 2. Massing

Castle block: outline centre (-70.3, -274.2), u (0.947, -0.321), 14 x 25 m (middle bays 1 m
proud on both long faces). Museum block: centre (-112.86, -268.13), u (-0.988, 0.156), 22 x 17 m.
Heights above the ground *(estimate)*: plinth 1.0 m; castle walls to 10.0 m, cornice to 10.6 m,
hip roof ridge 16.6 m, cross gables to 15.2 m, turret drum to 13.6 m with a cone to 21.0 m;
museum walls to 9.2 m, roof ridge 14.8 m, porch columns to 4.7 m.

## 3. Facade, base to top

- **Plinth**: 2 m stone band (1 m below ground).
- **Walls**: the mapped outline raised in plaster (M_MONUMENT draws the tall windows).
- **Cornice**: the outline grown 0.35 m, 0.6 m tall.
- **Porch** (museum, courtyard face): two round columns, a stylobate, an entablature, a small
  pediment, a dark glass door *(photo check: which door and face is the real entrance)*.

## 4. Roof

Castle: hip over 16.4 x 25.8 m rising 6.0 m, a cross gable on each middle bay (pediment face in
wall plaster, a dark window in it), 8 dormers, two chimneys. Museum: hip rising 5.0 m, 4
dormers, one chimney. The turret is on the north-west corner *(photo check: which corner, whether
there is one tower or several, and the real roof forms)*.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #e4d3ae | M_MONUMENT |
| Cornice, columns, turret ring | #efe6d0 | M_STONE |
| Plinth, stylobate, chimneys | #a89d89 | M_STONE |
| Roofs, turret cone | #8a4a3a | M_STONE |
| Windows in dormers and gables, door | #3a3f42 | M_GLASS |
| Turret ball | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

The car is stopped by the two mapped outlines (the courtyard stays open). Card: "Zamek
Ostrogskich", PL "Pałac nad skarpą na Tamce; w nim Muzeum Fryderyka Chopina.", EN "A palace on
the Tamka escarpment, home of the Fryderyk Chopin Museum." Windows light at dusk through the wall
shader like any other plastered building.

## 7. Detail level and budget

L2, triangle budget 870 (724 measured, plus about 20 %, in `check_mesh_quality.gd`). Shots:
`--at=-90,-262 --heading=0 --size=28` with `--time=day` and `--time=dusk`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | band round the outlines | 2 m (1 m below ground) | both blocks | M_STONE | 3 facade |
| walls | raised outlines | castle to 10.0 m, museum to 9.2 m | the mapped outlines | M_MONUMENT | 2 massing |
| cornice | outline grown 0.35 m | 0.6 m tall | on the walls | M_STONE | 3 facade |
| castle_roof | hip with cross gables | 16.4 x 25.8 m, ridge 16.6 m | castle block | M_STONE | 4 roof |
| museum_roof | hip | ridge 14.8 m | museum block | M_STONE | 4 roof |
| dormers | small gabled boxes | 8 castle, 4 museum | on the roofs | M_STONE, M_GLASS | 4 roof |
| turret | drum and cone with a ball | drum to 13.6 m, cone to 21.0 m | castle's north-west corner | M_MONUMENT, M_STONE | 2 massing |
| porch | two columns, entablature, pediment | columns to 4.7 m | museum, courtyard face | M_STONE, M_GLASS | 3 facade |
| chimneys | boxes | over the ridges | 2 castle, 1 museum | M_STONE | 4 roof |

## Rebuild from F's photos (2026-11-09)

F's Mac set `powisle/M01-M05, B13`: the castle is white (#ece8dc) with grey stone quoins
(#c4beb1) at the corners and the middle bays, orange tiled roofs (#b4664a), a statue on each
pediment, and stands on a red-brick bastion (#a1503a) with a white balustrade towards Tamka (built
where the ground there is more than 1.2 m lower). There is no turret: removed. The Institute
next door is a modern block: a 6 m stone base (#d8d4ca) and a blue-green glass tower (#7fb3b0)
to 26 m. Left: the double stairs from Tamka, the garden terrace's balustrades and lamps.
