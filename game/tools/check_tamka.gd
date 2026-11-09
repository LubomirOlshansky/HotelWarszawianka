extends SceneTree
## Tamka from F's photos (scripts/tamka.gd, spec docs/landmarks/specs/tamka.md), headless, from the
## committed map data (map/centrum.json) and data/dialogue.json:
##   1. the houses: every photographed house's point picks its own plaster and style; a house off
##      Tamka gets nothing; Tamka's other houses a plaster from PASTELS;
##   2. KEBONAFIDE's walk: every point on the map clear of the houses, within 9 m of Tamka's centre
##      line, the walk 120 m or more; he talks to a slow car near him, never to a fast one or the
##      helicopter;
##   3. his mesh under 700 triangles;
##   4. his lines: 10 or more for the street, 3 or more tagged `car`, each with an English half,
##      at most 75 characters in Polish, no real brand (data/brand_denylist.json);
##   5. the footbridge's ends lie on the mapped footway that crosses Tamka by the castle;
##   6. tamka.gd's CENTRE is the map's Tamka (a re-bake that moves the street must update it);
##   7. Powiśle's photographed houses (powisle_houses.gd): each point inside one mapped house, in
##      AREA, picking its own look; each front a unit-ish normal that one of its walls faces.
## Prints "check_tamka: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_tamka.gd

const Tamka := preload("res://scripts/tamka.gd")
const PowisleHouses := preload("res://scripts/powisle_houses.gd")

var problems: Array[String] = []


func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_houses()
	var walk := _walk(data)
	var tris := _mesh()
	var lines := _lines()
	_bridge(data)
	_centre(data)
	_powisle(data)
	if problems.is_empty():
		print("check_tamka: OK (%d Tamka + %d Powiśle photo houses, walk %.0f m, walker %d triangles, %d lines)" % [
				Tamka.HOUSES.size(), PowisleHouses.HOUSES.size(), walk, tris, lines])
		quit(0)
	else:
		for p in problems:
			print("check_tamka: " + p)
		quit(1)


func _square(at: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(-r, -r), at + Vector2(r, -r), at + Vector2(r, r), at + Vector2(-r, r)])


func _houses() -> void:
	for h: Array in Tamka.HOUSES:
		var got := Tamka.house(_square(Vector2(float(h[0]), float(h[1])), 4.0), true, 17)
		if got.is_empty() or got["plaster"] != Color(h[2]) or got["style"] != h[3]:
			problems.append("house at (%s, %s) not picked" % [h[0], h[1]])
	if not Tamka.house(_square(Vector2(-2000.0, 900.0), 5.0), false, 3).is_empty():
		problems.append("a house off Tamka got a look")
	var other := Tamka.house(_square(Vector2(-2000.0, 900.0), 5.0), true, 42)
	if other.is_empty() or not (Color(other["plaster"]).to_html(false) in Tamka.PASTELS.map(func(c: String) -> String: return c.trim_prefix("#"))):
		problems.append("a Tamka house got no pastel")


func _walk(data: Dictionary) -> float:
	var segs := []
	for r: Dictionary in data["roads"]:
		if str(r.get("name", "")) == "Tamka":
			var p: Array = r["p"]
			for i in range(0, p.size() - 3, 2):
				segs.append([Vector2(p[i], p[i + 1]), Vector2(p[i + 2], p[i + 3])])
	var polys := []
	for b: Dictionary in data["buildings"]:
		var p: Array = b["p"]
		if absf(float(p[0]) - 100.0) < 200.0 and absf(float(p[1]) + 360.0) < 120.0:
			var poly := PackedVector2Array()
			for i in range(0, p.size() - 1, 2):
				poly.append(Vector2(p[i], p[i + 1]))
			polys.append(poly)
	var length := 0.0
	for i in Tamka.WALK.size():
		var at: Vector2 = Tamka.WALK[i]
		if i > 0:
			length += at.distance_to(Tamka.WALK[i - 1])
		for poly: PackedVector2Array in polys:
			if Geometry2D.is_point_in_polygon(at, poly):
				problems.append("walk point %s inside a house" % at)
		var best := INF
		for sg: Array in segs:
			best = minf(best, Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at))
		if best > 9.0:
			problems.append("walk point %s %.1f m off Tamka" % [at, best])
	if length < 120.0:
		problems.append("walk only %.0f m" % length)
	var at0: Vector2 = Tamka.WALK[0]
	if not Tamka.says_to_car(at0, at0 + Vector2(6, 0), 12.0, false):
		problems.append("no line to a slow car near him")
	if Tamka.says_to_car(at0, at0 + Vector2(6, 0), 45.0, false) or Tamka.says_to_car(at0, at0 + Vector2(6, 0), 5.0, true) \
			or Tamka.says_to_car(at0, at0 + Vector2(40, 0), 5.0, false):
		problems.append("a line to a fast or far car or the helicopter")
	return length


func _mesh() -> int:
	var m := Tamka.walker_mesh()
	var tris := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		tris += (idx.size() if not idx.is_empty() else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	if tris > 700:
		problems.append("walker %d triangles" % tris)
	return tris


func _lines() -> int:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var lines: Array = d.get("kebonafide", [])
	var street := 0
	var car := 0
	for l: Array in lines:
		if l.size() < 2 or str(l[1]).is_empty():
			problems.append("a line without English")
			continue
		if str(l[0]).length() > 75:
			problems.append("line too long: %s" % l[0])
		if l.size() > 2 and l[2] is Dictionary and l[2].get("only", "") == "car":
			car += 1
		else:
			street += 1
		var low := (str(l[0]) + " " + str(l[1])).to_lower()
		for n: String in deny.get("names", []):
			var re := RegEx.create_from_string("(^|[^\\p{L}])" + _esc(n) + "($|[^\\p{L}])")
			if re.search(low) != null:
				problems.append("brand '%s' in: %s" % [n, l[0]])
	if street < 10 or car < 3:
		problems.append("lines: %d street, %d car" % [street, car])
	return lines.size()


func _esc(s: String) -> String:
	var out := ""
	for ch in s:
		out += ("\\" + ch) if ".^$*+?()[]{}|\\".contains(ch) else ch
	return out


func _bridge(data: Dictionary) -> void:
	var best_a := INF
	var best_b := INF
	for pa: Dictionary in data["paths"]:
		var p: Array = pa["p"]
		for i in range(0, p.size() - 1, 2):
			var v := Vector2(p[i], p[i + 1])
			best_a = minf(best_a, v.distance_to(Tamka.BRIDGE_A))
			best_b = minf(best_b, v.distance_to(Tamka.BRIDGE_B))
	if best_a > 2.0 or best_b > 2.0:
		problems.append("footbridge ends %.1f / %.1f m off the mapped footway" % [best_a, best_b])


func _centre(data: Dictionary) -> void:
	var n := 0
	for r: Dictionary in data["roads"]:
		if str(r.get("name", "")) == "Tamka" and not bool(r.get("bridge", false)):
			n += 1
			var p: Array = r["p"]
			var at := Vector2(float(p[0]), float(p[1]))
			if Tamka.distance(at) > 0.2:
				problems.append("Tamka's line at %s is not in tamka.gd CENTRE" % at)
	if n != Tamka.CENTRE.size():
		problems.append("Tamka has %d mapped lines, CENTRE %d" % [n, Tamka.CENTRE.size()])


func _powisle(data: Dictionary) -> void:
	for h: Array in PowisleHouses.HOUSES:
		var at := Vector2(float(h[0]), float(h[1]))
		var hits: Array[PackedVector2Array] = []
		for b: Dictionary in data["buildings"]:
			var p: Array = b["p"]
			if absf(float(p[0]) - at.x) > 150.0 or absf(float(p[1]) - at.y) > 150.0:
				continue
			var poly := PackedVector2Array()
			for i in range(0, p.size() - 1, 2):
				poly.append(Vector2(p[i], p[i + 1]))
			if Geometry2D.is_point_in_polygon(at, poly):
				hits.append(poly)
		if hits.size() != 1:
			problems.append("Powiśle house at %s is in %d mapped houses" % [at, hits.size()])
			continue
		var got := PowisleHouses.look(hits[0], at)
		if got.is_empty() or got["plaster"] != Color(h[2]):
			problems.append("Powiśle house at %s not picked" % at)
		for f: Vector2 in (h[3] as Dictionary).get("fronts", []):
			var seen := false
			var poly := hits[0]
			for i in poly.size():
				var e := poly[(i + 1) % poly.size()] - poly[i]
				var n := Vector2(e.y, -e.x).normalized()
				if Geometry2D.is_point_in_polygon((poly[i] + poly[(i + 1) % poly.size()]) * 0.5 + n * 0.5, poly):
					n = -n
				seen = seen or n.dot(f.normalized()) > PowisleHouses.FRONT_DOT
			if not seen:
				problems.append("Powiśle house at %s: no wall faces %s" % [at, f])
