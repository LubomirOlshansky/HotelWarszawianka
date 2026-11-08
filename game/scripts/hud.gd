extends CanvasLayer
## On-screen controls and panels at full resolution, above the pixel-art view.
##
## Loop 2e: the whole HUD is sized in points (screen_points.gd: 3 px a point on the iPhones the
## game targets; on a computer the window stands in for a phone), every control at least 44 pt,
## every text on one type scale (T_*: body 13 pt and up, labels 11 pt), everything inside the
## safe area (the Dynamic Island or notch, the rounded corners, the home indicator). The first
## screen is thin: the gear (settings) top left with the speed beside it, one context button
## in the middle of the top row (a rescue call that came in), RADIO and HELI / AUTO top right;
## the minimap and the wallet under the gear; the pedals bottom right; no credit line (the credits page in Settings)
## centre. Time of day, rain, VHS, the picture style and the camera moved into Settings
## (settings_panel.gd); zoom is a pinch, and with the fixed camera a two-finger twist turns the
## view. The panels that come and go (the status, the call or job card, FLASH LIGHTS, the race
## banner, toasts, the performance overlay, the note and landmark cards, the radio ticker) are
## placed by `_layout` in that order of priority, each giving way along its column so none
## covers another or a fixed control; the speech bubbles (bubbles.gd) keep clear of all of them
## (`panel_rects`). `game/tools/check_hud.gd` checks the sizes, the safe area and the overlaps.
##
## Before: a floating stick on the left (point-to-steer), BRAKE on the right (climb and sink
## pads in the helicopter), the rescue card and status (shared with races and the side jobs),
## an arrow to the target, the race challenge and countdown banner, rival dots, side-job places
## and the target on the minimap, the wallet (złoty and respect), the note card (an easter
## egg), the landmark card (v0.8), the now-playing ticker, the performance overlay (v0.9, a
## three-finger tap or P). Loop 2a: the gear and the settings panel; the controls follow the
## scheme: Point and Fixed keep the stick and BRAKE, Classic has a left / right steering strip
## and GAS with BRAKE beside it (a thumb can slide between them).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Chatter := preload("res://scripts/chatter.gd")
const Access := preload("res://scripts/access.gd")
const Lang := preload("res://scripts/lang.gd")  # one language at a time: every pl/en pair below shows one
const SettingsPanel := preload("res://scripts/settings_panel.gd")
const Gamepad := preload("res://scripts/gamepad.gd")  # the pad's A on the context button (2026-11-03)
const FullMap := preload("res://scripts/full_map.gd")
const MapArt := preload("res://scripts/map_art.gd")
const MainLine := preload("res://scripts/main_line.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
## drive_controls.gd's schemes (POINT, CLASSIC, FIXED).
const CLASSIC := 1

## Loop 2e: the HUD's type scale, in points. Body text is 13 pt or more, labels 11 pt.
const T_BANNER := 44.0
const T_CLOCK := 22.0
const T_TITLE := 17.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
## Loop 2e: the layout, in points. TOUCH is Apple's smallest comfortable tap; EDGE is kept from
## the safe area's sides; the top row starts ROW_Y down and is ROW_H tall.
const TOUCH := 44.0
const EDGE := 10.0
const GAP := 8.0
const ROW_Y := 8.0
const ROW_H := 44.0
## The minimap: its diameter on screen and how far from the car its rim reaches (metres).
const MINI_D := 96.0
const MINI_REACH := 360.0
## Map north (the L-shaped map, 2026-10-31): the minimap's and the full map's ground off the map
## (past the bounds and over the corner left outside), a step darker than the card's paper so the
## map reads as an L. Its chroma is over 0.2, so MINI_CLIP's night palette darkens it as an area.
const OFF_MAP := Color("#c8b48e")
## How far past the bounds the off-map ground is drawn (m): the full map at its widest zoom,
## centred on the map's edge, shows about 5.4 km past it on a 19.5:9 screen.
const OFF_MAP_REACH := 6000.0
## The stick's (and Classic's steering strip's) reach: a full push is this far from where the
## thumb came down (loop 2a's 70 HUD units were 43 pt on the user's Pro Max, 38 on a 6.1").
const STICK_R := 42.0
## The pedals and the helicopter's pads: drawn radius and touch reach.
const BRAKE_R := 36.0
const BRAKE_REACH := 46.0
const GAS_R := 40.0
const GAS_REACH := 48.0
const CLASSIC_BRAKE_R := 31.0
const CLASSIC_BRAKE_REACH := 38.0
const PAD_R := 34.0
const PAD_REACH := 40.0
## The night-buses loop: the horn's disc (44 pt across) and its touch radius, left of BRAKE
## (inward, its lower edge level with the brake's), clear of it by HORN_CLEAR pt, so the right
## column above the pedals stays free for the side cards.
const HORN_R := 22.0
const HORN_REACH := 27.0
const HORN_CLEAR := 14.0
## G13 (the upgrade shop): the nitro's disc (52 pt across, bigger than the horn: it is the one a
## thumb reaches for), left of the horn, shown once the nitro is bought; its ring is the tank.
const NITRO_R := 26.0
const NITRO_REACH := 31.0
## Loop 2e: the player's car sits about the middle of the screen (the view leads it a little);
## the passing panels (toasts, the ticker, notes, the overlay, the banner) keep out of a box
## this big round the middle. The cards and the status come first and may cover it.
const CAR_ZONE := Vector2(110.0, 84.0)
## Panel widths.
const CARD_W := 440.0
const STATUS_W := 260.0
const NOTE_W := 236.0
const TICKER_W := 380.0
const TOAST_W := 420.0
## PT-9: how far (points) the ticker moves as it fades in and out; it stays inside the safe area.
const TICKER_SLIDE := 18.0
## A long ticker line that finds no room at TICKER_W wraps this narrow and tries again.
const TICKER_NARROW := 250.0
## Loop 2e: the passing panels that, when the screen is full, wait for room (their time on
## screen counts only once they are up) instead of covering something; the performance overlay
## (a developer's tool) steps aside the same way when even its two-line form finds no room.
const WAITS := ["ticker", "note", "info", "perf"]
## Large text: how far a panel's text steps down at a time when it finds no room at the
## player's text size (Access.LARGE_TEXT), never below the normal size.
const FIT_STEP := 0.05
## A two-finger twist this far (radians) turns a fixed camera 90°.
const TWIST := 0.7
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const ACCENT := Color("#ffd23f")
const OUTLINE := Color("#1d1b19")
## Loop 2e: the one card recipe for every HUD surface (the settings panel's): near-black violet,
## at least 90 % opaque, so no surface takes its colour from the street behind it.
const CARD_BG := Color(0.07, 0.06, 0.1, 0.94)
const CARD_EDGE := Color(1, 1, 1, 0.16)
## Card buttons: the English word the game passes in -> the Polish one shown over it.
const WORDS := {
	"ACCEPT": "PRZYJMIJ", "SKIP": "POMIŃ", "LATER": "PÓŹNIEJ", "NEXT CALL": "NASTĘPNE",
	"FREE ROAM": "SWOBODNIE", "TRY AGAIN": "JESZCZE RAZ", "GO!": "JEDZIEMY!", "NOT NOW": "NIE TERAZ",
}
enum { DOWN = 1, UP = -1 }

## Loop 2e: a two-finger twist with the fixed camera (+1 clockwise on screen).
signal rotate_pressed(direction: int)
signal pinched(ratio: float)          # finger distance now / before
## The follow-camera loop: a second finger turns the stick's finger into a pinch while the stick is
## pushed less than this (a share of its radius: inside its dead zone).
const PINCH_STICK := 0.15
## Loop 3h slice 4: the ghost finger's gesture, once every this many seconds.
const FINGER_LOOP := 1.8
signal vehicle_pressed
signal zoom_pressed(steps: int)       # G3 (2026-11-01): the − (+1, wider) and + (-1, closer) buttons
signal card_pressed(index: int)       # a button on the mission card
signal pill_pressed                   # the context button: a rescue call that came in
signal context_pressed(owner: String) # loop 2d-1: the context button, whoever showed it
signal abort_pressed                  # the ✕ on the mission status
signal challenge_pressed              # FLASH LIGHTS: challenge the rival in front
signal radio_pressed                  # RADIO: next station or off
signal radio_skip_pressed             # RADIO held RADIO_HOLD s: the station's next track
signal tapped(at: Vector2)            # a short tap on the city, not on a control (v0.8: landmarks)
signal perf_gesture                   # three fingers down at once: the performance overlay
signal settings_pressed               # loop 2a: the gear
signal map_pressed                    # F's asks (2026-10-30): a tap on the minimap (the full-screen map)
signal nitro_pressed                  # G13: the nitro's disc went down (nitro_held while the finger stays)
signal horn_pressed                   # the night-buses loop: the horn (a disc over BRAKE / GAS)

var stick := Vector2.ZERO   # -1..1 in screen space, x right, y down
var brake := false
## Loop 2a: the GAS pedal (Classic), and the control scheme the pads are drawn for.
var gas := false
var scheme := 0
## Accessibility (2026-11-01): the pedals on the left, the stick on the right (set_left_handed).
var left_handed := false
var settings_panel: Control
## F's asks (2026-10-30): the full-screen map (full_map.gd), made on its first open.
var full_map: Control
## The minimap's map in metres (its bounds), for the full map.
var _map_bounds := Rect2()
## Map north: the map's outline (map_builder.gd `map_outline`) and the parts of the bounds left
## outside (its `outside`), from setup_minimap: the edge line runs round the outline, and no
## street or park is drawn in an outside part (check_edge counts the minimap's triangles there).
var _map_outline := PackedVector2Array()
## centrum.json, kept (a reference) for the full map's own meshes (full_map.gd, map_art.gd).
var _map_data: Dictionary = {}
## map_builder.gd `landmark_info`, for the full map's icons (main.gd sets it).
var map_landmarks: Array = []
## The full map's art (map_art.gd `prepare`), made on a worker thread from setup_minimap; the
## task's id until the first open waits for it (-1: none pending).
var _map_art_task := -1
var _map_art: Dictionary = {}
var _map_outside: Array[Rect2] = []
## A finger down on the minimap: [index, where, when] (a tap there opens the full map).
var _map_tap: Array = []
## Helicopter height pads: +1 held climbs, -1 sinks.
var climb := 0.0
var flying := false
## Loop 2e: pixels per point (the HUD was sized in 720-line units before), the screen and its
## safe area in pixels.
var pt := 1.0
var _screen := Vector2.ZERO
var _safe := Rect2()

var _gear: Button
var _speed: Label
var _speed_text := ""
var _vehicle_button: Button
var _zoom_out_button: Button
var _zoom_in_button: Button
var _radio_button: Button
## Beta radio (2026-11-02): DALEJ · NEXT under RADIO while the station has more than one song
## (the hold on RADIO and Shift+R stay); set_radio_skip shows it.
var _skip_button: Button
## Seconds RADIO is held before it skips to the station's next track (2026-10-30: the phone's
## skip; a tap still changes the station). Long enough that a slow tap isn't a skip.
const RADIO_HOLD := 0.5
## When RADIO went down (ticks in ms; -1: up), and whether this press has skipped already (its
## release is then not a station change).
var _radio_down_ms := -1
var _radio_skipped := false
## The context button in the middle of the top row (a rescue call that came in).
var _pill: Button
var _pill_t := 0.0
var _pad: Control
var _gas_index := -1
var _climb_index := -1
## Mission card (calls and results), the status panel while a mission runs.
var _card: PanelContainer
var _card_title: Label
var _card_body: Label
## Loop 2e: the English under the Polish title and text (smaller, the sub-text colour).
var _card_title_en: Label
var _card_body_en: Label
var _card_buttons: BoxContainer
## The side jobs' cards sit at the bottom centre, clear of the speech bubbles over the stand
## or the door; the others at the top centre under the top row.
var _card_bottom := false
var _status: PanelContainer
var _status_title: Label
var _status_clock: Label
var _status_hint: Label
var _status_hint_en: Label
var _status_bar: ColorRect
var _status_track: Control
var _status_badge: Label
## Street races: the challenge button and a big banner (countdown, GO!).
var _challenge: Button
var _banner: Label
var _overlay: Control
## The speech bubbles, once `add_speech` has them (the edge arrow keeps off their rects).
var speech: Control
## A short line (Polish, with its English gloss under it) at the bottom for 3 s.
var _toast_box: PanelContainer
var _toast: Label
var _toast_gloss: Label
var _toast_left := 0.0
var _kmh := 0
var _ambient_toast_at := -999.0
## Phase 0.2: the chatter budget (chatter.gd, bubbles.gd's); main.gd sets it. Null: no budget.
var chatter: RefCounted
## G16: ambient toasts (flavour, hints) come at most this often while the car is moving.
const AMBIENT_TOAST_GAP := 20.0
## The performance overlay.
var _perf: PanelContainer
var _perf_label: Label
var _perf_text := ""
## Loop 2e: only the first two lines, when the layout found no room for all of them.
var _perf_compact := false
## Loop 2b: the bench's result card (built when first shown) and the text COPY puts on the
## clipboard.
var _bench_card: PanelContainer
var _bench_label: Label
var _bench_copy: Button
var _bench_text := ""
## Fingers on the screen now (the three-finger tap).
var _fingers := {}
## The now-playing ticker: a panel that slides in, holds, and slides out.
var _ticker: PanelContainer
var _ticker_label: Label
var _ticker_style: StyleBoxFlat
var _ticker_left := 0.0
var _ticker_hold := 4.5
var _ticker_sub: Label
## The wallet under the minimap; a payment shows as "+54 zł" in its place for a moment.
var _wallet: Control
var _wallet_zl := 0
var _wallet_respect := 0
var _wallet_gain := 0
var _wallet_flash := 0.0
const WALLET_FLASH := 2.2
var _wallet_plate: StyleBoxFlat
var _note: PanelContainer
var _note_title: Label
var _note_body: Label
var _note_style: StyleBoxFlat
var _note_left := 0.0
## v0.8: the landmark info card (same look as the note card), and the touches that may turn
## out to be taps: index -> [start position, start time in ms].
var _info_card: PanelContainer
var _info_title: Label
var _info_pl: Label
var _info_en: Label
var _info_left := 0.0
var _taps := {}
## The status panel's picture row: a kebab's steam or the słoiki run's jars.
var _status_icons: Control
var _icons := {}
## Side-job places on the minimap (kebab stands, the station), blinking.
var _mini_pois := PackedVector2Array()
## Loop MW-1: the notebook's places not found yet near the car (map x, z), drawn as "?".
var _mini_unknown := PackedVector2Array()
## The garage loop: the garage's diamond (set_minimap_garage), INF while it isn't shown.
var _mini_garage := Vector2.INF
var _mini_garage_colour := Color.WHITE
## Loop 3h slice 3: the final race's start marker (set_minimap_final), INF while it isn't shown;
## pinned to the rim at any distance (it is the one place to go at night once the final opens).
var _mini_final := Vector2.INF
var _mini_final_colour := Color.WHITE
const GARAGE_REACH := 1500.0
var _mini_poi_colours := PackedColorArray()
## The questlines' starts (story_quests.gd `marks`): points and colours; empty in quest focus.
var _mini_story := PackedVector2Array()
var _mini_story_colours := PackedColorArray()
var _story_names := PackedStringArray()
const STORY_REACH := 1500.0
## Quest focus (main.gd `_story_tick`): something runs; the minimap and the full map hide the side
## places, the garage, the "?" marks and the starts, and the main star dims.
var quest_focus := false
## G11: the shape of each place's mark (MapIcons.POI_*), parallel to _mini_pois; a short or empty array
## means squares.
var _mini_poi_shapes := PackedInt32Array()
## G11 (2026-11-01): a place's mark by kind, so the minimap and the full map are not rows of
## identical squares: a kebab stand a round badge with a white cone, the station a triangle, a
## depot a little house, a scooter a dot, anything else the square.
## The main line (main_line.gd, set by main.gd's `_main_line_tick`): its marker (a gold star in a
## pulsing ring, pinned to the minimap's rim at any distance; INF: this step has no place) and its
## goal line [Polish, English] for the full map. Side quests keep their colours (a ringed dot for
## the active one, squares for the places to start one).
var _main_at := Vector2.INF
var main_goal := PackedStringArray(["", ""])
## Mission target: its point on screen (the arrow) and on the minimap.
var _target_visible := false
var _target_at := Vector2.ZERO
var _target_label := ""
var _target_colour := Color.WHITE
var _mini_target := Vector2.INF
var _mini_target_colour := Color.WHITE
var _mini_dots := PackedVector2Array()
var _mini_dot_colours := PackedColorArray()
## Loop 2d-1: whose the context button is ("call" or "ride").
var pill_owner := "call"
## Loop 2d-1: the card stands in the right-hand column beside the car (show_side_card).
var _card_side := false
var _side_call := false
## Loop 2d-1: the Podwózka app's route on the minimap (map coordinates), drawn dotted.
var _mini_route := PackedVector2Array()
var _mini_route_colour := Color.WHITE
var _mini_route_owner := ""
var _mini_car := Vector2.ZERO
var _mini_yaw := 0.0
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_point := Vector2.ZERO
var _brake_index := -1
## The night-buses loop: the finger on the horn (-1: none).
var _horn_index := -1
## G13: the nitro bought (the disc shows), the tank 0..1 (the ring), and the finger on it (-1: none).
var nitro_owned := false
var nitro_charge := 1.0
var nitro_held := false
var _nitro_index := -1
## Touches that are neither the stick nor the pedals; two of them make a pinch (or a twist).
var _free_touches := {}
var _pinch_distance := 0.0
var _twist_angle := 0.0
var _twist := 0.0
var _marker := Vector2.ZERO
var _marker_visible := false
## Loop 2e: the plate under Classic's steering strip (and its hint).
var _strip_plate: StyleBoxFlat

## Loop 3g-1 (police, part one; docs/design/police.md sections 5.1 and 9): the police pill (a
## passing panel at the top centre: the chase and its end-of-shift countdown, the lizak's "pull
## over"), the koguty (roosters: the light-bar domes, three, beside the wallet; lit, searching
## or a warning's outline), the overlay under the panels (the blue-red edge breath, an edge
## rooster for an off-screen chaser, the lizak paddle over a speed trap's officer), the chasers
## and known traps on the minimap, and panels other scripts lay out here (the pull-over card).
const POLICE_BLUE := Color("#1f4fd8")
const SCENE_AMBER := Color("#ffb020")
const LENS_BLUE := Color("#3d7bff")
const LENS_RED := Color("#ff3b3b")
var _police_pill: PanelContainer
var _police_pl: Label
var _police_en: Label
var _koguty: Control
var _koguty_lit := 0
## 0 hidden, 1 a chase (lit), 2 searching (grey, blinking), 3 a warning (the first outline blinks).
var _koguty_mode := 0
var _koguty_t := 0.0
var _police_fx: Control
var _breath := 0.0
var _edge_roosters := PackedVector2Array()
var _lizak := Vector2.INF
var _police_marks := PackedVector2Array()
var _trap_marks := PackedVector2Array()
## A crash scene (crash_scenes.gd): Vector2.INF when there is none.
var _scene_mark := Vector2.INF
## Panels added by other scripts (`add_panel`): their spot, "top" or "bottom".
var _panel_spots := {}
## The pedals are away while a pull-over holds the car (its card takes the bottom of the screen).
var _pedals_hidden := false
# --- desktop: --no-touch ---------------------------------------------------------------------
## Desktop: --no-touch (trailer loop, 2026-10-29): the touch-only controls stay off the screen
## for good (the pedals and brake, the stick's knob and Classic's strip hint, the helicopter's
## climb and sink pads), and their room goes to the panels; the keys still drive. The top row,
## the minimap, the wallet, the cards and the bubbles stay. Set once by main.gd.
var touch_off := false
# --- end desktop: --no-touch -----------------------------------------------------------------
## Loop 3h slice 4 (docs/DEMO.md 6.2, 0:05): the ghost finger. first10.gd turns it on after 4 s
## without a touch or a key; it is drawn on the pad (no node of its own: +0 draw calls when off)
## and goes at the first touch, click or key. `input_ms`: when the last touch, click or key came
## (Time.get_ticks_msec; 0: none yet).
var input_ms := 0
var _finger := false
var _finger_t := 0.0
## Minimap: north-up data drawn once, then turned and moved so the camera's view is up.
## Loop 2b: every street, park and pond is built once into one 2D mesh, drawn with one call and
## cut to the circle by a small shader (it was 6,500 draw calls, the iPhone's 16 fps).
## Loop 2e: at night (`night` 1) the map takes a night palette: the streets light on a dark
## ground, parks and water dark, so the minimap is no longer the brightest thing on screen.
const MINI_CLIP := """shader_type canvas_item;
uniform vec2 centre;
uniform float radius;
uniform float night = 0.0;
void fragment() {
	if (distance(FRAGCOORD.xy, centre) > radius) {
		discard;
	}
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	vec3 street = vec3(0.98 - l) * vec3(0.8, 0.8, 1.0);
	vec3 area = c * 0.36 + vec3(0.02, 0.02, 0.05);
	COLOR.rgb = mix(c, mix(street, area, smoothstep(0.08, 0.2, sat)), night);
}
"""
var _minimap: Control
var _mini_content: Node2D
var _mini_mesh: ArrayMesh
var _mini_clip: ShaderMaterial
var _mini_overlay: Control
var _mini_radius := 48.0
## Minimap pixels per metre.
var _mini_scale := 0.2
var _car_dir := Vector2.UP
var _north := Vector2.UP
## Loop 2e: 0 by day, 1 at night (the minimap's palette).
var _night := 0.0

## Loop 2e, the layout: the panels that come and go, in order of priority; which of them the
## game wants on screen; where each went; every rect on screen after the last layout (the fixed
## controls and the placed panels; the bubbles keep clear of them); how many found no room.
var _floating: Array[Control] = []
var _wants := {}
var _placed := {}
var _taken: Array[Rect2] = []
var _unplaced: Array[String] = []
## Large text (2026-11-02): the panels that had to step their text down to find room at the
## player's larger text size, and the scale each took (reset at every layout, so a panel grows
## back once there is room). See `_fit_text`.
var _fit_scale := {}
var _dirty := true
var _queued := false
## The ticker's spot is the bottom left (it slides in); elsewhere it fades in.
var _ticker_slides := true
## Where floating panels may go, and the rows the layout hangs them from (pixels).
var _bounds := Rect2()
var _top_y := 0.0
var _col_y := 0.0
var _col_right := 0.0
var _bottom_y := 0.0


func _ready() -> void:
	_screen = get_viewport().get_visible_rect().size
	var m := ScreenPoints.measure(_screen)
	pt = m["pt"]
	_safe = m["safe"]

	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	# Loop 3g-1: the police overlay, under every panel.
	_police_fx = Control.new()
	_police_fx.name = "police_fx"
	_police_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_police_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_police_fx.draw.connect(_draw_police_fx)
	add_child(_police_fx)
	_strip_plate = StyleBoxFlat.new()
	_strip_plate.bg_color = CARD_BG
	_strip_plate.border_color = Color(1, 1, 1, 0.3)
	_strip_plate.set_border_width_all(maxi(1, roundi(1.2 * pt)))

	# The top row: the gear (loop 2a), the speed, the context button, RADIO and HELI / AUTO.
	_gear = Button.new()
	_gear.focus_mode = Control.FOCUS_NONE
	_gear.flat = true
	_gear.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_gear.draw.connect(_draw_gear)
	_gear.pressed.connect(func(): settings_pressed.emit())
	add_child(_gear)
	# Loop 2e: the speed on a plate in the card recipe (it was outlined text over the street).
	_speed = _label(T_BODY, INK)
	_speed.name = "speed"
	var plate := _panel_box(9.0, 0.0)
	plate.content_margin_left = 12.0 * pt
	plate.content_margin_right = 12.0 * pt
	plate.content_margin_top = 6.0 * pt
	plate.content_margin_bottom = 6.0 * pt
	_speed.add_theme_stylebox_override("normal", plate)
	_speed.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_speed)
	_pill = _chip(self, "WEZWANIE", "rescue call", ACCENT)
	# Loop 2d-1: the context button is shared; only a rescue call's press is pill_pressed.
	_pill.pressed.connect(_on_pill)
	_pill.visible = false
	_radio_button = _chip(self, Lang.pick("RADIO wył.", "RADIO off"), "")
	_radio_button.button_down.connect(func():
		_radio_down_ms = Time.get_ticks_msec()
		_radio_skipped = false)
	_radio_button.button_up.connect(func(): _radio_down_ms = -1)
	_radio_button.pressed.connect(func():
		if not _radio_skipped:
			radio_pressed.emit()
		_radio_skipped = false)
	# Beta radio (F, 2026-11-02): a retro player's "next" key joined to the RADIO chip, one
	# segmented plate: [KEBAB FM | ▶▶|]. Drawn (two triangles and a bar), no font glyph.
	_skip_button = Button.new()
	_skip_button.name = "radio_next"
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.flat = true
	_skip_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_skip_button.custom_minimum_size = Vector2(TOUCH, TOUCH) * pt
	_skip_button.draw.connect(_draw_skip)
	_skip_button.button_down.connect(_skip_button.queue_redraw)
	_skip_button.button_up.connect(_skip_button.queue_redraw)
	_skip_button.pressed.connect(func(): radio_skip_pressed.emit())
	_skip_button.visible = false
	add_child(_skip_button)
	_vehicle_button = _chip(self, "HELI", "HELI")
	_vehicle_button.pressed.connect(func(): vehicle_pressed.emit())
	# G3 (F, 2026-11-01): pinch is hard to discover, so − and + sit beside the speed (the car's
	# view only: the helicopter has its own height pads).
	_zoom_out_button = _chip(self, "−", "", Color(0, 0, 0, 0))
	_zoom_out_button.name = "zoom_out"
	_zoom_out_button.pressed.connect(func(): zoom_pressed.emit(1))
	_zoom_in_button = _chip(self, "+", "", Color(0, 0, 0, 0))
	_zoom_in_button.name = "zoom_in"
	_zoom_in_button.pressed.connect(func(): zoom_pressed.emit(-1))
	for zb: Button in [_zoom_out_button, _zoom_in_button]:
		_set_chip(zb, zb.get_child(0).get_child(0).text, "", 44.0)

	_build_ticker()
	_build_mission_panels()
	_build_toast()
	_build_wallet()
	_build_perf()
	_build_police()
	_floating = [_status, _police_pill, _card, _challenge, _banner, _toast_box, _perf, _note, _info_card, _ticker]
	for c in _floating:
		_wants[c] = false
		c.visible = false
	settings_panel = SettingsPanel.new()
	settings_panel.pt = pt
	settings_panel.safe = _safe
	add_child(settings_panel)
	get_viewport().size_changed.connect(_on_resize)
	set_speed(0)
	_layout()


func _on_resize() -> void:
	_screen = get_viewport().get_visible_rect().size
	_safe = ScreenPoints.measure(_screen)["safe"]
	settings_panel.safe = _safe
	if full_map != null:
		full_map.safe = _safe
	_mark()


# --- pieces ----------------------------------------------------------------------------------

## Every label made by `_label`, so `apply_text_scale` can resize them live (Settings → text size).
var _scaled_labels: Array[Label] = []


## Re-apply `Access.text_scale` to every HUD label at once (no restart). Dead labels are dropped.
func apply_text_scale() -> void:
	var alive: Array[Label] = []
	for l in _scaled_labels:  # a freed label cannot be passed typed, so test it before use
		if is_instance_valid(l):
			alive.append(l)
	_scaled_labels = alive
	for l in _scaled_labels:
		l.add_theme_font_size_override("font_size", _px(float(l.get_meta("base_pt")) * Access.text_scale))
	_mark()


## A font size in pixels for a size in points.
func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


## A label on the type scale; `outline` for text that sits on the city rather than a panel.
func _label(points: float, colour: Color, outline := false) -> Label:
	var l := Label.new()
	l.set_meta("base_pt", points)
	_scaled_labels.append(l)
	l.add_theme_font_size_override("font_size", _px(points * Access.text_scale))
	l.add_theme_color_override("font_color", colour)
	if outline:
		l.add_theme_color_override("font_outline_color", OUTLINE)
		l.add_theme_constant_override("outline_size", _px(2.5 if points >= T_SUB else 2.0))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A dark card: near-black, a thin light border, rounded (the art bible's HUD card).
func _panel_box(radius := 10.0, margin := 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(roundi(radius * pt))
	s.set_content_margin_all(margin * pt)
	s.border_color = CARD_EDGE
	s.set_border_width_all(maxi(1, roundi(pt * 0.5)))
	return s


func _box(bg: Color, border: Color, width: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(roundi(10.0 * pt))
	s.border_color = border
	s.set_border_width_all(maxi(1, roundi(width * pt)))
	s.set_content_margin_all(4.0 * pt)
	return s


## Loop 2e: a button at least 44 pt tall with the Polish word over the English one (11 pt).
## `accent` draws its border in a colour (the context button).
func _chip(parent: Node, pl: String, en: String, accent := Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var lit := accent.a > 0.0
	var normal := _box(CARD_BG, accent if lit else Color(1, 1, 1, 0.22), 2.0 if lit else 1.0)
	var pressed := _box(Color(1, 0.82, 0.25, 0.3), ACCENT, 2.0)
	for s in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(s, normal)
	for s in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in [[T_BODY, accent if lit else INK], [T_LABEL, SUB]]:
		var l := _label(t[0], t[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
	b.add_child(words)
	parent.add_child(b)
	_set_chip(b, pl, en)
	return b


## New words on a chip; its width follows them (at least 64 pt).
func _set_chip(b: Button, pl: String, en: String, min_width := 64.0) -> void:
	pl = Lang.pick(pl, en)
	en = ""
	var words := b.get_child(0)
	var top := words.get_child(0) as Label
	var low := words.get_child(1) as Label
	top.text = pl
	low.text = en
	low.visible = en != ""
	var font := ThemeDB.fallback_font
	var w := maxf(font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x,
			font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x)
	b.custom_minimum_size = Vector2(maxf(w + 24.0 * pt, min_width * pt), TOUCH * pt)
	b.size = b.custom_minimum_size
	_mark()


## A wrapped label `w` points wide (its height follows the text at that width at once).
func _wrap(l: Label, w: float) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w * pt
	l.size.x = w * pt


# --- the layout ------------------------------------------------------------------------------

## Something changed size or came or went: lay the HUD out again before the frame is drawn.
func _mark() -> void:
	_dirty = true
	if not _queued and is_inside_tree():
		_queued = true
		_relayout.call_deferred()


func _relayout() -> void:
	_queued = false
	if _dirty:
		_layout()


## Shows or hides a floating panel (the layout decides where, or that there's no room).
func _show(c: Control, on: bool) -> void:
	if bool(_wants.get(c, false)) != on:
		_wants[c] = on
		if not on:
			c.visible = false
		_mark()


## The fixed controls: the top row, the minimap and the wallet under the gear.
func _layout_fixed() -> void:
	var x0 := _safe.position.x + EDGE * pt
	var y := ROW_Y * pt
	_gear.position = Vector2(x0, y)
	_gear.size = Vector2.ONE * TOUCH * pt
	_speed.size = _speed.get_combined_minimum_size()
	_speed.position = Vector2(x0 + (TOUCH + 8.0) * pt, y + (ROW_H * pt - _speed.size.y) * 0.5)
	var right := _safe.end.x - EDGE * pt
	for b: Button in [_vehicle_button, _skip_button, _radio_button]:
		if not b.visible:
			continue  # loop 3h slice 4: the HELI chip waits for the first rescue
		b.size = b.custom_minimum_size
		b.position = Vector2(right - b.size.x, y)
		# Beta radio: the next key sits flush against RADIO (one plate, a hairline between).
		right = b.position.x - (0.0 if b == _skip_button else GAP * pt)
	_style_radio_plate()
	_pill.size = _pill.custom_minimum_size
	_pill.position = Vector2(_safe.get_center().x - _pill.size.x * 0.5, y)
	var below := (ROW_Y + ROW_H + GAP) * pt
	if _minimap != null:
		_minimap.position = Vector2(x0, below)
		_minimap.size = Vector2.ONE * MINI_D * pt
		_mini_overlay.size = _minimap.size
		# G3: the zoom buttons stand in a column right of the minimap (the top row has no room
		# beside a centred context button on a small phone).
		var zy := _minimap.position.y
		var zx := _minimap.position.x + _minimap.size.x + 6.0 * pt
		for zb: Button in [_zoom_in_button, _zoom_out_button]:
			zb.visible = not flying
			zb.size = zb.custom_minimum_size
			zb.position = Vector2(zx, zy)
			zy += zb.size.y + 6.0 * pt
		below = _minimap.position.y + _minimap.size.y + 6.0 * pt
	_wallet.position = Vector2(x0, below)
	_wallet.size = Vector2(_wallet_width(), 30.0 * pt)
	_top_y = (ROW_Y + ROW_H + GAP) * pt
	_col_y = _wallet.position.y + _wallet.size.y + GAP * pt
	_col_right = maxf(_wallet.position.x + _wallet.size.x, below - 6.0 * pt if _minimap == null else _minimap.position.x + _minimap.size.x + (0.0 if flying else 6.0 * pt + _zoom_in_button.size.x)) + GAP * pt
	# Loop 3g-1: the koguty beside the wallet, on its row.
	_koguty.position = Vector2(_wallet.position.x + _wallet.size.x + 6.0 * pt, _wallet.position.y)
	_koguty.size = Vector2(KOGUTY_W * pt, _wallet.size.y)
	# The credit line left the screen (the credits page in Settings has it): the bottom is the safe edge.
	_bottom_y = _safe.end.y - 9.0 * pt - 14.0 * pt
	_bounds = Rect2(_safe.position.x + 4.0 * pt, _top_y, _safe.size.x - 8.0 * pt, _safe.end.y - 4.0 * pt - _top_y)


## Lays the HUD out: the fixed controls, then each floating panel the game wants on screen, in
## order of priority, at its spot or given way along its column (down from the top row, up
## from the bottom) until it is clear of everything placed before it; a panel that finds no
## room anywhere waits off screen until there is (counted in `_unplaced`).
func _layout() -> void:
	_dirty = false
	if _perf_compact:
		_perf_compact = false
		_perf_label.text = _perf_lines()
	_layout_fixed()
	for c: Control in _fit_scale:
		_scale_text(c, Access.text_scale)  # full size again: it shrinks below only if it must
	_fit_scale.clear()
	_taken.clear()
	_placed.clear()
	_unplaced.clear()
	for c: Control in [_gear, _pill, _radio_button, _skip_button, _vehicle_button, _zoom_out_button, _zoom_in_button, _minimap, _wallet, _koguty]:
		if c != null and c.visible:
			_taken.append(Rect2(c.position, c.size))
	_taken.append(_speed_rect())
	_taken.append_array(_pedal_rects())
	if _finger:
		# PT-26 (2026-11-07): the ghost finger's two-line hint is room taken too, so a bubble
		# (the Marszałkowska roadworks sign by the start) keeps off the words that teach steering.
		_taken.append(finger_hint_rect())
	var car_zone_added := false
	for c in _floating:
		if not car_zone_added and not c in [_status, _police_pill, _card, _challenge] and not _panel_spots.has(c):
			_taken.append(car_zone())
			car_zone_added = true
		if not bool(_wants.get(c, false)):
			c.visible = false
			continue
		var s := c.get_combined_minimum_size()
		var at := _place(c, s, _spots(c, s))
		if at < 0 and c == _perf and not _perf_compact:
			# No room for the whole overlay: its first two lines (fps and draw calls).
			_perf_compact = true
			_perf_label.text = _perf_lines()
			s = c.get_combined_minimum_size()
			at = _place(c, s, _spots(c, s))
		if at < 0 and c == _ticker and _ticker_label.custom_minimum_size.x > TICKER_NARROW * pt + 1.0:
			# No room for the long line: wrapped narrower it may fit beside what's in the way.
			for l: Label in [_ticker_label, _ticker_sub]:
				_wrap(l, TICKER_NARROW)
				l.update_minimum_size()
			_ticker.reset_size()
			s = c.get_combined_minimum_size()
			at = _place(c, s, _spots(c, s))
		if at < 0 and not String(c.name) in WAITS:
			at = _fit_text(c)
		c.visible = at >= 0
		if c == _ticker:
			_ticker_slides = at == 0
		if at < 0:
			# The ticker and the note and landmark cards wait for room (their clocks stop: see
			# WAITS); anything else is a layout fault.
			_unplaced.append(c.name)


## Large text (2026-11-02): a panel that must show (the status, the cards, the banner) and found
## no room at the player's text size steps its own text down FIT_STEP at a time, as little as
## it takes, to the normal size at most; the rest of the HUD keeps the larger text. Returns the
## spot it took, or -1 (no room even at the normal size: a layout fault, as before).
func _fit_text(c: Control) -> int:
	var k := Access.text_scale
	while k > 1.0 + 0.001:
		k = maxf(1.0, k - FIT_STEP)
		_scale_text(c, k)
		_fit_scale[c] = k
		var s := c.get_combined_minimum_size()
		var at := _place(c, s, _spots(c, s))
		if at >= 0:
			return at
	return -1


## Every HUD label in `c` (or `c` itself) at `k` times its size on the type scale.
func _scale_text(c: Control, k: float) -> void:
	for l in _scaled_labels:
		if is_instance_valid(l) and (l == c or c.is_ancestor_of(l)):
			l.add_theme_font_size_override("font_size", _px(float(l.get_meta("base_pt")) * k))
			l.update_minimum_size()
	c.update_minimum_size()
	c.reset_size()


## For tools/check_hud.gd: the panels showing smaller text than the player's setting, and how much.
func fitted() -> Dictionary:
	if _dirty:
		_layout()
	var out := {}
	for c: Control in _fit_scale:
		out[String(c.name)] = _fit_scale[c]
	return out


## The spots a floating panel of size `s` may take, in order: [position, DOWN or UP].
func _spots(c: Control, s: Vector2) -> Array:
	var cx := _safe.get_center().x
	var col := _safe.position.x + EDGE * pt
	var top := Vector2(cx - s.x * 0.5, _top_y)
	var bottom := Vector2(cx - s.x * 0.5, _bottom_y - s.y)
	# Beside the minimap and the wallet, when the middle is taken.
	var beside := Vector2(_col_right, _top_y)
	var beside_low := Vector2(_col_right, _bottom_y - s.y)
	if c == _status:
		return [[Vector2(_safe.end.x - EDGE * pt - s.x, _top_y), DOWN]]
	if c == _police_pill or _panel_spots.get(c, "") == "top":
		return [[top, DOWN], [beside, DOWN]]
	if _panel_spots.get(c, "") == "bottom":
		return [[bottom, UP], [beside_low, UP]]
	if c == _card and _card_side:
		return [[Vector2(_safe.end.x - EDGE * pt - s.x, _top_y), DOWN]]  # loop 2d-1, beside the car
	if c == _card:
		return [[bottom, UP], [beside_low, UP]] if _card_bottom else [[top, DOWN], [beside, DOWN]]
	if c == _challenge:
		return [[bottom, UP], [beside_low, UP]]
	if c == _toast_box:
		return [[bottom, UP], [beside_low, UP], [top, DOWN]]
	if c == _banner:
		var mid := Vector2(cx - s.x * 0.5, _screen.y * 0.5 - s.y - 50.0 * pt)
		return [[mid, UP], [mid, DOWN]]
	if c == _perf:
		return [[top, DOWN], [beside, DOWN], [Vector2(col, _col_y), DOWN], [bottom, UP], [beside_low, UP]]
	if c == _note or c == _info_card:
		# Landmark card fix: the right-hand column under the top row first (beside the car, as
		# the status panel and the ride's side card stand); the old spots stay as fallbacks.
		return [[Vector2(_safe.end.x - EDGE * pt - s.x, _top_y), DOWN], [Vector2(col, _col_y), DOWN],
				[beside, DOWN], [top, DOWN], [bottom, UP], [beside_low, UP]]
	if c == _ticker:
		return [[Vector2(col, _bottom_y - s.y), UP], [bottom, UP], [beside_low, UP], [top, DOWN], [beside, DOWN]]
	return []


## Puts `c` (size `s`) at the first candidate spot [position, DOWN or UP] where, after giving
## way along that direction, it is inside the bounds and clear of every rect taken so far.
## Returns the candidate's index, or -1.
func _place(c: Control, s: Vector2, cands: Array) -> int:
	var g := 6.0 * pt
	# Loop 2d-1: the ride's side card stands beside the car, never over it (too wide for the room
	# there at large text, it fits its text: `_fit_text`).
	var taken := _taken.duplicate()
	if c == _card and _card_side:
		taken.append(car_zone())
	for k in cands.size():
		var r := Rect2(cands[k][0], s)
		var flow: int = cands[k][1]
		r.position.x = clampf(r.position.x, _bounds.position.x, maxf(_bounds.end.x - s.x, _bounds.position.x))
		for i in 12:
			if not _bounds.encloses(r):
				break
			var hit := Rect2()
			for t: Rect2 in taken:
				if r.grow(g).intersects(t):
					hit = t
					break
			if not hit.has_area():
				c.position = r.position
				c.size = s
				_taken.append(r)
				_placed[c] = r
				return k
			r.position.y = hit.end.y + g if flow == DOWN else hit.position.y - g - s.y
	return -1


## The room the speed's plate may take: as wide as it gets ("188 km/h · 188 m"), so nothing has
## to move as the number changes.
func _speed_rect() -> Rect2:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size("888 km/h · 888 m", HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x + 24.0 * pt
	return Rect2(_speed.position, Vector2(maxf(w, _speed.size.x), _speed.size.y))


## The pedals' (or the helicopter pads') plates with 4 pt round them, and where Classic's
## steering strip waits. (Their touch reach is a little wider; a card over its edge takes the
## touches it covers.)
func _pedal_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if _pad_nitro_shown():
		var nc := _nitro_centre()
		var nr := (NITRO_R + 4.0) * pt
		out.append(Rect2(nc - Vector2(nr, nr), Vector2(nr * 2.0, nr * 2.0 + _px(T_LABEL) + 4.0 * pt)))
		return out  # the pad: only the nitro's tank stays on screen
	if touch_off or (_pedals_hidden and not flying):
		return out  # desktop: --no-touch keeps none
	var disc := func(c: Vector2, r: float) -> Rect2: return Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0)
	if flying:
		out.append(disc.call(_climb_centre(1), (PAD_R + 4.0) * pt))
		out.append(disc.call(_climb_centre(-1), (PAD_R + 4.0) * pt))
		return out
	out.append(disc.call(_brake_centre(), ((CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) + 4.0) * pt))
	out.append(disc.call(_horn_centre(), (HORN_R + 4.0) * pt))  # the night-buses loop: the horn
	if nitro_owned:
		out.append(disc.call(_nitro_centre(), (NITRO_R + 4.0) * pt))  # G13: the nitro
	if scheme == CLASSIC:
		out.append(disc.call(_gas_centre(), (GAS_R + 4.0) * pt))
		var o := _strip_hint_centre()
		out.append(Rect2(o - Vector2(52, 12) * pt, Vector2(104, 24) * pt))
	return out


## Every rect the HUD has on screen (the fixed controls and the panels up now); the speech
## bubbles keep clear of them.
func panel_rects() -> Array[Rect2]:
	if _dirty:
		_layout()
	return _taken


## Loop 2e: the box round the middle of the screen, where the player's car usually is.
func car_zone() -> Rect2:
	return Rect2(_screen * 0.5 - CAR_ZONE * pt * 0.5, CAR_ZONE * pt)


## Loop 2e: where the bubbles may go: inside the safe area, under the top row.
func bubble_area() -> Rect2:
	return Rect2(_safe.position.x + 4.0 * pt, (ROW_Y + ROW_H + 4.0) * pt, _safe.size.x - 8.0 * pt,
			_safe.end.y - 4.0 * pt - (ROW_Y + ROW_H + 4.0) * pt)


## Loop 2e, for tools/check_hud.gd: the safe area, and the panels the layout found no room for.
func safe_rect() -> Rect2:
	return _safe


func unplaced() -> Array[String]:
	if _dirty:
		_layout()
	var out: Array[String] = []
	for n in _unplaced:
		if not n in WAITS:
			out.append(n)
	return out


## For tools/check_hud.gd: the passing panels waiting for room now.
func waiting() -> Array[String]:
	var out: Array[String] = []
	for n in _unplaced:
		if n in WAITS:
			out.append(n)
	return out


## For tools/check_hud.gd: takes everything that comes and goes off the screen at once.
func clear_all() -> void:
	for c in _floating:
		_show(c, false)
	_toast_left = 0.0
	_ticker_left = 0.0
	_note_left = 0.0
	_info_left = 0.0
	_wallet_flash = 0.0
	hide_pill()
	hide_bench_card()
	set_koguty(0, 0)
	police_fx(0.0, PackedVector2Array(), Vector2.INF)
	set_pedals_hidden(false)
	_mark()


## For tools/check_hud.gd: every control the player can press now, with a name.
func touch_targets() -> Dictionary:
	if _dirty:
		_layout()
	var out := {}
	for c: Control in [_gear, _pill, _radio_button, _skip_button, _vehicle_button, _zoom_out_button, _zoom_in_button, _challenge]:
		if c.is_visible_in_tree():
			out[c.name] = c.get_global_rect()
	for c: Control in [_card, _status, _bench_card] + _panel_spots.keys():
		if c != null and c.is_visible_in_tree():
			for b in c.find_children("*", "Button", true, false):
				if (b as Button).is_visible_in_tree():
					out["%s/%s" % [c.name, b.name]] = (b as Control).get_global_rect()
	var disc := func(c: Vector2, r: float) -> Rect2: return Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0)
	if touch_off:
		pass  # desktop: --no-touch, no pedals or pads to press
	elif flying:
		out["climb"] = disc.call(_climb_centre(1), PAD_R * pt)
		out["sink"] = disc.call(_climb_centre(-1), PAD_R * pt)
	else:
		out["brake"] = disc.call(_brake_centre(), (CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) * pt)
		if not _pedals_hidden:
			out["horn"] = disc.call(_horn_centre(), HORN_R * pt)
			if nitro_owned:
				out["nitro"] = disc.call(_nitro_centre(), NITRO_R * pt)
		if scheme == CLASSIC:
			out["gas"] = disc.call(_gas_centre(), GAS_R * pt)
	return out


## For tools/check_hud.gd: each panel and fixed control on screen now, by name.
func named_rects() -> Dictionary:
	if _dirty:
		_layout()
	var out := {}
	for c: Control in [_gear, _pill, _radio_button, _skip_button, _vehicle_button, _zoom_out_button, _zoom_in_button, _minimap, _wallet, _koguty]:
		if c != null and c.visible:
			out[c.name] = Rect2(c.position, c.size)
	out["speed"] = _speed_rect()
	for c in _placed:
		out[(c as Control).name] = _placed[c]
	var pedals := _pedal_rects()
	for i in pedals.size():
		out["pedal%d" % i] = pedals[i]
	return out


# --- the top row -----------------------------------------------------------------------------

## The speed (and the helicopter's height) beside the gear.
func set_speed(kmh: int, metres := -1) -> void:
	_kmh = kmh
	var text := "%d km/h" % kmh if metres < 0 else "%d km/h · %d m" % [kmh, metres]
	if text != _speed_text:
		_speed_text = text
		_speed.text = text
		_speed.size = _speed.get_combined_minimum_size()


## Beta radio: the next key shows while the tuned station has another song to skip to.
func set_radio_skip(on: bool) -> void:
	if _skip_button.visible != on:
		_skip_button.visible = on
		_mark()


## Beta radio: the tuned station's colour: its name on the chip in it (like a car radio's
## display), and the next key's arrows.
var _radio_colour := INK


func set_radio_colour(c: Color) -> void:
	_radio_colour = c
	var top := _radio_button.get_child(0).get_child(0) as Label
	top.add_theme_color_override("font_color", c)
	_skip_button.queue_redraw()


## RADIO's plate squares its right corners while the next key is joined to it.
func _style_radio_plate() -> void:
	var r := 0 if _skip_button.visible else roundi(10.0 * pt)
	for st in ["normal", "hover", "disabled", "pressed", "hover_pressed"]:
		var box := _radio_button.get_theme_stylebox(st) as StyleBoxFlat
		if box != null and box.corner_radius_top_right != r:
			box = box.duplicate() as StyleBoxFlat
			box.corner_radius_top_right = r
			box.corner_radius_bottom_right = r
			_radio_button.add_theme_stylebox_override(st, box)


## Beta radio: the next key, a retro player's ▶▶| in the card recipe: the plate with its right
## corners rounded, a hairline on its left where it meets RADIO, the arrows in the station colour.
func _draw_skip() -> void:
	var sz := _skip_button.size
	var held := _skip_button.is_pressed()
	var box := _box(Color(1, 0.82, 0.25, 0.3) if held else CARD_BG, ACCENT if held else Color(1, 1, 1, 0.22), 2.0 if held else 1.0)
	box.corner_radius_top_left = 0
	box.corner_radius_bottom_left = 0
	_skip_button.draw_style_box(box, Rect2(Vector2.ZERO, sz))
	var ink := ACCENT if held else _radio_colour
	var c := sz * 0.5
	var h := 7.0 * pt
	var w := 6.5 * pt
	var x0 := c.x - w - 2.0 * pt
	for k in 2:
		var x := x0 + k * w
		_skip_button.draw_colored_polygon(PackedVector2Array([Vector2(x, c.y - h), Vector2(x + w, c.y), Vector2(x, c.y + h)]), ink)
	_skip_button.draw_rect(Rect2(x0 + 2.0 * w, c.y - h, 2.2 * pt, 2.0 * h), ink)


func set_radio_name(station_name: String) -> void:
	_radio_name = station_name
	# One line: the station (its own name is the same in both languages), or RADIO off.
	_set_chip(_radio_button, Lang.pick("RADIO wył.", "RADIO off") if station_name == "OFF" else station_name, "")


## The station the radio button shows (renewed when the language changes).
var _radio_name := "OFF"


## Settings → JĘZYK (or the title's buttons): every surface the HUD built once is made again in
## the chosen language (lang.gd). The settings panel is rebuilt at once, on its open tab; the full
## map when it next opens.
func language_changed(state: Dictionary) -> void:
	set_radio_name(_radio_name)
	_set_chip(_vehicle_button, "AUTO" if flying else "HELI", "CAR" if flying else "HELI")
	if settings_panel != null:
		settings_panel.rebuild.call_deferred(state)


## The context button: a call came in (Polish, English under it); pressing it emits pill_pressed.
## Loop 2d-1: `owner` says whose it is ("call", or "ride" for PODWÓZKA · rides.gd); every press
## also emits context_pressed(owner).
func show_pill(pl: String, en := "", owner := "call") -> void:
	pill_owner = owner
	_pill_words = [pl, en]
	_label_pill()
	if not _pill.visible:
		_pill.visible = true
		_pill_t = 0.0
		_mark()


## The context button's words as shown, kept so the pad's button can be put in front of them
## when the pad takes over (and taken off when a finger does).
var _pill_words := ["", ""]


## The context button's label: with the pad in use its button comes first ("A · KASETA"), so a
## pad player sees which button presses it (2026-11-03: the pad had no way to press it).
func _label_pill() -> void:
	var pl: String = _pill_words[0]
	var en: String = _pill_words[1]
	if pad_mode:
		pl = "%s · %s" % [Gamepad.key("a"), pl]
		en = "%s · %s" % [Gamepad.key("a"), en] if en != "" else ""
	_set_chip(_pill, pl, en, 96.0)


## A press of the context button, by a finger or the pad's A (`press_pill`). Only a rescue
## call's press is pill_pressed; every press is context_pressed(owner) (loop 2d-1).
func _on_pill() -> void:
	if pill_owner == "call":
		pill_pressed.emit()
	context_pressed.emit(pill_owner)


## The pad's A (main.gd `_primary`): presses the context button when it is up, as a tap would.
## False when it is not up, so A falls through to what it did before.
func press_pill() -> bool:
	if not _pill.visible:
		return false
	_on_pill()
	return true


## Loop 2d-1: the context button is up and `owner`'s.
func pill_shown(owner: String) -> bool:
	return _pill.visible and pill_owner == owner


## Loop MW-6: nobody's context button is up (KASETA waits for a free one).
func pill_free() -> bool:
	return not _pill.visible


## Who may take the context button from whom (PT-23, 2026-11-06): the ride app's PODWÓZKA is up
## whenever the player could take a ride, so "wait for a free button" meant the stuck offer's
## POMOC DROGOWA (and KASETA by a tape) never came up while it was. A higher rank takes the button;
## the one it took comes back on its own once the button is free again. A rescue call ranks top.
const PILL_RANK := {"ride": 0, "tape": 1, "ride_start": 1, "unstuck": 2, "call": 3}


## True when `owner` outranks `held` (an owner not in PILL_RANK ranks with a call).
static func pill_outranks(owner: String, held: String) -> bool:
	return int(PILL_RANK.get(owner, 3)) > int(PILL_RANK.get(held, 3))


## The context button is free for `owner`: nobody's up, or a lower-ranked owner's (PILL_RANK).
func pill_free_for(owner: String) -> bool:
	return not _pill.visible or pill_outranks(owner, pill_owner)


func hide_pill() -> void:
	if _pill.visible:
		_pill.visible = false
		_mark()


# --- the performance overlay and the bench card ----------------------------------------------

## The performance overlay: small monospace lines on a dark panel (Settings has Quality and the
## TEST button, so the overlay holds only numbers since loop 2e).
func _build_perf() -> void:
	var style := _panel_box(8.0, 8.0)
	_perf = PanelContainer.new()
	_perf.name = "perf"
	_perf.add_theme_stylebox_override("panel", style)
	_perf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perf_label = _label(T_LABEL, Color("#d8f5d0"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_perf_label.add_theme_font_override("font", mono)
	# As wide as its longest line can get, so changing numbers never move the other panels.
	_perf_label.custom_minimum_size.x = mono.get_string_size("x".repeat(44), HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x
	_perf.add_child(_perf_label)
	add_child(_perf)


func show_perf(on: bool) -> void:
	_show(_perf, on)


func set_perf(text: String) -> void:
	_perf_text = text
	_perf_label.text = _perf_lines()


## The overlay's text: all of it, or its first two lines when there is no room for more.
func _perf_lines() -> String:
	if not _perf_compact:
		return _perf_text
	var lines := _perf_text.split("\n")
	return "\n".join(lines.slice(0, 2))


func perf_visible() -> bool:
	return bool(_wants.get(_perf, false))


## Loop 2b: the bench's result: a card in the middle with the numbers (monospace, the same
## text as the clipboard's), KOPIUJ · COPY and ZAMKNIJ · CLOSE (44 pt). Loop 2e: the buttons
## sit in its title row and the numbers wrap to the card, so it fits a phone without shrinking.
func show_bench_card(text: String) -> void:
	_bench_text = text
	if _bench_card == null:
		_build_bench_card()
	_bench_label.text = text
	_set_chip(_bench_copy, "KOPIUJ", "copy", 96.0)
	_bench_card.visible = true
	_fit_bench_card()


func hide_bench_card() -> void:
	if _bench_card != null:
		_bench_card.visible = false


func bench_card_visible() -> bool:
	return _bench_card != null and _bench_card.visible


func _build_bench_card() -> void:
	var style := _panel_box(10.0, 12.0)
	style.border_width_left = roundi(3.0 * pt)
	style.border_color = Color("#5fd4ff")
	_bench_card = PanelContainer.new()
	_bench_card.name = "bench"
	_bench_card.add_theme_stylebox_override("panel", style)
	_bench_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(8.0 * pt))
	_bench_card.add_child(rows)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	rows.add_child(head)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	head.add_child(words)
	var title := _label(T_TITLE, ACCENT)
	title.text = Lang.pick("TEST WYDAJNOŚCI", "PERFORMANCE TEST")
	words.add_child(title)
	var sub := _label(T_SUB, SUB)
	sub.text = Lang.pick("Benchmark · wklej to w czacie", "Benchmark · paste it into the chat")
	words.add_child(sub)
	_bench_copy = _chip(head, "KOPIUJ", "copy")
	_bench_copy.name = "copy"
	_bench_copy.pressed.connect(func():
		DisplayServer.clipboard_set(_bench_text)
		_set_chip(_bench_copy, "SKOPIOWANE", "copied", 96.0)
		_fit_bench_card()
		print("bench: result copied to the clipboard"))
	var close := _chip(head, "ZAMKNIJ", "close")
	_set_chip(close, "ZAMKNIJ", "close", 96.0)
	close.name = "close"
	close.pressed.connect(hide_bench_card)
	_bench_label = _label(T_LABEL, Color("#d8f5d0"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_bench_label.add_theme_font_override("font", mono)
	rows.add_child(_bench_label)
	_bench_card.visible = false
	add_child(_bench_card)
	get_viewport().size_changed.connect(_fit_bench_card)


func _fit_bench_card() -> void:
	if _bench_card == null or not _bench_card.visible:
		return
	var room := _safe.grow(-8.0 * pt)
	# The numbers wrap to the card's width (the safe area's, less the card's margins).
	var font := _bench_label.get_theme_font("font")
	var natural := 0.0
	for line in _bench_text.split("\n"):
		natural = maxf(natural, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x)
	var w := minf(natural + 2.0, room.size.x - 26.0 * pt)
	_bench_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bench_label.custom_minimum_size.x = w
	_bench_label.size.x = w
	_bench_label.update_minimum_size()
	_bench_card.scale = Vector2.ONE
	_bench_card.reset_size()
	var need := _bench_card.get_combined_minimum_size()
	# Shrunk only if it still can't fit (never on the phones the HUD is checked at).
	var k := minf(1.0, room.size.y / maxf(need.y, 1.0))
	_bench_card.scale = Vector2(k, k)
	_bench_card.size = need
	_bench_card.position = room.get_center() - need * k * 0.5


# --- the radio ticker ------------------------------------------------------------------------

## The now-playing panel: bottom left, above the bottom edge, out of the way of the pedals.
func _build_ticker() -> void:
	_ticker_style = _panel_box(8.0, 6.0)
	_ticker_style.content_margin_left = 12.0 * pt
	_ticker_style.content_margin_right = 12.0 * pt
	# Only the left edge takes the station's colour (the card recipe keeps colour off the rest).
	_ticker_style.set_border_width_all(0)
	_ticker_style.border_width_left = roundi(4.0 * pt)
	_ticker_style.border_color = Color("#ff5fc8")
	_ticker = PanelContainer.new()
	_ticker.name = "ticker"
	_ticker.add_theme_stylebox_override("panel", _ticker_style)
	_ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker.add_child(rows)
	_ticker_label = _label(T_BODY, INK)
	rows.add_child(_ticker_label)
	_ticker_sub = _label(T_SUB, Color("#d9d2e6"))
	rows.add_child(_ticker_sub)
	add_child(_ticker)


## Shows a line on the now-playing ticker for a few seconds: the radio's station changes, and
## the radio host's lines with an English subtitle (held longer and wrapped to a readable width).
func ticker(text: String, colour: Color, subtitle := "") -> void:
	text = Lang.pick(text, subtitle)
	subtitle = ""
	colour = Access.tint(colour)  # colour-safe (access.gd)
	var font := ThemeDB.fallback_font
	var room := minf(TICKER_W * pt, _safe.size.x * 0.5)
	var long := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x > room \
			or font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB)).x > room
	for l: Label in [_ticker_label, _ticker_sub]:
		if long:
			_wrap(l, room / pt)
		else:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.custom_minimum_size.x = 0.0
	_ticker_label.text = text
	_ticker_sub.text = subtitle
	_ticker_sub.visible = subtitle != ""
	_ticker_style.border_color = colour
	_ticker.reset_size()
	_ticker_hold = maxf(4.5 if subtitle == "" else 9.0, Chatter.read_time(text + subtitle))
	_ticker_left = _ticker_hold
	_show(_ticker, true)
	_mark()
	_slide_ticker(1.0)


## Eases the ticker in from the left (or just fades it, when it had to go elsewhere). PT-9: it
## used to slide in from off screen, so mid-slide the screen edge cut its first words ("fternoon,
## Warsaw!", at 2.16:1); now it moves a few points, never past the safe area, and fades.
func _slide_ticker(slide: float) -> void:
	var r: Rect2 = _placed.get(_ticker, Rect2())
	var reach := clampf(r.position.x - _safe.position.x, 0.0, TICKER_SLIDE * pt) if _ticker_slides else 0.0
	_ticker.position.x = r.position.x - reach * slide
	_ticker.modulate.a = 1.0 - slide


# --- the toast -------------------------------------------------------------------------------

func _build_toast() -> void:
	var style := _panel_box(8.0, 6.0)
	style.content_margin_left = 14.0 * pt
	style.content_margin_right = 14.0 * pt
	_toast_box = PanelContainer.new()
	_toast_box.name = "toast"
	_toast_box.add_theme_stylebox_override("panel", style)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_child(rows)
	_toast = _label(T_TITLE, INK)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_toast)
	_toast_gloss = _label(T_SUB, SUB)
	_toast_gloss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_toast_gloss)
	add_child(_toast_box)


## A short line at the bottom for 3 s. Loop 10a: with `gloss`, the Polish line sits above its
## English gloss (smaller, the sub-text colour). Loop 2e: on a dark card, so it reads on any
## street by day or night.
## A toast for flavour or a hint, not a quest or danger line: while driving it is dropped if
## another ambient toast came in the last AMBIENT_TOAST_GAP seconds (G16).
## Phase 0.2: also dropped while the car struggles (and a few seconds after: chatter.gd quiet()).
func ambient_toast(text: String, gloss := "") -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _kmh > 10 and now - _ambient_toast_at < AMBIENT_TOAST_GAP:
		return
	if chatter != null and not chatter.toast_ok():
		return
	_ambient_toast_at = now
	toast(text, gloss)


func toast(text: String, gloss := "") -> void:
	text = Lang.pick(text, gloss)
	gloss = ""
	# PT-20 (Autopilot run 20261103-152518): the same toast again while it is still up only
	# keeps it up; it is not shown (and logged, and laid out) a second time.
	if _toast_left > 0.0 and _toast.text == text and bool(_wants.get(_toast_box, false)):
		_toast_left = Chatter.read_time(text)
		return
	# A long line wraps at TOAST_W points rather than running off a phone's screen.
	var font := ThemeDB.fallback_font
	for pair: Array in [[_toast, text, T_TITLE], [_toast_gloss, gloss, T_SUB]]:
		var l: Label = pair[0]
		if font.get_string_size(pair[1], HORIZONTAL_ALIGNMENT_LEFT, -1, _px(pair[2])).x > TOAST_W * pt:
			_wrap(l, TOAST_W)
		else:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.custom_minimum_size.x = 0.0
	_toast.text = text
	_toast_gloss.text = gloss
	_toast_gloss.visible = gloss != ""
	_toast_left = Chatter.read_time(text + gloss)
	_toast_box.modulate.a = 1.0
	_toast_box.reset_size()
	_show(_toast_box, true)
	_mark()


# --- the mission panels ----------------------------------------------------------------------

## The call card sits at the top centre under the top row (a side job's at the bottom centre);
## the running mission's status at the top right, so it never hides a target straight ahead.
func _build_mission_panels() -> void:
	_card = PanelContainer.new()
	_card.name = "card"
	_card.add_theme_stylebox_override("panel", _panel_box(10.0, 10.0))
	_card.custom_minimum_size.x = CARD_W * pt
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", roundi(6.0 * pt))
	_card.add_child(box)
	# The Polish title, and the English one beside it on the right (cut short rather than
	# widening the card).
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	box.add_child(head)
	_card_title = _label(T_TITLE, ACCENT)
	head.add_child(_card_title)
	_card_title_en = _label(T_LABEL, SUB)
	_card_title_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_title_en.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_title_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_card_title_en.clip_text = true
	_card_title_en.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(_card_title_en)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", roundi(2.0 * pt))
	box.add_child(text)
	_card_body = _label(T_SUB, INK)
	_wrap(_card_body, CARD_W - 20.0)
	text.add_child(_card_body)
	_card_body_en = _label(T_SUB, SUB)
	_wrap(_card_body_en, CARD_W - 20.0)
	text.add_child(_card_body_en)
	_card_buttons = BoxContainer.new()
	_card_buttons.add_theme_constant_override("separation", roundi(8.0 * pt))
	box.add_child(_card_buttons)
	add_child(_card)

	_status = PanelContainer.new()
	_status.name = "status"
	_status.add_theme_stylebox_override("panel", _panel_box(10.0, 10.0))
	_status.custom_minimum_size.x = STATUS_W * pt
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	_status.add_child(rows)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", roundi(6.0 * pt))
	rows.add_child(top)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	top.add_child(words)
	_status_title = _label(T_SUB, ACCENT)
	# PT-11: a long goal wraps onto a second line instead of ending in "...".
	_wrap(_status_title, STATUS_W - 70.0)
	words.add_child(_status_title)
	_status_clock = _label(T_CLOCK, Color.WHITE)
	words.add_child(_status_clock)
	_status_badge = _label(T_TITLE, Color.WHITE)
	_status_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_status_badge)
	var abort := _chip(top, "✕", "", Color(0, 0, 0, 0))
	abort.name = "abort"
	abort.custom_minimum_size = Vector2.ONE * TOUCH * pt
	abort.pressed.connect(func(): abort_pressed.emit())
	_status_icons = Control.new()
	_status_icons.custom_minimum_size.y = 36.0 * pt
	_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icons.draw.connect(_draw_status_icons)
	_status_icons.visible = false
	rows.add_child(_status_icons)
	_status_hint = _label(T_SUB, INK)
	_wrap(_status_hint, STATUS_W - 20.0)
	rows.add_child(_status_hint)
	_status_hint_en = _label(T_SUB, SUB)
	_wrap(_status_hint_en, STATUS_W - 20.0)
	rows.add_child(_status_hint_en)
	_status_track = Control.new()
	_status_track.custom_minimum_size.y = 4.0 * pt
	_status_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(_status_track)
	_status_bar = ColorRect.new()
	_status_bar.size = Vector2(0, 4.0 * pt)
	_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_track.add_child(_status_bar)
	add_child(_status)

	_challenge = _chip(self, "MRUGNIJ ŚWIATŁAMI", "flash your lights to race (L)")
	_challenge.name = "challenge"
	_challenge.pressed.connect(func(): challenge_pressed.emit())

	_banner = _label(T_BANNER, Color.WHITE, true)
	_banner.name = "banner"
	_banner.add_theme_constant_override("outline_size", _px(5.0))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)

	# The target pointer: drawn under the speech bubbles and the panels (PT-10: their text wins;
	# `add_speech` puts the bubbles above it), its edge arrow giving way along the edge.
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_target)
	add_child(_overlay)


## A call or a result: title, text, and up to three buttons (emit card_pressed(index)), each
## with the Polish word over the English one. `bottom` puts it at the bottom centre. Loop 2e:
## the title and text in Polish, `title_en` and `body_en` under them in English.
func show_card(title: String, body: String, buttons: PackedStringArray, accent: Color, bottom := false,
		title_en := "", body_en := "", stacked := false) -> void:
	accent = Access.tint(accent)  # colour-safe (access.gd)
	title = Lang.pick(title, title_en)
	body = Lang.pick(body, body_en)
	title_en = ""
	body_en = ""
	# Loop 2d-1: any other card is the centred one again.
	if _card_side and not _side_call:
		_card_side = false
		_set_card_width(CARD_W)
	_card_bottom = bottom
	_card_title.text = title
	_card_title.add_theme_color_override("font_color", accent)
	_card_title_en.text = title_en
	_card_title_en.visible = title_en != ""
	_card_body.text = body
	_card_body_en.text = body_en
	_card_body_en.visible = body_en != ""
	# The rave door's answers (rave.gd): one under another, so three long answers fit a narrow card.
	_card_buttons.vertical = stacked
	for b in _card_buttons.get_children():
		_card_buttons.remove_child(b)
		b.queue_free()
	for i in buttons.size():
		var en := buttons[i]
		var pl: String = WORDS.get(en, en)
		if "|" in en:
			# Loop 3h slice 4: "POLISH|ENGLISH", a button's own two words (the end card's).
			pl = en.get_slice("|", 0)
			en = en.get_slice("|", 1)
		# An all-caps English word reads as a sentence-case gloss; a written answer keeps its case.
		var gloss := en if en != en.to_upper() else en.substr(0, 1) + en.substr(1).to_lower()
		var b := _chip(_card_buttons, pl, "" if pl == en else gloss)
		b.name = "button%d" % i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): card_pressed.emit(i))
	_card.reset_size()
	_show(_card, true)
	_show(_status, false)
	hide_pill()
	_mark()


## PT-13 (2026-11-02): new words on a showing card's button `index` (a job card's GO counts down
## the seconds to the order's own start, so it no longer goes "without a tap" unexplained).
func set_card_button(index: int, pl: String, en: String) -> void:
	var b := _card_buttons.get_node_or_null("button%d" % index) as Button
	if b != null and not b.is_queued_for_deletion():
		_set_chip(b, pl, en)


## The words on a showing card's button `index` ("" when there is none).
func card_button_text(index: int) -> String:
	var b := _card_buttons.get_node_or_null("button%d" % index) as Button
	return "" if b == null else (b.get_child(0).get_child(0) as Label).text


func hide_card() -> void:
	_show(_card, false)


## The running mission or race: where to, the clock, the distance, a hint, how much of the
## hold-still is done (0..1), and an optional badge (race position). Loop 2e: the hint in
## Polish, `hint_en` under it in English.
func show_status(title: String, clock: String, distance: String, hint: String, progress: float, accent: Color,
		badge := "", icons := {}, hint_en := "") -> void:
	accent = Access.tint(accent)  # colour-safe (access.gd)
	hint = Lang.pick(hint, hint_en)
	hint_en = ""
	title = Lang.title(title)
	if icons != _icons:
		if icons.is_empty() != _icons.is_empty():
			_mark()
		_icons = icons
		_status_icons.visible = not icons.is_empty()
		_status_icons.queue_redraw()
	_status_badge.text = badge
	_status_badge.visible = badge != ""
	_status_badge.add_theme_color_override("font_color", Access.tint(Access.GREEN) if badge == "1ST" else ACCENT)
	_status_title.text = title
	_status_title.add_theme_color_override("font_color", accent)
	_status_clock.text = clock + "    " + distance
	if _status_hint.text != hint:
		_status_hint.text = hint
	if _status_hint_en.text != hint_en:
		_status_hint_en.text = hint_en
		_status_hint_en.visible = hint_en != ""
	_status_bar.color = accent
	_status_bar.size.x = _status_track.size.x * clampf(progress, 0.0, 1.0)
	_show(_status, true)


func hide_status() -> void:
	_show(_status, false)


## The button that challenges the rival in front (key L does the same): Polish over English.
func show_challenge(text: String, accent: Color, gloss := "flash your lights to race (L)") -> void:
	accent = Access.tint(accent)  # colour-safe (access.gd)
	var top := (_challenge.get_child(0) as Control).get_child(0) as Label
	if top.text != text:
		_set_chip(_challenge, text, gloss, 240.0)
		top.add_theme_color_override("font_color", accent)
	_show(_challenge, true)


func hide_challenge() -> void:
	_show(_challenge, false)


## A big line across the middle of the screen: the race countdown.
func show_banner(text: String, colour: Color) -> void:
	colour = Access.tint(colour)  # colour-safe (access.gd)
	if _banner.text != text:
		_banner.text = text
		_mark()
	_banner.add_theme_color_override("font_color", colour)
	_show(_banner, true)


func hide_banner() -> void:
	_show(_banner, false)


## Coloured dots on the minimap (the rivals), in map coordinates.
func set_minimap_dots(points: PackedVector2Array, colours: PackedColorArray) -> void:
	_mini_dots = points
	_mini_dot_colours = colours


# --- every frame -----------------------------------------------------------------------------

## RADIO held RADIO_HOLD s skips once per press (called every frame with the time; a check can
## call it with its own clock).
func radio_hold_tick(now_ms: int) -> void:
	if _radio_down_ms >= 0 and not _radio_skipped and now_ms - _radio_down_ms >= int(RADIO_HOLD * 1000.0):
		_radio_skipped = true
		radio_skip_pressed.emit()


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	radio_hold_tick(Time.get_ticks_msec())
	if _toast_left > 0.0:
		_toast_left -= dt
		_toast_box.modulate.a = clampf(_toast_left / 0.6, 0.0, 1.0)
		if _toast_left <= 0.0:
			_show(_toast_box, false)
	if _ticker_left > 0.0 and _ticker.visible:
		# (A ticker waiting for room keeps its time.)
		_ticker_left -= dt
		# Slide in over the first 0.3 s, out over the last 0.4 s.
		var slide := maxf(clampf((_ticker_left - (_ticker_hold - 0.3)) / 0.3, 0.0, 1.0), clampf(1.0 - _ticker_left / 0.4, 0.0, 1.0))
		_slide_ticker(slide * slide)
		if _ticker_left <= 0.0:
			_show(_ticker, false)
	if _wallet_flash > 0.0:
		_wallet_flash -= dt
		if _wallet_flash <= 0.0:
			_mark()  # back to the total: the wallet's width may change
		_wallet.queue_redraw()
	if _note_left > 0.0 and (_note.visible or not _wants.get(_note, false)):
		_note_left -= dt
		_note.modulate.a = clampf(_note_left / 0.6, 0.0, 1.0) * clampf((5.5 - _note_left) / 0.25, 0.0, 1.0)
		if _note_left <= 0.0:
			_show(_note, false)
	if _info_left > 0.0 and (_info_card.visible or not _wants.get(_info_card, false)):
		_info_left -= dt
		_info_card.modulate.a = clampf(_info_left / 0.6, 0.0, 1.0) * clampf((8.0 - _info_left) / 0.25, 0.0, 1.0)
		if _info_left <= 0.0:
			_show(_info_card, false)
	if _finger:
		_finger_t += dt
		_pad.queue_redraw()
	if _pill.visible:
		# The context button breathes so a call that came in is noticed.
		_pill_t += dt
		_pill.modulate.a = 0.78 + 0.22 * cos(_pill_t * 4.0)
	if not _icons.is_empty() and _status.visible:
		_status_icons.queue_redraw()
	if _koguty_mode >= 2:
		# Loop 3g-1: the searching roosters and a warning's outline blink.
		_koguty_t += dt
		_police_fx.queue_redraw()
		if _koguty_mode == 3 and _koguty_t > 2.0:
			set_koguty(0, 0)
	# A panel whose text grew or shrank since it was placed: lay out again.
	if not _dirty:
		for c in _floating:
			if c.visible and c.get_combined_minimum_size() != (_placed.get(c, Rect2()) as Rect2).size:
				_mark()
				break


## In the helicopter the brake gives way to climb and sink pads, and the vehicle button offers
## the car back.
func set_flying(on: bool) -> void:
	flying = on
	_mark()
	_set_chip(_vehicle_button, "AUTO" if on else "HELI", "CAR" if on else "HELI")
	brake = false
	_brake_index = -1
	gas = false
	_gas_index = -1
	climb = 0.0
	_climb_index = -1
	_pad.queue_redraw()
	_mark()


## The speech bubbles (bubbles.gd): above the target pointer, below the panels. PT-10: the
## pointer used to draw over every bubble and the banner.
func add_speech(b: Control) -> void:
	speech = b
	add_child(b)
	move_child(b, 1)
	move_child(_overlay, 1)


## The mission target as seen on screen (`at` in screen pixels); an arrow on the screen edge
## points to it when it's off screen.
func set_target(at: Vector2, label: String, colour: Color, show: bool) -> void:
	colour = Access.tint(colour)  # colour-safe (access.gd)
	if show or _target_visible:
		_overlay.queue_redraw()
	_target_visible = show
	_target_at = at
	_target_label = label
	_target_colour = colour


func set_minimap_target(xz: Vector2, colour: Color) -> void:
	colour = Access.tint(colour)  # colour-safe (access.gd)
	_mini_target = xz
	_mini_target_colour = colour


## Touches on the buttons and cards belong to them, not to the stick.
func _over_panel(p: Vector2) -> bool:
	for c: Control in [_gear, _pill, _radio_button, _skip_button, _vehicle_button, _zoom_out_button, _zoom_in_button, _card, _status, _challenge, _bench_card]:
		if c != null and c.visible and c.get_global_rect().has_point(p):
			return true
	return false


# --- the minimap -----------------------------------------------------------------------------

## `outline` and `outside`: the map's shape (map north; empty: the bounds' rectangle).
func setup_minimap(data: Dictionary, outline := PackedVector2Array(), outside: Array[Rect2] = []) -> void:
	_map_data = data
	_map_outline = outline
	_map_outside = outside
	_mini_radius = MINI_D * 0.5 * pt
	_mini_scale = _mini_radius / MINI_REACH
	_minimap = Control.new()
	_minimap.name = "minimap"
	_minimap.size = Vector2.ONE * _mini_radius * 2.0
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.draw.connect(func(): _minimap.draw_circle(Vector2.ONE * _mini_radius, _mini_radius,
			Color(0.93, 0.9, 0.83, 0.94).lerp(CARD_BG, _night)))
	add_child(_minimap)
	var bb: Array = data.get("bounds", [0.0, 0.0, 0.0, 0.0])
	_map_bounds = Rect2(Vector2(bb[0], bb[1]), Vector2(float(bb[2]) - float(bb[0]), float(bb[3]) - float(bb[1])))
	if _map_outline.size() < 3:
		_map_outline = PackedVector2Array([_map_bounds.position, Vector2(_map_bounds.end.x, _map_bounds.position.y),
				_map_bounds.end, Vector2(_map_bounds.position.x, _map_bounds.end.y)])
	_mini_mesh = _minimap_mesh(data)
	var outline_now := _map_outline
	var outside_now := _map_outside.duplicate()
	_map_art_task = WorkerThreadPool.add_task(func() -> void:
		_map_art = MapArt.prepare(data, outline_now, outside_now), false, "full map art")
	_mini_clip = ShaderMaterial.new()
	_mini_clip.shader = Shader.new()
	_mini_clip.shader.code = MINI_CLIP
	_mini_clip.set_shader_parameter("night", _night)
	_mini_content = Node2D.new()
	_mini_content.material = _mini_clip
	_mini_content.draw.connect(func(): _mini_content.draw_mesh(_mini_mesh, null))
	_minimap.add_child(_mini_content)
	_mini_overlay = Control.new()
	_mini_overlay.size = _minimap.size
	_mini_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_overlay.draw.connect(_draw_minimap_overlay)
	_minimap.add_child(_mini_overlay)
	_layout()


func update_minimap(car_xz: Vector2, car_yaw: float, view_yaw: float) -> void:
	if _minimap == null:
		return
	var s := _mini_scale
	_mini_car = car_xz
	_mini_yaw = view_yaw
	_mini_content.rotation = view_yaw
	_mini_content.position = Vector2.ONE * _mini_radius - (car_xz * s).rotated(view_yaw)
	# The clip is in screen pixels (the HUD layer is not moved or scaled).
	_mini_clip.set_shader_parameter("centre", _minimap.global_position + Vector2.ONE * _mini_radius)
	_mini_clip.set_shader_parameter("radius", _mini_radius)
	_car_dir = Vector2(-sin(car_yaw), -cos(car_yaw)).rotated(view_yaw)
	_north = Vector2(0, -1).rotated(view_yaw)
	_mini_overlay.queue_redraw()


## The minimap's map as one mesh (loop 2b), in the order it was drawn before: parks and
## water, then the streets (draw_polyline's strip: each point pushed out half the width
## along the mean of its two segments' normals), the map's edge and the Palace's dot. Map north:
## first the off-map ground (OFF_MAP: a frame round the bounds and each part left outside), and
## no park, street or tunnel triangle whose middle lies in a part left outside; the edge runs
## round the map's outline (an L since map north), not the bounds.
func _minimap_mesh(data: Dictionary) -> ArrayMesh:
	var s := _mini_scale
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var put := func(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		verts.append_array([a, b, c])
		cols.append_array([col, col, col])
	var outside := _map_outside
	var tri := func(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		var m := (a + b + c) / (3.0 * s)
		for o in outside:
			if o.has_point(m):
				return
		put.call(a, b, c, col)
	var quad := func(r: Rect2) -> void:
		var lo := r.position * s
		var hi := r.end * s
		put.call(lo, Vector2(hi.x, lo.y), hi, OFF_MAP)
		put.call(lo, hi, Vector2(lo.x, hi.y), OFF_MAP)
	var mb := _map_bounds
	var far := mb.grow(OFF_MAP_REACH)
	quad.call(Rect2(far.position, Vector2(far.size.x, mb.position.y - far.position.y)))
	quad.call(Rect2(Vector2(far.position.x, mb.end.y), Vector2(far.size.x, far.end.y - mb.end.y)))
	quad.call(Rect2(Vector2(far.position.x, mb.position.y), Vector2(mb.position.x - far.position.x, mb.size.y)))
	quad.call(Rect2(Vector2(mb.end.x, mb.position.y), Vector2(far.end.x - mb.end.x, mb.size.y)))
	for o in outside:
		quad.call(o.intersection(mb))
	for a in data["areas"]:
		var colour: Color
		match String(a["k"]):
			"park", "grass", "pitch":
				colour = Color("#a9cf7c")
			"water":
				# The river's grey-green-blue (art bible: low chroma, never azure), a step
				# lighter than ground.gdshader's DAY_WATER so it reads on the pale card (chroma kept
				# over 0.2, or MINI_CLIP's night palette would take it for a street).
				colour = Color("#70a0ac")
			_:
				continue
		var pts := PackedVector2Array()
		var flat: Array = a["p"]
		for i in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[i], flat[i + 1]) * s)
		if pts.size() < 3:
			continue
		var ids := Geometry2D.triangulate_polygon(pts)
		for k in range(0, ids.size() - 2, 3):
			tri.call(pts[ids[k]], pts[ids[k + 1]], pts[ids[k + 2]], colour)
	var strip := func(pts: PackedVector2Array, col: Color, width: float, emit: Callable) -> void:
		var prev := Vector2.ZERO
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in pts.size():
			var t := prev
			if i < pts.size() - 1:
				t = (pts[i + 1] - pts[i]).normalized().orthogonal()
				if i == 0:
					prev = t
			var off := (t + prev).normalized() * width * 0.5
			left.append(pts[i] + off)
			right.append(pts[i] - off)
			prev = t
		for i in pts.size() - 1:
			emit.call(left[i], right[i], left[i + 1], col)
			emit.call(right[i], right[i + 1], left[i + 1], col)
	for r in data["roads"]:
		var pts := PackedVector2Array()
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[i], flat[i + 1]) * s)
		if pts.size() < 2:
			continue
		var minor: bool = r["k"] in ["service", "living_street"]
		strip.call(pts, Color("#8d8f94") if minor else Color("#5b5e64"), maxf(1.0, float(r["w"]) * s), tri)
	# Loop 3b: tunnels, dashed (8 m drawn, 8 m left out) so they read as under the ground.
	for r in data.get("tunnels", {}).get("roads", []):
		var flat: Array = r["p"]
		var tp := PackedVector2Array()
		for i in range(0, flat.size() - 1, 2):
			tp.append(Vector2(flat[i], flat[i + 1]))
		var run := 0.0
		for i in tp.size() - 1:
			var a := tp[i]
			var c := tp[i + 1]
			var ln := a.distance_to(c)
			var t := 0.0
			while t < ln:
				var phase := fmod(run + t, 16.0)
				if phase < 8.0:
					var t1 := minf(t + 8.0 - phase, ln)
					strip.call(PackedVector2Array([a.lerp(c, t / ln) * s, a.lerp(c, t1 / ln) * s]),
							Color("#5b5e64"), maxf(1.0, float(r["w"]) * s), tri)
					t = t1
				else:
					t += 16.0 - phase
			run += ln
	var edge := PackedVector2Array()
	for q in _map_outline:
		edge.append(q * s)
	edge.append(_map_outline[0] * s)
	strip.call(edge, Color("#6a503b"), 1.2 * pt, put)
	for l in data.get("landmarks", []):
		if l["name"] == "Pałac Kultury i Nauki":
			var flat: Array = l["p"]
			var centre := Vector2.ZERO
			for i in range(0, flat.size() - 1, 2):
				centre += Vector2(flat[i], flat[i + 1])
			centre = centre / (flat.size() / 2.0) * s
			for k in 24:
				tri.call(centre, centre + Vector2.from_angle(TAU * k / 24.0) * 2.8 * pt,
						centre + Vector2.from_angle(TAU * (k + 1) / 24.0) * 2.8 * pt, Color("#c9a24a"))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh


func _draw_minimap_overlay() -> void:
	var t0 := Time.get_ticks_usec()
	_paint_minimap_overlay()
	spent_usec += Time.get_ticks_usec() - t0


func _paint_minimap_overlay() -> void:
	var centre := Vector2.ONE * _mini_radius
	var o := _mini_overlay
	var s := _mini_scale
	# Loop 3g-1: every shape below is gathered as triangles and drawn with one call (each draw_*
	# was a draw call of its own: ~10-15 for the minimap's marks; the police's added more).
	_tri_begin()
	# Side-job places: small blinking squares, pinned to the rim up to 700 m away.
	var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.006)
	# Quest focus (story_quests.gd, F 2026-11-07): while something runs, the side places, the garage
	# and the "?" marks stay off the minimap; only what the player is doing shows.
	for i in (0 if quest_focus else _mini_pois.size()):
		if _mini_pois[i].distance_to(_mini_car) > 700.0:
			continue
		var r := ((_mini_pois[i] - _mini_car) * s).rotated(_mini_yaw)
		var far := r.length() > _mini_radius - 5.0 * pt
		r = r.limit_length(_mini_radius - 5.0 * pt)
		var half := (2.0 if far else 3.2) * pt
		poi_mark(centre + r, half, Color(_mini_poi_colours[i], blink), _mini_poi_shapes[i] if i < _mini_poi_shapes.size() else MapIcons.POI_SQUARE)
	# The garage loop: the garage's diamond, pinned to the rim up to GARAGE_REACH m away.
	if not quest_focus and _mini_garage != Vector2.INF and _mini_garage.distance_to(_mini_car) <= GARAGE_REACH:
		var g := ((_mini_garage - _mini_car) * s).rotated(_mini_yaw).limit_length(_mini_radius - 6.0 * pt)
		_tri_diamond(centre + g, 4.6 * pt, _mini_garage_colour)
	# Loop 3h slice 3's diamond at the final's start is the main line's star now (main_line.gd).
	for i in _mini_dots.size():
		# Rivals within the minimap's reach; the rest would crowd the rim.
		var r := ((_mini_dots[i] - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 4.0 * pt:
			_tri_fan(centre + r, 2.8 * pt, 0.0, TAU, OUTLINE)
			_tri_fan(centre + r, 2.0 * pt, 0.0, TAU, _mini_dot_colours[i])
	# Loop 3g-1: known speed traps (a small hair dryer in police blue) and the chasers (blue and
	# red in turns, a white outline), within the minimap's reach.
	for q in _trap_marks:
		var r := ((q - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 5.0 * pt:
			var at := centre + r
			_tri_rect(Rect2(at - Vector2(3.6, 2.6) * pt, Vector2(7.2, 5.2) * pt), Color.WHITE)
			_tri_rect(Rect2(at - Vector2(2.8, 1.8) * pt, Vector2(4.0, 3.6) * pt), POLICE_BLUE)
			_tri_rect(Rect2(at + Vector2(0.6, -0.4) * pt, Vector2(2.2, 4.0) * pt), POLICE_BLUE)
	# Loop MW-1: the notebook's undiscovered places, a gold "?" on a dark plate (never a name).
	for q in (PackedVector2Array() if quest_focus else _mini_unknown):
		var r := ((q - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 6.0 * pt:
			_tri_question(centre + r)
	# The questlines' starts (story_quests.gd): a "!" badge in each one's colour, pinned to the rim
	# up to STORY_REACH m away (the list is empty in quest focus).
	for i in _mini_story.size():
		if _mini_story[i].distance_to(_mini_car) > STORY_REACH:
			continue
		var r := ((_mini_story[i] - _mini_car) * s).rotated(_mini_yaw).limit_length(_mini_radius - 7.0 * pt)
		story_badge(centre + r, 0.85, _mini_story_colours[i])
	if _scene_mark != Vector2.INF:
		# A crash scene: an amber dot with a white ring, pulsing slowly (not the chasers' flicker).
		var r := ((_scene_mark - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 5.0 * pt:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			_tri_fan(centre + r, (3.6 + pulse) * pt, 0.0, TAU, Color.WHITE)
			_tri_fan(centre + r, 2.6 * pt, 0.0, TAU, SCENE_AMBER)
	var flip := int(Time.get_ticks_msec() / 200) % 2 == 0
	for i in _police_marks.size():
		var r := ((_police_marks[i] - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 4.0 * pt:
			_tri_fan(centre + r, 3.4 * pt, 0.0, TAU, Color.WHITE)
			_tri_fan(centre + r, 2.4 * pt, 0.0, TAU, LENS_BLUE if flip == (i % 2 == 0) else LENS_RED)
	if _mini_route.size() >= 2:
		_paint_minimap_route(centre, s)
	if _mini_target != Vector2.INF:
		# A side quest's target, pinned to the rim when it's beyond the map's reach: a dot in the
		# job's colour inside a white ring (the main line's is the star below).
		var t := ((_mini_target - _mini_car) * s).rotated(_mini_yaw)
		t = t.limit_length(_mini_radius - 5.0 * pt)
		side_pin(centre + t, 1.0, _mini_target_colour)
	if _main_at != Vector2.INF:
		# The main line: a gold star in a pulsing ring, pinned to the rim at any distance.
		var mr := ((_main_at - _mini_car) * s).rotated(_mini_yaw).limit_length(_mini_radius - 8.0 * pt)
		main_star(centre + mr, 1.3, quest_focus)
	var d := _car_dir.normalized()
	var side := Vector2(-d.y, d.x)
	var tip := centre + d * 6.0 * pt
	var arrow := Color("#d8432f")
	var notch := centre - d * 2.0 * pt
	_tri(tip, centre - d * 4.0 * pt + side * 4.0 * pt, notch, arrow, arrow, arrow)
	_tri(tip, notch, centre - d * 4.0 * pt - side * 4.0 * pt, arrow, arrow, arrow)
	var rim := Color(0.17, 0.15, 0.13, 0.85).lerp(Color(1, 1, 1, 0.3), _night)
	_tri_rim(centre, _mini_radius - 1.9 * pt, _mini_radius - 0.1 * pt, rim)
	_tri_flush(o)
	var font := ThemeDB.fallback_font
	var fs := _px(T_LABEL)
	var n := centre + _north * (_mini_radius - 8.0 * pt)
	o.draw_string(font, n + Vector2(-fs * 0.3, fs * 0.35), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#2a2622").lerp(INK, _night))


## The main line's marker at `at` (k: its size, 1 on the minimap): a gold five-point star with a
## dark rim in a ring that pulses (into the overlay's one triangle batch).
## F (2026-11-07): "like in the Witcher, a big glowing blob" for the main quest: a soft gold glow
## (three fans fading out) breathes under the star, so it is the one mark that shines. `dim` (quest
## focus: a side quest is on) drops the glow and pulse, the star stays as a quiet reminder.
func main_star(at: Vector2, k: float, dim := false) -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	if not dim:
		for g: Array in [[13.0, 0.10], [10.0, 0.16], [7.6, 0.24]]:
			_tri_fan(at, (float(g[0]) + 2.0 * pulse) * pt * k, 0.0, TAU, Color(MainLine.COLOUR, float(g[1]) * (0.7 + 0.3 * pulse)))
		var ring := Color(MainLine.COLOUR, 0.25 + 0.45 * pulse)
		var r0 := (5.6 + 1.2 * pulse) * pt * k
		_tri_ring(at, r0, r0 + 1.4 * pt * k, 0.0, TAU, ring)
	var a := 0.75 if dim else 1.0
	_tri_star(at, 5.2 * pt * k, Color(MainLine.RIM, a))
	_tri_star(at, 4.0 * pt * k, Color(MainLine.COLOUR, a))


## A questline's start (story_quests.gd) at `at` (k: its size, 1 about 7 pt across): a slow halo
## in its colour, a dark rim, the colour disc with a white ring and a bold white "!", so it reads
## apart from the main star (gold, five points) and the street jobs' small icons.
func story_badge(at: Vector2, k: float, colour: Color) -> void:
	var c := Access.tint(colour)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)
	_tri_fan(at, (8.2 + 1.6 * pulse) * pt * k, 0.0, TAU, Color(c, 0.18 + 0.12 * pulse))
	_tri_fan(at, 6.6 * pt * k, 0.0, TAU, OUTLINE)
	_tri_fan(at, 5.6 * pt * k, 0.0, TAU, Color(1, 1, 1, 0.97))
	_tri_fan(at, 4.5 * pt * k, 0.0, TAU, c)
	var w := 1.5 * pt * k
	_tri_rect(Rect2(at + Vector2(-w * 0.5, -3.1 * pt * k), Vector2(w, 3.6 * pt * k)), Color.WHITE)
	_tri_rect(Rect2(at + Vector2(-w * 0.5, 1.4 * pt * k), Vector2(w, w)), Color.WHITE)


## G11: a place's mark at `at` (`half`: about half its width) in `colour`, by shape (MapIcons.POI_*), each
## with the dark outline and, where it has one, a white glyph; triangles into the batch.
func poi_mark(at: Vector2, half: float, colour: Color, shape: int) -> void:
	var o := 1.0 * pt
	var white := Color(1, 1, 1, colour.a)
	match shape:
		MapIcons.POI_KEBAB:
			_tri_fan(at, half + o, 0.0, TAU, Color(OUTLINE, colour.a))
			_tri_fan(at, half, 0.0, TAU, colour)
			_tri(at + Vector2(0, -half * 0.62), at + Vector2(half * 0.46, half * 0.56), at + Vector2(-half * 0.46, half * 0.56), white, white, white)
		MapIcons.POI_STATION:
			var out := Color(OUTLINE, colour.a)
			var e := half * 1.3 + o * 1.4
			_tri(at + Vector2(0, -e), at + Vector2(e, e * 0.8), at + Vector2(-e, e * 0.8), out, out, out)
			var t := half * 1.3
			_tri(at + Vector2(0, -t), at + Vector2(t, t * 0.8), at + Vector2(-t, t * 0.8), colour, colour, colour)
			_tri_rect(Rect2(at + Vector2(-t * 0.12, -t * 0.1), Vector2(t * 0.24, t * 0.5)), white)
		MapIcons.POI_DEPOT:
			var out := Color(OUTLINE, colour.a)
			var e := half + o
			_tri_rect(Rect2(at + Vector2(-e, -e * 0.15), Vector2(e * 2.0, e * 1.15)), out)
			_tri(at + Vector2(-e * 1.25, -e * 0.1), at + Vector2(e * 1.25, -e * 0.1), at + Vector2(0, -e * 1.2), out, out, out)
			_tri_rect(Rect2(at + Vector2(-half, 0.0), Vector2(half * 2.0, half * 0.95)), colour)
			_tri(at + Vector2(-half * 1.15, 0.0), at + Vector2(half * 1.15, 0.0), at + Vector2(0, -half * 1.05), colour, colour, colour)
			_tri_rect(Rect2(at + Vector2(-half * 0.2, half * 0.2), Vector2(half * 0.4, half * 0.75)), white)
		MapIcons.POI_SCOOTER:
			_tri_fan(at, half * 0.8 + o, 0.0, TAU, Color(OUTLINE, colour.a))
			_tri_fan(at, half * 0.8, 0.0, TAU, colour)
		MapIcons.POI_BOAT:
			# A disc with a white motorboat in profile: the hull (bow right), the windscreen.
			_tri_fan(at, half * 1.15 + o, 0.0, TAU, Color(OUTLINE, colour.a))
			_tri_fan(at, half * 1.15, 0.0, TAU, colour)
			var h := half * 1.15
			var a0 := at + Vector2(-h * 0.7, h * 0.05)
			var a1 := at + Vector2(h * 0.78, h * 0.05)
			var a2 := at + Vector2(h * 0.42, h * 0.42)
			var a3 := at + Vector2(-h * 0.6, h * 0.42)
			_tri(a0, a1, a2, white, white, white)
			_tri(a0, a2, a3, white, white, white)
			_tri(at + Vector2(-h * 0.2, h * 0.05), at + Vector2(h * 0.3, h * 0.05), at + Vector2(-h * 0.2, -h * 0.26), white, white, white)
		_:
			_tri_rect(Rect2(at - Vector2.ONE * (half + o), Vector2.ONE * (half + o) * 2.0), Color(OUTLINE, colour.a))
			_tri_rect(Rect2(at - Vector2.ONE * half, Vector2.ONE * half * 2.0), colour)


## A side quest's target at `at` (k: its size): a dot in its colour inside a white ring, with the
## dark outline.
func side_pin(at: Vector2, k: float, colour: Color) -> void:
	_tri_fan(at, 4.0 * pt * k, 0.0, TAU, OUTLINE)
	_tri_fan(at, 3.1 * pt * k, 0.0, TAU, Color(1, 1, 1, 0.95))
	_tri_fan(at, 2.2 * pt * k, 0.0, TAU, colour)


## A five-point star (point up), `r` to a point, the inner corners at 0.45 r.
func _tri_star(at: Vector2, r: float, colour: Color) -> void:
	for i in 10:
		var a0 := -PI * 0.5 + PI * i / 5.0
		var a1 := -PI * 0.5 + PI * (i + 1) / 5.0
		var p0 := at + Vector2.from_angle(a0) * (r if i % 2 == 0 else r * 0.45)
		var p1 := at + Vector2.from_angle(a1) * (r if i % 2 == 1 else r * 0.45)
		_tri(at, p0, p1, colour, colour, colour)


## The main line's marker (map x, z; INF: none) and its goal line (main.gd, a few times a second).
func set_main_line(at: Vector2, pl: String, en: String) -> void:
	pl = Lang.pick(pl, en)
	en = ""
	_main_at = at
	main_goal = PackedStringArray([pl, en])
	if full_map != null and full_map.is_open():
		full_map.set_main_line(at, pl, en)


## The garage loop: a diamond `r` from its centre to a corner, with the dark outline (two
## triangles each: no draw call of its own, it joins the overlay's batch).
func _tri_diamond(at: Vector2, r: float, colour: Color) -> void:
	for k: Array in [[r + 1.2 * pt, OUTLINE], [r, colour]]:
		var q: float = k[0]
		var c: Color = k[1]
		_tri(at + Vector2(0, -q), at + Vector2(q, 0), at + Vector2(0, q), c, c, c)
		_tri(at + Vector2(0, -q), at + Vector2(0, q), at + Vector2(-q, 0), c, c, c)


## Loop 2e: the minimap's day or night palette (time_of_day.gd's lights: 0 day, 1 night).
func set_night(amount: float) -> void:
	if is_equal_approx(amount, _night):
		return
	_night = clampf(amount, 0.0, 1.0)
	if _minimap != null:
		_mini_clip.set_shader_parameter("night", _night)
		_minimap.queue_redraw()
		_mini_overlay.queue_redraw()


func set_car_marker(at: Vector2, show: bool) -> void:
	if show != _marker_visible or (show and at.distance_to(_marker) > 0.5):
		_marker = at
		_marker_visible = show
		_pad.queue_redraw()


## Loop MW-1: the notebook's places not found yet (map coordinates), drawn as "?" (notebook.gd
## sends them twice a second, only when they change).
func set_minimap_unknown(points: PackedVector2Array) -> void:
	_mini_unknown = points


## Loop MW-1: the notebook's record changed (a new entry): the open notebook page shows it.
func notebook_changed() -> void:
	if settings_panel != null and settings_panel.has_method("refresh_notebook"):
		settings_panel.refresh_notebook()


## Loop MW-1: the "?" in pixels of 1.3 pt (3 x 5) on a dark plate, collectibles' gold. Built
## once as triangles round (0, 0) (`_question_pts`, rebuilt when the point size changes); each
## mark is that array moved (one Transform2D on the packed array, no per-pixel script work).
const QUESTION := ["###", "..#", ".##", "...", ".#."]
const QUESTION_GOLD := Color("#f0b429")
var _question_pts := PackedVector2Array()
var _question_cols := PackedColorArray()
var _question_pt := 0.0


func _tri_question(at: Vector2, k := 1.0) -> void:
	if _question_pt != pt:
		_question_pt = pt
		var keep_pts := _tri_pts
		var keep_cols := _tri_cols
		_tri_pts = PackedVector2Array()
		_tri_cols = PackedColorArray()
		var px := 1.3 * pt
		var origin := -Vector2(1.5, 2.5) * px
		_tri_rect(Rect2(origin - Vector2.ONE * px, Vector2(5.0, 7.0) * px), OUTLINE)
		for row in QUESTION.size():
			var line: String = QUESTION[row]
			for col in line.length():
				if line[col] == "#":
					_tri_rect(Rect2(origin + Vector2(col, row) * px, Vector2(px, px)), QUESTION_GOLD)
		_question_pts = _tri_pts
		_question_cols = _tri_cols
		_tri_pts = keep_pts
		_tri_cols = keep_cols
	_tri_pts.append_array(Transform2D(0.0, Vector2(k, k), 0.0, at) * _question_pts)
	_tri_cols.append_array(_question_cols)


## The garage loop: Warsztat u Mirka on the minimap and the full map (map coordinates; INF: not
## shown), a diamond in its colour, pinned to the minimap's rim up to GARAGE_REACH m away.
func set_minimap_garage(p: Vector2, colour: Color) -> void:
	_mini_garage = p
	_mini_garage_colour = colour


## Loop 3h slice 3: the final race's start marker on the minimap and the full map (map
## coordinates; INF: not shown), a diamond in its colour, pinned to the minimap's rim.
func set_minimap_final(p: Vector2, colour: Color) -> void:
	_mini_final = p
	_mini_final_colour = colour


## The questlines' starts on the minimap and the full map, and quest focus (main.gd, a few
## times a second; both only when they change).
func set_story(points: PackedVector2Array, colours: PackedColorArray, focus: bool, names := PackedStringArray()) -> void:
	_mini_story = points
	_mini_story_colours = colours
	_story_names = names
	quest_focus = focus
	if full_map != null and full_map.is_open():
		full_map.set_story(points, colours, focus, names)


## Side-job places on the minimap (map coordinates), drawn as blinking squares.
func set_minimap_pois(points: PackedVector2Array, colours: PackedColorArray, shapes := PackedInt32Array()) -> void:
	_mini_pois = points
	_mini_poi_colours = colours
	_mini_poi_shapes = shapes


# --- loop 2d-1: the Podwózka app's route (rides.gd) -------------------------------------------

## A card in the right-hand column under the top row, as wide as the room right of the car's
## spot allows (at most CARD_W points): the car stays in view (Podwózka's request and result).
## The same card, recipe and point sizes; the next show_card() puts it back in the middle.
func show_side_card(title: String, body: String, buttons: PackedStringArray, accent: Color, title_en := "",
		body_en := "", stacked := false) -> void:
	accent = Access.tint(accent)  # colour-safe (access.gd)
	_card_side = true
	_set_card_width(side_card_width())
	_side_call = true
	show_card(title, body, buttons, accent, false, title_en, body_en, stacked)
	_side_call = false


## The side card's width in points: from the car's spot (and a margin) to the safe area's edge.
func side_card_width() -> float:
	return clampf((_safe.end.x - car_zone().end.x) / pt - 2.0 * EDGE, 200.0, CARD_W)


func _set_card_width(w: float) -> void:
	_card.custom_minimum_size.x = w * pt
	_wrap(_card_body, w - 20.0)
	_wrap(_card_body_en, w - 20.0)
	_card.reset_size()


## A radio caption already up slides out now (a ride card has come; dialogue.gd's host_hold
## keeps the next one back).
func ticker_out() -> void:
	if _ticker_left > 0.4:
		_ticker_left = 0.4


## The app's route as a polyline in map coordinates (empty: none), drawn as dots on the minimap.
## Beta values (2026-11-04): `owner` names who drew it (route_line.gd's users: "jobs", "race"), so
## clear_minimap_route(owner) never wipes a route another activity has drawn since.
func set_minimap_route(points: PackedVector2Array, colour: Color, owner := "") -> void:
	_mini_route = points
	_mini_route_colour = colour
	_mini_route_owner = owner


## Takes the route off the minimap if `owner` drew the one on it now.
func clear_minimap_route(owner: String) -> void:
	if _mini_route_owner == owner:
		_mini_route = PackedVector2Array()
		_mini_route_owner = ""


## The minimap's route now (empty: none): the checks read it.
func minimap_route() -> PackedVector2Array:
	return _mini_route


## A small square every 5 pt along the route, fixed to the map (they don't crawl as the car
## moves), only on the stretches within the minimap's reach; into the overlay's one triangle
## batch (loop 3g-1's _tri_*).
func _paint_minimap_route(centre: Vector2, s: float) -> void:
	var gap := 5.0 * pt / s
	var reach := (_mini_radius - 4.0 * pt) / s
	var half := 1.3 * pt
	var at := 0.0
	for i in _mini_route.size() - 1:
		var a := _mini_route[i]
		var b := _mini_route[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.01:
			continue
		if Geometry2D.get_closest_point_to_segment(_mini_car, a, b).distance_to(_mini_car) <= reach:
			var u := ceilf(at / gap) * gap
			while u <= at + seg:
				var r := ((a.lerp(b, (u - at) / seg) - _mini_car) * s).rotated(_mini_yaw)
				if r.length() < _mini_radius - 4.0 * pt:
					_tri_rect(Rect2(centre + r - Vector2.ONE * (half + 0.8 * pt), Vector2.ONE * (half + 0.8 * pt) * 2.0), OUTLINE)
					_tri_rect(Rect2(centre + r - Vector2.ONE * half, Vector2.ONE * half * 2.0), _mini_route_colour)
				u += gap
		at += seg


# --- the wallet and the note card ------------------------------------------------------------

## The wallet sits under the minimap: a gold coin and the złoty, a pink star and the respect;
## a payment shows as "+54 zł" in green in the money's place for a moment (loop 2e: it used to
## float up over the minimap). The note card (an easter egg found) and the landmark card go
## under it.
func _build_wallet() -> void:
	_wallet = Control.new()
	_wallet.name = "wallet"
	_wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallet.draw.connect(_draw_wallet)
	add_child(_wallet)
	_wallet_plate = _panel_box(9.0, 0.0)
	_note_style = _panel_box(8.0, 8.0)
	_note_style.set_border_width_all(0)
	_note_style.border_width_left = roundi(4.0 * pt)
	_note_style.border_color = ACCENT
	_note = PanelContainer.new()
	_note.name = "note"
	_note.add_theme_stylebox_override("panel", _note_style)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.add_child(rows)
	_note_title = _label(T_SUB, Color("#ff4fd8"))
	rows.add_child(_note_title)
	_note_body = _label(T_SUB, INK)
	_wrap(_note_body, NOTE_W - 20.0)
	rows.add_child(_note_body)
	add_child(_note)

	var info_style := _note_style.duplicate() as StyleBoxFlat
	info_style.border_color = ACCENT
	_info_card = PanelContainer.new()
	_info_card.name = "info"
	_info_card.add_theme_stylebox_override("panel", info_style)
	_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", roundi(2.0 * pt))
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_card.add_child(lines)
	_info_title = _label(T_BODY, ACCENT)
	lines.add_child(_info_title)
	_info_pl = _label(T_SUB, INK)
	_info_en = _label(T_SUB, SUB)
	for l in [_info_pl, _info_en]:
		_wrap(l, NOTE_W - 20.0)
		lines.add_child(l)
	add_child(_info_card)


func set_wallet(zl: int, respect: int, gained := 0) -> void:
	_wallet_zl = zl
	_wallet_respect = respect
	if gained != 0:
		_wallet_gain = gained
		_wallet_flash = WALLET_FLASH
	_wallet.queue_redraw()
	_mark()


## The text in the money's place: the payment for its first 1.6 s, then the total.
func _money_text() -> String:
	if _wallet_flash > WALLET_FLASH - 1.6:
		return ("+" if _wallet_gain > 0 else "") + _money(_wallet_gain)
	return _money(_wallet_zl)


## The wallet's width in pixels: coin, money, star, respect.
func _wallet_width() -> float:
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var money := maxf(font.get_string_size(_money(_wallet_zl), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
			font.get_string_size("+" + _money(_wallet_gain), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if _wallet_flash > 0.0 else 0.0)
	return (8.0 + 20.0 + 10.0 + 20.0 + 10.0) * pt + money + font.get_string_size(str(_wallet_respect), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _draw_wallet() -> void:
	var w := _wallet
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var y := w.size.y * 0.5
	# Loop 2e: on a plate in the card recipe.
	w.draw_style_box(_wallet_plate, Rect2(Vector2.ZERO, w.size))
	# A coin with a "zł" stamp.
	var coin := Vector2(16.0 * pt, y)
	w.draw_circle(coin, 8.0 * pt, OUTLINE)
	w.draw_circle(coin, 6.8 * pt, Color("#f2c12e"))
	w.draw_circle(coin, 4.6 * pt, Color("#d9a21f"))
	var x := 28.0 * pt
	var gain := _wallet_flash > WALLET_FLASH - 1.6
	var money := _money_text()
	var base := Vector2(x, y + fs * 0.36)
	var colour := Color("#ffe27a")
	if gain:
		colour = Color(0.55, 1.0, 0.6).lerp(Color("#ffe27a"), 0.5 + 0.5 * sin(_wallet_flash * 12.0))
	w.draw_string(font, base, money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
	x += maxf(font.get_string_size(money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
			font.get_string_size(_money(_wallet_zl), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) + 10.0 * pt
	# A five-pointed star for respect.
	var star := PackedVector2Array()
	var outer := PackedVector2Array()
	var c := Vector2(x + 8.0 * pt, y)
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		star.append(c + Vector2(cos(a), sin(a)) * (7.2 if k % 2 == 0 else 3.2) * pt)
		outer.append(c + Vector2(cos(a), sin(a)) * (8.8 if k % 2 == 0 else 4.3) * pt)
	w.draw_colored_polygon(outer, OUTLINE)
	w.draw_colored_polygon(star, Color("#ff4fd8"))
	var resp := str(_wallet_respect)
	base = Vector2(x + 20.0 * pt, y + fs * 0.36)
	w.draw_string(font, base, resp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffd0f4"))


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out + " zł"


## A small card under the wallet for a few seconds (an easter egg found).
func show_note(title: String, body: String, colour: Color) -> void:
	colour = Access.tint(colour)  # colour-safe (access.gd)
	_set_note_width()  # landmark card fix
	_note_title.text = title
	_note_title.add_theme_color_override("font_color", colour.lerp(Color.WHITE, 0.2))
	_note_body.text = body
	_note.reset_size()
	_show(_note, true)
	_show(_info_card, false)
	_info_left = 0.0
	_note.modulate.a = 0.0
	_note_left = 5.5
	_mark()


## v0.8: a landmark's info card (it was tapped): the name, a Polish line or two and the
## English under it. It takes the note card's place for eight seconds.
func show_info(title: String, polish: String, english: String) -> void:
	polish = Lang.pick(polish, english)
	english = ""
	_set_note_width()  # landmark card fix
	_info_title.text = title
	_info_pl.text = polish
	_info_en.text = english
	_info_en.visible = english != ""
	_show(_note, false)
	_note_left = 0.0
	_info_card.reset_size()
	_show(_info_card, true)
	_info_card.modulate.a = 0.0
	_info_left = 8.0
	_mark()


# --- landmark card fix ---------------------------------------------------------------------

## The note and landmark cards are NOTE_W points wide, or narrower when the room right of the
## car's spot (the side card's rule, side_card_width()) is less, so they fit in the right-hand
## column beside the car on a short phone. Their labels wrap to that width.
func _set_note_width() -> void:
	var w := minf(NOTE_W, side_card_width())
	for l: Label in [_note_title, _note_body, _info_title, _info_pl, _info_en]:
		_wrap(l, w - 20.0)
	_note.reset_size()
	_info_card.reset_size()


# --- the status panel's pictures --------------------------------------------------------------

## {"heat": 0..1}: a wrapped kebab with steam that fades as it cools. {"jars": [intact,
## total], "shake": 0..1}: a row of mum's jars, the broken ones as shards, rattling
## when one is close to breaking. Drawn in units of 0.62 pt (loop 2e kept their old size on the
## user's Pro Max).
func _draw_status_icons() -> void:
	var c := _status_icons
	var h := c.size.y
	var q := 0.62 * pt
	if _icons.has("heat"):
		var heat: float = _icons["heat"]
		var x := 6.0 * q
		var u := q * 1.5
		# The kebab: a wrap in foil, a cone with the meat and salad showing at the top.
		var foil := PackedVector2Array([Vector2(x + 8 * u, h - 2 * u), Vector2(x + 1 * u, h - 14 * u), Vector2(x + 15 * u, h - 14 * u)])
		c.draw_colored_polygon(foil, Color("#e8c48a").lerp(Color("#b9c6d6"), clampf(1.0 - heat * 1.6, 0.0, 1.0)))
		c.draw_rect(Rect2(Vector2(x + 1 * u, h - 16 * u), Vector2(14 * u, 3 * u)), Color("#c9ced6"))
		c.draw_rect(Rect2(Vector2(x + 3 * u, h - 19 * u), Vector2(10 * u, 3 * u)), Color("#7a4a2a"))
		c.draw_rect(Rect2(Vector2(x + 5 * u, h - 20.5 * u), Vector2(3 * u, 1.5 * u)), Color("#4f9e3f"))
		# Steam: three wavy wisps rising from it, shorter and fainter as it cools.
		var t := Time.get_ticks_msec() * 0.003
		var a := clampf((heat - 0.1) / 0.5, 0.0, 1.0)
		var rise := maxf(h - 22 * u, 0.0) * (0.35 + heat * 0.65)
		for j in 3:
			var pts := PackedVector2Array()
			var sx := x + (3 + j * 5) * u
			for k in 9:
				var f := k / 8.0
				pts.append(Vector2(sx + sin(t * 2.0 + j * 2.1 + f * 6.0) * 1.8 * u, h - 22 * u - f * rise))
			if a > 0.02:
				c.draw_polyline(pts, Color(1, 1, 1, a * (0.9 - j * 0.12)), 2.0 * q)
		# A heat bar beside it, warm to cold.
		var bar := Rect2(Vector2(x + 24 * u, h * 0.5 - 4 * q), Vector2(c.size.x - x - 26 * u, 8 * q))
		c.draw_rect(bar.grow(1.5 * q), OUTLINE)
		c.draw_rect(bar, Color(0.2, 0.22, 0.28))
		var hot := Color("#ff5a2a").lerp(ACCENT, 0.3)
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(heat, 0.0, 1.0), bar.size.y)), Color("#7fb8de").lerp(hot, clampf(heat * 1.4, 0.0, 1.0)))
	elif _icons.has("jars"):
		var jars: Array = _icons["jars"]
		var intact: int = jars[0]
		var total: int = jars[1]
		var shake: float = _icons.get("shake", 0.0)
		var t := Time.get_ticks_msec() * 0.05
		var y0 := h * 0.5 - 7.0 * q
		for k in total:
			var x := (6 + k * 24) * q
			var jiggle := Vector2(sin(t + k * 2.1), cos(t * 1.3 + k)) * shake * shake * 2.2 * q if k < intact else Vector2.ZERO
			var body := Rect2(Vector2(x, y0) + jiggle, Vector2(16 * q, 20 * q))
			if k < intact:
				c.draw_rect(body.grow(1.5 * q), OUTLINE)
				c.draw_rect(body, Color("#d9a441"))
				c.draw_rect(Rect2(body.position + Vector2(2 * q, 7 * q), Vector2(12 * q, 7 * q)), Color("#f4ead2"))
				c.draw_rect(Rect2(body.position + Vector2(-1 * q, -5 * q), Vector2(18 * q, 5 * q)), Color("#c8282a"))
			else:
				# Shards and a puddle.
				c.draw_rect(Rect2(Vector2(x - 2 * q, y0 + 16 * q), Vector2(20 * q, 4 * q)), Color("#a0663a", 0.8))
				for s in [Vector2(1, 8), Vector2(8, 4), Vector2(12, 10)]:
					var p: Vector2 = Vector2(x, y0) + s * q
					c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(4, 6) * q, p + Vector2(-2, 6) * q]), Color("#c9d6dc"))
		var label := "%d/%d" % [intact, total]
		var font := ThemeDB.fallback_font
		var fs := _px(T_BODY)
		var at := Vector2((10 + total * 24) * q, h * 0.5 + fs * 0.36)
		c.draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if intact == total else Color("#ffb05a"))


# --- the pedals and the stick ----------------------------------------------------------------

func _brake_centre() -> Vector2:
	return _side(_brake_right())


## Where BRAKE is in the right-handed layout (the left-handed one mirrors it: `_side`).
func _brake_right() -> Vector2:
	if scheme == CLASSIC:
		# Left of GAS and a little lower, so the thumb rolls from one to the other.
		return Vector2(_safe.end.x - 156.0 * pt, _safe.end.y - 42.0 * pt)
	return Vector2(_safe.end.x - 56.0 * pt, _safe.end.y - 50.0 * pt)


## Accessibility (2026-11-01): the left-handed layout mirrors a point of the right-handed one
## across the safe area's middle (the pedals, the horn, the helicopter's pads, Classic's strip
## and the ghost finger); right-handed, the point as it is.
func _side(p: Vector2) -> Vector2:
	return Vector2(_safe.position.x + _safe.end.x - p.x, p.y) if left_handed else p


## Accessibility (2026-11-01): the left-handed layout on or off (Settings → DOSTĘP; access.gd).
func set_left_handed(on: bool) -> void:
	if on == left_handed:
		return
	left_handed = on
	_mark()
	if _pad != null:
		_pad.queue_redraw()


## Whether a finger coming down at x (pixels) is on the stick's side of the screen: the left
## 60 %, or the right 60 % in the left-handed layout.
func _stick_side(x: float, width: float) -> bool:
	return x > width * 0.4 if left_handed else x < width * 0.6


## Loop 2a: the GAS pedal (Classic), where BRAKE is in the other schemes.
func _gas_centre() -> Vector2:
	return _side(Vector2(_safe.end.x - 58.0 * pt, _safe.end.y - 52.0 * pt))


## The brake's touch radius (a little larger than drawn).
func _brake_reach() -> float:
	return (CLASSIC_BRAKE_REACH if scheme == CLASSIC else BRAKE_REACH) * pt


## Where Classic's steering strip is hinted until a thumb comes down.
func _strip_hint_centre() -> Vector2:
	var x := maxf(_safe.position.x + 110.0 * pt, _screen.x * 0.16)
	return Vector2(_screen.x - x if left_handed else x, _safe.end.y - 60.0 * pt)


func _on_pedals(p: Vector2) -> bool:
	if flying or _pedals_hidden or touch_off:
		return false
	return p.distance_to(_brake_centre()) < _brake_reach() or (scheme == CLASSIC and p.distance_to(_gas_centre()) < GAS_REACH * pt) \
			or _on_horn(p) or _on_nitro(p)


## The night-buses loop: the horn's centre, left of BRAKE (none in the helicopter).
func _horn_centre() -> Vector2:
	var r := CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R
	return _side(_brake_right() + Vector2(-(r + HORN_CLEAR + HORN_R), r - HORN_R) * pt)


## G13: the nitro's centre, left of the horn (right of it in the left-handed layout, which
## mirrors the horn already).
func _nitro_centre() -> Vector2:
	var step := (HORN_R + NITRO_R + 10.0) * pt
	return _horn_centre() + Vector2(step if left_handed else -step, 0.0)


## G13c leftover (2026-11-03): the pad is in use and the nitro bought: its disc stays as the
## tank's gauge (the touch pedals are gone; LB / RB burn it).
func _pad_nitro_shown() -> bool:
	return pad_mode and touch_off and nitro_owned and not flying and not _pedals_hidden


## G13: a touch at `p` is on the nitro's disc.
func _on_nitro(p: Vector2) -> bool:
	return nitro_owned and not touch_off and not flying and not _pedals_hidden and p.distance_to(_nitro_centre()) < NITRO_REACH * pt


## G13: the nitro's state from the car (main.gd, every frame): owned (the disc shows) and the tank.
## The disc redraws only when the ring would move by a visible step.
func set_nitro(owned: bool, charge: float) -> void:
	var q := roundf(charge * 48.0) / 48.0
	if owned == nitro_owned and is_equal_approx(q, nitro_charge):
		return
	if not owned:
		nitro_held = false
		_nitro_index = -1
	nitro_owned = owned
	nitro_charge = q
	if _pad != null:
		_pad.queue_redraw()


## The night-buses loop: a touch at `p` presses the horn.
func _on_horn(p: Vector2) -> bool:
	return not touch_off and not flying and not _pedals_hidden and p.distance_to(_horn_centre()) < HORN_REACH * pt


## Loop 2a: the on-screen controls for a control scheme (drive_controls.gd).
func set_scheme(s: int) -> void:
	scheme = s
	gas = false
	_gas_index = -1
	brake = false
	_brake_index = -1
	_pad.queue_redraw()
	_mark()


## True while the stick's (or steering strip's) finger is down.
func stick_active() -> bool:
	return _stick_index != -1


## Loop 2a, for screenshots and replays (--stick=x,y --pedal=gas|brake): hold the stick at a
## deflection with its centre at `origin` (screen pixels), and a pedal.
func hold_stick(origin: Vector2, v: Vector2) -> void:
	_stick_index = 99
	_stick_origin = origin
	var radius := STICK_R * pt
	_stick_point = origin + (Vector2(v.x, 0.0) if scheme == CLASSIC else v) * radius
	stick = Vector2(v.x, 0.0) if scheme == CLASSIC else v
	_pad.queue_redraw()


func hold_pedal(which: String) -> void:
	if which == "gas":
		_gas_index = 98
		gas = true
	elif which == "brake":
		_brake_index = 97
		brake = true
	elif which == "nitro":  # G13b: gas and the nitro disc, for shots of the flame
		_gas_index = 98
		gas = true
		nitro_held = true
	_pad.queue_redraw()


## Lets go of everything held (the settings panel opened over the game).
func release_all() -> void:
	_stick_index = -1
	stick = Vector2.ZERO
	_brake_index = -1
	brake = false
	_horn_index = -1
	_nitro_index = -1
	nitro_held = false
	_gas_index = -1
	gas = false
	_climb_index = -1
	climb = 0.0
	_free_touches.clear()
	_taps.clear()
	_pad.queue_redraw()


func open_settings(state: Dictionary) -> void:
	release_all()
	# Above everything added to the HUD since (the minimap, the bubbles).
	move_child(settings_panel, -1)
	settings_panel.open(state)


func settings_open() -> bool:
	return settings_panel != null and settings_panel.is_open()


## F's asks (2026-10-30): the full-screen map on the car (map metres, its heading), with the
## notebook's places found (`found`); the "?" marks and the target are the minimap's. Main pauses.
func open_full_map(car_xz: Vector2, car_yaw: float, found: PackedVector2Array) -> void:
	if _minimap == null:
		return
	release_all()
	if full_map == null:
		full_map = FullMap.new()
		full_map.name = "full_map"
		full_map.hud = self
		full_map.data = _map_data
		full_map.outline = _map_outline
		full_map.outside = _map_outside
		full_map.landmarks = map_landmarks
		full_map.bounds = _map_bounds
		_wait_map_art()
		full_map.prepared = _map_art
		_map_art = {}
		full_map.pt = pt
		full_map.safe = _safe
		add_child(full_map)
	move_child(full_map, -1)
	full_map.night = _night
	full_map.unknown = _mini_unknown
	full_map.scene_mark = _scene_mark
	full_map.found = found
	full_map.target = _mini_target
	full_map.garage = _mini_garage
	full_map.garage_colour = _mini_garage_colour
	full_map.final_start = _mini_final  # loop 3h slice 3
	full_map.final_colour = _mini_final_colour
	full_map.target_colour = _mini_target_colour
	full_map.side_spots = _mini_pois
	full_map.side_colours = _mini_poi_colours
	full_map.side_shapes = _mini_poi_shapes
	full_map.set_story(_mini_story, _mini_story_colours, quest_focus, _story_names)
	full_map.set_main_line(_main_at, main_goal[0], main_goal[1])
	full_map.open(car_xz, car_yaw)


## Waits for the full map's art (setup_minimap's worker task), if it's still being made.
func _wait_map_art() -> void:
	if _map_art_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_map_art_task)
		_map_art_task = -1


func _exit_tree() -> void:
	_wait_map_art()


func full_map_open() -> bool:
	return full_map != null and full_map.is_open()


## Phase 0.2: a card (a job's or a call's, a ride's, the full map) is up: ambient chatter waits
## (bubbles.gd cards_up, chatter.gd).
func cards_up() -> bool:
	return bool(_wants.get(_card, false)) or full_map_open()


const _UP_DOWN := [1, -1]


## The helicopter's climb (+1) and sink (-1) pads, stacked where the brake is.
func _climb_centre(direction: int) -> Vector2:
	return _side(Vector2(_safe.end.x - 56.0 * pt, _safe.end.y - (130.0 if direction > 0 else 44.0) * pt))


## Touches above this line belong to the top row (not the stick, not a tap on the city).
func _row_bottom() -> float:
	return (ROW_Y + ROW_H + 4.0) * pt


func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if pad_mode and event is InputEventScreenTouch and event.is_pressed():
		# The gamepad loop: a finger takes over from the pad, pedals and all, on this very touch.
		pad_mode = false
		set_touch_off(_touch_base)
		if _pill.visible:
			_label_pill()
	if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey \
			or event is InputEventJoypadButton) and event.is_pressed():
		input_ms = maxi(1, Time.get_ticks_msec())  # loop 3h slice 4: the ghost finger goes
		if _finger:
			ghost_finger(false)
	if settings_open() or full_map_open():
		return  # the panel's buttons take every touch; nothing steers under it
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		# Three fingers down together toggle the performance overlay.
		if touch.pressed:
			_fingers[touch.index] = Time.get_ticks_msec()
			if _fingers.size() == 3 and Time.get_ticks_msec() - int(_fingers.values().min()) < 400:
				perf_gesture.emit()
		else:
			_fingers.erase(touch.index)
		_track_tap(touch)
		if touch.pressed:
			if _over_panel(touch.position):
				pass  # a button takes it
			elif not touch_off and flying and (touch.position.distance_to(_climb_centre(1)) < PAD_REACH * pt
					or touch.position.distance_to(_climb_centre(-1)) < PAD_REACH * pt):
				_climb_index = touch.index
				climb = 1.0 if touch.position.distance_to(_climb_centre(1)) < touch.position.distance_to(_climb_centre(-1)) else -1.0
			elif _on_horn(touch.position):
				_horn_index = touch.index
				horn_pressed.emit()
			elif _on_nitro(touch.position):
				_nitro_index = touch.index
				nitro_held = true
				nitro_pressed.emit()
				_pad.queue_redraw()
			elif not touch_off and not flying and scheme == CLASSIC and touch.position.distance_to(_gas_centre()) < GAS_REACH * pt:
				_gas_index = touch.index
				gas = true
			elif not touch_off and not flying and touch.position.distance_to(_brake_centre()) < _brake_reach():
				_brake_index = touch.index
				brake = true
			elif _stick_side(touch.position.x, size.x) and touch.position.y > _row_bottom() and _stick_index == -1:
				_stick_index = touch.index
				_stick_origin = touch.position
				_stick_point = touch.position
				stick = Vector2.ZERO
			elif touch.position.y > _row_bottom():
				# The follow-camera loop: a second finger while the stick's finger has hardly moved
				# is a pinch (the first finger always took the stick, so a pinch on the left half
				# drove the car instead of zooming).
				if _stick_index != -1 and stick.length() < PINCH_STICK:
					_free_touches[_stick_index] = _stick_point
					_stick_index = -1
					stick = Vector2.ZERO
				_free_touches[touch.index] = touch.position
				_pinch_distance = _pinch_span()
				_twist_angle = _pinch_angle()
				_twist = 0.0
		else:
			if touch.index == _stick_index:
				_stick_index = -1
				stick = Vector2.ZERO
			if touch.index == _brake_index:
				_brake_index = -1
				brake = false
			if touch.index == _horn_index:
				_horn_index = -1
			if touch.index == _nitro_index:
				_nitro_index = -1
				nitro_held = false
				_pad.queue_redraw()
			if touch.index == _gas_index:
				_gas_index = -1
				gas = false
			if touch.index == _climb_index:
				_climb_index = -1
				climb = 0.0
			_free_touches.erase(touch.index)
			_pinch_distance = _pinch_span()
			_twist_angle = _pinch_angle()
			_twist = 0.0
		_pad.queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _taps.has(drag.index) and drag.position.distance_to(_taps[drag.index][0]) > 10.0 * pt:
			_taps.erase(drag.index)  # a drag (steering, a pinch), not a tap
		if _free_touches.has(drag.index):
			_free_touches[drag.index] = drag.position
			var span := _pinch_span()
			if span > 0.0 and _pinch_distance > 0.0:
				pinched.emit(span / _pinch_distance)
			_pinch_distance = span
			# Loop 2e: two fingers turning together: every TWIST radians, a 90° turn of the view
			# (main.gd only takes it with the fixed camera).
			if _free_touches.size() == 2:
				var angle := _pinch_angle()
				_twist += wrapf(angle - _twist_angle, -PI, PI)
				_twist_angle = angle
				if absf(_twist) >= TWIST:
					rotate_pressed.emit(1 if _twist > 0.0 else -1)
					_twist = 0.0
		if drag.index == _stick_index:
			var radius := STICK_R * pt
			var d := drag.position - _stick_origin
			if scheme == CLASSIC and not flying:
				# The steering strip: left / right only; its centre follows a thumb that runs past the end.
				d.y = 0.0
				if absf(d.x) > radius:
					_stick_origin.x += signf(d.x) * (absf(d.x) - radius)
				_stick_point = Vector2(drag.position.x, _stick_origin.y)
				stick = Vector2((_stick_point.x - _stick_origin.x) / radius, 0.0)
			else:
				if d.length() > radius:
					_stick_origin += d.normalized() * (d.length() - radius)
				_stick_point = drag.position
				stick = (_stick_point - _stick_origin) / radius
			_pad.queue_redraw()
		elif scheme == CLASSIC and not flying and (drag.index == _gas_index or drag.index == _brake_index):
			# A thumb sliding from one pedal to the other switches pedals without lifting.
			var to_gas := drag.position.distance_to(_gas_centre())
			var to_brake := drag.position.distance_to(_brake_centre())
			if to_gas < GAS_REACH * pt and to_gas < to_brake and drag.index == _brake_index:
				_brake_index = -1
				brake = false
				_gas_index = drag.index
				gas = true
				_pad.queue_redraw()
			elif to_brake < _brake_reach() and to_brake < to_gas and drag.index == _gas_index:
				_gas_index = -1
				gas = false
				_brake_index = drag.index
				brake = true
				_pad.queue_redraw()


## A tap: one finger down and up again within 0.35 s and 10 pt, not on a control, the pedals
## or the climb pads, and not part of a pinch. It goes out as `tapped`; the stick it may have
## started never moved, so the car is not steered by it.
func _track_tap(touch: InputEventScreenTouch) -> void:
	# F's asks (2026-10-30): a tap on the minimap (down and up on it within 0.35 s and 10 pt).
	if touch.pressed and _minimap != null and _minimap.get_global_rect().has_point(touch.position) and _map_tap.is_empty():
		_map_tap = [touch.index, touch.position, Time.get_ticks_msec()]
	elif not touch.pressed and not _map_tap.is_empty() and touch.index == int(_map_tap[0]):
		var quick := touch.position.distance_to(_map_tap[1]) <= 10.0 * pt and Time.get_ticks_msec() - int(_map_tap[2]) <= 350
		_map_tap = []
		if quick:
			map_pressed.emit()
	elif touch.pressed:
		_map_tap = []  # a second finger
	if touch.pressed:
		var p := touch.position
		var on_control := _over_panel(p) or p.y < _row_bottom() or (_minimap != null and _minimap.get_global_rect().has_point(p)) \
				or (flying and (p.distance_to(_climb_centre(1)) < PAD_REACH * pt or p.distance_to(_climb_centre(-1)) < PAD_REACH * pt)) \
				or _on_pedals(p)
		if not on_control and _taps.is_empty():
			_taps[touch.index] = [p, Time.get_ticks_msec()]
		else:
			_taps.clear()  # a second finger: a pinch
		return
	if not _taps.has(touch.index):
		return
	var start: Array = _taps[touch.index]
	_taps.erase(touch.index)
	if touch.position.distance_to(start[0]) <= 10.0 * pt and Time.get_ticks_msec() - int(start[1]) <= 350:
		tapped.emit(touch.position)


func _pinch_span() -> float:
	if _free_touches.size() != 2:
		return 0.0
	var points: Array = _free_touches.values()
	return (points[0] as Vector2).distance_to(points[1])


## The angle of the line between the two free fingers (0 with fewer or more).
func _pinch_angle() -> float:
	if _free_touches.size() != 2:
		return 0.0
	var points: Array = _free_touches.values()
	return ((points[1] as Vector2) - (points[0] as Vector2)).angle()


## Polish over English, centred on a pedal (the Polish word smaller if it would not fit).
func _pad_words(c: Vector2, r: float, pl: String, en: String) -> void:
	pl = Lang.pick(pl, en.to_upper())
	en = ""
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB)
	if font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r * 2.0 - 10.0 * pt:
		fs = _px(T_LABEL)
	var es := _px(T_LABEL)
	var w := font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ew := font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, es).x
	_pad.draw_string(font, c + Vector2(-w * 0.5, -1.0 * pt), pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	_pad.draw_string(font, c + Vector2(-ew * 0.5, es * 0.95), en, HORIZONTAL_ALIGNMENT_LEFT, -1, es, SUB)


## Loop 2e: a round control on a solid plate in the card recipe (it used to be a 1-px ring that
## vanished over trees); held, it lights up in the accent.
func _plate(c: Vector2, r: float, held: bool) -> void:
	_pad.draw_circle(c, r, CARD_BG)
	if held:
		_pad.draw_circle(c, r, Color(1, 0.82, 0.25, 0.32))
	_pad.draw_arc(c, r - 0.6 * pt, 0, TAU, 40, ACCENT if held else Color(1, 1, 1, 0.3), 1.3 * pt)


## Loop 3h slice 4: the ghost finger on or off (first10.gd; any touch or key turns it off).
func ghost_finger(on: bool) -> void:
	if on == _finger:
		return
	_finger = on
	_finger_t = 0.0
	_dirty = true  # PT-26: the hint's room (panel_rects) comes and goes with it
	_pad.queue_redraw()


func finger_shown() -> bool:
	return _finger


## The ghost finger's two-line hint for the scheme and input now: {"lines", "at" (the first
## line's baseline), "w"}; both _draw_finger and _draw_finger_classic draw it from here.
func _finger_hint() -> Dictionary:
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var fs2 := _px(T_SUB)
	var lines: Array
	if scheme == CLASSIC:
		lines = ["Przesuń w lewo / prawo i trzymaj GAZ", "Slide left / right to steer, hold GAS to go"]
		if pad_mode:
			lines = [Gamepad.fmt("Lewa gałka: skręt · {rt}: gaz · {lt}: hamulec"), Gamepad.fmt("Left stick steers, {rt} gas, {lt} brake")]
		elif touch_off:
			lines = ["A / D: skręt · W: gaz · S: hamulec", "A / D steer, W gas, S brake"]
	else:
		lines = ["Połóż palec i wskaż, dokąd jechać", "Put a finger down and point the way"]
		if pad_mode:
			lines = ["Lewa gałka: wskaż, dokąd jechać", "Left stick: point the way"]
		elif touch_off:
			lines = ["W A S D albo strzałki: jazda", "W A S D or the arrow keys to drive"]
	var w := maxf(font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x)
	var at: Vector2
	if scheme == CLASSIC:
		# Above the strip's plate (and its thumb), starting at the plate's outer end.
		var strip := _strip_hint_centre()
		at = Vector2(strip.x - 52.0 * pt if not left_handed else strip.x + 52.0 * pt - w, strip.y - 30.0 * pt - fs2 - 6.0 * pt)
	else:
		# Right of the stick's circle, level with it: above it the wallet and the minimap sit, below
		# it the credit line (the first shots had the hint under the wallet).
		at = _finger_origin() + Vector2(STICK_R * pt * 1.25 + 18.0 * pt, -(fs2 + 6.0 * pt) * 0.5)
	at.x = clampf(at.x, _safe.position.x + EDGE * pt, _safe.end.x - EDGE * pt - w)
	return {"lines": lines, "at": at, "w": w}


## PT-26: the box the ghost finger's hint takes on screen (both lines, a little margin).
func finger_hint_rect() -> Rect2:
	var font := ThemeDB.fallback_font
	var h := _finger_hint()
	var at: Vector2 = h["at"]
	var fs := _px(T_BODY)
	var fs2 := _px(T_SUB)
	var top := at.y - font.get_ascent(fs)
	var bottom := at.y + fs2 + 6.0 * pt + font.get_descent(fs2)
	return Rect2(at.x, top, float(h["w"]), bottom - top).grow(4.0 * pt)


## Where the ghost finger presses: the stick's side of the screen (main.gd's --stick spot).
func _finger_origin() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	var x := maxf(size.x * 0.2, _safe.position.x + 70.0 * pt)
	return Vector2(size.x - x if left_handed else x, size.y * 0.68)


## The ghost finger: a fingertip that comes down, drags up and to the right (the way Point steers:
## point where to go) and lifts, every FINGER_LOOP s, with its trail and a two-line hint. With
## --no-touch (a desktop) only the hint, naming the keys. Classic (the default since 2026-11-04)
## has its own: _draw_finger_classic.
func _draw_finger() -> void:
	if scheme == CLASSIC:
		_draw_finger_classic()
		return
	var o := _finger_origin()
	var font := ThemeDB.fallback_font
	var k := fmod(_finger_t, FINGER_LOOP) / FINGER_LOOP
	var hint := _finger_hint()
	var lines: Array = hint["lines"]
	if not (pad_mode or touch_off):
		var press := clampf(k / 0.15, 0.0, 1.0) * clampf((1.0 - k) / 0.15, 0.0, 1.0)
		var drag := clampf((k - 0.2) / 0.55, 0.0, 1.0)
		drag = drag * drag * (3.0 - 2.0 * drag)
		var tip := o + Vector2(0.55, -0.85).normalized() * STICK_R * pt * 1.1 * drag
		_pad.draw_circle(o, STICK_R * pt, Color(CARD_BG, 0.35 * press))
		_pad.draw_arc(o, STICK_R * pt - 0.6 * pt, 0, TAU, 40, Color(1, 1, 1, 0.35 * press), 1.3 * pt)
		if drag > 0.02:
			_pad.draw_line(o, tip, Color(INK, 0.45 * press), 5.0 * pt)
		_pad.draw_circle(tip, 19.0 * pt, Color(OUTLINE, 0.35 * press))
		_pad.draw_circle(tip, 16.0 * pt, Color(INK, 0.8 * press))
	var fs := _px(T_BODY)
	var fs2 := _px(T_SUB)
	var at: Vector2 = hint["at"]
	var outline := _px(3.0)
	_pad.draw_string_outline(font, at, lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE)
	_pad.draw_string(font, at, lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var at2 := at + Vector2(0, fs2 + 6.0 * pt)
	_pad.draw_string_outline(font, at2, lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, outline, OUTLINE)
	_pad.draw_string(font, at2, lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, SUB)


## Classic's ghost finger (2026-11-04, Classic the default): one fingertip holds GAZ down, the
## other slides the steering strip left and right, every FINGER_LOOP s, with the two-line hint
## above the strip. On a pad or a keyboard only the hint, naming the buttons or keys.
func _draw_finger_classic() -> void:
	var font := ThemeDB.fallback_font
	var k := fmod(_finger_t, FINGER_LOOP) / FINGER_LOOP
	var strip := _strip_hint_centre()
	var hint := _finger_hint()
	var lines: Array = hint["lines"]
	if not (pad_mode or touch_off):
		var press := clampf(k / 0.12, 0.0, 1.0) * clampf((1.0 - k) / 0.12, 0.0, 1.0)
		# GAZ: held down for the whole loop (a soft ring pulses round it).
		var gc := _gas_centre()
		_pad.draw_arc(gc, (GAS_R + 6.0 + 4.0 * sin(k * TAU)) * pt, 0, TAU, 40, Color(ACCENT, 0.6 * press), 2.0 * pt)
		_pad.draw_circle(gc, 19.0 * pt, Color(OUTLINE, 0.35 * press))
		_pad.draw_circle(gc, 16.0 * pt, Color(INK, 0.8 * press))
		# The strip: the thumb slides right, back through the middle, left and home.
		var tip := strip + Vector2(sin(k * TAU) * 32.0 * pt, 0)
		_pad.draw_line(strip, tip, Color(INK, 0.45 * press), 5.0 * pt)
		_pad.draw_circle(tip, 19.0 * pt, Color(OUTLINE, 0.35 * press))
		_pad.draw_circle(tip, 16.0 * pt, Color(INK, 0.8 * press))
	var fs := _px(T_BODY)
	var fs2 := _px(T_SUB)
	var at: Vector2 = hint["at"]
	var outline := _px(3.0)
	_pad.draw_string_outline(font, at, lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE)
	_pad.draw_string(font, at, lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var at2 := at + Vector2(0, fs2 + 6.0 * pt)
	_pad.draw_string_outline(font, at2, lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, outline, OUTLINE)
	_pad.draw_string(font, at2, lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, SUB)


## Loop 3h slice 4: the HELI chip shown or hidden (first10.gd: the helicopter waits for the first
## rescue on a fresh save).
func set_vehicle_shown(on: bool) -> void:
	if _vehicle_button.visible == on:
		return
	_vehicle_button.visible = on
	_mark()


func _draw_pad() -> void:
	if _finger and _stick_index == -1 and not flying:
		_draw_finger()
	if _marker_visible:
		# A yellow pointer over the player's car.
		var m := _marker - Vector2(0, 6.0 * pt)
		var tri := PackedVector2Array([m + Vector2(-5.5, -8.5) * pt, m + Vector2(5.5, -8.5) * pt, m])
		var outline := PackedVector2Array([m + Vector2(-7.6, -10.0) * pt, m + Vector2(7.6, -10.0) * pt, m + Vector2(0, 2.2) * pt])
		_pad.draw_colored_polygon(outline, Color("#2a2622"))
		_pad.draw_colored_polygon(tri, ACCENT)
	if _pad_nitro_shown():
		# G13c leftover (2026-11-03): with the pad in use the touch pedals go, but the nitro's
		# tank stays in its place, read-only, with the shoulders that burn it under the disc.
		var nc := _nitro_centre()
		_draw_nitro(nc, false)
		var font := ThemeDB.fallback_font
		var words := Gamepad.fmt("{lb} / {rb}")
		var fs := _px(T_LABEL)
		var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_pad.draw_string(font, nc + Vector2(-w * 0.5, NITRO_R * pt + fs + 2.0 * pt), words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SUB)
	if touch_off:
		return  # desktop: --no-touch, nothing below is drawn
	if _stick_index != -1 and scheme == CLASSIC and not flying:
		# The steering strip on its plate: arrows at the ends and the thumb's knob.
		var half := STICK_R * pt
		var o := _stick_origin
		_strip_plate.set_corner_radius_all(roundi(16.0 * pt))
		_pad.draw_style_box(_strip_plate, Rect2(o - Vector2(half + 16.0 * pt, 16.0 * pt), Vector2(half * 2.0 + 32.0 * pt, 32.0 * pt)))
		for side in [-1.0, 1.0]:
			var tip := o + Vector2(side * (half + 8.0 * pt), 0)
			_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 7, -5.5) * pt, tip + Vector2(-side * 7, 5.5) * pt]), SUB)
		_pad.draw_circle(_stick_point, 13.0 * pt, INK)
	elif _stick_index != -1:
		_pad.draw_circle(_stick_origin, STICK_R * pt, Color(CARD_BG, 0.72))
		_pad.draw_arc(_stick_origin, STICK_R * pt - 0.6 * pt, 0, TAU, 40, Color(1, 1, 1, 0.3), 1.3 * pt)
		_pad.draw_circle(_stick_point, 16.0 * pt, Color(INK, 0.9))
	if flying:
		for direction in _UP_DOWN:
			var c := _climb_centre(direction)
			_plate(c, PAD_R * pt, climb == float(direction))
			var s: float = 9.0 * pt * direction
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.6), c + Vector2(-s, s * 0.6)]), INK)
		return
	if _pedals_hidden:
		return  # loop 3g-1: the pull-over holds the car
	var bc := _brake_centre()
	var br := (CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) * pt
	_plate(bc, br, brake)
	_pad_words(bc, br, "HAMULEC", "brake")
	_draw_horn(_horn_centre(), _horn_index != -1)
	if nitro_owned:
		_draw_nitro(_nitro_centre(), nitro_held)
	if scheme == CLASSIC:
		var gc := _gas_centre()
		_plate(gc, GAS_R * pt, gas)
		_pad_words(gc, GAS_R * pt, "GAZ", "gas")
		if _stick_index == -1:
			# Where the steering strip lives, on a small plate, until a thumb comes down.
			var o := _strip_hint_centre()
			_strip_plate.set_corner_radius_all(roundi(12.0 * pt))
			_pad.draw_style_box(_strip_plate, Rect2(o - Vector2(52, 12) * pt, Vector2(104, 24) * pt))
			_pad.draw_line(o - Vector2(30, 0) * pt, o + Vector2(30, 0) * pt, SUB, 1.6 * pt)
			for side in [-1.0, 1.0]:
				var tip := o + Vector2(side * 44, 0) * pt
				_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 7.5, -6) * pt, tip + Vector2(-side * 7.5, 6) * pt]), INK)


## The night-buses loop: the horn on its plate: a little horn's bell and two sound arcs.
func _draw_horn(c: Vector2, held: bool) -> void:
	# One triangle array for the plate, its rim and the icon: one 2D draw call (six separate
	# primitives cost six).
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var r := HORN_R * pt
	_horn_disc(pts, cols, idx, c, r, CARD_BG)
	if held:
		_horn_disc(pts, cols, idx, c, r, Color(1, 0.82, 0.25, 0.32))
	_horn_ring(pts, cols, idx, c, r - 1.25 * pt, r, 0.0, TAU, 40, ACCENT if held else Color(1, 1, 1, 0.3))
	var ink := ACCENT if held else INK
	var o := c + Vector2(-3.0, 0.0) * pt
	_horn_fan(pts, cols, idx, [o + Vector2(-7.0, -2.2) * pt, o + Vector2(-2.0, -2.2) * pt, o + Vector2(-2.0, 2.2) * pt,
			o + Vector2(-7.0, 2.2) * pt], ink)
	_horn_fan(pts, cols, idx, [o + Vector2(-2.5, -2.2) * pt, o + Vector2(5.0, -7.0) * pt, o + Vector2(5.0, 7.0) * pt,
			o + Vector2(-2.5, 2.2) * pt], ink)
	for k in 2:
		var rr := (4.5 + 4.0 * k) * pt
		_horn_ring(pts, cols, idx, o + Vector2(6.0, 0.0) * pt, rr - 0.7 * pt, rr + 0.7 * pt, -0.7, 0.7, 8, ink)
	RenderingServer.canvas_item_add_triangle_array(_pad.get_canvas_item(), idx, pts, cols)


## G13: the nitro on its plate: a lightning bolt, in a ring that is the tank (orange while it can
## burn, grey while it refills, bright while held), one triangle array like the horn's.
func _draw_nitro(c: Vector2, held: bool) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var r := NITRO_R * pt
	var ready := nitro_charge >= 0.25
	var hot := Color(1.0, 0.55, 0.12) if ready else Color(0.6, 0.6, 0.62)
	_horn_disc(pts, cols, idx, c, r, CARD_BG)
	if held and nitro_charge > 0.0:
		_horn_disc(pts, cols, idx, c, r, Color(1.0, 0.55, 0.12, 0.32))
	_horn_ring(pts, cols, idx, c, r - 3.0 * pt, r, 0.0, TAU, 40, Color(1, 1, 1, 0.14))
	if nitro_charge > 0.01:
		_horn_ring(pts, cols, idx, c, r - 3.0 * pt, r, -PI * 0.5, -PI * 0.5 + TAU * nitro_charge, maxi(3, roundi(40.0 * nitro_charge)), hot)
	var ink := ACCENT if held and nitro_charge > 0.0 else (INK if ready else SUB)
	_horn_fan(pts, cols, idx, [c + Vector2(3, -10) * pt, c + Vector2(-5, 2) * pt, c + Vector2(1, 2) * pt], ink)
	_horn_fan(pts, cols, idx, [c + Vector2(-3, 10) * pt, c + Vector2(5, -2) * pt, c + Vector2(-1, -2) * pt], ink)
	RenderingServer.canvas_item_add_triangle_array(_pad.get_canvas_item(), idx, pts, cols)


## The night-buses loop: a convex polygon `poly` as a fan into a triangle array.
static func _horn_fan(pts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array, poly: Array, col: Color) -> void:
	var b := pts.size()
	for p: Vector2 in poly:
		pts.append(p)
		cols.append(col)
	for k in range(1, poly.size() - 1):
		idx.append_array([b, b + k, b + k + 1])


## The night-buses loop: a disc into a triangle array.
static func _horn_disc(pts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array, c: Vector2, r: float, col: Color) -> void:
	var poly := []
	for k in 32:
		poly.append(c + Vector2.from_angle(TAU * k / 32.0) * r)
	_horn_fan(pts, cols, idx, poly, col)


## The night-buses loop: a ring's arc (radii r0-r1, angles a0-a1, `n` pieces) into a triangle array.
static func _horn_ring(pts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array, c: Vector2, r0: float, r1: float,
		a0: float, a1: float, n: int, col: Color) -> void:
	var b := pts.size()
	for k in n + 1:
		var d := Vector2.from_angle(lerpf(a0, a1, float(k) / n))
		pts.append_array([c + d * r0, c + d * r1])
		cols.append_array([col, col])
	for k in n:
		var i := b + k * 2
		idx.append_array([i, i + 1, i + 3, i, i + 3, i + 2])


## Loop 2a: the gear, drawn like the HUD's buttons (a dark disc with a light gear).
func _draw_gear() -> void:
	var c := Vector2.ONE * TOUCH * 0.5 * pt
	var held := _gear.button_pressed or _gear.is_pressed()
	_gear.draw_circle(c, 20.0 * pt, CARD_BG)
	_gear.draw_arc(c, 20.0 * pt - 0.5 * pt, 0, TAU, 40, ACCENT if held else Color(1, 1, 1, 0.22), maxf(1.0, 0.6 * pt))
	var teeth := 8
	var pts := PackedVector2Array()
	for k in teeth * 4:
		var a := TAU * (k / 4.0) / teeth - PI / teeth * 0.5
		var r := (11.0 if k % 4 == 1 or k % 4 == 2 else 8.0) * pt
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_gear.draw_colored_polygon(pts, ACCENT if held else INK)
	_gear.draw_circle(c, 3.4 * pt, Color(CARD_BG, 1.0))


## On screen: a bobbing pointer over the target with the distance. Off screen: an arrow on the
## safe area's edge (below the top row, clear of the status panel), pointing the way.
func _draw_target() -> void:
	if not _target_visible:
		return
	var o := _overlay
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var w := font.get_string_size(_target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var inside := _target_inside()
	if inside.size.x <= 0.0 or inside.size.y <= 0.0:
		return  # no room to point (a headless run's tiny window)
	var outline := _px(2.5)
	if inside.has_point(_target_at):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 2.0 * pt
		var m := _target_at - Vector2(0, 16.0 * pt + bob)
		var at := m + Vector2(-w * 0.5, -15.0 * pt)
		# PT-10: under a bubble or the banner the pointer goes faint, so their words read clean.
		var box := Rect2(at - Vector2(0, fs), Vector2(w, fs)).merge(Rect2(m - Vector2(8, 11) * pt, Vector2(16, 14) * pt))
		var fade := 0.3 if _blocks(true).any(func(r: Rect2) -> bool: return r.intersects(box)) else 1.0
		var ink := Color(OUTLINE, OUTLINE.a * fade)
		var tint := Color(_target_colour, _target_colour.a * fade)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-8, -11) * pt, m + Vector2(8, -11) * pt, m + Vector2(0, 2.5) * pt]), ink)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-5.5, -9.5) * pt, m + Vector2(5.5, -9.5) * pt, m]), tint)
		o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, ink)
		o.draw_string(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tint)
		return
	var e := edge_pointer()
	if e.is_empty():
		return
	var tip: Vector2 = e["tip"]
	var dir: Vector2 = e["dir"]
	var side := Vector2(-dir.y, dir.x)
	var a := EDGE_ARROW * pt
	o.draw_colored_polygon(PackedVector2Array([tip + dir * 2.5 * pt, tip - dir * (a + 2.5 * pt) + side * (a * 0.7 + 2.0 * pt),
			tip - dir * (a + 2.5 * pt) - side * (a * 0.7 + 2.0 * pt)]), OUTLINE)
	o.draw_colored_polygon(PackedVector2Array([tip, tip - dir * a + side * a * 0.6, tip - dir * a - side * a * 0.6]), _target_colour)
	var label: Rect2 = e["label"]
	var at := Vector2(label.position.x, label.get_center().y + fs * 0.35)
	o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE)
	o.draw_string(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _target_colour)


## The edge arrow's length (points).
const EDGE_ARROW := 13.5


## Where the target pointer may stand: the safe area inset 28 pt, below the top row and the
## status panel.
func _target_inside() -> Rect2:
	var margin := 28.0 * pt
	var top := _row_bottom() + 24.0 * pt
	if _status.visible:
		# Keep the edge arrow off the status panel in the top right.
		top = maxf(top, _status.get_global_rect().end.y + 8.0 * pt)
	return Rect2(_safe.position.x + margin, top, _safe.size.x - margin * 2.0, _safe.end.y - margin - top)


## The edge arrow for an off-screen target, as drawn (also for tools/check_hud.gd): {"tip",
## "dir" (the way it points), "label" (the distance's box)}; empty while the target is on screen.
func edge_pointer() -> Dictionary:
	var inside := _target_inside()
	if not _target_visible or inside.size.x <= 0.0 or inside.size.y <= 0.0 or inside.has_point(_target_at):
		return {}
	var centre := inside.get_center()
	var d := _target_at - centre
	if d.length() < 1.0:
		return {}
	var fs := _px(T_BODY)
	var w := ThemeDB.fallback_font.get_string_size(_target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h := float(fs)
	var a := EDGE_ARROW * pt
	# Scale the line from the centre so it ends on the inset screen edge.
	var t := minf((inside.size.x * 0.5) / maxf(absf(d.x), 0.001), (inside.size.y * 0.5) / maxf(absf(d.y), 0.001))
	var tip := _edge_spot(centre + d * t, inside, w, h, a)
	var dir := (_target_at - tip).normalized()
	var c := _edge_label_centre(tip, dir, w, h, a)
	return {"tip": tip, "dir": dir, "label": Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))}


## PT-10: where the edge arrow's distance sits: behind the arrow by the arrow's length, a gap,
## and the label's own half-extent along the arrow, so the number never runs into the arrow.
func _edge_label_centre(tip: Vector2, dir: Vector2, w: float, h: float, a: float) -> Vector2:
	return tip - dir * (a + 2.5 * pt + 6.0 * pt + absf(dir.x) * w * 0.5 + absf(dir.y) * h * 0.5)


## PT-10: the rects the target pointer keeps clear of: the speech bubbles and the floating
## panels on screen (only the banner, with `banner_only`, for the pointer over the target).
func _blocks(banner_only: bool) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c: Control in _placed:
		if c.visible and c != _status and (not banner_only or c == _banner):
			out.append(_placed[c])
	if speech != null and "rects" in speech:
		# A bubble's tail reaches past its card (bubbles.gd TAIL).
		for r: Rect2 in speech.rects:
			out.append(r.grow(10.0 * pt))
	if not banner_only:
		# The edge arrow keeps off the fixed controls too: pointing up-left it hid under the
		# minimap and the wallet (the main line's arrow to a rival in the west, 2026-11-03).
		for c: Control in [_zoom_out_button, _zoom_in_button, _minimap, _wallet, _koguty]:
			if c != null and c.visible:
				out.append(Rect2(c.position, c.size))
		out.append_array(_pedal_rects())
	return out


## The box the edge arrow and its distance take, for the arrow's tip at `tip`.
func _edge_box(tip: Vector2, w: float, h: float, a: float) -> Rect2:
	var dir := (_target_at - tip).normalized()
	var c := _edge_label_centre(tip, dir, w, h, a)
	return Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)).merge(Rect2(tip, Vector2.ZERO).grow(a + 3.0 * pt))


## PT-10: the edge arrow's tip, moved along the edge of `inside` to the nearest spot where the
## arrow and its distance are clear of the floating panels (cards, banner, toast, ticker) and the
## speech bubbles. PT-27 (2026-11-07): with no clear spot within reach it no longer stays where it
## pointed (a job's long "KEBAB 1948 m" sat on BRAKE): it takes the spot that covers least, and
## never one on a pedal or button the thumb needs while another spot keeps off them.
func _edge_spot(tip: Vector2, inside: Rect2, w: float, h: float, a: float) -> Vector2:
	var blocks := _blocks(false)
	if blocks.is_empty():
		return tip
	var hard := _pedal_rects()
	# Along the left and right edges the tip moves up and down; along the top and bottom, sideways.
	var along := Vector2(0, 1) if absf(tip.x - inside.position.x) < 0.5 or absf(tip.x - inside.end.x) < 0.5 else Vector2(1, 0)
	var step := 12.0 * pt
	var best := tip
	var best_cost := INF
	for k in 25:
		for sgn: float in ([1.0] if k == 0 else [1.0, -1.0]):
			var p := tip + along * step * k * sgn
			if not inside.grow(0.5).has_point(p):
				continue
			var box := _edge_box(p, w, h, a)
			var cost := 0.0
			for r in blocks:
				if r.intersects(box):
					cost += r.intersection(box).get_area() + 1.0
			if cost == 0.0:
				return p
			for r in hard:
				if r.intersects(box):
					cost += 1e9
			# Nearer spots win a tie, so the arrow still points roughly the right way.
			cost += k * 0.01
			if cost < best_cost:
				best_cost = cost
				best = p
	return best


# --- loop 3g-1: the police -----------------------------------------------------------------------

## The koguty plate's width (points): three domes.
const KOGUTY_W := 74.0


func _build_police() -> void:
	var style := _panel_box(8.0, 6.0)
	style.content_margin_left = 14.0 * pt
	style.content_margin_right = 14.0 * pt
	style.border_color = POLICE_BLUE
	style.set_border_width_all(0)
	style.border_width_left = roundi(4.0 * pt)
	_police_pill = PanelContainer.new()
	_police_pill.name = "police"
	_police_pill.add_theme_stylebox_override("panel", style)
	_police_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_police_pill.add_child(rows)
	_police_pl = _label(T_BODY, INK)
	_police_pl.name = "police_pl"
	_police_pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_police_pl)
	_police_en = _label(T_SUB, SUB)
	_police_en.name = "police_en"
	_police_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_police_en)
	add_child(_police_pill)
	# The koguty's place beside the wallet (the layout keeps it); the overlay draws them.
	_koguty = Control.new()
	_koguty.name = "koguty"
	_koguty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_koguty.visible = false
	add_child(_koguty)


## The roosters: `lit` of three (the chase's level) in `mode` 1 (a chase), 2 (searching: grey,
## blinking), 3 (a warning: the first one's outline blinks for 2 s), or 0 (hidden).
func set_koguty(lit: int, mode: int) -> void:
	if lit == _koguty_lit and mode == _koguty_mode:
		return
	if mode != _koguty_mode:
		_koguty_t = 0.0
	_koguty_lit = lit
	_koguty_mode = mode
	var show := mode != 0
	if show != _koguty.visible:
		_koguty.visible = show
		_mark()
	_police_fx.queue_redraw()


## The koguty, drawn by the overlay (one draw call with it): the plate in the card recipe, three
## domes (lit blue and red in turns, grey and blinking while searching, an outline otherwise;
## a warning blinks the first one's outline blue and red).
func _koguty_tris() -> void:
	var at := _koguty.position
	var size := _koguty.size
	var edge := maxf(1.0, roundf(pt * 0.5))
	_tri_round_rect(Rect2(at, size), 9.0 * pt, CARD_EDGE)
	_tri_round_rect(Rect2(at, size).grow(-edge), 9.0 * pt - edge, CARD_BG)
	var blink_on := fmod(_koguty_t, 0.5) < 0.3
	var flip := int(Time.get_ticks_msec() / 250) % 2 == 0
	for k in 3:
		var c := at + Vector2((14.0 + k * 23.0) * pt, size.y * 0.5 + 5.0 * pt)
		var r := 8.0 * pt
		var lit := k < _koguty_lit and _koguty_mode == 1
		var grey := k < _koguty_lit and _koguty_mode == 2
		if lit:
			# Blue and red halves taking turns, like the light bar.
			_tri_fan(c, r, PI, PI * 1.5, LENS_BLUE if flip else LENS_BLUE.darkened(0.5))
			_tri_fan(c, r, PI * 1.5, TAU, LENS_RED.darkened(0.5) if flip else LENS_RED)
		elif grey:
			_tri_fan(c, r, PI, TAU, Color(0.62, 0.62, 0.66, 0.9 if blink_on else 0.35))
		else:
			var outline := Color(1, 1, 1, 0.3)
			if _koguty_mode == 3 and k == 0:
				outline = LENS_BLUE if blink_on else LENS_RED
			_tri_ring(c, r - maxf(1.0, 1.5 * pt), r, PI, TAU, outline)
		var base := Color(0.75, 0.75, 0.78) if lit or grey else Color(1, 1, 1, 0.25)
		_tri_rect(Rect2(c + Vector2(-r - 1.5 * pt, 0.0), Vector2(r * 2.0 + 3.0 * pt, 3.0 * pt)), base)


## The police pill at the top centre (Polish over English); empty words hide it.
func police_pill(pl: String, en: String) -> void:
	pl = Lang.pick(pl, en)
	en = ""
	if pl == "":
		_show(_police_pill, false)
		return
	if _police_pl.text != pl or _police_en.text != en:
		_police_pl.text = pl
		_police_en.text = en
		_police_en.visible = en != ""
		_police_pill.reset_size()
	_show(_police_pill, true)


## The overlay: the blue-red edge breath at `breath` (0..1; at most 10 % opacity at the very
## edge), the chasers' screen points (HUD pixels; one off screen gets a rooster pinned to the
## edge, towards it), and the lizak paddle over a trap's officer (a screen point, or INF).
func police_fx(breath: float, chasers: PackedVector2Array, lizak: Vector2) -> void:
	var was := _breath > 0.0 or not _edge_roosters.is_empty() or _lizak != Vector2.INF
	_breath = breath
	_edge_roosters = chasers
	_lizak = lizak
	if was or _breath > 0.0 or not chasers.is_empty() or lizak != Vector2.INF:
		_police_fx.queue_redraw()


func _draw_police_fx() -> void:
	var o := _police_fx
	var s := _screen
	_tri_begin()
	if _breath > 0.0:
		# A band at each edge, blue on the left and top, red on the right and bottom, breathing in
		# turns once a second; 10 % at the edge, gone 9 % of the height into the screen.
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU)
		var a := 0.1 * _breath
		var band := s.y * 0.09
		var blue := Color(LENS_BLUE, a * pulse)
		var red := Color(LENS_RED, a * (1.0 - pulse))
		var clear_b := Color(LENS_BLUE, 0.0)
		var clear_r := Color(LENS_RED, 0.0)
		var tl := Vector2.ZERO
		var tr := Vector2(s.x, 0.0)
		var br := s
		var bl := Vector2(0.0, s.y)
		var itl := Vector2(band, band)
		var itr := Vector2(s.x - band, band)
		var ibr := s - Vector2(band, band)
		var ibl := Vector2(band, s.y - band)
		_tri_quad(tl, itl, ibl, bl, [blue, clear_b, clear_b, blue])
		_tri_quad(tl, tr, itr, itl, [blue, blue, clear_b, clear_b])
		_tri_quad(tr, br, ibr, itr, [red, red, clear_r, clear_r])
		_tri_quad(bl, ibl, ibr, br, [red, clear_r, clear_r, red])
	# The koguty over the breath (the layout keeps their place clear of every panel).
	if _koguty.visible:
		_koguty_tris()
	var inside := Rect2(_safe.position.x + 34.0 * pt, _top_y + 20.0 * pt, _safe.size.x - 68.0 * pt, _safe.end.y - 54.0 * pt - _top_y)
	var flip := int(Time.get_ticks_msec() / 250) % 2 == 0
	for p in _edge_roosters:
		if inside.size.x <= 0.0 or inside.size.y <= 0.0 or inside.has_point(p):
			continue
		# A chaser off screen: a rooster on a dark disc at the edge, towards it.
		var centre := inside.get_center()
		var d := p - centre
		var k := minf((inside.size.x * 0.5) / maxf(absf(d.x), 0.001), (inside.size.y * 0.5) / maxf(absf(d.y), 0.001))
		var at := centre + d * k
		_tri_fan(at, 15.0 * pt, 0.0, TAU, CARD_BG)
		_tri_ring(at, 13.0 * pt, 15.0 * pt, 0.0, TAU, LENS_BLUE if flip else LENS_RED)
		_tri_fan(at + Vector2(0, 4.0 * pt), 8.0 * pt, PI, TAU, LENS_BLUE if flip else LENS_RED)
	if _lizak != Vector2.INF:
		# The lizak (the round stop paddle) over the officer, bobbing 2 pt at 2 Hz.
		var bob := sin(Time.get_ticks_msec() * 0.001 * TAU * 2.0) * 2.0 * pt
		var c := _lizak + Vector2(0, -26.0 * pt + bob)
		_tri_rect(Rect2(c + Vector2(-1.5, 6.0) * pt, Vector2(3.0, 12.0) * pt), Color("#2a2622"))
		_tri_fan(c, 9.0 * pt, 0.0, TAU, OUTLINE)
		_tri_fan(c, 8.0 * pt, 0.0, TAU, LENS_RED)
		_tri_fan(c, 5.0 * pt, 0.0, TAU, INK)
	_tri_flush(o)
	if _breath > 0.0 or not _edge_roosters.is_empty() or _lizak != Vector2.INF or _koguty_mode == 1:
		o.queue_redraw()


## Loop 3g-1: shapes gathered as triangles and drawn with one call a surface (the minimap's marks,
## the koguty and the police overlay): each draw_* call was a draw call of its own (+33 in the 2D
## pass in a chase; police.md section 12 allows +4). Kept cheap for GDScript: plain appends, the
## circle's points from a table, the minimap's rim built once, the index list reused.
var _tri_pts := PackedVector2Array()
var _tri_cols := PackedColorArray()
var _tri_idx := PackedInt32Array()
## A unit circle in TRI_SEGMENTS steps (screen y down: index 0 points right, a quarter is down).
const TRI_SEGMENTS := 24
var _unit := PackedVector2Array()
var _rim_key := []
var _rim_pts := PackedVector2Array()
var _rim_cols := PackedColorArray()


func _tri_begin() -> void:
	_tri_pts.clear()
	_tri_cols.clear()
	if _unit.is_empty():
		for k in TRI_SEGMENTS + 1:
			_unit.append(Vector2(cos(TAU * k / TRI_SEGMENTS), sin(TAU * k / TRI_SEGMENTS)))


func _tri(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
	_tri_pts.append(a)
	_tri_pts.append(b)
	_tri_pts.append(c)
	_tri_cols.append(ca)
	_tri_cols.append(cb)
	_tri_cols.append(cc)


## A quad a, b, c, d (in order round it), a colour at each corner.
func _tri_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, cols: Array) -> void:
	_tri(a, b, c, cols[0], cols[1], cols[2])
	_tri(a, c, d, cols[0], cols[2], cols[3])


func _tri_rect(r: Rect2, col: Color) -> void:
	var b := Vector2(r.end.x, r.position.y)
	var d := Vector2(r.position.x, r.end.y)
	_tri(r.position, b, r.end, col, col, col)
	_tri(r.position, r.end, d, col, col, col)


## A rectangle with round corners of `radius`.
func _tri_round_rect(r: Rect2, radius: float, col: Color) -> void:
	var k := minf(radius, minf(r.size.x, r.size.y) * 0.5)
	_tri_rect(r.grow_individual(0.0, -k, 0.0, -k), col)
	_tri_rect(Rect2(r.position + Vector2(k, 0.0), Vector2(r.size.x - 2.0 * k, k)), col)
	_tri_rect(Rect2(Vector2(r.position.x + k, r.end.y - k), Vector2(r.size.x - 2.0 * k, k)), col)
	_tri_fan(r.position + Vector2(k, k), k, PI, PI * 1.5, col)
	_tri_fan(Vector2(r.end.x - k, r.position.y + k), k, PI * 1.5, TAU, col)
	_tri_fan(r.end - Vector2(k, k), k, 0.0, PI * 0.5, col)
	_tri_fan(Vector2(r.position.x + k, r.end.y - k), k, PI * 0.5, PI, col)


## A disc's slice from angle a0 to a1 (radians, multiples of a quarter; screen y down, so PI..TAU
## is the top half), in the table's steps.
func _tri_fan(c: Vector2, r: float, a0: float, a1: float, col: Color) -> void:
	var k0 := roundi(a0 / TAU * TRI_SEGMENTS)
	var k1 := roundi(a1 / TAU * TRI_SEGMENTS)
	for k in range(k0, k1):
		_tri(c, c + _unit[k] * r, c + _unit[k + 1] * r, col, col, col)


## A ring between radii r0 and r1 from angle a0 to a1 (as _tri_fan).
func _tri_ring(c: Vector2, r0: float, r1: float, a0: float, a1: float, col: Color) -> void:
	var k0 := roundi(a0 / TAU * TRI_SEGMENTS)
	var k1 := roundi(a1 / TAU * TRI_SEGMENTS)
	for k in range(k0, k1):
		var u := _unit[k]
		var v := _unit[k + 1]
		_tri(c + u * r0, c + u * r1, c + v * r1, col, col, col)
		_tri(c + u * r0, c + v * r1, c + v * r0, col, col, col)


## The minimap's rim: a smooth ring of 64 steps, built when its size or colour changes.
func _tri_rim(c: Vector2, r0: float, r1: float, col: Color) -> void:
	var key := [c, r0, r1, col]
	if key != _rim_key:
		_rim_key = key
		_rim_pts.clear()
		_rim_cols.clear()
		for k in 64:
			var u := Vector2(cos(TAU * k / 64.0), sin(TAU * k / 64.0))
			var v := Vector2(cos(TAU * (k + 1) / 64.0), sin(TAU * (k + 1) / 64.0))
			_rim_pts.append_array(PackedVector2Array([c + u * r0, c + u * r1, c + v * r1, c + u * r0, c + v * r1, c + v * r0]))
		_rim_cols.resize(_rim_pts.size())
		_rim_cols.fill(col)
	_tri_pts.append_array(_rim_pts)
	_tri_cols.append_array(_rim_cols)


## Draws what was gathered on `item` with one call.
func _tri_flush(item: CanvasItem) -> void:
	var n := _tri_pts.size()
	if n == 0:
		return
	if _tri_idx.size() < n:
		for i in range(_tri_idx.size(), n + 256):
			_tri_idx.append(i)
	RenderingServer.canvas_item_add_triangle_array(item.get_canvas_item(), _tri_idx.slice(0, n), _tri_pts, _tri_cols)


## Chasers (map x, z) and the speed traps the player knows of, on the minimap.
func set_police_marks(chasers: PackedVector2Array, traps: PackedVector2Array) -> void:
	_police_marks = chasers
	_trap_marks = traps


## The crash scene's spot (map x, z) on the minimap and the full map, or Vector2.INF for none.
func set_scene_mark(at: Vector2) -> void:
	_scene_mark = at


## Lays out a panel another script made (the pull-over card) like the HUD's own passing panels,
## at the top or the bottom centre (`spot`); the bubbles keep clear of it.
func add_panel(c: Control, spot: String) -> void:
	_panel_spots[c] = spot
	c.visible = false
	add_child(c)
	_floating.push_front(c)
	_wants[c] = false


## Loop 3g-1: the car's pedals off the screen (and their room free) while the car is held.
func set_pedals_hidden(on: bool) -> void:
	if on != _pedals_hidden:
		_pedals_hidden = on
		brake = false
		_brake_index = -1
		gas = false
		_gas_index = -1
		_pad.queue_redraw()
		_mark()


# --- desktop: --no-touch ---------------------------------------------------------------------
## Desktop: --no-touch (trailer loop): the touch-only controls off the screen and their room
## free (see `touch_off`); main.gd calls it once after building the HUD.
func set_touch_off(on: bool) -> void:
	touch_off = on
	_pad.queue_redraw()
	_mark()


# --- the gamepad loop ------------------------------------------------------------------------
## True while the pad was used last (main.gd `_note_pad`): the touch pedals and pads are off the
## screen as with --no-touch, and the hints speak of the pad. A finger brings them back at once.
var pad_mode := false
## --no-touch's own setting, so leaving pad mode puts back what the run asked for.
var _touch_base := false


func set_pad_mode(on: bool, touch_base: bool) -> void:
	_touch_base = touch_base
	if on == pad_mode:
		return
	pad_mode = on
	set_touch_off(on or touch_base)
	if _pill.visible:
		_label_pill()
# --- end desktop: --no-touch -----------------------------------------------------------------


func show_panel(c: Control, on: bool) -> void:
	_show(c, on)
	if on:
		c.reset_size()
		_mark()
