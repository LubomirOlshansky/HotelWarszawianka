# Kościół Niepokalanego Poczęcia NMP ("Res Sacra Miser"), Krakowskie Przedmieście 62: spec

Site key `church_niepokalanego` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_niepokalanego`): the whole church is one model that replaces the
kit church (a tower with an onion it never had) and the LoD2 mass. Written 2026-11-14 from four
Mapillary 360s of 2026 taken from Skwer Hoovera (2162374931322524 straight onto the front,
1061577036859002 on its axis, 3580228702176291 and 1409461751243517 from the sides; re-projected
to flat views, kept in `refs/res_sacra_miser/`, never shipped), the OSM outline and GUGiK's LoD2.
Commons and the Polish photo sites are blocked from the cloud.

Which church: the LANDMARKS row "Krakowskie Przedmieście 62" is the small church of the
Immaculate Conception in the old refectory of Kazanowski's palace (since 1664), known by the
"Res Sacra Miser" of the charity society next door. Not the Grójecka parish church of the same name
(map edge, no model).

## 1. Identity
A narrow classicist front squeezed between the white Dom Polonii (north) and a lower convent wing
(south), set back from the street across the square. What makes it read as itself:
1. **Apricot plaster** front in two storeys, 8.8 m wide, about 12 m to the cornice.
2. **Two Tuscan columns** before a recessed door bay, the door with a **fanlight lunette** over it.
3. A tall **arched window** in a slightly proud middle field framed by pilaster strips.
4. A **stepped attic** in four tiers with an **iron cross**, hiding the nave roof from the street.

## 2. Massing
Frame: origin at the front's north end on the outline (-655.8, -1243.3), u along the front to the
south (axis (0.354, 0.935), +u to the viewer's right), +v out to the square (west). Ground is the
terrain at the front's middle (the plot falls about 1.2 m to the back; walls run down to g - 1.6).

| Block | Plan (u, v) | Height over the front's ground |
| --- | --- | --- |
| nave body | the outline, front wall at v -0.75 | 12.0 m, eaves band to 12.15 |
| front | u 0 to 8.77, v -0.75 to 0 (door bay u 3.35 to 5.65 open below 6 m) | cornice 12.3 m |
| stepped attic | four tiers, u 0.15-8.62 / 0.95-7.82 / 1.7-7.07 / 2.45-6.32 | 13.05 / 13.55 / 14.05 / 14.75 m, cross to 16.8 |
| nave roof | gable along v from v -1 to -18.15, centre u 4.7, half width 4.6 | eaves 12.1, ridge 14.1 |
| chancel (LoD2, behind the outline) | u 1.7 to 10.2, v -18.15 to -24.45 | eaves 6.5, hip to 11.4 |

LoD2 (seed 0.891) over the front's ground (6.4 m): front corners 11.9 to 12.5, attic peak 14.8,
nave eaves about 12, ridge 14.85, chancel eaves 6 to 7 with its hip apex at 11.4. The OSM outline's
front has a 0.75 m deep notch between u 3.35 and 5.65: the door bay behind the columns.

## 3. Facade
Lower storey: grey plinth on the piers; corner lesenes (0.7 m); the door bay one step up, a dark
wooden door 1.36 x 2.45 m with a hood, a half-round fanlight (0.76 m radius) at 3.3 m; two Tuscan
columns (radius 0.36) at c +- 1.45 up to 5.95 m; architrave, an inscription panel (u 1.9 to 7.1) and
the cornice at 7.25 to 7.6 m. Upper storey: the middle field u 1.7 to 7.3 standing 0.12 m proud,
pilaster strips at u 1.95 and 7.05, two short strips at c +- 1.4 up to the window's spring, the
arched window (1.48 m wide, sill 8.1, spring 10.0, top 10.74) in a trim surround with sill and
keystone, a frieze panel and the dentilled top cornice (11.65 to 12.3 m). Photo measures were scaled
to LoD2's cornice (x 0.94).

## 4. Roof
Grey sheet metal (as the convent wing's next door): the nave's low gable kept under the attic, the
chancel's hip. An iron cross on a small pedestal on the attic's top tier.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e8c19f | M_STONE |
| Trim (columns, cornices, surrounds) | #f0d3b6 | M_STONE |
| Recessed panels | #d8ac8a | M_STONE |
| Plinth, step | #b9b2a2 | M_STONE |
| Roofs | #7c7f84 | M_STONE |
| Door | #4a3b36 | M_STONE |
| Window, fanlight | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`). Card text: "Kościół Niepokalanego Poczęcia NMP",
"The small classicist Res Sacra Miser church on Krakowskie Przedmieście." No floodlights.

## 7. Detail level and budget
L3, triangle budget 720 (measured 644, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_niepokalanego`; the front alone `--solo=church_niepokalanego --lift=7.6
--cams=front:-654.2,,-1239.1,290,-6,20`; in the city from the square `--at=-672,-1236 --yaw=290`.
Open photo checks: the back (chancel, east gable) and the roof's covering are unseen from the
square (built from LoD2, plain); the attic's corner blocks are simplified; the north and south
walls stand against the neighbours and have no openings.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism on the outline, eaves band | 8.8-9.6 x 17.5 m, 12 m | front at v -0.75 | M_STONE | massing |
| nave roof | gable along v, east gable wall | 9.2 m wide, rise 2.0 | v -1 to -18.15 | M_STONE | 4 |
| chancel | box, eaves band, hip | 8.5 x 6.3 m, 6.5 m, hip 4.7 | v -18.15 to -24.45 | M_STONE | massing |
| piers and upper wall | 3 boxes | 0.75 m deep | u 0-3.35, 5.65-8.77; 6-12 m | M_STONE | 1 |
| door bay | step, kit_door, two half-round panels | 2.45 m door, 0.76 m fanlight | c, v -0.75 | M_STONE | 2 |
| columns | 2 kit_column TUSCAN | r 0.36, 5.8 m | c +- 1.45, v -0.15 | M_STONE | 2 |
| lower entablature | ledge, panel, cornice | 7.25-7.6 m | full width | M_STONE | 1 |
| middle field | box, 4 kit_pilaster | u 1.7-7.3, 0.12 proud | 7.6-11.35 m | M_STONE | 3 |
| window | two half-round panels, sill, keystone | 1.48 x 2.65 m | c, sill 8.1 | M_STONE | 3 |
| top cornice | dentil band, slab | 0.55 m proud | 11.65-12.3 m | M_STONE | 1 |
| attic | 4 tiers with copings | 0.95 m deep | 12.3-14.75 m | M_STONE | 4 |
| cross | pedestal, iron staff and arm | 1.7 m | c, v -0.45 | M_STONE | 4 |
