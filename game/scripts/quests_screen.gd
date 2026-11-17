extends Control
## The QUESTS screen (F's ask 2026-11-17: "make the map minimalistic and a separate quests screen
## with a big QUESTS button on the map, tabs like questlines and side jobs, where the player taps
## and sees a description, a little picture, what is done and how many deliveries"; the plan
## https://claude.ai/artifact/EdLnFk5DtfTakCMq2JeRzn). The map answers "where", this screen answers
## "what, and how far along"; the one bridge between them is SHOW ON MAP.
##
## A child of the full map (full_map.gd `open_screen`), over it while it is up; the game stays paused
## under both. It draws what quest_book.gd `tabs` builds (main.gd gathers the facts, the full map
## hands them over): the tabs along the top (‹ MAP first), the NOW line while something runs (its
## QUIT, tapped twice), the tab's list on the left (each row its icon, name, one line and NEW or ✓)
## and the picked item's detail on the right (its icon, the friend's face, the words, the facts,
## its buttons). A button hands its entry back (`acted`); the full map decides what it does.
##
## Fingers: a tap picks a row or a tab, a drag scrolls the list, the detail or the tabs (a drag is
## never a tap: `_dragged`). The full map routes its touches and the pad here while the screen is
## up (`touch`, `pad`). Pad: LB / RB the tabs, the D-pad's up / down the rows, A the detail's first
## button, X its second, B back to the map.

signal acted(key: String, entry: Dictionary)
signal back
signal quit_quest
## An item marked NEW was looked at (its id): main.gd forgets the mark.
signal seen(id: String)

const QuestBook := preload("res://scripts/quest_book.gd")
const Lang := preload("res://scripts/lang.gd")
const Portraits := preload("res://scripts/portraits.gd")
const Access := preload("res://scripts/access.gd")
const Gamepad := preload("res://scripts/gamepad.gd")

## Sizes in points: a row, a tab, the list's share of the width (and its bounds), the icons.
const ROW_H := 54.0
const TAB_H := 44.0
const LIST_SHARE := 0.42
const LIST_MIN := 210.0
const LIST_MAX := 330.0
const ROW_ICON := 38.0
const BIG_ICON := 64.0
const FACE := 56.0
const T_TITLE := 17.0
const T_SUB := 13.0
const T_BIG := 20.0
const GOLD := Color("#ffd23f")
const INK := Color("#1a1622")
const CREAM := Color("#fbf7ee")
const MUTED := Color("#c9c2d8")
const NEW_RED := Color("#ff4f6d")
const QUIT_COLOUR := Color("#ff5a5a")
## A second tap on QUIT within this long quits.
const QUIT_ARM := 3.0
## A finger that moved further than this (pt) was a drag, not a tap.
const DRAG_PT := 8.0

var pt := 1.0
var safe := Rect2()
## What it shows: quest_book.gd `tabs`, the tab shown (its key) and the item picked in it (-1 none).
var tabs: Array = []
var tab := ""
var pick := -1
## What runs now (quest_lines.gd entry, {} none) and its name for QUIT ([pl, en], [] nothing to quit).
var now_entry: Dictionary = {}
var quit_what: Array = []

var _built := false
var _quit_armed := 0.0
var _bg: ColorRect
var _back: Button
var _tab_scroll: ScrollContainer
var _tab_row: HBoxContainer
var _now: PanelContainer
var _list_scroll: ScrollContainer
var _list: VBoxContainer
var _detail: PanelContainer
var _detail_scroll: ScrollContainer
var _detail_box: VBoxContainer
var _buttons: HBoxContainer
var _row_buttons: Array[Button] = []
var _tab_buttons: Array[Button] = []
var _detail_buttons: Array[Button] = []
## The drag under way: its touch index (-1 none), the scroll it moves, how far it went (px).
var _drag_idx := -1
var _drag_scroll: ScrollContainer
var _drag_px := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


func _build() -> void:
	_built = true
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.07, 0.06, 0.1, 0.97)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	var bw: Array = QuestBook.words("b_back")
	_back = _button(Lang.pick(str(bw[0]), str(bw[1])), false, MUTED)
	_back.name = "back"
	_back.pressed.connect(func() -> void:
		if not _dragged():
			back.emit())
	add_child(_back)
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.name = "tab_scroll"
	_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_tab_scroll)
	_tab_row = HBoxContainer.new()
	_tab_row.name = "tabs"
	_tab_row.add_theme_constant_override("separation", _px(6))
	_tab_scroll.add_child(_tab_row)
	_now = PanelContainer.new()
	_now.name = "now"
	_now.visible = false
	add_child(_now)
	_list_scroll = ScrollContainer.new()
	_list_scroll.name = "list_scroll"
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.name = "list"
	_list.add_theme_constant_override("separation", _px(4))
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list)
	_detail = PanelContainer.new()
	_detail.name = "detail"
	_detail.add_theme_stylebox_override("panel", _panel(Color(0.12, 0.11, 0.17, 0.96), GOLD))
	add_child(_detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", _px(8))
	_detail.add_child(dv)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.name = "detail_scroll"
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(_detail_scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.name = "detail_box"
	_detail_box.add_theme_constant_override("separation", _px(6))
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail_box)
	_buttons = HBoxContainer.new()
	_buttons.name = "buttons"
	_buttons.add_theme_constant_override("separation", _px(8))
	dv.add_child(_buttons)
	get_viewport().size_changed.connect(_fit)


## Shows the screen with these tabs (quest_book.gd `tabs`) on tab `on` ("" the first) and the item
## `item_id` picked ("" the tab's first).
func open(tabs_list: Array, on := "", item_id := "") -> void:
	if not _built:
		_build()
	visible = true
	_quit_armed = 0.0
	_drag_idx = -1
	_drag_px = 0.0
	show_book(tabs_list, on, item_id)


## New contents with the screen up (a pin set, a rebuild): the tab and the pick stay where they can.
func show_book(tabs_list: Array, on := "", item_id := "") -> void:
	tabs = tabs_list
	if item_id != "":
		var f := QuestBook.find(tabs, item_id)
		if str(f[0]) != "":
			on = str(f[0])
			pick = int(f[1])
	if on != "":
		if on != tab and item_id == "":
			pick = -1
		tab = on
	if _tab_of(tab).is_empty():
		tab = QuestBook.first_tab(tabs)
		pick = -1
	if not _built or not visible:
		return
	_fill()


func close() -> void:
	visible = false
	_drag_idx = -1


## The tab with key `key` ({} none).
func _tab_of(key: String) -> Dictionary:
	for t: Dictionary in tabs:
		if str(t["key"]) == key:
			return t
	return {}


## The items of the tab shown.
func items() -> Array:
	var t := _tab_of(tab)
	return t.get("items", []) if not t.is_empty() else []


## The item picked ({} none).
func picked() -> Dictionary:
	var it := items()
	return it[pick] if pick >= 0 and pick < it.size() else {}


func _fill() -> void:
	var keep := _list_scroll.scroll_vertical
	for c in _tab_row.get_children():
		_tab_row.remove_child(c)
		c.queue_free()
	_tab_buttons.clear()
	for t: Dictionary in tabs:
		var title := Lang.pick(str(t["title"][0]), str(t["title"][1]))
		if str(t["badge"]) != "":
			title += "  " + str(t["badge"])
		if int(t["new"]) > 0:
			title += "  •%d" % int(t["new"])
		var on := str(t["key"]) == tab
		var b := _button(title, on, NEW_RED if int(t["new"]) > 0 and not on else GOLD)
		b.name = "tab_" + str(t["key"])
		b.pressed.connect(_tab_tapped.bind(str(t["key"])))
		_tab_row.add_child(b)
		_tab_buttons.append(b)
	_fill_now()
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_row_buttons.clear()
	var t := _tab_of(tab)
	var head: Array = t.get("head", ["", ""])
	if str(head[1]) != "":
		var hl := _label(Lang.pick(str(head[0]), str(head[1])), T_SUB, MUTED)
		hl.name = "head"
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(hl)
	var list := items()
	if pick < 0 and not list.is_empty():
		pick = 0
	pick = mini(pick, list.size() - 1)
	for i in list.size():
		var r := _row(list[i], i == pick)
		r.name = "row_%d" % i
		r.pressed.connect(_row_tapped.bind(i))
		_list.add_child(r)
		_row_buttons.append(r)
	_fill_detail()
	_fit()
	_list_scroll.set_deferred("scroll_vertical", keep)
	if pick >= 0 and pick < _row_buttons.size():
		_show_later(_list_scroll, _row_buttons[pick])
	for b in _tab_buttons:
		if b.name == "tab_" + tab:
			_show_later(_tab_scroll, b)


## Scrolls `sc` to show `c` once the frame's layout is done, if `c` is still in it then (a second
## fill in the same frame, a pad press, frees the rows of the first).
func _show_later(sc: ScrollContainer, c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and sc.is_ancestor_of(c):
			sc.ensure_control_visible(c)).call_deferred()


## The NOW line: what runs, SHOW (the map looks at its target) and QUIT (tapped twice).
func _fill_now() -> void:
	for c in _now.get_children():
		_now.remove_child(c)
		c.queue_free()
	_now.visible = not now_entry.is_empty()
	if not _now.visible:
		return
	var col := Access.tint(now_entry.get("colour", GOLD))
	_now.add_theme_stylebox_override("panel", _panel(Color(0.12, 0.11, 0.17, 0.96), col))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", _px(8))
	_now.add_child(h)
	var name := _label(Lang.pick(str(now_entry["pl"]), str(now_entry["en"])), T_TITLE, CREAM)
	name.name = "now_name"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(name)
	if now_entry.get("at", Vector2.INF) != Vector2.INF:
		var mw: Array = QuestBook.words("b_map")
		var show := _button(Lang.pick(str(mw[0]), str(mw[1])), false, col)
		show.name = "now_map"
		show.pressed.connect(func() -> void:
			if not _dragged():
				acted.emit("now", now_entry))
		h.add_child(show)
	if not quit_what.is_empty():
		var armed := _quit_armed > 0.0
		var w: Array = QuestBook.words("quit_sure") if armed else QuestBook.words("quit")
		var q := _button(Lang.pick(str(w[0]), str(w[1])), armed, QUIT_COLOUR)
		q.name = "quit_quest"
		q.pressed.connect(_quit_tapped)
		h.add_child(q)


func _fill_detail() -> void:
	for c in _detail_box.get_children():
		_detail_box.remove_child(c)
		c.queue_free()
	for c in _buttons.get_children():
		_buttons.remove_child(c)
		c.queue_free()
	_detail_buttons.clear()
	var it := picked()
	if it.is_empty():
		var t := _tab_of(tab)
		var head: Array = t.get("head", QuestBook.words("empty")) if not t.is_empty() else QuestBook.words("empty")
		if str(head[1]) == "":
			head = QuestBook.words("empty")
		var none := _label(Lang.pick(str(head[0]), str(head[1])), T_TITLE, MUTED)
		none.name = "none"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_box.add_child(none)
		return
	if bool(it.get("new", false)):
		seen.emit(str(it["id"]))
	var col := Access.tint(it["colour"])
	var head := HBoxContainer.new()
	head.name = "detail_head"
	head.add_theme_constant_override("separation", _px(10))
	_detail_box.add_child(head)
	head.add_child(_icon(it, BIG_ICON))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", _px(2))
	head.add_child(tv)
	var title := _label(Lang.pick(str(it["title"][0]), str(it["title"][1])), T_BIG, CREAM)
	title.name = "title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(title)
	var sub := Lang.pick(str(it["sub"][0]), str(it["sub"][1]))
	if sub != "":
		var sl := _label(sub, T_SUB, col.lightened(0.3))
		sl.name = "sub"
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(sl)
	var who := str(it.get("who", ""))
	if who != "" and Portraits.has_face(who) and Portraits.face(who) != null:
		var face := Portraits.badge(FACE * pt)
		Portraits.set_badge(face, who, col)
		head.add_child(face)
	var about := Lang.pick(str(it["about"][0]), str(it["about"][1]))
	if about != "":
		var al := _label(about, T_SUB + 1.0, CREAM)
		al.name = "about"
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_box.add_child(al)
	var facts: Array = it.get("facts", [])
	if not facts.is_empty():
		var grid := GridContainer.new()
		grid.name = "facts"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", _px(12))
		grid.add_theme_constant_override("v_separation", _px(3))
		_detail_box.add_child(grid)
		for f: Array in facts:
			grid.add_child(_label(Lang.pick(str(f[0][0]), str(f[0][1])), T_SUB, MUTED))
			var v := _label(Lang.pick(str(f[1][0]), str(f[1][1])), T_SUB, CREAM)
			v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(v)
	for b: Dictionary in it.get("buttons", []):
		var w: Array = b["words"]
		var btn := _button(Lang.pick(str(w[0]), str(w[1])), bool(b.get("gold", false)), col if not bool(b.get("gold", false)) else GOLD)
		btn.name = "b_" + str(b["key"])
		btn.pressed.connect(_act.bind(b))
		_buttons.add_child(btn)
		_detail_buttons.append(btn)
	_buttons.visible = not _detail_buttons.is_empty()


## The screen's parts inside the safe area: the top row (‹ MAP and the tabs), the NOW line under it,
## then the list on the left and the detail on the right down to the safe area's bottom.
func _fit() -> void:
	if not _built or not visible:
		return
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var m := 8.0 * pt
	var top := s.position.y + m
	_back.size = Vector2(_back.get_combined_minimum_size().x, TAB_H * pt)
	_back.position = Vector2(s.position.x + m, top)
	var tabs_x := _back.position.x + _back.size.x + m
	_tab_scroll.position = Vector2(tabs_x, top)
	_tab_scroll.size = Vector2(maxf(0.0, s.end.x - m - tabs_x), TAB_H * pt + 2.0)
	var y := top + TAB_H * pt + m
	if _now.visible:
		_now.size = Vector2(s.size.x - 2.0 * m, 0.0)
		_now.reset_size()
		_now.size.x = s.size.x - 2.0 * m
		_now.position = Vector2(s.position.x + m, y)
		y += _now.size.y + m
	var lw := clampf(s.size.x * LIST_SHARE, LIST_MIN * pt, LIST_MAX * pt)
	var h := maxf(ROW_H * pt, s.end.y - m - y)
	_list_scroll.position = Vector2(s.position.x + m, y)
	_list_scroll.size = Vector2(lw, h)
	for c in _list.get_children():
		(c as Control).custom_minimum_size.x = lw - 2.0
	var dx := _list_scroll.position.x + lw + m
	_detail.position = Vector2(dx, y)
	_detail.size = Vector2(maxf(120.0 * pt, s.end.x - m - dx), h)
	var inner := _detail.size.x - 28.0 * pt
	for l: Label in [_detail_box.find_child("about", true, false), _detail_box.find_child("none", true, false)]:
		if l != null:
			l.custom_minimum_size.x = inner
	var title := _detail_box.find_child("title", true, false) as Label
	if title != null:
		title.custom_minimum_size.x = maxf(60.0 * pt, inner - (BIG_ICON + FACE + 24.0) * pt)
	var grid := _detail_box.find_child("facts", true, false) as GridContainer
	if grid != null:
		# The names' column as wide as its widest (wrapped at under half the detail), the values the rest.
		var kw := 0.0
		for i in range(0, grid.get_child_count(), 2):
			var k := grid.get_child(i) as Label
			k.autowrap_mode = TextServer.AUTOWRAP_OFF
			k.custom_minimum_size.x = 0.0
			kw = maxf(kw, k.get_combined_minimum_size().x)
		if kw > inner * 0.45:
			kw = inner * 0.45
			for i in range(0, grid.get_child_count(), 2):
				var k := grid.get_child(i) as Label
				k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				k.custom_minimum_size.x = kw
		for i in range(1, grid.get_child_count(), 2):
			(grid.get_child(i) as Control).custom_minimum_size.x = maxf(60.0 * pt, inner - kw - 16.0 * pt)
	var hl := _list.find_child("head", false, false) as Label
	if hl != null:
		hl.custom_minimum_size.x = lw - 2.0


## For checks: the screen's parts in pixels.
func rects() -> Dictionary:
	if not _built or not visible:
		return {}
	var out := {"back": _back.get_global_rect(), "tabs": _tab_scroll.get_global_rect(), "list": _list_scroll.get_global_rect(),
			"detail": _detail.get_global_rect()}
	if _now.visible:
		out["now"] = _now.get_global_rect()
	for b in _detail_buttons:
		out[str(b.name)] = b.get_global_rect()
	return out


func _process(dt: float) -> void:
	if not visible or _quit_armed <= 0.0:
		return
	_quit_armed -= dt
	if _quit_armed <= 0.0:
		_fill_now()  # not tapped again: QUIT asks no more
		_fit()


# --- taps ----------------------------------------------------------------------------------------

func _tab_tapped(key: String) -> void:
	if _dragged() or key == tab:
		return
	tab = key
	pick = -1
	print("quests: tab %s" % key)
	_fill()


func _row_tapped(i: int) -> void:
	if _dragged():
		return
	select(i)


## Picks item `i` of the tab shown (its detail on the right).
func select(i: int) -> void:
	var list := items()
	if list.is_empty():
		return
	pick = clampi(i, 0, list.size() - 1)
	print("quests: %s" % str(list[pick]["id"]))
	_fill()


func _act(b: Dictionary) -> void:
	if _dragged():
		return
	print("quests: %s on %s" % [str(b["key"]), str(picked().get("id", ""))])
	acted.emit(str(b["key"]), b["entry"])


func _quit_tapped() -> void:
	if _dragged():
		return
	if _quit_armed > 0.0:
		_quit_armed = 0.0
		print("quests: quit %s" % str(quit_what[1]))
		quit_quest.emit()
		return
	_quit_armed = QUIT_ARM
	_fill_now()
	_fit()


func _dragged() -> bool:
	return _drag_px > DRAG_PT * pt


## A touch from the full map while the screen is up: a drag on the list, the detail or the tabs
## scrolls it (the buttons under the finger get the tap themselves, unless it was a drag).
func touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_drag_px = 0.0
			_drag_idx = -1
			for sc: ScrollContainer in [_list_scroll, _detail_scroll, _tab_scroll]:
				if sc.is_visible_in_tree() and sc.get_global_rect().has_point(t.position):
					_drag_idx = t.index
					_drag_scroll = sc
					break
		elif t.index == _drag_idx:
			_drag_idx = -1
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != _drag_idx or _drag_scroll == null:
			return
		if _drag_scroll == _tab_scroll:
			_drag_px += absf(d.relative.x)
			_drag_scroll.scroll_horizontal -= int(d.relative.x)
		else:
			_drag_px += absf(d.relative.y)
			_drag_scroll.scroll_vertical -= int(d.relative.y)


## A pad button while the screen is up; true when it was used.
func pad(button: int) -> bool:
	match button:
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			var i := 0
			for k in tabs.size():
				if str(tabs[k]["key"]) == tab:
					i = k
			i = wrapi(i + (1 if button == JOY_BUTTON_RIGHT_SHOULDER else -1), 0, maxi(1, tabs.size()))
			if not tabs.is_empty():
				tab = str(tabs[i]["key"])
				pick = -1
				_fill()
		JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP:
			if not items().is_empty():
				select(wrapi(pick + (1 if button == JOY_BUTTON_DPAD_DOWN else -1), 0, items().size()))
		JOY_BUTTON_A, JOY_BUTTON_X:
			var n := 0 if button == JOY_BUTTON_A else 1
			var bs: Array = picked().get("buttons", [])
			if n < bs.size():
				_drag_px = 0.0
				_act(bs[n])
		_:
			return false
	return true


# --- the parts -----------------------------------------------------------------------------------

func _panel(bg: Color, rim: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(_px(10))
	sb.set_content_margin_all(12.0 * pt)
	sb.border_color = rim
	sb.border_width_left = _px(4)
	return sb


func _label(text: String, size: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", _px(size))
	l.add_theme_color_override("font_color", colour)
	return l


## A button TAB_H tall: gold and filled (`strong`), or dark with `rim` round it.
func _button(text: String, strong: bool, rim: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(TAB_H, TAB_H) * pt
	b.add_theme_font_size_override("font_size", _px(T_SUB + 1.0))
	var c := Access.tint(rim)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, INK if strong else CREAM)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = (c.darkened(0.2) if st == "pressed" else c) if strong else (c.darkened(0.6) if st == "pressed" else Color(0.12, 0.11, 0.17, 0.95))
		sb.set_corner_radius_all(_px(8))
		sb.border_color = c
		sb.set_border_width_all(_px(2))
		sb.content_margin_left = 12.0 * pt
		sb.content_margin_right = 12.0 * pt
		b.add_theme_stylebox_override(st, sb)
	return b


## One row: the icon, the name over its line, NEW or ✓ on the right; the picked one lit.
func _row(it: Dictionary, on: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(LIST_MIN, ROW_H) * pt
	b.clip_contents = true
	var col := Access.tint(it["colour"])
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.darkened(0.62) if on or st == "pressed" else Color(0.12, 0.11, 0.17, 0.92)
		sb.set_corner_radius_all(_px(8))
		sb.border_color = col if on else col.darkened(0.3)
		sb.border_width_left = _px(5)
		if on:
			sb.set_border_width_all(_px(2))
			sb.border_width_left = _px(5)
		b.add_theme_stylebox_override(st, sb)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10.0 * pt
	h.offset_right = -8.0 * pt
	h.add_theme_constant_override("separation", _px(8))
	b.add_child(h)
	var ic := _icon(it, ROW_ICON)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var done := bool(it.get("done", false))
	var name := _label(Lang.pick(str(it["title"][0]), str(it["title"][1])), T_SUB + 2.0, MUTED if done else CREAM)
	name.clip_text = true
	v.add_child(name)
	var sub := Lang.pick(str(it["sub"][0]), str(it["sub"][1]))
	if sub != "":
		var sl := _label(sub, T_SUB, MUTED)
		sl.clip_text = true
		v.add_child(sl)
	if bool(it.get("new", false)):
		var nw: Array = QuestBook.words("new")
		var tag := _label(Lang.pick(str(nw[0]), str(nw[1])), T_SUB, NEW_RED)
		tag.name = "new"
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tag)
	elif done:
		var tick := _label("✓", T_TITLE, GOLD)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tick)
	if done:
		b.modulate = Color(1, 1, 1, 0.75)
	return b


## An item's icon `size` pt square: its picture (quest_book.gd `icon`) in a rounded frame of its
## colour, or, without one, a disc of its colour with the name's first letter.
func _icon(it: Dictionary, size: float) -> Control:
	return icon_tile(str(it.get("icon", "")), it["colour"], Lang.pick(str(it["title"][0]), str(it["title"][1])), size * pt)


## An item's icon as the screen draws it, `px` pixels square: a rounded light frame in `colour`
## with the picture (QuestBook `icon`), or the colour's disc with `name`'s first letter when the
## picture is missing. Static: the beta card's tiles use the same look (first10.gd).
static func icon_tile(key: String, colour: Color, name: String, px: float) -> Control:
	var c := Control.new()
	c.name = "icon"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size = Vector2.ONE * px
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex := QuestBook.icon(key)
	var col := Access.tint(colour)
	var letter := Portraits.initial(name)
	c.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, c.size)
		var sb := StyleBoxFlat.new()
		sb.bg_color = INK
		sb.set_corner_radius_all(roundi(c.size.x * 0.22))
		sb.border_color = col
		sb.set_border_width_all(maxi(1, roundi(c.size.x / 22.0)))
		c.draw_style_box(sb, r)
		if tex != null:
			var inset := c.size.x * 0.08
			c.draw_texture_rect(tex, r.grow(-inset), false)
		else:
			Portraits.paint(c, c.size * 0.5, c.size.x * 0.34, null, letter, col, 1.0))
	return c
