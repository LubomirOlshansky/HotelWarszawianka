# City AI: cars, police, trams, trains and people

How the city moves by itself. Everything here is built to be cheap: cars ride on the lane graph
instead of physics, people are instances in one MultiMesh, and decisions run a few times a second.

## 1. The layers

```
lane_graph.gd   the road network baked from OSM: directed edges, lanes, junction curves, lights
     │
traffic.gd      every AI car: one Driver per car on the graph, drawn as one MultiMesh per kind
     ├─ rivals.gd        named racers: wander as traffic, race with race_to / stop_racing
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
  `add_ghost`, `remove`, `teleport`, `race_to(d, finish, dist)`, `stop_racing`, `turn_next`,
  `remaining`, `add_police`, `park` / `unpark`, `add_parked_car`, `lane_free`, `set_lights`,
  `add_bus`, `send_to_stop`, `let_go`.
- **Routes** come from the lane graph: `distances_to(node)` once per target gives the cost from
  every node, then every car just takes the cheapest next edge. `snap(p, reach, heading,
  ground_only=...)` puts a point on a lane; pass `ground_only` for anything on the street level
  (tunnels and decks share x/z with the street).

## 3. Racers (`rivals.gd`, design in docs/design/race-ai.md)

Rivals are traffic Drivers with a personality. A race sets `race_to` with the distances to the
finish; the rival takes the shortest way and chances some red lights with its own dice. The race
AI rebuild (PR #630, #635, step 3 open) adds four layers: RaceNav (where a car can go, with race
links), RacePlanner (seconds to the finish per racer), RacePath (racing line and speed per metre),
RaceDriver (overtakes, collisions, recovery), plus RacerProfile and RaceSession. **No rubber band**:
difficulty comes from each rival's skill, not from the player's speed. A new race mode should use
RaceSession once it exists instead of its own ranking.

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
   `check_city_life`, `check_buses`, `check_trains`, `check_crash_scenes`, `check_race_bench`).
