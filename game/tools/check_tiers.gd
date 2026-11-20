extends SceneTree
## Loop G1: the device tiers and the pixel image's size (scripts/tiers.gd, what the game uses).
##   - every model id in MODELS gets its tier (docs/design/graphics.md 4.1; unknown → High);
##   - the image at the three phone sizes the loop was measured on (the iPhone 11's 1792x828, the
##     6.1" 2532x1170, the Pro Max's 2868x1320) and the SE's 1334x750, at each level and style:
##     whole-pixel scaling, inside the level's budget, the sizes in IMAGES;
##   - nothing else moved: every size, style and level gives loop 2b's scale (the style's lines,
##     Low and Medium one step coarser) except High at a scale of 1 over High's budget;
##   - Auto on the two phones: the iPhone 11 High at 896x414, the Pro Max Ultra at 1434x660 (the
##     levels' own images: what the manual levels and Auto's fallback draw).
## Loop G1b, Auto's sharp image and its fallback:
##   - which phones' screens the budget binds on at the level Auto picks for them, per style
##     (SCREENS: every iPhone id with its screen): only High with Sharp on the iPhone 11 and the
##     SE 2 / 3 (BINDS), and some Mac windows; there Auto's sharp scale is the style's own
##     (1792x828, 1334x750) and its fallback the budget's (896x414, 667x375); elsewhere Auto's
##     two scales are the same; manual levels are G1's (Wysoka ×2 on the iPhone 11, Ultra ×1);
##   - the back-off on scripted launches: a struggle at the sharp image falls back from the next
##     launch, 2 calm sessions at the fallback bring the sharp image back on trial, a struggle on
##     trial doubles the wait (2, 4, 8, 16, then 16), a passed trial (wait calm sessions) puts it
##     back to 2, a struggle at the fallback starts its count again, short sessions change
##     nothing, a calm verdict then a struggle in one session is the struggle; a phone that can't
##     hold the sharp image spends at most 1 launch in 17 on it after the wait is capped;
##   - the state from an old, empty or hand-edited file is cleaned (no fallback, the wait 2..16);
##   - the bench card's and log's quality text (describe);
## Mac step 1 (mac_mode.gd): the iPhone app on a Mac is told from a phone, an iPad and native
## macOS; there Auto is Ultra (High on a base M1 / M2), every level below Experimental draws x2
## (Low / Medium x3) inside 2 MP, High and up with MSAA 4x; an override still wins; the keys
## that hide the touch pads and the presses that bring them back.
## Prints `check_tiers: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_tiers.gd

const Tiers := preload("res://scripts/tiers.gd")
const MacMode := preload("res://scripts/mac_mode.gd")

## Model id -> the level Auto picks.
const MODELS := {
	"iPhone10,1": Tiers.LOW, "iPhone10,3": Tiers.LOW, "iPhone10,6": Tiers.LOW,
	"iPhone11,2": Tiers.MEDIUM, "iPhone11,6": Tiers.MEDIUM, "iPhone11,8": Tiers.MEDIUM,
	"iPhone12,1": Tiers.HIGH, "iPhone12,3": Tiers.HIGH, "iPhone12,5": Tiers.HIGH, "iPhone12,8": Tiers.HIGH,
	"iPhone13,2": Tiers.HIGH, "iPhone14,5": Tiers.HIGH, "iPhone14,6": Tiers.HIGH, "iPhone14,7": Tiers.HIGH,
	"iPhone15,2": Tiers.HIGH, "iPhone15,4": Tiers.HIGH, "iPhone15,5": Tiers.HIGH,
	"iPhone16,1": Tiers.ULTRA, "iPhone16,2": Tiers.ULTRA,
	"iPhone17,1": Tiers.ULTRA, "iPhone17,2": Tiers.ULTRA, "iPhone17,3": Tiers.ULTRA, "iPhone17,4": Tiers.ULTRA,
	"iPhone17,5": Tiers.HIGH,
	"iPhone18,1": Tiers.ULTRA, "iPhone18,3": Tiers.ULTRA, "iPhone19,4": Tiers.ULTRA,
	"iPad13,1": Tiers.HIGH, "iPad16,3": Tiers.HIGH, "Mac16,7": Tiers.HIGH, "MacBookPro18,3": Tiers.HIGH,
	"arm64": Tiers.HIGH, "x86_64": Tiers.HIGH, "GenericDevice": Tiers.HIGH, "": Tiers.HIGH,
	"iPhone": Tiers.HIGH, "iPhone12": Tiers.HIGH, "iPhoneX,1": Tiers.HIGH,
}
## Screen -> the Sharp image at Low, Medium, High, Ultra, Max (perf thread, F 2026-11-20: Ultra and Max
## keep High's budget, x2 on every phone; the Image switch's Full is the screen's own pixels).
const IMAGES := {
	Vector2i(1792, 828): [Vector2i(896, 414), Vector2i(896, 414), Vector2i(896, 414), Vector2i(896, 414), Vector2i(896, 414)],
	Vector2i(2532, 1170): [Vector2i(844, 390), Vector2i(844, 390), Vector2i(1266, 585), Vector2i(1266, 585), Vector2i(1266, 585)],
	Vector2i(2868, 1320): [Vector2i(956, 440), Vector2i(956, 440), Vector2i(1434, 660), Vector2i(1434, 660), Vector2i(1434, 660)],
	Vector2i(1334, 750): [Vector2i(667, 375), Vector2i(667, 375), Vector2i(667, 375), Vector2i(667, 375), Vector2i(667, 375)],
}
## main.gd STYLES' lines: Sharp, Fine, Clean, Chunky.
const LINES := [480.0, 360.0, 240.0, 170.0]
## Loop G1b: every iPhone id the game can meet and its screen (landscape pixels).
const SCREENS := {
	"iPhone10,1": Vector2i(1334, 750), "iPhone10,2": Vector2i(1920, 1080), "iPhone10,3": Vector2i(2436, 1125),
	"iPhone10,4": Vector2i(1334, 750), "iPhone10,5": Vector2i(1920, 1080), "iPhone10,6": Vector2i(2436, 1125),
	"iPhone11,2": Vector2i(2436, 1125), "iPhone11,4": Vector2i(2688, 1242), "iPhone11,6": Vector2i(2688, 1242),
	"iPhone11,8": Vector2i(1792, 828),
	"iPhone12,1": Vector2i(1792, 828), "iPhone12,3": Vector2i(2436, 1125), "iPhone12,5": Vector2i(2688, 1242),
	"iPhone12,8": Vector2i(1334, 750),
	"iPhone13,1": Vector2i(2340, 1080), "iPhone13,2": Vector2i(2532, 1170), "iPhone13,3": Vector2i(2532, 1170),
	"iPhone13,4": Vector2i(2778, 1284),
	"iPhone14,2": Vector2i(2532, 1170), "iPhone14,3": Vector2i(2778, 1284), "iPhone14,4": Vector2i(2340, 1080),
	"iPhone14,5": Vector2i(2532, 1170), "iPhone14,6": Vector2i(1334, 750), "iPhone14,7": Vector2i(2532, 1170),
	"iPhone14,8": Vector2i(2778, 1284),
	"iPhone15,2": Vector2i(2556, 1179), "iPhone15,3": Vector2i(2796, 1290), "iPhone15,4": Vector2i(2556, 1179),
	"iPhone15,5": Vector2i(2796, 1290),
	"iPhone16,1": Vector2i(2556, 1179), "iPhone16,2": Vector2i(2796, 1290),
	"iPhone17,1": Vector2i(2622, 1206), "iPhone17,2": Vector2i(2868, 1320), "iPhone17,3": Vector2i(2556, 1179),
	"iPhone17,4": Vector2i(2796, 1290), "iPhone17,5": Vector2i(2532, 1170),
	"iPhone18,1": Vector2i(2622, 1206), "iPhone18,2": Vector2i(2868, 1320), "iPhone18,3": Vector2i(2622, 1206),
	"iPhone18,4": Vector2i(2736, 1260),
}
## Loop G1b: the ids whose Auto level's budget binds (with Sharp only): the iPhone 11 and the SE 2 / 3.
const BINDS := ["iPhone12,1", "iPhone12,8", "iPhone14,6"]
## Loop G1b: Mac windows (High by Auto) the budget binds on with Sharp, and some it doesn't.
const WINDOWS := {Vector2i(1792, 828): true, Vector2i(1366, 768): true, Vector2i(1440, 900): true,
		Vector2i(1280, 720): false, Vector2i(1152, 648): false, Vector2i(1920, 1080): false, Vector2i(2532, 1170): false}

var problems: Array[String] = []


func _initialize() -> void:
	for model in MODELS:
		var got := Tiers.for_model(model)
		if got != MODELS[model]:
			problems.append("model %s: %s, wanted %s" % [model, Tiers.NAMES[got], Tiers.NAMES[MODELS[model]]])
	print("tiers: %d model ids checked" % MODELS.size())

	for screen: Vector2i in IMAGES:
		var row := PackedStringArray()
		for q in Tiers.QUALITY.size():
			var k := Tiers.image_scale(Vector2(screen), LINES[0], q)
			var img := Vector2i(screen.x / k, screen.y / k)
			row.append("%s %dx%d (x%d)" % [Tiers.NAMES[q], img.x, img.y, k])
			if img != IMAGES[screen][q]:
				problems.append("%dx%d %s: %dx%d, wanted %dx%d" % [screen.x, screen.y, Tiers.NAMES[q], img.x, img.y,
						IMAGES[screen][q].x, IMAGES[screen][q].y])
		print("image %dx%d, Sharp: %s" % [screen.x, screen.y, ", ".join(row)])

	var compared := 0
	for screen: Vector2i in IMAGES:
		for lines in LINES:
			for q in Tiers.QUALITY.size():
				var qs: Dictionary = Tiers.QUALITY[q]
				var k := Tiers.image_scale(Vector2(screen), lines, q)
				var pixels := float(screen.x / k) * float(screen.y / k)
				if k < 1 or pixels > float(qs["budget"]) * 1e6:
					problems.append("%dx%d %s at %.0f lines: x%d, %.2f MP over the budget %.2f" % [screen.x, screen.y,
							qs["name"], lines, k, pixels / 1e6, qs["budget"]])
				if q >= Tiers.ULTRA:
					continue
				# Loop 2b's rule: the style's scale, Low and Medium one step coarser.
				var old := maxi(1, floori(screen.y / lines)) + int(qs["step"])
				var one := float(screen.x) * float(screen.y)
				var expected := old
				if q == Tiers.HIGH and old == 1 and one > float(qs["budget"]) * 1e6:
					expected = 2
				compared += 1
				if k != expected:
					problems.append("%dx%d %s at %.0f lines: x%d, loop 2b gave x%d (only High at x1 over its budget may change)" % [
							screen.x, screen.y, qs["name"], lines, k, old])
	print("against loop 2b's rule: %d sizes x styles x levels" % compared)

	for pair in [["iPhone12,1", Vector2i(1792, 828), Vector2i(896, 414)], ["iPhone17,2", Vector2i(2868, 1320), Vector2i(1434, 660)]]:
		var level := Tiers.for_model(pair[0])
		var k := Tiers.image_scale(Vector2(pair[1]), LINES[0], level)
		var img := Vector2i(pair[1].x / k, pair[1].y / k)
		print("Auto's level on %s: %s, its own image (manual, Auto's fallback) %dx%d" % [pair[0], Tiers.NAMES[level], img.x, img.y])
		if img != pair[2]:
			problems.append("Auto on %s: %dx%d, wanted %dx%d" % [pair[0], img.x, img.y, pair[2].x, pair[2].y])

	for t in [["auto", Tiers.AUTO], ["Ultra", Tiers.ULTRA], ["med", Tiers.MEDIUM], ["2", Tiers.HIGH], ["9", Tiers.ULTRA], ["fast", -2],
			["experimental", Tiers.EXPERIMENTAL], ["Exp", Tiers.EXPERIMENTAL], ["4", Tiers.ULTRA]]:
		if Tiers.parse(t[0]) != t[1]:
			problems.append("--quality=%s parsed as %d, wanted %d" % [t[0], Tiers.parse(t[0]), t[1]])

	_check_sharp()
	_check_back_off()
	_check_experimental()
	_check_overrides()
	_check_mac()

	if problems.is_empty():
		print("check_tiers: OK (%d model ids, %d screens, %d comparisons with loop 2b, %d phones for Auto's sharp image)" % [
				MODELS.size(), IMAGES.size(), compared, SCREENS.size()])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_tiers: %d problems" % problems.size())
		quit(1)


## Loop G1b: where Auto's budget binds, and Auto's two scales there.
func _check_sharp() -> void:
	var hit := PackedStringArray()
	for model: String in SCREENS:
		var level := Tiers.for_model(model)
		var screen := Vector2(SCREENS[model])
		for s in LINES.size():
			var binds := Tiers.budget_binds(screen, LINES[s], level)
			if binds != (s == 0 and model in BINDS):
				problems.append("%s (%s, %s) at %.0f lines: the budget %s" % [model, Tiers.NAMES[level], SCREENS[model],
						LINES[s], "binds" if binds else "doesn't bind"])
			var sharp := Tiers.auto_scale(screen, LINES[s], level, true)
			var fallback := Tiers.auto_scale(screen, LINES[s], level, false)
			if fallback != Tiers.image_scale(screen, LINES[s], level):
				problems.append("%s at %.0f lines: Auto's fallback x%d is not the level's x%d" % [model, LINES[s], fallback,
						Tiers.image_scale(screen, LINES[s], level)])
			if (sharp != fallback) != binds:
				problems.append("%s at %.0f lines: Auto sharp x%d, fallback x%d" % [model, LINES[s], sharp, fallback])
			if binds:
				hit.append("%s %s x%d sharp / x%d fallback" % [model, Tiers.NAMES[level], sharp, fallback])
	print("Auto's budget binds (at the level Auto picks, any style) on: %s" % ", ".join(hit))
	for screen: Vector2i in WINDOWS:
		if Tiers.budget_binds(Vector2(screen), LINES[0], Tiers.HIGH) != WINDOWS[screen]:
			problems.append("window %dx%d at High: the budget %s" % [screen.x, screen.y, "doesn't bind" if WINDOWS[screen] else "binds"])
	# The phones: Auto's sharp and fallback images; the manual levels as in G1.
	var cases := [["iPhone12,1", true, Tiers.HIGH, Vector2i(1792, 828)], ["iPhone12,1", false, Tiers.HIGH, Vector2i(896, 414)],
			["iPhone12,8", true, Tiers.HIGH, Vector2i(1334, 750)], ["iPhone12,8", false, Tiers.HIGH, Vector2i(667, 375)],
			["iPhone17,2", true, Tiers.ULTRA, Vector2i(1434, 660)], ["iPhone17,2", false, Tiers.ULTRA, Vector2i(1434, 660)]]
	for c in cases:
		var level := Tiers.for_model(c[0])
		var screen: Vector2i = SCREENS[c[0]]
		var k := Tiers.auto_scale(Vector2(screen), LINES[0], level, c[1])
		var img := Vector2i(screen.x / k, screen.y / k)
		print("Auto on %s, %s: %s, image %dx%d" % [c[0], "sharp" if c[1] else "fallback", Tiers.NAMES[level], img.x, img.y])
		if level != c[2] or img != c[3]:
			problems.append("Auto on %s %s: %s %dx%d, wanted %s %dx%d" % [c[0], "sharp" if c[1] else "fallback",
					Tiers.NAMES[level], img.x, img.y, Tiers.NAMES[c[2]], c[3].x, c[3].y])
	var eleven := Vector2(1792, 828)
	if Tiers.image_scale(eleven, LINES[0], Tiers.HIGH) != 2 or Tiers.image_scale(eleven, LINES[0], Tiers.ULTRA) != 2:
		problems.append("manual levels on the iPhone 11: Wysoka x%d (wanted 2), Ultra x%d (wanted 2)" % [
				Tiers.image_scale(eleven, LINES[0], Tiers.HIGH), Tiers.image_scale(eleven, LINES[0], Tiers.ULTRA)])
	for d in [[Tiers.describe(Tiers.AUTO, Tiers.HIGH, "iPhone12,1", 1, "sharp"), "Auto→High ×1 sharp (iPhone12,1)"],
			[Tiers.describe(Tiers.AUTO, Tiers.HIGH, "iPhone12,1", 2, "fallback"), "Auto→High ×2 fallback (iPhone12,1)"],
			[Tiers.describe(Tiers.AUTO, Tiers.ULTRA, "iPhone17,2", 2), "Auto→Ultra ×2 (iPhone17,2)"],
			[Tiers.describe(Tiers.AUTO, Tiers.HIGH, "iPhone12,1", 0, "sharp"), "Auto→High sharp (iPhone12,1)"],
			[Tiers.describe(Tiers.HIGH, Tiers.HIGH, "iPhone12,1", 2), "High ×2"],
			[Tiers.describe(Tiers.AUTO, Tiers.HIGH, "iPhone12,1"), "Auto→High (iPhone12,1)"]]:
		if d[0] != d[1]:
			problems.append("describe: \"%s\", wanted \"%s\"" % [d[0], d[1]])


## Loop G1b: one launch after another from `state`, each letter a session's verdict (S struggled,
## C calm, - too short to say: nothing written); returns [the launches' images ("s" sharp, "f"
## fallback), the saved state at the end].
func _launches(state: Dictionary, sessions: String) -> Array:
	var images := ""
	for v in sessions:
		var launched := Tiers.sharp_launch(state)
		var sharp: bool = not launched["fallback"]
		images += "s" if sharp else "f"
		if v == "S":
			state = Tiers.sharp_struggled(launched, sharp, "scripted")
		elif v == "C":
			state = Tiers.sharp_calm(launched, sharp)
	return [images, state]


func _expect_launches(what: String, sessions: String, want: String) -> Dictionary:
	var r := _launches(Tiers.sharp_state(), sessions)
	print("back-off, %s: sessions %s → launches %s" % [what, sessions, r[0]])
	if r[0] != want:
		problems.append("back-off, %s: %s, wanted %s" % [what, r[0], want])
	return r[1]


func _check_back_off() -> void:
	# A hot day once: back after 2 calm sessions, the trial passed after 2 more; a struggle much
	# later starts from 2 again (not doubled).
	var end := _expect_launches("a hot day once", "SCCCCCCCSCCC", "sffssssssffs")
	if int(end["wait"]) != Tiers.SHARP_WAIT or int(end["trial"]) != 1:
		problems.append("back-off, a hot day once: ends %s, wanted wait 2, on trial 1" % end)
	# A struggle at the fallback starts its count again; short sessions write nothing.
	_expect_launches("a struggle at the fallback", "SCSCCC", "sffffs")
	end = _expect_launches("short sessions", "S--C-C-", "sfffffs")
	if Tiers.sharp_launch(end)["fallback"]:
		problems.append("short sessions: still the fallback after 2 calm ones (%s)" % end)
	# A phone that can't hold the sharp image (every sharp session struggles, every fallback one is
	# calm): back after 2, 4, 8, 16, 16... calm sessions, at most 1 launch in 17 once capped.
	var state := Tiers.sharp_state()
	var at := PackedInt32Array()
	for i in 120:
		var launched := Tiers.sharp_launch(state)
		var sharp: bool = not launched["fallback"]
		if sharp:
			at.append(i + 1)
		state = Tiers.sharp_struggled(launched, true, "scripted") if sharp else Tiers.sharp_calm(launched, false)
	print("back-off, a phone that can't hold it: sharp at launches %s of 120" % [at])
	var want := PackedInt32Array([1, 4, 9, 18, 35, 52, 69, 86, 103, 120])
	if at != want:
		problems.append("back-off, can't hold it: sharp at %s, wanted %s" % [at, want])
	# On trial: a calm verdict then a struggle in one session (main.gd computes both from the
	# launch's state) is the struggle, with the wait doubled.
	var trial := Tiers.sharp_launch({"fallback": true, "calm": 2, "wait": 2, "trial": -1, "why": "x"})
	var calm_then := Tiers.sharp_struggled(trial, true, "later")
	if trial["fallback"] or int(trial["trial"]) != 0 or not calm_then["fallback"] or int(calm_then["wait"]) != 4:
		problems.append("back-off, on trial, calm then a struggle: %s (from %s)" % [calm_then, trial])
	# 2026-10-30: the fallback's toast: a struggle at the sharp image asks for it once (told
	# false); a struggle or a calm session at the fallback, and the launch, keep what it was.
	var fell := Tiers.sharp_struggled(Tiers.sharp_state(), true, "x")
	var told := fell.duplicate()
	told["told"] = true
	if fell["told"] or not Tiers.sharp_launch(fell)["fallback"] or Tiers.sharp_launch(fell)["told"] \
			or not Tiers.sharp_struggled(told, false, "y")["told"] or not Tiers.sharp_calm(told, false)["told"]:
		problems.append("the fallback's toast: %s / %s" % [fell, Tiers.sharp_struggled(told, false, "y")])
	# The state from a file: missing keys, out of range.
	var cleaned := Tiers.sharp_clean({"wait": 999, "calm": -3, "trial": 99, "fallback": 1})
	if Tiers.sharp_clean({}) != Tiers.sharp_state() or int(cleaned["wait"]) != Tiers.SHARP_WAIT_MAX \
			or int(cleaned["calm"]) != 0 or int(cleaned["trial"]) != Tiers.SHARP_WAIT_MAX or not cleaned["fallback"]:
		problems.append("cleaning a state: %s / %s" % [Tiers.sharp_clean({}), cleaned])


## F 2026-11-10: Experimental is opt-in (Auto never picks it, on any model id or screen), draws the
## screen's own pixels at every style, and only it carries the trailer's extras.
func _check_experimental() -> void:
	for model: String in SCREENS:
		if Tiers.for_model(model) == Tiers.EXPERIMENTAL:
			problems.append("Auto picks Experimental on %s" % model)
	for model: String in MODELS:
		if Tiers.for_model(model) == Tiers.EXPERIMENTAL:
			problems.append("Auto picks Experimental on %s" % model)
	# Perf thread (F 2026-11-20): Max (was Experimental) draws the style's own scale like High and
	# Ultra (no budget), and the Image switch's Full draws x1 on any level.
	for screen: Vector2i in IMAGES:
		for lines in LINES:
			var ultra := Tiers.image_scale(Vector2(screen), lines, Tiers.ULTRA)
			if Tiers.image_scale(Vector2(screen), lines, Tiers.EXPERIMENTAL) != ultra:
				problems.append("Max at %dx%d, %.0f lines: x%d, wanted Ultra's x%d" % [screen.x, screen.y, lines,
						Tiers.image_scale(Vector2(screen), lines, Tiers.EXPERIMENTAL), ultra])
	Tiers.full_image = true
	for q in Tiers.QUALITY.size():
		if Tiers.image_scale(Vector2(1792, 828), 480.0, q) != 1 or Tiers.image_scale(Vector2(2868, 1320), 170.0, q) != 1:
			problems.append("%s: the Full image is not x1" % Tiers.NAMES[q])
	Tiers.full_image = false
	# The extras: MSAA and soft shadows on Ultra and Max; LOD 0, 16x anisotropic and the detailed trees on Max only.
	for q in Tiers.QUALITY.size():
		var top := q >= Tiers.ULTRA
		var mx := q == Tiers.EXPERIMENTAL
		if (int(Tiers.extra(q, "msaa")) != Viewport.MSAA_DISABLED) != top \
				or (int(Tiers.extra(q, "soft")) != RenderingServer.SHADOW_QUALITY_HARD) != top \
				or (float(Tiers.extra(q, "lod")) < 1.0) != mx or bool(Tiers.value(q, "fine_trees", false)) != mx:
			problems.append("%s: the extras are not as the perf thread set them" % Tiers.NAMES[q])
	# Ultra keeps High's budget: x2 on the iPhone 11 (it was x1 at 41.8 fps).
	if Tiers.image_scale(Vector2(1792, 828), 480.0, Tiers.ULTRA) != 2:
		problems.append("Ultra on the iPhone 11: x%d, wanted x2" % Tiers.image_scale(Vector2(1792, 828), 480.0, Tiers.ULTRA))
	if int(Tiers.value(Tiers.LOW, "cap", 0)) != 30 or int(Tiers.value(Tiers.HIGH, "cap", 0)) != 0:
		problems.append("the frame cap: Low %s, High %s (wanted 30, none)" % [Tiers.value(Tiers.LOW, "cap", 0), Tiers.value(Tiers.HIGH, "cap", 0)])
	if Tiers.describe(Tiers.EXPERIMENTAL, Tiers.EXPERIMENTAL, "iPhone17,2", 2) != "Max ×2" or Tiers.parse("max") != Tiers.EXPERIMENTAL:
		problems.append("describe Max: \"%s\"" % Tiers.describe(Tiers.EXPERIMENTAL, Tiers.EXPERIMENTAL, "iPhone17,2", 2))
	print("max: opt-in on %d model ids, its own scale on %d screens x %d styles, Full x1 everywhere, the extras by level" % [
			SCREENS.size() + MODELS.size(), IMAGES.size(), LINES.size()])


## Perf thread (2026-11-19): --gfx= overrides win over the level's row at every level, parse
## their values, set the image's scale exactly, and leave the tables alone when cleared; Auto on an
## Adreno 5xx/6xx is Low.
func _check_overrides() -> void:
	var o := Tiers.parse_overrides("scale=2,msaa=4,shadow_size=2048,small_shadows=off,soft=0,rain=0.5,aniso=16,bad")
	var want := {"scale": 2, "msaa": Viewport.MSAA_4X, "shadow_size": 2048, "small_shadows": false, "soft": 0,
			"rain": 0.5, "aniso": Viewport.ANISOTROPY_16X}
	for k: String in want:
		if not o.has(k) or o[k] != want[k]:
			problems.append("--gfx= parsed %s as %s, wanted %s" % [k, o.get(k), want[k]])
	if o.size() != want.size():
		problems.append("--gfx= kept %d keys, wanted %d (a pair without = is dropped)" % [o.size(), want.size()])
	Tiers.overrides = o
	for q in Tiers.QUALITY.size():
		if int(Tiers.value(q, "shadow_size")) != 2048 or bool(Tiers.value(q, "small_shadows")) or int(Tiers.extra(q, "msaa")) != Viewport.MSAA_4X:
			problems.append("%s: an override did not win" % Tiers.NAMES[q])
		if Tiers.image_scale(Vector2(2868, 1320), 480.0, q) != 2 or Tiers.own_scale(Vector2(1792, 828), 480.0, q) != 2:
			problems.append("%s: scale=2 not exact" % Tiers.NAMES[q])
	Tiers.overrides = {}
	if int(Tiers.value(Tiers.ULTRA, "shadow_size")) != 4096 or Tiers.image_scale(Vector2(1792, 828), 480.0, Tiers.ULTRA) != 2:
		problems.append("cleared overrides: Ultra no longer its own row")
	for pair: Array in [["A063", "Adreno (TM) 642L", Tiers.LOW], ["SM-S918B", "Adreno (TM) 740", Tiers.HIGH],
			["iPhone17,2", "Apple A18 Pro GPU", Tiers.ULTRA], ["A063", "", Tiers.HIGH], ["X", "Adreno (TM) 530", Tiers.LOW]]:
		if Tiers.for_device(pair[0], pair[1]) != pair[2]:
			problems.append("for_device %s / %s: %s, wanted %s" % [pair[0], pair[1], Tiers.NAMES[Tiers.for_device(pair[0], pair[1])], Tiers.NAMES[pair[2]]])
	print("overrides: --gfx= parsed, wins at %d levels, cleared again; Auto on an old Adreno is Low" % Tiers.QUALITY.size())


## Mac step 1: the iPhone app on a Mac (mac_mode.gd detect, tiers.gd's `mac` rules).
func _check_mac() -> void:
	for row: Array in [
			["iOS", "arm64", "Apple M4 Pro", true], ["iOS", "MacBookPro18,3", "", true], ["iOS", "x86_64", "", true],
			["iOS", "iPhone17,2", "Apple A18 Pro GPU", false], ["iOS", "iPad16,3", "Apple M4", false],
			["macOS", "MacBookPro18,3", "Apple M4 Pro", false], ["Android", "A063", "Adreno (TM) 642L", false]]:
		if MacMode.detect(row[0], row[1], row[2]) != row[3]:
			problems.append("mac detect %s / %s / %s: wanted %s" % row)
	Tiers.mac = true
	for pair: Array in [["Apple M4 Pro", Tiers.ULTRA], ["Apple M2", Tiers.HIGH], ["Apple M1", Tiers.HIGH],
			["Apple M3", Tiers.ULTRA], ["Apple M2 Max", Tiers.ULTRA]]:
		if Tiers.for_device("arm64", pair[0]) != pair[1]:
			problems.append("mac Auto on %s: %s, wanted %s" % [pair[0], Tiers.NAMES[Tiers.for_device("arm64", pair[0])], Tiers.NAMES[pair[1]]])
	# A 14" MacBook full screen, a 16", a 4K screen, a phone-sized window.
	var want := {Vector2i(3024, 1964): [3, 3, 2, 2, 1], Vector2i(3456, 2234): [3, 3, 2, 2, 1],
			Vector2i(3840, 2160): [4, 4, 3, 3, 1], Vector2i(1704, 786): [2, 2, 1, 1, 1]}
	for screen: Vector2i in want:
		for q in Tiers.QUALITY.size():
			var k := Tiers.image_scale(Vector2(screen), 480.0, q)
			var a := Tiers.auto_scale(Vector2(screen), 480.0, q, true)
			if k != want[screen][q] or a != k:
				problems.append("mac %dx%d %s: x%d (Auto x%d), wanted x%d" % [screen.x, screen.y, Tiers.NAMES[q], k, a, want[screen][q]])
			if q < Tiers.EXPERIMENTAL and floorf(screen.x / float(k)) * floorf(screen.y / float(k)) > Tiers.MAC_BUDGET * 1e6:
				problems.append("mac %dx%d %s: over the Mac's budget" % [screen.x, screen.y, Tiers.NAMES[q]])
	for q in Tiers.QUALITY.size():
		var msaa := int(Tiers.extra(q, "msaa"))
		if msaa != (Viewport.MSAA_4X if q >= Tiers.HIGH else Viewport.MSAA_DISABLED):
			problems.append("mac %s: msaa %d" % [Tiers.NAMES[q], msaa])
	Tiers.overrides = {"msaa": Viewport.MSAA_DISABLED, "scale": 1}
	if int(Tiers.extra(Tiers.ULTRA, "msaa")) != Viewport.MSAA_DISABLED or Tiers.image_scale(Vector2(3024, 1964), 480.0, Tiers.ULTRA) != 1:
		problems.append("mac: --gfx= overrides no longer win")
	Tiers.overrides = {}
	Tiers.mac = false
	if Tiers.image_scale(Vector2(3024, 1964), 480.0, Tiers.ULTRA) != 4 or int(Tiers.extra(Tiers.ULTRA, "msaa")) != Viewport.MSAA_DISABLED:
		problems.append("mac off: the phone's rules did not come back")
	# The keys that hide the touch pads, the presses that bring them back.
	for row: Array in [[KEY_W, true], [KEY_M, true], [KEY_LEFT, true], [KEY_SPACE, true], [KEY_ESCAPE, false],
			[KEY_BACK, false], [KEY_VOLUMEUP, false], [KEY_SHIFT, false]]:
		var e := InputEventKey.new()
		e.physical_keycode = row[0]
		e.pressed = true
		if MacMode.is_play_key(e) != row[1]:
			problems.append("mac: key %s hides the pads: wanted %s" % [OS.get_keycode_string(row[0]), row[1]])
		e.echo = true
		if MacMode.is_play_key(e):
			problems.append("mac: a repeat counted as a key press")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	if not MacMode.is_touch(touch) or not MacMode.is_touch(click) or MacMode.is_touch(wheel):
		problems.append("mac: a touch or click brings the pads back, the wheel doesn't")
	print("mac: detection, Auto, x2 inside %.0f MP with MSAA 4x, overrides, keys and touches checked" % Tiers.MAC_BUDGET)
