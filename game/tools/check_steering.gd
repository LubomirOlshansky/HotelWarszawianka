extends SceneTree
## Loop 2a: an input replay for the car's steering. Scripted stick, key and pedal inputs
## over time drive the real car script on a flat test ground (with walls where a test
## needs them) through the same input mapping and follow camera as the game, and the
## heading, speed and the car's place on screen are logged and measured: a held
## direction (does it get there, circle or oscillate), the turn radius at 20/50/90 km/h,
## a 90° turn from those speeds and from a standstill, pointing straight back, letting go
## (the camera coming round), the Mac keys, Classic's self-centring, sliding along a wall,
## a head-on wall, and getting out of an inside corner. The driving-feel loop (2026-10-30): a
## bollard clipped by the front corner, a stopped car clipped by it, and a stopped car square
## ahead (cars are kinematic bodies, like traffic's): the car must get past each. Camera loop: the camera is the game's
## own (follow_camera.gd), and three camera tests join: braking from 90 km/h (does the view
## slide back?), a small steering wiggle in Classic (does the view shake?), and the camera's
## turn rate in every test (never over 64°/s; never while Point's finger is down). Exits 1 on a
## problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_steering.gd
##   -- --legacy     the car, input mapping and camera before loop 2a (the "before" numbers;
##                   tools/steering_legacy_car.gd is the car script as it was)
##   -- --camera=2a  today's car and controls with loop 2a's camera (the camera loop's "before")
##   -- --verbose    also print every test's log, one line per 0.5 s (--every=N: per N frames)
##   -- --only=NAME  run only the tests whose name starts with NAME
##   -- --collide=v1 also run the v2 wall matrix with that preset (numbers only; the before of
##                   the table; --collide=soft|firm the same for another preset)
##
## The city objects plan, step 6 (docs/design/drivable-city-build.md item 2): the v2 wall matrix,
## with the `mid` preset (collide_rules.gd): a wall met at 10, 30, 60 and 90 deg from 1 m off it at
## 30 and 60 km/h, in Classic, Point and Fixed, Cruise, Sport and Grounded (72 runs, `v2_...`), each
## held into the wall (the gas, or the stick the way it started): no dead stop (contact_log.gd's
## rule: DEAD_SHARE of the speed and DEAD_LOST m/s gone within DEAD_TIME s), no unstick, moving at
## the end, the speed kept 1 s after the touch, the heading and the time pinned; and head-on at
## 50 km/h in every scheme and profile (`v2_..._headon50`): driving again at 15 km/h or more 1 s
## after the touch. The older tests keep the default preset (v1, today's answer).
##
## Screen positions are in pixels on an iPhone's landscape screen (2532 x 1170) at the
## game's default view height. Headings are compass degrees (0 north, 90 east).

const LegacyCar := preload("res://tools/steering_legacy_car.gd")
const Car := preload("res://scripts/car.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const CollideRules := preload("res://scripts/collide_rules.gd")
const ContactLog := preload("res://scripts/contact_log.gd")

const PITCH := -30.0
const SCREEN := Vector2(2532, 1170)
const KMH := 1.0 / 3.6
## The view height (m) before loop 2a.
const LEGACY_SIZE := 110.0

var legacy := false
## --camera=2a: loop 2a's camera (before the camera loop) with today's car and controls.
var camera_2a := false
var verbose := false
var only := ""
## --collide=PRESET: the v2 wall matrix is run with this preset as well (numbers only).
var extra_preset := &""
var _every := 30
var _tests: Array[Dictionary] = []
var _i := -1
var _test: Dictionary
var _scheme := ""
var _t := 0.0
var _car: CharacterBody3D
var _world: Node3D
var _ctl: RefCounted
var _cam := {}
var _rows: Array[Dictionary] = []
var _held_dir := Vector3.ZERO
var _fc: RefCounted
var _lead_vel_2a := Vector3.ZERO
var _results: Array[String] = []
var _problems := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--legacy":
			legacy = true
		elif a == "--camera=2a":
			camera_2a = true
		elif a == "--verbose":
			verbose = true
		elif a.begins_with("--every="):
			_every = maxi(1, int(a.trim_prefix("--every=")))
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--collide="):
			extra_preset = CollideRules.parse(a.trim_prefix("--collide="))
	_plan()
	print("check_steering: %s, %d runs" % ["BEFORE loop 2a (legacy car, mapping and camera)" if legacy
			else "loop 2a car and controls, loop 2a camera (before the camera loop)" if camera_2a
			else "loop 2a car and controls, the camera loop's camera", _tests.size()])


func _plan() -> void:
	var point_schemes := ["follow", "fixed"] if legacy else ["point", "fixed"]
	var all_schemes := point_schemes + ["classic"]
	for v in [20.0, 50.0, 90.0]:
		_add({"name": "radius_%d" % v, "schemes": ["car"], "v0": v * KMH, "dur": 4.0, "kind": "radius"})
	for s in point_schemes:
		# The stick held towards a compass heading (the car starts going north at 50 km/h):
		# 90° right, 45°, 15°, and straight behind.
		_add({"name": "hold_right", "schemes": [s], "v0": 50 * KMH, "dur": 10.0, "kind": "hold", "aim": 90.0})
		_add({"name": "hold_diagonal", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 45.0})
		_add({"name": "hold_slight", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 15.0})
		_add({"name": "behind", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 180.0})
		# Held 90° right for 2.5 s, then let go: how the camera comes round behind the car.
		_add({"name": "release", "schemes": [s], "v0": 50 * KMH, "dur": 7.0, "kind": "hold", "aim": 90.0, "until": 2.5})
	# The Mac keyboard, D held: Point points at the screen's right (before loop 2a the keys
	# steered car-relative, so a held D circled; in Classic it still steers, by design).
	_add({"name": "keys_right", "schemes": [point_schemes[0]], "v0": 50 * KMH, "dur": 8.0, "kind": "hold",
			"aim": 90.0, "keys": {"right": true, "up": true}})
	# Classic: full right for 0.6 s, then the stick back to the middle (gas held): how fast the
	# turning stops (self-centring) and how far it carries on.
	_add({"name": "steer_release", "schemes": ["classic"], "v0": 50 * KMH, "dur": 4.0, "kind": "release"})
	for s in all_schemes:
		for v in [0.0, 20.0, 50.0, 90.0]:
			_add({"name": "turn90_%d" % v, "schemes": [s], "v0": v * KMH, "dur": 6.0, "kind": "turn90"})
		_add({"name": "wall_glance", "schemes": [s], "v0": 50 * KMH, "dur": 4.0, "kind": "wall", "heading": 60.0,
				"walls": [[Vector3(0, 2, -16), Vector3(400, 4, 1)]]})
		# Walls redirect, never stop (road-objects.md 7.1): head-on slides off without the unstick.
		_add({"name": "wall_headon", "schemes": [s], "v0": 20 * KMH, "dur": 5.0, "kind": "wall", "heading": 0.0,
				"walls": [[Vector3(0, 2, -12), Vector3(400, 4, 1)]], "pin_max": 1.0, "unstick_max": 0})
		# Into an inside corner, held there 3 s, then pointing back out (Classic: reversing).
		_add({"name": "corner", "schemes": [s], "v0": 15 * KMH, "dur": 6.0, "kind": "wall", "heading": 45.0, "out_at": 3.0,
				"walls": [[Vector3(-20, 2, -14.5), Vector3(40, 4, 1)], [Vector3(0.5, 2, 5), Vector3(1, 4, 40)]],
				"start": Vector3(-9, 0, -4)})
		if not legacy:
			# The driving-feel loop: a bollard under the right front corner, a stopped car's corner
			# there, a stopped car square ahead (going round it, not sitting behind it: Point and
			# Fixed steer round; Classic slides off it as off a wall).
			_add({"name": "post_clip", "schemes": [s], "v0": 40 * KMH, "dur": 4.0, "kind": "wall", "heading": 0.0,
					"walls": [[Vector3(0.75, 1, -10), Vector3(0.3, 2, 0.3)]], "past": -12.0})
			_add({"name": "car_clip", "schemes": [s], "v0": 40 * KMH, "dur": 4.0, "kind": "wall", "heading": 0.0,
					"cars": [[Vector3(1.3, 0.85, -14), Vector3(1.8, 1.5, 4.2)]], "past": -18.0})
			# A stopped car square ahead, the gas held: Point steers round it, Classic slides off it
			# like off a wall once it has pushed CAR_PUSH_TIME (road-objects.md 7.1).
			_add({"name": "car_behind", "schemes": [s], "v0": 25 * KMH, "dur": 7.0, "kind": "wall", "heading": 0.0,
					"cars": [[Vector3(0, 0.85, -12), Vector3(1.8, 1.5, 4.2)]], "past": -16.0})
		if not legacy and s != "classic":
			# G17: boxed in by four stopped cars (0.3 m of air ahead and behind, side by side): ghosts through the one
			# ahead after 1.5 s and is past it well inside the 8 s a tow would take.
			_add({"name": "car_sandwich", "schemes": [s], "v0": 0.0, "dur": 8.0, "kind": "wall", "heading": 0.0,
					"cars": [[Vector3(0, 0.85, -4.4), Vector3(1.8, 1.5, 4.2)], [Vector3(0, 0.85, 4.4), Vector3(1.8, 1.5, 4.2)],
					[Vector3(-1.85, 0.85, 0), Vector3(1.8, 1.5, 4.2)], [Vector3(1.85, 0.85, 0), Vector3(1.8, 1.5, 4.2)]],
					"past": -10.0, "pin_max": 3.0})
	if legacy:
		return
	# Classic's strip held right into a head-on wall (for 1.5 s, then straight): it slides off to the right (east).
	_add({"name": "wall_headon_right", "schemes": ["classic"], "v0": 20 * KMH, "dur": 5.0, "kind": "wall", "heading": 0.0,
			"walls": [[Vector3(0, 2, -12), Vector3(400, 4, 1)]], "pin_max": 1.0, "unstick_max": 0, "strip": 0.5,
			"strip_until": 1.5, "end_heading": 90.0})
	# Camera loop: straight on at about 90 km/h for 2.5 s (the look-ahead settles), then the brake
	# to a stop: does the view slide back towards the car?
	for s in ["classic", point_schemes[0]]:
		_add({"name": "brake_90", "schemes": [s], "v0": 90 * KMH, "dur": 6.0, "kind": "brake", "brake_at": 2.5})
	# A thumb that can't keep still: Classic at 50 km/h, the strip wobbling ±0.35 at 1.2 Hz.
	_add({"name": "wiggle", "schemes": ["classic"], "v0": 50 * KMH, "dur": 8.0, "kind": "wiggle"})
	# Step 6: the v2 wall matrix (mid, gated; --collide= another preset beside it, numbers only).
	var presets: Array[StringName] = [CollideRules.MID]
	if extra_preset != &"" and extra_preset != CollideRules.MID:
		presets.append(extra_preset)
	for preset in presets:
		for prof: String in ["cruise", "sport", "grounded"]:
			for v in [30.0, 60.0]:
				for ang in [10.0, 30.0, 60.0, 90.0]:
					_add(_v2_case("v2_%s_%s_%d_%d" % [preset, prof, ang, v], preset, prof, v, ang, all_schemes))
			_add(_v2_case("v2_%s_%s_headon50" % [preset, prof], preset, prof, 50.0, 90.0, all_schemes))
			# Rounding a building's corner: the stick held north-east, the car sliding east along the
			# block's south face at 40 km/h until the face ends at x = 0 (the corner pivot's case).
			_add({"name": "v2_%s_%s_round" % [preset, prof], "schemes": point_schemes, "v0": 40 * KMH, "dur": 4.0, "kind": "wall",
					"heading": 80.0, "aim": 10.0, "walls": [[Vector3(-20, 2, -21.5), Vector3(40, 4, 20)]], "start": Vector3(-14, 0, -9.8),
					"collide": preset, "profile": prof, "unstick_max": 0, "v2": true, "gate": preset == CollideRules.MID,
					"past_x": 1.0})


## Step 6: a wall along x met at `ang` deg (0 parallel, 90 head-on) at `v` km/h, the car's corner
## nearest it 1 m off, held into it for 3 s, with the preset and handling profile named.
func _v2_case(name: String, preset: StringName, prof: String, v: float, ang: float, schemes: Array) -> Dictionary:
	var a := deg_to_rad(ang)
	var face := -11.5
	var t := {"name": name, "schemes": schemes, "v0": v * KMH, "dur": 3.0, "kind": "wall", "heading": 90.0 - ang,
			"walls": [[Vector3(0, 2, face - 0.5), Vector3(400, 4, 1)]], "start": Vector3(0, 0, face + 2.0 * sin(a) + 0.9 * cos(a) + 1.0),
			"collide": preset, "profile": prof, "unstick_max": 0, "v2": true}
	if preset == CollideRules.MID:
		t["gate"] = true
		if name.ends_with("headon50"):
			t["again_kmh"] = 15.0
	return t


func _add(t: Dictionary) -> void:
	if only != "" and not String(t["name"]).begins_with(only):
		return
	for s in t["schemes"]:
		var copy := t.duplicate()
		copy["scheme"] = s
		_tests.append(copy)


# --- running ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> bool:
	if _i < 0 or _t >= float(_test["dur"]):
		if _i >= 0:
			_finish_test()
		_i += 1
		if _i >= _tests.size():
			_summary()
			return true
		_start_test()
	_step(delta)
	_t += delta
	return false


func _start_test() -> void:
	_test = _tests[_i]
	_scheme = _test["scheme"]
	_t = 0.0
	_rows.clear()
	_world = Node3D.new()
	root.add_child(_world)
	for w in _test.get("walls", []):
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		shape.shape = box
		body.add_child(shape)
		body.position = w[0]
		_world.add_child(body)
	for c in _test.get("cars", []):
		# A stopped car, as traffic's (a kinematic body that the car can't move).
		var car := AnimatableBody3D.new()
		car.sync_to_physics = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = c[1]
		shape.shape = box
		car.add_child(shape)
		car.position = c[0]
		_world.add_child(car)
	_car = LegacyCar.new() if legacy else Car.new()
	if _test.has("profile"):
		_car.set_handling(Car.parse_handling(_test["profile"]))
	if _test.has("collide"):
		_car.collide = _test["collide"]
	_world.add_child(_car)
	var heading: float = _test.get("heading", 0.0)
	_car.global_position = _test.get("start", Vector3.ZERO)
	_car.rotation.y = -deg_to_rad(heading)
	var v0: float = _test["v0"]
	_car.vel = _fwd(heading) * v0
	_car.forward_speed = v0
	_ctl = null if legacy else Controls.new()
	if _ctl != null:
		_ctl.scheme = {"point": Controls.POINT, "fixed": Controls.FIXED, "classic": Controls.CLASSIC}.get(_scheme, Controls.POINT)
	var follow: bool = _scheme in ["follow", "point", "classic", "car"]
	# The camera starts settled: behind the car when following, on the 45° diagonal when fixed.
	var yaw := rad_to_deg(_car.rotation.y) if follow else 45.0
	var size := LEGACY_SIZE if legacy else FollowCamera.DEFAULT_SIZE
	_cam = {"yaw": yaw, "yaw_target": yaw, "follow": follow, "focus": _car.global_position, "size": size, "base": size}
	_held_dir = Vector3.ZERO
	_fc = FollowCamera.new()
	_lead_vel_2a = Vector3.ZERO
	if not legacy:
		# Camera loop: the view starts settled too (loop 2a's numbers in README started it at the
		# car with no look-ahead: the car slid across the screen as it caught up, which a car that
		# speeds up gradually never shows, and that slide was most of those tests' px/s).
		_warm_camera()


func _finish_test() -> void:
	var line := _measure() + _camera_rules()
	_results.append(line)
	print(line)
	if verbose:
		_print_log()
	_world.queue_free()
	_world = null
	_car = null


## One physics step: this test's input → the car's controls (as the game maps them) →
## the camera (as the game moves it). The car itself moves in its own physics step.
func _step(dt: float) -> void:
	var inp := _input()
	if legacy:
		_legacy_controls(inp)
		_legacy_camera(dt)
	else:
		_new_controls(inp, dt)
		_new_camera(dt)
	_record(inp)


## What the player does in this test, at time _t.
func _input() -> Dictionary:
	var kind: String = _test["kind"]
	var inp := {"stick": Vector2.ZERO, "gas": false, "brake": false, "steer": 0.0, "direct": false}
	var v0: float = _test["v0"]
	if kind == "radius":
		# Full lock to the right at a held speed: the car's own turning, whatever the scheme.
		inp["direct"] = true
		inp["steer"] = -1.0
		inp["hold"] = v0
		return inp
	if kind == "hold":
		if _test.has("keys"):
			inp["keys"] = _test["keys"]
		elif _t < float(_test.get("until", INF)):
			inp["stick"] = _stick_for(_test["aim"])
		return inp
	if kind == "release":
		inp["gas"] = true
		inp["stick"] = Vector2(1.0 if _t < 0.6 else 0.0, 0.0)
		return inp
	if kind == "turn90":
		# Turn to 90° right of the start heading (east), at full gas.
		if _scheme == "classic":
			inp["gas"] = true
			# A driver: full lock until 25° short, then easing the stick back to the middle.
			var err := _wrap(90.0 - _go_heading())
			inp["stick"] = Vector2(clampf(err / 25.0, -1.0, 1.0), 0.0)
		else:
			inp["stick"] = _stick_for(90.0)
		return inp
	if kind == "brake":
		var braking: bool = _t >= float(_test["brake_at"])
		var kmh: float = _car.vel.length() * 3.6
		if _scheme == "classic":
			inp["gas"] = not braking and kmh < 90.0
		elif not braking:
			# Point: pushed far enough for 90 km/h (a target speed), straight up the screen.
			var push: float = Controls.DEAD + 90.0 / 3.6 / _car.max_speed * (Controls.FULL - Controls.DEAD)
			inp["stick"] = _stick_for(0.0) * push
		# Held on at a standstill the brake would reverse: let go once stopped.
		inp["brake"] = braking and (kmh > 0.5 or not _test.has("stopped"))
		if braking and kmh <= 0.5:
			_test["stopped"] = true
		return inp
	if kind == "wiggle":
		inp["gas"] = _car.vel.length() * 3.6 < 50.0
		inp["stick"] = Vector2(0.35 * sin(TAU * 1.2 * _t), 0.0)
		return inp
	if kind == "wall":
		# Keep going the way the car started (into the wall).
		var heading: float = _test.get("heading", 0.0)
		var out: bool = _t >= float(_test.get("out_at", INF))
		if _scheme == "classic":
			# Getting out: reverse while still facing the corner (0, -14); once it faces away, gas.
			var to_corner := Vector3(0.0, 0.0, -14.0) - _car.global_position
			var facing := (-_car.global_transform.basis.z).dot(to_corner) > 0.0
			inp["gas"] = not out or not facing
			inp["brake"] = out and facing
			if _test.has("strip") and _t < float(_test.get("strip_until", INF)):
				inp["stick"] = Vector2(float(_test["strip"]), 0.0)
		elif out:
			inp["stick"] = _stick_for(heading + 180.0, "_stick_out")
		else:
			inp["stick"] = _stick_for(float(_test.get("aim", heading)))
		return inp
	return inp


## The stick (screen space) that points at compass heading `c` with the camera as it was
## when the test started (the finger goes down at t = 0 and stays put).
func _stick_for(c: float, key := "_stick") -> Vector2:
	if not _test.has(key):
		var view := -float(_cam["yaw"])  # compass heading the camera looks along
		var rel := deg_to_rad(c - view)
		_test[key] = Vector2(sin(rel), -cos(rel))
	return _test[key]


# --- the controls and camera before loop 2a (main.gd's _read_input / _update_camera) ---------

func _legacy_controls(inp: Dictionary) -> void:
	if inp["direct"]:
		_car.target_dir = Vector3.ZERO
		_car.steer = inp["steer"]
		_car.braking = false
		_car.throttle = clampf((float(inp["hold"]) - _car.forward_speed) * 3.0, 0.0, 1.0)
		return
	var stick: Vector2 = inp["stick"]
	if inp.has("keys"):
		# Before loop 2a the keys were car-relative in every scheme: A / D steer, W gas.
		var k: Dictionary = inp["keys"]
		_car.target_dir = Vector3.ZERO
		_car.steer = float(k.get("left", false)) - float(k.get("right", false))
		_car.throttle = 1.0 if k.get("up", false) else 0.0
		_car.braking = false
		return
	if _scheme == "classic":
		# Before loop 2a the keyboard was car-relative: A / D steer, W gas (keys are all or nothing).
		_car.target_dir = Vector3.ZERO
		_car.steer = -signf(stick.x) if absf(stick.x) > 0.5 else 0.0
		_car.throttle = 1.0 if inp["gas"] else 0.0
	elif stick.length() > 0.2:
		_car.target_dir = _screen_to_world(stick, _cam["yaw"]).normalized()
		_car.throttle = clampf((stick.length() - 0.2) / 0.8, 0.0, 1.0)
		_car.steer = 0.0
	else:
		_car.target_dir = Vector3.ZERO
		_car.throttle = 0.0
	_car.braking = inp["brake"]
	if _held_dir == Vector3.ZERO and _car.target_dir != Vector3.ZERO:
		_held_dir = _car.target_dir


func _legacy_camera(dt: float) -> void:
	var speed: float = absf(_car.forward_speed)
	if _cam["follow"]:
		var heading := rad_to_deg(_car.rotation.y)
		var rate := 2.2 * clampf(speed / 8.0, 0.0, 1.0)
		_cam["yaw"] = rad_to_deg(lerp_angle(deg_to_rad(_cam["yaw"]), deg_to_rad(heading), 1.0 - exp(-rate * dt)))
	else:
		_cam["yaw"] = lerpf(_cam["yaw"], _cam["yaw_target"], 1.0 - exp(-8.0 * dt))
	var lead: Vector3 = _car.vel * 0.6
	if lead.length() > 22.0:
		lead = lead.normalized() * 22.0
	var size: float = _cam["base"] * (1.0 + 0.25 * clampf(speed / _car.max_speed, 0.0, 1.0))
	_cam["focus"] = (_cam["focus"] as Vector3).lerp(_car.global_position + lead, 1.0 - exp(-3.5 * dt))
	_cam["size"] = lerpf(_cam["size"], size, 1.0 - exp(-2.5 * dt))


# --- the loop 2a controls (drive_controls.gd) and the camera (follow_camera.gd), as main.gd uses them ---

func _new_controls(inp: Dictionary, dt: float) -> void:
	if inp["direct"]:
		_car.target_dir = Vector3.ZERO
		_car.steer = inp["steer"]
		_car.braking = false
		_car.throttle = float(inp["hold"]) / _car.max_speed
		return
	var stick: Vector2 = inp["stick"]
	var keys: Dictionary = inp.get("keys", {"left": false, "right": false, "up": false, "down": false, "brake": false})
	if inp.has("keys") and _scheme != "classic":
		keys = keys.duplicate()
		keys["up"] = false  # Point: W would point up the screen too; D alone points right
	_ctl.drive(_car, stick, stick != Vector2.ZERO, keys, inp["gas"], inp["brake"], _cam["yaw"], dt)
	if _held_dir == Vector3.ZERO and _car.target_dir != Vector3.ZERO:
		_held_dir = _car.target_dir


func _new_camera(dt: float) -> void:
	_camera_step(_car.global_position, _car.vel, rad_to_deg(_car.rotation.y), absf(_car.forward_speed), dt)


## One step of the camera for a car at `pos` going `vel` (heading in degrees, rotation.y).
func _camera_step(pos: Vector3, vel: Vector3, heading: float, speed: float, dt: float) -> void:
	if camera_2a:
		_camera_2a(pos, vel, heading, speed, dt)
		return
	# The game's follow camera (main.gd _update_camera with follow_camera.gd), without the
	# pixel-grid snap.
	if _cam["follow"]:
		var classic: bool = _ctl.scheme == Controls.CLASSIC
		_cam["yaw"] = _fc.follow_yaw(_cam["yaw"], heading, speed, _ctl.camera_waits(), _ctl.held, _ctl.since_release,
				FollowCamera.FULL_SPEED if classic else FollowCamera.FULL_SPEED_POINT, dt,
				FollowCamera.TURN_GAIN if classic else FollowCamera.RETURN_GAIN)
	else:
		_fc.stop_turning()
		_cam["yaw"] = lerpf(_cam["yaw"], _cam["yaw_target"], 1.0 - exp(-8.0 * dt))
	var basis := Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(_cam["yaw"]), 0.0))
	var base: float = _cam["base"]
	var zoom: float = base * FollowCamera.SPEED_ZOOM * clampf(speed / _car.max_speed, 0.0, 1.0)
	_cam["size"] = _fc.zoom_step(_cam["size"], base, zoom, dt)
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized() if _cam["follow"] and _ctl.scheme == Controls.CLASSIC \
			else Vector3.ZERO
	var lead: Vector3 = _fc.lead_step(vel, _car.max_speed, _cam["size"], dt, forward)
	_cam["focus"] = _fc.focus_step(_cam["focus"], pos + lead, basis, _cam["size"], FollowCamera.FOCUS_RATE, dt)


## Camera loop: the camera starts settled, as if the car had been going `vel` straight on for
## 4 s (its centre, look-ahead, lag and speed zoom all steady), in either camera.
func _warm_camera() -> void:
	var p := _car.global_position
	var v := Vector3(_car.vel.x, 0.0, _car.vel.z)
	var heading := rad_to_deg(_car.rotation.y)
	_cam["focus"] = p - v * 4.0
	for k in 240:
		_camera_step(p - v * (4.0 - (k + 1) / 60.0), v, heading, v.length(), 1.0 / 60.0)


## Loop 2a's camera, as drive_controls.gd and main.gd had it before the camera loop: the follow
## yaw as a first-order lerp (Classic 2.2/s; Point 1.0/s eased in over 0.8 s after the 0.6 s
## hold), the lead as 0.5 s of the velocity smoothed over 0.7 s (at most a fifth of the view),
## the centre and the speed zoom as plain lerps.
func _camera_2a(pos: Vector3, vel: Vector3, heading: float, speed: float, dt: float) -> void:
	if _cam["follow"]:
		var rate := 2.2 * clampf(speed / 8.0, 0.0, 1.0)
		var turn := true
		if _ctl.scheme != Controls.CLASSIC:
			turn = not (_ctl.held or _ctl.since_release < 0.6)
			rate = 1.0 * smoothstep(0.6, 1.4, _ctl.since_release) * clampf(speed / 3.0, 0.0, 1.0)
		if turn:
			_cam["yaw"] = rad_to_deg(lerp_angle(deg_to_rad(_cam["yaw"]), deg_to_rad(heading), 1.0 - exp(-rate * dt)))
	else:
		_cam["yaw"] = lerpf(_cam["yaw"], _cam["yaw_target"], 1.0 - exp(-8.0 * dt))
	var size: float = _cam["base"] * (1.0 + 0.25 * clampf(speed / _car.max_speed, 0.0, 1.0))
	_lead_vel_2a = _lead_vel_2a.lerp(Vector3(vel.x, 0.0, vel.z), 1.0 - exp(-dt / 0.7))
	var lead: Vector3 = (_lead_vel_2a * 0.5).limit_length(float(_cam["size"]) * 0.2)
	_cam["focus"] = (_cam["focus"] as Vector3).lerp(pos + lead, 1.0 - exp(-6.0 * dt))
	_cam["size"] = lerpf(_cam["size"], size, 1.0 - exp(-2.5 * dt))


# --- logging and measuring ---------------------------------------------------------------------

func _record(inp: Dictionary) -> void:
	var p := _car.global_position
	var b := Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(_cam["yaw"]), 0.0))
	var off: Vector3 = p - _cam["focus"]
	var size: float = _cam["size"]
	var sx := off.dot(b.x) / (size * SCREEN.x / SCREEN.y) * SCREEN.x + SCREEN.x * 0.5
	var sy := -off.dot(b.y) / size * SCREEN.y + SCREEN.y * 0.5
	var moved := 0.0
	if not _rows.is_empty():
		moved = Vector2(p.x - float(_rows.back()["x"]), p.z - float(_rows.back()["z"])).length() * 60.0
	_rows.append({"t": _t, "x": p.x, "z": p.z, "heading": _body_heading(), "go": _go_heading(),
			"speed": _car.vel.length(), "moved": moved, "fs": _car.forward_speed, "cam": -float(_cam["yaw"]),
			"sx": sx, "sy": sy, "contact": _car.get_slide_collision_count() > 0,
			"braking": _car.get("brakes_on") if _car.get("brakes_on") != null else _car.braking,
			"held": _held_dir, "size": size, "fx": (_cam["focus"] as Vector3).x, "fz": (_cam["focus"] as Vector3).z,
			"finger": inp["stick"] != Vector2.ZERO or inp.has("keys") and _t < float(_test.get("until", INF))})


func _body_heading() -> float:
	var f := -_car.global_transform.basis.z
	return fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0)


## Where the car is going: its velocity's heading (its body's when nearly still).
func _go_heading() -> float:
	if _car.vel.length() < 0.5:
		return _body_heading()
	return fposmod(rad_to_deg(atan2(_car.vel.x, -_car.vel.z)), 360.0)


static func _fwd(compass: float) -> Vector3:
	return Vector3(sin(deg_to_rad(compass)), 0.0, -cos(deg_to_rad(compass)))


static func _wrap(a: float) -> float:
	return wrapf(a, -180.0, 180.0)


static func _compass(v: Vector3) -> float:
	return fposmod(rad_to_deg(atan2(v.x, -v.z)), 360.0)


func _screen_to_world(s: Vector2, yaw: float) -> Vector3:
	var b := Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(yaw), 0.0))
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var ahead := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	return right * s.x + ahead * -s.y


func _measure() -> String:
	var name := "%-14s %-8s" % [_test["name"], _scheme]
	match String(_test["kind"]):
		"radius":
			return name + _m_radius()
		"hold":
			return name + _m_hold()
		"release":
			return name + _m_release()
		"turn90":
			return name + _m_turn90()
		"wall":
			return name + _m_wall()
		"brake":
			return name + _m_brake()
		"wiggle":
			return name + _m_wiggle()
	return name


## Steady full-lock radius over the last 2 s: mean speed over mean turn rate of the path.
func _m_radius() -> String:
	var turn := 0.0
	var dist := 0.0
	var n := 0
	for k in range(1, _rows.size()):
		if _rows[k]["t"] < 2.0:
			continue
		turn += absf(_wrap(_rows[k]["go"] - _rows[k - 1]["go"]))
		dist += Vector2(_rows[k]["x"] - _rows[k - 1]["x"], _rows[k]["z"] - _rows[k - 1]["z"]).length()
		n += 1
	var r := dist / maxf(deg_to_rad(turn), 0.0001)
	var v: float = _rows.back()["speed"]
	return "full-lock radius %5.1f m at %3.0f km/h (yaw %.2f rad/s, sideways pull %.1f m/s² = %.1f g)" % [
			r, v * 3.6, v / r, v * v / r, v * v / r / 9.81]


## A held stick: the error between where the car goes and where the stick pointed when the
## finger went down; total turn (full circles), settling, overshoot and oscillation.
func _m_hold() -> String:
	var held: Vector3 = _rows.back()["held"]
	var want := _compass(held)
	var total := 0.0
	var errs := PackedFloat32Array()
	for k in _rows.size():
		if k > 0:
			total += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		errs.append(_wrap(_rows[k]["go"] - want))
	var settle := _settle_time(errs, 5.0)
	var first_in := -1
	for k in errs.size():
		if absf(errs[k]) < 5.0:
			first_in = k
			break
	var over := 0.0
	var flips := 0
	if first_in >= 0:
		var side := signf(errs[0])
		for k in range(first_in, errs.size()):
			if signf(errs[k]) == -side:
				over = maxf(over, absf(errs[k]))
		for k in range(first_in + 1, errs.size()):
			if absf(errs[k]) > 1.0 and absf(errs[k - 1]) > 1.0 and signf(errs[k]) != signf(errs[k - 1]):
				flips += 1
	var min_speed := INF
	var brake_t := 0.0
	for r in _rows:
		min_speed = minf(min_speed, r["speed"])
		if r["braking"]:
			brake_t += 1.0 / 60.0
	var circles := absf(total) / 360.0
	var final_err := errs[errs.size() - 1]
	var swing := _swing()
	if _test.has("until"):
		# After letting go: when the camera is within 10° of the car's heading, and how fast it turned.
		var aligned := -1.0
		var fastest := 0.0
		for k in range(1, _rows.size()):
			if _rows[k]["t"] < float(_test["until"]):
				continue
			fastest = maxf(fastest, absf(_wrap(_rows[k]["cam"] - _rows[k - 1]["cam"])) * 60.0)
			if aligned < 0.0 and absf(_wrap(_rows[k]["cam"] - _rows[k]["heading"])) < 10.0:
				aligned = _rows[k]["t"] - float(_test["until"])
		swing += " | let go at %.1f s: camera behind the car %s after, turning at most %.0f°/s, the car at %.0f km/h at the end" % [
				_test["until"], ("%.1f s" % aligned) if aligned >= 0.0 else "never", fastest, _rows.back()["speed"] * 3.6]
	var ok := circles < 0.75 and absf(final_err) < 5.0 and over < 10.0
	if not ok and not legacy:
		_problems += 1
	var errs_line := ""
	for t in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0]:
		var k := mini(int(t * 60.0), errs.size() - 1)
		errs_line += " %+4.0f" % errs[k]
	return "aim %03.0f° | error at 0.5/1/1.5/2/3/4/6/8 s:%s | turned %4.0f° (%.1f circles) | settles in %s | overshoot %2.0f° | flips %d | min %3.0f km/h, braked %.1f s | %s%s" % [
			want, errs_line, total, circles, ("%.1f s" % settle) if settle >= 0.0 else "never", over, flips,
			min_speed * 3.6, brake_t, swing, "" if ok or legacy else "  <-- PROBLEM"]


## Classic, steer and let go: the yaw rate when the stick returns, how long until the car stops
## turning (under 0.05 rad/s), and how far it turns after the release.
func _m_release() -> String:
	var k0 := int(0.6 * 60.0)
	var rate0 := 0.0
	var settle := -1.0
	var after := 0.0
	for k in range(k0, _rows.size()):
		var rate := absf(_wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])) * 60.0
		if k == k0:
			rate0 = rate
		if k > k0:
			after += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		if settle < 0.0 and k > k0 and rate < rad_to_deg(0.05):
			settle = (k - k0) / 60.0
	return "turning %.0f°/s when the stick returns, stops turning %s later, turns %.1f° more after letting go, then holds %03.0f°" % [
			rate0, ("%.2f s" % settle) if settle >= 0.0 else "never", absf(after), _rows.back()["heading"]]


## The first time the error enters ±tol and stays there to the end (-1: never).
func _settle_time(errs: PackedFloat32Array, tol: float) -> float:
	var k := errs.size() - 1
	if absf(errs[k]) > tol:
		return -1.0
	while k > 0 and absf(errs[k - 1]) <= tol:
		k -= 1
	return k / 60.0


## The car's place on screen: how far it wanders from the middle, and how fast.
func _swing() -> String:
	var lo := Vector2(INF, INF)
	var hi := -lo
	var fastest := 0.0
	var cam_rate := 0.0
	for k in range(6, _rows.size()):
		var s := Vector2(_rows[k]["sx"], _rows[k]["sy"])
		lo = lo.min(s)
		hi = hi.max(s)
		if k > 6:
			var s0 := Vector2(_rows[k - 1]["sx"], _rows[k - 1]["sy"])
			fastest = maxf(fastest, s.distance_to(s0) * 60.0)
			cam_rate = maxf(cam_rate, absf(_wrap(_rows[k]["cam"] - _rows[k - 1]["cam"])) * 60.0)
	return "on screen x %4.0f-%4.0f y %4.0f-%4.0f px, fastest %4.0f px/s, camera turns up to %3.0f°/s" % [
			lo.x, hi.x, lo.y, hi.y, fastest, cam_rate]


## A 90° turn to the right: time until the car goes within 5° of east, how far past it
## swings, the size of the turn (mean of the ground covered ahead and sideways), and the
## speed there.
func _m_turn90() -> String:
	var hit := -1
	for k in _rows.size():
		if absf(_wrap(_rows[k]["go"] - 90.0)) < 5.0 and _rows[k]["speed"] > 0.3:
			hit = k
			break
	var over := 0.0
	var flips := 0
	if hit >= 0:
		for k in range(hit, _rows.size()):
			over = maxf(over, _wrap(_rows[k]["go"] - 90.0))
		for k in range(hit + 1, _rows.size()):
			var a := _wrap(_rows[k]["go"] - 90.0)
			var b := _wrap(_rows[k - 1]["go"] - 90.0)
			if absf(a) > 1.0 and absf(b) > 1.0 and signf(a) != signf(b):
				flips += 1
	var final_err := _wrap(_rows.back()["go"] - 90.0)
	if hit < 0:
		var turned := 0.0
		for k in range(1, _rows.size()):
			turned += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		if not legacy:
			_problems += 1
		return "never reaches east (turned %.0f°, final heading %03.0f°)  <-- PROBLEM" % [turned, _rows.back()["go"]]
	var r: Dictionary = _rows[hit]
	var ahead := -(float(r["z"]) - float(_rows[0]["z"]))
	var side := float(r["x"]) - float(_rows[0]["x"])
	var dist := 0.0
	for k in range(1, hit + 1):
		dist += Vector2(_rows[k]["x"] - _rows[k - 1]["x"], _rows[k]["z"] - _rows[k - 1]["z"]).length()
	var ok := over < 10.0 and absf(final_err) < 5.0
	if not ok and not legacy:
		_problems += 1
	return "east in %.2f s, %4.1f m ahead + %4.1f m right (turn size %4.1f m), %5.1f m driven, %3.0f km/h there | overshoot %2.0f°, flips %d, after 6 s %+3.0f° | %s%s" % [
			hit / 60.0, ahead, side, (absf(ahead) + absf(side)) * 0.5, dist, r["speed"] * 3.6, over, flips, final_err,
			_swing(), "" if ok or legacy else "  <-- PROBLEM"]


## Into a wall: the ground speed (real movement) kept 1 s after the first touch, the ground
## covered in the 2 s after it, how long the car sat pinned (touching, moving under 1 m/s),
## the unsticks, and the end: still moving, and (corner) how far out of the corner it got.
func _m_wall() -> String:
	var first := -1
	for k in _rows.size():
		if _rows[k]["contact"]:
			first = k
			break
	if first < 0:
		return "never touched the wall"
	var v_in: float = _rows[maxi(first - 1, 1)]["moved"]
	var k1 := mini(first + 60, _rows.size() - 1)
	var k2 := mini(first + 120, _rows.size() - 1)
	var along := Vector2(_rows[k2]["x"] - _rows[first]["x"], _rows[k2]["z"] - _rows[first]["z"]).length()
	var pinned := 0.0
	var longest := 0.0
	var run := 0.0
	for k in range(first, _rows.size()):
		if _rows[k]["contact"] and _rows[k]["moved"] < 1.0:
			pinned += 1.0 / 60.0
			run += 1.0 / 60.0
			longest = maxf(longest, run)
		else:
			run = 0.0
	var end: Dictionary = _rows.back()
	var end_speed := 0.0
	for k in range(_rows.size() - 30, _rows.size()):
		end_speed += float(_rows[k]["moved"]) / 30.0
	var unstuck := ""
	var unsticks := 0
	if _car.get("unsticks") != null:
		unsticks = int(_car.get("unsticks"))
		unstuck = ", unstuck %d×" % unsticks
	var out := ""
	if _test.has("out_at"):
		# The corner is at (0, -14).
		var d := Vector2(float(end["x"]), float(end["z"]) + 14.0).length()
		out = ", %.1f m from the corner at the end" % d
	var ok := end_speed >= 2.0 and longest <= float(_test.get("pin_max", 2.0))
	ok = ok and unsticks <= int(_test.get("unstick_max", 99))
	if _test.get("v2", false):
		# Step 6: a dead stop as contact_log.gd counts one (the car's velocity), and (head-on at
		# 50 km/h) the ground speed 1 s after the touch.
		var s_in: float = _rows[maxi(first - 1, 0)]["speed"]
		var low3 := s_in
		for k in range(first, mini(first + int(ContactLog.DEAD_TIME * 60.0) + 1, _rows.size())):
			low3 = minf(low3, float(_rows[k]["speed"]))
		var dead := s_in - low3 >= ContactLog.DEAD_LOST and low3 <= s_in * (1.0 - ContactLog.DEAD_SHARE)
		var again := float(_rows[k1]["moved"]) * 3.6
		var gate: bool = _test.get("gate", false)
		out += ", lowest in 0.3 s %3.0f km/h%s, %d kick(s), %d pivot(s)" % [low3 * 3.6, " DEAD STOP" if dead else "",
				int(_car.get("kicks")), int(_car.get("pivots"))]
		if _test.has("past_x"):
			ok = ok and float(end["x"]) > float(_test["past_x"])
			out += ", ends at x %.1f" % float(end["x"])
		if _test.has("again_kmh"):
			out += ", %s 15 km/h 1 s on" % ("over" if again >= float(_test["again_kmh"]) else "UNDER")
		if not gate:
			ok = true
		else:
			ok = ok and not dead and again >= float(_test.get("again_kmh", 0.0))
	if _test.has("end_heading"):
		ok = ok and absf(angle_difference(deg_to_rad(float(end["go"])), deg_to_rad(float(_test["end_heading"])))) < deg_to_rad(30.0)
	if _test.has("past"):
		# The driving-feel loop: got past the thing (north of `past`) by the end, and how soon.
		var past_t := -1.0
		for r in _rows:
			if float(r["z"]) < float(_test["past"]):
				past_t = r["t"]
				break
		ok = ok and past_t >= 0.0
		out += ", past it %s" % (("at %.1f s" % past_t) if past_t >= 0.0 else "NEVER")
	if not ok and not legacy:
		_problems += 1
	return "touch at %3.0f km/h, 1 s later %3.0f km/h (%3.0f%%), %4.1f m covered in 2 s, pinned %.1f s (longest %.1f s)%s, last 0.5 s %3.0f km/h heading %03.0f°%s %s%s" % [
			v_in * 3.6, float(_rows[k1]["moved"]) * 3.6, 100.0 * float(_rows[k1]["moved"]) / maxf(v_in, 0.01), along,
			pinned, longest, unstuck, end_speed * 3.6, end["go"], out, "(moving)" if end_speed >= 2.0 else "(STUCK)",
			"" if ok or legacy else "  <-- PROBLEM"]


## Camera loop, every test with the camera loop's camera: never faster than 64°/s, and (Fixed;
## Point before the follow-camera loop) never while the finger is down.
func _camera_rules() -> String:
	if legacy or camera_2a:
		return ""
	var fastest := 0.0
	var while_held := 0.0
	for k in range(1, _rows.size()):
		var rate := absf(_wrap(_rows[k]["cam"] - _rows[k - 1]["cam"])) * 60.0
		fastest = maxf(fastest, rate)
		# (Point turns with the car since the follow-camera loop; Fixed never turns.)
		if _ctl.camera_waits() and _rows[k]["finger"] and _rows[k - 1]["finger"]:
			while_held = maxf(while_held, rate)
	var out := ""
	if fastest > FollowCamera.MAX_TURN + 0.5:
		out += "  <-- PROBLEM: the camera turned at %.0f°/s (over %.0f)" % [fastest, FollowCamera.MAX_TURN]
		_problems += 1
	if while_held > 0.01:
		out += "  <-- PROBLEM: the camera turned at %.1f°/s while the finger was down" % while_held
		_problems += 1
	return out


## Camera loop, braking from ~90 km/h: how far the view's centre slides back (against the way the
## car went) after its furthest point, and how fast; how fast the car moves on screen after the
## brake; the speed zoom coming back in; the car's place on screen at the end.
func _m_brake() -> String:
	var k0 := int(float(_test["brake_at"]) * 60.0)
	var dir := Vector2(_rows[k0]["x"] - _rows[k0 - 30]["x"], _rows[k0]["z"] - _rows[k0 - 30]["z"]).normalized()
	var v0: float = _rows[k0]["speed"]
	var furthest := -INF
	var back := 0.0
	var back_rate := 0.0
	var stop_t := -1.0
	var px_rate := 0.0
	for k in range(k0, _rows.size()):
		var along := Vector2(_rows[k]["fx"], _rows[k]["fz"]).dot(dir)
		furthest = maxf(furthest, along)
		back = maxf(back, furthest - along)
		if k > k0:
			var prev := Vector2(_rows[k - 1]["fx"], _rows[k - 1]["fz"]).dot(dir)
			back_rate = maxf(back_rate, (prev - along) * 60.0)
			var s := Vector2(_rows[k]["sx"], _rows[k]["sy"])
			px_rate = maxf(px_rate, s.distance_to(Vector2(_rows[k - 1]["sx"], _rows[k - 1]["sy"])) * 60.0)
		if stop_t < 0.0 and float(_rows[k]["speed"]) < 0.5:
			stop_t = _rows[k]["t"] - float(_test["brake_at"])
	var end: Dictionary = _rows.back()
	# The road ahead at the brake: from the car up to the screen's top edge (the camera behind it),
	# on the ground (the 30° view shows ground depth at half scale), and in seconds at that speed.
	var ahead := float(_rows[k0]["sy"]) / (SCREEN.y / float(_rows[k0]["size"])) / sin(deg_to_rad(-PITCH))
	var ok := back <= 0.5
	if not ok and not camera_2a:
		_problems += 1
	return "%3.0f m of road ahead (%.1f s) | brake at %3.0f km/h, stopped %.2f s later | view slides back %4.1f m (at most %4.1f m/s) | car on screen at most %3.0f px/s | view %5.1f → %5.1f m | car at %4.0f,%4.0f px at the end%s" % [
			ahead, ahead / maxf(v0, 0.1), v0 * 3.6, stop_t, back, back_rate, px_rate, _rows[k0]["size"], end["size"], end["sx"], end["sy"],
			"" if ok or camera_2a else "  <-- PROBLEM"]


## Camera loop, a wobbling thumb in Classic at 50 km/h: from 2 s on, how much the camera's turn and
## the view's centre (across the screen, its straight-line drift taken out) wobble, in degrees and
## in pixels, and how much the car's heading wobbles.
func _m_wiggle() -> String:
	var k0 := 120
	var right := Vector2(cos(deg_to_rad(-float(_rows[k0]["cam"]))), sin(deg_to_rad(-float(_rows[k0]["cam"]))))
	right = Vector2(right.x, -right.y)
	var n := _rows.size() - k0
	# The straight-line fit of the centre's sideways place over time, taken out.
	var st := 0.0
	var sy := 0.0
	var stt := 0.0
	var sty := 0.0
	for k in range(k0, _rows.size()):
		var t: float = _rows[k]["t"]
		var y := Vector2(_rows[k]["fx"], _rows[k]["fz"]).dot(right)
		st += t
		sy += y
		stt += t * t
		sty += t * y
	var slope := (n * sty - st * sy) / maxf(n * stt - st * st, 0.0001)
	var icpt := (sy - slope * st) / n
	var lo := INF
	var hi := -INF
	var cam_lo := INF
	var cam_hi := -INF
	var car_lo := INF
	var car_hi := -INF
	for k in range(k0, _rows.size()):
		var t: float = _rows[k]["t"]
		var y := Vector2(_rows[k]["fx"], _rows[k]["fz"]).dot(right) - (icpt + slope * t)
		lo = minf(lo, y)
		hi = maxf(hi, y)
		var c := _wrap(float(_rows[k]["cam"]) - float(_rows[k0]["cam"]))
		cam_lo = minf(cam_lo, c)
		cam_hi = maxf(cam_hi, c)
		var h := _wrap(float(_rows[k]["heading"]) - float(_rows[k0]["heading"]))
		car_lo = minf(car_lo, h)
		car_hi = maxf(car_hi, h)
	var px_per_m := SCREEN.y / float(_rows.back()["size"])
	# A turn of the view by d degrees moves the screen's side edge by half its width × d.
	var edge := deg_to_rad(cam_hi - cam_lo) * 0.5 * SCREEN.x
	return "car's heading wobbles %4.1f° | camera turn wobbles %4.2f° (the screen's side edge %3.0f px) | view centre wobbles %4.2f m (%3.0f px) across" % [
			car_hi - car_lo, cam_hi - cam_lo, edge, hi - lo, (hi - lo) * px_per_m]


func _print_log() -> void:
	for r in _rows:
		var k := int(round(float(r["t"]) * 60.0))
		if k % _every != 0:
			continue
		print("    t %4.1f  heading %03.0f  going %03.0f  %3.0f km/h  camera %03.0f  screen %4.0f,%4.0f%s" % [
				r["t"], r["heading"], r["go"], r["speed"] * 3.6, fposmod(r["cam"], 360.0), r["sx"], r["sy"],
				"  wall" if r["contact"] else ""])


func _summary() -> void:
	var car_len := 4.0 * SCREEN.y / (LEGACY_SIZE if legacy else FollowCamera.DEFAULT_SIZE)
	print("car on screen at the default view (%.0f m): %.0f px long side-on, %.0f px nose-up, of 1170 lines" % [
			LEGACY_SIZE if legacy else FollowCamera.DEFAULT_SIZE, car_len, car_len * (0.5 + 1.5 / 4.0 * 0.87)])
	if legacy:
		print("check_steering: legacy run (numbers only)")
	else:
		print("check_steering: %s" % ("OK" if _problems == 0 else "%d PROBLEM(S)" % _problems))
	if _problems > 0 and not legacy:
		quit(1)
