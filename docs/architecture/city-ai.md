# City AI: cars, police, trams, trains and people

How the city moves by itself. Everything here is built to be cheap: cars ride on the lane graph
instead of physics, people are instances in one MultiMesh, and decisions run a few times a second.

## 1. The layers

```
lane_graph.gd   the road network baked from OSM: directed edges, lanes, junction curves, lights
     │
traffic.gd      every AI car: one Driver per car on the graph, drawn as one MultiMesh per kind
     ├─ rivals.gd        named racers: wander as traffic, race with race_to / stop_racing
     │    ├─ race_session.gd  one race's mechanics: the course, the racers, their plans, effort and order
     │    ├─ race_planner.gd  a racer's plan: seconds to the finish from every street, by its own skill
     │    ├─ race_line.gd     a racer's line: its place on the ground and a speed for every metre of its way
     │    ├─ race_signals.gd  a racing rival's lights: brake lights, indicators, hazards, headlight flash, wobble
     │    └─ race_report.gd   a race's two ways and what decided it, for the result card and its picture
     ├─ police.gd        patrol cars (POLICE kind) + perception + the chase state machine
     │    └─ police/     beehave trees that only move a unit's car (5 Hz, ticked by hand)
     ├─ buses.gd         buses on traffic's BUS pool, sent to stops (send_to_stop / let_go)
     ├─ crazy_drivers.gd voices for traffic's crazy racer-mode cars
     ├─ crash_scenes.gd  two parked cars and a police car on a main road ahead
     └─ loud_cars.gd     a supercar meet parked by the road
trams.gd, tram_fleet.gd, old_tram.gd   trams on the baked rails, same lights as cars
trains.gd                               trains on the baked railway tracks
pedestrians.gd  walkers on footways in one MultiMesh, plus fixed "slots" other systems rent
     ├─ crowds.gd        queues, roof crowds, river people (still figures, same mesh)
     ├─ city_life.gd     dog walkers, cyclists, runners, Hyrax, the Wiralek trend cycle
     ├─ packs.gd         running clubs and coffee crowds
     ├─ fans.gd          football fans on match evenings
     └─ wellness.gd      sound healing, yoga and other park circles
plac_zamkowy_life.gd   tourists and a pigeon flock on Plac Zamkowy (own MultiMeshes, sleeps beyond 190 m, same flush rule as eggs.gd)
```

## 2. Traffic (`traffic.gd`, `lane_graph.gd`)

- **A Driver is a cursor on a lane**: edge `e`, lane, distance `s`, speed. It follows the lane at
  the road's speed, picks a random way at junctions (`next_lane`), keeps its gap with a simple
  intelligent-driver model (`ACCEL`, `DECEL`, `HEADWAY`, `MIN_GAP`), stops at red lights
  (`light`) and for the player's car.
- **It exists only near the view.** Cars appear and vanish out of sight, so the count stays near a
  target from how much road is on screen (`MAX_CARS` 140 pool). The governor and the Traffic
  setting scale that share. Cars out of sight update every other frame.
- **Collision only close by.** A small pool of kinematic bodies (`BODIES` 12 within
  `BODY_RANGE` 40 m) gives the nearest cars a collider. A hit car is shoved and dazed
  (`on_player_bump`, `_shove`), then drifts back into its lane.
- **Kinds**: CAR, TAXI, VAN, BUS, POLICE, NODE (a car drawn by its own node, like a rival). Each
  kind's MultiMesh draws a family of shapes picked in the instance's custom data.
- **The API other systems use** (never move a Driver's fields by hand): `add_node_driver`,
  `add_ghost`, `remove`, `teleport`, `race_to(d, finish, dist, plan)`, `stop_racing`, `reroute`,
  `turn_next`, `remaining`, `add_police`, `park` / `unpark`, `add_parked_car`, `lane_free`,
  `set_lights`, `add_bus`, `send_to_stop`, `let_go`; for a race also `race_density()` (the
  town's traffic as it is now), `race_delay` (what it costs a racer on a street) and the signal
  `turned_back` (a racer found its street blocked).
- **Routes** come from the lane graph: `distances_to(node)` once per target gives the cost from
  every node, then every car just takes the cheapest next edge. `snap(p, reach, heading,
  ground_only=...)` puts a point on a lane; pass `ground_only` for anything on the street level
  (tunnels and decks share x/z with the street).

## 3. Racers (`rivals.gd`, design in docs/design/race-ai.md, tuning in docs/design/race-ai-tuning.md)

Rivals are traffic Drivers with a personality. The race AI rebuild is four layers plus a profile
and a race object: RaceNav (where a car can go, with race links), RacePlanner (seconds to the
finish per racer), RacePath (racing line and speed per metre), RaceDriver (overtakes, collisions,
recovery), RacerProfile and RaceSession. **No rubber band**: difficulty comes from each rival's
skill, not from the player's speed. Built so far (steps 1 to 4a of 8):

- **The profile** is a rung's racer stats in `ladder.gd` (how much of the car it uses, its
  mistakes, what it knows of the town's traffic and how it weighs a street with no way past);
  `RaceSession.arm_racer` puts them on the Driver, and the rival rolls its own dice (`race_rng`).
- **The race session** (`race_session.gd`, step 6b part 1a: a `RefCounted` a race, no HUD, no
  words, no pay): the course (the junctions in order, the last the finish and its circle), its
  racers (a Driver each, the profile, the shortcuts, per leg the distances and the plan), the
  start (`arm_racer`, `race_to`), the legs, the effort (`pace_tick`, 5 Hz `rank`), the order, the
  reroutes after `turned_back` / `hop_refused`, the lights' tick and the end. `rivals.gd` (the
  ladder, the guided first race, Trzy mosty) and the race bench (`race_bench.gd` `race`) both race
  on it; the words, cards, ghost, the player's checkpoints and the pay stay theirs.
- **The plan** (`race_planner.gd`, one `RacePlanner` for the map, one `Plan` a race or a leg): a
  search back from the finish gives this racer's seconds to go from every street, with the
  shortcuts it knows and the delay it expects from the town's traffic (`Traffic.race_delay`,
  fitted on the bench by `tools/race_traffic.sh`). `race_to` takes the plan; at every junction
  the Driver asks it (`choose`), so it takes the quickest way and not the shortest. `rivals.gd`
  searches the plan a slice a frame from the challenge on (`_plan_tick`), never in one frame.
- **The line** (`race_line.gd`, one `RaceLine` in `traffic.gd` for the map): a racer with a plan
  drives its way as one line inside its lane and its junctions' room, with a speed for every
  metre from its grip and its brakes, so it brakes before a bend and holds it like the player's
  car. A stretch of line between two long streets is built once and shared by every racer. The
  Driver's rail stays (`s`, `cu`, lanes, gaps, lights): only its place on the ground (`_place`,
  `_line_at`) and its top speed for the frame (`_line_ahead`) are read from the line, and it asks
  its plan for its streets 100 m ahead (`way`). A racer beside its line (a pass, a lane change)
  is `line_dyn` m off it, and `_line_busy` says where no sideways move may start (in a corner).
  `check_race_line` builds every stretch of the map and holds the line to its room.
- **A blocked street**: the Driver shuts it in its plan (`block`), turns round in a two-way
  street or backs out of a one-way one, and `turned_back` tells `rivals.gd` to count the metres
  left without it (`reroute`).
- **The finish** is one line for both cars. A street race's finish is a circle
  (`FINISH_RADIUS`), and where another road runs through it (`RacePlanner.ends`: 8 of the 11
  finishes, and Trzy mosty's) the line runs across that road where it enters the circle, in
  whichever lane. The plan, the metres left (`Plan.metres`, `RacePlanner.links`), the rival's
  `arrived`, the player's `Rivals.home_at` and the minimap's route (`route_line.gd`) all end
  there. A new finish needs nothing: its roads are found from the map.
- **Out of the town's cars** (traffic exists only round the view) a racer pays the delay its
  streets would have cost, as ground not covered (`AWAY_*`), so a race out of sight is not a race
  on empty streets.
- **Told apart** (step 6a). A rival's own numbers in `ladder.gd` beyond its pace: `dare` (the
  clear oncoming road a pass needs), `indicate` and `flash` (how early it indicates, how soon it
  flashes its headlights at a slower car), `home` (districts whose every shortcut and yard it
  knows: `RaceCuts.links`' `home`). **The lights** (`race_signals.gd`) are read from the Driver
  every frame of a race by `rivals.gd` (`_signal_tick`) and never change how it drives: `tick`
  is pure (a `State`, the Driver, the graph), `build` makes four lamp meshes on the rival's
  `body` node, shown only while lit. A new thing a rival should be seen to do is a field on the
  Driver that `tick` reads, not a second copy of the decision. **The report** (`race_report.gd`)
  keeps both cars' ways through a race and at its end names what decided it (the route, the
  standing, the pace); `rivals.gd` adds its lines to the result card and its picture
  (`RaceReport.Sketch`) through `hud.set_card_art`.
- The night club's pack race (`street_meet.gd`, `ladder.gd` `CLUB`) races on the session too
  (step 6b part 1b): a plan, a racing line, shortcuts and lights each, and no report. The
  autopilot's ghost and Halina's roll-up behind the car before the first race (`call_first`)
  still go by metres (no plan), and only the ladder races and the final have a report. The
  police chasers and the crazy drivers are steps 6b-2 and 6b-3.

Still to come: RaceDriver (passing, contact and recovery are the old rail car's; its pass over
the centre line, `_race_pass`, minds only the oncoming lanes it uses and how fast the two cars
close, and is a timer until step 4b), RaceNav's links; a new race mode uses
RaceSession instead of its own ranking. Every race change reports `tools/race_bench.sh` before and after (`check_race_bench`,
`check_race_planner`, `check_race_line`).

## 4. Police (`police.gd`, `police/`)

The gentle police: warnings and jokes, never a fine. Read docs/design/police.md before a change.

- **Perception** once every 0.2 s for every unit: distance, a 180° cone, sight through the roof
  grid, the player's lane and limit. Offences: speeding past a patrol, red light, wrong way, a bump.
- **One state machine in police.gd**: CALM, LIZAK, CHASE 1-3, SEARCH, PULLOVER, then a cooldown.
  Every chase ends by itself.
- **Beehave trees only move cars** (`police_unit.gd`, `police/bt/*`), ticked by hand at 5 Hz.
  City guards on foot (`police/guards.gd`, `guard_unit.gd`) are fixed pedestrians with a tree.
- **The pull-over talk** is Dialogue Manager (`game/dialogue/police.dialogue`,
  `police_balloon.gd`, `police_talk.gd`); words in `data/dialogue.json`.
- **Rule from CLAUDE.md**: new behaviour that chooses between several actions decides on Beehave
  first (skill `beehave-trees`). Default: not used outside the police and authored scenes.

## 5. Rail (`trams.gd`, `tram_fleet.gd`, `old_tram.gd`, `trains.gd`)

Trams follow OSM track pieces, stop at platforms, obey the car lights and brake for anything in
their swept width (`AHEAD_REACH` along the curve). The fleet has four looks. Trains run on the
railway tracks and come in and out at the map edge.

## 6. People (`pedestrians.gd` and its renters)

- **One MultiMesh, about 60 walkers** (`MAX`, scaled by quality), legs swung in `actor.gdshader`.
- **Fixed slots in the same MultiMesh** are rented by other systems for +0 draw calls:
  `set_fixed` (trap officers, guards), `set_guest` (city life), `set_stop` (bus stops),
  `set_scene` (crash scenes). The slot ranges are agreed by hand today (tech-debt TD-6).
- **Crowds, packs, fans, wellness** draw still or looping figures in the same person mesh and
  material. They switch on by the game clock and place (`hours`, weekdays).
- **Reactions** go through bubbles and the chatter budget (`say_reaction`, `say_ambient`), never a
  private cooldown.

## 7. Adding city behaviour: the checklist

1. A new kind of car: a traffic kind or shape in `models.gd` + `traffic.gd`, not a new node per car.
2. A car that must do something special: a `Driver` from traffic's API (`add_node_driver`,
   `race_to`, `park`), so it still keeps gaps and stops at lights.
3. A new group of people: rent slots from `pedestrians.gd` or draw in the person mesh; no new
   material, no sun shadow.
4. Timing: run decisions at 5-10 Hz or on a timer, not every frame. Report the script time from
   `--bench` before and after.
5. Words: `data/dialogue.json` group and `bubbles.say_*` with the right chatter class.
6. Add a check in `game/tools/check_*.gd` (the existing ones: `check_police`, `check_crowds`,
   `check_city_life`, `check_buses`, `check_trains`, `check_crash_scenes`, `check_race_bench`,
   `check_race_planner`, `check_race_line`).
