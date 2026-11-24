extends SceneTree
## The Autopilot playtest's road route (scripts/playtest_route.gd, 2026-11-23) on the committed
## map (map/centrum.json), headless, no game scene:
##   1. road_place: a lane's middle is "lane" on its street; 1 m past the lane's edge is
##      "lane_edge"; 20 m off every road is "off";
##   2. a simple car (no collisions: turn rate limited by a 6 m radius, the speed eased to
##      `want_kmh`) that only steers at `aim` from steer() reaches three goals by road (about 400,
##      900 and 1600 m away) from the PT-60 spot on the Palace forecourt, off the roads, with
##      the car 12° off its first lane, and spends at least 90 % of the drive in a lane or at
##      its edge;
##   3. with no route (no path), steer() points straight at the goal and slows near it; a goal
##      25 m away whose way by road is a loop round the block (the kebab stand on Marszałkowska,
##      just passed) is pulled into straight, not driven round;
##   4. get_goal and get_drive_state on a stand-in /root/Main (the fields main.gd has): the HUD's
##      active target first, then the main line's target, and one tick's keys, with the route.
## Prints "check_playtest_route: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_playtest_route.gd

const PlaytestRoute := preload("res://scripts/playtest_route.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Fakes := preload("res://tools/fakes.gd")

## The PT-60 spot (run 20261123-170309): the Palace forecourt, the car facing ~78°.
const PT60 := Vector2(-941.2, 93.6)
const PT60_YAW := 78.0
const DT := 0.1
const MIN_RADIUS := 6.0

var problems: Array[String] = []
var digest: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary or not (data as Dictionary).has("graph"):
		print("check_playtest_route: no map/centrum.json graph")
		quit(1)
		return
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	_place(graph)
	_drives(graph)
	_no_route(graph)
	_on_main(graph, map)
	map.queue_free()
	if problems.is_empty():
		print("check_playtest_route: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_playtest_route: %d problems" % problems.size())
		quit(1)


## 1. road_place on a lane, at its edge, far off.
func _place(graph: LaneGraph) -> void:
	var e := -1
	for i in graph.e_len.size():
		if graph.e_len[i] > 80.0 and graph.e_name[i] != "" and graph.e_cf[i] == 0 and graph.e_tn[i] < 0 and graph.e_bridge[i] == 0:
			e = i
			break
	if e < 0:
		problems.append("place: no plain named edge over 80 m")
		return
	var s := graph.e_len[e] * 0.5
	var mid := graph.point_at(e, s, graph.lane_offset(e, 0))
	var p := PlaytestRoute.road_place(graph, mid)
	if p["place"] != "lane" or p["street"] != graph.e_name[e]:
		problems.append("place: a lane's middle on %s reads %s" % [graph.e_name[e], p])
	var right := Vector2(-graph.direction(e, s).y, graph.direction(e, s).x)
	var k_out := graph.e_lanes[e] - 1
	var edge := graph.point_at(e, s, graph.lane_offset(e, k_out) + graph.e_lw[e] * 0.5 + 0.6)
	var pe := PlaytestRoute.road_place(graph, edge)
	if not str(pe["place"]) in ["lane_edge", "lane"]:
		problems.append("place: 0.6 m past the kerb lane on %s reads %s" % [graph.e_name[e], pe])
	var far := mid + right * 400.0
	while not graph.snap(far, 20.0).is_empty():
		far += right * 37.0
	var pf := PlaytestRoute.road_place(graph, far)
	if pf["place"] != "off":
		problems.append("place: far from every road reads %s" % pf)
	digest.append("place on %s" % graph.e_name[e])


## 2. Three drives from the PT-60 spot.
func _drives(graph: LaneGraph) -> void:
	var start := graph.nearest_node(PT60)
	var dist := graph.distances_from(start, false)
	for want: float in [400.0, 900.0, 1600.0]:
		var goal_n := -1
		for n in dist.size():
			if dist[n] >= want and dist[n] < want + 60.0 and graph.node_scc[n] != 0:
				goal_n = n
				break
		if goal_n < 0:
			problems.append("drive %d m: no node that far" % want)
			continue
		_drive(graph, graph.node_pos[goal_n], want)


func _drive(graph: LaneGraph, goal: Vector2, want: float) -> void:
	PlaytestRoute.clear_route()
	var at := PT60
	var yaw := deg_to_rad(PT60_YAW)
	var speed := 0.0
	var t := 0.0
	var in_lane := 0
	var ticks := 0
	var worst := 0.0
	var limit := want / 4.0 + 60.0
	while t < limit:
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		var path := PlaytestRoute._route(graph, goal, at, fwd)
		var st := PlaytestRoute.steer(graph, path, at, fwd, speed, false, 50.0, goal)
		if at.distance_to(goal) < 12.0:
			break
		var bearing := deg_to_rad(float(st["bearing_deg"]))
		# The car's own yaw: + turns left (car.gd), so a bearing to the right lowers it.
		var max_rate := maxf(speed, 3.0) / MIN_RADIUS
		yaw -= clampf(bearing * 2.5, -max_rate, max_rate) * DT
		var target := float(st["want_kmh"]) / 3.6
		speed = move_toward(speed, target, (3.0 if target > speed else 6.0) * DT)
		at += Vector2(-sin(yaw), -cos(yaw)) * speed * DT
		t += DT
		if t > 6.0:
			ticks += 1
			var pl := PlaytestRoute.road_place(graph, at)
			if str(pl["place"]) in ["lane", "lane_edge", "junction"]:
				in_lane += 1
			worst = maxf(worst, float(pl["lane_gap_m"]))
	var left := at.distance_to(goal)
	var share := float(in_lane) / maxf(1.0, float(ticks))
	if left >= 12.0:
		problems.append("drive %d m: %.0f m short of the goal after %.0f s" % [want, left, t])
	if share < 0.9:
		problems.append("drive %d m: only %.0f %% in a lane (worst %.1f m off a lane's middle)" % [want, share * 100.0, worst])
	digest.append("%d m in %.0f s, %.0f %% in lane" % [want, t, share * 100.0])


## 3. No path: straight at the goal, slower within ARRIVE_SLOW_M.
func _no_route(graph: LaneGraph) -> void:
	var at := Vector2(0.0, 0.0)
	var fwd := Vector2(0.0, -1.0)
	var r := PlaytestRoute.steer(graph, PackedVector2Array(), at, fwd, 10.0, false, 50.0, Vector2(100.0, 0.0))
	if bool(r["route"]) or absf(float(r["bearing_deg"]) - 90.0) > 0.5:
		problems.append("no route: a goal due right reads %s" % r)
	var stand := Vector2(-1073.7, -217.9)
	var past := Vector2(-1074.0, -243.0)
	var hit := graph.snap(past, 40.0, Vector2.ZERO, true)
	var fwd_past := graph.direction(int(hit[0]), float(hit[2]))
	PlaytestRoute.clear_route()
	var loop := PlaytestRoute._route(graph, stand, past, fwd_past)
	var pull := PlaytestRoute.steer(graph, loop, past, fwd_past, 8.0, false, 50.0, stand)
	if not bool(pull.get("pull_in", false)) or float(pull["left_m"]) > 30.0:
		problems.append("pull in: the stand 25 m away reads %s" % pull)
	else:
		digest.append("stand pulled into (%.0f m by road)" % float(pull["by_road_m"]))
	var near := PlaytestRoute.steer(graph, PackedVector2Array(), at, fwd, 10.0, false, 50.0, Vector2(0.0, -20.0))
	if float(near["want_kmh"]) > PlaytestRoute.ARRIVE_KMH or absf(float(near["bearing_deg"])) > 0.5:
		problems.append("no route: a goal 20 m ahead reads %s" % near)


## 4. The rc entry points on a stand-in Main.
func _on_main(graph: LaneGraph, map: Node3D) -> void:
	var src := GDScript.new()
	src.source_code = "extends Node\nvar car: Node3D\nvar graph\nvar hud: Node\nvar map: Node3D\nvar flying := false\nvar _main_target := Vector2.INF\nvar main_step := {}\n"
	src.reload()
	var main: Node = src.new()
	main.name = "Main"
	var hud := Fakes.Hud.new()
	var car := Fakes.Car.new()
	main.add_child(car)
	main.set("car", car)
	main.set("graph", graph)
	main.set("hud", hud)
	main.set("map", map)
	root.add_child(main)
	car.global_position = Vector3(PT60.x, 0.0, PT60.y)
	car.rotation.y = deg_to_rad(PT60_YAW)
	if not PlaytestRoute.get_goal().is_empty():
		problems.append("main: a goal with nothing pinned: %s" % PlaytestRoute.get_goal())
	main.set("_main_target", Vector2(-1100.0, -300.0))
	var g := PlaytestRoute.get_goal()
	if g.get("source", "") != "main_target":
		problems.append("main: the guide's target reads %s" % g)
	hud.markers.set_target(Vector2(-1500.0, 0.0), Color.RED)
	g = PlaytestRoute.get_goal()
	if g.get("source", "") != "target" or absf(float(g.get("x", 0.0)) + 1500.0) > 0.1:
		problems.append("main: the active target reads %s" % g)
	PlaytestRoute.clear_route()
	var st := PlaytestRoute.get_drive_state()
	for key in ["x", "z", "heading_deg", "speed_kmh", "unsticks", "place", "street", "goal_source", "left_m", "bearing_deg", "want_kmh"]:
		if not st.has(key):
			problems.append("main: get_drive_state has no %s: %s" % [key, st])
	if not bool(st.get("route", false)) or float(st.get("left_m", 0.0)) < 500.0:
		problems.append("main: no road route to the target: %s" % st)
	var own := PlaytestRoute.get_drive_state(-1100.0, -300.0)
	if own.get("goal_source", "") != "own":
		problems.append("main: a harness goal reads %s" % own)
	digest.append("rc entry points (%s)" % str(st.get("street", "")))
	main.queue_free()
	hud.free()
