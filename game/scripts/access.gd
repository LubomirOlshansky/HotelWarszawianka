extends RefCounted
## Accessibility and comfort options (loop v1.0 "Accessibility", 2026-11-01), the one place the
## game reads them: settings.gd keeps them in the file, main.gd calls `apply` after loading and
## after each change, and the rest of the game only reads the statics here. Settings → ŁATWOŚĆ
## (settings_panel.gd) is where the player changes them.
##   text_scale     1.0, or LARGE_TEXT: the HUD's text (hud.gd `_label`) one step bigger;
##                  hud.gd `apply_text_scale` re-sizes every label at once when it changes.
##   calm           true: no flashing or shaking: the patrol cars' lights burn steady instead of
##                  alternating, the VHS pulse and the headlight flash stay off, and anything
##                  that shakes the screen asks `shake()`, which is 0 then.
##   color_safe     true: markers that told green from amber or red from blue by hue alone get
##                  a second cue (the drop-off beacon turns blue, the patrol lights white/blue),
##                  and the HUD's win green and fail red (cards, the status panel and its 1ST
##                  badge, banners, notes, the target arrow, bubbles) pass through `tint`: the
##                  green turns blue and the red a lighter vermilion, a pair red-green colour
##                  blindness tells apart by hue and brightness.
##   vibration      false: `buzz` does nothing. THE hook for the phone's haptics: every
##                  Input.vibrate_handheld call goes through it, on to haptics.gd (the floor a
##                  hand feels, the iOS engine kept warm; car.gd's knock calls haptics.gd directly).
##   stop_assist    false: the quest stop assist (stop_assist.gd) leaves the car alone.
##   left_handed    true: the pedals, the nitro and the helicopter's pads bottom left, the stick's
##                  half of the screen and Classic's steering strip on the right (hud.gd
##                  `set_left_handed`, applied by main.gd at once, no restart).

const LARGE_TEXT := 1.25

static var text_scale := 1.0
static var calm := false
static var color_safe := false
static var vibration := true
static var stop_assist := true
static var left_handed := false


## Take the values from the saved settings (settings.gd).
static func apply(s: RefCounted) -> void:
	text_scale = LARGE_TEXT if s.text_large else 1.0
	calm = s.calm
	color_safe = s.color_safe
	vibration = s.vibration
	stop_assist = s.stop_assist
	left_handed = s.left_handed


## The game's success green (missions DROPOFF_COLOUR, rivals WIN_COLOUR, the 1ST badge) and fail
## red (FAIL_COLOUR, LOSE_COLOUR), and what `tint` makes of them with `color_safe` on.
const GREEN := Color("#56d68a")
const RED := Color("#e2574c")
const GREEN_SAFE := Color("#4aa3ff")
const RED_SAFE := Color("#ff8a5c")


## A HUD colour as the player sees it: with `color_safe`, the success green turns blue and the fail
## red a lighter vermilion (alpha kept); every other colour, and everything with it off, as it is.
static func tint(c: Color) -> Color:
	if not color_safe:
		return c
	for pair in [[GREEN, GREEN_SAFE], [RED, RED_SAFE]]:
		var from: Color = pair[0]
		if absf(c.r - from.r) + absf(c.g - from.g) + absf(c.b - from.b) < 0.03:
			var to: Color = pair[1]
			return Color(to.r, to.g, to.b, c.a)
	return c


## A buzz on the phone (milliseconds, strength 0..1) unless vibration is off; haptics.gd raises
## it to a strength the hand feels and keeps iOS's haptic engine warm (v1.0 juice).
static func buzz(ms: int, strength: float) -> void:
	if vibration:
		load("res://scripts/haptics.gd").buzz(ms, strength)


## 1 for a normal run, 0 with `calm`: multiply any screen shake by it.
static func shake() -> float:
	return 0.0 if calm else 1.0
