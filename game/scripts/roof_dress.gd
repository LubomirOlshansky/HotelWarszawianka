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
	var levels := {}
	var grid := {}
	for t in range(t0, t1, 3):
		if nrm[t].y < 0.3:
			continue
		if box_verts.has(_key(pos[t])) and box_verts.has(_key(pos[t + 1])) and box_verts.has(_key(pos[t + 2])):
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
