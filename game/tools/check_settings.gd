extends SceneTree
## Loop 2a: settings.gd round trip. Saves every setting to a scratch file in user://, loads
## it into a fresh copy and compares; a missing file gives the defaults (Classic since 2026-11-04, Low
## traffic, High, full volumes, overlay off, 60 fps; loop 2e: Classic's camera following, the
## Sharp style, no VHS; loop G1: quality Auto instead of High); with persistent = false (--nosave)
## nothing is written. Loop G1: a file saved before G1 (no `tiers` key) that says High loads as
## Auto, once (a file saved since keeps High, Medium stays Medium, Ultra round-trips). Loop G1b:
## Auto's image state (`[auto_image]`) round-trips, a file without it starts sharp, hand-edited
## values are cleaned, and --nosave writes none of it either. F's asks (2026-10-30): the
## pedestrian zones' cap (`zone_cap`) is off in a missing file and round-trips on. F (2026-11-07): the closest zoom (40 m) and
## the camera angle (`pitch`) round-trip; an angle that isn't a choice loads as 30°. The real
## user://settings.cfg is never touched. Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_settings.gd

const Settings := preload("res://scripts/settings.gd")
const Tiers := preload("res://scripts/tiers.gd")
const SCRATCH := "user://settings_check.cfg"
const SCRATCH_OFF := "user://settings_check_nosave.cfg"
const SCRATCH_OLD := "user://settings_check_old.cfg"


func _initialize() -> void:
	var ok := true
	var fresh := Settings.new()
	fresh.path = "user://settings_check_missing.cfg"
	fresh.load_file()
	var defaults := fresh.controls == 1 and fresh.traffic == Settings.DEFAULT_TRAFFIC and fresh.quality == Settings.AUTO \
			and fresh.master == 1.0 and fresh.music == 1.0 and fresh.effects == 1.0 and not fresh.perf and fresh.classic_follow \
			and fresh.fps == 60 and fresh.style == 0 and not fresh.vhs and not fresh.zone_cap and fresh.handling == 0 and is_equal_approx(fresh.sensitivity, 0.5) \
			and not fresh.text_large and not fresh.calm and not fresh.color_safe and fresh.vibration and fresh.stop_assist \
			and not fresh.left_handed and not fresh.lane_assist and fresh.view == 80.0 and fresh.pitch == 30.0
	print("defaults from a missing file: %s (%s)" % ["OK" if defaults else "WRONG", fresh.summary()])
	ok = ok and defaults

	# Loop G1: the quality saved before G1 (a file without the `tiers` key, as loop 2a wrote it).
	var cases := [[2, false, Settings.AUTO], [1, false, 1], [0, false, 0], [2, true, 2], [Settings.ULTRA, true, Settings.ULTRA],
			[Settings.AUTO, true, Settings.AUTO]]
	var migrated := true
	for c in cases:
		var cfg := ConfigFile.new()
		cfg.set_value("world", "quality", c[0])
		if c[1]:
			cfg.set_value("world", "tiers", 1)
		cfg.save(SCRATCH_OLD)
		var s := Settings.new()
		s.path = SCRATCH_OLD
		s.load_file()
		if s.quality != c[2]:
			migrated = false
			print("  quality %d saved %s G1 loads as %d, wanted %d" % [c[0], "after" if c[1] else "before", s.quality, c[2]])
	# Once: loaded as Auto and saved, it stays Auto; a High chosen after that stays High.
	var once := Settings.new()
	once.path = SCRATCH_OLD
	var cfg_old := ConfigFile.new()
	cfg_old.set_value("world", "quality", 2)
	cfg_old.save(SCRATCH_OLD)
	once.load_file()
	once.save()
	once.quality = 2
	once.save()
	var again := Settings.new()
	again.path = SCRATCH_OLD
	again.load_file()
	migrated = migrated and again.quality == 2
	print("quality saved before loop G1: %s (High → Auto once, the rest kept, High chosen since kept: %d)" % [
			"OK" if migrated else "WRONG", again.quality])
	ok = ok and migrated

	# 2026-11-04: Classic became the default; a file saved before (no `classic_default` key) that
	# says Point loads as Classic once, Fixed stays Fixed, and a Point chosen since stays Point.
	var ctl_ok := true
	for c in [[0, false, 1], [2, false, 2], [1, false, 1], [0, true, 0]]:
		var cfg_c := ConfigFile.new()
		cfg_c.set_value("controls", "scheme", c[0])
		if c[1]:
			cfg_c.set_value("controls", "classic_default", 1)
		cfg_c.save(SCRATCH_OLD)
		var sc := Settings.new()
		sc.path = SCRATCH_OLD
		sc.load_file()
		if sc.controls != c[2]:
			ctl_ok = false
			print("  controls %d saved %s 2026-11-04 load as %d, wanted %d" % [c[0], "after" if c[1] else "before", sc.controls, c[2]])
	var pick := Settings.new()
	pick.path = SCRATCH_OLD
	pick.load_file()
	pick.controls = 0
	pick.save()
	var pick_back := Settings.new()
	pick_back.path = SCRATCH_OLD
	pick_back.load_file()
	ctl_ok = ctl_ok and pick_back.controls == 0
	print("controls saved before Classic became the default: %s (Point → Classic once, Point chosen since kept: %d)" % [
			"OK" if ctl_ok else "WRONG", pick_back.controls])
	ok = ok and ctl_ok

	var a := Settings.new()
	a.path = SCRATCH
	a.controls = 2
	a.classic_follow = false
	a.traffic = 0
	a.quality = 1
	a.master = 0.7
	a.music = 0.35
	a.effects = 0.0
	a.perf = true
	a.fps = 30
	a.style = 3
	a.vhs = true
	a.zone_cap = true
	a.handling = 1
	a.sensitivity = 0.8
	a.text_large = true
	a.calm = true
	a.color_safe = true
	a.vibration = false
	a.stop_assist = false
	a.left_handed = true
	a.lane_assist = true
	a.view = 40.0
	a.pitch = 50.0
	a.save()
	var b := Settings.new()
	b.path = SCRATCH
	b.load_file()
	var same := a.summary() == b.summary() and b.classic_follow == a.classic_follow and b.view == 40.0 and b.pitch == 50.0
	# F (2026-11-07): a hand-edited angle that isn't one of the choices loads as the default.
	var cfg_p := ConfigFile.new()
	cfg_p.set_value("display", "pitch", 33.0)
	cfg_p.set_value("display", "view", 10.0)
	cfg_p.save(SCRATCH_OLD)
	var sp := Settings.new()
	sp.path = SCRATCH_OLD
	sp.load_file()
	var angle_ok := sp.pitch == 30.0 and sp.view == 40.0
	print("camera angle and zoom from a hand-edited file: %s (%.0f°, %.0f m)" % ["OK" if angle_ok else "WRONG", sp.pitch, sp.view])
	ok = ok and angle_ok
	print("round trip: %s\n  saved  %s\n  loaded %s" % ["OK" if same else "DIFFERENT", a.summary(), b.summary()])
	ok = ok and same

	# Loop G1b: Auto's image state round-trips; a file without it (from before G1b) or with
	# hand-edited values starts sharp / is cleaned.
	var img := Settings.new()
	img.path = SCRATCH
	img.auto_image = {"fallback": true, "calm": 1, "wait": 4, "trial": -1, "why": "GPU extras down 74 s of 410", "told": false}
	img.save()
	var img_back := Settings.new()
	img_back.path = SCRATCH
	img_back.load_file()
	var cfg_pre := ConfigFile.new()
	cfg_pre.set_value("world", "quality", -1)
	cfg_pre.set_value("world", "tiers", 1)
	cfg_pre.save(SCRATCH_OLD)
	var pre := Settings.new()
	pre.path = SCRATCH_OLD
	pre.load_file()
	var cfg_odd := ConfigFile.new()
	cfg_odd.set_value("auto_image", "fallback", true)
	cfg_odd.set_value("auto_image", "wait", 500)
	cfg_odd.set_value("auto_image", "calm", -2)
	cfg_odd.save(SCRATCH_OLD)
	var odd := Settings.new()
	odd.path = SCRATCH_OLD
	odd.load_file()
	var image_ok: bool = img_back.auto_image == img.auto_image and pre.auto_image == Tiers.sharp_state() \
			and odd.auto_image["fallback"] and int(odd.auto_image["wait"]) == Tiers.SHARP_WAIT_MAX and int(odd.auto_image["calm"]) == 0
	print("Auto's image state: %s (round trip: %s; a file from before G1b: %s; hand-edited: %s)" % ["OK" if image_ok else "WRONG",
			img_back.image_summary(), pre.image_summary(), odd.image_summary()])
	ok = ok and image_ok

	var off := Settings.new()
	off.path = SCRATCH_OFF
	off.persistent = false
	off.traffic = 3
	off.auto_image = Tiers.sharp_struggled(Tiers.sharp_state(), true, "nosave")
	off.save()
	var wrote := FileAccess.file_exists(SCRATCH_OFF)
	print("--nosave writes nothing: %s" % ("OK" if not wrote else "WROTE A FILE"))
	ok = ok and not wrote

	for f in [SCRATCH, SCRATCH_OFF, SCRATCH_OLD]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	ok = _check_tint() and ok
	ok = _check_beacons() and ok
	print("settings: %s" % ("OK" if ok else "PROBLEM"))
	quit(0 if ok else 1)


## Colour-safe (access.gd `tint`): off, every colour as it is; on, the game's success green and fail
## red (every script's constant for them) turn blue and vermilion, and other colours stay.
func _check_tint() -> bool:
	var A := preload("res://scripts/access.gd")
	var greens := [A.GREEN, load("res://scripts/missions.gd").DROPOFF_COLOUR, load("res://scripts/rivals.gd").WIN_COLOUR]
	var reds := [A.RED, load("res://scripts/missions.gd").FAIL_COLOUR, load("res://scripts/rivals.gd").LOSE_COLOUR,
			load("res://scripts/jobs.gd").FAIL_COLOUR, load("res://scripts/rides.gd").FAIL_COLOUR,
			load("res://scripts/roundup_job.gd").FAIL_COLOUR, load("res://scripts/trend_job.gd").FAIL_COLOUR]
	var others := [Color("#ffd23f"), Color("#ff8a3d"), Color("#4fd8c4"), Color("#ff4fd8"), Color.WHITE]
	var good := true
	var was: bool = A.color_safe
	A.color_safe = false
	for c in greens + reds + others:
		good = good and A.tint(c) == c
	A.color_safe = true
	for c in greens:
		good = good and A.tint(c) == A.GREEN_SAFE
	for c in reds:
		good = good and A.tint(c) == A.RED_SAFE
	for c in others:
		good = good and A.tint(c) == c
	var faded := Color(A.GREEN, 0.5)
	good = good and is_equal_approx(A.tint(faded).a, 0.5) and A.tint(faded).b > 0.9
	A.color_safe = was
	print("colour-safe tint: %s (%d greens -> blue, %d reds -> vermilion, %d others kept)" % ["OK" if good else "WRONG",
			greens.size(), reds.size(), others.size()])
	return good


## Colour-safe's 3D markers (beacon.gd): off, every ring is a full ring in its own colour; on, the
## drop-off's green turns blue, the rescue pickup's ring is dashed and the race ring chequered
## (white blocks between coloured ones), so the race and rescue rings differ by more than hue;
## switching the setting mid-call re-draws a placed beacon without a restart.
func _check_beacons() -> bool:
	var A := preload("res://scripts/access.gd")
	var B := preload("res://scripts/beacon.gd")
	var M := load("res://scripts/missions.gd")
	var R := load("res://scripts/rivals.gd")
	var was: bool = A.color_safe
	var kinds := [[M.PICKUP_COLOUR, B.Pattern.DASHED], [M.DROPOFF_COLOUR, B.Pattern.SOLID], [R.RACE_COLOUR, B.Pattern.CHEQUER]]
	var beacons := []
	for k in kinds:
		var b: Node3D = B.new()
		b.setup(k[0], Color.WHITE)
		b.pattern = k[1]
		# place()'s part without the tree (it sets a global position): a 9 m ring, shown.
		b._ring_radius = 9.0
		b._refresh()
		b.visible = true
		beacons.append(b)
	var good := true
	var notes := PackedStringArray()
	for safe in [false, true]:
		A.color_safe = safe
		for i in beacons.size():
			var b: Node3D = beacons[i]
			b._process(0.016)  # notices the switch by itself, like a frame would
			var st := _ring_stats(b.ring_mesh())
			var want_col: Color = A.tint(kinds[i][0])
			var shape: int = kinds[i][1] if safe else B.Pattern.SOLID
			var fine: bool = b.shown_colour() == want_col and st["coloured"] > 0
			match shape:
				B.Pattern.SOLID:
					fine = fine and st["quads"] == 32 and st["white"] == 0
				B.Pattern.DASHED:
					fine = fine and st["quads"] == B.DASHES and st["white"] == 0
				B.Pattern.CHEQUER:
					fine = fine and st["white"] > 0 and st["white"] == st["coloured"]
			if not fine:
				notes.append("%s %s: %s" % ["safe" if safe else "off", B.Pattern.keys()[kinds[i][1]], str(st)])
			good = good and fine
	good = good and beacons[1].shown_colour() == A.GREEN_SAFE  # the drop-off, still on
	A.color_safe = was
	for b in beacons:
		b.free()
	print("colour-safe beacons: %s (rescue pickup dashed, race chequered, drop-off blue, live switch)%s" % [
			"OK" if good else "WRONG", "" if notes.is_empty() else "\n  " + "\n  ".join(notes)])
	return good


## Quads in a ring mesh, and how many are white (the chequer's) or coloured.
func _ring_stats(mesh: ArrayMesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var out := {"quads": cols.size() / 6, "white": 0, "coloured": 0}
	for q in cols.size() / 6:
		var c: Color = cols[q * 6]
		if c.r > 0.9 and c.g > 0.9 and c.b > 0.9:
			out["white"] += 1
		else:
			out["coloured"] += 1
	return out
