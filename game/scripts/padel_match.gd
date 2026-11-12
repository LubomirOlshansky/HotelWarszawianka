extends Node
## "Padel na Desce": the arcade padel match at WTS DESKA's outdoor court (F's ask 2026-11-08,
## docs/design/padel.md). The friend's call (trend_job.gd "Czwarty"), on time at the gate: you and
## the friend against Prezes z Mokotowa and Pan Zbyszek, two games of 0/15/30/40 with the golden
## point. The rules, the ball and the players are padel_sim.gd; this node draws it and plays it.
##
## The look: pixel art drawn at H px high (the width follows the screen) into a SubViewport, shown
## nearest-filtered over the whole screen, from F's photos of the real court (2026-11-08): a dark
## charcoal court with white lines, frameless glass back walls with black mesh on top, black mesh
## sides on a black steel frame, a black net with white padded posts, black swan-neck floodlights
## with flat heads, the lawn round it with beige DESKA deckchairs, a little football goal, the grey
## metal tennis hall and tall poplars and conifers behind, maple leaves in front. The club's crowd
## stands on the lawn behind the far fence and reacts (cheers a smash, "ooh" at a ball off the
## glass), one moment per game: phones up and clapping, a Mexican wave, Pani Basia's dog running
## the fence. A flip-card scoreboard on the lawn. Day, golden hour and night (the floodlights)
## follow the clock.
##
## Touch: the left thumb anywhere on the left half is a stick (leave it and you run to the ball by
## yourself), UDERZ (hit: a drive, a volley, a jumping smash on a high ball) and LOB on the right,
## ✕ gives the match up. Keys: arrows / WASD, Space or J (hit), K (lob), Esc. Multi-touch is read
## by index, so the stick and the buttons work together.
##
## Sound: everything made here at the first match (a chiptune loop at 120 BPM, the racket, the
## bounce, the glass, the mesh, the net, the crowd's cheer and ooh) plus the city's crowd murmur;
## the radio is ducked while it plays.
##
## Cost: while it runs the city's 3D is off (main.gd stops the city's SubViewport), so the frame is
## the 2D canvas alone: one SubViewport of about 470 x 216 px, a few hundred rects. Built once.

const PadelSim := preload("res://scripts/padel_sim.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Lang := preload("res://scripts/lang.gd")
const Sfx := preload("res://scripts/sfx.gd")

## The pixel canvas's height; the width follows the screen's aspect (at least MIN_W).
const H := 216
const MIN_W := 384
## The court's projection: px per metre along (near side), the depth per metre, the height per
## metre, the near edge's screen row, how much narrower the far side is.
const KX := 16.0
const DY := 6.6
const KZ := 15.0
const GY := 196.0
const FAR := 0.17
## After the match: the result stays this long (s) before it hands back.
const END_HOLD := 4.0
const INTRO_S := 3.0
const RATE := 22050
const MUSIC_RATE := 16000
const BPM := 120.0

const US := Color("#ff7a2a")
const US_DARK := Color("#d4501c")
const THEM := Color("#27c4dc")
const THEM_DARK := Color("#1784a8")
const BALL := Color("#e4f23a")
const LINE := Color("#f2f2ea")
const FRAME := Color("#16191d")
const COURT := Color("#2d3135")
const GOLD := Color("#ffd23a")

## Every line on screen: [pl, en] pairs (check_padel.gd checks both exist).
const LINES := {
	"title": [["PADEL NA DESCE", "PADEL AT DESKA"]],
	"hint": [["LEWY KCIUK: BIEGNIJ. ZOSTAW GO: BIEGNIESZ SAM.", "LEFT THUMB: RUN. LET GO: YOU RUN BY YOURSELF."],
			["UDERZ, GDY PIŁKA ŚWIECI. WYSOKA PIŁKA: SMECZ.", "HIT WHEN THE BALL GLOWS. A HIGH BALL: SMASH."],
			["LOB NAD PARĄ PRZY SIATCE. SZYBA JEST CZĘŚCIĄ GRY.", "LOB OVER A PAIR AT THE NET. THE GLASS IS PART OF THE GAME."]],
	"serve": [["TWÓJ SERWIS: UDERZ", "YOUR SERVE: HIT"]],
	"net": [["SIATKA", "NET"]],
	"short": [["NIE PRZESZŁA", "DIDN'T CROSS"]],
	"long": [["ZA DŁUGO: W SZYBĘ", "LONG: INTO THE GLASS"]],
	"wide": [["W BOCZNĄ SIATKĘ", "INTO THE SIDE FENCE"]],
	"winner": [["WINNER!", "WINNER!"]],
	"over": [["POR TRES! ZA KORT!", "POR TRES! OFF THE COURT!"]],
	"out": [["AUT", "OUT"]],
	"back": [["WRÓCIŁA ZA SIATKĘ!", "IT CAME BACK OVER!"]],
	"stall": [["PIŁKA UTKNĘŁA", "THE BALL GOT STUCK"]],
	"point_us": [["PUNKT DLA WAS", "YOUR POINT"]],
	"point_them": [["PUNKT DLA RYWALI", "THEIR POINT"]],
	"golden": [["ZŁOTY PUNKT!", "GOLDEN POINT!"]],
	"game_us": [["GEM DLA WAS!", "GAME TO YOU!"]],
	"game_them": [["GEM DLA RYWALI", "GAME TO THEM"]],
	"win": [["WYGRANA!", "YOU WIN!"]],
	"lose": [["PRZEGRANA", "YOU LOSE"]],
	"perfect": [["IDEALNIE!", "PERFECT!"]],
	"smash": [["SMECZ!", "SMASH!"]],
	"whiff": [["PUDŁO", "MISS"]],
	"ooh": [["OOOCH!", "OOOH!"]],
	"you": [["TY", "YOU"]],
	"hit": [["UDERZ", "HIT"]],
	"lob": [["LOB", "LOB"]],
	"games": [["GEMY", "GAMES"]],
	"coach": [["DOMINIK: „NIE BIEGAJ, USTAW SIĘ!”", "DOMINIK: DON'T RUN, GET IN PLACE!"],
			["DOMINIK: „ŚCIANA TO CZĘŚĆ GRY!”", "DOMINIK: THE WALL IS PART OF THE GAME!"],
			["DOMINIK: „LOB, KIEDY STOJĄ PRZY SIATCE!”", "DOMINIK: LOB WHEN THEY'RE AT THE NET!"],
			["DOMINIK: „WCZEŚNIEJ RAKIETA!”", "DOMINIK: RACKET BACK EARLIER!"]],
	"basia": [["PANI BASIA: „PARKING DLA HELIKOPTERÓW OD STRONY WISŁY.”", "PANI BASIA: THE HELICOPTER PARKING IS ON THE RIVER SIDE."]],
	"vs": [["%s I %s KONTRA %s I %s", "%s AND %s VS %s AND %s"]],
}

## The match's end: games won by your pair and by the rivals, the sim's stats.
signal done(games_us: int, games_them: int, stats: Dictionary)

var hud: CanvasLayer
var radio: Node
var log_on := false
## Plays itself (Autopilot, the shots, the check).
var auto_play := false
var hour := 12.0
var inside := false
var sim: PadelSim
var partner := "Kuba"
var rivals := ["Prezes", "Zbyszek"]
var flew := false

var W := MIN_W
var _layer: CanvasLayer
var _vp: SubViewport
var _canvas: Node2D
var _tex: TextureRect
var _pad: Control
var _t := 0.0
var _end_t := -1.0
var _cam_x := 0.0
var _shake := 0.0
var _shake_v := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
## Particles: [court position, velocity, life left, life, colour, size, gravity].
var _parts: Array = []
## Ball trail: recent court positions.
var _trail: Array[Vector3] = []
var _fire := false
var _callout := ""
var _callout_t := 0.0
var _callout_c := Color.WHITE
var _sub := ""
var _sub_t := 0.0
var _score_flip := 0.0
var _crowd: Array = []
var _crowd_cheer := 0.0
var _crowd_ooh := 0.0
var _wave_t := -10.0
var _dog_t := -10.0
var _flash_t := 0.0
var _flash_p := Vector2.ZERO
var _speckle: PackedVector2Array = PackedVector2Array()
var _clouds: Array = []
var _palette := {}
var _night := false
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_i := 0
var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _sounds := {}
## Touch: index -> "stick" / "hit" / "lob" / "quit"; the stick's base and knob (screen px).
var _touches := {}
var _stick_on := false
var _stick_base := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _keys := Vector2.ZERO
var _hit_glow := 0.0
var _hit_press := 0.0
var _lob_press := 0.0
var _coach_i := 0


func _ready() -> void:
	set_process(false)


# --- in and out -------------------------------------------------------------------------------

## Onto the court: `info` {partner, rivals [2], hour, flew, seed}. Builds the canvas and sounds once.
func enter(info: Dictionary) -> void:
	partner = String(info.get("partner", "Kuba"))
	rivals = info.get("rivals", ["Prezes", "Zbyszek"])
	hour = float(info.get("hour", 12.0))
	flew = bool(info.get("flew", false))
	_rng.seed = int(info.get("seed", 1))
	if _layer == null:
		_build()
	sim = PadelSim.new()
	sim.auto_human = auto_play
	sim.setup(int(info.get("seed", 1)), partner, rivals)
	_palette = palette(hour)
	_night = bool(_palette["night"])
	_make_crowd()
	_parts.clear()
	_trail.clear()
	_t = 0.0
	_end_t = -1.0
	_cam_x = 0.0
	_touches.clear()
	_stick_on = false
	inside = true
	_layer.visible = true
	_resize()
	Sfx.duck("padel")
	if _music != null:
		_music.play()
		_amb.play()
	var vs: Array = LINES["vs"][0]
	_say_sub(Lang.pick(vs[0], vs[1]) % [_you_name(), partner.to_upper(), String(rivals[0]).to_upper(), String(rivals[1]).to_upper()], INTRO_S)
	_say(_line("title"), GOLD, INTRO_S)
	if flew:
		_say_sub(_line("basia"), 4.5)
	set_process(true)
	_log("city before: %d draw calls, %d objects in the frame" % [int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
	_log("in: %s with %s vs %s, hour %.1f%s" % ["auto" if auto_play else "player", partner, rivals, hour, ", landed by helicopter" if flew else ""])


## ✕ or the end: hand back. Leaving early is a lost match.
func leave() -> void:
	if not inside:
		return
	var g0 := int(sim.games[0])
	var g1 := int(sim.games[1])
	if not sim.over():
		g1 = PadelSim.GAMES_TO_WIN
	_finish(g0, g1)


func _finish(g0: int, g1: int) -> void:
	inside = false
	_layer.visible = false
	set_process(false)
	Sfx.release("padel")
	if _music != null:
		_music.stop()
		_amb.stop()
	_log("out: games %d:%d, %s" % [g0, g1, sim.stats])
	done.emit(g0, g1, sim.stats.duplicate())


func _you_name() -> String:
	return _line("you")


func _line(key: String, i := 0) -> String:
	var row: Array = LINES[key]
	var pair: Array = row[i % row.size()]
	return Lang.pick(String(pair[0]), String(pair[1]))


# --- building -----------------------------------------------------------------------------------

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	_vp = SubViewport.new()
	_vp.size = Vector2i(MIN_W, H)
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.snap_2d_transforms_to_pixel = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_scene)
	_vp.add_child(_canvas)
	_tex = TextureRect.new()
	_tex.texture = _vp.get_texture()
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_tex)
	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	_layer.add_child(_pad)
	_layer.visible = false
	get_viewport().size_changed.connect(_resize)
	_speckle = PackedVector2Array()
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for i in 420:
		_speckle.append(Vector2(r.randf() * PadelSim.LEN, r.randf() * PadelSim.WID))
	for i in 6:
		_clouds.append([r.randf() * 600.0, 8.0 + r.randf() * 40.0, 18.0 + r.randf() * 30.0, 3.0 + r.randf() * 4.0])
	_build_audio()


func _resize() -> void:
	if _vp == null:
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W, H)


## The colours by the hour: day, golden hour, night.
static func palette(h: float) -> Dictionary:
	var night := h >= 19.75 or h < 6.0
	var golden := not night and h >= 17.25
	if night:
		return {"night": true, "sky": [Color("#0b1530"), Color("#16264a"), Color("#26365c")], "sun": Color(0, 0, 0, 0),
				"tree": Color("#0e1f18"), "tree2": Color("#132a1f"), "lawn": Color("#1d3a22"), "lawn2": Color("#244628"),
				"hall": Color("#3a4250"), "hall2": Color("#2c333e"), "light": 0.55, "court": Color("#33383d")}
	if golden:
		return {"night": false, "sky": [Color("#ffb46a"), Color("#f6c68a"), Color("#a8c4e0")], "sun": Color("#fff0b0"),
				"tree": Color("#2c4a22"), "tree2": Color("#3b5e2a"), "lawn": Color("#5f9a36"), "lawn2": Color("#6fae3e"),
				"hall": Color("#b9a99a"), "hall2": Color("#9a8a7e"), "light": 0.9, "court": COURT}
	return {"night": false, "sky": [Color("#4f86d8"), Color("#7fb0ea"), Color("#c6dcf2")], "sun": Color("#fffbe0"),
			"tree": Color("#2c5a2a"), "tree2": Color("#3f7a34"), "lawn": Color("#5fae3c"), "lawn2": Color("#71c046"),
			"hall": Color("#aab4bc"), "hall2": Color("#8e99a2"), "light": 1.0, "court": COURT}


func _make_crowd() -> void:
	_crowd.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 31
	var shirts := [Color("#ff7a2a"), Color("#27c4dc"), Color("#f4f4f0"), Color("#e8e04a"), Color("#ef5a8a"), Color("#8a6ae0"), Color("#3a3f48"), Color("#ffffff")]
	var skins := [Color("#f1c8a4"), Color("#d9a984"), Color("#b07a56"), Color("#7d5238")]
	var hairs := [Color("#2b1d14"), Color("#6b4423"), Color("#e2c060"), Color("#9a9a9a"), Color("#1a1a1a"), Color("#c0502a")]
	var n := 30
	for i in n:
		var kind := 0
		var roll := r.randf()
		if roll < 0.08:
			kind = 1   # a kid on a dad's shoulders
		elif roll < 0.2:
			kind = 3   # a sign
		elif roll < 0.34:
			kind = 4   # a phone
		_crowd.append({"x": -0.5 + 21.0 * (i + r.randf() * 0.6) / n, "row": i % 2, "kind": kind,
				"shirt": shirts[r.randi() % shirts.size()], "skin": skins[r.randi() % skins.size()],
				"hair": hairs[r.randi() % hairs.size()], "ph": r.randf() * TAU, "team": r.randi() % 3})


# --- the frame ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside:
		return
	dt = minf(dt, 0.05)
	_t += dt
	var stick := _keys
	if _stick_on:
		var d := (_stick_knob - _stick_base) / (60.0 * _pt())
		stick = Vector2(d.x, -d.y)
	sim.stick = stick.limit_length(1.0)
	sim.step(dt)
	for ev: Array in sim.events:
		_on_event(String(ev[0]), ev[1])
	sim.events.clear()
	_fx_tick(dt)
	if log_on and int(_t / 10.0) != int((_t - dt) / 10.0):
		_log("bench: %d draw calls, %d objects, %.0f fps" % [int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), Engine.get_frames_per_second()])
	if sim.over():
		if _end_t < 0.0:
			_end_t = _t
		elif _t - _end_t > END_HOLD:
			_finish(int(sim.games[0]), int(sim.games[1]))
			return
	_hit_glow = 1.0 if sim.can_hit(sim.players[0]) else maxf(_hit_glow - dt * 4.0, 0.0)
	_hit_press = maxf(_hit_press - dt * 5.0, 0.0)
	_lob_press = maxf(_lob_press - dt * 5.0, 0.0)
	_canvas.queue_redraw()
	_pad.queue_redraw()


func _fx_tick(dt: float) -> void:
	# The camera follows the ball a little; shakes decay.
	var want := -(sim.ball.p.x - PadelSim.NET_X) * KX * 0.22
	_cam_x = lerpf(_cam_x, want, minf(dt * 2.5, 1.0))
	_shake = maxf(_shake - dt * 9.0, 0.0)
	_shake_v = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake * 2.5
	_callout_t -= dt
	_sub_t -= dt
	_score_flip = maxf(_score_flip - dt * 3.0, 0.0)
	_crowd_cheer = maxf(_crowd_cheer - dt, 0.0)
	_crowd_ooh = maxf(_crowd_ooh - dt, 0.0)
	_flash_t = maxf(_flash_t - dt * 3.0, 0.0)
	if not sim.held:
		_trail.push_front(sim.ball.p)
		if _trail.size() > 7:
			_trail.pop_back()
	else:
		_trail.clear()
	if _fire and sim.ball.v.length() > 8.0 and not sim.held:
		for i in 2:
			_spawn(sim.ball.p, Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(0.5, 2.0)), 0.35,
					[Color("#ffd23a"), Color("#ff7a2a"), Color("#e8301c")][_rng.randi() % 3], 2.0, -2.0)
	else:
		_fire = false
	var i := 0
	while i < _parts.size():
		var p: Array = _parts[i]
		p[2] = float(p[2]) - dt
		if float(p[2]) <= 0.0:
			_parts.remove_at(i)
			continue
		var v: Vector3 = p[1]
		v.z -= float(p[6]) * dt
		p[1] = v
		p[0] = (p[0] as Vector3) + v * dt
		i += 1
	# The phones' moment (game 1): someone raises a phone now and then.
	if int(sim.games[0]) + int(sim.games[1]) == 0 and _rng.randf() < dt * 0.6:
		var c: Dictionary = _crowd[_rng.randi() % _crowd.size()]
		c["flash"] = 0.4


func _spawn(at: Vector3, v: Vector3, life: float, c: Color, size: float, grav := 6.0) -> void:
	if _parts.size() > 260:
		_parts.pop_front()
	_parts.append([at, v, life, life, c, size, grav])


func _burst(at: Vector3, c: Color, n: int, speed: float) -> void:
	for i in n:
		var a := _rng.randf() * TAU
		var u := _rng.randf_range(-0.6, 1.0)
		var v := Vector3(cos(a) * sqrt(1.0 - u * u), sin(a) * sqrt(1.0 - u * u), u) * speed * _rng.randf_range(0.4, 1.0)
		_spawn(at, v, _rng.randf_range(0.25, 0.55), c.lightened(_rng.randf() * 0.4), 1.0 + float(_rng.randi() % 2), 4.0)


func _on_event(kind: String, d: Dictionary) -> void:
	match kind:
		"hit":
			var team := int(d["team"])
			var c := US if team == 0 else THEM
			var q := float(d["q"])
			var shot := int(d["shot"])
			_burst(d["p"], c, 10 + int(q * 10.0), 3.0 + q * 3.0)
			_play("hit", 0.0 if shot != PadelSim.Shot.SMASH else 3.0, 0.9 + q * 0.25 + (0.15 if shot == PadelSim.Shot.VOLLEY else 0.0))
			if shot == PadelSim.Shot.SMASH:
				_fire = true
				_shake = 1.0
				_crowd_cheer = 1.2
				_play("cheer", -4.0)
				_say(_line("smash"), c, 0.9)
				_burst(d["p"], GOLD, 14, 6.0)
			elif q >= 0.9 and int(d["who"]) == 0:
				_say(_line("perfect"), GOLD, 0.7)
				_shake = maxf(_shake, 0.35)
			if int(d["who"]) == 0 and sim.players[0].human:
				_hit_press = 1.0
		"bounce":
			var p: Vector3 = d["p"]
			for i in 6:
				_spawn(p, Vector3(_rng.randf_range(-1.2, 1.2), _rng.randf_range(-0.6, 0.6), _rng.randf_range(0.4, 1.4)), 0.45,
						Color("#9a9286") if _rng.randf() < 0.6 else Color("#c8bea8"), 1.0, 5.0)
			_play("bounce", -3.0, _rng.randf_range(0.95, 1.1))
		"glass":
			_play("glass", -1.0, _rng.randf_range(0.95, 1.08))
			_flash_t = 1.0
			_flash_p = _proj(d["p"])
			_shake = maxf(_shake, 0.3)
			if bool(d["legal"]):
				_crowd_ooh = 1.1
				_play("ooh", -6.0)
		"mesh":
			_play("mesh", -2.0)
		"net":
			_play("net", -2.0)
		"whiff":
			if int(d["who"]) == 0:
				_say(_line("whiff"), Color("#c8c8c8"), 0.6)
		"point":
			var team := int(d["team"])
			var why := String(d["why"])
			_score_flip = 1.0
			_play("chime", -6.0, 1.0 if team == 0 else 0.8)
			var head := _line("point_us") if team == 0 else _line("point_them")
			if why in LINES:
				_say(_line(why), US if team == 0 else THEM, PadelSim.POINT_PAUSE)
				_say_sub(head, PadelSim.POINT_PAUSE)
			else:
				_say(head, US if team == 0 else THEM, PadelSim.POINT_PAUSE)
			if team == 0:
				_crowd_cheer = 1.6
				_play("cheer", -3.0)
			elif sim.players[0].human and not auto_play and _rng.randf() < 0.45:
				_say_sub(_line("coach", _coach_i), PadelSim.POINT_PAUSE + 0.4)
				_coach_i += 1
			if int(sim.games[0]) + int(sim.games[1]) == 1:
				_wave_t = _t
			if int(sim.games[0]) + int(sim.games[1]) == 2:
				_dog_t = _t
			_log("point %s (%s, %d hits): %s:%s, games %s" % ["us" if team == 0 else "them", why, int(d["hits"]), sim.call_of(0), sim.call_of(1), sim.games])
		"serve_ready":
			if sim.golden():
				_say(_line("golden"), GOLD, 1.6)
			elif int(d["server"]) == 0 and not auto_play:
				_say_sub(_line("serve"), 2.0)
			if _t > 0.5 and _t < 20.0 and not auto_play:
				_say_sub(_line("hint", int(_t / 6.0)), 3.0)
		"game":
			var team := int(d["team"])
			_say(_line("game_us") if team == 0 else _line("game_them"), US if team == 0 else THEM, PadelSim.GAME_PAUSE)
			_score_flip = 1.0
			_crowd_cheer = 2.5
			_play("cheer", 0.0)
		"match":
			var won := int(d["winner"]) == 0
			_say(_line("win") if won else _line("lose"), US if won else THEM, END_HOLD + 1.0)
			_say_sub("%s %d:%d" % [_line("games"), int(sim.games[0]), int(sim.games[1])], END_HOLD + 1.0)
			_crowd_cheer = 4.0
			_play("cheer", 1.0)


func _say(text: String, c: Color, life: float) -> void:
	_callout = text
	_callout_c = c
	_callout_t = life


func _say_sub(text: String, life: float) -> void:
	_sub = text
	_sub_t = life


func _log(text: String) -> void:
	if log_on:
		print("padel: " + text)


# --- drawing ------------------------------------------------------------------------------------

## A court point (x along, y across, z up, m) on the pixel canvas.
func _proj(p: Vector3) -> Vector2:
	var f := 1.0 - FAR * p.y / PadelSim.WID
	return Vector2(W * 0.5 + _cam_x + (p.x - PadelSim.NET_X) * KX * f, GY - p.y * DY - p.z * KZ * f) + _shake_v


func _pr(x: float, y: float, z: float) -> Vector2:
	return _proj(Vector3(x, y, z))


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	_canvas.draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), c)


func _poly(pts: Array, c: Color) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array(pts), c)


func _ln(a: Vector2, b: Vector2, c: Color) -> void:
	_canvas.draw_line(a.round() + Vector2(0.5, 0.5), b.round() + Vector2(0.5, 0.5), c, 1.0)


## Pixel text (the city's 5x7 font): `scale` px per font pixel, centred on `x` when `centre`.
func _text(s: String, x: float, y: float, c: Color, scale := 1, centre := true, shadow := true) -> void:
	s = s.to_upper()
	var w := PixelFont.width(s) * scale
	var x0 := roundf(x - w * 0.5) if centre else roundf(x)
	var y0 := roundf(y)
	if shadow:
		PixelFont.each_pixel(s, 0, func(px: int, row: int) -> void:
			_canvas.draw_rect(Rect2(x0 + px * scale + scale, y0 + row * scale + scale, scale, scale), Color(0, 0, 0, 0.7)))
	PixelFont.each_pixel(s, 0, func(px: int, row: int) -> void:
		_canvas.draw_rect(Rect2(x0 + px * scale, y0 + row * scale, scale, scale), c))


func _draw_scene() -> void:
	if sim == null:
		return
	_draw_sky()
	_draw_far()
	_draw_crowd()
	_draw_chairs()
	_draw_court()
	_draw_walls_far()
	_draw_bodies()
	_draw_parts()
	_draw_walls_near()
	_draw_front()
	_draw_board()
	_draw_texts()


func _draw_sky() -> void:
	var sky: Array = _palette["sky"]
	var bands := 9
	for i in bands:
		var k := float(i) / (bands - 1)
		var c: Color = (sky[0] as Color).lerp(sky[1], minf(k * 1.6, 1.0)).lerp(sky[2], maxf(k * 1.6 - 0.6, 0.0))
		_rect(0, i * 11, W, 12, c)
	if _night:
		var r := RandomNumberGenerator.new()
		r.seed = 5
		for i in 40:
			var tw := 0.5 + 0.5 * sin(_t * 2.0 + i)
			_rect(r.randf() * W, r.randf() * 70.0, 1, 1, Color(1, 1, 0.9, 0.4 + 0.5 * tw))
		# The moon.
		_canvas.draw_circle(Vector2(W * 0.18, 22), 7, Color("#f4f0d8"))
		_canvas.draw_circle(Vector2(W * 0.18 + 3, 20), 6, sky[0])
	else:
		var sun := Vector2(W * 0.14, 24) + Vector2(_cam_x * 0.05, 0)
		var sc: Color = _palette["sun"]
		# God rays: soft wedges from the sun.
		for i in 5:
			var a := 0.35 + i * 0.22 + sin(_t * 0.3 + i) * 0.03
			var d := Vector2(cos(a), sin(a))
			var s2 := Vector2(-d.y, d.x)
			_poly([sun, sun + d * 260.0 + s2 * 18.0, sun + d * 260.0 - s2 * 18.0], Color(sc.r, sc.g, sc.b, 0.07))
		_canvas.draw_circle(sun, 15, Color(sc.r, sc.g, sc.b, 0.25))
		_canvas.draw_circle(sun, 10, Color(sc.r, sc.g, sc.b, 0.5))
		_canvas.draw_circle(sun, 7, sc)
	for cl: Array in _clouds:
		var x := fposmod(float(cl[0]) + _t * float(cl[3]) + _cam_x * 0.08, W + 120.0) - 60.0
		var y: float = cl[1]
		var w: float = cl[2]
		var cc := Color(1, 1, 1, 0.85) if not _night else Color(0.4, 0.45, 0.6, 0.35)
		_rect(x, y, w, 4, cc)
		_rect(x + w * 0.15, y - 3, w * 0.5, 3, cc)
		_rect(x + w * 0.45, y - 5, w * 0.3, 2, cc)
		_rect(x + 2, y + 4, w - 4, 1, cc.darkened(0.12))


func _draw_far() -> void:
	var px := _cam_x * 0.3
	var t1: Color = _palette["tree"]
	var t2: Color = _palette["tree2"]
	var hall: Color = _palette["hall"]
	var hall2: Color = _palette["hall2"]
	# Tall trees: round crowns and dark conifers behind everything.
	var r := RandomNumberGenerator.new()
	r.seed = 9
	for i in 22:
		var x := -30.0 + i * (W + 60.0) / 21.0 + px * 0.5 + r.randf() * 10.0
		var top := 48.0 + r.randf() * 20.0
		if i % 3 == 0:
			_poly([Vector2(x, top - 14.0), Vector2(x + 9.0, 98.0), Vector2(x - 9.0, 98.0)], t1)
		else:
			var rr := 9.0 + r.randf() * 6.0
			_canvas.draw_circle(Vector2(x, top), rr, t1)
			_canvas.draw_circle(Vector2(x + rr * 0.6, top + 5.0), rr * 0.8, t2)
			_rect(x - 1, top, 2, 98.0 - top, t1.darkened(0.3))
	# The metal tennis hall: a long low grey box with ribbed walls and a shallow roof, right.
	var hx := W * 0.42 + px
	var hw := W * 0.62
	_poly([Vector2(hx - 4, 74), Vector2(hx + hw + 4, 74), Vector2(hx + hw, 68), Vector2(hx, 68)], hall2.lightened(0.15))
	_rect(hx, 74, hw, 26, hall)
	for k in int(hw / 3.0):
		_rect(hx + k * 3, 74, 1, 26, hall2)
	_rect(hx, 98, hw, 2, hall2.darkened(0.2))
	# A chimney on its roof.
	_rect(hx + hw * 0.7, 62, 3, 7, Color("#c8ccd0") if not _night else Color("#555a62"))
	# The clubhouse, left: dark wood with the DESKA letters (lit at night).
	var cx := W * 0.04 + px
	_rect(cx, 66, 74, 34, Color("#3b2a20") if not _night else Color("#22180f"))
	for k in 12:
		_rect(cx, 66 + k * 3, 74, 1, Color("#2c1f17") if not _night else Color("#18110b"))
	_rect(cx + 4, 86, 66, 10, Color("#1c242c") if not _night else Color("#ffd896"))
	_text("DESKA", cx + 37, 67, Color("#e8e0d0") if not _night else Color(0.3, 0.9, 1.0), 1, true, false)
	# The lawn.
	var lawn: Color = _palette["lawn"]
	var lawn2: Color = _palette["lawn2"]
	_rect(0, 98, W, H - 98, lawn)
	for k in 6:
		_rect(0, 100 + k * 16, W, 8, lawn2)
	# The little football goal on the lawn, right of the court.
	var gx := W * 0.5 + _cam_x * 0.8 + 196.0
	var goal := Color("#f4f4f0") if not _night else Color("#9aa0a8")
	_rect(gx, 104, 1, 14, goal)
	_rect(gx + 22, 104, 1, 14, goal)
	_rect(gx, 104, 23, 1, goal)
	for k in 6:
		_rect(gx + 1 + k * 4, 105, 1, 13, Color(goal, 0.25))
	# Bunting along the top of the far fence.
	var a := _pr(0, PadelSim.WID, PadelSim.WALL_H + 0.3)
	var b := _pr(PadelSim.LEN, PadelSim.WID, PadelSim.WALL_H + 0.3)
	_ln(a, b, Color(0.1, 0.1, 0.1, 0.6))
	for k in 24:
		var q := a.lerp(b, (k + 0.5) / 24.0)
		var bc := [US, THEM, LINE][k % 3] as Color
		_poly([q, q + Vector2(4, 0), q + Vector2(2, 4 + sin(_t * 3.0 + k) * 0.7)], bc)


func _draw_crowd() -> void:
	var n := _crowd.size()
	for i in n:
		var c: Dictionary = _crowd[i]
		var row := int(c["row"])
		var base := _pr(float(c["x"]), PadelSim.WID + 1.2 + row * 0.9, 0.0)
		var hop := 0.0
		var arms_up := false
		var ooh := false
		var ph := float(c["ph"])
		if _crowd_cheer > 0.0:
			hop = absf(sin(_t * 11.0 + ph)) * 3.0 * minf(_crowd_cheer, 1.0)
			arms_up = true
		elif _crowd_ooh > 0.0:
			ooh = true
		var wave := _t - _wave_t - float(c["x"]) * 0.08
		if wave > 0.0 and wave < 0.6:
			hop = maxf(hop, sin(wave / 0.6 * PI) * 5.0)
			arms_up = true
		var clap := int(sim.games[0]) + int(sim.games[1]) == 0 and sim.phase == PadelSim.Phase.PLAY and int(_t * 4.0 + ph) % 2 == 0
		var x := roundf(base.x)
		var y := roundf(base.y - hop)
		var dark := 0.45 if _night else 0.0
		var shirt := (c["shirt"] as Color).darkened(dark)
		var skin := (c["skin"] as Color).darkened(dark)
		var hair := (c["hair"] as Color).darkened(dark)
		var kind := int(c["kind"])
		# Legs, body, head (about 13 px).
		_rect(x - 2, y - 4, 1, 4, Color("#2a2f3a").darkened(dark))
		_rect(x + 1, y - 4, 1, 4, Color("#2a2f3a").darkened(dark))
		_rect(x - 2, y - 9, 4, 5, shirt)
		_rect(x - 2, y - 13, 4, 4, skin)
		_rect(x - 2, y - 14, 4, 2, hair)
		if arms_up:
			_rect(x - 3, y - 15, 1, 6, skin)
			_rect(x + 2, y - 15, 1, 6, skin)
		elif ooh:
			_rect(x - 3, y - 14, 1, 2, skin)
			_rect(x + 2, y - 14, 1, 2, skin)
		elif clap:
			_rect(x - 1, y - 9, 2, 1, skin)
		if kind == 1:
			# A kid on the shoulders.
			_rect(x - 1, y - 19, 3, 5, US.darkened(dark))
			_rect(x - 1, y - 22, 3, 3, skin)
		elif kind == 3:
			# A sign in a team's colour with a racket mark.
			var sc := US if int(c["team"]) != 1 else THEM
			var sy := y - 21 - (2 if arms_up else 0)
			_rect(x - 4, sy, 9, 6, sc.darkened(dark))
			_rect(x - 1, sy + 1, 3, 3, LINE)
			_rect(x, sy + 4, 1, 2, LINE)
			_rect(x, sy + 6, 1, 3, Color("#6b4423"))
		elif kind == 4 or float(c.get("flash", 0.0)) > 0.0:
			_rect(x + 2, y - 17, 2, 3, Color("#20242c"))
			if float(c.get("flash", 0.0)) > 0.0 or (_crowd_cheer > 0.0 and int(_t * 6.0 + ph) % 3 == 0):
				_rect(x + 2, y - 17, 2, 1, Color(1, 1, 0.8))
		if c.has("flash"):
			c["flash"] = float(c["flash"]) - 1.0 / 60.0
	# Pani Basia's dog runs the fence (game 3).
	var dt := _t - _dog_t
	if dt > 0.0 and dt < 5.0:
		var dx := -1.0 + dt / 5.0 * 22.0
		var d := _pr(dx, PadelSim.WID + 0.4, 0.0)
		var leg := int(_t * 14.0) % 2
		var dc := Color("#a8743a").darkened(0.4 if _night else 0.0)
		_rect(d.x - 4, d.y - 5, 7, 3, dc)
		_rect(d.x + 2, d.y - 7, 3, 3, dc)
		_rect(d.x - 4 + leg, d.y - 2, 1, 2, dc)
		_rect(d.x + 1 - leg, d.y - 2, 1, 2, dc)
		_rect(d.x - 6, d.y - 6, 2, 1, dc)
		_canvas.draw_circle(_pr(dx + 0.6, PadelSim.WID + 0.4, 0.15).round(), 1.5, BALL)


func _draw_court() -> void:
	var L := PadelSim.LEN
	var Wd := PadelSim.WID
	# The concrete surround and the court's dark synthetic surface (sand in it: speckles).
	_poly([_pr(-1.2, -0.6, 0), _pr(L + 1.2, -0.6, 0), _pr(L + 1.2, Wd + 0.6, 0), _pr(-1.2, Wd + 0.6, 0)], Color("#6e7072").darkened(0.4 if _night else 0.0))
	var cc: Color = _palette["court"]
	_poly([_pr(0, 0, 0), _pr(L, 0, 0), _pr(L, Wd, 0), _pr(0, Wd, 0)], cc)
	if _night:
		# The floodlights' pools on the court.
		for p: Vector2 in [Vector2(3.5, 2.5), Vector2(3.5, 7.5), Vector2(16.5, 2.5), Vector2(16.5, 7.5)]:
			var c := _pr(p.x, p.y, 0)
			_canvas.draw_set_transform(c, 0.0, Vector2(1.0, 0.45))
			_canvas.draw_circle(Vector2.ZERO, 46, Color(1, 0.97, 0.85, 0.06))
			_canvas.draw_circle(Vector2.ZERO, 30, Color(1, 0.97, 0.85, 0.06))
			_canvas.draw_set_transform(Vector2.ZERO)
	for s: Vector2 in _speckle:
		var q := _pr(s.x, s.y, 0)
		_rect(q.x, q.y, 1, 1, cc.lightened(0.12))
	var lc := LINE if not _night else LINE.darkened(0.08)
	for x: float in [3.05, L - 3.05]:
		_ln(_pr(x, 0, 0), _pr(x, Wd, 0), lc)
	_ln(_pr(3.05, Wd * 0.5, 0), _pr(L - 3.05, Wd * 0.5, 0), lc)
	# The marker: where the auto-run is taking you (your ball).
	var me := sim.players[0]
	if me.planned and sim.phase == PadelSim.Phase.PLAY and me.human:
		var m := _pr(me.plan_p.x, me.plan_p.y, 0)
		var pulse := 0.5 + 0.5 * sin(_t * 12.0)
		_canvas.draw_set_transform(m, 0.0, Vector2(1.0, 0.45))
		_canvas.draw_arc(Vector2.ZERO, 6.0 + pulse * 2.0, 0.0, TAU, 16, Color(GOLD, 0.8), 1.0)
		_canvas.draw_set_transform(Vector2.ZERO)


## The far side wall (glass at the ends, mesh between) and the two back walls (glass, mesh above).
func _draw_walls_far() -> void:
	var L := PadelSim.LEN
	var Wd := PadelSim.WID
	var mesh := Color(0.05, 0.06, 0.07, 0.42)
	var glass := Color(0.75, 0.9, 0.95, 0.13)
	# The far side.
	var y := Wd
	for x0: float in [0.0, L - 2.0]:
		_poly([_pr(x0, y, 0), _pr(x0 + 2.0, y, 0), _pr(x0 + 2.0, y, 3.0), _pr(x0, y, 3.0)], glass)
	_mesh_panel(Vector3(0, y, 3.0), Vector3(2, y, 4.0), mesh)
	_mesh_panel(Vector3(L - 2, y, 3.0), Vector3(L, y, 4.0), mesh)
	_mesh_panel(Vector3(2, y, 0.0), Vector3(L - 2, y, 3.0), mesh)
	for k in 11:
		_ln(_pr(k * 2.0, y, 0), _pr(k * 2.0, y, 4.0 if k <= 1 or k >= 9 else 3.0), FRAME)
	_ln(_pr(0, y, 4.0), _pr(2, y, 4.0), FRAME)
	_ln(_pr(L - 2, y, 4.0), _pr(L, y, 4.0), FRAME)
	_ln(_pr(2, y, 3.0), _pr(L - 2, y, 3.0), FRAME)
	_ln(_pr(0, y, 3.0), _pr(2, y, 3.0), FRAME)
	_ln(_pr(L - 2, y, 3.0), _pr(L, y, 3.0), FRAME)
	# The back walls: frameless glass to 3 m, the black mesh to 4 m on a steel rail.
	for x: float in [0.0, L]:
		_poly([_pr(x, 0, 0), _pr(x, Wd, 0), _pr(x, Wd, 3.0), _pr(x, 0, 3.0)], glass)
		# The glass's shine: a pale diagonal streak.
		_poly([_pr(x, 2.0, 0.4), _pr(x, 3.2, 0.4), _pr(x, 4.6, 2.6), _pr(x, 3.4, 2.6)], Color(1, 1, 1, 0.1))
		_mesh_panel(Vector3(x, 0, 3.0), Vector3(x, Wd, 4.0), mesh)
		_ln(_pr(x, 0, 3.0), _pr(x, Wd, 3.0), FRAME)
		_ln(_pr(x, 0, 4.0), _pr(x, Wd, 4.0), FRAME)
		_ln(_pr(x, Wd, 0), _pr(x, Wd, 4.0), FRAME)
		for k in 5:
			var gy := k * 2.5
			_ln(_pr(x, gy, 0), _pr(x, gy, 3.0), Color(0.85, 0.95, 1.0, 0.22))
		_ln(_pr(x, 0, 0), _pr(x, Wd, 0), FRAME)
	if _flash_t > 0.0:
		_canvas.draw_circle(_flash_p.round(), 3.0 + (1.0 - _flash_t) * 8.0, Color(1, 1, 1, 0.5 * _flash_t))
	# The floodlights, swan-necked, beyond the far corners.
	for x: float in [-1.0, L + 1.0]:
		_floodlight(x, Wd + 0.7, x < 0.0)


func _mesh_panel(a: Vector3, b: Vector3, c: Color) -> void:
	# A grid of thin lines between two corners of a vertical panel.
	var along_x := absf(b.x - a.x) > 0.01
	var n := int(absf((b.x - a.x) if along_x else (b.y - a.y)) / 0.5)
	for k in n + 1:
		var f := float(k) / maxf(n, 1)
		var p0 := Vector3(lerpf(a.x, b.x, f), lerpf(a.y, b.y, f), a.z)
		var p1 := Vector3(p0.x, p0.y, b.z)
		_ln(_proj(p0), _proj(p1), c)
	var m := int((b.z - a.z) / 0.5)
	for k in m + 1:
		var z := a.z + k * 0.5
		_ln(_proj(Vector3(a.x, a.y, z)), _proj(Vector3(b.x, b.y, z)), c)


func _floodlight(x: float, y: float, left: bool) -> void:
	var foot := _pr(x, y, 0)
	var top := _pr(x, y, 6.5)
	var s := 1.0 if left else -1.0
	var pole := Color("#101214")
	_ln(foot, top, pole)
	# The swan neck: a curve over and down to the flat head.
	var prev := top
	for k in 6:
		var a := (k + 1) / 6.0 * PI * 0.5
		var q := top + Vector2(s * sin(a) * 9.0, -cos(a) * 6.0 + 6.0 * 0.0 - sin(a) * 2.0)
		_ln(prev, q, pole)
		prev = q
	var head := prev + Vector2(s * 1.0, 0)
	_rect(head.x - 5, head.y, 10, 2, pole)
	if _night:
		_rect(head.x - 4, head.y + 2, 8, 1, Color("#fff6d8"))
		_poly([head + Vector2(-4, 3), head + Vector2(4, 3), head + Vector2(s * 40.0 + 30.0, 110), head + Vector2(s * 40.0 - 30.0, 110)], Color(1, 0.97, 0.85, 0.05))


func _draw_bodies() -> void:
	# Far to near: the players, the net's slices, the ball.
	var items: Array = []
	for pl in sim.players:
		items.append([pl.pos.y, 0, pl])
	for k in 10:
		items.append([k + 0.5, 1, k])
	if not sim.held or sim.phase == PadelSim.Phase.SERVE:
		items.append([sim.ball.p.y, 2, null])
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	# The ball's shadow first, under everything.
	var sh := _pr(sim.ball.p.x, sim.ball.p.y, 0)
	_rect(sh.x - 1, sh.y, 3, 1, Color(0, 0, 0, 0.45))
	for it: Array in items:
		match int(it[1]):
			0:
				_draw_player(it[2])
			1:
				_draw_net(int(it[2]))
			2:
				_draw_ball()


func _draw_net(k: int) -> void:
	var y0 := float(k)
	var y1 := y0 + 1.0
	var x := PadelSim.NET_X
	var h := PadelSim.NET_H
	_poly([_pr(x, y0, 0.05), _pr(x, y1, 0.05), _pr(x, y1, h), _pr(x, y0, h)], Color(0.03, 0.03, 0.04, 0.55))
	for j in 3:
		_ln(_pr(x, y0, h * (j + 1) / 4.0), _pr(x, y1, h * (j + 1) / 4.0), Color(0.2, 0.2, 0.22, 0.7))
	_ln(_pr(x, y0, h), _pr(x, y1, h), LINE)
	if k == 0 or k == 9:
		# The white padded posts with a red stripe.
		var yy := -0.15 if k == 0 else PadelSim.WID + 0.15
		var a := _pr(x, yy, 0)
		var b := _pr(x, yy, 1.05)
		_rect(a.x - 1, b.y, 3, a.y - b.y, LINE)
		_rect(a.x - 1, b.y + 4, 3, 2, Color("#d8282c"))


func _draw_ball() -> void:
	# The trail: fading dots; a glow when it's yours to hit.
	for i in range(_trail.size() - 1, 0, -1):
		var q := _proj(_trail[i])
		var a := 0.35 * (1.0 - float(i) / _trail.size())
		_rect(q.x - 1, q.y - 1, 2, 2, Color(BALL, a) if not _fire else Color(1, 0.5, 0.1, a * 1.6))
	var p := _proj(sim.ball.p)
	if _hit_glow > 0.0 and not sim.held:
		_canvas.draw_circle(p.round(), 4.0, Color(1, 1, 0.6, 0.35 * _hit_glow))
	_rect(p.x - 1, p.y - 1, 3, 3, BALL)
	_rect(p.x - 1, p.y - 1, 1, 1, Color(1, 1, 1, 0.9))
	_rect(p.x + 1, p.y + 1, 1, 1, BALL.darkened(0.35))


## A chibi player: about 18 px, the team's shirt, their own hair; the racket's swing smears.
func _draw_player(pl: PadelSim.Player) -> void:
	var foot := _pr(pl.pos.x, pl.pos.y, 0)
	var body := _pr(pl.pos.x, pl.pos.y, pl.jump)
	var x := roundf(body.x)
	var y := roundf(body.y)
	var us := pl.team == 0
	var shirt := US if us else THEM
	var shirt_d := US_DARK if us else THEM_DARK
	var face := 1.0 if us else -1.0
	# The shadow.
	_rect(foot.x - 4, foot.y - 1, 9, 2, Color(0, 0, 0, 0.4))
	var skins := [Color("#f1c8a4"), Color("#e2b08a"), Color("#d9a984"), Color("#c48d68")]
	var hairs := [Color("#4a2e1a"), Color("#e2c060"), Color("#bcbcbc"), Color("#2a2a2a")]
	var skin: Color = skins[pl.idx]
	var hair: Color = hairs[pl.idx]
	if _night:
		skin = skin.darkened(0.1)
	var step := int(pl.run * 2.2) % 2 if pl.vel.length() > 0.5 else 0
	# Legs and shoes.
	_rect(x - 3 + step, y - 5, 2, 4, skin)
	_rect(x + 1 - step, y - 5, 2, 4, skin)
	_rect(x - 3 + step, y - 1, 3, 1, LINE)
	_rect(x + 1 - step, y - 1, 3, 1, LINE)
	# Shorts, shirt (shaded), head and hair.
	_rect(x - 3, y - 7, 6, 2, Color("#262a36"))
	_rect(x - 3, y - 12, 6, 5, shirt)
	_rect(x + (1 if us else -3), y - 12, 2, 5, shirt_d)
	_rect(x - 3, y - 18, 6, 6, skin)
	match pl.idx:
		0:
			_rect(x - 3, y - 19, 6, 2, hair)
			_rect(x - 3, y - 18, 1, 2, hair)
		1:
			_rect(x - 3, y - 19, 6, 2, hair)
			_rect(x - 3, y - 17, 6, 1, LINE)   # the headband
		2:
			# Prezes: bald on top, grey sides, a moustache.
			_rect(x - 3, y - 17, 1, 3, hair)
			_rect(x + 2, y - 17, 1, 3, hair)
			_rect(x - 1 + (1 if us else -1), y - 14, 3, 1, hair.darkened(0.3))
		3:
			# Pan Zbyszek: a cap.
			_rect(x - 3, y - 20, 6, 3, Color("#f4f4f0"))
			_rect(x + (-5 if not us else 3), y - 18, 2, 1, Color("#f4f4f0"))
	_rect(x + (1 if us else -2), y - 16, 1, 1, Color("#1a1a1a"))
	# The racket arm: back, swinging through, or ready; the smear after a hit.
	var since := sim.time - pl.hit_at
	var ang := -0.6
	if pl.swing >= 0.0:
		ang = lerpf(-2.2, 0.8, minf(pl.swing / 0.12, 1.0))
	elif since < 0.2:
		ang = lerpf(0.9, 0.2, since / 0.2)
	var smash_pose := since < 0.3 and pl.jump > 0.1
	if smash_pose:
		ang = -1.6 + since * 8.0
	var sh := Vector2(x + face * 3.0, y - 11)
	var hand := sh + Vector2(cos(ang) * face, sin(ang)) * 4.0
	_ln(sh, hand, skin)
	var rk := hand + Vector2(cos(ang) * face, sin(ang)) * 4.0
	var rc := Color("#202428") if us else Color("#f4f4f0")
	_canvas.draw_circle(rk.round(), 2.5, rc)
	_canvas.draw_circle(rk.round(), 1.2, shirt)
	if since < 0.15:
		var a := 1.0 - since / 0.15
		var c := Color(shirt.lightened(0.5), 0.6 * a)
		_canvas.draw_arc(sh.round(), 8.0, -1.8 if face > 0 else PI + 1.8, 0.9 if face > 0 else PI - 0.9, 8, c, 2.0)
	# You: a small arrow and the word over your head; the ring under you when the ball's in reach.
	if pl.human:
		var tag := Color(GOLD, 0.6 + 0.4 * sin(_t * 6.0))
		_rect(x - 1, y - 24, 3, 1, tag)
		_rect(x, y - 23, 1, 1, tag)
		if _hit_glow > 0.0:
			_canvas.draw_set_transform(foot.round(), 0.0, Vector2(1.0, 0.45))
			_canvas.draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color(0.6, 1.0, 0.4, 0.9 * _hit_glow), 1.0)
			_canvas.draw_set_transform(Vector2.ZERO)


func _draw_parts() -> void:
	for p: Array in _parts:
		var q := _proj(p[0])
		var a := clampf(float(p[2]) / float(p[3]), 0.0, 1.0)
		var c: Color = p[4]
		var s := float(p[5])
		_rect(q.x, q.y, s, s, Color(c, a))


## The near side: only the frame's foot rail, posts and the end glass, faint, so the court shows.
func _draw_walls_near() -> void:
	var L := PadelSim.LEN
	_ln(_pr(0, 0, 0), _pr(L, 0, 0), FRAME)
	for k in 11:
		var x := k * 2.0
		_ln(_pr(x, 0, 0), _pr(x, 0, 0.6), FRAME)
	for x0: float in [0.0, L - 2.0]:
		_poly([_pr(x0, 0, 0), _pr(x0 + 2.0, 0, 0), _pr(x0 + 2.0, 0, 3.0), _pr(x0, 0, 3.0)], Color(0.75, 0.9, 0.95, 0.06))
	# The near corners' posts and top rails, to 4 m at the back walls.
	for x: float in [0.0, L]:
		_ln(_pr(x, 0, 0), _pr(x, 0, 4.0), FRAME)
		_ln(_pr(x, 0, 4.0), _pr(x, PadelSim.WID, 4.0), FRAME)
	for x: float in [-1.0, L + 1.0]:
		_floodlight(x, -0.9, x < 0.0)


## The foreground: the lawn's edge and maple leaves over the top corners (the deckchairs stand on
## the lawn beside the court, `_draw_chairs`, so the thumbs never cover them).
func _draw_front() -> void:
	var px := _cam_x * 1.4
	var lawn: Color = _palette["lawn"]
	_rect(0, H - 6, W, 6, lawn.darkened(0.2))
	# Leaves: dark maple silhouettes that sway.
	var leaf := Color("#173a1a", 0.85) if not _night else Color("#050c08", 0.9)
	for i in 7:
		var a := float(i)
		var lx := -10.0 + a * 14.0 + sin(_t * 0.8 + a) * 2.0 + px * 0.3
		var ly := -6.0 + fmod(a * 7.0, 13.0)
		_maple(Vector2(lx, ly), 9.0 + fmod(a * 3.0, 5.0), leaf)
	for i in 5:
		var a := float(i)
		var lx := W + 8.0 - a * 15.0 + sin(_t * 0.7 + a * 2.0) * 2.0 + px * 0.3
		var ly := -4.0 + fmod(a * 9.0, 15.0)
		_maple(Vector2(lx, ly), 8.0 + fmod(a * 2.0, 5.0), leaf)


## The club's beige sling deckchairs with DESKA on the cloth, on the lawn by the court (F's photos).
func _draw_chairs() -> void:
	for spot: Vector3 in [Vector3(-2.6, 6.5, 1.0), Vector3(-2.4, 3.2, 1.0), Vector3(22.4, 3.5, -1.0)]:
		var b := _pr(spot.x, spot.y, 0).round()
		var s := spot.z
		var fr := Color("#121416")
		var cloth := Color("#e9dfc6") if not _night else Color("#8c8676")
		# Back legs up to the top bar, front legs to the seat, the sling between.
		_ln(b + Vector2(-6 * s, 0), b + Vector2(-2 * s, -20), fr)
		_ln(b + Vector2(6 * s, 0), b + Vector2(3 * s, -9), fr)
		_ln(b + Vector2(-1 * s, 0), b + Vector2(-5 * s, -13), fr)
		_poly([b + Vector2(-3 * s, -21), b + Vector2(5 * s, -22), b + Vector2(9 * s, -8), b + Vector2(2 * s, -6)], cloth)
		_ln(b + Vector2(3 * s, -8), b + Vector2(9 * s, -9), fr)
		_rect(b.x - 1 + (1 if s > 0 else -3), b.y - 18, 4, 1, Color("#4a3222"))
		_rect(b.x - 1 + (1 if s > 0 else -3), b.y - 16, 3, 1, Color("#4a3222"))


func _maple(c: Vector2, r: float, col: Color) -> void:
	var pts: Array = []
	for k in 10:
		var a := k / 10.0 * TAU + 0.3
		var rr := r * (1.0 if k % 2 == 0 else 0.5)
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	_poly(pts, col)


## The flip-card scoreboard on the lawn, left of the court: each pair's call in its colour, the
## games as dots.
func _draw_board() -> void:
	var a := _pr(PadelSim.LEN + 2.4, PadelSim.WID - 1.0, 0)
	var x := roundf(a.x - 2)
	var y := roundf(a.y - 40)
	var wood := Color("#7a5232") if not _night else Color("#4a3220")
	_rect(x + 4, y + 22, 2, 16, wood)
	_rect(x + 30, y + 22, 2, 16, wood)
	_rect(x, y, 36, 23, wood)
	var flip := _score_flip
	for k in 2:
		var cx := x + 2 + k * 17
		var c := US if k == 0 else THEM
		var hgt := roundf(14.0 * (1.0 - absf(sin(flip * PI)) * 0.8))
		_rect(cx, y + 2 + (14 - hgt) * 0.5, 15, hgt, c.darkened(0.15))
		_rect(cx, y + 9, 15, 1, Color(0, 0, 0, 0.35))
		if hgt > 10:
			_text(sim.call_of(k), cx + 8, y + 2, LINE, 1, true, false)
		for g in int(sim.games[k]):
			_rect(cx + 4 + g * 5, y + 18, 3, 3, GOLD)
	# Also a clear strip at the top for the phone.
	var top := "%s  %s : %s  %s" % [_you_name() + "+" + partner.to_upper(), sim.call_of(0), sim.call_of(1), (String(rivals[0]) + "+" + String(rivals[1])).to_upper()]
	_rect(W * 0.5 - PixelFont.width(top) * 0.5 - 4, 2, PixelFont.width(top) + 8, 12, Color(0, 0, 0, 0.45))
	_text(top, W * 0.5, 1, LINE, 1, true, false)
	for k in 2:
		for g in int(sim.games[k]):
			_rect(W * 0.5 + (-1.0 if k == 0 else 1.0) * (PixelFont.width(top) * 0.5 + 8 + g * 5) - 1, 5, 3, 3, US if k == 0 else THEM)


func _draw_texts() -> void:
	if _callout_t > 0.0 and _callout != "":
		var pop := 1 if _callout_t < 0.15 else 2
		_text(_callout, W * 0.5, 34, _callout_c.lightened(0.15), pop)
	if _sub_t > 0.0 and _sub != "":
		var lines := PixelFont.wrap_lines(_sub.to_upper(), W - 40)
		for i in lines.size():
			var w := PixelFont.width(lines[i])
			_rect(W * 0.5 - w * 0.5 - 3, 58 + i * 11, w + 6, 11, Color(0, 0, 0, 0.5))
			_text(lines[i], W * 0.5, 58 + i * 11, Color(1, 1, 1), 1, true, false)


# --- the touch pad (native pixels) --------------------------------------------------------------

func _pt() -> float:
	if hud != null and "pt" in hud:
		return float(hud.pt)
	return maxf(get_viewport().get_visible_rect().size.y / 720.0, 0.5)


func _hit_c() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return s - Vector2(96, 92) * _pt()


func _lob_c() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return s - Vector2(212, 70) * _pt()


func _quit_c() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	return Vector2(s.x - 34 * _pt(), 34 * _pt())


func _draw_pad() -> void:
	var pt := _pt()
	var font := ThemeDB.fallback_font
	# The stick: its base where the thumb landed, or a ghost bottom left.
	var base := _stick_base if _stick_on else Vector2(110, get_viewport().get_visible_rect().size.y / pt - 100) * pt
	var knob := _stick_knob if _stick_on else base
	var ghost := 1.0 if _stick_on else 0.35
	_pad.draw_circle(base, 60 * pt, Color(1, 1, 1, 0.08 * ghost))
	_pad.draw_arc(base, 60 * pt, 0, TAU, 40, Color(1, 1, 1, 0.35 * ghost), 2.0 * pt)
	_pad.draw_circle(knob, 26 * pt, Color(1, 1, 1, 0.3 * ghost))
	# HIT: big, glowing when the ball is in reach; LOB smaller.
	var hc := _hit_c()
	var glow := _hit_glow
	_pad.draw_circle(hc, (62 + glow * 6) * pt, Color(US, 0.25 + 0.35 * glow + 0.3 * _hit_press))
	_pad.draw_arc(hc, (62 + glow * 6) * pt, 0, TAU, 40, Color(1, 1, 1, 0.7), 3.0 * pt)
	_label(font, _line("hit"), hc, 20 * pt)
	var smash_ready := not sim.held and sim.ball.p.z > 1.85 and sim.bounces == 0 and sim.can_hit(sim.players[0])
	if smash_ready:
		_label(font, _line("smash"), hc + Vector2(0, 24 * pt), 12 * pt)
	var lc := _lob_c()
	_pad.draw_circle(lc, 42 * pt, Color(THEM, 0.25 + 0.3 * _lob_press))
	_pad.draw_arc(lc, 42 * pt, 0, TAU, 32, Color(1, 1, 1, 0.6), 2.5 * pt)
	_label(font, _line("lob"), lc, 17 * pt)
	var qc := _quit_c()
	_pad.draw_circle(qc, 20 * pt, Color(0, 0, 0, 0.45))
	_label(font, "X", qc, 18 * pt)


func _label(font: Font, s: String, c: Vector2, size: float) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, int(size))
	_pad.draw_string(font, c + Vector2(-sz.x * 0.5, sz.y * 0.3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size), Color(1, 1, 1, 0.95))


func _input(event: InputEvent) -> void:
	if not inside:
		return
	var pt := _pt()
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			var what := _zone(e.position, pt)
			_touches[e.index] = what
			match what:
				"hit":
					_press(PadelSim.Shot.DRIVE)
				"lob":
					_press(PadelSim.Shot.LOB)
				"quit":
					leave()
				"stick":
					_stick_on = true
					_stick_base = e.position
					_stick_knob = e.position
		else:
			if String(_touches.get(e.index, "")) == "stick":
				_stick_on = false
			_touches.erase(e.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if String(_touches.get(e.index, "")) == "stick":
			var d := e.position - _stick_base
			_stick_knob = _stick_base + d.limit_length(60 * pt)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		var on := k.pressed
		match k.keycode:
			KEY_LEFT, KEY_A:
				_keys.x = -1.0 if on else (0.0 if _keys.x < 0 else _keys.x)
			KEY_RIGHT, KEY_D:
				_keys.x = 1.0 if on else (0.0 if _keys.x > 0 else _keys.x)
			KEY_UP, KEY_W:
				_keys.y = 1.0 if on else (0.0 if _keys.y > 0 else _keys.y)
			KEY_DOWN, KEY_S:
				_keys.y = -1.0 if on else (0.0 if _keys.y < 0 else _keys.y)
			KEY_SPACE, KEY_J:
				if on:
					_press(PadelSim.Shot.DRIVE)
			KEY_K, KEY_L:
				if on:
					_press(PadelSim.Shot.LOB)
			KEY_ESCAPE:
				if on:
					leave()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		# Touch comes in as touch (emulated from the mouse on a desktop too); the mouse is ignored.
		get_viewport().set_input_as_handled()


func _zone(p: Vector2, pt: float) -> String:
	if p.distance_to(_quit_c()) < 30 * pt:
		return "quit"
	if p.distance_to(_hit_c()) < 78 * pt:
		return "hit"
	if p.distance_to(_lob_c()) < 54 * pt:
		return "lob"
	if p.x < get_viewport().get_visible_rect().size.x * 0.55:
		return "stick"
	# Anywhere else on the right: a hit (a big target for a thumb).
	return "hit"


func _press(shot: int) -> void:
	if auto_play:
		return
	if shot == PadelSim.Shot.LOB:
		_lob_press = 1.0
	else:
		_hit_press = 1.0
	sim.press(shot)


# --- sound --------------------------------------------------------------------------------------

func _build_audio() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx.append(p)
	_sounds = make_sounds()
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.stream = make_music()
	_music.volume_db = -10.0
	add_child(_music)
	_amb = AudioStreamPlayer.new()
	_amb.bus = &"Ambience"
	var murmur := "res://audio/sfx/crowd_murmur.wav"
	if ResourceLoader.exists(murmur):
		_amb.stream = load(murmur)
	_amb.volume_db = -4.0
	add_child(_amb)


func _play(name: String, db := 0.0, pitch := 1.0) -> void:
	if _sfx.is_empty() or not _sounds.has(name):
		return
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = _sounds[name]
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


static func _wav(data: PackedFloat32Array, rate: int, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w


## The match's effects, made from sines and noise: the racket's pok, the bounce, the glass, the
## mesh's rattle, the net, the crowd's cheer and ooh, the point chime.
static func make_sounds() -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = 4
	var out := {}
	var n: int
	var d := PackedFloat32Array()
	# Pok: a short knock with a click.
	n = int(RATE * 0.1)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		d[i] = (sin(TAU * 620.0 * t) * 0.7 + sin(TAU * 1240.0 * t) * 0.2) * exp(-t * 55.0) + r.randf_range(-1, 1) * exp(-t * 300.0) * 0.5
	out["hit"] = _wav(d, RATE)
	d = PackedFloat32Array()
	n = int(RATE * 0.08)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		d[i] = sin(TAU * (190.0 - t * 600.0) * t) * exp(-t * 45.0) * 0.8 + r.randf_range(-1, 1) * exp(-t * 200.0) * 0.2
	out["bounce"] = _wav(d, RATE)
	d = PackedFloat32Array()
	n = int(RATE * 0.45)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		d[i] = (sin(TAU * 1310.0 * t) * 0.3 + sin(TAU * 1975.0 * t) * 0.22 + sin(TAU * 2790.0 * t) * 0.15) * exp(-t * 9.0) \
				+ sin(TAU * 160.0 * t) * exp(-t * 40.0) * 0.6 + r.randf_range(-1, 1) * exp(-t * 120.0) * 0.3
	out["glass"] = _wav(d, RATE)
	d = PackedFloat32Array()
	n = int(RATE * 0.3)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		d[i] = r.randf_range(-1, 1) * exp(-t * 12.0) * (0.5 + 0.5 * signf(sin(TAU * 34.0 * t))) * 0.5
	out["mesh"] = _wav(d, RATE)
	d = PackedFloat32Array()
	n = int(RATE * 0.18)
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.08
		d[i] = lp * exp(-t * 18.0) * 2.0
	out["net"] = _wav(d, RATE)
	# The cheer: a swell of filtered noise with whoops.
	d = PackedFloat32Array()
	n = int(RATE * 1.8)
	d.resize(n)
	lp = 0.0
	var bp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.25
		bp += (lp - bp) * 0.5
		var env := minf(t * 5.0, 1.0) * exp(-maxf(t - 0.5, 0.0) * 2.2)
		var whoop := 0.0
		for k in 3:
			var t0 := 0.1 + k * 0.35
			if t > t0 and t < t0 + 0.4:
				var u := t - t0
				whoop += sin(TAU * (500.0 + k * 140.0 + u * 700.0) * u) * sin(u / 0.4 * PI) * 0.12
		d[i] = (lp - bp * 0.5) * env * 0.9 + whoop
	out["cheer"] = _wav(d, RATE)
	# The ooh: a low voiced swell.
	d = PackedFloat32Array()
	n = int(RATE * 1.0)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := sin(minf(t / 1.0, 1.0) * PI)
		var f0 := 150.0 - t * 30.0
		var v := sin(TAU * f0 * t) * 0.5 + sin(TAU * f0 * 2.0 * t) * 0.3 + sin(TAU * f0 * 3.0 * t) * 0.15
		d[i] = (v * 0.5 + r.randf_range(-1, 1) * 0.12) * env * 0.7
	out["ooh"] = _wav(d, RATE)
	d = PackedFloat32Array()
	n = int(RATE * 0.35)
	d.resize(n)
	for i in n:
		var t := float(i) / RATE
		var f := 880.0 if t < 0.12 else 1320.0
		d[i] = signf(sin(TAU * f * t)) * 0.18 * exp(-fmod(t, 0.12) * 14.0)
	out["chime"] = _wav(d, RATE)
	return out


## The chiptune loop: 120 BPM, four bars (8 s), a square lead, a triangle bass, noise hats; it ends
## where it starts.
static func make_music() -> AudioStreamWAV:
	var beats := 16
	var spb := 60.0 / BPM
	var n := int(MUSIC_RATE * beats * spb)
	var d := PackedFloat32Array()
	d.resize(n)
	# A minor-ish sunny progression: A, F, C, G (roots in Hz), the lead in eighths over it.
	var roots := [110.0, 87.31, 130.81, 98.0]
	var lead := [[0, 7, 12, 7, 15, 12, 7, 12], [0, 7, 12, 16, 12, 7, 4, 7], [0, 4, 7, 12, 16, 12, 7, 4], [0, 7, 11, 14, 11, 7, 2, 7]]
	var r := RandomNumberGenerator.new()
	r.seed = 12
	var noise := 0.0
	for i in n:
		var t := float(i) / MUSIC_RATE
		var beat := t / spb
		var bar := int(beat / 4.0) % 4
		var root: float = roots[bar]
		var eighth := int(beat * 2.0) % 8
		var semis: int = lead[bar][eighth]
		var fl := root * 4.0 * pow(2.0, semis / 12.0)
		var et := fmod(beat * 2.0, 1.0) * spb * 0.5
		var sq := (1.0 if fmod(t * fl, 1.0) < 0.25 else -1.0) * 0.09 * exp(-et * 6.0)
		var bt := fmod(beat, 1.0) * spb
		var bf := root * (1.0 if int(beat) % 2 == 0 else 1.5)
		var tri := (absf(fmod(t * bf, 1.0) * 4.0 - 2.0) - 1.0) * 0.16 * exp(-bt * 3.0)
		var ht := fmod(beat * 2.0, 1.0) * spb * 0.5
		noise = r.randf_range(-1, 1)
		var hat := noise * 0.05 * exp(-ht * 60.0)
		var kick := 0.0
		if int(beat) % 2 == 0:
			kick = sin(TAU * (60.0 + 90.0 * exp(-bt * 30.0)) * bt) * 0.25 * exp(-bt * 12.0)
		else:
			kick = noise * 0.08 * exp(-bt * 22.0)
		d[i] = sq + tri + hat + kick
	return _wav(d, MUSIC_RATE, true)
