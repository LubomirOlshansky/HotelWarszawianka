extends SceneTree
## Sekretny rave (scripts/rave.gd, F's ask 2026-11-06): its rules headless, from the committed map
## data (map/centrum.json: the lane graph and the origin) and data/dialogue.json; seeded:
##   1. the meshes: the light cone, the booth and the club's room one surface each (one draw call apiece);
##   2. the lines: LEKTI's invites name {pw}, the rumours name MORDOR FM, Mati's tags (board,
##      board_smola, ride 10+, meet, go, go_smola, door_ok, door_out, abort), the
##      meeting point's lines name {where}, the crowd's night and day; Polish and English, bubbles
##      under 90 characters (the radio's under 200), no real brand (brand_denylist.json); the club's
##      people (club_dj, club_red, club_ziomek, club_bar, club_kolek, club_crowd, club_dance, club_patio*) 3+ each;
##   3. the clock: a rave on Friday and Saturday nights (and Thursday's), not on Sunday's, not by
##      day; the day rave on weekend afternoons only; LEKTI only on a rave night's evening;
##   4. the door: three questions, each with three different answers and the right one among them,
##      the password among them at a secret rave and never at Smoła; on a strict door all three
##      right lets you in, anything less sends you home ("Nie tym razem"); the door is easy for now
##      (DOOR_STRICT off, F 2026-11-10: any answer gets you in); the lights' pose has no NaN, the strobe dark with
##      `calm`; the club's lights stay inside the room, the dance's beat check is on the beat;
##   5. the real lane graph: every spot and Smoła found with a door on a ground road within 160 m,
##      Mati's pickup found from 30 seeded places, a meeting point 260-820 m from each night spot;
##   6. main.gd's arrow: every quest branch of `_show_target` ends in a return, so the next branch's
##      "nothing on" can't hide the arrow and re-fire the camera's look every frame (F 2026-11-10).
## Prints "check_rave: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_rave.gd [-- --verbose]

const Rave := preload("res://scripts/rave.gd")
const Club := preload("res://scripts/club.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Notebook := preload("res://scripts/notebook.gd")
const BUBBLE := 90


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
	_check_meshes(digest)
	_check_lines(digest)
	_check_clock(digest)
	_check_door(digest)
	_check_targets(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_map(g, map, data.get("origin", [52.234, 21.024]), digest)
	if problems.is_empty():
		print("check_rave: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_rave: %d problems" % problems.size())
		quit(1)


func _check_meshes(digest: PackedStringArray) -> void:
	var tris := 0
	for row: Array in [["cone", Rave.cone_mesh()], ["booth", Rave.booth_mesh()], ["club room", Club.room_mesh()], ["patio", Club.patio_mesh()]]:
		var m: ArrayMesh = row[1]
		if m.get_surface_count() != 1:
			problems.append("%s: %d surfaces (want 1)" % [row[0], m.get_surface_count()])
		tris += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	var cone := Rave.cone_mesh().get_aabb()
	if absf(cone.size.y - 1.0) > 0.01 or cone.position.y < -0.01:
		problems.append("cone mesh not unit length from the origin: %s" % cone)
	digest.append("4 meshes, %d triangles" % tris)


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var n := 0
	for l: Array in all.get("rave_lekti", []):
		n += 1
		_line_ok("rave_lekti", l, banned, 200)
		if not String(l[0]).contains("{pw}") or not String(l[1]).contains("{pw}"):
			problems.append("rave_lekti without {pw}: %s" % l[0])
	# LEKTI's voice: a clip for every line and every password, in the order rave.gd plays them.
	var lekti: Array = all.get("rave_lekti", [])
	for i in lekti.size():
		for pw: String in Rave.PASSWORDS:
			for f in Rave.voice_files(i, pw):
				if not ResourceLoader.exists(f) and not problems.has("voice clip missing: %s" % f):
					problems.append("voice clip missing: %s" % f)
	digest.append("%d voice clips" % (lekti.size() + Rave.PASSWORDS.size()))
	if all.get("rave_lekti", []).size() < 4:
		problems.append("rave_lekti: %d lines (want 4+)" % all.get("rave_lekti", []).size())
	for l: Array in all.get("rave_rumour", []):
		n += 1
		_line_ok("rave_rumour", l, banned, 200)
		if not String(l[0]).contains("MORDOR") and not String(l[0]).contains("Mordor"):
			problems.append("rave_rumour doesn't send you to MORDOR FM: %s" % l[0])
	var by_tag := _tags(all, "rave_ziomek", banned)
	for tag: String in ["board", "board_smola", "ride", "meet", "go", "go_smola", "door_ok", "door_out", "abort"]:
		var want := 10 if tag == "ride" else 1
		if int(by_tag.get(tag, 0)) < want:
			problems.append("rave_ziomek: %d lines tagged %s (want %d+)" % [int(by_tag.get(tag, 0)), tag, want])
	for l: Array in all.get("rave_meet", []):
		n += 1
		_line_ok("rave_meet", l, banned)
		if not String(l[0]).contains("{where}") or not String(l[1]).contains("{where}"):
			problems.append("rave_meet without {where}: %s" % l[0])
	var crowd := _tags(all, "rave_crowd", banned)
	for tag: String in ["night", "day"]:
		if int(crowd.get(tag, 0)) < 5:
			problems.append("rave_crowd: %d %s lines (want 5+)" % [int(crowd.get(tag, 0)), tag])
	for group: String in ["club_dj", "club_red", "club_ziomek", "club_bar", "club_kolek", "club_crowd", "club_dance", "club_patio", "club_patio_bar", "club_patio_dj"]:
		var rows: Array = all.get(group, [])
		if rows.size() < 3:
			problems.append("%s: %d lines (want 3+)" % [group, rows.size()])
		for l: Array in rows:
			n += 1
			_line_ok(group, l, banned)
	for s: Dictionary in Rave.SPOTS:
		for w: String in s["where"]:
			_line_ok("where", [w, w], banned)
	for q: Dictionary in Rave.QUESTIONS:
		for row: Array in [q["q"], q["right"], q["wrong"][0], q["wrong"][1]]:
			_line_ok("door", row, banned, 42)
	for p: String in Rave.PASSWORDS:
		_line_ok("password", [p, p], banned, 14)
	for k in by_tag:
		n += int(by_tag[k])
	for k in crowd:
		n += int(crowd[k])
	digest.append("%d lines" % n)


func _tags(all: Dictionary, group: String, banned: Array) -> Dictionary:
	var by_tag := {}
	for l: Array in all.get(group, []):
		var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
		by_tag[only] = int(by_tag.get(only, 0)) + 1
		_line_ok(group, l, banned)
	if by_tag.has(""):
		problems.append("%s: %d lines without a tag" % [group, by_tag[""]])
	return by_tag


func _line_ok(group: String, l: Array, banned: Array, most := BUBBLE) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without both languages: %s" % [group, l])
		return
	for k in 2:
		var t := String(l[k]).replace("{pw}", "TRAMWAJ ZERO").replace("{where}", "w starej zajezdni za torami na Pradze")
		if t.length() > most and group not in ["rave_meet"]:
			problems.append("%s: %d characters (max %d): %s" % [group, t.length(), most, t])
		var low := t.to_lower()
		for b in banned:
			var w := String(b).to_lower()
			if w.length() >= 3 and (" " + low + " ").contains(" " + w) and low.contains(w):
				problems.append("%s: brand '%s' in %s" % [group, b, t])


func _check_clock(digest: PackedStringArray) -> void:
	# [hour, weekday (1 Monday), night rave, day rave, LEKTI]
	var cases := [
		[23.0, 5, true, false, true], [1.5, 6, true, false, true], [3.0, 7, true, false, true],
		[23.0, 4, true, false, true], [1.0, 1, false, false, false], [23.0, 7, false, false, false],
		[14.0, 5, false, true, false], [14.0, 7, false, true, false], [14.0, 2, false, false, false],
		[19.5, 5, false, true, true], [5.0, 6, true, false, false], [7.0, 6, false, false, false],
	]
	for c: Array in cases:
		var got := [Rave.night_on(c[0], c[1]), Rave.day_on(c[0], c[1]), Rave.tease_on(c[0], c[1])]
		if got != [c[2], c[3], c[4]]:
			problems.append("clock %.1f h day %d: night/day/LEKTI %s (want %s)" % [c[0], c[1], got, [c[2], c[3], c[4]]])
	digest.append("%d clock cases" % cases.size())


func _check_door(digest: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for seed in 40:
		rng.seed = seed
		for pw: String in ["", Rave.PASSWORDS[seed % Rave.PASSWORDS.size()]]:
			var quiz := Rave.door_quiz(pw, rng)
			if quiz.size() != 3:
				problems.append("door_quiz gave %d questions" % quiz.size())
				continue
			var has_pw := false
			for q: Array in quiz:
				var answers: Array = q[1]
				var right: int = q[2]
				if answers.size() != 3 or right < 0 or right > 2:
					problems.append("door question %s: %d answers, right %d" % [q[0][0], answers.size(), right])
					continue
				if answers[0] == answers[1] or answers[1] == answers[2] or answers[0] == answers[2]:
					problems.append("door question %s: repeated answers" % q[0][0])
				if q[0][0] == "Hasło?":
					has_pw = true
					if answers[right][0] != pw:
						problems.append("the password question's right answer is %s, not %s" % [answers[right][0], pw])
			if has_pw != (pw != ""):
				problems.append("password asked %s with pw '%s'" % [has_pw, pw])
	for row: Array in [[3, "in"], [2, "out"], [1, "out"], [0, "out"]]:
		if Rave.door_result(row[0], true) != row[1]:
			problems.append("strict door_result(%d) = %s (want %s)" % [row[0], Rave.door_result(row[0], true), row[1]])
	# F 2026-11-10: for now every answer gets you in (DOOR_STRICT off).
	for right: int in [0, 1, 2, 3]:
		if Rave.door_result(right, false) != "in" or Rave.wrong_ends(false):
			problems.append("an easy door turns the player away with %d right" % right)
	for t: float in [0.0, 1.3, 7.7, 100.25]:
		for calm: bool in [false, true]:
			var pose := Rave.light_pose(t, calm)
			if pose.size() != Rave.BEAMS + Rave.LASERS + 1:
				problems.append("light_pose: %d instances" % pose.size())
			for p: Array in pose:
				var tr: Transform3D = p[0]
				if not tr.origin.is_finite() or not tr.basis.x.is_finite() or not tr.basis.y.is_finite():
					problems.append("light_pose: not finite at t %.2f" % t)
			if calm and (pose[pose.size() - 1][1] as Color).v > 0.0:
				problems.append("the strobe flashes with calm on")
	for t: float in [0.0, 3.3, 61.7]:
		for red: bool in [false, true]:
			var lights := Club.room_lights(t, false, red)
			if lights.size() != Rave.BEAMS + Rave.LASERS + 1:
				problems.append("room_lights: %d instances" % lights.size())
			for p: Array in lights:
				var tr: Transform3D = p[0]
				var tip := tr * Vector3(0, 1, 0)
				if not tip.is_finite() or absf(tip.x) > Club.ROOM.x or absf(tip.z) > Club.ROOM.y or tip.y < -0.5:
					problems.append("a room light reaches out of the room: %s" % tip)
	for t: float in [0.0, 4.1, 77.0]:
		var pl := Club.patio_lights(t)
		if pl.size() != Rave.BEAMS + Rave.LASERS + 1:
			problems.append("patio_lights: %d instances" % pl.size())
		for p: Array in pl:
			var tip: Vector3 = (p[0] as Transform3D) * Vector3(0, 1, 0)
			if not tip.is_finite() or absf(tip.x) > Club.PATIO.x * 0.5 or absf(tip.z) > Club.PATIO.y * 0.5 or tip.y < -0.5:
				problems.append("a patio light reaches out of the yard: %s" % tip)
	for l: String in Rave.entry_note():
		if l.length() > 110 or not l.contains(str(Rave.ENTRY)):
			problems.append("entry note: %s" % l)
	if Club.beat_offset(60.0 / Club.BPM * 7.0) > 0.001 or Club.beat_offset(60.0 / Club.BPM * 7.5) < 0.2:
		problems.append("beat_offset off the beat")
	if Club.beat_offset(60.0 / Club.PATIO_BPM * 5.0, Club.PATIO_BPM) > 0.001 or Club.beat_offset(60.0 / Club.PATIO_BPM * 5.5, Club.PATIO_BPM) < 0.2:
		problems.append("beat_offset off the patio's beat")
	for f: String in [Club.MUSIC_SALA, Club.MUSIC_PATIO]:
		if not ResourceLoader.exists(f):
			problems.append("no club music " + f)
	digest.append("door 80 quizzes, room and patio lights inside")


func _check_map(g: LaneGraph, map: Node3D, origin: Array, digest: PackedStringArray) -> void:
	var spots := Rave.find_spots(g, map, origin)
	if spots.size() != Rave.SPOTS.size():
		var found := spots.map(func(s: Dictionary) -> String: return s["id"])
		problems.append("spots found %s of %d" % [found, Rave.SPOTS.size()])
	var club := Rave.find_club(g, map, origin)
	if club.is_empty():
		problems.append("Smoła has no door on a ground road")
	# The two questlines' starts in person (F 2026-11-09): Mati's block and pod Rotundą, each on a
	# ground road, far enough apart to be two badges on the map.
	var starts: Array[Vector2] = []
	for ll: Array in [Rave.HOME_LL, Rave.SMOLA_START_LL]:
		var k := Rave.kerb_near(g, Notebook.project(origin, float(ll[0]), float(ll[1])), 120.0)
		if k.is_empty():
			problems.append("no ground road within 120 m of the start %s" % [ll])
		else:
			starts.append(Vector2(k["at"].x, k["at"].z))
	if starts.size() == 2 and starts[0].distance_to(starts[1]) < 300.0:
		problems.append("the rave's and Smoła's starts are %.0f m apart" % starts[0].distance_to(starts[1]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var far := 0.0
	for s: Dictionary in spots:
		var at: Vector3 = s["at"]
		var d: Vector3 = s["door"]["at"]
		var dd := Vector2(at.x, at.z).distance_to(Vector2(d.x, d.z))
		far = maxf(far, dd)
		if not bool(s["night"]):
			continue
		var meet := Rave.kerb_ring(g, Vector2(at.x, at.z), Rave.MEET_FROM, Rave.MEET_TO, Vector2.ZERO, rng)
		if meet.is_empty():
			problems.append("%s: no meeting point" % s["id"])
		else:
			var md := Vector2(meet["at"].x, meet["at"].z).distance_to(Vector2(at.x, at.z))
			if md < 260.0 or md > 820.0:
				problems.append("%s: meeting point %.0f m away" % [s["id"], md])
		if verbose:
			print("  %s at %d,%d, door %.0f m on %s" % [s["id"], roundi(at.x), roundi(at.z), dd, s["door"]["street"]])
	var found := 0
	for k in 30:
		var from := Vector2(rng.randf_range(-1800.0, 1200.0), rng.randf_range(-1200.0, 1500.0))
		if not Rave.kerb_ring(g, from, Rave.PICK_FROM, Rave.PICK_TO, Vector2.ZERO, rng).is_empty():
			found += 1
	if found < 27:
		problems.append("Mati's pickup found from %d of 30 places" % found)
	digest.append("%d spots + Smoła, doors within %.0f m, pickups %d/30" % [spots.size(), far, found])


## Every `_new_target(` in main.gd's `_show_target` is followed by a `return` before the next
## branch: a missing one (the rave's, 78d05081 until 2026-11-10) fell through to "nothing on".
func _check_targets(digest: PackedStringArray) -> void:
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var a := src.find("\nfunc _show_target(")
	var b := src.find("\nfunc ", a + 10)
	if a < 0 or b < 0:
		problems.append("main.gd: _show_target not found")
		return
	var lines := src.substr(a, b - a).split("\n")
	var n := 0
	for i in lines.size():
		if not lines[i].strip_edges().begins_with("_new_target("):
			continue
		n += 1
		var ok := true  # the function's last branch ends with it
		for k in range(i + 1, lines.size()):
			var l := lines[k].strip_edges()
			if l == "" or l.begins_with("#"):
				continue
			if not lines[k].begins_with("\t"):
				break  # past the function's end
			ok = l == "return"
			break
		if not ok:
			problems.append("main.gd _show_target: no return after line %d's _new_target" % i)
	digest.append("%d target branches return" % n)
