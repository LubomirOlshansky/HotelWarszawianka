extends Node
## The tasting at the Palm, drawn as Zbyszek's livestream (palm_tasting.gd's rules; plan doc "First
## 10 minutes: Tajny klient", "The river scene and the viral moment", moved to the Palm at Rondo de
## Gaulle'a by F): full screen in the pixel kit's look, the city's 3D off while it is up
## (GameCtx.city_drawn), like the kebab stand and beer pong.
##
## The look (F 2026-11-26 20:36: "use our first version but make more details, more pixels, like
## more detailed but not realistic"): the first version's composition, palette and staging, drawn
## as crisp axis-aligned rects in flat colours, now at twice the pixels. Every coordinate is on the
## first version's 216-unit grid; the scene's viewport draws 432 rows (canvas scale 2), so detail
## lives at half a unit = one pixel. No ellipses, rotations, gradients, shaders or smooth fonts:
## shading is two or three flat tones per material as rect bands, one key light from screen-left.
##   - the back (drawn once a size, its draw list kept): golden-hour bands, the sun behind the Party
##     House, the Party House's colonnade, Nowy Świat's fronts (cornices, framed windows, awnings,
##     shop signs, AC boxes, geraniums, a balcony, chimneys, a dish, an aerial), the lamps, the road
##     with its rails and dashes, kerb stones, slabs, bollards, a bin and a hydrant;
##   - the live layer: cars both ways and a tram every TRAM_S, the Palm with its ringed trunk and
##     swaying fronds, the Porsza, a pigeon, and the people: the player, Kebabulo, Zbyszek with his
##     gimbal, the fan for the photo. They are ~1.4x the first version's, each with a 1 px dark
##     outline, faces with eyes, catch-lights, brows, a nose, mouths that talk by the line's vowels,
##     chew and react, blinks and a 1 px breath; a pose per beat and per grade, held, hard cuts;
##   - the fx layer: the comic close-up for the bite (his big face at 2x), the MLASK as a full comic
##     panel (F 20:37, concept 3 "TRZY KADRY": gold rays, the giant word, his face rising, insets of
##     Zbyszek, the pigeon and the chat), the hearts and little kebabs, the 11/10 confetti.
## Kebabulo (F 20:38): a cartoon archetype, no portrait: short neat hair, a short trimmed beard and
## moustache, a plain black cap worn forward, a beige hoodie with the hood down behind the neck, a
## black puffer vest, light skin, the big open grin; slim. He shows three wraps at the hello.
## The stream's own layer (its own 216-row viewport, the kit's 5x7 font, the first version's style):
## the REC corners, NA ŻYWO and the viewers with a "+N", three chat lines bottom left, the speaker's
## line bottom right, hold-× to skip, the scoreboard, the selfie's flash, the RECENZJA card; the
## instant print rides over it at the scene's pixels.
##
## Touch: a tap anywhere advances, a hold on the skip chip skips. Keys for the Mac: Space or Enter
## a tap, Esc held the skip. Access.calm: no shake, no slam, a soft warm flash.
##
## Cost: while it is up the city's 3D is off; the frame is a 432-row and a 216-row canvas of flat
## rects (the back's ~3,300 replayed from its kept draw list; ~3,000 drawn a frame for the live
## layer, the people with their outlines and the stream's layer, up to ~5,000 under the MLASK's
## rays); closed, both viewports are off (UPDATE_DISABLED), so nothing runs.

const Tasting := preload("res://scripts/palm_tasting.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Access := preload("res://scripts/access.gd")

## The grid: 216 units high, at least MIN_W wide; the scene draws PX pixels a unit.
const H := 216
const MIN_W := 384
const PX := 2
const HORIZON := 78.0
const ROAD_Y := 112.0
const PAVE_Y := 146.0
const FEET := 196.0
const TRAM_S := 12.0
const WIPE_S := 0.45
const BLOCK := 12.0
const TOUCH_PT := 44.0
## The MLASK panel (Fable's critique, section 2 row 2): his face's scale (scene px a face px; 2.0 in
## the close-up), its forehead's row when it has risen (units: the cap over the word's lower third),
## and the row the insets and the chat stand on, above the caption strip.
const MLASK_FACE := 2.8
const MLASK_TOP := 100.0
const MLASK_LOW := 176.0

# --- the palette (the first version's family; shades as [base, shade, light]) ---
const SKY := [Color("#5f6694"), Color("#7c6f98"), Color("#a87892"), Color("#d08680"), Color("#ec9c68"), Color("#f4b866"), Color("#f8d488")]
const SUN := Color("#fff4cc")
const SUN_GLOW := Color("#ffe39a")
const STONE := Color("#d8cdb6")
const STONE_D := Color("#b3a68c")
const STONE_L := Color("#ece4d0")
const STONE_DD := Color("#8f846e")
const BAY := Color("#4c4a52")
const GLASS := Color("#4e5266")
const GLASS_L := Color("#7a7c96")
const GLOW := Color("#f2c97a")
const ASPHALT := Color("#45464c")
const ASPHALT_L := Color("#56585e")
const ASPHALT_D := Color("#3a3b40")
const RAIL := Color("#c9d2d8")
const KERB := Color("#a2a2a8")
const KERB_L := Color("#c4c4ca")
const KERB_D := Color("#6a6a72")
const PAVE := Color("#9a958c")
const PAVE_D := Color("#86817a")
const PAVE_L := Color("#a8a399")
const TRUNK := [Color("#8a6a48"), Color("#6a4e34"), Color("#a8845a")]
const TRUNK_RING := Color("#523a26")
const FROND := [Color("#3f9a4a"), Color("#2c7238"), Color("#6cc04a")]
const GRASS := [Color("#4a8a3e"), Color("#3a6e32"), Color("#6aa84e")]
const TRAM_R := Color("#c8302a")
const TRAM_RD := Color("#9a2020")
const TRAM_Y := Color("#f2c230")
## Kebabulo's Porsza: gunmetal paint (lit top, light, mid, low side, sill), the glass, the calipers.
const P911 := [Color("#d4dae2"), Color("#a3abb6"), Color("#838b97"), Color("#626a75"), Color("#3c4048")]
const GLASS911 := [Color("#28303a"), Color("#4a5866"), Color("#8ea4b8")]
const P911_CALIPER := Color("#f2c230")
const PIGEON := [Color("#8a8f9a"), Color("#5e6270"), Color("#b4b8c4")]
const OUT := Color("#2a1f3d")
const INK := Color("#16191d")
const WHITE := Color("#fbfaf6")
const RED := Color("#d4282e")
const RED_L := Color("#ee5a5a")
const GOLD := Color("#ffd23a")
const AMBER := Color("#ffb020")
const CYAN := Color("#1ae6ff")
const BLUSH := Color("#f08a78")
const MOUTH := Color("#5a1e1a")
const TONGUE := Color("#d9605a")
const TEETH := Color("#fbf6ec")
const SWEAT := Color("#8ad8f8")
# the people
const SKIN_LIGHT := [Color("#f1c8a4"), Color("#d9a984"), Color("#ffdcc0")]
const SKIN_MID := [Color("#e2b08a"), Color("#c48d68"), Color("#f1c8a4")]
const SKIN_FAIR := [Color("#f6d4b4"), Color("#dcae8e"), Color("#fff0dc")]
const HOODIE := [Color("#d8c09a"), Color("#b39a74"), Color("#ecdcb8")]
const VEST := [Color("#24232b"), Color("#141319"), Color("#45444f")]
const BLACK_PANTS := [Color("#24232b"), Color("#16151b"), Color("#383744")]
const CAP := [Color("#1e1d24"), Color("#0f0e14"), Color("#3e3d4a")]
const BEARD := Color("#5a3e2a")
const BEARD_L := Color("#7a5a40")
## His short neat hair, a shade lighter than the beard.
const HAIR_K := Color("#6a4a30")
const TEAL := [Color("#1f9cb8"), Color("#137089"), Color("#49cce4")]
const JEANS := [Color("#34466e"), Color("#232f4c"), Color("#4d6492")]
const CHARCOAL := [Color("#4e5260"), Color("#373a45"), Color("#6c7182")]
const DARK_JEANS := [Color("#2a3040"), Color("#1a1e2a"), Color("#3c4458")]
const PUFFER := [Color("#d8457a"), Color("#9c2c5c"), Color("#f47aa6")]
const LIGHT_JEANS := [Color("#7f9ac0"), Color("#5a7298"), Color("#a4bcdc")]
const MUSTARD := [Color("#e8b23a"), Color("#b8862a"), Color("#f8d070")]
const TRAINER := Color("#f4f1e6")
const SOLE_L := Color("#c9c4b8")
const SOLE_D := Color("#2a2630")
# the kebab
const FOIL := [Color("#c9d2d8"), Color("#8f9aa4"), Color("#eef4f8")]
const WRAP := [Color("#ecd8a4"), Color("#c9a86c"), Color("#fff0c8")]
const MEAT := Color("#9a4a24")
const LETTUCE := Color("#6cc04a")
const TOMATO := Color("#e0402a")
const SAUCE := Color("#fff8ec")
const KRAFT := [Color("#c8a06a"), Color("#a07a48"), Color("#dcbc88")]
## The bun (the default dish, F's "buła taka nie za sucha"): crust, shade, the lit top; and its napkin.
const BUN := [Color("#e0a556"), Color("#b87a34"), Color("#f6cb84")]
const PAPER := [Color("#f2eee6"), Color("#cfc8ba"), Color("#ffffff")]
const NICKS := [Kit.GO, CYAN, GOLD, Color("#ff7ab8"), Color("#ffa35c")]

## The floaters' sprites: a heart and a little kebab, a "#" a lit pixel.
const HEART := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
const MINI_KEBAB := ["..##.", ".####", "#####", "#####", "#####", ".###.", ".###."]
## The open-mouth letters, Polish ones as escapes (a code table, not on-screen text).
const VOWELS := "aeiouy\u0105\u0119\u00f3"

signal finished(result: Dictionary)

var tasting: Tasting
var pt := 1.0
var auto_play := false
var log_on := false
var inside := false
## Plays a short sound by name (the owner's hud.cue): "tick", "win", "mlask", "drumroll", "voice_*".
var cue := Callable()
var W := MIN_W
## Rects drawn this frame (or counted by `dry_frame`): the scene's per-frame budget for the check.
var rects := 0

var _layer: CanvasLayer
var _bg: ColorRect
var _vp: SubViewport
var _ui_vp: SubViewport
var _world: Node2D
var _back: Node2D
var _live_n: Node2D
var _fx: Node2D
var _ui: Node2D
var _over: Node2D
var _tex: TextureRect
var _ui_tex: TextureRect
var _ui_pen: Kit
var _t := 0.0
var _wipe := 0.0
var _leaving := false
var _skip_held := false
var _key_skip := false
var _last_phase := -1
var _last_said := ""
var _shake := 0.0
var _skip_rect := Rect2()
## The viewer count as drawn (it rolls toward the real one) and the last jump's "+N".
var _shown_viewers := 0.0
var _plus := 0
var _plus_t := 9.0
## Hearts and little kebabs rising up the right edge: {x, t, kind}.
var _floaters: Array = []
## The 11/10's confetti: {p, v, t, c}.
var _bits: Array = []
var _rng := RandomNumberGenerator.new()
## The fan's x in units (walks in from the right).
var _fan_x := 600.0

# The pen: rects in scene pixels (432-row grid) onto `_ci`; `_kd` target px a scene px, `_offd` the
# target origin, `_dinv` draw units a target px (0.5 in the viewport, whose canvas is scaled 2).
var _ci: CanvasItem
var _kd := 1.0
var _offd := Vector2.ZERO
var _dinv := 0.5
var _dry := false
# The figure frame: origin in scene px, facing (+1 right), scene px a local px; and the outline
# buffer (rects of one figure, outlined as one silhouette).
var _org := Vector2.ZERO
var _f := 1
var _sc := 1.0
var _buffering := false
var _buf: Array = []
var _ol_on := true


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
	_floaters.clear()
	_bits.clear()
	_rng.seed = 7
	_shown_viewers = float(tasting.viewers)
	_plus_t = 9.0
	inside = true
	_layer.visible = true
	_live(true)
	_resize()
	_fan_x = W + 30.0
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
	return shown(Lang.pick(str(p[0]), str(p[1])))


func _pick(l: Array) -> String:
	return shown(Lang.pick(str(l[0]), str(l[1]))) if l.size() >= 2 else ""


## A line as the kit's 5x7 font draws it (it has no ellipsis glyph).
static func shown(s: String) -> String:
	return s.replace("…", "...")


# --- building -----------------------------------------------------------------------------------

func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)
	_bg = ColorRect.new()
	_bg.color = Kit.VOID
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_bg)
	# The scene: 432 rows, the canvas scaled 2 so the grid stays in units.
	_vp = _viewport(false)
	_world = Node2D.new()
	_vp.add_child(_world)
	_back = Node2D.new()
	_back.draw.connect(_draw_back)
	_world.add_child(_back)
	_live_n = Node2D.new()
	_live_n.draw.connect(_draw_live)
	_world.add_child(_live_n)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	_vp.add_child(_fx)
	# The stream's layer: 216 rows, the kit's pen at one unit.
	_ui_vp = _viewport(true)
	_ui = Node2D.new()
	_ui.draw.connect(_draw_ui)
	_ui_vp.add_child(_ui)
	_ui_pen = Kit.new(_ui)
	_tex = _shown(_vp)
	_ui_tex = _shown(_ui_vp)
	# The instant print over the card, at the scene's pixels, straight on the screen.
	_over = Node2D.new()
	_over.draw.connect(_draw_over)
	_layer.add_child(_over)
	_layer.visible = false
	if is_inside_tree():
		get_viewport().size_changed.connect(_resize)


func _viewport(transparent: bool) -> SubViewport:
	var v := SubViewport.new()
	v.size = Vector2i(MIN_W, H)
	v.disable_3d = true
	v.transparent_bg = transparent
	v.msaa_2d = Viewport.MSAA_DISABLED
	v.snap_2d_transforms_to_pixel = true
	v.snap_2d_vertices_to_pixel = true
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(v)
	return v


func _shown(v: SubViewport) -> TextureRect:
	var r := TextureRect.new()
	r.texture = v.get_texture()
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(r)
	return r


## The two viewports render only while the scene is up (closed, they cost nothing).
func _live(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	_vp.render_target_update_mode = mode
	_ui_vp.render_target_update_mode = mode


func _resize() -> void:
	if _vp == null or not is_inside_tree():
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W * PX, H * PX)
	_vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(PX, PX))
	_ui_vp.size = Vector2i(W, H)
	_back.queue_redraw()
	pt = float(ScreenPoints.measure(s)["pt"])


## Screen px a unit (the canvas fits the screen; a screen narrower than MIN_W gets bars).
func _scale() -> float:
	var s := get_viewport().get_visible_rect().size
	return minf(s.x / float(W), s.y / float(H))


## The canvas's top left on the screen.
func _origin() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	var k := _scale()
	return ((s - Vector2(W, H) * k) * 0.5).floor()


func _to_canvas(p: Vector2) -> Vector2:
	return (p - _origin()) / _scale()


func _safe_canvas() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var s := get_viewport().get_visible_rect().size
	var safe: Rect2 = ScreenPoints.measure(s)["safe"]
	var k := _scale()
	var o := _origin()
	return Vector2(maxf(0.0, (safe.position.x - o.x) / k), maxf(0.0, (s.x - safe.end.x - o.x) / k))


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
	_plus_t += dt
	_shown_viewers = lerpf(_shown_viewers, float(tasting.viewers), 1.0 - exp(-dt * 4.0))
	_fan_tick(dt)
	_particles(dt)
	var off := Vector2.ZERO
	if _shake > 0.0 and not Access.calm:
		off = Vector2(roundf(sin(_t * 71.0) * 2.0), roundf(cos(_t * 53.0) * 1.5))
	_world.position = off
	_fx.position = off if tasting.phase == Tasting.Phase.MLASK else Vector2.ZERO
	_live_n.queue_redraw()
	_fx.queue_redraw()
	_ui.queue_redraw()
	_over.queue_redraw()


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
			_cue("mlask")
			Access.buzz(120, 1.0)
		Tasting.Phase.VERDICT:
			_rise(6)  # the hearts come on the cut back, not in the panel
		Tasting.Phase.DRUM:
			_cue("drumroll")
		Tasting.Phase.GRADE:
			_shake = 0.45 if tasting.perfect else 0.0
			if tasting.perfect:
				_cue("win")
				_confetti()
			Access.buzz(200, 1.0)
			_rise(10 if tasting.perfect else 4)
			_log("grade %s" % tasting.grade_label)
		Tasting.Phase.FAN:
			_fan_x = W + 30.0
			_log("fan")
		Tasting.Phase.SELFIE:
			_rise(5)
			_log("selfie")
		Tasting.Phase.CARD:
			_log("card%s" % (" (skipped)" if tasting.skipped else ""))
	if tasting.viewers > int(_shown_viewers) + 30:
		_plus = tasting.viewers - int(_shown_viewers)
		_plus_t = 0.0


func _fan_tick(dt: float) -> void:
	var ph := tasting.phase
	if ph == Tasting.Phase.FAN or ph == Tasting.Phase.SELFIE:
		# a steady walk, whole pixels (no easing: a held pose when she arrives)
		var goal := _fan_goal()
		_fan_x = maxf(goal, _fan_x - dt * 70.0)
	elif ph == Tasting.Phase.CARD:
		_fan_x += dt * 60.0


func _fan_goal() -> float:
	return _kebabulo_x() + (30.0 if tasting.phase == Tasting.Phase.SELFIE else 38.0)


## Draws one whole frame with no canvas, counting the rects (the check walks every beat with it).
func dry_frame() -> int:
	_dry = true
	rects = 0
	var ci := _ui_pen.ci
	_ui_pen.ci = null
	_ui_pen.rects = 0
	_draw_back()
	_draw_live()
	_draw_fx()
	_draw_ui()
	_draw_over()
	_ui_pen.ci = ci
	_dry = false
	return rects + _ui_pen.rects


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


# --- the pen --------------------------------------------------------------------------------------

## Draws on `node` in the scene's viewport from here on (no canvas in a dry frame).
func _use(node: CanvasItem) -> void:
	_ci = null if _dry else node
	_kd = 1.0
	_offd = Vector2.ZERO
	_dinv = 1.0 / PX


## A rect in scene pixels, snapped to whole target pixels (or into the figure's buffer).
func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if w <= 0.0 or h <= 0.0 or c.a <= 0.0:
		return
	if _buffering:
		_buf.append([x, y, w, h, c, _ol_on])
		return
	rects += 1
	if _ci == null:
		return
	var x0 := roundf(_offd.x + roundf(x) * _kd)
	var y0 := roundf(_offd.y + roundf(y) * _kd)
	var x1 := roundf(_offd.x + roundf(x + w) * _kd)
	var y1 := roundf(_offd.y + roundf(y + h) * _kd)
	_ci.draw_rect(Rect2(x0 * _dinv, y0 * _dinv, maxf(1.0, x1 - x0) * _dinv, maxf(1.0, y1 - y0) * _dinv), c)


## A rect in grid units (half units are single pixels).
func _u(x: float, y: float, w: float, h: float, c: Color) -> void:
	_r(roundf(x * PX), roundf(y * PX), roundf((x + w) * PX) - roundf(x * PX), roundf((y + h) * PX) - roundf(y * PX), c)


## A filled pixel disc in units (rows of half a unit), for wheels, the sun, the island.
func _disc(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var n := int(ceil(ry * PX))
	for k in range(-n, n):
		var t := (float(k) + 0.5) / (ry * PX)
		if absf(t) > 1.0:
			continue
		var hw := roundf(rx * sqrt(1.0 - t * t) * PX) / PX
		_u(cx - hw, cy + float(k) / PX, hw * 2.0, 1.0 / PX, c)


## Starts a figure at (x, y) in units, facing `f`, `s` scene px a local px; its rects are buffered.
func _fig(x: float, y: float, f: int, s := 1.0) -> void:
	_org = Vector2(roundf(x * PX), roundf(y * PX))
	_f = f
	_sc = s
	_buffering = true
	_ol_on = true
	_buf.clear()


## A rect in the figure's local px, mirrored when it faces left.
func _q(x: float, y: float, w: float, h: float, c: Color) -> void:
	var lx := x if _f > 0 else -x - w
	_r(_org.x + lx * _sc, _org.y + y * _sc, w * _sc, h * _sc, c)


## A rect in the figure's px, screen-relative (not mirrored): the light falls from screen-left.
func _qs(x: float, y: float, w: float, h: float, c: Color) -> void:
	_r(_org.x + x * _sc, _org.y + y * _sc, w * _sc, h * _sc, c)


## A local x span as screen-relative x (its left edge on screen).
func _sx(lx: float, w: float) -> float:
	return lx if _f > 0 else -lx - w


## A shaded box: the base, a shade band on its screen-right, a lit edge on its screen-left.
func _band(lx: float, y: float, w: float, h: float, c: Array, shade := 3.0, lit := 1.0) -> void:
	_q(lx, y, w, h, c[0])
	var s := _sx(lx, w)
	_qs(s + w - shade, y, shade, h, c[1])
	if lit > 0.0:
		_qs(s, y, lit, h, c[2])


## Details inside the silhouette: no outline of their own.
func _detail(on: bool) -> void:
	_ol_on = not on


## Ends the figure: the silhouette's outline (`e` px out), then the fills in order.
func _flush(ol: Color, e := 1.0) -> void:
	_buffering = false
	var b := _buf
	_buf = []
	for q: Array in b:
		if bool(q[5]):
			_r(float(q[0]) - e, float(q[1]) - e, float(q[2]) + e * 2.0, float(q[3]) + e * 2.0, ol)
	for q: Array in b:
		_r(float(q[0]), float(q[1]), float(q[2]), float(q[3]), q[4])


static func _hash(i: int) -> int:
	var h := (i * 73856093) ^ (i * 19349663 >> 3)
	return absi(h) % 1000


## An overshooting 0 to 1 (the slams), held at 1.
static func _pop(k: float, over := 1.7) -> float:
	var x := clampf(k, 0.0, 1.0) - 1.0
	return 1.0 + (over + 1.0) * x * x * x + over * x * x


# --- where things stand -------------------------------------------------------------------------

func _palm_x() -> float:
	return roundf(W * 0.40)


func _you_x() -> float:
	return roundf(W * 0.47)


func _kebabulo_x() -> float:
	return roundf(W * 0.60)


func _zbyszek_x() -> float:
	return W - 28.0


# --- the back (drawn once a size) -----------------------------------------------------------------

func _draw_back() -> void:
	_use(_back)
	_sky()
	_party_house()
	_nowy_swiat()
	_lamps()
	_road_bed()
	_pavement()
	_props()


func _sky() -> void:
	var stops := [0.0, 14.0, 27.0, 39.0, 50.0, 60.0, 69.0, ROAD_Y]
	for i in SKY.size():
		_u(0, stops[i], W, float(stops[i + 1]) - float(stops[i]), SKY[i])
		# a one-pixel seam of the next band's colour every few pixels: a hand-dithered edge
		if i + 1 < SKY.size():
			var x := float(i * 3 % 5)
			while x < W:
				_u(x, float(stops[i + 1]) - 0.5, 2.0, 0.5, SKY[i + 1])
				x += 5.0
	# the sun low behind the Party House, its glow in two steps
	var sx := roundf(W * 0.30)
	_disc(sx, 30, 17, 15, Color("#f8c878"))
	_disc(sx, 30, 13, 11.5, SUN_GLOW)
	_disc(sx, 30, 9.5, 8.5, SUN)
	# clouds: stacked strips, a warm underside
	for c: Array in [[0.08, 16.0, 40.0], [0.52, 24.0, 52.0], [0.78, 12.0, 30.0]]:
		var cx := roundf(W * float(c[0]))
		var cy: float = c[1]
		var cw: float = c[2]
		_u(cx + cw * 0.2, cy - 2, cw * 0.4, 1, Color("#ffe8d0"))
		_u(cx + cw * 0.1, cy - 1, cw * 0.7, 1, Color("#ffe8d0"))
		_u(cx, cy, cw, 1.5, Color("#fbd6b8"))
		_u(cx + 2, cy + 1.5, cw - 4, 0.5, Color("#e8a090"))
	# far birds
	for b: Array in [[0.62, 18.0], [0.66, 15.0], [0.70, 20.0]]:
		var bx := roundf(W * float(b[0]))
		_u(bx, b[1], 1, 0.5, Color("#5a4a6a"))
		_u(bx + 1.5, b[1], 1, 0.5, Color("#5a4a6a"))
		_u(bx + 1, float(b[1]) + 0.5, 0.5, 0.5, Color("#5a4a6a"))


## The old Party House on the corner: a long pale block, five rows of framed windows over a tall
## colonnade, the flag on the roof.
func _party_house() -> void:
	var x0 := -2.0
	var x1 := roundf(W * 0.40)
	var w := x1 - x0
	var top := 34.0
	_u(x0, top, w, ROAD_Y - top, STONE)
	# the roof: a parapet, a plant room, the flagpole
	_u(x0 + 24, top - 5, 34, 5, STONE_D)
	_u(x0 + 24, top - 5, 34, 0.5, STONE_L)
	_u(x0 + 26, top - 3.5, 30, 0.5, STONE_DD)
	_u(x0, top - 1.5, w, 1.5, STONE_L)
	_u(x0, top, w, 1, STONE_D)
	_u(x0, top + 2, w, 1, STONE_L)
	_u(x0, top + 3, w, 0.5, STONE_DD)
	var fx := x1 - 22.0
	_u(fx, top - 16, 0.5, 14.5, Color("#3a3a44"))
	_u(fx + 0.5, top - 16, 7, 2, WHITE)
	_u(fx + 0.5, top - 14, 7, 2, Color("#d4283a"))
	_u(fx + 6.5, top - 16, 0.5, 4, Color("#e8e0d8"))
	# the windows: framed, a sill, the cross, the sunset caught in the top pane
	var cy := top + 47.0
	for r in 4:
		var y := top + 6.0 + r * 9.5
		var x := x0 + 5.0
		var i := 0
		while x < x1 - 6.0:
			var lit := _hash(i * 7 + r * 31) % 9 == 0
			_u(x - 0.5, y - 0.5, 5, 7, STONE_D)
			_u(x, y, 4, 6, GLOW if lit else GLASS)
			_u(x, y, 4, 1.5, Color("#e8b070") if not lit else Color("#ffe39a"))
			_u(x + 1.5, y, 0.5, 6, STONE_L)
			_u(x, y + 2.5, 4, 0.5, STONE_L)
			_u(x - 1, y + 6, 6, 0.5, STONE_L)
			_u(x - 1, y + 6.5, 6, 0.5, STONE_DD)
			if not lit and _hash(i * 11 + r) % 5 == 0:
				_u(x + 2, y + 3, 2, 3, Color("#8a7a8a"))
			x += 8.0
			i += 1
	# pilasters every four bays
	var px := x0 + 2.5
	while px < x1 - 4.0:
		_u(px, top + 4, 1, cy - top - 7, STONE_L)
		_u(px + 1, top + 4, 0.5, cy - top - 7, STONE_D)
		px += 32.0
	# the colonnade: the entablature, the dark bays with shop light, the square pillars
	_u(x0, cy - 3, w, 3, STONE)
	_u(x0, cy - 3, w, 0.5, STONE_L)
	_u(x0, cy - 0.5, w, 0.5, STONE_DD)
	_u(x0, cy, w, ROAD_Y - cy, BAY)
	_u(x0, cy, w, 1.5, Color("#38363e"))
	var bx := x0 + 10.0
	var k := 0
	while bx < x1 - 6.0:
		if _hash(k * 5 + 3) % 3 == 0:
			_u(bx, cy + 10, 6, 14, Color("#d8a060"))
			_u(bx, cy + 10, 6, 1, Color("#f2c97a"))
			_u(bx + 2.5, cy + 10, 0.5, 14, Color("#8a6040"))
		else:
			_u(bx, cy + 10, 6, 14, Color("#3a3842"))
			_u(bx + 0.5, cy + 10.5, 5, 0.5, Color("#5a5866"))
		bx += 13.0
		k += 1
	var x := x0 + 3.0
	while x < x1 - 3.0:
		_u(x - 1, cy, 8, 1.5, STONE_L)
		_u(x - 1, cy + 1.5, 8, 0.5, STONE_DD)
		_u(x, cy + 2, 6, ROAD_Y - cy - 4, STONE)
		_u(x, cy + 2, 1, ROAD_Y - cy - 4, STONE_L)
		_u(x + 4.5, cy + 2, 1.5, ROAD_Y - cy - 4, STONE_D)
		_u(x + 2.5, cy + 3, 0.5, ROAD_Y - cy - 6, STONE_D)
		_u(x - 1, ROAD_Y - 2.5, 8, 2.5, STONE_D)
		_u(x - 1, ROAD_Y - 2.5, 8, 0.5, STONE_L)
		x += 13.0
	_u(x1 - 1, top, 1, ROAD_Y - top, STONE_DD)


## Nowy Świat's low pastel fronts: roofs, cornices, framed windows, shop signs and awnings.
func _nowy_swiat() -> void:
	var cols := [Color("#e8c9a0"), Color("#d6b6c4"), Color("#c9d4b0"), Color("#ead79c"), Color("#d8bca8")]
	var signs := [Color("#2e5a3a"), Color("#7a2a34"), Color("#2a3a6a"), Color("#5a3a20"), Color("#3a3a44")]
	var awn := [Color("#c8302a"), Color("#2e7a4a"), Color("#e8a020"), Color("#2a5aa8"), Color("#a8306a")]
	var x := roundf(W * 0.40)
	var i := 0
	while x < W:
		var w := 38.0 + float((i * 13) % 14)
		var top := 46.0 + float((i * 7) % 12)
		var c: Color = cols[i % cols.size()]
		var d := c.darkened(0.14)
		var l := c.lightened(0.14)
		_u(x, top, w, ROAD_Y - top, c)
		_u(x, top, 1, ROAD_Y - top, l)
		_u(x + w - 1.5, top, 1.5, ROAD_Y - top, d)
		# the roof and the cornice
		var roof := Color("#8a5040") if i % 2 == 0 else Color("#5e6070")
		_u(x - 0.5, top - 2, w + 1, 2, roof)
		_u(x - 0.5, top - 2, w + 1, 0.5, roof.lightened(0.25))
		_u(x, top, w, 1, c.darkened(0.3))
		_u(x, top + 1, w, 0.5, l)
		# the roof kit
		match i % 5:
			0, 3:
				_chimney(x + 6.0, top - 2.0)
				_chimney(x + w - 12.0, top - 2.0)
			2:
				_dish(x + w - 12.0, top - 2.0)
			4:
				_aerial(x + 9.0, top - 2.0)
			1:
				_chimney(x + w * 0.5, top - 2.0)
		# three floors of windows
		var n := int((w - 6.0) / 8.0)
		var ox := x + (w - n * 8.0) * 0.5 + 2.0
		for r in 3:
			var wy := top + 5.0 + r * 12.0
			if wy + 8.0 > ROAD_Y - 18.0:
				break
			_u(x, wy + 9.5, w, 0.5, c.darkened(0.08))
			for k in n:
				var wx := ox + k * 8.0
				_window(wx, wy, c, _hash(i * 17 + r * 5 + k))
			if i % 5 == 1 and r == 1:
				_balcony(x + 3.0, wy, w - 6.0)
		# the shop: a sign with squiggle letters, a striped awning, the lit window, the door
		var sy := ROAD_Y - 18.0
		var sc: Color = signs[i % signs.size()]
		_u(x + 2, sy, w - 4, 4.5, sc)
		_u(x + 2, sy, w - 4, 0.5, sc.lightened(0.3))
		_squiggle(x + 4.0, sy + 1.5, w - 8.0, Color("#f2e6c8") if i % 2 == 0 else GOLD, i)
		var ac: Color = awn[i % awn.size()]
		var ay := sy + 5.0
		var sx := x + 1.0
		var j := 0
		while sx < x + w - 1.0:
			var sw := minf(2.0, x + w - 1.0 - sx)
			var sc2 := ac if j % 2 == 0 else WHITE
			_u(sx, ay, sw, 3, sc2)
			_u(sx, ay + 3, sw, 0.5, sc2.darkened(0.15) if j % 2 == 0 else Color("#e0dcd0"))
			if j % 2 == 0:
				_u(sx + 0.5, ay + 3.5, 1, 0.5, ac.darkened(0.15))
			sx += 2.0
			j += 1
		_u(x + 1, ay, w - 2, 0.5, ac.lightened(0.3))
		_u(x + 1, ay + 4, w - 2, 0.5, Color(0.1, 0.05, 0.1, 0.35))
		var gy := ay + 4.5
		_u(x + 3, gy, w - 13, ROAD_Y - gy, GLOW)
		_u(x + 3, gy, w - 13, 1, Color("#c89050"))
		for g in int((w - 15.0) / 4.0):
			_u(x + 4.5 + g * 4.0, ROAD_Y - 3.5, 2, 2.5, [Color("#c84a3a"), Color("#4a8a3e"), Color("#e8b23a"), Color("#5a6ab0")][(g + i) % 4])
		_u(x + 3 + (w - 13) * 0.5, gy, 0.5, ROAD_Y - gy, Color("#a07040"))
		_u(x + w - 9, gy - 0.5, 6, ROAD_Y - gy + 0.5, Color("#3a2e2e"))
		_u(x + w - 8.5, gy + 0.5, 5, 4, Color("#6a5a5a"))
		_u(x + w - 4.5, gy + 6, 0.5, 1, GOLD)
		# an AC box on some fronts
		if i % 3 != 2:
			var ax := x + (4.0 if i % 2 == 0 else w - 9.0)
			_ac(ax, top + 12.5)
		x += w
		i += 1


func _window(wx: float, wy: float, wall: Color, h: int) -> void:
	var lit := h % 7 == 0
	_u(wx - 0.5, wy - 0.5, 4.5, 8, Color("#f4ead8"))
	_u(wx, wy, 3.5, 7, GLOW if lit else GLASS)
	_u(wx, wy, 3.5, 1.5, Color("#ffe39a") if lit else GLASS_L)
	_u(wx + 1.5, wy, 0.5, 7, Color("#f4ead8"))
	_u(wx, wy + 2.5, 3.5, 0.5, Color("#f4ead8"))
	_u(wx - 1, wy + 7.5, 5.5, 0.5, wall.darkened(0.3))
	_u(wx - 1, wy - 1, 5.5, 0.5, wall.darkened(0.12))
	if h % 4 == 1:
		# geraniums in a box
		_u(wx - 0.5, wy + 6, 4.5, 1.5, Color("#3a6a32"))
		_u(wx - 0.5, wy + 5.5, 1, 0.5, Color("#e0402a"))
		_u(wx + 1, wy + 5, 1, 1, Color("#ff6a7a"))
		_u(wx + 2.5, wy + 5.5, 1, 0.5, Color("#e0402a"))
		_u(wx + 0.5, wy + 6, 0.5, 0.5, Color("#6cc04a"))
	elif h % 5 == 2 and not lit:
		_u(wx, wy + 3, 1.5, 4, Color("#d8b8a8"))


func _ac(x: float, y: float) -> void:
	_u(x, y, 4, 3, Color("#d8dcdc"))
	_u(x, y, 4, 0.5, Color("#eef0f0"))
	_u(x + 0.5, y + 1, 2, 0.5, Color("#9aa0a4"))
	_u(x + 0.5, y + 2, 2, 0.5, Color("#9aa0a4"))
	_u(x + 3, y + 1, 0.5, 1.5, Color("#6b737a"))
	_u(x, y + 3, 4, 0.5, Color("#8a9094"))
	_u(x + 1, y + 3.5, 0.5, 0.5, Color("#6aa8d8"))


func _balcony(x: float, y: float, w: float) -> void:
	_u(x, y + 8, w, 1, Color("#b0a090"))
	_u(x, y + 9, w, 0.5, Color("#7a6a5a"))
	_u(x, y + 4, w, 0.5, Color("#3a3a44"))
	var bx := x
	while bx < x + w:
		_u(bx, y + 4.5, 0.5, 3.5, Color("#3a3a44"))
		bx += 1.5
	_u(x + 2, y + 2, 2.5, 2, Color("#4a8a3e"))
	_u(x + 2.5, y + 1.5, 1, 0.5, Color("#ff6a7a"))


func _chimney(x: float, base: float) -> void:
	_u(x, base - 5, 3, 5, Color("#8a4a3a"))
	_u(x, base - 5, 1, 5, Color("#a86050"))
	_u(x - 0.5, base - 5.5, 4, 1, Color("#5a3a30"))
	_u(x, base - 3, 3, 0.5, Color("#6a3a2e"))


func _dish(x: float, base: float) -> void:
	_u(x + 2, base - 3, 0.5, 3, Color("#6b737a"))
	_u(x, base - 6, 1, 3.5, Color("#e0e4e6"))
	_u(x + 1, base - 6.5, 1.5, 4.5, Color("#d0d4d6"))
	_u(x + 2.5, base - 5.5, 0.5, 2.5, Color("#a0a4a8"))
	_u(x + 2.5, base - 4.5, 2, 0.5, Color("#6b737a"))
	_u(x + 4.5, base - 5, 0.5, 1, Color("#3a3a44"))


func _aerial(x: float, base: float) -> void:
	_u(x, base - 11, 0.5, 11, Color("#3a3a44"))
	_u(x - 3, base - 10, 6.5, 0.5, Color("#3a3a44"))
	_u(x - 2, base - 8, 4.5, 0.5, Color("#3a3a44"))
	_u(x - 1, base - 6, 2.5, 0.5, Color("#3a3a44"))


## Tiny sign letters: one-pixel strokes that read as words from afar.
func _squiggle(x: float, y: float, w: float, c: Color, seed_i: int) -> void:
	var cx := x
	var k := seed_i * 13
	while cx < x + w - 1.0:
		var h := _hash(k)
		if h % 6 == 0:
			cx += 1.5
		else:
			_u(cx, y, 0.5, 1.5, c)
			if h % 3 == 0:
				_u(cx + 0.5, y, 0.5, 0.5, c)
			elif h % 3 == 1:
				_u(cx + 0.5, y + 1, 0.5, 0.5, c)
			else:
				_u(cx + 0.5, y + 0.5, 0.5, 0.5, c)
			cx += 1.5
		k += 1


## Jerozolimskie's lamps: a pole lit on its left, the arm, the head with its warm bottom.
func _lamps() -> void:
	for lf: float in [0.05, 0.25, 0.535, 0.77]:
		var lx := roundf(W * lf)
		_u(lx, 64, 1, ROAD_Y - 64, Color("#2a2e34"))
		_u(lx, 64, 0.5, ROAD_Y - 64, Color("#4a4e58"))
		_u(lx - 1, ROAD_Y - 4, 3, 4, Color("#2a2e34"))
		_u(lx - 1, ROAD_Y - 4, 3, 0.5, Color("#4a4e58"))
		_u(lx, 63, 4, 1, Color("#2a2e34"))
		_u(lx + 3, 63, 5, 2, Color("#3a3e46"))
		_u(lx + 3, 63, 5, 0.5, Color("#5a5e68"))
		_u(lx + 3.5, 65, 4, 0.5, SUN_GLOW)
		_u(lx + 4.5, 65.5, 2, 0.5, SUN)


func _road_bed() -> void:
	_u(0, ROAD_Y, W, PAVE_Y - ROAD_Y, ASPHALT)
	_u(0, ROAD_Y, W, 1, KERB_L)
	_u(0, ROAD_Y + 1, W, 0.5, KERB_D)
	_u(0, ROAD_Y + 1.5, W, 0.5, ASPHALT_D)
	# the track bed and its two rails, the sleepers' tops
	_u(0, ROAD_Y + 13, W, 9, Color("#4c4c52"))
	for ry: float in [ROAD_Y + 14.5, ROAD_Y + 19.5]:
		_u(0, ry, W, 0.5, RAIL)
		_u(0, ry + 0.5, W, 0.5, Color("#2a2a30"))
	var x := 0.0
	while x < W:
		_u(x, ROAD_Y + 13, 0.5, 0.5, Color("#5a5a60"))
		x += 6.0
	# patches and specks
	for i in 60:
		var h := _hash(i + 400)
		var sx := float(h % 467) / 467.0 * W
		var sy := ROAD_Y + 3.0 + float((h / 7) % 30)
		if sy > ROAD_Y + 12.5 and sy < ROAD_Y + 22.5:
			continue
		_u(sx, sy, 0.5, 0.5, ASPHALT_L if i % 2 == 0 else ASPHALT_D)
	_u(W * 0.18, ROAD_Y + 24, 14, 3, ASPHALT_D)
	_u(W * 0.72, ROAD_Y + 4, 10, 2.5, ASPHALT_D)
	# the lane dashes
	x = 0.0
	while x < W:
		for dy: float in [7.0, 27.0]:
			_u(x, ROAD_Y + dy, 8, 1, Color("#d8d8cc"))
			_u(x, ROAD_Y + dy + 1, 8, 0.5, Color("#9a9a94"))
		x += 16.0
	# the near kerb: granite stones, the gutter, a drain
	_u(0, PAVE_Y - 2.5, W, 0.5, ASPHALT_D)
	_u(0, PAVE_Y - 2, W, 2, KERB)
	_u(0, PAVE_Y - 2, W, 0.5, KERB_L)
	x = 4.0
	while x < W:
		_u(x, PAVE_Y - 2, 0.5, 2, KERB_D)
		x += 9.0
	var dx := roundf(W * 0.56)
	_u(dx, PAVE_Y - 3.5, 6, 1, Color("#2a2a30"))
	for g in 4:
		_u(dx + 0.5 + g * 1.5, PAVE_Y - 3.5, 0.5, 1, Color("#6a6a72"))


func _pavement() -> void:
	_u(0, PAVE_Y, W, H - PAVE_Y, PAVE)
	var y := PAVE_Y + 6.0
	var row := 0
	var prev := PAVE_Y
	while y < H + 8.0:
		var step := 7.0 + row
		var x := 12.0 if row % 2 == 0 else 0.0
		var col := 0
		while x < W:
			var h := _hash(row * 41 + col)
			if h % 7 == 0:
				_u(x + 0.5, prev + 0.5, 23.5, y - prev - 0.5, PAVE_L)
			elif h % 11 == 0:
				_u(x + 0.5, prev + 0.5, 23.5, y - prev - 0.5, Color("#908b82"))
			if h % 23 == 0:
				_u(x + 6, prev + 2, 3, 0.5, PAVE_D)
				_u(x + 9, prev + 2.5, 2, 0.5, PAVE_D)
			_u(x, prev + 0.5, 0.5, y - prev - 0.5, PAVE_D)
			_u(x + 0.5, prev + 0.5, 0.5, y - prev - 0.5, PAVE_L)
			x += 24.0
			col += 1
		_u(0, y, W, 0.5, PAVE_D)
		_u(0, y + 0.5, W, 0.5, PAVE_L)
		prev = y
		y += step
		row += 1
	# the palm's long shadow toward the right, the sun being low on the left
	_u(_palm_x() + 4, PAVE_Y + 0.5, 80, 2.5, Color(0.1, 0.05, 0.15, 0.16))


## Street furniture behind the people: bollards, a green bin, a hydrant.
func _props() -> void:
	for bx: float in [W * 0.31, W * 0.69, W * 0.83]:
		_bollard(roundf(bx), PAVE_Y + 2.0)
	_bin(roundf(W * 0.35), PAVE_Y + 8.0)
	_hydrant(roundf(W * 0.78), PAVE_Y + 9.0)


func _bollard(x: float, y: float) -> void:
	_u(x - 0.5, y - 0.5, 4, 12, OUT)
	_u(x, y, 3, 11, Color("#2a2e34"))
	_u(x, y, 1, 11, Color("#4a4e58"))
	_u(x - 0.5, y - 1, 4, 1.5, Color("#3a3e46"))
	_u(x, y + 2.5, 3, 1, Color("#e0e4e6"))
	_u(x + 4, y + 10, 6, 1, Color(0.1, 0.05, 0.15, 0.2))


func _bin(x: float, y: float) -> void:
	_u(x - 0.5, y - 1.5, 10, 14, OUT)
	_u(x, y, 9, 12, Color("#2e7a4a"))
	_u(x, y, 1.5, 12, Color("#4a9a62"))
	_u(x + 7, y, 2, 12, Color("#1e5a34"))
	_u(x - 0.5, y - 1, 10, 1.5, Color("#1e5a34"))
	_u(x + 0.5, y - 1.5, 8, 0.5, Color("#16191d"))
	_u(x, y + 3, 9, 0.5, Color("#1e5a34"))
	_u(x + 2.5, y + 1, 4, 1, Color("#16191d"))
	_u(x + 3, y + 5, 3, 2, Color("#f2f2ea"))
	_u(x + 3.5, y + 5.5, 2, 1, Color("#2e7a4a"))
	_u(x + 9.5, y + 11, 8, 1, Color(0.1, 0.05, 0.15, 0.2))


func _hydrant(x: float, y: float) -> void:
	_u(x - 0.5, y - 2.5, 6, 12, OUT)
	_u(x, y, 5, 9, Color("#c8302a"))
	_u(x, y, 1, 9, Color("#e8584a"))
	_u(x + 4, y, 1, 9, Color("#8a1e1a"))
	_u(x + 0.5, y - 2, 4, 2, Color("#c8302a"))
	_u(x + 1.5, y - 2.5, 2, 0.5, Color("#8a1e1a"))
	_u(x - 1, y + 3, 1, 1.5, Color("#c8c8c8"))
	_u(x + 5, y + 3, 1, 1.5, Color("#c8c8c8"))
	_u(x - 0.5, y + 8, 6, 1, Color("#8a1e1a"))
	_u(x + 6, y + 8.5, 7, 1, Color(0.1, 0.05, 0.15, 0.2))


# --- the live layer -------------------------------------------------------------------------------

func _draw_live() -> void:
	_use(_live_n)
	if tasting == null:
		return
	var colours := [Kit.CUP, Kit.THEM, Kit.CHROME, Kit.GOLD, Color("#5a6ab0"), Color("#2e7a4a")]
	for k in 4:
		var sp := 38.0 + k * 9.0
		var cx := fmod(_t * sp + k * 131.0, W + 60.0) - 30.0
		_car(cx, ROAD_Y + 1.5, colours[k], true)
	var tt := fmod(_t + 4.0, TRAM_S)
	if tt < 5.0:
		_tram(-120.0 + tt / 5.0 * (W + 240.0), ROAD_Y + 5.5)
	_palm()
	for k in 4:
		var sp := 38.0 + k * 9.0
		var bx := W + 30.0 - fmod(_t * (sp + 6.0) + k * 97.0, W + 60.0)
		_car(bx, ROAD_Y + 21.5, colours[(k + 2) % colours.size()], false)
	_porsza(roundf(W * 0.03), PAVE_Y - 1.0)
	_pigeon()
	var ph := tasting.phase
	var fan := ph == Tasting.Phase.FAN or ph == Tasting.Phase.SELFIE or ph == Tasting.Phase.CARD
	for x: float in [_you_x(), _kebabulo_x(), _zbyszek_x()] + ([_fan_x] if fan else []):
		_u(x - 8, FEET - 0.5, 16, 1.5, Color(0.1, 0.05, 0.15, 0.3))
		_u(x + 4, FEET, 30, 1.5, Color(0.1, 0.05, 0.15, 0.14))
	if fan and ph == Tasting.Phase.CARD:
		_fan()
	_zbyszek()
	if fan and ph != Tasting.Phase.CARD:
		_fan()
	_kebabulo()
	_you()


## A car side-on: two-tone body, framed glass with a glint, wheels with hubs, the lamps.
func _car(x: float, y: float, c: Color, right: bool) -> void:
	x = roundf(x * PX) / PX
	var d := c.darkened(0.28)
	var l := c.lightened(0.25)
	var fr := x + 21.5 if right else x
	var rr := x if right else x + 21.5
	var cab := x + (5.0 if right else 6.0)
	_u(x - 0.5, y + 2.5, 23, 6.5, OUT)
	_u(cab - 0.5, y - 0.5, 12, 4, OUT)
	_u(x, y + 3, 22, 5, c)
	_u(x, y + 6.5, 22, 1.5, d)
	_u(x + 0.5, y + 3, 21, 0.5, l)
	_u(cab, y, 11, 3.5, c)
	_u(cab, y, 11, 0.5, l)
	_u(cab + 1, y + 0.5, 4, 2.5, Color("#3a4a5a"))
	_u(cab + 5.5, y + 0.5, 4.5, 2.5, Color("#3a4a5a"))
	_u(cab + 1, y + 0.5, 1, 1, Color("#9ab4c8"))
	_u(cab + 5.5, y + 0.5, 1, 1, Color("#9ab4c8"))
	_u(x + 11, y + 3.5, 0.5, 3, d)
	_u(x + (12.5 if right else 8.5), y + 4.5, 1.5, 0.5, d)
	_u(fr, y + 4, 0.5, 1.5, SUN)
	_u(rr, y + 4, 0.5, 1.5, RED)
	_u(x, y + 7.5, 22, 0.5, Color("#2a2a30"))
	for wx: float in [x + 3.0, x + 15.0]:
		_u(wx, y + 6.5, 4, 3.5, INK)
		_u(wx + 1, y + 7.5, 2, 1.5, Color("#8a929a"))
		_u(wx + 1.5, y + 8, 1, 0.5, Color("#c9d2d8"))


## A Warsaw tram: three red cars, the yellow band, framed windows, doors, bogies, the pantograph.
func _tram(x: float, y: float) -> void:
	x = roundf(x * PX) / PX
	_u(x - 0.5, y - 1.5, 3 * 38.0 - 1, 17, OUT)
	for k in 3:
		var cx := x + k * 38.0
		_u(cx, y - 1, 36, 1.5, Color("#9a9aa0"))
		_u(cx, y + 0.5, 36, 13, TRAM_R)
		_u(cx, y + 0.5, 36, 0.5, Color("#e8584a"))
		_u(cx, y + 8, 36, 2, TRAM_Y)
		_u(cx, y + 10, 36, 0.5, Color("#b8901a"))
		_u(cx, y + 12, 36, 1.5, TRAM_RD)
		for wi in 4:
			var wx := cx + 3.0 + wi * 8.0
			if k == 1 and wi == 1:
				_u(wx, y + 2, 6, 11, Color("#2a2e34"))
				_u(wx + 0.5, y + 2.5, 2, 4, Color("#5a7a8a"))
				_u(wx + 3.5, y + 2.5, 2, 4, Color("#5a7a8a"))
				continue
			_u(wx - 0.5, y + 1.5, 7, 6, TRAM_RD)
			_u(wx, y + 2, 6, 5, Color("#3a4a5a"))
			_u(wx, y + 2, 2, 1, Color("#9ab4c8"))
		_u(cx + 4, y + 13.5, 9, 1.5, INK)
		_u(cx + 23, y + 13.5, 9, 1.5, INK)
		_u(cx + 36, y + 2, 2, 10, Color("#2a2e34"))
	# the front: its lamp and the destination board
	_u(x + 3 * 38.0 - 3, y + 9, 1, 1, SUN)
	_u(x + 3 * 38.0 - 10, y + 1, 6, 1.5, INK)
	_u(x + 3 * 38.0 - 9.5, y + 1.5, 3, 0.5, AMBER)
	_u(x + 44, y - 5.5, 12, 0.5, INK)
	_u(x + 46, y - 5, 0.5, 2, INK)
	_u(x + 53.5, y - 5, 0.5, 2, INK)
	_u(x + 46, y - 3, 8, 0.5, INK)
	_u(x + 49.5, y - 2.5, 1, 1.5, INK)


## The Palm on its island: grass and kerb, the trunk in rings (lit left, shaded right), fronds as
## stepped strips with leaflets, the dates; it sways by whole pixels.
func _palm() -> void:
	var x := _palm_x()
	var base := PAVE_Y - 8.0
	_disc(x, base + 3, 24, 5, Color("#8a8a92"))
	_disc(x, base + 2.5, 22.5, 4, GRASS[0])
	_u(x - 18, base + 0.5, 12, 0.5, GRASS[2])
	_u(x + 6, base + 4.5, 14, 0.5, GRASS[1])
	for g in 9:
		_u(x - 16 + g * 4, base + 1 + (g % 3), 0.5, 1, GRASS[2] if g % 2 == 0 else GRASS[1])
	var top := 28.0
	var seg := 2.5
	var n := int((base - top) / seg)
	for i in n:
		var y := base - (i + 1) * seg
		var lean := roundf(float(i) / n * 3.0 * PX) / PX
		var wide := 1.0 if i < 4 else 0.0
		var tx := x - 3.0 + lean - wide * 0.5
		var tw := 7.0 + wide
		_u(tx - 0.5, y, tw + 1, seg, OUT)
		_u(tx, y, tw, seg, TRUNK[0])
		_u(tx, y, 1.5, seg, TRUNK[2])
		_u(tx + tw - 2, y, 2, seg, TRUNK[1])
		_u(tx, y + seg - 0.5, tw, 0.5, TRUNK_RING)
		_u(tx + (0.0 if i % 2 == 0 else tw - 1.0) - 0.5, y + seg - 1, 1, 0.5, TRUNK[2] if i % 2 == 0 else TRUNK[1])
	var sway := roundf(sin(_t * 0.9) * 1.0 * PX) / PX
	var cx := x + 3.0 + sway
	var droop := 0.5 if fmod(_t, 2.4) < 1.2 else 0.0
	# the fronds behind first (darker), then the front ones; each a rib of stepped rects with
	# leaflets hanging under it, the tips drooping
	for layer in 2:
		for f in 6:
			var a := -PI * 1.1 + (float(f) + 0.5 * layer) * PI * 1.2 / 5.5
			var dx := cos(a)
			var dy := sin(a)
			var length := 9 + (f + layer * 3) % 4 - (2 if absf(dx) < 0.35 else 0)
			var shade: Array = [FROND[1], FROND[1].darkened(0.2), FROND[0]] if layer == 0 else FROND
			for k in length:
				var fx := roundf((cx + dx * k * 3.0) * PX) / PX
				var fy := roundf((top + dy * k * 2.4 + k * k * (0.16 + absf(dx) * 0.1) + (droop if k > length - 3 else 0.0)) * PX) / PX
				var th := 2.0 if k < length - 3 else 1.5
				_u(fx - 1.5, fy - 0.5, 4, th + 1, OUT)
				_u(fx - 1, fy, 3, th, shade[2] if k % 3 == 0 and layer == 1 else shade[0])
				_u(fx - 1, fy + th - 0.5, 3, 0.5, shade[1])
				if k > 1 and k % 2 == 0:
					var ll := 1.5 + minf(k, 6) * 0.25
					_u(fx - 1, fy + th, 0.5, ll, shade[1])
					_u(fx + 1, fy + th, 0.5, ll - 0.5, shade[0])
				elif k > 1:
					_u(fx, fy - 1, 0.5, 1, shade[2])
	_u(cx - 3, top - 1, 6, 4, OUT)
	_u(cx - 2.5, top - 0.5, 5, 3, FROND[1])
	_u(cx - 2, top + 2, 1.5, 1.5, Color("#c8a020"))
	_u(cx, top + 2.5, 1.5, 1.5, Color("#a87a18"))
	_u(cx + 1.5, top + 2, 1.5, 1.5, Color("#c8a020"))


## Kebabulo's Porsza parked at the near kerb, side-on, nose right (F 2026-11-26 21:09, a grey 911-style
## coupe from a photo, no badges): a gunmetal fastback whose roof runs down to the tail, the raised
## rear wing, the intake behind the door, a round lamp with its ring, a black front intake, dark
## multi-spoke rims with yellow calipers. The profile is rows of columns (equal tops merged), the
## paint in four horizontal bands clipped to it, so it costs a few hundred rects.
func _porsza(x: float, base: float) -> void:
	x = roundf(x * PX) / PX
	var w := roundf(W * 0.25)
	var n := int(w * PX)
	var su := float(PX)
	_u(x + 1, base - 0.5, w - 1, 2, Color(0.1, 0.05, 0.15, 0.32))
	_u(x + 4, base + 1.5, w - 8, 1, Color(0.1, 0.05, 0.15, 0.16))
	# the profile's top (units above the ground) at each scene px column
	var tops := PackedFloat32Array()
	for i in n:
		tops.append(_porsza_top((float(i) + 0.5) / float(n)))
	_fig(0, 0, 1)
	_org = Vector2.ZERO
	var gx := x * su
	var gy := base * su
	# the silhouette (outlined): runs of columns with the same top, then the wing on its stalk
	var i0 := 0
	for i in range(1, n + 1):
		if i == n or roundf(tops[i] * su) != roundf(tops[i0] * su):
			var t := roundf(tops[i0] * su)
			var b := 6.0 if i0 < n * 0.02 or i0 > n * 0.975 else 5.0
			_q(gx + i0, gy - t, i - i0, t - b, P911[1])
			i0 = i
	for sx: float in [0.05, 0.12]:
		_q(gx + w * sx * su, gy - 22.0 * su, 1.5 * su, 4 * su, P911[4])
	_q(gx + w * 0.005 * su, gy - 23.5 * su, w * 0.165 * su, 2.5 * su, P911[2])
	_detail(true)
	_q(gx + w * 0.005 * su, gy - 21.5 * su, w * 0.165 * su, 0.5 * su, P911[4])
	_q(gx + w * 0.005 * su, gy - 23.5 * su, w * 0.165 * su, 1, P911[0])
	# the paint: bands clipped to the profile (the sides darker down to the sill)
	for band: Array in [[18.0, 17.0, P911[0]], [17.0, 9.0, P911[2]], [9.0, 4.5, P911[3]], [4.5, 2.5, P911[4]]]:
		var a := -1
		var z := -1
		for i in n:
			if tops[i] > float(band[0]):
				if a < 0:
					a = i
				z = i
		if a >= 0:
			var hgt := float(band[0]) - float(band[1])
			_q(gx + a, gy - float(band[0]) * su, z - a + 1, hgt * su, band[2])
	# the light along the roof, the deck and the bonnet: one px on each run's top
	i0 = 0
	for i in range(1, n + 1):
		if i == n or roundf(tops[i] * su) != roundf(tops[i0] * su):
			_q(gx + i0, gy - roundf(tops[i0] * su), i - i0, 1, P911[0])
			i0 = i
	# the glass: the quarter light and the door window under the roof's line, a frame of paint above
	var gl := int(n * 0.30)
	var gr := int(n * 0.69)
	i0 = gl
	for i in range(gl + 1, gr + 1):
		var belt := _porsza_belt(float(i0) / float(n))
		if i == gr or roundf((tops[i] - 1.5) * su) != roundf((tops[i0] - 1.5) * su) or roundf(_porsza_belt(float(i) / float(n)) * su) != roundf(belt * su):
			var top := roundf((tops[i0] - 1.5) * su)
			var bot := roundf(belt * su)
			if top > bot:
				_q(gx + i0, gy - top, i - i0, top - bot, GLASS911[0])
				_q(gx + i0, gy - top, i - i0, 1, GLASS911[1])
			i0 = i
	_q(gx + w * 0.445 * su, gy - 27 * su, 1.5 * su, 6 * su, P911[4])
	_q(gx + w * 0.50 * su, gy - 25.5 * su, w * 0.05 * su, 1, GLASS911[2])
	_q(gx + w * 0.51 * su, gy - 25 * su, w * 0.03 * su, 1, GLASS911[2])
	_q(gx + w * 0.345 * su, gy - 25 * su, 2, 1, GLASS911[2])
	# the door: its cut lines, the flush handle, the mirror on the door's front
	_q(gx + w * 0.40 * su, gy - 20 * su, 1, 16 * su, P911[4])
	_q(gx + w * 0.675 * su, gy - 20 * su, 1, 15.5 * su, P911[4])
	_q(gx + w * 0.42 * su, gy - 18.5 * su, 3 * su, 1, P911[4])
	_q(gx + w * 0.42 * su, gy - 18.5 * su + 1, 3 * su, 1, P911[0])
	_q(gx + w * 0.655 * su, gy - 23.5 * su, w * 0.05 * su, 2.5 * su, P911[1])
	_q(gx + w * 0.655 * su, gy - 23.5 * su, w * 0.05 * su, 1, P911[0])
	_q(gx + w * 0.655 * su, gy - 21 * su, w * 0.05 * su, 1, P911[4])
	# the long reflections: a hard line along the door and the rear hip
	_q(gx + w * 0.42 * su, gy - 12.5 * su, w * 0.24 * su, 1, P911[1])
	_q(gx + w * 0.07 * su, gy - 14.5 * su, w * 0.15 * su, 1, P911[1])
	_q(gx + w * 0.74 * su, gy - 13 * su, w * 0.12 * su, 1, P911[1])
	# the intake behind the door, slats in it
	for k in 5:
		var iw := 4.0 - absf(float(k) - 1.5) * 0.6
		_q(gx + (w * 0.315 - iw * 0.5) * su, gy - (17.5 - k * 1.2) * su, iw * su, 1.2 * su, INK if k % 2 == 0 else Color("#33373e"))
	# the round lamp with its light ring, the black intake under the nose, the lip
	var lx := x + w * 0.875
	_disc(lx, base - 15.5, 3.0, 2.5, P911[4])
	_disc(lx, base - 15.5, 2.5, 2.0, Color("#c9d2da"))
	_disc(lx, base - 15.5, 1.5, 1.2, Color("#4a525c"))
	_u(lx - 0.5, base - 16, 1, 0.5, WHITE)
	for s: Vector2 in [Vector2(-1.5, -1.0), Vector2(1.0, -1.0), Vector2(-1.5, 0.5), Vector2(1.0, 0.5)]:
		_u(lx + s.x, base - 15.5 + s.y, 0.5, 0.5, Color("#f4fbff"))
	_q(gx + w * 0.93 * su, gy - 9 * su, w * 0.07 * su, 5 * su, INK)
	for k in 3:
		_q(gx + w * 0.935 * su, gy - (8 - k * 1.5) * su, w * 0.06 * su, 1, Color("#3a3e46"))
	_q(gx + w * 0.90 * su, gy - 4.5 * su, w * 0.10 * su, 1 * su, Color("#24272c"))
	# the tail: the light bar, the diffuser, two tailpipes
	_q(gx, gy - 15 * su, 1.5 * su, 1.5 * su, RED)
	_q(gx, gy - 15 * su, 1.5 * su, 1, RED_L)
	_q(gx + w * 0.015 * su, gy - 7 * su, w * 0.06 * su, 3 * su, INK)
	_q(gx - 1.5 * su, gy - 5.5 * su, 2 * su, 1 * su, Color("#8a929a"))
	_q(gx - 1.5 * su, gy - 5.5 * su, 1, 1 * su, INK)
	_detail(false)
	_flush(OUT)
	for wu: float in [0.205, 0.80]:
		_porsza_wheel(roundf((x + w * wu) * PX) / PX, base - 8.0, wu > 0.5)


## The Porsza's roof line, units above the ground at `u` (0 the tail, 1 the nose).
static func _porsza_top(u: float) -> float:
	var pts := [Vector2(0.0, 13.5), Vector2(0.02, 16.5), Vector2(0.06, 18.0), Vector2(0.15, 20.0),
		Vector2(0.25, 23.0), Vector2(0.35, 26.5), Vector2(0.45, 28.5), Vector2(0.52, 29.0),
		Vector2(0.58, 28.3), Vector2(0.64, 25.5), Vector2(0.70, 21.5), Vector2(0.73, 19.0),
		Vector2(0.76, 18.0), Vector2(0.83, 17.8), Vector2(0.88, 18.4), Vector2(0.93, 17.0),
		Vector2(0.97, 14.5), Vector2(0.995, 11.5), Vector2(1.0, 10.0)]
	for k in range(1, pts.size()):
		var b: Vector2 = pts[k]
		if u <= b.x:
			var a: Vector2 = pts[k - 1]
			return lerpf(a.y, b.y, (u - a.x) / (b.x - a.x))
	return 10.0


## The window's lower edge: level along the door, rising to the quarter light's tip.
static func _porsza_belt(u: float) -> float:
	return 20.0 + maxf(0.0, 0.45 - u) * 12.0


## A wheel: the arch, the tyre, a dark multi-spoke rim, the disc, a yellow caliper behind the spokes.
func _porsza_wheel(cx: float, cy: float, front: bool) -> void:
	_disc(cx, cy - 0.5, 9.0, 9.0, Color("#24262b"))
	_disc(cx, cy + 0.5, 8.0, 8.0, OUT)
	_disc(cx, cy + 0.5, 7.5, 7.5, Color("#17181c"))
	_disc(cx, cy + 0.5, 5.8, 5.8, Color("#3d4148"))
	_disc(cx, cy + 0.5, 5.3, 5.3, Color("#202227"))
	_disc(cx, cy + 0.5, 4.2, 4.2, Color("#5b6068"))
	var ca := PI * (0.80 if front else 0.20)
	for k in 5:
		var a := ca + (float(k) - 2.0) * 0.16
		_u(cx + cos(a) * 3.6 - 0.75, cy + 0.5 - sin(a) * 3.6 - 0.75, 1.5, 1.5, P911_CALIPER)
	for k in 10:
		var a := TAU * float(k) / 10.0 + 0.15
		for r: float in [1.6, 2.4, 3.2, 4.0, 4.8]:
			_u(cx + cos(a) * r - 0.25, cy + 0.5 + sin(a) * r - 0.25, 0.5, 0.5, Color("#6a6f78") if r < 3.0 else Color("#4a4e56"))
	_disc(cx, cy + 0.5, 1.4, 1.4, Color("#2a2d33"))
	_u(cx - 0.5, cy, 1, 1, Color("#9aa0a8"))
	_u(cx - 5.5, cy - 3.5, 1.5, 0.5, Color("#3a3d44"))


## A pigeon pacing toward the kebab, pecking; it takes off at the MLASK and is back for the verdict.
func _pigeon() -> void:
	var ph := tasting.phase
	var flying := ph == Tasting.Phase.MLASK or (ph == Tasting.Phase.VERDICT and tasting.t < 0.6 and tasting.line_i == 0)
	var k := fmod(_t, 16.0) / 16.0
	var x := roundf(lerpf(W * 0.29, _you_x() - 16.0, minf(1.0, k * 1.6)))
	var y := FEET - 2.0
	if flying:
		var ft := tasting.t + (0.0 if ph == Tasting.Phase.MLASK else Tasting.MLASK_S)
		y -= roundf(ft * 40.0)
		x -= roundf(ft * 30.0)
	var walk := int(_t * 5.0) % 2
	var peck := not flying and fmod(_t, 1.4) < 0.25
	_fig(x, y, 1)
	var hy := 4.0 if peck else 0.0
	var hx := 2.0 if peck else 0.0
	# tail, body, wing, neck, head
	_q(-6, -11, 6, 3, PIGEON[1])
	_q(-7, -10, 2, 2, Color("#3a3e48"))
	_q(-1, -13, 15, 8, PIGEON[0])
	_q(0, -7, 12, 2, PIGEON[2])
	if flying:
		var up := int(_t * 12.0) % 2 == 0
		_q(1, -22 if up else -10, 9, 10 if up else 6, PIGEON[2])
		_q(2, -22 if up else -6, 7, 2, Color("#3a3e48"))
	else:
		_q(1, -12, 10, 5, PIGEON[2])
		_detail(true)
		_q(4, -10, 1, 3, Color("#4a4e58"))
		_q(7, -10, 1, 3, Color("#4a4e58"))
		_detail(false)
	_q(11 + hx, -17 + hy, 5, 7, PIGEON[0])
	_q(12 + hx, -20 + hy, 6, 5, Color("#7a7f8a"))
	_q(18 + hx, -18 + hy, 2, 1, Color("#e8c090"))
	_detail(true)
	_q(12 + hx, -14 + hy, 3, 2, Color("#5fae8a"))
	_q(14 + hx, -13 + hy, 2, 2, Color("#8a6aa0"))
	_q(16 + hx, -19 + hy, 1, 1, Color("#ff8a2a"))
	_q(18 + hx, -19 + hy, 1, 1, WHITE)
	_detail(false)
	if not flying:
		_q(4 + walk, -5, 1, 4, Color("#e07a7a"))
		_q(8 - walk, -5, 1, 4, Color("#e07a7a"))
		_q(4 + walk, -1, 3, 1, Color("#e07a7a"))
		_q(8 - walk, -1, 3, 1, Color("#e07a7a"))
	_flush(OUT)


# --- the people -----------------------------------------------------------------------------------

## One figure, front-on with the face turned to `f`. `s` keys: x, f, top, legs, shoe, sole, skin,
## tw (torso px), th, ll (legs), hh (head), front / back arm poses ("down", "hold", "out", "up",
## "thumb", "fist", "peace", "scratch"), hold_f / hold_b ("kebab", "kebab_bit", "wraps3", "bag",
## "phone", "phone_up", "gimbal"), face (see `_head`), hair, hair_c, kind ("kebabulo", "you",
## "zbyszek", "fan"), bob (px up), walk (-1 or the frame 0/1), seed (blinks).
func _person(s: Dictionary) -> void:
	var f: int = s["f"]
	_fig(float(s["x"]), float(s.get("feet", FEET)), f, float(s.get("s", 1.0)))
	var tw: float = s["tw"]
	var th: float = s["th"]
	var ll: float = s["ll"]
	var hh: float = s.get("hh", 30.0)
	var bob: float = s.get("bob", 0.0)
	# a 1 px breath and the walk's bounce
	var seed: float = s.get("seed", 0.0)
	if fmod(_t + seed, 3.2) < 1.6:
		bob += 1.0
	var walk: int = s.get("walk", -1)
	if walk == 1:
		bob += 1.0
	var yh := -(7.0 + ll) - (bob if walk < 0 else 0.0)
	var ys := -(7.0 + ll + th) - bob
	var top: Array = s["top"]
	var kind: String = s.get("kind", "")
	# what is behind: the backpack, the back arm and its hold
	if kind == "fan":
		_band(-tw * 0.5 - 5.0, ys + 5, 7, 28, [Color("#1f5f6a"), Color("#14444c"), Color("#2f7f8a")], 2, 1)
	_arm(-1, str(s.get("back", "down")), ys, tw, th, top, s["skin"], str(s.get("hold_b", "")))
	# the legs and the shoes
	var legs: Array = s["legs"]
	var lw := floorf((tw - 6.0) * 0.5) - 1.0
	var ax := -tw * 0.5 + 3.0
	var bxl := 1.0
	var a_lift := 0.0
	var b_lift := 0.0
	if walk == 0:
		ax -= 3.0
		bxl += 3.0
		b_lift = 1.0
	elif walk == 1:
		ax += 2.0
		bxl -= 2.0
		a_lift = 1.0
	_q(-tw * 0.5 + 3.0, yh - 1.0, tw - 6.0, 8, legs[0])
	for lg: Array in [[ax, a_lift], [bxl, b_lift]]:
		var lx: float = lg[0]
		var lift: float = lg[1]
		_band(lx, yh, lw, -7.0 - yh - lift, legs, 2, 1)
		_detail(true)
		_q(lx, -10.0 - lift, lw, 1, legs[2])
		if kind == "you" or kind == "fan":
			_q(lx + floorf(lw * 0.5), yh + 8.0, 1, -18.0 - yh, legs[1])
		_detail(false)
		var shoe: Color = s.get("shoe", SOLE_D)
		_q(lx - 1.0, -7.0 - lift, lw + 4.0, 5, shoe)
		_q(lx - 1.0, -2.0 - lift, lw + 4.0, 2, s.get("sole", SOLE_L))
		_detail(true)
		_q(lx + 2.0, -6.0 - lift, 4, 1, shoe.darkened(0.25))
		_q(lx + lw + 1.0, -5.0 - lift, 2, 1, shoe.lightened(0.3))
		_detail(false)
	# the torso
	_band(-tw * 0.5, ys, tw, yh - ys, top, 4, 2)
	_q(-tw * 0.5, yh - 4.0, tw, 4, top[1])
	_detail(true)
	_q(-tw * 0.5, yh - 4.0, tw, 1, top[0].darkened(0.3))
	_detail(false)
	match kind:
		"kebabulo":
			_kebabulo_torso(ys, yh, tw)
		"you":
			_detail(true)
			_q(-tw * 0.5, ys + 14, tw, 3, top[2])
			_q(-tw * 0.5, ys + 17, tw, 1, top[1])
			_q(-5, ys, 10, 2, top[1])
			_detail(false)
		"zbyszek":
			_q(-8, ys - 3, 16, 5, top[2])
			_detail(true)
			_q(-8, ys - 3, 16, 1, top[2].lightened(0.15))
			_q(0, ys + 2, 1, yh - ys - 6, Color("#8a929a"))
			_q(-tw * 0.5 + 4, ys + 16, 7, 1, top[1])
			_q(4, ys + 26, 7, 1, top[1])
			_detail(false)
		"fan":
			_detail(true)
			var qy := ys + 7.0
			while qy < yh - 4.0:
				_q(-tw * 0.5, qy, tw, 1, top[1])
				_qs(-tw * 0.5, qy - 1.0, tw * 0.5, 1, top[2])
				qy += 7.0
			_detail(false)
			qy = ys + 4.0
			while qy < yh - 4.0:
				_q(-tw * 0.5 - 1.0, qy, 1, 5, top[0])
				_q(tw * 0.5, qy, 1, 5, top[1])
				qy += 7.0
			_q(-7, ys - 3, 14, 5, top[2])
			_q(-tw * 0.5 + 4, ys, 3, 22, Color("#14444c"))
		_:
			_torso_extra(kind, ys, yh, tw, top)
	# the neck and the head
	var skin: Array = s["skin"]
	_q(-4, ys - 4, 8, 5, skin[1])
	if kind == "kebabulo":
		_kebabulo_hood(ys)
	var face: Dictionary = (s.get("face", {}) as Dictionary).duplicate()
	if str(face.get("eyes", "open")) == "open" and fmod(_t + seed * 1.7, 3.3) < 0.12:
		face["eyes"] = "blink"
	_head(0, ys - 3.0 - hh, hh, skin, str(s.get("hair", "")), s.get("hair_c", BEARD), face, kind == "kebabulo")
	# the front arm and what it holds
	_arm(1, str(s.get("front", "down")), ys, tw, th, top, skin, str(s.get("hold_f", "")))
	_flush(OUT)


## A kind's own marks on the torso (none here; kemal_window_ui.gd's queue adds its own).
func _torso_extra(_kind: String, _ys: float, _yh: float, _tw: float, _top: Array) -> void:
	pass


## Kebabulo's black puffer vest over the beige hoodie: quilted bands, the zip, the pockets, the
## hoodie's V and strings at the neck and its ribbed hem below.
func _kebabulo_torso(ys: float, yh: float, tw: float) -> void:
	_band(-tw * 0.5, ys + 2, tw, yh - ys - 8, VEST, 4, 1)
	_detail(true)
	var qy := ys + 8.0
	while qy < yh - 8.0:
		_q(-tw * 0.5, qy, tw, 1, VEST[1])
		_qs(-tw * 0.5 + 1.0, qy - 1.0, tw * 0.5 - 2.0, 1, VEST[2])
		qy += 7.0
	_q(-1, ys + 8, 1, yh - ys - 14, Color("#6b737a"))
	_q(-tw * 0.5 + 3, yh - 16, 7, 1, Color("#6b737a"))
	_q(tw * 0.5 - 10, yh - 16, 7, 1, Color("#6b737a"))
	_detail(false)
	_q(-tw * 0.5, yh - 6, tw, 6, HOODIE[0])
	_detail(true)
	_q(-tw * 0.5, yh - 6, tw, 1, HOODIE[1])
	for rx in range(int(-tw * 0.5) + 2, int(tw * 0.5), 3):
		_q(rx, yh - 4, 1, 4, HOODIE[1])
	# the V of the hoodie and its strings
	_q(-5, ys + 1, 10, 5, HOODIE[0])
	_q(-3, ys + 6, 6, 2, HOODIE[0])
	_q(-4, ys + 5, 1, 6, TRAINER)
	_q(3, ys + 5, 1, 6, TRAINER)
	_q(-4, ys + 11, 1, 1, Color("#c9c4b8"))
	_q(3, ys + 11, 1, 1, Color("#c9c4b8"))
	_detail(false)


## The hood down behind his neck, beige, shaded.
func _kebabulo_hood(ys: float) -> void:
	_band(-15, ys - 8, 30, 8, HOODIE, 4, 2)
	_detail(true)
	_q(-12, ys - 8, 24, 1, HOODIE[2])
	_q(-6, ys - 3, 12, 2, HOODIE[1])
	_detail(false)


## An arm from the shoulder on side `side` (+1 the facing side, -1 the back), `pose`, the hand and
## what it holds. Coordinates go outward from the shoulder's outer edge.
func _arm(side: int, pose: String, ys: float, tw: float, th: float, top: Array, skin: Array, hold: String) -> void:
	var x0 := tw * 0.5 if side > 0 else -tw * 0.5
	var al := roundf(th * 0.55)
	var A := func(dx: float, y: float, w: float, h: float, c: Color) -> void:
		_q(x0 + dx if side > 0 else x0 - dx - w, ys + y, w, h, c)
	var hand := Vector2(3.5, al + 4.0)
	match pose:
		"hold":
			A.call(0, 1, 7, 19, top[0])
			A.call(0, 15, 15, 7, top[0])
			A.call(0, 20, 15, 2, top[1])
			A.call(13, 15, 2, 7, top[1])
			A.call(15, 14, 6, 8, skin[0])
			A.call(15, 20, 6, 2, skin[1])
			hand = Vector2(18, 16)
		"out":
			A.call(0, 1, 22, 7, top[0])
			A.call(0, 6, 22, 2, top[1])
			A.call(20, 1, 2, 7, top[1])
			A.call(22, 0, 6, 8, skin[0])
			A.call(22, 6, 6, 2, skin[1])
			hand = Vector2(25, 3)
		"up":
			A.call(0, -27, 7, 29, top[0])
			A.call(5, -27, 2, 29, top[1])
			A.call(0, -27, 7, 2, top[1])
			A.call(0, -34, 7, 7, skin[0])
			A.call(5, -34, 2, 7, skin[1])
			hand = Vector2(3.5, -31)
		"thumb", "fist", "peace":
			A.call(0, 1, 12, 7, top[0])
			A.call(0, 6, 12, 2, top[1])
			A.call(6, -16, 7, 19, top[0])
			A.call(11, -16, 2, 19, top[1])
			A.call(6, -16, 7, 2, top[1])
			A.call(5, -23, 9, 7, skin[0])
			A.call(5, -18, 9, 2, skin[1])
			if pose == "thumb":
				A.call(7, -28, 3, 5, skin[0])
				A.call(9, -28, 1, 5, skin[1])
			elif pose == "peace":
				A.call(6, -30, 2, 7, skin[0])
				A.call(10, -30, 2, 7, skin[0])
			hand = Vector2(9, -20)
		"scratch":
			A.call(0, 1, 9, 7, top[0])
			A.call(2, -14, 7, 17, top[0])
			A.call(7, -14, 2, 17, top[1])
			A.call(-3, -20, 11, 6, skin[0])
			A.call(-3, -16, 11, 2, skin[1])
			hand = Vector2(0, -18)
		_:
			A.call(0, 1, 7, al - 2.0, top[0])
			A.call(5, 1, 2, al - 2.0, top[1])
			A.call(0, al - 2.0, 7, 2, top[1])
			A.call(0, al, 7, 7, skin[0])
			A.call(5, al, 2, 7, skin[1])
	if hold == "":
		return
	var hx := x0 + hand.x if side > 0 else x0 - hand.x
	_hold(hold, hx, ys + hand.y)


## What a hand holds, centred on (hx, hy) in local px.
func _hold(what: String, hx: float, hy: float) -> void:
	match what:
		"kebab", "kebab_bit":
			_food(hx, hy, what == "kebab_bit")
		"wraps3":
			_wrap(hx - 7, hy - 1, false)
			_wrap(hx + 7, hy - 1, false)
			_wrap(hx, hy - 5, false)
		"bag":
			_q(hx - 1, hy - 1, 3, 4, KRAFT[1])
			_band(hx - 6, hy + 2, 12, 14, KRAFT, 3, 1)
			_detail(true)
			_q(hx - 6, hy + 2, 12, 2, KRAFT[1])
			_q(hx - 2, hy + 8, 4, 3, RED)
			_q(hx - 1, hy + 9, 2, 1, WHITE)
			_detail(false)
		"phone":
			_q(hx - 3, hy - 9, 6, 11, INK)
			_detail(true)
			_q(hx - 2, hy - 8, 4, 8, Color("#4f7fd8"))
			_q(hx - 2, hy - 8, 1, 2, Color("#9ab4f8"))
			_detail(false)
		"phone_up":
			_q(hx - 4, hy - 13, 8, 12, INK)
			_detail(true)
			_q(hx - 3, hy - 12, 6, 9, Color("#4f7fd8"))
			_q(hx - 1, hy - 12, 2, 1, Color("#16191d"))
			_q(hx - 3, hy - 12, 1, 3, Color("#9ab4f8"))
			_detail(false)
		"gimbal":
			_q(hx - 2, hy - 3, 4, 13, Color("#2a2e34"))
			_q(hx - 1, hy - 11, 2, 9, Color("#4a4e58"))
			_q(hx - 3, hy - 12, 6, 2, Color("#2a2e34"))
			_q(hx - 1, hy - 19, 15, 8, INK)
			_detail(true)
			_q(hx, hy - 18, 13, 6, Color("#3a4a6a"))
			_q(hx + 11, hy - 17, 1, 1, Color("#9ab4f8"))
			_q(hx - 1, hy + 2, 4, 1, Color("#6b737a"))
			if fmod(_t, 1.0) < 0.6:
				_q(hx + 1, hy - 17, 1, 1, Color("#ff4f6d"))
			_detail(false)


## What he ordered, in the hand (the Fable critique: he ate a wrap whatever was bought): the bun in
## its napkin, the wrap, the open box with a fork, the XXL wrap twice as long.
func _food(hx: float, hy: float, bit: bool) -> void:
	match tasting.dish if tasting != null else "wrap":
		"bun":
			_bun(hx, hy, bit)
		"box":
			_box(hx, hy, bit)
		"xxl":
			_wrap(hx, hy, bit, 2.0)
		_:
			_wrap(hx, hy, bit)


## The kebab in a bun: the napkin, the bottom half, the filling spilling at the sides, the domed top
## with sesame; `bit` takes a bite out of its far top corner.
func _bun(hx: float, hy: float, bit: bool) -> void:
	_band(hx - 5, hy - 2, 10, 6, PAPER, 2, 1)
	_band(hx - 5, hy - 6, 10, 4, BUN, 2, 1)
	_q(hx - 6, hy - 9, 12, 3, MEAT)
	_band(hx - 5, hy - 13, 10 if not bit else 6, 4, BUN, 2, 1)
	_q(hx - 3, hy - 15, 6 if not bit else 3, 2, BUN[0])
	_detail(true)
	_q(hx - 6, hy - 9, 3, 1, LETTUCE)
	_q(hx + 3, hy - 9, 3, 1, LETTUCE)
	_q(hx - 1, hy - 8, 2, 1, TOMATO)
	_q(hx + 4, hy - 7, 1, 2, SAUCE)
	_q(hx - 3, hy - 14, 4, 1, BUN[2])
	_q(hx - 2, hy - 12, 1, 1, PAPER[2])
	_q(hx + 1, hy - 13, 1, 1, PAPER[2])
	_q(hx - 5, hy + 1, 10, 1, PAPER[1])
	if bit:
		_q(hx + 1, hy - 13, 3, 3, MEAT)
		_q(hx + 1, hy - 13, 3, 1, LETTUCE)
	_detail(false)


## The open box: kraft, the lid up behind, the meat and fries on top, a white fork stuck in.
func _box(hx: float, hy: float, bit: bool) -> void:
	_band(hx - 7, hy - 12, 14, 5, KRAFT, 2, 1)
	_q(hx - 6, hy - 9, 12, 3 if not bit else 2, MEAT)
	_band(hx - 7, hy - 6, 14, 8, KRAFT, 3, 1)
	_q(hx + 2, hy - 17, 1, 9, PAPER[0])
	_detail(true)
	_q(hx - 7, hy - 6, 14, 1, KRAFT[2])
	_q(hx - 5, hy - 9, 3, 1, LETTUCE)
	_q(hx - 1, hy - 9, 2, 1, Color("#f2c84a"))
	_q(hx + 3, hy - 8, 2, 1, Color("#f2c84a"))
	_q(hx - 3, hy - 8, 1, 1, TOMATO)
	_q(hx + 1, hy - 18, 3, 2, PAPER[0])
	_q(hx - 2, hy - 2, 4, 2, RED)
	_detail(false)


## The wrap: foil below, the tortilla with grill marks, the filling at the top and a sauce drip;
## `bit` takes a bite out of its top; `long` stretches it (the XXL).
func _wrap(hx: float, hy: float, bit: bool, long := 1.0) -> void:
	var ex := roundf(11.0 * (long - 1.0))
	hy -= ex * 0.5
	_band(hx - 4, hy - 1 + ex, 8, 6, FOIL, 2, 1)
	_band(hx - 4, hy - 12, 8, 11 + ex, WRAP, 2, 1)
	if bit:
		_q(hx - 4, hy - 16, 4, 4, MEAT)
		_q(hx, hy - 13, 4, 1, MEAT)
	else:
		_q(hx - 4, hy - 17, 8, 5, MEAT)
	_detail(true)
	_q(hx - 4, hy + 2, 8, 1, FOIL[1])
	_q(hx - 2, hy, 1, 2, FOIL[2])
	_q(hx - 4, hy - 9, 6, 1, WRAP[1])
	_q(hx - 3, hy - 5, 6, 1, WRAP[1])
	if bit:
		_q(hx - 4, hy - 16, 3, 1, LETTUCE)
		_q(hx - 2, hy - 14, 2, 1, TOMATO)
		_q(hx + 1, hy - 13, 2, 1, LETTUCE)
		_q(hx - 3, hy - 12, 1, 2, SAUCE)
	else:
		_q(hx - 4, hy - 17, 8, 2, LETTUCE)
		_q(hx - 3, hy - 15, 2, 1, TOMATO)
		_q(hx + 1, hy - 14, 2, 1, TOMATO)
		_q(hx - 1, hy - 17, 1, 1, Color("#9ae06a"))
		_q(hx + 1, hy - 12, 1, 3, SAUCE)
	_detail(false)


## A head: `cx` the local centre x, `hy` its top, `hh` its height. Keys of `fc`: eyes ("open",
## "blink", "happy" (shut in bliss), "wide", "worried"), brows (px up), tilt (worried brows), mouth
## ("rest", "smile", "grin", "a", "o", "chew_a", "chew_b", "smack", "tight", "squiggle"), look (-1
## away, 1 toward the facing side), blush, sweat, freckles, talk ([the line, its time]).
func _head(cx: float, hy: float, hh: float, skin: Array, hair: String, hair_c: Color, fc: Dictionary, beard := false) -> void:
	var hw := 28.0
	var l := cx - hw * 0.5
	# the ear on the far side, the skull, the jaw
	_q(l - 3, hy + 12, 4, 8, skin[0])
	_detail(true)
	_q(l - 2, hy + 14, 1, 4, skin[1])
	_detail(false)
	_q(l + 1, hy, hw - 2, hh - 4, skin[0])
	_q(l, hy + 3, hw, hh - 10, skin[0])
	_q(l + 2, hy + hh - 4, hw - 4, 2, skin[0])
	_q(l + 4, hy + hh - 2, hw - 8, 2, skin[0])
	_detail(true)
	var sl := _sx(l, hw)
	_qs(sl + hw - 4, hy + 3, 4, hh - 10, skin[1])
	_qs(sl + hw - 5, hy + hh - 7, 3, 3, skin[1])
	_qs(sl + hw - 7, hy + hh - 4, 4, 2, skin[1])
	_qs(sl, hy + 4, 2, hh - 14, skin[2])
	_qs(sl + 2, hy + 1, 6, 2, skin[2])
	_detail(false)
	# the eyes, toward the facing side
	var ey := hy + 13.0
	var look: int = fc.get("look", 1)
	var eyes: String = fc.get("eyes", "open")
	var brows: float = fc.get("brows", 0.0)
	if eyes == "worried":
		brows += 1.0
	_detail(true)
	for ex: float in [cx - 6.0, cx + 6.0]:
		match eyes:
			"blink":
				_q(ex - 1, ey + 2, 4, 1, OUT)
			"happy":
				_q(ex - 1, ey + 1, 4, 1, OUT)
				_q(ex - 2, ey + 2, 1, 1, OUT)
				_q(ex + 3, ey + 2, 1, 1, OUT)
			"wide":
				_q(ex - 1, ey - 1, 5, 5, WHITE)
				_q(ex + (1.0 if look >= 0 else 0.0), ey, 2, 3, OUT)
				_q(ex + (1.0 if look >= 0 else 0.0), ey, 1, 1, WHITE)
			_:
				_q(ex - 1, ey, 4, 4, WHITE)
				_q(ex + (1.0 if look > 0 else (-1.0 if look < 0 else 0.0)), ey, 2, 4, OUT)
				_q(ex + (1.0 if look > 0 else (-1.0 if look < 0 else 0.0)), ey, 1, 1, WHITE)
				_q(ex - 1, ey + 4, 4, 1, skin[1])
		# the brows: worried ones raise their inner ends
		var bc := hair_c if hair != "beanie" else Color("#6a3a24")
		var by := ey - 3.0 - brows
		if eyes == "worried" or bool(fc.get("tilt", false)):
			var inner := 1.0 if ex < cx else -1.0
			_q(ex - 1 + (2.0 if inner > 0 else 0.0), by - 1, 2, 1, bc)
			_q(ex - 1 + (0.0 if inner > 0 else 2.0), by, 2, 1, bc)
		else:
			_q(ex - 1, by, 4, 1, bc)
	# the nose: a shade group toward the facing side, a lit pixel
	_q(cx + 1, ey + 3, 3, 5, skin[1])
	_q(cx + 1, ey + 3, 1, 2, skin[2])
	_q(cx + 3, ey + 7, 2, 1, skin[1].darkened(0.15))
	if bool(fc.get("blush", false)):
		_q(cx - 9, ey + 6, 4, 1, BLUSH)
		_q(cx + 6, ey + 6, 4, 1, BLUSH)
	if bool(fc.get("freckles", false)):
		for fp: Vector2 in [Vector2(-8, 7), Vector2(-6, 8), Vector2(7, 7), Vector2(9, 8)]:
			_q(cx + fp.x, ey + fp.y, 1, 1, skin[1].darkened(0.1))
	_detail(false)
	# the hair (or the cap) and the beard
	match hair:
		"cap_fwd":
			# short neat hair above the ear, a baseball cap hugging the head, its bill forward
			_q(l - 1, hy + 2, 4, 6, HAIR_K)
			_q(l, hy - 5, hw, 7, CAP[0])
			_q(l + 2, hy - 7, hw - 4, 2, CAP[0])
			_q(l + 6, hy - 8, hw - 12, 1, CAP[0])
			_q(l + hw - 4, hy, 13, 2, CAP[0])
			_detail(true)
			_qs(_sx(l, hw) + 2, hy - 6, 8, 1, CAP[2])
			_qs(_sx(l, hw) + 1, hy - 5, 1, 4, CAP[2])
			_q(l + hw * 0.5 - 1, hy - 9, 2, 1, CAP[2])
			_q(l + hw * 0.5 + 2, hy - 7, 1, 7, CAP[1])
			_q(l + hw - 4, hy, 13, 1, CAP[2])
			_q(l + 3, hy + 2, hw - 6, 1, skin[1])
			_q(l + hw - 2, hy + 2, 8, 1, Color(0, 0, 0, 0.18))
			_detail(false)
		"messy":
			_q(l - 1, hy - 4, hw + 2, 8, hair_c)
			_q(l - 3, hy, 4, 11, hair_c)
			_q(l + 2, hy - 6, 4, 2, hair_c)
			_q(l + 8, hy - 7, 5, 3, hair_c)
			_q(l + 16, hy - 6, 5, 2, hair_c)
			_q(l + hw - 4, hy + 3, 6, 3, hair_c)
			_detail(true)
			_q(l + 3, hy - 3, 6, 1, hair_c.lightened(0.25))
			_q(l + 11, hy - 6, 2, 1, hair_c.lightened(0.25))
			_q(l + 12, hy + 3, 8, 1, hair_c.darkened(0.2))
			_detail(false)
		"short":
			_q(l - 1, hy - 3, hw + 2, 6, hair_c)
			_q(l - 3, hy + 1, 4, 9, hair_c)
			_q(l + hw - 7, hy + 3, 8, 2, hair_c)
			_detail(true)
			_q(l + 2, hy - 2, 10, 1, hair_c.lightened(0.3))
			_q(l + 4, hy + 2, 12, 1, hair_c.darkened(0.2))
			_detail(false)
		"beanie":
			_q(l - 3, hy + 4, 4, 14, Color("#6a3a24"))
			_q(l - 2, hy - 7, hw + 4, 12, MUSTARD[0])
			_q(l - 2, hy + 2, hw + 4, 4, MUSTARD[1])
			_q(cx - 3, hy - 12, 6, 5, MUSTARD[2])
			_detail(true)
			for rx in range(int(l), int(l + hw + 2), 3):
				_q(rx, hy - 6, 1, 8, MUSTARD[1])
			_q(cx - 2, hy - 12, 2, 1, WHITE)
			_detail(false)
	if beard:
		# a short trimmed beard along the jaw line, the moustache
		_detail(true)
		_q(l, hy + 10, 2, hh - 16, hair_c)
		_q(l + hw - 2, hy + 10, 2, hh - 16, hair_c)
		_q(l + 1, hy + hh - 6, 3, 2, hair_c)
		_q(l + hw - 4, hy + hh - 6, 3, 2, hair_c)
		_q(l + 2, hy + hh - 4, hw - 4, 2, hair_c)
		_q(l + 4, hy + hh - 2, hw - 8, 2, hair_c)
		_q(cx - 3, hy + 20, 9, 1, hair_c)
		_q(l + 6, hy + hh - 4, 1, 1, BEARD_L)
		_q(l + 14, hy + hh - 2, 1, 1, BEARD_L)
		_q(l + 20, hy + hh - 4, 1, 1, BEARD_L)
		_detail(false)
	# the mouth, over the beard
	var mouth: String = fc.get("mouth", "rest")
	var talk: Array = fc.get("talk", [])
	if not talk.is_empty():
		mouth = _talk_mouth(str(talk[0]), float(talk[1]), mouth)
	_mouth(cx + 1.0, hy + 23.0, mouth)
	_detail(true)
	if bool(fc.get("sweat", false)):
		_q(l + 1, hy + 4, 1, 2, SWEAT)
		_q(l, hy + 6, 3, 2, SWEAT)
	_detail(false)


## A mouth at (mx, my) local px.
func _mouth(mx: float, my: float, m: String) -> void:
	_detail(true)
	match m:
		"smile":
			_q(mx - 3, my + 1, 6, 1, MOUTH)
			_q(mx - 4, my, 1, 1, MOUTH)
			_q(mx + 3, my, 1, 1, MOUTH)
		"grin":
			_q(mx - 5, my - 1, 10, 4, MOUTH)
			_q(mx - 4, my - 1, 8, 1, TEETH)
			_q(mx - 2, my + 2, 4, 1, TONGUE)
			_q(mx - 6, my - 2, 1, 1, MOUTH)
			_q(mx + 5, my - 2, 1, 1, MOUTH)
		"a":
			_q(mx - 2, my - 1, 5, 4, MOUTH)
			_q(mx - 1, my - 1, 3, 1, TEETH)
			_q(mx - 1, my + 2, 3, 1, TONGUE)
		"o":
			_q(mx - 1, my - 1, 3, 3, MOUTH)
		"chew_a":
			_q(mx - 3, my, 6, 2, MOUTH)
			_q(mx + 5, my - 3, 2, 3, Color(1, 1, 1, 0.25))
		"chew_b":
			_q(mx - 2, my + 1, 4, 1, MOUTH)
			_q(mx - 7, my - 3, 2, 3, Color(1, 1, 1, 0.25))
		"smack":
			_q(mx - 4, my - 1, 8, 3, MOUTH)
			_q(mx - 3, my + 1, 3, 1, TONGUE)
			_q(mx + 2, my - 1, 1, 1, WHITE)
		"tight":
			_q(mx - 3, my + 1, 6, 1, MOUTH)
		"squiggle":
			_q(mx - 4, my, 2, 1, MOUTH)
			_q(mx - 2, my + 1, 2, 1, MOUTH)
			_q(mx, my, 2, 1, MOUTH)
			_q(mx + 2, my + 1, 2, 1, MOUTH)
		_:
			_q(mx - 3, my + 1, 5, 1, MOUTH)
	_detail(false)


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


## A hop of `h` px in hard steps (up, held, down).
func _hop(t: float, period: float, h: float) -> float:
	return h if fmod(t, period) < period * 0.5 else 0.0


func _you() -> void:
	var ph := tasting.phase
	var g := tasting.grade
	var t := tasting.t
	var face := {"look": 1, "mouth": "smile"}
	var front := "down"
	var back := "down"
	var hold_f := ""
	var bob := 0.0
	match ph:
		Tasting.Phase.CHEW:
			face["eyes"] = "worried"
			face["mouth"] = "tight"
			face["sweat"] = true
		Tasting.Phase.MLASK:
			face["eyes"] = "wide"
			face["brows"] = 2.0
			face["mouth"] = "o"
			bob = 3.0 if t < 0.3 else 0.0
		Tasting.Phase.DRUM:
			face["mouth"] = "tight"
			face["eyes"] = "worried"
		Tasting.Phase.GRADE:
			if tasting.perfect:
				face["eyes"] = "happy"
				face["mouth"] = "grin"
				front = "up"
				back = "up"
				bob = _hop(t, 0.36, 3.0)
			elif g >= 8.0:
				face["mouth"] = "grin"
				front = "fist"
			elif g < 7.5:
				face["eyes"] = "worried"
				face["mouth"] = "squiggle"
		Tasting.Phase.FAN, Tasting.Phase.SELFIE, Tasting.Phase.CARD:
			face["mouth"] = "grin" if g >= 8.0 else "smile"
			if ph == Tasting.Phase.SELFIE and g >= 8.0:
				front = "thumb"
	_person({"x": _you_x(), "f": 1, "kind": "you", "top": TEAL, "legs": JEANS, "shoe": SOLE_D, "sole": Color("#c9c4b8"),
			"skin": SKIN_MID, "tw": 28.0, "th": 64.0, "ll": 64.0, "hair": "messy", "hair_c": Color("#5a3a24"), "face": face,
			"front": front, "back": back, "hold_f": hold_f, "hold_b": "bag" if ph <= Tasting.Phase.HELLO and back == "down" else "", "bob": bob, "seed": 0.4})


func _kebabulo() -> void:
	var ph := tasting.phase
	var g := tasting.grade
	var t := tasting.t
	var f := 1 if ph == Tasting.Phase.FAN or ph == Tasting.Phase.SELFIE else -1
	var face := {"look": 1, "mouth": "grin"}
	var front := "hold"
	var back := "down"
	var hold_f := "kebab_bit"
	var bob := 0.0
	match ph:
		Tasting.Phase.IN, Tasting.Phase.HELLO:
			# empty-handed, a thumb up: the bag is still in the player's hand (the handover)
			hold_f = ""
			front = "thumb"
			face["brows"] = 1.0
		Tasting.Phase.CHEW, Tasting.Phase.MLASK:
			face["eyes"] = "happy"
			face["mouth"] = "chew_a" if fmod(t, 0.32) < 0.16 else "chew_b"
			face["blush"] = true
		Tasting.Phase.VERDICT:
			front = "up" if t < 0.35 else "hold"
			face["brows"] = 1.0
			face["mouth"] = "smile"
		Tasting.Phase.DRUM:
			face["look"] = 1 if fmod(t, 0.6) < 0.3 else -1
			face["mouth"] = "tight"
			face["brows"] = 1.0
		Tasting.Phase.GRADE:
			if tasting.perfect:
				face["eyes"] = "wide" if t < 0.6 else "happy"
				face["mouth"] = "smack" if t < 0.6 else "grin"
				face["blush"] = true
				front = "up"
				back = "up"
				bob = _hop(t, 0.4, 3.0)
			elif g >= 8.0:
				face["brows"] = 1.0
				back = "fist"
			elif g >= 7.5:
				back = "thumb"
				face["mouth"] = "smile"
			else:
				face["eyes"] = "worried"
				face["mouth"] = "squiggle"
				back = "scratch"
		Tasting.Phase.FAN:
			if tasting.fan_i == 0:
				face["brows"] = 2.0 if t < 0.4 else 0.0
				face["mouth"] = "o" if t < 0.4 else "smile"
			else:
				front = "thumb"
				hold_f = ""
		Tasting.Phase.SELFIE:
			face["eyes"] = "happy" if t > 0.55 else "open"
			face["look"] = -1
			back = "thumb"
		Tasting.Phase.CARD:
			hold_f = "wraps3"
	var talk := _talk_of("kebabulo")
	if not talk.is_empty():
		face["talk"] = talk
	_person({"x": _kebabulo_x(), "f": f, "kind": "kebabulo", "top": HOODIE, "legs": BLACK_PANTS, "shoe": TRAINER, "sole": SOLE_L,
			"skin": SKIN_LIGHT, "tw": 28.0, "th": 70.0, "ll": 68.0, "hair": "cap_fwd", "hair_c": BEARD, "face": face,
			"front": front, "back": back, "hold_f": hold_f, "bob": bob, "seed": 1.3})


func _zbyszek() -> void:
	var ph := tasting.phase
	var t := tasting.t
	var face := {"look": 1, "mouth": "smile"}
	var back := "down"
	match ph:
		Tasting.Phase.MLASK:
			face["eyes"] = "wide"
			face["brows"] = 2.0
			face["mouth"] = "o"
		Tasting.Phase.DRUM:
			back = "fist" if fmod(t, 0.2) < 0.1 else "down"
			face["eyes"] = "wide"
		Tasting.Phase.GRADE, Tasting.Phase.SELFIE:
			if tasting.grade >= 8.0:
				face["mouth"] = "grin"
				back = "thumb"
			elif tasting.grade < 7.5:
				face["mouth"] = "tight"
	var talk := _talk_of("zbyszek")
	if not talk.is_empty():
		face["talk"] = talk
	_person({"x": _zbyszek_x(), "f": -1, "kind": "zbyszek", "top": CHARCOAL, "legs": DARK_JEANS, "shoe": Color("#c9d2d8"), "sole": Color("#6b737a"),
			"skin": SKIN_FAIR, "tw": 28.0, "th": 64.0, "ll": 64.0, "hair": "short", "hair_c": Color("#e2c060"), "face": face,
			"front": "out", "back": back, "hold_f": "gimbal", "bob": 1.0 if ph == Tasting.Phase.CHEW else 0.0, "seed": 2.1})


## The fan: a teen in a raspberry puffer and a mustard beanie; walks in from the right, asks, hops at
## the yes, the selfie with the phone held up and a peace sign, then walks off.
func _fan() -> void:
	var ph := tasting.phase
	var t := tasting.t
	var walking := ph == Tasting.Phase.CARD or _fan_x > _fan_goal() + 0.5
	var face := {"eyes": "wide", "look": 1, "blush": true, "freckles": true, "mouth": "smile"}
	var front := "down"
	var back := "down"
	var hold_f := "phone"
	var bob := 0.0
	if ph == Tasting.Phase.FAN and tasting.fan_i == 0 and t > 1.4:
		face["look"] = -1
		face["eyes"] = "open"
		back = "scratch"
	if ph == Tasting.Phase.FAN and tasting.fan_i == 1:
		face["eyes"] = "happy"
		face["mouth"] = "grin"
		bob = 3.0 if t < 0.3 else 0.0
	if ph == Tasting.Phase.SELFIE:
		face["mouth"] = "grin"
		face["eyes"] = "happy" if t > 0.55 else "open"
		front = "up"
		hold_f = "phone_up"
		back = "peace"
	if ph == Tasting.Phase.CARD:
		face["mouth"] = "grin"
		face["eyes"] = "happy"
	var talk := _talk_of("fan")
	if not talk.is_empty():
		face["talk"] = talk
	_person({"x": roundf(_fan_x), "f": 1 if ph == Tasting.Phase.CARD else -1, "kind": "fan", "top": PUFFER, "legs": LIGHT_JEANS, "shoe": TRAINER,
			"sole": SOLE_L, "skin": SKIN_FAIR, "tw": 26.0, "th": 54.0, "ll": 54.0, "hh": 28.0, "hair": "beanie", "face": face,
			"front": front, "back": back, "hold_f": hold_f, "bob": bob, "walk": int(_t * 6.0) % 2 if walking else -1, "seed": 3.3})


## Where the fan's phone is for the selfie (units): her raised hand on her front side.
func _fan_lens() -> Vector2:
	var tw := 26.0
	var ys := -(7.0 + 54.0 + 54.0)
	return Vector2(roundf(_fan_x) - (tw * 0.5 + 3.5) / PX, FEET + (ys - 31.0 - 8.0) / PX)


# --- the fx layer ---------------------------------------------------------------------------------

func _draw_fx() -> void:
	_use(_fx)
	if tasting == null:
		return
	match tasting.phase:
		Tasting.Phase.CHEW:
			_close_up()
		Tasting.Phase.MLASK:
			_mlask_panel()
	if tasting.phase != Tasting.Phase.MLASK:
		_floaters_draw()
	_bits_draw()


## The comic close-up for the bite: an ink-edged panel slams in from the right, his big face
## chewing with his eyes shut, the kebab at his mouth, crumbs.
func _close_up() -> void:
	var t := tasting.t
	var pw := roundf(W * 0.40)
	var ph := 132.0
	var slide := 0.0 if Access.calm else clampf(1.0 - t / 0.15, 0.0, 1.0)
	var x := roundf(W - pw - 18.0 + slide * (pw + 20.0))
	var y := 34.0
	_u(x - 2, y - 2, pw + 4, ph + 4, INK)
	_u(x - 1, y - 1, pw + 2, ph + 2, Kit.LINE)
	_u(x, y, pw, ph, Color("#f2a562"))
	# halftone dots in the corners, speed dashes round the head
	var dy := 2.0
	while dy < 30.0:
		var dx := 2.0 + fmod(dy, 4.0)
		while dx < pw * 0.3:
			_u(x + dx, y + dy, 1, 1, Color("#f6c07a"))
			_u(x + pw - dx - 1, y + ph - dy - 1, 1, 1, Color("#e08a52"))
			dx += 4.0
		dy += 2.0
	var cx := x + pw * 0.5
	var cy := y + ph * 0.5
	for i in 14:
		var a := float(i) / 14.0 * TAU + floorf(_t * 4.0) * 0.05
		var r0 := 0.40 + 0.04 * float(i % 3)
		var px0 := roundf(cx + cos(a) * pw * r0)
		var py0 := roundf(cy + sin(a) * ph * r0)
		if px0 > x + 4 and px0 < x + pw - 8 and py0 > y + 3 and py0 < y + ph - 4:
			_u(px0, py0, 5 if absf(cos(a)) > 0.5 else 1, 1 if absf(cos(a)) > 0.5 else 4, Color("#ffe0b0"))
	var st := {"eyes": "bliss", "mouth": "chew_a" if fmod(t, 0.32) < 0.16 else "chew_b", "blush": true, "brows": 3.0,
			"kebab": true, "shoulders": true}
	if t < 0.25:
		st["eyes"] = "open"
		st["mouth"] = "bite"
		st["brows"] = 0.0
	var jaw := 1.0 if str(st["mouth"]) == "chew_a" else 0.0
	st["jaw"] = jaw
	_big_face(cx, y + 34.0, 2.0, st, Rect2(x, y, pw, ph))
	# crumbs falling
	for i in 6:
		var ct := fmod(t * 0.8 + i * 0.17, 1.0)
		var cpx := roundf(cx - 30.0 + i * 3.0)
		var cpy := roundf(y + 86.0 + ct * 40.0)
		if cpy < y + ph - 2.0:
			_u(cpx, cpy, 1, 1, WRAP[1])


## The MLASK (F 20:37, concept 3 "TRZY KADRY"), held and staged (Fable's critique 2026-11-26,
## section 2 rows 1-2): one full comic panel slams in with an overshoot, gold rays from below the
## centre and the giant word bouncing letter by letter at once; his face rises at MLASK_FACE_AT, big
## (MLASK_FACE scene px a face px, the panel's hero, over the word's lower third), in bliss with
## sauce drops; a dead hold; Zbyszek's small inset bottom left at MLASK_INSET_AT; the chat panel
## (the stream layer's) at MLASK_CHAT_AT and the caption strip under his face at MLASK_CAPTION_AT.
## No pigeon inset and no hearts in the panel. A hard cut back to the street after it.
func _mlask_panel() -> void:
	var t := tasting.t
	var drop := 0.0 if Access.calm else roundf((1.0 - _pop(t / 0.22)) * -70.0)
	var x0 := 4.0
	var y0 := 4.0 + drop
	var pw := W - 8.0
	var ph := 208.0
	_u(0, drop, W, H, Kit.VOID)
	_u(x0, y0, pw, ph, GOLD)
	_rays(x0, y0, pw, ph, Vector2(roundf(W * 0.5), y0 + 162.0))
	# the edge: 1 px LINE, the corners cut
	_u(x0 + 1, y0, pw - 2, 0.5, Kit.LINE)
	_u(x0 + 1, y0 + ph - 0.5, pw - 2, 0.5, Kit.LINE)
	_u(x0, y0 + 1, 0.5, ph - 2, Kit.LINE)
	_u(x0 + pw - 0.5, y0 + 1, 0.5, ph - 2, Kit.LINE)
	_mlask_word(y0, t)
	var ft := t - Tasting.MLASK_FACE_AT
	if ft >= 0.0 or Access.calm:
		# his face rising from the bottom edge over the word's lower third
		var k := MLASK_FACE / 2.0
		var rise := 1.0 if Access.calm else _pop(ft / 0.3, 1.2)
		var top := roundf(lerpf(250.0, MLASK_TOP, rise)) + drop
		_big_face(roundf(W * 0.5) - 8.0, top, MLASK_FACE, {"eyes": "bliss", "mouth": "grin", "blush": true, "brows": 3.0, "shoulders": true},
				Rect2(x0, y0, pw, ph))
		# sauce drops flying out
		var cx := roundf(W * 0.5) - 8.0
		var ct := maxf(ft, 0.0)
		for d: Vector2 in [Vector2(-43, 38), Vector2(43, 34), Vector2(-51, 54), Vector2(51, 58), Vector2(-63, 28), Vector2(63, 26)]:
			var sp := 1.0 + minf(ct, 0.8) * 0.6
			var p := Vector2(cx + d.x * k * sp, top + d.y * k - minf(ct, 0.8) * 10.0 + ct * ct * 14.0)
			if p.y > y0 + ph - 6.0:
				continue
			_u(roundf(p.x), roundf(p.y), 3, 3, SAUCE)
			_u(roundf(p.x) + 0.5, roundf(p.y) + 0.5, 1, 1, WHITE)
			_u(roundf(p.x) + 2, roundf(p.y) + 2.5, 1, 0.5, Color("#d8c8a8"))
	if t >= Tasting.MLASK_INSET_AT or Access.calm:
		_inset_zbyszek(10.0, MLASK_LOW - 50.0 + drop)


## Sixteen ray wedges from `c`, alternately GOLD and AMBER, the one straight up GOLD; stepped sides
## (two-unit rows).
func _rays(x0: float, y0: float, pw: float, ph: float, c: Vector2) -> void:
	var step := 2.0
	var y := y0
	while y < y0 + ph:
		var dy := y + step * 0.5 - c.y
		var cuts := PackedFloat32Array([x0, x0 + pw])
		for k in 16:
			var a := -PI * 0.5 + (float(k) + 0.5) * TAU / 16.0
			var sa := sin(a)
			if absf(sa) < 0.001 or signf(sa) != signf(dy):
				continue
			var xi := c.x + dy * cos(a) / sa
			if xi > x0 and xi < x0 + pw:
				cuts.append(roundf(xi))
		cuts.sort()
		for i in cuts.size() - 1:
			var a0 := cuts[i]
			var a1 := cuts[i + 1]
			if a1 - a0 < 0.5:
				continue
			var mid := (a0 + a1) * 0.5
			var ang := atan2(dy, mid - c.x) + PI * 0.5
			var wedge := int(floor(fposmod(ang + TAU / 32.0, TAU) / (TAU / 16.0)))
			if wedge % 2 == 1:
				_u(a0, y, a1 - a0, minf(step, y0 + ph - y), AMBER)
		y += step


## The giant MLASK! in the 5x7 font: red letters, an ink copy behind, the top row lighter, each
## letter at its own height and bouncing.
func _mlask_word(y0: float, t: float) -> void:
	var word := _w("mlask").to_upper()
	var sc := clampf(floorf((W - 70.0) / float(PixelFont.width(word))), 5.0, 11.0)
	var tw := PixelFont.width(word) * sc
	var x := roundf(W * 0.5 - tw * 0.5)
	var offs := [0.0, -4.0, 3.0, -3.0, 4.0, 0.0]
	var i := 0
	for ch in word:
		var cw := PixelFont.char_width(ch)
		if cw == 0:
			continue
		var land := 1.0 if Access.calm else _pop((t - i * 0.03) / 0.2, 1.4)
		var bounce := 0.0 if Access.calm else roundf(sin(t * 9.0 + i * 1.3) * 1.5)
		var ly := y0 + 20.0 + float(offs[i % offs.size()]) + bounce - roundf((1.0 - land) * 60.0)
		var px := PixelFont.pixels(ch)
		var top_row := 99
		for p: Vector2i in px:
			top_row = mini(top_row, p.y)
		for pass_i in 3:
			for p: Vector2i in px:
				var rx := x + p.x * sc
				var ry := ly + (p.y - PixelFont.BODY) * sc
				match pass_i:
					0:
						_u(rx + 3, ry + 3, sc, sc, INK)
					1:
						_u(rx, ry, sc, sc, RED)
					2:
						if p.y == top_row:
							_u(rx, ry, sc, minf(sc, 4.0), RED_L)
		x += (cw + PixelFont.GAP) * sc
		i += 1


func _inset(x: float, y: float, w: float, h: float, ground: Color) -> void:
	_u(x - 2, y - 2, w + 4, h + 4, Kit.VOID)
	_u(x - 1, y - 1, w + 2, h + 2, Kit.LINE)
	_u(x, y, w, h, ground)


## Zbyszek's inset, small (70 x 50; the critique: the hero's face is the panel's biggest thing):
## half his shocked face, his phone up with Kebabulo on its screen. Drawn on the 100 x 72 design.
func _inset_zbyszek(x0: float, y0: float) -> void:
	_inset(x0, y0, 70, 50, Kit.NIGHT2)
	var k := 0.7
	var Z := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var ax := roundf((x0 + (x - x0) * k) * PX) / PX
		var ay := roundf((y0 + (y - y0) * k) * PX) / PX
		_u(ax, ay, maxf(0.5, roundf((x + w - x0) * k * PX) / PX - (ax - x0)), maxf(0.5, roundf((y + h - y0) * k * PX) / PX - (ay - y0)), c)
	var x := x0
	var y := y0
	# the face: skin, hair, the brow up, the wide eye, the open mouth, a sweat drop
	Z.call(x + 8, y + 14, 36, 44, SKIN_FAIR[0])
	Z.call(x + 8, y + 14, 3, 44, SKIN_FAIR[2])
	Z.call(x + 8, y + 52, 36, 6, SKIN_FAIR[1])
	Z.call(x + 4, y + 26, 4, 12, SKIN_FAIR[0])
	Z.call(x + 5, y + 29, 2, 6, SKIN_FAIR[1])
	Z.call(x + 8, y + 6, 36, 10, Color("#e2c060"))
	Z.call(x + 8, y + 6, 36, 2, Color("#f2d880"))
	Z.call(x + 4, y + 10, 6, 16, Color("#e2c060"))
	Z.call(x + 18, y + 19, 16, 3, Color("#8a5a2a"))
	Z.call(x + 20, y + 25, 12, 12, WHITE)
	Z.call(x + 24, y + 29, 5, 5, INK)
	Z.call(x + 24, y + 29, 2, 2, WHITE)
	Z.call(x + 20, y + 37, 12, 1, SKIN_FAIR[1])
	Z.call(x + 36, y + 30, 6, 10, SKIN_FAIR[1])
	Z.call(x + 26, y + 44, 8, 8, MOUTH)
	Z.call(x + 27, y + 49, 6, 3, TONGUE)
	Z.call(x + 40, y + 18, 2, 4, CYAN)
	Z.call(x + 39, y + 21, 4, 2, CYAN)
	# the phone, held by four fingers, Kebabulo on its screen with REC
	Z.call(x + 47.5, y + 11.5, 35, 55, OUT)
	Z.call(x + 48, y + 12, 34, 54, INK)
	Z.call(x + 51, y + 16, 28, 44, Color("#4f7fd8"))
	Z.call(x + 51, y + 16, 28, 14, Color("#f2a562"))
	Z.call(x + 59, y + 30, 12, 4, VEST[0])
	Z.call(x + 60, y + 34, 10, 9, SKIN_LIGHT[0])
	Z.call(x + 58, y + 29, 14, 3, CAP[0])
	Z.call(x + 62, y + 39, 6, 3, BEARD)
	Z.call(x + 63, y + 40, 4, 1, WHITE)
	Z.call(x + 56, y + 43, 18, 17, VEST[0])
	Z.call(x + 63, y + 43, 4, 4, HOODIE[0])
	Z.call(x + 53, y + 18, 2, 2, Color("#ff4f6d"))
	Z.call(x + 64, y + 62, 3, 2, Color("#3a3e46"))
	for f in 4:
		Z.call(x + 43.5, y + 21.5 + f * 11.0, 7, 9, OUT)
		Z.call(x + 44, y + 22 + f * 11.0, 6, 8, SKIN_FAIR[0])
		Z.call(x + 44, y + 28 + f * 11.0, 6, 2, SKIN_FAIR[1])


## Kebabulo's face, big (the close-up, the MLASK): `cx` its centre, `top` the forehead under the
## cap (units), `s` scene px a face px (64 face px wide). Keys of `st`: eyes ("open", "bliss"),
## mouth ("grin", "chew_a", "chew_b", "bite"), brows (face px up), blush, jaw (px down), kebab,
## shoulders. `clip` keeps it inside its panel (rows below it are cut).
func _big_face(cx: float, top: float, s: float, st: Dictionary, clip: Rect2) -> void:
	_fig(cx, top, 1, s)
	_org.x -= 32.0 * s
	var jaw: float = st.get("jaw", 0.0)
	var bottom := (clip.end.y - top) * PX / s
	var B := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var h2 := minf(h, bottom - y)
		if h2 > 0.0:
			_q(x, y, w, h2, c)
	if bool(st.get("shoulders", false)):
		# the vest's shoulders, the hood behind the neck, the hoodie's V and strings
		B.call(-34, 68, 132, 60, VEST[0])
		_detail(true)
		for qy: float in [76.0, 86.0, 96.0]:
			B.call(-34, qy, 132, 1, VEST[1])
			B.call(-34, qy - 1.0, 60, 1, VEST[2])
		B.call(84, 68, 14, 60, VEST[1])
		_detail(false)
		B.call(6, 58, 52, 10, HOODIE[0])
		B.call(48, 58, 10, 10, HOODIE[1])
		B.call(6, 58, 52, 2, HOODIE[2])
		for v in 5:
			B.call(20 + v * 3, 64 + v * 4, 24 - v * 6, 4, HOODIE[0])
		_detail(true)
		B.call(24, 70, 2, 16, TRAINER)
		B.call(38, 70, 2, 16, TRAINER)
		B.call(31, 68, 1, 40, Color("#6b737a"))
		_detail(false)
	B.call(20, 52 + jaw, 24, 10, SKIN_LIGHT[1])
	# the ears, the head (rounded at the jaw), its light and shade
	B.call(-5, 20, 6, 14, SKIN_LIGHT[0])
	B.call(63, 20, 6, 14, SKIN_LIGHT[1])
	B.call(2, 0, 60, 2, SKIN_LIGHT[0])
	B.call(0, 2, 64, 44, SKIN_LIGHT[0])
	B.call(1, 46, 62, 4 + jaw, SKIN_LIGHT[0])
	B.call(3, 50 + jaw, 58, 4, SKIN_LIGHT[0])
	B.call(7, 54 + jaw, 50, 3, SKIN_LIGHT[0])
	B.call(12, 57 + jaw, 40, 2, SKIN_LIGHT[0])
	_detail(true)
	B.call(-3, 23, 2, 8, SKIN_LIGHT[1])
	B.call(65, 23, 2, 8, SKIN_LIGHT[1].darkened(0.1))
	B.call(56, 4, 8, 42, SKIN_LIGHT[1])
	B.call(54, 46, 8, 6 + jaw, SKIN_LIGHT[1])
	B.call(0, 6, 3, 30, SKIN_LIGHT[2])
	B.call(4, 3, 20, 2, SKIN_LIGHT[2])
	B.call(2, 0, 60, 3, SKIN_LIGHT[1])
	_detail(false)
	# short neat hair at the temples, a baseball cap worn forward: the crown hugging the head, the
	# bill seen from the front (its lit top, its edge lower in the middle), its shadow on the brow
	B.call(-1, 2, 4, 12, HAIR_K)
	B.call(61, 2, 4, 12, HAIR_K)
	B.call(0, -10, 64, 10, CAP[0])
	B.call(4, -14, 56, 4, CAP[0])
	B.call(12, -17, 40, 3, CAP[0])
	B.call(29, -19, 6, 2, CAP[0])
	B.call(0, 0, 64, 3, CAP[0])
	B.call(6, 0, 52, 6, CAP[0])
	B.call(11, 6, 42, 2, CAP[0])
	_detail(true)
	B.call(7, -15, 16, 2, CAP[2])
	B.call(2, -11, 3, 9, CAP[2])
	B.call(31, -18, 2, 18, CAP[1])
	B.call(14, -14, 1, 14, CAP[1])
	B.call(49, -14, 1, 14, CAP[1])
	B.call(54, -12, 10, 12, CAP[1])
	B.call(6, 0, 52, 4, Color("#3e3d4c"))
	B.call(8, 0, 24, 1, Color("#5e5d70"))
	B.call(6, 4, 52, 1, CAP[2])
	B.call(11, 7, 42, 1, CAP[1])
	B.call(3, 3, 3, 4, SKIN_LIGHT[1])
	B.call(58, 3, 3, 4, SKIN_LIGHT[1])
	B.call(4, 8, 56, 2, SKIN_LIGHT[1])
	_detail(false)
	# the brows, the eyes, the nose, the blush
	var brows: float = st.get("brows", 0.0)
	_detail(true)
	B.call(10, 13 - brows, 16, 3, BEARD)
	B.call(38, 13 - brows, 16, 3, BEARD)
	match str(st.get("eyes", "open")):
		"bliss":
			for ex: float in [12.0, 40.0]:
				B.call(ex + 2, 22, 10, 3, OUT)
				B.call(ex - 1, 25, 3, 3, OUT)
				B.call(ex + 12, 25, 3, 3, OUT)
		_:
			for ex: float in [12.0, 40.0]:
				B.call(ex, 19, 13, 1, OUT)
				B.call(ex, 20, 13, 9, WHITE)
				B.call(ex + 3, 20, 7, 9, Color("#5a3a24"))
				B.call(ex + 4, 22, 5, 5, OUT)
				B.call(ex + 4, 21, 2, 2, WHITE)
				B.call(ex + 8, 25, 1, 1, WHITE)
				B.call(ex, 29, 13, 1, SKIN_LIGHT[1])
	B.call(27, 26, 10, 12, SKIN_LIGHT[1])
	B.call(28, 26, 2, 9, SKIN_LIGHT[2])
	B.call(28, 37, 3, 1, SKIN_LIGHT[1].darkened(0.2))
	B.call(33, 37, 3, 1, SKIN_LIGHT[1].darkened(0.2))
	B.call(35, 30, 2, 6, SKIN_LIGHT[1].darkened(0.1))
	if bool(st.get("blush", false)):
		B.call(5, 34, 8, 3, BLUSH)
		B.call(51, 34, 8, 3, BLUSH)
		B.call(6, 34, 2, 1, Color("#ffb0a0"))
		B.call(52, 34, 2, 1, Color("#ffb0a0"))
	_detail(false)
	# the short trimmed beard along the jaw line, stubble on the cheeks, the neat moustache
	_detail(true)
	B.call(-1, 14, 3, 22, BEARD)
	B.call(62, 14, 3, 22, BEARD)
	B.call(0, 36, 4, 12 + jaw, BEARD)
	B.call(60, 36, 4, 12 + jaw, BEARD)
	B.call(2, 47 + jaw, 6, 4, BEARD)
	B.call(56, 47 + jaw, 6, 4, BEARD)
	B.call(5, 51 + jaw, 54, 3, BEARD)
	B.call(8, 54 + jaw, 48, 3, BEARD)
	B.call(13, 57 + jaw, 38, 2, BEARD)
	for bp: Vector2 in [Vector2(4, 40), Vector2(6, 44), Vector2(9, 47), Vector2(58, 40), Vector2(56, 44), Vector2(53, 47),
			Vector2(14, 50), Vector2(50, 50), Vector2(22, 52), Vector2(42, 52)]:
		B.call(bp.x, bp.y + (jaw if bp.y > 44.0 else 0.0), 1, 1, BEARD)
	for bp: Vector2 in [Vector2(1, 24), Vector2(10, 53), Vector2(20, 56), Vector2(33, 57), Vector2(44, 55), Vector2(54, 52), Vector2(61, 40)]:
		B.call(bp.x, bp.y + (jaw if bp.y > 44.0 else 0.0), 1, 1, BEARD_L)
	B.call(19, 39, 26, 3, BEARD)
	B.call(17, 41, 3, 2, BEARD)
	B.call(44, 41, 3, 2, BEARD)
	B.call(31, 39, 2, 1, SKIN_LIGHT[1])
	B.call(21, 39, 8, 1, BEARD_L)
	# the mouth
	match str(st.get("mouth", "grin")):
		"grin":
			B.call(17, 43, 30, 10, MOUTH)
			B.call(19, 52, 26, 1, MOUTH)
			B.call(19, 43, 26, 3, TEETH)
			B.call(25, 43, 1, 3, Color("#d8d0c0"))
			B.call(38, 43, 1, 3, Color("#d8d0c0"))
			B.call(23, 48, 18, 5, TONGUE)
			B.call(25, 48, 6, 1, Color("#f08a80"))
			B.call(15, 41, 2, 2, MOUTH)
			B.call(47, 41, 2, 2, MOUTH)
		"chew_a":
			B.call(22, 45 + jaw, 20, 3, MOUTH)
			B.call(24, 45 + jaw, 6, 1, WRAP[0])
		"chew_b":
			B.call(24, 46, 16, 2, MOUTH)
		"bite":
			B.call(18, 43, 28, 10, MOUTH)
			B.call(20, 43, 24, 2, TEETH)
			B.call(20, 51, 24, 2, TEETH)
		_:
			B.call(22, 45, 20, 2, MOUTH)
	_detail(false)
	if bool(st.get("kebab", false)):
		# the bun or the wrap (its napkin or foil) held across into his mouth
		var bun := tasting.dish == "bun"
		var wr: Array = BUN if bun else WRAP
		var fo: Array = PAPER if bun else FOIL
		# the hand from the left, the wrap held across into his mouth, the bite in the tortilla
		var ky := 41.0
		B.call(-30, ky, 16, 16, SKIN_LIGHT[0])
		_detail(true)
		B.call(-30, ky + 13, 16, 3, SKIN_LIGHT[1])
		for k in 3:
			B.call(-30, ky + 3 + k * 4, 6, 1, SKIN_LIGHT[1])
		_detail(false)
		B.call(-24, ky + 2, 14, 12, fo[0])
		_detail(true)
		B.call(-24, ky + 11, 14, 3, fo[1])
		B.call(-22, ky + 4, 6, 1, fo[2])
		B.call(-16, ky + 7, 1, 4, fo[1])
		_detail(false)
		B.call(-10, ky + 1, 30, 14, wr[0])
		_detail(true)
		B.call(-10, ky + 12, 30, 3, wr[1])
		B.call(-10, ky + 1, 30, 2, wr[2])
		for gx in 6:
			B.call(-8 + gx * 5, ky + 4 + (gx % 2), 1, 6, wr[1])
		B.call(18, ky + 3, 4, 3, LETTUCE)
		B.call(18, ky + 7, 4, 4, MEAT)
		B.call(19, ky + 11, 3, 2, TOMATO)
		B.call(12, ky + 1, 2, 4, SAUCE)
		_detail(false)
	_flush(OUT, s)


# --- floaters and confetti ------------------------------------------------------------------------

func _rise(n: int) -> void:
	for i in n:
		if _floaters.size() >= 12:
			_floaters.pop_front()
		_floaters.append({"x": float(_rng.randi_range(-14, 0)), "t": -float(i) * 0.12, "kind": _rng.randi_range(0, 2)})


func _confetti() -> void:
	if Access.calm:
		return
	for i in 40:
		var a := _rng.randf_range(-PI, 0.0)
		_bits.append({"p": Vector2(W * 0.5, 50.0), "v": Vector2(cos(a), sin(a)) * _rng.randf_range(40.0, 120.0), "t": 0.0,
				"c": [GOLD, RED, CYAN, WHITE][i % 4]})


func _particles(dt: float) -> void:
	for f: Dictionary in _floaters:
		f["t"] = float(f["t"]) + dt
	while not _floaters.is_empty() and float((_floaters[0] as Dictionary)["t"]) > 1.6:
		_floaters.pop_front()
	for b: Dictionary in _bits:
		b["t"] = float(b["t"]) + dt
		b["v"] = (b["v"] as Vector2) + Vector2(0, 160.0) * dt
		b["p"] = (b["p"] as Vector2) + (b["v"] as Vector2) * dt
	while not _bits.is_empty() and float((_bits[0] as Dictionary)["t"]) > 2.0:
		_bits.pop_front()


## Hearts and little kebabs rising up the right edge, as tiny pixel sprites.
func _floaters_draw() -> void:
	var right := W - 7.0
	for f: Dictionary in _floaters:
		var t: float = f["t"]
		if t < 0.0 or t > 1.4:
			continue
		var px := roundf((right + float(f["x"]) + (1.0 if int(t * 4.0) % 2 == 0 else -1.0)) * PX)
		var py := roundf((H - 34.0 - t * 80.0) * PX)
		var kind: int = f["kind"]
		var rows: Array = HEART if kind < 2 else MINI_KEBAB
		for ry in rows.size():
			var row: String = rows[ry]
			for rx in row.length():
				if row[rx] != "#":
					continue
				var c: Color
				if kind < 2:
					c = (RED if kind == 0 else Color("#ff7ab8"))
					if ry == 1 and (rx == 1 or rx == 4):
						c = WHITE
				else:
					c = WRAP[0] if ry < 4 else FOIL[0]
					if ry == 0 or (ry == 1 and rx == 2):
						c = MEAT if ry == 0 else LETTUCE
				_r(px + rx * 2, py + ry * 2, 2, 2, c)


func _bits_draw() -> void:
	for b: Dictionary in _bits:
		var p: Vector2 = b["p"]
		var spin := int(float(b["t"]) * 10.0) % 2 == 0
		_u(roundf(p.x), roundf(p.y), 2 if spin else 1, 1 if spin else 2, b["c"])


# --- the stream's layer (216 rows, the kit's pen) -------------------------------------------------

func _draw_ui() -> void:
	if tasting == null:
		return
	var p := _ui_pen
	var safe := _safe_canvas()
	var left := maxf(6.0, safe.x + 4.0)
	var right := W - maxf(6.0, safe.y + 4.0)
	var ph := tasting.phase
	_rec_frame(p, left, right)
	if ph == Tasting.Phase.MLASK:
		_chat_panel(p, right)
		_caption(p)
	else:
		_chat(p, left)
	if ph == Tasting.Phase.DRUM or ph == Tasting.Phase.GRADE:
		_scoreboard(p)
	if tasting.line[0] != "" and ph != Tasting.Phase.CARD:
		_line(p, left, right)
	if ph == Tasting.Phase.SELFIE:
		_selfie_flash(p)
	_top_chips(p, left, right)
	if ph == Tasting.Phase.CARD:
		_card(p)
	if ph == Tasting.Phase.IN:
		_viewfinder(p)
	if _wipe > 0.0:
		_draw_wipe(p)


## NA ŻYWO, the viewers and the "+N", the channel; hold-× to skip top right until the card.
func _top_chips(p: Kit, left: float, right: float) -> void:
	var lw := p.chip(left + 4, 6, _w("live"), Kit.LINE, "", 0.0, Kit.ALERT)
	p.rect(left + 4, 6, lw, 13, Color(Kit.ALERT, 0.9))
	if fmod(_t, 1.0) < 0.6:
		p.rect(left + 4, 6, 2, 13, Kit.LINE)
	p.text(_w("live"), left + 8, 7, Kit.LINE)
	var vt := _w("viewers").format({"n": _thousands(int(round(_shown_viewers)))})
	var vw := p.chip(left + 6 + lw, 6, vt, Kit.GOLD)
	if _plus_t < 1.2 and _plus > 0 and int(_plus_t * 8.0) % 4 != 3:
		var pl := "+%d" % _plus
		var px := left + 8 + lw + vw
		var py := 6.0 - floorf(_plus_t * 4.0)
		p.rect(px, py, Kit.text_w(pl) + 8, 13, Color(Kit.INK, 0.86))
		p.text(pl, px + 4, py + 1, Kit.GO)
	if tasting.phase != Tasting.Phase.MLASK:
		p.text(_w("channel"), left + 6, 21, Color(Kit.LINE, 0.8), 1, false, true)
	if tasting.phase < Tasting.Phase.CARD:
		var label := _w("skip")
		var sw := Kit.text_w(label) + 10.0
		var sx := right - sw - 2
		p.chip(sx, 6, label, Kit.LINE, "", sw)
		if tasting.skip_t > 0.0:
			p.rect(sx, 18, sw * clampf(tasting.skip_t / Tasting.SKIP_S, 0.0, 1.0), 2, Kit.GOLD)
		_skip_rect = _grow(Rect2(sx, 6, sw, 13))
	else:
		_skip_rect = Rect2()


func _thousands(n: int) -> String:
	if n < 1000:
		return str(n)
	return "%d %03d" % [n / 1000, n % 1000]


## The REC corners and the dot.
func _rec_frame(p: Kit, left: float, right: float) -> void:
	var c := Color(Kit.LINE, 0.85)
	var y0 := 2.0
	var y1 := H - 3.0
	for corner: Array in [[left, y0, 1, 1], [right, y0, -1, 1], [left, y1, 1, -1], [right, y1, -1, -1]]:
		var x: float = corner[0]
		var y: float = corner[1]
		var sx: int = corner[2]
		var sy: int = corner[3]
		p.rect(x if sx > 0 else x - 12, y if sy > 0 else y - 1, 12, 1, c)
		p.rect(x if sx > 0 else x - 1, y if sy > 0 else y - 12, 1, 12, c)
	if tasting.phase == Tasting.Phase.MLASK:
		return
	if fmod(_t, 1.0) < 0.6:
		p.rect(W * 0.5 - 16, 9, 4, 4, Kit.ALERT)
		p.rect(W * 0.5 - 15, 8, 2, 6, Kit.ALERT)
		p.rect(W * 0.5 - 17, 10, 6, 2, Kit.ALERT)
	var secs := int(tasting.total) + 754
	p.text("%s %02d:%02d" % [_w("rec"), secs / 60, secs % 60], W * 0.5 - 8, 5, Kit.LINE, 1, false, true)


## Three chat lines bottom left, the newest at the bottom, rising in.
func _chat(p: Kit, left: float) -> void:
	var n := tasting.chat.size()
	for i in n:
		var c: Dictionary = tasting.chat[i]
		var y := H - 28.0 - (n - 1 - i) * 11.0
		var rise := clampf(float(c["t"]) / 0.2, 0.0, 1.0)
		y += roundf((1.0 - rise) * 6.0)
		var name := str(c["name"])
		var text := shown(Lang.pick(str(c["pl"]), str(c["en"])))
		var nw := Kit.text_w(name)
		var tw := Kit.text_w(text)
		p.rect(left + 4, y - 1, nw + tw + 12, 11, Color(Kit.INK, 0.6 * rise))
		p.text(name, left + 7, y - 1, Color(NICKS[absi(name.hash()) % NICKS.size()], rise))
		p.text(text, left + 11 + nw, y - 1, Color(Kit.LINE, rise))


## The MLASK's chat as its own dark comic inset bottom right: the viewers, then the lines.
func _chat_panel(p: Kit, right: float) -> void:
	if tasting.t < Tasting.MLASK_CHAT_AT and not Access.calm:
		return
	var vt := _w("viewers").format({"n": _thousands(int(round(_shown_viewers)))})
	var lines: Array = []
	var w := Kit.text_w(vt)
	for c: Dictionary in tasting.chat:
		var name := str(c["name"])
		var text := shown(Lang.pick(str(c["pl"]), str(c["en"])))
		lines.append([name, text])
		w = maxi(w, Kit.text_w(name) + 4 + Kit.text_w(text))
	var pw := float(w) + 10.0
	var ph := 16.0 + lines.size() * 11.0
	var x := right - pw - 2.0
	var y := MLASK_LOW - ph
	p.rect(x - 2, y - 2, pw + 4, ph + 4, Kit.VOID)
	p.rect(x - 1, y - 1, pw + 2, ph + 2, Kit.LINE)
	p.rect(x, y, pw, ph, Kit.INK)
	p.text(vt, x + 5, y + 2, Kit.GOLD)
	for i in lines.size():
		var l: Array = lines[i]
		var name: String = l[0]
		p.text(name, x + 5, y + 13 + i * 11, NICKS[absi(name.hash()) % NICKS.size()])
		p.text(str(l[1]), x + 9 + Kit.text_w(name), y + 13 + i * 11, Kit.LINE)


## The MLASK's caption strip under his face (F's "…ALE DOBRY.", handed in): a cream comic caption box
## with an ink edge, the words at the biggest scale that fits, popping up at MLASK_CAPTION_AT.
func _caption(p: Kit) -> void:
	var ct := tasting.t - Tasting.MLASK_CAPTION_AT
	if ct < 0.0 or tasting.caption.size() < 2 or str(tasting.caption[0]) == "":
		return
	var text := _pick(tasting.caption)
	var sc := caption_scale(text, W)
	var tw := float(Kit.text_w(text, sc))
	var bw := tw + 8.0 * sc
	var bh := 7.0 * sc + 8.0
	var x := roundf(W * 0.5 - 8.0 - bw * 0.5)
	var y := 208.0 - bh - 2.0 + (0.0 if Access.calm else roundf((1.0 - _pop(ct / 0.14)) * 20.0))
	p.rect(x + 3, y + 3, bw, bh, Color(Kit.VOID, 0.6))
	p.rect(x - 2, y - 2, bw + 4, bh + 4, Kit.INK)
	p.rect(x, y, bw, bh, Kit.PANEL)
	p.rect(x, y + bh - 2, bw, 2, Kit.PAPER_D)
	p.text(text, x + bw * 0.5, y + 4 - 2 * sc, Kit.INK, sc, true)


## The caption's text scale on a canvas `w` units wide: 3, or 2 when 3 does not fit.
static func caption_scale(text: String, w: float) -> int:
	return 3 if Kit.text_w(shown(text), 3) + 24 <= w - 24 else 2


## The speaker's line bottom right (the chat keeps the left), the name on its tab.
func _line(p: Kit, left: float, right: float) -> void:
	var bw := line_w()
	var bx := right - bw
	var lines := Kit.wrap(_pick(tasting.line), int(bw) - 10)
	var by := H - 8.0 - lines.size() * 10.0 - 6.0
	var name := _w("name_" + tasting.who) if tasting.who != "" else ""
	var nc := Kit.AMBER if tasting.who == "kebabulo" else (Color("#f47aa6") if tasting.who == "fan" else Kit.THEM)
	var tail := bx + 20.0
	match tasting.who:
		"kebabulo":
			tail = clampf(_kebabulo_x(), bx + 8.0, bx + bw - 8.0)
		"zbyszek":
			tail = clampf(_zbyszek_x(), bx + 8.0, bx + bw - 8.0)
		"fan":
			tail = clampf(_fan_x, bx + 8.0, bx + bw - 8.0)
	p.bubble(bx, by, bw, name, lines, tail, nc, false)
	var ph := tasting.phase
	if (ph == Tasting.Phase.HELLO or ph == Tasting.Phase.VERDICT or ph == Tasting.Phase.GRADE or ph == Tasting.Phase.FAN) and tasting.t > Tasting.TAP_S and fmod(_t, 1.0) < 0.7:
		var hint := _w("tap") + " \u2192"
		p.text(hint, right - Kit.text_w(hint) - 4, by - 10, Kit.GOLD, 1, false, true)


## The line's bubble width.
func line_w() -> float:
	return minf(roundf(W * 0.42), 200.0)


## The room the chat has, left of the bubble (the check holds every chat line to it).
func chat_w() -> float:
	return W - line_w() - 6.0 - 6.0 - 14.0


## A chat line's width, for the check: the handle and the text on their strip.
static func chat_line_w(name: String, text: String) -> float:
	return 4.0 + Kit.text_w(name) + Kit.text_w(shown(text)) + 12.0


## The pixel scoreboard: the digits rolling, then the grade; 11 cracks it and a digit falls.
func _scoreboard(p: Kit) -> void:
	var bw := 120.0
	var bh := 46.0
	var x := roundf(W * 0.5 - bw * 0.5)
	var slam := 0.0 if Access.calm or tasting.phase != Tasting.Phase.DRUM else roundf((1.0 - _pop(tasting.t / 0.2)) * -40.0)
	var y := 30.0 + slam
	p.rect(x + 2, y + 2, bw, bh, Color(Kit.VOID, 0.5))
	p.card(x, y, bw, bh, Color(Kit.INK, 0.96), Kit.GOLD)
	var txt := tasting.board_text()
	p.text(txt, x + bw * 0.42, y + 6, Kit.GOLD, 4, true)
	p.text("/ 10", x + bw - 26, y + bh - 16, Kit.LINE)
	if tasting.perfect and tasting.phase == Tasting.Phase.GRADE:
		for i in 8:
			p.rect(x + 30 + i * 4, y + 4 + (i % 3) * 5 + i * 2, 3, 2, Kit.LINE)
		var fall := minf(tasting.t * 90.0, 140.0)
		p.text("0", x + bw - 18, y + bh - 16 + fall, Kit.LINE)
		var cw := Kit.text_w(_w("cracked")) + 8.0
		p.rect(x + bw * 0.5 - cw * 0.5, y + bh + 2, cw, 12, Color(Kit.INK, 0.9))
		p.text(_w("cracked"), x + bw * 0.5, y + bh + 3, Kit.GOLD, 1, true)


## The selfie: the pre-flash dot at the fan's phone, one flash (soft and warm under calm), SNAP.
func _selfie_flash(p: Kit) -> void:
	var t := tasting.t
	var lens := _fan_lens()
	if t > 0.32 and t < 0.40:
		p.rect(lens.x - 1, lens.y - 1, 2, 2, Kit.LINE)
	if t < 0.55:
		return
	var ft := t - 0.55
	if ft < 0.06 and not Access.calm:
		p.rect(0, 0, W, H, Color(1.0, 0.98, 0.92, 0.9))
	elif ft < 0.24:
		p.rect(0, 0, W, H, Color(1.0, 0.9, 0.7, 0.3) if Access.calm else Color(1.0, 0.98, 0.92, 0.35))
	if not Access.calm and ft < 0.16:
		p.rect(lens.x - 8, lens.y, 17, 1, Kit.LINE)
		p.rect(lens.x, lens.y - 8, 1, 17, Kit.LINE)
	if ft < 0.4:
		p.text(_w("snap"), lens.x, lens.y - 18 - floorf(ft * 20.0), Kit.LINE, 1, true, true)


## The RECENZJA card: vertical, the order, the grade, the badge, the game's name (the print rides
## over its right edge, drawn by `_draw_over`).
func _card(p: Kit) -> void:
	var cw := 184.0
	var ch := 198.0
	var x := _card_x()
	var drop := 0.0 if Access.calm else roundf(exp(-tasting.t * 7.0) * cos(tasting.t * 14.0) * -40.0)
	var y := 9.0 + drop
	p.rect(0, 0, W, H, Color(Kit.VOID, 0.45))
	p.card(x, y, cw, ch, Color(Kit.INK, 0.97), Kit.GOLD)
	p.text(_w("card_title"), x + cw * 0.5, y + 6, Kit.GOLD, 2, true)
	p.text(_w("place"), x + cw * 0.5, y + 26, Kit.CHALK_D, 1, true)
	p.text(_w("card_order"), x + 8, y + 42, Kit.CHALK_D)
	var ol := Kit.wrap(_pick(tasting.order), int(cw) - 16)
	for i in mini(ol.size(), 2):
		p.text(ol[i], x + 8, y + 52 + i * 10, Kit.LINE)
	p.text(_w("card_grade"), x + 8, y + 76, Kit.CHALK_D)
	p.text(tasting.board_text() + " / 10", x + cw * 0.5, y + 84, Kit.GOLD, 3, true)
	var by := y + 122.0
	if not tasting.badge.is_empty():
		p.text(_w("card_badge"), x + 8, by, Kit.CHALK_D)
		var bt := _pick(tasting.badge)
		var bw := Kit.text_w(bt) + 10.0
		p.rect(x + 8, by + 10, bw, 12, Kit.GOLD)
		p.text(bt, x + 13, by + 10, Kit.INK)
	p.text(_w("card_shot"), x + cw * 0.5, y + ch - 46, Kit.CHALK_D, 1, true)
	p.text(_w("card_game"), x + cw * 0.5, y + ch - 34, Kit.LINE, 1, true)
	if tasting.t >= Tasting.CARD_S:
		var bw2 := 96.0
		p.button(x + cw * 0.5 - bw2 * 0.5, y + ch - 22, bw2, _w("btn_next"), true, 18.0)
	else:
		var bar := cw - 40.0
		p.rect(x + 20, y + ch - 12, bar, 2, Kit.SLATE_D)
		p.rect(x + 20, y + ch - 12, bar * clampf(tasting.t / Tasting.CARD_S, 0.0, 1.0), 2, Kit.GOLD)


## The card's left edge: left of the middle when there is room for the print beside it.
func _card_x() -> float:
	return roundf(maxf(W * 0.5 - 92.0 - 30.0, 8.0))


## Zbyszek's viewfinder closing in: black blocks giving way, the corners sliding in.
func _viewfinder(p: Kit) -> void:
	var k := clampf(tasting.t / Tasting.IN_S, 0.0, 1.0)
	var cols := int(ceil(W / BLOCK))
	var rows := int(ceil(H / BLOCK))
	for by in rows:
		for bx in cols:
			var d := float((bx * 7 + by * 13) % 16) / 16.0
			if d >= k * 1.15:
				p.rect(bx * BLOCK, by * BLOCK, BLOCK, BLOCK, Kit.VOID)
	var inset := roundf((1.0 - k) * 40.0)
	var c := Kit.LINE
	p.rect(inset, inset, 24, 2, c)
	p.rect(inset, inset, 2, 24, c)
	p.rect(W - inset - 24, H - inset - 2, 24, 2, c)
	p.rect(W - inset - 2, H - inset - 24, 2, 24, c)


func _grow(r: Rect2) -> Rect2:
	var m := _touch_px()
	var g := r
	if g.size.x < m:
		g = g.grow_individual((m - g.size.x) * 0.5, 0, (m - g.size.x) * 0.5, 0)
	if g.size.y < m:
		g = g.grow_individual(0, (m - g.size.y) * 0.5, 0, (m - g.size.y) * 0.5)
	return g


func _draw_wipe(p: Kit) -> void:
	var cols := int(ceil(W / BLOCK))
	var rows := int(ceil(H / BLOCK))
	for by in rows:
		for bx in cols:
			var d := float((bx * 7 + by * 13) % 16) / 16.0
			if d < _wipe:
				p.rect(bx * BLOCK, by * BLOCK, BLOCK, BLOCK, Kit.VOID)


# --- the instant print (over the stream's layer, at the scene's pixels) ----------------------------

func _draw_over() -> void:
	if tasting == null:
		return
	var ph := tasting.phase
	var at := Vector2.ZERO
	var big := false
	if ph == Tasting.Phase.SELFIE and tasting.t > 0.8:
		at = Vector2(roundf(W * 0.5 - 30.0), 36.0)
		big = tasting.t < 0.86 and not Access.calm
	elif ph == Tasting.Phase.CARD and tasting.t > 0.2:
		at = Vector2(_card_x() + 184.0 - 12.0, 40.0)
		big = tasting.t < 0.26 and not Access.calm
	else:
		return
	_ci = null if _dry else _over
	_dinv = 1.0
	if is_inside_tree():
		var k := _scale()
		var o := _origin()
		_kd = k / PX
		_offd = o
	_print(at, 1.25 if big else 1.0, ph == Tasting.Phase.CARD)


## The print: a white frame with a thick foot, the sunset, a frond, the two grinning faces, the
## caption in the kit's font; tape when it is on the card.
func _print(at: Vector2, s: float, taped: bool) -> void:
	var w := 60.0
	var h := 72.0
	var c := at + Vector2(w, h) * 0.5
	var o := c - Vector2(w, h) * 0.5 * s
	var R := func(x: float, y: float, rw: float, rh: float, col: Color) -> void:
		_u(o.x + x * s, o.y + y * s, rw * s, rh * s, col)
	R.call(1.5, 1.5, w, h, Color(0, 0, 0, 0.35))
	R.call(-0.5, -0.5, w + 1, h + 1, OUT)
	R.call(0, 0, w, h, WHITE)
	R.call(3, 3, w - 6, 54, Color("#f2a562"))
	R.call(3, 3, w - 6, 14, Color("#d9877a"))
	R.call(3, 17, w - 6, 1, Color("#e8957a"))
	R.call(3, 44, w - 6, 13, Color("#f6c56a"))
	for k in 6:
		R.call(3 + k * 2.5, 6 + k * 1.5, 3, 1, FROND[0])
		R.call(3.5 + k * 2.5, 7 + k * 1.5, 0.5, 1.5, FROND[1])
	R.call(0, h - 1, w, 1, Color("#e0dcd0"))
	# the two of them: shoulders, then the heads at the print's scale
	R.call(30, 45, 26, 12, VEST[0])
	R.call(38, 45, 8, 4, HOODIE[0])
	R.call(4, 46, 24, 11, PUFFER[0])
	R.call(4, 49, 24, 0.5, PUFFER[1])
	R.call(4, 53, 24, 0.5, PUFFER[1])
	var good := tasting.grade >= 8.0 or tasting.perfect
	var scale := s
	_fig(0, 0, -1, scale)
	_org = Vector2(roundf((o.x + 42.0 * s) * PX), roundf((o.y + 26.0 * s) * PX))
	_head(0, 0, 30, SKIN_LIGHT, "cap_fwd", BEARD, {"eyes": "happy", "mouth": "grin" if good else "tight", "blush": true}, true)
	_flush(OUT)
	_fig(0, 0, 1, scale)
	_org = Vector2(roundf((o.x + 17.0 * s) * PX), roundf((o.y + 29.0 * s) * PX))
	_head(0, 0, 28, SKIN_FAIR, "beanie", Color("#6a3a24"), {"eyes": "happy", "mouth": "grin", "blush": true, "freckles": true})
	_flush(OUT)
	# the caption in the 5x7 font, one font px a unit
	var cap := _w("print_caption").to_upper()
	var cw := PixelFont.width(cap)
	var cx := roundf(o.x + (w * 0.5) * s - cw * 0.5)
	var cy := roundf(o.y + 61.0 * s)
	_glyphs(cap, cx, cy, Color("#5a4a60"))
	if taped:
		R.call(w * 0.5 - 12, -4, 24, 7, Color("#fff2b0", 0.75))
		R.call(w * 0.5 - 12, -4, 24, 1, Color("#ffffff", 0.5))


## The 5x7 font with this pen, one font pixel a unit (the print's caption).
func _glyphs(s: String, x: float, y: float, c: Color) -> void:
	var cx := x
	for ch in s:
		var cw := PixelFont.char_width(ch)
		if cw == 0:
			continue
		for p: Vector2i in PixelFont.pixels(ch):
			_u(cx + p.x, y + p.y - PixelFont.BODY, 1, 1, c)
		cx += cw + PixelFont.GAP
