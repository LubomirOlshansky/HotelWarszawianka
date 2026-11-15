# Centrum LIM's tower (the Presidential hotel, Aleje Jerozolimskie 65/79): spec

Site key `lim` (a TOWERS entry; `_marriott` and `_lim_mast` in `game/scripts/landmarks/skyline.gd`); the podium is `lim-podium.md` and stays as it is. Written
2026-11-15 in a cloud thread from 25 photos, reference only and never shipped: three Wikimedia
Commons photos in the shared store `refs/lim/` (1 from the Palace's terrace, 2 the south-west
corner from below, 3 from the Palace, older signs), 16 Mapillary photos in `refs/lim_tower/street/`
(2022 to 2026, from Jerozolimskie, Emilii Plater and Chałubińskiego; the 2026 ones show today's
signs) and F's six night photos (`presidential-podium/refs/`). Massing from the one OpenStreetMap
part in `centrum.json` (140 m), unchanged.

## 1. Identity

1. A plain square glass shaft, 140 m, the first tall hotel opposite Centralna (1989): dark
   blue-green mirror glass in a fine grid of light mullions (all photos).
2. **White corner piers**: every corner is cut back about 3 m and clad in white panels, so each
   face reads as a dark glass slab between two white stripes running from the podium to the roof
   (photos 1, 2, 3, Mapillary from Jerozolimskie).
3. **Two dark bands** on the glass faces: the crown (the top ~7 m) carrying the hotel's name, and
   one about 62% up carrying the electronics maker's name. The white piers run through both
   (2, 3, the 2026 Mapillary).
4. **A red-and-white lattice mast** on the roof's middle, about 30 m, with two small platforms
   (1, 3).
5. At night: rooms lit warm at random, the crown name and the mid-band name lit white, a thin
   light up the corner piers (F's night photos).

## 2. Massing (the map's part)

One part, `#006666`, 0 to 140 m: a 30.6 m square turned about 19 degrees off the grid, its four
corners cut 3 by 3 m (twelve corners). The podium (`lim-podium.md`) wraps it to 15 m; the tower's
glass shows from the podium's roof up.

## 3. Facade, base to top

- **Glass** on the four long faces (24.6 m each): #132a2e in M_GLASS, the shader's mullions and
  transoms, rooms lit at night.
- **Corner piers**: the two short faces of each corner notch in white panels (#e4e6e3), with two
  vertical grooves (0.08 m dark ribs 0.08 m proud), from the podium's roof to the roof. A
  white edge strip 0.5 m wide, 0.12 m proud, at each end of every glass face (photo 2).
- **Mid band**: 4 m tall at 62% (86.8 m), dark #14191c, 0.15 m proud, on the glass faces only,
  the parody name on the south and east faces.
- **Crown band**: the top 7 m of each glass face, dark #14191c, 0.15 m proud, the hotel's parody
  name lit on it.

## 4. Roof

Flat, #6f777b, a 1.2 m parapet in the pier white round the edge. In the middle a plant box 8 by 8
by 3 m in dark grey, and on it the mast.

## 5. The mast

A square lattice 2.4 m wide at the foot and 1.2 m at the head, from the plant box (143 m) to 170
m: four legs 0.25 m, a zigzag brace on each face in eight panels, painted in alternating red
(#c8322b) and white bands every ~3.5 m (photo 3). Two square platforms (3.6 m, 0.4 m deep) at
152 m and 161 m, a thin pole to 171.6 m and the red lamp on top.

## 6. Colour and material

Glass #132a2e (M_GLASS); piers, edges and parapet #e4e6e3 with ribs #b9bcb9 (building material);
bands #14191c (plain, so they read dark by day); roof #6f777b; plant box #4a4f53; mast red #c8322b and white
#e8e8e4, platforms #8a8f93; lamp and names as the dusk loop's (DUSK_RED, DUSK_WARM). No new
material.

## 7. Ground and night

The podium, the pavement and the tram stop are the map's and the podium spec's. Collision stays
the podium's. Night: the rooms in the glass (M_GLASS), the crown and mid names lit white, a thin
M_LAMP line up the outer edge of each corner pier, the mast's red lamp and the aviation lights.

## 8. Detail level and budget

L3 (the first tall tower the player sees across from Centralna). Podium and tower 2,087 triangles
(was 1,421), 0 z-fights: budget 2,500 for the site (check_mesh_quality BUDGET "lim"). No new material, no
draw call, no shader change (building.gdshader stays 501 of 505).

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | prism | mapped ring, 15 to 140 m | the mapped part | M_GLASS #132a2e, roof #6f777b | 1 glass shaft |
| piers | notch walls | 3 m faces, full height | the twelve corner faces | #e4e6e3 | 2 white corners |
| grooves | quads | 0.08 m, two per face | on the piers, 0.08 m proud | #b9bcb9 | 2 white corners |
| edges | strips | 0.5 m wide, 0.12 m proud | each glass face's two ends | #e4e6e3 | 2 white corners |
| mid band | walls | 4 m tall, 0.15 m proud | 84.8 to 88.8 m, glass faces | #14191c | 3 dark bands |
| crown band | walls | 7 m tall, 0.15 m proud | 133 to 140 m, glass faces | #14191c | 3 dark bands |
| names | dusk signs | the band's height | crown and mid band, S and E | DUSK_WARM | 3, 5 names |
| parapet | ring | 1.2 m | roof edge | #e4e6e3 | roof |
| plant box | prism | 8 x 8 x 3 m | roof middle | #4a4f53 | roof |
| mast | 4 legs + braces | 2.4 to 1.2 m wide, 143 to 170 m, 8 panels | on the plant box | #c8322b / #e8e8e4 | 4 mast |
| platforms | prisms | 3.6 m square, 0.4 m | 152 and 161 m | #8a8f93 | 4 mast |
| pole and lamp | frustum + box | 0.4 m, to 172.2 m | mast head | steel, DUSK_RED | 4 mast |
| pier lights | strips | 0.15 m, full height | each pier's outer edge | M_LAMP | 5 night |

## 10. Not built, and what only the phone can show

- The plant on the roof beyond the one box; the mast's antennas.
- The thin third slab seen behind the tower in photo 3 belongs to the next block, not LIM.
- Phone: the white corner stripes at the game's zoom, the names at night.
