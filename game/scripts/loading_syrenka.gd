extends Control
## The loading screen's progress (F 2026-11-23: "for the loading make the Syrenka, not the PKiN"):
## Warsaw's mermaid in silhouette, the shield on her left arm and the sword raised, filling with
## warm gold from the tail's fin to the sword's tip as the city loads. It only ever moves up
## (title.gd eases `share` and never sends it back), so a long build step reads as the next moment
## of the fill, not as a stuck animation (the old moving bar stuttered with the build's steps:
## 0.9 s on the Nothing Phone). Drawn in code, scaled to the control's size.

## 0..1: how much of the city is in (title.gd `_shown`).
var share := 0.0

## The outline, x from 0 (left) to 1 (right), y from 0 (foot) to 1 (the sword's tip): the tail's
## fin, the shield, the head, the raised arm and sword, the body and the tail's curl.
const OUTLINE := [
	Vector2(0.05, 0.05), Vector2(0.15, 0.13), Vector2(0.06, 0.22), Vector2(0.21, 0.19), Vector2(0.33, 0.22),
	Vector2(0.41, 0.27), Vector2(0.34, 0.33), Vector2(0.25, 0.36), Vector2(0.20, 0.46), Vector2(0.25, 0.56),
	Vector2(0.34, 0.59), Vector2(0.41, 0.57), Vector2(0.45, 0.60), Vector2(0.475, 0.63), Vector2(0.465, 0.68),
	Vector2(0.48, 0.73), Vector2(0.52, 0.755), Vector2(0.56, 0.735), Vector2(0.575, 0.69), Vector2(0.565, 0.64),
	Vector2(0.58, 0.62), Vector2(0.63, 0.66), Vector2(0.665, 0.74), Vector2(0.68, 0.81), Vector2(0.65, 0.82),
	Vector2(0.65, 0.845), Vector2(0.69, 0.84), Vector2(0.70, 0.995), Vector2(0.735, 0.995), Vector2(0.725, 0.84),
	Vector2(0.765, 0.845), Vector2(0.765, 0.82), Vector2(0.725, 0.81), Vector2(0.71, 0.73), Vector2(0.67, 0.64),
	Vector2(0.62, 0.58), Vector2(0.61, 0.50), Vector2(0.585, 0.42), Vector2(0.60, 0.33), Vector2(0.64, 0.28),
	Vector2(0.72, 0.30), Vector2(0.80, 0.31), Vector2(0.86, 0.25), Vector2(0.85, 0.16), Vector2(0.78, 0.09),
	Vector2(0.62, 0.05), Vector2(0.42, 0.06), Vector2(0.27, 0.10), Vector2(0.16, 0.07),
]
const DARK := Color("#14053a")
const RIM := Color("#7ff6ff")
const LIT := Color("#ffcf6b")
const CREST := Color("#fff3b0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The outline in the control's pixels (y down).
func outline() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p: Vector2 in OUTLINE:
		pts.append(Vector2(p.x * size.x, (1.0 - p.y) * size.y))
	return pts


func _draw() -> void:
	var shape := outline()
	draw_colored_polygon(shape, Color(DARK, 0.85))
	if share > 0.0:
		# The gold under the line that has climbed to `share` of the height, a pale crest on top.
		var level := size.y * (1.0 - clampf(share, 0.0, 1.0))
		var crest := maxf(size.y / 120.0, 1.5)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(shape, _below(level)):
			draw_colored_polygon(part, Color(LIT, 0.92))
		if share < 1.0:
			for part: PackedVector2Array in Geometry2D.intersect_polygons(shape, _band(level, crest)):
				draw_colored_polygon(part, Color(CREST, 0.95))
	# The brand neon round her.
	var closed := shape.duplicate()
	closed.append(shape[0])
	draw_polyline(closed, RIM, maxf(size.x / 70.0, 1.5), true)


func _below(level: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-1, level), Vector2(size.x + 1, level), Vector2(size.x + 1, size.y + 1), Vector2(-1, size.y + 1)])


func _band(level: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-1, level), Vector2(size.x + 1, level), Vector2(size.x + 1, level + h), Vector2(-1, level + h)])
