extends Control
## The Szprotka's speed streaks and the rank tag (the arcade pass, 2026-11-26; main.gd
## `_boat_fx` sets them every frame of a race): LINES white lines rush in from the screen's
## edges towards its middle once the boat runs past 80 % of its top speed (alpha up to MAX_A at
## 120 %, NITRO_A while the nitro burns), drawn in one `_draw` of this one Control under the
## HUD's panels; and one outlined Label over the boat just ahead ("2ND"), placed from the camera.
## Hidden while there is nothing to draw: no cost off the water. View only.

const LINES := 14
const MAX_A := 0.35
const NITRO_A := 0.6
## A streak's run inwards (share of the half-diagonal per second) and its length (share).
const RUSH := 1.6
const LONG := 0.16

## 0..1: how strong the streaks are now (main.gd eases it).
var amount := 0.0
## The HUD's point (hud.gd `pt`): line widths and the tag's size.
var pt := 1.0
var _t := 0.0
var _angle := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _tag: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 1406
	for i in LINES:
		_angle.append(TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / LINES)
		_phase.append(rng.randf())
	_tag = Label.new()
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.add_theme_color_override("font_color", Color.WHITE)
	_tag.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08))
	_tag.visible = false
	add_child(_tag)
	visible = false


## In the HUD: the whole screen, and the tag's size by the HUD's point (set before the add).
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_tag.add_theme_font_size_override("font_size", maxi(10, roundi(15.0 * pt)))
	_tag.add_theme_constant_override("outline_size", maxi(2, roundi(3.0 * pt)))


## Streaks at `share` of the boat's top speed (`nitro`: burning), eased; call every frame.
func set_speed(share: float, nitro: bool, dt: float) -> void:
	var want := clampf((share - 0.8) / 0.4, 0.0, 1.0) * MAX_A
	if nitro:
		want = maxf(want, NITRO_A)
	amount = lerpf(amount, want, 1.0 - exp(-6.0 * dt))
	if amount < 0.01 and want == 0.0:
		amount = 0.0
	_t += dt
	visible = amount > 0.0 or _tag.visible
	if amount > 0.0:
		queue_redraw()


## The rank tag over the boat ahead: `text` ("" hides it) at screen point `at` (its foot).
func set_tag(text: String, at: Vector2, colour := Color.WHITE) -> void:
	_tag.visible = text != ""
	if text == "":
		visible = amount > 0.0
		return
	if _tag.text != text:
		_tag.text = text
		_tag.reset_size()
	_tag.add_theme_color_override("font_color", colour)
	_tag.position = (at - Vector2(_tag.size.x * 0.5, _tag.size.y)).round()
	visible = true


## Everything off (the race is over).
func off() -> void:
	amount = 0.0
	_tag.visible = false
	visible = false


func _draw() -> void:
	if amount <= 0.0:
		return
	var s := size
	var c := s * 0.5
	var half := c.length()
	var w := maxf(1.0, 1.6 * pt)
	for i in LINES:
		var f := fposmod(_phase[i] + _t * RUSH, 1.0)
		var dir := Vector2.from_angle(_angle[i])
		# From the edge (1.0 of the half-diagonal) inwards to 0.55: never over the boat.
		var r0 := half * lerpf(1.05, 0.62, f)
		var r1 := r0 - half * LONG
		var a := amount * sin(PI * f)
		draw_line(c + dir * r0, c + dir * r1, Color(1.0, 1.0, 1.0, a), w)
