extends SceneTree
## The Grounded handling (car.gd Handling.GROUNDED, F 2026-11-04: "driving feels too arcade"): the
## real car script on a flat test ground, each manoeuvre driven in all three profiles, and a table of
## the numbers that make the difference (the A/B for the PR and the phone test). Grounded must:
## stop from 90 km/h in GR_STOP m (Cruise and Sport stop in about 11, a 3 g brake), coast from
## 50 km/h for longer than the others, answer a step of the wheel later (the yaw's lag), turn at
## 90 km/h with no more than LAT_MAX m/s² sideways (about 1.2 g; Cruise pulls ~1.8 g), slide wider
## braking hard in a bend than turning alone (the friction circle), dip the nose under braking and
## roll out of a turn (the body spring), and pull away at full gas exactly like Cruise (the drag and
## the races measure that pull). Cruise and Sport must keep their numbers (they are not touched).
## Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_grounded.gd

const Car := preload("res://scripts/car.gd")
const KMH := 1.0 / 3.6
## Grounded's stopping distance from 90 km/h (m): ~1.1 g with the brakes' build.
const GR_STOP := Vector2(26.0, 40.0)
## Cruise's and Sport's (m): the 3 g arcade brake, kept as it was.
const OLD_STOP := Vector2(8.0, 14.0)
## The most sideways pull Grounded may turn with at 90 km/h, full lock (m/s²).
const LAT_MAX := 13.5
## The yaw's 63 % answer to a full step of the wheel at 50 km/h (s): Grounded slower than Cruise by at least this.
const LAG_MORE := 0.05

## name, start km/h, duration s; per frame: gas (share of top), steer, brake by time.
const CASES := ["stop90", "coast50", "step50", "lock90", "trail60", "turn60", "pull"]
const NAMES := ["Cruise", "Sport", "Grounded"]

var _problems: Array[String] = []
var _world: Node3D
var _car: Car
var _frames := 0
var _profile := 0
var _case := 0
var _start := Vector3.ZERO
var _r := {}
## Per-run measures.
var _stop_at := -1.0
var _yaw_final := 0.0
var _yaw_seen: Array[float] = []
var _max_slip := 0.0
var _max_lat := 0.0
var _min_pitch := 0.0
var _roll_seen := 0.0


func _initialize() -> void:
	_begin()


func _begin() -> void:
	if _world != null:
		_world.free()
	_world = Node3D.new()
	root.add_child(_world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4000, 1, 4000)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_car = Car.new()
	_car.set_handling(_profile)
	_world.add_child(_car)
	var v: float = _kmh() * KMH
	_car.vel = Vector3(0, 0, -v)
	_car.forward_speed = v
	_start = Vector3.ZERO
	_frames = 0
	_stop_at = -1.0
	_yaw_seen.clear()
	_max_slip = 0.0
	_max_lat = 0.0
	_min_pitch = 0.0
	_roll_seen = 0.0


func _kmh() -> float:
	match CASES[_case]:
		"stop90", "lock90":
			return 90.0
		"coast50", "step50":
			return 50.0
		"trail60", "turn60":
			return 60.0
	return 0.0


func _dur() -> float:
	match CASES[_case]:
		"coast50":
			return 3.0
		"pull":
			return 2.0
		"step50":
			return 1.5
	return 2.5


func _physics_process(dt: float) -> bool:
	var t := _frames * dt
	_frames += 1
	var hold := clampf(_kmh() * KMH / _car.max_speed, 0.0, 1.0)
	var c: String = CASES[_case]
	_car.throttle = hold
	_car.steer = 0.0
	_car.braking = false
	match c:
		"stop90":
			_car.throttle = 0.0
			_car.braking = true
		"coast50":
			_car.throttle = 0.0
		"step50", "lock90", "turn60":
			_car.steer = 1.0
		"trail60":
			_car.steer = 1.0
			_car.throttle = 0.0
			_car.braking = t > 0.4 and t < 1.6
		"pull":
			_car.throttle = 1.0
	if c == "stop90" and _stop_at < 0.0 and _car.forward_speed < 0.3:
		_stop_at = _car.global_position.distance_to(_start)
	if c == "step50":
		_yaw_seen.append(absf(_car.yaw_rate))
	if c == "lock90" and t > 0.6:
		_max_lat = maxf(_max_lat, absf(_car.yaw_rate * _car.forward_speed))
	if c == "trail60" or c == "turn60":
		if t > 0.4 and t < 1.6:
			_max_slip = maxf(_max_slip, _car.slip)
	if c == "stop90" and t < 1.0:
		_min_pitch = minf(_min_pitch, _car.get_child(1).rotation.x if _car.get_child_count() > 1 else 0.0)
	if c == "lock90" and t > 0.6:
		var body: Node3D = _car.get_child(1)
		_roll_seen = body.rotation.z
	if t < _dur():
		return false
	_record(c)
	_case += 1
	if _case >= CASES.size():
		_case = 0
		_profile += 1
		if _profile > 2:
			return _finish()
	_begin()
	return false


func _record(c: String) -> void:
	var key := "%d/%s" % [_profile, c]
	match c:
		"stop90":
			_r[key] = _stop_at
			_r["%d/pitch" % _profile] = _min_pitch
		"coast50":
			_r[key] = _car.forward_speed / KMH
		"step50":
			# The time to 63 % of the yaw rate it settles on.
			var final := _yaw_seen[_yaw_seen.size() - 1]
			var at := 0.0
			for i in _yaw_seen.size():
				if _yaw_seen[i] >= 0.63 * final:
					at = i / 60.0
					break
			_r[key] = at
		"lock90":
			_r[key] = _max_lat
			_r["%d/roll" % _profile] = _roll_seen
		"trail60", "turn60":
			_r[key] = _max_slip
		"pull":
			_r[key] = _car.forward_speed / KMH


func _finish() -> bool:
	_world.free()
	print("  %-42s %9s %9s %9s" % ["", NAMES[0], NAMES[1], NAMES[2]])
	var rows := [["stop from 90 km/h (m)", "stop90"], ["speed after 3 s coasting from 50 (km/h)", "coast50"],
			["yaw answer to a step at 50 (s, 63 %)", "step50"], ["sideways pull, full lock at 90 (m/s²)", "lock90"],
			["slide turning at 60 (m/s)", "turn60"], ["slide braking in the bend at 60 (m/s)", "trail60"],
			["speed after 2 s full gas (km/h)", "pull"], ["nose pitch under braking (rad)", "pitch"],
			["body roll, full lock left at 90 (rad)", "roll"]]
	for row in rows:
		print("  %-42s %9.2f %9.2f %9.2f" % [row[0], _r["0/" + row[1]], _r["1/" + row[1]], _r["2/" + row[1]]])
	var g := func(k: String) -> float: return float(_r["2/" + k])
	var cr := func(k: String) -> float: return float(_r["0/" + k])
	var sp := func(k: String) -> float: return float(_r["1/" + k])
	if g.call("stop90") < GR_STOP.x or g.call("stop90") > GR_STOP.y:
		_problems.append("Grounded stops from 90 km/h in %.1f m (want %.0f-%.0f)" % [g.call("stop90"), GR_STOP.x, GR_STOP.y])
	for k in [0, 1]:
		var d: float = _r["%d/stop90" % k]
		if d < OLD_STOP.x or d > OLD_STOP.y:
			_problems.append("%s stops from 90 km/h in %.1f m (it was ~11 m: not to be touched)" % [NAMES[k], d])
	if g.call("coast50") <= cr.call("coast50") + 5.0:
		_problems.append("Grounded does not coast further than Cruise (%.1f vs %.1f km/h after 3 s)" % [g.call("coast50"), cr.call("coast50")])
	if g.call("step50") < cr.call("step50") + LAG_MORE:
		_problems.append("Grounded's yaw answers no later than Cruise's (%.2f vs %.2f s)" % [g.call("step50"), cr.call("step50")])
	if g.call("step50") > 0.45:
		_problems.append("Grounded's yaw answers too late for a phone (%.2f s)" % g.call("step50"))
	if g.call("lock90") > LAT_MAX:
		_problems.append("Grounded turns at 90 km/h with %.1f m/s² (most %.1f)" % [g.call("lock90"), LAT_MAX])
	if g.call("trail60") <= g.call("turn60") + 0.3:
		_problems.append("Grounded does not slide wider braking in a bend (%.2f vs %.2f m/s)" % [g.call("trail60"), g.call("turn60")])
	if g.call("pitch") > -0.01:
		_problems.append("Grounded's nose does not dip under braking (%.3f rad)" % g.call("pitch"))
	if g.call("roll") > -0.01:
		_problems.append("Grounded does not roll out of a left turn (%.3f rad)" % g.call("roll"))
	if absf(g.call("pull") - cr.call("pull")) > 0.5:
		_problems.append("Grounded's full-gas pull differs from Cruise's (%.1f vs %.1f km/h)" % [g.call("pull"), cr.call("pull")])
	if absf(sp.call("pull") - cr.call("pull")) > 0.5:
		_problems.append("Sport's full-gas pull changed (%.1f vs %.1f km/h)" % [sp.call("pull"), cr.call("pull")])
	# The flag's words.
	if Car.parse_handling("grounded") != Car.Handling.GROUNDED or Car.parse_handling("sport") != Car.Handling.SPORT \
			or Car.parse_handling("0") != Car.Handling.CRUISE or Car.parse_handling("nope") != -1:
		_problems.append("parse_handling does not read the --handling= words")
	var probe := Car.new()
	probe.set_handling(Car.Handling.GROUNDED)
	var on := probe.weighty
	probe.set_handling(Car.Handling.CRUISE)
	if not on or probe.weighty:
		_problems.append("set_handling does not switch the weight on and off")
	probe.free()
	if _problems.is_empty():
		print("check_grounded: OK")
		quit(0)
	else:
		for p in _problems:
			printerr("check_grounded: " + p)
		print("check_grounded: %d PROBLEM(S)" % _problems.size())
		quit(1)
	return true
