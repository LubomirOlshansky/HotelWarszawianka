# Kościół Świętej Trójcy na Solcu (Holy Trinity on Solec): spec

Site key `church_trojca_praga` in `game/scripts/landmarks.gd` (the key's "Praga" is an old
mistake: the church stands on Solec, on the left bank; `_find_churches` finds it, `_build_church`
hands it to `_build_trojca_solec`): the whole church is one model that replaces the kit church.
Written 2026-11-14 from Mapillary 360s of 2025 and 2026 on the avenue north-east of it (the
temple front and the turret against the sky from 96 m; a floodlit night view; refs/trojca_praga,
never shipped), the OSM outline and GUGiK's LoD2. No photo is close; the colours are a default.

The kit church it replaces (2026-11-01) was a plain box without a tower.

## 1. Identity
1. The **classicist temple front** to the north-east: four pilasters, an entablature and a
   **pediment**.
2. The **slim bell turret over the crossing** with arched openings, a little bulb dome and a cross.
3. A **cross plan**: the nave, a short transept, the chancel, low wings round the back.

## 2. Massing
Frame: origin (1077.3, 252.8), the front's middle; u back from the front (axis (-0.6905,
0.7234)), v across. Ground g is the lowest terrain under the outline.

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| nave | u 0 to 19.5, v -4.6 to 4.6 | eaves 14.1; gable ridge 17 |
| transept | u 19.5 to 25, v -7.5 to 7.5 | 14.1; gable along v, ridge 17.2 |
| chancel | u 25 to 31, v -4 to 4 | 13.5; ridge 16.5 |
| back wings | u 25 to 31, out to v 9.5 either side | 9, flat |
| side annex | u 6 to 10, v 4.6 to 9.5 | 8.6, flat |
| turret | 3 m square round (22.3, 0) | from the roof 15 to 21.4; dome to 23.9; spire 25.6 |

LoD2: the nave's eaves 14 and ridge 17; the transept's ridge 17.2; the turret's top 26.4; the
chancel 16.5 to 17; the back wings 7.5 to 11; the side annex 7 to 13.

## 3. Facade: the front
Four pilasters, an entablature at 12.6 to 14.1, the pediment (2.9 m), an arched door (2 m wide,
to 4.2) and a round-headed window over it.

## 4. Facade: the sides and the back
Four pilasters and two tall round-headed windows a side; a tall window in each transept end;
the chancel, the wings and the annex plain (default).

## 5. Roof and turret
Grey sheet (#63696e) on the gables; a lighter grey on the flat wings. The turret: cream with
four arched openings, a white cornice, a dark green-grey (#5b6764) bulb dome and spire, the cross.

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Walls | #e2d6bc | M_STONE |
| Pilasters, entablature, pediment | #f2ecdf | M_STONE |
| Roofs | #63696e | M_STONE |
| Turret dome | #5b6764 | M_STONE |
| Door | #4a3a30 | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text says Solec and names the turret. No
floodlights (the real front is floodlit at night).

## 8. Detail level and budget
L1, triangle budget 520 (measured 469, `check_mesh_quality.gd`). Shots:
`tools/turntable.sh church_trojca_praga`.

## 9. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| nave | prism + gable | 19.5 x 9.2 m | u 0..19.5, y to 17 | #e2d6bc, #63696e | 1 nave |
| transept | prism + gable along v | 5.5 x 15 m | u 19.5..25, y to 17.2 | #e2d6bc, #63696e | 1 transept |
| chancel | prism + gable | 6 x 8 m | u 25..31, y to 16.5 | #e2d6bc, #63696e | 1 chancel |
| wings, annex | 3 prisms | 4 to 6 m | the back and the south-east side, y to 9 | #e2d6bc | 3 wings |
| front | 4 pilasters, entablature, pediment, door, window | 9.5 m wide | u 0 | #f2ecdf, #4a3a30 | 1 pediment |
| side windows | arched panels | 1.8 x 5.5 m | 2 a side, 1 a transept end | PAL_GLASS_DARK | 6 windows |
| turret | box, cornice, 4 arches, 3 frustums, cross | 3 m | u 22.3, y 15..26.6 | #e2d6bc, #5b6764 | 1 turret |
