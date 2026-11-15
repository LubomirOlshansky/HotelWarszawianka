# Hala Koszyki (Koszykowa 63): spec

Site key `koszyki` (`_build_koszyki` in `game/scripts/landmarks/works.gd`; the dispatch in
`landmarks.gd` builds the street block first). Rewritten 2026-11-15 in a cloud thread from photos:
F's T18 set (`refs/_f/warsaw-needed-photos/top-50/T18/` in the shared store: the front, the
terrace at night, the hall inside, a side passage) and Mapillary frames along Koszykowa
(`refs/koszyki_west`, `refs/koszyki_east`), and F's four photos of 2026-11-15 in the thread (two from
above, the pavilion straight on, the street front); reference only, never shipped. The 2026-11-01 version
(written with no photo) had red brick walls round the outline and a glass lantern; the photos show
otherwise.

The hall's mass is the street block that already stood on the outline
(`game/data/street_blocks/459521303.bin`: the buff brick ranges, the two long pitched halls, the
forecourt, a stone gable with a dark arch at each hall's street end, its own site `blk_459521303`).
This site dresses it and draws no walls of its own: the 2026-11-01 model drew a second hall over
the block.

## 1. Identity

1. Two 1909 pavilions on Koszykowa, one at the street end of each long hall (the Mapillary frames
   from both ends of the street; LoD2's two peaks of 13.2 and 12.2 m): a cream stone Art Nouveau
   front between two pylons, the big three-light arch in green steel over a balcony, a door and two
   shop windows under it, a stepped gable with a cartouche (the front photo).
2. The pylons carry tall red brick panels in the stone (the front photo).
3. Buff brick ranges round a forecourt between the pavilions, the summer terrace under festoon
   lights, KOSZYKI in blue neon over the hall's door at its back (the night photo).
4. Inside, a green steel hall under a clerestory (the hall photo; not built, the block's roof
   stands for it).

## 2. Massing (heights over the ground)

The block's, unchanged: ranges about 8.3 m, the two long halls' ridges about 12.6 m, the pavilions'
gables 13 m. The fronts stand on the block's pavilion faces (u 3.5..16.3 and 66..78 in the street's
frame), 12.8 m wide. F's straight-on photo (2026-11-15) sets the proportions: the cartouche on the
gable is the highest point (13 m), the pylons stop lower (11.6 m with their caps).

## 3. Facade, base to top

- **Foot**: a rusticated stone base, 1.8 m across the middle, 3 m on the pylons, #c2b597.
- **Ground floor**: a door (1.9 m wide, round head to 3.85 m) between two stone pilasters; a shop
  window either side (2.1 m wide, 0.3 to 4.2 m), green frames; a stone lintel to 5 m.
- **Balcony** at 5 to 5.6 m, a green railing to 6.3 m.
- **Arch**: a stone ring (9 m wide) round the glass (8 m wide, 5.6 m to the spring at 6.4 m and a
  half-round head to 10.4 m), two stone mullions, two green transoms at 7.4 and 8.9 m.
- **Pylons**: 1.9 m wide, cream stone, red brick panels (1.3 m wide) from 5.4 to 10.4 m, a
  rounded cap in two steps to 11.6 m.
- **Gable**: from the pylons' tops (9.9 m) its edges climb in five small steps, each with a light
  dentil, to the cartouche (11.4 to 13 m).

## 4. Roof

The block's: zinc grey over the ranges, darker over the two halls, a light ridge strip on each.

## 5. Colour and material

Stone #ddd2b6, foot #c2b597, red brick panels #b5643f (all M_STONE); green frames and railings
#2e6b4a; glass #24332e (M_GLASS); door #2a3532. The block keeps its own colours (buff brick
#bda186 with the building shader's windows, stone #d6c6a6). No new material, no shader change
(building.gdshader stays 501 of 505).

## 6. Ground and night

The car is stopped by the outline (the block's collision) and by a box in front of each pavilion.
The forecourt (F's aerial photos): a dark steel canopy #3b4044 on thin black posts
round all four sides of the paved yard, 2.6 m deep at 3.4 m; two strings of festoon bulbs hanging on
wires from the west canopy to the east one (M_LAMP, lit at night); and
the KOSZYKI sign in blue neon over the hall's door. The chill crowd (`chill_koszyki`) stays on the
forecourt.

## 7. Detail level and budget

L2 (a landmark on a street the drive uses, seen from above at an angle). About 1720 triangles of its
own (the block's 1100 are the block site's), budget 1900 (check_mesh_quality BUDGET "koszyki"); no
draw call added.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | street block | the whole hall | the outline | its own | 2 massing |
| frontispiece | box | 9 m wide, to 9.9 m | each pavilion | M_STONE #ddd2b6 | 1.1 pavilions |
| gable | five steps + cartouche | to 13 m | over the arch | M_STONE | 1.1 pavilions |
| pylons | boxes + rounded caps | 1.9 m, to 11.6 m | u ±5.45 | M_STONE | 1.1 pavilions |
| brick panels | thin boxes | 1.3 m, 5.4 to 10.4 m | the pylons' faces | M_STONE #b5643f | 1.2 pylons |
| arch | ring + glass panels | 9 / 8 m wide | the middle | M_STONE, M_GLASS | 1.1 pavilions |
| mullions, transoms | thin boxes | 0.3 m, to 9 m | in the arch | M_STONE, green | 1.1 pavilions |
| balcony | ledge + railing | 9 m, 5 to 6.3 m | under the arch | M_STONE, green | 1.1 pavilions |
| door, shops | arch panel + boxes | 2 m, to 4.2 m | the ground floor | M_STONE, M_GLASS | 1.1 pavilions |
| canopy | four slabs + posts | 2.6 m deep, at 3.4 m | round the yard | M_STONE #3b4044 | 3 forecourt |
| festoons | wires + bulbs | two strings | across the forecourt | M_LAMP | 3, 6 night |
| sign | KOSZYKI neon | 7.5 m | the hall's door | neon | 3, 6 night |

## 9. Not built, and what only the phone can show

- The Art Nouveau reliefs, the cartouche's carving, the green railing's ornament, the shop signs.
- The hall's clerestory and green steel inside (the block's roof stands for it).
- Phone: whether the two pavilions read cream against the buff brick at phone zoom, and whether the
  red pylon panels show.
