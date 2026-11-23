extends RefCounted
## Gamepad loop (2026-11-01, F asked "can it work with the pad?"): Xbox, PlayStation and MFi
## controllers through Godot's joypad input (SDL's mapping on the Mac and Linux, the Game
## Controller framework on iOS: the same button indices for all three). Touch and the keys stay
## as they were; the pad is a third way in, read next to them in main.gd `_read_input`.
##
## Driving follows the scheme (drive_controls.gd), like the touch stick:
##   left stick   POINT / FIXED: point the way (pushed further = more gas); CLASSIC: steer
##   RT           gas (CLASSIC); the helicopter climbs
##   LT or B      brake / reverse; the helicopter sinks (LT)
## Buttons (one press, `command`), named after the keys they stand for:
##   A primary (M)     X secondary (K)     Y car / helicopter (H)
##   LB or RB pressed: one nitro bottle (Shift)      right stick flicked left / right: turn the view (Q / E)
##   R3 follow camera (C)     L3 horn (B)
##   D-pad up / down zoom in / out (= / -)  D-pad right radio (R)     D-pad left flash lights (L)
##   Back / Share / View: the full map      Start / Options / Menu: Settings (Esc)
## Menus: Godot's own ui_up..ui_right carry the D-pad and the left stick; `install` adds A to
## ui_accept and B to ui_cancel. The settings card and the full map close on B, Start and Back.
##
## Pure functions over InputEvents and an action strength table so game/tools/check_gamepad.gd
## can drive them with synthetic events (no controller in CI).
##
## Glyphs and rumble (2026-11-02, the gamepad gaps in BACKLOG): the hints name the buttons the way
## the pad in the player's hands prints them. `note` reads the pad's name (Input.get_joy_name)
## and sorts it into a family: PlayStation (× / Circle / Square / Triangle, R2 / L2, R1 / L1),
## Nintendo (the labels sit swapped: the bottom button reads B, the right one A; ZR / ZL) or Xbox,
## which also covers MFi and unknown pads (the labels the button indices are named after). Hint
## text carries tokens, `fmt("Hold {a} to jump")`, filled per family and language by `key`.
## The HUD's font (Open Sans) has × but no ○ □ △, so the other PlayStation faces are words.
## Haptics.buzz sends the buzz to the pad (Input.start_joy_vibration) instead of the phone while
## the pad is in use: the hands are on the pad, the phone may sit on a stand.

const Lang := preload("res://scripts/lang.gd")

## The left stick's dead zone (a share of its throw; worn sticks rest up to ~0.15 off centre).
const DEAD := 0.2
## A trigger counts as pressed past this share of its travel.
const TRIGGER := 0.3

## The actions this adds to the InputMap (`install`), and what each is bound to.
const STICK_ACTIONS := {
	"pad_left": [JOY_AXIS_LEFT_X, -1.0],
	"pad_right": [JOY_AXIS_LEFT_X, 1.0],
	"pad_up": [JOY_AXIS_LEFT_Y, -1.0],
	"pad_down": [JOY_AXIS_LEFT_Y, 1.0],
}
const GAS := "pad_gas"
const BRAKE := "pad_brake"
## G13 leftovers (2026-11-02): the nitro is a hold, so it needs a button no press-command uses;
## the shoulders were the view's turn, which moved to the right stick (the usual camera stick).
const NITRO := "pad_nitro"
## The right stick turns the view one step per flick: past FLICK of its throw, armed again once it
## is back under FLICK_REST (so a held stick turns once, not every frame).
const FLICK := 0.6
const FLICK_REST := 0.3

## One press, one command (main.gd `_pad_command`).
const BUTTONS := {
	JOY_BUTTON_A: "primary",
	JOY_BUTTON_X: "secondary",
	JOY_BUTTON_Y: "vehicle",
	JOY_BUTTON_RIGHT_STICK: "follow",
	JOY_BUTTON_LEFT_STICK: "horn",
	JOY_BUTTON_DPAD_UP: "zoom_in",
	JOY_BUTTON_DPAD_DOWN: "zoom_out",
	JOY_BUTTON_DPAD_RIGHT: "radio",
	JOY_BUTTON_DPAD_LEFT: "flash",
	JOY_BUTTON_BACK: "map",
	JOY_BUTTON_START: "settings",
}

## The order of the last joypad event and the last touch / key / click (0: none yet; a counter,
## not the clock, so two in the same millisecond still have an order). `in_use` compares them.
static var _seq := 0
static var last_pad := 0
static var last_other := 0
## The right stick is back near the centre, so the next flick turns the view.
static var _flick_armed := true

## The pad families whose button faces differ (`family_of`).
const XBOX := "xbox"
const PLAYSTATION := "playstation"
const NINTENDO := "nintendo"
## Words in the pad's name that give its family away (lower case), checked in this order. iOS's
## Game Controller framework names Sony pads "DualSense Wireless Controller" / "DUALSHOCK 4 ...",
## SDL's mapping "PS4 Controller", "PS5 Controller", "Sony ..."; Nintendo's "Pro Controller",
## "Joy-Con", "Nintendo Switch ...".
const FAMILY_WORDS := [
	[PLAYSTATION, ["dualsense", "dualshock", "playstation", "sony", "ps3", "ps4", "ps5"]],
	[NINTENDO, ["nintendo", "switch", "pro controller", "joy-con", "joycon"]],
]
## Each button token's face per family: one text, or [Polish, English] for a word.
const FACES := {
	XBOX: {
		"a": "A", "b": "B", "x": "X", "y": "Y", "rt": "RT", "lt": "LT", "rb": "RB", "lb": "LB",
		"l3": "L3", "r3": "R3", "back": "View", "start": "Menu",
	},
	PLAYSTATION: {
		"a": "×", "b": ["kółko", "Circle"], "x": ["kwadrat", "Square"], "y": ["trójkąt", "Triangle"],
		"rt": "R2", "lt": "L2", "rb": "R1", "lb": "L1", "l3": "L3", "r3": "R3",
		"back": "Create", "start": "Options",
	},
	# Godot's indices are by place (A = the bottom button); a Nintendo pad prints B there.
	NINTENDO: {
		"a": "B", "b": "A", "x": "Y", "y": "X", "rt": "ZR", "lt": "ZL", "rb": "R", "lb": "L",
		"l3": "L3", "r3": "R3", "back": "-", "start": "+",
	},
}
## The family of the pad used last, and its device id (the rumble's target).
static var family := XBOX
static var device := 0


## The family a pad's name belongs to (anything not Sony or Nintendo reads as Xbox, as MFi pads do).
static func family_of(pad_name: String) -> String:
	var n := pad_name.to_lower()
	for entry: Array in FAMILY_WORDS:
		for w: String in entry[1]:
			if n.contains(w):
				return entry[0]
	return XBOX


## How the pad in use prints the button `token` ("a", "b", "x", "y", "rt", "lt", "rb", "lb", "l3",
## "r3", "back", "start"), in the player's language; the token itself for an unknown one.
static func key(token: String) -> String:
	var face: Variant = (FACES[family] as Dictionary).get(token, token)
	if face is Array:
		return Lang.pick(face[0], face[1])
	return face


## `text` with every {token} filled by `key` (hint lines: "Przytrzymaj {a}, by ...").
static func fmt(text: String) -> String:
	for token: String in FACES[XBOX]:
		var t := "{%s}" % token
		if text.contains(t):
			text = text.replace(t, key(token))
	return text


## Whether a pad is still plugged in to take a rumble (a check's synthetic device 0 isn't).
static func connected() -> bool:
	return fake_connected or device in Input.get_connected_joypads()


## check_gamepad / check_juice: count a synthetic pad as plugged in (the rumble's path).
static var fake_connected := false


## Adds the pad's actions once (main.gd `_ready`; the check calls it too). Device -1: any pad.
static var _installed := false


static func install() -> void:
	_installed = true
	for action: String in STICK_ACTIONS:
		_add(action, DEAD, _axis(STICK_ACTIONS[action][0], STICK_ACTIONS[action][1]))
	_add(GAS, TRIGGER, _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	_add(BRAKE, TRIGGER, _axis(JOY_AXIS_TRIGGER_LEFT, 1.0))
	var b := InputEventJoypadButton.new()
	b.device = -1
	b.button_index = JOY_BUTTON_B
	InputMap.action_add_event(BRAKE, b)
	_add_button(NITRO, JOY_BUTTON_LEFT_SHOULDER)
	_add_button(NITRO, JOY_BUTTON_RIGHT_SHOULDER)
	# Godot's ui_accept / ui_cancel carry no pad button out of the box (the D-pad is in ui_up..):
	# A presses the focused button, B backs out (the garage card, the settings card).
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)


static func _add_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return
	var b := InputEventJoypadButton.new()
	b.device = -1
	b.button_index = button
	InputMap.action_add_event(action, b)


static func _add(action: String, dead: float, event: InputEvent) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, dead)
	InputMap.action_add_event(action, event)


static func _axis(axis: JoyAxis, dir: float) -> InputEventJoypadMotion:
	var m := InputEventJoypadMotion.new()
	m.device = -1
	m.axis = axis
	m.axis_value = dir
	return m


## The left stick in screen space (-1..1, x right, y down, like hud.gd's `stick`), dead zone
## taken out and rescaled so the throw past it still reaches 1.
static func stick() -> Vector2:
	if not _installed:
		install()  # a card read before main.gd ran (tools/check_hud.gd builds the HUD alone)
	return Input.get_vector("pad_left", "pad_right", "pad_up", "pad_down")


static func gas() -> bool:
	if not _installed:
		install()  # a card read before main.gd ran (tools/check_hud.gd builds the HUD alone)
	return Input.is_action_pressed(GAS)


static func brake() -> bool:
	if not _installed:
		install()  # a card read before main.gd ran (tools/check_hud.gd builds the HUD alone)
	return Input.is_action_pressed(BRAKE)


## LB or RB held (main.gd feeds it to car.nitro_hold with the disc and Shift; N1: the press fires a bottle).
static func nitro() -> bool:
	return Input.is_action_pressed(NITRO)


## The right stick's flick: -1 (left) or 1 (right) once per flick past FLICK, 0 for anything else
## (main.gd turns the view by it, like Q / E).
static func view_flick(event: InputEvent) -> int:
	var m := event as InputEventJoypadMotion
	if m == null or m.axis != JOY_AXIS_RIGHT_X:
		return 0
	if absf(m.axis_value) < FLICK_REST:
		_flick_armed = true
	elif _flick_armed and absf(m.axis_value) >= FLICK:
		_flick_armed = false
		return 1 if m.axis_value > 0.0 else -1
	return 0


## The helicopter's height: RT up, LT down (-1..1, analogue).
static func climb() -> float:
	if not _installed:
		install()  # a card read before main.gd ran (tools/check_hud.gd builds the HUD alone)
	return Input.get_action_strength(GAS) - Input.get_action_strength(BRAKE)


## The command a joypad button press stands for ("" for anything else: a release, an axis, a
## touch, a key, a button with no job).
static func command(event: InputEvent) -> String:
	var b := event as InputEventJoypadButton
	if b == null or not b.pressed:
		return ""
	return BUTTONS.get(b.button_index, "")


## Whether `event` closes a card (the settings card, the full map): B or Start.
static func closes(event: InputEvent) -> bool:
	var b := event as InputEventJoypadButton
	return b != null and b.pressed and b.button_index in [JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK]


## Keeps track of which came last, the pad or a touch / key / click (main.gd `_input` calls it
## for every event). A stick resting inside its dead zone doesn't count.
static func note(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > DEAD):
		_seq += 1
		last_pad = _seq
		if event is InputEventJoypadButton or event.device != device:
			# A press or another pad: read the name again (a pad swapped on the same id).
			device = event.device
			family = family_of(Input.get_joy_name(device))
	elif event is InputEventScreenTouch or event is InputEventKey or event is InputEventMouseButton:
		_seq += 1
		last_other = _seq


## The accent ring a pad-focused control wears (settings, garage; the bars and the notebook draw
## their own in the same colour).
const RING := Color("#ffd23f")


static func ring(pt: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = RING
	box.set_border_width_all(maxi(2, roundi(2.0 * pt)))
	box.set_corner_radius_all(roundi(6.0 * pt))
	box.set_expand_margin_all(2.0 * pt)
	return box


## Every Button under `root` takes pad focus (the D-pad / stick moves it, A presses) with the ring.
## Only called once the pad opened a card, so touch never sees a focus ring.
static func focus_all(root: Node, pt: float) -> void:
	var box := ring(pt)
	for b in root.find_children("*", "Button", true, false):
		(b as Button).focus_mode = Control.FOCUS_ALL
		(b as Button).add_theme_stylebox_override("focus", box)


## Back to touch's way (a card opened by a finger after the pad): no Button under `root` takes focus.
static func focus_none(root: Node) -> void:
	for b in root.find_children("*", "Button", true, false):
		(b as Button).focus_mode = Control.FOCUS_NONE


## Drops the focus if it is inside `root` (a card closing).
static func drop_focus(root: Control) -> void:
	if not root.is_inside_tree():
		return
	var focused := root.get_viewport().gui_get_focus_owner()
	if focused != null and (focused == root or root.is_ancestor_of(focused)):
		focused.release_focus()


## True when the pad was used last: the HUD hides the touch pedals and shows the pad's words.
static func in_use() -> bool:
	return last_pad > last_other
