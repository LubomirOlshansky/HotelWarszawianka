extends SceneTree
## PT-55 (Aura, 2026-11-16): the kinematic bodies traffic.gd gives the town's cars round the
## player (`_bodies_step`, BODIES of them within BODY_RANGE), headless, from the committed map
## (map/centrum.json); seeded. With the player's car standing in the eastbound lane of Książęca at
## Kruczkowskiego, where 17 cars come within BODY_RANGE, 90 s of real traffic:
##   1. every physics step the cars with a body are the BODIES nearest (all of them when fewer are
##      in range), each body where its car is, the rest parked out of reach with no layer;
##   2. a car keeps its body while it stays among the nearest (a body handed to another car jumps
##      metres in a step, which the physics reads as its speed against the player's car);
##   3. the stand is a crowded one (more cars in range than bodies), or 1 proves nothing;
##   4. with the player off the road, no body has a layer.
## Prints "check_traffic_bodies: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_traffic_bodies.gd [-- --verbose]

const Traffic := preload("res://scripts/traffic.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Fakes := preload("res://tools/fakes.gd")

## The player's car: Aura run B's stop (bug log PT-55), in the eastbound lane.
const AT := Vector2(419.0, 427.0)
const SECONDS := 90

var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 90.0
	root.add_child(cam)
	var traffic: Node3D = Traffic.new()
	root.add_child(traffic)
	traffic.setup(g, map, cam, {})
	# (setup builds the pools over a few frames.)
	for i in 4:
		await process_frame
	traffic.set_process(false)
	traffic.set_physics_process(false)
	var focus := Vector3(AT.x, 0.0, AT.y)
	cam.global_transform = Transform3D(Basis.IDENTITY, focus + Vector3(0.0, 80.0, 60.0)).looking_at(focus, Vector3.UP)
	traffic.player_on_road = true
	traffic.player_pos = focus
	traffic.player_vel = Vector3.ZERO
	var most := 0
	var crowded := 0
	var wrong := 0
	var swaps := 0
	var misplaced := 0
	var usec := 0
	var bodies: Array = traffic._bodies
	var before: Array = []
	before.resize(Traffic.BODIES)
	for f in 60 * SECONDS:
		traffic.call("_process", 1.0 / 60.0)
		var near: Array = []
		for d in traffic.drivers():
			if d.ghost:
				continue
			var dist := Vector2(d.pos.x, d.pos.z).distance_to(AT)
			if dist <= Traffic.BODY_RANGE:
				near.append([dist, d])
		near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		most = maxi(most, near.size())
		if near.size() > Traffic.BODIES:
			crowded += 1
		var want := {}
		for i in mini(near.size(), Traffic.BODIES):
			want[near[i][1]] = near[i][0]
		var still_near := want.duplicate()
		var t0 := Time.get_ticks_usec()
		traffic.call("_bodies_step", 1.0 / 60.0)
		usec += Time.get_ticks_usec() - t0
		var got := {}
		for k in Traffic.BODIES:
			var d = traffic._body_driver[k]
			var body: AnimatableBody3D = bodies[k]
			if d == null:
				if body.collision_layer != 0:
					misplaced += 1
				continue
			got[d] = true
			if body.collision_layer != 1 or Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(d.pos.x, d.pos.z)) > 0.01:
				misplaced += 1
			# 2: the car this body had is still among the nearest, but another one has it now.
			if before[k] != null and before[k] != d and still_near.has(before[k]):
				swaps += 1
			before[k] = d
		for k in Traffic.BODIES:
			if traffic._body_driver[k] == null:
				before[k] = null
		var bad := got.size() != want.size()
		for d in want:
			if not got.has(d):
				bad = true
				if verbose and wrong < 5:
					print("frame %d: the car %.1f m away has no body" % [f, want[d]])
		if bad:
			wrong += 1
	if wrong > 0:
		problems.append("1: %d of %d steps gave the bodies to other cars than the %d nearest" % [wrong, 60 * SECONDS, Traffic.BODIES])
	if misplaced > 0:
		problems.append("1: %d body-steps with a body not at its car, or a free body with a layer" % misplaced)
	if swaps > 0:
		problems.append("2: %d times a body went to another car while its own was still among the nearest" % swaps)
	if crowded == 0:
		problems.append("3: never more than %d cars within %.0f m at %s (most %d): the stand is not a crowded one" % [Traffic.BODIES, Traffic.BODY_RANGE, AT, most])
	traffic.player_on_road = false
	traffic.call("_bodies_step", 1.0 / 60.0)
	for body: AnimatableBody3D in bodies:
		if body.collision_layer != 0:
			problems.append("4: a body keeps its layer with the player off the road")
			break
	for c in root.get_children():
		c.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_traffic_bodies: OK (%d s at %s: most %d cars in %.0f m, %d crowded steps, the %d nearest bodied every step, no body handed over; %.1f µs a step)" % [
				SECONDS, AT, most, Traffic.BODY_RANGE, crowded, Traffic.BODIES, float(usec) / (60 * SECONDS)])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_traffic_bodies: %d problems" % problems.size())
		quit(1)
