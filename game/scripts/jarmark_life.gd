extends RefCounted
## Jarmark Warszawski's moving shoppers (F, 2026-11-20: "it should be living, the market, with tons
## of people for the trailer"): singles, couples and families strolling up and down the aisles
## under the bulb strings and the cross aisles, slowly, as at a market. The same pattern as
## kladka_life.gd: pure rules and closed-form poses, no node and no per-figure state; city_life.gd
## asks for the poses at each step and writes them into the pedestrians' guest slots, so the draw
## calls are +0. The people who stay (at the counters, round the tree, in the rides' queues) are
## crowds.gd's `jarmark` sites; how many walk follows the same curve (Crowds.jarmark_level: open
## 11:00-22:00, fullest after dark). Not Beehave: one fixed back-and-forth loop per figure.
##
## The frame is the market's (landmarks/jarmark.gd: u along Marszałkowska, v towards the Palace).

const Market := preload("res://scripts/landmarks/jarmark.gd")
const Crowds := preload("res://scripts/crowds.gd")

## The view this near the market's middle (m) brings the strollers up.
const NEAR_R := 260.0
const CENTRE_UV := Vector2(175.0, 45.0)
## The aisles: [u0, v0, u1, v1, half width (m)]: along u between the rows' fronts under the strings
## (jarmark.gd JM_STRINGS), the cross aisles along v, the tree's square, Plac Centralny's walks. The
## first twelve are the ones WALKERS use.
const AISLES := [
	[152.0, 79.5, 218.0, 79.5, 2.0], [222.0, 80.2, 250.0, 80.2, 2.4], [150.0, 60.2, 250.0, 60.2, 3.0],
	[164.0, 40.0, 230.0, 40.0, 3.0], [158.0, 0.0, 158.0, 60.0, 1.4], [259.0, -3.0, 259.0, 80.0, 1.4],
	[207.0, -1.6, 252.0, -1.6, 1.6], [166.0, 20.6, 181.0, 20.6, 1.8], [96.0, 124.5, 127.0, 124.5, 3.0],
	[209.0, 15.5, 233.0, 15.5, 1.6], [53.0, 33.0, 93.0, 33.0, 2.2], [90.5, 46.0, 90.5, 95.0, 1.6],
	[150.0, 11.5, 180.0, 11.5, 1.8], [105.0, 52.0, 150.0, 52.0, 2.0],
]
## The strollers: [kind, aisle, phase 0..1, speed m/s, lane (-1..1 of the half width), shirt, shirt2].
## In the order they come out as the market fills (the first third walk from opening time).
const WALKERS := [
	["couple", 2, 0.05, 0.75, 0.5, "#7a1f26", "#2c3440"], ["single", 1, 0.3, 0.9, -0.4, "#e7e2d6", ""],
	["family", 3, 0.6, 0.6, 0.3, "#344a2e", "#c25a2a"], ["couple", 6, 0.2, 0.8, -0.5, "#1c1d22", "#e57aa0"],
	["single", 4, 0.7, 0.95, 0.4, "#4a5a8a", ""], ["couple", 0, 0.45, 0.7, 0.5, "#8a7a62", "#2f6fb5"],
	["couple", 9, 0.1, 0.75, -0.3, "#2c3440", "#d8432f"], ["family", 7, 0.85, 0.65, -0.4, "#e0b23a", "#1c1d22"],
	["single", 5, 0.15, 1.0, -0.5, "#c25a2a", ""], ["couple", 3, 0.25, 0.8, -0.6, "#f2efe8", "#344a2e"],
	["couple", 2, 0.55, 0.7, -0.5, "#2f6fb5", "#e7e2d6"], ["single", 10, 0.4, 0.9, 0.3, "#7a4fa8", ""],
	["family", 2, 0.35, 0.6, 0.0, "#d8432f", "#4a5a8a"], ["couple", 1, 0.8, 0.75, 0.5, "#3b8f5a", "#8a7a62"],
	["single", 6, 0.65, 1.05, 0.6, "#1c1d22", ""], ["couple", 11, 0.5, 0.7, 0.2, "#e57aa0", "#2c3440"],
	["couple", 3, 0.9, 0.8, 0.6, "#5aa9c9", "#7a1f26"], ["family", 6, 0.5, 0.55, -0.1, "#c9a25a", "#2f6fb5"],
	["single", 8, 0.2, 0.9, 0.0, "#e7e2d6", ""], ["couple", 4, 0.3, 0.8, -0.4, "#7a1f26", "#f2efe8"],
	["couple", 5, 0.75, 0.75, 0.4, "#2c3440", "#e0b23a"], ["single", 0, 0.95, 0.85, -0.5, "#344a2e", ""],
]
const CHILD_SCALE := 0.62
const PAIR_GAP := 0.42


## The market's middle on the map.
static func centre() -> Vector2:
	return Market._jm_world(CENTRE_UV.x, CENTRE_UV.y)


## Is the market's walking life up, the view this near and the market open?
static func near(eye: Vector2, hour: float) -> bool:
	return Crowds.jarmark_level(hour, false) > 0.0 and eye.distance_to(centre()) < NEAR_R


## How high a stroller stands at p over the ground (the market's asphalt on the car park).
static func lift(p: Vector2) -> float:
	return Market.jarmark_lift(p)


## The promo's strollers (crowds.gd promo_jarmark, F 2026-11-21 "why are people standing, can
## they move"): ~260 groups over every aisle, same form as WALKERS, made once from a fixed seed.
static var _promo: Array = []
const PROMO_GROUPS := 260
const PROMO_SHIRTS := ["#7a1f26", "#e7e2d6", "#344a2e", "#1c1d22", "#4a5a8a", "#8a7a62", "#2f6fb5", "#d8432f",
		"#e0b23a", "#c25a2a", "#f2efe8", "#7a4fa8", "#3b8f5a", "#e57aa0", "#5aa9c9", "#c9a25a", "#2c3440", "#b23a48"]


## The strollers in use: WALKERS, or the promo's crowd.
static func walkers() -> Array:
	if not Crowds.promo_jarmark:
		return WALKERS
	if _promo.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 2611
		for i in PROMO_GROUPS:
			var r := rng.randf()
			var kind := "single" if r < 0.3 else ("couple" if r < 0.72 else "family")
			_promo.append([kind, rng.randi() % AISLES.size(), rng.randf(), rng.randf_range(0.45, 0.95),
					rng.randf_range(-0.9, 0.9), PROMO_SHIRTS[rng.randi() % PROMO_SHIRTS.size()],
					PROMO_SHIRTS[rng.randi() % PROMO_SHIRTS.size()]])
	return _promo


## The strollers' figures at clock `t` and `hour`: [position (map x, z), yaw, shirt, trousers, scale].
static func walker_figures(t: float, hour: float) -> Array:
	var out: Array = []
	var list := walkers()
	var n := roundi(list.size() * Crowds.jarmark_level(hour, false))
	var a := Market.JM_AXIS.normalized()
	var b := Vector2(-a.y, a.x)
	for i in n:
		var w: Array = list[i]
		var ai: Array = AISLES[int(w[1])]
		var p0 := Vector2(float(ai[0]), float(ai[1]))
		var p1 := Vector2(float(ai[2]), float(ai[3]))
		var length := maxf(p0.distance_to(p1), 1.0)
		var f := float(w[2]) + t * float(w[3]) / (2.0 * length)
		var x := fposmod(f, 1.0)
		var way := 1.0 if x < 0.5 else -1.0
		var k := x * 2.0 if x < 0.5 else 2.0 - x * 2.0
		var duv := (p1 - p0) / length * way
		var face := (a * duv.x + b * duv.y).normalized()
		var side := Vector2(-face.y, face.x)
		var uv := p0.lerp(p1, k)
		var centre_ := Market._jm_world(uv.x, uv.y) + side * float(w[4]) * float(ai[4])
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
