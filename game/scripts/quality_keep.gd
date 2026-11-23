extends RefCounted
## Perf thread (F 2026-11-19, "remove the switch to lower graphics from Experimental"): a quality
## level the player picked by hand is kept, and Experimental is remembered like any level.
##
## - The governor acts only for Auto (main.gd `_govern` holds it on a manual level). On a manual
##   level it only counts: after HEAVY_AFTER seconds of play with over HEAVY_SHARE of the refreshes
##   missed (not flying, not in a wide view, not under the title or the opening: a stall of a
##   second can't add up to a minute), the game says once a session that the level is heavy here.
## - The guard: a launch at Experimental marks the save (settings.gd `quality_pending`) and clears
##   the mark after PENDING_CLEAR_S of frames; a launch that finds the mark (the last one never got
##   going: a crash on the 8192 shadow map) loads Ultra once (settings.gd `quality_guarded`).
## - The overrides of --gfx= (tiers.gd `value`) are named once in the log.
## Main is read untyped (`m`), as dev_harness.gd does, so this script needs nothing of its type.

const Tiers := preload("res://scripts/tiers.gd")

## Perf thread (2026-11-23): 0.25, not 0.1: at 0.1 a phone at 55 fps (the Samsung A56 at High) read
## as heavy all the time and Auto stepped it down; a quarter of the refreshes missed is about 45 fps.
const HEAVY_SHARE := 0.25
const HEAVY_AFTER := 60.0
const PENDING_CLEAR_S := 10.0

var _heavy_s := 0.0
var _heavy_said := false
## Perf thread (2026-11-23, PostHog: a Motorola edge 40 sat at 27 fps on Auto's High): Auto's level
## steps down one after a session that struggled (over STRUGGLE_SHARE of AUTO_TALLY seconds of
## play with over HEAVY_SHARE of the refreshes missed, CPU or GPU alike), and back up one after
## DROP_CALM calm sessions; settings.gd `auto_drop` and `auto_calm`, read at the next launch.
const AUTO_TALLY := 180.0
const STRUGGLE_SHARE := 0.25
const DROP_CALM := 3
var _auto_s := 0.0
var _auto_heavy := 0.0
var _auto_done := false
var _clear_at := -1.0
var _gfx_said := false


## The launch: the guard's note, and the mark when this launch is at Experimental.
func launch(m: Object) -> void:
	if m.settings.quality_guarded:
		print("quality: the last launch at Experimental never got going · Ultra this time (settings.gd quality_pending)")
	_arm(m)


## Auto's level for this launch: the device's (`base`), less the steps the last sessions earned.
func auto_level(m: Object, base: int) -> int:
	var level := maxi(Tiers.LOW, base - int(m.settings.auto_drop))
	if level != base:
		print("quality: Auto steps %s down to %s (%d struggling session%s ago, %d of %d calm since)" % [
				Tiers.NAMES[base], Tiers.NAMES[level], m.settings.auto_drop, "" if m.settings.auto_drop == 1 else "s",
				m.settings.auto_calm, DROP_CALM])
	return level


## The session's verdict on Auto's level, once AUTO_TALLY seconds are counted.
func _auto_verdict(m: Object) -> void:
	_auto_done = true
	var struggled := _auto_heavy > _auto_s * STRUGGLE_SHARE
	var s: Object = m.settings
	if struggled and m.quality > Tiers.LOW:
		s.auto_drop = mini(int(s.auto_drop) + 1, 3)
		s.auto_calm = 0
	elif not struggled:
		s.auto_calm = int(s.auto_calm) + 1
		if int(s.auto_calm) >= DROP_CALM and int(s.auto_drop) > 0:
			s.auto_drop = int(s.auto_drop) - 1
			s.auto_calm = 0
	if s.persistent:
		s.save()
	print("quality: Auto at %s %s (%.0f of %.0f s heavy) · the next launch steps down %d" % [Tiers.NAMES[m.quality],
			"struggled" if struggled else "was calm", _auto_heavy, _auto_s, s.auto_drop])


## The player picked a level (main.gd `_set_quality`, after the start): saved, Experimental too.
func chosen(m: Object) -> void:
	m.settings.quality = m.quality_choice
	m.settings.save()
	_arm(m)
	_heavy_s = 0.0
	_heavy_said = false


## Once a quality is applied: the overrides line, once.
func applied() -> void:
	if not Tiers.overrides.is_empty() and not _gfx_said:
		_gfx_said = true
		print("quality: per-option overrides %s" % Tiers.overrides)


## Once a frame, from main.gd `_govern`: the guard's clearing and the heavy level's one note.
func frame(m: Object, dt: float) -> void:
	if _clear_at >= 0.0 and m._clock_s() >= _clear_at:
		_clear_at = -1.0
		m.settings.quality_pending = false
		m.settings.save()
	if m._wide or m.flying or m.title != null or m._opening_on:
		return
	if m.quality_choice == Tiers.AUTO:
		if not _auto_done:
			_auto_s += dt
			if float(m.governor.late_share) > HEAVY_SHARE:
				_auto_heavy += dt
			if _auto_s >= AUTO_TALLY:
				_auto_verdict(m)
		return
	if _heavy_said:
		return
	if float(m.governor.late_share) <= HEAVY_SHARE:
		return
	_heavy_s += dt
	if _heavy_s < HEAVY_AFTER:
		return
	_heavy_said = true
	var fps := roundi(Engine.get_frames_per_second())
	var level: String = Tiers.NAMES[m.quality]
	print("quality: %s is heavy here (%.0f%% of refreshes missed, %d fps) · kept, the player was told once" % [
			level, float(m.governor.late_share) * 100.0, fps])
	if m.hud != null:
		m.hud.toast("Jakość %s jest ciężka dla tego urządzenia (%d kl./s)" % [level, fps],
				"%s is heavy on this device (%d fps) · Settings → Obraz" % [level, fps])


func _arm(m: Object) -> void:
	if m.settings.quality == Tiers.EXPERIMENTAL and m.settings.persistent:
		m.settings.quality_pending = true
		m.settings.save()
		_clear_at = m._clock_s() + PENDING_CLEAR_S
