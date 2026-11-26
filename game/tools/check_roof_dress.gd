extends SceneTree
## The roofs lane's geometry (scripts/roof_dress.gd, docs/design/roofs.md RF2-RF3): a flat
## roof gets a parapet on each outer edge and none inside (two roof polygons meeting, a
## T-junction) nor round a plant box's top; a small roof gets none; a tenement's flat roof
## gets party-wall chimneys, a slab's none; every piece stands
## on or over the roof and the budget holds (two triangles a parapet edge).
##   godot --headless --path game --script res://tools/check_roof_dress.gd

var failed := 0
var pos := PackedVector3Array()
var nrm := PackedVector3Array()
var col := PackedColorArray()
var uv := PackedVector2Array()


func _initialize() -> void:
	# A 20 x 12 m block, 15 m tall: four walls, a flat roof in two polygons (split at x = 8,
	# the east one triangulated with a T-junction on the west polygon's edge), a plant box.
	var y := 15.0
	_wall(Vector3(0, 0, 0), Vector3(20, 0, 0), y)
	_wall(Vector3(20, 0, 0), Vector3(20, 0, 12), y)
	_wall(Vector3(20, 0, 12), Vector3(0, 0, 12), y)
	_wall(Vector3(0, 0, 12), Vector3(0, 0, 0), y)
	_flat(Vector3(0, y, 0), Vector3(8, y, 0), Vector3(8, y, 12))
	_flat(Vector3(0, y, 0), Vector3(8, y, 12), Vector3(0, y, 12))
	_flat(Vector3(8, y, 0), Vector3(20, y, 0), Vector3(8, y, 6))
	_flat(Vector3(20, y, 0), Vector3(20, y, 12), Vector3(8, y, 6))
	_flat(Vector3(8, y, 6), Vector3(20, y, 12), Vector3(8, y, 12))
	# The plant box: 2 x 2 m, 1.5 m tall, sides with no window UV.
	var b := [Vector3(10, y, 4), Vector3(12, y, 4), Vector3(12, y, 6), Vector3(10, y, 6)]
	for i in 4:
		var p: Vector3 = b[i]
		var q: Vector3 = b[(i + 1) % 4]
		_add(p, q, q + Vector3.UP * 1.5, Vector3(0, 0, -1), Vector2(-1, -1))
		_add(p, q + Vector3.UP * 1.5, p + Vector3.UP * 1.5, Vector3(0, 0, -1), Vector2(-1, -1))
	var top := Vector3.UP * 1.5
	_flat(b[0] + top, b[1] + top, b[2] + top)
	_flat(b[0] + top, b[2] + top, b[3] + top)

	var before := RoofDress.parapets
	var slab := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 0, false)  # kind 0: parapets only
	var edges := RoofDress.parapets - before
	_expect(edges == 6, "a 20 x 12 m roof's outer edges, split at x = 8 and the T-junction: 6 parapets, got %d" % edges)
	_expect((slab["pos"] as PackedVector3Array).size() == edges * 6, "two triangles a parapet edge, no chimneys on a slab")
	for p: Vector3 in slab["pos"]:
		_expect(p.y >= y - 0.01 and p.y <= y + RoofDress.PARAPET_H + 0.01, "a parapet stands on its roof")
		_expect(p.x < 0.01 or p.x > 19.99 or p.z < 0.01 or p.z > 11.99, "a parapet stands on the outer edge, not round the box (%s)" % p)
	var chimneys := RoofDress.chimneys
	var tenement := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 1, false)
	_expect(RoofDress.chimneys > chimneys, "a tenement's flat roof gets party-wall chimneys")
	_expect((tenement["pos"] as PackedVector3Array).size() > (slab["pos"] as PackedVector3Array).size(), "the chimneys are drawn")
	for p: Vector3 in tenement["pos"]:
		_expect(p.y >= y - RoofDress.SINK - 0.01 and p.y <= y + 3.0, "a chimney stands on its roof")
	var old := RoofDress.chimneys
	RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 1, true)
	_expect(RoofDress.chimneys == old, "the Old Town's roofs are old_town_roofs.gd's")

	# Furniture (PR 3): a post-war slab gets lift rooms, an office HVAC units, a historic roof nothing extra.
	var rooms := RoofDress.rooms
	var post := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 2, false)
	_expect((post["pos"] as PackedVector3Array).size() > (slab["pos"] as PackedVector3Array).size(), "the slab's furniture is drawn")
	for p: Vector3 in post["pos"]:
		_expect(p.y <= y + 6.0 and p.x > -0.01 and p.x < 20.01 and p.z > -0.01 and p.z < 12.01, "slab furniture stays on its roof (%s)" % p)
	var office := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 3, false)
	var hvac := 0
	for p: Vector3 in office["pos"]:
		if p.y > y + 1.1 and p.y < y + 1.3:
			hvac += 1
	_expect(hvac > 0, "an office roof gets an HVAC unit")
	var hist := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 2, true)
	_expect((hist["pos"] as PackedVector3Array).size() == (slab["pos"] as PackedVector3Array).size(), "a historic roof gets nothing added")
	var tiny := RoofDress.rooms
	RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 0, false)
	_expect(RoofDress.rooms == tiny, "kind 0 gets no rooms")

	# A small roof (6 x 6 m) takes none.
	var small_from := pos.size()
	_flat(Vector3(100, 9, 0), Vector3(106, 9, 0), Vector3(106, 9, 6))
	_flat(Vector3(100, 9, 0), Vector3(106, 9, 6), Vector3(100, 9, 6))
	var small := RoofDress.building(pos, nrm, col, uv, small_from, pos.size(), 2, false)
	_expect((small["pos"] as PackedVector3Array).is_empty(), "a 36 m² roof takes no parapet and no furniture")

	# A steep tenement face (a mansard, 60 degrees): only chimneys, never under it.
	var steep_from := pos.size()
	var rise := tan(deg_to_rad(60.0)) * 4.0
	_slope(Vector3(200, 20, 0), Vector3(212, 20, 0), Vector3(212, 20 + rise, -4), Vector3(200, 20 + rise, -4))
	var steep := RoofDress.building(pos, nrm, col, uv, steep_from, pos.size(), 1, false)
	for p: Vector3 in steep["pos"]:
		_expect(p.y >= 20.0 - RoofDress.SINK - 0.01 and p.y <= 20.0 + rise + 3.0, "a mansard's chimney stands on it")

	# The plant box (10..12, 4..6) stays clear of every piece of furniture.
	for kind in [2, 3]:
		var dressed := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), kind, false)
		for p: Vector3 in dressed["pos"]:
			_expect(not (p.x > 9.5 and p.x < 12.5 and p.z > 3.5 and p.z < 6.5), "no furniture on or by a plant box (%s)" % p)

	# A 40 x 14 m slab turned 30 degrees, in two triangles: the furniture lies square to its
	# edges, INSET inside them, its feet under the roof, and the same whatever the order.
	var turn := deg_to_rad(30.0)
	var rot_from := pos.size()
	_rect(Vector2(400, 0), turn, 40.0, 14.0, 14.76)
	var rot := RoofDress.building(pos, nrm, col, uv, rot_from, pos.size(), 2, false)
	_expect(RoofDress.rooms > rooms, "a 560 m2 slab roof gets a lift or stair room")
	var ax := Vector2.RIGHT.rotated(turn)
	var feet := 0
	var rp: PackedVector3Array = rot["pos"]
	var rn: PackedVector3Array = rot["nrm"]
	for i in rp.size():
		var p := rp[i]
		var q := Vector2(p.x - 400.0, p.z).rotated(-turn)
		_expect(p.y <= 14.76 + 3.0, "slab furniture stays low (%s)" % p)
		if p.y < 14.76 - 0.1:  # a foot, sunk under the roof
			feet += 1
			_expect(absf(q.x) <= 20.0 - RoofDress.INSET + 0.01 and absf(q.y) <= 7.0 - RoofDress.INSET + 0.01,
					"a foot stands INSET inside the edges (%s)" % q)
		var n := Vector2(rn[i].x, rn[i].z)
		if absf(rn[i].y) < 0.01 and n.length() > 0.5 and p.y < 14.76 + 2.8:
			var d := absf(n.normalized().dot(ax))
			_expect(d > 0.999 or d < 0.001, "a box side is square to the roof's edges (%s)" % n)
	_expect(feet > 0, "the turned slab gets furniture standing on it")
	var flipped_from := pos.size()
	for t in range(pos.size() - 3, rot_from - 3, -3):
		_add(pos[t], pos[t + 1], pos[t + 2], nrm[t], uv[t])
	var flip := RoofDress.building(pos, nrm, col, uv, flipped_from, pos.size(), 2, false)
	_expect(_sum(flip["pos"]).is_equal_approx(_sum(rot["pos"])) and (flip["pos"] as PackedVector3Array).size() == rp.size(),
			"the same roof in another triangle order gets the same furniture")

	# A small higher part over a big roof (a stair tower): nothing under it, nothing by it.
	var tower_from := pos.size()
	_rect(Vector2(615, 10), 0.0, 30.0, 20.0, 10.0)
	_rect(Vector2(603, 3), 0.0, 6.0, 6.0, 14.0)
	var tw := RoofDress.building(pos, nrm, col, uv, tower_from, pos.size(), 3, false)
	for p: Vector3 in tw["pos"]:
		if p.y < 10.0 + 2.0 and p.y > 9.0:
			_expect(not (p.x < 606.0 + 0.5 and p.z < 6.0 + 0.5) or p.y > 9.99 and p.y < 10.71, "no furniture under a higher part (%s)" % p)

	# The budget and the variety: furniture on one big roof stays under 240 triangles, and some
	# places get masts, a dish or skylights.
	var masts := RoofDress.antennas
	var sky := false
	for i in 24:
		var from := pos.size()
		_rect(Vector2(1000 + i * 97, 300 + i * 41), 0.2 * i, 60.0, 20.0, 20.0)
		var before_t := RoofDress.triangles
		var before_p := RoofDress.parapets
		RoofDress.building(pos, nrm, col, uv, from, pos.size(), 2 + i % 2, false)
		var extra := RoofDress.triangles - before_t - 2 * (RoofDress.parapets - before_p)
		_expect(extra <= 240, "one roof's furniture stays under 240 triangles, got %d" % extra)
		if i % 2 == 1:
			var o := RoofDress.building(pos, nrm, col, uv, from, pos.size(), 3, false)
			for c: Color in o["col"]:
				if c.is_equal_approx(RoofDress.SKY):
					sky = true
	_expect(RoofDress.antennas > masts, "some slab roofs get a TV mast or a dish")
	_expect(sky, "some office roofs get skylights")

	if failed == 0:
		print("check_roof_dress: OK")
	quit(failed)


## A flat rectangle roof of two triangles: centre `c`, turned `ang`, `l` x `w` m, at `y`.
func _rect(c: Vector2, ang: float, l: float, w: float, y: float) -> void:
	var k: Array[Vector3] = []
	for s: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var q := c + Vector2(s.x * l * 0.5, s.y * w * 0.5).rotated(ang)
		k.append(Vector3(q.x, y, q.y))
	_flat(k[0], k[1], k[2])
	_flat(k[0], k[2], k[3])


func _sum(ps: PackedVector3Array) -> Vector3:
	var s := Vector3.ZERO
	for p in ps:
		s += p
	return s


func _add(a: Vector3, b: Vector3, c: Vector3, n: Vector3, u: Vector2) -> void:
	pos.append_array([a, b, c])
	nrm.append_array([n, n, n])
	col.append_array([Color("#b8a58c"), Color("#b8a58c"), Color("#b8a58c")])
	uv.append_array([u, u, u])


func _wall(a: Vector3, b: Vector3, h: float) -> void:
	var n := Vector3((b - a).z, 0, -(b - a).x).normalized()
	_add(a, b, b + Vector3.UP * h, n, Vector2(0, 0))
	_add(a, b + Vector3.UP * h, a + Vector3.UP * h, n, Vector2(0, 0))


func _flat(a: Vector3, b: Vector3, c: Vector3) -> void:
	_add(a, b, c, Vector3.UP, Vector2(-1, -1))


func _slope(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	_add(a, b, c, n, Vector2(-1, -1))
	_add(a, c, d, n, Vector2(-1, -1))


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_roof_dress: FAIL: ", what)
