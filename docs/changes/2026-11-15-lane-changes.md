- Cars no longer swerve sideways where a street gains or loses a lane: they move over along the road's taper, as on a real street.

## Backlog
- fixed: RT-4 lanes, the link between two ways of one street was 3 m long, so every lane that did not line up jumped half a lane or more inside it (586 links steeper than 1:6 → 84; `tools/lane_changes.py`, verify step `lanechanges`; road_truth R1 329 → 44 of 379 lane count changes by its new rule, R3 261 → 229)
- fixed: road_truth counted every lane count change as R1 and every turn pocket as a blip (R2 71 → 39 with pockets left out); R1 and R3 now tell a link along a taper from a jump
- found: 39 blips (Miedziana, Hoża, Bracka, Tamka, Browarna ...) whose drawn asphalt bulges or pinches for a few dozen metres; joining them moves kerbs, lines and junction corners (RT-4 geometry, a guarded pass or road design areas)
- found: 84 continuation links still jump (short ways between two joins, a stop line or bus stop at the node, a bend)
- found: where a lane ends there is no P-21 hatching or P-9 arrows yet (RT-4 paint)
- found: 212 R3 lane shifts are inside junctions (a one-way street meeting a two-way one, the next street's lanes elsewhere); they need the edges moved (RT-6, road design areas)

## Roadmap
- ticked: "Roads true to life RT-4: lane changes as paint" (the lanes; the blips' geometry and the hatching left)
