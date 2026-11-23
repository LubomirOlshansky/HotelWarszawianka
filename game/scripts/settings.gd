extends RefCounted
## Loop 2a: the player's settings, kept between sessions in user://settings.cfg (a
## ConfigFile beside the wallet's save.cfg, which wallet.gd rewrites whole): the control
## scheme and (for Classic) the camera, the traffic level, quality, three volumes and the
## performance overlay; loop 2b: the frame rate (60, or 30 to save the battery); loop 2e: the
## picture style (it moved off the driving screen into Settings; the time of
## day and the rain are the world's state and start by day and dry). `--nosave` neither reads
## nor writes it; command-line flags (`--controls= --traffic= --quality= --fixed --perf
## --style=`) win for that run and are not saved unless the player then changes the setting.
## Loop G1b: Auto's sharp image and its fallback (`[auto_image]`, tiers.gd SHARP_*), written only
## by a normal launch's own sessions (main.gd: never by --nosave, test runs, benches or
## --last-session=); a file without it (from before G1b) starts sharp.
## Loop 3h slice 1 (save v2): the file carries `[meta] version` (VERSION, 2); a file without it is
## version 1 and loads as before (loop G1's High → Auto rule is that migration); the next save
## writes version 2. A file from a newer version is read and never overwritten.

const FollowCamera := preload("res://scripts/follow_camera.gd")
const Tiers := preload("res://scripts/tiers.gd")
const SafeFile := preload("res://scripts/safe_file.gd")
const PATH := "user://settings.cfg"
## Loop 3h slice 1: the settings file's format version (1: before loop 3h, no `[meta]`).
const VERSION := 2
## F 2026-11-16 (TestFlight build 12): the players' defaults for the collision answer (2: mid) and the
## fences that break (on).
const DEFAULT_COLLIDE := 2
const DEFAULT_SOFT := true
## Traffic levels: traffic.gd's density (Busy = 1.0, the level before loop 2a) and the
## share of the pedestrians. Busy's target is more than the spawner can place in the band
## round the view (about 44 cars at the default view, wanted 70), so the densities are set
## from the cars that really appear (bench, default view): Busy 26 on screen, Normal ~17
## (0.65 of it, the new default: the player asked for a little less), Low ~10 (0.4),
## Almost empty ~5. Pedestrians follow more gently (about the square root of those shares).
const TRAFFIC := [0.1, 0.22, 0.38, 1.0]
const PEOPLE := [0.45, 0.65, 0.8, 1.0]
const TRAFFIC_NAMES := ["Almost empty", "Low", "Normal", "Busy"]
const TRAFFIC_KEYS := ["empty", "low", "normal", "busy"]
## The default for a fresh save: Low (F, 2026-11-01: the default was too heavy). Saves keep their choice.
const DEFAULT_TRAFFIC := 1
## How many collision presets the `collide` row has (collide_rules.gd PRESETS: v1, soft, mid, firm;
## not preloaded here: settings.gd is loaded before the title shows, check_boot.gd).
const COLLIDE_PRESETS := 4

## drive_controls.gd: POINT, CLASSIC, FIXED. Classic (steer left / right, GAS and BRAKE) is
## the only scheme in Settings since 2026-11-10 (F: remove the point-to-go option); Point and
## Fixed stay in drive_controls.gd for the --controls= test flag only.
const DEFAULT_CONTROLS := 1
var controls := DEFAULT_CONTROLS
## Classic's touch steering: PADS_SLIDER (1, the default since F 2026-11-14: the sliding steering
## strip) or PADS_ARROWS (0: fixed see-through arrows bottom left, F 2026-11-13). Both have the
## see-through GAZ / HAMULEC pedals bottom right. Settings → Jazda → Sterowanie, key "pads". A save
## without `[controls] pads_default` (every save before 2026-11-14) starts on the slider once, then
## keeps the player's choice.
const PADS_ARROWS := 0
const PADS_SLIDER := 1
var pads := PADS_SLIDER
## Classic only: the camera follows the car (CAM toggles it); Point always follows, Fixed never.
var classic_follow := true
var traffic := DEFAULT_TRAFFIC
## tiers.gd: AUTO (-1, the default since loop G1: the level Auto picks for the device) or
## Low, Medium, High, Ultra (0-3). A file saved before G1 (no `tiers` key) that says High
## loads as Auto, once: High was the default then, not a choice; the next save marks the file.
const AUTO := -1
const HIGH := 2
const ULTRA := 3
const EXPERIMENTAL := 4
var quality := AUTO
## Perf thread (2026-11-19): Experimental is saved like any level. quality_keep.gd sets this before a
## launch at Experimental and clears it after 10 s of frames; a launch that finds it still set (the
## last one never got going: a crash on the 8192 shadow map) loads Ultra instead, once (`quality_guarded`).
var quality_pending := false
var quality_guarded := false
## Perf thread (F 2026-11-20): Obraz Piksel / Pełny: the 3D image at the screen's own pixels on any
## level (tiers.gd full_image). Off by default: x2 on a phone is what holds 60.
var image_full := false
## Perf thread (2026-11-23): Auto's level steps down by this many after sessions that struggled, and
## back up one after DROP_CALM calm sessions (quality_keep.gd); `auto_calm` counts those.
var auto_drop := 0
var auto_calm := 0
## 0..1 each: everything, the radio (Music bus), the effects (SFX and Ambience buses).
var master := 1.0
var music := 1.0
var effects := 1.0
var perf := false
## Loop 2b: frames per second, 60 (the default; ProMotion phones would otherwise run at 120 and
## warm up) or 30 (battery saver).
const FPS := [60, 30]
var fps := 60
## The follow-camera loop (2026-10-30): the driving view's height in metres, the player's zoom
## (follow_camera.gd VIEWS). The start view is 65 m (F, 2026-11-20: "start with a little bit closer
## look, not so far"), one step in from the 80 m DEFAULT_SIZE the bench and the helicopter keep.
var view := 65.0
## F, 2026-11-07: the camera's angle over the ground in degrees (follow_camera.gd PITCHES; 30, the
## game's look, is the default). Settings → Obraz, key "angle".
var pitch := FollowCamera.DEFAULT_PITCH
## F, 2026-11-17: the camera view (follow_camera.gd VIEW_*): 0 the game's (the default), 1 top-down
## (main.gd `top_down`: straight down, north up), 2 aerial (the website's high view). DEV →
## "Widok kamery · Camera view", key "camera_view".
var camera_view := FollowCamera.VIEW_NORMAL
## F 2026-11-20: Promo Mode (promo_mode.gd), DEV → "Tryb promo · Promo mode", key "promo"; off by
## default. `promo_shots`: its saved frames, "x,y,z,yaw,pitch,size,hour,date" each.
var promo := false
## Stats thread 2026-11-21: DEV → "Test device (stats)": marks this device's events `test_device=true` so PostHog can
## filter F's own devices out (play_stats.gd). Off by default, key "test_device".
var test_device := false
var promo_shots := PackedStringArray()
## Loop 2e: main.gd STYLES (Sharp, Fine, Clean, Chunky). The Retro filter setting (key display/vhs) was removed
## 2026-11-22 (F: it did not work on phones); an old file that still has the key is simply not read.
var style := 0
## The colour look (grades.gd SETTING: 0 "warsaw", shown as Natural, the default; 1 Neon; 2 Classic, the picture
## before 2026-11-15). Settings → Obraz → Kolory, key "grade".
var grade := 0
## F's asks (2026-10-30): the pedestrian zones' 20 km/h cap (ped_zones.gd, loop 3d-1) and its
## pill, off by default (driving made easier); Settings → JAZDA turns it on. The guards stand in
## the zones either way, and the footway clamp is not part of it.
var zone_cap := false
## H1 (F 2026-11-22): the Realnie switch, the car with weight (car.gd GROUNDED, F 2026-11-04 "too
## arcade"): 0 off (the default), 1 on. DEV page, key "handling" (before H1 it held 0 Cruise,
## 1 Sport, 2 Grounded; `load` moves those saves over).
var handling := 0
## H1: „Charakter jazdy" 0..1, Spokojnie to Sportowo (car.gd set_character, CRUISE_AT), one slider
## for what Cruise/Sport and the sensitivity did. Settings → Jazda, key "character".
## About two thirds of the way to Sport's steering, with Cruise's grip (car.gd CRUISE_AT).
const CHARACTER_DEFAULT := 0.65
var character := CHARACTER_DEFAULT
## Beta values (2026-11-04): the lane assist (lane_assist.gd), Classic only. Settings → Jazda, key
## "lane_assist". On by default since 2026-11-13 (F: "A + lane assist", with the fixed arrows: an
## arrow is all or nothing, so between taps the lane holds the car straight); a save from before
## (no `lane_assist_default` key) starts on once, then keeps the player's choice.
var lane_assist := true
## Phase 0.2 (docs/GAMEPLAY_PLAN.md): the city's chattiness, chatter.gd GAPS: 0 Mało, 1 Średnio (the
## default), 2 Dużo. Settings → ŚWIAT, key "chatter".
var chatter := 1
## The city objects plan, settings rows (F 2026-11-14): the car's collision answer, an index into
## collide_rules.gd PRESETS (0 v1 "Klasyczne", the default; 1 soft, 2 mid, 3 firm), Settings → ŚWIAT,
## key "collide"; `--collide=` wins for a run. F 2026-11-16 (TestFlight build 12): Medium (2, "mid") is
## the default, and an older file (no `collide_default` key) starts on it once, then keeps the choice.
var collide := DEFAULT_COLLIDE
## Step 7's fences and hedges that break (soft_things.gd), DEV page, key "soft_fences". On by default
## since F 2026-11-16 (TestFlight build 12; before: off, "on for you only, off for testers"); an older
## file (no `collide_default` key) starts on once, then keeps the choice. `--no-soft` keeps them hard
## for a run, `--soft` breakable. A `--nosave` run (the checks) keeps the old measured defaults, hard
## fences and v1, unless a flag says otherwise (main.gd `_soft_on`, `_collide_preset`).
var soft_fences := DEFAULT_SOFT
## The beta's anonymous play stats (play_stats.gd, docs/STATS.md), Settings → DŹWIĘK beside the
## language, key "stats". On by default (F 2026-11-15: no consent card in the beta, an off switch
## in Settings); off stops sending at once and drops what waits to be sent.
var stats := true
## Accessibility (access.gd, Settings → ŁATWOŚĆ): larger HUD text, calm (no flashing or shaking),
## colour-safe markers, the phone's vibration, and the quest stop assist.
var text_large := false
var calm := false
var color_safe := false
var vibration := true
var stop_assist := true
## Accessibility (2026-11-01): the pedals on the left, the stick on the right (hud.gd).
var left_handed := false
## The language (lang.gd): "" until the player picks one (then the phone decides), "pl" or "en".
var lang := ""
## Loop G1b: Auto's sharp-image state (tiers.gd sharp_state: fallback, calm, wait, trial, why).
var auto_image := Tiers.sharp_state()
## False with --nosave: nothing is read or written.
var persistent := true
## Where it is kept (tools/check_settings.gd points it at a scratch file).
var path := PATH
## Loop 3h slice 1: the version of the file as loaded (0: no file); true when it is newer than
## VERSION (then save() leaves it alone).
var loaded_version := 0
var newer := false


func load_file() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	loaded_version = int(cfg.get_value("meta", "version", 1))
	newer = loaded_version > VERSION
	controls = clampi(int(cfg.get_value("controls", "scheme", controls)), 0, 2)
	# 2026-11-10 (F): the Point option is gone from the game, so a saved Point (or Fixed) scheme loads
	# as Classic; the camera on / off row keeps the follow choice (classic_follow).
	var saved_scheme := controls
	controls = DEFAULT_CONTROLS
	classic_follow = bool(cfg.get_value("controls", "classic_follow", classic_follow))
	pads = clampi(int(cfg.get_value("controls", "pads", pads)), PADS_ARROWS, PADS_SLIDER)
	if not cfg.has_section_key("controls", "pads_default"):
		pads = PADS_SLIDER  # F 2026-11-14: the slider is the default again, once for every older save
	if saved_scheme == 2:  # Fixed camera was Point's still-camera twin: Classic with the camera off
		classic_follow = false
	traffic = clampi(int(cfg.get_value("world", "traffic", traffic)), 0, TRAFFIC.size() - 1)
	quality = clampi(int(cfg.get_value("world", "quality", quality)), AUTO, EXPERIMENTAL)
	quality_pending = bool(cfg.get_value("world", "quality_pending", false))
	image_full = bool(cfg.get_value("display", "image_full", false))
	auto_drop = clampi(int(cfg.get_value("world", "auto_drop", 0)), 0, 3)
	auto_calm = maxi(int(cfg.get_value("world", "auto_calm", 0)), 0)
	if quality_pending and quality == EXPERIMENTAL:
		quality = ULTRA
		quality_pending = false
		quality_guarded = true
	if quality == HIGH and not cfg.has_section_key("world", "tiers"):
		quality = AUTO
	master = clampf(float(cfg.get_value("sound", "master", master)), 0.0, 1.0)
	music = clampf(float(cfg.get_value("sound", "music", music)), 0.0, 1.0)
	effects = clampf(float(cfg.get_value("sound", "effects", effects)), 0.0, 1.0)
	perf = bool(cfg.get_value("debug", "perf", perf))
	fps = int(cfg.get_value("display", "fps", fps))
	if not fps in FPS:
		fps = FPS[0]
	style = clampi(int(cfg.get_value("display", "style", style)), 0, 3)
	grade = clampi(int(cfg.get_value("display", "grade", grade)), 0, Grades.SETTING.size() - 1)
	view = clampf(float(cfg.get_value("display", "view", view)), FollowCamera.VIEWS[0], FollowCamera.VIEWS[-1])
	pitch = float(cfg.get_value("display", "pitch", pitch))
	if not pitch in FollowCamera.PITCHES:
		pitch = FollowCamera.DEFAULT_PITCH
	camera_view = clampi(int(cfg.get_value("display", "camera_view", camera_view)), 0, FollowCamera.VIEW_AERIAL)
	promo = bool(cfg.get_value("debug", "promo", promo))
	test_device = bool(cfg.get_value("debug", "test_device", test_device))
	promo_shots = PackedStringArray(cfg.get_value("debug", "promo_shots", promo_shots))
	zone_cap = bool(cfg.get_value("game", "zone_cap", zone_cap))
	if cfg.has_section_key("game", "character"):
		handling = clampi(int(cfg.get_value("game", "handling", handling)), 0, 1)
		character = clampf(float(cfg.get_value("game", "character", character)), 0.0, 1.0)
	else:
		character = migrate_character(int(cfg.get_value("game", "handling", 0)),
				float(cfg.get_value("game", "sensitivity", 0.5)))
		handling = 1 if int(cfg.get_value("game", "handling", 0)) == 2 else 0
	lane_assist = bool(cfg.get_value("game", "lane_assist", lane_assist))
	if not cfg.has_section_key("game", "lane_assist_default"):
		lane_assist = true
	chatter = clampi(int(cfg.get_value("world", "chatter", chatter)), 0, 2)
	collide = clampi(int(cfg.get_value("game", "collide", collide)), 0, COLLIDE_PRESETS - 1)
	soft_fences = bool(cfg.get_value("game", "soft_fences", soft_fences))
	if not cfg.has_section_key("game", "collide_default"):
		# F 2026-11-16: the two rows were on the hidden DEV page, so an older file holds the old
		# defaults, not a choice: once, the new ones.
		collide = DEFAULT_COLLIDE
		soft_fences = DEFAULT_SOFT
	stats = bool(cfg.get_value("game", "stats", stats))
	text_large = bool(cfg.get_value("access", "text_large", text_large))
	calm = bool(cfg.get_value("access", "calm", calm))
	color_safe = bool(cfg.get_value("access", "color_safe", color_safe))
	vibration = bool(cfg.get_value("access", "vibration", vibration))
	stop_assist = bool(cfg.get_value("access", "stop_assist", stop_assist))
	left_handed = bool(cfg.get_value("access", "left_handed", left_handed))
	lang = str(cfg.get_value("game", "lang", lang))
	if lang != "" and not lang in ["pl", "en"]:
		lang = ""
	var image := {}
	for key in auto_image:
		image[key] = cfg.get_value("auto_image", key, auto_image[key])
	auto_image = Tiers.sharp_clean(image)


func save() -> void:
	if not persistent or newer:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("controls", "scheme", controls)
	cfg.set_value("controls", "classic_follow", classic_follow)
	cfg.set_value("controls", "pads", pads)
	cfg.set_value("controls", "pads_default", 1)
	cfg.set_value("controls", "classic_default", 1)
	cfg.set_value("world", "traffic", traffic)
	cfg.set_value("world", "quality", quality)
	cfg.set_value("world", "quality_pending", quality_pending)
	cfg.set_value("display", "image_full", image_full)
	cfg.set_value("world", "auto_drop", auto_drop)
	cfg.set_value("world", "auto_calm", auto_calm)
	cfg.set_value("world", "tiers", 1)
	cfg.set_value("sound", "master", snappedf(master, 0.01))
	cfg.set_value("sound", "music", snappedf(music, 0.01))
	cfg.set_value("sound", "effects", snappedf(effects, 0.01))
	cfg.set_value("debug", "perf", perf)
	cfg.set_value("display", "fps", fps)
	cfg.set_value("display", "style", style)
	cfg.set_value("display", "grade", grade)
	cfg.set_value("display", "view", view)
	cfg.set_value("display", "pitch", pitch)
	cfg.set_value("display", "camera_view", camera_view)
	cfg.set_value("debug", "promo", promo)
	cfg.set_value("debug", "test_device", test_device)
	cfg.set_value("debug", "promo_shots", promo_shots)
	cfg.set_value("game", "zone_cap", zone_cap)
	cfg.set_value("game", "handling", handling)
	cfg.set_value("game", "character", snappedf(character, 0.05))
	cfg.set_value("game", "lane_assist", lane_assist)
	cfg.set_value("game", "lane_assist_default", 1)
	cfg.set_value("game", "collide_default", 1)
	cfg.set_value("world", "chatter", chatter)
	cfg.set_value("game", "collide", collide)
	cfg.set_value("game", "soft_fences", soft_fences)
	cfg.set_value("game", "stats", stats)
	cfg.set_value("access", "text_large", text_large)
	cfg.set_value("access", "calm", calm)
	cfg.set_value("access", "color_safe", color_safe)
	cfg.set_value("access", "vibration", vibration)
	cfg.set_value("access", "stop_assist", stop_assist)
	cfg.set_value("access", "left_handed", left_handed)
	if lang != "":
		cfg.set_value("game", "lang", lang)
	for key in auto_image:
		cfg.set_value("auto_image", key, auto_image[key])
	SafeFile.write(cfg, path)  # TD-8: a temp file, then one rename, never half a file


func summary() -> String:
	return "controls %d pads %d, classic camera %s, traffic %s, quality %s, volume %.0f/%.0f/%.0f %%, perf %s, %d fps, style %d, camera view %d, zone cap %s, handling %d character %.2f lane %s chatter %d, collide %d soft fences %s stats %s, access large %s calm %s colour-safe %s vibration %s assist %s left-handed %s, auto image %s" % [
			controls, pads, "follow" if classic_follow else "fixed", TRAFFIC_NAMES[traffic], "auto" if quality == AUTO else str(quality),
			master * 100.0, music * 100.0, effects * 100.0, perf, fps, style, camera_view, zone_cap, handling, character, lane_assist, chatter, collide, soft_fences, stats, text_large, calm, color_safe, vibration, stop_assist, left_handed, image_summary()]


## Loop G1b: "sharp", "sharp, on trial 1/4" or "fallback, calm 1/2 (GPU extras down 74 s)".
func image_summary() -> String:
	var s := auto_image
	if s["fallback"]:
		return "fallback, calm %d/%d (%s)" % [s["calm"], s["wait"], s["why"]]
	if int(s["trial"]) >= 0:
		return "sharp, on trial %d/%d" % [s["trial"], s["wait"]]
	return "sharp"


static func parse_traffic(v: String) -> int:
	var k := TRAFFIC_KEYS.find(v.to_lower())
	return k if k >= 0 else clampi(int(v), 0, TRAFFIC.size() - 1)


## H1: a save from before the slider (handling 0 Cruise, 1 Sport, 2 Grounded; sensitivity 0..1, 0.5
## as is) as „Charakter jazdy": Sport is the slider's right end; Cruise was the default nobody chose
## (the modes sat on the DEV page), so it starts at the new default; Grounded keeps the default under
## Realnie. A moved sensitivity shifts the slider by half its offset.
static func migrate_character(old_handling: int, old_sensitivity: float) -> float:
	var c := 1.0 if old_handling == 1 else CHARACTER_DEFAULT
	return clampf(snappedf(c + (clampf(old_sensitivity, 0.0, 1.0) - 0.5) * 0.5, 0.05), 0.0, 1.0)
