extends Node3D
## AI traffic on the lane graph: cars, taxis, vans and city buses drawn with one
## MultiMesh per kind, plus the rivals' cars (their own nodes) and an invisible
## "ghost" driver the autopilot uses. Cars follow their lane at the road's speed,
## pick a random way on at junctions, keep their distance (a simple intelligent
## driver model), stop for red lights and for the player's car.
##
## Cars only exist in a band around the view: they appear and vanish where the
## camera can't see them, so the count stays near a target set by how much road
## is in view. Near the player a small pool of kinematic bodies gives the closest
## cars collision; a car the player hits stops for a moment.
##
## The driving-feel loop (2026-10-30): a car the player hits is shoved, not stopped dead in
## front of it (`_shove`): rear-ended it rolls on with part of the player's speed, hit from the
## side it slides off its line, and while dazed it coasts to a stop and stays where it was
## pushed, then drifts back into its lane.
##
## Loop 2c (car models): each kind's MultiMesh draws a family of shapes (models.gd TRAFFIC and
## traffic_mesh(): cars are hatches, saloons, estates and SUVs; taxis the city taxi and
## Podwózka, the app taxi; vans panel and box vans), the shape picked per car and written in
## the instance's custom alpha, with its own size and paints. Each MultiMesh draws only up to
## its highest slot in use (visible_instance_count), not its whole pool.
##
## Loop 3g-1 (police, part one; docs/design/police.md sections 2, 4, 9, 12): a fifth kind,
## POLICE (pool 8, its own MultiMesh in the main and shadow passes, no headlight pools: the
## light bar's halos light the road instead, police.gd): the patrol estate and the guards' car
## from models.gd police_mesh(). Patrol cars spawn in the band like the rest (`police_target`:
## 0 / 1 / 2 / 3 by the Traffic level, main and secondary roads only, a pause between one
## leaving and the next); police.gd turns them into chasers, blockers and roadblocks, parks the
## speed traps' cars on the shoulder, and switches their light bars (SIREN, actor.gdshader).
## Traffic gives way to a car with its lights on.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const LaneGraph := preload("res://scripts/lane_graph.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RaceLine := preload("res://scripts/race_line.gd")
const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

enum Kind { CAR, TAXI, VAN, BUS, POLICE, NODE }
## Loop 3g-1: POLICE's pool is 8 (patrols, the traps' cars, the blocker and the roadblock).
const POOL := [112, 16, 16, 8, 8]
## The kinds the band fills by its density (POLICE is spawned by its own count) and that throw
## headlight pools at night.
const TRAFFIC_KINDS := 4
## Each kind's longest shape (m), for the headlight pools. The shapes, their sizes and paints
## are models.gd TRAFFIC (loop 2c; red stays the player's, orange the jobs': the look loop).
const LENGTH := [4.65, 4.6, 5.4, 18.0, 4.7]
## Cars per lane-metre in view, by road class (main, tertiary, residential, living street).
const DENSITY := [1.0 / 20.0, 1.0 / 34.0, 1.0 / 90.0, 1.0 / 180.0]
const MAX_CARS := 140
## Spawn band beyond the view edge, in metres, and the spacing of spawn slots in it.
const MARGIN := 45.0
const SLOT := 8.0
## The edge roadworks: room kept between a spawned car and a barrier line (m).
const SHUT_ROOM := 10.0
## Intelligent driver model: comfortable acceleration and braking, time gap, standstill gap.
const ACCEL := 2.2
const DECEL := 3.5
const HEADWAY := 1.1
const MIN_GAP := 2.2
## The traffic loop (2026-10-30): in a junction a car looks for the others' bodies and the next
## PATH_LOOK s of their way in its corridor (half widths + PATH_MARGIN m) up to PATH_AHEAD m
## ahead; a car within PATH_EXIT m of the start of the lane it came out on is still in the box.
const PATH_LOOK := 0.8
const PATH_MARGIN := 0.2
const PATH_AHEAD := 14.0
const PATH_EXIT := 6.0
## The traffic loop: a car gives way to a tram's body (TRAM_CAR m cars, TRAM_HALF m half width,
## as trams.gd) and the front car's next TRAM_LOOK s, with TRAM_MARGIN m to spare (it looked at
## three points of each tram car, missed the body between them, and stopped by its centre, so a
## car crossing at a slant stopped with its corner in the tram's way).
const TRAM_CAR := 10.5
const TRAM_HALF := 1.2
const TRAM_MARGIN := 0.8
const TRAM_LOOK := 1.5
## Kinematic bodies for the cars nearest the player.
const BODIES := 12
const BODY_RANGE := 40.0
## The driving-feel loop: a hit car takes SHOVE_ALONG of the player's speed beyond its own along
## its lane and slides sideways at SHOVE_SIDE of the player's speed across it (at most
## SHOVE_SLIDE m/s, slowing at SLIDE_DECEL m/s², at most SHOVE_ACROSS m off its line), and is
## dazed for DAZE s (DAZE_POLICE for a police car): no gas, braking at DAZE_DECEL m/s² (it was a
## dead stop at once), not steering back to its lane.
const SHOVE_ALONG := 0.4
const SHOVE_SIDE := 0.4
## ... and, rammed from behind, swerves away from the player at SHOVE_SWERVE of the closing speed.
const SHOVE_SWERVE := 0.35
const SHOVE_SLIDE := 4.0
const SLIDE_DECEL := 6.0
const SHOVE_ACROSS := 2.0
const DAZE := 2.5
const DAZE_POLICE := 1.5
const DAZE_DECEL := 4.0
## The traffic loop (2026-10-30): a brush is not a crash. A hit at BRUSH_HIT m/s closing speed or
## less (the car's own bump threshold is 2) dazes the car for DAZE_BRUSH s; a hit at FULL_HIT m/s
## or more for the whole DAZE (it stopped dead for 2.5 s whatever the knock).
const DAZE_BRUSH := 0.4
const BRUSH_HIT := 3.0
const FULL_HIT := 8.0
## Loop 3g-1: a car giving way to a police car with its lights on slows to this (m/s), and a
## chaser crosses a red (or a roundabout) no faster than SIREN_SLOW (30 km/h).
const YIELD_SPEED := 5.0
const SIREN_SLOW := 8.3
## Cars this far ahead of a police car with its lights on (same way) give way, for this long.
const YIELD_REACH := 30.0
const YIELD_TIME := 3.0
## The crash scenes: a car stopped within PARKED_LOOK m behind a parked car in its lane changes
## lane after PARKED_WAIT s (the queue drives round the scene, one by one).
const PARKED_LOOK := 12.0
const PARKED_WAIT := 1.6
## City-life satire #1 (loud_cars.gd, docs/design/city-life-satire.md 1): a few of the cars the
## band spawns on main and secondary roads are loud supercars instead, at most `loud_target` at
## once (main.gd --loud=N; 0: none), drawn in the taxis' MultiMesh (no draw call of their own).
## Their own seeded generator, so the rest of the traffic's sequence is the same as before.
const LOUD_CHANCE := 0.12
const LOUD_SPEED := Vector2(1.12, 1.25)
const LOUD_ACCEL := 1.7
## Crazy drivers (F 2026-11-05, docs/design/crazy-drivers.md): a few of the taxis and vans the band
## spawns drive in racer mode with no route (racing_mode): the Szkoda Oktawia taxis (crazy 1, the
## taxi shapes), the Szprynter couriers (2, the panel van) and one Pasatini 1.9 TDJ at most (3,
## the taxis' fourth shape, models.gd TAXI_PASAT, from a car's spawn), at most `crazy_target` at
## once (main.gd --crazy=N; 0: none). Indexed by `crazy` (0 unused): top speed (m/s, also capped
## by RACE_CLASS_TOP), at most this times the road's limit, pull (m/s²), corner grip (m/s²), the
## chance of a block / tight cut-in per roll (race_block, BLOCK_*), of running a fresh red, and of
## running wide out of a corner near the player (race_mistake). Their own seeded generator, so the
## rest of the traffic's sequence is the same as before.
const CRAZY_CHANCE := 0.35
const CRAZY_PASAT_SHARE := 0.3
const CRAZY_TOP := [0.0, 20.0, 18.0, 25.0]
const CRAZY_OVER := [1.0, 1.35, 1.3, 1.6]
const CRAZY_ACCEL := [0.0, 3.2, 3.0, 4.0]
const CRAZY_LAT := [7.0, 6.0, 5.0, 7.0]
const CRAZY_BLOCK := [0.0, 0.5, 0.5, 0.75]
const CRAZY_RED := [0.0, 0.1, 0.2, 0.35]
const CRAZY_MISTAKE := [0.0, 0.0, 0.0, 0.15]
## The Pasatini's Janusz paints (black, graphite, bottle green, dark slate, silver-grey: never the
## player's red and orange or the police's blue).
const PASAT_PAINT := ["#1d1e21", "#3a3d42", "#2f3d33", "#2a3340", "#8c9096"]
## Racer mode (docs/design/street-races.md R1, 2026-11-04): a driver with a race route and a
## `race_top` (rivals.gd) or a `race_accel` (police chasers) drives like a racer, not like a town
## car: its car's top speed `race_top`, capped by road class (RACE_CLASS_TOP: e_class 0 main,
## 1 tertiary, 2 residential, 3 living street): the road's racing speed, of which it holds its
## skill's share `race_share` × its effort `race_effort` on a straight (docs/design/race-ai.md 6:
## never a function of the player's speed), pulling `race_accel` m/s², braking for a corner at
## `race_brake` m/s² (0: RACE_DECEL × 0.7), corners at `race_lat` m/s² sideways (v = sqrt(lat ×
## radius) of the junction curve, at least RACE_TURN_MIN; a racer with a plan by its racing line
## instead, LINE_* below), a shorter headway, through every red
## (a little slower in the box, RACE_RED_SLOW of its speed within RACE_RED_LOOK m of the line),
## the cars that cross its way at a junction by where they will be (`_race_cross`), and round
## slower traffic and the player's car: a free lane, or out over the centre line for a pass
## planned from both cars' speeds (`_pass_start`, PASS_* below).
## (F 2026-11-05, "they go very slowly": 30/25/19/12 held them to 68 km/h on the centre's side
## streets, where the player does 90.)
const RACE_CLASS_TOP := [33.0, 29.0, 25.0, 16.0]
## Racer mode: once a second while a racer stands still, what holds it (main.gd --race-debug).
var race_debug := false
const RACE_DECEL := 8.0
const RACE_HEADWAY := 0.6
const RACE_TURN_MIN := RaceLine.SPEED_LEAST
## A racer's car turns no tighter than this (m: a small car's turning circle is about 10 m
## across). The lane graph's curve for a tight turn is shorter than the arc a car drives: where
## two carriageways meet at the tip of a median it is 2 m long for a turn of 165°, and a rail car
## was round it in a third of a second, which made a U-turn there the quickest way to anywhere
## (the race bench: every rival's plan began with one). A racer drives such a curve as the arc
## (`race_turn_length`), at that arc's speed and for that arc's time: `conn_pace` holds the car
## back along the short curve meanwhile. (On a racing line too: race_line.gd keeps a U-turn and
## a hairpin as the lane graph has them, with the same arc's metres and speed.)
const RACE_TURN_RADIUS := RaceLine.TURN_RADIUS
## ... and a turn sharper than this (rad) is a U-turn whatever road it ends on (round the tip of
## a median, onto the other carriageway): driven at UTURN_SPEED like the U-turn onto its own
## road's other side, with no corner speed to overcook.
const RACE_HAIRPIN := RaceLine.HAIRPIN
const UTURN_SPEED := RaceLine.UTURN_SPEED
const RACE_RED_SLOW := 0.75
const RACE_RED_LOOK := 30.0
const RACE_LOOK := 30.0
## Racer mode: a pass over the centre line minds the oncoming lanes whose line lies within this
## many metres of the line it drives itself (a car's width and a margin): the lane it is driven
## in. On a street with two lanes each way the far oncoming lane is a lane's width clear of the
## pass; counted too, it kept Pani Halina 15 s behind a row of cars on Książęca while the lane
## she would have used was empty (race bench, step 4a: with honest corners she came to that
## street in another gap of the town's cars).
const RACE_PASS_BESIDE := 2.5
## Racer mode: ... and an oncoming car in such a lane must be further off than the two cars
## close in the time the pass takes and this long (s) to come back into its lane.
## A fixed 70 m alone are 2.3 s away when a racer at 70 km/h meets a town car at 40, and a
## pass takes up to 4 s: it ended inside the oncoming car (race bench, step 4a).
const RACE_PASS_BACK := 0.7
## Racer mode: a racer that has moved to another lane stays in it this long (s) before it looks
## for a lane or a pass again (the friend's "brief commitment to an overtaking side", F
## 2026-11-09). The player's car is in no lane's list, so behind it the lane just left always
## looked free: a racer changed lane and back every frame, never moved over, and followed a slow
## player down a two-lane road for 35 s (race bench, the first race from Leszczyńska).
const RACE_LANE_HOLD := 2.0
## The town's traffic in a racer's way (docs/design/race-ai.md 5, step 3 of the racer AI rebuild;
## the friend's "route score = driving time + traffic delay + risk penalty"): the seconds a
## racer expects to lose on a street (`race_delay`). It drives a share of the street behind
## someone, at RACE_STUCK_SPEED m/s instead of its own speed: RACE_STUCK[0] of a one-lane one-way
## street (no way past), [1] of a one-lane street with an oncoming road to pass on, [2] of a
## street with several lanes; and it loses RACE_STUCK_END s at the street's end and
## RACE_STUCK_LIGHTS s at each of its lights. All at `density` 1 (Busy), in proportion below it.
## Fitted by least squares on 252 bench races (tools/race_traffic.sh: three rivals over ten
## courses at Low, Normal and Busy, each street's seconds against the same street on clear
## roads). The numbers are the driver's: fitted again for step 4b's, which stands in a queue
## where step 4a's drove through it (the light's share was 1.5 s and the street's end 0.25 s,
## the oncoming road's 0.24; the old numbers gave this driver's races 16.5 % too short). They
## give a race's time in traffic to 15 %, of which 11 to 12 % is the town's draw of cars.
## (The fit's shares for the oncoming road and for several lanes are 0.47 and 0.43, the same
## within its noise; kept in the order the planner's check holds: lanes cost more.)
const RACE_STUCK := [0.77, 0.44, 0.46]
const RACE_STUCK_SPEED := 10.0
const RACE_STUCK_END := 0.7
const RACE_STUCK_LIGHTS := 7.4
## Out of the band of town cars round the view (MARGIN, and AWAY_ROOM m beyond it) a racer had
## empty streets: in Busy traffic a rival that left the player at the line came home up to 38 %
## sooner than alone among the town's cars (the race bench: Halina in 107 s against 131 s,
## Zbyszek in 83 s against 135 s). Out there it owes each street's expected delay instead
## (`away_debt`, s) and pays by covering less ground a second: `away_pace` of its speed,
## 1 / (1 + debt / AWAY_TAU), moved AWAY_EASE a second at most so its speed over the ground has
## no steps. Back among real cars the debt is dropped.
const AWAY_ROOM := 15.0
const AWAY_TAU := 3.0
const AWAY_EASE := 0.3
## Turning back (docs/design/race-ai.md 5, step 3 of the racer AI rebuild: "nobody reacts to a
## blocked road"; before, a racer stood 1.5 s at a wall and drove through it). A racer with
## a plan (race_planner.gd) that finds its street blocked tells the plan, which shuts the street
## to it for the race and finds another way, and turns round. Blocked is: a wall, a parked car
## within WALL_SPAN m along every lane of the road and of the oncoming road, seen from WALL_SEE
## m; or the player's car standing in its way for BOX_WAIT s with no lane to pass in. It stops
## BACK_GAP m short (backing up to make that room when it is nearer) and makes a U-turn in the
## street at BACK_TURN m/s; on a one-way street it backs to the junction behind and out onto the
## road it came by, at BACK_SPEED m/s at most (the player's car's own reverse, car.gd
## `reverse_speed`), keeping BACK_CLEAR m from a car behind it. Boxed in behind as well for
## BACK_GIVE_UP s it does what a racer without a plan does (RACE_KNOT_LAST). A street it has turned
## back in already it drives on through (a wall: the knot rule), or, boxed by the player's car
## again, turns back in BACK_TRIES times at most a race. `back` says where it is in this:
## stopping for the block, backing up for room (and waiting for the oncoming lane), backing out
## to the junction, backwards through the junction's curve, or in the U-turn. Its plan searches
## for the new way meanwhile, PLAN_SLICE states a frame (0.6 ms on a desktop, 1.5 ms at worst;
## the whole search in one frame is 12 to 55 ms by the length of the race).
const WALL_SEE := 40.0
const WALL_SPAN := 8.0
const BOX_WAIT := 3.0
## ... but not when the player's car only waits itself (step 4b; a rival made a U-turn behind a
## player who stood 4 s in the traffic on Książęca, 171 m before the finish, and came home 3 km
## and four minutes later): with a car within QUEUE_GAP m in front of the player's car along
## the racer's way, or a red or amber light there, the racer waits behind it as in any queue.
## And on a street with an oncoming road it waits BOX_WAIT_PASS s before it turns back: a gap
## to pass in comes sooner than the way round.
const QUEUE_GAP := 12.0
const BOX_WAIT_PASS := 8.0
## ... and where there is no way back either (a one-way street with cars behind it, a street
## its plan has no other way from), it goes round the player's car at walking pace
## (SHOULDER_SPEED m/s forward, SHOULDER_SIDE m/s sideways even as it stands), over the kerb if it
## must, SIDE_CLEAR m from the car's side, and back to its lane once past it; given up after
## SHOULDER_MOST s or when the player's car moves off. The last resort: the first race did not
## finish behind a player who parked on Tamka (race bench, Finishes).
const PLAYER_IN := 1.0
const SHOULDER_SPEED := 3.0
const SHOULDER_SIDE := 0.8
const SHOULDER_MOST := 20.0
const BACK_GAP := 5.0
const BACK_TURN := 3.5
const BACK_SPEED := 7.0
const BACK_CLEAR := 3.0
const BACK_GIVE_UP := 6.0
const BACK_TRIES := 3
const PLAN_SLICE := 150
## Two drivers with plans in one street: the one behind a car that backs out towards it, within
## BACK_FOLLOW m, takes the street for blocked too and backs out first; one about to turn into a
## street a car is backing out of (seen from BACK_SEE m before the junction) shuts that street in
## its plan and takes another way.
const BACK_FOLLOW := 25.0
const BACK_SEE := 40.0
## A car backing up looks this far behind its tail for a car in any lane (m).
const BACK_NEAR := 12.0
## Out of the street first, with another car still to come out after it (one backing out of that
## street, or the player's car slow within YIELD_SEE m in front of its nose): it backs YIELD_ROOM m
## on along the road it came out on and holds there, YIELD_WAIT s at most, so the other can come
## out and go first (two cars that back out of one street through one mouth stood nose to tail
## for good: the first wanted on through the mouth, the second out through it).
const YIELD_ROOM := 12.0
const YIELD_SEE := 22.0
const YIELD_WAIT := 8.0
const BACK_NONE := 0
const BACK_STOP := 1
const BACK_ROOM := 2
const BACK_OUT := 3
const BACK_CURVE := 4
const BACK_UTURN := 5
const BACK_YIELD := 6
## Human rivals (F 2026-11-05: "never the skróty, never cut me off", docs/design/street-races.md
## section 9). Shortcuts (race_cuts.gd): a racer takes a cut it knows from the junction ahead when
## the cut and the road on from its far end beat the road route by RaceCuts.GAIN m, at most
## CUT_TOP m/s across the plaza (slower when it turns sharply in).
const CUT_TOP := RaceLine.CUT_TOP
## Mistakes: a racer that rolls its `race_mistake` at a corner takes it MISTAKE_FAST too fast and
## runs wide out of it: a slide of MISTAKE_SLIDE m/s outwards and MISTAKE_DAZE s of lifting off.
## A rival in a race rolls its own dice (`race_rng`) at every corner, seen or not: its mistakes
## are part of its skill and its time is its own. A driver without them (a crazy driver) rolls
## only within MISTAKE_NEAR m of the player, so it is seen.
const MISTAKE_NEAR := 110.0
const MISTAKE_FAST := 1.3
const MISTAKE_SLIDE := 4.5
const MISTAKE_DAZE := 0.8
## Wrong turns (Słoik's satnav): at a junction with a choice, more than WRONG_FAR m from the
## finish, a WRONG_CHANCE roll takes the second-best way (the route's distances bring him back).
## A racer with a plan (race_planner.gd) rolls only where a road out costs it real seconds
## (Plan.WRONG_LEAST to WRONG_MOST), and takes that one: its plan brings it back from anywhere.
## Such junctions are few (four or five in a race across the centre), so its roll is WRONG_SURE:
## about one race in sixteen goes by without the wrong turn.
const WRONG_FAR := 300.0
const WRONG_CHANCE := 0.2
const WRONG_SURE := 0.5
## Step 6a: the wrong turn is a moment the player sees (BACKLOG, "Słoik's wrong turn"): on the
## street he should not have taken he lifts off for WRONG_DAZE s (the satnav thinks again) with
## his hazard lights on for WRONG_SHOW s (race_signals.gd).
const WRONG_DAZE := 0.9
const WRONG_SHOW := 2.4
## Step 6a, what a racer's headlight flash is read from (`held_up`): the seconds it has been
## within HELD_GAP m of a car going HELD_SLOWER m/s or more under the speed it wants, not in a
## pass. (A look only: it changes nothing in how it drives.)
const HELD_GAP := 14.0
const HELD_SLOWER := 3.0
## Blocking (Game AI Pro's "one lateral move"): a racer with the player BLOCK_BACK m or less behind
## it, catching up, rolls its `race_block` once in BLOCK_EVERY s; on a hit it moves across onto the
## player's line, once, and holds it for BLOCK_HOLD s (the player can still go round the other side).
const BLOCK_BACK := 22.0
const BLOCK_EVERY := 2.5
const BLOCK_HOLD := 2.2
## Cutting in: a racer passing the player with `race_block` from BLOCK_TIGHT pulls back in this many
## metres sooner (in front of the player's bumper, not a polite car's length ahead).
const BLOCK_TIGHT := 0.5
## The racing line (race_line.gd; docs/design/race-ai.md 5.2, step 4a of the racer AI rebuild). A
## racer with a plan drives its way as one line with a speed for every metre of it, where the
## town's cars (and the racers without a plan, until step 6b) keep to the lane's line, the
## junction's curve and one speed a junction: no stretch of the line asks for more sideways pull
## than the racer's grip, and it brakes for each bend in time. For that it knows its streets
## LINE_AHEAD m ahead at least (`way`: its plan's choices beyond the junction ahead, held as it
## comes to them; LINE_MORE m more are decided each time, WAY_MOST streets at most), and of the
## stretches of line built LINE_KEPT are kept at most.
## Its place moves over to a new line (a lane changed, its plan changed its mind) over LINE_BLEND
## m, driving the old line less and the new one more with every metre, so its heading has no
## step; where it cannot (in a junction's curve, the line dropped to turn round) the difference
## eases out by LINE_EASE m a metre driven.
## Beside its line (a pass, a lane change under way: `line_dyn`) it drives the line's own shape
## that far over: inside a bend its metres are fewer than the line's and its speed lower for the
## tighter turn (never taken as less than LINE_INSIDE of the line's metres), outside it they are
## more. It leaves its lane (a lane change, a pass over the centre line) only where the line
## pulls it sideways with less than LINE_BUSY of its grip: not into a bend, in it or out of it,
## where the two would add up to more than the car holds.
## Its effort (rivals.gd `effort_of`: behind, it pushes) works on the grip it takes a corner
## with, between GRIP_EFFORT_LEAST and GRIP_EFFORT_MOST of its own (`race_corner`: the effort
## itself, not cut to the road's racing speed as on a straight).
## At a corner it misjudges (MISTAKE_FAST) it is too fast from LINE_FAST m before the junction's
## curve to LINE_FAST m past it, though never faster than a car of RACE_GRIP_MOST m/s² holds the
## bend (the player's own car's grip: the race bench's honest car).
const LINE_AHEAD := 100.0
const LINE_MORE := 40.0
const WAY_MOST := 12
const LINE_KEPT := 400
const LINE_EASE := 0.12
const LINE_BLEND := 12.0
const LINE_INSIDE := 0.4
const LINE_BUSY := 0.5
const GRIP_EFFORT_LEAST := 0.85
const GRIP_EFFORT_MOST := 1.15
const LINE_FAST := 15.0
const RACE_GRIP_MOST := 19.0
## Overtake, contact, recover (docs/design/race-ai.md 8, step 4b of the racer AI rebuild). Until
## now a racer that passed over the centre line or slipped out of a knot stopped seeing cars
## (`squeeze`) for a time worked out when it set off, and slid sideways at 4 m/s from one frame
## to the next: the race bench counted 473 cars driven through in 196 races in traffic, 382 dead
## stops and a sideways pull of 23.6 m/s² in the worst sideways move.
## Now a racer on a street sees the cars by where they are (`_race_gap`): a car is in its way when
## the two bodies overlap across the road (BESIDE_GAP m to spare), whatever lane either is in, and
## the oncoming cars count as soon as its own side is over the centre line. So out for a pass it
## no longer sees the cars of its own lane, and does see the one that comes at it.
## It moves sideways as a car does (`_side_step`): its sideways speed builds up and falls off at
## SIDE_ACCEL m/s² (the pull the move asks of the car, on top of the line's), SIDE_SPEED m/s at
## most and never more than SIDE_SLOPE of its speed forward (a standing car does not move
## sideways), and never into a car that is alongside (`_side_room`: SIDE_CLEAR m kept).
## Behind a car it means to go round it stands RACE_GAP m short (room to steer out), and closes up
## to RACE_GAP_OUT m while it steers out.
const SIDE_ACCEL := 5.0
const SIDE_SPEED := 4.0
const SIDE_SLOPE := 0.4
const SIDE_CLEAR := 0.45
const BESIDE_GAP := 0.2
## (A car alongside whose side is within SIDE_RUB m of its own is beside it, not in front: it
## moves away from it sideways as it drives on.)
const SIDE_RUB := 0.3
const RACE_GAP := 4.0
const RACE_GAP_OUT := 0.8
## The pass over the centre line (`_pass_start`, `_pass_drive`). Before it goes out it works out
## how long the pass takes and how far it goes (`_pass_plan`): from its own speed and pull, the
## speed of the cars ahead, and the whole row of them up to the first gap it can come back into
## (PASS_SLOT m and half the speed it has over the car beyond); PASS_MOST s at most, ending
## PASS_END m before the junction, with no bend of its line in it that takes more than LINE_BUSY
## of its grip. The oncoming lane it drives in must be clear for that far, for as far as an
## oncoming car comes meanwhile, and PASS_MARGIN m. It comes back PASS_IN m in front of the car
## it passed (PASS_IN_TIGHT cutting in on the player, BLOCK_TIGHT).
## Every frame of the pass it looks again: with room in its own lane before the next car it comes
## back; with the next car close it holds its side and goes on, if the plan from here still
## holds (PASS_KEEP m of margin: a pass is not given up for a metre); if not, it gives the pass
## up: behind the car it is beside it falls back (PASS_FALL m/s slower than that car) and comes
## in behind it; with its tail past that car's middle it finishes past that one car. After a pass
## given up it waits PASS_WAIT s before it tries again.
## A standing queue up to a junction it passes to the junction itself (the junction's curve
## brings it back to its lane), when it runs the lights, does not turn right there across the
## queue's front, and the oncoming road is clear all the way.
## The town's cars see a racer that is out of its lane by where it is (`_racers_out`, within
## OUT_SEE m in front of them): the oncoming car brakes for it too.
## No car is put down (`_try_spawn`) on a racer's own street within SPAWN_CLEAR m in front of it
## and its braking distance (at SPAWN_BRAKE m/s²), nor, while it is out of its lane, on the
## oncoming road within the metres the two close in SPAWN_PASS_T s (a car is put down at about
## SPAWN_V m/s): what a racer meets it must have been able to see coming.
const SPAWN_CLEAR := 25.0
## Racer AI step 5b (docs/design/race-ai.md 5.5): a wrong-way hop, one block of a small one-way
## street driven against its way (a race link of kind "wrong", race_cuts.gd `hop`), by a rival
## that dares (ladder.gd `hops`). The racer looks first and takes it only when the street is
## empty (`_hop_clear`): it decides HOP_DECIDE m before the place it could still stop from, so
## whichever way it goes on it has the room to brake for. No car on the street or on a curve into
## it, none standing by its kerb, nobody else hopping it, the player's car not in the way, and
## every car that means to turn into it far enough from its stop line to wait there (its braking
## distance and HOP_STOP m). From then until the racer is off the street the street is held
## (`_hop_held`): a car that would turn into it waits at its stop line as at a red light, and
## none is put down on it. A street not empty is refused for the race (RacePlanner.Plan
## `refuse`: its plan is searched again without the hop) and the racer takes its best other way.
const HOP_DECIDE := 12.0
const HOP_STOP := 6.0
const SPAWN_BRAKE := 8.0
const SPAWN_PASS_T := 4.0
const SPAWN_V := 9.0
const PASS_SLOT := 10.0
const PASS_MOST := 7.0
const PASS_END := 6.0
const PASS_MARGIN := 10.0
const PASS_KEEP := 4.0
const PASS_IN := 2.0
const PASS_IN_TIGHT := 0.6
const PASS_FALL := 3.0
const PASS_WAIT := 1.5
const PASS_STEP := 0.2
const PASS_QUEUE := 6.0
const PASS_LEAST := 4.0
const OUT_SEE := 35.0
const OUT_OFF := 0.7
const OUT_BESIDE := 0.5
const OUT_NEAR := 22.0
const OUT_WAY := 6
## ... and a racer whose own side is over the centre line brakes for an oncoming car it would
## meet within OUT_MEET s (further off, its pass's plan answers for it). The player's car, to a
## racer that moves over beside it or passes it: PLAYER_LONG by PLAYER_WIDE m.
const OUT_MEET := 1.2
const PLAYER_LONG := 4.5
const PLAYER_WIDE := 1.9
## ... and the knot rule is the last resort only: a racer stands in a queue like any car, and
## slips through the car ahead only after RACE_KNOT_LAST s without moving (a ring of cars that
## wait for each other; the town's own cars give up on one after 8 s).
const RACE_KNOT_LAST := 30.0
## Cars across a junction (`_race_cross`). A racer took a crossing car for a car in its way only
## within 7 m, and after 1.5 s of waiting for one no longer: at speed that was a dead
## stop or a drive through (the race bench: most of the 382 dead stops). Now, coming to a
## junction, in it and just out of it, it looks along its own way (`_way_at`: its line, or its
## lane and the junction's curve) CROSS_SEE m and CROSS_TIME s of its speed ahead, CROSS_FAR m at
## most, a place every CROSS_STEP m, and along the way of each car round that junction that is
## not a car of its own lanes: a place both come to within CROSS_SLACK s of each other (and the
## time the two bodies take to clear it) is taken; it brakes to stop CROSS_KEEP m before it, with
## its own brakes, and goes when the other is through or would come later. A car that stands in
## its way it waits for RACE_CROSS_WAIT s (then the knot rule).
const CROSS_SEE := 10.0
const CROSS_TIME := 2.0
const CROSS_FAR := 40.0
const CROSS_STEP := 2.5
const CROSS_SLACK := 0.6
const CROSS_KEEP := 2.5
const RACE_CROSS_WAIT := 6.0
## ... and a car that stands with only its side in the racer's way (a queue at the mouth of the
## next street, where two lanes lie closer than two cars are wide: its middle SWERVE_LEAST m or
## more beside the racer's way) the racer steers round: up to SWERVE_MOST m aside, within its
## road (SWERVE_OVER m over the edge of the outer lanes at most) and not into a car alongside,
## held SWERVE_HOLD s after the last such car. Where that is not enough the car is in its way.
const SWERVE_CURVE := 1.5
const SWERVE_OVER := 0.4
const SWERVE_HOLD := 1.0
## Pole lamps: red, amber, green.
const LAMP_ON := [Color("#ff3b2f"), Color("#ffb21e"), Color("#43ff6e")]
const LAMP_OFF := Color("#2a2c2e")
## Their halos at night (linear colour, alpha = brightness).
const HALO := [Color(1.0, 0.08, 0.04, 0.9), Color(1.0, 0.45, 0.02, 0.85), Color(0.1, 1.0, 0.3, 0.8)]


class Driver:
	var active := false
	var kind := 0
	var slot := -1
	## Rivals: their own car model, never despawned.
	var node: Node3D
	var persistent := false
	## The autopilot: not drawn, not in any lane (others see the player's car
	## instead), ignores lights and crossing cars but follows the car ahead.
	var ghost := false
	var length := 4.2
	var size := Vector3(1.8, 1.5, 4.2)
	var paint := Color.WHITE
	## Loop 2c: which of its kind's shapes it is (models.gd TRAFFIC; the instance's custom alpha).
	var shape := 0
	var edge := -1
	var lane := 0
	var s := 0.0
	var seg := 0
	var off := 0.0
	var off_target := 0.0
	var next_edge := -1
	var next_lane := 0
	var next_reg := -1
	var reg := -1
	## Position in the registered lane; negative of the lane start on the way in.
	var ls := 0.0
	var in_conn := false
	var cu := 0.0
	var conn := PackedVector2Array()
	var conn_len := 1.0
	## Racer mode: the share of its speed it moves along the curve at (1: all; less on a curve
	## tighter than a car turns, RACE_TURN_RADIUS).
	var conn_pace := 1.0
	var conn_y0 := 0.0
	var conn_y1 := 0.0
	var v_turn := 10.0
	var v := 0.0
	var speed_factor := 1.0
	var accel_factor := 1.0
	## Held still for this long (gps_moments.gd's app taxi).
	var stun := 0.0
	## The driving-feel loop: seconds left of the daze after the player hit it (coasting, shoved).
	var daze := 0.0
	## The driving-feel loop: sliding sideways off its line after a hit (m/s, + towards + off).
	var slide := 0.0
	var held := false
	var still := 0.0
	## Seconds stuck behind the player's car.
	var blocked := 0.0
	var squeeze := 0.0
	var pos := Vector3.ZERO
	var yaw := 0.0
	var clip := 1.0
	var visible := false
	## Time not yet driven (cars out of sight update every other frame).
	var pending := 0.0
	## Racing: distances to the finish for every node (empty = wander).
	var route := PackedFloat32Array()
	var finish := -1
	## A racer's plan (race_planner.gd Plan; null: none): the way on at each junction by the
	## seconds to the finish for this racer, where `route` goes by the metres. `plan_edge` is the
	## edge the plan last chose a way on for (it holds that way: Plan.choose's `held`), and
	## `wrong_edge` the edge it took a wrong turn from (kept until the turn is made).
	var plan = null
	var plan_edge := -1
	var wrong_edge := -1
	## ... and where its street enters the finish's circle (the s along it, from the plan's `ends`;
	## INF: nowhere ahead of it): from there on it is home, as at the end of a street into the
	## finish's junction.
	var end_from := INF
	## Turning back at a blocked street (BACK_* above): where it is in it, the s it backs up to
	## for room, its speed backwards (m/s; `v` is 0 meanwhile: to the cars round it a car that
	## backs is a car that stands), the seconds it has waited (boxed by the player's car, or with
	## no room behind), and how often it has turned back this race.
	var back := 0
	var back_to := 0.0
	var back_v := 0.0
	var back_wait := 0.0
	var turns_back := 0
	## ... and the road it comes out on, at whose end it takes the new way (-1: none): the
	## oncoming road after a U-turn, the road into the junction behind after backing out (its lane).
	var back_edge := -1
	var back_lane := 0
	## The edge and lane it came by (-1: unknown), to back out of a one-way street the way it came.
	var prev_edge := -1
	var prev_lane := 0
	## Where on `next_edge` the curve under way ends (< 0: at its start): a U-turn in the street
	## ends across the road, not at a junction.
	var conn_end := -1.0
	var arrived := false
	var run_red := false
	## Racer mode (RACE_CLASS_TOP above): the car's top speed (m/s; 0: none, the road's limit ×
	## speed_factor), acceleration (m/s²; 0: the town car's IDM), corner grip (m/s²), the braking it
	## plans a corner with (m/s²; 0: RACE_DECEL × 0.7), the share of the road's racing speed its
	## skill holds on a straight and its effort on top of that (rivals.gd `effort_of`: 1 its own
	## pace; never past the road's racing speed), its effort in a corner (the same effort without
	## that cut: a racer at the car's top has nothing more on a straight and still pushes through
	## the bends), and a pass over the centre line under way (s left, its offset).
	var race_top := 0.0
	var race_accel := 0.0
	var race_lat := 7.0
	var race_brake := 0.0
	var race_share := 1.0
	var race_effort := 1.0
	var race_corner := 1.0
	var pass_t := 0.0
	var pass_off := 0.0
	## Racer mode: the seconds it still holds the lane it has just moved to (RACE_LANE_HOLD).
	var lane_hold := 0.0
	## Step 4b (SIDE_* and PASS_* above): its sideways speed (m/s, + to the right); in a pass,
	## whether it cuts in, the speed it is held to while it gives the pass up (INF: none), and the
	## seconds before it tries a pass again.
	var off_v := 0.0
	## ... and steering round a car that stands with its side in its way (SWERVE_* above): how far
	## aside it means to be (m, + to the right), how far it is, and the seconds it still holds it.
	var swerve := 0.0
	var swerve_now := 0.0
	var swerve_t := 0.0
	## Step 4b: going round the player's stopped car (SHOULDER_* above): the side (-1 left, 1
	## right; 0 not), and the seconds left for it.
	var shoulder := 0.0
	var shoulder_t := 0.0
	## Step 4b: what `_race_cross` saw at its last look (`look_tick`, the traffic's `_tick`).
	var look_gap := INF
	var look_seen := false
	var look_tick := -2
	var pass_tight := false
	## ... whether it has come up beside a car yet (until then the car in front is the one it
	## set out to pass, however much room there is behind it), and whether it is falling back.
	var pass_by := false
	var pass_back := false
	var pass_cap := INF
	var pass_wait := 0.0
	## Racer mode, out of the town's cars (AWAY_* above): the seconds of expected traffic delay it
	## still owes, and the share of its speed it covers ground at meanwhile.
	var away_debt := 0.0
	var away_pace := 1.0
	## Racer stats for the race log: seconds stopped (under 1 m/s) and the passes made.
	var race_still := 0.0
	var race_passes := 0
	## Human rivals (RACE_* / CUT_* above): the shortcuts it knows ({node: [to, metres, ...]},
	## race_cuts.gd), its chance of a mistake per corner, wrong turns left, its chance of blocking;
	## on a cut now, a mistake under way (+1/-1: the side it runs wide to), a block (s left, its
	## offset, s to the next roll); and the counts for the race log and rivals.gd's lines.
	var cuts := {}
	var race_mistake := 0.0
	var race_wrong := 0
	var race_block := 0.0
	## Racer AI step 6a (docs/design/race-ai.md 6.1): how much clear oncoming road it wants for a
	## pass over the centre line (× PASS_MARGIN and PASS_KEEP: ladder.gd `dare`), and what its
	## lights are read from (race_signals.gd): its pull this frame (m/s², under 0 braking), the
	## seconds it has sat behind a slower car with no way past, and the seconds left of its
	## satnav's moment after a wrong turn (WRONG_SHOW: it lifts off, hazards on).
	var race_dare := 1.0
	var accel_now := 0.0
	var held_up := 0.0
	var wrong_t := 0.0
	## A rival's own dice for its wrong turns and mistakes (rivals.gd `arm_racer`; null: none). The
	## traffic's dice are shared with every car on the road, so a rival that rolled them made its
	## human moments where the player's car happened to shift the sequence: on the race bench
	## Słoik took no wrong turn alone and one with a player, 34 % slower.
	var race_rng: RandomNumberGenerator
	var on_cut := false
	var mistake_side := 0.0
	var block_t := 0.0
	var block_off := 0.0
	var block_wait := 0.0
	var cuts_taken := 0
	## Of those, the race links (yards, car parks, alleys: race_cuts.gd), for the race bench.
	var links_taken := 0
	## Step 5b: a wrong-way hop it has looked down and is taking (the street is held for it until
	## it is on the next one), the hops taken and those refused (the street was not empty).
	var hop_go := false
	var hops_taken := 0
	var hops_refused := 0
	var mistakes := 0
	var wrong_turns := 0
	var blocks := 0
	## The racing line (LINE_* above; null: none, it drives the lanes and the curves). `line_q` is
	## its street's place among the line's streets and `line_i` the point of the line it is at;
	## `line_cuts` the shortcuts' curves among the line's junctions (race_line.gd `path`);
	## `line_dyn` how far beside the line it is (m to the right: a pass, a lane change under way, a
	## slide) and `line_carry` what is left of its step over to a new line (m on the ground);
	## `line_was` the line it drove before this one while it moves over from it (its street's
	## place among that line's and a point of it, like `line_q` and `line_i`), `line_blend` the
	## metres driven since;
	## `line_grip` the grip its speeds were worked out for, `line_fast` whether with a mistake;
	## `line_full`: the line reaches its finish; `line_wait`: s before it asks for more of it again.
	var line: RaceLine.Path
	var line_q := 0
	var line_i := 0
	var line_cuts: Array = []
	var line_dyn := 0.0
	var line_carry := Vector2.ZERO
	var line_was: RaceLine.Path
	var line_was_q := 0
	var line_was_i := 0
	var line_blend := 0.0
	var line_grip := 0.0
	var line_fast := false
	var line_full := false
	var line_wait := 0.0
	## The streets it has decided on beyond `next_edge`, in order; of each, whether the junction
	## into it is a shortcut and whether it is a wrong turn (rolled when it was decided); and
	## `way_rolled`: the way on from its street has had its roll for a wrong turn.
	var way := PackedInt32Array()
	var way_cut := PackedByteArray()
	var way_wrong := PackedByteArray()
	var way_rolled := false
	## The street from whose end a shortcut was last counted (`cuts_taken`: once a street, though
	## its way on is chosen again and again, and a way decided ahead comes as a shortcut already).
	var cut_edge := -1
	## Stay inside the strongly connected core (rivals), so they never leave the map.
	var core_only := false
	## A car crossing our path in a junction box: gap to it and its speed.
	var cross_gap := INF
	var cross_v := 0.0
	## Waiting on crossing cars for long (a knot of cars yielding in a ring) makes
	## a car ignore them for a moment.
	var cross_wait := 0.0
	var cross_ignore := 0.0
	## A tram is in its path (it waits; the tram doesn't wait for it).
	var sees_tram := false
	## Loop 3g-1, police cars: the light bar flashing (SIREN), a roaming patrol (spawned by the
	## band), parked off the lane (a speed trap's car, a blocker, a roadblock: not driven, not
	## in any lane, `off` metres right of the centreline, `park_yaw` its heading), chasing (its
	## own top speed `v_cap`, slows to SIREN_SLOW at reds and runs them, never arrives),
	## `keep_gap` metres it keeps behind the player's car, and `goal`: where it heads at a
	## junction its route doesn't reach (distances_to's max_cost).
	var lights := false
	var patrol := false
	var parked := false
	var park_yaw := 0.0
	var chase := false
	var v_cap := 0.0
	var keep_gap := 2.4
	var goal := Vector2.INF
	## Any car: giving way to a police car with its lights on (seconds left: the kerb lane, slow).
	var yield_t := 0.0
	## The night-buses loop (buses.gd): a bus sent to a stop drives there (its route) and stops
	## with its front at `halt_s` on edge `halt_e` (-1: none), moves `halt_pull` m towards the
	## kerb, stands `halt_wait` s (`halting` while it does; INF: until buses.gd lets it go) and
	## drives on as any bus. `tag` is buses.gd's: what the bus is doing for it ("" = nothing).
	var halt_e := -1
	var halt_s := 0.0
	var halt_pull := 0.0
	var halt_wait := 0.0
	var halting := false
	var tag := ""
	## City-life satire #1 (loud_cars.gd): a loud supercar (kind TAXI, shape TAXI_SUPERCAR): it
	## drives quicker and pulls away harder; loud_cars.gd revs it when it passes the view.
	var loud := false
	## Crazy drivers (CRAZY_* above): 0 a town car, 1 a Szkoda Oktawia taxi, 2 a Szprynter
	## courier, 3 the Pasatini.
	var crazy := 0


signal bumped_driver(d: Driver)
## A racer found its street blocked and turns back (BACK_* above): its plan has shut the street;
## the race's owner gives it the metres left without that street (`reroute`).
signal turned_back(d: Driver)
## Step 5b: a racer found the one-way street of a wrong-way hop not empty and takes another way:
## its plan has dropped the hop (`plan.no_hop`); the race's owner gives it the metres left without
## it (`reroute`).
signal hop_refused(d: Driver)
## A car has been held up behind the player's stopped car for a while (it may shout).
signal blocked_by_player(d: Driver)
## Loop 3g-1: the player's car hit a police car at `speed` m/s (police.gd: a warning or a ram).
signal bumped_police(d: Driver, speed: float)
## Loop 3g-1: a police car came into the band (a patrol) or left it (any police car).
signal police_spawned(d: Driver)
signal police_released(d: Driver)
## The night-buses loop: a bus sent to a stop (send_to_stop) stands there now, pulled in; and
## one let go (its stand over) drives on.
signal bus_halted(d: Driver)
signal bus_left(d: Driver)

var graph: LaneGraph
var map: Node3D
var cam: Camera3D
## Quality (v0.9) × the Traffic setting (loop 2a): scales how many cars fill the view
## (1 = High, Busy). A change applies at once: the view's car count is worked out again.
var density := 1.0:
	set(value):
		density = value
		_target_at = Vector2.INF
## Spawning cars; rivals and the ghost drive even when this is off.
var spawning := true
## Set by the game every frame.
var player_pos := Vector3.ZERO
var player_vel := Vector3.ZERO
var player_on_road := true
## How long the last update took, for --bench.
var last_usec := 0
var visible_count := 0
## Loop 3g-1: roaming patrol cars to keep in the band (police.gd sets it from the Traffic level;
## 0 = none), how far from the player a new one may appear (the chase cooldown: 200 m), and the
## seconds before the next may come (police.gd sets it when one leaves the band).
var police_target := 0
var police_min_dist := 0.0
var patrol_wait := 20.0
## Patrol cars spawned so far (every third is the van).
var _patrol_spawns := 0
## The night-buses loop (vision.md 3.5): the buses show an N route sign (buses.gd sets it from
## the clock, 22:30-05:00). The BUS MultiMesh swaps its mesh for the bus with the sign (the
## same surface, material and instances: +0 draw calls, no shader change).
var night_sign := false:
	set(value):
		if value == night_sign:
			return
		night_sign = value
		if _mm.size() > Kind.BUS:
			if _bus_day == null:
				_bus_day = _mm[Kind.BUS].mesh
			_mm[Kind.BUS].mesh = night_bus_mesh() if value else _bus_day
## The day bus (kept while the night one is on).
var _bus_day: Mesh
static var _bus_night: ArrayMesh
## Police cars with their lights on this frame (traffic ahead gives way to them).
var _sirens: Array[Driver] = []

var _active: Array[Driver] = []
var _free: Array[Driver] = []
var _lane_cars: Array = []
var _mm: Array[MultiMesh] = []
## Headlight pools for each kind, drawn from the same instance buffer (night only).
var _beam_mm: Array[MultiMesh] = []
var _beam_mmi: Array[MultiMeshInstance3D] = []
var _buf: Array[PackedFloat32Array] = []
var _free_slots: Array[PackedInt32Array] = []
var _counts := PackedInt32Array([0, 0, 0, 0, 0])
## Loop 2c: instances each MultiMesh draws (its highest slot in use + 1), and this frame's.
var _drawn := PackedInt32Array([0, 0, 0, 0, 0])
var _top := PackedInt32Array([0, 0, 0, 0, 0])
var _bodies: Array[AnimatableBody3D] = []
var _body_driver: Array = []
var _rng := RandomNumberGenerator.new()
## The racing lines of this map (race_line.gd: the stretches built, shared by every racer).
var _line: RaceLine
## City-life satire #1: the loud supercars out now, the most at once, their generator.
var loud_count := 0
var loud_target := 3
var _loud_rng := RandomNumberGenerator.new()
## Crazy drivers: out now, the most at once, the Pasatinis out (one at most), their generator.
var crazy_count := 0
var crazy_target := 3
var pasat_count := 0
var _crazy_rng := RandomNumberGenerator.new()
## Loop 2c: picks the shapes, apart from _rng so where and what kind of car spawns is as before.
var _looks := RandomNumberGenerator.new()
var _tick := 0
## Cars in or near a junction box this frame (see _junction_conflicts); the
## trams read it too.
var junction_cars: Array[Driver] = []
## Testing aid (--traffic-overlaps): count the frames where two traffic cars' boxes overlap, and
## print a summary when the game quits. Frames counted, car-pair frames overlapping (in a
## junction curve / on lanes), the worst spot.
var count_overlaps := false
var _ov_frames := 0
var _ov_pairs := 0
var _ov_in_junction := 0
var _ov_spots := {}
## ... and how often a car gave up waiting on crossing cars (a knot: 8 s, then it ignores them).
var _ov_knots := 0
## Testing aid: tram car and traffic car pairs overlapping, frames (and how many with the car on
## a junction curve or about to enter one, and how many with the tram moving).
var _ov_tram := 0
var _ov_tram_moving := 0
var _ov_tram_spots := {}
var _ov_tram_still := 0
## The trams (trams.gd), set by the game: cars give way to them.
var trams: Node3D
var _tram_at := PackedVector2Array()
var _tram_axis := PackedVector2Array()
## The traffic loop (2026-10-30): how far ahead of each gathered tram car (m) it is looked for:
## the front car's next TRAM_LOOK s at its speed, 0 for the others.
var _tram_ahead := PackedFloat32Array()
## The traffic loop: whether each gathered tram car is the front one (a car already in front of a
## tram's nose drives on and clears it; the tram waits).
var _tram_front := PackedByteArray()
## Spawn slots around the view: edge, position, running total of their weight.
var _slot_e := PackedInt32Array()
var _slot_s := PackedFloat32Array()
var _slot_sum := PackedFloat32Array()
## ... and that total: the cars the band holds at density 1 (`race_density`).
var _slot_weight := 0.0
var _target := 40
var _target_at := Vector2.INF
var _target_size := 0.0
var _filled := false
var _view := Rect2()
## The traffic-cost item (2026-10-30): the orthographic camera's origin, right and up axes and
## pixels per metre, kept by _update_view(), so on_screen() projects with three dot products
## instead of two Camera3D.unproject_position calls (the same answer: no h/v offset, KEEP_HEIGHT).
var _cam_o := Vector3.ZERO
var _cam_x := Vector3.RIGHT
var _cam_y := Vector3.UP
var _cam_k := 1.0
var _view_mid := Vector2.ZERO
## ... and the junction cars' ground positions, so the pair test rejects far pairs on a packed
## array instead of reading two drivers' properties.
var _jc_at := PackedVector2Array()
## Step 4b: the racers out of their lane this frame (OUT_* above); what `_race_gap` found (the
## gap, that car's speed along the racer's way, whether it is parked); the cars of the lane a
## pass goes by, in order (`_pass_cars`: each one's tail and nose along the lane, and its speed);
## and what `_pass_plan` worked out (the metres and seconds the pass takes).
var _racers_out: Array[Driver] = []
## Every racer on the road (as of the frame before): `_try_spawn` puts no car down in their way.
var _racers: Array[Driver] = []
## Step 5b: the one-way streets a racer is hopping the wrong way now, {edge: the racer}.
var _hop_held := {}
var _rg_gap := INF
var _rg_v := 0.0
var _rg_parked := false
var _sr_lo := 0.0
var _sr_hi := 0.0
var _pl_rear := PackedFloat32Array()
var _pl_front := PackedFloat32Array()
var _pl_v := PackedFloat32Array()
var _pp_x := 0.0
var _pp_t := 0.0
## ... and for `_race_cross`: the cars near, and the places and times of one car's way.
var _rc_near: Array[Driver] = []
var _rc_at := PackedVector2Array()
var _rc_mid := PackedVector2Array()
var _rc_dir := PackedVector2Array()
## The ground in view, kept by _update_view(): centre, right and ahead axes, half size (m).
var view_centre := Vector2.ZERO
## A zone the traffic keeps out of (event_day.gd's cordon): (Vector2 game-plane point) -> bool.
## Cars inside it are released and none spawn there. Invalid: no zone.
var keep_out: Callable
var view_right := Vector2.RIGHT
var view_ahead := Vector2.UP
var view_half := Vector2.ONE
var _lamps: MultiMesh
## Soft halos round the lit signal lamps (night only).
var _halos: MultiMesh
var _lamp_state := PackedInt32Array()
## Controller*2+group -> lamp instance indices (first of three per pole).
var _lamp_slots := {}
## The performance lane (2026-10-30): `_lamp_slots`' keys, checked LAMP_STRIDE frames apart in
## turn. Loop 3d-1's bigger map has every signal of 18.6 km² in here, and asking each one's
## light every frame grew with the map; a lamp now changes at most LAMP_STRIDE frames (0.1 s
## at 60 fps) after its controller does. The cars read `graph.light` themselves, unaffected.
var _lamp_keys := PackedInt32Array()
var _lamp_turn := 0
const LAMP_STRIDE := 6


func setup(lane_graph: LaneGraph, map_node: Node3D, camera: Camera3D, data: Dictionary) -> void:
	graph = lane_graph
	map = map_node
	cam = camera
	_line = RaceLine.new(graph)
	_rng.seed = 2026
	_looks.seed = 2027
	_loud_rng.seed = 2028
	_crazy_rng.seed = 2030
	_lane_cars.resize(graph.lane_count)
	for i in graph.lane_count:
		_lane_cars[i] = []
	for i in MAX_CARS + 8:
		_free.append(Driver.new())
	for k in POOL.size():
		await LoadYield.tick("traffic kind %d" % k)  # the loading bar: a frame between the kinds' meshes
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		InstanceBuffers.prepare(mm)
		# Loop 3g-1: POLICE draws the patrol estate and the guards' car (shapes 0 and 1).
		mm.mesh = Models.police_mesh() if k == Kind.POLICE else Models.traffic_mesh(k)
		mm.instance_count = POOL[k]
		mm.visible_instance_count = 0
		# Instances move all over the map; never cull the whole set.
		mm.custom_aabb = AABB(Vector3(-2500, -200, -1500), Vector3(5000, 600, 3000))
		var buf := PackedFloat32Array()
		buf.resize(POOL[k] * 16)
		buf.fill(0.0)
		InstanceBuffers.send(mm.get_rid(), buf)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(mmi)
		_mm.append(mm)
		_buf.append(buf)
		var slots := PackedInt32Array()
		for i in range(POOL[k] - 1, -1, -1):
			slots.append(i)
		_free_slots.append(slots)
		if k == Kind.POLICE:
			# Loop 3g-1 (police.md section 12): a small caster (no shadow on Medium), and no
			# headlight pools of its own: the light bar's halos light the road at night.
			mmi.add_to_group(MapBuilder.SMALL_CASTERS, true)
			continue
		var beam := MultiMesh.new()
		beam.transform_format = MultiMesh.TRANSFORM_3D
		beam.use_custom_data = true
		InstanceBuffers.prepare(beam)
		beam.mesh = Models.headlight_pools(LENGTH[k] * 0.5, 0.85 if k == Kind.BUS else 0.6, 15.0 if k == Kind.BUS else 13.0)
		beam.instance_count = POOL[k]
		beam.visible_instance_count = 0
		beam.custom_aabb = mm.custom_aabb
		InstanceBuffers.send(beam.get_rid(), buf)
		var bmi := MultiMeshInstance3D.new()
		bmi.multimesh = beam
		bmi.material_override = Models.glow_material()
		bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		bmi.visible = false
		bmi.add_to_group("night_lights")
		add_child(bmi)
		_beam_mm.append(beam)
		_beam_mmi.append(bmi)
	for i in BODIES:
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		body.collision_layer = 0
		body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		body.add_child(shape)
		add_child(body)
		_bodies.append(body)
		_body_driver.append(null)
	await LoadYield.tick("traffic bodies")
	_build_lamps(data.get("signals", []))


# --- the frame ------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or graph == null:
		return
	var t0 := Time.get_ticks_usec()
	graph.clock += dt
	_update_lamps()
	_update_view()
	if spawning:
		_manage()
		# Loop 3g-1: patrol cars, by their own count.
		patrol_wait -= dt
		if police_target > 0:
			_manage_police()
	_junction_conflicts()
	if not _sirens.is_empty():
		_give_way_to_sirens()
	_racers_out.clear()
	_racers.clear()
	_hop_held.clear()
	for d in _active:
		if d.race_accel <= 0.0 or d.parked:
			continue
		_racers.append(d)
		if d.hop_go:
			var hop := RaceCuts.hop(graph.e_b[d.edge], graph.e_a[d.next_edge]) if d.on_cut and d.next_edge >= 0 else -1
			if hop >= 0:
				_hop_held[hop] = d
			else:
				d.hop_go = false
		if not d.ghost and (d.v < 1.0 or (not d.in_conn \
				and (d.pass_t > 0.0 or absf(d.off - graph.lane_offset(d.edge, d.lane)) > OUT_OFF))):
			_racers_out.append(d)
	var i := 0
	visible_count = 0
	_tick += 1
	while i < _active.size():
		var d := _active[i]
		d.pending += dt
		# Out of sight, half the updates are plenty (and halve the cost there).
		if not d.visible and d.node == null and not d.ghost and (i + _tick) % 2 == 0:
			i += 1
			continue
		_drive(d, d.pending)
		d.pending = 0.0
		if not d.active:
			continue  # released; the last driver took its place
		if d.visible:
			visible_count += 1
		i += 1
	_write()
	if count_overlaps:
		_count_overlaps()
	last_usec = Time.get_ticks_usec() - t0


func _physics_process(_dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_bodies_step(_dt)
	spent_usec += Time.get_ticks_usec() - t0


func _bodies_step(_dt: float) -> void:
	# The cars nearest the player get a body each, so the player's car bumps them.
	var used := 0
	var p := Vector2(player_pos.x, player_pos.z)
	if player_on_road:
		for d in _active:
			if used >= BODIES:
				break
			if d.ghost or Vector2(d.pos.x, d.pos.z).distance_squared_to(p) > BODY_RANGE * BODY_RANGE:
				continue
			var body := _bodies[used]
			var box: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape
			if box.size != d.size:
				box.size = d.size
			body.collision_layer = 1
			body.global_transform = Transform3D(Basis(Vector3.UP, d.yaw), d.pos + Vector3(0, d.size.y * 0.5 + 0.1, 0))
			_body_driver[used] = d
			used += 1
	for k in range(used, BODIES):
		if _body_driver[k] != null:
			_bodies[k].collision_layer = 0
			_bodies[k].global_position = Vector3(0, -500 - k * 10, 0)
			_body_driver[k] = null


## The player's car hit something; if it was one of ours, that car stops a moment.
func on_player_bump(collider: Object, speed := 0.0) -> void:
	# Walls, kiosks and statues are static bodies: not one of ours (and a typed
	# array's find() refuses another type).
	if not collider is AnimatableBody3D:
		return
	var k := _bodies.find(collider)
	if k >= 0 and _body_driver[k] != null:
		var d: Driver = _body_driver[k]
		_shove(d)
		if d.kind == Kind.POLICE:
			# Loop 3g-1: police.gd decides (a warning, a ram); a parked one doesn't budge.
			if not d.parked:
				d.daze = DAZE_POLICE
			bumped_police.emit(d, speed)
			return
		d.daze = maxf(d.daze, lerpf(DAZE_BRUSH, DAZE, clampf((speed - BRUSH_HIT) / (FULL_HIT - BRUSH_HIT), 0.0, 1.0)))
		bumped_driver.emit(d)


## The driving-feel loop: the player's car (going `player_vel`, the speed before the hit) pushes
## the car it hit: along its lane up to SHOVE_ALONG of the speed it lacks, across it off its
## line (not on a junction's curve, which has no line to leave). A parked police car stays put.
func _shove(d: Driver) -> void:
	if d.parked or d.ghost:
		return
	var pv := Vector2(player_vel.x, player_vel.z)
	var along := pv.dot(Vector2(-sin(d.yaw), -cos(d.yaw)))
	var closing := maxf(along - d.v, 0.0)
	if along > d.v:
		d.v += closing * SHOVE_ALONG
	if d.in_conn:
		return
	var e := d.edge
	var s := minf(d.s, graph.e_len[e])
	var seg := graph.seek(e, s, d.seg)
	var across := graph.point(e, s, 1.0, seg) - graph.point(e, s, 0.0, seg)
	# Rammed from behind it also swerves away from the player's side (a square hit: to the
	# right), so the player gets past instead of pushing it down the road.
	var lat := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z).dot(across)
	var away := -1.0 if lat > 0.0 else 1.0
	var push := clampf(pv.dot(across) * SHOVE_SIDE + away * closing * SHOVE_SWERVE, -SHOVE_SLIDE, SHOVE_SLIDE)
	if absf(push) > absf(d.slide):
		d.slide = push


# --- spawning ---------------------------------------------------------------------

## The ground under the view: its centre, the camera's right and ahead axes on the
## ground, and half its size; the viewport rectangle for the on-screen test.
func _update_view() -> void:
	var b := cam.global_transform.basis
	var o := cam.global_position
	var f := -b.z
	var t := (player_pos.y - o.y) / minf(f.y, -0.05)
	var c := o + f * t
	view_centre = Vector2(c.x, c.z)
	view_right = Vector2(b.x.x, b.x.z).normalized()
	view_ahead = Vector2(f.x, f.z).normalized()
	var vp := cam.get_viewport().get_visible_rect().size
	view_half = Vector2(cam.size * vp.x / maxf(vp.y, 1.0) * 0.5, cam.size * 0.5 / maxf(-f.y, 0.2))
	_view = Rect2(Vector2.ZERO, vp).grow(vp.y * 0.06)
	_cam_o = o
	_cam_x = b.x
	_cam_y = b.y
	_cam_k = vp.y / maxf(cam.size, 0.001)
	_view_mid = vp * 0.5


func on_screen(p: Vector3, height: float) -> bool:
	var r := p - _cam_o
	var at := Vector2(_view_mid.x + r.dot(_cam_x) * _cam_k, _view_mid.y - r.dot(_cam_y) * _cam_k)
	var up := height * _cam_k
	return _view.has_point(at) or _view.has_point(at + Vector2(_cam_x.y * up, -_cam_y.y * up))


## View coordinates of a ground point: metres right of and ahead of the view centre.
func _local(p: Vector2) -> Vector2:
	var q := p - view_centre
	return Vector2(q.dot(view_right), q.dot(view_ahead))


func _manage() -> void:
	if _target_at.distance_to(view_centre) > 16.0 or absf(_target_size - cam.size) > 4.0:
		_target_at = view_centre
		_target_size = cam.size
		_target = _count_target()
	var far := view_half + Vector2.ONE * (MARGIN + 30.0)
	var i := 0
	while i < _active.size():
		var d := _active[i]
		i += 1
		if d.persistent or d.ghost or d.visible:
			continue
		if keep_out.is_valid() and keep_out.call(Vector2(d.pos.x, d.pos.z)):
			_release(d)
			i -= 1
			continue
		var l := _local(Vector2(d.pos.x, d.pos.z))
		var gone := absf(l.x) > far.x or absf(l.y) > far.y
		# Too many (zoomed in, or the frame governor's CPU step lowered the density): thin out the
		# cars just outside the view first. Loop 3g-1: never a police car (they have their own
		# count; a chaser, a trap's car, a blocker are persistent anyway).
		if not gone and _counts_total() > _target + 6 and d.kind != Kind.POLICE:
			gone = absf(l.x) > view_half.x + 12.0 or absf(l.y) > view_half.y + 12.0
		# Stuck out of sight for a long time (a jam that will never clear).
		if gone or d.still > 45.0:
			_release(d)
			i -= 1
	var tries := 600 if not _filled else 30
	var made := 0
	for k in tries:
		if _counts_total() >= _target or made >= (200 if not _filled else 4):
			break
		if _try_spawn(not _filled):
			made += 1
	_filled = true


## The traffic kinds' cars (loop 3g-1: not the police, which have their own count).
func _counts_total() -> int:
	return _counts[0] + _counts[1] + _counts[2] + _counts[3]


## Spawn slots every 8 m along the lanes inside the band around the view, each
## weighted by how much traffic its road should carry; their total weight is how
## many cars the view should hold.
func _count_target() -> int:
	var reach := view_half + Vector2.ONE * MARGIN
	var corner := (view_right * reach.x).abs() + (view_ahead * reach.y).abs()
	var lo := view_centre - corner
	var hi := view_centre + corner
	var cell := LaneGraph.CELL
	var seen := {}
	_slot_e.clear()
	_slot_s.clear()
	_slot_sum.clear()
	var total := 0.0
	var z := lo.y
	while z <= hi.y + cell:
		var x := lo.x
		while x <= hi.x + cell:
			for e in graph.grid.get(LaneGraph.cell_key(Vector2(x, z)), PackedInt32Array()):
				if seen.has(e):
					continue
				seen[e] = true
				var w: float = graph.e_lanes[e] * DENSITY[graph.e_class[e]] * SLOT
				var at := graph.e_s0[e] + 4.0
				while at < graph.e_s1[e] - 6.0:
					var l := _local(graph.point_at(e, at))
					# The edge roadworks: no car between a barrier line and the map's edge.
					if absf(l.x) <= reach.x and absf(l.y) <= reach.y and not graph.closed_at(e, at + SHUT_ROOM) \
							and not graph.closed_at(e, at - SHUT_ROOM) and not graph.in_works_band(graph.point_at(e, at)):
						total += w
						_slot_e.append(e)
						_slot_s.append(at)
						_slot_sum.append(total)
					at += SLOT
			x += cell
		z += cell
	_slot_weight = total
	return clampi(int(total * density), 6, MAX_CARS)


func _try_spawn(anywhere: bool) -> bool:
	if _slot_e.is_empty():
		return false
	# A slot near the view, more likely the more traffic its road should carry.
	var k := mini(_slot_sum.bsearch(_rng.randf() * _slot_sum[_slot_sum.size() - 1]), _slot_e.size() - 1)
	var e := _slot_e[k]
	var cls := graph.e_class[e]
	var lane := _rng.randi() % graph.e_lanes[e]
	var s := clampf(_slot_s[k] + _rng.randf_range(-SLOT, SLOT) * 0.5, graph.e_s0[e] + 4.0, graph.e_s1[e] - 6.0)
	if graph.closed_at(e, s + SHUT_ROOM) or graph.closed_at(e, s - SHUT_ROOM):
		return false
	var q := graph.point_at(e, s, graph.lane_offset(e, lane))
	if keep_out.is_valid() and keep_out.call(q):
		return false
	var kind := Kind.CAR
	var r := _rng.randf()
	if cls == 0 and lane == graph.e_lanes[e] - 1 and r < 0.07:
		kind = Kind.BUS
	elif r < 0.17:
		kind = Kind.VAN
	elif r < 0.27 and cls <= 1:
		kind = Kind.TAXI
	if _free_slots[kind].is_empty():
		kind = Kind.CAR
		if _free_slots[kind].is_empty():
			return false
	var y := graph.height(e, s)
	var shapes: Array = Models.TRAFFIC[kind]
	var shape := 0
	var pick := _looks.randf()
	while shape < shapes.size() - 1 and pick >= float(shapes[shape]["share"]):
		pick -= float(shapes[shape]["share"])
		shape += 1
	# City-life satire #1: now and then a car is a loud supercar (a taxi's slot, its shape).
	var loud := false
	if kind == Kind.CAR and cls <= 1 and loud_count < loud_target and not _free_slots[Kind.TAXI].is_empty() \
			and _loud_rng.randf() < LOUD_CHANCE:
		kind = Kind.TAXI
		shapes = Models.TRAFFIC[kind]
		shape = Models.TAXI_SUPERCAR
		loud = true
	# Crazy drivers: now and then a taxi, a van, or (once at a time) a car's spawn drives wild.
	var crazy := 0
	if not loud and crazy_count < crazy_target and cls <= 2 and kind != Kind.BUS and _crazy_rng.randf() < CRAZY_CHANCE:
		if pasat_count == 0 and cls <= 1 and _crazy_rng.randf() < CRAZY_PASAT_SHARE and not _free_slots[Kind.TAXI].is_empty():
			kind = Kind.TAXI
			shapes = Models.TRAFFIC[kind]
			shape = Models.TAXI_PASAT
			crazy = 3
		elif kind == Kind.TAXI:
			crazy = 1
		elif kind == Kind.VAN:
			shape = 0
			crazy = 2
	var look: Dictionary = shapes[shape]
	var size: Vector3 = look["size"]
	if not anywhere and on_screen(Vector3(q.x, y, q.y), size.y):
		return false
	var lane_id: int = graph.e_lane0[e] + lane
	for o in _lane_cars[lane_id]:
		if absf((o as Driver).ls - s) < size.z + 12.0:
			return false
	if Vector2(player_pos.x, player_pos.z).distance_to(q) < 14.0:
		return false
	# Step 5b: nor on a one-way street a racer is hopping the wrong way.
	if _hop_held.has(e):
		return false
	# Step 4b: nor in a racer's way: no driver answers for a car that was not there when it
	# chose its speed or began a pass (SPAWN_CLEAR).
	for racer in _racers:
		if racer.in_conn:
			continue
		if racer.edge == e:
			var ahead := s - racer.s
			if ahead > -6.0 and ahead < SPAWN_CLEAR + racer.v * racer.v / (2.0 * SPAWN_BRAKE):
				return false
		elif graph.e_reverse[racer.edge] == e and (racer.pass_t > 0.0 or racer in _racers_out):
			var ahead := graph.e_len[e] - s - racer.s
			if ahead > -6.0 and ahead < SPAWN_CLEAR + (racer.v + SPAWN_V) * SPAWN_PASS_T:
				return false
	# Lanes of different roads meet at junctions: keep clear of every car, not just this lane's.
	for o in _active:
		if Vector2(o.pos.x, o.pos.z).distance_squared_to(q) < 100.0 + o.length * o.length:
			return false
	# The traffic loop: and of the trams (a car was put down beside the rails, under a passing
	# tram's side; the tram cars gathered by _give_way_to_trams last frame).
	for c in _tram_at.size():
		var rel := q - _tram_at[c]
		var along := rel.dot(_tram_axis[c])
		if along > -TRAM_CAR * 0.5 - 6.0 and along < TRAM_CAR * 0.5 + _tram_ahead[c] + 12.0 \
				and absf(rel.cross(_tram_axis[c])) < TRAM_HALF + 4.0:
			return false
	var d: Driver = _free.pop_back()
	d.kind = kind
	d.slot = _free_slots[kind][_free_slots[kind].size() - 1]
	_free_slots[kind].resize(_free_slots[kind].size() - 1)
	_counts[kind] += 1
	d.size = size
	d.length = size.z
	d.shape = shape
	var paints: Array = look["paint"]
	d.paint = Color(paints[_rng.randi() % paints.size()])
	d.speed_factor = _rng.randf_range(0.85, 1.08) * (0.85 if kind == Kind.BUS else 1.0)
	d.accel_factor = 0.7 if kind == Kind.BUS else _rng.randf_range(0.85, 1.15)
	d.loud = loud
	if loud:
		loud_count += 1
		d.paint = Color(paints[_loud_rng.randi() % paints.size()])
		d.speed_factor = _loud_rng.randf_range(LOUD_SPEED.x, LOUD_SPEED.y)
		d.accel_factor = LOUD_ACCEL
	d.persistent = false
	d.ghost = false
	d.node = null
	d.core_only = false
	d.crazy = crazy
	if crazy > 0:
		crazy_count += 1
		d.accel_factor = 1.3
		if crazy == 3:
			pasat_count += 1
			d.paint = Color(PASAT_PAINT[_crazy_rng.randi() % PASAT_PAINT.size()])
	_start(d, e, lane, s)
	if crazy > 0:
		# After _start (which clears a pooled car's racer stats): racer mode with no route.
		d.race_top = CRAZY_TOP[crazy]
		d.race_accel = CRAZY_ACCEL[crazy]
		d.race_lat = CRAZY_LAT[crazy]
		d.race_block = CRAZY_BLOCK[crazy]
		d.race_mistake = CRAZY_MISTAKE[crazy]
		d.race_effort = 1.0
		d.race_corner = 1.0
	d.v = graph.e_speed[e] * 0.6
	return true


## Puts a driver on a lane and into the active list.
func _start(d: Driver, e: int, lane: int, s: float) -> void:
	d.active = true
	d.reg = -1
	d.next_reg = -1
	d.stun = 0.0
	d.daze = 0.0
	d.slide = 0.0
	d.held = false
	d.still = 0.0
	d.blocked = 0.0
	d.squeeze = 0.0
	d.clip = 1.0
	d.pending = 0.0
	d.arrived = false
	d.route = PackedFloat32Array()
	d.finish = -1
	d.plan = null
	d.plan_edge = -1
	d.wrong_edge = -1
	d.end_from = INF
	d.back = BACK_NONE
	d.back_v = 0.0
	d.back_wait = 0.0
	d.back_edge = -1
	d.conn_end = -1.0
	d.run_red = false
	d.yield_t = 0.0
	d.pass_t = 0.0
	d.pass_cap = INF
	d.pass_wait = 0.0
	d.off_v = 0.0
	d.swerve = 0.0
	d.swerve_now = 0.0
	d.swerve_t = 0.0
	d.shoulder = 0.0
	d.shoulder_t = 0.0
	d.look_tick = -2
	d.lane_hold = 0.0
	d.away_debt = 0.0
	d.away_pace = 1.0
	if not d.persistent:
		d.race_top = 0.0
		d.race_accel = 0.0
		d.race_brake = 0.0
		d.race_share = 1.0
		d.race_effort = 1.0
		d.race_corner = 1.0
		d.cuts = {}
		d.race_mistake = 0.0
		d.race_wrong = 0
		d.race_block = 0.0
		d.race_dare = 1.0
		d.race_rng = null
	d.on_cut = false
	d.hop_go = false
	d.mistake_side = 0.0
	d.block_t = 0.0
	d.held_up = 0.0
	d.wrong_t = 0.0
	# The night-buses loop: a pooled driver forgets its last stop (and a ring bus's parking).
	d.halt_e = -1
	d.halting = false
	d.tag = ""
	d.parked = false
	d.line = null
	d.line_was = null
	d.line_cuts = []
	d.line_carry = Vector2.ZERO
	d.line_dyn = 0.0
	d.way.clear()
	d.way_cut.clear()
	d.way_wrong.clear()
	_enter_edge(d, e, lane, s)
	d.prev_edge = -1
	var p := graph.point_at(e, s, d.off)
	d.pos = Vector3(p.x, graph.height(e, s), p.y)
	var dir := graph.direction(e, s)
	d.yaw = atan2(-dir.x, -dir.y)
	d.visible = d.ghost == false and on_screen(d.pos, d.size.y)
	_active.append(d)


func _release(d: Driver) -> void:
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = -1
	d.active = false
	if d.loud:
		d.loud = false
		loud_count -= 1
	if d.crazy > 0:
		crazy_count -= 1
		if d.crazy == 3:
			pasat_count -= 1
		d.crazy = 0
	if d.kind < Kind.NODE and d.slot >= 0:
		var base := d.slot * 16
		for k in 12:
			_buf[d.kind][base + k] = 0.0
		_free_slots[d.kind].append(d.slot)
		_counts[d.kind] -= 1
		d.slot = -1
		if d.kind == Kind.POLICE:
			# Loop 3g-1: police.gd sets the pause before the next patrol (patrol_wait).
			police_released.emit(d)
			_police_reset(d)
	var at := _active.find(d)
	if at >= 0:
		_active[at] = _active[_active.size() - 1]
		_active.resize(_active.size() - 1)
	if not d.persistent and not d.ghost:
		_free.append(d)


# --- rivals and the autopilot ------------------------------------------------------

## A persistent driver that draws itself with `node` (a rival's car).
func add_node_driver(node: Node3D, size: Vector3, e: int, lane: int, s: float) -> Driver:
	var d := Driver.new()
	d.kind = Kind.NODE
	d.node = node
	d.persistent = true
	d.core_only = true
	d.size = size
	d.length = size.z
	d.speed_factor = 1.08
	d.accel_factor = 1.3
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_start(d, e, lane, s)
	return d


## The autopilot's invisible driver; the game puts the player's car where it is.
func add_ghost(e: int, lane: int, s: float) -> Driver:
	var d := Driver.new()
	d.kind = Kind.NODE
	d.ghost = true
	d.persistent = true
	d.core_only = true
	d.size = Vector3(1.8, 1.5, 4.0)
	d.length = 4.0
	_start(d, e, lane, s)
	return d


func remove(d: Driver) -> void:
	if d.active:
		_release(d)


## Moves a driver to a lane position at once (and its node, if any).
func teleport(d: Driver, e: int, lane: int, s: float) -> void:
	if d.active and d.kind < Kind.NODE:
		# Loop 3g-1: a pooled car (a chasing police car off the map's edge) keeps its slot.
		if d.reg >= 0:
			_lane_cars[d.reg].erase(d)
		_active.erase(d)
	elif d.active:
		_release(d)
	_start(d, e, lane, s)
	d.v = 0.0
	_place(d)


## Starts racing to graph node `finish`: the driver follows the shortest path by the metres of
## `dist`, or with `plan` (a race_planner.gd Plan to the same node) the quickest way for this
## racer where the plan knows one (`dist` still gives the metres left, `remaining`). It is home
## (`arrived`) at the end of a street into that node, and with a plan made for a finish's circle
## on any street through the circle, where the street enters it (the plan's `ends`).
func race_to(d: Driver, finish: int, dist: PackedFloat32Array, plan = null) -> void:
	d.route = dist
	d.finish = finish
	d.plan = plan
	d.plan_edge = -1
	d.wrong_edge = -1
	d.way.clear()
	d.way_cut.clear()
	d.way_wrong.clear()
	d.turns_back = 0
	d.away_debt = 0.0
	if d.back != BACK_NONE and d.back != BACK_UTURN and d.back != BACK_CURVE:
		# A new finish while it was stopping to turn back: the new plan looks at the street itself.
		d.back = BACK_NONE
		d.back_v = 0.0
	d.arrived = false
	d.end_from = INF
	if not d.in_conn:
		_choose_next(d)


## A racing driver's metres to its finish, counted anew (`dist`: without the streets its plan
## has shut, after `turned_back`): what `remaining` reads. Its way on is its plan's as before.
func reroute(d: Driver, dist: PackedFloat32Array) -> void:
	if not d.route.is_empty():
		d.route = dist


func stop_racing(d: Driver) -> void:
	d.route = PackedFloat32Array()
	d.finish = -1
	d.away_debt = 0.0
	d.plan = null
	d.plan_edge = -1
	d.wrong_edge = -1
	d.end_from = INF
	if d.back != BACK_NONE and d.back != BACK_UTURN and d.back != BACK_CURVE:
		d.back = BACK_NONE
		d.back_v = 0.0
	d.arrived = false
	d.run_red = false
	if not d.in_conn:
		_choose_next(d)


# --- loop 2d-1: Podwózka's GPS moments (gps_moments.gd) -----------------------------------------

## Sends driver d onto edge f at the junction ahead (a GPS U-turn: f is the way back); false if
## it is already in the junction or f is not one of the junction's ways out.
func turn_next(d: Driver, f: int) -> bool:
	if not d.active or d.in_conn or f < 0 or not f in graph.node_out[graph.e_b[d.edge]]:
		return false
	var e := d.edge
	d.next_edge = f
	d.next_lane = graph.next_lane(e, d.lane, f)
	d.conn = graph.connector(e, d.lane, f, d.next_lane)
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(f, graph.e_s0[f])
	d.v_turn = 3.5
	d.next_reg = graph.e_lane0[f] + d.next_lane
	return true


## Driving distance left to the race finish (with a plan: to where its street enters the
## finish's circle, when it is on one that does).
func remaining(d: Driver) -> float:
	if d.route.is_empty():
		return INF
	if d.in_conn:
		var onto := graph.e_s0[d.next_edge]
		return (d.conn_len - d.cu) + (d.plan.metres(d.route, d.next_edge, onto) if d.plan != null else graph.remaining(d.route, d.next_edge, onto))
	return d.plan.metres(d.route, d.edge, d.s) if d.plan != null else graph.remaining(d.route, d.edge, d.s)


func drivers() -> Array[Driver]:
	return _active


# --- loop 3g-1: the police ----------------------------------------------------------------

## Patrol cars come and go with the band like the rest, but by their own count: below
## `police_target` and once the pause after the last one is over, one appears out of sight on a
## main or secondary road (never within `police_min_dist` of the player).
func _manage_police() -> void:
	if patrol_wait > 0.0 or _free_slots[Kind.POLICE].is_empty():
		return
	var roaming := 0
	for d in _active:
		if d.kind == Kind.POLICE and d.patrol:
			roaming += 1
	if roaming >= police_target:
		return
	for attempt in 6:
		var d := _try_spawn_police()
		if d != null:
			police_spawned.emit(d)
			return


func _try_spawn_police() -> Driver:
	if _slot_e.is_empty() or _free.is_empty():
		return null
	var k := mini(_slot_sum.bsearch(_rng.randf() * _slot_sum[_slot_sum.size() - 1]), _slot_e.size() - 1)
	var e := _slot_e[k]
	if graph.e_class[e] > 1:
		return null  # main and secondary roads only (police.md section 2)
	var lane := _rng.randi() % graph.e_lanes[e]
	var s := clampf(_slot_s[k], graph.e_s0[e] + 4.0, graph.e_s1[e] - 6.0)
	var q := graph.point_at(e, s, graph.lane_offset(e, lane))
	if on_screen(Vector3(q.x, graph.height(e, s), q.y), 1.6):
		return null
	var me := Vector2(player_pos.x, player_pos.z)
	if me.distance_to(q) < maxf(police_min_dist, 14.0):
		return null
	# Ahead of a moving player (one behind would leave the band before it is met).
	var going := Vector2(player_vel.x, player_vel.z)
	if going.length() > 3.0 and (q - me).dot(going) < 0.0:
		return null
	if not _lane_clear(e, lane, s, 16.0, q):
		return null
	# Every third patrol car is the van (the silver Crafter), picked by a counter, not _rng.
	_patrol_spawns += 1
	var d := _take_police(3 if _patrol_spawns % 3 == 0 else 0)
	d.patrol = true
	d.persistent = false
	_start(d, e, lane, s)
	d.v = graph.e_speed[e] * 0.6
	return d


## True if lane (e, lane) has nobody within `room` metres of s, and nobody stands near q.
func _lane_clear(e: int, lane: int, s: float, room: float, q: Vector2) -> bool:
	for o in _lane_cars[graph.e_lane0[e] + lane]:
		if absf((o as Driver).ls - s) < room:
			return false
	for o in _active:
		if Vector2(o.pos.x, o.pos.z).distance_squared_to(q) < 49.0 + o.length * o.length:
			return false
	return true


## A police driver from the pool (shape 0 the patrol estate, 1 the guards' car, 2 the ambulance,
## 3 the patrol van), not yet placed.
func _take_police(shape: int) -> Driver:
	var d: Driver = _free.pop_back()
	d.kind = Kind.POLICE
	d.slot = _free_slots[Kind.POLICE][_free_slots[Kind.POLICE].size() - 1]
	_free_slots[Kind.POLICE].resize(_free_slots[Kind.POLICE].size() - 1)
	_counts[Kind.POLICE] += 1
	# The crash scenes: shape 2 the ambulance (the panel van; models.gd police_mesh()); shape 3 the
	# patrol van (the same body, silver with the police livery).
	d.size = [Vector3(1.85, 1.62, 4.7), Vector3(1.63, 1.43, 4.14), Vector3(1.98, 2.56, 5.2),
			Vector3(1.98, 2.56, 5.2)][clampi(shape, 0, 3)]
	d.length = d.size.z
	d.shape = shape
	d.paint = [Models.POLICE_SILVER, Models.GUARD_MUSTARD, Models.AMBULANCE_YELLOW,
			Models.POLICE_SILVER][clampi(shape, 0, 3)]
	d.speed_factor = 0.95
	d.accel_factor = 1.0
	d.ghost = false
	d.node = null
	d.core_only = true
	_police_reset(d)
	return d


## Clears a police car's state (on taking it and on releasing it).
func _police_reset(d: Driver) -> void:
	d.lights = false
	d.patrol = false
	d.parked = false
	d.chase = false
	d.v_cap = 0.0
	d.keep_gap = 2.4
	d.goal = Vector2.INF
	d.persistent = false
	_sirens.erase(d)


## Loop 3g-1, for police.gd: a police car on lane (e, lane) at s (a blocker, the roadblock, a
## test's chaser), kept until remove(); null if the pool is empty.
func add_police(e: int, lane: int, s: float, shape := 0) -> Driver:
	if _free_slots[Kind.POLICE].is_empty() or _free.is_empty():
		return null
	var d := _take_police(shape)
	d.persistent = true
	_start(d, e, lane, s)
	d.v = 0.0
	return d


## Loop 3g-1: parks a police car at `at`, heading `yaw` (a speed trap's car on the kerb facing
## the traffic, a blocker across a lane), by s along edge e (where it pulls out from). It is
## never driven and keeps its body near the player (it is solid). It leaves every lane, or with
## `block_lane` (a lane of e) stands in that one at s, so the traffic there stops behind it.
func park(d: Driver, e: int, s: float, at: Vector3, yaw: float, block_lane := -1) -> void:
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = -1
	d.next_reg = -1
	if block_lane >= 0:
		_register(d, graph.e_lane0[e] + block_lane)
		d.lane = block_lane
	d.ls = s
	d.parked = true
	d.edge = e
	d.s = s
	d.in_conn = false
	d.v = 0.0
	d.route = PackedFloat32Array()
	d.pos = at
	d.yaw = yaw
	d.park_yaw = yaw
	d.clip = 1.0
	d.visible = on_screen(d.pos, d.size.y)


## The crash scenes (crash_scenes.gd): a traffic car of shape `shape` (models.gd TRAFFIC[CAR])
## in `paint`, parked at `at` heading `yaw` and standing in lane `block_lane` of edge e at s (as
## park()): a wreck. Kept until drop_parked(); null if the pool is out.
func add_parked_car(e: int, s: float, at: Vector3, yaw: float, block_lane: int, shape: int, paint: Color) -> Driver:
	if _free_slots[Kind.CAR].is_empty() or _free.is_empty():
		return null
	var d: Driver = _free.pop_back()
	d.kind = Kind.CAR
	d.slot = _free_slots[Kind.CAR][_free_slots[Kind.CAR].size() - 1]
	_free_slots[Kind.CAR].resize(_free_slots[Kind.CAR].size() - 1)
	_counts[Kind.CAR] += 1
	var shapes: Array = Models.TRAFFIC[Kind.CAR]
	d.shape = clampi(shape, 0, shapes.size() - 1)
	d.size = shapes[d.shape]["size"]
	d.length = d.size.z
	d.paint = paint
	d.speed_factor = 1.0
	d.accel_factor = 1.0
	d.persistent = true
	d.ghost = false
	d.node = null
	d.core_only = false
	_start(d, e, block_lane, s)
	park(d, e, s, at, yaw, block_lane)
	return d


## The crash scenes: a wreck from add_parked_car() leaves (back to the pool).
func drop_parked(d: Driver) -> void:
	if d == null or not d.active:
		return
	d.persistent = false
	d.parked = false
	_release(d)


## The crash scenes: true if lane (e, lane) has nobody from s0 to s1 (with `room` m either side).
func lane_free(e: int, lane: int, s0: float, s1: float, room: float) -> bool:
	for o in _lane_cars[graph.e_lane0[e] + lane]:
		var ls: float = (o as Driver).ls
		if ls > s0 - room and ls < s1 + room:
			return false
	return true


## Loop 3g-1: a parked police car pulls out onto lane (e, lane) at s, the traffic's way.
func unpark(d: Driver, e: int, lane: int, s: float) -> void:
	d.parked = false
	_enter_edge(d, e, lane, s)
	d.v = 0.0
	_place(d)


## Loop 3g-1: a police car's light bar on or off (SIREN in actor.gdshader; traffic gives way).
func set_lights(d: Driver, on: bool) -> void:
	d.lights = on
	if on and not d in _sirens:
		_sirens.append(d)
	elif not on:
		_sirens.erase(d)


## Loop 3g-1: the police cars out now (patrols, traps, chasers).
func police() -> Array[Driver]:
	var out: Array[Driver] = []
	for d in _active:
		if d.kind == Kind.POLICE:
			out.append(d)
	return out


## Cars up to YIELD_REACH ahead of a police car with its lights on, in its lane or the next
## one it turns into, give way: the kerb lane and YIELD_SPEED for YIELD_TIME (police.md 4).
func _give_way_to_sirens() -> void:
	for p in _sirens:
		if not p.active or p.parked or p.reg < 0:
			continue
		for o in _lane_cars[p.reg]:
			if o != p and o.kind < Kind.POLICE and o.ls > p.ls and o.ls - p.ls < YIELD_REACH:
				o.yield_t = YIELD_TIME
		if not p.in_conn and p.next_reg >= 0 and graph.e_s1[p.edge] - p.s < YIELD_REACH:
			for o in _lane_cars[p.next_reg]:
				if o.kind < Kind.POLICE and o.ls - graph.e_s0[p.next_edge] < YIELD_REACH - (graph.e_s1[p.edge] - p.s):
					o.yield_t = YIELD_TIME


## Loop 3g-1: moves to lane `k` of its road if it is free alongside (giving way).
func _change_lane_to(d: Driver, k: int) -> void:
	var e := d.edge
	if graph.e_s1[e] - d.s < 18.0 or _line_busy(d):
		return
	for o in _lane_cars[graph.e_lane0[e] + k]:
		if o != d and absf(o.ls - d.ls) < (o.length + d.length) * 0.5 + 3.0:
			return
	d.lane = k
	_register(d, graph.e_lane0[e] + k)
	d.off_target = graph.lane_offset(e, k)
	_choose_next(d)


## Loop 3g-1: gap to the first stop line ahead showing red or amber, whatever the driver runs.
func _red_gap(d: Driver) -> float:
	var stops := graph.e_stops[d.edge]
	var front := d.s + d.length * 0.5
	for k in range(0, stops.size(), 3):
		if stops[k] < front - 0.2:
			continue
		if graph.light(int(stops[k + 1]), int(stops[k + 2])) == LaneGraph.GREEN:
			return INF
		return stops[k] - front
	return INF


# --- driving ------------------------------------------------------------------------

## Lanes keep cars apart along a lane, but junction curves from different
## approaches cross each other. Cars in a junction box (or about to enter one)
## check each other: a car straight ahead in our path is a leader. When two cars
## are each in the other's path, the one already further in goes first, so they
## never wait for each other.
func _junction_conflicts() -> void:
	junction_cars.clear()
	for d in _active:
		d.cross_gap = INF
		d.sees_tram = false
		# (Also just out of a junction curve: its first metres still lie in the junction box.)
		if not d.ghost and not d.parked and (d.in_conn or graph.e_s1[d.edge] - d.s < 14.0
				or d.s - graph.e_s0[d.edge] < PATH_EXIT):
			junction_cars.append(d)
	if trams != null:
		_give_way_to_trams()
	var n := junction_cars.size()
	_jc_at.resize(n)
	for a in n:
		_jc_at[a] = Vector2(junction_cars[a].pos.x, junction_cars[a].pos.z)
	for a in n:
		var at := _jc_at[a]
		var p: Driver = null
		var pf := Vector2.ZERO
		for b in range(a + 1, n):
			var rel := _jc_at[b] - at
			if rel.length_squared() > 196.0:
				continue
			if p == null:
				p = junction_cars[a]
				pf = Vector2(-sin(p.yaw), -cos(p.yaw))
			var q := junction_cars[b]
			# Followers in one lane keep their gap by the lane; two curves merging into one lane
			# (two turn lanes into one) are both registered there, side by side: checked here.
			if q.reg == p.reg and not (p.in_conn and q.in_conn and p.lane != q.lane):
				continue
			var qf := Vector2(-sin(q.yaw), -cos(q.yaw))
			# The traffic loop (2026-10-30): the other car's body and where it goes in the next
			# PATH_LOOK s, not just its centre, against our corridor (cars crossing at an angle
			# were seen too late, both drove into the box and one went through the other).
			var p_gap := _path_gap(p, pf, q, qf, rel)
			var q_gap := _path_gap(q, qf, p, pf, -rel)
			var p_sees := p_gap < INF
			var q_sees := q_gap < INF
			if p_sees and q_sees:
				# Both in each other's way: the one deeper into the junction goes.
				if p.in_conn and (not q.in_conn or p.cu / p.conn_len > q.cu / q.conn_len):
					p_sees = false
				else:
					q_sees = false
			if p_sees:
				if p_gap < p.cross_gap:
					p.cross_gap = p_gap
					p.cross_v = maxf(0.0, qf.dot(pf) * q.v)
			elif q_sees:
				if q_gap < q.cross_gap:
					q.cross_gap = q_gap
					q.cross_v = maxf(0.0, pf.dot(qf) * p.v)


## The traffic loop: the gap (m) from p's front to the nearest part of q that is in p's way: q's
## body from its tail to its nose and on PATH_LOOK s of its own way, in discs of q's half width,
## against p's corridor (both half widths and PATH_MARGIN), from beside p's front half to
## PATH_AHEAD m ahead; INF if none is.
func _path_gap(p: Driver, pf: Vector2, q: Driver, qf: Vector2, rel: Vector2) -> float:
	var reach := p.size.x * 0.5 + q.size.x * 0.5 + PATH_MARGIN
	var best := INF
	var k := -q.length * 0.5
	var last := q.length * 0.5 + q.v * PATH_LOOK
	while true:
		var c := rel + qf * minf(k, last)
		var along := c.dot(pf) - p.length * 0.5
		if along > -p.length * 0.5 and along < PATH_AHEAD and absf(c.cross(pf)) < reach:
			best = minf(best, along - q.size.x * 0.5)
		if k >= last:
			break
		k += 1.0
	return best


## Testing aid: every pair of drawn traffic cars (not ghosts, not parked) whose boxes overlap
## by more than 0.15 m this frame (2D separating axes on their footprints).
func _count_overlaps() -> void:
	_ov_frames += 1
	var n := _active.size()
	for a in n:
		var p := _active[a]
		if p.ghost or p.parked or p.clip < 1.0:
			continue
		for b in range(a + 1, n):
			var q := _active[b]
			if q.ghost or q.parked or q.clip < 1.0:
				continue
			var rel := Vector2(q.pos.x - p.pos.x, q.pos.z - p.pos.z)
			var reach := (p.length + q.length) * 0.5 + 1.0
			if rel.length_squared() > reach * reach or absf(q.pos.y - p.pos.y) > 2.0:
				continue
			if _boxes_overlap(p, q, rel):
				_ov_pairs += 1
				if p.in_conn or q.in_conn:
					_ov_in_junction += 1
				var key := Vector2i(roundi(p.pos.x / 10.0) * 10, roundi(p.pos.z / 10.0) * 10)
				_ov_spots[key] = int(_ov_spots.get(key, 0)) + 1
	if trams == null:
		return
	for tram in trams.trams:
		if tram.v < 0.3:
			_ov_tram_still += 1
		for body in tram.cars:
			if not body.visible:
				continue
			var t: Transform3D = body.global_transform
			var tc := Vector2(t.origin.x, t.origin.z)
			var tf := -Vector2(t.basis.z.x, t.basis.z.z).normalized()
			for d in _active:
				if d.ghost or d.parked or d.clip < 1.0 or absf(d.pos.y - t.origin.y) > 2.5:
					continue
				var rel := Vector2(d.pos.x, d.pos.z) - tc
				if rel.length_squared() > 64.0:
					continue
				if _sat(tf, 10.5, 2.4, Vector2(-sin(d.yaw), -cos(d.yaw)), d.length, d.size.x, rel):
					_ov_tram += 1
					if tram.v > 0.3:
						_ov_tram_moving += 1
					var key := Vector2i(roundi(d.pos.x / 10.0) * 10, roundi(d.pos.z / 10.0) * 10)
					_ov_tram_spots[key] = int(_ov_tram_spots.get(key, 0)) + 1


## Two boxes (forward axis, length, width) overlap by more than 0.15 m, the second at rel.
static func _sat(pf: Vector2, pl: float, pw: float, qf: Vector2, ql: float, qw: float, rel: Vector2) -> bool:
	var pr := Vector2(-pf.y, pf.x)
	var qr := Vector2(-qf.y, qf.x)
	for ax: Vector2 in [pf, pr, qf, qr]:
		var rp := absf(pf.dot(ax)) * pl * 0.5 + absf(pr.dot(ax)) * pw * 0.5
		var rq := absf(qf.dot(ax)) * ql * 0.5 + absf(qr.dot(ax)) * qw * 0.5
		if absf(rel.dot(ax)) > rp + rq - 0.15:
			return false
	return true


static func _boxes_overlap(p: Driver, q: Driver, rel: Vector2) -> bool:
	var axes := [Vector2(-sin(p.yaw), -cos(p.yaw)), Vector2(cos(p.yaw), -sin(p.yaw)),
			Vector2(-sin(q.yaw), -cos(q.yaw)), Vector2(cos(q.yaw), -sin(q.yaw))]
	var pf: Vector2 = axes[0]
	var pr: Vector2 = axes[1]
	var qf: Vector2 = axes[2]
	var qr: Vector2 = axes[3]
	for ax: Vector2 in axes:
		var rp := absf(pf.dot(ax)) * p.length * 0.5 + absf(pr.dot(ax)) * p.size.x * 0.5
		var rq := absf(qf.dot(ax)) * q.length * 0.5 + absf(qr.dot(ax)) * q.size.x * 0.5
		if absf(rel.dot(ax)) > rp + rq - 0.15:
			return false
	return true


func _exit_tree() -> void:
	if not count_overlaps:
		return
	var worst := Vector2i.ZERO
	var most := 0
	for k: Vector2i in _ov_spots:
		if int(_ov_spots[k]) > most:
			most = int(_ov_spots[k])
			worst = k
	print("traffic overlaps: %d car-pair frames in %d frames (%d with a car on a junction curve), %d spots; worst %d frames at %d, %d; %d knots given up" % [
			_ov_pairs, _ov_frames, _ov_in_junction, _ov_spots.size(), most, worst.x, worst.y, _ov_knots])
	worst = Vector2i.ZERO
	most = 0
	for k: Vector2i in _ov_tram_spots:
		if int(_ov_tram_spots[k]) > most:
			most = int(_ov_tram_spots[k])
			worst = k
	print("traffic tram overlaps: %d tram-car frames (%d with the tram moving), %d spots; worst %d frames at %d, %d; trams standing %d tram frames" % [
			_ov_tram, _ov_tram_moving, _ov_tram_spots.size(), most, worst.x, worst.y, _ov_tram_still])
	if OS.is_stdout_verbose():
		for k: Vector2i in _ov_tram_spots:
			print("  tram overlap spot %d, %d: %d" % [k.x, k.y, int(_ov_tram_spots[k])])


func _enter_edge(d: Driver, e: int, lane: int, s: float) -> void:
	# Its racing line goes on along the street it enters, or is dropped here (while its place is
	# still the end of the curve it came by).
	_line_settle(d)
	# Step 6a: onto the street of a wrong turn (the one chosen at `wrong_edge`'s end, not a way
	# back onto its own street): the satnav's moment.
	var took_wrong := d.wrong_edge >= 0 and d.wrong_edge == d.edge and e != d.edge and d.race_rng != null
	var on_line := d.line != null and d.conn_end < 0.0 and d.line_q + 1 < d.line.edges.size() \
			and d.line.edges[d.line_q + 1] == e and d.line.lanes[d.line_q + 1] == lane
	if not on_line:
		_line_drop(d)
	d.prev_edge = d.edge
	d.prev_lane = d.lane
	d.back = BACK_NONE
	d.back_v = 0.0
	d.back_wait = 0.0
	d.conn_end = -1.0
	d.edge = e
	d.lane = lane
	d.s = s
	d.seg = graph.e_first[e]
	d.in_conn = false
	d.off = graph.lane_offset(e, lane)
	d.off_target = d.off
	if on_line:
		# (Beside its line it stays where it was, and comes back to its lane as on any street.)
		d.line_q += 1
		d.off += d.line_dyn
	_register(d, graph.e_lane0[e] + lane)
	d.ls = s
	d.on_cut = false
	d.hop_go = false
	d.cut_edge = -1
	d.block_t = 0.0
	# A new street: no way on chosen for it yet, and the wrong turn it took is behind it. (Kept, a
	# rival whose wrong turn led it round the block came onto the same street again and took its
	# stale way on, the street itself: it drove that one street round and round to the time limit.)
	d.plan_edge = -1
	d.wrong_edge = -1
	d.way_rolled = false
	if not d.way.is_empty():
		if on_line:
			# The way on it decided for this street when it was still ahead: held (Plan.choose's
			# `held`), and a wrong turn rolled then is taken.
			d.next_edge = d.way[0]
			d.on_cut = d.way_cut[0] == 1
			d.plan_edge = e
			d.way_rolled = true
			if d.way_wrong[0] == 1:
				d.wrong_edge = e
				d.wrong_turns += 1
			d.way.remove_at(0)
			d.way_cut.remove_at(0)
			d.way_wrong.remove_at(0)
		else:
			_way_clear(d)
	if d.race_top > 0.0 and not d.route.is_empty() and d.crazy == 0 and not d.chase and not d.ghost and _away(d):
		# A racer out of the town's cars owes this street's expected delay (AWAY_* above).
		d.away_debt += race_delay(graph, e, minf(d.race_top, RACE_CLASS_TOP[graph.e_class[e]]) * d.race_share, race_density())
	if d.mistake_side != 0.0:
		# Human rivals: in too fast, out wide: it slides off its line and lifts off a moment.
		d.daze = MISTAKE_DAZE
		d.slide = MISTAKE_SLIDE * d.mistake_side
		d.mistake_side = 0.0
		d.mistakes += 1
	if took_wrong:
		d.daze = maxf(d.daze, WRONG_DAZE)
		d.wrong_t = WRONG_SHOW
	_choose_next(d)


func _register(d: Driver, lane_id: int) -> void:
	if d.ghost:
		return
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = lane_id
	_lane_cars[lane_id].append(d)


## Picks the edge after this one (`_choose_way`), and brings a racer's line up to date with it.
func _choose_next(d: Driver) -> void:
	_choose_way(d)
	_line_sync(d)


## Picks the edge after this one: by the race route, or at random with a liking
## for bigger roads and going straight; a U-turn only at a dead end.
func _choose_way(d: Driver) -> void:
	var e := d.edge
	d.end_from = INF
	if d.plan != null:
		# A racer on a street through its finish's circle, not past it: home where the street
		# enters it. (From there on, not only inside: a street can clip the circle for a metre,
		# less than a fast car, or one out of sight, moves in a step.)
		var end: Vector2 = d.plan.end_of(e)
		if d.s <= end.y:
			d.end_from = end.x
	if graph.e_shut[e] < INF:
		# The edge roadworks: this road is closed at the map's edge; no U-turn past the barriers
		# (the car stops at them, _drive).
		d.next_edge = -1
		d.next_reg = -1
		return
	var outs := graph.node_out[graph.e_b[e]]
	var rev := graph.e_reverse[e]
	var here := graph.direction(e, graph.e_s1[e])
	var best := -1
	if d.plan != null and not d.route.is_empty():
		# A racer with a plan: the quickest way on for it (docs/design/race-ai.md 5). It holds the
		# way it chose for this street unless another saves Plan.SWITCH_GAIN s, and a wrong turn
		# once taken is taken.
		if d.wrong_edge == e and d.next_edge >= 0 and not d.on_cut:
			best = d.next_edge
		else:
			var held := d.next_edge if d.plan_edge == e else -1
			var held_cut := d.on_cut
			best = d.plan.choose(e, d.s, d.v, held, held_cut)
			d.plan_edge = e
			if best != held or d.plan.chosen_cut != held_cut:
				_way_clear(d)  # another way on: what it had decided beyond the old one is void
			if best >= 0 and d.plan.chosen_cut:
				_cut_to(d, e, best)
				return
			d.on_cut = false
			var other: int = d.plan.wrong
			if best >= 0 and d.race_wrong > 0 and other >= 0 and not d.way_rolled and d.route[graph.e_b[e]] > WRONG_FAR:
				# Słoik's satnav: a road that costs him seconds (Plan.WRONG_LEAST to WRONG_MOST; the
				# plan knows the way back from anywhere). One roll a street.
				d.way_rolled = true
				if _race_roll(d) < WRONG_SURE:
					best = other
					d.race_wrong -= 1
					d.wrong_turns += 1
					d.wrong_edge = e
					_way_clear(d)
	if best >= 0:
		pass
	elif not d.route.is_empty():
		var best_d := INF
		var second := -1
		var second_d := INF
		for f in outs:
			var cost: float = graph.e_len[f] + d.route[graph.e_b[f]] + (60.0 if f == rev else 0.0)
			if cost < best_d:
				second = best
				second_d = best_d
				best_d = cost
				best = f
			elif cost < second_d:
				second = f
				second_d = cost
		if racing_mode(d):
			if not d.cuts.is_empty() and d.cuts.has(graph.e_b[e]) and best_d < INF:
				var g := best_cut(graph, d.cuts[graph.e_b[e]], d.route, best_d)
				if g >= 0:
					_cut_to(d, e, g)
					return
			d.on_cut = false
			if d.race_wrong > 0 and second >= 0 and second != rev and second_d < INF and d.route[graph.e_b[e]] > WRONG_FAR \
					and _race_roll(d) < WRONG_CHANCE:
				# Słoik's satnav: the second-best way (the route's distances bring him back).
				best = second
				d.race_wrong -= 1
				d.wrong_turns += 1
		if best < 0 and d.goal != Vector2.INF:
			# Loop 3g-1: beyond the route's reach (distances_to's max_cost): the way whose end
			# lies nearest the goal; back the way it came only at a dead end.
			for f in outs:
				var cost: float = graph.node_pos[graph.e_b[f]].distance_to(d.goal) + (1000.0 if f == rev else 0.0)
				if cost < best_d:
					best_d = cost
					best = f
	else:
		var total := 0.0
		var weights := PackedFloat32Array()
		for f in outs:
			var w := 0.0
			if f != rev and not (d.core_only and graph.node_scc[graph.e_b[f]] == 0):
				w = [3.0, 2.0, 1.0, 0.35][graph.e_class[f]]
				# The edge roadworks: a road closed at the map's edge only when nothing else is open.
				if graph.e_shut[f] < INF:
					w *= 0.02
				if d.kind == Kind.BUS and graph.e_class[f] >= 2:
					w *= 0.05
				if absf(here.angle_to(graph.direction(f, graph.e_s0[f]))) < 0.5:
					w *= 1.6
			weights.append(w)
			total += w
		if total > 0.0:
			var r := _rng.randf() * total
			for k in outs.size():
				r -= weights[k]
				if r <= 0.0 and weights[k] > 0.0:
					best = outs[k]
					break
		elif rev >= 0:
			best = rev
	if best < 0:
		d.next_edge = -1
		d.next_reg = -1
		return
	d.next_edge = best
	# (A racer on a line goes straight on into the lane ahead of its own: race_line.gd `lane_on`.)
	d.next_lane = _line.lane_on(e, d.lane, best) if lined(d) else graph.next_lane(e, d.lane, best)
	d.conn = graph.connector(e, d.lane, best, d.next_lane)
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(best, graph.e_s0[best])
	var turn := absf(here.angle_to(graph.direction(best, graph.e_s0[best])))
	d.v_turn = UTURN_SPEED if best == rev else lerpf(16.0, 5.5, clampf(turn / 1.6, 0.0, 1.0))
	d.conn_pace = 1.0
	var arc := d.conn_len
	var hairpin := false
	if d.race_accel > 0.0 and not d.route.is_empty() and not d.chase:
		# A racer drives a tight curve as the arc a car can turn (RACE_TURN_RADIUS), and a hairpin
		# as a U-turn. A police chaser takes the curve as it is, until it gets the racers' driver
		# (docs/design/race-ai.md, step 6b).
		arc = race_turn_length(d.conn_len, turn)
		d.conn_pace = d.conn_len / arc
		hairpin = best != rev and turn > RACE_HAIRPIN
	if hairpin:
		d.v_turn = UTURN_SPEED
	elif d.race_accel > 0.0 and best != rev and not d.route.is_empty():
		# Effort works on grip too: behind, it takes the corners harder (F: "catch up by driving
		# better, not by a speed boost").
		d.v_turn = race_turn_speed(arc, turn, d.race_lat * clampf(d.race_corner, GRIP_EFFORT_LEAST, GRIP_EFFORT_MOST))
		if d.race_mistake > 0.0 and turn > 0.6 \
				and (d.race_rng != null or Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z).length() < MISTAKE_NEAR) \
				and _race_roll(d) < d.race_mistake:
			# Human rivals: too fast into this one; out wide on the far side (_enter_edge).
			d.v_turn *= MISTAKE_FAST
			d.mistake_side = _outside(e, best)
	if d.crazy > 0 and best != rev:
		# Crazy drivers: racer corners, and the Pasatini now and then too fast into one (seen).
		d.v_turn = race_turn_speed(d.conn_len, turn, d.race_lat)
		if d.race_mistake > 0.0 and turn > 0.6 and Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z).length() < MISTAKE_NEAR \
				and _crazy_rng.randf() < d.race_mistake:
			d.v_turn *= MISTAKE_FAST
			d.mistake_side = _outside(e, best)
	d.next_reg = graph.e_lane0[best] + d.next_lane
	# A racing rival chances some reds.
	# The night-buses loop: a bus on a route (to a stop, the race to the Palm) never does.
	d.run_red = not d.route.is_empty() and d.kind != Kind.BUS and (d.race_top > 0.0 or _rng.randf() < 0.6)
	if d.crazy > 0:
		d.run_red = _crazy_rng.randf() < CRAZY_RED[d.crazy]  # crazy drivers: a fresh red now and then


## Racer mode: the speed (m/s) a racer takes a junction curve of `length` m turning `turn` rad at
## `lat` m/s² sideways (the curve's radius ~ length / turn).
static func race_turn_speed(length: float, turn: float, lat: float) -> float:
	var r := length / maxf(turn, 0.05)
	return clampf(sqrt(lat * r), RACE_TURN_MIN, 40.0)


## Racer mode: the metres a racer drives through a junction curve of `length` m turning `turn` rad:
## the curve's own, or the arc of RACE_TURN_RADIUS where the curve is tighter than a car turns.
static func race_turn_length(length: float, turn: float) -> float:
	return maxf(length, RACE_TURN_RADIUS * turn)


## Human rivals: takes the shortcut from the junction ahead (the end of edge e) that joins edge g
## (chosen by its plan, or by `best_cut` on the metres). Sets up the curve like _choose_next.
func _cut_to(d: Driver, e: int, g: int) -> void:
	d.next_edge = g
	d.next_lane = mini(d.lane, graph.e_lanes[g] - 1)
	d.conn = cut_curve(e, d.lane, g)
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_pace = 1.0
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(g, graph.e_s0[g])
	if RaceCuts.is_link(d.conn):
		# A race link (racer AI step 5): at its tightest bend's speed.
		d.v_turn = RaceCuts.bend_speed(d.conn, d.race_lat, RaceCuts.LINK_TOP)
	else:
		var chord := (d.conn[3] - d.conn[0]).normalized()
		var turn := maxf(absf(graph.direction(e, graph.e_s1[e]).angle_to(chord)), absf(chord.angle_to(graph.direction(g, graph.e_s0[g]))))
		d.v_turn = minf(CUT_TOP, race_turn_speed(d.conn_len, turn * 2.0, d.race_lat))
	d.next_reg = graph.e_lane0[g] + d.next_lane
	d.run_red = true
	d.on_cut = true
	if d.cut_edge != e:
		d.cut_edge = e
		d.cuts_taken += 1
		if RaceCuts.is_link(d.conn):
			d.links_taken += 1


## Step 5b: racer d, with a wrong-way hop ahead (`on_cut`, a link that drives against a one-way
## street), looks down it once it is HOP_DECIDE m from where it could still stop: empty, it takes
## it and the street is held for it (`hop_go`); not empty, the hop is refused for the race and it
## chooses its way on again. True for a racer with no plan (no other way on to choose) while the
## street is not empty: it waits at the stop line.
func _hop_look(d: Driver) -> bool:
	var e := d.edge
	var hop := RaceCuts.hop(graph.e_b[e], graph.e_a[d.next_edge])
	if hop < 0:
		return false
	if d.ghost:
		d.hop_go = true  # (the bench's ghost drives alone: nothing to look for, nothing held)
		d.hops_taken += 1
		return false
	var brake := d.race_brake if d.race_brake > 0.0 else RACE_DECEL * 0.7
	if graph.e_s1[e] - d.s > d.v * d.v / (2.0 * brake) + HOP_DECIDE:
		return false
	if _hop_clear(d, hop):
		d.hop_go = true
		d.hops_taken += 1
		_hop_held[hop] = d
		return false
	if d.plan == null:
		return true
	d.hops_refused += 1
	d.plan.refuse(e, d.next_edge)
	# (It was counted as a shortcut when it was chosen, `_cut_to`.)
	d.cuts_taken -= 1
	d.links_taken -= 1
	d.cut_edge = -1
	hop_refused.emit(d)
	_choose_next(d)
	return false


## Step 5b: whether one-way street `hop` is empty for racer d to drive the wrong way (HOP_* above).
func _hop_clear(d: Driver, hop: int) -> bool:
	if _hop_held.has(hop) and _hop_held[hop] != d:
		return false
	for k in graph.e_lanes[hop]:
		# (Its lanes' lists hold the cars on it and those on a junction's curve into it.)
		if not _lane_cars[graph.e_lane0[hop] + k].is_empty():
			return false
	for o in _active:
		if o == d or o.ghost:
			continue
		if o.parked:
			if o.edge == hop:
				return false
		elif o.next_edge == hop and not o.in_conn \
				and graph.e_s1[o.edge] - o.s - o.length * 0.5 < o.v * o.v / (2.0 * DECEL) + HOP_STOP:
			return false
	return not _player_in(d, d.conn)


## Human rivals: the curve of the shortcut (or race link) from the end of edge e, lane `lane`, onto
## edge g (into the lane of the same number, or g's last): race_cuts.gd `curve`.
func cut_curve(e: int, lane: int, g: int) -> PackedVector2Array:
	return RaceCuts.curve(graph, e, lane, g)


## Human rivals: the edge a racer takes on after the best of `cuts` ([edge on, metres, ...] from
## the junction ahead, race_cuts.gd), or -1 when none beats `road` (the best road route's metres
## from that junction, by `route`). The routing counts a cut exactly so (RaceCuts.cost, with the
## CUT_GAIN it must save), so a racer never circles a cut it won't take. Static for check_race_cuts.gd.
static func best_cut(graph: LaneGraph, cuts: PackedFloat32Array, route: PackedFloat32Array, road: float) -> int:
	var best_g := -1
	var best_cost := road
	for k in range(0, cuts.size(), 2):
		var g := int(cuts[k])
		var cost: float = RaceCuts.cost(cuts[k + 1], graph.e_len[g]) + route[graph.e_b[g]]
		if cost < best_cost:
			best_cost = cost
			best_g = g
	return best_g


## Human rivals: the side (+1/-1 of the lane offset) a car runs wide to out of the turn from e to f.
func _outside(e: int, f: int) -> float:
	var d_in := graph.direction(e, graph.e_s1[e])
	var d_out := graph.direction(f, graph.e_s0[f])
	var seg := graph.seek(f, graph.e_s0[f], graph.e_first[f])
	var across := graph.point(f, graph.e_s0[f], 1.0, seg) - graph.point(f, graph.e_s0[f], 0.0, seg)
	# The turn's inside lies towards d_out - d_in; the car runs out the other way.
	return -1.0 if across.dot(d_out - d_in) > 0.0 else 1.0


## Human rivals: one lateral move onto the chasing player's line (see BLOCK_* above).
func _race_block(d: Driver, dt: float) -> void:
	d.block_t -= dt
	d.block_wait -= dt
	if d.block_t > 0.0 or d.block_wait > 0.0 or d.in_conn or d.pass_t > 0.0 or not player_on_road:
		return
	var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	var along := rel.dot(fwd)
	if along > -3.0 or along < -BLOCK_BACK:
		return
	if Vector2(player_vel.x, player_vel.z).dot(fwd) < d.v - 1.0:
		return  # dropping back: nothing to defend
	d.block_wait = BLOCK_EVERY
	if _rng.randf() >= d.race_block:
		return
	var e := d.edge
	var s := minf(d.s, graph.e_len[e])
	var seg := graph.seek(e, s, d.seg)
	var across := graph.point(e, s, 1.0, seg) - graph.point(e, s, 0.0, seg)
	var lw := graph.e_lw[e]
	var lo := graph.lane_offset(e, 0) - lw * (0.75 if graph.e_reverse[e] >= 0 else 0.3)
	var hi := graph.lane_offset(e, graph.e_lanes[e] - 1) + lw * 0.3
	var want := clampf(d.off + rel.dot(across), lo, hi)
	if absf(want - d.off) < 0.6:
		return  # already on the player's line
	d.block_off = want
	d.block_t = BLOCK_HOLD
	d.blocks += 1


## Racer mode: whether driver d drives as a racer now (a route, and racer stats; or a crazy
## driver, CRAZY_* above, who wanders).
static func racing_mode(d) -> bool:
	return d.race_accel > 0.0 and (not d.route.is_empty() or d.crazy > 0)


func _drive(d: Driver, dt: float) -> void:
	if d.parked:
		# Loop 3g-1: a police car parked off the lane (a trap, a blocker, a roadblock).
		d.visible = on_screen(d.pos, d.size.y)
		return
	if d.back != BACK_NONE:
		# Turning back: the plan looks for the new way meanwhile; backing up is its own drive.
		if d.plan != null and d.back_edge >= 0:
			d.plan.step(d.back_edge, PLAN_SLICE)
		if d.back != BACK_STOP and d.back != BACK_UTURN:
			_drive_back(d, dt)
			return
	var e := d.edge
	var racer := racing_mode(d)
	var hop_stop := false
	if racer and d.on_cut and not d.in_conn and not d.hop_go and d.next_edge >= 0 and RaceCuts.is_link(d.conn):
		hop_stop = _hop_look(d)
	var v0 := graph.e_speed[e] * d.speed_factor
	if racer and d.race_top > 0.0:
		v0 = minf(d.race_top, RACE_CLASS_TOP[graph.e_class[e]]) * d.race_share * d.race_effort
		if d.crazy > 0:
			v0 = minf(v0, graph.e_speed[e] * CRAZY_OVER[d.crazy])
	if d.v_cap > 0.0:
		v0 = d.v_cap  # loop 3g-1: a chaser's own top speed
	if d.yield_t > 0.0:
		# Loop 3g-1: giving way to a police car with its lights on.
		d.yield_t -= dt
		v0 = minf(v0, YIELD_SPEED)
	if d.shoulder != 0.0:
		v0 = minf(v0, SHOULDER_SPEED)
	if d.pass_t > 0.0:
		v0 = minf(v0, d.pass_cap)  # step 4b: a pass given up: falling back behind the car beside it
	var line_v := INF
	if d.line != null:
		line_v = _line_ahead(d, dt)
	if d.line != null:
		v0 = minf(v0, line_v)  # on its racing line: the speed for the metre it comes to
	elif d.in_conn:
		v0 = minf(v0, d.v_turn)
	elif d.next_edge >= 0:
		var brake := (d.race_brake if d.race_brake > 0.0 else RACE_DECEL * 0.7) if racer else DECEL * 0.6
		v0 = minf(v0, sqrt(d.v_turn * d.v_turn + 2.0 * brake * maxf(graph.e_s1[e] - d.s, 0.0)))
	if racer and not d.in_conn and (d.run_red or d.chase) and _red_gap(d) < RACE_RED_LOOK:
		v0 = minf(v0, maxf(SIREN_SLOW * 1.4, v0 * RACE_RED_SLOW))  # racer mode: through a red, a little careful
	elif d.chase and not d.in_conn and _red_gap(d) < 30.0:
		v0 = minf(v0, SIREN_SLOW)  # loop 3g-1: through a red, slowly, with the siren
	var gap := INF
	var lead_v := 0.0
	# The crash scenes: the car ahead is parked in the lane (a wreck, the scene's police car).
	var lead_parked := false
	# The lane it is in (or curving into); the ghost reads lanes without being in them.
	var lane_id: int = d.next_reg if d.in_conn else graph.e_lane0[e] + d.lane
	if d.plan != null and d.back == BACK_NONE and d.in_conn and d.halt_e < 0 and d.conn_end < 0.0:
		# Turning back: in a junction's curve, with the car ahead backing out of the street it is
		# turning into: backwards out of the curve, out of that car's way.
		for o in _lane_cars[lane_id]:
			if o != d and o.ls > d.ls and (o.back == BACK_OUT or o.back == BACK_CURVE) and o.ls - d.ls < BACK_FOLLOW:
				if _curve_back(d):
					_drive_back(d, dt)
					return
				break
	elif d.plan != null and d.back == BACK_NONE and not d.in_conn and d.halt_e < 0:
		# Turning back: a wall within WALL_SEE m (seen past the cars between, and from out over the
		# centre line, where a racer ignores the cars of its own lane).
		var wall_gap := WALL_SEE
		var wall_s := -1.0
		var backing := false
		for o in _lane_cars[lane_id]:
			if o.ls > d.ls:
				if o.parked:
					if o.ls - d.ls - (o.length + d.length) * 0.5 < wall_gap:
						wall_gap = o.ls - d.ls - (o.length + d.length) * 0.5
						wall_s = o.ls
				elif o.back == BACK_OUT and o.ls - d.ls < BACK_FOLLOW:
					backing = true
		if wall_s >= 0.0 and _walled(e, wall_s) and _turn_back(d, true):
			gap = wall_gap
			lead_parked = true
		elif backing:
			_turn_back(d, false)  # the car ahead backs out of the street: so does this one
		elif d.next_reg >= 0 and graph.e_s1[e] - d.s < BACK_SEE:
			for o in _lane_cars[d.next_reg]:
				if o.back == BACK_OUT or o.back == BACK_CURVE:
					# A car backs out of the street it was about to take: another way.
					if d.plan.block(PackedInt32Array([d.next_edge])):
						d.plan_edge = -1
						d.wrong_edge = -1
						turned_back.emit(d)
						_choose_next(d)
					break
	# Step 4b: a racer on a street sees the cars by where they are across the road (`_race_gap`),
	# from where it is to where it is moving over to.
	var by_place := racer and not d.in_conn
	var out_gap := -INF
	var lat := 0.0
	var side_to := d.off_target
	if racer:
		d.swerve_t -= dt
		if d.swerve_t <= 0.0 or d.pass_t > 0.0:
			d.swerve = 0.0
	if by_place:
		lat = _lat_at(e, d.s, Vector2(d.pos.x, d.pos.z))
		if d.pass_t > 0.0:
			# (A pass given up, falling back: as near its lane as the car beside it lets it.)
			if not d.pass_back:
				side_to = d.pass_off
		elif d.block_t > 0.0:
			side_to = d.block_off
		elif d.shoulder != 0.0:
			# Round the player's stopped car: beside it, SIDE_CLEAR m from its side; until past it.
			var way := graph.direction(e, clampf(d.s, 0.0, graph.e_len[e]))
			var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
			d.shoulder_t -= dt
			if d.shoulder_t <= 0.0 or not player_on_road or rel.dot(way) < -(PLAYER_LONG + d.length) * 0.5 - 1.0 \
					or Vector2(player_vel.x, player_vel.z).length_squared() > 4.0:
				d.shoulder = 0.0
			else:
				side_to = d.off + rel.dot(RaceLine.right(way)) + d.shoulder * ((d.size.x + PLAYER_WIDE) * 0.5 + SIDE_CLEAR + 0.1)
		elif d.swerve != 0.0 or d.swerve_now != 0.0:
			# Steering round a car that stands with its side in the way: within its road.
			var room := (graph.e_lw[e] - d.size.x) * 0.5 + SWERVE_OVER
			side_to = clampf(side_to + d.swerve, minf(side_to, graph.lane_offset(e, 0) - room), maxf(side_to, graph.lane_offset(e, graph.e_lanes[e] - 1) + room))
	if d.squeeze <= 0.0:
		if by_place:
			_race_gap(d, lat, lat + side_to - d.off)
			gap = _rg_gap
			lead_v = _rg_v
			lead_parked = _rg_parked
			if d.shoulder != 0.0:
				# Off its road it sees every car by its place: one of another road stands there.
				var way := graph.direction(e, clampf(d.s, 0.0, graph.e_len[e]))
				var right := RaceLine.right(way)
				var here := Vector2(d.pos.x, d.pos.z)
				for o in _active:
					if o == d or o.ghost or o.edge == e or absf(o.pos.y - d.pos.y) > 2.5:
						continue
					var rel := Vector2(o.pos.x, o.pos.z) - here
					if rel.length_squared() > 225.0:
						continue
					var g := rel.dot(way) - (o.length + d.length) * 0.5
					var across := rel.dot(right)
					if g > -1.0 and g < gap and across > minf(0.0, side_to - d.off) - (o.length + d.size.x) * 0.5 \
							and across < maxf(0.0, side_to - d.off) + (o.length + d.size.x) * 0.5:
						gap = maxf(g, 0.0)
						lead_v = 0.0
						lead_parked = false
		else:
			for o in _lane_cars[lane_id]:
				if o != d and o.ls > d.ls:
					var g: float = o.ls - d.ls - (o.length + d.length) * 0.5
					if g < gap:
						gap = g
						lead_v = o.v
						lead_parked = o.parked
		if not d.ghost and d.cross_ignore <= 0.0:
			# ... and any car sees a racer that is out of its lane, or stands, by where it is
			# (and waits for it no longer than for a crossing car: `cross_wait`).
			for r in _racers_out:
				if r == d or r.reg == lane_id or (by_place and r.edge == e and not r.in_conn) or (racer and r.v < 1.0):
					continue
				var r_rel := Vector2(r.pos.x - d.pos.x, r.pos.z - d.pos.z)
				if r_rel.length_squared() > OUT_SEE * OUT_SEE or absf(r.pos.y - d.pos.y) > 2.5:
					continue
				var g := INF
				var r_fwd := Vector2(-sin(r.yaw), -cos(r.yaw))
				if r.v < 1.0:
					# One that stands: in the way only where this car's own way goes through it.
					if r_rel.length_squared() < OUT_NEAR * OUT_NEAR:
						g = _way_gap(d, r, r_fwd)
				else:
					var d_fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
					var r_along := r_rel.dot(d_fwd)
					if r_along > 0.0 and absf(r_rel.cross(d_fwd)) < (r.size.x + d.size.x) * 0.5 + OUT_BESIDE:
						g = r_along - (r.length + d.length) * 0.5
				if g < gap:
					gap = g
					out_gap = g
					lead_v = r_fwd.dot(Vector2(-sin(d.yaw), -cos(d.yaw))) * r.v
					lead_parked = false
		if not d.in_conn and d.next_reg >= 0:
			var base: float = graph.e_s1[e] - d.s + d.conn_len - graph.e_s0[d.next_edge]
			for o in _lane_cars[d.next_reg]:
				if o != d:
					var g: float = base + o.ls - (o.length + d.length) * 0.5
					# (Step 4b: a car on another street's curve into that lane is not in front of a
					# racer by the lane's metres: it is where it is, `_race_cross` looks at it.)
					if by_place and d.crazy == 0 and o.in_conn and o.edge != e:
						continue
					if g < gap:
						gap = g
						lead_v = o.v
						lead_parked = false
	var leader_gap := gap
	if d.back == BACK_STOP and lead_parked:
		gap -= BACK_GAP - MIN_GAP  # it stops BACK_GAP m short of the wall: room to turn round
	var player_gap := INF
	if not d.ghost:
		# (Step 4b: a racer looks along its way for the cars that cross it, `_race_cross`.)
		var looked := racer and d.crazy == 0 and d.squeeze <= 0.0 and d.cross_ignore <= 0.0 and _race_cross(d)
		var cross := d.cross_gap < gap and d.squeeze <= 0.0 and d.cross_ignore <= 0.0 and (not racer or d.crazy > 0 or looked)
		if cross:
			gap = d.cross_gap
			lead_v = d.cross_v
		if not d.in_conn:
			var stop := _red_ahead(d)
			if hop_stop or (d.next_edge >= 0 and not _hop_held.is_empty() and _hop_held.get(d.next_edge) != null and _hop_held[d.next_edge] != d):
				# Step 5b: a racer is hopping the street it turns into the wrong way (or a racer
				# with no other way waits for its hop's street to empty): at the stop line.
				stop = minf(stop, maxf(graph.e_s1[e] - d.s - d.length * 0.5, 0.0))
			if stop < gap:
				gap = stop
				lead_v = 0.0
			# The edge roadworks: the barrier line across a road that leaves the map.
			if d.next_edge < 0 and graph.e_shut[e] < INF and not d.persistent:
				var shut := graph.e_shut[e] - d.s - d.length * 0.5
				if shut < gap:
					gap = shut
					lead_v = 0.0
		if d.halt_e >= 0:
			# The night-buses loop: a bus on its way to a stop (buses.gd).
			var hg := _halt_gap(d, dt)
			if hg < gap:
				gap = hg
				lead_v = 0.0
		if player_on_road:
			var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
			if rel.length_squared() < (1600.0 if d.chase else 900.0):
				var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
				var along := rel.dot(fwd)
				var g := INF
				if racer and not d.chase and d.next_edge >= 0 and (d.in_conn or along > graph.e_s1[e] - d.s):
					# A racer looks along its own way: from the end of its street on, the corridor
					# bends with the junction's curve. The player's car at the mouth of the street
					# opposite is not in the way of a turn; one that turned the corner ahead still is.
					g = _player_gap_in_curve(d)
				elif by_place and not d.chase:
					# Step 4b: on its street the player's car is in a racer's way as any car is
					# (`_race_gap`): by the street's direction and where the two are across it, not
					# by its own nose (askew in a move sideways, it took a car beside it for one in
					# front and the two stood for good). Alongside and clear of it: not in its way;
					# nor with the two bodies PLAYER_IN m into each other after a touch: standing
					# does not part them (each took the other for the car in front, for good), moving
					# on and apart does (`_side_room`).
					var way := graph.direction(e, clampf(d.s, 0.0, graph.e_len[e]))
					var al := rel.dot(way)
					var pl := lat + rel.dot(RaceLine.right(way))
					var half := d.size.x * 0.5 + BESIDE_GAP + PLAYER_WIDE * 0.5
					var lat_to := lat if d.shoulder != 0.0 else lat + side_to - d.off
					if al > 0.0 and pl > minf(lat, lat_to) - half and pl < maxf(lat, lat_to) + half \
							and (al >= (PLAYER_LONG + d.length) * 0.5 or (absf(pl - lat) < (d.size.x + PLAYER_WIDE) * 0.5 - SIDE_RUB \
							and al >= (PLAYER_LONG + d.length) * 0.5 - PLAYER_IN)):
						g = al - d.length * 0.5 - d.keep_gap
				# Loop 3g-1: a chaser looks wider and keeps `keep_gap` behind (it never rams).
				elif along > 0.0 and absf(rel.cross(fwd)) < (4.0 if d.chase else 2.3):
					g = along - d.length * 0.5 - d.keep_gap
				if g < INF:
					player_gap = g
					if g < gap:
						gap = g
						lead_v = maxf(0.0, Vector2(player_vel.x, player_vel.z).dot(fwd))
		if ((cross and gap == d.cross_gap) or gap == out_gap) and d.v < 0.3 and not d.sees_tram:
			d.cross_wait += dt
			if d.cross_wait > (RACE_CROSS_WAIT if racer else 8.0):
				d.cross_ignore = 3.0
				d.cross_wait = 0.0
				_ov_knots += 1
		else:
			d.cross_wait = 0.0
		d.cross_ignore -= dt
	if d.back != BACK_NONE:
		pass  # turning back: no pass, no lane change, no block
	elif racer and d.halt_e < 0:
		_race_overtake(d, leader_gap, player_gap, dt)
		if d.race_block > 0.0:
			_race_block(d, dt)
	elif not d.route.is_empty() and d.halt_e < 0:
		_overtake(d, leader_gap, dt)
	elif not d.ghost and player_gap < 10.0 and player_gap <= gap + 0.01 and d.v < 0.5:
		# The player's car stands in the lane: go round it when the next lane is free.
		var was := d.blocked
		d.blocked += dt
		# Held up for 2 s, and every 10 s after that: the driver loses patience.
		if floori((d.blocked + 8.0) / 10.0) != floori((was + 8.0) / 10.0) and d.kind != Kind.POLICE:
			blocked_by_player.emit(d)
		if d.blocked > 2.5 and _change_lane(d, 14.0):
			d.blocked = 0.0
	elif not d.ghost and lead_parked and leader_gap < PARKED_LOOK and leader_gap <= gap + 0.01 and d.v < 0.5:
		# The crash scenes: a wreck or the scene's car stands in the lane: queue, then go round it
		# when the next lane has room (every waiting car in turn, PARKED_WAIT s after it stopped).
		d.blocked += dt
		if d.blocked > PARKED_WAIT and _change_lane(d, 12.0):
			d.blocked = 0.0
	if d.yield_t > 0.0 and d.route.is_empty() and not d.in_conn and d.lane < graph.e_lanes[e] - 1:
		# Loop 3g-1: over to the kerb lane for the police car behind.
		_change_lane_to(d, graph.e_lanes[e] - 1)
	var dazed := d.daze > 0.0
	if dazed:
		# Shoved off its line: it slides on a little and stays there until it comes round.
		d.daze -= dt
		if d.slide != 0.0 and not d.in_conn:
			# (The band limits the slide. An offset outside it already is left there: a racer that
			# changed lane in the daze of a mistake was put 2.6 m sideways in one frame, race bench.)
			d.off = clampf(d.off + d.slide * dt, minf(d.off, d.off_target - SHOVE_ACROSS), maxf(d.off, d.off_target + SHOVE_ACROSS))
		d.slide = move_toward(d.slide, 0.0, SLIDE_DECEL * dt)
		d.off_v = 0.0
	else:
		d.slide = 0.0
		var to := d.off_target
		if d.pass_t > 0.0 and not d.pass_back:
			to = d.pass_off
		elif d.block_t > 0.0:
			to = d.block_off
		if by_place:
			d.off = _side_step(d, d.off, _side_room(d, lat, side_to), dt)
			d.swerve_now = d.off - to if d.pass_t <= 0.0 and d.block_t <= 0.0 and (d.swerve != 0.0 or d.swerve_now != 0.0) else 0.0
		else:
			d.off = move_toward(d.off, to, (4.0 if racer else 2.5) * dt)
			if d.line == null:
				d.off_v = 0.0  # (on its line through a junction it moves over by `line_dyn`)
	if d.held or d.stun > 0.0 or d.arrived:
		gap = minf(gap, 0.0)
		lead_v = 0.0
		d.stun -= dt

	var ratio := minf(d.v / maxf(v0, 0.1), 2.0)
	var amax := d.race_accel if racer else ACCEL * d.accel_factor
	var a := amax * (1.0 - ratio * ratio * ratio * ratio)
	if gap < INF:
		var head := RACE_HEADWAY if racer else HEADWAY
		var comfy := sqrt(amax * RACE_DECEL) if racer else sqrt(ACCEL * DECEL)
		# (Step 4b: a racer on a street stands RACE_GAP m short, room to steer out; steering out,
		# it closes up.)
		var least := MIN_GAP
		if by_place and not d.ghost and gap == _rg_gap:
			least = RACE_GAP_OUT if absf(side_to - d.off) > 0.3 else RACE_GAP
		var star := least + maxf(0.0, d.v * head + d.v * (d.v - lead_v) / (2.0 * comfy))
		var q := star / maxf(gap, 0.05)
		a -= (amax if racer else ACCEL) * q * q
	if dazed:
		a = minf(a, -DAZE_DECEL)
	if d.back == BACK_STOP:
		# Turning back: on the brakes from where it saw the block, and round where it stops.
		a = minf(a, -(d.race_brake if d.race_brake > 0.0 else RACE_DECEL * 0.7))
	var v_was := d.v
	d.v = maxf(0.0, d.v + maxf(a, -10.0) * dt)
	if racer:
		# Step 6a, for its lights (race_signals.gd): held up behind a slower car, not passing it.
		d.held_up = d.held_up + dt if gap < HELD_GAP and lead_v < v0 - HELD_SLOWER and d.pass_t <= 0.0 and not dazed else 0.0
		d.wrong_t = maxf(d.wrong_t - dt, 0.0)
	if d.line != null and line_v < INF:
		# (The line's speeds fall as fast as the racer brakes; the pull towards a speed lags a
		# falling one, and it would come into the bend too fast.)
		d.v = minf(d.v, maxf(line_v, v_was - maxf(10.0, d.race_brake) * dt))
	if gap < 0.2:
		d.v = minf(d.v, maxf(lead_v, 0.0) * 0.5)
	d.accel_now = (d.v - v_was) / maxf(dt, 0.001)
	if d.back == BACK_STOP and d.v < 0.3 and not d.in_conn:
		d.v = 0.0
		_back_begin(d, minf(leader_gap, player_gap))
	if d.route.is_empty() and not d.held:
		d.still = d.still + dt if d.v < 0.3 else 0.0
	if racer and not d.held and d.v < 1.0:
		d.race_still += dt
		if race_debug and fmod(d.race_still, 1.0) < dt:
			print("race debug: still %.0f s at (%.0f, %.0f) e%d s%.0f/%.0f lanes %d rev %d: leader %.1f player %.1f cross %.1f ign %.1f red %.1f gap %.1f pass %.1f sq %.1f conn %s chase %s" % [d.race_still, d.pos.x, d.pos.z, e, d.s, graph.e_s1[e], graph.e_lanes[e], graph.e_reverse[e], leader_gap, player_gap, d.cross_gap, d.cross_ignore, _red_ahead(d) if not d.in_conn else -1.0, gap, d.pass_t, d.squeeze, d.in_conn, d.chase])

	var step := d.v * dt
	if d.away_debt > 0.0 or d.away_pace < 1.0:
		step *= _away_pace(d, dt)
	# The lane graph's metres the step makes: on a racing line by the line's own way.
	var along := step
	if d.line != null:
		var x := _line_x(d)
		d.line_i = d.line.seek(x, d.line_i)
		# (Beside its line the car's own metres are the step: the line's are more inside a bend.)
		along = d.line.advance(x, d.line_i, step / _line_share(d, d.line_i))
		# (In a junction's curve it comes back to its line, or steers round a car that stands with
		# its side in the way, SWERVE_*.)
		if d.in_conn:
			d.line_dyn = _side_step(d, d.line_dyn, d.swerve, dt)
			d.swerve_now = d.line_dyn if d.swerve != 0.0 else 0.0
		else:
			d.line_dyn = d.off - graph.lane_offset(e, d.lane)
	elif d.in_conn:
		along = step * d.conn_pace
	if d.line_carry != Vector2.ZERO:
		d.line_carry = d.line_carry.move_toward(Vector2.ZERO, LINE_EASE * step)
	if d.line_was != null:
		d.line_blend += step
		if d.line_blend >= LINE_BLEND or d.line_was.xs[d.line_was_q] + d.s >= d.line_was.xl[d.line_was.xl.size() - 1]:
			_line_settle(d)
	if d.in_conn:
		d.cu += along
		# (A U-turn in the street ends across the road at `conn_end`, not at the next road's start.)
		var end_s: float = d.conn_end if d.conn_end >= 0.0 else graph.e_s0[d.next_edge]
		if d.cu >= d.conn_len:
			_enter_edge(d, d.next_edge, d.next_lane, end_s + d.cu - d.conn_len)
			e = d.edge
		else:
			d.ls = end_s - (d.conn_len - d.cu)
	else:
		d.s += along
		# Checked before the junction curve: a fast car can cross the last metres in a frame.
		if not d.route.is_empty() and not d.chase and ((graph.e_b[e] == d.finish and d.s >= graph.e_s1[e] - 3.0) or d.s >= d.end_from):
			d.arrived = true
		if d.next_edge < 0 and d.s + d.length * 0.5 >= graph.e_shut[e] - 1.0:
			# The edge roadworks: at the barriers. A rival or the autopilot takes the off-map link
			# from here (as it did at the map's edge); a town car waits and goes once out of sight
			# (it turned off into the detour).
			if d.persistent:
				if not _through_portal(d):
					teleport(d, e, d.lane, maxf(graph.e_s0[e], graph.e_open[e]))
				return
			if not d.visible and d.v < 0.5:
				_release(d)
				return
		if d.s >= graph.e_s1[e]:
			if d.next_edge >= 0:
				_line_settle(d)
				d.in_conn = true
				d.cu = d.s - graph.e_s1[e]
				_register(d, d.next_reg)
				d.ls = graph.e_s0[d.next_edge] - (d.conn_len - d.cu)
			elif d.s >= graph.e_len[e] + d.length * 0.5:
				# Off the edge of the map.
				if d.persistent:
					if not _through_portal(d):
						teleport(d, e, d.lane, maxf(graph.e_s0[e], graph.e_open[e]))
				else:
					_release(d)
				return
		else:
			d.ls = d.s
	_place(d)


## A persistent driver (a rival, the autopilot) that drove off the map comes back in
## through an off-map link: the one towards its race finish, else any. False if the
## road has none.
func _through_portal(d: Driver) -> bool:
	var links := graph.e_portals[d.edge]
	if links.is_empty():
		return false
	var best := -1
	var best_cost := INF
	for i in links:
		var to := graph.portal_to[i]
		var cost := graph.portal_cost[i] + (graph.e_len[to] + d.route[graph.e_b[to]] if not d.route.is_empty() else _rng.randf() * 100.0)
		if cost < best_cost:
			best_cost = cost
			best = to
	if best < 0:
		return false
	var route := d.route
	var finish := d.finish
	var plan = d.plan
	var run_red := d.run_red
	# The edge roadworks: in past the barriers of the road it comes back on.
	teleport(d, best, mini(d.lane, graph.e_lanes[best] - 1), maxf(graph.e_s0[best], graph.e_open[best] + d.length * 0.5))
	if not route.is_empty():
		race_to(d, finish, route, plan)
		d.run_red = run_red
	return true


## A racer stuck behind slower traffic moves to a freer lane of the same road. If
## there is none it waits, and after a while slips through, but only out of sight.
func _overtake(d: Driver, leader_gap: float, dt: float) -> void:
	d.squeeze -= dt
	if leader_gap > 14.0 or d.in_conn or graph.e_s1[d.edge] - d.s < 18.0:
		d.still = 0.0
		return
	if _change_lane(d, leader_gap + 10.0):
		return
	if d.v < 1.0:
		d.still += dt
		if d.still > 6.0 and not d.visible:
			d.squeeze = 2.5
			d.still = 0.0


## Racer mode: the gap (m) to the player's car along d's own way from the end of its street on:
## the junction curve it takes next (or is in), then RACE_LOOK m along the road it joins; INF when
## the car is not within 2.3 m of that way (the corridor a car on a road looks down, bent along
## the curve). Step 3 of the racer AI rebuild: looking straight ahead, a rival turning right stood
## for the player's car that waited at the mouth of the street opposite, and backed out of a free
## turn; and one behind the player's car lost it at the corner, sped up, and was stopped dead by
## the game on finding it again a metre ahead in the curve.
func _player_gap_in_curve(d: Driver) -> float:
	var pp := Vector2(player_pos.x, player_pos.z)
	var back := d.length * 0.5 + d.keep_gap
	# The metres to the curve's start (still on its street), and how far along the curve it is.
	var before := 0.0 if d.in_conn else maxf(graph.e_s1[d.edge] - d.s, 0.0)
	var t0 := d.cu / d.conn_len if d.in_conn else 0.0
	var rest := d.conn_len * (1.0 - t0)
	# The curve's point nearest the car, of one every 2 m or so (in the curve: from the next on,
	# a car beside or behind is not ahead). A race link's long curve: its next RACE_LOOK m only.
	var span := minf(rest, RACE_LOOK) if RaceCuts.is_link(d.conn) else rest
	var t1 := 1.0 if span >= rest else t0 + span / d.conn_len
	var n := clampi(ceili(span / 2.0), 2, 12)
	var near := 5.29
	var near_t := -1.0
	for k in range(1 if d.in_conn else 0, n + 1):
		var t := lerpf(t0, t1, float(k) / n)
		var dd := LaneGraph.bezier(d.conn, t).distance_squared_to(pp)
		if dd < near:
			near = dd
			near_t = t
	if near_t >= 0.0:
		return before + (near_t - t0) * d.conn_len - back
	if span < rest:
		return INF
	var last := d.conn.size() - 1
	var on := (d.conn[last] - d.conn[last - 1]).normalized()
	var rel := pp - d.conn[last]
	var along := rel.dot(on)
	if along > 0.0 and along < RACE_LOOK and absf(rel.cross(on)) < 2.3:
		return before + rest + along - back
	return INF


## Racer mode: a roll of the racer's own dice (`race_rng`; the traffic's for a driver without).
func _race_roll(d: Driver) -> float:
	return d.race_rng.randf() if d.race_rng != null else _rng.randf()


## The seconds a racer that holds `v` m/s along edge e expects to lose there to the town's
## traffic at `at_density` (RACE_STUCK above). With `caution` a street with no way past counts
## that much more again: the risk a careful racer sees in it (race_planner.gd).
static func race_delay(g: LaneGraph, e: int, v: float, at_density: float, caution := 0.0) -> float:
	if at_density <= 0.0:
		return 0.0
	var share: float = RACE_STUCK[2]
	if g.e_lanes[e] == 1:
		share = RACE_STUCK[1] if g.e_reverse[e] >= 0 else RACE_STUCK[0] * (1.0 + caution)
	var slower := maxf(1.0 / RACE_STUCK_SPEED - 1.0 / maxf(v, 1.0), 0.0)
	return at_density * (share * (g.e_s1[e] - g.e_s0[e]) * slower + RACE_STUCK_END + RACE_STUCK_LIGHTS * (g.e_stops[e].size() / 3))


## The town's traffic as a racer meets it in the band round the view: `density`, less where the
## view holds more road than MAX_CARS cars fill; 0 while no cars are spawning.
func race_density() -> float:
	if not spawning:
		return 0.0
	return minf(density, MAX_CARS / maxf(_slot_weight, 1.0))


## Racer mode: d is out of the band of town cars round the view (AWAY_* above).
func _away(d: Driver) -> bool:
	var l := _local(Vector2(d.pos.x, d.pos.z))
	return absf(l.x) > view_half.x + MARGIN + AWAY_ROOM or absf(l.y) > view_half.y + MARGIN + AWAY_ROOM


## Racer mode, out of the town's cars: the share of its speed d covers ground at this frame, and
## the debt it pays with the rest (none while it stands: a car that is not moving loses nothing
## by covering less ground).
func _away_pace(d: Driver, dt: float) -> float:
	if d.away_debt > 0.0 and not _away(d):
		d.away_debt = 0.0
	d.away_pace = move_toward(d.away_pace, AWAY_TAU / (AWAY_TAU + d.away_debt), AWAY_EASE * dt)
	if d.v > 2.0:
		d.away_debt = maxf(d.away_debt - (1.0 - d.away_pace) * dt, 0.0)
	return d.away_pace


## Racer mode: past slower traffic and the player's car. Start looking RACE_LOOK m back; a free
## lane of the same road first (as _overtake); else, from the lane by the centre line of a road
## with an oncoming one, out over it for a pass (`_pass_start`, driven by `_pass_drive`). Stuck
## still behind someone with no way past for RACE_KNOT_LAST s (a knot of cars in a junction
## box): it slips through.
func _race_overtake(d: Driver, leader_gap: float, player_gap: float, dt: float) -> void:
	d.squeeze -= dt
	d.lane_hold -= dt
	d.pass_wait -= dt
	if d.pass_t > 0.0:
		_pass_drive(d, dt)
		if d.pass_t > 0.0 or d.squeeze > 0.0:
			return
	# A chaser keeps its gap behind the player (it never passes or rams); a rival goes round.
	var ahead := leader_gap if d.chase else minf(leader_gap, player_gap)
	if ahead > RACE_LOOK:
		d.still = 0.0
		d.back_wait = 0.0
		return
	# Any free lane, even close to the junction (a racer slips out of a queue at the lights); in
	# the junction curve itself only the knot rule below (Zbyszek stood 22 s in one).
	if not d.in_conn:
		if d.lane_hold > 0.0 and d.v >= 1.0:
			return  # committed to the lane it has just moved to (stood still in it: look again)
		if _change_lane(d, ahead + 6.0, 4.0 if d.v < 3.0 else 12.0):
			d.lane_hold = RACE_LANE_HOLD
			return
		if _pass_start(d, d.race_block >= BLOCK_TIGHT and player_gap <= leader_gap):
			return
	if d.v < 1.0:
		d.still += dt
		if not d.chase and player_gap < 10.0 and player_gap <= leader_gap and Vector2(player_vel.x, player_vel.z).length_squared() < 1.0:
			# Boxed in behind the player's stopped car (no lane to pass in: both were tried above;
			# the race bench's two races that never finished). The player's car is no knot of cars
			# to slip through; a racer with a plan turns back after BOX_WAIT s of it (in a
			# junction's curve: backwards out of the curve).
			d.still = 0.0
			if d.plan != null and not d.held and d.stun <= 0.0 and not d.arrived:
				if _player_queues(d, player_gap):
					d.back_wait = 0.0  # the player's car waits in a queue: so does the racer
					return
				d.back_wait += dt
				if d.back_wait > (BOX_WAIT if d.in_conn or graph.e_reverse[d.edge] < 0 else BOX_WAIT_PASS):
					d.back_wait = 0.0
					if _curve_back(d) if d.in_conn else _turn_back(d, false):
						return
					if not d.in_conn and d.shoulder == 0.0 and d.pass_t <= 0.0:
						# No way back: round the player's car, on the kerb's side unless it stands there.
						var way := graph.direction(d.edge, clampf(d.s, 0.0, graph.e_len[d.edge]))
						var side := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z).dot(RaceLine.right(way))
						d.shoulder = 1.0 if side <= 0.3 else -1.0
						d.shoulder_t = SHOULDER_MOST
		else:
			d.back_wait = 0.0
		# A knot of cars in a junction box (headless runs: Halina stood 20 s at the start behind
		# a town car that stood too): a racer slips through after RACE_KNOT_LAST s, seen or not.
		# A crazy driver (town traffic, no race to win) never slips through a queue.
		if d.still > RACE_KNOT_LAST and d.crazy == 0:
			d.squeeze = 2.0
			d.cross_ignore = 2.0
			d.still = 0.0


## Racer mode: whether the player's car, standing `player_gap` m in front of racer d, only
## waits itself (QUEUE_GAP above): a car in front of it along d's way, or a light against it.
func _player_queues(d: Driver, player_gap: float) -> bool:
	# (The player's car from d's front: its tail at the gap and d's `keep_gap`, about 4.5 m long.)
	var nose := player_gap + d.keep_gap + 4.5
	if not d.in_conn:
		var red := _red_gap(d)
		if red > nose - 3.0 and red < nose + QUEUE_GAP:
			return true
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	for o in _active:
		if o == d or o.ghost or o.parked or o.clip < 1.0 or absf(o.pos.y - player_pos.y) > 2.5:
			continue
		var rel := Vector2(o.pos.x - player_pos.x, o.pos.z - player_pos.z)
		var along := rel.dot(fwd)
		# (A car going its way, in its lane: not the oncoming one that stands beside it.)
		if along > 1.0 and along < QUEUE_GAP + (o.length + 4.5) * 0.5 and absf(rel.cross(fwd)) < 2.0 \
				and fwd.dot(Vector2(-sin(o.yaw), -cos(o.yaw))) > 0.5:
			return true
	return false


## Step 4b: the place on the ground `ahead` m further along driver d's way: its racing line, or
## its lane's line, the junction's curve and the lane it comes out in.
func _way_at(d: Driver, ahead: float) -> Vector2:
	if d.line != null:
		var x := minf(_line_x(d) + ahead, d.line.xl[d.line.xl.size() - 1])
		var i := d.line.seek(x, d.line_i)
		var p := d.line.point(x, i)
		return p + d.line.side(x, i) * d.line_dyn if d.line_dyn != 0.0 else p
	var e := d.edge
	if not d.in_conn:
		var left := graph.e_s1[e] - d.s
		if ahead <= left or d.next_edge < 0:
			return graph.point_at(e, minf(d.s + ahead, graph.e_len[e]), d.off)
		ahead -= left
	else:
		ahead += d.cu
	if ahead < d.conn_len:
		return LaneGraph.bezier(d.conn, ahead / d.conn_len)
	var f := d.next_edge
	var from: float = d.conn_end if d.conn_end >= 0.0 else graph.e_s0[f]
	return graph.point_at(f, minf(from + ahead - d.conn_len, graph.e_len[f]), graph.lane_offset(f, d.next_lane))


## Step 4b: the metres driver d has before racer r, who stands (heading `r_fwd`), is in its way:
## along d's own way, OUT_WAY stretches of CROSS_STEP m; INF when its way does not go through r.
func _way_gap(d: Driver, r: Driver, r_fwd: Vector2) -> float:
	var was := Vector2(d.pos.x, d.pos.z)
	var at := Vector2(r.pos.x, r.pos.z)
	for k in OUT_WAY:
		var p := _way_at(d, (k + 1) * CROSS_STEP)
		var mid := (was + p) * 0.5
		var dir := (p - was).normalized()
		was = p
		if k == 0 and (at - mid).dot(dir) < -CROSS_STEP * 0.5:
			continue
		if _sat(dir, d.length + CROSS_STEP, d.size.x + 0.6, r_fwd, r.length, r.size.x, at - mid):
			return maxf(k * CROSS_STEP - 1.0, 0.0)
	return INF


## Step 4b: racer d looks for a car that will be in its way at a junction (CROSS_* above): true
## when there is one, with `cross_gap` the metres it has to stop in. A car that stands in its way
## it steers round instead where it can (`swerve`, SWERVE_* above).
func _race_cross(d: Driver) -> bool:
	# (Every other frame: what it saw the frame before stands for one more, a third of a metre
	# at speed. The look is the dearest part of a racer's frame among the town's cars.)
	if (_tick + d.slot) & 1 == 1 and d.look_tick == _tick - 1:
		d.cross_gap = d.look_gap
		if d.look_seen:
			d.cross_v = 0.0
		return d.look_seen
	d.look_seen = _race_cross_look(d)
	d.look_gap = d.cross_gap
	d.look_tick = _tick
	return d.look_seen


## Step 4b: `_race_cross`'s look itself.
func _race_cross_look(d: Driver) -> bool:
	var e := d.edge
	var reach := minf(CROSS_SEE + d.v * CROSS_TIME, CROSS_FAR)
	d.cross_gap = INF
	if not d.in_conn and graph.e_s1[e] - d.s > reach and d.s - graph.e_s0[e] > PATH_EXIT:
		return false
	var here := Vector2(d.pos.x, d.pos.z)
	_rc_near.clear()
	for q in junction_cars:
		if q == d or absf(q.pos.y - d.pos.y) > 2.5:
			continue
		# Racer AI step 6b part 1b, the night club's pack (several racers with plans in one race;
		# never the test player's car, so a race of one is as before): another of them behind it
		# is not a car in its way, nor one still on the street it is turning out of, nor one less
		# far along the same junction's curve (each of those waits for it: who is first goes); one
		# ahead on a shortcut's curve is in its way, also from its own lane (the lane's metres do
		# not reach along a long curve). Before, two of the club onto one shortcut each stood for
		# the other, 0.3 m apart, until the knot rule let them through each other, and the next
		# drove into the one on the curve: 8 to 20 cars driven through at the start of the bench's
		# pack race.
		var mate: bool = d.plan != null and q.plan != null and not q.ghost
		if mate and ((q.pos.x - d.pos.x) * -sin(d.yaw) + (q.pos.z - d.pos.z) * -cos(d.yaw) < 0.0
				or (d.in_conn and not q.in_conn and q.edge == d.edge)
				or (d.in_conn and q.in_conn and d.cu / maxf(d.conn_len, 0.1) > q.cu / maxf(q.conn_len, 0.1))):
			continue
		var curve_ahead: bool = mate and q.on_cut and q.in_conn
		# The cars of its own lanes it follows by the lane (and those beside it on its street it
		# sees by their place); two curves into one lane are side by side until they meet.
		if q.reg == d.reg and not (d.in_conn and q.in_conn and d.lane != q.lane) and not curve_ahead:
			continue
		if not d.in_conn and ((q.reg == d.next_reg and not (q.in_conn and q.edge != e)) or (q.edge == e and not q.in_conn)) and not curve_ahead:
			continue
		var far := reach + q.v * CROSS_TIME + 8.0
		if Vector2(q.pos.x, q.pos.z).distance_squared_to(here) < far * far:
			_rc_near.append(q)
	if _rc_near.is_empty():
		return false
	# Its own way: the middle of each CROSS_STEP m of it, and its heading there.
	_rc_mid.clear()
	_rc_dir.clear()
	var was := here
	var along := CROSS_STEP
	while along <= reach:
		var p := _way_at(d, along)
		_rc_mid.append((was + p) * 0.5)
		_rc_dir.append((p - was).normalized())
		was = p
		along += CROSS_STEP
	var n := _rc_mid.size()
	var pace := maxf(d.v, 4.0)
	# The first stretch of its way a car is in (n: none).
	var first := n
	# How far it has steered aside already (the stretches of its way have moved over with it), how
	# far it may (on a street: within its road; on its line through a junction: SWERVE_CURVE m;
	# not in a pass, not on a junction's curve without a line), and what it has to (m, + to the
	# right) for the cars that stand in its way, from which stretch on.
	var aside := d.swerve_now
	var room_r := 0.0
	var room_l := 0.0
	if d.pass_t <= 0.0:
		if d.in_conn:
			if d.line != null:
				# (On its line through a junction: within the street it comes out in.)
				var f := d.next_edge
				var over := (graph.e_lw[f] - d.size.x) * 0.5 + SWERVE_OVER
				room_r = maxf(graph.lane_offset(f, graph.e_lanes[f] - 1) + over - graph.lane_offset(f, d.next_lane), SWERVE_CURVE)
				room_l = maxf(graph.lane_offset(f, d.next_lane) - graph.lane_offset(f, 0) + over, SWERVE_CURVE)
		else:
			var edge := (graph.e_lw[e] - d.size.x) * 0.5 + SWERVE_OVER
			room_r = maxf(graph.lane_offset(e, graph.e_lanes[e] - 1) + edge - d.off_target, 0.0)
			room_l = maxf(d.off_target - graph.lane_offset(e, 0) + edge, 0.0)
	var swerve := 0.0
	var swerve_from := n
	# Its own body on a stretch: the stretch longer, a margin wider (and the 0.15 m `_sat` lets
	# two bodies overlap).
	var p_long := d.length + CROSS_STEP
	var p_wide := d.size.x + 2.0 * PATH_MARGIN + 0.3
	for q in _rc_near:
		var qf := Vector2(-sin(q.yaw), -cos(q.yaw))
		var qp := Vector2(q.pos.x, q.pos.z)
		var stands := q.v <= 0.5
		# The other car's way, a place every CROSS_STEP m (standing: where it is), and its body
		# there: longer by the metres it makes in CROSS_SLACK s either way.
		_rc_at.clear()
		_rc_at.append(qp)
		if not stands:
			var span := q.v * (reach / pace + CROSS_SLACK) + CROSS_STEP
			var at := CROSS_STEP
			while at < span + CROSS_STEP:
				_rc_at.append(_way_at(q, at))
				at += CROSS_STEP
		var q_long := q.length + 2.0 * q.v * CROSS_SLACK
		for k in mini(first, n):
			var dir := _rc_dir[k]
			var q_at := qp
			var q_dir := qf
			if not stands:
				# Where the other car is when d's middle is on this stretch.
				var gone := q.v * (k + 0.5) * CROSS_STEP / pace / CROSS_STEP
				var j := mini(int(gone), _rc_at.size() - 2)
				q_at = _rc_at[j].lerp(_rc_at[j + 1], clampf(gone - j, 0.0, 1.0))
				if _rc_at[j + 1].distance_squared_to(_rc_at[j]) > 0.01:
					q_dir = (_rc_at[j + 1] - _rc_at[j]).normalized()
			var rel := q_at - _rc_mid[k]
			# (Not a car whose middle it has passed already.)
			if rel.length_squared() > 196.0 or (k == 0 and rel.dot(dir) < -CROSS_STEP * 0.5):
				continue
			var in_way := _sat(dir, p_long, p_wide, q_dir, q_long, q.size.x, rel)
			if stands and (room_r > 0.0 or room_l > 0.0):
				# A car that stands: round it, on the side its middle is not (all across d's way
				# as it would be had it not steered aside yet: it holds the way round until it is
				# past), or where there is more room.
				var right := RaceLine.right(dir)
				if not in_way and (aside == 0.0 or not _sat(dir, p_long, p_wide, q_dir, q_long, q.size.x, rel + right * aside)):
					continue
				var across := -rel.cross(dir) + aside
				var away := -signf(across) if absf(across) > 0.3 else (1.0 if room_r >= room_l else -1.0)
				if swerve != 0.0:
					away = signf(swerve)
				var most := room_r if away > 0.0 else room_l
				var need := 0.0
				var step := maxf(absf(swerve), 0.3)
				while step <= most + 0.01:
					if not _sat(dir, p_long, p_wide, q_dir, q_long, q.size.x, rel - right * (away * step - aside)):
						need = away * step
						break
					step += 0.3
				if need != 0.0:
					swerve = need
					swerve_from = mini(swerve_from, k)
					continue
			if in_way:
				first = k
				break
	if swerve != 0.0:
		# The way round must be free of every car that stands there too, as far as it sees.
		var ok := true
		for q in _rc_near:
			if q.v > 0.5:
				continue
			var qf := Vector2(-sin(q.yaw), -cos(q.yaw))
			var qp := Vector2(q.pos.x, q.pos.z)
			for k in mini(first, n):
				var rel := qp - _rc_mid[k]
				if rel.length_squared() < 196.0 and _sat(_rc_dir[k], p_long, p_wide, qf, q.length, q.size.x, rel - RaceLine.right(_rc_dir[k]) * (swerve - aside)):
					ok = false
					break
			if not ok:
				break
		if ok:
			d.swerve = swerve
			d.swerve_t = SWERVE_HOLD
		else:
			first = mini(first, swerve_from)  # no way round: that car is in its way
	if first >= n:
		return false
	# (Never nearer than a car's brakes can answer: no dead stop for a car seen late.)
	d.cross_gap = maxf(first * CROSS_STEP - d.length * 0.5 - CROSS_KEEP, 0.3)
	d.cross_v = 0.0
	return true


## Step 4b: how far right of edge e's centreline the ground point p lies, taken at station s.
func _lat_at(e: int, s: float, p: Vector2) -> float:
	var at := clampf(s, 0.0, graph.e_len[e])
	var i := graph.seek(e, at, graph.e_first[e])
	return (p - graph.point(e, at, 0.0, i)).dot(RaceLine.right((graph.pts[i + 1] - graph.pts[i]).normalized()))


## Step 4b: where car o of edge e's lanes is across that road (m right of its centreline): a car
## on the lane's rail by its offset, a racer on its line by where it is on the ground.
func _lat_of(o: Driver, e: int) -> float:
	if o.line == null and not o.in_conn and o.edge == e:
		return o.off
	return _lat_at(e, o.ls, Vector2(o.pos.x, o.pos.z))


## Step 4b: the car in racer d's way on its street (`_rg_gap`, `_rg_v`, `_rg_parked`): the nearest
## one ahead in any lane of the road whose body overlaps d's across the road, anywhere from where
## d is (`lat`, m right of the centreline) to where it is moving over to (`lat_to`); and, as soon
## as that reaches over the centre line, the oncoming car it would meet within OUT_MEET s (further
## off, a pass under way has its plan and is not braked for it).
func _race_gap(d: Driver, lat: float, lat_to: float) -> void:
	_rg_gap = INF
	_rg_v = 0.0
	_rg_parked = false
	var e := d.edge
	var half := d.size.x * 0.5 + BESIDE_GAP
	var lo := minf(lat, lat_to) - half
	var hi := maxf(lat, lat_to) + half
	var lane0 := graph.e_lane0[e]
	for k in graph.e_lanes[e]:
		for o: Driver in _lane_cars[lane0 + k]:
			if o == d or o.ls <= d.ls:
				continue
			var g: float = o.ls - d.ls - (o.length + d.length) * 0.5
			if g >= _rg_gap:
				continue
			if o.parked and k == d.lane and d.pass_t <= 0.0:
				pass  # (a wreck that shuts its lane, wherever its body lies)
			else:
				var ol := _lat_of(o, e)
				if ol + o.size.x * 0.5 <= lo or ol - o.size.x * 0.5 >= hi:
					continue
				# (A car alongside, where d is moving over to: not in its way, it cannot move
				# over yet, `_side_room`. Counted, the two stood beside each other for good.)
				if g < 0.0 and absf(ol - lat) >= (d.size.x + o.size.x) * 0.5 - SIDE_RUB:
					continue
			_rg_gap = g
			_rg_v = o.v
			_rg_parked = o.parked
	var rev := graph.e_reverse[e]
	if rev < 0 or lo >= graph.lane_offset(e, 0) - graph.e_lw[e] * 0.5:
		return
	var at := graph.e_len[e] - d.s
	# (Out there with no pass under way, or falling back from one: it brakes in time to stand.)
	var far := 4.0 if d.pass_t > 0.0 and not d.pass_back else 4.0 + d.v * d.v / (2.0 * SPAWN_BRAKE)
	for k in graph.e_lanes[rev]:
		for o: Driver in _lane_cars[graph.e_lane0[rev] + k]:
			var dd: float = at - o.ls
			if dd <= 0.0:
				continue
			var g: float = dd - (o.length + d.length) * 0.5
			if g >= _rg_gap or g > (d.v + o.v) * OUT_MEET + far:
				continue
			var ol := _lat_at(e, graph.e_len[e] - o.ls, Vector2(o.pos.x, o.pos.z))
			if ol + o.size.x * 0.5 <= lo or ol - o.size.x * 0.5 >= hi:
				continue
			_rg_gap = g
			_rg_v = -o.v
			_rg_parked = false


## Step 4b: how far racer d may move over towards offset `to` this frame: not into a car that is
## alongside (within a metre of overlapping it along the road; SIDE_CLEAR m kept between the
## bodies, and away from one that is nearer than that): the cars of its road's lanes, the
## oncoming cars it is about to meet, the player's car. Between two such cars: the middle.
func _side_room(d: Driver, lat: float, to: float) -> float:
	var e := d.edge
	# (Its offset counts from its lane's line; its racing line lies `dev` m beside that.)
	var dev := lat - d.off
	_sr_lo = -INF
	_sr_hi = INF
	var lane0 := graph.e_lane0[e]
	for k in graph.e_lanes[e]:
		for o: Driver in _lane_cars[lane0 + k]:
			if o != d and absf(o.ls - d.ls) < (o.length + d.length) * 0.5 + 1.0:
				_side_limit(d, _lat_of(o, e) - dev, o.size.x)
	var rev := graph.e_reverse[e]
	if rev >= 0 and minf(to, d.off) + dev - d.size.x * 0.5 < graph.lane_offset(e, 0) - graph.e_lw[e] * 0.5:
		var at := graph.e_len[e] - d.s
		for k in graph.e_lanes[rev]:
			for o: Driver in _lane_cars[graph.e_lane0[rev] + k]:
				var dd: float = at - o.ls
				if dd > -(o.length + d.length) * 0.5 - 1.0 and dd < (o.length + d.length) * 0.5 + 1.0 + (d.v + o.v) * 0.4:
					_side_limit(d, _lat_at(e, graph.e_len[e] - o.ls, Vector2(o.pos.x, o.pos.z)) - dev, o.size.x)
	if player_on_road and not d.ghost:
		var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
		if rel.length_squared() < 100.0:
			var way := graph.direction(e, minf(d.s, graph.e_len[e]))
			if absf(rel.dot(way)) < (PLAYER_LONG + d.length) * 0.5 + 1.0:
				_side_limit(d, d.off + rel.dot(RaceLine.right(way)), PLAYER_WIDE)
	if _sr_lo > _sr_hi:
		return (_sr_lo + _sr_hi) * 0.5
	return clampf(to, _sr_lo, _sr_hi)


## Step 4b: a car `wide` m wide alongside racer d at offset `at` bounds how far d may be to that
## side (`_sr_lo`, `_sr_hi`): SIDE_CLEAR m between the bodies.
func _side_limit(d: Driver, at: float, wide: float) -> void:
	var room := (d.size.x + wide) * 0.5 + SIDE_CLEAR
	if at >= d.off:
		_sr_hi = minf(_sr_hi, at - room)
	else:
		_sr_lo = maxf(_sr_lo, at + room)


## Step 4b: racer d moves over from `at` towards `to` (m across its way) as a car does (SIDE_*
## above): its sideways speed builds up at SIDE_ACCEL m/s² and falls off again in time to end at
## `to`. Returns where it is after this frame.
func _side_step(d: Driver, at: float, to: float, dt: float) -> float:
	var err := to - at
	if absf(err) < 0.005 and absf(d.off_v) < SIDE_ACCEL * dt * 2.0:
		d.off_v = 0.0
		return to
	var most := minf(SIDE_SPEED, SIDE_SLOPE * d.v)
	if d.shoulder != 0.0:
		most = maxf(most, SHOULDER_SIDE)
	# (The speed it can still stop from at `to`, with a little in hand for the frame's step.)
	var want := signf(err) * minf(most, sqrt(1.6 * SIDE_ACCEL * absf(err)))
	d.off_v = move_toward(d.off_v, want, SIDE_ACCEL * dt)
	var step := d.off_v * dt
	if step * err > 0.0 and absf(step) >= absf(err):
		d.off_v = 0.0
		return to
	return at + step


## Step 4b: the speed racer d would drive its street at with nobody in its way (m/s).
func _race_top(d: Driver) -> float:
	var e := d.edge
	if d.v_cap > 0.0:
		return d.v_cap
	if d.race_top <= 0.0:
		return graph.e_speed[e] * d.speed_factor
	var top := minf(d.race_top, RACE_CLASS_TOP[graph.e_class[e]]) * d.race_share * d.race_effort
	if d.crazy > 0:
		top = minf(top, graph.e_speed[e] * CRAZY_OVER[d.crazy])
	return top


## Step 4b: the cars a pass by racer d has to do with (`_pl_rear`, `_pl_front`, `_pl_v`, in order
## along the lane): those of its street's lane by the centre line whose nose is beyond station
## `from` of that lane, and the player's car when it is in that lane (a chaser's quarry is not a
## car to pass).
func _pass_cars(d: Driver, from: float) -> void:
	_pl_rear.clear()
	_pl_front.clear()
	_pl_v.clear()
	var e := d.edge
	for o: Driver in _lane_cars[graph.e_lane0[e]]:
		if o != d and o.ls + o.length * 0.5 > from:
			_pass_add(o.ls - o.length * 0.5, o.ls + o.length * 0.5, o.v)
	if player_on_road and not d.ghost and not d.chase:
		var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
		if rel.length_squared() < 3600.0 and absf(player_pos.y - d.pos.y) < 2.5:
			var way := graph.direction(e, minf(d.s, graph.e_len[e]))
			var at := d.ls + rel.dot(way)
			if at + PLAYER_LONG * 0.5 > from and absf(_lat_at(e, d.s + rel.dot(way), Vector2(player_pos.x, player_pos.z)) - graph.lane_offset(e, 0)) < graph.e_lw[e] * 0.5 + 0.5:
				_pass_add(at - PLAYER_LONG * 0.5, at + PLAYER_LONG * 0.5, maxf(0.0, Vector2(player_vel.x, player_vel.z).dot(way)))


func _pass_add(rear: float, front: float, v: float) -> void:
	var i := _pl_rear.size()
	_pl_rear.append(rear)
	_pl_front.append(front)
	_pl_v.append(v)
	while i > 0 and _pl_rear[i - 1] > rear:
		_pl_rear[i] = _pl_rear[i - 1]
		_pl_front[i] = _pl_front[i - 1]
		_pl_v[i] = _pl_v[i - 1]
		i -= 1
	_pl_rear[i] = rear
	_pl_front[i] = front
	_pl_v[i] = v


## Step 4b: whether racer d's way on turns right at the end of its street (across the front of
## the cars it would have passed on their left).
func _turns_right(d: Driver) -> bool:
	if d.next_edge < 0:
		return false
	var a := graph.direction(d.edge, graph.e_s1[d.edge])
	var b := graph.direction(d.next_edge, graph.e_s0[d.next_edge])
	return b.dot(RaceLine.right(a)) > 0.3


## Step 4b: whether racer d may pass a row of cars (the fastest at `slowest` m/s) all the way to
## the junction: a standing queue, by a racer on a line that runs the lights and does not turn
## right there across the queue's front.
func _pass_to_end(d: Driver, slowest: float) -> bool:
	return d.line != null and d.run_red and slowest <= PASS_QUEUE and d.next_edge >= 0 and not _turns_right(d)


## Step 4b: the pass racer d would make from here by the cars of `_pass_cars` (PASS_* above): the
## metres (`_pp_x`) and seconds (`_pp_t`) until its tail is PASS_IN m (cutting in: PASS_IN_TIGHT)
## past the nose of the last car of the row in front of it, the row ending at the first gap long
## enough to come back into. It speeds up by its own pull to the street's speed and no faster
## than its line allows on the way. False when there is no such pass: longer than PASS_MOST s, a
## bend of its line in it, or the junction first; but a standing queue up to the junction is
## passed to the junction (the whole street left), by a racer on a line that runs the lights and
## does not turn right there.
func _pass_plan(d: Driver, tight: bool) -> bool:
	var n := _pl_rear.size()
	if n == 0:
		return false
	var e := d.edge
	var i := 0
	var slowest := _pl_v[0]
	while i + 1 < n and _pl_rear[i + 1] - _pl_front[i] < PASS_SLOT + 0.5 * maxf(d.v - _pl_v[i + 1], 0.0):
		i += 1
		slowest = maxf(slowest, _pl_v[i])
	var u := _pl_v[i]
	var need := _pl_front[i] + (PASS_IN_TIGHT if tight else PASS_IN) - (d.ls - d.length * 0.5)
	var left := graph.e_s1[e] - d.s
	var top := _race_top(d)
	var v := d.v
	var rel := 0.0
	var x := 0.0
	var t := 0.0
	var li := d.line_i
	var lx := _line_x(d) if d.line != null else 0.0
	var to_end := false
	var bend := false
	while true:
		if not to_end and rel >= need:
			if not bend:
				break
			# (Past the row inside the junction's own bend: on to the junction, if it may.)
			if not _pass_to_end(d, slowest):
				return false
			to_end = true
		if to_end and x >= left:
			break
		if t >= PASS_MOST:
			return false
		v = minf(v + d.race_accel * (1.0 - pow(minf(v / maxf(top, 0.1), 1.0), 4.0)) * PASS_STEP, top)
		if d.line != null and lx + x < d.line.xl[d.line.xl.size() - 1]:
			li = d.line.seek(lx + x, li)
			v = minf(v, maxf(d.line.speed(lx + x, li), 1.0))
			# (A bend of its line on the way: no pass, but for a queue passed to the junction,
			# where the bend is the junction's own and the line's speed there is kept.)
			if x < left and v * v * maxf(d.line.turn[li], d.line.turn[li + 1]) / RaceLine.RUN > LINE_BUSY * d.line_grip:
				bend = true
		rel += (v - u) * PASS_STEP
		x += v * PASS_STEP
		t += PASS_STEP
		if not to_end and x > left - PASS_END:
			if not _pass_to_end(d, slowest):
				return false
			to_end = true
	_pp_x = minf(x, left) if to_end else x
	_pp_t = t
	return true


## Step 4b: whether the oncoming lanes a pass by racer d is driven in are clear for the x m and
## t s it takes: no oncoming car nearer than those metres, the metres it comes itself meanwhile
## and while d moves back over (RACE_PASS_BACK s), and `margin` m. A careful racer (`race_dare`
## over 1) counts the oncoming car's metres that many times over, so it waits for a longer gap;
## a daring one gets no discount on them, because the gap it needs is physics, not nerve.
func _oncoming_clear(d: Driver, x: float, t: float, margin: float) -> bool:
	var care := maxf(d.race_dare, 1.0)
	var e := d.edge
	var rev := graph.e_reverse[e]
	var at := graph.e_len[e] - d.s
	var mind := _pass_lanes(e, rev, d.s, graph.lane_offset(e, 0) - graph.e_lw[e] * 0.9)
	for k in graph.e_lanes[rev]:
		if mind[k] == 0:
			continue
		for o: Driver in _lane_cars[graph.e_lane0[rev] + k]:
			var dd: float = at - o.ls
			if dd > -8.0 and dd - (o.length + d.length) * 0.5 < x + o.v * (t + RACE_PASS_BACK) * care + margin:
				return false
	return true


## Step 4b: racer d goes out over the centre line for a pass, if it is behind a slower car in the
## lane by the centre line, near enough that it is out as it gets there, the pass can be made
## (`_pass_plan`) and the oncoming lane is clear for it (`_oncoming_clear`).
func _pass_start(d: Driver, tight: bool) -> bool:
	var e := d.edge
	if d.lane != 0 or d.pass_wait > 0.0 or graph.e_reverse[e] < 0 or graph.e_s1[e] - d.s < PASS_LEAST or _line_busy(d):
		return false
	var front := d.ls + d.length * 0.5
	_pass_cars(d, front - 0.5)
	if _pl_rear.is_empty() or _pl_v[0] > _race_top(d) - 2.0:
		return false
	if _pl_rear[0] - front > maxf(d.v + 10.0, (d.v - _pl_v[0]) * 2.5 + 6.0):
		return false
	if not _pass_plan(d, tight) or not _oncoming_clear(d, _pp_x, _pp_t, PASS_MARGIN * d.race_dare):
		return false
	d.pass_t = _pp_t
	d.pass_off = graph.lane_offset(e, 0) - graph.e_lw[e] * 0.9
	d.pass_tight = tight
	d.pass_by = false
	d.pass_back = false
	d.pass_cap = INF
	d.race_passes += 1
	return true


## Step 4b: a frame of racer d's pass (PASS_* above): back into its lane when there is room before
## the next car; on past the next car too while the plan from here holds; given up when it does
## not.
func _pass_drive(d: Driver, dt: float) -> void:
	if d.in_conn:
		_pass_end(d, 0.0)  # (the junction's curve brings it back to its lane)
		return
	if d.v < 1.0:
		# Standing out there (it gave the pass up beside a queue that stands): the last resort.
		d.still += dt
		if d.still > RACE_KNOT_LAST and d.crazy == 0:
			_pass_end(d, 0.0)
			d.squeeze = 2.0
			d.cross_ignore = 2.0
			d.still = 0.0
			return
	else:
		d.still = 0.0
	var e := d.edge
	var rear := d.ls - d.length * 0.5
	var front := d.ls + d.length * 0.5
	_pass_cars(d, rear - (PASS_IN_TIGHT if d.pass_tight else PASS_IN))
	if _pl_rear.is_empty():
		_pass_end(d, 0.0)
		return
	var room := _pl_rear[0] - front
	if room < 1.0:
		d.pass_by = true
	elif d.pass_by and room > clampf((d.v - _pl_v[0]) * 1.2, 4.0, 30.0):
		_pass_end(d, 0.0)  # past a car, and room before the next one: back in
		return
	# A racer without a line has no way through the junction beside its lane: back in before it.
	if (d.line != null or graph.e_s1[e] - d.s > 12.0) and _pass_plan(d, d.pass_tight) and _oncoming_clear(d, _pp_x, _pp_t, PASS_KEEP * d.race_dare):
		d.pass_t = maxf(_pp_t, 0.05)
		d.pass_cap = INF
		d.pass_back = false
		return
	# Given up.
	d.pass_t = 0.05
	if room >= 1.0:
		_pass_end(d, PASS_WAIT)  # behind that car: back in behind it
	elif rear > (_pl_rear[0] + _pl_front[0]) * 0.5 - 1.0:
		# Its tail is past that car's middle: on past this one car, no faster than the next.
		d.pass_cap = maxf(_pl_v[1], _pl_v[0] + 2.0) if _pl_rear.size() > 1 and _pl_rear[1] - front < 12.0 else INF
	else:
		d.pass_cap = maxf(_pl_v[0] - PASS_FALL, 0.0)
		d.pass_back = true


func _pass_end(d: Driver, wait: float) -> void:
	d.pass_t = 0.0
	d.pass_back = false
	d.pass_cap = INF
	d.pass_wait = wait


## Racer mode: the lanes of the oncoming road `rev` that a pass over the centre line of edge e
## minds at station s (1 each), driven `out` m beside e's line: those whose own line lies within
## RACE_PASS_BESIDE m of the pass's. Every lane where none does: the oncoming road is no
## neighbour there (another carriageway between the same two junctions), and the rule is as it
## was.
func _pass_lanes(e: int, rev: int, s: float, out: float) -> PackedByteArray:
	var n := graph.e_lanes[rev]
	var mind := PackedByteArray()
	mind.resize(n)
	if n > 1:
		var here := graph.point_at(e, s, out)
		var across := RaceLine.right(graph.direction(e, s))
		var at := graph.e_len[e] - s
		var any := false
		for k in n:
			if absf((graph.point_at(rev, at, graph.lane_offset(rev, k)) - here).dot(across)) < RACE_PASS_BESIDE:
				mind[k] = 1
				any = true
		if any:
			return mind
	mind.fill(1)
	return mind


## Moves to the neighbouring lane with the most room ahead (more than `room`
## metres, nobody alongside), if the road has one. The car slides across.
func _change_lane(d: Driver, room_needed: float, near := 18.0) -> bool:
	var e := d.edge
	if d.in_conn or graph.e_s1[e] - d.s < near or _line_busy(d):
		return false
	var best := -1
	var best_room := room_needed
	for k in [d.lane - 1, d.lane + 1]:
		if k < 0 or k >= graph.e_lanes[e]:
			continue
		var room := 60.0
		for o in _lane_cars[graph.e_lane0[e] + k]:
			if o != d and o.ls > d.ls - (o.length + d.length) * 0.5 - 4.0:
				room = minf(room, o.ls - d.ls - (o.length + d.length) * 0.5)
		if room > best_room:
			best_room = room
			best = k
	if best < 0:
		return false
	d.lane = best
	if not d.ghost:
		_register(d, graph.e_lane0[e] + best)
	d.off_target = graph.lane_offset(e, best)
	_choose_next(d)
	return true


# --- turning back at a blocked street (BACK_* above) ---------------------------------------------

## Turning back: a parked car stands within WALL_SPAN m of s in lane `lane_id`.
func _parked_at(lane_id: int, s: float) -> bool:
	for o in _lane_cars[lane_id]:
		if o.parked and absf(o.ls - s) < WALL_SPAN:
			return true
	return false


## Turning back: whether the road is walled at s on edge e: a parked car there in every lane of
## e and of the oncoming road (a wreck that leaves a lane or the oncoming side free is passed).
func _walled(e: int, s: float) -> bool:
	for k in graph.e_lanes[e]:
		if not _parked_at(graph.e_lane0[e] + k, s):
			return false
	var rev := graph.e_reverse[e]
	if rev >= 0:
		for k in graph.e_lanes[rev]:
			if not _parked_at(graph.e_lane0[rev] + k, graph.e_len[e] - s):
				return false
	return true


## Turning back: racer d has found its street blocked (`both`: the oncoming road as well, a
## wall): its plan shuts the street and searches again, and it stops to turn round. False when
## it has turned back here before (a wall: the knot rule takes it through; boxed by the player's
## car: after BACK_TRIES turns in the race).
func _turn_back(d: Driver, both: bool) -> bool:
	var e := d.edge
	var rev := graph.e_reverse[e]
	var shut := PackedInt32Array([e])
	if both and rev >= 0:
		shut.append(rev)
	var news: bool = d.plan.block(shut)
	if not news and (both or d.turns_back >= BACK_TRIES):
		return false
	d.back = BACK_STOP
	d.back_wait = 0.0
	d.back_v = 0.0
	d.squeeze = 0.0
	d.pass_t = 0.0
	d.block_t = 0.0
	d.plan_edge = -1
	d.wrong_edge = -1
	_way_clear(d)
	_line_drop(d)
	d.turns_back += 1
	# Where it comes out: on the oncoming road, or (a one-way street) on the road it came by; else
	# the road into the junction behind that lines up best with this one.
	d.back_edge = rev
	d.back_lane = 0
	if rev < 0:
		if d.prev_edge >= 0 and d.prev_edge != e and graph.e_b[d.prev_edge] == graph.e_a[e]:
			d.back_edge = d.prev_edge
			d.back_lane = clampi(d.prev_lane, 0, graph.e_lanes[d.prev_edge] - 1)
		else:
			var best_dot := -2.0
			var here := graph.direction(e, graph.e_s0[e])
			for f in graph.node_in[graph.e_a[e]]:
				var dot := here.dot(graph.direction(f, graph.e_s1[f]))
				if f != e and dot > best_dot:
					best_dot = dot
					d.back_edge = f
					d.back_lane = mini(d.lane, graph.e_lanes[f] - 1)
	if news:
		turned_back.emit(d)
	return true


## Turning back in a junction's curve: racer d, boxed in there behind the player's car, backs
## out of the curve onto the road it came by, and its plan shuts the street it was turning into.
## False after BACK_TRIES turns in the race.
func _curve_back(d: Driver) -> bool:
	if d.next_edge < 0 or d.conn_end >= 0.0:
		return false
	var news: bool = d.plan.block(PackedInt32Array([d.next_edge]))
	if not news and d.turns_back >= BACK_TRIES:
		return false
	d.back = BACK_CURVE
	d.back_edge = d.edge
	d.back_lane = d.lane
	d.back_wait = 0.0
	d.back_v = 0.0
	d.squeeze = 0.0
	d.pass_t = 0.0
	d.mistake_side = 0.0
	d.plan_edge = -1
	d.wrong_edge = -1
	_way_clear(d)
	_line_drop(d)
	d.turns_back += 1
	if news:
		turned_back.emit(d)
	return true


## Turning back: stopped for the block, `room` m short of it. On a street with an oncoming road
## it turns round where it stands (backing up first when it stands nearer than BACK_GAP m); on a
## one-way street it backs out to the junction behind.
func _back_begin(d: Driver, room: float) -> void:
	d.back_wait = 0.0
	d.back_v = 0.0
	if graph.e_reverse[d.edge] < 0:
		d.back = BACK_OUT
		return
	d.back = BACK_ROOM
	d.back_to = d.s
	if room < BACK_GAP - 0.5:
		d.back_to = maxf(d.s - (BACK_GAP - room), minf(d.s, graph.e_s0[d.edge] + 1.0))


## Turning back: gives the manoeuvre up (no room behind, the oncoming lane never free): it
## stands where it is and the old rule takes over (RACE_KNOT_LAST).
func _back_give_up(d: Driver) -> void:
	d.back = BACK_NONE
	d.back_v = 0.0
	d.back_wait = 0.0
	d.still = 0.0


## Turning back: the room behind d to back into ([m, who]: up to BACK_CLEAR m from the nearest
## car behind it (who 1) or from the player's car behind it (who 2)). A car behind it is one in
## its lane (in a junction's curve: also at the end of the road it backs onto), or any car that
## stands or drives within BACK_NEAR m in the way of its tail, whatever lane that one is in (a
## car crossing the junction, the rival behind the bench's test player).
func _room_behind(d: Driver) -> Vector2:
	var behind := INF
	var who := 1.0
	var lane_id: int = d.next_reg if d.in_conn else graph.e_lane0[d.edge] + d.lane
	for o in _lane_cars[lane_id]:
		if o != d and o.ls <= d.ls:
			behind = minf(behind, d.ls - o.ls - (o.length + d.length) * 0.5)
	if d.in_conn and d.back_edge >= 0:
		var f := d.back_edge
		for o in _lane_cars[graph.e_lane0[f] + d.back_lane]:
			if o != d:
				behind = minf(behind, d.cu + graph.e_s1[f] - o.ls - (o.length + d.length) * 0.5)
	var here := Vector2(d.pos.x, d.pos.z)
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	for o in _active:
		if o == d or o.ghost or o.clip < 1.0:
			continue
		var rel := Vector2(o.pos.x - here.x, o.pos.z - here.y)
		if rel.length_squared() > BACK_NEAR * BACK_NEAR or absf(o.pos.y - d.pos.y) > 2.5:
			continue
		var along := -rel.dot(fwd)
		if along > 0.0 and absf(rel.cross(fwd)) < (o.size.x + d.size.x) * 0.5 + 0.5:
			behind = minf(behind, along - (o.length + d.length) * 0.5)
	if player_on_road and not d.ghost:
		var rel := Vector2(player_pos.x - here.x, player_pos.z - here.y)
		var along := -rel.dot(fwd)
		if along > 0.0 and absf(rel.cross(fwd)) < 2.3 and along - d.length * 0.5 - d.keep_gap < behind:
			behind = along - d.length * 0.5 - d.keep_gap
			who = 2.0
	return Vector2(behind - BACK_CLEAR, who)


## Turning back: whether a car still has to come out of the street `left` that d has just backed
## out of (it stands at the end of the road behind, its nose to the junction): a car backing out
## of that street, or the player's car slow (or backing) within YIELD_SEE m in front of its nose.
func _coming_out(d: Driver, left: int) -> bool:
	if left >= 0:
		for k in graph.e_lanes[left]:
			for o in _lane_cars[graph.e_lane0[left] + k]:
				if o != d and (o.back == BACK_OUT or o.back == BACK_CURVE):
					return true
	if player_on_road and not d.ghost:
		var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
		var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
		var along := rel.dot(fwd)
		return along > 0.0 and along < YIELD_SEE + d.length * 0.5 and absf(rel.cross(fwd)) < 4.0 \
				and Vector2(player_vel.x, player_vel.z).dot(fwd) < 2.0
	return false


## Turning back: whether d's body anywhere along `curve` meets a car that is there now (any
## car: one crossing the junction, one standing at the end of the road behind) or the player's car.
func _curve_free(d: Driver, curve: PackedVector2Array) -> bool:
	if _player_in(d, curve):
		return false
	var mid := LaneGraph.bezier(curve, 0.5)
	var reach := curve[0].distance_to(curve[3]) * 0.5 + BACK_NEAR
	for o in _active:
		if o == d or o.ghost or o.clip < 1.0 or absf(o.pos.y - d.pos.y) > 2.5:
			continue
		var at := Vector2(o.pos.x, o.pos.z)
		if at.distance_squared_to(mid) > reach * reach:
			continue
		var near := (o.length + d.length) * 0.5 + 1.0
		for k in 9:
			if at.distance_squared_to(LaneGraph.bezier(curve, k / 8.0)) < near * near:
				return false
	return true


## Turning back: one frame of backing up along its lane towards `to` (its s there), ending at
## `v_end` m/s. 0: backing; 1: a car stands close behind it; 2: the player's car does (it waits
## for that one as long as it takes: it gives up for a queue, never to drive through a wall in
## front of the player who boxed it in).
func _back_along(d: Driver, dt: float, to: float, v_end: float) -> int:
	var free := _room_behind(d)
	var room := minf(free.x, d.s - to)
	if room <= 0.0:
		d.back_v = 0.0
		return int(free.y) if free.x <= 0.0 else 1
	var brake := d.race_brake if d.race_brake > 0.0 else RACE_DECEL * 0.7
	# (The player's car backs up at 0.6 of its pull, car.gd.)
	d.back_v = minf(minf(d.back_v + maxf(d.race_accel, ACCEL) * 0.6 * dt, BACK_SPEED), sqrt(v_end * v_end + 2.0 * brake * room))
	d.s -= minf(d.back_v * dt, room)
	d.ls = d.s
	return 0


## Turning back: whether the player's car (a disc of its half diagonal) lies in the way of d's
## body anywhere along `curve`.
func _player_in(d: Driver, curve: PackedVector2Array) -> bool:
	if not player_on_road or d.ghost:
		return false
	var pp := Vector2(player_pos.x, player_pos.z)
	if pp.distance_squared_to(curve[0]) > 900.0:
		return false
	var prev := curve[0]
	for k in range(1, 9):
		var q := LaneGraph.bezier(curve, k / 8.0)
		var fwd := (q - prev).normalized()
		var rel := pp - q
		var dx := maxf(absf(rel.dot(fwd)) - d.length * 0.5, 0.0)
		var dy := maxf(absf(rel.cross(fwd)) - d.size.x * 0.5, 0.0)
		if dx * dx + dy * dy < 2.4 * 2.4:
			return true
		prev = q
	return false


## Turning back: starts the U-turn in the street, from where it stands across to the oncoming
## road's nearest lane. False while a car is in that lane there (or coming: 2 s of its speed),
## beside it in a lane it has to cross, or the player's car is in the way.
func _u_turn(d: Driver) -> bool:
	var e := d.edge
	var rev := graph.e_reverse[e]
	var to_s := clampf(graph.e_len[e] - d.s, graph.e_s0[rev] + 0.5, maxf(graph.e_s1[rev] - 1.0, graph.e_s0[rev] + 0.5))
	for o in _lane_cars[graph.e_lane0[rev]]:
		var rel: float = o.ls - to_s
		var room: float = (o.length + d.length) * 0.5
		if rel < room + 2.0 and rel > -(room + 1.0 + o.v * 2.0):
			return false
	for k in d.lane:
		for o in _lane_cars[graph.e_lane0[e] + k]:
			if absf(o.ls - d.s) < (o.length + d.length) * 0.5 + 3.0:
				return false
	var p0 := graph.point_at(e, d.s, d.off)
	var d0 := graph.direction(e, d.s)
	var p3 := graph.point_at(rev, to_s, graph.lane_offset(rev, 0))
	var d3 := graph.direction(rev, to_s)
	var reach := maxf(absf((p3 - p0).cross(d0)) * 0.6, 3.0)
	var curve := PackedVector2Array([p0, p0 + d0 * reach, p3 - d3 * reach, p3])
	if _player_in(d, curve):
		return false
	d.conn = curve
	d.conn_len = LaneGraph.bezier_length(curve)
	d.conn_pace = 1.0
	d.conn_y0 = graph.height(e, d.s)
	d.conn_y1 = graph.height(rev, to_s)
	d.conn_end = to_s
	d.next_edge = rev
	d.next_lane = 0
	d.next_reg = graph.e_lane0[rev]
	d.v_turn = BACK_TURN
	d.in_conn = true
	d.cu = 0.0
	_register(d, d.next_reg)
	d.ls = to_s - d.conn_len
	d.back = BACK_UTURN
	d.back_v = 0.0
	d.on_cut = false
	d.mistake_side = 0.0
	return true


## Turning back: the frames in which racer d backs up for room and waits for the oncoming lane
## (BACK_ROOM), backs out of a one-way street (BACK_OUT) and goes backwards through the
## junction's curve onto the road behind (BACK_CURVE). `v` stays 0 throughout: to the cars round
## it a car that backs is a car that stands; `back_v` is its speed backwards.
func _drive_back(d: Driver, dt: float) -> void:
	d.v = 0.0
	var e := d.edge
	if d.line != null:
		# (Backwards it drives the lane graph's way: a racing line knows only the way on. One
		# was begun where it came out of the curve backwards, before it made room: BACK_YIELD.)
		_way_clear(d)
		_line_drop(d)
	if not d.in_conn:
		d.off = move_toward(d.off, d.off_target, 2.5 * dt)
	if d.held or d.arrived or d.daze > 0.0 or d.stun > 0.0:
		d.daze -= dt
		d.stun -= dt
		d.back_v = 0.0
	elif d.back == BACK_ROOM:
		if d.s > d.back_to + 0.05:
			if _back_along(d, dt, d.back_to, 0.0) == 0:
				d.back_wait = 0.0
			else:
				# Somebody close behind: it turns in the room it has.
				d.back_wait += dt
				if d.back_wait > 1.0:
					d.back_to = d.s
					d.back_wait = 0.0
		else:
			d.back_v = 0.0
			if not _u_turn(d):
				d.back_wait += dt
				if d.back_wait > BACK_GIVE_UP:
					_back_give_up(d)
	elif d.back == BACK_OUT:
		if d.s > graph.e_s0[e] + 0.05:
			var stuck := _back_along(d, dt, graph.e_s0[e], BACK_TURN)
			d.back_wait = d.back_wait + dt if stuck == 1 else 0.0
			if d.back_wait > BACK_GIVE_UP:
				_back_give_up(d)
		else:
			# At the junction's mouth: backwards through the curve onto the road behind, when that
			# road's end is free.
			var f := d.back_edge
			var free := f >= 0
			var curve := PackedVector2Array()
			if free:
				for o in _lane_cars[graph.e_lane0[f] + d.back_lane]:
					if o.ls > graph.e_s1[f] - (o.length + d.length) * 0.5 - BACK_CLEAR - o.v * 2.0:
						free = false
						break
			if free:
				curve = graph.connector(f, d.back_lane, e, d.lane)
				free = _curve_free(d, curve)
			if free:
				d.conn = curve
				d.conn_len = LaneGraph.bezier_length(d.conn)
				d.conn_pace = 1.0
				d.conn_y0 = graph.height(f, graph.e_s1[f])
				d.conn_y1 = graph.height(e, graph.e_s0[e])
				d.next_edge = e
				d.next_lane = d.lane
				d.next_reg = graph.e_lane0[e] + d.lane
				d.in_conn = true
				d.cu = d.conn_len
				d.back = BACK_CURVE
				d.back_wait = 0.0
			else:
				d.back_v = 0.0
				d.back_wait += dt
				if d.back_wait > BACK_GIVE_UP:
					_back_give_up(d)
	elif d.back == BACK_CURVE:
		var free := _room_behind(d)
		if free.x <= 0.0:
			# Somebody at the end of the road behind, or the player's car: it waits in the curve;
			# for a queue not for ever (it drives on in again, and the old rule is left).
			d.back_v = 0.0
			d.back_wait = d.back_wait + dt if free.y < 2.0 else 0.0
			if d.back_wait > BACK_GIVE_UP:
				_back_give_up(d)
		else:
			d.back_wait = 0.0
			d.back_v = minf(minf(d.back_v + maxf(d.race_accel, ACCEL) * 0.6 * dt, BACK_TURN), sqrt(2.0 * RACE_DECEL * free.x) + 0.3)
			d.cu -= d.back_v * dt
			if d.cu <= 0.0:
				# Out on the road behind, at its end: the new way on from there; first room for a
				# car that still has to come out after it.
				d.cu = 0.0
				_place(d)
				var left := d.next_edge
				d.in_conn = false
				_enter_edge(d, d.back_edge, d.back_lane, graph.e_s1[d.back_edge] - 0.1)
				if _coming_out(d, left):
					d.back = BACK_YIELD
					d.back_edge = left
					d.back_to = maxf(d.s - YIELD_ROOM, minf(d.s, graph.e_s0[d.edge] + 1.0))
				return
			d.ls = graph.e_s0[d.next_edge] - (d.conn_len - d.cu)
	elif d.back == BACK_YIELD:
		if d.s > d.back_to + 0.05 and d.back_wait < 1.0:
			# (Somebody close behind: it holds in the room it has.)
			d.back_wait = d.back_wait + dt if _back_along(d, dt, d.back_to, 0.0) != 0 else 0.0
		else:
			d.back_v = 0.0
			d.back_wait += dt
			if d.back_wait > YIELD_WAIT or not _coming_out(d, d.back_edge):
				d.back = BACK_NONE
				d.back_wait = 0.0
				_line_sync(d)
	_place(d)


## Cars at a junction give way to a tram in their path: where the car's way meets each tram car's
## line, if the tram car's body (or the front car's next TRAM_LOOK s) is there, the car stops with
## its box TRAM_MARGIN m from the tram's side, whatever the angle it crosses at.
func _give_way_to_trams() -> void:
	# Each visible tram car once: centre and axis (gathered first; reading node
	# transforms inside the loop below would cost far more than the maths).
	_tram_at.clear()
	_tram_axis.clear()
	_tram_ahead.clear()
	_tram_front.clear()
	for tram in trams.trams:
		for k in tram.cars.size():
			var body: AnimatableBody3D = tram.cars[k]
			if body.visible:
				var t: Transform3D = body.global_transform
				_tram_at.append(Vector2(t.origin.x, t.origin.z))
				# Forward: the cars' -Z faces the way the tram goes.
				_tram_axis.append(-Vector2(t.basis.z.x, t.basis.z.z).normalized())
				_tram_ahead.append(tram.v * TRAM_LOOK if k == 0 else 0.0)
				_tram_front.append(1 if k == 0 else 0)
	for d in junction_cars:
		var f := Vector2(-sin(d.yaw), -cos(d.yaw))
		var at := Vector2(d.pos.x, d.pos.z)
		for c in _tram_at.size():
			var rel := _tram_at[c] - at
			if rel.length_squared() > 900.0:
				continue
			var axis := _tram_axis[c]
			if absf(axis.dot(f)) > 0.9:
				continue  # running alongside the track, not across it
			# Across the track: the car's centre is `side` m from the tram car's line and
			# closes on it at `fn` m per metre driven (only if it is heading towards it).
			var n := Vector2(-axis.y, axis.x)
			var side := rel.dot(n)
			var fn := f.dot(n)
			if side * fn <= 0.0:
				continue  # past the line, driving away from it
			fn = absf(fn)
			var fa := absf(f.dot(axis))
			# How far the car's box reaches towards the line, and along it.
			var ext_n := fn * d.length * 0.5 + fa * d.size.x * 0.5
			var ext_a := fa * d.length * 0.5 + fn * d.size.x * 0.5
			var to_line := absf(side) / fn
			if to_line > 22.0:
				continue
			# Where the car's path meets the line, from the tram car's centre along its axis:
			# in the way if the tram car's body (or the front car's next metres) is there.
			var t := (f * to_line - rel).dot(axis)
			if t < -TRAM_CAR * 0.5 - ext_a - TRAM_MARGIN or t > TRAM_CAR * 0.5 + _tram_ahead[c] + ext_a + TRAM_MARGIN:
				continue
			# The gap along the car's way until its box is TRAM_MARGIN from the tram's side.
			var g := (absf(side) - ext_n - TRAM_HALF - TRAM_MARGIN) / fn
			# Already in the way in front of the tram's nose: drive on and clear it (it waits;
			# waiting here too stopped both for good).
			if g < 0.0 and _tram_front[c] == 1 and t > TRAM_CAR * 0.5:
				continue
			if g < d.cross_gap:
				d.cross_gap = g
				d.cross_v = 0.0
			d.sees_tram = true


## Gap to the first stop line ahead that shows red (or amber the car can stop for).
func _red_ahead(d: Driver) -> float:
	var stops := graph.e_stops[d.edge]
	var front := d.s + d.length * 0.5
	for k in range(0, stops.size(), 3):
		var at := stops[k]
		if at < front - 0.2:
			continue
		var state := graph.light(int(stops[k + 1]), int(stops[k + 2]))
		# Loop 3g-1: a chaser goes through (slowly: SIREN_SLOW, in _drive).
		if state == LaneGraph.GREEN or d.run_red or d.chase:
			return INF
		var g := at - front - 0.5
		if state == LaneGraph.AMBER and g < d.v * d.v / (2.0 * DECEL):
			return INF  # too close to stop: go through on amber
		return g
	return INF


## World position and heading from the lane (or the junction curve); the heading
## follows the motion, so cars swing smoothly through bends.
func _place(d: Driver) -> void:
	var p: Vector2
	var y: float
	var e := d.edge
	d.clip = 1.0
	if d.in_conn:
		var t := d.cu / d.conn_len
		p = _line_at(d) if d.line != null else LaneGraph.bezier(d.conn, t)
		y = lerpf(d.conn_y0, d.conn_y1, t)
	else:
		var length := graph.e_len[e]
		var s := minf(d.s, length)
		if d.line != null:
			p = _line_at(d)
		else:
			d.seg = graph.seek(e, s, d.seg)
			p = graph.point(e, s, d.off, d.seg)
		y = graph.height(e, s)
		if d.s > length - d.length * 0.5 and d.next_edge < 0:
			# Leaving the map: slide out under the edge of the diorama.
			var dir := graph.direction(e, length)
			p += dir * (d.s - length)
			d.clip = clampf((length - d.s + d.length * 0.5) / d.length, 0.0, 1.0)
		if graph.e_tn[e] >= 0 and graph.tunnel_depth(e, s) > LaneGraph.TUNNEL_HIDE:
			d.clip = 0.0  # loop 3b: deep in a tunnel (simulated, not drawn)
	p += d.line_carry
	var moved := Vector2(p.x - d.pos.x, p.y - d.pos.z)
	if d.back_v > 0.0:
		moved = -moved  # backing up: the nose points against the motion
	# (Round the player's car at a standstill it edges sideways: its nose stays where it points.)
	if moved.length_squared() > 0.000001 and not (d.shoulder != 0.0 and d.v < 1.0):
		d.yaw = lerp_angle(d.yaw, atan2(-moved.x, -moved.y), 0.35)
	d.pos = Vector3(p.x, y, p.y)
	if not d.ghost:
		d.visible = on_screen(d.pos, d.size.y)
	if d.node != null:
		d.node.global_transform = Transform3D(Basis(Vector3.UP, d.yaw), d.pos)


# --- the racing line (LINE_* above) ----------------------------------------------------------------

## Whether driver d drives a racing line: a racer with a plan in a race (not a chaser, a crazy
## driver or the autopilot's).
static func lined(d) -> bool:
	return d.plan != null and d.race_accel > 0.0 and d.race_lat > 0.0 and not d.route.is_empty() and not d.chase \
			and d.crazy == 0 and not d.ghost


## The lane graph's metres of driver d's place along its line.
func _line_x(d: Driver) -> float:
	return d.line.xc[d.line_q] + d.cu if d.in_conn else d.line.xs[d.line_q] + d.s


## Driver d's place on the ground by its line (without `line_carry`): `line_dyn` m to the right
## of the line (a pass, a lane change under way); while it moves over from the line it drove
## before (`line_was`), between the places the two give it.
func _line_at(d: Driver) -> Vector2:
	var p := _line_own(d)
	if d.line_was == null:
		return p
	var x := d.line_was.xs[d.line_was_q] + d.s
	d.line_was_i = d.line_was.seek(x, d.line_was_i)
	var was := d.line_was.point(x, d.line_was_i)
	var dyn := d.off - graph.lane_offset(d.edge, d.line_was.lanes[d.line_was_q])
	if dyn != 0.0:
		was += d.line_was.side(x, d.line_was_i) * dyn
	return was.lerp(p, smoothstep(0.0, LINE_BLEND, d.line_blend))


## Whether driver d's racing line pulls it sideways too hard here for it to leave its lane as
## well (LINE_BUSY of its grip, by the turn within the line's window before and after it).
func _line_busy(d: Driver) -> bool:
	if d.line == null:
		return false
	var i := mini(d.line_i, d.line.turn.size() - 2)
	return d.v * d.v * maxf(d.line.turn[i], d.line.turn[i + 1]) / RaceLine.RUN > LINE_BUSY * d.line_grip


## Driver d's place by the line it drives alone.
func _line_own(d: Driver) -> Vector2:
	var x := _line_x(d)
	d.line_i = d.line.seek(x, d.line_i)
	var p := d.line.point(x, d.line_i)
	if d.line_dyn != 0.0:
		p += d.line.side(x, d.line_i) * d.line_dyn
	return p


## Ends driver d's moving over from the line it drove before (it leaves the street it began on,
## that line ends): what is left of the difference is carried (`line_carry`).
func _line_settle(d: Driver) -> void:
	if d.line_was == null:
		return
	var p := _line_at(d)
	d.line_was = null
	if d.line != null:
		d.line_carry += p - _line_own(d)


## The metres driver d makes for each metre of piece i of its line: 1 on the line, fewer beside
## it inside a bend (LINE_INSIDE at least), more outside one.
func _line_share(d: Driver, i: int) -> float:
	return 1.0 if d.line_dyn == 0.0 else clampf(d.line.beside(i, d.line_dyn), LINE_INSIDE, 1.0 / LINE_INSIDE)


## Driver d's place on the ground by the lane graph: its lane's line, the junction's curve.
func _rail_at(d: Driver) -> Vector2:
	if d.in_conn:
		return LaneGraph.bezier(d.conn, d.cu / d.conn_len)
	var s := minf(d.s, graph.e_len[d.edge])
	d.seg = graph.seek(d.edge, s, d.seg)
	return graph.point(d.edge, s, d.off, d.seg)


## Forgets the streets driver d had decided on beyond the one ahead (a wrong turn among them is
## not made: its roll is given back).
func _way_clear(d: Driver) -> void:
	for wrong in d.way_wrong:
		d.race_wrong += wrong
	d.way.clear()
	d.way_cut.clear()
	d.way_wrong.clear()


## Driver d leaves its racing line for the lane graph's way; its place eases over (`line_carry`).
func _line_drop(d: Driver) -> void:
	if d.line == null:
		return
	var was := _line_at(d)
	d.line = null
	d.line_was = null
	d.line_cuts = []
	d.line_carry += was - _rail_at(d)


## Driver d's racing line, brought up to date with its way on: more of the way decided where
## little is left, and the line built along it (with `more_only`, only when more was decided:
## nothing else has changed). Dropped when d is no racer on a line (any more), has no way on, or
## is turning round.
func _line_sync(d: Driver, more_only := false) -> void:
	if not lined(d) or d.next_edge < 0 or d.back != BACK_NONE or d.conn_end >= 0.0:
		_way_clear(d)
		_line_drop(d)
		return
	if d.in_conn and (d.line == null or d.line.lanes[d.line_q] != d.lane):
		_line_drop(d)
		return  # (in a junction's curve no line begins: from the next street on)
	if _way_extend(d) or not more_only or d.line == null:
		_line_build(d)


## Decides more of driver d's way (`way`) until it reaches LINE_AHEAD + LINE_MORE m ahead of it and
## ends on a street long enough to end a stretch of line on, or at its finish: each street by its
## plan, as it will choose there (and a wrong turn by its roll, here, a junction or more early:
## the line through a big junction is one line). True when it decided more.
func _way_extend(d: Driver) -> bool:
	var g := graph
	var more := false
	d.line_full = false
	if d.arrived or (not d.in_conn and d.plan.ends_on(d.edge, d.s)):
		d.line_full = true
		return false
	var ahead := d.conn_len - d.cu if d.in_conn else maxf(g.e_s1[d.edge] - d.s, 0.0) + d.conn_len
	ahead += g.e_s1[d.next_edge] - g.e_s0[d.next_edge]
	for f in d.way:
		ahead += g.e_s1[f] - g.e_s0[f]
	var last := d.way[d.way.size() - 1] if not d.way.is_empty() else d.next_edge
	while true:
		if d.plan.ends_on(last, g.e_s0[last]):
			d.line_full = true
			return more
		# (The line ends where its last street's is cut.)
		if _line.is_long(last) and ahead - (g.e_s1[last] - _line.split(last)) >= LINE_AHEAD + LINE_MORE:
			return more
		if d.way.size() >= WAY_MOST or g.e_shut[last] < INF or not d.plan.step(last, 0):
			return more  # (its plan has not searched that far yet: asked again in a moment)
		var f: int = d.plan.choose(last, g.e_s0[last], d.plan.speed(last))
		if f < 0:
			return more
		var cut: bool = d.plan.chosen_cut
		var wrong := 0
		var other: int = d.plan.wrong
		if d.race_wrong > 0 and other >= 0 and d.route[g.e_b[last]] > WRONG_FAR and _race_roll(d) < WRONG_SURE:
			f = other
			cut = false
			wrong = 1
			d.race_wrong -= 1
		if f == d.edge or f == d.next_edge or f in d.way:
			# Round in a ring (the way back from a wrong turn): decided when it gets there.
			d.race_wrong += wrong
			return more
		d.way.append(f)
		d.way_cut.append(1 if cut else 0)
		d.way_wrong.append(wrong)
		ahead += g.e_s1[f] - g.e_s0[f]
		last = f
		more = true
	return more


## Builds driver d's racing line along its way: from the start of the stretch of line it is on
## (so the line under it stays where it is), or from where it is when it has none or has changed
## lane; through the street ahead and those of its `way`, to the middle of the last or to its
## finish. Its place does not jump: on a street it moves over from the line it had (`line_was`,
## LINE_BLEND), elsewhere the difference is carried (`line_carry`) and eased out.
func _line_build(d: Driver) -> void:
	var g := graph
	var e := d.edge
	var before := _line_at(d) if d.line != null else _rail_at(d)
	var old := d.line
	var old_q := d.line_q
	var old_i := d.line_i
	var old_own := _line_own(d) if old != null else before
	var edges := PackedInt32Array()
	var lanes := PackedInt32Array()
	var cuts: Array = []
	var from := 0.0
	if d.line != null and d.line.lanes[d.line_q] == d.lane:
		var k := d.line.part(_line_x(d))
		var q0 := d.line.part_q[k]
		from = d.line.part_from[k]
		edges = d.line.edges.slice(q0, d.line_q + 1)
		lanes = d.line.lanes.slice(q0, d.line_q + 1)
		cuts = d.line_cuts.slice(q0, d.line_q)
	else:
		edges.append(e)
		lanes.append(d.lane)
		from = clampf(d.s, 0.0, maxf(g.e_s1[e] - 0.1, 0.0))
	var q := edges.size() - 1
	edges.append(d.next_edge)
	lanes.append(d.next_lane)
	cuts.append(d.conn if d.on_cut else null)
	for k in d.way.size():
		var f := d.way[k]
		var at := edges[edges.size() - 1]
		var lane := lanes[lanes.size() - 1]
		if d.way_cut[k] == 1:
			cuts.append(cut_curve(at, lane, f))
			lanes.append(mini(lane, g.e_lanes[f] - 1))
		else:
			cuts.append(null)
			lanes.append(_line.lane_on(at, lane, f))
		edges.append(f)
	var last := edges[edges.size() - 1]
	var to := g.e_s1[last]
	if d.plan.ends_on(last, g.e_s0[last]):
		# Its finish is on the last street: at its end, or where it enters the finish's circle.
		var end: Vector2 = d.plan.end_of(last)
		to = clampf(end.x, g.e_s0[last] + 0.5, g.e_s1[last])
	elif _line.is_long(last):
		to = _line.split(last)
	if _line.kept() > LINE_KEPT:
		_line.clear()
	d.line = _line.path(edges, lanes, from, to, cuts)
	d.line_cuts = cuts
	d.line_q = q
	d.line_i = 0
	if not d.in_conn:
		d.line_dyn = d.off - g.lane_offset(e, d.lane)
	_line_speeds(d)
	var own := _line_own(d)
	if old != null and own.distance_squared_to(old_own) < 0.0001:
		return  # (the same line under it: nothing moves, and it goes on moving over as it was)
	if old == null or d.in_conn:
		d.line_was = null
		d.line_carry += before - own
		return
	# (Moving over already: what was left of that is carried, and it moves over from the last line.)
	d.line_carry += before - old_own
	d.line_was = old
	d.line_was_q = old_q
	d.line_was_i = old_i
	d.line_blend = 0.0


## The speed for every metre of driver d's line, for its grip now (its effort works on it:
## behind, it takes the corners harder) and its braking; with a mistake rolled for the junction
## ahead (`mistake_side`), too fast round that one.
func _line_speeds(d: Driver) -> void:
	var brake := d.race_brake if d.race_brake > 0.0 else RACE_DECEL * 0.7
	d.line_grip = d.race_lat * clampf(d.race_corner, GRIP_EFFORT_LEAST, GRIP_EFFORT_MOST)
	d.line_fast = d.mistake_side != 0.0
	if d.line_fast:
		var at := d.line.xc[d.line_q]
		_line.speeds(d.line, d.line_grip, brake, at - LINE_FAST, at + d.conn_len + LINE_FAST, MISTAKE_FAST, RACE_GRIP_MOST)
	else:
		_line.speeds(d.line, d.line_grip, brake)


## Driver d's racing line kept up for this frame (dropped where it ends or d is no racer on a
## line any more, its speeds worked out again when its grip has changed, more of the way decided
## when less than LINE_AHEAD m are left), and the speed (m/s) it gives for the metre the car comes
## to this frame; INF with the line dropped.
func _line_ahead(d: Driver, dt: float) -> float:
	d.line_wait -= dt
	var x := _line_x(d)
	var last := d.line.xl.size() - 1
	if not lined(d) or x >= d.line.xl[last] - 0.01:
		_way_clear(d)
		_line_drop(d)
		return INF
	if not d.line_full and d.line_wait <= 0.0 and d.line.xl[last] - x < LINE_AHEAD:
		d.line_wait = 0.5
		_line_sync(d, true)
		if d.line == null:
			return INF
		x = _line_x(d)
	elif absf(d.race_lat * clampf(d.race_corner, GRIP_EFFORT_LEAST, GRIP_EFFORT_MOST) - d.line_grip) > 0.01 * d.line_grip or (d.mistake_side != 0.0) != d.line_fast:
		_line_speeds(d)
	d.line_i = d.line.seek(x, d.line_i)
	var to := x + d.line.advance(x, d.line_i, d.v * dt / _line_share(d, d.line_i))
	var i := d.line.seek(to, d.line_i)
	# (Beside the line inside a bend the turn is tighter by the share: the same pull at less speed.)
	return d.line.speed(to, i) * sqrt(minf(_line_share(d, i), 1.0))


func _write() -> void:
	for d in _active:
		if d.kind >= Kind.NODE or d.slot < 0:
			continue
		var buf := _buf[d.kind]
		var b := d.slot * 16
		var c := cos(d.yaw)
		var s := sin(d.yaw)
		var z := d.clip
		var o := d.pos
		if z < 1.0:
			# Keep the rear where it is while the front disappears.
			o -= Vector3(-s, 0.0, -c) * (1.0 - z) * d.length * 0.5
		buf[b] = c
		buf[b + 1] = 0.0
		buf[b + 2] = s * z
		buf[b + 3] = o.x
		buf[b + 4] = 0.0
		buf[b + 5] = 1.0
		buf[b + 6] = 0.0
		buf[b + 7] = o.y
		buf[b + 8] = -s
		buf[b + 9] = 0.0
		buf[b + 10] = c * z
		buf[b + 11] = o.z
		buf[b + 12] = d.paint.r
		buf[b + 13] = d.paint.g
		buf[b + 14] = d.paint.b
		# Loop 3g-1: a police car's custom alpha also says its light bar's state (actor.gdshader
		# SIREN: + 4 lights off, + 8 flashing).
		buf[b + 15] = float(d.shape) + (0.0 if d.kind != Kind.POLICE else (8.0 if d.lights else 4.0))
		_top[d.kind] = maxi(_top[d.kind], d.slot + 1)
	for k in POOL.size():
		# Loop 2c: draw only up to the highest slot in use (a freed slot is the next one taken,
		# so this stays near the most cars of the kind at once; the pools are 112 / 16 / 16 / 8).
		if _top[k] != _drawn[k]:
			_drawn[k] = _top[k]
			_mm[k].visible_instance_count = _top[k]
			if k < TRAFFIC_KINDS:
				_beam_mm[k].visible_instance_count = _top[k]
		_top[k] = 0
		if k == Kind.POLICE and _drawn[k] == 0:
			continue  # loop 3g-1: no police car out, nothing to send
		InstanceBuffers.send(_mm[k].get_rid(), _buf[k])
		if k < TRAFFIC_KINDS and _beam_mmi[k].visible:
			InstanceBuffers.send(_beam_mm[k].get_rid(), _buf[k])


# --- the night-buses loop: the N sign, stops, extra buses ------------------------------------

## The N, four by five (the route sign's letter; no operator's name or number).
const N_GLYPH := ["#..#", "##.#", "#.##", "#..#", "#..#"]


## The bus with its night route sign: models.gd's bus plus a dark display with an amber N
## (LIT_SIGN: it glows with the city's lights) on both sides by the front door, the back and
## over the windscreen, merged into the bus's one surface (one mesh, made once).
static func night_bus_mesh() -> ArrayMesh:
	if _bus_night != null:
		return _bus_night
	var plate := Models.fin(Color("#16171b"))
	var lit := Models.fin(Color("#ffb21e"), Models.LIT_SIGN)
	# One shape per bus (models.gd bus_mesh: the articulated and the solo bus), the signs placed
	# by its front (-9 or -6) and back (9 or 6).
	var shapes: Array = []
	for solo: bool in [false, true]:
		var s := Models.bus_shape(solo)
		var front := -6.0 if solo else -9.0
		var back := 6.0 if solo else 9.0
		# A side's "right" as seen from outside it: -z on the +x side, +z on the -x side.
		for sgn: float in [-1.0, 1.0]:
			_n_sign(s, Vector3(sgn * 1.262, 2.12, front + 2.45), Vector3(0, 0, -sgn), Vector3(sgn, 0, 0), Vector2(1.2, 1.0), 0.19, plate, lit)
		_n_sign(s, Vector3(0.0, 2.44, back - 0.005), Vector3.RIGHT, Vector3.BACK, Vector2(1.0, 0.8), 0.15, plate, lit)
		_n_sign(s, Vector3(0.0, 2.56, front + 0.1), Vector3.LEFT, Vector3.FORWARD, Vector2(0.9, 0.72), 0.13, plate, lit)
		shapes.append(s)
	_bus_night = Models.family(shapes)
	return _bus_night


## A dark plate `size` (w, h) at `centre` facing `out`, with N_GLYPH on it in `px` m pixels.
static func _n_sign(s: Models.Shape, centre: Vector3, right: Vector3, out: Vector3, size: Vector2, px: float,
		plate: Array, lit: Array) -> void:
	var up := Vector3.UP
	var hw := right * size.x * 0.5
	var hh := up * size.y * 0.5
	s.quad(centre - hw - hh, centre + hw - hh, centre + hw + hh, centre - hw + hh, plate, out)
	var o := centre - right * px * 2.0 + up * px * 2.5 + out * 0.006
	for r in N_GLYPH.size():
		var row: String = N_GLYPH[r]
		for c in row.length():
			if row[c] != "#":
				continue
			var a := o + right * px * c - up * px * r
			s.quad(a, a + right * px, a + right * px - up * px, a - up * px, lit, out)


## The buses out now (traffic and buses.gd's).
func buses() -> Array[Driver]:
	var out: Array[Driver] = []
	for d in _active:
		if d.kind == Kind.BUS:
			out.append(d)
	return out


## A bus from the pool on lane (e, lane) at s, standing (buses.gd: a ring bus, the one that
## comes for the player's horn); null if the pool is empty. Not persistent: the caller decides.
func add_bus(e: int, lane: int, s: float) -> Driver:
	if _free_slots[Kind.BUS].is_empty() or _free.is_empty():
		return null
	var look: Dictionary = Models.TRAFFIC[Kind.BUS][0]
	var d: Driver = _free.pop_back()
	d.kind = Kind.BUS
	d.slot = _free_slots[Kind.BUS][_free_slots[Kind.BUS].size() - 1]
	_free_slots[Kind.BUS].resize(_free_slots[Kind.BUS].size() - 1)
	_counts[Kind.BUS] += 1
	d.size = look["size"]
	d.length = d.size.z
	d.shape = 0
	d.paint = Color(look["paint"][0])
	d.speed_factor = 0.85
	d.accel_factor = 0.7
	d.persistent = false
	d.ghost = false
	d.node = null
	d.core_only = false
	d.parked = false
	_start(d, e, lane, s)
	d.v = 0.0
	return d


## Sends bus `d` to stop with its front at s on edge e (its route `dist`: graph.distances_to the
## edge's end), pulled `pull` m towards the kerb, for `wait` s (INF: until let_go). It keeps out
## of the band's thinning while on its way (persistent) and runs no reds.
func send_to_stop(d: Driver, e: int, s: float, dist: PackedFloat32Array, wait: float, pull: float) -> void:
	d.halt_e = e
	d.halt_s = s
	d.halt_wait = wait
	d.halt_pull = pull
	d.halting = false
	d.persistent = true
	d.route = dist
	d.finish = graph.e_b[e]
	d.arrived = false
	if not d.in_conn and not d.parked:
		_choose_next(d)
	d.run_red = false


## Ends a bus's stop (or its way there): it drives on as any bus, out of the kerb's pull.
func let_go(d: Driver) -> void:
	var was := d.halting
	d.halt_e = -1
	d.halting = false
	d.persistent = false
	d.tag = ""
	if d.reg >= 0 and not d.in_conn:
		d.off_target = graph.lane_offset(d.edge, d.lane)
	stop_racing(d)
	if was:
		bus_left.emit(d)


## True if the driver is still the same pooled car (kind and slot unchanged since `slot`).
static func same(d: Driver, kind: int, slot: int) -> bool:
	return d != null and d.active and d.kind == kind and d.slot == slot


## A bus's way to its stop, each frame it drives on the stop's edge (_drive): the gap to the
## stop's line (INF: not there yet); standing, it pulls in and counts its wait down.
func _halt_gap(d: Driver, dt: float) -> float:
	if d.halting:
		var off := graph.lane_offset(d.edge, d.lane) + d.halt_pull
		d.off_target = off
		if d.halt_wait < INF:
			d.halt_wait -= dt
			if d.halt_wait <= 0.0:
				let_go(d)
				return INF
		return 0.0
	if d.arrived:
		let_go(d)
		return INF
	var e := d.edge
	var g := INF
	if not d.in_conn and e == d.halt_e:
		if d.lane < graph.e_lanes[e] - 1:
			_change_lane_to(d, graph.e_lanes[e] - 1)
		g = d.halt_s - (d.s + d.length * 0.5)
	elif d.next_edge == d.halt_e and d.next_edge >= 0:
		# The stop is just past the junction ahead (a short edge): look through it.
		var rest := d.conn_len - d.cu if d.in_conn else graph.e_s1[e] - d.s + d.conn_len
		g = rest + d.halt_s - graph.e_s0[d.halt_e] - d.length * 0.5
	else:
		return INF
	if g < -3.0:
		# Driven past it (pushed, or put down beyond it): no stop this time.
		let_go(d)
		return INF
	if g < 1.2 and d.v < 0.4:
		d.halting = true
		d.v = 0.0
		bus_halted.emit(d)
		return 0.0
	# The driver model keeps MIN_GAP to a stop line: the stop's line is that much further on.
	return maxf(g + MIN_GAP, 0.0)


# --- traffic-light lamps --------------------------------------------------------------

## A lamp box through each signal head's red, amber and green lights, coloured by
## its junction's controller. It shows on both faces of the head, so the light
## reads from wherever the camera looks.
func _build_lamps(signals: Array) -> void:
	var poles := graph.poles
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.28, 0.36)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	_lamps = MultiMesh.new()
	_lamps.transform_format = MultiMesh.TRANSFORM_3D
	_lamps.use_colors = true
	_lamps.mesh = mesh
	var spots: Array[Transform3D] = []
	for i in range(0, mini(signals.size() / 3, poles.size() / 2)):
		var c := poles[i * 2]
		if c < 0:
			continue
		var x := float(signals[i * 3])
		var z := float(signals[i * 3 + 1])
		var t := Transform3D(Basis(Vector3.UP, float(signals[i * 3 + 2])), Vector3(x, map.terrain_height(x, z), z))
		var key := c * 2 + poles[i * 2 + 1]
		if not _lamp_slots.has(key):
			_lamp_slots[key] = PackedInt32Array()
		_lamp_slots[key].append(spots.size())
		for y in [3.65, 3.35, 3.05]:
			spots.append(t * Transform3D(Basis(), Vector3(0, y, 0.2)))
	_lamps.instance_count = spots.size()
	var box := AABB()
	for k in spots.size():
		_lamps.set_instance_transform(k, spots[k])
		_lamps.set_instance_color(k, LAMP_OFF)
		box = AABB(spots[k].origin, Vector3.ZERO) if k == 0 else box.expand(spots[k].origin)
	_lamps.custom_aabb = box.grow(2.0)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _lamps
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# Halos: the same spots, a billboard each, coloured like the lamp (black when off).
	_halos = MultiMesh.new()
	_halos.transform_format = MultiMesh.TRANSFORM_3D
	_halos.use_colors = true
	_halos.mesh = MapBuilder.halo_quad(1.5)
	_halos.instance_count = spots.size()
	for k in spots.size():
		_halos.set_instance_transform(k, spots[k])
		_halos.set_instance_color(k, Color.BLACK)
	_halos.custom_aabb = _lamps.custom_aabb
	var glow := ShaderMaterial.new()
	glow.shader = load("res://shaders/glow.gdshader")
	glow.set_shader_parameter("billboard", true)
	glow.set_shader_parameter("radial", true)
	glow.set_shader_parameter("lift", 0.6)
	glow.render_priority = 1
	var hmi := MultiMeshInstance3D.new()
	hmi.multimesh = _halos
	hmi.material_override = glow
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hmi.visible = false
	hmi.add_to_group("night_lights")
	add_child(hmi)
	_lamp_state.resize(graph.ctrl_pos.size() * 2)
	_lamp_state.fill(-1)
	_lamp_keys = PackedInt32Array(_lamp_slots.keys())


func _update_lamps() -> void:
	_lamp_turn = (_lamp_turn + 1) % LAMP_STRIDE
	for n in range(_lamp_turn, _lamp_keys.size(), LAMP_STRIDE):
		var key := _lamp_keys[n]
		var state := graph.light(key / 2, key % 2)
		if state == _lamp_state[key]:
			continue
		_lamp_state[key] = state
		var red := state == LaneGraph.RED or state == LaneGraph.RED_AMBER
		var amber := state == LaneGraph.AMBER or state == LaneGraph.RED_AMBER
		var green := state == LaneGraph.GREEN
		for first in _lamp_slots[key]:
			_lamps.set_instance_color(first, LAMP_ON[0] if red else LAMP_OFF)
			_lamps.set_instance_color(first + 1, LAMP_ON[1] if amber else LAMP_OFF)
			_lamps.set_instance_color(first + 2, LAMP_ON[2] if green else LAMP_OFF)
			_halos.set_instance_color(first, HALO[0] if red else Color.BLACK)
			_halos.set_instance_color(first + 1, HALO[1] if amber else Color.BLACK)
			_halos.set_instance_color(first + 2, HALO[2] if green else Color.BLACK)
