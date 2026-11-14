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
## Prints `check_soft_things: OK (...)` (exit 0) or the problems (exit 1). The map part needs the
## sector split and the prebuilt sectors (tools/setup_map.sh); --all compares every sector (slow).
##   godot --headless --path game --script res://tools/check_soft_things.gd [-- --all --sectors=i,j;i,j --verbose]

const SoftThings := preload("res://scripts/soft_things.gd")
const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const ContactLog := preload("res://scripts/contact_log.gd")
const Car := preload("res://scripts/car.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

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


func _initialize() -> void:
	var all := false
	var only: Array[Vector2i] = []
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
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
	var cases_ms := Time.get_ticks_msec() - t0
	var map_note := _map_part(all, only)
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
	for key in keys:
		CityBarriers.soft_off = false
		var built: Node3D = runtime.build_sector(key)
		var soft: Dictionary = built.get_meta(&"soft", {})
		var soft_faces := _class_faces(built)
		built.free()
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if not ResourceLoader.exists(path):
			problems.append("M1 %s: no prebuilt sector" % key)
			continue
		var inst := (load(path) as PackedScene).instantiate()
		var pre: Dictionary = inst.get_meta(&"soft", {})
		inst.free()
		var same := soft.size() == pre.size()
		for k: String in soft:
			same = same and pre.has(k) and soft[k] == pre[k]
		_expect(same, "M1 %s: the runtime and prebuilt soft lists are the same (%d and %d segments)" % [key,
				(soft.get("segs", PackedFloat64Array()) as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE,
				(pre.get("segs", PackedFloat64Array()) as PackedFloat64Array).size() / CityBarriers.SOFT_STRIDE])
		if soft.is_empty():
			continue
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
		var hard_meta := hard.has_meta(&"soft")
		hard.free()
		var restored := SoftThings.hard_faces(soft, Rect2(Vector2(key) * MapBuilder.SECTOR, Vector2(MapBuilder.SECTOR, MapBuilder.SECTOR)))
		_expect(not hard_meta, "M2 %s: no soft list with --no-soft" % key)
		for cls: StringName in [&"fence", &"hedge"]:
			var got: PackedStringArray = soft_faces.get(cls, PackedStringArray()).duplicate()
			got.append_array(_keys(restored.get(cls, PackedVector3Array())))
			got.sort()
			var w: PackedStringArray = want.get(cls, PackedStringArray())
			_expect(got == w, "M2 %s %s: the soft build's faces + the restored ones = the --no-soft build's (%d + restored = %d, want %d)" % [
					key, cls, (soft_faces.get(cls, PackedStringArray()) as PackedStringArray).size(), got.size(), w.size()])
		# M3: the setting turned over on a loaded sector, the runtime build's and the prebuilt one.
		var again: Node3D = runtime.build_sector(key)
		root.add_child(again)
		_m3_toggle(again, key, "runtime", want, soft_faces)
		again.free()
		var pre_again := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(pre_again)
		_m3_toggle(pre_again, key, "prebuilt", want, soft_faces)
		pre_again.free()
		if verbose:
			print("   %s: %d soft lines, %d segments" % [key, (soft["ids"] as PackedStringArray).size(), segs])
	runtime.free()
	return "%d sectors on both paths: %d soft lines, %d segments; the hard restore %.1f ms a sector on average" % [keys.size(), lines, segs,
			_m3_usec / 1000.0 / maxf(_m3_hardens, 1)]


## M3: sector `sector` (in the tree) loaded with the fences hard, then turned breakable and hard
## again; its fence and hedge faces each time against `hard` (the --no-soft build's) and `soft_faces`
## (the soft build's).
func _m3_toggle(sector: Node3D, key: Vector2i, path: String, hard: Dictionary, soft_faces: Dictionary) -> void:
	var st := SoftThings.new()
	st.no_soft = true
	root.add_child(st)
	st.add_sector(sector)
	_expect(_same_faces(_class_faces(sector), hard), "M3 %s %s: loaded with the fences hard, its faces are the --no-soft build's" % [key, path])
	_expect(st.segment_count() == 0, "M3 %s %s: nothing swept while hard (%d segments)" % [key, path, st.segment_count()])
	var n := st.set_soft(true)
	_expect(n == 1 and _same_faces(_class_faces(sector), soft_faces), "M3 %s %s: breakable live, the restored bodies are gone (%d sectors turned)" % [key, path, n])
	_expect(st.segment_count() > 0, "M3 %s %s: breakable live, the sector is swept" % [key, path])
	st._remember("x#0", "x", 0, Vector3.ZERO)
	n = st.set_soft(false)
	_expect(n == 1 and _same_faces(_class_faces(sector), hard), "M3 %s %s: hard again live, the --no-soft faces are back" % [key, path])
	_expect(st.segment_count() == 0 and st.broken_count() == 0, "M3 %s %s: hard again, nothing swept and nothing left broken" % [key, path])
	_expect(st.set_soft(false) == 0 and _same_faces(_class_faces(sector), hard), "M3 %s %s: hard twice adds nothing" % [key, path])
	_m3_usec += st.harden_usec
	_m3_hardens += 2
	st.free()


## Fence and hedge faces the same in `a` and `b` (sorted byte keys by class).
static func _same_faces(a: Dictionary, b: Dictionary) -> bool:
	for cls: StringName in [&"fence", &"hedge"]:
		if a.get(cls, PackedStringArray()) != b.get(cls, PackedStringArray()):
			return false
	return true


## Every collider face of a sector root by class, as sorted byte keys (fence and hedge only matter).
func _class_faces(node: Node) -> Dictionary:
	var out := {}
	for n in node.find_children("*", "CollisionShape3D", true, false):
		var body := n.get_parent()
		if body == null or not body.has_meta(&"solid"):
			continue
		var cls := StringName(body.get_meta(&"solid"))
		if cls != &"fence" and cls != &"hedge":
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
