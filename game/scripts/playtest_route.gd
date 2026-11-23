extends RefCounted
## The road route an Autopilot playtest drives by (2026-11-23, tools/autopilot/README.md): the
## harness that steered straight at the arrow pinned the car on the Palace forecourt (PT-60) and
## never finished a job or a race. This gives it what a player has: the way by road to the arrow,
## on the lane graph (route_line.gd, the minimap's dotted line), with a point a few metres ahead on
## a lane to steer at and a speed for the next bend.
##
## Nothing in the game calls it. The Autopilot add-on calls the static `get_*` functions over its
## `rc` (`game.ret("res://scripts/playtest_route.gd", "get_drive_state")`): one call a tick, plain
## numbers and strings back (Godot metres, x and z), and the reads never change the game. The pure
## parts (`steer`, `road_place`) are checked on the real map by check_playtest_route.gd.

const RouteLine := preload("res://scripts/route_line.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## The goal is searched again once it has moved this far (m): a rival's pin, the next checkpoint.
const REGOAL_M := 20.0
## A goal further than this from every road (m) gets no route: the straight line to it.
const SNAP_M := 60.0
## The aim is this many seconds ahead along the route, between AIM_MIN and AIM_MAX m.
const AIM_TIME := 1.0
const AIM_MIN := 7.0
const AIM_MAX := 22.0
## The aim's lane is taken only from an edge whose centreline is this close to the route's (m).
const LANE_SNAP_M := 1.5
## Off a lane this close to its edge's ends (m) is in the junction (road_place).
const JUNCTION_M := 10.0
## The bend is read this far ahead (m); the speeds for a sharp one, a soft one, and the last metres.
const BEND_AHEAD := 28.0
const SHARP_KMH := 20.0
const SOFT_KMH := 32.0
const ARRIVE_KMH := 25.0
const ARRIVE_SLOW_M := 35.0

static var _line: RouteLine
static var _graph: LaneGraph
static var _goal := Vector2.INF


## The arrow's goal now: {"source", "x", "z"} or {} when there is none. The map registry's active
## target first (rescues, jobs, races, tours, quest pins), then the main line's target (the first
## minutes' guide arrow: the first kebab stand), then the main line's next step.
static func get_goal() -> Dictionary:
	var m := _main()
	if m == null:
		return {}
	var at := Vector2.INF
	var source := ""
	var hud: Node = m.get("hud")
	if hud != null:
		at = hud.markers.target()
		source = "target"
	if at == Vector2.INF:
		var mt: Variant = m.get("_main_target")
		if mt is Vector2 and mt != Vector2.INF:
			at = mt
			source = "main_target"
	if at == Vector2.INF:
		var step: Variant = m.get("main_step")
		if step is Dictionary and (step as Dictionary).get("at", Vector2.INF) is Vector2:
			var sa: Vector2 = step.get("at", Vector2.INF)
			if sa != Vector2.INF:
				at = sa
				source = "main_line"
	if at == Vector2.INF:
		return {}
	return {"source": source, "x": snappedf(at.x, 0.1), "z": snappedf(at.y, 0.1)}


## One tick of driving state for the harness. `x`, `z`: a goal of the harness's own (NAN: the
## arrow's, get_goal); `kerb`: steer on the kerb-side lane (true) or the inner one; `cruise_kmh`:
## the speed on a straight. Keys: the car (`x`, `z`, `y`, `heading_deg`, `speed_kmh`, `unsticks`,
## `flying`, `below_ground_m`), where it is on the road (`street`, `place`, `side_m`, `lane_gap_m`,
## road_place), the goal (`goal_source`, `goal_x`, `goal_z`, `goal_m` straight), and the route
## (`route` true when on the lane graph, `left_m` by road, `aim_x`, `aim_z`, `bearing_deg` (+ right
## of the car's heading), `bend_deg`, `want_kmh`). {"error": ...} when the game isn't up.
static func get_drive_state(x := NAN, z := NAN, kerb := false, cruise_kmh := 50.0) -> Dictionary:
	var m := _main()
	if m == null:
		return {"error": "no /root/Main"}
	var car: Node3D = m.get("car")
	var graph: LaneGraph = m.get("graph")
	if car == null or graph == null:
		return {"error": "the car or the lane graph is not built yet"}
	var at := Vector2(car.global_position.x, car.global_position.z)
	var fwd := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var v: Variant = car.get("vel")
	var vel: Vector3 = v if v is Vector3 else Vector3.ZERO
	var speed := Vector2(vel.x, vel.z).length()
	var un: Variant = car.get("unsticks")
	var out := {
		"x": snappedf(at.x, 0.1), "z": snappedf(at.y, 0.1), "y": snappedf(car.global_position.y, 0.01),
		"heading_deg": snappedf(rad_to_deg(car.rotation.y), 0.1), "speed_kmh": snappedf(speed * 3.6, 0.1),
		"unsticks": int(un) if un is int else -1, "flying": m.get("flying") == true,
	}
	var map: Node = m.get("map")
	if map != null and map.has_method("drive_height"):
		out["below_ground_m"] = snappedf(float(map.drive_height(at.x, at.y, car.global_position.y)) - car.global_position.y, 0.01)
	out.merge(road_place(graph, at))
	var goal := Vector2(x, z)
	var source := "own"
	if is_nan(x) or is_nan(z):
		var g := get_goal()
		if g.is_empty():
			out["goal_source"] = ""
			return out
		goal = Vector2(float(g["x"]), float(g["z"]))
		source = str(g["source"])
	out["goal_source"] = source
	out["goal_x"] = snappedf(goal.x, 0.1)
	out["goal_z"] = snappedf(goal.y, 0.1)
	out["goal_m"] = snappedf(at.distance_to(goal), 0.1)
	var path := _route(graph, goal, at, fwd)
	out.merge(steer(graph, path, at, fwd, speed, kerb, cruise_kmh, goal))
	return out


## Forget the route (a new row, a teleport).
static func clear_route() -> void:
	_line = null
	_goal = Vector2.INF


## The route from the car to `goal` as a polyline (the lane graph's centrelines, then the goal);
## empty when no road is near the goal or the car.
static func _route(graph: LaneGraph, goal: Vector2, at: Vector2, fwd: Vector2) -> PackedVector2Array:
	if _line == null or _graph != graph or _goal == Vector2.INF or goal.distance_to(_goal) > REGOAL_M:
		_graph = graph
		_goal = goal
		_line = RouteLine.new(graph)
		var hit := graph.snap(goal, SNAP_M, Vector2.ZERO, true)
		if hit.is_empty():
			_line = null
			return PackedVector2Array()
		_line.to_lane(int(hit[0]), float(hit[2]), goal)
	if _line == null:
		return PackedVector2Array()
	# Walked again from the car on every call (a snap and a greedy walk, no search): the harness
	# asks a few times a second, and a stale line would steer at a point already behind.
	_line.update(at, fwd, RouteLine.REFRESH)
	return _line.points


## Where on the road the point is: `street` (the nearest lane's street name), `place` ("lane":
## inside a lane, "lane_edge": within a metre past it, "kerb": up to 3 m past it, "off": further
## or no road within 15 m), `side_m` (+ right of the nearest edge's centreline, its direction of
## travel) and `lane_gap_m` (from the nearest lane's middle).
static func road_place(graph: LaneGraph, at: Vector2) -> Dictionary:
	var hit := graph.snap(at, 15.0)
	if hit.is_empty():
		return {"street": "", "place": "off", "side_m": 0.0, "lane_gap_m": -1.0}
	var e := int(hit[0])
	var s := float(hit[2])
	var centre := graph.point_at(e, s)
	var right := _right(graph.direction(e, s))
	var lane := graph.point_at(e, s, graph.lane_offset(e, int(hit[1])))
	var gap := lane.distance_to(at)
	var half := graph.e_lw[e] * 0.5
	var place := "lane" if gap <= half else ("lane_edge" if gap <= half + 1.0 else ("kerb" if gap <= half + 3.0 else "off"))
	if gap > half + 1.0 and (s < graph.e_s0[e] + JUNCTION_M or s > graph.e_s1[e] - JUNCTION_M):
		place = "junction"
	return {"street": graph.e_name[e], "place": place, "side_m": snappedf((at - centre).dot(right), 0.01),
			"lane_gap_m": snappedf(gap, 0.01)}


## The pure step: the aim on a lane AIM_TIME s ahead along `path`, the bearing to it from the car's
## heading (degrees, + right), the bend ahead and the speed for it. With no path, straight at `goal`.
static func steer(graph: LaneGraph, path: PackedVector2Array, at: Vector2, fwd: Vector2, speed: float,
		kerb: bool, cruise_kmh: float, goal: Vector2) -> Dictionary:
	if path.size() < 2:
		var to := goal - at
		return {"route": false, "left_m": snappedf(to.length(), 0.1), "aim_x": snappedf(goal.x, 0.1),
				"aim_z": snappedf(goal.y, 0.1), "bearing_deg": snappedf(rad_to_deg(fwd.angle_to(to)), 0.1),
				"bend_deg": 0.0, "want_kmh": minf(cruise_kmh, ARRIVE_KMH) if to.length() < ARRIVE_SLOW_M else cruise_kmh}
	# The car's place along the path: the nearest point of the first few segments (the line
	# starts at the car's lane point and is walked again every few tenths of a second).
	var best_i := 0
	var best_t := 0.0
	var best_d := INF
	for i in mini(path.size() - 1, 12):
		var a := path[i]
		var ab := path[i + 1] - a
		var l2 := ab.length_squared()
		var t := clampf((at - a).dot(ab) / l2, 0.0, 1.0) if l2 > 0.0001 else 0.0
		var d := at.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best_i = i
			best_t = t
	var total := _length_from(path, best_i, best_t)
	var look := clampf(speed * AIM_TIME, AIM_MIN, AIM_MAX)
	var aim_c := _along(path, best_i, best_t, look)
	var dir_here := (path[best_i + 1] - path[best_i]).normalized()
	var dir_aim := _dir_at(path, best_i, best_t, look)
	# On a lane of the route's own edge: the snap must land on the centreline the route runs on
	# (within LANE_SNAP_M of it, the same way); at a junction (a curve across, a roundabout) it
	# would find a crossing street's lane, so there the aim stays on the route's line.
	var aim := aim_c
	if look >= total - 2.0:
		aim = path[path.size() - 1]
	else:
		var hit := graph.snap(aim_c, 8.0, dir_aim)
		if not hit.is_empty():
			var e := int(hit[0])
			var s := float(hit[2])
			if graph.point_at(e, s).distance_to(aim_c) < LANE_SNAP_M and absf(graph.direction(e, s).angle_to(dir_aim)) < deg_to_rad(20.0):
				aim = graph.point_at(e, s, graph.lane_offset(e, lane_for(graph, e, kerb)))
	var bend := 0.0
	var step := 4.0
	var ahead := step
	while ahead <= minf(BEND_AHEAD, total):
		bend = maxf(bend, absf(rad_to_deg(dir_here.angle_to(_dir_at(path, best_i, best_t, ahead)))))
		ahead += step
	var want := cruise_kmh
	if bend > 55.0:
		want = minf(want, SHARP_KMH)
	elif bend > 25.0:
		want = minf(want, SOFT_KMH)
	if total < ARRIVE_SLOW_M:
		want = minf(want, ARRIVE_KMH)
	return {"route": true, "left_m": snappedf(total, 0.1), "aim_x": snappedf(aim.x, 0.1), "aim_z": snappedf(aim.y, 0.1),
			"bearing_deg": snappedf(rad_to_deg(fwd.angle_to(aim - at)), 0.1), "bend_deg": snappedf(bend, 0.1),
			"want_kmh": want, "off_route_m": snappedf(best_d, 0.1)}


## The lane to drive in on edge e: the kerb-side one (`kerb`), else the one nearest the edge's
## centreline (the route's line: far from it, the route walked again from the car can take the
## lane of another way at a junction or on a roundabout, and send the car round again).
static func lane_for(graph: LaneGraph, e: int, kerb: bool) -> int:
	var n := int(graph.e_lanes[e])
	if kerb:
		return n - 1
	var best := 0
	for k in n:
		if absf(graph.lane_offset(e, k)) < absf(graph.lane_offset(e, best)):
			best = k
	return best


## Right of a direction on the ground (x right, -z ahead: (0, -1) has (1, 0) on its right).
static func _right(d: Vector2) -> Vector2:
	return Vector2(-d.y, d.x)


static func _length_from(path: PackedVector2Array, i: int, t: float) -> float:
	var total := path[i].distance_to(path[i + 1]) * (1.0 - t)
	for k in range(i + 1, path.size() - 1):
		total += path[k].distance_to(path[k + 1])
	return total


## The point `dist` m along the path from segment i at t (the path's end at most).
static func _along(path: PackedVector2Array, i: int, t: float, dist: float) -> Vector2:
	var p := path[i].lerp(path[i + 1], t)
	var left := dist
	var k := i
	while k < path.size() - 1:
		var b := path[k + 1]
		var l := p.distance_to(b)
		if l >= left:
			return p + (b - p).normalized() * left if l > 0.0001 else b
		left -= l
		p = b
		k += 1
	return path[path.size() - 1]


## The path's direction `dist` m along from segment i at t.
static func _dir_at(path: PackedVector2Array, i: int, t: float, dist: float) -> Vector2:
	var p := path[i].lerp(path[i + 1], t)
	var left := dist
	var k := i
	while k < path.size() - 1:
		var l := p.distance_to(path[k + 1])
		if l >= left or k == path.size() - 2:
			var d := path[k + 1] - path[k]
			return d.normalized() if d.length() > 0.0001 else Vector2.ZERO
		left -= l
		p = path[k + 1]
		k += 1
	return (path[path.size() - 1] - path[path.size() - 2]).normalized()


static func _main() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("Main")
