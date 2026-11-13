extends SceneTree
## City-life satire #1, loud cars (scripts/loud_cars.gd, 2026-11-02): headless, from the committed
## map (map/centrum.json) and data/dialogue.json; seeded:
##   1. the taxis' family mesh: one surface, a morphing family of four shapes (the city taxi,
##      Podwózka, the supercar, the Pasatini), so the loud cars and the meet add no traffic draw call; the
##      supercar is never a random taxi (share 0) and none of its paints is the player's red or
##      orange or the police's blue;
##   2. the meet at Browary: every car clear of every building outline (1 m), of every road's
##      carriageway (0.5 m) and of the trees' trunks (0.6 m), no two cars overlapping, none of
##      the crowd's spots inside a car or a building;
##   3. the lines: car_meet (8+ untagged, 3+ "rev"), loud_driver (5+), radio_host "loud" (3+, one
##      saying "liczą obroty"), Polish and English, bubbles under 70 characters, no real brand;
##      the sound file and its level in sfx.gd;
##   4. the real traffic round Browary for 40 s of play with the view moving: loud cars appear,
##      never more than loud_target at once, each a taxi slot in the supercar shape, the count
##      always matching the active loud drivers; with loud_target 0 none;
##   5. loud_cars.gd's tick: a loud car near the ear revs once (then waits), KEBAB FM's line once.
## Prints "check_loud_cars: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_loud_cars.gd [-- --verbose]

const LoudCars := preload("res://scripts/loud_cars.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Fakes := preload("res://tools/fakes.gd")
const BUBBLE := 70


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0


class FakeRadio extends Node:
	var station := 0
	var said: Array = []
	func announce(text: String, _sub := "") -> void:
		said.append(text)


class FakeSfx extends Node:
	var played: Array = []
	func play_at(n: String, at: Vector3, _gain_db := 0.0) -> void:
		played.append([n, at])


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_mesh(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_check_meet(data, digest)
	_check_lines(digest)
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	await _check_traffic(g, map, digest)
	for c in root.get_children():
		c.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_loud_cars: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_loud_cars: %d problems" % problems.size())
		quit(1)


func _check_mesh(digest: PackedStringArray) -> void:
	var m := Models.traffic_mesh(1)
	if m.get_surface_count() != 1:
		problems.append("taxi family: %d surfaces (want 1)" % m.get_surface_count())
	if m.surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM1 == 0:
		problems.append("taxi family: not a morphing family of 4 shapes (the shapes' vertex counts differ?)")
	var shapes: Array = Models.TRAFFIC[1]
	var sc: Dictionary = shapes[Models.TAXI_SUPERCAR]
	if str(sc["name"]) != "supercar" or float(sc["share"]) != 0.0:
		problems.append("TRAFFIC[1][%d]: %s share %.2f (want supercar, 0)" % [Models.TAXI_SUPERCAR, sc["name"], sc["share"]])
	for hex: String in sc["paint"]:
		var c := Color(hex)
		var reserved := c.s > 0.5 and (c.h < 0.11 or c.h > 0.95 or (c.h > 0.55 and c.h < 0.7))
		if reserved:
			problems.append("supercar paint %s is a reserved colour (red, orange, police blue)" % hex)
	var n := (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	digest.append("taxi family 4 shapes, 1 surface, %d vertices" % n)


func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in flat.size() / 2:
		out.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
	return out


## A car's four corners (its footprint grown by `grow`).
func _corners(c: Array, size: Vector3, grow: float) -> PackedVector2Array:
	var p: Vector2 = c[0]
	var yaw: float = c[1]
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	var out := PackedVector2Array()
	for k: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		out.append(p + right * (size.x * 0.5 + grow) * k.x + fwd * (size.z * 0.5 + grow) * k.y)
	return out


func _check_meet(data: Dictionary, digest: PackedStringArray) -> void:
	var mid := LoudCars.meet_centre()
	var polys: Array[PackedVector2Array] = []
	for key: String in ["buildings", "landmarks"]:
		for b: Dictionary in data.get(key, []):
			var q := _pts(b["p"])
			if q.size() >= 3 and q[0].distance_to(mid) < 160.0:
				polys.append(q)
	var roads: Array = []
	for r: Dictionary in data.get("roads", []):
		var q := _pts(r["p"])
		for v in q:
			if v.distance_to(mid) < 120.0:
				roads.append([q, float(r.get("w", 6.0)) * 0.5, str(r.get("name", ""))])
				break
	var size: Vector3 = Models.TRAFFIC[1][Models.TAXI_SUPERCAR]["size"]
	var cars := LoudCars.meet_cars()
	var feet: Array[PackedVector2Array] = []
	for i in cars.size():
		var foot := _corners(cars[i], size, 0.0)
		feet.append(foot)
		var near_bld := INF
		for poly in polys:
			for v in foot:
				if Geometry2D.is_point_in_polygon(v, poly):
					problems.append("meet car %d: a corner inside a building" % i)
			for k in poly.size():
				for v in foot:
					near_bld = minf(near_bld, v.distance_to(Geometry2D.get_closest_point_to_segment(v, poly[k], poly[(k + 1) % poly.size()])))
		if near_bld < 1.0:
			problems.append("meet car %d: %.2f m from a building (want 1+)" % [i, near_bld])
		for r: Array in roads:
			var q: PackedVector2Array = r[0]
			for k in q.size() - 1:
				for v in foot:
					var d := v.distance_to(Geometry2D.get_closest_point_to_segment(v, q[k], q[k + 1]))
					if d < float(r[1]) + 0.5:
						problems.append("meet car %d: on %s's carriageway (%.2f m from its middle)" % [i, r[2], d])
	var trees: Array = data.get("trees3d", [])
	for k in range(0, trees.size() - 5, 6):
		var tp := Vector2(float(trees[k]), float(trees[k + 1]))
		if tp.distance_to(mid) > 40.0:
			continue
		for i in cars.size():
			if Geometry2D.is_point_in_polygon(tp, _corners(cars[i], size, 0.6)):
				problems.append("meet car %d: a tree's trunk at %.1f, %.1f within 0.6 m" % [i, tp.x, tp.y])
	for a in feet.size():
		for b in range(a + 1, feet.size()):
			if not Geometry2D.intersect_polygons(feet[a], feet[b]).is_empty():
				problems.append("meet cars %d and %d overlap" % [a, b])
	var slots := LoudCars.meet_slots()
	for k in slots.size():
		var p: Vector2 = slots[k]["p"]
		for i in cars.size():
			if Geometry2D.is_point_in_polygon(p, _corners(cars[i], size, 0.3)):
				problems.append("meet spot %d inside car %d" % [k, i])
		for poly in polys:
			if Geometry2D.is_point_in_polygon(p, poly):
				problems.append("meet spot %d inside a building" % k)
	digest.append("meet %d cars, %d spots, clear" % [cars.size(), slots.size()])


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var counts := {}
	for group: String in ["car_meet", "loud_driver"]:
		for l: Array in all.get(group, []):
			var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
			var key := group + ":" + only
			counts[key] = int(counts.get(key, 0)) + 1
			_line_ok(group, l, banned)
	var radio := 0
	var obroty := false
	for l: Array in all.get("radio_host", []):
		if l.size() > 2 and (l[2] as Dictionary).get("only", "") == "loud":
			radio += 1
			obroty = obroty or String(l[0]).contains("liczą obroty")
			_line_ok("radio_host", l, banned, 200)
	for want: Array in [["car_meet:", 8], ["car_meet:rev", 3], ["car_meet:stop", 4], ["loud_driver:", 5]]:
		if int(counts.get(want[0], 0)) < int(want[1]):
			problems.append("%s: %d lines (want %d+)" % [want[0], int(counts.get(want[0], 0)), want[1]])
	if radio < 3 or not obroty:
		problems.append("radio_host loud: %d lines, \"liczą obroty\" %s (want 3+, yes)" % [radio, obroty])
	if not FileAccess.file_exists("res://audio/sfx/%s.wav" % LoudCars.SOUND):
		problems.append("no audio/sfx/%s.wav (tools/make_sfx.py --only=%s)" % [LoudCars.SOUND, LoudCars.SOUND])
	if not Sfx.SHOTS.has(LoudCars.SOUND):
		problems.append("sfx.gd SHOTS has no level for %s" % LoudCars.SOUND)
	digest.append("lines %s, radio %d" % [counts, radio])


func _line_ok(group: String, l: Array, banned: Array, most := BUBBLE) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without its Polish or English: %s" % [group, l])
		return
	if String(l[0]).length() >= most:
		problems.append("%s: %d characters (under %d): %s" % [group, String(l[0]).length(), most, l[0]])
	for text: String in [String(l[0]).to_lower(), String(l[1]).to_lower()]:
		for b in banned:
			var rx := RegEx.create_from_string("(^|[^\\p{L}])" + _escape(String(b)) + "($|[^\\p{L}])")
			if rx.search(text) != null:
				problems.append("%s: a real brand (%s): %s" % [group, b, l[0]])


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += "\\" + c if c in ".+*?^$()[]{}|\\" else c
	return out


## The loud drivers now, and whether the count and their kind and shape hold.
func _loud_ok(traffic: Node3D, when: String) -> int:
	var n := 0
	for d in traffic.drivers():
		if d.loud:
			n += 1
			if d.kind != Traffic.Kind.TAXI or d.shape != Models.TAXI_SUPERCAR:
				problems.append("%s: a loud car of kind %d shape %d" % [when, d.kind, d.shape])
	if n != int(traffic.loud_count):
		problems.append("%s: loud_count %d but %d loud drivers" % [when, traffic.loud_count, n])
	if n > int(traffic.loud_target):
		problems.append("%s: %d loud cars (most %d)" % [when, n, traffic.loud_target])
	return n


func _check_traffic(g: LaneGraph, map: Node3D, digest: PackedStringArray) -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 90.0
	root.add_child(cam)
	var traffic: Node3D = Traffic.new()
	root.add_child(traffic)
	traffic.setup(g, map, cam, {})
	traffic.player_on_road = false
	traffic.set_process(false)
	traffic.set_physics_process(false)
	traffic.loud_target = 3
	traffic.crazy_target = 0  # the crazy drivers have their own check (check_crazy_drivers.gd)
	# The view drifts from Rondo Daszyńskiego east along Grzybowska past the Browary and back.
	var path := [Vector2(-2750.0, 40.0), Vector2(-2300.0, -60.0), Vector2(-1900.0, -40.0), Vector2(-2600.0, -120.0)]
	var most := 0
	var ever := {}
	var frames := 60 * 40
	for f in frames:
		var u := float(f) / frames * (path.size() - 1)
		var k := mini(int(u), path.size() - 2)
		var at: Vector2 = (path[k] as Vector2).lerp(path[k + 1], u - k)
		var focus := Vector3(at.x, 0.0, at.y)
		cam.global_transform = Transform3D(Basis.IDENTITY, focus + Vector3(0.0, 80.0, 60.0)).looking_at(focus, Vector3.UP)
		traffic.player_pos = focus
		traffic.call("_process", 1.0 / 60.0)
		if f % 30 == 0:
			most = maxi(most, _loud_ok(traffic, "frame %d" % f))
			for d in traffic.drivers():
				if d.loud:
					ever[d] = true
			if verbose and f % 300 == 0:
				print("frame %d at %s: %d cars, %d loud" % [f, at, traffic.drivers().size(), traffic.loud_count])
	if most == 0:
		problems.append("traffic: no loud car in 40 s round Browary")
	# Hold the view on Grzybowska by the Browary until a loud car is in the band (at most 30 s more).
	var hold := Vector3(-2450.0, 0.0, -25.0)
	cam.global_transform = Transform3D(Basis.IDENTITY, hold + Vector3(0.0, 80.0, 60.0)).looking_at(hold, Vector3.UP)
	traffic.player_pos = hold
	for f in 60 * 30:
		var found := false
		for d in traffic.drivers():
			found = found or (d.loud and d.clip >= 0.5)
		if found:
			break
		traffic.call("_process", 1.0 / 60.0)
		if verbose and f % 300 == 0:
			print("hold %d: %d cars, %d loud, counts %s" % [f, traffic.drivers().size(), traffic.loud_count, traffic.get("_counts")])
	# KEBAB FM and the revs: a loud car at the ear.
	var lc := LoudCars.new()
	var fsfx := FakeSfx.new()
	var fradio := FakeRadio.new()
	root.add_child(fsfx)
	root.add_child(fradio)
	var dlg := Dialogue.new()
	dlg.bubbles = Fakes.Bubbles.new()
	root.add_child(dlg)
	root.add_child(dlg.bubbles)
	lc.traffic = traffic
	lc.sfx = fsfx
	lc.radio = fradio
	lc.dialogue = dlg
	lc.map = map
	lc.set_process(false)
	root.add_child(lc)
	lc.setup()
	var loud: Object = null
	for d in traffic.drivers():
		if d.loud and d.clip >= 0.5:
			loud = d
			break
	if loud == null:
		problems.append("tick: no loud car to listen to")
	else:
		var ear: Vector3 = loud.pos
		lc.focus = func() -> Vector3: return ear
		lc.step(0.25)
		lc.step(0.25)
		lc.step(0.25)
		if lc.revs != 1:
			problems.append("tick: %d revs from one car in 0.75 s (want 1)" % lc.revs)
		if fradio.said.size() != 1:
			problems.append("tick: KEBAB FM said %d lines (want 1)" % fradio.said.size())
		for i in 3:
			lc.step(LoudCars.REV_GAP.y)
		if fradio.said.size() != 1:
			problems.append("tick: KEBAB FM said %d lines within RADIO_GAP (want 1)" % fradio.said.size())
	# The meet revs when the ear is there.
	var mid := LoudCars.meet_centre()
	lc.focus = func() -> Vector3: return Vector3(mid.x, 0.0, mid.y)
	for i in 20:
		lc.step(1.0)
	if lc.meet_revs < 1:
		problems.append("meet: no rev in 20 s at the meet")
	# loud_target 0: the loud ones go as they leave and no new one comes.
	traffic.loud_target = 0
	for d in traffic.drivers().duplicate():
		if d.loud:
			traffic.remove(d)
	for f in 60 * 10:
		traffic.call("_process", 1.0 / 60.0)
	if _loud_ok(traffic, "loud_target 0") != 0:
		problems.append("loud_target 0: loud cars still spawn")
	digest.append("traffic: %d loud at most, %d in 40 s, %d revs, %d meet revs, %d radio" % [most, ever.size(), lc.revs, lc.meet_revs, fradio.said.size()])
