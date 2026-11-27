extends SceneTree
## The time owner (game_time.gd, F 2026-11-19: "a centralized system that understands time and which
## activity is on at what time"; "show the night activities by day too, the time changes when the
## player picks the quest"). No map, no game. Checks that:
## - hours wrap past midnight; each activity's hours are pacing.json's; what is open at 15:00 and at
##   23:00;
## - the night friends may call by day with `by_day` on, and only in their hours with it off;
## - the jump: the look that fits the hour, the clock set, one toast; a run that keeps hours jumps
##   into them only when it starts outside them (activity.gd `start`), and its call says so;
## - the map clock's words.
## - the game clock (F 2026-11-19, time_of_day.gd `start_clock`): it starts on a Friday at 11:00 (DAY_START_HOUR) in
##   the Day look's light and runs at time.speed (30x); the sun follows the date (a June day
##   longer than a November one); the golden hour round sunset lasts time.golden times longer
##   and the clock's sunrise and sunset are the real ones; a look picked moves the clock forward
##   to its hour; Night is dark, the sunset gold; the watch's hour from a point.
##   godot --headless --path game --script res://tools/check_game_time.gd

const GameTime := preload("res://scripts/game_time.gd")
const Pacer := preload("res://scripts/pacer.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Activity := preload("res://scripts/activity.gd")
const Fakes := preload("res://tools/fakes.gd")
const UiKit := preload("res://scripts/ui_kit.gd")
const ClockDial := preload("res://scripts/clock_dial.gd")
const FullMap := preload("res://scripts/full_map.gd")
const Shots := preload("res://scripts/camera_shots.gd")


## A clock with the methods the jump uses.
class FakeTod extends Node:
	var mode := 0
	var fixed_start := -1.0
	var hour := 14.0
	func set_mode(m: int, _instant := false) -> void:
		mode = m
	func set_hour(h: float, _instant := false) -> void:
		mode = TimeOfDay.parse(TimeOfDay.look_at(h))
		fixed_start = h
	func local_clock() -> Dictionary:
		return {"hour": fixed_start if fixed_start >= 0.0 else hour, "weekday": 5}


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run.call_deferred()


## The game clock on a real TimeOfDay (its own environment, sun and post material).
func _game_clock() -> void:
	var t := TimeOfDay.new()
	root.add_child(t)
	var env := Environment.new()
	var sun := DirectionalLight3D.new()
	root.add_child(sun)
	t.setup(env, sun, ShaderMaterial.new(), -50.0)
	t.start_clock(20261120)
	var c := t.local_clock()
	_expect(t.game_clock and t.mode == TimeOfDay.LIVE and int(c["weekday"]) == 5 and absf(float(c["hour"]) - t.look_hour(TimeOfDay.DAY)) < 0.01,
			"the game clock did not start on Friday in the day: %s" % [c])
	_expect(t.look_mode() == TimeOfDay.DAY and t.sun.shadow_enabled, "the game clock's start is not the day's light")
	# F 2026-11-20: the opening's morning ends on the clock's own 11:00 start, no jump after the car appears.
	_expect(absf(float(c["hour"]) - TimeOfDay.DAY_START_HOUR) < 0.01, "a new game's clock does not start at DAY_START_HOUR: %s" % [c])
	_expect(t.wake(Shots.OPEN_TIME), "the opening's morning did not start on the game clock")
	t._frame(Shots.OPEN_TIME + 0.1)
	var after := float(t.local_clock()["hour"])
	_expect(not t.waking() and absf(after - TimeOfDay.DAY_START_HOUR) < (Shots.OPEN_TIME + 1.0) * t.speed / 3600.0,
			"the clock is at %.2f after the morning, not about %.0f:00 (a jump when the car appears)" % [after, TimeOfDay.DAY_START_HOUR])
	_expect(is_equal_approx(t.speed, Pacer.num("time", "speed")) and t.speed >= 10.0, "the clock does not run fast (time.speed)")
	var h0 := float(t.local_clock()["hour"])
	t._frame(10.0)
	var ran := (float(t.local_clock()["hour"]) - h0) * 3600.0
	_expect(absf(ran - 10.0 * t.speed) < 1.0, "10 real s moved the clock %.0f game s, not %.0f" % [ran, 10.0 * t.speed])
	# F 2026-11-26 (story-structure, "The clock"): inside a questline the clock goes at
	# time.hold_speed (real time), and the speed comes back as it was when the questline ends.
	t.held = true
	h0 = float(t.local_clock()["hour"])
	t._frame(10.0)
	ran = (float(t.local_clock()["hour"]) - h0) * 3600.0
	_expect(absf(ran - 10.0 * Pacer.num("time", "hold_speed")) < 0.5, "held, 10 real s moved the clock %.0f game s, not %.0f" % [ran, 10.0 * Pacer.num("time", "hold_speed")])
	_expect(is_equal_approx(t.speed, Pacer.num("time", "speed")), "holding the clock wrote its speed (Promo mode's speeds would be lost)")
	t.held = false
	h0 = float(t.local_clock()["hour"])
	t._frame(10.0)
	ran = (float(t.local_clock()["hour"]) - h0) * 3600.0
	_expect(absf(ran - 10.0 * t.speed) < 1.0, "after the hold, 10 real s moved the clock %.0f game s, not %.0f" % [ran, 10.0 * t.speed])
	# What holds it: a questline under way, or the Tajny klient chapter; nothing else.
	var idle := {"busy": func() -> bool: return false}
	var running := {"busy": func() -> bool: return true}
	_expect(not GameTime.held_for([idle, {}]), "no questline runs, yet the clock is held")
	_expect(GameTime.held_for([idle, running]), "a questline runs, yet the clock is not held")
	_expect(GameTime.held_for([], true), "the Tajny klient chapter runs, yet the clock is not held")
	# The seasons: Warsaw's real day lengths, about 8.5 h on 20 November and 16.8 h on 21 June.
	var nov := t.sun_times()
	var jun := TimeOfDay.sun_times_on(TimeOfDay.warsaw_to_utc("00:00", 20270621))
	_expect(absf((nov.y - nov.x) - 8.5) < 0.4 and absf((jun.y - jun.x) - 16.8) < 0.4, "day lengths: November %s, June %s" % [nov, jun])
	_expect(nov.y > 15.0 and nov.y < 16.0 and jun.y > 20.5 and jun.y < 21.5, "sunsets: November %.2f, June %.2f" % [nov.y, jun.y])
	# The long golden hour: the clock's sunset is the real one, and the band round it is longer.
	var band := t._band()
	_expect(is_zero_approx(TimeOfDay.solar_shift(nov.y, nov.x, nov.y, band)) and is_zero_approx(TimeOfDay.solar_shift(nov.x, nov.x, nov.y, band)),
			"the clock's sunrise or sunset is not the sun's")
	var stretch := band.y / band.x
	_expect(absf(stretch - Pacer.num("time", "golden")) < 0.01, "the golden hour lasts %.2fx, not time.golden" % stretch)
	var before := nov.y - band.y
	_expect(absf((before + TimeOfDay.solar_shift(before, nov.x, nov.y, band)) - (nov.y - band.x)) < 0.01,
			"the golden band's edge is not where the sun is %.2f h before sunset" % band.x)
	# A look picked moves the clock forward to its hour, and its light follows.
	t.set_mode(TimeOfDay.DUSK, true)
	_expect(absf(float(t.local_clock()["hour"]) - nov.y) < 0.02 and t.look_mode() == TimeOfDay.DUSK, "Dusk is not the sunset")
	var dusk_sun := t.sun.light_color
	_expect(t.sun.shadow_enabled and dusk_sun.r > dusk_sun.b, "the sunset is not golden (sun %s)" % dusk_sun)
	t.set_mode(TimeOfDay.NIGHT, true)
	_expect(absf(float(t.local_clock()["hour"]) - 23.0) < 0.02 and t.look_mode() == TimeOfDay.NIGHT and t.lights_on > 0.9,
			"Night is not 23:00 with the lights on")
	t.set_hour(10.0, true)
	c = t.local_clock()
	_expect(absf(float(c["hour"]) - 10.0) < 0.02 and int(c["weekday"]) == 6, "10:00 after the night is not Saturday morning: %s" % [c])
	t.next()
	_expect(t.look_mode() == TimeOfDay.DUSK, "N after the day is not the dusk")
	_expect(GameTime.jump(t, null, 21.0) and absf(float(t.local_clock()["hour"]) - 21.0) < 0.02, "the jump does not move the game clock")
	# The watch: noon at the top, 6:00 left, quarter hours.
	_expect(is_equal_approx(ClockDial.hour_at(Vector2(0, -50)), 12.0) and is_equal_approx(ClockDial.hour_at(Vector2(-50, 0)), 6.0)
			and is_equal_approx(ClockDial.hour_at(Vector2(0, 50)), 0.0), "the watch's hours are wrong")
	# The map: the clock button opens the watch on the game clock's hour; the watch moves the clock;
	# a look button picks its look and the button the sun makes SELECTED (F 2026-11-20, the kit).
	t.set_hour(14.0, true)
	var fm := FullMap.new()
	fm.bounds = Rect2(-2000, -2000, 4000, 4000)
	fm.tod = t
	root.add_child(fm)
	fm.open(Vector2.ZERO, 0.0)
	fm._clock_tapped()
	var dial := fm.find_child("clock_dial", true, false)
	_expect(fm._picker.visible and dial != null and absf(float(dial.hour) - 14.0) < 0.05 and dial.day_name.size() == 2,
			"the map's watch did not open on 14:00 with the weekday")
	fm._hour_picked(17.5)
	_expect(absf(float(t.local_clock()["hour"]) - 17.5) < 0.02 and fm._clock_btn.text.ends_with("17:30"), "the watch did not move the clock to 17:30")
	fm._time_tapped(TimeOfDay.DAWN)
	_expect(t.look_mode() == TimeOfDay.DAWN, "the map's Dawn did not make the dawn")
	fm._clock_tapped()
	var chosen := 0
	for b: Button in fm._time_buttons:
		if b.get_theme_stylebox("normal").border_color == UiKit.GOLD:
			chosen += 1
	_expect(chosen == 1, "%d look buttons are SELECTED, not one" % chosen)
	_expect(ClockDial.phase(15.25, Vector2(7.07, 15.65)) == "clock_golden" and ClockDial.phase(23.0, Vector2(7.07, 15.65)) == "clock_night"
			and ClockDial.phase(11.0, Vector2(7.07, 15.65)) == "clock_day", "the watch's parts of the day are wrong")
	fm.free()
	t.free()
	sun.free()


func _run() -> void:
	_expect(GameTime.in_hours(23.0, Vector2(17, 2)) and GameTime.in_hours(1.0, Vector2(17, 2)), "17 to 2 does not hold 23:00 and 1:00")
	_expect(not GameTime.in_hours(15.0, Vector2(17, 2)) and GameTime.in_hours(15.0, Vector2(14, 23)), "hours wrong at 15:00")
	_expect(GameTime.hours("shisha") == Pacer.span("shisha", "hours"), "shisha's hours are not pacing.json's")
	_expect(GameTime.hours("nobody") == Vector2(0, 24), "an id without hours is not always open")
	var day := GameTime.open_ids(15.0)
	var night := GameTime.open_ids(23.0)
	for id: String in GameTime.NIGHT:
		_expect(not id in day, "%s is open at 15:00" % id)
		_expect(id in night, "%s is not open at 23:00" % id)
	for id: String in GameTime.SOURCES:
		_expect(GameTime.NAMES.has(id), "%s has no name for the map clock" % id)
	# By day (F 2026-11-19).
	var was := GameTime.BY_DAY
	GameTime.BY_DAY = 1.0
	_expect(GameTime.may_call(GameTime.hours("shisha"), 15.0), "with by_day the shisha night may not call at 15:00")
	_expect(not GameTime.may_call(Vector2(8, 19), 23.0, false), "a day-only activity may call at night")
	GameTime.BY_DAY = 0.0
	_expect(not GameTime.may_call(GameTime.hours("shisha"), 15.0) and GameTime.may_call(GameTime.hours("shisha"), 18.0), "without by_day the hours don't hold")
	GameTime.BY_DAY = was
	_expect(Pacer.num("time", "by_day") > 0.0, "the night friends don't call by day (time.by_day)")
	# The looks and the jump.
	_expect(GameTime.look_for(14.0) == "Day" and GameTime.look_for(19.0) == "Dusk" and GameTime.look_for(23.0) == "Night" \
			and GameTime.look_for(6.0) == "Dawn", "the looks for the hours are wrong")
	var tod := FakeTod.new()
	var hud := Fakes.Hud.new()
	root.add_child(tod)
	root.add_child(hud)
	_expect(GameTime.jump(tod, hud, 21.0) and tod.mode == TimeOfDay.NIGHT and is_equal_approx(tod.fixed_start, 21.0) \
			and hud.toasts.size() == 1, "the jump to 21:00 did not set the night, the clock and one toast")
	_expect(not GameTime.jump(null, hud, 21.0), "a jump without a clock")
	_expect(not GameTime.jump_into(tod, hud, Vector2(20, 4)) and hud.toasts.size() == 1, "a run inside its hours jumped")
	tod.fixed_start = -1.0
	tod.hour = 14.0
	_expect(GameTime.jump_into(tod, hud, Vector2(20, 4)) and GameTime.in_hours(float(tod.local_clock()["hour"]), Vector2(20, 4)),
			"a run at 14:00 that keeps 20 to 4 did not jump into its hours")
	# An activity of the kit: its call says when, its start jumps.
	var a := Activity.new()
	a.hud = null
	a.clock_node = tod
	a.run_hours = Vector2(21, 4)
	tod.fixed_start = -1.0
	tod.hour = 14.0
	_expect(not a._night_line().is_empty(), "a night run offered at 14:00 doesn't say when it starts")
	a.start()
	_expect(GameTime.in_hours(float(tod.local_clock()["hour"]), a.run_hours), "a night run taken at 14:00 didn't jump the clock")
	_expect(a._night_line().is_empty(), "a night run at night still says when it starts")
	a.free()
	var w: Array = GameTime.label({"hour": 14.09, "weekday": 5})
	_expect(w[0] == "PT 14:05" and w[1] == "Fri 14:05", "the clock's words: %s" % [w])
	tod.free()
	hud.free()
	_game_clock()
	for e: String in Pacer.errors:
		_expect(false, "pacer: " + e)
	if _problems == 0:
		print("check_game_time: OK (night at 23:00: %s; open at 15:00: %s)" % [", ".join(night), ", ".join(day)])
		quit(0)
	else:
		print("check_game_time: %d problems" % _problems)
		quit(1)
