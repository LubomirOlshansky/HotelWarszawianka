extends RefCounted
## Kładka Abakanowicz's moving life (F, 2026-11-20: "make it alive, cyclists and everyone"): walkers,
## joggers, a family, cyclists, scooters and a rollerblader on the footbridge from Karowa to Port
## Praski. The same pattern as boulevard_life.gd: pure rules and closed-form poses, no node and no
## per-figure state; city_life.gd asks for the poses at each step and writes them into the
## pedestrians' guest slots (people) and the scooters' MultiMesh (scooters, the rollerblader and the
## cyclists: the scooter family's third shape), so the draw calls are +0. The people who stay (the
## seats, the railing, the meridian pair) are crowds.gd's `kladka` sites. Not Beehave: one fixed
## back-and-forth loop per figure (beehave-trees: no choice between behaviours).
##
## The frame is the bridge's centre line from the map's stamp (`data["kladka"]`, tools/kladka.py):
## `s` metres from the Powiśle end, a lane `v` metres to the right of the line (the walk is
## +-HALF wide). setup() reads it once; with no bridge on the map nothing is out.

## The view this near the bridge's middle (m) brings the life up (the bridge is 451 m long).
const NEAR_R := 320.0

## The walkers: [kind, hours key, lane (m off the centre line), s0, s1 (m from the Powiśle end; a
## negative s1 is from the Praga end), speed m/s, phase 0..1, shirt, shirt2]. Kind "couple", "single",
## "jogger", "family" (two adults and a child), "photo" (one standing still at the railing's lane,
## phone up). Hours: "eve" 17:00-24:00, "day" 9:00-18:00, "all" 6:00-24:00.
const EVE_HOURS := [17.0, 24.0]
const DAY_HOURS := [9.0, 18.0]
const ALL_HOURS := [6.0, 24.0]
const WALKERS := [
	["couple", "eve", -1.2, 5.0, -5.0, 1.0, 0.05, "#e57aa0", "#2b2c2f"],
	["couple", "eve", 1.4, 5.0, -5.0, 0.95, 0.38, "#5aa9c9", "#9c2f3a"],
	["couple", "eve", -1.6, 60.0, 330.0, 0.85, 0.7, "#f2efe8", "#3b8f5a"],
	["couple", "all", 1.1, 5.0, -5.0, 1.05, 0.88, "#7a4fa8", "#e0b23a"],
	["single", "all", 1.8, 5.0, -5.0, 1.3, 0.22, "#d8432f", ""],
	["single", "eve", -2.0, 30.0, 400.0, 1.15, 0.6, "#2f6fb5", ""],
	["single", "day", 0.4, 5.0, -5.0, 1.25, 0.15, "#c96b2c", ""],
	["jogger", "all", -0.6, 5.0, -5.0, 2.8, 0.5, "#fff3a6", ""],
	["jogger", "eve", 0.7, 5.0, -5.0, 3.1, 0.12, "#b8f0d8", ""],
	["family", "day", -1.0, 20.0, 380.0, 0.75, 0.3, "#3b8f5a", "#e0b23a"],
	["family", "eve", 1.3, 40.0, 300.0, 0.8, 0.8, "#e8e4d8", "#2f6fb5"],
	["couple", "day", -1.4, 5.0, -5.0, 0.9, 0.55, "#2f6fb5", "#d8432f"],
]
## The riders: [kind (0 scooter, 1 rollerblader, 2 cyclist), hours key, lane, speed m/s, phase, shirt].
## Cyclists keep near the middle (the bridge is shared; the signs say pedestrians first).
const RIDERS := [
	[2, "all", 0.4, 4.6, 0.1, "#2f6fb5"], [2, "all", -0.3, 5.2, 0.46, "#d8432f"], [2, "eve", 0.6, 4.2, 0.72, "#3b8f5a"],
	[2, "day", -0.5, 5.6, 0.3, "#e0b23a"], [0, "all", 0.9, 5.4, 0.62, "#7a4fa8"], [0, "eve", -0.8, 6.0, 0.9, "#f2efe8"],
	[1, "eve", 0.2, 3.4, 0.2, "#e57aa0"],
]
const RIDE_KINDS := {"scooter": 0, "blader": 1, "cyclist": 2}
## A rider's lane does not come closer than this to the walk's edge (m).
const EDGE := 0.8
const CHILD_SCALE := 0.62
const PAIR_GAP := 0.42
## The bubble: a passer-by's line once per LINE_GAP s, when the view is within LINE_R m of one.
const LINE_GAP := 40.0
const LINE_R := 40.0

static var _line := PackedVector3Array()
static var _cum := PackedFloat32Array()
static var _half := 3.45
static var _centre := Vector2.INF


## Reads the bridge's line from the map's stamp (`data["kladka"]`); clears it when there is none.
static func setup(st: Dictionary) -> void:
	_line = PackedVector3Array()
	_cum = PackedFloat32Array()
	_centre = Vector2.INF
	if int(st.get("v", 0)) < 1:
		return
	var flat: Array = st["line"]
	for i in range(0, flat.size() - 2, 3):
		_line.append(Vector3(float(flat[i]), float(flat[i + 2]), float(flat[i + 1])))
	if _line.size() < 2:
		_line = PackedVector3Array()
		return
	_cum.append(0.0)
	for i in range(1, _line.size()):
		_cum.append(_cum[i - 1] + Vector2(_line[i].x - _line[i - 1].x, _line[i].z - _line[i - 1].z).length())
	_half = float(st["half"])
	var m := at(total() * 0.5, 0.0)
	_centre = m


## The bridge's length (m), 0 without one.
static func total() -> float:
	return _cum[_cum.size() - 1] if _cum.size() > 0 else 0.0


## The bridge's middle (Vector2.INF without one).
static func centre() -> Vector2:
	return _centre


## Is the life up, the view this near the bridge?
static func near(eye: Vector2, hour: float) -> bool:
	return _centre != Vector2.INF and active(hour) and eye.distance_to(_centre) < NEAR_R


## Is any of the bridge's life up at `hour` (it is lit and open all night; quiet 1:00-6:00)?
static func active(hour: float) -> bool:
	return hour >= 6.0 or hour < 1.0


static func in_window(w: Array, hour: float) -> bool:
	return hour >= float(w[0]) and hour < float(w[1])


static func hours(key: String) -> Array:
	return EVE_HOURS if key == "eve" else (DAY_HOURS if key == "day" else ALL_HOURS)


## The map point `v` m right of the line at `s`.
static func at(s: float, v: float) -> Vector2:
	var d := dir(s)
	var k := _seg(s)
	var t := clampf((s - _cum[k]) / maxf(_cum[k + 1] - _cum[k], 0.001), 0.0, 1.0)
	var p := _line[k].lerp(_line[k + 1], t)
	return Vector2(p.x, p.z) + Vector2(-d.y, d.x) * v


## The unit direction along the line at `s` (over 6 m, so a bend turns smoothly).
static func dir(s: float) -> Vector2:
	var a := _pt(maxf(s - 3.0, 0.0))
	var b := _pt(minf(s + 3.0, total()))
	return (b - a).normalized()


static func _pt(s: float) -> Vector2:
	var k := _seg(s)
	var t := clampf((s - _cum[k]) / maxf(_cum[k + 1] - _cum[k], 0.001), 0.0, 1.0)
	var p := _line[k].lerp(_line[k + 1], t)
	return Vector2(p.x, p.z)


static func _seg(s: float) -> int:
	return clampi(_cum.bsearch(s, true) - 1, 0, _cum.size() - 2)


static func yaw_of(d: Vector2) -> float:
	return atan2(-d.x, -d.y)


## A back-and-forth triangle wave: 0 at x = 0, 1 at x = 0.5, 0 at 1.
static func tri(x: float) -> float:
	var f := fposmod(x, 1.0)
	return f * 2.0 if f < 0.5 else 2.0 - f * 2.0


## Where a there-and-back walker is at clock `t`: [s, +1 out / -1 back]. Its lane is mirrored on the
## way back (people keep right).
static func _walk(s0: float, s1: float, speed: float, phase: float, t: float) -> Array:
	var length := maxf(s1 - s0, 1.0)
	var f := phase + t * speed / (2.0 * length)
	return [s0 + tri(f) * length, 1.0 if fposmod(f, 1.0) < 0.5 else -1.0]


static func _ends(w0: float, w1: float) -> Vector2:
	var s1 := w1 if w1 > 0.0 else total() + w1
	return Vector2(w0, maxf(s1, w0 + 10.0))


## The walkers' figures at clock `t` and `hour`: [position (map x, z), yaw, shirt, trousers, scale].
static func walker_figures(t: float, hour: float) -> Array:
	var out: Array = []
	if _line.is_empty():
		return out
	for i in WALKERS.size():
		var w: Array = WALKERS[i]
		if not in_window(hours(str(w[1])), hour):
			continue
		var e := _ends(float(w[3]), float(w[4]))
		var wk := _walk(e.x, e.y, float(w[5]), float(w[6]), t)
		var s := float(wk[0])
		var way := float(wk[1])
		var face := dir(s) * way
		var side := Vector2(-face.y, face.x)
		var centre_ := at(s, clampf(float(w[2]) * way, -_half + 0.6, _half - 0.6))
		var yaw := yaw_of(face)
		var c1 := Color(str(w[7]))
		var c2 := Color(str(w[8])) if str(w[8]) != "" else c1
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


## The riders' instances at clock `t` and `hour`: [position (map x, z), yaw, kind, shirt].
static func rider_figures(t: float, hour: float) -> Array:
	var out: Array = []
	if _line.is_empty():
		return out
	for r: Array in RIDERS:
		if not in_window(hours(str(r[1])), hour):
			continue
		var wk := _walk(2.0, total() - 2.0, float(r[3]), float(r[4]), t)
		var s := float(wk[0])
		var way := float(wk[1])
		var v := clampf(float(r[2]) * way + 0.9 * way, -_half + EDGE, _half - EDGE)
		out.append([at(s, v), yaw_of(dir(s) * way), int(r[0]), Color(str(r[5]))])
	return out


## The walk's height (map y) under p: the line's at the nearest point (the walk is level across), so
## a figure stands on the deck, never on the river under it (city_life's _ground is the terrain).
static func walk_y(p: Vector2) -> float:
	var best := INF
	var y := 0.0
	for k in _line.size() - 1:
		var a := Vector2(_line[k].x, _line[k].z)
		var ab := Vector2(_line[k + 1].x, _line[k + 1].z) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
		var d2 := p.distance_squared_to(a + ab * t)
		if d2 < best:
			best = d2
			y = lerpf(_line[k].y, _line[k + 1].y, t)
	return y


## The nearest of `figs` ([position, ...] each) to p, Vector2.INF when none.
static func nearest(figs: Array, p: Vector2) -> Vector2:
	var best := Vector2.INF
	var bd := INF
	for f: Array in figs:
		var q: Vector2 = f[0]
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d
			best = q
	return best
