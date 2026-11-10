# Smolna 38: spec

Site key `smolna38` in `game/scripts/landmarks.gd` (`_build_smolna38`, constants `S38_`). Written 2026-11-08 from F's own photos (refs/smolna38/: f1 the street front by day, f2 and f4 the gate, f6 the club door at night) and OSM relation 2983897 (`building=office`, `historic=yes`, 4 levels, LoD2 14.2 m), found at `S38_AT` and kept for the streamed path by `tools/bake_sectors.py` SITE_AREAS. The Smoła club's house; the club queue and doormen are the crowd worker's (`club.gd`, `crowds.gd`). Only the street front is detailed; the other faces are plain.

## 1. Identity

1. The grey rusticated ground floor with a deep rectangular gate.
2. The big curved, fluted stone cartouche over the gate carrying a two-storey oriel and a third-floor balcony with a thin iron railing.
3. Three cream plaster floors with grey stone window surrounds, triangular pediments on the first-floor windows beside the bay, seven window axes.
4. The club dressing: a plank awning, two black pop-up tents, steel crowd barriers, a "GUEST LIST" banner, red light in the gate at night.

## 2. Massing

The mapped outline, simplified to 0.35 m (its two 0.2 m jogs in the street front would bury the windows), to 14.2 m over the ground with a stepped cornice and a flat grey roof; the courtyard is not cut out. The street front is the edge from (-164.4, 158.1) to (-140.7, 149.9), 25.08 m, outward normal (0.327, 0.945). Local frame: origin at its west end, u east along it, v out.

## 3. Facade, base to top

Ground floor 4.2 m: dark plinth 0.9 m, grey stone with bed joints every 0.45 m, windows (1.2 x 1.8 m) under flat splayed-voussoir lintels, basement windows in the plinth, a cornice band to 4.55 m. Floors at 3.1 m: window axes at u 1.8, 5.1, 8.4, 11.7, [bay at 15.0], 18.3, 21.6; frames white, surrounds grey, sills; pediments on the first floor at u 11.7 and 18.3. Gate at u 15.0, 3.2 m wide, 3.9 m high, 4 m deep, dark leaves folded on its sides. Cartouche: five stacked curved layers, 3.5 m wide and 1.15 m out at the top, fluted. Oriel: u 13.3 to 16.7, 0.7 m out, floors 1-2; balcony slab 1.2 m out with a 0.95 m railing on floor 3. Blue number plate "38" at u 17.4. Red-brown drainpipe at u 24.2. Cornice 0.85 m, stepped.

## 4. Roof

Flat grey deck at 14.2 m with two chimney stacks (the ortho was not consulted: not shown on the photos).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #d6c6a6 | M_STONE |
| Ground stone, surrounds | #a8a49c | M_STONE |
| Plinth | #7d7a74 | M_STONE |
| Frames | #ece9e2 | M_STONE |
| Glass | #2e3640 | M_GLASS |
| Gate interior | #d42a1c | M_LAMP |
| Tents, banner | #17171a | M_STONE |

No new material or draw call.

## 6. Ground and night

On the pavement: the plank awning under the cartouche, tents at u 19.6 and 22.7 (v 0.5 to 3.5), barriers along the kerb side and one left of the gate with the banner. At night the gate passage glows red (M_LAMP) and windows light through M_GLASS.

## 7. Detail level and budget

L2 with the street front's identity features modelled, triangle budget 2700 (`check_mesh_quality.gd` BUDGET entry to add: built 2208).

Shots: `--at=-152,167 --size=22` by day and `--time=night --clock=01:00`, runtime and `--prebuilt`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | notched ring prisms, stepped cornice | 25 m front, 14.2 m | the outline | M_STONE | 3 floors |
| rustication | thin groove strips | 0.45 m pitch | ground floor, u 0 to 25 | M_STONE | 1 ground floor |
| windows | frames, glass, surrounds, sills | 1.2 x 1.75 m | six axes, three floors | M_STONE, M_GLASS | 3 floors |
| pediments | wedges on cornices | 2.2 m wide | first floor, u 11.7 and 18.3 | M_STONE | 3 floors |
| gate | notch, red walls, leaves | 3.2 x 3.9 x 4 m | u 15.0 | M_STONE, M_LAMP | 1 gate |
| cartouche | five curved prisms, flutes | 3.5 x 1.15 x 1 m | over the gate | M_STONE | 2 cartouche |
| oriel_balcony | box, slab, railing | 3.4 x 0.7 m, slab 3.8 x 1.2 m | u 15.0, floors 1 to 3 | M_STONE | 2 cartouche |
| plate_pipe | plate, digits, pipe | 0.45 x 0.3 m | u 17.4, u 24.2 | M_STONE | 1 ground floor |
| awning | six planks | 3.8 x 2 m | v 0.3 to 2.5, y 3 m | M_STONE | 4 club |
| tents | legs, canopy, curtains | 3 x 3 x 2.9 m | u 19.6 and 22.7, v 2 | M_STONE | 4 club |
| barriers_banner | rails, bars, lettering | 2.1 m each | kerb side v 3.85; banner u 10.1 to 12.3 | M_STONE | 4 club |
