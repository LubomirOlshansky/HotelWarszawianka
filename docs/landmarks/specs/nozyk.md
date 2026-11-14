# Synagoga Nożyków (the Nożyk Synagogue), ul. Twarda 6: spec

Site key `church_nozykow` in `game/scripts/landmarks.gd` (`_find_churches` finds it,
`_build_church` hands it to `_build_nozyk`): the whole synagogue is one model that replaces the kit
church and the LoD2 mass. Written 2026-11-14 from F's three photos (`refs/_f/warsaw-needed-photos/top-50/T33`:
one straight onto the front, two from the courtyard's south-west; never shipped), the OSM outline,
GUGiK's LoD2 and the building's history (English Wikipedia: the 1923 semicircular choir on the
east wall, the Community's wing added to the east wall in 1977-1983). Mapillary and Panoramax have
no photo facing it (11 within 60 m, all looking elsewhere).

The kit church it replaces (2026-11-01) faced **east**, into the 1980s wing, had a grid of
windows and a **cross on the gable**. The real front faces **west** over the courtyard: the OSM
outline's west side has the risalit's 0.5 m step exactly where the photo puts the middle bays
(6.4 m wing, 10 m risalit, 6.6 m wing, the same 0.28 / 0.43 / 0.29 split as the straight-on photo),
and the 1980s wing and the choir sit on the east wall.

## 1. Identity
Neo-Romanesque with Byzantine touches (Karol and Leandro Marconi, 1898-1902; burnt 1944, rebuilt
1977-1983), the only pre-war synagogue in Warsaw still standing, in its courtyard behind Twarda.
What makes it read as itself:
1. **Cream-yellow plaster** all over, a **rusticated ground floor** of deep horizontal grooves.
2. A **three-bay middle risalit** between two tall **pylons with zinc urns**, under a **gable with a
   corbel-arch (Lombard) frieze** and a **ball finial** (no cross, no dome).
3. A big **roundel with the Star of David** in the gable, two small arched windows beside it.
4. The **arched door at the top of a flight of steps**, two arched windows either side, the
   **Tablets of the Law** over the door between **two small domed turrets**.
5. Two plainer **wings**: an arched window below, two tall windows and a **triple arched light**
   above, a cornice with corner acroteria.

## 2. Massing
Frame: origin at the front's north end on the wings' line (-1579.14, -238.72), u along the front to
the south (axis (0.0926, 0.9957), +u to the viewer's right), +v out to the courtyard (west). Ground
g is the terrain 3 m before the front's middle (13.9; the plot falls 0.5 m to the east; walls run
down to g - 1).

| Block | Plan (u, v) | Height over g |
| --- | --- | --- |
| front block | u 0 to 23.12, v -8.2 to 0 | cornice 11.6 to 12.0; hip to 14.4 (ridge along u at v -4.1) |
| risalit | u 7.67 to 15.67, v to +0.5; pylons u 6.67-7.67 and 15.67-16.67 to v +0.8 | 12.4; pylons 12.6 with urns to 13.9 |
| nave | u 6.67 to 16.67, v -8.2 to -28.6 | walls 12.4; gable along v from the front (v +0.5) back, ridge 15.0 |
| stair halls behind the wings | u 0.58-6.67 and 16.67-22.58, v -8.2 to -11.42 | lean-to 9.0 to 11.2 |
| aisles | u 2.99-6.67 and 16.67-20.4, v -11.42 to -28 / -29.4 | lean-to 9.9 to 11.2 |
| choir (1923) | the outline's east bay, u 6.93-16.79, v -27.85 to -32.1 | 12.0, low pyramid to 13.2 |

LoD2 over g (absolute ground 13.9): front block eaves 12.0 and its ridge 14.4 at v -3.8; the nave's
gable ridge 15.0 from the front gable to v -28; the aisles' lean-tos 9.7 (outer) to 11.2 (at the
nave); the stair halls' outer eaves 8.9; the choir 12.0 to 13.2. LoD2 lesenes on both aisle walls
at v -14.5, -20.6 and -26.8. The straight-on photo scales to the same heights (wing cornice 11.5,
gable apex 15.1 at 68 px/m from the 23 m front).

The Community's wing (OSM outline east of the synagogue, LoD2 to 14.9 m) has its centre inside
the site's 3 m zone, so the site would drop it: `_find_churches` passes its outline (`NZ_WING`) as
the site's keep ring, and it stays the map's LoD2.

## 3. Front (west)
Ground floor (0 to 5.35 m): an ochre plinth to 0.9 m; rustication grooves every 0.5 m to the belt;
the belt course (5.35 to 5.75). Wings: an arched window (pane 1.24 m wide, sill 1.9, spring 3.5) in a
trim surround and a carved hood, at u 4.2 and 19.15. Risalit: the door (1.72 m wide, from the top
step at 1.0 to 4.3) in a trim arch and a carved arch to 5.05; four steps 4.6 m wide out to v +2.6;
arched windows at c +- 2.75 (c = 11.67); over the door a low rail, the Tablets (grey stone, round
top, 5.85 to 7.1) and two square turrets on corbels (3.7 to 6.5) with little domes to 7.05.
Upper storey: risalit four tall windows (0.94 m wide, 6.4 to 8.5) at c +- 0.85 and c +- 2.75 between
colonnettes (paired in the middle), a sill band and a carved frieze (8.95 to 9.4); two arched windows
(sill 9.65, top 10.45) with hoods at c +- 2.75; the roundel (1.75 m radius at 11.1: a carved ring, a
trim field, the Star of David as two triangles). Wings: two tall windows (0.76 m wide, 6.4 to 8.5)
at the wing centre +- 0.75 over a panel band; a triple arched light (9.55 to 10.35) in a carved
arcade panel; a corner lesene; the cornice (11.2 to 12.0) and a small round-topped acroterion over
each outer corner. Gable: raking cornices on the nave's front triangle (slope as the roof's), eight
corbels under each, a pedestal, zinc stem, ball and spike on the apex (to about 17.1).

## 4. Sides and back
Not photographed; built in the front's language (default, see QUESTIONS): plinth, grooves and belt
on every side; the front block's ends one arched window on each storey; the stair halls one each;
the aisles a window in each bay between the LoD2 lesenes (three bays, both storeys, the lower ones
hooded), cornice at the eaves. The east end is the choir against the 1980s wing (LoD2), plain.

## 5. Roof
Grey sheet metal (#7d8486): the front block's hip, the nave's gable, four lean-tos, the choir's low
pyramid. Zinc urns and finial (#8c9694).

## 6. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #e7d4a4 | M_STONE |
| Trim (cornices, surrounds, colonnettes) | #efe1b8 | M_STONE |
| Carved bands and hoods | #d6bd86 | M_STONE |
| Plinth | #d8bd82 | M_STONE |
| Roofs | #7d8486 | M_STONE |
| Urns, finial | #8c9694 | M_STONE |
| Tablets | PAL_GREY_STONE | M_STONE |
| Door | PAL_OAK | M_STONE |
| Windows | PAL_GLASS_DARK | lit by chance at night (`_lit`) |

No new material, shader instruction or draw call. Arched windows stack their layers 4 cm apart:
`_wall` drops a later wall within 3 cm of an earlier one in the same plane, which first hid the
panes behind their surrounds.

## 7. Ground and night
The car is stopped by the outline (`_collide`). Card text: "Synagoga Nożyków", "Jedyna przedwojenna
synagoga Warszawy, przy Twardej." / "Warsaw's only pre-war synagogue, on Twarda." No floodlights.

## 8. Detail level and budget
L3, triangle budget 2900 (measured 2625, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_nozykow`; the front alone `--solo=church_nozykow --lift=8
--cams=front:-1578.1,,-227.1,270,-4,22`.
