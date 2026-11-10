# Barbakan: spec

Site key `barbakan` in `game/scripts/landmarks.gd` (`_find_barbakan`, `_build_barbakan`). Written
2026-11-02 in a cloud thread from the OpenStreetMap outline; no photo and no LoD2 here, so heights
and colours are estimates *(photo check)*. It replaces the earlier skin (colour on LoD2).

## 1. Identity

The Barbican of Warsaw, a brick outwork of 1548 before the Nowomiejska gate, burned in 1944, rebuilt
1952-1954. Landmark card kept ("Barbakan").

## 2. Massing

The mapped outline is a C of wall about 3.5 m thick, opening to the east, around 22 m north to south.
One closed prism, from 1.5 m under the lowest ground to 9.5 m over it *(photo check: real curtain
height)*. Four octagonal turrets (radius 2.6 m) stand on the wall's mid-line, 13 m high.

## 3. Facade, base to top

Brick `#ab5a42` in `M_GOTHIC` (buttresses and pointed lancets from the shader), a stone course
`#c4b69a` on the walk, then a crenellated parapet 1.5 m high (`_attic`, zero thickness).

## 4. Roof

Turrets: a corbel ring (+0.35 m) and a steep eight-sided cone `#6b4a3c`, 6.2 m high, with a small stone finial.
The curtain has no roof.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Wall, turrets | #ab5a42 | M_GOTHIC |
| Walk, corbels, finials | #c4b69a | M_STONE |
| Cones | #6b4a3c | M_STONE |

## 6. Ground and night

Car collision follows the simplified outline. Card (kept): "Barbakan", PL "Ceglana brama dawnych murów
miejskich, odbudowana po wojnie."

## 7. Detail level and budget

L2, triangle budget 900. Shots: city, from the east (inside the C) and from the south-west.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wall | prism | 3.5 m thick, 11 m tall | mapped C outline | M_GOTHIC | curtain |
| parapet | attic | 1.5 m | on the wall top | M_ATTIC | merlons |
| tower x4 | octagonal prism and cone | r 2.6 m, 13 m + 6.2 m | wall mid-line | M_GOTHIC | turrets |

## Update

Photo pass 2026-11-06 (refs/barbakan 1-2, ortho): turret roofs are terracotta (`#a9502f`) cones with a deep eave swelling out over twelve-sided brick turrets; stone-capped merlons every 1.6 m along the crest; the colour of the table below for cones is superseded. Not modelled: the gate passage, the long curtain walls.

## Update 2 (F's photos, 2026-11-08)

Five photos from F (the side from the walk, both side views, the bastion's gate, the inner gate):
- The crown is on the round bastion only: a corbel band, a brick parapet, brick posts every 1.45 m
  under grey stone pyramids, a little pointed gable between each pair. Loopholes in two rows and
  small round holes under the crown. The walls are plain brick `#b2604a` (no Gothic lancets).
- The four towers stand in two pairs on the arms toward the city, at the mapped 13 m outlines
  (radius 2.2 m), each under a tile cone with a deep eave; slit windows on the outer side.
- The arms carry tiled ridge roofs; each arm's outer face has the bridge's two pointed arches with
  iron grilles in brick fans.
- A pointed gate through the bastion's front and its inner face, and a gate wall with a round arch
  and merlons across the C's open east end, toward Nowomiejska (`BARB_GATE_WALL`).
Not modelled: the passage open through the bastion (a dark panel), the moat's depth.
