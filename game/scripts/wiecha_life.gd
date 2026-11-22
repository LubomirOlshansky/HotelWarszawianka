extends RefCounted
## Pasaż Wiecha's strollers at Christmas (F, 2026-11-22: "add people", scattered and moving, not
## overdone): singles, couples and families walking up and down the pasaż under the shooting stars,
## one way through the gingerbread man, round the photo frames, and up to Chmielna. The same pattern
## as jarmark_life.gd: pure rules and closed-form poses, no node and no per-figure state; city_life.gd
## asks for the poses at each step and writes them into the pedestrians' guest slots (+0 draw calls).
## The people who stay (at the decorations, at the café fronts) are crowds.gd's `wiecha` site; how
## many walk follows Crowds.wiecha_level. Not Beehave: one fixed back-and-forth walk per figure.
##
## The frame is the first scene's (first_scene.gd FRAME_*: u north along Marszałkowska, v east).

const Decor := preload("res://scripts/landmarks/wiecha_swieta.gd")
const Crowds := preload("res://scripts/crowds.gd")

## The view this near the pasaż's middle (m) brings the strollers up.
const NEAR_R := 230.0
const CENTRE_UV := Vector2(-30.0, 69.0)
## The walks, polylines in (u, v), threaded round the decorations and the masts (the spec's plan):
## the stores' side (through the gingerbread man), the pavilions' side, and up to Chmielna.
const PATHS := [
	[Vector2(-160.0, 65.0), Vector2(-121.0, 65.2), Vector2(-115.0, 66.3), Vector2(-90.0, 66.3), Vector2(-86.0, 69.3),
			Vector2(-78.0, 69.3), Vector2(-70.0, 66.2), Vector2(-34.0, 68.6), Vector2(-21.0, 68.6), Vector2(-5.0, 66.1),
			Vector2(9.5, 66.0), Vector2(11.5, 69.4), Vector2(16.5, 69.4), Vector2(25.0, 66.1), Vector2(105.0, 66.1)],
	[Vector2(-160.0, 72.0), Vector2(-110.0, 71.9), Vector2(-100.0, 71.4), Vector2(-60.0, 71.0), Vector2(-40.0, 72.2),
			Vector2(25.0, 72.0), Vector2(62.0, 71.4), Vector2(72.0, 66.8), Vector2(110.0, 66.6)],
	[Vector2(-62.0, 69.6), Vector2(-65.5, 76.5), Vector2(-65.5, 96.0)],
]
## The strollers: [kind, path, phase 0..1, speed m/s, lane (m, off the path's line), shirt, shirt2].
## In the order they come out as the pasaż fills (the first third walk from the morning).
const WALKERS := [
	["couple", 0, 0.05, 0.8, 0.3, "#7a1f26", "#2c3440"], ["single", 1, 0.3, 1.05, -0.3, "#e7e2d6", ""],
	["family", 0, 0.62, 0.6, -0.2, "#344a2e", "#c25a2a"], ["single", 2, 0.2, 1.0, 0.2, "#1c1d22", ""],
	["couple", 1, 0.75, 0.8, 0.3, "#4a5a8a", "#e57aa0"], ["single", 0, 0.4, 1.1, 0.4, "#8a7a62", ""],
	["couple", 1, 0.12, 0.75, -0.2, "#2f6fb5", "#d8432f"], ["single", 0, 0.85, 1.0, -0.4, "#e0b23a", ""],
	["family", 1, 0.45, 0.6, 0.0, "#c9a25a", "#2c3440"], ["single", 2, 0.7, 0.95, -0.2, "#5aa9c9", ""],
	["couple", 0, 0.25, 0.8, -0.3, "#f2efe8", "#344a2e"], ["single", 1, 0.58, 1.1, 0.4, "#7a4fa8", ""],
	["couple", 0, 0.52, 0.7, 0.4, "#3b8f5a", "#8a7a62"], ["single", 1, 0.92, 1.0, -0.4, "#d8432f", ""],
	["single", 0, 0.15, 1.15, 0.1, "#1c1d22", ""], ["couple", 2, 0.45, 0.75, 0.0, "#e57aa0", "#2c3440"],
	["family", 0, 0.95, 0.55, 0.2, "#e7e2d6", "#7a1f26"], ["single", 1, 0.2, 0.95, 0.2, "#c25a2a", ""],
	["couple", 1, 0.35, 0.8, 0.1, "#2c3440", "#e0b23a"], ["single", 0, 0.7, 1.05, 0.3, "#4a5a8a", ""],
]
const CHILD_SCALE := 0.62
const PAIR_GAP := 0.42


## The pasaż's middle on the map.
static func centre() -> Vector2:
	return Decor._wx_world(CENTRE_UV.x, CENTRE_UV.y)


## Is the pasaż's walking life up, the view this near and the hour right?
static func near(eye: Vector2, hour: float) -> bool:
	return Crowds.wiecha_level(hour, false) > 0.0 and eye.distance_to(centre()) < NEAR_R


## A path's length and its points' running lengths.
static func _lengths(path: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for k in range(1, path.size()):
		out.append(out[k - 1] + (path[k] as Vector2).distance_to(path[k - 1]))
	return out


## Where along `path` a distance `s` is: [point (u, v), direction (u, v)].
static func _along(path: Array, run: PackedFloat32Array, s: float) -> Array:
	for k in range(1, path.size()):
		if s <= run[k] or k == path.size() - 1:
			var a: Vector2 = path[k - 1]
			var b: Vector2 = path[k]
			var f := clampf((s - run[k - 1]) / maxf(run[k] - run[k - 1], 0.01), 0.0, 1.0)
			return [a.lerp(b, f), (b - a).normalized()]
	return [path[0], Vector2.RIGHT]


## The strollers' figures at clock `t` and `hour`: [position (map x, z), yaw, shirt, trousers, scale].
static func walker_figures(t: float, hour: float) -> Array:
	var out: Array = []
	var n := roundi(WALKERS.size() * Crowds.wiecha_level(hour, false))
	var a := Decor.FirstScene.FRAME_S.normalized()
	var b := Vector2(-a.y, a.x)
	for i in n:
		var w: Array = WALKERS[i]
		var path: Array = PATHS[int(w[1])]
		var run := _lengths(path)
		var length := maxf(run[run.size() - 1], 1.0)
		var x := fposmod(float(w[2]) + t * float(w[3]) / (2.0 * length), 1.0)
		var way := 1.0 if x < 0.5 else -1.0
		var s := length * (x * 2.0 if x < 0.5 else 2.0 - x * 2.0)
		var at: Array = _along(path, run, s)
		var duv: Vector2 = (at[1] as Vector2) * way
		var face := (a * duv.x + b * duv.y).normalized()
		var side := Vector2(-face.y, face.x)
		var uv: Vector2 = at[0]
		var centre_ := Decor._wx_world(uv.x, uv.y) + side * float(w[4]) * way
		var yaw := atan2(-face.x, -face.y)
		var c1 := Color(str(w[5]))
		var c2 := Color(str(w[6])) if str(w[6]) != "" else c1
		match str(w[0]):
			"couple":
				out.append([centre_ + side * PAIR_GAP, yaw, c1, 0.1 + 0.25 * (i % 3), Vector3.ONE])
				out.append([centre_ - side * PAIR_GAP, yaw, c2, 0.1 + 0.25 * ((i + 1) % 3), Vector3.ONE])
			"family":
				out.append([centre_ + side * 0.55, yaw, c1, 0.35, Vector3.ONE])
				out.append([centre_ - side * 0.55, yaw, c2, 0.1, Vector3.ONE])
				out.append([centre_ + face * 0.3, yaw, Color("#e57aa0"), 0.1, Vector3.ONE * CHILD_SCALE])
			_:
				out.append([centre_, yaw, c1, 0.35, Vector3.ONE])
	return out
