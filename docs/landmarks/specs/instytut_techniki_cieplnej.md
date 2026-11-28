# Instytut Techniki Cieplnej PW (Nowowiejska 21/25)

Site key `itc` in `game/scripts/landmarks/srodmiescie.gd` (`_find_itc`, `_build_itc`). Modelling
queue v2 row 16 (F, 2026-11-27: buildings with no model first), Gemini lane, together with Gmach
Chemii (spec `gmach_chemii.md`). Today it is the map's plain prisms (10.9-17.5 m).

Sources: Google Street View, 2026-11-28 (`refs/itc/streetview/`: the three `1qa...` frames from
Nowowiejska show the front with its portal and the two canopies); reference only, gitignored, never
copied. No 3D Tiles orbit (the day's cap was spent): the back follows the outline and the type.
OpenStreetMap: landmark "Instytut Techniki Cieplnej" (33 nodes, about 70 x 82 m); find it by name.

## Identity

The 1950s Institute of Heat Engineering of the Politechnika on Nowowiejska, a big socialist-realist
block. What makes it read as itself from the iso camera:
1. A long, even, pale beige front #d8cfb9 on Nowowiejska: six storeys of plain rectangular windows
   (white frames) in a strict grid, a light stone-clad ground floor #e6e1d4, a simple crowning
   cornice.
2. In the middle a tall stone portal #ece8de: three big wooden doors #6b4a32 in deep stone
   surrounds under a plain frieze, up a broad flight of steps across the front.
3. Two modern dark grey-glass canopies #3e4448 sloping out over the side entrances near the front's
   ends.
4. Lower back wings round a courtyard (same render), seen only from the air.

## Massing

The landmark outline; ground = `_ground_under`. The front is the run along Nowowiejska on the
outline's north side, roughly from (-1016, 1563) to (-953, 1566); work out the front block and the
back wings from the outline itself, simplifying only short wiggles (under 1.5 m).
- Front block: about 14 m deep along the north side, 0-20.5 m (ground floor 0-4.5 m, five upper
  storeys of 3.2 m), cornice 0.6 m, low hipped roof 2.5 m.
- Back wings: round an open courtyard, 0-14.0 m (four storeys), cornice, low hipped roofs 2.0 m.
- Portal: 12 m wide in the middle of the front, 0-7.5 m, stepping forward 0.6 m; steps 1.2 m over 4 m
  in front of it, across about 30 m of the front.
- Canopies: two thin sloping roofs about 8 x 4 m at 4.0-5.0 m, one near each end of the front.

## Facade

Kit parts only. kit_window_grid on every outer face (1.3 x 1.9 m windows, white frames #f1eee6,
glass #4a5660, bays about 3.2 m); kit_ledge at the ground floor top and kit_cornice_ring at the top;
kit_wall/kit_bands for the stone ground floor; kit_door for the three portal doors (wood #6b4a32)
and the side entrances; kit_pilaster for the portal's stone piers. Courtyard faces: kit_panes.

## Roof

Low hipped roofs, grey #7d8084, over the front block and the back wings.

## Colour and material

Render #d8cfb9, ground floor #e6e1d4, portal #ece8de, trim #f1eee6, roof #7d8084, glass #4a5660,
doors #6b4a32, canopies #3e4448. All M_STONE. No new material, light or node: one site mesh. No
lettering, signs, plaques or flags (leave the portal frieze plain).

## Ground and night

Collision follows the outline. At night the portal doors glow warm (M_PAVILION or M_LAMP lamp,
existing codes); the rest stays dark.

## Detail level and budget

L3 (a whole block on Nowowiejska, seen at length from the street and Plac Politechniki's side).
Budget 4,500 triangles; set `"itc": 4500` in both game/tools/check_mesh_quality.gd BUDGET and
game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| it_front | six-storey block, stone base, cornice, hip | 0-20.5 m (+2.5 m) | north side | M_STONE #d8cfb9 | 1 |
| it_windows | window grid | 3.2 m bays | outer faces | M_STONE / glass | 1 |
| it_portal | stone portal, three doors, frieze, steps | 12 x 7.5 m | front middle | M_STONE #ece8de | 2 |
| it_canopies | two sloping dark canopies | 8 x 4 m | front ends | M_STONE #3e4448 | 3 |
| it_wings | four-storey back wings, courtyard | 0-14.0 m (+2.0 m) | rest of the outline | M_STONE #d8cfb9 | 4 |
| collision | outline | full height | outline | (collider) | 4 |
