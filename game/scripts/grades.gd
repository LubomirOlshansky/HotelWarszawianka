class_name Grades
extends RefCounted
## The picture's colour looks (F, 2026-11-15, after the grading research: "go with the recommended
## settings"). A look is a set of overrides on time_of_day.gd's LOOKS (the light, the sky, the split
## tone) plus the post pass's grade values (g_*: gain, contrast round a pivot, lift, vibrance, a
## highlight shoulder). Settings → Obraz → Kolory picks one of SETTING: "warsaw" (shown as Natural, the default: a
## clean camera look by day and night, a real sunset at dusk), "neon" (the vaporwave side turned
## up) and "classic" (the picture before 2026-11-15, which overrides nothing). The rest are the
## research's other looks, kept for --grade=NAME and --grade-sweep= comparison sheets. No look
## adds a pass, a texture, a light or a draw call: a few instructions in the post pass.

## The looks Settings offers, in the order of its segments; the saved value is the index.
const SETTING := ["warsaw", "neon", "classic"]
const NAMES := ["warsaw", "neon", "classic", "natural", "cinematic", "golden", "pastel"]

## The grade values that leave the image alone (merged into every look first).
const NEUTRAL := {
	"g_gain": Vector3(1, 1, 1), "g_contrast": 1.0, "g_pivot": 0.18, "g_lift": Vector3(0, 0, 0),
	"g_vibrance": 0.0, "g_shoulder": 0.0,
}

## name -> [day, dusk, night] overrides.
const LOOKS := {
	"classic": [{}, {}, {}],
	# Natural: what a good camera would give. A gentle S-curve, deeper and cooler shade by day,
	# a navy (not violet) night with warm lamps.
	"natural": [
		{
			"ambient": Color("#aebfdc"), "ambient_energy": 0.6, "sun": Color("#fff0d6"), "sun_energy": 1.38,
			"g_contrast": 1.12, "g_shoulder": 0.3, "g_vibrance": 0.12,
		},
		{
			"g_contrast": 1.1, "g_shoulder": 0.2, "g_vibrance": 0.1,
			"tone_amount": 0.55, "tone_shadow": Vector3(0.86, 0.92, 1.14), "tone_light": Vector3(1.05, 0.99, 0.92),
		},
		{
			"ambient": Color("#2a3558"), "ambient_energy": 0.4, "sun": Color("#9fb0e8"), "sky_top": Color("#03060f"), "sky_bottom": Color("#16224a"),
			"background": Color("#080c1c"),
			"tone_amount": 0.7, "tone_shadow": Vector3(0.84, 0.94, 1.18), "tone_light": Vector3(1.07, 0.98, 0.9),
			"g_contrast": 1.12, "g_pivot": 0.1, "g_vibrance": 0.1,
		},
	],
	# Cinematic: the teal and orange of film posters. Shade towards teal, light towards orange,
	# strong contrast with a soft highlight roll-off.
	"cinematic": [
		{
			"ambient": Color("#a6c4d6"), "ambient_energy": 0.6, "sun": Color("#ffe2b4"), "sun_energy": 1.4,
			"tone_amount": 0.75, "tone_shadow": Vector3(0.84, 1.0, 1.1), "tone_light": Vector3(1.09, 1.0, 0.88),
			"g_contrast": 1.22, "g_shoulder": 0.45, "g_vibrance": -0.05,
		},
		{
			"tone_amount": 0.85, "tone_shadow": Vector3(0.72, 0.98, 1.16), "tone_light": Vector3(1.14, 0.98, 0.82),
			"sky_top": Color("#1c3348"), "sky_bottom": Color("#c9966e"),
			"g_contrast": 1.18, "g_shoulder": 0.3,
		},
		{
			"ambient": Color("#1f4a6e"), "sky_top": Color("#020a12"), "sky_bottom": Color("#0e3344"),
			"background": Color("#061018"),
			"tone_amount": 0.9, "tone_shadow": Vector3(0.7, 1.02, 1.2), "tone_light": Vector3(1.16, 0.97, 0.8),
			"g_contrast": 1.2, "g_pivot": 0.1,
		},
	],
	# Golden: a late sunny afternoon. A lower, amber sun and blue shade by day, a real sunset
	# at dusk, a warm lamp-lit night.
	"golden": [
		{
			"sun": Color("#ffd296"), "sun_energy": 1.95, "sun_pitch": -38.0, "ambient": Color("#aab8e6"), "ambient_energy": 0.7,
			"background": Color("#bcd9ea"), "sky_colour": Vector3(0.74, 0.84, 0.9),
			"g_gain": Vector3(1.05, 1.0, 0.93), "g_contrast": 1.1, "g_shoulder": 0.3, "g_lift": Vector3(0.01, 0.006, 0.002),
			"g_vibrance": 0.1,
		},
		{
			"background": Color("#6a5a78"), "ambient": Color("#7a6c96"), "ambient_energy": 0.55,
			"sun": Color("#ffa868"), "sun_energy": 0.95, "sun_pitch": -12.0,
			"sky_colour": Vector3(0.78, 0.56, 0.5), "sky_top": Color("#34406e"), "sky_bottom": Color("#f2a46c"),
			"tone_amount": 0.7, "tone_shadow": Vector3(0.88, 0.86, 1.16), "tone_light": Vector3(1.14, 0.98, 0.82),
			"g_contrast": 1.08, "g_shoulder": 0.3,
		},
		{
			"ambient": Color("#4a3c6c"), "ambient_energy": 0.42, "sun": Color("#b0a4e0"), "sky_bottom": Color("#4a2440"),
			"tone_amount": 1.0, "tone_shadow": Vector3(0.96, 0.9, 1.1), "tone_light": Vector3(1.22, 1.0, 0.74),
			"g_contrast": 1.1, "g_pivot": 0.1, "g_lift": Vector3(0.006, 0.003, 0.0),
		},
	],
	# Neon: the vaporwave side turned up. Vivid day, a pink and violet dusk, a deep night where
	# the signs and windows burn.
	"neon": [
		{
			"saturation_share": 1.0, "ambient": Color("#b4bfee"), "ambient_energy": 0.62, "sun_energy": 1.36,
			"tone_amount": 0.5, "tone_shadow": Vector3(0.94, 0.94, 1.14), "tone_light": Vector3(1.05, 0.99, 0.96),
			"g_contrast": 1.16, "g_shoulder": 0.35, "g_vibrance": 0.3,
		},
		{
			"background": Color("#4a3a78"), "ambient": Color("#6a5aa0"),
			"sky_colour": Vector3(0.7, 0.42, 0.66), "sky_top": Color("#241a5c"), "sky_bottom": Color("#ff7aa6"),
			"tone_amount": 0.85, "tone_shadow": Vector3(0.82, 0.8, 1.34), "tone_light": Vector3(1.14, 0.92, 1.0),
			"glow": 0.6, "g_contrast": 1.15, "g_vibrance": 0.2,
		},
		{
			"ambient": Color("#2a1f86"), "ambient_energy": 0.36, "sun": Color("#8a8cff"), "sun_energy": 0.4,
			"sky_top": Color("#03020f"), "sky_bottom": Color("#4c1470"), "background": Color("#070418"),
			"tone_amount": 1.0, "tone_shadow": Vector3(0.74, 0.84, 1.46), "tone_light": Vector3(1.16, 0.9, 1.06),
			"glow": 1.0, "g_contrast": 1.28, "g_pivot": 0.1, "g_vibrance": 0.25,
		},
	],
	# Pastel: the soft diorama look of small stylised games. Lifted, slightly blue blacks, low
	# contrast, pale haze, colours kept clear by vibrance rather than saturation.
	"pastel": [
		{
			"background": Color("#c6deec"), "ambient": Color("#c2cde4"), "ambient_energy": 0.78, "sun": Color("#fff0dc"),
			"sun_energy": 1.35, "g_gain": Vector3(1.03, 1.0, 0.98), "g_contrast": 0.96, "g_shoulder": 0.35,
			"g_lift": Vector3(0.016, 0.019, 0.028), "g_vibrance": 0.4,
		},
		{
			"background": Color("#5c6488"), "ambient": Color("#7078a0"), "ambient_energy": 0.56,
			"sky_top": Color("#414a78"), "sky_bottom": Color("#d8b4c4"),
			"tone_amount": 0.6, "g_contrast": 0.94, "g_lift": Vector3(0.016, 0.018, 0.034), "g_vibrance": 0.15,
		},
		{
			"ambient": Color("#3c44a0"), "ambient_energy": 0.5, "sky_top": Color("#0a0c2c"), "sky_bottom": Color("#3a2a70"),
			"tone_amount": 0.7, "g_contrast": 0.96, "g_pivot": 0.1, "g_lift": Vector3(0.008, 0.01, 0.026), "g_vibrance": 0.15,
		},
	],
}


## A look's [day, dusk, night] overrides ("warsaw" is Natural with Golden's sunset; unknown
## names and the research's "current": classic).
static func looks_of(name: String) -> Array:
	if name == "warsaw":
		return [LOOKS["natural"][0], LOOKS["golden"][1], LOOKS["natural"][2]]
	return LOOKS.get(name, LOOKS["classic"])


## The three base looks with `name`'s overrides on top.
static func apply(base: Array, name: String) -> Array:
	var over: Array = looks_of(name)
	var out: Array = []
	for i in 3:
		var look: Dictionary = (base[i] as Dictionary).duplicate(true)
		look.merge(NEUTRAL)
		look.merge(over[i], true)
		out.append(look)
	return out
