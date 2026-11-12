extends CanvasLayer
## The title screen on a normal launch: a chrome "AROUND WARSAW" wordmark (WORDMARK) and the
## tagline under it, over a striped setting sun, the Warsaw skyline (the Palace of Culture against the
## sun), a neon perspective grid, and a palm in silhouette (the artificial palm on
## Rondo de Gaulle'a). The city builds behind it; once it is ready, a tap or any
## key fades the title out ("TAP TO DRIVE / DOTKNIJ, BY JECHAĆ").
##
## Save and resume (2026-10-31): with a save worth resuming (wallet.gd `has_progress`, main.gd sets
## `can_resume`) the prompt reads "KONTYNUUJ / continue" (a tap anywhere, Enter or Space: the car
## is where the last session left it) and a "NOWA GRA / new game" button sits in the bottom-right
## corner (or the N key). It asks first, "ZACZĄĆ OD NOWA?", with TAK / NIE (Y or T, N or Esc), since
## a new game wipes the progress (wallet.gd keeps one copy, save.prev.cfg); TAK emits `new_game`.

signal dismissed
## Save and resume: "NOWA GRA" confirmed (main.gd wipes the save and starts the city again).
signal new_game

## The game's name as the title shows it (the rename to Around Warsaw, 2026-10-30; it was
## "NOCNA WARSZAWA"). The one place to change it.
const Lang := preload("res://scripts/lang.gd")
const Sfx := preload("res://scripts/sfx.gd")
const WORDMARK := "AROUND WARSAW"
## The tagline under the wordmark, Polish above English (the rename, 2026-10-30). "Jeźdź" is
## the standard imperative of "jeździć" (the spoken "jeździj" is the common slip).
const TAGLINE_PL := "Jeźdź, lataj i odkrywaj prawdziwą Warszawę"
const TAGLINE_EN := "Drive, fly and discover the real Warsaw"

## The player picked a language here (POLSKI / ENGLISH, top right): main.gd keeps it (settings.gd `lang`).
signal language_chosen(code: String)

var ready_to_drive := false
## Desktop: --no-touch (trailer loop, 2026-10-29): no "tap to drive" prompt once the city is
## built (a key still starts the game).
var touch_off := false
var _root: Control
var _backdrop: ColorRect
var _palm: Control
var _mark: Label
var _shadow: Label
## The tagline's two lines (the rename, 2026-10-30): Polish, and English under it.
var _tag_pl: Label
var _tag_en: Label
var _prompt: Label
var _prompt_pl: Label
## Save and resume: a save to continue (set before set_ready), the "NOWA GRA" button, the
## confirmation's TAK and NIE buttons, the save's line under the prompt ("1 240 zł · respekt 87"),
## and the screen: CHOICE (continue or new game) or CONFIRM (TAK / NIE).
var can_resume := false
var resume_line := ""
## Save and resume: after "NOWA GRA" the city starts again with the title up; it goes by itself
## once the start is in (no second tap).
var auto_go := false
## The boot scene (boot.gd): the game could not be loaded; this line stands in the prompt's place.
var problem := ""
enum {CHOICE, CONFIRM}
var screen := CHOICE
var _new_btn: Label
## The language buttons, top right: one language is shown at a time (lang.gd).
var _lang_btns: Array[Label] = []
var _yes_btn: Label
var _no_btn: Label
var _line: Label
var _gone := false
var _t := 0.0
## The loading bar (F, 2026-11-05: the start screen looked frozen, then the city popped in): a
## thin neon bar over the prompt while the city loads, its share in the prompt ("budujemy
## miasto… 42 %"). main.gd sets `progress` (0..1) as the load goes (threaded loads, the build's
## steps, the start's sectors); the bar eases towards it and never goes back; set_ready fills it
## and fades it out.
var progress := 0.0
## The share the next report will reach: the bar creeps towards it between two reports.
var cap := 0.0
var _shown := 0.0
var _bar_plate: Panel
var _bar_fill: ColorRect
## Safe area in pixels: left, top, right, bottom.
var _safe := Rect2()


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/title.gdshader")
	_backdrop.material = mat
	_root.add_child(_backdrop)

	_palm = Control.new()
	_palm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_palm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palm.draw.connect(_draw_palm)
	_root.add_child(_palm)

	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.1
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	font.spacing_glyph = 2
	_shadow = _make_label(font)
	_mark = _make_label(font)
	var chrome := ShaderMaterial.new()
	chrome.shader = load("res://shaders/chrome.gdshader")
	_mark.material = chrome

	_tag_pl = _make_label(ThemeDB.fallback_font)
	_tag_en = _make_label(ThemeDB.fallback_font)
	_prompt = _make_label(ThemeDB.fallback_font)
	_prompt_pl = _make_label(ThemeDB.fallback_font)
	_line = _make_label(ThemeDB.fallback_font)
	_bar_plate = Panel.new()
	_bar_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.08, 0.02, 0.18, 0.82)
	plate.border_color = Color("#7ff6ff")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(3)
	_bar_plate.add_theme_stylebox_override("panel", plate)
	_root.add_child(_bar_plate)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color("#ff2fa0")
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_plate.add_child(_bar_fill)
	_new_btn = _make_button()
	_yes_btn = _make_button()
	_no_btn = _make_button()
	for code in Lang.CODES:
		var lb := _make_button()
		lb.visible = true
		lb.name = "lang_%s" % code
		_lang_btns.append(lb)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _make_label(font: Font) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


## Save and resume: a label on a dark, cyan-edged plate, as the HUD's buttons; hidden until used.
func _make_button() -> Label:
	var l := _make_label(ThemeDB.fallback_font)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.02, 0.18, 0.82)
	box.border_color = Color("#7ff6ff")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	l.add_theme_stylebox_override("normal", box)
	l.visible = false
	return l


## Everything is placed from the screen size, inside the safe area (notch, home bar).
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_safe = Rect2(Vector2.ZERO, size)
	if OS.has_feature("mobile"):
		var screen := DisplayServer.screen_get_size()
		var area := DisplayServer.get_display_safe_area()
		var k := size.x / float(maxi(screen.x, 1))
		_safe = Rect2(Vector2(area.position) * k, Vector2(area.size) * k)
	(_backdrop.material as ShaderMaterial).set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	var h := size.y
	var fs := int(minf(h * 0.12, _safe.size.x * 0.072))
	for l in [_mark, _shadow]:
		l.text = WORDMARK
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_constant_override("outline_size", maxi(4, int(fs * 0.1)))
		l.position = Vector2(_safe.position.x, h * 0.05)  # 0.07 before the tagline (2026-10-30)
		l.size = Vector2(_safe.size.x, fs * 1.6)
	_mark.add_theme_color_override("font_color", Color.WHITE)
	_mark.add_theme_color_override("font_outline_color", Color("#2a0838"))
	_shadow.add_theme_color_override("font_color", Color("#ff2fa0"))
	_shadow.add_theme_color_override("font_outline_color", Color("#ff2fa0"))
	_shadow.position += Vector2(fs * 0.06, fs * 0.08)
	# The chrome gradient spans the capitals: from the cap top to the baseline.
	var font: Font = _mark.get_theme_font("font")
	var ascent := font.get_ascent(fs)
	var chrome := _mark.material as ShaderMaterial
	chrome.set_shader_parameter("top", ascent - fs * 0.74)
	chrome.set_shader_parameter("bottom", ascent)

	# The tagline under the wordmark, in the prompt's colours: Polish ~14 pt, English ~12 pt
	# (h / 420 is about a point on the phones), each with a dark outline over the sun.
	var ts := int(maxf(h * 0.034, 13.0))
	var tag_top := h * 0.05 + fs * 1.22  # under the caps' pink shadow; both lines clear the Palace's spire
	_tag_pl.text = Lang.pick(TAGLINE_PL, TAGLINE_EN)
	_tag_pl.add_theme_font_size_override("font_size", ts)
	_tag_pl.add_theme_color_override("font_color", Color("#7ff6ff"))
	_tag_pl.add_theme_color_override("font_outline_color", Color("#14053a"))
	_tag_pl.add_theme_constant_override("outline_size", maxi(3, int(ts * 0.24)))
	_tag_pl.position = Vector2(_safe.position.x, tag_top)
	_tag_pl.size = Vector2(_safe.size.x, ts * 1.4)
	_tag_en.text = ""  # one language (lang.gd)
	_tag_en.add_theme_font_size_override("font_size", int(ts * 0.84))
	_tag_en.add_theme_color_override("font_color", Color("#ffb3e6"))
	_tag_en.add_theme_color_override("font_outline_color", Color("#14053a"))
	_tag_en.add_theme_constant_override("outline_size", maxi(3, int(ts * 0.2)))
	_tag_en.position = Vector2(_safe.position.x, tag_top + ts * 1.18)
	_tag_en.size = Vector2(_safe.size.x, ts * 1.3)

	var ps := int(maxf(h * 0.04, 14.0))
	_prompt.add_theme_font_size_override("font_size", ps)
	_prompt.add_theme_color_override("font_color", Color("#7ff6ff"))
	_prompt.add_theme_color_override("font_outline_color", Color("#14053a"))
	_prompt.add_theme_constant_override("outline_size", maxi(3, int(ps * 0.22)))
	_prompt_pl.add_theme_font_size_override("font_size", int(ps * 0.72))
	_prompt_pl.add_theme_color_override("font_color", Color("#ffb3e6"))
	_prompt_pl.add_theme_color_override("font_outline_color", Color("#14053a"))
	_prompt_pl.add_theme_constant_override("outline_size", maxi(3, int(ps * 0.18)))
	var bottom := _safe.end.y - h * 0.06
	_prompt_pl.size = Vector2(_safe.size.x, ps * 1.3)
	_prompt_pl.position = Vector2(_safe.position.x, bottom - ps * 1.0)
	_prompt.size = Vector2(_safe.size.x, ps * 1.5)
	_prompt.position = Vector2(_safe.position.x, bottom - ps * 2.4)
	# The loading bar just over the prompt: a third of the safe width, ~2 % of the height.
	var bar_h := maxf(h * 0.02, 8.0)
	_bar_plate.size = Vector2(_safe.size.x * 0.34, bar_h)
	_bar_plate.position = Vector2(size.x * 0.5 - _bar_plate.size.x * 0.5, bottom - ps * 2.4 - bar_h - ps * 0.35)
	_set_bar()
	# Save and resume: the save's line just under the prompt's English, the NOWA GRA button in
	# the bottom-right corner, TAK and NIE side by side above the prompt (each at least ~11 mm high).
	_line.add_theme_font_size_override("font_size", int(ps * 0.62))
	_line.add_theme_color_override("font_color", Color("#fff3b0"))
	_line.add_theme_color_override("font_outline_color", Color("#14053a"))
	_line.add_theme_constant_override("outline_size", maxi(3, int(ps * 0.16)))
	_line.size = Vector2(_safe.size.x, ps * 1.1)
	_line.position = Vector2(_safe.position.x, bottom + ps * 0.3)
	var bh := maxf(h * 0.1, 44.0)
	var bs := int(maxf(h * 0.03, 12.0))
	for b: Label in [_new_btn, _yes_btn, _no_btn]:
		b.add_theme_font_size_override("font_size", bs)
		b.add_theme_color_override("font_color", Color("#7ff6ff"))
		b.add_theme_color_override("font_outline_color", Color("#14053a"))
		b.add_theme_constant_override("outline_size", maxi(2, int(bs * 0.16)))
	_new_btn.size = Vector2(maxf(bs * 9.0, 140.0), bh)
	_new_btn.position = Vector2(_safe.end.x - _new_btn.size.x - h * 0.03, _safe.end.y - bh - h * 0.04)
	var bw := maxf(bs * 13.0, 200.0)
	var gap := h * 0.04
	var by := bottom - ps * 2.4 - bh - gap
	_yes_btn.size = Vector2(bw, bh)
	_no_btn.size = Vector2(bw * 0.6, bh)
	var row := _yes_btn.size.x + gap + _no_btn.size.x
	_yes_btn.position = Vector2(size.x * 0.5 - row * 0.5, by)
	_no_btn.position = Vector2(_yes_btn.position.x + bw + gap, by)
	# The language buttons, top right, inside the safe area: each at least 44 px tall.
	var lw := maxf(bs * 7.0, 96.0)
	for k in _lang_btns.size():
		var lb := _lang_btns[k]
		lb.add_theme_font_size_override("font_size", bs)
		lb.add_theme_constant_override("outline_size", maxi(2, int(bs * 0.16)))
		lb.size = Vector2(lw, bh)
		lb.position = Vector2(_safe.end.x - (lw + h * 0.02) * float(_lang_btns.size() - k) - h * 0.02, _safe.position.y + h * 0.03)
	_set_prompt()
	_palm.queue_redraw()


## Loop 2e: Polish above English (the big upper line is Polish, the small one under it English).
func _set_prompt() -> void:
	var choosing := ready_to_drive and can_resume and not auto_go
	_new_btn.visible = choosing and screen == CHOICE
	_yes_btn.visible = choosing and screen == CONFIRM
	_no_btn.visible = choosing and screen == CONFIRM
	_line.visible = choosing and screen == CHOICE and resume_line != ""
	_new_btn.text = Lang.pick("NOWA GRA", "NEW GAME")
	_yes_btn.text = Lang.pick("TAK, OD NOWA", "YES, START OVER")
	_no_btn.text = Lang.pick("NIE", "NO")
	_line.text = resume_line
	_tag_pl.text = Lang.pick(TAGLINE_PL, TAGLINE_EN)
	for k in _lang_btns.size():
		var code: String = Lang.CODES[k]
		_lang_btns[k].text = Lang.NAMES[code]
		var on: bool = code == Lang.code
		_lang_btns[k].add_theme_color_override("font_color", Color("#ffd23f") if on else Color("#7ff6ff"))
		_lang_btns[k].modulate.a = 1.0 if on else 0.7
	_prompt_pl.text = ""  # one language at a time (lang.gd): the small second line is gone
	if problem != "":
		_prompt.text = problem
	elif choosing and screen == CONFIRM:
		_prompt.text = Lang.pick("ZACZĄĆ OD NOWA? Pieniądze, zlecenia i znaleziska znikną", "START OVER? The money, jobs and finds are wiped")
	elif choosing:
		_prompt.text = Lang.pick("KONTYNUUJ", "CONTINUE")
	elif ready_to_drive and auto_go:
		_prompt.text = Lang.pick("NOWA GRA", "NEW GAME")
	elif ready_to_drive and touch_off:
		_prompt.text = ""  # desktop: --no-touch
	elif ready_to_drive:
		_prompt.text = Lang.pick("DOTKNIJ, BY JECHAĆ", "TAP TO DRIVE")
	else:
		_prompt.text = Lang.pick("budujemy miasto… %d %%", "building the city… %d %%") % roundi(_shown * 100.0)


## The loading bar's fill (2 px inside the plate's edge).
func _set_bar() -> void:
	var inner := _bar_plate.size - Vector2(4.0, 4.0)
	_bar_fill.position = Vector2(2.0, 2.0)
	_bar_fill.size = Vector2(maxf(inner.x * clampf(_shown, 0.0, 1.0), 0.0), maxf(inner.y, 0.0))


## Lays the title out again with its words as they are now (main.gd, when it takes over the
## boot scene's title and a flag has changed the language).
func refresh() -> void:
	_layout()


## The city is built: the prompt changes and a tap or a key starts the game.
func set_ready() -> void:
	ready_to_drive = true
	_t = 0.0
	progress = 1.0
	_shown = 1.0
	_set_bar()
	_set_prompt()
	var fade := create_tween()
	fade.tween_property(_bar_plate, "modulate:a", 0.0, 0.35).set_delay(0.15)
	if auto_go:
		dismiss()


func _process(dt: float) -> void:
	_t += dt
	if not ready_to_drive:
		# The bar eases towards the load's share (quick to catch up, never back); between two
		# reports it creeps a little so a long step doesn't look stuck, never past the next 5 %.
		var target := clampf(progress, _shown, 1.0)
		var next := minf(_shown + (target - _shown) * minf(dt * 8.0, 1.0), 1.0)
		if next - _shown < 0.0005 and _shown < minf(progress + 0.05, 0.99):
			next = _shown + dt * 0.01
		# Between two reports the bar keeps moving towards the next report's share (`cap`, set by
		# main.gd; F, 2026-11-08: it stood at 56 % for 10 s while frames were flowing), slowing as it
		# nears it, never reaching it.
		if cap > _shown and next - _shown < dt * 0.03:
			next = minf(_shown + maxf(cap * 0.97 - _shown, 0.0) * (1.0 - exp(-dt / 5.0)) + dt * 0.003, 0.99)
		if next != _shown:
			var pct := roundi(_shown * 100.0)
			_shown = next
			_set_bar()
			if roundi(_shown * 100.0) != pct:
				_set_prompt()
	if ready_to_drive and not _gone and screen == CHOICE:
		# The prompt pulses like a VCR's menu (still while the question is asked).
		var a := 0.45 + 0.55 * (0.5 + 0.5 * cos(_t * 4.2))
		_prompt.modulate.a = a
		_prompt_pl.modulate.a = a


func _input(event: InputEvent) -> void:
	if _gone:
		return
	var go := false
	var key := KEY_NONE
	var at := Vector2.INF
	if event is InputEventKey:
		go = (event as InputEventKey).pressed and not (event as InputEventKey).echo
		key = (event as InputEventKey).keycode
	elif event is InputEventScreenTouch:
		go = (event as InputEventScreenTouch).pressed
		at = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton:
		go = (event as InputEventMouseButton).pressed
		at = (event as InputEventMouseButton).position
	elif event is InputEventJoypadButton:
		# The gamepad loop: A or Start is Enter, Y is NOWA GRA (N), B is NIE (Esc).
		var b := event as InputEventJoypadButton
		go = b.pressed
		key = pad_key(b.button_index, screen == CONFIRM)
		if key == KEY_NONE and go:
			return  # a stick click or a shoulder: not a pick
	if not go:
		return
	# The language buttons work from the first frame, and never start the game.
	if at != Vector2.INF or key == KEY_L:
		var picked := _lang_at(at, key)
		if picked != "":
			get_viewport().set_input_as_handled()
			choose_language(picked)
			return
	get_viewport().set_input_as_handled()
	if not ready_to_drive:
		return
	if not can_resume or auto_go:
		dismiss()
		return
	choose(_pick(key, at))


## Which language button a tap at `at` hits (or L, which switches), "" if none.
func _lang_at(at: Vector2, key: Key) -> String:
	if key == KEY_L:
		return Lang.EN if Lang.code == Lang.PL else Lang.PL
	for k in _lang_btns.size():
		if at != Vector2.INF and _lang_btns[k].get_global_rect().grow(6.0).has_point(at):
			return Lang.CODES[k]
	return ""


## Shows the title in `code` (the player's pick; check_language.gd calls it too) and tells main.gd.
func choose_language(code: String) -> void:
	if code == Lang.code:
		return
	Lang.set_code(code)
	language_chosen.emit(code)  # main.gd saves it and renews the save line
	_layout()


## The gamepad loop: the key a pad button stands for on the title (KEY_NONE: no job here). On
## the question A is TAK (Y) and B is NIE; otherwise A / Start continue, Y starts anew, B does nothing.
static func pad_key(button: JoyButton, confirm: bool) -> Key:
	match button:
		JOY_BUTTON_A:
			return KEY_Y if confirm else KEY_ENTER
		JOY_BUTTON_START:
			return KEY_ENTER
		JOY_BUTTON_Y:
			return KEY_NONE if confirm else KEY_N
		JOY_BUTTON_B:
			return KEY_ESCAPE if confirm else KEY_NONE
	return KEY_NONE


## Save and resume: what a key or a tap at `at` picks on the screen shown: "continue", "new",
## "yes", "no" or "" (nothing: a stray key on the question).
func _pick(key: Key, at: Vector2) -> String:
	if screen == CONFIRM:
		if key in [KEY_Y, KEY_T] or (at != Vector2.INF and _yes_btn.get_global_rect().grow(6.0).has_point(at)):
			return "yes"
		if key in [KEY_N, KEY_ESCAPE, KEY_BACKSPACE] or (at != Vector2.INF and _no_btn.get_global_rect().grow(6.0).has_point(at)):
			return "no"
		return ""
	if key == KEY_N or (at != Vector2.INF and _new_btn.get_global_rect().grow(6.0).has_point(at)):
		return "new"
	return "continue"


## Save and resume: acts on a pick ("continue", "new", "yes", "no"; check_save.gd calls it too).
func choose(what: String) -> void:
	match what:
		"continue":
			dismiss()
		"new":
			screen = CONFIRM
			_set_prompt()
			_prompt.modulate.a = 1.0
			_prompt_pl.modulate.a = 1.0
		"no":
			screen = CHOICE
			_set_prompt()
		"yes":
			_gone = true
			new_game.emit()


func dismiss() -> void:
	if _gone:
		return
	_gone = true
	_prompt.modulate.a = 1.0
	_prompt_pl.modulate.a = 1.0
	Sfx.ui("start")
	dismissed.emit()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free).set_delay(0.6)


## The palm: a curved, ringed trunk and a crown of drooping fronds, each a rachis
## with leaflets hanging off both sides, in silhouette with a pink rim on the
## sun's side.
func _draw_palm() -> void:
	var size := get_viewport().get_visible_rect().size
	var h := size.y
	var base := Vector2(_safe.position.x + _safe.size.x * 0.1, h * 1.02)
	var height := h * 0.58
	var top := base + Vector2(height * 0.2, -height)
	var bend := base + Vector2(-height * 0.04, -height * 0.55)
	var rim := Color("#ff4fb0")
	var dark := Color("#10041f")
	var px := maxf(h / 720.0, 1.0)
	for pass_i in 2:
		var off := Vector2(2.5, -1.5) * px if pass_i == 0 else Vector2.ZERO
		var col := rim if pass_i == 0 else dark
		# Trunk: quadratic curve, tapering, in short ringed segments.
		var segs := 18
		for i in segs:
			var t0 := float(i) / segs
			var t1 := float(i + 1) / segs
			var p0 := _bezier(base, bend, top, t0)
			var p1 := _bezier(base, bend, top, t1)
			var w0 := lerpf(height * 0.045, height * 0.024, t0)
			var w1 := lerpf(height * 0.045, height * 0.024, t1) * 0.84
			var d := (p1 - p0).normalized()
			var n := Vector2(-d.y, d.x)
			_palm.draw_primitive(PackedVector2Array([p0 + n * w0 + off, p0 - n * w0 + off,
					p1 - n * w1 + off, p1 + n * w1 + off]), PackedColorArray([col, col, col, col]), PackedVector2Array())
		# Fronds: arcs out from the top that droop towards their tips.
		var fronds := [-3.05, -2.6, -2.15, -1.75, -1.35, -0.95, -0.5, -0.08, 0.3]
		for k in fronds.size():
			var a: float = fronds[k]
			var length := height * (0.4 + 0.07 * sin(k * 2.3))
			var dir := Vector2(cos(a), sin(a))
			var tip := top + dir * length + Vector2(0, height * (0.12 + 0.3 * absf(dir.x)))
			var mid := top + dir * length * 0.55 - Vector2(0, height * 0.06)
			var steps := 16
			var prev := top + off
			for i in range(1, steps + 1):
				var t := float(i) / steps
				var p := _bezier(top, mid, tip, t) + off
				var d := (p - prev).normalized()
				var n := Vector2(-d.y, d.x)
				if n.y < 0.0:
					n = -n
				_palm.draw_line(prev, p, col, maxf(height * 0.01 * (1.0 - t * 0.6), 1.5 * px))
				# Leaflets: thin blades hanging off both sides, longest mid-frond.
				var leaf := sin(PI * minf(t * 1.25, 1.0)) * height * 0.085
				for side: float in [-1.0, 1.0]:
					var hang := (n * side * 0.75 + Vector2(0, 0.85) + d * 0.35).normalized() * leaf
					var w := (p - prev) * 0.55
					# draw_primitive: a plain triangle, no triangulation (tips can be degenerate).
					_palm.draw_primitive(PackedVector2Array([prev, p, p - w * 0.2 + hang]), PackedColorArray([col, col, col]), PackedVector2Array())
				prev = p
		_palm.draw_circle(top + off, height * 0.03, col)


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
