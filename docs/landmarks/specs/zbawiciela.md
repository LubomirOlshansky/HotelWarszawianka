# Kościół Najświętszego Zbawiciela (Church of the Holiest Saviour): spec

Site key `zbawiciela` in `game/scripts/landmarks.gd` (`_find_zbawiciela`, `_build_zbawiciela`).
Written 2026-11-01 in a cloud thread ("Marszałkowska street by street") from the OpenStreetMap
outlines in `centrum.json` (no photo, no LoD2 here). Shapes and every height below the towers
are estimates; the towers' 76 m is the mapped height. The Mac photo check is parked.

## 1. Identity

Neo-Renaissance basilica (Józef Dziekoński and Józef Piotrowski, 1901-1911) on the south side
of Plac Zbawiciela, its front to the north, to the square. Defining: a pale plaster body, two
tall towers with copper spires, a dome over the crossing, a porch with a pediment. Before this
the map had two round 76 m posts and one 34 m box.

## 2. Massing

Frame: origin (-417.6, 1612.3) (the front's middle), u east along the front, +v out of the
front to the north. The mapped outline (simplified 0.6 m) gives the nave (15.7 m wide), the
transept (37 m wide, v -22 to -36) and the apse (to v -51). Porch 15.8 x 6.2 m, 18 m to its
cornice. Towers at u +-9.25, v -9.4, 7.8 m square, behind the porch's corners. Dome at u -0.5,
v -29.

## 3. Facade, base to top

Plinth 1.5 m (outline grown 0.3 m); a windowed storey (monument shader) to 21 m; a cornice
21-22 m. Porch: stone base, three dark portals (the middle 3.4 x 7.5 m, the sides 2 x 5.5 m),
hoods over the sides, a cornice over the middle, four pilasters, an entablature at 16.6-17.6 m,
a round window (r 1.6 m) in the pediment, three steps. Towers: square shaft to 31 m, cornice
with four pinnacles, octagonal belfry (r 3.4 m) to 50 m, cornice.

## 4. Roof

- **Nave and transept**: copper hips from 22 m, ridges at 29.5 m (nave) and 27.5 m (transept).
- **Porch**: a pediment rising 4.4 m (to 22 m) in copper, a gilt cross to 25.4 m.
- **Towers**: copper spire 51-69 m, a gilt ball, a gilt cross to 76 m.
- **Dome**: a 16-sided windowed drum (r 6.9 m) 22-36 m, cornice to 38 m, copper dome to 46.3 m,
  a windowed lantern to 50.5 m, a cap to 54 m, a gilt cross to 58.5 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #d8cfba | M_MONUMENT (windows), M_STONE |
| Trim | #ebe4d2 | M_STONE |
| Plinth, steps | #a8a08e | M_STONE |
| Copper (roofs, spires, dome) | #6f8c80 | M_STONE |
| Portals, round window | #3a3d40 | M_GLASS, M_STONE |
| Gilt (balls, crosses) | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car collision along the outline, the two towers and the steps. Card: "Kościół Najświętszego
Zbawiciela", PL "Neorenesansowa bazylika z 1911 roku, z dwiema wieżami i kopułą, na placu,
który od niej wziął nazwę.", EN "The neo-Renaissance basilica of 1911 with two towers and a
dome, on the square that took its name from it." Open *(photo check)*: the real plaster and
roof colours, the towers' stage heights and tops (belfry shape, spire or dome), the dome's
height, the porch (portico or recess).

Night lighting (2026-11-02, M_LAMP, no new material): the gilt crosses and balls (#e8c05a) glow;
the rose window is stained glass (#7a5226, dark amber by day) that glows; four lanterns on the
porch pilasters and 12 floodlamps (`ZB_FLOODS`) on the paving at the porch, the towers and the
transept ends. Open *(photo check)*: whether the real church is floodlit and in what colour.

## 7. Detail level and budget

L3 for the front and towers, L2 for the body; 3254 triangles measured (2026-11-13), budget 3400 (`check_mesh_quality.gd`); the square's colonnades (`zbawiciela_plac`) 2106 triangles, budget 2200
(`check_mesh_quality.gd`). Shot: `--at=-417,1590 --heading=340 --time=day --size=45 --nohud`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism of the mapped outline | 21 m high | outline | M_MONUMENT | 3 body |
| plinth, cornice | 2 prisms | outline grown 0.3 and 0.5 m | 0..1.5 m, 21..22 m | M_STONE | 3 body |
| nave roof | hip | 15.8 x 44.8 m, rise 7.5 m | 22 m | M_STONE | 4 roof |
| transept roof | hip | 37.6 x 14.4 m, rise 5.5 m | 22 m | M_STONE | 4 roof |
| porch | box | 15.8 x 6.2 m, 18 m high | u 0, v -3.1 | M_MONUMENT | 3 porch |
| portals | 3 dark panes | 3.4 and 2 m wide | u 0, +-5.2 | M_GLASS | 3 porch |
| pilasters | 4 boxes | 1 x 0.6 m, 15 m | u +-7.2, +-3.4 | M_STONE | 3 porch |
| pediment | gable | 15.8 m wide, rise 4.4 m | 17.6 m | M_STONE | 4 roof |
| towers | 2 square shafts | 7.8 m square, 31 m | u +-9.25, v -9.4 | M_MONUMENT | 3 towers |
| belfries | 2 octagons | r 3.4 m, 32..50 m | on the shafts | M_MONUMENT | 3 towers |
| spires | 2 frustums | r 3.5 to 0.5 m, 51..69 m | on the belfries | M_STONE | 4 roof |
| dome | drum, 5 frustums, lantern | r 6.9 m, to 46.3 m | u -0.5, v -29 | M_MONUMENT, M_STONE | 4 roof |

## 9. Photo rebuild (2026-11-13)

Pass 1 (Mapillary panoramas of 2026-06) was replaced the same day by pass 2 from F's ten photos
(front, both obliques, the side with the chapel dome, two aerials; refs never committed):

- **Colours**: white plaster #efebe2, trim #f8f5ee, grey plinth #a9a7a1, grey stone portal
  columns #8f959c, pale verdigris roofs #7fb59b (the aerials), dark green caps and spires #3e5f52.
- **Front block** (u +-8.3, v 0 to -5.6, before the towers): plinth; ground storey to 15.5 m with
  a portal of four grey columns under an entablature and pediment (to 13.4 m) round a dark
  round-headed door, a statue niche and a round window in each side bay, paired pilasters;
  entablature 15.5-17 m; upper storey to 29.5 m with the tall round-headed window (5.4 m wide,
  18.4-27.9 m) with two mullions and a transom; cornice 29.5-30.6 m; a stepped attic (to 38.2 m)
  with a niche, a small pediment and a gilt cross to 43 m; statues and urns at the corners.
- **Towers** at the mapped centres (u +-9, v -9.4), 8 m square: shaft to 29.5 m with arched
  windows, cornice and balustrade with corner urns, a square stage with paired arched openings on
  every face (31-41 m), a cornice with urns, an octagonal belfry (42-48.5 m), a dark green bell cap,
  lantern, bulb and needle spire to the ball at 66 m and the cross at 69.6 m. The real height is in
  no source we reached (OSM said 76 m); the front photo puts the cornice near 30 m and the crosses
  a little over twice that.
- **Body**: the mapped outline as plain plaster to 23 m (no windowed storeys), tall arched windows
  between pilasters on the nave, the transept arms and the choir, a cornice; gabled roofs: nave
  ridge 33.5 m, transept 32 m, the transept ends with a tall arched window, a small one in the
  gable and a cross.
- **Crossing**: the mapped 35 m square as a white lantern with four windows under a verdigris cap.
- **Chapel**: the low domed chapel behind the east transept arm (the side photo, both aerials):
  10.6 m box, drum, verdigris dome, lantern, cross to 21 m. Outside the mapped outline (its own
  collision box).
- Night: the stained windows (M_LAMP), the round windows, lanterns at the portal, the floodlamps.

No new material or shader (M_STONE, M_LAMP, M_GLASS). Unseen in any photo: the north transept
arm's back and the apse's details.

## 10. Plac Zbawiciela's colonnades (site `zbawiciela_plac`)

OpenStreetMap maps the MDM colonnades round the roundabout as 7.6 m `roof` parts; the map drew
them as solid blocks. `_find_zbawiciela_plac` takes every such part within 75 m of the roundabout
and `_build_zbawiciela_plac` builds cream columns every ~3 m along the side whose nearest road
lies ahead of it, the slab (6.7-7.6 m), a green balustrade on the terrace (F's rainy photo) and a
lantern under every other pair. The frontage is MDM's site already (its stone skin). Card:
"Plac Zbawiciela".
