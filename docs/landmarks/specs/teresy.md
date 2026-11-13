# Kościół św. Teresy od Dzieciątka Jezus (Powiśle parish church, Tamka): spec

Site key `teresy` in `game/scripts/landmarks.gd` (`_find_teresy`, `_build_teresy`). First written
2026-11-01 from the OpenStreetMap outline with no photo (a brick guess); REBUILT 2026-11-13 from
F's photos (a corner view from Tamka, a visualisation of Flisac with the church beside it). The
outline "Parafia Świętej Teresy od Dzieciątka Jezus" in `centrum.json` still gives the footprint.
Photos are reference only, never in the repo. Still open *(photo check)*: the exact window count,
the side door's place and whether the copper spire stands on the street corner or behind it.

## 1. Identity

A light cream plastered parish church of Powiśle, 20th century, plain and tall. Defining: the long
nave with tall round-headed lattice windows over plain panels, the front gable with a round window
over a big arched porch, a green copper gutter line under the eaves, a slim copper-capped spire
beside the front, a lower chapel and the parish house behind. Not brick.

## 2. Massing

Frame: origin (369.93, -579.04) (the outline's centre), u along the nave (axis (0.643, 0.766)), +v
to the right. Nave u -10..21.8, v -7.8..14.3 (31.8 x 22.1 m), plinth 1 m, walls to the eaves at
12.6 m, a gable roof rising 7 m to a 19.9 m ridge. Front gable at u +21.8 (towards Tamka). The lower
annex u -13.4..-10 (6.5 m), the polygonal chapel on the -v side (7.5 m, cap to 9 m), the parish
house behind (8.5 m, hipped roof to 12.1 m). The stair tower: 3.4 x 3 m, u 15.9, v 14.65 (a
little proud of the +v wall), to 21 m, copper pyramid to 30 m, a gilt cross to 32.2 m.

## 3. Facade, base to top

Plinth in a darker trim, cream plaster above. Each side wall: five round-headed windows (1.9 m
wide, 7.3 m tall from 4 m up) in a pale frame, dark lattice glass (two bars, three transoms), a
plain recessed panel under each sill; corner piers in trim. Front: a stepped plinth, the arched porch
(6.8 m wide, round head, a dark recess with a smaller arch and a brown door, three steps), a round
window (r 1.65 m in a trim ring) under the gable, corner piers up to the cornice, a gilt cross at
the apex. A small brown side door with a hood and steps by the front corner.

## 4. Roof

Grey-green gable roof `#5f6c66`, a copper-green gutter band `#6f9d88` over a trim cornice; the
tower's pyramid in the same copper; chapel and house in the same grey-green.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Plaster | #e4dbb8, lower blocks #d9d0ac | M_STONE, M_MONUMENT (house) |
| Trim, frames, piers, steps | #efe8cf | M_STONE |
| Roof | #5f6c66 | M_STONE |
| Gutter band, spire | #6f9d88 | M_STONE |
| Window glass, porch recess, round window | #343a40 | M_PANE (lit by chance at night) |
| Door | #5b3626 | M_STONE |
| Crosses | #c9a24a | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by the nave, the parish house and the chapel (three rings). Card: "Kościół św.
Teresy od Dzieciątka Jezus", PL "Jasny kościół parafialny przy Tamce, z wysokimi łukowymi oknami,
okrągłym oknem i wielkim portalem.", EN "A light parish church on Tamka, with tall arched windows, a
round window and a big arched porch.". Night: the window
panes are M_PANE, lit one by one by chance.

## 7. Detail level and budget

L3, triangle budget 900 (`check_mesh_quality.gd`, `teresy`). Shots: `--at=370,-579 --solo=teresy
--size=40 --yaw=20` (front and tower) and `--yaw=120` (the side wall).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| plinth | box | 31.8 x 22.1 m, 1.6 m high | u 5.9, v 3.25 | M_STONE | 3 facade |
| nave walls | box | 31.6 x 21.9 m to the eaves | 1..12.1 m | M_STONE | 3 facade |
| gutter and cornice | two boxes | 0.4 m each | 12.1..12.9 m | M_STONE | 4 roof |
| roof | gable | 22.8 m span, rise 7 m | 12.9..19.9 m | M_STONE | 4 roof |
| side windows | 10 arched panes with frame, bars and panel | 1.9 x 7.3 m | u -5.6..16, both sides | M_PANE | 3 facade |
| corner piers | 4 boxes | 1.4 x 0.9 m | the nave's corners | M_STONE | 3 facade |
| porch | trim arch, dark recess, door, 3 steps | 6.8 x 7 m | u 22, v 3.25 | M_PANE, M_STONE | 3 facade |
| round window | two discs | r 2.1 and 1.65 m | 15 m up | M_PANE | 3 facade |
| annex | box | 3.4 x 17 m, 7.1 m high | u -11.7, v 5.8 | M_STONE | 2 massing |
| chapel | 6-sided prism and cap | 8.6 x 4.3 m, 9 m high | v -7.9..-11.9 | M_STONE | 2 massing |
| parish house | box and hip | 15.1 x 14.8 m, 12.1 m high | u -3.25, v 21.6 | M_MONUMENT | 2 massing |
| stair tower | shaft, louvres, pyramid | 3.4 x 3 m, 30 m with the cap | u 15.9, v 14.65 | M_STONE | 4 roof |
| crosses | 4 boxes | 2.6 and 2.2 m | gable apex, tower | M_STONE | 4 roof |
