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
##   godot --headless --path game --script res://tools/check_game_time.gd

const GameTime := preload("res://scripts/game_time.gd")
const Pacer := preload("res://scripts/pacer.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Activity := preload("res://scripts/activity.gd")
const Fakes := preload("res://tools/fakes.gd")


## A clock with the methods the jump uses.
class FakeTod extends Node:
	var mode := 0
	var fixed_start := -1.0
	var hour := 14.0
	func set_mode(m: int, _instant := false) -> void:
		mode = m
	func local_clock() -> Dictionary:
		return {"hour": fixed_start if fixed_start >= 0.0 else hour, "weekday": 5}


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run.call_deferred()


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
	for e: String in Pacer.errors:
		_expect(false, "pacer: " + e)
	if _problems == 0:
		print("check_game_time: OK (night at 23:00: %s; open at 15:00: %s)" % [", ".join(night), ", ".join(day)])
		quit(0)
	else:
		print("check_game_time: %d problems" % _problems)
		quit(1)
