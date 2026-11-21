extends Control
## The loading screen's progress (F 2026-11-20: "the progress bar like the PKiN"): the Palace of
## Culture in silhouette, lit floor by floor from the foot to the spire as the city loads. It only
## ever moves up (title.gd eases `share` and never sends it back), so a long build step reads as
## the next floor taking a moment, not as a stuck animation (the old moving bar stuttered with the
## build's steps: 0.9 s on the Nothing Phone). Drawn in code, scaled to the control's size.

## 0..1: how much of the city is in (title.gd `_shown`).
var share := 0.0

## The silhouette, x from 0 (left) to 1 (right), y from 0 (foot) to 1 (spire's tip): the podium
## and wings, the stepped tower, the crown with its pinnacles and the spire. Symmetric.
const HALF := [
	Vector2(0.0, 0.0), Vector2(0.0, 0.10), Vector2(0.10, 0.10), Vector2(0.10, 0.20), Vector2(0.18, 0.20),
	Vector2(0.18, 0.31), Vector2(0.27, 0.31), Vector2(0.27, 0.44), Vector2(0.34, 0.44), Vector2(0.34, 0.60),
	Vector2(0.38, 0.60), Vector2(0.38, 0.69), Vector2(0.41, 0.69), Vector2(0.41, 0.76), Vector2(0.44, 0.76),
	Vector2(0.44, 0.81), Vector2(0.475, 0.81), Vector2(0.475, 0.86), Vector2(0.493, 0.86), Vector2(0.5, 1.0),
]
const DARK := Color("#14053a")
const RIM := Color("#7ff6ff")
const LIT := Color("#ffcf6b")
const WINDOW := Color("#fff3b0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The whole outline in the control's pixels (y down).
func outline() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p: Vector2 in HALF:
		pts.append(_px(p))
	for i in range(HALF.size() - 2, -1, -1):
		var p: Vector2 = HALF[i]
		pts.append(_px(Vector2(1.0 - p.x, p.y)))
	return pts


func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * size.x, (1.0 - p.y) * size.y)


func _draw() -> void:
	var shape := outline()
	draw_colored_polygon(shape, Color(DARK, 0.85))
	# The lit part: the silhouette under the line that has climbed to `share` of the height.
	var level := size.y * (1.0 - clampf(share, 0.0, 1.0))
	if share > 0.0:
		var below := PackedVector2Array([Vector2(-1, level), Vector2(size.x + 1, level),
				Vector2(size.x + 1, size.y + 1), Vector2(-1, size.y + 1)])
		for part: PackedVector2Array in Geometry2D.intersect_polygons(shape, below):
			draw_colored_polygon(part, Color(LIT, 0.9))
		# Windows in the lit floors: a grid of small warm cells inside the silhouette.
		var cell := maxf(size.x / 26.0, 2.0)
		var y := size.y - cell * 1.5
		while y > level + cell * 0.5:
			var x := cell
			while x < size.x - cell:
				var c := Vector2(x, y)
				if Geometry2D.is_point_in_polygon(c, shape) and Geometry2D.is_point_in_polygon(c + Vector2(cell * 0.6, cell * 0.6), shape):
					draw_rect(Rect2(c, Vector2(cell * 0.5, cell * 0.6)), Color(WINDOW, 0.75))
				x += cell * 1.2
			y -= cell * 1.6
	# The brand neon round it.
	var closed := shape.duplicate()
	closed.append(shape[0])
	draw_polyline(closed, RIM, maxf(size.x / 90.0, 1.5), true)
