extends Control
## The phone (F 2026-11-26, "the phone with jobs"): the card the TELEFON chip opens, over a dimmed
## city, the game paused under it (main.gd holds PauseReasons.PHONE). One row of apps (ŁUBER the
## ride, ZLECENIA the side jobs, ZADANIA the quests, COTAM the messenger, not built yet) and under it
## the three featured quests, each with a START. What is in it is phone_rules.gd's `model`; this
## script only draws it and hands a press back: `app_pressed(key)`, `featured_pressed(id)`, `closed`.
## Sized in points like the rest of the HUD (`pt`), every control at least 44 pt, the card scrolls
## when a short phone has no room for it all. The look is ui_kit.gd's (docs/design/ui-kit.md).

signal app_pressed(key: String)
signal featured_pressed(id: String)
signal closed

const UiKit := preload("res://scripts/ui_kit.gd")
const Rules := preload("res://scripts/phone_rules.gd")
const Lang := preload("res://scripts/lang.gd")

const CARD_W := 420.0
const TILE_H := 64.0
const ROW_H := 46.0

var pt := 1.0
var safe := Rect2()
## The game's clock for the status line (main.gd: {"hour": float}); the device's when unset.
var local_clock: Callable

var _card: PanelContainer
var _scroll: ScrollContainer


func _init() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Shows the phone for `model` (phone_rules.gd `model`).
func open(model: Dictionary) -> void:
	# The HUD is a CanvasLayer (no parent size to anchor to): fill the viewport by hand.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_build(model)
	visible = true


func _process(_delta: float) -> void:
	# A Control under a CanvasLayer has no parent to anchor to: keep it the viewport's size.
	var vp := get_viewport_rect().size
	if visible and size != vp:
		size = vp


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _gui_input(event: InputEvent) -> void:
	# The card and its buttons take their own presses, so a press that reaches this root is on the
	# dim outside the card: it closes the phone.
	var tap := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	var click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if tap or click:
		close()
		accept_event()


func _build(model: Dictionary) -> void:
	if _card != null:
		_card.queue_free()
	var scrim := get_node_or_null("Scrim") as ColorRect
	if scrim == null:
		scrim = ColorRect.new()
		scrim.name = "Scrim"
		scrim.color = UiKit.SCRIM
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card = PanelContainer.new()
	_card.name = "Card"
	_card.add_theme_stylebox_override("panel", UiKit.card(pt, UiKit.PAD))
	add_child(_card)
	var area := safe if safe.size.x > 0.0 else Rect2(Vector2.ZERO, get_viewport_rect().size)
	var w := minf(CARD_W * pt, area.size.x - 24.0 * pt)
	var h_max := area.size.y - 16.0 * pt
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	box.custom_minimum_size.x = w - 2.0 * UiKit.PAD * pt

	var head := HBoxContainer.new()
	var title := _label(Rules.words("title"), "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var clock := _label([_clock_text(), _clock_text()], "sub")
	head.add_child(clock)
	var close_btn := Button.new()
	close_btn.name = "close"
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(UiKit.TOUCH, UiKit.TOUCH) * pt
	UiKit.style_button(close_btn, UiKit.Kind.SECONDARY, pt, UiKit.T_TITLE)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	box.add_child(head)

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	for a: Dictionary in model.get("apps", []):
		tiles.add_child(_tile(a))
	box.add_child(tiles)

	var rows: Array = model.get("featured", [])
	if not rows.is_empty():
		box.add_child(_label(Rules.words("featured_head"), "label"))
		for r: Dictionary in rows:
			box.add_child(_row(r))

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.add_child(box)
	_card.add_child(_scroll)
	_scroll.custom_minimum_size = Vector2(w - 2.0 * UiKit.PAD * pt, 0)
	# Size the card to its contents, but never taller than the safe area (then it scrolls).
	_card.reset_size.call_deferred()
	_fit.call_deferred(area, w, h_max, box)


func _fit(area: Rect2, w: float, h_max: float, box: Control) -> void:
	if _card == null or box == null:
		return
	var inner_h := box.get_combined_minimum_size().y
	var h := minf(inner_h + 2.0 * UiKit.PAD * pt, h_max)
	_scroll.custom_minimum_size.y = h - 2.0 * UiKit.PAD * pt
	_card.size = Vector2(w, h)
	_card.position = area.position + (area.size - _card.size) * 0.5


func _tile(a: Dictionary) -> Button:
	var b := Button.new()
	b.name = "app_" + str(a["key"])
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, TILE_H * pt)
	UiKit.style_button(b, UiKit.Kind.SECONDARY, pt)
	var col: Color = a["colour"]
	var on := bool(a["enabled"])
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := _label(a["title"], "body")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", col if on else UiKit.FAINT)
	t.uppercase = true
	words.add_child(t)
	var s := _label(a["sub"], "faint")
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(s)
	b.add_child(words)
	b.disabled = not on
	var key := str(a["key"])
	b.pressed.connect(func() -> void: app_pressed.emit(key))
	return b


func _row(r: Dictionary) -> Button:
	var b := Button.new()
	b.name = "feat_" + str(r["id"])
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, ROW_H * pt)
	UiKit.style_button(b, UiKit.Kind.SECONDARY, pt)
	var on := bool(r["enabled"])
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = UiKit.px(UiKit.GAP, pt)
	h.offset_right = -UiKit.px(UiKit.GAP, pt)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := _label(r["title"], "body")
	t.add_theme_color_override("font_color", r["colour"])
	v.add_child(t)
	v.add_child(_label(r["sub"], "faint"))
	h.add_child(v)
	var state := _label(Rules.words("done") if bool(r["done"]) else Rules.words("b_start"), "label")
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(state)
	b.add_child(h)
	b.disabled = not on
	var id := str(r["id"])
	b.pressed.connect(func() -> void: featured_pressed.emit(id))
	return b


func _label(pair: Array, role: String) -> Label:
	var l := Label.new()
	l.text = _pick(pair)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.style_label(l, role, pt)
	return l


func _pick(pair: Array) -> String:
	return Lang.pick(str(pair[0]), str(pair[1]))


func _clock_text() -> String:
	if not local_clock.is_valid():
		return Time.get_time_string_from_system().substr(0, 5)
	var m := posmod(floori(float(local_clock.call()["hour"]) * 60.0), 24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]
