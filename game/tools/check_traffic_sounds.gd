extends SceneTree
## Traffic you can hear (scripts/traffic_sounds.gd), headless, with made-up drivers and a tram:
##   1. nearest(): up to n indices under the reach, nearest first;
##   2. the Doppler factor: higher coming closer, lower going away, held at its limit;
##   3. who is heard: the 3 nearest moving cars, the nearest bus, the tram; never a parked, ghost,
##      inactive or out-of-reach one; a car at full speed reaches full level, a waiting one hums
##      (its idle share), a standing tram is silent;
##   4. changes: a nearer car takes the spare voice while the one pushed out fades and frees; a
##      vehicle that jumps (reused, put back on its line) or parks frees its voice at once; an
##      approaching car is pitched up;
##   5. the cost of one choice among 300 drivers and of one frame's step.
## Prints "traffic_sounds: OK (...)" or "traffic_sounds: PROBLEM" and the problems.
##   godot --headless --path game --script res://tools/check_traffic_sounds.gd

const TrafficSounds := preload("res://scripts/traffic_sounds.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Trams := preload("res://scripts/trams.gd")

var problems: Array[String] = []
var cars: Array = []
var tram_list: Array = []


func _initialize() -> void:
	_nearest()
	_doppler()
	var info := _choice()
	var cost := _cost()
	for p in problems:
		print("  PROBLEM: " + p)
	if problems.is_empty():
		print("traffic_sounds: OK (%s; %s)" % [info, cost])
	else:
		print("traffic_sounds: PROBLEM")
	quit(0 if problems.is_empty() else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _nearest() -> void:
	var d := PackedFloat32Array([5.0, 1.0, 9.0, 3.0, 50.0])
	_expect(TrafficSounds.nearest(d, 2, 8.0) == PackedInt32Array([1, 3]), "nearest 2 under 8 is not [1, 3]")
	_expect(TrafficSounds.nearest(d, 9, 8.0) == PackedInt32Array([1, 3, 0]), "nearest under 8 does not leave out 9 and 50")
	_expect(TrafficSounds.nearest(d, 0, 100.0).is_empty(), "nearest 0 is not empty")
	_expect(TrafficSounds.nearest(PackedFloat32Array(), 3, 100.0).is_empty(), "nearest of none is not empty")


func _doppler() -> void:
	_expect(TrafficSounds.doppler(-10.0) > 1.0, "coming closer is not pitched up")
	_expect(TrafficSounds.doppler(10.0) < 1.0, "going away is not pitched down")
	_expect(is_equal_approx(TrafficSounds.doppler(0.0), 1.0), "standing still is not pitch 1")
	_expect(is_equal_approx(TrafficSounds.doppler(-1000.0), 1.0 + TrafficSounds.DOPPLER_MAX), "the shift is not held at its limit")


func _driver(x: float, kind := 0, v := 14.0) -> Traffic.Driver:
	var d := Traffic.Driver.new()
	d.active = true
	d.kind = kind
	d.pos = Vector3(x, 0.0, 0.0)
	d.v = v
	cars.append(d)
	return d


func _make() -> TrafficSounds:
	var ts := TrafficSounds.new()
	ts.ear = func() -> Vector3: return Vector3.ZERO
	ts.drivers = func() -> Array: return cars
	ts.trams = func() -> Array: return tram_list
	ts.setup()
	return ts


func _heard(ts: TrafficSounds, src: Object) -> TrafficSounds.Voice:
	for v in ts.voices:
		if v.src == src:
			return v
	return null


func _run(ts: TrafficSounds, seconds: float, dt := 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds:
		ts.step(dt)
		t += dt


func _choice() -> String:
	cars.clear()
	tram_list.clear()
	var c5 := _driver(5.0)
	var c10 := _driver(10.0)
	var c15 := _driver(15.0)
	var c20 := _driver(20.0)
	var parked := _driver(2.0)
	parked.parked = true
	var ghost := _driver(3.0)
	ghost.ghost = true
	var off := _driver(1.0)
	off.active = false
	var far := _driver(-45.0)
	var bus := _driver(-20.0, TrafficSounds.BUS_KIND, 11.0)
	var bus_far := _driver(60.0, TrafficSounds.BUS_KIND, 11.0)
	var tr := Trams.Tram.new()
	tr.pos = Vector3(0.0, 0.0, 30.0)
	tr.rear = Vector2(0.0, 60.0)
	tr.v = 0.0
	tram_list.append(tr)
	var ts := _make()
	_expect(ts.voices.size() == 8, "%d voices, not 3+1 cars, 1+1 bus, 1+1 tram" % ts.voices.size())
	ts.tick()
	for c in [c5, c10, c15]:
		_expect(_heard(ts, c) != null and _heard(ts, c).kind == "car", "a car among the 3 nearest is not heard as a car")
	for c in [c20, parked, ghost, off, far, bus_far]:
		_expect(_heard(ts, c) == null, "a car beyond the 3 nearest, parked, ghost, inactive or far is heard")
	_expect(_heard(ts, bus) != null and _heard(ts, bus).kind == "bus", "the bus is not heard as a bus")
	_expect(_heard(ts, tr) != null, "the tram 30 m off is not heard")
	_run(ts, 1.5)
	_expect(ts.live == 5, "%d voices sound, not 5" % ts.live)
	_expect(is_equal_approx(_heard(ts, c5).level, 1.0), "a car at full speed is not at full level")
	_expect(_heard(ts, tr).level == 0.0, "a standing tram is not silent")
	c10.v = 0.0
	_run(ts, 1.5)
	_expect(is_equal_approx(_heard(ts, c10).level, float(TrafficSounds.KINDS["car"]["idle"])), "a waiting car does not hum at its idle share")
	_expect(is_equal_approx(_heard(ts, c10).pitch, TrafficSounds.PITCH_LOW), "a waiting car is not at the low pitch")

	# A nearer car comes: the spare voice takes it, the one pushed out fades and frees.
	var c4 := _driver(-4.0)
	ts.tick()
	_expect(_heard(ts, c4) != null, "a new nearer car does not take the spare voice")
	_expect(_heard(ts, c15) != null and _heard(ts, c15).leaving, "the car pushed out is not leaving")
	_run(ts, 1.0)
	_expect(_heard(ts, c15) == null, "the car pushed out still holds its voice after its fade")

	# A jump (the driver reused elsewhere) and a park free at once.
	c5.pos.x += 30.0
	c10.parked = true
	ts.step(1.0 / 60.0)
	_expect(_heard(ts, c5) == null, "a driver that jumped 30 m keeps its voice")
	_expect(_heard(ts, c10) == null, "a parked driver keeps its voice")

	# An approaching car at full speed is pitched up.
	c4.pos.x = -30.0
	ts.step(1.0 / 60.0)
	ts.tick()
	var come := _heard(ts, c4)
	for i in 60:
		c4.pos.x += 14.0 / 60.0
		ts.step(1.0 / 60.0)
	_expect(come.pitch > TrafficSounds.PITCH_HIGH, "an approaching car is not pitched up (%.3f)" % come.pitch)
	var info := "%d voices, approach pitch %.3f" % [ts.voices.size(), come.pitch]
	ts.free()
	# main.gd's build with no traffic and no trams: a node that hears nothing.
	var world := Node3D.new()
	var lone: Node3D = TrafficSounds.build(world, null, null, func() -> Vector3: return Vector3.ZERO)
	lone.tick()
	lone.step(0.1)
	_expect(lone.get_parent() == world and lone.live == 0, "build with no traffic is not a silent child of the world")
	world.free()
	return info


func _cost() -> String:
	cars.clear()
	tram_list.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 300:
		_driver(rng.randf_range(-400.0, 400.0), 3 if i % 20 == 0 else 0).pos.z = rng.randf_range(-400.0, 400.0)
	for i in 12:
		var tr := Trams.Tram.new()
		tr.pos = Vector3(rng.randf_range(-400.0, 400.0), 0.0, rng.randf_range(-400.0, 400.0))
		tr.rear = Vector2(tr.pos.x, tr.pos.z + 30.0)
		tr.v = 8.0
		tram_list.append(tr)
	var ts := _make()
	var t0 := Time.get_ticks_usec()
	for i in 50:
		ts.tick()
	var tick_us := float(Time.get_ticks_usec() - t0) / 50.0
	t0 = Time.get_ticks_usec()
	for i in 200:
		ts.step(1.0 / 60.0)
	var step_us := float(Time.get_ticks_usec() - t0) / 200.0
	ts.free()
	_expect(tick_us < 2000.0, "a choice among 300 drivers takes %.0f µs" % tick_us)
	return "choice %.0f µs at 5 Hz, step %.1f µs a frame" % [tick_us, step_us]
