# Kościół Świętego Krzyża (Holy Cross): spec

Site key `sw_krzyz` in `game/scripts/landmarks.gd` (`_build_krzyz`, `_krzyz_tower`). Written
2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` and the
church's well-known baroque front (no photo here). The nave and transepts stay the kept
LoD2 skin; the model adds the street front and the two towers. Values marked *(photo check)*
wait for the Mac's `refs/`.

## 1. Identity

Bellotti's baroque church (1679-1696, rebuilt after 1944) on Krakowskie Przedmieście, where
Chopin's heart rests in a pillar.

1. **Two square towers** at the ends of the front, each with a belfry and a copper onion helm
   carrying a lantern, a ball and a cross (about 48 m).
2. **A central block** between them with a portico of four giant columns and a statue over
   each, an upper storey of tall windows and a triangular pediment with an oculus.
3. **A cream plaster front** with white trim and a pale stone base.

## 2. Massing

Plan frame: origin (-456.1, -510.0), the front's south end on the outline; u along the front
(axis (-0.323, -0.946), 31.3 m, to the north), +v out of it to the street (east, (0.946, -0.323)).
Towers 8.6 x 9.2 m at u 4.4 and 26.9, reaching back to v -8.7 (the outline's two bumps). The
central block u 8.9..22.4. Heights above the ground: plinth 1.6 m, tower shaft 22 m, belfry to
31.4 m, helm to 40.5 m, lantern to 45.6 m, cross to 48.6 m; central block 21 m, pediment apex
25.1 m, cross 27.6 m. The transept and choir outline (u 4..40, v -25..-63) stays the skin.

## 3. Facade, base to top

- **Base**: pale stone plinth 1.6 m, 0.5 m proud, all along the front; a stylobate 1.8 m deep
  with two steps in front of the portico.
- **Ground floor**: plaster with three dark doors (2.2 x 4.6 m) *(photo check: count)*.
- **Columns**: four, r 0.58 m, 10 m tall, at u 15.65 ± 2.0 and ± 5.6, v 1.7, over a stepped
  entablature (11.2..13 m) with a statue block over each column (2.4 m).
- **Upper storey** (13..21 m): the monument shader's tall windows between piers.
- **Tower shaft**: plinth, plain shaft to 13 m, trim band, second stage with a window on the
  front and back, a double cornice at 22..23.4 m.
- **Belfry** (23.4..31.4 m): windows (monument shader) between four corner piers, cornice.

## 4. Roof

Top cornice, then the pediment (3.2 m rise, copper-green slopes) with a dark oculus (r 0.8 m)
and a gilt cross. Tower helms in copper: an octagonal drum, the onion swell to r 4.0 m, a
taper to a white lantern (r 1.1 m, windows), a cap, a gilt ball and cross.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster front, tower shafts | #e6dcc2 | M_STONE, M_MONUMENT (upper storey, belfries) |
| Trim, columns, cornices, lanterns | #f1ebdc | M_STONE |
| Plinth, stylobate, steps | #bdb39c | M_STONE |
| Helms, pediment slopes | #6a9a8a | M_STONE |
| Doors, tower windows, oculus | #3a3d40 | M_GLASS, M_STONE |
| Ball and crosses | #c9a24a | M_STONE |

No new material or draw call: everything goes into the city's building surface.

## 6. Ground and night

The street is the map's. The car is stopped by the stylobate (one ring, 13.8 x 2.8 m) and the
church's own mapped walls. Card (kept): "Kościół Świętego Krzyża", PL "W filarze kościoła
spoczywa serce Chopina.", EN "Chopin's heart rests in one of its pillars." Open: the Christ
statue with the cross beside the steps, the dome over the crossing *(photo check)*.

## 7. Detail level and budget

L3 for the front and towers, L1 for the rest, triangle budget 1100 (934 measured, plus about
18 %, in `check_mesh_quality.gd`). Shots: `--solo=sw_krzyz --solo-look=lit`, then in the city
from Krakowskie Przedmieście.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | 3 boxes | 1.6 m tall | all along the front | M_STONE | 3 base |
| front_low | box | 13.5 m wide | y 0..12.9 | M_STONE | 3 ground floor |
| front_up | box | 13.5 m wide | y 13..21 | M_MONUMENT | 2 upper storey |
| doors | 3 panels | 2.2 x 4.6 m | u 15.65, ±3.8 | M_GLASS | 3 ground floor |
| columns | 4 on 8-sided shafts | r 0.58, 10 m | u 15.65 ± 2.0, ± 5.6 | M_STONE | 2 portico |
| statues | 4 blocks | 1 x 1 x 2.4 m | over the columns | M_STONE | 2 portico |
| pediment | gable | 14 m, rise 3.2 | y 21.9 | M_STONE | 4 pediment |
| towers | 2 stacks of boxes | 8.6 x 9.2 m | u 4.4 and 26.9 | M_STONE, M_MONUMENT | 1 towers |
| helms | 2 x 5 frusta, drum, cap | r 3.4..4.0 m | y 32.3..45.6 | M_STONE | 1 towers |
| crosses | 3 | 0.4 m bars | tower tips, apex | M_STONE | 1 towers |

## Update

Photo pass 2026-11-06 (refs/sw_krzyz 1-2): the photos show no giant portico. The front between the towers is a flat two-storey wall with paired pilasters, a small portal (two columns, entablature and a pediment) in the middle, pedimented lower windows, capped upper windows and a great round-headed window, a cornice, a curved stepped attic with the cross, a balustrade across the whole front with the steps open in the middle, the black "Sursum corda" plinth with the bronze Christ left of the portal; the towers gain corner pilasters and darker copper (`#5a8a78`). Replaces the four-column portico below.
