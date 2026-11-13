extends SceneTree
## Beta values (2026-11-04, docs/design/beta-values.md): the delivery's way-finding and clock,
## headless, from the committed map (map/centrum.json: the lane graph, the kebab stands placed as
## jobs.gd places them, the addresses):
##   1. the minimap route (route_line.gd) for 60 kebab orders from the stands, as jobs.gd picks them:
##      it starts on the car's lane, ends at the door's ring, follows the road (each step under 250 m,
##      its length within 15 % + 40 m of the order's road length), and from the wrong way (the
##      reverse lane) it still gets there;
##   2. the walk is cheap (the median under 1 ms; it runs once a second);
##   3. the heat's words (jobs.gd heat_hint): the seconds to warm and to cold from the decay rate,
##      each one line on the status card (40 characters at most);
##   4. NASTĘPNE (point_next_stand): from a delivery's door it picks the stand nearest by road,
##      points at it (has_target, stop_spot) and draws its route; the hud's route is cleared only
##      by its owner.
## Prints "check_delivery: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_delivery.gd [-- --verbose]

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Jobs := preload("res://scripts/jobs.gd")
const RouteLine := preload("res://scripts/route_line.gd")
const Fakes := preload("res://tools/fakes.gd")

var problems: Array[String] = []
var verbose := false


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -INF
	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_delivery: FAIL (no map/centrum.json)")
		quit(1)
		return
	var map := FakeMap.new()
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	var world := Node3D.new()
	root.add_child(world)
	var jobs: Jobs = Jobs.new()
	jobs.graph = graph
	jobs.map = map
	for p: Dictionary in data.get("pois", []):
		match str(p["k"]):
			"kebab":
				jobs.call("_add_stand", p, null, world)
			"address":
				var door: Array = p["door"]
				jobs.get("_addresses").append({"name": p["name"], "door": Vector2(door[0], door[1]), "at": Vector2(p["x"], p["z"]),
						"office": p.has("o"), "d": String(p.get("d", ""))})
	var stands: Array = jobs.get("_stands")
	_expect(stands.size() >= 40, "%d kebab stands placed (want 42)" % stands.size())
	var summary := {}
	summary["route"] = _check_routes(jobs, graph, stands)
	summary["heat"] = _check_heat(jobs)
	summary["next"] = _check_next(jobs, graph, stands)
	jobs.free()
	if problems.is_empty():
		print("check_delivery: OK (%s)" % ", ".join(summary.keys().map(func(k: String) -> String: return "%s %s" % [k, summary[k]])))
		quit(0)
	else:
		for p in problems:
			print("check_delivery: %s" % p)
		print("check_delivery: FAIL (%d problems)" % problems.size())
		quit(1)


## 1-2. The route of 60 orders, and from the reverse lane.
func _check_routes(jobs: Jobs, graph: LaneGraph, stands: Array) -> String:
	var rng := RandomNumberGenerator.new()
	var orders := 0
	var reversed := 0
	var worst := 0.0
	var times: Array[float] = []
	for n in 60:
		var i := (n * 7) % stands.size()
		var s: Dictionary = stands[i]
		rng.seed = n * 7907 + i * 131 + 3
		var from := Vector2(s["ring"].x, s["ring"].z)
		var pick: Dictionary = jobs.call("_pick_address", s["edge"], s["s"], from, Jobs.ORDER_MIN, Jobs.ORDER_MAX, rng,
				func(_a: Dictionary) -> bool: return true)
		if pick.is_empty() or not bool(pick["reached"]):
			continue
		orders += 1
		var ring: Vector3 = pick["ring"]
		var line := RouteLine.new(graph)
		line.to_lane(int(pick["edge"]), float(pick["s"]), Vector2(ring.x, ring.z))
		var out := PackedVector2Array()
		var t0 := Time.get_ticks_usec()
		line.walk(int(s["edge"]), float(s["s"]), out)
		times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		out.append(Vector2(ring.x, ring.z))
		var length := 0.0
		var step := 0.0
		for k in out.size() - 1:
			var d := out[k].distance_to(out[k + 1])
			length += d
			step = maxf(step, d)
		var road: float = pick["road"]
		var start: Vector2 = graph.point_at(int(s["edge"]), float(s["s"]))
		_expect(out[0].distance_to(start) < 0.5, "order %d: the route starts %.1f m from the stand's lane" % [n, out[0].distance_to(start)])
		# (A long straight edge has its points far apart: the longest on the map is under 250 m.)
		_expect(step < 250.0, "order %d (%s): a %.0f m jump in the route" % [n, pick["name"], step])
		_expect(absf(length - road) < road * 0.15 + 40.0, "order %d (%s): route %.0f m, road %.0f m" % [n, pick["name"], length, road])
		worst = maxf(worst, absf(length - road) / road)
		# The wrong way: from the reverse lane it turns round somewhere and still gets there.
		var rev: int = graph.e_reverse[int(s["edge"])]
		if rev >= 0:
			var back := PackedVector2Array()
			line.walk(rev, graph.e_len[rev] - float(s["s"]), back)
			var end_at: Vector2 = graph.point_at(int(pick["edge"]), float(pick["s"]))
			_expect(not back.is_empty() and back[back.size() - 1].distance_to(end_at) < 1.0,
					"order %d: from the reverse lane the route ends %.0f m from the door's lane" % [n,
					back[back.size() - 1].distance_to(end_at) if not back.is_empty() else INF])
			reversed += 1
		if verbose:
			print("order %d: stand %d -> %s, road %.0f m, route %.0f m, %d points" % [n, i, pick["name"], road, length, out.size()])
	_expect(orders >= 40, "only %d orders reached by road" % orders)
	times.sort()
	var median: float = times[times.size() / 2] if not times.is_empty() else 0.0
	_expect(median < 1.0, "the route's walk takes %.2f ms (median)" % median)
	return "%d orders (%d from the reverse lane), worst %.0f %% off the road length, walk %.2f ms" % [orders, reversed, worst * 100.0, median]


## 3. The heat's words.
func _check_heat(jobs: Jobs) -> String:
	jobs.set("_order", {"fair": 100.0})
	jobs.set("_heat", 1.0)
	var hot: Array = jobs.heat_hint()
	_expect(String(hot[0]).begins_with("Gorący jeszcze 50 s"), "heat 1.0, fair 100 s: '%s' (want 50 s hot)" % hot[0])
	jobs.set("_heat", 0.55)
	var warm: Array = jobs.heat_hint()
	_expect(String(warm[0]).begins_with("Ciepły jeszcze 25 s"), "heat 0.55: '%s' (want 25 s warm)" % warm[0])
	jobs.set("_heat", 0.2)
	var cold: Array = jobs.heat_hint()
	_expect(String(cold[0]).begins_with("Zimny"), "heat 0.2: '%s'" % cold[0])
	for l: Array in [hot, warm, cold]:
		# One line on the status card (the old hint, "Jedź do pomarańczowego światła", was 30).
		_expect(String(l[0]).length() <= 40 and String(l[1]).length() <= 40, "a heat line over 40 characters: %s" % [l])
	return "hot 50 s, warm 25 s, cold"


## 4. NASTĘPNE from a door: the nearest stand by road, pointed at, routed; the owner rule.
func _check_next(jobs: Jobs, graph: LaneGraph, stands: Array) -> String:
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var car := CharacterBody3D.new()
	root.add_child(car)
	jobs.hud = hud
	jobs.car = car
	jobs.set("_route", RouteLine.new(graph))
	# A delivery's door: the first address 300-700 m from the first stand (Marszałkowska ×
	# Świętokrzyska) with a lane by it.
	var hit := []
	for a: Dictionary in jobs.get("_addresses"):
		var d: float = (a["door"] as Vector2).distance_to(Jobs.FIRST_STAND)
		if d > 300.0 and d < 700.0:
			hit = graph.snap(a["door"], 30.0, Vector2.ZERO, true)
			if not hit.is_empty():
				break
	_expect(not hit.is_empty(), "no lane by the test door")
	if hit.is_empty():
		return "-"
	var at := graph.point_at(int(hit[0]), float(hit[2]))
	car.global_position = Vector3(at.x, 0.0, at.y)
	var dir := graph.point_at(int(hit[0]), minf(float(hit[2]) + 1.0, graph.e_len[int(hit[0])])) - at
	car.rotation.y = atan2(-dir.x, -dir.y)
	var i := jobs.point_next_stand()
	_expect(i >= 0, "NASTĘPNE picked no stand")
	if i < 0:
		return "-"
	# The nearest by road, checked against every stand.
	var dist := graph.distances_from(graph.e_b[int(hit[0])], false)
	var best := INF
	for s: Dictionary in stands:
		best = minf(best, graph.trip(dist, int(hit[0]), float(hit[2]), int(s["edge"]), float(s["s"])))
	var mine: float = graph.trip(dist, int(hit[0]), float(hit[2]), int(stands[i]["edge"]), float(stands[i]["s"]))
	_expect(mine <= best + 0.5, "NASTĘPNE picked stand %d at %.0f m, the nearest is %.0f m" % [i, mine, best])
	_expect(jobs.pointing() and jobs.target_position() == stands[i]["ring"] and jobs.stop_spot() == stands[i]["ring"],
			"the pointer: pointing %s, target %s, stand ring %s" % [jobs.pointing(), jobs.target_position(), stands[i]["ring"]])
	_expect(hud.route.size() >= 2 and hud.route_owner == "jobs", "NASTĘPNE drew no route (%d points, owner '%s')" % [hud.route.size(), hud.route_owner])
	var ring: Vector3 = stands[i]["ring"]
	_expect(hud.route.size() >= 2 and hud.route[hud.route.size() - 1].distance_to(Vector2(ring.x, ring.z)) < 0.5, "the route doesn't end at the stand's ring")
	_expect(hud.toasts.size() == 1 and String(hud.toasts[0]).begins_with("Następne zamówienie"), "the toast: %s" % [hud.toasts])
	# Another activity drew its own route since: the pointer's end leaves it alone.
	hud.set_minimap_route(PackedVector2Array([Vector2.ZERO, Vector2.ONE]), Color.WHITE, "rides")
	jobs.call("_route_off", true)
	_expect(hud.route.size() == 2 and hud.route_owner == "rides", "the jobs route's end wiped the ride's route")
	return "stand %d at %.0f m by road" % [i, mine]
