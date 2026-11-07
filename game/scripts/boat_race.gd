extends Node3D
## "Wiślana Szprotka": the boat race down the Vistula (docs/design/boat-race.md; F's ask 2026-11-06:
## a friend phones and asks for a boat race through rings; miss three and you lose, then go again
## or quit; fun rivals and physics).
##
## Szymek phones (daytime, once the player has driven a while, then every CALL_COOL s; or the
## pill WYŚCIG ŁODZI by the start pontoon): ODBIERZ, then PŁYNĘ! puts a beacon on the pontoon at
## the mouth of Port Czerniakowski. Stop there and the car stays on the bank: the player takes the
## runabout "Szprotka" on the grid with three rivals (Szymek's red runabout, Pan Zdzisiek's old
## "Złota Rybka", Kamil's jet ski), 3-2-1, and races 3.1 km downstream under four bridges through
## 25 rings to the finish arch below Most Śląsko-Dąbrowski.
##
## Rules: every ring must be passed through (gold rings are extra: a boost, no penalty). A ring
## passed outside its opening, or left behind, is a miss (PUDŁO); the third miss is ODPADASZ!
## with JESZCZE RAZ (the grid again) or WYJDŹ (back to the car). Rings in a row build the rhythm
## (RYTM, +3 % top speed a ring, up to +15 %; a miss resets it). The rivals play by the same rules
## and can drop out. A sand barge pushed upstream throws big wake rings across the course.
##
## The boats (boat.gd) share one model; the rivals drive it through `steer` / `throttle` from a
## racing line through each ring at their own offset, slow for sharp rings, avoid and block, make
## mistakes by temperament, and are rubber-banded only off screen. Waves: a low chop plus wake
## rings each boat and the barge drop as they go (`wave`), felt by every hull.
##
## Free ride (F 2026-11-07): three boats of his photos stay moored along the pontoon, each with its
## own feel (boat.gd SPECS): the jet ski "Rekin X", the electric runabout "Srebrna Strzała" and the
## offshore "Czarna Pantera". Stop there and the pill PRZYSTAŃ opens the marina card: pick one and
## take it out with nobody else (no rings, no clock; the sand barge passes for its wake), ✕ on the
## panel ends the ride and the car is where it was left; WYŚCIG starts the race as before.
##
## While the race is on, the game shadows the car on the player's boat (main.gd `_boat_frame`), so
## the camera, the streamer and the minimap follow it; the car itself waits on the bank.
##
## Cost: nothing per frame while idle but a timer. During the race: 4 boats + the barge (5 draw
## calls), the next 3 rings and the finish (up to 4), one foam mesh (1): about +10 draw calls; four
## sphere tests a frame against the world; the wave sum ~1k cheap terms a frame.

const Boat := preload("res://scripts/boat.gd")
const Models := preload("res://scripts/models.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

const COURSE := "res://data/boat_race.json"
const COLOUR := Color("#2fb8e0")      # the Vistula's blue: the race's accent
const RING := Color("#ff7a1a")
const RING_NEXT := Color("#ffb347")
const GOLD := Color("#ffd23f")
const FAIL := Color("#e2574c")
const NAME := "Wiślana Szprotka"

## The start pontoon on the left bank at the harbour's mouth, and where the car stops by it.
const PONTOON := [Vector2(1464.0, 703.0), Vector2(1500.0, 690.0)]
## The pontoon's deck is 3.2 m wide: solid for the boats (solid_at), a capsule along PONTOON.
const PONTOON_HALF_W := 1.8
const CAR_SPOT := Vector2(1446.0, 716.0)
## The free-ride fleet, moored alongside the pontoon on its upstream (south) side, bows to the river
## (MOOR_YAW): `along` m out along the deck from its bank end, `off` m off its centre line
## (the deck's half width + the boat's radius + a metre or so: the current sets them on the deck).
## Their places are worked out from PONTOON in `_fleet_spot`.
const FLEET := [
	{"kind": Boat.Kind.SKUTER, "name": "Rekin X", "short": "REKIN X", "what": ["skuter", "jet ski"], "along": 7.0, "off": 4.0},
	{"kind": Boat.Kind.ELECTRIC, "name": "Srebrna Strzała", "short": "STRZAŁA", "what": ["elektryczna", "electric"], "along": 17.0, "off": 5.0},
	{"kind": Boat.Kind.OFFSHORE, "name": "Czarna Pantera", "short": "PANTERA", "what": ["offshore", "offshore"], "along": 30.0, "off": 7.0},
]
## Bows 35° off the deck towards the open river, in echelon: each boat leaves clear of the ones
## moored further out.
const MOOR_YAW := 1.31
const FREE_COLOUR := Color("#1f4fa8")
const ARRIVE := 9.0
const PILL_R := 45.0

## The call: daytime, after FIRST_CALL s of play, then every CALL_COOL s; the card's life.
const HOURS := [7.0, 22.0]
const FIRST_CALL := 300.0
const CALL_COOL := 1500.0
const CARD_LIFE := 12.0
const PLAY_LIMIT := 1800.0

## The rules.
const MISSES := 3
const RHYTHM_STEP := 0.03
const RHYTHM_MAX := 5
const GOLD_BOOST := 1.18
const GOLD_TIME := 2.5
const COUNT := 3.0
## Pay by place *guess*: [złoty, respect].
const PAY := [[150, 40], [60, 15], [25, 5], [0, 0]]

## The river.
const FLOW := 1.0            # m/s downstream
const CHOP := 0.07           # m
const WAKE_EVERY := 0.32     # s between a boat's wake rings
const WAKE_N := 10           # rings kept per source
const WAKE_LIFE := 3.4       # s
const WAKE_SPREAD := 5.0     # m/s the ring grows
const WAKE_W := 1.6          # m, a crest's half width when new
const BARGE_SPEED := 2.4     # m/s upstream
const BARGE_LEN := 72.0
const BARGE_HALF_W := 5.6
const BARGE_WAKE := 0.8      # m
const OWN_WAKE := 0.7        # s: a boat does not feel its own newest rings

## The rivals: name, kind, paint, shirt, hair, line offset share, mistake chance a ring, block,
## pace (share of the kind's top), start delay (s), the dialogue tag.
const RIVALS := [
	{"name": "Szymek", "kind": Boat.Kind.RUNABOUT, "paint": "#c8302c", "shirt": "#2f6fb5", "hair": "#4a3426",
		"line": 0.15, "miss": 0.03, "block": 0.3, "pace": 0.975, "delay": 0.35, "tag": "szymek"},
	{"name": "Pan Zdzisiek", "kind": Boat.Kind.TUB, "line": 0.0, "miss": 0.0, "block": 0.0, "pace": 1.0,
		"delay": 0.8, "tag": "zdzisiek"},
	{"name": "Kamil", "kind": Boat.Kind.JETSKI, "line": 0.35, "miss": 0.05, "block": 0.8, "pace": 1.0,
		"delay": 0.15, "tag": "kamil"},
]
const PLAYER_PAINT := Color("#ff8a1a")
const RUBBER := 0.07
const RUBBER_GAP := 60.0

enum State { IDLE, RING, OFFER, TO_PIER, COUNTDOWN, RACE, OUT, DONE, MENU, FREE }

## Set by the game.
var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var map: Node3D
var car: Node3D
var log_on := false
var autopilot := false
## () -> bool: nothing else on (no card, job, race, rescue...).
var free_now: Callable = func() -> bool: return true
## () -> [position: Vector3, speed km/h, flying: bool]
var vehicle: Callable
## (Vector3) -> bool: the point is on screen (the rubber band only works off it).
var seen: Callable = func(_p: Vector3) -> bool: return true
## () -> float, the hour of day.
var clock: Callable = func() -> float: return 12.0
## A stop at the pontoon hands the race the controls; leaving hands them back (main.gd).
signal boarded
signal left_boat

var state := State.IDLE
var line: PackedVector2Array = PackedVector2Array()
var half_w: PackedFloat32Array = PackedFloat32Array()
var rings: Array = []
var grid: Array = []
var barge_cfg: Dictionary = {}
var flow_dir := Vector2(-0.36, -0.93)
var water_y := 0.0

var player: Boat
## The free-ride fleet (FLEET order; moored, or one of them the player's while State.FREE), each
## with its two looks [parked, ridden], and the one out now (-1: none).
var fleet: Array[Boat] = []
var _fleet_meshes: Array = []
var riding := -1
var free_boat: Boat
var _free_status_t := 0.0
var boats: Array[Boat] = []          # player first, then the rivals
var racers: Array = []         # per boat: {name, next, misses, rhythm, gold_t, out, finished, place, time, li, ...}
var clock_t := 0.0
## The water's own clock (runs on after the finish, so the wakes keep moving).
var wave_t := 0.0
var _t := 0.0
var _session := 0.0
var _next_call := FIRST_CALL
var _count := 0.0
var _finish_order: Array = []
var _rng := RandomNumberGenerator.new()
var _beacon: Node3D
var _ring_nodes: Array[MeshInstance3D] = []
var _mats := {}
var _barge: MeshInstance3D
var _barge_pos := Vector2.ZERO
var _barge_dir := Vector2.ZERO
var _barge_li := 0.0
var _foam: MeshInstance3D
var _foam_mesh: ImmediateMesh
var _pontoon: MeshInstance3D
## Wake rings: per source (boats, then the barge's bow and stern) a ring buffer.
var _wakes: Array = []
var _wake_t: Array = []
var _query: PhysicsShapeQueryParameters3D
var _sphere: SphereShape3D
var _car_spot := Vector3.ZERO
var _car_yaw := 0.0
var _result: Dictionary = {}
var _last_line_t := 0.0
var _solid_log := -10.0
var _piers := {}
const PIER_CELL := 40.0
## Testing aids.
var force_hours := false
## The WYŚCIG ŁODZI pill by the pontoon; off when story_quests.gd's in-person start owns the spot.
var walk_up_pill := true


func setup(world: Node3D) -> void:
	_rng.randomize()
	_load_course()
	water_y = map.terrain_height(line[0].x, line[0].y) if map != null and map.has_method("terrain_height") else 0.0
	_build_materials()
	_build_pontoon(world)
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#1f3a5f"))
	_beacon.visible = false
	_sphere = SphereShape3D.new()
	_query = PhysicsShapeQueryParameters3D.new()
	_query.shape = _sphere
	_build_boats()
	_build_free_boat()
	_build_rings()
	_build_barge()
	_foam_mesh = ImmediateMesh.new()
	_foam = MeshInstance3D.new()
	_foam.mesh = _foam_mesh
	_foam.material_override = _mats["foam"]
	_foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_foam)
	_show_race(false)
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func() -> void:
		if state in [State.TO_PIER, State.COUNTDOWN, State.RACE]:
			_quit()
		elif state == State.FREE:
			end_free_ride())
	hud.context_pressed.connect(func(owner: String) -> void:
		if owner == "boat" and state == State.IDLE:
			hud.hide_pill()
			_marina_card())


func _load_course() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COURSE))
	for p: Array in data["line"]:
		line.append(Vector2(float(p[0]), float(p[1])))
		half_w.append(float(p[2]))
	rings = data["rings"]
	grid = data["grid"]
	barge_cfg = data["barge"]
	flow_dir = Vector2(float(data["flow"][0]), float(data["flow"][1]))
	# The bridge piers in the water (tools/boat_course.py, circles): solid whether or not their
	# sector's colliders are loaded, bucketed by PIER_CELL m.
	for c: Array in data.get("piers", []):
		var key := Vector2i(floori(float(c[0]) / PIER_CELL), floori(float(c[1]) / PIER_CELL))
		if not _piers.has(key):
			_piers[key] = []
		_piers[key].append(Vector3(float(c[0]), float(c[1]), float(c[2])))


func busy() -> bool:
	return state != State.IDLE and state != State.RING


## The player is in the boat (the game drives it and shadows the car on it).
func boating() -> bool:
	return state in [State.COUNTDOWN, State.RACE, State.OUT, State.DONE, State.FREE]


func has_target() -> bool:
	return state == State.TO_PIER or state == State.RACE


func target_position() -> Vector3:
	if state == State.TO_PIER:
		return _car_spot_3d()
	var r: Dictionary = rings[mini(int(racers[0]["next"]), rings.size() - 1)] if not racers.is_empty() else rings[0]
	return Vector3(float(r["x"]), water_y, float(r["z"]))


func target_colour() -> Color:
	return COLOUR if state == State.TO_PIER else RING_NEXT


func _car_spot_3d() -> Vector3:
	return Vector3(CAR_SPOT.x, map.ground_height(CAR_SPOT.x, CAR_SPOT.y), CAR_SPOT.y)


# --- the call and the pontoon ----------------------------------------------------------------------

func _process(dt: float) -> void:
	_t += dt
	_session += dt
	match state:
		State.IDLE:
			_idle_tick()
		State.MENU:
			var mv: Array = vehicle.call() if vehicle.is_valid() else []
			var away := not mv.is_empty() and Vector2(mv[0].x, mv[0].z).distance_to(CAR_SPOT) > PILL_R
			if _t > CARD_LIFE or away:
				hud.hide_card()
				state = State.IDLE  # the call's timer runs on untouched
		State.FREE:
			_free_tick(dt)
		State.RING, State.OFFER:
			if _t > CARD_LIFE:
				hud.hide_card()
				_reset(CALL_COOL * 0.5)
			elif autopilot and _t > 1.5:
				_on_card(0)
		State.TO_PIER:
			_pier_tick()
		State.COUNTDOWN:
			_countdown_tick(dt)
		State.RACE:
			_race_tick(dt)
		State.OUT, State.DONE:
			_idle_boats(dt)
			if autopilot and _t > 3.0:
				_on_card(1)


func _idle_tick() -> void:
	if not vehicle.is_valid():
		return
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var near := walk_up_pill and Vector2(p.x, p.z).distance_to(CAR_SPOT) < PILL_R and not bool(v[2])
	if near and free_now.call() and hud.pill_free_for("boat"):
		if not hud.pill_shown("boat"):
			hud.show_pill("PRZYSTAŃ", "MARINA", "boat")
	elif hud.pill_shown("boat"):
		hud.hide_pill()
	if _session < _next_call or int(_session * 2.0) == int((_session - get_process_delta_time()) * 2.0):
		return
	var h: float = clock.call()
	if not force_hours and (h < HOURS[0] or h >= HOURS[1]):
		return
	if bool(v[2]) or not free_now.call():
		return
	ring()


## Szymek met in person at the pontoon (story_quests.gd: he walks up, the player said WCHODZĘ):
## no call, straight to the start. False unless idle.
func meet() -> bool:
	if state != State.IDLE:
		return false
	if hud.pill_shown("boat"):
		hud.hide_pill()
	_log("met Szymek at the pontoon")
	_go_to_pier()
	return true


## Idle: not ringing, not racing (a questline may start now).
func idle() -> bool:
	return state == State.IDLE


## Szymek phones.
func ring() -> bool:
	if state != State.IDLE:
		return false
	state = State.RING
	_t = 0.0
	hud.show_side_card("📞 SZYMEK DZWONI", "Kumpel z przystani w Porcie Czerniakowskim. Ma motorówkę, za dużo wolnego czasu i zero cierpliwości.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "Szymek is calling",
			"Your mate from the marina at Port Czerniakowski. He has a motorboat, too much free time and no patience.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


func _offer() -> void:
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("SZYMEK: „ŚCIGAMY SIĘ?”",
			"„Słuchaj, %s! Pan Zdzisiek wyciągnął Złotą Rybkę, Kamil swój skuter. Płyniemy z Portu Czerniakowskiego pod Śląsko-Dąbrowski, przez kółka. Trzy pudła i odpadasz. Wchodzisz?”" % NAME,
			PackedStringArray(["PŁYNĘ!|I'M IN!", "NIE DZIŚ|NOT TODAY"]), COLOUR, "Szymek: \"Race you?\"",
			"\"Listen, the %s! Pan Zdzisiek got the Złota Rybka out, Kamil his jet ski. We go from Port Czerniakowski down to Śląsko-Dąbrowski, through the rings. Three misses and you're out. You in?\"" % NAME)


func _on_card(i: int) -> void:
	match state:
		State.RING:
			if i == 0:
				_offer()
			else:
				hud.hide_card()
				_reset(CALL_COOL)
		State.OFFER:
			hud.hide_card()
			if i == 0:
				_go_to_pier()
			else:
				_reset(CALL_COOL)
		State.OUT, State.DONE:
			hud.hide_card()
			if i == 0:
				_start_grid()
			else:
				_quit()
		State.MENU:
			hud.hide_card()
			state = State.IDLE
			if i < FLEET.size():
				free_ride(i)
			elif i == FLEET.size():
				_board()


func _go_to_pier() -> void:
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	if Vector2(p.x, p.z).distance_to(CAR_SPOT) < ARRIVE * 2.0 and not bool(v[2]):
		_board()
		return
	state = State.TO_PIER
	_t = 0.0
	_beacon.visible = true
	_beacon.place(_car_spot_3d(), ARRIVE - 0.5)
	hud.toast("Na przystań: start przy ujściu Portu Czerniakowskiego", "To the pontoon: the start at the mouth of Port Czerniakowski")
	_log("to the pontoon")


func _pier_tick() -> void:
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var d := Vector2(p.x, p.z).distance_to(CAR_SPOT)
	if not bool(v[2]) and d < ARRIVE and float(v[1]) < 12.0:
		_board()
	elif _t > PLAY_LIMIT:
		_reset(CALL_COOL)


## The car stays on the bank; the boats go on the grid.
func _board() -> void:
	_beacon.visible = false
	_car_spot = car.global_position if car != null else _car_spot_3d()
	_car_yaw = car.rotation.y if car != null else 0.0
	boarded.emit()
	_start_grid()


func _start_grid() -> void:
	hud.hide_card()
	hud.hide_pill()
	var f := flow_dir
	var heading := atan2(f.x, f.y)
	racers.clear()
	_finish_order.clear()
	for k in boats.size():
		var b: Boat = boats[k]
		var g: Array = grid[k]
		b.place(Vector2(float(g[0]), float(g[1])), heading)
		b.visible = true
		var r := {"name": "Ty" if k == 0 else String(RIVALS[k - 1]["name"]), "next": 0, "misses": 0, "rhythm": 0,
				"gold_t": 0.0, "out": false, "finished": false, "time": 0.0, "li": 0.0, "prev": b.pos,
				"aim": _rng.randf_range(-1.0, 1.0), "mistake": false, "block_t": 0.0, "said": 0.0}
		racers.append(r)
	_place_barge()
	for w: Array in _wakes:
		w.clear()
	for k in _wake_t.size():
		_wake_t[k] = 0.0
	_show_race(true)
	_update_rings()
	state = State.COUNTDOWN
	_count = COUNT + 0.6
	clock_t = 0.0
	_t = 0.0
	_log("grid: 4 boats, %d rings" % rings.size())


func _countdown_tick(dt: float) -> void:
	_count -= dt
	_hold_boats(dt)
	_status()
	var n := ceili(_count - 0.6)
	if n >= 1:
		hud.show_banner(str(n), COLOUR)
	else:
		hud.show_banner("START!", Access.GREEN)
		state = State.RACE
		_t = 0.0
		_say(1, "start")
		Access.buzz(80, 0.8)
		_log("start")


## Before the start: the boats sit on the grid, bobbing.
func _hold_boats(dt: float) -> void:
	_tick_wakes(dt)
	for b: Boat in boats:
		var keep: Vector2 = b.pos
		b.throttle = 0.0
		b.steer = 0.0
		b.braking = false
		b.target_dir = Vector3.ZERO
		b.step(dt)
		b.pos = keep
		b.vel = Vector2.ZERO


func _idle_boats(dt: float) -> void:
	if state == State.DONE:
		clock_t += dt  # the rivals still out there get their times
	_tick_wakes(dt)
	_barge_tick(dt)
	for k in boats.size():
		var b: Boat = boats[k]
		if k > 0 and not bool(racers[k]["finished"]) and not bool(racers[k]["out"]):
			racers[k]["prev"] = b.pos
			_drive_rival(k, dt)
			b.step(dt)
			_check_rings(k)
			_progress(k)
			continue
		else:
			b.throttle = 0.0
			b.target_dir = Vector3.ZERO
			b.braking = b.forward_speed() > 1.0
		b.step(dt)
	_draw_foam()


# --- free ride ---------------------------------------------------------------------------------------

## The pill PRZYSTAŃ: the marina's card (one of the three boats, or the race).
func _marina_card() -> void:
	state = State.MENU
	_t = 0.0
	# Short names in one row (a name reads the same in both languages: one line a button), so the
	# card fits a phone beside the other panels; no NIE TERAZ: the card goes by itself
	# (CARD_LIFE) or when the car drives off.
	var buttons := PackedStringArray()
	for f: Dictionary in FLEET:
		buttons.append(String(f["short"]))
	buttons.append("WYŚCIG")
	hud.show_card("PRZYSTAŃ · wybierz łódź", "Rekin X: skuter. Srebrna Strzała: elektryczna. Czarna Pantera: offshore, najszybsza, ponad 70 km/h.",
			buttons, FREE_COLOUR, false, "MARINA · pick a boat", "Rekin X: jet ski. Srebrna Strzała: electric. Czarna Pantera: offshore, the fastest, over 70 km/h.")
	_log("marina card")


## The mooring of FLEET[i] (x, z).
static func fleet_spot(i: int) -> Vector2:
	var a: Vector2 = PONTOON[0]
	var dir: Vector2 = (PONTOON[1] - PONTOON[0]).normalized()
	var south := Vector2(-dir.y, dir.x)
	if south.y < 0.0:
		south = -south
	return a + dir * float(FLEET[i]["along"]) + south * float(FLEET[i]["off"])


## Out on the river in FLEET[i]: no rings, no rivals, no clock; ✕ ends it.
func free_ride(i := 1) -> void:
	i = clampi(i, 0, FLEET.size() - 1)
	_beacon.visible = false
	hud.hide_pill()
	_car_spot = car.global_position if car != null else _car_spot_3d()
	_car_yaw = car.rotation.y if car != null else 0.0
	state = State.FREE
	_t = 0.0
	_free_status_t = 0.0
	riding = i
	free_boat = fleet[i]
	free_boat.set_mesh(_fleet_meshes[i][1])
	free_boat.place(fleet_spot(i), MOOR_YAW)
	player = free_boat
	for w: Array in _wakes:
		w.clear()
	_place_barge()
	boarded.emit()
	var name: String = FLEET[i]["name"]
	hud.toast("%s jest twoja. ✕ na panelu: z powrotem do auta" % name, "The %s is yours. ✕ on the panel: back to the car" % name)
	_free_status()
	_log("free ride: %s" % name)


func _free_tick(dt: float) -> void:
	_tick_wakes(dt)
	_barge_tick(dt)
	var b := free_boat
	_wake_t[0] = float(_wake_t[0]) + dt
	var v: float = b.speed()
	if v > 4.0 and not b.air and float(_wake_t[0]) >= WAKE_EVERY:
		_wake_t[0] = 0.0
		_drop(0, b.pos - b.forward() * float(b.spec["len"]) * 0.45, float(b.spec["wake"]) * clampf(v / float(b.spec["top"]), 0.0, 1.2), b.forward())
	b.boost = 1.0
	b.step(dt)
	if b.bumped > 2.5 or b.landed > Boat.HARD_LANDING:
		Access.buzz(40, clampf(maxf(b.bumped, b.landed) / 10.0, 0.3, 0.9))
	_draw_foam()
	_free_status_t -= dt
	if _free_status_t <= 0.0:
		_free_status()


func _free_status() -> void:
	_free_status_t = 0.25
	var kmh := roundi(free_boat.forward_speed() * 3.6)
	var home := roundi(free_boat.pos.distance_to(fleet_spot(riding)))
	hud.show_status("Rejs · %s" % FLEET[riding]["name"], _clock_text(_t), "%d km/h" % maxi(kmh, 0),
			"Przystań %d m · ✕ do auta" % home, 0.0, FREE_COLOUR, "", {}, "Marina %d m · ✕ to the car" % home)


## Back to the car on the bank; the boat goes back to its mooring.
func end_free_ride() -> void:
	if state != State.FREE:
		return
	hud.hide_status()
	_barge.visible = false
	_foam_mesh.clear_surfaces()
	player = boats[0]
	_park(riding)
	riding = -1
	state = State.IDLE
	_t = 0.0
	left_boat.emit()
	_log("free ride over")


func _park(i: int) -> void:
	var b: Boat = fleet[i]
	b.set_mesh(_fleet_meshes[i][0])
	b.place(fleet_spot(i), MOOR_YAW)
	b.visible = true


## The fleet: hulls on the same water as the race's boats (slot 0's wakes while one is ridden: the
## race's boat 0 is not out then); the moored ones are solid for the boat out (solid_at).
func _build_free_boat() -> void:
	var mat := Models.material()
	for i in FLEET.size():
		var k := int(FLEET[i]["kind"])
		var looks: Array
		match k:
			Boat.Kind.SKUTER:
				looks = [Boat.skuter_mesh(false), Boat.skuter_mesh(true)]
			Boat.Kind.ELECTRIC:
				looks = [Boat.electric_mesh(false), Boat.electric_mesh(true)]
			_:
				looks = [Boat.offshore_mesh(false), Boat.offshore_mesh(true)]
		_fleet_meshes.append(looks)
		var b := Boat.new()
		b.name = "Fleet%d" % i
		add_child(b)
		b.setup(k, looks[0], mat)
		b.water_y = water_y
		b.flow = flow_dir * FLOW
		b.wave = func(x: float, z: float) -> float: return wave(x, z, 0)
		if map != null:
			b.shore = map.shore_distance
		b.solid = solid_at
		fleet.append(b)
		_park(i)
	free_boat = fleet[1]


# --- the race --------------------------------------------------------------------------------------

func _race_tick(dt: float) -> void:
	clock_t += dt
	if _t > 1.0:
		hud.hide_banner()
	_tick_wakes(dt)
	_barge_tick(dt)
	for k in boats.size():
		var b: Boat = boats[k]
		var r: Dictionary = racers[k]
		r["prev"] = b.pos
		if k > 0:
			if bool(r["out"]) or bool(r["finished"]):
				b.throttle = 0.0
				b.braking = b.forward_speed() > 1.0
			elif clock_t < float(RIVALS[k - 1]["delay"]):
				b.throttle = 0.0
			else:
				_drive_rival(k, dt)
		elif autopilot or bool(r["finished"]):
			_drive_rival(0, dt)
		r["gold_t"] = maxf(0.0, float(r["gold_t"]) - dt)
		b.boost = (1.0 + RHYTHM_STEP * mini(int(r["rhythm"]), RHYTHM_MAX)) * (GOLD_BOOST if float(r["gold_t"]) > 0.0 else 1.0)
		if k > 0:
			b.boost *= _rubber(k)
		b.step(dt)
		_check_rings(k)
		_progress(k)
		if k == 0 and (b.bumped > 2.5 or b.landed > Boat.HARD_LANDING):
			Access.buzz(40, clampf(maxf(b.bumped, b.landed) / 10.0, 0.3, 0.9))
	_update_rings()
	_draw_foam()
	_status()
	_chatter(dt)
	if bool(racers[0]["finished"]) and state == State.RACE:
		_finish()


## Did boat k go through its next ring this step?
func _check_rings(k: int) -> void:
	var r: Dictionary = racers[k]
	if bool(r["out"]) or bool(r["finished"]):
		return
	var b: Boat = boats[k]
	var p0: Vector2 = r["prev"]
	var p1: Vector2 = b.pos
	var i := int(r["next"])
	# Gold rings in the way: a pass is a boost, a miss nothing; then the next real ring.
	while i < rings.size():
		var g: Dictionary = rings[i]
		var hit := _crossing(g, p0, p1)
		if hit == 0:
			# Left behind: the boat has crossed a later ring's line already.
			if i + 1 < rings.size() and _crossing(rings[i + 1], p0, p1) != 0:
				if not bool(g["gold"]):
					_miss(k, i)
				i += 1
				r["next"] = i
				continue
			return
		if hit > 0:
			if bool(g["finish"]):
				r["finished"] = true
				r["time"] = clock_t
				_finish_order.append(k)
				_log("%s finishes %d. in %.1f s" % [r["name"], _finish_order.size(), clock_t])
				if k > 0:
					_say(k, "finish")
			elif bool(g["gold"]):
				r["gold_t"] = GOLD_TIME
				if k == 0:
					hud.toast("ZŁOTE KÓŁKO! Dopalacz", "GOLD RING! Boost")
					Access.buzz(30, 0.5)
			else:
				r["rhythm"] = int(r["rhythm"]) + 1
				if k == 0 and int(r["rhythm"]) > 1 and int(r["rhythm"]) <= RHYTHM_MAX:
					hud.ambient_toast("Rytm ×%d" % int(r["rhythm"]), "Rhythm ×%d" % int(r["rhythm"]))
		elif not bool(g["gold"]):
			_miss(k, i)
		i += 1
		r["next"] = i
		return


## +1 through the opening, -1 over the ring's line but outside the opening, 0 not crossed.
func _crossing(g: Dictionary, p0: Vector2, p1: Vector2) -> int:
	var c := Vector2(float(g["x"]), float(g["z"]))
	var yaw := float(g["yaw"])
	var f := Vector2(sin(yaw), cos(yaw))
	var s0 := (p0 - c).dot(f)
	var s1 := (p1 - c).dot(f)
	if not (s0 < 0.0 and s1 >= 0.0):
		return 0
	var x := p0 + (p1 - p0) * (s0 / (s0 - s1))
	var across := absf((x - c).dot(Vector2(f.y, -f.x)))
	if across > 260.0:
		return 0
	return 1 if across <= float(g["w"]) * 0.5 - 0.4 else -1


func _miss(k: int, i: int) -> void:
	var r: Dictionary = racers[k]
	r["misses"] = int(r["misses"]) + 1
	r["rhythm"] = 0
	_log("%s misses ring %d (%d/%d)" % [r["name"], i, int(r["misses"]), MISSES])
	if k == 0:
		Access.buzz(90, 0.9)
		if int(r["misses"]) >= MISSES:
			_out()
		else:
			hud.toast("PUDŁO! %d/%d" % [int(r["misses"]), MISSES], "MISSED! %d/%d" % [int(r["misses"]), MISSES])
			_say(-1, "player_miss")
	else:
		if int(r["misses"]) >= MISSES:
			r["out"] = true
			hud.ambient_toast("%s odpada! Trzy pudła." % r["name"], "%s is out! Three misses." % r["name"])
			_say(k, "out")
		else:
			_say(k, "miss")


## The player's third miss.
func _out() -> void:
	racers[0]["out"] = true
	state = State.OUT
	_t = 0.0
	hud.hide_status()
	hud.show_banner("ODPADASZ!", FAIL)
	hud.show_card("ODPADASZ! Trzy pudła.", "Szymek: „No to klasyk. Kółka, nie bojki do omijania! Jeszcze raz?”",
			PackedStringArray(["JESZCZE RAZ|AGAIN", "WYJDŹ|QUIT"]), FAIL, false, "YOU'RE OUT! Three misses.",
			"Szymek: \"A classic. Rings, not buoys to dodge! Once more?\"")
	_log("player out after %.1f s" % clock_t)


func _finish() -> void:
	state = State.DONE
	_t = 0.0
	var place := _finish_order.find(0) + 1
	var pay: Array = PAY[clampi(place - 1, 0, PAY.size() - 1)]
	if wallet != null and int(pay[0]) > 0:
		wallet.pay(int(pay[0]), int(pay[1]), "boat_race")
	hud.hide_status()
	hud.hide_banner()
	var t := _clock_text(float(racers[0]["time"]))
	var words := ["Pierwszy! Szymek stawia lody na bulwarach.", "Drugi. Szymek: „Rewanż, ale już!”", "Trzeci. Pan Zdzisiek kiwa głową z uznaniem.", "Ostatni. Kamil już nagrywa relację."]
	var words_en := ["First! Szymek buys the ice cream on the boulevards.", "Second. Szymek: \"Rematch, right now!\"", "Third. Pan Zdzisiek nods his approval.", "Last. Kamil is already filming his story."]
	var w := clampi(place - 1, 0, 3)
	hud.show_card("META! %d. miejsce · %s" % [place, t], "%s%s" % [words[w], "  +%d zł  +%d szacunu" % pay if int(pay[0]) > 0 else ""],
			PackedStringArray(["REWANŻ|REMATCH", "WYJDŹ|QUIT"]), COLOUR, false, "FINISH! Place %d · %s" % [place, t],
			"%s%s" % [words_en[w], "  +%d zł  +%d respect" % pay if int(pay[0]) > 0 else ""])
	_result = {"place": place, "time": float(racers[0]["time"]), "misses": int(racers[0]["misses"])}
	_log("player finishes %d. in %.1f s, %d misses" % [place, float(racers[0]["time"]), int(racers[0]["misses"])])


## Back to the car on the bank.
func _quit() -> void:
	hud.hide_card()
	hud.hide_status()
	hud.hide_banner()
	_beacon.visible = false
	var was := boating()
	_show_race(false)
	_reset(CALL_COOL)
	if was:
		left_boat.emit()
	_log("back to the car")


func _reset(cool: float) -> void:
	state = State.IDLE
	_t = 0.0
	_next_call = _session + cool


func last_result() -> Dictionary:
	return _result


# --- the rivals --------------------------------------------------------------------------------------

## Boat k drives itself down the racing line (a rival, or the player's boat on autopilot or after
## the finish): it aims at its next ring at its own offset, looks ahead along the line between the
## rings, slows for a sharp one, keeps off the boat in front, blocks a boat close behind.
func _drive_rival(k: int, dt: float) -> void:
	var b: Boat = boats[k]
	var r: Dictionary = racers[k]
	var cfg: Dictionary = RIVALS[k - 1] if k > 0 else {"line": 0.1, "miss": 0.0, "block": 0.0, "pace": 1.0}
	var i := mini(int(r["next"]), rings.size() - 1)
	if bool(r["finished"]):
		# Ease off down the river after the line.
		b.target_dir = Vector3(flow_dir.x, 0.0, flow_dir.y) * 0.3
		return
	var g: Dictionary = rings[i]
	var aim := _ring_aim(k, i, cfg)
	var to := aim - b.pos
	var d := to.length()
	# Look past the ring once close: the line from this ring to the next.
	var want := aim
	if i + 1 < rings.size():
		var aim2 := _ring_aim(k, i + 1, cfg)
		var look := 6.0 + b.speed() * 0.55
		if d < look:
			want = aim.lerp(aim2, clampf((look - d) / look, 0.0, 0.6))
	# Keep clear of a boat just ahead; block a boat close behind.
	var f: Vector2 = b.forward()
	var right := Vector2(f.y, -f.x)
	for j in boats.size():
		if j == k:
			continue
		var o: Boat = boats[j]
		var rel: Vector2 = o.pos - b.pos
		var ahead := rel.dot(f)
		var side := rel.dot(right)
		if ahead > 0.0 and ahead < 14.0 and absf(side) < 4.5:
			want += right * (-signf(side) if side != 0.0 else 1.0) * 5.0
		elif ahead < -3.0 and ahead > -22.0 and absf(side) < 7.0 and float(cfg["block"]) > 0.0 and j == 0:
			r["block_t"] = float(r["block_t"]) + dt
			if float(r["block_t"]) < 2.5 * float(cfg["block"]):
				want += right * side * 0.6
		else:
			r["block_t"] = maxf(0.0, float(r["block_t"]) - dt * 0.5)
	# The turn at this ring: slow before a sharp one.
	var turn := 0.0
	if i + 1 < rings.size():
		var nxt := Vector2(float(rings[i + 1]["x"]), float(rings[i + 1]["z"]))
		var a1 := (aim - b.pos)
		var a2 := (nxt - aim)
		if a1.length() > 1.0 and a2.length() > 1.0:
			turn = absf(a1.angle_to(a2))
	var top: float = b.top() * float(cfg["pace"])
	var corner := top * (1.0 - 0.32 * clampf((turn - 0.5) / 1.0, 0.0, 1.0))
	var vf: float = b.forward_speed()
	var brake_d := maxf(0.0, (vf * vf - corner * corner) / (2.0 * Boat.BRAKE * 0.6)) + 8.0
	var go := 1.0
	if d < brake_d and vf > corner + 0.5:
		go = 0.0
	# The barge's wake ahead: Pan Zdzisiek takes it slow.
	if b.kind == Boat.Kind.TUB and _barge.visible and b.pos.distance_to(_barge_pos) < 70.0:
		go = minf(go, 0.6)
	var err := wrapf(atan2(want.x - b.pos.x, want.y - b.pos.y) - b.yaw, -PI, PI)
	b.target_dir = Vector3.ZERO
	b.steer = clampf(err * 2.4, -1.0, 1.0)
	b.throttle = go
	b.braking = go == 0.0 and vf > corner + 3.0
	if absf(err) > 1.4 and vf > 8.0:
		b.throttle = 0.3
	if bool(g["gold"]) and float(cfg["line"]) > 0.3:
		pass


## Where boat k aims through ring i: the ring's centre at its own share of the opening (fixed per
## race, `aim`), or past the opening when this ring is its mistake.
func _ring_aim(k: int, i: int, cfg: Dictionary) -> Vector2:
	var g: Dictionary = rings[i]
	var c := Vector2(float(g["x"]), float(g["z"]))
	var yaw := float(g["yaw"])
	var across := Vector2(cos(yaw), -sin(yaw))
	var r: Dictionary = racers[k]
	var half := float(g["w"]) * 0.5 - 2.4
	var off := float(r["aim"]) * float(cfg["line"]) * half
	# A gold ring is a detour: the careful skip it when it is off their line.
	var key := "m%d" % i
	if not r.has(key):
		r[key] = _rng.randf() < float(cfg["miss"]) and not bool(g["finish"])
	if bool(r[key]):
		off = (half + 4.0 + float(g["w"]) * 0.3) * (1.0 if float(r["aim"]) >= 0.0 else -1.0)
	return c + across * off


## Off screen only: a rival far ahead eases, one far behind pushes (never on the player's screen).
func _rubber(k: int) -> float:
	var me: float = racers[k]["li"]
	var you: float = racers[0]["li"]
	var b: Boat = boats[k]
	if seen.call(b.position):
		return 1.0
	var gap := (me - you) * 10.0
	if gap > RUBBER_GAP:
		return 1.0 - RUBBER
	if gap < -RUBBER_GAP:
		return 1.0 + RUBBER
	return 1.0


## How far down the line boat k is (line points, fractional), searched round the last value.
func _progress(k: int) -> void:
	var r: Dictionary = racers[k]
	var b: Boat = boats[k]
	var li := int(r["li"])
	var best := li
	var bd := INF
	for j in range(maxi(0, li - 3), mini(line.size(), li + 8)):
		var dd: float = b.pos.distance_squared_to(line[j])
		if dd < bd:
			bd = dd
			best = j
	var frac := 0.0
	if best + 1 < line.size():
		var seg := line[best + 1] - line[best]
		frac = clampf((b.pos - line[best]).dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
	r["li"] = float(best) + frac


## The player's place now (1-4): finished first, then the out last, then by the line.
func place_now() -> int:
	var mine: Dictionary = racers[0]
	var p := 1
	for k in range(1, racers.size()):
		var o: Dictionary = racers[k]
		if bool(mine["finished"]):
			if bool(o["finished"]) and _finish_order.find(k) < _finish_order.find(0):
				p += 1
		elif bool(o["finished"]):
			p += 1
		elif bool(o["out"]):
			continue
		elif float(o["li"]) > float(mine["li"]):
			p += 1
	return p


func _status() -> void:
	var r: Dictionary = racers[0]
	var place := place_now()
	var marks := ""
	for m in MISSES:
		marks += "✕" if m < int(r["misses"]) else "○"
	var next := mini(int(r["next"]), rings.size() - 1)
	var done := 0
	var total := 0
	for k in rings.size():
		if not bool(rings[k]["gold"]) and not bool(rings[k]["finish"]):
			total += 1
			if k < next:
				done += 1
	var rh := mini(int(r["rhythm"]), RHYTHM_MAX)
	hud.show_status(NAME, _clock_text(clock_t), "%d/%d" % [done, total],
			"Pudła %s · Rytm ×%d" % [marks, rh], float(r["li"]) / float(line.size() - 1), COLOUR,
			["1ST", "2ND", "3RD", "4TH"][place - 1], {}, "Misses %s · Rhythm ×%d" % [marks, rh])
	var dots := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(1, boats.size()):
		dots.append(boats[k].pos)
		cols.append(Color(RIVALS[k - 1].get("paint", "#e9dfc4")) if k != 3 else Color("#a6d63a"))
	hud.set_minimap_dots(dots, cols)


static func _clock_text(t: float) -> String:
	return "%d:%02d.%d" % [int(t) / 60, int(t) % 60, int(t * 10.0) % 10]


# --- what they say -------------------------------------------------------------------------------------

func _say(k: int, what: String) -> void:
	if dialogue == null:
		return
	if k < 0:
		# Someone near the player answers a miss.
		k = _nearest_rival()
		if k < 0:
			return
	if k == 0:
		return
	var tag := "%s_%s" % [RIVALS[k - 1]["tag"], what]
	dialogue.say(boats[k], String(RIVALS[k - 1]["name"]), "boat_race", tag, 3.0, COLOUR, 2.4, true)
	racers[k]["said"] = clock_t


func _nearest_rival() -> int:
	var best := -1
	var bd := 60.0
	for k in range(1, boats.size()):
		var d: float = boats[k].pos.distance_to(boats[0].pos)
		if d < bd and not bool(racers[k]["out"]):
			bd = d
			best = k
	return best


## Overtakes and bumps get a line now and then.
func _chatter(_dt: float) -> void:
	if clock_t - _last_line_t < 7.0:
		return
	var me: Boat = boats[0]
	for k in range(1, boats.size()):
		var b: Boat = boats[k]
		if b.pos.distance_to(me.pos) > 25.0 or bool(racers[k]["out"]):
			continue
		if me.bumped > 2.0 or b.bumped > 2.0:
			_say(k, "bump")
			_last_line_t = clock_t
			return
		var ahead: bool = float(racers[k]["li"]) > float(racers[0]["li"])
		var was: bool = racers[k].get("ahead", ahead)
		racers[k]["ahead"] = ahead
		if was != ahead:
			_say(k, "passed" if not ahead else "pass")
			_last_line_t = clock_t
			return


# --- the river: waves, wakes, the barge, the solid world -----------------------------------------------

## The water's height over its rest level at (x, z): the chop and the wake rings.
func wave(x: float, z: float, skip := -1) -> float:
	var h := CHOP * (sin(0.31 * x + 1.7 * wave_t) * 0.6 + sin(0.23 * z - 1.3 * wave_t + 0.11 * x) * 0.4)
	for s in _wakes.size():
		var ws: Array = _wakes[s]
		for w: Array in ws:
			var age: float = wave_t - float(w[1])
			if age > WAKE_LIFE or (s == skip and age < OWN_WAKE):
				continue
			var p: Vector2 = w[0]
			var r := 2.0 + age * WAKE_SPREAD
			var dx := x - p.x
			var dz := z - p.y
			var d2 := dx * dx + dz * dz
			var width := WAKE_W + age * 0.9
			var lo := r - width
			var hi := r + width
			if d2 < lo * lo or d2 > hi * hi:
				continue
			var u := (sqrt(d2) - r) / width
			h += float(w[2]) * exp(-age / 1.4) * (1.0 - u * u)
	return h


func _tick_wakes(dt: float) -> void:
	wave_t += dt
	for k in boats.size():
		var b: Boat = boats[k]
		_wake_t[k] = float(_wake_t[k]) + dt
		var v: float = b.speed()
		if b.visible and v > 4.0 and not b.air and float(_wake_t[k]) >= WAKE_EVERY:
			_wake_t[k] = 0.0
			var amp: float = float(b.spec["wake"]) * clampf(v / float(b.spec["top"]), 0.0, 1.2)
			_drop(k, b.pos - b.forward() * float(b.spec["len"]) * 0.45, amp, b.forward())
	if _barge.visible:
		var s := boats.size()
		_wake_t[s] = float(_wake_t[s]) + dt
		if float(_wake_t[s]) >= WAKE_EVERY * 1.6:
			_wake_t[s] = 0.0
			_drop(s, _barge_pos + _barge_dir * BARGE_LEN * 0.45, BARGE_WAKE, _barge_dir)
			_drop(s + 1, _barge_pos - _barge_dir * BARGE_LEN * 0.45, BARGE_WAKE * 0.7, _barge_dir)


func _drop(s: int, p: Vector2, amp: float, dir: Vector2) -> void:
	var ws: Array = _wakes[s]
	ws.append([p, wave_t, amp, atan2(-dir.y, -dir.x)])
	if ws.size() > WAKE_N:
		ws.pop_front()


func _place_barge() -> void:
	var a := int(barge_cfg.get("from", 175))
	_barge_li = float(a)
	_barge_at()
	_barge.visible = true


func _barge_at() -> void:
	var i := clampi(int(_barge_li), 1, line.size() - 2)
	var n := line[i + 1] - line[i - 1]
	var dir := -n.normalized()   # upstream
	var across := Vector2(-n.y, n.x).normalized()
	# Its lane (tools/boat_course.py: off the right bank, round the bridge piers), metres across.
	var lane: Array = barge_cfg.get("lane", [])
	var off: float = float(lane[i]) if i < lane.size() else float(barge_cfg.get("side", 0.55)) * half_w[i]
	var off2: float = float(lane[i + 1]) if i + 1 < lane.size() else off
	off = lerpf(off, off2, _barge_li - floorf(_barge_li))
	_barge_pos = line[i].lerp(line[i + 1], _barge_li - floorf(_barge_li)) + across * off
	_barge_dir = dir
	_barge.position = Vector3(_barge_pos.x, water_y, _barge_pos.y)
	_barge.rotation.y = atan2(dir.x, dir.y)


func _barge_tick(dt: float) -> void:
	if not _barge.visible:
		return
	_barge_li -= BARGE_SPEED * dt / 10.0
	if _barge_li <= float(barge_cfg.get("to", 20)):
		_barge.visible = false
		return
	_barge_at()


## The physics test for a boat: the bridge piers, the moored barges and the marina (whatever has a
## collider), and the moving barge (a capsule): the push out, ZERO when clear.
func solid_at(centre: Vector3, r: float) -> Vector2:
	var out := Vector2.ZERO
	if _barge.visible:
		var p := Vector2(centre.x, centre.z)
		var a := _barge_pos - _barge_dir * (BARGE_LEN * 0.5 - BARGE_HALF_W)
		var b := _barge_pos + _barge_dir * (BARGE_LEN * 0.5 - BARGE_HALF_W)
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < BARGE_HALF_W + r and d > 0.001:
			out += (p - q) / d * (BARGE_HALF_W + r - d)
	var p2 := Vector2(centre.x, centre.z)
	var pq := Geometry2D.get_closest_point_to_segment(p2, PONTOON[0], PONTOON[1])
	var pd := p2.distance_to(pq)
	if pd < PONTOON_HALF_W + r and pd > 0.001:
		out += (p2 - pq) / pd * (PONTOON_HALF_W + r - pd)
	# The moored fleet (not the one out).
	for i in fleet.size():
		if i == riding:
			continue
		var mq := p2 - fleet_spot(i)
		var mr := float(fleet[i].spec["r"]) + r
		if mq.length_squared() < mr * mr and mq.length_squared() > 0.0001:
			out += mq.normalized() * (mr - mq.length())
	var cell := Vector2i(floori(p2.x / PIER_CELL), floori(p2.y / PIER_CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for c: Vector3 in _piers.get(cell + Vector2i(dx, dz), []):
				var q := p2 - Vector2(c.x, c.y)
				var reach := c.z + r
				var l2 := q.length_squared()
				if l2 < reach * reach and l2 > 0.0001:
					var l := sqrt(l2)
					out += q / l * (reach - l)
	if not is_inside_tree():
		return out
	var space := get_world_3d().direct_space_state
	_sphere.radius = r
	_query.transform = Transform3D(Basis.IDENTITY, centre)
	if car != null and car is CollisionObject3D:
		_query.exclude = [(car as CollisionObject3D).get_rid()]
	var info := space.get_rest_info(_query)
	if not info.is_empty():
		var n: Vector3 = info["normal"]
		var pt: Vector3 = info["point"]
		var flat := Vector2(centre.x - pt.x, centre.z - pt.z)
		var d := flat.length()
		var nn := Vector2(n.x, n.z)
		if d > 0.001:
			nn = flat / d
		if nn.length_squared() > 0.0001:
			out += nn.normalized() * maxf(0.0, r - d + 0.05)
			if log_on and wave_t - _solid_log > 1.0:
				_solid_log = wave_t
				_log("solid at %.0f, %.0f (%s)" % [centre.x, centre.z, str(info.get("collider_id", ""))])
	return out


# --- the look -------------------------------------------------------------------------------------------

func _build_materials() -> void:
	for key: String in ["ring", "next", "gold", "finish"]:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var c: Color = {"ring": RING, "next": RING_NEXT, "gold": GOLD, "finish": Color("#f4f2ea")}[key]
		m.albedo_color = c
		_mats[key] = m
	var foam := StandardMaterial3D.new()
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.vertex_color_use_as_albedo = true
	foam.cull_mode = BaseMaterial3D.CULL_DISABLED
	foam.render_priority = 1
	_mats["foam"] = foam


## A ring: an upright half torus standing in the water (the boats go through under its arch),
## orange with white bands and a float at each foot. Width w, tube 0.45 m.
static func ring_mesh(w: float, colour: Color, band: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var big := w * 0.5
	var tube := 0.45 if w < 30.0 else 0.8
	var segs := 18
	var sides := 6
	for i in segs:
		var a0 := PI * float(i) / segs
		var a1 := PI * float(i + 1) / segs
		var c := band if i % 3 == 1 else colour
		for j in sides:
			var b0 := TAU * float(j) / sides
			var b1 := TAU * float(j + 1) / sides
			var q := [_torus(big, tube, a0, b0), _torus(big, tube, a1, b0), _torus(big, tube, a1, b1), _torus(big, tube, a0, b1)]
			var n: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
			for v: Vector3 in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(c)
				st.set_normal(n)
				st.set_uv(Vector2(Models.FIXED, 0.0))
				st.add_vertex(v)
	for s: float in [-1.0, 1.0]:
		Models.box(st, Vector3(s * big, 0.2, 0.0), Vector3(1.6, 0.7, 1.6), colour)
	return st.commit()


static func _torus(big: float, tube: float, a: float, b: float) -> Vector3:
	var centre := Vector3(cos(a) * big, sin(a) * big, 0.0)
	var out := Vector3(cos(a), sin(a), 0.0)
	return centre + out * cos(b) * tube + Vector3(0, 0, 1) * sin(b) * tube


func _build_rings() -> void:
	for g: Dictionary in rings:
		var mi := MeshInstance3D.new()
		var w := float(g["w"])
		if bool(g["finish"]):
			mi.mesh = ring_mesh(w, Color("#f4f2ea"), Color("#c8202c"))
		elif bool(g["gold"]):
			mi.mesh = ring_mesh(w, GOLD, Color("#fff6c8"))
		else:
			mi.mesh = ring_mesh(w, RING, Color("#fff4ea"))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(g["x"]), water_y, float(g["z"]))
		# The ring's plane is across the course: its forward (sin, cos)(yaw) is its normal.
		mi.rotation.y = float(g["yaw"])
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		mi.material_override = m
		mi.visible = false
		add_child(mi)
		_ring_nodes.append(mi)


## The player's next ring bright, the two after it dim, the finish when near; the rest hidden.
func _update_rings() -> void:
	if racers.is_empty():
		return
	var nxt := int(racers[0]["next"])
	var shown := 0
	for i in _ring_nodes.size():
		var mi := _ring_nodes[i]
		var g: Dictionary = rings[i]
		var on: bool = i >= nxt and (shown < 3 or bool(g["finish"]) and boats[0].pos.distance_to(Vector2(float(g["x"]), float(g["z"]))) < 500.0)
		if on and i >= nxt and not bool(g["finish"]):
			shown += 1
		mi.visible = on and state in [State.COUNTDOWN, State.RACE]
		var m := mi.material_override as StandardMaterial3D
		var tint := Color(1, 1, 1) if i == nxt else Color(0.72, 0.72, 0.72)
		if not m.albedo_color.is_equal_approx(tint):
			m.albedo_color = tint


func _build_boats() -> void:
	var mat := Models.material()
	var meshes := [
		Boat.runabout_mesh(PLAYER_PAINT, Color("#f2f2ee"), Color("#ff8a1a"), Color("#3a2a1c"), 0.55),
		Boat.runabout_mesh(Color(RIVALS[0]["paint"]), Color("#a0a4aa"), Color(RIVALS[0]["shirt"]), Color(RIVALS[0]["hair"])),
		Boat.tub_mesh(),
		Boat.jetski_mesh(),
	]
	var kinds := [Boat.Kind.RUNABOUT, RIVALS[0]["kind"], RIVALS[1]["kind"], RIVALS[2]["kind"]]
	for k in 4:
		var b := Boat.new()
		b.name = "Boat%d" % k
		add_child(b)
		b.setup(int(kinds[k]), meshes[k], mat)
		b.water_y = water_y
		b.flow = flow_dir * FLOW
		var kk := k
		b.wave = func(x: float, z: float) -> float: return wave(x, z, kk)
		if map != null:
			b.shore = map.shore_distance
		b.solid = solid_at
		boats.append(b)
		_wakes.append([])
		_wake_t.append(0.0)
	for b: Boat in boats:
		b.others = boats
	_wakes.append([])
	_wakes.append([])
	_wake_t.append(0.0)
	_wake_t.append(0.0)
	player = boats[0]


## The sand barge pushed upstream by its pusher tug (a Vistula sight): 72 m, the heap of sand in
## the hold, the tug's wheelhouse up high at the back.
func _build_barge() -> void:
	var st := Models._begin()
	var hull := Color("#2d3138")
	var rust := Color("#7a3b25")
	var sand := Color("#d9c08a")
	var L := BARGE_LEN
	var W := BARGE_HALF_W * 2.0
	# the barge (front 54 m)
	Models.box(st, Vector3(0, 0.5, L * 0.5 - 27.0), Vector3(W, 1.8, 54.0), hull)
	Models.box(st, Vector3(0, 0.0, L * 0.5 - 27.0), Vector3(W + 0.1, 0.5, 54.1), rust)
	Models.box(st, Vector3(0, 1.8, L * 0.5 - 27.0), Vector3(W - 1.6, 1.4, 48.0), sand)
	Models.box(st, Vector3(0, 2.6, L * 0.5 - 27.0), Vector3(W - 4.0, 0.8, 36.0), sand.lightened(0.08))
	# the pusher tug (back 16 m)
	Models.box(st, Vector3(0, 0.6, -L * 0.5 + 8.0), Vector3(W - 1.0, 2.0, 16.0), Color("#1d4b7a"))
	Models.box(st, Vector3(0, 2.6, -L * 0.5 + 7.0), Vector3(W - 4.0, 2.2, 7.0), Color("#efeee8"))
	Models.box(st, Vector3(0, 5.0, -L * 0.5 + 7.5), Vector3(W - 5.0, 2.4, 4.0), Color("#efeee8"))
	Models.box(st, Vector3(0, 5.3, -L * 0.5 + 9.55), Vector3(W - 5.2, 0.8, 0.08), Boat.GLASS)
	Models.box(st, Vector3(0, 6.6, -L * 0.5 + 7.5), Vector3(W - 4.6, 0.25, 4.6), Color("#1d4b7a"))
	Models.box(st, Vector3(1.6, 7.6, -L * 0.5 + 6.0), Vector3(0.5, 2.0, 0.5), Color("#c8202c"))
	Models.box(st, Vector3(0, 0.5, L * 0.5 - 0.5), Vector3(W, 2.2, 1.0), Color("#f2c230"))
	_barge = MeshInstance3D.new()
	_barge.mesh = st.commit()
	_barge.material_override = Models.material()
	_barge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_barge.visible = false
	add_child(_barge)


## The start pontoon at the mouth of Port Czerniakowski: a floating deck on pontoon floats, a
## gangway to the bank, bollards, the race's flags and a banner "WIŚLANA SZPROTKA · START".
func _build_pontoon(world: Node3D) -> void:
	var st := Models._begin()
	var a: Vector2 = PONTOON[0]
	var b: Vector2 = PONTOON[1]
	var mid := (a + b) * 0.5
	var along := (b - a)
	var length := along.length()
	var dir := along / length
	var yaw := atan2(dir.x, dir.y)
	var deck := Color("#8a6a48")
	var float_c := Color("#3a3d44")
	var gy: float = water_y
	# Local frame: +Z along the pontoon (bank to river), x across.
	Models.box(st, Vector3(0, 0.55, 0), Vector3(3.2, 0.18, length), deck)
	for z in range(int(-length * 0.5) + 2, int(length * 0.5), 4):
		Models.box(st, Vector3(-1.2, 0.2, float(z)), Vector3(0.8, 0.6, 3.2), float_c)
		Models.box(st, Vector3(1.2, 0.2, float(z)), Vector3(0.8, 0.6, 3.2), float_c)
	# bollards and the railing on the river end
	for z: float in [-length * 0.5 + 3.0, 0.0, length * 0.5 - 1.0]:
		for x: float in [-1.45, 1.45]:
			Models.box(st, Vector3(x, 0.85, z), Vector3(0.25, 0.4, 0.25), Color("#26282b"))
	# the flag masts: blue and white race flags
	for k in 4:
		var z := -length * 0.5 + 6.0 + float(k) * (length - 8.0) / 3.0
		Models.box(st, Vector3(1.5, 3.0, z), Vector3(0.08, 4.8, 0.08), Color("#d8d8d2"))
		Models.box(st, Vector3(1.5, 5.0, z + 0.55), Vector3(0.04, 0.8, 1.0), COLOUR if k % 2 == 0 else Color("#f4f2ea"))
	# the banner arch over the river end
	var e := length * 0.5 - 2.0
	Models.box(st, Vector3(-1.5, 2.4, e), Vector3(0.18, 3.6, 0.18), Color("#d8d8d2"))
	Models.box(st, Vector3(1.5, 2.4, e), Vector3(0.18, 3.6, 0.18), Color("#d8d8d2"))
	Models.box(st, Vector3(0, 4.0, e), Vector3(3.6, 0.9, 0.12), COLOUR)
	Boat._part = Models.FIXED
	Boat._glow = 0.0
	# The gangway: from the deck's bank end up to the top of the bank (found along the pontoon's
	# line, where the water ends), a sloped plank with a rail on each side.
	var edge := a
	if map != null:
		for k in 40:
			edge = a - dir * float(k)
			if map.shore_distance(edge.x, edge.y) <= 0.0:
				break
	var reach := (a - edge).length() + 1.5
	var bank_y: float = map.ground_height(edge.x - dir.x * 1.5, edge.y - dir.y * 1.5) if map != null else gy + 1.0
	var top := Vector3(0, clampf(bank_y - gy, 0.3, 4.0) + 0.05, -length * 0.5 - reach)
	var foot := Vector3(0, 0.66, -length * 0.5)
	for s2: float in [-1.0, 1.0]:
		Boat._quad(st, foot + Vector3(-0.7, 0, 0), foot + Vector3(0.7, 0, 0), top + Vector3(0.7, 0, 0), top + Vector3(-0.7, 0, 0), deck.darkened(0.15), s2)
		Boat._quad(st, foot + Vector3(s2 * 0.7, 0, 0), top + Vector3(s2 * 0.7, 0, 0), top + Vector3(s2 * 0.7, 0.9, 0), foot + Vector3(s2 * 0.7, 0.9, 0), Color("#26282b"), 1.0)
	var mesh := st.commit()
	_pontoon = MeshInstance3D.new()
	_pontoon.mesh = mesh
	_pontoon.material_override = Models.material()
	_pontoon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pontoon.position = Vector3(mid.x, gy, mid.y)
	_pontoon.rotation.y = yaw
	world.add_child(_pontoon)


## The foam: every wake ring as two arcs (the V behind the boat), white fading with age; a short
## spray strip behind each fast boat.
func _draw_foam() -> void:
	_foam_mesh.clear_surfaces()
	var any := false
	var y := water_y + 0.12
	for s in _wakes.size():
		for w: Array in _wakes[s]:
			var age: float = wave_t - float(w[1])
			if age > WAKE_LIFE:
				continue
			if not any:
				_foam_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				any = true
			var p: Vector2 = w[0]
			var r := 2.0 + age * WAKE_SPREAD
			var alpha := clampf(float(w[2]) * 1.6, 0.15, 0.85) * (1.0 - age / WAKE_LIFE)
			var c := Color(0.95, 0.97, 1.0, alpha)
			var thick := 0.3 + float(w[2]) * 0.5
			var back: float = w[3]
			# The two arms of the V behind the boat (the Kelvin wake's look), a gap down the middle.
			for side: float in [-1.0, 1.0]:
				for k in 4:
					var a0: float = back + side * deg_to_rad(18.0 + 13.0 * k)
					var a1: float = back + side * deg_to_rad(18.0 + 13.0 * (k + 1))
					var i0 := Vector3(p.x + cos(a0) * (r - thick), y, p.y + sin(a0) * (r - thick))
					var o0 := Vector3(p.x + cos(a0) * (r + thick), y, p.y + sin(a0) * (r + thick))
					var i1 := Vector3(p.x + cos(a1) * (r - thick), y, p.y + sin(a1) * (r - thick))
					var o1 := Vector3(p.x + cos(a1) * (r + thick), y, p.y + sin(a1) * (r + thick))
					for v: Vector3 in [i0, o0, o1, i0, o1, i1]:
						_foam_mesh.surface_set_color(c)
						_foam_mesh.surface_add_vertex(v)
	if any:
		_foam_mesh.surface_end()


func _show_race(on: bool) -> void:
	for b: Boat in boats:
		b.visible = on
	if not on:
		for mi in _ring_nodes:
			mi.visible = false
		_barge.visible = false
		_foam_mesh.clear_surfaces()
		if hud != null:
			hud.set_minimap_dots(PackedVector2Array(), PackedColorArray())


func _log(s: String) -> void:
	if log_on:
		print("boat race: ", s)
