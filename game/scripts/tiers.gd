extends RefCounted
## Loop G1: the quality levels, the level Auto picks for a device, and the pixel image's size
## (docs/design/graphics.md section 4). Static, so tools/check_tiers.gd tests the same tables
## and rules the game uses (main.gd applies them).
##
## - Auto (the default since G1) picks a level from the device's model id
##   (`OS.get_model_name()`, e.g. `iPhone12,1`; the number before the comma is the family, not
##   the marketing name: `iPhone11,x` is the XS/XR, the iPhone 11 is `iPhone12,1`).
## - The pixel image: each style has its lines (Sharp 480); the image scales up by the most
##   whole screen pixels that keep at least that many lines (at least 1), `step` coarser for
##   Low and Medium, then coarser again until the image fits the level's **budget** in
##   megapixels. The iPhone 11's 828 lines at Sharp were 1 → 1792×828, 1.48 MP, the most pixels
##   of any phone with half the Pro Max's GPU, and its High stuttered (1 % low 25 fps) from fill;
##   High's budget (the Pro Max's own 1434×660, 0.95 MP, the most a phone has held 60 fps with
##   at High) gives it 2 → 896×414 with High's shadows and effects, and leaves every phone
##   that already scaled by 2 or more as it was.
## - Loop G1b: **Auto starts sharp.** Where a level's budget makes the image coarser than the
##   style's own scale (budget_binds: High with Sharp on the iPhone 11 and the SE 2 / 3), Auto
##   draws the style's own scale with that level's effects (High ×1, not Ultra's extras), and
##   falls back to the budget for the next launches when a session there struggled (the
##   governor's GPU extras down a minute, governor.gd `struggle`), coming back after calm
##   sessions with a doubling wait (SHARP_*). Manual levels keep G1's rule.

enum { LOW, MEDIUM, HIGH, ULTRA, EXPERIMENTAL }
## The player's choice that follows the device (settings.gd quality).
const AUTO := -1
const NAMES := ["Low", "Medium", "High", "Ultra", "Experimental"]

## Low, Medium, High, Ultra. step: whole screen pixels coarser than the style's own scale
## (loop 2b); budget: the most megapixels the pixel image may have (G1); the sun's shadow map
## (loop 2b: 2048 on High and 1024 on Medium cover only the view, finer than 4096 did over
## 2 km; Ultra's 4096 halves the texels again, 0.37 → 0.18 m); glow at night; rain streaks;
## mirror-reflection steps a pixel; the traffic's share and the most pedestrians; whether
## things over a metre that aren't buildings or trees (map_builder.gd SMALL_CASTERS: lamps,
## signals, parked cars, columns, shelters) cast sun shadows. Ultra (A17 Pro and newer by
## Auto) is High plus the 4096 map and 16 reflection steps, with a budget that keeps a
## 1.48 MP ×1 image (the iPhone 11's look before G1, for anyone who picks it).
const QUALITY := [
	{"name": "Low", "step": 1, "budget": 0.5, "shadows": false, "shadow_size": 1024, "glow": false, "rain": 0.4,
		"reflect": 0, "traffic": 0.55, "people": 24, "small_shadows": false},
	{"name": "Medium", "step": 1, "budget": 0.5, "shadows": true, "shadow_size": 1024, "glow": true, "rain": 0.7,
		"reflect": 6, "traffic": 0.8, "people": 40, "small_shadows": false},
	{"name": "High", "step": 0, "budget": 0.96, "shadows": true, "shadow_size": 2048, "glow": true, "rain": 1.0,
		"reflect": 10, "traffic": 1.0, "people": 60, "small_shadows": true},
	{"name": "Ultra", "step": 0, "budget": 1.6, "shadows": true, "shadow_size": 4096, "glow": true, "rain": 1.0,
		"reflect": 16, "traffic": 1.0, "people": 60, "small_shadows": true},
	{"name": "Experimental", "step": 0, "budget": 99.0, "shadows": true, "shadow_size": 8192, "glow": true, "rain": 1.0,
		"reflect": 16, "traffic": 1.0, "people": 60, "small_shadows": true,
		"full": true, "msaa": Viewport.MSAA_4X, "aniso": Viewport.ANISOTROPY_16X, "lod": 0.0,
		"soft": RenderingServer.SHADOW_QUALITY_SOFT_HIGH},
]
## Experimental (F 2026-11-10, "after the ultra the experimental setting of graphic to test all
## this enhancements on the phone"): Ultra plus the beta trailer's capture extras
## (trailer.gd begin; the graphics research's "High" list), to judge each on a real phone:
## - `full`: the 3D image at the screen's own pixels (scale 1, no budget), the sharpest picture;
## - an 8192 sun shadow map (16-bit, 128 MB) with soft edges (`soft`, SHADOW_QUALITY_SOFT_HIGH);
## - `msaa`: 4x MSAA on the 3D image (smooth edges); `aniso`: 16x anisotropic filtering (roads
##   and facades seen at a slant stay sharp); `lod`: 0, every mesh at full detail.
## No shader source changes (the building shader is at the Adreno budget): all are engine
## settings on the 3D SubViewport and the RenderingServer. Opt-in only: Auto never picks it
## (for_model), the saved settings never keep it (main.gd _set_quality: a launch that can't hold
## it can't lock the player out), and the governor's first GPU drop there steps the session back
## to Ultra with a toast (main.gd _govern). Every other level leaves the extras at the engine's
## defaults (EXTRA_DEFAULTS).
const EXTRA_DEFAULTS := {"full": false, "msaa": Viewport.MSAA_DISABLED, "lod": 1.0,
		"soft": RenderingServer.SHADOW_QUALITY_HARD}


## A level's value for one of Experimental's extras (EXTRA_DEFAULTS on the others; "aniso" has
## no default here: main.gd keeps the SubViewport's own).
static func extra(quality: int, key: String) -> Variant:
	var q: Dictionary = QUALITY[clampi(quality, 0, QUALITY.size() - 1)]
	return q.get(key, EXTRA_DEFAULTS.get(key))


## The level Auto picks for a model id (graphics.md 4.1): iPhone 8 / X (`iPhone10,x`, A11) Low,
## XS / XR (`iPhone11,x`, A12) Medium, 11 to 15 and the SE 2 / 3 (`iPhone12,x`–`iPhone15,x`,
## A13–A16) and the 16e (`iPhone17,5`, A18 with a 4-core GPU) High, 15 Pro and newer
## (`iPhone16,x`, `iPhone17,1`–`4`, `iPhone18,x` and up: A17 Pro, A18, A19…) Ultra; anything
## else (an iPad, a Mac, the simulator, an id this doesn't know) High, with the governor.
static func for_model(model: String) -> int:
	if not model.begins_with("iPhone"):
		return HIGH
	var parts := model.trim_prefix("iPhone").split(",")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return HIGH
	var family := int(parts[0])
	var unit := int(parts[1])
	if family <= 10:
		return LOW
	if family == 11:
		return MEDIUM
	if family <= 15:
		return HIGH
	if family == 17 and unit == 5:
		return HIGH
	return ULTRA


## Whole screen pixels per image pixel for a screen `size` (pixels), a style's `lines` and a
## quality level: the style's own scale, the level's step coarser, then coarser until the
## image (the screen's size divided by it, as SubViewportContainer.stretch_shrink rounds it)
## fits the level's budget.
static func image_scale(size: Vector2, lines: float, quality: int) -> int:
	var q: Dictionary = QUALITY[clampi(quality, 0, QUALITY.size() - 1)]
	var k := own_scale(size, lines, quality)
	var budget := float(q["budget"]) * 1e6
	while k < 64 and floorf(size.x / k) * floorf(size.y / k) > budget:
		k += 1
	return k


## Loop G1b: the style's own scale at a level, before the budget: the most whole screen pixels
## that keep the style's lines (at least 1), the level's step coarser.
static func own_scale(size: Vector2, lines: float, quality: int) -> int:
	var q: Dictionary = QUALITY[clampi(quality, 0, QUALITY.size() - 1)]
	if bool(q.get("full", false)):
		return 1
	return maxi(1, floori(size.y / lines)) + int(q["step"])


## Loop G1b: whether the level's budget makes this image coarser than the style's own scale (on
## the phones only High with Sharp on the iPhone 11's 1792×828 and the SE 2 / 3's 1334×750):
## there Auto draws the style's own scale, with the fallback below.
static func budget_binds(size: Vector2, lines: float, quality: int) -> bool:
	return image_scale(size, lines, quality) > own_scale(size, lines, quality)


## Loop G1b: the scale Auto draws: the style's own where `sharp`, else the level's budget's
## (image_scale; they differ only where budget_binds). Manual levels always use image_scale.
static func auto_scale(size: Vector2, lines: float, quality: int, sharp: bool) -> int:
	return own_scale(size, lines, quality) if sharp else image_scale(size, lines, quality)


## Loop G1b: Auto's sharp image and its fallback (docs/design/graphics.md 4.5), a state kept in
## settings.gd between launches:
## - `fallback`: the next launches draw the level's budget (×2 on the iPhone 11);
## - `calm`: calm sessions at the fallback so far; `wait`: how many it takes before the sharp
##   image is tried again;
## - `trial`: -1, or the calm sessions at the sharp image since it came back: a struggle before
##   `wait` of them doubles the wait (up to SHARP_WAIT_MAX), `wait` of them pass the trial and
##   the wait is back to SHARP_WAIT;
## - `why`: what the struggle was, for the log.
## The governor's raise-wait law one level up: a retry that fails soon waits twice as long next
## time, so the image can't swing launch after launch. 2 calm sessions: a day or two of play
## after a hot session (the heat is the session's: sun, charging, a case, not the phone's for
## good); doubling to 16: a phone that can't hold the sharp image spends one session in 17 on
## it (the governor guarding that one), about a fortnight of daily play between tries.
const SHARP_WAIT := 2
const SHARP_WAIT_MAX := 16


## A fresh state: the sharp image, no fallback.
static func sharp_state() -> Dictionary:
	return {"fallback": false, "calm": 0, "wait": SHARP_WAIT, "trial": -1, "why": "", "told": true}


## The state a launch starts from: a fallback that has had `wait` calm sessions tries the sharp
## image again, on trial. The launch is sharp when the result's `fallback` is false.
static func sharp_launch(state: Dictionary) -> Dictionary:
	var s := sharp_clean(state)
	if s["fallback"] and int(s["calm"]) >= int(s["wait"]):
		s["fallback"] = false
		s["calm"] = 0
		s["trial"] = 0
	return s


## After a session that struggled (`launched`: the state its launch started from; `sharp`: it
## drew the sharp image). At the sharp image: the fallback from the next launch on, the wait
## doubled if the sharp image was on trial, else SHARP_WAIT. At the fallback: its calm count
## starts again (the phone is under strain, so the sharp image waits longer).
static func sharp_struggled(launched: Dictionary, sharp: bool, why: String) -> Dictionary:
	var s := sharp_clean(launched)
	if sharp:
		s["wait"] = mini(int(s["wait"]) * 2, SHARP_WAIT_MAX) if int(s["trial"]) >= 0 else SHARP_WAIT
		s["fallback"] = true
		s["trial"] = -1
		s["why"] = why
		# 2026-10-30: the first launch at the fallback says so once (main.gd _fallback_toast).
		s["told"] = false
	s["calm"] = 0
	return s


## After a calm session: at the fallback one more towards the sharp image; at the sharp image on
## trial one more towards passing it.
static func sharp_calm(launched: Dictionary, sharp: bool) -> Dictionary:
	var s := sharp_clean(launched)
	if not sharp:
		s["calm"] = int(s["calm"]) + 1
	elif int(s["trial"]) >= 0:
		s["trial"] = int(s["trial"]) + 1
		if int(s["trial"]) >= int(s["wait"]):
			s["trial"] = -1
			s["wait"] = SHARP_WAIT
	return s


## A copy with every key present and in range (a missing, old or hand-edited settings file).
static func sharp_clean(state: Dictionary) -> Dictionary:
	var s := sharp_state()
	s["fallback"] = bool(state.get("fallback", false))
	s["wait"] = clampi(int(state.get("wait", SHARP_WAIT)), SHARP_WAIT, SHARP_WAIT_MAX)
	s["calm"] = clampi(int(state.get("calm", 0)), 0, SHARP_WAIT_MAX)
	s["trial"] = clampi(int(state.get("trial", -1)), -1, SHARP_WAIT_MAX)
	s["why"] = str(state.get("why", ""))
	s["told"] = bool(state.get("told", true))
	return s


## A choice (AUTO or a level) by name or number for --quality= (-2: not one).
static func parse(text: String) -> int:
	var t := text.to_lower()
	# Experimental by name only: a number still stops at Ultra.
	var named := {"auto": AUTO, "low": LOW, "medium": MEDIUM, "med": MEDIUM, "high": HIGH, "ultra": ULTRA,
			"experimental": EXPERIMENTAL, "exp": EXPERIMENTAL}
	if named.has(t):
		return named[t]
	if t.is_valid_int():
		return clampi(int(t), LOW, ULTRA)
	return -2


## "Auto→High (iPhone12,1)" or "Medium": the choice for the bench card. Loop G1b: with the
## image's `scale` (0: left out) and Auto's `mode` ("sharp", "fallback" or "": the budget
## doesn't bind): "Auto→High ×1 sharp (iPhone12,1)", "Auto→High ×2 fallback (iPhone12,1)",
## "Auto→Ultra ×2 (iPhone17,2)", "High ×2".
static func describe(choice: int, level: int, model: String, scale := 0, mode := "") -> String:
	var tail := (" ×%d" % scale if scale > 0 else "") + (" " + mode if mode != "" else "")
	if choice == AUTO:
		return "Auto→%s%s (%s)" % [NAMES[level], tail, model]
	return NAMES[clampi(choice, LOW, EXPERIMENTAL)] + tail
