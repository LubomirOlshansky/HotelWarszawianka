extends SceneTree
## Podwózka on the activity kit (scripts/rides.gd, tech-debt TD-1), played headless: the real Rides
## on the shared stand-ins of tools/fakes.gd (a HUD, a dialogue, a wallet, the rescue calls, the
## bubbles) and a few of its own (a small city of 7 x 7 junctions 400 m apart with address doors
## along every street, a river on the east side, a pond, two roofs, a ghost driver in traffic, the
## jobs.gd side: an address by road and a kerb by a door), a fixed seed, no map data. Rides that
## are driven by hand run without an await (a frame is a call); the autopilot's rides run over the
## engine's own frames (`--fixed-fps 60`, its `drive_player` reads the frame's delta). Numbers and
## words are literals here, the roads, doors and names come from the rig's own data and from the
## ride as the request gave it (`q._ride`, read once), never read back at the moment of the check.
## It states, per fact, what the old script did and the kit's job must still do:
##   A. the settings and what `setup` builds;  B. idle: the button, the first two minutes, what
##   holds a request back, the tap, the quiet walk, the guide's hold, the clock that stands away;
##   C. the request card, its surge, its 10 s, SKIP, the keys, taken back and taken away, a foreign
##   card over it;  D. the way to the passenger: the pin and the passenger, the status line, their
##   line, START KURS, boarding by stopping, giving up, the ✕ and the cancelled card;  E. the ride:
##   the status line, the talk, the stars lost by driving, the police, lateness, the door, the pay
##   and its card, the passenger getting out;  F. the quirks (river, park, recalculation, the Frogs
##   turn), the Frogs stop;  G. the kinds of passenger and the day's rules;  H. the story
##   passengers (lines, the question, the answers, silence, the ✕ and the door under it, a foreign
##   card over it, the order of the stories);  I. the autopilot, frame by frame;  J. the least the
##   game hands in (no traffic, no rivals, no clock, an older bake);  K. a save that has driven
##   before;  L. the director;  M. what deliberate breaks of the script showed.
## Prints "check_ride_play: OK (N checks; ...)" or one "  problem: ..." line per failed fact under
## "check_ride_play: PROBLEMS" (exit 1).
##   godot --headless --fixed-fps 60 --path game --script res://tools/check_ride_play.gd

const Rides := preload("res://scripts/rides.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Missions := preload("res://scripts/missions.gd")
const Stories := preload("res://scripts/taxi_stories.gd")
const DT := 1.0 / 60.0
const SEED := 20261113
const BASE := 4242
## The grid: junctions a side, metres between them.
const N := 7
const STEP := 400.0
## The river's edge (water east of it), the pond, the roofs.
const SHORE := 2440.0
const POND := Vector2(1000.0, 1400.0)
const ROOFS := [Rect2(830.0, 830.0, 340.0, 340.0), Rect2(112.0, 1190.0, 16.0, 8.0)]
## (Its north-west corner is 30 m in, so the finish at the junction (0, 0) lies outside what a ride may be taken to.)
const BOUNDS := Rect2(30.0, 30.0, 2670.0, 2570.0)
## The car's own lane, eastbound on Pozioma 3, and its yaw there.
const HOME := Vector2(1000.0, 1201.75)
const EAST := -PI / 2.0
const TEAL := Color("#4fd8c4")
const RED := Color("#e2574c")
const FROG_DOORS := [Vector2(810.0, 410.0), Vector2(1610.0, 1210.0), Vector2(410.0, 1610.0)]
## The second, bigger city (parts N on; a rig asks for it by `opts["big"]`): the outline without the
## corner CUT out of it, two more waters (a small pond by Pozioma 3, a puddle under a park's point), a
## third, long roof by the bank, one direction of Pionowa 6 in a tunnel, and a long spur street out of
## the south-west corner and back.
const BIG_BOUNDS := Rect2(-100.0, -100.0, 2700.0, 2600.0)
const CUT := Rect2(2420.0, -100.0, 180.0, 510.0)
const POND2 := Vector2(600.0, 1240.0)
const PUDDLE := Vector2(350.0, 1650.0)
const ROOF3 := Rect2(2405.0, 2000.0, 8.0, 400.0)
const SPUR_MID := Vector2(400.0, 4900.0)
const SPUR_END := Vector2(0.0, 7400.0)
const GATES := ["flying", "away", "mission", "water", "rescue target", "rescue offer", "a side job", "a race", "a rival calling", "a card",
		"the other activity"]


# --- the stand-ins that are this check's own ----------------------------------------------------------

## dialogue.gd's host switch, the words `say` answers with (a bubble's Polish and English) and the
## comment `line` answers with.
class PlayDialogue extends Fakes.Dialogue:
	var host_hold := false
	var say_words: Array = ["Słowo", "A word"]
	func _init() -> void:
		line_words = ["Komentarz", "A comment"]
	func say(anchor: Variant, who: String, group: String, tag := "", s := 4.0, c := Color.WHITE, h := 2.6, p := false) -> Array:
		super.say(anchor, who, group, tag, s, c, h, p)
		return say_words


## missions.gd's side the rides ask: the state of its rescue calls and whether one has a target.
class PlayCalls extends Fakes.Calls:
	var state: int = Missions.State.CLOSED
	var target := false
	func has_target() -> bool:
		return target


## rivals.gd's side: a race on, a rival's prompt, the race finishes ({name, node}).
class PlayRivals extends Node:
	var on := false
	var call_on := false
	var _finishes: Array = []
	func busy() -> bool:
		return on
	func calling() -> bool:
		return call_on


## The map as the rides ask it: its outline, the water (the river east of SHORE, a pond), roofs,
## and three heights that never agree (one taken from the wrong place shows).
class WorldMap extends Node3D:
	## Whether it is the bigger city's map (a rig sets it).
	var big := false
	## An island some scene lays in the river by the map's east edge (empty: none).
	var isle := Rect2()
	var bounds: Rect2:
		get:
			return BIG_BOUNDS if big else BOUNDS
	func in_map(p: Vector2, margin := 0.0) -> bool:
		return bounds.grow(margin).has_point(p) and not (big and CUT.grow(-margin).has_point(p))
	func shore_distance(x: float, z: float) -> float:
		# The bank bends (0 to 6 m east of SHORE), so the scan's 8 m samples fit some rows and not others.
		var d := maxf(x - (SHORE + 3.0 + 3.0 * sin(z / 90.0)), 12.0 - Vector2(x, z).distance_to(POND))
		if big:
			d = maxf(d, maxf(6.0 - Vector2(x, z).distance_to(POND2), 0.9 - Vector2(x, z).distance_to(PUDDLE)))
		if isle.has_point(Vector2(x, z)):
			d = -5.0
		return d
	func terrain_height(x: float, z: float) -> float:
		return 5.0 + 0.0007 * x - 0.0003 * z
	func ground_height(x: float, z: float) -> float:
		return 2.0 + 0.001 * x + 0.0005 * z
	func top_height(x: float, z: float, _r := 1.0) -> float:
		for r: Rect2 in ROOFS:
			if r.has_point(Vector2(x, z)):
				return terrain_height(x, z) + 12.0
		if big and ROOF3.has_point(Vector2(x, z)):
			return terrain_height(x, z) + 12.0
		return terrain_height(x, z)


## The lane graph's own map: the road's surface (not the terrain the map gives).
class RoadMap extends Node3D:
	func terrain_height(x: float, z: float) -> float:
		return 1.0 + 0.0011 * x - 0.0007 * z
	func tunnel_height(_t: int, x: float, z: float) -> float:
		return -4.0 + 0.0011 * x - 0.0007 * z


class PlayCar extends CharacterBody3D:
	signal bumped(collider: Object, speed: float)
	var vel := Vector3.ZERO
	var forward_speed := 0.0
	var in_water := false
	var throttle := 0.0
	var braking := false
	var target_dir := Vector3.ZERO


class PlayTod extends Node:
	var hour := 12.0
	var mode := 0
	var lights_on := 0.0
	func local_clock() -> Dictionary:
		return {"hour": hour}


class PlayWeather extends Node:
	var state := 0


## storefronts.gd's side: the Frogs' doors.
class PlayFrogs extends Node:
	const STAMP_REACH := 14.0
	var shops: Array = [{"triple": ""}, {"triple": "x3"}, {"triple": ""}]
	var doors: Array = FROG_DOORS.duplicate()
	func shop_near(p: Vector2, reach: float) -> int:
		for i in doors.size():
			if (doors[i] as Vector2).distance_to(p) < reach:
				return i
		return -1
	func frogs_at_junction(p: Vector2, r: float) -> int:
		return shop_near(p, r)


## The autopilot's invisible driver, as far as rides.gd reads and sets it.
class Ghost:
	var pos := Vector3.ZERO
	var yaw := 0.0
	var v := 0.0
	var arrived := false
	var speed_factor := 1.0
	var accel_factor := 1.0
	var finish := -1
	## How often the job told it to squeeze by (every assignment counts).
	var squeezes := 0
	var squeeze := 0.0:
		set(x):
			squeeze = x
			squeezes += 1


## traffic.gd's side: a ghost goes straight for its junction (14 m/s times its factor), or stands
## in a jam until it is told to squeeze by. It counts the ghosts added and removed and what each
## was raced with.
class PlayTraffic extends Node3D:
	var graph: LaneGraph
	var cam: Camera3D = null
	var view_centre := Vector2.ZERO
	var ghosts: Array = []
	var added := 0
	var removed := 0
	var raced: Array = []
	var jam := false
	## A ghost let go from a jam gains speed slowly (0.2 m/s a frame), not at once.
	var gentle := false
	func drivers() -> Array:
		return []
	func add_ghost(e: int, lane: int, s: float) -> Ghost:
		var g := Ghost.new()
		var p := graph.point_at(e, s, graph.lane_offset(e, lane))
		g.pos = Vector3(p.x, graph.surface(e, p), p.y)
		ghosts.append(g)
		added += 1
		return g
	func race_to(d: Ghost, finish: int, _dist: PackedFloat32Array, _plan: Variant = null) -> void:
		d.finish = finish
		raced.append({"finish": finish, "speed": d.speed_factor, "accel": d.accel_factor})
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
			if jam and gentle:
				sp = minf(g.v + 0.2, sp)
			if d < 2.0:
				g.arrived = true
				g.v = 0.0
				continue
			var m := minf(d, sp * dt)
			g.pos += Vector3(to.x, 0.0, to.y) / d * m
			g.yaw = atan2(-to.x, -to.y)
			g.v = sp


## jobs.gd's side the rides use, as jobs.gd has it: its own busy, an address by road, the kerb by a
## door (both on the real lane graph). `kerbs`: every door asked for; `picks`: every [lo, hi, seed].
class PlayJobs extends Node:
	var side := false
	var no_address := false
	var no_kerb := false
	## No kerb anywhere but by an address door (a passenger away from the pin finds no place).
	var no_kerb_away := false
	## An address asked for with this reach or more is handed back as one no road reaches.
	var unreached_hi := INF
	## The lane the last pickup was looked for from (the car's own).
	var from_e := -1
	var graph: LaneGraph
	var map: Node3D
	var kerbs: Array = []
	var picks: Array = []
	var _addresses: Array[Dictionary] = []
	func side_busy() -> bool:
		return side
	func _kerb(door: Vector2, _at: Vector2, half: float, offsets: Array) -> Dictionary:
		kerbs.append(door)
		if no_kerb:
			return {}
		if no_kerb_away:
			var by_door := false
			for a in _addresses:
				by_door = by_door or a["door"] == door
			if not by_door:
				return {}
		var hit := graph.snap(door, 30.0, Vector2.ZERO, true, true)
		if hit.is_empty():
			return {}
		var e: int = hit[0]
		for flip: float in [1.0, -1.0]:
			for shift: float in [0.0, 8.0, -8.0, 16.0, -16.0, 24.0, -24.0, 32.0, -32.0, 40.0, -40.0]:
				var s := clampf(float(hit[2]) + shift, graph.e_s0[e] + 2.0, graph.e_s1[e] - 2.0)
				var centre := graph.point_at(e, s)
				var dir := graph.direction(e, s)
				var right := Vector2(-dir.y, dir.x)
				var sd := right if (_at - centre).dot(right) >= 0.0 else -right
				sd *= flip
				for off: float in offsets:
					var p: Vector2 = centre + sd * (half + off)
					var ground: float = map.terrain_height(p.x, p.y)
					if map.top_height(p.x, p.y, 1.8) > ground + 0.5 or not graph.snap(p, 3.0).is_empty():
						continue
					return {"centre": centre, "side": sd, "heading": dir if sd == right else -dir, "edge": e, "s": s, "spot": p}
		return {}
	func _pick_address(e: int, s: float, from: Vector2, lo: float, hi: float, rng: RandomNumberGenerator, test: Callable, _aim := 0.0) -> Dictionary:
		picks.append([lo, hi, rng.seed])
		if hi == 600.0:
			from_e = e
		if no_address:
			return {}
		var dist := graph.distances_from(graph.e_b[e], false)
		var list: Array[Dictionary] = []
		for a in _addresses:
			var d: float = (a["door"] as Vector2).distance_to(from)
			if d >= lo * 0.55 and d <= hi and test.call(a):
				list.append(a)
		for k in range(list.size() - 1, 0, -1):
			var j := rng.randi() % (k + 1)
			var t := list[k]
			list[k] = list[j]
			list[j] = t
		for a in list.slice(0, 80):
			var hit := graph.snap(a["door"], 30.0)
			if hit.is_empty():
				continue
			var road := graph.trip(dist, e, s, hit[0], hit[2])
			var reached := road < INF
			var finish: int = graph.e_b[hit[0]]
			if road < lo or road > hi:
				continue
			var out: Dictionary = a.duplicate()
			var door: Vector2 = a["door"]
			var sd: Vector2 = ((a["at"] as Vector2) - door).normalized()
			var ring2 := door + sd * 2.0
			out["ring"] = Vector3(ring2.x, graph.surface(hit[0], ring2), ring2.y)
			out["road"] = road
			out["edge"] = hit[0]
			out["s"] = hit[2]
			out["reached"] = reached and hi < unreached_hi
			out["finish"] = finish
			return out
		return {}


# --- the rig -----------------------------------------------------------------------------------------

var problems: Array[String] = []
var _n := 0
var _sec_name := ""
var _marks: Array[String] = []
const PARTS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S"]
var _map: WorldMap
var _road: RoadMap
var _graph: LaneGraph
var _graph_small: LaneGraph
var _graph_big: LaneGraph
var _stories: Array = []
## The parts of the world, a fresh set whenever a scenario wants a clean start.
var world: Node3D
var q: Node
var hud: Fakes.Hud
var bubbles: Fakes.Bubbles
var dialogue: PlayDialogue
var wallet: Fakes.Wallet
var missions: PlayCalls
var rivals: PlayRivals
var jobs: PlayJobs
var car: PlayCar
var tod: PlayTod
var weather: PlayWeather
var frogs: PlayFrogs
var traffic: PlayTraffic
var director: Activities
var other: Activity
var data: Dictionary = {}
## What main.gd's callables answer: the club doors at dawn, the Hyrax forecourt.
var clubs: Array = []
var hurry := Vector2.INF
## `_offer_in` as `setup` threw it, before the rig sets its own.
var setup_offer_in := 0.0
## What the play hands in each frame, as main.gd does.
var _car := Vector3(HOME.x, 0.0, HOME.y)
var _vel := Vector3.ZERO
var _fwd := 0.0
var _yaw := EAST
var _fly := false
var _away := false
var _mission := false
var _frames := 0
## Frames at the moment a ride was boarded (the ride's clock counts from there).
var _boarded_at := 0


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	_world()
	_run_part("A", "A. settings", _a_settings)
	_run_part("B", "B. idle", _b_idle)
	_run_part("C", "C. the request", _c_request)
	_run_part("D", "D. the way to the passenger", _d_pickup)
	_run_part("E", "E. the ride", _e_ride)
	_run_part("F", "F. the app's ideas", _f_quirks)
	_run_part("G", "G. the passengers", _g_passengers)
	_run_part("H", "H. the story passengers", _h_stories)
	_sec_name = "I. the autopilot"
	await _i_autopilot()
	_marks.append("I")
	_run_part("J", "J. the least", _j_least)
	_run_part("K", "K. a save that has driven before", _k_kept)
	_run_part("L", "L. the director", _l_director)
	_run_part("M", "M. the breaks", _m_breaks)
	_run_part("N", "N. making rides", _n_requests)
	_run_part("O", "O. the autopilot's legs", _o_auto)
	_run_part("P", "P. the pickup", _p_pickup)
	_run_part("Q", "Q. two rides in a row", _q_pairs)
	_run_part("R", "R. plans on the way", _r_plans)
	_run_part("S", "S. the plans asked straight", _s_plans)
	for part: String in PARTS:
		if not _marks.has(part):
			problems.append("part %s did not run to its end (a script error?)" % part)
	if problems.is_empty():
		# No time in the line (verify.sh's table has it), so every run prints the same one.
		print("check_ride_play: OK (%d checks; A-S, %d frames by hand)" % [_n, _frames])
		quit(0)
	else:
		print("check_ride_play: PROBLEMS")
		for p in problems:
			print("  problem: " + p)
		quit(1)


## The maps and the two lane graphs, made once and shared by every rig.
func _world() -> void:
	_map = WorldMap.new()
	root.add_child(_map)
	_road = RoadMap.new()
	root.add_child(_road)
	_graph_small = LaneGraph.new(_graph_data(), _road)
	_graph_big = LaneGraph.new(_graph_data(true), _road)
	_graph = _graph_small
	_stories = _own_stories()


func _run_part(mark: String, name: String, f: Callable) -> void:
	_sec_name = name
	f.call()
	_marks.append(mark)


func _ok(cond: bool, what: String) -> void:
	_n += 1
	if not cond:
		problems.append("[%s] %s" % [_sec_name, what])


# --- the small city ---------------------------------------------------------------------------------

func _node(i: int, j: int) -> int:
	return j * N + i


func _edge(a: int, b: int, name: String) -> Dictionary:
	var pa := Vector2((a % N) * STEP, (a / N) * STEP)
	var pb := Vector2((b % N) * STEP, (b / N) * STEP)
	var m := pa.lerp(pb, 0.5)
	return {"a": a, "b": b, "p": [pa.x, pa.y, m.x, m.y, pb.x, pb.y], "s0": 6.0, "s1": STEP - 6.0, "n": 1, "o": 1.75, "lw": 3.5,
			"v": 13.9, "k": "residential", "name": name}


func _graph_data(big := false) -> Dictionary:
	var nodes: Array = []
	var scc: Array = []
	for j in N:
		for i in N:
			nodes.append(i * STEP)
			nodes.append(j * STEP)
			scc.append(1)
	var edges: Array = []
	for j in N:
		for i in N:
			if i + 1 < N:
				edges.append(_edge(_node(i, j), _node(i + 1, j), "Pozioma %d" % j))
				edges.append(_edge(_node(i + 1, j), _node(i, j), "Pozioma %d" % j))
			if j + 1 < N:
				edges.append(_edge(_node(i, j), _node(i, j + 1), "Pionowa %d" % i))
				edges.append(_edge(_node(i, j + 1), _node(i, j), "Pionowa %d" % i))
				if big and i == N - 1 and j == 3:
					# Pionowa 6's southbound side runs in a tunnel between Pozioma 3 and 4 (a portal at each end).
					edges[-2]["tn"] = 0
					edges[-2]["po"] = 3
	if big:
		# The spur (node 49 at its far end), out of the corner (0, 6) and back, with a bend half way.
		nodes.append(SPUR_END.x)
		nodes.append(SPUR_END.y)
		scc.append(1)
		var corner := Vector2(0.0, (N - 1) * STEP)
		var run := corner.distance_to(SPUR_MID) + SPUR_MID.distance_to(SPUR_END)
		for back: bool in [false, true]:
			var a := SPUR_END if back else corner
			var b := corner if back else SPUR_END
			edges.append({"a": N * N if back else _node(0, N - 1), "b": _node(0, N - 1) if back else N * N,
					"p": [a.x, a.y, SPUR_MID.x, SPUR_MID.y, b.x, b.y], "s0": 6.0, "s1": run - 6.0, "n": 1, "o": 1.75, "lw": 3.5,
					"v": 13.9, "k": "residential", "name": "Ostroga"})
	return {"nodes": nodes, "scc": scc, "edges": edges, "ctrl": []}


func _addr(name: String, door: Vector2, out: Vector2, d: String) -> Dictionary:
	var at := door + out * 8.0
	return {"k": "address", "name": name, "door": [door.x, door.y], "x": at.x, "z": at.y, "d": d}


## The index as main.gd reads it: address doors along every street (the north-east corner's are
## Praga's), parks (one in the pond, one under a roof), the spawn, the bank spots.
func _data(bank: bool, spawn := Vector2(1200.0, 1200.0), big := false) -> Dictionary:
	var pois: Array = []
	for j in N:
		for i in N - 1:
			var d := "praga" if j == 0 and i >= 4 else ""
			pois.append(_addr("Pozioma %d m. %d" % [j, 2 * i + 1], Vector2(i * STEP + 120.0, j * STEP - 9.0), Vector2(0.0, -1.0), d))
			pois.append(_addr("Pozioma %d m. %d" % [j, 2 * i + 2], Vector2(i * STEP + 280.0, j * STEP + 9.0), Vector2(0.0, 1.0), d))
	for i in N:
		for j in N - 1:
			pois.append(_addr("Pionowa %d m. %d" % [i, 2 * j + 1], Vector2(i * STEP - 9.0, j * STEP + 150.0), Vector2(-1.0, 0.0), ""))
			pois.append(_addr("Pionowa %d m. %d" % [i, 2 * j + 2], Vector2(i * STEP + 9.0, j * STEP + 250.0), Vector2(1.0, 0.0), ""))
	# By the gate of Pod Gigantami, on Pionowa 0.
	pois.append(_addr("Aleje 49", Vector2(-9.0, 790.0), Vector2(-1.0, 0.0), ""))
	for p: Array in [["Park Rogu", 450.0, 450.0], ["Park Środka", 1250.0, 850.0], ["Park Wschodu", 2050.0, 1650.0],
			["Park w Stawie", POND.x, POND.y + 4.0], ["Park pod Dachem", 1000.0, 1000.0], ["Park Zachodu", 350.0, 1250.0]]:
		pois.append({"k": "park", "name": p[0], "x": p[1], "z": p[2]})
	if big:
		pois.append({"k": "park", "name": "Park w Kałuży", "x": PUDDLE.x, "z": PUDDLE.y})
	pois.append({"k": "kebab", "name": "nie nasze", "x": 0.0, "z": 0.0})
	var out := {"pois": pois, "spawn": {"x": spawn.x, "z": spawn.y}}
	if bank:
		var spots: Array = []
		for z: float in [200.0, 600.0, 1000.0, 1400.0, 1800.0, 2200.0]:
			spots.append([SHORE - 5.0, z, 2398.25 if big and z == 1400.0 else 2400.0, z])
		spots.append([SHORE - 5.0, 3000.0, 2400.0, 3000.0])  # outside the map
		spots.append([SHORE - 5.0, 1100.0, 2300.0, 1100.0])  # no lane by it
		out["drivable_bank"] = spots
	return out


## The real stories, each sent to a place of this city: most to an address door, every third to a
## big site with no door near (its `drop` lane point).
func _own_stories() -> Array:
	var out: Array = Stories.load_all().duplicate(true)
	for i in out.size():
		var st: Dictionary = out[i]
		var col := i % 6
		var row := (i / 6) % N
		if i % 3 == 2:
			st["to"] = {"name": st["to"]["name"], "at": [col * STEP + 200.0, row * STEP + 200.0], "r": 120,
					"drop": [col * STEP + 200.0, row * STEP + 1.75]}
		else:
			st["to"] = {"name": st["to"]["name"], "at": [col * STEP + 120.0, row * STEP - 9.0], "r": 60}
	return out


## A fresh world: the job as main.gd makes it (the members, `map_data`, the kit's `setup`), the
## director with a second, empty activity, the car at HOME by day, 200 s of play behind it. `full`:
## everything main.gd hands in; false: the least (no traffic, rivals, clock, weather, callables, no
## bank spots). `opts`: "big" (the second city), "bank" (false: no bank list, the scan), "fresh" (no play behind it), "spawn" (the index's spawn), "gps_first",
## "log_on" (handed in before `setup`).
func _rig(full := true, kept := {}, opts := {}) -> void:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	hud = Fakes.Hud.new()
	bubbles = Fakes.Bubbles.new()
	dialogue = PlayDialogue.new()
	dialogue.bubbles = bubbles
	wallet = Fakes.Wallet.new()
	wallet.money = 100
	wallet.keep = kept.duplicate(true)
	missions = PlayCalls.new()
	rivals = PlayRivals.new()
	jobs = PlayJobs.new()
	car = PlayCar.new()
	tod = PlayTod.new()
	weather = PlayWeather.new()
	frogs = PlayFrogs.new()
	traffic = PlayTraffic.new()
	var big := opts.has("big")
	_map.big = big
	_graph = _graph_big if big else _graph_small
	data = _data(bool(opts.get("bank", full)), opts.get("spawn", Vector2(1200.0, 1200.0)), big)
	jobs.graph = _graph
	jobs.map = _map
	for p: Dictionary in data["pois"]:
		if str(p["k"]) == "address":
			jobs._addresses.append({"name": p["name"], "door": Vector2(p["door"][0], p["door"][1]), "at": Vector2(p["x"], p["z"]),
					"d": str(p.get("d", ""))})
	traffic.graph = _graph
	rivals._finishes = [{"name": "Plac Testowy (meta)", "node": _node(1, 1)}, {"name": "Most Testowy (meta)", "node": _node(5, 5)},
			{"name": "Rondo Dalekie", "node": _node(6, 6)}, {"name": "Skwer Bliski", "node": _node(3, 3)},
			{"name": "Za Mapą", "node": _node(6, 0) if big else _node(0, 0)}]
	for nd: Node in [hud, bubbles, dialogue, wallet, missions, rivals, jobs, car, tod, weather, frogs, traffic]:
		world.add_child(nd)
	_car = Vector3(HOME.x, 0.0, HOME.y)
	_yaw = EAST
	_vel = Vector3.ZERO
	_fwd = 0.0
	_fly = false
	_away = false
	_mission = false
	car.global_position = _car
	car.rotation.y = _yaw
	clubs = []
	hurry = Vector2.INF
	q = Rides.new()
	q.autopilot = false
	q.log_on = bool(opts.get("log_on", false))
	if opts.has("gps_first"):
		q.gps_first = float(opts["gps_first"])
	world.add_child(q)
	q.hud = hud
	q.bubbles = bubbles
	q.dialogue = dialogue
	q.wallet = wallet
	q.missions = missions
	q.rivals = rivals if full else null
	q.jobs = jobs
	q.graph = _graph
	q.traffic = traffic if full else null
	q.map = _map
	q.car = car
	q.tod = tod if full else null
	q.weather = weather if full else null
	q.map_data = data
	q.free_now = func() -> bool: return true
	q.setup(world)
	q.set_process(false)
	q.set_physics_process(false)
	setup_offer_in = q._offer_in
	# The dice, the day's first ride number and the first request's clock.
	q._rng.seed = SEED
	q._base = BASE
	q._offer_in = 90.0
	q._stories = _stories.duplicate(true)
	q.force_story = "none"
	if not opts.has("fresh"):
		q._played = 200.0
	director = Activities.new()
	director.add(q, func() -> bool: return true)
	other = Activity.new()
	other.hud = hud
	other.dialogue = dialogue
	other.wallet = wallet
	other.map = _map
	other.car = car
	world.add_child(other)
	other.setup(world)
	other.set_process(false)
	director.add(other, func() -> bool: return true)
	if full:
		q.mission_on = func() -> bool: return _mission or director.busy()
		q.club_doors = func() -> Array: return clubs
		q.hurry_to = func() -> Vector2: return hurry


# --- driving it ---------------------------------------------------------------------------------------

## A frame by hand, as main.gd hands things in before the job's own frame.
func _frame() -> void:
	car.global_position = _car
	car.rotation.y = _yaw
	car.vel = _vel
	car.velocity = _vel
	car.forward_speed = _fwd
	q.flying = _fly
	q.away = _away
	q._physics_process(DT)
	q._process(DT)
	_frames += 1


func _secs(s: float) -> void:
	for i in roundi(s * 60.0):
		_frame()


## Frames until `cond` holds (at most `s` seconds): the frames it took, or -1.
func _until(cond: Callable, s: float) -> int:
	for i in roundi(s * 60.0):
		if cond.call():
			return i
		_frame()
	return 0 if cond.call() else -1


func _phase() -> int:
	return int(q.phase)


func _stage() -> int:
	return int(q.stage)


func _is_idle() -> bool:
	return _phase() == Activity.Phase.IDLE


func _on_offer() -> bool:
	return _phase() == Activity.Phase.OFFER


func _in_stage(s: int) -> bool:
	return _phase() == Activity.Phase.RUN and _stage() == s


## The car at `p`, going `speed` m/s the way it faces (`yaw`).
func _at(p: Vector2, speed := 0.0, yaw := EAST) -> void:
	_car = Vector3(p.x, _map.ground_height(p.x, p.y), p.y)
	_yaw = yaw
	_fwd = speed
	_vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed


## The car `d` m east of the place `r`.
func _by(r: Vector3, d: float, speed := 0.0) -> void:
	_at(Vector2(r.x + d, r.z), speed)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _v2(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## The harness's car where the script put its own (a test flag's teleport).
func _car_from_q() -> void:
	_car = car.global_position
	_yaw = car.rotation.y
	_vel = Vector3.ZERO
	_fwd = 0.0


func _gate(name: String, on: bool) -> void:
	match name:
		"flying":
			_fly = on
		"away":
			_away = on
		"mission":
			_mission = on
		"water":
			car.in_water = on
		"rescue target":
			missions.target = on
		"rescue offer":
			missions.state = Missions.State.OFFER if on else Missions.State.CLOSED
		"a side job":
			jobs.side = on
		"a race":
			rivals.on = on
		"a rival calling":
			rivals.call_on = on
		"a card":
			if on:
				hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
			else:
				hud.hide_card()
		"the other activity":
			if on:
				other.start()
			else:
				other.finish()
		_:
			_ok(false, "no gate %s" % name)


## A request by the clock, here and now.
func _offer_now() -> bool:
	q._offer_in = 0.05
	return _until(_on_offer, 0.5) >= 0


## Ride `n` by the test flag (--ride=N): the request is up and the car where the flag put it.
func _request(n: int) -> bool:
	var ok: bool = q.start_ride(n)
	_car_from_q()
	return ok


## The first ride from `from` on that `fits` (the others are skipped); -1 when none in 120.
func _find(from: int, fits: Callable) -> int:
	for n in range(from, from + 120):
		if not _request(n):
			continue
		if fits.call(q._ride):
			return n
		hud.press(1)
	_ok(false, "no ride from %d on fits" % from)
	return -1


func _take() -> void:
	hud.press(0)


## Stops by the waiting passenger until they are in.
func _board(r: Dictionary) -> bool:
	var b: Vector3 = r["board"]
	_at(Vector2(b.x, b.z))
	var got := _until(func() -> bool: return _in_stage(Rides.Stage.RIDE), 1.2) >= 0
	_boarded_at = _frames
	return got


## Stops at the door until the ride is over.
func _arrive(r: Dictionary) -> bool:
	var g: Vector3 = r["ring"]
	_at(Vector2(g.x, g.z))
	return _until(func() -> bool: return _in_stage(Rides.Stage.RESULT), 0.2) >= 0


## The result card closed by M.
func _close() -> void:
	_secs(2.7)
	q.primary()
	_frame()


## A request, taken, boarded, to the door and the card closed: the ride of `n`.
func _through(n: int) -> Dictionary:
	_request(n)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	_arrive(r)
	_close()
	return r


func _bump(speed: float) -> void:
	car.bumped.emit(null, speed)


func _abort() -> void:
	hud.abort_pressed.emit()


func _tap(owner: String) -> void:
	hud.context_pressed.emit(owner)


func _toast_n() -> int:
	return hud.toasts.size()


func _last_toast() -> String:
	return hud.toasts.back() if not hud.toasts.is_empty() else ""


func _last_toast_en() -> String:
	return hud.toasts_en.back() if not hud.toasts_en.is_empty() else ""


## 4.5 -> "4,5" (Polish) or "4.5".
func _num(x: float, places := 1, polish := true) -> String:
	var t := ("%." + str(places) + "f") % x
	return t.replace(".", ",") if polish else t


func _stars_text(x: float) -> String:
	var full := floori(x)
	return "★".repeat(full) + ("½" if x - full >= 0.5 else "") + " " + _num(x)


func _rating_after(history: Array) -> float:
	var h := history.slice(maxi(0, history.size() - 20))
	var sum := 4.87 * (20 - h.size())
	for x in h:
		sum += float(x)
	return sum / 20.0


## The pay by the rules as the brief states them.
func _pay(road: float, final: float, night: bool, rain: bool, hurry_kind: bool, streak: int, story := 0) -> Dictionary:
	var mult := (1.5 if night else 1.0) * (1.2 if rain else 1.0)
	var fare := roundi((15.0 + 9.0 * road / 1000.0) * mult)
	var share := 0.40 if final >= 5.0 else (0.25 if final >= 4.5 else (0.10 if final >= 4.0 else 0.0))
	var tip := roundi(fare * share * (1.2 if hurry_kind else 1.0))
	var seria := mini(10 * streak, 50) if final >= 5.0 else 0
	var st := maxi(story, -tip - seria)
	return {"fare": fare, "tip": tip, "seria": seria, "story": st, "total": fare + tip + seria + st, "mult": mult,
			"respect": 25 if final >= 5.0 else (10 if final >= 4.0 else 0)}


func _eta(r: Dictionary) -> float:
	return (float(r["road"]) / 9.0 + 20.0) * (0.8 if str(r["type"]) == "hurry" or str(r["type"]) == "date" else 1.0)


func _addr_door(pin_name: String) -> Vector2:
	for a: Dictionary in jobs._addresses:
		if str(a["name"]) == pin_name:
			return a["door"]
	return Vector2.INF


func _addr_flag(pin_name: String) -> String:
	for a: Dictionary in jobs._addresses:
		if str(a["name"]) == pin_name:
			return str(a["d"])
	return "?"


func _ring_look(b: Node3D) -> Array:
	if not b.visible:
		return [false]
	return [true, b.position, b._ring_radius, b._colour, b.waving, b._column.visible, b._person.visible]



# --- A. the settings ------------------------------------------------------------------------------------

func _a_settings() -> void:
	_rig(true, {"podwozka_ratings": [5.0, 4.0]})
	_ok(q.tag == "podwózka" and q.is_job and not q.offer_busy and not q.cards_hold and not q.cards_low and not q.flown,
			"the tag, a job, the request leaves the player free, the cards do not hold the drive, beside the road, not flown")
	_ok(q.card_life == 10.0 and q.play_limit == 0.0, "the request's life is 10 s, the run has no limit")
	_ok(_phase() == Activity.Phase.IDLE and _stage() == Rides.Stage.NONE and q.idle() and not q.busy() and not q.offering(),
			"idle with no stage: not busy, not offering")
	_ok(not q.has_target() and q.stop_spot() == Vector3.INF and q.grounded() == [], "no target, no stop spot, nothing grounds the helicopter")
	_ok(q.target_arrow() and q.target_label(123) == "123 m" and q.target_colour() == TEAL, "the arrow shows, its metres, the teal")
	var look := _ring_look(q._beacon)
	_ok(look == [false] and q._beacon._colour == TEAL, "the ring is teal and hidden")
	var body := q._beacon._person.get_child(2) as MeshInstance3D
	var shirt := ((body.mesh as BoxMesh).material as StandardMaterial3D).albedo_color
	_ok(shirt == Color("#3b8f5a"), "the ring's person wears a green shirt")
	_ok(not q._rider.visible and q._bang.scale == Vector3.ONE * 1.6 and q._rider_mesh.scale == Vector3.ONE * 1.35,
			"the waiting passenger is hidden, the '!' 1.6 times, the body 1.35 times")
	_ok(setup_offer_in >= 75.0 and setup_offer_in <= 120.0, "the first request's clock is 75 to 120 s: %.1f" % setup_offer_in)
	var want_parks := ["Park Rogu", "Park Środka", "Park Wschodu", "Park Zachodu"]
	var got_parks: Array = []
	for pk: Dictionary in q._parks:
		got_parks.append(str(pk["name"]))
	_ok(got_parks == want_parks, "the parks without the one in the pond and the one under a roof: %s" % [got_parks])
	_ok(q._addresses.size() == jobs._addresses.size() and q._addresses.size() == 169, "every address of the index: %d" % q._addresses.size())
	var same := true
	var praga := 0
	for i in q._addresses.size():
		var a: Dictionary = q._addresses[i]
		var b: Dictionary = jobs._addresses[i]
		if a["name"] != b["name"] or a["door"] != b["door"] or a["at"] != b["at"] or a["d"] != b["d"]:
			same = false
		if str(a["d"]) == "praga":
			praga += 1
	_ok(same and praga == 4, "the addresses with their doors and street-side flags (%d in Praga)" % praga)
	_ok(not q._spawn_lane.is_empty(), "the spawn has a lane")
	_ok(q.river_spots.size() == 6 and q._river_ready, "the bake's river spots: 6 of the 8 (not outside the map, not without a lane): %d" % q.river_spots.size())
	_ok(q.map_data == {}, "the index is let go after setup")
	_ok(q.moments != null and q.moments.traffic == traffic and q.moments.dialogue == dialogue and q.moments.log_on == q.log_on
			and q.moments.first_in == q.gps_first and q.moments.get_parent() == q, "the GPS moments are a child with the traffic and the dialogue")
	var want := (5.0 + 4.0 + 18.0 * 4.87) / 20.0
	_ok(absf(q._rating() - want) < 0.0001, "the rating of [5, 4] reads %.4f, want %.4f" % [q._rating(), want])
	_rig(true, {}, {"gps_first": 33.0, "log_on": true})
	_ok(q.moments.first_in == 33.0 and q.moments.log_on, "the GPS moments get gps_first and log_on")
	_rig(false)
	_ok(q.moments == null and q.river_spots.is_empty() and not q._river_ready, "the bare rig: no GPS moments, the river not yet scanned")


# --- B. idle ----------------------------------------------------------------------------------------------

func _b_idle() -> void:
	_rig(true, {}, {"fresh": true})
	_at(HOME)
	_secs(1.0)
	_ok(hud.pill == "", "no button in the first two minutes")
	_ok(not q.can_request(), "no request can be asked for in the first two minutes")
	q.request()
	_secs(0.3)
	_ok(_toast_n() == 0 and _is_idle(), "request() did nothing in the first two minutes")
	q._played = 119.9
	_secs(2.0 / 60.0)
	_ok(hud.pill == "", "the button came before 120 s")
	_secs(8.0 / 60.0)
	_ok(hud.pill == "ride" and hud.pill_word == "PODWÓZKA" and q.can_request(), "the PODWÓZKA button after 120 s")
	for gate: String in GATES:
		_gate(gate, true)
		_secs(2.0 / 60.0)
		_ok(hud.pill == "", "the button stayed up in spite of %s" % gate)
		_ok(not q.can_request(), "a request could be asked for in spite of %s" % gate)
		q._offer_in = 0.2
		_secs(0.5)
		_ok(_is_idle(), "a request by the clock in spite of %s" % gate)
		var t0 := _toast_n()
		q.request()
		_secs(0.3)
		_ok(_toast_n() == t0 and _is_idle(), "request() did something in spite of %s" % gate)
		_gate(gate, false)
		q._offer_in = 60.0
		_secs(2.0 / 60.0)
		_ok(hud.pill == "ride", "the button did not come back after %s" % gate)
	# A rescue call ringing: the button is the call's, a request still comes.
	missions.state = Missions.State.RINGING
	_secs(2.0 / 60.0)
	_ok(hud.pill == "" and q.can_request(), "a ringing call: the button down (it is the call's), a request still possible")
	_ok(_offer_now(), "a request comes while a rescue call rings")
	_secs(0.5)
	_ok(_on_offer(), "the ringing call did not take the request away")
	missions.state = Missions.State.CLOSED
	hud.press(1)
	_ok(_is_idle(), "SKIP closed the request")
	_secs(2.0 / 60.0)
	# Somebody else holds the button.
	hud.pill = "tape"
	hud.pill_free = false
	_secs(3.0 / 60.0)
	_ok(hud.pill == "tape", "PODWÓZKA took a button that outranks it")
	hud.pill = ""
	hud.pill_free = true
	_secs(2.0 / 60.0)
	_ok(hud.pill == "ride", "the button did not come back once it was free")
	# A tap on the button.
	q._offer_in = 60.0
	var toasts0 := _toast_n()
	_tap("ride")
	_ok(q._pill_at >= 0.0 and _toast_n() == toasts0 + 1, "the tap was taken, one toast")
	_ok(_last_toast() == "Szukam kursu…" and _last_toast_en() == "Finding you a ride…", "the toast reads: %s / %s" % [_last_toast(), _last_toast_en()])
	var at0: float = q._pill_at
	_tap("ride")
	_ok(q._pill_at == at0 and _toast_n() == toasts0 + 1, "a second tap started the wait again or toasted again")
	_secs(1.1)
	_ok(_is_idle(), "the request came before the button's 1.2 s")
	_secs(0.2)
	_ok(_on_offer(), "no request by 1.3 s after the tap")
	_ok(hud.pill == "", "the button stayed up beside the request")
	_ok(q.secondary() and _is_idle(), "K skipped the request")
	_ok(not q.secondary() and not q.primary(), "the keys do nothing while idle")
	_secs(2.0 / 60.0)
	# request() while free is a tap.
	var t1 := _toast_n()
	q.request()
	_ok(_toast_n() == t1 + 1, "request() while free toasts like a tap")
	_ok(_until(_on_offer, 1.5) >= 0, "request() brought a request")
	hud.press(1)
	_secs(2.0 / 60.0)
	# A tap, then a race on for 2 frames.
	_tap("ride")
	_secs(0.5)
	_gate("a race", true)
	_secs(2.0 / 60.0)
	_gate("a race", false)
	_secs(1.5)
	_ok(_is_idle(), "the tap outlived the race")
	# Spacer: a quiet walk.
	q.quiet = true
	q._offer_in = 0.2
	_secs(1.0)
	_ok(_is_idle(), "a request by itself on a quiet walk")
	_tap("ride")
	_ok(_until(_on_offer, 1.5) >= 0, "a tap brings a request on a quiet walk")
	hud.press(1)
	q.quiet = false
	_secs(2.0 / 60.0)
	# The guide's hold.
	q.guide_hold = true
	q._offer_in = 0.2
	_secs(1.0)
	_ok(_is_idle(), "a request while the guide holds them")
	_ok(q._offer_in == 30.0, "the guide's hold puts the request 30 s off: %s" % q._offer_in)
	_tap("ride")
	_ok(_until(_on_offer, 1.5) >= 0, "a tap brings a request in the guide's hold")
	hud.press(1)
	q.guide_hold = false
	_secs(2.0 / 60.0)
	# No road near; a road only against the car's way.
	var offers: int = q._offers
	_at(Vector2(200.0, 200.0))
	q._offer_in = 0.1
	_secs(0.5)
	_ok(_is_idle() and q._offers == offers, "a request with no road within 60 m (offers %d / %d)" % [q._offers, offers])
	_at(Vector2(1000.0, 1245.0), 0.0, EAST)
	_ok(_offer_now(), "a road only against the car's way still gives a request")
	hud.press(1)
	_at(HOME)
	_secs(2.0 / 60.0)
	offers = q._offers
	jobs.no_address = true
	q._offer_in = 0.1
	_secs(0.5)
	_ok(_is_idle() and q._offers == offers + 1, "a request with no address: none, but counted (%d after %d)" % [q._offers, offers])
	jobs.no_address = false
	jobs.no_kerb = true
	q._offer_in = 0.1
	_secs(0.5)
	_ok(_is_idle(), "a request with no kerb")
	jobs.no_kerb = false
	# The clock stands while away.
	var played: float = q._played
	var session: float = q._session
	_away = true
	_secs(0.5)
	_ok(q._played == played, "the play clock ran while away")
	_ok(q._session > session, "the kit's own clock should not stand while away (it never does)")
	_away = false
	_secs(2.0 / 60.0)
	# After a request by the clock: the next one 75 to 120 s off; idle holds nothing.
	_ok(not dialogue.host_hold and not q.moments.held, "the host and the GPS moments are held while idle")
	q._offer_in = 0.05
	_until(_on_offer, 0.5)
	_ok(q._offer_in >= 75.0 and q._offer_in <= 120.0, "the next request's clock is 75 to 120 s: %.1f" % q._offer_in)


# --- C. the request ---------------------------------------------------------------------------------------

## The request card's body as the brief words it: from the ride as the request gave it.
func _offer_body(r: Dictionary, polish: bool) -> String:
	var note: Array = r["note"]
	return "%s ★ %s · %d m · %s km\n%s" % [r["name"], _num(float(r["their"]), 1, polish), roundi(float(r["away"])),
			_num(float(r["road"]) / 1000.0, 1, polish), str(note[0] if polish else note[1])]


func _c_request() -> void:
	_rig()
	_at(HOME)
	var tickers0 := hud.tickers
	_ok(_offer_now(), "a request by the clock")
	var r: Dictionary = q._ride.duplicate(true)  # read once, when the request went up
	_ok(_phase() == Activity.Phase.OFFER and _stage() == Rides.Stage.NONE and not q.busy() and q.offering() and not q.idle(),
			"the request: offer phase, no stage, not busy, offering")
	_ok(not q.has_target() and director.current() == null and director.may_start(other), "the request: no target, the director sees nothing on")
	_ok(hud.side and hud.card_is(q) and not hud.stacked and hud.face == "", "the request: beside the road, its own card, not stacked, no face")
	_ok(hud.card == "PODWÓZKA · NOWY KURS" and hud.card_en == "New ride" and hud.accent == TEAL, "the request's title and colour: %s" % hud.card)
	_ok(hud.button_words == PackedStringArray(["ACCEPT", "SKIP"]), "the request's buttons: %s" % [hud.button_words])
	_ok(r["note"] == ["Komentarz", "A comment"], "the note is the request line: %s" % [r["note"]])
	_ok(hud.body == _offer_body(r, true), "the request's body: %s / %s" % [hud.body, _offer_body(r, true)])
	_ok(hud.body_en == _offer_body(r, false), "the request's English body: %s" % hud.body_en)
	_ok(dialogue.line_asks.size() > 0 and dialogue.line_asks.has("podwozka_request:"), "the request line was asked for")
	_ok(hud.tickers == tickers0 + 1 and hud.pill == "", "the ticker went out, the button is down")
	_ok(dialogue.host_hold and q.moments.held, "the host and the GPS moments wait for the request")
	_ok(jobs.picks[0][0] == 150.0 and jobs.picks[0][1] == 600.0 and jobs.picks[0][2] == (BASE + 1) * 9973 + 17,
			"the pickup is asked 150 to 600 m by road, from the ride's own dice: %s" % [jobs.picks[0]])
	var dest_asked := false
	for pk: Array in jobs.picks:
		if pk[0] == 600.0 and pk[1] == 2500.0:
			dest_asked = true
	_ok(dest_asked or r["dest"] != "", "the destination is asked 600 to 2,500 m by road")
	var road := float(r["road"])
	_ok(road >= 600.0 and road <= 2500.0 and float(r["away"]) >= 0.0, "the ride is %.0f m by road" % road)
	# The ✕ does nothing; the calls are not touched.
	var closed0 := missions.closed
	_abort()
	_ok(_on_offer() and not missions.paused and missions.closed == closed0, "the ✕ did something to the request, or the calls were touched")
	# Nobody answers.
	var money := wallet.money
	var toasts := _toast_n()
	_secs(9.9)
	_ok(_on_offer(), "the request went before its 10 s")
	_secs(0.2)
	_ok(_is_idle() and hud.card == "" and _toast_n() == toasts and wallet.money == money, "the request stayed up or did something after its 10 s")
	_ok(q._ride["n"] == r["n"] and q._ride["name"] == r["name"], "the ride of a request nobody took stays")
	_secs(3.0 / 60.0)
	_ok(not dialogue.host_hold and not q.moments.held, "the host stayed held after the request")
	# SKIP and the keys.
	_offer_now()
	hud.press(1)
	_ok(_is_idle() and hud.card == "" and _toast_n() == toasts, "SKIP: idle, no toast")
	_offer_now()
	_ok(q.secondary() and _is_idle(), "K skipped the request")
	_offer_now()
	_ok(q.primary() and _in_stage(Rides.Stage.PICKUP), "M took the request")
	_ok(not q.primary() and not q.secondary(), "on the way to the passenger the keys do nothing")
	_abort()
	_close()
	_secs(3.0 / 60.0)
	# Taken back at the next frame, no toast.
	for gate: String in ["flying", "away", "a rival calling"]:
		_offer_now()
		_secs(0.3)
		var t0 := _toast_n()
		_gate(gate, true)
		_frame()
		_ok(_is_idle() and hud.card == "" and _toast_n() == t0, "the request stayed up or toasted in spite of %s" % gate)
		_gate(gate, false)
		_secs(3.0 / 60.0)
	# Taken away by somebody else starting; their card is theirs.
	for gate: String in ["rescue offer", "a side job", "a race"]:
		_offer_now()
		_secs(0.3)
		_gate(gate, true)
		hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
		_frame()
		_ok(_is_idle() and hud.card == "INNA", "%s puts its own card up: the request goes, the card stays (%s)" % [gate, hud.card])
		hud.hide_card()
		_gate(gate, false)
		_secs(3.0 / 60.0)
		_offer_now()
		_secs(0.3)
		_gate(gate, true)
		_frame()
		_ok(_is_idle() and hud.card == "", "%s with no card of its own: the request's card came down (%s)" % [gate, hud.card])
		_gate(gate, false)
		_secs(3.0 / 60.0)
	# Not taken back by a mission on, the water, a rescue call ringing.
	for gate: String in ["mission", "water", "ringing"]:
		_offer_now()
		if gate == "ringing":
			missions.state = Missions.State.RINGING
		else:
			_gate(gate, true)
		_secs(0.5)
		_ok(_on_offer() and hud.card == "PODWÓZKA · NOWY KURS", "%s took the request away" % gate)
		missions.state = Missions.State.CLOSED
		_gate("mission", false)
		_gate("water", false)
		hud.press(1)
		_secs(3.0 / 60.0)
	# Somebody else's card over the request: its press goes to every listener, the request runs out.
	_offer_now()
	_secs(0.3)
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	var bc := hud.broadcast
	hud.press(0)
	_ok(hud.broadcast == bc + 1 and _on_offer(), "a press of the other's card went to every listener; the request is still on")
	_secs(10.0)
	_ok(_is_idle() and hud.card == "INNA", "the request ran out under the other's card; the other's card is still up (%s)" % hud.card)
	hud.hide_card()
	_secs(3.0 / 60.0)
	# The surge in the title.
	var cases := [[2, 0.0, false, "PODWÓZKA · MNOŻNIK ×1,5", "New ride · surge ×1.5 · night"],
			[0, 0.0, true, "PODWÓZKA · MNOŻNIK ×1,2", "New ride · surge ×1.2 · rain"],
			[2, 0.0, true, "PODWÓZKA · MNOŻNIK ×1,8", "New ride · surge ×1.8 · night + rain"],
			[3, 0.6, false, "PODWÓZKA · MNOŻNIK ×1,5", "New ride · surge ×1.5 · night"],
			[3, 0.4, false, "PODWÓZKA · NOWY KURS", "New ride"]]
	for c: Array in cases:
		tod.mode = int(c[0])
		tod.lights_on = float(c[1])
		weather.state = 1 if bool(c[2]) else 0
		_request(5)
		_ok(hud.card == c[3] and hud.card_en == c[4], "the surge: %s / %s, want %s / %s" % [hud.card, hud.card_en, c[3], c[4]])
		hud.press(1)
	tod.mode = 0
	tod.lights_on = 0.0
	weather.state = 0
	# --ride=N over a request that is up: the new one takes its place with its own 10 s.
	_request(5)
	_secs(5.0)
	_request(6)
	_ok(q._ride["n"] == 6 and jobs.picks.back() != null, "the new request took the old one's place")
	_secs(9.9)
	_ok(_on_offer(), "the new request had less than its own 10 s")
	_secs(0.2)
	_ok(_is_idle(), "the new request outlived its 10 s")
	# The same n, the same ride (but for how far away it starts).
	_request(7)
	var a: Dictionary = q._ride.duplicate(true)
	hud.press(1)
	_request(7)
	var b: Dictionary = q._ride.duplicate(true)
	hud.press(1)
	a.erase("away")
	b.erase("away")
	_ok(a == b, "the same n gives the same ride")
	_request(8)
	_ok(q._ride["n"] == 8 and q._ride["name"] != "" and jobs.picks.back()[2] == 8 * 9973 + 17, "the next n is another ride, from its own dice")
	hud.press(1)


# --- D. the way to the passenger -----------------------------------------------------------------------------

func _cancel_card(title: String, en: String, body: String, body_en: String, what: String) -> void:
	_ok(hud.card == title and hud.card_en == en, "%s: the card reads %s / %s" % [what, hud.card, hud.card_en])
	_ok(hud.body == body and hud.body_en == body_en, "%s: the body reads %s / %s" % [what, hud.body, hud.body_en])
	_ok(hud.side and hud.card_is(q) and hud.buttons == 0 and hud.accent == RED and not hud.stacked, "%s: beside the road, its own, no buttons, red" % what)


func _d_pickup() -> void:
	_rig(true, {"podwozka_streak": 3})
	_find(1, func(r: Dictionary) -> bool: return not bool(r["offset"]) and str(r["type"]) == "normal")
	var r: Dictionary = q._ride.duplicate(true)
	var nm := str(r["name"])
	var pin: Vector3 = r["pin"]
	var board: Vector3 = r["board"]
	var closed0 := missions.closed
	var pills0 := hud.pills_hidden
	var ch0 := hud.challenges_hidden
	var rides0: int = q._rides
	var tickers0 := hud.tickers
	_by(pin, 300.0, 12.0)
	_take()
	_ok(_in_stage(Rides.Stage.PICKUP) and q.busy() and director.current() == q and director.busy_tag() == "podwózka",
			"ACCEPT: the way to the passenger, busy, the director sees it")
	_ok(not director.may_start(other) and director.targeted() == q and q.has_target(), "ACCEPT: nobody else may start, the arrow is the ride's")
	_ok(hud.card == "" and missions.paused and missions.closed == closed0 + 1, "ACCEPT: no card, the calls held and the line closed")
	_ok(hud.pills_hidden == pills0 + 1 and hud.challenges_hidden == ch0 + 1, "ACCEPT: the button and the challenge taken down")
	_ok(_last_toast() == "Kurs przyjęty: %s czeka" % nm and _last_toast_en() == "Ride accepted: %s is waiting" % nm, "ACCEPT: the toast reads %s" % _last_toast())
	_ok(q._rides == rides0 + 1, "ACCEPT: one more ride counted")
	var look := _ring_look(q._beacon)
	_ok(look[0] and (look[1] as Vector3).is_equal_approx(pin) and look[2] == 12.5 and look[3] == TEAL and look[4], "the ring at the pin, 12.5 m, teal, waving: %s" % [look])
	_ok(q._rider.visible and q._rider.global_position.is_equal_approx(r["spot"]) and is_equal_approx(q._rider.rotation.y, r["spot_yaw"]),
			"the passenger waits at their spot, turned as the kerb says")
	var colours: PackedColorArray = (q._rider_mesh.mesh as Mesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	_ok(colours.has(r["shirt"]), "the passenger wears their shirt")
	_ok(hud.route.size() > 1 and hud.route_colour == TEAL and hud.route[hud.route.size() - 1].is_equal_approx(_v2(pin)), "the minimap's route is teal and ends at the pin")
	_frame()
	_ok(not dialogue.host_hold and not q.moments.held, "the host is free on the way to the passenger")
	# The status line after one frame.
	_ok(hud.status_title == "PODWÓZKA · ODBIÓR: %s" % nm and hud.count == "0:00", "the status line: %s / %s" % [hud.status_title, hud.count])
	_ok(hud.distance == "%d m" % roundi(_flat(_car, pin)) and hud.tint == TEAL and hud.progress == 0.0, "the status line's metres, colour and bar: %s" % hud.distance)
	_ok(hud.status == "Jedź do pinezki (turkusowe światło)" and hud.hint_en == "Head for the pin (the teal beacon)", "the hint from afar: %s" % hud.status)
	_ok(q.target_position() == pin and q.stop_spot() == Vector3.INF, "far away the arrow is on the pin and the stop assist is not")
	_ok(not dialogue.said.has("podwozka_pickup:"), "the passenger called out from 300 m")
	_secs(7.1)
	_ok(hud.count == "0:07", "the status line's clock after 7 s: %s" % hud.count)
	# Their line, once, from 80 m.
	_by(r["spot"], 81.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(not dialogue.said.has("podwozka_pickup:"), "the passenger called out from 81 m")
	_by(r["spot"], 79.0, 9.0)
	_secs(3.0 / 60.0)
	var said := dialogue.said.size() - 1
	_ok(dialogue.said.back() == "podwozka_pickup:" and dialogue.speakers.back() == nm and dialogue.anchors.back() == q._rider,
			"the passenger called out from 79 m: %s" % dialogue.said.back())
	_ok(dialogue.hows.back() == [4.0, TEAL, 6.5, false], "the call-out's bubble: %s" % [dialogue.hows.back()])
	_secs(1.0)
	_ok(dialogue.said.size() == said + 1, "the passenger called out more than once")
	_by(pin, 29.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(q.target_position() == board and q.stop_spot() == board, "29 m from the pin the arrow is on the passenger, the stop assist too")
	_by(board, 69.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(q.target_position() == board, "69 m from the passenger the arrow is on them")
	# The hop and the "!".
	var lo := 9.0
	var hi := -9.0
	var up := false
	var down := false
	for i in 120:
		_frame()
		lo = minf(lo, q._rider_mesh.position.y)
		hi = maxf(hi, q._rider_mesh.position.y)
		up = up or q._bang.position.y > 0.05
		down = down or q._bang.position.y < -0.05
	_ok(lo >= 0.0 and hi > 0.05, "the passenger hops (%.3f to %.3f)" % [lo, hi])
	_ok(up and down, "the '!' bobs both ways")
	# START KURS.
	_by(board, 24.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.pill == "ride_start" and hud.pill_word == "START KURS", "START KURS 24 m from the passenger: %s" % hud.pill)
	_fly = true
	_secs(3.0 / 60.0)
	_ok(hud.pill == "", "START KURS stayed up in the air")
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.PICKUP), "START KURS worked from the air")
	_fly = false
	_by(board, 26.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.pill == "", "START KURS stayed up 26 m away")
	# Boarding by stopping.
	_by(board, 14.0)
	_secs(1.5)
	_ok(_in_stage(Rides.Stage.PICKUP), "boarded from 14 m")
	_by(board, 12.0, 6.5)
	_secs(1.5)
	_ok(_in_stage(Rides.Stage.PICKUP), "boarded at 6.5 m/s")
	_by(board, 12.0, 5.9)
	_fly = true
	_secs(1.3)
	_ok(_in_stage(Rides.Stage.PICKUP), "boarded from the air")
	_fly = false
	_secs(0.5)
	_ok(hud.progress > 0.4, "the hold fills while stopped by the passenger: %.2f" % hud.progress)
	_by(board, 14.0)
	_secs(2.0 / 60.0)
	_ok(hud.progress == 0.0, "the hold was kept after leaving the passenger")
	_by(board, 12.0, 5.9)
	_tap("ride")
	_ok(not q.primary() and not q.secondary(), "the keys did something on the way to the passenger")
	_secs(0.9)
	_ok(_in_stage(Rides.Stage.PICKUP), "boarded before the hold's second")
	_secs(0.2)
	_ok(_in_stage(Rides.Stage.RIDE), "not boarded after 1.1 s stopped in the ring")
	_ok(not q._rider.visible and hud.pill == "", "the passenger still waits, or START KURS is still up, after boarding")
	var toasts := _toast_n()
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RIDE) and _toast_n() == toasts, "a tap of START KURS did something on the ride")
	_abort()
	_ok(_in_stage(Rides.Stage.RESULT), "the ✕ on the ride")
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RESULT) and _toast_n() == toasts, "a tap of START KURS did something on the result card")
	_secs(0.1)
	hud.press(0)
	_ok(_is_idle(), "a tap closed the cancelled ride's card")
	_tap("ride_start")
	_secs(3.0 / 60.0)
	_ok(_is_idle() and hud.card == "", "a tap of START KURS did something while idle")
	# START KURS starts the ride.
	_request(r["n"])
	_take()
	_by(board, 20.0, 9.0)
	_secs(3.0 / 60.0)
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RIDE), "START KURS did not start the ride")
	_abort()
	hud.press(0)
	# The pull-over on the way to the passenger costs nothing.
	_request(r["n"])
	_take()
	_by(pin, 300.0, 12.0)
	_secs(3.0 / 60.0)
	toasts = _toast_n()
	q.on_pulled_over()
	_secs(3.0 / 60.0)
	_ok(_toast_n() == toasts and _in_stage(Rides.Stage.PICKUP), "a pull-over on the way to the passenger cost something")
	# The passenger gives up after 3 x the ETA.
	var limit := 3.0 * (maxf(float(r["away"]), 60.0) / 9.0 + 20.0)
	wallet.keep["podwozka_streak"] = 3
	var saves0 := wallet.saves
	q._t = limit - 1.5 * DT
	_frame()
	_ok(_in_stage(Rides.Stage.PICKUP), "the passenger gave up before 3 x the ETA (%.1f s)" % limit)
	_frame()
	_ok(_in_stage(Rides.Stage.RESULT), "the passenger did not give up past 3 x the ETA (%.1f s)" % limit)
	var money := wallet.money
	_cancel_card("PASAŻER ANULOWAŁ", "The passenger cancelled", "%s wybiera inną Podwózkę. Bez opłat; seria przepadła." % nm,
			"%s picked another Podwózka. No charge; the streak is gone." % nm, "the passenger gave up")
	_ok(int(wallet.keep.get("podwozka_streak", -1)) == 0 and wallet.saves == saves0 + 1 and wallet.money == money, "the passenger gave up: the streak ended, saved once, no pay")
	_ok(not q._beacon.visible and not q._rider.visible and hud.route.is_empty() and hud.status_title == "", "the passenger gave up: the ring, the passenger, the route and the status line are gone")
	_ok(not q.has_target() and q.busy() and hud.tickers > tickers0, "the passenger gave up: no target, still busy, the ticker went out")
	# That card.
	_abort()
	_ok(_in_stage(Rides.Stage.RESULT), "the ✕ did something on the cancelled card")
	_ok(not q.secondary(), "K did something on the cancelled card")
	_secs(11.9)
	_ok(_in_stage(Rides.Stage.RESULT), "the cancelled card went before its 12 s")
	var closed1 := missions.closed
	_secs(0.2)
	_ok(_is_idle() and hud.card == "" and not missions.paused, "the cancelled card stayed up, or the calls stayed held")
	_ok(q._ride == {} and _stage() == Rides.Stage.NONE and hud.status_title == "" and not q._beacon.visible, "back to idle: the ride is gone")
	_ok(q._offer_in >= 75.0 and q._offer_in <= 120.0, "the next request's clock is 75 to 120 s: %.1f" % q._offer_in)
	_ok(missions.closed == closed1 + 1, "the calls' line was closed once more at the end (%d / %d)" % [missions.closed, closed1])
	# The ✕ on the way, a passenger away from the pin.
	_find(1, func(x: Dictionary) -> bool: return bool(x["offset"]))
	var o: Dictionary = q._ride.duplicate(true)
	var opin: Vector3 = o["pin"]
	var oboard: Vector3 = o["board"]
	_take()
	_by(opin, 300.0, 12.0)
	_secs(3.0 / 60.0)
	_ok(q.target_position() == opin, "far away the arrow is on the pin of a passenger away from it")
	var away_dir := (_v2(oboard) - _v2(opin)).normalized()
	_at(_v2(oboard) + away_dir * 71.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(q.target_position() == opin, "71 m from the passenger (and far from the pin) the arrow is on the pin")
	_at(_v2(oboard) + away_dir * 60.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Pinezka swoje, pasażer swoje: szukaj „!”" and hud.hint_en == "The pin is here, the passenger isn't: look for the !",
			"the hint for a passenger away from the pin: %s" % hud.status)
	_by(oboard, 20.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Stań przy pasażerze" and hud.hint_en == "Pull up by the passenger", "within 25 m of the passenger: %s" % hud.status)
	_abort()
	var onm := str(o["name"])
	_cancel_card("KURS ANULOWANY", "Ride cancelled", "%s zostaje na chodniku. Bez opłat; seria przepadła." % onm,
			"%s stays on the pavement. No charge; the streak is gone." % onm, "the ✕ on the way")
	var cancel_at := _v2(_car)
	_at(cancel_at + Vector2(24.0, 0.0), 9.0)
	_secs(0.2)
	_ok(_in_stage(Rides.Stage.RESULT), "the cancelled card went 24 m from where it came up")
	_at(cancel_at + Vector2(26.0, 0.0), 9.0)
	_secs(0.1)
	_ok(_is_idle(), "the cancelled card stayed 26 m from where it came up")
	_request(o["n"])
	_take()
	_abort()
	_ok(q.primary() and _is_idle(), "M did not close the cancelled ride's card")
	_request(o["n"])
	_take()
	_abort()
	hud.press(0)
	_ok(_is_idle(), "a tap did not close the cancelled ride's card")
	# The request is not a run: the ✕ and abort() do nothing to it.
	_request(o["n"])
	q.abort()
	_ok(_on_offer(), "abort() took the request away")
	hud.press(1)


# --- E. the ride -----------------------------------------------------------------------------------------

func _plain(r: Dictionary) -> bool:
	return str(r["quirk"]) == "" and str(r["type"]) == "normal" and not bool(r["detour"])


## A fresh rig and ride `n` boarded, the car 400 m east of the door doing 12 m/s: the ride as the request gave it.
func _ride_ready(n: int, cfg := {}) -> Dictionary:
	_rig(true, cfg.get("kept", {}))
	if cfg.has("start_stars"):
		q.start_stars = float(cfg["start_stars"])
	if cfg.has("passenger"):
		q.force_passenger = str(cfg["passenger"])
	if cfg.has("setup"):
		(cfg["setup"] as Callable).call()
	_request(n)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	_by(r["ring"], 400.0, 12.0)
	return r


func _e_ride() -> void:
	_rig()
	var n := _find(1, _plain)
	var r: Dictionary = q._ride.duplicate(true)
	var nm := str(r["name"])
	var ring: Vector3 = r["ring"]
	var tickers0 := hud.tickers
	_take()
	_board(r)
	var km := roundi(_flat(_car, ring))
	_ok(_in_stage(Rides.Stage.RIDE) and q.busy() and q.has_target(), "boarded: the ride is on")
	_ok(_last_toast() == "%s wsiada · cel: %s (%d m, strzałka)" % [nm, r["dest"], km]
			and _last_toast_en() == "%s gets in · off to %s (%d m, follow the arrow)" % [nm, r["dest"], km], "boarded: the toast reads %s" % _last_toast())
	_ok(not q._rider.visible and bubbles.hushed.back() == q._rider and hud.pill == "", "boarded: the passenger is in, hushed, the button down")
	var look := _ring_look(q._beacon)
	_ok(look[0] and (look[1] as Vector3).is_equal_approx(ring) and look[2] == 12.5 and not look[4], "boarded: the ring at the door, 12.5 m, not waving: %s" % [look])
	_ok(q.target_position() == ring and q.stop_spot() == ring, "boarded: the target and the stop assist are the door")
	_ok(hud.route[hud.route.size() - 1].is_equal_approx(_v2(ring)), "boarded: the route ends at the door")
	# The status line.
	_by(ring, 400.0, 12.0)
	var k0 := _frames
	_secs(5.0)
	var eta := _eta(r)
	_ok(hud.status_title == "PODWÓZKA → %s" % r["dest"] and hud.count == "★★★★★ 5,0" and hud.distance == "400 m" and hud.tint == TEAL,
			"the status line: %s / %s / %s" % [hud.status_title, hud.count, hud.distance])
	_ok(absf(hud.progress - float(_frames - k0 + 1) * DT / eta) < 0.003, "the status line's bar is the ride's clock over its ETA: %.4f" % hud.progress)
	_ok(hud.status == "Jedź do turkusowego światła" and hud.hint_en == "Head for the teal beacon", "the hint from afar: %s" % hud.status)
	_by(ring, 39.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Stań w kręgu" and hud.hint_en == "Pull up inside the ring", "the hint inside 40 m: %s" % hud.status)
	_by(ring, 12.0, 7.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Stań pod drzwiami" and hud.hint_en == "Stop at the door" and _in_stage(Rides.Stage.RIDE), "the hint at the door (rolling at 7 m/s): %s" % hud.status)
	_by(ring, 400.0, 12.0)
	_fly = true
	_secs(3.0 / 60.0)
	_ok(hud.status == "Wyląduj i weź auto: pasażer jedzie autem" and hud.hint_en == "Land and take the car: the passenger rides in the car", "the hint in the air: %s" % hud.status)
	_fly = false
	# The door: not from 14 m, not at 6.5 m/s, not from the air, at 5.9 m/s the next frame.
	_by(ring, 14.0)
	_secs(0.5)
	_ok(_in_stage(Rides.Stage.RIDE), "arrived from 14 m")
	_by(ring, 12.0, 6.5)
	_secs(0.5)
	_ok(_in_stage(Rides.Stage.RIDE), "arrived at 6.5 m/s")
	_by(ring, 5.0)
	_fly = true
	_secs(0.5)
	_ok(_in_stage(Rides.Stage.RIDE), "arrived from the air")
	_fly = false
	_by(ring, 12.0, 5.9)
	_frame()
	_ok(_in_stage(Rides.Stage.RESULT), "not arrived 12 m from the door at 5.9 m/s")
	_ok(q.busy() and not q.has_target() and hud.status_title == "" and hud.route.is_empty() and hud.tickers > tickers0,
			"arrived: still busy, no target, the status line down, the route empty, the ticker went out")
	look = _ring_look(q._beacon)
	_ok(look[0] and not look[4] and not look[5] and look[6], "arrived: the ring at the door dimmed and not waving: %s" % [look])
	_ok(bubbles.hushed.back() == car, "arrived: the bubbles over the car were hushed")
	_ok(dialogue.said.back() == "podwozka_gps:arrive" and dialogue.speakers.back() == "Nawigacja" and dialogue.hows.back() == [2.0, TEAL, 0.0, true],
			"arrived: Nawigacja says so: %s" % dialogue.said.back())
	_ok((dialogue.anchors.back() as Callable).call() == car.global_position + Vector3(0, 3.4, 0), "Nawigacja speaks over the car, 3.4 m up")
	_secs(0.2)
	_ok(dialogue.host_hold, "the host is held on the result")
	_ok(not q.primary() and _in_stage(Rides.Stage.RESULT), "M did something before the result card was up")
	hud.press(0)
	_ok(_in_stage(Rides.Stage.RESULT), "a tap closed a result card that was not up yet")
	_secs(2.3)
	_ok(hud.card == "", "the result card came before 2.6 s")
	_secs(0.2)
	_ok(hud.card.begins_with("KURS · "), "no result card 2.7 s after the door")
	_abort()
	_ok(_in_stage(Rides.Stage.RESULT) and not q.secondary(), "the ✕ or K did something on the result card")
	_secs(11.7)
	_ok(_in_stage(Rides.Stage.RESULT), "the result card went before its 12 s")
	_secs(0.3)
	_ok(_is_idle() and hud.card == "" and not missions.paused and not q._beacon.visible, "after the ride: a card, the calls held or the ring")
	_ok(q.primary() == false and q.secondary() == false, "the keys do something while idle")
	# The card goes once the car is 25 m off; M and a tap close it.
	var r2 := _through_to_card(n)
	var door := _v2(r2["ring"])
	_at(door + Vector2(24.0, 0.0), 9.0)
	_secs(0.2)
	_ok(_in_stage(Rides.Stage.RESULT), "the result card went 24 m from the door")
	_at(door + Vector2(26.0, 0.0), 9.0)
	_secs(0.1)
	_ok(_is_idle(), "the result card stayed 26 m from the door")
	_through_to_card(n)
	_ok(q.primary() and _is_idle(), "M did not close the result card")
	_through_to_card(n)
	hud.press(0)
	_ok(_is_idle(), "a tap did not close the result card")
	# Somebody else's card over the result card: M ends the ride and leaves the card.
	_through_to_card(n)
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_ok(q.primary() and _is_idle() and hud.card == "INNA", "M under somebody else's card: the ride ends and the other's card stays")
	hud.hide_card()
	_e_talk(n)
	_e_driving(n)
	_e_pay(n)
	_e_ends(n)


## A request, taken, boarded, driven to the door and the result card up.
func _through_to_card(n: int) -> Dictionary:
	_request(n)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	_arrive(r)
	_secs(2.7)
	return r


func _e_talk(n: int) -> void:
	var r := _ride_ready(n, {"start_stars": 5.0})
	var nm := str(r["name"])
	var start := _frames
	var times: Array[float] = []
	var seen := dialogue.said.size()
	var kinds := {}
	for i in 7200:
		_frame()
		if dialogue.said.size() > seen:
			seen = dialogue.said.size()
			times.append(float(_frames - start) * DT)
			var g: String = dialogue.said.back()
			kinds[g] = true
			if not (dialogue.speakers.back() == nm and dialogue.hows.back() == [4.5, TEAL, 2.4, false] and dialogue.anchors.back() == car):
				_ok(false, "a line of the talk: %s by %s %s" % [g, dialogue.speakers.back(), dialogue.hows.back()])
	_ok(times.size() >= 3 and times[0] >= 8.0 and times[0] <= 14.1, "the first line comes 8 to 14 s in: %s" % [times])
	var gaps_ok := true
	for i in range(1, times.size()):
		if times[i] - times[i - 1] < 25.0 or times[i] - times[i - 1] > 40.1:
			gaps_ok = false
	_ok(gaps_ok, "the next lines come 25 to 40 s apart: %s" % [times])
	for g: String in kinds.keys():
		_ok(g == "podwozka_passenger:normal" or g == "passenger:", "a line of the talk is of a known kind: %s" % g)
	# None while somebody is talking; one the frame they stop.
	_ok(_in_stage(Rides.Stage.RIDE), "the ride is still on after 120 s of talk")
	q._chat_t = 0.05
	bubbles.talking = true
	var said := dialogue.said.size()
	_secs(2.0)
	_ok(dialogue.said.size() == said, "the passenger spoke over another bubble")
	bubbles.talking = false
	_secs(3.0 / 60.0)
	_ok(dialogue.said.size() == said + 1, "the passenger said nothing once the bubble was free")
	# Both kinds come up in 20 lines' worth.
	var seen_kinds := {}
	for i in 20:
		q._chat_t = 0.05
		_secs(5.0 / 60.0)
		seen_kinds[dialogue.said.back()] = true
	_ok(seen_kinds.has("podwozka_passenger:normal") and seen_kinds.has("passenger:"), "both kinds of talk come up: %s" % [seen_kinds.keys()])
	# With start_stars 3.0 the count starts at three stars.
	r = _ride_ready(n, {"start_stars": 3.0})
	_secs(3.0 / 60.0)
	_ok(hud.count == "★★★ 3,0", "start_stars 3.0: the count reads %s" % hud.count)


func _e_driving(n: int) -> void:
	# A bump: not at 4 m/s, at 5 m/s half a star, its toast 3 s after the last penalty.
	var r := _ride_ready(n)
	_bump(4.0)
	_secs(3.2)
	_ok(hud.count == "★★★★★ 5,0" and q.drive_toasts == 0, "a bump at 4 m/s cost something: %s" % hud.count)
	var toasts := _toast_n()
	_bump(5.0)
	_frame()
	_ok(hud.count == "★★★★½ 4,5", "a bump at 5 m/s: the count reads %s" % hud.count)
	_secs(2.8)
	_ok(q.drive_toasts == 0 and _toast_n() == toasts, "the drive toast came before 2.9 s of quiet")
	_secs(0.3)
	_ok(q.drive_toasts == 1 and _last_toast() == "−½ ★ · stłuczka" and _last_toast_en() == "−½ star · bump", "the drive toast: %s / %s" % [_last_toast(), _last_toast_en()])
	# Two bumps 2.1 s apart: one toast.
	r = _ride_ready(n)
	toasts = _toast_n()
	_bump(5.0)
	_secs(2.1)
	_bump(5.0)
	_secs(3.1)
	_ok(q.drive_toasts == 1 and _toast_n() == toasts + 1 and _last_toast() == "−1 ★ · stłuczki" and _last_toast_en() == "−1 star · bumps",
			"two bumps, one toast: %s / %s" % [_last_toast(), _last_toast_en()])
	# A second bump 1.9 s after the first costs nothing.
	r = _ride_ready(n)
	_bump(5.0)
	_secs(1.9)
	_bump(5.0)
	_frame()
	_ok(hud.count == "★★★★½ 4,5", "a second bump 1.9 s after the first cost something: %s" % hud.count)
	# Harsh braking: 20 m/s to 0 in 0.5 s.
	r = _ride_ready(n)
	_fwd = 20.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	_secs(3.2)
	_ok(_last_toast() == "−½ ★ · hamowanie" and _last_toast_en() == "−½ star · harsh braking" and hud.count == "★★★★½ 4,5",
			"harsh braking: %s / %s / %s" % [_last_toast(), _last_toast_en(), hud.count])
	# A fast corner: 1 rad in 0.5 s at 12 m/s.
	r = _ride_ready(n)
	_fwd = 12.0
	_secs(0.5)
	for i in 30:
		_yaw += 1.0 / 30.0
		_frame()
	_secs(3.2)
	_ok(_last_toast() == "−½ ★ · zakręt" and _last_toast_en() == "−½ star · fast corner", "a fast corner: %s / %s" % [_last_toast(), _last_toast_en()])
	# A bump and a braking in one toast.
	r = _ride_ready(n)
	_fwd = 20.0
	_secs(0.5)
	_bump(5.0)
	_secs(2.1)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	_secs(3.2)
	_ok(q.drive_toasts == 1 and _last_toast() == "−1 ★ · stłuczka, hamowanie" and _last_toast_en() == "−1 star · bump, harsh braking",
			"a bump and a braking in one toast: %s / %s" % [_last_toast(), _last_toast_en()])
	# Never more than 2 stars lost that way.
	r = _ride_ready(n)
	for i in 6:
		_bump(8.0)
		_secs(2.1)
	_secs(3.2)
	_ok(hud.count == "★★★ 3,0", "driving cost more than 2 stars: %s" % hud.count)
	# Not measured in the air or on the autopilot.
	r = _ride_ready(n)
	_fly = true
	_fwd = 20.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	_fly = false
	_secs(3.2)
	_ok(q.drive_toasts == 0, "the driving was measured in the air")
	q.autopilot = true
	_fwd = 20.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	q.autopilot = false
	_secs(3.2)
	_ok(q.drive_toasts == 0, "the driving was measured on the autopilot")
	# A penalty whose toast waits when the ride ends is never shown.
	r = _ride_ready(n)
	_bump(5.0)
	_secs(0.5)
	_arrive(r)
	var dt0: int = q.drive_toasts
	toasts = _toast_n()
	_secs(4.0)
	_ok(q.drive_toasts == dt0 and _toast_n() == toasts, "a drive toast came after the ride ended")
	# The police.
	r = _ride_ready(n)
	toasts = _toast_n()
	q.on_pulled_over()
	_ok(_toast_n() == toasts + 1 and _last_toast() == "−1 ★ · policja" and _last_toast_en() == "−1 star · police", "the pull-over: %s / %s" % [_last_toast(), _last_toast_en()])
	_frame()
	_ok(hud.count == "★★★★ 4,0", "the pull-over: the count reads %s" % hud.count)
	_rig()
	q.on_pulled_over()
	_ok(_toast_n() == 0, "a pull-over while idle cost something")
	_request(5)
	q.on_pulled_over()
	_ok(_toast_n() == 0, "a pull-over with a request up cost something")
	var rr: Dictionary = q._ride.duplicate(true)
	_take()
	toasts = _toast_n()
	q.on_pulled_over()
	_ok(_toast_n() == toasts, "a pull-over on the way to the passenger cost something")
	_board(rr)
	_arrive(rr)
	toasts = _toast_n()
	q.on_pulled_over()
	_ok(_toast_n() == toasts, "a pull-over on the result card cost something")
	# Late: 15 s past the ETA, again at 30 and 45 s, no more.
	r = _ride_ready(n)
	var eta := _eta(r)
	var late := 0
	for k in [14.7, 29.7, 44.7, 59.7, 74.7]:
		q._rules.clock = eta + float(k)
		_secs(0.6)
		late = 0
		for tt in hud.toasts:
			if tt.ends_with("spóźnienie"):
				late += 1
	_ok(late == 3 and hud.toasts.has("−½ ★ · spóźnienie") and hud.toasts_en.has("−½ star · late"), "lateness cost %d toasts in all, want 3" % late)
	_frame()
	_ok(hud.count == "★★★½ 3,5", "lateness cost at most 1.5: %s" % hud.count)


## Pay and the result card, case by case.
func _pay_case(n: int, final: float, cfg := {}) -> void:
	var streak := int(cfg.get("streak", 0))
	var night := bool(cfg.get("night", false))
	var rain := bool(cfg.get("rain", false))
	var tag := str(cfg.get("tag", "%s" % ("5" if final >= 5.0 else ("4" if final >= 4.0 else "low"))))
	var r := _ride_ready(n, {"kept": {"podwozka_streak": streak}, "start_stars": cfg.get("start", -1.0), "passenger": cfg.get("passenger", ""),
			"setup": func() -> void:
				tod.mode = 2 if night else 0
				weather.state = 1 if rain else 0
				dialogue.no_lines = bool(cfg.get("no_lines", false))})
	if cfg.has("during"):
		(cfg["during"] as Callable).call(r)
	if cfg.has("clock"):
		q._rules.clock = float(cfg["clock"]) * _eta(r)
	var money := wallet.money
	var respect := wallet.respect
	var kinds := wallet.kinds.size()
	var hurry_kind := str(r["type"]) == "hurry"
	_arrive(r)
	var p := _pay(float(r["road"]), final, night, rain, hurry_kind, streak)
	var what := "pay %s" % [cfg.get("name", final)]
	_ok(wallet.money == money + int(p["total"]), "%s: paid %d, want %d" % [what, wallet.money - money, p["total"]])
	_ok(wallet.kinds.size() == kinds + 1 and wallet.kinds.back() == "podwozka" and wallet.respect == respect + int(p["respect"]),
			"%s: paid once as podwozka, respect +%d, want +%d" % [what, wallet.respect - respect, p["respect"]])
	var hist: Array = wallet.keep.get("podwozka_ratings", [])
	_ok(not hist.is_empty() and float(hist.back()) == final, "%s: the rating kept is %s" % [what, hist])
	var want_streak := 0
	if final >= 5.0:
		want_streak = streak + 1
	elif final >= 4.5:
		want_streak = streak
	_ok(int(wallet.keep.get("podwozka_streak", -1)) == want_streak, "%s: the streak is %s, want %d" % [what, wallet.keep.get("podwozka_streak"), want_streak])
	_secs(2.5)
	_ok(hud.card == "", "%s: the card came before 2.6 s" % what)
	_secs(0.2)
	var money_text := "%d\u00a0zł: kurs %d%s + napiwek %d%s" % [p["total"], p["fare"], (" (×%s)" % _num(float(p["mult"]))) if float(p["mult"]) > 1.0 else "",
			p["tip"], (" + seria %d" % p["seria"]) if int(p["seria"]) > 0 else ""]
	var rating := _rating_after(hist)
	var why := str(cfg.get("why", "" if cfg.has("clock") else "przed czasem +½"))
	var no_lines := bool(cfg.get("no_lines", false))
	var body := ("" if no_lines else "%s: Komentarz\n" % r["name"]) + "%s\nOcena %s%s" % [money_text, _num(rating, 2), (" · " + why) if why != "" else ""]
	_ok(hud.card == "KURS · " + _stars_text(final) and hud.card_en == "Ride done", "%s: the card reads %s / %s" % [what, hud.card, hud.card_en])
	_ok(hud.body == body, "%s: the body reads %s, want %s" % [what, hud.body, body])
	_ok(hud.body_en == (("" if no_lines else "A comment ") + "%d\u00a0zł." % p["total"]), "%s: the English body reads %s" % [what, hud.body_en])
	_ok(hud.side and hud.card_is(q) and hud.buttons == 0 and not hud.stacked and hud.accent == (TEAL if final >= 4.0 else RED),
			"%s: beside the road, its own, no buttons, not stacked, %s" % [what, "teal" if final >= 4.0 else "red"])
	if not no_lines:
		_ok(dialogue.line_asks.back() == "podwozka_rating:" + tag and dialogue.line_prefers.back(), "%s: the comment is asked for as podwozka_rating:%s (%s)" % [what, tag, dialogue.line_asks.back()])
	hud.press(0)


func _e_pay(n: int) -> void:
	_pay_case(n, 5.0, {"name": "5 stars by day"})
	_pay_case(n, 4.5, {"name": "4.5 stars", "start": 4.0, "tag": "4"})
	_pay_case(n, 4.0, {"name": "4.0 stars", "start": 3.5, "tag": "4"})
	_pay_case(n, 3.5, {"name": "3.5 stars", "start": 3.0, "tag": "low"})
	_pay_case(n, 4.5, {"name": "4.5 without the early half star", "start": 4.5, "clock": 0.9, "tag": "4"})
	_pay_case(n, 5.0, {"name": "5 stars at night", "night": true})
	_pay_case(n, 5.0, {"name": "5 stars in rain", "rain": true})
	_pay_case(n, 5.0, {"name": "5 stars at night in rain", "night": true, "rain": true})
	_pay_case(n, 5.0, {"name": "5 stars after 3 five-star rides", "streak": 3})
	_pay_case(n, 5.0, {"name": "5 stars after 6 five-star rides", "streak": 6})
	_pay_case(n, 4.5, {"name": "4.5 keeps the streak", "start": 4.0, "streak": 3, "tag": "4"})
	_pay_case(n, 3.5, {"name": "3.5 ends the streak", "start": 3.0, "streak": 3, "tag": "low"})
	_pay_case(n, 5.0, {"name": "5 stars, an empty line bag", "no_lines": true})
	_pay_case(n, 4.5, {"name": "after a pull-over", "tag": "police", "why": "policja −1, przed czasem +½",
			"during": func(_r: Dictionary) -> void: q.on_pulled_over()})
	_pay_case(n, 4.0, {"name": "after a bump", "tag": "4", "start": 4.0, "why": "jazda −½, przed czasem +½",
			"during": func(_r: Dictionary) -> void:
				_bump(6.0)
				_frame()})
	# Late: the half star for being early is lost, lateness costs.
	_pay_case(n, 4.0, {"name": "late by 20 s", "start": 4.5, "tag": "4", "why": "spóźnienie −½",
			"during": func(r: Dictionary) -> void:
				q._rules.clock = _eta(r) + 14.9
				_secs(0.3)})


func _e_ends(n: int) -> void:
	# The passenger has had enough.
	var r := _ride_ready(n, {"kept": {"podwozka_streak": 3}})
	var nm := str(r["name"])
	var eta := _eta(r)
	var money := wallet.money
	var saves0 := wallet.saves
	q._rules.clock = 3.0 * eta - 1.5 * DT
	_frame()
	_ok(_in_stage(Rides.Stage.RIDE), "the passenger got out before 3 x the ETA")
	_frame()
	_ok(_in_stage(Rides.Stage.RESULT), "the passenger did not get out past 3 x the ETA")
	_cancel_card("PASAŻER ANULOWAŁ", "The passenger cancelled", "„Słowo”\n%s wysiada. Bez opłat; seria pięciu gwiazdek przepadła." % nm,
			"A word\n%s gets out. No charge; the 5-star streak is gone." % nm, "the passenger got out")
	_ok(dialogue.said.has("podwozka_rating:cancel") and dialogue.hows[dialogue.said.rfind("podwozka_rating:cancel")] == [4.5, RED, 2.4, true],
			"the passenger's last word: %s" % [dialogue.said])
	_ok(wallet.money == money and int(wallet.keep["podwozka_streak"]) == 0 and wallet.saves == saves0 + 1 and hud.status_title == "",
			"the passenger got out: no pay, the streak ended, saved, the status line down")
	r = _ride_ready(n, {"setup": func() -> void: dialogue.say_words = []})
	nm = str(r["name"])
	q._rules.clock = 3.0 * _eta(r) - 1.5 * DT
	_secs(2.0 / 60.0)
	_cancel_card("PASAŻER ANULOWAŁ", "The passenger cancelled", "%s wysiada. Bez opłat; seria pięciu gwiazdek przepadła." % nm,
			"%s gets out. No charge; the 5-star streak is gone." % nm, "the passenger got out with no word")
	# The ✕ on the ride.
	r = _ride_ready(n)
	nm = str(r["name"])
	_abort()
	_cancel_card("KURS ANULOWANY", "Ride cancelled", "%s wysiada tutaj. Bez opłat; seria przepadła." % nm,
			"%s gets out here. No charge; the streak is gone." % nm, "the ✕ on the ride")
	_ok(_in_stage(Rides.Stage.RESULT) and director.current() == q, "after the ✕ the director still sees the ride")
	_secs(12.1)
	_ok(director.current() == null, "the director saw the ride after its card was gone")


# --- F. the app's ideas -----------------------------------------------------------------------------------

func _count_said(tag: String) -> int:
	var c := 0
	for s in dialogue.said:
		if s == tag:
			c += 1
	return c


func _route_has(p: Vector2) -> bool:
	for v in hud.route:
		if v.is_equal_approx(p):
			return true
	return false


func _park_points() -> Array:
	return [Vector2(450.0, 450.0), Vector2(1250.0, 850.0), Vector2(2050.0, 1650.0), Vector2(350.0, 1250.0)]


## The Frogs' doors are near a junction of the grid: the waypoint of the Frogs turn is that junction.
func _near_frog(w: Vector2) -> bool:
	for d: Vector2 in FROG_DOORS:
		if d.distance_to(w) < 30.0:
			return true
	return false


func _f_quirks() -> void:
	for quirk: String in ["river", "zone", "oldtown", "rechotka"]:
		for who: String in ["believer", "normal"]:
			for driven: bool in [true, false]:
				_quirk_ride(quirk, who, driven)
	# The recalculation.
	_rig()
	q.force_quirk = "reroute"
	_request(5)
	var r: Dictionary = q._ride.duplicate(true)
	var door := _v2(r["ring"])
	var straight := _flat(r["board"], r["ring"])
	_take()
	_board(r)
	_ok(str(q._ride["quirk"]) == "reroute", "the recalculation is planned")
	_secs(0.3)
	_ok(_count_said("podwozka_gps:reroute") == 0, "the app recalculated at the kerb")
	_at(HOME, 9.0)
	q._rules.clock = 0.4 * _eta(r) - 0.2
	_secs(0.1)
	_ok(_count_said("podwozka_gps:reroute") == 0, "the app recalculated before 40 percent of the ETA")
	var routes0 := hud.routes_set
	_secs(0.4)
	_ok(_count_said("podwozka_gps:reroute") == 1 and dialogue.speakers.back() == "Nawigacja" and dialogue.hows.back() == [4.5, TEAL, 0.0, true],
			"no recalculation 40 %% of the ETA in (%s)" % [dialogue.said.back()])
	_ok(hud.routes_set > routes0 and hud.route[hud.route.size() - 1].is_equal_approx(door), "the minimap's route changed and still ends at the door")
	_ok(hud.route[0].distance_to(HOME) < 3.0 and _route_has(Vector2(800.0, 1200.0)), "the new line first leads back to the junction behind the car")
	_secs(1.0)
	_ok(_count_said("podwozka_gps:reroute") == 1, "the app recalculated twice")
	_arrive(r)
	_rig()
	q.force_quirk = "reroute"
	_request(5)
	_take()
	_board(r)
	_at(Vector2(200.0, 200.0), 9.0)
	q._rules.clock = 0.4 * _eta(r) + 0.5
	_secs(0.2)
	_ok(_count_said("podwozka_gps:reroute") == 1, "no recalculation off the road")
	_rig()
	q.force_quirk = "reroute"
	_request(5)
	_take()
	_board(r)
	_at(door + (_v2(r["board"]) - door).normalized() * straight * 0.58, 9.0)
	_secs(0.2)
	_ok(_count_said("podwozka_gps:reroute") == 1, "no recalculation 0.58 of the way from the door")
	# A forced quirk with no place for it: none. A quirk by the dice with no place: the recalculation.
	_rig()
	q.force_quirk = "zone"
	q._parks = [] as Array[Dictionary]
	_request(5)
	_take()
	_board(q._ride)
	_ok(str(q._ride["quirk"]) == "", "a park's paths with no park: \"%s\"" % q._ride["quirk"])
	_rig()
	q.force_quirk = ""
	var zn := _find(1, func(x: Dictionary) -> bool: return str(x["quirk"]) == "zone")
	_ok(zn > 0, "a ride with a park quirk by the dice")
	q._parks = [] as Array[Dictionary]
	_take()
	_board(q._ride)
	_ok(str(q._ride["quirk"]) == "reroute", "a park quirk by the dice with no park becomes a recalculation: \"%s\"" % q._ride["quirk"])
	# The Frogs turn with none placed: the first turn 250 m or more in.
	_rig()
	q.force_quirk = "rechotka"
	_request(5)
	_take()
	_board(q._ride)
	var w: Vector2 = q._ride["q"]["w"]
	var run := 0.0
	var found := false
	for i in range(1, hud.route.size()):
		run += hud.route[i].distance_to(hud.route[i - 1])
		if hud.route[i].is_equal_approx(w):
			found = true
			break
	_ok(found and run >= 250.0, "the Frogs turn with none placed is the first turn 250 m or more in (%.0f m)" % run)
	_f_detour()


## One forced quirk ride, driven by the waypoint or passed by.
func _quirk_ride(quirk: String, who: String, driven: bool) -> void:
	var what := "quirk %s, a %s passenger, %s" % [quirk, who, "driven" if driven else "ignored"]
	_rig()
	q.frogs = frogs
	q.force_quirk = quirk
	q.force_passenger = who
	var r: Dictionary = {}
	if quirk == "rechotka":
		# The first ride whose road turns at a junction with a Frogs on it.
		for n in range(1, 160):
			if not _request(n):
				continue
			r = q._ride.duplicate(true)
			_take()
			_board(r)
			if _in_stage(Rides.Stage.RIDE) and q._ride.has("q") and (q._ride["q"] as Dictionary).has("w") and _near_frog(q._ride["q"]["w"]):
				break
			_abort()
			hud.press(0)
	else:
		_find(3 if quirk == "river" else 1, func(_x: Dictionary) -> bool: return true)
		r = q._ride.duplicate(true)
		_take()
		_board(r)
	var got := str(q._ride["quirk"])
	var tag := "zone" if quirk == "oldtown" else quirk
	_ok(got == tag, "%s: the quirk planned is \"%s\"" % [what, got])
	if got != tag:
		return
	var w: Vector2 = q._ride["q"]["w"]
	var door := _v2(r["ring"])
	_ok(_route_has(w), "%s: the app's route goes by the waypoint" % what)
	_at(Vector2(-80.0, 2480.0), 12.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Cel to turkusowe światło. Kropki to pomysł aplikacji." and hud.hint_en == "The goal is the teal beacon. The dots are the app's idea.",
			"%s: the hint reads %s" % [what, hud.status])
	if quirk == "river":
		var spot := false
		for sp: Dictionary in q.river_spots:
			if sp["w"] == w:
				spot = true
		_ok(spot and _map.shore_distance(w.x, w.y) <= 0.0, "%s: the river's waypoint is one of the spots, on dry land" % what)
	elif tag == "zone":
		_ok(_park_points().has(w), "%s: the park's waypoint is a park of the rig" % what)
	else:
		_ok(_near_frog(w), "%s: the Frogs turn has a Frogs within 30 m" % what)
	_at(w + Vector2(0.0, 201.0), 9.0)
	_secs(0.3)
	_ok(_count_said("podwozka_gps:" + tag) == 0, "%s: Nawigacja spoke 201 m before the waypoint" % what)
	_at(w + Vector2(0.0, 199.0), 9.0)
	_secs(0.3)
	_ok(_count_said("podwozka_gps:" + tag) == 1 and dialogue.said.has("podwozka_gps:" + tag), "%s: Nawigacja did not speak 199 m before it" % what)
	var gi := dialogue.said.rfind("podwozka_gps:" + tag)
	_ok(dialogue.speakers[gi] == "Nawigacja" and dialogue.hows[gi] == [4.5, TEAL, 0.0, true], "%s: Nawigacja's bubble: %s" % [what, dialogue.hows[gi]])
	_secs(1.0)
	_ok(_count_said("podwozka_gps:" + tag) == 1, "%s: Nawigacja spoke twice" % what)
	var toasts := _toast_n()
	var star := who == "believer" and quirk != "rechotka" and quirk != "oldtown" or (who == "believer" and quirk == "oldtown")
	if quirk == "rechotka":
		star = false
	if driven:
		_at(w + Vector2(0.0, 16.0), 9.0)
		_secs(0.2)
		_ok(_toast_n() == toasts, "%s: the waypoint counted from 16 m" % what)
		_at(w + Vector2(0.0, 14.0), 9.0)
		_secs(0.2)
		if star:
			_ok(_toast_n() == toasts + 1 and _last_toast() == "+½ ★ · za aplikacją" and _last_toast_en() == "+½ star · followed the app",
					"%s: the half star for following the app: %s" % [what, _last_toast()])
			_ok(_count_said("podwozka_passenger:followed") == 1 and dialogue.hows.back() == [3.5, TEAL, 2.4, true], "%s: the passenger's thanks" % what)
		else:
			_ok(_toast_n() == toasts and _count_said("podwozka_passenger:followed") == 0, "%s: a passenger who does not care followed the app" % what)
		_secs(1.0)
		_ok(_toast_n() == toasts + (1 if star else 0), "%s: the half star came twice" % what)
	else:
		var far := w.distance_to(door)
		_ok(far > 100.0, "%s: the waypoint is %.0f m from the door" % [what, far])
		_at(door + (w - door).normalized() * far * 0.52, 9.0)
		_secs(0.2)
		_ok(_count_said("podwozka_passenger:believer") == 0, "%s: the waypoint was given up at 0.52 of its way to the door" % what)
		_at(door + (w - door).normalized() * far * 0.4, 9.0)
		_secs(0.2)
		if quirk == "rechotka":
			_ok(_count_said("podwozka_passenger:believer") == 0 and _toast_n() == toasts, "%s: the Frogs turn passed by cost something" % what)
		elif who == "believer":
			var bi := dialogue.said.rfind("podwozka_passenger:believer")
			_ok(bi >= 0 and dialogue.hows[bi] == [4.0, TEAL, 2.4, true] and _count_said("podwozka_passenger:believer") == 1, "%s: the believer did not grumble" % what)
			_ok(_toast_n() == toasts, "%s: the grumble cost a star" % what)
			_secs(1.0)
			_ok(_count_said("podwozka_passenger:believer") == 1, "%s: the believer grumbled twice" % what)
			_at(w + Vector2(0.0, 10.0), 9.0)
			_secs(0.2)
			_ok(_last_toast() == "+½ ★ · za aplikacją", "%s: a waypoint first ignored could not be driven after all" % what)
		else:
			_ok(_count_said("podwozka_passenger:believer") == 0 and _toast_n() == toasts, "%s: a passenger who does not care grumbled" % what)
	_arrive(r)


## A passenger who asks for a stop at a Frogs.
func _f_detour() -> void:
	_rig()
	q.force_passenger = "detour"
	_request(7)
	var r: Dictionary = q._ride.duplicate(true)
	_ok(bool(r["detour"]) and str(r["type"]) == "normal", "the forced detour passenger rides as a normal one")
	_take()
	_board(r)
	_by(r["ring"], 400.0, 12.0)
	_secs(10.0)
	_ok(_count_said("podwozka_passenger:detour") == 0, "a stop asked for with no Frogs in the city")
	_arrive(r)
	_rig()
	q.frogs = frogs
	q.force_passenger = "detour"
	_request(7)
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	var frog: Vector2 = FROG_DOORS[1]
	var toasts := _toast_n()
	_at(frog + Vector2(10.0, 0.0))
	_secs(2.5)
	_ok(_toast_n() == toasts, "the stop counted before it was asked for")
	var used := _frames - _boarded_at
	for i in roundi(7.9 * 60.0) - used:
		_frame()
	_ok(_count_said("podwozka_passenger:detour") == 0, "the passenger asked for a Frogs at 7.9 s")
	bubbles.talking = true
	_secs(0.5)
	_ok(_count_said("podwozka_passenger:detour") == 0, "the passenger asked over another bubble")
	bubbles.talking = false
	_secs(3.0 / 60.0)
	_ok(_count_said("podwozka_passenger:detour") == 1 and dialogue.hows.back() == [4.5, TEAL, 2.4, true], "the passenger did not ask for a Frogs 8 s in")
	_at(frog + Vector2(10.0, 0.0), 2.1)
	_secs(2.3)
	_at(frog + Vector2(10.0, 0.0), 2.5)
	_secs(2.3)
	_at(frog + Vector2(15.0, 0.0))
	_secs(2.3)
	_at(frog + Vector2(40.0, 0.0))
	_secs(2.3)
	_at(frog + Vector2(10.0, 0.0))
	_fly = true
	_secs(2.3)
	_fly = false
	_ok(_toast_n() == toasts, "the stop counted at 2.1 m/s, 2.5 m/s, from 15 m, from 40 m or from the air")
	_secs(1.9)
	_ok(_toast_n() == toasts, "the stop counted before its 2 s")
	_secs(0.2)
	_ok(_toast_n() == toasts + 1 and _last_toast() == "+½ ★ · postój przy Frogsie" and _last_toast_en() == "+½ star · a Frogs stop", "the stop by the Frogs: %s" % _last_toast())
	_secs(3.0)
	_ok(_toast_n() == toasts + 1, "the stop counted twice")
	_arrive(r)


# --- G. the passengers ------------------------------------------------------------------------------------

func _g_passengers() -> void:
	for who: String in ["believer", "hurry", "timber", "club", "date", "normal"]:
		_rig()
		q.force_passenger = who
		if who == "club":
			clubs = [["klub_testowy", Vector2(1320.0, 1200.0)], ["klub_daleki", Vector2(200.0, 2200.0)]]
		_find(7, func(x: Dictionary) -> bool: return str(x["type"]) == who)
		var r: Dictionary = q._ride.duplicate(true)
		var what := "a forced %s" % who
		_ok(str(r["type"]) == who, "%s: the ride's type is %s" % [what, r["type"]])
		_ok(is_equal_approx(float(r["eta"]), _eta(r)), "%s: the ETA is %.1f s, the ride says %.1f" % [what, _eta(r), r["eta"]])
		if who == "timber" or who == "club" or who == "date":
			_ok(dialogue.line_asks.has("podwozka_request:" + who), "%s: the request line is asked for by kind" % what)
			var pi := dialogue.line_asks.rfind("podwozka_request:" + who)
			_ok(dialogue.line_prefers[pi], "%s: the request line is the preferred one" % what)
		if who == "club":
			var d := _addr_door(str(r["pin_name"]))
			_ok(str(r["club"]) != "" and (d.distance_to(Vector2(1320.0, 1200.0)) < 60.0 or d.distance_to(Vector2(200.0, 2200.0)) < 60.0),
					"%s: the pin is an address by a club's door" % what)
		if who == "date":
			_ok(str(r["dest"]) == "Pod Gigantami" and _v2(r["ring"]).distance_to(Vector2(-36.0, 778.0)) < 90.0, "%s: Pod Gigantami, by its gate" % what)
		_take()
		_board(r)
		_by(r["ring"], 400.0, 12.0)
		var seen := 0
		for i in 20:
			q._chat_t = 0.05
			_secs(5.0 / 60.0)
			var s: String = dialogue.said.back()
			if s == "podwozka_passenger:" + who:
				seen += 1
				_ok(dialogue.hows.back()[3] == (who != "normal"), "%s: the talk is preferred only for a kind of its own" % what)
		_ok(seen > 0, "%s: the talk of its own kind never came" % what)
		_arrive(r)
	# A date with nowhere to go to is a normal passenger.
	_rig()
	q.force_passenger = "date"
	for a: Dictionary in jobs._addresses.duplicate():
		if str(a["name"]) == "Aleje 49":
			jobs._addresses.erase(a)
	_request(7)
	_ok(str(q._ride["type"]) == "normal" and str(q._ride["dest"]) != "Pod Gigantami", "a date with no address at Pod Gigantami is a normal passenger")
	# The TIMBER evening.
	for h: Array in [[17.9, false], [18.0, true], [23.9, true], [0.5, true], [0.9, true], [1.0, false], [12.0, false]]:
		tod.hour = h[0]
		_ok(q.timber_hour() == bool(h[1]), "the TIMBER hour at %s" % [h[0]])
	_rig()
	tod.hour = 20.0
	var tn := _find(1, func(x: Dictionary) -> bool: return str(x["type"]) == "timber")
	_ok(tn > 0, "a TIMBER passenger on an evening by the dice")
	# A club's door at dawn, a late Hyrax competitor, nobody in Praga, the named places.
	_rig()
	clubs = [["klub_testowy", Vector2(1320.0, 1200.0)]]
	_find(1, func(x: Dictionary) -> bool: return str(x["type"]) == "club")
	_ok(str(q._ride["club"]) != "" and dialogue.line_asks.has("podwozka_request:club"), "a club passenger at dawn")
	_rig()
	hurry = Vector2(2000.0, 400.0)
	_find(1, func(x: Dictionary) -> bool: return str(x["type"]) == "hurry")
	var hy: Dictionary = q._ride
	_ok(bool(hy.get("hyrax", false)) and str(hy["dest"]).begins_with("Hyrax · "), "the one in a hurry goes to the Hyrax: %s" % hy["dest"])
	_ok(_addr_door(str(hy["dest"]).trim_prefix("Hyrax · ")).distance_to(hurry) < 350.0, "the Hyrax address is within 350 m of the forecourt")
	_rig()
	hurry = Vector2(9000.0, 9000.0)
	_find(1, func(x: Dictionary) -> bool: return str(x["type"]) == "hurry")
	_ok(not q._ride.has("hyrax"), "a Hyrax with no door near it")
	_rig()
	var praga := 0
	var asked := 0
	var named := {}
	for k in range(101, 181):
		if not _request(k):
			continue
		asked += 1
		var rr: Dictionary = q._ride
		if _addr_flag(str(rr["pin_name"])) == "praga":
			praga += 1
		var dest := str(rr["dest"])
		if _addr_flag(dest) == "praga":
			praga += 1
		if _addr_flag(dest) == "?" and dest != "Pod Gigantami" and (rr["story"] as Dictionary).is_empty():
			named[dest] = true
		hud.press(1)
	_ok(asked > 50 and praga == 0, "nobody is picked up in Praga or taken there (%d of %d)" % [praga, asked])
	_ok(named.has("Plac Testowy") and not named.has("Most Testowy") and not named.has("Za Mapą"), "the named places: %s" % [named.keys()])


# --- H. the story passengers ----------------------------------------------------------------------------------

func _story_of(id: String) -> Dictionary:
	for st: Dictionary in _stories:
		if str(st["id"]) == id:
			return st
	return {}


## The clock of the ride in seconds since boarding (frames counted by the play).
func _ride_s() -> float:
	return float(_frames - _boarded_at) * DT


## Frames until `cond` holds, at most `s` seconds since boarding: the ride's clock then, or -1.
func _until_ride(cond: Callable, s: float) -> float:
	while _ride_s() < s:
		if cond.call():
			return _ride_s()
		_frame()
	return _ride_s() if cond.call() else -1.0


func _story_ride(id: String, cfg := {}) -> Dictionary:
	_rig(true, cfg.get("kept", {}))
	q.force_story = id
	if cfg.has("start_stars"):
		q.start_stars = float(cfg["start_stars"])
	_request(9)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	_at(_v2(r["board"]), 9.0)
	return r


func _h_stories() -> void:
	var ids: Array = []
	for st: Dictionary in _stories:
		ids.append(str(st["id"]))
	var plays := [[ids[0], 0, "press"], [ids[0], 1, "press"], [ids[1], 0, "key"], [ids[3], -1, "nobody"], [ids[4], 0, "door"],
			[ids[5], 0, "abort"], [ids[2], 1, "press"], [ids[8], 0, "press"], [ids[12], 0, "press"]]
	for pl: Array in plays:
		_story_play(str(pl[0]), int(pl[1]), str(pl[2]))
	_story_waits()
	_story_foreign()
	_story_dice(ids)


func _story_play(id: String, idx: int, mode: String) -> void:
	var what := "story %s, %d (%s)" % [id, idx, mode]
	var st := _story_of(id)
	_rig()
	q.force_story = id
	_request(9)
	var r: Dictionary = q._ride.duplicate(true)
	var nm := str(r["name"])
	_ok(not (r["story"] as Dictionary).is_empty() and str(r["story"]["id"]) == id, "%s: the forced story is on the ride" % what)
	var note: Array = [str(st["who"][0]) + " · " + str(st["teaser"][0]), str(st["who"][1]) + " · " + str(st["teaser"][1])]
	_ok(nm == str(st["name"]) and r["note"] == note and str(r["dest"]) == str(st["to"]["name"][0]), "%s: the passenger, the note and the place are the story's" % what)
	_ok(hud.body.ends_with("\n" + str(note[0])) and hud.body_en.ends_with("\n" + str(note[1])), "%s: the request card carries the note" % what)
	_take()
	_board(r)
	_at(_v2(r["board"]), 9.0)
	_ok((wallet.keep.get("podwozka_stories", []) as Array).has(id), "%s: the story is kept as heard at boarding" % what)
	var eta := _eta(r)
	var lines: Array = st["lines"]
	var said0 := dialogue.said.size()
	_secs(2.9)
	_ok(q.story_lines == 0 and bubbles.said.is_empty(), "%s: the first line came before 3 s" % what)
	bubbles.talking = true
	_secs(0.4)
	bubbles.talking = false
	bubbles.ok = false
	_secs(3.0 / 60.0)
	_ok(q.story_lines == 0, "%s: a line over another bubble, or one the budget refused, was counted" % what)
	bubbles.ok = true
	_secs(2.0 / 60.0)
	_ok(q.story_lines == 1 and bubbles.said == [lines[0][0]], "%s: the first line 3 s in: %s" % [what, bubbles.said])
	var t1 := _ride_s()
	var t2 := _until_ride(func() -> bool: return q.story_lines >= 2, 20.0)
	_ok(t2 >= 12.9 and t2 <= 13.2 and t2 - t1 >= 7.5, "%s: the second line at %.2f s (want 13 s, 7.5 s after the first)" % [what, t2])
	var t3 := _until_ride(func() -> bool: return q.story_lines >= 3, 30.0)
	_ok(t3 >= 22.9 and t3 <= 23.2 and t3 - t2 >= 7.5, "%s: the third line at %.2f s (want 23 s)" % [what, t3])
	_ok(bubbles.said == [lines[0][0], lines[1][0], lines[2][0]], "%s: the three lines in order: %s" % [what, bubbles.said])
	# The question: not from the air, not over somebody else's card.
	_secs(8.5)
	_fly = true
	_secs(1.0)
	_fly = false
	_ok(not q._asking, "%s: the question came in the air" % what)
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_secs(0.3)
	_ok(not q._asking, "%s: the question came over another card" % what)
	hud.hide_card()
	var tq := _until_ride(func() -> bool: return q._asking, 40.0)
	_ok(tq > 0.0, "%s: no question once the card was free" % what)
	var ask: Array = st["ask"]
	var answers: Array = st["answers"]
	var buttons := PackedStringArray(["%s|%s" % [answers[0]["say"][0], answers[0]["say"][1]], "%s|%s" % [answers[1]["say"][0], answers[1]["say"][1]]])
	_ok(hud.card == "%s PYTA" % nm.to_upper() and hud.card_en == "%s asks" % nm and hud.body == str(ask[0]) and hud.body_en == str(ask[1]),
			"%s: the question card reads %s / %s" % [what, hud.card, hud.body])
	_ok(hud.side and hud.card_is(q) and hud.stacked and hud.button_words == buttons and hud.accent == TEAL, "%s: beside the road, its own, stacked, the two answers, teal" % what)
	_ok(hud.status_title == "" and dialogue.host_hold, "%s: the status line is down and the host held under the question" % what)
	_ok(_count_said("passenger:") == 0 and _count_said("podwozka_passenger:normal") == 0, "%s: small talk on a story ride" % what)
	_ok(q.story_lines == 3, "%s: three lines were counted" % what)
	var answered0: int = q.story_answers
	if mode == "key":
		_ok(not q.primary() and not q.secondary() and q._asking, "%s: a key did something under the question" % what)
	if idx == 0 and mode == "press" and id == str(_stories[0]["id"]):
		# The ride goes on under the question: the car's metres change, a late half star still comes.
		_secs(1.0)
		var door := _v2(r["ring"])
		_at(door + Vector2(120.0, 0.0), 9.0)
		_secs(0.2)
		q._rules.clock = eta + 14.7
		_secs(0.6)
		_ok(hud.toasts.has("−½ ★ · spóźnienie") and q._asking, "%s: lateness cost nothing under the question" % what)
		_ok(hud.status_title == "", "%s: the status line came back under the question" % what)
	_secs(1.0)
	var money := wallet.money
	match mode:
		"press", "key":
			var toasts := _toast_n()
			hud.press(idx)
			var star := bool(answers[idx].get("star", false))
			_ok(not q._asking and hud.card == "" and bubbles.said.back() == str(answers[idx]["reply"][0]), "%s: the answer: the card down, the reply %s" % [what, bubbles.said.back()])
			_ok(q.story_answers == answered0 + 1 and int(q._ride["answer"]) == idx, "%s: the answer is kept" % what)
			if star:
				_ok(_toast_n() == toasts + 1 and _last_toast() == "+½ ★ · rozmowa" and _last_toast_en() == "+½ star · good talk", "%s: the half star for a good talk: %s" % [what, _last_toast()])
			else:
				_ok(_toast_n() == toasts, "%s: a half star for a talk that did not earn it" % what)
			_secs(1.0)
			_ok(hud.status_title != "", "%s: the status line did not come back after the answer" % what)
			_ok(hud.distance == "%d m" % roundi(_flat(_car, r["ring"])), "%s: the status line's metres follow the car: %s" % [what, hud.distance])
			_arrive(r)
			_secs(2.7)
			var tip := int(answers[idx]["tip"])
			var p := _pay(float(r["road"]), 5.0, false, false, false, 0, tip)
			var money_text := "%d\u00a0zł: kurs %d + napiwek %d" % [p["total"], p["fare"], p["tip"]]
			if int(p["story"]) > 0:
				money_text += " + rozmowa %d" % p["story"]
			elif int(p["story"]) < 0:
				money_text += " − inwestycja %d" % -int(p["story"])
			_ok(wallet.money == money + int(p["total"]), "%s: paid %d, want %d (the story's tip %d)" % [what, wallet.money - money, p["total"], tip])
			_ok(hud.body.begins_with("%s: %s\n%s\n" % [nm, answers[idx]["outro"][0], money_text]), "%s: the card carries the outro and the story's tip: %s" % [what, hud.body])
			_ok(hud.body_en.begins_with("%s " % answers[idx]["outro"][1]), "%s: the English card carries the outro" % what)
			if id == str(_stories[12]["id"]):
				_ok(int(p["story"]) < 0 and money_text.contains("− inwestycja"), "%s: the investment takes the tip" % what)
		"nobody":
			_secs(8.8)
			_ok(q._asking and hud.card_is(q), "%s: the question went before its 10 s" % what)
			_secs(0.4)
			var silent: Array = st.get("silent", ["Dobra, patrz na drogę. Ja też popatrzę.", "Fine, eyes on the road. I'll watch it too."])
			_ok(not q._asking and hud.card == "" and bubbles.said.back() == str(silent[0]) and int(q._ride["answer"]) == -1 and q.story_answers == answered0,
					"%s: no answer in 10 s: the passenger lets it go (%s)" % [what, bubbles.said.back()])
			_arrive(r)
			_secs(2.7)
			_ok(hud.body.begins_with("%s: Komentarz\n" % nm), "%s: with no answer the card carries the bag's comment" % what)
		"door":
			_arrive(r)
			_ok(hud.card == "" and not q._asking and int(q._ride["answer"]) == -1, "%s: the question stayed up at the door, or an answer was made" % what)
			_secs(2.5)
			_ok(hud.card == "", "%s: the result card came before 2.6 s" % what)
			_secs(0.2)
			_ok(hud.card.begins_with("KURS · "), "%s: no result card 2.7 s after the door" % what)
		"abort":
			_abort()
			_ok(_in_stage(Rides.Stage.RESULT) and hud.card == "KURS ANULOWANY" and not q._asking, "%s: the ✕ under the question: %s" % [what, hud.card])
	# A badly driven ride keeps the passenger's last word to itself.
	if mode == "press" and idx == 0 and id == str(_stories[0]["id"]):
		var r2 := _story_ride(id, {"start_stars": 2.0})
		var tq2 := _until_ride(func() -> bool: return q._asking, 40.0)
		_ok(tq2 > 0.0, "%s: no question on the badly driven ride" % what)
		hud.press(0)
		_arrive(r2)
		_secs(2.7)
		_ok(hud.body.begins_with("%s: Komentarz\n" % str(r2["name"])), "%s: a low ride carries the bag's line, not the outro: %s" % [what, hud.body])


## The question's 10 s; a stranger's card over it; the order of the stories.
func _story_waits() -> void:
	var id := str(_stories[3]["id"])
	var r := _story_ride(id)
	var tq := _until_ride(func() -> bool: return q._asking, 40.0)
	var up := _frames
	_secs(9.9)
	_ok(q._asking and hud.card_is(q), "the question went before its 10 s (%.1f)" % tq)
	_secs(0.2)
	_ok(not q._asking, "the question outlived its 10 s")
	_ok(_frames - up >= 600, "the question was let go after %d frames" % (_frames - up))
	_arrive(r)


func _story_foreign() -> void:
	var id := str(_stories[0]["id"])
	var r := _story_ride(id)
	_until_ride(func() -> bool: return q._asking, 40.0)
	_secs(1.0)
	var title := hud.card
	var body := hud.body
	var chat: float = q._chat_t
	hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_secs(10.5)
	_ok(q._asking and hud.card == "INNA", "the question gave way under another card and was let go")
	_ok(q._chat_t == chat, "the passenger's small talk went on under the waiting question")
	hud.hide_card()
	_frame()
	_ok(q._asking and hud.card == title and hud.body == body and hud.stacked and hud.card_is(q), "the question was not put back in the frame after the card was free: %s" % hud.card)
	_frame()
	_ok(not q._asking and int(q._ride["answer"]) == -1 and hud.card == "", "the question was not over in the frame after it was put back")
	_arrive(r)


func _story_dice(ids: Array) -> void:
	_rig()
	q.force_story = "none"
	var any := 0
	for k in range(200, 220):
		_request(k)
		if not (q._ride["story"] as Dictionary).is_empty():
			any += 1
		hud.press(1)
	_ok(any == 0, "stories off: %d of 20 rides had one" % any)
	q.force_story = "nie ma takiej"
	for k in range(200, 205):
		_request(k)
		if not (q._ride["story"] as Dictionary).is_empty():
			any += 1
		hud.press(1)
	_ok(any == 0, "a story that is not in the list was on a ride")
	_rig()
	q.force_story = ""
	var with := 0
	var kind_story := 0
	for k in range(100, 140):
		if not _request(k):
			continue
		if not (q._ride["story"] as Dictionary).is_empty():
			with += 1
		hud.press(1)
	_ok(with > 20 and with < 40, "by the dice %d of 40 rides have a story" % with)
	_ok(with == 29, "by the dice 29 of 40 rides have a story (pinned): %d" % with)
	# Each story is heard once before any comes back (by day, the night-only one waits).
	_rig()
	q.force_story = ""
	var day := 0
	for st: Dictionary in _stories:
		if str(st.get("when", "")) != "night":
			day += 1
	var heard: Array = []
	var n := 100
	while heard.size() < day and n < 600:
		n += 1
		if not _request(n):
			continue
		var rr: Dictionary = q._ride.duplicate(true)
		if (rr["story"] as Dictionary).is_empty():
			hud.press(1)
			continue
		heard.append(str(rr["story"]["id"]))
		_take()
		_board(rr)
		_abort()
		hud.press(0)
	var seen := {}
	for i: String in heard:
		seen[i] = true
	_ok(heard.size() == day and seen.size() == day, "the %d day stories were heard once each before any came back (%d rides, %d different)" % [day, heard.size(), seen.size()])
	# None for a club or a date passenger.
	for who: String in ["club", "date"]:
		_rig()
		clubs = [["klub_testowy", Vector2(1320.0, 1200.0)]]
		q.force_story = ""
		q.force_passenger = who
		var got := 0
		for k in range(100, 112):
			if _request(k) and str(q._ride["type"]) == who:
				got += 1
				_ok((q._ride["story"] as Dictionary).is_empty(), "a %s passenger has a story" % who)
			hud.press(1)
		_ok(got > 0, "no %s ride in 12 tries" % who)

#__stubs__
# --- J. the least the game can hand in --------------------------------------------------------------------------

func _j_least() -> void:
	_rig(false)
	_ok(not q._river_ready and q.river_spots.is_empty() and q.moments == null and q.traffic == null and q.rivals == null and q.tod == null and q.weather == null,
			"the bare rig has nothing to the job's name but the least")
	var frames := _until(func() -> bool: return q._river_ready, 3.4)
	_ok(frames > 0 and frames <= 200, "the river's edge was scanned over %d frames" % frames)
	var scanned: Array = q.river_spots.duplicate()
	_ok(scanned.size() > 0, "the scan found no spot at the river")
	var wet := 0
	var far := 0
	for sp: Dictionary in scanned:
		var w: Vector2 = sp["w"]
		if _map.shore_distance(w.x, w.y) > 0.0:
			wet += 1
		if _graph.snap(w, 70.0, Vector2.ZERO, true, true).is_empty():
			far += 1
	_ok(wet == 0 and far == 0, "the spots found: %d in the water, %d more than 70 m from a road, of %d" % [wet, far, scanned.size()])
	# A forced river ride before the scan is over finishes it first, and finds the same spots.
	_rig(false)
	_secs(3.0 / 60.0)
	_ok(not q._river_ready, "the scan was over in three frames")
	q.force_quirk = "river"
	q.force_passenger = "believer"
	var started := _request(3)
	_ok(started and q._river_ready and q.river_spots.size() == scanned.size(), "start_ride finished the scan first (%d spots, want %d)" % [q.river_spots.size(), scanned.size()])
	var same: bool = q.river_spots.size() == scanned.size()
	for i in mini(q.river_spots.size(), scanned.size()):
		if q.river_spots[i]["w"] != scanned[i]["w"]:
			same = false
	_ok(same, "the scan by frames and the scan at once found different spots")
	hud.press(1)
	# No clock, no weather, no named places, no GPS moments, no Hyrax, no club.
	_rig(false)
	q.force_story = "none"
	var named := 0
	var asked := 0
	for k in range(101, 161):
		if not _request(k):
			continue
		asked += 1
		var rr: Dictionary = q._ride
		if _addr_flag(str(rr["dest"])) == "?" and str(rr["dest"]) != "Pod Gigantami":
			named += 1
		_ok(not bool(rr["night"]) and not bool(rr["rain"]) and str(rr["type"]) != "club" and not rr.has("hyrax"), "a ride with a night, a rain, a club or a Hyrax in the bare rig")
		hud.press(1)
	_ok(asked > 40 and named == 0, "named places in the bare rig: %d of %d rides" % [named, asked])
	_ok(not q.timber_hour() and not q._night() and not q._rain(), "the bare rig has a TIMBER hour, a night or a rain")
	# A ride by hand from the request to the card pays as by day.
	_rig(false)
	q.force_passenger = "normal"
	var n := _find(1, _plain)
	var r: Dictionary = q._ride.duplicate(true)
	var money := wallet.money
	_take()
	_board(r)
	_arrive(r)
	var p := _pay(float(r["road"]), 5.0, false, false, false, 0)
	_ok(n > 0 and wallet.money == money + int(p["total"]), "the bare rig paid %d, want %d" % [wallet.money - money, p["total"]])
	_secs(2.7)
	_ok(hud.card == "KURS · " + _stars_text(5.0), "the bare rig's card reads %s" % hud.card)


# --- K. a save that has driven before ---------------------------------------------------------------------------

func _k_kept() -> void:
	var day_ids: Array = []
	for st: Dictionary in _stories:
		if str(st.get("when", "")) != "night":
			day_ids.append(str(st["id"]))
	var kept_ids: Array = day_ids.slice(0, 3)
	var kept := {"podwozka_ratings": [5.0, 5.0, 3.0], "podwozka_streak": 2, "podwozka_stories": kept_ids.duplicate()}
	var r := _ride_ready(5, {"kept": kept})
	var money := wallet.money
	_arrive(r)
	var p := _pay(float(r["road"]), 5.0, false, false, str(r["type"]) == "hurry", 2)
	_ok(int(p["seria"]) == 20 and wallet.money == money + int(p["total"]), "a 5-star ride after a streak of 2 paid %d, want %d (the streak's 20 included)" % [wallet.money - money, p["total"]])
	_ok(int(wallet.keep["podwozka_streak"]) == 3, "the streak after it is %s, want 3" % wallet.keep["podwozka_streak"])
	_ok(wallet.keep["podwozka_ratings"] == [5.0, 5.0, 3.0, 5.0], "the ratings kept are %s" % [wallet.keep["podwozka_ratings"]])
	_secs(2.7)
	var want := _rating_after([5.0, 5.0, 3.0, 5.0])
	_ok(absf(want - (4.87 * 16.0 + 18.0) / 20.0) < 0.0001, "the average of the last 20 reads %.4f" % want)
	_ok(hud.body.contains("Ocena " + _num(want, 2)), "the card's Ocena is %s: %s" % [_num(want, 2), hud.body])
	# The three stories heard wait until the others have come.
	_rig(true, kept)
	q.force_story = ""
	var order: Array = []
	var n := 100
	while order.size() < day_ids.size() and n < 700:
		n += 1
		if not _request(n):
			continue
		var rr: Dictionary = q._ride.duplicate(true)
		if (rr["story"] as Dictionary).is_empty():
			hud.press(1)
			continue
		order.append(str(rr["story"]["id"]))
		_take()
		_board(rr)
		_abort()
		hud.press(0)
	var early := order.slice(0, day_ids.size() - 3)
	var bad := 0
	for id: String in early:
		if kept_ids.has(id):
			bad += 1
	var seen := {}
	for id: String in early:
		seen[id] = true
	_ok(order.size() >= early.size() and bad == 0 and seen.size() == early.size(), "the stories heard came first again: %d of the first %d (%d different)" % [bad, early.size(), seen.size()])


# --- L. with the director ---------------------------------------------------------------------------------------

func _l_director() -> void:
	_rig()
	_ok(q.play_limit == 0.0 and director.may_start(other) and director.current() == null, "no play limit, nothing on")
	var n := _find(1, _plain)
	var r: Dictionary = q._ride.duplicate(true)
	q.abort()
	_ok(_on_offer() and hud.card_is(q), "abort() did something to the request")
	_take()
	_ok(_in_stage(Rides.Stage.PICKUP) and director.current() == q and not director.may_start(other), "on the way: the director has the ride and lets nobody else start")
	_at(Vector2(-80.0, 2480.0), 12.0)
	_secs(15.0)
	_ok(_in_stage(Rides.Stage.PICKUP) and director.current() == q, "a ride was dropped by the kit's limit 15 s on the way (stage %d)" % _stage())
	_board(r)
	_ok(_in_stage(Rides.Stage.RIDE) and not director.may_start(other) and director.busy_tag() == "podwózka", "on the ride: nobody else may start")
	_at(Vector2(-80.0, 2480.0), 12.0)
	_secs(15.0)
	_ok(_in_stage(Rides.Stage.RIDE) and director.current() == q, "the ride was dropped by the kit's limit 15 s into the ride (%d)" % _stage())
	_abort()
	_ok(director.current() == q and not director.may_start(other), "the director saw the ride go before its card was gone")
	_secs(12.1)
	_ok(director.current() == null and director.may_start(other) and n > 0, "the director still saw the ride after its card was gone")
	# The ✕ does nothing on the result card, nor on the cancelled card.
	for cancelled: bool in [false, true]:
		var rc := _ride_ready(5)
		if cancelled:
			_frame()
			_abort()
		else:
			_arrive(rc)
			_secs(2.7)
		var card := hud.card
		var money := wallet.money
		var rated: int = (wallet.keep.get("podwozka_ratings", []) as Array).size()
		var shown := hud.shown
		_abort()
		_frame()
		_ok(_in_stage(Rides.Stage.RESULT) and hud.card == card and hud.card_is(q) and wallet.money == money and hud.shown == shown
				and (wallet.keep.get("podwozka_ratings", []) as Array).size() == rated and director.current() == q,
				"the ✕ on the %s card did something (%s)" % ["cancelled" if cancelled else "result", hud.card])
	# The other activity first: no button, no request, until it is done.
	_rig()
	_gate("the other activity", true)
	_ok(director.current() == other and not director.may_start(q), "the other activity is on")
	q._offer_in = 0.05
	_secs(1.0)
	_ok(_is_idle() and q._offer_in >= 0.0, "a request came over the other activity")
	_gate("the other activity", false)
	_ok(director.current() == null, "the other activity left the director with it")


# --- M. what deliberate breaks showed is easy to leave out ----------------------------------------------------

func _m_breaks() -> void:
	# The police on the way to the passenger cost nothing and say nothing.
	_rig()
	_request(5)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	var toasts := _toast_n()
	var said := dialogue.said.size()
	q.on_pulled_over()
	_secs(0.5)
	_ok(_toast_n() == toasts and _in_stage(Rides.Stage.PICKUP), "the police on the way cost a toast or the ride (%d -> %d)" % [toasts, _toast_n()])
	_board(r)
	_arrive(r)
	var hist: Array = wallet.keep.get("podwozka_ratings", [])
	_ok(not hist.is_empty() and float(hist.back()) == 5.0 and dialogue.said.size() >= said, "the ride after the police on the way was rated %s" % [hist])
	# A spawn with no lane: no ride, nothing changed.
	_rig()
	q._spawn_lane = []
	var car0 := car.global_position
	var shown := hud.shown
	var state: int = q._rng.state
	_ok(not q.start_ride(5), "start_ride answered true with no lane at the spawn")
	_ok(_is_idle() and hud.shown == shown and car.global_position == car0 and q._rng.state == state and not hud.card_showing(), "start_ride with no spawn lane changed something")
	# The bare rig's river scan, finished by a forced river ride in its first frames.
	_rig(false)
	_secs(2.0 / 60.0)
	var was_ready: bool = q._river_ready
	q.force_quirk = "river"
	var ok := _request(3)
	_ok(not was_ready and ok and q._river_ready and not q.river_spots.is_empty(), "a forced river ride in the first frames did not finish the scan (%s, %d spots)" % [q._river_ready, q.river_spots.size()])
	# The spawn's lane is found from 40 m, not from 70 m.
	_rig(true, {}, {"spawn": Vector2(1000.0, 1240.0)})
	_ok(not q._spawn_lane.is_empty(), "no lane 40 m from the spawn")
	_rig(true, {}, {"spawn": Vector2(1000.0, 1270.0)})
	_ok(q._spawn_lane.is_empty(), "a lane 70 m from the spawn")
	# The first request's clock.
	var lo := 1000.0
	var hi := 0.0
	var seen := {}
	for i in 10:
		_rig()
		lo = minf(lo, setup_offer_in)
		hi = maxf(hi, setup_offer_in)
		seen[snappedf(setup_offer_in, 0.001)] = true
	_ok(lo >= 75.0 and hi <= 120.0 and seen.size() >= 5, "the first request's clock over ten rigs: %.1f to %.1f s, %d different" % [lo, hi, seen.size()])
	# The GPS moments get the dialogue, the log and the first moment's clock.
	_rig(true, {}, {"gps_first": 41.0, "log_on": true})
	_ok(q.moments.dialogue == dialogue and q.moments.log_on and q.moments.first_in == 41.0, "the GPS moments lack the dialogue, the log or the first clock")


# --- I. the autopilot -----------------------------------------------------------------------------------------

## What `drive_player()` answered in the last frame on the autopilot, and what the frame watched.
var _last_dp := false
var _watch := Vector2.INF
var _dmin := INF
var _step_max := 0.0
var _step_seen := 0
var _prev := Vector2.ZERO
var _added_seen := 0
var _born := 0
var _squeeze_after := -1
var _squeeze_value := 0.0
## What the last autopilot ride asked of the traffic (the junctions its ghosts were raced to, in order) and
## the app's line as it stood two frames after boarding.
var _auto_raced: Array = []
var _auto_route := PackedVector2Array()


## A frame on the engine's own clock, as main.gd runs the autopilot: the traffic, the job's drive of the
## car, the car's velocity, the two flags, the job's two frames.
func _afr() -> void:
	if q.traffic != null:
		traffic.step(DT)
	_last_dp = q.drive_player()
	car.velocity = car.vel
	q.flying = false
	q.away = false
	q._physics_process(DT)
	q._process(DT)
	_frames += 1
	var here := _v2(car.global_position)
	if _watch != Vector2.INF:
		_dmin = minf(_dmin, here.distance_to(_watch))
	if _stage() == Rides.Stage.RIDE:
		_step_max = maxf(_step_max, here.distance_to(_prev))
		_step_seen += 1
	_prev = here
	if traffic.added > _added_seen:
		_added_seen = traffic.added
		_born = _frames
	if _squeeze_after < 0 and not traffic.ghosts.is_empty() and (traffic.ghosts[0] as Ghost).squeeze > 0.0:
		_squeeze_after = _frames - _born
		_squeeze_value = (traffic.ghosts[0] as Ghost).squeeze
	await process_frame


## Engine frames until `cond` holds (at most `frames`): how many it took, or -1.
func _afr_until(cond: Callable, frames: int) -> int:
	for i in frames:
		if cond.call():
			return i
		await _afr()
	return 0 if cond.call() else -1


func _afr_n(frames: int) -> void:
	for i in frames:
		await _afr()


func _card_is_result() -> bool:
	return hud.card.begins_with("KURS")


## One ride on the autopilot from the request to idle, over the engine's frames. `cfg`: "bare", "who",
## "quirk", "ignore", "story", "answer", "jam", "fits".
func _auto_ride(what: String, cfg: Dictionary) -> Dictionary:
	var bare := bool(cfg.get("bare", false))
	_rig(not bare)
	q.autopilot = true
	q.ignore_app = bool(cfg.get("ignore", false))
	q.force_story = str(cfg.get("story", "none"))
	q.force_answer = int(cfg.get("answer", -1))
	q.force_passenger = str(cfg.get("who", "normal"))
	q.force_quirk = str(cfg.get("quirk", ""))
	traffic.jam = bool(cfg.get("jam", false))
	var fits: Callable = cfg.get("fits", func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0 and (str(cfg.get("quirk", "")) != "" or cfg.has("story") or _plain(x)))
	var n := _find(int(cfg.get("from", 1)), fits)
	if n < 0:
		return {}
	var r: Dictionary = q._ride.duplicate(true)
	_watch = Vector2.INF
	_dmin = INF
	_step_max = 0.0
	_step_seen = 0
	_added_seen = 0
	_squeeze_after = -1
	var start_f := _frames
	var money := wallet.money
	var said0 := dialogue.said.size()
	# The request: taken 1.5 s after it went up.
	_ok(not q.drive_player() and _on_offer(), "%s: no drive while the request is up" % what)
	var bad := 0
	for i in 84:
		await _afr()
		if not _on_offer() or _last_dp:
			bad += 1
	_ok(bad == 0, "%s: the request was taken before 1.4 s, or the car was driven under it (%d frames)" % [what, bad])
	await _afr_n(12)
	_ok(_in_stage(Rides.Stage.PICKUP) and not _on_offer(), "%s: the request was not taken 1.6 s after it went up" % what)
	# On the way to the passenger.
	_ok(_last_dp, "%s: no drive on the way" % what)
	if not bare and (q._legs[0] as Dictionary).has("node"):
		_ok(traffic.ghosts.size() == 1 and traffic.raced.size() == 1, "%s: a ghost on the road (%d, raced %d)" % [what, traffic.ghosts.size(), traffic.raced.size()])
		if traffic.ghosts.size() == 1 and traffic.raced.size() == 1:
			var g: Ghost = traffic.ghosts[0]
			var nodes := []
			for leg: Dictionary in q._legs:
				if leg.has("node"):
					nodes.append(int(leg["node"]))
			_ok(traffic.raced[0]["speed"] == 1.3 and traffic.raced[0]["accel"] == 1.5 and nodes.has(int(traffic.raced[0]["finish"])),
					"%s: the ghost is raced at 1.3 times the speed and 1.5 the acceleration to a junction of the route: %s" % [what, traffic.raced[0]])
			_ok(car.collision_mask == 0, "%s: the car passes through" % what)
			_ok(_v2(car.global_position).distance_to(Vector2(g.pos.x, g.pos.z)) < 0.01, "%s: the car is where the ghost is" % what)
	elif bare:
		_ok(traffic.added == 0 and car.collision_mask == 0, "%s: no traffic: no ghost, the car still passes through" % what)
	var got := await _afr_until(func() -> bool: return _in_stage(Rides.Stage.RIDE), 7200)
	_ok(got >= 0, "%s: the passenger was not picked up in 120 s" % what)
	if got < 0:
		return r
	_ok(_flat(car.global_position, r["board"]) < 12.0, "%s: the passenger boarded %.1f m from the kerb" % [what, _flat(car.global_position, r["board"])])
	_boarded_at = _frames
	if q._ride.has("q"):
		_watch = (q._ride["q"] as Dictionary).get("w", Vector2.INF)
	await _afr_n(2)
	_auto_route = hud.route.duplicate()
	_ok(_last_dp or bare, "%s: no drive on the ride" % what)
	if cfg.has("story"):
		var asked := await _afr_until(func() -> bool: return q._asking, 9000)
		_ok(asked >= 0, "%s: no question on the ride" % what)
		if asked >= 0:
			var bad_q := 0
			for i in 144:
				await _afr()
				if not q._asking or not hud.card_is(q):
					bad_q += 1
			_ok(bad_q == 0, "%s: the question was answered before 2.4 s (%d frames)" % [what, bad_q])
			await _afr_n(12)
			var want := maxi(int(cfg.get("answer", -1)), 0)
			_ok(not q._asking and int(q._ride["answer"]) == want, "%s: the question was not answered 2.6 s in (asking %s, answer %s, want %d)" % [what, q._asking, q._ride["answer"], want])
	var done := await _afr_until(func() -> bool: return _in_stage(Rides.Stage.RESULT), 20000)
	_ok(done >= 0, "%s: the ride did not reach the door (%.0f s in)" % [what, (_frames - start_f) * DT])
	if done < 0:
		return r
	var came := await _afr_until(_card_is_result, 300)
	_ok(came >= 0, "%s: no result card" % what)
	if came >= 0:
		_ok(not _last_dp and q._auto_button() == -1, "%s: driven on the result card, or the autopilot would press it" % what)
		var title := hud.card
		var bad_c := 0
		for i in 714:
			await _afr()
			if hud.card != title or _last_dp:
				bad_c += 1
		_ok(bad_c == 0, "%s: the result card went before 11.9 s (%d frames wrong)" % [what, bad_c])
		await _afr_n(18)
		_ok(hud.card == "" and not _card_is_result(), "%s: the result card outlived its 12 s: %s" % [what, hud.card])
	var idle := await _afr_until(func() -> bool: return _is_idle() and _stage() == Rides.Stage.NONE, 600)
	_ok(idle >= 0 and not _last_dp, "%s: not idle after the card" % what)
	var secs := float(_frames - start_f) * DT
	_ok(secs <= 400.0, "%s: from the request to idle took %.0f s" % [what, secs])
	_auto_raced = []
	for e: Dictionary in traffic.raced:
		_auto_raced.append(e["finish"])
	var hist: Array = wallet.keep.get("podwozka_ratings", [])
	var stars := float(hist.back()) if not hist.is_empty() else 0.0
	_ok(wallet.money > money and stars >= 4.0, "%s: paid %d zł, %.1f stars" % [what, wallet.money - money, stars])
	_ok(traffic.ghosts.is_empty() and traffic.added == traffic.removed, "%s: the ghost was left on the road (%d, added %d, removed %d)" % [what, traffic.ghosts.size(), traffic.added, traffic.removed])
	_ok(not q._asking and hud.card == "" and dialogue.said.size() >= said0, "%s: a card left up" % what)
	return r


## Whether a polyline is the flat list of x, z pairs `xs` (within a centimetre).
func _line_is(line: PackedVector2Array, xs: Array) -> bool:
	if line.size() * 2 != xs.size():
		return false
	for i in line.size():
		if absf(line[i].x - float(xs[2 * i])) > 0.01 or absf(line[i].y - float(xs[2 * i + 1])) > 0.01:
			return false
	return true




func _i_autopilot() -> void:
	_rig()
	q.autopilot = true
	await _afr()
	_ok(absf(q.get_process_delta_time() - DT) < 0.0002, "the engine's frame is %.5f s, not 1/60 (run with --fixed-fps 60)" % q.get_process_delta_time())
	_ok(not _last_dp and _is_idle(), "no drive while idle")
	# With the autopilot off, nothing is driven on the way.
	_rig()
	q.autopilot = false
	_request(5)
	_take()
	_ok(_in_stage(Rides.Stage.PICKUP) and not q.drive_player(), "no drive on the way with the autopilot off")
	q.autopilot = true
	_ok(q.drive_player(), "a drive on the way with it on")
	var short := func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0
	var plain := await _auto_ride("autopilot, a plain ride", {})
	_ok(_auto_raced == [16, 24] and _line_is(_auto_route, [800, 550, 800, 600, 800, 800, 1000, 800, 1200, 800, 1200, 1000, 1200, 1200, 1200, 1200]),
			"the plain ride: the ghosts raced to junctions %s, the app's line %s" % [_auto_raced, _auto_route])
	var money_plain := wallet.money
	var rr1 := await _auto_ride("autopilot, a ride in a jam", {"jam": true})
	_ok(_auto_raced == [16, 24], "the ride in a jam: the ghosts raced to junctions %s" % [_auto_raced])
	_ok(_squeeze_after >= 238 and _squeeze_after <= 246 and _squeeze_value == 3.0, "the ghost stood %d frames in the jam before it was told to squeeze by (%.1f)" % [_squeeze_after, _squeeze_value])
	var rr2 := await _auto_ride("autopilot, a story's question", {"story": str(_stories[0]["id"]), "answer": 1})
	_ok(_auto_raced == [0] and _line_is(_auto_route, [0, 792, 0, 600, 0, 400, 0, 200, 0, 0, 120, -11]), "the story ride: the pickup is a straight leg, one ghost to junction %s, the line %s" % [_auto_raced, _auto_route])
	var app := await _auto_ride("autopilot, the river the app's way", {"quirk": "river", "who": "believer", "fits": short})
	_ok(_auto_raced == [27, 27, 19] and _line_is(_auto_route, [2400, 950, 2400, 1000, 2435, 1000, 2400, 1000, 2400, 1000, 2400, 1200, 2400, 1000, 2400, 800, 2200, 800, 2000, 800, 2011, 1050]),
			"the river the app's way: the ghosts raced to junctions %s, the line %s" % [_auto_raced, _auto_route])
	_ok(_dmin <= 15.0, "the app's way passes %.1f m from the river waypoint" % _dmin)
	_ok(hud.toasts.count("+½ ★ · za aplikacją") == 1 and _count_said("podwozka_gps:river") == 1, "the believer's half star came %d times" % hud.toasts.count("+½ ★ · za aplikacją"))
	_ok(_count_said("podwozka_passenger:believer") == 0, "the believer grumbled though the app's way was driven")
	var rr3 := await _auto_ride("autopilot, the river the shortest way", {"quirk": "river", "who": "believer", "ignore": true, "fits": short})
	_ok(_auto_raced == [27, 19] and _line_is(_auto_route, [2400, 950, 2400, 1000, 2435, 1000, 2400, 1000, 2400, 1000, 2400, 1200, 2400, 1000, 2400, 800, 2200, 800, 2000, 800, 2011, 1050]),
			"the river the shortest way: the ghosts raced to junctions %s (the app's line is still shown: %s)" % [_auto_raced, _auto_route])
	_ok(_dmin > 15.0, "the shortest way passes %.1f m from the river waypoint" % _dmin)
	_ok(hud.toasts.count("+½ ★ · za aplikacją") == 0 and _count_said("podwozka_passenger:believer") == 1, "the believer grumbled %d times on the shortest way" % _count_said("podwozka_passenger:believer"))
	var rr4 := await _auto_ride("autopilot, a recalculation", {"quirk": "reroute", "who": "normal"})
	_ok(_auto_raced == [16, 24, 16, 24], "the recalculation the app's way: the ghosts raced to junctions %s (back to 16, on to 24)" % [_auto_raced])
	_ok(_count_said("podwozka_gps:reroute") == 1, "the app recalculated %d times" % _count_said("podwozka_gps:reroute"))
	var rr6 := await _auto_ride("autopilot, a recalculation on the shortest way", {"quirk": "reroute", "who": "normal", "ignore": true})
	_ok(_auto_raced == [16, 24], "the recalculation on the shortest way: the ghosts raced to junctions %s" % [_auto_raced])
	var rr7 := await _auto_ride("autopilot, the river from a street before it", {"quirk": "river", "who": "believer", "fits": func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0 and int(x["p_e"]) != 76})
	_ok(_auto_raced == [47, 34, 41, 40] and _line_is(_auto_route, [2120, 2400, 2000, 2400, 2000, 2200, 2000, 2000, 2000, 1800, 2000, 1600, 2200, 1600, 2400, 1600, 2400, 1800, 2435, 1800, 2400, 1800, 2400, 1800, 2400, 2000, 2200, 2000, 2000, 2000, 1880, 2011]),
			"the river from a street before it: the ghosts raced to junctions %s (the waypoint street's start 34 first), the line %s" % [_auto_raced, _auto_route])
	var rr8 := await _auto_ride("autopilot, a park", {"quirk": "zone", "who": "believer", "fits": short})
	_ok(_auto_raced == [25, 33, 34, 32] and _line_is(_auto_route, [1600, 950, 1600, 1000, 1600, 1200, 1800, 1200, 2000, 1200, 2000, 1400, 2000, 1600, 2031.073, 1600, 2050, 1650,
			2000, 1664.51, 2000, 1664.51, 2000, 1600, 1800, 1600, 1600, 1600, 1611, 1850]), "the park the app's way: the ghosts raced to junctions %s, the line %s" % [_auto_raced, _auto_route])
	var rr9 := await _auto_ride("autopilot, a park behind the car", {"quirk": "zone", "who": "believer", "from": 6, "fits": short})
	_ok(_auto_raced == [34, 33, 34, 40] and _line_is(_auto_route, [2280, 1600, 2400, 1600, 2200, 1600, 2000, 1600, 2084.201, 1600, 2050, 1650, 2000, 1684.277, 2000, 1684.277, 2000, 1600, 2000, 1800, 2000, 2000, 2120, 1989]),
			"the park behind the car: the ghosts raced to junctions %s, the line %s" % [_auto_raced, _auto_route])
	var rr5 := await _auto_ride("autopilot, the bare rig", {"bare": true})
	_ok(_step_seen > 100 and _step_max <= 12.0 * DT + 0.001 and _step_max > 12.0 * DT - 0.01, "the bare rig's legs are straight lines at 12 m/s (a frame's step %.3f m, %d frames)" % [_step_max, _step_seen])
	_ok(plain.size() > 0 and money_plain > 100, "the plain autopilot ride ran")


# --- N. making rides: the census of seeded requests ------------------------------------------------------------

## Which side of the street `e` the point `p` is on (+1 left of its way, -1 right of it).
func _side_of(e: int, p: Vector2) -> int:
	var s: float = _graph.project(e, p)
	var c: Vector2 = _graph.point_at(e, s)
	var dir: Vector2 = _graph.direction(e, s)
	return 1 if dir.cross(p - c) > 0.0 else -1


## What a run of seeded requests (ride numbers `from` to `to`) holds: counts of kinds, quirks, the kinds of
## place and the extremes of the roads, the rides skipped when no ride fits.
func _census(from: int, to: int) -> Dictionary:
	var out := {"rides": 0, "offset": 0, "across": 0, "along_back": 0, "kinds": {}, "quirks": {}, "detour": 0, "story": 0, "named": 0, "hyrax": 0,
			"club": 0, "named_min": INF, "named_max": 0.0, "shirts": {}, "bad_board": 0, "bad_spot": 0, "bad_kerb": 0, "night_story": 0, "club_detour": 0, "hyrax_other": 0, "off_min": INF, "off_max": 0.0}
	for n in range(from, to):
		if not _request(n):
			continue
		var r: Dictionary = q._ride
		out["rides"] += 1
		var kinds: Dictionary = out["kinds"]
		kinds[str(r["type"])] = int(kinds.get(str(r["type"]), 0)) + 1
		var quirks: Dictionary = out["quirks"]
		quirks[str(r["quirk"])] = int(quirks.get(str(r["quirk"]), 0)) + 1
		(out["shirts"] as Dictionary)[(r["shirt"] as Color).to_html(false)] = true
		if bool(r["offset"]):
			out["offset"] += 1
			out["off_min"] = minf(out["off_min"], float(r["off_m"]))
			out["off_max"] = maxf(out["off_max"], float(r["off_m"]))
			var c: Vector2 = _graph.point_at(r["p_e"], r["p_s"])
			if _side_of(r["p_e"], Vector2(r["pin"].x, r["pin"].z)) != _side_of(r["p_e"], Vector2(r["spot"].x, r["spot"].z)):
				out["across"] += 1
			if _graph.project(r["p_e"], Vector2(r["spot"].x, r["spot"].z)) < _graph.project(r["p_e"], Vector2(r["pin"].x, r["pin"].z)):
				out["along_back"] += 1
		if bool(r["detour"]):
			out["detour"] += 1
		if not (r["story"] as Dictionary).is_empty():
			out["story"] += 1
		if _addr_flag(str(r["dest"])) == "?" and str(r["dest"]) != "Pod Gigantami" and (r["story"] as Dictionary).is_empty() and not str(r["dest"]).begins_with("Hyrax"):
			out["named"] += 1
			out["named_min"] = minf(out["named_min"], float(r["road"]))
			out["named_max"] = maxf(out["named_max"], float(r["road"]))
		if r.has("hyrax"):
			out["hyrax"] += 1
			if str(r["type"]) != "hurry":
				out["hyrax_other"] += 1
		if str(r["club"]) != "":
			out["club"] += 1
			if bool(r["detour"]):
				out["club_detour"] += 1
		if (r["story"] as Dictionary).has("when") and str(r["story"]["when"]) == "night":
			out["night_story"] += 1
		var cc: Vector2 = _graph.point_at(r["p_e"], r["p_s"])
		if absf(_flat(r["board"], Vector3(cc.x, 0.0, cc.y)) - 2.0) > 0.01:
			out["bad_kerb"] += 1
		if absf(r["board"].y - (1.0 + 0.0011 * r["board"].x - 0.0007 * r["board"].z)) > 0.01:
			out["bad_board"] += 1
		if absf(r["spot"].y - (5.0 + 0.0007 * r["spot"].x - 0.0003 * r["spot"].z)) > 0.01:
			out["bad_spot"] += 1
		hud.press(1)
	return out


## The seeded census in each light the game has (the dice are fixed, so the counts are literals).
func _n_requests() -> void:
	_rig()
	q.force_story = "none"
	var c := _census(100, 400)
	_ok(c["rides"] == 300 and c["offset"] == 141 and c["across"] == 59 and c["along_back"] == 70,
			"300 seeded requests: %d rides, %d with the passenger away from the pin, %d across the street, %d behind the pin" % [c["rides"], c["offset"], c["across"], c["along_back"]])
	_ok(c["kinds"] == {"believer": 96, "normal": 160, "hurry": 24, "date": 20}, "the kinds of passenger: %s" % [c["kinds"]])
	_ok(c["quirks"] == {"river": 42, "": 190, "reroute": 35, "zone": 33}, "the quirks by the dice (no Frogs): %s" % [c["quirks"]])
	_ok((c["shirts"] as Dictionary).size() == 6 and (c["shirts"] as Dictionary).has("3b8f5a") and (c["shirts"] as Dictionary).has("5d6f8a"),
			"the shirts: %s" % [(c["shirts"] as Dictionary).keys()])
	_ok(c["named"] == 82 and c["named_min"] == 650.0 and c["named_max"] == 2250.0, "the named places: %d, %.0f to %.0f m by road" % [c["named"], c["named_min"], c["named_max"]])
	_ok(c["bad_kerb"] == 0 and c["bad_board"] == 0 and c["bad_spot"] == 0 and c["detour"] == 0,
			"the boarding point is 2 m from the lane's middle on the road's surface (%d wrong, %d off the road's height), the passenger on the terrain (%d wrong), %d Frogs stops with no Frogs" % [
			c["bad_kerb"], c["bad_board"], c["bad_spot"], c["detour"]])
	_ok(c["off_min"] > 30.0 and c["off_min"] < 31.0 and c["off_max"] > 61.0 and c["off_max"] < 62.0,
			"the passenger waits %.1f to %.1f m from the pin (30 to 60 m along the street, a little across)" % [c["off_min"], c["off_max"]])
	# The Frogs placed: the Frogs turn is offered, and a stop at a Frogs is asked for.
	_rig()
	q.force_story = "none"
	q.frogs = frogs
	c = _census(100, 400)
	_ok(c["quirks"] == {"rechotka": 27, "": 190, "river": 29, "reroute": 32, "zone": 22} and c["detour"] == 42,
			"with the Frogs placed: the quirks %s, %d Frogs stops asked for" % [c["quirks"], c["detour"]])
	# The stories, by day and by night.
	_rig()
	q.force_story = ""
	c = _census(100, 400)
	_ok(c["story"] == 222 and c["night_story"] == 0 and c["named"] == 21, "by day: %d story rides, %d of the night-only stories, %d named places" % [c["story"], c["night_story"], c["named"]])
	_rig()
	q.force_story = ""
	tod.mode = 2
	c = _census(100, 400)
	_ok(c["story"] == 222 and c["night_story"] == 6, "by night: %d story rides, %d of the night-only stories" % [c["story"], c["night_story"]])
	# The TIMBER evening: a fifth of the ordinary passengers.
	_rig()
	q.force_story = "none"
	tod.hour = 20.0
	c = _census(100, 400)
	_ok(c["kinds"] == {"believer": 96, "normal": 120, "timber": 44, "hurry": 24, "date": 16}, "at 20:00 the kinds of passenger: %s" % [c["kinds"]])
	# The first small talk 8 to 14 s in, then 25 to 40 s between.
	_rig()
	q.force_story = "none"
	_request(5)
	var rc: Dictionary = q._ride.duplicate(true)
	_take()
	_board(rc)
	_at(Vector2(-80.0, 2480.0), 12.0)
	var gap_min := 1000.0
	var gap_max := 0.0
	var chats := dialogue.said.size()
	for i in 40:
		q._chat_t = 0.01
		_secs(5.0 / 60.0)
		gap_min = minf(gap_min, q._chat_t)
		gap_max = maxf(gap_max, q._chat_t)
	_ok(gap_min >= 25.0 and gap_max <= 40.0 and dialogue.said.size() - chats >= 39, "the gap before the next small talk: %.1f to %.1f s, %d lines in 40 tries" % [gap_min, gap_max, dialogue.said.size() - chats])
	_abort()
	# Dawn: most requests at the clubs' doors; a club passenger asks for no Frogs.
	_rig()
	q.force_story = "none"
	q.frogs = frogs
	clubs = [["klub_testowy", Vector2(1320.0, 1200.0)]]
	c = _census(100, 400)
	_ok(c["club"] == 218 and c["club_detour"] == 0 and c["detour"] == 11 and c["kinds"]["club"] == 218, "at dawn: %d club passengers, %d of them asking for a Frogs, %d Frogs stops in all" % [c["club"], c["club_detour"], c["detour"]])
	# The Hyrax Saturday: only the one in a hurry goes to the forecourt, and has no story.
	_rig()
	q.force_story = ""
	hurry = Vector2(2000.0, 400.0)
	c = _census(100, 400)
	_ok(c["hyrax"] == 24 and c["hyrax_other"] == 0 and c["story"] == 204, "with a Hyrax forecourt: %d go to it, %d of them not in a hurry, %d story rides" % [c["hyrax"], c["hyrax_other"], c["story"]])
	_n_golden()


## Single rides read whole: the distance to the pin, where the passenger waits, what was asked of the
## jobs, the places by name.
func _n_golden() -> void:
	_rig()
	q.force_story = "none"
	jobs.kerbs.clear()
	_request(101)
	var r: Dictionary = q._ride
	_ok(r["pin_name"] == "Pionowa 5 m. 12" and r["offset"] and absf(r["away"] - 17.4) < 0.05 and absf(r["off_m"] - 45.52) < 0.05,
			"ride 101: the pin %s is %.1f m by road away, the passenger %.2f m off it" % [r["pin_name"], r["away"], r["off_m"]])
	_ok(jobs.kerbs.size() == 1 and jobs.kerbs[0].distance_to(Vector2(2006.0, 2204.893)) < 0.01 and absf(r["spot_yaw"] - 1.571) < 0.001 and absf(r["spot"].x - 2004.9) < 0.01,
			"ride 101: the kerb asked for at %s, the passenger faces %.3f at %s" % [jobs.kerbs, r["spot_yaw"], r["spot"]])
	_ok(hud.body.contains("17 m"), "ride 101: the card says how far away: %s" % hud.body)
	hud.press(1)
	jobs.kerbs.clear()
	_request(108)
	r = q._ride
	_ok(not r["offset"] and absf(r["off_m"] - 6.1) < 0.05 and jobs.kerbs.size() == 1 and jobs.kerbs[0].distance_to(Vector2(791.0, 150.0)) < 0.01 and absf(r["away"] - 60.67) < 0.05,
			"ride 108: the passenger at the pin: %.2f m off, the kerb asked for at %s, %.2f m away" % [r["off_m"], jobs.kerbs, r["away"]])
	hud.press(1)
	_request(104)
	r = q._ride
	_ok(r["dest"] == "Skwer Bliski" and r["ring"] == Vector3(1200.0, 3.8, 1200.0) and r["finish"] == _node(3, 3),
			"ride 104: a named place, the ring on the map's ground: %s" % [r["ring"]])
	hud.press(1)
	_request(111)
	r = q._ride
	_ok(r["type"] == "hurry" and absf(r["eta"] - 97.1) < 0.05, "ride 111: one in a hurry has 0.8 of the time: %.1f s" % r["eta"])
	hud.press(1)
	# A request by the clock: how far away is how far the road is, not the air.
	_rig()
	q.force_story = "none"
	_offer_now()
	_ok(q._ride["pin_name"] == "Pozioma 3 m. 8" and q._ride["away"] == 480.0 and hud.body.contains("480 m"), "the clock's request: %s is %.0f m away: %s" % [q._ride["pin_name"], q._ride["away"], hud.body])
	hud.press(1)
	# A date: to the gate of Pod Gigantami by the first door asked for, and the last junction of that road.
	_rig()
	q.force_story = "none"
	q.force_passenger = "date"
	_request(8)
	r = q._ride
	_ok(r["type"] == "date" and r["dest"] == "Pod Gigantami" and absf(r["road"] - 4595.89) < 0.05 and r["finish"] == 14 and r["ring"] == Vector3(-11.0, 0.4349, 790.0),
			"ride 8, a date: to %s, %.2f m, ending at junction %d, ring %s" % [r["dest"], r["road"], r["finish"], r["ring"]])
	hud.press(1)
	# One in a hurry with a story: the story's place, a hurry's 0.8 of the time.
	_rig()
	q.force_passenger = "hurry"
	q.force_story = str(_stories[0]["id"])
	_request(9)
	r = q._ride
	_ok(r["dest"] == "Warsaw Spire" and absf(r["road"] - 4089.5) < 0.05 and absf(r["eta"] - 379.5) < 0.05 and r["ring"] == Vector3(120.0, 1.1397, -11.0) and r["finish"] == 0,
			"a story passenger in a hurry: %s, %.1f m, ETA %.1f s, ring %s, junction %d" % [r["dest"], r["road"], r["eta"], r["ring"], r["finish"]])
	hud.press(1)
	# A story whose place is a lane point: the ring on the road's surface, ending at the junction before it.
	_rig()
	q.force_story = str(_stories[2]["id"])
	_request(9)
	r = q._ride
	_ok(r["dest"] == "Dworzec Centralny" and r["ring"] == Vector3(1000.0, 2.1, 0.0) and r["finish"] == 2 and absf(r["road"] - 3609.5) < 0.05,
			"a story with a lane point for its place: %s, ring %s, junction %d, %.1f m" % [r["dest"], r["ring"], r["finish"], r["road"]])
	hud.press(1)
	_n_places()


## Where the rides go and come from when the city holds back: one name for every door, no kerb away
## from a door, doors no road reaches.
func _n_places() -> void:
	_rig()
	q.force_story = "none"
	var named: Array = ["Pod Gigantami"]
	for f: Dictionary in rivals._finishes:
		named.append(str(f["name"]).get_slice(" (", 0))
	for a: Dictionary in jobs._addresses:
		a["name"] = "Wszędzie 1"
	var none := 0
	var bad := 0
	for n in range(201, 216):
		if not _request(n):
			none += 1
			continue
		if not named.has(str(q._ride["dest"])):
			bad += 1
		hud.press(1)
	_ok(bad == 0 and none >= 5 and none < 15, "every door under one name: %d rides to a door of the pickup's own name, %d of 15 found nowhere to go" % [bad, none])
	_rig()
	q.force_story = "none"
	jobs.no_kerb_away = true
	var got := 0
	var away := 0
	for n in range(221, 233):
		if not _request(n):
			continue
		got += 1
		if bool(q._ride["offset"]):
			away += 1
		hud.press(1)
	_ok(got >= 8 and away == 0, "no kerb away from a door: %d of 12 rides, %d with the passenger away from the pin" % [got, away])
	_rig()
	q.force_story = "none"
	jobs.unreached_hi = 2500.0
	none = 0
	bad = 0
	for n in range(241, 256):
		if not _request(n):
			none += 1
			continue
		if not named.has(str(q._ride["dest"])) or q._ride["dest"] == "Pod Gigantami":
			bad += 1
		hud.press(1)
	_ok(bad == 0 and none >= 5 and none < 15, "doors no road reaches: %d rides to one, %d of 15 found none to go to" % [bad, none])
	_rig()
	q.force_story = "none"
	q.force_passenger = "date"
	var nd := _find(7, func(x: Dictionary) -> bool: return str(x["type"]) == "date")
	hud.press(1)
	jobs.unreached_hi = 6000.0
	_ok(_request(nd) and q._ride["type"] == "normal" and q._ride["dest"] != "Pod Gigantami", "a date at a door no road reaches: a %s passenger to %s" % [q._ride["type"], q._ride["dest"]])
	hud.press(1)
	_rig()
	q.force_story = str(_stories[0]["id"])
	_ok(_request(9) and str((q._ride["story"] as Dictionary).get("id", "")) == str(_stories[0]["id"]), "no ride 9 with the first story")
	hud.press(1)
	jobs.unreached_hi = 6000.0
	_ok(_request(9) and (q._ride["story"] as Dictionary).is_empty(), "a story went to a door no road reaches")
	hud.press(1)


# --- O. the autopilot's legs and what a ride leaves behind ------------------------------------------------------

## A frame on the autopilot with no await: the traffic, the job's drive of the car, the job's two frames.
func _autoframe() -> void:
	if q.traffic != null:
		traffic.step(DT)
	_last_dp = q.drive_player()
	car.velocity = car.vel
	q.flying = false
	q.away = false
	q._physics_process(DT)
	q._process(DT)
	_frames += 1


## Autopilot frames until the job is idle again (at most `seconds` of them).
func _auto_until_idle(seconds: float) -> bool:
	for i in roundi(seconds * 60.0):
		_autoframe()
		if _is_idle() and _stage() == Rides.Stage.NONE:
			return true
	return false


## A rig on the autopilot with the first plain, short ride taken and the car on the way to the passenger.
func _auto_rig() -> Dictionary:
	_rig()
	q.autopilot = true
	q.force_story = "none"
	q.force_passenger = "normal"
	_find(1, func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0 and _plain(x))
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	return r


func _o_auto() -> void:
	# No lane by the car: the job drives the car straight at the junction.
	var r := _auto_rig()
	var node: Vector2 = _graph.node_pos[16]
	car.global_position = Vector3(-80.0, 0.0, 2480.0)
	car.rotation.y = 1.0
	car.throttle = 1.0
	_autoframe()
	_ok(_last_dp and traffic.ghosts.is_empty(), "no lane by the car: the job did not take the frame (%s)" % _last_dp)
	var before := _v2(car.global_position).distance_to(node)
	_autoframe()
	var want_yaw := atan2(-(node.x + 80.0), -(node.y - 2480.0))
	_ok(_last_dp and traffic.ghosts.is_empty() and absf(_v2(car.global_position).distance_to(node) - (before - 0.2)) < 0.01,
			"no lane by the car: the job drove %s, a ghost %d, the way to the junction shortened by %.2f m" % [_last_dp, traffic.ghosts.size(), before - _v2(car.global_position).distance_to(node)])
	_ok(absf(angle_difference(car.rotation.y, want_yaw)) < 0.001 and car.throttle == 0.0 and car.vel == Vector3.ZERO,
			"the straight leg turns the car to %.3f (it is at %.3f), takes its throttle off (%.1f) and its speed (%s)" % [want_yaw, car.rotation.y, car.throttle, car.vel])
	# The road leg: the ghost carries the car, with its heading, its speed and no throttle.
	r = _auto_rig()
	car.rotation.y = 1.0
	car.throttle = 1.0
	for i in 30:
		_autoframe()
	var g: Ghost = traffic.ghosts[0]
	_ok(_v2(car.global_position).distance_to(Vector2(g.pos.x, g.pos.z)) < 0.01 and absf(angle_difference(car.rotation.y, g.yaw)) < 0.001 and car.rotation.y != 1.0,
			"on the road the car is at the ghost's place with its heading (%.3f, the ghost %.3f)" % [car.rotation.y, g.yaw])
	_ok(absf(car.vel.length() - 18.2) < 0.01 and car.vel.normalized().distance_to(Vector3(-sin(g.yaw), 0.0, -cos(g.yaw))) < 0.001 and car.throttle == 0.0,
			"on the road the car has the ghost's speed (%.2f m/s of 18.2) and heading, and no throttle (%.1f)" % [car.vel.length(), car.throttle])
	# A leg ends 12 m from its junction; a moving ghost is not told to squeeze by.
	g.pos = Vector3(node.x + 20.0, 0.0, node.y)
	_autoframe()
	_ok(traffic.ghosts.size() == 1 and traffic.removed == 0, "the road leg ended 20 m from its junction")
	g.pos = Vector3(node.x + 10.0, 0.0, node.y)
	_autoframe()
	_ok(traffic.ghosts.is_empty() and traffic.removed == 1, "the road leg did not end 10 m from its junction (ghosts %d, taken off %d)" % [traffic.ghosts.size(), traffic.removed])
	_autoframe()
	_ok(traffic.ghosts.is_empty() and _last_dp, "the straight leg after it did not go on without a ghost")
	# The straight leg stops at 0.6 m from its point.
	var kerb: Vector2 = r["kerb"]
	car.global_position = Vector3(kerb.x + 3.0, 0.0, kerb.y)
	for i in 25:
		_autoframe()
	_ok(_v2(car.global_position).distance_to(kerb) < 0.7, "the straight leg stopped %.2f m from the kerb" % _v2(car.global_position).distance_to(kerb))
	# Near the passenger's kerb the road leg is over though the junction is far.
	r = _auto_rig()
	_autoframe()
	g = traffic.ghosts[0]
	_ok(_flat(Vector3(kerb.x, 0.0, kerb.y), Vector3(node.x, 0.0, node.y)) > 30.0, "the kerb is not near the junction")
	g.pos = Vector3(kerb.x + 8.0, 0.0, kerb.y)
	_autoframe()
	_ok(traffic.ghosts.is_empty() and traffic.removed == 1, "the road leg did not end 8 m from the passenger's kerb (ghosts %d)" % traffic.ghosts.size())
	# A moving ghost is never told to squeeze by; one let go from a jam is told once.
	r = _auto_rig()
	_autoframe()
	g = traffic.ghosts[0]
	for i in 360:
		g.pos = Vector3(node.x + 3000.0, 0.0, node.y)
		_autoframe()
	_ok(g.squeezes == 0 and g.v > 18.0, "a moving ghost was told to squeeze by %d times" % g.squeezes)
	r = _auto_rig()
	traffic.jam = true
	traffic.gentle = true
	for i in 420:
		_autoframe()
	g = traffic.ghosts[0]
	_ok(g.squeezes == 1 and g.squeeze == 3.0 and g.v > 1.0, "the ghost in the jam was told to squeeze by %d times (%.1f), it goes at %.1f m/s" % [g.squeezes, g.squeeze, g.v])
	# START KURS and the ✕ while the ghost drives take it off the road.
	r = _auto_rig()
	for i in 20:
		_autoframe()
	_ok(traffic.ghosts.size() == 1 and _in_stage(Rides.Stage.PICKUP), "no ghost on the way to the passenger")
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RIDE) and traffic.ghosts.is_empty() and traffic.removed == 1, "START KURS left the pickup's ghost on the road (%d)" % traffic.ghosts.size())
	for i in 20:
		_autoframe()
	_ok(traffic.ghosts.size() == 1 and traffic.raced.back()["finish"] == 24, "no ghost on the ride, or not to junction 24: %s" % [traffic.raced])
	_abort()
	_ok(_in_stage(Rides.Stage.RESULT) and traffic.ghosts.is_empty() and traffic.removed == 2, "the ✕ left the ghost on the road (%d)" % traffic.ghosts.size())
	# With the autopilot switched off on the ride, the door by hand takes the ghost off the road.
	r = _auto_rig()
	for i in 20:
		_autoframe()
	_tap("ride_start")
	for i in 30:
		_autoframe()
	_ok(traffic.ghosts.size() == 1, "no ghost on the ride")
	q.autopilot = false
	_car_from_q()
	_ok(not q.drive_player(), "the autopilot drove the ride with the autopilot off")
	_arrive(r)
	_ok(traffic.ghosts.is_empty() and _in_stage(Rides.Stage.RESULT), "the ghost stayed after the door (%d)" % traffic.ghosts.size())


# --- P. the pickup: where the car starts, what the hints say, what a ride leaves behind ----------------------------

## How many lines the dialogue was asked for whose "group:tag" starts with `prefix`.
func _count_prefix(prefix: String) -> int:
	var c := 0
	for s in dialogue.said:
		if s.begins_with(prefix):
			c += 1
	return c


func _p_pickup() -> void:
	# The flag's ride: the car 60 m before the passenger on their street, still, on the road's surface.
	_rig()
	q.force_story = "none"
	car.vel = Vector3(5.0, 0.0, 0.0)
	car.forward_speed = 12.0
	_request(101)
	var p := car.global_position
	_ok(p.distance_to(Vector3(2002.0, 1.616775, 2264.893)) < 0.01 and absf(car.rotation.y) < 0.001 and car.vel == Vector3.ZERO and car.forward_speed == 0.0,
			"ride 101 by the flag: the car at %s heading %.3f, going %s at %.1f" % [p, car.rotation.y, car.vel, car.forward_speed])
	_ok(absf(q._ride["away"] - 17.4) < 0.05, "ride 101 by the flag: the pin is %.1f m from the car" % q._ride["away"])
	hud.press(1)
	_request(108)
	p = car.global_position
	_ok(p.distance_to(Vector3(798.0, 1.8148, 90.0)) < 0.01 and absf(absf(car.rotation.y) - PI) < 0.001 and absf(q._ride["away"] - 60.67) < 0.05,
			"ride 108 by the flag: the car at %s heading %.3f, the pin %.2f m away" % [p, car.rotation.y, q._ride["away"]])
	hud.press(1)
	# The hello: 80 m from the passenger, with the offset words when they wait away from the pin.
	_rig()
	q.force_story = "none"
	_request(101)
	_take()
	_secs(3.0 / 60.0)
	_ok(_count_prefix("podwozka_pickup") == 1 and dialogue.said.back() == "podwozka_pickup:offset" and dialogue.hows.back()[3] == true,
			"ride 101: the passenger away from the pin calls out with the offset words (%s)" % [dialogue.said.back()])
	_abort()
	_rig()
	q.force_story = "none"
	_request(108)
	_take()
	_secs(3.0 / 60.0)
	_ok(_count_prefix("podwozka_pickup") == 1 and dialogue.said.back() == "podwozka_pickup:" and dialogue.hows.back()[3] == false,
			"ride 108: the passenger at the pin calls out with the plain words (%s)" % [dialogue.said.back()])
	_abort()
	_p_hints()
	_p_after()


## The hints, the metres and the target on the way to a passenger who waits away from the pin, and at it.
func _p_hints() -> void:
	var pin_hint := "Pinezka swoje, pasażer swoje: szukaj „!”"
	var go_hint := "Jedź do pinezki (turkusowe światło)"
	var pull_hint := "Stań przy pasażerze"
	_rig()
	q.force_story = "none"
	_request(101)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	var pin := _v2(r["pin"])
	var board := _v2(r["board"])
	var u := (board - pin).normalized()
	_at(pin - u * 35.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(board.distance_to(_v2(_car3())) > 71.0 and pin.distance_to(_v2(_car3())) < 39.0, "the scene: near the pin, far from the passenger")
	_ok(hud.status == pin_hint and q.target_position() == r["pin"] and hud.distance == "35 m", "35 m before the pin, 80 m from the passenger: %s, the target the pin, %s" % [hud.status, hud.distance])
	_at(board + Vector2(-u.y, u.x) * 50.0, 9.0)
	_secs(3.0 / 60.0)
	var d_pin := _v2(_car3()).distance_to(pin)
	_ok(hud.status == pin_hint and q.target_position() == r["board"] and hud.distance == "50 m" and d_pin > 60.0,
			"50 m from the passenger, %.0f m from the pin: %s, the target the passenger, %s" % [d_pin, hud.status, hud.distance])
	_at(board + u * 20.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == pull_hint and hud.distance == "20 m", "20 m from the passenger: %s, %s" % [hud.status, hud.distance])
	_at(board + u * 60.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == pin_hint, "60 m from the passenger who waits away from the pin: %s" % hud.status)
	_at(board + u * 100.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == go_hint and q.target_position() == r["pin"], "100 m away: %s" % hud.status)
	_abort()
	# A passenger at the pin: the pin hint is never theirs, and "pull up" starts at 25 m.
	_rig()
	q.force_story = "none"
	_request(108)
	r = q._ride.duplicate(true)
	_take()
	board = _v2(r["board"])
	pin = _v2(r["pin"])
	u = (board - pin).normalized()
	_at(board - u * 35.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == go_hint, "35 m from a passenger at the pin: %s" % hud.status)
	_at(board - u * 30.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == go_hint and hud.distance == "30 m", "30 m from a passenger at the pin: %s, %s" % [hud.status, hud.distance])
	_at(board - u * 24.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == pull_hint, "24 m from the passenger: %s" % hud.status)
	_abort()


func _car3() -> Vector3:
	return car.global_position


## What the end of a ride leaves behind, and what the start of the next one must not find.
func _p_after() -> void:
	# The passenger gives up at 3 times the ETA of 60 m, not of the pin's own 17 m.
	_rig()
	q.force_story = "none"
	_request(101)
	_take()
	_secs(79.0)
	_ok(_in_stage(Rides.Stage.PICKUP), "the passenger gave up before 79 s")
	_secs(1.5)
	_ok(_in_stage(Rides.Stage.RESULT) and hud.card == "PASAŻER ANULOWAŁ", "the passenger did not give up by 80.5 s: %s" % hud.card)
	# The frame they board: the status line is the ride's, not the pickup's.
	_rig()
	q.force_story = "none"
	_request(108)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	var b: Vector3 = r["board"]
	_at(Vector2(b.x, b.z))
	var drawn := 0
	for i in 120:
		drawn = hud.lines
		_frame()
		if _in_stage(Rides.Stage.RIDE):
			break
	_ok(_in_stage(Rides.Stage.RIDE) and hud.lines == drawn, "the frame they boarded a pickup status line was drawn (%d lines, %d before)" % [hud.lines, drawn])
	# The hold for boarding starts again with each ride.
	_arrive(r)
	q.finish()
	_request(108)
	r = q._ride.duplicate(true)
	_at(_v2(r["board"]))
	_take()
	_secs(0.5)
	_ok(_in_stage(Rides.Stage.PICKUP), "the second passenger boarded in 0.5 s: the hold of the first was kept")
	_secs(0.6)
	_ok(_in_stage(Rides.Stage.RIDE), "the second passenger did not board after 1.1 s")
	_abort()
	# The ✕ takes down START KURS, rings the ticker, puts the bubbles out, and the result card of the last ride
	# does not come over the cancelled one.
	_rig()
	q.force_story = "none"
	_request(108)
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	_arrive(r)
	q.finish()
	_request(108)
	r = q._ride.duplicate(true)
	_at(_v2(r["board"]) + Vector2(10.0, 0.0), 9.0)
	_take()
	_secs(0.2)
	_ok(hud.pill == "ride_start", "no START KURS 10 m from the passenger")
	var tickers := hud.tickers
	_abort()
	_ok(hud.pill == "" and hud.tickers == tickers + 1 and bubbles.hushed.back() == car, "the ✕: the pill %s, the ticker %d -> %d, the bubbles hushed for %s" % [hud.pill, tickers, hud.tickers, bubbles.hushed.back()])
	_secs(3.5)
	_ok(hud.card == "KURS ANULOWANY", "the cancelled card was taken over after 3.5 s: %s" % hud.card)
	_p_first_chat()


## The first small talk comes 8 to 14 s after boarding.
func _p_first_chat() -> void:
	_rig()
	q.force_story = "none"
	var lo := 1000.0
	var hi := 0.0
	for k in 24:
		_find(300 + 7 * k, _plain)
		var r: Dictionary = q._ride.duplicate(true)
		_take()
		_board(r)
		_at(Vector2(-80.0, 2480.0), 12.0)
		var said := dialogue.said.size()
		var t0 := _frames
		_until(func() -> bool: return dialogue.said.size() > said, 25.0)
		var t := float(_frames - t0) * DT
		lo = minf(lo, t)
		hi = maxf(hi, t)
		_abort()
		q.finish()
	_ok(lo >= 8.0 and hi <= 14.1, "the first small talk came %.1f to %.1f s after boarding (24 rides)" % [lo, hi])


# --- Q. two rides in a row: what the first must not leave to the second ------------------------------------------

func _q_pairs() -> void:
	var short := func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0
	# The end of a ride: the app's line is taken off the map and the next request's clock is thrown again.
	_rig()
	q.force_story = "none"
	_through(5)
	_ok(hud.route.size() == 0, "the app's line stayed on the minimap after the ride (%d points)" % hud.route.size())
	var t0 := _frames
	var got := _until(_on_offer, 200.0)
	var waited := float(_frames - t0) * DT
	_ok(got >= 0 and waited > 97.0 and waited < 97.6, "the next request came %.1f s after the ride (the clock is thrown again at its end)" % waited)
	# The same river ride twice on the autopilot: the hello, Nawigacja and the half star each time.
	_rig()
	q.autopilot = true
	q.force_story = "none"
	q.force_passenger = "believer"
	q.force_quirk = "river"
	for k in 2:
		_find(1, short)
		_take()
		_ok(_auto_until_idle(400.0), "river ride %d of 2 did not end" % (k + 1))
	_ok(_count_prefix("podwozka_pickup") == 2 and _count_said("podwozka_gps:river") == 2 and hud.toasts.count("+½ ★ · za aplikacją") == 2 and traffic.raced.size() == 6,
			"two river rides: %d hellos, Nawigacja %d times, %d half stars, %d ghosts raced" % [_count_prefix("podwozka_pickup"), _count_said("podwozka_gps:river"),
			hud.toasts.count("+½ ★ · za aplikacją"), traffic.raced.size()])
	# A passenger who asks for a Frogs asks on the second ride too.
	_rig()
	q.autopilot = true
	q.frogs = frogs
	q.force_story = "none"
	q.force_passenger = "detour"
	for k in 2:
		_find(1, short)
		_take()
		_ok(_auto_until_idle(400.0), "stop ride %d of 2 did not end" % (k + 1))
	_ok(_count_said("podwozka_passenger:detour") == 2, "the passenger asked for a Frogs %d times in two rides" % _count_said("podwozka_passenger:detour"))
	# A story passenger tells all three lines and asks on the second ride too.
	_rig()
	q.autopilot = true
	q.force_story = str(_stories[0]["id"])
	q.force_answer = 0
	for k in 2:
		_request(9)
		_take()
		_ok(_auto_until_idle(400.0), "story ride %d of 2 did not end" % (k + 1))
	_ok(q.story_lines == 6 and q.story_answers == 2, "two story rides: %d lines, %d answers" % [q.story_lines, q.story_answers])
	_q_story_times()


## The lines of a story come at 3 s, then each 7.5 s after the last, with the car well on its way; the
## question after the third.
func _q_story_times() -> void:
	_rig()
	q.force_story = str(_stories[0]["id"])
	_request(9)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	var ring := _v2(r["ring"])
	var start := _v2(r["board"])
	_at(ring + (start - ring) * 0.5, 9.0)
	var times: Array = []
	var seen := 0
	var asked := -1.0
	for i in 40 * 60:
		_frame()
		if q.story_lines > seen:
			seen = q.story_lines
			times.append(snappedf(_ride_s(), 0.1))
		if q._asking and asked < 0.0:
			asked = _ride_s()
			break
	_ok(times.size() == 3 and absf(times[0] - 3.0) < 0.2 and absf(times[1] - 10.5) < 0.2 and absf(times[2] - 18.0) < 0.2 and absf(asked - 25.5) < 0.2,
			"the story's lines came at %s s, the question at %.1f s (3, 10.5, 18, 25.5)" % [times, asked])
	_ok(bubbles.durations.slice(bubbles.durations.size() - 3) == [4.5, 4.5, 4.5], "the story's lines stay %s s" % [bubbles.durations])
	# Far from the door, the lines wait for the clock: 3, 13 and 23 s, the question at 32.
	_rig()
	q.force_story = str(_stories[0]["id"])
	_request(9)
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	_at(start, 9.0)
	times = []
	seen = 0
	asked = -1.0
	for i in 40 * 60:
		_frame()
		if q.story_lines > seen:
			seen = q.story_lines
			times.append(snappedf(_ride_s(), 0.1))
		if q._asking and asked < 0.0:
			asked = _ride_s()
			break
	_ok(times.size() == 3 and absf(times[0] - 3.0) < 0.2 and absf(times[1] - 13.0) < 0.2 and absf(times[2] - 23.0) < 0.2 and absf(asked - 32.0) < 0.2,
			"at the start of the way the lines came at %s s, the question at %.1f s (3, 13, 23, 32)" % [times, asked])
	# The reply stays 5 s and takes the line bubbles down.
	var hushed := bubbles.hushed.size()
	hud.press(0)
	_ok(bubbles.hushed.size() == hushed + 1 and bubbles.hushed.back() == car and bubbles.durations.back() == 5.0, "the reply: the bubbles hushed %d times, it stays %.1f s" % [bubbles.hushed.size() - hushed, bubbles.durations.back()])
	_abort()


# --- R. plans met on the way: the pin's ring, the waypoint's road, a turn that is not there ------------------------

func _r_plans() -> void:
	# The pin's ring: lit and waving for the car, with nobody standing in it.
	_rig()
	q.force_story = "none"
	_request(108)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_ok(_ring_look(q._beacon) == [true, r["pin"], 12.5, TEAL, true, true, false], "the pin's ring: %s" % [_ring_look(q._beacon)])
	var started := _frames
	var b: Vector3 = r["board"]
	_at(Vector2(b.x, b.z))
	_secs(1.2)
	_ok(_in_stage(Rides.Stage.RIDE) and absf(float(q._ride.get("picked_after", -1.0)) - float(_frames - started) * DT) < 0.1 + 0.1, "how long the pickup took is kept: %.1f s" % float(q._ride.get("picked_after", -1.0)))
	# The app's road leg is over near the waypoint's road, however far the next junction is.
	_rig()
	q.autopilot = true
	q.force_story = "none"
	q.force_passenger = "believer"
	q.force_quirk = "river"
	_find(1, func(x: Dictionary) -> bool: return float(x["road"]) < 1500.0)
	r = q._ride.duplicate(true)
	_take()
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RIDE), "the river ride did not start")
	_autoframe()
	_autoframe()
	_ok(traffic.ghosts.size() == 1, "no ghost on the river ride")
	var road := Vector2(2400.0, 1000.0)
	var removed := traffic.removed
	traffic.ghosts[0].pos = Vector3(road.x, 0.0, road.y - 8.0)
	_autoframe()
	_ok(traffic.removed == removed + 1 and traffic.ghosts.is_empty(), "the road leg did not end 8 m from the waypoint's road (%d ghosts)" % traffic.ghosts.size())
	_abort()
	# The Frogs turn by the dice with no Frogs on the way is no quirk at all.
	_rig()
	q.force_story = "none"
	q.frogs = frogs
	frogs.doors = [Vector2(-5000.0, -5000.0)]
	var n := _find(1, func(x: Dictionary) -> bool: return str(x["quirk"]) == "rechotka")
	_ok(n > 0, "no Frogs turn by the dice")
	_take()
	_board(q._ride)
	_ok(_in_stage(Rides.Stage.RIDE) and str(q._ride["quirk"]) == "" and (q._ride["q"] as Dictionary).is_empty(), "a Frogs turn with no Frogs on the way stayed a quirk: \"%s\"" % q._ride["quirk"])
	_secs(5.0)
	_abort()


# --- S. the plans asked straight, in the bigger city -----------------------------------------------------------

func _edge_of(a: int, b: int) -> int:
	for e in _graph.e_a.size():
		if _graph.e_a[e] == a and _graph.e_b[e] == b:
			return e
	return -1


## The app's road from lane point (e, s) to the junction `to`.
func _route_to(e: int, s: float, to: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	q._road_path(e, s, to, _graph.distances_to(to), out)
	return out


## The road's points where it turns by more than `sharp` rad, `from` m or more in.
func _turns(path: PackedVector2Array, from := 250.0, sharp := 0.8) -> Array:
	var out: Array = []
	var run := 0.0
	for i in range(1, path.size() - 1):
		run += path[i].distance_to(path[i - 1])
		if run > from and absf((path[i] - path[i - 1]).angle_to(path[i + 1] - path[i])) > sharp:
			out.append(path[i])
	return out


func _s_plans() -> void:
	_rig(true, {}, {"big": true})
	q.force_story = "none"
	# Straight lines over dry, open ground.
	for l: Array in [[Vector2(600.0, 1200.0), Vector2(600.0, 1260.0), false, "over the small pond"],
			[Vector2(120.0, 1200.0), Vector2(120.0, 1160.0), false, "through the small roof"],
			[Vector2(120.0, 1150.0), Vector2(120.0, 1230.0), false, "80 m long with the small roof's 8 m on it"],
			[Vector2(1000.0, 1200.0), Vector2(1000.0, 1250.0), true, "over open ground"]]:
		_ok(q._clear(l[0], l[1]) == l[2], "the line %s is %s" % [l[3], "clear" if q._clear(l[0], l[1]) else "not clear"])
	_ok(q._wet(PUDDLE, 2.0), "a point in a puddle is dry")
	_ok(not q._wet(PUDDLE + Vector2(0.0, 10.0), 2.0), "a point 10 m from a puddle is wet")
	_ok(not q._wet(PUDDLE + Vector2(0.0, 1.9), 0.5) and q._wet(PUDDLE + Vector2(0.0, 1.9), 1.5), "water 1.9 m from a point is %s within 0.5 m, %s within 1.5 m" % [
			q._wet(PUDDLE + Vector2(0.0, 1.9), 0.5), q._wet(PUDDLE + Vector2(0.0, 1.9), 1.5)])
	_s_zone()
	_s_river()
	_s_turn()
	_s_story_places()
	_s_edges()
	_s_scans()
	_s_steps()
	_t_statics()
	_t_quirk_rules()
	_t_detour()
	_t_misc()
	_t_lanes()


func _zone(what: String, parks: Array, a_e: int, a_s: float, ring: Vector2) -> Dictionary:
	var list: Array[Dictionary] = []
	for p: Array in parks:
		list.append({"name": p[0], "w": p[1]})
	q._parks = list
	q._ride = {"road": 1500.0, "ring": Vector3(ring.x, 0.0, ring.y)}
	return q._zone_plan(a_e, a_s, _graph.distances_from(_graph.e_b[a_e]), _graph.distances_to(_node(3, 3)))


## A park's paths asked straight: in on the road toward A, out on the road toward B.
func _s_zone() -> void:
	var north := _edge_of(_node(1, 2), _node(2, 2))
	var plan := _zone("a park 15 m from the road", [["Park Próbny", Vector2(600.0, 1215.0)]], north, 200.0, Vector2(1000.0, 1215.0))
	_ok(plan.is_empty(), "a park 15 m from the road has a plan: %s" % [plan])
	plan = _zone("the small roof on the way in", [["Park Próbny", Vector2(120.0, 1160.0)]], _edge_of(_node(0, 4), _node(1, 4)), 120.0, Vector2(700.0, 1160.0))
	_ok(plan.is_empty(), "the way in through the small roof has a plan: %s" % [plan])
	plan = _zone("the small roof on the way out", [["Park Próbny", Vector2(120.0, 1160.0)]], _edge_of(_node(2, 2), _node(2, 3)), 360.0, Vector2(120.0, 1600.0))
	_ok(plan.is_empty(), "the way out through the small roof has a plan: %s" % [plan])
	plan = _zone("the small pond on the way in", [["Park Próbny", Vector2(600.0, 1252.0)]], north, 200.0, Vector2(995.5, 1192.0))
	_ok(plan.is_empty(), "the way in over the small pond has a plan: %s" % [plan])
	plan = _zone("open ground", [["Park Próbny", Vector2(1000.0, 1240.0)]], _edge_of(_node(2, 2), _node(3, 2)), 200.0, Vector2(1400.0, 1240.0))
	_ok(str(plan.get("name", "")) == "Park Próbny" and plan["w"] == Vector2(1000.0, 1240.0) and plan["r"] == Vector2(1000.0, 1200.0) and plan["r2"] == Vector2(1035.0, 1200.0),
			"a park over open ground: %s" % [plan])
	_ok(absf(float(plan["detour"]) + 41.85) < 0.05 and plan["gap"] == 40.0 and plan["e"] == _edge_of(_node(2, 3), _node(3, 3)) and plan["e2"] == plan["e"],
			"a park over open ground: the detour %.2f m (the paths in and out counted), %.0f m from the road" % [plan["detour"], plan["gap"]])
	plan = _zone("a park beside the way", [["Park Próbny", Vector2(1000.0, 1240.0)]], _edge_of(_node(2, 2), _node(3, 2)), 200.0, Vector2(1000.0, 900.0))
	_ok(plan.is_empty(), "a park beside the way, not between the car and the door, has a plan: %s" % [plan])
	plan = _zone("two parks", [["Park Pierwszy", Vector2(1000.0, 1240.0)], ["Park Drugi", Vector2(1100.0, 1240.0)]], _edge_of(_node(2, 2), _node(3, 2)), 200.0, Vector2(1400.0, 1240.0))
	_ok(str(plan.get("name", "")) == "Park Drugi" and absf(float(plan["detour"]) + 48.86) < 0.05, "of two parks the one that adds least was not taken: %s %.2f" % [plan.get("name"), plan.get("detour", 0.0)])


## The river plan for a car on the lane of `a` -> `b` (100 m along it) bound for junction `to`.
func _river(a: int, b: int, to: int, forced: bool) -> Dictionary:
	var e := _edge_of(a, b)
	var dist_b := _graph.distances_to(to)
	var path := PackedVector2Array()
	q._road_path(e, 100.0, to, dist_b, path)
	var road := 0.0
	for i in range(1, path.size()):
		road += path[i].distance_to(path[i - 1])
	q._ride = {"road": road}
	q.force_quirk = "river" if forced else ""
	return q._river_plan(e, 100.0, _graph.distances_from(_graph.e_b[e]), dist_b)


## The nearest river spot: what it adds is the road there, the walk to the water and back, the road on.
func _s_river() -> void:
	_rig(true, {}, {"big": true})
	q.force_story = "none"
	var plan := _river(_node(4, 1), _node(5, 1), _node(6, 3), false)
	_ok(plan.get("e") == 50 and plan.get("w") == Vector2(2435.0, 600.0) and plan.get("detour") == 70.0 and plan.get("gap") == 35.0,
			"the river spot beside the way adds the walk to the water and back: %s" % [plan])
	plan = _river(_node(4, 3), _node(5, 3), _node(6, 3), false)
	_ok(plan.get("e") == 76 and plan.get("w") == Vector2(2435.0, 1000.0) and plan.get("detour") == 870.0, "a river spot 870 m out of the way by the dice: %s" % [plan])
	plan = _river(_node(0, 0), _node(1, 0), _node(0, 2), false)
	_ok(plan.is_empty(), "a river ride by the dice over 1500 m out of the way: %s" % [plan])
	plan = _river(_node(0, 0), _node(1, 0), _node(0, 2), true)
	_ok(plan.get("e") == 50 and plan.get("detour") == 4070.0, "a forced river ride takes the nearest spot however far: %s" % [plan])
	# A river ride planned before the scan is done finishes it.
	_rig(false)
	q.force_story = "none"
	q.force_quirk = "river"
	q._offer_in = 0.02
	_until(_on_offer, 0.3)
	_ok(_on_offer() and not q._river_ready, "the scan was done in the first frames")
	_take()
	_tap("ride_start")
	_ok(_in_stage(Rides.Stage.RIDE) and q._river_ready and str(q._ride["quirk"]) == "river", "boarding did not finish the scan for the river's plan: ready %s, the quirk \"%s\"" % [q._river_ready, q._ride["quirk"]])
	_abort()


## The Frogs turn asked straight: which corner on the way, and where the Frogs stand.
func _turn_plan(e: int, s: float, to: int, forced: bool) -> Dictionary:
	q.force_quirk = "rechotka" if forced else ""
	q._ride = {"finish": to}
	return q._rechotka_plan(e, s, _graph.distances_to(to))


func _s_turn() -> void:
	_rig(true, {}, {"big": true})
	q.force_story = "none"
	var west := _edge_of(_node(0, 0), _node(1, 0))
	var fin := -1
	var turns: Array = []
	for cand in N * N:
		turns = _turns(_route_to(west, 10.0, cand))
		if turns.size() >= 2 and (turns[0] as Vector2).distance_to(turns[1]) > 150.0:
			fin = cand
			break
	_ok(fin >= 0, "no road with two turns from the corner")
	if fin < 0:
		return
	var by := Vector2(8.0, 8.0)
	q.frogs = null
	var plan := _turn_plan(west, 10.0, fin, false)
	_ok(plan == {"w": turns[0]}, "with no Frogs in the city the first turn is the place: %s" % [plan])
	q.frogs = frogs
	frogs.doors = [Vector2(-5000.0, -5000.0)]
	frogs.shops = [{"triple": ""}]
	plan = _turn_plan(west, 10.0, fin, true)
	_ok(plan == {"w": turns[0]}, "forced with no Frogs on the way the first turn is the place: %s" % [plan])
	plan = _turn_plan(west, 10.0, fin, false)
	_ok(plan == {}, "by the dice with no Frogs on the way there is no plan: %s" % [plan])
	frogs.doors = [turns[0] + by, turns[1] + by]
	frogs.shops = [{"triple": ""}, {"triple": ""}]
	plan = _turn_plan(west, 10.0, fin, false)
	_ok(plan == {"w": turns[0], "triple": false, "shop": 0}, "a Frogs on both corners, the first is taken: %s" % [plan])
	frogs.shops = [{"triple": ""}, {"triple": "x3"}]
	plan = _turn_plan(west, 10.0, fin, false)
	_ok(plan == {"w": turns[1], "triple": true, "shop": 1}, "a triple corner after a plain one wins: %s" % [plan])
	frogs.doors = [turns[0] + Vector2(60.0, 0.0)]
	frogs.shops = [{"triple": ""}]
	plan = _turn_plan(west, 10.0, fin, false)
	_ok(plan == {}, "a Frogs 60 m from the corner is on the way: %s" % [plan])
	frogs.doors = [Vector2(200.0, 0.0)]
	var early := _route_to(west, 200.0, _node(1, 2))
	_ok(_turns(early).is_empty() and _turns(early, 100.0).size() == 1, "the road with its one turn 200 m in: %s" % [early])
	frogs.doors = [(_turns(early, 100.0)[0] as Vector2) + by]
	plan = _turn_plan(west, 200.0, _node(1, 2), false)
	_ok(plan == {}, "a turn 200 m in is a turn too near for the Frogs: %s" % [plan])
	var spur := _edge_of(N * N, _node(0, N - 1))
	var bent := _route_to(spur, 10.0, _node(0, 3))
	_ok(_turns(bent).is_empty() and _turns(bent, 250.0, 0.1).size() >= 1, "the spur's bend: %s" % [bent])
	frogs.doors = [(_turns(bent, 250.0, 0.1)[0] as Vector2) + by]
	plan = _turn_plan(spur, 10.0, _node(0, 3), false)
	_ok(plan == {}, "a bend of 0.3 rad is not a turn: %s" % [plan])
	frogs.doors = FROG_DOORS.duplicate()
	frogs.shops = [{"triple": ""}, {"triple": "x3"}, {"triple": ""}]
	q.force_quirk = ""


func _place(pe: int, ps: float, drop: Array) -> Dictionary:
	var st := {"id": "g", "to": {"name": ["Plac", "Square"], "at": [-5000.0, -5000.0], "r": 10, "drop": drop}}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return q._story_place({"p_e": pe, "p_s": ps}, st, rng, Vector2(1300.0, 1203.0))


## A story's place by its lane point.
func _s_story_places() -> void:
	_rig(true, {}, {"big": true})
	q.force_story = "none"
	var e := _edge_of(_node(3, 3), _node(4, 3))
	var spur := _edge_of(N * N, _node(0, N - 1))
	var near := _place(e, 100.0, [1700.0, 1201.75])
	_ok(near.is_empty(), "a lane point 400 m by road is a story's place: %s" % [near])
	var right := _place(e, 100.0, [2100.0, 1201.75])
	_ok(not right.is_empty() and absf(float(right["road"]) - 800.0) < 1.0 and int(right["finish"]) == _node(5, 3), "a lane point 800 m by road: %s" % [right])
	var off := _place(e, 100.0, [2100.0, 1235.0])
	_ok(off.is_empty(), "a point 33 m from any lane is a story's place: %s" % [off])
	var far := _place(spur, 10.0, [2300.0, 1.75])
	_ok(far.is_empty(), "a lane point over 6 km by road is a story's place: %s" % [far])


func _s_edges() -> void:
	pass



## A spot tried straight at a water's-edge sample: the rows it would add (empty: refused).
func _spot_try(edge: Vector2, into: Vector2) -> Array:
	q._river_raw.clear()
	q._try_spot(edge, into)
	var out: Array = []
	for sp: Dictionary in q._river_raw:
		out.append([sp["e"], snappedf(sp["s"], 0.01), sp["w"], snappedf(sp["gap"], 0.01)])
	q._river_raw.clear()
	return out


func _todo_strings() -> Array:
	var out: Array = []
	for it: Array in q._river_todo:
		out.append("%d,%d,%d,%d" % [it[0].x, it[0].y, it[1].x, it[1].y])
	out.sort()
	return out


## The river scan in the big city with no bank list: the frames it takes, the spots it finds, the GPS moments' edges.
func _s_scans() -> void:
	_rig(true, {}, {"big": true})
	var bank: Array = []
	for sp: Dictionary in q.river_spots:
		bank.append([sp["e"], snappedf(sp["s"], 0.01), sp["w"], snappedf(sp["gap"], 0.01)])
	_ok(bank == [[50, 200.0, Vector2(2435.0, 600.0), 35.0], [76, 200.0, Vector2(2435.0, 1000.0), 35.0], [128, 200.0, Vector2(2435.0, 1800.0), 35.0],
			[154, 200.0, Vector2(2435.0, 2200.0), 35.0]], "the bake's river spots: %s" % [bank])
	_rig(true, {}, {"big": true, "bank": false})
	var f := 0
	while q.moments.river_edges.is_empty() and f < 2000:
		_frame()
		f += 1
	_ok(f == 122, "the scan was done in %d frames" % f)
	var spots: Array = []
	for sp: Dictionary in q.river_spots:
		spots.append([sp["e"], snappedf(sp["s"], 0.01), sp["w"], snappedf(sp["gap"], 0.01)])
	_ok(spots == [[128, 388.0, Vector2(2439.0, 1988.0), 39.0], [129, 12.0, Vector2(2439.0, 1988.0), 39.0], [103, 156.0, Vector2(2439.0, 1444.0), 39.0],
			[76, 356.0, Vector2(2439.0, 1156.0), 39.0], [77, 44.0, Vector2(2439.0, 1156.0), 39.0], [50, 196.0, Vector2(2439.0, 596.0), 39.0],
			[51, 204.0, Vector2(2439.0, 596.0), 39.0]], "the river spots the scan found: %s" % [spots])
	_ok(q.moments.river_edges == {128: [388.0, 44.0], 129: [12.0, 44.0], 103: [156.0, 44.0], 102: [244.0, 44.0], 76: [356.0, 44.0], 77: [44.0, 44.0],
			50: [196.0, 44.0], 51: [204.0, 44.0]}, "the GPS moments were told the edges %s" % [q.moments.river_edges])
	_ok(_spot_try(Vector2(2444.0, 1156.0), Vector2(1.0, 0.0)) == [[76, 356.0, Vector2(2439.0, 1156.0), 39.0], [77, 44.0, Vector2(2439.0, 1156.0), 39.0]],
			"a spot at an open bank on both ways of the street: %s" % [_spot_try(Vector2(2444.0, 1156.0), Vector2(1.0, 0.0))])
	_ok(_spot_try(Vector2(2444.0, 516.0), Vector2(1.0, 0.0)).is_empty(), "a waypoint 2.5 m from the water was taken")
	_ok(_spot_try(Vector2(2444.0, 12.0), Vector2(1.0, 0.0)).is_empty(), "a spot in the corner the outline leaves out was taken")
	_ok(_spot_try(Vector2(594.5, 1240.0), Vector2(1.0, 0.0)).is_empty(), "a pond was taken for the river")
	# One spot per street: the nearest the water; the other way's edge and the walk in told to the moments.
	var keep: Array[Dictionary] = []
	for sp: Dictionary in q.river_spots:
		keep.append(sp.duplicate())
	var far := (keep[5] as Dictionary).duplicate()
	far["gap"] = 45.0
	far["s"] = 100.0
	q.moments.river_edges.clear()
	q._river_raw.assign([far] + keep)
	q._keep_river_spots()
	var again: Array = []
	for sp: Dictionary in q.river_spots:
		again.append([sp["e"], snappedf(sp["s"], 0.01), snappedf(sp["gap"], 0.01)])
	_ok(again.size() == 7 and [50, 196.0, 39.0] in again and not [50, 100.0, 45.0] in again, "of two spots on a street the nearer was not kept: %s" % [again])
	_ok(q.moments.river_edges.get(50) == [196.0, 44.0] and q.moments.river_edges.get(51) == [204.0, 44.0], "the GPS moments' edges: %s" % [q.moments.river_edges])
	q._keep_river_spots()
	_ok(q.river_spots.is_empty(), "the samples of the last scan were kept for the next: %d spots" % q.river_spots.size())
	# The scan's samples: the grid over the map's box less a sample's margin, the water's edge at the wet sample.
	_map.isle = Rect2(2570.0, 1000.0, 100.0, 200.0)
	q._river_todo.clear()
	q._queue_river()
	for r in q._scan_rows:
		q._scan_line(r)
	var todo := _todo_strings()
	_map.isle = Rect2()
	_ok(todo.size() == 380 and "\n".join(todo).hash() == 1577425040, "the scan's water-edge samples: %d, hash %d" % [todo.size(), "\n".join(todo).hash()])
	_ok("2452,2492,1,0" in todo and "2588,996,0,-1" in todo and "2588,1204,0,1" in todo and "596,1236,1,0" in todo and "604,1236,-1,0" in todo,
			"the scan lacks the last row's, the last column's or a pond's edge samples")


## The first RIDE frames after a harsh stop and then a pause in the air ("fly") or the ✕ and the
## next ride ("next"): [the driving penalty after each frame, ...]. The smoothed braking of the stop
## carries over (a found defect, see `_s_steps`).
func _after_stop(pause: String) -> Array:
	_rig()
	q.force_story = "none"
	var n := _find(1, _plain)
	_take()
	_board(q._ride)
	_by(q._ride["ring"], 400.0, 12.0)
	_fwd = 20.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	var out: Array = []
	if pause == "fly":
		_fly = true
		_secs(2.6)
		_fly = false
		for i in 4:
			_frame()
			out.append(q._rules.drive)
		return out
	_abort()
	_frame()
	_request(n + 1)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	var b: Vector3 = r["board"]
	_at(_v2(b))
	var k := 0
	while k < 120 and int(q.stage) != Rides.Stage.RIDE:
		_frame()
		k += 1
	for i in 4:
		out.append(q._rules.drive)
		_frame()
	return out


func _s_steps() -> void:
	_rig()
	q.force_story = "none"
	var n := _find(1, _plain)
	_ride_ready(n)
	_fwd = 0.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 * float(i + 1) / 30.0
		_frame()
	_secs(3.2)
	_ok(q.drive_toasts == 0 and hud.count == "★★★★★ 5,0", "speeding up cost braking: %s" % hud.count)
	_ride_ready(n)
	_fwd = 20.0
	_secs(0.5)
	for i in 12:
		_fwd = 20.0 - 0.5 * float(i + 1)
		_frame()
	_secs(3.2)
	_ok(q.drive_toasts == 1 and _last_toast() == "−½ ★ · hamowanie", "a 0.2 s stop at 30 m/s² did not cost: %s" % _last_toast())
	_ride_ready(n)
	_fwd = 20.0
	_secs(0.5)
	_fwd = 1.0
	_secs(3.2)
	_ok(q.drive_toasts == 0 and hud.count == "★★★★★ 5,0", "a speed lost in a frame (a teleport) was measured: %s" % hud.count)
	_ride_ready(n)
	_fwd = 12.0
	_secs(0.5)
	for i in 102:
		_yaw += 1.0
		_frame()
	_secs(3.2)
	_ok(q.drive_toasts == 1 and _last_toast() == "−½ ★ · zakręt" and hud.count == "★★★★½ 4,5", "a long spin cost %s: %s" % [hud.count, _last_toast()])
	_ride_ready(n)
	for k in 2:
		_fwd = 20.0
		_secs(0.5)
		for i in 30:
			_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
			_frame()
		_secs(1.0)
	_secs(3.3)
	_ok(q.drive_toasts == 1 and _last_toast() == "−1 ★ · hamowania" and _last_toast_en() == "−1 star · harsh braking", "two harsh brakings: %s / %s" % [_last_toast(), _last_toast_en()])
	_ride_ready(n)
	for k in 2:
		_fwd = 12.0
		_secs(0.5)
		for i in 30:
			_yaw += 1.0 / 30.0
			_frame()
		_secs(1.0)
	_secs(3.3)
	_ok(q.drive_toasts == 1 and _last_toast() == "−1 ★ · zakręty" and _last_toast_en() == "−1 star · fast corners", "two fast corners: %s / %s" % [_last_toast(), _last_toast_en()])
	# On the way to the passenger the driving is not measured at all.
	_rig()
	q.force_story = "none"
	n = _find(1, _plain)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_by(r["board"], 100.0, 12.0)
	_fwd = 20.0
	_secs(0.5)
	for i in 30:
		_fwd = 20.0 - 20.0 * float(i + 1) / 30.0
		_frame()
	_at(_v2(r["board"]))
	_board(r)
	_secs(3.2)
	_ok(q.drive_toasts == 0 and hud.count == "★★★★★ 5,0", "a harsh stop on the way to the passenger marked the ride: %s" % hud.count)
	# As the script is today, and a found defect (BACKLOG, 2026-11-13; the old script the same): the
	# smoothed braking of a harsh stop is never set back, so it marks the ride again a frame after a
	# pause and marks the next ride in its third frame. These two facts pin the frames (they are what
	# shows that the first sample after a pause or a boarding is not measured); a fix that sets
	# `_brake_s` and `_lat_s` back changes them on purpose.
	var seq := _after_stop("fly")
	_ok(seq == [0.5, 1.0, 1.0, 1.0], "after the pause in the air the penalty came %s" % [seq])
	seq = _after_stop("next")
	_ok(seq == [0.0, 0.0, 0.5, 0.5], "on the next ride the penalty came %s" % [seq])


func _t_statics() -> void:
	for h: Array in [[0.0, "0"], [0.24, "0"], [0.26, "½"], [0.5, "½"], [0.76, "1"], [1.0, "1"], [1.5, "1½"], [1.74, "1½"], [2.0, "2"], [2.6, "2½"]]:
		_ok(Rides._halves(float(h[0])) == h[1], "%s stars are written \"%s\"" % [h[0], Rides._halves(float(h[0]))])
	for c: Array in [[-5.0, "0:00"], [0.0, "0:00"], [61.0, "1:01"], [75.9, "1:15"], [600.0, "10:00"]]:
		_ok(Rides._clock_text(float(c[0])) == c[1], "%s s are written \"%s\"" % [c[0], Rides._clock_text(float(c[0]))])
	_ok(Rides._flat(Vector3(0.0, 50.0, 0.0), Vector3(30.0, 0.0, 40.0)) == 50.0, "the flat distance counts the height")
	_rig()
	q._rules.drive = 0.5
	q._rules.late = 1.0
	q._rules.police = 1.0
	q._rules.early = true
	q._rules.followed = true
	q._rules.chatted = true
	_ok(q._why() == ["jazda −½, spóźnienie −1, policja −1, przed czasem +½, za aplikacją +½, rozmowa +½",
			"driving −½, late −1, police −1, early +½, followed the app +½, good talk +½"], "the reasons for the card: %s" % [q._why()])


## A river ride boarded, for the rules about the app's waypoint.
func _river_believer() -> Dictionary:
	_rig()
	q.force_quirk = "river"
	q.force_passenger = "believer"
	_find(3, func(_r: Dictionary) -> bool: return true)
	_take()
	_board(q._ride)
	return q._ride.duplicate(true)


func _grumbles() -> int:
	return _count_said("podwozka_passenger:believer")


func _t_quirk_rules() -> void:
	# Not before Nawigacja spoke or 20 s are up.
	var r := _river_believer()
	_ok(str(q._ride["quirk"]) == "river", "no river quirk on the ride")
	var door := _v2(r["ring"])
	q._ride["q"]["w"] = door + Vector2(600.0, 0.0)
	_at(door + Vector2(240.0, 0.0), 9.0)
	_secs(0.3)
	_ok(_grumbles() == 0 and _count_said("podwozka_gps:river") == 0, "the waypoint was passed by in the ride's first second")
	q._rules.clock = 19.8
	_secs(0.1)
	_ok(_grumbles() == 0, "the waypoint was passed by before the ride's 20 s")
	_secs(0.3)
	_ok(_grumbles() == 1, "the waypoint passed by was not given up after 20 s: %d" % _grumbles())
	_arrive(r)
	# Past it at 0.45 of the way to the door, not at 0.55.
	r = _river_believer()
	door = _v2(r["ring"])
	q._ride["q"]["w"] = door + Vector2(600.0, 0.0)
	q._rules.clock = 25.0
	_at(door + Vector2(330.0, 0.0), 9.0)
	_secs(0.3)
	_ok(_grumbles() == 0, "the waypoint was given up at 0.55 of its way to the door")
	_at(door + Vector2(270.0, 0.0), 9.0)
	_secs(0.3)
	_ok(_grumbles() == 1, "the waypoint was not given up at 0.45 of its way to the door")
	_arrive(r)
	# Right beside it: Nawigacja speaks (from the car), the waypoint is not passed by.
	r = _river_believer()
	door = _v2(r["ring"])
	q._ride["q"]["w"] = door + Vector2(40.0, 0.0)
	_at(door + Vector2(18.0, 0.0), 9.0)
	_secs(0.3)
	var gi := dialogue.said.rfind("podwozka_gps:river")
	_ok(gi >= 0 and _grumbles() == 0, "a waypoint 22 m away counted as passed by")
	_ok(gi >= 0 and dialogue.anchors[gi] is Callable and ((dialogue.anchors[gi] as Callable).call() as Vector3).is_equal_approx(_car + Vector3(0.0, 3.4, 0.0)),
			"Nawigacja did not speak from 3.4 m over the car: %s" % [dialogue.anchors[gi] if gi >= 0 else null])
	_arrive(r)
	# The Frogs turn is never given a star for (a believer, driven to the corner).
	_rig()
	q.frogs = frogs
	q.force_quirk = "rechotka"
	q.force_passenger = "believer"
	var found := false
	for n in range(1, 160):
		if not _request(n):
			continue
		r = q._ride.duplicate(true)
		_take()
		_board(r)
		if _in_stage(Rides.Stage.RIDE) and q._ride.has("q") and (q._ride["q"] as Dictionary).has("w") and _near_frog(q._ride["q"]["w"]):
			found = true
			break
		_abort()
		hud.press(0)
	_ok(found, "no Frogs turn ride")
	if found:
		var toasts := _toast_n()
		var w: Vector2 = q._ride["q"]["w"]
		_at(w + Vector2(0.0, 10.0), 9.0)
		_secs(0.3)
		_ok(_toast_n() == toasts and _count_said("podwozka_passenger:followed") == 0, "the Frogs turn was a waypoint to follow: %s" % _last_toast())
		_at(Vector2(-80.0, 2480.0), 12.0)
		_secs(3.0 / 60.0)
		_ok(hud.status == "Jedź do turkusowego światła", "the dots hint went on after the Frogs turn: %s" % hud.status)
		_arrive(r)
	# The dots hint ends with the app's waypoint, driven or passed by.
	r = _river_believer()
	door = _v2(r["ring"])
	var w2: Vector2 = q._ride["q"]["w"]
	_at(w2 + Vector2(0.0, 10.0), 9.0)
	_secs(0.3)
	_at(Vector2(-80.0, 2480.0), 12.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Jedź do turkusowego światła", "the dots hint went on after the waypoint was driven: %s" % hud.status)
	_arrive(r)
	r = _river_believer()
	door = _v2(r["ring"])
	q._ride["q"]["w"] = door + Vector2(600.0, 0.0)
	q._rules.clock = 25.0
	_at(door + Vector2(270.0, 0.0), 9.0)
	_secs(0.3)
	_at(Vector2(-80.0, 2480.0), 12.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Jedź do turkusowego światła", "the dots hint went on after the waypoint was passed by: %s" % hud.status)
	_arrive(r)


func _t_detour() -> void:
	var frog: Vector2 = FROG_DOORS[1]
	# The wait at the door starts again after a car that drove past it or stood away from it.
	_rig()
	q.frogs = frogs
	q.force_passenger = "detour"
	_request(7)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	var toasts := _toast_n()
	q._rules.clock = 8.5
	_at(frog + Vector2(10.0, 0.0), 9.0)
	_secs(0.1)
	_ok(_count_said("podwozka_passenger:detour") == 1, "the passenger did not ask for a Frogs")
	_at(frog + Vector2(10.0, 0.0))
	_secs(1.5)
	_at(frog + Vector2(10.0, 0.0), 2.5)
	_frame()
	_at(frog + Vector2(10.0, 0.0))
	_secs(1.0)
	_ok(_toast_n() == toasts, "the stop counted 2.5 s in all after a car drove through")
	_secs(1.1)
	_ok(_toast_n() == toasts + 1 and _last_toast() == "+½ ★ · postój przy Frogsie", "the stop did not count in the end: %s" % _last_toast())
	_arrive(r)
	_rig()
	q.frogs = frogs
	q.force_passenger = "detour"
	_request(7)
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	toasts = _toast_n()
	q._rules.clock = 8.5
	_at(frog + Vector2(10.0, 0.0), 9.0)
	_secs(0.1)
	_at(frog + Vector2(10.0, 0.0))
	_secs(1.0)
	_at(frog + Vector2(15.0, 0.0))
	_frame()
	_at(frog + Vector2(10.0, 0.0))
	_secs(1.5)
	_ok(_toast_n() == toasts, "the stop counted 2.5 s in all after the car left the door")
	_secs(0.6)
	_ok(_toast_n() == toasts + 1, "the stop did not count in the end")
	_arrive(r)
	# Only a passenger who asked.
	_rig()
	q.frogs = frogs
	q.force_passenger = "normal"
	_find(7, func(x: Dictionary) -> bool: return not bool(x["detour"]))
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	toasts = _toast_n()
	q._rules.clock = 9.0
	_at(frog + Vector2(10.0, 0.0))
	_secs(4.0)
	_ok(_count_said("podwozka_passenger:detour") == 0 and _toast_n() == toasts, "a passenger who did not ask for a Frogs: %s" % _last_toast())
	_arrive(r)


func _t_misc() -> void:
	# The buttons: the words, a button that outranks, a tap that is not ours or not for now.
	_rig()
	q.force_story = "none"
	_at(HOME)
	_secs(0.2)
	_ok(hud.pill == "ride" and hud.pill_word == "PODWÓZKA" and hud.pill_en == "ride app", "the idle button: %s / %s" % [hud.pill_word, hud.pill_en])
	hud.pill = "tape"
	hud.pill_free = false
	_fly = true
	_secs(0.2)
	_fly = false
	_ok(hud.pill == "tape", "PODWÓZKA took down a button that is not its own: %s" % hud.pill)
	hud.pill = ""
	hud.pill_free = true
	var toasts := _toast_n()
	_tap("tape")
	_secs(0.1)
	_ok(_toast_n() == toasts and _is_idle(), "somebody else's button asked for a ride")
	var t0 := hud.tickers
	_request(5)
	_ok(hud.tickers_at_card == t0 and hud.tickers == t0 + 1, "the ticker went out %d before the card and %d after it" % [hud.tickers_at_card - t0, hud.tickers - t0])
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_by(r["board"], 24.0, 9.0)
	hud.pill_free = false
	hud.pill = "tape"
	_secs(0.1)
	_ok(hud.pill == "tape", "START KURS was put up over a button that outranks it: %s" % hud.pill)
	hud.pill_free = true
	hud.pill = ""
	_secs(0.1)
	_ok(hud.pill == "ride_start" and hud.pill_word == "START KURS" and hud.pill_en == "start the ride", "START KURS: %s / %s" % [hud.pill_word, hud.pill_en])
	_board(r)
	toasts = _toast_n()
	_tap("ride")
	_secs(0.1)
	_ok(_toast_n() == toasts, "the ride button during a ride asked for another")
	# Bumps on the way to the passenger cost nothing.
	_abort()
	q.finish()
	_request(5)
	r = q._ride.duplicate(true)
	_take()
	_bump(8.0)
	_secs(3.5)
	_ok(q.drive_toasts == 0, "a bump on the way to the passenger counted")
	_board(r)
	_secs(0.2)
	_ok(hud.count == "★★★★★ 5,0", "the ride began with %s after a bump on the way to the passenger" % hud.count)
	# 'In the ring' from 40 m, not from 80.
	_by(r["ring"], 60.0, 9.0)
	_secs(3.0 / 60.0)
	_ok(hud.status == "Jedź do turkusowego światła", "the hint at 60 m: %s" % hud.status)
	# The director ending the ride takes the app's route down.
	q.finish()
	_ok(hud.route.is_empty(), "the route stayed on the minimap after the ride was ended")
	_rig()
	q.force_story = "none"
	_request(5)
	r = q._ride.duplicate(true)
	_take()
	q.finish()
	_ok(hud.route.is_empty(), "the route stayed on the minimap after the pickup was ended")
	# The passenger who gets out: the bubbles are put out.
	var n := _find(1, _plain)
	r = _ride_ready(n)
	var hushed := bubbles.hushed.size()
	q._rules.clock = 3.0 * _eta(r)
	_secs(0.1)
	_ok(bubbles.hushed.size() > hushed and bubbles.hushed.back() == car, "the bubbles stayed up after the passenger got out")
	_abort()
	# What a drive toast carries from one to the next.
	r = _ride_ready(n)
	_bump(5.0)
	_secs(3.2)
	_ok(q.drive_toasts == 1 and _last_toast() == "−½ ★ · stłuczka", "the first bump: %s" % _last_toast())
	_bump(5.0)
	_secs(3.2)
	_ok(q.drive_toasts == 2 and _last_toast() == "−½ ★ · stłuczka" and _last_toast_en() == "−½ star · bump", "the second bump's toast: %s / %s" % [_last_toast(), _last_toast_en()])
	r = _ride_ready(n)
	_bump(5.0)
	_secs(2.1)
	_bump(5.0)
	_secs(2.8)
	_ok(q.drive_toasts == 0, "the toast of two bumps came less than 3 s after the second")
	_secs(0.3)
	_ok(q.drive_toasts == 1, "the toast of two bumps did not come")
	r = _ride_ready(n)
	_bump(5.0)
	_secs(0.5)
	_arrive(r)
	_secs(4.0)
	q.finish()
	var dt0: int = q.drive_toasts
	_request(n + 1)
	r = q._ride.duplicate(true)
	_take()
	_board(r)
	_secs(4.0)
	_ok(q.drive_toasts == dt0 and hud.count == "★★★★★ 5,0", "the last ride's bump came back on the next: %s" % hud.count)
	# The passenger hops 0.12 m.
	_rig()
	q.force_story = "none"
	_request(5)
	_take()
	var hi := 0.0
	for i in 120:
		_frame()
		hi = maxf(hi, q._rider_mesh.position.y)
	_ok(hi > 0.115 and hi <= 0.1201, "the passenger hops %.3f m" % hi)
	# A hurry passenger pays as the others do; a four-star ride has the story passenger's last word.
	_pay_case(n, 5.0, {"name": "5 stars, a hurry passenger", "passenger": "hurry"})
	var st: Dictionary = _stories[0]
	var outro: Array = st["answers"][0]["outro"]
	var rs := _story_ride(str(st["id"]), {"start_stars": 3.5})
	_until_ride(func() -> bool: return q._asking, 40.0)
	hud.press(0)
	_arrive(rs)
	_secs(2.7)
	var final: float = (wallet.keep["podwozka_ratings"] as Array)[-1]
	_ok(final >= 4.0 and final < 5.0, "the ride ended with %s stars" % final)
	_ok(hud.body.begins_with("%s: %s\n" % [rs["name"], outro[0]]), "a four-star ride had no last word: %s" % hud.body)


func _lane_offer(yaw: float, at: Vector2) -> int:
	_rig()
	q.force_story = "none"
	_at(at, 0.0, yaw)
	q._offers = 0
	q._offer_in = 0.02
	_until(_on_offer, 0.3)
	var pe := int(q._ride.get("p_e", -1)) if _on_offer() else -1
	hud.press(1)
	return pe


func _route_text(route: PackedVector2Array) -> String:
	var out := PackedStringArray()
	for v in route:
		out.append("%d,%d" % [roundi(v.x), roundi(v.y)])
	return " ".join(out)


## The app's recalculated line for a car on the street at `at` facing `yaw`.
func _reroute_line(n: int, at: Vector2, yaw: float) -> String:
	_rig()
	q.force_story = "none"
	q.force_quirk = "reroute"
	_request(n)
	var r: Dictionary = q._ride.duplicate(true)
	_take()
	_board(r)
	_at(at, 9.0, yaw)
	q._rules.clock = 0.5 * float(q._rules.eta)
	_secs(0.1)
	return _route_text(hud.route)


func _t_lanes() -> void:
	_ok(_lane_offer(EAST, Vector2(1000.0, 1195.0)) == 90 and _lane_offer(-EAST, Vector2(1000.0, 1195.0)) == 83,
			"a request from a car facing east/west 5 m north of the road: the pin lanes %d / %d" % [_lane_offer(EAST, Vector2(1000.0, 1195.0)), _lane_offer(-EAST, Vector2(1000.0, 1195.0))])
	var lines := {
		[1, -EAST]: "1000,1200 800,1200 1000,1200 1200,1200 1200,1200 1200,1000 1200,800 1200,1000 1200,1200 1200,1200",
		[1, EAST]: "1000,1200 1200,1200 1000,1200 800,1200 800,1200 1000,1200 1200,1200 1200,1200",
		[3, -EAST]: "1000,1200 800,1200 1000,1200 1200,1200 1200,1200 1200,1400 1200,1600 1200,1800 1200,2000 1320,1989",
		[3, EAST]: "1000,1200 1200,1200 1000,1200 800,1200 800,1200 1000,1200 1200,1200 1200,1400 1200,1600 1200,1800 1200,2000 1320,1989",
		[4, -EAST]: "1000,1200 800,1200 1000,1200 1200,1200 1200,1200 1200,1000 1200,800 1189,550",
		[4, EAST]: "1000,1200 1200,1200 1000,1200 800,1200 800,1200 800,1000 800,800 1000,800 1200,800 1189,550",
		[6, -EAST]: "1000,1200 800,1200 1000,1200 1200,1200 1200,1200 1400,1200 1600,1200 1600,1400 1600,1600 1600,1800 1600,2000 1600,2200 1600,2400 1720,2389",
		[6, EAST]: "1000,1200 1200,1200 1000,1200 800,1200 800,1200 1000,1200 1200,1200 1400,1200 1600,1200 1600,1400 1600,1600 1600,1800 1600,2000 1600,2200 1600,2400 1720,2389"}
	for k: Array in lines:
		var got := _reroute_line(int(k[0]), Vector2(1000.0, 1195.0), float(k[1]))
		_ok(got == lines[k], "ride %d recalculated facing %s: %s" % [k[0], "east" if float(k[1]) == EAST else "west", got])
