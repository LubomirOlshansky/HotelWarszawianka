extends Control
## F 2026-11-19 ("maybe the user can change the clock like on a watch"): the map clock's watch, a
## 24-hour face (midnight at the bottom, noon at the top). Its ring is the game day: warm gold at
## sunrise and sunset fading to cream at noon, the night a dim lavender with a few stars, gold
## ticks at the day's sunrise and sunset (time_of_day.gd `sun_times`). The hour is a knob on the
## ring (a sun by day, a moon by night) with a short hand in, so the middle stays free for the
## time, the weekday and the part of the day (DAY, GOLDEN HOUR, NIGHT). Drag the knob (or tap the
## ring) to an hour: it follows the finger and on release `picked` says it (full_map.gd moves the
## game clock there: time_of_day.gd `set_hour`). Snaps to a quarter hour.
##
## F 2026-11-20 ("make the clocks more stylish, with our design system"): drawn only from the UI
## kit's tokens and type sizes (ui_kit.gd, docs/design/ui-kit.md). Drawn only when it changes.

signal picked(hour: float)

const UiKit := preload("res://scripts/ui_kit.gd")
const QuestBook := preload("res://scripts/quest_book.gd")
const Lang := preload("res://scripts/lang.gd")

## The face's size in points.
const SIZE := 200.0
## Hours each side of sunrise and sunset that read as the golden hour (the game clock stretches
## them: time_of_day.gd `solar_shift`).
const GOLDEN_H := 1.25

var pt := 1.0
var hour := 14.0
## Sunrise and sunset, local hours.
var sun := Vector2(6.0, 18.0)
## [Polish, English] of the weekday ("PT", "FRI"); empty: none.
var day_name: Array = []
var _drag := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(SIZE, SIZE) * pt


## The clock now, the day's sunrise and sunset, and the weekday's [Polish, English]; the knob
## goes there.
func set_time(h: float, sun_times: Vector2, weekday: Array = []) -> void:
	hour = fposmod(h, 24.0)
	sun = sun_times
	day_name = weekday
	custom_minimum_size = Vector2(SIZE, SIZE) * pt
	queue_redraw()


## The face's angle for an hour (radians, screen y down): 0:00 at the bottom, 6:00 left, noon top.
static func angle_of(h: float) -> float:
	return PI * 0.5 + h / 24.0 * TAU


## The hour (0-24) at a point `p` seen from the centre, snapped to a quarter hour.
static func hour_at(p: Vector2) -> float:
	var h := fposmod((p.angle() - PI * 0.5) / TAU * 24.0, 24.0)
	return fposmod(roundf(h * 4.0) / 4.0, 24.0)


## The part of the day at `h` for sunrise and sunset `s`: "clock_golden" within GOLDEN_H of either,
## else "clock_day" or "clock_night" (dialogue.json keys).
static func phase(h: float, s: Vector2) -> String:
	for edge: float in [s.x, s.y]:
		var d := absf(fposmod(h - edge + 12.0, 24.0) - 12.0)
		if d <= GOLDEN_H:
			return "clock_golden"
	return "clock_day" if fposmod(h - s.x, 24.0) < fposmod(s.y - s.x, 24.0) else "clock_night"


## A gold sun with eight rays, or a cream crescent moon, centred at `at` with radius `r` on `ci`
## (the watch's knob, the map clock button's icon); `bg` cuts the crescent.
static func draw_sun_or_moon(ci: CanvasItem, at: Vector2, r: float, night: bool, pt: float, bg := UiKit.RAISED) -> void:
	if night:
		ci.draw_circle(at, r * 0.85, UiKit.INK)
		ci.draw_circle(at + Vector2(r * 0.42, -r * 0.3), r * 0.72, bg)
		return
	for k in 8:
		var ra := TAU * k / 8.0
		ci.draw_line(at + Vector2.from_angle(ra) * r * 0.75, at + Vector2.from_angle(ra) * r * 1.05, UiKit.GOLD, 1.5 * pt, true)
	ci.draw_circle(at, r * 0.55, UiKit.GOLD)


## The ring's colour at hour `h`: gold at the sun's edges, cream at noon; the night lavender.
func _ring_colour(h: float) -> Color:
	var day_len := fposmod(sun.y - sun.x, 24.0)
	var into := fposmod(h - sun.x, 24.0)
	if into >= day_len:
		return UiKit.RAISED.lerp(UiKit.SUB, 0.24)  # opaque: the ring is drawn in overlapping steps
	var edge := minf(into, day_len - into)
	return UiKit.HEAT.lerp(UiKit.GOLD, clampf(edge / GOLDEN_H, 0.0, 1.0)).lerp(UiKit.INK, clampf((edge - GOLDEN_H) / 3.0, 0.0, 0.85))


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
			queue_redraw()
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
	var r := minf(size.x, size.y) * 0.5 - 1.0 * pt
	var font := get_theme_default_font()
	# the face: the kit's raised tile, round, with its edge
	draw_circle(c, r, UiKit.CARD_SOLID.lerp(UiKit.RAISED, 0.6))
	draw_arc(c, r, 0.0, TAU, 96, UiKit.EDGE_STRONG if _drag else UiKit.EDGE, maxf(1.0, UiKit.EDGE_W * 2.0 * pt), true)
	var ring := r * 0.84
	var w := r * 0.13
	# the day ring in 96 steps, its colour by the hour
	for i in 96:
		var h0 := i / 4.0
		draw_arc(c, ring, angle_of(h0), angle_of(h0 + 0.26), 3, _ring_colour(h0 + 0.125), w, true)
	# a few stars over the night
	var day_len := fposmod(sun.y - sun.x, 24.0)
	var night_len := 24.0 - day_len
	for k: float in [0.2, 0.45, 0.7, 0.85]:
		var sh := sun.y + night_len * k
		var p := c + Vector2.from_angle(angle_of(sh)) * (ring + w * (0.18 if k < 0.5 else -0.18))
		draw_circle(p, 1.2 * pt, Color(UiKit.INK, 0.7))
	# the hour ticks inside the ring: every hour a dot, every six a line and its number
	for h: int in 24:
		var a := angle_of(h)
		var inner := ring - w * 0.5 - 4.0 * pt
		if h % 6 == 0:
			draw_line(c + Vector2.from_angle(a) * inner, c + Vector2.from_angle(a) * (inner - 6.0 * pt), UiKit.SUB, 1.5 * pt, true)
			var t := "%d" % h
			var fs := UiKit.px(UiKit.T_LABEL, pt)
			var ts := font.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			var p := c + Vector2.from_angle(a) * (inner - 14.0 * pt)
			draw_string(font, p + Vector2(-ts.x * 0.5, ts.y * 0.32), t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, UiKit.FAINT)
		else:
			draw_circle(c + Vector2.from_angle(a) * inner, 1.0 * pt, Color(UiKit.FAINT, 0.6))
	# sunrise and sunset: gold ticks across the ring
	for s: float in [sun.x, sun.y]:
		var a := angle_of(s)
		draw_line(c + Vector2.from_angle(a) * (ring - w * 0.75), c + Vector2.from_angle(a) * (ring + w * 0.75), UiKit.GOLD, 2.0 * pt, true)
	# the hand: a short gold line in from the knob, the knob a sun by day and a moon by night
	var a := angle_of(hour)
	var tip := c + Vector2.from_angle(a) * ring
	draw_line(c + Vector2.from_angle(a) * (ring - w * 1.9), tip, UiKit.GOLD, 2.5 * pt, true)
	var night := phase(hour, sun) == "clock_night"
	var knob := w * (0.95 if _drag else 0.8)
	draw_circle(tip, knob + 2.0 * pt, UiKit.CARD_SOLID)
	draw_sun_or_moon(self, tip, knob, night, pt, UiKit.CARD_SOLID)
	# the middle: the part of the day (gold caps), the time (the kit's clock size), the weekday
	var pw: Array = QuestBook.words(phase(hour, sun))
	var label := Lang.pick(str(pw[0]), str(pw[1])) if pw.size() >= 2 else ""
	var hm := "%02d:%02d" % [int(hour), int(round(fmod(hour, 1.0) * 60.0)) % 60]
	var big := UiKit.px(UiKit.T_CLOCK + 6.0, pt)
	var small := UiKit.px(UiKit.T_LABEL, pt)
	var hs := font.get_string_size(hm, HORIZONTAL_ALIGNMENT_CENTER, -1, big)
	draw_string(font, c + Vector2(-hs.x * 0.5, hs.y * 0.3), hm, HORIZONTAL_ALIGNMENT_CENTER, -1, big, UiKit.INK)
	if label != "":
		var ls := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, small)
		draw_string(font, c + Vector2(-ls.x * 0.5, -hs.y * 0.55), label, HORIZONTAL_ALIGNMENT_CENTER, -1, small,
				UiKit.FAINT if night else UiKit.GOLD)
	if day_name.size() >= 2:
		var dn := Lang.pick(str(day_name[0]), str(day_name[1]))
		var ds := font.get_string_size(dn, HORIZONTAL_ALIGNMENT_CENTER, -1, small)
		draw_string(font, c + Vector2(-ds.x * 0.5, hs.y * 0.95), dn, HORIZONTAL_ALIGNMENT_CENTER, -1, small, UiKit.SUB)
