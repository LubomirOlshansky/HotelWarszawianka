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

const HEAVY_SHARE := 0.1
const HEAVY_AFTER := 60.0
const PENDING_CLEAR_S := 10.0

var _heavy_s := 0.0
var _heavy_said := false
var _clear_at := -1.0
var _gfx_said := false


## The launch: the guard's note, and the mark when this launch is at Experimental.
func launch(m: Object) -> void:
	if m.settings.quality_guarded:
		print("quality: the last launch at Experimental never got going · Ultra this time (settings.gd quality_pending)")
	_arm(m)


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
	if _heavy_said or m.quality_choice == Tiers.AUTO or m._wide or m.flying or m.title != null or m._opening_on:
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
