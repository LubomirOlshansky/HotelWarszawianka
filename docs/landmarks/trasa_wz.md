# Trasa W-Z under Plac Zamkowy: the slip roads and the cutting

F's photos (2026-11-15, from the balustrade over the tunnel looking east; kept in the shared refs
store as `trasa_wz`, never in the repo) asked for the two cobbled slip roads and the details around
them. What is built, and where:

| What | Where | Notes |
| --- | --- | --- |
| Granite setts in segmental arcs, two rows of darker gutter stones along each edge | `ground.gdshader` (`WZ_LINE`, `wz_frame`) | Nowy Zjazd (ways 246, 4393) and Grodzka (3708, 247) from just past their zebras to the foot; the painted edge lines are setts there too. One box test, a 29-point loop without branches; ground shader 219 of 260 branches. |
| Pilasters every 2.6 m and a cornice on the tall wall along Grodzka and the wall over Nowy Zjazd by the viaduct | `trasa_wz.gd` | Walls are sector-only data, so the lines are constants in the script (the phone's city builds the same). |
| White tube railings: on the low W-Z edge walls, the Stare Miasto platform's edge over Grodzka, the south pavement over Nowy Zjazd | `trasa_wz.gd` | Not solid. |
| Sandstone block facing on the escarpment's foot walls under St Anne's; stone balustrades on the six stair flights | `trasa_wz.gd` | Balustrade on each flight's north (road) cheek. |
| Stare Miasto tram stop: two white louvred shelters on the platform, one on the south pavement, amber passenger boards "STARE MIASTO 01/02", ticket machine, stop post | `trasa_wz.gd` | The map's own red-framed shelter stays. |
| The map's kiosk (building 5432) gets a lit front: goods window, a board "PAMIĄTKI · NAPOJE · BILETY · PRZEKĄSKI", awning | `trasa_wz.gd` | |
| Black bollards on Grodzka's top kerb, hire scooters (plain colours, no brand) | `trasa_wz.gd` | |
| Signs: D-6 at the zebras, Nowy Zjazd's plate with B-5, A-30 with the bus-and-walkers board, B-36 + D-3 by the wall, B-2 at the platform's nose, yellow posts on the islands | `trasa_wz.gd` | |

Cost: one mesh of about 17,000 triangles poured into the sector's places mesh; `--probe
--prebuilt --at=-630,-1412` on lavapipe: 56 → 57 main-pass draws, 31 → 32 shadow draws (the
sector had no places mesh before).

Open: Grodzka and Nowy Zjazd are drawn 3.25 m wide, about half the real width (a guarded map
pass); the rough terrain fill between the stair flights; the W-Z platform's own paving; a phone
look (PHONE-CHECK 14n).
