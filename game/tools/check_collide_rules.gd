extends SceneTree
## The city objects plan, step 6 (docs/design/drivable-city-build.md "Item 2. Collision answer v2"):
## the collision answer's table (collide_rules.gd) and the car that applies it (car.gd).
##   table    every v2 preset keeps no more along a wall the harder it is met (monotonic in the
##            angle), soft >= mid >= firm, a graze (GRAZE_DEG) keeps 97 / 90 / 80 %; no answer of
##            any preset sends more speed out than went in; the traffic shares (car_keep,
##            shove_side) stay in 0..1 and order as the spec says; the ghosting time
##   numbers  collide_rules.gd's v1 numbers and profile ids are car.gd's own
##   v1       the 12 wall cases (10, 30, 60, 85 deg at 8, 14, 22 m/s): the real car with the
##            default preset (car.gd's own block, untouched) leaves the first contact frame with
##            exactly the velocity the v1 table says (keep_along x exp(-scrape / 60) along the wall,
##            bounce off it), within 0.01 m/s
##   mid      the same 12 cases with --collide=mid's answer: the velocity out is the table's
##            (keep_along along the wall, bounce off it), never more than went in, and the head-on
##            case's nose kicked off the wall
## No map. Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_collide_rules.gd

const Car := preload("res://scripts/car.gd")
const CollideRules := preload("res://scripts/collide_rules.gd")

const ANGLES: Array[float] = [10.0, 30.0, 60.0, 85.0]
const SPEEDS: Array[float] = [8.0, 14.0, 22.0]
## The wall's face toward the car (z), and how far from it the car's nearest corner starts (m).
const FACE := -9.5
const GAP := 0.3
const TOL := 0.01

var _problems: Array[String] = []
var _cases: Array[Dictionary] = []
var _i := -1
var _world: Node3D
var _car: Car
var _prev := Vector3.ZERO
var _yaw0 := 0.0
var _frames := 0


func _initialize() -> void:
	_table()
	_numbers()
	for preset: StringName in [CollideRules.V1, CollideRules.MID]:
		for a in ANGLES:
			for s in SPEEDS:
				_cases.append({"preset": preset, "angle": a, "speed": s})


func _table() -> void:
	var graze := {CollideRules.SOFT: 0.97, CollideRules.MID: 0.90, CollideRules.FIRM: 0.80}
	for p: StringName in graze:
		var k := CollideRules.keep_along(p, CollideRules.GRAZE_DEG)
		if absf(k - float(graze[p])) > 0.0001:
			_problems.append("%s keeps %.3f at a graze (%.0f deg), not %.2f" % [p, k, CollideRules.GRAZE_DEG, graze[p]])
	for p: StringName in CollideRules.PRESETS:
		for prof in [CollideRules.CRUISE, CollideRules.SPORT, CollideRules.GROUNDED]:
			var last := INF
			for a in range(0, 91):
				for s: float in [0.5, 2.0, 5.0, 12.0, 30.0]:
					var ans := CollideRules.answer(p, prof, s, float(a), &"building")
					var out := sqrt(pow(float(ans["keep_along"]), 2.0) + pow(float(ans["bounce"]), 2.0))
					if out > 1.0 + 0.0001:
						_problems.append("%s at %d deg, %.1f m/s sends %.3f of the speed out" % [p, a, s, out])
					if float(ans["keep_along"]) < 0.0 or float(ans["bounce"]) < 0.0 or float(ans["kick_deg"]) < 0.0:
						_problems.append("%s at %d deg: a negative share %s" % [p, a, ans])
				var keep := float(CollideRules.answer(p, prof, 10.0, float(a))["keep_along"])
				if keep > last + 0.00001:
					_problems.append("%s keeps more at %d deg (%.3f) than at %d (%.3f)" % [p, a, keep, a - 1, last])
				last = keep
	for a in range(0, 91, 5):
		var soft := CollideRules.keep_along(CollideRules.SOFT, float(a))
		var mid := CollideRules.keep_along(CollideRules.MID, float(a))
		var firm := CollideRules.keep_along(CollideRules.FIRM, float(a))
		if not (soft >= mid and mid >= firm):
			_problems.append("at %d deg soft %.2f, mid %.2f, firm %.2f are out of order" % [a, soft, mid, firm])
	# The head-on kick: only over HEADON_DEG and HEADON_SPEED, 15-25 deg; v1 never kicks.
	var kick_hi := float(CollideRules.answer(CollideRules.MID, 0, 14.0, 90.0)["kick_deg"])
	var kick_lo := float(CollideRules.answer(CollideRules.MID, 0, 14.0, 76.0)["kick_deg"])
	if not (kick_hi <= 25.0 and kick_lo >= 15.0 and kick_hi >= kick_lo):
		_problems.append("the head-on kick is %.0f-%.0f deg, not 15-25" % [kick_lo, kick_hi])
	if float(CollideRules.answer(CollideRules.MID, 0, 3.0, 90.0)["kick_deg"]) != 0.0 \
			or float(CollideRules.answer(CollideRules.MID, 0, 14.0, 60.0)["kick_deg"]) != 0.0 \
			or float(CollideRules.answer(CollideRules.V1, 0, 14.0, 90.0)["kick_deg"]) != 0.0:
		_problems.append("a kick where there should be none (slow, glancing, or v1)")
	if float(CollideRules.answer(CollideRules.MID, CollideRules.CRUISE, 10.0, 30.0)["yaw_rate"]) != 3.5:
		_problems.append("the nose does not turn at 3.5 rad/s in Cruise")
	# Traffic: v1 keeps CAR_KEEP whatever the hit; v2 by angle (rear-end 0.75, side 0.85, T-bone 0.4).
	for p: StringName in CollideRules.PRESETS:
		for a in range(0, 91, 10):
			for c in range(0, 91, 10):
				var k := CollideRules.car_keep(p, float(a), float(c))
				if k < 0.0 or k > 1.0:
					_problems.append("%s car_keep %.2f at %d / %d deg" % [p, k, a, c])
				if p == CollideRules.V1 and k != Car.CAR_KEEP:
					_problems.append("v1 car_keep is %.2f, not car.gd's %.2f" % [k, Car.CAR_KEEP])
			var sh := CollideRules.shove_side(p, float(a))
			if sh < CollideRules.V1_SHOVE_SIDE - 0.0001 or sh > CollideRules.SHOVE_TBONE + 0.0001:
				_problems.append("%s shove_side %.2f at %d deg" % [p, sh, a])
	var m := CollideRules.MID
	var rear := CollideRules.car_keep(m, 90.0, 0.0)
	var side := CollideRules.car_keep(m, 5.0, 10.0)
	var tbone := CollideRules.car_keep(m, 90.0, 90.0)
	if not (is_equal_approx(rear, 0.75) and side > 0.8 and is_equal_approx(tbone, 0.4)):
		_problems.append("mid traffic shares: rear-end %.2f, side swipe %.2f, T-bone %.2f" % [rear, side, tbone])
	if not is_equal_approx(CollideRules.shove_side(m, 90.0), 0.8) or not is_equal_approx(CollideRules.shove_side(m, 0.0), 0.4) \
			or CollideRules.shove_side(CollideRules.V1, 90.0) != 0.4:
		_problems.append("shove_side is not 0.4 in line, 0.8 for a T-bone (v1 0.4)")
	if CollideRules.ghost_push_time(m, CollideRules.CRUISE) != 0.8 or CollideRules.ghost_push_time(m, CollideRules.SPORT) != Car.GHOST_PUSH_TIME \
			or CollideRules.ghost_push_time(CollideRules.V1, CollideRules.CRUISE) != Car.GHOST_PUSH_TIME:
		_problems.append("the ghosting time is not 0.8 s in Cruise with v2 and car.gd's otherwise")
	if CollideRules.parse("MID") != m or CollideRules.parse("nonsense") != CollideRules.V1 or CollideRules.parse("") != CollideRules.V1:
		_problems.append("parse does not read the presets (unknown words: v1)")
	print("  table: %d presets, keep at 10/45/75/90 deg: %s" % [CollideRules.PRESETS.size(), _keeps()])


func _keeps() -> String:
	var parts := PackedStringArray()
	for p: StringName in CollideRules.PRESETS:
		var ks := PackedStringArray()
		for a: float in [10.0, 45.0, 75.0, 90.0]:
			ks.append("%.2f" % CollideRules.keep_along(p, a))
		parts.append("%s %s" % [p, "/".join(ks)])
	return ", ".join(parts)


func _numbers() -> void:
	var pairs := [
		[CollideRules.V1_SCRAPE, Car.SCRAPE, "SCRAPE"], [CollideRules.V1_SCRAPE_PRESS, Car.SCRAPE_PRESS, "SCRAPE_PRESS"],
		[CollideRules.V1_SCRAPE_MIN, Car.SCRAPE_MIN, "SCRAPE_MIN"], [CollideRules.V1_WALL_TURN, Car.WALL_TURN, "WALL_TURN"],
		[CollideRules.V1_WALL_PUSH, Car.WALL_PUSH, "WALL_PUSH"], [CollideRules.V1_CAR_KEEP, Car.CAR_KEEP, "CAR_KEEP"],
		[CollideRules.V1_GHOST_PUSH, Car.GHOST_PUSH_TIME, "GHOST_PUSH_TIME"],
		[float(CollideRules.CRUISE), float(Car.Handling.CRUISE), "CRUISE"], [float(CollideRules.SPORT), float(Car.Handling.SPORT), "SPORT"],
		[float(CollideRules.GROUNDED), float(Car.Handling.GROUNDED), "GROUNDED"],
	]
	for p: Array in pairs:
		if float(p[0]) != float(p[1]):
			_problems.append("collide_rules.gd's %s is %s, car.gd's %s" % [p[2], p[0], p[1]])
	var fresh := Car.new()
	if fresh.collide != CollideRules.V1:
		_problems.append("a new car's preset is %s, not v1" % fresh.collide)
	fresh.free()


func _physics_process(dt: float) -> bool:
	if _i < 0:
		_next()
		return false
	_frames += 1
	if _car.get_slide_collision_count() > 0:
		_judge(dt)
		if not _next():
			return _finish()
		return false
	if _frames > 900:
		_problems.append("%s %.0f deg %.0f m/s: never touched the wall" % [_cases[_i]["preset"], _cases[_i]["angle"], _cases[_i]["speed"]])
		if not _next():
			return _finish()
		return false
	_prev = _car.vel
	return false


func _next() -> bool:
	if _world != null:
		_world.free()
		_world = null
	_i += 1
	if _i >= _cases.size():
		return false
	var c := _cases[_i]
	_world = Node3D.new()
	root.add_child(_world)
	var wall := StaticBody3D.new()
	wall.set_meta(&"solid", &"wall")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 4.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0.0, 2.0, FACE - 0.5)
	_world.add_child(wall)
	_car = Car.new()
	_car.collide = c["preset"]
	_world.add_child(_car)
	var a := deg_to_rad(float(c["angle"]))
	var d := Vector3(cos(a), 0.0, -sin(a))
	# The car's corner nearest the wall GAP m from it: the touch comes within a few frames, near the speed set.
	_car.global_position = Vector3(0.0, 0.0, FACE + 2.0 * sin(a) + 0.9 * cos(a) + GAP)
	_car.rotation.y = atan2(-d.x, -d.z)
	_yaw0 = _car.rotation.y
	_car.vel = d * float(c["speed"])
	_car.forward_speed = float(c["speed"])
	_prev = _car.vel
	_frames = 0
	return true


## The first contact frame: what went in (the frame before, less the coast of the car's own step)
## against what came out.
func _judge(dt: float) -> void:
	var c := _cases[_i]
	var preset: StringName = c["preset"]
	var s0 := Vector3(_prev.x, 0.0, _prev.z).length()
	var v_in := Vector3(_prev.x, 0.0, _prev.z).normalized() * (s0 - 5.0 * dt)
	var s := v_in.length()
	var n := Vector3(0.0, 0.0, 1.0)
	var t := Vector3(1.0, 0.0, 0.0)
	var angle := rad_to_deg(asin(clampf(-v_in.normalized().dot(n), 0.0, 1.0)))
	var ans := CollideRules.answer(preset, _car.handling, s, angle, &"wall")
	var out := Vector3(_car.vel.x, 0.0, _car.vel.z)
	var along := out.dot(t)
	var off := out.dot(n)
	var want_along := s * float(ans["keep_along"])
	if preset == CollideRules.V1:
		want_along *= exp(-float(ans["scrape"]) * dt)
	var want_off := s * float(ans["bounce"])
	var ok := absf(absf(along) - want_along) <= TOL and absf(off - want_off) <= TOL and out.length() <= s + TOL
	var note := ""
	if preset == CollideRules.MID and float(ans["kick_deg"]) > 0.0:
		var turned := rad_to_deg(absf(angle_difference(_yaw0, _car.rotation.y)))
		note = ", the nose turned %.0f deg" % turned
		ok = ok and turned >= float(ans["kick_deg"]) - 0.5
	if not ok:
		_problems.append("%s %.0f deg %.0f m/s: out %.3f along, %.3f off; the table says %.3f, %.3f" % [preset, c["angle"], c["speed"],
				absf(along), off, want_along, want_off])
	print("  %-4s %2.0f deg %4.1f m/s in: out %6.3f along, %5.3f off (table %6.3f, %5.3f)%s %s" % [preset, angle, s, absf(along), off,
			want_along, want_off, note, "ok" if ok else "FAIL"])


func _finish() -> bool:
	if _world != null:
		_world.free()
		_world = null
	if _problems.is_empty():
		print("check_collide_rules: OK (%d wall cases, v1 and mid)" % _cases.size())
		quit(0)
	else:
		for p in _problems:
			printerr("check_collide_rules: " + p)
		print("check_collide_rules: %d PROBLEM(S)" % _problems.size())
		quit(1)
	return true
