extends Control
## Loop 2a: the settings panel, opened by the gear in the HUD's top left (or Esc). The game
## pauses under it (main.gd). Polish first with the English under it, every control at least
## 44 pt (the iPhone guideline). Emits `changed(key, value)` for each change (main.gd applies
## and saves it) and `closed`.
##
## Loop 2e: sized in points throughout (text too: 11 pt and up), in the HUD's card recipe, and
## in four tabs so it fits a phone 390 pt tall without shrinking, now that the driving screen's
## toggles live here:
##   Jazda · Driving: Controls (Point / Classic, with a line saying what the scheme does) and
##     "Kamera za autem · Camera follows the car" On / Off (the old CAM button, now with its
##     state in view; Point with the camera off is the Fixed camera scheme);
##   Świat · World: Time of day (the old TIME button), Weather (RAIN), Traffic;
##   Obraz · Picture: Retro and the camera angle (F, 2026-11-07: 30°, 40°, 50°), Quality (loop G1: Auto, the default, then Low, Medium,
##     High, Ultra; Auto's English line names the level it picked here), VHS tape (VHS), Frame
##     rate, the performance overlay and the TEST bench;
##   Dźwięk · Sound: volume, radio, effects (− and + in tenths, or drag along the bar).
## Loop MW-1: a fifth tab, ZESZYT · notebook: MOJA WARSZAWA, the city notebook
## (notebook_page.gd); the card's title says MOJA WARSZAWA there, with the count found.
## Loop MW-6: Jazda gets "Tryb gry · Game mode" (Miasto / Spacer: vision.md 4.3) under the camera,
## and Obraz the FOTKA button beside TEST (closes the card and opens the photo mode: fotka.gd).
## F's asks (2026-10-30): Jazda gets "Strefy piesze 20 km/h · Pedestrian zones 20 km/h" Off / On
## under the mode (settings.gd `zone_cap`, off by default: key "zones").
## 2026-11-01: Jazda's first column ends with "Utknąłeś? · Stuck?" and POMOC DROGOWA (closes the
## card and tows the car onto the nearest road: main.gd `_unstuck`, key "unstuck").

signal changed(key: String, value: Variant)
signal closed

const Lang := preload("res://scripts/lang.gd")  # one language at a time
const ACCENT := Color("#ffd23f")
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const DIM := Color(1, 1, 1, 0.07)
## The HUD's card recipe (hud.gd CARD_BG).
const CARD_BG := Color(0.07, 0.06, 0.1, 0.94)
## Type sizes in points (hud.gd's scale).
const T_HEAD := 22.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
## Loop MW-1: the notebook tab's title size (hud.gd T_TITLE).
const T_NOTES := 17.0

const TABS := [["JAZDA", "driving"], ["ŚWIAT", "world"], ["OBRAZ", "picture"], ["DŹWIĘK", "sound"], ["ZESZYT", "notebook"], ["DOSTĘP", "access"]]
## Loop MW-1: the notebook's tab. The accessibility tab comes last (index 5) so the notebook keeps
## its index 4.
const NOTEBOOK_TAB := 4
const ACCESS_TAB := 5
## DEMO 3j: the credits page, after the tabs' pages; no tab of its own (DŹWIĘK → LICENCJE opens it,
## and its tab stays lit).
const CREDITS_PAGE := 6
const SOUND_TAB := 3
const Credits := preload("res://scripts/credits.gd")
const NotebookPage := preload("res://scripts/notebook_page.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
const DRIVE := [["Wskaż", "Point"], ["Klasycznie", "Classic"]]
## Loop 2e: the camera choice, explicit (it was the CAM button, easy to switch off unnoticed):
## on, it follows the car (Point; Classic's default), off it stays put (Fixed camera; Classic
## with the camera fixed).
const CAMERA := [["Wł.", "On"], ["Wył.", "Off"]]
## What each scheme (drive_controls.gd POINT, CLASSIC, FIXED) does, in a line.
const CONTROLS_SAY := [
	["Pokaż palcem, dokąd jechać. Kamera jedzie za autem.", "Point where to go. The camera follows the car."],
	["Kierownica lewo–prawo, gaz i hamulec po prawej.", "Steer left–right; GAS and BRAKE on the right."],
	["Pokaż palcem, dokąd jechać. Kamera stoi: obróć ją dwoma palcami.", "Point where to go. The camera stays put: twist two fingers to turn it."],
]
## Loop MW-3: Świt (Dawn) last, the mode's index (time_of_day.gd DAWN after LIVE).
const TIME := [["Dzień", "Day"], ["Zmierzch", "Dusk"], ["Noc", "Night"], ["Na żywo", "Live"], ["Świt", "Dawn"]]
const WEATHER := [["Pogodnie", "Clear"], ["Deszcz", "Rain"]]
const TRAFFIC := [["Pustawo", "Almost empty"], ["Mało", "Low"], ["Normalnie", "Normal"], ["Tłoczno", "Busy"]]
## Loop G1: index 0 is Auto (settings.gd AUTO), then the levels (tiers.gd LOW..ULTRA) one up.
const QUALITY := [["Auto", "auto"], ["Niska", "Low"], ["Średnia", "Medium"], ["Wysoka", "High"], ["Ultra", "Ultra"]]
const ON_OFF := [["Wył.", "Off"], ["Wł.", "On"]]
## F (2026-11-07): the camera's angle over the ground, follow_camera.gd PITCHES (30° the default).
const ANGLE := [["30°", "30°"], ["40°", "40°"], ["50°", "50°"]]
## Loop 2b: frames per second (settings.gd FPS: 60, 30) and the benchmark button.
const FPS := [["60 płynnie", "60 smooth"], ["30 bateria", "30 battery"]]
## Loop MW-6: the game's mode (settings.gd `wander`).
const MODE := [["Miasto", "City"], ["Spacer", "Wander"]]
## G4: the car's handling (settings.gd `handling`, car.gd PROFILES).
const HANDLING := [["Spokojnie", "Cruise"], ["Sportowo", "Sport"]]
## Phase 0.2: the city's chattiness (settings.gd `chatter`, chatter.gd GAPS).
const CHATTER := [["Mało", "Quiet"], ["Średnio", "Some"], ["Dużo", "Lots"]]
const LEVELS := [["master", "Głośność", "Volume"], ["music", "Radio", "Radio"], ["effects", "Efekty", "Effects"]]

## Loop 2e: pixels per point and the safe area in pixels (from the HUD, screen_points.gd).
var pt := 1.0
var safe := Rect2()
## The smallest touch target in pixels (44 pt).
var touch := 132.0
var _card: PanelContainer
var _groups := {}
var _bars := {}
var _values := {}
## G16: stepped sliders (traffic): key -> bar; the chosen step is in `_values`.
var _stepbars := {}
var _say_pl: Label
var _say_en: Label
var _tabs: Array[Button] = []
var _pages: Array[Control] = []
var _tab := 0
var _built := false
## Loop G1: the level Auto picked on this device (the state's "auto", in English), shown under
## the Auto button.
var _auto_name := "High"
## Loop MW-1: the notebook (notebook.gd; set before the panel first opens), its page, the
## card's title and line under it (they say MOJA WARSZAWA on the notebook's tab), the
## settings pages' size and a --notebook= target to show.
var notebook: Node
var notebook_page: Control
## Loop MW-6: the notebook page's extra sections (egg_book.gd, tape.gd, fotka.gd), set before the
## panel first opens.
var notebook_eggs: Node
var notebook_tape: Node
var notebook_kadr: Node
var _title: Label
var _subtitle: Label
var _subtitle_en: Label
var _settings_size := Vector2.ZERO
var _body: Control
var _target := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	get_viewport().size_changed.connect(_fit)


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


func _build() -> void:
	_built = true
	touch = 44.0 * pt
	if not safe.has_area():
		safe = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.05, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	# A tap beside the card closes it.
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	add_child(shade)

	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.set_corner_radius_all(_px(12))
	style.set_content_margin_all(14.0 * pt)
	style.border_color = Color(1, 1, 1, 0.16)
	style.set_border_width_all(maxi(1, roundi(0.5 * pt)))
	style.border_width_left = _px(3)
	style.border_color = ACCENT
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", style)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", _px(10))
	_card.add_child(rows)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", _px(8))
	rows.add_child(head)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(titles)
	# Loop MW-1: the line under the title in two (Polish over English), and the column as wide as
	# MOJA WARSZAWA (the notebook tab's title, at T_NOTES): the fifth tab fits a 375 pt phone.
	_title = _text(Lang.pick("USTAWIENIA", "SETTINGS"), T_HEAD, ACCENT)
	_subtitle = _text(Lang.pick("gra wstrzymana", "game paused"), T_SUB, SUB)
	_subtitle_en = _text("", T_LABEL, SUB)
	_subtitle_en.visible = false
	titles.add_child(_title)
	titles.add_child(_subtitle)
	titles.add_child(_subtitle_en)
	titles.custom_minimum_size.x = ThemeDB.fallback_font.get_string_size(Lang.pick("MOJA WARSZAWA", "MY WARSAW"), HORIZONTAL_ALIGNMENT_LEFT, -1,
			_px(T_NOTES)).x
	for i in TABS.size():
		var b := _word_button(TABS[i][0], String(TABS[i][1]).to_upper())
		b.toggle_mode = true
		b.name = "tab_%s" % TABS[i][1]
		_tighten(b, TABS[i][0], String(TABS[i][1]).to_upper())
		b.pressed.connect(set_tab.bind(i))
		head.add_child(b)
		_tabs.append(b)
	var x := _flat_button("✕", 22)
	x.name = "close"
	x.custom_minimum_size = Vector2(touch, touch)
	x.pressed.connect(close)
	head.add_child(x)

	var body := Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(body)
	_body = body

	# Jazda · Driving.
	var drive := _page(body, 2)
	# G14 (F, 2026-11-01): the two rescue buttons at the top of the first tab, where they are found:
	# the tow onto the nearest road, and a new game (two taps: the second wipes the progress).
	var rescue := HBoxContainer.new()
	rescue.add_theme_constant_override("separation", _px(8))
	drive[0].add_child(rescue)
	var tow := _word_button("POMOC DROGOWA", "TOW TRUCK")
	tow.name = "unstuck"
	tow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tow.pressed.connect(func():
		close()
		changed.emit("unstuck", 1))
	rescue.add_child(tow)
	_new_game_button = _word_button("NOWA GRA", "NEW GAME")
	_new_game_button.name = "new_game"
	_new_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_game_button.pressed.connect(_on_new_game_pressed)
	rescue.add_child(_new_game_button)

	_heading(drive[0], "Sterowanie", "Controls")
	_segments(drive[0], "drive", DRIVE)
	_say_pl = _text("", T_SUB, INK)
	_say_en = _text("", T_SUB, SUB)
	for l in [_say_pl, _say_en]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 240.0 * pt
		drive[0].add_child(l)
	_level(drive[0], "sensitivity", "Czułość", "Steering", 120.0)
	_heading(drive[1], "Kamera za autem", "Camera follows the car")
	_segments(drive[1], "camera", CAMERA)
	_heading(drive[1], "Prowadzenie", "Handling")
	_segments(drive[1], "handling", HANDLING)
	# Beta values (2026-11-04): the lane assist (lane_assist.gd), Classic only, off by default,
	# side by side with the pedestrian zones (a fourth row made the panel too tall for the phone).
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", _px(8))
	pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive[1].add_child(pair)
	var zones := VBoxContainer.new()
	zones.add_theme_constant_override("separation", _px(6))
	pair.add_child(zones)
	_heading(zones, "Strefy piesze 20 km/h", "Pedestrian zones 20 km/h")
	_segments(zones, "zones", ON_OFF)
	var lane := VBoxContainer.new()
	lane.add_theme_constant_override("separation", _px(6))
	pair.add_child(lane)
	_heading(lane, "Asysta pasa", "Lane assist")
	_segments(lane, "lane_assist", ON_OFF)
	# Świat · World.
	var world := _page(body, 2)
	_heading(world[0], "Pora dnia", "Time of day")
	_segments(world[0], "time", TIME)
	_heading(world[0], "Pogoda", "Weather")
	_segments(world[0], "weather", WEATHER)
	_heading(world[0], "Ruch uliczny", "Traffic")
	_steps(world[0], "traffic", TRAFFIC)
	_heading(world[1], "Tryb gry", "Game mode")
	_segments(world[1], "wander", MODE)
	_heading(world[1], "Gadatliwość miasta", "City chattiness")
	_segments(world[1], "chatter", CHATTER)
	# Three choices beside the five times of day: narrower buttons (still over 44 pt) so the
	# page keeps the card's width on a 375 pt phone.
	for b: Button in _groups["chatter"]:
		b.custom_minimum_size.x = touch * 1.3
	# Obraz · Picture. Loop G1: in three rows (Quality's five choices made the two columns too
	# wide for the SE): Style and VHS; Quality; Frame rate and the overlay with TEST.
	# 2026-11-01 (F): the Style picker is gone (always the sharp image); the old VHS tape is now
	# the "Retro" vaporwave filter (vhs.gdshader), the one switch left in the first row.
	# F (2026-11-07): the camera's angle beside Retro (follow_camera.gd PITCHES, key "angle").
	var picture := _rows(body, [2, 1, 2])
	_heading(picture[0], "Retro · vaporwave", "Retro filter")
	_segments(picture[0], "vhs", ON_OFF)
	_heading(picture[1], "Kąt kamery", "Camera angle")
	_segments(picture[1], "angle", ANGLE)
	_heading(picture[2], "Jakość obrazu", "Quality")
	var quality := QUALITY.duplicate(true)
	quality[0] = ["Auto · %s" % _auto_name, "Auto · %s" % _auto_name]
	_segments(picture[2], "quality", quality)
	_heading(picture[3], "Klatki na sekundę", "Frame rate")
	_segments(picture[3], "fps", FPS)
	_heading(picture[4], "Licznik wydajności", "Performance overlay")
	var perf_row := HBoxContainer.new()
	perf_row.add_theme_constant_override("separation", _px(6))
	picture[4].add_child(perf_row)
	_segments(perf_row, "perf", ON_OFF)
	# Loop 2b: a minute on the bench route, then a result card to copy (main.gd).
	var bench := _word_button("TEST", "BENCH")
	bench.name = "bench"
	bench.pressed.connect(func():
		close()
		changed.emit("bench", 1))
	perf_row.add_child(bench)
	# Loop MW-6: the photo mode (fotka.gd), from the pause card.
	var photo := _word_button("FOTKA", "PHOTO")
	photo.name = "fotka"
	photo.pressed.connect(func():
		close()
		changed.emit("fotka", 1))
	perf_row.add_child(photo)
	# Dźwięk · Sound.
	var sound := _page(body, 2)
	for l in LEVELS:
		_level(sound[0], l[0], l[1], l[2])
	# 2026-11-02 (F): the language, one at a time (lang.gd): POLSKI or ENGLISH.
	_heading(sound[1], "Język", "Language")
	_segments(sound[1], "lang", [["Polski", "Polski"], ["English", "English"]])
	# DEMO 3j: the credits and licences (credits.gd), a page of their own opened from here.
	_heading(sound[1], "O grze", "About")
	var about := _word_button("LICENCJE", "CREDITS")
	about.name = "credits"
	about.pressed.connect(show_credits)
	sound[1].add_child(about)

	# DOSTĘP · Access (access.gd): built here so the card is sized for it, moved after the
	# notebook's page below (the notebook keeps tab 4).
	var access_at := _pages.size()
	var access := _page(body, 2)
	_heading(access[0], "Duży tekst", "Larger text (after restart)")
	_segments(access[0], "text_large", ON_OFF)
	_heading(access[0], "Spokojny obraz", "Calm: no flashing or shaking")
	_segments(access[0], "calm", ON_OFF)
	_heading(access[0], "Kolory dla daltonistów", "Colour-safe markers")
	_segments(access[0], "color_safe", ON_OFF)
	_heading(access[1], "Wibracje", "Vibration")
	_segments(access[1], "vibration", ON_OFF)
	_heading(access[1], "Pomoc przy zatrzymaniu", "Stop assist at pick-ups")
	_segments(access[1], "stop_assist", ON_OFF)
	_heading(access[1], "Dla leworęcznych", "Left-handed: pedals on the left")
	_segments(access[1], "left_handed", ON_OFF)

	# The body is as big as the biggest page, so the card keeps its size from tab to tab.
	var biggest := Vector2.ZERO
	for p in _pages:
		biggest = biggest.max(p.get_combined_minimum_size())
	body.custom_minimum_size = biggest
	for p in _pages:
		p.size = biggest
	_settings_size = biggest
	# Loop MW-1: the notebook's page, sized on its own (the settings tabs keep their size).
	notebook_page = NotebookPage.new()
	notebook_page.name = "notebook"
	notebook_page.pt = pt
	notebook_page.book = notebook
	notebook_page.eggs = notebook_eggs
	notebook_page.tape = notebook_tape
	notebook_page.kadr = notebook_kadr
	body.add_child(notebook_page)
	_pages.append(notebook_page)
	_pages.append(_pages[access_at])
	_pages.remove_at(access_at)
	notebook_page.size = notebook_page.custom_minimum_size
	_credits_page(body)
	if _target != "":
		notebook_page.show_target(_target)
	set_tab(_tab)


## Settings → Język: the panel is made again in the chosen language (hud.gd `language_changed`),
## on the tab that was open, with the values in `state`.
func rebuild(state: Dictionary) -> void:
	if not _built:
		return
	var was_visible := visible
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_groups.clear()
	_bars.clear()
	_values.clear()
	_stepbars.clear()
	_tabs.clear()
	_pages.clear()
	_new_game_armed = false
	_built = false
	_build()
	_built = true
	sync(state)
	visible = was_visible
	set_tab(_tab)
	_fit()
	if Gamepad.in_use():
		pad_focus()


## A page of the panel: `columns` columns side by side; returns the columns.
func _page(parent: Control, columns: int) -> Array[VBoxContainer]:
	var page := HBoxContainer.new()
	page.add_theme_constant_override("separation", _px(24))
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(page)
	_pages.append(page)
	var out: Array[VBoxContainer] = []
	for i in columns:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", _px(6))
		page.add_child(col)
		out.append(col)
	return out


## Loop G1: a page of rows, row i with `cells[i]` cells side by side (the columns' spacing);
## returns the cells in order.
func _rows(parent: Control, cells: Array[int]) -> Array[VBoxContainer]:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", _px(6))
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(page)
	_pages.append(page)
	var out: Array[VBoxContainer] = []
	for n in cells:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", _px(24))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(row)
		for i in n:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", _px(6))
			row.add_child(cell)
			out.append(cell)
	return out


## Shows tab `i` (0 Driving, 1 World, 2 Picture, 3 Sound, 4 Notebook, 5 Access; 6 the credits page).
func set_tab(i: int) -> void:
	_tab = clampi(i, 0, CREDITS_PAGE if _built else TABS.size() - 1)
	if not _built:
		return
	var lit := SOUND_TAB if _tab == CREDITS_PAGE else _tab
	for k in _pages.size():
		_pages[k].visible = k == _tab
	for k in _tabs.size():
		_tabs[k].set_pressed_no_signal(k == lit)
	# Loop MW-1: the notebook's tab has its own size and title.
	var on_notes := _tab == NOTEBOOK_TAB
	var on_credits := _tab == CREDITS_PAGE
	_body.custom_minimum_size = notebook_page.custom_minimum_size if on_notes else _settings_size
	_title.text = Lang.pick("MOJA WARSZAWA", "MY WARSAW") if on_notes else (Lang.pick("O GRZE", "ABOUT") if on_credits else Lang.pick("USTAWIENIA", "SETTINGS"))
	_title.add_theme_font_size_override("font_size", _px(T_NOTES if on_notes else T_HEAD))
	_subtitle.text = _notes_count() if on_notes else (Lang.pick("licencje i autorzy", "credits and licences") if on_credits else Lang.pick("gra wstrzymana", "game paused"))
	_subtitle_en.text = ""
	if on_notes:
		notebook_page.queue_redraw()
	_fit()


## DEMO 3j: shows the credits and licences (DŹWIĘK → LICENCJE; any tab goes back).
func show_credits() -> void:
	set_tab(CREDITS_PAGE)
	if Gamepad.in_use():
		pad_focus()


## DEMO 3j: the credits page: credits.gd's sections in a column that scrolls (a finger drag or
## the pad), as big as the settings pages so the card keeps its size.
func _credits_page(body: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "credits_page"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size = _settings_size
	scroll.custom_minimum_size = _settings_size
	body.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _px(4))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size.x = _settings_size.x - 16.0 * pt
	scroll.add_child(col)
	for s in Credits.sections():
		_heading(col, s[0], s[1])
		for line in s[2]:
			var l := _text(Lang.split(String(line), " ‖ "), T_SUB, INK)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = col.custom_minimum_size.x
			col.add_child(l)
	_pages.append(scroll)


## Loop MW-1: "zeszyt miasta · 12/72" (the line under MOJA WARSZAWA).
func _notes_count() -> String:
	if notebook == null or notebook.places.is_empty():
		return Lang.pick("zeszyt miasta", "the city notebook")
	return Lang.pick("zeszyt miasta · %d/%d", "the city notebook · %d/%d") % [notebook.found_total(), notebook.places.size()]


## Loop MW-1: opens on the notebook (--notebook=TARGET: a chapter or a place's card).
func show_notebook(target: String) -> void:
	_target = target
	_tab = NOTEBOOK_TAB
	if _built:
		notebook_page.show_target(target)
		set_tab(NOTEBOOK_TAB)


## Loop MW-1: the record changed (a new entry) while the panel is built: the page and count follow.
func refresh_notebook() -> void:
	if _built:
		notebook_page.queue_redraw()
		if _tab == NOTEBOOK_TAB:
			_subtitle.text = _notes_count()


## Shows the panel with the current values: {controls (the scheme), follow, traffic, quality
## (0 Auto, 1-4 Low..Ultra), auto (the level Auto picked, by name), master, music, effects,
## perf, fps, style, vhs, weather, time}.
func open(state: Dictionary) -> void:
	if not _built:
		_auto_name = str(state.get("auto", _auto_name))
		_build()
	sync(state)
	visible = true
	set_tab(_tab)  # loop MW-1: the notebook's count and page as they are now
	_fit()
	if Gamepad.in_use():
		pad_focus()
	elif _built:
		Gamepad.focus_none(_card)
		for key in _bars:
			(_bars[key] as Control).focus_mode = Control.FOCUS_NONE
		if notebook_page != null:
			notebook_page.focus_mode = Control.FOCUS_NONE


## The gamepad loop: the card's buttons take focus (the D-pad or the left stick moves it, A
## presses, LB / RB change the tab, B or Start closes), with an accent ring on the focused one.
## Only once the pad opened the card: touch never sees a focus ring.
func pad_focus() -> void:
	if not _built:
		return
	Gamepad.focus_all(_card, pt)
	# The follow-ups: the volume bars (D-pad left / right step them) and the notebook's page (its
	# own cursor over the drawn targets, notebook_page.gd) take focus too.
	for key in _bars:
		(_bars[key] as Control).focus_mode = Control.FOCUS_ALL
	if notebook_page != null:
		notebook_page.focus_mode = Control.FOCUS_ALL
	focus_target().grab_focus()


## The button the pad's focus starts on: the open tab's.
func focus_target() -> Button:
	return _tabs[SOUND_TAB if _tab == CREDITS_PAGE else _tab]


## The current values again (after a change that moves another row: Classic's camera).
func sync(state: Dictionary) -> void:
	if not _built:
		return
	var scheme := int(state.get("controls", 1))  # Classic, the default (settings.gd DEFAULT_CONTROLS)
	var follow := bool(state.get("follow", scheme != 2))
	var values := state.duplicate()
	values["drive"] = 1 if scheme == 1 else 0
	values["camera"] = 0 if follow else 1
	# Loop G1b: what Auto draws can change with the style ("High ostry" / "High ×2" / "High").
	_set_auto_name(str(state.get("auto", _auto_name)))
	for key in _groups:
		_select(key, int(values.get(key, 0)))
	for key in _stepbars:
		_values[key] = int(values.get(key, 0))
		(_stepbars[key] as Control).queue_redraw()
	for key in _bars:
		_values[key] = float(state.get(key, 1.0))
		(_bars[key] as Control).queue_redraw()
	_say(scheme)


func close() -> void:
	if not visible:
		return
	Gamepad.drop_focus(_card)
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Loop 2e, for tools/check_hud.gd: the card's scale (1 unless the window is too small for it)
## and every button on the open tab, by name, in pixels.
func card_scale() -> float:
	return _card.scale.x if _card != null else 1.0


func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size * _card.scale) if _card != null else Rect2()


func button_rects() -> Dictionary:
	var out := {}
	if _card == null:
		return out
	for b in _card.find_children("*", "Button", true, false):
		var c := b as Control
		if c.is_visible_in_tree():
			out[str(_card.get_path_to(c))] = c.get_global_rect()
	# Loop MW-1: the notebook page's targets (drawn, not Buttons).
	if notebook_page != null and notebook_page.is_visible_in_tree():
		out.merge(notebook_page.hit_rects())
	return out


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## The gamepad loop: B, Start or Back close the card; LB / RB change the tab.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if Gamepad.closes(event):
		close()
		get_viewport().set_input_as_handled()
		return
	var b := event as InputEventJoypadButton
	if b != null and b.pressed and b.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		var step := -1 if b.button_index == JOY_BUTTON_LEFT_SHOULDER else 1
		set_tab(wrapi(_tab + step, 0, TABS.size()))
		pad_focus()
		get_viewport().set_input_as_handled()


## Centred in the safe area; scaled down only if the window is too small for it (never on the
## phones tools/check_hud.gd measures).
func _fit() -> void:
	if _card == null or not visible:
		return
	_card.scale = Vector2.ONE
	_card.reset_size()
	var need := _card.get_combined_minimum_size()
	var room := safe.grow(-8.0 * pt).size
	var k := minf(1.0, minf(room.x / maxf(need.x, 1.0), room.y / maxf(need.y, 1.0)))
	_card.scale = Vector2(k, k)
	_card.size = need
	# Loop MW-1: the notebook's page as wide as the card's inside (the tabs set the card's width).
	if notebook_page != null:
		var inner := need.x - 28.0 * pt
		notebook_page.size = Vector2(maxf(notebook_page.custom_minimum_size.x, inner), notebook_page.custom_minimum_size.y)
		notebook_page.queue_redraw()
	_card.position = safe.get_center() - need * k * 0.5


# --- pieces --------------------------------------------------------------------------------------

func _text(s: String, points: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", _px(points))
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _heading(parent: Node, pl: String, en: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(8))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_text(Lang.pick(pl, en).to_upper(), T_SUB, ACCENT))
	parent.add_child(row)


func _box(bg: Color, border: Color, width: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(_px(8))
	s.border_color = border
	s.set_border_width_all(maxi(1, roundi(width * pt)))
	s.set_content_margin_all(4.0 * pt)
	return s


func _flat_button(label: String, points: float) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", _px(points))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", ACCENT)
	var normal := _box(DIM, Color(1, 1, 1, 0.18), 0.5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	var on := _box(Color(1, 0.82, 0.25, 0.22), ACCENT, 1.0)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


## A 44 pt button with the Polish word (15 pt) over the English one (11 pt); its width follows
## the words.
var _new_game_button: Button
var _new_game_armed := false


## NOWA GRA in the settings: the first tap asks, the second (within 4 s) wipes the save.
func _on_new_game_pressed() -> void:
	if not _new_game_armed:
		_new_game_armed = true
		_set_word_button(_new_game_button, "NA PEWNO?", "SURE? TAP AGAIN")
		get_tree().create_timer(4.0).timeout.connect(_disarm_new_game)
		return
	_new_game_armed = false
	close()
	changed.emit("new_game", 1)


func _disarm_new_game() -> void:
	if _new_game_armed:
		_new_game_armed = false
		_set_word_button(_new_game_button, "NOWA GRA", "NEW GAME")



func _word_button(pl: String, en: String) -> Button:
	var b := _flat_button("", T_BODY)
	b.custom_minimum_size = Vector2(touch * 1.45, touch)
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := _text(Lang.pick(pl, en), T_BODY, INK)
	var low := _text("", T_LABEL, SUB)  # the second line is gone: one language (lang.gd)
	low.visible = false
	for l in [top, low]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
	b.add_child(words)
	_fit_words(b, pl, en)
	return b


## A word button's two lines changed (the words are its first child's labels).
func _set_word_button(b: Button, pl: String, en: String) -> void:
	var words := b.get_child(0)
	(words.get_child(0) as Label).text = Lang.pick(pl, en)
	(words.get_child(1) as Label).text = ""


## The words set the button's width (a Button doesn't size to its children); measured with the
## font itself (a label outside the tree can under-measure).
func _fit_words(b: Button, pl: String, en: String) -> void:
	pl = Lang.pick(pl, en)
	en = ""
	var font := ThemeDB.fallback_font
	var w := maxf(font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x,
			font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x) + 24.0 * pt
	b.custom_minimum_size.x = maxf(touch * 1.45, w)


## The six tabs share one row: their buttons are as wide as their words need plus a little, not
## the 1.45 x 44 pt of the option buttons (still 44 pt tall, and never narrower than 44 pt).
func _tighten(b: Button, pl: String, en: String) -> void:
	pl = Lang.pick(pl, en)
	en = ""
	var font := ThemeDB.fallback_font
	var w := maxf(font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x,
			font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x) + 12.0 * pt
	b.custom_minimum_size.x = maxf(touch, w)


## Loop G1b: the Auto button's English line, "auto · High ostry" (the sharp image), "auto · High
## ×2" (its fallback) or "auto · High", kept up to date while the panel is open.
func _set_auto_name(name: String) -> void:
	if name == _auto_name and _built:
		return
	_auto_name = name
	if not _groups.has("quality"):
		return
	var b: Button = _groups["quality"][0]
	var top: Label = b.get_child(0).get_child(0)
	top.text = "Auto · %s" % name
	_fit_words(b, top.text, top.text)
	_fit()


## A row of options (one chosen), each a button with the Polish word over the English.
func _segments(parent: Node, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(6))
	parent.add_child(row)
	var buttons: Array[Button] = []
	for i in options.size():
		var b := _word_button(options[i][0], options[i][1])
		b.name = "%s_%d" % [key, i]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			_select(key, i)
			changed.emit(key, i))
		row.add_child(b)
		buttons.append(b)
	_groups[key] = buttons


## A slider with one notch per option (tap or drag along the bar), the chosen words beneath.
func _steps(parent: Node, key: String, options: Array) -> void:
	var bar := Control.new()
	bar.name = "%s_slider" % key
	bar.custom_minimum_size = Vector2(260.0 * pt, touch + 22.0 * pt)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.draw.connect(_draw_steps.bind(bar, key, options))
	bar.gui_input.connect(func(e: InputEvent):
		var at := -1.0
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			at = (e as InputEventMouseButton).position.x
		elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			at = (e as InputEventMouseMotion).position.x
		if at >= 0.0:
			var pad := 14.0 * pt
			var f := clampf((at - pad) / maxf(bar.size.x - pad * 2.0, 1.0), 0.0, 1.0)
			var i := roundi(f * (options.size() - 1))
			if i != int(_values.get(key, -1)):
				_values[key] = i
				bar.queue_redraw()
				changed.emit(key, i))
	parent.add_child(bar)
	_stepbars[key] = bar
	_values[key] = 0


func _draw_steps(bar: Control, key: String, options: Array) -> void:
	var v := int(_values.get(key, 0))
	var n := options.size()
	var pad := 14.0 * pt
	var y := touch * 0.5
	var x0 := pad
	var span := maxf(bar.size.x - pad * 2.0, 1.0)
	var h := 9.0 * pt
	bar.draw_rect(Rect2(x0 - 1.2 * pt, y - h * 0.5 - 1.2 * pt, span + 2.4 * pt, h + 2.4 * pt), Color("#1d1b19"))
	bar.draw_rect(Rect2(x0, y - h * 0.5, span, h), Color(1, 1, 1, 0.1))
	var lit := span * float(v) / maxf(n - 1.0, 1.0)
	bar.draw_rect(Rect2(x0, y - h * 0.5, lit, h), Color("#5fd4ff").lerp(Color("#ff4fd8"), float(v) / maxf(n - 1.0, 1.0)))
	for k in n:
		var cx := x0 + span * float(k) / maxf(n - 1.0, 1.0)
		bar.draw_circle(Vector2(cx, y), (9.0 if k == v else 4.5) * pt, Color("#fff4d6") if k == v else Color(1, 1, 1, 0.5))
	var font := ThemeDB.fallback_font
	var words: Array = options[clampi(v, 0, n - 1)]
	bar.draw_string(font, Vector2(x0, touch + 12.0 * pt), Lang.pick(words[0], words[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB), SUB)


func _select(key: String, index: int) -> void:
	var buttons: Array = _groups[key]
	for k in buttons.size():
		(buttons[k] as Button).set_pressed_no_signal(k == index)


func _say(scheme: int) -> void:
	var s: Array = CONTROLS_SAY[clampi(scheme, 0, CONTROLS_SAY.size() - 1)]
	_say_pl.text = Lang.pick(s[0], s[1])
	_say_en.text = ""
	_say_en.visible = false


## A volume: the words, −, a bar (tap or drag along it) and +.
func _level(parent: Node, key: String, pl: String, en: String, bar_width := 200.0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(8))
	parent.add_child(row)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.custom_minimum_size.x = 76.0 * pt
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_text(Lang.pick(pl, en), T_BODY, INK))
	row.add_child(words)
	var minus := _flat_button("−", 22)
	minus.name = "%s_minus" % key
	minus.custom_minimum_size = Vector2(touch, touch)
	minus.pressed.connect(func(): _set_level(key, float(_values.get(key, 1.0)) - 0.1))
	row.add_child(minus)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(bar_width * pt, touch)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.draw.connect(_draw_bar.bind(bar, key))
	bar.name = "%s_bar" % key
	bar.focus_entered.connect(bar.queue_redraw)
	bar.focus_exited.connect(bar.queue_redraw)
	bar.gui_input.connect(func(e: InputEvent):
		# The gamepad follow-ups: focused (pad_focus), D-pad / stick left and right step it by 0.1
		# (as − and + do); up and down move on.
		if bar.has_focus() and (e.is_action_pressed("ui_left", true) or e.is_action_pressed("ui_right", true)):
			_set_level(key, float(_values.get(key, 1.0)) + (-0.1 if e.is_action_pressed("ui_left", true) else 0.1))
			bar.accept_event()
			return
		var at := -1.0
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			at = (e as InputEventMouseButton).position.x
		elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			at = (e as InputEventMouseMotion).position.x
		if at >= 0.0:
			var pad := 6.0 * pt
			_set_level(key, snappedf(clampf((at - pad) / maxf(bar.size.x - pad * 2.0, 1.0), 0.0, 1.0), 0.05)))
	row.add_child(bar)
	_bars[key] = bar
	var plus := _flat_button("+", 22)
	plus.name = "%s_plus" % key
	plus.custom_minimum_size = Vector2(touch, touch)
	plus.pressed.connect(func(): _set_level(key, float(_values.get(key, 1.0)) + 0.1))
	row.add_child(plus)


func _set_level(key: String, v: float) -> void:
	v = clampf(snappedf(v, 0.05), 0.0, 1.0)
	if is_equal_approx(v, float(_values.get(key, -1.0))):
		return
	_values[key] = v
	(_bars[key] as Control).queue_redraw()
	changed.emit(key, v)


func _draw_bar(bar: Control, key: String) -> void:
	var v: float = _values.get(key, 1.0)
	var pad := 6.0 * pt
	var h := 9.0 * pt
	var track := Rect2(Vector2(pad, bar.size.y - h - 8.0 * pt), Vector2(bar.size.x - pad * 2.0, h))
	if bar.has_focus():
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size).grow(1.0 * pt), Gamepad.RING, false, maxf(2.0, 2.0 * pt))
	bar.draw_rect(track.grow(1.2 * pt), Color("#1d1b19"))
	bar.draw_rect(track, Color(1, 1, 1, 0.1))
	# Ten steps, lit up to the level: cyan to pink, the vaporwave way.
	var steps := 10
	var w := track.size.x / steps
	for k in steps:
		var f := (k + 1.0) / steps
		if f <= v + 0.001 or (k == floori(v * steps) and v * steps - k > 0.01):
			var share := clampf(v * steps - k, 0.0, 1.0)
			var c := Color("#5fd4ff").lerp(Color("#ff4fd8"), float(k) / (steps - 1))
			bar.draw_rect(Rect2(track.position + Vector2(k * w + 0.6 * pt, 0), Vector2((w - 1.2 * pt) * share, h)), c)
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB)
	var label := "%d %%" % roundi(v * 100.0) if v > 0.001 else Lang.pick("0 % · cisza", "0 % · muted")
	bar.draw_string(font, Vector2(track.position.x, track.position.y - 5.0 * pt), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SUB)
