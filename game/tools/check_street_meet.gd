extends SceneTree
## Nocny spot (scripts/street_meet.gd, F's ask 2026-11-06): the WARSAW NIGHT RACING CLUB's rules
## headless, from the committed map data (map/centrum.json: the lane graph and the origin):
##   1. the meshes: the club's five cars and the donut marks one surface each (one draw call apiece);
##   2. the lines: every meet, raid, race and drag line in Polish and English, under 90 characters,
##      no real brand (brand_denylist.json), the parody names only;
##   3. the clock: the club meets from 21:00 to 04:00, never by day;
##   4. the pay: the race's places pay less with each place; a shift's grade (early, perfect, late);
##   5. the drag: the "ok" run, Tadek's and a perfect one in that order of time, all under 30 s,
##      nitro faster still; Tadek beatable by a perfect run, not by a lazy one (shifts 0.9 s late,
##      a slow start); the profile rises and reaches 402 m;
##   6. the real car (car.gd on a flat floor, its inputs held as hold_car holds them, a stick aimed
##      20° off at 75 %): a clean run (0.46 s reaction, shifts 0.15 s after BIEG!) beats Tadek, a
##      lazy one doesn't, and the real time stays within 0.3 s of sim_run's (PT-33);
##   7. the real lane graph: both meets found with a door on a ground road within 160 m, the ring's
##      slots clear of the gap, the strip found and long enough, straight on the southbound lane.
## Prints "check_street_meet: OK (...)" or the problems (exit 1).
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_street_meet.gd [-- --verbose]

const Meet := preload("res://scripts/street_meet.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Car := preload("res://scripts/car.gd")
const BUBBLE := 90


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_meshes(digest)
	_check_lines(digest)
	_check_rules(digest)
	_check_drag(digest)
	await _check_real_car(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_map(g, map, data.get("origin", [52.234, 21.024]), digest)
	if problems.is_empty():
		print("check_street_meet: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_street_meet: %d problems" % problems.size())
		quit(1)


func _check_meshes(digest: PackedStringArray) -> void:
	var tris := 0
	for k: String in ["bawarka", "porsze", "skajlajner", "show_a", "show_b"]:
		var m: ArrayMesh = Meet.car_mesh(k)
		if m.get_surface_count() != 1:
			problems.append("%s: %d surfaces (want 1)" % [k, m.get_surface_count()])
		tris += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	var marks := Meet.marks_mesh()
	if marks.get_surface_count() != 1:
		problems.append("marks: %d surfaces (want 1)" % marks.get_surface_count())
	digest.append("6 meshes, %d triangles" % tris)


func _check_lines(digest: PackedStringArray) -> void:
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	banned.append_array(["BMW", "Porsche", "Nissan", "Skyline", "Toretto", "Fast & Furious", "Furious", "Need for Speed",
			"NFS", "Telegram", "Brian", "Dom ", "family", "rodzina"])
	var lines: Array = []
	lines.append_array(Meet.MEET_LINES)
	lines.append_array(Meet.MEET2_LINES)
	lines.append_array(Meet.RAID_LINES)
	lines.append_array(Meet.RACE_LINES)
	lines.append_array(Meet.DRAG_LINES.values())
	for l: Array in lines:
		if l.size() != 3 or String(l[1]).is_empty() or String(l[2]).is_empty():
			problems.append("line not [who, pl, en]: %s" % str(l))
			continue
		for k in [1, 2]:
			var t := String(l[k])
			if t.length() > BUBBLE:
				problems.append("line over %d characters: %s" % [BUBBLE, t])
			for b in banned:
				if t.to_lower().contains(String(b).to_lower()):
					problems.append("brand or film name '%s' in: %s" % [b, t])
	digest.append("%d lines" % lines.size())


func _check_rules(digest: PackedStringArray) -> void:
	for h: float in [21.0, 23.5, 0.5, 3.9]:
		if not Meet.night_on(h):
			problems.append("no meet at %.1f h" % h)
	for h: float in [4.0, 9.0, 13.0, 20.9]:
		if Meet.night_on(h):
			problems.append("a meet at %.1f h" % h)
	var last := 1 << 20
	for p in range(1, 6):
		var pay: Array = Meet.place_pay(p)
		if int(pay[0]) > last or int(pay[1]) <= 0:
			problems.append("place %d pays %s" % [p, str(pay)])
		last = int(pay[0])
	if Meet.shift_grade(-0.1) != "early" or Meet.shift_grade(0.1) != "perfect" or Meet.shift_grade(0.8) != "late":
		problems.append("shift grades wrong")
	digest.append("clock, pay, shifts")


func _check_drag(digest: PackedStringArray) -> void:
	# The hatch: accel 15, top 30 m/s, the drag tune on top.
	var accel := 15.0
	var top := 30.0 * Meet.DRAG_TOP
	var rr: Array = Meet.rival_run(accel, top)
	var ok := float(rr[3])
	var best := float(rr[4])
	var tadek := float(rr[2])
	var lazy: Array = Meet.sim_run(accel, top, 0.6, 0.9, false)
	var nitro: Array = Meet.sim_run(accel, top, 0.3, 0.3, true, 3.5, 3.0)
	if not (best < tadek and tadek < ok):
		problems.append("times out of order: perfect %.2f, Tadek %.2f, ok %.2f" % [best, tadek, ok])
	if float(lazy[0]) <= tadek:
		problems.append("a lazy run (%.2f s) beats Tadek (%.2f s)" % [lazy[0], tadek])
	if float(nitro[0]) >= tadek:
		problems.append("clean shifts + nitro (%.2f s) don't beat Tadek (%.2f s)" % [nitro[0], tadek])
	if ok > 30.0:
		problems.append("the ok run takes %.1f s" % ok)
	var prof: PackedFloat32Array = rr[0]
	for i in range(1, prof.size()):
		if prof[i] < prof[i - 1]:
			problems.append("profile goes back at %d" % i)
			break
	if Meet.profile_at(prof, ok) < Meet.QUARTER - 1.0:
		problems.append("profile ends short: %.1f m" % Meet.profile_at(prof, ok))
	if verbose:
		print("drag: perfect %.2f, nitro %.2f, Tadek %.2f, ok %.2f, lazy %.2f" % [best, nitro[0], tadek, ok, lazy[0]])
	digest.append("drag: perfect %.2f < Tadek %.2f < ok %.2f s" % [best, tadek, ok])


## One real-car run: [time (s), Tadek's time]. The gear logic is street_meet.gd's _drag_frame.
func _real_run(react: float, delay: float) -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 1200)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, -500)
	world.add_child(floor_body)
	var car := Car.new()
	world.add_child(car)
	var on := {"start": Vector2.ZERO, "dir": Vector2(0, -1), "right": Vector2(1, 0)}
	var top0 := float(car.top_mult)
	var acc0 := float(car.accel_mult)
	var rr: Array = Meet.rival_run(float(car.accel) * acc0, float(car.max_speed) * top0 * Meet.DRAG_TOP)
	var t := 0.0
	var gear := 0
	var w := -1.0
	var boost := 0.0
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	while t < 40.0:
		await physics_frame
		t += dt
		# The stick: aimed 20° off the strip at 75 %, as a thumb would; hold_inputs fixes both.
		car.target_dir = Vector3(sin(deg_to_rad(20.0)), 0.0, -cos(deg_to_rad(20.0)))
		car.throttle = 0.75 if t > react else 0.0
		Meet.hold_inputs(car, on)
		boost = maxf(0.0, boost - dt)
		car.accel_mult = acc0 * (Meet.SHIFT_BOOST if boost > 0.0 else 1.0)
		car.top_mult = top0 * Meet.DRAG_TOP * float(Meet.GEARS[gear])
		var cap := float(car.max_speed) * float(car.top_mult)
		if gear < Meet.GEARS.size() - 1 and car.vel.length() >= cap * Meet.SHIFT_AT:
			w = 0.0 if w < 0.0 else w + dt
			if w >= minf(delay, Meet.AUTO_SHIFT):
				gear += 1
				w = -1.0
				if delay <= Meet.PERFECT:
					boost = Meet.BOOST_S
		if -car.global_position.z >= Meet.QUARTER:
			break
	var lat := absf(car.global_position.x)
	world.free()
	if lat > 3.0:
		problems.append("the held car wandered %.1f m off its line" % lat)
	return [t, float(rr[2])]


func _check_real_car(digest: PackedStringArray) -> void:
	var clean: Array = await _real_run(0.46, 0.15)
	var lazy: Array = await _real_run(0.6, 0.9)
	var c := Car.new()
	var sim: Array = Meet.sim_run(float(c.accel), float(c.max_speed) * Meet.DRAG_TOP, 0.46, 0.15, true)
	c.free()
	if float(clean[0]) >= float(clean[1]):
		problems.append("the real car's clean run (%.2f s) doesn't beat Tadek (%.2f s)" % [clean[0], clean[1]])
	if float(lazy[0]) <= float(lazy[1]):
		problems.append("the real car's lazy run (%.2f s) beats Tadek (%.2f s)" % [lazy[0], lazy[1]])
	if absf(float(clean[0]) - float(sim[0])) > 0.3:
		problems.append("the real car (%.2f s) and sim_run (%.2f s) differ" % [clean[0], sim[0]])
	digest.append("real car: clean %.2f < Tadek %.2f < lazy %.2f s" % [clean[0], clean[1], lazy[0]])


func _check_map(g: LaneGraph, map: Node3D, origin: Array, digest: PackedStringArray) -> void:
	var meets := Meet.find_meets(g, map, origin)
	if meets.size() != Meet.MEETS.size():
		problems.append("%d of %d meets found on the map" % [meets.size(), Meet.MEETS.size()])
	for m in meets:
		var d3: Vector3 = m["door"]["at"]
		var c: Vector3 = m["at"]
		var gap: Vector3 = m["gap"]
		for s: Vector3 in m["slots"]:
			if s.distance_to(gap) < 5.0:
				problems.append("%s: a slot on the gap" % m["id"])
		if verbose:
			print("meet %s at %.0f, %.0f, door %.0f m away on %s" % [m["id"], c.x, c.z, c.distance_to(d3), m["door"]["street"]])
	var strip := Meet.find_strip(g, map, origin)
	if not bool(strip.get("ok", false)):
		problems.append("the strip isn't on the map (or too short): %s" % str(strip.get("start")))
	else:
		# Straight: the lane graph under the line, the finish and halfway lies within 2 m of the strip's line.
		var dir: Vector2 = strip["dir"]
		for s: float in [0.0, Meet.QUARTER * 0.5, Meet.QUARTER]:
			var p: Vector2 = strip["start"] + dir * s
			var hit: Array = g.snap(p, 6.0, dir, false, true)
			if hit.is_empty():
				problems.append("no southbound lane under the strip at %.0f m" % s)
		digest.append("strip %.0f m, lanes %.1f m apart" % [float(strip["length"]), float(strip["lane_gap"])])
	digest.append("%d meets" % meets.size())
