extends Control
## F 2026-11-19 ("maybe the user can change the clock like on a watch"): the map clock's watch, a
## 24-hour face (midnight at the bottom, noon at the top) with the day light, the night dark and
## gold marks at the game day's sunrise and sunset (time_of_day.gd `sun_times`). Drag the hand
## (or tap the face) to an hour: the hour shows in the middle while the finger moves, and on
## release `picked` says it (full_map.gd moves the game clock there: time_of_day.gd `set_hour`).
## Snaps to a quarter hour. Drawn only when it changes.

signal picked(hour: float)

## The face's size in points.
const SIZE := 190.0
const DAY_INK := Color("#f3d98a")
const NIGHT_INK := Color("#1d2150")
const GOLD := Color("#ffb347")
const FACE := Color("#0f1230")
const HAND := Color("#fbf7ee")

var pt := 1.0
var hour := 14.0
## Sunrise and sunset, local hours.
var sun := Vector2(6.0, 18.0)
var _drag := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(SIZE, SIZE) * pt


## The clock now and the day's sunrise and sunset; the hand goes there.
func set_time(h: float, sun_times: Vector2) -> void:
	hour = fposmod(h, 24.0)
	sun = sun_times
	custom_minimum_size = Vector2(SIZE, SIZE) * pt
	queue_redraw()


## The face's angle for an hour (radians, screen y down): 0:00 at the bottom, 6:00 left, noon top.
static func angle_of(h: float) -> float:
	return PI * 0.5 + h / 24.0 * TAU


## The hour (0-24) at a point `p` seen from the centre, snapped to a quarter hour.
static func hour_at(p: Vector2) -> float:
	var h := fposmod((p.angle() - PI * 0.5) / TAU * 24.0, 24.0)
	return fposmod(roundf(h * 4.0) / 4.0, 24.0)


func _gui_input(event: InputEvent) -> void:
	var c := size * 0.5
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.position - c).length() <= c.x:
			_drag = true
			hour = hour_at(mb.position - c)
			queue_redraw()
		elif not mb.pressed and _drag:
			_drag = false
			picked.emit(hour)
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		var mm := event as InputEventMouseMotion
		if (mm.position - c).length() > 6.0 * pt:
			hour = hour_at(mm.position - c)
			queue_redraw()
		accept_event()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0 * pt
	draw_circle(c, r, FACE)
	# the day from sunrise to sunset light, the night dark, as a ring
	var ring := r * 0.82
	var w := r * 0.22
	var day_len := fposmod(sun.y - sun.x, 24.0)
	draw_arc(c, ring, angle_of(sun.x), angle_of(sun.x + day_len), 48, DAY_INK, w, true)
	draw_arc(c, ring, angle_of(sun.y), angle_of(sun.y + 24.0 - day_len), 48, NIGHT_INK, w, true)
	for s: float in [sun.x, sun.y]:
		var a := angle_of(s)
		draw_line(c + Vector2.from_angle(a) * (ring - w * 0.6), c + Vector2.from_angle(a) * (ring + w * 0.6), GOLD, 3.0 * pt, true)
	var font := get_theme_default_font()
	var fs := int(round(12.0 * pt))
	for h: int in [0, 6, 12, 18]:
		var p := c + Vector2.from_angle(angle_of(h)) * (ring - w * 1.25)
		var t := "%d" % h
		var ts := font.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, p + Vector2(-ts.x * 0.5, ts.y * 0.3), t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color("#c9c2d8"))
	var tip := c + Vector2.from_angle(angle_of(hour)) * ring
	draw_line(c, tip, HAND, 4.0 * pt, true)
	var day := fposmod(hour - sun.x, 24.0) < day_len
	draw_circle(tip, w * 0.55, GOLD if day else HAND)
	draw_circle(c, 5.0 * pt, HAND)
	var hm := "%02d:%02d" % [int(hour), int(round(fmod(hour, 1.0) * 60.0)) % 60]
	var big := int(round(20.0 * pt))
	var hs := font.get_string_size(hm, HORIZONTAL_ALIGNMENT_CENTER, -1, big)
	draw_string(font, c + Vector2(-hs.x * 0.5, r * 0.42), hm, HORIZONTAL_ALIGNMENT_CENTER, -1, big, HAND)
