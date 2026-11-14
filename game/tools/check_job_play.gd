extends SceneTree
## The deliveries on the activity kit (scripts/jobs.gd, tech-debt TD-1), played headless: the real
## Jobs on the committed map (map/centrum.json: its lane graph, its kebab places, its station, its
## address doors) and the shared stand-ins of tools/fakes.gd (a HUD, a dialogue, a wallet, the
## rescue calls, the bubbles) and a few of its own (a map of formulas whose heights never agree, a
## car, a ghost driver in traffic, the other jobs the director knows). A fixed seed. Deliveries
## that are driven by hand run without an await (a frame is a call); the autopilot's run over the
## engine's own frames (`--fixed-fps 60`: its `drive_player` reads the frame's delta). Numbers and
## words are literals here; the places, the doors and the roads are never pinned: every fact is a
## rule worked out from the map's data and from the order as it said itself when it went up
## (`q._order`, read once), so a road fix that re-bakes the map does not break it.
## It states, per fact, what the deliveries did before the kit and must still do:
##   A. the settings and what `setup` builds (addresses, stands and their rings, the Zagłębie's
##   five, the stations, the courier child);  B. idle: the squares, what holds the places back, the
##   pull-in, the wait after NOT NOW, no address in reach, the welcome;  C. the kebab order: the
##   card, the vendor and the line, the order against the map, the count-down, GO, NOT NOW, the
##   keys;  D. the drive: the ring, the route, the status line, the heat and its words, the door;
##   E. the result cards, the pay, the record, OK, NASTĘPNE and the pointer, the 12 s and the 25 m,
##   the dropped order;  F. the craft kebab, the Zagłębie's shops and the trail;  G. the słoiki run
##   and its jars;  I. the director and the other jobs, a card of somebody else's;  J. the names
##   and the test flags;  H. the courier's race beside an order, where the two scripts meet (the
##   challenge, L and the button, the win and the loss, what ends it, the night's roll, the
##   autopilot taking it after its second; the race's own rules are check_side_jobs' and
##   check_couriers');  K. the autopilot, frame by frame;
##   L. the least the game hands in;  M. what deliberate breaks of the script showed;  N. what 138 more
##   breaks showed: the kerb asked straight, the orders made straight, the first order's reach, the jars'
##   thresholds, the passenger's chat, the minimap's places and route, an order over the river, the
##   autopilot's ends.
## Prints "check_job_play: OK (N checks in F frames; notes)" or one "  problem: ..." line per failed fact under
## "check_job_play: PROBLEMS" (exit 1).
##   godot --headless --fixed-fps 60 --path game --script res://tools/check_job_play.gd

const Jobs := preload("res://scripts/jobs.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Zaglebie := preload("res://scripts/zaglebie.gd")
const CourierRace := preload("res://scripts/courier_race.gd")
const RouteLine := preload("res://scripts/route_line.gd")
const DT := 1.0 / 60.0
const SEED := 20261113
const FAR := Vector2(99000.0, 99000.0)
const ORANGE := Color("#ff8a3d")
const TEAL := Color("#4fd8c4")
const RED := Color("#e2574c")
const ICE := Color("#7fb8de")
const AMBER := Color("#ffb05a")
const BOAT := Color("#1f4fa8")
const NAMES := ["Ania", "Kasia", "Ola", "Magda", "Zosia", "Ewa", "Basia", "Marta", "Tomek", "Kuba", "Piotrek", "Michał", "Paweł",
		"Marek", "Wojtek", "Krzysiek"]
const NEWCOMERS := ["Kuba", "Ola", "Bartek", "Kasia", "Michał", "Magda"]
const ZAGS := ["zag_krol", "zag_stambul", "zag_pasza", "zag_erdal", "zag_rozen"]
const BOARDS := ["KRÓL MAZOWSZA", "STAMBUŁ 24", "DONER PASZA", "U WUJKA ERDALA", "ZAKWAS I ROŻEN"]
const GATES := ["flying", "a questline", "a rescue", "a ride", "the trend job", "the round-up", "a race", "a card"]


# --- the stand-ins that are this check's own ----------------------------------------------------------

## dialogue.gd's `say` answers with the bubble's words (`say_words`; `[]`: no line in the bag).
class PlayDialogue extends Fakes.Dialogue:
	func _init() -> void:
		say_words = ["Słowo", "A word"]


## missions.gd's side: whether a rescue has a target.
class PlayCalls extends Fakes.Calls:
	var target := false
	func has_target() -> bool:
		return target


class PlayRivals extends Node:
	var on := false
	func busy() -> bool:
		return on


class PlayTod extends Node:
	var mode := 0


## city_life.gd's side: the couriers waiting by each stand.
class PlayLife extends Node:
	var waiting := {}
	var taken: Array = []
	func waiting_at(i: int) -> Array:
		return (waiting.get(i, []) as Array).duplicate()
	func take_waiting(i: int) -> Array:
		taken.append(i)
		var w: Array = waiting.get(i, [])
		return w.pop_back() if not w.is_empty() else []


class PlayCar extends CharacterBody3D:
	signal bumped(collider: Object, speed: float)
	var vel := Vector3.ZERO
	var forward_speed := 0.0
	var throttle := 0.0
	var braking := false
	var target_dir := Vector3.ZERO
	var flashes := 0
	func flash_lights() -> void:
		flashes += 1


## The map as the jobs and the lane graph ask it: three heights that never agree (one taken from
## the wrong place shows), roofs in patches (a kerb's spot under one is no spot).
class CityMap extends Fakes.FlatMap:
	func terrain_height(x: float, z: float) -> float:
		return 3.0 + 0.0007 * x - 0.0003 * z
	func ground_height(x: float, z: float) -> float:
		return 2.0 + 0.001 * x + 0.0005 * z
	func deck_height(g: int, x: float, z: float) -> float:
		return terrain_height(x, z) if g < 0 else 9.0 + 0.0002 * x + 0.0001 * z
	func tunnel_height(_t: int, x: float, z: float) -> float:
		return -4.0 + 0.0011 * x - 0.0007 * z
	func roof_height(_x: float, _z: float) -> float:
		return -INF
	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false
	## A roof the check switches on: a Callable taking the point (Vector2) and answering whether a roof is over it.
	var roof := Callable()
	func top_height(x: float, z: float, _r := 0.0) -> float:
		var t := terrain_height(x, z) + (12.0 if sin(x * 0.05) * cos(z * 0.045) > 0.92 else 0.0)
		if roof.is_valid() and bool(roof.call(Vector2(x, z))):
			t += 20.0
		return t


## The autopilot's invisible driver, as far as jobs.gd reads and sets it.
class Ghost:
	var pos := Vector3.ZERO
	var yaw := 0.0
	var v := 0.0
	var arrived := false
	var speed_factor := 1.0
	var accel_factor := 1.0
	var finish := -1
	var squeeze := 0.0


## traffic.gd's side: a ghost goes straight for its junction (14 m/s times its factor), or stands
## in a jam until it is told to squeeze by.
class PlayTraffic extends Node3D:
	var graph: LaneGraph
	var ghosts: Array = []
	var added := 0
	var removed := 0
	var races: Array = []
	var jam := false
	func add_ghost(e: int, lane: int, s: float) -> Ghost:
		var g := Ghost.new()
		var p := graph.point_at(e, s, graph.lane_offset(e, lane))
		g.pos = Vector3(p.x, graph.surface(e, p), p.y)
		ghosts.append(g)
		added += 1
		return g
	func race_to(d: Ghost, finish: int, dist: PackedFloat32Array, _plan: Variant = null) -> void:
		d.finish = finish
		races.append([finish, d.speed_factor, d.accel_factor, dist.size()])
	func remove(d: Ghost) -> void:
		ghosts.erase(d)
		removed += 1
	func step(dt: float) -> void:
		for g: Ghost in ghosts:
			if g.finish < 0 or g.arrived:
				continue
			if jam and g.squeeze <= 0.0:
				g.v = 0.0
				continue
			var t: Vector2 = graph.node_pos[g.finish]
			var to := Vector2(t.x - g.pos.x, t.y - g.pos.z)
			var d := to.length()
			var sp := 14.0 * g.speed_factor
			if jam:
				sp = minf(g.v + 0.2, sp)
			if d < 2.0:
				g.arrived = true
				g.v = 0.0
				continue
			var m := minf(d, sp * dt)
			g.pos += Vector3(to.x, 0.0, to.y) / d * m
			g.yaw = atan2(-to.x, -to.y)
			g.v = sp


## Another side job as jobs.gd and the director see it (the ride, the trend job, the round-up).
class Other extends Activity:
	const COLOUR := Color("#e8c547")
	var who := ""
	var on := false
	var offer := false
	var takes_m := false
	var takes_k := false
	var keys: Array = []
	var _shown := false
	var depots := PackedVector2Array()
	func busy() -> bool:
		return on
	func idle() -> bool:
		return not on and not offer
	func offering() -> bool:
		return offer
	func primary() -> bool:
		if takes_m:
			keys.append("M")
		return takes_m
	func secondary() -> bool:
		if takes_k:
			keys.append("K")
		return takes_k
	func depot_points() -> PackedVector2Array:
		return depots


class Rig:
	var q: Node
	var full := true
	var world: Node3D
	var aside: Node3D
	var hud: Fakes.Hud
	var bubbles: Fakes.Bubbles
	var dialogue: PlayDialogue
	var wallet: Fakes.Wallet
	var missions: PlayCalls
	var rivals: PlayRivals
	var car: PlayCar
	var tod: PlayTod
	var traffic: PlayTraffic
	var life: PlayLife
	var rides: Other
	var trend: Other
	var round: Other
	var director: Activities
	var jars: Array = []


var _data: Dictionary
var _map: CityMap
var _graph: LaneGraph
var r: Rig
var _car := Vector3(FAR.x, 0.0, FAR.y)
var _vel := Vector3.ZERO
var _fwd := 0.0
var _yaw := 0.0
var _fly := false
var _mission := false
var _frames := 0
var _checks := 0
var _problems: Array[String] = []
var _notes: Array[String] = []
var _auto := false


func _initialize() -> void:
	_go.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_problems.append(what)


func _near(a: float, b: float, eps: float, what: String) -> void:
	_ok(absf(a - b) <= eps, "%s: %s, wanted %s" % [what, a, b])


func _go() -> void:
	await process_frame
	await process_frame
	var dt := root.get_process_delta_time()
	if not is_equal_approx(dt, DT):
		print("check_job_play: PROBLEMS\n  problem: the engine's frame is %.5f s, run with --fixed-fps 60" % dt)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not parsed is Dictionary:
		print("check_job_play: PROBLEMS\n  problem: no map/centrum.json")
		quit(1)
		return
	_data = parsed
	_map = CityMap.new()
	root.add_child(_map)
	_graph = LaneGraph.new(_data["graph"], _map)
	_s_a_setup()
	_s_b_idle()
	_s_c_order()
	_s_d_drive()
	_s_e_results()
	_s_f_zag()
	_s_g_sloik()
	_s_i_hub()
	_s_j_names()
	_s_l_bare()
	_s_m_more()
	_s_h_courier()
	_s_n_orders()
	_s_n_first()
	_s_n_jars()
	_s_n_places()
	_s_n_sloik()
	_s_n_cards()
	_s_n_routes()
	_s_n_river()
	_s_n_book()
	await _s_k_auto()
	await _s_n_auto()

	if r != null:
		_settle()
	print("check_job_play: %s" % ("OK (%d checks in %d frames; %s)" % [_checks, _frames, "; ".join(_notes)] if _problems.is_empty() else "PROBLEMS"))
	for p in _problems:
		print("  problem: " + p)
	quit(0 if _problems.is_empty() else 1)


# --- the rig ------------------------------------------------------------------------------------------

## The job as main.gd makes it (the test flags first, then the members, `add_child`, `setup`), with the
## director as main.gd fills it. `full`: rivals, the clock, the other jobs and the city life are there.
func _rig(full := true, kept := {}, opts := {}) -> Rig:
	if r != null:
		_settle()
		r.aside.free()
		r.world.free()
	var s := Rig.new()
	s.full = full
	s.world = Node3D.new()
	root.add_child(s.world)
	s.aside = Node3D.new()
	root.add_child(s.aside)
	s.hud = Fakes.Hud.new()
	s.bubbles = Fakes.Bubbles.new()
	s.dialogue = PlayDialogue.new()
	s.dialogue.line_words = ["Komentarz", "A comment"]
	s.wallet = Fakes.Wallet.new()
	s.wallet.money = 100
	s.wallet.keep = kept.duplicate(true)
	s.missions = PlayCalls.new()
	s.rivals = PlayRivals.new()
	s.car = PlayCar.new()
	s.tod = PlayTod.new()
	s.traffic = PlayTraffic.new()
	s.traffic.graph = _graph
	s.life = PlayLife.new()
	s.rides = Other.new()
	s.rides.who = "rides"
	s.trend = Other.new()
	s.trend.who = "trend"
	s.round = Other.new()
	s.round.who = "round"
	for nd: Node in [s.hud, s.bubbles, s.dialogue, s.wallet, s.missions, s.rivals, s.car, s.tod, s.traffic, s.life, s.rides, s.trend, s.round]:
		s.aside.add_child(nd)
		if nd is Other:
			(nd as Other).is_job = true
			nd.set_process(false)
	_car = Vector3(FAR.x, 0.0, FAR.y)
	_vel = Vector3.ZERO
	_fwd = 0.0
	_yaw = 0.0
	_fly = false
	_mission = false
	s.car.global_position = _car
	var q: Node = Jobs.new()
	q.autopilot = bool(opts.get("autopilot", false))
	q.craft_plain = bool(opts.get("craft_plain", false))
	if opts.has("start_heat"):
		q.start_heat = float(opts["start_heat"])
	s.aside.add_child(q)
	s.q = q
	q.hud = s.hud
	q.bubbles = s.bubbles
	q.dialogue = s.dialogue
	q.wallet = s.wallet
	q.missions = s.missions
	q.rivals = s.rivals if full else null
	q.graph = _graph
	q.traffic = s.traffic
	q.map = _map
	q.car = s.car
	q.tod = s.tod if full else null
	q.map_data = opts.get("data", _data)
	if opts.has("boat"):
		q.boat_spot = opts["boat"]
	q.setup(s.world)
	s.director = Activities.new()
	s.director.add(s.rides, func() -> bool: return true) if full else null
	s.director.add(q, func() -> bool: return true)
	if full:
		s.director.add(s.round, func() -> bool: return bool(q._free()) and not bool(q.own_busy()))
		s.director.add(s.trend, func() -> bool: return true)
		q.rides = s.rides
		q.trend = s.trend
		q.roundup = s.round
		q.others_busy = func() -> bool: return _mission
		q.courier.life = s.life
	q.set_process(false)
	q.set_physics_process(false)
	q._rng.seed = SEED
	q.jars.connect(func(kind: int) -> void: s.jars.append(kind))
	r = s
	return s


## The courier's way is worked out on another thread: wait for it before a frame goes on.
func _settle() -> void:
	var c: Node = r.q.courier
	if c != null and int(c._task) >= 0:
		var waited := 0
		while not WorkerThreadPool.is_task_completed(int(c._task)) and waited < 20000:
			OS.delay_msec(1)
			waited += 1


## A frame by hand, as main.gd hands things in before the job's own frame.
func _f(n := 1) -> void:
	for i in n:
		_settle()
		r.car.global_position = _car
		r.car.rotation.y = _yaw
		r.car.vel = _vel
		r.car.velocity = _vel
		r.car.forward_speed = _fwd
		r.q.flying = _fly
		r.q._physics_process(DT)
		r.q._process(DT)
		_frames += 1


## A frame on the autopilot (main.gd `_autopilot` before the job's frame), over the engine's frames.
func _af(n := 1) -> void:
	for i in n:
		_settle()
		r.traffic.step(DT)
		r.car.throttle = 0.7
		r.car.braking = true
		r.car.target_dir = Vector3(0.0, 0.0, -1.0)
		var t: Activity = r.director.targeted()
		if t != null:
			t.drive_player()
		r.car.velocity = r.car.vel
		r.q.flying = _fly
		r.q._physics_process(DT)
		r.q._process(DT)
		_frames += 1
		await process_frame


func _at(p: Vector2, speed := 0.0, yaw := 0.0) -> void:
	_car = Vector3(p.x, _map.ground_height(p.x, p.y), p.y)
	_yaw = yaw
	_fwd = speed
	_vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed


## The car `d` m east of the place `p`.
func _by(p: Vector3, d: float, speed := 0.0) -> void:
	_at(Vector2(p.x + d, p.z), speed)


## The play's car where the script put its own (a test flag's teleport).
func _sync() -> void:
	_car = r.car.global_position
	_yaw = r.car.rotation.y
	_vel = Vector3.ZERO
	_fwd = 0.0


func _stage() -> int:
	return int(r.q.stage)


func _ordr() -> Dictionary:
	return (r.q._order as Dictionary).duplicate(true)


func _ring_of(o: Dictionary) -> Vector3:
	return o["ring"]


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _stand(i: int) -> Dictionary:
	return r.q._stands[i]


func _zag(tag: String) -> int:
	for i in r.q._stands.size():
		if str(_stand(i)["zag"]) == tag:
			return i
	return -1


func _ct(seconds: float) -> String:
	var tenths := maxi(0, int(seconds * 10.0))
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


func _zl(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out + " zł"


## A stand of no craft and no shop whose ring has no other ring or station within 25 m.
func _lone_stand() -> int:
	for i in r.q._stands.size():
		var st := _stand(i)
		if str(st["zag"]) != "":
			continue
		var fine := true
		for j in r.q._stands.size():
			if j != i and _flat(st["ring"], _stand(j)["ring"]) < 25.0:
				fine = false
		for st2 in r.q._stations:
			if _flat(st["ring"], st2["ring"]) < 25.0:
				fine = false
		if fine:
			return i
	return 0


func _lone_station(k: int) -> int:
	var seen := 0
	for i in r.q._stations.size():
		var fine := true
		for st in r.q._stands:
			if _flat(r.q._stations[i]["ring"], st["ring"]) < 25.0:
				fine = false
		if fine:
			if seen == k:
				return i
			seen += 1
	return clampi(k, 0, r.q._stations.size() - 1)


## Turns the order that is up down (the craft kebab's card has no NOT NOW: its plain kebab goes, the
## ✕ drops it and OK closes the card).
func _turn_down() -> void:
	if _stage() != 1:
		return
	if bool(r.q._order.get("craft", false)):
		if r.hud.card == "":
			r.director.secondary()
		else:
			r.hud.press(1)
		r.hud.abort_pressed.emit()
		r.hud.press(0)
	else:
		r.hud.press(1)
	_f()


## The first order from `from` on that `fits` (the others are turned down); -1 and one problem when none in 200.
func _find(from: int, fits: Callable, why: String, step := 1) -> int:
	for k in 200:
		var n := from + k * step
		r.q.start_kebab(n)
		if _stage() == 0:
			continue
		_sync()
		if fits.call(r.q._order):
			return n
		_turn_down()
	_problems.append("no order from %d on fits: %s (stage %d, last order %s)" % [from, why, _stage(), str(r.q._order.get("zag", "")) + "/" + str(r.q._order.get("across", ""))])
	return -1


func _plain(o: Dictionary) -> bool:
	return str(o["zag"]) == "" and not bool(o.get("craft", false))


func _plain_day() -> Callable:
	return func(o: Dictionary) -> bool: return _plain(o) and not bool(o["across"]) and not bool(o["office"])


## A plain order of a plain stand by day, the card up, the car in the ring (stage 1, `_t` 0).
func _order_up(from := 0) -> Dictionary:
	_find(from, _plain_day(), "a plain order")
	return _ordr()


func _press(i: int) -> void:
	r.hud.press(i)


## GO, the drive far from the door: the car 300 m east of the ring at 10 m/s for `frames`.
func _drive_far(frames: int, speed := 10.0) -> void:
	var ring: Vector3 = r.q._order["ring"]
	_by(ring, 300.0, speed)
	_f(frames)


func _arrive_now() -> void:
	var ring: Vector3 = r.q._order["ring"]
	_at(Vector2(ring.x, ring.z))
	_f()


## A whole delivery of the order that is up (GO, `way` frames on the road, the door); what it paid.
func _deliver(way := 60) -> Dictionary:
	var money0: int = r.wallet.money
	var resp0: int = r.wallet.respect
	_press(0)
	_drive_far(way)
	_arrive_now()
	return {"o": _ordr(), "h": float(r.q._heat), "clock": float(r.q._clock), "money": r.wallet.money - money0,
			"respect": r.wallet.respect - resp0, "stage": _stage()}


func _close_result() -> void:
	_press(0)
	_at(FAR)
	_f(2)


func _look(b: Node3D) -> Array:
	if b == null or not b.visible:
		return [false]
	return [true, b._ring_radius, b._colour, b._ring.visible, b._column.visible, b._person.visible, b.waving]


func _count(arr: Array, what: String) -> int:
	var n := 0
	for s in arr:
		if str(s) == what:
			n += 1
	return n


func _last_said(group_tag: String) -> int:
	for i in range(r.dialogue.said.size() - 1, -1, -1):
		if r.dialogue.said[i] == group_tag:
			return i
	return -1


func _last_ask(group_tag: String) -> int:
	for i in range(r.dialogue.line_asks.size() - 1, -1, -1):
		if r.dialogue.line_asks[i] == group_tag:
			return i
	return -1


func _extras(o: Dictionary, night: bool) -> Array:
	var across := bool(o["across"])
	return [" Za rzeką: „w sumie to centrum”." if across else "", " Across the river (\"basically the centre\")." if across else "",
			" Nocą ×1,5." if night else "", " Night pays ×1.5." if night else ""]


## The kebab card's body as the rules word it, both languages.
func _plain_body(o: Dictionary, night: bool, zag_words := "") -> Array:
	var x := _extras(o, night)
	return ["Dla: %s, %s.%s Im cieplejszy dojedzie, tym większy napiwek.%s%s" % [o["customer"], o["name"], x[0], x[2], zag_words],
			"It cools on the way: the hotter, the bigger the tip.%s%s" % [x[1], x[3]]]


# --- A. what setup builds -----------------------------------------------------------------------------

func _s_a_setup() -> void:
	_rig()
	var q: Node = r.q
	_ok(q.tag == "jobs" and q.colour == ORANGE and q.dark == Color("#2f6fb5"), "A: tag, colour, dark")
	_ok(q.is_job and q.cards_low and not q.cards_hold and not q.flown, "A: is_job, cards_low, not cards_hold, not flown")
	_ok(q.play_limit == 0.0 and int(q.phase) == Activity.Phase.IDLE and _stage() == 0 and int(q.job) == 0, "A: play_limit, phase, stage, job")
	_ok(q.idle() and not q.busy() and not q.has_target() and not q.pointing() and q.stop_spot() == Vector3.INF, "A: idle, no target")
	_ok(q.grounded() == [] and q.target_arrow() and q.target_label(123) == "123 m" and q._auto_button() == -1, "A: grounded, arrow, label, auto button")
	_ok(q._beacon != null and not q._beacon.visible and q.map_data == {}, "A: the kit's ring is made and hidden, map_data cleared")
	_ok(int(Jobs.Stage.ORDER) == 1 and int(Jobs.Stage.DELIVER) == 2 and int(Jobs.Stage.RESULT) == 3, "A: the stages' numbers")
	_ok(q.heat() == 1.0 and q.orders_started() == 0, "A: heat and orders at the start")
	# the addresses, one for every address poi, in the map's order
	var pois: Array = _data["pois"]
	var addr: Array = []
	var kebabs: Array = []
	var stations: Array = []
	for p: Dictionary in pois:
		match str(p["k"]):
			"address":
				addr.append(p)
			"kebab":
				kebabs.append(p)
			"station":
				stations.append(p)
	var qa: Array = q._addresses
	_ok(qa.size() == addr.size(), "A: one address per address poi (%d / %d)" % [qa.size(), addr.size()])
	var bad := 0
	for i in mini(qa.size(), addr.size()):
		var p: Dictionary = addr[i]
		var door: Array = p["door"]
		if qa[i]["name"] != p["name"] or qa[i]["door"] != Vector2(door[0], door[1]) or qa[i]["at"] != Vector2(p["x"], p["z"]) \
				or bool(qa[i]["office"]) != p.has("o") or qa[i]["d"] != str(p.get("d", "")):
			bad += 1
	_ok(bad == 0, "A: %d addresses differ from their pois" % bad)
	# the stands, each against the map by the check's own arithmetic
	var plain_stands: Array = []
	var zag_stands: Array = []
	for i in q._stands.size():
		(zag_stands if str(_stand(i)["zag"]) != "" else plain_stands).append(i)
	var j := 0
	var no_stand := 0
	var road_unlike := 0
	for p: Dictionary in kebabs:
		if j >= plain_stands.size():
			no_stand += 1
			continue
		var st := _stand(plain_stands[j])
		var door: Array = p["door"]
		var edge: int = st["edge"]
		var centre := _graph.point_at(edge, float(st["s"]))
		if centre.distance_to(Vector2(door[0], door[1])) > 70.0:
			no_stand += 1  # this poi has no stand: the next stand is the next poi's
			continue
		j += 1
		_stand_facts(st, p, centre)
		var ringp := Vector2(st["ring"].x, st["ring"].z)
		if absf(float(st["ring"].y) - _map.terrain_height(ringp.x, ringp.y)) > 0.005:
			road_unlike += 1
	_ok(j == plain_stands.size(), "A: every stand belongs to a kebab poi in order (%d of %d)" % [j, plain_stands.size()])
	_notes.append("%d stands of %d kebab pois (%d without room), road height unlike the terrain's at %d" % [q._stands.size(), kebabs.size(),
			no_stand, road_unlike])
	if road_unlike == 0:
		_notes.append("the road's height is the terrain's at every ground stand (only decks differ)")
	# the Zagłębie's five
	var named := 0
	for i in zag_stands.size():
		var st := _stand(zag_stands[i])
		if str(st["zag"]) in ZAGS:
			named += 1
			var k := ZAGS.find(str(st["zag"]))
			_ok(st["name"] == BOARDS[k] and str(st["tag"]) != "", "A: %s wears its board and tag (%s)" % [st["zag"], st["name"]])
			_ok((st["node"] as Node3D).get_node_or_null("NamedStand") != null, "A: %s has a NamedStand mesh" % st["zag"])
	_ok(named == 5, "A: the Zagłębie's five stands (%d)" % named)
	for i in plain_stands:
		_ok(_stand(i)["name"] == "" and _stand(i)["tag"] == "", "A: stand %d unnamed" % i)
	var inst := 0
	var tiles := 0
	for c in r.world.get_children():
		if c is MultiMeshInstance3D and not c.is_queued_for_deletion():
			tiles += 1
			inst += (c as MultiMeshInstance3D).multimesh.instance_count
			_ok((c as MultiMeshInstance3D).is_in_group("small_casters"), "A: a stand tile is a small caster")
	_ok(inst == plain_stands.size() and tiles >= 1, "A: the unnamed stands' MultiMeshes hold %d of %d (%d tiles)" % [inst, plain_stands.size(), tiles])
	# the stations
	var ss: Array = q._stations
	_ok(ss.size() == stations.size() + 1, "A: %d stations (the map's, then Gdański)" % ss.size())
	if ss.size() >= 2:
		_ok(ss[0]["name"] == stations[0]["name"] and ss[0]["tag"] == "centralny" and ss[0]["dest_pl"] == "Powiśle" and ss[0]["lo"] == 1000.0 \
				and ss[0]["hi"] == 2400.0, "A: the map's station and its Powiśle flats")
		_ok(ss[1]["name"] == "Dworzec Gdański" and ss[1]["tag"] == "gdanski" and ss[1]["dest_pl"] == "Muranów" and ss[1]["lo"] == 600.0 \
				and ss[1]["hi"] == 2000.0 and ss[1]["box"] == [-2700.0, -2700.0, -1500.0, -1500.0], "A: Gdański and its Muranów flats")
		_ok(Vector2(ss[1]["ring"].x, ss[1]["ring"].z).distance_to(Vector2(-2001.0, -2664.0)) < 60.0, "A: Gdański's ring by its door")
	for st in ss:
		var person: MeshInstance3D = st["person"]
		var d := _flat(person.global_position, st["ring"])
		_ok(d >= 3.2 and d <= 5.0 and person.visible and absf(person.scale.x - 1.35) < 0.001, "A: %s's newcomer %.1f m from the ring" % [st["name"], d])
		_near(person.global_position.y, _map.terrain_height(person.global_position.x, person.global_position.z), 0.01, "A: the newcomer stands on the terrain")
		var ringp := Vector2(st["ring"].x, st["ring"].z)
		_near(st["ring"].y, _graph.surface(int(st["edge"]), ringp), 0.01, "A: the station's ring at the road's height")
		var mi := (st["marker"] as Node3D).get_child(0) as MeshInstance3D
		_ok(mi != null and (mi.material_override as StandardMaterial3D).albedo_color == TEAL, "A: a station's marker is teal")
	# a second Gdański is not made where one stands; a far station poi makes a third
	var extra := _data.duplicate()
	var plist: Array = (_data["pois"] as Array).duplicate()
	plist.append({"k": "station", "name": "Jakiś Gdański", "x": -2008.0, "z": -2700.0, "door": [-2001.0, -2664.0], "w": 10.0})
	extra["pois"] = plist
	_rig(true, {}, {"data": extra})
	_ok(r.q._stations.size() == 2, "A: a station poi at Gdański's door leaves two stations (%d)" % r.q._stations.size())
	var far_door := _far_door(r.q)
	if far_door.is_empty():
		_notes.append("no far station place found")
	else:
		var extra2 := _data.duplicate()
		var plist2: Array = (_data["pois"] as Array).duplicate()
		plist2.append({"k": "station", "name": "Daleka stacja", "x": far_door["at"].x, "z": far_door["at"].y,
				"door": [far_door["door"].x, far_door["door"].y], "w": 10.0})
		extra2["pois"] = plist2
		_rig(true, {}, {"data": extra2})
		_ok(r.q._stations.size() == 3, "A: a station more than 150 m from both makes three (%d)" % r.q._stations.size())
	_rig()
	q = r.q
	# the answers the game asks by index
	var pts: PackedVector2Array = q.stand_points()
	var frames: Array = q.stand_frames()
	var same: bool = pts.size() == q._stands.size() and frames.size() == q._stands.size()
	for i in mini(pts.size(), q._stands.size()):
		same = same and pts[i] == Vector2(_stand(i)["at"].x, _stand(i)["at"].z)
		same = same and frames[i][0] == _stand(i)["at"] and absf(angle_difference(float(frames[i][1]),
				(_stand(i)["xf"] as Transform3D).basis.get_euler().y)) < 0.001
	_ok(same, "A: stand_points and stand_frames are the kiosks in order")
	_ok(q.stand_ring(0) == _stand(0)["ring"] and q.stand_ring(-1) == Vector3.INF and q.stand_ring(q._stands.size()) == Vector3.INF, "A: stand_ring")
	_ok(q.stand_tag(-1) == "" and q.stand_tag(q._stands.size()) == "", "A: stand_tag out of range")
	var nearest := -1
	var best := 120.0
	for i in q._stands.size():
		var d := Vector2(_stand(i)["at"].x, _stand(i)["at"].z).distance_to(Vector2(-1060.0, -230.0))
		if d < best:
			best = d
			nearest = i
	_ok(q.first_stand() == nearest, "A: first_stand is the stand nearest (-1060, -230), within 120 m (%d / %d)" % [q.first_stand(), nearest])
	var offers: Array = q.offer_places()
	_ok(offers.size() == q._stands.size() + q._stations.size(), "A: offer_places has a row per stand and station")
	var rows_ok := true
	for i in mini(offers.size(), q._stands.size()):
		var st := _stand(i)
		var who: String = "Kebab 24h" if st["name"] == "" else String(st["name"]).capitalize()
		rows_ok = rows_ok and offers[i]["group"] == "kebab" and offers[i]["colour"] == ORANGE \
				and offers[i]["name"] == ["Kebab · %s" % who, "Kebab · %s" % who] \
				and offers[i]["at"] == Vector2(st["ring"].x, st["ring"].z)
	for k in q._stations.size():
		var o: Dictionary = offers[q._stands.size() + k]
		var st: Dictionary = q._stations[k]
		rows_ok = rows_ok and o["group"] == "sloik" and o["colour"] == TEAL and o["name"] == ["Słoiki · %s" % st["name"], "Jars · %s" % st["name"]]
	_ok(rows_ok, "A: offer_places rows")
	var c: Node = q.courier
	_ok(c != null and c.get_parent() == q and str(c.name) == "CourierRace" and not c.is_processing() and c.hud == r.hud \
			and c.dialogue == r.dialogue and c.bubbles == r.bubbles and c.wallet == r.wallet and c.map == _map and c.car == r.car \
			and c.graph == _graph and (c.paths as Array).size() == (_data["paths"] as Array).size() and not c.autopilot, "A: the courier child")
	_rig(true, {}, {"autopilot": true})
	_ok(r.q.courier.autopilot, "A: the courier has the autopilot flag")
	_rig()
	_at(FAR)
	r.car.bumped.emit(null, 6.0)
	_f()
	_ok(_stage() == 0 and r.jars.is_empty(), "A: a bump while idle changes nothing")


## One stand against its poi.
func _stand_facts(st: Dictionary, p: Dictionary, centre: Vector2) -> void:
	var at: Vector3 = st["at"]
	var ring: Vector3 = st["ring"]
	var nm := "stand at %d,%d" % [roundi(at.x), roundi(at.z)]
	var half := float(p.get("w", 7.0)) * 0.5
	_near(at.y, _map.terrain_height(at.x, at.z), 0.01, "A: %s's kiosk on the terrain" % nm)
	_ok(_graph.snap(Vector2(at.x, at.z), 3.0).is_empty(), "A: %s's kiosk has a lane within 3 m" % nm)
	_ok(_map.top_height(at.x, at.z, 1.8) <= _map.terrain_height(at.x, at.z) + 0.5, "A: %s's kiosk under a roof" % nm)
	var ringp := Vector2(ring.x, ring.z)
	_near(ringp.distance_to(centre), maxf(half - 2.0, 0.0), 0.01, "A: %s's ring off the lane point" % nm)
	_near(ring.y, _graph.surface(int(st["edge"]), ringp), 0.01, "A: %s's ring at the road's height" % nm)
	var d := _flat(at, ring)
	_ok(d >= 3.59 and d <= 6.41, "A: %s's kiosk %.2f m from the ring" % [nm, d])
	var head: Vector2 = st["heading"]
	_ok(absf(head.length() - 1.0) < 0.001, "A: %s's heading is a unit vector" % nm)
	var kiosk := Vector2(at.x, at.z)
	_ok(Vector2(-head.y, head.x).dot(kiosk - ringp) > 0.0, "A: %s is on the right of its heading" % nm)
	var side := (kiosk - centre).normalized()
	_ok(absf((ringp - centre).cross(kiosk - centre)) < 0.05, "A: %s's ring is on the line from the lane to the kiosk" % nm)
	var xf: Transform3D = st["xf"]
	_ok(xf.origin == at and absf(angle_difference(xf.basis.get_euler().y, atan2(side.x, side.y))) < 0.01, "A: %s's kiosk faces the road" % nm)
	var node: Node3D = st["node"]
	_ok(node.global_position.distance_to(at) < 0.01 and node.get_parent() == r.world, "A: %s's node in the world at the kiosk" % nm)
	var body: StaticBody3D = null
	var halo: MeshInstance3D = null
	for ch in node.get_children():
		if ch is StaticBody3D:
			body = ch
		elif ch is MeshInstance3D and ch.is_in_group("night_lights"):
			halo = ch
	var box_ok := false
	if body != null and body.get_child_count() > 0:
		var sh := (body.get_child(0) as CollisionShape3D)
		box_ok = sh.shape is BoxShape3D and (sh.shape as BoxShape3D).size == Vector3(3.1, 2.6, 2.1) and absf(sh.position.y - 1.3) < 0.001
	_ok(box_ok, "A: %s is solid (a 3.1 x 2.6 x 2.1 box at 1.3 m)" % nm)
	_ok(halo != null and not halo.visible, "A: %s's halo is hidden in night_lights" % nm)
	var mk := (st["marker"] as Node3D)
	_ok(mk.global_position.distance_to(ring) < 0.01 and mk.get_child_count() > 0, "A: %s's marker at the ring" % nm)
	if mk.get_child_count() > 0:
		var mat := (mk.get_child(0) as MeshInstance3D).material_override as StandardMaterial3D
		_ok(mat != null and mat.albedo_color == ORANGE and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "A: %s's marker is unshaded orange" % nm)
	_ok(not bool(st["cool"]), "A: %s is not cool" % nm)
	var near_d := INF
	var near_praga := false
	for a: Dictionary in r.q._addresses:
		var dd := (a["at"] as Vector2).distance_to(ringp)
		if dd < near_d:
			near_d = dd
			near_praga = a["d"] == "praga"
	_ok(bool(st["across"]) == near_praga, "A: %s's across is the nearest address being in Praga" % nm)


## An address door with room for a station, more than 150 m from both stations.
func _far_door(q: Node) -> Dictionary:
	for a: Dictionary in q._addresses:
		var ok := true
		for st in q._stations:
			if Vector2(st["ring"].x, st["ring"].z).distance_to(a["door"]) < 400.0:
				ok = false
		if ok and not _graph.snap(a["door"], 30.0).is_empty():
			return a
	return {}


# --- B. idle: the places and the pull-in ---------------------------------------------------------------

func _s_b_idle() -> void:
	_rig(true, {}, {"boat": Vector2(-500.0, 500.0)})
	var q: Node = r.q
	_f()
	var n_places: int = q._stands.size() + q._stations.size()
	var all_vis := true
	for st in q._stands:
		all_vis = all_vis and (st["marker"] as Node3D).visible
	for st in q._stations:
		all_vis = all_vis and (st["marker"] as Node3D).visible
	_ok(all_vis and r.hud.pois_set == 1, "B: free: every marker visible, the squares set once (%d)" % r.hud.pois_set)
	_ok(r.hud.pois == n_places + 1, "B: the squares: the places and the boat (%d)" % r.hud.pois)
	var ok_sq := r.hud.poi_points.size() == n_places + 1
	for i in q._stands.size():
		if ok_sq:
			ok_sq = ok_sq and r.hud.poi_points[i] == Vector2(_stand(i)["ring"].x, _stand(i)["ring"].z) and r.hud.poi_colours[i] == ORANGE \
					and r.hud.poi_shapes[i] == MapIcons.POI_KEBAB
	for k in q._stations.size():
		if ok_sq:
			var i: int = q._stands.size() + k
			ok_sq = ok_sq and r.hud.poi_colours[i] == TEAL and r.hud.poi_shapes[i] == MapIcons.POI_STATION
	_ok(ok_sq and r.hud.poi_colours[n_places] == BOAT and r.hud.poi_shapes[n_places] == MapIcons.POI_BOAT, "B: the squares' colours and shapes, the boat last")
	r.round._shown = true
	r.round.depots = PackedVector2Array([Vector2(10.0, 10.0), Vector2(20.0, 20.0)])
	q.depots_shown(true)
	_ok(r.hud.pois == n_places + 3 and r.hud.poi_colours[n_places + 1] == Other.COLOUR and r.hud.poi_shapes[n_places + 1] == MapIcons.POI_DEPOT,
			"B: the depots' squares come after the boat's")
	var lez := 0
	for o: Dictionary in q.offer_places():
		if o["group"] == "lezak":
			lez += 1
			_ok(o["name"] == ["Leżaki · zbiórka", "Leżak round-up"], "B: the depot's words")
	_ok(lez == 2, "B: offer_places gains the depots (%d)" % lez)
	r.round._shown = false
	# what holds the places back
	_rig()
	q = r.q
	var i := _lone_stand()
	var ring: Vector3 = _stand(i)["ring"]
	_f()
	for g in GATES:
		_at(FAR)
		_f()
		_gate(g, true)
		_f()
		var any_vis := false
		for st in q._stands:
			any_vis = any_vis or (st["marker"] as Node3D).visible
		for st in q._stations:
			any_vis = any_vis or (st["marker"] as Node3D).visible
		_ok(not any_vis and r.hud.pois == 0, "B: %s takes every marker and the squares down" % g)
		var offers: int = q.offer_places().size()
		var empty_wanted: bool = g in ["a rescue", "a ride", "the trend job", "the round-up", "a race"]
		_ok((offers == 0) == empty_wanted, "B: offer_places under %s has %d rows" % [g, offers])
		_at(Vector2(ring.x, ring.z))
		_f(60)
		_ok(_stage() == 0, "B: no order on a pull-in under %s" % g)
		_at(FAR)
		_gate(g, false)
		_f()
		var back := true
		for st in q._stands:
			back = back and (st["marker"] as Node3D).visible
		_ok(back and r.hud.pois == n_places and q.offer_places().size() == n_places, "B: the places are back after %s" % g)
	# the pull-in
	var orders0: int = q.orders_started()
	_by(ring, 7.1)
	_f(60)
	_ok(_stage() == 0, "B: 7.1 m from the ring: no order in 1 s")
	_at(Vector2(ring.x, ring.z), 8.1)
	_f(60)
	_ok(_stage() == 0, "B: 8.1 m/s in the ring: no order")
	_at(Vector2(ring.x, ring.z), 7.9)
	_f()
	_ok(_stage() == 1 and int(q.job) == 1 and q.orders_started() == orders0 + 1, "B: 7.9 m/s in the ring: an order, number %d" % orders0)
	_ok(int(q._order["n"]) == orders0 and int(q._order["stand"]) == i, "B: the order's number and stand")
	_press(1)
	# the wait after NOT NOW
	_ok(bool(_stand(i)["cool"]) and _stage() == 0, "B: NOT NOW: idle and the stand is cool")
	_at(Vector2(ring.x, ring.z))
	_f(120)
	_ok(_stage() == 0, "B: the car still in the ring gets no second order")
	_by(ring, 24.0)
	_f()
	_ok(bool(_stand(i)["cool"]), "B: 24 m: still cool")
	_by(ring, 26.0)
	_f()
	_ok(not bool(_stand(i)["cool"]), "B: 26 m: not cool")
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(_stage() == 1, "B: back in the ring: an order")
	_press(1)
	# the same at a station
	_rig()
	q = r.q
	var k := _lone_station(0)
	var sring: Vector3 = q._stations[k]["ring"]
	_by(sring, 6.9)
	_f()
	_ok(_stage() == 1 and int(q.job) == 2, "B: 6.9 m from a station's ring: the słoiki run")
	_press(1)
	_ok(bool(q._stations[k]["cool"]), "B: NOT NOW: the station is cool")
	_at(Vector2(sring.x, sring.z))
	_f(120)
	_ok(_stage() == 0, "B: the station: no second run in the ring")
	_by(sring, 24.0)
	_f()
	_ok(bool(q._stations[k]["cool"]), "B: the station: 24 m still cool")
	_by(sring, 26.0)
	_f()
	_ok(not bool(q._stations[k]["cool"]), "B: the station: 26 m not cool")
	_by(sring, 7.1)
	_f(60)
	_ok(_stage() == 0, "B: the station: 7.1 m no run")
	_at(Vector2(sring.x, sring.z), 8.1)
	_f(30)
	_ok(_stage() == 0, "B: the station: 8.1 m/s no run")
	_at(Vector2(sring.x, sring.z), 7.9)
	_f()
	_ok(_stage() == 1, "B: the station: 7.9 m/s a run")
	# no address in reach
	_rig()
	q = r.q
	q._addresses.clear()
	i = _lone_stand()
	ring = _stand(i)["ring"]
	_at(Vector2(ring.x, ring.z))
	var t0 := r.hud.toasts.size()
	_f()
	_ok(_stage() == 0 and r.hud.toasts.size() == t0 + 1 and r.hud.toasts[t0] == "Brak zamówień" and r.hud.toasts_en[t0] == "No orders right now" \
			and bool(_stand(i)["cool"]) and q.orders_started() == 0, "B: no address in reach: the toast, the stand cool, still idle")
	k = _lone_station(0)
	sring = q._stations[k]["ring"]
	_at(Vector2(sring.x, sring.z))
	_f()
	_ok(_stage() == 0 and r.hud.toasts.back() == "Nikt nie potrzebuje podwózki" and r.hud.toasts_en.back() == "Nobody needs a lift right now" \
			and bool(q._stations[k]["cool"]), "B: no address in reach at a station")
	# the Zagłębie's welcome
	_rig()
	q = r.q
	var femina: Vector2 = Zaglebie.femina_at(_data["origin"])
	var spot81 := _clear_spot(femina, 81.0)
	var spot79 := _clear_spot(femina, 79.0)
	_at(spot81)
	t0 = r.hud.toasts.size()
	_f()
	_ok(r.hud.toasts.size() == t0 and not r.wallet.keep.has("zaglebie_seen") and _last_ask("zaglebie:welcome") == -1, "B: 81 m from Kino Femina: nothing")
	_at(spot79)
	_f()
	_ok(_last_ask("zaglebie:welcome") >= 0 and r.hud.toasts.size() == t0 + 1 and r.hud.toasts.back() == "Komentarz" and int(r.wallet.keep.get("zaglebie_seen", 0)) == 1,
			"B: 79 m: the welcome, its words as a toast, the key set")
	_at(spot81)
	_f()
	_at(spot79)
	_f()
	_ok(r.hud.toasts.size() == t0 + 1, "B: the welcome plays once")
	_rig(true, {"zaglebie_seen": 1})
	_at(spot79)
	_f()
	_ok(r.hud.toasts.is_empty() and _last_ask("zaglebie:welcome") == -1, "B: a save that has seen it: no toast, no line asked")
	_rig()
	r.dialogue.no_lines = true
	_at(spot79)
	_f()
	_ok(r.hud.toasts.is_empty() and int(r.wallet.keep.get("zaglebie_seen", 0)) == 1, "B: with no line in the bag: no toast, the key still set")


## A point `d` m from `c` with no ring of the job within 15 m of it.
func _clear_spot(c: Vector2, d: float) -> Vector2:
	for a in 12:
		var p := c + Vector2.from_angle(TAU * a / 12.0) * d
		var fine := true
		for st in r.q._stands:
			fine = fine and Vector2(st["ring"].x, st["ring"].z).distance_to(p) > 15.0
		for st in r.q._stations:
			fine = fine and Vector2(st["ring"].x, st["ring"].z).distance_to(p) > 15.0
		if fine:
			return p
	return c + Vector2(d, 0.0)


func _gate(name: String, on: bool) -> void:
	match name:
		"flying":
			_fly = on
		"a questline":
			_mission = on
		"a rescue":
			r.missions.target = on
		"a ride":
			r.rides.on = on
		"the trend job":
			r.trend.on = on
		"the round-up":
			r.round.on = on
		"a race":
			r.rivals.on = on
		"a card":
			if on:
				r.hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
			else:
				r.hud.hide_card()


# --- C. the kebab order -----------------------------------------------------------------------------------

func _s_c_order() -> void:
	_rig()
	var q: Node = r.q
	r.dialogue.line_words = ["Dwa kebaby", "Two kebabs"]
	r.dialogue.line_notes["kebab_order:office"] = {"customer": "Pan Prezes"}
	var i := _lone_stand()
	var ring: Vector3 = _stand(i)["ring"]
	_at(FAR)
	_f()
	var closed0: int = r.missions.closed
	var pills0: int = r.hud.pills_hidden
	var chal0: int = r.hud.challenges_hidden
	var shown_before: int = r.hud.shown
	_at(Vector2(ring.x, ring.z))
	_f()
	if _stage() != 1:
		_problems.append("C: a pull-in at a plain stand did not start an order")
		return
	var o := _ordr()
	var d := r.director
	_ok(int(q.phase) == Activity.Phase.RUN and int(q.job) == 1 and q.busy() and q.own_busy() and q.side_busy() and d.job_on(), "C: RUN, KEBAB, busy, side job on")
	_ok(d.current() == q and d.busy_tag() == "jobs" and d.targeted() == null and not q.pointing(), "C: the director's current, no target")
	_ok(r.missions.paused and r.missions.closed == closed0 + 1 and r.hud.pills_hidden == pills0 + 1 and r.hud.challenges_hidden == chal0 + 1,
			"C: the rescue calls wait, the pill and challenge go")
	var any_vis := false
	for st in q._stands:
		any_vis = any_vis or (st["marker"] as Node3D).visible
	_ok(not any_vis and r.hud.pois == 0 and r.hud.shown > shown_before, "C: the places go down for a job")
	_card_facts(o, "plain", false)
	# the vendor and the line
	var vi := _last_said("kebab_vendor:")
	_ok(vi >= 0 and r.dialogue.speakers[vi] == "Kebab 24h" and r.dialogue.anchors[vi] == _stand(int(o["stand"]))["node"] \
			and r.dialogue.hows[vi] == [2.4, ORANGE, 5.2, false], "C: the vendor says his line over the stand")
	var la := _last_ask("kebab_order:" + _kind_of(o))
	_ok(la >= 0 and r.dialogue.line_prefers[la] == bool(o["across"]), "C: the order's line asked with its kind, preferred across the river")
	_ok(str(o["customer"]) in NAMES, "C: the customer is one of the sixteen (%s)" % o["customer"])
	_order_vs_map(o, _stand(int(o["stand"])))
	# the line is spoken at 2.6 s, once
	var said0: int = r.bubbles.said.size()
	_f(149)
	_ok(r.bubbles.said.size() == said0, "C: no bubble at 2.5 s")
	_f(10)
	_ok(r.bubbles.said.size() == said0 + 1 and r.bubbles.said.back() == "Dwa kebaby" and r.bubbles.durations.back() == 3.5, "C: the line at 2.6 s, 3.5 s long")
	_f(60)
	_ok(r.bubbles.said.size() == said0 + 1, "C: the line once")
	# the count-down: nine words, once a second
	_rig()
	q = r.q
	var n := _find(0, _plain_day(), "a plain order")
	if n < 0:
		return
	r.hud.buttons_set = 0
	o = _ordr()
	_ok(r.hud.button_words == PackedStringArray(["GO!", "NOT NOW"]), "C: the card's buttons GO! and NOT NOW")
	_f()
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9" and r.hud.button_words_en[0] == "GO! · 9" and r.hud.button_words[1] == "NOT NOW", "C: the first frame reads 9")
	_f(29)
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9", "C: half a second in reads 9")
	for sec in range(1, 9):
		_f(60)
		_ok(r.hud.button_words[0] == "JEDZIEMY! · %d" % (9 - sec) and r.hud.button_words_en[0] == "GO! · %d" % (9 - sec), "C: %d.5 s in reads %d (%s)" % [sec, 9 - sec, r.hud.button_words[0]])
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	r.hud.buttons_set = 0
	_f(534)
	_ok(_stage() == 1 and r.hud.buttons_set == 9, "C: still the order at 8.9 s, the words set nine times (%d)" % r.hud.buttons_set)
	_f(12)
	_ok(_stage() == 2 and r.hud.card == "", "C: nobody answers: the drive by 9.1 s")
	_ok(r.hud.buttons_set == 10 and r.hud.buttons_lost == 0, "C: the last frame reads '· 0' as it is today (ten words set)")
	# driving off
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	ring = _ring_of(_ordr())
	var sring: Vector3 = _stand(int(_ordr()["stand"]))["ring"]
	_by(sring, 13.9)
	_f(5)
	_ok(_stage() == 1, "C: 13.9 m from the stand's ring: still the order")
	_by(sring, 14.1)
	_f()
	_ok(_stage() == 2, "C: 14.1 m: the drive")
	# GO, NOT NOW, the keys
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	o = _ordr()
	_press(0)
	_ok(_stage() == 2, "C: GO: the drive")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	o = _ordr()
	var closed1: int = r.missions.closed
	var toasts1: int = r.hud.toasts.size()
	var kinds1: int = r.wallet.kinds.size()
	_press(1)
	_ok(_stage() == 0 and int(q.job) == 0 and r.hud.card == "" and bool(_stand(int(o["stand"]))["cool"]), "C: NOT NOW: idle at once, the card down, the stand cool")
	_ok(r.bubbles.hushed.back() == _stand(int(o["stand"]))["node"] and not r.missions.paused and r.missions.closed == closed1 + 1, "C: NOT NOW: the vendor hushed, the calls ring again")
	_ok(r.wallet.kinds.size() == kinds1 and r.hud.toasts.size() == toasts1 and r.hud.route_owner != "jobs", "C: NOT NOW: no pay, no toast, no route")
	_rig()
	q = r.q
	_ok(not r.director.primary() and not r.director.secondary(), "C: both keys false while idle")
	_find(0, _plain_day(), "a plain order")
	_ok(r.director.primary() and _stage() == 2, "C: the M key: GO")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_ok(r.director.secondary() and _stage() == 0, "C: the K key: NOT NOW")
	_ok(not q.flash(), "C: flash with no challenge: false")
	# the order against the map is stated by the rules; the same n gives the same order
	_rig()
	q = r.q
	n = _find(0, _plain_day(), "a plain order")
	o = _ordr()
	_turn_down()
	q.start_kebab(n)
	_ok(q._order == o, "C: the same n at the same stand gives the same order")
	_turn_down()
	q.start_kebab(n + q._stands.size())
	_ok(q._order["name"] != o["name"] or q._order["door"] != o["door"], "C: the next n another door")
	_turn_down()
	var across := 0
	var total := 0
	for m in 60:
		if q.start_kebab(m):
			total += 1
			across += 1 if bool(q._order["across"]) else 0
			_turn_down()
	_ok(across > 0 and across < total / 2, "C: over %d orders %d are across the river" % [total, across])


func _turn_down_if_any() -> void:
	if _stage() == 1:
		_turn_down()


func _kind_of(o: Dictionary) -> String:
	return "praga" if o["d"] == "praga" else ("office" if o["office"] else str(o["d"]))


## The order card as the rules word it.
func _card_facts(o: Dictionary, kind: String, night: bool) -> void:
	var road := roundi(o["road"])
	if kind == "plain":
		_ok(r.hud.card == "ZAMÓWIENIE · KEBAB · %d m" % road and r.hud.card_en == "Kebab order · %d m" % road, "C: the card's title")
		var body := _plain_body(o, night)
		_ok(r.hud.body == body[0] and r.hud.body_en == body[1], "C: the card's body: '%s' / '%s'" % [r.hud.body, body[0]])
		_ok(r.hud.accent == ORANGE and r.hud.low and not r.hud.stacked and r.hud.card_is(r.q), "C: the card is orange, at the bottom, its own")


func _order_vs_map(o: Dictionary, st: Dictionary) -> void:
	var found := false
	for a: Dictionary in r.q._addresses:
		if a["name"] == o["name"] and a["door"] == o["door"]:
			found = true
	_ok(found, "C: the door is an address of the map")
	var door: Vector2 = o["door"]
	var side := ((o["at"] as Vector2) - door).normalized()
	var ring2 := door + side * 2.0
	var ring: Vector3 = o["ring"]
	_near(Vector2(ring.x, ring.z).distance_to(ring2), 0.0, 0.01, "C: the door's ring 2 m from the door")
	_near(ring.y, _graph.surface(int(o["edge"]), ring2), 0.01, "C: the door's ring at its lane's height")
	var road: float = o["road"]
	_ok(road >= 400.0 and road <= (3600.0 if bool(o["across"]) else 1500.0), "C: the trip %.0f m is in 400 to 1500 (3600 across)" % road)
	if bool(o["reached"]):
		var dist := _graph.distances_from(_graph.e_b[int(st["edge"])], false)
		_near(road, _graph.trip(dist, int(st["edge"]), float(st["s"]), int(o["edge"]), float(o["s"])), 0.01, "C: the trip is the lane graph's")
	_near(float(o["fair"]), (25.0 + road / 8.0) * (1.0 if str(o["zag"]) == "" else 1.0), 0.001 if str(o["zag"]) == "" else 1000.0, "C: fair is 25 + road / 8")
	_ok(int(o["stand"]) >= 0 and not bool(o["premium"]), "C: stand, not premium")


# --- D. the drive -------------------------------------------------------------------------------------------

func _s_d_drive() -> void:
	_rig(true, {}, {"start_heat": 0.9})
	var q: Node = r.q
	_find(0, _plain_day(), "a plain order")
	var o := _ordr()
	var ring := _ring_of(o)
	var toasts0: int = r.hud.toasts.size()
	_press(0)
	_ok(_stage() == 2 and q.busy() and r.hud.card == "" and q.has_target() and r.director.targeted() == q, "D: GO: the drive, the card down, the door is the target")
	_ok(q.target_position() == ring and q.stop_spot() == ring and q.target_colour() == ORANGE, "D: the target, the stop spot, the colour")
	_ok(_look(q._beacon) == [true, 12.5, ORANGE, true, true, true, true], "D: the ring at the door: %s" % [_look(q._beacon)])
	_ok(r.hud.toasts.size() == toasts0 + 1 and r.hud.toasts.back() == "Jedziemy! %s czeka" % o["customer"] \
			and r.hud.toasts_en.back() == "Go! %s is waiting" % o["customer"], "D: the toast")
	_ok(r.hud.route_owner == "jobs" and r.hud.route_colour == ORANGE and r.hud.route.size() >= 2, "D: the route on the minimap")
	if r.hud.route.size() >= 2:
		var worst := 0.0
		for k in range(1, r.hud.route.size()):
			worst = maxf(worst, r.hud.route[k].distance_to(r.hud.route[k - 1]))
		_ok(worst < 250.0, "D: the route's steps under 250 m (%.0f)" % worst)
		if bool(o["reached"]):
			_ok(r.hud.route[r.hud.route.size() - 1].distance_to(Vector2(ring.x, ring.z)) < 0.5, "D: the route ends at the door's ring")
	_ok(q.heat() == 0.9, "D: heat 0.9 with --heat=0.9")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	o = _ordr()
	ring = _ring_of(o)
	_press(0)
	_ok(q.heat() == 1.0, "D: heat 1.0 at GO")
	_by(ring, 300.0, 10.0)
	_f()
	_ok(r.hud.status_title == "KEBAB → %s" % o["name"] and r.hud.count == "GORĄCY 100%" and r.hud.distance == "%d m" % roundi(_flat(_car, ring)) \
			and r.hud.tint == ORANGE and r.hud.progress == 0.0 and r.hud.badge == "" and r.hud.icons.has("heat"), "D: the status line (%s / %s / %s)" % [r.hud.status_title, r.hud.count, r.hud.distance])
	_ok(absf(float(r.hud.icons["heat"]) - float(q._heat)) < 0.0001, "D: the heat picture is the heat")
	var fair: float = o["fair"]
	_f(599)
	_near(float(q._heat), 1.0 - 600.0 * DT * 0.6 / fair, 0.001, "D: the heat after 10 s")
	var h0: float = q._heat
	var c0: float = q._clock
	q.heat_frozen = true
	_f(300)
	_near(float(q._heat), h0, 0.0001, "D: the heat stands still while frozen")
	_ok(float(q._clock) > c0 + 4.9, "D: the clock does not stand still")
	q.heat_frozen = false
	q._heat = 0.001
	_f(60)
	_ok(float(q._heat) == 0.0 and r.hud.count == "ZIMNY 0%", "D: the heat never below 0 (%s)" % r.hud.count)
	for pair in [[0.705, "GORĄCY"], [0.695, "CIEPŁY"], [0.405, "CIEPŁY"], [0.395, "ZIMNY"]]:
		q._heat = pair[0]
		_f()
		_ok(r.hud.count.begins_with(pair[1]), "D: heat %.3f reads %s (%s)" % [pair[0], pair[1], r.hud.count])
	# the hints
	var rate := 0.6 / maxf(fair, 1.0)
	q._heat = 0.9
	_f()
	var s1 := ceili((float(q._heat) - 0.7) / rate - 0.01)
	_ok(r.hud.status == "Gorący jeszcze %d s" % s1 and r.hud.hint_en == "Hot for %d s more" % s1, "D: the hot hint (%s)" % r.hud.status)
	q._heat = 0.6
	_f()
	var s2 := ceili((float(q._heat) - 0.4) / rate - 0.01)
	_ok(r.hud.status == "Ciepły jeszcze %d s, potem bez napiwku" % s2 and r.hud.hint_en == "Warm for %d s, then no tip" % s2, "D: the warm hint")
	q._heat = 0.2
	_f()
	_ok(r.hud.status == "Zimny: bez napiwku, kurs się liczy" and r.hud.hint_en == "Cold: no tip, the fare still counts", "D: the cold hint")
	_by(ring, 30.0, 10.0)
	_f()
	_ok(r.hud.status == "Stań w kręgu" and r.hud.hint_en == "Pull up inside the ring", "D: 30 m: pull up inside the ring")
	_by(ring, 10.0, 6.5)
	_f()
	_ok(r.hud.status == "Stań pod drzwiami" and r.hud.hint_en == "Stop at the door" and _stage() == 2, "D: inside rolling: stop at the door")
	_fly = true
	_by(ring, 300.0, 10.0)
	_f()
	_ok(r.hud.status == "Wyląduj i weź auto: zamówienie jedzie autem" and r.hud.hint_en == "Land and take the car: the order rides in the car", "D: flying: the landing hint")
	_by(ring, 5.0)
	_f(30)
	_ok(_stage() == 2, "D: from the air over the door: never")
	_fly = false
	# the door
	_by(ring, 13.1)
	_f(30)
	_ok(_stage() == 2, "D: 13.1 m from the ring: never")
	_by(ring, 12.9, 6.1)
	_f(30)
	_ok(_stage() == 2, "D: 12.9 m at 6.1 m/s: never")
	_by(ring, 12.9, 5.9)
	_f()
	_ok(_stage() == 3, "D: 12.9 m at 5.9 m/s: the result")
	# the keys and the ✕ on the drive
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_press(0)
	_drive_far(5)
	_ok(not r.director.primary() and not r.director.secondary() and _stage() == 2, "D: both keys false on the drive")
	r.hud.abort_pressed.emit()
	_ok(_stage() == 3 and not bool(q._delivered) and r.hud.card == "KURS PRZERWANY" or r.hud.card == "ZAMÓWIENIE PRZEPADŁO", "D: the ✕ on the drive drops the order")
	# the route is walked again as the car moves
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	var st := _stand(int(q._order["stand"]))
	_press(0)
	var first: Vector2 = r.hud.route[0] if r.hud.route.size() > 0 else Vector2.ZERO
	var head: Vector2 = st["heading"]
	var p := Vector2(st["ring"].x, st["ring"].z)
	for k in 120:
		p += head * 20.0 * DT
		_at(p, 20.0, atan2(-head.x, -head.y))
		_f()
	_ok(r.hud.route.size() > 0 and r.hud.route[0] != first and r.director.job_on(), "D: the route's first point moved with the car")


# --- E. the result cards ------------------------------------------------------------------------------------

func _s_e_results() -> void:
	_rig()
	var q: Node = r.q
	_ok(Jobs._clock_text(0.04) == "0:00.0" and Jobs._clock_text(9.96) == "0:09.9" and Jobs._clock_text(61.5) == "1:01.5" and Jobs._clock_text(-3.0) == "0:00.0",
			"E: the clock's words")
	_ok(Jobs._money(1234567) == "1 234 567 zł", "E: the wallet's words")
	for kase in [[1.0, false], [0.55, false], [0.2, false], [0.9, true]]:
		_rig()
		q = r.q
		var night: bool = kase[1]
		r.tod.mode = 2 if night else 0
		_find(0, _plain_day(), "a plain order")
		_press(0)
		_drive_far(60)
		q._heat = kase[0]
		var money0: int = r.wallet.money
		var resp0: int = r.wallet.respect
		var kinds0: int = r.wallet.kinds.size()
		_arrive_now()
		var o := _ordr()
		var h: float = q._heat
		var clock: float = q._clock
		_ok(_stage() == 3 and q.busy() and not q.has_target() and q.stop_spot() == Vector3.INF and r.hud.status_title == "", "E: the result: stage 3, busy, no target, status down")
		_ok(r.bubbles.hushed.back() == r.car, "E: the passenger's chatter hushed")
		var b := _look(q._beacon)
		_ok(b[0] and not b[3] and not b[4] and b[5] and not b[6], "E: the ring at the door: the person waits, not waving")
		var fare := roundi(12.0 + float(o["road"]) * 0.015)
		var tip := roundi(h * (10.0 + float(o["road"]) * 0.02)) if h >= 0.4 else 0
		var total := roundi((fare + tip) * (1.5 if night else 1.0))
		_ok(r.wallet.money - money0 == total and r.wallet.respect - resp0 == (10 if h >= 0.4 else 0) and r.wallet.kinds.size() == kinds0 + 1 \
				and r.wallet.kinds.back() == "kebab", "E: the pay %d (fare %d + tip %d%s), respect, kind once" % [total, fare, tip, " x1.5" if night else ""])
		_ok(absf(float(r.wallet.best["kebab:%d:%s" % [o["stand"], o["name"]]]) - clock) < 0.0001, "E: the record under the order's key")
		var word := "still hot" if h >= 0.7 else ("warm" if h >= 0.4 else "cold")
		var word_pl := "WCIĄŻ GORĄCY" if h >= 0.7 else ("CIEPŁY" if h >= 0.4 else "ZIMNY")
		var hot := h >= 0.4
		var li := _last_said("kebab_hot:" if hot else "kebab_cold:")
		_ok(li >= 0 and r.dialogue.speakers[li] == o["customer"] and r.dialogue.anchors[li] == q._beacon \
				and r.dialogue.hows[li] == [5.0, ORANGE if hot else ICE, 3.6, false], "E: the customer's line over the ring")
		_ok(r.hud.card == "DOWIEZIONE · " + word_pl and r.hud.card_en == "Delivered · " + word and r.hud.low and not r.hud.stacked \
				and r.hud.card_is(q) and r.hud.accent == (ORANGE if hot else ICE) and r.hud.button_words == PackedStringArray(["OK", "NASTĘPNE"]), "E: the card's title, colour, buttons")
		var night_pl := " · noc ×1,5" if night else ""
		var night_en := " · night ×1.5" if night else ""
		var body_pl := "„Słowo”\n%s, %s: %s, ciepło %d%%\nKurs %d zł + napiwek %d zł%s = %d zł · w portfelu %s" % [o["customer"], o["name"], _ct(clock),
				roundi(h * 100.0), fare, tip, night_pl, total, _zl(r.wallet.money)]
		var body_en := "A word\n%s at %d%% heat · Fare %d zł + tip %d zł%s = %d zł · wallet %s" % [_ct(clock), roundi(h * 100.0), fare, tip, night_en,
				total, _zl(r.wallet.money)]
		_ok(r.hud.body == body_pl, "E: the body '%s' / '%s'" % [r.hud.body, body_pl])
		_ok(r.hud.body_en == body_en, "E: the English body '%s' / '%s'" % [r.hud.body_en, body_en])
	# OK
	_rig()
	q = r.q
	var n := _find(0, _plain_day(), "a plain order")
	var res := _deliver()
	_ok(res["stage"] == 3, "E: delivered")
	var o1: Dictionary = res["o"]
	var closed0: int = r.missions.closed
	_press(0)
	_ok(_stage() == 0 and r.hud.card == "" and not q._beacon.visible and not r.missions.paused and r.missions.closed == closed0 + 1 \
			and r.hud.route_owner != "jobs" and not q.pointing() and int(q.next_stand) == -1 and not bool(_stand(int(o1["stand"]))["cool"]), "E: OK: idle, the ring hidden, the calls ring, no pointer")
	_at(FAR)
	_f()
	_ok(r.hud.pois > 0, "E: the places are back at the next frame")
	# the same order again, faster and slower
	for kase in [["faster", 30, " · nowy rekord!", " · new best!"], ["slower", 200, " · rekord %s", " · best %s"]]:
		q.start_kebab(n)
		_sync()
		_press(0)
		_drive_far(int(kase[1]))
		_arrive_now()
		var clock: float = q._clock
		var h: float = q._heat
		var suffix_pl: String = kase[2]
		var suffix_en: String = kase[3]
		if kase[0] == "slower":
			suffix_pl = suffix_pl % _ct(float(r.wallet.best["kebab:%d:%s" % [o1["stand"], o1["name"]]]))
			suffix_en = suffix_en % _ct(float(r.wallet.best["kebab:%d:%s" % [o1["stand"], o1["name"]]]))
		_ok(r.hud.body.contains("%s, ciepło %d%%%s\n" % [_ct(clock), roundi(h * 100.0), suffix_pl]), "E: the %s second delivery says '%s' (%s)" % [kase[0], suffix_pl, r.hud.body])
		_ok(r.hud.body_en.contains("at %d%% heat%s\n" % [roundi(h * 100.0), suffix_en]) or r.hud.body_en.contains("heat%s ·" % suffix_en), "E: the English record words '%s'" % r.hud.body_en)
		_press(0)
		_at(FAR)
		_f(2)
	# no line in the bag: no quote
	_rig()
	q = r.q
	r.dialogue.say_words = []
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_ok(not r.hud.body.begins_with("„") and not r.hud.body_en.begins_with("A word"), "E: with no line in the bag, no quote")
	# NASTĘPNE and the pointer
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	var heading := Vector2(-sin(_yaw), -cos(_yaw))
	var want := _nearest_stand(Vector2(_car.x, _car.z), heading)
	var toasts0: int = r.hud.toasts.size()
	_press(1)
	_ok(_stage() == 0 and q.pointing() and int(q.next_stand) == want[0], "E: NASTĘPNE: idle, pointing at the nearest stand by road (%d / %d)" % [q.next_stand, want[0]])
	var st := _stand(int(q.next_stand))
	_ok(not bool(st["cool"]) and not q.has_target() and r.director.targeted() == null and q.target_position() == st["ring"] \
			and q.stop_spot() == st["ring"] and q.target_colour() == ORANGE, "E: the pointer's target and colour")
	var who: String = "Kebab 24h" if st["name"] == "" else String(st["name"]).capitalize()
	_ok(r.hud.toasts.size() == toasts0 + 1 and r.hud.toasts.back() == "Następne zamówienie: %s, %d m" % [who, roundi(want[1])] \
			and r.hud.toasts_en.back() == "Next order: %s, %d m" % [who, roundi(want[1])], "E: the pointer's toast (%s)" % r.hud.toasts.back())
	_ok(r.hud.route_owner == "jobs" and r.hud.route_colour == ORANGE, "E: the pointer's route")
	var ring: Vector3 = st["ring"]
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(int(q.next_stand) == -1 and _stage() == 1, "E: the pointer goes with a pull-in there")
	_turn_down()
	# anything else coming on
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_press(1)
	_at(FAR)
	r.rides.on = true
	_f()
	_ok(int(q.next_stand) == -1 and not q.pointing() and r.hud.route_owner != "jobs", "E: a ride on: the pointer and its route go")
	r.rides.on = false
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_press(1)
	r.round.on = true
	_ok(not q.pointing() and q.stop_spot() == Vector3.INF, "E: not pointing while the round-up is on")
	# the 12 s and the 25 m, the ✕ does nothing
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	r.hud.abort_pressed.emit()
	r.hud.abort_pressed.emit()
	_ok(_stage() == 3 and r.hud.card.begins_with("DOWIEZIONE") and bool(q._delivered), "E: the ✕ does nothing on a result card (it is still the delivered card)")
	_f(713)
	_ok(_stage() == 3, "E: still up at 11.9 s")
	_f(12)
	_ok(_stage() == 0 and r.hud.card == "", "E: gone by 12.1 s")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	ring = _ring_of(_ordr())
	_by(ring, 24.9)
	_f(3)
	_ok(_stage() == 3, "E: 24.9 m from where it came up: still up")
	_by(ring, 25.1)
	_f()
	_ok(_stage() == 0, "E: 25.1 m: gone")
	# dropped
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	var oo := _ordr()
	var money0: int = r.wallet.money
	r.hud.abort_pressed.emit()
	_ok(_stage() == 3 and q.busy() and not q.has_target() and r.hud.status_title == "" and not q._beacon.visible and r.wallet.money == money0, "E: dropped on the order: result stage, no pay")
	_ok(r.hud.card == "ZAMÓWIENIE PRZEPADŁO" and r.hud.card_en == "Order dropped" and r.hud.accent == RED and r.hud.low and r.hud.card_is(q) \
			and r.hud.button_words == PackedStringArray(["OK"]), "E: the dropped card")
	_ok(r.hud.body == "%s (%s) się nie dowie. Gołębie z placu Defilad miały ucztę." % [oo["customer"], oo["name"]] \
			and r.hud.body_en == "%s at %s will never know. The pigeons on Plac Defilad had a feast." % [oo["customer"], oo["name"]], "E: the dropped card's words")
	_ok(not r.director.secondary(), "E: the K key on a dropped card: nothing")
	_ok(r.director.primary() and _stage() == 0, "E: the M key closes it")
	_ok(not bool(_stand(int(oo["stand"]))["cool"]), "E: after a dropped order the stand is not cool")
	_f()
	_ok(_stage() == 1, "E: the car in its ring gets the next order")
	q.card_pressed(1)
	_ok(_stage() == 0, "E: NOT NOW on the next order: idle")


## The stand nearest the car by the roads (the check's own search, never the links off the map), and the metres.
func _nearest_stand(p: Vector2, heading: Vector2) -> Array:
	var hit := _graph.snap(p, 40.0, heading, true)
	var dist := PackedFloat32Array()
	if not hit.is_empty():
		dist = _graph.distances_from(_graph.e_b[int(hit[0])], false)
	var best := -1
	var best_d := INF
	for i in r.q._stands.size():
		var s := _stand(i)
		var d := INF
		if not dist.is_empty():
			d = _graph.trip(dist, int(hit[0]), float(hit[2]), int(s["edge"]), float(s["s"]))
		if d >= INF:
			d = Vector2(s["ring"].x, s["ring"].z).distance_to(p) * 1.4
		if d < best_d:
			best_d = d
			best = i
	return [best, best_d]


# --- F. the craft kebab and the Zagłębie --------------------------------------------------------------------

## The first n from `from` that is at the stand of shop `tag` (n mod the stands).
func _n_of(tag: String, k := 0) -> int:
	return _zag(tag) + r.q._stands.size() * k


func _s_f_zag() -> void:
	_rig()
	var q: Node = r.q
	var size: int = q._stands.size()
	# the royal set
	var min_road := INF
	for k in 20:
		q.start_kebab(_n_of("zag_krol", k))
		_sync()
		min_road = minf(min_road, float(q._order["road"]))
		if k == 0:
			var o := _ordr()
			var body_pl: Array = _plain_body(o, false, " Zestaw Królewski: ×1,25.")
			_ok(r.hud.body == body_pl[0], "F: the royal card ends with its set (%s)" % r.hud.body)
		_turn_down()
	_ok(min_road >= 700.0, "F: zag_krol sends only trips of 700 m or more (%.0f)" % min_road)
	# each shop's pay
	var fair_ratio := 0.0
	for tag in ["zag_krol", "zag_stambul", "zag_pasza", "zag_erdal"]:
		for night in [false, true]:
			_rig()
			q = r.q
			r.tod.mode = 2 if night else 0
			_find_shop(tag)
			var o := _ordr()
			var vi := _last_said("kebab_vendor:" + str(_stand(_zag(tag))["tag"]))
			_ok(vi >= 0 and r.dialogue.hows[vi][3] == true, "F: %s's vendor line is asked with its tag, preferred" % tag)
			var res := _deliver()
			var h: float = res["h"]
			var road: float = res["o"]["road"]
			var fare := roundi(12.0 + road * 0.015)
			var tip_mul := 2.0 if tag == "zag_erdal" else 1.0
			var tip := roundi(h * (10.0 + road * 0.02) * tip_mul) if h >= 0.4 else 0
			var zmul := 1.25 if tag == "zag_krol" or (tag == "zag_stambul" and night) or tag == "zag_pasza" and false else 1.0
			if tag == "zag_stambul" or tag == "zag_pasza" or tag == "zag_erdal":
				zmul = 1.25 if (tag == "zag_stambul" and night) else 1.0
			var total := roundi((fare + tip) * (1.5 if night else 1.0) * zmul)
			_ok(res["money"] == total, "F: %s pays %d%s (%d)" % [tag, total, " at night" if night else "", res["money"]])
			if tag == "zag_pasza" and not night:
				fair_ratio = float(res["o"]["fair"]) / (25.0 + road / 8.0)
	_near(fair_ratio, 0.8, 0.001, "F: zag_pasza's fair is 0.8 of 25 + road / 8")
	# the craft shop
	_rig()
	q = r.q
	var n := _find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	if n >= 0:
		var o := _ordr()
		var x := _extras(o, false)
		_ok(r.hud.card == "ZAMÓWIENIE · ROŻEN · %d m" % roundi(o["road"]) and r.hud.card_en == "Craft kebab · %d m" % roundi(o["road"]) \
				and r.hud.button_words == PackedStringArray(["POCZEKAM", "ZWYKŁY"]), "F: the craft card's title and buttons")
		_ok(r.hud.body == "Dla: %s, %s.%s Rzemieślnik kroi ręcznie, z zakwasu: poczekaj 6 s, a kebab pójdzie ×1,6 i wolniej stygnie. Albo weź zwykły.%s" \
				% [o["customer"], o["name"], x[0], x[2]], "F: the craft card's body (%s)" % r.hud.body)
		_ok(r.hud.body_en == "Hand-carved, on sourdough: wait 6 s and it pays ×1.6 and cools slower. Or take a plain one.", "F: the craft card's English")
		_f()
		_ok(r.hud.button_words[1] == "ZWYKŁY · 14" and r.hud.button_words_en[1] == "PLAIN · 14" and r.hud.button_words[0] == "POCZEKAM", "F: the count-down is on the second button")
		_f(90)
		_ok(r.hud.button_words[1] == "ZWYKŁY · 13", "F: the second button counts down (%s)" % r.hud.button_words[1])
		_f(740)
		_ok(_stage() == 1, "F: nobody answers: still the order at 13.9 s")
		_f(14)
		_ok(_stage() == 2 and not bool(q._order["premium"]), "F: the plain kebab goes by 14.1 s")
	# POCZEKAM
	_rig()
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	var fair0: float = q._order["fair"]
	var toasts0: int = r.hud.toasts.size()
	_press(0)
	_ok(r.hud.card == "" and _stage() == 1 and r.hud.toasts.size() == toasts0 + 1 and r.hud.toasts.back() == "Rzemieślnik kroi… 6 s" \
			and r.hud.toasts_en.back() == "Carving by hand… 6 s", "F: POCZEKAM: the card down, still the order, the toast")
	var set0: int = r.hud.buttons_set
	_f(354)
	_ok(_stage() == 1 and r.hud.buttons_set == set0, "F: 5.9 s after: still the order, no count-down while waiting")
	_f(12)
	_ok(_stage() == 2 and bool(q._order["premium"]) and absf(float(q._order["fair"]) - fair0 * 1.5) < 0.001, "F: by 6.1 s: the drive with premium, fair x1.5")
	var res := _deliver_after_go()
	var fare := roundi(12.0 + float(res["o"]["road"]) * 0.015)
	var tip := roundi(float(res["h"]) * (10.0 + float(res["o"]["road"]) * 0.02)) if float(res["h"]) >= 0.4 else 0
	_ok(res["money"] == roundi((fare + tip) * 1.6), "F: the craft kebab pays x1.6 (%d)" % res["money"])
	# during the wait
	_rig()
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	var sring: Vector3 = _stand(int(q._order["stand"]))["ring"]
	_press(0)
	_by(sring, 14.1)
	_f()
	_ok(_stage() == 2 and not bool(q._order["premium"]), "F: during the wait, 14.1 m off: the plain one goes")
	_rig()
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	_press(0)
	_ok(r.director.primary() and _stage() == 1, "F: the M key during the wait: taken, nothing changes")
	_ok(r.director.secondary() and _stage() == 2 and not bool(q._order["premium"]), "F: the K key during the wait: the plain one at once")
	_rig()
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	_press(0)
	r.hud.abort_pressed.emit()
	_ok(_stage() == 3 and r.hud.card == "ZAMÓWIENIE PRZEPADŁO", "F: the ✕ during the wait: the dropped card")
	# ZWYKŁY
	_rig()
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	_press(1)
	_ok(_stage() == 2 and not bool(q._order["premium"]), "F: ZWYKŁY: the drive at once, plain")
	res = _deliver_after_go()
	fare = roundi(12.0 + float(res["o"]["road"]) * 0.015)
	tip = roundi(float(res["h"]) * (10.0 + float(res["o"]["road"]) * 0.02)) if float(res["h"]) >= 0.4 else 0
	_ok(res["money"] == roundi(fare + tip), "F: the plain pay x1.0 at the craft shop (%d)" % res["money"])
	# Szlak Szpili
	_rig()
	q = r.q
	var order_done: Array = []
	for tag in ["zag_stambul", "zag_krol", "zag_erdal", "zag_rozen", "zag_pasza"]:
		_find_shop(tag)
		var tt: int = r.hud.toasts.size()
		var kinds0: int = r.wallet.kinds.size()
		res = _deliver_after_go(true)
		order_done.append(tag)
		var trail: String = str(r.wallet.keep.get("zaglebie_trail", ""))
		_ok(trail == ",".join(PackedStringArray(order_done)), "F: the trail key after %s: %s" % [tag, trail])
		var bonus: bool = tag == "zag_pasza"
		var sz := "SZLAK SZPILI: pięć kebabów, pięć zagłębi! +120 zł"
		var had := r.hud.toasts.slice(tt).has(sz)
		_ok(had == bonus, "F: the trail's toast only with the fifth (%s)" % tag)
		if bonus:
			_ok(r.wallet.kinds.size() == kinds0 + 2 and r.wallet.kinds.back() == "" and r.hud.toasts_en.has("Skewer Trail: five kebabs from five shops! +120 zł"), "F: the fifth's bonus has no kind")
	_find_shop("zag_krol")
	var tt6: int = r.hud.toasts.size()
	res = _deliver_after_go(true)
	_ok(not r.hud.toasts.slice(tt6).has("SZLAK SZPILI: pięć kebabów, pięć zagłębi! +120 zł"), "F: a sixth delivery pays no second bonus")
	_rig(true, {"zaglebie_trail": "zag_krol,zag_stambul,zag_pasza,zag_erdal"})
	q = r.q
	_find_shop("zag_rozen")
	res = _deliver_after_go(true)
	_ok(r.hud.toasts.has("SZLAK SZPILI: pięć kebabów, pięć zagłębi! +120 zł"), "F: with four done, the first rozen delivery pays the trail")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_ok(not r.wallet.keep.has("zaglebie_trail"), "F: a plain stand's delivery leaves the key alone")


## An order of the shop `tag`, by day, not across the river; a craft one answers ZWYKŁY at once.
func _find_shop(tag: String) -> void:
	_find(_n_of(tag), func(o: Dictionary) -> bool: return str(o["zag"]) == tag and not bool(o["across"]), "an order of " + tag, r.q._stands.size())
	if bool(r.q._order.get("craft", false)):
		_press(1)


## The drive of the order that is on (GO unless it is already on the road), then the door.
func _deliver_after_go(press_go := false) -> Dictionary:
	var money0: int = r.wallet.money
	var resp0: int = r.wallet.respect
	if press_go and _stage() == 1:
		_press(0)
	_drive_far(60)
	_arrive_now()
	var out := {"o": _ordr(), "h": float(r.q._heat), "money": r.wallet.money - money0, "respect": r.wallet.respect - resp0}
	_press(0)
	_at(FAR)
	_f(2)
	return out


# --- G. the słoiki run ----------------------------------------------------------------------------------------

func _station_run(k: int, broken := 0) -> void:
	r.q.start_sloik(broken, k)
	_sync()


func _s_g_sloik() -> void:
	_rig()
	var q: Node = r.q
	for k in q._stations.size():
		_rig()
		q = r.q
		r.dialogue.line_words = ["Dwa kebaby", "Two kebabs"]
		var st: Dictionary = q._stations[k]
		var sring: Vector3 = st["ring"]
		var lone := _lone_station(k)
		_by(q._stations[lone]["ring"], 0.0)
		st = q._stations[lone]
		sring = st["ring"]
		_at(Vector2(sring.x, sring.z))
		_f()
		if _stage() != 1:
			_problems.append("G: a pull-in at %s did not start a run" % st["name"])
			continue
		var o := _ordr()
		var dest_pl: String = st["dest_pl"]
		_ok(int(q.job) == 2 and r.hud.card == "SŁOIKI · NIEDZIELNY WIECZÓR" and r.hud.card_en == "The słoiki run · Sunday evening" and r.hud.low \
				and r.hud.card_is(q) and r.hud.accent == TEAL and r.hud.button_words == PackedStringArray(["GO!", "NOT NOW"]), "G: the run's card at %s" % st["name"])
		_ok(r.hud.body == "%s wraca od mamy z 6 słoikami. Cel: %s, %s (%d m). Dziury, hamowanie i szybkie zakręty tłuką słoiki." % [o["customer"], o["name"], dest_pl, roundi(o["road"])] \
				and r.hud.body_en == "Back from home with 6 of mum's jars, to a rented flat in %s. Bumps, braking and fast corners break jars." % st["dest_en"], "G: the run's body")
		var vi := _last_said("sloik_start:" + str(st["tag"]))
		_ok(vi >= 0 and r.dialogue.speakers[vi] == o["customer"] and r.dialogue.anchors[vi] == st["person"] and r.dialogue.hows[vi] == [4.0, TEAL, 2.9, false], "G: the newcomer's line")
		_ok(str(o["customer"]) in NEWCOMERS and not bool(o["office"]), "G: the customer is a newcomer, the flat no office")
		if st["tag"] == "centralny":
			_ok(o["d"] == "powisle" and float(o["road"]) >= 1000.0 and float(o["road"]) <= 2400.0, "G: a Powiśle flat 1000 to 2400 m by road (%.0f)" % o["road"])
		else:
			var at: Vector2 = o["at"]
			_ok(at.x >= -2700.0 and at.y >= -2700.0 and at.x <= -1500.0 and at.y <= -1500.0 and float(o["road"]) >= 600.0 and float(o["road"]) <= 2000.0,
					"G: a flat in the Muranów box 600 to 2000 m (%.0f)" % o["road"])
		_f()
		_ok(r.hud.button_words[0] == "JEDZIEMY! · 9" and r.hud.button_words_en[0] == "GO! · 9", "G: the count-down")
		_f(534)
		_ok(_stage() == 1, "G: still the order at 8.9 s")
		_f(12)
		_ok(_stage() == 2, "G: gone to the drive by 9.1 s")
	# NOT NOW, the keys, GO
	_rig()
	q = r.q
	var k0 := _lone_station(0)
	q.start_sloik(0, k0)
	_sync()
	_press(1)
	_ok(_stage() == 0 and bool(q._stations[k0]["cool"]) and r.bubbles.hushed.back() == q._stations[k0]["person"], "G: NOT NOW: idle, the station cool, the newcomer hushed")
	q.start_sloik(0, k0)
	_sync()
	_ok(r.director.secondary() and _stage() == 0, "G: the K key: NOT NOW")
	q.start_sloik(0, k0)
	_sync()
	_ok(r.director.primary() and _stage() == 2, "G: the M key: GO")
	o_check_go(q, k0)


func o_check_go(q: Node, k0: int) -> void:
	var o := _ordr()
	var ring := _ring_of(o)
	var st: Dictionary = q._stations[k0]
	_ok(not (st["person"] as Node3D).visible, "G: the newcomer hidden")
	_ok(r.hud.toasts.back() == "Jedź płynnie, bo słoiki się tłuką" and r.hud.toasts_en.back() == "Drive smoothly: hard bumps, braking and fast corners break jars", "G: GO's toast")
	_ok(_look(q._beacon) == [true, 12.5, TEAL, true, true, false, true] and q.target_colour() == TEAL and r.hud.route_colour == TEAL \
			and r.hud.route_owner == "jobs", "G: the ring at the flat, teal, no person (%s)" % [_look(q._beacon)])
	_by(ring, 300.0, 15.0)
	_f()
	_ok(r.hud.status_title == "SŁOIKI → %s" % o["name"] and r.hud.count == "0:00.0" and r.hud.tint == TEAL and r.hud.progress == float(q._stress) \
			and r.hud.icons.get("jars") == [6, 6] and float(r.hud.icons.get("shake", -1.0)) == clampf(float(q._stress), 0.0, 1.0), "G: the status line")
	_ok(r.hud.status == "Jedź do turkusowego światła" and r.hud.hint_en == "Head for the teal beacon", "G: the far hint")
	_ok(q.heat() == 1.0, "G: the heat does not move on a run")
	_f(437)
	_ok(r.hud.count == _ct(float(q._clock)) and float(q._clock) > 7.2, "G: the clock reads %s" % r.hud.count)
	q._stress = 0.58
	_f()
	_ok(r.hud.status == "Spokojnie! Słoiki dzwonią" and r.hud.hint_en == "Easy! The jars are rattling", "G: the rattle's hint")
	_by(ring, 30.0, 10.0)
	_f()
	_ok(r.hud.status == "Spokojnie! Słoiki dzwonią", "G: the rattle's hint within 40 m")
	_by(ring, 10.0, 6.5)
	_f()
	_ok(r.hud.status == "Stań pod drzwiami" and _stage() == 2, "G: inside the ring rolling: the door, not the rattle")
	q._stress = 0.0
	_fly = true
	_by(ring, 300.0, 10.0)
	_f()
	_ok(r.hud.status == "Wyląduj i weź auto: zamówienie jedzie autem", "G: flying: the landing hint")
	_fly = false


## The jars' physics on a fresh run: the car's forward speed and yaw by hand.
func _sloik_drive() -> Node:
	_rig()
	var q: Node = r.q
	q.start_sloik(0, _lone_station(0))
	_sync()
	_press(0)
	var ring := _ring_of(_ordr())
	_by(ring, 800.0, 15.0)
	_yaw = 0.0
	_fwd = 15.0
	return q


func _fr(v: float, yaw: float) -> void:
	_fwd = v
	_yaw = yaw
	_f()


# --- I. the director and the other jobs -------------------------------------------------------------------------

func _s_i_hub() -> void:
	_rig()
	var q: Node = r.q
	var d := r.director
	_ok(not d.job_on() and not q.own_busy() and not q.side_busy() and not q.round_busy() and not q.ride_offered(), "I: nothing on")
	r.rides.on = true
	_ok(d.job_on() and q.busy() == false, "I: a ride on alone: a side job is on")
	r.rides.on = false
	r.trend.on = true
	_ok(d.job_on(), "I: the trend job on alone: a side job is on")
	r.trend.on = false
	r.round.on = true
	_ok(q.own_busy() and q.round_busy(), "I: the round-up on: own_busy, round_busy")
	r.round.on = false
	r.trend.offer = true
	_ok(q.side_busy() and not q.own_busy(), "I: the trend job's card: side_busy")
	r.trend.offer = false
	r.rides.offer = true
	_ok(q.ride_offered(), "I: the ride's request: ride_offered")
	r.rides.offer = false
	_find(0, _plain_day(), "a plain order")
	_ok(d.job_on() and not d.may_start(r.round), "I: an order: a side job on, the round-up may not start")
	r.rides.takes_m = true
	_ok(d.primary() and r.rides.keys == ["M"] and _stage() == 1, "I: a ride's card takes M before the order")
	r.rides.takes_m = false
	_press(0)
	_ok(d.job_on(), "I: the drive: a side job is on")
	_drive_far(5)
	_arrive_now()
	_ok(d.job_on(), "I: the result card: a side job is on")
	_press(0)
	_at(FAR)
	_f(2)
	_ok(not d.job_on() and d.may_start(r.round), "I: after: none, and the round-up may start")
	r.round.takes_m = true
	r.trend.takes_k = true
	_ok(d.primary() and r.round.keys == ["M"] and d.secondary() and r.trend.keys == ["K"], "I: idle: the round-up's and the trend job's keys go")
	r.round.takes_m = false
	r.trend.takes_k = false
	# the squares
	var p0: int = r.hud.pois_set
	q.depots_shown(true)
	_ok(r.hud.pois_set == p0 + 1, "I: depots_shown while free: the squares again")
	q.places_dirty()
	_ok(r.hud.pois_set == p0 + 2, "I: places_dirty while free: the squares at once")
	r.round.on = true
	var p1: int = r.hud.pois_set
	q.depots_shown(true)
	_ok(r.hud.pois_set == p1, "I: depots_shown under the round-up: not")
	r.round.on = false
	# somebody else's card
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	r.hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	var b0: int = r.hud.broadcast
	r.hud.press(0)
	_ok(r.hud.broadcast == b0 + 1 and _stage() == 1, "I: a press of somebody else's card reaches every listener, the order stays")
	_f(5)
	_ok(r.hud.button_words[0].begins_with("JEDZIEMY!"), "I: the count-down relabels the other's card (as it is today)")
	_f(540)
	_ok(_stage() == 2 and r.hud.card == "INNA", "I: the order goes by itself at 9 s, the other's card still up")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	r.hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_f(726)
	_ok(_stage() == 0 and r.hud.card == "INNA", "I: a result card goes in 12 s under another's card")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	var title: String = r.hud.card
	var body: String = r.hud.body
	r.hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_f()
	_ok(r.hud.card == "INNA", "I: the other's card stays while it is up")
	r.hud.hide_card()
	_f()
	_ok(r.hud.card == title and r.hud.body == body and r.hud.card_is(q), "I: the order's card is back, its own, at the next frame")
	r.hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_ok(r.director.secondary() and _stage() == 0 and r.hud.card == "INNA", "I: the K key under the other's card: idle, the other's card still up")
	# other things coming on do not end it
	for what in ["a ride", "the trend job", "a race", "a rescue", "a questline"]:
		_rig()
		q = r.q
		_find(0, _plain_day(), "a plain order")
		_gate(what, true)
		_f(5)
		_ok(_stage() == 1, "I: %s on during an order: the order stays" % what)
		_press(0)
		_drive_far(5)
		_ok(_stage() == 2, "I: %s on during a drive: the drive stays" % what)


# --- J. the names and the test flags ----------------------------------------------------------------------------

func _s_j_names() -> void:
	_rig()
	var q: Node = r.q
	var plain: Array = []
	for i in q._stands.size():
		if str(_stand(i)["zag"]) == "":
			plain.append(i)
	var i: int = plain[0]
	var inst0 := _tile_instances()
	q.name_stand(i, "U ZDZICHA", "zdzich")
	_ok(_stand(i)["name"] == "U ZDZICHA" and q.stand_tag(i) == "zdzich" and (_stand(i)["node"] as Node3D).get_node_or_null("NamedStand") != null \
			and _tile_instances() == inst0 - 1, "J: name_stand: the board, the tag, the mesh, one instance fewer")
	q.name_stand(i, "ZMIANA", "inna")
	_ok(_stand(i)["name"] == "U ZDZICHA" and q.stand_tag(i) == "zdzich", "J: a second name_stand changes nothing")
	var z := _zag("zag_krol")
	q.name_stand(z, "X", "y")
	_ok(_stand(z)["name"] == BOARDS[0], "J: a Zagłębie stand's name stays")
	q.name_stand(-1, "X", "y")
	q.name_stand(q._stands.size(), "X", "y")
	q.tag_stand(i, "hala")
	_ok(q.stand_tag(i) == "hala" and _stand(i)["name"] == "U ZDZICHA", "J: tag_stand: the tag only")
	q.tag_stand(i, "zdzich")
	var ring: Vector3 = _stand(i)["ring"]
	var offers: Array = q.offer_places()
	_ok(offers[i]["name"] == ["Kebab · U Zdzicha", "Kebab · U Zdzicha"], "J: offer_places says Kebab · U Zdzicha")
	_at(Vector2(ring.x, ring.z))
	_f()
	var vi := _last_said("kebab_vendor:zdzich")
	_ok(_stage() == 1 and vi >= 0 and r.dialogue.speakers[vi] == "U Zdzicha" and r.dialogue.hows[vi][3] == true, "J: the vendor is the board capitalized, with the tag preferred")
	# the guided first order
	_rig()
	q = r.q
	var fs: int = q.first_stand()
	if fs < 0:
		_problems.append("J: no first stand on the map")
		return
	_ok(q.first_pick(-1) == {}, "J: first_pick(-1) is empty")
	var pick: Dictionary = q.first_pick(fs)
	var want := _first_by_rules(fs)
	_ok(not pick.is_empty() and str(pick["name"]).begins_with("Marszałkowska") and pick["d"] != "praga" and float(pick["road"]) >= 150.0 and float(pick["road"]) <= 600.0, "J: the first order's door (%s, %.0f m)" % [pick.get("name", ""), pick.get("road", 0.0)])
	_ok(not want.is_empty() and pick["door"] == want["door"], "J: the first order is the door nearest 300 m by the check's own search")
	q.pin_first(fs)
	ring = _stand(fs)["ring"]
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(_stage() == 1 and q._order["door"] == pick["door"] and int(q.pinned) == -1, "J: the pinned stand's pull-in gives that door, pinned goes")
	_turn_down()
	_at(FAR)
	_f()
	q.start_kebab(fs)
	_sync()
	_ok(float(q._order["road"]) >= 400.0 and int(q.pinned) == -1, "J: the next order there is an ordinary one (400 m or more)")
	_turn_down()
	var other := 1 if fs != 1 else 0
	q.pin_first(fs)
	var oring: Vector3 = _stand(other)["ring"]
	_at(Vector2(oring.x, oring.z))
	_f()
	_ok(int(q.pinned) == fs, "J: a pull-in at another stand keeps the pin")
	_turn_down()
	_rig()
	q = r.q
	fs = q.first_stand()
	_ok(q.start_first(fs) and _stage() == 1, "J: start_first: true, the card up")
	var st := _stand(fs)
	_ok(_flat(r.car.global_position, st["ring"]) < 0.01 and r.car.vel == Vector3.ZERO, "J: start_first puts the car in the ring, standing")
	var h: Vector2 = st["heading"]
	_near(absf(angle_difference(r.car.rotation.y, atan2(-h.x, -h.y))), 0.0, 0.001, "J: facing along the heading")
	_ok(not q.start_first(fs) and not q.start_first(-1), "J: start_first is false while an order is on and for -1")
	# start_kebab
	_rig()
	q = r.q
	var n := 7
	_ok(q.start_kebab(n), "J: start_kebab(n)")
	_sync()
	_ok(int(q._order["stand"]) == posmod(n, q._stands.size()) and _flat(r.car.global_position, _stand(posmod(n, q._stands.size()))["ring"]) < 0.01 and _stage() == 1,
			"J: the stand n mod stands, the car in its ring")
	var o0: int = q.orders_started()
	q.start_kebab(n + 1)
	_ok(_stage() == 1 and q.orders_started() == o0 + 1 and int(q._order["n"]) == n + 1, "J: over an order that is on, start_kebab starts the new one (as it is today)")
	_turn_down()
	q.start_sloik(0, 1)
	_sync()
	_ok(q._station["name"] == "Dworzec Gdański" and _stage() == 1, "J: start_sloik(0, 1): Gdański")


func _tile_instances() -> int:
	var inst := 0
	for c in r.world.get_children():
		if c is MultiMeshInstance3D and not c.is_queued_for_deletion():
			inst += (c as MultiMeshInstance3D).multimesh.instance_count
	return inst


## The guided first order by the check's own rules: a Marszałkowska door not in Praga, a trip 150 to 600 m by
## road (its door 0.55 x 150 to 600 m from the ring in a straight line), the one nearest 300 m.
func _first_by_rules(i: int) -> Dictionary:
	var s := _stand(i)
	var from := Vector2(s["ring"].x, s["ring"].z)
	var dist := _graph.distances_from(_graph.e_b[int(s["edge"])], false)
	var best: Dictionary = {}
	for a: Dictionary in r.q._addresses:
		if not str(a["name"]).begins_with("Marszałkowska") or a["d"] == "praga":
			continue
		var dd: float = (a["door"] as Vector2).distance_to(from)
		if dd < 150.0 * 0.55 or dd > 600.0:
			continue
		var hit := _graph.snap(a["door"], 30.0)
		if hit.is_empty():
			continue
		var road := _graph.trip(dist, int(s["edge"]), float(s["s"]), hit[0], hit[2])
		if road >= INF or road < 150.0 or road > 600.0:
			continue
		if best.is_empty() or absf(road - 300.0) < absf(float(best["road"]) - 300.0):
			var b: Dictionary = a.duplicate()
			b["road"] = road
			best = b
	return best


# --- L. the least the game hands in -------------------------------------------------------------------------------

func _s_l_bare() -> void:
	_rig(false)
	var q: Node = r.q
	_ok(q._free() and not q.round_busy() and not q.ride_offered() and not q.side_busy(), "L: the bare rig: free, no round-up, no ride, no side job")
	_f()
	_ok(q.offer_places().size() == q._stands.size() + q._stations.size(), "L: offer_places: the stands and stations")
	_find(0, _plain_day(), "a plain order")
	var res := _deliver()
	var o: Dictionary = res["o"]
	var fare := roundi(12.0 + float(o["road"]) * 0.015)
	var tip := roundi(float(res["h"]) * (10.0 + float(o["road"]) * 0.02)) if float(res["h"]) >= 0.4 else 0
	_ok(res["money"] == fare + tip and res["stage"] == 3 and r.hud.challenge == "", "L: a delivery by hand pays as by day, no challenge")
	_close_result()
	_ok(_stage() == 0 and q._free(), "L: and is idle again")


# --- M. what deliberate breaks showed ---------------------------------------------------------------------------------

func _s_m_more() -> void:
	# the pointer and the słoiki
	_rig()
	var q: Node = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_press(1)
	var k := _lone_station(0)
	var sring: Vector3 = q._stations[k]["ring"]
	_at(Vector2(sring.x, sring.z))
	_f()
	_ok(_stage() == 1 and int(q.job) == 2 and int(q.next_stand) == -1, "M: with the pointer up a pull-in at a station starts the run, the pointer gone")
	_press(0)
	var o := _ordr()
	_ok(not q.pointing() and q.target_position() == o["ring"] and r.hud.route.size() >= 2, "M: on the run: not pointing, the target is the flat")
	# a questline during the order and the drive
	_mission = true
	_ok(q._free(), "M: a questline on during a drive: _free stays true")
	_arrive_now()
	_ok(q._free(), "M: ... and on the result card")
	_press(0)
	_f()
	_ok(not q._free(), "M: ... and false once idle")
	_mission = false
	# places_dirty
	_rig()
	q = r.q
	_f()
	var p0: int = r.hud.pois_set
	q.places_dirty()
	var vis := true
	for st in q._stands:
		vis = vis and (st["marker"] as Node3D).visible
	_ok(vis and r.hud.pois_set == p0 + 1, "M: places_dirty while free: still shown, the squares once more")
	r.rides.on = true
	_f()
	q.places_dirty()
	vis = false
	for st in q._stands:
		vis = vis or (st["marker"] as Node3D).visible
	_ok(not vis and r.hud.pois == 0, "M: places_dirty while not free: still hidden")
	# the pointer from 20 places
	_rig()
	q = r.q
	var step := maxi(1, q._addresses.size() / 20)
	var good := 0
	var tried := 0
	for a in range(0, q._addresses.size(), step):
		if tried >= 20:
			break
		tried += 1
		var door: Vector2 = q._addresses[a]["door"]
		r.car.global_position = Vector3(door.x, 0.0, door.y)
		r.car.rotation.y = 0.0
		var want := _nearest_stand(door, Vector2(0.0, -1.0))
		q.next_stand = -1
		q.point_next_stand()
		if int(q.next_stand) == want[0]:
			good += 1
		q.next_stand = -1
		q._route_off(true)
	_ok(good == tried, "M: point_next_stand from %d places: %d match the stand nearest by road" % [tried, good])
	# NASTĘPNE's stand is not cool
	for st in q._stands:
		st["cool"] = true
	_at(Vector2(q._stands[0]["ring"].x + 3.0, q._stands[0]["ring"].z))
	var idx: int = q.point_next_stand()
	_ok(idx >= 0 and not bool(_stand(idx)["cool"]), "M: NASTĘPNE's stand is not cool right after")
	# jars and bumps
	_ok(Jobs._clock_text(-3.0) == "0:00.0", "M: _clock_text of a negative time")
	var sq := _sloik_drive()
	_f(1200)
	_ok(float(sq._stress) == 0.0 and int(sq._jars) == 6, "M/G: steady driving at 15 m/s for 20 s: no stress, six jars")
	# braking at 15 m/s²: no stress; the lateral cap
	_sloik_drive()
	q = r.q
	var v := 20.0
	var top := 0.0
	_fr(v, 0.0)
	for f in 75:
		v = maxf(0.0, v - 15.0 * DT)
		_fr(v, 0.0)
		top = maxf(top, float(q._brake_s))
		_ok(float(q._stress) == 0.0, "G: braking at 15 m/s² (under 16) adds no stress")
	_ok(top > 14.5 and top < 15.5, "G: braking at 15 m/s² reads as 15 (%.1f)" % top)
	_sloik_drive()
	q = r.q
	_fr(20.0, 0.0)
	_fr(20.0, 0.1)
	_near(float(q._lat_s), 60.0 * (1.0 - exp(-DT / 0.12)), 0.0001, "M: the sideways force is capped at 60")
	_sloik_drive()
	q = r.q
	var yaw := 0.0
	_fr(20.0, yaw)
	for f in 120:
		yaw += 0.65 * DT
		_fr(20.0, yaw)
	_ok(float(q._stress) == 0.0 and absf(float(q._lat_s) - 13.0) < 0.5, "G: a turn at 13 m/s²: none (lat %.1f)" % q._lat_s)
	_sloik_drive()
	q = r.q
	yaw = 0.0
	_fr(20.0, yaw)
	for f in 60:
		yaw += 1.0 * DT
		_fr(20.0, yaw)
	_ok(float(q._stress) > 0.05, "G: a turn at 20 m/s² makes stress (%.3f)" % q._stress)
	_sloik_drive()
	q = r.q
	_fr(15.0, 0.0)
	_fr(15.0, 0.0)
	_fr(10.0, 0.0)
	_ok(float(q._brake_s) == 0.0, "G: a jump of speed over 60 m/s² in one frame is not counted")
	_sloik_drive()
	q = r.q
	q._stress = 0.5
	_f(60)
	_near(float(q._stress), 0.5 - 0.12, 0.01, "G: the stress falls 0.12 a second")
	# braking until a jar breaks
	_sloik_drive()
	q = r.q
	var broke := false
	var s_before := 0.0
	var s_after := 0.0
	for rep in 12:
		v = 20.0
		_fr(v, 0.0)
		for f in 30:
			v = maxf(0.0, v - 40.0 * DT)
			s_before = float(q._stress)
			var j0: int = q._jars
			_fr(v, 0.0)
			if int(q._jars) < j0:
				broke = true
				s_after = float(q._stress)
				break
		if broke:
			break
		for f in 20:
			_fr(20.0, 0.0)
	_ok(broke and int(q._jars) == 5, "G: hard braking breaks a jar")
	_near(s_after, 0.25, 0.03, "G: the stress 0.75 less after a jar breaks (%.2f from %.2f)" % [s_after, s_before])
	_ok(r.jars.has(1) and r.hud.toasts.back() == "Trzask! Pękł słoik · zostało 5 z 6" and r.hud.toasts_en.back() == "Crash! A jar broke · 5 of 6 left", "G: the crash toast and signal")
	var ci := _last_said("sloik_crash:")
	_ok(ci >= 0 and r.dialogue.anchors[ci] == r.car and r.dialogue.hows[ci] == [3.5, RED, 2.4, false], "G: the crash line over the car")
	# bumps
	_sloik_drive()
	q = r.q
	_fr(15.0, 0.0)
	r.jars.clear()
	r.car.bumped.emit(null, 8.0)
	_ok(r.jars == [0, 1] and int(q._jars) == 5, "G: a bump at 8 m/s: stress 1.0, a jar at once, the signal 0 then 1")
	r.jars.clear()
	_f(18)
	var s1: float = q._stress
	r.car.bumped.emit(null, 8.0)
	_ok(r.jars.is_empty() and float(q._stress) == s1, "G: a second bump 0.3 s later: nothing")
	_f(12)
	r.car.bumped.emit(null, 8.0)
	_ok(not r.jars.is_empty(), "G: 0.5 s later: counted")
	_sloik_drive()
	q = r.q
	_fr(15.0, 0.0)
	r.jars.clear()
	r.car.bumped.emit(null, 2.9)
	_ok(r.jars == [0] and float(q._stress) == 0.0, "G: a bump at 2.9 m/s: the signal 0, no stress")
	# the warning
	_sloik_drive()
	q = r.q
	_fr(15.0, 0.0)
	var warns := 0
	for f in 360:
		q._stress = 0.7
		_fr(15.0, 0.0)
	warns = _count(r.dialogue.said, "sloik_bump:")
	_ok(warns == 1, "G: the warning once in 6 s (%d)" % warns)
	var wi := _last_said("sloik_bump:")
	_ok(wi >= 0 and r.dialogue.hows[wi] == [2.5, AMBER, 2.4, false], "G: the warning's line")
	for f in 70:
		q._stress = 0.7
		_fr(15.0, 0.0)
	_ok(_count(r.dialogue.said, "sloik_bump:") == 2, "G: and again after 7 s")
	# a new run starts with the warning's wait at 0
	r.hud.abort_pressed.emit()
	_press(0)
	_f()
	var sk := _lone_station(0)
	q.start_sloik(0, sk)
	_sync()
	_press(0)
	_by(_ring_of(_ordr()), 800.0, 15.0)
	_fr(15.0, 0.0)
	var w1 := _count(r.dialogue.said, "sloik_bump:")
	q._stress = 0.7
	_fr(15.0, 0.0)
	_ok(_count(r.dialogue.said, "sloik_bump:") == w1 + 1, "M: a second run's first warning comes at once")
	# no jars left: no seventh toast, no warning
	_rig()
	q = r.q
	q.start_sloik(9, 1)
	_sync()
	_press(0)
	_ok(int(q._jars) == 0 and q._station["name"] == "Dworzec Gdański", "G: start_sloik(9, 1): no jars at Gdański")
	_by(_ring_of(_ordr()), 800.0, 15.0)
	_fr(15.0, 0.0)
	var t0: int = r.hud.toasts.size()
	for f in 10:
		r.car.bumped.emit(null, 8.0)
		_f(30)
		q._stress = 0.7
		_f(30)
	_ok(float(q._stress) < 1.0 and r.hud.toasts.size() == t0 and _count(r.dialogue.said, "sloik_bump:") == 0, "M: with no jar left: no toast, no warning, the stress under 1")
	_rig()
	q = r.q
	q.start_sloik(2, 0)
	_sync()
	_press(0)
	_ok(int(q._jars) == 4, "G: start_sloik(2, 0): four jars")
	# bumps with the card up, on a kebab, on the result card
	_rig()
	q = r.q
	q.start_sloik(0, 0)
	_sync()
	r.jars.clear()
	r.car.bumped.emit(null, 8.0)
	_ok(r.jars.is_empty() and float(q._stress) == 0.0, "M: a bump with the order's card up: nothing")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_press(0)
	_drive_far(5)
	r.car.bumped.emit(null, 8.0)
	_ok(r.jars.is_empty() and float(q._stress) == 0.0, "M: a bump on a kebab's drive: nothing")
	# delivered słoiki
	for jars in [6, 3, 2, 5]:
		_rig()
		q = r.q
		var kk := _lone_station(0)
		q.start_sloik(0, kk)
		_sync()
		_press(0)
		_by(_ring_of(_ordr()), 300.0, 10.0)
		_f(30)
		q._jars = jars
		var m0: int = r.wallet.money
		var z0: int = r.wallet.respect
		var kinds0: int = r.wallet.kinds.size()
		_arrive_now()
		var oo := _ordr()
		var clock: float = q._clock
		var pay: int = 40 + 30 * jars
		_ok(r.wallet.money - m0 == pay and r.wallet.respect - z0 == (30 if jars == 6 else 0) and r.wallet.kinds.size() == kinds0 + 1 \
				and r.wallet.kinds.back() == "sloik", "G: %d jars pay %d zł and respect" % [jars, pay])
		var group := "sloik_done:" if jars >= 3 else "sloik_broken:"
		var li := _last_said(group + ("all" if jars == 6 else "some"))
		_ok(li >= 0 and r.dialogue.hows[li] == [5.0, TEAL if jars >= 3 else RED, 3.6, false], "G: %d jars: the line %s and its colour" % [jars, group])
		_ok(r.hud.card == "DOWIEZIONE · %d/6 SŁOIKÓW" % jars and r.hud.card_en == "Delivered · %d/6 jars" % jars and r.hud.accent == (TEAL if jars >= 3 else RED) \
				and r.hud.button_words == PackedStringArray(["OK"]) and r.hud.low and r.hud.card_is(q), "G: %d jars: the card" % jars)
		_ok(r.hud.body == "„Słowo”\n%s, %s: %s\nKurs 40 zł + %d × 30 zł za słoiki = %d zł · w portfelu %s" % [oo["customer"], oo["name"], _ct(clock), jars, pay, _zl(r.wallet.money)] \
				and r.hud.body_en == "A word\n%s · fare 40 zł + %d jars × 30 zł = %d zł" % [_ct(clock), jars, pay], "G: %d jars: the words (%s)" % [jars, r.hud.body])
		_ok(r.wallet.best.has("sloik") == (jars == 6), "G: the record only with all six")
		_ok(not r.director.secondary(), "G: the K key on a słoiki result: false")
		var pr: bool = r.director.primary()
		var all_vis := true
		for st in q._stations:
			all_vis = all_vis and (st["person"] as Node3D).visible
		_ok(pr and _stage() == 0 and all_vis, "G: the M key closes it, the newcomers are back (%s, stage %d, vis %s)" % [pr, _stage(), all_vis])
		if jars == 5:
			_ok(not r.wallet.best.has("sloik"), "G: a run with 5 jars never sets the record")
	# the second run's words about the record
	_rig()
	q = r.q
	var records: Array = []
	for frames in [60, 30, 120, 90]:
		var kk := _lone_station(0)
		q.start_sloik(0, kk)
		_sync()
		_press(0)
		_by(_ring_of(_ordr()), 300.0, 10.0)
		_f(frames)
		var best_before: float = r.wallet.best_time("sloik")
		_arrive_now()
		records.append([best_before, float(q._clock), r.hud.body, r.hud.body_en])
		_press(0)
		_at(FAR)
		_f(2)
	_ok(not str(records[0][2]).contains("rekord") and str(records[1][2]).ends_with(" · nowy rekord!") or str(records[1][2]).contains(" · nowy rekord!") and str(records[1][3]).contains(" · new best!"),
			"G: a faster full run after a first: nowy rekord / new best")
	_ok(str(records[2][2]).contains(" · rekord z kompletem %s" % _ct(float(records[1][1]))) and str(records[2][3]).contains(" · best with every jar %s" % _ct(float(records[1][1]))),
			"G: a slower full run: the best with every jar")
	# the heat at the door: warm and cold
	for kase in [[0.41, true], [0.39, false]]:
		_rig()
		q = r.q
		_find(0, _plain_day(), "a plain order")
		_press(0)
		_drive_far(5)
		var m0: int = r.wallet.money
		var z0: int = r.wallet.respect
		q._heat = kase[0]
		_arrive_now()
		_ok((r.wallet.respect - z0 == 10) == kase[1] and r.hud.accent == (ORANGE if kase[1] else ICE) and r.hud.card.ends_with("CIEPŁY" if kase[1] else "ZIMNY") \
				and (r.wallet.money - m0 > 0), "M: heat %.2f at the door is %s" % [kase[0], "warm" if kase[1] else "cold"])
	# presses of a button the card does not have
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	r.hud.abort_pressed.emit()
	q.card_pressed(1)
	_ok(_stage() == 0 and r.hud.card == "" and not q.pointing(), "M: button 1 on a dropped card: closes it, no pointer")
	_rig()
	q = r.q
	q.start_sloik(0, 0)
	_sync()
	_press(0)
	_arrive_now()
	q.card_pressed(1)
	_ok(_stage() == 0 and not q.pointing(), "M: button 1 on a słoiki result: closes it, no pointer")
	# zag_stambul by day and the autopilot's flags
	_rig()
	q = r.q
	_ok(not q.drive_player(), "M: drive_player false while idle with the autopilot off")


# --- H. the courier beside an order -------------------------------------------------------------------

## The first order from `from` on (by `step`) that `fits` and that the rider has a fitting way to
## (the challenge is up two frames after the card; the others are turned down); -1 and a problem when none in 200.
func _h_up(from: int, fits := Callable(), step := 1) -> int:
	for k in 200:
		var n := from + k * step
		r.q.start_kebab(n)
		if _stage() == 0:
			continue
		_sync()
		if (fits.is_null() and _plain(r.q._order)) or (not fits.is_null() and bool(fits.call(r.q._order))):
			_f(2)
			if int(r.q.courier.state) == 2:
				return n
		_turn_down()
	_problems.append("H: no order from %d on has a rider's way" % from)
	return -1


func _h_rig(speed := -1.0) -> void:
	_rig()
	r.q.courier.force = true
	if speed > 0.0:
		r.q.courier.speed = speed
		r.q.courier.fixed_speed = true


func _s_h_courier() -> void:
	_h_rig()
	var q: Node = r.q
	var c: Node = q.courier
	var n0 := _h_up(700)
	if n0 < 0:
		return
	var o := _ordr()
	var ring := _ring_of(o)
	_ok(r.hud.challenge == "WYŚCIG · PĘDZIK" and r.hud.challenge_accent == Color("#c23a7e") \
			and r.hud.challenge_sub == "Do drzwi klienta. Dotknij albo L" and r.hud.challenge_sub_en == "To the door. Tap or L", "H1: the challenge's words (%s)" % r.hud.challenge)
	_ok(c._rider.visible and c._rider.is_inside_tree() and _stage() == 1 and r.hud.card != "", "H1: the rider is in the world, the order is still on its card")
	_ok(r.dialogue.said.has("pedzik:challenge"), "H1: the rider says his challenge")
	# left alone
	_f(352)
	_ok(int(c.state) == 2 and r.hud.challenge != "", "H2: still up at 5.9 s")
	_f(12)
	_ok(int(c.state) == 0 and r.hud.challenge == "" and not c._rider.visible and _stage() == 1 and r.hud.card != "", "H2: gone after 6 s, the order still on its card")
	_ok(not q.flash() and _stage() == 1, "H2: L takes nothing then")
	# L takes it
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	o = _ordr()
	ring = _ring_of(o)
	_f(30)
	var flashes0: int = r.car.flashes
	_ok(q.flash(), "H3: L takes the challenge")
	_ok(r.hud.card == "" and _stage() == 2 and int(c.state) == 3 and r.hud.challenge == "" and r.car.flashes == flashes0 + 1 \
			and q._beacon.visible, "H3: the order goes, the challenge is down, the car flashed, the ring is at the door")
	_ok(q._beacon.waving, "H3: the customer at the door waves")
	_ok(float(c.road) == float(o["road"]) and absf(float(c.speed) - CourierRace.pace(float(c.path_len), float(o["road"]))) < 0.0001, "H3: the rider's pace is the one for this order's road")
	_by(ring, 250.0, 10.0)
	_f(60)
	var behind: bool = float(c._player_left) <= float(c._rider_left)
	_ok(r.hud.badge == ("1ST" if behind else "2ND"), "H3: the badge (%s)" % r.hud.badge)
	if behind:
		_ok(r.hud.status.begins_with("Pędzik: ") and r.hud.status.ends_with(" m za tobą") and r.hud.hint_en.begins_with("The courier is ") \
				and r.hud.hint_en.ends_with(" m behind"), "H3: the race hint, ahead (%s)" % r.hud.status)
	else:
		_ok(r.hud.status.begins_with("Pędzik: ") and r.hud.status.ends_with(" m przed tobą") and r.hud.hint_en.begins_with("The courier is ") \
				and r.hud.hint_en.ends_with(" m ahead"), "H3: the race hint, behind (%s)" % r.hud.status)
	_fly = true
	_f()
	_ok(r.hud.status == "Wyląduj i weź auto: zamówienie jedzie autem", "H3: flying in the race: the landing hint")
	_fly = false
	_by(ring, 10.0, 6.5)
	_f()
	_ok(r.hud.status == "Stań pod drzwiami" and r.hud.hint_en == "Stop at the door" and _stage() == 2, "H3: inside the ring rolling: stop at the door, not the courier's")
	# won
	_by(ring, 250.0, 10.0)
	_f(5)
	var won0: int = c.won
	var pays0: int = r.wallet.payments.size()
	var pedzik0 := 0
	for w in r.dialogue.said:
		if w.begins_with("pedzik:") and w != "pedzik:challenge":
			pedzik0 += 1
	_arrive_now()
	_ok(r.hud.body.ends_with("\nPędzik w tyle: +30 zł, +30 szacunku") and r.hud.body_en.ends_with("\nYou beat the courier: +30 zł, +30 respect"), "H4: the won race on the card (%s)" % r.hud.body)
	var courier_pays := 0
	for pay in r.wallet.payments.slice(pays0):
		if pay[2] == "courier" and pay[0] == 30 and pay[1] == 30:
			courier_pays += 1
	_ok(courier_pays == 1 and r.wallet.kinds.has("kebab"), "H4: the kebab's pay and the courier's own 30 zł and 30 respect")
	var pedzik1 := 0
	for w in r.dialogue.said:
		if w.begins_with("pedzik:") and w != "pedzik:challenge":
			pedzik1 += 1
	_ok(pedzik1 == pedzik0 + 1 and int(c.state) == 4 and c.won == won0 + 1, "H4: the rider's line, the race done, one more won")
	_close_result()
	_f(440)
	_ok(int(c.state) == 4 and c._rider.visible and _stage() == 0 and int(q.phase) == Activity.Phase.IDLE, "H4: at 7.5 s the rider still stands at the door, the job idle")
	_f(50)
	_ok(int(c.state) == 0 and not c._rider.visible and _stage() == 0, "H4: at 8.1 s he is gone")
	# a new order while the last race's rider still stands at his door
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	_f(10)
	q.flash()
	_arrive_now()
	_close_result()
	_ok(int(c.state) == 4 and c._rider.visible, "H6: the rider stands at the last door")
	_f(60)
	q.start_kebab(n0 + 1)
	_ok(int(c.state) != 4 and not c._rider.visible, "H6: a new order takes the rider from the last door")
	# the button, and a race lost
	_h_rig(400.0)
	q = r.q
	c = q.courier
	_h_up(n0)
	o = _ordr()
	ring = _ring_of(o)
	var won1: int = c.won
	r.hud.challenge_pressed.emit()
	_ok(_stage() == 2 and int(c.state) == 3, "H5: the button takes the challenge as L does")
	_by(ring, 250.0, 0.0)
	_f(360)
	_ok(c.rider_first and r.hud.badge == "2ND" and r.hud.status == "Pędzik już pod drzwiami. Dowieź i tak" \
			and r.hud.hint_en == "The courier is at the door. Deliver anyway", "H5: six seconds on the rider is at the door (%s)" % r.hud.status)
	var pays1: int = r.wallet.payments.size()
	var pedzik2: int = r.dialogue.said.size()
	_arrive_now()
	_ok(r.hud.body.ends_with("\nPędzik był pierwszy. Kebab i tak dojechał") and r.hud.body_en.ends_with("\nThe courier got there first. The kebab still made it"), "H5: the lost race on the card (%s)" % r.hud.body)
	var any_courier := false
	for pay in r.wallet.payments.slice(pays1):
		any_courier = any_courier or pay[2] == "courier"
	var said_pedzik := false
	for w in r.dialogue.said.slice(pedzik2):
		said_pedzik = said_pedzik or w.begins_with("pedzik:")
	_ok(not any_courier and c.won == won1 and not said_pedzik, "H5: a lost race pays nothing and the rider says nothing")
	# the order's ends take the challenge with them
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	_press(1)
	_ok(int(c.state) == 0 and r.hud.challenge == "" and not c._rider.visible, "H6: NOT NOW takes the challenge down")
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	r.hud.abort_pressed.emit()
	_ok(int(c.state) == 0 and r.hud.challenge == "" and not c._rider.visible and r.hud.card == "ZAMÓWIENIE PRZEPADŁO", "H6: the ✕ on the order card takes the challenge down")
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	o = _ordr()
	_press(0)
	_by(_ring_of(o), 250.0, 10.0)
	_f(10)
	r.hud.abort_pressed.emit()
	_ok(int(c.state) == 0 and not c._rider.visible and r.hud.card == "ZAMÓWIENIE PRZEPADŁO" and _stage() == 3, "H6: the ✕ in a race: no race, the dropped order's card")
	# GO first, then L
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	_press(0)
	_ok(_stage() == 2 and int(c.state) == 2 and r.hud.challenge != "", "H7: GO leaves the challenge up")
	_f(30)
	var clock0: float = q._clock
	var heat0: float = q._heat
	_ok(q.flash() and int(c.state) == 3, "H7: L after GO takes it")
	_ok(float(q._clock) == clock0 and float(q._heat) == heat0 and _stage() == 2, "H7: the delivery is not started again")
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	_press(0)
	_f(366)
	_ok(int(c.state) == 0 and r.hud.challenge == "" and _stage() == 2, "H7: nobody presses L: gone 6 s after, the delivery goes on")
	_h_rig()
	q = r.q
	c = q.courier
	_h_up(n0)
	o = _ordr()
	var sring: Vector3 = _stand(int(o["stand"]))["ring"]
	_by(sring, 15.0, 4.0)
	_f()
	_ok(_stage() == 2 and int(c.state) == 2 and r.hud.challenge != "", "H7: the order that goes as the car drives off keeps the challenge up")
	# no way for the rider
	_h_rig()
	q = r.q
	c = q.courier
	c.paths = []
	var n8 := _find(n0, _plain_day(), "a plain order")
	_f(2)
	_ok(n8 >= 0 and int(c.state) == 0 and r.hud.challenge == "" and _stage() == 1, "H8: no footways: no challenge, the order is on")
	_h_night()
	_h_beside()


## H9: the night's roll.
func _h_night() -> void:
	_rig()
	var q: Node = r.q
	var c: Node = q.courier
	var size: int = q._stands.size()
	var rolled: Array[int] = []
	var plain: Array[int] = []
	for n in range(1, 400):
		if CourierRace.roll(n) < 0.25:
			rolled.append(n)
		elif plain.size() < 3:
			plain.append(n)
	# by day a rolled order is not challenged
	var seen := false
	for n in rolled.slice(0, 6):
		q.start_kebab(n)
		if _stage() == 0:
			continue
		_sync()
		_f(2)
		seen = seen or int(c.state) != 0
		_turn_down()
	_ok(not seen, "H9: by day a rolled order is not challenged")
	r.tod.mode = 2
	seen = false
	for n in plain.slice(0, 3):
		q.start_kebab(n)
		if _stage() == 0:
			continue
		_sync()
		_f(2)
		seen = seen or int(c.state) != 0
		_turn_down()
	_ok(not seen, "H9: by night a plain order is not challenged")
	# a rolled order with two couriers waiting at its stand
	var found := -1
	var at := Vector3.ZERO
	var i := -1
	for n in rolled:
		i = posmod(n, size)
		at = _stand(i)["at"]
		r.life.waiting = {i: [[at + Vector3(4, 0, 1), 0.4], [at + Vector3(2, 0, 1.5), 1.1]]}
		q.start_kebab(n)
		if _stage() == 0:
			continue
		_sync()
		if _plain(q._order):
			_f(2)
			if int(c.state) == 2:
				found = n
				break
		_turn_down()
	if found < 0:
		_problems.append("H9: no rolled order with a rider's way and a courier waiting")
		return
	_ok(not c._rider.visible and not c._waiter.is_empty() and r.hud.challenge != "", "H9: by night with couriers waiting: the challenge, the rider's node hidden")
	_ok(q.flash() and c._rider.visible and r.life.taken == [i] and (r.life.waiting[i] as Array).size() == 1, "H9: L: the rider shows, one courier taken from the stand")
	# the same order by day, with the couriers waiting there
	_rig()
	r.q.courier.force = false
	r.life.waiting = {i: [[at + Vector3(4, 0, 1), 0.4], [at + Vector3(2, 0, 1.5), 1.1]]}
	r.q.start_kebab(found)
	_sync()
	_f(2)
	_ok(int(r.q.courier.state) == 0 and r.hud.challenge == "", "H9: by day a rolled order is not challenged though couriers wait")
	# the same order with nobody waiting
	_rig()
	r.q.courier.force = false
	r.tod.mode = 2
	r.q.start_kebab(found)
	_sync()
	_f(2)
	_ok(int(r.q.courier.state) == 0 and r.hud.challenge == "", "H9: by night, a rolled order with nobody waiting: none")


## H10: beside a słoiki run never; at the craft shop as anywhere.
func _h_beside() -> void:
	_h_rig()
	var q: Node = r.q
	var c: Node = q.courier
	q.start_sloik(0, 0)
	_sync()
	_f(3)
	_ok(int(c.state) == 0 and r.hud.challenge == "", "H10: no challenge on a słoiki run's card")
	_press(0)
	_f(30)
	_ok(int(c.state) == 0 and _stage() == 2 and not q.flash(), "H10: nor on the run")
	_h_rig()
	q = r.q
	c = q.courier
	var crafts := func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen"
	var nc := _h_up(_n_of("zag_rozen"), crafts, q._stands.size())
	if nc < 0:
		return
	_ok(bool(q._order.get("craft", false)) and r.hud.challenge != "", "H10: the craft kebab's order is challenged like any other")
	_f(30)
	_ok(q.flash() and _stage() == 2 and int(c.state) == 3 and not bool(q._order.get("premium", false)) and float(q._craft_t) == 0.0, "H10: L on the craft card: the plain kebab goes at once")
	_h_rig()
	q = r.q
	c = q.courier
	nc = _h_up(_n_of("zag_rozen"), crafts, q._stands.size())
	_press(0)
	_f(30)
	_ok(float(q._craft_t) > 0.0 and _stage() == 1 and int(c.state) == 2, "H10: POCZEKAM: the wait is on, the challenge still up")
	_ok(q.flash() and _stage() == 2 and int(c.state) == 3 and not bool(q._order.get("premium", false)) and float(q._craft_t) == 0.0, "H10: L in the wait: the plain kebab goes, the wait is over")


# --- N. what the breaks of the first round showed ------------------------------------------------------

## The orders made straight (no card): the reach of the roads, the names, the lines the dialogue is asked for.
func _s_n_orders() -> void:
	_rig()
	var q: Node = r.q
	_ok(Array(Jobs.CUSTOMERS) == NAMES and Array(Jobs.NEWCOMERS) == NEWCOMERS, "N: the customers' and the newcomers' names, in their order")
	var min_road := INF
	var under_500 := 0
	var max_across := 0.0
	var over_3000 := 0
	var names := {}
	var made := 0
	var lines_fine := true
	var across_rule := true
	var west_across := 0
	var praga_not_across := 0
	var dists := {}
	var dists_links := {}
	var roads_fine := true
	var shorter_with_links := 0
	var plain: Array[int] = []
	for i in q._stands.size():
		if str(_stand(i)["zag"]) == "":
			plain.append(i)
	for i in plain:
		for k in 4:
			var asks0: int = r.dialogue.line_asks.size()
			var o: Dictionary = q._make_kebab_order(i, k * 37 + 5)
			if o.is_empty():
				continue
			made += 1
			var road := float(o["road"])
			if bool(o["reached"]):
				if not dists.has(i):
					dists[i] = _graph.distances_from(_graph.e_b[int(_stand(i)["edge"])], false)
					dists_links[i] = _graph.distances_from(_graph.e_b[int(_stand(i)["edge"])], true)
				var trip_f: float = _graph.trip(dists[i], int(_stand(i)["edge"]), float(_stand(i)["s"]), int(o["edge"]), float(o["s"]))
				var trip_t: float = _graph.trip(dists_links[i], int(_stand(i)["edge"]), float(_stand(i)["s"]), int(o["edge"]), float(o["s"]))
				roads_fine = roads_fine and absf(trip_f - road) < 0.01
				shorter_with_links += 1 if trip_t < trip_f - 0.5 else 0
			min_road = minf(min_road, road)
			under_500 += 1 if road < 500.0 else 0
			names[str(o["customer"])] = true
			if bool(o["across"]):
				max_across = maxf(max_across, road)
				over_3000 += 1 if road > 3000.0 else 0
			if r.dialogue.line_asks.size() != asks0 + 1:
				lines_fine = false
				continue
			var kind := "praga" if o["d"] == "praga" else ("office" if bool(o["office"]) else str(o["d"]))
			var want_prefer: bool = bool(_stand(i)["across"]) != (o["d"] == "praga")
			lines_fine = lines_fine and r.dialogue.line_asks[asks0] == "kebab_order:" + kind and r.dialogue.line_prefers[asks0] == bool(o["across"]) and bool(o["across"]) == want_prefer
			if bool(_stand(i)["across"]):
				west_across += 1 if bool(o["across"]) else 0
				praga_not_across += 0 if bool(o["across"]) else 1
			across_rule = across_rule and (str(o["customer"]) in NAMES)
	_ok(made > 100, "N: orders made straight (%d)" % made)
	_ok(roads_fine, "N: every reached order's road is the roads on the map, not the links off it (%d of the %d are shorter with the links)" % [shorter_with_links, made])
	_notes.append("%d of %d orders are shorter by the links off the map" % [shorter_with_links, made])
	_ok(min_road >= 400.0 and under_500 > 0, "N: no order under 400 m by road, some under 500 (min %.0f, %d under 500)" % [min_road, under_500])
	_ok(max_across <= 3600.0 and over_3000 > 0, "N: no across order over 3600 m, some over 3000 (max %.0f, %d)" % [max_across, over_3000])
	_ok(lines_fine, "N: each order asks its own line: office, Praga or its district, the river line preferred exactly when across")
	_ok(names.size() >= 3 and across_rule, "N: the customers differ (%d names)" % names.size())
	# a stand of Praga's: its order to a Praga door is not across
	var praga_stand := -1
	for i in plain:
		if bool(_stand(i)["across"]):
			praga_stand = i
			break
	if praga_stand >= 0:
		var seen_praga := false
		var seen_west := false
		for k in 40:
			var o: Dictionary = q._make_kebab_order(praga_stand, k * 11 + 1)
			if o.is_empty():
				continue
			if o["d"] == "praga":
				seen_praga = true
				_ok(not bool(o["across"]), "N: from a stand in Praga a Praga door is not across")
			else:
				seen_west = true
				_ok(bool(o["across"]), "N: from a stand in Praga the west bank is across")
		_ok(seen_praga or seen_west, "N: a stand of Praga's made orders")
	else:
		_notes.append("no stand of Praga's")
	# the line's own customer
	_rig()
	q = r.q
	var kinds := {"office": true, "praga": true}
	for a: Dictionary in q._addresses:
		kinds[str(a["d"])] = true
	for kd in kinds:
		r.dialogue.line_notes["kebab_order:" + str(kd)] = {"customer": "Pan Zenek"}
	var zenek := 0
	for k in 6:
		var o: Dictionary = q._make_kebab_order(plain[k], 3)
		zenek += 1 if not o.is_empty() and o["customer"] == "Pan Zenek" else 0
	_ok(zenek >= 5, "N: a customer the line names is the customer (%d of 6)" % zenek)
	# the card's words: the river and the night
	_rig()
	q = r.q
	var n_across := _find(0, func(o: Dictionary) -> bool: return _plain(o) and bool(o["across"]) and not bool(o["office"]), "an across plain order")
	if n_across >= 0:
		var oa := _ordr()
		_ok(r.hud.body == _plain_body(oa, false)[0] and r.hud.body_en == _plain_body(oa, false)[1] and r.hud.body.contains("Za rzeką: „w sumie to centrum”."), "N: the across order's card has the river words (%s)" % r.hud.body)
		_turn_down()
	r.tod.mode = 2
	var n_night := _find(0, func(o: Dictionary) -> bool: return _plain(o) and not bool(o["across"]), "a night order")
	if n_night >= 0:
		var on := _ordr()
		_ok(r.hud.body == _plain_body(on, true)[0] and r.hud.body_en == _plain_body(on, true)[1] and r.hud.body_en.ends_with(" Night pays ×1.5."), "N: the night's order card has its words (%s)" % r.hud.body_en)
		_turn_down()
	# a shop whose pay is not over 1.0 names no set; the royal one does
	_rig()
	q = r.q
	var shop_n := _find(_n_of("zag_stambul"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_stambul" and not bool(o["across"]), "a Stambuł order", q._stands.size())
	if shop_n >= 0:
		var os := _ordr()
		_ok(r.hud.body == _plain_body(os, false)[0], "N: a shop that pays no more than a stand names no set (%s)" % r.hud.body)
		_turn_down()
	# the second order in a rig says its own line, and starts its count-down again
	_rig()
	q = r.q
	q.start_kebab(2)
	_sync()
	_f()
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9", "N: the first order counts from 9")
	var said0: int = r.bubbles.said.size()
	_turn_down()
	q.start_kebab(3)
	_sync()
	_f()
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9" and r.hud.button_words_en[0] == "GO! · 9", "N: the second order counts down from 9 in its first frame")
	_f(160)
	_ok(r.bubbles.said.size() == said0 + 1 and r.bubbles.colours.back() == ORANGE, "N: the second order's line is said, 2.6 s after its card, in the stand's orange")
	_rig()
	q = r.q
	q.start_kebab(2)
	_sync()
	_f(165)
	var said1: int = r.bubbles.said.size()
	_ok(said1 > 0, "N: the first order says its line 2.6 s after its card")
	_turn_down()
	q.start_kebab(3)
	_sync()
	_f(165)
	_ok(r.bubbles.said.size() == said1 + 1, "N: so does the second order after it")
	# a stand's order numbers
	_rig()
	q = r.q
	q.start_kebab(5)
	_sync()
	_turn_down()
	var k0 := _lone_stand()
	var ring: Vector3 = _stand(k0)["ring"]
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(_stage() == 1 and int(q._order["n"]) == 1, "N: a pull-in's order is numbered by the orders so far (%s)" % str(q._order.get("n")))
	_turn_down()
	_at(FAR)
	_f(2)
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(_stage() == 1 and int(q._order["n"]) == 2, "N: and the next one by one more")


## The guided first order (left 4 and 5, 6), `start_*` with no address, the car put in a place.
func _s_n_first() -> void:
	_rig()
	var q: Node = r.q
	var fs: int = q.first_stand()
	if fs < 0:
		return
	var at_real: Vector3 = _stand(fs)["at"]
	# first_stand: the stand nearest (-1060, -230) within 120 m, by the check's own search
	var best := -1
	var best_d := 120.0
	for i in q._stands.size():
		var d := Vector2(_stand(i)["at"].x, _stand(i)["at"].z).distance_to(Vector2(-1060.0, -230.0))
		if d < best_d:
			best_d = d
			best = i
	_ok(best == fs, "N: the first stand is the one nearest the corner (%d, wanted %d)" % [fs, best])
	var pois: Array = _data["pois"]
	var real_poi := -1
	var near_d := INF
	for k in pois.size():
		if str(pois[k]["k"]) == "kebab":
			var d := Vector2(float(pois[k]["x"]), float(pois[k]["z"])).distance_to(Vector2(-1060.0, -230.0))
			if d < near_d:
				near_d = d
				real_poi = k
	var made_up := _made_up_poi(real_poi, at_real)
	if made_up.is_empty():
		_notes.append("no made-up kebab place found for first_stand")
	else:
		var p2: Array = pois.duplicate()
		p2.append(made_up)
		var d2 := _data.duplicate(false)
		d2["pois"] = p2
		_rig(true, {}, {"data": d2})
		q = r.q
		var two: int = q.first_stand()
		_ok(two >= 0 and (_stand(two)["at"] as Vector3).is_equal_approx(at_real), "N: with a second kebab place nearer the corner's far side, still the real one")
		var p3: Array = []
		for k in pois.size():
			if k != real_poi:
				p3.append(pois[k])
		p3.append(made_up)
		d2["pois"] = p3
		_rig(true, {}, {"data": d2})
		q = r.q
		var one: int = q.first_stand()
		_ok(one >= 0 and not (_stand(one)["at"] as Vector3).is_equal_approx(at_real), "N: with the real place gone, the made-up one within 120 m is the first stand")
	var p4: Array = []
	for k in pois.size():
		if not (str(pois[k]["k"]) == "kebab" and Vector2(float(pois[k]["x"]), float(pois[k]["z"])).distance_to(Vector2(-1060.0, -230.0)) <= 200.0):
			p4.append(pois[k])
	var d4 := _data.duplicate(false)
	d4["pois"] = p4
	_rig(true, {}, {"data": d4})
	_ok(r.q.first_stand() == -1, "N: with every kebab place within 200 m of the corner gone: no first stand")
	# the first order's reach
	_rig()
	q = r.q
	fs = q.first_stand()
	var all := _first_list(fs, false)
	var street := _first_list(fs, true)
	if street.is_empty():
		_problems.append("N: the first order has no door on its street in reach")
		return
	var base: Dictionary = q.first_pick(fs)
	# doors 150 to 450 m by road taken out: the pick is 450 to 600
	var far_doors: Array = []
	var kept: Array = []
	var fits_far := 0
	for a: Dictionary in all:
		if float(a["road"]) >= 450.0:
			fits_far += 1
	var far_street := 0
	for a: Dictionary in street:
		if float(a["road"]) >= 450.0:
			far_street += 1
	var near_set := {}
	for a: Dictionary in all:
		if float(a["road"]) < 450.0:
			near_set[a["door"]] = true
	var rest: Array = []
	for a: Dictionary in q._addresses:
		if not near_set.has(a["door"]):
			rest.append(a)
	_set_addrs(q, rest)
	var pk: Dictionary = q.first_pick(fs)
	if fits_far > 0:
		_ok(not pk.is_empty() and float(pk["road"]) >= 450.0 and float(pk["road"]) <= 600.0, "N: with the doors up to 450 m gone the pick is 450 to 600 m (%s)" % str(pk.get("road")))
	else:
		_notes.append("no first-order door 450 to 600 m")
	# every door 150 to 600 m by road gone: none
	_rig()
	q = r.q
	var reach := {}
	for a: Dictionary in all:
		reach[a["door"]] = true
	var rest2: Array = []
	for a: Dictionary in q._addresses:
		if not reach.has(a["door"]):
			rest2.append(a)
	_set_addrs(q, rest2)
	_ok(q.first_pick(fs) == {}, "N: with every door 150 to 600 m by road gone there is no first order (nearer ones stay)")
	# 100 copies of a worse door first
	_rig()
	q = r.q
	var worst: Dictionary = street[0]
	for a: Dictionary in street:
		if absf(float(a["road"]) - 300.0) > absf(float(worst["road"]) - 300.0):
			worst = a
	var copies: Array = []
	for k in 100:
		copies.append(_address_of(q, worst))
	var rest3: Array = copies.duplicate()
	rest3.append_array(q._addresses)
	_set_addrs(q, rest3)
	var pk3: Dictionary = q.first_pick(fs)
	_ok(not pk3.is_empty() and pk3["door"] == base["door"], "N: with 100 worse copies of a door first the pick is still the door nearest 300 m")
	# two fitting doors left: the one nearer 300 m by road wins over the one nearer 350
	var b2: Dictionary = {}
	var c2: Dictionary = {}
	for a: Dictionary in street:
		if float(a["road"]) <= 320.0 and (b2.is_empty() or absf(float(a["road"]) - 300.0) < absf(float(b2["road"]) - 300.0)):
			b2 = a
	for a: Dictionary in street:
		if float(a["road"]) > 325.0 and (c2.is_empty() or absf(float(a["road"]) - 350.0) < absf(float(c2["road"]) - 350.0)):
			c2 = a
	if not b2.is_empty() and not c2.is_empty() and absf(float(b2["road"]) - 350.0) > absf(float(c2["road"]) - 350.0):
		_rig()
		q = r.q
		_set_addrs(q, [_address_of(q, b2), _address_of(q, c2)])
		var pk4: Dictionary = q.first_pick(fs)
		_ok(not pk4.is_empty() and pk4["door"] == b2["door"], "N: with two doors left the one nearer 300 m by road wins (%s)" % str(pk4.get("road")))
	else:
		_notes.append("no pair of doors for the 300 against 350 m")
	# no Marszałkowska door in reach: any door not in Praga
	_rig()
	q = r.q
	var rest5: Array = []
	for a: Dictionary in q._addresses:
		if not str(a["name"]).begins_with("Marszałkowska"):
			rest5.append(a)
	_set_addrs(q, rest5)
	var pk5: Dictionary = q.first_pick(fs)
	_ok(not pk5.is_empty() and pk5["d"] != "praga" and float(pk5["road"]) >= 150.0 and float(pk5["road"]) <= 600.0, "N: with no Marszałkowska door the pick is any door in reach, not in Praga")
	# none in reach at all: an ordinary order that is never across
	_rig()
	q = r.q
	var ring: Vector3 = _stand(fs)["ring"]
	var rest6: Array = []
	for a: Dictionary in q._addresses:
		if (a["door"] as Vector2).distance_to(Vector2(ring.x, ring.z)) > 600.0:
			rest6.append(a)
	_set_addrs(q, rest6)
	_ok(q.first_pick(fs) == {}, "N: with every door within 600 m gone there is no first pick")
	var across_first := 0
	var across_plain := 0
	for k in 40:
		var of: Dictionary = q._make_kebab_order(fs, fs + k * q._stands.size(), true)
		across_first += 1 if not of.is_empty() and bool(of["across"]) else 0
		var ou: Dictionary = q._make_kebab_order(fs, fs + k * q._stands.size(), false)
		across_plain += 1 if not ou.is_empty() and bool(ou["across"]) else 0
	if across_plain > 0:
		_ok(across_first == 0, "N: the guided order with no door in reach is an ordinary one that is never across (%d of 40, unguided %d)" % [across_first, across_plain])
	else:
		_notes.append("the first stand has no across orders")
	# start_first, start_kebab, start_sloik with no address at all
	_rig()
	q = r.q
	q._addresses.clear()
	fs = q.first_stand()
	_ok(not q.start_first(fs) and r.hud.toasts.back() == "Brak zamówień" and r.hud.toasts_en.back() == "No orders right now", "N: start_first with no address: false, the toast")
	_ok(not q.start_kebab(3) and _stage() == 0, "N: start_kebab with no address: false")
	_ok(not q.start_sloik(0, 0) and _stage() == 0, "N: start_sloik with no address: false")
	# the pinned order goes to the door first_pick named; the next orders there are ordinary ones (some beyond 600 m or off its street)
	_rig()
	q = r.q
	fs = q.first_stand()
	var want: Dictionary = q.first_pick(fs)
	_ok(q.start_first(fs) and q._order["door"] == want["door"] and int(q.pinned) == -1, "N: start_first: the order is the guided one")
	var ordinary := 0
	for k in 20:
		var ou: Dictionary = q._make_kebab_order(fs, fs + q._stands.size() * (k + 1))
		ordinary += 1 if not ou.is_empty() and (float(ou["road"]) > 600.0 or not str(ou["name"]).begins_with("Marszałkowska")) else 0
	_ok(ordinary > 10, "N: the orders after the guided one are ordinary: most are beyond 600 m or off its street (%d of 20)" % ordinary)
	# a place the car is put into: standing
	_rig()
	q = r.q
	r.car.vel = Vector3(6.0, 0.0, 0.0)
	r.car.forward_speed = 6.0
	q.start_kebab(4)
	_ok(r.car.vel == Vector3.ZERO and r.car.forward_speed == 0.0, "N: the car put in a place stands")


## `q._addresses` (a typed array) set to `list`.
func _set_addrs(q: Node, list: Array) -> void:
	q._addresses.clear()
	for a in list:
		q._addresses.append(a)


## One address as `q._addresses` holds it, the one whose door is `a`'s.
func _address_of(q: Node, a: Dictionary) -> Dictionary:
	for x: Dictionary in q._addresses:
		if x["door"] == a["door"]:
			return x.duplicate()
	return {}


## The addresses the guided first order may take from stand `i` (a trip 150 to 600 m by road, its door 0.55 x 150 to 600 m
## away in a straight line, not in Praga), nearest FIRST_ROAD... all of them, with their road; `street` only Marszałkowska's.
func _first_list(i: int, street: bool) -> Array:
	var s := _stand(i)
	var from := Vector2(s["ring"].x, s["ring"].z)
	var dist := _graph.distances_from(_graph.e_b[int(s["edge"])], false)
	var out: Array = []
	for a: Dictionary in r.q._addresses:
		if a["d"] == "praga" or (street and not str(a["name"]).begins_with("Marszałkowska")):
			continue
		var dd: float = (a["door"] as Vector2).distance_to(from)
		if dd < 150.0 * 0.55 or dd > 600.0:
			continue
		var hit := _graph.snap(a["door"], 30.0)
		if hit.is_empty():
			continue
		var road := _graph.trip(dist, int(s["edge"]), float(s["s"]), hit[0], hit[2])
		if road >= INF or road < 150.0 or road > 600.0:
			continue
		var b: Dictionary = a.duplicate()
		b["road"] = road
		out.append(b)
	return out


## A kebab poi copied from poi `k` with its place moved 80 to 100 m (door with it), where a rig's setup finds room for it and
## it lies nearer (-1060, -330) than the real stand and farther from (-1060, -230); {} when no such place is found.
func _made_up_poi(k: int, at_real: Vector3) -> Dictionary:
	var pois: Array = _data["pois"]
	var real_d_far := Vector2(at_real.x, at_real.z).distance_to(Vector2(-1060.0, -330.0))
	var real_d_near := Vector2(at_real.x, at_real.z).distance_to(Vector2(-1060.0, -230.0))
	for step in 16:
		var ang := TAU * step / 16.0
		for dist in [90.0, 80.0, 100.0]:
			var off: Vector2 = Vector2(cos(ang), sin(ang)) * float(dist)
			var p: Dictionary = (pois[k] as Dictionary).duplicate(true)
			p["x"] = float(p["x"]) + off.x
			p["z"] = float(p["z"]) + off.y
			p["door"] = [float(p["door"][0]) + off.x, float(p["door"][1]) + off.y]
			var k2 := Vector2(float(p["x"]), float(p["z"]))
			if k2.distance_to(Vector2(-1060.0, -330.0)) >= real_d_far or k2.distance_to(Vector2(-1060.0, -230.0)) <= real_d_near:
				continue
			var kerb: Dictionary = _graph_kerb(p)
			if not kerb.is_empty() and (kerb["spot"] as Vector2).distance_to(Vector2(-1060.0, -230.0)) > real_d_near + 5.0 \
					and (kerb["spot"] as Vector2).distance_to(Vector2(-1060.0, -330.0)) < real_d_far - 5.0 and (kerb["spot"] as Vector2).distance_to(Vector2(-1060.0, -230.0)) < 118.0:
				return p
	return {}


## Where a rig's setup would put a kebab place `p` (its `_kerb`), by the rig that is up.
func _graph_kerb(p: Dictionary) -> Dictionary:
	var door: Array = p["door"]
	return r.q._kerb(Vector2(door[0], door[1]), Vector2(p["x"], p["z"]), float(p.get("w", 7.0)) * 0.5, [2.4, 1.6, 3.4, 4.4])


## The jars: the thresholds, where the measure runs, the signals, the passenger's chat, the status line.
func _s_n_jars() -> void:
	# braking at 15.9 and turning at 13.9 m/s²: still nothing
	var q := _sloik_drive()
	var v := 25.0
	_fr(v, 0.0)
	for f in 90:
		v = maxf(0.0, v - 15.9 * DT)
		_fr(v, 0.0)
	_ok(float(q._stress) == 0.0 and int(q._jars) == 6, "N: braking at 15.9 m/s²: no stress")
	q = _sloik_drive()
	var yaw := 0.0
	_fr(20.0, yaw)
	for f in 180:
		yaw += 0.695 * DT
		_fr(20.0, yaw)
	_ok(float(q._stress) == 0.0 and absf(float(q._lat_s) - 13.9) < 0.5, "N: a turn at 13.9 m/s²: no stress (lat %.1f)" % q._lat_s)
	# measured on the słoiki drive only
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_press(0)
	var ring := _ring_of(_ordr())
	_by(ring, 300.0, 20.0)
	_f(2)
	v = 20.0
	for f in 15:
		v = maxf(0.0, v - 40.0 * DT)
		_fr(v, 0.0)
	_ok(float(q._stress) == 0.0 and float(q._brake_s) == 0.0 and r.jars.is_empty() and not r.hud.toasts.back().begins_with("Trzask"), "N: braking at 40 m/s² on a kebab's drive: nothing is measured")
	_rig()
	q = r.q
	q.start_sloik(0, _lone_station(0))
	_sync()
	_fr(20.0, 0.0)
	v = 20.0
	for f in 15:
		v = maxf(0.0, v - 40.0 * DT)
		_fr(v, 0.0)
	_ok(float(q._brake_s) == 0.0 and float(q._stress) == 0.0 and _stage() == 1, "N: braking at 40 m/s² with the run's card up: nothing is measured")
	# speeding up is not braking
	q = _sloik_drive()
	v = 0.0
	_fr(v, 0.0)
	for f in 30:
		v += 40.0 * DT
		_fr(v, 0.0)
	_ok(float(q._brake_s) == 0.0 and float(q._stress) == 0.0, "N: speeding up at 40 m/s² is no braking")
	# none left
	_rig()
	q = r.q
	q.start_sloik(6, _lone_station(0))
	_sync()
	_press(0)
	ring = _ring_of(_ordr())
	_by(ring, 800.0, 15.0)
	_fr(15.0, 0.0)
	r.jars.clear()
	r.car.bumped.emit(null, 8.0)
	_ok(r.jars.is_empty() and int(q._jars) == 0, "N: a bump with no jar left: no clink, no break")
	r.car.bumped.emit(null, 20.0)
	_f(2)
	_ok(float(q._stress) <= 0.99 and r.hud.progress <= 0.99, "N: with no jar left the bar never reads over 0.99 (%.2f)" % q._stress)
	# one check, two jars
	q = _sloik_drive()
	_fr(15.0, 0.0)
	r.car.bumped.emit(null, 13.0)
	_ok(int(q._jars) == 4 and absf(float(q._stress) - 0.5) < 0.01, "N: a bump at 13 m/s breaks two jars at once (%d left, stress %.2f)" % [q._jars, q._stress])
	# the warning's clink, the wait after a break
	q = _sloik_drive()
	_fr(15.0, 0.0)
	var warn0 := _count(r.dialogue.said, "sloik_bump:")
	r.jars.clear()
	q._stress = 0.7
	_f()
	_ok(r.jars == [0] and _count(r.dialogue.said, "sloik_bump:") == warn0 + 1, "N: the warning clinks once and says its line")
	q = _sloik_drive()
	_fr(15.0, 0.0)
	r.car.bumped.emit(null, 8.0)
	_ok(int(q._jars) == 5, "N: one jar broke")
	var warn1 := _count(r.dialogue.said, "sloik_bump:")
	q._stress = 0.7
	_f(10)
	_ok(_count(r.dialogue.said, "sloik_bump:") == warn1, "N: no warning in the 3 s after a break")
	_f(170)
	q._stress = 0.7
	_f()
	_ok(_count(r.dialogue.said, "sloik_bump:") == warn1 + 1, "N: and one after")
	# the passenger: 9 s after GO, never over a bubble, 20 to 32 s apart, and not right after a break
	q = _sloik_drive()
	_f(530)
	_ok(_count(r.dialogue.said, "passenger:") == 0, "N: no passenger line at 8.9 s")
	_f(10)
	var pi := _last_said("passenger:")
	_ok(pi >= 0 and r.dialogue.speakers[pi] == q._order["customer"] and r.dialogue.anchors[pi] == r.car and r.dialogue.hows[pi] == [4.5, TEAL, 2.4, false], "N: the passenger's first line by 9.1 s, over the car")
	var seed1 := 1
	while true:
		var g := RandomNumberGenerator.new()
		g.seed = seed1
		if g.randf() < 0.1:
			break
		seed1 += 1
	q._rng.seed = seed1
	var said_n := _count(r.dialogue.said, "passenger:")
	_f(1180)
	_ok(_count(r.dialogue.said, "passenger:") == said_n, "N: no second passenger line for 19.8 s after the first")
	_f(160)
	_ok(_count(r.dialogue.said, "passenger:") == said_n + 1, "N: a second one by 22.5 s")
	q = _sloik_drive()
	r.bubbles.talking = true
	_f(700)
	_ok(_count(r.dialogue.said, "passenger:") == 0, "N: the passenger waits while a bubble is up")
	r.bubbles.talking = false
	_f(2)
	_ok(_count(r.dialogue.said, "passenger:") == 1, "N: and talks once it is down")
	q = _sloik_drive()
	_f(510)
	r.car.bumped.emit(null, 8.0)
	_f(460)
	_ok(_count(r.dialogue.said, "passenger:") == 0, "N: no passenger line within 7.8 s of a break")
	_f(40)
	_ok(_count(r.dialogue.said, "passenger:") == 1, "N: one 8.3 s after it")
	# the status line: the bar, the jars, the shake
	q = _sloik_drive()
	_fr(15.0, 0.0)
	r.car.bumped.emit(null, 8.0)
	q._stress = 0.5
	_f()
	_ok(r.hud.progress == float(q._stress) and r.hud.progress > 0.4 and r.hud.icons.get("jars") == [5, 6] and float(r.hud.icons.get("shake", -1.0)) == float(q._stress),
			"N: the status line: the bar is the stress, five of six jars, the jars shake with it (%s)" % str(r.hud.icons))
	# the distances of the hints
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_press(0)
	ring = _ring_of(_ordr())
	_by(ring, 35.0, 10.0)
	_f()
	_ok(r.hud.status == "Stań w kręgu", "N: 35 m from the door: pull up inside the ring (%s)" % r.hud.status)
	_by(ring, 45.0, 10.0)
	_f()
	_ok(r.hud.status.begins_with("Gorący jeszcze"), "N: 45 m: the heat's hint")
	_by(ring, 20.0, 10.0)
	_f()
	_ok(r.hud.status == "Stań w kręgu", "N: 20 m: pull up inside the ring (%s)" % r.hud.status)
	_by(ring, 300.0, 10.0)
	q._heat = 0.75
	_f()
	var rate := 0.6 / maxf(float((q._order as Dictionary).get("fair", 60.0)), 1.0)
	var sec := ceili((float(q._heat) - 0.7) / rate - 0.01)
	_ok(r.hud.status == "Gorący jeszcze %d s" % sec, "N: heat 0.75 is still hot (%s)" % r.hud.status)
	q._heat = 0.75
	_arrive_now()
	_ok(r.hud.card == "DOWIEZIONE · WCIĄŻ GORĄCY" and r.hud.card_en == "Delivered · still hot", "N: at the door with heat 0.75: still hot (%s)" % r.hud.card)
	# the customer waves at the door on the second delivery too
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_close_result()
	_find(0, _plain_day(), "a plain order")
	_press(0)
	_ok(q._beacon.waving, "N: the customer at the door waves on the second kebab's drive")
	# a run dropped with stress left: the next run's bar starts at 0
	q = _sloik_drive()
	_fr(15.0, 0.0)
	q._stress = 0.5
	r.hud.abort_pressed.emit()
	_close_result()
	q.start_sloik(0, _lone_station(0))
	_sync()
	_press(0)
	ring = _ring_of(_ordr())
	_by(ring, 300.0, 10.0)
	_f()
	_ok(r.hud.progress == 0.0, "N: the next run's bar starts at 0 (%.2f)" % r.hud.progress)
	# AS IT IS TODAY: the sliding means of the braking and of the sideways force are not set back between runs
	q = _sloik_drive()
	ring = _ring_of(_ordr())
	_fr(20.0, 0.0)
	v = 20.0
	for f in 40:
		v = maxf(0.0, v - 40.0 * DT)
		_by(ring, 0.0, v)
		_f()
		if _stage() == 3:
			break
	_ok(_stage() == 3 and float(q._brake_s) > 30.0, "N: the first run ended in a 40 m/s² stop (stage %d, braking %.1f)" % [_stage(), q._brake_s])
	_close_result()
	q.start_sloik(0, _lone_station(0))
	_sync()
	_press(0)
	ring = _ring_of(_ordr())
	_by(ring, 800.0, 15.0)
	_yaw = 0.0
	_f(30)
	_near(float(q._stress), 0.0231, 0.001, "N: AS FOUND (a defect, not fixed): the second run's stress after 0.5 s with no braking")
	_notes.append("a second run after a rough first one carries stress %.4f after 0.5 s (AS FOUND, not fixed)" % q._stress)


## The kerb asked straight, the stands' and the stations' places, a door by a deck and by a tunnel.
func _s_n_places() -> void:
	_rig()
	var q: Node = r.q
	var offs := [2.4, 1.6, 3.4, 4.4]
	# the kiosks and the newcomers face the road
	var turned := true
	for i in q._stands.size():
		var st := _stand(i)
		var side := Vector2(st["at"].x - st["ring"].x, st["at"].z - st["ring"].z).normalized()
		turned = turned and absf(angle_difference((st["node"] as Node3D).rotation.y, atan2(side.x, side.y))) < 0.001
	_ok(turned, "N: every kiosk's node faces the road")
	var tiles := 0
	var cells := {}
	for c in r.world.get_children():
		if c is MultiMeshInstance3D and not c.is_queued_for_deletion():
			tiles += 1
	for st in q._stands:
		if str(st["name"]) == "":
			cells[Vector2i(floori(st["at"].x / 512.0), floori(st["at"].z / 512.0))] = true
	_ok(tiles == cells.size(), "N: one tile per 512 m cell of unnamed kiosks (%d tiles, %d cells)" % [tiles, cells.size()])
	var gd: Dictionary = Jobs.GDANSKI
	for st in q._stations:
		var person: MeshInstance3D = st["person"]
		var side2 := Vector2(person.global_position.x - st["ring"].x, person.global_position.z - st["ring"].z).normalized()
		_ok(absf(angle_difference(person.rotation.y, atan2(side2.x, side2.y))) < 0.001, "N: %s's newcomer faces the road" % st["name"])
		var half := 3.5
		for p: Dictionary in _data["pois"]:
			if str(p["k"]) == "station" and str(p["name"]) == str(st["name"]):
				half = float(p.get("w", 7.0)) * 0.5
		if str(st["name"]) == str(gd["name"]):
			half = float(gd.get("w", 7.0)) * 0.5
		var ring2 := Vector2(st["ring"].x, st["ring"].z)
		var centre := ring2 - side2 * maxf(half - 2.0, 0.0)
		var want := 0.0
		for off in [1.2, 2.0, 3.0]:
			var sp: Vector2 = centre + side2 * (half + float(off))
			if _graph.snap(sp, 3.0).is_empty():
				want = float(off) + 2.0 if half >= 2.0 else float(half + off)
				break
		var dd := _flat(person.global_position, st["ring"])
		_ok(want == 0.0 or absf(dd - want) < 0.05, "N: %s's newcomer stands at the first free spot of 1.2, 2.0, 3.0 (%.2f, wanted %.2f)" % [st["name"], dd, want])
	# a door 400 m to 1 km from Gdański's ring makes a third station (a kerb within 150 m only counts as near)
	var gring := Vector2.ZERO
	for st in q._stations:
		if str(st["name"]) == str(gd["name"]):
			gring = Vector2(st["ring"].x, st["ring"].z)
	var near_door := {}
	for a: Dictionary in q._addresses:
		var dg := (a["door"] as Vector2).distance_to(gring)
		if dg > 400.0 and dg < 1000.0 and not _graph.snap(a["door"], 30.0).is_empty():
			var ok := true
			for st in q._stations:
				ok = ok and Vector2(st["ring"].x, st["ring"].z).distance_to(a["door"]) > 400.0
			if ok:
				near_door = a
				break
	if near_door.is_empty():
		_notes.append("no door 400 m to 1 km from Gdański's ring with room")
	else:
		var d3 := _data.duplicate()
		var pl3: Array = (_data["pois"] as Array).duplicate()
		pl3.append({"k": "station", "name": "Bliska stacja", "x": near_door["at"].x, "z": near_door["at"].y,
				"door": [near_door["door"].x, near_door["door"].y], "w": 10.0})
		d3["pois"] = pl3
		_rig(true, {}, {"data": d3})
		_ok(r.q._stations.size() == 3, "N: a station 400 m to 1 km from Gdański's ring is a third (%d)" % r.q._stations.size())
	# _kerb asked straight
	_rig()
	q = r.q
	var found15 := false
	var found_conn := false
	var tried_ends := 0
	var good_ends := 0
	var pick15: Vector2 = Vector2.ZERO
	var pick_conn: Vector2 = Vector2.ZERO
	for a: Dictionary in q._addresses:
		var dp: Vector2 = a["door"]
		if not found15 and _graph.snap(dp, 15.0, Vector2.ZERO, true, true).is_empty() and not _graph.snap(dp, 30.0, Vector2.ZERO, true, true).is_empty() \
				and int(_graph.snap(dp, 30.0, Vector2.ZERO, false, true)[0]) != int(_graph.snap(dp, 30.0, Vector2.ZERO, true, true)[0]):
			found15 = true
			pick15 = dp
		if not found_conn and _graph.snap(dp, 30.0, Vector2.ZERO, true, true).is_empty() and not _graph.snap(dp, 30.0, Vector2.ZERO, false, true).is_empty():
			found_conn = true
			pick_conn = dp
		if found15 and found_conn:
			break
	if found15:
		var h15 := _graph.snap(pick15, 30.0, Vector2.ZERO, true, true)
		var k15: Dictionary = q._kerb(pick15, pick15 + Vector2(5.0, 0.0), 3.5, offs)
		_ok(not k15.is_empty() and int(k15["edge"]) == int(h15[0]), "N: a connected lane 15 to 30 m from the door is the kerb's road")
	else:
		_notes.append("no door with a lane only 15 to 30 m away")
	if found_conn:
		var hc := _graph.snap(pick_conn, 30.0, Vector2.ZERO, false, true)
		var kc: Dictionary = q._kerb(pick_conn, pick_conn + Vector2(5.0, 0.0), 3.5, offs)
		_ok(not kc.is_empty() and int(kc["edge"]) == int(hc[0]), "N: a door with no connected road in reach takes the nearest ground lane")
	else:
		_notes.append("no door whose only lane is unconnected")
	# the kerb of a stand, then roofs
	var best_i := -1
	var k0: Dictionary = {}
	var pois_k: Array = []
	for p: Dictionary in _data["pois"]:
		if str(p["k"]) == "kebab":
			pois_k.append(p)
	var tried := 0
	var shifted := false
	for p: Dictionary in pois_k:
		var door: Array = p["door"]
		var dv := Vector2(door[0], door[1])
		var av := Vector2(p["x"], p["z"])
		var half2 := float(p.get("w", 7.0)) * 0.5
		var kk: Dictionary = q._kerb(dv, av, half2, offs)
		if kk.is_empty():
			continue
		tried += 1
		var centre0: Vector2 = kk["centre"]
		var side0: Vector2 = kk["side"]
		var dir0: Vector2 = _graph.direction(int(kk["edge"]), float(kk["s"]))
		_map.roof = func(pt: Vector2) -> bool: return (pt - centre0).dot(side0) > 0.5 and absf((pt - centre0).dot(dir0)) < 4.0
		var k1: Dictionary = q._kerb(dv, av, half2, offs)
		_map.roof = func(pt: Vector2) -> bool: return (pt - centre0).dot(side0) > 0.5
		var k2: Dictionary = q._kerb(dv, av, half2, offs)
		_map.roof = func(_pt: Vector2) -> bool: return true
		var k3: Dictionary = q._kerb(dv, av, half2, offs)
		_map.roof = Callable()
		if not k1.is_empty() and absf(absf(float(k1["s"]) - float(kk["s"])) - 8.0) < 0.01 and (k1["side"] as Vector2).is_equal_approx(side0):
			shifted = true
			_ok(not k2.is_empty() and (k2["side"] as Vector2).is_equal_approx(-side0) and (k2["heading"] as Vector2).is_equal_approx(-(kk["heading"] as Vector2)),
					"N: with the whole of the place's side roofed the kerb is on the other side, the other way")
			_ok(k3.is_empty(), "N: with both sides roofed there is no kerb")
			# the mirrored place is on the other side of the lane, the heading reversed
			var mirror: Vector2 = 2.0 * centre0 - av
			var km: Dictionary = q._kerb(dv, mirror, half2, offs)
			_ok(not km.is_empty() and (km["side"] as Vector2).is_equal_approx(-side0) and (km["heading"] as Vector2).is_equal_approx(-(kk["heading"] as Vector2)),
					"N: a place on the other side of the lane gets the other side and the other heading")
			break
	_ok(shifted, "N: with a roof over the door's own spot the kerb moves 8 m along the same side (tried %d)" % tried)
	# a door at the very start of a lane: never closer than 2 m to its end
	for e in _graph.e_a.size():
		if tried_ends >= 60:
			break
		var s0: float = _graph.e_s0[e]
		var dpt: Vector2 = _graph.point_at(e, s0)
		var hit := _graph.snap(dpt, 30.0, Vector2.ZERO, true, true)
		if hit.is_empty() or int(hit[0]) != e or float(hit[2]) > s0 + 2.0:
			continue
		tried_ends += 1
		var ke: Dictionary = q._kerb(dpt, dpt + Vector2(0.0, 4.0), 3.5, offs)
		if ke.is_empty() or int(ke["edge"]) != e:
			continue
		good_ends += 1
		_ok(float(ke["s"]) >= s0 + 2.0 - 0.0001, "N: the kerb of a door at a lane's very end keeps 2 m from it (lane %d, s %.2f from %.2f)" % [e, ke["s"], s0])
	_ok(good_ends > 0, "N: doors at lanes' very ends were tried (%d tried, %d answered)" % [tried_ends, good_ends])
	_notes.append("%d lane ends tried" % tried_ends)
	_s_n_decks()


## A door by a deck and one by a tunnel (the map has none): the ring's height is the deck's or the tunnel's, one 20 m from a lane
## gets its lane within 30 m.
func _s_n_decks() -> void:
	_rig()
	var q: Node = r.q
	var si := _lone_stand()
	var st := _stand(si)
	var from := Vector2(st["ring"].x, st["ring"].z)
	var dist_tried := {"deck": 0, "tunnel": 0}
	var done := {"deck": false, "tunnel": false}
	for kind in ["deck", "tunnel"]:
		var seen := 0
		for e in _graph.e_a.size():
			if done[kind] or seen >= 40:
				break
			var on: bool = (int(_graph.e_dk[e]) >= 0) if kind == "deck" else (int(_graph.e_tn[e]) >= 0)
			if not on:
				continue
			var mid: float = (float(_graph.e_s0[e]) + float(_graph.e_s1[e])) * 0.5
			var pt: Vector2 = _graph.point_at(e, mid)
			seen += 1
			var addr := {"name": "Wiaduktowa 1", "door": pt, "at": pt + Vector2(6.0, 0.0), "office": false, "d": ""}
			var saved: Array = q._addresses.duplicate()
			q._addresses.clear()
			q._addresses.append(addr)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			var out: Dictionary = q._pick_address(int(st["edge"]), float(st["s"]), from, 0.0, 99000.0, rng, func(_a: Dictionary) -> bool: return true)
			q._addresses.clear()
			for a in saved:
				q._addresses.append(a)
			if out.is_empty() or int(out["edge"]) != e:
				continue
			var ring: Vector3 = out["ring"]
			var want_y: float = _map.deck_height(int(_graph.e_dk[e]), ring.x, ring.z) if kind == "deck" else _map.tunnel_height(int(_graph.e_tn[e]), ring.x, ring.z)
			_ok(absf(ring.y - want_y) < 0.001, "N: a door by a %s: its ring at the %s's height (%.2f, wanted %.2f)" % [kind, kind, ring.y, want_y])
			done[kind] = true
		dist_tried[kind] = seen
	for kind in ["deck", "tunnel"]:
		if not done[kind]:
			_notes.append("no door by a %s that the roads reach from a stand (%d tried)" % [kind, dist_tried[kind]])
	# a door 10 to 30 m from the nearest lane: its lane is the one within 30 m
	var tried_far := 0
	var answered := false
	for a: Dictionary in q._addresses:
		var dp: Vector2 = a["door"]
		if not _graph.snap(dp, 10.0).is_empty() or _graph.snap(dp, 30.0).is_empty():
			continue
		var far_hit := _graph.snap(dp, 30.0)
		var dist_f := _graph.distances_from(_graph.e_b[int(st["edge"])], false)
		if _graph.trip(dist_f, int(st["edge"]), float(st["s"]), far_hit[0], far_hit[2]) >= INF:
			continue
		tried_far += 1
		if tried_far > 12:
			break
		var saved2: Array = q._addresses.duplicate()
		q._addresses.clear()
		q._addresses.append({"name": "Daleka 1", "door": dp, "at": dp + Vector2(6.0, 0.0), "office": false, "d": ""})
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 5
		var out2: Dictionary = q._pick_address(int(st["edge"]), float(st["s"]), from, 0.0, 99000.0, rng2, func(_a: Dictionary) -> bool: return true)
		q._addresses.clear()
		for b in saved2:
			q._addresses.append(b)
		answered = true
		_ok(not out2.is_empty() and int(out2["edge"]) == int(far_hit[0]), "N: a door 10 to 30 m from the nearest lane, reached by the roads, takes it")
		break
	if not answered:
		_notes.append("no door 10 to 30 m from a lane that the roads reach (%d tried)" % tried_far)


## The słoiki run: what it asks, what it claims, the names, the card.
func _s_n_sloik() -> void:
	# every address an office: nobody
	_rig()
	var q: Node = r.q
	for a: Dictionary in q._addresses:
		a["office"] = true
	var k0 := _lone_station(0)
	q.start_sloik(0, k0)
	_ok(_stage() == 0 and bool(q._stations[k0]["cool"]) and r.hud.toasts.back() == "Nikt nie potrzebuje podwózki", "N: with every address an office: nobody needs a lift")
	# no flat in Gdański's box
	_rig()
	q = r.q
	var gi := -1
	for i in q._stations.size():
		if str(q._stations[i]["tag"]) == "gdanski":
			gi = i
	var keep: Array = []
	for a: Dictionary in q._addresses:
		var at: Vector2 = a["at"]
		if not (at.x >= -2700.0 and at.y >= -2700.0 and at.x <= -1500.0 and at.y <= -1500.0):
			keep.append(a)
	_set_addrs(q, keep)
	q.start_sloik(0, gi)
	_ok(_stage() == 0 and r.hud.toasts.back() == "Nikt nie potrzebuje podwózki", "N: with no flat in the Muranów box, Gdański has nobody")
	# only flats nearer than the station's lo by road
	_rig()
	q = r.q
	var st: Dictionary = q._stations[0]
	var from := Vector2(st["ring"].x, st["ring"].z)
	var dist := _graph.distances_from(_graph.e_b[int(st["edge"])], false)
	var made_flat := {}
	var tried_flat := 0
	for e in _graph.e_a.size():
		if not made_flat.is_empty() or tried_flat > 4000:
			break
		var pt: Vector2 = _graph.point_at(e, (float(_graph.e_s0[e]) + float(_graph.e_s1[e])) * 0.5)
		if pt.distance_to(from) < 560.0 or pt.distance_to(from) > 900.0:
			continue
		var hit := _graph.snap(pt, 30.0)
		if hit.is_empty() or int(hit[0]) != e:
			continue
		tried_flat += 1
		var road := _graph.trip(dist, int(st["edge"]), float(st["s"]), hit[0], hit[2])
		if road < 980.0 and road >= 560.0:
			made_flat = {"name": "Blisko 1", "door": pt, "at": pt + Vector2(6.0, 0.0), "office": false, "d": "powisle"}
	if made_flat.is_empty():
		_notes.append("no road point 560 to 900 m away by air and under 980 m by road from the station")
	else:
		_set_addrs(q, [made_flat])
		q.start_sloik(0, 0)
		_ok(_stage() == 0 and r.hud.toasts.back() == "Nikt nie potrzebuje podwózki", "N: a flat nearer than the lo by road is nobody (the only one left)")
	# the newcomers differ, the run is counted and claims the places
	_rig()
	q = r.q
	var names := {}
	for n in 30:
		q._station = q._stations[0]
		q._begin_sloik(n)
		if _stage() == 1:
			names[str(q._order["customer"])] = true
			_press(1)
	_ok(names.size() >= 3, "N: the newcomers over 30 runs differ (%d names)" % names.size())
	_rig()
	q = r.q
	var closed0: int = r.missions.closed
	var pills0: int = r.hud.pills_hidden
	var chal0: int = r.hud.challenges_hidden
	var started0: int = q.orders_started()
	q.start_sloik(0, _lone_station(0))
	_sync()
	_ok(q.orders_started() == started0 + 1 and r.missions.closed > closed0 and r.missions.paused and r.hud.pills_hidden > pills0 and r.hud.challenges_hidden > chal0 \
			and not bool(q._places_shown), "N: a run's card counts the order and claims the places as a kebab's does")
	_f()
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9" and r.hud.button_words_en[0] == "GO! · 9", "N: the run's count-down")
	_press(1)
	q.start_sloik(0, _lone_station(0))
	_sync()
	_f()
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 9", "N: the next run's count-down starts from 9 again")
	# a station that carries its own district: the card says it in both languages
	var made := _data.duplicate()
	var pl: Array = (_data["pois"] as Array).duplicate()
	var real_st := {}
	for p: Dictionary in pl:
		if str(p["k"]) == "station":
			real_st = p.duplicate(true)
	if real_st.is_empty():
		return
	real_st["dest"] = ""
	real_st["dest_pl"] = "Śródmieście"
	real_st["dest_en"] = "the centre"
	real_st["lo"] = 600.0
	real_st["hi"] = 2400.0
	real_st["box"] = []
	real_st["tag"] = "centralny"
	for p: Dictionary in pl:
		if str(p["k"]) == "station":
			pl.erase(p)
			break
	pl.append(real_st)
	made["pois"] = pl
	_rig(true, {}, {"data": made})
	q = r.q
	q.start_sloik(0, 0)
	_sync()
	_ok(r.hud.body_en.contains("to a rented flat in the centre.") and r.hud.body.contains("Śródmieście ("), "N: a station's own district words are on the card (%s)" % r.hud.body_en)


## The cards: the craft wait, the keys, a dropped order.
func _s_n_cards() -> void:
	var crafts := func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"])
	_rig()
	var q: Node = r.q
	var nc := _find(_n_of("zag_rozen"), crafts, "a craft order", q._stands.size())
	if nc >= 0:
		_f(180)
		_press(0)
		_f(348)
		_ok(_stage() == 1, "N: the craft wait counts from POCZEKAM: still waiting 5.8 s after it")
		_f(24)
		_ok(_stage() == 2 and bool(q._order.get("premium", false)), "N: and the hand-carved kebab goes by 6.2 s")
	_rig()
	q = r.q
	nc = _find(_n_of("zag_rozen"), crafts, "a craft order", q._stands.size())
	if nc >= 0:
		_press(0)
		_f(180)
		q.primary()
		_f(168)
		_ok(_stage() == 1, "N: the M key in the wait changes nothing: still waiting 5.8 s after POCZEKAM")
		_f(24)
		_ok(_stage() == 2 and bool(q._order.get("premium", false)), "N: the hand-carved kebab goes 6.2 s after the first press")
	_rig()
	q = r.q
	nc = _find(_n_of("zag_rozen"), crafts, "a craft order", q._stands.size())
	if nc >= 0:
		_f(5)
		_ok(q.primary() and r.hud.card == "" and r.hud.toasts.back() == "Rzemieślnik kroi… 6 s", "N: the M key on the craft card: the card is down at once, the wait is on")
		_f(5)
		_ok(q.secondary() and _stage() == 2 and not bool(q._order.get("premium", false)), "N: the K key in the wait takes the plain kebab")
		# an ordinary order after it: the wait is not kept
		_abort_and_close()
		var nk := _find(0, _plain_day(), "a plain order")
		_press(0)
		_ok(nk >= 0 and _stage() == 2 and not bool(q._order.get("premium", false)), "N: the next plain order goes plain")
	# POCZEKAM, the ✕ in the wait, OK: the next plain order is not hurried by the old wait
	_rig()
	q = r.q
	nc = _find(_n_of("zag_rozen"), crafts, "a craft order", q._stands.size())
	if nc >= 0:
		_press(0)
		_f(30)
		_abort_and_close()
		_at(FAR)
		_f(2)
		_find(0, _plain_day(), "a plain order")
		_f(400)
		_ok(_stage() == 1, "N: after a dropped craft wait a plain order is not hurried (stage %d)" % _stage())
		_f(180)
		_ok(_stage() == 2 and not bool(q._order.get("premium", false)), "N: and it goes plain by its own 9 s")
	# the K key on cards
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_ok(r.director.secondary() and q.pointing(), "N: the K key on a delivered kebab's card is NASTĘPNE")
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_close_result()
	_find(0, _plain_day(), "a plain order")
	_press(0)
	_f(5)
	r.hud.abort_pressed.emit()
	var res_at: Vector3 = r.car.global_position
	_ok(r.hud.card == "ZAMÓWIENIE PRZEPADŁO" and not q.secondary() and not r.director.secondary() and not bool(q._delivered), "N: a dropped order's card after a delivered one: K is not taken")
	_ok(r.hud.status_title == "" and not q._beacon.visible, "N: the dropped order has no status line and no ring")
	q.card_pressed(1)
	_ok(not q.pointing() and int(q.next_stand) == -1, "N: and index 1 gives no pointer")
	# the dropped card stays where it came up
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_close_result()
	q.start_kebab(5)
	_sync()
	_press(0)
	_f(5)
	r.hud.abort_pressed.emit()
	_f(60)
	_ok(r.hud.card == "ZAMÓWIENIE PRZEPADŁO", "N: the dropped card is still up a second later")
	# the jars' dropped card
	_rig()
	q = r.q
	q.start_sloik(0, _lone_station(0))
	_sync()
	_press(0)
	_f(5)
	r.hud.abort_pressed.emit()
	_ok(r.hud.card == "KURS PRZERWANY" and r.hud.card_en == "Run abandoned" and r.hud.accent == RED, "N: the dropped run's card: its English and its red")
	_ok(not q.secondary() and r.hud.card != "", "N: the K key on it is not taken")
	# the K key on a słoiki result
	_rig()
	q = r.q
	q.start_sloik(0, _lone_station(0))
	_sync()
	_press(0)
	var ring := _ring_of(_ordr())
	_by(ring, 300.0, 10.0)
	_f(3)
	_arrive_now()
	_ok(r.hud.card.begins_with("DOWIEZIONE") and not q.secondary() and r.hud.card != "", "N: the K key on a run's result is not taken")
	# the welcome comes once, whatever the save says
	_rig()
	q = r.q
	var femina: Vector2 = Zaglebie.femina_at(_data["origin"])
	var spot81 := _clear_spot(femina, 81.0)
	var spot79 := _clear_spot(femina, 79.0)
	_at(spot79)
	_f()
	var asks := _count(r.dialogue.line_asks, "zaglebie:welcome")
	var toasts := r.hud.toasts.size()
	r.wallet.keep.clear()
	_at(spot81)
	_f()
	_at(spot79)
	_f()
	_ok(_count(r.dialogue.line_asks, "zaglebie:welcome") == asks and r.hud.toasts.size() == toasts, "N: with the save wiped in the same session the welcome does not come again")
	# the trail pays respect
	_rig(true, {"zaglebie_trail": "zag_krol,zag_stambul,zag_pasza,zag_erdal"})
	q = r.q
	_find_shop("zag_rozen")
	var pays0: int = r.wallet.payments.size()
	_deliver_after_go(true)
	var trail_pay := false
	for pay in r.wallet.payments.slice(pays0):
		trail_pay = trail_pay or (pay[0] == 120 and pay[1] == 25)
	_ok(trail_pay, "N: the fifth shop's delivery pays the trail's 120 zł and 25 respect")
	# the height does not count for a pull-in or an arrival
	_rig()
	q = r.q
	var li := _lone_stand()
	var lring: Vector3 = _stand(li)["ring"]
	_at(Vector2(lring.x, lring.z))
	_car.y += 40.0
	_f()
	_ok(_stage() == 1, "N: 40 m above a stand's ring is a pull-in")
	_press(0)
	var dring := _ring_of(_ordr())
	_by(dring, 300.0, 10.0)
	_f(2)
	_at(Vector2(dring.x, dring.z))
	_car.y += 40.0
	_f()
	_ok(_stage() == 3, "N: 40 m above the door's ring is an arrival")


func _abort_and_close() -> void:
	r.hud.abort_pressed.emit()
	_press(0)
	_at(FAR)
	_f(2)


## The places on the minimap and in the AUTO list, the route's walking, the pointer.
func _s_n_routes() -> void:
	# the depots
	_rig(true, {}, {"boat": Vector2(-500.0, 500.0)})
	var q: Node = r.q
	r.round.depots = PackedVector2Array([Vector2(10.0, 10.0), Vector2(20.0, 20.0)])
	_f()
	var base: int = q._stands.size() + q._stations.size() + 1
	_ok(r.hud.pois == base and not r.hud.poi_shapes.has(MapIcons.POI_DEPOT), "N: by day the depots have no squares")
	r.round._shown = false
	q.depots_shown(false)
	_ok(r.hud.pois == base, "N: depots_shown by day: no squares of the depots")
	var lez := 0
	for o: Dictionary in q.offer_places():
		lez += 1 if o["group"] == "lezak" else 0
	_ok(lez == 0, "N: by day offer_places has no depots")
	var set0: int = r.hud.pois_set
	_f(60)
	_ok(r.hud.pois_set == set0, "N: the places are not set again every frame")
	r.round._shown = true
	r.round.on = true
	var set1: int = r.hud.pois_set
	q.depots_shown(true)
	_ok(r.hud.pois_set == set1, "N: during the round-up depots_shown sets nothing")
	q.places_dirty()
	_ok(r.hud.pois == 0, "N: during the round-up the places' squares are off, the depots' too (%d)" % r.hud.pois)
	r.round.on = false
	# the boat's mark goes with the places while a job is on
	_rig(true, {}, {"boat": Vector2(-500.0, 500.0)})
	q = r.q
	_f()
	_ok(r.hud.pois > 0, "N: with the boat, the places are on the map")
	_find(0, _plain_day(), "a plain order")
	_ok(r.hud.pois == 0, "N: on the order card the minimap has no squares, the boat's too")
	_press(0)
	_f(5)
	_ok(r.hud.pois == 0, "N: nor on the drive")
	# offer_places during a job
	var none := true
	none = none and q.offer_places().is_empty()
	var ring := _ring_of(_ordr())
	_by(ring, 300.0, 10.0)
	_f()
	none = none and q.offer_places().is_empty()
	_arrive_now()
	none = none and q.offer_places().is_empty()
	_ok(none, "N: offer_places is empty on the card, on the drive and on the result card")
	# the pointer, the route that is walked and the line that is not kept
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_press(1)
	_ok(q.pointing() and r.hud.routes_set > 0 and not r.hud.route.is_empty(), "N: NASTĘPNE: the pointer and its route")
	_at(FAR)
	_f(2)
	var routes0: int = r.hud.routes_set
	_by(Vector3(FAR.x, 0.0, FAR.y), 300.0, 0.0)
	_f(75)
	_ok(r.hud.routes_set > routes0, "N: with the pointer up the route is walked again as the car moves")
	var st_ring := Vector3(r.q.stand_ring(int(q.next_stand)))
	_at(Vector2(st_ring.x, st_ring.z))
	_f()
	_ok(_stage() == 1 and r.hud.route.is_empty(), "N: a pull-in takes the pointer's route off the minimap at once (%d points)" % r.hud.route.size())
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_deliver()
	_close_result()
	var routes1: int = r.hud.routes_set
	_by(Vector3(FAR.x, 0.0, FAR.y), 300.0, 0.0)
	_f(90)
	_ok(r.hud.routes_set == routes1 and r.hud.route.is_empty(), "N: after OK with no pointer no route comes back")
	# the route's first leg runs the car's way
	var with_dir := 0
	var against := 0
	for i in q._stands.size():
		_rig()
		q = r.q
		var stand := _stand(i)
		var h: Vector2 = stand["heading"]
		q.start_kebab(i)
		_sync()
		_press(0)
		_f(2)
		var pts: PackedVector2Array = r.hud.route
		if pts.size() < 3:
			continue
		var lead: Vector2 = Vector2.ZERO
		for k in range(1, pts.size()):
			if pts[k].distance_to(pts[0]) > 8.0:
				lead = pts[k] - pts[0]
				break
		if lead.dot(h) > 0.0:
			with_dir += 1
		else:
			against += 1
		if with_dir + against >= 24:
			break
	_ok(with_dir > 0 and against <= with_dir / 4, "N: the route's first leg runs the car's way (%d with, %d against)" % [with_dir, against])
	# the nearest stand by the roads on the map, not by the links off it
	_rig()
	q = r.q
	var found_place := Vector2.INF
	var tried := 0
	for a: Dictionary in q._addresses:
		if a["d"] != "praga":
			continue
		tried += 1
		if tried > 400:
			break
		var p: Vector2 = a["door"]
		var hit := _graph.snap(p, 40.0, Vector2(0.0, -1.0), true)
		if hit.is_empty():
			continue
		var d_false := _graph.distances_from(_graph.e_b[int(hit[0])], false)
		var d_true := _graph.distances_from(_graph.e_b[int(hit[0])], true)
		var best_f := -1
		var best_t := -1
		var bf := INF
		var bt := INF
		for i in q._stands.size():
			var st := _stand(i)
			var air := Vector2(st["ring"].x, st["ring"].z).distance_to(p) * 1.4
			var df := _graph.trip(d_false, int(hit[0]), float(hit[2]), int(st["edge"]), float(st["s"]))
			var dt := _graph.trip(d_true, int(hit[0]), float(hit[2]), int(st["edge"]), float(st["s"]))
			df = air if df >= INF else df
			dt = air if dt >= INF else dt
			if df < bf:
				bf = df
				best_f = i
			if dt < bt:
				bt = dt
				best_t = i
		if best_f != best_t:
			found_place = p
			break
	if found_place == Vector2.INF:
		_notes.append("no place in Praga where the roads off the map change the nearest stand (%d tried)" % tried)
	else:
		_at(found_place)
		_f()
		var hit2 := _graph.snap(found_place, 40.0, Vector2(-sin(0.0), -cos(0.0)), true)
		var d2 := _graph.distances_from(_graph.e_b[int(hit2[0])], false)
		var want_i := -1
		var want_d := INF
		for i in q._stands.size():
			var st := _stand(i)
			var dd := _graph.trip(d2, int(hit2[0]), float(hit2[2]), int(st["edge"]), float(st["s"]))
			dd = Vector2(st["ring"].x, st["ring"].z).distance_to(found_place) * 1.4 if dd >= INF else dd
			if dd < want_d:
				want_d = dd
				want_i = i
		_ok(q.point_next_stand() == want_i, "N: the pointer from a place in Praga is the stand nearest by the roads on the map")


## An order over the river: the roads on the map do not reach its door.
func _s_n_river() -> void:
	_rig()
	var q: Node = r.q
	var found := {}
	var stand_i := -1
	var n_found := -1
	var cands: Array[int] = []
	# the check's own count: is there a door the roads on the map do not reach, with a junction that they do reach nearest it?
	var first_plain := _lone_stand()
	var d0 := _graph.distances_from(_graph.e_b[int(_stand(first_plain)["edge"])], false)
	var exists := false
	for a: Dictionary in q._addresses:
		var hit0 := _graph.snap(a["door"], 30.0)
		if hit0.is_empty() or _graph.trip(d0, int(_stand(first_plain)["edge"]), float(_stand(first_plain)["s"]), hit0[0], hit0[2]) < INF:
			continue
		var nn := _graph.nearest_node(a["door"])
		if nn >= 0 and d0[nn] < INF:
			exists = true
			break
	if not exists:
		_notes.append("no door over the river that the roads reach a junction near")
		return
	for i in q._stands.size():
		if bool(_stand(i)["across"]) or str(_stand(i)["zag"]) != "":
			continue
		for k in 80:
			var n: int = i + int(q._stands.size()) * (k + 1)
			var rng := RandomNumberGenerator.new()
			rng.seed = n * 7907 + i * 131 + 3
			if not rng.randf() < 0.3:
				continue
			var o: Dictionary = q._make_kebab_order(i, n)
			if not o.is_empty() and not bool(o["reached"]):
				if found.is_empty():
					found = o
					stand_i = i
					n_found = n
				cands.append(n)
		if cands.size() >= 8:
			break
	if found.is_empty():
		_problems.append("N: no order over the river among the across ones of the west-bank stands, though a door the roads do not reach has a junction near it")
		return
	var st := _stand(stand_i)
	var dist := _graph.distances_from(_graph.e_b[int(st["edge"])], false)
	var door: Vector2 = found["door"]
	var last := _graph.nearest_node(door)
	_ok(int(found["finish"]) == last and dist[last] < INF, "N: an order over the river ends at the connected junction nearest the door (%d, %d, %s)" % [found["finish"], last, str(found["across"])])
	var want_road: float = (float(_graph.e_len[int(st["edge"])]) - float(st["s"])) + dist[last] + Vector2(_graph.node_pos[last]).distance_to(door) * 1.3
	_ok(absf(float(found["road"]) - want_road) < 0.5, "N: its road is the way to the junction and 1.3 times the last stretch by air (%.1f, wanted %.1f)" % [found["road"], want_road])
	_ok(float(found["road"]) >= 400.0 and float(found["road"]) <= 3600.0, "N: and within the across order's reach")
	# GO on it: the route runs to the junction
	_rig()
	r.q.courier.force = true
	q = r.q
	q.start_kebab(n_found)
	_sync()
	if _stage() != 1 or int(q._order["stand"]) != stand_i or bool(q._order["reached"]):
		_notes.append("the order over the river did not come again by start_kebab")
		return
	_f(2)
	var o2 := _ordr()
	var challenged := false
	for cn in cands:
		_rig()
		r.q.courier.force = true
		q = r.q
		q.start_kebab(cn)
		_sync()
		_f(2)
		if int(q.courier.state) == 2:
			challenged = true
			_ok(int(q.courier._door_e) == -1, "N: the courier on an order over the river gets no lane at the door")
			break
	if not challenged:
		_notes.append("no rider has a way to a door over the river (%d tried)" % cands.size())
	_rig()
	r.q.courier.force = true
	q = r.q
	q.start_kebab(n_found)
	_sync()
	_f(2)
	o2 = _ordr()
	_press(0) if int(q.courier.state) != 2 else q.flash()
	_f(3)
	var pts: PackedVector2Array = r.hud.route
	var node_pos := Vector2(_graph.node_pos[int(o2["finish"])])
	var through := false
	for pt in pts:
		through = through or pt.distance_to(node_pos) < 3.0
	_ok(pts.size() >= 3 and through and pts[pts.size() - 1].distance_to(Vector2(o2["ring"].x, o2["ring"].z)) < 3.0,
			"N: GO on an order over the river: the minimap's route runs through the junction to the door (%d points)" % pts.size())
	_notes.append("an order over the river found (stand %d, n %d, challenged %s)" % [stand_i, n_found, str(challenged)])


## A contrived address book: exactly one door in the road's reach among 80 that pass the air test.
func _s_n_book() -> void:
	_rig()
	var q: Node = r.q
	var si := _lone_stand()
	var st := _stand(si)
	var from := Vector2(st["ring"].x, st["ring"].z)
	var dist := _graph.distances_from(_graph.e_b[int(st["edge"])], false)
	var goods: Array = []
	var bads: Array = []
	for a: Dictionary in q._addresses:
		var air: float = (a["door"] as Vector2).distance_to(from)
		if air < 220.0 or air > 1500.0:
			continue
		var hit := _graph.snap(a["door"], 30.0)
		var road := INF
		if not hit.is_empty():
			road = _graph.trip(dist, int(st["edge"]), float(st["s"]), hit[0], hit[2])
			if road >= INF:
				var last := _graph.nearest_node(a["door"])
				if last >= 0 and dist[last] < INF:
					road = (float(_graph.e_len[int(st["edge"])]) - float(st["s"])) + dist[last] + Vector2(_graph.node_pos[last]).distance_to(a["door"]) * 1.3
		if road >= 400.0 and road <= 1500.0:
			goods.append(a)
		else:
			bads.append(a)
	if goods.is_empty() or bads.size() < 79:
		_notes.append("no contrived address book (%d in reach, %d out of it)" % [goods.size(), bads.size()])
		return
	var book: Array = [goods[0]]
	book.append_array(bads.slice(0, 79))
	_set_addrs(q, book)
	var found := 0
	var tried := 0
	var n := 0
	while tried < 12 and n < 400:
		var nn: int = si + q._stands.size() * n
		n += 1
		var rng := RandomNumberGenerator.new()
		rng.seed = nn * 7907 + si * 131 + 3
		if rng.randf() < 0.3:
			continue
		tried += 1
		var o: Dictionary = q._make_kebab_order(si, nn)
		found += 1 if not o.is_empty() and o["door"] == goods[0]["door"] else 0
	_ok(found == tried and tried == 12, "N: with one door in reach among 80 every one of 12 orders finds it (%d of %d)" % [found, tried])


## The autopilot beyond the plain drive: off the roads, the ghost's ends, a jam, a door by hand, a car turned against its lane.
func _s_n_auto() -> void:
	_auto = true
	_rig(true, {}, {"autopilot": true, "start_heat": 0.9})
	var q: Node = r.q
	_find_auto_plain()
	var ring := _ring_of(_ordr())
	var off := _off_spot(ring)
	_ok(r.car.collision_mask == 1, "N: the car collides before the drive")
	if off == Vector2.INF:
		_notes.append("no spot off the roads near the door")
	else:
		r.car.global_position = Vector3(off.x, 0.0, off.y)
		r.car.rotation.y = 0.0
		await _af(3)
		_ok(_stage() == 2 and r.traffic.ghosts.is_empty() and r.car.collision_mask == 0, "N: off the roads there is no ghost, the car slides and collides with nothing")
		var to := Vector2(ring.x - r.car.global_position.x, ring.z - r.car.global_position.z)
		_ok(absf(angle_difference(r.car.rotation.y, atan2(-to.x, -to.y))) < 0.05, "N: the slide turns the car towards the door")
		var guard := 0
		while _stage() == 2 and guard < 12000:
			await _af(10)
			guard += 10
		_ok(_stage() == 3, "N: the slide arrives (%d frames)" % guard)
		_press(0)
		_at(FAR)
		r.car.global_position = Vector3(FAR.x, 0.0, FAR.y)
		await _af(2)
	# a run on a road after it: a ghost again, the car where the ghost is, in its yaw and at its speed
	# (an order whose door is 30 m or more before its lane's end and near the ghost's straight way there: it is taken off 22 m out)
	var near_way := func(o: Dictionary) -> bool:
		if not (_plain_day().call(o) and bool(o["reached"])):
			return false
		var st2 := _stand(int(o["stand"]))
		var start: Vector2 = _graph.point_at(int(st2["edge"]), float(st2["s"]))
		var node: Vector2 = _graph.node_pos[int(o["finish"])]
		var ringp := Vector2(o["ring"].x, o["ring"].z)
		return node.distance_to(ringp) >= 30.0 and Geometry2D.get_closest_point_to_segment(ringp, start, node).distance_to(ringp) < 6.0 and start.distance_to(ringp) > 150.0
	_find(0, near_way, "a plain order whose door is on the way to the end of its lane")
	ring = _ring_of(_ordr())
	var guard2 := 0
	var followed := true
	var seen_ghost := false
	var d_gone := -1.0
	var last_d := -1.0
	while _stage() != 3 and guard2 < 24000:
		var gs: Array = r.traffic.ghosts
		if not gs.is_empty():
			var gh: Ghost = gs[0]
			last_d = Vector2(gh.pos.x - ring.x, gh.pos.z - ring.z).length()
		await _af(1)
		guard2 += 1
		if not r.traffic.ghosts.is_empty():
			seen_ghost = true
			var gh2: Ghost = r.traffic.ghosts[0]
			if guard2 % 20 == 0:
				# The car is where the ghost is, turned as it and at its speed; it moves unless the ghost all but stands.
				var as_ghost: bool = r.car.global_position.distance_to(gh2.pos) < 0.01 and absf(angle_difference(r.car.rotation.y, gh2.yaw)) < 0.001 \
						and absf(r.car.vel.length() - gh2.v) < 0.01
				followed = followed and as_ghost and (r.car.vel.length() > 0.0 or gh2.v < 0.5)
		elif d_gone < 0.0 and seen_ghost:
			d_gone = last_d
	_ok(seen_ghost and followed, "N: after a run off the roads a run on a road has a ghost again, and the car is the ghost's (position, yaw, speed)")
	_ok(d_gone > 15.0 and d_gone <= 22.5, "N: the ghost leaves the route 22 m from the door (%.1f)" % d_gone)
	_ok(r.traffic.added == 1 and _stage() == 3 and r.traffic.ghosts.is_empty(), "N: one ghost in the whole run, gone at the door (added %d)" % r.traffic.added)
	_press(0)
	r.car.global_position = Vector3(FAR.x, 0.0, FAR.y)
	await _af(2)
	# the next run in the same rig gets a ghost of its own and reaches its door
	_find_auto_plain()
	var guard3 := 0
	while _stage() != 3 and guard3 < 24000:
		await _af(10)
		guard3 += 10
	_ok(_stage() == 3 and r.traffic.added == 2, "N: a second run on the autopilot has a ghost of its own and arrives (added %d, %d frames)" % [r.traffic.added, guard3])
	_press(0)
	# a jam: told to squeeze by after 4 s, the clock starts again after
	_rig(true, {}, {"autopilot": true})
	q = r.q
	_find_auto_plain()
	r.traffic.jam = true
	var g0 := 0
	while (_stage() != 2 or r.traffic.ghosts.is_empty()) and g0 < 800:
		await _af(1)
		g0 += 1
	var frames_jam := 0
	var gj: Ghost = r.traffic.ghosts[0] if not r.traffic.ghosts.is_empty() else null
	if gj != null:
		while gj.squeeze == 0.0 and frames_jam < 400:
			await _af(1)
			frames_jam += 1
		_ok(frames_jam >= 236 and frames_jam <= 246, "N: a jam: the ghost is told to squeeze by after 4 s (%d frames)" % frames_jam)
		gj.squeeze = 0.0
		await _af(1)
		_ok(gj.squeeze == 0.0, "N: the stall's clock starts again: not told again a frame later")
		await _af(233)
		_ok(gj.squeeze == 0.0, "N: nor 3.9 s later")
		await _af(25)
		_ok(gj.squeeze == 3.0, "N: but 4 s later")
	r.traffic.jam = false
	# the car put in the door's ring by hand while the ghost is far from it
	_rig(true, {}, {"autopilot": true})
	q = r.q
	_find_auto_plain()
	ring = _ring_of(_ordr())
	var g4 := 0
	while _stage() != 2 and g4 < 800:
		await _af(1)
		g4 += 1
	await _af(60)
	var far_ghost: bool = not r.traffic.ghosts.is_empty() and Vector2(r.traffic.ghosts[0].pos.x - ring.x, r.traffic.ghosts[0].pos.z - ring.z).length() > 40.0
	_at(Vector2(ring.x, ring.z))
	_f()
	_ok(far_ghost and _stage() == 3 and r.traffic.ghosts.is_empty(), "N: the car put in the ring by hand ends the run and takes the ghost off the road")
	# the car turned against its lane at GO: a ghost all the same
	var place := _against_lane()
	if place.is_empty():
		_notes.append("no place where no lane goes the car's way within 40 m but one is within 60 m")
	else:
		_rig(true, {}, {"autopilot": true})
		q = r.q
		_find_auto_plain()
		r.car.global_position = Vector3(place["p"].x, 0.0, place["p"].y)
		r.car.rotation.y = atan2(-place["h"].x, -place["h"].y)
		await _af(3)
		_ok(_stage() == 2 and r.traffic.ghosts.size() == 1, "N: a car turned against its lane still gets a ghost")
	_auto = false


## A spot 150 to 600 m from `ring` with no lane within 60 m, or INF.
func _off_spot(ring: Vector3) -> Vector2:
	for d: float in [150.0, 250.0, 350.0, 450.0, 600.0]:
		for a in 12:
			var p := Vector2(ring.x, ring.z) + Vector2.from_angle(TAU * a / 12.0) * d
			if _graph.snap(p, 60.0, Vector2.ZERO, true).is_empty() and _graph.snap(p, 40.0, Vector2.UP, true).is_empty():
				return p
	return Vector2.INF


## A point and a heading with no connected lane going that way within 40 m but one (any way) within 60 m.
func _against_lane() -> Dictionary:
	var tried := 0
	for e in _graph.e_a.size():
		tried += 1
		if tried > 3000:
			break
		var mid: float = (float(_graph.e_s0[e]) + float(_graph.e_s1[e])) * 0.5
		var p: Vector2 = _graph.point_at(e, mid)
		var h: Vector2 = -_graph.direction(e, mid)
		if _graph.snap(p, 40.0, h, true).is_empty() and not _graph.snap(p, 60.0, Vector2.ZERO, true).is_empty():
			return {"p": p, "h": h}
	return {}


# --- K. the autopilot ---------------------------------------------------------------------------------------------------

func _s_k_auto() -> void:
	_rig(true, {}, {"autopilot": true, "start_heat": 0.9})
	var q: Node = r.q
	_auto = true
	_ok(not q.drive_player(), "K: drive_player false while idle")
	var t0 := _frames
	_find_auto_plain()
	_ok(not q.drive_player(), "K: false on the order")
	await _af(1)
	_ok(r.hud.button_words[0] == "JEDZIEMY! · 4", "K: the autopilot's order counts to 4")
	await _af(233 - 1)
	_ok(_stage() == 1, "K: still the order at 3.9 s")
	await _af(10)
	_ok(_stage() == 2, "K: the order goes after 4 s")
	await _af(2)
	_ok(r.traffic.ghosts.size() == 1 and r.traffic.races.size() == 1 and r.traffic.races[0][1] == 1.3 and r.traffic.races[0][2] == 1.5 \
			and r.traffic.races[0][0] == int(q._order["finish"]), "K: a ghost on the road, raced to the order's finish at 1.3 and 1.5")
	_ok(r.car.collision_mask == 0 and q.drive_player(), "K: the car is the ghost's, collision off")
	var g: Ghost = r.traffic.ghosts[0] if not r.traffic.ghosts.is_empty() else null
	if g != null:
		_ok(r.car.global_position.distance_to(g.pos) < 25.0, "K: the car is where the ghost is")
	var guard := 0
	while _stage() == 2 and guard < 24000:
		await _af(10)
		guard += 10
	_ok(_stage() == 3 and r.traffic.ghosts.is_empty(), "K: the autopilot arrives and the ghost is gone (%d frames)" % guard)
	_ok(not q.drive_player() and q._auto_button() == -1, "K: false on the result card")
	await _af(713)
	_ok(_stage() == 3, "K: the result card waits out its 12 s")
	await _af(20)
	_ok(_stage() == 0 and r.traffic.ghosts.is_empty(), "K: then idle, no ghost left")
	# a jam, the ✕ on the autopilot's drive
	_rig(true, {}, {"autopilot": true})
	q = r.q
	_find_auto_plain()
	r.traffic.jam = true
	await _af(250)
	_ok(_stage() == 2 and r.traffic.ghosts.size() == 1, "K: the drive starts")
	await _af(300)
	_ok(not r.traffic.ghosts.is_empty() and r.traffic.ghosts[0].squeeze == 3.0, "K: a jam: the ghost is told to squeeze by")
	r.traffic.jam = false
	r.hud.abort_pressed.emit()
	_ok(r.traffic.ghosts.is_empty() and _stage() == 3, "K: the ✕ removes the ghost")
	# the craft shop on the autopilot, plain and not
	_rig(true, {}, {"autopilot": true})
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	_ok(r.hud.card == "" and _stage() == 1 and float(q._craft_t) > 0.0, "K: the craft card is down at once, the wait on")
	await _af(366)
	_ok(_stage() == 2 and bool(q._order["premium"]), "K: the drive 6 s later with premium")
	_rig(true, {}, {"autopilot": true, "craft_plain": true})
	q = r.q
	_find(_n_of("zag_rozen"), func(o: Dictionary) -> bool: return str(o["zag"]) == "zag_rozen" and not bool(o["across"]), "a craft order", r.q._stands.size())
	_ok(_stage() == 2 and not bool(q._order["premium"]), "K: --craft=plain: the plain one at once")
	# a słoiki run on the autopilot
	_rig(true, {}, {"autopilot": true})
	q = r.q
	q.start_sloik(0, _lone_station(0))
	_sync()
	await _af(250)
	_ok(_stage() == 2 and r.traffic.races.size() == 1 and r.traffic.races[0][1] == 0.95 and r.traffic.races[0][2] == 0.9, "K: a słoiki ghost at 0.95 and 0.9")
	guard = 0
	while _stage() == 2 and guard < 24000:
		await _af(10)
		guard += 10
	_ok(_stage() == 3 and int(q._jars) == 6, "K: the słoiki run arrives with six jars")
	# H12: the courier's challenge on the autopilot: his own autopilot takes it after 1 s, before the order's 4 s.
	_rig(true, {}, {"autopilot": true})
	q = r.q
	q.courier.force = true
	if _h_up(700) >= 0:
		_ok(_stage() == 1 and int(q.courier.state) == 2 and r.hud.challenge == "WYŚCIG · PĘDZIK", "H12: on the autopilot the challenge is up on the order's card")
		await _af(52)
		_ok(_stage() == 1 and int(q.courier.state) == 2, "H12: still the order and the challenge at 0.9 s")
		await _af(24)
		_ok(_stage() == 2 and int(q.courier.state) == 3 and r.hud.challenge == "", "H12: by 1.3 s the race is on and the order has gone, before its own 4 s")
	_auto = false
	_rig()
	q = r.q
	_find(0, _plain_day(), "a plain order")
	_press(0)
	var before := r.car.global_position
	_ok(not q.drive_player() and r.car.global_position == before, "M: drive_player on the drive with the autopilot off: false, the car not moved")


func _find_auto_plain() -> void:
	_find(0, _plain_day(), "a plain order")
