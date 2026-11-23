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

const Lang := preload("res://scripts/lang.gd")
const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)

signal closed

const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad follow-ups
const CarStage := preload("res://scripts/car_stage.gd")  # G1: the car in the night box
const Ladder := preload("res://scripts/ladder.gd")  # R1: the car's class

## The swatches' size in points (at least 44 tall: the touch rule); G1: the width follows the panel's.
const SWATCH := Vector2(114.0, 58.0)
## G1: the panel's share of the safe area's width, its least and most width (pt), and the gap to the stage.
const SWATCH_G1_H := 48.0
const PANEL_SHARE := 0.46
const PANEL_MIN := 330.0
const PANEL_MAX := 470.0
const STAGE_GAP := 10.0
## G1: the class letters' colours (D .. S) on the badge.
const CLASS_COLOURS := [Color("#c9c2d8"), Color("#5fd38a"), Color("#5fd4ff"), Color("#ff4fd8"), Color("#ffd23f")]
const GAP := 6.0
## Swatches per row (loop 3h slice 2: ten paints in two rows of five).
const COLUMNS := 5

## garage.gd (the rules, the paints, Mirek's lines).
var garage: Node
## Pixels per point and the safe area (hud.gd's).
var pt := 1.0
var safe := Rect2()
## The swatch picked (a paint id).
var picked := ""
## G13: the tab shown ("paint" or "parts") and the shop item picked on the parts tab (upgrades.gd id).
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
var _parts: GridContainer
var _stats: Label
var _stats_en: Label
var _tab_paint: Button
var _tab_parts: Button
var _action: Button
var _leave: Button


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
	_card.add_theme_stylebox_override("panel", hud._panel_box(12.0, 12.0))
	_card.custom_minimum_size.x = (_inner + 24.0) * pt
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi(6.0 * pt))
	_card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	col.add_child(head)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	_title = hud._label(hud.T_TITLE, UiKit.GOLD)  # card titles are gold (the kit; was the garage blue)
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
	_money = hud._label(hud.T_BODY, hud.ACCENT)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_money)
	_bars = StatBars.new()
	_bars.name = "bars"
	_bars.pt = pt
	_bars.names = [garage.line("bar_top"), garage.line("bar_pull"), garage.line("bar_grip"), garage.line("bar_nitro")]
	_bars.custom_minimum_size = Vector2(_inner, StatBars.ROW * 2.0) * pt
	col.add_child(_bars)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", roundi(GAP * pt))
	col.add_child(tabs)
	head = tabs
	_tab_paint = hud._chip(head, "LAKIER", "Paint")
	_tab_paint.name = "tab_paint"
	_tab_paint.pressed.connect(func() -> void: show_tab("paint"))
	_tab_parts = hud._chip(head, "CZĘŚCI I AUTA", "Parts and cars")
	_tab_parts.name = "tab_parts"
	_tab_parts.pressed.connect(func() -> void: show_tab("parts"))
	for t: Button in [_tab_paint, _tab_parts]:
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var width := _inner
	_line = hud._label(hud.T_SUB, hud.INK)
	hud._wrap(_line, width)
	_line.max_lines_visible = 2  # G1: the panel is narrower; Mirek keeps it to two lines
	_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(_line)
	_line_en = hud._label(hud.T_LABEL, hud.SUB)
	hud._wrap(_line_en, width)
	col.add_child(_line_en)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", roundi(GAP * pt))
	_grid.add_theme_constant_override("v_separation", roundi(GAP * pt))
	col.add_child(_grid)
	for p: Dictionary in garage.PAINTS:
		_swatches[str(p["id"])] = _swatch(p)
	_parts = GridContainer.new()
	_parts.columns = 3  # G1: three across in the narrower panel
	_parts.add_theme_constant_override("h_separation", roundi(GAP * pt))
	_parts.add_theme_constant_override("v_separation", roundi(GAP * pt))
	col.add_child(_parts)
	for id: String in garage.Upgrades.ORDER:
		_items[id] = _item(id, width)
	_stats = hud._label(hud.T_SUB, hud.INK)
	hud._wrap(_stats, width)
	col.add_child(_stats)
	_stats_en = hud._label(hud.T_LABEL, hud.SUB)
	hud._wrap(_stats_en, width)
	col.add_child(_stats_en)
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


## One paint's button: its colour (with the stripe), the Polish name, the price or the state.
func _swatch(p: Dictionary) -> Button:
	var hud := _hud()
	var b := Button.new()
	b.name = "paint_%s" % p["id"]
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(maxf(44.0, (_inner - GAP * (COLUMNS - 1)) / COLUMNS), SWATCH_G1_H) * pt
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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


## One shop cell (a car, the nitro or a part): its name over its state or price.
func _item(id: String, width: float) -> Button:
	var hud := _hud()
	var row: Dictionary = garage.Upgrades.find(id)
	var b := Button.new()
	b.name = "item_%s" % id
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2((width - GAP * 2.0) / 3.0, 46.0) * pt
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var name_l: Label = hud._label(hud.T_SUB, hud.INK)
	name_l.name = "name"
	name_l.text = Lang.pick(str(row["name"][0]), str(row["name"][1]))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_l)
	var state: Label = hud._label(hud.T_LABEL, hud.SUB)
	state.name = "price"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.clip_text = true
	box.add_child(state)
	b.pressed.connect(func() -> void: pick_item(id))
	_parts.add_child(b)
	return b


## G13: the tab shown ("paint" or "parts").
func show_tab(t: String) -> void:
	tab = "parts" if t == "parts" else "paint"
	_say("parts" if tab == "parts" else "hello")
	_refresh()


## A shop cell tapped: it is picked, and Mirek says what it is (its blurb) or why not.
func pick_item(id: String) -> void:
	picked_item = id
	if stage != null:
		stage.focus("engine" if id == "engine" else ("tyres" if id == "tyres" else ("nitro" if id == "nitro" else "")))
	var row: Dictionary = garage.Upgrades.find(id)
	_line.text = str((row["blurb"] as Array)[0])
	_line_en.text = str((row["blurb"] as Array)[1])
	_refresh()


## Opens on the paint the car wears, with Mirek's hello.
func open(start_tab := "paint", mode := "garage") -> void:
	if not _built:
		_build()
	stage.set_mode(mode)
	_title.text = Lang.pick("MOJE AUTO", "MY CAR") if mode == "mine" else str(garage.NAME[0]).to_upper()
	picked = garage.current()
	tab = start_tab
	_say("mine" if mode == "mine" else ("parts" if tab == "parts" else "hello"))
	_refresh()
	visible = true
	_place.call_deferred()
	_place()
	if Gamepad.in_use():
		# The gamepad follow-ups: the swatches and the two chips take focus, on the paint worn.
		Gamepad.focus_all(_card, pt)
		(_swatches.get(picked, _leave) as Button).grab_focus()
	else:
		Gamepad.focus_none(_card)


func close() -> void:
	Gamepad.drop_focus(self)
	visible = false
	if stage != null:
		stage.visible = false


func is_open() -> bool:
	return visible


## A swatch tapped: it is picked; a paint you can't have yet gets Mirek's reason.
func pick(id: String) -> void:
	picked = id
	match garage.rule_now(id):
		"short":
			_say("short")
		"locked":
			_say("locked")
	_refresh()


## The action button: buy or switch to the picked paint.
func _on_action() -> void:
	if tab == "parts":
		var r: String = garage.choose_item(picked_item)
		if r == "buy":
			var maxed: bool = garage.Upgrades.kind(picked_item) == "part" \
					and garage.Upgrades.level(garage.wallet.tune, picked_item) >= garage.Upgrades.MAX_LEVEL
			_say(picked_item if picked_item in ["tt", "nitro"] else ("max" if maxed else "part"))
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


func _refresh() -> void:
	var hud := _hud()
	var w: Node = garage.wallet
	_money.text = w.money(int(w.zl)) if w != null else ""
	var on_parts := tab == "parts"
	_grid.visible = not on_parts
	_parts.visible = on_parts
	_stats.visible = false  # G1: the bars say it; the line stays for the log
	_stats_en.visible = false
	_refresh_look()
	for t: Array in [[_tab_paint, "paint"], [_tab_parts, "parts"]]:
		var tb: Button = t[0]
		var tstyle: StyleBoxFlat = hud._box(UiKit.GOLD_TINT if tab == t[1] else hud.CARD_BG, hud.ACCENT if tab == t[1] else UiKit.EDGE_STRONG, 2.0 if tab == t[1] else 1.0)
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			tb.add_theme_stylebox_override(s, tstyle)
	if on_parts:
		_refresh_parts()
		_place()
		return
	var cur: String = garage.current()
	for id: String in _swatches:
		var b: Button = _swatches[id]
		var r: String = garage.rule_now(id)
		var p: Dictionary = garage.find(id)
		var price := b.find_child("price", true, false) as Label
		match r:
			"on":
				price.text = Lang.pick("na aucie", "on the car")
			"switch":
				price.text = Lang.pick("masz", "yours") if not (p.has("eggs") or p.has("syrenki")) or w.paints.has(id) else Lang.pick("gratis", "free")
			"locked":
				if p.has("syrenki"):
					price.text = Lang.pick("%d/%d Syrenek", "%d/%d Mermaids") % [garage.syrenki_now(), int(p["syrenki"])]
				else:
					price.text = Lang.pick("%d/%d sekretów", "%d/%d easter eggs") % [garage.eggs_now(), int(p["eggs"])]
			_:
				price.text = w.money(int(p["price"]))
		var lit := id == picked
		var edge: Color = hud.ACCENT if lit else (UiKit.INK if id == cur else UiKit.EDGE_STRONG)
		var style: StyleBoxFlat = hud._box(hud.CARD_BG, edge, 2.0 if lit or id == cur else 1.0)
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			b.add_theme_stylebox_override(s, style)
	var p2: Dictionary = garage.find(picked)
	var name_pl := str(p2["name"][0]) if not p2.is_empty() else ""
	var name_en := str(p2["name"][1]) if not p2.is_empty() else ""
	match garage.rule_now(picked):
		"on":
			hud._set_chip(_action, "NA AUCIE: %s" % name_pl.to_upper(), "%s is on the car" % name_en)
			_action.disabled = true
		"switch":
			hud._set_chip(_action, "LAKIERUJ: %s" % name_pl.to_upper(), "Paint it %s, free" % name_en.to_lower())
			_action.disabled = false
		"buy":
			hud._set_chip(_action, "KUP ZA %s" % w.money(int(p2["price"])).to_upper(), "Buy %s" % name_en.to_lower())
			_action.disabled = false
		"short":
			var miss := int(p2["price"]) - int(w.zl)
			hud._set_chip(_action, "BRAKUJE %s" % w.money(miss).to_upper(), "%s short" % _money_en(miss))
			_action.disabled = true
		"locked":
			if p2.has("syrenki"):
				hud._set_chip(_action, "ZA %d SYRENEK" % int(p2["syrenki"]), "Find %d Mermaids" % int(p2["syrenki"]))
			else:
				hud._set_chip(_action, "ZA %d SEKRETÓW" % int(p2["eggs"]), "Find %d easter eggs" % int(p2["eggs"]))
			_action.disabled = true
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mine_gate(garage.rule_now(picked))
	_place()


## G2: from the full map (MOJE AUTO) the shop's buys wait for the workshop: the action says where.
func _mine_gate(rule: String) -> void:
	if garage.mode == "mine" and rule in ["buy", "short"]:
		_hud()._set_chip(_action, "KUP U MIRKA · TWARDA", "Buy it at Mirek's on Twarda")
		_action.disabled = true


## G1: the stage wears the paint picked (or the car picked on the parts tab), and the badge and bars
## show the car's numbers now and after the item picked.
func _refresh_look() -> void:
	var U: GDScript = garage.Upgrades
	var st: Dictionary = garage.shop_state()
	var now: Dictionary = U.stats(str(st["car"]), st["tune"], bool(st["nitro"]))
	var after := now
	var car_id := str(st["car"])
	if tab == "parts" and garage.item_rule_now(picked_item) in ["buy", "short", "switch"]:
		after = U.stats_after(picked_item, st)
		if U.kind(picked_item) == "car":
			car_id = picked_item
	var p: Dictionary = garage.find(picked if tab == "paint" else garage.current())
	if p.is_empty():
		p = garage.find(garage.current())
	if stage != null and not p.is_empty():
		stage.set_car("player_tt" if car_id == "tt" else "player", p["paint"], p["stripe"])
		stage.visible = visible
	var c0 := Ladder.car_class(float(now["top_mult"]), float(now["pull"]))
	var c1 := Ladder.car_class(float(after["top_mult"]), float(after["pull"]))
	_badge.text = (Lang.pick("KL. %s", "CL. %s") % Ladder.CLASS_NAMES[c0]) + ("" if c1 == c0 else " → %s" % Ladder.CLASS_NAMES[c1])
	_badge.add_theme_color_override("font_color", CLASS_COLOURS[c1])
	(_bars as StatBars).show_stats(now, after)


## G13: the parts tab: each cell's state, the stat card, the action for the cell picked.
func _refresh_parts() -> void:
	var hud := _hud()
	var w: Node = garage.wallet
	var U: GDScript = garage.Upgrades
	var st: Dictionary = garage.shop_state()
	for id: String in _items:
		var b: Button = _items[id]
		var r: String = garage.item_rule_now(id)
		var row: Dictionary = U.find(id)
		var price := b.find_child("price", true, false) as Label
		var name_l := b.find_child("name", true, false) as Label
		name_l.text = Lang.pick(str(row["name"][0]), str(row["name"][1]))
		match r:
			"on":
				price.text = Lang.pick("na aucie", "on the car")
			"switch", "owned":
				price.text = Lang.pick("masz", "yours")
			"max":
				price.text = Lang.pick("poziom %d/%d", "level %d/%d") % [U.MAX_LEVEL, U.MAX_LEVEL]
			_:
				if U.kind(id) == "part":
					price.text = Lang.pick("poz. %d → %d · %s", "lvl %d → %d · %s") % [U.level(st["tune"], id), U.level(st["tune"], id) + 1, w.money(U.price(id, st["tune"]))]
				else:
					price.text = w.money(U.price(id, st["tune"]))
		var lit := id == picked_item
		var worn: bool = r in ["on", "owned", "max"]
		var edge: Color = hud.ACCENT if lit else (UiKit.INK if worn else UiKit.EDGE_STRONG)
		var style: StyleBoxFlat = hud._box(hud.CARD_BG, edge, 2.0 if lit or worn else 1.0)
		for s in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			b.add_theme_stylebox_override(s, style)
	var now: Dictionary = U.stats(str(st["car"]), st["tune"], bool(st["nitro"]))
	var after: Dictionary = U.stats_after(picked_item, st)
	var rule: String = garage.item_rule_now(picked_item)
	var shows_after: bool = rule in ["buy", "short", "switch"]
	_stats.text = _stat_line(now, after if shows_after else now, Lang.code == Lang.EN)
	# The key to the numbers, in English only (the Polish line's labels say it already).
	_stats_en.text = Lang.pick("", "top speed · pull · grip · nitro (now → after buying)")
	var row2: Dictionary = U.find(picked_item)
	var name_pl := str(row2["name"][0])
	var name_en := str(row2["name"][1])
	match rule:
		"on":
			hud._set_chip(_action, "NA AUCIE", "%s is on the road" % name_en)
			_action.disabled = true
		"owned":
			hud._set_chip(_action, "MASZ: NITRO", "Owned: the button is by the horn")
			_action.disabled = true
		"max":
			hud._set_chip(_action, "POZIOM MAX", "%s is maxed" % name_en.to_lower())
			_action.disabled = true
		"switch":
			hud._set_chip(_action, "JEDŹ: %s" % name_pl.to_upper(), "Drive the %s, free" % name_en)
			_action.disabled = false
		"buy":
			hud._set_chip(_action, "KUP ZA %s" % w.money(U.price(picked_item, st["tune"])).to_upper(), "Buy: %s" % name_en)
			_action.disabled = false
		_:
			var miss: int = U.price(picked_item, st["tune"]) - int(w.zl)
			hud._set_chip(_action, "BRAKUJE %s" % w.money(miss).to_upper(), "%s short" % _money_en(miss))
			_action.disabled = true
	_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


## For check_hud: the card and its buttons, in pixels.
func ui_rects() -> Dictionary:
	var out := {"card": _card.get_global_rect(), "action": _action.get_global_rect(), "leave": _leave.get_global_rect(),
			"tab_paint": _tab_paint.get_global_rect(), "tab_parts": _tab_parts.get_global_rect()}
	if tab == "parts":
		for id: String in _items:
			out["item_" + id] = (_items[id] as Button).get_global_rect()
	else:
		for id: String in _swatches:
			out["paint_" + id] = (_swatches[id] as Button).get_global_rect()
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
