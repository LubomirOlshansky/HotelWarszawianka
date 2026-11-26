extends Node
## Day, Dusk and Night (and loop MW-3's Dawn): the sun (or moon), the ambient light, the sky behind the
## diorama, the colour grade and the city's lights, blended over 1.5 s when the
## mode changes. The city's shaders read three global uniforms (project.godot
## [shader_globals]): lights_on, daylight and sky_colour. The values below are the "classic"
## look (by day: lights off, no grade, no sky gradient, no glow); the look the player picked
## (grades.gd, "warsaw" by default) lays its overrides on top.
##
## v0.9: Live, a fourth mode: the real sun over Warsaw (52.23 N, 21.01 E) for the
## device's clock (or --clock=HH:MM --date=YYYYMMDD, Warsaw time), from the NOAA
## solar-position formulas. The three looks are blended by the sun's elevation (Day
## above 10 degrees, Dusk round sunset, Night below -10) and the sun turns with its
## real azimuth; its pitch is held between 20 and 55 degrees so midday still has
## shadows and a low sun doesn't throw them across the whole map. Rechecked every
## 10 s. The weather (weather.gd) greys the light and softens the shadows in rain;
## the quality setting can switch shadows and glow off.
##
## F 2026-11-19, the game clock (`start_clock`): one clock for the whole game, no Live and no
## fixed looks in a normal launch. It runs at pacing.json time.speed (30x: a game day in 48 real
## minutes) from 14:00 on this week's Friday; the sun stands where it would over Warsaw on that
## date (Live's machinery, so winter days are short and summer ones long), and the hour and a half
## round sunrise and sunset lasts time.golden times longer (2.5x, like GTA's golden hour), taken
## from midday and midnight (`solar_shift`). Between the full day and the blue hour a golden look
## (the opening's sunrise, the sun turned to its azimuth) holds the low sun and long shadows. The
## light is worked out every time.look_every real seconds. Picking a look (settings, the map's
## clock, the N key, GameTime.jump) moves the clock forward to that look's hour (`set_hour`).
## Test runs keep the fixed looks unless --game-clock (dev_flags.gd `game_clock`).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

signal changed(mode: int)
## The lights went on (lights_on > 0) or off: night-only nodes show or hide.
signal lights_switched(on: bool)

const Pacer := preload("res://scripts/pacer.gd")

## Loop MW-3: DAWN (Świt) after LIVE, so the saved and the existing indices keep their meaning.
enum { DAY, DUSK, NIGHT, LIVE, DAWN }
## The Day look's hour, where a new game's clock starts.
const DAY_START_HOUR := 11.0
const NAMES := ["Day", "Dusk", "Night", "Live", "Dawn"]
const BLEND := 1.5
const LAT := 52.23
const LON := 21.01
## The sun's pitch in Live (degrees above the horizon), so shadows stay readable.
const LIVE_PITCH := Vector2(20.0, 55.0)
## Loop MW-3 (vision.md 4.5): the Dawn look is Dusk's palette with the sun in the east-north-east
## (azimuth 67.5 degrees: yaw = 180 - azimuth, as in Live), no new shader.
const DAWN_SUN_YAW := 112.5
## The morning of the opening flight (F, 2026-11-16, docs/design/opening-flyover.md): on a new
## game the city wakes up while the camera flies in. The flight's share (0..1) at which each look
## is reached, and in between one look blends into the next: Night, held while the host says
## "Dzień dobry, Warszawo!"; Dawn's blue hour by her weather line (the lamps fading, the windows
## going dark one by one); SUNRISE (low gold light from the east, long shadows) by the
## Marszałkowska line; the Day look by her last sentence. The lights only go down and the daylight
## only up on the way, and the last frame is the Day look itself.
const WAKE_KEYS := [[0.0, NIGHT], [0.15, NIGHT], [0.42, DAWN], [0.62, SUNRISE_LOOK], [0.88, DAY]]
## Where the sunrise sits in the looks (after Dawn; no mode has it).
const SUNRISE_LOOK := 5
## The sunrise: Dawn's look (the grade's sunset, the sun in the east-north-east) with the sun out:
## shadows on, the lights nearly off, brighter and warmer. Only the opening uses it.
const SUNRISE := {
	"shadows": 1.0, "lights_on": 0.15, "daylight": 0.72, "sun": Color("#ffbc7a"), "sun_energy": 1.85,
	"sun_pitch": -16.0, "sun_yaw": 60.0, "ambient_energy": 0.62, "glow": 0.15, "stars": 0.0,
}
## A tap that skips the flight: the Day look comes in over this many seconds (the camera takes
## camera_shots.gd SKIP_TIME to the car).
const WAKE_SKIP := 1.0

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
## The colour look (grades.gd: Settings → Kolory, or --grade=NAME).
var grade := "warsaw"
var _day_pitch := -50.0
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
## The opening's morning: the seconds into it (-1: none), its length, and the seconds the current
## blend takes (BLEND, or WAKE_SKIP after a skip).
var _wake_t := -1.0
var _wake_len := 0.0
var _blend_len := BLEND
var _lit := false
var _rain := 0.0
var _live_wait := 0.0
var _started_ms := Time.get_ticks_msec()
## Loop MW-5: when the current look was set (the fixed looks' clock runs on from there).
var _look_ms := Time.get_ticks_msec()
## Loop MW-3: --clock=HH:MM with a fixed look: the hour its clock starts from (-1: the look's own,
## vision.md 4.5). Cleared when the look changes.
var fixed_start := -1.0
## F 2026-11-19: the game clock is on (`start_clock`); it runs `speed` game seconds a real second
## and stands at `_game_utc` (Unix seconds UTC, read by now_utc). Sunrise and sunset (local hours)
## per game day, worked out once a day.
var game_clock := false
var speed := 1.0
## F 2026-11-26 (docs/design/story-structure.md, "The clock"): while a story chapter or a questline
## runs the clock goes at real time (1 game second a real second), so a 3-minute boat race started
## at 21:00 ends at 21:03, not in the dark at 22:30 (pacing.json time.hold_speed: 1; 3 if real time
## feels frozen on the phone). Set by main.gd's story tick through
## game_time.gd `held_for`; jobs, rides, rival races and rescues leave it off. A flag, not a write
## to `speed`, so Promo mode's speeds (promo_mode.gd) come back untouched.
var held := false
var hold_speed := 1.0
var _game_utc := 0.0
var _golden := 1.0
var _look_every := 10.0
var _sun_day := -1
var _sun_times := Vector2(6.0, 18.0)
## Landmarks 0.3: `--solo` shots keep this plain background (alpha 0: the look's own sky).
var plain_background := Color(0, 0, 0, 0)


## `day_pitch` is the day sun's pitch (--sun=).
func setup(environment: Environment, light: DirectionalLight3D, post_material: ShaderMaterial, day_pitch: float) -> void:
	env = environment
	sun = light
	post = post_material
	_day_pitch = day_pitch
	_build_looks()
	_to = _looks[mode]
	_from = _to
	_apply(_to)


## The colour look (grades.gd), applied at once; the mode and its clock stay as they are.
func set_grade(name: String) -> void:
	grade = name
	_build_looks()
	_to = _live_look() if mode == LIVE else _looks[mode]
	_from = _to
	_t = 1.0
	_apply(_wake_look() if waking() else _to)


## The looks for this grade: Day, Dusk, Night, then Live (no entry of its own: it blends the
## three) and Dawn (loop MW-3: Dusk's with the sun in the east-north-east).
func _build_looks() -> void:
	_looks = build_looks(grade, _day_pitch)


## The looks of `grade`, indexed by mode (Live's entry empty), then the opening's sunrise
## (SUNRISE_LOOK). Static so check_opening.gd builds the same ones.
static func build_looks(grade_name: String, day_pitch: float) -> Array:
	var looks := Grades.apply(LOOKS, grade_name)
	if not Grades.looks_of(grade_name)[DAY].has("sun_pitch"):
		looks[DAY]["sun_pitch"] = day_pitch
	looks.append({})
	var dawn: Dictionary = looks[DUSK].duplicate()
	dawn["sun_yaw"] = DAWN_SUN_YAW
	looks.append(dawn)
	var sunrise := dawn.duplicate()
	sunrise.merge(SUNRISE, true)
	looks.append(sunrise)
	return looks


static func parse(text: String) -> int:
	return maxi(0, NAMES.map(func(n: String) -> String: return n.to_lower()).find(text.to_lower()))


## Switches to a mode, blending over BLEND seconds unless `instant`.
func set_mode(m: int, instant := false) -> void:
	if game_clock:
		if m % NAMES.size() != LIVE:
			set_hour(look_hour(m % NAMES.size()), instant)
		return
	_wake_t = -1.0
	_blend_len = BLEND
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


func next() -> void:
	if game_clock:
		var order := [DAWN, DAY, DUSK, NIGHT]
		set_mode(order[(order.find(look_mode()) + 1) % order.size()])
		return
	set_mode(mode + 1)


## F 2026-11-19: the game clock starts at `hour` (0-24; -1: look `m`'s, `look_hour`) on `date`
## (YYYYMMDD; 0: the Friday of this week, so the stories' Friday holds) and runs from here (main.gd,
## a normal launch or --game-clock). The look follows the sun at once.
func start_clock(date := 0, m := DAY, hour := -1.0) -> void:
	if date <= 0:
		var today := Time.get_unix_time_from_system()
		var d := Time.get_datetime_dict_from_unix_time(int(today) + warsaw_offset(today))
		var back := (int(d["weekday"]) - 5 + 7) % 7
		var fri := Time.get_datetime_dict_from_unix_time(int(today) + warsaw_offset(today) - back * 86400)
		date = int(fri["year"]) * 10000 + int(fri["month"]) * 100 + int(fri["day"])
	game_clock = true
	speed = Pacer.num("time", "speed")
	hold_speed = Pacer.num("time", "hold_speed")
	_golden = Pacer.num("time", "golden")
	_look_every = Pacer.num("time", "look_every")
	mode = LIVE
	_game_utc = warsaw_to_utc("12:00", date)
	_sun_day = -1
	var h := hour if hour >= 0.0 else look_hour(m)
	if m == DAY and h < 12.0:
		# The Day start (11:00, F 2026-11-20) is a morning: from the noon base `set_hour` would move
		# it to tomorrow, a Saturday. Base the day at midnight instead; the other looks keep noon.
		_game_utc = warsaw_to_utc("00:00", date)
		_sun_day = -1
	set_hour(h, true)


## The clock moves forward to `hour` (0-24) today, or tomorrow if that hour has passed (a few
## minutes back still counts as now): the look blends in over BLEND s unless `instant`. Without
## the game clock: the look that fits the hour (`look_at`), its clock started there (loop MW-3).
func set_hour(hour: float, instant := false) -> void:
	hour = fposmod(hour, 24.0)
	if not game_clock:
		set_mode(parse(look_at(hour)), instant)
		fixed_start = hour
		return
	_wake_t = -1.0
	_blend_len = BLEND
	var off := warsaw_offset(_game_utc)
	var local := _game_utc + off
	var target := floorf(local / 86400.0) * 86400.0 + hour * 3600.0
	if target < local - 600.0:
		target += 86400.0
	_game_utc = target - off
	_from = _current()
	_to = _live_look()
	_live_wait = _look_every
	_t = 1.0 if instant else 0.0
	if instant:
		_apply(_to)
	changed.emit(mode)


## Promo Mode (promo_mode.gd, through game_time.gd `nudge`): the clock moves by `minutes`, back
## as well as forward (set_hour only goes forward), and the light follows at once. Without the game
## clock: the look that fits the new hour.
func shift_clock(minutes: float) -> void:
	if not game_clock:
		set_hour(float(local_clock()["hour"]) + minutes / 60.0, true)
		return
	_game_utc += minutes * 60.0
	_wake_t = -1.0
	_from = _current()
	_to = _live_look()
	_live_wait = _look_every
	_t = 1.0
	_apply(_to)
	changed.emit(mode)


## The fixed look whose light fits `hour` (game_time.gd `look_for` asks it): Dawn 5-8, Day to
## 18:30, Dusk to 20:30, else Night.
static func look_at(hour: float) -> String:
	if hour >= 5.0 and hour < 8.0:
		return "Dawn"
	if hour >= 8.0 and hour < 18.5:
		return "Day"
	if hour >= 18.5 and hour < 20.5:
		return "Dusk"
	return "Night"


## The hour a look stands for on the game clock's date: Dawn the sunrise, Dusk the sunset (the
## golden hour turning blue), Night 23:00, Day DAY_START_HOUR (11:00, F 2026-11-20: the game starts at
## 11 from the first frame, no jump to 14) kept clear of the golden hours (a winter day
## is short). Without the game clock, the fixed looks' hours.
func look_hour(m: int) -> float:
	if not game_clock:
		return float([11.0, 19.5, 1.5, 14.0, 5.75][m % NAMES.size()])
	var st := sun_times()
	var g := _band().y
	match m:
		DAWN:
			return st.x
		DUSK:
			return st.y
		NIGHT:
			return 23.0
	var lo := st.x + g + 0.5
	var hi := st.y - g - 1.0
	return clampf(DAY_START_HOUR, lo, hi) if lo <= hi else (st.x + st.y) * 0.5


## The look for the menus and the stories: the mode, or on the game clock the look the sun makes
## now (Day above 10 degrees, Dawn or Dusk to 6 below by the morning or the afternoon, Night).
func look_mode() -> int:
	if not game_clock:
		return mode
	if sun_elevation >= 10.0:
		return DAY
	if sun_elevation >= -6.0:
		return DAWN if sun_azimuth < 180.0 else DUSK
	return NIGHT


## Sunrise and sunset of the game clock's day (Warsaw local hours, the sun's rim at -0.833
## degrees), worked out once a day.
func sun_times() -> Vector2:
	var off := warsaw_offset(_game_utc)
	var day := int(floorf((_game_utc + off) / 86400.0))
	if day != _sun_day:
		_sun_day = day
		_sun_times = sun_times_on(day * 86400.0 - off)
	return _sun_times


## Sunrise and sunset (local hours after `midnight_utc`, the local midnight as Unix UTC): the
## crossings of -0.833 degrees, found on a 10-minute walk and narrowed by halving.
static func sun_times_on(midnight_utc: float) -> Vector2:
	var out := Vector2(6.0, 18.0)
	var found := 0
	var prev := sun_position(midnight_utc).x + 0.833
	for i in range(1, 145):
		var t := midnight_utc + i * 600.0
		var e := sun_position(t).x + 0.833
		if (prev < 0.0) != (e < 0.0):
			var a := t - 600.0
			var b := t
			for _k in 12:
				var mid := (a + b) * 0.5
				if (sun_position(mid).x + 0.833 < 0.0) == (prev < 0.0):
					a = mid
				else:
					b = mid
			var h := ((a + b) * 0.5 - midnight_utc) / 3600.0
			if prev < 0.0:
				out.x = h
			else:
				out.y = h
			found += 1
		prev = e
	return out if found >= 2 else Vector2(6.0, 18.0)


## The golden band round sunrise and sunset: Vector2(real hours each side, game hours each side).
## 0.75 real hours each side last `_golden` times longer, kept short enough that the day and the
## night between them still last an hour.
func _band() -> Vector2:
	var st := sun_times()
	var day := st.y - st.x
	var g := minf(0.75 * _golden, minf((day - 1.0) * 0.5, (23.0 - day) * 0.5))
	return Vector2(minf(0.75, g), maxf(g, 0.0))


## Game time is not the sun's time: the long golden hour (F 2026-11-19, like GTA). How many hours
## the sun stands ahead of (or behind) the game clock at local hour `h`: the clock's sunrise and
## sunset are the real ones, the band round each is stretched and the rest squeezed, piecewise
## straight. Static and pure (check_game_time.gd).
static func solar_shift(h: float, sunrise: float, sunset: float, band: Vector2) -> float:
	var b := band.x
	var g := band.y
	if g <= b or b <= 0.0:
		return 0.0
	var d := sunset - sunrise
	var x := fposmod(h - sunrise, 24.0)
	var knots := [[0.0, 0.0], [g, b], [d - g, d - b], [d, d], [d + g, d + b], [24.0 - g, 24.0 - b], [24.0, 24.0]]
	for i in range(knots.size() - 1):
		var a: Array = knots[i]
		var c: Array = knots[i + 1]
		if x <= float(c[0]):
			var k := (x - float(a[0])) / maxf(float(c[0]) - float(a[0]), 0.0001)
			return lerpf(float(a[1]), float(c[1]), k) - x
	return 0.0


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
	if _wake_t >= 0.0:
		_wake_t += dt
		if _wake_t >= _wake_len:
			_wake_t = -1.0
			# the game clock's look comes in from the morning's last (the Day look) over BLEND s
			_from = _looks[DAY]
			_t = 0.0 if game_clock else 1.0
			_apply(_current())
		else:
			_apply(_wake_look())
		return
	if game_clock:
		_game_utc += dt * (hold_speed if held else speed)
	if mode == LIVE:
		_live_wait -= dt
		if _live_wait <= 0.0:
			_live_wait = _look_every
			_to = _live_look()
			if _t >= 1.0:
				_apply(_to)
	if _t >= 1.0:
		return
	_t = minf(_t + dt / _blend_len, 1.0)
	_apply(_current())


func _current() -> Dictionary:
	if waking():
		return _wake_look()
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


## The opening's morning (WAKE_KEYS): from Night to the Day look over `seconds`, the night at once.
## Only from the Day look (a normal launch's), so a --time= run keeps its look; false otherwise.
func wake(seconds: float) -> bool:
	if (mode != DAY and not game_clock) or seconds <= 0.0:
		return false
	_wake_len = seconds
	_wake_t = 0.0
	_from = _looks[DAY]
	_to = _live_look() if game_clock else _looks[DAY]
	_t = 1.0
	_apply(_wake_look())
	return true


## The flight ended: a skip brings the Day look in over WAKE_SKIP s from wherever the morning is; a
## flight that ran its length has already ended the morning.
func end_wake() -> void:
	if not waking():
		return
	_from = _wake_look()
	_wake_t = -1.0
	_blend_len = WAKE_SKIP
	_t = 0.0


## True while the opening's morning plays.
func waking() -> bool:
	return _wake_t >= 0.0


func _wake_look() -> Dictionary:
	return morning(_looks, _wake_t / maxf(_wake_len, 0.001))


## The morning's look at `e` (0..1 of the flight) from `looks` (build_looks): the two WAKE_KEYS
## round `e`, blended with a smoothstep. Static and pure (check_opening.gd samples it).
static func morning(looks: Array, e: float) -> Dictionary:
	e = clampf(e, 0.0, 1.0)
	for i in range(WAKE_KEYS.size() - 1):
		var a: Array = WAKE_KEYS[i]
		var b: Array = WAKE_KEYS[i + 1]
		if e <= float(b[0]):
			var k := smoothstep(float(a[0]), float(b[0]), e) if float(b[0]) > float(a[0]) else 1.0
			return _blend(looks[int(a[1])], looks[int(b[1])], k)
	return (looks[int(WAKE_KEYS[-1][1])] as Dictionary).duplicate()


## Live: the three looks blended by the real sun's elevation, the sun turned to its
## azimuth (the light shines along -Z: yaw = 180 - azimuth; pitch = -elevation).
func _live_look() -> Dictionary:
	var t := now_utc()
	if game_clock:
		var st := sun_times()
		t += solar_shift(fposmod((t + warsaw_offset(t)) / 3600.0, 24.0), st.x, st.y, _band()) * 3600.0
	var sp := sun_position(t)
	sun_elevation = sp.x
	sun_azimuth = sp.y
	var e := sp.x
	var day: Dictionary = _looks[DAY].duplicate()
	var dusk: Dictionary = _looks[DUSK].duplicate()
	day["sun_yaw"] = 180.0 - sp.y
	day["sun_pitch"] = -clampf(e, LIVE_PITCH.x, LIVE_PITCH.y)
	dusk["sun_yaw"] = 180.0 - sp.y
	if game_clock:
		return golden_look(day, dusk, _looks[SUNRISE_LOOK], _looks[NIGHT], sp)
	if e >= 10.0:
		return day
	if e >= -2.0:
		return _blend(day, dusk, smoothstep(10.0, -2.0, e))
	if e >= -10.0:
		return _blend(dusk, _looks[NIGHT], smoothstep(-2.0, -10.0, e))
	return _looks[NIGHT].duplicate()


## The game clock's look for the sun at `sp` (elevation, azimuth): Day above 14 degrees, then the
## golden light (`golden`: the opening's sunrise, low and warm, long shadows) down to 4, into the
## blue hour (`dusk`) by 3 below the horizon, and Night from 10 below. Static and pure.
static func golden_look(day: Dictionary, dusk: Dictionary, golden: Dictionary, night: Dictionary, sp: Vector2) -> Dictionary:
	var e := sp.x
	var gold := golden.duplicate()
	gold["sun_yaw"] = 180.0 - sp.y
	gold["sun_pitch"] = -clampf(e, 16.0, 30.0)
	if e >= 14.0:
		return day
	if e >= 4.0:
		return _blend(day, gold, smoothstep(14.0, 4.0, e))
	if e >= -3.0:
		return _blend(gold, dusk, smoothstep(4.0, -3.0, e))
	if e >= -10.0:
		return _blend(dusk, night, smoothstep(-3.0, -10.0, e))
	return night.duplicate()


## Now, as Unix seconds UTC: the game clock's moment (F 2026-11-19), the device's clock, or the
## --clock/--date start plus the time since the game started.
func now_utc() -> float:
	if game_clock:
		return _game_utc
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
	# The shadows fade in and out with a blend (the opening's sunrise) instead of switching at its
	# middle; a whole look is 0 or 1 as before.
	var shade := clampf(float(look["shadows"]), 0.0, 1.0)
	sun.shadow_enabled = shade > 0.02 and shadows_allowed
	sun.shadow_opacity = shade * (1.0 - 0.5 * r)
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
	post.set_shader_parameter("g_gain", look["g_gain"])
	post.set_shader_parameter("g_contrast", look["g_contrast"])
	post.set_shader_parameter("g_pivot", look["g_pivot"])
	post.set_shader_parameter("g_lift", look["g_lift"])
	post.set_shader_parameter("g_vibrance", look["g_vibrance"])
	post.set_shader_parameter("g_shoulder", look["g_shoulder"])
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
