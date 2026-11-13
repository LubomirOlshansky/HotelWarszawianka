# Wybrzeże Kościuszkowskie 41 (the power company's building): spec

Site key `eon41` in `game/scripts/landmarks.gd` (`_find_eon41`, `_build_eon41`). Written 2026-11-13
from F's three photos and sixteen Commons photos of Nos. 37 and 41 (gathered on the Mac, refs/asp37/) (the corner from the street, the whole front with the red roof sign, the
stair tower and the medallion wall close up) and the building's history (1937-39, Czesław
Jabłoński and Józef Korszyński; the sandstone façade renovated 2023-24). The photos are reference
only and are not in the repository. The real roof sign is the company's red logo: here it is the
parody ELEKTRON, never the real name.

## 1. Identity

The 1930s functionalist power-company building at the corner of Tamka and Wybrzeże Kościuszkowskie:
two flat sandstone wings meeting in a rounded corner, a tall glass-block stair tower with a round
lantern on top, and twelve bronze medallions on the curved wall. What makes a passer-by say it: the
curve with its medallions, the glass tower with the lantern, the red letters on the roof.

## 2. Massing

An L of two wings round a courtyard, 14 m deep: the Tamka wing about 55 m and the Wybrzeże wing
about 50 m, the mapped outline (centrum.json) with its zigzag corner replaced by a true quarter
arc of radius 9 m. Five storeys (photo report) to 21.5 m; the corner block (the Tamka end and the first 40 m of the
Wybrzeże wing) a storey higher, 25.5 m; the stair tower 30 m with the lantern to 35 m.

## 3. Facade, base to top

Plinth in dark stone 1.3 m; the sandstone wall with rows of tall punched windows (the building
shader's punched skin); a pale cornice 0.7 m and a parapet of 0.6 m at each eave. The Tamka face has
two doors (3.6 m dark panels under pale lintels); by the tower a dark plaque. The curved wall carries
twelve bronze medallions (rim, pale star, boss), 1.3 to 2.6 m across, from 7.8 to 19.8 m up. The
stair tower is a rounded glass front 5.5 m wide with a pale ledge at every storey.

## 4. Roof

Flat, grey, with the parapet. On the tower a lantern: a white band 1.3 m, an open drum of twelve
steel posts with diagonals 2.9 m high, a white rim, 3.6 m radius. Two red roof signs: ELEKTRON on
the corner block facing Tamka and on its Wybrzeże wing facing the river.

## 5. Colour and material

Sandstone #b3a78f (renovated, lighter), cornice #c4b9a2, plinth #625d55, glass #56646c, steel
#3b4044, lantern white #e9e6de, medallions #5f5f52 with #8a8b78, the sign red. All in the city's
building surface: no new draw call.

## 6. Ground and night

The wings and the tower collide. The windows follow the building shader's night rule; the roof sign
glows as neon.

## 7. Detail level and budget

L2, budget 1300 triangles (measured 971). One surface with the city.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | prism of the mapped L | 14 m deep, 21.5 m | Tamka and Wybrzeże faces | sandstone, punched skin | identity |
| corner_arc | quarter arc, 8 segments | radius 9 m | the corner | sandstone | rounded corner |
| block | prism, one storey over | 4 m on the corner block | Tamka end and the first 40 m of the river wing | sandstone | the higher corner block |
| tower | five-sided glass prism with ledges | 5.5 m wide, 30 m | Wybrzeże face beside the arc | glass, pale ledges | glass stair tower |
| lantern | drum, 12 posts, white band and rim | 3.6 m radius, 5 m | over the tower | white, steel | round lantern |
| medallions | three stacked discs, twelve | 1.3 to 2.6 m | on the arc, 4.6 to 19.8 m up | bronze | metal ornaments |
| doors | dark panels with lintels | 3.8 × 3.6 m | Tamka face | dark stone | entrances |
| signs | neon letters | 2.2 m tall | roof of the corner block, two faces | red neon | ELEKTRON |

## 9. Driving

The wings and the tower collide; the courtyard side is as mapped.

## Open

- Phone look check by day and night.
- Photos of the courtyard side and the Tamka face's ground floor (doors, plaque) are still missing.
