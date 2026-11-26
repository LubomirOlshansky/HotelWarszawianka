extends Node
## The 2D kebab stand's view and touch (plan doc "First 10 minutes: Tajny klient", "The 2D kebab
## stand", Fable's art direction): kebab_stand.gd's rules drawn full screen in padel's pixel look,
## the city's 3D off while it is up (GameCtx.city_drawn), as beer pong does.
##
## The frame (a 216-row canvas, nearest-filtered over the whole screen, pixel_kit.gd's pen):
##   - the spit in the left third, lit by the grill's orange, the only warm light in the room (8
##     turning frames, 2 px of steam, the 3-frame knife smear while Kemal shaves it);
##   - Kemal in the centre behind the glass with the salad trays and three sauce bottles, a big
##     head with four faces held long (smile, focus, proud, shock), a 2x crash zoom on the extreme
##     ones;
##   - the fridge (KOLKA-KOLA, AYRANEK) and the till with the BLIP terminal on the right, "KARTĄ OD
##     20 ZŁ" taped above it; the lit board across the top with four photo panels and gold prices;
##   - the DŻEMINI flyer on the tiles, the tip jar on the counter, a nazar as silent décor;
##   - white tile, a cobalt band, a green-white fluorescent cast.
## The order is picked on buttons along the counter (each the size of a thumb, 44 pt or more); the
## pour is the finger held anywhere, a gauge with its green beside the dish. A pixel wipe in (WEJDŹ)
## and out (WYJDŹ).
##
## Art: flat rects through the kit, like the pub (no textures); the plan's Codex sprites for the
## spit and Kemal can replace `_spit` and `_kemal` later without touching the rules or the touch.
##
## Touch only (the project emulates touch from the mouse); keys for the Mac: 1-4 the buttons,
## Space the pour, Enter WYJDŹ.
##
## Cost: while it is up the city's 3D is off and the frame is two 2D canvases of about 467 x 216
## px (about 600 untextured rects); nothing per frame while it is closed.

const Stand := preload("res://scripts/kebab_stand.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Access := preload("res://scripts/access.gd")

const H := 216
const MIN_W := 384
const WIPE_S := 0.45
const BLOCK := 12.0
const ZOOM_S := 0.7
const BUBBLE_S := 3.6
const BTN_Y := 184.0
const BTN_H := 25.0
const TOUCH_PT := 44.0

## The stand closed after WYJDŹ: kebab_stand.gd `result()`.
signal finished(result: Dictionary)

var stand: Stand
var pt := 1.0
var auto_play := false
var auto_pour := false
var log_on := false
var inside := false
## The wallet's złoty for the chip (the owner keeps it current) and the tip's payment: () -> bool.
var zl := 0
var pay_tip := Callable()
## (name) -> void: a UI cue (hud.gd cue: tick, win, fail); empty in checks.
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
var _wipe := 1.0
var _leaving := false
var _finger := false
var _key_finger := false
var _zoom_t := 0.0
var _zoom_at := Vector2.ZERO
var _face := "smile"
var _face_t := 0.0
var _hits: Array = []
var _press := -1
var _press_t := 0.0
var _last_phase := -1
var _last_line := ""
var _auto_t := 0.0


func _ready() -> void:
	set_process(false)


# --- in and out ---------------------------------------------------------------------------------

## The stand `id` (data/kebab_stand.json); `who` asks "Dla kogo?".
func open(id := "kemal", who := true) -> void:
	if _layer == null:
		_build()
	stand = Stand.new(id, who)
	stand.auto_play = auto_play
	stand.auto_pour = auto_pour
	_t = 0.0
	_wipe = 1.0
	_leaving = false
	_finger = false
	_key_finger = false
	_zoom_t = 0.0
	_face = "smile"
	_last_phase = -1
	_last_line = ""
	_auto_t = 0.0
	inside = true
	_layer.visible = true
	_resize()
	set_process(true)
	_log("open %s" % id)


func _leave() -> void:
	if _leaving or not stand.leave():
		return
	_leaving = true
	_cue("tick")
	_log("leave: " + stand.summary())


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
	finished.emit(stand.result())


func _log(text: String) -> void:
	if log_on:
		print("kebab stand: " + text)


func _cue(n: String) -> void:
	if cue.is_valid():
		cue.call(n)


func _w(tag: String) -> String:
	var p: Array = Stand.say(tag, stand.words() if stand != null else "kemal")
	return Lang.pick(str(p[0]), str(p[1]))


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


## The safe area's left and right insets in canvas px.
func _safe_canvas() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var s := get_viewport().get_visible_rect().size
	var safe: Rect2 = ScreenPoints.measure(s)["safe"]
	var k := _scale()
	return Vector2(safe.position.x / k, (s.x - safe.end.x) / k)


## The smallest touch target in canvas px (44 pt).
func _touch_px() -> float:
	if not is_inside_tree():
		return 24.0
	return TOUCH_PT * pt / _scale()


# --- the frame ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside:
		return
	_t += dt
	_press_t = maxf(0.0, _press_t - dt)
	if _leaving:
		_wipe = minf(1.0, _wipe + dt / WIPE_S)
		if _wipe >= 1.0:
			_close()
			return
	else:
		_wipe = maxf(0.0, _wipe - dt / WIPE_S)
		if _wipe <= 0.0 or auto_play:
			stand.tick(dt, _finger or _key_finger)
	_react(dt)
	if auto_play and stand.phase == Stand.Phase.DONE and not _leaving:
		_auto_t += dt
		if _auto_t >= Stand.AUTO_DONE_S:
			_leave()
	_zoom_t = maxf(0.0, _zoom_t - dt)
	_scene.transform = Transform2D(0.0, Vector2(2, 2), 0.0, -_zoom_at) if _zoom_t > 0.0 else Transform2D.IDENTITY
	_scene.queue_redraw()
	_ui.queue_redraw()


## The faces, the zooms and the cues as the rules move on.
func _react(dt: float) -> void:
	_face_t += dt
	var p := int(stand.phase)
	if p != _last_phase:
		_last_phase = p
		match stand.phase:
			Stand.Phase.DISH, Stand.Phase.SAUCE, Stand.Phase.WHO:
				_set_face("smile")
			Stand.Phase.BUILD:
				if stand.cam:
					_set_face("proud")
					_crash(Vector2(_kx(), 76), 0.4)
				else:
					_set_face("focus")
				_log("order: " + "/".join(stand.picks))
			Stand.Phase.POUR:
				_set_face("smile")
			Stand.Phase.PAY:
				_cue("tick")
			Stand.Phase.DONE:
				_set_face("smile")
				_log("paid %d zl" % stand.price())
	if stand.line != _last_line:
		_last_line = stand.line
		if stand.line != "":
			_cue("voice_kemal")
		match stand.line:
			"pour_good":
				_set_face("proud")
				_crash(Vector2(_kx(), 140))
				_cue("win")
				_log("pour good %.2f" % stand.level)
			"pour_dry":
				_set_face("focus")
				_log("pour dry %.2f" % stand.level)
			"pour_jacket":
				_set_face("shock")
				_crash(Vector2(_kx(), 78))
				_cue("fail")
				_log("pour jacket %.2f" % stand.level)


func _set_face(f: String) -> void:
	_face = f
	_face_t = 0.0


## The integer 2x crash zoom on a face or the dish, held ZOOM_S (not under the calm setting).
func _crash(at: Vector2, hold := ZOOM_S) -> void:
	if Access.calm:
		return
	_zoom_at = Vector2(clampf(at.x, W * 0.25, W * 0.75), clampf(at.y, H * 0.25, H * 0.75))
	_zoom_t = hold


# --- touch --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not inside or _leaving:
		return
	var vp := get_viewport()
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.index != 0:
			return
		if e.pressed:
			_down(_to_canvas(e.position))
		else:
			_finger = false
		vp.set_input_as_handled()
	elif event is InputEventScreenDrag:
		vp.set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		if k.keycode == KEY_SPACE:
			_key_finger = k.pressed
		elif k.pressed and k.keycode >= KEY_1 and k.keycode <= KEY_4:
			_act(int(k.keycode - KEY_1))
		elif k.pressed and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER):
			_leave()
		vp.set_input_as_handled()


func _down(c: Vector2) -> void:
	if _wipe > 0.2:
		return
	if stand.phase == Stand.Phase.POUR:
		_finger = true
		return
	for h: Array in _hits:
		if (h[0] as Rect2).has_point(c):
			_press = int(h[1])
			_press_t = 0.15
			_tap(str(h[2]), int(h[1]))
			return
	if stand.phase == Stand.Phase.HELLO:
		stand.tap_hello()


func _act(i: int) -> void:
	for h: Array in _hits:
		if str(h[2]) == "pick" and int(h[1]) == i:
			_tap("pick", i)
			return
	if i == 0:
		for h: Array in _hits:
			if str(h[2]) == "leave":
				_tap("leave", 0)
				return


func _tap(what: String, i: int) -> void:
	match what:
		"pick":
			if stand.pick(i):
				_cue("tick")
		"leave":
			_leave()
		"tip":
			if not stand.tipped and (not pay_tip.is_valid() or bool(pay_tip.call())):
				if stand.tip():
					_cue("tick")
					_set_face("proud")
					_log("tip")
		"flyer":
			stand.flyer()
			_set_face("focus")


# --- the layout ---------------------------------------------------------------------------------

func _kx() -> float:
	return roundf(W * 0.47)


func _spit_x() -> float:
	return roundf(W * 0.15)


func _glass() -> Vector2:
	return Vector2(roundf(W * 0.29), roundf(W * 0.62))


func _fridge_x() -> float:
	return W - 68.0


func _till_x() -> float:
	return W - 112.0


# --- the scene ----------------------------------------------------------------------------------

func _draw_scene() -> void:
	_wall()
	_board()
	_hood_and_spit()
	_flyer()
	_nazar()
	_card_sign()
	_fridge()
	_kemal()
	_glass_and_trays()
	_counter()
	_bottles()
	_tip_jar()
	_till()
	_order_on_counter()
	# the fluorescent cast over everything
	_pen.rect(0, 0, W, H, Kit.FLUO)


func _wall() -> void:
	var p := _pen
	p.rect(0, 0, W, 152, Kit.TILE)
	var y := 4.0
	while y < 152:
		p.rect(0, y, W, 1, Kit.GROUT)
		y += 10
	var x := 3.0
	while x < W:
		p.rect(x, 0, 1, 152, Kit.GROUT)
		x += 10
	# the cobalt band at shoulder height and its thin light line
	p.rect(0, 92, W, 8, Kit.COBALT)
	p.rect(0, 92, W, 1, Kit.COBALT_L)
	p.rect(0, 99, W, 1, Kit.COBALT_D)


## The lit menu board across the top: four photo panels, each name and its price in gold.
func _board() -> void:
	var p := _pen
	var x0 := roundf(W * 0.31)
	var x1 := W - 6.0
	p.rect(x0 - 2, 2, x1 - x0 + 4, 54, Kit.INK)
	p.rect(x0 - 2, 2, x1 - x0 + 4, 1, Kit.SLATE_L)
	var n: int = stand.dishes().size()
	if n == 0:
		return
	var gap := 3.0
	var pw := floorf((x1 - x0 - gap * (n - 1)) / n)
	for i in n:
		var px := x0 + i * (pw + gap)
		var lit := stand.phase == Stand.Phase.DISH or stand.dish == i and stand.phase > Stand.Phase.DISH
		var chosen := stand.phase > Stand.Phase.DISH and stand.dish == i
		p.rect(px, 5, pw, 28, Kit.PANEL if lit else Kit.PANEL.darkened(0.25))
		p.rect(px, 5, pw, 1, Color.WHITE)
		_dish_art(str(stand.dishes()[i].get("id", "")), px + pw * 0.5, 29, 1.0, 1.0, 0.0, Kit.SAUCE_W, i == 3)
		p.rect(px, 33, pw, 21, Kit.BOARD)
		p.text(_w("dish_%d" % i), px + pw * 0.5, 33, Kit.LINE, 1, true)
		p.text(_w("price").format({"zl": int(stand.dishes()[i].get("price", 0))}), px + pw * 0.5, 43, Kit.GOLD, 1, true)
		if chosen:
			p.frame(px - 1, 4, pw + 2, 51, Kit.GOLD)
	# the XXL's note on its panel's corner
	var lx := x0 + (n - 1) * (pw + gap)
	var note := _w("dish_3_note")
	var nw := Kit.text_w(note) + 4.0
	p.rect(lx + pw - nw, 6, nw, 9, Kit.ALERT)
	p.text(note, lx + pw - nw + 2, 5, Kit.LINE)


## The steel hood, the heater, the meat cone turning in 8 frames, the drip tray and 2 px of steam.
func _hood_and_spit() -> void:
	var p := _pen
	var sx := _spit_x()
	var frame := int(_t * 8.0) % 8
	# the grill's orange: the only warm light in the room
	p.glow(sx + 8, 74, 58, Kit.GRILL, 0.06)
	# the heater behind the cone
	p.rect(sx + 16, 22, 12, 100, Kit.STEEL_D)
	for i in 5:
		var flick := 0.75 + 0.25 * sin(_t * 9.0 + i * 1.7)
		p.rect(sx + 18, 26 + i * 19, 8, 14, Color(Kit.GRILL, flick))
		p.rect(sx + 19, 28 + i * 19, 6, 2, Color(Kit.AMBER_L, flick))
	# the hood
	p.rect(sx - 34, 0, 70, 12, Kit.STEEL)
	p.rect(sx - 34, 11, 70, 2, Kit.STEEL_D)
	for i in 6:
		p.rect(sx - 28 + i * 10, 4, 6, 1, Kit.STEEL_D)
	# the rod
	p.rect(sx - 1, 12, 2, 128, Kit.CHROME)
	# the cone: wide at the top, narrow at the bottom; bands of four browns turning
	var top := 26.0
	var bottom := 118.0
	var shave := _shave()
	for y in range(int(top), int(bottom)):
		var k := (y - top) / (bottom - top)
		var hw := roundf(lerpf(22.0, 9.0, k) - shave * 3.0 * (1.0 - k))
		var band := (int(y / 3.0) + frame) % 4
		var c: Color = Kit.MEAT[band]
		p.rect(sx - hw, y, hw * 2.0, 1, c)
		# the heater's side is lit, the far side in shade
		p.rect(sx + hw - 4, y, 4, 1, c.lightened(0.22))
		p.rect(sx - hw, y, 3, 1, c.darkened(0.25))
		if (y + frame * 3) % 11 == 0:
			p.rect(sx - hw + 4 + (frame * 5) % maxi(1, int(hw)), y, 3, 1, Kit.MEAT_FAT)
	p.rect(sx - 4, top - 4, 8, 4, Kit.MEAT[3])
	p.rect(sx - 2, top - 6, 4, 2, Kit.CHROME)
	# the drip tray
	p.rect(sx - 16, 128, 32, 6, Kit.STEEL)
	p.rect(sx - 16, 128, 32, 1, Kit.CHROME)
	p.rect(sx - 12, 129, 24, 2, Kit.MEAT[3].darkened(0.3))
	# steam
	for i in 3:
		var st := fmod(_t * 0.7 + i * 0.33, 1.0)
		var wx := sx - 10 + i * 10 + roundf(sin(_t * 2.0 + i) * 2.0)
		p.rect(wx, 22 - st * 16, 1, 2, Color(Kit.LINE, 0.5 * (1.0 - st)))
	# the knife smear while Kemal shaves
	if stand.phase == Stand.Phase.BUILD and stand.t >= 0.8 and stand.t < 1.8:
		var kf := int(stand.t * 12.0) % 3
		var ky := 46.0 + kf * 16.0
		p.rect(sx + 14, ky, 16, 2, Kit.CHROME)
		p.rect(sx + 10 - kf * 3, ky + 2, 18, 1, Color(Kit.LINE, 0.6))
		p.rect(sx + 6 - kf * 3, ky + 3, 12, 1, Color(Kit.LINE, 0.3))
		# the shavings falling into the tray
		for i in 4:
			var fy := fmod(stand.t * 60.0 + i * 13.0, 50.0)
			p.rect(sx + 10 + i * 2, ky + 4 + fy, 2, 1, Kit.MEAT[i % 4])


## How far the cone has been shaved (0..1), for its outline.
func _shave() -> float:
	if stand.phase == Stand.Phase.BUILD:
		return clampf((stand.t - 0.8) / 1.0, 0.0, 1.0)
	return 1.0 if stand.phase > Stand.Phase.BUILD else 0.0


## DŻEMINI KEBAB's flyer taped to the tiles: a tap toy.
func _flyer() -> void:
	var p := _pen
	var fx := roundf(W * 0.215)
	var fy := 58.0
	p.rect(fx, fy, 42, 30, Kit.DZEMINI)
	p.rect(fx, fy, 42, 10, Kit.DZEMINI_L)
	p.text(_w("flyer_name"), fx + 21, fy, Kit.LINE, 1, true)
	p.text("AI", fx + 21, fy + 10, Kit.GOLD, 1, true)
	# the sparkle the rival's ads always have
	var tw := 1.0 if int(_t * 2.0) % 2 == 0 else 0.0
	p.rect(fx + 33, fy + 14, 1, 5, Kit.GOLD)
	p.rect(fx + 31, fy + 16, 5, 1, Kit.GOLD)
	p.px(fx + 8, fy + 15 + tw, Kit.LINE)
	p.rect(fx + 4, fy + 22, 34, 1, Color(Kit.LINE, 0.6))
	p.rect(fx + 4, fy + 25, 26, 1, Color(Kit.LINE, 0.6))
	# tape
	p.rect(fx - 2, fy - 1, 6, 2, Color(Kit.PAPER_D, 0.85))
	p.rect(fx + 38, fy - 1, 6, 2, Color(Kit.PAPER_D, 0.85))
	_hit(Rect2(fx, fy, 42, 30), -1, "flyer")


## The nazar hanging off the board's corner: silent décor.
func _nazar() -> void:
	var p := _pen
	var nx := roundf(W * 0.31) + 14
	var sway := roundf(sin(_t * 1.3) * 1.0)
	p.rect(nx, 56, 1, 6, Kit.CHALK_D)
	p.disc(nx + sway, 66, 4, 4, Kit.COBALT)
	p.disc(nx + sway, 66, 3, 3, Kit.LINE)
	p.disc(nx + sway, 66, 2, 2, Kit.THEM)
	p.px(nx + sway, 66, Kit.INK)


## "KARTĄ OD 20 ZŁ" taped on the wall over the till.
func _card_sign() -> void:
	var p := _pen
	var x := _till_x() - 4
	p.rect(x, 97, 50, 22, Kit.FOAM)
	p.rect(x, 97, 50, 1, Color.WHITE)
	p.text(_w("card_1"), x + 25, 97, Kit.INK, 1, true)
	p.text(_w("card_2"), x + 25, 107, Kit.CUP, 1, true)
	p.rect(x + 20, 96, 10, 2, Color(Kit.PAPER_D, 0.85))


func _fridge() -> void:
	var p := _pen
	var x := _fridge_x()
	var w := 62.0
	p.rect(x, 58, w, 92, Kit.CHROME)
	p.rect(x, 58, w, 10, Kit.CUP)
	p.text("KOLKA-KOLA", x + w * 0.5, 58, Kit.LINE, 1, true)
	p.rect(x + 3, 70, w - 6, 78, Kit.FRIDGE)
	for shelf in 3:
		var sy := 74.0 + shelf * 24.0
		p.rect(x + 3, sy + 19, w - 6, 1, Kit.CHROME)
		for i in 7:
			var bx := x + 6 + i * 7.6
			match shelf:
				0:
					p.rect(bx, sy + 8, 5, 11, Kit.CUP)
					p.rect(bx, sy + 8, 5, 1, Kit.CHROME)
					p.rect(bx + 1, sy + 12, 3, 2, Kit.LINE)
				1:
					p.rect(bx + 1, sy + 4, 3, 3, Kit.COBALT)
					p.rect(bx, sy + 7, 5, 12, Kit.LINE)
					p.rect(bx, sy + 11, 5, 3, Kit.COBALT)
				_:
					var c := Kit.GO if i % 2 == 0 else Kit.AMBER
					p.rect(bx, sy + 6, 5, 13, c)
					p.rect(bx + 1, sy + 3, 3, 3, c.darkened(0.2))
	p.rect(x + 3, 70, 3, 78, Color(Color.WHITE, 0.35))
	p.rect(x + w - 8, 96, 2, 14, Kit.STEEL_D)
	# the yoghurt drink's own sticker
	p.rect(x + 8, 120, w - 16, 9, Kit.COBALT)
	p.text("AYRANEK", x + w * 0.5, 119, Kit.LINE, 1, true)


## Kemal: a big head, a thick moustache, the white shirt and apron, a paper cap; his face now.
func _kemal() -> void:
	var p := _pen
	var kx := _kx()
	# during the shave he turns to the spit, then comes back
	if stand.phase == Stand.Phase.BUILD:
		var k := 0.0
		if stand.t < 0.4:
			k = 0.0  # a beat at the counter first (the camera's crash zoom on his face)
		elif stand.t < 0.8:
			k = (stand.t - 0.4) / 0.4
		elif stand.t < 1.8:
			k = 1.0
		elif stand.t < 2.2:
			k = 1.0 - (stand.t - 1.8) / 0.4
		kx = roundf(lerpf(kx, _spit_x() + 52.0, k))
	var bob := roundf(sin(_t * 2.2)) if stand.phase != Stand.Phase.BUILD else 0.0
	var top := 60.0 + bob
	# body: the shirt, the apron, the arms on the counter
	p.rect(kx - 21, top + 30, 42, 64, Kit.LINE)
	p.rect(kx - 21, top + 30, 42, 3, Kit.CHALK_D)
	p.rect(kx - 13, top + 40, 26, 54, Kit.APRON)
	p.rect(kx - 13, top + 40, 26, 1, Kit.APRON.lightened(0.3))
	p.rect(kx - 2, top + 30, 4, 10, Kit.SKIN[3])
	var arm_y := top + 48 + (roundf(sin(stand.t * 20.0) * 3.0) if stand.phase == Stand.Phase.BUILD and stand.t > 1.8 else 0.0)
	p.rect(kx - 27, top + 34, 7, 20, Kit.LINE)
	p.rect(kx + 20, top + 34, 7, 20, Kit.LINE)
	p.rect(kx - 27, arm_y + 6, 7, 6, Kit.SKIN[3])
	p.rect(kx + 20, arm_y + 6, 7, 6, Kit.SKIN[3])
	if stand.phase == Stand.Phase.BUILD and stand.t >= 0.6 and stand.t < 1.8:
		# the long knife toward the spit
		p.rect(kx - 44, arm_y + 7, 18, 2, Kit.CHROME)
		p.rect(kx - 28, arm_y + 6, 3, 4, Kit.WOOD_D)
	# the head: 30 x 30, big on purpose
	var hx := kx - 15
	p.rect(hx, top, 30, 30, Kit.SKIN[3])
	p.rect(hx, top + 26, 30, 4, Kit.SKIN[3].darkened(0.12))
	p.rect(hx - 2, top + 11, 2, 8, Kit.SKIN[3])
	p.rect(hx + 30, top + 11, 2, 8, Kit.SKIN[3])
	# hair, the cap
	p.rect(hx, top - 2, 30, 6, Kit.HAIR_BK)
	p.rect(hx + 2, top - 8, 26, 7, Kit.LINE)
	p.rect(hx + 2, top - 8, 26, 1, Color.WHITE)
	p.rect(hx + 2, top - 2, 26, 1, Kit.CHALK_D)
	p.rect(hx + 10, top - 6, 10, 3, Kit.CUP)
	_face_art(hx, top)


func _face_art(hx: float, top: float) -> void:
	var p := _pen
	var blink := fmod(_t, 3.3) < 0.12
	var brow := top + 8
	match _face:
		"shock":
			brow -= 3
		"focus":
			brow += 1
	# the eyebrows: thick, the face's loudest part
	p.rect(hx + 5, brow, 8, 2, Kit.HAIR_BK)
	p.rect(hx + 17, brow, 8, 2, Kit.HAIR_BK)
	# the eyes
	match _face:
		"shock":
			p.rect(hx + 6, top + 9, 6, 6, Kit.LINE)
			p.rect(hx + 18, top + 9, 6, 6, Kit.LINE)
			p.rect(hx + 8, top + 11, 2, 2, Kit.INK)
			p.rect(hx + 20, top + 11, 2, 2, Kit.INK)
		"proud":
			p.rect(hx + 6, top + 13, 6, 1, Kit.INK)
			p.rect(hx + 18, top + 13, 6, 1, Kit.INK)
			p.px(hx + 5, top + 12, Kit.INK)
			p.px(hx + 24, top + 12, Kit.INK)
		"focus":
			p.rect(hx + 7, top + 12, 4, 1, Kit.INK)
			p.rect(hx + 19, top + 12, 4, 1, Kit.INK)
		_:
			if blink:
				p.rect(hx + 7, top + 13, 4, 1, Kit.INK)
				p.rect(hx + 19, top + 13, 4, 1, Kit.INK)
			else:
				p.rect(hx + 7, top + 11, 4, 3, Kit.LINE)
				p.rect(hx + 19, top + 11, 4, 3, Kit.LINE)
				p.rect(hx + 8, top + 12, 2, 2, Kit.INK)
				p.rect(hx + 20, top + 12, 2, 2, Kit.INK)
	# the nose
	p.rect(hx + 13, top + 14, 4, 5, Kit.SKIN[3].darkened(0.18))
	# the moustache, and the mouth under it
	p.rect(hx + 6, top + 19, 18, 3, Kit.HAIR_BK)
	p.rect(hx + 4, top + 21, 4, 2, Kit.HAIR_BK)
	p.rect(hx + 22, top + 21, 4, 2, Kit.HAIR_BK)
	match _face:
		"shock":
			p.rect(hx + 12, top + 23, 6, 5, Kit.MOUTH)
		"proud", "smile":
			p.rect(hx + 9, top + 23, 12, 2, Kit.MOUTH)
			p.rect(hx + 10, top + 23, 10, 1, Kit.LINE)
		_:
			p.rect(hx + 11, top + 24, 8, 1, Kit.MOUTH)
	if _face == "proud":
		p.rect(hx + 3, top + 17, 3, 2, Color(Kit.CUP_L, 0.6))
		p.rect(hx + 24, top + 17, 3, 2, Color(Kit.CUP_L, 0.6))
	if _face == "shock":
		for i in 3:
			p.rect(hx - 6 - i * 2, top - 4 + i * 6, 3, 1, Kit.INK)
			p.rect(hx + 33 + i * 2, top - 4 + i * 6, 3, 1, Kit.INK)


## The sneeze guard and the salad trays behind it.
func _glass_and_trays() -> void:
	var p := _pen
	var g := _glass()
	var colours: Array[Color] = [Kit.LETTUCE, Kit.TOMATO, Kit.ONION, Kit.CABBAGE, Kit.CUCUMBER, Kit.CABBAGE_R]
	var n := colours.size()
	var tw := floorf((g.y - g.x - 8) / n)
	for i in n:
		var tx := g.x + 4 + i * tw
		p.rect(tx, 136, tw - 2, 10, Kit.STEEL_D)
		p.rect(tx + 1, 136, tw - 4, 4, colours[i])
		for j in 3:
			p.px(tx + 2 + (j * 5 + i) % maxi(1, int(tw) - 5), 137 + j % 2, colours[i].lightened(0.3))
	# the glass: a pale sheet, its top edge and one glint
	p.rect(g.x, 114, g.y - g.x, 32, Color(Kit.GLASS_C, 0.18))
	p.rect(g.x, 114, g.y - g.x, 1, Color(Color.WHITE, 0.7))
	p.rect(g.x, 115, 1, 31, Color(Color.WHITE, 0.4))
	p.rect(g.y - 1, 115, 1, 31, Color(Color.WHITE, 0.4))
	var gl := g.x + 12 + fmod(_t * 6.0, g.y - g.x - 30)
	p.rect(gl, 116, 1, 10, Color(Color.WHITE, 0.35))
	p.rect(gl + 3, 116, 1, 6, Color(Color.WHITE, 0.25))


func _counter() -> void:
	var p := _pen
	p.rect(0, 146, W, 6, Kit.STEEL)
	p.rect(0, 146, W, 1, Kit.CHROME)
	p.rect(0, 151, W, 1, Kit.STEEL_D)
	p.rect(0, 152, W, 64, Kit.TILE)
	var y := 156.0
	while y < H:
		p.rect(0, y, W, 1, Kit.GROUT)
		y += 8
	var x := 1.0
	while x < W:
		p.rect(x, 152, 1, 64, Kit.GROUT)
		x += 8
	# a cobalt chequer on the front and a kick strip
	for i in range(0, int(W / 16.0) + 1):
		p.rect(i * 16 + 1, 160, 7, 7, Kit.COBALT)
	p.rect(0, 208, W, 8, Kit.STEEL_D)


## Three squeeze bottles on the counter: garlic, mixed, hot.
func _bottles() -> void:
	var p := _pen
	var bx := _glass().y + 6
	var n: int = stand.sauces().size()
	for i in n:
		var x := bx + i * 9
		var c := _sauce_colour(i)
		var lift := 2.0 if stand.phase == Stand.Phase.SAUCE else 0.0
		if stand.phase >= Stand.Phase.POUR and i == stand.sauce:
			continue  # it is in your hand
		p.rect(x, 128 - lift, 7, 18, c)
		p.rect(x, 128 - lift, 2, 18, c.lightened(0.2))
		p.rect(x + 2, 124 - lift, 3, 4, c.darkened(0.15))
		p.rect(x + 3, 121 - lift, 1, 3, Kit.LINE)
		p.rect(x + 1, 134 - lift, 5, 4, Kit.LINE if i != 0 else Kit.COBALT)


func _sauce_colour(i: int) -> Color:
	if stand.sauces().is_empty():
		return Kit.SAUCE_W
	match str(stand.sauces()[clampi(i, 0, stand.sauces().size() - 1)].get("colour", "white")):
		"pink":
			return Kit.SAUCE_P
		"red":
			return Kit.SAUCE_R
	return Kit.SAUCE_W


## The tip jar: a tap toy (2 zł, Kemal's blessing).
func _tip_jar() -> void:
	var p := _pen
	var x := _glass().x - 22
	p.rect(x, 132, 14, 14, Color(Kit.GLASS_C, 0.4))
	p.rect(x, 132, 14, 1, Color.WHITE)
	p.rect(x + 1, 131, 12, 1, Kit.CHROME)
	for i in (6 if stand.tipped else 3):
		p.rect(x + 2 + (i * 4) % 10, 143 - int(i / 3.0) * 2, 3, 2, Kit.GOLD)
	p.rect(x + 2, 136, 10, 5, Kit.FOAM)
	p.text(_w("tip_jar"), x + 7, 133, Kit.INK, 1, true)
	_hit(Rect2(x, 128, 14, 18), -1, "tip")


## The till and the BLIP terminal; the terminal's screen lights up on PAY.
func _till() -> void:
	var p := _pen
	var x := _till_x()
	p.rect(x, 126, 34, 20, Kit.SLATE_L)
	p.rect(x, 126, 34, 1, Kit.CHROME)
	p.rect(x + 3, 120, 28, 7, Kit.SLATE_D)
	p.rect(x + 5, 121, 24, 4, Kit.GO.darkened(0.5))
	for i in 4:
		p.rect(x + 4 + i * 7, 131, 5, 3, Kit.CHALK_D)
		p.rect(x + 4 + i * 7, 136, 5, 3, Kit.CHALK_D)
	# the terminal
	var tx := x + 38
	p.rect(tx, 128, 12, 18, Kit.INK)
	var lit := stand.phase >= Stand.Phase.PAY
	var blink := lit and stand.phase == Stand.Phase.PAY and int(stand.t * 6.0) % 2 == 0
	p.rect(tx + 2, 130, 8, 6, Kit.GO if lit and not blink else Kit.SLATE_D)
	for i in 3:
		p.rect(tx + 2 + i * 3, 139, 2, 2, Kit.CHALK_D)


## The order on the counter: built, then poured; in your hand the bottle and your sleeve.
func _order_on_counter() -> void:
	if stand.phase < Stand.Phase.BUILD:
		return
	var p := _pen
	var cx := _kx()
	var base := 146.0
	var progress := 1.0
	if stand.phase == Stand.Phase.BUILD:
		progress = clampf((stand.t - 1.8) / (Stand.BUILD_S - 1.8), 0.0, 1.0)
		if stand.t < 1.8:
			return
	var sc := _sauce_colour(stand.sauce)
	var poured := stand.level / maxf(stand.green().y, 0.01)
	var dish_id := str(stand.dishes()[stand.dish].get("id", "")) if not stand.dishes().is_empty() else "bun"
	_dish_art(dish_id, cx, base, 2.0, progress, poured if stand.phase >= Stand.Phase.POUR else 0.0, sc)
	if stand.cam:
		# the VIP kebab's sparklers
		for i in 2:
			var sx := cx - 6 + i * 12
			p.rect(sx, base - 34, 1, 12, Kit.CHALK_D)
			for k in 4:
				var a := _t * 13.0 + k * 1.6 + i
				p.px(sx + roundf(cos(a) * 3.0), base - 35 + roundf(sin(a) * 3.0), Kit.GOLD)
	if stand.phase == Stand.Phase.POUR:
		_pour_hand(cx, base, sc)
		_gauge(cx - 44, sc)
	if stand.pour == "jacket" and stand.phase == Stand.Phase.POUR:
		_jacket(sc)


## The dish: bun, wrap, box or the XXL (`s` its size, `progress` how far it is rolled, `sauce`
## 0..1+ how much sauce is on it).
func _dish_art(id: String, cx: float, base: float, s: float, progress: float, sauce: float, sc: Color, label := false) -> void:
	var p := _pen
	var w := roundf(18.0 * s)
	var h := roundf(9.0 * s)
	match id:
		"bun":
			p.rect(cx - w * 0.5, base - h * 0.5, w, h * 0.5, Kit.BUN_D)
			p.rect(cx - w * 0.5 + 1, base - h * 0.5 - 2, w - 2, 3, Kit.MEAT[1])
			p.rect(cx - w * 0.5 + 2, base - h * 0.5 - 3, 4, 2, Kit.LETTUCE)
			p.rect(cx + 2, base - h * 0.5 - 3, 3, 2, Kit.TOMATO)
			var lid := roundf(lerpf(-6.0 * s, 0.0, progress))
			p.rect(cx - w * 0.5 + 1, base - h - 2 + lid, w - 2, h * 0.5, Kit.BUN)
			p.rect(cx - w * 0.5 + 3, base - h - 3 + lid, w - 6, 1, Kit.BUN)
			p.px(cx - 3, base - h + lid, Kit.FOAM)
			p.px(cx + 2, base - h - 1 + lid, Kit.FOAM)
		"wrap", "xxl":
			var ww := w * (1.6 if id == "xxl" else 1.0)
			var hh := roundf(lerpf(h * 1.2, h * 0.8, progress))
			p.rect(cx - ww * 0.5, base - hh, ww, hh, Kit.TORTILLA)
			p.rect(cx - ww * 0.5, base - hh, ww, 1, Kit.TORTILLA.lightened(0.15))
			for i in int(ww / 5.0):
				p.px(cx - ww * 0.5 + 2 + i * 5, base - hh * 0.5, Kit.BUN_D)
			p.rect(cx - ww * 0.5 - 2, base - hh + 1, 3, hh - 2, Kit.MEAT[1])
			p.px(cx - ww * 0.5 - 2, base - hh + 1, Kit.LETTUCE)
			if id == "xxl":
				# the pick with its flag
				p.rect(cx + ww * 0.5 - 6, base - hh - 8, 1, 8, Kit.WOOD_L)
				p.rect(cx + ww * 0.5 - 5, base - hh - 8, 7, 4, Kit.CUP)
		"box":
			var bw := w * 1.1
			p.rect(cx - bw * 0.5, base - h, bw, h, Kit.KRAFT)
			p.rect(cx - bw * 0.5, base - h, bw, 1, Kit.KRAFT.lightened(0.2))
			p.rect(cx - bw * 0.5 + 2, base - h - 2, bw - 4, 3, Kit.MEAT[1])
			for i in 4:
				p.rect(cx - bw * 0.5 + 3 + i * (bw - 6) / 4.0, base - h - 4, 2, 3, Kit.FRIES)
			var lid_h := roundf(lerpf(h, 2.0, progress))
			p.rect(cx - bw * 0.5, base - h - lid_h - 1, bw, 2, Kit.KRAFT.darkened(0.1))
			p.rect(cx - bw * 0.5, base - h - lid_h, 2, lid_h, Kit.KRAFT.darkened(0.2))
	if label:
		p.text("XXL", cx, base - h - 14, Kit.GOLD, 1, true)
	if sauce > 0.0:
		var sw := roundf(clampf(sauce, 0.0, 1.4) * w * 0.8)
		p.rect(cx - sw * 0.5, base - h - 2, sw, 2, sc)
		if sauce > 1.0:
			p.rect(cx - sw * 0.5 - 2, base - h, 2, 4, sc)
			p.rect(cx + sw * 0.5, base - h + 1, 2, 5, sc)


## Your hand from the bottom right holding the bottle over the dish: upright, or tipped and
## streaming while the finger is down. Outlined, so the white garlic bottle reads on the shirt.
func _pour_hand(cx: float, base: float, sc: Color) -> void:
	var p := _pen
	var pouring := (_finger or _key_finger or ((stand.auto_pour or stand.auto_play) and stand.t >= 0.5)) and stand.pour == ""
	var nx := cx + 2.0
	var ny := base - 30.0
	var hx := cx + 22.0
	var hy := base - 26.0
	if pouring:
		# tipped: the nozzle down over the dish, the body a diagonal in steps up to the hand
		for i in 7:
			p.rect(nx + 1 + i * 3 - 1, ny - 4 - i * 2 - 1, 8, 8, Kit.INK)
		for i in 7:
			p.rect(nx + 1 + i * 3, ny - 4 - i * 2, 6, 6, sc)
			p.rect(nx + 1 + i * 3, ny - 4 - i * 2, 6, 1, sc.lightened(0.25))
		p.rect(nx - 2, ny - 1, 4, 3, Kit.LINE)
		p.rect(nx - 1, ny + 2, 1, base - 20 - ny, sc)
		p.rect(nx - 1, ny + 2, 1, base - 20 - ny, Color(Kit.INK, 0.25))
		var drop := fmod(_t * 40.0, 6.0)
		p.px(nx - 1, ny + 2 + drop * 2.0, sc.lightened(0.3))
		hx = nx + 22
		hy = ny - 16
	else:
		p.rect(hx - 4, hy - 20, 9, 22, Kit.INK)
		p.rect(hx - 3, hy - 19, 7, 20, sc)
		p.rect(hx - 3, hy - 19, 2, 20, sc.lightened(0.25))
		p.rect(hx - 1, hy - 24, 3, 5, Kit.LINE)
		p.rect(hx, hy - 27, 1, 3, Kit.LINE)
	# the hand round the bottle and the sleeve to the bottom right corner: the player's orange
	p.rect(hx - 4, hy - 6, 11, 8, Kit.INK)
	p.rect(hx - 3, hy - 5, 9, 6, Kit.SKIN[1])
	var n := 48
	for i in n + 1:
		var k := float(i) / n
		var x := lerpf(hx + 4, W + 10, k)
		var y := lerpf(hy - 4, H + 10, k)
		p.rect(x - 1, y - 1, 16, 14, Kit.INK)
	for i in n + 1:
		var k := float(i) / n
		var x := lerpf(hx + 4, W + 10, k)
		var y := lerpf(hy - 4, H + 10, k)
		p.rect(x, y, 14, 12, Kit.US)
		p.rect(x, y, 14, 2, Kit.US.lightened(0.2))
	p.rect(hx + 3, hy - 5, 3, 12, Kit.US_D)


## The pour gauge: the bottle's share, its green, the line where it is now.
func _gauge(x: float, sc: Color) -> void:
	var p := _pen
	var top := 92.0
	var h := 72.0
	var g := stand.green()
	var full := stand.spill()
	p.rect(x - 1, top - 1, 10, h + 2, Kit.INK)
	p.rect(x, top, 8, h, Kit.SLATE_D)
	var gy0 := top + h * (1.0 - g.y / full)
	var gy1 := top + h * (1.0 - g.x / full)
	p.rect(x, gy0, 8, gy1 - gy0, Color(Kit.GO, 0.55))
	var lvl := clampf(stand.level / full, 0.0, 1.0)
	p.rect(x + 2, top + h * (1.0 - lvl), 4, h * lvl, sc)
	var over := stand.level > g.y
	p.rect(x - 3, top + h * (1.0 - lvl), 14, 1, Kit.ALERT if over else Kit.GOLD)


## Too much: sauce on your jacket, splats along the sleeve.
func _jacket(sc: Color) -> void:
	var p := _pen
	var from := Vector2(_kx() + 30.0, 110.0)
	var to := Vector2(W, H)
	for i in 7:
		var q := from.lerp(to, 0.08 + i * 0.09)
		p.disc(q.x + 7 + (i % 3) * 2, q.y + 4 - (i % 2) * 3, 2 + i % 3, 2, sc)
		p.px(q.x + 12, q.y + 9, sc.darkened(0.2))


# --- the interface over it ----------------------------------------------------------------------

func _draw_ui() -> void:
	var p := _ui_pen
	_hits = _hits.filter(func(h: Array) -> bool: return str(h[2]) == "tip" or str(h[2]) == "flyer")
	var safe := _safe_canvas()
	var left := maxf(6.0, safe.x + 4.0)
	var right := W - maxf(6.0, safe.y + 4.0)
	# the chips: the place, the wallet
	var sign: Array = stand.stand.get("sign", ["KEBAB", "KEBAB"])
	var cw := p.chip(left, 4, Lang.pick(str(sign[0]), str(sign[1])), Kit.GOLD)
	var paid := stand.price() if stand.phase == Stand.Phase.DONE or (stand.phase == Stand.Phase.PAY and stand.t >= 0.9) else 0
	p.chip(left + cw + 3, 4, _w("wallet").format({"zl": maxi(0, zl - paid)}), Kit.LINE, "wallet")
	# the owner's line
	if stand.line != "" and (stand.line_t < BUBBLE_S or stand.phase == Stand.Phase.HELLO or stand.phase == Stand.Phase.DONE):
		var owner: Array = stand.stand.get("owner", ["", ""])
		_say_bubble(p, Lang.pick(str(owner[0]), str(owner[1])), _w(stand.line), right)
	match stand.phase:
		Stand.Phase.HELLO:
			_caption(p, _w("hello_note"), Kit.CHALK_D)
		Stand.Phase.DISH:
			var labels: Array[String] = []
			for i in stand.dishes().size():
				labels.append("%s %s" % [_w("dish_%d" % i), _w("price").format({"zl": int(stand.dishes()[i].get("price", 0))})])
			_buttons(labels, left, right)
		Stand.Phase.SAUCE:
			var labels: Array[String] = []
			for i in stand.sauces().size():
				labels.append(_w("sauce_%d" % i))
			_buttons(labels, left, right)
		Stand.Phase.WHO:
			_buttons([_w("who_0"), _w("who_1")], left, right)
		Stand.Phase.BUILD:
			var steps := ["build_shave", "build_fill", "build_roll"]
			var k := 0 if stand.t < 1.8 else (1 if stand.t < 3.4 else 2)
			_caption(p, _w(steps[k]), Kit.LINE)
			var bar := (right - left) * 0.4
			p.rect(W * 0.5 - bar * 0.5, BTN_Y + 18, bar, 3, Kit.SLATE_D)
			p.rect(W * 0.5 - bar * 0.5, BTN_Y + 18, bar * clampf(stand.t / Stand.BUILD_S, 0.0, 1.0), 3, Kit.GOLD)
		Stand.Phase.POUR:
			if stand.pour == "":
				var hint := _w("pour_auto" if stand.auto_pour else "pour_hint")
				_caption(p, hint, Kit.GOLD)
		Stand.Phase.PAY:
			_blip(p)
		Stand.Phase.DONE:
			_blip(p)
			var bw := 110.0
			var x := W * 0.5 - bw * 0.5
			p.button(x, BTN_Y, bw, _w("btn_leave"), true, BTN_H, _press == 0 and _press_t > 0.0)
			_hit(_grow(Rect2(x, BTN_Y, bw, BTN_H)), 0, "leave")
	if _wipe > 0.0:
		_draw_wipe(p)


## The owner's line: a bubble right of his head, its tail pointing left at him.
func _say_bubble(p: Kit, name: String, text: String, right: float) -> void:
	var kx := _kx()
	if stand.phase == Stand.Phase.BUILD and stand.t >= 0.6 and stand.t < 2.0:
		kx = _spit_x() + 52.0
	var bw := 150.0
	var bx := minf(kx + 24.0, right - bw)
	var lines := Kit.wrap(text, int(bw) - 10)
	var bh := 6.0 + lines.size() * 10.0
	var by := 66.0
	p.card(bx, by, bw, bh, Color(Kit.INK, 0.94), Kit.CHALK_D)
	for i in 4:
		p.rect(bx - 1 - i, by + 8 + i * 0.5, 1, 4 - i, Color(Kit.INK, 0.94))
	var nw := Kit.text_w(name) + 6.0
	p.rect(bx + 5, by - 6, nw, 9, Kit.AMBER)
	p.text(name, bx + 8, by - 7, Kit.INK)
	for i in lines.size():
		p.text(lines[i], bx + 5, by + 2 + i * 10, Kit.LINE)


## A line of words under the scene on a dark strip (no blur of a drop shadow on the tiles).
func _caption(p: Kit, text: String, c: Color) -> void:
	var tw := Kit.text_w(text)
	p.rect(W * 0.5 - tw * 0.5 - 4, BTN_Y + 4, tw + 8, 12, Color(Kit.INK, 0.86))
	p.text(text, W * 0.5, BTN_Y + 4, c, 1, true)


## The BLIP terminal's card over the till: what was paid, or on the house.
func _blip(p: Kit) -> void:
	var x := _till_x() - 30
	var y := 154.0
	p.card(x, y, 96, 30, Color(Kit.INK, 0.94), Kit.GO)
	p.text("BLIP", x + 6, y + 2, Kit.GO)
	var paid := stand.price()
	var l := _w("blip_free") if paid == 0 else _w("blip_paid").format({"zl": paid})
	var thinking := stand.phase == Stand.Phase.PAY and stand.t < 0.9
	p.text("..." if thinking else l, x + 48, y + 15, Kit.LINE, 1, true)


## A row of buttons along the counter, each `_hit` grown to the thumb.
func _buttons(labels: Array, left: float, right: float) -> void:
	var p := _ui_pen
	var n := labels.size()
	var gap := 4.0
	var bw := floorf((right - left - gap * (n - 1)) / n)
	bw = minf(bw, 150.0)
	var total := bw * n + gap * (n - 1)
	var x0 := roundf(W * 0.5 - total * 0.5)
	for i in n:
		var x := x0 + i * (bw + gap)
		p.button(x, BTN_Y, bw, str(labels[i]), true, BTN_H, _press == i and _press_t > 0.0)
		_hit(_grow(Rect2(x, BTN_Y, bw, BTN_H)), i, "pick")


func _hit(r: Rect2, i: int, what: String) -> void:
	for h: Array in _hits:
		if str(h[2]) == what and int(h[1]) == i:
			h[0] = _grow(r)
			return
	_hits.append([_grow(r), i, what])


## A rect grown to the 44 pt thumb either way.
func _grow(r: Rect2) -> Rect2:
	var m := _touch_px()
	var g := r
	if g.size.x < m:
		g = g.grow_individual((m - g.size.x) * 0.5, 0, (m - g.size.x) * 0.5, 0)
	if g.size.y < m:
		g = g.grow_individual(0, (m - g.size.y) * 0.5, 0, (m - g.size.y) * 0.5)
	return g


## The pixel wipe: blocks in an ordered pattern, all there at 1, gone at 0.
func _draw_wipe(p: Kit) -> void:
	var cols := int(ceil(W / BLOCK))
	var rows := int(ceil(H / BLOCK))
	for by in rows:
		for bx in cols:
			var d := float((bx * 7 + by * 13) % 16) / 16.0
			if d < _wipe:
				p.rect(bx * BLOCK, by * BLOCK, BLOCK, BLOCK, Kit.VOID)
	if _wipe > 0.6 and not _leaving:
		p.text(_w("enter"), W * 0.5, H * 0.5 - 10, Kit.GOLD, 2, true, true)
