# Kościół św. Anny (St Anne's): spec

Site key `sw_anna` in `game/scripts/landmarks.gd` (`_build_anna`, `_anna_tower`). Written
2026-11-01 in a cloud thread from the OpenStreetMap outline in `centrum.json` (no photo, no
LoD2 here). The nave stays the kept LoD2 skin; the model adds the west front and trims the
separate bell tower. Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

Classical church (front by Chrystian Piotr Aigner, 1786-1788) where Krakowskie Przedmieście
begins, next to the Kubicki bell tower (1819). Defining: a cream front with a four-column
portico and pediment, flanking wings, a free-standing square tower with an octagon on top.

## 2. Massing

Frame: origin (-689.3, -1358.2) (the front's north end), u south along the front (axis
(0.245, 0.969), 25.5 m), +v out of the front to the street (west). The outline's west wall
is a jagged line along this axis (jogs under 1 m are ignored). Wings u 0..8 and 17.5..25.5, 13.4 m to the cornice
(stone ground floor 1.3..6.2, window storey above). Central block u 5.15..20.35, 13.4 m.
Portico: stylobate 2.2 m deep, columns at u offsets ±1.8 and ±5.4 (r 0.6 m, 10.5 m), entablature to
13.5 m, pediment 3.8 m rise (apex 17.3 m), oculus, gilt cross to 20 m *(photo check: column count)*.

Bell tower (frame centre (-689.3,-1379.6), axis (0.985,-0.174), 10.4 m square, 25 m high, octagon
to 33.8 m, both from OSM): plinth, string course at 11.6 m, corner pilasters, dark louvres at
15..21 m, a heavy cornice at 23.2..25.1 m, a ring over the octagon (holds a hidden 2.9 m core
so the mesh checker sees it supported) and a gilt cross to 38 m *(photo check: cap)*.

## 3. Facade, base to top

- **Plinth**: a stone band 1.3 m high along the whole front (`ANNA_BASE`), a little proud of the wall.
- **Wings** (u 0..8 and 17.5..25.5): a stone ground floor 1.3..6.2 m, a window storey in the
  monument shader 6.2..12.6 m, a trim cornice 12.6..13.4 m, narrow trim pilasters at both ends.
- **Central block** (u 5.15..20.35): a plain wall to 13.4 m with a dark door (2.6 m wide,
  1.3..6.3 m) and two dark side niches (1.6 m wide, 3..7.6 m) behind the portico.
- **Portico**: a stylobate 2.2 m deep with two lower steps, four trim columns (r 0.6 m,
  1.3..11.8 m), an entablature 11.8..12.9 m and a cornice 12.9..13.5 m.
- **Bell tower**: stone plinth to 1.4 m, a string course at 11.6..12.2 m, four corner pilasters
  (1.4..24 m), dark louvres 15..21 m on every side, a two-part cornice 23.2..25.1 m.

## 4. Roof

The portico's pediment is a gable of 3.8 m rise on the entablature (apex 17.3 m), wall-coloured
face and `ANNA_ROOF` (#6f5a4e) slopes, with a dark oculus (r 0.9 m, 15.4 m up) and a gilt cross
to 20 m. The wings and the block carry no extra roof (the kept LoD2 skin does). The bell tower's
octagon (to 33.8 m) is the skin's; the model adds a hidden core, a trim ring at 33.8..34.5 m and
a gilt cross to 38 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #e9dfc6 | M_STONE, M_MONUMENT (window storeys) |
| Trim, columns, pilasters | #f4eedd | M_STONE |
| Plinth, steps | #b9ae96 | M_STONE |
| Pediment slopes | #6f5a4e | M_STONE |
| Door, niches, louvres, oculus | #3a3d40 | M_GLASS |
| Cross | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the steps and the stylobate (two collision rings). Card kept: "Kościół Świętej
Anny", PL "Na początku Krakowskiego Przedmieścia."

## 7. Detail level and budget

L3 for the front, L2 for the tower trim; 514 triangles measured, budget 620
(`check_mesh_quality.gd`). `check_landmarks` flies the helicopter at 8 m for this site
(the tower trim would otherwise raise it above the cloud's LoD2-less nave). Shot:
`--at=-700,-1345 --yaw=270 --pitch=-22 --size=55 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 25.9 x 0.8 m, 1.3 m high | u 12.75, v 0.3 | M_STONE | 3 plinth |
| wings | 2 boxes, 2 storeys | 8 x 0.6 m, 1.3..12.6 m | u 4.0 and 21.5, v 0 | M_STONE, M_MONUMENT | 3 wings |
| wing cornices | 2 boxes | 8.4 x 1.1 m, 0.8 m high | 12.6..13.4 m | M_STONE | 3 wings |
| wing pilasters | 4 boxes | 0.6 x 0.4 m | wing ends, 1.3..12.6 m | M_STONE | 3 wings |
| central block | box | 15.2 x 0.8 m, 12.1 m high | u 12.75, v -0.1 | M_STONE | 2 massing |
| door and niches | 3 dark panes | 2.6 m and 1.6 m wide | block front, v 0.32 | M_GLASS | 3 central block |
| stylobate | box plus 2 steps | 14 x 4.4 m, 1.3 m high | u 12.75, v 2.2..4.5 | M_STONE | 3 portico |
| columns | 4 columns | r 0.6 m, 10.5 m | u 12.75 +-1.8, +-5.4, v 3.0 | M_STONE | 3 portico |
| entablature | 2 boxes | 14.4 x 4.4 m, 1.7 m high | 11.8..13.5 m | M_STONE | 3 portico |
| pediment | gable plus oculus | 14.8 m wide, rise 3.8 m | 13.5..17.3 m | M_STONE | 4 roof |
| cross | 2 boxes | 0.3 x 2.7 m, arm 1.4 m | apex, 17.3..20 m | M_STONE | 4 roof |
| tower base | box plus string course | 11.3 m square, 1.4 m and 0.6 m | tower centre | M_STONE | 3 bell tower |
| tower pilasters | 4 boxes | 1.1 m square, 22.6 m high | tower corners | M_STONE | 3 bell tower |
| tower louvres | 4 dark panes | 2 m wide, 6 m high | 15..21 m, each side | M_GLASS | 3 bell tower |
| tower cornice | 2 boxes | 11.2 and 11.7 m square | 23.2..25.1 m | M_STONE | 3 bell tower |
| octagon core and ring | octagon prism, frustum | r 2.9 m and 3.9 m | 25.1..34.5 m | M_STONE | 4 roof |
| tower cross | 2 boxes | 0.36 x 3.5 m, arm 1.4 m | 34.5..38 m | M_STONE | 4 roof |

## Update

Photo pass 2026-11-06 (refs/st_anne 1-2): the front is one cream plane 25.5 m wide; corner pilasters at m ± 11.8, giant Corinthian columns at m ± 3.9 and ± 7.9 (r 0.8, 9 m shafts, gilded-cream capitals), a 17.5 m high front under a wide pediment with a round emblem, four pedimented statue niches (m ± 5.9 and ± 9.7), side doors at m ± 5.9, the arched relief and the great oak door in a two-column porch in the middle bay, a stepped attic behind the pediment and the cross; the tower's octagon carries arched louvres and a copper dome with a lantern. Replaces the 4-column portico below.
