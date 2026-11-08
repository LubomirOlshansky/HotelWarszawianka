extends Node
## Loop 3g-1 (police, part one; docs/design/police.md): the gentle police. Warnings and jokes,
## never a fine: nothing here ever writes the złoty (an escape adds +15 respect through
## wallet.add_respect, the joke notebook counts cautions), nobody is arrested, nothing is rammed,
## and every chase ends by itself (30 / 40 / 45 s, "Koniec zmiany!").
##
## - Patrol cars drive in the traffic (traffic.gd's POLICE kind, 0 / 1 / 2 / 3 by the Traffic
##   level); speed traps ("suszarka") stand at 3 of the spots in data/police_traps.json each
##   day, picked by the date like the roadworks, an officer by the parked car (a pedestrian
##   instance) who waves the lizak at a speeder.
## - Perception 5 times a second, one pass for every unit: distance, a 180° cone in front of a
##   patrol car, sight by a walk through the roof grid (map_builder.gd roof_height); the
##   player's lane and speed limit from the lane graph. Offences: speeding past a patrol car, a
##   red light, the wrong way, a bump; a ram counts double. Two strikes in 45 s start koguty 1.
## - The state machine of police.md section 4 lives here (CALM, LIZAK, CHASE at level 1-3,
##   SEARCH, PULLOVER; then a 180 s cooldown); each unit's beehave tree only moves its car
##   (police/police_unit.gd), ticked right after the perception pass.
## - Escaping (120 m from every chaser, or 4 s out of sight, then 8 s of searching; 4 s in a
##   hiding spot: under a bridge deck or in a tunnel) pays +15 respect; stopping by a chaser
##   (1.5 s under 1 m/s within 15 m) or by the officer opens the pull-over (Dialogue Manager,
##   game/dialogue/police.dialogue; police/police_balloon.gd), which ends in a caution.
## - The HUD (hud.gd): the koguty, the pill with the end-of-shift countdown, the edge breath, an
##   edge rooster for an off-screen chaser, the lizak, chasers and known traps on the minimap.
##   The light bars flash in actor.gdshader (SIREN); at night their halos and the koguty-3
##   searchlight are one glow MultiMesh.
##
## Part two (loop 3g-2; police.md 5.6, 8): a rescue in pickup or drop-off is never seen and
## accepting one ends a chase; with the person aboard a patrol car escorts the player to the
## hospital (+10 s on the clock); a race seen pulls in koguty 1 and escaping it marks the race
## (+20 % on a win, rivals.gd); the kebab's heat stands still during the card; the scripted
## first contact after the first race (once per save); the city guards (police/guards.gd: the
## zone pill, the whistle and the run, the guards' car, the guard conversation, the clamp).
## Phantom Camera's chase framing and the PixelLab portraits are still to come.

## Night meets (street_meet.gd): a chase or a pull-over ended, and how (`_end`'s words).
signal chase_ended(how: String)

## Time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0
## The night-buses loop (E25, buses.gd): times a speed trap caught the player speeding past it.
var trap_flashes := 0

const Access := preload("res://scripts/access.gd")
const Chatter := preload("res://scripts/chatter.gd")
const Unit := preload("res://scripts/police/police_unit.gd")
const Talk := preload("res://scripts/police/police_talk.gd")
const Balloon := preload("res://scripts/police/police_balloon.gd")
## Loop 3g-2: the city guards.
const Guards := preload("res://scripts/police/guards.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const TRAPS_PATH := "res://data/police_traps.json"
const DIALOGUE_PATH := "res://dialogue/police.dialogue"
const DIALOGUE_MANAGER := "res://addons/dialogue_manager/dialogue_manager.gd"

enum Phase { CALM, LIZAK, CHASE, SEARCH, PULLOVER }
const PHASES := ["calm", "lizak", "chase", "search", "pullover"]

## Perception and the trees: 5 times a second.
const TICK := 0.2
## Patrol cars in the band by Traffic level (Empty, Low, Normal, Busy), and the pool (traffic.gd).
const PATROLS := [0, 1, 2, 3]
const POOL := 8
## After a patrol car the player met (came within MET m of) leaves the band, the next comes
## PATROL_GAP s later (*guess*: a 10-minute drive should meet ~2 to 4); after one they never met,
## PATROL_MISSED s later.
const PATROL_GAP := Vector2(90.0, 180.0)
const PATROL_MISSED := 10.0
const MET := 80.0
## No chase in the session's first START_GRACE s (warnings from WARN_FROM s) or COOLDOWN s after
## one; a ram still starts one in the cooldown. The grace ends early once the police have met
## the player (a chase or a pull-over).
const START_GRACE := 180.0
const WARN_FROM := 60.0
const COOLDOWN := 180.0
## Two strikes within STRIKE_FADE s start koguty 1; one fades every STRIKE_FADE s.
const STRIKE_FADE := 45.0
## A chase's cap from its start by its highest level; no level rises in its last NO_RISE s; a
## ram raises the level at most once every RAM_GAP s.
const CAPS := [30.0, 40.0, 45.0]
const NO_RISE := 10.0
const RAM_GAP := 10.0
## Escape: ESCAPE_DIST from every chaser, or UNSEEN s out of sight; then SEARCH s (SEARCH_HIDDEN
## in a hiding spot), unless a unit sees the player again within RESEEN m.
const ESCAPE_DIST := 100.0
const UNSEEN := 4.0
const SEARCH := 8.0
const SEARCH_HIDDEN := 4.0
const RESEEN := 50.0
## A second unit that sees the player this close raises the level, once the level has held
## LEVEL_HOLD s (*guess*: a patrol that happens to be near when a chase starts doesn't make it
## koguty 2 at once).
const SECOND_UNIT := 60.0
const LEVEL_HOLD := 5.0
## Pulling over: under PULL_SPEED m/s with a chaser's bumper within PULL_DIST m, PULL_HOLD s.
const PULL_DIST := 15.0
const PULL_SPEED := 1.0
const PULL_HOLD := 1.5
const ESCAPE_RESPECT := 15
## Offences (police.md section 3).
const SPEED_OVER := 25.0 / 3.6
const SPEED_REACH := 40.0
const RED_REACH := 60.0
const WRONG_WAY := 3.0
const BUMP := 2.0
const RAM := 6.0
## Sight: eye heights (m), the roof grid's step, the farthest a unit sees.
const EYE := 2.2
const TARGET_EYE := 1.2
const SIGHT_STEP := 4.0
const SIGHT_REACH := 160.0
## Speed traps: limit + TRAP_OVER inside the RADAR m before the officer; stop within LIZAK_STOP
## m under LIZAK_SLOW → pull-over; LIZAK_PAST m past → koguty 1; stopped elsewhere
## LIZAK_GIVE_UP s → calm; re-arms after TRAP_REARM s. Cars come within TRAP_BAND m.
const TRAP_OVER := 20.0 / 3.6
const RADAR := 40.0
const LIZAK_STOP := 20.0
const LIZAK_SLOW := 8.0 / 3.6
const LIZAK_PAST := 30.0
const LIZAK_GIVE_UP := 6.0
const LIZAK_LONGEST := 15.0
const TRAP_REARM := 60.0
const TRAPS_A_DAY := 3
const TRAP_BAND := 320.0
## Megaphone lines: one every MEGAPHONE_GAP s in the city, UNIT_GAP s per unit; in a chase the
## untagged lines every CHASE_LINES s.
const MEGAPHONE_GAP := 8.0
const UNIT_GAP := 20.0
const CHASE_LINES := Vector2(10.0, 12.0)
## Chasers re-plan once a second (one unit a frame), the search bounded at MAX_COST m.
const MAX_COST := 800.0
const REPLAN := 1.0
## No patrol car appears within this of the player during the cooldown.
const COOLDOWN_SPAWN := 200.0
## The pull-over: a line's time, the reply's auto-pick, the longest it may take.
const BEAT := 2.4
const REPLY_AUTO := 5.0
const TALK_LONGEST := 12.0
## The officer's lemon hi-vis and navy trousers (the trousers palette's first, actor.gdshader).
const OFFICER_SHIRT := Color("#e8f23a")
const OFFICER_TROUSERS := 0.1
## Halos at night: blue and red pools on the road beside a flashing car; the searchlight.
const HALO_SIZE := 5.0
const HALO_BLUE := Color(0.24, 0.48, 1.0, 1.0)
const HALO_RED := Color(1.0, 0.23, 0.23, 0.8)
## Colour-safe: white instead of red beside the blue.
const HALO_SAFE := Color(1.0, 0.97, 0.88, 0.8)
const SEARCHLIGHT := 9.0
## Test drivers (--police-auto, the soak's roaming autopilot).
const ESCAPE_TOP := 30.0

## Loop 3g-2, the escort (police.md 8.1, 14): a patrol car within ESCORT_JOIN m joins, else one is
## placed out of sight ESCORT_AHEAD m (up to ESCORT_FAR m) ahead on the route (always on the
## session's first rescue, then ESCORT_CHANCE of the time, *guess*); it keeps ESCORT_LEAD m
## ahead along the route, waits while the player is over ESCORT_WAIT m behind, drops behind once
## overtaken by ESCORT_PASSED m; +ESCORT_BONUS s on the rescue clock.
const ESCORT_JOIN := 200.0
const ESCORT_AHEAD := 150.0
const ESCORT_FAR := 400.0
const ESCORT_CHANCE := 0.5
const ESCORT_LEAD := Vector2(15.0, 25.0)
const ESCORT_WAIT := 60.0
const ESCORT_PASSED := 4.0
const ESCORT_BONUS := 10.0
## The escort's own pace in the 15-25 m band (m/s, 45 km/h, *guess*).
const ESCORT_PACE := 12.5
## It stops this many metres before the route's end (the hospital) and waits for the hand-over.
const ESCORT_THERE := 20.0
const ESCORT_SPEAKER := "Sierżant Bogdan"
## Loop 3g-2, races (police.md 3, 8.2): a race seen within this of a patrol car or a trap.
const RACE_REACH := 60.0
## Loop 3g-2, the first contact (police.md 1, 5.2): set up FIRST_DELAY s after the first race,
## the car parked FIRST_AHEAD m ahead on the player's road; dropped (and set up again
## FIRST_RETRY s later) if the player goes FIRST_DROP m away or FIRST_LONGEST s pass.
const FIRST_KEY := "police_first_contact"
const FIRST_DELAY := 6.0
const FIRST_AHEAD := 150.0
const FIRST_DROP := 450.0
const FIRST_LONGEST := 90.0
const FIRST_RETRY := 20.0
const FIRST_TRIES := 4
const FIRST_SLOT := 3
const HOLD_SPEED := 1.6
const ROAM_OVER := 2.0

## Set by main.gd.
var map: Node3D
var graph: LaneGraph
var traffic: Node3D
var car: CharacterBody3D
var cam: Camera3D
var hud: CanvasLayer
var bubbles: Control
var dialogue: Node
var wallet: Node
var walkers: Node3D
var radio: Node
var sfx: Node3D
var jobs: Node
var missions: Node
var tod: Node
## Loop 3g-2: the rivals (a race seen), the pedestrian zones (guards.gd) and the zone the car is in
## now (main.gd sets it every frame).
var rivals: Node
var ped_zones: RefCounted
var zone := ""
## F's asks (2026-10-30): the zones' 20 km/h cap is on (Settings → JAZDA; off by default): the
## guards' zone pill and whistle only then (main.gd sets it every frame).
var zone_cap := false
var guards: Guards
## World position -> HUD pixels.
var project: Callable
## The player is in the helicopter (main.gd, every frame).
var flying := false
## Loop MW-6: Spacer (spacer.gd, vision.md 4.3): the speed traps give the warning only, nothing
## chases (the gentle joke stays: the megaphone line).
var gentle := false
## Flags (main.gd parses them; README's flags table).
var opts := {}
var now := false
var log_on := false
var auto := ""
## --pedal (main.gd's hold_pedal) and --autopilot, for the test drivers.
var pedal := ""
var autopilot := false
## The Traffic level now (Settings can change it): the patrol count follows.
var level_now: Callable

var phase := Phase.CALM
var level := 0
var top_level := 0
var strikes := 0
## Seconds of play, of the cooldown left, of the chase (from its start).
var clock := 0.0
var cooldown := 0.0
var chase_t := 0.0
var grace_over := false
var chases_started := 0
var chases_ended := 0
var day := 0
var _in_chase := false

var _units: Array = []
var _free: Array = []
var _unit_of := {}
var _engaged: Array = []
var _replans: Array = []
var _planned := {}
var _tick_t := 0.0
var _frame := 0
var _strike_t := 0.0
var _megaphone := 0.0
var _chase_line := 0.0
var _rise_wait := 0.0
var _level_at := 0.0
var _unseen := 0.0
## The raid's hold left (s; RAID_HOLD from police.raid), 0 outside a raid's chase.
var _raid_t := 0.0
## The chase came from a raid (RAID_ESCAPE counts), until it ends.
var raid_chase := false
var _search_t := 0.0
var _still := 0.0
var _last_seen := Vector3.ZERO
var _rewarded := false
var _zl0 := 0
## The player on the lane graph (5 Hz): edge, s, the road's limit (m/s), red light / wrong way.
var _edge := -1
var _s := 0.0
var _limit := 50.0 / 3.6
var _ran_red := false
var _wrong_t := 0.0
var _pill_note := ""
var _pill_note_en := ""
var _pill_note_t := 0.0
## Speed traps: today's active ones in the map (dictionaries), the one waving.
var traps: Array = []
var _lizak_trap: Dictionary = {}
var _lizak_t := 0.0
var _lizak_still := 0.0
var _today := 0
var _traps_announced := -1.0e9
## The pull-over.
var talk: Talk
var _talk_unit = null
var _talk_tag := ""
var _line = null
var _beat_t := 0.0
var _talk_t := 0.0
var _caution_n := 0
var _routine := false
var _balloon: Control
var _dm: Node
var _resource: Resource
## Halos and the searchlight (night).
var _halo_mm: MultiMesh
var _halo_mmi: MultiMeshInstance3D
var _halo_buf := PackedFloat32Array()
## Test drivers.
var _ghost = null
var _mask := -1
var _auto_flip := 0
var _offences: Array = []
var _b4_t := 0.0
## The soak's B4: the closest the car came to a screen edge in a chase (a share of the screen).
var _b4_worst := 1.0
var _lane_worst := 0.0

## Loop 3g-2, the escort: its unit, the hospital node's route (cached by node), the state ("lead",
## "behind"), the rescue it belongs to, and the session's rescues so far.
var _escort = null
var _escort_routes := {}
var _escort_state := ""
var _escort_for := -1
var _escort_tried := -1
var _rescues := 0
var _escort_said := false
var _escort_flip := 0.0
var _escort_lead := INF
## Loop 3g-2: a race seen while no chase could start (logged once a race).
var _race_noted := false
## Loop 3g-2: the kebab's heat stood still for the card.
var _froze_heat := false
## Loop 3g-2, the first contact: its spot (a trap's dictionary) while set up, the wait before
## the next set-up (-1: not armed), the tries this session.
var _first: Dictionary = {}
var _first_wait := -1.0
var _first_t := 0.0
var _first_tries := 0
## Loop 3g-2: the guard in the conversation (null for a police pull-over).
var _guard = null
## Loop 3g-2, test drivers: --guards' waypoints.
## Loop MW-3 (vision.md 3.1): the patrol cars parked by the clubs (crowds.gd `club_park`): club id
## -> {e, s, lane, car: Vector2, yaw, unit}. Role "club": parked, sees nothing, starts nothing.
var _clubs := {}
var _waypoints: Array[Vector2] = []
var _waypoints_done := false
var _follow_last := false


func setup(nodes: Dictionary, data: Dictionary, world: Node3D) -> void:
	for k in nodes:
		set(k, nodes[k])
	now = opts.get("now", false)
	log_on = opts.get("log", false)
	auto = String(opts.get("auto", ""))
	day = int(opts.get("day", 0))
	if day == 0:
		var d := Time.get_date_dict_from_system()
		day = int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
	_today = day
	for t in String(opts.get("offences", "")).split(",", false):
		var fk := t.split(":")
		if fk.size() == 2:
			_offences.append([int(fk[0]), fk[1]])
	for i in POOL:
		var u := Unit.new(i + 1)
		u.police = self
		u.traffic = traffic
		u.build()
		add_child(u)
		_units.append(u)
		_free.append(u)
	traffic.police_spawned.connect(_on_spawned)
	traffic.police_released.connect(_on_released)
	traffic.bumped_police.connect(_on_bumped)
	traffic.police_target = PATROLS[clampi(int(opts.get("traffic_level", 2)), 0, 3)]
	traffic.patrol_wait = 5.0 if now else 20.0
	_load_traps(data)
	_build_halos(world)
	_balloon = Balloon.new()
	_balloon.pt = hud.pt
	hud.add_panel(_balloon, "bottom")
	_balloon.advanced.connect(_on_tap)
	_balloon.replied.connect(_on_reply)
	# Loop 3g-2: the city guards; accepting a rescue ends a chase.
	guards = Guards.new()
	guards.name = "Guards"
	add_child(guards)
	guards.setup(self)
	if missions != null and missions.has_signal("accepted"):
		missions.accepted.connect(_on_rescue_accepted)
	if radio != null:
		radio.station_changed.connect(_on_station)
	# Dialogue Manager and the conversation now, while the city builds (~70 ms on the Mac): at the
	# first pull-over it would be a hitch just as the card opens.
	_ensure_dm()
	_zl0 = wallet.zl
	_log("start (%s, traffic %d patrols, wallet %d zł)" % ["no grace, no cooldown" if now else "grace %d s" % int(START_GRACE),
			traffic.police_target, wallet.zl])


func _exit_tree() -> void:
	if wallet != null:
		_log("wallet %d zł → %d zł (end; chases %d started, %d ended%s; b4 closest to an edge %.2f; lanes worst %.2f m)" % [
				_zl0, wallet.zl, chases_started, chases_ended, ", 1 running" if _in_chase else "", _b4_worst, _lane_worst])
	_untangle()
	if _dm != null and Engine.has_singleton("DialogueManager") and Engine.get_singleton("DialogueManager") == _dm:
		Engine.unregister_singleton("DialogueManager")


## Dialogue Manager 4.1.0 writes each line it reads back into the resource's own `lines` (a
## line's data gets `resource` = the resource itself): a reference cycle that leaked the
## resource at exit ("1 resources still in use"). Cleared after every conversation.
func _untangle() -> void:
	if _resource != null:
		for data in _resource.lines.values():
			(data as Dictionary).erase("resource")


func _log(text: String) -> void:
	if log_on:
		print("police: %s (frame %d, %.1f s)" % [text, _frame, clock])


# --- the frame -------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or graph == null:
		return
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _step(dt: float) -> void:
	_frame += 1
	clock += dt
	cooldown = maxf(0.0, cooldown - dt)
	_megaphone -= dt
	_chase_line -= dt
	_rise_wait -= dt
	_pill_note_t -= dt
	if strikes > 0:
		_strike_t += dt
		if _strike_t >= STRIKE_FADE:
			strikes -= 1
			_strike_t = 0.0
	traffic.police_min_dist = COOLDOWN_SPAWN if cooldown > 0.0 else 0.0
	_test_frame()
	if flying and phase in [Phase.CHASE, Phase.SEARCH]:
		_end("heli")
	_tick_t += dt
	if _tick_t >= TICK:
		_tick_t -= TICK
		_perceive()
		_escort_tick()
		guards.zone = zone
		guards.zone_cap = zone_cap
		guards.tick()
		_clubs_tick()
		for u in _units:
			if u.driver != null:
				u.tree.blackboard.set_value("phase", PHASES[phase])
				u.tick()
	guards.frame(dt)
	_first_frame(dt)
	match phase:
		Phase.LIZAK:
			_lizak_frame(dt)
		Phase.CHASE, Phase.SEARCH:
			_chase_frame(dt)
		Phase.PULLOVER:
			_talk_frame(dt)
	_traps_frame()
	_replan_one()
	_hud_frame()
	_halos_frame()


# --- units -----------------------------------------------------------------------------------

func _on_spawned(d) -> void:
	_bind(d, "patrol")


func _on_released(d) -> void:
	var u = _unit_of.get(d)
	if u != null:
		if d.patrol and u.role() == "patrol":
			# The next patrol car: a while after one the player met, soon after one they didn't.
			traffic.patrol_wait = maxf(traffic.patrol_wait, randf_range(PATROL_GAP.x, PATROL_GAP.y) if u.met else PATROL_MISSED)
		_unbind(u)


func _bind(d, role: String):
	if _free.is_empty():
		return null
	var u = _free.pop_back()
	u.bind(d, role)
	_unit_of[d] = u
	return u


func _unbind(u) -> void:
	_unit_of.erase(u.driver)
	_engaged.erase(u)
	_replans.erase(u)
	for t in traps:
		if t["unit"] == u:
			t["unit"] = null
			_officer(t, false)
	for c: Dictionary in _clubs.values():
		if c["unit"] == u:
			c["unit"] = null
	if _talk_unit == u:
		_talk_unit = null
	u.unbind()
	_free.append(u)


## A unit's car leaves the street (out of sight), or, on screen, rejoins the traffic.
func dismiss(u) -> void:
	if u.driver == null:
		return
	_engaged.erase(u)
	if traffic.on_screen(u.driver.pos, 2.0):
		if u.driver.parked:
			pull_out(u)
		u.set_role("patrol")
	else:
		traffic.remove(u.driver)


## A parked unit (a trap's car, a blocker) pulls out onto its road's outer lane.
func pull_out(u) -> void:
	var d = u.driver
	var e: int = d.edge
	var lane: int = graph.e_lanes[e] - 1
	traffic.unpark(d, e, lane, clampf(d.s, graph.e_s0[e] + 1.0, graph.e_s1[e] - 1.0))
	for t in traps:
		if t["unit"] == u:
			t["unit"] = null
			_officer(t, false)


## G13 leftovers (2026-11-02): the chasers' and the escort's top speed, Unit.CHASE_SHARE of the
## player's own (car.gd max_speed x top_mult: the Ołdi TT and the engine levels), so a bought car
## never outruns every patrol at a walk. The nitro's lift is left out on purpose: a burn is the one
## way to open a quick gap. A stand-in car without the fields gets the hatch's CHASE_TOP.
func chase_top() -> float:
	if car == null or not ("top_mult" in car and "max_speed" in car):
		return Unit.CHASE_TOP
	return float(car.max_speed) * float(car.top_mult) * Unit.CHASE_SHARE


func chasing() -> bool:
	return phase == Phase.CHASE or phase == Phase.SEARCH


func request_replan(u) -> void:
	if not u in _replans:
		_replans.append(u)


## One route a frame at most: the chasers by turns once a second, and anyone who asked.
func _replan_one() -> void:
	if _replans.is_empty():
		for u in _engaged:
			if u.role() == "chaser" and clock - float(_planned.get(u, -99.0)) >= REPLAN:
				_replans.append(u)
				break
	if _replans.is_empty():
		return
	var u = _replans.pop_front()
	if u.driver == null or not u.driver.active or u.driver.parked:
		return
	_planned[u] = clock
	var d = u.driver
	var p := _xz(car.global_position)
	var node := -1
	if phase == Phase.SEARCH:
		var seen := _xz(_last_seen)
		if Vector2(d.pos.x, d.pos.z).distance_to(seen) > 30.0 and not d.arrived:
			node = graph.nearest_node(seen)
		else:
			node = _wander_node(seen)
	elif _edge >= 0 and graph.node_pos[graph.e_b[_edge]].distance_to(p) < 400.0:
		node = graph.e_b[_edge]
	else:
		node = graph.nearest_node(p)
	if node < 0:
		return
	d.goal = graph.node_pos[node]
	traffic.race_to(d, node, graph.distances_to(node, MAX_COST))


## A node within the search reach of the last-seen point (police_unit.gd SEARCH_REACH).
func _wander_node(around: Vector2) -> int:
	var picks: Array[int] = []
	for n in graph.node_pos.size():
		if graph.node_scc[n] != 0 and graph.node_pos[n].distance_to(around) < Unit.SEARCH_REACH:
			picks.append(n)
	return picks[randi() % picks.size()] if not picks.is_empty() else graph.nearest_node(around)


# --- perception (5 Hz, one pass) -------------------------------------------------------------

func _perceive() -> void:
	var p := car.global_position
	var hidden := _hidden(p)
	var in_car := not flying
	if level_now.is_valid():
		traffic.police_target = PATROLS[clampi(level_now.call(), 0, 3)]
	_track_player()
	for u in _units:
		u.line_wait -= TICK
		u.warn_wait -= TICK
		var d = u.driver
		if d == null:
			continue
		u.dist = Vector2(d.pos.x - p.x, d.pos.z - p.z).length()
		u.sees = in_car and u.dist < SIGHT_REACH and (not hidden or u.dist < 15.0) and _sight(d.pos, p)
		if u.dist < MET:
			u.met = true
	if in_car and _may_offend():
		_offences_seen()
		_race_seen()
	if log_on and _frame % 3600 < 12 and _frame > 12:
		var cars := 0
		for u in _units:
			cars += int(u.driver != null)
		_log("status: %s at %d,%d, %d km/h, %d police cars, strikes %d" % [PHASES[phase], roundi(p.x), roundi(p.z),
				roundi(car.vel.length() * 3.6), cars, strikes])
	if phase == Phase.CHASE and clock - _level_at >= LEVEL_HOLD:
		for u in _units:
			# A second unit seeing the player close joins and raises the level.
			if u.driver != null and not u in _engaged and u.role() == "patrol" and u.sees and u.dist < SECOND_UNIT:
				if _raise("second unit %d" % u.number):
					_engage(u, "chaser")
	_lane_check()


## The player on the lane graph: the road (its limit), stop lines crossed on red, the wrong way.
func _track_player() -> void:
	if flying:
		_edge = -1
		return
	var p := _xz(car.global_position)
	var v := _xz(car.vel)
	var speed := v.length()
	var fwd := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit: Array = graph.snap(p, 7.0, fwd if speed > 1.0 else Vector2.ZERO)
	if hit.is_empty():
		var any: Array = graph.snap(p, 7.0)
		if not any.is_empty() and speed > 3.0 and graph.e_reverse[any[0]] < 0 \
				and graph.direction(any[0], any[2]).dot(v / speed) < -0.5:
			_wrong_t += TICK
		else:
			_wrong_t = 0.0
		_edge = -1
		return
	_wrong_t = 0.0
	var e: int = hit[0]
	var s: float = hit[2]
	if e == _edge and s > _s:
		var stops: PackedFloat32Array = graph.e_stops[e]
		for k in range(0, stops.size(), 3):
			var at := stops[k]
			if _s + 2.0 < at and s + 2.0 >= at and graph.light(int(stops[k + 1]), int(stops[k + 2])) == LaneGraph.RED:
				_ran_red = true
	_edge = e
	_s = s
	_limit = graph.e_speed[e]


func _may_offend() -> bool:
	if phase == Phase.PULLOVER or phase == Phase.LIZAK:
		return false
	# Loop 3g-2: a rescue in PICKUP or DROPOFF (the escort) perceives nothing.
	if _rescue_on():
		return false
	return true


## Loop 3g-2 (police.md 8.1): a rescue in PICKUP or DROPOFF: the police see nothing, start nothing.
func _rescue_on() -> bool:
	return missions != null and missions.has_target()


## Nothing police-side is going on (guards.gd: talks and the clamp wait for it).
func calm() -> bool:
	return phase == Phase.CALM


## Loop 3g-2 (police.md 3, 8.2): a street race within 60 m of a patrol car or a trap's car, in
## sight: koguty 1 on the player (the rival keeps racing; rivals don't see the police).
func _race_seen() -> void:
	if phase != Phase.CALM or rivals == null or not rivals.in_race():
		_race_noted = false if rivals == null or not rivals.in_race() else _race_noted
		return
	for u in _units:
		if u.driver == null or not u.role() in ["patrol", "trap"] or not u.sees or u.dist >= RACE_REACH:
			continue
		if _may_chase():
			_start_chase(1, u, "race seen, unit %d %.0f m away" % [u.number, u.dist])
		elif not _race_noted:
			_race_noted = true
			_log("race seen by unit %d (%s)" % [u.number, "cooldown" if cooldown > 0.0 else "grace"])
		return


func _offences_seen() -> void:
	var speed: float = car.vel.length()
	var p := car.global_position
	for u in _units:
		if u.driver == null or u.role() != "patrol" or not u.sees or u.warn_wait > 0.0:
			continue
		var d = u.driver
		var to := Vector2(p.x - d.pos.x, p.z - d.pos.z)
		var ahead := Vector2(-sin(d.yaw), -cos(d.yaw))
		var in_cone := to.dot(ahead) >= 0.0
		if in_cone and u.dist < SPEED_REACH and speed > _limit + SPEED_OVER:
			_offence("speed", u)
			return
		if _ran_red and u.dist < RED_REACH:
			_ran_red = false
			_offence("red", u)
			return
		if _wrong_t >= WRONG_WAY and u.dist < RED_REACH:
			_wrong_t = 0.0
			_offence("oneway", u)
			return
	_ran_red = false


## Is the line between a unit's eye and the player's car clear of the roof grid?
func _sight(a: Vector3, b: Vector3) -> bool:
	var from := a + Vector3(0, EYE, 0)
	var to := b + Vector3(0, TARGET_EYE, 0)
	var n := int(Vector2(to.x - from.x, to.z - from.z).length() / SIGHT_STEP)
	for k in range(1, n):
		var q := from.lerp(to, float(k) / n)
		if map.roof_height(q.x, q.z) > q.y:
			return false
	return true


## Hiding spots: under a bridge deck or in a tunnel.
func _hidden(p: Vector3) -> bool:
	if flying:
		return false
	return map.in_tunnel(p.x, p.z, p.y) or map.ground_height(p.x, p.z) > p.y + 3.0


# --- offences and the state machine ----------------------------------------------------------

## An offence seen by `u` (null for a test's): a warning and a strike, or a chase.
func _offence(kind: String, u) -> void:
	if _rescue_on() and not chasing():
		_log("%s seen, on a rescue (nothing)" % kind)
		return
	if chasing():
		if kind == "ram":
			_ram_in_chase()
		return
	if phase != Phase.CALM:
		return
	var why := ""
	if kind == "ram":
		# A ram starts koguty 1 even in the cooldown; only the session's first minutes are spared.
		if not _start_grace():
			_start_chase(1, u, "ram")
			return
		kind = "bump"
	if clock < WARN_FROM and not now and not grace_over:
		_log("%s seen, before the warnings start" % kind)
		return
	if u != null:
		u.warn_wait = UNIT_GAP
	strikes += 1
	_strike_t = 0.0
	if cooldown > 0.0 and not now:
		why = " (cooldown)"
	elif _start_grace():
		why = " (grace)"
	_log("warn %s%s%s, strikes %d" % [kind, " (unit %d)" % u.number if u != null else "", why, strikes])
	hud.set_koguty(0, 3)
	sfx_cue("whoop")
	if kind == "oneway":
		_note("POD PRĄD!", "WRONG WAY!")
	else:
		_say(u, "police_warn", kind, true)
	if strikes >= 2 and _may_chase():
		_start_chase(1, u, "2 strikes")


## The session's first minutes, before the police have met the player (no chase).
func _start_grace() -> bool:
	return clock < START_GRACE and not grace_over and not now


## No chase starts now: the start grace or the cooldown after the last one.
func _may_chase() -> bool:
	return not gentle and not _start_grace() and (cooldown <= 0.0 or now)


func _ram_in_chase() -> void:
	if _rise_wait > 0.0:
		return
	if _raise("ram"):
		_rise_wait = RAM_GAP


func _on_bumped(d, speed: float) -> void:
	if flying or speed < BUMP:
		return
	var u = _unit_of.get(d)
	if u != null and u.role() == "crash":
		# The crash scenes: the scene's car stays put; the offence is anyone's (a ram's chase
		# goes to the nearest other unit).
		u = null
	_offence("ram" if speed > RAM else "bump", u)


func _start_chase(lvl: int, u, why: String) -> void:
	if gentle:
		_log("no chase in Spacer (%s)" % why)
		return
	if u == null:
		u = _nearest_unit()
	phase = Phase.CHASE
	level = lvl
	top_level = lvl
	chase_t = 0.0
	_unseen = 0.0
	_still = 0.0
	_rewarded = false
	_rise_wait = RAM_GAP if why == "ram" else 0.0
	_level_at = clock
	_last_seen = car.global_position
	grace_over = true
	strikes = 0
	chases_started += 1
	_in_chase = true
	_log("L%d (%s)%s" % [lvl, why, " unit %d" % u.number if u != null else ""])
	_log("wallet %d zł (chase start)" % wallet.zl)
	if u != null:
		_engage(u, "chaser")
		_say(u, "police_chase", "start", true)
	_chase_line = randf_range(CHASE_LINES.x, CHASE_LINES.y)
	sfx_cue("whoop")
	if lvl >= 2:
		_place_blocker()
	if lvl >= 3:
		_place_roadblock()


func _engage(u, role: String) -> void:
	if not u in _engaged:
		_engaged.append(u)
	u.set_role(role)
	if u.driver != null:
		# Seen now (perception runs at 5 Hz; the chase checks its distance every frame).
		var p := car.global_position
		u.dist = Vector2(u.driver.pos.x - p.x, u.driver.pos.z - p.z).length()
		u.sees = not flying and _sight(u.driver.pos, p)


## +1 level (koguty 2: a blocker, 3: the roadblock), unless at 3 or in the cap's last NO_RISE s.
func _raise(why: String) -> bool:
	if level >= 3 or chase_t > CAPS[top_level - 1] - NO_RISE:
		return false
	level += 1
	top_level = maxi(top_level, level)
	_level_at = clock
	_log("L%d (%s)" % [level, why])
	sfx_cue("whoop")
	if level == 2:
		_place_blocker()
		_say(_chaser(), "police_chase", "backup", true)
	elif level == 3:
		_place_roadblock()
		_say(_chaser(), "police_chase", "roadblock", true)
	return true


func _chase_frame(dt: float) -> void:
	chase_t += dt
	var cap: float = CAPS[top_level - 1]
	if chase_t >= cap:
		_end("shift")
		return
	var p := car.global_position
	var near := INF
	var far := true
	var seen := false
	var nearest = null
	for u in _engaged:
		if u.driver == null:
			continue
		if u.dist < (RAID_ESCAPE if raid_chase else ESCAPE_DIST):
			far = false
		if u.sees:
			seen = true
		if u.role() == "chaser" and u.dist < near:
			near = u.dist
			nearest = u
	if _engaged.is_empty():
		far = true
	_raid_t = maxf(0.0, _raid_t - dt)
	if phase == Phase.CHASE:
		if seen:
			_unseen = 0.0
			_last_seen = p
		else:
			_unseen += dt
		if (far or _unseen >= UNSEEN) and _raid_t <= 0.0:
			phase = Phase.SEARCH
			_search_t = 0.0
			_log("search (%s)" % ("120 m away" if far else "out of sight %.1f s" % _unseen))
			return
		var speed: float = car.vel.length()
		var gap: float = near - (nearest.driver.length * 0.5 + 2.0 if nearest != null else 0.0)
		# (--police-auto=still, for the probes: the car stands and the chase goes on.)
		if speed < PULL_SPEED and gap < PULL_DIST and auto != "still":
			if _still <= 0.0:
				_log("stopped by unit %d (%.1f m between the bumpers)" % [nearest.number, gap])
			_still += dt
			if _still >= PULL_HOLD:
				_pull_over(_opener(""), nearest)
				return
		else:
			_still = 0.0
		if _chase_line <= 0.0 and nearest != null:
			_chase_line = randf_range(CHASE_LINES.x, CHASE_LINES.y)
			_say(nearest, "police_chase", "", false)
	else:
		_search_t += dt
		var close := false
		for u in _engaged:
			if u.sees and u.dist < RESEEN:
				close = true
		if close:
			phase = Phase.CHASE
			_unseen = 0.0
			_last_seen = p
			_log("seen again (L%d)" % level)
			return
		if _search_t >= (SEARCH_HIDDEN if _hidden(p) else SEARCH):
			_end("escaped")
	# The blockers and the roadblock that the chase has left behind go (police_unit.gd).
	if log_on:
		_b4_t += dt
		if _b4_t >= 1.0:
			_b4_t = 0.0
			_b4()


## Ends a chase or a pull-over: "escaped", "shift" (the cap), "heli", "pullover".
func _end(how: String) -> void:
	var t := chase_t
	raid_chase = false
	_raid_t = 0.0
	var lost = _chaser()
	match how:
		"escaped":
			_log("escaped after %.1f s" % t)
			if not _rewarded:
				_rewarded = true
				wallet.add_respect(ESCAPE_RESPECT)
				wallet.add_escape()
			hud.toast("UCIECZKA!  +%d" % ESCAPE_RESPECT, "ESCAPED!  +%d RESPECT" % ESCAPE_RESPECT)
			sfx_cue("chord")
			_say_or_radio(lost, "police_lost", "escaped")
		"shift":
			_log("end of shift after %.1f s (L%d)" % [t, top_level])
			hud.toast("KONIEC ZMIANY", "END OF SHIFT")
			_say_or_radio(lost, "police_lost", "shift")
		"heli":
			_log("end of shift (heli) after %.1f s" % t)
			_say_or_radio(lost, "police_lost", "heli")
		"pullover":
			_log("pull-over done")
		"guard":
			_log("guard talk done")
		"rescue":
			# Loop 3g-2 (police.md 8.1): accepting a rescue ends the chase, straight to the cooldown.
			_log("chase ended after %.1f s: rescue accepted" % t)
			hud.toast("POLICJA ODPUSZCZA: RATUJESZ KOGOŚ", "THE POLICE BACK OFF: YOU'RE ON A RESCUE")
	if how == "escaped" and rivals != null and rivals.in_race() and not rivals.escape_bonus:
		# Loop 3g-2 (police.md 8.2): escaping during a race marks it: a win pays the stake x 1.2.
		rivals.escape_bonus = true
		_log("race marked +20 % for the escape")
	if _in_chase:
		_in_chase = false
		chases_ended += 1
	var done := _engaged.duplicate()
	if _talk_unit != null and not _talk_unit in done:
		done.append(_talk_unit)
	for u in done:
		if u.driver == null:
			continue
		u.tree.blackboard.set_value("pullover", false)
		u.driver.held = false
		if u.role() in ["blocker", "roadblock"]:
			dismiss(u)
		elif u.role() != "trap":
			u.set_role("patrol")
	_engaged.clear()
	_talk_unit = null
	phase = Phase.CALM
	level = 0
	top_level = 0
	strikes = 0
	grace_over = true
	# A guard's talk is not the police's: no cooldown after it.
	if how != "guard":
		cooldown = 0.0 if now else COOLDOWN
	if sfx != null:
		sfx.police_siren(Vector3.INF)
	hud.set_koguty(0, 0)
	_log("wallet %d zł → %d zł" % [_zl0, wallet.zl])
	chase_ended.emit(how)


func _chaser():
	for u in _engaged:
		if u.role() == "chaser" and u.driver != null:
			return u
	return null


func _nearest_unit():
	var best = null
	for u in _units:
		# Loop 3g-2: never the guards' car (guards never call the police) nor the escort.
		if u.driver != null and not u.role() in ["guard", "guard_follow", "escort", "club", "crash"] and (best == null or u.dist < best.dist):
			best = u
	return best


# --- loop MW-3: the police by the clubs ------------------------------------------------------

## A patrol car parked across the street from a club's door (crowds.gd, Fri/Sat nights): the
## outer lane's kerb of the road nearest the door, on its far side, 8 m along. Returns where its
## officer stands (on the footway beside it, facing the road) as {officer: Vector3, officer_yaw,
## car: Vector3}, or {} with no road near. The car itself comes and goes with the player like a
## trap's (out of sight), as a unit of role "club": it never perceives, warns or chases.
func club_park(id: String, door: Vector2) -> Dictionary:
	if graph == null:
		return {}
	var hit: Array = graph.snap(door, 45.0, Vector2.ZERO, false, true)
	if hit.is_empty():
		return {}
	var best := {}
	for e: int in [hit[0], graph.e_reverse[hit[0]]]:
		if e < 0:
			continue
		var s := clampf(graph.project(e, door) + 8.0, graph.e_s0[e] + 3.0, graph.e_s1[e] - 3.0)
		var lane: int = graph.e_lanes[e] - 1
		var off := graph.lane_offset(e, lane) + 0.9
		var c := graph.point_at(e, s, off)
		if best.is_empty() or c.distance_to(door) > (best["car"] as Vector2).distance_to(door):
			best = {"e": e, "s": s, "lane": lane, "car": c, "off": off}
	var e: int = best["e"]
	var s: float = best["s"]
	var d := graph.direction(e, s)
	var nrm := (graph.point_at(e, s, float(best["off"]) + 1.0) - (best["car"] as Vector2)).normalized()
	var o: Vector2 = (best["car"] as Vector2) + nrm * 2.4 + d * 1.6
	best["yaw"] = atan2(-d.x, -d.y)
	best["unit"] = null
	if _clubs.has(id):
		club_leave(id)
	_clubs[id] = best
	var car3 := _v3(best["car"])
	_log("club %s: a car parked at %d,%d" % [id, roundi(car3.x), roundi(car3.z)])
	return {"officer": Vector3(o.x, map.ground_height(o.x, o.y), o.y), "officer_yaw": atan2(nrm.x, nrm.y), "car": car3}


## The club's car leaves (pulls out if on screen, else goes).
func club_leave(id: String) -> void:
	if not _clubs.has(id):
		return
	var u = _clubs[id]["unit"]
	_clubs.erase(id)
	if u != null and u.driver != null:
		dismiss(u)


## At 5 Hz: each club's car comes into the street out of sight within TRAP_BAND m of the player
## (or in the first 3 s), and goes again past TRAP_BAND + 100 m.
func _clubs_tick() -> void:
	if _clubs.is_empty():
		return
	var p2 := _xz(car.global_position)
	for id: String in _clubs:
		var c: Dictionary = _clubs[id]
		var at := _v3(c["car"])
		var dist := p2.distance_to(c["car"])
		var u = c["unit"]
		if u == null:
			if dist < TRAP_BAND and (clock < 3.0 or not traffic.on_screen(at, 2.0)):
				var e: int = c["e"]
				var d = traffic.add_police(e, int(c["lane"]), clampf(float(c["s"]), graph.e_s0[e] + 1.0, graph.e_s1[e] - 1.0))
				if d == null:
					continue
				u = _bind(d, "club")
				if u == null:
					traffic.remove(d)
					continue
				traffic.park(d, e, float(c["s"]), at, float(c["yaw"]))
				c["unit"] = u
		elif dist > TRAP_BAND + 100.0 and u.driver != null and not traffic.on_screen(u.driver.pos, 2.0):
			traffic.remove(u.driver)


# --- the crash scenes ------------------------------------------------------------------------

## The crash scenes (crash_scenes.gd, 2026-11-01): a car of the police family parked at a scene
## at `at` heading `yaw`, standing in lane `lane` of edge e at s (the traffic stops behind it and
## goes round): shape 0 the patrol car, 2 the ambulance. A unit of role "crash" (lights on, sees
## nothing, starts nothing, never a chaser). Null if the pool is out.
func scene_car(e: int, lane: int, s: float, at: Vector3, yaw: float, shape: int):
	if _free.is_empty():
		return null
	var d = traffic.add_police(e, lane, s, shape)
	if d == null:
		return null
	var u = _bind(d, "crash")
	if u == null:
		traffic.remove(d)
		return null
	traffic.park(d, e, s, at, yaw, lane)
	traffic.set_lights(d, true)
	return d


## The scene's car goes (out of sight: crash_scenes.gd only clears a scene the view can't see).
func scene_leave(d) -> void:
	if d != null and d.active:
		traffic.remove(d)


# --- the night meets' raids -------------------------------------------------------------------

## Night meets (street_meet.gd, F's ask 2026-11-06): a raid on a street racers' meet at `at`. Up to
## `n` patrol cars come in, lights on, from lanes RAID_FROM..RAID_TO m round it (headed in where a
## lane allows), and a chase at koguty `lvl` starts on the player at once: no start grace and no
## cooldown (the raid is the quest's beat). Still never one in Spacer (`gentle`) or while the player
## flies. Returns the cars placed (0: none, no chase).
const RAID_FROM := 50.0
const RAID_TO := 110.0
## A raid's chase can't be lost in its first RAID_HOLD s, and its escape needs RAID_ESCAPE m from
## every chaser (PT-34: koguty 2 from a raid was lost in 8 s, the cars came in near ESCAPE_DIST).
const RAID_HOLD := 15.0
const RAID_ESCAPE := 160.0


func raid(at: Vector3, n: int, lvl := 2) -> int:
	if gentle or flying or graph == null or phase == Phase.PULLOVER:
		return 0
	var placed: Array = []
	var a0 := randf() * TAU
	for k in 12:
		if placed.size() >= n:
			break
		var q := Vector2(at.x, at.z) + Vector2.from_angle(a0 + TAU * k / 12.0) * randf_range(RAID_FROM, RAID_TO)
		var hit: Array = graph.snap(q, 40.0, Vector2.ZERO, true, true)
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var s := clampf(float(hit[2]), graph.e_s0[e] + 2.0, graph.e_s1[e] - 2.0)
		# Headed towards the meet: the lane whose way points at it.
		var to := Vector2(at.x, at.z) - graph.point_at(e, s)
		if graph.direction(e, s).dot(to) < 0.0 and graph.e_reverse[e] >= 0:
			var r: int = graph.e_reverse[e]
			s = clampf(graph.e_len[e] - s, graph.e_s0[r] + 2.0, graph.e_s1[r] - 2.0)
			e = r
		var p := graph.point_at(e, s)
		var near := false
		for u in placed:
			if Vector2(u.driver.pos.x, u.driver.pos.z).distance_to(p) < 25.0:
				near = true
		if near:
			continue
		var d = traffic.add_police(e, 0, s)
		if d == null:
			break
		var u = _bind(d, "patrol")
		if u == null:
			traffic.remove(d)
			break
		d.v = graph.e_speed[e] * 0.7
		traffic.set_lights(d, true)
		placed.append(u)
	if placed.is_empty():
		_log("raid at %.0f, %.0f: no lane for a car" % [at.x, at.z])
		return 0
	_track_player()
	if phase == Phase.CALM:
		_start_chase(clampi(lvl, 1, 3), placed[0], "raid")
	_raid_t = RAID_HOLD
	raid_chase = true
	for u in placed:
		_engage(u, "chaser")
	_log("raid at %.0f, %.0f: %d cars" % [at.x, at.z, placed.size()])
	return placed.size()


# --- blocker and roadblock -------------------------------------------------------------------

## The first junction on the player's way ahead between `lo` and `hi` metres (straight on at
## each node), out of sight: [edge into it, s], or [].
func _spot_ahead(lo: float, hi: float) -> Array:
	if _edge < 0:
		return []
	var e := _edge
	var run := graph.e_s1[e] - _s
	var guard := 0
	while run < hi and guard < 40:
		guard += 1
		var node := graph.e_b[e]
		var outs: PackedInt32Array = graph.node_out[node]
		var real := 0
		for f in outs:
			if f != graph.e_reverse[e]:
				real += 1
		var s := graph.e_s1[e] - 6.0
		if run >= lo and real >= 2 and s > graph.e_s0[e] + 2.0:
			var q := graph.point_at(e, s)
			if not traffic.on_screen(Vector3(q.x, graph.height(e, s), q.y), 2.0):
				return [e, s]
		var here := graph.direction(e, graph.e_s1[e])
		var next := -1
		var best := 9.0
		for f in outs:
			if f == graph.e_reverse[e]:
				continue
			var turn := absf(here.angle_to(graph.direction(f, graph.e_s0[f])))
			if turn < best:
				best = turn
				next = f
		if next < 0:
			return []
		e = next
		run += graph.e_len[e]
	return []


## Koguty 2: a blocker parked across the far lane at a junction ahead (≥ 3.5 m left clear).
func _place_blocker() -> void:
	var spot := _spot_ahead(250.0, 400.0)
	if spot.is_empty():
		_log("no blocker spot ahead")
		return
	var e: int = spot[0]
	var s: float = spot[1]
	var d = traffic.add_police(e, 0, s)
	if d == null:
		return
	var u = _bind(d, "blocker")
	if u == null:
		traffic.remove(d)
		return
	var dir := graph.direction(e, s)
	var off := graph.lane_offset(e, 0) - (0.0 if graph.e_lanes[e] > 1 else graph.e_lw[e] * 0.5 + 0.6)
	var q := graph.point_at(e, s, off)
	var yaw := atan2(-dir.x, -dir.y) + deg_to_rad(55.0)
	traffic.park(d, e, s, Vector3(q.x, graph.height(e, s), q.y), yaw, 0 if graph.e_lanes[e] > 1 else -1)
	_engaged.append(u)
	_log("blocker (unit %d) at %d,%d" % [u.number, roundi(q.x), roundi(q.y)])


## Koguty 3: two cars in a V at the next junction ahead, a ≥ 4 m gap in the middle.
func _place_roadblock() -> void:
	var spot := _spot_ahead(150.0, 320.0)
	if spot.is_empty():
		_log("no roadblock spot ahead")
		return
	var e: int = spot[0]
	var s: float = spot[1]
	var n := graph.e_lanes[e]
	var left := graph.lane_offset(e, 0) - graph.e_lw[e] * 0.5
	var right := graph.lane_offset(e, n - 1) + graph.e_lw[e] * 0.5
	var dir := graph.direction(e, s)
	var base := atan2(-dir.x, -dir.y)
	for k in 2:
		var d = traffic.add_police(e, 0 if k == 0 else n - 1, s)
		if d == null:
			return
		var u = _bind(d, "roadblock")
		if u == null:
			traffic.remove(d)
			return
		var off := left + 0.4 if k == 0 else right - 0.4
		var q := graph.point_at(e, s, off)
		traffic.park(d, e, s, Vector3(q.x, graph.height(e, s), q.y), base + deg_to_rad(40.0 if k == 0 else -40.0),
				(0 if k == 0 else n - 1) if n > 2 else -1)
		_engaged.append(u)
	_log("roadblock at %s" % [graph.point_at(e, s).round()])


# --- speed traps and the lizak ---------------------------------------------------------------

## Today's traps: the spots of data/police_traps.json whose road is in this map (found by name
## on the lane graph at the officer's spot), three of them by the date (like the roadworks);
## --trap=N makes N one of them.
func _load_traps(_data: Dictionary) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TRAPS_PATH))
	if not parsed is Dictionary:
		push_error("police: can't read %s" % TRAPS_PATH)
		return
	var present: Array = []
	var skipped: PackedStringArray = []
	for row: Dictionary in parsed["traps"]:
		var id := int(row["id"])
		if not row.has("officer"):
			skipped.append("%d" % id)
			continue
		var t := _trap_from(row)
		if t.is_empty():
			skipped.append("%d (%s not found)" % [id, row["road"]])
			continue
		present.append(t)
	var rng := RandomNumberGenerator.new()
	rng.seed = _today
	var order := present.duplicate()
	for k in range(order.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var tmp = order[k]
		order[k] = order[j]
		order[j] = tmp
	traps = order.slice(0, TRAPS_A_DAY)
	var forced := int(opts.get("trap", 0))
	if forced > 0:
		var keep := traps.filter(func(t: Dictionary) -> bool: return t["id"] == forced)
		if keep.is_empty():
			for t in present:
				if t["id"] == forced:
					traps.pop_back()
					traps.push_front(t)
	traps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	var ids := PackedStringArray()
	for t in traps:
		ids.append(str(t["id"]))
	_log("traps for %d: %s (%d in this map; not here: %s)" % [_today, ", ".join(ids), present.size(), ", ".join(skipped)])


func _trap_from(row: Dictionary) -> Dictionary:
	var officer := Vector2(row["officer"][0], row["officer"][1])
	var dir := Vector2(row["direction"][0], row["direction"][1]).normalized()
	var hit: Array = graph.snap(officer, 14.0, dir)
	if hit.is_empty() or graph.e_name[hit[0]] != String(row["road"]):
		return {}
	var e: int = hit[0]
	var at := Vector2(row["car"][0], row["car"][1])
	return {"id": int(row["id"]), "road": String(row["road"]), "car": at, "officer": officer, "dir": dir,
			"heading": float(row["car_heading"]), "edge": e, "s": graph.project(e, at),
			"limit": graph.e_speed[e], "radio": row["radio"], "rearm": 0.0, "unit": null, "slot": -1,
			"known": false, "waving": false}


## Where --trap=N starts the car: [position (y 0), compass heading], or [] (main.gd, before the
## city is built).
static func trap_start(n: int) -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TRAPS_PATH))
	if not parsed is Dictionary:
		return []
	for row: Dictionary in parsed["traps"]:
		if int(row["id"]) == n and row.has("start"):
			return [Vector3(row["start"][0], 0.0, row["start"][1]), float(row["start_heading"])]
	return []


## Each frame: the traps' cars and officers come and go with the player (out of sight), and a
## speeder in a radar's 40 m gets the lizak (or, before the police may chase, a warning).
func _traps_frame() -> void:
	var p := car.global_position
	var p2 := _xz(p)
	var speed: float = car.vel.length()
	for t in traps:
		var d2: float = p2.distance_to(t["car"])
		var u = t["unit"]
		if u == null:
			if d2 < TRAP_BAND and (_frame < 5 or not traffic.on_screen(_v3(t["car"]), 2.0)):
				_spawn_trap_car(t)
		elif u.role() == "trap" and d2 > TRAP_BAND + 100.0 and not traffic.on_screen(u.driver.pos, 2.0):
			traffic.remove(u.driver)
			continue
		if t["unit"] != null and not t["known"] and d2 < 60.0:
			t["known"] = true
		if flying or clock < t["rearm"] or t["unit"] == null or t["unit"].role() != "trap":
			continue
		var rel: Vector2 = p2 - t["officer"]
		var dir: Vector2 = t["dir"]
		var along := rel.dot(dir)
		var lat := absf(rel.cross(dir))
		if along < -RADAR or along > 0.0 or lat > 14.0 or _xz(car.vel).dot(dir) <= 0.0:
			continue
		if speed <= t["limit"] + TRAP_OVER:
			continue
		t["rearm"] = clock + TRAP_REARM
		trap_flashes += 1
		if phase != Phase.CALM:
			continue
		if _rescue_on():
			_log("trap %d: %d km/h, on a rescue (nothing)" % [t["id"], roundi(speed * 3.6)])
			continue
		if not _may_chase():
			_log("trap %d: %d km/h in %d, %.1f m before the officer (%s)" % [t["id"], roundi(speed * 3.6),
					roundi(t["limit"] * 3.6), -along, "cooldown" if cooldown > 0.0 else "grace"])
			if clock >= WARN_FROM or grace_over or now:
				_offence("speed", t["unit"])
			continue
		_lizak(t, speed, -along)


func _spawn_trap_car(t: Dictionary) -> void:
	var e: int = t["edge"]
	var d = traffic.add_police(e, graph.e_lanes[e] - 1, clampf(t["s"], graph.e_s0[e] + 1.0, graph.e_s1[e] - 1.0))
	if d == null:
		return
	var u = _bind(d, "trap")
	if u == null:
		traffic.remove(d)
		return
	var at: Vector2 = t["car"]
	traffic.park(d, e, t["s"], Vector3(at.x, map.ground_height(at.x, at.y), at.y), -deg_to_rad(t["heading"]))
	t["unit"] = u
	_officer(t, true)


## The trap's officer, a pedestrian instance standing at the kerb facing the traffic.
func _officer(t: Dictionary, on: bool) -> void:
	if walkers == null:
		return
	var slot: int = t["slot"] if int(t.get("slot", -1)) >= 0 else traps.find(t)
	if slot < 0 or slot >= walkers.FIXED:
		return
	if not on:
		walkers.clear_fixed(slot)
		return
	var at: Vector2 = t["officer"]
	var face: Vector2 = -t["dir"]
	if t["waving"]:
		face = (_xz(car.global_position) - at).normalized()
	walkers.set_fixed(slot, Vector3(at.x, map.ground_height(at.x, at.y), at.y), atan2(-face.x, -face.y), OFFICER_SHIRT, OFFICER_TROUSERS)


func _lizak(t: Dictionary, speed: float, before: float) -> void:
	phase = Phase.LIZAK
	_lizak_trap = t
	_lizak_t = 0.0
	_lizak_still = 0.0
	t["waving"] = true
	t["known"] = true
	grace_over = true
	_officer(t, true)
	sfx_cue("whistle")
	_log("lizak (trap %d, %d km/h in %d, %.1f m before the officer, unit %d)" % [t["id"], roundi(speed * 3.6),
			roundi(t["limit"] * 3.6), before, t["unit"].number])


func _lizak_frame(dt: float) -> void:
	var t := _lizak_trap
	_lizak_t += dt
	if t.is_empty() or t["unit"] == null:
		_lizak_done("the car went")
		return
	_officer(t, true)
	var p := _xz(car.global_position)
	var rel: Vector2 = p - t["officer"]
	var along: float = rel.dot(t["dir"])
	var speed: float = car.vel.length()
	if rel.length() < LIZAK_STOP and speed < LIZAK_SLOW:
		var u = t["unit"]
		_log("stopped %.1f m from the officer" % rel.length())
		_lizak_done("")
		# Loop 3g-2: the scripted first contact's stop is the routine check.
		_pull_over("routine" if t.get("first", false) else "trap", u)
		return
	if along > LIZAK_PAST:
		var u = t["unit"]
		_lizak_done("")
		if t.get("first", false):
			_first_done("drove on")
			_start_chase(1, u, "first contact ignored, %.1f m past the officer" % along)
		else:
			_start_chase(1, u, "lizak ignored, %.1f m past the officer" % along)
		return
	_lizak_still = _lizak_still + dt if speed < 1.0 else 0.0
	if _lizak_still >= LIZAK_GIVE_UP or _lizak_t > LIZAK_LONGEST or flying:
		_lizak_done("stopped elsewhere" if _lizak_still >= LIZAK_GIVE_UP else "gone")


func _lizak_done(why: String) -> void:
	if not _lizak_trap.is_empty():
		_lizak_trap["waving"] = false
		_officer(_lizak_trap, _lizak_trap["unit"] != null)
	_lizak_trap = {}
	if phase == Phase.LIZAK:
		phase = Phase.CALM
	if why != "":
		_log("lizak dropped (%s)" % why)


## The radio host reads the day's traps once per station change after 120 s, at most once an
## hour; the minimap shows them from then on.
func _on_station(_index: int, _station: Dictionary) -> void:
	if traps.is_empty() or radio.station < 0 or clock < 120.0 or clock - _traps_announced < 3600.0:
		return
	var l: Array = dialogue.line("radio_host", "traps", true)
	if l.is_empty():
		return
	_traps_announced = clock
	var pl := PackedStringArray()
	var en := PackedStringArray()
	for t in traps:
		t["known"] = true
		pl.append(t["radio"][0])
		en.append(t["radio"][1])
	radio.announce(String(l[0]).replace("{pl}", _list(pl, " i ")), String(l[1]).replace("{en}", _list(en, " and ")))


static func _list(items: PackedStringArray, last: String) -> String:
	if items.size() <= 1:
		return "".join(items)
	return ", ".join(items.slice(0, items.size() - 1)) + last + items[items.size() - 1]


# --- the pull-over ---------------------------------------------------------------------------

## The opener's tag: the first contact, else the job running, else the reason, else generic.
func _opener(reason: String) -> String:
	if jobs != null and jobs.busy():
		if jobs.job == 1:
			return "kebab"
		if jobs.job == 2:
			return "sloik"
	return reason


func _pull_over(tag: String, u) -> void:
	phase = Phase.PULLOVER
	_talk_unit = u
	_talk_tag = tag
	grace_over = true
	if _in_chase:
		_log("wallet %d zł (pull-over)" % wallet.zl)
	_log("pull-over %s%s" % [tag if tag != "" else "generic", " (unit %d)" % u.number if u != null else ""])
	if u != null and u.driver != null:
		u.tree.blackboard.set_value("pullover", true)
		u.driver.held = true
		traffic.set_lights(u.driver, true)
	if sfx != null:
		sfx.police_siren(Vector3.INF)
	if radio != null:
		radio.duck_db = -6.0
	# The car is held: its pedals give the card their room.
	hud.set_pedals_hidden(true)
	_freeze_heat(true)
	_start_talk(tag)


## Loop 3g-2 (police.md 4, 8.3): the kebab's heat stands still while the card is open.
func _freeze_heat(on: bool) -> void:
	if jobs == null or not "heat_frozen" in jobs:
		return
	if on and jobs.busy() and jobs.job == 1:
		jobs.heat_frozen = true
		_froze_heat = true
		_log("kebab heat frozen at %d %%" % roundi(jobs.heat() * 100.0))
	elif not on and _froze_heat:
		jobs.heat_frozen = false
		_froze_heat = false
		_log("kebab heat runs again from %d %%" % roundi(jobs.heat() * 100.0))


func _ensure_dm() -> bool:
	if _resource != null:
		return true
	var t0 := Time.get_ticks_usec()
	if Engine.has_singleton("DialogueManager"):
		_dm = Engine.get_singleton("DialogueManager")
	else:
		_dm = load(DIALOGUE_MANAGER).new()
		_dm.name = "DialogueManager"
		add_child(_dm)
	# The flow reads only `talk` (no `self`: Dialogue Manager would put the resource into every
	# line's states).
	_dm.include_dialogue_resource_as_self = false
	_resource = _dm.create_resource_from_text(FileAccess.get_file_as_string(DIALOGUE_PATH))
	_log("dialogue manager and police.dialogue ready in %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	return _resource != null


func _start_talk(tag: String) -> void:
	_talk_t = 0.0
	_routine = tag == "routine"
	_caution_n = 0
	if not _ensure_dm():
		_talk_done()
		return
	talk = Talk.new()
	talk.dialogue = dialogue
	talk.opener = tag
	talk.first_contact = _routine
	talk.has_reply = _has_reply(tag)
	talk.caution_tag = "fifth" if wallet.cautions_on(_today) + 1 == 5 else "police"
	talk.on_caution = _on_caution
	talk.on_routine = _on_routine
	# Loop 3g-2: a guard's conversation (police.dialogue guard_stop), the zone's tag.
	if _guard != null:
		talk.zone = _guard.tag
		talk.opener = ""
		talk.first_contact = false
		_show_next("guard_stop")
		return
	_show_next("pull_over")


func _has_reply(tag: String) -> bool:
	if tag == "":
		return false
	for l in dialogue.lines.get("police_reply", []):
		if dialogue.notes(l).get("only", "") == tag:
			return true
	return false


## Fetches the next line (Dialogue Manager runs the mutations on the way) and shows it.
func _show_next(id: String) -> void:
	if id == "" or id == "end" or id == "end!":
		_talk_done()
		return
	_line = null
	var line = await _dm.get_next_dialogue_line(_resource, id, [{"talk": talk}])
	if phase != Phase.PULLOVER or talk == null:
		return
	if line == null:
		_talk_done()
		return
	_line = line
	_beat_t = 0.0
	var speaker := talk.speaker_override if talk.speaker_override != "" else String(line.character)
	talk.speaker_override = ""
	var replies: Array = []
	for r in line.responses:
		if r.is_allowed:
			replies.append([r.text, talk.english_of(r.text), r.next_id])
	_balloon.show_line(speaker, line.text, talk.english_of(line.text), replies)
	hud.show_panel(_balloon, true)
	_log("talk %s: %s%s" % [speaker, line.text, " | " + " | ".join(replies.map(func(r: Array) -> String: return r[0])) if not replies.is_empty() else ""])


func _talk_frame(dt: float) -> void:
	_talk_t += dt
	if _talk_t > TALK_LONGEST:
		_talk_done()
		return
	if _line == null:
		return
	_beat_t += dt
	if _line.responses.is_empty():
		if _beat_t >= BEAT:
			_show_next(_line.next_id)
	elif _beat_t >= REPLY_AUTO:
		_on_reply(0)


func _on_tap() -> void:
	# Loop 3g-2: the clamp's card: a tap is the "Przepraszam".
	if guards.clamp == "on":
		guards.sorry()
		return
	if phase != Phase.PULLOVER or _line == null:
		return
	if _line.responses.is_empty():
		_show_next(_line.next_id)
	else:
		_on_reply(0)


func _on_reply(i: int) -> void:
	if guards.clamp == "on":
		guards.sorry()
		return
	if phase != Phase.PULLOVER or _line == null:
		return
	var allowed: Array = _line.responses.filter(func(r) -> bool: return r.is_allowed)
	if allowed.is_empty():
		_show_next(_line.next_id)
		return
	var r = allowed[clampi(i, 0, allowed.size() - 1)]
	_log("reply: %s" % r.text)
	_show_next(r.next_id)


## police.dialogue's `done_caution`: one more in the joke notebook.
func _on_caution() -> void:
	_caution_n = wallet.add_caution(_today)
	_log("caution n=%d today" % _caution_n)
	sfx_cue("stamp")


## police.dialogue's `done_routine`: the first contact's rules toast.
func _on_routine() -> void:
	_log("first contact")
	_first_done("routine check")


func _talk_done() -> void:
	_line = null
	talk = null
	_untangle()
	hud.show_panel(_balloon, false)
	hud.set_pedals_hidden(false)
	if radio != null:
		radio.duck_db = 0.0
	if _caution_n > 0:
		hud.toast("POUCZENIE · W ZESZYCIE: %d DZIŚ" % _caution_n, "CAUTION · IN THE NOTEBOOK: %d TODAY" % _caution_n)
	elif _routine:
		hud.toast("KOGUTY = POLICJA. UCIEKNIJ ALBO STAŃ: NIC NIE TRACISZ",
				"ROOSTERS = POLICE. ESCAPE OR STOP: YOU LOSE NOTHING.")
	_freeze_heat(false)
	# Loop 3g-2: a guard's talk: back to the post, no star, no cooldown.
	if _guard != null:
		var g = _guard
		_guard = null
		guards.talk_done(g)
		_end("guard")
		return
	# The first contact's car pulls out and goes.
	if _routine and _talk_unit != null:
		var fu = _talk_unit
		_end("pullover")
		dismiss(fu)
		return
	# --- loop 2d-1: a Podwózka passenger on board takes one star for the pull-over (police.md
	# 8.3, parodies.md 3.3; rides.gd acts only while a ride runs). An escape costs nothing. ---
	var rides = jobs.get("rides") if jobs != null else null
	if rides != null:
		rides.on_pulled_over()
	# --- end loop 2d-1 ---
	_end("pullover")


# --- lines and sound -------------------------------------------------------------------------

## A megaphone line over unit `u`'s car (at most one every 8 s in the city, 20 s per unit; the
## lost lines always), or nothing if there is no unit.
func _say(u, group: String, tag: String, prefer: bool, always := false, speaker := "Policja") -> void:
	if u == null or u.driver == null or dialogue == null:
		return
	if not always and (_megaphone > 0.0 or u.line_wait > 0.0):
		return
	_megaphone = MEGAPHONE_GAP
	u.line_wait = UNIT_GAP
	var d = u.driver
	var anchor := func() -> Vector3:
		if u.driver != d or not d.active:
			return Vector3.INF
		return d.pos + Vector3(0, d.size.y + 0.4, 0)
	# Loop 3g-2: the megaphone's chirp before its line (police.md 10).
	if speaker == "Policja":
		sfx_cue("megaphone")
	var l: Array = dialogue.say(anchor, speaker, group, tag, 3.5, Color("#8fb0ff"), 2.6, prefer, Chatter.POLICE)
	if not l.is_empty():
		_log("line %s/%s: %s" % [group, tag, l[0]])


## The end of a chase: a bubble from the last chaser if it is on screen, else the radio ticker.
func _say_or_radio(u, group: String, tag: String) -> void:
	if u != null and u.driver != null and traffic.on_screen(u.driver.pos, 2.0):
		_say(u, group, tag, true, true)
		return
	var l: Array = dialogue.line(group, tag, true)
	if not l.is_empty() and radio != null:
		radio.announce("Policja: " + String(l[0]), String(l[1]))
		_log("radio %s/%s: %s" % [group, tag, l[0]])


func sfx_cue(kind: String) -> void:
	if sfx != null:
		sfx.police_cue(kind)


## A short pill (the wrong way).
func _note(pl: String, en: String) -> void:
	_pill_note = pl
	_pill_note_en = en
	_pill_note_t = 2.0


# --- the HUD, the halos ----------------------------------------------------------------------

func _hud_frame() -> void:
	var pts := PackedVector2Array()
	var marks := PackedVector2Array()
	var siren := Vector3.INF
	var siren_d := INF
	for u in _engaged:
		if u.driver == null:
			continue
		marks.append(_xz(u.driver.pos))
		if project.is_valid():
			pts.append(project.call(u.driver.pos + Vector3(0, 1.5, 0)))
		if phase == Phase.CHASE and u.role() == "chaser" and u.dist < siren_d:
			siren_d = u.dist
			siren = u.driver.pos
	# Loop 3g-2: the escort on the minimap, its siren while it leads.
	if _escort != null and _escort.driver != null:
		marks.append(_xz(_escort.driver.pos))
		if phase == Phase.CALM:
			siren = _escort.driver.pos
	var known := PackedVector2Array()
	for t in traps:
		if t["known"]:
			known.append(t["car"])
	hud.set_police_marks(marks, known)
	var lizak := Vector2.INF
	match phase:
		Phase.CHASE:
			hud.set_koguty(level, 1)
			hud.police_pill("POŚCIG · KONIEC ZMIANY ZA %s" % _clock_text(), "CHASE · END OF SHIFT IN %s" % _clock_text())
		Phase.SEARCH:
			hud.set_koguty(level, 2)
			hud.police_pill("SZUKAJĄ CIĘ · KONIEC ZMIANY ZA %s" % _clock_text(), "SEARCHING · END OF SHIFT IN %s" % _clock_text())
		Phase.LIZAK:
			hud.police_pill("ZATRZYMAJ SIĘ PRZY POLICJANCIE", "PULL OVER BY THE OFFICER")
			if project.is_valid() and not _lizak_trap.is_empty():
				var o: Vector2 = _lizak_trap["officer"]
				lizak = project.call(Vector3(o.x, map.ground_height(o.x, o.y) + 1.9, o.y))
		_:
			# Loop 3g-2: the escort's pill, then the guards' (the clamp's countdown, the zone).
			var gp: Array = guards.pill()
			if _pill_note_t > 0.0:
				hud.police_pill(_pill_note, _pill_note_en)
			elif _escort != null and _escort.driver != null:
				hud.police_pill("ESKORTA · +%d S" % int(ESCORT_BONUS), "ESCORT · +%d S" % int(ESCORT_BONUS))
			elif not gp.is_empty():
				hud.police_pill(gp[0], gp[1])
			else:
				hud.police_pill("", "")
	var breath := 1.0 if phase == Phase.CHASE else (0.5 if phase == Phase.SEARCH else 0.0)
	hud.police_fx(breath, pts if chasing() else PackedVector2Array(), lizak)
	if sfx != null and (phase == Phase.CHASE or (phase == Phase.CALM and _escort != null)):
		sfx.police_siren(siren)
	elif sfx != null and phase == Phase.SEARCH:
		sfx.police_siren(Vector3.INF)


## "0:27": the cap's time left.
func _clock_text() -> String:
	var left := maxi(0, ceili(CAPS[maxi(top_level, 1) - 1] - chase_t))
	return "%d:%02d" % [left / 60, left % 60]


## One glow MultiMesh for every police light at night: two pools on the road beside each car
## with its lights on (blue on the left, red on the right, taking turns with the lenses) and, at
## koguty 3, the police helicopter's searchlight sweeping round the player (never in frame).
func _build_halos(world: Node3D) -> void:
	_halo_mm = MultiMesh.new()
	_halo_mm.transform_format = MultiMesh.TRANSFORM_3D
	_halo_mm.use_colors = true
	_halo_mm.mesh = MapBuilder.halo_quad(1.0)
	_halo_mm.instance_count = POOL * 2 + 1
	_halo_mm.visible_instance_count = 0
	_halo_mm.custom_aabb = AABB(Vector3(-2500, -200, -1500), Vector3(5000, 600, 3000))
	_halo_buf.resize(_halo_mm.instance_count * 16)
	_halo_buf.fill(0.0)
	var glow := ShaderMaterial.new()
	glow.shader = load("res://shaders/glow.gdshader")
	glow.set_shader_parameter("billboard", false)
	glow.set_shader_parameter("radial", true)
	glow.set_shader_parameter("lift", 0.9)
	glow.render_priority = 1
	_halo_mmi = MultiMeshInstance3D.new()
	_halo_mmi.name = "PoliceHalos"
	_halo_mmi.multimesh = _halo_mm
	_halo_mmi.material_override = glow
	_halo_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# Shown only at night with a light bar flashing (_halos_frame): no draw call otherwise.
	_halo_mmi.visible = false
	world.add_child(_halo_mmi)


func _halos_frame() -> void:
	if tod == null or tod.lights_on < 0.01:
		_halo_mmi.visible = false
		return
	var n := 0
	var t := Time.get_ticks_msec() * 0.001
	var left_on := fmod(t * 2.5, 1.0) >= 0.5
	# Calm (access.gd): both pools burn steady and softer, no alternating flash.
	var steady := Access.calm
	for u in _units:
		var d = u.driver
		# Loop 3g-2: the guards' amber beacon has no blue and red pools.
		if d == null or not d.lights or d.clip < 0.5 or d.shape == 1:
			continue
		var c := cos(d.yaw)
		var s := sin(d.yaw)
		var right := Vector3(c, 0.0, -s)
		for side in 2:
			var at: Vector3 = d.pos + right * (1.6 if side == 1 else -1.6) + Vector3(0, 0.2, 0)
			var col := Color(0, 0, 0, 0)
			if steady or left_on == (side == 0):
				# The crash scenes: the ambulance (shape 2) has two blue lamps.
				col = HALO_BLUE if side == 0 or d.shape == 2 else (HALO_SAFE if Access.color_safe else HALO_RED)
				if steady:
					col.a *= 0.5
			_halo_put(n, at, HALO_SIZE, col)
			n += 1
	if level >= 3 and chasing():
		var p := car.global_position
		var a := t * TAU * 0.25
		_halo_put(n, p + Vector3(sin(a) * 7.0, 0.3, sin(a * 2.0) * 4.0), SEARCHLIGHT, Color(1.0, 0.97, 0.88, 0.35))
		n += 1
	if n != _halo_mm.visible_instance_count:
		_halo_mm.visible_instance_count = n
	_halo_mmi.visible = n > 0
	if n > 0:
		RenderingServer.multimesh_set_buffer(_halo_mm.get_rid(), _halo_buf)


## Halo instance i: a flat quad of `size` metres on the ground at `at`, coloured `col`.
func _halo_put(i: int, at: Vector3, size: float, col: Color) -> void:
	var b := i * 16
	# Lying flat: the quad's y axis turned onto the ground's -z (a -90° turn about x).
	_halo_buf[b] = size
	_halo_buf[b + 1] = 0.0
	_halo_buf[b + 2] = 0.0
	_halo_buf[b + 3] = at.x
	_halo_buf[b + 4] = 0.0
	_halo_buf[b + 5] = 0.0
	_halo_buf[b + 6] = size
	_halo_buf[b + 7] = at.y
	_halo_buf[b + 8] = 0.0
	_halo_buf[b + 9] = -size
	_halo_buf[b + 10] = 0.0
	_halo_buf[b + 11] = at.z
	_halo_buf[b + 12] = col.r
	_halo_buf[b + 13] = col.g
	_halo_buf[b + 14] = col.b
	_halo_buf[b + 15] = col.a


# --- loop 3g-2: rescues and the escort (police.md 8.1) -------------------------------------------

## missions.gd `accepted`: a rescue taken during a chase ends it (straight to the cooldown); a
## lizak waving is let go.
func _on_rescue_accepted() -> void:
	_rescues += 1
	if chasing():
		_end("rescue")
	elif phase == Phase.LIZAK:
		_lizak_done("rescue accepted")


## 5 times a second: the escort joins once the person is aboard (in the car), leads, waits, drops
## behind, and leaves at the hospital (or when the rescue ends or the player takes off).
func _escort_tick() -> void:
	if missions == null:
		return
	var aboard: bool = missions != null and missions.has_target() and missions.state == 4 and not flying
	if _escort != null:
		if _escort.driver == null or _escort.role() != "escort":
			_escort = null
			_log("escort lost (its car left)")
		elif not aboard:
			_escort_end("at the hospital" if missions != null and missions.state == 5 and missions.get("_success") else ("in the helicopter" if flying else "the rescue ended"))
		else:
			_escort_pace()
		return
	var key: int = missions.number * 1000 + _rescues
	if not aboard or _escort_for == key or _escort_tried == key:
		return
	# The session's first rescue always gets one; later ones when a patrol is near, or by chance.
	var forced: bool = opts.get("escort", false) or _rescues <= 1
	var u = null
	var best := ESCORT_JOIN
	for k in _units:
		if k.driver != null and k.role() == "patrol" and not k.driver.parked and k.dist < best:
			best = k.dist
			u = k
	var how := ""
	var route := _hospital_route()
	if route.is_empty():
		_escort_tried = key
		_log("escort: no route to the hospital")
		return
	if u != null:
		how = "patrol %d m away" % roundi(best)
	elif forced or randf() < ESCORT_CHANCE:
		var spot := _route_spot(route[1], ESCORT_AHEAD, ESCORT_FAR)
		if spot.is_empty():
			return  # tried again at the next tick (the player may be off the roads)
		var d = traffic.add_police(spot[0], 0, spot[1])
		if d == null:
			return
		u = _bind(d, "patrol")
		if u == null:
			traffic.remove(d)
			return
		var q := graph.point_at(spot[0], spot[1])
		how = "placed %d m ahead on the route at %d,%d" % [roundi(spot[2]), roundi(q.x), roundi(q.y)]
	else:
		_escort_tried = key
		_log("escort: none this time")
		return
	_escort = u
	_escort_for = key
	_escort_state = "lead"
	_escort_said = false
	u.escort_node = route[0]
	u.escort_route = route[1]
	u.tree.blackboard.set_value("escort_wait", false)
	u.tree.blackboard.set_value("escort_v", chase_top())
	u.set_role("escort")
	missions.add_time(ESCORT_BONUS)
	sfx_cue("whoop")
	_say(u, "police_escort", "", false, true, ESCORT_SPEAKER)
	var h: Vector3 = missions.target_position()
	_log("escort joined (unit %d, %s; rescue clock +%d s; the hospital %.0f m by road, %.0f m straight)" % [u.number, how,
			int(ESCORT_BONUS), _route_left(route[1], _xz(car.global_position)), _xz(car.global_position).distance_to(_xz(h))])


## The escort's pace: 15-25 m ahead of the player along the route, stopped while the player is over
## 60 m behind; once overtaken it follows behind (it never pushes in front of the player again
## until the player waits for it).
func _escort_pace() -> void:
	var u = _escort
	var d = u.driver
	if traffic.remaining(d) == INF:
		return  # its tree hasn't set it on the route yet (the next tick)
	var lead: float = _route_left(u.escort_route, _xz(car.global_position)) - traffic.remaining(d)
	var v: float = car.vel.length()
	var bb: Blackboard = u.tree.blackboard
	# A change holds for a second first (the player's place on the route jumps at junctions).
	var flip := (_escort_state == "lead" and lead < -ESCORT_PASSED) or (_escort_state == "behind" and lead > ESCORT_LEAD.x and lead < ESCORT_FAR)
	_escort_flip = _escort_flip + TICK if flip else 0.0
	if flip and _escort_flip >= 1.0:
		_escort_flip = 0.0
		if _escort_state == "lead":
			_escort_state = "behind"
			_log("escort behind (overtaken, %.0f m)" % -lead)
		else:
			_escort_state = "lead"
			_log("escort leads again (%.0f m ahead)" % lead)
	# Waiting for the player, or there: it stops at the hospital's door (it never "arrives" on its
	# own: it drives like a chaser) until the hand-over.
	var there: bool = traffic.remaining(d) < ESCORT_THERE
	var wait: bool = (_escort_state == "lead" and u.dist > ESCORT_WAIT) or there
	if wait != bool(bb.get_value("escort_wait", false)):
		_log("escort %s (%.0f m from the player)" % ["waits" if wait else "goes on", u.dist])
	bb.set_value("escort_wait", wait)
	# It sets the pace (ESCORT_PACE, or a little over the player's): slower while the player is more
	# than 25 m back, faster while closer than 15 m.
	var pace := chase_top()
	if _escort_state == "lead":
		if lead < ESCORT_LEAD.x:
			pace = maxf(v + 5.0, ESCORT_PACE + 2.0)
		elif lead > ESCORT_LEAD.y:
			pace = maxf(v - 3.0, 3.0)
		else:
			pace = maxf(v + 2.0, ESCORT_PACE)
		pace = clampf(pace, 2.0, chase_top())
	bb.set_value("escort_v", pace)
	_escort_lead = lead
	if log_on and _frame % 300 < 12:
		_log("escort status: %s, %.0f m ahead on the route, %.0f m apart, player %d km/h, escort %d km/h (cap %d)" % [
				_escort_state, lead, u.dist, roundi(v * 3.6), roundi(d.v * 3.6), roundi(pace * 3.6)])


func _escort_end(why: String) -> void:
	var u = _escort
	_escort = null
	_escort_state = ""
	if u.driver != null:
		u.tree.blackboard.set_value("escort_wait", false)
		traffic.set_lights(u.driver, false)
		u.set_role("patrol")
	if sfx != null and phase == Phase.CALM:
		sfx.police_siren(Vector3.INF)
	_log("escort left (%s)" % why)


## [hospital node, distances to it] for the rescue under way (cached by node, like the rivals'
## finishes), or [].
func _hospital_route() -> Array:
	var h: Vector3 = missions.target_position()
	var hit: Array = graph.snap(Vector2(h.x, h.z), 120.0, Vector2.ZERO, true)
	if hit.is_empty():
		return []
	var e: int = hit[0]
	var hp := Vector2(h.x, h.z)
	var node: int = graph.e_b[e]
	if graph.node_pos[graph.e_a[e]].distance_to(hp) < graph.node_pos[node].distance_to(hp):
		node = graph.e_a[e]
	if not _escort_routes.has(node):
		_escort_routes[node] = graph.distances_to(node)
	return [node, _escort_routes[node]]


## Driving distance left to the route's end from `p` (the nearer of the road's two ways), or the
## straight line x 1.3 off the roads.
func _route_left(route: PackedFloat32Array, p: Vector2) -> float:
	var hit: Array = graph.snap(p, 25.0)
	if hit.is_empty():
		return INF
	var e: int = hit[0]
	var best := graph.remaining(route, e, hit[2])
	var rev := graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, graph.remaining(route, rev, graph.e_len[e] - hit[2]))
	return best


## The player's place on the route's roads: [edge, lane, s] on the road nearest `p`, the way
## of it that leads on along the route; [] off the roads.
func _route_start(route: PackedFloat32Array, p: Vector2) -> Array:
	var hit: Array = graph.snap(p, 25.0, Vector2.ZERO, true)
	if hit.is_empty():
		hit = graph.snap(p, 60.0, Vector2.ZERO, true)
	if hit.is_empty():
		return []
	var e: int = hit[0]
	var s: float = hit[2]
	var rev := graph.e_reverse[e]
	if rev >= 0 and graph.remaining(route, rev, graph.e_len[e] - s) < graph.remaining(route, e, s):
		return [rev, 0, clampf(graph.e_len[e] - s, graph.e_s0[rev], graph.e_s1[rev])]
	return hit


## A spot on the route ahead of the player between `lo` and `hi` metres, out of sight:
## [edge, s, metres], or [].
func _route_spot(route: PackedFloat32Array, lo: float, hi: float) -> Array:
	var hit := _route_start(route, _xz(car.global_position))
	if hit.is_empty():
		return []
	var e: int = hit[0]
	var s: float = hit[2]
	var run := 0.0
	var guard := 0
	while run < hi and guard < 60:
		guard += 1
		var step := 10.0
		s += step
		run += step
		if s > graph.e_s1[e] - 2.0:
			var best := -1
			var best_d := INF
			for f in graph.node_out[graph.e_b[e]]:
				var c: float = graph.e_len[f] + route[graph.e_b[f]]
				if c < best_d:
					best_d = c
					best = f
			if best < 0 or route[graph.e_b[e]] <= 0.0:
				return []
			e = best
			s = graph.e_s0[e] + 2.0
		if run >= lo:
			var q := graph.point_at(e, s, graph.lane_offset(e, 0))
			if not traffic.on_screen(Vector3(q.x, graph.height(e, s), q.y), 2.0):
				return [e, s, run]
	return []


# --- loop 3g-2: the city guards' conversation --------------------------------------------------

## guards.gd: the car stopped by guard `g`: the guard conversation (police.dialogue guard_stop),
## the car held like a pull-over, no police, no cooldown after it.
func guard_talk(g) -> void:
	phase = Phase.PULLOVER
	_guard = g
	_talk_unit = null
	_talk_tag = "guard"
	_log("guard talk (post %s, tag \"%s\")" % [g.post, g.tag])
	if radio != null:
		radio.duck_db = -6.0
	hud.set_pedals_hidden(true)
	_freeze_heat(true)
	_start_talk("guard")


# --- loop 3g-2: the scripted first contact (police.md 1, 5.2) -----------------------------------

func _first_seen() -> bool:
	return wallet != null and "keep" in wallet and bool(wallet.keep.get(FIRST_KEY, false))


## Loop 3h slice 4: the first contact is armed (waiting to be set up, or set up), or done.
func first_armed() -> bool:
	return _first_seen() or _first_wait >= 0.0 or not _first.is_empty()


## Loop 3h slice 4: the guided first 10 minutes (first10.gd) arm the first contact when the first
## race never came (its beat's fallback): as the race would, FIRST_DELAY s from now. False if it
## was armed or done already.
func arm_first_contact() -> bool:
	if first_armed():
		return false
	_first_wait = FIRST_DELAY
	_log("first contact armed (the guide: no race yet)")
	return true


## Marks the first contact done in the save (once per save).
func _first_done(why: String) -> void:
	if _first_seen():
		return
	if wallet != null and "keep" in wallet:
		wallet.keep[FIRST_KEY] = true
		if wallet.has_method("save"):
			wallet.save()
	_log("first contact done (%s)" % why)


## Every frame: armed after the first race (or --first-contact), set up a patrol car parked by the
## kerb ahead with an officer; the officer waves the lizak at the player whatever the speed.
func _first_frame(dt: float) -> void:
	if _first_seen():
		if not _first.is_empty() and phase != Phase.LIZAK and phase != Phase.PULLOVER:
			_first_clear()
		return
	if _first.is_empty():
		if _first_wait < 0.0:
			if rivals != null and rivals.has_method("raced") and rivals.raced():
				_first_wait = FIRST_DELAY
				_log("first contact armed (the first race is over)")
			return
		_first_wait -= dt
		if _first_wait <= 0.0:
			if _first_tries >= FIRST_TRIES:
				_first_wait = INF
				return
			if phase != Phase.CALM or flying or _rescue_on() or (rivals != null and rivals.busy()) or not _place_first():
				_first_wait = 2.0
		return
	var t := _first
	_first_t += dt
	if t["unit"] == null:
		_first_clear()
		_first_wait = FIRST_RETRY
		return
	var p := _xz(car.global_position)
	if phase == Phase.CALM and (p.distance_to(t["car"]) > FIRST_DROP or _first_t > FIRST_LONGEST):
		_log("first contact dropped (%s)" % ("the player went elsewhere" if p.distance_to(t["car"]) > FIRST_DROP else "too long"))
		_first_clear()
		_first_wait = FIRST_RETRY
		return
	if phase != Phase.CALM or flying or _rescue_on() or clock < t["rearm"]:
		return
	var rel: Vector2 = p - t["officer"]
	var along := rel.dot(t["dir"])
	if along < -RADAR or along > 0.0 or absf(rel.cross(t["dir"])) > 14.0 or _xz(car.vel).dot(t["dir"]) <= 0.0:
		return
	t["rearm"] = clock + 10.0
	_lizak(t, car.vel.length(), -along)


## The first contact's patrol car on the player's road FIRST_AHEAD m ahead (straight on at the
## junctions), parked by the kerb facing the traffic, its officer 3 m upstream. False if no spot.
func _place_first() -> bool:
	if _edge < 0:
		return false
	_first_tries += 1
	var e := _edge
	var s := _s + FIRST_AHEAD
	var guard := 0
	while s > graph.e_s1[e] - 8.0 and guard < 30:
		guard += 1
		var here := graph.direction(e, graph.e_s1[e])
		var next := -1
		var best := 0.8
		for f in graph.node_out[graph.e_b[e]]:
			if f == graph.e_reverse[e]:
				continue
			var turn := absf(here.angle_to(graph.direction(f, graph.e_s0[f])))
			if turn < best:
				best = turn
				next = f
		if next < 0:
			return false
		s = graph.e_s0[next] + (s - graph.e_s1[e])
		e = next
	s = maxf(s, graph.e_s0[e] + 8.0)
	var n := graph.e_lanes[e]
	var kerb := graph.lane_offset(e, n - 1) + graph.e_lw[e] * 0.5
	var car_at := graph.point_at(e, s + 3.0, kerb + 1.5)
	var officer := graph.point_at(e, s, kerb + 0.9)
	if traffic.on_screen(_v3(car_at), 2.0):
		return false
	var dir := graph.direction(e, s)
	var t := {"id": 0, "road": graph.e_name[e], "car": car_at, "officer": officer, "dir": dir,
			"heading": -rad_to_deg(atan2(dir.x, dir.y)), "edge": e, "s": s + 3.0, "limit": graph.e_speed[e],
			"radio": ["", ""], "rearm": 0.0, "unit": null, "slot": FIRST_SLOT, "known": false, "waving": false, "first": true}
	_spawn_trap_car(t)
	if t["unit"] == null:
		return false
	_first = t
	_first_t = 0.0
	_log("first contact set up (unit %d parked on %s at %d,%d, %.0f m ahead)" % [t["unit"].number, t["road"],
			roundi(car_at.x), roundi(car_at.y), FIRST_AHEAD])
	return true


func _first_clear() -> void:
	var t := _first
	_first = {}
	if t.is_empty():
		return
	if walkers != null:
		walkers.clear_fixed(FIRST_SLOT)
	var u = t["unit"]
	if u != null and u.driver != null and u.role() == "trap":
		dismiss(u)


# --- the test drivers (flags) ----------------------------------------------------------------

## Frame-counted test starts: --police=N and --pullover=TAG at frame 60, --police-offence.
func _test_frame() -> void:
	if _frame == 60:
		var lvl := int(opts.get("level", 0))
		if lvl > 0:
			_test_chase(clampi(lvl, 1, 3))
	# Loop 3g-2: --escort (the person aboard at once), --guards (drive into the zone), --clamp,
	# --first-contact (set up the first contact now).
	if _frame == 30 and opts.get("escort", false) and missions != null and missions.has_method("board") and missions.state == 3:
		# At the pickup: the car where the person waited, the person aboard.
		var at: Vector3 = missions.target_position()
		car.global_position = at + Vector3(0, 0.3, 0)
		car.vel = Vector3.ZERO
		if car.has_method("reset_physics_interpolation"):
			car.reset_physics_interpolation()
		missions.board()
	if _frame == 2 and String(opts.get("guards", "")) != "":
		for w: Array in (GUARDS_TALK_ROUTE if opts["guards"] == "talk" else GUARDS_ROUTE):
			_waypoints.append(Vector2(w[0], w[1]))
	if _frame == 60 and String(opts.get("clamp", "")) != "":
		guards.test_clamp(String(opts["clamp"]) == "sorry")
	if _frame == 60 and opts.get("first_contact", false) and _first_wait < 0.0 and _first.is_empty():
		_first_wait = 0.0
		_log("first contact armed (--first-contact)")
	# Loop 2d-1: --pullover-frame=N moves the --pullover conversation (default frame 60).
	var po := String(opts.get("pullover", ""))
	if po != "" and _frame == int(opts.get("pullover_frame", 60)):
		_test_pullover(po)
	for o in _offences:
		if o[0] == _frame:
			var u = _nearest_unit()
			_log("test offence %s" % o[1])
			if o[1] == "ram":
				_offence("ram", u)
			else:
				_offence(o[1], u)


## --police=N: a chase at level N, the chaser 40 m behind on the player's lane.
func _test_chase(lvl: int) -> void:
	var d = _car_behind(40.0)
	if d == null:
		_log("no lane for the test chase")
		return
	var u = _bind(d, "patrol")
	if u == null:
		traffic.remove(d)
		return
	# Coming up at the road's pace, as a patrol car that saw something would.
	d.v = graph.e_speed[d.edge] * 0.6
	_track_player()
	_start_chase(lvl, u, "test")


## --pullover=TAG: the conversation at once, a patrol car stopped behind (routine, trap, kebab,
## sloik, generic).
func _test_pullover(tag: String) -> void:
	var d = _car_behind(12.0)
	var u = _bind(d, "patrol") if d != null else null
	_pull_over("" if tag == "generic" else tag, u)


## A police car `back` metres behind the player on their lane (the edge before it if need be).
func _car_behind(back: float):
	var p := _xz(car.global_position)
	var fwd := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit: Array = graph.snap(p, 12.0, fwd)
	if hit.is_empty():
		hit = graph.snap(p, 30.0)
	if hit.is_empty():
		return null
	var e: int = hit[0]
	var lane: int = hit[1]
	var s: float = hit[2] - back
	while s < graph.e_s0[e] + 1.0:
		var prev := -1
		for f in graph.node_in[graph.e_a[e]]:
			if f != graph.e_reverse[e]:
				prev = f
				break
		if prev < 0:
			s = graph.e_s0[e] + 1.0
			break
		s = graph.e_s1[prev] - (graph.e_s0[e] + 1.0 - s)
		lane = mini(lane, graph.e_lanes[prev] - 1)
		e = prev
	return traffic.add_police(e, lane, s)


## main.gd's _read_input, after the controls: the pull-over holds the car; the test drivers
## (--police-auto, --trap with --pedal=gas, the soak's roaming autopilot) drive it. True if
## the police took the car's controls this frame.
func control_car(c: CharacterBody3D, _dt: float) -> bool:
	# Loop 3g-2: the clamp holds the car too.
	if phase == Phase.PULLOVER or guards.holds():
		_drop_ghost(c)
		_brake(c)
		return true
	if flying:
		_drop_ghost(c)
		return false
	var mode := ""
	if auto == "follow" and _escort != null and _escort.driver != null:
		return _follow_escort(c)
	if not _waypoints.is_empty():
		return _drive_waypoints(c)
	if chasing():
		mode = auto
		if mode == "" and autopilot and now:
			mode = "escape" if _auto_flip % 2 == 0 else "stop"
	elif phase == Phase.LIZAK and auto == "stop":
		mode = "officer"
	elif pedal == "gas" and (int(opts.get("trap", 0)) > 0 or not _first.is_empty()):
		mode = "pedal"
	elif autopilot and now:
		mode = "roam"
	match mode:
		"stop", "still":
			_drop_ghost(c)
			_brake(c)
			return true
		"escape":
			return _ghost_drive(c, ESCAPE_TOP)
		"hold":
			return _ghost_drive(c, HOLD_SPEED)
		"roam":
			return _ghost_drive(c, maxf(_limit * ROAM_OVER, 8.0))
		"pedal", "officer":
			_drop_ghost(c)
			return _drive_at_trap(c, mode == "officer")
	_drop_ghost(c)
	return false


## Loop 3g-2, --guards: from the Krakowskie Przedmieście end north into the zone (map metres),
## held to 30 km/h before it (the zone's cap holds it to 20 inside), stopping at the last point.
## (Today's zone there is the pedestrian way's own strip, ~8 m wide: the route keeps to it.)
## --guards=talk stops by the gate's guards instead (the guard conversation).
const GUARDS_ROUTE := [[-706.0, -1318.0], [-714.0, -1334.0], [-708.0, -1346.0], [-704.0, -1366.0], [-704.0, -1392.0]]
const GUARDS_TALK_ROUTE := [[-706.0, -1318.0], [-714.0, -1334.0], [-708.0, -1346.0], [-705.0, -1360.0]]
const GUARDS_TOP := 30.0 / 3.6


func _drive_waypoints(c: CharacterBody3D) -> bool:
	var p := _xz(c.global_position)
	while _waypoints.size() > 1 and p.distance_to(_waypoints[0]) < 6.0:
		_waypoints.pop_front()
		_log("test drive: at %d,%d, %d km/h, %d points to go" % [roundi(p.x), roundi(p.y), roundi(c.vel.length() * 3.6), _waypoints.size()])
	var to := _waypoints[0] - p
	if _waypoints.size() == 1 and to.length() < 4.0:
		if c.vel.length() < 0.3 and not _waypoints_done:
			_waypoints_done = true
			_log("test drive: stopped at %d,%d (top speed in the zone after its first %.0f s: %d km/h)" % [roundi(p.x), roundi(p.y),
					guards.ZONE_SETTLE, roundi(guards._zone_top * 3.6)])
		_brake(c)
		return true
	c.parked = false
	c.target_dir = Vector3(to.x, 0.0, to.y).normalized()
	c.steer = 0.0
	var v: float = c.vel.length()
	c.throttle = 1.0 if v < GUARDS_TOP - 0.5 else 0.0
	c.braking = _waypoints.size() == 1 and to.length() < v * v / (2.0 * 6.0) + 4.0
	if c.braking:
		c.throttle = 0.0
	return true


## Loop 3g-2, --police-auto=follow: the car rides a ghost along the escort's route (queueing behind
## the cars ahead, the escort among them), then the last metres to the hospital's ring straight.
func _follow_escort(c: CharacterBody3D) -> bool:
	var u = _escort
	var h: Vector3 = missions.target_position()
	var p := _xz(c.global_position)
	var to := Vector2(h.x, h.z) - p
	if _follow_last or to.length() < 45.0 or (_ghost != null and (_ghost.arrived or traffic.remaining(_ghost) < 45.0)):
		_follow_last = true
		_drop_ghost(c)
		if _mask < 0:
			_mask = c.collision_mask
		c.collision_mask = 0
		c.vel = Vector3.ZERO
		c.throttle = 0.0
		if log_on and _frame % 60 == 0:
			_log("test drive: %.1f m from the hospital's ring, %.1f m above it, %.1f m/s" % [to.length(), c.global_position.y - h.y, c.vel.length()])
		if to.length() > 1.0:
			var step := minf(to.length(), 14.0 * get_process_delta_time())
			var dir := to.normalized()
			c.global_position += Vector3(dir.x, 0.0, dir.y) * step
			c.rotation.y = atan2(-dir.x, -dir.y)
		return true
	if _ghost == null:
		var hit := _route_start(u.escort_route, p)
		if hit.is_empty():
			return false
		_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
		_ghost.v = c.vel.length()
		if _mask < 0:
			_mask = c.collision_mask
		traffic.race_to(_ghost, u.escort_node, u.escort_route)
	# Following, not passing: it keeps 12 m or more behind the escort along the route.
	var gap: float = _escort_lead if _escort_state == "lead" else INF
	_ghost.v_cap = 16.0 if gap > 22.0 else (maxf(u.driver.v + 1.0, 1.0) if gap > 12.0 else 0.5)
	_ghost.accel_factor = 2.0
	_ghost.squeeze = 0.0
	c.collision_mask = 0
	c.global_position = _ghost.pos
	c.rotation.y = _ghost.yaw
	c.vel = Vector3(-sin(_ghost.yaw), 0.0, -cos(_ghost.yaw)) * _ghost.v
	c.throttle = 0.0
	c.braking = false
	c.target_dir = Vector3.ZERO
	return true


## On the brake; stopped, parked (car.gd: a held brake at a standstill would reverse it into the
## police car behind).
func _brake(c: CharacterBody3D) -> void:
	c.target_dir = Vector3.ZERO
	c.throttle = 0.0
	c.steer = 0.0
	c.braking = true
	if c.vel.length() < 0.5:
		c.parked = true


## Along a trap's road, flat out into its radar (--trap=N --pedal=gas); `stop` brakes to stop by
## the officer.
func _drive_at_trap(c: CharacterBody3D, stop: bool) -> bool:
	var t: Dictionary = _lizak_trap
	if t.is_empty():
		for k in traps:
			if k["id"] == int(opts.get("trap", 0)):
				t = k
	if t.is_empty() and not _first.is_empty():
		t = _first
	if t.is_empty():
		return false
	# Through the traffic, like the other test drivers (a car in the lane would stop the run).
	if _mask < 0:
		_mask = c.collision_mask
	c.collision_mask = 0
	var p := _xz(c.global_position)
	var dir: Vector2 = t["dir"]
	var right := Vector2(-dir.y, dir.x)
	var lane: Vector2 = t["officer"] - right * 3.0
	var along: float = (p - t["officer"]).dot(dir)
	var aim: Vector2 = lane + dir * (along + 25.0)
	var to := (aim - p).normalized()
	c.target_dir = Vector3(to.x, 0.0, to.y)
	c.steer = 0.0
	var v: float = c.vel.length()
	if stop and (-along < v * v / (2.0 * 22.0) + 3.0 or v < 0.6):
		_brake(c)
		return true
	c.throttle = 1.0
	c.braking = false
	return true


## The car rides on a traffic ghost (like the race and job autopilots): `top` m/s, through the
## traffic, at random at junctions.
func _ghost_drive(c: CharacterBody3D, top: float) -> bool:
	if _ghost == null or not _ghost.active or Vector2(_ghost.pos.x - c.global_position.x, _ghost.pos.z - c.global_position.z).length() > 20.0:
		_drop_ghost(c)
		var p := _xz(c.global_position)
		var fwd := Vector2(-sin(c.rotation.y), -cos(c.rotation.y))
		var hit: Array = graph.snap(p, 25.0, fwd, true)
		if hit.is_empty():
			hit = graph.snap(p, 60.0, Vector2.ZERO, true)
		if hit.is_empty():
			return false
		_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
		_ghost.v = c.vel.length()
		if _mask < 0:
			_mask = c.collision_mask
		if chasing():
			_auto_flip += 1
			if top == ESCAPE_TOP:
				# Beta values (2026-11-04): the escape is a player driving flat out, so the ghost
				# drives in racer mode like rivals.gd's `--ghost-pace=racer` (the car's own top,
				# corners by their radius, through reds). As a town car it took every corner at
				# ~20 km/h, and once the chasers raced (#426) they never lost sight of it (P3, R1).
				_ghost.race_top = float(c.max_speed) * float(c.top_mult)
				_ghost.race_accel = ESCAPE_ACCEL
				_ghost.race_lat = ESCAPE_LAT
				_escape_route()
	_ghost.v_cap = top
	_ghost.accel_factor = 5.0
	_ghost.squeeze = 1.0
	c.collision_mask = 0
	c.global_position = _ghost.pos
	c.rotation.y = _ghost.yaw
	c.vel = Vector3(-sin(_ghost.yaw), 0.0, -cos(_ghost.yaw)) * _ghost.v
	c.throttle = 0.0
	c.braking = false
	c.target_dir = Vector3.ZERO
	return true


## Loop 3d-1 (the test autopilot only, --police-auto=escape): the escape rides a route to a node
## ESCAPE_REACH m out on the side away from the chaser, not random turns. On the demo map's bigger
## lane graph the random turns from the spawn went south, east, then back north-west past the
## chaser's side, where a traffic patrol saw the car within 60 m at 20 s (police.md's second-unit
## rule: L2, cap 40 s) and P3's L1 escape came at 34.2 s. Nothing the player meets changes.
const ESCAPE_REACH := 900.0
## The escape ghost's racer numbers (rivals.gd's skilled ghost: accel 12 m/s², 8.5 m/s² in corners).
const ESCAPE_ACCEL := 12.0
const ESCAPE_LAT := 8.5
func _escape_route() -> void:
	var u = _chaser()
	var p := Vector2(_ghost.pos.x, _ghost.pos.z)
	var away := Vector2(_ghost.pos.x, _ghost.pos.z) - Vector2(u.driver.pos.x, u.driver.pos.z) if u != null else Vector2.ZERO
	away = away.normalized() if away.length() > 1.0 else Vector2(-sin(_ghost.yaw), -cos(_ghost.yaw))
	var best := -1
	var best_score := -INF
	for n in graph.node_pos.size():
		if graph.node_scc[n] == 0:
			continue
		var q := graph.node_pos[n] - p
		var d := q.length()
		if d < ESCAPE_REACH * 0.6 or d > ESCAPE_REACH * 1.4:
			continue
		var score := q.dot(away) / d - absf(d - ESCAPE_REACH) / ESCAPE_REACH
		if score > best_score:
			best_score = score
			best = n
	if best >= 0:
		traffic.race_to(_ghost, best, graph.distances_to(best))
		_log("escape route to node %d at %s (test autopilot)" % [best, graph.node_pos[best].round()])


func _drop_ghost(c: CharacterBody3D) -> void:
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null
	if _mask >= 0:
		c.collision_mask = _mask
		_mask = -1


## The soak's checks (--police-log): the player's car on screen during a chase (DEMO bar B4: never
## within 20 % of an edge), and how far moving police cars stray from a lane.
func _b4() -> void:
	if cam == null or flying:
		return
	var vp := cam.get_viewport().get_visible_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return
	var q := cam.unproject_position(car.global_position) / vp
	var edge := minf(minf(q.x, 1.0 - q.x), minf(q.y, 1.0 - q.y))
	_b4_worst = minf(_b4_worst, edge)
	print("police: b4 x %.2f y %.2f%s" % [q.x, q.y, "" if edge >= 0.2 else " (inside 20 %% of an edge)"])


func _lane_check() -> void:
	for u in _units:
		var d = u.driver
		if d == null or d.parked or d.in_conn:
			continue
		var best := INF
		for k in graph.e_lanes[d.edge]:
			best = minf(best, absf(d.off - graph.lane_offset(d.edge, k)))
		_lane_worst = maxf(_lane_worst, best)


static func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, map.ground_height(p.x, p.y), p.y)
