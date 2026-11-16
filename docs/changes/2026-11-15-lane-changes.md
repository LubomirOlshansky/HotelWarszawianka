- Crazy taxis no longer start in a cul-de-sac where no fare can reach them.

## Backlog
- fixed: a crazy driver could be born on a street outside the town's one connected net (Widok, Kubusia Puchatka) and look for a fare it could never reach (traffic.gd spawn, `node_scc`)
- fixed: road_truth counted every lane count change as R1 and every turn pocket as a blip (R2 71 → 39 with pockets left out); R1 and R3 now tell a link along a taper from a jump (R1 329 of 379 lane count changes still jump, R3 255)
- fixed: the loud-cars check heard two loud cars that happened to drive side by side as one car revving twice
- found: 586 continuation links move a lane over steeper than 1:6 (`tools/lane_changes.py --check`, verify step `lanechanges`, a ratchet). The pass that stretches them along the taper works (586 → 84 uncapped, 227 capped at 18 m) but is parked: traffic.gd treats every link as a short junction curve (TD-27), and with it the race bench's clear-road marks moved (Słoik from Tamka +13 s by another route, the chase escape +9 s, the ladder curve under 3 %), one race did not finish and laneassist, raceline, raceplanner and check_drive failed until the caps (TD-28)
- found: 39 blips (Miedziana, Hoża, Bracka, Tamka, Browarna ...) whose drawn asphalt bulges or pinches for a few dozen metres; joining them moves kerbs, lines and junction corners (RT-4 geometry, a guarded pass or road design areas)
- found: where a lane ends there is no P-21 hatching or P-9 arrows yet (RT-4 paint)
- found: 212 R3 lane shifts are inside junctions (a one-way street meeting a two-way one, the next street's lanes elsewhere); they need the edges moved (RT-6, road design areas)

## Roadmap
- added: "Roads true to life RT-4: lane changes along the taper, after TD-27 (traffic drives long links)"
