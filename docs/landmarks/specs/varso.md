# Varso Tower (Chmielna 69): spec

Site key `varso` in `game/scripts/landmarks.gd` (`_build_varso` and its `_varso_*` helpers). Written
2026-11-15 in a cloud thread from 14 photos, reference only and never shipped: seven Wikimedia
Commons photos in the shared store `refs/varso/` (1 from the park east of Centralna, 2 the spire
from below, 3 from the Jana Pawła II viaduct, 4 over Centralna's canopy, 5 the crown from above, 6
from the Palace, 7 the ortho) and F's seven in `refs/_f/warsaw-needed-photos/top-50/T01/` (from
Centralna, the lobby between the tower and Varso I, the spire floodlit at night, the observation
box from inside). Massing from the OpenStreetMap parts in `centrum.json`, unchanged. The sky garden
on the 205 m roof and Varso Place are `varso_place.md`'s and stay as they were.

## 1. Identity

1. The tallest building in the European Union: a slim stack of deep blue glass with a long lattice
   spire standing off one corner to 310 m (all photos).
2. The glass sits in a proud grey frame of big cells: a post every three panes, a transom every
   two storeys. From the street the tower reads as a blue grid, not a smooth mirror (1, 3, 4, F's
   from Centralna).
3. Three slabs stepping 177, 205 and 230 m from Chmielna down to the tracks, a light grey pier at
   each step running up past the roofs (4, 7, F's).
4. The crown: silver louvres in two bands over the top storeys with a glass band between, on the
   outer faces of the 230 m top (1, 3, 4, F's). The top is an L round the 205 m garden.
5. The spire: a square lattice mast with four round dish platforms close together over the roof,
   then a thin pole with one small ring and a red lamp (2, 4, 7). Floodlit white at night, the
   dishes glowing (F's night shot).

## 2. Massing (the mapped parts)

The plan is a parallelogram about 56 by 45 m with its long sides along the tracks (local u east-north-east,
v south-south-east). The 177 m slab is the north side (Chmielna), the 205 m slab the middle and
south, and the 205 to 230 m top an L along the west end and the south side, the sky garden inside
it. The mapped crown strips (193 to 234 m) hug the L's outer edges just inside them; four grey piers
(1 m thick, 8 to 11 m long, to 209 and 234 m) stand at the steps at both ends. The lobby is a 12 m
glass hall west of the tower (towards Varso I) and a smaller one on the east. The spire stands on
the L's south-west corner at the mapped rings (240, 250, 260, 274, 294 m).

Outlines are cleaned of their notches under 3 m² (`_varso_clean`), so the glass is flat planes.

## 3. Facade, base to top

- **Glass** (#2a5c93, M_GLASS: the shader's 1.5 m mullions and 4 m transoms, rooms lit at night)
  on every slab to its top.
- **The frame** (#565c63) over it on every face nothing stands in front of: posts 0.44 m wide and
  0.34 m proud every ~4.6 m and at each corner, transoms 0.5 m tall and 0.26 m proud every 8.3 m
  (two storeys) from the lobby's 12 m up.
- **The crown** on the faces the crown strips stand on: silver louvre plates (#d3d8dc, 0.12 m
  proud, a darker rib every 1.2 m) from 193 to 204 m and from 213.5 m to the top, the slab's glass
  showing between them. Over the 230 m roof the strips are the louvred screen to 234 m.
- **Piers** (#959ba1) from the ground to 209 and 234 m, a lamp strip up each one's outer end.
- **Lobby**: warm lit glass (M_PAVILION) to 12 m under a dark canopy 1.4 m proud; the small mapped
  service boxes in dark steel.

## 4. Roofs

The 177 and 205 m roofs dark grey (#5d6369) with the mapped glass parapets in pale glass; the
garden as `varso_place.md`. On the 230 m top, at the corner farthest from the spire, the
observation box: 5 by 5 m of pale glass, 6 m tall, lit cool at night, under a dark lid.

## 5. The spire

A square lattice mast from 228 m to 274 m, 3 m wide at the foot and 1.9 m at the head: four legs
0.4 m and a zigzag brace on each face in eleven panels (#b9c0c8). Round dish platforms (12-sided,
0.7 m deep, #dfe4e9 in M_LAMP so they glow at night) at 240, 250 and 260 m (radius 3 m) and 274 m
(2.6 m). A tapering pole from 274 to 308 m, a small lit ring at 294 m, the red lamp to 309.3 m and
the dusk loop's red light on top at 310 m.

## 6. Night

The rooms in the glass (M_GLASS's own share), the lobby warm, the observation box cool white, the
dish platforms and ring glowing white, the piers' lamp strips, the red lamp.

## 7. Budget

3,602 triangles (budget 4,300), no z-fights, no floating parts; the same building material, so
no draw call is added. No shader change (building.gdshader stays 501 of 505).

## 8. Not built, and what only the phone or the Mac can show

- The louvres' exact band heights are read from photos taken from the ground; the faces F's
  photo from above shows without louvres (the inner faces round the garden) are glass.
- The vents in some frame cells, the glass balustrade on top of the crown, the lobby's entrance.
- Phone: the frame at the game's zoom (a grid or noise?), the spire's dishes at night.
