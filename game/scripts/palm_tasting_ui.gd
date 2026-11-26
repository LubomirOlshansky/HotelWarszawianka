extends Node
## The tasting at the Palm, drawn as Zbyszek's livestream (palm_tasting.gd's rules; plan doc "First
## 10 minutes: Tajny klient", "The river scene and the viral moment", moved to the Palm at Rondo de
## Gaulle'a by F): full screen, the city's 3D off while it is up (GameCtx.city_drawn), like the
## kebab stand and beer pong.
##
## The look: pixel art with more pixels (F 2026-11-26: first "too pixel ... more detail, the persons
## fake 3D, fine animations and emotions", then at 19:33 "it should be the pixel style ... with more
## pixels", after an isometric pixel-city reference). The cel-shaded shapes of toon_pen.gd are drawn
## on the 216-unit grid into a pixel viewport at the screen divided by a whole number (~360-400
## rows), nearest-filtered with no antialiasing, and pixel_art.gdshader adds one-pixel ink outlines
## in each shape's own hue and steps the gradients into bands. The props carry pixel-model detail:
## window crosses, AC boxes, geranium boxes, balconies, shop signs, chimneys, a dish and an aerial,
## granite kerbs, bollards, a bin, a hydrant. One warm key light from screen-left (the sun low
## behind the Party House), three tones and a rim on every form, contact and long cast shadows.
## The stream's own overlay (chips, chat, bubble, scoreboard, card) stays sharp at the screen's
## resolution: it is the phone app over the camera's picture.
##   - far: the sky, the Party House, Nowy Świat's fronts and the haze, drawn once;
##   - middle: the roundabout's carriageway, cars both ways, a tram every TRAM_S, the Palm on its
##     island;
##   - near: the pavement, Kebabulo's Porsza, a pigeon, the player, Kebabulo, Zbyszek with his
##     gimbal, and the fan who walks up for a photo after the grade;
##   - the handheld sway moves the layers by different amounts; the MLASK and the grade punch in.
## The acting: breathing, weight shifts, blinks, the mouth following the line's letters, the chew
## cycle and the bliss in the close-up, surprise at the MLASK, a face per grade, the fan's shuffle
## and the selfie with its one flash and the instant print, which lands on the RECENZJA card.
## The stream's own layer: REC corners and a timecode, NA ŻYWO and the viewers (an odometer with a
## green +N), three chat lines on a scrim bottom left, the speaker's bubble above the speaker's
## head, hold × to skip, hearts and little kebabs rising at the big moments.
##
## Touch: a tap anywhere advances, a hold on the skip chip skips. Keys for the Mac: Space or Enter
## a tap, Esc held the skip. Access.calm: no shake, no punch, no flash (a soft warm one).
##
## Cost: while it is up the city's 3D is off; the frame is the cached far texture, about 1,200
## untextured polygons in the pixel viewport, the overlay viewport and one full-screen post pass;
## closed, both live viewports are switched off, so nothing runs per frame.

const Tasting := preload("res://scripts/palm_tasting.gd")
const Pen := preload("res://scripts/toon_pen.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Access := preload("res://scripts/access.gd")

const H := 216
const MIN_W := 384
## The most lines the viewport draws (a 1170-line phone draws 1080 and scales a little).
const MAX_LINES := 1080
## About how many pixel rows the scene has (the screen divided by the nearest whole number).
const PIXEL_LINES := 380.0
const PIXEL_ART := preload("res://shaders/pixel_art.gdshader")
const ROAD_Y := 112.0
const PAVE_Y := 150.0
const FEET := 200.0
const TRAM_S := 12.0
const WIPE_S := 0.45
const TOUCH_PT := 44.0
## Text sizes in grid units (216 to the screen's height).
const T_CHIP := 6.0
const T_CHAT := 6.6
const T_LINE := 7.6
const T_NAME := 5.6
## The scoreboard's width (the line's bubble keeps right of it).
const SCORE_W := 116.0

# --- the palette (base, shade, light) ---
const SKIN := [Color("#e6b48e"), Color("#b97a5e"), Color("#f7d2ac")]
const SKIN_TAN := [Color("#d9a07a"), Color("#a86a4c"), Color("#f0c098")]
const SKIN_FAIR := [Color("#f0c6a6"), Color("#c98e72"), Color("#ffe0c4")]
const HOODIE := [Color("#e2561c"), Color("#a8351a"), Color("#ff8038")]
const BLACK := [Color("#1e1d24"), Color("#121118"), Color("#3a3c48")]
const JACKET := [Color("#1f8fb0"), Color("#15607e"), Color("#49b8d4")]
const JEANS := [Color("#34466e"), Color("#232f4c"), Color("#4d6492")]
const CHARCOAL := [Color("#3a3d46"), Color("#24262e"), Color("#565a66")]
const DARK_JEANS := [Color("#2a3040"), Color("#1a1e2a"), Color("#3c4458")]
const PUFFER := [Color("#d8457a"), Color("#9c2c5c"), Color("#f47aa6")]
const LIGHT_JEANS := [Color("#7f9ac0"), Color("#5a7298"), Color("#a4bcdc")]
const MUSTARD := Color("#e8b23a")
const WHITE_SHOE := Color("#f4f1e6")
const INK := Color("#16191d")
const GOLD := Color("#ffd23a")
const GOLD_D := Color("#c8901a")
const CREAM := Color("#fff6e6")
const RED := Color("#ff3b5c")
const GREEN := Color("#5fd38a")
const MOUTH := Color("#5a1e1a")
const TONGUE := Color("#d9605a")
const BLUSH := Color("#e8846a")
const TORTILLA := [Color("#ecd8a4"), Color("#c9a86c"), Color("#fff0c8")]
const FOIL := [Color("#c9d2d8"), Color("#8f9aa4"), Color("#eef4f8")]
const MEAT := Color("#9a4a24")
const LETTUCE := Color("#6cc04a")
const TOMATO := Color("#e0402a")
const SAUCE := Color("#fff8ec")
const PORSZA := [Color("#eeebe2"), Color("#b9b4c2"), Color("#ffffff")]
const PIGEON := [Color("#8a8f9a"), Color("#5e6270"), Color("#b4b8c4")]
const NICKS := [Color("#ffd23f"), Color("#1ae6ff"), Color("#ff7ab8"), Color("#9be36a"), Color("#ffa35c")]

signal finished(result: Dictionary)

var tasting: Tasting
var pt := 1.0
var auto_play := false
var log_on := false
var inside := false
## Plays a short sound by name (the owner's hud.cue): "tick", "win", "mlask", "drumroll", "voice_*".
var cue := Callable()
var W := MIN_W

var _layer: CanvasLayer
var _vp: SubViewport
var _px_vp: SubViewport
var _far_vp: SubViewport
var _far: Node2D
var _scene: Node2D
var _mid: Node2D
var _ui: Node2D
var _tex: TextureRect
var _px_tex: TextureRect
var _pen: Pen
var _far_pen: Pen
var _mid_pen: Pen
var _ui_pen: Pen
## Scene pixels per grid unit (the pixel viewport's canvas scale).
var _kp := 1.0
var _t := 0.0
var _wipe := 0.0
var _leaving := false
var _skip_held := false
var _key_skip := false
var _last_phase := -1
var _last_said := ""
var _shake := 0.0
var _punch := 0.0
var _flash := 0.0
var _skip_rect := Rect2()
## The viewer count as drawn (it rolls toward the real one) and the last "+N".
var _shown_viewers := 0.0
var _plus := 0
var _plus_t := 9.0
## Hearts and little kebabs rising up the right edge: {x, t, kind, wob}.
var _floaters: Array = []
## The 11/10's confetti: {p, v, t, c, r}.
var _bits: Array = []
var _rng := RandomNumberGenerator.new()
## The fan's x (eased in).
var _fan_x := -40.0


func _ready() -> void:
	set_process(false)


# --- in and out ---------------------------------------------------------------------------------

## `spec` as palm_tasting.gd's `_init`.
func open(spec: Dictionary) -> void:
	if _layer == null:
		_build()
	tasting = Tasting.new(spec)
	tasting.auto_play = auto_play
	_t = 0.0
	_wipe = 0.0
	_leaving = false
	_skip_held = false
	_key_skip = false
	_last_phase = -1
	_last_said = ""
	_shake = 0.0
	_punch = 0.0
	_flash = 0.0
	_floaters.clear()
	_bits.clear()
	_rng.seed = 7
	_shown_viewers = float(tasting.viewers)
	_plus_t = 9.0
	_fan_x = -40.0
	inside = true
	_layer.visible = true
	_live(true)
	_resize()
	set_process(true)
	_log("open: grade %s" % tasting.grade_label)


## Taken down at once by its owner (the run dropped): no `finished`.
func hide_now() -> void:
	inside = false
	if _layer != null:
		_layer.visible = false
		_live(false)
	set_process(false)


func _close() -> void:
	inside = false
	_layer.visible = false
	_live(false)
	set_process(false)
	_log("done: " + tasting.summary())
	finished.emit(tasting.result())


func _log(text: String) -> void:
	if log_on:
		print("palm tasting: " + text)


func _cue(n: String) -> void:
	if cue.is_valid():
		cue.call(n)


func _w(tag: String) -> String:
	var p: Array = Tasting.say(tag)
	return Lang.pick(str(p[0]), str(p[1]))


func _pick(l: Array) -> String:
	return Lang.pick(str(l[0]), str(l[1])) if l.size() >= 2 else ""


# --- building -----------------------------------------------------------------------------------

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	# The pixel layer: the scene at a whole fraction of the screen, nearest, no antialiasing.
	_far_vp = _pixel_vp(false)
	_far = Node2D.new()
	_far.draw.connect(_draw_far)
	_far_vp.add_child(_far)
	_far_pen = Pen.new(_far)
	_px_vp = _pixel_vp(true)
	_scene = Node2D.new()
	_scene.draw.connect(_draw_scene)
	_px_vp.add_child(_scene)
	# the close-up, the MLASK burst, the hearts and the confetti: art, so pixels too
	_mid = Node2D.new()
	_mid.draw.connect(_draw_mid)
	_px_vp.add_child(_mid)
	_pen = Pen.new(_scene)
	_mid_pen = Pen.new(_mid)
	for pen: Pen in [_far_pen, _pen, _mid_pen]:
		pen.hard = true
	# The stream's own overlay (the phone app over the camera's picture): sharp, screen resolution.
	_vp = SubViewport.new()
	_vp.size = Vector2i(MIN_W, H)
	_vp.disable_3d = true
	_vp.transparent_bg = true
	_vp.msaa_2d = Viewport.MSAA_2X
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_ui = Node2D.new()
	_ui.draw.connect(_draw_ui)
	_vp.add_child(_ui)
	_ui_pen = Pen.new(_ui)
	_px_tex = _shown(_px_vp, CanvasItem.TEXTURE_FILTER_NEAREST)
	var mat := ShaderMaterial.new()
	mat.shader = PIXEL_ART
	_px_tex.material = mat
	_tex = _shown(_vp, CanvasItem.TEXTURE_FILTER_LINEAR)
	_layer.visible = false
	if is_inside_tree():
		get_viewport().size_changed.connect(_resize)


## The two live viewports render only while the scene is up (closed, they cost nothing).
func _live(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	_px_vp.render_target_update_mode = mode
	_vp.render_target_update_mode = mode


func _pixel_vp(always: bool) -> SubViewport:
	var v := SubViewport.new()
	v.size = Vector2i(MIN_W, H)
	v.disable_3d = true
	v.transparent_bg = false
	v.msaa_2d = Viewport.MSAA_DISABLED
	v.snap_2d_vertices_to_pixel = true
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS if always else SubViewport.UPDATE_ONCE
	add_child(v)
	return v


func _shown(v: SubViewport, filter: CanvasItem.TextureFilter) -> TextureRect:
	var r := TextureRect.new()
	r.texture = v.get_texture()
	r.texture_filter = filter
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(r)
	return r


func _resize() -> void:
	if _vp == null or not is_inside_tree():
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	var lines := clampf(minf(s.y, MAX_LINES), float(H), float(MAX_LINES))
	var k := lines / float(H)
	_vp.size = Vector2i(roundi(W * k), roundi(H * k))
	_vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(k, k))
	# The pixel layer: the screen divided by a whole number, ~360-400 lines (the old look had 216),
	# so each scene pixel is the same whole number of screen pixels.
	var n := maxi(1, roundi(s.y / PIXEL_LINES))
	_kp = floorf(s.y / n) / float(H)
	for v: SubViewport in [_px_vp, _far_vp]:
		v.size = Vector2i(maxi(1, roundi(W * _kp)), maxi(1, roundi(H * _kp)))
		v.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(_kp, _kp))
	_far_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_far.queue_redraw()
	(_px_tex.material as ShaderMaterial).set_shader_parameter("px", Vector2(_px_vp.size))
	_pen.k = _kp
	_mid_pen.k = _kp
	_far_pen.k = _kp
	_ui_pen.k = k
	pt = float(ScreenPoints.measure(s)["pt"])


func _scale() -> float:
	return get_viewport().get_visible_rect().size.y / float(H)


func _to_canvas(p: Vector2) -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var k := _scale()
	return Vector2((p.x - (s.x - W * k) * 0.5) / k, p.y / k)


func _safe_canvas() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var s := get_viewport().get_visible_rect().size
	var safe: Rect2 = ScreenPoints.measure(s)["safe"]
	var k := _scale()
	return Vector2(safe.position.x / k, (s.x - safe.end.x) / k)


func _touch_px() -> float:
	if not is_inside_tree():
		return 24.0
	return TOUCH_PT * pt / _scale()


# --- the frame ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside:
		return
	_t += dt
	if _leaving:
		_wipe = minf(1.0, _wipe + dt / WIPE_S)
		if _wipe >= 1.0:
			_close()
			return
	else:
		tasting.tick(dt, _skip_held or _key_skip)
		if tasting.done():
			_leaving = true
	_react()
	_shake = maxf(0.0, _shake - dt)
	_punch = maxf(0.0, _punch - dt * 1.6)
	_flash = maxf(0.0, _flash - dt)
	_plus_t += dt
	_shown_viewers = lerpf(_shown_viewers, float(tasting.viewers), 1.0 - exp(-dt * 4.0))
	_fan_tick(dt)
	_particles(dt)
	# The camera: the punch-in about the middle and the decaying shake.
	var z := 1.0 + (0.0 if Access.calm else 0.06 * Pen.ease_out(_punch))
	var off := Vector2.ZERO
	if _shake > 0.0 and not Access.calm:
		var a := _shake / 0.5
		off = Vector2(sin(_t * 71.0), cos(_t * 53.0)) * 2.2 * a * a
	_scene.scale = Vector2(z, z)
	_scene.position = _snap(Vector2(W, H) * 0.5 * (1.0 - z) + off)
	_scene.queue_redraw()
	_mid.queue_redraw()
	_ui.queue_redraw()


func _react() -> void:
	var said := "%s|%s" % [tasting.who, tasting.line[0]]
	if said != _last_said:
		_last_said = said
		if tasting.who != "":
			_cue("voice_" + tasting.who)
	var p := int(tasting.phase)
	if p == _last_phase:
		return
	_last_phase = p
	match tasting.phase:
		Tasting.Phase.MLASK:
			_shake = 0.5
			_punch = 1.0
			_cue("mlask")
			Access.buzz(120, 1.0)
			_rise(6)
		Tasting.Phase.DRUM:
			_cue("drumroll")
		Tasting.Phase.GRADE:
			_shake = 0.45 if tasting.perfect else 0.0
			_punch = 0.7
			if tasting.perfect:
				_cue("win")
				_confetti()
				_flash = 0.08
			Access.buzz(200, 1.0)
			_rise(10 if tasting.perfect else 4)
			_log("grade %s" % tasting.grade_label)
		Tasting.Phase.FAN:
			_fan_x = -30.0
		Tasting.Phase.SELFIE:
			_rise(5)
		Tasting.Phase.CARD:
			_log("card%s" % (" (skipped)" if tasting.skipped else ""))
	if tasting.viewers > int(_shown_viewers) + 30:
		_plus = tasting.viewers - int(_shown_viewers)
		_plus_t = 0.0


func _fan_tick(dt: float) -> void:
	var ph := tasting.phase
	if ph == Tasting.Phase.FAN or ph == Tasting.Phase.SELFIE:
		_fan_x = lerpf(_fan_x, _fan_goal(), 1.0 - exp(-dt * 5.0))
	elif ph == Tasting.Phase.CARD:
		_fan_x += dt * 60.0


func _fan_goal() -> float:
	return _kebabulo_x() - 38.0 if tasting.phase == Tasting.Phase.SELFIE else _kebabulo_x() - 50.0


# --- touch --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not inside or _leaving:
		return
	var vp := get_viewport()
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.index != 0:
			return
		var c := _to_canvas(e.position)
		if e.pressed:
			if _skip_rect.has_point(c) and tasting.phase < Tasting.Phase.CARD:
				_skip_held = true
			elif tasting.tap():
				_cue("tick")
		else:
			_skip_held = false
		vp.set_input_as_handled()
	elif event is InputEventScreenDrag:
		vp.set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		if k.keycode == KEY_ESCAPE:
			_key_skip = k.pressed
		elif k.pressed and (k.keycode == KEY_SPACE or k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER):
			if tasting.tap():
				_cue("tick")
		vp.set_input_as_handled()


# --- where things stand ---------------------------------------------------------------------------

func _palm_x() -> float:
	return W * 0.47


func _you_x() -> float:
	var x := W * 0.36
	if tasting != null and tasting.phase == Tasting.Phase.FAN:
		x -= 10.0 * Pen.ease_out(tasting.t / 0.5)
	elif tasting != null and tasting.phase == Tasting.Phase.SELFIE:
		x -= 10.0
	return x


func _kebabulo_x() -> float:
	return W * 0.57


func _zbyszek_x() -> float:
	return W * 0.86


## The handheld sway: the near layer moves the most.
func _sway(depth: float) -> Vector2:
	if Access.calm:
		return Vector2.ZERO
	return _snap(Vector2(sin(_t * TAU / 6.0) * 1.4, sin(_t * TAU / 4.3 + 0.7) * 0.7) * depth)


## To whole scene pixels, so a layer moves a pixel at a time and never smears.
func _snap(v: Vector2) -> Vector2:
	return (v * _kp).round() / _kp


# --- the far layer (drawn once) -------------------------------------------------------------------

func _draw_far() -> void:
	var p := _far_pen
	# The sky: four stops, the low sun on the horizon behind the Party House.
	p.rect_v(0, 0, W, 40, Color("#5b5f9a"), Color("#c9788a"))
	p.rect_v(0, 40, W, 34, Color("#c9788a"), Color("#f2a05e"))
	p.rect_v(0, 74, W, ROAD_Y - 74, Color("#f2a05e"), Color("#ffd98a"))
	var sun := Vector2(W * 0.12, 88)
	p.blob(sun, Vector2(110, 80), Color("#ffe6a8", 0.55), 24)
	p.blob(sun, Vector2(40, 34), Color("#fff4cc", 0.8), 20)
	for c: Array in [[W * 0.30, 22.0, 58.0], [W * 0.66, 34.0, 74.0], [W * 0.88, 16.0, 44.0]]:
		_cloud(p, Vector2(c[0], c[1]), c[2])
	_nowy_swiat(p)
	_party_house(p)
	# The haze over the lower part of the buildings.
	p.rect_v(0, 64, W, ROAD_Y - 64, Color("#ffc98a", 0.0), Color("#ffc98a", 0.38))
	_lamps(p)


func _cloud(p: Pen, c: Vector2, w: float) -> void:
	p.ell(c + Vector2(0, 1.4), Vector2(w * 0.5, 3.6), Color("#ffcf9a", 0.75))
	p.ell(c, Vector2(w * 0.46, 3.0), Color("#9a7aa8", 0.55))
	p.ell(c + Vector2(-w * 0.12, -1.6), Vector2(w * 0.22, 2.6), Color("#b48cb0", 0.5))


## The old Party House on the corner: in its own shade (the sun behind it), the bright rim on the
## roof and the left edge, square piers over dark bays, recessed windows with one in five aflame.
func _party_house(p: Pen) -> void:
	var x0 := -4.0
	var x1 := W * 0.38
	var top := 30.0
	p.rect_v(x0, top, x1 - x0, ROAD_Y - top, Color("#c9b49a"), Color("#a8918a"))
	p.rect(x0, top - 2, x1 - x0, 3, Color("#d8c6aa"))
	p.rect(x0, top - 2, x1 - x0, 0.8, Color("#fff0c8"))
	p.rect(x1 - 1.5, top - 2, 1.5, ROAD_Y - top + 2, Color("#8f7a74"))
	p.rect(x0, top + 9, x1 - x0, 1.6, Color("#9a8478"))
	var n := 0
	for r in 4:
		var y := top + 14 + r * 9.5
		var x := x0 + 6.0
		while x < x1 - 8.0:
			p.rect(x - 0.6, y - 0.6, 6.2, 6.8, Color("#9a8478"))
			p.rect_v(x, y, 5, 5.6, Color("#4a4660"), Color("#5c5874"))
			if (n * 7 + r * 3) % 5 == 0:
				p.rect_v(x, y, 5, 5.6, Color("#ffb060"), Color("#ffd98a"))
			p.rect(x + 2.2, y, 0.6, 5.6, Color("#9a8478"))
			p.rect(x, y + 2.4, 5, 0.6, Color("#9a8478"))
			p.rect(x - 0.8, y + 5.6, 6.6, 1.0, Color("#e8d8bc"))
			if (n * 5 + r) % 7 == 3:
				_ac_unit(p, x + 0.4, y + 6.6)
			elif (n * 3 + r * 2) % 9 == 4:
				_flower_box(p, x - 0.4, y + 5.0, 5.8)
			x += 10.5
			n += 1
	# the roof: a lift-room box, a dish, an aerial
	p.rect(x1 * 0.22, top - 7, 14, 5, Color("#b8a48e"))
	p.rect(x1 * 0.22, top - 7, 14, 0.8, Color("#e8d8bc"))
	p.rect(x1 * 0.22 + 12.6, top - 7, 1.4, 5, Color("#8f7a74"))
	_dish(p, Vector2(x1 * 0.55, top - 4.5))
	_aerial(p, Vector2(x1 * 0.78, top - 2.0))
	var cy := top + 54.0
	p.rect(x0, cy - 2.4, x1 - x0, 2.6, Color("#d8c6aa"))
	p.rect(x0, cy, x1 - x0, ROAD_Y - cy, Color("#3b3348"))
	var x := x0 + 3.0
	while x < x1 - 4.0:
		p.rect_h(x, cy, 6, ROAD_Y - cy, Color("#e2d2b4"), Color("#a8918a"))
		p.rect(x, cy, 0.8, ROAD_Y - cy, Color("#fff0c8", 0.8))
		x += 15.0


## Nowy Świat's low pastel fronts: cornices, awnings, lit shop windows, a lit left reveal on each.
func _nowy_swiat(p: Pen) -> void:
	var cols := [Color("#e8c9a0"), Color("#d6b6c4"), Color("#c9d4b0"), Color("#ead79c"), Color("#d8bca8")]
	var awn := [Color("#b84a3a"), Color("#3f7a5a"), Color("#3a5a8a"), Color("#c08a2a")]
	var x := W * 0.40
	var i := 0
	while x < W:
		var w := 36.0 + float((i * 13) % 14)
		var top := 46.0 + float((i * 7) % 12)
		var c: Color = cols[i % cols.size()]
		p.rect_v(x, top, w, ROAD_Y - top, c, c.darkened(0.12))
		p.rect(x, top, 1.4, ROAD_Y - top, c.lightened(0.35))
		p.rect(x - 1, top - 2.5, w + 2, 2.8, c.darkened(0.25))
		p.rect(x - 1, top - 2.5, w + 2, 0.8, c.lightened(0.3))
		for r in 3:
			for kx in int((w - 6.0) / 8.0):
				var wx := x + 4.0 + kx * 8.0
				var wy := top + 7.0 + r * 12.0
				p.rect(wx - 0.5, wy - 0.5, 5, 8, c.darkened(0.2))
				p.rect_v(wx, wy, 4, 7, Color("#4e5266"), Color("#666a80"))
				p.rect(wx + 1.7, wy, 0.6, 7, c.darkened(0.2))
				p.rect(wx + 0.4, wy + 0.4, 0.8, 2.4, Color(1, 1, 1, 0.22))
				p.rect(wx - 0.6, wy + 7, 5.2, 0.9, c.lightened(0.25))
				if (i + kx + r) % 6 == 2:
					_flower_box(p, wx - 0.6, wy + 6.0, 5.2)
				elif (i * 2 + kx + r) % 8 == 5:
					_ac_unit(p, wx, wy + 8.0)
			# a balcony on every other front, first floor
			if i % 2 == 1:
				_railing(p, x + 3.0, top + 7.0 + 12.0 + 6.0, w - 6.0, c)
		# the roof: a chimney or two, a dormer on the wider fronts, a drainpipe at the joint
		p.rect(x + w * 0.24, top - 6.5, 3.2, 4.2, c.darkened(0.3))
		p.rect(x + w * 0.24 - 0.4, top - 7.2, 4.0, 1.0, c.darkened(0.45))
		if w > 42.0:
			p.poly(PackedVector2Array([Vector2(x + w * 0.6, top - 2.5), Vector2(x + w * 0.6 + 4, top - 7.5), Vector2(x + w * 0.6 + 8, top - 2.5)]), c.darkened(0.3))
			p.rect(x + w * 0.6 + 2.5, top - 5.2, 3, 2.7, Color("#4e5266"))
		p.rect(x + w - 1.6, top, 1.0, ROAD_Y - top - 14.0, c.darkened(0.35))
		# the shop: an awning and a warm window
		var sy := ROAD_Y - 14.0
		p.rect_v(x + 3, sy, w - 6, 13, Color("#ffd98a"), Color("#ffb060"))
		p.rect(x + 3, sy + 4, w - 6, 0.6, Color("#c08040", 0.6))
		for m in int((w - 6.0) / 9.0):
			p.rect(x + 3 + (m + 1) * 9.0, sy, 0.7, 13, Color("#8a6040"))
		p.rect(x + w * 0.5 - 3, sy + 4.6, 6, 8.4, Color("#6a4a3a"))
		p.rect(x + w * 0.5 - 2.4, sy + 5.2, 4.8, 3.6, Color("#ffe8b0"))
		# the shop's sign board over the awning, a squiggle for its name
		var sg := minf(w - 10.0, 22.0)
		var sx0 := x + (w - sg) * 0.5
		p.rect(sx0, sy - 9.5, sg, 4.4, Color("#2a2a3a"))
		for q in int(sg / 2.2) - 1:
			p.rect(sx0 + 1.2 + q * 2.2, sy - 8.4 + float((q + i) % 2) * 0.8, 1.4, 1.4, NICKS[(i + q / 3) % NICKS.size()])
		var a: Color = awn[i % awn.size()]
		p.poly(PackedVector2Array([Vector2(x + 1, sy - 4), Vector2(x + w - 1, sy - 4), Vector2(x + w + 1, sy + 1), Vector2(x - 1, sy + 1)]), a)
		for s in int(w / 5.0):
			if s % 2 == 0:
				p.poly(PackedVector2Array([Vector2(x + 1 + s * 5, sy - 4), Vector2(x + 6 + s * 5, sy - 4), Vector2(x + 6.4 + s * 5, sy + 1), Vector2(x + 0.6 + s * 5, sy + 1)]), a.lightened(0.35))
		x += w
		i += 1


## A wall air-conditioner box with its grille and fan.
func _ac_unit(p: Pen, x: float, y: float) -> void:
	p.rect(x, y, 5.2, 3.6, Color("#d8dce0"))
	p.rect(x, y + 3.0, 5.2, 0.6, Color("#9aa0a8"))
	p.rect(x + 4.6, y, 0.6, 3.6, Color("#aab0b8"))
	p.ell(Vector2(x + 2.0, y + 1.6), Vector2(1.2, 1.2), Color("#7a808a"), 0.0, 8)
	p.rect(x + 3.4, y + 0.6, 0.6, 2.2, Color("#9aa0a8"))


## A window box of geraniums.
func _flower_box(p: Pen, x: float, y: float, w: float) -> void:
	p.rect(x, y + 1.2, w, 1.6, Color("#8a4a2a"))
	for f in int(w / 1.4):
		var fc := RED if f % 3 == 0 else (Color("#ff9ab0") if f % 3 == 1 else LETTUCE)
		p.rect(x + 0.2 + f * 1.4, y + float(f % 2) * 0.5, 1.1, 1.2, fc)


## A balcony: the slab, the rail and its bars.
func _railing(p: Pen, x: float, y: float, w: float, c: Color) -> void:
	p.rect(x - 1, y + 4.2, w + 2, 1.2, c.darkened(0.3))
	p.rect(x - 1, y, w + 2, 0.7, Color("#3a3646"))
	var bx := x
	while bx <= x + w:
		p.rect(bx, y, 0.5, 4.2, Color("#3a3646"))
		bx += 1.8


func _dish(p: Pen, at: Vector2) -> void:
	p.rect(at.x - 0.3, at.y, 0.7, 3.0, Color("#5a5666"))
	p.ell(at + Vector2(0, -1.0), Vector2(2.6, 2.0), Color("#e8eaee"), -0.5, 10)
	p.ell(at + Vector2(0.4, -0.8), Vector2(1.6, 1.2), Color("#b8bcc4"), -0.5, 8)


func _aerial(p: Pen, at: Vector2) -> void:
	p.rect(at.x - 0.3, at.y - 9.0, 0.6, 9.0, Color("#3a3646"))
	for r in 3:
		var w := 6.0 - r * 1.4
		p.rect(at.x - w * 0.5, at.y - 8.6 + r * 2.0, w, 0.5, Color("#3a3646"))


func _lamps(p: Pen) -> void:
	for k in 5:
		var lx := 30.0 + k * W * 0.22
		p.rect(lx - 0.5, 64, 1.1, ROAD_Y - 64, Color("#3a3646"))
		p.rect(lx - 4, 63, 8, 1.6, Color("#3a3646"))
		p.blob(Vector2(lx, 65.5), Vector2(6, 4), Color("#ffe39a", 0.6), 10)


# --- the scene ------------------------------------------------------------------------------------

func _draw_scene() -> void:
	var p := _pen
	p.o = Vector2.ZERO
	if _far_vp != null:
		_scene.draw_texture_rect(_far_vp.get_texture(), Rect2(Vector2.ZERO, Vector2(_far_vp.size) / _kp), false)
	p.o = _sway(0.35)
	_road(p)
	p.o = _sway(1.0)
	_pavement(p)
	_porsza(p, W * 0.015, 176.0)
	_pigeon(p)
	_zbyszek(p)
	_kebabulo(p)
	_you(p)
	if tasting.phase in [Tasting.Phase.FAN, Tasting.Phase.SELFIE, Tasting.Phase.CARD]:
		_fan(p)
	p.o = Vector2.ZERO


func _road(p: Pen) -> void:
	p.rect_v(0, ROAD_Y, W, PAVE_Y - ROAD_Y, Color("#4a4850"), Color("#3e3d45"))
	# the sun's sheen along the far side, the kerb's lit edge
	p.blob(Vector2(W * 0.14, ROAD_Y + 8), Vector2(W * 0.3, 7), Color("#ffb878", 0.28), 16)
	p.rect(0, ROAD_Y, W, 1.0, Color("#8a8076"))
	# the tracks and the wires
	for ty in [ROAD_Y + 13.0, ROAD_Y + 17.0]:
		p.rect(0, ty, W, 0.6, Color("#9aa0a8", 0.7))
	for wy in [18.0, 21.0]:
		p.seg(Vector2(-4, wy), Vector2(W + 4, wy + 2.0), 0.35, Color("#2a2630", 0.7))
	# the lane dashes, curving round the island
	var c := Vector2(_palm_x(), ROAD_Y + 19.0)
	for lane: Array in [[W * 0.7, 12.0], [W * 0.78, 16.5]]:
		var pts := Pen.ell_pts(c, Vector2(lane[0], lane[1]), 0.0, 64)
		for i in range(0, 64, 2):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 64]
			if a.y > ROAD_Y + 1.0 and a.y < PAVE_Y - 1.0:
				p.seg(a, b, 0.7, Color("#e8e4d8", 0.6))
	var colours := [Color("#d4282e"), Color("#27c4dc"), Color("#c9d2d8"), Color("#ffd23a"), Color("#3a4a7a")]
	# the far lane (behind the island) and the tram
	for k in 4:
		var sp := 38.0 + k * 9.0
		var bx := W + 30.0 - fmod(_t * (sp + 6.0) + k * 97.0, W + 60.0)
		_car(p, bx, ROAD_Y + 4.5, colours[(k + 2) % colours.size()], false, 0.86)
	var tt := fmod(_t + 4.0, TRAM_S)
	if tt < 5.0:
		_tram(p, -130.0 + tt / 5.0 * (W + 260.0), ROAD_Y + 2.5)
	_palm(p)
	for k in 4:
		var sp := 38.0 + k * 9.0
		var cx := fmod(_t * sp + k * 131.0, W + 60.0) - 30.0
		_car(p, cx, ROAD_Y + 25.0, colours[k], true, 1.0)
	p.rect_v(0, PAVE_Y - 2.6, W, 2.6, Color("#b8b2a6"), Color("#8a857c"))
	p.rect(0, PAVE_Y - 2.6, W, 0.7, Color("#efe6d2"))


## A car side-on: a rounded body in two tones, the glass with a sheen, wheels, a lamp, its shadow.
func _car(p: Pen, x: float, y: float, c: Color, right: bool, s: float) -> void:
	var w := 24.0 * s
	var h := 8.0 * s
	p.blob(Vector2(x + w * 0.6, y + h + 0.6), Vector2(w * 0.7, 1.4), Color(Pen.SHADOW, 0.45), 10)
	p.rrect_v(x, y + h * 0.35, w, h * 0.55, 2.0 * s, c.lightened(0.15), c.darkened(0.3))
	var cab := PackedVector2Array([Vector2(x + w * (0.22 if right else 0.30), y + h * 0.36), Vector2(x + w * (0.34 if right else 0.38), y),
			Vector2(x + w * (0.62 if right else 0.66), y), Vector2(x + w * (0.78 if right else 0.70), y + h * 0.36)])
	p.poly(cab, c.darkened(0.1))
	var g := PackedVector2Array([cab[0] + Vector2(1.2 * s, -0.2), cab[1] + Vector2(0.6 * s, 0.8 * s), cab[2] + Vector2(-0.6 * s, 0.8 * s), cab[3] + Vector2(-1.2 * s, -0.2)])
	p.poly_cols(g, PackedColorArray([Color("#3a4660"), Color("#8fb4d0"), Color("#5a7090"), Color("#2a3448")]))
	p.rect(x + w * 0.02, y + h * 0.58, w * 0.96, 0.5 * s, c.lightened(0.4))
	for wx in [x + w * 0.22, x + w * 0.78]:
		p.ell(Vector2(wx, y + h * 0.9), Vector2(2.6 * s, 2.6 * s), INK, 0.0, 14)
		p.ell(Vector2(wx, y + h * 0.9), Vector2(1.2 * s, 1.2 * s), Color("#b8c0c8"), 0.0, 10)
	p.blob(Vector2(x + (w if right else 0.0), y + h * 0.52), Vector2(2.4, 1.6), Color("#fff4cc", 0.9), 8)


## A Warsaw tram: three red cars with the yellow band, the pantograph on the wire.
func _tram(p: Pen, x: float, y: float) -> void:
	p.blob(Vector2(x + 60, y + 16), Vector2(64, 1.8), Color(Pen.SHADOW, 0.4), 14)
	for k in 3:
		var cx := x + k * 40.0
		p.rrect_v(cx, y, 39, 15, 2.4, Color("#d8403a"), Color("#a02420"))
		p.rect(cx + 0.5, y + 9.5, 38, 2.2, Color("#f2c230"))
		for wi in 4:
			p.rrect_v(cx + 3.0 + wi * 9.0, y + 2.2, 7, 6, 1.0, Color("#8fb4d0"), Color("#2a3448"))
		p.rect(cx + 0.5, y + 0.6, 38, 0.7, Color("#ff8a7a"))
	p.seg(Vector2(x + 58, y), Vector2(x + 52, y - 6), 0.6, INK)
	p.seg(Vector2(x + 52, y - 6), Vector2(x + 60, y - 6), 0.6, INK)


## The Palm on its island: a grass oval and its kerb, the trunk in shaded diamonds, sixteen fronds
## bursting like a firework (the upper ones up, the lower ones drooping), each a curved tapered
## blade with a serrated edge, rim-lit on the left.
func _palm(p: Pen) -> void:
	var x := _palm_x()
	var base := ROAD_Y + 21.0
	p.ell(Vector2(x, base + 1.0), Vector2(30, 5.2), Color("#8a857c"))
	p.ell(Vector2(x, base + 0.4), Vector2(28, 4.4), Color("#4a8a3e"))
	p.ell(Vector2(x - 5, base - 0.6), Vector2(16, 2.4), Color("#6aa84e"))
	var top := 30.0
	var sway := sin(_t * 0.9) * 1.2
	var n := 22
	var seg := (base - top) / n
	for i in n:
		var u := float(i) / float(n)
		var y := base - (i + 1) * seg
		var lean := u * u * 4.0 + sway * u
		var w := lerpf(3.4, 2.6, u)
		p.poly(PackedVector2Array([Vector2(x - w + lean, y + seg), Vector2(x + w + lean, y + seg), Vector2(x + w * 0.9 + lean, y), Vector2(x - w * 0.9 + lean, y)]),
				Color("#6a4e34") if i % 2 == 0 else Color("#5a4028"))
		p.poly(PackedVector2Array([Vector2(x - w + lean, y + seg), Vector2(x + lean, y + seg * 0.55), Vector2(x - w * 0.9 + lean, y)]), Color("#a8845a"))
	var cx := x + 4.0 + sway
	p.ell(Vector2(cx, top + 1.5), Vector2(4.6, 3.6), Color("#5a4a2a"))
	for f in 16:
		var a := -PI + float(f) / 15.0 * PI
		_frond(p, Vector2(cx, top), a + sin(_t * 1.1 + f) * 0.03, 30.0 + float((f * 5) % 7))
	p.ell(Vector2(cx - 1.6, top + 3.0), Vector2(1.4, 1.4), Color("#c8a020"))
	p.ell(Vector2(cx + 1.6, top + 3.4), Vector2(1.4, 1.4), Color("#b08a18"))


func _frond(p: Pen, at: Vector2, a: float, length: float) -> void:
	var dir := Vector2(cos(a), sin(a))
	var droop := 0.5 + 0.5 * absf(cos(a))
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var u := float(i) / float(n)
		var u2 := minf(1.0, u + 0.1)
		var spine := at + dir * length * u + Vector2(0, length * 0.42 * droop * u * u)
		var ahead := at + dir * length * u2 + Vector2(0, length * 0.42 * droop * u2 * u2)
		var t := ahead - spine
		var nrm := Vector2(-t.y, t.x).normalized()
		if nrm.y > 0.0:
			nrm = -nrm
		var w := 3.2 * sin(PI * minf(1.0, u * 1.08))
		top.append(spine + nrm * w * 0.45)
		var tooth := 1.0 if i % 2 == 0 else 0.4
		bot.append(spine - nrm * w * tooth)
	var pts := PackedVector2Array(top)
	for i in range(bot.size() - 1, -1, -1):
		pts.append(bot[i])
	p.poly(pts, Color("#2f7a3e"))
	var inner := PackedVector2Array(top)
	for i in range(top.size() - 1, -1, -1):
		inner.append(top[i].lerp(bot[i], 0.35))
	p.poly(inner, Color("#3f9a4a"))
	if dir.x < 0.0:
		p.line(top, 0.5, Color("#7fd05a", 0.9))


## The pavement in front: slabs in perspective (the joints converging on the vanishing point), the
## palm's long shadow.
func _pavement(p: Pen) -> void:
	p.rect_v(0, PAVE_Y, W, H - PAVE_Y, Color("#a8a296"), Color("#8e887e"))
	var vp := Vector2(W * 0.5, ROAD_Y - 30.0)
	var y := PAVE_Y + 5.0
	var gap := 5.0
	while y < H:
		p.rect(0, y, W, 0.45, Color("#6e6a62", 0.55))
		y += gap
		gap *= 1.32
	for i in range(-8, 9):
		var bx := W * 0.5 + i * 34.0
		var d := Vector2(bx, H) - vp
		var t0 := (PAVE_Y - vp.y) / d.y
		p.seg(vp + d * t0, Vector2(bx, H), 0.45, Color("#6e6a62", 0.5))
	p.poly(PackedVector2Array([Vector2(_palm_x() + 2, PAVE_Y), Vector2(_palm_x() + 7, PAVE_Y), Vector2(_palm_x() + 70, H), Vector2(_palm_x() + 55, H)]),
			Color(Pen.SHADOW, 0.12))
	# the kerb: granite blocks with a lit top edge
	p.rect(0, PAVE_Y - 1.2, W, 2.4, Color("#b8b2a6"))
	p.rect(0, PAVE_Y - 1.2, W, 0.6, Color("#ddd8cc"))
	var kx := 0.0
	while kx < W:
		p.rect(kx, PAVE_Y - 1.2, 0.5, 2.4, Color("#7e786e"))
		kx += 9.0
	# street furniture along the kerb: bollards, a bin, a hydrant (behind the people)
	for bx: float in [W * 0.30, W * 0.33, W * 0.70, W * 0.73, W * 0.76]:
		_bollard(p, Vector2(bx, PAVE_Y + 6.0))
	_bin(p, Vector2(W * 0.455, PAVE_Y + 9.0))
	_hydrant(p, Vector2(W * 0.95, PAVE_Y + 8.0))


func _bollard(p: Pen, at: Vector2) -> void:
	p.ell(at + Vector2(0.8, 0.4), Vector2(2.2, 0.8), Color(Pen.SHADOW, 0.3), 0.0, 8)
	p.rect(at.x - 1.2, at.y - 6.0, 2.4, 6.0, Color("#4a4a56"))
	p.rect(at.x - 1.2, at.y - 6.0, 0.7, 6.0, Color("#6e6e7c"))
	p.rect(at.x - 1.2, at.y - 4.6, 2.4, 0.8, Color("#e8e4d8"))
	p.ell(at + Vector2(0, -6.0), Vector2(1.2, 0.6), Color("#6e6e7c"), 0.0, 8)


## A Warsaw street bin: the green barrel on its post, a lid, a bag edge.
func _bin(p: Pen, at: Vector2) -> void:
	p.ell(at + Vector2(1.5, 0.4), Vector2(4.0, 1.0), Color(Pen.SHADOW, 0.3), 0.0, 10)
	p.rect(at.x - 0.5, at.y - 6.0, 1.0, 6.0, Color("#3a3646"))
	p.rect(at.x - 3.2, at.y - 13.0, 6.4, 8.0, Color("#3f7a4a"))
	p.rect(at.x - 3.2, at.y - 13.0, 1.6, 8.0, Color("#5a9a62"))
	p.rect(at.x + 2.2, at.y - 13.0, 1.0, 8.0, Color("#2a5a34"))
	p.rect(at.x - 3.6, at.y - 14.0, 7.2, 1.4, Color("#2a5a34"))
	p.rect(at.x - 1.4, at.y - 10.6, 2.8, 2.4, Color("#e8e4d8"))


func _hydrant(p: Pen, at: Vector2) -> void:
	p.ell(at + Vector2(1.0, 0.3), Vector2(3.0, 0.8), Color(Pen.SHADOW, 0.3), 0.0, 8)
	p.rect(at.x - 1.6, at.y - 7.0, 3.2, 7.0, Color("#c83a2a"))
	p.rect(at.x - 1.6, at.y - 7.0, 0.9, 7.0, Color("#e86a4a"))
	p.rect(at.x - 2.6, at.y - 4.6, 5.2, 1.2, Color("#a02a1e"))
	p.ell(at + Vector2(0, -7.2), Vector2(1.6, 1.0), Color("#a02a1e"), 0.0, 8)


## Kebabulo's Porsza, side-on, nose right: a low white fastback in three tones, the roof sloping to
## the tail, round lamps, the gold stripe, five-spoke rims, its shadow.
func _porsza(p: Pen, x: float, base: float) -> void:
	var w := W * 0.27
	var hh := w * 0.27
	p.ground(Vector2(x + w * 0.5, base + 0.5), w * 0.5, 1.6, 0.5)
	var body := PackedVector2Array()
	var outline := [[0.0, 0.62], [0.02, 0.42], [0.10, 0.36], [0.30, 0.30], [0.40, 0.06], [0.50, 0.0], [0.60, 0.02],
			[0.72, 0.24], [0.86, 0.34], [0.97, 0.42], [1.0, 0.56], [0.99, 0.82], [0.0, 0.84]]
	for q: Array in outline:
		body.append(Vector2(x + w * float(q[0]), base - hh + hh * float(q[1])))
	p.form(body, PORSZA[0], PORSZA[1], 0.86)
	p.blob(Vector2(x + w * 0.42, base - hh * 0.75), Vector2(w * 0.22, hh * 0.16), Color(PORSZA[2], 0.8), 12)
	var glass := PackedVector2Array([Vector2(x + w * 0.34, base - hh * 0.68), Vector2(x + w * 0.42, base - hh * 0.9),
			Vector2(x + w * 0.58, base - hh * 0.92), Vector2(x + w * 0.68, base - hh * 0.70)])
	p.poly_cols(glass, PackedColorArray([Color("#2a3448"), Color("#8fb4d0"), Color("#5a7090"), Color("#1e2638")]))
	p.seg(Vector2(x + w * 0.52, base - hh * 0.91), Vector2(x + w * 0.52, base - hh * 0.68), 0.7, PORSZA[1])
	p.seg(Vector2(x + w * 0.40, base - hh * 0.78), Vector2(x + w * 0.46, base - hh * 0.9), 0.6, Color(1, 1, 1, 0.5))
	p.rect(x + w * 0.04, base - hh * 0.44, w * 0.92, 0.9, GOLD)
	p.rect(x + w * 0.05, base - hh * 0.2, w * 0.9, 1.0, PORSZA[1].darkened(0.15))
	p.ell(Vector2(x + w * 0.955, base - hh * 0.5), Vector2(1.8, 1.6), Color("#fff4cc"))
	p.blob(Vector2(x + w * 0.98, base - hh * 0.5), Vector2(5, 3), Color("#fff4cc", 0.5), 10)
	p.rrect(x, base - hh * 0.52, 2.0, 1.6, 0.6, Color("#d4282e"))
	for wx in [x + w * 0.2, x + w * 0.8]:
		var wc := Vector2(wx, base - hh * 0.18)
		p.ell(wc + Vector2(0, -0.6), Vector2(hh * 0.36, hh * 0.36), Color("#2a2630"), 0.0, 18)
		p.ell(wc, Vector2(hh * 0.31, hh * 0.31), INK, 0.0, 18)
		p.ell(wc, Vector2(hh * 0.19, hh * 0.19), Color("#c9d2d8"), 0.0, 16)
		for s in 5:
			var a := float(s) / 5.0 * TAU + 0.3
			p.seg(wc, wc + Vector2(cos(a), sin(a)) * hh * 0.17, 0.7, Color("#8f9aa4"))
		p.ell(wc, Vector2(hh * 0.05, hh * 0.05), Color("#eef4f8"), 0.0, 8)


## A pigeon pacing toward the crumbs, pecking; it takes off at the MLASK and is back for the card.
func _pigeon(p: Pen) -> void:
	var ph := tasting.phase
	var flying := ph == Tasting.Phase.MLASK or (ph == Tasting.Phase.VERDICT and tasting.t < 0.8 and tasting.line_i == 0)
	var k := fmod(_t, 16.0) / 16.0
	var x := lerpf(W * 0.30, _you_x() + 14.0, minf(1.0, k * 1.6))
	var y := FEET - 1.0
	if flying:
		var ft := tasting.t + (Tasting.MLASK_S if ph == Tasting.Phase.VERDICT else 0.0)
		x += ft * 70.0
		y -= ft * 60.0
	else:
		p.ground(Vector2(x + 3, FEET), 4.0, 1.4, 0.3)
	var peck := not flying and fmod(_t, 1.4) < 0.25
	p.ball(Vector2(x + 3, y - 4.5), Vector2(4.6, 3.2), PIGEON[0], PIGEON[1], PIGEON[2], -0.15)
	var hc := Vector2(x + (8.5 if not peck else 9.5), y - (8.0 if not peck else 4.6))
	p.ball(hc, Vector2(1.9, 1.8), PIGEON[0], PIGEON[1], PIGEON[2])
	p.ell(Vector2(x + 7.0, y - 5.6), Vector2(1.6, 1.4), Color("#5fae8a", 0.85))
	p.poly(PackedVector2Array([hc + Vector2(1.4, -0.4), hc + Vector2(3.4, 0.4), hc + Vector2(1.4, 0.8)]), GOLD_D)
	p.ell(hc + Vector2(0.5, -0.5), Vector2(0.45, 0.45), INK, 0.0, 8)
	if flying:
		var flap := sin(_t * 30.0)
		p.poly(PackedVector2Array([Vector2(x + 2, y - 6), Vector2(x - 3, y - 12 - flap * 4), Vector2(x + 6, y - 6)]), PIGEON[2])
	else:
		p.seg(Vector2(x + 2, y - 2), Vector2(x + 2, y + 1), 0.6, Color("#ee5a5a"))
		p.seg(Vector2(x + 4.5, y - 2), Vector2(x + 4.5, y + 1), 0.6, Color("#ee5a5a"))
		p.poly(PackedVector2Array([Vector2(x - 1, y - 5), Vector2(x - 4.5, y - 3.4), Vector2(x - 1, y - 3)]), PIGEON[1])


# --- the people -----------------------------------------------------------------------------------

## A figure, cel-shaded, five heads tall, in three-quarter view (`f` 1 facing right, -1 left).
## `s` (all optional but x, foot, h, f, skin, top, legs):
##   build: "big"; breath period `bp`; seed (blinks and shifts differ);
##   near / far: the arms as [shoulder angle, elbow angle] (0 straight down, + forward);
##   hold_near / hold_far: "", "kebab", "kebab_bit", "bag", "phone", "gimbal", "thumb", "peace", "fist";
##   face: the head's own keys (see `_head`); bob (up), lean, walk (a phase, or -1);
##   shoe colour, hood, chain, puffer (quilt lines), backpack.
func _person(p: Pen, s: Dictionary) -> void:
	var x: float = s["x"]
	var foot: float = s["foot"]
	var h: float = s["h"]
	var f: int = s["f"]
	var seed := float(s.get("seed", 0.0))
	var big := str(s.get("build", "")) == "big"
	var top: Array = s["top"]
	var legs: Array = s["legs"]
	var skin: Array = s["skin"]
	var shoe: Color = s.get("shoe", INK)
	var bp := float(s.get("bp", 3.2))
	var breath := sin(_t * TAU / bp + seed)
	var walk := float(s.get("walk", -1.0))
	var bob := float(s.get("bob", 0.0))
	if walk >= 0.0:
		bob += absf(sin(walk)) * 0.012 * h
	# the weight shift every few seconds
	var shift := 0.0
	if walk < 0.0:
		var sv := sin(_t * TAU / (5.3 + seed) + seed * 2.0)
		shift = signf(sv) * pow(absf(sv), 0.35) * 0.010 * h
	var hip := Vector2(x + shift, foot - 0.44 * h - bob)
	var sw := (0.34 if big else 0.25) * h
	var bw := (0.42 if big else 0.22) * h * (1.0 + breath * (0.025 if big else 0.012))
	var hw := (0.30 if big else 0.19) * h
	var torso_h := 0.32 * h * (1.0 + breath * 0.012)
	var lean := float(s.get("lean", 0.0))
	var sh_c := Vector2(hip.x + lean * torso_h, hip.y - torso_h - breath * 0.004 * h)
	p.ground(Vector2(x, foot), 0.22 * h * (1.3 if big else 1.0), 3.0, 0.45)
	if bool(s.get("backpack", false)):
		p.ball(sh_c + Vector2(-f * sw * 0.48, torso_h * 0.42), Vector2(sw * 0.3, torso_h * 0.36), Color("#3a5a8a"), Color("#25406a"), Color("#5a7aaa"))
	# the far leg and arm, a tone darker and a little smaller
	var dk := func(c: Color) -> Color: return c.darkened(0.12)
	var lt := 1.35 if big else 1.0
	_leg(p, hip + Vector2(-f * hw * 0.22, 0), foot, h, f, -1.0, walk, legs, shoe, dk, lt)
	_arm(p, sh_c + Vector2(-f * sw * 0.40, 0.03 * h), h * 0.95, f, s.get("far", [0.12, 0.25]), top, skin, str(s.get("hold_far", "")), dk)
	_leg(p, hip + Vector2(f * hw * 0.22, 0), foot, h, f, 1.0, walk, legs, shoe, Callable(), lt)
	# the torso: an egg for Kebabulo, a tapered capsule for the rest
	var pts := PackedVector2Array()
	var n := 9
	for side: int in [-1, 1]:
		for i in n + 1:
			var u := float(i) / float(n) if side < 0 else 1.0 - float(i) / float(n)
			var half: float
			if u < 0.12:
				half = lerpf(sw * 0.36, sw * 0.5, Pen.ease_out(u / 0.12))
			elif u < 0.62:
				half = lerpf(sw * 0.5, bw * 0.5, Pen.ease_in_out((u - 0.12) / 0.5))
			else:
				half = lerpf(bw * 0.5, hw * 0.5, Pen.ease_in_out((u - 0.62) / 0.38))
			var yy := sh_c.y + torso_h * u + (0.012 * h if u > 0.98 else 0.0)
			var xx := lerpf(sh_c.x, hip.x, u) + side * half
			pts.append(Vector2(xx, yy))
	p.form(pts, top[0], top[1], 0.82)
	p.blob(sh_c + Vector2(-sw * 0.18, torso_h * 0.22), Vector2(sw * 0.2, torso_h * 0.18), Color(top[2], 0.55), 10)
	p.line(PackedVector2Array([pts[0], pts[1], pts[2]]), 0.45, Color(Pen.RIM, 0.55))
	# folds: armpit to belly, a hem crease, a light crease
	var fc: Color = top[1]
	p.seg(sh_c + Vector2(f * sw * 0.30, torso_h * 0.18), hip + Vector2(f * bw * 0.18, -torso_h * 0.32), 0.5, Color(fc, 0.7))
	p.seg(hip + Vector2(-hw * 0.4, -0.01 * h), hip + Vector2(hw * 0.4, -0.01 * h), 0.6, Color(fc, 0.8))
	p.seg(sh_c + Vector2(-sw * 0.12, torso_h * 0.3), sh_c + Vector2(-sw * 0.05, torso_h * 0.6), 0.45, Color(top[2], 0.6))
	if bool(s.get("puffer", false)):
		for q in 3:
			var qy := sh_c.y + torso_h * (0.28 + q * 0.24)
			var qhalf := lerpf(sw, hw, 0.28 + q * 0.24) * 0.5
			p.line(PackedVector2Array([Vector2(hip.x - qhalf, qy), Vector2(hip.x, qy + 0.6), Vector2(hip.x + qhalf, qy)]), 0.55, Color(fc, 0.75))
	if bool(s.get("hood", false)):
		p.ball(sh_c + Vector2(-f * sw * 0.16, -0.01 * h), Vector2(sw * 0.34, 0.05 * h), top[0], top[1], top[2])
		for dsx: float in [-0.06, 0.06]:
			var dx := sh_c.x + f * sw * 0.1 + dsx * h
			var sway := sin(_t * 2.0 + dsx * 20.0) * 0.004 * h
			p.seg(Vector2(dx, sh_c.y + 0.02 * h), Vector2(dx + sway, sh_c.y + 0.11 * h), 0.55, Color("#f6e6c8"))
		p.line(PackedVector2Array([hip + Vector2(-hw * 0.28, -torso_h * 0.3), hip + Vector2(0, -torso_h * 0.22), hip + Vector2(hw * 0.28, -torso_h * 0.3)]), 0.6, Color(fc, 0.9))
	if bool(s.get("chain", false)):
		p.line(Pen.ell_pts(sh_c + Vector2(f * 0.02 * h, 0.03 * h), Vector2(0.06 * h, 0.05 * h), 0.0, 10, 0.25, PI - 0.25), 0.55, GOLD)
	# the neck and the head
	var head_c := sh_c + Vector2(f * 0.01 * h, -0.125 * h) + Vector2(0, sin(_t * TAU / bp + seed - 0.6) * 0.002 * h)
	p.limb(sh_c + Vector2(0, 0.01 * h), head_c + Vector2(0, 0.04 * h), 0.04 * h, 0.035 * h, skin[1], skin[1].darkened(0.1), 0.0)
	var face: Dictionary = s.get("face", {})
	_head(p, head_c, h, f, skin, face, seed)
	# the near arm last, in front
	_arm(p, sh_c + Vector2(f * sw * 0.40, 0.03 * h), h, f, s.get("near", [0.1, 0.2]), top, skin, str(s.get("hold_near", "")), Callable())


func _leg(p: Pen, hip: Vector2, foot: float, h: float, f: int, side: float, walk: float, legs: Array, shoe: Color, tone: Callable, thick := 1.0) -> void:
	var swing := sin(walk) * 0.38 * side if walk >= 0.0 else 0.0
	var thigh := 0.21 * h
	var shin := 0.19 * h
	var knee := hip + Vector2(sin(swing) * thigh * f, cos(swing) * thigh)
	var bend := maxf(0.0, -sin(walk) * side) * 0.5 if walk >= 0.0 else 0.0
	var ankle := knee + Vector2(sin(swing - bend) * shin * f, cos(swing - bend) * shin)
	if walk < 0.0:
		ankle.y = foot - 0.04 * h
	var b: Color = legs[0]
	var sh: Color = legs[1]
	var sc := shoe
	if tone.is_valid():
		b = tone.call(b)
		sh = tone.call(sh)
		sc = tone.call(sc)
	p.limb(hip, knee, 0.05 * h * thick, 0.042 * h * thick, b, sh, 0.35)
	p.limb(knee, ankle, 0.042 * h * thick, 0.034 * h * thick, b, sh, 0.35)
	# the shoe: a rounded wedge toward the facing side, a light sole
	var sy := ankle.y
	var toe := ankle.x + f * 0.075 * h
	var heel := ankle.x - f * 0.035 * h
	var shoe_pts := PackedVector2Array([Vector2(heel, sy - 0.02 * h), Vector2(ankle.x, sy - 0.035 * h), Vector2(toe - f * 0.02 * h, sy - 0.012 * h),
			Vector2(toe, sy + 0.018 * h), Vector2(heel, sy + 0.022 * h)])
	if f < 0:
		shoe_pts.reverse()
	p.form(shoe_pts, sc, sc.darkened(0.3), 0.85)
	p.seg(Vector2(heel, sy + 0.018 * h), Vector2(toe, sy + 0.016 * h), 0.6, sc.lightened(0.4) if sc.get_luminance() < 0.5 else Color("#d8d2c4"))


## An arm from `sh` (shoulder): `ang` [shoulder, elbow] radians from straight down, + forward; the
## hand and what it holds.
func _arm(p: Pen, sh: Vector2, h: float, f: int, ang: Array, top: Array, skin: Array, hold: String, tone: Callable) -> void:
	var a := float(ang[0])
	var e := float(ang[1])
	var elbow := sh + Vector2(sin(a) * f, cos(a)) * 0.16 * h
	var hand := elbow + Vector2(sin(a + e) * f, cos(a + e)) * 0.15 * h
	var b: Color = top[0]
	var sd: Color = top[1]
	var sk: Array = skin
	if tone.is_valid():
		b = tone.call(b)
		sd = tone.call(sd)
		sk = [tone.call(skin[0]), tone.call(skin[1]), tone.call(skin[2])]
	p.limb(sh, elbow, 0.038 * h, 0.034 * h, b, sd, 0.45)
	p.limb(elbow, hand, 0.034 * h, 0.03 * h, b, sd, 0.45)
	# the ribbed cuff
	var d := (hand - elbow).normalized()
	var nn := Vector2(-d.y, d.x)
	p.seg(hand - d * 0.02 * h + nn * 0.03 * h, hand - d * 0.02 * h - nn * 0.03 * h, 0.9, sd)
	var hr := 0.033 * h
	match hold:
		"kebab", "kebab_bit":
			_kebab(p, hand + Vector2(f * 0.01 * h, -0.03 * h), 0.11 * h, -0.8, hold == "kebab_bit", f)
			p.ball(hand, Vector2(hr, hr * 0.95), sk[0], sk[1], sk[2])
			p.ell(hand + Vector2(f * hr * 0.6, -hr * 0.3), Vector2(hr * 0.42, hr * 0.32), sk[1])
		"bag":
			p.ball(hand, Vector2(hr, hr), sk[0], sk[1], sk[2])
			p.form(Pen.rr_pts(hand.x - 0.05 * h, hand.y + hr * 0.4, 0.1 * h, 0.11 * h, 0.01 * h), Color("#c9a06a"), Color("#9a7448"))
			p.line(PackedVector2Array([Vector2(hand.x - 0.05 * h, hand.y + hr * 1.6), Vector2(hand.x, hand.y + hr * 1.3), Vector2(hand.x + 0.05 * h, hand.y + hr * 1.6)]), 0.5, Color("#9a7448"))
		"phone":
			p.ball(hand, Vector2(hr, hr), sk[0], sk[1], sk[2])
			var ph := hand + Vector2(f * 0.005 * h, -0.05 * h)
			p.rrect(ph.x - 0.032 * h, ph.y - 0.05 * h, 0.064 * h, 0.1 * h, 0.012 * h, Color("#1ae6ff"))
			p.rrect_v(ph.x - 0.026 * h, ph.y - 0.044 * h, 0.052 * h, 0.088 * h, 0.008 * h, Color("#bfe8ff"), Color("#4a7aa0"))
		"gimbal":
			p.ball(hand, Vector2(hr, hr), sk[0], sk[1], sk[2])
			var rod := hand + Vector2(f * 0.02 * h, -0.13 * h)
			p.seg(hand, rod, 0.025 * h, Color("#2a2630"))
			var tilt := sin(_t * TAU / 2.3) * 0.08
			var pc := rod + Vector2(f * 0.03 * h, 0)
			p.poly(_rot_rect(pc, Vector2(0.1 * h, 0.055 * h), tilt), Color("#1e1d24"))
			p.poly(_rot_rect(pc + Vector2(-f * 0.004 * h, 0), Vector2(0.088 * h, 0.044 * h), tilt), Color("#2a3448"))
			if fmod(_t, 1.0) < 0.6:
				p.ell(pc + Vector2(f * 0.04 * h, -0.018 * h), Vector2(0.008 * h, 0.008 * h), RED, 0.0, 8)
		"thumb":
			p.ball(hand, Vector2(hr * 1.05, hr), sk[0], sk[1], sk[2])
			p.limb(hand + Vector2(0, -hr * 0.4), hand + Vector2(f * hr * 0.2, -hr * 1.7), hr * 0.38, hr * 0.32, sk[0], sk[1], 0.3)
		"peace":
			p.ball(hand, Vector2(hr, hr), sk[0], sk[1], sk[2])
			p.limb(hand + Vector2(-hr * 0.3, -hr * 0.4), hand + Vector2(-hr * 0.7, -hr * 1.9), hr * 0.3, hr * 0.26, sk[0], sk[1], 0.3)
			p.limb(hand + Vector2(hr * 0.3, -hr * 0.4), hand + Vector2(hr * 0.7, -hr * 1.9), hr * 0.3, hr * 0.26, sk[0], sk[1], 0.3)
		"fist":
			p.ball(hand, Vector2(hr * 1.15, hr * 1.05), sk[0], sk[1], sk[2])
			p.seg(hand + Vector2(-hr * 0.6, -hr * 0.2), hand + Vector2(hr * 0.6, -hr * 0.2), 0.4, sk[1])
		_:
			p.ball(hand, Vector2(hr, hr), sk[0], sk[1], sk[2])


func _rot_rect(c: Vector2, size: Vector2, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for q: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		pts.append(c + (q * size * 0.5).rotated(rot))
	return pts


## The kebab: a foil-wrapped cone, the tortilla with grill stripes, the open end with lettuce,
## tomato, meat and a drip of sauce; `bit` shows the bite; two wisps of steam.
## `rot` tilts it from upright, toward the facing side `f`.
func _kebab(p: Pen, at: Vector2, length: float, rot: float, bit: bool, f: int) -> void:
	var d := Vector2(sin(-rot) * f, -cos(rot))
	var n := Vector2(-d.y, d.x)
	var l := length * (0.86 if bit else 1.0)
	var w0 := length * 0.21
	var w1 := length * 0.25
	var tip := at - d * l * 0.25
	var end := at + d * l * 0.75
	var wrap := PackedVector2Array([tip + n * w0 * 0.75, tip + n * w0 * 0.2 - d * w0 * 0.5, tip - n * w0 * 0.2 - d * w0 * 0.5, tip - n * w0 * 0.75, end - n * w1, end + n * w1])
	p.poly(wrap, TORTILLA[1])
	p.poly(PackedVector2Array([tip + n * w0 * 0.6, end + n * w1 * 0.9, end - n * w1 * 0.3, tip - n * w0 * 0.3]), TORTILLA[0])
	for s in 3:
		var u := 0.55 + s * 0.14
		var c := tip.lerp(end, u)
		var hw := lerpf(w0 * 0.3, w1, u) * 0.85
		p.seg(c + n * hw + d * 0.6, c - n * hw - d * 0.6, 0.5, Color("#b77834"))
	var mid := tip.lerp(end, 0.5)
	var mw := lerpf(w0 * 0.75, w1, 0.5) * 1.06
	var foil := PackedVector2Array([tip + n * w0 * 0.8, tip + n * w0 * 0.2 - d * w0 * 0.55, tip - n * w0 * 0.2 - d * w0 * 0.55, tip - n * w0 * 0.8, mid - n * mw, mid + n * mw])
	p.poly(foil, FOIL[1])
	p.poly(PackedVector2Array([tip + n * w0 * 0.62, mid + n * mw * 0.9, mid - n * mw * 0.2, tip - n * w0 * 0.3]), FOIL[0])
	p.seg(mid + n * mw, mid - n * mw, 0.5, FOIL[2])
	p.seg(tip.lerp(end, 0.12) + n * w0 * 0.3, tip.lerp(end, 0.45) + n * w1 * 0.4, 0.45, FOIL[2])
	# the open end
	var ang := n.angle()
	p.ell(end, Vector2(w1 * 1.02, w1 * 0.42), TORTILLA[2], ang)
	p.ell(end + d * 0.4, Vector2(w1 * 0.85, w1 * 0.34), MEAT, ang)
	p.ell(end + d * 0.6 + n * w1 * 0.4, Vector2(w1 * 0.36, w1 * 0.2), LETTUCE, ang)
	p.ell(end + d * 0.6 - n * w1 * 0.3, Vector2(w1 * 0.3, w1 * 0.18), TOMATO, ang)
	p.ell(end + d * 0.5, Vector2(w1 * 0.5, w1 * 0.16), SAUCE, ang)
	if bit:
		for i in 3:
			p.ell(end + n * w1 * (0.6 - i * 0.6) + d * w1 * 0.25, Vector2(w1 * 0.3, w1 * 0.22), MEAT.darkened(0.2), ang)
	for i in 2:
		var ph := fmod(_t * 0.6 + i * 0.5, 1.0)
		var sx := end + d * (2.0 + ph * 8.0) + n * sin(ph * 6.0 + i) * 1.5
		p.blob(sx, Vector2(1.8, 1.8) * (0.6 + ph), Color(1, 1, 1, 0.35 * (1.0 - ph)), 8)


## A head: `c` its centre, `h` the figure's height (the head is 0.2 h); `f` the facing side.
## `fc` keys: hair ("short", "messy", "cap_back", "beanie"), hair_c, beard, eyes ("open", "shut",
## "wide", "happy", "worried"), brows (+ up), brow_tilt, mouth ("rest", "smile", "grin", "a", "o",
## "chew", "squiggle", "smack", "tight"), jaw, blush (0..1), look (the pupils, -1..1 toward the
## facing side), tilt (radians), cap_lift, freckles, sweat, talk ([the line, its time]).
func _head(p: Pen, c: Vector2, h: float, f: int, skin: Array, fc: Dictionary, seed := 0.0) -> void:
	var rx := 0.095 * h
	var ry := 0.112 * h
	var tilt := float(fc.get("tilt", 0.0))
	var hair := str(fc.get("hair", "short"))
	var hair_c: Color = fc.get("hair_c", Color("#2a2420"))
	var beard := bool(fc.get("beard", false))
	var R := func(v: Vector2) -> Vector2: return c + v.rotated(tilt)
	# behind the head: the cap's brim
	if hair == "cap_back":
		var brim: Vector2 = R.call(Vector2(-f * rx * 1.05, -ry * 0.62))
		p.poly(PackedVector2Array([brim + Vector2(f * rx * 0.3, -ry * 0.1), brim + Vector2(-f * rx * 0.55, ry * 0.02), brim + Vector2(-f * rx * 0.5, ry * 0.18), brim + Vector2(f * rx * 0.3, ry * 0.16)]), BLACK[1])
	# the ear (the back side shows in three-quarter view)
	var ear: Vector2 = R.call(Vector2(-f * rx * 0.78, ry * 0.08))
	p.ball(ear, Vector2(rx * 0.2, ry * 0.24), skin[0], skin[1], skin[2], 0.0, 0.3)
	p.ell(ear + Vector2(f * rx * 0.04, 0), Vector2(rx * 0.08, ry * 0.12), skin[1])
	p.ball(c, Vector2(rx, ry), skin[0], skin[1], skin[2], tilt, 0.65)
	var fx: Vector2 = R.call(Vector2(f * rx * 0.16, 0))
	var blush := float(fc.get("blush", 0.15))
	if blush > 0.0:
		p.blob(fx + Vector2(f * rx * 0.42, ry * 0.28).rotated(tilt), Vector2(rx * 0.24, ry * 0.14), Color(BLUSH, 0.25 + blush * 0.4), 10)
		p.blob(fx + Vector2(-f * rx * 0.38, ry * 0.28).rotated(tilt), Vector2(rx * 0.16, ry * 0.12), Color(BLUSH, 0.15 + blush * 0.3), 10)
	if beard:
		# the beard on the jaw and round the mouth only: the cheeks and the eyes stay clear
		var bpts := Pen.ell_pts(R.call(Vector2(0, ry * 0.36)), Vector2(rx * 0.99, ry * 0.68), tilt, 20, 0.12, PI - 0.12)
		bpts.append(R.call(Vector2(-rx * 0.93, ry * 0.06)))
		bpts.append(R.call(Vector2(-rx * 0.55, ry * 0.34)))
		bpts.append(R.call(Vector2(f * rx * 0.2, ry * 0.3)))
		bpts.append(R.call(Vector2(rx * 0.55, ry * 0.34)))
		bpts.append(R.call(Vector2(rx * 0.93, ry * 0.06)))
		p.form(bpts, hair_c, hair_c.darkened(0.3), 0.85)
		p.line(Pen.ell_pts(R.call(Vector2(0, ry * 0.36)), Vector2(rx * 0.9, ry * 0.6), tilt, 8, PI * 0.25, PI * 0.55), 0.5, hair_c.lightened(0.3))
	# the nose, breaking the silhouette toward the facing side
	var nose: Vector2 = R.call(Vector2(f * rx * 0.74, ry * 0.12))
	p.ball(nose, Vector2(rx * 0.17, ry * 0.15), skin[0], skin[1], skin[2], 0.0, 0.0)
	p.ell(nose + Vector2(-f * rx * 0.04, ry * 0.07), Vector2(rx * 0.05, ry * 0.035), skin[1].darkened(0.2))
	# the eyes
	var eyes := str(fc.get("eyes", "open"))
	var blink := fmod(_t + seed * 1.7, 3.6 + seed * 0.4) < 0.11
	if blink and eyes in ["open", "wide", "worried"]:
		eyes = "blink"
	var look := float(fc.get("look", 0.0))
	var bdy := float(fc.get("brows", 0.0))
	var btilt := float(fc.get("brow_tilt", 0.0))
	for side: int in [1, -1]:
		var near := side == 1
		var ex := fx + Vector2(f * side * rx * (0.30 if near else 0.28), -ry * 0.05).rotated(tilt)
		var sc := 1.0 if near else 0.72
		var er := Vector2(rx * 0.17 * sc, ry * 0.15)
		match eyes:
			"open", "wide", "worried":
				var k := 1.3 if eyes == "wide" else 1.0
				p.ell(ex, er * k, Color("#fbf8f2"), tilt, 14)
				var pr := rx * 0.1 * (0.72 if eyes == "wide" else 1.0)
				var pc := ex + Vector2(f * look * er.x * 0.35, er.y * 0.1)
				p.ell(pc, Vector2(pr * sc, pr), Color("#2a1c1a"), 0.0, 12)
				p.ell(pc + Vector2(-pr * 0.35, -pr * 0.4), Vector2(pr * 0.32, pr * 0.32), Color(1, 1, 1, 0.95), 0.0, 8)
				p.line(Pen.ell_pts(ex, er * k * 1.05, tilt, 8, PI * 1.08, PI * 1.92), 0.55, skin[1].darkened(0.35))
			"blink":
				p.line(PackedVector2Array([ex + Vector2(-er.x, 0.3), ex + Vector2(er.x, 0.3)]), 0.6, skin[1].darkened(0.4))
			"shut", "happy":
				p.line(Pen.ell_pts(ex + Vector2(0, er.y * 0.3), er, tilt, 8, PI * 1.1, PI * 1.9), 0.7, Color("#2a1c1a"))
		# the brows
		var by := ex + Vector2(0, -ry * (0.27 + bdy * 0.1)).rotated(tilt)
		var inner := by + Vector2(-f * side * er.x * 1.0, (btilt + (0.25 if eyes == "worried" else 0.0)) * ry * 0.09)
		var outer := by + Vector2(f * side * er.x * 1.1, -btilt * ry * 0.06)
		var bw := ry * 0.07
		p.poly(PackedVector2Array([inner + Vector2(0, -bw * 0.5), outer + Vector2(0, -bw * 0.3), outer + Vector2(0, bw * 0.2), inner + Vector2(0, bw * 0.5)]),
				hair_c.darkened(0.1))
	if bool(fc.get("freckles", false)):
		for i in 4:
			p.ell(fx + Vector2(f * rx * (0.2 + i * 0.12), ry * (0.2 + (i % 2) * 0.06)).rotated(tilt), Vector2(rx * 0.025, rx * 0.025), skin[1].darkened(0.2), 0.0, 6)
	# the mouth
	var mouth := str(fc.get("mouth", "rest"))
	var talk: Array = fc.get("talk", [])
	if not talk.is_empty():
		mouth = _talk_mouth(str(talk[0]), float(talk[1]), mouth)
	var mc := fx + Vector2(f * rx * 0.22, ry * 0.5 + float(fc.get("jaw", 0.0)) * ry).rotated(tilt)
	var mw := rx * 0.36
	var lip: Color = skin[1].darkened(0.35) if not beard else Color("#c98a7a")
	match mouth:
		"rest":
			p.line(PackedVector2Array([mc + Vector2(-mw * 0.6, 0), mc + Vector2(0, mw * 0.12), mc + Vector2(mw * 0.6, -mw * 0.04)]), 0.6, lip)
		"smile":
			p.line(Pen.ell_pts(mc + Vector2(0, -mw * 0.35), Vector2(mw * 0.75, mw * 0.5), tilt, 8, PI * 0.15, PI * 0.85), 0.7, lip)
		"tight":
			p.line(PackedVector2Array([mc + Vector2(-mw * 0.55, 0), mc + Vector2(mw * 0.55, -mw * 0.02)]), 0.65, lip)
			p.ell(mc + Vector2(mw * 0.62, -mw * 0.06), Vector2(mw * 0.08, mw * 0.08), lip, 0.0, 6)
		"grin", "smack":
			var r := Vector2(mw, mw * 0.62) if mouth == "grin" else Vector2(mw * 1.15, mw * 0.9)
			var pts := Pen.ell_pts(mc, r, tilt, 12, 0.0, PI)
			p.poly(pts, MOUTH)
			p.poly(PackedVector2Array([mc + Vector2(-r.x * 0.9, 0), mc + Vector2(r.x * 0.9, 0), mc + Vector2(r.x * 0.75, r.y * 0.3), mc + Vector2(-r.x * 0.75, r.y * 0.3)]), Color("#fbf8f2"))
			p.ell(mc + Vector2(0, r.y * 0.72), Vector2(r.x * 0.5, r.y * 0.22), TONGUE)
		"a":
			p.ell(mc + Vector2(0, mw * 0.2), Vector2(mw * 0.5, mw * 0.42), MOUTH, tilt, 12)
			p.rect(mc.x - mw * 0.34, mc.y - mw * 0.14, mw * 0.68, mw * 0.14, Color("#fbf8f2"))
			p.ell(mc + Vector2(0, mw * 0.42), Vector2(mw * 0.28, mw * 0.12), TONGUE)
		"o":
			p.ell(mc + Vector2(0, mw * 0.1), Vector2(mw * 0.24, mw * 0.26), MOUTH, tilt, 10)
		"chew":
			var cs := sin(_t * TAU * 3.0)
			p.line(PackedVector2Array([mc + Vector2(-mw * 0.5 + cs * mw * 0.1, 0), mc + Vector2(mw * 0.5 + cs * mw * 0.1, -mw * 0.06)]), 0.75, lip)
			p.blob(fx + Vector2(f * cs * rx * 0.5, ry * 0.42).rotated(tilt), Vector2(rx * 0.22, ry * 0.15), Color(skin[2], 0.5), 8)
		"squiggle":
			var sq := PackedVector2Array()
			for i in 7:
				var u := float(i) / 6.0
				sq.append(mc + Vector2((u - 0.5) * mw * 1.2, sin(u * TAU * 1.2) * mw * 0.12))
			p.line(sq, 0.65, lip)
	if bool(fc.get("sweat", false)):
		var sp: Vector2 = R.call(Vector2(-f * rx * 0.75, -ry * 0.35 + fmod(_t * 0.8, 1.0) * ry * 0.3))
		p.poly(PackedVector2Array([sp + Vector2(0, -rx * 0.18), sp + Vector2(rx * 0.1, rx * 0.04), sp + Vector2(-rx * 0.1, rx * 0.04)]), Color("#bfe8ff"))
		p.ell(sp + Vector2(0, rx * 0.05), Vector2(rx * 0.1, rx * 0.1), Color("#bfe8ff"), 0.0, 8)
	# the hair on top
	match hair:
		"short", "messy":
			var hc: Vector2 = R.call(Vector2(-f * rx * 0.06, -ry * 0.12))
			var hp := Pen.ell_pts(hc, Vector2(rx * 1.04, ry * 0.95), tilt, 16, PI * 1.02, PI * 1.98)
			if hair == "messy":
				for i in hp.size():
					if i % 2 == 0:
						hp[i] = hp[i] + (hp[i] - c).normalized() * rx * 0.12
			hp.append(R.call(Vector2(-f * rx * 0.2, -ry * 0.42)))
			p.form(hp, hair_c, hair_c.darkened(0.25), 0.85)
			p.line(Pen.ell_pts(hc, Vector2(rx * 0.92, ry * 0.85), tilt, 6, PI * 1.15, PI * 1.45), 0.55, hair_c.lightened(0.25))
			p.poly(PackedVector2Array([R.call(Vector2(-f * rx * 0.92, -ry * 0.25)), R.call(Vector2(-f * rx * 0.62, -ry * 0.3)), R.call(Vector2(-f * rx * 0.66, ry * 0.12)), R.call(Vector2(-f * rx * 0.86, ry * 0.06))]), hair_c)
		"cap_back":
			var lift := float(fc.get("cap_lift", 0.0)) * ry
			var cc: Vector2 = R.call(Vector2(0, -ry * 0.18 - lift))
			p.form(Pen.ell_pts(cc, Vector2(rx * 1.07, ry * 0.92), tilt, 16, PI * 1.0, PI * 2.0), BLACK[0], BLACK[1], 0.84)
			p.line(Pen.ell_pts(cc, Vector2(rx * 0.98, ry * 0.84), tilt, 8, PI * 1.1, PI * 1.5), 0.6, BLACK[2])
			p.seg(R.call(Vector2(-rx * 1.06, -ry * 0.18 - lift)), R.call(Vector2(rx * 1.06, -ry * 0.18 - lift)), 0.9, BLACK[1])
			p.ell(R.call(Vector2(-f * rx * 0.55, -ry * 0.62 - lift)), Vector2(rx * 0.12, rx * 0.08), GOLD, tilt, 8)
		"beanie":
			var bc: Vector2 = R.call(Vector2(0, -ry * 0.2))
			p.form(Pen.ell_pts(bc, Vector2(rx * 1.08, ry * 0.95), tilt, 16, PI * 1.0, PI * 2.0), MUSTARD, MUSTARD.darkened(0.3), 0.84)
			p.rrect_v(bc.x - rx * 1.1, bc.y - ry * 0.1, rx * 2.2, ry * 0.26, ry * 0.08, MUSTARD.lightened(0.1), MUSTARD.darkened(0.25))
			for i in 7:
				var rxk := bc.x - rx * 0.95 + i * rx * 0.32
				p.seg(Vector2(rxk, bc.y - ry * 0.08), Vector2(rxk, bc.y + ry * 0.14), 0.4, MUSTARD.darkened(0.35))
			var lag := sin(_t * 5.0 + seed) * rx * 0.12
			p.ball(bc + Vector2(lag, -ry * 1.02).rotated(tilt), Vector2(rx * 0.3, rx * 0.28), MUSTARD.lightened(0.15), MUSTARD.darkened(0.25), Color("#fff0b0"))
			p.poly(PackedVector2Array([R.call(Vector2(-f * rx * 0.95, -ry * 0.05)), R.call(Vector2(-f * rx * 0.7, -ry * 0.1)), R.call(Vector2(-f * rx * 0.75, ry * 0.45)), R.call(Vector2(-f * rx * 0.98, ry * 0.35))]), hair_c)


## The open-mouth letters, Polish ones as escapes (a code table, not on-screen text).
const VOWELS := "aeiouy\u0105\u0119\u00f3"


## The mouth for a line being spoken: about 14 letters a second, a vowel open, a consonant small,
## the gaps and the end at rest.
func _talk_mouth(s: String, t: float, rest: String) -> String:
	var i := int(t * 14.0)
	if i >= s.length() or s == "":
		return rest
	var ch := s.substr(i, 1).to_lower()
	if VOWELS.contains(ch):
		return "a"
	if ch in [" ", ",", ".", "!", "?", "…", "„", "”", "\""]:
		return rest
	return "o"


## The line `who` is saying now, for the mouth: [text, time since it started].
func _talk_of(who: String) -> Array:
	if tasting.who != who or tasting.line[0] == "":
		return []
	return [_pick(tasting.line), tasting.t]


func _you(p: Pen) -> void:
	var ph := tasting.phase
	var g := tasting.grade
	var face := {"hair": "messy", "hair_c": Color("#5a3a24"), "look": 1.0, "blush": 0.1, "mouth": "smile"}
	var near := [0.15, 0.25]
	var far := [0.05, 0.35]
	var hold_near := ""
	var bob := 0.0
	match ph:
		Tasting.Phase.CHEW:
			face["eyes"] = "worried"
			face["mouth"] = "tight"
			face["sweat"] = true
			near = [0.35, 1.4]
		Tasting.Phase.MLASK:
			face["eyes"] = "wide"
			face["brows"] = 1.2
			face["mouth"] = "o"
			bob = 1.4 * maxf(0.0, 1.0 - tasting.t / 0.3)
		Tasting.Phase.DRUM:
			face["mouth"] = "tight"
			face["eyes"] = "worried"
		Tasting.Phase.GRADE:
			if tasting.perfect:
				face["eyes"] = "happy"
				face["mouth"] = "grin"
				near = [2.6, 0.3]
				far = [2.5, 0.2]
				bob = absf(sin(tasting.t * 9.0)) * 4.0
			elif g >= 8.0:
				face["mouth"] = "grin"
				near = [2.2, 0.9]
				hold_near = "fist"
		Tasting.Phase.FAN, Tasting.Phase.SELFIE:
			face["look"] = -0.6
			if ph == Tasting.Phase.SELFIE and g >= 8.0:
				near = [2.5, 0.2]
				hold_near = "thumb"
				face["mouth"] = "grin"
	_person(p, {"x": _you_x(), "foot": FEET, "h": 92.0, "f": 1, "skin": SKIN, "top": JACKET, "legs": JEANS, "shoe": Color("#2a2630"),
			"seed": 0.4, "near": near, "far": far, "hold_near": hold_near, "hold_far": "bag" if ph >= Tasting.Phase.HELLO else "", "face": face, "bob": bob})


func _kebabulo(p: Pen) -> void:
	var ph := tasting.phase
	var g := tasting.grade
	var t := tasting.t
	var face := {"hair": "cap_back", "hair_c": BLACK[0], "beard": true, "look": 0.6, "blush": 0.2, "mouth": "smile"}
	var near := [0.35, 1.5]
	var far := [0.1, 0.3]
	var hold := "kebab" if ph < Tasting.Phase.CHEW else "kebab_bit"
	var hold_far := ""
	var lean := 0.0
	var bob := 0.0
	var talk := _talk_of("kebabulo")
	if not talk.is_empty():
		face["talk"] = talk
	match ph:
		Tasting.Phase.HELLO:
			face["brows"] = 0.6
			near = [0.6, 1.7]
		Tasting.Phase.CHEW, Tasting.Phase.MLASK:
			face["eyes"] = "happy"
			face["mouth"] = "chew"
			face["tilt"] = -0.1
			near = [0.9, 1.8]
		Tasting.Phase.VERDICT:
			# a gesture with the kebab at each line's start (a little anticipation first)
			var lift := sin(clampf((t - 0.08) / 0.4, 0.0, 1.0) * PI) * 0.5 - (0.08 if t < 0.08 else 0.0)
			near = [0.6 + lift, 1.6 - lift * 0.6]
			far = [0.5, 1.2]
			face["brows"] = 0.8
			face["tilt"] = sin(t * 6.0) * 0.03
		Tasting.Phase.DRUM:
			face["look"] = sin(t * 5.0)
			face["mouth"] = "tight"
			face["brows"] = 0.5
			near = [0.5, 1.6]
			lean = sin(t * 75.0) * 0.004
		Tasting.Phase.GRADE:
			if tasting.perfect:
				face["eyes"] = "wide" if t < 0.6 else "happy"
				face["mouth"] = "smack" if t < 0.6 else "grin"
				face["cap_lift"] = maxf(0.0, 0.25 - absf(t - 0.25)) * 1.2
				near = [2.7, 0.4]
				far = [2.6, 0.3]
				bob = maxf(0.0, sin(t * 6.0)) * 2.0
			elif g >= 8.0:
				face["mouth"] = "grin"
				face["brows"] = 0.6
				hold_far = "fist"
				far = [2.3, 1.0]
			elif g >= 5.0:
				hold_far = "thumb"
				far = [1.3, 0.9]
			else:
				face["mouth"] = "squiggle"
				face["brow_tilt"] = 0.8
				face["tilt"] = 0.08
		Tasting.Phase.FAN:
			face["look"] = 1.0
			if tasting.fan_i == 0:
				face["brows"] = 0.4 if t < 0.4 else 0.0
				face["brow_tilt"] = 0.6 if t < 0.4 else 0.0
				face["mouth"] = "rest"
			else:
				face["mouth"] = "grin"
				near = [1.4 + sin(t * 9.0) * 0.25, 1.2]
		Tasting.Phase.SELFIE:
			face["mouth"] = "grin"
			face["eyes"] = "happy"
			face["look"] = 0.0
			near = [1.6, 1.9]
			lean = -0.12
	_person(p, {"x": _kebabulo_x(), "foot": FEET, "h": 102.0, "f": -1, "skin": SKIN_TAN, "top": HOODIE, "legs": BLACK, "shoe": WHITE_SHOE,
			"build": "big", "bp": 3.6, "seed": 1.3, "hood": true, "chain": true, "near": near, "far": far, "hold_near": hold, "hold_far": hold_far,
			"face": face, "lean": lean, "bob": bob})


func _zbyszek(p: Pen) -> void:
	var ph := tasting.phase
	var t := tasting.t
	var face := {"hair": "short", "hair_c": Color("#c8a060"), "look": 1.0, "blush": 0.1, "mouth": "smile"}
	var talk := _talk_of("zbyszek")
	if not talk.is_empty():
		face["talk"] = talk
	var lis := Vector2(sin(_t * TAU / 2.3), sin(_t * TAU / 3.1)) * 0.05
	var near := [1.35 + lis.x, 0.25 + lis.y]
	var far := [0.1, 0.3]
	var hold_far := ""
	var lean := 0.0
	match ph:
		Tasting.Phase.CHEW:
			near = [1.5, 0.15]
			lean = -0.07
		Tasting.Phase.MLASK:
			face["eyes"] = "wide"
			face["brows"] = 1.2
			face["mouth"] = "o"
			near = [1.6, 0.1]
		Tasting.Phase.DRUM:
			far = [0.9 + sin(t * 40.0) * 0.12, 1.0]
		Tasting.Phase.GRADE, Tasting.Phase.SELFIE:
			if tasting.grade >= 8.0:
				face["mouth"] = "grin"
				hold_far = "thumb"
				far = [1.2, 1.2]
	_person(p, {"x": _zbyszek_x(), "foot": FEET, "h": 90.0, "f": -1, "skin": SKIN_FAIR, "top": CHARCOAL, "legs": DARK_JEANS, "shoe": Color("#c9d2d8"),
			"seed": 2.1, "near": near, "far": far, "hold_near": "gimbal", "hold_far": hold_far, "face": face, "lean": lean})


## The fan: a teen in a raspberry puffer and a mustard beanie, starstruck; shuffles in, asks, hops at
## the yes, then the selfie with the phone held out, the peace sign.
func _fan(p: Pen) -> void:
	var ph := tasting.phase
	var t := tasting.t
	var walking := ph == Tasting.Phase.CARD or absf(_fan_x - _fan_goal()) > 1.5
	var face := {"hair": "beanie", "hair_c": Color("#6a3a24"), "eyes": "wide", "look": 1.0, "blush": 0.5, "freckles": true, "mouth": "smile"}
	var talk := _talk_of("fan")
	if not talk.is_empty():
		face["talk"] = talk
	var near := [0.9, 1.6]
	var far := [0.8, 1.7]
	var hold_far := ""
	var bob := 0.0
	if ph == Tasting.Phase.FAN and tasting.fan_i == 0 and t > 1.4:
		# "for my mum": looks away, scratches the neck, the blush up
		face["look"] = -1.0
		face["blush"] = 0.9
		far = [2.4, 2.2]
	if ph == Tasting.Phase.FAN and tasting.fan_i == 1:
		face["eyes"] = "happy"
		face["mouth"] = "grin"
		bob = maxf(0.0, sin(clampf(t / 0.35, 0.0, 1.0) * PI)) * 3.0
	if ph == Tasting.Phase.SELFIE:
		face["mouth"] = "grin"
		face["eyes"] = "happy" if t > 0.55 else "open"
		face["look"] = 0.0
		near = [2.2, -0.2]
		far = [2.4, 0.5]
		hold_far = "peace"
	if ph == Tasting.Phase.CARD:
		near = [0.4, 0.3]
		face["mouth"] = "grin"
	_person(p, {"x": _fan_x, "foot": FEET, "h": 81.0, "f": 1, "skin": SKIN_FAIR, "top": PUFFER, "legs": LIGHT_JEANS, "shoe": WHITE_SHOE,
			"seed": 3.3, "puffer": true, "backpack": true, "near": near, "far": far, "hold_near": "phone", "hold_far": hold_far, "face": face,
			"bob": bob, "walk": _t * TAU * 2.0 if walking else -1.0})


# --- the stream's layer -------------------------------------------------------------------------

## The art above the scene, in the pixel layer: the close-up, the MLASK burst, hearts, confetti.
func _draw_mid() -> void:
	var p := _mid_pen
	p.o = Vector2.ZERO
	var right := W - maxf(6.0, _safe_canvas().y + 4.0)
	var ph := tasting.phase
	if ph in [Tasting.Phase.CHEW, Tasting.Phase.MLASK]:
		_close_up(p)
	if ph == Tasting.Phase.MLASK:
		_burst(p)
	_floaters_draw(p, right)
	_bits_draw(p)


func _draw_ui() -> void:
	var p := _ui_pen
	p.o = Vector2.ZERO
	var safe := _safe_canvas()
	var left := maxf(6.0, safe.x + 4.0)
	var right := W - maxf(6.0, safe.y + 4.0)
	var ph := tasting.phase
	_chat(p, left)
	if ph in [Tasting.Phase.DRUM, Tasting.Phase.GRADE]:
		_scoreboard(p, left)
	if tasting.line[0] != "" and ph != Tasting.Phase.CARD:
		_line(p, left, right)
	if ph == Tasting.Phase.SELFIE:
		_selfie_flash(p)
	_rec_frame(p, left, right)
	_top_chips(p, left, right)
	if ph == Tasting.Phase.CARD:
		_card(p, left)
	if _flash > 0.0:
		p.rect(0, 0, W, H, Color(1, 1, 1, _flash / 0.08 * 0.6))
	if ph == Tasting.Phase.IN:
		_viewfinder(p)
	if _wipe > 0.0:
		p.rect(0, 0, W, H, Color(0.04, 0.04, 0.05, Pen.ease_in_out(_wipe)))


func _top_chips(p: Pen, left: float, right: float) -> void:
	var ph := tasting.phase
	# NA ŻYWO with its pulsing dot, the viewers with an eye and the rolling count
	var live := _w("live")
	var lw := Pen.text_w(live, T_CHIP) + 13.0
	p.rrect(left + 4, 6, lw, 10, 5, RED)
	p.ell(Vector2(left + 9, 11), Vector2(1.7, 1.7), Color(1, 1, 1, 0.6 + 0.4 * sin(_t * 6.0)), 0.0, 10)
	p.text(live, left + 12.5, 7.6, T_CHIP, Color.WHITE)
	var vt := _w("viewers").format({"n": _thousands(int(round(_shown_viewers)))})
	var vw := Pen.text_w(vt, T_CHIP) + 15.0
	var vx := left + 7 + lw
	p.rrect(vx, 6, vw, 10, 5, Color(0.05, 0.05, 0.08, 0.6))
	p.ell(Vector2(vx + 5.5, 11), Vector2(2.6, 1.6), Color.WHITE, 0.0, 12)
	p.ell(Vector2(vx + 5.5, 11), Vector2(1.0, 1.0), Color(0.05, 0.05, 0.08), 0.0, 8)
	p.text(vt, vx + 10, 7.6, T_CHIP, Color.WHITE)
	if _plus_t < 1.2 and _plus > 0:
		var a := 1.0 - Pen.ease_in_out(_plus_t / 1.2)
		p.text("+%d" % _plus, vx + vw + 3, 7.6 - _plus_t * 4.0, T_CHIP, Color(GREEN, a), -1, 0.4)
	p.text(_w("channel"), left + 5, 18.5, T_NAME, Color(1, 1, 1, 0.85), -1, 0.4)
	# skip, top right, until the card: a pill with its ring filling
	if ph < Tasting.Phase.CARD:
		var label := _w("skip")
		var sw := Pen.text_w(label, T_CHIP) + 18.0
		var sx := right - sw
		p.rrect(sx, 6, sw, 10, 5, Color(0.05, 0.05, 0.08, 0.6))
		var ring := Vector2(sx + 6, 11)
		p.line(Pen.ell_pts(ring, Vector2(3, 3), 0.0, 16, 0.0, TAU), 0.6, Color(1, 1, 1, 0.35))
		var k := clampf(tasting.skip_t / Tasting.SKIP_S, 0.0, 1.0)
		if k > 0.0:
			p.line(Pen.ell_pts(ring, Vector2(3, 3), 0.0, 16, -PI * 0.5, -PI * 0.5 + TAU * k), 0.9, GOLD)
		p.text("×", ring.x, 7.2, T_CHIP, Color.WHITE, 0)
		p.text(label, sx + 11.5, 7.6, T_CHIP, Color.WHITE)
		_skip_rect = _grow(Rect2(sx, 6, sw, 10))
	else:
		_skip_rect = Rect2()


func _thousands(n: int) -> String:
	if n < 1000:
		return str(n)
	return "%d %03d" % [n / 1000, n % 1000]


## The REC corners (round caps), the dot and a running timecode.
func _rec_frame(p: Pen, left: float, right: float) -> void:
	var c := Color(1, 1, 1, 0.85)
	for corner: Array in [[left, 3.0, 1, 1], [right, 3.0, -1, 1], [left, H - 3.0, 1, -1], [right, H - 3.0, -1, -1]]:
		var x: float = corner[0]
		var y: float = corner[1]
		var sx: int = corner[2]
		var sy: int = corner[3]
		p.line(PackedVector2Array([Vector2(x, y + sy * 11), Vector2(x, y), Vector2(x + sx * 11, y)]), 0.9, c)
	if fmod(_t, 1.0) < 0.6:
		p.ell(Vector2(W * 0.5 - 16, 11), Vector2(2.2, 2.2), RED, 0.0, 12)
	var secs := int(tasting.total) + 754
	p.text("%s  %02d:%02d" % [_w("rec"), secs / 60, secs % 60], W * 0.5 - 12, 7.6, T_CHIP, Color.WHITE, -1, 0.4)


## Three chat lines bottom left on a soft scrim: an avatar dot, a coloured nick, white text; the
## newest at the bottom sliding up, the older ones fading.
func _chat(p: Pen, left: float) -> void:
	var n := tasting.chat.size()
	if n == 0:
		return
	p.poly_cols(PackedVector2Array([Vector2(0, H - 54), Vector2(W * 0.52, H - 54), Vector2(W * 0.52, H), Vector2(0, H)]),
			PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6)]))
	p.poly_cols(PackedVector2Array([Vector2(0, H - 54), Vector2(W * 0.4, H - 54), Vector2(W * 0.4, H), Vector2(0, H)]),
			PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0.3)]))
	for i in n:
		var c: Dictionary = tasting.chat[i]
		var age := n - 1 - i
		var y := H - 17.0 - age * 11.0
		var rise := Pen.ease_out(float(c["t"]) / 0.15)
		y += (1.0 - rise) * 6.0
		var a := rise * (1.0 if age == 0 else 0.72)
		var name := str(c["name"])
		var text := Lang.pick(str(c["pl"]), str(c["en"]))
		var col: Color = NICKS[absi(name.hash()) % NICKS.size()]
		p.ell(Vector2(left + 8, y + 3.6), Vector2(3.2, 3.2), Color(col, a * 0.9), 0.0, 12)
		p.text(name.substr(0, 1), left + 8, y + 1.0, 4.4, Color(0.05, 0.05, 0.08, a), 0)
		p.text(name, left + 14, y, T_CHAT, Color(col, a), -1, 0.4)
		p.text(text, left + 17 + Pen.text_w(name, T_CHAT), y, T_CHAT, Color(1, 1, 1, a), -1, 0.4)


## The room the chat has (the check holds every chat line to it): the scrim's width.
func chat_w() -> float:
	return W * 0.52 - 12.0


## A chat line's width, for the check: the handle and the text.
static func chat_line_w(name: String, text: String) -> float:
	return 14.0 + Pen.text_w(name, T_CHAT) + 3.0 + Pen.text_w(text, T_CHAT)


## The line's bubble width.
func line_w() -> float:
	return minf(roundf(W * 0.42), 200.0)


## The speaker's head top (the bubble's tail points at it).
func _speaker_at() -> Vector2:
	match tasting.who:
		"kebabulo":
			return Vector2(_kebabulo_x() - 4.0, FEET - 104.0)
		"zbyszek":
			return Vector2(_zbyszek_x(), FEET - 92.0)
		"fan":
			return Vector2(_fan_x, FEET - 90.0)
	return Vector2(W * 0.5, FEET - 100.0)


## The speaker's line in a rounded card above the speaker's head, the name on its tab, the tail
## down to the head; the tap hint a pulsing chevron inside.
func _line(p: Pen, left: float, right: float) -> void:
	var bw := line_w()
	var lines := Pen.wrap(_pick(tasting.line), bw - 14.0, T_LINE)
	var lh := 9.4
	var bh := lines.size() * lh + 10.0
	var head := _speaker_at()
	var lo := left + 2.0
	if tasting.phase == Tasting.Phase.DRUM or tasting.phase == Tasting.Phase.GRADE:
		lo = left + 14.0 + SCORE_W + 6.0
	var bx := clampf(head.x - bw * 0.5, lo, right - bw - 2.0)
	var by := maxf(30.0, head.y - 8.0 - bh)
	var s := Pen.pop(tasting.t / 0.22, 1.06)
	var cx := bx + bw * 0.5
	var cy := by + bh
	var bx2 := cx + (bx - cx) * s
	var by2 := cy + (by - cy) * s
	var bw2 := bw * s
	var bh2 := bh * s
	p.rrect(bx2 + 1.2, by2 + 1.6, bw2, bh2, 6, Color(0, 0, 0, 0.25))
	var tail_x := clampf(head.x, bx2 + 10.0, bx2 + bw2 - 10.0)
	p.poly(PackedVector2Array([Vector2(tail_x - 5, by2 + bh2 - 1), Vector2(tail_x + 5, by2 + bh2 - 1), Vector2(head.x, by2 + bh2 + 6.5)]), Color("#f2e6cc"))
	p.rrect_v(bx2, by2, bw2, bh2, 6, Color("#fffaf0"), Color("#f2e6cc"))
	if s < 0.98:
		return
	var name := _w("name_" + tasting.who) if tasting.who != "" else ""
	if name != "":
		var nc := Color("#ff8038") if tasting.who == "kebabulo" else (Color("#d8457a") if tasting.who == "fan" else Color("#1f8fb0"))
		var nw := Pen.text_w(name, T_NAME) + 10.0
		p.rrect(bx + 8, by - 5.5, nw, 9, 4.5, nc)
		p.text(name, bx + 13, by - 4.2, T_NAME, Color.WHITE)
	for i in lines.size():
		p.text(lines[i], bx + 7, by + 5.2 + i * lh, T_LINE, Color("#2a1f3d"))
	var ph := tasting.phase
	if (ph == Tasting.Phase.HELLO or ph == Tasting.Phase.VERDICT or ph == Tasting.Phase.GRADE or ph == Tasting.Phase.FAN) and tasting.t > Tasting.TAP_S:
		var a := 0.5 + 0.5 * sin(_t * 5.0)
		var tx := bx + bw - 8.0 + sin(_t * 5.0) * 1.0
		var ty := by + bh - 7.0
		p.line(PackedVector2Array([Vector2(tx - 2, ty - 2.5), Vector2(tx + 1, ty), Vector2(tx - 2, ty + 2.5)]), 1.1, Color(Color("#ff8038"), a))


## The close-up: a rounded picture-in-picture card with a white border over Kebabulo and Zbyszek,
## his face big, the bite, the chewing with his eyes shut, the bliss (the smack at the MLASK).
func _close_up(p: Pen) -> void:
	var x := W * 0.48
	var y := 26.0
	var pw := W - x - 12.0
	var ph := H - y - 10.0
	var slide := 0.0 if Access.calm or tasting.phase != Tasting.Phase.CHEW else 1.0 - Pen.ease_out(tasting.t / 0.22)
	x += slide * (pw + 30.0)
	p.rrect(x + 2, y + 3, pw, ph, 9, Color(0, 0, 0, 0.35))
	p.rrect(x - 1.6, y - 1.6, pw + 3.2, ph + 3.2, 10, Color.WHITE)
	p.rrect_v(x, y, pw, ph, 8, Color("#f6b06a"), Color("#e07a5a"))
	var mid := Vector2(x + pw * 0.5, y + ph * 0.5)
	p.blob(mid + Vector2(-pw * 0.2, -ph * 0.1), Vector2(pw * 0.5, ph * 0.5), Color("#ffe0a0", 0.6), 18)
	for i in 14:
		var a := float(i) / 14.0 * TAU + _t * 0.4
		var d := Vector2(cos(a), sin(a) * ph / pw)
		var p0 := mid + d * pw * 0.36
		var p1 := mid + d * pw * 0.48
		if p1.x > x + 3 and p1.x < x + pw - 3 and p1.y > y + 3 and p1.y < y + ph - 3:
			p.seg(p0, p1, 0.9, Color(1, 1, 1, 0.35))
	var mlask := tasting.phase == Tasting.Phase.MLASK
	var t := tasting.t
	var face := {"hair": "cap_back", "hair_c": BLACK[0], "beard": true, "blush": 0.45, "eyes": "happy"}
	var tilt := 0.0
	var jaw := 0.0
	if mlask:
		face["mouth"] = "smack"
		face["brows"] = 1.0
		face["brow_tilt"] = 0.6
		tilt = -0.1
	elif t < 0.18:
		face["mouth"] = "smack"
		face["eyes"] = "open"
		face["look"] = -0.8
	else:
		face["mouth"] = "chew"
		jaw = absf(sin((t - 0.18) * TAU * 3.0)) * 0.08
		tilt = -0.10 * Pen.ease_in_out((t - 0.18) / 0.5)
		face["brows"] = 0.6 * Pen.ease_out((t - 0.18) / 1.0)
		face["brow_tilt"] = 0.5
	face["jaw"] = jaw
	face["tilt"] = tilt
	var hh := ph * 3.1
	var hc := Vector2(x + pw * 0.54, y + ph * 0.46 + jaw * 6.0)
	# the hoodie at the bottom of the frame
	var sh := PackedVector2Array([Vector2(x + 6, y + ph), Vector2(x + pw * 0.14, y + ph * 0.8), Vector2(x + pw * 0.5, y + ph * 0.74),
			Vector2(x + pw * 0.88, y + ph * 0.8), Vector2(x + pw - 6, y + ph)])
	p.form(sh, HOODIE[0], HOODIE[1], 0.82)
	p.limb(Vector2(hc.x, hc.y + ph * 0.28), Vector2(hc.x, hc.y + ph * 0.1), 0.04 * hh, 0.04 * hh, SKIN_TAN[1], SKIN_TAN[1].darkened(0.1), 0.0)
	_head(p, hc, hh, -1, SKIN_TAN, face, 1.3)
	# the kebab at his mouth, the crumbs
	var km := hc + Vector2(-0.085 * hh * 0.9, 0.1 * hh * 0.5)
	if not mlask:
		_kebab(p, km + Vector2(-0.04 * hh, 0.05 * hh), 0.16 * hh, -1.0, t > 0.18, -1)
	for i in 6:
		var ct := fmod(t * 0.8 + i * 0.17, 1.0)
		var cp := km + Vector2(-6.0 + i * 2.4, 4.0 + ct * 30.0)
		if cp.y < y + ph - 4:
			p.ell(cp, Vector2(0.9, 0.7), TORTILLA[1], 0.0, 6)


## MLASK: a fourteen-spike star in yellow with a red stroke and a white inner line, the word heavy
## and leaning; it pops in with an overshoot, pulses while held, eight sauce drops fly.
func _burst(p: Pen) -> void:
	var t := tasting.t
	var k := 1.0 if Access.calm else Pen.pop(t / 0.18, 1.15)
	var pulse := 1.0 + 0.02 * sin(t * TAU * 6.0)
	var c := Vector2(W * 0.40, 78.0)
	var r0 := Vector2(78.0, 46.0) * k * pulse
	var r1 := r0 * 0.72
	var rot := -0.14 + 0.05 * (1.0 - k)
	if k < 0.05:
		return
	p.poly(Pen.star_pts(c + Vector2(3, 4), r0, r1, 14, rot), Color(0.1, 0.05, 0.1, 0.4))
	p.poly(Pen.star_pts(c, r0 * 1.05, r1 * 1.05, 14, rot), Color("#e0263a"))
	var inner := Pen.star_pts(c, r0 * 0.96, r1 * 0.96, 14, rot)
	var cols := PackedColorArray()
	for q in inner:
		cols.append(Color("#ffe14a").lerp(Color("#ffb020"), clampf((q.y - (c.y - r0.y)) / (r0.y * 2.0), 0.0, 1.0)))
	p.poly_cols(inner, cols)
	var ring := Pen.star_pts(c, r0 * 0.88, r1 * 0.88, 14, rot)
	ring.append(ring[0])
	p.line(ring, 0.8, Color(1, 1, 1, 0.85))
	for i in 8:
		var a := float(i) / 8.0 * TAU + 0.3
		var dp := c + Vector2(cos(a) * r0.x, sin(a) * r0.y) * (0.9 + t * 1.2)
		p.ell(dp, Vector2(2.2, 2.2) * maxf(0.0, 1.0 - t), SAUCE, 0.0, 8)
	if k > 0.6:
		p.text_outlined(_w("mlask"), c.x, c.y - 13.0 * k, 26.0 * k, Color("#2a1f3d"), Color.WHITE, 1.6, 0, -0.14)


## The scoreboard: the dark card, gold rim, the digits rolling like an odometer, then the grade;
## 11 cracks it (jagged lines, a flash, confetti) and a digit falls.
func _scoreboard(p: Pen, left: float) -> void:
	var bw := SCORE_W
	var bh := 60.0
	var appear := Pen.pop(tasting.t / 0.3, 1.08) if tasting.phase == Tasting.Phase.DRUM else 1.0
	var cx := left + 14.0 + bw * 0.5
	var cy := 32.0 + bh * 0.5
	var w := bw * appear
	var h := bh * appear
	var x := cx - w * 0.5
	var y := cy - h * 0.5
	p.rrect(x + 2, y + 3, w, h, 9, Color(0, 0, 0, 0.35))
	p.rrect_v(x, y, w, h, 9, Color("#22262c"), Color("#121418"))
	p.rrect_line(x + 1.4, y + 1.4, w - 2.8, h - 2.8, 7.6, 0.9, GOLD)
	if appear < 0.95:
		return
	var gc := Color("#fff2b0") if tasting.phase == Tasting.Phase.GRADE else GOLD
	p.text_outlined(tasting.board_text(), cx - 12, y + 10, 34.0, gc, Color("#7a4a10"), 1.2, 0)
	p.text("/ 10", x + w - 30, y + h - 16, 9.0, Color(1, 1, 1, 0.8))
	p.text(_w("card_grade"), x + 10, y + 6, T_NAME, Color(1, 1, 1, 0.6))
	if tasting.perfect and tasting.phase == Tasting.Phase.GRADE:
		for cr: Array in [[0.22, 0.1, 0.34, 0.5, 0.26, 0.92], [0.6, 0.06, 0.52, 0.4, 0.66, 0.7], [0.8, 0.2, 0.9, 0.55]]:
			var pts := PackedVector2Array()
			for i in range(0, cr.size(), 2):
				pts.append(Vector2(x + w * float(cr[i]), y + h * float(cr[i + 1])))
			p.line(pts, 1.1, Color(0.95, 0.95, 1.0, 0.9))
			p.line(pts, 0.4, Color("#5a5a6a"))
		var fall := minf(tasting.t * tasting.t * 160.0, 150.0)
		p.text("0", x + w - 15, y + h - 16 + fall, 9.0, Color.WHITE, -1, 0.0, tasting.t * 3.0)
		var label := _w("cracked")
		var lw := Pen.text_w(label, T_CHIP) + 14.0
		p.rrect(cx - lw * 0.5, y + h + 3, lw, 10, 5, GOLD)
		p.text(label, cx, y + h + 4.4, T_CHIP, INK, 0)


## The selfie: the pre-flash dot at the fan's phone, one flash (soft and warm under calm), the star
## flare, and the instant print popping out, tilted.
func _selfie_flash(p: Pen) -> void:
	var t := tasting.t
	var lens := Vector2(_fan_x + 22.0, FEET - 74.0)
	if t > 0.32 and t < 0.40:
		p.ell(lens, Vector2(1.6, 1.6), Color.WHITE, 0.0, 10)
	if t < 0.55:
		return
	var ft := t - 0.55
	var a := (0.85 if not Access.calm else 0.35) * exp(-ft / 0.08)
	p.rect(0, 0, W, H, Color(1.0, 0.98, 0.92, a) if not Access.calm else Color(1.0, 0.9, 0.7, a))
	if ft < 0.16 and not Access.calm:
		var sk := sin(ft / 0.16 * PI) * 1.4
		p.poly(Pen.star_pts(lens, Vector2(16, 16) * sk, Vector2(2, 2) * sk, 4, PI * 0.25), Color(1, 1, 1, 0.9))
	if ft > 0.25:
		_print(p, Vector2(W * 0.5, H * 0.44), 62.0 * Pen.pop((ft - 0.25) / 0.35, 1.12), -0.1)
	if ft < 0.3:
		p.text(_w("snap"), lens.x, lens.y - 16, 9.0, Color(1, 1, 1, 1.0 - ft / 0.3), 0, 0.6)


## The instant print of the selfie: a white frame, the two faces on a warm backdrop, the caption;
## the faces follow the grade.
func _print(p: Pen, c: Vector2, size: float, rot: float) -> void:
	if size < 4.0:
		return
	var w := size
	var h := size * 1.2
	p.poly(_rot_rect(c + Vector2(1.5, 2.2), Vector2(w, h), rot), Color(0, 0, 0, 0.3))
	p.poly(_rot_rect(c, Vector2(w, h), rot), Color("#fbfaf6"))
	var img := c + Vector2(0, -h * 0.08).rotated(rot)
	var iw := w * 0.86
	var ih := w * 0.84
	p.poly_cols(_rot_rect(img, Vector2(iw, ih), rot), PackedColorArray([Color("#f2a05e"), Color("#c9788a"), Color("#e07a5a"), Color("#ffd98a")]))
	p.blob(img + Vector2(-iw * 0.25, -ih * 0.2), Vector2(iw * 0.3, ih * 0.24), Color("#fff4cc", 0.7), 10)
	var good := tasting.grade >= 8.0 or tasting.perfect
	var hh := ih * 2.1
	_head(p, img + Vector2(iw * 0.16, ih * 0.12).rotated(rot), hh, -1, SKIN_TAN,
			{"hair": "cap_back", "hair_c": BLACK[0], "beard": true, "eyes": "happy", "mouth": "grin" if good else "tight", "tilt": rot - 0.12, "blush": 0.3}, 1.3)
	_head(p, img + Vector2(-iw * 0.2, ih * 0.22).rotated(rot), hh * 0.86, 1, SKIN_FAIR,
			{"hair": "beanie", "hair_c": Color("#6a3a24"), "eyes": "happy", "mouth": "grin", "tilt": rot + 0.1, "blush": 0.6, "freckles": true}, 3.3)
	var cap := c + Vector2(0, h * 0.4).rotated(rot)
	p.text(_w("print_caption"), cap.x, cap.y - 3.0, maxf(3.0, size * 0.07), Color("#5a4a60"), 0, 0.0, rot)


## The RECENZJA card: the dark recipe left of the middle (the scene dimmed behind), the order, the
## grade as a red stamp slamming in, the badge as a swinging medal, the selfie print taped on.
func _card(p: Pen, left: float) -> void:
	var t := tasting.t
	p.rect(0, 0, W, H, Color(0.03, 0.03, 0.05, 0.5 * Pen.ease_out(t / 0.3)))
	var cw := minf(W * 0.46, 220.0)
	var ch := 186.0
	var drop := 0.0 if Access.calm else _spring(t) * -40.0
	var x := maxf(left + 8.0, W * 0.5 - cw - 4.0)
	var y := 16.0 + drop
	p.rrect(x + 2.5, y + 3.5, cw, ch, 11, Color(0, 0, 0, 0.4))
	p.rrect_v(x, y, cw, ch, 11, Color("#22262c"), Color("#121418"))
	p.rrect_line(x + 1.5, y + 1.5, cw - 3, ch - 3, 9.5, 0.9, GOLD)
	p.text(_w("card_title"), x + 12, y + 10, 15.0, GOLD)
	p.text(_w("place"), x + 12, y + 28, T_NAME, Color(1, 1, 1, 0.6))
	var ry := y + 44.0 + maxf(0.0, 8.0 - (t - 0.15) * 60.0)
	p.text(_w("card_order"), x + 12, ry, T_NAME, Color(1, 1, 1, 0.55))
	var ol := Pen.wrap(_pick(tasting.order), cw - 24.0, T_LINE)
	for i in mini(ol.size(), 2):
		p.text(ol[i], x + 12, ry + 7.5 + i * 9.0, T_LINE, Color.WHITE)
	# the grade: a red stamp roundel slamming in
	ry = y + 76.0 + maxf(0.0, 8.0 - (t - 0.27) * 60.0)
	p.text(_w("card_grade"), x + 12, ry, T_NAME, Color(1, 1, 1, 0.55))
	var st := clampf((t - 0.35) / 0.12, 0.0, 1.0)
	if st > 0.0:
		var sk := lerpf(2.2, 1.0, Pen.ease_out(st))
		var sc := Vector2(x + cw * 0.62, ry + 14.0)
		var sr := 24.0 * sk
		p.line(Pen.ell_pts(sc, Vector2(sr, sr * 0.84), -0.2, 28), 1.8, Color("#e0263a", 0.95))
		p.line(Pen.ell_pts(sc, Vector2(sr * 0.86, sr * 0.7), -0.2, 28), 0.6, Color("#e0263a", 0.8))
		p.text(tasting.board_text(), sc.x, sc.y - 12.0 * sk, 17.0 * sk, Color("#ff5a6a"), 0, 0.0, -0.2)
		p.text("/ 10", sc.x + 2.0 * sk, sc.y + 6.5 * sk, 6.0 * sk, Color("#ff5a6a"), 0, 0.0, -0.2)
		if st < 1.0:
			p.line(Pen.ell_pts(sc, Vector2(sr * 1.4, sr * 0.6), 0.0, 20), 0.6, Color(1, 1, 1, 0.3 * (1.0 - st)))
	# the badge: a gold medal on a ribbon, swinging
	if not tasting.badge.is_empty():
		var by := y + ch - 54.0
		var swing := sin(t * 4.0) * 0.3 * exp(-t * 0.9)
		var top := Vector2(x + 24, by)
		var m := top + Vector2(sin(swing) * 13.0, cos(swing) * 13.0)
		p.poly(PackedVector2Array([top + Vector2(-5, 0), top + Vector2(5, 0), m + Vector2(3, -3), m + Vector2(-3, -3)]), Color("#e0263a"))
		p.ball(m, Vector2(7, 7), GOLD, GOLD_D, Color("#fff2b0"))
		p.poly(Pen.star_pts(m, Vector2(3.6, 3.6), Vector2(1.5, 1.5), 5, -PI * 0.5), Color("#7a4a10"))
		p.text(_w("card_badge"), x + 40, by + 2, T_NAME, Color(1, 1, 1, 0.55))
		p.text(_pick(tasting.badge), x + 40, by + 10, T_LINE, GOLD)
	p.text(_w("card_game"), x + cw * 0.5, y + ch - 27, T_NAME, Color(1, 1, 1, 0.7), 0)
	if t >= Tasting.CARD_S:
		var bw := 84.0
		var bx := x + cw * 0.5 - bw * 0.5
		p.rrect(bx, y + ch - 19, bw, 13, 6.5, GOLD)
		p.text(_w("btn_next"), bx + bw * 0.5, y + ch - 17, T_LINE, INK, 0)
	else:
		var bar := cw - 40.0
		p.text(_w("card_shot"), x + cw * 0.5, y + ch - 19, T_NAME, Color(1, 1, 1, 0.55), 0)
		p.rrect(x + 20, y + ch - 10, bar, 2.4, 1.2, Color(1, 1, 1, 0.15))
		p.rrect(x + 20, y + ch - 10, maxf(2.4, bar * clampf(t / Tasting.CARD_S, 0.0, 1.0)), 2.4, 1.2, GOLD)
	# the selfie print, taped over the card's right edge
	var pk := Pen.pop((t - 0.2) / 0.4, 1.06)
	var pc := Vector2(x + cw + 52.0, y + ch * 0.46 - drop * 0.5)
	_print(p, pc, 92.0 * pk, 0.09)
	if pk > 0.9:
		p.poly(_rot_rect(pc + Vector2(0, -92.0 * 1.2 * 0.5).rotated(0.09), Vector2(26, 7), 0.09 - 0.25), Color("#fff2b0", 0.7))


## A damped spring from 1 to 0 (the card's drop with one overshoot).
func _spring(t: float) -> float:
	return exp(-t * 7.0) * cos(t * 14.0)


## Zbyszek's viewfinder opening: the black frame drawing back, the corners sliding out, the focus.
func _viewfinder(p: Pen) -> void:
	var m := 1.0 - Pen.ease_in_out(tasting.t / Tasting.IN_S)
	p.rect(0, 0, W, H * 0.5 * m, Color.BLACK)
	p.rect(0, H - H * 0.5 * m, W, H * 0.5 * m, Color.BLACK)
	p.rect(0, 0, W * 0.3 * m, H, Color(0, 0, 0, m))
	p.rect(W - W * 0.3 * m, 0, W * 0.3 * m, H, Color(0, 0, 0, m))
	var inset := m * 50.0 + 12.0
	var c := Color(1, 1, 1, 0.9)
	for q: Array in [[inset, inset, 1, 1], [W - inset, inset, -1, 1], [inset, H - inset, 1, -1], [W - inset, H - inset, -1, -1]]:
		var x: float = q[0]
		var y: float = q[1]
		var sx: int = q[2]
		var sy: int = q[3]
		p.line(PackedVector2Array([Vector2(x, y + sy * 14), Vector2(x, y), Vector2(x + sx * 14, y)]), 1.2, c)
	var fr := 10.0 + m * 30.0
	p.line(Pen.ell_pts(Vector2(W * 0.5, H * 0.5), Vector2(fr, fr), 0.0, 24), 0.8, Color(1, 1, 1, 0.6 * m))


func _grow(r: Rect2) -> Rect2:
	var m := _touch_px()
	var g := r
	if g.size.x < m:
		g = g.grow_individual((m - g.size.x) * 0.5, 0, (m - g.size.x) * 0.5, 0)
	if g.size.y < m:
		g = g.grow_individual(0, (m - g.size.y) * 0.5, 0, (m - g.size.y) * 0.5)
	return g


# --- the crowd's floaters and the confetti -----------------------------------------------------------

func _rise(n: int) -> void:
	for i in n:
		if _floaters.size() >= 12:
			_floaters.pop_front()
		_floaters.append({"x": _rng.randf_range(-14.0, 0.0), "t": -float(i) * 0.12, "kind": _rng.randi_range(0, 2), "wob": _rng.randf() * TAU})


func _confetti() -> void:
	if Access.calm:
		return
	for i in 40:
		var a := _rng.randf_range(-PI, 0.0)
		_bits.append({"p": Vector2(W * 0.2, 60.0), "v": Vector2(cos(a), sin(a)) * _rng.randf_range(40.0, 120.0), "t": 0.0,
				"c": [GOLD, RED, Color("#1ae6ff"), Color.WHITE][i % 4], "r": _rng.randf() * TAU})


func _particles(dt: float) -> void:
	for f: Dictionary in _floaters:
		f["t"] = float(f["t"]) + dt
	while not _floaters.is_empty() and float((_floaters[0] as Dictionary)["t"]) > 1.6:
		_floaters.pop_front()
	for b: Dictionary in _bits:
		b["t"] = float(b["t"]) + dt
		b["v"] = (b["v"] as Vector2) + Vector2(0, 160.0) * dt
		b["p"] = (b["p"] as Vector2) + (b["v"] as Vector2) * dt
		b["r"] = float(b["r"]) + dt * 8.0
	while not _bits.is_empty() and float((_bits[0] as Dictionary)["t"]) > 2.0:
		_bits.pop_front()


func _floaters_draw(p: Pen, right: float) -> void:
	for f: Dictionary in _floaters:
		var t: float = f["t"]
		if t < 0.0:
			continue
		var u := Pen.ease_out(t / 1.4)
		var pos := Vector2(right - 12.0 + float(f["x"]) + sin(t * 5.0 + float(f["wob"])) * 3.0, H - 30.0 - u * 110.0)
		var a := 1.0 - clampf((t - 0.9) / 0.6, 0.0, 1.0)
		var s := 1.0 + 0.2 * sin(t * 10.0)
		if int(f["kind"]) < 2:
			var hc := RED if int(f["kind"]) == 0 else Color("#ff7ab8")
			p.ell(pos + Vector2(-1.6, -0.6) * s, Vector2(2.2, 2.2) * s, Color(hc, a), 0.0, 10)
			p.ell(pos + Vector2(1.6, -0.6) * s, Vector2(2.2, 2.2) * s, Color(hc, a), 0.0, 10)
			p.poly(PackedVector2Array([pos + Vector2(-3.7, 0) * s, pos + Vector2(3.7, 0) * s, pos + Vector2(0, 4.2) * s]), Color(hc, a))
		else:
			p.poly(PackedVector2Array([pos + Vector2(-1.6, 3.4), pos + Vector2(1.6, 3.4), pos + Vector2(3.0, -2.6), pos + Vector2(-3.0, -2.6)]), Color(TORTILLA[0], a))
			p.ell(pos + Vector2(0, -2.6), Vector2(3.0, 1.2), Color(MEAT, a), 0.0, 10)


func _bits_draw(p: Pen) -> void:
	for b: Dictionary in _bits:
		var a := 1.0 - clampf((float(b["t"]) - 1.4) / 0.6, 0.0, 1.0)
		p.poly(_rot_rect(b["p"], Vector2(2.6, 1.4), float(b["r"])), Color(b["c"], a))
