extends SceneTree
## Promo Mode (promo_mode.gd, F 2026-11-20: framing tools for the trailer and the Reels) and its clock
## nudge (game_time.gd `nudge`, time_of_day.gd `shift_clock`). No map, no game window. Checks that:
## - -15 / +15 move the game clock a quarter hour either way, past midnight too (the weekday with
##   it), and the light follows the new hour;
## - off, Promo Mode builds nothing and leaves the camera to the game (`frame` false, the car free);
## - CAR: the camera rides on the car, its yaw the car's heading plus the offset, at the tilt and
##   view chosen, looking at the focus from the game's distance;
## - FREE: the car waits (`holds_car`), a finger's drag moves the focus over the ground by what the
##   finger covered, GLIDE eases in and goes on, the clock's speeds reach the clock and turning
##   Promo Mode off gives the game its own speed and camera back;
## - a saved shot comes back exactly with NEXT, and COPY's flags render the same frame (--cam is
##   the focus, follow_camera.gd `parse_free` reads it; --pitch is the game's minus the tilt);
## - VERTICAL takes the 9:16 guide and keeps the view's metres per pixel as the screen turns,
##   HORIZONTAL and PROMO OFF turn it back;
## - --promo=free,grid,9:16 sets those switches.
##   godot --headless --path game --script res://tools/check_promo.gd

const PromoMode := preload("res://scripts/promo_mode.gd")
const GameTime := preload("res://scripts/game_time.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Pacer := preload("res://scripts/pacer.gd")
const Settings := preload("res://scripts/settings.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const Fakes := preload("res://tools/fakes.gd")

var _fails: Array[String] = []


## What Promo Mode reads of main.gd.
class Game extends Node:
	var cam: Camera3D
	var cam_focus := Vector3.ZERO
	var cam_yaw := 45.0
	var cam_yaw_target := 45.0
	var camera_pitch := -30.0
	var top_down := false
	var flying := false
	var car: Node3D
	var heli: Node3D
	var map: Node3D
	var tod: Node
	var weather: Node
	var hud: CanvasLayer
	var settings := Settings.new()
	var sv: SubViewport
	var cuts := 0
	var moved_to := Vector2.INF

	func _cut_camera() -> void:
		cuts += 1

	func _teleport_from_map(p: Vector2) -> void:
		moved_to = p


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_clock()
	_promo()
	if _fails.is_empty():
		print("check_promo: OK")
		quit(0)
	else:
		for f in _fails:
			print("check_promo: FAIL %s" % f)
		quit(1)


func _expect(fact: bool, what: String) -> void:
	if not fact:
		_fails.append(what)


func _clock_tod() -> TimeOfDay:
	var t := TimeOfDay.new()
	root.add_child(t)
	var sun := DirectionalLight3D.new()
	root.add_child(sun)
	t.setup(Environment.new(), sun, ShaderMaterial.new(), -50.0)
	t.start_clock(20261120)
	return t


func _clock() -> void:
	var t := _clock_tod()
	var h0 := float(t.local_clock()["hour"])
	_expect(GameTime.nudge(t, 15.0), "nudge refused a clock")
	var h1 := float(t.local_clock()["hour"])
	_expect(absf(h1 - h0 - 0.25) < 0.01, "+15 moved the clock from %.3f to %.3f" % [h0, h1])
	GameTime.nudge(t, -15.0)
	_expect(absf(float(t.local_clock()["hour"]) - h0) < 0.01, "-15 did not come back to %.3f" % h0)
	# Past midnight, both ways: Friday 23:50 + 15 is Saturday 00:05, and back.
	t.set_hour(23.0 + 50.0 / 60.0, true)
	var wd := int(t.local_clock()["weekday"])
	GameTime.nudge(t, 15.0)
	var c := t.local_clock()
	_expect(absf(float(c["hour"]) - (5.0 / 60.0)) < 0.01 and int(c["weekday"]) == wd % 7 + 1,
			"23:50 + 15 min is not 00:05 the next day: %s (was weekday %d)" % [c, wd])
	GameTime.nudge(t, -15.0)
	c = t.local_clock()
	_expect(absf(float(c["hour"]) - (23.0 + 50.0 / 60.0)) < 0.01 and int(c["weekday"]) == wd, "00:05 - 15 min is not 23:50 back: %s" % [c])
	# The light follows at once: noon is the day's, 23:00 the night's.
	t.set_hour(12.0, true)
	GameTime.nudge(t, 11.0 * 60.0)
	_expect(t.look_mode() == TimeOfDay.NIGHT, "+11 h from noon is not night's light (%d)" % t.look_mode())
	_expect(not GameTime.nudge(null, 15.0), "nudge without a clock said yes")


func _game() -> Game:
	var g := Game.new()
	g.cam = Camera3D.new()
	g.cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	g.cam.size = 80.0
	g.cam.near = 1.0
	g.add_child(g.cam)
	g.car = Node3D.new()
	g.heli = Node3D.new()
	g.add_child(g.car)
	g.add_child(g.heli)
	g.map = Fakes.FlatMap.new()
	g.add_child(g.map)
	g.tod = _clock_tod()
	g.settings.persistent = false
	root.add_child(g)
	return g


func _promo() -> void:
	var g := _game()
	var p := PromoMode.new()
	p.game = g
	p.log_on = false
	g.add_child(p)
	_expect(not p.frame(0.016) and not p.holds_car() and p.get_child_count() == 0, "Promo Mode off still placed the camera or built its panel")

	# CAR: on the car, its heading plus the offset.
	g.car.global_position = Vector3(100.0, 0.0, -50.0)
	g.car.rotation.y = deg_to_rad(30.0)
	p.set_on(true)
	_expect(p.on and p.get_child_count() > 0, "set_on did not build the panel")
	p.yaw_offset = 90.0
	p.pitch = 45.0
	p.size = 120.0
	p._snap = true
	_expect(p.frame(0.016), "frame did not place the camera")
	_expect(p.focus.distance_to(g.car.global_position) < 0.01, "CAR: the focus %s is not the car %s" % [p.focus, g.car.global_position])
	_expect(absf(wrapf(p.yaw - 120.0, -180.0, 180.0)) < 0.01, "CAR: yaw %.1f is not heading 30 + offset 90" % p.yaw)
	_expect(is_equal_approx(g.cam.size, 120.0) and is_equal_approx(g.camera_pitch, -45.0), "the camera's view or tilt is not the panel's")
	var back := g.cam.global_position - p.focus
	_expect(back.normalized().dot(g.cam.global_transform.basis.z) > 0.9999 and back.length() >= 499.0,
			"the camera does not look at the focus from the game's distance")
	_expect(g.cam.far > back.length() + 60.0, "the far plane %.0f stops short of the ground" % g.cam.far)
	_expect(not p.holds_car(), "CAR held the car")

	# FREE: the car waits; a drag moves the focus over the ground by the finger's way.
	p._set_cam(PromoMode.Cam.FREE)
	_expect(p.holds_car(), "FREE did not park the car")
	p.yaw = 0.0
	p.pitch = 30.0
	p.size = 100.0
	var f0 := p.focus
	var h := maxf(p.get_viewport().get_visible_rect().size.y, 1.0)
	p._pan(Vector2(0.0, h * 0.5))  # half the screen down: the camera goes forward (north at yaw 0)
	var moved := p.focus - f0
	_expect(absf(moved.x) < 0.01 and absf(moved.z + 100.0) < 0.5,
			"a drag of half the screen at 100 m and 30 degrees moved the focus %s, not 100 m north" % moved)
	p.move = Vector3(PromoMode.GLIDE_STEP * 4.0, 0.0, 0.0)
	var f1 := p.focus
	for i in 120:
		p.frame(1.0 / 60.0)
	var glided := f1.z - p.focus.z
	_expect(glided > 0.5 and glided < PromoMode.GLIDE_STEP * 4.0 * p.size * 2.0, "GLIDE did not ease forward (%.2f m in 2 s)" % glided)
	p._stop_moves()

	# The clock's speed reaches the clock, and off gives the game's back.
	p.speed_i = 0
	p._apply_speed()
	_expect(g.tod.speed == 0.0, "PAUSE did not stop the clock")
	p.speed_i = 4
	p._apply_speed()
	_expect(g.tod.speed == PromoMode.SPEEDS[4], "600x did not reach the clock")

	# A saved shot comes back with NEXT; COPY's flags are the frame.
	p.focus = Vector3(-845.0, 0.0, 415.0)
	p.yaw = 12.0
	p.pitch = 32.0
	p.size = 60.0
	p._save_shot()
	_expect(g.settings.promo_shots.size() == 1, "SAVE kept %d shots" % g.settings.promo_shots.size())
	var flags := p.shot_flags()
	p.focus = Vector3.ZERO
	p.yaw = 200.0
	p.size = 300.0
	p.shot_i = -1
	p._next_shot()
	_expect(p.focus.distance_to(Vector3(-845.0, 0.0, 415.0)) < 0.1 and absf(p.yaw - 12.0) < 0.1 and absf(p.pitch - 32.0) < 0.1 \
			and absf(p.size - 60.0) < 0.1, "NEXT did not bring the shot back: %s %.1f %.1f %.1f" % [p.focus, p.yaw, p.pitch, p.size])
	var cam := ""
	for part in flags.split(" "):
		if part.begins_with("--cam="):
			cam = part.trim_prefix("--cam=")
	var xyz := FollowCamera.parse_free(cam)
	_expect(xyz.size() == 3 and absf(float(xyz[0]) + 845.0) < 0.1 and absf(float(xyz[2]) - 415.0) < 0.1,
			"COPY's --cam does not read back as the focus: %s" % flags)
	_expect("--pitch=-32.0" in flags and "--yaw=12.0" in flags and "--size=60.0" in flags and "--game-clock" in flags \
			and "--clock=" in flags and "--date=2026" in flags, "COPY's flags are not the frame: %s" % flags)
	p._drop_shot()
	_expect(g.settings.promo_shots.is_empty(), "DELETE kept the shot")

	# The flag's switches.
	p.use_flag("free,grid,9:16,ghost")
	_expect(p.cam_mode == PromoMode.Cam.FREE and p.grid and str(PromoMode.GUIDES[p.guide][0]) == "9:16" \
			and p.hud_show == PromoMode.HudShow.GHOST, "--promo=free,grid,9:16,ghost did not set them")

	# VERTICAL: the guide goes 9:16, the view keeps its metres per pixel when the screen's height
	# changes, HORIZONTAL brings the full screen back.
	_expect(PromoMode.can_turn(), "a desktop build may not turn")
	p.guide = 0
	p.set_portrait(true)
	_expect(p.portrait and str(PromoMode.GUIDES[p.guide][0]) == "9:16" and (p._buttons["rotate"] as Button).text == "HORIZONTAL",
			"VERTICAL did not take the 9:16 guide or its button")
	p.size = 80.0
	p._last_h = p.get_viewport().get_visible_rect().size.y * 0.5
	p._place_panel()
	_expect(is_equal_approx(p.size, 160.0), "a screen twice as tall did not double the view's height (%.1f m)" % p.size)
	p.set_portrait(false)
	_expect(not p.portrait and p.guide == 0, "HORIZONTAL did not bring the full screen back")
	p.set_portrait(true)

	# Off: the game's camera, speed and car back (and the screen landscape).
	var cuts := g.cuts
	p.set_on(false)
	_expect(not p.frame(0.016) and not p.holds_car() and g.cuts == cuts + 1, "off did not give the camera back")
	_expect(is_equal_approx(g.tod.speed, Pacer.num("time", "speed")), "off left the clock at %.0fx" % g.tod.speed)
	_expect(is_equal_approx(g.camera_pitch, -g.settings.pitch), "off left the tilt at %.1f" % g.camera_pitch)
	_expect(not p.portrait, "off left the screen vertical")
