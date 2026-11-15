# Stadion Leguminy (Legia's ground, Łazienkowska): spec

Site key `legia` (`_find_legia`, `_build_legia` in `game/scripts/landmarks/ujazdow.gd`). First
written 2026-11-01 in a cloud thread from `centrum.json` alone. Rewritten 2026-11-15 in a cloud
thread from twelve Mapillary street photos (CC BY-SA 4.0, 2019 to 2025, reference only, never
shipped) of the north and north-east fronts along Łazienkowska, in `refs/legia/street/`. The
south and west fronts, the stands and the roof from above are not in them: those parts are
estimates. Massing from the mapped 27 m outline (about 165 by 205 m), unchanged. The name is the
parody "Stadion Leguminy" (the club name is a brand).

## 1. Identity

1. A roofed four-sided bowl with cut corners, long axis about north-south (all photos).
2. The roof's edge is the signature: a row of white membrane tents, peak after peak, on a dark
   steel truss that overhangs the facade (every photo of the north front).
3. Under it, the open concourse behind tall light grey columns, in shadow, with big green and
   white banners hung between them (1357191621960202, 289530189548905, 499505714713979).
4. A light grey concrete podium two floors high with a row of windows along the street
   (1009753391008916, 1357191621960202).
5. Glass at the corners, white fins on it (289530189548905, the north-east corner).

## 2. Massing (heights over the lowest ground under the outline)

The mapped outline, unchanged, for the facade and the collision. The 20 m west part and the
5.4 m footprint stay dropped with the zone, as before. The roof reaches 1.035 x the outline
(about 4 m over the facade) and peaks at 31.5 m; the bowl inside as before.

## 3. Facade, base to top

- **Podium** (long fronts): the kit's punched skin (S_PUNCHED) in light grey concrete #c9cccb, 0
  to 8.5 m, a ledge on top.
- **Concourse**: a dark recess (#2c3136) 3 % of the radius in (about 3 m), 8.5 to 24.5 m.
- **Columns**: 1.2 m square, light grey (#d9dbda, sides #b9bcbc), at every tent's valley (about
  12 m), 8.5 to 24.5 m.
- **Banners**: every third bay, 8 m tall (11 to 19 m), green #2b6e3f and white #eef0ec in turn.
- **Corners** (the short slanted edges): glass #3a4652 (M_GLASS) from the ground to 24.5 m.
- **Sign**: LEGUMINA in green neon, 15 m up, on the longest south and east fronts.

## 4. Roof

- **Truss**: a steel band #4b5259 at the eave, 24.5 to 26 m, its underside dark.
- **Tents**: one a bay along every edge, a low pyramid from the eave (26 m) to the valley line
  (0.9 x the outline), peaking at 31.5 m 30 % of the way in; neighbours meet in a valley.
  White #f6f6f3 to the street, #e3e5e4 to the pitch (M_MEMBRANE).
- **Inner membrane**: from the valley line (26 m) down to a rounded rectangle about 160 by
  122 m round the pitch (24 m), its last 5 m grey-blue.
- **Floodlights**: a lit strip under the inner edge, all round (M_LAMP). The photos show no
  corner masts, so the four 46 m masts of the first build are gone.

## 5. Colour and material

Podium #c9cccb (S_PUNCHED skin); recess #2c3136, columns #d9dbda and #b9bcbc, truss #4b5259,
banners #2b6e3f and #eef0ec, apron #b6b4ac, seats white, green and red, pitch stripes #5a9643
and #4f8a3a (M_STONE); corner glass #3a4652 (M_GLASS); tents and inner membrane (M_MEMBRANE);
floodlights #fff1c9 (M_LAMP). No new material.

## 6. Ground and night

An apron 4 m round the outline (-1.5 to 0.25 m) meets the street. It is now a band and not a
full cap: the full cap lay 15 cm under the pitch and hid the grass in the game's depth buffer,
so the first build's pitch never showed. Collision is the mapped outline's. At night the
floodlight strip and the two LEGUMINA signs are lit.

## 7. Detail level and budget

L2 (the city's second stadium, a big landmark south-east of the centre, seen from Łazienkowska
and the Trasa). 762 triangles, budget 950 (check_mesh_quality BUDGET "legia"); 0 z-fights; no
draw call, no shader change (building.gdshader stays 501 of 505).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| apron | prism sides + band | outline + 4 m | round the outline | M_STONE #b6b4ac | 6 ground |
| podium | walls | 0 to 8.5 m | long fronts | S_PUNCHED #c9cccb | 1.4 podium |
| ledge | band | outline to 0.97 x | 8.5 m | M_STONE | 1.4 podium |
| recess | walls | 8.5 to 24.5 m | 0.97 x the outline | M_STONE #2c3136 | 1.3 concourse |
| columns | three walls each | 1.2 m, 8.5 to 24.5 m | every 12 m on the long fronts | M_STONE #d9dbda | 1.3 concourse |
| banners | panels | 8 m tall | every third bay, 11 to 19 m | M_STONE green, white | 1.3 banners |
| corners | walls | 0 to 24.5 m | the cut corners | M_GLASS #3a4652 | 1.5 glass corners |
| truss | wall + soffit | 24.5 to 26 m | the eave, 1.035 x | M_STONE #4b5259 | 1.2 roof |
| tents | 4 triangles each | a bay, peak 31.5 m | eave to 0.9 x | M_MEMBRANE white | 1.2 roof |
| membrane | sloped ring | 26 to 24 m | 0.9 x to 160 x 122 m | M_MEMBRANE | 1.2 roof |
| floodlights | strip | 0.7 m | under the inner edge | M_LAMP #fff1c9 | 6 night |
| tiers | stepped rings | 1.2 to 23.5 m | round the pitch | M_STONE seats | 1.1 bowl |
| pitch | slab + stripes + lines | 105 x 68 m | the centre, on the axis | M_STONE | 1.1 bowl |
| signs | neon word | 0.55 of the front, max 60 m | south and east fronts, 15 m | M_LAMP | 6 night |

## 9. Not built, and what only the phone can show

- The banners' sponsors and pictures, the red, white and green rings on the ground-floor pillars,
  the stairs inside the concourse, the white fins on the corner glass, the roof's struts.
- The seats' real colours and the stands' shape (no photo from inside); the south and west
  fronts (no photo).
- Phone: whether the tent edge reads as peaks at the game's zoom, and whether the green pitch and
  the banners read.
