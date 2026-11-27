# Mansjonaria (Plac Zamkowy at Świętojańska): spec

Site key `mansjonaria` (`_find_mansjonaria`, `_build_mansjonaria` in `game/scripts/landmarks/old_town.gd`).
Written 2026-11-26 from F's photo of the oak on Plac Zamkowy and the Google 3D views of the house
(refs/mansjonaria, local only, reference only). Replaces street block 101331240, whose fronts stood on
LoD2's mass: LoD2 reads the ground-floor buttresses as walls leaning out the whole height (F: "fix
this building and roof").

## 1. Identity

The house on the corner of Castle Square and Świętojańska, right by the oak and the castle's west
wing: pale yellow-grey plaster, three big sloped buttresses holding the square front's ground floor
(a fourth at the north corner), a red-brick arched door between the south ones, windows in dark
stone surrounds, a cream cornice and a steep red tile hip roof with dormers and white chimneys.

## 2. Massing

The OSM outline "Mansjonaria" without its buttresses as one prism to the eave (12.4 m over the
square). Frame: from the square front's north corner (-689.81, -1564.41) to its south corner
(-679.35, -1575.45), u south along it (15.2 m), +v out to the square; the house runs back to
v -17.1.

## 3. Facade

- A grey stone plinth to 0.55 m round the whole plan.
- The buttresses on the square front at u 0.1..2.08, 4.15..7.23 and 8.3..11.2: 1.85 m out at the
  foot (deeper than the mapped 1.48 m: the photo's buttresses dominate the corner), sloping back
  to 0.3 m at 4.3 m, a cap 0.18 m thick, a shade darker than the wall (#c9bb8c); a cream band
  round the house at 4.55 m over them.
- Square front: the brick-arched door at u 13.2 (1.5 m wide, 3.0 m to the crown), one small window
  on the ground floor at u 3.1, four axes above (u 3.1, 5.7, 9.75, 13.2).
- South (to the castle) and north (to Świętojańska) fronts: four and five axes, three rows.
- Windows: ground floor sill 1.5 m, 1.9 m tall, framed; first floor sill 5.1 m, 2.1 m tall,
  with a small pediment; second floor sill 8.7 m, 1.85 m tall, framed; all in dark stone surrounds.
- A cream cornice 0.35 m deep at the eave.

## 4. Roof

A steep hip in red tile #b0583d, 6.2 m rise, 0.3 m over the walls, a short ridge along v. Six
dormers (two over the square, two on each side slope), wide boxes in grey sheet metal #868b8b
(the 3D views' zinc dormers) with a dark window and a small metal gable. Two white chimneys by the ridge.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Walls | #dccf9f | M_STONE |
| Buttresses | #c9bb8c | M_STONE |
| Cornice, caps, chimneys | #e8dfc2 | M_STONE |
| Window surrounds | #77736a | M_STONE |
| Glass | #353a3c | M_PANE (lit by chance at night) |
| Door arch | #9a4b38 | M_STONE |
| Roof | #b0583d | M_STONE |
| Dormers | #868b8b | M_STONE |

No new material or draw call.

## 6. Ground and night

The outline and the buttresses are solid for the car (`_collide`). No floodlight of its own; the
square's lamps light it, the windows light by chance at night. Card "Mansjonaria", PL "Dom z
wielkimi przyporami na rogu placu Zamkowego i Świętojańskiej, przy dębie.", EN "The house with the
big buttresses on the corner of Castle Square and Świętojańska, by the oak."

## 7. Detail level and budget

L2: budget 2700 triangles (2458 measured) (`check_mesh_quality.gd`).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| mass | outline prism | the plan without buttresses, to 12.4 m | world | M_STONE | 2 massing |
| plinth | ring prism | 0.06 m out, to 0.55 m | world | M_STONE | 3 plinth |
| buttresses | 3 frustums | 2-3 m wide, 1.85 to 0.3 m deep, to 4.3 m | u 0.1..11.2 | M_STONE | 3 buttresses |
| door | arched door | 1.5 x 3.0 m | u 13.2 | M_STONE | 3 door |
| windows | kit windows | 1.0-1.1 m wide | three rows, 13 axes | M_PANE | 3 windows |
| cornice | ring cornice | 0.35 m | eave | M_STONE | 3 top |
| roof | hip frustum | 15.8 x 17.7 m, 6.2 m rise | eave | M_STONE | 4 roof |
| dormers | box and gable | 1.9 x 2.0 m | six on the slopes | M_STONE | 4 dormers |
| chimneys | boxes | 0.9 x 0.7 m | by the ridge | M_STONE | 4 roof |
