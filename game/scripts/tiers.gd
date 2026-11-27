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
## Perf thread (F 2026-11-20): the fifth level is Max (it was Experimental), for everyone.
const NAMES := ["Low", "Medium", "High", "Ultra", "Max"]

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
		"reflect": 0, "traffic": 0.55, "people": 24, "small_shadows": false, "tree_limbs": false, "panel_holes": true,
		"cap": 30, "screen_fx": false, "house_clutter": false},
	{"name": "Medium", "step": 1, "budget": 0.5, "shadows": true, "shadow_size": 1024, "glow": true, "rain": 0.7,
		"reflect": 6, "traffic": 0.8, "people": 40, "small_shadows": false, "panel_holes": true},
	{"name": "High", "step": 0, "budget": 0.96, "shadows": true, "shadow_size": 2048, "glow": true, "rain": 1.0,
		"reflect": 10, "traffic": 1.0, "people": 60, "small_shadows": true},
	{"name": "Ultra", "step": 0, "budget": 0.96, "shadows": true, "shadow_size": 4096, "glow": true, "rain": 1.0,
		"reflect": 16, "traffic": 1.0, "people": 60, "small_shadows": true,
		"msaa": Viewport.MSAA_4X, "soft": RenderingServer.SHADOW_QUALITY_SOFT_LOW},
	{"name": "Max", "step": 0, "budget": 0.96, "shadows": true, "shadow_size": 8192, "glow": true, "rain": 1.0,
		"reflect": 16, "traffic": 1.0, "people": 60, "small_shadows": true,
		"fine_trees": true, "msaa": Viewport.MSAA_4X, "aniso": Viewport.ANISOTROPY_16X, "lod": 0.0,
		"soft": RenderingServer.SHADOW_QUALITY_SOFT_HIGH},
]
## Perf thread (F 2026-11-20, "go"), the levels rebuilt from the per-option costs (docs/changes
## 2026-11-19-graphics-kept.md: on Apple GPUs the image's pixels are the cost; shadow map size,
## softness, reflections and the rest are nearly free):
## - Low caps the frame rate at 30 (`cap`, main.gd _apply_fps; the player's 60/30 can only lower
##   it): the Adreno 642L runs Low at 28.5-35 uncapped, so a steady 30 paces better than 60.
## - Ultra keeps the High budget (0.96 MP: x2 on every phone; it was 1.6, x1 on the iPhone 11 at
##   41.8 fps, x2 is 60) and adds MSAA 4x and soft shadows (the 16 Pro Max: Ultra + MSAA 4x 60.0).
## - Max (was Experimental) is every extra at the x2 image, the same 0.96 MP budget (60.0 / 59.9 on
##   the 16 Pro Max; 37 at x1). The screen's own pixels are the Image switch's Full (`full_image`, Settings → Obraz),
##   on any level, for shots and trailers.
## The extras (msaa, soft, aniso, lod, fine_trees) apply only on the rows that name them; missing
## keys take EXTRA_DEFAULTS.
## Perf thread (2026-11-19): `fine_trees` true (Max only; missing means false) draws the cut
## 80-face crowns (map_builder.gd set_tree_detail), the others the 20-face crown with its limbs.
## THE TAPCZAN (2026-11-24, perf audit): `screen_fx` false (Low, so also Auto's Low on an old Adreno)
## skips the full-screen passes that read the screen back (tipsy.gdshader's hint_screen_texture: on
## a tile-based GPU it ends the pass and copies the frame); the effect keeps what costs nothing
## (tipsy.gd: the camera's sway, the thoughts, the car's pull). Missing means true.
## Trees thread (2026-11-15): `tree_limbs` false (Low) hides the crowns' limbs (foliage.gdshader
## `limbs`): a bare tree is its haze and trunk, 36 fewer triangles a crown. Missing means true.
## House types 2b (docs/design/house-types.md): `house_clutter` false (Low) drops the painted
## air conditioners, flower boxes, laundry and dishes on ordinary houses (building.gdshader
## `clutter`); the stairwells and televisions stay. Missing means true.
## W4 of the walls look (docs/design/walls-true-to-life.md 9): `panel_holes` false makes the
## fence panels (panel.gdshader `holes`) solid, their gaps the row's colour blended toward the
## ground by its openness, so the tile-based GPU keeps its hidden-surface shortcut for them (a
## `discard` turns it off). The fallback ladder's step for a frame that drops on the iPhone 11
## with panels: true everywhere until the phone shows it is needed (then Low and Medium go
## false); the governor never touches it. Missing means true.
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
	if mac and key == "msaa" and quality >= HIGH and not overrides.has(key):
		return maxi(int(value(quality, key, EXTRA_DEFAULTS[key])), MAC_MSAA)
	return value(quality, key, EXTRA_DEFAULTS.get(key))


## Perf thread (2026-11-19): one option's value at a level, with the per-option overrides on top
## (`overrides`, key → value: today the --gfx= test flag, dev_flags.gd; the graphics options page
## later, docs/design/graphics-and-perf-plan.md 2.4). An override wins at every level, so one
## option can be measured or set on its own; missing keys fall back to the level's row, then to
## `fallback`. Keys are QUALITY's (shadows, shadow_size, glow, rain, reflect, traffic, people,
## small_shadows, tree_limbs, panel_holes, fine_trees, step, budget, full, msaa, aniso, lod, soft)
## plus `scale`: the image's whole screen pixels per image pixel, exact (no style, step or budget).
static var overrides: Dictionary = {}


static func value(quality: int, key: String, fallback: Variant = null) -> Variant:
	if overrides.has(key):
		return overrides[key]
	var q: Dictionary = QUALITY[clampi(quality, 0, QUALITY.size() - 1)]
	return q.get(key, fallback)


## The --gfx= flag's text, "key=value,key=value", as overrides: true/false/on/off as bools,
## numbers as int or float, msaa as 0/2/4/8 (Viewport.MSAA_*), soft as 0 (hard) to 5
## (RenderingServer.SHADOW_QUALITY_*), aniso as 0/2/4/8/16. A pair without "=" is dropped.
const MSAA_BY_SAMPLES := {0: Viewport.MSAA_DISABLED, 2: Viewport.MSAA_2X, 4: Viewport.MSAA_4X, 8: Viewport.MSAA_8X}
const ANISO_BY_TAPS := {0: Viewport.ANISOTROPY_DISABLED, 2: Viewport.ANISOTROPY_2X, 4: Viewport.ANISOTROPY_4X,
		8: Viewport.ANISOTROPY_8X, 16: Viewport.ANISOTROPY_16X}


static func parse_overrides(text: String) -> Dictionary:
	var out := {}
	for pair: String in text.split(",", false):
		var kv := pair.split("=", false)
		if kv.size() != 2:
			continue
		var key := kv[0].strip_edges()
		var raw := kv[1].strip_edges().to_lower()
		var v: Variant = raw
		if raw in ["true", "on", "yes"]:
			v = true
		elif raw in ["false", "off", "no"]:
			v = false
		elif raw.is_valid_int():
			v = int(raw)
		elif raw.is_valid_float():
			v = float(raw)
		if key == "msaa" and v is int:
			v = MSAA_BY_SAMPLES.get(v, Viewport.MSAA_DISABLED)
		elif key == "aniso" and v is int:
			v = ANISO_BY_TAPS.get(v, Viewport.ANISOTROPY_DISABLED)
		out[key] = v
	return out


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


## Perf thread (2026-11-19): the level Auto picks for this device: for_model, except an Adreno
## 5xx/6xx GPU (`adapter`, e.g. "Adreno (TM) 642L": the Nothing Phone 1 did 17.6 fps at High, 22.8
## at Medium, 28.5 at Low on the bench route) starts at Low. "" (a --model= run) skips the GPU rule.
static func for_device(model: String, adapter: String) -> int:
	if mac:
		return for_mac(adapter)
	if GpuQuirks.is_old_adreno(adapter):
		return LOW
	var android := android_level(adapter)
	if android >= 0:
		return android
	return for_model(model)


## Perf thread (2026-11-23, the beta's PostHog fps samples): an Android phone's level by its GPU's
## name, -1 for a GPU that is no phone's. Adreno 7xx and up and Samsung's Xclipse hold High (Galaxy
## S24 56.8 fps, A56 58.6); Mali, PowerVR and the rest start at Medium (Motorola edge 40, Mali-G77:
## 27.2 at High); Immortalis (the Mali flagships) High. An old Adreno is Low (`for_device`). Every
## Auto level can still step down a level after a session that struggled (quality_keep.gd).
static func android_level(adapter: String) -> int:
	var a := adapter.to_lower()
	if a.contains("adreno") or a.contains("xclipse") or a.contains("immortalis"):
		return HIGH
	if a.contains("mali") or a.contains("powervr") or a.contains("maleoon"):
		return MEDIUM
	return -1


## Mac step 1 (F 2026-11-20; mac_mode.gd): the iPhone app on a Mac. main.gd sets it from
## MacMode.active() before the level is picked. There the image is no phone's: every level below
## Experimental draws `mac_scale` (2 screen pixels a pixel, Low and Medium their step coarser)
## instead of the style's lines and the level's budget, and High and up add MSAA 4x (the edges a
## 2x image shows that the pixel look hid). The perf thread's numbers (M4 Pro, 2026-11-20):
## Ultra x2 145 fps, Experimental at 3024x1890 90 fps; an M2 MacBook Air is still owed a run.
static var mac := false
const MAC_MSAA := Viewport.MSAA_4X
## The most megapixels a Mac's image may have: a 16" MacBook's 3456x2234 window at x2 is 1.93 MP;
## a 4K screen (3840x2160, 2.07 MP at x2) goes to x3.
const MAC_BUDGET := 2.0


## The level Auto picks on a Mac from its GPU's name: a base M1 or M2 ("Apple M1", "Apple M2",
## the MacBook Air's 7 to 10 GPU cores) High, every other (Pro, Max, Ultra, M3 and newer) Ultra.
static func for_mac(adapter: String) -> int:
	return HIGH if adapter in ["Apple M1", "Apple M2"] else ULTRA


## A Mac's image scale for a window `size`: 2, coarser until the image fits MAC_BUDGET; 1 in a
## window under 800 pixels tall (a phone-sized window on a non-Retina screen).
static func mac_scale(size: Vector2) -> int:
	if size.y < 800.0:
		return 1
	var k := 2
	while k < 64 and floorf(size.x / k) * floorf(size.y / k) > MAC_BUDGET * 1e6:
		k += 1
	return k


## Whole screen pixels per image pixel for a screen `size` (pixels), a style's `lines` and a
## quality level: the style's own scale, the level's step coarser, then coarser until the
## image (the screen's size divided by it, as SubViewportContainer.stretch_shrink rounds it)
## fits the level's budget.
## Perf thread (F 2026-11-20): Settings → Obraz "Pełny · Full": the 3D image at the screen's own
## pixels on any level (the old Experimental's x1, for shots and trailers; 37 fps on the 16 Pro Max at
## Max, where x2 holds 60). main.gd sets it from settings.gd `image_full`.
static var full_image := false


static func image_scale(size: Vector2, lines: float, quality: int) -> int:
	if (full_image or bool(value(quality, "full", false))) and not overrides.has("scale"):
		return 1  # the screen's own pixels: no budget (Settings' Full, or --gfx=full=true)
	if overrides.has("scale"):
		return maxi(1, int(overrides["scale"]))
	var k := own_scale(size, lines, quality)
	if mac:
		return k  # the Mac's own budget (mac_scale)
	var budget := float(value(quality, "budget")) * 1e6
	while k < 64 and floorf(size.x / k) * floorf(size.y / k) > budget:
		k += 1
	return k


## Loop G1b: the style's own scale at a level, before the budget: the most whole screen pixels
## that keep the style's lines (at least 1), the level's step coarser.
static func own_scale(size: Vector2, lines: float, quality: int) -> int:
	if overrides.has("scale"):
		return maxi(1, int(overrides["scale"]))
	if full_image or bool(value(quality, "full", false)):
		return 1
	if mac:
		# Max on a Mac is the screen's own pixels (the Mac thread's rule: an M4 Pro holds it at 90
		# fps); on a phone Max is x2 (the perf thread's levels, 2026-11-20).
		if quality == EXPERIMENTAL:
			return 1
		return mac_scale(size) + int(value(quality, "step"))
	return maxi(1, floori(size.y / lines)) + int(value(quality, "step"))


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
	# Max (was Experimental) by name only: a number still stops at Ultra.
	var named := {"auto": AUTO, "low": LOW, "medium": MEDIUM, "med": MEDIUM, "high": HIGH, "ultra": ULTRA,
			"experimental": EXPERIMENTAL, "exp": EXPERIMENTAL, "max": EXPERIMENTAL}
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
