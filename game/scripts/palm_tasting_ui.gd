extends Node
## The tasting at the Palm, drawn as Zbyszek's livestream (palm_tasting.gd's rules; plan doc "First
## 10 minutes: Tajny klient", "The river scene and the viral moment", moved to the Palm at Rondo de
## Gaulle'a by F): full screen in the pixel kit's look, the city's 3D off while it is up
## (GameCtx.city_drawn), like the kebab stand and beer pong.
##
## The frame (a 216-row canvas, nearest-filtered over the whole screen, pixel_kit.gd's pen), a
## medium-wide shot at golden hour:
##   - the sky in four warm bands, the horizon at 36 % of the height;
##   - the old Party House's pale colonnade on the left, the low pastel fronts of Nowy Świat on
##     the right, Jerozolimskie's lamps;
##   - the roundabout's carriageway across the middle, cars sliding both ways and a tram every
##     TRAM_S along the tracks;
##   - the Palm on its island, its trunk in rings, its fronds swaying;
##   - the pavement in front: Kebabulo's Porsza side-on at left-centre, nose right; the player and
##     Kebabulo face to face with the kebab between them; Zbyszek with his gimbal at the right edge;
##     a pigeon walking toward the kebab.
## The stream's own layer: the REC corners, NA ŻYWO and the viewer count top left, three chat lines
## rising bottom left, the speaker's line bottom centre, hold-× to skip top right. For the bite a
## comic close-up panel (about 40 % of the screen) slams in, since the figures are too small for
## faces; the MLASK burst, the shake (not under the calm setting), the scoreboard, the RECENZJA card.
##
## Art: flat rects through the kit (no textures), as the stand; Codex sprites can replace the
## figure and backdrop functions later without touching the rules or the touch.
##
## Touch: a tap anywhere advances, a hold on the skip chip skips. Keys for the Mac: Space or Enter
## a tap, Esc held the skip.
##
## Cost: while it is up the city's 3D is off and the frame is two 2D canvases of about 467 x 216 px
## (about 500 untextured rects); nothing per frame while it is closed.

const Tasting := preload("res://scripts/palm_tasting.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Access := preload("res://scripts/access.gd")

const H := 216
const MIN_W := 384
const HORIZON := 78.0
const ROAD_Y := 112.0
const PAVE_Y := 146.0
const FEET := 196.0
const TRAM_S := 12.0
const WIPE_S := 0.45
const BLOCK := 12.0
const TOUCH_PT := 44.0

const SKY := [Color("#f6c56a"), Color("#f2a562"), Color("#d9877a"), Color("#6f6f9e")]
const STONE := Color("#d8cdb6")
const STONE_D := Color("#b3a68c")
const STONE_L := Color("#ece4d0")
const ASPHALT := Color("#45464c")
const ASPHALT_L := Color("#56585e")
const PAVE := Color("#9a958c")
const PAVE_D := Color("#86817a")
const TRUNK := Color("#8a6a48")
const TRUNK_D := Color("#6a4e34")
const FROND := Color("#3f9a4a")
const FROND_L := Color("#6cc04a")
const TRAM_R := Color("#c8302a")
const TRAM_Y := Color("#f2c230")
const PORSZA := Color("#e9e6dc")
const HOODIE := Color("#e2561c")
const PIGEON := Color("#8a8f9a")

signal finished(result: Dictionary)

var tasting: Tasting
var pt := 1.0
var auto_play := false
var log_on := false
var inside := false
## Plays a short sound by name (the owner's hud.cue): "tick", "win".
var cue := Callable()
var W := MIN_W

var _layer: CanvasLayer
var _vp: SubViewport
var _scene: Node2D
var _ui: Node2D
var _tex: TextureRect
var _pen: Kit
var _ui_pen: Kit
var _t := 0.0
var _wipe := 0.0
var _leaving := false
var _skip_held := false
var _key_skip := false
var _last_phase := -1
var _shake := 0.0
var _skip_rect := Rect2()


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
	_shake = 0.0
	inside = true
	_layer.visible = true
	_resize()
	set_process(true)
	_log("open: grade %s" % tasting.grade_label)


## Taken down at once by its owner (the run dropped): no `finished`.
func hide_now() -> void:
	inside = false
	if _layer != null:
		_layer.visible = false
	set_process(false)


func _close() -> void:
	inside = false
	_layer.visible = false
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
	_vp = SubViewport.new()
	_vp.size = Vector2i(MIN_W, H)
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.snap_2d_transforms_to_pixel = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_scene = Node2D.new()
	_scene.draw.connect(_draw_scene)
	_vp.add_child(_scene)
	_ui = Node2D.new()
	_ui.draw.connect(_draw_ui)
	_vp.add_child(_ui)
	_pen = Kit.new(_scene)
	_ui_pen = Kit.new(_ui)
	_tex = TextureRect.new()
	_tex.texture = _vp.get_texture()
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_tex)
	_layer.visible = false
	if is_inside_tree():
		get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	if _vp == null or not is_inside_tree():
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W, H)
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
	var off := Vector2.ZERO
	if _shake > 0.0 and not Access.calm:
		off = Vector2(roundf(sin(_t * 71.0) * 2.0), roundf(cos(_t * 53.0) * 1.5))
	_scene.position = off
	_scene.queue_redraw()
	_ui.queue_redraw()


func _react() -> void:
	var p := int(tasting.phase)
	if p == _last_phase:
		return
	_last_phase = p
	match tasting.phase:
		Tasting.Phase.HELLO:
			_cue("tick")
		Tasting.Phase.MLASK:
			_shake = 0.5
			_cue("tick")
			Access.buzz(120, 1.0)
		Tasting.Phase.GRADE:
			_shake = 0.35 if tasting.perfect else 0.0
			_cue("win")
			Access.buzz(200, 1.0)
			_log("grade %s" % tasting.grade_label)
		Tasting.Phase.CARD:
			_log("card%s" % (" (skipped)" if tasting.skipped else ""))


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


# --- the scene ----------------------------------------------------------------------------------

func _palm_x() -> float:
	return roundf(W * 0.44)


func _kebabulo_x() -> float:
	return roundf(W * 0.62)


func _you_x() -> float:
	return roundf(W * 0.50)


func _draw_scene() -> void:
	_sky()
	_party_house()
	_nowy_swiat()
	_road()
	_palm()
	_pavement()
	_porsza(roundf(W * 0.10), 186.0)
	_pigeon()
	_you(_you_x())
	_kebabulo(_kebabulo_x())
	_kebab(roundf((_you_x() + _kebabulo_x()) * 0.5), 150.0)
	_zbyszek(W - 26.0)


func _sky() -> void:
	var p := _pen
	var band := HORIZON / SKY.size()
	for i in SKY.size():
		p.rect(0, HORIZON - (i + 1) * band, W, band + 1, SKY[i])
	# the sun low over Jerozolimskie, a soft disc
	p.disc(W * 0.78, HORIZON - 14, 14, 10, Color("#ffe39a"))
	p.disc(W * 0.78, HORIZON - 14, 9, 7, Color("#fff4cc"))
	# two thin clouds
	p.rect(W * 0.12, 18, 46, 2, Color(Kit.PEARL, 0.5))
	p.rect(W * 0.55, 30, 60, 2, Color(Kit.PEARL, 0.35))


## The old Party House on the corner: a long pale block with a tall colonnade.
func _party_house() -> void:
	var p := _pen
	var x0 := -6.0
	var x1 := W * 0.40
	var top := 34.0
	p.rect(x0, top, x1 - x0, ROAD_Y - top, STONE)
	p.rect(x0, top, x1 - x0, 3, STONE_L)
	p.rect(x0, top + 10, x1 - x0, 2, STONE_D)
	# the windows in five rows above the colonnade
	for r in 4:
		var y := top + 15 + r * 9
		var x := x0 + 6
		while x < x1 - 8:
			p.rect(x, y, 5, 5, Color("#5b5e6e"))
			p.rect(x, y, 5, 1, Color("#f2c97a", 0.5))
			x += 10
	# the colonnade: tall pillars on the ground floor
	var cy := top + 52
	p.rect(x0, cy, x1 - x0, ROAD_Y - cy, Color("#4c4a52"))
	var x := x0 + 4
	while x < x1 - 4:
		p.rect(x, cy, 5, ROAD_Y - cy, STONE)
		p.rect(x, cy, 1, ROAD_Y - cy, STONE_L)
		x += 14
	p.rect(x0, cy - 2, x1 - x0, 3, STONE_D)


## Nowy Świat's low pastel fronts and Jerozolimskie's lamps on the right.
func _nowy_swiat() -> void:
	var p := _pen
	var cols := [Color("#e8c9a0"), Color("#d6b6c4"), Color("#c9d4b0"), Color("#ead79c"), Color("#d8bca8")]
	var x := W * 0.52
	var i := 0
	while x < W:
		var w := 34.0 + float((i * 13) % 14)
		var top := 50.0 + float((i * 7) % 12)
		var c: Color = cols[i % cols.size()]
		p.rect(x, top, w, ROAD_Y - top, c)
		p.rect(x, top, w, 2, c.darkened(0.2))
		for r in 3:
			for k in int((w - 6) / 8):
				p.rect(x + 4 + k * 8, top + 7 + r * 13, 4, 7, Color("#4e5266"))
				p.rect(x + 4 + k * 8, top + 7 + r * 13, 4, 2, Color("#f2c97a", 0.45))
		x += w
		i += 1
	# the lamps
	for k in 5:
		var lx := 30.0 + k * W * 0.22
		p.rect(lx, 66, 1, ROAD_Y - 66, Kit.SLATE_D)
		p.rect(lx - 3, 66, 7, 2, Kit.SLATE_D)
		p.rect(lx - 2, 68, 5, 1, Color("#ffe39a"))


func _road() -> void:
	var p := _pen
	p.rect(0, ROAD_Y, W, PAVE_Y - ROAD_Y, ASPHALT)
	p.rect(0, ROAD_Y, W, 1, ASPHALT_L)
	# the tracks down the middle
	p.rect(0, ROAD_Y + 15, W, 1, Kit.CHROME.darkened(0.4))
	p.rect(0, ROAD_Y + 19, W, 1, Kit.CHROME.darkened(0.4))
	# the lane dashes
	var x := fmod(0.0, 16.0)
	while x < W:
		p.rect(x, ROAD_Y + 7, 8, 1, Kit.LINE.darkened(0.2))
		p.rect(x, ROAD_Y + 27, 8, 1, Kit.LINE.darkened(0.2))
		x += 16
	# cars both ways
	var colours := [Kit.CUP, Kit.THEM, Kit.CHROME, Kit.GOLD, Kit.JEANS]
	for k in 4:
		var sp := 38.0 + k * 9.0
		var cx := fmod(_t * sp + k * 131.0, W + 60.0) - 30.0
		_car(cx, ROAD_Y + 2, colours[k], true)
		var bx := W + 30.0 - fmod(_t * (sp + 6.0) + k * 97.0, W + 60.0)
		_car(bx, ROAD_Y + 22, colours[(k + 2) % colours.size()], false)
	# the tram
	var tt := fmod(_t + 4.0, TRAM_S)
	if tt < 5.0:
		var tx := -120.0 + tt / 5.0 * (W + 240.0)
		_tram(tx, ROAD_Y + 6)
	p.rect(0, PAVE_Y - 2, W, 2, Kit.CONCRETE)


func _car(x: float, y: float, c: Color, right: bool) -> void:
	var p := _pen
	p.rect(x, y + 2, 20, 5, c)
	p.rect(x + (4 if right else 6), y, 10, 3, c.darkened(0.15))
	p.rect(x + (5 if right else 7), y + 1, 8, 1, Kit.GLASS_C.darkened(0.3))
	p.rect(x + 3, y + 7, 3, 2, Kit.INK)
	p.rect(x + 14, y + 7, 3, 2, Kit.INK)
	p.px(x + (19 if right else 0), y + 3, Color("#fff4cc"))


## A Warsaw tram: three red cars with the yellow band.
func _tram(x: float, y: float) -> void:
	var p := _pen
	for k in 3:
		var cx := x + k * 38.0
		p.rect(cx, y, 36, 13, TRAM_R)
		p.rect(cx, y + 8, 36, 2, TRAM_Y)
		for wi in 4:
			p.rect(cx + 3 + wi * 8, y + 2, 6, 5, Kit.GLASS_C.darkened(0.25))
	p.rect(x + 50, y - 5, 1, 5, Kit.INK)
	p.rect(x + 44, y - 5, 12, 1, Kit.INK)


## The Palm on its island: the trunk in rings, the fronds swaying a little.
func _palm() -> void:
	var p := _pen
	var x := _palm_x()
	var base := PAVE_Y - 8.0
	p.disc(x, base + 2, 22, 4, Color("#4a8a3e"))
	p.rect(x - 9, base - 2, 18, 4, Kit.CONCRETE)
	var top := 26.0
	var sway := roundf(sin(_t * 0.9) * 1.0)
	var n := int((base - top) / 5.0)
	for i in n:
		var y := base - (i + 1) * 5.0
		var lean := roundf(float(i) / n * 3.0)
		p.rect(x - 3 + lean, y, 7, 5, TRUNK if i % 2 == 0 else TRUNK_D)
		p.rect(x - 3 + lean, y, 7, 1, TRUNK.lightened(0.2))
	var cx := x + 3.0 + sway
	# the fronds: nine long arcs that rise and droop, two tones and a leaflet fringe
	for f in 9:
		var a := -PI + f * PI / 8.0
		var dx := cos(a)
		var up := sin(a) * 1.9
		for k in 13:
			var fx := cx + dx * k * 3.4
			var fy := top + up * k + k * k * 0.16
			p.rect(fx - 1, fy, 4, 3, FROND if (k + f) % 2 == 0 else FROND_L)
			if k > 3 and k % 2 == 0:
				p.rect(fx, fy + 3, 2, 2, FROND.darkened(0.25))
	p.disc(cx, top + 1, 6, 4, FROND.darkened(0.2))
	p.px(cx - 1, top + 1, Color("#c8a020"))
	p.px(cx + 2, top + 2, Color("#c8a020"))


func _pavement() -> void:
	var p := _pen
	p.rect(0, PAVE_Y, W, H - PAVE_Y, PAVE)
	var y := PAVE_Y + 6.0
	var row := 0
	while y < H:
		p.rect(0, y, W, 1, PAVE_D)
		var x := 12.0 if row % 2 == 0 else 0.0
		while x < W:
			p.rect(x, y - 6 + 1, 1, 5, PAVE_D)
			x += 24
		y += 7.0 + row
		row += 1
	# the long golden-hour shadows
	p.rect(_palm_x() + 6, PAVE_Y, 70, 3, Color(Kit.INK, 0.15))


## Kebabulo's Porsza, side-on, nose right: a low white fastback, the roof sloping all the way to
## the tail, round lamps, the gold stripe.
func _porsza(x: float, base: float) -> void:
	var p := _pen
	var w := roundf(W * 0.25)
	p.rect(x + 4, base - 2, w - 8, 3, Color(Kit.INK, 0.3))
	# the body: low, the bonnet dropping to the nose
	p.rect(x + 2, base - 14, w - 4, 10, PORSZA)
	p.rect(x, base - 12, w, 7, PORSZA)
	p.rect(x + w * 0.70, base - 16, w * 0.26, 3, PORSZA)
	# the cabin: the windscreen raked, the roof sloping down to the tail in steps
	var roof_l := x + w * 0.10
	var roof_r := x + w * 0.66
	for i in 10:
		var k := float(i) / 9.0
		var yy := base - 15.0 - roundf(10.0 * sin(k * PI * 0.5 + 0.05) if k < 0.85 else 10.0 * (1.0 - (k - 0.85) * 4.0))
		p.rect(roof_l + k * (roof_r - roof_l), yy, (roof_r - roof_l) / 9.0 + 1, base - 14 - yy, PORSZA)
	p.rect(x + w * 0.36, base - 23, w * 0.16, 7, Kit.GLASS_C.darkened(0.35))
	p.rect(x + w * 0.53, base - 23, w * 0.10, 7, Kit.GLASS_C.darkened(0.35))
	p.rect(x + w * 0.22, base - 20, w * 0.12, 4, Kit.GLASS_C.darkened(0.45))
	# the lamps, the tail light, the sill
	p.disc(x + w - 4, base - 12, 2, 2, Color("#fff4cc"))
	p.rect(x + 1, base - 11, 3, 2, Kit.CUP)
	p.rect(x + w * 0.04, base - 6, w * 0.92, 2, PORSZA.darkened(0.15))
	p.rect(x + w * 0.06, base - 9, w * 0.88, 1, Kit.GOLD)
	for wx in [x + w * 0.20, x + w * 0.80]:
		p.disc(wx, base - 3, 7, 6, Kit.INK)
		p.disc(wx, base - 3, 3, 3, Kit.CHROME)


## A pigeon pacing toward the kebab, stopping to peck.
func _pigeon() -> void:
	var p := _pen
	var k := fmod(_t, 16.0) / 16.0
	var x := roundf(lerpf(W * 0.30, _you_x() - 10.0, minf(1.0, k * 1.6)))
	var peck := fmod(_t, 1.4) < 0.25
	var y := FEET - 2.0
	p.rect(x, y - 6, 8, 5, PIGEON)
	p.rect(x + 1, y - 5, 5, 2, PIGEON.lightened(0.15))
	p.rect(x + (7 if not peck else 8), y - (9 if not peck else 6), 4, 4, PIGEON.darkened(0.1))
	p.px(x + (9 if not peck else 10), y - (8 if not peck else 5), Kit.INK)
	p.rect(x + (11 if not peck else 12), y - (7 if not peck else 4), 2, 1, Kit.GOLD)
	p.rect(x + 8, y - 5, 2, 1, Color("#5fae8a"))
	p.rect(x + 2, y - 1, 1, 2, Kit.CUP_L)
	p.rect(x + 5, y - 1, 1, 2, Kit.CUP_L)


## A standing figure, 66 px: legs, body, arms, a head with hair; `face` 1 right, -1 left.
func _figure(x: float, top: float, body: Color, legs: Color, skin: Color, hair: Color, face: int) -> void:
	var p := _pen
	p.rect(x - 12, FEET - 1, 24, 2, Color(Kit.INK, 0.25))
	p.rect(x - 7, top + 40, 6, FEET - top - 40, legs)
	p.rect(x + 1, top + 40, 6, FEET - top - 40, legs)
	p.rect(x - 8, FEET - 3, 8, 3, Kit.INK)
	p.rect(x, FEET - 3, 8, 3, Kit.INK)
	p.rect(x - 9, top + 16, 18, 26, body)
	p.rect(x - 9, top + 16, 18, 2, body.lightened(0.15))
	p.rect(x - 12, top + 18, 4, 18, body.darkened(0.1))
	p.rect(x + 8, top + 18, 4, 18, body.darkened(0.1))
	var hx := x - 7
	p.rect(hx, top, 14, 15, skin)
	p.rect(hx, top - 2, 14, 4, hair)
	p.rect(hx + (9 if face > 0 else 3), top + 5, 2, 2, Kit.INK)
	p.rect(hx + (14 if face > 0 else -1), top + 7, 1, 3, skin)


func _you(x: float) -> void:
	var top := FEET - 66.0
	_figure(x, top, Kit.THEM_D, Kit.JEANS, Kit.SKIN[1], Kit.HAIR_BR, 1)
	# the paper bag in the hand once the kebab has gone over
	if tasting == null or tasting.phase >= Tasting.Phase.HELLO:
		_pen.rect(x + 9, top + 34, 6, 7, Kit.KRAFT)


func _kebabulo(x: float) -> void:
	var p := _pen
	var top := FEET - 70.0
	var chew := tasting != null and (tasting.phase == Tasting.Phase.CHEW or tasting.phase == Tasting.Phase.MLASK)
	_figure(x, top, HOODIE, Kit.INK, Kit.SKIN[2], Kit.HAIR_BK, -1)
	# the cap backwards, the beard, the chain
	p.rect(x - 8, top - 4, 16, 4, Kit.INK)
	p.rect(x + 6, top - 2, 5, 2, Kit.INK)
	p.rect(x - 7, top + 10, 14, 5, Kit.HAIR_BK)
	p.rect(x - 4, top + 11, 6, 1 if not chew or fmod(_t, 0.3) < 0.15 else 2, Kit.MOUTH)
	p.rect(x - 5, top + 17, 10, 1, Kit.GOLD)
	p.px(x, top + 18, Kit.GOLD)
	# the kebab in his hand from the bite on
	if tasting != null and tasting.phase >= Tasting.Phase.CHEW:
		p.rect(x - 16, top + 22, 8, 5, Kit.TORTILLA)
		p.rect(x - 17, top + 22, 2, 5, Kit.MEAT[1])


## The kebab between them until he takes it.
func _kebab(x: float, y: float) -> void:
	if tasting != null and tasting.phase >= Tasting.Phase.CHEW:
		return
	var p := _pen
	p.rect(x - 7, y, 14, 6, Kit.TORTILLA)
	p.rect(x - 8, y + 1, 2, 4, Kit.MEAT[1])
	p.px(x - 8, y + 1, Kit.LETTUCE)
	p.rect(x - 4, y - 1, 8, 1, Kit.SAUCE_W)


## Zbyszek at the edge: the gimbal held out, its red light on.
func _zbyszek(x: float) -> void:
	var p := _pen
	var top := FEET - 64.0
	_figure(x, top, Kit.SLATE_L, Kit.JEANS, Kit.SKIN[0], Kit.HAIR_BL, -1)
	p.rect(x - 22, top + 20, 12, 2, Kit.INK)
	p.rect(x - 24, top + 14, 6, 8, Kit.INK)
	p.rect(x - 23, top + 15, 4, 4, Kit.SLATE_L)
	if fmod(_t, 1.0) < 0.6:
		p.px(x - 19, top + 14, Kit.ALERT)


# --- the stream's layer -------------------------------------------------------------------------

func _draw_ui() -> void:
	var p := _ui_pen
	var safe := _safe_canvas()
	var left := maxf(6.0, safe.x + 4.0)
	var right := W - maxf(6.0, safe.y + 4.0)
	var ph := tasting.phase
	_rec_frame(p, left, right)
	# NA ŻYWO and the viewers
	var lw := p.chip(left + 4, 6, _w("live"), Kit.LINE, "", 0.0, Kit.ALERT)
	p.rect(left + 4, 6, lw, 13, Color(Kit.ALERT, 0.9))
	p.text(_w("live"), left + 8, 7, Kit.LINE)
	p.chip(left + 6 + lw, 6, _w("viewers").format({"n": _thousands(tasting.viewers)}), Kit.LINE)
	p.text(_w("channel"), left + 6, 21, Color(Kit.LINE, 0.8))
	# skip, top right, until the card
	if ph < Tasting.Phase.CARD:
		var label := _w("skip")
		var sw := Kit.text_w(label) + 10.0
		var sx := right - sw - 2
		p.chip(sx, 6, label, Kit.LINE, "", sw)
		if tasting.skip_t > 0.0:
			p.rect(sx, 18, sw * clampf(tasting.skip_t / Tasting.SKIP_S, 0.0, 1.0), 2, Kit.GOLD)
		_skip_rect = _grow(Rect2(sx, 6, sw, 13))
	else:
		_skip_rect = Rect2()
	_chat(p, left)
	match ph:
		Tasting.Phase.CHEW, Tasting.Phase.MLASK:
			_close_up(p)
		Tasting.Phase.DRUM, Tasting.Phase.GRADE:
			_scoreboard(p)
	if ph == Tasting.Phase.MLASK:
		_burst(p)
	if tasting.line[0] != "" and ph != Tasting.Phase.CARD:
		_line(p, left, right)
	if ph == Tasting.Phase.CARD:
		_card(p)
	if ph == Tasting.Phase.IN:
		_viewfinder(p)
	if _wipe > 0.0:
		_draw_wipe(p)


func _thousands(n: int) -> String:
	if n < 1000:
		return str(n)
	return "%d %03d" % [n / 1000, n % 1000]


## The REC corners and the dot.
func _rec_frame(p: Kit, left: float, right: float) -> void:
	var c := Color(Kit.LINE, 0.85)
	var y0 := 2.0
	var y1 := H - 3.0
	for corner in [[left, y0, 1, 1], [right, y0, -1, 1], [left, y1, 1, -1], [right, y1, -1, -1]]:
		var x: float = corner[0]
		var y: float = corner[1]
		var sx: int = corner[2]
		var sy: int = corner[3]
		p.rect(x if sx > 0 else x - 12, y if sy > 0 else y - 1, 12, 1, c)
		p.rect(x if sx > 0 else x - 1, y if sy > 0 else y - 12, 1, 12, c)
	if fmod(_t, 1.0) < 0.6:
		p.disc(W * 0.5 - 14, 11, 3, 3, Kit.ALERT)
	p.text(_w("rec"), W * 0.5 - 8, 5, Kit.LINE)


## Three chat lines bottom left, the newest at the bottom, rising in.
func _chat(p: Kit, left: float) -> void:
	var n := tasting.chat.size()
	for i in n:
		var c: Dictionary = tasting.chat[i]
		var y := H - 28.0 - (n - 1 - i) * 11.0
		var rise := clampf(float(c["t"]) / 0.2, 0.0, 1.0)
		y += roundf((1.0 - rise) * 6.0)
		var name := str(c["name"])
		var text := Lang.pick(str(c["pl"]), str(c["en"]))
		var nw := Kit.text_w(name)
		var tw := Kit.text_w(text)
		p.rect(left + 4, y - 1, nw + tw + 12, 11, Color(Kit.INK, 0.55 * rise))
		p.text(name, left + 7, y - 1, Color(Kit.GOLD, rise))
		p.text(text, left + 11 + nw, y - 1, Color(Kit.LINE, rise))


## The speaker's line bottom right (the chat keeps the left), the name on its tab.
func _line(p: Kit, left: float, right: float) -> void:
	var bw := line_w()
	var bx := right - bw
	var lines := Kit.wrap(_pick(tasting.line), int(bw) - 10)
	var by := H - 8.0 - lines.size() * 10.0 - 6.0
	var name := _w("name_" + tasting.who) if tasting.who != "" else ""
	p.bubble(bx, by, bw, name, lines, bx + 20, Kit.AMBER if tasting.who == "kebabulo" else Kit.THEM, false)
	var ph := tasting.phase
	if (ph == Tasting.Phase.HELLO or ph == Tasting.Phase.VERDICT or ph == Tasting.Phase.GRADE) and tasting.t > Tasting.TAP_S and fmod(_t, 1.0) < 0.7:
		var hint := _w("tap") + " →"
		p.text(hint, right - Kit.text_w(hint) - 4, by - 10, Kit.GOLD, 1, false, true)


## The line's bubble width, half the frame at most.
func line_w() -> float:
	return minf(roundf(W * 0.5), 240.0)


## The room the chat has, left of the bubble (the check holds every chat line to it).
func chat_w() -> float:
	return W - line_w() - 6.0 - 6.0 - 14.0


## The comic panel: his face, close, chewing with his eyes shut; it slams in from the right.
func _close_up(p: Kit) -> void:
	var pw := roundf(W * 0.40)
	var ph := 132.0
	var slide := 0.0 if Access.calm or tasting.phase != Tasting.Phase.CHEW else clampf(1.0 - tasting.t / 0.15, 0.0, 1.0)
	var x := roundf(W - pw - 18 + slide * (pw + 20))
	var y := 34.0
	p.rect(x - 2, y - 2, pw + 4, ph + 4, Kit.INK)
	p.rect(x, y, pw, ph, Color("#f2a562"))
	# speed lines behind the head
	for i in 9:
		var a := float(i) / 9.0 * TAU + _t * 0.5
		var cx := x + pw * 0.5
		var cy := y + ph * 0.55
		p.rect(cx + cos(a) * pw * 0.42, cy + sin(a) * ph * 0.42, 6, 2, Color(Kit.PEARL, 0.4))
	var hx := x + pw * 0.5 - 30
	var hy := y + 26.0
	var chew := fmod(_t, 0.32) < 0.16
	# the hoodie, the head, the cap backwards
	p.rect(x + 6, y + ph - 26, pw - 12, 26, HOODIE)
	p.rect(hx, hy, 60, 62, Kit.SKIN[2])
	p.rect(hx - 4, hy + 22, 4, 14, Kit.SKIN[2])
	p.rect(hx + 60, hy + 22, 4, 14, Kit.SKIN[2])
	p.rect(hx - 2, hy - 8, 64, 12, Kit.INK)
	p.rect(hx + 50, hy - 4, 16, 5, Kit.INK)
	# the eyes shut, the brows up in bliss
	p.rect(hx + 10, hy + 18, 14, 2, Kit.HAIR_BK)
	p.rect(hx + 36, hy + 18, 14, 2, Kit.HAIR_BK)
	p.rect(hx + 11, hy + 26, 12, 2, Kit.INK)
	p.rect(hx + 37, hy + 26, 12, 2, Kit.INK)
	p.rect(hx + 27, hy + 28, 7, 10, Kit.SKIN[2].darkened(0.15))
	# the beard and the chewing mouth
	p.rect(hx + 2, hy + 40, 56, 22, Kit.HAIR_BK)
	p.rect(hx + 18, hy + 43, 24, 6 if chew else 3, Kit.MOUTH)
	if chew:
		p.rect(hx + 20, hy + 43, 20, 2, Kit.TORTILLA)
	p.rect(hx + 12, hy + 64, 36, 2, Kit.GOLD)
	# the kebab at his mouth
	p.rect(hx - 18, hy + 42, 26, 12, Kit.TORTILLA)
	p.rect(hx - 20, hy + 43, 4, 10, Kit.MEAT[1])
	p.rect(hx - 20, hy + 43, 4, 2, Kit.LETTUCE)
	p.rect(hx - 14, hy + 41, 18, 2, Kit.SAUCE_W)


## MLASK: a sticker-shaped burst, the word big inside it.
func _burst(p: Kit) -> void:
	var k := clampf(tasting.t / 0.12, 0.0, 1.0) if not Access.calm else 1.0
	var cx := roundf(W * 0.33)
	var cy := 84.0
	var rx := 74.0 * k
	var ry := 40.0 * k
	for i in 16:
		var a := float(i) / 16.0 * TAU
		var rr := 1.0 if i % 2 == 0 else 0.78
		p.rect(cx + cos(a) * rx * rr - 5, cy + sin(a) * ry * rr - 5, 11, 11, Kit.CUP)
	p.disc(cx, cy, rx * 0.9, ry * 0.86, Kit.CUP)
	p.disc(cx, cy, rx * 0.8, ry * 0.74, Kit.GOLD)
	if k >= 1.0:
		p.text(_w("mlask"), cx, cy - 12, Kit.INK, 3, true)


## The pixel scoreboard: the digits rolling, then the grade; 11 cracks it and a digit falls.
func _scoreboard(p: Kit) -> void:
	var bw := 120.0
	var bh := 46.0
	var x := roundf(W * 0.5 - bw * 0.5)
	var y := 30.0
	p.card(x, y, bw, bh, Color(Kit.INK, 0.96), Kit.GOLD)
	var txt := tasting.board_text()
	p.text(txt, x + bw * 0.42, y + 6, Kit.GOLD, 4, true)
	p.text("/ 10", x + bw - 26, y + bh - 16, Kit.LINE)
	if tasting.perfect and tasting.phase == Tasting.Phase.GRADE:
		# the crack and the fallen digit
		for i in 8:
			p.rect(x + 30 + i * 4, y + 4 + (i % 3) * 5 + i * 2, 3, 2, Kit.LINE)
		var fall := minf(tasting.t * 90.0, 140.0)
		p.text("0", x + bw - 18, y + bh - 16 + fall, Kit.LINE)
		var cw := Kit.text_w(_w("cracked")) + 8.0
		p.rect(x + bw * 0.5 - cw * 0.5, y + bh + 2, cw, 12, Color(Kit.INK, 0.9))
		p.text(_w("cracked"), x + bw * 0.5, y + bh + 3, Kit.GOLD, 1, true)


## The RECENZJA card: vertical, the order, the grade, the badge, the game's name.
func _card(p: Kit) -> void:
	var cw := 184.0
	var ch := 198.0
	var x := roundf(W * 0.5 - cw * 0.5)
	var y := 9.0
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


## Zbyszek's viewfinder closing in: black blocks giving way, the REC corners sliding in.
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
