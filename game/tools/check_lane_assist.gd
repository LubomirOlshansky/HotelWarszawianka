extends SceneTree
## Beta values (2026-11-04): the lane assist "Asysta pasa" (scripts/lane_assist.gd, car.gd
## `_lane_pull`; GAMEPLAY_PLAN 1.5 item 1 and test D2), on the real car script on flat ground,
## Classic controls, steering in the middle, the gas held at ~50 km/h:
##   1. a straight lane, the car 6° off it: with the assist it is back on the lane (heading within
##      1°, under 1 m across) within 3 s and stays under 2 m; without it, it keeps the 6° and
##      drifts on (the "before");
##   2. a gentle curve (300 m radius): with the assist the car follows it with no steering, within
##      4 m of the curve over 10 s; without, it runs off the outside;
##   3. a deliberate turn (the strip at 0.6 for 1 s) turns exactly as much with the assist as
##      without (it lets go past NEAR_CENTRE);
##   4. under 15 km/h, braking, or 25° off the lane (turning into a street): no pull;
##   5. on the committed map (map/centrum.json): along a lane the direction found is the lane's;
##      turned against it, or 10 m off it, nothing.
## Prints "check_lane_assist: OK (...)" or the problems (exit 1).
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_lane_assist.gd

const Car := preload("res://scripts/car.gd")
const LaneAssist := preload("res://scripts/lane_assist.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Fakes := preload("res://tools/fakes.gd")

const DT := 1.0 / 60.0
const SPEED := 50.0 / 3.6

var problems: Array[String] = []
var summary: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await _straight()
	await _curve()
	await _deliberate()
	_no_pull()
	_on_map()
	if problems.is_empty():
		print("check_lane_assist: OK (%s)" % ", ".join(summary))
		quit(0)
	else:
		for p in problems:
			print("check_lane_assist: %s" % p)
		print("check_lane_assist: FAIL (%d problems)" % problems.size())
		quit(1)


## A Classic car at the origin heading `deg` (compass: 0 north = -z, 90 east = +x) at SPEED.
func _car(deg: float, assist: bool) -> CharacterBody3D:
	var c: CharacterBody3D = Car.new()
	root.add_child(c)
	c.rotation.y = -deg_to_rad(deg)
	var fwd := Vector3(-sin(c.rotation.y), 0.0, -cos(c.rotation.y))
	c.vel = fwd * SPEED
	c.forward_speed = SPEED
	c.lane_assist = assist
	c.steer = 0.0
	c.target_dir = Vector3.ZERO
	return c


## Holds about SPEED with the gas (the car's top × gas).
func _gas(c: CharacterBody3D) -> void:
	c.throttle = clampf(SPEED / c.top_speed(), 0.0, 1.0)
	c.braking = false


func _heading_err(c: CharacterBody3D, lane: Vector3) -> float:
	var fwd := Vector3(-sin(c.rotation.y), 0.0, -cos(c.rotation.y))
	return rad_to_deg(fwd.signed_angle_to(lane, Vector3.UP))


## 1. The straight lane north (-z), the car 6° east of it.
func _straight() -> void:
	var out := {}
	for assist in [true, false]:
		var c := _car(6.0, assist)
		var lane := Vector3(0, 0, -1)
		var settled := -1.0
		for f in 360:
			# The aim, as lane_assist.gd finds it on a lane: the lane's middle ahead.
			var at := Vector2(c.global_position.x, c.global_position.z)
			var aim := Vector2(0.0, at.y - LaneAssist.ahead(c.vel.length()))
			var to := LaneAssist.pursuit(at, aim, Vector2(0, -1))
			c.lane_dir = Vector3(to.x, 0.0, to.y)
			_gas(c)
			await physics_frame
			if settled < 0.0 and absf(_heading_err(c, lane)) < 1.0 and absf(c.global_position.x) < 1.0:
				settled = f * DT
		out[assist] = {"settled": settled, "across": absf(c.global_position.x), "err": absf(_heading_err(c, lane))}
		c.queue_free()
	var on: Dictionary = out[true]
	var off: Dictionary = out[false]
	_expect(on["settled"] >= 0.0 and on["settled"] <= 3.0, "straight: the assist took %.1f s to line up (want ≤ 3 s)" % on["settled"])
	_expect(on["across"] < 2.0, "straight: %.1f m across after 6 s with the assist (want < 2 m)" % on["across"])
	_expect(off["err"] > 4.0 and off["across"] > 6.0, "straight without the assist: %.1f° and %.1f m (the before: it should drift)" % [off["err"], off["across"]])
	summary.append("straight 6°: on the lane in %.1f s, %.1f m across (off: %.1f m)" % [on["settled"], on["across"], off["across"]])


## 2. A 300 m curve to the left: centre 300 m west of the start, the car heading north on it.
func _curve() -> void:
	var r := 300.0
	var centre := Vector2(-r, 0.0)
	var out := {}
	for assist in [true, false]:
		var c := _car(0.0, assist)
		var worst := 0.0
		for f in 600:
			var p := Vector2(c.global_position.x, c.global_position.z)
			var radial := (p - centre).normalized()
			# Anticlockwise seen from above with z down the screen: heading north at (0, 0) the
			# tangent turns west.
			var tangent := Vector2(-radial.y, radial.x)
			if tangent.dot(Vector2(-sin(c.rotation.y), -cos(c.rotation.y))) < 0.0:
				tangent = -tangent
			# The aim on the curve, an arc of ahead() m on from the car's nearest point.
			var turn := LaneAssist.ahead(c.vel.length()) / r * signf(radial.cross(tangent))
			var aim := centre + radial.rotated(turn) * r
			var to := LaneAssist.pursuit(p, aim, tangent)
			c.lane_dir = Vector3(to.x, 0.0, to.y)
			_gas(c)
			await physics_frame
			worst = maxf(worst, absf(Vector2(c.global_position.x, c.global_position.z).distance_to(centre) - r))
		out[assist] = worst
		c.queue_free()
	_expect(out[true] < 4.0, "curve: %.1f m off the 300 m curve with the assist (want < 4 m)" % out[true])
	_expect(out[false] > 20.0, "curve without the assist: only %.1f m off (the before: it should run wide)" % out[false])
	summary.append("300 m curve: %.1f m off (off: %.0f m)" % [out[true], out[false]])


## 3. The strip at 0.6 for 1 s on a straight lane north: the same turn either way.
func _deliberate() -> void:
	var turned := {}
	for assist in [true, false]:
		var c := _car(0.0, assist)
		var start := c.rotation.y
		for f in 60:
			c.lane_dir = Vector3(0, 0, -1)
			c.steer = 0.6
			_gas(c)
			await physics_frame
		turned[assist] = rad_to_deg(c.rotation.y - start)
		c.queue_free()
	_expect(absf(turned[true] - turned[false]) < 0.5, "a deliberate turn: %.1f° with the assist, %.1f° without" % [turned[true], turned[false]])
	summary.append("deliberate turn %.0f° both ways" % turned[false])


## 4. The pull's rules.
func _no_pull() -> void:
	var e := deg_to_rad(6.0)
	_expect(LaneAssist.yaw_pull(e, 0.0, 15.0 / 3.6) == 0.0, "a pull under 15 km/h")
	_expect(LaneAssist.yaw_pull(deg_to_rad(25.0), 0.0, SPEED) == 0.0, "a pull 25° off the lane")
	_expect(LaneAssist.yaw_pull(e, 0.2, SPEED) == 0.0, "a pull with the strip at 0.2")
	_expect(LaneAssist.yaw_pull(e, 0.0, SPEED) > 0.0 and LaneAssist.yaw_pull(-e, 0.0, SPEED) < 0.0, "the pull's sign")
	_expect(absf(LaneAssist.yaw_pull(e, 0.0, SPEED) - LaneAssist.GAIN * e) < 0.0001, "the full pull at 50 km/h")
	_expect(LaneAssist.yaw_pull(e, 0.075, SPEED) < LaneAssist.GAIN * e * 0.6, "the pull fades with the strip")
	var c := _car(0.0, true)
	c.lane_dir = Vector3(0, 0, -1).rotated(Vector3.UP, e)
	c.braking = true
	_expect(c._lane_pull(Vector3(0, 0, -1), SPEED) == 0.0, "a pull while braking")
	c.braking = false
	c.target_dir = Vector3(0, 0, -1)
	_expect(c._lane_pull(Vector3(0, 0, -1), SPEED) == 0.0, "a pull in Point (target_dir set)")
	c.target_dir = Vector3.ZERO
	c.lane_assist = false
	_expect(c._lane_pull(Vector3(0, 0, -1), SPEED) == 0.0, "a pull with the setting off")
	c.free()
	summary.append("no pull slow, braking, 25° off, strip ≥ 0.15, in Point, off")


## 5. The lane's direction on the real map.
func _on_map() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		problems.append("no map/centrum.json")
		return
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	var along := 0
	var ok := 0
	var against := 0
	var off := 0
	for e in range(0, graph.e_len.size(), 37):
		if graph.e_len[e] < 30.0 or graph.e_tn[e] >= 0:
			continue
		var s := graph.e_len[e] * 0.5
		var p := graph.point_at(e, s, graph.lane_offset(e, 0))
		var d := graph.direction(e, s)
		along += 1
		var h := LaneAssist.lane_heading(graph, p, d)
		# Another edge can lie closer (a parallel lane of the same road): any lane within ALIGN counts.
		ok += int(h != Vector2.ZERO and absf(h.angle_to(d)) < LaneAssist.ALIGN)
		var back := LaneAssist.lane_heading(graph, p, -d)
		against += int(back == Vector2.ZERO or absf(back.angle_to(-d)) < LaneAssist.ALIGN)
		var side := Vector2(-d.y, d.x)
		var far := p + side * 10.0
		if graph.snap(far, LaneAssist.REACH + 0.5).is_empty():
			off += int(LaneAssist.lane_heading(graph, far, d) == Vector2.ZERO)
		else:
			off += 1
	_expect(along > 50, "only %d lanes sampled" % along)
	_expect(ok >= along * 0.97, "the lane's direction found on %d of %d lanes" % [ok, along])
	_expect(against == along, "turned against the lane, %d of %d gave its own direction back" % [along - against, along])
	_expect(off == along, "10 m off the road, %d of %d still found a lane" % [along - off, along])
	map.queue_free()
	summary.append("map: %d of %d lanes" % [ok, along])
