extends Node
## Loop jobs-2 (docs/design/parodies.md 4.3): the courier race. At night, when the player takes a
## kebab order at a stand, 1 time in 4 (`CHANCE`, *guess*) a Pędzik courier waiting there
## challenges: a `pedzik` `challenge` bubble and the ŚCIGAJ button (the rivals' FLASH LIGHTS slot,
## key L) for 6 s. Accept and both go to the same door: the rider on the footway network (parks,
## squares, crossings and cycle paths: an A* from the stand to the door, worked out in a worker
## thread while the order card is up), the car by road. No challenge when the rider's way is longer
## than 1.6 × the straight line (`DETOUR_MAX`). Loop couriers: the challenger is one of the couriers
## waiting by the stand at night (city_life.gd `waiting_at`; none waiting, no challenge unless forced):
## he stands by his bike through the offer, and on ŚCIGAJ gets on it (`take_waiting`) and goes from his
## spot. His pace is the order's: his time is the road's at V_ROAD (`pace`, 6.5-11 m/s), so a decent
## player (DECENT: 30-50 km/h door to door) wins about two in three. The race
## UI is the kebab's status with the rivals' 1ST / 2ND badge and the gap. Win: the kebab pays as usual
## plus +30 zł +30 respect and the rider's `lose` line; lose: the kebab pays as usual, the rider's
## `win` line. No fine, nothing taken; the heat rules are the kebab's (jobs.gd owns the job: this
## node is its child and only adds the rider, the badge and the bonus).
##
## Drawing: one MeshInstance3D of props.gd's Pędzik rider (the shared actor material, no shadow),
## shown from the start of the race (from the challenge when no courier was waiting) to a few
## seconds after the door: +1 draw call while it is in view,
## 0 otherwise. Per frame only while a race runs: the rider's step (a few vector ops) and the rank
## at 5 Hz (a lane snap and a lookup). Nothing runs when no race is on.

const Access := preload("res://scripts/access.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## Pędzik's magenta (parodies.md 4.1).
const COLOUR := Color("#c23a7e")
const CHANCE := 0.25
const OFFER_S := 6.0
## The A* has this long to finish before the challenge is dropped (s).
const ROUTE_WAIT := 4.0
const V := 6.5
## Loop couriers (BACKLOG "The courier rarely wins"): the rider's time is the order's road at V_ROAD
## m/s (36 km/h), his speed within V_MIN-V_MAX (23-40 km/h: an e-bike courier, cartoon fast); a decent
## player averages DECENT m/s door to door (30-50 km/h), so he wins about 2 in 3 (`decent_wins`).
const V_ROAD := 10.0
const V_MIN := 6.5
const V_MAX := 11.0
const DECENT := Vector2(8.0, 14.0)
const DETOUR_MAX := 1.6
const PAY_ZL := 30
const PAY_RESPECT := 30
## The A*'s box: the stand and the door, and this much round them (m).
const BOX_GROW := 250.0
## The rider stays at the door this long after the race (s).
const LINGER := 8.0
const RANK_EVERY := 0.2

enum State { IDLE, ROUTING, OFFER, RACE, DONE }

var dialogue: Node
var bubbles: Control
var hud: CanvasLayer
var wallet: Node
var map: Node3D
var car: CharacterBody3D
var graph: LaneGraph
## The map data's paths (`k`, `dk`, `p`), read by the worker thread only.
var paths: Array = []
## --courier-race: every order is challenged (day or night).
var force := false
## --autopilot: the challenge is taken after a second.
var autopilot := false
## The rider's speed (m/s): `pace` at the race's start, or --courier-v for a test run (`fixed_speed`).
var speed := V
var fixed_speed := false
## Loop couriers: city_life.gd (the couriers waiting at the stands; null: the rider appears at the
## kiosk, as before) and the order's stand.
var life: Node
var stand_i := -1
var state := State.IDLE
## The race's outcome once the rider or the car is at the door.
var rider_first := false
## The rider's path (m), the straight line and the road (m), for the log and the check.
var path_len := 0.0
var straight := 0.0
var road := 0.0
## Races run, won (the check, the log).
var raced := 0
var won := 0

var _rider: MeshInstance3D
## Loop couriers: the waiting courier who challenged ([at, yaw]; [] when he appeared at the kiosk).
var _waiter: Array = []
var _task := -1
var _out: Array = [null]
var _pts := PackedVector2Array()
var _h := PackedFloat32Array()
var _cum := PackedFloat32Array()
var _s := 0.0
var _seg := 0
var _t := 0.0
var _rank_t := 0.0
var _rider_left := 0.0
var _player_left := 0.0
var _dist := PackedFloat32Array()
## The same to the door edge's other way (the door can be reached from either side of the street).
var _dist_rev := PackedFloat32Array()
## The door's lane graph point (its edge and the distance along it): the car's road left is measured
## to it (the edge's end node can be far past the door).
var _door_e := -1
var _door_s := 0.0
var _door := Vector3.ZERO
## Set when an order is taken: jobs.gd's `_go` is called when the race is accepted first.
var _go: Callable


## Order n's roll (0..1): the same order always rolls the same.
static func roll(n: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 4421 + 17
	return rng.randf()


## The challenge rule: at night (or forced), the order's roll under CHANCE.
static func challenges(night: bool, r: float, forced := false) -> bool:
	return forced or (night and r < CHANCE)


## The way fits: the rider's path at most DETOUR_MAX × the straight line (and some way at all).
static func fits(path_m: float, straight_m: float) -> bool:
	return path_m > 0.0 and straight_m > 0.0 and path_m <= DETOUR_MAX * straight_m


## Loop couriers: the rider's speed for a way `path_m` long against `road_m` by road: his time is the
## road's at V_ROAD, within V_MIN-V_MAX (V without a road).
static func pace(path_m: float, road_m: float) -> float:
	if path_m <= 0.0 or road_m <= 0.0:
		return V
	return clampf(path_m * V_ROAD / road_m, V_MIN, V_MAX)


## Loop couriers: the share of decent drives (an average speed door to door spread evenly over
## DECENT) that beat a rider at `v` m/s on a way `path_m` long to a door `road_m` away by road.
static func decent_wins(path_m: float, road_m: float, v: float) -> float:
	var tie := road_m * v / maxf(path_m, 0.01)
	return clampf((DECENT.y - tie) / (DECENT.y - DECENT.x), 0.0, 1.0)


## The race's pay on top of the kebab's: {zl, respect, line (the rider's dialogue tag)}.
static func result(car_first: bool) -> Dictionary:
	if car_first:
		return {"zl": PAY_ZL, "respect": PAY_RESPECT, "line": "lose"}
	return {"zl": 0, "respect": 0, "line": "win"}


## A path's length.
static func length_of(pts: PackedVector2Array) -> float:
	var run := 0.0
	for i in range(1, pts.size()):
		run += pts[i].distance_to(pts[i - 1])
	return run


## The rider's way: A* over the footways, crossings and cycle paths within BOX_GROW m of the box
## round `from` and `to` (pure: the worker runs it, check_side_jobs.gd too); its points end at `to`.
static func route(all_paths: Array, from: Vector2, to: Vector2) -> Dictionary:
	var box := Rect2(from, Vector2.ZERO).expand(to).grow(BOX_GROW)
	var list: Array = []
	for p: Dictionary in all_paths:
		var k := str(p.get("k", ""))
		if not k in ["foot", "zebra", "cycle", "cyclecross"]:
			continue
		var flat: Array = p["p"]
		var n := flat.size() / 2
		if n < 2:
			continue
		var a := Vector2(float(flat[0]), float(flat[1]))
		var b := Vector2(float(flat[n * 2 - 2]), float(flat[n * 2 - 1]))
		if not box.has_point(a) and not box.has_point(b):
			continue
		var pts := PackedVector2Array()
		for i in n:
			pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
		list.append([pts, int(p.get("dk", -1))])
	if list.is_empty():
		return {}
	var routes := Crowds.build_routes(list, [["stand", from]], [["door", to]])
	if routes.is_empty():
		return {}
	var r: Dictionary = routes[0]
	var pts: PackedVector2Array = r["pts"]
	var dk: PackedInt32Array = r["dk"]
	# From the stand onto the footway, and off it to the door.
	pts.insert(0, from)
	dk.insert(0, -1)
	pts.append(to)
	dk.append(-1)
	return {"pts": pts, "dk": dk, "len": length_of(pts)}


func setup(world: Node3D) -> void:
	_rider = MeshInstance3D.new()
	_rider.name = "CourierRacer"
	_rider.mesh = Props.pedzik_rider()
	_rider.material_override = Models.material()
	_rider.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rider.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rider.visible = false
	world.add_child(_rider)
	if hud != null:
		hud.challenge_pressed.connect(accept)


## A kebab order was taken at a stand (jobs.gd `_begin_kebab`): the kiosk at `stand`, the door's
## ring at `door`, its lane graph point (`door_e`, `door_s`; -1: none); `n` the order's number (its
## roll), `go` starts the delivery; loop couriers: `si` the stand's index (its waiting couriers).
func on_order(stand: Vector3, door: Vector3, n: int, night: bool, door_e: int, door_s: float, go: Callable, si := -1) -> void:
	cancel()
	if not challenges(night, roll(n), force):
		return
	stand_i = si
	_waiter = []
	_door = door
	_go = go
	_door_e = door_e
	_door_s = door_s
	straight = Vector2(stand.x, stand.z).distance_to(Vector2(door.x, door.z))
	var from := Vector2(stand.x, stand.z)
	var to := Vector2(door.x, door.z)
	var all := paths
	var out := [null]
	_out = out
	_task = WorkerThreadPool.add_task(func() -> void: out[0] = route(all, from, to), false, "courier route")
	state = State.ROUTING
	_t = 0.0


## The ŚCIGAJ button or key L: the challenge taken. False when there is none.
func accept() -> bool:
	if state != State.OFFER:
		return false
	state = State.RACE
	_t = 0.0
	_s = 0.0
	_seg = 0
	_rank_t = 0.0
	raced += 1
	rider_first = false
	if not fixed_speed:
		speed = pace(path_len, road)
	# Loop couriers: the waiting courier gets on his bike and goes.
	if not _waiter.is_empty() and life != null:
		life.take_waiting(stand_i)
	_place(0.0)
	_rider.visible = true
	if hud != null:
		hud.hide_challenge()
	if car != null and car.has_method("flash_lights"):
		car.flash_lights()
	_dist = PackedFloat32Array()
	_dist_rev = PackedFloat32Array()
	if graph != null and _door_e >= 0:
		_dist = graph.distances_to(graph.e_a[_door_e])
		if graph.e_reverse[_door_e] >= 0:
			_dist_rev = graph.distances_to(graph.e_a[graph.e_reverse[_door_e]])
	_rider_left = path_len
	_player_left = road
	print("courier: race on: the rider's way %d m (%.2f × the straight %d m), the road %d m; the rider at %.1f m/s (%.0f s; a decent drive wins %.0f %%)" % [
			roundi(path_len), path_len / maxf(straight, 1.0), roundi(straight), roundi(road), speed, path_len / maxf(speed, 0.1),
			decent_wins(path_len, road, speed) * 100.0])
	if _go.is_valid():
		_go.call()
	Access.buzz(80, 0.7)
	return true


## The road length of the order (jobs.gd sets it with the order).
func set_road(m: float) -> void:
	road = m


## A race is on (accepted, the car not at the door yet).
func racing() -> bool:
	return state == State.RACE


## The status badge while racing: 1ST / 2ND (rivals' look), "" otherwise.
func badge() -> String:
	if state != State.RACE:
		return ""
	if rider_first:
		return "2ND"
	return "1ST" if _player_left <= _rider_left else "2ND"


## The status hint while racing [Polish, English], or [] when no race runs.
func hint() -> Array:
	if state != State.RACE:
		return []
	if rider_first:
		return ["Pędzik już pod drzwiami. Dowieź i tak", "The courier is at the door. Deliver anyway"]
	var gap := roundi(absf(_rider_left - _player_left))
	if _player_left <= _rider_left:
		return ["Pędzik: %d m za tobą" % gap, "The courier is %d m behind" % gap]
	return ["Pędzik: %d m przed tobą" % gap, "The courier is %d m ahead" % gap]


## The car is at the door (jobs.gd `_arrive`): the race's pay and line, {} when no race ran.
func finish() -> Dictionary:
	if state != State.RACE:
		cancel()
		return {}
	var r := result(not rider_first)
	state = State.DONE
	_t = 0.0
	if int(r["zl"]) > 0 or int(r["respect"]) > 0:
		won += 1
		if wallet != null:
			wallet.pay(int(r["zl"]), int(r["respect"]), "courier")
	if dialogue != null and not rider_first:
		dialogue.say(_rider, "Pędzik", "pedzik", str(r["line"]), 4.5, COLOUR, 2.4, true)
	print("courier: race %s: the rider %d m from the door; +%d zł +%d respect" % ["won" if not rider_first else "lost",
			roundi(_rider_left), int(r["zl"]), int(r["respect"])])
	r["won"] = not rider_first
	return r


## The order went (dropped, not taken, the job over): no race, the rider gone.
func cancel() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if state == State.OFFER and hud != null:
		hud.hide_challenge()
	state = State.IDLE
	if _rider != null:
		_rider.visible = false


## One frame (jobs.gd's _process calls it while the race isn't idle).
func step(dt: float) -> void:
	match state:
		State.ROUTING:
			_t += dt
			if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
				WorkerThreadPool.wait_for_task_completion(_task)
				_task = -1
				_routed(_out[0])
			elif _t > ROUTE_WAIT:
				print("courier: no challenge (the way took over %.0f s)" % ROUTE_WAIT)
				cancel()
		State.OFFER:
			_t += dt
			hud.show_challenge("WYŚCIG · PĘDZIK", COLOUR, "RACE · PĘDZIK", "Do drzwi klienta. Dotknij albo L", "To the door. Tap or L")
			if autopilot and _t > 1.0:
				accept()
			elif _t > OFFER_S:
				hud.hide_challenge()
				print("courier: challenge not taken")
				state = State.IDLE
				_rider.visible = false
		State.RACE:
			_t += dt
			if not rider_first:
				_ride(dt)
			_rank_t -= dt
			if _rank_t <= 0.0:
				_rank_t = RANK_EVERY
				_rider_left = maxf(0.0, path_len - _s)
				_player_left = _remaining()
				if int(_t / 20.0) != int((_t - RANK_EVERY) / 20.0):
					print("courier: %.0f s: the rider %d m from the door, the car %d m by road (%s)" % [_t, roundi(_rider_left),
							roundi(_player_left), badge()])
		State.DONE:
			_t += dt
			if _t > LINGER:
				state = State.IDLE
				_rider.visible = false


func _routed(r: Variant) -> void:
	if not r is Dictionary or (r as Dictionary).is_empty():
		print("courier: no challenge (no footway from the stand to the door)")
		state = State.IDLE
		return
	var d: Dictionary = r
	# Loop couriers: the challenger is a courier waiting by the stand (from his spot); none waiting,
	# no challenge, unless forced (--courier-race: he appears at the kiosk, as before).
	_waiter = []
	if life != null and stand_i >= 0:
		var w: Array = life.waiting_at(stand_i)
		if not w.is_empty():
			_waiter = w[w.size() - 1]
		elif not force:
			print("courier: no challenge (no courier waiting at stand %d)" % stand_i)
			state = State.IDLE
			return
	if not _waiter.is_empty():
		var at: Vector3 = _waiter[0]
		var pts0: PackedVector2Array = d["pts"]
		var dk0: PackedInt32Array = d["dk"]
		pts0.insert(0, Vector2(at.x, at.z))
		dk0.insert(0, -1)
		d = {"pts": pts0, "dk": dk0, "len": length_of(pts0)}
	path_len = float(d["len"])
	if not fits(path_len, straight):
		print("courier: no challenge (the way %d m is %.2f × the straight %d m)" % [roundi(path_len), path_len / maxf(straight, 1.0),
				roundi(straight)])
		state = State.IDLE
		return
	_pts = d["pts"]
	var dk: PackedInt32Array = d["dk"]
	_h = PackedFloat32Array()
	_cum = PackedFloat32Array()
	var run := 0.0
	for i in _pts.size():
		if i > 0:
			run += _pts[i].distance_to(_pts[i - 1])
		_cum.append(run)
		_h.append(map.deck_height(dk[i], _pts[i].x, _pts[i].y) if map != null else 0.0)
	_s = 0.0
	_seg = 0
	_place(0.0)
	if not _waiter.is_empty():
		# He stands by his bike (city life draws him) until ŚCIGAJ; the node only carries the bubble.
		var w0: Vector3 = _waiter[0]
		_rider.global_position = w0
		_rider.rotation.y = float(_waiter[1])
	_rider.visible = _waiter.is_empty()
	state = State.OFFER
	_t = 0.0
	if dialogue != null:
		dialogue.say(_rider, "Pędzik", "pedzik", "challenge", 4.5, COLOUR, 2.4, true)
	print("courier: challenge: the rider's way %d m, %.2f × the straight %d m%s" % [roundi(path_len), path_len / maxf(straight, 1.0),
			roundi(straight), " (a courier waiting at stand %d)" % stand_i if not _waiter.is_empty() else ""])


## The rider on along its way; at its end it waits at the door.
func _ride(dt: float) -> void:
	_s = minf(_s + speed * dt, path_len)
	_place(_s)
	if _s >= path_len - 0.01:
		rider_first = true
		_rider_left = 0.0
		if dialogue != null:
			dialogue.say(_rider, "Pędzik", "pedzik", "win", 4.5, COLOUR, 2.4, true)
		if hud != null:
			hud.toast("Pędzik pierwszy pod drzwiami", "The courier got to the door first")
		print("courier: the rider at the door first after %.1f s" % _t)


func _place(s: float) -> void:
	while _seg < _pts.size() - 2 and _cum[_seg + 1] < s:
		_seg += 1
	var a := _pts[_seg]
	var b := _pts[mini(_seg + 1, _pts.size() - 1)]
	var span := maxf(_cum[mini(_seg + 1, _cum.size() - 1)] - _cum[_seg], 0.001)
	var k := clampf((s - _cum[_seg]) / span, 0.0, 1.0)
	var p := a.lerp(b, k)
	var y := lerpf(_h[_seg], _h[mini(_seg + 1, _h.size() - 1)], k)
	_rider.global_position = Vector3(p.x, y, p.y)
	var dir := b - a
	if dir.length_squared() > 0.0001:
		_rider.rotation.y = atan2(-dir.x, -dir.y)


## The car's driving distance to the door: from the nearest lane (either way), else the straight
## line × 1.3 (as rivals.gd's), plus nothing for the last few metres to the ring.
func _remaining() -> float:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var straight_left := p.distance_to(Vector2(_door.x, _door.z))
	if graph == null or _dist.is_empty():
		return straight_left * 1.3
	# The lane the car is driving along (its heading): on a dual carriageway the nearest lane can be
	# the other side's, a long way round.
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 25.0, heading)
	if hit.is_empty():
		hit = graph.snap(p, 25.0)
	if hit.is_empty():
		return straight_left * 1.3
	var e: int = hit[0]
	var s: float = hit[2]
	var best := _to_door(e, s)
	var rev := graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, _to_door(rev, graph.e_len[e] - s) + 25.0)
	if best >= INF:
		return straight_left * 1.3
	return minf(best, straight_left * 3.0) if straight_left < 40.0 else best


## The road from lane point (e, s) to the door's point.
func _to_door(e: int, s: float) -> float:
	if e == _door_e and s <= _door_s:
		return _door_s - s
	var best := graph.remaining(_dist, e, s) + _door_s
	var rev := graph.e_reverse[_door_e]
	if rev >= 0 and not _dist_rev.is_empty():
		var rs := graph.e_len[_door_e] - _door_s
		if e == rev and s <= rs:
			return minf(best, rs - s)
		best = minf(best, graph.remaining(_dist_rev, e, s) + rs)
	return best


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
