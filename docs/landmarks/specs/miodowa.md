# Miodowa's and Senatorska's palaces: spec

Site keys `branickich`, `mlodziejowski`, `szaniawski`, `chodkiewicz`, `arcybiskupi`, `paca`,
`nobilium` in `game/scripts/landmarks.gd` (SKINS; `_build_branickich`). Written 2026-11-07 in a
cloud thread from F's photo set on the Mac (`warsaw-other-buildings-part-1`, rows M184-M204; the
Mac's `refs/` folder is the home of the originals) and OpenStreetMap's outlines in `centrum.json`.
Every palace keeps its LoD2 mass in a kept skin (colours read off the photos); Pałac Branickich
also gets a modelled street front. Values marked *(photo check)* wait for a Mac walk along Miodowa.

## 1. Identity

Miodowa is a street of baroque and classicist palaces behind tile-red roofs. Defining features:
Branickich is a 60 m rococo front of cream plaster with dusty-pink pilaster strips, an attic
balustrade crowded with statues and scrolled dormers with oculi (M199). Młodziejowskiego is a
cream classicist cour d'honneur under red roofs (M198). Szaniawskich is a white house with a
small pediment, a stone arch ground floor and a dark dormer (M204). Paca is a mint-green copper
roof over cream wings with a round gate court (M197). Arcybiskupi's wings are yellow-cream round
a lime court (M200). Collegium Nobilium is a long pale front with a tower block and a roof
balustrade (M202).

## 2. Massing

Outlines from `centrum.json`: Branickich (`Pałac Branickich` near (-852, -1425), 1925 m²), the front
edge from (-883.7, -1420.3) to (-832.5, -1389.4) is 59.8 m long, facing south-west onto Miodowa
(9 m from its centre line). Heights stay LoD2's. The front model adds 6.4 m over the cornice
(attic 2.1 m, dormers to 6.4 m, statues to 4.2 m).

## 3. Facade, base to top

Branickich: a 0.9 m stone plinth; nine pilaster strips 0.7 m wide every 7.1 m, 0.2 m proud,
dusty pink (#d6a898) up to the cornice at 10.4 m; a 0.8 m cornice, 0.9 m proud; the attic wall
(1.3 m) with a statue plinth and figure every 5.7 m; centre gate: a dark door 2.4 x 3.1 m in a
stone frame, a stone balcony slab and an iron rail at 4.3-5.7 m. The wall behind keeps the
window rhythm of the monument skin (cream, #ecd7c2).

## 4. Roof

Tile red, from the skin (#a85f45 for Branickich, Szaniawskich and Chodkiewiczów; #b3583c for
Młodziejowskiego; #ad6446 for Arcybiskupi). Paca's is green copper (#7fa391); Collegium Nobilium's
is a pale grey-green (#8c8f86). Three dormers on Branickich (u 9, 29.9, 50.8 m): three stepped
tiers (6.6, 4.6, 2.4 m wide), an oculus of 0.7 m radius, two scrolls with cherubs.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster (Branickich) | #ecd7c2 | M_MONUMENT |
| Pilaster strips | #d6a898 | M_STONE |
| Stone (plinth, attic, dormers) | #cfc7b6 | M_STONE |
| Door and rail | #34383b | M_GLASS, M_STONE |

No new material or draw call.

## 6. Ground and night

The car stops at the plinth (a collision strip along the front). Card: "Pałac Branickich", PL
"Barokowy pałac z 1740 roku przy Miodowej, z attyką pełną rzeźb i lukarnami z oculusami.", EN "The
baroque palace of 1740 on Miodowa, its attic crowded with statues and oculus dormers." Open
*(photo check)*: the real storey count under the cornice, the pavilion bays at the ends.
Not built yet: Młodziejowskiego's pediment block and wrought-iron fence, Paca's gate court,
Collegium Nobilium's tower block and roof balustrade (BACKLOG "Miodowa palaces").

## 7. Detail level and budget

L2 for the Branickich front, L1 skins for the other six palaces; triangle budget 1500
(`check_mesh_quality.gd`). Shot: `--at=-858,-1405 --yaw=45 --pitch=-25 --size=45 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 59.8 x 0.3 m, 1.5 m high | u 29.9, v 0.15 | M_STONE | 3 plinth |
| pilasters | 9 boxes | 0.7 x 0.4 m, 9.5 m high | u 3.5 + 7.1 k | M_STONE | 3 pilaster strips |
| cornice | box | 60 x 0.9 m, 0.8 m high | 10.4 m, v 0.35 | M_STONE | 3 cornice |
| attic | box | 59.8 x 0.6 m, 1.3 m high | 11.2-12.5 m | M_STONE | 3 attic balustrade |
| statues | 10 plinths and figures | 0.6 m plinths, 1.5 m figures | u 2.9 + 5.7 k | M_STONE | 1 statues |
| dormers | 3 stacks of 3 boxes | 6.6, 4.6, 2.4 m wide | u 9, 29.9, 50.8 | M_STONE | 1 scrolled dormers |
| oculi | 3 discs | r 0.7 m | 4.5 m over the attic | M_STONE | 1 oculi |
| gate | dark pane and frame | 2.4 x 3.1 m; frame 3.4 m | u 29.9, v 0.5 | M_GLASS, M_STONE | 3 gate |
| balcony | slab and rail | 3.8 x 1.0 m; rail 1 m | 4.3-5.7 m | M_STONE | 3 gate |
