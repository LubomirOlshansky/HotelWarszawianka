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
## car: top speed `race_top` × its rubber band, capped by road class (RACE_CLASS_TOP: e_class 0
## main, 1 tertiary, 2 residential, 3 living street), pulling `race_accel` m/s², braking
## RACE_DECEL, corners at `race_lat` m/s² sideways (v = sqrt(lat × radius) of the junction curve,
## at least RACE_TURN_MIN), a shorter headway, through every red (a little slower in the box,
## RACE_RED_SLOW of its speed within RACE_RED_LOOK m of the line), crossing cars only when one is
## within RACE_CROSS m, and round slower traffic and the player's car: a free lane, or out over
## the centre line for a pass when the oncoming lane is clear for RACE_PASS_CLEAR m.
## (F 2026-11-05, "they go very slowly": 30/25/19/12 held them to 68 km/h on the centre's side
## streets, where the player does 90.)
const RACE_CLASS_TOP := [33.0, 29.0, 25.0, 16.0]
## Racer mode: once a second while a racer stands still, what holds it (main.gd --race-debug).
var race_debug := false
const RACE_DECEL := 8.0
const RACE_HEADWAY := 0.6
const RACE_TURN_MIN := 6.0
const RACE_RED_SLOW := 0.75
const RACE_RED_LOOK := 30.0
const RACE_CROSS := 7.0
const RACE_LOOK := 30.0
const RACE_PASS_CLEAR := 70.0
const RACE_PASS_ROOM := 40.0
## Racer mode: stood still this long behind a car with no way past, it slips through (s).
const RACE_KNOT := 1.5
## Human rivals (F 2026-11-05: "never the skróty, never cut me off", docs/design/street-races.md
## section 9). Shortcuts (race_cuts.gd): a racer takes a cut it knows from the junction ahead when
## the cut and the road on from its far end beat the road route by RaceCuts.GAIN m, at most
## CUT_TOP m/s across the plaza (slower when it turns sharply in).
const CUT_TOP := 16.0
## Mistakes: a racer that rolls its `race_mistake` at a corner (only within MISTAKE_NEAR m of the
## player, so it is seen) takes it MISTAKE_FAST too fast and runs wide out of it: a slide of
## MISTAKE_SLIDE m/s outwards and MISTAKE_DAZE s of lifting off.
const MISTAKE_NEAR := 110.0
const MISTAKE_FAST := 1.3
const MISTAKE_SLIDE := 4.5
const MISTAKE_DAZE := 0.8
## Wrong turns (Słoik's satnav): at a junction with a choice, more than WRONG_FAR m from the
## finish, a WRONG_CHANCE roll takes the second-best way (the route's distances bring him back).
const WRONG_FAR := 300.0
const WRONG_CHANCE := 0.2
## Blocking (Game AI Pro's "one lateral move"): a racer with the player BLOCK_BACK m or less behind
## it, catching up, rolls its `race_block` once in BLOCK_EVERY s; on a hit it moves across onto the
## player's line, once, and holds it for BLOCK_HOLD s (the player can still go round the other side).
const BLOCK_BACK := 22.0
const BLOCK_EVERY := 2.5
const BLOCK_HOLD := 2.2
## Cutting in: a racer passing the player with `race_block` from BLOCK_TIGHT pulls back in this many
## metres sooner (in front of the player's bumper, not a polite car's length ahead).
const BLOCK_TIGHT := 0.5
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
	var arrived := false
	var run_red := false
	## Racer mode (RACE_CLASS_TOP above): top speed (m/s; 0: none, the road's limit × speed_factor),
	## acceleration (m/s²; 0: the town car's IDM), corner grip (m/s²), the rubber band's factor on
	## the top speed (rivals.gd), and a pass over the centre line under way (s left, its offset).
	var race_top := 0.0
	var race_accel := 0.0
	var race_lat := 7.0
	var race_band := 1.0
	var pass_t := 0.0
	var pass_off := 0.0
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
	var on_cut := false
	var mistake_side := 0.0
	var block_t := 0.0
	var block_off := 0.0
	var block_wait := 0.0
	var cuts_taken := 0
	var mistakes := 0
	var wrong_turns := 0
	var blocks := 0
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
## The ground in view, kept by _update_view(): centre, right and ahead axes, half size (m).
var view_centre := Vector2.ZERO
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
		d.race_band = 1.0
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
	d.run_red = false
	d.yield_t = 0.0
	d.pass_t = 0.0
	if not d.persistent:
		d.race_top = 0.0
		d.race_accel = 0.0
		d.race_band = 1.0
		d.cuts = {}
		d.race_mistake = 0.0
		d.race_wrong = 0
		d.race_block = 0.0
	d.on_cut = false
	d.mistake_side = 0.0
	d.block_t = 0.0
	# The night-buses loop: a pooled driver forgets its last stop (and a ring bus's parking).
	d.halt_e = -1
	d.halting = false
	d.tag = ""
	d.parked = false
	_enter_edge(d, e, lane, s)
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


## Starts racing to graph node `finish`: the driver follows the shortest path.
func race_to(d: Driver, finish: int, dist: PackedFloat32Array) -> void:
	d.route = dist
	d.finish = finish
	d.arrived = false
	if not d.in_conn:
		_choose_next(d)


func stop_racing(d: Driver) -> void:
	d.route = PackedFloat32Array()
	d.finish = -1
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


## Driving distance left to the race finish.
func remaining(d: Driver) -> float:
	if d.route.is_empty():
		return INF
	if d.in_conn:
		return (d.conn_len - d.cu) + graph.remaining(d.route, d.next_edge, graph.e_s0[d.next_edge])
	return graph.remaining(d.route, d.edge, d.s)


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
	if graph.e_s1[e] - d.s < 18.0:
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
	d.edge = e
	d.lane = lane
	d.s = s
	d.seg = graph.e_first[e]
	d.in_conn = false
	d.off = graph.lane_offset(e, lane)
	d.off_target = d.off
	_register(d, graph.e_lane0[e] + lane)
	d.ls = s
	d.on_cut = false
	d.block_t = 0.0
	if d.mistake_side != 0.0:
		# Human rivals: in too fast, out wide: it slides off its line and lifts off a moment.
		d.daze = MISTAKE_DAZE
		d.slide = MISTAKE_SLIDE * d.mistake_side
		d.mistake_side = 0.0
		d.mistakes += 1
	_choose_next(d)


func _register(d: Driver, lane_id: int) -> void:
	if d.ghost:
		return
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = lane_id
	_lane_cars[lane_id].append(d)


## Picks the edge after this one: by the race route, or at random with a liking
## for bigger roads and going straight; a U-turn only at a dead end.
func _choose_next(d: Driver) -> void:
	var e := d.edge
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
	if not d.route.is_empty():
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
			if not d.cuts.is_empty() and d.cuts.has(graph.e_b[e]) and best_d < INF and _take_cut(d, e, best_d):
				return
			if d.race_wrong > 0 and second >= 0 and second != rev and second_d < INF and d.route[graph.e_b[e]] > WRONG_FAR \
					and _rng.randf() < WRONG_CHANCE:
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
	d.next_lane = graph.next_lane(e, d.lane, best)
	d.conn = graph.connector(e, d.lane, best, d.next_lane)
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(best, graph.e_s0[best])
	var turn := absf(here.angle_to(graph.direction(best, graph.e_s0[best])))
	d.v_turn = 3.5 if best == rev else lerpf(16.0, 5.5, clampf(turn / 1.6, 0.0, 1.0))
	if d.race_accel > 0.0 and best != rev and not d.route.is_empty():
		# The rubber band works on grip too: behind, it takes the corners harder (F: "catch up by
		# driving better, not by a speed boost").
		d.v_turn = race_turn_speed(d.conn_len, turn, d.race_lat * clampf(d.race_band, 0.85, 1.15))
		if d.race_mistake > 0.0 and turn > 0.6 and Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z).length() < MISTAKE_NEAR \
				and _rng.randf() < d.race_mistake:
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


## Human rivals: takes a shortcut from the junction ahead (the end of edge e) if one it knows beats
## `road` (the best road route's metres from there; best_cut). Sets up the curve like _choose_next.
func _take_cut(d: Driver, e: int, road: float) -> bool:
	var best_g := best_cut(graph, d.cuts[graph.e_b[e]], d.route, road)
	if best_g < 0:
		return false
	var p0 := graph.point_at(e, graph.e_s1[e], graph.lane_offset(e, d.lane))
	var d0 := graph.direction(e, graph.e_s1[e])
	var g := best_g
	d.next_edge = g
	d.next_lane = mini(d.lane, graph.e_lanes[g] - 1)
	var p3 := graph.point_at(g, graph.e_s0[g], graph.lane_offset(g, d.next_lane))
	var d3 := graph.direction(g, graph.e_s0[g])
	var reach := clampf(p0.distance_to(p3) * 0.25, 1.0, 8.0)
	d.conn = PackedVector2Array([p0, p0 + d0 * reach, p3 - d3 * reach, p3])
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(g, graph.e_s0[g])
	var chord := (p3 - p0).normalized()
	var turn := maxf(absf(d0.angle_to(chord)), absf(chord.angle_to(d3)))
	d.v_turn = minf(CUT_TOP, race_turn_speed(d.conn_len, turn * 2.0, d.race_lat))
	d.next_reg = graph.e_lane0[g] + d.next_lane
	d.run_red = true
	d.on_cut = true
	d.cuts_taken += 1
	return true


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
	var e := d.edge
	var racer := racing_mode(d)
	var v0 := graph.e_speed[e] * d.speed_factor
	if racer and d.race_top > 0.0:
		v0 = minf(d.race_top, RACE_CLASS_TOP[graph.e_class[e]]) * d.race_band
		if d.crazy > 0:
			v0 = minf(v0, graph.e_speed[e] * CRAZY_OVER[d.crazy])
	if d.v_cap > 0.0:
		v0 = d.v_cap  # loop 3g-1: a chaser's own top speed
	if d.yield_t > 0.0:
		# Loop 3g-1: giving way to a police car with its lights on.
		d.yield_t -= dt
		v0 = minf(v0, YIELD_SPEED)
	if d.in_conn:
		v0 = minf(v0, d.v_turn)
	elif d.next_edge >= 0:
		var brake := RACE_DECEL * 0.7 if racer else DECEL * 0.6
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
	if d.squeeze <= 0.0:
		for o in _lane_cars[lane_id]:
			if o != d and o.ls > d.ls:
				var g: float = o.ls - d.ls - (o.length + d.length) * 0.5
				if g < gap:
					gap = g
					lead_v = o.v
					lead_parked = o.parked
		if not d.in_conn and d.next_reg >= 0:
			var base: float = graph.e_s1[e] - d.s + d.conn_len - graph.e_s0[d.next_edge]
			for o in _lane_cars[d.next_reg]:
				if o != d:
					var g: float = base + o.ls - (o.length + d.length) * 0.5
					if g < gap:
						gap = g
						lead_v = o.v
						lead_parked = false
	var leader_gap := gap
	var player_gap := INF
	if not d.ghost:
		var cross := d.cross_gap < gap and d.squeeze <= 0.0 and d.cross_ignore <= 0.0 and (not racer or d.crazy > 0 or d.cross_gap < RACE_CROSS)
		if cross:
			gap = d.cross_gap
			lead_v = d.cross_v
		if not d.in_conn:
			var stop := _red_ahead(d)
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
				# Loop 3g-1: a chaser looks wider and keeps `keep_gap` behind (it never rams).
				if along > 0.0 and absf(rel.cross(fwd)) < (4.0 if d.chase else 2.3):
					var g := along - d.length * 0.5 - d.keep_gap
					player_gap = g
					if g < gap:
						gap = g
						lead_v = maxf(0.0, Vector2(player_vel.x, player_vel.z).dot(fwd))
		if cross and gap == d.cross_gap and d.v < 0.3 and not d.sees_tram:
			d.cross_wait += dt
			if d.cross_wait > (1.5 if racer else 8.0):
				d.cross_ignore = 3.0
				d.cross_wait = 0.0
				_ov_knots += 1
		else:
			d.cross_wait = 0.0
		d.cross_ignore -= dt
	if racer and d.halt_e < 0:
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
			d.off = clampf(d.off + d.slide * dt, d.off_target - SHOVE_ACROSS, d.off_target + SHOVE_ACROSS)
		d.slide = move_toward(d.slide, 0.0, SLIDE_DECEL * dt)
	else:
		d.slide = 0.0
		var to := d.off_target
		if d.pass_t > 0.0:
			to = d.pass_off
		elif d.block_t > 0.0:
			to = d.block_off
		d.off = move_toward(d.off, to, (4.0 if racer else 2.5) * dt)
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
		var star := MIN_GAP + maxf(0.0, d.v * head + d.v * (d.v - lead_v) / (2.0 * comfy))
		var q := star / maxf(gap, 0.05)
		a -= (amax if racer else ACCEL) * q * q
	if dazed:
		a = minf(a, -DAZE_DECEL)
	d.v = maxf(0.0, d.v + maxf(a, -10.0) * dt)
	if gap < 0.2:
		d.v = minf(d.v, lead_v * 0.5)
	if d.route.is_empty() and not d.held:
		d.still = d.still + dt if d.v < 0.3 else 0.0
	if racer and not d.held and d.v < 1.0:
		d.race_still += dt
		if race_debug and fmod(d.race_still, 1.0) < dt:
			print("race debug: still %.0f s at (%.0f, %.0f) e%d s%.0f/%.0f lanes %d rev %d: leader %.1f player %.1f cross %.1f ign %.1f red %.1f gap %.1f pass %.1f sq %.1f conn %s chase %s" % [d.race_still, d.pos.x, d.pos.z, e, d.s, graph.e_s1[e], graph.e_lanes[e], graph.e_reverse[e], leader_gap, player_gap, d.cross_gap, d.cross_ignore, _red_ahead(d) if not d.in_conn else -1.0, gap, d.pass_t, d.squeeze, d.in_conn, d.chase])

	var step := d.v * dt
	if d.in_conn:
		d.cu += step
		if d.cu >= d.conn_len:
			_enter_edge(d, d.next_edge, d.next_lane, graph.e_s0[d.next_edge] + d.cu - d.conn_len)
			e = d.edge
		else:
			d.ls = graph.e_s0[d.next_edge] - (d.conn_len - d.cu)
	else:
		d.s += step
		# Checked before the junction curve: a fast car can cross the last metres in a frame.
		if not d.route.is_empty() and graph.e_b[e] == d.finish and d.s >= graph.e_s1[e] - 3.0 and not d.chase:
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
	var run_red := d.run_red
	# The edge roadworks: in past the barriers of the road it comes back on.
	teleport(d, best, mini(d.lane, graph.e_lanes[best] - 1), maxf(graph.e_s0[best], graph.e_open[best] + d.length * 0.5))
	if not route.is_empty():
		race_to(d, finish, route)
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


## Racer mode: past slower traffic and the player's car. Start looking RACE_LOOK m back; a free
## lane of the same road first (as _overtake); else, on a road with an oncoming lane clear for
## RACE_PASS_CLEAR m (and RACE_PASS_ROOM m of this road left before the junction), out over the
## centre line for long enough to get by, ignoring the cars in its own lane meanwhile. Stuck still
## behind someone with no way past for RACE_KNOT s (a knot of cars in a junction box): it slips through.
func _race_overtake(d: Driver, leader_gap: float, player_gap: float, dt: float) -> void:
	d.squeeze -= dt
	if d.pass_t > 0.0:
		d.pass_t -= dt
		d.squeeze = maxf(d.squeeze, 0.1)
		if d.pass_t <= 0.0 or d.in_conn or graph.e_s1[d.edge] - d.s < 6.0:
			# Back in lane; stay out while a car is alongside (if the junction allows).
			if not d.in_conn and graph.e_s1[d.edge] - d.s >= 6.0 and _alongside(d):
				d.pass_t = 0.3
			else:
				d.pass_t = 0.0
				d.squeeze = 0.0
		return
	# A chaser keeps its gap behind the player (it never passes or rams); a rival goes round.
	var ahead := leader_gap if d.chase else minf(leader_gap, player_gap)
	if ahead > RACE_LOOK:
		d.still = 0.0
		return
	# Any free lane, even close to the junction (a racer slips out of a queue at the lights); in
	# the junction curve itself only the knot rule below (Zbyszek stood 22 s in one).
	if not d.in_conn:
		if _change_lane(d, ahead + 6.0, 4.0 if d.v < 3.0 else 12.0):
			return
		if _race_pass(d, ahead, d.race_block >= BLOCK_TIGHT and player_gap <= leader_gap):
			return
	if d.v < 1.0:
		d.still += dt
		# A knot of cars in a junction box (headless runs: Halina stood 20 s at the start behind
		# a town car that stood too): a racer slips through after RACE_KNOT s, seen or not.
		# A crazy driver (town traffic, no race to win) never slips through a queue.
		if d.still > RACE_KNOT and d.crazy == 0:
			d.squeeze = 2.0
			d.cross_ignore = 2.0
			d.still = 0.0


## Racer mode: starts a pass over the centre line if the oncoming lane is clear (see above).
func _race_pass(d: Driver, ahead: float, tight := false) -> bool:
	var e := d.edge
	var left := graph.e_s1[e] - d.s
	if left < RACE_PASS_ROOM:
		return false
	var rev := graph.e_reverse[e]
	var lw := graph.e_lw[e]
	var out := graph.lane_offset(e, 0) - lw * 0.9
	if rev >= 0:
		# The oncoming cars: on the reverse edge, s_rev ~ e_len - s; clear ahead of us.
		var at := graph.e_len[e] - d.s
		for k in graph.e_lanes[rev]:
			for o in _lane_cars[graph.e_lane0[rev] + k]:
				var dd: float = at - o.ls
				if dd > -8.0 and dd < RACE_PASS_CLEAR:
					return false
	else:
		return false  # a one-way street: its other lanes or nothing (no oncoming side to use)
	# Long enough to get by the car ahead and its leader's length, at our speed edge over theirs.
	# Cutting in (BLOCK_TIGHT): past the player it pulls back in right in front of the bumper.
	var need := clampf((ahead + (9.0 if tight else 16.0)) / maxf(d.v * 0.35, 3.0), 1.2, 4.0)
	if need * maxf(d.v, 5.0) > left - 6.0:
		return false
	d.pass_t = need
	d.pass_off = out
	d.squeeze = need
	d.race_passes += 1
	return true


## Racer mode: a car of its own road's lanes within a car's length beside d.
func _alongside(d: Driver) -> bool:
	var e := d.edge
	for k in graph.e_lanes[e]:
		for o in _lane_cars[graph.e_lane0[e] + k]:
			if o != d and absf(o.ls - d.ls) < (o.length + d.length) * 0.5 + 1.5:
				return true
	return false


## Moves to the neighbouring lane with the most room ahead (more than `room`
## metres, nobody alongside), if the road has one. The car slides across.
func _change_lane(d: Driver, room_needed: float, near := 18.0) -> bool:
	var e := d.edge
	if d.in_conn or graph.e_s1[e] - d.s < near:
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
		p = LaneGraph.bezier(d.conn, t)
		y = lerpf(d.conn_y0, d.conn_y1, t)
	else:
		var length := graph.e_len[e]
		var s := minf(d.s, length)
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
	var moved := Vector2(p.x - d.pos.x, p.y - d.pos.z)
	if moved.length_squared() > 0.000001:
		d.yaw = lerp_angle(d.yaw, atan2(-moved.x, -moved.y), 0.35)
	d.pos = Vector3(p.x, y, p.y)
	if not d.ghost:
		d.visible = on_screen(d.pos, d.size.y)
	if d.node != null:
		d.node.global_transform = Transform3D(Basis(Vector3.UP, d.yaw), d.pos)


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
