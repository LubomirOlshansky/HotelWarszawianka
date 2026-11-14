extends Node
## Loop 3g-1 (police, part one; docs/design/police.md section 11.1): one police unit, a POLICE
## car in traffic (traffic.gd's Driver) and its beehave tree. police.gd keeps a pool of eight
## (the POLICE kind's pool), binds one to each police car that comes into the band or that it
## places (a speed trap's car, a blocker, the roadblock), writes the blackboard (`role`,
## `phase`, `pullover`) at 5 Hz right after its perception pass, and ticks the trees there.
## Escalation is not in the trees: police.gd's state machine decides; a tree only moves its
## unit, through the traffic API (race_to, stop_racing, park, unpark, held, the light bar).
##
##   SelectorReactive
##   ├ SequenceReactive  Escort   : IsRole(escort) → escort_lead (loop 3g-2: lights on, ahead to the
##   │                              hospital at the pace police.gd asks; waiting for the player)
##   ├ SequenceReactive  PullOver : IsPullOver → hold_still (stopped behind the player, lights on)
##   ├ SequenceReactive  Roadblock: IsRole(roadblock) → hold_or_leave (parked; 10 s, then goes)
##   ├ SequenceReactive  Blocker  : IsRole(blocker) → hold_or_leave
##   ├ SequenceReactive  Search   : IsRole(chaser), IsPhase(search) → search_area
##   ├ SequenceReactive  Chase    : IsRole(chaser) → pursue (re-planned 1 Hz by police.gd; racer AI
##   │                              step 6b part 2: on the racers' driver, police/chase_route.gd)
##   ├ SequenceReactive  Trap     : IsRole(trap) → stay_parked
##   ├ SequenceReactive  Club     : IsRole(club) → stay_parked (loop MW-3: parked by a club)
##   ├ SequenceReactive  Crash    : IsRole(crash) → attend (a crash scene's car: parked, lights on)
##   ├ SequenceReactive  GuardFollow: IsRole(guard_follow) → guard_follow (loop 3g-2: the guards'
##   │                              car after the player at 25 km/h, amber beacon; guards.gd routes)
##   ├ SequenceReactive  Guard    : IsRole(guard) → drive_as_guard (the guards' car round the zone)
##   └ drive_as_traffic

const PoliceTree := preload("res://scripts/police/police_tree.gd")
const SelectorReactive := preload("res://addons/beehave/nodes/composites/selector_reactive.gd")
const SequenceReactive := preload("res://addons/beehave/nodes/composites/sequence_reactive.gd")
const IsRole := preload("res://scripts/police/bt/is_role.gd")
const IsPhase := preload("res://scripts/police/bt/is_phase.gd")
const IsPullOver := preload("res://scripts/police/bt/is_pull_over.gd")
const UnitAction := preload("res://scripts/police/bt/unit_action.gd")

## Chasers: CHASE_SHARE of the player's own top speed (police.gd `chase_top`: the car's model, the
## Ołdi TT and the engine level; a flat-out run opens a fifth of it, 100 m in ~15 s at any speed),
## traffic's acceleration x 1.2, and the gap they keep behind the player's car (they never ram;
## police.md section 4). CHASE_TOP is the share of the default hatch's 30 m/s, the fallback.
const CHASE_SHARE := 0.8
const CHASE_TOP := 24.0
const CHASE_ACCEL := 1.2
const CHASE_GAP := 10.0
## Street races R1 for the police (2026-11-04, F: "make the racers and police smarter"): a chaser
## drives in traffic.gd's racer mode: CHASE_RACE_ACCEL m/s² (the town car's 2.2 x 1.2 = 2.6
## before), corners at CHASE_LAT m/s² sideways by the curve's radius (not the town car's 20 km/h
## right angle), through reds a little careful (not SIREN_SLOW's 30 km/h), crossing cars only
## when one is close, and round traffic that doesn't give way. Its top speed stays chase_top
## (CHASE_SHARE of the player's), so a flat-out run still escapes; corners cost the player less
## than before, not nothing (CHASE_LAT under the rivals' 7.5).
## Racer AI step 6b part 2: a chaser drives the racers' driver with ladder.gd POLICE's numbers
## (police/chase_route.gd `join`); these two are the chase without a plan (the race bench's
## `old`, the reference the POLICE profile is fitted against) and CHASE_LAT the car's grip in
## every other mode.
const CHASE_RACE_ACCEL := 6.0
const CHASE_LAT := 6.5
## Searching: to the last-seen point, then round it within SEARCH_REACH at 30 km/h.
const SEARCH_SPEED := 8.3
const SEARCH_REACH := 150.0
## A blocker or the roadblock the chase has gone past (or away from) leaves after this.
const HOLD_LEAVE := 10.0

## Its number in the log ("unit 2").
var number := 0
var police: Node
var traffic: Node3D
## The traffic Driver it drives (null while unbound).
var driver = null
var tree: Node
## police.gd's perception (5 Hz): metres to the player and whether it sees the player now.
var dist := INF
var sees := false
## It has come near the player (police.gd paces the patrol cars by it).
var met := false
## Seconds before its megaphone may speak again, and before it warns again.
var line_wait := 0.0
var warn_wait := 0.0
## Loop 3g-2, the escort: the route to the hospital (distances to its node, police.gd's cache).
var escort_route := PackedFloat32Array()
var escort_node := -1
## Blocker and roadblock: seconds the chase has been away from it, the player's closest pass.
var away := 0.0
var closest := INF
var _mode := ""


func _init(n: int) -> void:
	number = n
	name = "PoliceUnit%d" % n


## Builds the tree once (the pool's units keep theirs).
func build() -> void:
	tree = PoliceTree.new()
	tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	tree.actor = self
	var top := SelectorReactive.new()
	top.name = "Selector"
	tree.add_child(top)
	top.add_child(_branch("Escort", [_role("escort")], "escort_lead"))
	top.add_child(_branch("PullOver", [IsPullOver.new()], "hold_still"))
	top.add_child(_branch("Roadblock", [_role("roadblock")], "hold_or_leave"))
	top.add_child(_branch("Blocker", [_role("blocker")], "hold_or_leave"))
	var in_search := IsPhase.new()
	in_search.phase = "search"
	top.add_child(_branch("Search", [_role("chaser"), in_search], "search_area"))
	top.add_child(_branch("Chase", [_role("chaser")], "pursue"))
	top.add_child(_branch("Trap", [_role("trap")], "stay_parked"))
	# Loop MW-3: a car parked by a club (police.gd club_park) just stays.
	top.add_child(_branch("Club", [_role("club")], "stay_parked"))
	# The crash scenes: a car at a scene (police.gd scene_car) stands there, lights on.
	top.add_child(_branch("Crash", [_role("crash")], "attend"))
	top.add_child(_branch("GuardFollow", [_role("guard_follow")], "guard_follow"))
	top.add_child(_branch("Guard", [_role("guard")], "drive_as_guard"))
	top.add_child(_action("drive_as_traffic"))
	add_child(tree)


func _branch(label: String, conditions: Array, behaviour: String) -> Node:
	var seq := SequenceReactive.new()
	seq.name = label
	for c: Node in conditions:
		seq.add_child(c)
	seq.add_child(_action(behaviour))
	return seq


func _role(r: String) -> Node:
	var c := IsRole.new()
	c.role = r
	c.name = "Is_" + r
	return c


func _action(behaviour: String) -> Node:
	var a := UnitAction.new()
	a.behaviour = behaviour
	a.name = behaviour
	return a


func role() -> String:
	return tree.blackboard.get_value("role", "")


func set_role(r: String) -> void:
	tree.blackboard.set_value("role", r)


func bind(d, r: String) -> void:
	driver = d
	_mode = ""
	dist = INF
	sees = false
	met = false
	line_wait = 0.0
	warn_wait = 0.0
	away = 0.0
	tree.blackboard.set_value("pullover", false)
	tree.blackboard.set_value("phase", "calm")
	set_role(r)


func unbind() -> void:
	if tree.status == BeehaveTree.RUNNING:
		tree.interrupt()
	tree.status = -1
	driver = null
	set_role("")
	_mode = ""


## police.gd, 5 times a second.
func tick() -> void:
	if driver != null and driver.active:
		tree.tick()


# --- behaviours (the trees' actions) --------------------------------------------------------

## A patrol in traffic: obeys the lights, at 0.95 of the road's speed, lights off.
func drive_as_traffic() -> int:
	if _mode != "traffic":
		_mode = "traffic"
		_racer(false)
		var d = driver
		traffic.set_lights(d, false)
		d.chase = false
		d.v_cap = 0.0
		d.keep_gap = 2.4
		d.goal = Vector2.INF
		d.accel_factor = 1.0
		d.held = false
		if not d.route.is_empty():
			traffic.stop_racing(d)
		# Back to the band's rules: it may leave when out of sight.
		d.persistent = false
	return BeehaveNode.RUNNING


## The chaser: lights on, after the player on the lane graph (police.gd re-plans the route once
## a second, one unit a frame), never closer than CHASE_GAP behind, slow through reds; on the
## racers' driver (step 6b part 2, `arm_chase`).
func pursue() -> int:
	if _mode != "chase":
		_mode = "chase"
		if driver.parked:
			police.pull_out(self)
		arm_chase(driver, traffic, police.chase_route, police.chase_top())
		police.request_replan(self)
	# Every tick: a car swapped or tuned at the garage mid-chase changes the pace at once.
	driver.v_cap = police.chase_top()
	return BeehaveNode.RUNNING


## Searching: to where it last saw the player, then round there at 30 km/h (police.gd picks the
## spots; lights stay on, no siren).
func search_area() -> int:
	var d = driver
	if _mode != "search":
		_mode = "search"
		_racer(false)
		if d.parked:
			police.pull_out(self)
		traffic.set_lights(d, true)
		d.chase = false
		d.held = false
		d.persistent = true
		d.v_cap = SEARCH_SPEED
		d.keep_gap = CHASE_GAP
		police.request_replan(self)
	elif d.arrived or d.route.is_empty():
		police.request_replan(self)
	return BeehaveNode.RUNNING


## Pulled over with the player: stopped where it is (a few metres behind), lights on.
func hold_still() -> int:
	if _mode != "hold":
		_mode = "hold"
		_racer(false)
		traffic.set_lights(driver, true)
		driver.held = true
	return BeehaveNode.RUNNING


## A speed trap's car: parked on the shoulder, lights off (the officer does the waving).
func stay_parked() -> int:
	if _mode != "parked":
		_mode = "parked"
		_racer(false)
		traffic.set_lights(driver, false)
	return BeehaveNode.RUNNING


## The crash scenes: parked at the scene with the lights on (crash_scenes.gd clears it).
func attend() -> int:
	if _mode != "crash":
		_mode = "crash"
		_racer(false)
		traffic.set_lights(driver, true)
		driver.held = true
	return BeehaveNode.RUNNING


## A blocker or the roadblock: parked at its junction with the lights on; once the chase has
## been away from it HOLD_LEAVE seconds (gone past, turned off, over), it goes (police.gd).
func hold_or_leave() -> int:
	if _mode != "block":
		_mode = "block"
		_racer(false)
		traffic.set_lights(driver, true)
		away = 0.0
		closest = INF
	# Waiting while the player comes nearer; gone past or turned off: going away from it.
	if not police.chasing() or dist > closest + 40.0:
		away += police.TICK
	else:
		away = 0.0
	closest = minf(closest, dist)
	if away >= HOLD_LEAVE:
		police.dismiss(self)
	return BeehaveNode.RUNNING


# --- loop 3g-2: the escort and the guards' car ------------------------------------------------

## Escorting a rescue to the hospital: lights and siren, along the route, at the pace police.gd
## writes on the blackboard (`escort_v` m/s; `escort_wait`: stopped, waiting for the player).
## Through reds slowly like a chaser; traffic ahead gives way.
func escort_lead() -> int:
	var d = driver
	if _mode != "escort":
		_mode = "escort"
		_racer(false)
		if d.parked:
			police.pull_out(self)
		traffic.set_lights(d, true)
		d.chase = true
		d.persistent = true
		d.accel_factor = CHASE_ACCEL
		d.keep_gap = 8.0
		d.goal = Vector2.INF
		if escort_node >= 0:
			traffic.race_to(d, escort_node, escort_route)
	d.held = tree.blackboard.get_value("escort_wait", false)
	d.v_cap = maxf(float(tree.blackboard.get_value("escort_v", police.chase_top())), 2.0)
	return BeehaveNode.RUNNING


## The guards' car round the zone: lights off, the traffic's pace; guards.gd takes it away.
func drive_as_guard() -> int:
	if _mode != "guard":
		_mode = "guard"
		_racer(false)
		var d = driver
		traffic.set_lights(d, false)
		d.chase = false
		d.v_cap = 0.0
		d.keep_gap = 2.4
		d.goal = Vector2.INF
		d.accel_factor = 1.0
		d.held = false
		if not d.route.is_empty():
			traffic.stop_racing(d)
		d.persistent = true
	return BeehaveNode.RUNNING


## The guards' car after the player in a zone: the amber beacon, at most 25 km/h, keeping 8 m
## (guards.gd routes it to the player's nearest node once a second).
func guard_follow() -> int:
	if _mode != "guard_follow":
		_mode = "guard_follow"
		_racer(false)
		var d = driver
		traffic.set_lights(d, true)
		d.chase = false
		d.held = false
		d.v_cap = 25.0 / 3.6
		d.keep_gap = 8.0
	return BeehaveNode.RUNNING


## Racer mode off in every mode but the chase (step 6b part 2: and the unit out of the chase's
## session, police/chase_route.gd `leave`).
func _racer(on: bool) -> void:
	if driver == null:
		return
	if not on and police != null and police.chase_route != null:
		police.chase_route.leave(driver)
	racer_mode(driver, on)
	if not on:
		driver.race_brake = 0.0
		driver.race_share = 1.0


## Racer mode as the chase had it before step 6b part 2 (CHASE_RACE_ACCEL above; on), or off.
static func racer_mode(d, on: bool) -> void:
	d.race_accel = CHASE_RACE_ACCEL if on else 0.0
	d.race_lat = CHASE_LAT
	d.race_top = 0.0
	d.race_effort = 1.0
	d.pass_t = 0.0


## A chaser armed as `pursue` arms it (the race bench's `chase` arms its chasers here too): lights
## on, after the player, kept CHASE_GAP behind, never parked or held, its top `top` (m/s,
## police.gd `chase_top`; re-read every tick by `pursue`), and on the racers' driver through
## `route` (police/chase_route.gd `join`: a racer of the chase's session with ladder.gd POLICE's
## numbers; with `route.planned` off, the old racer mode alone).
static func arm_chase(d, traffic_node, route, top: float) -> void:
	racer_mode(d, true)
	traffic_node.set_lights(d, true)
	d.chase = true
	d.held = false
	d.persistent = true
	d.accel_factor = CHASE_ACCEL
	d.keep_gap = CHASE_GAP
	d.v_cap = top
	if route != null:
		route.join(d, top, Vector2(d.speed_factor, CHASE_ACCEL))
