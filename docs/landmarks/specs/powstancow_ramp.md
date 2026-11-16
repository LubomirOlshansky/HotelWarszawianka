# Plac Powstańców Warszawy car park entry: spec

Site key `powstancow_ramp` (a `SUNKEN` entry of style "ramp" in `game/scripts/map_builder.gd`,
built by `_build_sunken` in `game/scripts/landmarks/centre.gd`; its mouth in `GARAGE_MOUTHS`;
its WJAZD board in `game/scripts/centralny_ramp.gd`). Written 2026-11-16 in a cloud thread from
F's two photos of the entry and Mapillary frames of the square (`refs/kilinski_plac`); reference
only, never shipped. It replaces the blurred pit of the 10 m ground grid, the asphalt road that
wandered into it and the roller shutter that floated halfway down.

## 1. Identity

1. A straight ramp down into the ground between light concrete walls shaped like a U, on the
   square's west side by Świętokrzyska (F's photos).
2. A dark board over the way in with WJAZD, the no-entry and limit signs and a green count of the
   free places (235) (F's photos).
3. The dark mouth under a concrete hood at the foot, with a barrier.

## 2. Massing (heights over the grid at the top)

The ramp 5.2 m wide and 26 m long, falling 3.5 m from the top at the north to the mouth at the
south; walls 1.0 m over the square round the top, 12.9 m rim; the hood over the mouth 2.6 m
deep.

## 3. Facade, base to top

- **Walls**: light concrete #cdcac2, a lighter coping on top, down both sides and round the top.
- **Floor**: grey setts #8b8d8e with darker ribs across.
- **Mouth**: a dark opening under the hood with a yellow and black band, a barrier and a P board.
- **WJAZD board**: dark, 5.6 x 0.8 m, 3.35 m over the floor at the mouth, facing up the ramp: a
  no-entry disc, two red-rimmed limit discs, WJAZD in white, 235 in green.
- **Gauge**: a height bar at the top of the ramp.

## 4. Roof

The hood's flat top, level with the square; the rest is open.

## 5. Colour and material

Walls #cdcac2 (M_STONE), their tops a shade lighter; floor #8b8d8e, ribs a shade darker; the
board #2a2f35, its letters #f2f2ee, the count #3fe07a (M_LAMP, lit at night). No new material, no
shader change.

## 6. Ground and night

The ramp's floor is drivable down to the mouth, the walls collide, the mouth's barrier is solid.
The square's lamps light the top; the green count glows at night.

## 7. Detail level and budget

L1 (a street feature seen from above). About 1,100 triangles with the walls, the setts and the
mouth; budget 1500 (check_mesh_quality BUDGET "powstancow_ramp"); no draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| floor | sloped strips | 5.2 x 26 m | the ramp | M_STONE #8b8d8e | 1.1 ramp |
| ribs | strips | 0.2 m across | on the floor | M_STONE #80827f | 1.1 setts |
| walls | prisms | 0.3 m thick, to 1 m over the square | both sides and the top | M_STONE #cdcac2 | 1.1 U walls |
| hood | box | 6 x 2.6 m | over the mouth | M_STONE #cdcac2 | 1.3 mouth |
| mouth | quad | 5.2 x 2.4 m | the foot | dark | 1.3 mouth |
| barrier | box | 4.8 m | in the mouth | M_STONE red and white | 1.3 barrier |
| WJAZD board | box | 5.6 x 0.8 m | over the floor at the mouth | M_STONE #2a2f35 | 1.2 board |
| board text | pixel faces | 0.5 m letters | on the board | M_LAMP #f2f2ee, #3fe07a | 1.2 WJAZD 235 |
| gauge | bar | 5.2 m | the top of the ramp | M_STONE yellow and black | 1.3 entry |

## 9. Not built, and what only the phone can show

- The glass pavilion beside the ramp (the car park's lift), the ramp's handrails.
- Phone: whether the board reads from the default camera, and whether a car can drive down to
  the mouth without catching a wall.
