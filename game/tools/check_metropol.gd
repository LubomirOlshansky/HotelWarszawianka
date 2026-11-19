extends SceneTree
## Hotel Metropol's roof sign METROPOLKA (landmarks/srodmiescie.gd `_build_metropol_sign`), checked
## headless from the committed map data alone (map/centrum.json, flat ground; no sectors, LoD2 or
## renderer, so it runs in CI). The sign went wrong again and again (2026-10-31 #101: floating on an
## edge; 2026-11-07 a rebuild that stayed a patch; 2026-11-11 #639; 2026-11-19 F's teaser render, an
## old build showing the old sign, and on main the light box going as dark as the roof at night):
## this pins what F's photos show, so the next change that breaks it fails here.
##   - the site is found and built, and it emits exactly one METROPOLKA;
##   - no street block (`blk_*`, data/street_blocks) stands on the hotel too: #495's block of the same
##     outline was a second model whose roof-edge panel covered the letters (the root cause, 2026-11-19);
##   - the sign faces Marszałkowska (the outline's longest edge's outward side) and stands on the
##     hotel's real (diagonal) outline, on its street face: not on the outline's bounding box;
##   - it stands over the main roof, on a light box (M_LAMP, so it is lit at night) whose bottom is
##     over the slab's top;
##   - the letters' row (map_builder `_build_landmark_signs`: the sign's point is the middle of the
##     letters' bottom edge, plus half their height up and 0.4 m out) lies inside the box's face,
##     no more than 0.25 m in front of it, and no wider than the box.
## Prints `check_metropol: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_metropol.gd

const Landmarks := preload("res://scripts/landmarks.gd")
const Neon := preload("res://scripts/neon_signs.gd")
const Fakes := preload("res://tools/fakes.gd")
const WORD := "METROPOLKA"
## map_builder `_build_landmark_signs`: how far out of the sign's point the letters are drawn.
const SIGN_OUT := 0.4

var problems: Array[String] = []


## A stand-in for the city's building surface: keeps what the landmark emits.
class Recorder:
	var pos := PackedVector3Array()
	var codes := PackedFloat32Array()
	var _uv2 := Vector2.ZERO

	func set_color(_c: Color) -> void:
		pass

	func set_normal(_n: Vector3) -> void:
		pass

	func set_uv(_uv: Vector2) -> void:
		pass

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		pos.append(p)
		codes.append(_uv2.x)


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_metropol: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := Fakes.BuilderMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	_check(marks, map)
	map.free()
	if problems.is_empty():
		print("check_metropol: OK")
		quit(0)
	else:
		print("check_metropol: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


## The outward normal of edge a-b of ring (facade_kit's `_out`).
func _out(ring: PackedVector2Array, a: Vector2, b: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var nn := Vector2(e.y, -e.x)
	return -nn if Geometry2D.is_polygon_clockwise(ring) else nn


func _check(marks, map: Fakes.BuilderMap) -> void:
	var k := -1
	for i in marks.sites.size():
		if marks.sites[i]["key"] == "metropolsign":
			k = i
	if k < 0:
		problems.append("metropolsign: site not found (Hotel Metropol's outline gone from the map?)")
		return
	var s: Dictionary = marks.sites[k]
	var outline: PackedVector2Array = s["outline"]
	# One model only: no street block (data/street_blocks, `blk_*`) may stand on the hotel too. #495's
	# block of this outline drew a second hotel whose roof-edge panel covered the letters' lower half.
	var probes: Array[Vector2] = []
	for i in outline.size():
		var q := outline[i].lerp(outline[(i + 1) % outline.size()], 0.5)
		var inward := -_out(outline, outline[i], outline[(i + 1) % outline.size()])
		if Geometry2D.is_point_in_polygon(q + inward * 2.0, outline):
			probes.append(q + inward * 2.0)
	for o: Dictionary in marks.sites:
		if not o.has("block"):
			continue
		for z: PackedVector2Array in o["zone"]:
			for q in probes:
				if Geometry2D.is_point_in_polygon(q, z):
					problems.append("street block %s also stands on the hotel (at %s): two models, one over the sign" % [o["key"], q.round()])
					break
	var rec := Recorder.new()
	marks.st = rec
	marks._pick.resize(map._roof_nx * map._roof_nz * 2)
	marks._pick.fill(0)
	marks._id = k + 1
	marks.signs.clear()
	marks._build_metropol_sign(s)
	marks._id = 0
	var mine: Array = marks.signs.filter(func(sg: Array) -> bool: return sg[0] == WORD)
	if mine.size() != 1:
		problems.append("%d %s signs, want 1" % [mine.size(), WORD])
		return
	var sign: Array = mine[0]
	var at: Vector3 = sign[1]
	var n := Vector2((sign[2] as Vector3).x, (sign[2] as Vector3).z).normalized()
	var scale: float = sign[3]
	var plan := Vector2(at.x, at.z)

	# Faces Marszałkowska: the outline's longest edge's outward side.
	var ref_len := 0.0
	var ref_out := Vector2.ZERO
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		if a.distance_to(b) > ref_len:
			ref_len = a.distance_to(b)
			var e := (b - a).normalized()
			ref_out = Vector2(e.y, -e.x) if not Geometry2D.is_polygon_clockwise(outline) else Vector2(-e.y, e.x)
	if n.dot(ref_out) < 0.9:
		problems.append("the sign faces %s, not the street side %s" % [n, ref_out])

	# On the real outline: its point within 1.5 m of the outline's nearest edge, not on the box.
	var near := INF
	for i in outline.size():
		var q := Geometry2D.get_closest_point_to_segment(plan, outline[i], outline[(i + 1) % outline.size()])
		near = minf(near, q.distance_to(plan))
	if near > 1.5:
		problems.append("the sign stands %.1f m off the hotel's outline (on its bounding box?)" % near)

	# The box: M_LAMP triangles over the canopy's lit strip (which is at the ground floor).
	var along := Vector2(-n.y, n.x)
	var lo := Vector3(INF, INF, INF)  # (u along the face, y, v out of it) round the sign's point
	var hi := Vector3(-INF, -INF, -INF)
	var roof_top := -INF  # the highest other point inside the box
	for t in rec.pos.size() / 3:
		var c := (rec.pos[t * 3] + rec.pos[t * 3 + 1] + rec.pos[t * 3 + 2]) / 3.0
		if absf(rec.codes[t * 3] - Landmarks.M_LAMP) < 0.01 and c.y > at.y - 5.0:
			for j in 3:
				var p := rec.pos[t * 3 + j]
				var d := Vector2(p.x, p.z) - plan
				var l := Vector3(d.dot(along), p.y, d.dot(n))
				lo = lo.min(l)
				hi = hi.max(l)
	if lo.x == INF:
		problems.append("no light box (M_LAMP) behind the letters: at night they float on the dark")
		return
	# Nothing else of the hotel (a roof structure) may stand inside the box.
	for t in rec.pos.size() / 3:
		if absf(rec.codes[t * 3] - Landmarks.M_LAMP) < 0.01:
			continue
		for j in 3:
			var p := rec.pos[t * 3 + j]
			var d := Vector2(p.x, p.z) - plan
			var u := d.dot(along)
			var w := d.dot(n)
			if u > lo.x + 0.05 and u < hi.x - 0.05 and w > lo.z + 0.05 and w < hi.z - 0.05 and p.y > lo.y + 0.05 and p.y < hi.y - 0.05:
				roof_top = maxf(roof_top, p.y)
	if roof_top > -INF:
		problems.append("the hotel's roof (%.1f m) stands inside the light box (%.1f..%.1f m)" % [roof_top, lo.y, hi.y])

	# The letters inside the box's face.
	var th := Neon.ROW_H * Neon.PIXEL * scale
	var half_w := Neon.length_of(WORD) * scale * 0.5
	var y0 := at.y
	var y1 := at.y + th
	var v := SIGN_OUT  # out of the sign's point, which is v 0 in this frame
	if y0 < lo.y - 0.01 or y1 > hi.y + 0.01:
		problems.append("the letters (%.2f..%.2f m) stick out of the box (%.2f..%.2f m)" % [y0, y1, lo.y, hi.y])
	if half_w > hi.x + 0.01 or -half_w < lo.x - 0.01:
		problems.append("the letters (%.1f m wide) are wider than the box (%.1f m)" % [half_w * 2.0, hi.x - lo.x])
	if v < hi.z - 0.01 or v > hi.z + 0.25:
		problems.append("the letters stand %.2f m out of the box's face (want 0..0.25 m)" % (v - hi.z))
	print("check_metropol: box %.1f x %.1f m at %.1f m, letters %.2f..%.2f m, %.2f m before its face, %.1f m off the outline" % [
			hi.x - lo.x, hi.y - lo.y, lo.y, y0, y1, v - hi.z, near])
