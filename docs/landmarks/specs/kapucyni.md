# Kościół Kapucynów (Przemienienia Pańskiego), Miodowa 13: spec

Site key `church_kapucyni` in `game/scripts/landmarks.gd` (`_find_churches` finds it, `_build_church`
hands it to `_build_kapucyni`): the whole church is a model that replaces the kit church and the LoD2
mass inside the OSM outline (29 points, 21.7 m wide, 31 m deep). Written 2026-11-14 from F's Commons
photo (top-50 set, `100-kosciol-kapucynow-exterior-2`: the front and the long wall by day), ten
Mapillary views (a 360 of the front) and the OSM outline. Heights are estimates from the photo
(OSM says 14 m): the LoD2 numbers were not read.

## 1. Identity
Baroque church of 1683-1692 (front 1750s), rebuilt after 1944. What makes it read as itself:
1. A narrow **salmon-pink pavilion** with two pairs of cream pilasters, an arched window over a stone balcony, a triangular pediment with a cartouche, a pedestal and a cross.
2. Steps and balustrades up to the portal; urns on the pediment's feet.
3. **Low cream wings** either side with scrolls up to the pavilion, a statue on a pedestal on the right one.
4. A long **cream nave** with tall arched windows over lower aisles and a hipped **pale green copper roof** with an iron cross.

## 2. Massing
Frame: origin at the front's east end (-958.7, -1428.0), u along the front (+u to the viewer's right,
axis (-0.7275, -0.6861)), +v out to Miodowa. Main wall at v = 0.8.

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| low mass (aisles, wings, sacristy, apse) | the outline, front straightened to v = 0 | 7.4 m, copper top, cornice |
| nave | u 1.5 to 20.2, v -2.5 to -29.5 | eaves 12.5 m, hip to 17.5 m, cross to 20.2 m |
| pavilion | u 6.0 to 15.7, v 0.8 to -6.9 | cornice 12.35 m, pediment apex 15.45 m, cross 19.1 m |
| wings | u 0.9 to 6.0 and 15.7 to 20.8 | 8.4 m |

## 3. Facade
Landing and steps in sandstone grey (1.3 m, four treads), balustrade piers; pavilion fields salmon,
pilaster pairs at +-2.3 and +-4.15 m from the axis (0.85 m wide, 7.6 m tall), portal 2 x 3.4 m, arched
window 1.9 x 3.9 m over a stone balcony, inscription band, cornice, pediment 9.2 m wide, 3.1 m tall.
Wings: arched window, cornice, three-step scroll, statue on a pedestal to 12.5 m. Nave: four arched
windows and five pilasters a side, two low windows per 6 m on the aisle wall, a rear arched window.

## 4. Roof
Pale green copper (#76a592) on the nave hip, the pavilion gable and the low mass. Iron crosses on the
ridge and the pediment.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ecdfb4 | M_STONE |
| Trim | #e8d6aa | M_STONE |
| Front | #d8806a | M_STONE |
| Steps, plinth | #b9b2a2 | M_STONE |
| Copper | #76a592 | M_STONE |
| Windows | PAL_GLASS_DARK | M_PANE (kit) |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`). Card kept: "Kościół Kapucynów". No floodlights.

## 7. Detail level and budget
L3, triangle budget 2400 (measured 2136, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_kapucyni`, then in the city `--at=-968,-1436 --heading=315`.
Open photo checks: the wall to the west (cloister), the apse and back (plain), the exact heights, the
dome-topped chapel and the statue on the street corner (outside the outline, not built), the nave's
upper windows (the photo shows pairs), the volutes (stepped boxes).
