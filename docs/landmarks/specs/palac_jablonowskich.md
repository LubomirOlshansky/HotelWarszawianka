# Pałac Jabłonowskich (Senatorska 14, Plac Teatralny)

Site key `jablonowskich` in `game/scripts/landmarks/old_town.gd` (`_find_jablonowskich`,
`_build_jablonowskich`). Modelling queue v2 row 14 (F, 2026-11-27: buildings with no model
first), Gemini lane. Today it is the map's plain 14 m prism facing Teatr Wielki across
Plac Teatralny.

Sources: Google Street View, 2026-11-28 (`refs/jablonowskich/streetview/`: the three `nr1...`
frames from Senatorska show the palace front with its tower; the `dm6...` frames look the other way
at Teatr Wielki; the `vnf...` frames show the modern building behind it; the `nov...` frames the
plain rear wing on Wierzbowa); reference only, gitignored, never copied. No 3D Tiles orbit (the
day's cap was spent). OpenStreetMap: landmark "Pałac Jabłonowskich" (building 12751, 14.0 m,
39 nodes, about 80 x 83 m); find it by name.

## Identity

The rebuilt palace (once the city hall, now a bank) on Plac Teatralny, by Teatr Wielki. What makes
it read as itself from the iso camera:
1. A long white neo-baroque front #ecebe6 on Senatorska, three storeys over a rusticated ground
   floor #dcdad3, tall windows with ornate surrounds and small iron balconies on the first floor.
2. Two corner pavilions that stand forward and up, each under a steep tall mansard #6f7f7a
   (grey-green copper) with a round-top dormer / oeil-de-boeuf in the middle.
3. A central risalit with columns or pilasters, a balcony over the main arched door, a curved or
   triangular pediment with a small dormer, and a lower grey-green mansard over the wings between
   pavilions with rows of dormers.
4. The clock tower: a slender square white tower about 40 m tall rising behind the front at its end
   toward Teatr Wielki, with clock faces, a balustraded top, and a grey-green cupola with a lantern
   and spire.
5. The plain rear wings round a courtyard behind (pale yellow #e6d9b0 render, two to three
   storeys), seen only from Wierzbowa and the air.

## Massing

The landmark outline; ground = `_ground_under`. Find the front (the concave run along Senatorska on the
outline's south-east side, facing Plac Teatralny and Teatr Wielki; its middle straight edge runs
about (-994, -1167) to (-970, -1182)) and the rear wings from the outline itself; simplify only
short wiggles. (As built, 2026-11-28: the first draft of this spec said north-east; the outline
shows south-east, and the model follows the outline.)
- Front block: ground floor 0-5.0 m (rusticated), two upper storeys to 14.0 m, cornice.
- Corner pavilions (about 14 m wide each at both ends of the front): to 15.5 m, then a steep mansard
  6.0 m tall.
- Middle wings between pavilions: mansard 4.5 m with dormers.
- Central risalit: 1.0 m forward, pediment 3.0 m over the cornice.
- Clock tower: square about 7 x 7 m, from the roof to 34 m (body), balustrade, then cupola and lantern
  to about 42 m with a 3 m spire. Place it at the front's west end (toward Teatr Wielki), just behind
  the pavilion.
- Rear wings: modern 5-6 storey grey-beige stone blocks (#cfc8bb, 0-21.0 m with 0.58 m parapets), flat dark roofs with mechanical plant boxes, round a courtyard covered by a big pitched glass atrium roof (18.8-22.35 m, glass #8fa3ad, thin dark steel frame lines). (As built from 3D Tiles, 2026-11-28: orbits show dark grey mansards and cupola #5f6468 instead of grey-green, modern 5-6 storey grey-beige stone rear blocks with flat dark roofs and plant boxes instead of low pale-yellow hipped wings, and a pitched glass atrium roof covering the courtyard.)

## Facade

Kit parts only. kit_window_grid on the front (1.4 x 2.6 m windows, white frames, glass #4a5660, bays
about 3.6 m); first-floor windows with pediments and small balconies (kit_window Win.PEDIMENT /
kit balcony parts); kit_bands rustication on the ground floor; kit_ledge string courses;
kit_cornice_ring at 14.0 m; kit_pilaster or kit_column on the risalit; kit_door arched for the main
door (wood #6b4a32); kit_dormer on the mansards (round-top where the kit allows). Rear wings: kit_panes
with sill ledges.

## Roof

Steep mansards in dark grey #5f6468 on the pavilions and lower ones on the middle wings; tower
cupola dark grey #5f6468 with a white lantern and a dark spire; modern rear blocks flat dark grey
#52575b inside stone parapets with rooftop HVAC plant boxes; big pitched glass atrium roof
(#8fa3ad, thin dark steel frame lines) covering the courtyard. (As built from 3D Tiles, 2026-11-28:
recoloured mansards and tower cupola to dark grey, replaced rear hips with flat dark roofs + plant
boxes, and added the pitched glass atrium roof.)

## Colour and material

Front #ecebe6, ground floor #dcdad3, trim white #f4f3ef, roofs #6f7f7a, rear #e6d9b0, glass
#4a5660, door #6b4a32, clock faces white with dark hands. All M_STONE; the clock faces may use
M_LAMP so they read at night. No new material, light or node: one site mesh. No bank name, logo,
sign or flag.

## Ground and night

Collision follows the outline. At night the clock faces glow softly (M_LAMP) and the main door
warm; the rest stays dark.

## Detail level and budget

L3 (it frames Plac Teatralny opposite Teatr Wielki, with a tower seen from far). Budget 7,500
triangles; set `"jablonowskich": 7500` in both game/tools/check_mesh_quality.gd BUDGET and
game/tools/check_sites.gd BUDGET.

## Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| pj_front | three storeys, rusticated base, cornice | 0-14.0 m | Senatorska front | M_STONE #ecebe6 | 1 |
| pj_windows | window grid, pedimented first floor, balconies | 3.6 m bays | front faces | M_STONE / glass | 1 |
| pj_pavilions | forward corner blocks, steep mansards, oeil-de-boeuf | to 15.5 m + 6.0 m | both front ends | M_STONE #5f6468 | 2 |
| pj_risalit | pilasters, balcony, arched door, pediment | 0-17.0 m | front middle | M_STONE | 3 |
| pj_mansard | lower mansard with dormers | 4.5 m | middle wings | M_STONE #5f6468 | 3 |
| pj_tower | square tower, clocks, balustrade, cupola, lantern, spire | to about 45 m | front's west end | M_STONE / M_LAMP | 4 |
| pj_rear | modern 5-6 storey grey-beige stone blocks, flat dark roofs, plant boxes | 0-21.0 m (+0.6 m parapet) | rest of the outline | M_STONE #cfc8bb / #52575b | 5 |
| pj_atrium | pitched glass atrium roof with dark steel frame lines | 18.8-22.35 m | whole courtyard | M_GLASS #8fa3ad / M_STONE #3b4044 | 5 |
| collision | outline | full height | outline | (collider) | 5 |
