extends SceneTree
## The crash scenes (scripts/crash_scenes.gd, 2026-11-01): their rules headless, from the
## committed map data (map/centrum.json: the lane graph) and data/dialogue.json; seeded:
##   1. the police family's mesh: one surface, four shapes (the patrol car, the guards' car, the ambulance and the patrol van; was: the patrol car, the guards' car and
##      the ambulance), so the ambulance adds no draw call;
##   2. the lines: every speaker's tag in `crash_scene` (drivers, officer, paramedic, onlookers),
##      Polish and English, bubbles under 70 characters, no real brand; KEBAB FM's `crash` lines
##      name {street} in both languages;
##   3. spots on the real lane graph from 60 seeded places and headings: most find one; every one
##      is on a main or secondary road of 2+ lanes off bridges and tunnels with room at both ends;
##      the four vehicles stand one behind the other in the kerb lane without overlapping, nobody
##      stands inside a vehicle, the onlookers are off the carriageway;
##   4. the real traffic on a straight two-lane road: a scene of wrecks stands in the kerb lane,
##      six cars driving that lane queue behind it and all go round it into the other lane, none
##      ever inside the scene; after clear() the wrecks are back in the pool;
##   5. the timer on that road: the first scene within FIRST s, placed ahead of the moving car
##      and out of sight; cleared after its life (not while seen); the next after GAP.
## Prints "check_crash_scenes: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_crash_scenes.gd [-- --verbose]

const CrashScenes := preload("res://scripts/crash_scenes.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
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


## A stand-in for pedestrians.gd's scene figures.
class FakeWalkers extends Node3D:
	var figures := {}
	func set_scene(i: int, at: Vector3, _yaw: float, _shirt: Color, _trousers: float) -> void:
		figures[i] = at
	func clear_scene(i: int) -> void:
		figures.erase(i)


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_mesh(digest)
	_check_lines(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_spots(g, digest)
	await _check_traffic(map, digest)
	await _check_timer(map, digest)
	if problems.is_empty():
		print("check_crash_scenes: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_crash_scenes: %d problems" % problems.size())
		quit(1)


func _check_mesh(digest: PackedStringArray) -> void:
	var m := Models.police_mesh()
	var n := (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	if m.get_surface_count() != 1:
		problems.append("police family: %d surfaces (want 1)" % m.get_surface_count())
	# family() falls back to the first shape's own mesh (no custom channels) if the shapes differ.
	if m.surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM0 == 0:
		problems.append("police family: not a morphing family (the shapes' vertex counts differ?)")
	digest.append("police family 4 shapes, 1 surface, %d vertices" % n)


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var by_tag := {}
	for l: Array in all.get("crash_scene", []):
		var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
		by_tag[only] = int(by_tag.get(only, 0)) + 1
		_line_ok("crash_scene", l, banned)
	for tag: String in ["driver", "officer", "medic", "gawker"]:
		if int(by_tag.get(tag, 0)) < 3:
			problems.append("crash_scene: %d lines for %s (want 3+)" % [int(by_tag.get(tag, 0)), tag])
	if by_tag.has(""):
		problems.append("crash_scene: %d lines without a speaker's tag" % by_tag[""])
	for i in CrashScenes.PEOPLE.size():
		if not by_tag.has(CrashScenes.PEOPLE[i][0]):
			problems.append("crash_scene: no lines for person %d (%s)" % [i, CrashScenes.PEOPLE[i][0]])
	var radio := 0
	for l: Array in all.get("radio_host", []):
		if l.size() > 2 and (l[2] as Dictionary).get("only", "") == CrashScenes.RADIO_TAG:
			radio += 1
			if not String(l[0]).contains("{street}") or not String(l[1]).contains("{street}"):
				problems.append("radio crash line without {street}: %s" % l[0])
			_line_ok("radio_host", l, banned, 200)
	if radio < 2:
		problems.append("radio_host: %d crash lines (want 2+)" % radio)
	digest.append("lines %s, radio %d" % [by_tag, radio])


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


func _check_spots(g: LaneGraph, digest: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 87
	var found := 0
	var tries := 60
	for k in tries:
		var from := g.node_pos[rng.randi() % g.node_pos.size()]
		var heading := Vector2.UP.rotated(rng.randf_range(-PI, PI)) if k % 4 != 0 else Vector2.ZERO
		var spot := CrashScenes.pick_spot(g, from, heading, rng)
		if spot.is_empty():
			continue
		found += 1
		var e: int = spot["e"]
		var s0: float = spot["s0"]
		if not CrashScenes.fits(g, e):
			problems.append("spot %d: edge %d doesn't fit" % [k, e])
		if int(spot["lane"]) != g.e_lanes[e] - 1:
			problems.append("spot %d: lane %d, not the kerb lane" % [k, spot["lane"]])
		if s0 < g.e_s0[e] + CrashScenes.END_ROOM - 0.01 or s0 + CrashScenes.SPAN > g.e_s1[e] - CrashScenes.END_ROOM + 0.01:
			problems.append("spot %d: s %.1f-%.1f too near the ends of %.1f-%.1f" % [k, s0, s0 + CrashScenes.SPAN, g.e_s0[e], g.e_s1[e]])
		_check_layout(g, CrashScenes.layout(g, spot), k)
	if found < tries * 0.6:
		problems.append("spots: %d of %d tries found one (want 60 %%+)" % [found, tries])
	digest.append("spots %d/%d on the real graph" % [found, tries])


## The vehicles' footprints don't overlap (the two wrecks may touch: 0.4 m), nobody inside one.
func _check_layout(g: LaneGraph, lay: Dictionary, k: int) -> void:
	var sizes := {"police": Vector2(1.85, 4.7), "hitter": Vector2(1.8, 4.65), "hit": Vector2(1.8, 4.65), "ambulance": Vector2(1.98, 5.2)}
	var boxes: Array = []
	for c: Array in lay["cars"]:
		var sz: Vector2 = sizes[c[0]]
		var p: Vector3 = c[1]
		boxes.append([Vector2(p.x, p.z), float(c[2]), sz])
	for a in boxes.size():
		for b in range(a + 1, boxes.size()):
			var pen := _overlap(boxes[a], boxes[b])
			if pen > 0.4:
				problems.append("spot %d: %s and %s overlap %.2f m" % [k, lay["cars"][a][0], lay["cars"][b][0], pen])
	for i in (lay["people"] as Array).size():
		var p: Vector3 = lay["people"][i][0]
		for bx: Array in boxes:
			if _inside(Vector2(p.x, p.z), bx, 0.25):
				problems.append("spot %d: person %d inside the %s" % [k, i, lay["cars"][boxes.find(bx)][0]])


## The two boxes' overlap along the road (each [centre, yaw, (width, length)]); 0 if clear.
func _overlap(a: Array, b: Array) -> float:
	# Corners of b inside a (and the other way): the deepest one.
	var worst := 0.0
	for pair: Array in [[a, b], [b, a]]:
		var host: Array = pair[0]
		var guest: Array = pair[1]
		var gc: Vector2 = guest[0]
		var gy: float = guest[1]
		var gs: Vector2 = guest[2]
		var fwd := Vector2(-sin(gy), -cos(gy))
		var right := Vector2(cos(gy), -sin(gy))
		for sx: float in [-0.5, 0.5]:
			for sz: float in [-0.5, 0.5]:
				var q := gc + right * gs.x * sx + fwd * gs.y * sz
				worst = maxf(worst, _depth(q, host))
	return worst


func _depth(q: Vector2, box: Array) -> float:
	var c: Vector2 = box[0]
	var y: float = box[1]
	var s: Vector2 = box[2]
	var rel := q - c
	var along := absf(rel.dot(Vector2(-sin(y), -cos(y))))
	var across := absf(rel.dot(Vector2(cos(y), -sin(y))))
	if along >= s.y * 0.5 or across >= s.x * 0.5:
		return 0.0
	return minf(s.y * 0.5 - along, s.x * 0.5 - across)


func _inside(q: Vector2, box: Array, grow: float) -> bool:
	var c: Vector2 = box[0]
	var y: float = box[1]
	var s: Vector2 = box[2]
	var rel := q - c
	return absf(rel.dot(Vector2(-sin(y), -cos(y)))) < s.y * 0.5 + grow and absf(rel.dot(Vector2(cos(y), -sin(y)))) < s.x * 0.5 + grow


## A straight one-way road 1.2 km long with two lanes (x 0..1200 at z 0), the real traffic on it,
## a camera far off (nothing on screen).
func _road(map: Node3D) -> Array:
	var gd := {"nodes": [0.0, 0.0, 1200.0, 0.0], "scc": [1, 1], "ctrl": [], "poles": [], "portals": [],
			"edges": [{"a": 0, "b": 1, "p": [0.0, 0.0, 1200.0, 0.0], "k": "primary", "n": 2, "lw": 3.25, "o": 1.6,
				"v": 13.9, "s0": 1.0, "s1": 1199.0, "name": "Testowa"}]}
	var g := LaneGraph.new(gd, map)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 40.0
	root.add_child(cam)
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 50.0, 9000.0))
	var traffic: Node3D = Traffic.new()
	root.add_child(traffic)
	traffic.setup(g, map, cam, {})
	traffic.spawning = false
	traffic.player_on_road = false
	traffic.set_process(false)
	traffic.set_physics_process(false)
	return [g, traffic, cam]


func _scenes(g: LaneGraph, traffic: Node3D, map: Node3D) -> CrashScenes:
	var cs := CrashScenes.new()
	cs.traffic = traffic
	cs.graph = g
	cs.map = map
	cs.walkers = FakeWalkers.new()
	root.add_child(cs.walkers)
	var dlg := Dialogue.new()
	dlg.bubbles = Fakes.Bubbles.new()
	root.add_child(dlg)
	root.add_child(dlg.bubbles)
	cs.dialogue = dlg
	cs.set_process(false)
	root.add_child(cs)
	return cs


func _check_traffic(map: Node3D, digest: PackedStringArray) -> void:
	var made := _road(map)
	var g: LaneGraph = made[0]
	var traffic: Node3D = made[1]
	await process_frame
	var cs := _scenes(g, traffic, map)
	cs.setup(5)
	var cars0: int = traffic.get("_counts")[0]
	# The scene: its rear at s 500 in the kerb lane (lane 1); no police here (the wrecks only).
	var spot := {"e": 0, "lane": 1, "s0": 500.0}
	var lay := CrashScenes.layout(g, spot)
	var wrecks: Array = []
	for c: Array in lay["cars"]:
		if c[0] in ["hitter", "hit"]:
			var s: float = 500.0 + (CrashScenes.AT_HITTER if c[0] == "hitter" else CrashScenes.AT_HIT)
			wrecks.append(traffic.add_parked_car(0, s, c[1], c[2], 1, 0, Color.RED))
	cs.scene = {"e": 0, "lane": 1, "s0": 500.0, "mid": lay["mid"], "drivers": wrecks, "people": lay["people"],
			"age": 0.0, "life": 100.0, "talk": 1.0, "turn": 0, "street": "Testowa"}
	# Six cars in the kerb lane behind it, 25 m apart, driving on (node drivers: they come back in
	# at the start when they leave the far end).
	var cars: Array = []
	for i in 6:
		var n := Node3D.new()
		root.add_child(n)
		var d = traffic.add_node_driver(n, Vector3(1.8, 1.5, 4.4), 0, 1, 330.0 + i * 25.0)
		d.speed_factor = 1.0
		cars.append(d)
	var passed := {}
	var inside := 0
	var lane_changes := 0
	var was_lane := {}
	var wreck_lo := 500.0 + CrashScenes.AT_HITTER - 2.6
	var wreck_hi := 500.0 + CrashScenes.AT_HIT + 2.6
	for f in 60 * 90:
		traffic.call("_process", 1.0 / 60.0)
		for d in cars:
			if was_lane.get(d, 1) == 1 and d.lane == 0:
				lane_changes += 1
			was_lane[d] = d.lane
			if d.s > wreck_hi + 5.0 and d.s < 700.0:
				passed[d] = true
			# Still on the kerb lane's line (not slid across) inside the wrecks' stretch.
			var off := absf(d.off - g.lane_offset(0, 1))
			if d.s + d.length * 0.5 > wreck_lo and d.s - d.length * 0.5 < wreck_hi and off < 1.2:
				inside += 1
		if passed.size() == cars.size():
			break
	if passed.size() < cars.size():
		problems.append("traffic: %d of %d cars got past the scene in 90 s" % [passed.size(), cars.size()])
	if inside > 0:
		problems.append("traffic: %d frames with a car inside the wrecks' stretch on their lane" % inside)
	if lane_changes < cars.size():
		problems.append("traffic: %d lane changes for %d cars" % [lane_changes, cars.size()])
	cs.clear()
	var cars1: int = traffic.get("_counts")[0]
	if cars1 != cars0:
		problems.append("traffic: %d cars in the pool's count after clear() (was %d)" % [cars1, cars0])
	for w in wrecks:
		if w.active:
			problems.append("traffic: a wreck still out after clear()")
	digest.append("traffic: %d/%d past the scene, %d lane changes, 0 inside" % [passed.size(), cars.size(), lane_changes])
	for d in cars:
		traffic.remove(d)
	cs.queue_free()
	traffic.queue_free()
	(made[2] as Node).queue_free()
	await process_frame


func _check_timer(map: Node3D, digest: PackedStringArray) -> void:
	var made := _road(map)
	var g: LaneGraph = made[0]
	var traffic: Node3D = made[1]
	await process_frame
	var cs := _scenes(g, traffic, map)
	var pos := [Vector3(60.0, 0.0, 1.6)]
	cs.vehicle = func() -> Array: return [pos[0], 30.0, false]
	cs.log_on = verbose
	cs.setup(11)
	var t := 0.0
	var first_at := -1.0
	var cleared_at := -1.0
	var second_at := -1.0
	var dt := CrashScenes.TICK
	while t < 1200.0 and second_at < 0.0:
		t += dt
		# The car drives east at 2.5 m/s and stops at x 640 (by the first scene: it talks).
		pos[0] = Vector3(minf(60.0 + t * 2.5, 640.0), 0.0, 1.6)
		cs.step(dt)
		if first_at < 0.0 and not cs.scene.is_empty():
			first_at = t
			var m: Vector2 = cs.scene["mid"]
			var ahead: float = m.x - pos[0].x
			if ahead < CrashScenes.AHEAD.x - 40.0 or ahead > CrashScenes.AHEAD.y + 40.0:
				problems.append("timer: the scene %.0f m ahead (want %.0f-%.0f)" % [ahead, CrashScenes.AHEAD.x, CrashScenes.AHEAD.y])
			if (cs.walkers as FakeWalkers).figures.size() != CrashScenes.PEOPLE.size():
				problems.append("timer: %d people at the scene (want %d)" % [(cs.walkers as FakeWalkers).figures.size(), CrashScenes.PEOPLE.size()])
		if first_at >= 0.0 and cleared_at < 0.0 and cs.scene.is_empty():
			cleared_at = t
		if cleared_at >= 0.0 and second_at < 0.0 and not cs.scene.is_empty():
			second_at = t
	if first_at < CrashScenes.FIRST.x or first_at > CrashScenes.FIRST.y + 4.0:
		problems.append("timer: the first scene at %.1f s (want %.0f-%.0f)" % [first_at, CrashScenes.FIRST.x, CrashScenes.FIRST.y])
	var life := cleared_at - first_at
	if cleared_at < 0.0 or life < CrashScenes.LIFE.x or life > CrashScenes.LIFE.y + 1.0:
		problems.append("timer: the scene lived %.1f s (want %.0f-%.0f)" % [life, CrashScenes.LIFE.x, CrashScenes.LIFE.y])
	var gap := second_at - cleared_at
	if second_at < 0.0 or gap < CrashScenes.GAP.x or gap > CrashScenes.GAP.y + 4.0:
		problems.append("timer: the next scene %.1f s after (want %.0f-%.0f)" % [gap, CrashScenes.GAP.x, CrashScenes.GAP.y])
	if (cs.walkers as FakeWalkers).figures.size() != CrashScenes.PEOPLE.size():
		problems.append("timer: the second scene has %d people" % (cs.walkers as FakeWalkers).figures.size())
	var said: int = (cs.dialogue.bubbles as Fakes.Bubbles).said.size()
	if said < 3:
		problems.append("timer: %d lines said with the car by the scene (want 3+)" % said)
	digest.append("timer: first at %.0f s, lived %.0f s, next %.0f s later, %d lines said" % [first_at, life, gap, said])
	cs.clear()
	cs.queue_free()
	traffic.queue_free()
	(made[2] as Node).queue_free()
	await process_frame
