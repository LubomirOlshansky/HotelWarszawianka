extends SceneTree
## The city objects plan, step 7 (docs/design/drivable-city-build.md item 3, section 5): the soft
## things (scripts/soft_things.gd) on pure cases, then the map's soft lists on both city paths.
##   T1 the box against a segment: the swept hull and the clip (crossing, missing, end-on, inside);
##   T2 a crossing costs Solidity.smash_cost per panel (fence 6 %, hedge 10 %), from both sides the
##      same, the panels under the car's width and no more;
##   T3 the cap: at most SMASH_CAP within SMASH_CAP_TIME s however many panels go (a long diagonal);
##   T4 a broken panel costs nothing and says nothing the second time;
##   T5 grinding along a line: GRIND_COST a second, the car nudged out at GRIND_NUDGE m/s, the
##      panels touched go down without their crossing cost;
##   T6 no sweep under MIN_SPEED, with the collision mask 0 (the boat, the helicopter, the testing
##      autopilots), or with the car on a deck over the fence;
##   T7 rule B: a panel is repaired only far (over REPAIR_FAR m), out of the camera's view and
##      REPAIR_AFTER s or a dawn after it broke; `repair_near`, `reset`, MEMORY (the oldest goes);
##   T8 the contact log writes a smash as a `soft` contact line, apart from the hard ones;
##   M1 in SECTORS, the runtime build's soft list (map_builder.gd build_sector, the root's "soft"
##      meta) is the prebuilt sector's, number for number, and only S fences and hedges are in it
##      (centrum.json `sc`);
##   M2 `--no-soft`: the builder's faces with CityBarriers.soft_off are the soft build's faces plus
##      SoftThings.hard_faces of its soft list, class by class (the prebuilt path's restore is exact);
##   M3 the settings row (Łamliwe płoty, 2026-11-14), live: a sector loaded with the fences hard (the
##      default) has the --no-soft build's fence and hedge faces, on both paths; `set_soft(true)` takes
##      the restored bodies out (the soft build's faces, the sector swept) and `set_soft(false)` puts
##      them back (the --no-soft faces again, nothing swept, every broken panel standing).
## Step 8a (drivable-city-build.md item 4), the parked cars that are pushed:
##   P1 end-on: square into a car's end the player keeps 0.75 of its speed, the car slides along its
##      length Solidity.push_slide of PUSH_SHARE of it, no spin, one `pushed`, one soft contact line;
##   P2 side: square into its side the same, the car slides sideways; brushing along its side at 5 deg
##      keeps push_keep(sin 5 deg) (0.98) and barely moves it; a hit near an end turns it the way it was
##      pushed (that end goes further than the other); a creep at 1 m/s still moves it, a little;
##   P3 wedged: a wall a hand behind it (the slide clamped under PUSH_WEDGED): nothing pushed, the
##      player's speed untouched, a `parked` box collider where the car stands (car.gd answers it as a
##      wall with the preset's rules), gone once the player is HARD_NEAR m away;
##   P4 a chain of two: the first car slides into the one behind it, which slides on; the two end apart;
##   P5 rest never in a lane: pushed toward a lane it stops short, clear of every lane; with the only
##      clear rest under PUSH_WEDGED (a lane at its nose) it cannot move: a wall; its bay in the lanes
##      and lanes all the way, it is `towed` and hidden out of view; pushed away from the lane it slides
##      as friction stops it;
##   P6 its sector unloaded and loaded again finds it where it was left; back in its bay by rule B (far,
##      out of view, 10 min); `reset` puts every car back;
##   P7 settings off (`no_soft`): the cars' colliders are the builder's (MapBuilder.parked_faces), none
##      swept; turned on live the colliders go and a push moves a car; off again puts them back, the car
##      in its bay;
##   M4 in SECTORS, the runtime and prebuilt "soft_cars" lists are the same and every own car has its
##      instance in its tile's MultiMesh (both paths); M2 and M3 hold the `parked` faces too: settings
##      off, the restored faces are the --no-soft build's (main's builder's), on both paths;
##   M5 the lane rule over the map's cars (SECTORS; --all every sector): each car pushed off both sides
##      and both ends at 8 m/s, no walls: its rest in a lane counted with friction alone (the defect
##      class) and with the rule (what is left is towed); its bay in a lane counted apart (8b's matter).
##   M6 the cost, the prebuilt sector -2,0: three cars sliding, then the player driving past its cars,
##      each under 0.1 ms a frame.
## Prints `check_soft_things: OK (...)` (exit 0) or the problems (exit 1). The map part needs the
## sector split and the prebuilt sectors (tools/setup_map.sh); --all compares every sector (slow).
##   godot --headless --path game --script res://tools/check_soft_things.gd [-- --all --sectors=i,j;i,j --verbose]

const SoftThings := preload("res://scripts/soft_things.gd")
const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const ContactLog := preload("res://scripts/contact_log.gd")
const Car := preload("res://scripts/car.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Fakes := preload("res://tools/fakes.gd")

## The stadium's grounds (3,-1: 127 hedges and 35 fences), Marszałkowska and the spawn (-2,0),
## Powiśle and the river (0,-1), the Old Town (-2,-3).
const SECTORS: Array[Vector2i] = [Vector2i(3, -1), Vector2i(-2, 0), Vector2i(0, -1), Vector2i(-2, -3)]
const DT := 1.0 / 60.0

var problems: Array[String] = []
var verbose := false
## M3: the time the hard restores took (soft_things.gd harden_usec) and how many were made.
var _m3_usec := 0
var _m3_hardens := 0
var _broke: Array = []
var _repaired: Array = []
var _car: Car
var _soft: SoftThings
## Step 8a: the pushes seen ([id, at, dir, speed]) and the cars back in their bays.
var _pushed: Array = []
var _returned: Array = []
## M5's counts.
var _m5 := {"cars": 0, "pushes": 0, "natural": 0, "ruled": 0, "wedged": 0, "bays": 0, "usec": 0}


func _initialize() -> void:
	var all := false
	var cases_only := false
	var only: Array[Vector2i] = []
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
		elif a == "--cases":
			cases_only = true
		elif a == "--all":
			all = true
		elif a.begins_with("--sectors="):
			for part in a.trim_prefix("--sectors=").split(";"):
				var v := part.split_floats(",")
				only.append(Vector2i(int(v[0]), int(v[1])))
	await process_frame  # the root is in the tree from the first frame on (global transforms)
	var t0 := Time.get_ticks_msec()
	_t1_clip()
	_t2_crossing()
	_t3_cap()
	_t4_twice()
	_t5_grind()
	_t6_skips()
	_t7_rule_b()
	_t8_log()
	_p1_end_on()
	_p2_side()
	await _p3_wedged()
	_p4_chain()
	_p5_lanes()
	_p6_bay()
	_p7_settings()
	var cases_ms := Time.get_ticks_msec() - t0
	var map_note := "no map part (--cases)" if cases_only else _map_part(all, only)
	if not cases_only:
		var before := problems.size()
		var m6 := await _m6_cost(SECTORS[1])
		for _try in 2:
			if problems.size() == before:
				break
			problems.resize(before)  # timing on a shared machine: measured again, up to three times
			m6 = await _m6_cost(SECTORS[1])
		map_note += "; M6 " + m6
	if problems.is_empty():
		print("check_soft_things: OK (the cases in %d ms; %s; %d ms)" % [cases_ms, map_note, Time.get_ticks_msec() - t0])
		quit(0)
	else:
		for p in problems:
			print("PROBLEM %s" % p)
		print("check_soft_things: %d problems" % problems.size())
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
	elif verbose:
		print("   ok  %s" % what)


# --- the pure cases ------------------------------------------------------------------------------

## A fence (or hedge) along x from x0 to x1 at z, its foot at y0, `panels` of 2 m.
static func _line(kind: String, x0: float, x1: float, z: float, y0 := 0.0, height := 1.6, id := "test") -> Dictionary:
	var length := x1 - x0
	return {"ids": PackedStringArray([id]), "kinds": PackedStringArray([kind]), "mats": PackedStringArray(["hedge" if kind == "hedge" else "metal"]),
			"panels": PackedInt32Array([ceili(length / CityBarriers.PANEL)]),
			"segs": PackedFloat64Array([0.0, x0, z, x1, z, y0, y0, 0.05, height, 0.0, 1.0])}


## A fresh soft_things with one sector holding `soft`, a real car (car.gd, its own physics off: the
## case moves it) at `at`, heading `yaw`.
func _setup(soft: Dictionary, at: Vector3, yaw: float) -> void:
	if _soft != null:
		_soft.free()
	if _car != null:
		_car.free()
	_soft = SoftThings.new()
	root.add_child(_soft)
	_soft.set_physics_process(false)
	if not soft.is_empty():
		var sec := Node3D.new()
		sec.name = "s_0_0"
		sec.set_meta(&"soft", soft)
		_soft.add_sector(sec)
		sec.free()  # its list is kept (a root leaving the tree drops it; this one never was in)
	_car = Car.new()
	root.add_child(_car)
	_car.set_physics_process(false)
	_car.global_position = at
	_car.rotation.y = yaw
	_soft.car = _car
	_broke.clear()
	_repaired.clear()
	_soft.broke.connect(func(id: String, panel: int, kind: StringName, _at: Vector3, _d: Vector3, _s: float) -> void: _broke.append([id, panel, kind]))
	_soft.repaired.connect(func(id: String, panel: int) -> void: _repaired.append([id, panel]))


## Drives the car at velocity `v` for `frames` frames (it moves by its own vel, as car.gd leaves it).
func _drive(v: Vector3, frames: int) -> void:
	_car.vel = v
	_soft.step(DT)  # the first frame only remembers where the car was
	for _i in frames:
		_car.global_position += _car.vel * DT
		_soft.step(DT)


func _t1_clip() -> void:
	var still := Transform3D(Basis(), Vector3(0, 0, 0))
	var hull := SoftThings.swept_hull(still, Transform3D(Basis(), Vector3(0, 0, -1)), Vector2(0.9, 2.0))
	_expect(hull.size() >= 4, "T1 the swept hull has corners (%d)" % hull.size())
	var across := SoftThings.clip(Vector2(-5, 0), Vector2(5, 0), hull)
	_expect(is_equal_approx(across.x, 0.41) and is_equal_approx(across.y, 0.59), "T1 a segment across the car is cut to its width: %s" % across)
	var miss := SoftThings.clip(Vector2(-5, 4), Vector2(5, 4), hull)
	_expect(miss.x < 0.0, "T1 a segment 4 m off misses: %s" % miss)
	var inside := SoftThings.clip(Vector2(-0.2, -0.5), Vector2(0.2, -0.5), hull)
	_expect(is_equal_approx(inside.x, 0.0) and is_equal_approx(inside.y, 1.0), "T1 a segment inside the hull is whole: %s" % inside)
	var end_on := SoftThings.clip(Vector2(0, 5), Vector2(0, 1.5), hull)
	_expect(end_on.x >= 0.0 and end_on.x < 1.0 and is_equal_approx(end_on.y, 1.0), "T1 a segment ending in the box is cut at the box: %s" % end_on)
	# The swept part counts: the box moved 3 m in one frame covers a segment it jumped over.
	var jump := SoftThings.swept_hull(still, Transform3D(Basis(), Vector3(0, 0, -3)), Vector2(0.9, 2.0))
	_expect(SoftThings.clip(Vector2(-5, -2.5), Vector2(5, -2.5), jump).x >= 0.0, "T1 the hull covers the frame's motion")


func _t2_crossing() -> void:
	for kind in ["fence", "hedge"]:
		var keep_by_side: Array[float] = []
		for side in [1.0, -1.0]:
			_setup(_line(kind, -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0 * side), 0.0 if side > 0.0 else PI)
			_drive(Vector3(0, 0, -15.0 * side), 50)
			var keep := Vector2(_car.vel.x, _car.vel.z).length() / 15.0
			keep_by_side.append(keep)
			var c := Solidity.smash_cost(StringName(kind))
			var want := (1.0 - c) * (1.0 - minf(c, Solidity.SMASH_CAP - c))
			_expect(_broke.size() == 2, "T2 %s from side %+d: two panels under the car's 1.8 m (%d: %s)" % [kind, int(side), _broke.size(), _broke])
			_expect(absf(keep - want) < 0.002, "T2 %s from side %+d: kept %.4f of the speed, want %.4f" % [kind, int(side), keep, want])
		_expect(absf(keep_by_side[0] - keep_by_side[1]) < 0.0005, "T2 %s: both directions cost the same (%s)" % [kind, keep_by_side])


func _t3_cap() -> void:
	var w: Array[Vector2] = []
	var taken := [SoftThings.cap_take(w, 0.0, 0.06), SoftThings.cap_take(w, 0.1, 0.06), SoftThings.cap_take(w, 0.2, 0.06),
			SoftThings.cap_take(w, 0.3, 0.06)]
	_expect(is_equal_approx(taken[0], 0.06) and is_equal_approx(taken[1], 0.06) and is_equal_approx(taken[2], 0.03)
			and is_equal_approx(taken[3], 0.0), "T3 the cap: %s (want 0.06, 0.06, 0.03, 0)" % [taken])
	_expect(is_equal_approx(SoftThings.cap_take(w, 0.75, 0.06), 0.06), "T3 the window lets go after %.1f s" % Solidity.SMASH_CAP_TIME)
	# A long diagonal through a hedge (at 20 deg): many panels, still at most the cap.
	_setup(_line("hedge", -30.0, 30.0, 0.0), Vector3(0, 0, 2.0), 0.0)
	var dir := Vector3(-sin(deg_to_rad(70.0)), 0, -cos(deg_to_rad(70.0)))
	_car.rotation.y = atan2(-dir.x, -dir.z)
	_drive(dir * 20.0, 28)
	var keep := Vector2(_car.vel.x, _car.vel.z).length() / 20.0
	_expect(_broke.size() >= 3, "T3 the diagonal broke several panels (%d)" % _broke.size())
	_expect(keep >= 1.0 - Solidity.SMASH_CAP - 0.0005, "T3 the diagonal kept %.3f of the speed (at least %.2f)" % [keep, 1.0 - Solidity.SMASH_CAP])


func _t4_twice() -> void:
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	var first := _broke.size()
	_broke.clear()
	_car.global_position = Vector3(0.1, 0, 5.0)
	_soft.reset_motion()
	_drive(Vector3(0, 0, -15.0), 50)
	_expect(first == 2 and _broke.is_empty(), "T4 the second pass breaks nothing (first %d, then %d)" % [first, _broke.size()])
	_expect(is_equal_approx(Vector2(_car.vel.x, _car.vel.z).length(), 15.0), "T4 the second pass costs nothing (%.3f m/s)" % _car.vel.length())
	_expect(_soft.is_broken("test", 4) and _soft.is_broken("test", 5) and not _soft.is_broken("test", 6),
			"T4 is_broken names the panels under the car (4, 5)")


func _t5_grind() -> void:
	# Along the fence, the car's side over it, for one second at 10 m/s.
	_setup(_line("fence", -40.0, 40.0, 0.0), Vector3(-20.0, 0, 0.6), -PI * 0.5)
	_drive(Vector3(10.0, 0, 0), 60)
	var along := _car.vel.x
	var out := _car.vel.z
	var want := 10.0 * pow(1.0 - Solidity.GRIND_COST * DT, 60)
	_expect(absf(along - want) < 0.05, "T5 grinding kept %.3f m/s along (want about %.3f)" % [along, want])
	_expect(out >= Solidity.GRIND_NUDGE - 0.001, "T5 grinding nudged the car out of the line at %.2f m/s (want %.2f)" % [out, Solidity.GRIND_NUDGE])
	_expect(_broke.size() >= 4, "T5 grinding knocked the panels down as it went (%d)" % _broke.size())


func _t6_skips() -> void:
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 2.5), 0.0)
	_drive(Vector3(0, 0, -1.5), 200)
	_expect(_broke.is_empty(), "T6 under MIN_SPEED nothing breaks (%d)" % _broke.size())
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	_car.collision_mask = 0
	_drive(Vector3(0, 0, -15.0), 50)
	_expect(_broke.is_empty(), "T6 with the collision mask 0 nothing breaks (%d)" % _broke.size())
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 6.0, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	_expect(_broke.is_empty(), "T6 a car on a deck 6 m over the fence breaks nothing (%d)" % _broke.size())
	_setup(_line("fence", -10.0, 10.0, 0.0, 0.0, 1.6), Vector3(0.1, 0.4, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	_expect(_broke.size() == 2, "T6 a car a little over the fence's foot (a kerb, a slope) still breaks it (%d)" % _broke.size())


func _t7_rule_b() -> void:
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	var near := Vector3(0, 0, 100.0)
	var far := Vector3(0, 0, 200.0)
	var where := [near]
	_soft.focus_at = func() -> Vector3: return where[0]
	_soft.car = null
	for _i in int(SoftThings.REPAIR_AFTER * 0.5):
		_soft.step(1.0)
	where[0] = far
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(_repaired.is_empty() and _soft.broken_count() == 2, "T7 not repaired before REPAIR_AFTER s (%d left)" % _soft.broken_count())
	where[0] = near
	for _i in int(SoftThings.REPAIR_AFTER * 0.6):
		_soft.step(1.0)
	_expect(_repaired.is_empty(), "T7 not repaired within %.0f m (%d repaired)" % [SoftThings.REPAIR_FAR, _repaired.size()])
	# In the camera's view, far: still standing (a headless camera has no frustum: the view test is
	# the case's own).
	var seen := [true]
	_soft.view_test = func(_at: Vector3) -> bool: return seen[0]
	where[0] = far
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(_repaired.is_empty(), "T7 not repaired in the camera's view (%d repaired)" % _repaired.size())
	seen[0] = false
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(_repaired.size() == 2 and _soft.broken_count() == 0, "T7 far, out of view and old: repaired (%d)" % _repaired.size())
	# A dawn instead of the ten minutes.
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	_soft.car = null
	_soft.focus_at = func() -> Vector3: return far
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(_repaired.is_empty(), "T7 a fresh break stays before the dawn")
	_soft.on_dawn()
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(_repaired.size() == 2, "T7 a dawn later, far and out of view: repaired (%d)" % _repaired.size())
	# repair_near, reset, MEMORY.
	_setup(_line("fence", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	_drive(Vector3(0, 0, -15.0), 50)
	_expect(_soft.repair_near(Vector3(0, 0, 0), 5.0) == 2 and _soft.broken_count() == 0, "T7 repair_near makes the spot whole")
	for i in SoftThings.MEMORY + 5:
		_soft._remember("line%d#0" % i, "line%d" % i, 0, Vector3(i, 0, 0))
	_expect(_soft.broken_count() == SoftThings.MEMORY and not _soft.is_broken("line0", 0) and _soft.is_broken("line%d" % (SoftThings.MEMORY + 4), 0),
			"T7 at most %d remembered, the oldest repaired first (%d)" % [SoftThings.MEMORY, _soft.broken_count()])
	_soft.reset()
	_expect(_soft.broken_count() == 0, "T7 reset makes the city whole")


func _t8_log() -> void:
	_setup(_line("hedge", -10.0, 10.0, 0.0), Vector3(0.1, 0, 5.0), 0.0)
	var log := ContactLog.new()
	_soft.contacts = log
	_car.vel = Vector3(0, 0, -15.0)
	_soft.step(DT)
	for _i in 120:
		log.observe(_car, DT)
		_car.global_position += _car.vel * DT
		_soft.step(DT)
	log.flush()
	var soft_lines := 0
	var hard := 0
	for line: String in log.lines:
		if line.begins_with("contact\t"):
			if line.contains("flags=soft") and line.contains("class=hedge") and line.contains("panels=2"):
				soft_lines += 1
			else:
				hard += 1
	_expect(soft_lines == 1 and hard == 0, "T8 one soft contact line for the hedge (%d soft, %d other): %s" % [soft_lines, hard, log.lines])
	var parsed := ContactLog.parse(log.lines[0]) if not log.lines.is_empty() else {}
	_expect(float(parsed.get("in", "0")) > 14.9 and float(parsed.get("low", "99")) < 14.0, "T8 its speeds in and after: %s" % parsed)
	if _soft != null:
		_soft.free()
		_soft = null
	if _car != null:
		_car.free()
		_car = null


# --- step 8a: the parked cars ------------------------------------------------------------------

## A "soft_cars" list of cars [x, z, yaw], all owned by sector s_0_0, no instances drawn.
static func _cars(list: Array) -> Dictionary:
	var out := PackedFloat64Array()
	for c: Array in list:
		out.append_array([float(c[0]), float(c[1]), float(c[2]), 0.0, 1.0, 0.0, 0.0, -1.0])
	return {"cars": out}


## A fresh soft_things whose sector s_0_0 (in the tree when `in_tree`) holds `cars`, a real car
## (its own physics off) at `at` heading `yaw`. Returns the sector root (freed unless `in_tree`).
func _setup_cars(cars: Array, at: Vector3, yaw: float, in_tree := false) -> Node3D:
	_setup({}, at, yaw)
	_soft.pushed.connect(func(id: String, p: Vector3, d: Vector3, sp: float) -> void: _pushed.append([id, p, d, sp]))
	_soft.car_returned.connect(func(id: String) -> void: _returned.append(id))
	_pushed.clear()
	_returned.clear()
	var sec := Node3D.new()
	sec.name = "s_0_0"
	sec.set_meta(&"soft_cars", _cars(cars))
	if in_tree:
		root.add_child(sec)
	_soft.add_sector(sec)
	if not in_tree:
		sec.free()
		return null
	return sec


## The parked car at x, z in the case's soft_things.
func _parked(x: float, z: float) -> SoftThings.Parked:
	return _soft.parked(SoftThings.car_id(x, z))


## The case's car's speed on the map.
func _speed() -> float:
	return Vector2(_car.vel.x, _car.vel.z).length()


## Drives the car at `v` (it moves by its own vel) until something changes its speed (the push), at
## most `frames` frames, and returns its speed then.
func _drive_to_hit(v: Vector3, frames: int) -> float:
	_car.vel = v
	_soft.step(DT)
	var s0 := v.length()
	for _i in frames:
		_car.global_position += _car.vel * DT
		_soft.step(DT)
		if absf(_speed() - s0) > 0.01:
			return _speed()
	return _speed()


## The player stops where it is; the soft things run on for `frames` frames.
func _settle(frames: int) -> void:
	_car.vel = Vector3.ZERO
	for _i in frames:
		_soft.step(DT)


func _p1_end_on() -> void:
	# A car at the origin along z; the player 9 m behind its back (+z) heading -z at 10 m/s.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(0, 0, 9.0), 0.0)
	var log := ContactLog.new()
	_soft.contacts = log
	var kept := 0.0
	_car.vel = Vector3(0, 0, -10.0)
	_soft.step(DT)
	for _i in 120:
		log.observe(_car, DT)
		_car.global_position += _car.vel * DT
		_soft.step(DT)
		if kept == 0.0 and absf(_speed() - 10.0) > 0.01:
			kept = _speed() / 10.0
			_car.vel = Vector3.ZERO  # the player stops at once, the car slides on alone
	for _i in 90:
		log.observe(_car, DT)
		_soft.step(DT)
	log.flush()
	_expect(_pushed.size() == 1, "P1 end-on: one push (%d)" % _pushed.size())
	_expect(absf(kept - Solidity.push_keep(1.0)) < 0.002, "P1 end-on: kept %.3f of the speed, want %.3f" % [kept, Solidity.push_keep(1.0)])
	var p := _parked(0.0, 0.0)
	_settle(240)
	var moved := p.xf.origin - p.bay.origin
	var want := Solidity.push_slide(10.0 * Solidity.PUSH_SHARE)
	_expect(moved.z < 0.0 and absf(moved.z + want) < 0.35 and absf(moved.x) < 0.01,
			"P1 end-on: slid %.2f m along its length (want about %.2f), %.2f aside" % [-moved.z, want, moved.x])
	_expect(absf(p.xf.basis.get_euler().y) < 0.001, "P1 end-on: square on, no spin (%.3f rad)" % p.xf.basis.get_euler().y)
	_expect(p.state == SoftThings.MOVED and _soft.off_bay_count() == 1, "P1 end-on: at rest off its bay (state %d)" % p.state)
	var soft_lines := 0
	for line: String in log.lines:
		if line.begins_with("contact\t") and line.contains("class=parked") and line.contains("soft\tpanels"):
			soft_lines += 1
	_expect(soft_lines == 1, "P1 end-on: one soft contact line of class parked (%s)" % [log.lines])


func _p2_side() -> void:
	# Square into its right side (+x) heading -x.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(6.0, 0, 0.0), PI * 0.5)
	var kept := _drive_to_hit(Vector3(-10.0, 0, 0), 120) / 10.0
	_expect(_pushed.size() == 1 and absf(kept - Solidity.push_keep(1.0)) < 0.002, "P2 side: pushed once, kept %.3f (want %.3f)" % [kept, Solidity.push_keep(1.0)])
	var p := _parked(0.0, 0.0)
	_settle(240)
	var moved := p.xf.origin - p.bay.origin
	_expect(moved.x < -1.5 and absf(moved.z) < 0.01, "P2 side: slid %.2f m sideways, %.2f along" % [-moved.x, moved.z])
	# Brushing along its side: 5 deg into it, the player's side just over the car's side.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(1.85, 0, 0.5), 0.0)
	var a := deg_to_rad(5.0)
	_car.rotation.y = a
	kept = _drive_to_hit(Vector3(-sin(a), 0, -cos(a)) * 12.0, 120) / 12.0
	p = _parked(0.0, 0.0)
	_settle(240)
	_expect(absf(kept - Solidity.push_keep(sin(a))) < 0.003, "P2 brushing at 5 deg: kept %.3f (want %.3f)" % [kept, Solidity.push_keep(sin(a))])
	_expect((p.xf.origin - p.bay.origin).length() < 0.35, "P2 brushing: moved it %.2f m" % (p.xf.origin - p.bay.origin).length())
	# At a corner: square into its side near its front end (-z): that end swings further.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(6.0, 0, -1.6), PI * 0.5)
	_drive_to_hit(Vector3(-10.0, 0, 0), 120)
	p = _parked(0.0, 0.0)
	_settle(240)
	var front_moved := (p.xf * Vector3(0, 0, -2.1)) - (p.bay * Vector3(0, 0, -2.1))
	var back_moved := (p.xf * Vector3(0, 0, 2.1)) - (p.bay * Vector3(0, 0, 2.1))
	_expect(front_moved.x < back_moved.x - 0.05 and absf(p.xf.basis.get_euler().y) > 0.01,
			"P2 corner: the hit end went further (%.2f) than the other (%.2f), turned %.3f rad" % [-front_moved.x, -back_moved.x, p.xf.basis.get_euler().y])
	# A creep at 1 m/s: still a push, a little.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(2.5, 0, 0.0), PI * 0.5)
	_drive_to_hit(Vector3(-1.0, 0, 0), 120)
	p = _parked(0.0, 0.0)
	_expect(_pushed.size() == 1 and p.state != SoftThings.BAY and p.hard == null, "P2 a creep at 1 m/s pushes it (%d pushes, state %d)" % [_pushed.size(), p.state])


func _p3_wedged() -> void:
	# A wall 0.3 m beyond the car's left side (-x): pushed from +x it cannot move.
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(6.0, 0, 0.0), PI * 0.5)
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 3.0, 12.0)
	cs.shape = box
	wall.add_child(cs)
	root.add_child(wall)
	wall.global_position = Vector3(-0.9 - 0.3 - 0.2, 1.5, 0.0)
	await physics_frame
	await physics_frame
	var kept := _drive_to_hit(Vector3(-10.0, 0, 0), 40) / 10.0
	var p := _parked(0.0, 0.0)
	_expect(_pushed.is_empty() and _soft.wedges == 1, "P3 wedged: not pushed (%d pushes, %d wedged)" % [_pushed.size(), _soft.wedges])
	_expect(is_equal_approx(kept, 1.0), "P3 wedged: soft_things left the speed alone (%.3f): car.gd answers the wall" % kept)
	var ok := p.hard != null and is_instance_valid(p.hard) and StringName(p.hard.get_meta(&"solid", "")) == &"parked" \
			and p.hard.global_position.distance_to(p.bay.origin + Vector3(0, SoftThings.CAR_HIGH * 0.5, 0)) < 0.01
	_expect(ok, "P3 wedged: a parked-class box collider stands where the car is")
	_car.global_position = Vector3(30.0, 0, 0)
	_soft.reset_motion()
	_soft.step(DT)
	_expect(p.hard == null, "P3 wedged: the collider goes once the player is away")
	wall.free()


func _p4_chain() -> void:
	# Two cars in a row along z, 1.4 m apart; the player from behind the first (+z), 14 m/s.
	_setup_cars([[0.0, 0.0, 0.0], [0.0, -5.6, 0.0]], Vector3(0, 0, 9.0), 0.0)
	_drive_to_hit(Vector3(0, 0, -14.0), 120)
	_settle(300)
	var a := _parked(0.0, 0.0)
	var b := _parked(0.0, -5.6)
	_expect(_soft.chains == 1 and _pushed.size() == 2, "P4 chain: the first car pushed the second (%d chains, %d pushes)" % [_soft.chains, _pushed.size()])
	_expect(b.xf.origin.z < b.bay.origin.z - 0.3, "P4 chain: the second car slid %.2f m" % (b.bay.origin.z - b.xf.origin.z))
	_expect(not SoftThings.polys_meet(SoftThings.box_of(a.xf, SoftThings.CAR_HALF), SoftThings.box_of(b.xf, SoftThings.CAR_HALF)),
			"P4 chain: the two end apart (at z %.2f and %.2f)" % [a.xf.origin.z, b.xf.origin.z])


## A one-way road heading +x, its centreline at z = `z`, `lanes` lanes of 3 m to its right (+z: the
## lanes span z .. z + 3 × lanes), on a flat map.
func _road(z: float, lanes: int, flat: Node3D) -> LaneGraph:
	var g := {"nodes": [-60.0, z, 60.0, z], "scc": [0, 0], "ctrl": [],
			"edges": [{"a": 0, "b": 1, "p": [-60.0, z, 60.0, z], "s0": 0.0, "s1": 120.0, "n": lanes, "o": 1.5, "lw": 3.0,
				"v": 14.0, "k": "residential"}]}
	return LaneGraph.new(g, flat)


func _p5_lanes() -> void:
	var flat := Fakes.FlatMap.new()  # the hand-made lane graph's map (P5)
	root.add_child(flat)
	# A lane from z -7 to -4 (its centreline at -7, the lane to its right): the car (along z, -2.1 ..
	# 2.1) pushed 3 m back would rest half in it: it stops short, clear of it.
	var near := _road(-7.0, 1, flat)
	var segs := SoftThings.corridor_segments(near, Vector2.ZERO, 30.0, 0.0)
	_expect(not segs.is_empty() and SoftThings.in_corridor(Transform3D(Basis(), Vector3(0, 0, -5.0)), segs)
			and not SoftThings.in_corridor(Transform3D(), segs), "P5 the lane's corridor is found (%d segments)" % (segs.size() / 6))
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(0, 0, 9.0), 0.0)
	_soft.graph = near
	_drive_to_hit(Vector3(0, 0, -10.0), 120)
	_settle(300)
	var p := _parked(0.0, 0.0)
	_expect(p.state == SoftThings.MOVED and not SoftThings.in_corridor(p.xf, segs) and p.xf.origin.z < -1.0,
			"P5 pushed toward a lane: stops short of it at z %.2f (state %d)" % [p.xf.origin.z, p.state])
	# A lane 0.4 m off its nose: the only clear rest is under PUSH_WEDGED: it cannot move, a wall.
	var close := _road(-5.5, 1, flat)
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(0, 0, 9.0), 0.0)
	_soft.graph = close
	var kept := _drive_to_hit(Vector3(0, 0, -10.0), 40) / 10.0
	p = _parked(0.0, 0.0)
	_expect(_pushed.is_empty() and _soft.lane_wedges == 1 and p.hard != null and is_equal_approx(kept, 1.0),
			"P5 a lane at its nose: not pushed, a wall (%d pushes, %d lane wedges)" % [_pushed.size(), _soft.lane_wedges])
	# Its bay in the lanes already (a bake defect) and lanes all the way: towed, hidden once out of view.
	var wide := _road(-15.0, 5, flat)  # its lanes from z -15 to 0
	_setup_cars([[0.0, 0.0, 0.0]], Vector3(0, 0, 9.0), 0.0)
	_soft.graph = wide
	_soft.view_test = func(_at: Vector3) -> bool: return false
	_drive_to_hit(Vector3(0, 0, -10.0), 120)
	_settle(300)
	p = _parked(0.0, 0.0)
	_soft.step(SoftThings.REPAIR_EVERY)  # rule B's tick hides a towed car out of view
	_expect(p.state == SoftThings.TOWED and p.hidden and _soft.towed == 1, "P5 lanes all the way: towed and hidden (state %d, hidden %s)" % [p.state, p.hidden])
	# Pushed away from the lane (the player on the lane's side, heading +z): it just slides.
	_setup_cars([[0.0, 0.5, 0.0]], Vector3(0, 0, -9.0), PI)
	_soft.graph = close
	_drive_to_hit(Vector3(0, 0, 10.0), 120)
	_settle(300)
	p = _parked(0.0, 0.5)
	_expect(p.state == SoftThings.MOVED and absf(p.xf.origin.z - p.bay.origin.z - Solidity.push_slide(6.0)) < 0.35,
			"P5 pushed away from the lane: slid %.2f m as friction stops it" % (p.xf.origin.z - p.bay.origin.z))
	flat.free()


func _p6_bay() -> void:
	var sec := _setup_cars([[0.0, 0.0, 0.0]], Vector3(6.0, 0, 0.0), PI * 0.5, true)
	_drive_to_hit(Vector3(-10.0, 0, 0), 120)
	_settle(240)
	var p := _parked(0.0, 0.0)
	var rest := p.xf
	# The sector leaves and comes in again: the car lies where it was left.
	var meta: Dictionary = sec.get_meta(&"soft_cars")
	sec.free()
	_expect(_soft.car_count() == 0, "P6 the sector left with its cars (%d)" % _soft.car_count())
	var again := Node3D.new()
	again.name = "s_0_0"
	again.set_meta(&"soft_cars", meta)
	root.add_child(again)
	_soft.add_sector(again)
	p = _parked(0.0, 0.0)
	_expect(p != null and p.xf.is_equal_approx(rest) and p.state == SoftThings.MOVED, "P6 loaded again: where it was left (%s)" % (p.xf.origin if p != null else Vector3.INF))
	if p == null:
		again.free()
		return
	# Rule B: within REPAIR_FAR it stays; far and out of view, ten minutes on, it is back in its bay.
	var where := [Vector3(40, 0, 0)]
	_soft.focus_at = func() -> Vector3: return where[0]
	_soft.view_test = func(_at: Vector3) -> bool: return false
	_soft.car = null
	for _i in int(SoftThings.REPAIR_AFTER) + 5:
		_soft.step(1.0)
	_expect(p.state == SoftThings.MOVED and _returned.is_empty(), "P6 within %.0f m it stays pushed" % SoftThings.REPAIR_FAR)
	where[0] = Vector3(400, 0, 0)
	_soft.step(1.0)
	_soft.step(1.0)
	_expect(p.state == SoftThings.BAY and p.xf.is_equal_approx(p.bay) and _returned.size() == 1, "P6 far, out of view, old: back in its bay")
	# reset: every car back.
	_soft.car = _car
	_car.global_position = Vector3(6.0, 0, 0.0)
	_soft.reset_motion()
	_drive_to_hit(Vector3(-10.0, 0, 0), 120)
	_expect(p.state != SoftThings.BAY, "P6 pushed again")
	_soft.reset()
	_expect(p.state == SoftThings.BAY and _soft.off_bay_count() == 0, "P6 reset puts it back in its bay")
	again.free()


func _p7_settings() -> void:
	var list := [[100.0, 100.0, 0.0], [110.0, 104.0, 1.2]]
	var sec := Node3D.new()
	sec.name = "s_0_0"
	sec.set_meta(&"soft_cars", _cars(list))
	root.add_child(sec)
	_setup({}, Vector3(106.0, 0, 100.0), PI * 0.5)
	_soft.no_soft = true
	_soft.add_sector(sec)
	var want := PackedVector3Array()
	for c: Array in list:
		want.append_array(MapBuilder.parked_faces(Transform3D(Basis(Vector3.UP, c[2]), Vector3(c[0], 0.0, c[1]))))
	var w := _keys(want)
	w.sort()
	_expect(_parked_faces(sec) == w and _soft.car_count() == 0, "P7 settings off: the cars' colliders are the builder's (%d faces, want %d), none swept" % [
			_parked_faces(sec).size(), w.size()])
	_soft.set_soft(true)
	_expect(_parked_faces(sec).is_empty() and _soft.car_count() == 2, "P7 turned on live: no collider, both cars swept (%d)" % _soft.car_count())
	_pushed.clear()
	_soft.pushed.connect(func(id: String, p: Vector3, d: Vector3, sp: float) -> void: _pushed.append([id, p, d, sp]))
	_drive_to_hit(Vector3(-10.0, 0, 0), 120)
	_expect(_pushed.size() == 1, "P7 on: a push moves it (%d)" % _pushed.size())
	_soft.set_soft(false)
	_expect(_parked_faces(sec) == w and _soft.car_count() == 0 and _soft.off_bay_count() == 0, "P7 off again: the builder's colliders back, the car in its bay")
	sec.free()
	_soft.free()
	_soft = null
	_car.free()
	_car = null


## Every `parked` collider face under `node`, as sorted byte keys.
func _parked_faces(node: Node) -> PackedStringArray:
	var keys := PackedStringArray()
	for n in node.find_children("*", "CollisionShape3D", true, false):
		var body := n.get_parent()
		if body == null or StringName(str(body.get_meta(&"solid", ""))) != &"parked":
			continue
		var shape := (n as CollisionShape3D).shape as ConcavePolygonShape3D
		if shape != null:
			keys.append_array(_keys(shape.get_faces()))
	keys.sort()
	return keys


# --- the map ------------------------------------------------------------------------------------

func _map_part(all: bool, only: Array[Vector2i]) -> String:
	if not FileAccess.file_exists("res://map/index.json") or not ResourceLoader.exists("res://map/index.res"):
		problems.append("M1 no sector split or prebuilt city: run tools/setup_map.sh")
		return "no map"
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var keys: Array[Vector2i] = []
	if not only.is_empty():
		keys = only
	elif all:
		for k: Array in index["sectors"]["keys"]:
			keys.append(Vector2i(int(k[0]), int(k[1])))
	else:
		keys = SECTORS
	# The lines the bake classed S (fence, hedge), by stable id.
	var s_ids := {}
	var centrum: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	for l: Dictionary in (centrum as Dictionary).get("lines", []):
		if (l["k"] == "fence" or l["k"] == "hedge") and str(l.get("sc", "")) == "S":
			s_ids[CityBarriers.barrier_id(l["k"], l["p"])] = true
	var runtime: Node3D = MapBuilder.new()
	root.add_child(runtime)
	runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var segs := 0
	var lines := 0
	var cars_n := 0
	# M5: one soft_things with the map's lane graph, for the lane rule.
	runtime.data = runtime.index_data
	var m5 := SoftThings.new()
	m5.graph = LaneGraph.new(runtime.index_data["graph"], runtime)
	root.add_child(m5)
	for key in keys:
		CityBarriers.soft_off = false
		var built: Node3D = runtime.build_sector(key)
		var soft: Dictionary = built.get_meta(&"soft", {})
		var cars: Dictionary = built.get_meta(&"soft_cars", {})
		var soft_faces := _class_faces(built)
		var drawn_rt := _car_instances(built, cars)
		built.free()
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if not ResourceLoader.exists(path):
			problems.append("M1 %s: no prebuilt sector" % key)
			continue
		var inst := (load(path) as PackedScene).instantiate()
		var pre: Dictionary = inst.get_meta(&"soft", {})
		var pre_cars: Dictionary = inst.get_meta(&"soft_cars", {})
		var drawn_pb := _car_instances(inst, pre_cars)
		inst.free()
		var same := soft.size() == pre.size()
		for k: String in soft:
			same = same and pre.has(k) and soft[k] == pre[k]
		_expect(same, "M1 %s: the runtime and prebuilt soft lists are the same (%d and %d segments)" % [key,
				(soft.get("segs", PackedFloat64Array()) as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE,
				(pre.get("segs", PackedFloat64Array()) as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE])
		# M4: the parked cars' lists and their instances, both paths.
		var n_cars := (cars.get("cars", PackedFloat64Array()) as PackedFloat64Array).size() / MapBuilder.CAR_STRIDE
		_expect(cars.size() == pre_cars.size() and (cars.is_empty() or cars["cars"] == pre_cars["cars"]),
				"M4 %s: the runtime and prebuilt parked-car lists are the same (%d and %d cars)" % [key, n_cars,
				(pre_cars.get("cars", PackedFloat64Array()) as PackedFloat64Array).size() / MapBuilder.CAR_STRIDE])
		_expect(drawn_rt == "" and drawn_pb == "", "M4 %s: every own car has its instance in its tile's MultiMesh (runtime: %s; prebuilt: %s)" % [
				key, "ok" if drawn_rt == "" else drawn_rt, "ok" if drawn_pb == "" else drawn_pb])
		_expect(not soft_faces.has(&"parked"), "M4 %s: the soft build files no parked collider (%d faces)" % [key,
				(soft_faces.get(&"parked", PackedStringArray()) as PackedStringArray).size()])
		cars_n += n_cars
		_m5_sector(m5, cars)
		if soft.is_empty() and cars.is_empty():
			continue
		if not soft.is_empty():
			var not_s := 0
			for id: String in soft["ids"]:
				if not s_ids.has(id):
					not_s += 1
			_expect(not_s == 0, "M1 %s: every soft line is an S fence or hedge of centrum.json (%d are not)" % [key, not_s])
			lines += (soft["ids"] as PackedStringArray).size()
			segs += (soft["segs"] as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE
		# M2: the builder with --no-soft against the soft build plus the restore.
		CityBarriers.soft_off = true
		var hard: Node3D = runtime.build_sector(key)
		CityBarriers.soft_off = false
		var want := _class_faces(hard)
		var hard_meta := hard.has_meta(&"soft") or hard.has_meta(&"soft_cars")
		hard.free()
		var rect := Rect2(Vector2(key) * MapBuilder.SECTOR, Vector2(MapBuilder.SECTOR, MapBuilder.SECTOR))
		var restored := SoftThings.hard_faces(soft, rect) if not soft.is_empty() else {}
		restored[&"parked"] = SoftThings.car_faces(cars, rect)
		_expect(not hard_meta, "M2 %s: no soft list with --no-soft" % key)
		for cls: StringName in SAME_CLASSES:
			var got: PackedStringArray = soft_faces.get(cls, PackedStringArray()).duplicate()
			got.append_array(_keys(restored.get(cls, PackedVector3Array())))
			got.sort()
			var w: PackedStringArray = want.get(cls, PackedStringArray())
			_expect(got == w, "M2 %s %s: the soft build's faces + the restored ones = the --no-soft build's (%d + restored = %d, want %d)" % [
					key, cls, (soft_faces.get(cls, PackedStringArray()) as PackedStringArray).size(), got.size(), w.size()])
		# M3: the setting turned over on a loaded sector, the runtime build's and the prebuilt one.
		var again: Node3D = runtime.build_sector(key)
		root.add_child(again)
		_m3_toggle(again, key, "runtime", want, soft_faces, not soft.is_empty(), n_cars)
		again.free()
		var pre_again := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(pre_again)
		_m3_toggle(pre_again, key, "prebuilt", want, soft_faces, not soft.is_empty(), n_cars)
		pre_again.free()
		if verbose:
			print("   %s: %d soft lines, %d segments, %d parked cars" % [key, (soft.get("ids", PackedStringArray()) as PackedStringArray).size(), segs, n_cars])
	m5.free()
	runtime.free()
	print("check_soft_things: M5 the lane rule over %d parked cars (%d pushes off their sides and ends at 8 m/s, no walls): rests in a lane %d with friction alone -> %d with the rule (towed), %d walls instead (the only clear rest under %.1f m); bays in a lane %d; %.2f ms a plan" % [
			_m5["cars"], _m5["pushes"], _m5["natural"], _m5["ruled"], _m5["wedged"], Solidity.PUSH_WEDGED, _m5["bays"],
			_m5["usec"] / 1000.0 / maxf(_m5["pushes"], 1)])
	return "%d sectors on both paths: %d soft lines, %d segments, %d parked cars; the hard restore %.1f ms a sector on average; lane rule: %d of %d pushes rest in a lane (%d with friction alone, %d walls)" % [
			keys.size(), lines, segs, cars_n, _m3_usec / 1000.0 / maxf(_m3_hardens, 1), _m5["ruled"], _m5["pushes"], _m5["natural"], _m5["wedged"]]


## M6, the script's cost: the prebuilt sector `key` loaded, its parked cars watched with the map's lane
## graph; three of them pushed (sliding together), then the player driving through the sector at
## 12 m/s past its first car: the step's microseconds a frame each way (the brief: under 0.1 ms).
func _m6_cost(key: Vector2i) -> String:
	var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
	if not ResourceLoader.exists(path) or not FileAccess.file_exists("res://map/index.json"):
		return "no prebuilt sector %s" % key
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var runtime: Node3D = MapBuilder.new()
	root.add_child(runtime)
	runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	runtime.data = runtime.index_data
	var sec := (load(path) as PackedScene).instantiate() as Node3D
	root.add_child(sec)
	await physics_frame
	await physics_frame  # the sector's colliders in the space for the slide's casts
	var st := SoftThings.new()
	st.graph = LaneGraph.new(runtime.index_data["graph"], runtime)
	root.add_child(st)
	st.set_physics_process(false)
	st.add_sector(sec)
	var cars: Array = st._car_sectors.get(key, {}).get("cars", [])
	if cars.size() < 3:
		st.free()
		sec.free()
		runtime.free()
		problems.append("M6 %s has %d parked cars" % [key, cars.size()])
		return "no cars"
	var started := 0
	for i in 3:
		var p: SoftThings.Parked = cars[i * (cars.size() / 3)]
		var side := Vector2(p.xf.basis.x.x, p.xf.basis.x.z).normalized()
		if st._start_slide(p, side, 6.0, 0.4) or st._start_slide(p, -side, 6.0, 0.4):
			started += 1
	var slide: Array[float] = []
	while not st._sliding.is_empty() and slide.size() < 600:
		var t0 := Time.get_ticks_usec()
		st.step(DT)
		slide.append(Time.get_ticks_usec() - t0)
	var frames := slide.size()
	var slide_mean := _mean(slide)
	slide.sort()
	var slide_us := slide[frames / 2] if frames > 0 else 0.0
	var c := Car.new()
	root.add_child(c)
	c.set_physics_process(false)
	var first: SoftThings.Parked = cars[0]
	var along := -Vector3(first.bay.basis.z.x, 0.0, first.bay.basis.z.z).normalized()
	var aside := Vector3(first.bay.basis.x.x, 0.0, first.bay.basis.x.z).normalized()
	c.global_position = first.bay.origin + aside * 3.0 - along * 40.0
	c.look_at(c.global_position + along, Vector3.UP)
	st.car = c
	c.vel = along * 12.0
	st.step(DT)
	var drive: Array[float] = []
	var pushes0 := st.pushes
	for _i in 300:
		c.global_position += c.vel * DT
		c.vel = along * 12.0
		var t1 := Time.get_ticks_usec()
		st.step(DT)
		drive.append(Time.get_ticks_usec() - t1)
	var drive_mean := _mean(drive)
	drive.sort()
	var drive_us := drive[150]
	var drive_pushes := st.pushes - pushes0
	st.free()
	c.free()
	sec.free()
	runtime.free()
	_expect(started > 0 and slide_us < 100.0, "M6 %s: %d cars sliding cost %.0f us a frame (the median; under 100)" % [key, started, slide_us])
	_expect(drive_us < 100.0, "M6 %s: driving among the cars costs %.0f us a frame (the median; under 100)" % [key, drive_us])
	return "%s: %d cars sliding %.0f us a frame (median; mean %.0f with the chain pushes' casts, worst %.0f) over %d frames; driving among %d cars %.0f us (mean %.0f, worst %.0f, %d pushes)" % [
			key, started, slide_us, slide_mean, slide[frames - 1] if frames > 0 else 0.0, frames, cars.size(), drive_us, drive_mean, drive[299], drive_pushes]


func _mean(xs: Array[float]) -> float:
	var t := 0.0
	for x in xs:
		t += x
	return t / maxf(xs.size(), 1)


## M4: "" when every own car of `cars` has its instance (slot) in the parked MultiMesh of its tile under
## `sector`, else what is wrong.
func _car_instances(sector: Node, cars: Dictionary) -> String:
	if cars.is_empty():
		return ""
	var by_tile := {}
	for c in sector.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi != null and mmi.has_meta(MapBuilder.PARKED_TILE):
			by_tile[mmi.get_meta(MapBuilder.PARKED_TILE)] = mmi.multimesh
	var list: PackedFloat64Array = cars["cars"]
	var own_by_tile := {}
	for o in range(0, list.size(), MapBuilder.CAR_STRIDE):
		if list[o + 4] < 0.5:
			continue
		var tile := Vector2i(int(list[o + 5]), int(list[o + 6]))
		own_by_tile[tile] = int(own_by_tile.get(tile, 0)) + 1
		var mm: MultiMesh = by_tile.get(tile)
		if mm == null:
			return "no MultiMesh for tile %s" % tile
		if int(list[o + 7]) < 0 or int(list[o + 7]) >= mm.instance_count:
			return "car at %.1f, %.1f: instance %d of %d" % [list[o], list[o + 1], int(list[o + 7]), mm.instance_count]
	for tile: Vector2i in own_by_tile:
		if (by_tile[tile] as MultiMesh).instance_count != int(own_by_tile[tile]):
			return "tile %s draws %d cars, %d own" % [tile, (by_tile[tile] as MultiMesh).instance_count, own_by_tile[tile]]
	return ""


## M5: every own car of `cars` pushed off its two sides and two ends at 8 m/s (PUSH_SHARE of it), no
## walls: where friction alone would stop it, and where the lane rule rests it, in a lane or not.
func _m5_sector(st: SoftThings, cars: Dictionary) -> void:
	if cars.is_empty():
		return
	var list: PackedFloat64Array = cars["cars"]
	for o in range(0, list.size(), MapBuilder.CAR_STRIDE):
		if list[o + 4] < 0.5:
			continue
		var bay := SoftThings.bay_of(list, o)
		_m5["cars"] += 1
		var at := Vector2(bay.origin.x, bay.origin.z)
		var near := SoftThings.corridor_segments(st.graph, at, 12.0, bay.origin.y)
		if SoftThings.in_corridor(bay, near):
			_m5["bays"] += 1
		var right := Vector2(bay.basis.x.x, bay.basis.x.z).normalized()
		var back := Vector2(bay.basis.z.x, bay.basis.z.z).normalized()
		for d: Vector2 in [right, -right, back, -back]:
			var speed := 8.0 * Solidity.PUSH_SHARE
			var natural := bay
			natural.origin += Vector3(d.x, 0.0, d.y) * Solidity.push_slide(speed)
			if SoftThings.in_corridor(natural, near):
				_m5["natural"] += 1
			var p := SoftThings.Parked.new()
			p.bay = bay
			p.xf = bay
			p.dir = d
			p.speed = speed
			p.speed0 = speed
			p.limit = INF
			var t0 := Time.get_ticks_usec()
			var friction := st._plan_rest(p)
			_m5["usec"] += Time.get_ticks_usec() - t0
			_m5["pushes"] += 1
			if p.target >= 0.0 and p.target < Solidity.PUSH_WEDGED and p.target < friction - 0.01:
				_m5["wedged"] += 1  # it would stop on the spot: a wall instead
			elif p.in_lane:
				_m5["ruled"] += 1
			else:
				var rest := bay
				rest.origin += Vector3(d.x, 0.0, d.y) * p.target
				var segs := SoftThings.corridor_segments(st.graph, Vector2(rest.origin.x, rest.origin.z), 4.0, bay.origin.y)
				_expect(not SoftThings.in_corridor(rest, segs), "M5 the lane rule's rest for the car at %.1f, %.1f is clear of the lanes" % [at.x, at.y])


## M3: sector `sector` (in the tree) loaded with the soft things hard, then turned soft and hard again;
## its fence, hedge and parked faces each time against `hard` (the --no-soft build's) and `soft_faces`
## (the soft build's); `lines` (it has soft lines) and `cars` (its parked cars) say what is swept.
func _m3_toggle(sector: Node3D, key: Vector2i, path: String, hard: Dictionary, soft_faces: Dictionary, lines: bool, cars: int) -> void:
	var st := SoftThings.new()
	st.no_soft = true
	root.add_child(st)
	st.add_sector(sector)
	_expect(_same_faces(_class_faces(sector), hard), "M3 %s %s: loaded with the soft things hard, its faces are the --no-soft build's" % [key, path])
	_expect(st.segment_count() == 0 and st.car_count() == 0, "M3 %s %s: nothing swept while hard (%d segments, %d cars)" % [key, path, st.segment_count(), st.car_count()])
	var n := st.set_soft(true)
	_expect(n == 1 and _same_faces(_class_faces(sector), soft_faces), "M3 %s %s: soft live, the restored bodies are gone (%d sectors turned)" % [key, path, n])
	_expect((st.segment_count() > 0) == lines and (st.car_count() > 0) == (cars > 0), "M3 %s %s: soft live, the sector is swept (%d segments, %d cars)" % [
			key, path, st.segment_count(), st.car_count()])
	st._remember("x#0", "x", 0, Vector3.ZERO)
	n = st.set_soft(false)
	_expect(n == 1 and _same_faces(_class_faces(sector), hard), "M3 %s %s: hard again live, the --no-soft faces are back" % [key, path])
	_expect(st.segment_count() == 0 and st.car_count() == 0 and st.broken_count() == 0, "M3 %s %s: hard again, nothing swept and nothing left broken" % [key, path])
	_expect(st.set_soft(false) == 0 and _same_faces(_class_faces(sector), hard), "M3 %s %s: hard twice adds nothing" % [key, path])
	_m3_usec += st.harden_usec
	_m3_hardens += 2
	st.free()


## The classes the soft things restore (step 7's fences and hedges, step 8a's parked cars).
const SAME_CLASSES: Array[StringName] = [&"fence", &"hedge", &"parked"]


## Fence, hedge and parked faces the same in `a` and `b` (sorted byte keys by class).
static func _same_faces(a: Dictionary, b: Dictionary) -> bool:
	for cls: StringName in SAME_CLASSES:
		if a.get(cls, PackedStringArray()) != b.get(cls, PackedStringArray()):
			return false
	return true


## Every collider face of a sector root by class, as sorted byte keys (fence, hedge and parked only).
func _class_faces(node: Node) -> Dictionary:
	var out := {}
	for n in node.find_children("*", "CollisionShape3D", true, false):
		var body := n.get_parent()
		if body == null or not body.has_meta(&"solid"):
			continue
		var cls := StringName(body.get_meta(&"solid"))
		if not cls in SAME_CLASSES:
			continue
		var shape := (n as CollisionShape3D).shape as ConcavePolygonShape3D
		if shape == null:
			continue
		var keys: PackedStringArray = out.get(cls, PackedStringArray())
		keys.append_array(_keys(shape.get_faces()))
		out[cls] = keys
	for cls: StringName in out.keys():
		var keys: PackedStringArray = out[cls]
		keys.sort()
		out[cls] = keys
	return out


static func _keys(f: PackedVector3Array) -> PackedStringArray:
	var out := PackedStringArray()
	for i in range(0, f.size() - 2, 3):
		out.append(PackedVector3Array([f[i], f[i + 1], f[i + 2]]).to_byte_array().hex_encode())
	return out
