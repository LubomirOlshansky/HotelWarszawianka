extends SceneTree
## The road route to the active target (target_route.gd, TD-13 step 4) on the real lane graph
## (map/centrum.json) with the HUD stand-in (fakes.gd Hud) and the real marker registry:
##   1. no target, no route and no search;
##   2. a target across the centre: one search, the route on the HUD under the owner "target" in the
##      target's colour, from the car's lane to the target, by road (longer than the straight line,
##      no jump over 250 m);
##   3. many frames on one goal: no second search (the line is only walked again);
##   4. a goal that moves: under REGOAL_M no search, over it only once REGOAL_S have passed;
##   5. another owner's route (a delivery's) wins, and the target's comes back when it goes;
##   6. in the air, without a target, or with a goal far from every road: no route;
##   7. a tracked place (the full map's track, map_track.gd: the quest pin is the registry's TARGET mark
##      main.gd `_put_target` puts): the route follows it in its colour, goes when it is untracked and
##      comes to the next place tracked, with a search each.
## Usage: godot --headless --path game --script res://tools/check_target_route.gd

const LaneGraph := preload("res://scripts/lane_graph.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const TargetRoute := preload("res://scripts/target_route.gd")
const RouteLine := preload("res://scripts/route_line.gd")
const MapTrack := preload("res://scripts/map_track.gd")
const Fakes := preload("res://tools/fakes.gd")

var problems: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_target_route: FAIL (no map/centrum.json)")
		quit(1)
		return
	var map := Fakes.FlatMap.new()
	map.roof_level = -INF
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var markers: MapMarkers = hud.markers
	var tr := TargetRoute.new(hud, graph)
	# The car and the goal: two lane points of the drivable network about a kilometre apart.
	var car_hit := graph.snap(Vector2(-300, 0), 200.0, Vector2.ZERO, true)
	var goal_hit := graph.snap(Vector2(500, 300), 200.0, Vector2.ZERO, true)
	if car_hit.is_empty() or goal_hit.is_empty():
		print("check_target_route: FAIL (no lane near the test points)")
		quit(1)
		return
	var car: Vector2 = graph.point_at(int(car_hit[0]), float(car_hit[2]))
	var goal: Vector2 = graph.point_at(int(goal_hit[0]), float(goal_hit[2])) + Vector2(6, 0)  # a door beside the road
	hud.car_at = car
	hud.heading = (graph.point_at(int(car_hit[0]), float(car_hit[2]) + 1.0) - car).normalized()
	# 1.
	_frames(tr, 5)
	_expect(hud.route.is_empty() and tr.searches == 0, "no target: no route, no search")
	# 2.
	markers.set_target(goal, Color.ORANGE)
	var t0 := Time.get_ticks_usec()
	_frames(tr, 1)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	var pts := hud.route
	_expect(tr.searches == 1, "a new target: one search (%d)" % tr.searches)
	_expect(pts.size() >= 3 and hud.route_owner == TargetRoute.OWNER and hud.route_colour == Color.ORANGE,
			"the route on the HUD under \"target\" in the target's colour (%d points, %s)" % [pts.size(), hud.route_owner])
	var length := 0.0
	var step := 0.0
	for k in pts.size() - 1:
		length += pts[k].distance_to(pts[k + 1])
		step = maxf(step, pts[k].distance_to(pts[k + 1]))
	if pts.size() >= 2:
		_expect(pts[0].distance_to(car) < 1.0 and pts[pts.size() - 1] == goal, "from the car's lane (%.1f m) to the target" % pts[0].distance_to(car))
	_expect(length >= car.distance_to(goal) and step < 250.0, "by road: %.0f m against %.0f m straight, longest step %.0f m" % [length, car.distance_to(goal), step])
	# 3.
	var set_before: int = hud.routes_set
	_frames(tr, 300)
	_expect(tr.searches == 1, "300 frames on one goal: still one search (%d)" % tr.searches)
	_expect(hud.routes_set - set_before >= 3 and hud.routes_set - set_before <= 6, "the line walked again about once a second (%d in 5 s)" % (hud.routes_set - set_before))
	# 4.
	markers.set_target(goal + Vector2(20, 0), Color.ORANGE)
	_frames(tr, 240)
	_expect(tr.searches == 1, "a goal moved %d m: no new search" % 20)
	markers.set_target(goal + Vector2(0, 70), Color.ORANGE)
	_frames(tr, 1)
	var early := tr.searches
	_frames(tr, 100)
	_expect(early == 2 and tr.searches == 2, "a goal moved 70 m after 4 s: one search at once, then none (%d, %d)" % [early, tr.searches])
	markers.set_target(goal + Vector2(0, 140), Color.ORANGE)
	_frames(tr, 60)
	_expect(tr.searches == 2, "moved again within REGOAL_S: no search yet (%d)" % tr.searches)
	_frames(tr, 150)
	_expect(tr.searches == 3, "after REGOAL_S: one more (%d)" % tr.searches)
	# 5.
	hud.set_minimap_route(PackedVector2Array([car, car + Vector2(50, 0)]), Color.RED, "jobs")
	_frames(tr, 120)
	_expect(hud.route_owner == "jobs" and hud.route.size() == 2, "a delivery's route wins (%s)" % hud.route_owner)
	hud.clear_minimap_route("jobs")
	_frames(tr, 70)
	_expect(hud.route_owner == TargetRoute.OWNER and hud.route.size() >= 3, "the target's route comes back when the delivery's goes (%s)" % hud.route_owner)
	# 6.
	hud.flying = true
	_frames(tr, 2)
	_expect(hud.route.is_empty(), "in the air: no road route")
	hud.flying = false
	_frames(tr, 70)
	_expect(hud.route_owner == TargetRoute.OWNER, "back on the road: the route again")
	markers.set_target(Vector2.INF, Color.WHITE)
	_frames(tr, 2)
	_expect(hud.route.is_empty(), "the target gone: the route gone")
	var n := tr.searches
	markers.set_target(Vector2(90000, 90000), Color.ORANGE)
	_frames(tr, 300)
	_expect(hud.route.is_empty() and tr.searches == n, "a goal far from every road: no route, no search")
	# 7.
	var pin := MapTrack.entry_of("garage", goal)
	var n7 := tr.searches
	markers.set_target(pin["at"], pin["colour"])  # the tracked pin, as `_put_target` puts it
	_frames(tr, 2)
	_expect(tr.searches == n7 + 1 and hud.route.size() >= 3 and hud.route_colour == pin["colour"] and hud.route[hud.route.size() - 1] == goal,
			"a tracked place: the route to it in its colour (%d points, %d searches)" % [hud.route.size(), tr.searches - n7])
	markers.set_target(Vector2.INF, Color.WHITE)  # untracked
	_frames(tr, 2)
	_expect(hud.route.is_empty(), "untracked: the route is gone")
	var other := graph.point_at(int(car_hit[0]), float(car_hit[2]) + 60.0) + Vector2(6, 0)
	markers.set_target(other, pin["colour"])
	_frames(tr, 2)
	_expect(tr.searches == n7 + 2 and hud.route.size() >= 2, "the next place tracked: a new search and its route (%d)" % (tr.searches - n7))
	tr.free()
	hud.queue_free()
	map.queue_free()
	if problems.is_empty():
		print("check_target_route: OK (route %.0f m by road for %.0f m straight, %d points, first frame %.1f ms with the search)"
				% [length, car.distance_to(goal), pts.size(), ms])
		quit(0)
	else:
		for p in problems:
			print("check_target_route: %s" % p)
		print("check_target_route: FAIL (%d problems)" % problems.size())
		quit(1)


## `n` frames of 1/60 s.
func _frames(tr: Node, n: int) -> void:
	for i in n:
		tr.call("tick", 1.0 / 60.0)
