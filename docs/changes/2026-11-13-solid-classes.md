## Backlog
- fixed: 0 Solid classes in the collider (`_wall_faces` by class, one body per class per sector, `solidity.gd`, `check_solids`): no change in behaviour; it comes before item 1
- found: the water's edge (map_builder `_build_shore`) has no solid class of its own; filed under `struct_wall` until the palette gets a `shore` class
- found: the Old Town's city walls are filed under `wall` (barrier walls); a later rule by height must not treat a 1-1.5 m ruin stub of the city wall as a garden wall
- found: a car park mouth's barrier arm is filed under `garage_door` and the Powiśle viaduct's closed bays under `struct_wall`, the nearest classes
- found: the runtime sectors hold 644,365 collider faces and the whole-city build 644,223 (+6 edge boxes): 142 faces are built only in the sectors (unchanged by this step; check_streaming's identity part would name them)
- found: a prebuilt sector now has up to 49 pieces (was 40) because every class has its own collider patches, and the streamer's gate loads one piece a frame: sector s_-1_0 streams in 47 frames instead of 37 (the CPU cost is within noise). For the performance lane: let the gate count collider faces, not pieces, and measure on the phone
- found: two printed speeds in `check_stuck_spots` (PT-40, the Poniatowski tower) moved by 0.1-0.2 m/s with an identical face set, because contacts are now resolved per class body; all rows still pass and no recorded number changed
