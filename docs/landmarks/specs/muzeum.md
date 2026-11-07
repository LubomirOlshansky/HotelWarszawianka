# Muzeum Narodowe: spec

Site key `muzeum` in `game/scripts/landmarks.gd` (`_find_muzeum`, `_build_muzeum`). Written 2026-11-06 from refs/muzeum_narodowe 1-4 (Commons photos, see SOURCES.md there), on top of the 2026-10-31 model.

## 1. Identity

The National Museum in Warsaw (Muzeum Narodowe), Tadeusz Tołwiński's stripped-classical block of 1927-1938 on Aleje Jerozolimskie, with the army museum's yard to the east. Landmark card kept.

## 2. Massing

The mapped outline straightened (`_simplify`) on a plinth to the wings' height with a parapet; a raised entrance block at the back of the forecourt (25 m). Detail level L3, triangle budget 3300 (check_sites; 3500 in check_mesh_quality).

## 3. Facade, base to top

Warm sandstone `#cdbfa1`. Tall window strips every 4.4 m (`_bays`) with a stone pier (1 m wide, 0.5 m proud) on every bay boundary of every straight run (`_muzeum_piers`). The entrance block: four square piers, three dark doors in the recessed wall (`_muzeum_doors`), a lintel and three wide steps.

## 4. Roof

Wings flat behind the parapet; the entrance block has a pale green copper roof `#8fae9f` (photo 4).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #cdbfa1 | M_STONE |
| Piers, lintel | lightened wall | M_STONE |
| Windows | #3b424b | M_GLASS |
| Entrance block roof | #8fae9f | M_STONE |
| Fence, gate | #1d1e21 | M_STONE |
| Flagpoles, banners | #e8e8e4, #3a4496 | M_STONE |

## 6. Ground and night

Forecourt (`_muzeum_forecourt`): the black spear-topped iron fence across the court's mouth (v -62.7, u -22..24.7) with the gate standing open, collision except the gate; six 11 m flagpoles in front of the steps with blue banners of the museum's own design (no sponsor marks). Windows light up at night through M_GLASS. Not modelled: the court's pink-red paving, the pool, benches, lamps.

## 7. Detail level and budget

L3, 3300 triangles (check_sites BUDGET), 3500 (check_mesh_quality). Shots: before/after from the south-west and over the forecourt.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| wings | prism | mapped height | outline | M_STONE | block with parapet |
| piers | boxes | 1 x 0.5 m, to the parapet | every bay boundary | M_STONE | pilasters |
| bays | glass walls | 1.3 m wide every 4.4 m | all fronts | M_GLASS | windows |
| entrance block | prism | 25 m | back of the forecourt | M_STONE | copper roof, piers, doors, steps |
| fence | posts and rails | 2.2 m | court mouth | M_STONE | open gate |
| flagpoles | beams and banners | 11 m | before the steps | M_STONE | six poles |
| hardware | tank and field gun | 4 x 2.4 m pads | east lawn | M_STONE | army yard |
