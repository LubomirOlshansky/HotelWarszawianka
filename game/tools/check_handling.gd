extends SceneTree
## G4 (F, 2026-11-01: "very drifty and sensitive, this is a city, not a racer"): the real car script
## on a flat test ground in both handling profiles (car.gd PROFILES). Cruise must hold the road:
## a lane change at 50 km/h and a 90 degree corner at 25 km/h with full lock held keep the
## sideways speed (`slip`) under CRUISE_SLIP, and braking hard from 90 km/h with the wheel
## straight does not swing the tail. Sport keeps the old feel (it may slide more than Cruise, and
## the profile numbers differ), the profile switch round-trips, and the gas pulls away more softly
## in Cruise.
##
## The city objects plan, step 6 (docs/design/drivable-city-build.md item 2): the car against a
## stopped traffic car (a kinematic body, as traffic.gd's) with the default preset (v1) and `mid`
## (collide_rules.gd), in Cruise: a rear-end, a side swipe and a T-bone at 40 km/h keep on the
## first contact frame the share collide_rules.gd `car_keep` names of what went into it (v1: car.gd's
## CAR_KEEP, 0.5, whatever the hit; mid: 0.75 / about 0.85 / 0.4; less the first frame's push back; a tram's
## side, a body with the meta `heavy`, answers as a wall with mid: nothing kept going into it), and a queue at a red (rolling at 10 km/h off
## the gas into the car ahead, and creeping on a light gas under the "trying" line) ends in the
## same place with both presets, behind it, never ghosting through. Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_handling.gd

const Car := preload("res://scripts/car.gd")
const CollideRules := preload("res://scripts/collide_rules.gd")
const KMH := 1.0 / 3.6
## The most sideways speed (m/s) Cruise may show in the tests below.
const CRUISE_SLIP := 1.2

var _problems: Array[String] = []
var _world: Node3D
var _car: Car
var _frames := 0
var _stage := 0
var _profile := 0
var _max_slip := 0.0
var _case := 0
var _results := {}
## Step 6: the traffic cases' run (phase 1), the one now, and what each ended with.
var _phase := 0
var _tcase := -1
var _tprev := Vector3.ZERO
var _tfirst := {}
var _tend := {}

## Step 6: name, the other car's place and yaw (deg, 0 facing north like ours), our speed (km/h)
## and heading (compass deg), the gas (share of top speed; 0 off), how long (s), and the hit's kind
## ("" for the queue: no share judged, only where it ends).
const TRAFFIC := [
	{"name": "rear-end", "at": Vector3(0, 0.85, -9.0), "yaw": 0.0, "kmh": 40.0, "heading": 0.0, "gas": 0.37, "dur": 1.5},
	{"name": "side swipe", "at": Vector3(2.3, 0.85, -4.0), "yaw": 0.0, "kmh": 40.0, "heading": 6.0, "gas": 0.37, "dur": 1.5},
	{"name": "T-bone", "at": Vector3(0, 0.85, -8.0), "yaw": 90.0, "kmh": 40.0, "heading": 0.0, "gas": 0.37, "dur": 1.5},
	{"name": "tram side", "at": Vector3(0, 0.85, -8.0), "yaw": 90.0, "kmh": 40.0, "heading": 0.0, "gas": 0.37, "dur": 1.5, "heavy": true},
	{"name": "queue roll", "at": Vector3(0, 0.85, -4.6), "yaw": 0.0, "kmh": 10.0, "heading": 0.0, "gas": 0.0, "dur": 3.0, "queue": true},
	{"name": "queue creep", "at": Vector3(0, 0.85, -5.0), "yaw": 0.0, "kmh": 4.0, "heading": 0.0, "gas": 0.05, "dur": 3.0, "queue": true},
]

## name, speed (km/h), steering held (-1..1) for the first `hold` s, duration s, brake from 2 s
const CASES := [
	{"name": "lane change 50 km/h", "kmh": 50.0, "steer": 1.0, "hold": 0.6, "dur": 2.5, "brake": false},
	{"name": "90 degree corner 25 km/h", "kmh": 25.0, "steer": 1.0, "hold": 1.2, "dur": 3.0, "brake": false},
	{"name": "full lock 50 km/h", "kmh": 50.0, "steer": 1.0, "hold": 2.0, "dur": 3.0, "brake": false},
	{"name": "hard brake 90 km/h", "kmh": 90.0, "steer": 0.0, "hold": 0.0, "dur": 2.5, "brake": true},
]


func _initialize() -> void:
	# The profile numbers: Cruise holds the road harder and turns less sharply than Sport.
	var c: Dictionary = Car.PROFILES[Car.Handling.CRUISE]
	var s: Dictionary = Car.PROFILES[Car.Handling.SPORT]
	if not (c["grip"] > s["grip"] and c["drift_grip"] > s["drift_grip"] and c["turn_pull"] < s["turn_pull"] \
			and c["turn_cap"] < s["turn_cap"] and c["steer_time"] > s["steer_time"] and c["onset"] < s["onset"]):
		_problems.append("Cruise is not softer than Sport in every number")
	var probe := Car.new()
	probe.set_handling(Car.Handling.SPORT)
	if probe.grip != s["grip"] or probe.handling != Car.Handling.SPORT:
		_problems.append("set_handling(SPORT) did not set the numbers")
	probe.set_handling(Car.Handling.CRUISE)
	if probe.grip != c["grip"] or probe.handling != Car.Handling.CRUISE:
		_problems.append("set_handling(CRUISE) did not set the numbers")
	probe.set_handling(99)
	if probe.handling != Car.Handling.CRUISE:
		_problems.append("an unknown profile did not fall back to Cruise")
	probe.free()
	var fresh := Car.new()
	if fresh.handling != Car.Handling.CRUISE:
		_problems.append("a new car is not in Cruise")
	fresh.free()
	_begin()


func _begin() -> void:
	if _world != null:
		_world.queue_free()
	_world = Node3D.new()
	root.add_child(_world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000, 1, 2000)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_car = Car.new()
	_car.set_handling(_profile)
	_world.add_child(_car)
	var cs: Dictionary = CASES[_case]
	var v: float = float(cs["kmh"]) * KMH
	_car.vel = Vector3(0, 0, -v)
	_car.forward_speed = v
	_frames = 0
	_max_slip = 0.0


func _physics_process(dt: float) -> bool:
	if _phase == 1:
		return _traffic_step(dt)
	var cs: Dictionary = CASES[_case]
	var t := _frames * dt
	_frames += 1
	_car.throttle = clampf(float(cs["kmh"]) * KMH / _car.max_speed, 0.0, 1.0)
	_car.steer = float(cs["steer"]) if t < float(cs["hold"]) else 0.0
	_car.braking = bool(cs["brake"]) and t > 0.3
	if t > 0.3:
		_max_slip = maxf(_max_slip, _car.slip)
	if t < float(cs["dur"]):
		return false
	_results["%d/%s" % [_profile, cs["name"]]] = _max_slip
	print("  %s %-26s max slip %.2f m/s" % ["Cruise" if _profile == 0 else "Sport ", cs["name"], _max_slip])
	_case += 1
	if _case >= CASES.size():
		_case = 0
		_profile += 1
		if _profile > 1:
			_phase = 1
			return not _next_traffic()
	_begin()
	return false


## Step 6: the next traffic case (every case with v1, then with mid); false when they are done.
func _next_traffic() -> bool:
	_tcase += 1
	if _tcase >= TRAFFIC.size() * 2:
		_judge_traffic()
		_finish()
		return false
	var tc: Dictionary = TRAFFIC[_tcase % TRAFFIC.size()]
	if _world != null:
		_world.free()
	_world = Node3D.new()
	root.add_child(_world)
	var other := AnimatableBody3D.new()
	other.sync_to_physics = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.5, 4.2)
	shape.shape = box
	other.add_child(shape)
	other.position = tc["at"]
	if tc.get("heavy", false):
		other.set_meta(&"heavy", true)  # trams.gd's bodies; traffic.gd's buses with a v2 preset
	other.rotation.y = -deg_to_rad(float(tc["yaw"]))
	_world.add_child(other)
	_car = Car.new()
	_car.collide = CollideRules.V1 if _tcase < TRAFFIC.size() else CollideRules.MID
	_world.add_child(_car)
	var h := deg_to_rad(float(tc["heading"]))
	_car.rotation.y = -h
	var v := float(tc["kmh"]) * KMH
	_car.vel = Vector3(sin(h), 0.0, -cos(h)) * v
	_car.forward_speed = v
	_tprev = _car.vel
	_frames = 0
	return true


func _traffic_step(dt: float) -> bool:
	var tc: Dictionary = TRAFFIC[_tcase % TRAFFIC.size()]
	var key := "%s/%s" % [_car.collide, tc["name"]]
	_frames += 1
	if _car.get_slide_collision_count() > 0 and not _tfirst.has(key):
		# The first contact frame: the share kept of what went in (the frame before, less the coast
		# or plus the pull of the car's own step: the gas holds the speed).
		var into := Vector3(_tprev.x, 0.0, _tprev.z)
		var hit := _car.get_slide_collision(0)
		var n := hit.get_normal()
		n.y = 0.0
		n = n.normalized()
		var out := Vector3(_car.vel.x, 0.0, _car.vel.z)
		# car.gd: out = slid x scrape + (into - slid) x keep, and slid has no part along n.
		var gone := -into.dot(n)
		var kept := -out.dot(n)
		var deg := rad_to_deg(asin(clampf(-into.normalized().dot(n), 0.0, 1.0)))
		var cross := CollideRules.cross_angle(into, -(hit.get_collider() as Node3D).global_transform.basis.z)
		# (The first frame of a touch also pushes back off it: car.gd WALL_PUSH of what went in, at most 1.2 m/s.)
		var push := minf(gone * Car.WALL_PUSH, 1.2) if gone > 1.0 else 0.0
		var want := (gone * CollideRules.car_keep(_car.collide, deg, cross) - push) / maxf(gone, 0.001)
		var keep := CollideRules.car_keep(_car.collide, deg, cross)
		if tc.get("heavy", false) and _car.collide != CollideRules.V1:
			# A tram or a bus answers as a wall (v2): nothing kept going into it, the bounce off it.
			keep = 0.0
			want = -float(CollideRules.answer(_car.collide, _car.handling, into.length(), deg)["bounce"]) * into.length() / maxf(gone, 0.001)
		_tfirst[key] = {"share": kept / maxf(gone, 0.001), "want": want, "keep": keep, "deg": deg, "cross": cross}
	_tprev = _car.vel
	_car.throttle = float(tc["gas"])
	_car.steer = 0.0
	_car.braking = false
	if _frames * dt < float(tc["dur"]):
		return false
	_tend[key] = {"z": _car.global_position.z, "ghost": not _car._ghosted.is_empty(), "speed": _car.vel.length()}
	return not _next_traffic()


func _judge_traffic() -> void:
	for tc: Dictionary in TRAFFIC:
		var name: String = tc["name"]
		var line := "  traffic %-11s" % name
		for p: StringName in [CollideRules.V1, CollideRules.MID]:
			var key := "%s/%s" % [p, name]
			var first: Dictionary = _tfirst.get(key, {})
			var end: Dictionary = _tend.get(key, {})
			if tc.has("queue"):
				line += "  %s: ends at z %.2f%s" % [p, float(end.get("z", 0.0)), ", GHOSTED" if end.get("ghost", false) else ""]
				var behind := float(tc["at"].z) + 2.1 + 2.0 - 0.05
				if end.get("ghost", false) or float(end.get("z", -99.0)) < behind:
					_problems.append("the queue (%s) with %s ghosted or ended past the car ahead (z %.2f)" % [name, p, float(end.get("z", 0.0))])
				continue
			if first.is_empty():
				_problems.append("%s with %s never touched the other car" % [name, p])
				continue
			line += "  %s: kept %.2f of what went in (car_keep %.2f less the push: %.2f; %.0f deg to its side, %.0f deg to its axis)" % [p, first["share"],
					first["keep"], first["want"], first["deg"], first["cross"]]
			if absf(float(first["share"]) - float(first["want"])) > 0.06:
				_problems.append("%s with %s kept %.2f, the table says %.2f" % [name, p, first["share"], first["want"]])
		if tc.has("queue"):
			var a := float((_tend.get("v1/" + name, {}) as Dictionary).get("z", 0.0))
			var b := float((_tend.get("mid/" + name, {}) as Dictionary).get("z", 0.0))
			if absf(a - b) > 0.1:
				_problems.append("the queue (%s) moved with mid: z %.2f, v1 %.2f" % [name, b, a])
		print(line)


func _finish() -> bool:
	# Freed now, not queued: nothing is left alive when the script quits (verify.sh fails on leak warnings).
	_world.free()
	for cs in CASES:
		var cr: float = _results["0/%s" % cs["name"]]
		var sp: float = _results["1/%s" % cs["name"]]
		if cr > CRUISE_SLIP:
			_problems.append("Cruise %s slides %.2f m/s (limit %.1f)" % [cs["name"], cr, CRUISE_SLIP])
		if cr > sp + 0.01:
			_problems.append("Cruise %s slides more than Sport (%.2f vs %.2f)" % [cs["name"], cr, sp])
	# The sensitivity slider: its left end turns less than the middle, which turns less than its right end.
	var gains: Array[float] = []
	for lv in [0.0, 0.5, 1.0]:
		var sc := Car.new()
		sc.set_sensitivity(lv)
		gains.append(sc.max_turn(10.0) )
		sc.free()
	print("  max turn at 36 km/h by sensitivity 0 / 0.5 / 1: %.2f / %.2f / %.2f rad/s" % [gains[0], gains[1], gains[2]])
	if not (gains[0] < gains[1] and gains[1] < gains[2]):
		_problems.append("the sensitivity slider does not order the steering (%s)" % [gains])
	var mid := Car.new()
	if not is_equal_approx(mid.steer_gain, 1.0):
		_problems.append("a new car's steering gain is not 1.0")
	mid.set_sensitivity(0.5)
	if not is_equal_approx(mid.steer_gain, 1.0):
		_problems.append("sensitivity 0.5 is not the profile as is")
	mid.free()
	# The gas: a quarter push for 1 s reaches a lower speed in Cruise than in Sport.
	var cruise_v := _pull_away(Car.Handling.CRUISE)
	var sport_v := _pull_away(Car.Handling.SPORT)
	print("  quarter gas for 1 s: Cruise %.1f m/s, Sport %.1f m/s" % [cruise_v, sport_v])
	if cruise_v >= sport_v:
		_problems.append("Cruise does not pull away more softly (%.1f vs %.1f m/s)" % [cruise_v, sport_v])
	if _problems.is_empty():
		print("check_handling: OK")
		quit(0)
	else:
		for p in _problems:
			printerr("check_handling: " + p)
		print("check_handling: %d PROBLEM(S)" % _problems.size())
		quit(1)
	return true


func _pull_away(h: int) -> float:
	var car := Car.new()
	car.set_handling(h)
	car.throttle = 0.25
	var v := 0.0
	for i in 60:
		v = v + car.accel * (car.onset + (1.0 - car.onset) * 0.25) * (1.0 / 60.0) * (1.0 - 0.6 * clampf(v / car.max_speed, 0.0, 1.0))
	car.free()
	return v
