extends SceneTree
## Crazy drivers (scripts/crazy_drivers.gd, traffic.gd CRAZY_*, docs/design/crazy-drivers.md,
## 2026-11-05): headless, from the committed map (map/centrum.json) and data/dialogue.json; seeded:
##   1. the taxis' family mesh: one surface, a morphing family of four shapes; the Pasatini (shape
##      TAXI_PASAT) is never a random taxi (share 0), its paints are traffic.gd's PASAT_PAINT and
##      none is the player's red or orange or the police's blue;
##   2. the lines: crazy_taxi, crazy_courier, crazy_pasatini (5+ each), radio_host "pasatini" (3+),
##      Polish and English, bubbles under 70 characters, no denylisted brand and no real marque
##      (passat, skoda, volkswagen, sprinter, octavia);
##   3. 60 s of the real traffic with the view moving through the centre: crazy drivers appear,
##      never more than crazy_target and never two Pasatinis, the counts match, each of the right
##      kind and shape, in racer mode, on a lane, never over its top speed, and faster on average
##      than the town cars round them;
##   4. crazy_drivers.gd's tick: a cut-in near the player honks and makes one line; a second
##      cut-in by the same car honks again but makes no second line;
##   5. with crazy_target 0, none spawn.
## Prints "check_crazy_drivers: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_crazy_drivers.gd [-- --verbose]

const CrazyDrivers := preload("res://scripts/crazy_drivers.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const BUBBLE := 70
const MARQUES := ["passat", "skoda", "škoda", "volkswagen", "sprinter", "octavia", "tdi"]


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


class FakeSfx extends Node:
	var played: Array = []
	func play_at(n: String, at: Vector3, _gain_db := 0.0) -> void:
		played.append([n, at])


class FakeBubbles extends Control:
	var said := 0
	## false: the budget refuses (the player too fast, the reaction window).
	var ok := true
	func say(_anchor: Variant, _speaker: String, _line: String, _sub := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _k := 0, _key := "") -> bool:
		if not ok:
			return false
		said += 1
		return true
	func allows(_k: int, _key := "") -> bool:
		return ok
	func is_talking(_anchor: Variant) -> bool:
		return false
	func hush(_anchor: Variant) -> void:
		pass
	func muted() -> bool:
		return false


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
	await _check_traffic(g, map, digest)
	for c in root.get_children():
		c.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_crazy_drivers: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_crazy_drivers: %d problems" % problems.size())
		quit(1)


func _check_mesh(digest: PackedStringArray) -> void:
	var m := Models.traffic_mesh(1)
	if m.get_surface_count() != 1:
		problems.append("taxi family: %d surfaces (want 1)" % m.get_surface_count())
	if m.surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM1 == 0:
		problems.append("taxi family: not a morphing family (the shapes' vertex counts differ?)")
	var shapes: Array = Models.TRAFFIC[1]
	if shapes.size() != 4:
		problems.append("TRAFFIC[1]: %d shapes (want 4: city, Podwózka, supercar, Pasatini)" % shapes.size())
	var ps: Dictionary = shapes[Models.TAXI_PASAT]
	if str(ps["name"]) != "pasatini" or float(ps["share"]) != 0.0:
		problems.append("TRAFFIC[1][%d]: %s share %.2f (want pasatini, 0)" % [Models.TAXI_PASAT, ps["name"], ps["share"]])
	if Array(ps["paint"]) != Array(Traffic.PASAT_PAINT):
		problems.append("the Pasatini's paints in models.gd and traffic.gd PASAT_PAINT differ")
	for hex: String in ps["paint"]:
		var c := Color(hex)
		if c.s > 0.5 and (c.h < 0.11 or c.h > 0.95 or (c.h > 0.55 and c.h < 0.7)):
			problems.append("Pasatini paint %s is a reserved colour (red, orange, police blue)" % hex)
	digest.append("taxi family %d shapes, 1 surface" % shapes.size())


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = MARQUES.duplicate()
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var counts := {}
	for group: String in ["crazy_taxi", "crazy_courier", "crazy_pasatini"]:
		var lines: Array = all.get(group, [])
		counts[group] = lines.size()
		if lines.size() < 5:
			problems.append("%s: %d lines (want 5+)" % [group, lines.size()])
		for l: Array in lines:
			_line_ok(group, l, banned)
	var radio := 0
	for l: Array in all.get("radio_host", []):
		if l.size() > 2 and (l[2] as Dictionary).get("only", "") == "pasatini":
			radio += 1
			_line_ok("radio_host", l, banned, 200)
	if radio < 3:
		problems.append("radio_host pasatini: %d lines (want 3+)" % radio)
	for group: String in CrazyDrivers.GROUPS:
		if group != "" and not all.has(group):
			problems.append("crazy_drivers.gd GROUPS names %s, not in dialogue.json" % group)
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


## The crazy drivers now, and whether the counts, their kind and shape and their state hold.
func _crazy_ok(traffic: Node3D, when: String) -> int:
	var n := 0
	var pasat := 0
	for d in traffic.drivers():
		if d.crazy <= 0:
			continue
		n += 1
		match int(d.crazy):
			1:
				if d.kind != Traffic.Kind.TAXI or d.shape == Models.TAXI_SUPERCAR or d.shape == Models.TAXI_PASAT:
					problems.append("%s: a crazy taxi of kind %d shape %d" % [when, d.kind, d.shape])
			2:
				if d.kind != Traffic.Kind.VAN or d.shape != 0:
					problems.append("%s: a crazy courier of kind %d shape %d" % [when, d.kind, d.shape])
			3:
				pasat += 1
				if d.kind != Traffic.Kind.TAXI or d.shape != Models.TAXI_PASAT:
					problems.append("%s: a Pasatini of kind %d shape %d" % [when, d.kind, d.shape])
		if not Traffic.racing_mode(d):
			problems.append("%s: a crazy driver (%d) not in racer mode" % [when, d.crazy])
		if d.edge < 0 or d.reg < 0:
			problems.append("%s: a crazy driver (%d) off the lanes (edge %d, lane %d)" % [when, d.crazy, d.edge, d.reg])
		if d.v > float(Traffic.CRAZY_TOP[d.crazy]) + 0.5:
			problems.append("%s: a crazy driver (%d) at %.1f m/s (top %.1f)" % [when, d.crazy, d.v, Traffic.CRAZY_TOP[d.crazy]])
	if n != int(traffic.crazy_count) or pasat != int(traffic.pasat_count):
		problems.append("%s: crazy_count %d / pasat_count %d but %d / %d drivers" % [when, traffic.crazy_count, traffic.pasat_count, n, pasat])
	if n > int(traffic.crazy_target):
		problems.append("%s: %d crazy drivers (most %d)" % [when, n, traffic.crazy_target])
	if pasat > 1:
		problems.append("%s: %d Pasatinis (one at most)" % [when, pasat])
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
	traffic.loud_target = 0
	traffic.crazy_target = 3
	# The view drifts along Marszałkowska, Jerozolimskie and Świętokrzyska and back.
	var path := [Vector2(-1050.0, -130.0), Vector2(-850.0, 470.0), Vector2(-400.0, 300.0), Vector2(-500.0, -310.0), Vector2(-1050.0, -130.0)]
	var most := 0
	var ever := {}
	var kinds := {}
	var crazy_v := 0.0
	var crazy_n := 0
	var town_v := 0.0
	var town_n := 0
	var frames := 60 * 60
	for f in frames:
		var u := float(f) / frames * (path.size() - 1)
		var k := mini(int(u), path.size() - 2)
		var at: Vector2 = (path[k] as Vector2).lerp(path[k + 1], u - k)
		var focus := Vector3(at.x, 0.0, at.y)
		cam.global_transform = Transform3D(Basis.IDENTITY, focus + Vector3(0.0, 80.0, 60.0)).looking_at(focus, Vector3.UP)
		traffic.player_pos = focus + Vector3(0.0, 0.0, 200.0)  # out of the way
		traffic.call("_process", 1.0 / 60.0)
		if f % 30 == 0:
			most = maxi(most, _crazy_ok(traffic, "frame %d" % f))
			for d in traffic.drivers():
				if d.kind == Traffic.Kind.BUS or d.kind == Traffic.Kind.POLICE or d.v < 2.0 or d.in_conn:
					continue
				if d.crazy > 0:
					ever[d] = true
					kinds[d.crazy] = true
					crazy_v += d.v
					crazy_n += 1
				elif not d.loud:
					town_v += d.v
					town_n += 1
			if verbose and f % 300 == 0:
				print("frame %d at %s: %d cars, %d crazy" % [f, at, traffic.drivers().size(), traffic.crazy_count])
	if most == 0:
		problems.append("traffic: no crazy driver in 60 s through the centre")
	var cv := crazy_v / maxf(crazy_n, 1.0)
	var tv := town_v / maxf(town_n, 1.0)
	if crazy_n > 0 and cv < tv * 1.15:
		problems.append("traffic: crazy drivers at %.1f m/s on average, town cars %.1f (want 15 %%+ faster)" % [cv, tv])
	# The tick: a cut-in next to the player.
	var cd := CrazyDrivers.new()
	var fsfx := FakeSfx.new()
	root.add_child(fsfx)
	var dlg := Dialogue.new()
	var bubbles := FakeBubbles.new()
	dlg.bubbles = bubbles
	root.add_child(dlg)
	root.add_child(bubbles)
	cd.traffic = traffic
	cd.sfx = fsfx
	cd.dialogue = dlg
	cd.set_process(false)
	root.add_child(cd)
	var one: Object = null
	for d in traffic.drivers():
		if d.crazy > 0:
			one = d
			break
	if one == null:
		problems.append("tick: no crazy driver to test")
	else:
		traffic.player_on_road = true
		traffic.player_pos = one.pos + Vector3(3.0, 0.0, 6.0)
		one.visible = true
		cd.step(0.25)
		# PT-25: the budget refuses at the cut (the player fast): a horn, no line, and the line
		# is not spent; it comes once the budget lets it, a tick later.
		bubbles.ok = false
		one.blocks += 1
		cd.step(0.25)
		if cd.cuts != 1 or cd.lines != 0 or fsfx.played.size() != 1 or str(fsfx.played[0][0]) != "horn":
			problems.append("tick: refused cut-in made %d cuts, %d lines, sounds %s (want 1, 0, a horn)" % [cd.cuts, cd.lines, fsfx.played])
		cd.step(0.25)
		if cd.lines != 0:
			problems.append("tick: a refused line showed anyway (%d lines)" % cd.lines)
		bubbles.ok = true
		cd.step(0.25)
		if cd.cuts != 1 or cd.lines != 1 or cd.lost_lines != 0:
			problems.append("tick: pending line made %d cuts, %d lines, %d lost (want 1, 1, 0)" % [cd.cuts, cd.lines, cd.lost_lines])
		one.race_passes += 1
		cd.step(0.25)
		if cd.cuts != 2 or cd.lines != 1:
			problems.append("tick: a second cut-in made %d cuts, %d lines (want 2, 1)" % [cd.cuts, cd.lines])
		traffic.player_on_road = false
	# crazy_target 0: the crazy ones go and no new one comes.
	traffic.crazy_target = 0
	for d in traffic.drivers().duplicate():
		if d.crazy > 0:
			traffic.remove(d)
	for f in 60 * 10:
		traffic.call("_process", 1.0 / 60.0)
	if _crazy_ok(traffic, "crazy_target 0") != 0:
		problems.append("crazy_target 0: crazy drivers still spawn")
	digest.append("traffic: %d crazy at most, %d in 60 s, kinds %s, %.1f vs town %.1f m/s, tick %d cuts %d lines" % [most, ever.size(), kinds.keys(), cv, tv, cd.cuts, cd.lines])
