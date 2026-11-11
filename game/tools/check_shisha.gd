extends SceneTree
## Dym u Senatorka (scripts/shisha.gd, scripts/lounge.gd, F's ask 2026-11-08): the shisha night's
## rules headless, from the committed map data (map/centrum.json) and data/shisha.json:
##   1. the lines: every scene the quest and the lounge play is there, each line [speaker, pl, en]
##      with both languages under 90 characters and no real brand (brand_denylist.json); every
##      tappable person in the lounge has 2+ lines; six jars with sweet/cool 0..5, ids unique;
##   2. the votes: each card has three answers, a timed-out card takes a real answer, the scenes
##      after a vote exist; the pay is full for smoking, half and no respect for leaving;
##   3. the mini-game: hearts 0..3, the tomato soup a legend (Ivan 0, Bogdan 3), strong pleases
##      Bogdan and light pleases Ivan, a perfect mix (6 hearts) reachable only strong, the coal's
##      band narrower when stronger and a tap in its middle good, early and late not; the draw's
##      band; the total 0..9 and its verdict scene;
##   4. the meshes: the lounge (room and terrace) one surface, its light pose no NaN;
##   5. the real lane graph: Ivan's block, the courts and the lounge's door found on ground roads
##      near their places, the door on Emilii Plater, the courts between the two (shorter than
##      going via WTS DESKA), the hours wrapping past midnight; the entrance's door ring in front of
##      the revolving door on the kerb's side (F 2026-11-11).
## Prints "check_shisha: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_shisha.gd [-- --verbose]

const Shisha := preload("res://scripts/shisha.gd")
const Lounge := preload("res://scripts/lounge.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Notebook := preload("res://scripts/notebook.gd")
const BUBBLE := 90
const SCENES := ["board_ivan", "leg1", "court", "board_bogdan", "flavour", "flavour_ivan", "flavour_bogdan",
		"flavour_master", "strength", "strength_low", "strength_mid", "strength_high", "name", "door", "lift",
		"order", "jars", "two_hoses", "soup", "coal", "coal_good", "coal_early", "coal_late", "draw_good",
		"draw_bad", "result_high", "result_mid", "result_low", "smoke", "terrace", "ring", "leave", "after",
		"drop_bogdan", "drop_ivan", "abort"]
const TAPPED := ["Kelner", "Barman", "Goście", "Oliwka", "Mistrz", "Ivan", "Bogdan"]


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	var data := Shisha.load_data()
	_check_lines(data, digest)
	_check_votes(digest)
	_check_game(data.get("jars", []), digest)
	_check_meshes(digest)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(m["graph"], map)
	_check_map(g, m.get("origin", [52.234, 21.024]), digest)
	if problems.is_empty():
		print("check_shisha: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("check_shisha: " + p)
		quit(1)


func _check_lines(data: Dictionary, digest: PackedStringArray) -> void:
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var scenes: Dictionary = data.get("scenes", {})
	var n := 0
	for id: String in SCENES:
		var rows: Array = scenes.get(id, [])
		if rows.is_empty():
			problems.append("scene '%s' missing or empty" % id)
		for r: Array in rows:
			n += 1
			if r.size() != 3 or String(r[0]) == "":
				problems.append("scene %s: a line is not [speaker, pl, en]: %s" % [id, r])
				continue
			_line_ok(id, [r[1], r[2]], banned)
	var taps: Dictionary = data.get("taps", {})
	for who: String in TAPPED:
		var rows: Array = taps.get(who, [])
		if rows.size() < 2:
			problems.append("taps: %s has %d lines (2+)" % [who, rows.size()])
		for r: Array in rows:
			n += 1
			_line_ok("tap " + who, r, banned)
	var jars: Array = data.get("jars", [])
	var ids := {}
	for j: Dictionary in jars:
		ids[String(j["id"])] = true
		for k in ["sweet", "cool"]:
			if float(j[k]) < 0.0 or float(j[k]) > 5.0:
				problems.append("jar %s: %s %s outside 0..5" % [j["id"], k, j[k]])
		_line_ok("jar", [j["pl"], j["en"]], banned)
	if jars.size() != 6 or ids.size() != 6 or not ids.has("zupa"):
		problems.append("jars: %d (%d ids), want six and the tomato soup" % [jars.size(), ids.size()])
	digest.append("%d lines, %d jars" % [n, jars.size()])


func _line_ok(group: String, l: Array, banned: Array) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without both languages: %s" % [group, l])
		return
	for k in 2:
		var t := String(l[k])
		if t.length() > BUBBLE:
			problems.append("%s: %d characters (max %d): %s" % [group, t.length(), BUBBLE, t])
		var low := t.to_lower()
		for b in banned:
			var w := String(b).to_lower()
			if w.length() >= 3 and (" " + low + " ").contains(" " + w) and low.contains(w):
				problems.append("%s: brand '%s' in %s" % [group, b, t])


## A vote card's three answers in one row, letters (PT-46: stacked or longer answers left the side
## card beside the car no room, so it never showed; 'HERBATA RANDKA POLITYKA' was too wide).
const VOTE_ROW := 20


func _check_votes(digest: PackedStringArray) -> void:
	var scenes := Shisha.load_scenes()
	for k in 3:
		var c := Shisha.vote_card(k)
		if (c[4] as PackedStringArray).size() != 3:
			problems.append("vote %d: %d answers (3)" % [k, (c[4] as PackedStringArray).size()])
		# PT-46: a vote card rides in the side column beside the car, its answers in one row.
		for side in 2:
			var row := 0
			for b: String in c[4]:
				row += b.get_slice("|", side).length()
			if row > VOTE_ROW:
				problems.append("vote %d: answers %d letters in a row (over %d: the side card won't fit)" % [k, row, VOTE_ROW])
		for i in 3:
			var v := {}
			Shisha.apply_vote(v, k, i)
			if not scenes.has(Shisha.vote_scene(v, k)):
				problems.append("vote %d answer %d: no scene %s" % [k, i, Shisha.vote_scene(v, k)])
		var d := {}
		Shisha.apply_vote(d, k, Shisha.default_vote(k))
		if d.is_empty():
			problems.append("vote %d: the default sets nothing" % k)
	var full := Shisha.pay_for("smoke", 9)
	var half := Shisha.pay_for("leave", 9)
	if int(half[0]) * 2 != int(full[0]) or int(half[1]) != 0 or int(full[1]) <= Shisha.RESPECT:
		problems.append("pay: smoke %s, leave %s" % [full, half])
	if not Shisha.open_at(23.0) or not Shisha.open_at(1.0) or Shisha.open_at(12.0):
		problems.append("hours: 23 %s, 1 %s, 12 %s" % [Shisha.open_at(23.0), Shisha.open_at(1.0), Shisha.open_at(12.0)])
	digest.append("votes, pay %s/%s" % [full, half])


func _check_game(jars: Array, digest: PackedStringArray) -> void:
	var by := {}
	for j: Dictionary in jars:
		by[String(j["id"])] = j
	if by.size() < 6:
		return
	for a: Dictionary in jars:
		for b: Dictionary in jars:
			for s in [1, 3, 5]:
				var h := Lounge.friends_hearts(a, b, s)
				if h.x < 0 or h.x > 3 or h.y < 0 or h.y > 3:
					problems.append("hearts %s+%s at %d: %s" % [a["id"], b["id"], s, h])
	if Lounge.friends_hearts(by["zupa"], by["arbuz"], 3) != Vector2i(0, 3):
		problems.append("the soup is not a legend")
	var mid := Lounge.friends_hearts(by["jablko"], by["mgla"], 3)
	var strong := Lounge.friends_hearts(by["jablko"], by["mgla"], 5)
	var light := Lounge.friends_hearts(by["jablko"], by["mgla"], 1)
	if strong.y <= mid.y or light.x < mid.x or light.y >= mid.y:
		problems.append("strength: mid %s strong %s light %s" % [mid, strong, light])
	var best5: Array = Lounge.best_jars(jars, 5)
	var best3: Array = Lounge.best_jars(jars, 3)
	var h5 := Lounge.friends_hearts(by[best5[0]], by[best5[1]], 5)
	var h3 := Lounge.friends_hearts(by[best3[0]], by[best3[1]], 3)
	if h5.x + h5.y != 6 or h3.x + h3.y >= 6:
		problems.append("perfect mix: strong %s %s, mid %s %s" % [best5, h5, best3, h3])
	var w1 := Lounge.coal_band(1)
	var w5 := Lounge.coal_band(5)
	if w5.y - w5.x >= w1.y - w1.x or w5.x <= 0.0 or w1.y >= 1.0:
		problems.append("coal bands: 1 %s, 5 %s" % [w1, w5])
	for s in [1, 3, 5]:
		var band := Lounge.coal_band(s)
		if int(Lounge.coal_result((band.x + band.y) * 0.5, s)[0]) != 2 or int(Lounge.coal_result(band.x - 0.05, s)[0]) != 0 \
				or String(Lounge.coal_result(band.y + 0.05, s)[1]) != "coal_late":
			problems.append("coal at strength %d" % s)
	if not Lounge.draw_ok((Lounge.DRAW_BAND.x + Lounge.DRAW_BAND.y) * 0.5) or Lounge.draw_ok(0.2) or Lounge.draw_ok(1.0):
		problems.append("draw band")
	if Lounge.total(Vector2i(3, 3), 2, true) != 9 or Lounge.total(Vector2i.ZERO, 0, false) != 0:
		problems.append("total")
	if Lounge.result_scene(9) != "result_high" or Lounge.result_scene(5) != "result_mid" or Lounge.result_scene(1) != "result_low":
		problems.append("verdicts")
	for f: String in ["ivan", "bogdan", "master"]:
		if not by.has(Lounge.first_jar(f)):
			problems.append("first jar for %s" % f)
	digest.append("perfect %s strong" % "+".join(best5))


func _check_meshes(digest: PackedStringArray) -> void:
	var mesh := Lounge.room_mesh()
	if mesh.get_surface_count() != 1:
		problems.append("lounge mesh: %d surfaces" % mesh.get_surface_count())
	var tris := (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	if tris > 40000:
		problems.append("lounge mesh: %d triangles (40k max)" % tris)
	for ter in [false, true]:
		for row: Array in Lounge.light_pose(ter, 3.0):
			var t: Transform3D = row[0]
			if not t.origin.is_finite() or not t.basis.x.is_finite():
				problems.append("light pose NaN")
	digest.append("lounge %d tris" % tris)


func _check_map(g: LaneGraph, org: Array, digest: PackedStringArray) -> void:
	var f := Shisha.find_kerbs(g, org)
	var want := {"home": Shisha.IVAN_LL, "court": Shisha.COURT_LL, "door": Shisha.LOUNGE_LL}
	for k: String in want:
		var kerb: Dictionary = f[k]
		if kerb.is_empty():
			problems.append("%s: no kerb" % k)
			continue
		var ll: Array = want[k]
		var q := Notebook.project(org, float(ll[0]), float(ll[1]))
		var at: Vector3 = kerb["at"]
		var d := Vector2(at.x, at.z).distance_to(q)
		if d > 90.0:
			problems.append("%s: kerb %.0f m from its place" % [k, d])
		if verbose:
			print("%s: %.0f,%.0f on %s (%.0f m)" % [k, at.x, at.z, kerb["street"], d])
	if f["door"].is_empty() or f["home"].is_empty() or f["court"].is_empty():
		return
	if not "Plater" in String(f["door"]["street"]):
		problems.append("door on %s, not Emilii Plater" % f["door"]["street"])
	# The entrance (F 2026-11-11): the gold door ring stands in front of the revolving door, on
	# the kerb's side of the facade, and close enough to the kerb to read as one entrance.
	var en := Shisha.entry_point(f["door"]["at"])
	var kd: Vector3 = f["door"]["at"]
	var a0: Vector2 = Landmarks.WCF_LOW[0]
	var a1: Vector2 = Landmarks.WCF_LOW[1]
	var revolving := a0.lerp(a1, Landmarks.WCF_DOOR_T)
	var e2 := Vector2(en.x, en.z)
	var k2 := Vector2(kd.x, kd.z)
	if absf(e2.distance_to(revolving) - Shisha.ENTRY_OUT) > 0.5 or e2.distance_to(k2) >= revolving.distance_to(k2):
		problems.append("entry %s: not in front of the revolving door %s toward the kerb" % [e2, revolving])
	if e2.distance_to(k2) > 45.0:
		problems.append("entry %.0f m from the door kerb (45 max)" % e2.distance_to(k2))
	digest.append("entry %.0f m from the kerb" % e2.distance_to(k2))
	var h: Vector3 = f["home"]["at"]
	var c: Vector3 = f["court"]["at"]
	var dd: Vector3 = f["door"]["at"]
	var direct := Vector2(h.x, h.z).distance_to(Vector2(dd.x, dd.z))
	var via := Vector2(h.x, h.z).distance_to(Vector2(c.x, c.z)) + Vector2(c.x, c.z).distance_to(Vector2(dd.x, dd.z))
	if via > direct * 1.35:
		problems.append("the courts are off the way: %.0f m via, %.0f m direct" % [via, direct])
	digest.append("home→court→door %.0f m (direct %.0f)" % [via, direct])
