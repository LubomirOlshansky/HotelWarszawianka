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
##      the same two runs in the Grounded handling (car.gd GROUNDED) straddle Tadek too;
##   7. the real lane graph: both meets found with a door on a ground road within 160 m, the ring's
##      slots clear of the gap, the strip found and long enough, straight on the southbound lane;
##      the questline's start found on Parkingowa, past the start beacon's reach from the spawn
##      (out of the first view) and under 700 m from it;
##   8. the rings clear (F 2026-11-08, meet 2 stood among fences): no fence, wall, guard rail or
##      building within RING_R + 4 m of a meet's middle;
##   9. the drag's tacho dial rises with the revs and the gate mesh is one surface; the count reads
##      3, 2, 1, START!;
##  10. the play: a real Meet on the real lane graph, a fixed seed, driven a frame at a time against
##      stand-ins (the HUD, the traffic, the police, the car): Darek's clock, the call and the offer
##      (missed, declined), JADĘ!, the meet, both raids, the race and its places, meet 2, the pin to the
##      drag, the exhibition pairs, the line, the launch, the shifts, every end of the drag (win, loss,
##      false start, off the strip, the card left), REWANŻ and KONIEC, the ✕ in every stage, in person,
##      the director, that each end puts everything down, and the script's dice at every point where
##      it draws (the first call, a missed call, the crowd and the parked cars at JADĘ!, meet 2's
##      crowd, the tree, the next call after a night: once, and twice when the call came by the clock).
## Prints "check_street_meet: OK (...)" or the problems (exit 1).
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_street_meet.gd [-- --verbose]

const Meet := preload("res://scripts/street_meet.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Story := preload("res://scripts/story_quests.gd")
const Car := preload("res://scripts/car.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const BUBBLE := 90
const DT := 1.0 / 60.0


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0


## The play's map: the ground is not the terrain, so a height taken from the wrong one shows (the
## arrow leads to the spot's own height, the kit's target sits on the ground).
class PlayMap extends FakeMap:
	func ground_height(_x: float, _z: float) -> float:
		return 0.5


## traffic.gd's Driver, as much of it as the meet and its race session (race_session.gd: the
## fields `arm_racer` sets, the street a plan is searched from, in view) read and write.
class Driver extends RefCounted:
	var id := 0
	var pos := Vector3.ZERO
	var yaw := 0.0
	var edge := 0
	var visible := false
	var parked := false
	var persistent := false
	var ghost := false
	var active := true
	var arrived := false
	var cuts: Variant = null
	var plan: Variant = null
	var race_top := 0.0
	var race_share := 0.0
	var race_accel := 0.0
	var race_brake := 0.0
	var race_lat := 0.0
	var race_effort := 0.0
	var race_corner := 0.0
	var race_still := 0.0
	var race_passes := 0
	var race_mistake := 0.0
	var race_wrong := 0
	var race_block := 0.0
	var race_dare := 1.0
	var race_rng: RandomNumberGenerator
	var cuts_taken := 0
	var links_taken := 0
	var mistakes := 0
	var wrong_turns := 0
	var blocks := 0
	var speed_factor := 1.0
	var accel_factor := 1.0
	## The stand-in's own: racing to a node, the road left to it (m), a patrol car.
	var racing := false
	var left := 99999.0
	var patrol := false


## traffic.gd as the meet uses it: every call remembered by name in `calls`.
class PlayTraffic extends Node3D:
	signal turned_back(d: Driver)
	signal hop_refused(d: Driver)
	var calls: Array[String] = []
	var all: Array = []
	var cars: Array = []
	## on_screen's answer.
	var seen := true

	func make(at: Vector3, yaw: float) -> Driver:
		var d := Driver.new()
		d.id = all.size()
		d.pos = at
		d.yaw = yaw
		all.append(d)
		return d

	## An ordinary car in traffic (the check places these, on the strip for one).
	func spawn(at: Vector3) -> Driver:
		var d := make(at, 0.0)
		cars.append(d)
		return d

	func add_parked_car(e: int, _s: float, at: Vector3, yaw: float, _block_lane: int, _shape: int, _paint: Color) -> Driver:
		var d := make(at, yaw)
		d.edge = e
		d.parked = true
		cars.append(d)
		calls.append("add_parked_car")
		return d

	func park(d: Driver, _e: int, _s: float, at: Vector3, yaw: float, _block_lane := -1) -> void:
		d.pos = at
		d.yaw = yaw
		d.parked = true
		calls.append("park")

	func unpark(d: Driver, e: int, _lane: int, _s: float) -> void:
		d.edge = e
		d.parked = false
		calls.append("unpark")

	func remove(d: Driver) -> void:
		d.active = false
		d.racing = false
		cars.erase(d)
		calls.append("remove")

	func stop_racing(d: Driver) -> void:
		d.racing = false
		calls.append("stop_racing")

	func race_to(d: Driver, _finish: int, _dist: PackedFloat32Array, plan: Variant = null) -> void:
		d.racing = true
		d.plan = plan
		calls.append("race_to")

	func reroute(_d: Driver, _dist: PackedFloat32Array) -> void:
		calls.append("reroute")

	## No town cars on the stand-in's roads (the plans count none).
	func race_density() -> float:
		return 0.0

	func remaining(d: Driver) -> float:
		return d.left

	func on_screen(_p: Vector3, _height: float) -> bool:
		return seen

	func drivers() -> Array:
		return cars

	func add_node_driver(node: Node3D, _size: Vector3, e: int, _lane: int, _s: float) -> Driver:
		var d := make(node.global_position, node.global_rotation.y)
		d.edge = e
		cars.append(d)
		calls.append("add_node_driver")
		return d

	func count(what: String) -> int:
		return calls.count(what)


## police.gd as the meet uses it: the raid's arguments, the cordon's cars, the stand-downs.
class PlayPolice extends Node:
	signal chase_ended(how: String)
	var gentle := false
	var chase := false
	var traffic: PlayTraffic
	## Every raid as [at, cars, level]; the cordon's patrol cars asked for and sent away; how
	## often the chase was called off.
	var raids: Array = []
	var cordon: Array = []
	var left := 0
	var stood_down := 0

	func raid(at: Vector3, n: int, lvl := 2) -> int:
		raids.append([at, n, lvl])
		return n

	func chasing() -> bool:
		return chase

	func scene_car(_e: int, _lane: int, _s: float, at: Vector3, yaw: float, _shape: int) -> Driver:
		var d := traffic.make(at, yaw)
		d.patrol = true
		cordon.append(d)
		return d

	func scene_leave(d: Driver) -> void:
		d.active = false
		left += 1

	func stand_down() -> void:
		chase = false
		stood_down += 1


## car.gd's part the meet reads and writes.
class PlayCar extends CharacterBody3D:
	var top_mult := 1.0
	var accel_mult := 1.0
	var nitro_owned := false
	var nitro_on := false
	var nitro_charge := 0.4
	var max_speed := 30.0
	var accel := 15.0
	var vel := Vector3.ZERO
	var throttle := 0.0
	var steer := 0.0
	var target_dir := Vector3.FORWARD


var problems: Array[String] = []
var verbose := false
## The play's stand-ins and inputs.
var _m: Meet
var _hud: Fakes.Hud
var _bubbles: Fakes.Bubbles
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _traffic: PlayTraffic
var _police: PlayPolice
var _car: PlayCar
var _director: Activities
var _other: Activity
var _hour := 12.0
var _world_free := true
## How often the meet put the car back on the line, the checks made, the nights played.
var _placed := 0
var _plays := 0
var _nights := 0


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
	var sp: Dictionary = data.get("spawn", {})
	_check_map(g, map, data.get("origin", [52.234, 21.024]), digest, Vector2(float(sp.get("x", 0.0)), float(sp.get("z", 0.0))))
	_check_clear(data, digest)
	_check_drag_hud(digest)
	await _play(g, data.get("origin", [52.234, 21.024]), digest)
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
	# The genre's grades (F 2026-11-08): yellow is good, before it early, green perfect, long on
	# the limiter late; the launch by the revs at green.
	var grades := [Meet.shift_grade_at(0.5, -1.0), Meet.shift_grade_at(Meet.SHIFT_SHOW + 0.01, -1.0),
			Meet.shift_grade_at(0.97, 0.1), Meet.shift_grade_at(1.0, Meet.PERFECT + 0.1), Meet.shift_grade_at(1.0, Meet.GOOD_LATE + 0.2)]
	if grades != ["early", "good", "perfect", "good", "late"]:
		problems.append("shift grades at the needle wrong: %s" % str(grades))
	var launches := [Meet.launch_grade(0.2), Meet.launch_grade((Meet.LAUNCH.x + Meet.LAUNCH.y) * 0.5), Meet.launch_grade(1.0)]
	if launches != ["bog", "perfect", "spin"]:
		problems.append("launch grades wrong: %s" % str(launches))
	# Holding the gas from the first amber overshoots the launch zone by green: the launch is a skill.
	var revs_at_green := minf(1.0, Meet.REV_UP * (3.0 * Meet.TREE_STEP))
	if Meet.launch_grade(revs_at_green) != "spin":
		problems.append("gas held from the first amber lands a %s launch" % Meet.launch_grade(revs_at_green))
	for st: int in Meet.Stage.values():
		var want: bool = not (st in [Meet.Stage.NONE, Meet.Stage.RESULT])
		if Meet.can_quit(st) != want:
			problems.append("quit in %s: %s (PT-52)" % [Meet.STAGES[st], Meet.can_quit(st)])
	digest.append("clock, pay, shifts, quit")


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
func _real_run(react: float, delay: float, handling := 0) -> Array:
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
	car.set_handling(handling)
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
	# The Grounded handling (car.gd GROUNDED) pulls the same, so the drag stays fair in it too.
	var g_clean: Array = await _real_run(0.46, 0.15, Car.Handling.GROUNDED)
	var g_lazy: Array = await _real_run(0.6, 0.9, Car.Handling.GROUNDED)
	if float(g_clean[0]) >= float(g_clean[1]) or float(g_lazy[0]) <= float(g_lazy[1]):
		problems.append("in Grounded the clean run (%.2f s) and the lazy one (%.2f s) don't straddle Tadek (%.2f s)"
				% [g_clean[0], g_lazy[0], g_clean[1]])
	if absf(float(g_clean[0]) - float(clean[0])) > 0.15:
		problems.append("the drag in Grounded (%.2f s) differs from Cruise (%.2f s)" % [g_clean[0], clean[0]])
	digest.append("Grounded: clean %.2f, lazy %.2f s" % [g_clean[0], g_lazy[0]])


func _check_map(g: LaneGraph, map: Node3D, origin: Array, digest: PackedStringArray, spawn: Vector2) -> void:
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
	# The start (F 2026-11-11): Darek on Parkingowa by Rondo Dmowskiego, past the start beacon's
	# reach from the spawn (so nothing of it is in the first view) and a short drive from it.
	var st := Meet.find_start(g, origin)
	if st.is_empty():
		problems.append("the start isn't on the map (no kerb on %s)" % Meet.START["street"])
	else:
		var sd := spawn.distance_to(Vector2(st["at"].x, st["at"].z))
		if sd <= Story.BEACON_R + 20.0 or sd > 700.0:
			problems.append("the start is %.0f m from the spawn (want %.0f..700 m)" % [sd, Story.BEACON_R + 20.0])
		digest.append("start on %s %.0f m from the spawn" % [st["street"], sd])


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _check_clear(data: Dictionary, digest: PackedStringArray) -> void:
	var origin: Array = data.get("origin", [52.234, 21.024])
	var reach := Meet.RING_R + 4.0
	for row: Dictionary in Meet.MEETS:
		var ll: Array = row["ll"]
		var c := Meet.Notebook.project(origin, float(ll[0]), float(ll[1]))
		var near := INF
		var what := ""
		for key: String in ["lines", "guards", "walls", "buildings"]:
			for item: Variant in data.get(key, []):
				var p: Array = item["p"] if item is Dictionary else item
				if p.size() < 4 or absf(float(p[0]) - c.x) > 600.0 or absf(float(p[1]) - c.y) > 600.0:
					continue
				for i in range(0, p.size() - 3, 2):
					var dd := _seg_dist(c, Vector2(p[i], p[i + 1]), Vector2(p[i + 2], p[i + 3]))
					if dd < near:
						near = dd
						what = "%s %s" % [key, item.get("k", item.get("kind", "")) if item is Dictionary else ""]
		if near < reach:
			problems.append("meet %s: a %s %.1f m from the middle (want %.0f m clear)" % [row["id"], what, near, reach])
	digest.append("rings clear")


func _check_drag_hud(digest: PackedStringArray) -> void:
	var last := -1.0
	for i in 11:
		var f := Meet.DragTacho.dial(i / 10.0)
		if f <= last:
			problems.append("the tacho's dial doesn't rise at %.1f" % (i / 10.0))
		last = f
	if Meet.DragTacho.dial(Meet.SHIFT_AT) >= Meet.DragTacho.dial(1.0) or Meet.DragTacho.dial(1.0) >= 1.0:
		problems.append("the tacho's green zone or limiter doesn't fit the dial")
	if Meet.gate_mesh(8.4).get_surface_count() != 1:
		problems.append("the start gate isn't one surface")
	var tree := Meet.DragTree.new()
	var words := PackedStringArray()
	for a in 4:
		tree.ambers = a
		words.append(tree.count_text())
	tree.green = true
	words.append(tree.count_text())
	tree.free()
	if words != PackedStringArray(["", "3", "2", "1", "START!"]):
		problems.append("the count reads %s" % str(words))
	digest.append("tacho, gate, count")


# --- the play ---------------------------------------------------------------------------------

## One frame of the car on the strip: the player's gas (0..1) and nitro, held as main.gd holds
## them through the meet's `hold_car`, then the car moves by its own tune. Call it before the
## meet's `_process` on every frame from the line to the result card.
func _drive(meet: Node, car: PlayCar, gas: float, nitro: bool, dt: float) -> void:
	car.throttle = gas
	car.nitro_on = nitro and car.nitro_owned
	car.target_dir = Vector3(sin(0.3), 0.0, -cos(0.3))
	car.steer = 0.4
	meet.hold_car(car)
	var cap: float = car.max_speed * car.top_mult
	var speed := car.vel.length()
	if car.throttle > 0.0 and speed < cap:
		speed = minf(cap, speed + car.accel * car.accel_mult * (1.5 if car.nitro_on else 1.0) * car.throttle * dt)
	elif speed > cap:
		speed = maxf(cap, speed - 30.0 * dt)
	elif car.throttle <= 0.0:
		speed = maxf(0.0, speed - 4.0 * dt)
	if car.nitro_on:
		car.nitro_charge = maxf(0.0, car.nitro_charge - 0.2 * dt)
	car.vel = car.target_dir * speed
	car.global_position += car.vel * dt


## One frame of the racers on the road: each loses road at its own pace; one with none left has
## arrived. Set `d.left` yourself to decide who gets there first.
func _roll(traffic: PlayTraffic, dt: float) -> void:
	for d: Driver in traffic.all:
		if d.racing and d.active:
			d.left -= (14.0 + d.id * 1.5) * dt
			if d.left <= 0.0:
				d.arrived = true


func _ok(cond: bool, what: String) -> void:
	_plays += 1
	if not cond:
		problems.append("the play: " + what)


func _make(g: LaneGraph, origin: Array) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var map := PlayMap.new()
	world.add_child(map)
	_hud = Fakes.Hud.new()
	_bubbles = Fakes.Bubbles.new()
	var talk := Fakes.Dialogue.new()
	talk.bubbles = _bubbles
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	_traffic = PlayTraffic.new()
	_police = PlayPolice.new()
	_police.traffic = _traffic
	_car = PlayCar.new()
	for node: Node in [_hud, _bubbles, talk, _wallet, _calls, _traffic, _police, _car]:
		world.add_child(node)
	_m = Meet.new()
	_m.hud = _hud
	_m.dialogue = talk
	_m.wallet = _wallet
	_m.map = map
	_m.graph = g
	_m.traffic = _traffic
	_m.police = _police
	_m.car = _car
	_m.origin = origin
	_m.vehicle = _vehicle
	_m.calendar = _calendar
	_m.place_car = _place
	world.add_child(_m)
	_m.setup(world, 7)
	_m.set_process(false)
	_director = Activities.new()
	_director.world_free = func() -> bool: return _world_free
	_director.add(_m)
	_other = Activity.new()
	_director.add(_other)
	_director.add(_calls)  # the rescue line joins last, as in main.gd (M1)


func _vehicle() -> Array:
	return [_car.global_position, _car.vel.length() * 3.6, false]


func _calendar() -> Dictionary:
	return {"hour": _hour, "weekday": 5}


## main.gd's `_place_car`: the car at `at`, standing; counted.
func _place(at: Vector3, yaw: float) -> void:
	_car.global_position = at
	_car.rotation.y = yaw
	_car.vel = Vector3.ZERO
	_placed += 1


func _park_at(at: Vector3) -> void:
	_car.global_position = at
	_car.vel = Vector3.ZERO


## `seconds` of frames with the car standing (the racers rolling).
func _frames(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_roll(_traffic, DT)
		_m._process(DT)


## Frames with real engine frames in between, for the script's own timers.
func _real(seconds: float) -> void:
	for i in roundi(seconds / DT):
		await process_frame
		_roll(_traffic, DT)
		_m._process(DT)


## Frames until `cond` holds (checked after each frame); false when `limit` s ran out.
func _until(cond: Callable, limit: float) -> bool:
	if cond.call():
		return true
	for i in roundi(limit / DT):
		_roll(_traffic, DT)
		_m._process(DT)
		if cond.call():
			return true
	return false


## The same with the player's gas held through the meet's `hold_car` (from the line to the card).
func _driven(seconds: float, gas: float, nitro := false) -> void:
	for i in roundi(seconds / DT):
		_drive(_m, _car, gas, nitro, DT)
		_roll(_traffic, DT)
		_m._process(DT)


func _drive_until(cond: Callable, limit: float, gas: float, nitro := false) -> bool:
	if cond.call():
		return true
	for i in roundi(limit / DT):
		_drive(_m, _car, gas, nitro, DT)
		_roll(_traffic, DT)
		_m._process(DT)
		if cond.call():
			return true
	return false


func _in(stage: int) -> bool:
	return _m.phase == Activity.Phase.RUN and _m.stage == stage


func _toast(text: String) -> bool:
	for t in _hud.toasts:
		if text in t:
			return true
	return false


func _said(pl: String) -> bool:
	return pl in _bubbles.said


func _glided() -> bool:
	for r in _m._racers:
		if not (r["glide"] as Dictionary).is_empty():
			return false
	return true


## The dice `_show_meet` draws for the crowd: where the ring of people starts, then each one's
## angle and distance.
func _crowd_dice(dice: RandomNumberGenerator) -> void:
	dice.randf()
	for k in Meet.CROWD:
		dice.randf_range(-0.12, 0.12)
		dice.randf_range(-0.8, 0.8)


## The call answered and JADĘ! pressed.
func _accept() -> void:
	_hud.toasts.clear()
	_m.ring()
	_hud.press(0)
	_hud.press(0)
	_nights += 1


## A night begun at `beat` by the test flag's jump.
func _jump(beat: String) -> void:
	_calls.paused = false
	_hud.toasts.clear()
	_m.jump(beat)
	_nights += 1


## Everything put down: idle, nothing up, the dice drawn.
func _clean(what: String) -> void:
	var m := _m
	_ok(m.phase == Activity.Phase.IDLE and m.stage == Meet.Stage.NONE and m.idle() and not m.busy() and not m.under_way(), what + ": idle")
	_ok(_hud.card == "" and _hud.status == "" and _hud.pill == "", what + ": no card, status line or pill")
	_ok(not m.has_target() and not m._beacon.visible and _director.targeted() == null, what + ": no target, no ring")
	_ok(not m._scene.visible and not m._gate.visible and not m._tree.visible and not m._tacho.visible, what + ": scene, gate, tree, tacho down")
	_ok(m._racers.is_empty() and m._cordon.is_empty() and _hud.dots == 0 and not _hud.hush, what + ": racers, cordon, dots, hush gone")
	_ok(m.call_in >= Meet.NEXT_CALL.x - 1.0 and m.call_in <= Meet.NEXT_CALL.y, what + ": the next call drawn (%.0f s)" % m.call_in)


## The car's own tune and nitro given back.
func _tune(what: String) -> void:
	_ok(is_equal_approx(_car.top_mult, 1.0) and is_equal_approx(_car.accel_mult, 1.0) and not _car.nitro_owned and not _car.nitro_on \
			and is_equal_approx(_car.nitro_charge, 0.4) and not _police.gentle, what + ": the car's tune, nitro and the police back")


## The ✕ in `label`'s stage: the words, the stand-down, everything down.
func _quit(label: String) -> void:
	var m := _m
	var down := _police.stood_down
	_hud.toasts.clear()
	_hud.abort_pressed.emit()
	_ok(_toast("Spoko, następnym razem"), "the ✕ in %s: the quit toast" % label)
	_ok(_police.stood_down == down + 1, "the ✕ in %s: the chase called off" % label)
	_clean("the ✕ in " + label)
	_tune("the ✕ in " + label)
	_ok(not _calls._held(), "the ✕ in %s: the rescue calls back" % label)
	_ok(m._cordon.is_empty(), "the ✕ in %s: the cordon gone" % label)


func _play(g: LaneGraph, origin: Array, digest: PackedStringArray) -> void:
	_make(g, origin)
	var m := _m
	var dice := RandomNumberGenerator.new()
	dice.seed = 7
	var first := dice.randf_range(Meet.FIRST_CALL.x, Meet.FIRST_CALL.y)
	_ok(m.call_in == first and m._rng.state == dice.state, "setup draws the first call from the seed")
	_ok(m.idle() and not m.busy() and not m.under_way() and not m.has_target() and m.target_position() == Vector3.INF and m.stop_spot() == Vector3.INF, "at rest: idle, not busy, no target")
	_ok(m.meets.size() == 2 and bool(m.strip.get("ok", false)) and _director.list.has(m) and m.free_now.is_valid(), "the real graph gives both meets and the strip; the director has it")

	# 1. Darek's clock.
	_hour = 12.0
	var t0: float = m.call_in
	_frames(2.0)
	_ok(m.call_in == t0, "by day (12 h) the clock stands")
	_hour = 23.0
	_world_free = false
	_frames(2.0)
	_ok(m.call_in == t0, "the director says not free: the clock stands")
	_world_free = true
	m.auto = false
	_frames(2.0)
	_ok(m.call_in == t0, "auto off: the clock stands")
	m.auto = true
	_frames(2.0)
	_ok(m.call_in < t0 - 1.5 and m.call_in > t0 - 2.5, "at night (23 h), free and auto: the clock counts (%.2f s of 2)" % (t0 - m.call_in))
	_hour = 12.0
	m.force = true
	t0 = m.call_in
	_frames(2.0)
	_ok(m.call_in < t0 - 1.5, "with force it counts by day")
	m.force = false
	_hour = 23.0
	m.call_in = 0.4
	_hud.toasts.clear()
	_frames(1.0)
	_ok(m.phase == Activity.Phase.RING and _hud.card.contains("DZWONI") and m.call_in <= 0.0, "the clock runs out: the phone rings")
	_hour = 12.0
	_ok(not m.ring() and not m.meet_in_person(), "while it rings, ring() and meet_in_person() say no")
	_ok(not m.busy() and not m.idle(), "a ringing phone is not busy, and not idle")

	# 2. The call and the offer.
	_hud.abort_pressed.emit()
	_ok(m.phase == Activity.Phase.RING and _hud.card.contains("DZWONI"), "the ✕ does nothing on a call")
	_frames(Meet.RING_LIFE + 0.5)
	var drawn := dice.randf_range(Meet.NEXT_CALL.x, Meet.NEXT_CALL.y)
	_ok(m.phase == Activity.Phase.IDLE and _toast("Nieodebrane połączenie") and _hud.card == "", "a call nobody answers goes after RING_LIFE: the missed-call toast, idle")
	_ok(m._rng.state == dice.state and m.call_in <= drawn and m.call_in > drawn - 40.0, "the dice: the missed call draws call_in once (%.0f s)" % m.call_in)
	m.call_in = 900.0
	var state: int = m._rng.state
	_hud.toasts.clear()
	_ok(m.ring() and m.phase == Activity.Phase.RING, "ring() rings (--meet-call)")
	_hud.press(1)
	_ok(m.idle() and _toast("Odrzucono") and _hud.card == "" and m._rng.state == state, "a declined call: its toast, idle, no dice")
	_hud.toasts.clear()
	m.ring()
	_hud.press(0)
	_ok(m.phase == Activity.Phase.OFFER and m.busy() and not m.idle() and _hud.card.contains("DAREK"), "the offer card: busy from here")
	_ok(not m.under_way(), "the offer card: the night is not under way yet (the clock jumps at JADĘ!)")
	_hud.abort_pressed.emit()
	_ok(m.phase == Activity.Phase.OFFER and _hud.card.contains("DAREK"), "the ✕ does nothing on an offer")
	_hud.press(1)
	_ok(m.idle() and _toast("Dobra. Ale jak Lena") and _hud.card == "" and m._rng.state == state, "a declined offer: its toast, idle, no dice")
	_hud.toasts.clear()
	m.ring()
	_hud.press(0)
	_frames(Meet.RING_LIFE + 0.5)
	_ok(m.idle() and _toast("Nieodebrane połączenie") and _hud.card == "" and m._rng.state == state, "an offer nobody answers: the missed-call toast, idle")
	var saved: Array[Dictionary] = m.meets.duplicate()
	var one: Array[Dictionary] = [saved[0]]
	m.meets = one
	_ok(not m.ring() and not m.meet_in_person(), "with one meet there is no call and no meeting")
	m.meets = saved
	var strip_saved: Dictionary = m.strip
	m.strip = {"ok": false}
	_ok(not m.ring() and not m.meet_in_person(), "with no strip there is no call and no meeting")
	m.strip = strip_saved
	_ok(m.idle() and _hud.card == "", "refused rings left nothing up")

	# 3. JADĘ!: night 1.
	var gap: Vector3 = m.meets[0]["gap"]
	_park_at(Vector3(400.0, 0.0, 400.0))
	_calls.paused = false
	_accept()
	_ok(m.phase == Activity.Phase.RUN and m.stage == Meet.Stage.TO_MEET and m.under_way() and m.busy() and _director.busy(), "JADĘ!: the night is under way")
	_crowd_dice(dice)
	for k in Meet.RING_CARS:
		dice.randi()
	_ok(m._rng.state == dice.state, "the dice: JADĘ! draws the crowd's places and a shape for each parked car")
	_ok(_calls._held() and m.nights == 1, "the rescue calls held, the night counted")
	_ok(_toast("Jedź na spot") and _hud.card == "", "the toast, the cards down")
	_ok(m._scene.visible and _traffic.count("add_parked_car") == Meet.RING_CARS and m._racers.size() == Meet.RING_CARS + 2, "the scene is up with RING_CARS parked cars from the traffic, Darek and Lena")
	_ok(m._bawarka.visible and m._porsze.visible and m._crowd.visible, "Darek's Bawarka, Lena's Porszę and the crowd are up")
	var person: Node3D = m._beacon.get("_person")
	_ok(m._beacon.visible and is_equal_approx(float(m._beacon.get("_ring_radius")), Meet.MEET_R * 0.7) and not person.visible \
			and m._beacon.global_position.is_equal_approx(gap), "the ring in the gap, MEET_R * 0.7, nobody in it")
	_ok(not bool(m._beacon.get("waving")), "the club's ring does not wave")
	_ok(m.has_target() and m.target_position() == gap and m.target_colour() == Meet.COLOUR and _director.targeted() == m and m.stop_spot() == Vector3.INF, "the arrow's target is the gap itself; no stop assist")
	_frames(0.6)
	_ok(_hud.status_title.begins_with("PLAC DEFILAD") and _hud.status_title.contains("SPOT") and _hud.status == "Stań w luce między autami" and _hud.tint == Meet.COLOUR, "the status line: PLAC DEFILAD · SPOT")
	_ok(_hud.distance == "%d m" % roundi(Vector2(400.0, 400.0).distance_to(Vector2(gap.x, gap.z))) and _hud.progress == 0.0 and _hud.badge == "", "the status line: the metres to the gap, an empty bar, no badge (%s)" % _hud.distance)
	var drawn0: int = _hud.lines
	_frames(1.0)
	_ok(_hud.lines - drawn0 >= 3 and _hud.lines - drawn0 <= 5, "the stages run on the quarter-second step (%d status lines in a second)" % (_hud.lines - drawn0))
	_ok(not _director.may_start(_other) and not _other.free_now.call(), "under way: the director refuses another activity")

	# 4. Stopping in the gap, the talk, the raid.
	_park_at(gap)
	_frames(0.6)
	_ok(_in(Meet.Stage.TO_MEET) and _hud.progress > 0.2 and _hud.progress < 1.0 and _hud.distance == "0 m", "standing in the gap fills the status line's bar (%.2f)" % _hud.progress)
	_ok(_until(_in.bind(Meet.Stage.MEET), 3.0), "stopped in the gap: the club is at the meet")
	_ok(not m.has_target() and not m._beacon.visible and _hud.status == "", "at the meet: no target, no status line")
	_ok(_until(_in.bind(Meet.Stage.RAID), 20.0), "the club talks, then the sirens")
	var talked := true
	for l: Array in Meet.MEET_LINES:
		talked = talked and _said(String(l[1]))
	_ok(talked, "the club said all of MEET_LINES")
	_ok(_hud.banners.has("NALOT!") and _police.raids.size() == 1 and int(_police.raids[0][1]) == Meet.RAID_CARS and int(_police.raids[0][2]) == Meet.RAID_LEVEL, "the banner NALOT!, police.raid once with RAID_CARS at RAID_LEVEL")
	_ok(_police.cordon.size() == Meet.CORDON and m._cordon.size() == Meet.CORDON, "CORDON patrol cars asked for")
	_ok(m._crowd_run > 0.0 and not m._drifting and not m._tandem and not _glided(), "the crowd runs, the drift stops, every racer starts to glide")
	_frames(0.1)
	_ok(_hud.dots == m._racers.size(), "the racers show on the minimap")
	await _real(1.8)
	_ok(_hud.banner == "", "the banner goes after 1.6 s")

	# 5. The pin, the race.
	_ok(_until(_in.bind(Meet.Stage.RACE), 10.0), "PIN_AFTER s after the sirens the race begins")
	_ok(_hud.notes.size() == 1 and _hud.notes[0].begins_with("TYGRAM · WNRC"), "the TYGRAM note")
	var goal: Vector3 = m.meets[1]["at"]
	_ok(m.has_target() and m.target_position() == goal and m.target_colour() == Meet.PIN_COLOUR and _director.targeted() == m, "the race's target is meet 2's middle, in PIN_COLOUR")
	_ok(Color(m._beacon.get("_colour")) == Meet.PIN_COLOUR and is_equal_approx(float(m._beacon.get("_ring_radius")), Meet.ARRIVE_R * 0.6), "the ring is recoloured, ARRIVE_R * 0.6")
	_ok(_until(_glided, 40.0), "every racer reaches the road")
	# Racer AI step 6b part 1b: each racer drives its own CLUB profile (ladder.gd) on the race
	# session, with a plan, in the player's own car (its top, never over it).
	var handed := true
	var lamps := 0
	var top: float = _car.max_speed * _car.top_mult
	for r in m._racers:
		var d: Driver = r["d"]
		var club := Meet.Ladder.club(int(r["glow"]))
		handed = handed and d != null and d.persistent and not d.parked and d.racing and d.plan != null and is_equal_approx(d.race_top, top) \
				and d.race_share == float(club["share"]) and d.race_accel == float(club["race_accel"]) and d.race_lat == float(club["lat"]) \
				and d.race_brake == float(club["brake"]) and d.race_block == float(club["block"]) \
				and d.speed_factor == Meet.Ladder.CLUB_PACE.x and d.accel_factor == Meet.Ladder.CLUB_PACE.y and d.cuts is Dictionary and not (d.cuts as Dictionary).is_empty()
		if r.get("lamps") is Node3D and (r["lamps"] as Node3D).get_node_or_null("brake") != null:
			lamps += 1
	_ok(handed, "the racers are in traffic: unparked, persistent, racing with a plan, each its CLUB profile at the player's top, the club's pace, every shortcut")
	_ok(lamps == m._racers.size(), "every racer has its race lights (%d of %d)" % [lamps, m._racers.size()])
	_ok(_traffic.count("unpark") == Meet.RING_CARS and _traffic.count("add_node_driver") == 2 and _traffic.count("race_to") == Meet.RING_CARS + 2, "pool cars unparked, Darek and Lena node drivers, race_to for all")
	_frames(0.6)
	_ok(_hud.badge == "1ST" and _hud.status_title.contains("WYŚCIG") and _hud.status == "Bądź pierwszy na miejscu", "nobody ahead: the badge 1ST")
	_ok(_hud.tint == Meet.PIN_COLOUR, "the race's status line is in the pin's colour")
	# The race lasts longer than a raid's PIN_AFTER: the second raid must count its own time.
	_frames(Meet.PIN_AFTER)
	var ahead0: Driver = m._racers[0]["d"]
	var ahead1: Driver = m._racers[1]["d"]
	ahead0.left = 5.0
	ahead1.left = 5.0
	_frames(0.6)
	_ok(_hud.badge == "3/9", "two ahead: the badge 3/9 (%s)" % _hud.badge)
	var money: int = _wallet.money
	var respect: int = _wallet.respect
	_hud.toasts.clear()
	dice.state = m._rng.state
	_park_at(goal)
	_ok(_until(_in.bind(Meet.Stage.MEET2), 3.0), "inside ARRIVE_R: the race is done, meet 2")
	_crowd_dice(dice)
	_ok(m._rng.state == dice.state, "the dice: meet 2 draws its crowd's places and no cars")
	var pay: Array = Meet.place_pay(3)
	_ok(m.place == 3 and m.last_pay == pay and _wallet.money == money + int(pay[0]) and _wallet.respect == respect + int(pay[1]) and "meet_race" in _wallet.kinds, "third place pays place_pay(3)")
	_ok(_toast("3. MIEJSCE") and not m.has_target() and _hud.status == "", "the toast, no target, no status line")
	_ok(m.meet_i == 1 and m._tandem and m._drifting and m._skajlajner.visible and m._scene.visible, "meet 2 is up with the tandem and Tadek's car")
	var parked := true
	for r in m._racers:
		if r["d"] != null:
			parked = parked and (r["d"] as Driver).parked
	_ok(parked, "the racers who have drivers are parked in the new ring")
	var lamps_left := 0
	for r in m._racers:
		lamps_left += 1 if r.has("lamps") or r.has("r") else 0
	_ok(m._race == null and lamps_left == 0, "the race is over: its session and every racer's lights gone")

	# 6. Meet 2, the second raid, the pin to the drag.
	_ok(_until(_in.bind(Meet.Stage.RAID2), 20.0), "meet 2 talks, then the sirens")
	var talked2 := true
	for l: Array in Meet.MEET2_LINES:
		talked2 = talked2 and _said(String(l[1]))
	_ok(talked2, "the club said all of MEET2_LINES")
	_ok(_police.raids.size() == 2 and _hud.banners.count("NALOT!") == 2 and _police.cordon.size() == 2 * Meet.CORDON and m._cordon.size() == Meet.CORDON and _police.left == Meet.CORDON, "the second raid: its cordon, the first one sent away")
	_frames(Meet.PIN_AFTER - 1.5)
	_ok(_in(Meet.Stage.RAID2), "the second raid counts its own PIN_AFTER s (not on from the race's)")
	_ok(_until(_in.bind(Meet.Stage.TO_DRAG), 12.0), "the pin to the drag")
	var watch: Vector3 = m.strip["watch"]
	_ok(_hud.notes.size() == 2 and m._gate.visible and m._gate.mesh != null and not m._scene.visible and m._racers.is_empty() and _hud.dots == 0, "the note, the gate, the scene and the racers gone")
	_ok(m.has_target() and m.target_position() == watch and m._beacon.global_position.is_equal_approx(watch) and is_equal_approx(float(m._beacon.get("_ring_radius")), Meet.MEET_R), "the target is the start, ring MEET_R")
	_traffic.seen = false
	_frames(0.6)
	_ok(m._cordon.is_empty() and _police.left == 2 * Meet.CORDON and not m._flash.visible, "the cordon leaves once out of sight")
	_traffic.seen = true
	var on_strip := _traffic.spawn(m.strip_at(60.0))
	var off_strip := _traffic.spawn(Vector3(5000.0, 0.0, 5000.0))
	_park_at(watch)
	_ok(_until(_in.bind(Meet.Stage.WATCH), 3.0), "stopped at the start: the exhibition pairs launch")
	_ok(m._shows.size() == 2 and _said(String(Meet.DRAG_LINES["watch"][1])), "two pairs, Darek's line")
	_ok(not m.has_target() and not m._beacon.visible and _hud.pill == "", "while they run: no target, no pill")
	_ok(_until(func() -> bool: return m._shows.is_empty(), 60.0), "the pairs run their quarter mile and go")
	_ok(m.has_target(), "the arrow to the line the moment they are gone")
	_frames(0.6)
	_ok(_hud.pill == "drag" and _hud.pill_word == "START DRAG" and m._beacon.visible and is_equal_approx(float(m._beacon.get("_ring_radius")), Meet.LINE_R * 0.6) \
			and m.target_position().is_equal_approx(m.strip_at(0.0)) and _hud.status == "Stań na linii pod bramą", "then the START DRAG pill and the ring on the line")

	# 7. On the line (the pill's button), the launch, the shifts.
	var placed0 := _placed
	var nitro_before: bool = _car.nitro_owned
	_hud.toasts.clear()
	dice.state = m._rng.state
	_hud.context_pressed.emit("drag")
	_ok(m.stage == Meet.Stage.LINE and _hud.pill == "" and not m.has_target() and _placed == placed0 + 1, "START DRAG: on the line, the car put there once")
	dice.randf_range(0.0, Meet.TREE_JITTER)
	_ok(m._rng.state == dice.state, "the dice: the tree draws its jitter once")
	_ok(m._tree.visible and m._tacho.visible and m._tacho.staging and m._gate.visible, "the tree and the tacho are up")
	_ok(not nitro_before and _car.nitro_owned and _car.nitro_charge == 1.0, "the nitro on loan")
	_ok(is_equal_approx(_car.top_mult, Meet.DRAG_TOP * float(Meet.GEARS[0])), "the car's top held to first gear")
	_ok(_hud.hush and _bubbles.cleared >= 1 and _bubbles.quiet_all and _police.gentle, "the quiet screen on, the bubbles cleared, the police gentle")
	_ok(not on_strip.active and off_strip.active, "the traffic on the strip is cleared, the rest stays")
	# Coast, then gas for the last 0.73 s: the revs land in the launch zone at green.
	_driven(2.67, 0.0)
	_ok(_car.vel == Vector3.ZERO and m.stage == Meet.Stage.LINE, "on the line the car stays (no false start by gas)")
	_ok(_drive_until(func() -> bool: return m.stage == Meet.Stage.DRAG, 3.0, 1.0), "green after TREE_PRE + 3 * TREE_STEP")
	_ok(m._tree.green and not m._tacho.staging and m._boost_t > 0.0 and Meet.launch_grade(m._revs) == "perfect", "the revs in the launch zone (%.2f): a perfect launch, a burst" % m._revs)
	var gears_ok := true
	for k in 3:
		var top_before := _car.top_mult
		var reached := _drive_until(func() -> bool: return m._shift_w >= 0.0, 12.0, 1.0)
		var pill_up := _hud.pill == "drag_shift"
		_hud.context_pressed.emit("drag_shift")
		_driven(0.05, 1.0)
		gears_ok = gears_ok and reached and pill_up and m._gear == k + 1 and m._boost_t > 0.0 and _hud.pill == "" \
				and is_equal_approx(_car.top_mult, Meet.DRAG_TOP * float(Meet.GEARS[k + 1])) and _car.top_mult > top_before
	_ok(gears_ok, "three perfect shifts: the pill, the gear, a burst, the car's tune with the gear")
	money = _wallet.money
	respect = _wallet.respect

	# 8. The ends: the win.
	_ok(_drive_until(_in.bind(Meet.Stage.RESULT), 30.0, 1.0), "across 402 m")
	_ok(m.drag_won and _hud.card == "RESPEKT!" and _hud.buttons == 1 and m.drag_time > 0.0, "before Tadek: RESPEKT!, one button (%.2f s)" % m.drag_time)
	_ok(_wallet.money == money + int(Meet.DRAG_PAY[0]) and _wallet.respect == respect + int(Meet.DRAG_PAY[1]) and "meet_drag" in _wallet.kinds, "DRAG_PAY paid")
	_ok(bool(_wallet.keep.get("wnrc_member", false)) and int(_wallet.keep.get("wnrc_wins", 0)) == 1 and is_equal_approx(float(_wallet.best.get("drag_402", -1.0)), m.drag_time), "the club card kept, the record")
	_tune("the win")
	_ok(not m._tacho.visible and not m._tree.visible and not _hud.hush and _hud.pill == "", "the tacho, tree, pill and quiet screen down")
	_hud.abort_pressed.emit()
	_ok(m.stage == Meet.Stage.RESULT and _hud.card == "RESPEKT!", "the ✕ does nothing on the result card")
	dice.state = m._rng.state
	_hud.press(0)
	_clean("OK after the win")
	var next_call := dice.randf_range(Meet.NEXT_CALL.x, Meet.NEXT_CALL.y)
	_ok(m._rng.state == dice.state and m.call_in == next_call, "the dice: the night's end draws the next call once (%.0f s)" % m.call_in)
	_ok(not _calls._held() and _wallet.keep.has("wnrc_member"), "the rescue calls as they were")
	_ok(_director.may_start(_other), "after the night the director lets another start")
	_ok(_hud.broadcast == 0, "no press went unowned")

	# Night 2: in person, held calls; the loss, REWANŻ, the false start, off the strip.
	_calls.paused = true
	_park_at(Vector3(400.0, 0.0, 400.0))
	var shown: int = _hud.shown
	_ok(m.meet_in_person() and m.stage == Meet.Stage.TO_MEET and m.phase == Activity.Phase.RUN and _hud.shown == shown and _hud.card == "", "meet_in_person() starts the night with no call")
	_nights += 1
	_ok(not _director.may_start(_other) and not m.meet_in_person() and not m.ring(), "the director refuses a second while the night is on; no second start")
	m.jump("drag")
	_ok(_until(func() -> bool: return m._shows.is_empty(), 60.0), "(the jump to the drag) the pairs run and go")
	_park_at(m.strip_at(0.0))
	_ok(_until(_in.bind(Meet.Stage.LINE), 3.0) and _hud.pill == "", "stopping on the line stages the run")
	var tadek_wins := int(_wallet.keep.get("wnrc_wins", 0))
	money = _wallet.money
	respect = _wallet.respect
	_ok(_drive_until(_in.bind(Meet.Stage.RESULT), 45.0, 1.0), "gas and no shifts reach the end")
	_ok(not m.drag_won and _hud.card == "TADEK WYGRAŁ" and _hud.buttons == 2, "after Tadek: TADEK WYGRAŁ, two buttons")
	_ok(_wallet.money == money + int(Meet.DRAG_LOSE[0]) and _wallet.respect == respect + int(Meet.DRAG_LOSE[1]) and int(_wallet.keep.get("wnrc_wins", 0)) == tadek_wins, "DRAG_LOSE paid, no new win")
	_tune("the loss")
	placed0 = _placed
	_hud.press(0)
	_ok(m.stage == Meet.Stage.LINE and _hud.card == "" and _placed == placed0 + 1 and m._tree.visible and _car.nitro_owned \
			and is_equal_approx(_car.top_mult, Meet.DRAG_TOP * float(Meet.GEARS[0])), "REWANŻ: the car back on the line, the tree, the loan, first gear")
	var dir: Vector2 = m.strip["dir"]
	var right: Vector2 = m.strip["right"]
	_car.global_position += Vector3(dir.x, 0.0, dir.y) * 2.0
	_frames(0.1)
	_ok(m.stage == Meet.Stage.RESULT and _hud.card == "FALSTART" and m._tree.visible and m._tree.red and _hud.buttons == 2, "a false start: FALSTART, the tree still up")
	_tune("the false start")
	await _real(2.1)
	_ok(not m._tree.visible, "the tree goes 2 s later")
	_hud.press(0)
	_ok(m.stage == Meet.Stage.LINE, "REWANŻ again")
	_ok(_drive_until(_in.bind(Meet.Stage.DRAG), 5.0, 0.0) and m._bog_t > 0.0 and Meet.launch_grade(m._revs) == "bog", "no gas: a bogged launch")
	_car.global_position += Vector3(right.x, 0.0, right.y) * 12.0
	_driven(0.1, 1.0)
	_ok(m.stage == Meet.Stage.RESULT and _hud.card == "POZA PASEM" and _hud.buttons == 2, "off the strip: POZA PASEM")
	_tune("off the strip")
	_hud.press(1)
	_clean("KONIEC")
	_ok(_calls.paused and _calls._held(), "the rescue calls held before the night stay held")

	# Night 3: the spin, the nitro, the card nobody presses.
	_calls.paused = false
	_jump("stage")
	_ok(_in(Meet.Stage.LINE), "(the jump to the stage) on the line")
	_ok(_drive_until(_in.bind(Meet.Stage.DRAG), 5.0, 1.0) and m._spin_t > 0.0 and Meet.launch_grade(m._revs) == "spin", "gas held from the start: wheelspin")
	_driven(1.0, 1.0, true)
	_ok(_car.nitro_on and _car.nitro_charge < 1.0, "the nitro works on loan")
	_car.global_position += Vector3(right.x, 0.0, right.y) * 12.0
	_driven(0.1, 1.0)
	_ok(m.stage == Meet.Stage.RESULT and _hud.card == "POZA PASEM", "off the strip again")
	_tune("the nitro run")
	placed0 = _placed
	_hud.abort_pressed.emit()
	_ok(m.stage == Meet.Stage.RESULT, "the ✕ does nothing on the result card")
	_frames(Meet.RESULT_LIFE - 1.0)
	_ok(m.stage == Meet.Stage.RESULT and _hud.card == "POZA PASEM", "the card waits")
	_frames(2.0)
	_clean("the card left")
	_ok(_placed == placed0 and not _calls._held(), "the card nobody presses ends the night and does not rematch")

	# 9. The ✕ in every stage under way.
	_calls.paused = false
	m.start()
	_nights += 1
	_quit("TO_MEET")
	for beat: String in ["meet", "raid", "race", "meet2", "drag", "stage"]:
		_jump(beat)
		if beat == "raid":
			_ok(m._cordon.size() == Meet.CORDON, "the jump to the raid boxes the player in")
		_frames(0.3)
		_quit(beat)
	_jump("stage")
	_ok(_drive_until(_in.bind(Meet.Stage.DRAG), 5.0, 1.0), "(the jump to the stage) green")
	_driven(1.0, 1.0)
	_ok(_car.vel.length() > 1.0 and not is_equal_approx(_car.top_mult, 1.0), "(a run past green) the car runs on the drag tune")
	_ok(_drive_until(func() -> bool: return _hud.pill == "drag_shift", 12.0, 1.0), "(a run past green) the shift button comes up")
	_quit("DRAG, the shift button up")
	_jump("drag")
	_ok(_until(func() -> bool: return _hud.pill == "drag", 60.0), "(the jump to the drag) the pairs go, START DRAG is up")
	_quit("WATCH, START DRAG up")

	# The dice after a night whose call came by the clock: two draws, as they always rolled.
	_hour = 23.0
	m.call_in = 0.3
	_frames(0.6)
	_ok(m.phase == Activity.Phase.RING and m.call_in <= 0.0, "(Darek's clock rings again)")
	_hud.press(0)
	_hud.press(0)
	_nights += 1
	_ok(_in(Meet.Stage.TO_MEET), "(JADĘ! again)")
	dice.state = m._rng.state
	_hud.abort_pressed.emit()
	dice.randf_range(Meet.NEXT_CALL.x, Meet.NEXT_CALL.y)
	var again := dice.randf_range(Meet.NEXT_CALL.x, Meet.NEXT_CALL.y)
	_ok(m.idle() and m._rng.state == dice.state and m.call_in == again, "the dice: after a night whose call came by the clock, the next call is drawn twice (%.0f s)" % m.call_in)
	_ok(_hud.broadcast == 0, "no press went unowned in the whole play")
	_other.free()
	digest.append("the play: %d nights, %d checks" % [_nights, _plays])
