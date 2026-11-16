extends Control
## F's asks (2026-10-30; BACKLOG "From loop MW-1"): the full-screen map, opened by a tap on the
## minimap (hud.gd `map_pressed`; main.gd pauses the game under it, like the settings card). The
## map (since 2026-10-31 its own game-map style, below; one look day and night), north up and
## scaled to the screen: one finger pans, two pinch to zoom (the mouse wheel on a computer). On it
## the car's arrow, the mission target, the notebook's "?" marks (the places not found yet within
## the minimap's reach: never their names) and the places found (gold dots). The ✕, Esc or the
## Android back gesture close it. Built the first time it opens; hidden it draws nothing (0 cost).
## Loop 3h slice 1 (DEMO G3): the districts (districts.gd `view`, given by `set_districts` after
## open): the ones not discovered yet under a light fog, each discovered one's name and per cent
## at its label, and a card listing them all with the total (the districts' completion on the map).
## Loop 3h slice 3: the rival ladder's card on the right (DRABINKA · rival ladder: each rung with
## its stake, ★ beaten, → next and what it needs, · locked; the final's state), given by
## `set_ladder` after open, and the final's start marker (a diamond) once it is open at night.
## (First hour step 4: the ladder is the Rivals section of the one list now, below.)
## F's ask (2026-10-31, BACKLOG top): a game map, not a survey sheet. Its own meshes (map_art.gd:
## the land, the districts' pastels, the greens and water, bold roads by class, the bridges on top;
## built on the first open, three draw calls) and the landmarks' pin icons (map_icons.gd, in the
## overlay's one batch, the crowded ones left out by importance, their names when close in). Press
## and hold a spot (HOLD_S, the finger still) to teleport there: `teleport` is emitted and the map
## closes; main.gd puts the car on the nearest lane (the helicopter keeps its height).
## `can_teleport` says why not, when not (a race, a job, a rescue, the guide).
## G12 part 2 (F, 2026-11-01: car quests and heli quests "each with its own list"): the ZADANIA card
## on the right under the buttons, two tabs AUTO and HELI (the vehicle's own first), each listing
## what can be started now (quest_lines.gd `rows`: requests, then places nearest first with their
## distance and compass point). A tapped place centres the map on it and becomes the quest pin (a
## big pin in its colour here, the arrow and minimap dot in the city: main.gd); tapped again, the
## pin goes. A request (a ride, a rescue call) closes the map and starts. The ≡ cards take its place.
## First hour step 4 (the spec "First hour for the beta" section 3, the critique's point 7, F's yes
## 2026-11-15): the tabs are gone. The card is ONE scrolling list in sections (quest_lines.gd
## `sections`): TERAZ (only while something runs), PIERWSZE KROKI (the promise and the nearest
## First steps left, first_steps.gd), RYWALE (the six as one row of names, a tap calls one out; the
## final, and the night for it), W MIEŚCIE (one row per kind of job), ZNAJOMI (after the third First
## step) and KOLEKCJA (after the first find; a tap opens the ≡ cards).

signal closed
## G12 part 2: a row of the ZADANIA card was tapped (its entry, quest_lines.gd `entry`; {}: the
## pin was taken off).
signal quest_picked(entry: Dictionary)
## F (2026-11-08): the quest under way is to be dropped (the ZADANIA card's quit button, tapped
## twice). main.gd gives up whatever runs (hud's abort, as the status card's ✕ does).
signal quit_quest
## The hold's spot (map metres), when the hold was held to the end.
signal teleport(at: Vector2)
## First hour step 5 (The Six): a rival's row on the RYWALE card was tapped (its ladder.gd rung):
## main.gd calls that rival out (rivals.gd `call_out`) and the map closes.
signal rival_called(rung: int)

const Lang := preload("res://scripts/lang.gd")
const MapArt := preload("res://scripts/map_art.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const MainLine := preload("res://scripts/main_line.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const Access := preload("res://scripts/access.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
const Hints := preload("res://scripts/hints.gd")  # 2026-11-16: the map's coach marks
const MapTrack := preload("res://scripts/map_track.gd")  # 2026-11-16: track, filters, "?" marks
## The hold to teleport: this long, the finger within HOLD_SLOP points of where it went down.
const HOLD_S := 0.6
const HOLD_SLOP := 12.0
## The gamepad follow-ups: the left stick pans (points a second, the stick full over), RT / LT
## zoom in / out (e-folds a second), and holding A teleports to the cross at the screen's centre
## (the hold's "finger": PAD_HOLD).
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
const GOLD := Color("#f0b429")
const ARROW := Color("#d8432f")
## Type sizes in points (hud.gd's).
const T_TITLE := 17.0
const T_SUB := 13.0

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
## The main line (main_line.gd): its marker (the registry's MapMarkers.MAIN_STAR; none: no star)
## and goal line (hud.gd `set_main_goal`). On the map a big gold star in a pulsing ring (pinned to the screen's edge when off it); the side quests
## keep their colours: the active one a ringed dot, the places to start one (kebab stands, the
## station, the scooters: hud.gd's minimap squares) squares. A legend bottom left says which is which.
var main_pl := ""
var main_en := ""
## The map marker registry (map_markers.gd, TD-13; hud.gd hands its own over on open): the street
## jobs' places (JOB), the garage (SERVICE), the questlines' starts (STORY: each with its name in
## the language shown, its one-line description for a tap, `_tap_story`, and "small" for a smaller
## "!") and the main line's star (MAIN) come from it, by its rule table.
var markers := MapMarkers.new()
var _qdrag := -1
var _qdrag_px := 0.0
## F (2026-11-08): what is under way, [pl, en] (main.gd sets it on open; empty: nothing to quit).
## The card's quit button names it; the first tap arms it for QUIT_ARM s, the second quits.
var quit_what: Array = []
var _quit_armed := 0.0
const QUIT_ARM := 3.0
const QUIT_COLOUR := Color("#ff5a5a")
var _tap_at := Vector2.INF
var _tap_ms := 0
## Quest focus (a quest under way: the side places, the garage, the "?" marks and the starts stay
## off, the main star dims) and flying (the starts stay off): hud.gd sets both.
var focus := false
var flying := false
## F (2026-11-07): the hospitals only matter to a rescue; their marks show only while one is on
## (main.gd sets it on open).
var hospitals := false
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
## A refusal line shown for a moment (the time left, s).
var _note: PanelContainer
var _note_t := 0.0
## The main line's goal card (under the title) and the legend (bottom left; its icons are painted
## in the overlay's batch at `_legend_icons`' rects).
var _goal: PanelContainer
var _legend: PanelContainer
var _legend_icons: Array[Control] = []
## The legend's icons are drawn here, on top of its card (the overlay is under the cards).
var _legend_art: Control
## 2026-11-16 (map_track.gd): the legend's filter cells (a Button each, in KINDS' order) and its ALL
## cell; the kinds the player hid (id -> true, this session only, never saved).
var _legend_cells: Array[Button] = []
var _legend_all: Button
var _hidden := {}
## The "?" tapped now (the First step's id, "" none) and the TRACK button offered with its teaser.
var _unknown_sel := ""
var _unknown_at := Vector2.INF
var _offer: Button
## A legend cell's width (pt) and where its icon sits over it (pt from its left edge).
const LEGEND_W := 150.0
const LEGEND_ICON_X := 17.0
## The legend's rows: [Polish · English]; their icons in order: the star, the ringed dot, the
## kebab stand's badge, the station's triangle, the garage's diamond, the metro's pin. Each is
## the filter of the same index in map_track.gd KINDS.
const LEGEND := ["główny wątek · main line", "wątek: start · questline start", "zlecenie · side job", "kebab · kebab stand", "stacja · job station",
		"warsztat · garage", "metro · underground"]
## For checks: the last spot teleported to (INF: none).
var last_teleport := Vector2.INF
var _overlay: Control
var _head: PanelContainer
var _hint: PanelContainer
var _close: Button
## The ≡ button: shows or hides the districts' and the ladder's cards (hidden at first: the map is
## the point; F 2026-10-31, the game map). `cards_shown` is its state.
var _cards: Button
var cards_shown := false
var _has_list := false
var _touches := {}
var _pinch := 0.0
## Loop 3h slice 1: the fog's triangles (map points, three a triangle: the districts not
## discovered yet, clipped to the map's bounds) and the districts' card.
var _fog := PackedVector2Array()
var _list: PanelContainer
## Loop 3h slice 3: the ladder's card (top right, under the ✕).
## G12 part 2: the ZADANIA card, the quests given by `set_quests` (entries), the tab shown
## (Lines.Line) and the picked place (an entry; {} none). `quest_rows` is what the tab shows now.
var _quests: PanelContainer
var quest_entries: Array = []
var quest_line := 0
var quest_pick: Dictionary = {}
var quest_rows: Array = []
var _quest_buttons: Array[Button] = []
## G12b: the row the gamepad has picked out (-1: none; the D-pad moves it, Y takes it, X jumps to
## the next section). A is still the teleport hold, so the card never takes A.
var quest_pad := -1
## Row heights in points (MIN_TOUCH, 44 pt) and the list's width.
const ROW_H := 44.0
const QUEST_W := 236.0
## Its rows' colours: beaten, next, locked.
const LADDER_COLOURS := {"won": Color("#ffd23f"), "next": Color("#fbf7ee"), "open": Color("#fbf7ee"), "locked": Color("#8f88a0")}
## First hour step 4: what the one list shows besides the quests (each given after open by main.gd):
## the First steps left ({"id", "pl", "en", "entry"}), their header and the promise ([pl, en]);
## the rivals' chips (ladder.gd `chips`), the Rivals title, the final's line ([text, state]) and
## whether the night button shows; the Collection line ([pl, en]; empty: no find yet); and whether
## the Friends section is open (the third First step).
var steps_left: Array = []
var steps_head: Array = []
var promise: Array = []
var rival_chips: Array = []
var rivals_title: Array = []
var final_line: Array = []
var night_offer := false
var collection: Array = []
var friends_open := true
## The sections shown now (quest_lines.gd `sections`) and where each starts in `quest_rows` (the
## pad's X jumps to the next one).
var list_sections: Array = []
var _section_starts: Array[int] = []
## 2026-11-16 (map guidance, F's playtest of build 11): the NEXT card pinned above the list's scroll
## (`set_next`: after First steps, the main line's next step as [pl, en] and its place, INF none),
## Rivals folded to one row that opens to the six chips, a "more below" cue on the scroll, and the
## coach marks (hints.gd `map_tick`; `hints` is main.gd's, null in a check that wants none).
var next_words: Array = []
var next_at := Vector2.INF
var _next_card: PanelContainer
var _rivals_open := false
var _reveal_chips := false
var hints: Hints
var _coach: PanelContainer
var _help: Button
var _more: Control
var _more_label: Label
var _did_scroll := false
var _did_hold := false
var _did_pin := false
var _replay := false
## The "more below" fade is this tall (points).
const FADE_H := 30.0
## The rivals row's action (a tap folds or opens the six chips).
const RIVALS_TOGGLE := "rivals_toggle"
## The rivals' race colour (rivals.gd RACE_COLOUR) for the chips' rim.
const RIVAL_COLOUR := Color("#ff4f6d")
## A rival chip's width share (three to a row) and the gap between chips.
const CHIPS_PER_ROW := 3
## The list's scroll is never shorter than this many rows (a short screen still scrolls).
const LIST_MIN_ROWS := 2.0


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
	_head = _card([Lang.pick("MAPA WARSZAWY", "MAP OF WARSAW")], [T_TITLE])
	_head.name = "head"
	add_child(_head)
	_goal = _card(["", ""], [T_SUB, T_SUB])
	_goal.name = "goal"
	_goal.visible = false
	var gl: Label = _goal.get_child(0).get_child(0)
	gl.add_theme_color_override("font_color", MainLine.COLOUR)
	add_child(_goal)
	_legend = _card([], [])
	_legend.name = "legend"
	var lv: VBoxContainer = _legend.get_child(0)
	# 2026-11-16: the legend's rows are the filters: two columns of cells MIN_TOUCH tall (the icon
	# painted over the cell's left, its name, "n/total"), then ALL.
	var grid := GridContainer.new()
	grid.name = "legend_grid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(4.0 * pt))
	grid.add_theme_constant_override("v_separation", int(4.0 * pt))
	lv.add_child(grid)
	_legend_cells.clear()
	for i in LEGEND.size():
		var kind := str(MapTrack.KINDS[i]["id"])
		var cell := _legend_cell("legend_" + kind)
		cell.pressed.connect(_toggle_kind.bind(kind))
		grid.add_child(cell)
		_legend_cells.append(cell)
		_legend_icons.append(cell)
	_legend_all = _legend_cell("legend_all")
	_legend_all.pressed.connect(_toggle_kind.bind(""))
	grid.add_child(_legend_all)
	add_child(_legend)
	_legend_art = Control.new()
	_legend_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_legend_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend_art.draw.connect(_paint_legend)
	add_child(_legend_art)
	_hint = _card([Lang.pick("Przytrzymaj miejsce, by się tam przenieść", "Hold a spot to jump there")], [T_SUB])
	_hint.name = "hint"
	add_child(_hint)
	_close = Button.new()
	_close.name = "close"
	_close.text = "✕"
	_close.focus_mode = Control.FOCUS_NONE
	_close.add_theme_font_size_override("font_size", _px(22))
	_close.add_theme_color_override("font_color", Color("#fbf7ee"))
	for s in ["normal", "hover", "pressed", "focus"]:
		_close.add_theme_stylebox_override(s, _box(0.94 if s != "pressed" else 1.0))
	_close.custom_minimum_size = Vector2.ONE * 48.0 * pt
	_close.pressed.connect(close)
	add_child(_close)
	_cards = Button.new()
	_cards.name = "cards"
	_cards.text = "≡"
	_cards.focus_mode = Control.FOCUS_NONE
	_cards.add_theme_font_size_override("font_size", _px(22))
	_cards.add_theme_color_override("font_color", Color("#ffd23f"))
	for s in ["normal", "hover", "pressed", "focus"]:
		_cards.add_theme_stylebox_override(s, _box(0.94 if s != "pressed" else 1.0))
	_cards.custom_minimum_size = Vector2.ONE * 48.0 * pt
	_cards.pressed.connect(func() -> void: show_cards(not cards_shown))
	add_child(_cards)
	_help = Button.new()
	_help.name = "help"
	_help.text = "?"
	_help.focus_mode = Control.FOCUS_NONE
	_help.add_theme_font_size_override("font_size", _px(22))
	_help.add_theme_color_override("font_color", Color("#ffd23f"))
	for s in ["normal", "hover", "pressed", "focus"]:
		_help.add_theme_stylebox_override(s, _box(0.94 if s != "pressed" else 1.0))
	_help.custom_minimum_size = Vector2.ONE * 48.0 * pt
	_help.pressed.connect(replay_coach)
	add_child(_help)
	_list = _card([], [])
	_list.name = "districts"
	_list.visible = false
	add_child(_list)
	_quests = _card([], [])
	_quests.name = "quests"
	_quests.visible = false
	add_child(_quests)
	_note = _card(["", ""], [T_SUB, T_SUB])
	_note.name = "note"
	_note.visible = false
	add_child(_note)
	_more = Control.new()
	_more.name = "more"
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more.visible = false
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(0.07, 0.06, 0.1, 0.0), Color(0.07, 0.06, 0.1, 0.97)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.0, 0.0)
	gt.fill_to = Vector2(0.0, 1.0)
	gt.width = 4
	gt.height = 32
	var fade := TextureRect.new()
	fade.name = "fade"
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_more.add_child(fade)
	_more_label = Label.new()
	_more_label.text = "▼"
	_more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_more_label.add_theme_font_size_override("font_size", _px(T_SUB))
	_more_label.add_theme_color_override("font_color", Color("#ffd23f"))
	_more_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more.add_child(_more_label)
	add_child(_more)
	_coach = _card([""], [T_SUB])
	_coach.name = "coach"
	_coach.visible = false
	add_child(_coach)
	_offer = Button.new()
	_offer.name = "track_offer"
	_offer.focus_mode = Control.FOCUS_NONE
	_offer.text = Hints.words_of("track_offer")
	_offer.visible = false
	_offer.custom_minimum_size = Vector2(120.0, 48.0) * pt
	_offer.add_theme_font_size_override("font_size", _px(T_SUB))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		_offer.add_theme_color_override(k, Color("#1a1622"))
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = GOLD.darkened(0.2) if st == "pressed" else GOLD
		sb.set_corner_radius_all(_px(8))
		_offer.add_theme_stylebox_override(st, sb)
	_offer.pressed.connect(_track_unknown)
	add_child(_offer)
	_refresh_legend()


func _box(alpha: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.07, 0.06, 0.1, alpha)
	b.set_corner_radius_all(_px(12))
	b.set_content_margin_all(10.0 * pt)
	b.border_color = Color("#ffd23f")
	b.border_width_left = _px(3)
	return b


## A small card: lines of text, Polish over English.
func _card(lines: Array, sizes: Array) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _box(0.9))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override("font_size", _px(sizes[i]))
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 and sizes[i] == T_TITLE else
				(Color("#fbf7ee") if i == 0 else Color("#c9c2d8")))
		v.add_child(l)
	return p


## Opens on the car, START_M across the screen's height.
func open(at: Vector2, yaw: float) -> void:
	if _built and _built_lang != Lang.code:
		# The language changed since the cards were made (Settings): make them again.
		for c in get_children():
			c.queue_free()
		_legend_icons.clear()
		_built = false
		_tint_key = -1
	if not _built:
		_build()
		var keep := [main_pl, main_en]
		main_pl = "-"
		set_main_goal(keep[0], keep[1])
	car = at
	car_yaw = yaw
	centre = at
	_unknown_sel = ""
	_offer.visible = false
	_refresh_legend()
	_touches.clear()
	_hold_index = -1
	_note_t = 0.0
	_note.visible = false
	_hint.visible = true
	_hint_words()
	_did_scroll = false
	_did_hold = false
	_did_pin = false
	_replay = false
	if hints != null:
		hints.map_reset()
	visible = true
	_fit()
	ppm = clampf(_view().y / START_M, _ppm_min(), _ppm_max())
	_place()


## The hint card's words: the fingers', or the pad's while the pad is used (gamepad.gd).
func _hint_words() -> void:
	# One line in the player's language (Lang.pick, as _build makes it).
	var label := (_hint.get_child(0) as VBoxContainer).get_child(0) as Label
	if Gamepad.in_use():
		label.text = Gamepad.fmt(Lang.pick("Przytrzymaj {a}, by się przenieść pod krzyżyk · lewa gałka przesuwa · {rt} / {lt} przybliża",
				"Hold {a} to jump to the cross · left stick pans · {rt} / {lt} zoom"))
	else:
		label.text = Lang.pick("Przytrzymaj miejsce, by się tam przenieść", "Hold a spot to jump there")


## Shows or hides the districts' card (the ≡ button; the rivals are in the one list since step 4).
func show_cards(on: bool) -> void:
	cards_shown = on
	if not _built:
		return
	_list.visible = _has_list and on
	_quests.visible = not on and _has_quests()
	_fit()


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
	_quit_armed = 0.0
	_coach.visible = false
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


## The header top left, the ✕ top right, the hint bottom centre, inside the safe area.
func _fit() -> void:
	if not _built or not visible:
		return
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var m := 8.0 * pt
	_head.size = _head.get_combined_minimum_size()
	_head.position = s.position + Vector2(m, m)
	_close.size = _close.custom_minimum_size
	_close.position = Vector2(s.end.x - m - _close.size.x, s.position.y + m)
	_cards.size = _cards.custom_minimum_size
	_cards.position = _close.position - Vector2(m + _cards.size.x, 0.0)
	_help.size = _help.custom_minimum_size
	_help.position = _cards.position - Vector2(m + _help.size.x, 0.0)
	# 2026-11-16: the legend is the filters now (two columns of 44 pt cells), so the hint and the note
	# make room for it instead of the legend giving way; it still gives way to the districts' card,
	# and to the list when they would meet.
	_legend.size = _legend.get_combined_minimum_size()
	_legend.position = Vector2(s.position.x + m, s.end.y - m - _legend.size.y)
	var leg_ok := not _list.visible and (not _quests.visible \
			or _legend.position.x + _legend.size.x + m <= s.end.x - m - _quests.get_combined_minimum_size().x - m)
	var leg_right := _legend.position.x + _legend.size.x + m if leg_ok else s.position.x
	_hint.size = _hint.get_combined_minimum_size()
	_hint.position = Vector2(maxf(s.position.x + (s.size.x - _hint.size.x) * 0.5, leg_right), s.end.y - m - _hint.size.y)
	var below := _head.position.y + _head.size.y + m
	if _quests.visible:
		_fit_list(s, m)
	if _goal.visible:
		# As wide as its line, but never into the list's card or the buttons: then it wraps.
		var right := _quests.position.x if _quests.visible else _help.position.x
		_wrap_goal(maxf(120.0 * pt, right - m - (s.position.x + m) - 24.0 * pt))
		_goal.size = _goal.get_combined_minimum_size()
		_goal.position = Vector2(s.position.x + m, below)
		below = _goal.position.y + _goal.size.y + m
	_legend.visible = leg_ok and not (_goal.visible and Rect2(_legend.position, _legend.size).grow(m * 0.5).intersects(Rect2(_goal.position, _goal.size))) \
			and not (_quests.visible and Rect2(_legend.position, _legend.size).grow(m * 0.5).intersects(Rect2(_quests.position, _quests.size)))
	if _list.visible:
		_list.size = _list.get_combined_minimum_size()
		_list.position = Vector2(s.position.x + m, below)
	if _note.visible:
		_note.size = _note.get_combined_minimum_size()
		_note.position = Vector2(maxf(s.position.x + (s.size.x - _note.size.x) * 0.5, leg_right), s.end.y - m - _note.size.y)
	if _offer.visible:
		_offer.size = _offer.custom_minimum_size
		_offer.position = Vector2(_note.position.x + (_note.size.x - _offer.size.x) * 0.5, _note.position.y - m - _offer.size.y)
	_hint.visible = not _note.visible  # the note takes the hint's place for its moment
	_place_coach()
	_place()


## First hour step 4: the list's card on the right under the buttons, as tall as its rows but no
## lower than the safe area's bottom (or the hint's top, when the hint sits under it): past that
## its scroll takes the rest.
func _fit_list(s: Rect2, m: float) -> void:
	var top := _close.position.y + _close.size.y + m
	var bottom := s.end.y - m
	var sc := _quests.find_child("list_scroll", true, false) as ScrollContainer
	var w := _quests.get_combined_minimum_size().x
	var left := s.end.x - m - w
	if _hint.visible and _hint.position.x < s.end.x - m and _hint.position.x + _hint.size.x > left:
		bottom = _hint.position.y - m
	if sc != null:
		var inner := sc.get_child(0) as Control
		sc.custom_minimum_size.y = 0.0
		_quests.reset_size()
		var chrome := _quests.get_combined_minimum_size().y
		var want := inner.get_combined_minimum_size().y
		var avail := bottom - top - chrome
		var floor_h := LIST_MIN_ROWS * ROW_H * pt
		var h := clampf(want, floor_h, maxf(floor_h, avail))
		if want > avail:
			h = maxf(floor_h, minf(avail, _fold_cut(inner, avail)))
		sc.custom_minimum_size.y = h
	_quests.reset_size()
	_quests.size = _quests.get_combined_minimum_size()
	_quests.position = Vector2(s.end.x - m - _quests.size.x, top)
	_update_more()


## Where to cut the list's scroll (px from its top, never past `avail`) so a row is cut at the
## fold and the list reads as scrollable: the first child that runs past `avail` shows between a
## third and two thirds of itself; when that would leave only a sliver, the one before it is cut.
func _fold_cut(inner: Control, avail: float) -> float:
	var gap := float(inner.get_theme_constant("separation"))
	var y := 0.0
	var prev_y := -1.0
	var prev_h := 0.0
	for c in inner.get_children():
		var ch := (c as Control).get_combined_minimum_size().y
		if y + ch > avail:
			var shown := avail - y
			if shown >= ch * 0.34:
				return y + minf(shown, ch * 0.66)
			if prev_y >= 0.0:
				return prev_y + prev_h * 0.6
			return avail
		prev_y = y
		prev_h = ch
		y += ch + gap
	return avail


## The "more below" cue: a fade and a ▼ over the scroll's bottom while there is more under it,
## gone once the end is in view (and while the ≡ cards hide the list). Every frame the map is open
## and after a drag; cheap (a few reads).
func _update_more() -> void:
	if _more == null:
		return
	var sc: ScrollContainer = null
	if _quests.visible:
		sc = _quests.find_child("list_scroll", true, false) as ScrollContainer
	var over := 0.0
	if sc != null and maxf(sc.size.y, sc.custom_minimum_size.y) > 1.0:
		# Its size is last frame's until the layout runs; the height the fit asked for stands in.
		over = (sc.get_child(0) as Control).get_combined_minimum_size().y - maxf(sc.size.y, sc.custom_minimum_size.y)
	var on := sc != null and over > 2.0 and float(sc.scroll_vertical) < over - 2.0
	_more.visible = on
	if not on:
		return
	var r := sc.get_global_rect()
	var fade_h := minf(FADE_H * pt, r.size.y * 0.5)
	_more.position = Vector2(r.position.x, r.end.y - fade_h) - get_global_rect().position
	_more.size = Vector2(r.size.x, fade_h)
	_more_label.size = Vector2(r.size.x, _more_label.get_combined_minimum_size().y)
	_more_label.position = Vector2(0.0, fade_h - _more_label.size.y)


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
	_legend_art.queue_redraw()


## A map point (m) on the screen (px).
func to_screen(p: Vector2) -> Vector2:
	return _view() * 0.5 + (p - centre) * ppm


## For check_hud: the ✕ and the cards, in pixels.
func rects() -> Dictionary:
	if not _built:
		return {}
	var out := {"close": _close.get_global_rect(), "cards": _cards.get_global_rect(), "head": _head.get_global_rect()}
	if _goal.visible:
		out["goal"] = _goal.get_global_rect()
	if _legend.visible:
		out["legend"] = _legend.get_global_rect()
	if _hint.visible:
		out["hint"] = _hint.get_global_rect()
	if _note.visible:
		out["note"] = _note.get_global_rect()
	if _list.visible:
		out["districts"] = _list.get_global_rect()
	if _quests.visible:
		out["quests"] = _quests.get_global_rect()
	out["help"] = _help.get_global_rect()
	if _more.visible:
		out["more"] = _more.get_global_rect()
	if _next_card != null and _quests.visible:
		out["next"] = _next_card.get_global_rect()
	if _coach.visible:
		out["coach"] = _coach.get_global_rect()
	if _offer.visible:
		out["offer"] = _offer.get_global_rect()
	return out


## The legend's icons, in its rows' order, on top of its card (one batch of their own).
func _paint_legend() -> void:
	if not _legend.visible or _legend_icons.size() != LEGEND.size():
		return
	var ic: Array[Vector2] = []
	for c in _legend_icons:
		var r := c.get_global_rect()  # the icon sits over the cell's left (2026-11-16: the cells are the filters)
		ic.append(Vector2(r.position.x + LEGEND_ICON_X * pt, r.get_center().y) - _legend_art.get_global_rect().position)
	hud._tri_begin()
	# A hidden kind's icon is a hollow ring (the cell's words are dimmed too).
	var on: Array[bool] = []
	for k: Dictionary in MapTrack.KINDS:
		on.append(not _hidden.has(str(k["id"])))
	if on[0]:
		hud.main_star(ic[0], 1.0)
	if on[1]:
		hud.story_badge(ic[1], 1.0, Color("#2fb8e0"))  # boat_race.gd COLOUR
	if on[2]:
		hud.side_pin(ic[2], 1.2, Color("#ff8a3d"))  # jobs.gd KEBAB_COLOUR
	if on[3]:
		hud.poi_mark(ic[3], 5.4 * pt, Color("#ff8a3d"), MapIcons.POI_KEBAB)
	if on[4]:
		hud.poi_mark(ic[4], 5.4 * pt, Color("#4fd8c4"), MapIcons.POI_STATION)  # jobs.gd SLOIK_COLOUR
	if on[5]:
		hud._tri_diamond(ic[5], 4.6 * pt, Color("#5aa0ff"))  # garage.gd GARAGE_COLOUR
	if on[6]:
		MapIcons.paint_quiet(hud, "metro", MapIcons.METRO, ic[6], 7.5 * pt)
	for i in on.size():
		if not on[i]:
			hud._tri_fan(ic[i], 6.0 * pt, 0.0, TAU, Color("#8f88a0"))
			hud._tri_fan(ic[i], 4.2 * pt, 0.0, TAU, Color(0.07, 0.06, 0.1, 1.0))
	hud._tri_flush(_legend_art)


## One legend cell: a Button MIN_TOUCH tall, its left kept free for the icon painted over it.
func _legend_cell(n: String) -> Button:
	var b := Button.new()
	b.name = n
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size = Vector2(LEGEND_W, ROW_H) * pt
	b.add_theme_font_size_override("font_size", _px(T_SUB - 1.0))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color("#fbf7ee"))
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.18, 0.28, 0.95) if st == "pressed" else Color(0.12, 0.11, 0.17, 0.9)
		sb.set_corner_radius_all(_px(6))
		sb.content_margin_left = (LEGEND_ICON_X + 11.0 if n != "legend_all" else 10.0) * pt
		sb.content_margin_right = 4.0 * pt
		b.add_theme_stylebox_override(st, sb)
	return b


## How many marks of legend kind `kind` the map has: all of them (`ctx` -1) or those the rule table
## shows on the full map in `ctx` (the metro's are the map's own icons, always).
func _kind_total(kind: Dictionary, ctx := -1) -> int:
	if str(kind["id"]) == "metro":
		var n := 0
		for ic in icons:
			if str(ic["shape"]) == "metro":
				n += 1
		return n
	return markers.count_group(kind["groups"], MapMarkers.View.FULL_MAP, ctx)


## The cells' words ("kebab  3/9": shown n of the total; a hidden kind shows 0) and looks, ALL's too.
func _refresh_legend() -> void:
	if _legend_cells.size() != LEGEND.size() or _legend_all == null:
		return
	var ctx := MapMarkers.context_of(focus, flying)
	var vis := 0
	var tot := 0
	for i in LEGEND.size():
		var kind: Dictionary = MapTrack.KINDS[i]
		var all_n := _kind_total(kind)
		var n := 0 if _hidden.has(str(kind["id"])) else _kind_total(kind, ctx)
		vis += n
		tot += all_n
		_legend_cells[i].text = "%s  %d/%d" % [Lang.split(LEGEND[i]), n, all_n]
		_legend_cells[i].modulate = Color(1, 1, 1, 0.55 if _hidden.has(str(kind["id"])) else 1.0)
	_legend_all.text = "%s  %d/%d" % [Hints.words_of("map_all"), vis, tot]
	_legend_all.modulate = Color(1, 1, 1, 1.0 if not _hidden.is_empty() else 0.55)


## A tap on a legend cell: that kind's icons hide or show on this map (the minimap is not touched);
## ALL (`kind` "") shows every kind again. Session only.
func _toggle_kind(kind: String) -> void:
	if kind == "":
		_hidden.clear()
	elif _hidden.has(kind):
		_hidden.erase(kind)
	else:
		_hidden[kind] = true
	print("full map: legend %s -> hidden %s" % [kind if kind != "" else "ALL", ",".join(_hidden.keys())])
	_refresh_legend()
	_place()


## Whether marks of registry group `group` are drawn (no legend kind hides it). The target, the
## quest pin and the car are not groups and are never hidden.
func _group_on(group: String) -> bool:
	var k := MapTrack.kind_of(group)
	return k == "" or not _hidden.has(k)


## The goal card's lines wrap at `w` pixels (the card's padding left out) when longer.
func _wrap_goal(w: float) -> void:
	var box: VBoxContainer = _goal.get_child(0)
	for c in box.get_children():
		var l := c as Label
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.custom_minimum_size.x = 0.0
		if l.get_minimum_size().x > w:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = w
	_goal.reset_size()


## The main line's goal line (hud.gd passes it on open and while open; its star is in the
## registry). An empty line hides the goal card (the main line is done).
func set_main_goal(pl: String, en: String) -> void:
	var changed := pl != main_pl or en != main_en
	main_pl = pl
	main_en = en
	if not _built or not changed:
		return
	var box: VBoxContainer = _goal.get_child(0)
	(box.get_child(0) as Label).text = "★ " + Lang.pick(pl, en)
	(box.get_child(1) as Label).text = ""
	(box.get_child(1) as Label).visible = false
	_goal.visible = pl != ""
	_fit()


## Loop 3h slice 3 (the ladder's card) and The Six (step 5): since first hour step 4 the rivals are
## the one list's RYWALE section: `chips` (ladder.gd `chips`: six names, "open" and "won" ones
## tappable to call that rival out, `rival_called`), `title` [pl, en] (ladder.gd `title`), `final`
## the final's line (ladder.gd `rows`' last, [text, state]) and `night` (the final waits for the
## night: a button switches it on, main.gd). Call after open().
func set_rivals(chips: Array, title: Array = [], final: Array = [], night := false) -> void:
	rival_chips = chips
	rivals_title = title
	final_line = final
	night_offer = night
	if _built:
		_fill_quests()


func _rival_tapped(rung: int) -> void:
	print("full map: rival %d called out" % rung)
	rival_called.emit(rung)
	close()


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
	for d in districts:
		if d["found"]:
			continue
		for poly: PackedVector2Array in d["polys"]:
			var parts: Array[PackedVector2Array] = [poly]
			if bounds.has_area():
				parts = Geometry2D.intersect_polygons(poly, frame)
			for part in parts:
				var tris := Geometry2D.triangulate_polygon(part)
				for i in tris:
					_fog.append(part[i])
	if not _built:
		return
	var lines := [Lang.pick("DZIELNICE", "DISTRICTS")]
	var sizes := [T_TITLE]
	for d in districts:
		lines.append("%s · %d%%" % [Lang.pick(d["name_pl"], d["name_en"]), d["pct"]] if d["found"] else "? ? ?")
		sizes.append(T_SUB)
	if syrenki_total > 0:
		lines.append("Syrenki %d/%d" % [syrenki_found, syrenki_total])
		sizes.append(T_SUB)
	lines.append(Lang.pick("Razem %d%%", "In all %d%%") % total)
	sizes.append(T_SUB)
	var rows: VBoxContainer = _list.get_child(0)
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override("font_size", _px(sizes[i]))
		var found: bool = i < 1 or i >= 1 + districts.size() or districts[i - 1]["found"]
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 else
				(Color("#fbf7ee") if found and i >= 1 else Color("#c9c2d8")))
		rows.add_child(l)
	_has_list = not districts.is_empty()
	_list.visible = _has_list and cards_shown
	_fit()


## The main line's star (INF: none), from the registry.
func _main_at() -> Vector2:
	return markers.where(MapMarkers.MAIN_STAR)


## The questlines' starts the map shows now (the registry's STORY layer by the rule table).
func _stories() -> Dictionary:
	return markers.shown(MapMarkers.Layer.STORY, MapMarkers.View.FULL_MAP, MapMarkers.context_of(focus, flying))


## G12 part 2: the quests on offer now (quest_lines.gd entries), the vehicle's line (its places
## lead Around town) and the id of the quest pin (""); call after open().
func set_quests(entries: Array, line: int, pick_id := "", pin := {}) -> void:
	quest_entries = entries
	quest_line = line
	quest_pick = {}
	quest_pad = -1
	for e: Dictionary in entries:
		if str(e["id"]) == pick_id and pick_id != "":
			quest_pick = e
	if quest_pick.is_empty() and not pin.is_empty() and MapTrack.keepable(pin):
		quest_pick = pin  # a place the list does not carry (a "?" tracked, a saved track found again)
	if not _built:
		return
	_fill_quests()


## First hour step 4: the First steps left (each {"id", "pl", "en", "entry"}: first_steps.gd's rows
## not done with the place or request that does each, main.gd), the header ("PIERWSZE KROKI 2/7"),
## the promise and whether Friends shows (the third step). Empty `left`: no First steps section.
func set_steps(left: Array, head: Array, words: Array, friends := true) -> void:
	steps_left = left
	steps_head = head
	promise = words
	friends_open = friends
	if _built:
		_fill_quests()


## 2026-11-16: what the NEXT card says once First steps are done (or while no step has a row):
## the main line's next step as [pl, en] (main_line.gd `step`; empty: no card) and its place on the
## map (INF: none). Call after open().
func set_next(words: Array, at := Vector2.INF) -> void:
	next_words = words
	next_at = at
	if _built:
		_fill_quests()


## First hour step 4: the Collection line ([pl, en]: districts, Syrenki, cassettes); empty until
## the first find.
func set_collection(words: Array) -> void:
	collection = words
	if _built:
		_fill_quests()


## A section's title [pl, en] as the list shows it (the First steps' and the Rivals' with counts).
func _section_title(key: String) -> String:
	var t: Array = Lines.SECTION_TITLES[key]
	if key == "steps" and steps_head.size() == 2:
		t = steps_head
	elif key == "rivals" and rivals_title.size() == 2:
		t = rivals_title
	return Lang.pick(str(t[0]), str(t[1]))


## Builds the one list (first hour step 4): the pad's keys, then one scroll with the sections
## (quest_lines.gd `sections`), each a title and its rows, then the quit button for what runs.
## `quest_rows` and `_quest_buttons` hold every tappable row in order (the rivals' chips too).
func _fill_quests() -> void:
	var box: VBoxContainer = _quests.get_child(0)
	var keep := 0
	var old := _quests.find_child("list_scroll", true, false) as ScrollContainer
	if old != null:
		keep = old.scroll_vertical  # a rebuild (a pin, the rivals opened) keeps the place in the list
	_next_card = null
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	_quest_buttons.clear()
	_section_starts.clear()
	box.add_theme_constant_override("separation", int(4.0 * pt))
	box.custom_minimum_size.x = QUEST_W * pt
	list_sections = Lines.sections(quest_entries, quest_line, car, steps_left, friends_open)
	quest_rows = []
	if Gamepad.in_use():
		# G12b: the pad's words for the card (A stays the teleport hold).
		var keys := Label.new()
		keys.name = "pad_keys"
		keys.text = Gamepad.fmt(Lang.pick("{x}: następna sekcja · krzyżak: wybór · {y}: bierz", "{x}: next section · D-pad: pick · {y}: take"))
		keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		keys.custom_minimum_size.x = QUEST_W * pt
		keys.add_theme_font_size_override("font_size", _px(T_SUB))
		keys.add_theme_color_override("font_color", Gamepad.RING)
		box.add_child(keys)
	var nxt := _make_next()
	if nxt != null:
		box.add_child(nxt)
		_next_card = nxt
	var scroll := ScrollContainer.new()
	scroll.name = "list_scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.x = QUEST_W * pt
	box.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.name = "list"
	inner.add_theme_constant_override("separation", int(4.0 * pt))
	inner.custom_minimum_size.x = QUEST_W * pt
	scroll.add_child(inner)
	var padded: Button = null
	var any := false
	for sec: Dictionary in list_sections:
		var key := str(sec["key"])
		var rows: Array = sec["rows"]
		if key == "rivals" and rival_chips.is_empty() and rows.is_empty():
			continue
		if key == "collection" and collection.size() != 2:
			continue
		any = true
		_section_starts.append(quest_rows.size())
		if key == "rivals":
			var tb := _rivals_row()
			inner.add_child(tb)
			if quest_rows.size() - 1 == quest_pad:
				padded = tb
		else:
			inner.add_child(_section_label(key))
		if key == "steps" and promise.size() == 2:
			inner.add_child(_words(Lang.pick(str(promise[0]), str(promise[1])), "promise"))
		if key == "rivals":
			if _rivals_open:
				padded = _add_chips(inner, padded)
			if _rivals_open and final_line.size() == 2 and rows.is_empty():
				var fl := _words(str(final_line[0]), "final_line")
				fl.add_theme_color_override("font_color", LADDER_COLOURS.get(str(final_line[1]), Color.WHITE))
				inner.add_child(fl)
			if night_offer:
				rows = rows + [_night_row()]
		if key == "collection":
			var cr := Lines.entry("collection", "collection", Lines.Line.CAR, str(collection[0]), str(collection[1]),
					Vector2.INF, Color("#ffd23f"), "cards")
			cr["far"] = ["", ""]
			rows = [cr]
		for r: Dictionary in rows:
			if bool(r.get("label", false)):
				inner.add_child(_words("○ " + Lang.pick(str(r["pl"]), str(r["en"])), "step_" + str(r.get("step", ""))))
				continue
			var b := _row_button(r, quest_rows.size())
			inner.add_child(b)
			if quest_rows.size() - 1 == quest_pad:
				padded = b
	if not any:
		var none := _words(Lang.pick("Na razie nic. Skończ to, co trwa, albo zajrzyj później.",
				"Nothing to start now. Finish what's on, or look again later."), "none")
		inner.add_child(none)
	quest_pad = mini(quest_pad, quest_rows.size() - 1)
	if not quit_what.is_empty():
		box.add_child(_quit_button())
	_quests.reset_size()
	_quests.visible = not cards_shown and _has_quests()
	_fit()
	if keep > 0:
		scroll.set_deferred("scroll_vertical", keep)
	if padded != null:
		scroll.ensure_control_visible.call_deferred(padded)
	if _reveal_chips:
		_reveal_chips = false
		var grid := inner.find_child("rival_chips", false, false) as Control
		if grid != null:
			scroll.ensure_control_visible.call_deferred(grid)


## A section's title in the list: small gold capitals.
func _section_label(key: String) -> Label:
	var l := Label.new()
	l.name = "sec_" + key
	l.text = _section_title(key)
	l.add_theme_font_size_override("font_size", _px(T_SUB))
	l.add_theme_color_override("font_color", Color("#ffd23f"))
	return l


## A line of words in the list (the promise, a step done by a button, "nothing now"), wrapped.
func _words(text: String, n: String) -> Label:
	var l := Label.new()
	l.name = n
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = QUEST_W * pt
	l.add_theme_font_size_override("font_size", _px(T_SUB))
	l.add_theme_color_override("font_color", Color("#c9c2d8"))
	return l


## The rivals' chips, CHIPS_PER_ROW to a row (each MIN_TOUCH tall): "★ HALINA" beaten, "BARTEK •••"
## open (a tap calls them out), locked ones greyed and not tappable. Returns the pad's pick's
## button if it is one of them (else `padded`).
func _add_chips(inner: VBoxContainer, padded: Button) -> Button:
	var grid := GridContainer.new()
	grid.name = "rival_chips"
	grid.columns = CHIPS_PER_ROW
	grid.add_theme_constant_override("h_separation", int(4.0 * pt))
	grid.add_theme_constant_override("v_separation", int(4.0 * pt))
	inner.add_child(grid)
	var w := (QUEST_W - 4.0 * (CHIPS_PER_ROW - 1)) / CHIPS_PER_ROW
	for c: Dictionary in rival_chips:
		var state := str(c["state"])
		var b := Button.new()
		b.name = "rival_%d" % int(c["rung"])
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.custom_minimum_size = Vector2(w, ROW_H) * pt
		b.add_theme_font_size_override("font_size", _px(T_SUB))
		b.text = ("★ " + str(c["short"])) if state == "won" else str(c["short"])
		var col: Color = LADDER_COLOURS.get(state, Color.WHITE)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(k, col)
		var tappable := state != "locked"
		var here := quest_rows.size()
		var rim := Access.tint(RIVAL_COLOUR)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = rim.darkened(0.55) if st == "pressed" else Color(0.12, 0.11, 0.17, 0.9)
			sb.set_corner_radius_all(_px(6))
			sb.border_color = Gamepad.RING if tappable and here == quest_pad else (rim if tappable else Color("#8f88a0"))
			sb.set_border_width_all(_px(3) if tappable and here == quest_pad else _px(1))
			sb.border_width_bottom = _px(4)
			sb.content_margin_left = 4.0 * pt
			sb.content_margin_right = 4.0 * pt
			b.add_theme_stylebox_override(st, sb)
		if not tappable:
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.7)
		else:
			var r := Lines.entry("rival_%d" % int(c["rung"]), "rival", Lines.Line.CAR, str(c["short"]), str(c["short"]),
					Vector2.INF, RIVAL_COLOUR, Lines.RIVAL_CALL)
			r["rung"] = int(c["rung"])
			r["far"] = ["", ""]
			quest_rows.append(r)
			_quest_buttons.append(b)
			b.pressed.connect(_row_tapped.bind(here))
			if here == quest_pad:
				padded = b
		grid.add_child(b)
	return padded


## The Rivals section's one row, "RYWALE 1/6 ›": a tap opens the six chips under it, again folds them.
func _rivals_row() -> Button:
	var t := _section_title("rivals")
	var r := Lines.entry("rivals_toggle", "rival", Lines.Line.CAR, t, t, Vector2.INF, RIVAL_COLOUR, RIVALS_TOGGLE)
	r["far"] = ["", ""]
	var b := _row_button(r, quest_rows.size())
	b.name = "rivals_toggle"
	if _rivals_open:
		b.text = t + " ▲"
	return b


## The NEXT card, pinned above the list's scroll (the list's first thing, whatever it is scrolled
## to): while First steps are not all done, their header ("First steps 2/7") and the nearest step,
## tappable like its row below; after them the main line's next step (`set_next`: the next rival,
## the respect to earn, the final). None while something runs (only Now shows) or with nothing to say.
func _make_next() -> PanelContainer:
	if list_sections.is_empty() or str(list_sections[0]["key"]) == "now":
		return null
	var head := ""
	var row: Dictionary = {}
	var words := ""
	var first: Dictionary = list_sections[0]
	var tr := _tracked()
	if not tr.is_empty():
		# 2026-11-16: the tracked place leads the card, gold; a tap on it lets it go.
		head = "%s · %s" % [Hints.words_of("track_head"), Hints.words_of("track_off")]
		row = tr.duplicate()
		row["far"] = [Lines.far_text(car, tr["at"], true), Lines.far_text(car, tr["at"], false)]
	elif str(first["key"]) == "steps" and not (first["rows"] as Array).is_empty():
		head = _section_title("steps")
		row = (first["rows"] as Array)[0]
	elif next_words.size() == 2 and str(next_words[0]) != "":
		head = Hints.words_of("next_head")
		words = Lang.pick(str(next_words[0]), str(next_words[1]))
	else:
		return null
	var card := PanelContainer.new()
	card.name = "next_card"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.16, 0.04, 0.96)
	sb.set_corner_radius_all(_px(8))
	sb.border_color = GOLD
	sb.set_border_width_all(_px(2))
	sb.set_content_margin_all(6.0 * pt)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size.y = ROW_H * pt
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(2.0 * pt))
	card.add_child(v)
	var hl := Label.new()
	hl.name = "next_head"
	hl.text = head
	hl.add_theme_font_size_override("font_size", _px(T_SUB))
	hl.add_theme_color_override("font_color", GOLD)
	v.add_child(hl)
	var w := (QUEST_W - 16.0) * pt
	if not row.is_empty():
		var nm := Lang.pick(str(row["pl"]), str(row["en"]))
		if bool(row.get("label", false)):
			var l := _words("○ " + nm, "next_words")
			l.custom_minimum_size.x = w
			v.add_child(l)
		else:
			var far := Lang.pick(str(row["far"][0]), str(row["far"][1]))
			if not tr.is_empty():
				v.add_child(_next_button("◆ %s · %s" % [nm, far], GOLD, _untrack))
			else:
				v.add_child(_next_button(("○ %s · %s" % [nm, far]) if far != "" else ("○ %s ›" % nm), Access.tint(row["colour"]),
						_next_tapped.bind(str(row["id"]))))
	elif next_at != Vector2.INF:
		v.add_child(_next_button(words + " ›", MainLine.COLOUR, _next_look))
	else:
		var l := _words(words, "next_words")
		l.custom_minimum_size.x = w
		v.add_child(l)
	return card


## The NEXT card's tappable line: `col`'s rim on its left, MIN_TOUCH tall, `then` on a tap.
func _next_button(text: String, col: Color, then: Callable) -> Button:
	var b := Button.new()
	b.name = "next_row"
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size = Vector2(QUEST_W - 16.0, ROW_H) * pt
	b.add_theme_font_size_override("font_size", _px(T_SUB))
	b.text = text
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color("#fbf7ee"))
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.darkened(0.55) if st == "pressed" else Color(0.12, 0.11, 0.17, 0.9)
		sb.set_corner_radius_all(_px(6))
		sb.border_color = col
		sb.border_width_left = _px(6)
		sb.content_margin_left = 12.0 * pt
		sb.content_margin_right = 6.0 * pt
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(then)
	return b


## A tap on the NEXT card's step: the same as a tap on its row in the list below.
func _next_tapped(id: String) -> void:
	if _dragged():
		return
	for i in quest_rows.size():
		if str(quest_rows[i]["id"]) == id:
			pick_row(i)
			return


## The tracked place ({} none): the pin picked, when it is a place (a request or a rival's call is no track).
func _tracked() -> Dictionary:
	if quest_pick.is_empty() or str(quest_pick.get("action", "")) != "" or quest_pick.get("at", Vector2.INF) == Vector2.INF:
		return {}
	return quest_pick


## A tap on the tracked line: the same as the second tap on its row (the pin goes, main.gd lets the track go).
func _untrack() -> void:
	if _dragged() or quest_pick.is_empty():
		return
	quest_pick = {}
	print("full map: track off")
	quest_picked.emit({})
	_fill_quests()
	_place()


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
	_unknown_sel = str((v["extra"][best] as Dictionary).get("step", ""))
	_unknown_at = v_at[best]
	_offer.visible = _tracked().get("id", "") != "unknown_" + _unknown_sel
	_say(MapTrack.teaser(_unknown_sel))
	_note_t = 6.0
	print("full map: ? %s" % _unknown_sel)
	return true


## TRACK on a "?": the First step's place becomes the pin (main.gd keeps it and the route follows).
func _track_unknown() -> void:
	if _unknown_sel == "":
		return
	var e := MapTrack.entry_of(_unknown_sel, _unknown_at)
	_unknown_sel = ""
	_offer.visible = false
	_note.visible = false
	quest_pick = e
	_did_pin = true
	centre = e["at"]
	print("full map: track %s at %.0f, %.0f" % [e["id"], e["at"].x, e["at"].y])
	quest_picked.emit(e)
	_fill_quests()
	_fit()
	_place()


## A tap on the NEXT card's main line step: the map looks at its place.
func _next_look() -> void:
	if _dragged() or next_at == Vector2.INF:
		return
	centre = next_at
	_place()


## The night button under the rivals: the final waits for the night (critique point 5).
func _night_row() -> Dictionary:
	var r := Lines.entry("night", "night", Lines.Line.CAR, "Noc na Trzy mosty", "Night for Trzy mosty",
			Vector2.INF, Color("#8fa8ff"), Lines.NIGHT)
	r["far"] = ["", ""]
	return r


## One tappable row of the list: its name and distance, its colour's rim (the pin's and the pad's
## pick drawn round it). `i` is its index in `quest_rows` (it is appended there).
func _row_button(r: Dictionary, i: int) -> Button:
	quest_rows.append(r)
	var b := Button.new()
	b.name = "quest_%d" % i
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size = Vector2(QUEST_W, ROW_H) * pt
	b.add_theme_font_size_override("font_size", _px(T_SUB))
	var picked := str(r["id"]) == str(quest_pick.get("id", ""))
	var padded := i == quest_pad
	var far := Lang.pick(str(r["far"][0]), str(r["far"][1]))
	var name := Lang.pick(str(r["pl"]), str(r["en"]))
	if picked and str(r.get("action", "")) == "":
		name = "◆ " + name  # tracked (2026-11-16): the pin the second tap lets go
	elif r.has("step"):
		name = "○ " + name
	b.text = ("%s · %s" % [name, far]) if far != "" else ("%s ›" % name if str(r["action"]) != Lines.NOW else name)
	b.add_theme_color_override("font_color", Color("#fbf7ee"))
	b.add_theme_color_override("font_hover_color", Color("#fbf7ee"))
	b.add_theme_color_override("font_pressed_color", Color("#fbf7ee"))
	var col := Access.tint(r["colour"])
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col.darkened(0.55) if picked or st == "pressed" else Color(0.12, 0.11, 0.17, 0.9)
		sb.set_corner_radius_all(_px(6))
		sb.border_color = col
		sb.border_width_left = _px(6)
		if picked:
			sb.set_border_width_all(_px(2))
			sb.border_width_left = _px(6)
		if padded:
			# G12b: the pad's pick wears the pad's accent ring (gamepad.gd RING).
			sb.border_color = Gamepad.RING
			sb.set_border_width_all(_px(3))
			sb.border_width_left = _px(6)
		sb.content_margin_left = 12.0 * pt
		sb.content_margin_right = 6.0 * pt
		b.add_theme_stylebox_override(st, sb)
	if not bool(r.get("open", true)):
		b.modulate = Color(1, 1, 1, 0.7)  # a questline closed at this hour (the beta still starts it)
	b.pressed.connect(_row_tapped.bind(i))
	_quest_buttons.append(b)
	return b


## F 2026-11-08: a way out of the quest taken, under the list; a second tap within QUIT_ARM s.
func _quit_button() -> Button:
	var q := Button.new()
	q.name = "quit_quest"
	q.focus_mode = Control.FOCUS_NONE
	q.alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.clip_text = true
	q.custom_minimum_size = Vector2(QUEST_W, ROW_H) * pt
	q.add_theme_font_size_override("font_size", _px(T_SUB))
	var armed := _quit_armed > 0.0
	q.text = Lang.pick("Na pewno? Dotknij jeszcze raz", "Sure? Tap again") if armed \
			else Lang.pick("✕ Porzuć: %s" % str(quit_what[0]), "✕ Quit: %s" % str(quit_what[1]))
	var qc := Access.tint(QUIT_COLOUR)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		q.add_theme_color_override(k, Color("#1a1622") if armed else qc)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = qc if armed or st == "pressed" else Color(0.12, 0.11, 0.17, 0.9)
		sb.set_corner_radius_all(_px(6))
		sb.border_color = qc
		sb.set_border_width_all(_px(2))
		sb.content_margin_left = 8.0 * pt
		sb.content_margin_right = 8.0 * pt
		q.add_theme_stylebox_override(st, sb)
	q.pressed.connect(_quit_tapped)
	return q


## The card shows: something to list, or a quest to quit.
func _has_quests() -> bool:
	return not quest_entries.is_empty() or not quit_what.is_empty() or not steps_left.is_empty() \
			or not rival_chips.is_empty() or collection.size() == 2


## A finger let go on a row: a tap picks it, the end of a drag (the list scrolled, F 2026-11-08:
## a scroll used to start the row under the finger and close the map) does not.
func _row_tapped(i: int) -> void:
	if _dragged():
		print("full map: row %d not picked (a drag)" % i)
		return
	pick_row(i)


func _dragged() -> bool:
	return _qdrag_px > 8.0 * pt


## The quit button: the first tap arms it (it asks "Sure?"), the second within QUIT_ARM s quits.
func _quit_tapped() -> void:
	if _dragged():
		return
	if _quit_armed > 0.0:
		_quit_armed = 0.0
		print("full map: quit quest %s" % str(quit_what[1]))
		close()
		quit_quest.emit()
		return
	_quit_armed = QUIT_ARM
	print("full map: quit quest armed")
	_fill_quests()


## The vehicle's line (Lines.Line): its places lead Around town. Kept for --quest-tab (shots).
func show_line(line: int) -> void:
	quest_line = line
	if _built:
		_fill_quests()


## G12b: a gamepad button on the list: X jumps to the next section's first row, the D-pad up /
## down moves the pick (a place's row centres the map on it, as a look before taking it), Y takes
## the row picked out as a tap would. True when the card used the press.
func pad_quest(button: int) -> bool:
	if not _quests.visible:
		return false
	match button:
		JOY_BUTTON_X:
			pad_section()
		JOY_BUTTON_DPAD_DOWN:
			pad_select(1)
		JOY_BUTTON_DPAD_UP:
			pad_select(-1)
		JOY_BUTTON_Y:
			if quest_pad >= 0:
				pick_row(quest_pad)
		_:
			return false
	return true


## G12b: the pad's pick jumps to the first row of the next section that has one (round to the
## first section after the last).
func pad_section() -> void:
	if quest_rows.is_empty():
		return
	var to := -1
	for st: int in _section_starts:
		if st > quest_pad and st < quest_rows.size():
			to = st
			break
	if to < 0:
		to = 0
	quest_pad = to - 1
	pad_select(1)


## G12b: moves the pad's pick `dir` rows (0: the first row, or none on an empty list).
func pad_select(dir: int) -> void:
	quest_pad = Lines.pad_move(quest_pad if dir != 0 else -1, quest_rows.size(), 1 if dir == 0 else dir)
	if quest_pad >= 0:
		var r: Dictionary = quest_rows[quest_pad]
		if r["at"] != Vector2.INF:
			centre = r["at"]
	if _built:
		_fill_quests()
		_place()


## Row `i` of the list was tapped: a request closes the map and starts (main.gd); a place becomes
## the quest pin and the map centres on it, or, picked already, the pin goes. A rival's chip (or
## the race step) calls that rival out; the Collection row opens the ≡ cards; the night button
## asks main.gd for the night.
func pick_row(i: int) -> void:
	if i < 0 or i >= quest_rows.size():
		return
	var r: Dictionary = quest_rows[i]
	match str(r["action"]):
		Lines.NOW:
			# G12c: the quest under way: the map looks at its target; nothing else changes.
			if r["at"] != Vector2.INF:
				centre = r["at"]
				_place()
			print("full map: quest under way %s" % r["id"])
			return
		Lines.RIVAL_CALL:
			_rival_tapped(int(r["rung"]))
			return
		"cards":
			print("full map: the collection's cards")
			show_cards(true)
			return
		RIVALS_TOGGLE:
			_rivals_open = not _rivals_open
			_reveal_chips = _rivals_open
			print("full map: the rivals %s" % ("open" if _rivals_open else "folded"))
			_fill_quests()
			return
	if str(r["action"]) != "":
		print("full map: quest request %s" % r["id"])
		quest_picked.emit(r)
		close()
		return
	if str(r["id"]) == str(quest_pick.get("id", "")):
		quest_pick = {}
		print("full map: quest pin off")
		quest_picked.emit({})
	else:
		quest_pick = r
		_did_pin = true
		centre = r["at"]
		print("full map: quest pin %s at %.0f, %.0f" % [r["id"], r["at"].x, r["at"].y])
		quest_picked.emit(r)
	_fill_quests()
	_place()


func _paint() -> void:
	var o := _overlay
	var view := Rect2(Vector2.ZERO, _view()).grow(20.0 * pt)
	hud._tri_begin()
	# Loop 3h slice 1: the districts not discovered yet, under a light fog.
	var fog := Color(0.12, 0.13, 0.2, 0.34)
	for i in range(0, _fog.size() - 2, 3):
		hud._tri(to_screen(_fog[i]), to_screen(_fog[i + 1]), to_screen(_fog[i + 2]), fog, fog, fog)
	# The landmarks, printed small on the map (no pins since 2026-11-07): the most important first;
	# one that would touch one already drawn is left out (they come back as it zooms in).
	var r := ICON_R * pt
	var shown: Array[Vector2] = []
	var named: Array[Dictionary] = []
	var close_in := _view().y / ppm <= NAMES_M
	for ic in icons:
		if str(ic["shape"]) == "hospital" and not hospitals:
			continue
		if str(ic["shape"]) == "metro" and _hidden.has("metro"):
			continue  # the legend's filter (map_track.gd)
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
		if view.has_point(at) and _group_on(job_group[i]):
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
	# The questlines' starts: the "!" badges, bigger than any street job's icon (none in focus).
	var stories := markers.shown(MapMarkers.Layer.STORY, MapMarkers.View.FULL_MAP, ctx)
	var story_at: PackedVector2Array = stories["at"]
	var story_on := _group_on("story")
	for i in (story_at.size() if story_on else 0):
		var at := to_screen(story_at[i])
		if view.has_point(at):
			var small := bool((stories["extra"][i] as Dictionary).get("small", false))
			hud.story_badge(at, 1.4 if small else 2.3, (stories["colour"] as PackedColorArray)[i])
	var service := markers.shown(MapMarkers.Layer.SERVICE, MapMarkers.View.FULL_MAP, ctx)
	for i in (service["at"] as PackedVector2Array).size():
		var g := to_screen((service["at"] as PackedVector2Array)[i])
		if view.has_point(g) and _group_on((service["group"] as PackedStringArray)[i]):
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
	if main_at != Vector2.INF and _group_on("main"):
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
	hud._tri_flush(o)
	var font := ThemeDB.fallback_font
	var qs := _px(T_SUB + 3.0)
	for i in unknown_at.size():
		var at := to_screen(unknown_at[i])
		if view.has_point(at):
			var qw := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs).x
			o.draw_string(font, at + Vector2(-qw * 0.5, qs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, qs, Color("#1a1622"))
	# Loop 3h slice 1: each discovered district's name and per cent at its label: big, spaced
	# capitals in its own tint's deep shade, a cream outline.
	var fs := _px(T_TITLE)
	var rim := Color(1.0, 0.98, 0.93, 0.95)
	# Far out the names step down a size; one that would run into a name already written is left
	# out (it comes back as it zooms in).
	if _view().y / ppm > NAMES_M:
		fs = _px(T_SUB + 1.0)
	var taken: Array[Rect2] = []
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
	for i in (story_at.size() if story_on else 0):
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
	_update_more()
	_coach_frame(dt)
	if _quit_armed > 0.0:
		_quit_armed -= dt
		if _quit_armed <= 0.0 and _built:
			_fill_quests()  # not tapped again: the button asks no more
	if _note_t > 0.0:
		_note_t -= dt
		if _note_t <= 0.0:
			_note.visible = false
			_offer.visible = false
			_unknown_sel = ""
			_fit()
	_pad_frame(dt)
	if (_main_at() != Vector2.INF or markers.has(MapMarkers.ACTIVE_TARGET) or not quest_pick.is_empty()) and _hold_index < 0:
		_overlay.queue_redraw()  # the star's and the active pin's rings pulse (one batch, the game paused under it)
		_legend_art.queue_redraw()
	if _hold_index < 0:
		return
	_hold_t += dt
	if _hold_t >= HOLD_S:
		_finish_hold()
	_overlay.queue_redraw()


## 2026-11-16: the coach marks (hints.gd `map_tick`) while the map is open: scroll the list, hold a
## spot, tap a place; each goes when the player does it. The game is paused under the map, so the
## words are a card of the map's own (`_coach`), not hud.gd's spotlight. Off for a run without hints
## (the bench, the demo, --no-hints) unless the "?" asked for them.
func _coach_frame(dt: float) -> void:
	if hints == null or not _built or (hints.off and not _replay):
		_coach.visible = false
		return
	var has_place := false
	for r: Dictionary in quest_rows:
		if r["at"] != Vector2.INF and str(r["action"]) == "":
			has_place = true
			break
	var f := {"scrollable": _more.visible, "has_place": has_place, "cards": cards_shown, "replay": _replay,
			"did_scroll": _did_scroll, "did_hold": _did_hold, "did_pin": _did_pin}
	var before := hints.coach
	var id := hints.map_tick(dt, f)
	if id == "" and _replay:
		_replay = false
		hints.map_reset()
	if id != before:
		_did_scroll = false  # a mark waits for the thing done after it came up
		_did_hold = false
		_did_pin = false
	_place_coach()
	if _coach.visible:
		_coach.modulate.a = 0.82 + 0.18 * sin(float(Time.get_ticks_msec()) * 0.006)


## The coach mark's card: beside the list for the list and the pin, over the hold hint for the hold.
func _place_coach() -> void:
	var id := hints.coach if hints != null else ""
	_coach.visible = id != "" and _built
	if not _coach.visible:
		return
	var lbl := (_coach.get_child(0) as VBoxContainer).get_child(0) as Label
	lbl.text = Hints.words_of(id) + ("" if id == "map_hold" else " ›")
	_coach.size = _coach.get_combined_minimum_size()
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var m := 8.0 * pt
	var at := Vector2(s.position.x + (s.size.x - _coach.size.x) * 0.5, _hint.position.y - m - _coach.size.y)
	if id != "map_hold" and _quests.visible:
		var sc := _quests.find_child("list_scroll", true, false) as ScrollContainer
		var r := sc.get_global_rect() if sc != null else _quests.get_global_rect()
		var y := r.position.y + (r.size.y - _coach.size.y) * 0.5
		if id == "map_pin":
			for i in mini(quest_rows.size(), _quest_buttons.size()):
				if quest_rows[i]["at"] != Vector2.INF and str(quest_rows[i]["action"]) == "":
					y = _quest_buttons[i].get_global_rect().get_center().y - _coach.size.y * 0.5
					break
			y = clampf(y, r.position.y, maxf(r.position.y, r.end.y - _coach.size.y))
		at = Vector2(_quests.position.x - m - _coach.size.x, y)
	at.x = clampf(at.x, s.position.x + m, maxf(s.position.x + m, s.end.x - m - _coach.size.x))
	at.y = clampf(at.y, s.position.y + m, maxf(s.position.y + m, s.end.y - m - _coach.size.y))
	_coach.position = at


## The "?" button: the coach marks again, one at a time, whether seen or not (the save is not
## touched); the ≡ cards go so the list is there to point at.
func replay_coach() -> void:
	if hints == null:
		return
	if cards_shown:
		show_cards(false)
	hints.map_reset()
	_replay = true
	_did_scroll = false
	_did_hold = false
	_did_pin = false
	print("full map: coach marks replay")


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


## A short tap on a questline's "!" pin: its name and one line about it (F 2026-11-08).
func _tap_story(at: Vector2) -> bool:
	if not _group_on("story"):
		return false
	var best := -1
	var best_d := 16.0 * pt
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
	var e: Dictionary = stories["extra"][best]
	var text := str(e.get("name", "")) + " · " + str(e.get("blurb", ""))
	_say([text, text])
	_note_t = 4.5
	return true


## A finger drag on the list: scrolls it (first hour step 4: the one list's scroll); past a few
## points the row under the finger is not picked when it lets go (`_row_tapped`).
func _drag_quests(dy: float) -> void:
	_qdrag_px += absf(dy)
	var sc := _quests.find_child("list_scroll", true, false) as ScrollContainer
	if sc != null:
		sc.scroll_vertical -= int(dy)
		if int(dy) != 0:
			_did_scroll = true
		_update_more()


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
	if (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE) \
			or Gamepad.closes(event):  # the gamepad loop: B, Start or Back
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed \
			and pad_quest((event as InputEventJoypadButton).button_index):
		get_viewport().set_input_as_handled()  # G12b: X, Y and the D-pad's up / down on the ZADANIA card
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
			if _close.get_global_rect().has_point(t.position) or _cards.get_global_rect().has_point(t.position) \
					or _help.get_global_rect().has_point(t.position) \
					or (_legend.visible and _legend.get_global_rect().has_point(t.position)) \
					or (_offer.visible and _offer.get_global_rect().has_point(t.position)) \
					or (_quests.visible and _quests.get_global_rect().has_point(t.position)):
				# F 2026-11-08: a finger dragged on the list scrolls it (the bar alone was too thin).
				_qdrag = t.index if _quests.visible and _quests.get_global_rect().has_point(t.position) else -1
				_qdrag_px = 0.0
				return  # the ✕, ≡ or the ZADANIA card takes it
			_touches[t.index] = t.position
			if _touches.size() == 1:
				_tap_at = t.position
				_tap_ms = Time.get_ticks_msec()
				_start_hold(t.index, t.position)
			else:
				_cancel_hold()  # a second finger: a pinch
		else:
			if t.index == _qdrag:
				_qdrag = -1
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
		if d.index == _qdrag:
			_drag_quests(d.relative.y)
			get_viewport().set_input_as_handled()
			return
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
