extends RefCounted
## Loop 2a: the player's settings, kept between sessions in user://settings.cfg (a
## ConfigFile beside the wallet's save.cfg, which wallet.gd rewrites whole): the control
## scheme and (for Classic) the camera, the traffic level, quality, three volumes and the
## performance overlay; loop 2b: the frame rate (60, or 30 to save the battery); loop 2e: the
## picture style and the VHS tape (they moved off the driving screen into Settings; the time of
## day and the rain are the world's state and start by day and dry). `--nosave` neither reads
## nor writes it; command-line flags (`--controls= --traffic= --quality= --fixed --perf
## --style= --vhs`) win for that run and are not saved unless the player then changes the setting.
## Loop G1b: Auto's sharp image and its fallback (`[auto_image]`, tiers.gd SHARP_*), written only
## by a normal launch's own sessions (main.gd: never by --nosave, test runs, benches or
## --last-session=); a file without it (from before G1b) starts sharp.
## Loop 3h slice 1 (save v2): the file carries `[meta] version` (VERSION, 2); a file without it is
## version 1 and loads as before (loop G1's High → Auto rule is that migration); the next save
## writes version 2. A file from a newer version is read and never overwritten.

const FollowCamera := preload("res://scripts/follow_camera.gd")
const Tiers := preload("res://scripts/tiers.gd")
const PATH := "user://settings.cfg"
## Loop 3h slice 1: the settings file's format version (1: before loop 3h, no `[meta]`).
const VERSION := 2
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

## drive_controls.gd: POINT, CLASSIC, FIXED. Classic (steer left / right, GAS and BRAKE) is the
## default since 2026-11-04 (F: "driving with left, right, gas and brake should be the default");
## Point and Fixed stay in Settings → Jazda.
const DEFAULT_CONTROLS := 1
var controls := DEFAULT_CONTROLS
## Classic only: the camera follows the car (CAM toggles it); Point always follows, Fixed never.
var classic_follow := true
var traffic := DEFAULT_TRAFFIC
## tiers.gd: AUTO (-1, the default since loop G1: the level Auto picks for the device) or
## Low, Medium, High, Ultra (0-3). A file saved before G1 (no `tiers` key) that says High
## loads as Auto, once: High was the default then, not a choice; the next save marks the file.
const AUTO := -1
const HIGH := 2
const ULTRA := 3
var quality := AUTO
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
## (follow_camera.gd VIEWS; 80 is DEFAULT_SIZE).
var view := 80.0
## F, 2026-11-07: the camera's angle over the ground in degrees (follow_camera.gd PITCHES; 30, the
## game's look, is the default). Settings → Obraz, key "angle".
var pitch := FollowCamera.DEFAULT_PITCH
## Loop 2e: main.gd STYLES (Sharp, Fine, Clean, Chunky) and the VHS overlay.
var style := 0
var vhs := false
## Loop MW-6 (vision 4.3, Open Question 7): the game's mode, Miasto (0, jobs and calls come by
## themselves; the default) or Spacer (1, wander: nothing comes by itself, hints to the notebook's
## places), and whether Spacer has been offered once (after the first pause).
var wander := false
var wander_offered := false
## F's asks (2026-10-30): the pedestrian zones' 20 km/h cap (ped_zones.gd, loop 3d-1) and its
## pill, off by default (driving made easier); Settings → JAZDA turns it on. The guards stand in
## the zones either way, and the footway clamp is not part of it.
var zone_cap := false
## G4: car.gd Handling (0 Cruise, the default; 1 Sport, the loop 2a feel). Settings → Jazda, key "handling".
var handling := 0
## Steering sensitivity 0..1 (0.5 = the profile as is; car.gd set_sensitivity). Settings → Jazda, key "sensitivity".
var sensitivity := 0.5
## Beta values (2026-11-04): the lane assist (lane_assist.gd), Classic only. Settings → Jazda, key
## "lane_assist"; off by default until F has felt it on the phone (QUESTIONS, A/B 10).
var lane_assist := false
## Phase 0.2 (docs/GAMEPLAY_PLAN.md): the city's chattiness, chatter.gd GAPS: 0 Mało, 1 Średnio (the
## default), 2 Dużo. Settings → ŚWIAT, key "chatter".
var chatter := 1
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
	# 2026-11-04: Point was the default before, so a file saved then (no `classic_default` key)
	# that says Point loads as Classic, once; the next save marks the file, and a Point chosen
	# after that stays Point.
	if controls == 0 and not cfg.has_section_key("controls", "classic_default"):
		controls = DEFAULT_CONTROLS
	classic_follow = bool(cfg.get_value("controls", "classic_follow", classic_follow))
	traffic = clampi(int(cfg.get_value("world", "traffic", traffic)), 0, TRAFFIC.size() - 1)
	quality = clampi(int(cfg.get_value("world", "quality", quality)), AUTO, ULTRA)
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
	vhs = bool(cfg.get_value("display", "vhs", vhs))
	view = clampf(float(cfg.get_value("display", "view", view)), FollowCamera.VIEWS[0], FollowCamera.VIEWS[-1])
	pitch = float(cfg.get_value("display", "pitch", pitch))
	if not pitch in FollowCamera.PITCHES:
		pitch = FollowCamera.DEFAULT_PITCH
	wander = bool(cfg.get_value("game", "wander", wander))
	wander_offered = bool(cfg.get_value("game", "wander_offered", wander_offered))
	zone_cap = bool(cfg.get_value("game", "zone_cap", zone_cap))
	handling = clampi(int(cfg.get_value("game", "handling", handling)), 0, 1)
	sensitivity = clampf(float(cfg.get_value("game", "sensitivity", sensitivity)), 0.0, 1.0)
	lane_assist = bool(cfg.get_value("game", "lane_assist", lane_assist))
	chatter = clampi(int(cfg.get_value("world", "chatter", chatter)), 0, 2)
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
	cfg.set_value("controls", "classic_default", 1)
	cfg.set_value("world", "traffic", traffic)
	cfg.set_value("world", "quality", quality)
	cfg.set_value("world", "tiers", 1)
	cfg.set_value("sound", "master", snappedf(master, 0.01))
	cfg.set_value("sound", "music", snappedf(music, 0.01))
	cfg.set_value("sound", "effects", snappedf(effects, 0.01))
	cfg.set_value("debug", "perf", perf)
	cfg.set_value("display", "fps", fps)
	cfg.set_value("display", "style", style)
	cfg.set_value("display", "vhs", vhs)
	cfg.set_value("display", "view", view)
	cfg.set_value("display", "pitch", pitch)
	cfg.set_value("game", "wander", wander)
	cfg.set_value("game", "wander_offered", wander_offered)
	cfg.set_value("game", "zone_cap", zone_cap)
	cfg.set_value("game", "handling", handling)
	cfg.set_value("game", "sensitivity", snappedf(sensitivity, 0.05))
	cfg.set_value("game", "lane_assist", lane_assist)
	cfg.set_value("world", "chatter", chatter)
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
	cfg.save(path)


func summary() -> String:
	return "controls %d, classic camera %s, traffic %s, quality %s, volume %.0f/%.0f/%.0f %%, perf %s, %d fps, style %d, vhs %s, zone cap %s, handling %d sens %.2f lane %s chatter %d, access large %s calm %s colour-safe %s vibration %s assist %s left-handed %s, auto image %s" % [
			controls, "follow" if classic_follow else "fixed", TRAFFIC_NAMES[traffic], "auto" if quality == AUTO else str(quality),
			master * 100.0, music * 100.0, effects * 100.0, perf, fps, style, vhs, zone_cap, handling, sensitivity, lane_assist, chatter, text_large, calm, color_safe, vibration, stop_assist, left_handed, image_summary()]


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
