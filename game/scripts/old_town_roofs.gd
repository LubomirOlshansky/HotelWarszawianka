class_name OldTownRoofs
extends RefCounted
## The Old Town's roof detail: the LoD2 roofs are bare planes, so each pitched slope of a
## historic house gets a small gabled dormer (a cream frame round a dark window under a tiled
## cap) and a few ridges a brick chimney. Pure geometry into the walls' own tile meshes (the
## same material, so no draw call is added); load time only, shared by both city paths.

const MIN_AREA := 14.0       ## m², a roof triangle smaller than this stays bare
const MIN_INRADIUS := 1.25   ## m, room for a dormer and its cheeks inside the triangle
const FRAME := Color("#efe3cb")
const GLASS := Color("#2c3a4d")
const BRICK := Color("#8c4a3a")
## The trailer pass (F's drone photos E05, 2026-11-08): most Old Town stacks are white-plastered,
## and most dormers wear dark grey zinc on their cheeks and caps.
const PLASTER := Color("#ebe5da")
const ZINC := Color("#5d6266")
const SINK := 0.45           ## m, a chimney's foot under the slope
const NO_UV := Vector2(-1.0, -1.0)
const RYNEK := Vector2(-812.4, -1753.8)  ## the market square's centre (OSM place node)
const PLAC := Vector2(-724.2, -1465.4)  ## Plac Zamkowy (Sigismund's Column)
const PLAC_NEAR := 18.0      ## m, the plac's ring of fronts: inner and outer radius (gables of three kinds)
const PLAC_FAR := 92.0
const GABLE_NEAR := 22.0     ## m, the stepped-gable ring round the square: inner and outer radius
const GABLE_FAR := 72.0
const GABLE_BAY := 8.0       ## m, a house front's usual width: one gable per bay
const GABLE_MIN := 4.5       ## m, a wall edge shorter than this takes none
const GABLE_STEPS := [[0.0, 1.0], [1.0, 0.76], [2.0, 0.52]]  ## [height of a stage, its width / the bay's]
const STAGE_H := 1.0         ## m, one stage's height
const PINNACLE := 0.9        ## m, the triangle crowning the top stage
const DEPTH := 0.3           ## m, the gable's thickness


## The extra triangles for one roof triangle (a, b, c; world metres; n its upward normal) of a
## house with `wall` and `tile` colours and a 0..1 `seed`, or an empty Dictionary when it takes
## none. Keys "pos", "nrm", "col" hold one entry per vertex (UVs are all "no window").
static func dress(a: Vector3, b: Vector3, c: Vector3, n: Vector3, wall: Color, tile: Color, seed: float) -> Dictionary:
	var out := {"pos": [], "nrm": [], "col": []}  # plain Arrays: packed ones copy when read out of a Dictionary
	var ab := b - a
	var ac := c - a
	var area := ab.cross(ac).length() * 0.5
	var la := (c - b).length()
	var lb := (c - a).length()
	var lc := ab.length()
	var perimeter := la + lb + lc
	if area < MIN_AREA or perimeter < 0.001 or 2.0 * area / perimeter < MIN_INRADIUS:
		return {}
	var run := Vector3(n.x, 0.0, n.z)  # downslope, horizontal
	var flat := run.length()
	if flat < 0.2 or n.y < 0.3:
		return {}
	var r := flat / n.y  # rise per horizontal metre
	run = run / flat
	# The roof point of the dormer: the triangle's incentre, so the cheeks stay on the slope.
	var p := (a * la + b * lb + c * lc) / perimeter
	var across := Vector3(-run.z, 0.0, run.x)
	var tri2 := PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)])
	# G7 (2026-11-01): what a slope carries comes from its hash, so a street is not one row of
	# the same dormer: a gabled dormer (some wide, some narrow), a pair of skylights, a chimney
	# alone, or a bare slope; the piece sits off the incentre by a hash too, and a chimney varies
	# in height, width and plaster or brick.
	var kind := fposmod(seed * 17.0, 1.0)
	var shift := (fposmod(seed * 23.0, 1.0) - 0.5) * 0.5 * (2.0 * area / perimeter)
	var half := 0.55 + 0.5 * fposmod(seed * 7.0, 1.0)
	var spot := p + across * shift
	if kind < 0.5:
		p = _inside(p, spot, across, half + 0.3, tri2)
		_dormer(out, p, run, across, r, half, seed, wall, tile)
	elif kind < 0.68:
		p = _inside(p, spot, across, 1.2, tri2)
		_skylights(out, p, run, across, r, n, seed, tri2)
	var chimney_odds := 0.35 if kind < 0.5 else (0.9 if kind < 0.85 else 0.5)
	if kind < 0.68:
		half += 0.2
	else:
		half = 0.6
	# A chimney on some slopes: a stack on the same contour (so the same roof height).
	var side_sign := -1.0 if fposmod(seed * 29.0, 1.0) < 0.5 else 1.0
	var cb := p + across * side_sign * (half + 1.3)
	if fposmod(seed * 11.0, 1.0) < chimney_odds and Geometry2D.is_point_in_polygon(Vector2(cb.x, cb.z), tri2):
		_chimney(out, cb, seed, wall)
	if (out["pos"] as Array).is_empty():
		return {}
	return {"pos": PackedVector3Array(out["pos"]), "nrm": PackedVector3Array(out["nrm"]), "col": PackedColorArray(out["col"])}


## The dormer's roof point: `spot` when its two cheeks (`reach` m either side along `across`) stay
## inside the triangle `tri`, else the incentre `p`.
static func _inside(p: Vector3, spot: Vector3, across: Vector3, reach: float, tri: PackedVector2Array) -> Vector3:
	for sgn in [-1.0, 1.0]:
		var q: Vector3 = spot + across * sgn * reach
		if not Geometry2D.is_point_in_polygon(Vector2(q.x, q.z), tri):
			return p
	return spot


## A gabled dormer at roof point `p`: a cream frame round a dark window under a tiled cap.
static func _dormer(out: Dictionary, p: Vector3, run: Vector3, across: Vector3, r: float, half: float, seed: float,
		wall: Color, tile: Color) -> void:
	var up := Vector3.UP
	var wall_h := 0.9 + 0.5 * fposmod(seed * 3.0, 1.0)
	var rise := half * (0.6 + 0.4 * fposmod(seed * 5.0, 1.0))
	var b1 := p - across * half
	var b2 := p + across * half
	var e1 := b1 + up * wall_h
	var e2 := b2 + up * wall_h
	var apex := p + up * (wall_h + rise)
	var q1 := e1 - run * (wall_h / r)
	var q2 := e2 - run * (wall_h / r)
	var ridge := apex - run * ((wall_h + rise) / r)
	var centre := p + up * (wall_h * 0.5) - run * 0.5
	var zinc := fposmod(seed * 59.0, 1.0) < 0.7
	var roof := ZINC if zinc else tile.darkened(0.12)
	var cheek := ZINC.lightened(0.08) if zinc else wall
	var front := wall.lerp(FRAME, 0.7)
	# The front: a cream pentagon, then the window pane just proud of it.
	_tri(out, b1, b2, e2, front, centre)
	_tri(out, b1, e2, e1, front, centre)
	_tri(out, e1, e2, apex, front, centre)
	var f := run * 0.03
	var g1 := b1 + across * 0.18 + up * 0.22 + f
	var g2 := b2 - across * 0.18 + up * 0.22 + f
	var g3 := g2 + up * (wall_h - 0.34)
	var g4 := g1 + up * (wall_h - 0.34)
	_tri(out, g1, g2, g3, GLASS, centre)
	_tri(out, g1, g3, g4, GLASS, centre)
	# The cheeks, then the two slopes of the cap.
	_tri(out, b1, e1, q1, cheek, centre)
	_tri(out, b2, e2, q2, cheek, centre)
	_tri(out, e1, apex, ridge, roof, centre)
	_tri(out, e1, ridge, q1, roof, centre)
	_tri(out, e2, apex, ridge, roof, centre)
	_tri(out, e2, ridge, q2, roof, centre)


## Two roof windows (a dark frame, a pale pane) lying on the slope at `p`, side by side.
static func _skylights(out: Dictionary, p: Vector3, run: Vector3, across: Vector3, r: float, n: Vector3, seed: float,
		tri: PackedVector2Array) -> void:
	var upslope := (-run + Vector3.UP * r).normalized()
	var lift := n * 0.07
	var w := 0.38 + 0.12 * fposmod(seed * 31.0, 1.0)
	var h := 0.5 + 0.2 * fposmod(seed * 37.0, 1.0)
	for sgn in [-1.0, 1.0]:
		var m: Vector3 = p + across * sgn * (w + 0.12)
		if not Geometry2D.is_point_in_polygon(Vector2(m.x, m.z), tri):
			continue
		for k: Array in [[1.0, Color("#3b3d42"), 0.0], [0.72, Color("#6d8aa3"), 0.03]]:
			var s: float = k[0]
			var o := lift + n * float(k[2])
			var q0 := m - across * w * s - upslope * h * s + o
			var q1 := m + across * w * s - upslope * h * s + o
			var q2 := m + across * w * s + upslope * h * s + o
			var q3 := m - across * w * s + upslope * h * s + o
			_tri(out, q0, q1, q2, k[1], m - n)
			_tri(out, q0, q2, q3, k[1], m - n)


## A brick or plastered chimney stack at roof point `cb`, its height, width and cap by `seed`.
static func _chimney(out: Dictionary, cb: Vector3, seed: float, wall: Color) -> void:
	var up := Vector3.UP
	var s := 0.3 + 0.16 * fposmod(seed * 41.0, 1.0)
	var top := 1.1 + 1.4 * fposmod(seed * 43.0, 1.0) + SINK
	var pick := fposmod(seed * 47.0, 1.0)
	var body := PLASTER.darkened(0.08 * fposmod(seed * 53.0, 1.0)) if pick < 0.65 \
			else (BRICK.lerp(wall, 0.65) if pick < 0.8 else BRICK.darkened(0.12 * fposmod(seed * 53.0, 1.0)))
	cb.y -= SINK  # its foot goes under the slope, so no gap shows on the downhill side
	var c0 := cb + Vector3(-s, 0, -s)
	var c1 := cb + Vector3(s, 0, -s)
	var c2 := cb + Vector3(s, 0, s)
	var c3 := cb + Vector3(-s, 0, s)
	var t0 := c0 + up * top
	var t1 := c1 + up * top
	var t2 := c2 + up * top
	var t3 := c3 + up * top
	var cc := cb + up * (top * 0.5)
	for quad: Array in [[c0, c1, t1, t0], [c1, c2, t2, t1], [c2, c3, t3, t2], [c3, c0, t0, t3]]:
		_tri(out, quad[0], quad[1], quad[2], body, cc)
		_tri(out, quad[0], quad[2], quad[3], body, cc)
	_tri(out, t0, t1, t2, body.darkened(0.3), cc)
	_tri(out, t0, t2, t3, body.darkened(0.3), cc)


## One triangle, wound and lit so its normal points away from `inside`.
static func _tri(out: Dictionary, p0: Vector3, p1: Vector3, p2: Vector3, colour: Color, inside: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length() < 0.0001:
		return
	nrm = nrm.normalized()
	var mid := (p0 + p1 + p2) / 3.0
	if nrm.dot(mid - inside) < 0.0:
		var t := p1
		p1 = p2
		p2 = t
		nrm = -nrm
	(out["pos"] as Array).append_array([p0, p1, p2])
	(out["nrm"] as Array).append_array([nrm, nrm, nrm])
	(out["col"] as Array).append_array([colour, colour, colour])


## A stepped gable (the Old Town's attic gables) standing on a wall's top edge a -> b (same
## height, world metres) facing the outward horizontal normal `n`: three stages of
## shrinking width under a pinnacle, a front and a back face, a cap on each step and a dark
## window in the second stage. `wall` is the house colour, `seed` 0..1 varies the stage count.
## Keys "pos", "nrm", "col" as in dress().
static func gable(a: Vector3, b: Vector3, n: Vector3, wall: Color, seed: float) -> Dictionary:
	var out := {"pos": [], "nrm": [], "col": []}
	var span := b - a
	var width := span.length()
	if width < GABLE_MIN:
		return {}
	var along := span / width
	var mid := (a + b) * 0.5
	var up := Vector3.UP
	var front := n * 0.05  # proud of the wall, so it never z-fights the LoD2 plane
	var back := -n * (DEPTH - 0.05)
	var inside := mid - n * 4.0 + up * 1.5
	var stages := 3 if fposmod(seed * 13.0, 1.0) > 0.25 else 2
	var cap := wall.darkened(0.35)
	var face := wall.lerp(FRAME, 0.25)
	var top_h := 0.0
	for i in stages:
		var w: float = width * float(GABLE_STEPS[i][1])
		var y0: float = float(GABLE_STEPS[i][0])
		var y1 := y0 + STAGE_H
		var l := mid - along * (w * 0.5)
		var r := mid + along * (w * 0.5)
		# Front and back faces of the stage.
		for off: Vector3 in [front, back]:
			_tri(out, l + off + up * y0, r + off + up * y0, r + off + up * y1, face, inside)
			_tri(out, l + off + up * y0, r + off + up * y1, l + off + up * y1, face, inside)
		# Its two ends (a thin strip, so the gable reads solid from the side) and its cap.
		for side: Vector3 in [l, r]:
			_tri(out, side + front + up * y0, side + back + up * y0, side + back + up * y1, face, inside)
			_tri(out, side + front + up * y0, side + back + up * y1, side + front + up * y1, face, inside)
		var next_w: float = width * float(GABLE_STEPS[i + 1][1]) if i + 1 < stages else 0.0
		var shoulder := (w - next_w) * 0.5
		for sgn in [-1.0, 1.0]:
			var e0: Vector3 = mid + along * sgn * (w * 0.5)
			var e1: Vector3 = mid + along * sgn * (w * 0.5 - shoulder)
			_tri(out, e0 + front + up * y1, e1 + front + up * y1, e1 + back + up * y1, cap, inside)
			_tri(out, e0 + front + up * y1, e1 + back + up * y1, e0 + back + up * y1, cap, inside)
		top_h = y1
	# The pinnacle: a triangle over the last stage, front and back.
	var last_w: float = width * float(GABLE_STEPS[stages - 1][1])
	var pl := mid - along * (last_w * 0.5) + up * top_h
	var pr := mid + along * (last_w * 0.5) + up * top_h
	var tip := mid + up * (top_h + PINNACLE)
	for off: Vector3 in [front, back]:
		_tri(out, pl + off, pr + off, tip + off, face, inside)
	_tri(out, pl + front, tip + front, tip + back, cap, inside)
	_tri(out, pl + front, tip + back, pl + back, cap, inside)
	_tri(out, pr + front, tip + back, tip + front, cap, inside)
	_tri(out, pr + front, pr + back, tip + back, cap, inside)
	# A dark window in the second stage.
	var ww := minf(0.9, width * 0.12)
	var wl := mid - along * ww + up * (STAGE_H + 0.25)
	var wr := mid + along * ww + up * (STAGE_H + 0.25)
	var wf := n * 0.09
	_tri(out, wl + wf, wr + wf, wr + wf + up * 0.6, GLASS, inside)
	_tri(out, wl + wf, wr + wf + up * 0.6, wl + wf + up * 0.6, GLASS, inside)
	return {"pos": PackedVector3Array(out["pos"]), "nrm": PackedVector3Array(out["nrm"]), "col": PackedColorArray(out["col"])}


## The attic gable of a house on Plac Zamkowy, in one of three kinds by its seed so a row of
## fronts does not repeat: 0 the stepped gable (`gable`), 1 a triangular pediment with a
## cornice and an oculus, 2 a curved (segmental) gable with a round window. Same arguments
## and result as `gable`.
static func plac_gable(a: Vector3, b: Vector3, n: Vector3, wall: Color, seed: float) -> Dictionary:
	var kind := int(fposmod(seed * 17.0, 1.0) * 3.0)
	if kind == 0:
		return gable(a, b, n, wall, seed)
	var out := {"pos": [], "nrm": [], "col": []}
	var span := b - a
	var width := span.length()
	if width < GABLE_MIN:
		return {}
	var along := span / width
	var mid := (a + b) * 0.5
	var up := Vector3.UP
	var front := n * 0.05
	var back := -n * (DEPTH - 0.05)
	var inside := mid - n * 4.0 + up * 1.5
	var face := wall.lerp(FRAME, 0.25)
	var cap := wall.darkened(0.3)
	var half := width * 0.5
	# The profile from the left foot to the right foot: a pediment is two straight rakes, a
	# curved gable an arc of the same rise.
	var rise := minf(half * (0.55 if kind == 1 else 0.5), 3.2)
	var prof: Array[Vector3] = []
	var steps := 2 if kind == 1 else 6
	for i in steps + 1:
		var t := float(i) / steps  # 0..1 across
		var x := (t - 0.5) * 2.0
		var y := rise * (1.0 - absf(x)) if kind == 1 else rise * (1.0 - x * x)
		prof.append(mid + along * (x * half) + up * y)
	var base_l := mid - along * half
	var base_r := mid + along * half
	# Fan the front and back faces from the foot line up to the profile.
	for off: Vector3 in [front, back]:
		for i in prof.size() - 1:
			_tri(out, base_l + off, prof[i] + off, prof[i + 1] + off, face, inside)
			_tri(out, base_l + off, prof[i + 1] + off, base_r + off, face, inside)
	# A coping along the rake, its two sides and top as one band.
	for i in prof.size() - 1:
		var p0 := prof[i]
		var p1 := prof[i + 1]
		_tri(out, p0 + front, p1 + front, p1 + back, cap, inside)
		_tri(out, p0 + front, p1 + back, p0 + back, cap, inside)
	# A cornice strip along the foot (the gable's bottom edge, a little proud).
	var cn := n * 0.14
	_tri(out, base_l + cn, base_r + cn, base_r + cn + up * 0.28, cap, inside)
	_tri(out, base_l + cn, base_r + cn + up * 0.28, base_l + cn + up * 0.28, cap, inside)
	# An oculus (a dark square on the diagonal reads as a round window from the street).
	var wr := minf(0.55, width * 0.08)
	var wc := mid + up * (rise * 0.38 + 0.35) + n * 0.09
	_tri(out, wc - along * wr, wc + up * wr, wc + along * wr, GLASS, inside)
	_tri(out, wc - along * wr, wc + along * wr, wc - up * wr, GLASS, inside)
	return {"pos": PackedVector3Array(out["pos"]), "nrm": PackedVector3Array(out["nrm"]), "col": PackedColorArray(out["col"])}
