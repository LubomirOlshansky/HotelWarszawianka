# Office pass: Brama Zachodnia, Proximo I and II: spec

Site keys `brama_zach`, `proximo1`, `proximo2` in `game/scripts/landmarks.gd` (SKINS). Written 2026-11-07 in a
cloud thread from F's photos on the Mac (`warsaw-other-buildings-part-2`, rows M565 Al. Jerozolimskie 92,
M557 Prosta 68, and the neighbours in the same frame) and the outlines in `centrum.json`. Each keeps its
LoD2 mass in a kept skin; no model. Values marked *(photo check)* wait for a Mac walk.

## 1. Identity

Brama Zachodnia is a 14-storey block clad in apricot terracotta panels with green-tinted ribbon windows, a stepped crown
with a taller glazed block over the middle and a tall vertical name strip on the east corner (M565). Proximo I
(Prosta 68) is a nine-storey glass block whose mullions are ochre-yellow, with a dark top band and a rooftop sign (M557).
Proximo II beside it is a taller dark-glass block with a sloped roof edge (M557, left of centre).

## 2. Massing

Outlines `Brama Zachodnia` (47 m, 14 corners, near (-2924, 1199)), `Proximo I` (44 m, 79 corners, near (-2906, 412))
and `Proximo II` (42 m, 94 corners, near (-2932, 353)). Heights stay LoD2's.

## 3. Facade, base to top

Brama Zachodnia in the re-clad code M_SKIN + S_PUNCHED (light horizontal cladding, punched windows in bands), wall
apricot #d9a27c; Proximo I in the curtain-wall code M_GLASS, #667f93 (the photo's steel-blue glass); Proximo II in
the dark-glass skin M_SKIN + S_DARK, #35495b. Not modelled: Brama Zachodnia's stepped crown and name strip,
Proximo I's ochre mullions and sign, the podium shops.

## 4. Roof

Grey membrane for all three: #878d8f, #6d7377, #596168.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Brama Zachodnia wall | #d9a27c | M_SKIN + S_PUNCHED |
| Proximo I wall | #667f93 | M_GLASS |
| Proximo II wall | #35495b | M_SKIN + S_DARK |
| Roofs | #878d8f, #6d7377, #596168 | roof |

No new material or draw call.

## 6. Ground and night

Nothing new at the foot. Open: the name strips and signs must be parodies (never the real company names), the
stepped crown, the ochre mullions, and a night look. Equator I and II, Crown Square, Crown Point and Crown Tower have no
usable ground photo yet (the Equator photo is a plaque).

## 7. Detail level and budget

L1 skins, no triangles added; triangle budget 200 (exception: none used).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| brama skin | kept LoD2 mass | 14-corner outline, 47 m | (-2924, 1199) | M_SKIN + S_PUNCHED | 1 apricot cladding |
| proximo1 skin | kept LoD2 mass | 79-corner outline, 44 m | (-2906, 412) | M_GLASS | 1 blue glass |
| proximo2 skin | kept LoD2 mass | 94-corner outline, 42 m | (-2932, 353) | M_SKIN + S_DARK | 1 dark glass |
