extends Control
## The garage loop (2026-10-31): the paint card at Warsztat u Mirka (garage.gd). The game pauses
## under it (main.gd, like the settings card), so it runs with PROCESS_MODE_ALWAYS. In the HUD's
## card recipe (hud.gd `_panel_box`, `_chip`, the type scale): the title and the wallet, Mirek's
## line, the paints as swatches in two rows of five (each 44 pt or more: the colour, its Polish
## name, the price or "masz" / "na aucie"), then the action for the swatch picked (buy, switch,
## or why not) and WYJAZD · Drive off. Polish over English throughout. Built at the first open.
## G1 (F 2026-11-23, docs/design/garage-and-cars.md 0b, the night-garage look): the card is the
## right-hand panel of the car screen; the left is the car itself on a turntable in a night box
## (car_stage.gd), wearing the paint or the car picked. The head shows the car's class (ladder.gd
## car_class: a neon letter, "C → B" when the item picked would lift it) and four stat bars
## (top speed, pull, grip, nitro: now in white, what a buy adds in cyan).
## G13: two tabs in the header, LAKIER (the paints) and CZĘŚCI I AUTA (the Ołdi TT, the nitro, tyres
## and engine: upgrades.gd, six cells in two columns), with a stat card (top speed, pull, grip now
## -> after buying the item picked) in place of the paints; the same action button buys it.
## F 2026-11-24: MOJE AUTO (mode "mine", from the full map) is the player's own garage: only what is
## owned shows (the cars bought and the paints owned, `mine_shows`), and nothing is sold there; the
## parts, the nitro and the cars not yet bought are at Mirek's on Grzybowska.
## F 2026-11-24 ("redo the workshop's interface by our design system, stylish, everything reads
## well and it is clear what to press"): four tabs, AUTA (the cars), TUNING (engine, tyres, nitro),
## LAKIER (the paints) and STYL (the GT wing and the underglow: upgrades.gd LOOKS), the chosen tab
## SELECTED; every item a kit tile (RAISED, the one picked SELECTED, the one on the car a green
## edge) with its short name whole, the part's level as pips and its state (the price, MASZ, NA
## AUCIE) on its own line; Mirek's line in a box with the brand's pink rail; the action the card's
## one gold PRIMARY while it can be pressed (a plain grey one when it can't: on the car, short of
## money), WYJAZD a SECONDARY. MOJE AUTO shows AUTA, LAKIER and STYL (what you own).

const Lang := preload("res://scripts/lang.gd")
const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)

signal closed

const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad follow-ups
const CarStage := preload("res://scripts/car_stage.gd")  # G1: the car in the night box
const Ladder := preload("res://scripts/ladder.gd")  # R1: the car's class
const Upgrades := preload("res://scripts/upgrades.gd")  # the shop's rows and rules

## The swatches' size in points (at least 44 tall: the touch rule); G1: the width follows the panel's.
const SWATCH := Vector2(114.0, 58.0)
## G1: the panel's share of the safe area's width, its least and most width (pt), and the gap to the stage.
const SWATCH_G1_H := 48.0
const PANEL_SHARE := 0.46
const PANEL_MIN := 330.0
const PANEL_MAX := 470.0
const STAGE_GAP := 10.0
## G1: the class letters' colours (D .. S) on the badge.
const CLASS_COLOURS := [UiKit.SUB, UiKit.GO, UiKit.NEON_CYAN, UiKit.NEON_PINK, UiKit.GOLD]
const GAP := 6.0
## The tabs: id, words [pl, en], the shop ids on it (the paints on "paint"), tiles across.
const TABS := [
	{"id": "cars", "words": ["AUTA", "CARS"], "across": 5, "tile_h": 50.0},
	{"id": "tune", "words": ["TUNING", "TUNING"], "across": 3},
	{"id": "paint", "words": ["LAKIER", "PAINT"], "across": 5},
	{"id": "style", "words": ["STYL", "STYLE"], "across": 2},
]
## A tile's height (pt) and the pips of a part's level.
const TILE_H := 58.0
const PIP_ON := "●"
const PIP_OFF := "○"
## Swatches per row (loop 3h slice 2: ten paints in two rows of five).
const COLUMNS := 5

## garage.gd (the rules, the paints, Mirek's lines).
var garage: Node
## Pixels per point and the safe area (hud.gd's).
var pt := 1.0
var safe := Rect2()
## The swatch picked (a paint id).
var picked := ""
## The tab shown (TABS id) and the shop item picked on the other tabs (upgrades.gd id).
var tab := "paint"
var picked_item := "tt"

var _built := false
## G1: the car in the night box, the class badge and the stat bars; the panel's inner width (pt).
var stage: SubViewportContainer
var _badge: Label
var _bars: Control
var _inner := 520.0
## The dim over the HUD and the city behind the card (drawn by this Control, `_draw`).
const DIM := UiKit.SCRIM
var _card: PanelContainer
var _title: Label
var _title_en: Label
var _money: Label
var _line: Label
var _line_en: Label
var _grid: GridContainer
var _swatches := {}
var _items := {}
## Each tab's button and its page (the grid of its tiles), by TABS id.
var _tab_buttons := {}
var _pages := {}
var _action: Button
var _leave: Button
## True while the action can be pressed (it is then the gold PRIMARY).
var _action_live := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _hud() -> CanvasLayer:
	return garage.hud


func _build() -> void:
	_built = true
	var hud := _hud()
	var vw := (safe.size.x if safe.has_area() else get_viewport_rect().size.x) / pt
	_inner = clampf(vw * PANEL_SHARE, PANEL_MIN, PANEL_MAX) - 24.0
	stage = CarStage.new()
	stage.name = "stage"
	add_child(stage)
	_card = PanelContainer.new()
	_card.name = "card"
	_card.add_theme_stylebox_override("panel", UiKit.card(pt))
	_card.custom_minimum_size.x = (_inner + 24.0) * pt
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi(GAP * pt))
	_card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	col.add_child(head)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	_title = hud._label(hud.T_TITLE, UiKit.GOLD)  # card titles are gold capitals (the kit)
	_title.text = str(garage.NAME[0]).to_upper()
	names.add_child(_title)
	_title_en = hud._label(hud.T_LABEL, hud.SUB)
	_title_en.text = "%s, %s" % [garage.STREET, garage.DISTRICT]
	names.add_child(_title_en)
	_title_en.visible = false  # G1: the stage's back wall says where; the panel keeps its height
	_badge = hud._label(hud.T_TITLE, CLASS_COLOURS[0])
	_badge.name = "class"
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_badge)
	_money = hud._label(hud.T_BODY, UiKit.GOLD)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_money)
	_bars = StatBars.new()
	_bars.name = "bars"
	_bars.pt = pt
	_bars.names = [garage.line("bar_top"), garage.line("bar_pull"), garage.line("bar_grip"), garage.line("bar_nitro")]
	_bars.custom_minimum_size = Vector2(_inner, StatBars.ROW * 2.0) * pt
	col.add_child(_bars)
	# The tabs: kit buttons, the one shown SELECTED.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", roundi(GAP * 0.75 * pt))
	col.add_child(tabs)
	for t: Dictionary in TABS:
		var id := str(t["id"])
		var b := Button.new()
		b.name = "tab_" + id
		b.focus_mode = Control.FOCUS_NONE
		b.text = Lang.pick(str(t["words"][0]), str(t["words"][1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, UiKit.TOUCH) * pt
		UiKit.style_button(b, UiKit.Kind.SECONDARY, pt, UiKit.T_SUB)
		b.pressed.connect(func() -> void: show_tab(id))
		tabs.add_child(b)
		_tab_buttons[id] = b
	# Mirek's line: a raised box with the brand's pink rail on its left.
	var say := PanelContainer.new()
	say.name = "mirek"
	var say_box := UiKit.box(UiKit.RAISED, UiKit.NEON_PINK, pt, UiKit.R_SMALL, 0.0, 6.0)
	say_box.set_border_width_all(0)
	say_box.border_width_left = UiKit.px(3.0, pt)
	say_box.content_margin_left = 10.0 * pt
	say.add_theme_stylebox_override("panel", say_box)
	col.add_child(say)
	var width := _inner
	var say_col := VBoxContainer.new()
	say_col.add_theme_constant_override("separation", 0)
	say.add_child(say_col)
	_line = hud._label(hud.T_SUB, hud.INK)
	hud._wrap(_line, width - 16.0)
	_line.max_lines_visible = 2  # the panel is narrow; Mirek keeps it to two lines
	_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	say_col.add_child(_line)
	_line_en = hud._label(hud.T_LABEL, hud.SUB)
	hud._wrap(_line_en, width - 16.0)
	say_col.add_child(_line_en)
	# The pages: one grid of tiles a tab.
	for t: Dictionary in TABS:
		var g := GridContainer.new()
		g.name = "page_" + str(t["id"])
		g.columns = int(t["across"])
		g.add_theme_constant_override("h_separation", roundi(GAP * 0.75 * pt))
		g.add_theme_constant_override("v_separation", roundi(GAP * 0.75 * pt))
		col.add_child(g)
		_pages[str(t["id"])] = g
	_grid = _pages["paint"]
	for p: Dictionary in garage.PAINTS:
		_swatches[str(p["id"])] = _swatch(p)
	for id: String in Upgrades.ORDER:
		_items[id] = _item(id, width)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(GAP * pt))
	col.add_child(row)
	_action = hud._chip(row, "", "")
	_action.name = "action"
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action.pressed.connect(_on_action)
	_leave = hud._chip(row, "WYJAZD", "Drive off")
	_leave.name = "leave"
	_leave.pressed.connect(func() -> void: closed.emit())
	_chip_kind(_leave, UiKit.Kind.SECONDARY)


## A tile's look: picked (SELECTED), on the car (a green edge), or plain (RAISED). The focus box is
## left alone (the gamepad's ring).
func _tile_style(b: Button, chosen: bool, worn: bool) -> void:
	var boxes := UiKit.button_boxes(UiKit.Kind.SELECTED if chosen else UiKit.Kind.SECONDARY, pt, UiKit.R_SMALL)
	if worn and not chosen:
		for st in ["normal", "hover", "disabled"]:
			var bx := (boxes[st] as StyleBoxFlat).duplicate() as StyleBoxFlat
			bx.border_color = UiKit.GO
			bx.set_border_width_all(UiKit.px(1.0, pt))
			boxes[st] = bx
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, boxes[st])


## A two-line chip (hud.gd `_chip`) dressed as a kit button of `kind`: its boxes and its words' colour.
func _chip_kind(b: Button, kind: int) -> void:
	var boxes := UiKit.button_boxes(kind, pt)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, boxes[st])
	var ink := UiKit.button_ink(kind)
	for l in b.get_child(0).get_children():
		(l as Label).add_theme_color_override("font_color", ink)
		(l as Label).add_theme_constant_override("outline_size", 0)


## One paint's tile: its colour (with the stripe), the name, the price or the state.
func _swatch(p: Dictionary) -> Button:
	var hud := _hud()
	var b := Button.new()
	b.name = "paint_%s" % p["id"]
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(maxf(44.0, (_inner - GAP * 0.75 * (COLUMNS - 1)) / COLUMNS), SWATCH_G1_H) * pt
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 4.0 * pt
	box.offset_right = -4.0 * pt
	box.offset_top = 4.0 * pt
	box.add_theme_constant_override("separation", roundi(2.0 * pt))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var chip := ColorRect.new()
	chip.color = p["paint"]
	chip.custom_minimum_size = Vector2(0.0, 9.0 * pt)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(chip)
	var stripe := ColorRect.new()
	stripe.color = p["stripe"]
	stripe.custom_minimum_size = Vector2(0.0, 2.0 * pt)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stripe)
	var name_l: Label = hud._label(hud.T_LABEL, hud.INK)
	name_l.text = Lang.pick(str(p["name"][0]), str(p["name"][1]))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_l)
	var price: Label = hud._label(hud.T_LABEL, hud.SUB)
	price.name = "price"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.clip_text = true
	box.add_child(price)
	b.pressed.connect(func() -> void: pick(str(p["id"])))
	_grid.add_child(b)
	return b


## The TABS id that holds shop item `id`.
static func tab_of(id: String) -> String:
	for t: String in ["cars", "tune", "style"]:
		if id in (Upgrades.TABS[t] as Array):
			return t
	return "paint"


## One shop tile (a car, the nitro, a part or a look): its short name whole, the part's level as
## pips, its state or price.
func _item(id: String, width: float) -> Button:
	var hud := _hud()
	var t := tab_of(id)
	var across := 2
	var tile_h := TILE_H
	for td: Dictionary in TABS:
		if str(td["id"]) == t:
			across = int(td["across"])
			# AUTA holds seven cars in two rows of four (C1a), a little lower than one row of two.
			tile_h = float(td.get("tile_h", TILE_H))
	var b := Button.new()
	b.name = "item_%s" % id
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2((width - GAP * 0.75 * (across - 1)) / across, tile_h) * pt
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", roundi(1.0 * pt))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var name_l: Label = hud._label(hud.T_SUB, hud.INK)
	name_l.name = "name"
	name_l.text = short_name(id)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_l)
	var pips: Label = hud._label(hud.T_LABEL, UiKit.NEON_CYAN)
	pips.name = "pips"
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pips.visible = Upgrades.kind(id) == "part"
	box.add_child(pips)
	var state: Label = hud._label(hud.T_LABEL, hud.SUB)
	state.name = "price"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(state)
	b.pressed.connect(func() -> void: pick_item(id))
	(_pages[t] as GridContainer).add_child(b)
	return b


## A tile's name in the game's language: the short one when the row has it (upgrades.gd "short").
static func short_name(id: String) -> String:
	var row: Dictionary = Upgrades.find(id)
	var n: Array = row.get("short", row["name"])
	return Lang.pick(str(n[0]), str(n[1]))


## The tab shown (a TABS id; the old "parts" is TUNING, or AUTA in MOJE AUTO).
func show_tab(t: String) -> void:
	if t == "parts":
		t = "cars" if garage.mode == "mine" else "tune"
	if not _pages.has(t):
		t = "paint"
	if garage.mode == "mine" and t == "tune":
		t = "cars"
	tab = t
	if t != "paint" and tab_of(picked_item) != t:
		picked_item = _first_on(t)
	_say({"paint": "hello", "cars": "cars", "tune": "parts", "style": "style"}[t] if garage.mode != "mine" else "mine")
	_refresh()


## The first tile shown on tab `t` (the car on the road on AUTA).
func _first_on(t: String) -> String:
	if t == "cars":
		return str(garage.shop_state()["car"])
	for id: String in (Upgrades.TABS[t] as Array):
		if garage.mode != "mine" or mine_shows(Upgrades.kind(id), garage.item_rule_now(id)):
			return id
	return (Upgrades.TABS[t] as Array)[0]


## A shop tile tapped: its tab shows, it is picked, and Mirek says what it is (its blurb) or why not.
func pick_item(id: String) -> void:
	picked_item = id
	tab = tab_of(id)
	if stage != null:
		stage.focus("engine" if id == "engine" else ("tyres" if id == "tyres" else ("nitro" if id == "nitro" else "")))
	if Upgrades.kind(id) == "look":
		_say(id)
	elif garage.item_rule_now(id) == "locked":
		_say(id + "_locked")
	else:
		var row: Dictionary = Upgrades.find(id)
		_line.text = Lang.pick(str((row["blurb"] as Array)[0]), str((row["blurb"] as Array)[1]))
	_refresh()


## Opens on `start_tab` ("paint", "parts" or a TABS id), on the paint the car wears, with Mirek's hello.
func open(start_tab := "paint", mode := "garage") -> void:
	if not _built:
		_build()
	stage.set_mode(mode)
	(_tab_buttons["tune"] as Button).visible = mode != "mine"
	_title.text = Lang.pick("MOJE AUTO", "MY CAR") if mode == "mine" else str(garage.NAME[0]).to_upper()
	picked = garage.current()
	if mode == "mine" and not mine_shows(Upgrades.kind(picked_item), garage.item_rule_now(picked_item)):
		picked_item = str(garage.shop_state()["car"])
	show_tab(start_tab)
	visible = true
	_place.call_deferred()
	_place()
	if Gamepad.in_use():
		# The gamepad follow-ups: the tiles, tabs and chips take focus, on the paint worn.
		Gamepad.focus_all(_card, pt)
		if tab == "paint":
			(_swatches.get(picked, _leave) as Button).grab_focus()
		else:
			_leave.grab_focus()
	else:
		Gamepad.focus_none(_card)


func close() -> void:
	Gamepad.drop_focus(self)
	visible = false
	if stage != null:
		stage.visible = false


func is_open() -> bool:
	return visible


## A swatch tapped: LAKIER shows, it is picked; a paint you can't have yet gets Mirek's reason.
func pick(id: String) -> void:
	picked = id
	tab = "paint"
	match garage.rule_now(id):
		"short":
			_say("short")
		"locked":
			_say("locked")
	_refresh()


## The action button: buy or switch to the paint or the item picked.
func _on_action() -> void:
	if tab != "paint":
		var r: String = garage.choose_item(picked_item)
		if r == "buy":
			var maxed: bool = Upgrades.kind(picked_item) == "part" \
					and Upgrades.level(garage.wallet.tune, picked_item) >= Upgrades.MAX_LEVEL
			if Upgrades.kind(picked_item) == "look":
				_say(picked_item + "_buy")
			else:
				_say(picked_item if picked_item == "nitro" or Upgrades.kind(picked_item) == "car" else ("max" if maxed else "part"))
		elif r == "switch":
			_say("switch")
		_refresh()
		return
	var first: bool = not garage.wallet.paints.has(picked)
	var r: String = garage.choose(picked)
	if r == "buy":
		_say(picked if picked in ["black", "green"] else "buy")
	elif r == "switch":
		# The gold paint, opened by the eggs, the first time: its own line.
		_say("gold" if picked == "gold" and first else "switch")
	_refresh()


func _say(tag: String) -> void:
	var l: Array = garage.line(tag)
	if str(l[0]) == "" and tag in ["black", "green"]:
		l = garage.line("buy")
	_line.text = Lang.pick(str(l[0]), str(l[1]))
	_line_en.text = ""
	_line_en.visible = false


## The action's words and whether it can be pressed: live, it is the card's gold PRIMARY; not, a
## grey SECONDARY (the words still say why).
func _set_action(pl: String, en: String, live: bool) -> void:
	_hud()._set_chip(_action, pl, en)
	_action.disabled = not live
	_action_live = live
	_chip_kind(_action, UiKit.Kind.PRIMARY if live else UiKit.Kind.SECONDARY)
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(_action.get_parent() as Container).queue_sort()  # the row lays the new width out at once


func _refresh() -> void:
	var w: Node = garage.wallet
	_money.text = w.money(int(w.zl)) if w != null else ""
	for id: String in _pages:
		(_pages[id] as Control).visible = id == tab
	for id: String in _tab_buttons:
		UiKit.style_button(_tab_buttons[id], UiKit.Kind.SELECTED if id == tab else UiKit.Kind.SECONDARY, pt, UiKit.T_SUB,
				UiKit.R_CARD, Gamepad.in_use())
	_refresh_look()
	if tab != "paint":
		_refresh_parts()
		_place()
		return
	var cur: String = garage.current()
	for id: String in _swatches:
		var b: Button = _swatches[id]
		var r: String = garage.rule_now(id)
		var p: Dictionary = garage.find(id)
		var price := b.find_child("price", true, false) as Label
		var ink: Color = UiKit.SUB
		match r:
			"on":
				price.text = Lang.pick("na aucie", "on the car")
				ink = UiKit.GO
			"switch":
				price.text = Lang.pick("masz", "yours") if not (p.has("eggs") or p.has("syrenki")) or w.paints.has(id) else Lang.pick("gratis", "free")
				ink = UiKit.GO
			"locked":
				if p.has("syrenki"):
					price.text = Lang.pick("%d/%d Syrenek", "%d/%d Mermaids") % [garage.syrenki_now(), int(p["syrenki"])]
				else:
					price.text = Lang.pick("%d/%d sekretów", "%d/%d easter eggs") % [garage.eggs_now(), int(p["eggs"])]
				ink = UiKit.FAINT
			"short":
				price.text = w.money(int(p["price"]))
				ink = UiKit.FAINT
			_:
				price.text = w.money(int(p["price"]))
				ink = UiKit.INK
		price.add_theme_color_override("font_color", ink)
		b.visible = garage.mode != "mine" or mine_shows("paint", r)
		_tile_style(b, id == picked, id == cur)
	var p2: Dictionary = garage.find(picked)
	var name_pl := str(p2["name"][0]) if not p2.is_empty() else ""
	var name_en := str(p2["name"][1]) if not p2.is_empty() else ""
	match garage.rule_now(picked):
		"on":
			_set_action("NA AUCIE: %s" % name_pl.to_upper(), "%s is on the car" % name_en, false)
		"switch":
			_set_action("LAKIERUJ: %s" % name_pl.to_upper(), "Paint it %s, free" % name_en.to_lower(), true)
		"buy":
			_set_action("KUP ZA %s" % w.money(int(p2["price"])).to_upper(), "Buy %s" % name_en.to_lower(), true)
		"short":
			var miss := int(p2["price"]) - int(w.zl)
			_set_action("BRAKUJE %s" % w.money(miss).to_upper(), "%s short" % _money_en(miss), false)
		"locked":
			if p2.has("syrenki"):
				_set_action("ZA %d SYRENEK" % int(p2["syrenki"]), "Find %d Mermaids" % int(p2["syrenki"]), false)
			else:
				_set_action("ZA %d SEKRETÓW" % int(p2["eggs"]), "Find %d easter eggs" % int(p2["eggs"]), false)
	_mine_gate(garage.rule_now(picked))
	_place()


## F 2026-11-24: what MOJE AUTO shows: a car bought, a paint owned (on the car now, or one to
## switch to for free) or a look owned; `kind` is upgrades.gd's ("car", "nitro", "part", "look")
## or "paint".
static func mine_shows(kind: String, rule: String) -> bool:
	return (kind in ["car", "paint"] and rule in ["on", "switch"]) or (kind == "look" and rule == "owned")


## G2: from the full map (MOJE AUTO) the shop's buys wait for the workshop: the action says where
## (only reached by a paint picked before the card filtered them, kept as the guard).
func _mine_gate(rule: String) -> void:
	if garage.mode == "mine" and rule in ["buy", "short"]:
		_set_action("KUP U MIRKA · GRZYBOWSKA", "Buy it at Mirek's on Grzybowska", false)


## G1: the stage wears the paint picked (or the car picked on AUTA) and the looks owned (and the
## look picked on STYL, tried on), and the badge and bars show the car's numbers now and after the
## item picked.
func _refresh_look() -> void:
	var st: Dictionary = garage.shop_state()
	var now: Dictionary = Upgrades.stats(str(st["car"]), st["tune"], bool(st["nitro"]))
	var after := now
	var car_id := str(st["car"])
	if tab != "paint" and garage.item_rule_now(picked_item) in ["buy", "short", "switch"]:
		after = Upgrades.stats_after(picked_item, st)
		if Upgrades.kind(picked_item) == "car":
			car_id = picked_item
	var p: Dictionary = garage.find(picked if tab == "paint" else garage.current())
	if p.is_empty():
		p = garage.find(garage.current())
	var tune: Dictionary = st["tune"]
	var wing: bool = Upgrades.has_look(tune, "wing") or (tab == "style" and picked_item == "wing")
	var neon: bool = Upgrades.has_look(tune, "neon") or (tab == "style" and picked_item == "neon")
	if stage != null and not p.is_empty():
		stage.set_car(str(CarStage.Models.PLAYER_BODIES.get(car_id, "player")), p["paint"], p["stripe"], wing, neon)
		stage.visible = visible
	var c0 := Ladder.car_class(float(now["top_mult"]), float(now["pull"]))
	var c1 := Ladder.car_class(float(after["top_mult"]), float(after["pull"]))
	_badge.text = (Lang.pick("KL. %s", "CL. %s") % Ladder.CLASS_NAMES[c0]) + ("" if c1 == c0 else " → %s" % Ladder.CLASS_NAMES[c1])
	_badge.add_theme_color_override("font_color", CLASS_COLOURS[c1])
	(_bars as StatBars).show_stats(now, after)


## The shop tabs (AUTA, TUNING, STYL): each tile's state, the action for the tile picked.
func _refresh_parts() -> void:
	var w: Node = garage.wallet
	var st: Dictionary = garage.shop_state()
	for id: String in _items:
		var b: Button = _items[id]
		var r: String = garage.item_rule_now(id)
		var price := b.find_child("price", true, false) as Label
		var pips := b.find_child("pips", true, false) as Label
		var ink: Color = UiKit.INK
		match r:
			"on":
				price.text = Lang.pick("na aucie", "on the car")
				ink = UiKit.GO
			"switch":
				price.text = Lang.pick("masz · gratis", "yours · free")
				ink = UiKit.GO
			"owned":
				price.text = Lang.pick("masz", "yours")
				ink = UiKit.GO
			"max":
				price.text = Lang.pick("max", "maxed")
				ink = UiKit.GO
			"short":
				price.text = w.money(Upgrades.price(id, st["tune"]))
				ink = UiKit.FAINT
			"locked":
				var need := int(Upgrades.car(id).get("respect", 0))
				if need > 0:
					price.text = Lang.pick("%d szac.", "%d resp.") % need
				else:
					price.text = Lang.pick("za drag", "win the drag")
				ink = UiKit.FAINT
			_:
				price.text = w.money(Upgrades.price(id, st["tune"]))
		price.add_theme_color_override("font_color", ink)
		if Upgrades.kind(id) == "part":
			var lv := Upgrades.level(st["tune"], id)
			pips.text = PIP_ON.repeat(lv) + PIP_OFF.repeat(Upgrades.MAX_LEVEL - lv)
		b.visible = garage.mode != "mine" or mine_shows(Upgrades.kind(id), r)
		_tile_style(b, id == picked_item, r in ["on", "owned", "max"])
	var rule: String = garage.item_rule_now(picked_item)
	var row2: Dictionary = Upgrades.find(picked_item)
	var name_pl := short_name(picked_item) if Lang.code != Lang.EN else str(row2["name"][0])
	var name_en := str(row2["name"][1])
	match rule:
		"on":
			_set_action("NA AUCIE", "%s is on the road" % name_en, false)
		"owned":
			if Upgrades.kind(picked_item) == "look":
				_set_action("NA AUCIE", "%s is on the car" % name_en, false)
			else:
				_set_action("MASZ: NITRO", "Owned: the button is by the horn", false)
		"max":
			_set_action("POZIOM MAX", "%s is maxed" % name_en.to_lower(), false)
		"switch":
			_set_action("JEDŹ: %s" % name_pl.to_upper(), "Drive the %s, free" % name_en, true)
		"buy":
			var lv := Upgrades.level(st["tune"], picked_item)
			var what := (" · POZ. %d" % (lv + 1)) if Upgrades.kind(picked_item) == "part" else ""
			_set_action("KUP ZA %s%s" % [w.money(Upgrades.price(picked_item, st["tune"])).to_upper(), what], "Buy: %s" % name_en, true)
		"locked":
			var need := int(Upgrades.car(picked_item).get("respect", 0))
			if need > 0:
				# The top cars (F 2026-11-27: "they unlock with respect, not at once").
				_set_action("ZA %d SZACUNKU" % need, "Earn %d respect" % need, false)
			else:
				# The Bawarka before the night meet's drag: gold gives it, a loss opens it here.
				_set_action("WYGRAJ DRAG · NOCNY SPOT", "Race the drag at the night meet", false)
		_:
			var miss: int = Upgrades.price(picked_item, st["tune"]) - int(w.zl)
			_set_action("BRAKUJE %s" % w.money(miss).to_upper(), "%s short" % _money_en(miss), false)
	_mine_gate(rule)


## The stat card's line: top speed, pull and grip now (and after the item picked, when it changes them).
## One line, in the game's language (`en`); the key to it is the line under it (`_stats_en`).
static func _stat_line(now: Dictionary, after: Dictionary, en := false) -> String:
	var parts: Array[String] = []
	var labels := ["", "pull ", "grip "] if en else ["", "przysp. ", "przyczep. "]
	var keys := ["top_kmh", "pull", "grip"]
	for i in 3:
		var a: float = float(now[keys[i]])
		var b: float = float(after[keys[i]])
		var unit := " km/h" if i == 0 else ""
		var fmt := "%d" if i == 0 else "%.2f"
		var txt: String = labels[i] + (fmt % a)
		if not is_equal_approx(a, b):
			txt += " → " + (fmt % b)
		parts.append(txt + unit)
	parts.append("nitro %s" % (("yes" if en else "tak") if bool(after["nitro"]) else ("no" if en else "nie")))
	return " · ".join(parts)


static func _money_en(amount: int) -> String:
	var s := str(amount)
	if amount >= 1000:
		s = "%d,%03d" % [amount / 1000, amount % 1000]
	return s + " zł"


## The card in the middle of the safe area at its natural size.
func _place() -> void:
	if _card == null:
		return
	# This Control covers the screen (sized by hand: top-left anchors), dims it in `_draw` and
	# takes the touches that would reach the HUD under it.
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()
	_card.reset_size()
	var s := _card.get_combined_minimum_size()
	_card.size = s
	var r := safe if safe.has_area() else get_viewport_rect()
	# G1: the panel on the right, the car on the left in the rest of the safe area.
	_card.position = Vector2(r.end.x - s.x, r.position.y + (r.size.y - s.y) * 0.5).round()
	if stage != null:
		# The stage fills the screen behind the panel; its camera slides the car into the rest.
		var full := get_viewport_rect().size
		stage.position = Vector2.ZERO
		stage.size = full
		stage.panel_share = clampf((full.x - _card.position.x + STAGE_GAP * pt) / maxf(full.x, 1.0), 0.0, 0.7)
		stage.visible = visible


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DIM)


## For check_hud: the card and its buttons shown, in pixels.
func ui_rects() -> Dictionary:
	var out := {"card": _card.get_global_rect(), "action": _action.get_global_rect(), "leave": _leave.get_global_rect()}
	for id: String in _tab_buttons:
		if (_tab_buttons[id] as Button).visible:
			out["tab_" + id] = (_tab_buttons[id] as Button).get_global_rect()
	var tiles: Dictionary = _swatches if tab == "paint" else _items
	for id: String in tiles:
		var b := tiles[id] as Button
		if b.visible and b.is_visible_in_tree():
			out[("paint_" if tab == "paint" else "item_") + id] = b.get_global_rect()
	return out


func card_rect() -> Rect2:
	return _card.get_global_rect()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or Gamepad.closes(event)):
		get_viewport().set_input_as_handled()
		closed.emit()


## G1: four stat bars (top speed, pull, grip, nitro): the car now in white, what
## the item picked adds in cyan, what a switch loses in pink. Drawn, no nodes per bar.
class StatBars extends Control:
	const ROW := 21.0
	## The bars' names [pl, en] (dialogue.json "garage": bar_top, bar_pull, bar_grip, bar_nitro).
	var names: Array = [["", ""], ["", ""], ["", ""], ["", ""]]
	## What fills a bar: 160 km/h, pull ×2, grip ×1.5, the nitro kit.
	const FULL := [160.0, 2.0, 1.5, 1.0]
	var pt := 1.0
	var _now: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var _after: Array[float] = [0.0, 0.0, 0.0, 0.0]

	func show_stats(now: Dictionary, after: Dictionary) -> void:
		var keys := ["top_kmh", "pull", "grip", "nitro"]
		for i in 4:
			_now[i] = clampf(float(now[keys[i]]) / float(FULL[i]), 0.0, 1.0)
			_after[i] = clampf(float(after[keys[i]]) / float(FULL[i]), 0.0, 1.0)
		queue_redraw()

	## Two columns of two: each name over its bar.
	func _draw() -> void:
		var font := get_theme_default_font()
		var fs := roundi(UiKit.T_LABEL * pt)
		var h := 5.0 * pt
		var col_w := (size.x - 12.0 * pt) * 0.5
		for i in 4:
			var x0 := (i % 2) * (col_w + 12.0 * pt)
			var y0 := (i / 2) * ROW * pt
			draw_string(font, Vector2(x0, y0 + fs), Lang.pick(str(names[i][0]), str(names[i][1])), HORIZONTAL_ALIGNMENT_LEFT, col_w, fs, UiKit.SUB)
			var bar := Rect2(x0, y0 + fs + 4.0 * pt, col_w, h)
			draw_rect(bar, UiKit.DIM)
			var a := _now[i]
			var b := _after[i]
			draw_rect(Rect2(bar.position.x, bar.position.y, col_w * minf(a, b), h), UiKit.INK)
			if b > a + 0.001:
				draw_rect(Rect2(bar.position.x + col_w * a, bar.position.y, col_w * (b - a), h), UiKit.NEON_CYAN)
			elif a > b + 0.001:
				draw_rect(Rect2(bar.position.x + col_w * b, bar.position.y, col_w * (a - b), h), UiKit.NEON_PINK)
