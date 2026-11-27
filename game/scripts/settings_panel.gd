extends Control
## Loop 2a: the settings panel, opened by the gear in the HUD's top left (or Esc). The game
## pauses under it (main.gd). Polish first with the English under it, every control at least
## 44 pt (the iPhone guideline). Emits `changed(key, value)` for each change (main.gd applies
## and saves it) and `closed`.
## Settings redesign step 3 (F 2026-11-23): the tabs are GRA, OBRAZ, DŹWIĘK, DOSTĘP, OGÓLNE and DEV
## (TABS below); the loop notes under this line are the history of where each row came from.
##
## Loop 2e: sized in points throughout (text too: 11 pt and up), in the HUD's card recipe, and
## in four tabs so it fits a phone 390 pt tall without shrinking, now that the driving screen's
## toggles live here:
##   Jazda · Driving: Controls (Point / Classic, with a line saying what the scheme does) and
##     "Kamera za autem · Camera follows the car" On / Off (the old CAM button, now with its
##     state in view; Point with the camera off is the Fixed camera scheme);
##   Świat · World: Time of day (the old TIME button), Weather (RAIN), Traffic;
##   Obraz · Picture: the camera angle (F, 2026-11-07: 30°, 40°, 50°), Quality (loop G1: Auto, the default, then Low, Medium,
##     High, Ultra, Experimental; Auto's English line names the level it picked here), Frame
##     rate, the performance overlay and the TEST bench;
##   Dźwięk · Sound: volume, radio, effects (− and + in tenths, or drag along the bar).
## Loop MW-1: a fifth tab, ZESZYT · notebook: MOJA WARSZAWA, the city notebook
## (notebook_page.gd); the card's title says MOJA WARSZAWA there, with the count found. Since the
## settings redesign step 2 it is a page without a tab, opened from QUESTS → Collection (show_notebook).
## Loop MW-6: Obraz gets the FOTKA button beside TEST (closes the card and opens the photo mode: fotka.gd).
## F's asks (2026-10-30): Jazda gets "Strefy piesze 20 km/h · Pedestrian zones 20 km/h" Off / On
## under the mode (settings.gd `zone_cap`, off by default: key "zones").
## Settings rows (F 2026-11-14): Świat in three rows gets "Łamliwe płoty · Smashable fences"
## Off / On beside the weather (settings.gd `soft_fences`, off by default: key "soft_fences") and
## "Zderzenia · Collisions" beside the traffic (settings.gd `collide`, collide_rules.gd PRESETS:
## key "collide").
## 2026-11-01: Jazda's first column ends with "Utknąłeś? · Stuck?" and POMOC DROGOWA (closes the
## card and tows the car onto the nearest road: main.gd `_unstuck`, key "unstuck").

signal changed(key: String, value: Variant)
signal closed

const UiKit := preload("res://scripts/ui_kit.gd")  # the one look (docs/design/ui-kit.md)
const Lang := preload("res://scripts/lang.gd")  # one language at a time
const KebabStand := preload("res://scripts/kebab_stand.gd")  # the auto-pour heading's words
const ACCENT := UiKit.GOLD
const INK := UiKit.INK
const SUB := UiKit.SUB
const DIM := UiKit.DIM
## The HUD's card recipe (hud.gd CARD_BG).
const CARD_BG := UiKit.CARD
## Type sizes in points (hud.gd's scale).
const T_HEAD := UiKit.T_CLOCK
const T_BODY := UiKit.T_BODY
const T_SUB := UiKit.T_SUB
const T_LABEL := UiKit.T_LABEL
## Loop MW-1: the notebook tab's title size (hud.gd T_TITLE).
const T_NOTES := UiKit.T_TITLE

## Settings redesign step 2 (F 2026-11-23): ZESZYT left the tabs; the notebook page opens from QUESTS → Collection.
## Step 3: six tabs, GRA (the rescue, the controls, the lane assist, weather and traffic), OBRAZ,
## DŹWIĘK, DOSTĘP, OGÓLNE (language, stats, credits, tips) and DEV (our A/B switches plus the time
## of day, the frame rate and Piksel/Pełny).
const TABS := [["GRA", "game"], ["OBRAZ", "picture"], ["DŹWIĘK", "sound"], ["DOSTĘP", "access"], ["OGÓLNE", "general"], ["DEV", "dev"]]
## Settings redesign step 1 (F 2026-11-23): the pages by name, in the order `_build` makes them.
## Everything outside this script (`set_page`, --settings-tab=NAME, the checks) names a page; the
## numbers below follow from this list, so the redesign can reorder tabs in one place. The tabs are
## the TABS keys, first; the notebook (QUESTS → Kolekcja), credits (OGÓLNE → LICENCJE) and tips
## (OGÓLNE → PORADY, game/data/tips.json) have no tab of their own. DEV (the Fable critique, F
## 2026-11-15) has its tab since step 3; DEV_TAPS taps on the version still open it.
const PAGES := ["game", "picture", "sound", "access", "general", "dev", "notebook", "credits", "tips", "advanced"]
## The tab that stays lit on a page without a tab of its own (credits and tips under OGÓLNE,
## OBRAZ → ZAAWANSOWANE under OBRAZ).
const PAGE_TAB := {"credits": "general", "tips": "general", "advanced": "picture"}
## The names before step 3 (old --settings-tab values, saved shot lists): JAZDA and ŚWIAT are GRA now.
const PAGE_ALIAS := {"driving": "game", "world": "game"}
static var NOTEBOOK_TAB: int = PAGES.find("notebook")
static var ACCESS_TAB: int = PAGES.find("access")
static var CREDITS_PAGE: int = PAGES.find("credits")
static var TIPS_PAGE: int = PAGES.find("tips")
static var DEV_PAGE: int = PAGES.find("dev")
static var ADVANCED_PAGE: int = PAGES.find("advanced")
const TIPS_FILE := "res://data/tips.json"
const DEV_TAPS := 7
const DEV_TAP_GAP := 1.5
const Credits := preload("res://scripts/credits.gd")
const Feedback := preload("res://scripts/feedback.gd")  # the feedback card (F 2026-11-21)
const NotebookPage := preload("res://scripts/notebook_page.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the gamepad loop
## Loop 2e: the camera choice, explicit (it was the CAM button, easy to switch off unnoticed):
## on, it follows the car (Point; Classic's default), off it stays put (Fixed camera; Classic
## with the camera fixed).
const CAMERA := [["Wł.", "On"], ["Wył.", "Off"]]
## Classic's touch steering (settings.gd `pads`): fixed arrows or the strip (the default since
## F 2026-11-14); the pedals are the same in both.
const PADS := [["Strzałki", "Arrows"], ["Suwak", "Slider"]]
## What each (PADS) does, in a line.
const CONTROLS_SAY := [
	["Strzałki w lewym rogu, pedały gazu i hamulca w prawym.", "Arrows bottom left; GAS and BRAKE pedals bottom right."],
	["Przesuń kciukiem w lewo–prawo, pedały gazu i hamulca po prawej.", "Slide your thumb left–right; GAS and BRAKE pedals on the right."],
]
## Loop MW-3: Świt (Dawn) last, the mode's index (time_of_day.gd DAWN after LIVE).
const TIME := [["Dzień", "Day"], ["Zmierzch", "Dusk"], ["Noc", "Night"], ["Na żywo", "Live"], ["Świt", "Dawn"]]
const WEATHER := [["Pogodnie", "Clear"], ["Deszcz", "Rain"]]
const TRAFFIC := [["Pustawo", "Almost empty"], ["Mało", "Low"], ["Normalnie", "Normal"], ["Tłoczno", "Busy"]]
## Loop G1: index 0 is Auto (settings.gd AUTO), then the levels (tiers.gd LOW..ULTRA) one up.
## F 2026-11-10: Experimental after Ultra (tiers.gd: Ultra plus the trailer's extras, to test on the
## phone; this session only, never saved).
const QUALITY := [["Auto", "auto"], ["Niska", "Low"], ["Średnia", "Medium"], ["Wysoka", "High"], ["Ultra", "Ultra"],
		["Maks", "Max"]]
## Perf thread (F 2026-11-20): the 3D image, the pixel look's own (x2 on a phone) or the screen's own
## pixels (settings.gd image_full, tiers.gd full_image).
const IMAGE := [["Piksel", "Pixel"], ["Pełny", "Full"]]
## Settings redesign step 4 (F 2026-11-23: one simple choice, the deeper options behind
## ZAAWANSOWANE): a preset is a view over the saved keys, not a key of its own, so nothing is
## migrated. Each preset is [quality choice (QUALITY index), fps (FPS index), image (IMAGE index)];
## any other mix lights WŁASNE (custom), whose tap opens the advanced page.
const PRESET := [["Auto", "Auto"], ["Bateria", "Battery"], ["Najlepsza", "Best"], ["Własne", "Custom"]]
const PRESET_VALUES := [[0, 0, 0], [1, 1, 0], [4, 0, 0]]
const ON_OFF := [["Wył.", "Off"], ["Wł.", "On"]]
## F 2026-11-17: DEV's camera view (settings.gd `camera_view`).
const CAMERA_VIEW := [["Normalny", "Normal"], ["Z góry", "Top"], ["Z lotu", "Aerial"]]
## grades.gd SETTING, in its order.
const GRADE := [["Natura", "Natural"], ["Neon", "Neon"], ["Klasyk", "Classic"]]
## F (2026-11-07): the camera's angle over the ground, follow_camera.gd PITCHES (30° the default).
## F 2026-11-24: a fourth choice, straight down (main.gd `top_down`, the same view as DEV's "Z góry").
const ANGLE := [["30°", "30°"], ["40°", "40°"], ["50°", "50°"], ["Z góry", "Top"]]
## Loop 2b: frames per second (settings.gd FPS: 60, 30) and the benchmark button.
const FPS := [["60 płynnie", "60 smooth"], ["30 bateria", "30 battery"]]
## H1: the Realnie switch on the DEV page (settings.gd `handling`: 0 off, 1 the car with weight);
## Cruise to Sport is the „Charakter jazdy" slider on Jazda now.
const HANDLING := [["Zwykle", "Arcade"], ["Realnie", "Grounded"]]
## Phase 0.2: the city's chattiness (settings.gd `chatter`, chatter.gd GAPS).
const CHATTER := [["Mało", "Quiet"], ["Średnio", "Some"], ["Dużo", "Lots"]]
## Settings rows (F 2026-11-14): the car's collision answer (settings.gd `collide`, collide_rules.gd
## PRESETS: v1, soft, mid, firm), short words like the handling's.
const COLLIDE := [["Klasyka", "Classic"], ["Miękko", "Soft"], ["Średnio", "Medium"], ["Twardo", "Firm"]]
const LEVELS := [["master", "Głośność", "Volume"], ["music", "Radio", "Radio"], ["effects", "Efekty", "Effects"]]

## Loop 2e: pixels per point and the safe area in pixels (from the HUD, screen_points.gd).
var pt := 1.0
var safe := Rect2()
## The RAPORT button on the sound page (the error trap, TD-14): our own debug builds have it,
## testers' builds do not (F, 2026-11-12).
var report_on := OS.is_debug_build()
## The DEV page was opened in this run (`_dev_tap`).
var dev_on := false
var _dev_taps := 0
var _dev_tap_ms := -100000
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
## Where the player is, for the feedback card (main.gd `_settings_state` "where").
var _where := ""
var _feedback: Feedback
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
	shade.color = UiKit.SCRIM
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	# A tap beside the card closes it.
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	add_child(shade)

	var style := UiKit.card(pt, 14.0)  # the kit's card, as every panel (docs/design/ui-kit.md)
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
	# The version under the title; seven taps on it open the DEV page.
	_subtitle.name = "version"
	_subtitle.mouse_filter = Control.MOUSE_FILTER_STOP
	_subtitle.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			dev_tap())
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
		b.pressed.connect(set_page.bind(String(TABS[i][1])))
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

	# GRA · Game (settings redesign step 3, F 2026-11-23: was JAZDA and ŚWIAT).
	var drive := _page(body, 2)
	# G14 (F, 2026-11-01): the two rescue buttons at the top of the first tab, where they are found:
	# the tow onto the nearest road, and a new game (two taps: the second wipes the progress).
	# F 2026-11-22: the feedback button moved from Dźwięk to the very top of the first tab, gold and
	# full width with its own words, so a tester finds it without looking (feedback.gd).
	var feedback_button := Button.new()
	feedback_button.name = "feedback"
	feedback_button.text = Lang.pick("✉ NAPISZ DO AUTORA · OPINIA", "✉ WRITE TO THE AUTHOR · FEEDBACK")
	feedback_button.custom_minimum_size = Vector2(0.0, touch)
	feedback_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.style_button(feedback_button, UiKit.Kind.PRIMARY, pt, T_BODY)
	feedback_button.pressed.connect(_open_feedback)
	drive[0].add_child(feedback_button)
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
	_segments(drive[0], "pads", PADS)
	_say_pl = _text("", T_SUB, INK)
	_say_en = _text("", T_SUB, SUB)
	for l in [_say_pl, _say_en]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 240.0 * pt
		drive[0].add_child(l)
	# H1 (F 2026-11-22): one slider for the handling, calm on the left, sharp on the right; the
	# slides only open on its last third (car.gd set_character).
	# The ends' words sit under the name inside the row (the column is full since the feedback button).
	_level(drive[0], "character", "Charakter jazdy", "Handling", 120.0, ["spokojnie → ostro", "calm → sharp"])
	# First hour step 6 (the Fable critique's beta settings, F 2026-11-15): our own A/B switches live
	# on DEV, so every tester drives the same car; the player's own preferences stay on the tabs.
	# F 2026-11-22: the lane assist is a player setting, not a DEV one (key "lane_assist", settings.gd),
	# at the top of the second column (the first is full on a 375 pt phone).
	_heading(drive[1], "Asysta pasa", "Lane assist")
	_segments(drive[1], "lane_assist", ON_OFF)
	for b: Button in _groups["lane_assist"]:
		b.custom_minimum_size.x = touch * 1.05
	# The weather and the traffic (was ŚWIAT; the time of day went to DEV in step 3: the game runs
	# its own clock, F 2026-11-19).
	_heading(drive[1], "Pogoda", "Weather")
	_segments(drive[1], "weather", WEATHER)
	_heading(drive[1], "Ruch uliczny", "Traffic")
	_steps(drive[1], "traffic", TRAFFIC, 200.0)  # narrower in GRA's second column (375 pt phones)
	# Obraz · Picture: the camera angle and colours; Quality; the photo mode. (Frame rate and
	# Piksel/Pełny went to DEV in step 3.) 2026-11-01 (F): the Style picker is gone; 2026-11-22 (F):
	# the Retro filter too. Camera angle: follow_camera.gd PITCHES, key "angle".
	var picture := _rows(body, [2, 1, 1])
	_heading(picture[0], "Kąt kamery", "Camera angle")
	_segments(picture[0], "angle", ANGLE)
	# F (2026-11-15): the colour look (grades.gd SETTING, key "grade"), beside them.
	_heading(picture[1], "Kolory", "Colours")
	_segments(picture[1], "grade", GRADE)
	# Two pickers in one row: narrower buttons (still over 44 pt) keep the card's width.
	for b: Button in _groups["angle"]:
		b.custom_minimum_size.x = touch * 1.05
	(_groups["angle"][ANGLE.size() - 1] as Button).custom_minimum_size.x = touch * 1.5
	for b: Button in _groups["grade"]:
		b.custom_minimum_size.x = touch * 1.6
	# Step 4: the preset (Auto, Battery, Best, or Custom) and ZAAWANSOWANE for the level, the frame
	# rate and Piksel/Pełny (the advanced page, built below).
	_heading(picture[2], "Jakość obrazu", "Quality")
	var preset := PRESET.duplicate(true)
	preset[0] = ["Auto · %s" % _auto_name, "Auto · %s" % _auto_name]
	_segments(picture[2], "preset", preset)
	for i in _groups["preset"].size():
		var pb: Button = _groups["preset"][i]
		for c in pb.pressed.get_connections():
			pb.pressed.disconnect(c["callable"])
		pb.pressed.connect(_pick_preset.bind(i))
	var advanced := _word_button("ZAAWANSOWANE", "ADVANCED")
	advanced.name = "advanced"
	advanced.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	advanced.pressed.connect(show_advanced)
	picture[3].add_child(advanced)
	# Loop MW-6: the photo mode (fotka.gd), from the pause card. (The overlay and TEST are on DEV.)
	var photo := _word_button("FOTKA", "PHOTO")
	photo.name = "fotka"
	photo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	photo.pressed.connect(func():
		close()
		changed.emit("fotka", 1))
	picture[3].add_child(photo)
	# Dźwięk · Sound: the volumes.
	var sound := _page(body, 1)
	for l in LEVELS:
		_level(sound[0], l[0], l[1], l[2])

	# DOSTĘP · Access (access.gd).
	# A third column for the stand's auto-pour (kebab_stand.gd): a fourth row would make the page too tall.
	var access := _page(body, 3)
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
	var auto_pour: Array = KebabStand.say("setting_auto_pour")
	_heading(access[2], str(auto_pour[0]), str(auto_pour[1]))
	_segments(access[2], "auto_pour", ON_OFF)

	# OGÓLNE · General (step 3): the language, the stats, the credits and the tips (were on DŹWIĘK).
	var general := _page(body, 2)
	# 2026-11-02 (F): the language, one at a time (lang.gd): POLSKI or ENGLISH.
	_heading(general[0], "Język", "Language")
	_segments(general[0], "lang", [["Polski", "Polski"], ["English", "English"]])
	# The beta's play stats (play_stats.gd, docs/STATS.md, F 2026-11-15): anonymous counts, on by
	# default, off here at once (settings.gd `stats`, key "stats").
	_heading(general[0], "Anonimowa statystyka", "Anonymous stats")
	_segments(general[0], "stats", ON_OFF)
	# Step 5 (F 2026-11-23): one way back to the defaults, two taps like NOWA GRA (main.gd "defaults";
	# the language, the stats and DEV stay as they are).
	_defaults_button = _word_button("PRZYWRÓĆ DOMYŚLNE", "RESTORE DEFAULTS")
	_defaults_button.name = "defaults"
	_defaults_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_defaults_button.pressed.connect(_on_defaults_pressed)
	general[0].add_child(_defaults_button)
	# DEMO 3j: the credits and licences (credits.gd), and the tips, pages of their own opened from here.
	_heading(general[1], "O grze", "About")
	var about_row := HBoxContainer.new()
	about_row.add_theme_constant_override("separation", _px(6))
	general[1].add_child(about_row)
	var about := _word_button("LICENCJE", "CREDITS")
	about.name = "credits"
	about.pressed.connect(show_credits)
	about_row.add_child(about)
	var tips_button := _word_button("PORADY", "TIPS")
	tips_button.name = "tips"
	tips_button.pressed.connect(show_tips)
	about_row.add_child(tips_button)
	# The error trap (tech-debt TD-14): this run's errors and last lines onto the clipboard
	# (main.gd). Only in our own debug builds (`report_on`).
	if report_on:
		var report := _word_button("RAPORT", "REPORT")
		report.name = "report"
		report.pressed.connect(func():
			close()
			changed.emit("report", 1))
		about_row.add_child(report)

	var dev := _dev_page(body)

	# The body is as big as the biggest page, so the card keeps its size from tab to tab.
	var biggest := Vector2.ZERO
	for p in _pages:
		if p != dev:  # DEV scrolls inside the others' size
			biggest = biggest.max(p.get_combined_minimum_size())
	body.custom_minimum_size = biggest
	for p in _pages:
		p.size = biggest
	_settings_size = biggest
	dev.custom_minimum_size = biggest
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
	notebook_page.size = notebook_page.custom_minimum_size
	_credits_page(body)
	_tips_page(body)
	_advanced_page(body)
	if _pages.size() != PAGES.size() or _pages[DEV_PAGE] != dev:
		push_error("settings_panel: %d pages built for the %d PAGES names" % [_pages.size(), PAGES.size()])
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


## The page called `key` (PAGES), or a page number as text ("4"); an unknown name opens the first tab.
static func page_of(key: String) -> int:
	if key.is_valid_int():
		return clampi(int(key), 0, PAGES.size() - 1)
	return maxi(0, PAGES.find(String(PAGE_ALIAS.get(key, key))))


## Shows the page called `key` (PAGES: game, picture, sound, access, general, dev, notebook, credits, tips).
func set_page(key: String) -> void:
	set_tab(page_of(key))


## The name of the page on show (PAGES).
func page() -> String:
	return PAGES[_tab]


## The index in `_tabs` (TABS) of the tab lit for page `i`, or -1 (the notebook has no tab).
func _tab_button(i: int) -> int:
	var key: String = PAGE_TAB.get(PAGES[i], PAGES[i])
	for k in TABS.size():
		if TABS[k][1] == key:
			return k
	return -1


## Shows page `i` of PAGES (set_page by name is the way in from outside).
func set_tab(i: int) -> void:
	# The pages past the tabs (credits, tips, DEV) can be asked for before the panel is built
	# (--settings-tab=credits/tips/dev); `_build` shows the page asked for. Opening DEV by any road turns it on.
	_tab = clampi(i, 0, PAGES.size() - 1)
	if _tab == DEV_PAGE:
		dev_on = true
	if not _built:
		return
	var lit := _tab_button(_tab)
	for k in _pages.size():
		_pages[k].visible = k == _tab
	for k in _tabs.size():
		_tabs[k].set_pressed_no_signal(k == lit)
	# Loop MW-1: the notebook's tab has its own size and title.
	var on_notes := _tab == NOTEBOOK_TAB
	var on_credits := _tab == CREDITS_PAGE
	var on_tips := _tab == TIPS_PAGE
	var on_dev := _tab == DEV_PAGE
	_body.custom_minimum_size = notebook_page.custom_minimum_size if on_notes else _settings_size
	_title.text = Lang.pick("MOJA WARSZAWA", "MY WARSAW") if on_notes else (Lang.pick("O GRZE", "ABOUT") if on_credits else (Lang.pick("PORADY", "TIPS") if on_tips else ("DEV" if on_dev else Lang.pick("USTAWIENIA", "SETTINGS"))))
	_title.add_theme_font_size_override("font_size", _px(T_NOTES if on_notes else T_HEAD))
	_subtitle.text = _notes_count() if on_notes else (Lang.pick("licencje i autorzy", "credits and licences") if on_credits else "%s · %s" % [Lang.pick("gra wstrzymana", "game paused"), version()])
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


## The game's version as the card shows it ("v0.1"): project.godot's application/config/version.
static func version() -> String:
	return "v%s" % str(ProjectSettings.get_setting("application/config/version", "dev"))


## A tap on the version: the seventh in a row (each within DEV_TAP_GAP s) opens the DEV page, and
## once it was open in this run every tap does. True when it opened.
func dev_tap() -> bool:
	var now := Time.get_ticks_msec()
	_dev_taps = _dev_taps + 1 if now - _dev_tap_ms <= int(DEV_TAP_GAP * 1000.0) else 1
	_dev_tap_ms = now
	if not dev_on and _dev_taps < DEV_TAPS:
		return false
	_dev_taps = 0
	show_dev()
	return true


## Opens the DEV page. (Max quality, once Experimental behind DEV, is on Obraz for everyone since
## the perf thread, F 2026-11-20.)
func show_dev() -> void:
	dev_on = true
	if not _built:
		return
	set_tab(DEV_PAGE)
	if Gamepad.in_use():
		pad_focus()


## First hour step 6: the DEV page, our own A/B switches (the Fable critique's list): handling,
## the follow camera and the lane assist; the 20 km/h zones, collisions and smashable fences; the
## city's chattiness, the performance overlay and TEST. The same keys as before, so main.gd and
## settings.gd keep them as ever; only where they sit changed.
func _dev_page(body: Control) -> Control:
	# Settings redesign step 3: DEV is a tab, so it scrolls inside the settings pages' size (it had
	# grown wider and taller than a 375 pt phone); two settings a row.
	var scroll := ScrollContainer.new()
	scroll.name = "dev_page"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true  # the pad's focus brings the rows below into view
	body.add_child(scroll)
	var dev := _rows(scroll, [2, 2, 2, 2, 2, 2])
	_pages[_pages.size() - 1] = scroll
	_heading(dev[0], "Kamera za autem", "Camera follows the car")
	_segments(dev[0], "camera", CAMERA)
	_heading(dev[1], "Prowadzenie", "Handling")
	_segments(dev[1], "handling", HANDLING)
	_heading(dev[2], "Strefy 20 km/h", "20 km/h zones")
	_segments(dev[2], "zones", ON_OFF)
	_heading(dev[3], "Zderzenia", "Collisions")
	_segments(dev[3], "collide", COLLIDE)
	_heading(dev[4], "Łamliwe płoty", "Smashable fences")
	_segments(dev[4], "soft_fences", ON_OFF)
	_heading(dev[5], "Gadatliwość miasta", "City chattiness")
	_segments(dev[5], "chatter", CHATTER)
	_heading(dev[6], "Licznik wydajności", "Performance overlay")
	var perf_row := HBoxContainer.new()
	perf_row.add_theme_constant_override("separation", _px(6))
	dev[6].add_child(perf_row)
	_segments(perf_row, "perf", ON_OFF)
	# Loop 2b: a minute on the bench route, then a result card to copy (main.gd).
	var bench := _word_button("TEST", "BENCH")
	bench.name = "bench"
	bench.pressed.connect(func():
		close()
		changed.emit("bench", 1))
	perf_row.add_child(bench)
	# Bokiem na Narodowym's grey box (drift_stadium.gd, critique-drift.md 4): the drift practice on
	# the stadium floor, so F can hold it on the phone before the quest exists.
	var drift := _word_button("BOKIEM", "DRIFT")
	drift.name = "drift"
	drift.pressed.connect(func():
		close()
		changed.emit("drift", 1))
	perf_row.add_child(drift)
	# F 2026-11-20: Promo Mode (promo_mode.gd): framing tools for the trailer and the Reels.
	_heading(dev[7], "Tryb promo", "Promo mode")
	_segments(dev[7], "promo", ON_OFF)
	# F 2026-11-17: the camera view (follow_camera.gd VIEW_*): the game's, top-down, aerial.
	_heading(dev[8], "Widok kamery", "Camera view")
	_segments(dev[8], "camera_view", CAMERA_VIEW)
	# Stats thread 2026-11-21: the tester's own phone, so the anonymous stats can leave it out.
	_heading(dev[9], "Urządzenie testowe", "Test device (stats)")
	_segments(dev[9], "test_device", ON_OFF)
	# Settings redesign step 3 (F 2026-11-23): the time of day (the game runs its own clock, F
	# 2026-11-19, so this is a tester's jump). (Piksel/Pełny and the frame rate: OBRAZ → ZAAWANSOWANE.)
	_heading(dev[10], "Pora dnia", "Time of day")
	_segments(dev[10], "time", TIME)
	_groups["time"][3].visible = false  # F 2026-11-19: no Live, the game runs its own clock (time_of_day.gd)
	# F 2026-11-26: the new opening (tajny_klient.gd) instead of the guide, on a fresh save from the next launch.
	_heading(dev[11], "Tajny klient (nowy start)", "Secret customer (new start)")
	_segments(dev[11], "tajny", ON_OFF)
	for key: String in ["camera", "zones", "soft_fences", "perf", "promo", "test_device", "tajny"]:
		for b: Button in _groups[key]:
			b.custom_minimum_size.x = touch * 1.05
	return scroll


## Settings redesign step 4: OBRAZ → ZAAWANSOWANE, the level (QUALITY, Max included), the frame
## rate and Piksel/Pełny, under the OBRAZ tab; any tab goes back.
func show_advanced() -> void:
	set_tab(ADVANCED_PAGE)
	if Gamepad.in_use():
		pad_focus()


func _advanced_page(body: Control) -> void:
	var adv := _rows(body, [1, 2])
	var page := _pages[_pages.size() - 1]
	page.name = "advanced_page"
	_heading(adv[0], "Poziom grafiki", "Graphics level")
	var quality := QUALITY.duplicate(true)
	quality[0] = ["Auto · %s" % _auto_name, "Auto · %s" % _auto_name]
	_segments(adv[0], "quality", quality)
	_heading(adv[1], "Klatki na sekundę", "Frame rate")
	_segments(adv[1], "fps", FPS)
	_heading(adv[2], "Obraz", "Image")
	_segments(adv[2], "image", IMAGE)
	page.size = _settings_size


## Step 4: a tap on a preset sets the level, the frame rate and the image together (main.gd applies
## each key as before); WŁASNE opens the advanced page.
func _pick_preset(i: int) -> void:
	if i >= PRESET_VALUES.size():
		_sync_preset()
		show_advanced()
		return
	var v: Array = PRESET_VALUES[i]
	for k in 3:
		var key: String = ["quality", "fps", "image"][k]
		if _chosen(key) != int(v[k]):
			_select(key, int(v[k]))
			changed.emit(key, int(v[k]))
	_sync_preset()


## The index of the lit button of `key`'s row, or -1.
func _chosen(key: String) -> int:
	var buttons: Array = _groups.get(key, [])
	for k in buttons.size():
		if (buttons[k] as Button).button_pressed:
			return k
	return -1


## Lights the preset the saved level, frame rate and image match, else WŁASNE.
func _sync_preset() -> void:
	if not _groups.has("preset"):
		return
	var now := [_chosen("quality"), _chosen("fps"), _chosen("image")]
	var at := PRESET_VALUES.find(now)
	_select("preset", at if at >= 0 else PRESET.size() - 1)


## First hour step 6: shows the tips (DŹWIĘK → PORADY; any tab goes back).
func show_tips() -> void:
	set_tab(TIPS_PAGE)
	if Gamepad.in_use():
		pad_focus()


## First hour step 6: the tips page, every loading tip (tips.json) in a column that scrolls, as big
## as the settings pages so the card keeps its size.
func _tips_page(body: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "tips_page"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size = _settings_size
	scroll.custom_minimum_size = _settings_size
	body.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", _px(6))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size.x = _settings_size.x - 16.0 * pt
	scroll.add_child(col)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(TIPS_FILE))
	var tips: Array = (d as Dictionary).get("tips", []) if d is Dictionary else []
	for t: Dictionary in tips:
		var l := _text("•  " + Lang.pick(str(t.get("pl", "")), str(t.get("en", ""))), T_BODY, INK)
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
## perf, fps, style, weather, time}.
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
	return _tabs[maxi(0, _tab_button(_tab))]


## The current values again (after a change that moves another row: Classic's camera).
func sync(state: Dictionary) -> void:
	if not _built:
		return
	_where = str(state.get("where", _where))
	var scheme := int(state.get("controls", 1))  # Classic, the default (settings.gd DEFAULT_CONTROLS)
	var follow := bool(state.get("follow", scheme != 2))
	var values := state.duplicate()
	values["drive"] = 1 if scheme == 1 else 0
	values["camera"] = 0 if follow else 1
	# Loop G1b: what Auto draws can change with the style ("High ostry" / "High ×2" / "High").
	_set_auto_name(str(state.get("auto", _auto_name)))
	for key in _groups:
		if key != "preset":  # step 4: a view over quality, fps and image (_sync_preset)
			_select(key, int(values.get(key, 0)))
	_sync_preset()
	for key in _stepbars:
		_values[key] = int(values.get(key, 0))
		(_stepbars[key] as Control).queue_redraw()
	for key in _bars:
		_values[key] = float(state.get(key, 1.0))
		(_bars[key] as Control).queue_redraw()
	_say(int(state.get("pads", 1)))


## F 2026-11-21: the feedback card over the panel (feedback.gd posts it to the author's form).
func _open_feedback() -> void:
	if _feedback == null:
		_feedback = Feedback.new()
		_feedback.name = "FeedbackCard"
		_feedback.pt = pt
		_feedback.safe = safe
		add_child(_feedback)
		_feedback.visible = false
	_feedback.where = _where
	_feedback.open()


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
		if c.is_visible_in_tree() and _in_view(c):
			out[str(_card.get_path_to(c))] = c.get_global_rect()
	# Loop MW-1: the notebook page's targets (drawn, not Buttons).
	if notebook_page != null and notebook_page.is_visible_in_tree():
		out.merge(notebook_page.hit_rects())
	return out


## False for a button scrolled out of a scrolling page's view (DEV since step 3): it is no target
## until a drag or the pad brings it in.
func _in_view(c: Control) -> bool:
	var n := c.get_parent()
	while n != null and n != _card:
		if n is ScrollContainer:
			return (n as Control).get_global_rect().grow(1.0).encloses(c.get_global_rect())
		n = n.get_parent()
	return true


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
		set_page(String(TABS[wrapi(maxi(0, _tab_button(_tab)) + step, 0, TABS.size())][1]))
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


## A kit button (docs/design/ui-kit.md): SECONDARY, its pressed and toggled state SELECTED.
func _flat_button(label: String, points: float) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	UiKit.style_button(b, UiKit.Kind.SECONDARY, pt, points)
	return b


## A 44 pt button with the Polish word (15 pt) over the English one (11 pt); its width follows
## the words.
var _new_game_button: Button
var _new_game_armed := false
var _defaults_button: Button
var _defaults_armed := false


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


## Step 5: the first tap asks, the second (within 4 s) restores the defaults.
func _on_defaults_pressed() -> void:
	if not _defaults_armed:
		_defaults_armed = true
		_set_word_button(_defaults_button, "NA PEWNO?", "SURE? TAP AGAIN")
		get_tree().create_timer(4.0).timeout.connect(_disarm_defaults)
		return
	_disarm_defaults()
	changed.emit("defaults", 1)


func _disarm_defaults() -> void:
	_defaults_armed = false
	_set_word_button(_defaults_button, "PRZYWRÓĆ DOMYŚLNE", "RESTORE DEFAULTS")


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
	top.uppercase = true  # the kit's button words are capitals
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
	for key: String in ["quality", "preset"]:
		if not _groups.has(key):
			continue
		var b: Button = _groups[key][0]
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
func _steps(parent: Node, key: String, options: Array, width := 260.0) -> void:
	var bar := Control.new()
	bar.name = "%s_slider" % key
	bar.custom_minimum_size = Vector2(width * pt, touch + 22.0 * pt)
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
	bar.draw_rect(Rect2(x0 - 1.2 * pt, y - h * 0.5 - 1.2 * pt, span + 2.4 * pt, h + 2.4 * pt), UiKit.OUTLINE)
	bar.draw_rect(Rect2(x0, y - h * 0.5, span, h), UiKit.DIM)
	var lit := span * float(v) / maxf(n - 1.0, 1.0)
	bar.draw_rect(Rect2(x0, y - h * 0.5, lit, h), UiKit.NEON_CYAN.lerp(UiKit.NEON_PINK, float(v) / maxf(n - 1.0, 1.0)))
	for k in n:
		var cx := x0 + span * float(k) / maxf(n - 1.0, 1.0)
		bar.draw_circle(Vector2(cx, y), (9.0 if k == v else 4.5) * pt, UiKit.INK if k == v else Color(UiKit.INK, 0.5))
	var font := ThemeDB.fallback_font
	var words: Array = options[clampi(v, 0, n - 1)]
	bar.draw_string(font, Vector2(x0, touch + 12.0 * pt), Lang.pick(words[0], words[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB), SUB)


func _select(key: String, index: int) -> void:
	var buttons: Array = _groups[key]
	for k in buttons.size():
		(buttons[k] as Button).set_pressed_no_signal(k == index)
	if key in ["quality", "fps", "image"]:
		_sync_preset()


func _say(pads: int) -> void:
	var s: Array = CONTROLS_SAY[clampi(pads, 0, CONTROLS_SAY.size() - 1)]
	_say_pl.text = Lang.pick(s[0], s[1])
	_say_en.text = ""
	_say_en.visible = false


## A volume: the words, −, a bar (tap or drag along it) and +.
## `sub` ([pl, en], optional): a small second line under the name, inside the row's height.
func _level(parent: Node, key: String, pl: String, en: String, bar_width := 200.0, sub: Array = []) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _px(8))
	parent.add_child(row)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.custom_minimum_size.x = 76.0 * pt
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_text(Lang.pick(pl, en), T_BODY, INK))
	if sub.size() == 2:
		words.add_child(_text(Lang.pick(sub[0], sub[1]), T_SUB, SUB))
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
	bar.draw_rect(track.grow(1.2 * pt), UiKit.OUTLINE)
	bar.draw_rect(track, UiKit.DIM)
	# Ten steps, lit up to the level: cyan to pink, the vaporwave way.
	var steps := 10
	var w := track.size.x / steps
	for k in steps:
		var f := (k + 1.0) / steps
		if f <= v + 0.001 or (k == floori(v * steps) and v * steps - k > 0.01):
			var share := clampf(v * steps - k, 0.0, 1.0)
			var c := UiKit.NEON_CYAN.lerp(UiKit.NEON_PINK, float(k) / (steps - 1))
			bar.draw_rect(Rect2(track.position + Vector2(k * w + 0.6 * pt, 0), Vector2((w - 1.2 * pt) * share, h)), c)
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB)
	var label := "%d %%" % roundi(v * 100.0) if v > 0.001 else Lang.pick("0 % · cisza", "0 % · muted")
	bar.draw_string(font, Vector2(track.position.x, track.position.y - 5.0 * pt), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SUB)
