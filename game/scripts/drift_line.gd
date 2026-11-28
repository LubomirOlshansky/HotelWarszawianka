extends RefCounted
## A drift track's ideal line (Bokiem na Narodowym, the grey box: docs/design/drift-narodowy.md 0b.2,
## critique-drift.md section 4): pure, no scene. Built from a `game/data/drift_tracks.json` track: the
## line sampled every STEP m (position on the floor x, z; heading yaw, the game's rotation.y; signed
## curvature, + a left bend), its bends (the arcs, with their centres: the loop camera's anchors), the
## sign-change points between two bends that turn opposite ways (the crossovers' flick spots), the kick
## boxes (KICK_BOX m before each bend up to its start) and the zones' boards (BOARD m off the line).
## The one-thumb car is posed on this line (drift_car.gd), so `project` exists for the score's rules
## and the checks, not for steering.

const DATA := "res://data/drift_tracks.json"
## Metres between two samples.
const STEP := 0.5
## A bend this far ahead (m) or nearer lets a kick open the angle (0b.2).
const KICK_BOX := 30.0
## The curvature of a bend (1/m) the kick looks for (0b.2: |κ| ≥ 1/60).
const BEND_K := 1.0 / 60.0
## The zones' boards and cones stand this far from the line (m, 0b.2).
const BOARD := 2.6

var key := ""
var name_pair: Array = ["", ""]
var length := 0.0
var pos := PackedVector2Array()
var yaw := PackedFloat32Array()
var kappa := PackedFloat32Array()
## One per segment: {"kind": "straight"|"arc", "s0", "s1", "sign" (arcs: +1 left, -1 right), "centre": Vector2, "r"}.
var segments: Array[Dictionary] = []
## The arcs only: indices into `segments`, in order.
var bends: Array[int] = []
## s of each sign change (the middle of a straight between two bends turning opposite ways).
var flips := PackedFloat32Array()
## Kick boxes: [s0, s1] before each bend.
var kick_boxes: Array[Vector2] = []
## Zones: {"kind", "side", "s0", "s1", "sign" (the bend's), "points": PackedVector2Array along the board}.
var zones: Array[Dictionary] = []
## Grass islands [x, z, half width, half depth] (floor decoration, not a rule).
var islands: Array = []
## Per sample: the sign of the first bend within KICK_BOX m ahead (0 none), for `bend_ahead`.
var _ahead := PackedInt32Array()

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(DATA, FileAccess.READ)
		if f == null:
			push_error("drift_line.gd: cannot read %s" % DATA)
			return {}
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		_data = parsed if parsed is Dictionary else {}
		if _data.is_empty():
			push_error("drift_line.gd: %s is not a JSON object" % DATA)
	return _data


## [Polish, English] for a word of the drift's UI (drift_tracks.json "words").
static func word(id: String) -> Array:
	var w: Variant = data().get("words", {}).get(id, null)
	if w is Array and (w as Array).size() >= 2:
		return w
	push_warning("drift_line.gd: no word '%s'" % id)
	return [id, id]


## The track `id` of drift_tracks.json (null when it is missing).
static func load_track(id: String) -> RefCounted:
	var t: Variant = data().get("tracks", {}).get(id, null)
	if not t is Dictionary:
		push_error("drift_line.gd: no track '%s'" % id)
		return null
	var line := new()
	line.key = id
	line.build(t)
	return line


## The forward direction on the floor (x, z) of heading `y` (rad): rotation.y's -z turned by y.
static func dir(y: float) -> Vector2:
	return Vector2(-sin(y), -cos(y))


## The left of heading `y` on the floor.
static func left(y: float) -> Vector2:
	return Vector2(-cos(y), sin(y))


func build(t: Dictionary) -> void:
	name_pair = t.get("name", [key, key])
	islands = t.get("islands", [])
	var st: Array = t.get("start", [0.0, 0.0])
	var p := Vector2(float(st[0]), float(st[1]))
	var y := deg_to_rad(float(t.get("yaw", 0.0)))
	pos.clear()
	yaw.clear()
	kappa.clear()
	segments.clear()
	bends.clear()
	var s := 0.0
	pos.append(p)
	yaw.append(y)
	kappa.append(0.0)
	for seg: Dictionary in t.get("segments", []):
		var d := {"kind": "straight", "s0": s, "sign": 0, "r": 0.0, "centre": Vector2.INF}
		var seg_len := 0.0
		var k := 0.0
		if seg.has("arc"):
			var a: Array = seg["arc"]
			var r := float(a[0])
			var sg := signf(float(a[2]))
			seg_len = r * deg_to_rad(float(a[1]))
			k = sg / r
			d["kind"] = "arc"
			d["sign"] = int(sg)
			d["r"] = r
			d["centre"] = p + left(y) * r * sg
			bends.append(segments.size())
		else:
			seg_len = float(seg.get("straight", 0.0))
		var n := maxi(1, int(round(seg_len / STEP)))
		var ds := seg_len / n
		for i in n:
			# Exact on an arc: the chord of the step at the mid heading.
			var mid := y + k * ds * 0.5
			p += dir(mid) * (ds if k == 0.0 else 2.0 / absf(k) * sin(absf(k) * ds * 0.5))
			y += k * ds
			pos.append(p)
			yaw.append(y)
			kappa.append(k)
		s += seg_len
		d["s1"] = s
		segments.append(d)
	length = s
	# Sign changes: a straight between two bends of opposite signs flips at its middle.
	flips.clear()
	for i in range(1, segments.size() - 1):
		var a: Dictionary = segments[i - 1]
		var b: Dictionary = segments[i + 1]
		if segments[i]["kind"] == "straight" and a["kind"] == "arc" and b["kind"] == "arc" and int(a["sign"]) != int(b["sign"]):
			flips.append((float(segments[i]["s0"]) + float(segments[i]["s1"])) * 0.5)
	_ahead.resize(pos.size())
	var next_sign := 0
	var next_at := INF
	for i in range(pos.size() - 1, -1, -1):
		if absf(kappa[i]) >= BEND_K:
			next_sign = int(signf(kappa[i]))
			next_at = i * STEP
		_ahead[i] = next_sign if next_at - i * STEP <= KICK_BOX + 0.001 else 0
	kick_boxes.clear()
	for bi in bends:
		var s0 := float(segments[bi]["s0"])
		kick_boxes.append(Vector2(maxf(0.0, s0 - KICK_BOX), s0))
	zones.clear()
	for z: Dictionary in t.get("zones", []):
		var zs: Dictionary = segments[int(z.get("seg", 0))]
		var a0 := lerpf(float(zs["s0"]), float(zs["s1"]), float(z.get("from", 0.0)))
		var a1 := lerpf(float(zs["s0"]), float(zs["s1"]), float(z.get("to", 1.0)))
		var zsign := bend_sign((a0 + a1) * 0.5)
		var out := str(z.get("side", "out")) == "out"
		# Out: away from the bend's centre (right of a left bend); in: towards it.
		var lat := BOARD * float(zsign) * (-1.0 if out else 1.0)
		var pts := PackedVector2Array()
		var q := a0
		while q <= a1 + 0.001:
			pts.append(at(q) + left(yaw_at(q)) * lat)
			q += 1.0
		zones.append({"kind": str(z.get("kind", "zona")), "side": "out" if out else "in", "s0": a0, "s1": a1,
				"sign": zsign, "points": pts})


func _i(s: float) -> int:
	return clampi(int(s / STEP), 0, pos.size() - 2)


## The line's point at s (m along it).
func at(s: float) -> Vector2:
	var i := _i(s)
	return pos[i].lerp(pos[i + 1], clampf(s / STEP - i, 0.0, 1.0))


## The line's heading at s (rad, rotation.y).
func yaw_at(s: float) -> float:
	var i := _i(s)
	return lerpf(yaw[i], yaw[i + 1], clampf(s / STEP - i, 0.0, 1.0))


## The signed curvature at s (1/m, + left).
func kappa_at(s: float) -> float:
	return kappa[_i(s) + 1]


## The segment index at s.
func segment_at(s: float) -> int:
	for i in segments.size():
		if s < float(segments[i]["s1"]):
			return i
	return segments.size() - 1


## The side the slip belongs on at s (+1 left, -1 right, 0 none): the arc's own, on a straight the
## previous bend's before its flip point and the next one's after it (before the first bend the
## first's, after the last the last's).
func bend_sign(s: float) -> int:
	var i := segment_at(s)
	var d: Dictionary = segments[i]
	if d["kind"] == "arc":
		return int(d["sign"])
	var prev := 0
	var next := 0
	for j in range(i - 1, -1, -1):
		if segments[j]["kind"] == "arc":
			prev = int(segments[j]["sign"])
			break
	for j in range(i + 1, segments.size()):
		if segments[j]["kind"] == "arc":
			next = int(segments[j]["sign"])
			break
	if prev == 0:
		return next
	if next == 0:
		return prev
	if prev == next:
		return prev
	return prev if s < (float(d["s0"]) + float(d["s1"])) * 0.5 else next


## The sign of the first bend within `reach` m ahead of s (the arc s is on counts), 0 for none.
func bend_ahead(s: float, reach := KICK_BOX) -> int:
	if reach == KICK_BOX and not _ahead.is_empty():
		return _ahead[clampi(int(ceil(s / STEP)), 0, _ahead.size() - 1)]
	var q := s
	while q <= minf(s + reach, length):
		var k := kappa_at(q)
		if absf(k) >= BEND_K:
			return int(signf(k))
		q += STEP
	return 0


## The flick spot nearest to s (m), or INF.
func flip_near(s: float) -> float:
	var best := INF
	for f in flips:
		if absf(f - s) < absf(best - s):
			best = f
	return best


## Seconds from the nearest flick spot at speed v (- before it, + after it), INF far from all.
func flip_dt(s: float, v: float) -> float:
	var f := flip_near(s)
	if f == INF:
		return INF
	return (s - f) / maxf(v, 0.5)


## The bend's centre the loop camera frames at s (INF on a straight that follows the car): an arc's
## own; a crossover the previous arc's before its flick spot and the next one's after it.
func loop_centre(s: float) -> Vector2:
	var i := segment_at(s)
	var d: Dictionary = segments[i]
	if d["kind"] == "arc":
		return d["centre"]
	var before: bool = i > 0 and segments[i - 1]["kind"] == "arc"
	var after: bool = i + 1 < segments.size() and segments[i + 1]["kind"] == "arc"
	if before and after:
		var mid := (float(d["s0"]) + float(d["s1"])) * 0.5
		return segments[i - 1]["centre"] if s < mid else segments[i + 1]["centre"]
	return Vector2.INF


## The point's place along the line: Vector2(s, offset) (offset + left of the line), the nearest
## sample's (a search over every sample: only the checks and the score's tests call it).
func project(p: Vector2) -> Vector2:
	var best := INF
	var bi := 0
	for i in pos.size():
		var d := pos[i].distance_squared_to(p)
		if d < best:
			best = d
			bi = i
	var off := (p - pos[bi]).dot(left(yaw[bi]))
	return Vector2(bi * STEP, off)


## The distance (m) from p to a zone's board (a polyline).
static func board_distance(zone: Dictionary, p: Vector2) -> float:
	var pts: PackedVector2Array = zone["points"]
	var best := INF
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	if pts.size() == 1:
		best = p.distance_to(pts[0])
	return best
