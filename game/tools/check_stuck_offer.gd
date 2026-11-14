extends SceneTree
## The stuck offer (G14's "later", 2026-11-03): the car counts the time the player spends trying to
## drive in one spot (car.gd `stalled`), and main.gd puts POMOC DROGOWA on the context button once it
## reaches Car.STALL_TIME. This drives the real car script on a flat test ground and checks:
##   pen      boxed in by four walls with the gas held: the offer is due by STALL_TIME + 1 s
##   pen_mid  the same with the city objects plan's step 6 preset `mid` (collide_rules.gd): a car
##            that really is boxed in still gets the offer (the v2 answer must not free it)
##   open     driving on with the gas held: never due (the spot moves with the car)
##   idle     in the pen, 5 s gas, 5 s off the controls, 4 s gas: not due during the pause (time off
##            the controls does not count), due after it (nor does it reset)
##   parked   in the pen, parked by the game (title, Fotka, a pull-over) with the brake on: never due
##   backoff  a corridor 18 m long, gas into one end then back off for another run, over and
##            over (PT-24: backing off reset the count every try): due by 2 x STALL_TIME
##   reset    reset_stall() and reset_motion() (the tows) start it again from nothing
##   pill     the real HUD's context button (PT-23): POMOC DROGOWA takes it from the ride app's
##            PODWÓZKA (up whenever a ride could be taken) and from KASETA, never from a rescue
##            call; PODWÓZKA can't take it back while the offer is up, and can once it goes
## Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_stuck_offer.gd

const Car := preload("res://scripts/car.gd")
const Hud := preload("res://scripts/hud.gd")

## [name, seconds, walls ("pen", "corridor" or ""), inputs(t) -> [throttle, braking, parked]]
var _tests: Array = []
var _i := -1
var _t := 0.0
var _world: Node3D
var _car: CharacterBody3D
var _problems := 0
var _due_at := -1.0
var _due_in_pause := false
## The backoff run: how far apart the car's positions got (m), so the run shows it really backed off.
var _span := 0.0
var _min_z := 0.0
var _max_z := 0.0


func _initialize() -> void:
	_tests = [
		["pen", 10.0, "pen", func(_t: float) -> Array: return [1.0, false, false]],
		["pen_mid", 10.0, "pen", func(_t: float) -> Array: return [1.0, false, false]],
		["open", 14.0, "", func(_t: float) -> Array: return [0.6, false, false]],
		["idle", 14.5, "pen", func(t: float) -> Array: return [1.0 if t < 5.0 or t >= 10.0 else 0.0, false, false]],
		["parked", 10.0, "pen", func(_t: float) -> Array: return [0.0, true, true]],
		["backoff", 16.0, "corridor", func(t: float) -> Array: return [1.0, false, false] if fmod(t, 4.0) < 2.5 else [0.0, true, false]],
		["reset", 9.5, "pen", func(_t: float) -> Array: return [1.0, false, false]],
	]
	print("check_stuck_offer: %d runs, STALL_TIME %.0f s, STALL_RADIUS %.0f m" % [_tests.size(), Car.STALL_TIME, Car.STALL_RADIUS])


func _physics_process(delta: float) -> bool:
	if _i < 0 or _t >= float(_tests[_i][1]):
		if _i >= 0:
			_finish()
		_i += 1
		if _i >= _tests.size():
			_pill_ranks()
			print("check_stuck_offer: %s" % ("OK" if _problems == 0 else "%d problem(s)" % _problems))
			quit(1 if _problems > 0 else 0)
			return true
		_start()
	var inp: Array = (_tests[_i][3] as Callable).call(_t)
	_car.throttle = inp[0]
	_car.braking = inp[1]
	_car.parked = inp[2]
	_car.steer = 0.0
	_car.target_dir = Vector3.ZERO
	if _car.stalled >= Car.STALL_TIME and _due_at < 0.0:
		_due_at = _t
	if _tests[_i][0] == "idle" and _t >= 5.0 and _t < 10.0 and _car.stalled >= Car.STALL_TIME:
		_due_in_pause = true
	_min_z = minf(_min_z, _car.global_position.z)
	_max_z = maxf(_max_z, _car.global_position.z)
	_span = _max_z - _min_z
	_t += delta
	return false


func _start() -> void:
	_t = 0.0
	_due_at = -1.0
	_due_in_pause = false
	_min_z = 0.0
	_max_z = 0.0
	_span = 0.0
	_world = Node3D.new()
	root.add_child(_world)
	var walls: Array = []
	if _tests[_i][2] == "pen":
		# A pen 3.0 m wide and 5.2 m long round a 1.8 x 4.0 m car: it can turn a little, never leave.
		walls = [[Vector3(0, 0.6, -2.9), Vector3(4.0, 1.2, 0.6)], [Vector3(0, 0.6, 2.9), Vector3(4.0, 1.2, 0.6)],
				[Vector3(-1.8, 0.6, 0), Vector3(0.6, 1.2, 6.4)], [Vector3(1.8, 0.6, 0), Vector3(0.6, 1.2, 6.4)]]
	elif _tests[_i][2] == "corridor":
		# A corridor 3.0 m wide with its ends 9 m either side of the start: room to back off 5-8 m.
		walls = [[Vector3(0, 0.6, -9.3), Vector3(4.0, 1.2, 0.6)], [Vector3(0, 0.6, 9.3), Vector3(4.0, 1.2, 0.6)],
				[Vector3(-1.8, 0.6, 0), Vector3(0.6, 1.2, 19.2)], [Vector3(1.8, 0.6, 0), Vector3(0.6, 1.2, 19.2)]]
	for w: Array in walls:
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = w[1]
			shape.shape = box
			body.add_child(shape)
			body.position = w[0]
			_world.add_child(body)
	_car = Car.new()
	if String(_tests[_i][0]).ends_with("_mid"):
		_car.collide = &"mid"
	_world.add_child(_car)
	_car.global_position = Vector3.ZERO


func _finish() -> void:
	var name: String = _tests[_i][0]
	var ok := true
	var note := ""
	match name:
		"pen", "pen_mid":
			ok = _due_at >= 0.0 and _due_at <= Car.STALL_TIME + 1.0
			note = "due at %.1f s" % _due_at if _due_at >= 0.0 else "never due"
		"open":
			ok = _due_at < 0.0
			note = "drove %.0f m, stalled %.1f s at the end" % [_car.global_position.length(), _car.stalled]
		"idle":
			ok = not _due_in_pause and _due_at >= 10.0
			note = "due at %.1f s%s" % [_due_at, ", DUE IN THE PAUSE" if _due_in_pause else ""]
		"backoff":
			ok = _due_at >= 0.0 and _due_at <= 2.0 * Car.STALL_TIME
			note = ("due at %.1f s" % _due_at if _due_at >= 0.0 else "never due") + ", %.1f m apart at most" % _span
		"parked":
			ok = _due_at < 0.0 and _car.stalled == 0.0
			note = "stalled %.1f s" % _car.stalled
		"reset":
			var before: float = _car.stalled
			_car.reset_stall()
			var after_stall: float = _car.stalled
			_car.stalled = 5.0
			_car.reset_motion()
			ok = before >= Car.STALL_TIME and after_stall == 0.0 and _car.stalled == 0.0
			note = "%.1f s, after reset_stall %.1f, after reset_motion %.1f" % [before, after_stall, _car.stalled]
	if not ok:
		_problems += 1
	print("  %-7s %s  %s" % [name, "ok  " if ok else "FAIL", note + " (ends at %.1f, %.1f)" % [_car.global_position.x, _car.global_position.z]])
	_world.queue_free()
	_world = null
	_car = null


## PT-23 (2026-11-06): the stuck offer never came up while the ride app held the context button.
func _pill_ranks() -> void:
	var hud: CanvasLayer = Hud.new()
	root.add_child(hud)
	var fails: Array[String] = []
	hud.show_pill("PODWÓZKA", "ride app", "ride")
	if not hud.pill_free_for("unstuck"):
		fails.append("POMOC DROGOWA can't take the button from PODWÓZKA")
	hud.show_pill("POMOC DROGOWA", "tow truck", "unstuck")
	if hud.pill_free_for("ride") or hud.pill_free_for("ride_start") or hud.pill_free_for("tape"):
		fails.append("the ride app or KASETA can take the button back from POMOC DROGOWA")
	if not hud.pill_free_for("call"):
		fails.append("a rescue call can't take the button from POMOC DROGOWA")
	hud.hide_pill()
	if not hud.pill_free_for("ride"):
		fails.append("PODWÓZKA can't come back once the offer is gone")
	hud.show_pill("WEZWANIE", "rescue call")
	if hud.pill_free_for("unstuck"):
		fails.append("POMOC DROGOWA takes the button from a rescue call")
	hud.show_pill("PODWÓZKA", "ride app", "ride")
	if not hud.pill_free_for("tape"):
		fails.append("KASETA can't take the button from PODWÓZKA")
	hud.queue_free()
	if not fails.is_empty():
		_problems += 1
	print("  %-7s %s  %s" % ["pill", "ok  " if fails.is_empty() else "FAIL", "; ".join(fails) if not fails.is_empty() else "ranks hold"])
