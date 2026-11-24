extends Control
## F's asks (2026-10-30; BACKLOG "From loop MW-1"): the full-screen map, opened by a tap on the
## minimap (hud.gd `map_pressed`; main.gd pauses the game under it, like the settings card). The
## map (since 2026-10-31 its own game-map style, map_art.gd; one look day and night), north up and
## scaled to the screen: one finger pans, two pinch to zoom (the mouse wheel on a computer). On it
## the car's arrow, the mission target, the places found (gold dots) and the districts (districts.gd
## `view`, given by `set_districts` after open: the ones not discovered yet under a light fog, each
## discovered one's name and per cent at its label). The ✕, Esc or the Android back gesture close
## it. Built the first time it opens; hidden it draws nothing (0 cost). Press and hold a spot
## (HOLD_S, the finger still) to teleport there: `teleport` is emitted and the map closes; main.gd
## puts the car on the nearest lane (the helicopter keeps its height). `can_teleport` says why not.
##
## F's ask (2026-11-17, "it's overcomplicated, make it minimalistic, and a separate quests screen
## with a big QUESTS button"; the plan https://claude.ai/artifact/EdLnFk5DtfTakCMq2JeRzn): the map
## shows only places now. The city, the car, the route, the questlines' dots with their names
## (always, dimmed while something runs: map_markers.gd's rule table), Mirek's garage, the street
## jobs close in, the "?" of a First step. On top only three things: a NEXT line top left (the
## tracked place, else the nearest First step, else the next goal; a tap shows it or pins it), the
## ✕ top right and a big gold QUESTS button bottom right (its red badge counts the questlines that
## invited the player and wait). The title, the legend and its filters, the standing hint, the ?
## and ≡ buttons, the districts' card, the list on the right and the metro icons are gone. The
## lists are the QUESTS screen (quests_screen.gd, drawing quest_book.gd `tabs` from main.gd's facts:
## `set_book`), opened by the button or by a dot's DETAILS. A tap on a questline's dot tells its
## line and offers ROUTE (its start becomes the pin) and DETAILS (the screen on that questline).

signal closed
## G2 (F 2026-11-23): MOJE AUTO tapped: the map closes and the car screen opens (main.gd).
signal my_car
## A place became the quest pin, or a request was taken (its entry, quest_lines.gd `entry`; {}: the
## pin was taken off). main.gd `_on_quest_picked`.
signal quest_picked(entry: Dictionary)
## F (2026-11-08): the quest under way is to be dropped (the QUESTS screen's QUIT, tapped twice).
## main.gd gives up whatever runs (hud's abort, as the status card's ✕ does).
signal quit_quest
## The hold's spot (map metres), when the hold was held to the end.
signal teleport(at: Vector2)
## First hour step 5 (The Six): a rival was called out from the QUESTS screen (its ladder.gd rung):
## main.gd calls that rival out (rivals.gd `call_out`) and the map closes.
signal rival_called(rung: int)
## An item marked NEW was looked at on the QUESTS screen (its id, quest_book.gd): main.gd forgets it.
signal seen(id: String)
## Settings redesign step 2: QUESTS → Collection → OPEN NOTEBOOK; `target` is a chapter or "" (main.gd opens
## the notebook page of the settings card).
signal notebook(target: String)

const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)
const Lang := preload("res://scripts/lang.gd")
const MapArt := preload("res://scripts/map_art.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const MainLine := preload("res://scripts/main_line.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const Access := preload("res://scripts/access.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
const Hints := preload("res://scripts/hints.gd")  # 2026-11-16: the map's coach marks
const MapTrack := preload("res://scripts/map_track.gd")  # 2026-11-16: track and "?" marks
const QuestBook := preload("res://scripts/quest_book.gd")  # 2026-11-17: the QUESTS screen's contents
const QuestsScreen := preload("res://scripts/quests_screen.gd")
const ClockDial := preload("res://scripts/clock_dial.gd")  # F 2026-11-19: the watch
## The hold to teleport: this long, the finger within HOLD_SLOP points of where it went down.
const HOLD_S := 0.6
const HOLD_SLOP := 12.0
## The gamepad follow-ups: the left stick pans (points a second, the stick full over), RT / LT
## zoom in / out (e-folds a second), and holding A teleports to the cross at the screen's centre
## (the hold's "finger": PAD_HOLD). Y opens QUESTS, X does the NEXT line's tap.
const PAD_PAN := 520.0
const PAD_ZOOM := 1.4
const PAD_HOLD := 99
## The icons' badge radius in points, and the zoom (metres across the screen's height) under
## which their names show.
const ICON_R := 11.0
const NAMES_M := 2200.0
## The side streets (residential, service: map_art.gd's minor mesh) show under this zoom only.
const MINOR_M := 2600.0

## The closest zoom: this many metres across the screen's height; the start: START_M.
const NEAR_M := 250.0
const START_M := 1400.0
const GOLD := UiKit.GOLD  # the one gold (was #f0b429; docs/design/ui-kit.md)
const GameTime := preload("res://scripts/game_time.gd")
## The clock picker's choices, in the day's order: [time_of_day.gd mode, Polish, English].
## No Live here (F 2026-11-19: the game has its own clock).
const TIME_PICKS := [[4, "Świt", "Dawn"], [0, "Dzień", "Day"], [1, "Zmierzch", "Dusk"], [2, "Noc", "Night"]]
const ARROW := Color("#d8432f")
## Type sizes in points (hud.gd's).
const T_TITLE := 17.0
const T_SUB := 13.0
## The QUESTS button (points) and the NEXT line's height and widest.
const QUESTS_W := 150.0
const QUESTS_H := 60.0
const NEXT_H := 44.0
const NEXT_W := 330.0
## A questline's dot and name while something runs (quest focus): drawn this small and this faint.
const FOCUS_DIM := 0.45
## The legend's row height (points; F 2026-11-19).
const LEGEND_ROW := 20.0
const NEW_RED := UiKit.ALERT

## Set by hud.gd before the first open.
var hud: CanvasLayer
## centrum.json (hud.gd keeps it from setup_minimap), the map's outline and the parts of the
## bounds left off the map.
var data: Dictionary = {}
var outline := PackedVector2Array()
var outside: Array[Rect2] = []
## map_builder.gd `landmark_info` (key, centre) for the icons.
var landmarks: Array = []
## map_art.gd `prepare`'s result when hud.gd made it on a worker thread (else made on the first open).
var prepared: Dictionary = {}
## The map's bounds in metres.
var bounds := Rect2()
## Returns [] when a teleport is allowed now, else [pl, en] (why not). Set by main.gd.
var can_teleport := Callable()
var pt := 1.0
var safe := Rect2()

## What it shows (map metres), from open().
var car := Vector2.ZERO
var car_yaw := 0.0
## A crash scene (hud.set_scene_mark), Vector2.INF for none.
var scene_mark := Vector2.INF
var found := PackedVector2Array()
## The map marker registry (map_markers.gd, TD-13; hud.gd hands its own over on open): the street
## jobs' places (JOB), the garage (SERVICE), the questlines' starts (STORY: each with its name in
## the language shown, its one-line description and its id for a tap, `_tap_story`, and "small"
## for a smaller "!"), the "?" marks (UNKNOWN), the main line's star (MAIN) and the target, by its
## rule table.
var markers := MapMarkers.new()
## F (2026-11-08): what is under way, [pl, en] (main.gd sets it on open; empty: nothing to quit).
## The QUESTS screen's NOW line names it; QUIT there, tapped twice, quits.
var quit_what: Array = []
var _tap_at := Vector2.INF
var _tap_ms := 0
## Quest focus (a quest under way: the side places, the garage and the "?" marks stay off, the
## questlines' dots dim) and flying: hud.gd sets both.
var focus := false
var flying := false
## F (2026-11-07): the hospitals only matter to a rescue; their marks show only while one is on
## (main.gd sets it on open).
var hospitals := false
## The time of day (time_of_day.gd; main.gd sets it): its `local_clock` is the clock top right, the
## watch and the looks move it (`set_hour`, `set_mode`). Null in the checks: "--:--".
var tod: Node
## The minimap's night (kept for hud.gd; the full map has one look day and night).
var night := 0.0
## Loop 3h slice 1: districts.gd `view()` (names, label point, polygons, found, pct) and the total %.
var districts: Array[Dictionary] = []
var districts_total := 0

## The map point at the screen's centre (m) and the zoom (pixels per metre).
var centre := Vector2.ZERO
var ppm := 1.0

var _built := false
## The language the cards were built in (lang.gd).
var _built_lang := ""
var _paper: ColorRect
var _land: Node2D
var _content: Node2D
var _mat: ShaderMaterial
var _base_mesh: ArrayMesh
var _tint_mesh: ArrayMesh
var _streets_mesh: ArrayMesh
var _minor_mesh: ArrayMesh
var _edge_mesh: ArrayMesh
var _tint_key := -1
## The icons placed (map_icons.gd `place`).
var icons: Array[Dictionary] = []
## The hold: its touch index (-1: none), where it went down (px), its time (s) held.
var _hold_index := -1
var _hold_at := Vector2.ZERO
var _hold_t := 0.0
## A line shown for a moment (the time left, s): a refusal, a dot's or a "?"'s words.
var _note: PanelContainer
var _note_t := 0.0
## The dot or "?" tapped now: a First step's id for a "?" (`_unknown_sel`), a questline's id for a
## dot (`_story_sel`), and its map point; the gold button offered with its words (TRACK for a "?",
## ROUTE for a dot: `_offer`) and DETAILS for a dot.
var _unknown_sel := ""
var _story_sel := ""
var _sel_at := Vector2.INF
var _offer: Button
var _details: Button
## For checks: the last spot teleported to (INF: none).
var last_teleport := Vector2.INF
var _overlay: Control
var _close: Button
var _touches := {}
var _pinch := 0.0
## Loop 3h slice 1: the fog's triangles (map points, three a triangle: the districts not
## discovered yet, clipped to the map's bounds).
var _fog := PackedVector2Array()
## The soft edge: the fog's merged shapes shrunk by FOG_RAMP metres each, one triangle list a step
## (each adds a little tone, so the fog thickens from its border inward).
var _fog_soft: Array[PackedVector2Array] = []
const FOG_RAMP := [45.0, 100.0, 170.0]
const FOG_A0 := 0.14  ## the fog's tone at its very edge
const FOG_A_STEP := 0.07  ## what each inset adds (the whole: 0.14 + 3 × 0.07 = 0.35)
## The quest pin (main.gd `quest_pin`: an entry with a place; {} none): drawn gold, the NEXT line's.
var quest_pick: Dictionary = {}
## 2026-11-17: the QUESTS screen's facts (main.gd `_fill_map_list`, `set_book`), the tabs built from
## them (quest_book.gd `tabs`), the screen, the QUESTS button and its badge, the NEXT line.
var book: Dictionary = {}
var tabs: Array = []
var _screen: QuestsScreen
var _quests_btn: Button
## G2: the MOJE AUTO chip, over the QUESTS button.
var _car_btn: Button
var _badge: Label
var _next: Button
## F 2026-11-19 ("add the clock to the map", "when the user clicks the time show a clock where they
## can change it"): the clock left of the ✕, and its picker under it (what is open now, the looks).
var _clock_btn: Button
var _picker: PanelContainer
var _picker_open: Label
var _dial: Control
var _clock_icon: Control
var _time_buttons: Array[Button] = []
## The NEXT line's thing ({} none): {"words": [pl, en], "colour", "at", "entry" (a place to pin, {}
## none), "id" (an item to open the screen on, "" none)}.
var next_info: Dictionary = {}
## 2026-11-16: after First steps, the main line's next step as [pl, en] and its place (`set_next`).
var next_words: Array = []
var next_at := Vector2.INF
## The coach marks (hints.gd `map_tick`; `hints` is main.gd's, null in a check that wants none) and
## what the player did since the mark came up.
var hints: Hints
var _coach: PanelContainer
var _did_quests := false
var _did_hold := false
var _did_pin := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS  # the game is paused under it; the hold still runs
	visible = false
	get_viewport().size_changed.connect(_fit)


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


func _build() -> void:
	_built = true
	_built_lang = Lang.code
	var t0 := Time.get_ticks_usec()
	if outline.size() < 3 and bounds.has_area():
		outline = PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end,
				Vector2(bounds.position.x, bounds.end.y)])
	if prepared.is_empty():
		prepared = MapArt.prepare(data, outline, outside)
	var m := MapArt.meshes(prepared)
	_base_mesh = m["base"]
	_streets_mesh = m["streets"]
	_minor_mesh = m["minor"]
	_edge_mesh = m["edge"]
	icons = MapIcons.place(landmarks, data.get("palm", []), prepared["bridges"])
	icons.append_array(MapIcons.place_extras(data.get("pois", [])))
	prepared = {}  # its arrays are in the meshes now
	print("full map: built in %.0f ms, %d icons" % [(Time.get_ticks_usec() - t0) / 1000.0, icons.size()])
	_paper = ColorRect.new()
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.color = MapArt.OFF_MAP
	add_child(_paper)
	_land = Node2D.new()
	_land.draw.connect(func() -> void:
		_land.draw_mesh(_base_mesh, null)
		if _tint_mesh != null:
			_land.draw_mesh(_tint_mesh, null))
	add_child(_land)
	_mat = ShaderMaterial.new()
	_mat.shader = Shader.new()
	_mat.shader.code = MapArt.WIDEN
	_content = Node2D.new()
	_content.material = _mat
	_content.draw.connect(func() -> void:
		if _view().y / ppm <= MINOR_M:
			_content.draw_mesh(_minor_mesh, null)
		_content.draw_mesh(_streets_mesh, null)
		_content.draw_mesh(_edge_mesh, null))
	add_child(_content)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_paint)
	add_child(_overlay)
	_close = _round_button("✕", UiKit.INK)
	_close.name = "close"
	_close.pressed.connect(close)
	add_child(_close)
	_clock_btn = _round_button("", UiKit.INK)
	_clock_btn.name = "clock"
	_clock_btn.add_theme_font_size_override("font_size", _px(T_SUB + 2.0))
	_clock_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock_btn.pressed.connect(_clock_tapped)
	# F 2026-11-20: a sun or a moon left of the time (clock_dial.gd draws both)
	_clock_icon = Control.new()
	_clock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock_icon.draw.connect(func() -> void:
		var c: Dictionary = tod.local_clock() if tod != null else {}
		var night := tod != null and tod.has_method("sun_times") \
				and ClockDial.phase(float(c.get("hour", 12.0)), tod.sun_times()) == "clock_night"
		ClockDial.draw_sun_or_moon(_clock_icon, _clock_icon.size * 0.5, 7.0 * pt, night, pt))
	_clock_btn.add_child(_clock_icon)
	add_child(_clock_btn)
	_build_picker()
	_next = Button.new()
	_next.name = "next"
	_next.focus_mode = Control.FOCUS_NONE
	_next.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_next.clip_text = true
	_next.add_theme_font_size_override("font_size", _px(T_SUB + 1.0))
	_next.visible = false
	_next.pressed.connect(_next_tapped)
	add_child(_next)
	_quests_btn = Button.new()
	_quests_btn.name = "quests"
	_quests_btn.focus_mode = Control.FOCUS_NONE
	var qw: Array = QuestBook.words("quests")
	_quests_btn.text = Lang.pick(str(qw[0]), str(qw[1]))
	_quests_btn.custom_minimum_size = Vector2(QUESTS_W, QUESTS_H) * pt
	_quests_btn.add_theme_font_size_override("font_size", _px(T_TITLE + 3.0))
	# The kit's PRIMARY button (docs/design/ui-kit.md), lifted off the map by a shadow.
	UiKit.style_button(_quests_btn, UiKit.Kind.PRIMARY, pt, T_TITLE + 3.0)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := _quests_btn.get_theme_stylebox(st) as StyleBoxFlat
		sb.shadow_color = Color(UiKit.CARD_SOLID, 0.45)
		sb.shadow_size = _px(6)
	_quests_btn.pressed.connect(func() -> void: open_screen())
	add_child(_quests_btn)
	_car_btn = Button.new()
	_car_btn.name = "my_car"
	_car_btn.focus_mode = Control.FOCUS_NONE
	_car_btn.text = Lang.pick("MOJE AUTO", "MY CAR")
	_car_btn.custom_minimum_size = Vector2(QUESTS_W, 44.0) * pt
	UiKit.style_button(_car_btn, UiKit.Kind.SECONDARY, pt, T_SUB + 1.0)
	_car_btn.add_theme_color_override("font_color", UiKit.NEON_CYAN)
	_car_btn.pressed.connect(func() -> void:
		close()
		my_car.emit())
	add_child(_car_btn)
	_badge = Label.new()
	_badge.name = "badge"
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.add_theme_font_size_override("font_size", _px(T_SUB + 1.0))
	_badge.add_theme_color_override("font_color", UiKit.INK)
	var bb := StyleBoxFlat.new()
	bb.bg_color = NEW_RED
	bb.set_corner_radius_all(_px(13))
	bb.border_color = UiKit.ON_GOLD
	bb.set_border_width_all(_px(2))
	_badge.add_theme_stylebox_override("normal", bb)
	_badge.custom_minimum_size = Vector2(26.0, 26.0) * pt
	_badge.visible = false
	_quests_btn.add_child(_badge)
	_note = _card(["", ""], [T_SUB, T_SUB])
	_note.name = "note"
	_note.visible = false
	add_child(_note)
	_coach = _card([""], [T_SUB])
	_coach.name = "coach"
	_coach.visible = false
	add_child(_coach)
	_offer = _gold_button(Hints.words_of("track_offer"))
	_offer.name = "track_offer"
	_offer.pressed.connect(_offer_tapped)
	add_child(_offer)
	var dw: Array = QuestBook.words("b_details")
	_details = _gold_button(Lang.pick(str(dw[0]), str(dw[1])))
	_details.name = "details"
	_details.pressed.connect(_details_tapped)
	add_child(_details)
	_screen = QuestsScreen.new()
	_screen.name = "quests_screen"
	_screen.pt = pt
	_screen.safe = safe
	_screen.acted.connect(_on_acted)
	_screen.back.connect(close_screen)
	_screen.quit_quest.connect(_quit_tapped)
	_screen.seen.connect(_on_seen)
	add_child(_screen)


func _box(alpha: float) -> StyleBoxFlat:
	var b := UiKit.card(pt, 10.0)  # the kit's card (no gold rail)
	b.bg_color = Color(UiKit.CARD, alpha)
	return b


## A small card: lines of text, Polish over English. Taps go through it to the map (its box too: a
## container stops them by default, and the coach mark took the ✕'s tap under it, 2026-11-17).
func _card(lines: Array, sizes: Array) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _box(0.9))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override("font_size", _px(sizes[i]))
		l.add_theme_color_override("font_color", UiKit.GOLD if i == 0 and sizes[i] == T_TITLE else
				(UiKit.INK if i == 0 else UiKit.SUB))
		v.add_child(l)
	return p


## A square 48 pt button on the map's dark card look (the ✕).
## The clock's picker: a dark card with "what is open now" and one button per look.
func _build_picker() -> void:
	_picker = PanelContainer.new()
	_picker.name = "time_picker"
	_picker.add_theme_stylebox_override("panel", _box(0.95))
	_picker.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", _px(6))
	_picker.add_child(v)
	var title := Label.new()
	var tw: Array = QuestBook.words("clock_title")
	title.text = Lang.pick(str(tw[0]), str(tw[1]))
	title.add_theme_font_size_override("font_size", _px(T_TITLE))
	title.add_theme_color_override("font_color", UiKit.GOLD)
	v.add_child(title)
	_picker_open = Label.new()
	_picker_open.add_theme_font_size_override("font_size", _px(T_SUB))
	_picker_open.add_theme_color_override("font_color", UiKit.SUB)
	_picker_open.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_picker_open.custom_minimum_size.x = 300.0 * pt
	v.add_child(_picker_open)
	_dial = ClockDial.new()
	_dial.name = "clock_dial"
	_dial.pt = pt
	_dial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dial.picked.connect(_hour_picked)
	v.add_child(_dial)
	var hint := Label.new()
	var hw: Array = QuestBook.words("clock_drag")
	hint.text = Lang.pick(str(hw[0]), str(hw[1]))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.style_label(hint, "sub", pt)
	v.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(6))
	v.add_child(row)
	# F 2026-11-20 (the kit's rules): the looks are SECONDARY buttons, the one the sun makes now
	# SELECTED (`_show_time`); no gold PRIMARY on this card.
	for pick: Array in TIME_PICKS:
		var b := Button.new()
		b.text = Lang.pick(str(pick[1]), str(pick[2])).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(64.0, 44.0) * pt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.name = "time_%d" % int(pick[0])
		b.set_meta("mode", int(pick[0]))
		b.pressed.connect(_time_tapped.bind(int(pick[0])))
		row.add_child(b)
		_time_buttons.append(b)
	add_child(_picker)


## The clock's words now ("PT 14:05"; "--:--" without a clock).
func _clock_words() -> String:
	if tod == null:
		return "--:--"
	var w: Array = GameTime.label(tod.local_clock())
	return Lang.pick(str(w[0]), str(w[1]))


## "Open now: ..." for the picker, from the time owner's table.
func _open_words() -> String:
	if tod == null:
		return ""
	var c: Dictionary = tod.local_clock()
	var names := PackedStringArray()
	for id: String in GameTime.open_ids(float(c.get("hour", 12.0))):
		var n: Array = GameTime.NAMES[id]
		names.append(Lang.pick(str(n[0]), str(n[1])))
	var none: Array = QuestBook.words("clock_none")
	var w: Array = QuestBook.fmt("clock_open", [", ".join(names) if not names.is_empty() else Lang.pick(str(none[0]), str(none[1]))])
	return Lang.pick(str(w[0]), str(w[1]))


func _clock_tapped() -> void:
	_picker.visible = not _picker.visible
	_picker_open.text = _open_words()
	_show_time()
	print("full map: clock %s (%s)" % ["open" if _picker.visible else "closed", _clock_words()])
	_fit()


## The clock now on the watch, the clock button (SELECTED while its picker is open, its sun or
## moon) and the look buttons (the look the sun makes now SELECTED).
func _show_time() -> void:
	_clock_btn.text = _clock_words()
	UiKit.style_button(_clock_btn, UiKit.Kind.SELECTED if _picker.visible else UiKit.Kind.SECONDARY, pt, T_SUB + 2.0, UiKit.R_PILL)
	# F 2026-11-20: a pill over the map is a solid dark card, never see-through (open: gold edge).
	var edge := UiKit.GOLD if _picker.visible else UiKit.EDGE_STRONG
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		_clock_btn.add_theme_stylebox_override(st, UiKit.box(UiKit.CARD_SOLID, edge, pt, UiKit.R_PILL, 1.5 if _picker.visible else 1.0, 4.0))
	_clock_icon.queue_redraw()
	if tod == null or not tod.has_method("sun_times"):
		return
	var c: Dictionary = tod.local_clock()
	_dial.set_time(float(c["hour"]), tod.sun_times(), GameTime.DAYS[clampi(int(c.get("weekday", 5)) - 1, 0, 6)])
	var now: int = tod.look_mode()
	for b: Button in _time_buttons:
		UiKit.style_button(b, UiKit.Kind.SELECTED if int(b.get_meta("mode")) == now else UiKit.Kind.SECONDARY, pt, T_SUB)


func _time_tapped(mode: int) -> void:
	if tod != null:
		tod.set_mode(mode)
	_picker.visible = false
	_show_time()
	print("full map: time picked %d, now %s" % [mode, _clock_words()])
	_fit()


## The watch's hand let go at `hour`: the clock moves forward there (time_of_day.gd `set_hour`).
func _hour_picked(hour: float) -> void:
	if tod != null:
		tod.set_hour(hour)
	_picker_open.text = _open_words()
	_show_time()
	print("full map: watch set %.2f, now %s" % [hour, _clock_words()])


func _round_button(text: String, ink: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", _px(22))
	b.add_theme_color_override("font_color", ink)
	for s in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(s, _box(0.94 if s != "pressed" else 1.0))
	b.custom_minimum_size = Vector2.ONE * 48.0 * pt
	return b


## A gold button 48 pt tall (TRACK, ROUTE, DETAILS under a tapped mark).
func _gold_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.visible = false
	b.custom_minimum_size = Vector2(110.0, 48.0) * pt
	b.add_theme_font_size_override("font_size", _px(T_SUB + 1.0))
	UiKit.style_button(b, UiKit.Kind.PRIMARY, pt, T_SUB + 1.0)
	return b


## Opens on the car, START_M across the screen's height.
func open(at: Vector2, yaw: float) -> void:
	if _built and _built_lang != Lang.code:
		# The language changed since the cards were made (Settings): make them again.
		for c in get_children():
			c.queue_free()
		_built = false
		_tint_key = -1
	if not _built:
		_build()
	car = at
	car_yaw = yaw
	centre = at
	_unselect()
	_touches.clear()
	_hold_index = -1
	_note_t = 0.0
	_note.visible = false
	_picker.visible = false
	_show_time()
	_did_quests = false
	_did_hold = false
	_did_pin = false
	_screen.close()
	_screen.tab = ""  # each visit's QUESTS opens on its first tab (First steps while they last)
	if hints != null:
		hints.map_reset()
	visible = true
	if Gamepad.in_use():
		# With a pad: what its buttons do here, for a few seconds (no hint stays on the map).
		var pw: Array = QuestBook.words("pad_map")
		_say([Gamepad.fmt(str(pw[0])), Gamepad.fmt(str(pw[1]))])
		_note_t = 6.0
	_fit()
	ppm = clampf(_view().y / START_M, _ppm_min(), _ppm_max())
	_place()


## Zooms to `metres` across the screen's height, about the centre (--fullmap=M).
func show_span(metres: float) -> void:
	ppm = _view().y / maxf(metres, 1.0)
	_place()


func close() -> void:
	if not visible:
		return
	visible = false
	_touches.clear()
	_hold_index = -1
	_coach.visible = false
	if _screen != null:
		_screen.close()
	if hints != null:
		hints.map_reset()
	closed.emit()


func is_open() -> bool:
	return visible


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _ppm_min() -> float:
	return minf(_view().x / maxf(bounds.size.x, 1.0), _view().y / maxf(bounds.size.y, 1.0)) * 0.9


func _ppm_max() -> float:
	return _view().y / NEAR_M


## The NEXT line top left, the ✕ top right, QUESTS bottom right, the note (and its buttons) bottom
## centre, inside the safe area.
func _fit() -> void:
	if not _built or not visible:
		return
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var m := 8.0 * pt
	_close.size = _close.custom_minimum_size
	_close.position = Vector2(s.end.x - m - _close.size.x, s.position.y + m)
	_clock_btn.text = _clock_words()
	_clock_btn.size = Vector2.ZERO
	_clock_btn.size = Vector2(maxf(_clock_btn.get_combined_minimum_size().x + 22.0 * pt, 112.0 * pt), _close.size.y)
	_clock_icon.position = Vector2(8.0 * pt, 0.0)
	_clock_icon.size = Vector2(22.0 * pt, _clock_btn.size.y)
	_clock_icon.queue_redraw()
	_clock_btn.position = Vector2(_close.position.x - m - _clock_btn.size.x, _close.position.y)
	if _picker.visible:
		_picker.reset_size()
		_picker.size = _picker.get_combined_minimum_size()
		_picker.position = Vector2(s.end.x - m - _picker.size.x, _close.position.y + _close.size.y + m)
	_quests_btn.visible = not _picker.visible  # the time card owns the corner while it is open
	_quests_btn.size = _quests_btn.custom_minimum_size
	_quests_btn.position = s.end - Vector2(m, m) - _quests_btn.size
	_car_btn.visible = _quests_btn.visible
	_car_btn.size = _car_btn.custom_minimum_size
	_car_btn.position = _quests_btn.position - Vector2(0.0, m + _car_btn.size.y)
	_badge.size = _badge.custom_minimum_size
	_badge.position = Vector2(_quests_btn.size.x - _badge.size.x * 0.7, -_badge.size.y * 0.3)
	if _next.visible:
		var room := _clock_btn.position.x - m - (s.position.x + m)
		# Its words' width (the button clips them, so its own minimum is none), at least a touch target.
		var want := _next.get_theme_font("font").get_string_size(_next.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				_next.get_theme_font_size("font_size")).x + _next.get_theme_stylebox("normal").get_minimum_size().x + 4.0
		_next.size = Vector2(clampf(want, NEXT_H * pt, maxf(NEXT_H * pt, minf(NEXT_W * pt, room))), NEXT_H * pt)
		_next.position = s.position + Vector2(m, m)
	if _note.visible:
		var lg_w := _legend_rect(_legend_rows()).size.x + m
		var room_w := _quests_btn.position.x - m - (s.position.x + m + lg_w)
		var nl := (_note.get_child(0) as VBoxContainer).get_child(0) as Label
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nl.custom_minimum_size.x = 0.0
		if nl.get_minimum_size().x > room_w - 24.0 * pt:
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # a long line wraps short of QUESTS
			nl.custom_minimum_size.x = room_w - 24.0 * pt
		_note.reset_size()
		_note.size = _note.get_combined_minimum_size()
		_note.position = Vector2(s.position.x + m + lg_w + maxf(0.0, (room_w - _note.size.x) * 0.5), s.end.y - m - _note.size.y)
	var bx := _note.position.x
	for b: Button in [_offer, _details]:
		if b.visible:
			b.size = b.get_combined_minimum_size()
			b.position = Vector2(bx, _note.position.y - m - b.size.y)
			bx += b.size.x + m
	_screen.pt = pt
	_screen.safe = s
	_screen._fit()
	_place_coach()
	_place()


## The map under the screen's centre and the zoom: the content's transform, the marks redrawn.
func _place() -> void:
	if not _built:
		return
	ppm = clampf(ppm, _ppm_min(), _ppm_max())
	if bounds.has_area():
		centre = centre.clamp(bounds.position, bounds.end)
	for n: Node2D in [_land, _content]:
		n.scale = Vector2(ppm, ppm)
		n.position = _view() * 0.5 - centre * ppm
	# The roads' width in points grows a little as it zooms in (a third of the zoom's power), so
	# they read as bold lines far out and don't swamp the blocks close in: metres per point here.
	var ref := _view().y / START_M
	_mat.set_shader_parameter("widen", pt * pow(ppm / maxf(ref, 0.0001), 0.33) / ppm)
	_content.queue_redraw()  # the side streets come and go with the zoom
	_overlay.queue_redraw()


## A map point (m) on the screen (px).
func to_screen(p: Vector2) -> Vector2:
	return _view() * 0.5 + (p - centre) * ppm



## For checks: the map's parts in pixels (the QUESTS screen's own: quests_screen.gd `rects`).
func rects() -> Dictionary:
	if not _built:
		return {}
	var out := {"close": _close.get_global_rect(), "quests": _quests_btn.get_global_rect(), "clock": _clock_btn.get_global_rect(),
			"my_car": _car_btn.get_global_rect()}
	if _picker.visible:
		out["picker"] = _picker.get_global_rect()
	if _next.visible:
		out["next"] = _next.get_global_rect()
	if _note.visible:
		out["note"] = _note.get_global_rect()
	if _coach.visible:
		out["coach"] = _coach.get_global_rect()
	if _offer.visible:
		out["offer"] = _offer.get_global_rect()
	if _details.visible:
		out["details"] = _details.get_global_rect()
	if _badge.visible:
		out["badge"] = _badge.get_global_rect()
	if _screen.visible:
		out["screen"] = _screen.get_global_rect()
	return out


## Loop 3h slice 1: the districts to show (districts.gd `view()`) and the total per cent; call
## after open(). The fog is triangulated here once (the map is paused), so painting it is a few
## dozen triangles in the overlay's one batch (+0 draw calls).
## Loop 3h slice 2: `syrenki_total` > 0 adds one line, "Syrenki found/total", above the total.
func set_districts(view: Array[Dictionary], total: int, syrenki_found := 0, syrenki_total := 0) -> void:
	districts = view
	districts_total = total
	# The districts' pastels: built once (their shapes don't change; only the fog does).
	if _tint_key != view.size():
		_tint_key = view.size()
		_tint_mesh = MapArt.districts(view, outline)
		if _land != null:
			_land.queue_redraw()
	_fog = PackedVector2Array()
	var frame := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end,
			Vector2(bounds.position.x, bounds.end.y)])
	if outline.size() >= 3:
		frame = outline  # map north's L
	# F 2026-11-20 ("looks bad"): the fog was each unfound district alone, so two touching ones
	# darkened their overlap twice (the dark squares) and every edge was a hard line. Now the
	# districts are merged into one shape (one tone), and a few insets of it add a soft ramp.
	var found_polys: Array[PackedVector2Array] = []
	for d in districts:
		if d["found"]:
			for poly: PackedVector2Array in d["polys"]:
				found_polys.append(poly)
	var shapes: Array[PackedVector2Array] = []  # the merged unfound districts (the insets' source)
	var pieces: Array[PackedVector2Array] = []  # the fill: unfound minus the others minus the found, no overlap, no holes
	for d in districts:
		if d["found"]:
			continue
		for poly: PackedVector2Array in d["polys"]:
			var parts: Array[PackedVector2Array] = [poly]
			if bounds.has_area():
				parts = Geometry2D.intersect_polygons(poly, frame)
			for part in parts:
				var fresh: Array[PackedVector2Array] = [part]
				for e in pieces:
					fresh = _minus_all(fresh, e)
				pieces.append_array(fresh)
				shapes.append(part)
	shapes = _union_all(shapes)
	for f in found_polys:  # a found district is never under fog, even one the unfound ones surround
		pieces = _minus_all(pieces, f)
	for piece in pieces:
		for i in Geometry2D.triangulate_polygon(piece):
			_fog.append(piece[i])
	_fog_soft.clear()
	for shape in shapes:
		if Geometry2D.is_polygon_clockwise(shape):
			continue  # a hole's outline, not a shape
		for step in FOG_RAMP:
			var rings: Array[PackedVector2Array] = []
			for ring in Geometry2D.offset_polygon(shape, -step, Geometry2D.JOIN_ROUND):
				if not Geometry2D.is_polygon_clockwise(ring):
					rings.append(ring)
			for f in found_polys:
				rings = _minus_all(rings, f)
			var inner := PackedVector2Array()
			for ring in rings:
				for i in Geometry2D.triangulate_polygon(ring):
					inner.append(ring[i])
			_fog_soft.append(inner)
	if not _built:
		return

## The shapes with every touching pair merged into one (repeat until none is left). A ring the
## merge closes round a hole comes back with the hole too: only the outline is kept (the hole is
## cut out again where the found districts are taken off).
static func _union_all(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = shapes.duplicate()
	var again := true
	while again:
		again = false
		for i in out.size():
			for j in range(i + 1, out.size()):
				var outers: Array[PackedVector2Array] = []
				for r in Geometry2D.merge_polygons(out[i], out[j]):
					if not Geometry2D.is_polygon_clockwise(r):
						outers.append(r)
				if outers.size() == 1:
					out[i] = outers[0]
					out.remove_at(j)
					again = true
					break
			if again:
				break
	return out


## Every shape of `shapes` minus `cut`, as solid outlines (no holes: triangulation has none).
static func _minus_all(shapes: Array[PackedVector2Array], cut: PackedVector2Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s in shapes:
		out.append_array(_minus(s, cut, 0))
	return out


## `s` minus `c`. When `c` lies inside `s` the result has a hole, which a triangle fill can't show:
## then `s` is cut in two along the line through `c`'s middle first, so `c` becomes a notch of each half.
static func _minus(s: PackedVector2Array, c: PackedVector2Array, depth: int) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var holey := false
	for r in Geometry2D.clip_polygons(s, c):
		if Geometry2D.is_polygon_clockwise(r):
			holey = true
		else:
			out.append(r)
	if not holey or depth >= 2:
		return out
	var lo := INF
	var hi := -INF
	for v in c:
		lo = minf(lo, v.y)
		hi = maxf(hi, v.y)
	var cy := (lo + hi) * 0.5
	var halves: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-1e7, -1e7), Vector2(1e7, -1e7), Vector2(1e7, cy), Vector2(-1e7, cy)]),
		PackedVector2Array([Vector2(-1e7, cy), Vector2(1e7, cy), Vector2(1e7, 1e7), Vector2(-1e7, 1e7)])]
	var res: Array[PackedVector2Array] = []
	for h in halves:
		for p in Geometry2D.intersect_polygons(s, h):
			if not Geometry2D.is_polygon_clockwise(p):
				res.append_array(_minus(p, c, depth + 1))
	return res


## The main line's star (INF: none), from the registry.
func _main_at() -> Vector2:
	return markers.where(MapMarkers.MAIN_STAR)


## The questlines' starts the map shows now (the registry's STORY layer by the rule table).
func _stories() -> Dictionary:
	return markers.shown(MapMarkers.Layer.STORY, MapMarkers.View.FULL_MAP, MapMarkers.context_of(focus, flying))



## 2026-11-17: the QUESTS screen's facts (quest_book.gd `tabs` reads them; main.gd gathers them on
## open) and the quest pin as main.gd keeps it ({} none; a place's pin is drawn and is the NEXT
## line's). Call after open().
func set_book(facts: Dictionary, pin := {}) -> void:
	book = facts
	quest_pick = pin if not pin.is_empty() and pin.get("at", Vector2.INF) != Vector2.INF and str(pin.get("action", "")) == "" else {}
	_rebuild()


## The tabs again from `book`, the NEXT line and the badge; the screen too while it is up.
func _rebuild() -> void:
	book["tracked"] = str(quest_pick.get("id", ""))
	tabs = QuestBook.tabs(book)
	next_info = _next_of()
	if not _built:
		return
	var n := QuestBook.new_count(book)
	_badge.text = str(n)
	_badge.visible = n > 0
	_next.visible = not next_info.is_empty()
	if _next.visible:
		var w: Array = next_info["words"]
		_next.text = Lang.pick(str(w[0]), str(w[1]))
		_style_next(Access.tint(next_info["colour"]), bool(next_info.get("tracked", false)))
	_screen.quit_what = quit_what
	_screen.now_entry = book.get("now", {})
	if _screen.visible:
		_screen.show_book(tabs)
	_fit()


## 2026-11-16: the main line's next step once First steps are done ([pl, en]; empty: none) and its
## place (INF: none), for the NEXT line. Call before `set_book`.
func set_next(words: Array, at := Vector2.INF) -> void:
	next_words = words
	next_at = at


## What the NEXT line says and does ({} nothing): the tracked place (gold; a tap looks at it), else
## the First step nearest (a tap pins its place, or opens QUESTS on a step without one), else the
## main line's next step (a tap looks at its place), else a questline that invited the player.
func _next_of() -> Dictionary:
	var tr := _tracked()
	var nx: Array = QuestBook.words("next")
	if not tr.is_empty():
		var tw: Array = QuestBook.words("tracked")
		return {"words": ["◆ %s · %s · %s" % [tw[0], tr["pl"], Lines.far_text(car, tr["at"], true)],
				"◆ %s · %s · %s" % [tw[1], tr["en"], Lines.far_text(car, tr["at"], false)]],
				"colour": GOLD, "at": tr["at"], "entry": {}, "id": "", "tracked": true}
	for t: Dictionary in tabs:
		if str(t["key"]) != "steps":
			continue
		for it: Dictionary in t["items"]:
			if bool(it["done"]):
				continue
			var e: Dictionary = {}
			for b: Dictionary in it["buttons"]:
				if str(b["key"]) == "map":
					e = b["entry"]
			var sub: Array = it["sub"]
			return {"words": ["%s · %s · %s" % [nx[0], it["title"][0], sub[0]], "%s · %s · %s" % [nx[1], it["title"][1], sub[1]]],
					"colour": it["colour"], "at": it["at"], "entry": e, "id": str(it["id"])}
	if next_words.size() == 2 and str(next_words[1]) != "":
		return {"words": ["%s · %s" % [nx[0], next_words[0]], "%s · %s" % [nx[1], next_words[1]]], "colour": MainLine.COLOUR,
				"at": next_at, "entry": {}, "id": ""}
	for t: Dictionary in tabs:
		for it: Dictionary in t["items"]:
			if bool(it.get("new", false)):
				return {"words": ["%s · %s" % [nx[0], it["title"][0]], "%s · %s" % [nx[1], it["title"][1]]], "colour": it["colour"],
						"at": it["at"], "entry": {}, "id": str(it["id"])}
	return {}


func _style_next(col: Color, tracked: bool) -> void:
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		_next.add_theme_color_override(k, UiKit.ON_GOLD if tracked else UiKit.INK)
	# The kit: tracked is the gold PRIMARY, otherwise the card; the quest's own colour is gone
	# from the plate (its pin on the map carries it).
	var boxes := UiKit.button_boxes(UiKit.Kind.PRIMARY, pt) if tracked else {
		"normal": UiKit.card(pt, 0.0), "hover": UiKit.card(pt, 0.0), "pressed": UiKit.row(pt, true, 0.0)}
	boxes["focus"] = boxes["normal"]
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := (boxes[st] as StyleBoxFlat).duplicate() as StyleBoxFlat
		sb.content_margin_left = 12.0 * pt
		sb.content_margin_right = 12.0 * pt
		sb.content_margin_top = 4.0 * pt
		sb.content_margin_bottom = 4.0 * pt
		_next.add_theme_stylebox_override(st, sb)


## A tap on the NEXT line (the pad's X): the tracked place or the next goal is looked at; a First
## step's place becomes the pin; a step or questline with no place opens QUESTS on it.
func _next_tapped() -> void:
	if next_info.is_empty():
		return
	var e: Dictionary = next_info["entry"]
	if not e.is_empty():
		_pin(e)
	elif next_info["at"] != Vector2.INF:
		centre = next_info["at"]
		_place()
	elif str(next_info["id"]) != "":
		open_screen("", str(next_info["id"]))
	print("full map: next %s" % str(next_info["words"][1]))


## The QUESTS screen over the map, on tab `on` ("" the first) and item `item_id` ("" the first).
func open_screen(on := "", item_id := "") -> void:
	if not _built:
		return
	_unselect()
	_did_quests = true
	_coach.visible = false
	_screen.quit_what = quit_what
	_screen.now_entry = book.get("now", {})
	_screen.open(tabs, on, item_id)
	_screen._fit()
	print("full map: QUESTS on %s" % _screen.tab)


## Back from the QUESTS screen to the map.
func close_screen() -> void:
	_screen.close()
	print("full map: QUESTS closed")


## A button of the QUESTS screen: SHOW ON MAP pins the place and the map looks at it, STOP TRACKING
## lets the pin go, a request (START, CALL, a ride, the night) and a rival's RACE close the map and
## go to main.gd, the NOW line's SHOW looks at the target.
func _on_acted(key: String, e: Dictionary) -> void:
	match key:
		"map":
			close_screen()
			_pin(e)
		"untrack":
			_untrack()
		"race":
			print("full map: rival %d called out" % int(e.get("rung", -1)))
			rival_called.emit(int(e.get("rung", -1)))
			close()
		"notebook":
			print("full map: notebook %s" % str(e.get("target", "")))
			notebook.emit(str(e.get("target", "")))
			close()
		"now":
			close_screen()
			if e.get("at", Vector2.INF) != Vector2.INF:
				centre = e["at"]
				_place()
		_:
			print("full map: quest request %s" % str(e.get("id", "")))
			quest_picked.emit(e)
			close()


## `e`'s place becomes the quest pin (the route follows, main.gd) and the map looks at it.
func _pin(e: Dictionary) -> void:
	quest_pick = e
	_did_pin = true
	centre = e["at"]
	print("full map: quest pin %s at %.0f, %.0f" % [e["id"], e["at"].x, e["at"].y])
	quest_picked.emit(e)
	_rebuild()
	_place()


## The QUESTS screen looked at a NEW item: no longer new here (main.gd forgets it in the save).
func _on_seen(id: String) -> void:
	for s: Dictionary in book.get("stories", []):
		if "story_" + str(s["id"]) == id:
			s["new"] = false
	for t: Dictionary in tabs:  # in place: the screen's order and pick stay
		for it: Dictionary in t["items"]:
			if str(it["id"]) == id and bool(it["new"]):
				it["new"] = false
				t["new"] = maxi(0, int(t["new"]) - 1)
	var n := QuestBook.new_count(book)
	_badge.text = str(n)
	_badge.visible = n > 0
	seen.emit(id)


## QUIT on the screen's NOW line, tapped twice: the map closes and main.gd gives the run up.
func _quit_tapped() -> void:
	print("full map: quit quest %s" % str(quit_what[1] if quit_what.size() > 1 else ""))
	close()
	quit_quest.emit()


## --quest-tab=N (shots): the QUESTS screen on its N-th tab.
func show_tab(n: int) -> void:
	if n >= 0 and n < tabs.size():
		open_screen(str(tabs[n]["key"]))


## --quest-pick=N (tests, shots): the first button of item N of the first tab, as a tap would.
func pick_item(n: int) -> void:
	open_screen(QuestBook.first_tab(tabs))
	var list := _screen.items()
	if n < 0 or n >= list.size() or (list[n]["buttons"] as Array).is_empty():
		print("full map: no item %d to pick" % n)
		return
	_screen.select(n)
	var b: Dictionary = list[n]["buttons"][0]
	_on_acted(str(b["key"]), b["entry"])



## The tracked place ({} none): the pin, when it is a place (a request or a rival's call is no track).
func _tracked() -> Dictionary:
	if quest_pick.is_empty() or str(quest_pick.get("action", "")) != "" or quest_pick.get("at", Vector2.INF) == Vector2.INF:
		return {}
	return quest_pick


## The pin goes (STOP TRACKING; main.gd lets the track go).
func _untrack() -> void:
	if quest_pick.is_empty():
		return
	quest_pick = {}
	print("full map: track off")
	quest_picked.emit({})
	_rebuild()
	_place()


## The tapped mark's note and buttons go.
func _unselect() -> void:
	_unknown_sel = ""
	_story_sel = ""
	_sel_at = Vector2.INF
	if _offer != null:
		_offer.visible = false
		_details.visible = false


## A short tap on a "?" mark: the First step's teaser line, and TRACK (the pin is its place).
func _tap_unknown(at: Vector2) -> bool:
	var v := markers.shown(MapMarkers.Layer.UNKNOWN, MapMarkers.View.FULL_MAP, MapMarkers.context_of(focus, flying))
	var best := -1
	var best_d := 20.0 * pt
	var v_at: PackedVector2Array = v["at"]
	for i in v_at.size():
		var d := to_screen(v_at[i]).distance_to(at)
		if d < best_d:
			best = i
			best_d = d
	if best < 0:
		return false
	_cancel_hold()
	_unselect()
	_unknown_sel = str((v["extra"][best] as Dictionary).get("step", ""))
	_sel_at = v_at[best]
	_offer.text = Hints.words_of("track_offer")
	_offer.visible = _tracked().get("id", "") != "unknown_" + _unknown_sel
	_say(MapTrack.teaser(_unknown_sel))
	_note_t = 6.0
	print("full map: ? %s" % _unknown_sel)
	return true


## A short tap on a questline's dot (F 2026-11-08, 2026-11-17): its name and line, ROUTE (its start
## becomes the pin) and DETAILS (the QUESTS screen on it).
func _tap_story(at: Vector2) -> bool:
	var best := -1
	var best_d := 18.0 * pt
	var stories := _stories()
	var story_at: PackedVector2Array = stories["at"]
	for i in story_at.size():
		var d := to_screen(story_at[i]).distance_to(at)
		if d < best_d and (stories["extra"][i] as Dictionary).has("blurb"):
			best = i
			best_d = d
	if best < 0:
		return false
	_cancel_hold()
	_unselect()
	var e: Dictionary = stories["extra"][best]
	_story_sel = str(e.get("id", ""))
	_sel_at = story_at[best]
	var text := str(e.get("name", "")) + " · " + str(e.get("blurb", ""))
	var rw: Array = QuestBook.words("b_route")
	_offer.text = Lang.pick(str(rw[0]), str(rw[1]))
	_offer.visible = _story_sel != "" and _tracked().get("id", "") != "start_" + _story_sel
	_details.visible = _story_sel != "" and not QuestBook.find(tabs, "story_" + _story_sel)[0].is_empty()
	_did_pin = true
	_say([text, text])
	_note_t = 6.0
	print("full map: dot %s" % _story_sel)
	return true


## The gold button under a tapped mark: TRACK on a "?" (the First step's place becomes the pin),
## ROUTE on a questline's dot (its start does).
func _offer_tapped() -> void:
	var e: Dictionary = {}
	if _unknown_sel != "":
		e = MapTrack.entry_of(_unknown_sel, _sel_at)
	elif _story_sel != "":
		var f := QuestBook.find(tabs, "story_" + _story_sel)
		if not str(f[0]).is_empty():
			for t: Dictionary in tabs:
				if str(t["key"]) == str(f[0]):
					for b: Dictionary in t["items"][int(f[1])]["buttons"]:
						if str(b["key"]) == "map":
							e = b["entry"]
		if e.is_empty():
			e = Lines.entry("start_" + _story_sel, "story", Lines.Line.STORY, _story_sel, _story_sel, _sel_at, Lines.STORY_COLOUR)
	if e.is_empty():
		return
	_unselect()
	_note.visible = false
	_pin(e)
	_fit()


## DETAILS under a tapped dot: the QUESTS screen on that questline.
func _details_tapped() -> void:
	var id := _story_sel
	_note.visible = false
	if id != "":
		open_screen("", "story_" + id)


func _paint() -> void:
	var o := _overlay
	var view := Rect2(Vector2.ZERO, _view()).grow(20.0 * pt)
	hud._tri_begin()
	# Loop 3h slice 1: the districts not discovered yet, under a light fog.
	var fog := Color(0.12, 0.13, 0.2, FOG_A0)
	for i in range(0, _fog.size() - 2, 3):
		hud._tri(to_screen(_fog[i]), to_screen(_fog[i + 1]), to_screen(_fog[i + 2]), fog, fog, fog)
	var fog_step := Color(0.12, 0.13, 0.2, FOG_A_STEP)
	for tris in _fog_soft:
		for i in range(0, tris.size() - 2, 3):
			hud._tri(to_screen(tris[i]), to_screen(tris[i + 1]), to_screen(tris[i + 2]), fog_step, fog_step, fog_step)
	# The landmarks, printed small on the map (no pins since 2026-11-07): the most important first;
	# one that would touch one already drawn is left out (they come back as it zooms in).
	var r := ICON_R * pt
	var shown: Array[Vector2] = []
	var named: Array[Dictionary] = []
	var close_in := _view().y / ppm <= NAMES_M
	for ic in icons:
		if str(ic["shape"]) == "hospital" and not hospitals:
			continue
		if str(ic["shape"]) == "metro":
			continue  # F 2026-11-17: "what for the metro?": off the full map
		var tip := to_screen(ic["at"])
		if not view.grow(r * 2.0).has_point(tip):
			continue
		var c := tip
		var crowded := false
		for q in shown:
			if q.distance_to(c) < r * 1.7:
				crowded = true
				break
		if crowded:
			continue
		shown.append(c)
		# F (2026-11-07): printed on the map, quiet (no pins); fainter still while a quest runs.
		MapIcons.paint_quiet(hud, ic["shape"], ic["colour"], c, r, 0.5 if focus else 0.9)
		if close_in:
			named.append(ic)
	# The side quests' places to start one: squares in their job's colour.
	# F 2026-11-08: fewer pins, the street jobs show only zoomed in.
	var ctx := MapMarkers.context_of(focus, flying)
	var jobs := markers.shown(MapMarkers.Layer.JOB, MapMarkers.View.FULL_MAP, ctx)
	var job_at: PackedVector2Array = jobs["at"]
	var job_group: PackedStringArray = jobs["group"]
	for i in (job_at.size() if close_in else 0):
		var at := to_screen(job_at[i])
		if view.has_point(at):
			hud.poi_mark(at, 5.2 * pt, (jobs["colour"] as PackedColorArray)[i], (jobs["shape"] as PackedInt32Array)[i])
	for q in found:
		var at := to_screen(q)
		if view.has_point(at):
			hud._tri_fan(at, 4.2 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 3.0 * pt, 0.0, TAU, GOLD)
	# F 2026-11-08: the "?" marks of the places not found yet are gone from the map.
	if scene_mark != Vector2.INF:
		var at := to_screen(scene_mark)
		if view.has_point(at):
			hud._tri_fan(at, 4.4 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 3.2 * pt, 0.0, TAU, hud.SCENE_AMBER)
	# The questlines' starts: the "!" badges, bigger than any street job's icon; F 2026-11-17: always
	# on the full map, faint while something runs (quest focus).
	var stories := markers.shown(MapMarkers.Layer.STORY, MapMarkers.View.FULL_MAP, ctx)
	var story_at: PackedVector2Array = stories["at"]
	var story_k := FOCUS_DIM if focus else 1.0
	for i in story_at.size():
		var at := to_screen(story_at[i])
		if view.has_point(at):
			var small := bool((stories["extra"][i] as Dictionary).get("small", false))
			hud.story_badge(at, (1.4 if small else 2.3) * maxf(story_k, 0.65), (stories["colour"] as PackedColorArray)[i])
	var service := markers.shown(MapMarkers.Layer.SERVICE, MapMarkers.View.FULL_MAP, ctx)
	for i in (service["at"] as PackedVector2Array).size():
		var g := to_screen((service["at"] as PackedVector2Array)[i])
		if view.has_point(g):
			var sshape := (service["shape"] as PackedInt32Array)[i]
			if sshape == MapIcons.POI_MUG:
				hud.poi_mark(g, 6.0 * pt, (service["colour"] as PackedColorArray)[i], sshape)
			else:
				hud._tri_diamond(g, 6.5 * pt, (service["colour"] as PackedColorArray)[i])
	# Loop 3h slice 3's diamond at the final's start is the main line's star now.
	var targets := markers.shown(MapMarkers.Layer.TARGET, MapMarkers.View.FULL_MAP, ctx)
	for i in (targets["at"] as PackedVector2Array).size():
		# F 2026-11-08: the quest taken, strongly: a dotted line from the car, the glowing pin; off
		# the screen it waits at the edge on the way to it (the registry's TARGET mark, TD-13).
		var tp := to_screen((targets["at"] as PackedVector2Array)[i])
		var tc := Access.tint((targets["colour"] as PackedColorArray)[i])  # colour-safe (access.gd)
		var inner_t := Rect2(Vector2.ZERO, _view()).grow(-24.0 * pt)
		var road := _route_to(tp)
		if road.size() >= 2:
			_dotted_path(road, Rect2(Vector2.ZERO, _view()), tc)  # by road (target_route.gd, TD-13 step 4)
		else:
			_dotted(to_screen(car), tp.clamp(inner_t.position, inner_t.end), tc)
		hud.active_pin(tp.clamp(inner_t.position, inner_t.end), 2.0 if inner_t.has_point(tp) else 1.4, tc)
	# 2026-11-16: the "?" of a First step not done (map_track.gd): a gold disc, its "?" written below.
	var unknown := markers.shown(MapMarkers.Layer.UNKNOWN, MapMarkers.View.FULL_MAP, ctx)
	var unknown_at: PackedVector2Array = unknown["at"]
	for i in unknown_at.size():
		var at := to_screen(unknown_at[i])
		if view.has_point(at):
			hud._tri_fan(at, 9.0 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 7.4 * pt, 0.0, TAU, (unknown["colour"] as PackedColorArray)[i])
	var tracked := _tracked()
	if not tracked.is_empty():
		# The tracked place: a gold ring round the pin (the one gold mark; the active pin and the road
		# line are the registry's TARGET mark, drawn above).
		var tp := to_screen(tracked["at"])
		if view.has_point(tp):
			var ring := 0.75 + 0.25 * sin(float(Time.get_ticks_msec()) * 0.005)
			hud._tri_fan(tp, 15.0 * pt * ring, 0.0, TAU, Color(GOLD.r, GOLD.g, GOLD.b, 0.35))
			hud._tri_fan(tp, 11.0 * pt, 0.0, TAU, Color(GOLD.r, GOLD.g, GOLD.b, 0.9))
	if quest_pick.get("at", Vector2.INF) != Vector2.INF:
		hud.side_pin(to_screen(quest_pick["at"]), 1.9, Access.tint(quest_pick["colour"]))  # G12: the quest pin
	var main_at := _main_at()
	if main_at != Vector2.INF:
		# The main line's star; off the screen it waits at the edge, smaller, on the way to it.
		var mp := to_screen(main_at)
		var inner := Rect2(Vector2.ZERO, _view()).grow(-24.0 * pt)
		if inner.has_point(mp):
			hud.main_star(mp, 2.2, focus)
		else:
			hud.main_star(mp.clamp(inner.position, inner.end), 1.4, focus)
	var c := to_screen(car)
	var d := Vector2(-sin(car_yaw), -cos(car_yaw))
	var side := Vector2(-d.y, d.x)
	var tip := c + d * 9.0 * pt
	var notch := c - d * 3.0 * pt
	hud._tri_fan(c, 11.0 * pt, 0.0, TAU, hud.OUTLINE)
	hud._tri_fan(c, 9.5 * pt, 0.0, TAU, Color(1, 1, 1, 0.95))
	hud._tri(tip, c - d * 6.0 * pt + side * 6.0 * pt, notch, ARROW, ARROW, ARROW)
	hud._tri(tip, notch, c - d * 6.0 * pt - side * 6.0 * pt, ARROW, ARROW, ARROW)
	if Gamepad.in_use():
		# The gamepad follow-ups: the cross A teleports to (in the batch: +0 draw calls).
		var m := _view() * 0.5
		for arm: Vector2 in [Vector2(1, 0), Vector2(0, 1)]:
			var a := arm * 10.0 * pt
			var w := Vector2(arm.y, arm.x)
			for pair: Array in [[2.4, hud.OUTLINE], [1.0, Color(1, 1, 1, 0.95)]]:
				var t: Vector2 = w * float(pair[0]) * pt
				var col: Color = pair[1]
				hud._tri_quad(m - a - t, m + a - t, m + a + t, m - a + t, [col, col, col, col])
	# The hold: a ring filling round the finger, a pin in it.
	if _hold_index >= 0 and _hold_t > 0.08:
		var k := clampf(_hold_t / HOLD_S, 0.0, 1.0)
		var h := _hold_at
		var r0 := 26.0 * pt
		var r1 := 31.0 * pt
		var n := 40
		for i in n:
			var u := Vector2.from_angle(-PI * 0.5 + TAU * i / n)
			var v := Vector2.from_angle(-PI * 0.5 + TAU * (i + 1) / n)
			var col := GOLD if float(i) / n < k else Color(0.1, 0.09, 0.14, 0.55)
			hud._tri_quad(h + u * r0, h + u * r1, h + v * r1, h + v * r0, [col, col, col, col])
		hud._tri_fan(h, 4.0 * pt, 0.0, TAU, hud.OUTLINE)
		hud._tri_fan(h, 2.6 * pt, 0.0, TAU, GOLD)
	var legend := _legend_rows()
	_legend_marks(legend)
	hud._tri_flush(o)
	var font := ThemeDB.fallback_font
	_legend_text(o, font, legend)
	var qs := _px(T_SUB + 3.0)
	for i in unknown_at.size():
		var at := to_screen(unknown_at[i])
		if view.has_point(at):
			var qw := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs).x
			o.draw_string(font, at + Vector2(-qw * 0.5, qs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs, UiKit.ON_GOLD)
	# Loop 3h slice 1: each discovered district's name and per cent at its label: big, spaced
	# capitals in its own tint's deep shade, a cream outline.
	var fs := _px(T_TITLE)
	var rim := Color(1.0, 0.98, 0.93, 0.95)
	# Far out the names step down a size; one that would run into a name already written is left
	# out (it comes back as it zooms in).
	if _view().y / ppm > NAMES_M:
		fs = _px(T_SUB + 1.0)
	var taken: Array[Rect2] = [_legend_rect(legend).grow(4.0 * pt)]  # no name is printed under the legend card
	for i in districts.size():
		var dd := districts[i]
		if not dd["found"]:
			continue
		var at := to_screen(dd["at"])
		if not view.has_point(at):
			continue
		var name := " ".join(str(dd["name_pl"]).to_upper().split(""))
		var nw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(at + Vector2(-nw * 0.5, -fs * 1.1), Vector2(nw, fs * 2.3))
		var clash := false
		for q in taken:
			if q.intersects(box):
				clash = true
				break
		if clash:
			continue
		taken.append(box)
		var ink := MapArt.tint(i).darkened(0.62)
		for row: Array in [[name, -0.15, fs], ["%d%%" % dd["pct"], 1.0, _px(T_SUB)]]:
			var text: String = row[0]
			var size: int = row[2]
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var p := at + Vector2(-w * 0.5, fs * float(row[1]))
			o.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, _px(5), rim)
			o.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
	# The pins' names, close in.
	var ns := _px(T_SUB)
	# The questlines' names under their badges (any zoom: there are few; a clash leaves one out).
	for i in story_at.size():
		var text := str((stories["extra"][i] as Dictionary).get("name", ""))
		if text == "":
			continue
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		var p := to_screen(story_at[i]) + Vector2(-w * 0.5, 21.0 * pt + ns)
		var box := Rect2(p - Vector2(0.0, ns), Vector2(w, ns * 1.3)).grow(2.0 * pt)
		if not view.has_point(p):
			continue
		var clash := false
		for q in taken:
			if q.intersects(box):
				clash = true
				break
		if clash:
			continue
		taken.append(box)
		var col := Access.tint((stories["colour"] as PackedColorArray)[i])
		var a := FOCUS_DIM if focus else 1.0
		o.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, _px(5), Color(0.11, 0.1, 0.14, 0.95 * a))
		o.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, Color(col.lightened(0.35), a))
	# The service marks' names (THE TAPCZAN's mug, any zoom): coloured text like the badges' names.
	var svc := markers.shown(MapMarkers.Layer.SERVICE, MapMarkers.View.FULL_MAP, ctx)
	for i in (svc["at"] as PackedVector2Array).size():
		var text := str((svc["extra"][i] as Dictionary).get("name", ""))
		if text == "":
			continue
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		var p := to_screen((svc["at"] as PackedVector2Array)[i]) + Vector2(-w * 0.5, 10.0 * pt + ns)
		var box := Rect2(p - Vector2(0.0, ns), Vector2(w, ns * 1.3)).grow(2.0 * pt)
		if not view.has_point(p):
			continue
		taken.append(box)
		var col := Access.tint((svc["colour"] as PackedColorArray)[i])
		o.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, _px(5), Color(0.11, 0.1, 0.14, 0.95))
		o.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, col.lightened(0.35))
	for ic in named:
		var text: String = ic["pl"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		var p := to_screen(ic["at"]) + Vector2(-w * 0.5, ICON_R * pt * 0.85 + ns)
		var box := Rect2(p - Vector2(0.0, ns), Vector2(w, ns * 1.3)).grow(2.0 * pt)
		var clash := false
		for q in taken:
			if q.intersects(box):
				clash = true
				break
		if clash:
			continue
		taken.append(box)
		# Printed like a map's own labels: dark ink in a cream outline (quieter than the quests' names).
		o.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, _px(4), Color(1.0, 0.97, 0.9, 0.85))
		o.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns, Color(0.16, 0.14, 0.2, 0.95))


## F (2026-11-19): a small legend bottom left, so the marks read at a glance and the hold to jump is
## said once, quietly: the main quest's star, a questline's "!", a side job's square, and the hold.
## Rows: {"words": [pl, en], "kind": "main"|"story"|"job"|"hold"}. Drawn in the batch (no node).
func _legend_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for pair: Array in [["main", "legend_main"], ["story", "legend_story"], ["job", "legend_job"]]:
		rows.append({"kind": pair[0], "words": QuestBook.words(pair[1])})
	var hw: Array = QuestBook.words("legend_hold_pad" if Gamepad.in_use() else "legend_hold")
	if Gamepad.in_use():
		hw = [Gamepad.fmt(str(hw[0])), Gamepad.fmt(str(hw[1]))]
	rows.append({"kind": "hold", "words": hw})
	return rows


## The legend's box in px: bottom left of the safe area, as wide as its longest line.
func _legend_rect(rows: Array[Dictionary]) -> Rect2:
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB - 1.0)
	var w := 0.0
	for r in rows:
		var t := Lang.pick(str(r["words"][0]), str(r["words"][1]))
		w = maxf(w, font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var size := Vector2(w + 44.0 * pt, rows.size() * LEGEND_ROW * pt + 12.0 * pt)
	var m := 8.0 * pt
	return Rect2(Vector2(s.position.x + m, s.end.y - m - size.y), size)


func _legend_marks(rows: Array[Dictionary]) -> void:
	var box := _legend_rect(rows)
	hud._tri_rect(box, UiKit.CARD)  # the dark card (F 2026-11-19: dark cards everywhere)
	var edge := UiKit.EDGE
	var ew := maxf(1.0, pt)
	hud._tri_rect(Rect2(box.position, Vector2(box.size.x, ew)), edge)
	hud._tri_rect(Rect2(box.position + Vector2(0, box.size.y - ew), Vector2(box.size.x, ew)), edge)
	hud._tri_rect(Rect2(box.position, Vector2(ew, box.size.y)), edge)
	hud._tri_rect(Rect2(box.position + Vector2(box.size.x - ew, 0), Vector2(ew, box.size.y)), edge)
	for i in rows.size():
		var at := box.position + Vector2(17.0 * pt, 6.0 * pt + (i + 0.5) * LEGEND_ROW * pt)
		match str(rows[i]["kind"]):
			"main":
				hud.main_star(at, 1.0, true)
			"story":
				hud._tri_fan(at, 5.6 * pt, 0.0, TAU, hud.OUTLINE)
				hud._tri_fan(at, 4.6 * pt, 0.0, TAU, Color(1, 1, 1, 0.97))
				hud._tri_fan(at, 3.6 * pt, 0.0, TAU, Color("#e0527a"))
				var w := 1.2 * pt
				hud._tri_rect(Rect2(at + Vector2(-w * 0.5, -2.4 * pt), Vector2(w, 2.8 * pt)), Color.WHITE)
				hud._tri_rect(Rect2(at + Vector2(-w * 0.5, 1.2 * pt), Vector2(w, w)), Color.WHITE)
			"job":
				hud.poi_mark(at, 4.6 * pt, Color("#ff8a3d"), MapIcons.POI_SQUARE)
			"hold":
				for j in 24:
					var u := Vector2.from_angle(TAU * j / 24.0)
					var v := Vector2.from_angle(TAU * (j + 1) / 24.0)
					var col := Color(GOLD, 0.95 if j < 16 else 0.35)
					hud._tri_quad(at + u * 4.4 * pt, at + u * 6.4 * pt, at + v * 6.4 * pt, at + v * 4.4 * pt, [col, col, col, col])
				hud._tri_fan(at, 2.0 * pt, 0.0, TAU, GOLD)


func _legend_text(o: Control, font: Font, rows: Array[Dictionary]) -> void:
	var box := _legend_rect(rows)
	var fs := _px(T_SUB - 1.0)
	for i in rows.size():
		var t := Lang.pick(str(rows[i]["words"][0]), str(rows[i]["words"][1]))
		var y := box.position.y + 6.0 * pt + (i + 0.5) * LEGEND_ROW * pt + fs * 0.35
		var col := UiKit.GOLD if str(rows[i]["kind"]) == "hold" else UiKit.INK
		o.draw_string(font, Vector2(box.position.x + 32.0 * pt, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## The map point (m) under a screen point (px).
func to_map(p: Vector2) -> Vector2:
	return centre + (p - _view() * 0.5) / ppm


## A spot the car may go to: inside the outline (map north's L).
func on_map(p: Vector2) -> bool:
	if outline.size() >= 3:
		return Geometry2D.is_point_in_polygon(p, outline)
	return bounds.has_point(p)



func _process(dt: float) -> void:
	if not visible:
		return
	_coach_frame(dt)
	if _note_t > 0.0:
		_note_t -= dt
		if _note_t <= 0.0:
			_note.visible = false
			_unselect()
			_fit()
	if _screen.visible:
		return  # the screen is over the map: no pan, no hold, no pulse under it
	_pad_frame(dt)
	if (_main_at() != Vector2.INF or markers.has(MapMarkers.ACTIVE_TARGET) or not quest_pick.is_empty()) and _hold_index < 0:
		_overlay.queue_redraw()  # the star's and the active pin's rings pulse (one batch, the game paused under it)
	if _hold_index < 0:
		return
	_hold_t += dt
	if _hold_t >= HOLD_S:
		_finish_hold()
	_overlay.queue_redraw()


## The coach marks (hints.gd `map_tick`) while the map is open: tap QUESTS, tap a questline's dot,
## hold a spot; each goes when the player does it. The game is paused under the map, so the words
## are a card of the map's own (`_coach`), not hud.gd's spotlight. Off for a run without hints (the
## bench, the demo, --no-hints) and under the QUESTS screen.
func _coach_frame(dt: float) -> void:
	if hints == null or not _built or hints.off:
		_coach.visible = false
		return
	var dots := (_stories()["at"] as PackedVector2Array).size() > 0
	var f := {"has_book": not tabs.is_empty(), "has_story": dots, "screen": _screen.visible,
			"did_quests": _did_quests, "did_hold": _did_hold, "did_pin": _did_pin}
	var before := hints.coach
	var id := hints.map_tick(dt, f)
	if id != before:
		_did_quests = false  # a mark waits for the thing done after it came up
		_did_hold = false
		_did_pin = false
	_place_coach()
	if _coach.visible:
		_coach.modulate.a = 0.82 + 0.18 * sin(float(Time.get_ticks_msec()) * 0.006)


## The coach mark's card: over QUESTS for QUESTS, under the NEXT line for the dots, bottom centre for
## the hold.
func _place_coach() -> void:
	var id := hints.coach if hints != null else ""
	_coach.visible = id != "" and _built and not _screen.visible and not _picker.visible
	if not _coach.visible:
		return
	var lbl := (_coach.get_child(0) as VBoxContainer).get_child(0) as Label
	lbl.text = Hints.words_of(id) + (" ↓" if id == "map_quests" else "")
	_coach.size = _coach.get_combined_minimum_size()
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var m := 8.0 * pt
	var at := Vector2(s.position.x + (s.size.x - _coach.size.x) * 0.5, s.end.y - m - _coach.size.y)
	match id:
		"map_quests":
			at = Vector2(_quests_btn.position.x + _quests_btn.size.x - _coach.size.x, _quests_btn.position.y - m - _coach.size.y)
		"map_pin":
			at.y = s.position.y + m + NEXT_H * pt + m
	if _note.visible and id == "map_hold":
		at.y = _note.position.y - m - _coach.size.y - (56.0 * pt if _offer.visible else 0.0)
	at.x = clampf(at.x, s.position.x + m, maxf(s.position.x + m, s.end.x - m - _coach.size.x))
	at.y = clampf(at.y, s.position.y + m, maxf(s.position.y + m, s.end.y - m - _coach.size.y))
	_coach.position = at


## The gamepad follow-ups: the stick pans, RT / LT zoom about the centre (the cross); a move
## cancels A's hold, as a drag cancels a finger's.
func _pad_frame(dt: float) -> void:
	var s := Gamepad.stick()
	var z := Gamepad.climb()
	if s == Vector2.ZERO and absf(z) < 0.05:
		return
	if s != Vector2.ZERO:
		centre += s * PAD_PAN * pt * dt / ppm
	if absf(z) >= 0.05:
		ppm = clampf(ppm * exp(z * PAD_ZOOM * dt), _ppm_min(), _ppm_max())
	if _hold_index == PAD_HOLD:
		_cancel_hold()
	_place()


## The hold began at `at` (px): a refusal shows at once (no ring) when a teleport isn't allowed.
func _start_hold(index: int, at: Vector2) -> void:
	_hold_index = -1
	if not on_map(to_map(at)):
		return
	_did_hold = true
	var why: Array = can_teleport.call() if can_teleport.is_valid() else []
	if not why.is_empty():
		_say(why)
		return
	_hold_index = index
	_hold_at = at
	_hold_t = 0.0


func _cancel_hold() -> void:
	if _hold_index >= 0:
		_hold_index = -1
		_overlay.queue_redraw()


func _finish_hold() -> void:
	var p := to_map(_hold_at)
	_hold_index = -1
	last_teleport = p
	print("full map: teleport to %.0f, %.0f" % [p.x, p.y])
	teleport.emit(p)
	close()


## The note card above the hint: [pl, en], for 2.5 s.
func _say(lines: Array) -> void:
	var box: VBoxContainer = _note.get_child(0)
	(box.get_child(0) as Label).text = Lang.pick(str(lines[0]), str(lines[1]) if lines.size() > 1 else "")
	(box.get_child(1) as Label).text = ""
	(box.get_child(1) as Label).visible = false
	_note.visible = true
	_note_t = 2.5
	_fit()


## A dotted line from `a` to `b` (px) in `colour`, a dark-rimmed square every 9 pt (the
## active quest's way on the full map; into the overlay's batch).
## The HUD's road route (the activity's own or target_route.gd's) on the screen, from the car to the
## target at `tp` (empty: none, or it doesn't end near the target: the straight line then).
func _route_to(tp: Vector2) -> PackedVector2Array:
	var pts: PackedVector2Array = hud.minimap_route() if hud != null and hud.has_method("minimap_route") else PackedVector2Array()
	if pts.size() < 2 or to_screen(pts[pts.size() - 1]).distance_to(tp) > 40.0 * pt:
		return PackedVector2Array()
	var out := PackedVector2Array([to_screen(car)])
	for p in pts:
		out.append(to_screen(p))
	return out


## Dots along a polyline (screen points), one every 9 pt across its joins, only those inside `view`.
func _dotted_path(pts: PackedVector2Array, view: Rect2, colour: Color) -> void:
	var gap := 9.0 * pt
	var half := 1.8 * pt
	var u := gap
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var len := a.distance_to(b)
		while u < len:
			var p := a.lerp(b, u / len)
			if view.has_point(p):
				hud._tri_rect(Rect2(p - Vector2.ONE * (half + 0.9 * pt), Vector2.ONE * (half + 0.9 * pt) * 2.0), hud.OUTLINE)
				hud._tri_rect(Rect2(p - Vector2.ONE * half, Vector2.ONE * half * 2.0), colour)
			u += gap
		u -= len


func _dotted(a: Vector2, b: Vector2, colour: Color) -> void:
	var len := a.distance_to(b)
	var gap := 9.0 * pt
	if len < gap * 2.0:
		return
	var half := 1.8 * pt
	var u := gap
	while u < len - gap:
		var p := a.lerp(b, u / len)
		hud._tri_rect(Rect2(p - Vector2.ONE * (half + 0.9 * pt), Vector2.ONE * (half + 0.9 * pt) * 2.0), hud.OUTLINE)
		hud._tri_rect(Rect2(p - Vector2.ONE * half, Vector2.ONE * half * 2.0), colour)
		u += gap



# --- gestures ------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _screen.visible:
		# The QUESTS screen is up: Esc, back and the pad's B go back to the map; its pad buttons and
		# its drags go to it; its buttons take their taps themselves.
		if (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE) \
				or Gamepad.closes(event):
			close_screen()
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed \
				and _screen.pad((event as InputEventJoypadButton).button_index):
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch or event is InputEventScreenDrag:
			_screen.touch(event)
		return
	if (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE) \
			or Gamepad.closes(event):  # the gamepad loop: B, Start or Back
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed \
			and (event as InputEventJoypadButton).button_index in [JOY_BUTTON_Y, JOY_BUTTON_X]:
		if (event as InputEventJoypadButton).button_index == JOY_BUTTON_Y:
			open_screen()  # 2026-11-17: Y opens QUESTS
		else:
			_next_tapped()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A:
		# The gamepad follow-ups: A held is a finger held on the cross.
		if event.is_pressed() and _hold_index < 0:
			_start_hold(PAD_HOLD, _view() * 0.5)
		elif not event.is_pressed() and _hold_index == PAD_HOLD:
			_cancel_hold()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			for b: Control in [_close, _clock_btn, _picker, _quests_btn, _next, _offer, _details]:
				if b.visible and b.get_global_rect().has_point(t.position):
					return  # the button takes it
			_touches[t.index] = t.position
			if _touches.size() == 1:
				_tap_at = t.position
				_tap_ms = Time.get_ticks_msec()
				_start_hold(t.index, t.position)
			else:
				_cancel_hold()  # a second finger: a pinch
		else:
			if _touches.size() == 1 and _tap_at != Vector2.INF and t.position.distance_to(_tap_at) <= HOLD_SLOP * pt \
					and Time.get_ticks_msec() - _tap_ms < 350:
				if not _tap_story(t.position):
					_tap_unknown(t.position)
			_tap_at = Vector2.INF
			_touches.erase(t.index)
			if t.index == _hold_index:
				_cancel_hold()  # let go too soon
		_pinch = _span()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if not _touches.has(d.index):
			return
		if d.index == _hold_index and d.position.distance_to(_hold_at) > HOLD_SLOP * pt:
			_cancel_hold()  # a drag: a pan
		if _touches.size() == 1:
			centre -= (d.position - _touches[d.index]) / ppm
			_touches[d.index] = d.position
		else:
			var before := _mid()
			_touches[d.index] = d.position
			var span := _span()
			if _pinch > 0.0 and span > 0.0:
				zoom_at(span / _pinch, _mid())
			centre -= (_mid() - before) / ppm
			_pinch = span
		_place()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(1.15, b.position)
		elif b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(1.0 / 1.15, b.position)


## Zooms by `ratio` keeping the map point under `at` (px) where it is.
func zoom_at(ratio: float, at: Vector2) -> void:
	var p := centre + (at - _view() * 0.5) / ppm
	ppm = clampf(ppm * ratio, _ppm_min(), _ppm_max())
	centre = p - (at - _view() * 0.5) / ppm
	_place()


func _span() -> float:
	if _touches.size() != 2:
		return 0.0
	var v: Array = _touches.values()
	return (v[0] as Vector2).distance_to(v[1])


func _mid() -> Vector2:
	var m := Vector2.ZERO
	for p: Vector2 in _touches.values():
		m += p
	return m / maxf(_touches.size(), 1.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		close()
