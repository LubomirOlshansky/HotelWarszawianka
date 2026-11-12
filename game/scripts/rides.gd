extends Node
## Loop 2d-1: Podwózka, the app-taxi side job (docs/design/parodies.md 3.3; the rules and the
## pay are ride_rules.gd, the GPS moments of the app-taxis in traffic gps_moments.gd).
##
## Start: in the car with nothing else on (one activity at a time, like the kebab and słoiki
## jobs) and not in the first 2 minutes: a request card at the bottom every 75-120 s (not
## modal, gone after 10 s), or the context button PODWÓZKA in the top row (a request within
## 2 s). Pickup: the app's pin (teal ring and column, the minimap dot) at a real address door
## 150-600 m by road; half the time the passenger waits 30-60 m away instead, waving under a
## teal "!" (the pin is a bit off). Stop within 7 m of them under 2.5 m/s for 1 s. The ride:
## to a real address 600-2,500 m by road or one of the race finishes; the beacon and the arrow
## always point at the real door, the minimap's dotted line is the app's idea, and 35 % of
## rides get one quirk (the river's edge, a park's paths, a recalculation; the Old Town square
## and the Frogs turn (quirk id `rechotka`; loop MW-2: in the pool once the Frogs exist, at a junction
## with a Frogs on it), said by "Nawigacja" 200 m before it. Loop MW-2: a `detour` passenger (DETOUR_SHARE
## of the rides once there are Frogs) asks for a stop at one: stopped by any Frogs door, +½. Stars live
## in the status panel; at the door a result card with the passenger's comment and the pay.
## Cancel: the ✕ any time, or the passenger after 3 × the ETA: no pay, the streak ends. The
## police loop calls on_pulled_over() (one star).

const Access := preload("res://scripts/access.gd")
const Rules := preload("res://scripts/ride_rules.gd")
const Beacon := preload("res://scripts/beacon.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const Missions := preload("res://scripts/missions.gd")
const GpsMoments := preload("res://scripts/gps_moments.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Jobs := preload("res://scripts/jobs.gd")
const Stories := preload("res://scripts/taxi_stories.gd")

## Teal: the passengers' job colour (the słoiki run's).
const COLOUR := Color("#4fd8c4")
const FAIL_COLOUR := Color("#e2574c")
const PICKUP_MIN := 150.0
const PICKUP_MAX := 600.0
const RIDE_MIN := 600.0
const RIDE_MAX := 2500.0
const NAMED_SHARE := 0.3
const OFFSET_SHARE := 0.5
const OFFSET := Vector2(30.0, 60.0)
const QUIRK_SHARE := 0.35
## Passenger types (*guess*): normal 65 %, GPS believer 25 %, in a hurry 10 %.
const BELIEVER_SHARE := 0.25
const HURRY_SHARE := 0.10
## G3 leftover: in the evening (18:00-01:00) a "timber" passenger, off to a date from the dating
## app TIMBER, takes this share of the normal rides (club doors at dawn still win).
const TIMBER_SHARE := 0.2
const DATE_SHARE := 0.08  # a date at Pod Gigantami
const DATE_DOOR := Vector2(-36.0, 778.0)  # its gate, on Aleje Ujazdowskie
const TIMBER_HOURS := [18.0, 25.0]
const BOARD := StopAssist.RING
const BOARD_SPEED := StopAssist.STOP_SPEED
const BOARD_HOLD := 1.0
## G10: this close (m) to the waiting passenger the context button reads START KURS and a tap
## starts the ride (no stopping in a ring needed). The rider's "!" is drawn BANG_SCALE times larger.
const START_REACH := 25.0
const BANG_SCALE := 1.6
const ARRIVE := StopAssist.RING
const ARRIVE_SPEED := StopAssist.STOP_SPEED
## A quirk's waypoint counts as driven within REACH; Nawigacja speaks SAY_AT from it; a believer
## grumbles once the car is within PASSED of the waypoint's distance to the door, without it.
const REACH := 15.0
const SAY_AT := 200.0
const PASSED := 0.5
## A quirk's leg is silly, not a tour: at most this much longer than the shortest road.
const DETOUR_MAX := 1500.0
const FIRST_OFFER := 120.0
const OFFER_GAP := Vector2(75.0, 120.0)
const OFFER_LIFE := 10.0
## A held request (`guide_hold`) comes at least this long after the hold lets go.
const HOLD_GAP := 30.0
const PILL_DELAY := 1.2
const CHAT_GAP := Vector2(25.0, 40.0)
## The river spots: a waypoint RIVER_INLAND m in from the water's edge, dry for RIVER_DRY m all
## round, at most RIVER_ROAD m from a road (straight and clear). The water's edge comes from the
## map's global water test (shore_distance), sampled every SCAN m, SCAN_ROWS rows a frame (loop
## 3c: the streamed city's exported index has no shore runs), then RIVER_BUDGET edge points a frame.
const RIVER_INLAND := 5.0
const RIVER_DRY := 3.0
const RIVER_ROAD := 70.0
const SCAN := 8.0
const SCAN_ROWS := 3
const RIVER_BUDGET := 24
const QUIRKS := ["river", "zone", "reroute"]
## Loop MW-2: with the Frogs placed (storefronts.gd) their turn joins the pool, and this share of
## the rides has a `detour` passenger *guess*; the stop: by a Frogs door under DETOUR_SPEED m/s for
## DETOUR_HOLD s; the Frogs turn's junction needs a Frogs within FROGS_TURN m.
const DETOUR_SHARE := 0.15
const DETOUR_SPEED := 2.0
const DETOUR_HOLD := 2.0
const FROGS_TURN := 30.0
## The result card comes this long after the arrival (Nawigacja's line first), and goes by itself
## RESULT_LIFE s later or once the car is RESULT_OFF m away (no button: M closes it too).
const RESULT_AFTER := 2.6
const RESULT_LIFE := 12.0
const RESULT_OFF := 25.0
const SHIRTS := ["#3b8f5a", "#2f6fb5", "#7a4fb5", "#c9b458", "#4c6650", "#5d6f8a"]

enum State { IDLE, OFFER, PICKUP, RIDE, RESULT }

var hud: CanvasLayer
var bubbles: Control
var dialogue: Node
var wallet: Node
var missions: Node
var rivals: Node
var jobs: Node
var graph: LaneGraph
var traffic: Node3D
var map: Node3D
var car: CharacterBody3D
var tod: Node
var weather: Node
var moments: Node
## Loop MW-2: the Frogs (storefronts.gd: shop_near, frogs_at_junction); null: none placed.
var frogs: Node
var state := State.IDLE
## Set by the game each frame: in the helicopter; `away`: the title screen or the bench is up
## (no offers, and the first 2 minutes wait).
var flying := false
var away := false
## Loop MW-6: Spacer (spacer.gd): a request comes only when the PODWÓZKA button is tapped.
var quiet := false
## The first-10 guide (first10.gd `_hold_offers`): a beat is due, so no request comes by itself
## until it has fired; the PODWÓZKA button still asks for one.
var guide_hold := false
## Testing: --autopilot drives the app's route (--ignore-app: the shortest one); --parody-log
## prints `ride:` lines; --ride-quirk, --passenger and --stars force the quirk, the passenger
## type and the live rating's start.
var autopilot := false
var ignore_app := false
var log_on := false
var force_quirk := ""
var force_passenger := ""
## --ride-story=ID: that story passenger on the next rides ("none": no story); --ride-answer=0|1:
## what the autopilot answers to the question (0 when not given).
var force_story := ""
var force_answer := -1
## Story rides (taxi_stories.gd): the list, the next beat (0-2 lines, 3 the question, 4 done), the
## seconds since the last one, and the question card while it is up.
var _stories: Array = []
var _beat := 0
var _beat_since := 0.0
var _asking := false
var _ask_t := 0.0
## Story lines said and questions answered (tools/check_rides.gd, the logs).
var story_lines := 0
var story_answers := 0
var start_stars := -1.0
## Loop MW-3 (vision.md 4.5, 4.7): at dawn the requests come from the club doors: -> [[club id,
## door: Vector2], ...] while the dawn crowd is out (crowds.gd), else []. Unset: none.
var club_doors: Callable
## F 2026-11-10: true while any mission, race, job, questline or tour is on (main.gd); PODWÓZKA
## stays off the context button for all of it.
var mission_on: Callable
## Loop MW-4 (vision.md 3.7, 4.7): where a `hurry` passenger goes now, -> Vector2 (Saturday
## morning: the Hyrax forecourt by the stadium, a late competitor; city_life.gd hurry_target), INF
## for anywhere. Unset: anywhere.
var hurry_to: Callable
## --gps-in=S: the first GPS moment in traffic from S seconds in (gps_moments.gd).
var gps_first := -1.0
## How long the last update took, for --bench (µs), and the physics step's sum.
var last_usec := 0
var spent_usec := 0
## River spots: {e, s, road: Vector2, w: Vector2, gap, water}, one per road edge.
var river_spots: Array[Dictionary] = []

var _ride: Dictionary = {}
## The result card waits RESULT_AFTER s for Nawigacja's arrival line: [text, accent].
var _result_card: Array = []
var _result_in := 0.0
var _result_at := Vector3.ZERO
var _rules := Rules.new()
var _session := 0.0
var _t := 0.0
var _offer_in := -1.0
var _pill_at := -1.0
var _rides := 0
var _offers := 0
var _base := 0
var _hold := 0.0
var _said_pickup := false
var _said_quirk := false
## "" (not yet), "reached", "ignored" (can still turn "reached"), "reroute" (done).
var _quirk_done := ""
var _chat_t := 0.0
## Loop MW-2: the detour's stop (seconds held by a Frogs door) and whether it has been asked for.
var _detour_hold := 0.0
var _detour_said := false
var _route := PackedVector2Array()
var _legs: Array[Dictionary] = []
var _leg := 0
var _ghost = null
var _stall := 0.0
var _beacon: Node3D
var _rider: Node3D
var _rider_mesh: MeshInstance3D
var _bang: MeshInstance3D
var _gps_anchor: Callable
var _addresses: Array[Dictionary] = []
var _parks: Array[Dictionary] = []
var _spawn_lane: Array = []
var _river_todo: Array = []
var _scan_row := 0
var _scan_rows := 0
var _scan_cols := 0
var _scan_origin := Vector2.ZERO
var _scan_prev := PackedByteArray()
var _scan_usec := 0
var _river_raw: Array[Dictionary] = []
var _river_ready := false
## Braking and cornering, smoothed like the słoiki's (jobs.gd).
var _brake_s := 0.0
var _lat_s := 0.0
var _last_v := 0.0
var _last_yaw := 0.0
var _have_last := false
var _rng := RandomNumberGenerator.new()
## Phase 0.2: the drive penalties waiting for their one merged toast (_drive_note).
const DRIVE_MERGE := 3.0
var _drive_sum := 0.0
var _drive_quiet := 0.0
var _drive_words: Array = []
var _drive_counts: Array[int] = []
## How many merged drive toasts were shown (tools/check_chatter.gd).
var drive_toasts := 0


func setup(nodes: Dictionary, data: Dictionary, world: Node3D) -> void:
	hud = nodes["hud"]
	bubbles = nodes["bubbles"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	missions = nodes["missions"]
	rivals = nodes["rivals"]
	jobs = nodes["jobs"]
	graph = nodes["graph"]
	traffic = nodes["traffic"]
	map = nodes["map"]
	car = nodes["car"]
	tod = nodes["tod"]
	weather = nodes.get("weather")
	_rng.randomize()
	_base = _rng.randi() % 100000
	_stories = Stories.load_all()
	var t0 := Time.get_ticks_msec()
	for p in data.get("pois", []):
		match String(p["k"]):
			"address":
				var door: Array = p["door"]
				_addresses.append({"name": p["name"], "door": Vector2(door[0], door[1]), "at": Vector2(p["x"], p["z"]),
						"d": String(p.get("d", ""))})
			"park":
				var w := Vector2(p["x"], p["z"])
				if not _wet(w, 2.0) and not _roofed(w):
					_parks.append({"name": String(p["name"]), "w": w})
	var sp: Dictionary = data.get("spawn", {})
	_spawn_lane = graph.snap(Vector2(float(sp.get("x", 0.0)), float(sp.get("z", 0.0))), 60.0, Vector2.ZERO, true, true)
	if not _bank_spots(data):  # map round 2b: the bake's drivable river spots, else the scan
		_queue_river()
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color(SHIRTS[0]))
	_build_rider(world)
	_gps_anchor = func() -> Vector3: return car.global_position + Vector3(0, 3.4, 0)
	_offer_in = _rng.randf_range(OFFER_GAP.x, OFFER_GAP.y)
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func():
		if state == State.PICKUP or state == State.RIDE:
			_cancel(false))
	hud.context_pressed.connect(_on_context)
	car.bumped.connect(_on_bump)
	if traffic != null:
		moments = GpsMoments.new()
		moments.traffic = traffic
		moments.dialogue = dialogue
		moments.log_on = log_on
		moments.first_in = gps_first
		add_child(moments)
	print("rides: %d addresses, %d parks in %d ms; the river's edge: %d × %d water samples to scan" % [_addresses.size(),
			_parks.size(), Time.get_ticks_msec() - t0, _scan_cols, _scan_rows])


## The waiting passenger: a person (one mesh) and a teal "!" over them (one mesh).
func _build_rider(world: Node3D) -> void:
	_rider = Node3D.new()
	_rider_mesh = MeshInstance3D.new()
	_rider_mesh.material_override = Models.material()
	_rider_mesh.scale = Vector3.ONE * 1.35
	_rider.add_child(_rider_mesh)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cube(st, Vector3(0, 3.65, 0), Vector3(0.55, 1.1, 0.55))
	_cube(st, Vector3(0, 2.8, 0), Vector3(0.55, 0.42, 0.55))
	st.generate_normals()
	_bang = MeshInstance3D.new()
	_bang.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = COLOUR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bang.material_override = m
	_bang.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bang.scale = Vector3.ONE * BANG_SCALE
	_rider.add_child(_bang)
	_rider.visible = false
	world.add_child(_rider)


static func _cube(st: SurfaceTool, c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var corners := [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
			Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]
	for f in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [0, 4, 7, 3], [1, 2, 6, 5]]:
		var q: Array = []
		for k in f:
			q.append(c + (corners[k] as Vector3) * h)
		for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
			st.add_vertex(v)


# --- the game's view of the job ----------------------------------------------------------------

func busy() -> bool:
	return state != State.IDLE and state != State.OFFER


func has_target() -> bool:
	return state == State.PICKUP or state == State.RIDE


## PT-15: a request card is up, waiting for ACCEPT / SKIP.
func offering() -> bool:
	return state == State.OFFER


## The pin (then the passenger, once the car is near the pin or them), or the ride's real door.
func target_position() -> Vector3:
	if state == State.PICKUP:
		var near: bool = _flat(car.global_position, _ride["pin"]) < 30.0 or _flat(car.global_position, _ride["board"]) < 70.0
		return _ride["board"] if near else _ride["pin"]
	return _ride["ring"]


## Where the car should stop now (stop_assist.gd): the passenger once the arrow points at them
## (never the pin, which is only roughly where they wait), then the door.
func stop_spot() -> Vector3:
	if state == State.RIDE:
		return _ride["ring"]
	if state == State.PICKUP and target_position() == _ride["board"]:
		return _ride["board"]
	return Vector3.INF


func target_colour() -> Color:
	return COLOUR


## Keyboard: M accepts a request or closes the result card, K skips a request.
func primary() -> bool:
	if state == State.OFFER or (state == State.RESULT and _result_in <= 0.0):
		_on_card(0)
		return true
	return false


func secondary() -> bool:
	if state == State.OFFER:
		_on_card(1)
		return true
	return false


## The police loop (3g-2) calls this when the player has been pulled over with a passenger on
## board (police.md 8.3): exactly one star. Escaping a chase costs nothing (don't call it).
func on_pulled_over() -> void:
	if state != State.RIDE:
		return
	_rules.pull_over()
	_star_note(-Rules.POLICE, "police", ["policja", "police"])


## --ride=N: ride N's request, the car on the road 60 m before its passenger (the same N gives
## the same ride, wherever the car is). With --ride-quirk=river or zone the passenger is picked
## near a place for it (river spot or park N), so the quirk's leg fits the ride.
func start_ride(n: int) -> bool:
	if _spawn_lane.is_empty():
		return false
	_finish_river_spots()
	var places: Array = []
	if force_quirk == "river":
		for sp in river_spots:
			places.append(sp["road"])
	elif force_quirk == "zone" or force_quirk == "oldtown":
		for park in _parks:
			places.append(park["w"])
	var r := {}
	# The place N first, then the next ones (a spot on the Praga bank has no west-bank door near).
	for k in places.size():
		var hit := graph.snap(places[posmod(n + k, places.size())], 70.0, Vector2.ZERO, true, true)
		if not hit.is_empty():
			r = _make_ride(n, hit[0], hit[2], graph.point_at(hit[0], hit[2]), PICKUP_MIN, PICKUP_MAX)
		if not r.is_empty():
			break
	if r.is_empty():
		var e: int = _spawn_lane[0]
		var s: float = _spawn_lane[2]
		r = _make_ride(n, e, s, graph.point_at(e, s), 0.0, 3000.0)
	if r.is_empty():
		print("podwózka ride %d: no ride (no address fits)" % n)
		return false
	# Back along the passenger's own street (as far as it goes), on their side of it.
	var pe: int = r["p_e"]
	var ps: float = r["p_s"]
	var heading: Vector2 = r["heading"]
	var along := 1.0 if heading.dot(graph.direction(pe, ps)) > 0.0 else -1.0
	var back := clampf(ps - along * 60.0, graph.e_s0[pe] + 1.0, graph.e_s1[pe] - 1.0)
	var at: Vector2 = graph.point_at(pe, back) + ((r["kerb"] as Vector2) - graph.point_at(pe, ps))
	var y: float = graph.surface(pe, at)
	car.global_position = Vector3(at.x, y, at.y)
	car.rotation.y = atan2(-r["heading"].x, -r["heading"].y)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	r["away"] = _flat(car.global_position, r["pin"])
	_log("the car at %d,%d heading %d°, the passenger at %d,%d (%d m), the pin at %d,%d" % [roundi(at.x), roundi(at.y),
			roundi(rad_to_deg(atan2(heading.x, -heading.y))), roundi(r["kerb"].x), roundi(r["kerb"].y),
			roundi(at.distance_to(r["kerb"])), roundi(r["pin"].x), roundi(r["pin"].z)])
	missions.close()
	_show_offer(r)
	return true


# --- every frame --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if graph == null:
		return
	var t0 := Time.get_ticks_usec()
	if not away:
		_session += dt
	_t += dt
	_drive_tick(dt)
	if not _river_ready:
		_river_step(RIVER_BUDGET)
	match state:
		State.IDLE:
			_idle_tick(dt)
		State.OFFER:
			_offer_tick()
		State.PICKUP:
			_pickup_tick(dt)
		State.RIDE:
			_ride_tick(dt)
		State.RESULT:
			if _result_in > 0.0:
				_result_in -= dt
				if _result_in <= 0.0:
					var card: Array = _result_card
					var text: Array = card[0]
					hud.show_side_card(text[0], text[1], PackedStringArray(), card[1], text[2], text[3])
					_result_at = car.global_position
					_t = 0.0
			elif _t > RESULT_LIFE or _flat(car.global_position, _result_at) > RESULT_OFF:
				_release()
	# One card at a time: while a ride's request or result is up (or about to be), the app-taxis'
	# GPS bubbles and the radio host wait; they come after.
	var card_up := state == State.OFFER or state == State.RESULT or _asking
	if moments != null:
		moments.held = card_up
	dialogue.host_hold = card_up
	if _rider.visible:
		# Waving: a little hop and the "!" bobbing.
		_bang.position.y = 0.15 * sin(_t * 6.0)
		_rider_mesh.position.y = maxf(0.0, 0.12 * sin(_t * 9.0))
	last_usec = Time.get_ticks_usec() - t0 + (moments.last_usec if moments != null else 0)


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


## Harsh braking and fast corners, measured as the słoiki are (jobs.gd), cost stars.
func _step(dt: float) -> void:
	# The autopilot puts the car on its ghost's path (its turns are steps, not driving).
	if state != State.RIDE or dt <= 0.0 or flying or autopilot:
		_have_last = false
		return
	var v: float = car.forward_speed
	var yaw := car.rotation.y
	if not _have_last:
		_last_v = v
		_last_yaw = yaw
		_have_last = true
		return
	var a_long: float = (v - _last_v) / dt
	var lat := absf(v * angle_difference(_last_yaw, yaw) / dt)
	_last_v = v
	_last_yaw = yaw
	if absf(a_long) < 60.0:
		var k := 1.0 - exp(-dt / 0.12)
		_brake_s = lerpf(_brake_s, maxf(0.0, -a_long * signf(v)), k)
		_lat_s = lerpf(_lat_s, minf(lat, 60.0), k)
	if _rules.drive_event("brake", _brake_s):
		_drive_note("braking %.0f m/s²" % _brake_s, ["hamowanie", "hamowania", "harsh braking", "harsh braking"])
	elif _rules.drive_event("corner", _lat_s):
		_drive_note("corner %.0f m/s²" % _lat_s, ["zakręt", "zakręty", "fast corner", "fast corners"])


func _on_bump(_collider: Object, speed: float) -> void:
	if state == State.RIDE and _rules.drive_event("bump", speed):
		_drive_note("bump %.1f m/s" % speed, ["stłuczka", "stłuczki", "bump", "bumps"])


# --- offers --------------------------------------------------------------------------------------

## Nothing else on: no rescue, race, kebab or słoiki, not flying, no call's card up. A call
## ringing (WEZWANIE waiting on the context button) doesn't stop a request card: taking the
## ride puts the call off, as any job does.
func _free() -> bool:
	if flying or away or car.in_water or missions.has_target() or not _calls_quiet():
		return false
	if mission_on.is_valid() and bool(mission_on.call()):
		return false
	if state == State.IDLE and hud != null and hud.cards_up():
		return false  # no request over a result or win card (2026-11-08)
	if jobs != null and jobs.side_busy():
		return false  # loop MW-4: the "Na czasie" job too
	# PT-15 (2026-11-03): nor while a rival's prompt is up or Pani Halina rolls up to flash for the
	# first race (rivals.gd `calling`): a "New ride" card came up over her flash-back offer.
	return rivals == null or not (rivals.busy() or rivals.calling())


func _calls_quiet() -> bool:
	return missions.state == Missions.State.CLOSED or missions.state == Missions.State.RINGING


func _idle_tick(dt: float) -> void:
	var free := _free() and _session >= FIRST_OFFER
	if not free:
		_set_pill(false)
		_pill_at = -1.0
		return
	# The context button is the call's while one rings.
	_set_pill(missions.state == Missions.State.CLOSED)
	_offer_in -= dt
	if guide_hold:
		_offer_in = maxf(_offer_in, HOLD_GAP)  # a beat comes first; a request a while after it
	if (_offer_in <= 0.0 and not quiet and not guide_hold) or (_pill_at >= 0.0 and _t - _pill_at >= PILL_DELAY):
		_pill_at = -1.0
		_offer_in = _rng.randf_range(OFFER_GAP.x, OFFER_GAP.y)
		_offer_here()


## The top row's context button reads PODWÓZKA while the player could take a ride.
func _set_pill(on: bool) -> void:
	var shown: bool = hud.pill_shown("ride")
	if on and not shown and hud.pill_free_for("ride"):
		hud.show_pill("PODWÓZKA", "ride app", "ride")
	elif not on and shown:
		hud.hide_pill()


## G10: the context button reads START KURS while the passenger waits within START_REACH.
func _set_start(on: bool) -> void:
	var shown: bool = hud.pill_shown("ride_start")
	if on and not shown and hud.pill_free_for("ride_start"):
		hud.show_pill("START KURS", "start the ride", "ride_start")
	elif not on and shown:
		hud.hide_pill()


func _on_context(owner: String) -> void:
	if owner == "ride_start":
		if state == State.PICKUP and not flying:
			_set_start(false)
			_board()
		return
	if owner == "ride" and state == State.IDLE and _pill_at < 0.0:
		_pill_at = _t
		hud.toast("Szukam kursu…", "Finding you a ride…")


## G12 part 2: the AUTO list may offer "ask for a ride" now (the PODWÓZKA button's rule: in the
## car, nothing else on, past the first FIRST_OFFER seconds).
func can_request() -> bool:
	return state == State.IDLE and _free() and _session >= FIRST_OFFER


## G12 part 2: the AUTO list's request: as a tap on PODWÓZKA (a request within PILL_DELAY s).
func request() -> void:
	if can_request():
		_on_context("ride")


## A request from near where the car is.
func _offer_here() -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true, true)
	if hit.is_empty():
		hit = graph.snap(p, 60.0, Vector2.ZERO, true, true)
	if hit.is_empty():
		return
	# Each request a new passenger (a skipped one isn't offered again).
	_offers += 1
	var r := _make_ride(_base + _offers, hit[0], hit[2], p, PICKUP_MIN, PICKUP_MAX)
	if r.is_empty():
		return
	_show_offer(r)


func _show_offer(r: Dictionary) -> void:
	_ride = r
	state = State.OFFER
	_t = 0.0
	_set_pill(false)
	var text := Rules.offer_text({"name": r["name"], "away": r["away"], "road": r["road"], "their": r["their"],
			"note": r["note"], "night": r["night"], "rain": r["rain"], "rating": _rating()})
	hud.show_side_card(text[0], text[1], PackedStringArray(["ACCEPT", "SKIP"]), COLOUR, text[2], text[3])
	hud.ticker_out()
	print("podwózka ride %d: %s (%s) at %s, %d m away, to %s, %d m by road%s" % [r["n"], r["name"], r["type"], r["pin_name"],
			roundi(r["away"]), r["dest"], roundi(r["road"]), (", quirk " + String(r["quirk"])) if r["quirk"] != "" else ""])
	_log("offer %d: %s, a %s passenger (★ %.1f), pin at %s %d m away%s, to %s (%d m by road, ETA %d s), quirk %s, surge ×%.1f, your rating %.2f" % [
			r["n"], r["name"], r["type"], r["their"], r["pin_name"], roundi(r["away"]),
			(", waiting %d m from the pin" % roundi(r["off_m"])) if r["offset"] else "", r["dest"], roundi(r["road"]),
			roundi(r["eta"]), r["quirk"] if r["quirk"] != "" else "none", Rules.multiplier(r["night"], r["rain"]), _rating()])


## The request waits 10 s (the autopilot takes it after 2); a rescue call opened over it, or
## anything else starting, takes it away.
func _offer_tick() -> void:
	if not _calls_quiet() or (jobs != null and jobs.side_busy()) or (rivals != null and rivals.busy()):
		state = State.IDLE  # their card is up now, not ours
		return
	if rivals != null and rivals.calling():
		_withdraw()  # PT-15: her prompt is a strip, not a card: ours must go, not hide behind it
		return
	if flying or away:
		_withdraw()
		return
	if autopilot and _t > 2.0:
		_accept()
	elif _t > OFFER_LIFE:
		_withdraw()


func _withdraw() -> void:
	hud.hide_card()
	state = State.IDLE
	_t = 0.0
	_log("offer %d gone" % _ride.get("n", -1))


func _on_card(index: int) -> void:
	if state == State.RESULT and _result_in > 0.0:
		return  # the result card isn't up yet
	match state:
		State.OFFER:
			if index == 0:
				_accept()
			else:
				_withdraw()
		State.RIDE:
			if _asking:
				_answer(index)
		State.RESULT:
			_release()


# --- a ride: making one -----------------------------------------------------------------------

## Ride n: a pickup door lo-hi m by road from lane point (e, s), the passenger (and where they
## really wait), the destination and the quirk (resolved on accepting). Same n, same ride from
## the same lane point.
func _make_ride(n: int, e: int, s: float, from: Vector2, lo: float, hi: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 9973 + 17
	var west := func(a: Dictionary) -> bool: return a["d"] != "praga"
	# Loop MW-3: at dawn, most requests are at an address by a club's door (a `club` passenger).
	var club := ""
	var pick: Dictionary = {}
	var doors: Array = club_doors.call() if club_doors.is_valid() else []
	if not doors.is_empty() and rng.randf() < 0.7:
		var door: Array = doors[rng.randi() % doors.size()]
		var by_door := func(a: Dictionary) -> bool: return a["d"] != "praga" and (a["door"] as Vector2).distance_to(door[1]) < 60.0
		pick = jobs._pick_address(e, s, from, lo, hi, rng, by_door)
		if not pick.is_empty():
			club = str(door[0])
	if pick.is_empty():
		pick = jobs._pick_address(e, s, from, lo, hi, rng, west)
	if pick.is_empty():
		return {}
	var r := {"n": n, "pin_name": String(pick["name"]), "pin": pick["ring"], "away": float(pick["road"])}
	# Where the passenger really is: by the pin, or (half the time) 30-60 m along the street or across it.
	var door: Vector2 = pick["door"]
	var offset := rng.randf() < OFFSET_SHARE
	var off_m := rng.randf_range(OFFSET.x, OFFSET.y)
	var k: Dictionary = {}
	if offset:
		var pe: int = pick["edge"]
		var ps: float = pick["s"]
		var along := off_m * (1.0 if rng.randf() < 0.5 else -1.0)
		var s2 := clampf(ps + along, graph.e_s0[pe] + 2.0, graph.e_s1[pe] - 2.0)
		var c := graph.point_at(pe, s2)
		var side := (door - graph.point_at(pe, ps)).normalized()
		if rng.randf() < 0.4:
			side = -side  # across the street
		k = jobs._kerb(c + side * 6.0, c + side * 12.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		offset = false
		k = jobs._kerb(door, pick["at"], 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return {}
	var spot: Vector2 = k["spot"]
	var kerb: Vector2 = k["centre"] + (k["side"] as Vector2) * 2.0
	r["offset"] = offset
	r["off_m"] = Vector2(pick["ring"].x, pick["ring"].z).distance_to(spot)
	r["spot"] = Vector3(spot.x, map.terrain_height(spot.x, spot.y), spot.y)
	r["spot_yaw"] = atan2((k["side"] as Vector2).x, (k["side"] as Vector2).y)
	r["kerb"] = kerb
	r["board"] = Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y)
	r["heading"] = k["heading"]
	r["p_e"] = k["edge"]
	r["p_s"] = k["s"]
	# Where to: an address, or now and then a named place (the race finishes).
	var named: Array = []
	if rivals != null and rng.randf() < NAMED_SHARE:
		var dist := graph.distances_from(graph.e_b[r["p_e"]])
		for f in rivals.get("_finishes"):
			# Nobody asks to be taken to the far end of a bridge, or to the map's edge (map north:
			# the L-shaped outline's, 40 m in).
			if String(f["name"]).contains("Most") or not map.in_map(graph.node_pos[int(f["node"])], -40.0):
				continue
			var road: float = graph.e_len[r["p_e"]] - float(r["p_s"]) + dist[int(f["node"])]
			if road >= RIDE_MIN and road <= RIDE_MAX:
				named.append([f, road])
	if not named.is_empty():
		var f = named[rng.randi() % named.size()]
		var p: Vector2 = graph.node_pos[int(f[0]["node"])]
		r["dest"] = String(f[0]["name"]).get_slice(" (", 0)
		r["ring"] = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
		r["road"] = f[1]
		r["finish"] = int(f[0]["node"])
	else:
		var not_here := func(a: Dictionary) -> bool: return a["d"] != "praga" and a["name"] != r["pin_name"]
		var to: Dictionary = jobs._pick_address(r["p_e"], r["p_s"], kerb, RIDE_MIN, RIDE_MAX, rng, not_here)
		if to.is_empty() or not to["reached"]:
			return {}
		r["dest"] = String(to["name"])
		r["ring"] = to["ring"]
		r["road"] = float(to["road"])
		r["finish"] = int(to["finish"])
	r["name"] = Jobs.CUSTOMERS[rng.randi() % Jobs.CUSTOMERS.size()]
	var roll := rng.randf()
	var kind := "believer" if roll < BELIEVER_SHARE else ("hurry" if roll < BELIEVER_SHARE + HURRY_SHARE else "normal")
	if kind == "normal" and rng.randf() < TIMBER_SHARE and timber_hour():
		kind = "timber"
	if club != "":
		kind = "club"
	if force_passenger != "":
		kind = force_passenger
	# Pod Gigantami (F, 2026-11-06): now and then the passenger is late for a date there.
	if (kind == "normal" and rng.randf() < DATE_SHARE) or force_passenger == "date":
		var by_date := func(a: Dictionary) -> bool: return (a["door"] as Vector2).distance_to(DATE_DOOR) < 90.0
		var date: Dictionary = jobs._pick_address(r["p_e"], r["p_s"], kerb, RIDE_MIN, 6000.0, rng, by_date)
		if not date.is_empty() and date["reached"]:
			kind = "date"
			r["dest"] = "Pod Gigantami"
			r["ring"] = date["ring"]
			r["road"] = float(date["road"])
			r["finish"] = int(date["finish"])
		elif force_passenger == "date":
			kind = "normal"
	r["type"] = kind
	r["club"] = club
	# Loop MW-4: on a Hyrax Saturday morning the one in a hurry is a late competitor.
	var race: Vector2 = hurry_to.call() if kind == "hurry" and hurry_to.is_valid() else Vector2.INF
	if race != Vector2.INF:
		var by_race := func(a: Dictionary) -> bool: return (a["door"] as Vector2).distance_to(race) < 350.0
		var go: Dictionary = jobs._pick_address(r["p_e"], r["p_s"], kerb, RIDE_MIN, 6000.0, rng, by_race)
		if not go.is_empty():
			r["dest"] = "Hyrax · %s" % go["name"]
			r["ring"] = go["ring"]
			r["road"] = float(go["road"])
			r["finish"] = int(go["finish"])
			r["hyrax"] = true
	r["their"] = snappedf(rng.randf_range(4.2, 5.0), 0.1)
	var quirk := ""
	var pool: Array = QUIRKS + (["rechotka"] if frogs != null and not frogs.shops.is_empty() else [])
	if rng.randf() < QUIRK_SHARE:
		quirk = pool[rng.randi() % pool.size()]
	if force_quirk != "":
		quirk = force_quirk
	r["quirk"] = quirk
	var droll := rng.randf()
	r["detour"] = (frogs != null and not frogs.shops.is_empty() and kind != "club" and droll < DETOUR_SHARE) \
			or force_passenger == "detour"
	if force_passenger == "detour":
		r["type"] = "normal"
	r["shirt"] = Color(SHIRTS[rng.randi() % SHIRTS.size()])
	r["night"] = _night()
	r["rain"] = _rain()
	r["eta"] = Rules.eta_for(r["road"], kind == "hurry" or kind == "date")
	var l: Array = dialogue.line("podwozka_request", kind, true) if kind == "club" or kind == "timber" or kind == "date" else dialogue.line("podwozka_request")
	r["note"] = [l[0], l[1]] if not l.is_empty() else []
	# F (2026-11-07): most passengers are story passengers (taxi_stories.json), in turn; a club
	# night, a date and a late Hyrax competitor keep their own lines.
	r["story"] = {}
	var sroll := rng.randf()
	var can: bool = kind != "club" and kind != "date" and not bool(r.get("hyrax", false))
	if force_story != "none" and not _stories.is_empty() and ((can and sroll < Stories.SHARE) or force_story != ""):
		var seen: Array = wallet.keep.get("podwozka_stories", []) if wallet != null else []
		var skip: Array = []
		# F (2026-11-07): each story goes to its real place (`to`); one whose place doesn't fit
		# this pickup (too near, too far, no door) waits for another ride, and the next one is tried.
		for attempt in 3:
			var st: Dictionary = Stories.pick(_stories, seen + skip, rng, r["night"], force_story)
			if st.is_empty() or skip.has(st["id"]):
				break
			var go := _story_place(r, st, rng, kerb)
			if go.is_empty():
				skip.append(st["id"])
				_log("story %s: its place %s doesn't fit this ride" % [st["id"], st["to"]["name"][1]])
				if force_story != "":
					break
				continue
			r["story"] = st
			r["name"] = String(st["name"])
			r["note"] = ["%s · %s" % [st["who"][0], st["teaser"][0]], "%s · %s" % [st["who"][1], st["teaser"][1]]]
			r["dest"] = String(st["to"]["name"][0])
			r["ring"] = go["ring"]
			r["road"] = float(go["road"])
			r["finish"] = int(go["finish"])
			r["eta"] = Rules.eta_for(r["road"], kind == "hurry")
			break
	return r


## A story's real place: an address door within its `to.r` of `to.at`, 600 m to 6 km by road from
## the pickup ({} when none is).
func _story_place(r: Dictionary, st: Dictionary, rng: RandomNumberGenerator, kerb: Vector2) -> Dictionary:
	var to: Dictionary = st.get("to", {})
	if to.is_empty():
		return {}
	var at := Vector2(float(to["at"][0]), float(to["at"][1]))
	var reach := float(to.get("r", 120.0))
	var near := func(a: Dictionary) -> bool: return (a["door"] as Vector2).distance_to(at) < reach
	var go: Dictionary = jobs._pick_address(r["p_e"], r["p_s"], kerb, RIDE_MIN, 6000.0, rng, near)
	if not go.is_empty() and go["reached"]:
		return go
	# A big site with no address door near (the Palace of Culture, the Central Station, the
	# Castle, the Stadium): the lane point `drop` by it (taxi_stories.json), reached from the
	# junction before it.
	var drop_at: Array = to.get("drop", [])
	if drop_at.size() != 2:
		return {}
	var hit := graph.snap(Vector2(float(drop_at[0]), float(drop_at[1])), 30.0, Vector2.ZERO, true, true, true)
	if hit.is_empty():
		return {}
	var dist := graph.distances_from(graph.e_b[r["p_e"]])
	var road: float = graph.trip(dist, r["p_e"], r["p_s"], hit[0], hit[2])
	if road < RIDE_MIN or road > 6000.0:
		return {}
	var p: Vector2 = graph.point_at(hit[0], hit[2])
	return {"ring": Vector3(p.x, graph.surface(hit[0], p), p.y), "road": road, "finish": graph.e_a[hit[0]]}


# --- pickup ---------------------------------------------------------------------------------

func _accept() -> void:
	_rides += 1
	state = State.PICKUP
	_t = 0.0
	_hold = 0.0
	_said_pickup = false
	hud.hide_card()
	_claim()
	_beacon.recolour(COLOUR)
	_beacon.waving = true
	_beacon.place(_ride["pin"], ARRIVE - 0.5, true, false)
	_rider_mesh.mesh = Props.person(_ride["shirt"], Color("#2d3442"))
	_rider.global_position = _ride["spot"]
	_rider.rotation.y = _ride["spot_yaw"]
	_rider.visible = true
	_ride["pickup_eta"] = Rules.eta_for(maxf(float(_ride["away"]), 60.0))
	# The app's line to the pin, then (once boarded) its route.
	var hit := _car_lane()
	_route = PackedVector2Array()
	if not hit.is_empty():
		var to_node: int = graph.e_b[_ride["p_e"]]
		_path_to(hit[0], hit[2], _ride["p_e"], _ride["p_s"], graph.distances_to(graph.e_a[_ride["p_e"]]), _route)
		_legs = [{"node": to_node, "near": _ride["kerb"]}, {"to": _ride["kerb"]}]
		if _flat(car.global_position, _ride["board"]) < 60.0:
			_legs = [{"to": _ride["kerb"]}]
	else:
		_legs = [{"to": _ride["kerb"]}]
	_route.append(Vector2(_ride["pin"].x, _ride["pin"].z))
	hud.set_minimap_route(_route, COLOUR)
	_leg = 0
	_remove_ghost()
	hud.toast("Kurs przyjęty: %s czeka" % _ride["name"], "Ride accepted: %s is waiting" % _ride["name"])
	_log("accepted ride %d" % _ride["n"])


## Other activities stop offering themselves while a ride runs.
func _claim() -> void:
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()


func _release() -> void:
	state = State.IDLE
	_asking = false
	_t = 0.0
	_beacon.visible = false
	_rider.visible = false
	hud.hide_card()
	hud.hide_status()
	hud.set_minimap_route(PackedVector2Array(), COLOUR)
	missions.paused = false
	missions.close()
	_remove_ghost()
	_ride = {}
	_offer_in = _rng.randf_range(OFFER_GAP.x, OFFER_GAP.y)


func _pickup_tick(dt: float) -> void:
	var p := car.global_position
	var to_rider := _flat(p, _ride["board"])
	var to_pin := _flat(p, _ride["pin"])
	var speed: float = car.vel.length()
	if not _said_pickup and _flat(p, _ride["spot"]) < 80.0:
		_said_pickup = true
		dialogue.say(_rider, _ride["name"], "podwozka_pickup", "offset" if _ride["offset"] else "", 4.0, COLOUR, 6.5,
				_ride["offset"])
	_set_start(to_rider < START_REACH and not flying)
	if to_rider < BOARD and speed < BOARD_SPEED and not flying:
		_hold += dt
		if _hold >= BOARD_HOLD:
			_board()
			return
	else:
		_hold = 0.0
	if _t > Rules.CANCEL_AFTER * float(_ride["pickup_eta"]):
		_cancel(true)
		return
	var hint := ["Jedź do pinezki (turkusowe światło)", "Head for the pin (the teal beacon)"]
	if to_rider < 25.0:
		hint = ["Stań przy pasażerze", "Pull up by the passenger"]
	elif _ride["offset"] and (to_pin < 40.0 or to_rider < 70.0):
		hint = ["Pinezka swoje, pasażer swoje: szukaj „!”", "The pin is here, the passenger isn't: look for the !"]
	hud.show_status("PODWÓZKA · ODBIÓR: %s" % _ride["name"], _clock_text(_t), "%d m" % roundi(_flat(p, target_position())),
			hint[0], _hold / BOARD_HOLD, COLOUR, "", {}, hint[1])


func _board() -> void:
	_set_start(false)
	state = State.RIDE
	_ride["picked_after"] = _t
	_t = 0.0
	_rider.visible = false
	bubbles.hush(_rider)
	_rules.begin(_ride["eta"], start_stars if start_stars > 0.0 else Rules.START)
	_said_quirk = false
	_quirk_done = ""
	_detour_hold = 0.0
	_detour_said = false
	_ride["straight"] = _flat(car.global_position, _ride["ring"])
	_chat_t = _rng.randf_range(8.0, 14.0)
	_beat = 0
	_beat_since = 0.0
	_asking = false
	_ride["answer"] = -1
	var st: Dictionary = _ride.get("story", {})
	if not st.is_empty():
		wallet.keep["podwozka_stories"] = Stories.heard(wallet.keep.get("podwozka_stories", []), String(st["id"]))
		_log("story %s: %s" % [st["id"], st["who"][1]])
	_have_last = false
	_beacon.waving = false
	_beacon.place(_ride["ring"], ARRIVE - 0.5, true, false)
	_plan()
	hud.set_minimap_route(_route, COLOUR)
	var km := roundi(_flat(car.global_position, _ride["ring"]))
	hud.toast("%s wsiada · cel: %s (%d m, strzałka)" % [_ride["name"], _ride["dest"], km],
			"%s gets in · off to %s (%d m, follow the arrow)" % [_ride["name"], _ride["dest"], km])
	_log("pickup: %s got in at %d,%d after %.1f s%s" % [_ride["name"], roundi(car.global_position.x), roundi(car.global_position.z),
			_t_pickup(), (" (the pin was %d m off)" % roundi(_ride["off_m"])) if _ride["offset"] else " (at the pin)"])


func _t_pickup() -> float:
	return float(_ride.get("picked_after", 0.0))


# --- the ride ---------------------------------------------------------------------------------

## The app's route from where the passenger got in: the shortest road, bent by the quirk; and the
## autopilot's legs (the app's route, or with --ignore-app the shortest).
func _plan() -> void:
	var a_e: int = _ride["p_e"]
	var a_s: float = _ride["p_s"]
	var finish: int = _ride["finish"]
	var ring: Vector3 = _ride["ring"]
	var dist_b := graph.distances_to(finish)
	var quirk: String = _ride["quirk"]
	var q := {}
	if quirk == "oldtown":
		_log("quirk oldtown: no Old Town square on this map, a park's paths instead")
		quirk = "zone"
	if quirk == "river" or quirk == "zone":
		var dist_a := graph.distances_from(graph.e_b[a_e])
		q = _river_plan(a_e, a_s, dist_a, dist_b) if quirk == "river" else _zone_plan(a_e, a_s, dist_a, dist_b)
		if q.is_empty() and force_quirk == "":
			quirk = "reroute"
		elif q.is_empty():
			_log("quirk %s: no place for it on this ride" % quirk)
			quirk = ""
	elif quirk == "rechotka":
		q = _rechotka_plan(a_e, a_s, dist_b)
		if q.is_empty():
			quirk = ""
	_ride["quirk"] = quirk
	_ride["q"] = q
	_route = PackedVector2Array()
	var direct := PackedVector2Array()
	_road_path(a_e, a_s, finish, dist_b, direct)
	direct.append(Vector2(ring.x, ring.z))
	_legs = [{"node": finish}, {"to": Vector2(ring.x, ring.z)}]
	if quirk == "river" or quirk == "zone":
		var e1: int = q["e"]
		var s1: float = q["s"]
		_path_to(a_e, a_s, e1, s1, graph.distances_to(graph.e_a[e1]), _route)
		_route.append(q["w"])
		_route.append(q["r2"])
		_road_path(q["e2"], q["s2"], finish, dist_b, _route)
		_route.append(Vector2(ring.x, ring.z))
		if not ignore_app:
			_legs = [{"node": graph.e_b[e1], "near": q["r"]}, {"to": q["w"]}, {"to": q["r2"]}, {"node": finish},
					{"to": Vector2(ring.x, ring.z)}]
			if a_e != e1 or a_s > s1:
				_legs.push_front({"node": graph.e_a[e1]})
		_log("quirk %s: waypoint %d,%d %s, %d m off the road, the app's way %d m longer than the shortest" % [quirk,
				roundi(q["w"].x), roundi(q["w"].y), ("on dry land, the water %.1f m away" % _water_distance(q["w"])) if quirk == "river"
				else "in %s" % q["name"], roundi(q["gap"]), roundi(q["detour"])])
	else:
		_route = direct
		if quirk != "":
			_log("quirk %s planned" % quirk)
	_leg = 0
	_remove_ghost()


func _ride_tick(dt: float) -> void:
	var p := car.global_position
	var ring: Vector3 = _ride["ring"]
	var d := _flat(p, ring)
	var speed: float = car.vel.length()
	if _rules.tick(dt):
		_star_note(-Rules.LATE_STEP, "late %d s" % roundi(_rules.clock - _rules.eta), ["spóźnienie", "late"])
	if d < ARRIVE and speed < ARRIVE_SPEED and not flying:
		_arrive()
		return
	if _rules.overdue():
		_cancel(true)
		return
	_quirk_tick(p)
	_detour_tick(p, speed, dt)
	if not (_ride.get("story", {}) as Dictionary).is_empty():
		_story_tick(dt, d)
		if _asking:
			return  # the question card stands where the status panel was
	_chat_t -= dt
	if (_ride.get("story", {}) as Dictionary).is_empty() and _chat_t <= 0.0 and not bubbles.is_talking(car):
		_chat_t = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
		var kind: String = _ride["type"]
		if _rng.randf() < 0.5:
			dialogue.say(car, _ride["name"], "podwozka_passenger", kind, 4.5, COLOUR, 2.4, kind != "normal")
		else:
			dialogue.say(car, _ride["name"], "passenger", "", 4.5, COLOUR, 2.4)
	var hint := ["Jedź do turkusowego światła", "Head for the teal beacon"]
	if flying:
		hint = ["Wyląduj i weź auto: pasażer jedzie autem", "Land and take the car: the passenger rides in the car"]
	elif d < ARRIVE:
		hint = ["Stań pod drzwiami", "Stop at the door"]
	elif d < 40.0:
		hint = ["Stań w kręgu", "Pull up inside the ring"]
	elif _ride["quirk"] != "" and _quirk_done == "":
		hint = ["Cel to turkusowe światło. Kropki to pomysł aplikacji.", "The goal is the teal beacon. The dots are the app's idea."]
	hud.show_status("PODWÓZKA → %s" % _ride["dest"], Rules.stars_text(_rules.stars()), "%d m" % roundi(d),
			hint[0], _rules.clock / _rules.eta, COLOUR, "", {}, hint[1])


## Nawigacja speaks 200 m before the quirk; the waypoint driven (a believer's +½), or ignored (a
## believer grumbles); the recalculation comes 40 % of the way in.
func _quirk_tick(p: Vector3) -> void:
	var quirk: String = _ride["quirk"]
	if quirk == "" or _quirk_done == "reached" or _quirk_done == "reroute":
		return
	var q: Dictionary = _ride["q"]
	var ring := Vector2(_ride["ring"].x, _ride["ring"].z)
	var to_door := Vector2(p.x - ring.x, p.z - ring.y).length()
	if quirk == "reroute":
		if _rules.clock > 0.4 * _rules.eta or to_door < 0.6 * float(_ride["straight"]):
			_reroute()
		return
	var w: Vector2 = q["w"]
	var dw := Vector2(p.x - w.x, p.z - w.y).length()
	if not _said_quirk and dw < SAY_AT:
		_said_quirk = true
		dialogue.say(_gps_anchor, "Nawigacja", "podwozka_gps", quirk, 4.5, COLOUR, 0.0, true)
		_log("quirk %s: Nawigacja speaks %d m before it" % [quirk, roundi(dw)])
	if quirk == "rechotka":
		if dw < REACH:
			_quirk_done = "reached"
		return
	if dw < REACH:
		_quirk_done = "reached"
		_log("quirk %s reached at %.1f s, %.1f m from the waypoint (%s passenger)" % [quirk, _rules.clock, dw, _ride["type"]])
		if _ride["type"] == "believer" and _rules.follow():
			_star_note(Rules.BONUS, "followed the app", ["za aplikacją", "followed the app"])
			dialogue.say(car, _ride["name"], "podwozka_passenger", "followed", 3.5, COLOUR, 2.4, true)
	elif _quirk_done == "" and (_said_quirk or _rules.clock > 20.0) and dw > 2.0 * REACH \
			and to_door < PASSED * w.distance_to(ring):
		# Past it: the car is well nearer the door than the waypoint is (it can still go back).
		_quirk_done = "ignored"
		_log("quirk %s ignored at %.1f s (%s passenger)" % [quirk, _rules.clock, _ride["type"]])
		if _ride["type"] == "believer":
			dialogue.say(car, _ride["name"], "podwozka_passenger", "believer", 4.0, COLOUR, 2.4, true)


## Loop MW-2: a `detour` passenger asks for a Frogs 8 s in; stopped by any Frogs door (storefronts.gd's
## shop_near, STAMP_REACH) under DETOUR_SPEED for DETOUR_HOLD s: +½ once (ride_rules.gd detour).
func _detour_tick(p: Vector3, speed: float, dt: float) -> void:
	if not bool(_ride.get("detour", false)) or frogs == null or _rules.detoured:
		return
	if not _detour_said and _rules.clock > 8.0 and not bubbles.is_talking(car):
		_detour_said = true
		dialogue.say(car, _ride["name"], "podwozka_passenger", "detour", 4.5, COLOUR, 2.4, true)
		_log("detour: %s asks for a Frogs" % _ride["name"])
	if not _detour_said or speed >= DETOUR_SPEED or flying:
		_detour_hold = 0.0
		return
	if frogs.shop_near(Vector2(p.x, p.z), frogs.STAMP_REACH) < 0:
		_detour_hold = 0.0
		return
	_detour_hold += dt
	if _detour_hold >= DETOUR_HOLD and _rules.detour():
		_star_note(Rules.BONUS, "a Frogs stop", ["postój przy Frogsie", "a Frogs stop"])


## The app recalculates once: a new line that first turns back to the junction behind the car.
func _reroute() -> void:
	_quirk_done = "reroute"
	var hit := _car_lane()
	dialogue.say(_gps_anchor, "Nawigacja", "podwozka_gps", "reroute", 4.5, COLOUR, 0.0, true)
	if hit.is_empty():
		return
	var e: int = hit[0]
	var back: int = graph.e_a[e]
	var finish: int = _ride["finish"]
	var ring: Vector3 = _ride["ring"]
	var route := PackedVector2Array()
	_road_path(e, hit[2], back, graph.distances_to(back), route)
	var n := back
	var dist_b := graph.distances_to(finish)
	var first := -1
	for f in graph.node_out[n]:
		if first < 0 or graph.e_len[f] + dist_b[graph.e_b[f]] < graph.e_len[first] + dist_b[graph.e_b[first]]:
			first = f
	if first >= 0:
		_road_path(first, 0.0, finish, dist_b, route)
	route.append(Vector2(ring.x, ring.z))
	_route = route
	hud.set_minimap_route(_route, COLOUR)
	if autopilot and not ignore_app:
		_legs.insert(_leg, {"node": back})
		_remove_ghost()
	_log("quirk reroute: recalculated at %.1f s, the new line turns back to the junction at %d,%d" % [_rules.clock,
			roundi(graph.node_pos[back].x), roundi(graph.node_pos[back].y)])


## A believer's or the game's star change: logged, a short toast.
func _star_note(delta: float, why: String, words: Array) -> void:
	var sign_pl := "+" if delta > 0.0 else "−"
	var amount := _halves(absf(delta))
	hud.toast("%s%s ★ · %s" % [sign_pl, amount, words[0]], "%s%s star · %s" % [sign_pl, amount, words[1]])
	_log("stars %.1f (%s %s%.1f)" % [_rules.stars(), why, "+" if delta > 0.0 else "−", absf(delta)])


## Phase 0.2 (the chatter budget): the passenger's drive penalties (a bump, harsh braking, a fast
## corner) are logged at once but toast together, one "−1 ★ · stłuczki" once they have stopped for
## DRIVE_MERGE s (one toast per bump while stuck against a wall was most of the spam). `words` is
## [Polish one, Polish many, English one, English many].
func _drive_note(why: String, words: Array) -> void:
	_drive_sum += Rules.DRIVE_STEP
	_drive_quiet = 0.0
	var k := _drive_words.find(words)
	if k < 0:
		_drive_words.append(words)
		_drive_counts.append(1)
	else:
		_drive_counts[k] += 1
	_log("stars %.1f (%s −%.1f)" % [_rules.stars(), why, Rules.DRIVE_STEP])


## The merged drive toast, DRIVE_MERGE s after the last penalty; dropped when the ride ends first
## (the result card says the stars).
func _drive_tick(dt: float) -> void:
	if _drive_sum <= 0.0:
		return
	if state != State.RIDE:
		_drive_reset()
		return
	_drive_quiet += dt
	if _drive_quiet < DRIVE_MERGE:
		return
	var pl: PackedStringArray = []
	var en: PackedStringArray = []
	for i in _drive_words.size():
		var many := int(_drive_counts[i]) > 1
		pl.append(_drive_words[i][1 if many else 0])
		en.append(_drive_words[i][3 if many else 2])
	var amount := _halves(_drive_sum)
	hud.toast("−%s ★ · %s" % [amount, ", ".join(pl)], "−%s star · %s" % [amount, ", ".join(en)])
	drive_toasts += 1
	_drive_reset()


func _drive_reset() -> void:
	_drive_sum = 0.0
	_drive_quiet = 0.0
	_drive_words.clear()
	_drive_counts.clear()


# --- story rides (taxi_stories.gd) ------------------------------------------------------------

## The story passenger's beats: three lines along the way, then the question card; while it is up,
## its clock (no answer in ASK_LIFE s: the passenger lets it go; the autopilot answers after AUTO s).
func _story_tick(dt: float, d: float) -> void:
	var st: Dictionary = _ride["story"]
	_beat_since += dt
	if _asking:
		_ask_t += dt
		if autopilot and _ask_t >= Stories.AUTO:
			_answer(maxi(force_answer, 0))
		elif _ask_t >= Stories.ASK_LIFE:
			_answer(-1)
		return
	if _beat > 3:
		return
	var done := clampf(1.0 - d / maxf(float(_ride["straight"]), 1.0), 0.0, 1.0)
	if not Stories.due(_beat, done, _t, _beat_since) or bubbles.is_talking(car):
		return
	if _beat < 3:
		var l: Array = st["lines"][_beat]
		if bubbles.say(car, _ride["name"], l[0], l[1], 4.5, COLOUR, 2.4):
			_beat += 1
			_beat_since = 0.0
			story_lines += 1
			_log("story %s line %d at %d%% of the way, %.0f s in" % [st["id"], _beat, roundi(done * 100.0), _t])
	elif not flying and not hud.cards_up():
		_ask(done)


func _ask(done: float) -> void:
	var st: Dictionary = _ride["story"]
	var a: Array = st["answers"]
	_asking = true
	_ask_t = 0.0
	_beat = 4
	_beat_since = 0.0
	hud.hide_status()
	var name_pl := String(_ride["name"])
	hud.show_side_card("%s PYTA" % name_pl.to_upper(), String(st["ask"][0]),
			PackedStringArray(["%s|%s" % [a[0]["say"][0], a[0]["say"][1]], "%s|%s" % [a[1]["say"][0], a[1]["say"][1]]]),
			COLOUR, "%s asks" % name_pl, String(st["ask"][1]), true)
	Access.buzz(40, 0.4)
	_log("story %s asks at %d%% of the way, %.0f s in" % [st["id"], roundi(done * 100.0), _t])


## The answer `i` (0 or 1; -1: none in time): the passenger's reply, and a good talk's half star.
func _answer(i: int) -> void:
	var st: Dictionary = _ride["story"]
	_asking = false
	hud.hide_card()
	_ride["answer"] = i
	var l: Array = st.get("silent", Stories.SILENT)
	if i >= 0:
		var a: Dictionary = st["answers"][i]
		l = a["reply"]
		story_answers += 1
		if bool(a.get("star", false)) and _rules.chat():
			_star_note(Rules.BONUS, "good talk", ["rozmowa", "good talk"])
	bubbles.hush(car)
	bubbles.say(car, _ride["name"], l[0], l[1], 5.0, COLOUR, 2.4)
	_log("story %s: answer %d (%s)" % [st["id"], i, "none in time" if i < 0 else String(st["answers"][i]["say"][1])])


## The chosen answer of this ride's story ({} for no story or no answer).
func _story_answer() -> Dictionary:
	var st: Dictionary = _ride.get("story", {})
	var i := int(_ride.get("answer", -1))
	if st.is_empty() or i < 0:
		return {}
	return st["answers"][i]


# --- the end of a ride ------------------------------------------------------------------------

func _arrive() -> void:
	state = State.RESULT
	if _asking:
		_asking = false
		hud.hide_card()
		_log("story: arrived before an answer")
	hud.hide_status()
	_remove_ghost()
	bubbles.hush(car)
	var early := _rules.arrive()
	if early:
		_log("stars %.1f (early: %.0f s of an ETA of %.0f s +0.5)" % [_rules.stars(), _rules.clock, _rules.eta])
	var final := _rules.final()
	_log("arrived at %s in %.1f s (ETA %.0f s): stars %.1f" % [_ride["dest"], _rules.clock, _rules.eta, final])
	var streak := int(wallet.keep.get("podwozka_streak", 0))
	var answer: Dictionary = _story_answer()
	var pay := Rules.pay(_ride["road"], final, _ride["night"], _ride["rain"], _ride["type"] == "hurry", streak,
			int(answer.get("tip", 0)))
	var before := _rating()
	var history: Array = wallet.keep.get("podwozka_ratings", [])
	wallet.keep["podwozka_ratings"] = Rules.pushed(history, final)
	wallet.keep["podwozka_streak"] = int(pay["streak_after"])
	var zl_before: int = wallet.zl
	wallet.pay(int(pay["total"]), int(pay["respect"]), "podwozka")
	var tag := "police" if _rules.pulled_over else ("5" if final >= 5.0 else ("4" if final >= 4.0 else "low"))
	_beacon.place(_ride["ring"], ARRIVE - 0.5, false, true)
	hud.set_minimap_route(PackedVector2Array(), COLOUR)
	hud.ticker_out()
	# Nawigacja's "you have arrived" first; the result card when it has been said (one at a time).
	dialogue.say(_gps_anchor, "Nawigacja", "podwozka_gps", "arrive", 2.0, COLOUR, 0.0, true)
	# The passenger's comment is on the card (a bubble too would say it twice).
	var comment: Array = dialogue.line("podwozka_rating", tag, true)
	# A story passenger's last word (the answer's outro), unless the ride went badly.
	if answer.has("outro") and (tag == "5" or tag == "4"):
		comment = answer["outro"]
	var text := Rules.result_text({"stars": final, "name": _ride["name"], "place": _ride["dest"], "time": _clock_text(_rules.clock),
			"comment": comment, "pay": pay, "rating": _rating(), "why": _why()})
	_result_card = [text, COLOUR if final >= 4.0 else FAIL_COLOUR]
	_result_in = RESULT_AFTER
	Access.buzz(120, 0.8)
	print("podwózka done: %s to %s in %.1f s, %.1f stars, paid %d zł (wallet %d zł)" % [_ride["name"], _ride["dest"],
			_rules.clock, final, pay["total"], wallet.zl])
	if int(pay["story"]) != 0:
		_log("story %s: answer %d, tip %+d zł" % [_ride["story"]["id"], int(_ride["answer"]), int(pay["story"])])
	_log("pay %d zł (fare %d, tip %d, streak %d) · MNOŻNIK ×%.1f · respect +%d · wallet %d -> %d zł · rating %.2f -> %.2f · streak %d -> %d" % [
			pay["total"], pay["fare"], pay["tip"], pay["streak"], pay["mult"], pay["respect"], zl_before, wallet.zl, before,
			_rating(), streak, pay["streak_after"]])


## What moved the stars, for the result card: [Polish, English].
func _why() -> Array:
	var pl := PackedStringArray()
	var en := PackedStringArray()
	if _rules.drive > 0.0:
		pl.append("jazda −" + _halves(_rules.drive))
		en.append("driving −" + _halves(_rules.drive))
	if _rules.late > 0.0:
		pl.append("spóźnienie −" + _halves(_rules.late))
		en.append("late −" + _halves(_rules.late))
	if _rules.police > 0.0:
		pl.append("policja −" + _halves(_rules.police))
		en.append("police −" + _halves(_rules.police))
	if _rules.early:
		pl.append("przed czasem +½")
		en.append("early +½")
	if _rules.followed:
		pl.append("za aplikacją +½")
		en.append("followed the app +½")
	if _rules.chatted:
		pl.append("rozmowa +½")
		en.append("good talk +½")
	return [", ".join(pl), ", ".join(en)]


## The ✕ (by_passenger false) or the passenger giving up after 3 × the ETA: no pay, no stars
## lost, the 5-star streak ends.
func _cancel(by_passenger: bool) -> void:
	var riding := state == State.RIDE
	_asking = false
	state = State.RESULT
	_set_start(false)
	_result_in = 0.0
	_result_at = car.global_position
	_t = 0.0
	hud.hide_status()
	_remove_ghost()
	bubbles.hush(car)
	_beacon.visible = false
	_rider.visible = false
	hud.set_minimap_route(PackedVector2Array(), COLOUR)
	hud.ticker_out()
	var streak := int(wallet.keep.get("podwozka_streak", 0))
	wallet.keep["podwozka_streak"] = 0
	wallet.save()
	var who: String = _ride["name"]
	if by_passenger and riding:
		var l: Array = dialogue.say(car, who, "podwozka_rating", "cancel", 4.5, FAIL_COLOUR, 2.4, true)
		var quote := "„%s”\n" % l[0] if not l.is_empty() else ""
		hud.show_side_card("PASAŻER ANULOWAŁ", quote + "%s wysiada. Bez opłat; seria pięciu gwiazdek przepadła." % who,
				PackedStringArray(), FAIL_COLOUR, "The passenger cancelled",
				("%s\n" % l[1] if not l.is_empty() else "") + "%s gets out. No charge; the 5-star streak is gone." % who)
	elif by_passenger:
		hud.show_side_card("PASAŻER ANULOWAŁ", "%s wybiera inną Podwózkę. Bez opłat; seria przepadła." % who,
				PackedStringArray(), FAIL_COLOUR, "The passenger cancelled",
				"%s picked another Podwózka. No charge; the streak is gone." % who)
	else:
		hud.show_side_card("KURS ANULOWANY", ("%s wysiada tutaj." if riding else "%s zostaje na chodniku.") % who
				+ " Bez opłat; seria przepadła.", PackedStringArray(), FAIL_COLOUR, "Ride cancelled",
				("%s gets out here." if riding else "%s stays on the pavement.") % who + " No charge; the streak is gone.")
	_log("cancelled by the %s %s after %.1f s: no pay, no stars lost, streak %d -> 0" % ["passenger" if by_passenger else "player",
			"during the ride" if riding else "before the pickup", _rules.clock if riding else _t, streak])
	print("podwózka cancelled: %s, by the %s" % [who, "passenger" if by_passenger else "player"])


# --- quirks: where they go ---------------------------------------------------------------------

## The river spot whose leg (road to it, out to the water's edge and back) adds least to the
## shortest road A -> B: {e, s, r, w, r2, e2, s2, gap, detour}; {} if none is within DETOUR_MAX
## (a forced quirk takes the least anyway).
func _river_plan(a_e: int, a_s: float, dist_a: PackedFloat32Array, dist_b: PackedFloat32Array) -> Dictionary:
	_finish_river_spots()
	var best := {}
	var direct: float = _ride["road"]
	for sp in river_spots:
		var e: int = sp["e"]
		var s: float = sp["s"]
		var da := graph.trip(dist_a, a_e, a_s, e, s)
		var db: float = graph.e_len[e] - s + dist_b[graph.e_b[e]]
		var detour: float = da + 2.0 * float(sp["gap"]) + db - direct
		if detour >= INF or (force_quirk == "" and detour > DETOUR_MAX):
			continue
		if best.is_empty() or detour < float(best["detour"]):
			best = {"e": e, "s": s, "r": sp["road"], "w": sp["w"], "r2": sp["road"], "e2": e, "s2": s, "gap": sp["gap"],
					"detour": detour}
	return best


## A park roughly between A and B: in from the road on A's side, through the middle, out on B's.
func _zone_plan(a_e: int, a_s: float, dist_a: PackedFloat32Array, dist_b: PackedFloat32Array) -> Dictionary:
	var best := {}
	var direct: float = _ride["road"]
	var a := graph.point_at(a_e, a_s)
	var b := Vector2(_ride["ring"].x, _ride["ring"].z)
	for park in _parks:
		var w: Vector2 = park["w"]
		var to_a := (a - w).normalized()
		var to_b := (b - w).normalized()
		if to_a.dot(to_b) > 0.2:
			continue
		var h1 := graph.snap(w + to_a * 35.0, 60.0, Vector2.ZERO, true, true)
		var h2 := graph.snap(w + to_b * 35.0, 60.0, Vector2.ZERO, true, true)
		if h1.is_empty() or h2.is_empty():
			continue
		var r1 := graph.point_at(h1[0], h1[2])
		var r2 := graph.point_at(h2[0], h2[2])
		if r1.distance_to(w) < 20.0 or r2.distance_to(w) < 20.0 or not _clear(r1, w) or not _clear(w, r2):
			continue
		var da := graph.trip(dist_a, a_e, a_s, h1[0], h1[2])
		var db: float = graph.e_len[h2[0]] - float(h2[2]) + dist_b[graph.e_b[h2[0]]]
		var detour: float = da + r1.distance_to(w) + w.distance_to(r2) + db - direct
		if detour >= INF or (force_quirk == "" and detour > DETOUR_MAX):
			continue
		if best.is_empty() or detour < float(best["detour"]):
			best = {"e": h1[0], "s": h1[2], "r": r1, "w": w, "r2": r2, "e2": h2[0], "s2": h2[2],
					"gap": r1.distance_to(w), "detour": detour, "name": park["name"]}
	return best


## The Frogs turn (quirk id `rechotka`: the shop was Rechotka 24 until 2026-10-30; flag only
## until the shops are placed, loop 2d-2): the first junction on the shortest road, 250 m or
## more in, where the way turns; Nawigacja names the shop there.
## Loop MW-2: with the Frogs placed, the turn must have a Frogs on its junction (a triple corner
## first); without them (or forced with none on the way) the first turn, as before.
func _rechotka_plan(a_e: int, a_s: float, dist_b: PackedFloat32Array) -> Dictionary:
	var path := PackedVector2Array()
	_road_path(a_e, a_s, _ride["finish"], dist_b, path)
	var run := 0.0
	var first := {}
	var best := {}
	for i in range(1, path.size() - 1):
		run += path[i].distance_to(path[i - 1])
		var turn := absf((path[i] - path[i - 1]).angle_to(path[i + 1] - path[i]))
		if run > 250.0 and turn > 0.8:
			if first.is_empty():
				first = {"w": path[i]}
			if frogs == null:
				break
			var k: int = frogs.frogs_at_junction(path[i], FROGS_TURN)
			if k >= 0:
				var triple: bool = frogs.shops[k]["triple"] != ""
				if best.is_empty() or (triple and not bool(best["triple"])):
					best = {"w": path[i], "triple": triple, "shop": k}
				if triple:
					break
	if not best.is_empty():
		_log("quirk rechotka: the turn at the Frogs at %d,%d%s" % [roundi(best["w"].x), roundi(best["w"].y),
				" (a triple corner)" if best["triple"] else ""])
		return best
	if frogs != null and not frogs.shops.is_empty() and force_quirk == "":
		return {}
	return first


# --- roads on the lane graph -------------------------------------------------------------------

## The shortest road from lane point (e, s) to graph node `to` (given distances_to(to)) as a
## polyline of the edges' own points, appended to `out`; it stops where the way leaves the map.
func _road_path(e: int, s: float, to: int, dist: PackedFloat32Array, out: PackedVector2Array) -> void:
	out.append(graph.point_at(e, s))
	_edge_points(e, s, graph.e_len[e], out)
	var n: int = graph.e_b[e]
	var guard := 0
	while n != to and guard < 600:
		guard += 1
		var best := -1
		var best_d := INF
		for f in graph.node_out[n]:
			var c: float = graph.e_len[f] + dist[graph.e_b[f]]
			if c < best_d:
				best_d = c
				best = f
		if best < 0 or best_d >= INF or best_d > dist[n] + 1.0:
			break
		_edge_points(best, 0.0, graph.e_len[best], out)
		n = graph.e_b[best]


## From lane point (e, s) to lane point (e2, s2): along e if s2 is ahead on it, else the road to
## e2's start (`dist`: distances_to(e_a[e2])) and along e2.
func _path_to(e: int, s: float, e2: int, s2: float, dist: PackedFloat32Array, out: PackedVector2Array) -> void:
	if e == e2 and s2 >= s:
		out.append(graph.point_at(e, s))
		_edge_points(e, s, s2, out)
		return
	_road_path(e, s, graph.e_a[e2], dist, out)
	_edge_points(e2, 0.0, s2, out)


func _edge_points(e: int, a: float, b: float, out: PackedVector2Array) -> void:
	var i0: int = graph.e_first[e]
	for k in graph.e_count[e]:
		var c: float = graph.cum[i0 + k]
		if c > a and c < b:
			out.append(graph.pts[i0 + k])
	out.append(graph.point_at(e, b))


func _car_lane() -> Array:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		hit = graph.snap(p, 60.0, Vector2.ZERO, true)
	return hit


# --- the river spots ----------------------------------------------------------------------------

## The water test on a SCAN m grid over the map, row by row: each dry-to-wet step between two
## neighbouring samples is a point on the water's edge, with the way into the water.
# --- Map round 2b (2026-10-29): the river spots from the bake --------------------------------
# The scan below found a dry waypoint 5 m in from the water and a straight line to a lane over
# dry ground with no building, but never asked whether a car can drive it: on today's map every
# one of its lines crossed a guard rail, a retaining wall, steps or a boulevard's drop (the car
# only got there because the autopilot ghosts). tools/bake_structures.py `place_bank` walks each
# candidate's line against those and writes the drivable ones to the index as `drivable_bank`
# ([wx, wz, rx, rz]: the waypoint and the lane point it was checked from). Here they become the
# spots (snapped to the lane graph at their lane point); a map without the list keeps the scan.

## The lane point of a baked spot is this close to the lane graph's.
const BANK_SNAP := 2.5


## River spots from the index's `drivable_bank`; false when the map has none (an older bake).
func _bank_spots(data: Dictionary) -> bool:
	var bank: Array = data.get("drivable_bank", [])
	if bank.is_empty():
		return false
	var t0 := Time.get_ticks_usec()
	for b: Array in bank:
		var w := Vector2(float(b[0]), float(b[1]))
		if not map.in_map(w, -SCAN):
			continue  # map north: never in the corner left outside
		var hit := graph.snap(Vector2(float(b[2]), float(b[3])), BANK_SNAP, Vector2.ZERO, true, true)
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var s: float = hit[2]
		if graph.tunnel_depth(e, s) > 0.5:
			continue
		var r := graph.point_at(e, s)
		_river_raw.append({"e": e, "s": s, "road": r, "w": w, "gap": r.distance_to(w)})
	_scan_usec = Time.get_ticks_usec() - t0
	_river_ready = true
	_keep_river_spots()
	return true
# --- end of map round 2b ---------------------------------------------------------------------


func _queue_river() -> void:
	var b: Rect2 = map.bounds.grow(-SCAN)
	_scan_origin = b.position
	_scan_cols = int(b.size.x / SCAN) + 1
	_scan_rows = int(b.size.y / SCAN) + 1
	_scan_row = 0


func _scan_line(row: int) -> void:
	var wet := PackedByteArray()
	wet.resize(_scan_cols)
	var z := _scan_origin.y + row * SCAN
	for c in _scan_cols:
		var x := _scan_origin.x + c * SCAN
		var w := 1 if float(map.shore_distance(x, z)) > 0.0 else 0
		wet[c] = w
		if c > 0 and w != wet[c - 1]:
			_river_todo.append([Vector2(x if w == 1 else x - SCAN, z), Vector2(1.0 if w == 1 else -1.0, 0.0)])
		if row > 0 and w != _scan_prev[c]:
			_river_todo.append([Vector2(x, z if w == 1 else z - SCAN), Vector2(0.0, 1.0 if w == 1 else -1.0)])
	_scan_prev = wet


func _river_step(budget: int) -> void:
	var t0 := Time.get_ticks_usec()
	var rows := SCAN_ROWS if budget < (1 << 30) else (1 << 30)
	while rows > 0 and _scan_row < _scan_rows:
		_scan_line(_scan_row)
		_scan_row += 1
		rows -= 1
	if _scan_row >= _scan_rows:
		while budget > 0 and not _river_todo.is_empty():
			budget -= 1
			var item: Array = _river_todo.pop_back()
			_try_spot(item[0], item[1])
		if _river_todo.is_empty():
			_river_ready = true
	_scan_usec += Time.get_ticks_usec() - t0
	if _river_ready:
		_keep_river_spots()


func _finish_river_spots() -> void:
	if not _river_ready:
		_river_step(1 << 30)


## A spot by the river at a water's-edge sample (`into`: the way into the water): the water past
## it wide; a dry waypoint RIVER_INLAND m in from it; a road within RIVER_ROAD m, the line to it
## over dry, open ground.
func _try_spot(edge: Vector2, into: Vector2) -> void:
	var t := Vector2(-into.y, into.x)
	# Map north: the scan runs over the bounding box; a spot keeps to the map's outline.
	if not map.in_map(edge, -SCAN):
		return
	# The river, not a pond or a fountain: still deep water 60 m out.
	var deep := edge + into * 60.0
	if map.shore_distance(deep.x, deep.y) < 40.0:
		return
	var w := edge - into * RIVER_INLAND
	if _wet(w, RIVER_DRY) or _roofed(w):
		return
	# Both ways along the bank (a dual carriageway's far side is a long way round).
	for way: Vector2 in [t, -t]:
		var hit := graph.snap(w, RIVER_ROAD, way, true, true)
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var s: float = hit[2]
		if graph.tunnel_depth(e, s) > 0.5:
			continue
		var r := graph.point_at(e, s)
		if _clear(r, w):
			_river_raw.append({"e": e, "s": s, "road": r, "w": w, "gap": r.distance_to(w)})


## One spot per road edge (the nearest the water); gps_moments.gd gets the edges and their way back.
func _keep_river_spots() -> void:
	var by_edge := {}
	for sp in _river_raw:
		var e: int = sp["e"]
		if not by_edge.has(e) or float(sp["gap"]) < float(by_edge[e]["gap"]):
			by_edge[e] = sp
	river_spots.clear()
	for e in by_edge:
		river_spots.append(by_edge[e])
	_river_raw.clear()
	if moments != null:
		for sp in river_spots:
			var e: int = sp["e"]
			moments.river_edges[e] = [sp["s"], float(sp["gap"]) + RIVER_INLAND]
			var rev: int = graph.e_reverse[e]
			if rev >= 0 and not moments.river_edges.has(rev):
				moments.river_edges[rev] = [graph.project(rev, sp["road"]), float(sp["gap"]) + RIVER_INLAND]
	print("rides: %d river spots (road within %d m of a dry waypoint %d m in from the edge), found in %.1f ms over the frames" % [
			river_spots.size(), roundi(RIVER_ROAD), roundi(RIVER_INLAND), _scan_usec / 1000.0])


## Water within r m of p (or at it).
func _wet(p: Vector2, r: float) -> bool:
	if map.shore_distance(p.x, p.y) > 0.0:
		return true
	for k in 12:
		for f: float in [0.5, 1.0]:
			var q := p + Vector2.from_angle(TAU * k / 12.0) * r * f
			if map.shore_distance(q.x, q.y) > 0.0:
				return true
	return false


func _roofed(p: Vector2) -> bool:
	return map.top_height(p.x, p.y, 1.0) > map.terrain_height(p.x, p.y) + 0.5


## The straight line a -> b over dry ground with no building on it.
func _clear(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 3.0))
	for i in range(1, steps):
		var q := a.lerp(b, float(i) / steps)
		if map.shore_distance(q.x, q.y) > 0.0 or _roofed(q):
			return false
	return true


## How far the nearest water is from p (m, to 0.5 m; INF past 20 m): the log's dry-land proof.
func _water_distance(p: Vector2) -> float:
	var r := 0.0
	while r <= 20.0:
		for k in 24:
			var q := p + Vector2.from_angle(TAU * k / 24.0) * r
			if map.shore_distance(q.x, q.y) > 0.0:
				return r
		r += 0.5
	return INF


# --- the autopilot ---------------------------------------------------------------------------

## --autopilot: drives the legs (the road on a ghost driver, the off-road bits straight).
func drive_player() -> bool:
	if not autopilot or (state != State.PICKUP and state != State.RIDE) or _leg >= _legs.size():
		return false
	var leg: Dictionary = _legs[_leg]
	var dt := get_process_delta_time()
	if leg.has("node"):
		var target: Vector2 = graph.node_pos[int(leg["node"])]
		if _ghost == null:
			_start_ghost(int(leg["node"]))
			if _ghost == null:
				_legs[_leg] = {"to": target}
				return true
		var at := Vector2(_ghost.pos.x, _ghost.pos.z)
		if _ghost.arrived or at.distance_to(target) < 12.0 or (leg.has("near") and at.distance_to(leg["near"]) < 10.0):
			_remove_ghost()
			_leg += 1
			_log("autopilot: leg %d of %d done at %d,%d" % [_leg, _legs.size(), roundi(at.x), roundi(at.y)])
			return true
		_stall = _stall + dt if _ghost.v < 0.5 else 0.0
		if _stall > 4.0:
			_stall = 0.0
			_ghost.squeeze = 3.0
		car.collision_mask = 0
		car.global_position = _ghost.pos
		car.rotation.y = _ghost.yaw
		car.vel = Vector3(-sin(_ghost.yaw), 0.0, -cos(_ghost.yaw)) * _ghost.v
		car.throttle = 0.0
		car.braking = false
		car.target_dir = Vector3.ZERO
		car.reset_physics_interpolation()
		return true
	var to2: Vector2 = leg["to"]
	var to := Vector3(to2.x - car.global_position.x, 0.0, to2.y - car.global_position.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	if d > 0.6:
		car.global_position += to / d * minf(d, 12.0 * dt)
		car.rotation.y = atan2(-to.x, -to.z)
	elif _leg < _legs.size() - 1:
		_leg += 1
		_log("autopilot: leg %d of %d done at %d,%d" % [_leg, _legs.size(), roundi(to2.x), roundi(to2.y)])
	return true


func _start_ghost(node: int) -> void:
	var hit := _car_lane()
	if hit.is_empty() or traffic == null:
		return
	_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	# The test drive goes briskly, as the kebab one does: it should arrive inside the ETA.
	_ghost.speed_factor = 1.3
	_ghost.accel_factor = 1.5
	var dist := graph.distances_to(node)
	traffic.race_to(_ghost, node, dist)
	_log("autopilot: on the road at %d,%d to the junction at %d,%d, %d m" % [roundi(car.global_position.x),
			roundi(car.global_position.z), roundi(graph.node_pos[node].x), roundi(graph.node_pos[node].y),
			roundi(graph.remaining(dist, hit[0], hit[2]))])


func _remove_ghost() -> void:
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null


# --- helpers ------------------------------------------------------------------------------------

## The player's rating: the last 20 rides (a new save counts as 4,87).
func _rating() -> float:
	return Rules.rating(wallet.keep.get("podwozka_ratings", []))


## Is it the TIMBER evening, 18:00-01:00 (the dates)? Without a clock, never.
func timber_hour() -> bool:
	if tod == null:
		return false
	var h := float(tod.local_clock()["hour"])
	return h >= float(TIMBER_HOURS[0]) or h < float(TIMBER_HOURS[1]) - 24.0


## Night or Live after dusk: the MNOŻNIK's ×1.5.
func _night() -> bool:
	return tod != null and (tod.mode == 2 or (tod.mode == 3 and tod.lights_on > 0.5))


func _rain() -> bool:
	return weather != null and weather.state == 1


func _log(what: String) -> void:
	if log_on:
		print("ride: " + what)


static func _halves(x: float) -> String:
	var n := roundi(x * 2.0)
	var whole := n / 2
	if n % 2 == 0:
		return str(whole)
	return ("%d½" % whole) if whole > 0 else "½"


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _clock_text(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]
