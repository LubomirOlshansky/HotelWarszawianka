# Kościół św. Ducha (the Paulines'), Długa 3: spec

Site key `church_duch` in `game/scripts/landmarks.gd` (`_find_churches` finds it, `_build_church`
hands it to `_build_duch`): the whole church and both its towers are one model that replaces the
kit church (one guessed helm) and the church's LoD2 inside the OSM outline (39 points, 23 m wide,
44 m deep from the Freta / Długa / Nowomiejska corner by the Barbican). Written 2026-11-14 from
Mapillary photos (refs/sw_ducha and refs/sw_ducha_far, never shipped): the front from Freta
(2016, three shots: the front's pilasters, statues, pediment and the near tower), the front from
Mostowa (2020: the whole front, the near tower's belfry and cap), the lower front close by (2020:
the portal's segmental hood, the niches with statues, the balustrade panels) and three shots
down Długa (2016: the Długa side, the clerestory, the chapel's pediment and both towers' caps over
the nave), and GUGiK's LoD2 (heights over its ground at 0.2 m: towers' walls 26.9, their caps to
35.5, the front's cornice 20.6 and pediment 25.5, nave eaves 20.6 and ridge 25.0 with a hip at
the east end, chapels 12.2-12.4, the Częstochowa chapel's gable 14-15). Commons is blocked from
the cloud; no aerial photo.

## 1. Identity
Baroque church of the Paulines (1707-1717, Józef Piola and Józef Szymon Bellotti), burnt in 1944
and rebuilt by 1956. What makes it read as itself:
1. A **cream two-tower front** facing the Barbican: two storeys of paired pilasters, an arched
   portal, statues in niches, an arched window and a **triangular pediment** with an oculus.
2. The **two square towers** flush with the front, each with a belfry stage (arched openings, a
   round clock window), urns at the corners and a **green copper bell cap with an open lantern**,
   a bulb and a cross, seen over the roofs down Długa and Freta.
3. A tall cream nave under a **pale green copper roof**, arched clerestory windows, the chapels'
   lean-to on the Długa side and the Częstochowa chapel's pediment to Długa.

## 2. Massing
Frame: origin at the kit's front point (-1005.6, -1848.8), u along the front (axis (-0.8491,
-0.5283), +u to the Długa side), +v out of the front towards the Barbican. Heights over the ground.

| Block | Plan (u, v) | Height |
| --- | --- | --- |
| body (chapels, aisles, sacristy) | the outline for v < -5.3 | 12.3 m, copper flat top, cornice ring |
| front block | u -6.9 to 6.6, v -0.4 to -5.3 | 20.6 m, pediment to 25.5 m, cross to 27.8 m |
| towers | centres u 8.65 and -9.0, v -2.9, 4.2 x 4.9 m | walls 26.9 m, cornice 27.5, cap 30.3, lantern 32.3, bulb 34.4, spire 36.0, cross 37.4 |
| nave | u -6.5 to 5.9, v -0.9 to -38.9 | eaves 20.6 m, ridge 25.0 m, hip from v -33.2 |
| chapels' lean-to | u 5.95 to 11.0, v -5.3 to -28.4 | 12.5 to 14.4 m |
| Częstochowa chapel | u 5.95 to 11.7, v -28.4 to -38.9 | eaves 12.5 m, gable to 15.1 m across |

## 3. Facade
Front (v -0.45): a plinth band, four pairs of pilasters on each storey (0.7 and 0.6 m), the
towers' corner pilasters on the lower storey, the entablature at 12.3 m across front and towers,
a panel band over it, the cornice at 20.6 m. Lower storey: the portal (an arched oak door 1.9 x
4.2 m in a frame, a segmental hood, a dark plaque over it) and two arched niches with statues.
Upper storey: the arched window (2.2 x 4.8 m) and two niches with statues. The pediment (13.7 m
wide, 4.4 m tall) with an inner relief panel, an oculus, a copper ball and an iron cross.
Towers: a small framed window and an oculus on the front face, a window and an oculus on the
other faces; the belfry (21.2 to 26.9 m) with corner strips, an arched opening and a round clock
window on every face. Nave: five arched clerestory windows a side between lesenes, an oculus in
the east wall under the hip. Długa side: four arched windows between lesenes on the chapels, the
Częstochowa chapel with four pilasters, a tall arched window and a round window in its gable.
Monastery side: three arched windows on the courtyard between the wings. Windows are flat arch
panels (trim and dark glass).

## 4. Roof
Nave: pale green copper gable roof (#72a490), its ridge along v from the front block to v -33.2,
a hip at the east end. Front block and body: copper flat tops; chapels: copper lean-to; the
chapel: a copper gable across with its pediment to Długa. Towers: darker copper (#5b8a78) bell
caps (8 sides, widest 2.12 m), open lanterns (cream posts, iron openings), bulbs, spires, gilt
balls, iron crosses; four urns on each tower's cornice.

## 5. Colour and material
| Part | Colour | Material |
| --- | --- | --- |
| Plaster | #ece2c6 | M_STONE |
| Trim | #f6f0de | M_STONE |
| Copper (roofs) | #72a490 | M_STONE |
| Copper (caps) | #5b8a78 | M_STONE |
| Plinth | #b8b1a0 | M_STONE |
| Statues | PAL_GREY_STONE | M_STONE |
| Windows | PAL_GLASS_DARK | M_PANE (lit by chance) |

No new material, shader instruction or draw call.

## 6. Ground and night
The car is stopped by the outline (`_collide`); the monastery's wings close the -u side and the
back. Card kept: "Kościół Świętego Ducha". No floodlights.

## 7. Detail level and budget
L3, triangle budget 3300 (measured 3010, `check_mesh_quality.gd`). Shots: `tools/turntable.sh
church_duch`, then in the city `--at=-990,-1800 --heli --heli-alt=35 --size=55`.
Open photo checks: the lower front's middle (one close photo shows it convex; built flat on the
outline), the towers' cap profile and the lantern's height (LoD2 stops at 35.5 m), the Długa
side's window count, the chapel's pediment relief, the east end behind the monastery (unseen).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | prism on the outline | 1.5 m | outline | M_STONE | 1 massing |
| body | prism, copper top, cornice ring | 12.3 m | outline v < -5.3 | M_STONE | 3 nave |
| front block | box, copper top | 13.5 x 4.9 m, 20.6 m | u -0.15, v -2.85 | M_STONE | 1 front |
| front storeys | 16 pilasters, tower pilasters, entablature, panel band, cornice | 22 m wide | v -0.45 | M_STONE | 1 front |
| portal | frame, arched door, segmental hood, plaque | 2.7 x 5.1 m | front middle | M_STONE | 1 portal |
| niches | 4 arched niches with statues | 1.2 m wide | u ±3.85, lower and upper storey | M_STONE | 1 front |
| upper window | arch panel | 2.2 x 4.8 m | front middle, 14.2 m | M_STONE / M_PANE | 1 front |
| pediment | triangle, relief, oculus, ball, cross | 13.7 x 4.4 m | over the front | M_STONE | 1 pediment |
| towers | 2 shafts, ledge, cornice rings, 4 faces each | 4.2 x 4.9 m, 26.9 m | u 8.65 and -9.0 | M_STONE / M_PANE | 2 towers |
| caps | 8 urns, bell cap, lantern, bulb, spire, gilt ball, cross | r 2.12 m, to 37.4 m | each tower | M_STONE | 2 caps |
| nave | box, cornice, gable roof, hip | 12.4 x 38 m, eaves 20.6 m, ridge 25.0 m | u -0.3 | M_STONE | 3 nave |
| clerestory | 10 arches, 8 lesenes, east oculus | 1.7 m wide | nave walls | M_STONE / M_PANE | 3 nave |
| chapels | lean-to roof, 4 arches, 3 lesenes | 22 m long | Długa side | M_STONE / M_PANE | 3 Długa side |
| chapel | gable roof, 4 pilasters, arch, round window | 10.5 m wide | Długa side, v -28.4 to -38.9 | M_STONE / M_PANE | 3 Długa side |
