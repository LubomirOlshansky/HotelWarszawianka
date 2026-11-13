extends RefCounted
## The examination of a mesh's triangles shared by check_mesh_quality.gd (every landmark site) and
## check_places.gd (every place script), moved out of check_mesh_quality.gd on 2026-11-13 without
## changing a result: a stub map with flat ground, a Recorder that stands in for the SurfaceTool
## the builders write to (and reads a finished mesh back into the same arrays), and `examine`,
## which counts the defects a judge looking at a shot misses:
##   - ZFIGHT: same-facing triangles on one plane (within 2 cm) that overlap by more than
##     0.01 m^2 flicker when the camera moves;
##   - DEGENERATE: zero-area triangles (< 1e-5 m^2) and BADNORMAL: triangles whose declared
##     normal disagrees with their geometry (|cos| < 0.5), which light wrongly;
##   - FLOAT: connected parts (welded to 5 cm) that touch neither the ground (y <= 0.2) nor the
##     box of a part that does (grown 10 cm): detail hanging in the air.
##     A site in ON_ROOF stands on a mapped roof: its lowest level counts as its ground.
##   - plain: triangles without a landmark material code (UV2.x < 2).
## The caller owns the ratchets (BUDGET, KNOWN) and the verdict.

const MapBuilderRef := preload("res://scripts/map_builder.gd")

const ZFIGHT_AREA := 0.01
const ZFIGHT_PLANE := 0.02
const ZFIGHT_WINDOW := 0.3  ## coarse sort window; _coplanar decides
const DEGENERATE_AREA := 1.0e-5
const WELD := 20.0  ## vertices closer than 1/WELD m are one
const TOUCH := 0.1
const GROUND := 0.2
## Sites that stand on a mapped building's roof (the building is the map's, not the site's): their
## parts are supported by the site's lowest level instead of the ground (LORETKA's terrace on
## HOTEL PIURE, F 2026-11-01).
const ON_ROOF := ["loretka"]
## Sites on several mapped roofs (Varso Place's terraces on Varso 1 and 2, Krajobraz K3): a part
## is held up when its bottom lies on a mapped building's top under its middle (within GROUND).
const ON_ROOFS := ["varso_place"]
## The map's data (centrum.json), for the sites on mapped roofs.
var _data: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	_data = data


## The city as the builders see it, on flat ground (tops at 0, the sunken places 3.4 m under it).
## A Node3D, so a place script (`var map: Node3D`) takes it; `data` and `_terrain` are what the
## places read besides the heights.
class StubMap extends Node3D:
	const ROOF_CELL := 4.0
	var _roof_x0 := 0.0
	var _roof_z0 := 0.0
	var _roof_nx := 0
	var _roof_nz := 0
	var _wall_faces := PackedVector3Array()
	var data: Dictionary = {}
	var _terrain := {"step": 10.0}

	## The sunken places (map_builder SUNKEN) on the flat ground: tops at 0, floors 3.4 m under it.
	var _sunk: Array[Dictionary] = []

	func _init() -> void:
		for e: Dictionary in MapBuilderRef.SUNKEN:
			var f := e.duplicate()
			if not is_nan(float(f["hb"])):
				f["hb"] = -3.4
			if f.has("rim"):
				f["rim"] = 0.0
			_sunk.append(MapBuilderRef.sunk_entry(f, 0.0, 10.0))

	## map_builder.gd's collider by class (step 1, solid classes): here one bag, as before.
	func _solid(_cls: StringName, faces: PackedVector3Array) -> void:
		_wall_faces.append_array(faces)

	func _grid_height(_x: float, _z: float) -> float:
		return 0.0

	func sunk_floor(x: float, z: float, _grown := false) -> float:
		for sk: Dictionary in _sunk:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), sk["ring"]):
				return MapBuilderRef.sunk_level(sk, Vector2(x, z))
		return INF

	func sunk_level(sk: Dictionary, p: Vector2) -> float:
		return MapBuilderRef.sunk_level(sk, p)

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func platform_top(_x: float, _z: float) -> float:
		return NAN

	func tunnel_floor_under(_x: float, _z: float) -> float:
		return NAN

	func _roof_triangle(_a: Vector3, _b: Vector3, _c: Vector3, _is_roof: bool, _col := Color(0, 0, 0, 0)) -> void:
		pass


class Recorder:
	var pos := PackedVector3Array()
	var norms := PackedVector3Array()
	var codes := PackedFloat32Array()
	var _uv2 := Vector2.ZERO
	var _n := Vector3.UP

	func set_color(_c: Color) -> void:
		pass

	func set_normal(n: Vector3) -> void:
		_n = n

	func set_uv(_uv: Vector2) -> void:
		pass

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		pos.append(p)
		norms.append(_n)
		codes.append(_uv2.x)

	## Reads a finished mesh back: positions, normals and UV2.x per vertex, in index order.
	func add_mesh(mesh: Mesh) -> void:
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var p: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var n: Variant = a[Mesh.ARRAY_NORMAL]
			var u2: Variant = a[Mesh.ARRAY_TEX_UV2]
			var idx: Variant = a[Mesh.ARRAY_INDEX]
			var count: int = (idx as PackedInt32Array).size() if idx != null else p.size()
			for k in count:
				var i: int = (idx as PackedInt32Array)[k] if idx != null else k
				pos.append(p[i])
				norms.append((n as PackedVector3Array)[i] if n != null else Vector3.ZERO)
				codes.append((u2 as PackedVector2Array)[i].x if u2 != null else 0.0)


## The defects of the recorded triangles (counts and where): see the header.
func examine(key: String, rec: Recorder) -> Dictionary:
	var tris := rec.pos.size() / 3
	var out := {"tris": tris, "zfight": 0, "degenerate": 0, "badnormal": 0, "float": 0, "plain": 0,
			"at_zfight": [], "at_degenerate": [], "at_badnormal": [], "at_float": []}
	var gn: Array[Vector3] = []  # geometric normal per triangle (zero for a degenerate one)
	var live: Array[int] = []
	for t in tris:
		var a := rec.pos[t * 3]
		var b := rec.pos[t * 3 + 1]
		var c := rec.pos[t * 3 + 2]
		if rec.codes[t * 3] < 2.0:
			out["plain"] += 1
		var cr := (b - a).cross(c - a)
		var area := cr.length() * 0.5
		if area < DEGENERATE_AREA:
			out["degenerate"] += 1
			out["at_degenerate"].append(a)
			gn.append(Vector3.ZERO)
			continue
		var n := cr.normalized()
		gn.append(n)
		live.append(t)
		var declared := rec.norms[t * 3]
		if declared.length() > 0.001 and absf(n.dot(declared.normalized())) < 0.5:
			out["badnormal"] += 1
			out["at_badnormal"].append(a)
	_zfight(rec, gn, live, out)
	_floating(rec, live, out, key in ON_ROOF, key in ON_ROOFS)
	return out


func _zfight(rec: Recorder, gn: Array[Vector3], live: Array[int], out: Dictionary) -> void:
	# Buckets of near-equal plane normals (up to sign); inside one, triangles sorted by plane
	# distance are compared while their planes lie within ZFIGHT_PLANE.
	var buckets := {}
	# Plane distances are measured from the site's own centre: with positions 1500 m from the
	# origin, a 1e-5 difference between two near-equal normals alone shifts a distance by 1.5 cm.
	var origin := Vector3.ZERO
	if not live.is_empty():
		var lo := rec.pos[live[0] * 3]
		var hi := lo
		for t in live:
			for k in 3:
				lo = lo.min(rec.pos[t * 3 + k])
				hi = hi.max(rec.pos[t * 3 + k])
		origin = (lo + hi) * 0.5
	for t in live:
		var n := gn[t]
		var s := 1.0
		if n.x < -0.01 or (absf(n.x) <= 0.01 and (n.y < -0.01 or (absf(n.y) <= 0.01 and n.z < 0.0))):
			s = -1.0
		var cn := n * s
		var key := Vector3i(roundi(cn.x * 25.0), roundi(cn.y * 25.0), roundi(cn.z * 25.0))
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append([(rec.pos[t * 3] - origin).dot(cn), t, s])
	for key: Vector3i in buckets:
		var list: Array = buckets[key]
		if list.size() < 2:
			continue
		list.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for i in list.size():
			for j in range(i + 1, list.size()):
				if list[j][0] - list[i][0] > ZFIGHT_WINDOW:
					break
				if list[i][2] != list[j][2] and gn[list[i][1]].dot(gn[list[j][1]]) < 0.0:
					# opposite facing: back to back, culled, no fight
					if (list[i][2] * list[j][2]) < 0.0:
						continue
				if not _coplanar(rec, list[i][1], list[j][1], gn[list[i][1]], gn[list[j][1]]):
					continue
				if _overlap(rec, list[i][1], list[j][1], gn[list[i][1]]) > ZFIGHT_AREA:
					out["zfight"] += 1
					out["at_zfight"].append(rec.pos[list[i][1] * 3])


## The exact test behind the sorted window: every vertex of each triangle within ZFIGHT_PLANE
## of the other's plane.
func _coplanar(rec: Recorder, ta: int, tb: int, na: Vector3, nb: Vector3) -> bool:
	for k in 3:
		if absf((rec.pos[tb * 3 + k] - rec.pos[ta * 3]).dot(na)) > ZFIGHT_PLANE:
			return false
		if absf((rec.pos[ta * 3 + k] - rec.pos[tb * 3]).dot(nb)) > ZFIGHT_PLANE:
			return false
	return true


func _overlap(rec: Recorder, ta: int, tb: int, n: Vector3) -> float:
	if gn_dot_sign(rec, ta, tb) < 0.0:
		return 0.0  # facing opposite ways: only one is drawn
	var ax := absf(n.x)
	var ay := absf(n.y)
	var az := absf(n.z)
	var drop := 0 if (ax >= ay and ax >= az) else (1 if ay >= az else 2)
	var pa := _flat(rec, ta, drop)
	var pb := _flat(rec, tb, drop)
	var box_a := Rect2(pa[0], Vector2.ZERO).expand(pa[1]).expand(pa[2])
	var box_b := Rect2(pb[0], Vector2.ZERO).expand(pb[1]).expand(pb[2])
	if not box_a.intersects(box_b):
		return 0.0
	var area := 0.0
	for poly in Geometry2D.intersect_polygons(pa, pb):
		area += _poly_area(poly)
	return area


func gn_dot_sign(rec: Recorder, ta: int, tb: int) -> float:
	var na := (rec.pos[ta * 3 + 1] - rec.pos[ta * 3]).cross(rec.pos[ta * 3 + 2] - rec.pos[ta * 3])
	var nb := (rec.pos[tb * 3 + 1] - rec.pos[tb * 3]).cross(rec.pos[tb * 3 + 2] - rec.pos[tb * 3])
	return na.dot(nb)


func _flat(rec: Recorder, t: int, drop: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 3:
		var v := rec.pos[t * 3 + k]
		match drop:
			0:
				p.append(Vector2(v.y, v.z))
			1:
				p.append(Vector2(v.x, v.z))
			_:
				p.append(Vector2(v.x, v.y))
	return p


func _poly_area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return absf(a) * 0.5


func _floating(rec: Recorder, live: Array[int], out: Dictionary, on_roof := false, on_roofs := false) -> void:
	# Union-find over welded vertices.
	var parent := {}
	var find := func(k: Vector3i) -> Vector3i:
		var r := k
		while parent[r] != r:
			parent[r] = parent[parent[r]]
			r = parent[r]
		return r
	var kv := func(v: Vector3) -> Vector3i:
		return Vector3i(roundi(v.x * WELD), roundi(v.y * WELD), roundi(v.z * WELD))
	for t in live:
		var ks: Array[Vector3i] = []
		for k in 3:
			var key: Vector3i = kv.call(rec.pos[t * 3 + k])
			if not parent.has(key):
				parent[key] = key
			ks.append(key)
		for k in [1, 2]:
			var ra: Vector3i = find.call(ks[0])
			var rb: Vector3i = find.call(ks[k])
			if ra != rb:
				parent[ra] = rb
	var boxes := {}
	for t in live:
		var root: Vector3i = find.call(kv.call(rec.pos[t * 3]))
		var bb: AABB
		if boxes.has(root):
			bb = boxes[root]
		else:
			bb = AABB(rec.pos[t * 3], Vector3.ZERO)
		for k in 3:
			bb = bb.expand(rec.pos[t * 3 + k])
		boxes[root] = bb
	var roots: Array = boxes.keys()
	var supported := {}
	var base := 0.0
	if on_roof:
		base = INF
		for r in roots:
			base = minf(base, (boxes[r] as AABB).position.y)
	for r in roots:
		var bb: AABB = boxes[r]
		if bb.position.y <= base + GROUND or on_roofs and _on_mapped_roof(bb):
			supported[r] = true
	var grew := true
	while grew:
		grew = false
		for r in roots:
			if supported.has(r):
				continue
			for s in supported:
				if (boxes[s] as AABB).grow(TOUCH).intersects(boxes[r]):
					supported[r] = true
					grew = true
					break
	for r in roots:
		if not supported.has(r):
			out["float"] += 1
			out["at_float"].append((boxes[r] as AABB).position)


## Whether a part's bottom lies on the top of a mapped building under its middle (ON_ROOFS; the
## stub's ground is at 0, so a top is the building's height).
func _on_mapped_roof(bb: AABB) -> bool:
	var c := Vector2(bb.position.x + bb.size.x * 0.5, bb.position.z + bb.size.z * 0.5)
	for bld: Dictionary in _data.get("buildings", []):
		if absf(float(bld["h"]) - bb.position.y) > GROUND + 0.15:
			continue
		var q := PackedVector2Array()
		var p: Array = bld["p"]
		for i in range(0, p.size() - 1, 2):
			q.append(Vector2(p[i], p[i + 1]))
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(c, q):
			return true
	return false
