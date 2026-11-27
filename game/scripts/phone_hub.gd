extends Control
## The phone (F 2026-11-26, "the phone with jobs"; F 2026-11-27: "it should look like the phone, compact
## like the call, with minimum information, four buttons in a landscape view; QUESTS opens the big
## screen; ŁUBER and the food app open inside it, looking for…, and you take or not; ŁUBER with the
## passenger's photo and rating"; then "like the incoming call, compact on the right, all inside the phone"). A portrait handset on the right, like the call card's frame, over a dimmed city, the game paused under it
## (phone.gd holds PauseReasons.PHONE).
##
## Home: the four apps (phone_rules.gd `model`) as a 2x2 grid of icons. An app that offers (ŁUBER, GŁODNO) goes to
## a searching screen for SEARCH_S seconds, then phone.gd answers with an offer (`show_offer`: the
## face, the words, TAKE / SKIP) or nothing (`show_none`). This script only draws and hands presses
## back: `app_pressed(key)`, `home_pressed`, `searched(key)`, `offer_taken(key)`, `offer_skipped(key)`, `closed`.
## Sized in points like the rest of the HUD (`pt`), every control at least 44 pt. The look is
## ui_kit.gd's (docs/design/ui-kit.md); the faces are portraits.gd's.

signal app_pressed(key: String)
signal searched(key: String)
signal home_pressed
signal offer_taken(key: String)
signal offer_skipped(key: String)
signal closed

const UiKit := preload("res://scripts/ui_kit.gd")
const Rules := preload("res://scripts/phone_rules.gd")
const Lang := preload("res://scripts/lang.gd")
const Portraits := preload("res://scripts/portraits.gd")

const PHONE_W := 214.0
const PHONE_H := 372.0
const TILE_H := 96.0
const EDGE_GAP := 20.0

var pt := 1.0
var safe := Rect2()
## The game's clock for the status line (main.gd: {"hour": float}); the device's when unset.
var local_clock: Callable

var _frame: PanelContainer
var _body: VBoxContainer
var _head: HBoxContainer
## The app on screen ("" home): the search timer only answers while it is still the one asked.
var _app := ""
var _search_id := 0


func _init() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)


## Shows the phone, on its home, for `model` (phone_rules.gd `model`).
func open(model: Dictionary) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	if get_node_or_null("Scrim") == null:
		var scrim := ColorRect.new()
		scrim.name = "Scrim"
		scrim.color = UiKit.SCRIM
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scrim)
		scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_frame()
	visible = true
	show_home(model)


func _process(_delta: float) -> void:
	# A Control under a CanvasLayer has no parent to anchor to: keep it the viewport's size.
	var vp := get_viewport_rect().size
	if visible and size != vp:
		size = vp
		_place()


func close() -> void:
	if not visible:
		return
	visible = false
	_app = ""
	_search_id += 1
	closed.emit()


func is_open() -> bool:
	return visible


## The app on screen ("" for the home).
func app() -> String:
	return _app


func _gui_input(event: InputEvent) -> void:
	# The handset and its buttons take their own presses, so a press that reaches this root is on the
	# dim outside it: it closes the phone.
	var tap := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	var click := event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if tap or click:
		close()
		accept_event()


# --- the screens ---------------------------------------------------------------------------------

func show_home(model: Dictionary) -> void:
	_app = ""
	_search_id += 1
	_clear()
	_status_strip()
	var tiles := GridContainer.new()
	tiles.name = "tiles"
	tiles.columns = 2
	tiles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tiles.add_theme_constant_override("h_separation", UiKit.px(UiKit.GAP, pt))
	tiles.add_theme_constant_override("v_separation", UiKit.px(UiKit.GAP, pt))
	for a: Dictionary in model.get("apps", []):
		tiles.add_child(_tile(a))
	_body.add_child(tiles)
	_home_bar()


## The searching screen of app `key`: "looking for…" with moving dots, then `searched(key)`.
func show_search(key: String, title: Array, colour: Color) -> void:
	_app = key
	_search_id += 1
	var mine := _search_id
	_clear()
	_status_strip()
	_header(title, colour)
	var l := _label(Rules.words("searching"), "title")
	l.name = "searching"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", colour)
	_body.add_child(l)
	_home_bar()
	await get_tree().create_timer(Rules.SEARCH_S, true, false, true).timeout
	if mine == _search_id and visible:
		searched.emit(key)


## An offer on app `key`'s screen: offer {"who" (the face, "" none), "title", "body" ([pl, en]),
## "stars" (their rating, -1 none)}.
func show_offer(key: String, title: Array, offer: Dictionary, colour: Color) -> void:
	_app = key
	_search_id += 1
	_clear()
	_status_strip()
	_header(title, colour)
	var col := VBoxContainer.new()
	col.name = "offer"
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	var who := str(offer.get("who", ""))
	var face := Portraits.badge(72.0 * pt)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Portraits.set_badge(face, who, colour)
	col.add_child(face)
	var t := _label(offer["title"], "label")
	t.add_theme_color_override("font_color", colour)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)
	var b := _label(offer["body"], "body")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 150.0 * pt
	col.add_child(b)
	_body.add_child(col)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	var skip := _button("skip", Rules.words("b_skip"), UiKit.Kind.SECONDARY, 60.0)
	skip.pressed.connect(func() -> void: offer_skipped.emit(key))
	var take := _button("take", Rules.words("b_take"), UiKit.Kind.PRIMARY, 60.0)
	take.pressed.connect(func() -> void: offer_taken.emit(key))
	buttons.add_child(skip)
	buttons.add_child(take)
	_body.add_child(buttons)
	_home_bar()


## Nothing on offer on app `key`'s screen.
func show_none(key: String, title: Array, colour: Color) -> void:
	_app = key
	_search_id += 1
	_clear()
	_status_strip()
	_header(title, colour)
	var l := _label(Rules.words("none_" + key), "body")
	l.name = "none"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(l)
	_home_bar()


# --- the parts -----------------------------------------------------------------------------------

func _ensure_frame() -> void:
	if _frame != null:
		return
	_frame = PanelContainer.new()
	_frame.name = "Handset"
	var bezel := UiKit.box(UiKit.CARD_SOLID, UiKit.EDGE_STRONG, pt, 22.0, 1.5, 12.0)
	_frame.add_theme_stylebox_override("panel", bezel)
	add_child(_frame)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	_frame.add_child(_body)
	_place()


func _place() -> void:
	if _frame == null:
		return
	var area := safe if safe.size.x > 0.0 else Rect2(Vector2.ZERO, get_viewport_rect().size)
	_frame.size = Vector2(minf(PHONE_W * pt, area.size.x - 24.0 * pt), minf(PHONE_H * pt, area.size.y - 16.0 * pt))
	_frame.position = Vector2(area.end.x - _frame.size.x - EDGE_GAP * pt, area.position.y + (area.size.y - _frame.size.y) * 0.5)


func _clear() -> void:
	_place()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()


## The phone's status line: the clock on the left, "5G" and a battery on the right (a look, no buttons).
func _status_strip() -> void:
	var row := HBoxContainer.new()
	row.name = "status"
	var clock := _label([_clock_text(), _clock_text()], "sub")
	clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(clock)
	var net := _label(["5G", "5G"], "sub")
	row.add_child(net)
	var bat := Control.new()
	bat.custom_minimum_size = Vector2(22.0, 12.0) * pt
	bat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bat.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, bat.size - Vector2(3.0 * pt, 0.0))
		bat.draw_rect(r, UiKit.FAINT, false, 1.5 * pt)
		bat.draw_rect(r.grow(-3.0 * pt), UiKit.FAINT)
		bat.draw_rect(Rect2(r.end.x, bat.size.y * 0.3, 3.0 * pt, bat.size.y * 0.4), UiKit.FAINT))
	row.add_child(bat)
	_body.add_child(row)


## An app's header: BACK to the home and the app's name in its colour.
func _header(title: Array, colour: Color) -> void:
	_head = HBoxContainer.new()
	_head.name = "head"
	_head.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	var bk := _button("back", Rules.words("b_back"), UiKit.Kind.SECONDARY, 0.0)
	bk.pressed.connect(func() -> void: home_pressed.emit())
	_head.add_child(bk)
	var t := _label(title, "title")
	t.add_theme_color_override("font_color", colour)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_head.add_child(t)
	_body.add_child(_head)


## The home bar along the bottom (a 44 pt button, drawn as the phone's grey bar): puts the phone away.
func _home_bar() -> void:
	var x := Button.new()
	x.name = "close"
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2(0.0, UiKit.TOUCH * pt)
	UiKit.style_button(x, UiKit.Kind.SECONDARY, pt)
	x.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	x.pressed.connect(close)
	x.draw.connect(func() -> void:
		var w := x.size.x * 0.4
		x.draw_rect(Rect2((x.size.x - w) * 0.5, x.size.y * 0.5 - 2.0 * pt, w, 4.0 * pt), UiKit.FAINT))
	_body.add_child(x)


func _button(name_: String, words: Array, kind: int, min_w := 120.0) -> Button:
	var b := Button.new()
	b.name = name_
	b.text = _pick(words)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if min_w > 0.0 else Control.SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(min_w * pt, UiKit.TOUCH * pt)
	UiKit.style_button(b, kind, pt)
	return b


func _tile(a: Dictionary) -> Button:
	var b := Button.new()
	b.name = "app_" + str(a["key"])
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, TILE_H * pt)
	UiKit.style_button(b, UiKit.Kind.SECONDARY, pt)
	var col: Color = a["colour"]
	var on := bool(a["enabled"])
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", UiKit.px(2.0, pt))
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The app's icon: a drawn glyph in the app's colour on a round disc.
	var icon := Control.new()
	icon.custom_minimum_size = Vector2.ONE * 48.0 * pt
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key := str(a["key"])
	icon.draw.connect(func() -> void: _draw_glyph(icon, key, col if on else UiKit.DIM, UiKit.ON_GOLD if on else UiKit.FAINT))
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	words.add_child(holder)
	var t := _label(a["title"], "body")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", col if on else UiKit.FAINT)
	t.uppercase = true
	words.add_child(t)
	b.add_child(words)
	b.disabled = not on
	b.pressed.connect(func() -> void: app_pressed.emit(key))
	return b


## The four app icons, drawn: ŁUBER a car, GŁODNO a kebab on its spit, ZADANIA a flag, COTAM an envelope.
func _draw_glyph(c: Control, key: String, disc: Color, ink: Color) -> void:
	var r := c.size.x * 0.5
	var m := c.size * 0.5
	c.draw_circle(m, r, disc)
	match key:
		"luber":
			c.draw_rect(Rect2(m + Vector2(-r * 0.55, -r * 0.05), Vector2(r * 1.1, r * 0.4)), ink)
			c.draw_rect(Rect2(m + Vector2(-r * 0.32, -r * 0.38), Vector2(r * 0.64, r * 0.36)), ink)
			c.draw_circle(m + Vector2(-r * 0.3, r * 0.38), r * 0.14, disc)
			c.draw_circle(m + Vector2(r * 0.3, r * 0.38), r * 0.14, disc)
		"glodno":
			c.draw_line(m + Vector2(0, -r * 0.6), m + Vector2(0, r * 0.6), ink, maxf(2.0, r * 0.1))
			for i in 3:
				var w := r * (0.5 + 0.12 * (1 - absf(i - 1)))
				c.draw_rect(Rect2(m + Vector2(-w * 0.5, -r * 0.42 + i * r * 0.3), Vector2(w, r * 0.24)), ink)
		"quests":
			c.draw_line(m + Vector2(-r * 0.3, -r * 0.55), m + Vector2(-r * 0.3, r * 0.55), ink, maxf(2.0, r * 0.1))
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(-r * 0.3, -r * 0.5), m + Vector2(r * 0.5, -r * 0.25), m + Vector2(-r * 0.3, r * 0.05)]), ink)
		_:
			var e := Rect2(m + Vector2(-r * 0.55, -r * 0.35), Vector2(r * 1.1, r * 0.7))
			c.draw_rect(e, ink, false, maxf(2.0, r * 0.09))
			c.draw_polyline(PackedVector2Array([e.position, m + Vector2(0, r * 0.05), Vector2(e.end.x, e.position.y)]), ink, maxf(2.0, r * 0.09))


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
