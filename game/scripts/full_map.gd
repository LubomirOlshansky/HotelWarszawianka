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

signal closed
## G12 part 2: a row of the ZADANIA card was tapped (its entry, quest_lines.gd `entry`; {}: the
## pin was taken off).
signal quest_picked(entry: Dictionary)
## The hold's spot (map metres), when the hold was held to the end.
signal teleport(at: Vector2)

const Lang := preload("res://scripts/lang.gd")
const MapArt := preload("res://scripts/map_art.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const MainLine := preload("res://scripts/main_line.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const Access := preload("res://scripts/access.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
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
var unknown := PackedVector2Array()
## A crash scene (hud.set_scene_mark), Vector2.INF for none.
var scene_mark := Vector2.INF
var found := PackedVector2Array()
var target := Vector2.INF
## The garage loop: Warsztat u Mirka's diamond (INF: not shown yet).
var garage := Vector2.INF
var garage_colour := Color.WHITE
## Loop 3h slice 3: the final race's start marker (INF: not shown).
var final_start := Vector2.INF
var final_colour := Color.WHITE
var target_colour := Color.WHITE
## The main line (main_line.gd, hud.gd `set_main_line`): its marker (INF: none) and goal line. On the
## map a big gold star in a pulsing ring (pinned to the screen's edge when off it); the side quests
## keep their colours: the active one a ringed dot, the places to start one (kebab stands, the
## station, the scooters: hud.gd's minimap squares) squares. A legend bottom left says which is which.
var main_at := Vector2.INF
var main_pl := ""
var main_en := ""
var side_spots := PackedVector2Array()
var side_colours := PackedColorArray()
## G11: each place's shape (hud.gd POI_*), parallel to side_spots.
var side_shapes := PackedInt32Array()
## The questlines' starts (story_quests.gd) and their colours; quest focus (a quest under way: the
## side places, the garage, the "?" marks and the starts stay off, the main star dims).
var story_spots := PackedVector2Array()
var story_colours := PackedColorArray()
## The questlines' names (in the language shown) by start, for their labels.
var story_names := PackedStringArray()
var focus := false
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
## The legend's rows: [Polish · English]; their icons in order: the star, the ringed dot, the
## kebab stand's badge, the station's triangle, the garage's diamond, the metro's pin, the "?".
const LEGEND := ["główny wątek · main line", "wątek: start · questline start", "zlecenie · side job", "kebab · kebab stand", "stacja · job station",
		"warsztat · garage", "metro · underground", "nieodkryte · not found yet"]
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
var _has_ladder := false
var _touches := {}
var _pinch := 0.0
## Loop 3h slice 1: the fog's triangles (map points, three a triangle: the districts not
## discovered yet, clipped to the map's bounds) and the districts' card.
var _fog := PackedVector2Array()
var _list: PanelContainer
## Loop 3h slice 3: the ladder's card (top right, under the ✕).
var _ladder: PanelContainer
## G12 part 2: the ZADANIA card, the quests given by `set_quests` (entries), the tab shown
## (Lines.Line) and the picked place (an entry; {} none). `quest_rows` is what the tab shows now.
var _quests: PanelContainer
var quest_entries: Array = []
var quest_line := 0
var quest_pick: Dictionary = {}
var quest_rows: Array = []
var _quest_buttons: Array[Button] = []
## G12b: the row the gamepad has picked out (-1: none; the D-pad moves it, Y takes it, X switches
## the tab). A is still the teleport hold, so the card never takes A.
var quest_pad := -1
var _tab_buttons: Array[Button] = []
## Row and tab heights in points (MIN_TOUCH, 44 pt: four rows still fit under the buttons at 375 pt).
const ROW_H := 44.0
const TAB_H := 44.0
const QUEST_W := 236.0
## Its rows' colours: beaten, next, locked.
const LADDER_COLOURS := {"won": Color("#ffd23f"), "next": Color("#fbf7ee"), "locked": Color("#8f88a0")}


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
	for text in LEGEND:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(4.0 * pt))
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(16.0, 16.0) * pt
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		_legend_icons.append(icon)
		var l := Label.new()
		l.text = Lang.split(text)
		l.add_theme_font_size_override("font_size", _px(T_SUB - 1.0))
		l.add_theme_color_override("font_color", Color("#fbf7ee"))
		row.add_child(l)
		lv.add_child(row)
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
	_list = _card([], [])
	_list.name = "districts"
	_list.visible = false
	add_child(_list)
	_ladder = _card([], [])
	_ladder.name = "ladder"
	_ladder.visible = false
	add_child(_ladder)
	_quests = _card([], [])
	_quests.name = "quests"
	_quests.visible = false
	add_child(_quests)
	_note = _card(["", ""], [T_SUB, T_SUB])
	_note.name = "note"
	_note.visible = false
	add_child(_note)


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
		set_main_line(main_at, keep[0], keep[1])
	car = at
	car_yaw = yaw
	centre = at
	_touches.clear()
	_hold_index = -1
	_note_t = 0.0
	_note.visible = false
	_hint.visible = true
	_hint_words()
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


## Shows or hides the districts' and the ladder's cards (the ≡ button).
func show_cards(on: bool) -> void:
	cards_shown = on
	if not _built:
		return
	_list.visible = _has_list and on
	_ladder.visible = _has_ladder and on
	_quests.visible = not on and not quest_entries.is_empty()
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
	_hint.size = _hint.get_combined_minimum_size()
	_hint.position = Vector2(s.position.x + (s.size.x - _hint.size.x) * 0.5, s.end.y - m - _hint.size.y)
	var below := _head.position.y + _head.size.y + m
	if _quests.visible:
		_quests.size = _quests.get_combined_minimum_size()
		_quests.position = Vector2(s.end.x - m - _quests.size.x, _close.position.y + _close.size.y + m)
	if _ladder.visible:
		_ladder.size = _ladder.get_combined_minimum_size()
		_ladder.position = Vector2(s.end.x - m - _ladder.size.x, _close.position.y + _close.size.y + m)
	if _goal.visible:
		# As wide as its line, but never into the ladder's card or the buttons: then it wraps.
		var right := _ladder.position.x if _ladder.visible else (_quests.position.x if _quests.visible else _cards.position.x)
		_wrap_goal(maxf(120.0 * pt, right - m - (s.position.x + m) - 24.0 * pt))
		_goal.size = _goal.get_combined_minimum_size()
		_goal.position = Vector2(s.position.x + m, below)
		below = _goal.position.y + _goal.size.y + m
	_legend.size = _legend.get_combined_minimum_size()
	_legend.position = Vector2(s.position.x + m, s.end.y - m - _legend.size.y)
	# A narrow screen: the legend gives way to the hold hint (they would meet at the bottom).
	_legend.visible = _legend.position.x + _legend.size.x + m <= _hint.position.x and not _list.visible \
			and not (_quests.visible and Rect2(_legend.position, _legend.size).grow(m * 0.5).intersects(Rect2(_quests.position, _quests.size)))
	if _list.visible:
		_list.size = _list.get_combined_minimum_size()
		_list.position = Vector2(s.position.x + m, below)
	if _note.visible:
		_note.size = _note.get_combined_minimum_size()
		_note.position = Vector2(s.position.x + (s.size.x - _note.size.x) * 0.5, s.end.y - m - _note.size.y)
	_hint.visible = not _note.visible  # the note takes the hint's place for its moment
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
	if _ladder.visible:
		out["ladder"] = _ladder.get_global_rect()
	if _quests.visible:
		out["quests"] = _quests.get_global_rect()
	return out


## The legend's icons, in its rows' order, on top of its card (one batch of their own).
func _paint_legend() -> void:
	if not _legend.visible or _legend_icons.size() != LEGEND.size():
		return
	var ic: Array[Vector2] = []
	for c in _legend_icons:
		ic.append(c.get_global_rect().get_center() - _legend_art.get_global_rect().position)
	hud._tri_begin()
	hud.main_star(ic[0], 1.0)
	hud.story_badge(ic[1], 1.0, Color("#2fb8e0"))  # boat_race.gd COLOUR
	hud.side_pin(ic[2], 1.2, Color("#ff8a3d"))  # jobs.gd KEBAB_COLOUR
	hud.poi_mark(ic[3], 5.4 * pt, Color("#ff8a3d"), MapIcons.POI_KEBAB)
	hud.poi_mark(ic[4], 5.4 * pt, Color("#4fd8c4"), MapIcons.POI_STATION)  # jobs.gd SLOIK_COLOUR
	hud._tri_diamond(ic[5], 4.6 * pt, Color("#5aa0ff"))  # garage.gd GARAGE_COLOUR
	MapIcons.paint_quiet(hud, "metro", MapIcons.METRO, ic[6], 7.5 * pt)
	hud._tri_question(ic[7], 1.3)
	hud._tri_flush(_legend_art)


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


## The main line's marker (map x, z; INF: none) and goal line (hud.gd passes it on open and while
## open). An empty line hides the goal card (the main line is done).
func set_main_line(at: Vector2, pl: String, en: String) -> void:
	var changed := pl != main_pl or en != main_en
	main_at = at
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


## Loop 3h slice 3: the rival ladder's card (ladder.gd `rows`: [text, "won" | "next" | "locked"]);
## call after open(). Labels only: the game is paused under the map.
func set_ladder(rows: Array) -> void:
	if not _built:
		return
	var box: VBoxContainer = _ladder.get_child(0)
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var lines: Array = [[Lang.pick("DRABINKA", "RIVAL LADDER"), ""]]
	lines.append_array(rows)
	for i in lines.size():
		var l := Label.new()
		l.text = str(lines[i][0])
		l.add_theme_font_size_override("font_size", _px(T_TITLE if i == 0 else T_SUB))
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 else
				LADDER_COLOURS.get(str(lines[i][1]), Color.WHITE))
		box.add_child(l)
	_has_ladder = not rows.is_empty()
	_ladder.visible = _has_ladder and cards_shown
	_fit()


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


## The questlines' starts and quest focus (hud.gd `set_story`).
func set_story(points: PackedVector2Array, colours: PackedColorArray, in_focus: bool, names := PackedStringArray()) -> void:
	story_names = names
	story_spots = points
	story_colours = colours
	focus = in_focus


## G12 part 2: the quests on offer now (quest_lines.gd entries), the tab to show first and the id
## of the quest pin (""); call after open().
func set_quests(entries: Array, line: int, pick_id := "") -> void:
	quest_entries = entries
	quest_line = line
	quest_pick = {}
	quest_pad = -1
	for e: Dictionary in entries:
		if str(e["id"]) == pick_id and pick_id != "":
			quest_pick = e
	if not _built:
		return
	_fill_quests()


## Builds the ZADANIA card for `quest_line`: the two tabs (they name it), the rows (or a line saying
## there is nothing to start).
func _fill_quests() -> void:
	var box: VBoxContainer = _quests.get_child(0)
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	_quest_buttons.clear()
	_tab_buttons.clear()
	box.add_theme_constant_override("separation", int(4.0 * pt))
	box.custom_minimum_size.x = QUEST_W * pt
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", int(6.0 * pt))
	box.add_child(tabs)
	# F (2026-11-07): a third tab, WĄTKI, the big questlines (story_quests.gd); in the beta a tap
	# starts one now.
	for line in [Lines.Line.CAR, Lines.Line.HELI, Lines.Line.STORY]:
		var b := Button.new()
		b.name = ["tab_car", "tab_heli", "tab_story"][line]
		b.text = [Lang.pick("AUTO", "CAR"), Lang.pick("HELI", "HELI"), Lang.pick("WĄTKI", "STORIES")][line]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = TAB_H * pt
		b.add_theme_font_size_override("font_size", _px(T_SUB))
		var on: bool = line == quest_line
		var col: Color = _line_colour(line)
		b.add_theme_color_override("font_color", Color("#1a1622") if on else col)
		b.add_theme_color_override("font_hover_color", Color("#1a1622") if on else col)
		b.add_theme_color_override("font_pressed_color", Color("#1a1622"))
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col if on or st == "pressed" else Color(0.16, 0.14, 0.22, 0.95)
			sb.set_corner_radius_all(_px(8))
			sb.border_color = col
			sb.set_border_width_all(_px(2))
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(show_line.bind(line))
		tabs.add_child(b)
		_tab_buttons.append(b)
	quest_rows = Lines.rows(quest_entries, quest_line, car)
	quest_pad = mini(quest_pad, quest_rows.size() - 1)
	if Gamepad.in_use():
		# G12b: the pad's words for the card (A stays the teleport hold).
		var keys := Label.new()
		keys.name = "pad_keys"
		keys.text = Gamepad.fmt(Lang.pick("{x}: AUTO / HELI / WĄTKI · krzyżak: wybór · {y}: bierz", "{x}: CAR / HELI / STORIES · D-pad: pick · {y}: take"))
		keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		keys.custom_minimum_size.x = QUEST_W * pt
		keys.add_theme_font_size_override("font_size", _px(T_SUB))
		keys.add_theme_color_override("font_color", Gamepad.RING)
		box.add_child(keys)
	if quest_rows.is_empty():
		var none := Label.new()
		none.text = Lang.pick("Na razie nic. Skończ to, co trwa, albo zajrzyj później.",
				"Nothing to start now. Finish what's on, or look again later.")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.custom_minimum_size.x = QUEST_W * pt
		none.add_theme_font_size_override("font_size", _px(T_SUB))
		none.add_theme_color_override("font_color", Color("#c9c2d8"))
		box.add_child(none)
	# The WĄTKI tab lists every questline: past MAX_ROWS rows they scroll (the card keeps its size).
	var holder: Container = box
	if quest_rows.size() > Lines.MAX_ROWS:
		var scroll := ScrollContainer.new()
		scroll.name = "story_scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(QUEST_W, (ROW_H + 4.0) * Lines.MAX_ROWS) * pt
		box.add_child(scroll)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", int(4.0 * pt))
		scroll.add_child(inner)
		holder = inner
	for i in quest_rows.size():
		var r: Dictionary = quest_rows[i]
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
		b.pressed.connect(pick_row.bind(i))
		holder.add_child(b)
		_quest_buttons.append(b)
	_quests.reset_size()
	_quests.visible = not cards_shown and not quest_entries.is_empty()
	_fit()


## A tab's colour: the car's amber pickup, the helicopter's violet, the questlines' pink
## (colour-safe aware).
func _line_colour(line: int) -> Color:
	if line == Lines.Line.STORY:
		return Access.tint(Lines.STORY_COLOUR)
	return Access.tint(Lines.HELI_COLOUR if line == Lines.Line.HELI else Color("#ff8a3d"))


## Shows the AUTO or HELI tab (Lines.Line).
func show_line(line: int) -> void:
	quest_line = line
	if _built:
		_fill_quests()


## G12b: a gamepad button on the ZADANIA card: X switches the tab (its first row picked out), the
## D-pad up / down moves the pick (a place's row centres the map on it, as a look before taking
## it), Y takes the row picked out as a tap would. True when the card used the press.
func pad_quest(button: int) -> bool:
	if not _quests.visible:
		return false
	match button:
		JOY_BUTTON_X:
			show_line((quest_line + 1) % 3)  # AUTO, HELI, WĄTKI
			pad_select(0)
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


## G12b: moves the pad's pick `dir` rows (0: the first row, or none on an empty tab).
func pad_select(dir: int) -> void:
	quest_pad = Lines.pad_move(quest_pad if dir != 0 else -1, quest_rows.size(), 1 if dir == 0 else dir)
	if quest_pad >= 0:
		var r: Dictionary = quest_rows[quest_pad]
		if r["at"] != Vector2.INF:
			centre = r["at"]
	if _built:
		_fill_quests()
		_place()


## Row `i` of the tab shown was tapped: a request closes the map and starts (main.gd); a place
## becomes the quest pin and the map centres on it, or, picked already, the pin goes.
func pick_row(i: int) -> void:
	if i < 0 or i >= quest_rows.size():
		return
	var r: Dictionary = quest_rows[i]
	if str(r["action"]) == Lines.NOW:
		# G12c: the quest under way: the map looks at its target; nothing else changes.
		if r["at"] != Vector2.INF:
			centre = r["at"]
			_place()
		print("full map: quest under way %s" % r["id"])
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
	for i in (0 if focus else side_spots.size()):
		var at := to_screen(side_spots[i])
		if view.has_point(at):
			hud.poi_mark(at, 5.2 * pt, side_colours[i] if i < side_colours.size() else Color.WHITE,
					side_shapes[i] if i < side_shapes.size() else MapIcons.POI_SQUARE)
	for q in found:
		var at := to_screen(q)
		if view.has_point(at):
			hud._tri_fan(at, 4.2 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 3.0 * pt, 0.0, TAU, GOLD)
	for q in (PackedVector2Array() if focus else unknown):
		var at := to_screen(q)
		if view.has_point(at):
			hud._tri_question(at, 1.6)
	if scene_mark != Vector2.INF:
		var at := to_screen(scene_mark)
		if view.has_point(at):
			hud._tri_fan(at, 4.4 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 3.2 * pt, 0.0, TAU, hud.SCENE_AMBER)
	# The questlines' starts: the "!" badges, bigger than any street job's icon (none in focus).
	for i in story_spots.size():
		var at := to_screen(story_spots[i])
		if view.has_point(at):
			hud.story_badge(at, 2.3, story_colours[i] if i < story_colours.size() else Color.WHITE)
	if garage != Vector2.INF and not focus:
		var g := to_screen(garage)
		if view.has_point(g):
			hud._tri_diamond(g, 6.5 * pt, garage_colour)
	# Loop 3h slice 3's diamond at the final's start is the main line's star now.
	if target != Vector2.INF:
		hud.side_pin(to_screen(target), 1.5, target_colour)
	if quest_pick.get("at", Vector2.INF) != Vector2.INF:
		hud.side_pin(to_screen(quest_pick["at"]), 1.9, Access.tint(quest_pick["colour"]))  # G12: the quest pin
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
	hud._tri_flush(o)
	var font := ThemeDB.fallback_font
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
	for i in mini(story_spots.size(), story_names.size()):
		var text := story_names[i]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ns).x
		var p := to_screen(story_spots[i]) + Vector2(-w * 0.5, 21.0 * pt + ns)
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
		var col := Access.tint(story_colours[i]) if i < story_colours.size() else Color.WHITE
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
	if _note_t > 0.0:
		_note_t -= dt
		if _note_t <= 0.0:
			_note.visible = false
			_fit()
	_pad_frame(dt)
	if main_at != Vector2.INF and _hold_index < 0:
		_overlay.queue_redraw()  # the star's ring pulses (one batch, the game paused under it)
		_legend_art.queue_redraw()
	if _hold_index < 0:
		return
	_hold_t += dt
	if _hold_t >= HOLD_S:
		_finish_hold()
	_overlay.queue_redraw()


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
					or (_quests.visible and _quests.get_global_rect().has_point(t.position)):
				return  # the ✕, ≡ or the ZADANIA card takes it
			_touches[t.index] = t.position
			if _touches.size() == 1:
				_start_hold(t.index, t.position)
			else:
				_cancel_hold()  # a second finger: a pinch
		else:
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
