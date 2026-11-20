extends SceneTree
## The beta's anonymous play stats (play_stats.gd, docs/STATS.md):
##   mode      the rule for a run: a debug build, `--nosave`, the setting off or no token send
##             nothing; `--stats=log` logs, `--stats=send` without a token only logs, `--stats=off`
##             wins over all; a release build with all four sends
##   list      the white list: an event not on it is dropped, a property not on it is dropped, every
##             value is cast to its type, a string that is not a short slug (a name, a sentence,
##             an e-mail) never leaves
##   key       the token file: none, a broken one or one without a "phc_" token is no token
##   log       a LOG run: `begin` says session_start, a setting change on the list is counted (one
##             off the list, a slider's step, is not), `pause` says session_end once, off says
##             stats_off and then nothing more is tracked
##   signals   the director passes each run's start and end on (activities.gd run_started,
##             run_ended) and an activity keeps how its run ended (activity.gd end_how)
## No map, no network. Exits 1 on a problem.
##
##   godot --headless --path game --script res://tools/check_stats.gd

const PlayStats := preload("res://scripts/play_stats.gd")
const Activities := preload("res://scripts/activities.gd")
const Activity := preload("res://scripts/activity.gd")

var _problems: Array[String] = []


func _initialize() -> void:
	if not (PlayStats as GDScript).can_instantiate():
		print("check_stats: FAIL play_stats.gd does not compile")
		quit(1)
		return
	_mode()
	_list()
	_key()
	_log()
	_device()
	_signals()
	if _problems.is_empty():
		print("check_stats: OK")
		quit(0)
	else:
		for p in _problems:
			print("check_stats: FAIL ", p)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems.append(what)


func _mode() -> void:
	var OFF := PlayStats.Mode.OFF
	var LOG := PlayStats.Mode.LOG
	var SEND := PlayStats.Mode.SEND
	# debug, persistent, setting, flag, key
	_expect(PlayStats.mode_for(false, true, true, "", true) == SEND, "release + save + setting + key should send")
	_expect(PlayStats.mode_for(true, true, true, "", true) == OFF, "a debug build sent without a flag")
	_expect(PlayStats.mode_for(false, false, true, "", true) == OFF, "--nosave sent")
	_expect(PlayStats.mode_for(false, true, false, "", true) == OFF, "the setting off sent")
	_expect(PlayStats.mode_for(false, true, true, "", false) == OFF, "no token but not OFF")
	_expect(PlayStats.mode_for(true, false, false, "log", false) == LOG, "--stats=log did not log")
	_expect(PlayStats.mode_for(true, false, true, "send", false) == LOG, "--stats=send without a token did not fall back to log")
	_expect(PlayStats.mode_for(true, false, true, "send", true) == SEND, "--stats=send with a token did not send")
	_expect(PlayStats.mode_for(false, true, true, "off", true) == OFF, "--stats=off did not win")


func _list() -> void:
	_expect(PlayStats.clean("not_an_event", {"a": 1}).is_empty(), "an event off the list was kept")
	var e := PlayStats.clean("activity_end", {"activity": "Bar Crawl", "job": 1, "how": "done", "duration_s": 61.7,
			"t_play_s": 12.2, "name": "Jan Kowalski"})
	_expect(not e.is_empty(), "activity_end dropped")
	if e.is_empty():
		return
	var p: Dictionary = e["props"]
	_expect(not p.has("name"), "a property off the list was kept")
	_expect(p.get("activity") == "bar_crawl", "slug: 'Bar Crawl' gave %s" % p.get("activity"))
	_expect(p.get("job") is bool and p["job"] == true, "a bool was not cast")
	_expect(p.get("duration_s") is int and p["duration_s"] == 61, "an int was not cast: %s" % p.get("duration_s"))
	_expect(PlayStats.slug("Śródmieście") == "srodmiescie", "slug folds Polish letters: %s" % PlayStats.slug("Śródmieście"))
	for bad in ["ola@example.com", "a sentence that is far too long to be a slug ever", "nazwa/ścieżka", ""]:
		_expect(PlayStats.slug(bad) == "", "slug let '%s' through" % bad)
	var r := PlayStats.clean("radio", {"station": "who knows? (free text)"})
	_expect(not (r["props"] as Dictionary).has("station"), "free text left as a station")


func _key() -> void:
	var dir := OS.get_user_data_dir()
	_expect(PlayStats.read_key(dir.path_join("no_such_stats_key.json")).is_empty(), "a missing key file gave a key")
	var path := dir.path_join("check_stats_key.json")
	for text in ["{broken", "{\"api_key\": \"sk_live_x\"}", "[]"]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		_expect(PlayStats.read_key(path).is_empty(), "a bad key file gave a key: %s" % text)
	var g := FileAccess.open(path, FileAccess.WRITE)
	g.store_string("{\"api_key\": \"phc_test\", \"host\": \"https://eu.i.posthog.com\"}")
	g.close()
	_expect(str(PlayStats.read_key(path).get("api_key", "")) == "phc_test", "a good key file was refused")
	DirAccess.remove_absolute(path)


func _device() -> void:
	_expect(PlayStats.device_name("iPhone17,2") == "iphone_16_pro_max", "iPhone17,2 is not the 16 Pro Max")
	_expect(PlayStats.device_name("iPhone99,1") == "iphone99.1", "an unknown iPhone code: %s" % PlayStats.device_name("iPhone99,1"))
	_expect(PlayStats.device_name("SM-S918B") == "sm-s918b", "an Android model code: %s" % PlayStats.device_name("SM-S918B"))
	_expect(PlayStats.device_name("A phone with a very long name that is no slug at all") == "", "a long model was sent")
	_expect(not PlayStats.STRIPPED.has("$device_model") and PlayStats.STRIPPED.has("$locale"), "STRIPPED is not just the locale")


func _log() -> void:
	var s: PlayStats = PlayStats.new()
	root.add_child(s)
	s.setup(true, false, true, "", {})
	_expect(s.mode == PlayStats.Mode.OFF, "a debug run without --stats= is not OFF")
	s.begin()
	_expect(s.tracked.is_empty(), "an OFF run tracked")
	s.setup(true, false, true, "log", {"platform": "Linux"})
	s.load_ms = 4321
	s.begin()
	_expect(_names(s).has("session_start"), "no session_start")
	_expect(int(s.tracked.back()["props"].get("load_ms", -1)) == 4321 and s.load_ms == 0, "session_start's load_ms: %s" % s.tracked.back())
	# Perf thread: two fps samples, at 2 and 10 minutes of play, with the level, the image's scale and the cap.
	s.quality_now = func() -> String: return "High"
	s.image_scale = func() -> int: return 2
	s.frame_cap = func() -> int: return 60
	for t: float in [121.0, 601.0, 1300.0]:
		s._play = t
		for i in PlayStats.FPS_WINDOW + 1:
			s._second()
	var samples := s.tracked.filter(func(e: Dictionary) -> bool: return e["event"] == "fps_sample")
	_expect(samples.size() == 2, "fps samples: %d, wanted 2" % samples.size())
	if samples.size() == 2:
		var p0: Dictionary = samples[0]["props"]
		_expect(int(p0["minute"]) == 2 and int(samples[1]["props"]["minute"]) == 10 and p0["quality"] == "high"
				and int(p0["scale"]) == 2 and int(p0["frame_cap"]) == 60, "fps_sample's props: %s" % p0)
	s._on_setting("traffic", 2)
	s._on_setting("master", 0.4)
	_expect(_names(s).count("setting") == 1, "settings counted: %d (traffic yes, a volume slider no)" % _names(s).count("setting"))
	s.pause()
	s.pause()
	_expect(_names(s).count("session_end") == 1, "session_end %d times" % _names(s).count("session_end"))
	s.resume()
	_expect(_names(s).count("session_start") == 2, "resume did not start a new stretch")
	s.set_enabled(false)
	_expect(_names(s).back() == "stats_off", "turning off did not say stats_off")
	var n := s.tracked.size()
	s.track("radio", {"station": "nocna_fm"})
	s.pause()
	_expect(s.tracked.size() == n and s.mode == PlayStats.Mode.OFF, "events tracked after the setting went off")
	s.queue_free()


func _names(s: PlayStats) -> Array:
	return s.tracked.map(func(e: Dictionary) -> String: return str(e["event"]))


func _signals() -> void:
	var d := Activities.new()
	_expect(d.has_signal("run_started") and d.has_signal("run_ended"), "activities.gd has no run_started / run_ended")
	var a := Activity.new()
	_expect(a.end_how == "ended", "activity.gd end_how missing")
	var got: Array = []
	d.run_ended.connect(func(x: Object, how: String, secs: float) -> void: got.append([x, how, secs]))
	d._ended(a)
	_expect(got.size() == 1 and got[0][1] == "ended", "the director did not pass the end on")
	a.free()
