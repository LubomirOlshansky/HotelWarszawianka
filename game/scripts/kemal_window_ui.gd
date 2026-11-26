extends "res://scripts/palm_tasting_ui.gd"
## SZYBA, the Tajny klient's payoff at Kemal's window, drawn (kemal_window.gd's rules; Fable's
## critique 2026-11-26, section 3 "Sticker and payoff": "a third 2D scene, in the stand's
## grammar"): KEBAB U KEMALA's shopfront from the pavement, full screen, the city's 3D off while it
## is up (GameCtx.city_drawn, tajny_klient.gd holds it), like the stand and the tasting.
##
## The look is the tasting's (palm_tasting_ui.gd, which this extends for its pen and its people):
## flat axis-aligned rects on the 216-unit grid drawn into a 432-row nearest viewport (detail at
## half a unit), outlines through the figure buffer, no ellipses, rotations, gradients or shaders.
##   - the back (drawn once a size, its draw list kept): the tenement's plaster and first-floor
##     windows, the cornice, the lit sign KEBAB U KEMALA with its spits, inside the window the white
##     tiles and the cobalt band, the menu board, the spit glowing;
##   - Kemal behind the glass (the stand's master: the white jacket, the cap with the red band, the
##     brows, the moustache; rolled sleeves and a pencil behind the ear): smile, shock, proud, and
##     his eyes filling, then the tears, a mouth that talks his line;
##   - the front (drawn once a size): the counter and the salad trays, the window's frame and its
##     reflections, the door with the opening's balloons, the cobalt riser, the pavement's slabs;
##   - the street layer: the round MLASK sticker (a miniature of the MLASK panel: gold rays, the red
##     word, a white die-cut edge), the player's hand in the teal sleeve bottom right (or
##     Kebabulo's beige one from the right edge when he won the race), the slap's two squash
##     frames and PLASK!, the high five and PIONA!, the queue: QUEUE_N people of the street crowd
##     (Fable 4a: the oat-latte freelancer, the vinyl digger, the plant mum, the dog walker, the
##     Mordor escapee, Pani Halina, a fixie courier, a film kid) walking in from both sides at 0.8
##     scale and lining up at the door;
##   - the 216-row layer in the kit's 5x7 font: the wipe, hold-× to skip, the winner's line, the tap
##     hint, Kemal's line, and PARAGON, the receipt (the order, the grade, the pay, the respect,
##     the badges, the leak line), its DALEJ.
## Touch: a tap anywhere, a hold on the skip chip skips to the receipt. Keys: Space or Enter a tap,
## Esc held the skip. Access.calm: no shake, no squash overshoot.
##
## Cost: while it is up the city's 3D is off; the frame is the two canvases of flat rects (the back
## and the front replayed from their kept draw lists, Kemal, the sticker, the hands and up to eight
## people drawn a frame; check_kemal_window.gd bounds the count); closed, both viewports are off
## (UPDATE_DISABLED), so nothing runs.

const Win := preload("res://scripts/kemal_window.gd")

# --- the shop's palette (the stand's tiles and cobalt, an Aleje tenement at dusk) ---
const PLASTER := [Color("#b9a890"), Color("#9c8c76"), Color("#d2c3aa")]
const SIGN_RED := Color("#7a1418")
const SIGN_RIM := Color("#c8302a")
const SIGN_LIT := Color("#ffe27a")
const SIGN_GLOW := Color("#ffb020")
const FRAME_C := [Color("#3c4a4c"), Color("#2a3436"), Color("#5c6c6e")]
const GLASS_IN := Color("#2a3040")
const WARM := Color(1.0, 0.82, 0.55, 0.14)
const SHINE := Color(1.0, 1.0, 1.0, 0.10)
const TEAR := Color("#8ad8f8")
const TEAR_D := Color("#4aa8d8")
const KEMAL_SKIN := [Color("#c48d68"), Color("#a8744f"), Color("#d6a27c")]
const JACKET := [Color("#f4f2ea"), Color("#c9ccc4"), Color("#ffffff")]
const PAPER_R := Color("#f6f3ea")
const PAPER_RD := Color("#d9d2c2")
const RECEIPT_INK := Color("#2c2c34")
const RECEIPT_RED := Color("#9a2020")

## Kemal's scale (scene px a unit of his design: 3 is 1.5 units, the stand's big head behind the glass).
const KEMAL_S := 3.0
## The sticker's radius on the glass and in the hand (units).
const R_GLASS := 19.0
const R_HAND := 25.0
## The queue's feet (units), the walkers a step nearer, their scale (Fable 4a: 0.8), their pace.
const QUEUE_FEET := 205.0
const WALK_FEET := 209.0
const QUEUE_S := 0.8
const WALK_PACE := 280.0
## The receipt's width (units).
const RECEIPT_W := 170.0

## The street crowd for the queue (Fable 4a; the palette ochre, sage, rust, cream, navy, camel; no
## logos, no letters). Each: the person's spec for palm_tasting_ui.gd `_person` (minus x, f, feet).
const CROWD := [
	{"kind": "latte", "top": [Color("#c89a5a"), Color("#a07a42"), Color("#dcb47a")], "legs": [Color("#2a3040"), Color("#1a1e2a"), Color("#3c4458")],
		"shoe": Color("#f4f1e6"), "sole": Color("#c9c4b8"), "skin": [Color("#f6d4b4"), Color("#dcae8e"), Color("#fff0dc")],
		"tw": 30.0, "th": 70.0, "ll": 58.0, "hair": "beanie_grey", "hair_c": Color("#6a4a30"), "hold_f": "cup", "hold_b": "laptop"},
	{"kind": "vinyl", "top": [Color("#4d6492"), Color("#34466e"), Color("#7f9ac0")], "legs": [Color("#7a7a4a"), Color("#5c5c36"), Color("#949464")],
		"shoe": Color("#4a3220"), "sole": Color("#2a2630"), "skin": [Color("#e2b08a"), Color("#c48d68"), Color("#f1c8a4")],
		"tw": 28.0, "th": 62.0, "ll": 64.0, "hair": "curls", "hair_c": Color("#3a2618"), "hold_b": "records", "tache": true},
	{"kind": "plant", "top": [Color("#8aa37a"), Color("#6a8360"), Color("#a8c098")], "legs": [Color("#8aa37a"), Color("#6a8360"), Color("#a8c098")],
		"shoe": Color("#e8e0cc"), "sole": Color("#c8a06a"), "skin": [Color("#f1c8a4"), Color("#d9a984"), Color("#ffdcc0")],
		"tw": 26.0, "th": 56.0, "ll": 58.0, "hh": 28.0, "hair": "bun", "hair_c": Color("#8a3a1e"), "front": "hold", "hold_f": "monstera"},
	{"kind": "dog", "top": [Color("#6f8a62"), Color("#56704c"), Color("#8aa37a")], "legs": [Color("#2a3550"), Color("#1c2438"), Color("#3c4868")],
		"shoe": Color("#2a2630"), "sole": Color("#6b737a"), "skin": [Color("#f6d4b4"), Color("#dcae8e"), Color("#fff0dc")],
		"tw": 30.0, "th": 74.0, "ll": 52.0, "hair": "bucket", "hair_c": Color("#c8a06a"), "hold_f": "lead"},
	{"kind": "mordor", "top": [Color("#cfe0f0"), Color("#a8bccf"), Color("#eef6ff")], "legs": [Color("#3a3e46"), Color("#2a2e34"), Color("#4e525c")],
		"shoe": Color("#2a2630"), "sole": Color("#16151b"), "skin": [Color("#f1c8a4"), Color("#d9a984"), Color("#ffdcc0")],
		"tw": 28.0, "th": 64.0, "ll": 66.0, "hair": "short", "hair_c": Color("#2a2a2a"), "hold_b": "helmet"},
	{"kind": "halina", "top": [Color("#2a3550"), Color("#1c2438"), Color("#3c4868")], "legs": [Color("#3a3e46"), Color("#2a2e34"), Color("#4e525c")],
		"shoe": Color("#4a3220"), "sole": Color("#2a2630"), "skin": [Color("#f1c8a4"), Color("#d9a984"), Color("#ffdcc0")],
		"tw": 28.0, "th": 62.0, "ll": 50.0, "hh": 28.0, "hair": "beret", "hair_c": Color("#bcbcbc"), "hold_b": "trolley"},
	{"kind": "courier", "top": [Color("#b5532a"), Color("#8a3a1e"), Color("#d0744a")], "legs": [Color("#2a3040"), Color("#1a1e2a"), Color("#3c4458")],
		"shoe": Color("#e8e0cc"), "sole": Color("#2a2630"), "skin": [Color("#e2b08a"), Color("#c48d68"), Color("#f1c8a4")],
		"tw": 26.0, "th": 60.0, "ll": 66.0, "hair": "cyclecap", "hair_c": Color("#4a2e1a"), "tache": true},
	{"kind": "analog", "top": [Color("#c8963a"), Color("#a0742a"), Color("#e0b460")], "legs": [Color("#e8e0cc"), Color("#c9c0aa"), Color("#f6f0e0")],
		"shoe": Color("#2a2630"), "sole": Color("#e8e0cc"), "skin": [Color("#f6d4b4"), Color("#dcae8e"), Color("#fff0dc")],
		"tw": 28.0, "th": 60.0, "ll": 62.0, "hair": "short", "hair_c": Color("#1e1a18"), "hold_b": "tote", "glasses": true},
]

var win: Win
var _kemal_n: Node2D
var _front: Node2D
var _street: Node2D
var _ready_line := ""
var _plask_at := -1.0


# --- in and out ---------------------------------------------------------------------------------

## `spec` as kemal_window.gd's `_init`.
func open(spec: Dictionary) -> void:
	if _layer == null:
		_build()
	win = Win.new(spec)
	win.auto_play = auto_play
	_t = 0.0
	_wipe = 1.0
	_leaving = false
	_skip_held = false
	_key_skip = false
	_last_phase = -1
	_last_said = ""
	_shake = 0.0
	_plask_at = -1.0
	inside = true
	_layer.visible = true
	_live(true)
	_resize()
	set_process(true)
	_log("open: %s" % ("won" if win.won else "kebabulo won"))


func _close() -> void:
	inside = false
	_layer.visible = false
	_live(false)
	set_process(false)
	_log("done: " + win.summary())
	finished.emit(win.result())


func _log(text: String) -> void:
	if log_on:
		print("kemal window: " + text)


func _w(tag: String) -> String:
	var p: Array = Win.say(tag)
	return shown(Lang.pick(str(p[0]), str(p[1])))


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
	_back.draw.connect(_draw_shop)
	_world.add_child(_back)
	_kemal_n = Node2D.new()
	_kemal_n.draw.connect(_draw_kemal)
	_world.add_child(_kemal_n)
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	_world.add_child(_front)
	_street = Node2D.new()
	_street.draw.connect(_draw_street)
	_world.add_child(_street)
	# The words: 216 rows, the kit's pen at one unit.
	_ui_vp = _viewport(true)
	_ui = Node2D.new()
	_ui.draw.connect(_draw_words)
	_ui_vp.add_child(_ui)
	_ui_pen = Kit.new(_ui)
	_tex = _shown(_vp)
	_ui_tex = _shown(_ui_vp)
	_layer.visible = false
	if is_inside_tree():
		get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	if _vp == null or not is_inside_tree():
		return
	var s := get_viewport().get_visible_rect().size
	W = maxi(MIN_W, int(round(H * s.x / maxf(s.y, 1.0))))
	_vp.size = Vector2i(W * PX, H * PX)
	_vp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(PX, PX))
	_ui_vp.size = Vector2i(W, H)
	_back.queue_redraw()
	_front.queue_redraw()
	pt = float(ScreenPoints.measure(s)["pt"])


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
		win.tick(dt, _skip_held or _key_skip)
		_wipe = clampf(1.0 - win.total / Win.IN_S, 0.0, 1.0) if win.phase == Win.Phase.IN else 0.0
		if win.done():
			_leaving = true
			_wipe = 0.0
	_react()
	_shake = maxf(0.0, _shake - dt)
	var off := Vector2.ZERO
	if _shake > 0.0 and not Access.calm:
		off = Vector2(roundf(sin(_t * 71.0) * 1.5), roundf(cos(_t * 53.0) * 1.0))
	_world.position = off
	_kemal_n.queue_redraw()
	_street.queue_redraw()
	_ui.queue_redraw()


func _react() -> void:
	var said := ""
	match win.phase:
		Win.Phase.READY:
			said = "kebabulo|" + str(win.line[0])
		Win.Phase.CRY:
			said = "kemal|" + str(win.cry[0])
	if said != _last_said:
		_last_said = said
		if said != "":
			_cue("voice_" + said.get_slice("|", 0))
	var p := int(win.phase)
	if p == _last_phase:
		return
	_last_phase = p
	match win.phase:
		Win.Phase.SLAP:
			_shake = 0.25
			_plask_at = _t
			_cue("checkpoint")
			Access.buzz(80, 1.0)
			_log("slap")
		Win.Phase.FIVE:
			_log("high five")
		Win.Phase.QUEUE:
			_log("queue")
		Win.Phase.CRY:
			_log("cry")
		Win.Phase.PARAGON:
			_cue("win")
			_log("paragon%s" % (" (skipped)" if win.skipped else ""))


## Draws one whole frame with no canvas, counting the rects (the check walks every beat with it).
func dry_frame() -> int:
	_dry = true
	rects = 0
	var ci := _ui_pen.ci
	_ui_pen.ci = null
	_ui_pen.rects = 0
	_draw_shop()
	_draw_kemal()
	_draw_front()
	_draw_street()
	_draw_words()
	_ui_pen.ci = ci
	_dry = false
	return rects + _ui_pen.rects


# --- touch --------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not inside or _leaving or win == null:
		return
	var vp := get_viewport()
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.index != 0:
			return
		var c := _to_canvas(e.position)
		if e.pressed:
			if _skip_rect.has_point(c) and win.phase < Win.Phase.PARAGON:
				_skip_held = true
			elif win.tap():
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
			if win.tap():
				_cue("tick")
		vp.set_input_as_handled()


# --- where things stand -------------------------------------------------------------------------

func _door_x() -> float:
	return roundf(W * 0.035)


func _glass_x0() -> float:
	return _door_x() + 52.0


func _glass_x1() -> float:
	return W - roundf(W * 0.03)


func _kemal_x() -> float:
	return roundf(W * 0.56)


func _spit_x() -> float:
	return _glass_x0() + 38.0


## Where the sticker goes on the glass (units): right of Kemal, at his eyes' height.
func sticker_at() -> Vector2:
	return Vector2(roundf(W * 0.80), 94.0)


## A queue place's x (units): the first at the door, the rest along the window.
func _slot_x(i: int) -> float:
	return _door_x() + 30.0 + float(i) * 23.0


# --- the back (drawn once a size) -----------------------------------------------------------------

func _draw_shop() -> void:
	_use(_back)
	# the tenement above: plaster, two first-floor windows, the cornice
	_u(0, 0, W, 34, PLASTER[0])
	for y: float in [6.0, 13.0, 20.0]:
		_u(0, y, W, 0.5, PLASTER[1])
	for i in 2:
		var wx := roundf(W * (0.22 + 0.5 * i))
		_u(wx - 1, 0, 42, 22, PLASTER[2])
		_u(wx, 0, 40, 20, Color("#3c3f52") if i == 0 else Color("#f2c97a"))
		_u(wx + 19.5, 0, 1, 20, PLASTER[2])
		_u(wx, 9.5, 40, 1, PLASTER[2])
		_u(wx - 3, 20, 46, 3, PLASTER[2])
		_u(wx - 3, 23, 46, 1, PLASTER[1])
		if i == 1:
			_u(wx + 2, 1, 6, 8, Color("#e8a85a"))
			_u(wx + 22, 11, 16, 8, Color("#e8b870"))
	_u(0, 28, W, 3, PLASTER[2])
	_u(0, 31, W, 1.5, PLASTER[1])
	_u(0, 32.5, W, 1.5, Color("#6a5e50"))
	# the sign: the dark red box, its lit rim, the name in lit letters, a spit at each end
	var sx0 := 4.0
	var sx1 := W - 4.0
	_u(sx0, 34, sx1 - sx0, 24, SIGN_RED)
	_u(sx0, 34, sx1 - sx0, 1, SIGN_RIM)
	_u(sx0, 57, sx1 - sx0, 1, Color("#4a0c0e"))
	_u(sx0, 34, 1, 24, SIGN_RIM)
	_u(sx1 - 1, 34, 1, 24, SIGN_RIM)
	var name := _w("sign").to_upper()
	var sc := 3.0 if Kit.text_w(name, 3) <= W - 90 else 2.0
	var tw := Kit.text_w(name) * sc
	var tx := roundf(W * 0.5 - tw * 0.5)
	var ty := roundf(46.0 - 3.5 * sc)
	_k_word(name, tx, ty + 0.5, sc, SIGN_GLOW)
	_k_word(name, tx, ty, sc, SIGN_LIT)
	for k in 2:
		var cx := tx - 18.0 if k == 0 else tx + tw + 18.0
		_k_cone(cx, 38.0, 0.55)
	# the glow of the sign on the plaster above it
	_u(0, 26, W, 2, Color(1.0, 0.75, 0.4, 0.18))
	# the frame's lintel
	_u(0, 58, W, 4, FRAME_C[0])
	_u(0, 58, W, 1, FRAME_C[2])
	# inside: the white tiles, warm, the cobalt band, the board, the spit
	var gx0 := _glass_x0()
	var gx1 := _glass_x1()
	_u(gx0, 62, gx1 - gx0, 88, Kit.TILE)
	var y := 66.0
	while y < 150.0:
		_u(gx0, y, gx1 - gx0, 0.5, Kit.GROUT)
		y += 7.0
	var x := gx0 + 3.0
	while x < gx1:
		_u(x, 62, 0.5, 88, Kit.GROUT)
		x += 7.0
	_u(gx0, 116, gx1 - gx0, 6, Kit.COBALT)
	_u(gx0, 116, gx1 - gx0, 0.5, Kit.COBALT_L)
	_u(gx0, 121.5, gx1 - gx0, 0.5, Kit.COBALT_D)
	_k_board(roundf(W * 0.66), gx1 - 6.0)
	_k_spit(_spit_x())
	_u(gx0, 62, gx1 - gx0, 88, WARM)


## The lit menu board inside: four photo panels with gold prices (no words, the stand's art).
func _k_board(x0: float, x1: float) -> void:
	_u(x0 - 1, 63, x1 - x0 + 2, 19, Kit.INK)
	var n := 4
	var pw := floorf((x1 - x0 - 3.0 * (n - 1)) / n)
	for i in n:
		var px := x0 + i * (pw + 3.0)
		_u(px, 64.5, pw, 10, Kit.PANEL)
		_u(px, 64.5, pw, 0.5, WHITE)
		# a dish on each photo
		var c := px + pw * 0.5
		match i:
			0:
				_u(c - 6, 69, 12, 4, Kit.BUN)
				_u(c - 6, 68, 12, 1, Kit.LETTUCE)
				_u(c - 5, 67, 10, 1, Kit.MEAT[0])
			1:
				_u(c - 3, 66.5, 6, 7, Kit.TORTILLA)
				_u(c - 2, 66, 4, 1.5, Kit.MEAT[1])
			2:
				_u(c - 6, 68, 12, 5, Kit.STEEL)
				_u(c - 5, 67, 10, 2, Kit.FRIES)
			_:
				_u(c - 8, 68, 16, 5, Kit.TORTILLA)
				_u(c - 7, 67, 14, 1.5, Kit.MEAT[1])
		_u(px + 2, 76, pw - 4, 2, Kit.GOLD)
		_u(px + 2, 79, pw * 0.5, 1, Kit.CHALK_D)


## The spit behind the glass, glowing: the heater's orange, the cone in four browns, the rod.
func _k_spit(sx: float) -> void:
	_u(sx - 22, 66, 44, 66, Color(Kit.GRILL, 0.10))
	_u(sx + 9, 70, 6, 56, Kit.STEEL_D)
	for i in 4:
		_u(sx + 10, 73 + i * 13, 4, 9, Kit.GRILL)
		_u(sx + 10.5, 74 + i * 13, 3, 1, Kit.AMBER_L)
	_u(sx - 18, 62, 36, 5, Kit.STEEL)
	_u(sx - 18, 66.5, 36, 1, Kit.STEEL_D)
	_u(sx - 0.5, 67, 1, 64, Kit.CHROME)
	var top := 74.0
	var bottom := 124.0
	var yy := top
	while yy < bottom:
		var k := (yy - top) / (bottom - top)
		var hw := roundf(lerpf(13.0, 5.0, k) * 2.0) / 2.0
		var c: Color = Kit.MEAT[int(yy / 2.0) % 4]
		_u(sx - hw, yy, hw * 2.0, 1, c)
		_u(sx + hw - 2.5, yy, 2.5, 1, c.lightened(0.22))
		_u(sx - hw, yy, 1.5, 1, c.darkened(0.25))
		yy += 1.0
	_u(sx - 2, top - 2, 4, 2, Kit.MEAT[3])
	_u(sx - 9, 128, 18, 3, Kit.STEEL)
	_u(sx - 9, 128, 18, 0.5, Kit.CHROME)


## A little turning kebab cone (the sign's ends): `s` its scale.
func _k_cone(cx: float, top: float, s: float) -> void:
	var h := roundf(30.0 * s)
	for k in int(h):
		var hw := roundf(lerpf(9.0, 3.0, float(k) / h) * s * 2.0) / 2.0
		_u(cx - hw, top + k, hw * 2.0, 1, Kit.MEAT[(k / 2) % 4])
		_u(cx + hw - 1, top + k, 1, 1, SIGN_LIT)
	_u(cx - 0.5, top - 2, 1, h + 4, Kit.CHROME)


# --- Kemal (drawn a frame) ------------------------------------------------------------------------

## His face for the beat: "smile", "shock", "proud" or "cry".
func kemal_face() -> String:
	if win == null:
		return "smile"
	match win.phase:
		Win.Phase.SLAP:
			return "shock"
		Win.Phase.FIVE:
			return "proud"
		Win.Phase.QUEUE:
			return "shock" if win.t < 0.5 else "proud"
		Win.Phase.CRY, Win.Phase.PARAGON:
			return "cry"
	return "smile"


func _draw_kemal() -> void:
	_use(_kemal_n)
	if win == null:
		return
	var face := kemal_face()
	var kx := _kemal_x()
	var bob := 1.0 if fmod(_t, 2.4) < 1.2 and face != "shock" else 0.0
	var top := 77.0 + bob
	_fig(kx, top, 1, KEMAL_S)
	# the jacket: shoulders, the double row of buttons, the rolled sleeves, the forearms on the counter
	_q(-17, 26, 34, 2, JACKET[0])
	_band(-21, 28, 42, 34, JACKET, 4, 1)
	_detail(true)
	for by: float in [33.0, 39.0, 45.0]:
		_q(-6, by, 1.5, 1.5, Kit.STEEL_D)
		_q(4.5, by, 1.5, 1.5, Kit.STEEL_D)
	_q(-5, 27, 10, 3, JACKET[1])
	_q(-2, 27, 4, 4, KEMAL_SKIN[1])
	_detail(false)
	for side: float in [-1.0, 1.0]:
		var ax := -28.0 if side < 0 else 21.0
		_band(ax, 30, 7, 14, JACKET, 2, 1)
		_q(ax - 0.5, 43, 8, 3, JACKET[1])
		_q(ax, 46, 7, 10, KEMAL_SKIN[0])
		_q(ax + (5.0 if side > 0 else 0.0), 46, 2, 10, KEMAL_SKIN[1])
		_q(ax - 1, 55, 9, 4, KEMAL_SKIN[0])
	_q(-3.5, 23, 7, 4, KEMAL_SKIN[1])
	# the head: big, round at the jaw; the ears
	_q(-13.5, 8, 2, 7, KEMAL_SKIN[0])
	_q(11.5, 8, 2, 7, KEMAL_SKIN[1])
	_q(-11, 0, 22, 1, KEMAL_SKIN[0])
	_q(-12, 1, 24, 19, KEMAL_SKIN[0])
	_q(-11, 20, 22, 2, KEMAL_SKIN[0])
	_q(-9, 22, 18, 2, KEMAL_SKIN[0])
	_detail(true)
	_q(8.5, 1, 3.5, 19, KEMAL_SKIN[1])
	_q(7, 20, 4, 2, KEMAL_SKIN[1])
	_q(-12, 2, 1, 15, KEMAL_SKIN[2])
	_detail(false)
	# black hair at the temples, the white cap with its red band, a pencil behind the ear
	_q(-12.5, 0, 2.5, 8, Kit.HAIR_BK)
	_q(10, 0, 2.5, 8, Kit.HAIR_BK)
	_q(-12, -9, 24, 9, JACKET[0])
	_q(-11, -10, 22, 1, JACKET[0])
	_detail(true)
	_q(-12, -4, 24, 3.5, Kit.CUP)
	_q(-12, -4, 24, 0.5, Kit.CUP_L)
	_q(8, -9, 4, 5, JACKET[1])
	_q(-11, -9, 6, 1, JACKET[2])
	_detail(false)
	_q(-15.5, 3, 1.5, 9, Kit.GOLD)
	_detail(true)
	_q(-15.5, 3, 1.5, 1.5, Color("#f08a9a"))
	_q(-15.5, 11, 1.5, 1, Kit.WOOD_D)
	_detail(false)
	_k_face(face)
	_flush(OUT)


## His face (local units at the figure's origin, the head's top).
func _k_face(face: String) -> void:
	var ct := win.t if win.phase == Win.Phase.CRY else (9.0 if win.phase == Win.Phase.PARAGON else 0.0)
	var brow := 6.0
	match face:
		"shock":
			brow = 4.0
	_detail(true)
	# the brows, thick: the face's loudest part; in tears their inner ends go up
	if face == "cry" and ct > 0.5:
		_q(-9, brow + 1, 4, 2, Kit.HAIR_BK)
		_q(-5, brow, 3, 2, Kit.HAIR_BK)
		_q(2, brow, 3, 2, Kit.HAIR_BK)
		_q(5, brow + 1, 4, 2, Kit.HAIR_BK)
	else:
		_q(-9, brow, 7, 2, Kit.HAIR_BK)
		_q(2, brow, 7, 2, Kit.HAIR_BK)
	var blink := fmod(_t, 3.3) < 0.12
	var look := 1.0
	for ex: float in [-8.0, 3.0]:
		match face:
			"shock":
				_q(ex, 8.5, 5, 5, WHITE)
				_q(ex + 1.5 + look * 0.5, 10, 2, 2, INK)
			"proud":
				_q(ex, 11, 5, 1, INK)
				_q(ex - 0.5, 10, 1, 1, INK)
				_q(ex + 4.5, 10, 1, 1, INK)
			"cry":
				if ct < 0.5:
					# the eyes filling: the water rising in them, a glint on top
					_q(ex, 9, 5, 4, WHITE)
					_q(ex + 1.5 + look * 0.5, 9.5, 2, 2.5, INK)
					var fill := clampf(ct / 0.4, 0.0, 1.0)
					var rows := roundf(fill * 3.0 * 2.0) / 2.0
					if rows > 0.0:
						_q(ex, 13 - rows, 5, rows, TEAR)
						_q(ex + 0.5, 13 - rows, 1.5, 0.5, WHITE)
				else:
					# squeezed shut, the tears running
					_q(ex, 11, 5, 1, INK)
					_q(ex - 0.5, 10.5, 1, 1, INK)
					_q(ex + 4.5, 10.5, 1, 1, INK)
					var tx := ex - 1.0 if ex < 0.0 else ex + 5.0
					var run := clampf((ct - 0.5) / 0.4, 0.0, 1.0)
					_q(tx, 11.5, 1.5, 2.0 + run * 7.0, TEAR)
					_q(tx + 0.5, 11.5, 0.5, 2.0 + run * 7.0, TEAR_D)
					var dt := fmod(ct * 1.3 + (0.0 if ex < 0.0 else 0.45), 1.0)
					_q(tx - 0.5, 20.0 + dt * 10.0, 2, 2, TEAR)
					_q(tx, 20.0 + dt * 10.0, 1, 0.5, WHITE)
			_:
				if blink:
					_q(ex, 11, 5, 1, INK)
				else:
					_q(ex, 9, 5, 4, WHITE)
					_q(ex + 2 + look * 0.5, 9.5, 2, 2.5, INK)
					_q(ex + 2.5 + look * 0.5, 9.5, 0.5, 0.5, WHITE)
	# the nose, the blush, the moustache, the mouth under it
	_q(-2, 10, 4, 6, KEMAL_SKIN[1])
	_q(-2, 10, 1, 4, KEMAL_SKIN[2])
	if face == "proud" or face == "cry":
		_q(-11, 14, 4, 1.5, Color(Kit.CUP_L, 0.7))
		_q(7, 14, 4, 1.5, Color(Kit.CUP_L, 0.7))
	_q(-8, 15.5, 16, 2.5, Kit.HAIR_BK)
	_q(-10, 17, 3, 2, Kit.HAIR_BK)
	_q(7, 17, 3, 2, Kit.HAIR_BK)
	_q(-6, 15, 4, 0.5, Color("#4a4a4a"))
	var mouth := "smile"
	match face:
		"shock":
			mouth = "o"
		"cry":
			mouth = "wobble"
	if win.phase == Win.Phase.CRY:
		var said := _talk_mouth(_pick(win.cry), win.t, "wobble")
		if said == "a" or said == "o":
			mouth = said
	match mouth:
		"o":
			_q(-1.5, 19, 3, 3, MOUTH)
		"a":
			_q(-3, 19, 6, 2.5, MOUTH)
			_q(-2, 21, 4, 0.5, TONGUE)
		"wobble":
			_q(-4, 19.5, 2, 1, MOUTH)
			_q(-2, 20, 2, 1, MOUTH)
			_q(0, 19.5, 2, 1, MOUTH)
			_q(2, 20, 2, 1, MOUTH)
		_:
			_q(-4, 19, 8, 1.5, MOUTH)
			_q(-3, 19, 6, 0.5, WHITE)
	_detail(false)


# --- the front (drawn once a size) ----------------------------------------------------------------

func _draw_front() -> void:
	_use(_front)
	var gx0 := _glass_x0()
	var gx1 := _glass_x1()
	# the counter: its steel top, the salad trays and the sneeze guard, the panel under it
	_u(gx0, 140, gx1 - gx0, 3, Kit.STEEL)
	_u(gx0, 140, gx1 - gx0, 0.5, Kit.CHROME)
	_u(gx0, 143, gx1 - gx0, 7, Kit.STEEL_D)
	for x in range(int(gx0) + 6, int(gx1) - 4, 12):
		_u(x, 144, 0.5, 5, Kit.STEEL)
	var trays: Array[Color] = [Kit.LETTUCE, Kit.TOMATO, Kit.ONION, Kit.CABBAGE, Kit.CUCUMBER, Kit.CABBAGE_R]
	var tx := roundf(W * 0.56) - 40.0
	for i in trays.size():
		_u(tx + i * 14, 137, 12, 3, Kit.STEEL_D)
		_u(tx + i * 14 + 1, 137, 10, 2, trays[i])
	_u(tx - 4, 126, trays.size() * 14 + 6, 0.5, Color(Kit.GLASS_C, 0.6))
	_u(tx - 4, 126, 0.5, 11, Color(Kit.GLASS_C, 0.4))
	_u(tx + trays.size() * 14 + 1.5, 126, 0.5, 11, Color(Kit.GLASS_C, 0.4))
	# the tip jar and the bottles at the counter's end
	_u(gx1 - 30, 132, 7, 8, Color(Kit.GLASS_C, 0.5))
	_u(gx1 - 29, 136, 5, 3, Kit.GOLD)
	for i in 3:
		_u(gx1 - 20 + i * 5, 130, 3, 10, [Kit.SAUCE_W, Kit.SAUCE_P, Kit.SAUCE_R][i])
		_u(gx1 - 19.5 + i * 5, 128.5, 2, 1.5, Kit.STEEL_D)
	# the glass: reflections in stepped streaks
	var gw := gx1 - gx0
	for s: Vector2 in [Vector2(0.12, 14.0), Vector2(0.46, 8.0), Vector2(0.80, 18.0)]:
		var sx := gx0 + gw * s.x
		var k := 0.0
		while k < 86.0:
			var x0 := sx + k * 0.5
			if x0 + s.y < gx1:
				_u(x0, 62 + k, s.y, 2, SHINE)
			k += 2.0
	# the window's frame and its mullion
	_u(gx0 - 3, 58, 3, 92, FRAME_C[0])
	_u(gx0 - 3, 58, 1, 92, FRAME_C[2])
	_u(gx1, 58, 3, 92, FRAME_C[0])
	_u(gx1 + 2, 58, 1, 92, FRAME_C[1])
	var mx := roundf(gx0 + gw * 0.36)
	_u(mx - 1, 62, 2, 88, FRAME_C[0])
	_u(mx - 1, 62, 0.5, 88, FRAME_C[2])
	# the sill and the cobalt riser under the window
	_u(gx0 - 3, 148, gx1 - gx0 + 6, 3, FRAME_C[2])
	_u(gx0 - 3, 150.5, gx1 - gx0 + 6, 1, FRAME_C[1])
	_u(0, 151.5, W, 23, Kit.COBALT)
	var ry := 157.0
	while ry < 174.0:
		_u(0, ry, W, 0.5, Kit.COBALT_D)
		ry += 6.0
	for x in range(0, int(W), 6):
		_u(x + (3 if int((x / 6)) % 2 == 0 else 0), 152, 0.5, 22, Kit.COBALT_D)
	_u(0, 151.5, W, 0.5, Kit.COBALT_L)
	# the door: its frame, the dark glass with the warm room in it, the push bar
	var dx := _door_x()
	_u(dx - 3, 58, 50, 117, FRAME_C[0])
	_u(dx - 3, 58, 1, 117, FRAME_C[2])
	_u(dx, 62, 44, 112, GLASS_IN)
	_u(dx, 62, 44, 112, WARM)
	_u(dx + 4, 66, 36, 20, Color(Kit.PANEL, 0.25))
	_u(dx + 2, 118, 40, 3, Kit.CHROME)
	_u(dx + 2, 120.5, 40, 0.5, Kit.STEEL_D)
	for k in 30:
		_u(dx + 6 + k * 0.5, 64 + k * 2.0, 4, 2, SHINE)
	# the opening's balloons by the door (GRAND OPENING), on their strings
	for b: Array in [[dx - 4.0, 44.0, Kit.CUP], [dx + 3.0, 38.0, Kit.GOLD], [dx + 10.0, 46.0, Kit.CUP],
			[dx + 40.0, 46.0, Kit.GOLD], [dx + 47.0, 39.0, Kit.CUP], [dx + 53.0, 45.0, Kit.GOLD]]:
		var bx: float = b[0]
		var by: float = b[1]
		var bc: Color = b[2]
		_u(bx - 0.25, by + 5, 0.5, 66.0 - by, Color("#d8d0c0"))
		_disc(bx, by, 5.5, 6.5, OUT)
		_disc(bx, by, 5, 6, bc)
		_u(bx - 3, by - 3.5, 2, 2, bc.lightened(0.45))
		_u(bx - 1, by + 6, 2, 1, bc.darkened(0.25))
	# the pavement: slabs, their joints closer far away
	_u(0, 174.5, W, 41.5, PAVE)
	_u(0, 174.5, W, 1, PAVE_D)
	var rows: Array[float] = [174.5, 182.0, 193.0, 208.0]
	for r in rows.size():
		var y0 := rows[r]
		var y1 := rows[r + 1] if r + 1 < rows.size() else 216.0
		_u(0, y0, W, 0.5, PAVE_D)
		_u(0, y0 + 0.5, W, 0.5, PAVE_L)
		var step := 18.0 + r * 10.0
		var x := fmod(float(r) * 9.0, step)
		while x < W:
			_u(x, y0, 0.5, y1 - y0, PAVE_D)
			x += step


# --- the street: the sticker, the queue, the hands ------------------------------------------------

func _draw_street() -> void:
	_use(_street)
	if win == null:
		return
	var ph := win.phase
	var at := sticker_at()
	var st := win.t
	# the sticker on the glass from the slap on (two squash frames, then it settles)
	if win.stuck():
		var rx := R_GLASS
		var ry := R_GLASS
		if ph == Win.Phase.SLAP and not Access.calm:
			if st < 0.06:
				rx = 0.0
			elif st < 0.14:
				rx = R_GLASS * 1.3
				ry = R_GLASS * 0.72
			elif st < 0.22:
				rx = R_GLASS * 0.9
				ry = R_GLASS * 1.12
		if rx > 0.0:
			_k_sticker(at.x, at.y, rx, ry)
	# the queue: the ones in line, then the ones still walking (a step nearer)
	if ph >= Win.Phase.QUEUE:
		var walking: Array = []
		for i in Win.QUEUE_N:
			var w := win.walked(i)
			if w < 0.0:
				continue
			var p := _walker(i, w)
			if bool(p["walking"]):
				walking.append(p)
			else:
				_queuer(i, p)
		for p: Dictionary in walking:
			_queuer(int(p["i"]), p)
	# the hands
	match ph:
		Win.Phase.IN, Win.Phase.READY:
			_k_hold_pose()
		Win.Phase.SLAP:
			_k_slap_pose(st)
		Win.Phase.FIVE:
			_k_five_pose(st)
	# PLASK! over the sticker, PIONA! at the high five
	if (ph == Win.Phase.SLAP and st >= 0.06) or (ph == Win.Phase.FIVE and st < 0.2) or (ph == Win.Phase.QUEUE and st < 0.4):
		var k := 1.0 if Access.calm or ph != Win.Phase.SLAP or st > 0.14 else 1.25
		var pa := plask_at()
		_k_burst(pa.x, pa.y, 30.0 * k, WHITE)
		_k_shout(_w("plask"), pa.x, pa.y, 3.0 * k, Kit.CUP)
	if ph == Win.Phase.FIVE and st >= 0.22:
		var five := _five_at()
		var k2 := 1.25 if st < 0.3 and not Access.calm else 1.0
		_k_burst(five.x - 6.0, five.y - 40.0, 19.0 * k2, GOLD)
		_k_shout(_w("piona"), five.x - 6.0, five.y - 40.0, 2.0 * k2, Kit.CUP)


## Where walker `i` is `w` s after setting off: {"i", "x", "f", "walking", "step"}.
func _walker(i: int, w: float) -> Dictionary:
	var goal := _slot_x(i)
	var from_right := i % 2 == 0
	var start := W + 24.0 if from_right else -24.0
	var d := absf(goal - start)
	var gone := w * WALK_PACE
	var x := goal
	var walking := gone < d
	if walking:
		x = start + (gone if not from_right else -gone)
	return {"i": i, "x": roundf(x), "f": -1 if from_right or not walking else 1, "walking": walking, "step": int(w * 7.0) % 2}


## One of the queue (Fable 4a's street crowd), from its CROWD spec.
func _queuer(i: int, p: Dictionary) -> void:
	var c: Dictionary = (CROWD[i % CROWD.size()] as Dictionary).duplicate()
	var walking := bool(p["walking"])
	c["x"] = float(p["x"])
	c["f"] = int(p["f"])
	c["feet"] = WALK_FEET if walking else QUEUE_FEET
	c["s"] = QUEUE_S
	c["seed"] = float(i) * 0.7
	if walking:
		c["walk"] = int(p["step"])
	var face := {"look": 1, "mouth": "smile"}
	if not walking and win.phase >= Win.Phase.CRY and i % 3 == 1:
		face["eyes"] = "happy"
		face["mouth"] = "grin"
	elif not walking and i % 4 == 2:
		face["look"] = -1
	if bool(c.get("glasses", false)):
		face["glasses"] = true
	if bool(c.get("tache", false)):
		face["tache"] = true
	c["face"] = face
	if not c.has("front"):
		c["front"] = "down"
	_person(c)


# --- the hands ------------------------------------------------------------------------------------

## READY: the winner's hand holding the sticker up (the player's from the bottom right; Kebabulo's
## beige sleeve from the right edge when he won the race), a 1-unit bob.
func _k_hold_pose() -> void:
	var bob := 1.0 if fmod(_t, 1.0) < 0.5 else 0.0
	if win.won:
		var c := Vector2(W - 70.0, 150.0 + bob)
		_k_hand(c + Vector2(0, R_HAND + 4.0), 1.0, Vector2(0.3, 1.0), TEAL, "hold")
		_k_sticker(c.x, c.y, R_HAND, R_HAND)
		_k_thumb(c + Vector2(-8.0, R_HAND - 3.0), 1.0, TEAL)
	else:
		var c2 := Vector2(W - 78.0, 112.0 + bob)
		_k_hand(c2 + Vector2(R_HAND + 4.0, 0), 1.0, Vector2(1.0, 0.25), HOODIE, "hold", true)
		_k_sticker(c2.x, c2.y, R_HAND, R_HAND)
		_k_thumb(c2 + Vector2(R_HAND - 3.0, 8.0), 1.0, HOODIE, true)


## SLAP: one in-between frame, the hand flat on the sticker, then pulled back down out of frame.
func _k_slap_pose(st: float) -> void:
	var at := sticker_at()
	var sleeve: Array = TEAL if win.won else HOODIE
	var side := not win.won
	var dir := Vector2(0.3, 1.0) if win.won else Vector2(1.0, 0.25)
	var held := Vector2(W - 70.0, 150.0 + R_HAND + 4.0) if win.won else Vector2(W - 78.0 + R_HAND + 4.0, 112.0)
	var press := at + (Vector2(0, 6.0) if win.won else Vector2(6.0, 2.0))
	if st < 0.06:
		_k_hand(held.lerp(press, 0.5), 0.85, dir, sleeve, "press", side)
	elif st < 0.22:
		_k_hand(press, 0.75, dir, sleeve, "press", side)
	elif st < 0.36:
		_k_hand(press + dir.normalized() * 40.0, 0.8, dir, sleeve, "press", side)


## The high five (Kebabulo won): his open hand from the right edge, the player's from below, meeting.
func _k_five_pose(st: float) -> void:
	var five := _five_at()
	var k := clampf(st / 0.22, 0.0, 1.0)
	if Access.calm:
		k = 1.0
	k = roundf(k * 3.0) / 3.0
	var his := Vector2(W + 10.0, five.y - 2.0).lerp(five + Vector2(14.0, -2.0), k)
	var yours := Vector2(five.x - 40.0, 236.0).lerp(five + Vector2(-14.0, 4.0), k)
	_k_hand(his, 0.9, Vector2(1.0, 0.25), HOODIE, "open", true)
	_k_hand(yours, 0.9, Vector2(0.3, 1.0), TEAL, "open")


## Where PLASK! stands: above and left of the sticker, inside the window.
func plask_at() -> Vector2:
	var at := sticker_at()
	return Vector2(at.x - 32.0, at.y - 30.0)


func _five_at() -> Vector2:
	return Vector2(roundf(W * 0.76), 164.0)


## A hand in the frame: `c` the palm's centre (units), `k` units a hand px, `from` the way to the
## edge the arm comes from (the sleeve steps that way off screen), `pose` "hold" (fingers behind
## the sticker), "press" (flat) or "open" (spread, the high five); `left` turns it a quarter so the
## fingers point left (an arm from the right edge).
func _k_hand(c: Vector2, k: float, from: Vector2, sleeve: Array, pose: String, left := false) -> void:
	_fig(c.x, c.y, 1, 2.0 * k)
	var skin: Array = SKIN_MID if sleeve == TEAL else SKIN_LIGHT
	var R := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		if left:
			_q(y, -x - w, h, w, col)
		else:
			_q(x, y, w, h, col)
	# the sleeve: stepped blocks from the wrist off the screen's edge, its cuff
	var dl := from.normalized()
	for i in range(1, 22):
		var o := dl * float(i) * 7.0
		if left:
			_q(10.0 + o.x, -12.0 + o.y, 12, 24, sleeve[0])
			_q(10.0 + o.x, 8.0 + o.y, 12, 4, sleeve[1])
		else:
			_q(-12.0 + o.x, 10.0 + o.y, 24, 12, sleeve[0])
			_q(8.0 + o.x, 10.0 + o.y, 4, 12, sleeve[1])
	R.call(-13, 10, 26, 5, sleeve[2])
	R.call(-13, 14, 26, 1, sleeve[1])
	# the palm, its shade and light, the knuckles
	R.call(-11, -5, 22, 16, skin[0])
	_detail(true)
	R.call(7, -5, 4, 16, skin[1])
	R.call(-11, -5, 1.5, 16, skin[2])
	_detail(false)
	match pose:
		"hold":
			for f in 4:
				R.call(-11 + f * 5.5, -11 + absf(1.5 - f) * 1.0, 5, 7, skin[0])
			_detail(true)
			for f in 3:
				R.call(-6 + f * 5.5, -10, 0.5, 5, skin[1])
			_detail(false)
		"press":
			var tops := [-20.0, -23.0, -22.0, -18.0]
			for f in 4:
				R.call(-11 + f * 5.5, tops[f], 5, -5.0 - tops[f] + 1.0, skin[0])
			_detail(true)
			for f in 4:
				R.call(-11 + f * 5.5, tops[f], 5, 1, skin[2])
				R.call(-11 + f * 5.5 + 1.0, tops[f] + 1.0, 3, 2, Color("#f4e0d0"))
			_detail(false)
			R.call(-18, -1, 8, 6, skin[0])
		"open":
			var tops2 := [-21.0, -25.0, -24.0, -19.0]
			for f in 4:
				R.call(-14 + f * 7.0, tops2[f], 5, -5.0 - tops2[f] + 1.0, skin[0])
			_detail(true)
			for f in 4:
				R.call(-14 + f * 7.0, tops2[f], 5, 1, skin[2])
			_detail(false)
			R.call(-21, 0, 10, 5, skin[0])
	_flush(OUT, 2.0)


## The thumb over the sticker's lower edge (the hand holds it).
func _k_thumb(c: Vector2, k: float, sleeve: Array, left := false) -> void:
	var skin: Array = SKIN_MID if sleeve == TEAL else SKIN_LIGHT
	_fig(c.x, c.y, 1, 2.0 * k)
	if left:
		_q(-3, -4, 8, 7, skin[0])
		_q(-3, -4, 3, 7, skin[2])
		_q(-3, -3, 2, 5, Color("#f4e0d0"))
	else:
		_q(-4, -3, 7, 8, skin[0])
		_q(-4, -3, 7, 2, skin[2])
		_q(-3, -3, 5, 2, Color("#f4e0d0"))
	_flush(OUT, 2.0)


# --- the sticker, the bursts, the words -------------------------------------------------------------

## The round MLASK sticker (a miniature of the MLASK panel): the ink edge, a white die-cut ring, gold
## with amber rays, the red word with its ink copy and a lighter top row. `rx`, `ry` its radii.
func _k_sticker(cx: float, cy: float, rx: float, ry: float) -> void:
	_disc(cx + 1, cy + 1.5, rx + 1, ry + 1, Color(0, 0, 0, 0.25))
	_disc(cx, cy, rx + 1, ry + 1, OUT)
	_disc(cx, cy, rx, ry, WHITE)
	var gx := rx - 2.0
	var gy := ry - 2.0
	_disc(cx, cy, gx, gy, GOLD)
	# the rays: twelve wedges from the centre, alternate ones amber, in half-unit rows
	var n := int(ceil(gy * PX))
	for row in range(-n, n):
		var yy := (float(row) + 0.5) / PX
		var tt := yy / gy
		if absf(tt) >= 1.0:
			continue
		var hw := roundf(gx * sqrt(1.0 - tt * tt) * PX) / PX
		var cuts := PackedFloat32Array([cx - hw, cx + hw])
		for kk in 12:
			var a := (float(kk) + 0.5) * TAU / 12.0
			var sa := sin(a)
			if absf(sa) < 0.001 or signf(sa) != signf(yy):
				continue
			var xi := cx + yy * cos(a) / sa * (gx / gy)
			if xi > cx - hw and xi < cx + hw:
				cuts.append(roundf(xi * PX) / PX)
		cuts.sort()
		for j in cuts.size() - 1:
			var a0 := cuts[j]
			var a1 := cuts[j + 1]
			if a1 - a0 < 0.5:
				continue
			var mid := (a0 + a1) * 0.5
			var ang := atan2(yy * (gx / gy), mid - cx)
			var wedge := int(floor(fposmod(ang, TAU) / (TAU / 12.0)))
			if wedge % 2 == 1:
				_u(a0, cy + float(row) / PX, a1 - a0, 1.0 / PX, AMBER)
	# the word
	var word := _w("sticker_word").to_upper()
	var fw := float(PixelFont.width(word))
	var sc := clampf(roundf(minf(rx * 1.5, ry * 2.6) / fw * 2.0) / 2.0, 0.5, 2.0)
	var x := roundf((cx - fw * sc * 0.5) * PX) / PX
	var y := roundf((cy - 3.5 * sc) * PX) / PX
	_k_word(word, x + sc * 0.5 + 0.5, y + sc * 0.5 + 0.5, sc, INK)
	_k_word(word, x, y, sc, RED)
	_k_word(word, x, y, sc, RED_L, true)


## A comic burst behind a shout: an octagon of rows and four long spikes, ink-edged.
func _k_burst(cx: float, cy: float, r: float, c: Color) -> void:
	for pass_i in 2:
		var e := 1.0 if pass_i == 0 else 0.0
		var col := INK if pass_i == 0 else c
		_u(cx - r * 2.3 - e, cy - 2 - e, r * 4.6 + e * 2.0, 4 + e * 2.0, col)
		_u(cx - 3 - e, cy - r * 1.0 - e, 6 + e * 2.0, r * 2.0 + e * 2.0, col)
		var rows := int(r * 0.6)
		var k := -rows
		while k <= rows:
			var hw := r * (2.0 - 0.7 * absf(float(k)) / float(rows))
			_u(cx - hw - e, cy + k - e, hw * 2.0 + e * 2.0, 2 + e * 2.0, col)
			k += 2


## A shout in the 5x7 font at `sc` units a font px, centred on (cx, cy), with its ink copy.
func _k_shout(text: String, cx: float, cy: float, sc: float, c: Color) -> void:
	var t := text.to_upper()
	var w := float(PixelFont.width(t)) * sc
	var x := roundf(cx - w * 0.5)
	var y := roundf(cy - 3.5 * sc)
	_k_word(t, x + sc * 0.5, y + sc * 0.5, sc, INK)
	_k_word(t, x, y, sc, c)


## The 5x7 font with this pen (its letter's top at y), `sc` units a font px, each row's runs merged;
## `top_only` draws only each letter's top row (the lighter rim).
func _k_word(s: String, x: float, y: float, sc: float, c: Color, top_only := false) -> void:
	var cx := x
	for ch in s:
		var cw := PixelFont.char_width(ch)
		if cw == 0:
			continue
		var g: Array[Vector2i] = Kit.glyph(ch)
		var top_row := 99
		for p: Vector2i in g:
			top_row = mini(top_row, p.y)
		var i := 0
		while i < g.size():
			var p: Vector2i = g[i]
			var j := i
			while j + 1 < g.size() and g[j + 1].y == p.y and g[j + 1].x == g[j].x + 1:
				j += 1
			if not top_only or p.y == top_row:
				_u(cx + p.x * sc, y + (p.y - PixelFont.BODY) * sc, (j - i + 1) * sc, sc if not top_only else minf(sc, 1.0), c)
			i = j + 1
		cx += (cw + PixelFont.GAP) * sc


# --- the street crowd's looks (palm_tasting_ui.gd `_person` calls these) --------------------------

## The heads' extras: the crowd's hats and hair, glasses, a moustache.
func _head(cx: float, hy: float, hh: float, skin: Array, hair: String, hair_c: Color, fc: Dictionary, beard := false) -> void:
	super(cx, hy, hh, skin, hair, hair_c, fc, beard)
	var hw := 28.0
	var l := cx - hw * 0.5
	match hair:
		"beanie_grey":
			_q(l - 3, hy + 4, 4, 10, hair_c)
			_q(l - 2, hy - 7, hw + 4, 11, Color("#8a8f9a"))
			_q(l - 2, hy + 1, hw + 4, 3, Color("#6e7380"))
			_detail(true)
			for rx in range(int(l), int(l + hw + 2), 3):
				_q(rx, hy - 6, 1, 7, Color("#6e7380"))
			_detail(false)
		"curls":
			for c: Vector2 in [Vector2(-2, -6), Vector2(4, -8), Vector2(10, -8), Vector2(16, -7), Vector2(22, -5), Vector2(-4, 0), Vector2(25, 1), Vector2(-4, 6)]:
				_q(l + c.x, hy + c.y, 7, 7, hair_c)
			_detail(true)
			for c: Vector2 in [Vector2(0, -5), Vector2(7, -7), Vector2(14, -6), Vector2(21, -4)]:
				_q(l + c.x, hy + c.y, 2, 1, hair_c.lightened(0.3))
			_detail(false)
		"bun":
			_q(l - 1, hy - 4, hw + 2, 7, hair_c)
			_q(l - 3, hy, 4, 12, hair_c)
			_q(cx - 5, hy - 12, 10, 8, hair_c)
			_detail(true)
			_q(cx - 3, hy - 11, 4, 1, hair_c.lightened(0.3))
			_q(l + 2, hy - 3, 10, 1, hair_c.lightened(0.25))
			_detail(false)
		"bucket":
			_q(l - 1, hy + 2, 4, 6, Color("#6a4a30"))
			_q(l + 1, hy - 9, hw - 2, 9, hair_c)
			_q(l - 5, hy - 1, hw + 10, 3, hair_c)
			_detail(true)
			_q(l + 1, hy - 3, hw - 2, 1, hair_c.darkened(0.25))
			_q(l - 5, hy + 1, hw + 10, 1, hair_c.darkened(0.2))
			_detail(false)
		"beret":
			_q(l - 2, hy + 1, 4, 10, hair_c)
			_q(l + hw - 2, hy + 1, 4, 8, hair_c)
			_q(l - 3, hy - 7, hw + 8, 7, Color("#b5532a"))
			_q(l + 1, hy - 9, hw - 2, 2, Color("#b5532a"))
			_q(cx + 1, hy - 11, 2, 2, Color("#8a3a1e"))
			_detail(true)
			_q(l - 3, hy - 2, hw + 8, 1, Color("#8a3a1e"))
			_q(l + 2, hy - 7, 10, 1, Color("#d0744a"))
			_detail(false)
		"cyclecap":
			_q(l - 1, hy + 1, 4, 8, hair_c)
			_q(l, hy - 6, hw, 7, Color("#8ad8c0"))
			_q(l + hw - 6, hy - 9, 10, 4, Color("#8ad8c0"))
			_detail(true)
			_q(l, hy - 3, hw, 1, Color("#5ab8a0"))
			_q(cx - 1, hy - 6, 2, 7, WHITE)
			_q(l + hw - 6, hy - 9, 10, 1, Color("#b0f0e0"))
			_detail(false)
	_detail(true)
	if bool(fc.get("glasses", false)):
		for ex: float in [cx - 6.0, cx + 6.0]:
			_q(ex - 2, hy + 11, 7, 1, Color("#c9a24a"))
			_q(ex - 2, hy + 17, 7, 1, Color("#c9a24a"))
			_q(ex - 2, hy + 11, 1, 7, Color("#c9a24a"))
			_q(ex + 4, hy + 11, 1, 7, Color("#c9a24a"))
			_q(ex - 1, hy + 12, 1, 1, WHITE)
		_q(cx + 0, hy + 13, 2, 1, Color("#c9a24a"))
	if bool(fc.get("tache", false)):
		_q(cx - 4, hy + 20, 9, 1.5, hair_c)
	_detail(false)


## The torsos' marks: the trench's belt, the denim's cream collar, the dungarees over the stripes,
## the puffer's quilting, the Mordor vest and lanyard, Halina's coat buttons, the courier's yellow
## strap, the corduroy's cords.
func _torso_extra(kind: String, ys: float, yh: float, tw: float, top: Array) -> void:
	var l := -tw * 0.5
	match kind:
		"latte":
			_detail(true)
			_q(l, ys + 30, tw, 3, top[1])
			_q(-2, ys + 29, 4, 5, Color("#6a4a30"))
			_q(-1, ys, 1, yh - ys - 4, top[1])
			_q(-7, ys, 6, 6, top[2])
			_detail(false)
		"vinyl":
			_q(-9, ys - 3, 18, 6, Color("#e8e0cc"))
			_detail(true)
			_q(-9, ys + 2, 18, 1, Color("#c9c0aa"))
			_q(l + 3, ys + 12, 7, 5, top[1])
			_q(tw * 0.5 - 10, ys + 12, 7, 5, top[1])
			_q(-0.5, ys + 3, 1, yh - ys - 7, Color("#c9a24a"))
			_detail(false)
		"plant":
			_detail(true)
			var y := ys + 1.0
			while y < ys + 14.0:
				_q(l, y, tw, 2, Color("#2a3550"))
				_q(l, y + 2, tw, 2, Color("#e8e0cc"))
				y += 4.0
			_q(-8, ys + 6, 16, 9, top[0])
			_q(-8, ys + 6, 16, 1, top[2])
			_q(-7, ys + 1, 2, 6, top[0])
			_q(5, ys + 1, 2, 6, top[0])
			_q(-3, ys + 9, 6, 4, top[1])
			_detail(false)
		"dog":
			_detail(true)
			var qy := ys + 8.0
			while qy < yh - 2.0:
				_q(l, qy, tw, 1, top[1])
				_qs(l, qy - 1.0, tw * 0.5, 1, top[2])
				qy += 8.0
			_q(-6, ys - 3, 12, 5, top[2])
			_detail(false)
		"mordor":
			_band(l, ys + 1, tw, yh - ys - 9, [Color("#2a3550"), Color("#1c2438"), Color("#3c4868")], 3, 1)
			_detail(true)
			var qy2 := ys + 7.0
			while qy2 < yh - 10.0:
				_q(l, qy2, tw, 1, Color("#1c2438"))
				qy2 += 6.0
			_q(-4, ys, 8, 4, top[0])
			_q(-4, ys + 1, 1, 18, RED)
			_q(3, ys + 1, 1, 18, RED)
			_q(-3, ys + 19, 6, 7, WHITE)
			_q(-2, ys + 21, 4, 2, Color("#4f7fd8"))
			_detail(false)
		"halina":
			_detail(true)
			for by: float in [ys + 8.0, ys + 18.0, ys + 28.0]:
				_q(-1, by, 2, 2, Color("#c9a24a"))
			_q(-7, ys - 2, 14, 4, Color("#b5532a"))
			_detail(false)
		"courier":
			_detail(true)
			for k in 12:
				_q(l + float(k) * 2.4, ys + 2.0 + float(k) * 3.0, 4, 3, Color("#f2c230"))
			_detail(false)
		"analog":
			_detail(true)
			for cx in range(int(l) + 2, int(tw * 0.5), 3):
				_q(cx, ys + 4, 1, yh - ys - 8, top[1])
			_q(-8, ys - 2, 16, 4, top[2])
			_detail(false)


## What a hand holds: the crowd's props (a cup, a laptop sleeve, a record bag, a monstera, a
## dachshund on its lead, a scooter helmet, a checked trolley, a tote with a tulip); the rest as the
## tasting's.
func _hold(what: String, hx: float, hy: float) -> void:
	match what:
		"cup":
			_q(hx - 3, hy - 9, 6, 9, Color("#e8e0cc"))
			_detail(true)
			_q(hx - 3, hy - 6, 6, 3, Color("#c89a5a"))
			_q(hx - 3, hy - 10, 6, 1, WHITE)
			_detail(false)
		"laptop":
			_q(hx - 2, hy - 6, 4, 22, Color("#6e7380"))
			_detail(true)
			_q(hx - 2, hy - 6, 1, 22, Color("#8a8f9a"))
			_detail(false)
		"records":
			_q(hx - 1, hy - 2, 2, 5, Color("#4a3220"))
			_band(hx - 9, hy + 2, 18, 18, [Color("#c8963a"), Color("#a0742a"), Color("#e0b460")], 3, 1)
			_detail(true)
			_q(hx - 7, hy, 14, 3, INK)
			_q(hx - 1, hy + 1, 2, 1, Color("#d4282e"))
			_detail(false)
		"monstera":
			_q(hx - 6, hy - 2, 12, 10, Color("#b5532a"))
			_detail(true)
			_q(hx - 6, hy - 2, 12, 2, Color("#d0744a"))
			_detail(false)
			for lf: Vector2 in [Vector2(-12, -14), Vector2(-2, -20), Vector2(4, -12), Vector2(-8, -8)]:
				_q(hx + lf.x, hy + lf.y, 10, 8, Color("#3f9a4a"))
			_detail(true)
			for lf: Vector2 in [Vector2(-10, -12), Vector2(0, -18), Vector2(6, -10)]:
				_q(hx + lf.x + 3, hy + lf.y, 1, 6, Color("#6cc04a"))
				_q(hx + lf.x, hy + lf.y + 3, 3, 1, Color("#2c7238"))
			_detail(false)
		"lead":
			var dog := Vector2(hx + 22.0, -12.0)
			var k := 0.0
			while k < 1.0:
				_q(lerpf(hx, dog.x - 4.0, k), lerpf(hy, dog.y - 6.0, k), 1, 2, Color("#b5532a"))
				k += 0.08
			var leg := 1.0 if fmod(_t, 0.4) < 0.2 else 0.0
			_q(dog.x - 6, dog.y - 6, 26, 9, Color("#8a4a24"))
			_q(dog.x - 10, dog.y - 9, 8, 7, Color("#8a4a24"))
			_q(dog.x - 13, dog.y - 6, 4, 3, Color("#6e3a1c"))
			_q(dog.x + 20, dog.y - 6, 5, 2, Color("#8a4a24"))
			for lx: float in [-4.0, 0.0, 12.0, 16.0]:
				_q(dog.x + lx, dog.y + 3, 2, 6 - leg * (1.0 if int(lx) % 8 == 0 else 0.0), Color("#6e3a1c"))
			_detail(true)
			_q(dog.x - 8, dog.y - 8, 1, 1, INK)
			_q(dog.x - 4, dog.y - 9, 3, 5, Color("#6e3a1c"))
			_q(dog.x - 6, dog.y - 6, 26, 2, Color("#a65a2a"))
			_detail(false)
		"helmet":
			_q(hx - 1, hy - 1, 2, 4, INK)
			_q(hx - 8, hy + 3, 16, 12, WHITE)
			_q(hx - 7, hy + 2, 14, 1, WHITE)
			_detail(true)
			_q(hx - 8, hy + 10, 16, 4, Color("#3a4a6a"))
			_q(hx - 6, hy + 4, 5, 2, Color("#e8f0ff"))
			_detail(false)
		"trolley":
			_q(hx - 1, hy, 2, 14, Color("#3a3e46"))
			_q(hx - 8, hy + 14, 16, 34, Color("#c8302a"))
			_detail(true)
			for ty in 6:
				for tx in 3:
					if (tx + ty) % 2 == 0:
						_q(hx - 8 + tx * 5.5, hy + 14 + ty * 5.5, 5, 5, Color("#e8e0cc"))
			_detail(false)
			_q(hx - 6, hy + 47, 5, 5, INK)
			_q(hx + 2, hy + 47, 5, 5, INK)
		"tote":
			_q(hx - 1, hy - 4, 2, 6, Color("#c9c0aa"))
			_q(hx - 8, hy + 2, 16, 18, Color("#e8e0cc"))
			_detail(true)
			_q(hx - 8, hy + 2, 16, 1, Color("#f6f0e0"))
			_q(hx - 1, hy + 10, 1, 6, Color("#3f9a4a"))
			_q(hx - 3, hy + 7, 5, 4, Color("#d4282e"))
			_q(hx - 2, hy + 6, 1, 1, Color("#d4282e"))
			_q(hx + 1, hy + 6, 1, 1, Color("#d4282e"))
			_detail(false)
		_:
			super(what, hx, hy)


# --- the words layer (216 rows, the kit's pen) ------------------------------------------------------

func _draw_words() -> void:
	if win == null:
		return
	var p := _ui_pen
	var safe := _safe_canvas()
	var left := maxf(6.0, safe.x + 4.0)
	var right := W - maxf(6.0, safe.y + 4.0)
	var ph := win.phase
	if ph == Win.Phase.READY:
		_say(p, left, _w("name_kebabulo"), _pick(win.line), Kit.AMBER, left + 10.0)
		if win.t > Win.TAP_S and fmod(_t, 1.0) < 0.8:
			var hint := _w("tap_slap" if win.won else "tap_five")
			var hx := (W - 70.0) if win.won else (W - 78.0)
			var hy := (150.0 - R_HAND - 15.0) if win.won else (112.0 - R_HAND - 15.0)
			hx = minf(hx, right - Kit.text_w(hint) * 0.5 - 2.0)
			p.rect(hx - Kit.text_w(hint) * 0.5 - 4, hy - 1, Kit.text_w(hint) + 8, 11, Color(Kit.INK, 0.86))
			p.text(hint, hx, hy, Kit.GOLD, 1, true)
	if ph == Win.Phase.CRY:
		_say(p, left, _w("name_kemal"), _pick(win.cry), Kit.THEM, _kemal_x() - 14.0)
	if ph < Win.Phase.PARAGON:
		var label := _w("skip")
		var sw := Kit.text_w(label) + 10.0
		var sx := right - sw - 2
		p.chip(sx, 6, label, Kit.LINE, "", sw)
		if win.skip_t > 0.0:
			p.rect(sx, 18, sw * clampf(win.skip_t / Win.SKIP_S, 0.0, 1.0), 2, Kit.GOLD)
		_skip_rect = _grow(Rect2(sx, 6, sw, 13))
	else:
		_skip_rect = Rect2()
	if ph >= Win.Phase.PARAGON:
		_receipt(p)
	if _wipe > 0.0:
		_draw_wipe(p)


## The bubble's width.
func bubble_w() -> float:
	return minf(roundf(W * 0.44), 200.0)


## A line in a bubble over the glass's left part (the door and the spit), its tail toward the
## speaker (`tail_x`).
func _say(p: Kit, left: float, name: String, text: String, nc: Color, tail_x: float) -> void:
	if text == "":
		return
	var bw := bubble_w()
	var lines := Kit.wrap(text, int(bw) - 10)
	var bx := left + 2.0
	var h := 6.0 + lines.size() * 10.0
	var by := bubble_bottom() - h
	p.bubble(bx, by, bw, name, lines, clampf(tail_x, bx + 8.0, bx + bw - 8.0), nc, true)


## The row a bubble's bottom stands on (units: over the counter, under Kemal's chin).
static func bubble_bottom() -> float:
	return 112.0


## PARAGON: the receipt rising from the bottom over the dimmed shop: the title, the shop and its
## street, the order, the grade, the pay and the respect, the badges and the leak line, the note, a
## barcode, DALEJ after CARD_S. Its rows are `receipt_rows()`'s.
func _receipt(p: Kit) -> void:
	var rows := receipt_rows(win, W)
	var h := receipt_h(rows)
	var rw := RECEIPT_W
	var x := roundf(W * 0.5 - rw * 0.5)
	var rise := 1.0 if Access.calm else clampf(win.t / 0.3, 0.0, 1.0)
	rise = roundf(rise * 6.0) / 6.0
	var y := roundf(lerpf(H + 4.0, (H - h) * 0.5, rise))
	p.rect(0, 0, W, H, Color(Kit.VOID, 0.5 * rise))
	p.rect(x + 3, y + 3, rw, h, Color(Kit.VOID, 0.5))
	p.rect(x, y, rw, h, PAPER_R)
	p.rect(x + rw - 3, y, 3, h, PAPER_RD)
	# the torn top edge
	for k in int(rw / 4.0):
		p.rect(x + k * 4.0, y - 1.0, 2, 1, PAPER_R)
	var cy := y + 5.0
	for r: Array in rows:
		var kind: String = r[0]
		match kind:
			"title":
				p.text(str(r[1]), x + rw * 0.5, cy - 2, RECEIPT_INK, 2, true)
				cy += 16.0
			"centre":
				p.text(str(r[1]), x + rw * 0.5, cy, RECEIPT_INK, 1, true)
				cy += 9.0
			"sep":
				var dx := x + 6.0
				while dx < x + rw - 8.0:
					p.rect(dx, cy + 2, 3, 1, PAPER_RD.darkened(0.2))
					dx += 5.0
				cy += 5.0
			"pair":
				p.text(str(r[1]), x + 7, cy, RECEIPT_INK)
				var v := str(r[2])
				p.text(v, x + rw - 8 - Kit.text_w(v), cy, RECEIPT_INK)
				cy += 9.0
			"line":
				p.text(str(r[1]), x + 7, cy, RECEIPT_INK)
				cy += 9.0
			"badge":
				var bt := str(r[1])
				var bw := Kit.text_w(bt) + 16.0
				p.rect(x + 7, cy, bw, 10, Kit.GOLD)
				_star(p, x + 9, cy + 2)
				p.text(bt, x + 19, cy, RECEIPT_INK)
				cy += 11.0
			"leak":
				p.text(str(r[1]), x + 7, cy, RECEIPT_RED)
				cy += 9.0
			"barcode":
				cy += 2.0
				var bx := x + 22.0
				var i := 0
				while bx < x + rw - 24.0:
					var bw2 := 1.0 + float((i * 7 + 3) % 3)
					p.rect(bx, cy, bw2, 7, RECEIPT_INK)
					bx += bw2 + 1.0 + float((i * 5) % 2)
					i += 1
				cy += 10.0
	if win.t >= Win.CARD_S:
		var bw3 := 96.0
		p.button(x + rw * 0.5 - bw3 * 0.5, cy, bw3, _w("btn_next"), true, 18.0)
	else:
		var bar := rw - 40.0
		p.rect(x + 20, cy + 8, bar, 2, PAPER_RD)
		p.rect(x + 20, cy + 8, bar * clampf(win.t / Win.CARD_S, 0.0, 1.0), 2, Kit.GOLD)
	# the torn bottom edge
	for k in int(rw / 4.0):
		p.rect(x + k * 4.0 + 2.0, y + h, 2, 1, PAPER_R)


## A tiny 7x6 star (the kit's font has none).
func _star(p: Kit, x: float, y: float) -> void:
	p.rect(x + 3, y, 1, 2, RECEIPT_INK)
	p.rect(x, y + 2, 7, 1, RECEIPT_INK)
	p.rect(x + 1, y + 3, 5, 1, RECEIPT_INK)
	p.rect(x + 2, y + 4, 3, 1, RECEIPT_INK)
	p.rect(x + 1, y + 5, 2, 1, RECEIPT_INK)
	p.rect(x + 4, y + 5, 2, 1, RECEIPT_INK)


## The receipt's rows for `w` (pure, so the check can lay out every case): [kind, text(, value)].
static func receipt_rows(w: Win, _width: float) -> Array:
	var inner := int(RECEIPT_W) - 15
	var rows: Array = []
	rows.append(["title", shown(Lang.pick(str(w.title[0]), str(w.title[1])))])
	rows.append(["centre", _say_w("sign")])
	rows.append(["centre", _say_w("r_place")])
	rows.append(["sep"])
	var order := shown(Lang.pick(str(w.order[0]), str(w.order[1])))
	var qty := _say_w("r_qty")
	if Kit.text_w(order) + 6 + Kit.text_w(qty) <= inner:
		rows.append(["pair", order, qty])
	else:
		for l in Kit.wrap(order, inner):
			rows.append(["line", l])
		rows.append(["pair", "", qty])
	rows.append(["pair", _say_w("r_grade"), w.grade])
	rows.append(["sep"])
	rows.append(["pair", _say_w("r_pay"), _say_w("r_zl").format({"n": w.pay})])
	rows.append(["pair", _say_w("r_respect"), "+%d" % w.respect])
	if not w.badges.is_empty() or not w.leak.is_empty():
		rows.append(["sep"])
	for b: Array in w.badges:
		rows.append(["badge", shown(Lang.pick(str(b[0]), str(b[1])))])
	if w.leak.size() >= 2:
		for l in Kit.wrap(shown(Lang.pick(str(w.leak[0]), str(w.leak[1]))), inner):
			rows.append(["leak", l])
	rows.append(["sep"])
	rows.append(["centre", _say_w("r_note")])
	rows.append(["barcode"])
	return rows


static func _say_w(tag: String) -> String:
	var p: Array = Win.say(tag)
	return shown(Lang.pick(str(p[0]), str(p[1])))


## The receipt's height for its rows, the button included (units).
static func receipt_h(rows: Array) -> float:
	var h := 5.0
	for r: Array in rows:
		match str(r[0]):
			"title":
				h += 16.0
			"sep":
				h += 5.0
			"badge":
				h += 11.0
			"barcode":
				h += 12.0
			_:
				h += 9.0
	return h + 18.0 + 4.0
