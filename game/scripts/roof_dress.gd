class_name RoofDress
extends RefCounted
## The roofs lane (docs/design/roofs.md, RF2 and RF3): what an ordinary LoD2 building's roof
## lacks between its bare planes. Each flat roof gets a low parapet on its outer edges (the
## coping's light band that closes the knife edge the camera saw), and the pre-war tenements
## (R4 type 1) outside the Old Town get their brick chimney stacks: rows of them along the
## party walls on flat roofs, one now and then on a pitch. Pure geometry into the walls' own tile meshes
## (the same material, so no draw call is added), no collision and no roof-grid cell (the
## helicopter's landings, the roof cassettes and the roof rescues keep the LoD2 planes). Load
## time only, shared by both city paths; every seed comes from a place, never an index (a
## sector's batch numbers its triangles differently from the whole map's).

const PARAPET_H := 0.7          ## m, a parapet over a flat roof
const PARAPET_TALL := 1.1       ## m, over a roof 40 m up or more (towers' screens)
const PARAPET_MIN_EDGE := 2.0   ## m, a shorter roof edge takes none (the triangle budget)
const PARAPET_MIN_AREA := 60.0  ## m², a flat roof level smaller than this takes none (plant boxes)
const PROBE := 0.35             ## m, outside an edge: a roof there means the edge is inside
const CELL := 8.0               ## m, the run's triangle grid for the probes
const COPING := Color("#c9c6bf")
const COPING_METAL := Color("#aeb3b8")
const BRICK := Color("#7d5446")
const PLASTER := Color("#b9ab98")
const SINK := 0.45              ## m, a chimney's foot under its roof
const NO_UV := Vector2(-1.0, -1.0)

## Counts for the build's report: parapet edges, chimneys, triangles added.
static var parapets := 0
static var chimneys := 0
static var triangles := 0
static var rooms := 0
static var antennas := 0
static var furniture := 0      ## triangles of roof furniture (rooms, masts, units)

## Off switch for the roof furniture (PR 3), kept for before/after shots.
const FURNITURE := true
const FURNITURE_MIN_AREA := 150.0  ## m², the highest flat level must be this big
const INSET := 1.5                 ## m, furniture stays this far inside every outer edge
const SKY := Color("#2f3a44")  ## a skylight's dark glass lid


## The extra triangles for one LoD2 building: its triangles are `t0` to `t1` of the arrays,
## `kind` its roof dress class (HouseTypes.rhythm: 1 tenement, 2 slab, 3 office, 0 other), `historic` whether it stands in
## the Old Town or the New Town (their roofs are old_town_roofs.gd's). Returns "pos", "nrm",
## "col" (one entry per vertex; empty arrays when it takes none).
static func building(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		uv: PackedVector2Array, t0: int, t1: int, kind: int, historic: bool) -> Dictionary:
	var out := {"pos": [], "nrm": [], "col": []}  # plain Arrays: packed ones copy out of a Dictionary
	var box_verts := {}
	var ground := INF
	var wall := Color(-1, -1, -1)
	var glass := false
	for t in range(t0, t1, 3):
		ground = minf(ground, minf(pos[t].y, minf(pos[t + 1].y, pos[t + 2].y)))
		if absf(nrm[t].y) < 0.3:
			if uv[t].y < -0.5:
				# A plant box's side (tools/bake_gugik.py rooftop_boxes): its corners mark its top.
				for k in 3:
					box_verts[_key(pos[t + k])] = true
			elif wall.r < 0.0:
				wall = col[t]
				glass = col[t].a < 0.75
	if wall.r < 0.0:
		wall = Color("#b5aca0")
	wall.a = 1.0
	# The roof triangles (a box's top is not the roof) and the area of each flat level.
	var roofs: Array[int] = []
	var box_tops: Array[int] = []
	var levels := {}
	var grid := {}
	for t in range(t0, t1, 3):
		if nrm[t].y < 0.3:
			continue
		if box_verts.has(_key(pos[t])) and box_verts.has(_key(pos[t + 1])) and box_verts.has(_key(pos[t + 2])):
			box_tops.append(t)
			continue
		roofs.append(t)
		var lo := Vector2(pos[t].x, pos[t].z)
		var hi := lo
		for k in range(1, 3):
			var q := Vector2(pos[t + k].x, pos[t + k].z)
			lo = lo.min(q)
			hi = hi.max(q)
		for gx in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
			for gz in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
				var gk := Vector2i(gx, gz)
				if not grid.has(gk):
					grid[gk] = []
				(grid[gk] as Array).append(t)
		if nrm[t].y > 0.97:
			var lk := roundi((pos[t].y + pos[t + 1].y + pos[t + 2].y) / 3.0 * 2.0)
			levels[lk] = float(levels.get(lk, 0.0)) + _area(pos[t], pos[t + 1], pos[t + 2])
	if FURNITURE and not historic and (kind == 2 or kind == 3):
		var before := triangles
		_furniture(out, pos, nrm, roofs, levels, grid, wall, kind, box_tops)
		furniture += triangles - before
	for t in roofs:
		var n := nrm[t]
		var place := fposmod(pos[t].x * 0.0731 + pos[t].z * 0.0417, 1.0)
		if n.y > 0.97:
			var y := (pos[t].y + pos[t + 1].y + pos[t + 2].y) / 3.0
			if float(levels.get(roundi(y * 2.0), 0.0)) < PARAPET_MIN_AREA:
				continue
			_flat_edges(out, pos, t, grid, y, y - ground, wall, kind, glass, historic)
		elif kind == 1 and not historic:
			_pitched(out, pos[t], pos[t + 1], pos[t + 2], n, place)
	return {"pos": PackedVector3Array(out["pos"]), "nrm": PackedVector3Array(out["nrm"]),
			"col": PackedColorArray(out["col"])}


## Roof furniture on the building's highest flat level (at least FURNITURE_MIN_AREA m²), inside
## its outer edges by INSET and clear of the baked plant boxes: a slab's lift and stair rooms,
## TV masts, a dish and vent stacks, an office's HVAC units and skylight strips. Laid square to
## the roof's outer edges; every choice is seeded from the roof's place, never an index.
static func _furniture(out: Dictionary, pos: PackedVector3Array, nrm: PackedVector3Array, roofs: Array[int],
		levels: Dictionary, grid: Dictionary, wall: Color, kind: int, box_tops: Array[int]) -> void:
	var top_key := -100000
	for lk: int in levels:
		if float(levels[lk]) >= FURNITURE_MIN_AREA and lk > top_key:
			top_key = lk
	if top_key == -100000:
		return
	var tris: Array[int] = []
	var sum := Vector2.ZERO
	var ysum := 0.0
	var wsum := 0.0
	for t in roofs:
		if nrm[t].y > 0.97 and roundi((pos[t].y + pos[t + 1].y + pos[t + 2].y) / 3.0 * 2.0) == top_key:
			tris.append(t)
			var a := _area(pos[t], pos[t + 1], pos[t + 2])
			var c := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
			sum += Vector2(c.x, c.z) * a
			ysum += c.y * a
			wsum += a
	var mean := sum / wsum
	var y := ysum / wsum
	# The axis: the outer edges' directions folded into a quarter turn, weighted by length (a
	# roof's edges meet square; inner diagonals of the triangulation do not count).
	var fold := Vector2.ZERO
	for t in tris:
		for i in 3:
			var p := Vector2(pos[t + i].x, pos[t + i].z)
			var q := Vector2(pos[t + (i + 1) % 3].x, pos[t + (i + 1) % 3].z)
			var e := q - p
			var length := e.length()
			if length < 0.5:
				continue
			var o := Vector2(e.y, -e.x) / length
			var c3 := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
			if o.dot((p + q) * 0.5 - Vector2(c3.x, c3.z)) < 0.0:
				o = -o
			if _covered(pos, grid, (p + q) * 0.5 + o * PROBE, y - 0.3):
				continue
			var ang := atan2(e.y, e.x) * 4.0
			fold += Vector2(cos(ang), sin(ang)) * length
	var ax := Vector2.RIGHT.rotated(fold.angle() * 0.25) if fold.length() > 0.001 else Vector2.RIGHT
	var cr := Vector2(-ax.y, ax.x)
	var lo := Vector2(INF, INF)  # extent in (along, across)
	var hi := -lo
	for t in tris:
		for k in 3:
			var q := Vector2(pos[t + k].x, pos[t + k].z) - mean
			var uvq := Vector2(q.dot(ax), q.dot(cr))
			lo = lo.min(uvq)
			hi = hi.max(uvq)
	if hi.x - lo.x < hi.y - lo.y:  # the long side first
		ax = cr
		cr = Vector2(-ax.y, ax.x)
		var l2 := Vector2(lo.y, -hi.x)
		hi = Vector2(hi.y, -lo.x)
		lo = l2
	var length := hi.x - lo.x
	var width := hi.y - lo.y
	var at := func(u: float, v: float) -> Vector2: return mean + ax * u + cr * v
	# An item of half size (hw along, hd across) fits when its centre, corners and side middles,
	# pushed out by INSET, all stand on this level with nothing higher over them, and it keeps
	# a metre from every plant box.
	var fit := func(p: Vector2, hw: float, hd: float) -> bool:
		for su: float in [-1.0, 0.0, 1.0]:
			for sv: float in [-1.0, 0.0, 1.0]:
				var s := p + ax * su * (hw + INSET * absf(su)) + cr * sv * (hd + INSET * absf(sv))
				if not _on_level(pos, nrm, grid, s, y):
					return false
		var clear := maxf(hw, hd) + 1.0
		for t in box_tops:
			var a := Vector2(pos[t].x, pos[t].z)
			var b := Vector2(pos[t + 1].x, pos[t + 1].z)
			var c := Vector2(pos[t + 2].x, pos[t + 2].z)
			if Geometry2D.point_is_inside_triangle(p, a, b, c):
				return false
			for e: Array in [[a, b], [b, c], [c, a]]:
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p, e[0], e[1])) < clear:
					return false
		return true
	var d3 := Vector3(ax.x, 0.0, ax.y)
	var x3 := Vector3(cr.x, 0.0, cr.y)
	var taken: Array[Vector2] = []
	var cx := mean.x
	var cz := mean.y
	var up := Vector3.UP
	var mast := COPING_METAL.darkened(0.4)
	if kind == 2:
		var n_rooms := 0 if box_tops.size() >= 4 else mini(4, ceili(length / 30.0))  # two baked boxes: GUGiK has them
		for i in n_rooms:
			var u: float = lo.x + length * (i + 0.5) / n_rooms
			for off: float in [0.0, 0.25, -0.25]:
				var p: Vector2 = at.call(u, (lo.y + hi.y) * 0.5 + off * width)
				if fit.call(p, 2.0, 1.5):
					_box(out, Vector3(p.x, y, p.y), d3, 2.0, 1.5, 2.6, wall.lightened(0.15), COPING)
					taken.append(p)
					rooms += 1
					break
		if _r(cx, cz, 1) < 0.5:
			for j in int(_r(cx, cz, 2) * 3.0) + 1:
				var p := _spot(at, lo, hi, fit, taken, cx, cz, 10 + j, 0.4, 0.4)
				if p.x == INF:
					continue
				var f := Vector3(p.x, y, p.y)
				_box(out, f, d3, 0.1, 0.1, 2.5, mast, mast)
				for b in 1 + int(_r(cx, cz, 20 + j) * 2.0):
					_box(out, f + up * (1.7 + 0.4 * b), x3, 0.6, 0.06, 0.15, mast, mast, 0.0)
				antennas += 1
		if _r(cx, cz, 3) < 0.3:
			var p := _spot(at, lo, hi, fit, taken, cx, cz, 30, 0.7, 0.7)
			if p.x != INF:
				var f := Vector3(p.x, y, p.y)
				_box(out, f, d3, 0.075, 0.075, 0.9, mast, mast)
				var dir := x3 * (1.0 if _r(cx, cz, 4) < 0.5 else -1.0)
				var tilt := deg_to_rad(25.0)  # the face 65 degrees up from the roof
				var nrm_d := (dir * cos(tilt) + up * sin(tilt)).normalized()
				var ua := up.cross(nrm_d).normalized()
				var va := nrm_d.cross(ua)
				var cc := f + up * 1.0 + nrm_d * 0.1
				var back := COPING.darkened(0.25)
				for k in 8:
					var a0 := k * TAU / 8.0
					var a1 := (k + 1) * TAU / 8.0
					var p0 := cc + (ua * cos(a0) + va * sin(a0)) * 0.6
					var p1 := cc + (ua * cos(a1) + va * sin(a1)) * 0.6
					_tri2(out, cc, p0, p1, COPING, COPING, COPING, cc - nrm_d)
					_tri2(out, cc, p0, p1, back, back, back, cc + nrm_d)
				antennas += 1
		for j in 2 + int(_r(cx, cz, 5) * 3.0):
			var p := _spot(at, lo, hi, fit, taken, cx, cz, 40 + j, 0.2, 0.2)
			if p.x != INF:
				_box(out, Vector3(p.x, y, p.y), d3, 0.2, 0.2, 0.6, PLASTER, PLASTER.darkened(0.2))
	else:
		for j in 1 + int(_r(cx, cz, 6) * 3.0):
			var p := _spot(at, lo, hi, fit, taken, cx, cz, 50 + j, 1.25, 0.75)
			if p.x != INF:
				_box(out, Vector3(p.x, y, p.y), d3, 1.25, 0.75, 1.2, COPING_METAL, COPING_METAL.darkened(0.25))
		if _r(cx, cz, 7) < 0.4:
			for j in 1 + int(_r(cx, cz, 8) * 2.0):
				var p := _spot(at, lo, hi, fit, taken, cx, cz, 60 + j, 3.0, 0.6)
				if p.x != INF:
					_box(out, Vector3(p.x, y, p.y), d3, 3.0, 0.6, 0.25, COPING_METAL, SKY)


## A seeded roof place: the k-th random number in [0, 1) of a roof at (x, z), hashed from the
## place rounded to half a metre (a sector's copy of a roof gives the same numbers).
static func _r(x: float, z: float, k: int) -> float:
	var h := (roundi(x * 2.0) * 73856093) ^ (roundi(z * 2.0) * 19349663) ^ (k * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h ^= h >> 16
	return float(h & 0xFFFFFF) / 16777216.0


## A point of the roof for furniture of half size (hw, hd): the first of a few seeded tries that
## fits and keeps 3 m from what is placed; (INF, INF) when none does.
static func _spot(at: Callable, lo: Vector2, hi: Vector2, fit: Callable, taken: Array[Vector2], x: float, z: float,
		k: int, hw: float, hd: float) -> Vector2:
	var r := maxf(hw, hd)
	for i in 12:
		var p: Vector2 = at.call(lerpf(lo.x, hi.x, _r(x, z, k * 13 + i * 2)), lerpf(lo.y, hi.y, _r(x, z, k * 13 + i * 2 + 1)))
		var free := true
		for q in taken:
			if q.distance_to(p) < 3.0 + r:
				free = false
				break
		if free and fit.call(p, hw, hd):
			taken.append(p)
			return p
	return Vector2(INF, INF)


## Whether `at` stands on a flat roof triangle at `y` (within 0.3 m) with no higher part of the
## building over it.
static func _on_level(pos: PackedVector3Array, nrm: PackedVector3Array, grid: Dictionary, at: Vector2, y: float) -> bool:
	var on := false
	for t: int in grid.get(Vector2i(floori(at.x / CELL), floori(at.y / CELL)), []):
		var a := Vector2(pos[t].x, pos[t].z)
		var b := Vector2(pos[t + 1].x, pos[t + 1].z)
		var c := Vector2(pos[t + 2].x, pos[t + 2].z)
		if not Geometry2D.point_is_inside_triangle(at, a, b, c):
			continue
		var top := maxf(pos[t].y, maxf(pos[t + 1].y, pos[t + 2].y))
		if top > y + 0.3:
			return false
		if nrm[t].y > 0.97 and absf((pos[t].y + pos[t + 1].y + pos[t + 2].y) / 3.0 - y) < 0.3:
			on = true
	return on


## A box standing on `foot`: half `hw` along `along`, `hd` across, `h` tall, sides in `colour`,
## the lid in `lid`; its foot sunk `sink` m under the roof (a roof's planes are not quite level).
static func _box(out: Dictionary, foot: Vector3, along: Vector3, hw: float, hd: float, h: float, colour: Color,
		lid: Color, sink: float = 0.3) -> void:
	var across := Vector3(-along.z, 0.0, along.x)
	var base := foot - Vector3.UP * sink
	var up := Vector3.UP * (h + sink)
	var c0 := base - along * hw - across * hd
	var c1 := base + along * hw - across * hd
	var c2 := base + along * hw + across * hd
	var c3 := base - along * hw + across * hd
	var inside := foot + Vector3.UP * (h * 0.5)
	for quad: Array in [[c0, c1], [c1, c2], [c2, c3], [c3, c0]]:
		var p: Vector3 = quad[0]
		var q: Vector3 = quad[1]
		_tri2(out, p, q, q + up, colour, colour, colour, inside)
		_tri2(out, p, q + up, p + up, colour, colour, colour, inside)
	_tri2(out, c0 + up, c1 + up, c2 + up, lid, lid, lid, inside - Vector3.UP * h)
	_tri2(out, c0 + up, c2 + up, c3 + up, lid, lid, lid, inside - Vector3.UP * h)


## A flat roof triangle's outer edges: a parapet on each, and on a tenement a party-wall
## chimney stack on some of the long ones.
static func _flat_edges(out: Dictionary, pos: PackedVector3Array, t: int, grid: Dictionary, y: float, tall: float,
		wall: Color, kind: int, glass: bool, historic: bool) -> void:
	var centre := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
	var high := PARAPET_TALL if tall > 40.0 else PARAPET_H
	var coping := COPING_METAL if glass or kind == 3 else COPING
	for i in 3:
		var p := pos[t + i]
		var q := pos[t + (i + 1) % 3]
		var along := Vector2(q.x - p.x, q.z - p.z)
		var length := along.length()
		if length < PARAPET_MIN_EDGE:
			continue
		var d := along / length
		var mid := (p + q) * 0.5
		var out_dir := Vector2(d.y, -d.x)
		if out_dir.dot(Vector2(mid.x - centre.x, mid.z - centre.z)) < 0.0:
			out_dir = -out_dir
		var probe := Vector2(mid.x, mid.z) + out_dir * PROBE
		if _covered(pos, grid, probe, y - 0.3):
			continue  # the roof goes on (the next triangle), or a taller part's wall stands there
		var inside := mid - Vector3(out_dir.x, 0.0, out_dir.y) * 2.0
		var top := Vector3.UP * high
		_tri2(out, p, q, q + top, wall, wall, coping, inside)
		_tri2(out, p, q + top, p + top, wall, coping, coping, inside)
		parapets += 1
		if kind == 1 and not historic and length >= 5.0:
			var seed := fposmod(mid.x * 0.0913 + mid.z * 0.0571, 1.0)
			if seed < 0.4:
				var foot := mid - Vector3(out_dir.x, 0.0, out_dir.y) * 0.75
				foot.y = y
				_chimney(out, foot, Vector3(d.x, 0.0, d.y), 0.55 + 0.6 * seed, 0.32, 1.5 + 1.2 * seed,
						BRICK if seed < 0.15 else PLASTER)


## A pitched tenement slope: a chimney stack on some of the big ones (a steep mansard face
## too; its dormers were tried on 2026-11-01 and read as black holes from the helicopter on
## the Royal Route's palaces, so they stay the Old Town's).
static func _pitched(out: Dictionary, a: Vector3, b: Vector3, c: Vector3, n: Vector3, place: float) -> void:
	if _area(a, b, c) < 20.0 or place > 0.45:
		return
	var la := (c - b).length()
	var lb := (c - a).length()
	var lc := (b - a).length()
	var foot := (a * la + b * lb + c * lc) / (la + lb + lc)  # the incentre: on the slope
	var across := Vector3(-n.z, 0.0, n.x).normalized()
	_chimney(out, foot, across, 0.5 + 0.5 * place, 0.36, 1.3 + 1.0 * place, BRICK if place < 0.2 else PLASTER)


## A chimney stack standing on `foot` (on its roof), `w` metres along `along` and `d` across,
## `h` over the roof: four sides and a darker cap, its foot sunk under the roof.
static func _chimney(out: Dictionary, foot: Vector3, along: Vector3, w: float, d: float, h: float, colour: Color) -> void:
	var across := Vector3(-along.z, 0.0, along.x)
	var base := foot - Vector3.UP * SINK
	var up := Vector3.UP * (h + SINK)
	var c0 := base - along * w - across * d
	var c1 := base + along * w - across * d
	var c2 := base + along * w + across * d
	var c3 := base - along * w + across * d
	var inside := foot + Vector3.UP * (h * 0.5)
	for quad: Array in [[c0, c1], [c1, c2], [c2, c3], [c3, c0]]:
		var p: Vector3 = quad[0]
		var q: Vector3 = quad[1]
		_tri2(out, p, q, q + up, colour, colour, colour, inside)
		_tri2(out, p, q + up, p + up, colour, colour, colour, inside)
	var cap := colour.darkened(0.3)
	_tri2(out, c0 + up, c1 + up, c2 + up, cap, cap, cap, inside - Vector3.UP * h)
	_tri2(out, c0 + up, c2 + up, c3 + up, cap, cap, cap, inside - Vector3.UP * h)
	chimneys += 1


## Whether a roof triangle of the building lies under `at` at `y` or higher.
static func _covered(pos: PackedVector3Array, grid: Dictionary, at: Vector2, y: float) -> bool:
	for t: int in grid.get(Vector2i(floori(at.x / CELL), floori(at.y / CELL)), []):
		var a := Vector2(pos[t].x, pos[t].z)
		var b := Vector2(pos[t + 1].x, pos[t + 1].z)
		var c := Vector2(pos[t + 2].x, pos[t + 2].z)
		if not Geometry2D.point_is_inside_triangle(at, a, b, c):
			continue
		if maxf(pos[t].y, maxf(pos[t + 1].y, pos[t + 2].y)) >= y:
			return true
	return false


static func _area(a: Vector3, b: Vector3, c: Vector3) -> float:
	return (b - a).cross(c - a).length() * 0.5


static func _key(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0))


## One triangle with a colour per corner, wound and lit so its normal points away from `inside`.
static func _tri2(out: Dictionary, p0: Vector3, p1: Vector3, p2: Vector3, c0: Color, c1: Color, c2: Color,
		inside: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length() < 0.0001:
		return
	nrm = nrm.normalized()
	var mid := (p0 + p1 + p2) / 3.0
	if nrm.dot(mid - inside) < 0.0:
		var tp := p1
		p1 = p2
		p2 = tp
		var tc := c1
		c1 = c2
		c2 = tc
		nrm = -nrm
	(out["pos"] as Array).append_array([p0, p1, p2])
	(out["nrm"] as Array).append_array([nrm, nrm, nrm])
	(out["col"] as Array).append_array([c0, c1, c2])
	triangles += 1
