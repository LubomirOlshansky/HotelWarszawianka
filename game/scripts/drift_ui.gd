extends Control
## The drift stadium's own screen (Bokiem na Narodowym, the grey box: critique-drift.md section 4;
## docs/design/drift-narodowy.md 0b.3), on a CanvasLayer of the root viewport while the city's HUD is
## hidden. In the UI kit's tokens (ui_kit.gd), words from drift_tracks.json "words" (Polish or English).
##   - The top strip (TOP_SHARE of the height): WYNIK (the banked total) and the best, the run's
##     clock, and WIDOK Z GÓRY, PONÓW and ✕.
##   - The unbanked pile in gold above the car (`pile_at`, the stadium projects the car) with the
##     chain's chip (×3); a flash for what happened (ZAKSIĘGOWANE +2 340 in green, PRZEPADŁO in red,
##     ZONA!, KLIP!, PRZEKŁADKA!, IDEALNIE!, ZŁA STRONA, ZA WOLNO, BĄCZEK!).
##   - The tips at the start; the run's card at its end (the total, LINIA, KĄT, STYL; PONÓW, WYJDŹ).
##   - Change 4: the angle's arc only in WIDOK Z GÓRY (a 2D copy of the floor's wedge; in the iso view
##     the wedge under the car is the gauge).
## Everything under the top strip is the thumb's pad: `_input` hands its touches to the stadium
## (`thumb`); the top strip and the card keep theirs for their buttons.

const UiKit := preload("res://scripts/ui_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const DriftLine := preload("res://scripts/drift_line.gd")

signal top_pressed
signal retry_pressed
signal leave_pressed
## The thumb on the pad (or Space on a keyboard): down or up, the touch's index.
signal thumb(down: bool, index: int)

## The top strip's share of the screen's height (0b.3: the pad is everything under it).
const TOP_SHARE := 0.18
const FLASH_S := 1.3

var pt := 1.0
## The pile's screen point (set each frame by the stadium; off screen hides it).
var pile_at := Vector2(-1000, -1000)
var pile := 0
var chain := 1
var total := 0
var best := 0
var clock := 0.0
## The arc (WIDOK Z GÓRY only): the slip (°) and the bend's side (+1 left, -1 right, 0 none).
var arc_on := false
var arc_beta := 0.0
var arc_side := 0

var _total: Label
var _clock: Label
var _pile: Label
var _chip: Label
var _flash: Label
var _tip: Label
var _top: Button
var _card: PanelContainer
var _card_text: Label
var _flash_t := 0.0
var _tip_t := 0.0


static func w(id: String) -> String:
	var p := DriftLine.word(id)
	return Lang.pick(str(p[0]), str(p[1]))


## Thousands with a thin gap, as the city's money: 12 340.
static func num(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func build(points: float) -> void:
	pt = points
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip := HBoxContainer.new()
	strip.name = "TopStrip"
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.offset_left = UiKit.px(UiKit.PAD + 40.0, pt)
	strip.offset_right = -UiKit.px(UiKit.PAD + 40.0, pt)
	strip.offset_top = UiKit.px(UiKit.GAP, pt)
	strip.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	_total = _label(strip, "title", UiKit.T_TITLE)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(gap)
	_clock = _label(strip, "body", UiKit.T_TITLE)
	var gap2 := Control.new()
	gap2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(gap2)
	_top = _button(strip, w("top"), UiKit.Kind.SECONDARY)
	_top.pressed.connect(func() -> void: top_pressed.emit())
	_button(strip, w("retry"), UiKit.Kind.SECONDARY).pressed.connect(func() -> void: retry_pressed.emit())
	_button(strip, "✕", UiKit.Kind.DANGER).pressed.connect(func() -> void: leave_pressed.emit())
	_pile = _label(self, "title", UiKit.T_BANNER * 0.8)
	_pile.add_theme_color_override("font_outline_color", UiKit.OUTLINE)
	_pile.add_theme_constant_override("outline_size", UiKit.px(4.0, pt))
	_chip = _label(self, "body", UiKit.T_TITLE)
	_chip.add_theme_color_override("font_color", UiKit.ON_GOLD)
	var chip_box := UiKit.box(UiKit.GOLD, UiKit.GOLD_PRESS, pt, UiKit.R_PILL, UiKit.EDGE_W, 6.0)
	_chip.add_theme_stylebox_override("normal", chip_box)
	_flash = _label(self, "title", UiKit.T_BANNER * 0.7)
	_flash.add_theme_color_override("font_outline_color", UiKit.OUTLINE)
	_flash.add_theme_constant_override("outline_size", UiKit.px(4.0, pt))
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip = _label(self, "body", UiKit.T_BODY)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.add_theme_stylebox_override("normal", UiKit.glass(pt))
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiKit.card(pt))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	_card.add_child(col)
	_card_text = _label(col, "body", UiKit.T_BODY)
	_card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	col.add_child(row)
	_button(row, w("retry"), UiKit.Kind.PRIMARY).pressed.connect(func() -> void: retry_pressed.emit())
	_button(row, w("leave"), UiKit.Kind.SECONDARY).pressed.connect(func() -> void: leave_pressed.emit())
	_card.visible = false


func _label(parent: Control, role: String, size_pt: float) -> Label:
	var l := Label.new()
	UiKit.style_label(l, role, pt, size_pt)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, kind: int) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(b, kind, pt)
	b.custom_minimum_size = Vector2(UiKit.px(UiKit.TOUCH, pt), UiKit.px(UiKit.TOUCH, pt))
	parent.add_child(b)
	return b


## A screen point is on the pad (not the top strip, not a button or the card).
func on_pad(at: Vector2) -> bool:
	if at.y < size.y * TOP_SHARE:
		return false
	return not (_card.visible and _card.get_global_rect().has_point(at))


## The pad: a touch that starts under the top strip (not on the card) is the thumb; its release counts
## wherever it is. The project emulates touch from the mouse, so a Mac's click is a touch too.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and not on_pad(t.position):
			return
		thumb.emit(t.pressed, t.index)
	elif event is InputEventKey:
		# The keys are the stadium's while it is on (the PR review): Space is the thumb, Esc the ✕ (the
		# settings panel lives in the hidden HUD), and the city's keys (camera, M, K, H, ...) do nothing.
		var k := event as InputEventKey
		if not k.echo and k.physical_keycode == KEY_SPACE:
			thumb.emit(k.pressed, 99)
		elif k.pressed and not k.echo and k.physical_keycode == KEY_ESCAPE:
			leave_pressed.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventMagnifyGesture \
			or event is InputEventPanGesture or (event is InputEventMouseButton and (event as InputEventMouseButton).button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]):
		get_viewport().set_input_as_handled()  # no city zoom, view flick or pad command under the stadium


## A word flashes for FLASH_S s: `id` of the words, `extra` after it, in `colour`.
func flash(id: String, extra := "", colour := UiKit.GOLD) -> void:
	_flash.text = w(id) + ("" if extra == "" else " " + extra)
	_flash.add_theme_color_override("font_color", colour)
	_flash_t = FLASH_S


func show_tips() -> void:
	_tip.text = w("tip") + "\n" + w("tip_wedge")
	_tip_t = 7.0


func set_top(on: bool) -> void:
	_top.text = w("iso") if on else w("top")
	arc_on = on


## The run's card: the total and the three cards (LINIA, KĄT, STYL), the best so far.
func show_result(run_total: int, cards: Dictionary, best_total: int) -> void:
	_card_text.text = "%s · %s\n\n%s  %s\n%s  %s\n%s  %s\n\n%s  %s" % [w("run"), num(run_total),
			w("linia"), num(roundi(float(cards.get("linia", 0.0)))), w("kat"), num(roundi(float(cards.get("kat", 0.0)))),
			w("styl"), num(roundi(float(cards.get("styl", 0.0)))), w("best"), num(best_total)]
	_card.visible = true


func hide_result() -> void:
	_card.visible = false


func result_up() -> bool:
	return _card.visible


func _process(dt: float) -> void:
	size = get_viewport_rect().size  # a Control under a CanvasLayer: its rect is the screen's
	_total.text = "%s %s" % [w("score"), num(total)] + ("" if best <= 0 else "   %s %s" % [w("best"), num(best)])
	_clock.text = "%s %.1f" % [w("time"), clock]
	var show_pile := pile > 0 and pile_at.x > -500.0
	_pile.visible = show_pile
	_chip.visible = show_pile and chain > 1
	if show_pile:
		_pile.text = num(pile)
		_pile.reset_size()
		_pile.position = pile_at - Vector2(_pile.size.x * 0.5, _pile.size.y + UiKit.px(24.0, pt))
		_chip.text = "×%d" % chain
		_chip.reset_size()
		_chip.position = _pile.position + Vector2(_pile.size.x + UiKit.px(6.0, pt), _pile.size.y * 0.5 - _chip.size.y * 0.5)
	_flash_t -= dt
	_flash.visible = _flash_t > 0.0
	if _flash.visible:
		_flash.modulate.a = clampf(_flash_t / 0.3, 0.0, 1.0)
		_flash.reset_size()
		_flash.position = Vector2(size.x * 0.5 - _flash.size.x * 0.5, size.y * 0.24)
	_tip_t -= dt
	_tip.visible = _tip_t > 0.0 and not _card.visible
	if _tip.visible:
		_tip.modulate.a = clampf(_tip_t, 0.0, 1.0)
		_tip.size = Vector2(minf(size.x * 0.6, UiKit.px(520.0, pt)), 0.0)
		_tip.reset_size()
		_tip.size.x = minf(size.x * 0.6, UiKit.px(520.0, pt))
		_tip.position = Vector2(size.x * 0.5 - _tip.size.x * 0.5, size.y - _tip.size.y - UiKit.px(28.0, pt))
	if _card.visible:
		_card.reset_size()
		_card.position = (size - _card.size) * 0.5
	queue_redraw()


## Change 4's 2D copy of the wedge, only in WIDOK Z GÓRY: a 120° arc at the bottom centre, the green
## band 25-50°, the bright rim 45-55°, red past 65°, the needle on the slip.
func _draw() -> void:
	if not arc_on or arc_side == 0:
		return
	var r := float(UiKit.px(70.0, pt))
	var c := Vector2(size.x * 0.5, size.y - UiKit.px(18.0, pt))
	var wid := float(UiKit.px(9.0, pt))
	# 0° points up; the bend's side is to the right of the dial for a right bend.
	var to_rad := func(deg: float) -> float: return -PI * 0.5 + deg_to_rad(deg) * -float(arc_side)
	draw_arc(c, r, to_rad.call(-20.0), to_rad.call(85.0), 32, UiKit.GLASS, wid * 1.8)
	draw_arc(c, r, to_rad.call(25.0), to_rad.call(50.0), 12, UiKit.GO, wid)
	draw_arc(c, r + wid * 0.5, to_rad.call(45.0), to_rad.call(55.0), 6, UiKit.GOLD, wid * 0.6)
	draw_arc(c, r, to_rad.call(65.0), to_rad.call(80.0), 8, UiKit.ALERT, wid)
	var a: float = to_rad.call(clampf(arc_beta * float(arc_side), -20.0, 85.0))
	draw_line(c, c + Vector2(cos(a), sin(a)) * (r + wid), UiKit.INK, float(UiKit.px(3.0, pt)))
