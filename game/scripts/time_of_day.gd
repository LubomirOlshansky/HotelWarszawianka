extends Node
## Day, Dusk and Night (and loop MW-3's Dawn): the sun (or moon), the ambient light, the sky behind the
## diorama, the colour grade and the city's lights, blended over 1.5 s when the
## mode changes. The city's shaders read three global uniforms (project.godot
## [shader_globals]): lights_on, daylight and sky_colour. Day is the original
## look exactly: lights off, no grade, no sky gradient, no glow.
##
## v0.9: Live, a fourth mode: the real sun over Warsaw (52.23 N, 21.01 E) for the
## device's clock (or --clock=HH:MM --date=YYYYMMDD, Warsaw time), from the NOAA
## solar-position formulas. The three looks are blended by the sun's elevation (Day
## above 10 degrees, Dusk round sunset, Night below -10) and the sun turns with its
## real azimuth; its pitch is held between 20 and 55 degrees so midday still has
## shadows and a low sun doesn't throw them across the whole map. Rechecked every
## 10 s. The weather (weather.gd) greys the light and softens the shadows in rain;
## the quality setting can switch shadows and glow off.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

signal changed(mode: int)
## The lights went on (lights_on > 0) or off: night-only nodes show or hide.
signal lights_switched(on: bool)

## Loop MW-3: DAWN (Świt) after LIVE, so the saved and the existing indices keep their meaning.
enum { DAY, DUSK, NIGHT, LIVE, DAWN }
const NAMES := ["Day", "Dusk", "Night", "Live", "Dawn"]
const BLEND := 1.5
const LAT := 52.23
const LON := 21.01
## The sun's pitch in Live (degrees above the horizon), so shadows stay readable.
const LIVE_PITCH := Vector2(20.0, 55.0)
## Loop MW-3 (vision.md 4.5): the Dawn look is Dusk's palette with the sun in the east-north-east
## (azimuth 67.5 degrees: yaw = 180 - azimuth, as in Live), no new shader.
const DAWN_SUN_YAW := 112.5

## Each look. Colours are sRGB except the post-pass values (linear multipliers).
## saturation_share (the look loop, 2026-10-28): how much of the visual style's saturation
## boost the post pass applies: none by day (calmer day colours), all of it at dusk and night.
const LOOKS := [
	{
		"background": Color("#a8cde6"), "ambient": Color("#b6c6db"), "ambient_energy": 0.7,
		"sun": Color("#ffe8c8"), "sun_energy": 1.25, "sun_pitch": -50.0, "sun_yaw": -20.0, "shadows": 1.0,
		"lights_on": 0.0, "daylight": 1.0, "sky_colour": Vector3(0.66, 0.8, 0.91),
		"tone_amount": 0.0, "tone_shadow": Vector3(1, 1, 1), "tone_light": Vector3(1, 1, 1),
		"sky_amount": 0.0, "sky_top": Color("#a8cde6"), "sky_bottom": Color("#a8cde6"), "stars": 0.0,
		"glow": 0.0, "saturation_share": 0.0,
	},
	{
		# The dusk loop (2026-10-31, the user's photos of Śródmieście at 16:20 in late October): the
		# blue hour under an overcast sky, not a sunset. A slate-blue sky, cool flat light and no
		# shadows (the sun is behind the clouds), so the lit windows, the signs and the floodlit
		# Palace carry the picture; a soft glow, as at night (no shadow pass to pay for it).
		"background": Color("#47506e"), "ambient": Color("#5f6a8c"), "ambient_energy": 0.52,
		"sun": Color("#d9b8a0"), "sun_energy": 0.55, "sun_pitch": -16.0, "sun_yaw": -40.0, "shadows": 0.0,
		"lights_on": 0.8, "daylight": 0.36, "sky_colour": Vector3(0.46, 0.5, 0.63),
		"tone_amount": 0.7, "tone_shadow": Vector3(0.8, 0.86, 1.24), "tone_light": Vector3(1.06, 0.98, 0.9),
		"sky_amount": 1.0, "sky_top": Color("#2a3150"), "sky_bottom": Color("#a49aa6"), "stars": 0.0,
		"glow": 0.4, "saturation_share": 0.8,
	},
	{
		"background": Color("#0a0b22"), "ambient": Color("#33378a"), "ambient_energy": 0.44,
		"sun": Color("#8ea2ff"), "sun_energy": 0.46, "sun_pitch": -52.0, "sun_yaw": -35.0, "shadows": 0.0,
		"lights_on": 1.0, "daylight": 0.0, "sky_colour": Vector3(0.12, 0.13, 0.32),
		"tone_amount": 0.85, "tone_shadow": Vector3(0.8, 0.92, 1.3), "tone_light": Vector3(1.08, 0.94, 0.98),
		"sky_amount": 1.0, "sky_top": Color("#04051a"), "sky_bottom": Color("#2c1658"), "stars": 1.0,
		"glow": 0.75, "saturation_share": 1.0,
	},
]

var mode := DAY
var env: Environment
var sun: DirectionalLight3D
var post: ShaderMaterial
## The current blended look, readable by anything that wants it (car lights, sound).
var lights_on := 0.0
var daylight := 1.0
## Quality (main.gd): shadows and the night glow may be switched off.
var shadows_allowed := true
var glow_allowed := true
## Live: a fixed Warsaw clock to start from (--clock / --date, as Unix seconds UTC),
## else the device's clock; the sun's elevation and azimuth now (degrees).
var clock_start := -1.0
var sun_elevation := 0.0
var sun_azimuth := 180.0
var _from: Dictionary
var _to: Dictionary
var _t := 1.0
var _looks: Array = []
var _lit := false
var _rain := 0.0
var _live_wait := 0.0
var _started_ms := Time.get_ticks_msec()
## Loop MW-5: when the current look was set (the fixed looks' clock runs on from there).
var _look_ms := Time.get_ticks_msec()
## Loop MW-3: --clock=HH:MM with a fixed look: the hour its clock starts from (-1: the look's own,
## vision.md 4.5). Cleared when the look changes.
var fixed_start := -1.0
## Landmarks 0.3: `--solo` shots keep this plain background (alpha 0: the look's own sky).
var plain_background := Color(0, 0, 0, 0)


## `day_pitch` is the day sun's pitch (--sun=).
func setup(environment: Environment, light: DirectionalLight3D, post_material: ShaderMaterial, day_pitch: float) -> void:
	env = environment
	sun = light
	post = post_material
	_looks = LOOKS.duplicate(true)
	_looks[DAY]["sun_pitch"] = day_pitch
	# Loop MW-3: Live has no entry of its own (it blends the three); Dawn is Dusk's with the sun
	# in the east-north-east.
	_looks.append({})
	var dawn: Dictionary = _looks[DUSK].duplicate()
	dawn["sun_yaw"] = DAWN_SUN_YAW
	_looks.append(dawn)
	_to = _looks[mode]
	_from = _to
	_apply(_to)


static func parse(text: String) -> int:
	return maxi(0, NAMES.map(func(n: String) -> String: return n.to_lower()).find(text.to_lower()))


## Switches to a mode, blending over BLEND seconds unless `instant`.
func set_mode(m: int, instant := false) -> void:
	mode = m % NAMES.size()
	_look_ms = Time.get_ticks_msec()
	fixed_start = -1.0
	_from = _current()
	_to = _live_look() if mode == LIVE else _looks[mode]
	_live_wait = 10.0
	_t = 1.0 if instant else 0.0
	if instant:
		_apply(_to)
	changed.emit(mode)


## The beta trailer (trailer.gd): a held look on the way day -> golden hour -> dusk -> night, `k`
## 0..3 (0 day, 1 golden, 2 dusk, 3 night), applied at once and kept (no blend runs after it). The
## mode is left as it was; set_mode() hands the look back to the game.
func scrub(k: float) -> void:
	var stops: Array = [_looks[DAY], golden_look(), _looks[DUSK], _looks[NIGHT]]
	k = clampf(k, 0.0, 3.0)
	var i := mini(int(k), 2)
	_from = stops[i]
	_to = _blend(stops[i], stops[i + 1], smoothstep(0.0, 1.0, k - float(i)))
	_t = 1.0
	_apply(_to)


## The golden hour for the trailer's time scrub only: the day look with a low, warm sun from the
## west, a warm sky band and the first lights coming on. Not a mode of its own.
func golden_look() -> Dictionary:
	var g: Dictionary = _looks[DAY].duplicate()
	g["background"] = Color("#e9b98f")
	g["ambient"] = Color("#d6b49a")
	g["ambient_energy"] = 0.62
	g["sun"] = Color("#ffb066")
	g["sun_energy"] = 1.1
	g["sun_pitch"] = -14.0
	g["sun_yaw"] = -70.0
	g["lights_on"] = 0.25
	g["daylight"] = 0.75
	g["sky_colour"] = Vector3(0.86, 0.72, 0.6)
	g["tone_amount"] = 0.45
	g["tone_shadow"] = Vector3(0.9, 0.9, 1.12)
	g["tone_light"] = Vector3(1.12, 0.98, 0.84)
	g["sky_amount"] = 1.0
	g["sky_top"] = Color("#6d86b8")
	g["sky_bottom"] = Color("#ffc58a")
	g["glow"] = 0.2
	g["saturation_share"] = 0.5
	return g


func next() -> void:
	set_mode(mode + 1)


## Rain (weather.gd, 0..1): greyer light, softer shadows. Applied on top of the look.
func set_weather(amount: float) -> void:
	_rain = amount
	_apply(_current())


## Re-applies the current look (after the quality changed).
func refresh() -> void:
	_apply(_current())


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	if mode == LIVE:
		_live_wait -= dt
		if _live_wait <= 0.0:
			_live_wait = 10.0
			_to = _live_look()
			if _t >= 1.0:
				_apply(_to)
	if _t >= 1.0:
		return
	_t = minf(_t + dt / BLEND, 1.0)
	_apply(_current())


func _current() -> Dictionary:
	if _t >= 1.0:
		return _to
	return _blend(_from, _to, smoothstep(0.0, 1.0, _t))


static func _blend(from: Dictionary, to: Dictionary, k: float) -> Dictionary:
	var out := {}
	for key in to:
		var a = from[key]
		var b = to[key]
		if a is float:
			out[key] = lerpf(a, b, k)
		else:
			out[key] = a.lerp(b, k)
	return out


## Live: the three looks blended by the real sun's elevation, the sun turned to its
## azimuth (the light shines along -Z: yaw = 180 - azimuth; pitch = -elevation).
func _live_look() -> Dictionary:
	var sp := sun_position(now_utc())
	sun_elevation = sp.x
	sun_azimuth = sp.y
	var e := sp.x
	var day: Dictionary = _looks[DAY].duplicate()
	var dusk: Dictionary = _looks[DUSK].duplicate()
	day["sun_yaw"] = 180.0 - sp.y
	day["sun_pitch"] = -clampf(e, LIVE_PITCH.x, LIVE_PITCH.y)
	dusk["sun_yaw"] = 180.0 - sp.y
	if e >= 10.0:
		return day
	if e >= -2.0:
		return _blend(day, dusk, smoothstep(10.0, -2.0, e))
	if e >= -10.0:
		return _blend(dusk, _looks[NIGHT], smoothstep(-2.0, -10.0, e))
	return _looks[NIGHT].duplicate()


## Now, as Unix seconds UTC: the device's clock, or the --clock/--date start plus the
## time since the game started.
func now_utc() -> float:
	if clock_start >= 0.0:
		return clock_start + (Time.get_ticks_msec() - _started_ms) * 0.001
	return Time.get_unix_time_from_system()


## Loop MW-5: the game clock, {hour: 0..24 (fractional), weekday: 1 Monday .. 7 Sunday}. Live:
## the Warsaw clock (the device's, or --clock / --date). The fixed looks have the times of
## vision.md 4.5 (Day 14:00, Dusk 19:30, Night 01:30, loop MW-3's Dawn 05:45; --clock= moves the start) on
## "always Friday" (Open Question 4: the night is Friday's, so 01:30 is early Saturday), and run
## on in real time from the moment the look was set. PÓŁNOC FM's hours and the city's sounds
## (club hours, the bells, the busker, the 02:00 beat) read it.
func local_clock() -> Dictionary:
	if mode == LIVE:
		var t := now_utc()
		var d := Time.get_datetime_dict_from_unix_time(int(t) + warsaw_offset(t))
		var wd := int(d["weekday"])
		return {"hour": float(d["hour"]) + float(d["minute"]) / 60.0 + float(d["second"]) / 3600.0,
				"weekday": 7 if wd == 0 else wd}
	return look_clock(NAMES[mode], (Time.get_ticks_msec() - _look_ms) / 3600000.0, fixed_start)


## A fixed look's clock `elapsed_h` hours after it was set (see local_clock); loop MW-3: `from`
## (0-24, --clock=) replaces the look's own start hour.
static func look_clock(look: String, elapsed_h: float, from := -1.0) -> Dictionary:
	var start: float = {"Day": 14.0, "Dusk": 19.5, "Night": 1.5, "Dawn": 5.75}.get(look, 14.0)
	if from >= 0.0:
		start = fmod(from, 24.0)
	# hours since Friday 00:00: the evening looks are Friday's, the small hours Saturday's
	var abs_h := (start if start >= 12.0 else start + 24.0) + elapsed_h
	return {"hour": fmod(abs_h, 24.0), "weekday": (4 + int(floor(abs_h / 24.0))) % 7 + 1}


## "Live 13:05": Warsaw time for the TIME button.
func live_label() -> String:
	var t := now_utc()
	var local := Time.get_datetime_dict_from_unix_time(int(t) + warsaw_offset(t))
	return "Live %02d:%02d" % [local["hour"], local["minute"]]


## Warsaw's offset from UTC in seconds: CET, or CEST from the last Sunday of March to
## the last Sunday of October (both at 01:00 UTC).
static func warsaw_offset(unix_utc: float) -> int:
	var year: int = Time.get_datetime_dict_from_unix_time(int(unix_utc))["year"]
	var start := _last_sunday(year, 3)
	var end := _last_sunday(year, 10)
	return 7200 if unix_utc >= start and unix_utc < end else 3600


static func _last_sunday(year: int, month: int) -> float:
	var t := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": 31, "hour": 1, "minute": 0, "second": 0})
	var weekday: int = Time.get_datetime_dict_from_unix_time(int(t))["weekday"]
	return t - weekday * 86400.0


## A Warsaw wall-clock time ("HH:MM", date YYYYMMDD or 0 for today) as Unix seconds UTC.
static func warsaw_to_utc(clock: String, date: int) -> float:
	var hm := clock.split(":")
	var today := Time.get_datetime_dict_from_system(true)
	var d := {"year": date / 10000 if date > 0 else today["year"], "month": (date / 100) % 100 if date > 0 else today["month"],
			"day": date % 100 if date > 0 else today["day"], "hour": int(hm[0]), "minute": int(hm[1]) if hm.size() > 1 else 0, "second": 0}
	var as_utc := Time.get_unix_time_from_datetime_dict(d)
	return as_utc - warsaw_offset(as_utc - 3600.0)


## The sun over Warsaw at a moment (Unix seconds UTC): Vector2(elevation, azimuth) in
## degrees, azimuth clockwise from north. NOAA's general solar position formulas
## (fractional year, equation of time, declination, hour angle); good to about a
## tenth of a degree, which is plenty for a shadow.
static func sun_position(unix_utc: float) -> Vector2:
	var dt := Time.get_datetime_dict_from_unix_time(int(unix_utc))
	var year: int = dt["year"]
	var jan1 := Time.get_unix_time_from_datetime_dict({"year": year, "month": 1, "day": 1, "hour": 0, "minute": 0, "second": 0})
	var doy := floorf((unix_utc - jan1) / 86400.0) + 1.0
	var hours := fmod(unix_utc, 86400.0) / 3600.0
	var days := 366.0 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 365.0
	var g := TAU / days * (doy - 1.0 + (hours - 12.0) / 24.0)
	var eqtime := 229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g) - 0.014615 * cos(2.0 * g) - 0.040849 * sin(2.0 * g))
	var decl := 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2.0 * g) + 0.000907 * sin(2.0 * g) \
			- 0.002697 * cos(3.0 * g) + 0.00148 * sin(3.0 * g)
	var true_solar := hours * 60.0 + eqtime + 4.0 * LON
	var ha := deg_to_rad(true_solar / 4.0 - 180.0)
	var lat := deg_to_rad(LAT)
	var cos_zenith := clampf(sin(lat) * sin(decl) + cos(lat) * cos(decl) * cos(ha), -1.0, 1.0)
	var elevation := 90.0 - rad_to_deg(acos(cos_zenith))
	var azimuth := fposmod(rad_to_deg(atan2(sin(ha), cos(ha) * sin(lat) - tan(decl) * cos(lat))) + 180.0, 360.0)
	return Vector2(elevation, azimuth)


func _apply(look: Dictionary) -> void:
	var r := _rain
	var grey := r * float(look["daylight"])
	env.background_color = (look["background"] as Color).lerp(Color("#8d97a4"), 0.6 * grey)
	if plain_background.a > 0.0:
		env.background_color = plain_background
	# The land past the map's edge fades into the background (map_edge.gd), linear as emitted.
	var bg := env.background_color.srgb_to_linear()
	RenderingServer.global_shader_parameter_set("edge_haze", Vector3(bg.r, bg.g, bg.b))
	env.ambient_light_color = (look["ambient"] as Color).lerp(Color("#aab1bd"), 0.4 * grey)
	env.ambient_light_energy = look["ambient_energy"] * (1.0 + 0.18 * r)
	sun.light_color = look["sun"]
	sun.light_energy = look["sun_energy"] * (1.0 - 0.45 * r)
	sun.rotation_degrees = Vector3(look["sun_pitch"], look["sun_yaw"], 0.0)
	sun.shadow_enabled = look["shadows"] > 0.5 and shadows_allowed
	sun.shadow_opacity = 1.0 - 0.5 * r
	lights_on = look["lights_on"]
	daylight = look["daylight"]
	RenderingServer.global_shader_parameter_set("lights_on", lights_on)
	RenderingServer.global_shader_parameter_set("daylight", look["daylight"])
	RenderingServer.global_shader_parameter_set("sky_colour", look["sky_colour"])
	post.set_shader_parameter("tone_amount", look["tone_amount"])
	post.set_shader_parameter("tone_shadow", look["tone_shadow"])
	post.set_shader_parameter("tone_light", look["tone_light"])
	post.set_shader_parameter("sky_amount", look["sky_amount"])
	post.set_shader_parameter("sky_top", _linear3(look["sky_top"]))
	post.set_shader_parameter("sky_bottom", _linear3(look["sky_bottom"]))
	post.set_shader_parameter("stars", look["stars"])
	post.set_shader_parameter("saturation_share", look["saturation_share"])
	var glow: float = look["glow"]
	env.glow_enabled = glow > 0.01 and glow_allowed
	if env.glow_enabled:
		env.glow_intensity = glow * 1.4
		env.glow_strength = 1.0
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 0.62
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var lit := lights_on > 0.001
	if lit != _lit:
		_lit = lit
		lights_switched.emit(lit)


## A vec3 uniform takes a Vector3: an sRGB colour, made linear for the post pass.
static func _linear3(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	return Vector3(l.r, l.g, l.b)
