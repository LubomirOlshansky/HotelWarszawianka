extends Control
## The phone (F 2026-11-26, "the phone with jobs"; F 2026-11-27: "it should look like the phone, compact
## like the call, with minimum information, four buttons in a landscape view; QUESTS opens the big
## screen; ŁUBER and the food app open inside it, looking for…, and you take or not; ŁUBER with the
## passenger's photo and rating"). A landscape handset over a dimmed city, the game paused under it
## (phone.gd holds PauseReasons.PHONE).
##
## Home: the four apps (phone_rules.gd `model`) in a row. An app that offers (ŁUBER, GŁODNO) goes to
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

const PHONE_W := 560.0
const PHONE_H := 236.0
const TILE_H := 112.0

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
	_header(Rules.words("title"), UiKit.GOLD, false)
	var tiles := HBoxContainer.new()
	tiles.name = "tiles"
	tiles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tiles.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	for a: Dictionary in model.get("apps", []):
		tiles.add_child(_tile(a))
	_body.add_child(tiles)


## The searching screen of app `key`: "looking for…" with moving dots, then `searched(key)`.
func show_search(key: String, title: Array, colour: Color) -> void:
	_app = key
	_search_id += 1
	var mine := _search_id
	_clear()
	_header(title, colour, true)
	var l := _label(Rules.words("searching"), "title")
	l.name = "searching"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", colour)
	_body.add_child(l)
	await get_tree().create_timer(Rules.SEARCH_S, true, false, true).timeout
	if mine == _search_id and visible:
		searched.emit(key)


## An offer on app `key`'s screen: offer {"who" (the face, "" none), "title", "body" ([pl, en]),
## "stars" (their rating, -1 none)}.
func show_offer(key: String, title: Array, offer: Dictionary, colour: Color) -> void:
	_app = key
	_search_id += 1
	_clear()
	_header(title, colour, true)
	var row := HBoxContainer.new()
	row.name = "offer"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", UiKit.px(UiKit.PAD, pt))
	var who := str(offer.get("who", ""))
	var face := Portraits.badge(84.0 * pt)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Portraits.set_badge(face, who, colour)
	row.add_child(face)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := _label(offer["title"], "label")
	t.add_theme_color_override("font_color", colour)
	words.add_child(t)
	var b := _label(offer["body"], "body")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 200.0 * pt
	words.add_child(b)
	row.add_child(words)
	_body.add_child(row)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	var skip := _button("skip", Rules.words("b_skip"), UiKit.Kind.SECONDARY)
	skip.pressed.connect(func() -> void: offer_skipped.emit(key))
	var take := _button("take", Rules.words("b_take"), UiKit.Kind.PRIMARY)
	take.pressed.connect(func() -> void: offer_taken.emit(key))
	buttons.add_child(skip)
	buttons.add_child(take)
	_body.add_child(buttons)


## Nothing on offer on app `key`'s screen.
func show_none(key: String, title: Array, colour: Color) -> void:
	_app = key
	_search_id += 1
	_clear()
	_header(title, colour, true)
	var l := _label(Rules.words("none_" + key), "body")
	l.name = "none"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(l)


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
	_frame.position = area.position + (area.size - _frame.size) * 0.5


func _clear() -> void:
	_place()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()


## The status line: the title (or a BACK button on an app's screen), the clock, the close cross.
func _header(title: Array, colour: Color, back: bool) -> void:
	_head = HBoxContainer.new()
	_head.name = "status"
	_head.add_theme_constant_override("separation", UiKit.px(UiKit.GAP, pt))
	if back:
		var bk := _button("back", Rules.words("b_back"), UiKit.Kind.SECONDARY, 0.0)
		bk.pressed.connect(func() -> void: home_pressed.emit())
		_head.add_child(bk)
	var t := _label(title, "title")
	t.add_theme_color_override("font_color", colour)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_head.add_child(t)
	var clock := _label([_clock_text(), _clock_text()], "sub")
	clock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_head.add_child(clock)
	var x := Button.new()
	x.name = "close"
	x.text = "✕"
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2.ONE * UiKit.TOUCH * pt
	UiKit.style_button(x, UiKit.Kind.SECONDARY, pt, UiKit.T_TITLE)
	x.pressed.connect(close)
	_head.add_child(x)
	_body.add_child(_head)


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
	# The app's round "icon": its colour disc with the first letter.
	var disc := Label.new()
	disc.text = _pick(a["title"]).substr(0, 1)
	disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disc.custom_minimum_size = Vector2.ONE * 44.0 * pt
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_theme_font_size_override("font_size", UiKit.px(UiKit.T_TITLE, pt))
	disc.add_theme_color_override("font_color", UiKit.ON_GOLD if on else UiKit.FAINT)
	disc.add_theme_stylebox_override("normal", UiKit.box(col if on else UiKit.DIM, Color(0, 0, 0, 0), pt, 999.0, 0.0, 2.0))
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(disc)
	words.add_child(holder)
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
