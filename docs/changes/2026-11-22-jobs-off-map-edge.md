- Deliveries, rides and other jobs no longer send you to the very end of the map: every target is now well inside the city.

## Backlog
- fixed: a tester's kebab order at the very end of the map (2026-11-22): a door 5 m from the outline, behind the edge roadworks. All job targets (kebab orders, Podwózka pickups and drop-offs, the trend job, the EV tow, crash scenes, Leżak depots and pins, rescues) keep 80 m inside the map's outline (lane_graph.gd `TARGET_PAD`, `in_play`); 219 of 3,389 addresses are left out; check_edge E4 guards it
- found: rescue calls near the edge have fewer places now (their pad went from 40 to 80 m); watch on the phone that no job runs dry in a corner district (Wola west, Praga east; row 15zs)
- found: authored places (bar crawl, shisha, rave, tours, street meets) are hand-placed, not under the pad and not read by check_edge E4

## Roadmap
- adds: "Every job target at least 80 m inside the map (phone row 15zs)"
