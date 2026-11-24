extends Node
## The drive after THE TAPCZAN (F's ask 2026-11-24, docs/design/tapczan-pub.md): a pint or a lost
## cup of beer pong, and once the player is back in the car the world is a little off for about
## LONG s, fading out: the camera sways and rolls a touch (main.gd `_update_camera` passes its
## transform through `sway`), the city is seen double and soft at the edges (tipsy.gdshader, in the
## city's SubViewport, so the HUD stays sharp), odd thoughts drift across the screen and fade (data/
## tapczan.json "tipsy"), and the car pulls gently to one side and then the other (car.gd
## `tipsy_pull`, a yaw rate added while moving). More drinks, a stronger start (up to 1).
##
## Cost: nothing while sober (the overlay hidden, `_process` off). While on: one full-screen pass
## with three taps of the screen (fill rate: a phone question, PHONE-CHECK), a Label, a few sines.

const Lang := preload("res://scripts/lang.gd")
const Room := preload("res://scripts/tapczan_room.gd")

## How long it lasts (s) from the full amount, and the amount a drink adds.
const LONG := 60.0
const PER_DRINK := 0.35
## The car's pull at the full amount (rad/s of yaw at speed) and the camera's sway.
const PULL := 0.22
const ROLL := 0.045
const DRIFT := 0.9
## A thought every THOUGHT_GAP s, each on screen THOUGHT_S s (fading in and out).
const THOUGHT_GAP := 7.0
const THOUGHT_S := 5.5

var hud: CanvasLayer
var car: Node3D
## 0..1 now; `start` is the amount at the last drink.
var amount := 0.0
var left := 0.0
var _start := 0.0
var _t := 0.0
var _next_thought := 1.5
var _thought_t := -1.0
var _overlay: ColorRect
var _mat: ShaderMaterial
var _text_layer: CanvasLayer
var _text: Label
var _rng := RandomNumberGenerator.new()


## Built once: the overlay under `world` (the city's SubViewport), the thought line on its own layer.
func setup(world: Node) -> void:
	_rng.randomize()
	var layer := CanvasLayer.new()
	layer.layer = 0
	layer.name = "TipsyLayer"
	world.add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/tipsy.gdshader")
	_overlay.material = _mat
	_overlay.visible = false
	layer.add_child(_overlay)
	_text_layer = CanvasLayer.new()
	_text_layer.layer = 2
	add_child(_text_layer)
	_text = Label.new()
	_text.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pt: float = hud.pt if hud != null and "pt" in hud else 1.0
	_text.add_theme_font_size_override("font_size", int(17 * pt))
	_text.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6))
	_text.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	_text.add_theme_constant_override("outline_size", int(6 * pt))
	_text.visible = false
	_text_layer.add_child(_text)
	set_process(false)


## `drinks` more: stronger, and the clock starts again (it begins when `go` is called).
func add(drinks: int) -> void:
	_start = minf(1.0, maxf(amount, _start) + PER_DRINK * drinks)


## Back in the car: it begins (nothing when sober).
func go() -> void:
	if _start <= 0.0:
		return
	amount = _start
	left = LONG
	_t = 0.0
	_next_thought = 1.5
	_overlay.visible = true
	set_process(true)
	if hud != null:
		var p := Room.pair("drunk_toast")
		hud.toast(str(p[0]), str(p[1]))


## The amount (0..1) `t` s into a spell that started at `a`: an ease out to 0 at LONG.
static func fade(a: float, t: float) -> float:
	var k := clampf(1.0 - t / LONG, 0.0, 1.0)
	return a * k * (2.0 - k)


func on() -> bool:
	return amount > 0.0


## The car's pull now (rad/s of yaw): a slow wander one way and then the other.
static func pull_at(a: float, t: float) -> float:
	return a * PULL * (sin(t * 0.45) + 0.35 * sin(t * 1.7 + 0.8))


## The camera's transform with the sway in it (main.gd, after it placed the camera).
func sway(xf: Transform3D) -> Transform3D:
	if amount <= 0.0:
		return xf
	var roll := amount * ROLL * sin(_t * 0.8)
	var b := xf.basis.rotated(xf.basis.z.normalized(), roll)
	var drift := xf.basis.x * amount * DRIFT * sin(_t * 0.6) + xf.basis.y * amount * DRIFT * 0.4 * sin(_t * 0.9 + 1.0)
	return Transform3D(b, xf.origin + drift)


func _process(dt: float) -> void:
	_t += dt
	left -= dt
	amount = fade(_start, _t)
	if left <= 0.0 or amount <= 0.001:
		_stop()
		return
	_mat.set_shader_parameter("amount", amount)
	_mat.set_shader_parameter("t", _t)
	if car != null and "tipsy_pull" in car:
		car.tipsy_pull = pull_at(amount, _t)
	_thoughts(dt)


func _thoughts(dt: float) -> void:
	if _thought_t < 0.0:
		_next_thought -= dt
		if _next_thought <= 0.0:
			var lines: Array = Room.data().get("tipsy", [])
			if not lines.is_empty():
				var l: Array = lines[_rng.randi() % lines.size()]
				_text.text = Lang.pick(str(l[0]), str(l[1]))
				var vp := _text.get_viewport().get_visible_rect().size
				_text.size = Vector2(vp.x * 0.6, 0)
				_text.position = Vector2(vp.x * _rng.randf_range(0.12, 0.28), vp.y * _rng.randf_range(0.16, 0.32))
				_text.visible = true
				_thought_t = 0.0
		return
	_thought_t += dt
	var k := _thought_t / THOUGHT_S
	_text.modulate.a = clampf(minf(k * 4.0, (1.0 - k) * 3.0), 0.0, 1.0) * clampf(amount * 2.0, 0.3, 1.0)
	_text.position.y -= dt * 6.0
	if k >= 1.0:
		_text.visible = false
		_thought_t = -1.0
		_next_thought = THOUGHT_GAP * _rng.randf_range(0.7, 1.3)


func _stop() -> void:
	var was := _start > 0.0
	amount = 0.0
	_start = 0.0
	left = 0.0
	_overlay.visible = false
	_text.visible = false
	_thought_t = -1.0
	if car != null and "tipsy_pull" in car:
		car.tipsy_pull = 0.0
	set_process(false)
	if was and hud != null:
		var p := Room.pair("drunk_over")
		hud.toast(str(p[0]), str(p[1]))
