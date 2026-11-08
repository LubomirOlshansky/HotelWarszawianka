extends SceneTree
## Driving-first P14 and P16 (docs/PLAYTEST.md §5, GAMEPLAY_PLAN 1.6) without the Autopilot bill:
## the real car (car.gd) steered along real lane-graph routes in the whole city (the sectors built
## from their files, or the prebuilt sector scenes with --prebuilt), no traffic. A simple driver
## points the stick (car.target_dir, the point-to-steer input) at a spot LOOK m ahead on the route
## and holds a speed that the next bends allow, as a careful player would. A route fails on a stall
## (under STALL m/s for over STALL_TIME s), an unstick, the car leaving the route (OFF_ROUTE m) or
## sinking under `drive_height`, or not reaching the end in time.
##
## PT-21 (2026-11-04, Autopilot run 20261104-102329): with the gas held and no steering, the car
## slowed hard at bends on Frascati, Hoża, Ordynacka and Sienna. This drives those streets end to
## end, steered: a fail here is a road problem, a pass means the run hit the corners' walls.
## P16: the Trzy mosty route (trzy_mosty.gd legs), bridge by bridge at full speed.
##
## --streets=A,B (with --box=x0,z0,x1,z1, metres): drive those streets instead, only their lanes inside
## the box, and no Trzy mosty; --route=NAME:x,z>x,z[>...][;NAME2:...] adds a route through the graph
## nodes nearest those points (into and out of side roads) (a road design check: tools/road_design.py streets driven end to end).
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_lane_drive.gd [-- --prebuilt --handling=grounded --verbose --only=NAME --streets=A,B --box=...]

const LaneGraph := preload("res://scripts/lane_graph.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")
const Car := preload("res://scripts/car.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
## Sectors within this of a route point are built.
const REACH := 60.0
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")

## The narrow streets of P14 (lanes under 2.5 m in the GAMEPLAY_PLAN audit): each driven from one
## end of its named edges to the other, both ways.
const STREETS := ["Frascati", "Hoża", "Ordynacka", "Sienna", "Aleja 3 Maja"]
## Route points every STEP m; the stick aims LOOK m ahead (more at speed).
const STEP := 3.0
const LOOK := 5.0
const STALL := 2.0
const STALL_TIME := 1.5
const OFF_ROUTE := 12.0
## Speeds (m/s) for the sharpest turn within the next BEND_AHEAD m.
const BEND_AHEAD := 35.0
const CRUISE_NARROW := 14.0
const CRUISE_FAST := 30.0

var prebuilt := false
## --handling=cruise|sport|grounded: drive the routes in that profile (-1: the car's default, Cruise).
var handling := -1
var verbose := false
var only := ""
var streets: Array = STREETS
var box := Rect2()
var extra := ""
var map: Node3D
var graph: LaneGraph
var car: CharacterBody3D
var routes: Array[Dictionary] = []
var _r := -1
var _path := PackedVector3Array()
var _idx := 0
var _t := 0.0
var _stalled := 0.0
var _worst := 0.0
var _worst_at := Vector3.ZERO
var _sink := 0.0
var _off := 0.0
var _min_v := INF
var _failures := 0
var _frames := 0
var _cruise := CRUISE_NARROW
var _over := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--prebuilt":
			prebuilt = true
		elif a == "--verbose":
			verbose = true
		elif a.begins_with("--handling="):
			handling = Car.parse_handling(a.trim_prefix("--handling="))
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--streets="):
			streets = Array(a.trim_prefix("--streets=").split(","))
		elif a.begins_with("--route="):
			extra = a.trim_prefix("--route=")
		elif a.begins_with("--box="):
			var b := a.trim_prefix("--box=").split_floats(",")
			box = Rect2(minf(b[0], b[2]), minf(b[1], b[3]), absf(b[2] - b[0]), absf(b[3] - b[1]))
	var t0 := Time.get_ticks_msec()
	# The index first (the lane graph needs only it), then just the sectors within REACH of a route.
	if prebuilt:
		map = (load(SectorStreamer.INDEX_SCENE) as PackedScene).instantiate()
		root.add_child(map)
	else:
		map = MapBuilder.new()
		root.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(SectorStreamer.INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	graph = LaneGraph.new(map.data["graph"], map)
	for street: String in streets:
		var ends := _street_ends(street)
		if ends.is_empty():
			_fail_build("no lanes named %s" % street)
			continue
		for way in 2:
			var a: int = ends[way]
			var b: int = ends[1 - way]
			_add_route("%s %s" % [street, "→" if way == 0 else "←"], PackedInt32Array([a, b]), CRUISE_NARROW)
	for spec: String in extra.split(";", false):
		var parts := spec.split(":")
		var stops := PackedInt32Array()
		for xz: String in parts[1].split(">"):
			var f := xz.split_floats(",")
			stops.append(graph.nearest_node(Vector2(f[0], f[1])))
		_add_route(parts[0], stops, CRUISE_NARROW)
	var tm := TrzyMosty.new()
	if streets != STREETS or extra != "":
		pass
	elif not tm.build(graph, map.data):
		_fail_build("Trzy mosty: %s" % tm.error)
	else:
		var start := graph.nearest_node(Vector2(tm.start_pos.x, tm.start_pos.z))
		var stops := PackedInt32Array([start])
		stops.append_array(tm.legs)
		# One episode a bridge: start → span's far end, then on to the next span's far end, then the finish.
		var cut := [0, 2, 4, stops.size() - 1]
		for i in 3:
			var part := stops.slice(cut[i], cut[i + 1] + 1)
			_add_route("Trzy mosty leg %d (%s)" % [i + 1, TrzyMosty.BRIDGES[i]["pl"]], part, CRUISE_FAST)
	var n := 0
	for k: Array in map.index_data["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := Rect2(key.x * MapBuilder.SECTOR, key.y * MapBuilder.SECTOR, MapBuilder.SECTOR, MapBuilder.SECTOR).grow(REACH)
		var near := false
		for r: Dictionary in routes:
			for q: Vector3 in r["pts"]:
				if rect.has_point(Vector2(q.x, q.z)):
					near = true
					break
			if near:
				break
		if not near:
			continue
		var sector: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
				if prebuilt else map.build_sector(key)
		map.add_child(sector)
		n += 1
	if not prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	print("check_lane_drive: %d routes, %d sectors %s in %d ms" % [routes.size(), n, "loaded" if prebuilt else "built", Time.get_ticks_msec() - t0])


func _fail_build(why: String) -> void:
	print("FAIL %s" % why)
	_failures += 1


## The two graph nodes of a street's edges that lie furthest apart (in the connected part).
func _street_ends(street: String) -> Array:
	var nodes: Array[int] = []
	for e in graph.e_a.size():
		if graph.e_name[e] == street:
			for n: int in [graph.e_a[e], graph.e_b[e]]:
				if graph.node_scc[n] != 0 and not nodes.has(n) and (box.size == Vector2.ZERO or box.has_point(graph.node_pos[n])):
					nodes.append(n)
	if nodes.size() < 2:
		return []
	var best := [nodes[0], nodes[1]]
	var best_d := -1.0
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var d := graph.node_pos[nodes[i]].distance_squared_to(graph.node_pos[nodes[j]])
			if d > best_d:
				best_d = d
				best = [nodes[i], nodes[j]]
	return best


## The shortest lane path through `stops` (graph nodes), as points on lane 0 every STEP m.
func _add_route(name: String, stops: PackedInt32Array, cruise: float) -> void:
	if only != "" and not name.contains(only):
		return
	var pts := PackedVector3Array()
	var prev := -1
	var lane := 0
	for i in stops.size() - 1:
		var dist := graph.distances_to(stops[i + 1])
		var n := stops[i]
		var guard := 0
		while n != stops[i + 1]:
			guard += 1
			var best := -1
			var best_c := INF
			for e in graph.node_out[n]:
				var c: float = graph.e_len[e] + dist[graph.e_b[e]]
				if c < best_c:
					best_c = c
					best = e
			if best < 0 or best_c == INF or guard > 5000:
				_fail_build("%s: no lane path from node %d to %d" % [name, n, stops[i + 1]])
				return
			# Across the junction as traffic drives it: the lane traffic would take and the curve.
			if prev >= 0:
				var j := graph.next_lane(prev, lane, best)
				var c := graph.connector(prev, lane, best, j)
				var hy := graph.height(prev, graph.e_s1[prev])
				var hy2 := graph.height(best, graph.e_s0[best])
				var cn := maxi(2, int(LaneGraph.bezier_length(c) / STEP))
				for k in range(1, cn):
					var q := LaneGraph.bezier(c, float(k) / cn)
					pts.append(Vector3(q.x, lerpf(hy, hy2, float(k) / cn), q.y))
				lane = j
			prev = best
			var off := graph.lane_offset(best, lane)
			var s := graph.e_s0[best]
			while s < graph.e_s1[best]:
				var q := graph.point_at(best, s, off)
				pts.append(Vector3(q.x, graph.height(best, s), q.y))
				s += STEP
			n = graph.e_b[best]
	if pts.size() < 4:
		_fail_build("%s: route under %d points" % [name, pts.size()])
		return
	var length := 0.0
	for i in range(1, pts.size()):
		length += pts[i].distance_to(pts[i - 1])
	if verbose:
		for i in range(0, pts.size(), 5):
			print("   route %s point %d: %.1f, %.1f, %.1f" % [name, i, pts[i].x, pts[i].z, pts[i].y])
	routes.append({"name": name, "pts": pts, "cruise": cruise, "len": length})


func _next() -> bool:
	if car != null:
		car.queue_free()
		car = null
	_r += 1
	if _r >= routes.size():
		return false
	var r: Dictionary = routes[_r]
	_path = r["pts"]
	_cruise = float(r["cruise"])
	car = Car.new()
	if handling >= 0:
		car.set_handling(handling)
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	var d := _path[1] - _path[0]
	car.global_position = _path[0]
	car.rotation.y = atan2(-d.x, -d.z)
	car.reset_physics_interpolation()
	_idx = 0
	_t = 0.0
	_stalled = 0.0
	_worst = 0.0
	_sink = 0.0
	_off = 0.0
	_min_v = INF
	return true


## The sharpest heading change (radians) over the route's next `ahead` metres from point i.
func _bend(i: int, ahead: float) -> float:
	var worst := 0.0
	var steps := int(ahead / STEP)
	var j0 := mini(i + 1, _path.size() - 1)
	var d0 := Vector2(_path[j0].x - _path[i].x, _path[j0].z - _path[i].z)
	for k in range(2, steps):
		var j := i + k
		if j + 1 >= _path.size():
			break
		var d := Vector2(_path[j + 1].x - _path[j].x, _path[j + 1].z - _path[j].z)
		if d.length() > 0.01 and d0.length() > 0.01:
			worst = maxf(worst, absf(d0.angle_to(d)))
	return worst


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _frames < 3 or _over:
		return false
	if car == null:
		if not _next():
			_finish()
		return false
	_t += dt
	var p := car.global_position
	# Progress: the nearest route point a little way on from the last one.
	var best := _idx
	var best_d := INF
	for j in range(_idx, mini(_idx + 20, _path.size())):
		var dd := Vector2(_path[j].x - p.x, _path[j].z - p.z).length()
		if dd < best_d:
			best_d = dd
			best = j
	_idx = best
	var v := Vector2(car.vel.x, car.vel.z).length()
	var look := LOOK + v * 0.3
	var ahead := mini(_idx + int(ceil(look / STEP)), _path.size() - 1)
	var aim := _path[ahead] - p
	aim.y = 0.0
	# Grounded brakes at ~1.1 g, not 3 g: a careful driver looks a stopping distance further on.
	var bend := _bend(_idx, BEND_AHEAD + v + (v * v / 18.0 if car.weighty else 0.0))
	var want := _cruise
	if bend > deg_to_rad(70.0):
		want = 6.0
	elif bend > deg_to_rad(40.0):
		want = 9.0
	elif bend > deg_to_rad(20.0):
		want = minf(_cruise, 14.0)
	if car.weighty:
		# Grounded turns with ~1.2 g at most: no faster than 80 % of that grip allows on the bend's radius.
		var reach := BEND_AHEAD + v
		var curve := _bend(_idx, reach)
		if curve > 0.02:
			want = minf(want, maxf(6.0, sqrt(0.8 * car.turn_pull * reach / curve)))
	car.target_dir = aim.normalized() if aim.length() > 0.5 else Vector3.ZERO
	car.throttle = clampf(want / car.top_speed(), 0.0, 1.0)
	car.braking = v > want + 4.0
	# Findings.
	_stalled = _stalled + dt if v < STALL and _t > 2.0 else 0.0
	if _stalled > _worst:
		_worst = _stalled
		_worst_at = p
	_off = maxf(_off, best_d)
	_min_v = minf(_min_v, v) if _t > 3.0 else _min_v
	var h: float = map.drive_height(p.x, p.z, p.y)
	_sink = maxf(_sink, h - p.y)
	if verbose and car.get_slide_collision_count() > 0:
		var c := car.get_slide_collision(0)
		var who: Object = c.get_collider()
		print("   hit t=%.2f at %.1f, %.1f  %s normal %s point %s" % [_t, p.x, p.z,
				(who as Node).get_path() if who is Node else str(who), c.get_normal(), c.get_position()])
	if verbose and int(_t / dt) % 30 == 0:
		print("   t=%.1f at %.0f, %.0f  %.1f m/s (want %.0f) point %d/%d%s" % [_t, p.x, p.z, v, want, _idx, _path.size(),
				"  touching" if car.get_slide_collision_count() > 0 else ""])
	var r: Dictionary = routes[_r]
	var limit: float = float(r["len"]) / 4.0 + 20.0
	var done := _idx >= _path.size() - 3
	var why: Array[String] = []
	if _worst > STALL_TIME:
		why.append("stalled %.1f s at %.0f, %.0f" % [_worst, _worst_at.x, _worst_at.z])
	if int(car.unsticks) > 0:
		why.append("unstuck %d×" % int(car.unsticks))
	if _off > OFF_ROUTE:
		why.append("%.0f m off the route at %.0f, %.0f" % [_off, p.x, p.z])
	if _sink > 1.0:
		why.append("%.1f m under drive_height" % _sink)
	if not why.is_empty() or done or _t > limit:
		if not done and why.is_empty():
			why.append("not at the end after %.0f s (at %.0f, %.0f, point %d/%d)" % [_t, p.x, p.z, _idx, _path.size()])
		print("%s %s: %.0f m in %.1f s (%.0f km/h on average), slowest %.1f m/s%s  (--at=%.0f,%.0f)" % [
				"FAIL" if not why.is_empty() else "ok  ", r["name"], float(r["len"]), _t,
				float(r["len"]) / maxf(_t, 0.1) * 3.6, 0.0 if _min_v == INF else _min_v,
				"" if why.is_empty() else " · " + ", ".join(why), _path[0].x, _path[0].z])
		if not why.is_empty():
			_failures += 1
		if not _next():
			_finish()
	return false


func _finish() -> void:
	if _over:
		return
	_over = true
	if _failures == 0:
		print("check_lane_drive: OK")
	else:
		print("check_lane_drive: %d of %d routes fail" % [_failures, routes.size()])
	quit(1 if _failures > 0 else 0)
