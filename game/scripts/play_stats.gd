extends Node
## Anonymous play stats (F, 2026-11-15: "no confirmations for the player, an anonymous user id so I
## see who comes back, who is online, how long they play"; plan: docs/STATS.md). The one script
## that knows about PostHog (game/addons/posthog, the official GDScript SDK, EU Cloud): the rest of
## the game hands it its systems once (`watch`) and it listens to their signals, so no feature
## calls the SDK and the add-on can be swapped or dropped in one change.
##
## **What leaves the phone.** Only the events and properties in EVENTS (a white list: any other
## name, key, or a string that is not a short slug is dropped in `clean`), plus a few coarse super
## properties (`platform`, `lang`, `quality_tier`, `controls`) and the SDK's own `$os`,
## `$os_version`, `$app_version`, `$device_model` (the phone's model code, e.g. `iPhone17,2`; F, 2026-11-16:
## "how many different devices and which models"), screen size and session id, and one super property
## `device_name` (`device_name()`: the code as a readable slug, e.g. `iphone_16_pro_max`). `$locale` is
## taken out (`_before_send`). The id is the SDK's random UUID in `user://posthog/` (no device id,
## no advertising id, no account); `person_profiles` NEVER, no `identify`. The project discards the
## IP after the country is read (PostHog's "Discard client IP data", set 2026-11-15).
##
## **When it sends** (`mode_for`): only a release build (TestFlight, App Store, Play) with the
## setting on (Settings → Dźwięk, "Anonimowa statystyka", key "stats", on by default) and a saving
## session, and only when the project's token is in the build (`res://data/stats_key.json`, a
## gitignored file on the Mac that exports the builds: a cloud or CI build has none). A debug run, a
## test run (every flag), the editor and `--nosave` send nothing. `--stats=log` prints each event as
## a `play_stats:` line instead (the checks), `--stats=send` sends from a debug build (a device test).
##
## **Offline.** The SDK queues events on disk (up to 1000) and sends them when the network is back,
## also after a restart; going to the background ends the session (`session_end`) and flushes.
##
## Cost: nothing per frame but a float add; its own work runs once a second (`TICK`).

const PostHogScript := preload("res://addons/posthog/posthog.gd")
const PostHogConfigScript := preload("res://addons/posthog/posthog_config.gd")

## The project's token and host, written on the Mac (gitignored; data/*.json goes into the export).
const KEY_PATH := "res://data/stats_key.json"
## Perf thread (2026-11-23): written by tools/export_ios.sh and export_android.sh at each export
## ({"build": the iOS build number or Android version code, "commit"}), gitignored; missing in a
## run from the editor or a check ("dev").
const BUILD_STAMP := "res://data/build_stamp.json"
const HOST := "https://eu.i.posthog.com"
const TICK := 1.0
## fps_sample: taken twice a session, at these seconds into play (perf thread 2026-11-19: the second
## one shows a phone that slows as it warms), from the last FPS_WINDOW seconds.
const FPS_AT := [120.0, 600.0]
const FPS_WINDOW := 10
## A jump of the car longer than this in one tick is a teleport or a respawn, not driving (metres).
const JUMP := 80.0
## Turning the setting off: seconds the queued events (stats_off last) get to leave before opt_out.
const OFF_GRACE := 5.0

enum Mode { OFF, LOG, SEND }

## The white list: event -> {property: type}. Anything else is dropped (`clean`).
const EVENTS := {
	"session_start": {"fresh_save": TYPE_BOOL, "resumed": TYPE_BOOL, "zl": TYPE_INT, "load_ms": TYPE_INT,
			"title_ms": TYPE_INT, "quality": TYPE_STRING, "crashed_before": TYPE_BOOL},
	"session_end": {"minutes_played": TYPE_FLOAT, "km_driven": TYPE_FLOAT, "zl_earned": TYPE_INT, "runs_done": TYPE_INT,
			"heli_pct": TYPE_INT, "how": TYPE_STRING},
	"fps_sample": {"avg_fps": TYPE_FLOAT, "low_fps": TYPE_FLOAT, "draw_calls": TYPE_INT, "frame_cap": TYPE_INT,
			"minute": TYPE_INT, "quality": TYPE_STRING, "scale": TYPE_INT, "flying": TYPE_BOOL},
	"guide_beat": {"beat": TYPE_STRING, "how": TYPE_STRING, "t_play_s": TYPE_INT},
	## The funnel's bookends (stats thread 2026-11-21): the first job's start and its end (stage
	## start / end, once per install; `how` as activity_end), so a drop between the beats and the first job shows.
	"first_job": {"stage": TYPE_STRING, "activity": TYPE_STRING, "how": TYPE_STRING, "t_play_s": TYPE_INT},
	"activity_start": {"activity": TYPE_STRING, "job": TYPE_BOOL, "t_play_s": TYPE_INT},
	"activity_end": {"activity": TYPE_STRING, "job": TYPE_BOOL, "how": TYPE_STRING, "duration_s": TYPE_INT, "t_play_s": TYPE_INT},
	"chase_end": {"how": TYPE_STRING, "t_play_s": TYPE_INT},
	"discover": {"kind": TYPE_STRING, "id": TYPE_STRING, "t_play_s": TYPE_INT},
	"garage": {"action": TYPE_STRING, "id": TYPE_STRING},
	"heli_landed": {"t_play_s": TYPE_INT},
	"radio": {"station": TYPE_STRING},
	"setting": {"key": TYPE_STRING, "value": TYPE_STRING},
	"save_problem": {"kind": TYPE_STRING},
	"stats_off": {},
}
## The settings whose changes are counted (`setting`): the choices, never a slider's every step.
const SETTING_KEYS := ["controls", "pads", "quality", "traffic", "lang", "fps", "collide", "soft_fences",
		"handling", "angle", "grade", "text_large", "calm", "color_safe", "vibration", "stop_assist",
		"left_handed", "lane_assist", "chatter", "zones", "time", "weather"]
## The SDK's default properties that stay on the phone.
const STRIPPED := ["$locale"]
## iPhone model code -> readable name (slug), for the `device_name` super property. A code that is
## not here (a new phone, an iPad, an Android phone) is sent as its own slug: Android's code is
## Build.MODEL (e.g. sm-s918b); Godot has no call for the maker, so the model alone is what there is.
const IPHONES := {
	"iPhone10,1": "iphone_8", "iPhone10,4": "iphone_8", "iPhone10,2": "iphone_8_plus", "iPhone10,5": "iphone_8_plus",
	"iPhone10,3": "iphone_x", "iPhone10,6": "iphone_x", "iPhone11,2": "iphone_xs", "iPhone11,4": "iphone_xs_max",
	"iPhone11,6": "iphone_xs_max", "iPhone11,8": "iphone_xr", "iPhone12,1": "iphone_11", "iPhone12,3": "iphone_11_pro",
	"iPhone12,5": "iphone_11_pro_max", "iPhone12,8": "iphone_se_2", "iPhone13,1": "iphone_12_mini", "iPhone13,2": "iphone_12",
	"iPhone13,3": "iphone_12_pro", "iPhone13,4": "iphone_12_pro_max", "iPhone14,2": "iphone_13_pro", "iPhone14,3": "iphone_13_pro_max",
	"iPhone14,4": "iphone_13_mini", "iPhone14,5": "iphone_13", "iPhone14,6": "iphone_se_3", "iPhone14,7": "iphone_14",
	"iPhone14,8": "iphone_14_plus", "iPhone15,2": "iphone_14_pro", "iPhone15,3": "iphone_14_pro_max", "iPhone15,4": "iphone_15",
	"iPhone15,5": "iphone_15_plus", "iPhone16,1": "iphone_15_pro", "iPhone16,2": "iphone_15_pro_max", "iPhone17,1": "iphone_16_pro",
	"iPhone17,2": "iphone_16_pro_max", "iPhone17,3": "iphone_16", "iPhone17,4": "iphone_16_plus", "iPhone17,5": "iphone_16e",
	"iPhone18,1": "iphone_17_pro", "iPhone18,2": "iphone_17_pro_max", "iPhone18,3": "iphone_17", "iPhone18,4": "iphone_air",
}
## Where the iOS app runs on a Mac (Apple silicon "iPhone app on Mac"): Godot reports the model as
## iPhone99,x / iPad99,x there. They are tagged `platform=mac_ios_app`.
const MAC_PREFIXES := ["iphone99,", "ipad99,", "mac", "macbook", "imac"]
## Written every CHECKPOINT seconds while a session runs, deleted when it ends in order (`pause`): a file
## still there at the next launch is a session that was killed or crashed in the foreground.
const CHECKPOINT_PATH := "user://play_stats_session.json"
const CHECKPOINT := 15.0
## The settings flag file for F's own devices: the DEV page's "test device" toggle sets
## settings `test_device`; PostHog's filter drops events with `test_device = true`.
## A string property: a short slug, so no free text (a name, a sentence) can leave by mistake.
const SLUG_MAX := 32

var mode: int = Mode.OFF
## What was tracked, newest last (the last LOG_KEEP), for the checks.
var tracked: Array = []
const LOG_KEEP := 200

## Handed in by main.gd (`watch`).
var wallet: Node
var car: Node3D
## True while the player flies (main.gd's `flying`).
var is_flying: Callable = func() -> bool: return false
## Perf thread (2026-11-19), from main.gd's `look`: the level drawn now ("High", "Experimental"),
## the image's screen pixels per image pixel, the frame cap (60 on an iPhone, where Engine.max_fps
## is 0); and the launch's milliseconds from the engine's start to the start's sectors in (0: none).
var quality_now: Callable = func() -> String: return ""
var image_scale: Callable = func() -> int: return 0
var frame_cap: Callable = func() -> int: return Engine.max_fps
var load_ms := 0

var _sdk: Node
var _setting_on := true
var _begun := false
var _ended := true
var _play := 0.0
var _tick := 0.0
var _last_pos := Vector3.INF
var _km := 0.0
var _fly_s := 0.0
## `_play` when this stretch began (begin): the launch, or the last resume from the background.
var _play0 := 0.0
var _zl0 := 0
var _runs := 0
var _fps: Array[float] = []
var _fps_sent := 0
var _supers: Dictionary = {}
var _key: Dictionary = {}
var _checkpoint_t := 0.0
## A session found unfinished at launch (`_recover`): the next `begin` says so.
var _crashed_before := false
var _test_device := false


## The rule for this run (pure: check_stats tests it). `flag`: --stats= ("", "log", "send", "off").
static func mode_for(debug: bool, persistent: bool, setting_on: bool, flag: String, has_key: bool) -> int:
	if flag == "off":
		return Mode.OFF
	if flag == "log":
		return Mode.LOG
	if flag == "send":
		return Mode.SEND if has_key else Mode.LOG
	if debug or not persistent or not setting_on or not has_key:
		return Mode.OFF
	return Mode.SEND


## A short lower-case slug (Polish letters folded, spaces to "_"), or "" when it would not be one.
static func slug(text: String) -> String:
	var s := text.to_lower().strip_edges()
	var fold := {"ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n", "ó": "o", "ś": "s", "ź": "z", "ż": "z", " ": "_"}
	for k: String in fold:
		s = s.replace(k, fold[k])
	if s.is_empty() or s.length() > SLUG_MAX:
		return ""
	for c in s:
		if not (c >= "a" and c <= "z") and not (c >= "0" and c <= "9") and not c in ["_", "-", "."]:
			return ""
	return s


## The readable name of a model code (pure): IPHONES, else the code as a slug ("." for ","), else "".
static func device_name(model: String) -> String:
	if IPHONES.has(model):
		return str(IPHONES[model])
	return slug(model.replace(",", "."))


## True when the model code is a Mac running the iPhone/iPad app (pure).
static func is_mac_model(model: String) -> bool:
	var m := model.to_lower()
	for p: String in MAC_PREFIXES:
		if m.begins_with(p):
			return true
	return false


## The `platform` super property (pure): "ios", "android", "mac_ios_app" (an iOS app on a Mac), or the
## engine's name lower-cased.
static func platform_for(os_name: String, model: String) -> String:
	var n := os_name.to_lower()
	if n == "ios" and is_mac_model(model):
		return "mac_ios_app"
	return n


## The white list applied (pure): {} with "event" missing when the event is not on it.
static func clean(event: String, props: Dictionary) -> Dictionary:
	if not EVENTS.has(event):
		return {}
	var allowed: Dictionary = EVENTS[event]
	var out := {}
	for k: String in props:
		if not allowed.has(k):
			continue
		var v: Variant = props[k]
		match int(allowed[k]):
			TYPE_BOOL:
				out[k] = bool(v)
			TYPE_INT:
				out[k] = int(v)
			TYPE_FLOAT:
				out[k] = snappedf(float(v), 0.1)
			TYPE_STRING:
				var s := slug(str(v))
				if not s.is_empty():
					out[k] = s
	return {"event": event, "props": out}


## Reads the token file; {} without one.
## "0.1 (14, 839dfd2)": the version, the build and its commit (PostHog's app_build).
static func build_name(path := BUILD_STAMP) -> String:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not d is Dictionary:
		return version + " (dev)"
	var commit := str((d as Dictionary).get("commit", ""))
	return "%s (%s%s)" % [version, str((d as Dictionary).get("build", "dev")), ", " + commit if commit != "" else ""]


static func read_key(path := KEY_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()  # not JSON.parse_string: a broken file is no token, not an engine error
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var d: Variant = json.data
	if not d is Dictionary or not str(d.get("api_key", "")).begins_with("phc_"):
		return {}
	return d


## Start for this run. `supers`: platform, lang, quality_tier, controls.
func setup(debug: bool, persistent: bool, setting_on: bool, flag: String, supers: Dictionary) -> void:
	_key = read_key()
	_setting_on = setting_on
	mode = mode_for(debug, persistent, setting_on, flag, not _key.is_empty())
	_supers = {}
	var model := OS.get_model_name()
	var dn := device_name(model)
	if not dn.is_empty():
		_supers["device_name"] = dn
	# Stats thread 2026-11-21: the model and OS version are always set (the SDK's `$device_model` was
	# empty before 18 Nov and on the lifecycle events), as plain slugs beside the SDK's own.
	var ms := slug(model.replace(",", "."))
	if not ms.is_empty():
		_supers["device_model"] = ms
	var osv := slug(OS.get_version().replace(" ", "_"))
	if not osv.is_empty():
		_supers["os_version"] = osv
	var os_name := OS.get_name()
	_supers["platform"] = platform_for(os_name, model)
	for k: String in supers:
		if supers[k] is bool:
			_test_device = bool(supers[k]) if k == "test_device" else _test_device
			continue
		var s := slug(str(supers[k]))
		if not s.is_empty() and k != "platform":
			_supers[k] = s
	if _supers["platform"] == "mac_ios_app":
		_supers["device_name"] = "mac_ios_app"
	_supers["test_device"] = _test_device
	if mode == Mode.SEND:
		_start_sdk()
	set_process(mode != Mode.OFF)


func _start_sdk() -> void:
	if _sdk != null or _key.is_empty():
		return
	var c: Resource = PostHogConfigScript.new()
	c.api_key = str(_key["api_key"])
	c.host = str(_key.get("host", HOST))
	c.person_profiles = 2  # PostHogConfig.PersonProfiles.NEVER
	c.capture_exceptions = false
	c.capture_exceptions_in_editor = false
	c.preload_feature_flags = false
	c.send_feature_flag_event = false
	c.send_default_person_properties_for_flags = false
	c.flush_on_quit = false  # main.gd's _notification flushes; the SDK must not own the quit
	c.capture_application_lifecycle_events = true
	c.app_build = build_name()
	c.before_send = _before_send
	_sdk = PostHogScript.new()
	_sdk.name = "PostHog"
	add_child(_sdk)
	if not _sdk.setup(c):
		push_warning("play_stats.gd: PostHog setup failed; no stats this run")
		_sdk.queue_free()
		_sdk = null
		mode = Mode.OFF
		return
	if _sdk.is_opted_out:
		_sdk.opt_in()  # a launch after the setting was turned back on
	for k: String in _supers:
		_sdk.register(k, _supers[k])


## DEV → "Test device (stats)": F's own devices, so PostHog can filter them out.
func set_test_device(on: bool) -> void:
	_test_device = on
	_supers["test_device"] = on
	if _sdk != null:
		_sdk.register("test_device", on)


func _before_send(event: Dictionary) -> Variant:
	var p: Dictionary = event.get("properties", {})
	for k: String in STRIPPED:
		p.erase(k)
	# The SDK's own startup events (Application Installed / Opened) are captured before `register`:
	# the supers go on every event from here, so the model and platform are never missing.
	for k: String in _supers:
		if not p.has(k):
			p[k] = _supers[k]
	event["properties"] = p
	return event


## The game's systems, once they are built: each one that is there is listened to.
func watch(ctx: Dictionary) -> void:
	wallet = ctx.get("wallet")
	car = ctx.get("car")
	if ctx.get("is_flying") is Callable:
		is_flying = ctx["is_flying"]
	if ctx.get("look") is Callable:  # main.gd: [the level's name, the image's scale, the frame cap]
		var look: Callable = ctx["look"]
		quality_now = func() -> String: return str(look.call()[0])
		image_scale = func() -> int: return int(look.call()[1])
		frame_cap = func() -> int: return int(look.call()[2])
	var activities: Object = ctx.get("activities")
	if activities != null and activities.has_signal("run_started"):
		activities.run_started.connect(_on_run_started)
		activities.run_ended.connect(_on_run_ended)
	var police: Object = ctx.get("police")
	if police != null:
		police.chase_ended.connect(func(how: String) -> void: track("chase_end", {"how": how, "t_play_s": _play}))
	var first10: Object = ctx.get("first10")
	if first10 != null:
		first10.beat.connect(func(id: String, how: String, at: float) -> void:
			track("guide_beat", {"beat": id, "how": how, "t_play_s": at}))
	var tajny: Object = ctx.get("tajny")  # the Tajny klient opening's beats ("tk_*"), in the guide's funnel
	if tajny != null:
		tajny.beat.connect(func(id: String, how: String, at: float) -> void:
			track("guide_beat", {"beat": id, "how": how, "t_play_s": at}))
	var districts: Object = ctx.get("districts")
	if districts != null:
		districts.discovered.connect(func(id: String, _card: bool) -> void:
			track("discover", {"kind": "district", "id": id, "t_play_s": _play}))
	var eggs: Object = ctx.get("egg_book")
	if eggs != null:
		eggs.found.connect(func(id: String) -> void: track("discover", {"kind": "egg", "id": id, "t_play_s": _play}))
	var napkin: Object = ctx.get("napkin")
	if napkin != null:
		napkin.ticked.connect(func(id: String) -> void: track("discover", {"kind": "napkin", "id": id, "t_play_s": _play}))
	var garage: Object = ctx.get("garage")
	if garage != null:
		garage.opened.connect(func() -> void: track("garage", {"action": "visit"}))
		garage.painted.connect(func(id: String) -> void: track("garage", {"action": "paint", "id": id}))
		garage.upgraded.connect(func(id: String) -> void: track("garage", {"action": "upgrade", "id": id}))
	var heli: Object = ctx.get("heli")
	if heli != null:
		heli.landed.connect(func() -> void: track("heli_landed", {"t_play_s": _play}))
	var radio: Object = ctx.get("radio")
	if radio != null:
		radio.station_changed.connect(func(_i: int, info: Dictionary) -> void:
			if _begun:
				track("radio", {"station": str(info.get("id", "off"))}))
	var panel: Object = ctx.get("panel")
	if panel != null:
		panel.changed.connect(_on_setting)
	if wallet != null and wallet.has_signal("save_failed"):
		wallet.save_failed.connect(func(_e: int) -> void: track("save_problem", {"kind": "failed"}))
	var note: String = str(ctx.get("save_note", ""))
	if note != "":
		_pending_note = note

var _pending_note := ""


## The player is in the game (the title went, or there was none).
func begin(resumed := false) -> void:
	if mode == Mode.OFF or not _ended:
		return
	_begun = true
	_ended = false
	_km = 0.0
	_fly_s = 0.0
	_runs = 0
	_last_pos = Vector3.INF
	_zl0 = int(wallet.zl) if wallet != null else 0
	if not resumed:
		_play = 0.0
	_play0 = _play  # this stretch's start: session_end counts from here, not from the launch
	var fresh: bool = wallet != null and wallet.has_method("has_progress") and not wallet.has_progress()
	_recover()
	# title_ms: engine start to the tap on "tap to drive" (a launch only; 0 after a resume).
	track("session_start", {"fresh_save": fresh, "resumed": resumed, "zl": _zl0, "load_ms": load_ms,
			"title_ms": 0 if resumed else Time.get_ticks_msec(), "quality": str(quality_now.call()),
			"crashed_before": _crashed_before})
	_crashed_before = false
	_checkpoint_t = 0.0
	_write_checkpoint()
	load_ms = 0  # a resume after the background is not a launch
	if _pending_note != "":
		track("save_problem", {"kind": _pending_note})
		_pending_note = ""


## The app goes to the background or closes: the session's summary, then everything queued is sent.
func pause() -> void:
	if mode == Mode.OFF or not _begun or _ended:
		return
	_ended = true
	_drop_checkpoint()  # ended in order: the session_end below is queued on the disk
	var minutes := _stretch() / 60.0
	track("session_end", {"minutes_played": minutes, "km_driven": _km / 1000.0,
			"zl_earned": (int(wallet.zl) - _zl0) if wallet != null else 0, "runs_done": _runs,
			"heli_pct": int(round(100.0 * _fly_s / maxf(_stretch(), 1.0))), "how": "end"})
	flush()


## This stretch of play in seconds (since the launch or the last resume): what one session_end
## counts, so the stretches of one launch add up to its play and never count a minute twice.
func _stretch() -> float:
	return maxf(_play - _play0, 0.0)


## Back from the background: a new stretch of play (the play clock goes on).
func resume() -> void:
	if _begun and _ended:
		begin(true)


## A session file from an earlier run, still there: that run was killed or crashed in the foreground
## (an end in order deletes it, `pause`). Its play time so far is sent as a session_end `how=lost`, so
## play length is not missing for the sessions that never reached a pause.
func _recover() -> void:
	if not FileAccess.file_exists(CHECKPOINT_PATH):
		return
	var json := JSON.new()
	var ok := json.parse(FileAccess.get_file_as_string(CHECKPOINT_PATH)) == OK
	_drop_checkpoint()
	if not ok or not json.data is Dictionary:
		return
	var d: Dictionary = json.data
	_crashed_before = true
	track("session_end", {"minutes_played": float(d.get("play", 0.0)) / 60.0, "km_driven": float(d.get("km", 0.0)) / 1000.0,
			"zl_earned": int(d.get("zl", 0)), "runs_done": int(d.get("runs", 0)),
			"heli_pct": int(d.get("heli_pct", 0)), "how": "lost"})


func _write_checkpoint() -> void:
	if mode == Mode.OFF:
		return
	var f := FileAccess.open(CHECKPOINT_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"play": _stretch(), "km": _km, "runs": _runs,
			"zl": (int(wallet.zl) - _zl0) if wallet != null else 0,
			"heli_pct": int(round(100.0 * _fly_s / maxf(_stretch(), 1.0)))}))
	f.close()


func _drop_checkpoint() -> void:
	if FileAccess.file_exists(CHECKPOINT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CHECKPOINT_PATH))


func flush() -> void:
	if _sdk != null and mode == Mode.SEND:
		_sdk.flush()


## Settings → Dźwięk, "Anonimowa statystyka": off says so once, sends what is queued, then stops and
## forgets the queue; on starts again (a new session).
func set_enabled(on: bool) -> void:
	if on == _setting_on:
		return
	_setting_on = on
	if not on:
		if mode == Mode.OFF:
			return
		track("stats_off", {})
		mode = Mode.OFF
		set_process(false)
		if _sdk != null:
			# Not awaited: offline, the send would wait for the network's timeout. What is queued
			# (stats_off last) gets OFF_GRACE seconds, then opt_out drops the rest.
			_sdk.flush()
			get_tree().create_timer(OFF_GRACE).timeout.connect(func() -> void:
				if _sdk != null and not _setting_on:
					_sdk.opt_out())
		return
	if _key.is_empty() or OS.is_debug_build():
		return
	mode = Mode.SEND
	_start_sdk()
	if _sdk != null and _sdk.is_opted_out:
		_sdk.opt_in()
	set_process(true)
	_ended = true
	if _begun:
		begin(true)


## One event, through the white list.
func track(event: String, props: Dictionary) -> void:
	if mode == Mode.OFF:
		return
	var e := clean(event, props)
	if e.is_empty():
		push_warning("play_stats.gd: '%s' is not on the white list" % event)
		return
	tracked.append(e)
	if tracked.size() > LOG_KEEP:
		tracked.pop_front()
	if mode == Mode.LOG:
		print("play_stats: %s %s" % [e["event"], JSON.stringify(e["props"])])
	elif _sdk != null:
		_sdk.capture(e["event"], e["props"])


## The once-per-install funnel marks ("first_job" start / end), kept in a tiny file beside the SDK's.
const STATE_PATH := "user://play_stats_state.json"


func _state() -> Dictionary:
	if not FileAccess.file_exists(STATE_PATH):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(STATE_PATH)) == OK and json.data is Dictionary:
		return json.data
	return {}


## True the first time `mark` is asked for (and remembers it).
func _first_time(mark: String) -> bool:
	if mode == Mode.OFF:
		return false
	var d := _state()
	if d.has(mark):
		return false
	d[mark] = true
	var f := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()
	return true


func _on_run_started(a: Object) -> void:
	if bool(a.get("is_job")) and _first_time("job_start"):
		track("first_job", {"stage": "start", "activity": str(a.get("tag")), "t_play_s": _play})
	track("activity_start", {"activity": str(a.get("tag")), "job": bool(a.get("is_job")), "t_play_s": _play})


func _on_run_ended(a: Object, how: String, seconds: float) -> void:
	if bool(a.get("is_job")) and how == "done" and _first_time("job_done"):
		track("first_job", {"stage": "end", "activity": str(a.get("tag")), "how": how, "t_play_s": _play})
	if how in ["done", "won", "lost"]:  # a race's end says who won (rivals.gd)
		_runs += 1
	track("activity_end", {"activity": str(a.get("tag")), "job": bool(a.get("is_job")), "how": how,
			"duration_s": seconds, "t_play_s": _play})


func _on_setting(key: String, value: Variant) -> void:
	if key == "stats":
		return  # set_enabled answers it
	if key in SETTING_KEYS:
		track("setting", {"key": key, "value": str(value)})


func _process(dt: float) -> void:
	if not _begun or _ended:
		return
	_play += dt
	_tick += dt
	if _tick < TICK:
		return
	_tick -= TICK
	_second()
	_checkpoint_t += TICK
	if _checkpoint_t >= CHECKPOINT:
		_checkpoint_t = 0.0
		_write_checkpoint()
		flush()  # what is queued leaves now, not only at the SDK's 30 s timer or a pause


## Once a second: the distance, the time in the air, the frame-rate sample.
func _second() -> void:
	var flying: bool = is_flying.call()
	if flying:
		_fly_s += TICK
	if car != null and is_instance_valid(car) and not flying:
		var p := car.global_position
		if _last_pos != Vector3.INF:
			var d := Vector2(p.x - _last_pos.x, p.z - _last_pos.z).length()
			if d < JUMP:
				_km += d
		_last_pos = p
	else:
		_last_pos = Vector3.INF
	if _fps_sent >= FPS_AT.size():
		return
	_fps.append(Engine.get_frames_per_second())
	if _fps.size() > FPS_WINDOW:
		_fps.pop_front()
	if _play >= float(FPS_AT[_fps_sent]) and _fps.size() >= FPS_WINDOW:
		_fps_sent += 1
		var total := 0.0
		for f in _fps:
			total += f
		track("fps_sample", {"avg_fps": total / _fps.size(), "low_fps": _fps.min(),
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"frame_cap": int(frame_cap.call()), "minute": int(_play / 60.0), "quality": str(quality_now.call()),
				"scale": int(image_scale.call()), "flying": flying})
