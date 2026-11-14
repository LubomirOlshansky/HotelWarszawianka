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
##      both starts on a ground road, 300 m apart, and past the start beacon's reach from the spawn;
##   6. main.gd's arrow: every quest branch of `_show_target` ends in a return, so the next branch's
##      "nothing on" can't hide the arrow and re-fire the camera's look every frame (F 2026-11-10);
##   7. the play (the nights on the activity kit, a real Rave on the real lane graph with the shared
##      stand-ins of tools/fakes.gd, a fixed seed, its own `_process` a frame at a time): LEKTI's tease
##      (on MORDOR FM and off it; none outside the hours, with the timer off or the world not free),
##      the call after `call_in`, missed, declined; the offer declined, missed, with no kerb to meet
##      at; JADĘ! and the amber dashed pickup ring, boarding by stopping, the meeting point ("???",
##      the hooded man), the reveal, the door ring in the night's colour; the three questions
##      (stacked, the password among the answers at a secret rave and never at Smoła), "out" after
##      DOOR_LIFE, "in" after three answers, the pay, the two-button card; PŁACĘ with and without
##      cash, POTEM, the card's own 45 s and 12 s; the next night spot after a result and not after
##      a ✕; the ✕ in PICKUP, MEET and DRIVE (and not at the door); meeting in person, for both
##      nights; `busy`, `busy_kind`, `idle`, `under_way`; the script's dice, draw for draw through
##      one night; the director refusing a second activity.
## Prints "check_rave: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_rave.gd [-- --verbose]

const Rave := preload("res://scripts/rave.gd")
const Club := preload("res://scripts/club.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Activity := preload("res://scripts/activity.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Story := preload("res://scripts/story_quests.gd")
const BUBBLE := 90
const DT := 1.0 / 60.0


## dialogue.gd's `line` over the real data: the first line of a group.
class Talk extends Fakes.Dialogue:
	var lines := {}
	func line(group: String, _tag := "", _prefer := false) -> Array:
		var rows: Array = lines.get(group, [])
		return rows[0] if not rows.is_empty() else []


var problems: Array[String] = []
var verbose := false
## The play's stand-ins and inputs.
var _rv: Rave
var _hud: Fakes.Hud
var _bubbles: Fakes.Bubbles
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _talk: Talk
var _radio: Fakes.Radio
var _sounds: Fakes.CitySounds
var _director: Activities
var _other: Activity
var _pos := Vector3.ZERO
var _kmh := 0.0
var _hour := 23.0
var _weekday := 5
var _focus := Vector3(1.0e6, 0.0, 1.0e6)
var _world_free := true
var _entered: Array = []
var _plays := 0
var _nights := 0


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
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	var sp: Dictionary = data.get("spawn", {})
	_check_map(g, map, data.get("origin", [52.234, 21.024]), digest, Vector2(float(sp.get("x", 0.0)), float(sp.get("z", 0.0))))
	_play(g, data.get("origin", [52.234, 21.024]), digest)
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


func _check_map(g: LaneGraph, map: Node3D, origin: Array, digest: PackedStringArray, spawn: Vector2) -> void:
	var spots := Rave.find_spots(g, map, origin)
	if spots.size() != Rave.SPOTS.size():
		var found := spots.map(func(s: Dictionary) -> String: return s["id"])
		problems.append("spots found %s of %d" % [found, Rave.SPOTS.size()])
	var club := Rave.find_club(g, map, origin)
	if club.is_empty():
		problems.append("Smoła has no door on a ground road")
	# The two questlines' starts in person (F 2026-11-09): Mati's block and Jerozolimskie, each on a
	# ground road, far enough apart to be two badges on the map.
	var starts: Array[Vector2] = []
	for ll: Array in [Rave.HOME_LL, Rave.SMOLA_START_LL]:
		var k := Rave.kerb_near(g, Notebook.project(origin, float(ll[0]), float(ll[1])), 120.0)
		if k.is_empty():
			problems.append("no ground road within 120 m of the start %s" % [ll])
		else:
			starts.append(Vector2(k["at"].x, k["at"].z))
	# No start in the game's first view (F 2026-11-11): past the start beacon's reach from the spawn.
	for s: Vector2 in starts:
		if s.distance_to(spawn) <= Story.BEACON_R + 20.0:
			problems.append("a start %.0f m from the spawn (want over %.0f m)" % [s.distance_to(spawn), Story.BEACON_R + 20.0])
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


# --- the play ---------------------------------------------------------------------------------

func _ok(cond: bool, what: String) -> void:
	_plays += 1
	if not cond:
		problems.append("the play: " + what)


func _make(g: LaneGraph, origin: Array) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_hud = Fakes.Hud.new()
	_bubbles = Fakes.Bubbles.new()
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	_talk = Talk.new()
	_talk.bubbles = _bubbles
	_talk.lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	_radio = Fakes.Radio.new()
	_radio.station = 0
	_radio.stations = {"mordor_fm": 3}
	_sounds = Fakes.CitySounds.new()
	var map := Fakes.FlatMap.new()
	for node: Node in [_hud, _bubbles, _wallet, _calls, _talk, _radio, _sounds, map]:
		world.add_child(node)
	_rv = Rave.new()
	_rv.hud = _hud
	_rv.dialogue = _talk
	_rv.wallet = _wallet
	_rv.map = map
	_rv.graph = g
	_rv.radio = _radio
	_rv.city_sounds = _sounds
	_rv.origin = origin
	_rv.vehicle = func() -> Array: return [_pos, _kmh, false]
	_rv.focus = func() -> Vector3: return _focus
	_rv.calendar = func() -> Dictionary: return {"hour": _hour, "weekday": _weekday}
	_rv.enter_club = func(pl: String, en: String) -> void: _entered.append([pl, en])
	world.add_child(_rv)
	_rv.setup(world, 7)
	_rv.set_process(false)
	_director = Activities.new()
	_director.world_free = func() -> bool: return _world_free
	_director.add(_rv)
	_other = Activity.new()
	_director.add(_other)
	_director.add(_calls)


func _frames(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_rv._process(DT)


func _park() -> void:
	_pos = _rv.target_position()
	_kmh = 0.0


func _is(stage: int) -> bool:
	return _rv.phase == Activity.Phase.RUN and _rv.stage == stage


func _toast(text: String) -> bool:
	for t in _hud.toasts:
		if text in t:
			return true
	return false


## The player says JADĘ! to Mati's call at the middle of the map: the pickup stage.
func _to_pickup() -> void:
	_pos = Vector3.ZERO
	_kmh = 0.0
	_hud.toasts.clear()
	_rv.ring()
	_hud.press(0)
	_hud.press(0)
	_nights += 1


## ... and on, by stopping at each target, to `stage`.
func _reach(stage: int) -> void:
	_to_pickup()
	for st: int in [Rave.Stage.PICKUP, Rave.Stage.MEET, Rave.Stage.DRIVE]:
		if st == stage:
			return
		_park()
		_frames(1.2)


## Answers the door's questions: `right` the right answers, else the first button each time.
func _answer_all(right: bool) -> void:
	for k in 3:
		_hud.press(int(_rv.quiz[_rv.quiz_i][2]) if right else 0)


func _play(g: LaneGraph, origin: Array, digest: PackedStringArray) -> void:
	_make(g, origin)
	var c := _rv
	var b: Node3D = c._beacon
	var passwords := PackedStringArray(Rave.PASSWORDS)

	# At rest: the real map gives the places; nothing is on.
	_ok(c.spots.size() == Rave.SPOTS.size() and not c.smola.is_empty() and not c.home.is_empty(), "the real graph gives the spots, Smoła and Mati's block")
	_ok(_sounds.crowds.size() == c.spots.size(), "one crowd of thump per spot")
	_ok(c.tease_in >= Rave.FIRST_TEASE.x and c.tease_in <= Rave.FIRST_TEASE.y, "LEKTI's first line is 2.5 to 5 minutes of free play away (%.0f s)" % c.tease_in)
	_ok(c.idle() and not c.busy() and not c.under_way() and not c.has_target() and c.target_position() == Vector3.INF and c.stop_spot() == Vector3.INF, "at rest: idle, not busy, no target")
	_ok(_director.list.has(c) and c.free_now.is_valid(), "the director has it")

	# The rig's toast on a rave night, near the spot; then far, the rig is off.
	_focus = c.spots[c.night_spot]["at"] + Vector3(100.0, 0.0, 0.0)
	_frames(0.5)
	_ok(_toast("Ktoś tu robi imprezę") and c.active == c.night_spot and c.active_mode == "night" and c._rig.visible, "near the night spot on a rave night: the rig is on and the toast says so")
	_focus = Vector3(1.0e6, 0.0, 1.0e6)
	_frames(0.3)
	_ok(not c._rig.visible, "far from it the rig is off")

	# LEKTI's timer: only on a rave night's evening, with the timer on and the world free.
	_hour = 12.0
	var t0: float = c.tease_in
	_frames(2.0)
	_ok(c.tease_in == t0, "no tease outside the hours")
	_hour = 23.0
	_world_free = false
	_frames(2.0)
	_ok(c.tease_in == t0, "no tease while something else is on")
	_world_free = true
	c.auto = false
	_frames(2.0)
	_ok(c.tease_in == t0, "no tease with the timer off (a test run)")
	c.auto = true
	_frames(2.0)
	_ok(c.tease_in < t0 - 1.5 and c.tease_in > t0 - 2.5, "on a rave night with the world free the timer counts (%.2f of %.2f)" % [c.tease_in, t0])

	# Mati's nights take turns: Smoła first, he rings straight away.
	c.tease_in = 0.3
	_frames(0.6)
	_ok(c.phase == Activity.Phase.RING and c.kind == "smola" and c.next_kind == "rave" and "MATI" in _hud.card and _hud.card_is(c), "the first night is Smoła's: Mati rings at once (%s)" % _hud.card)
	_ok(not c.busy() and not _director.busy() and not c.idle(), "a ringing phone is not busy, and not idle either")
	_ok(not c.ring() and not c.tease() and not c.meet_in_person("smola"), "no second call, tease or meeting while it rings")
	_frames(Rave.RING_LIFE + 0.5)
	_ok(c.phase == Activity.Phase.IDLE and _hud.card == "" and _toast("Nieodebrane połączenie: Mati"), "a call nobody answers goes, with the missed call's words")
	_ok(c.tease_in >= Rave.NEXT_TEASE.x and c.tease_in <= Rave.NEXT_TEASE.y and c.kind == "" and c.password == "" and c.quest_spot == -1, "and LEKTI is 15 to 25 minutes away again, the night forgotten (%.0f s)" % c.tease_in)

	# Then a secret rave: LEKTI on MORDOR FM.
	_radio.station = 3
	c.tease_in = 0.3
	_frames(0.6)
	var pw: String = c.password
	_ok(c.waiting and c.heard and pw in passwords and c.kind == "rave" and c.next_kind == "smola" and c.quest_spot == c.night_spot, "LEKTI speaks on MORDOR FM: heard, a password, the night's spot")
	_ok(_radio.said.size() == 1 and pw in _radio.said[0] and not "{pw}" in _radio.said[0], "his line names the password (%s)" % [_radio.said])
	_ok(c.call_in >= Rave.CALL_AFTER.x and c.call_in <= Rave.CALL_AFTER.y and c.idle() and not c.busy(), "Mati rings 30 to 75 s later; meanwhile the kit's phase is idle")
	_ok(not c.tease(), "no second tease while Mati is to ring")
	_world_free = false
	var left: float = c.call_in
	_frames(2.0)
	_ok(c.call_in == left, "Mati's clock stands while something else is on")
	_world_free = true
	c.call_in = 0.3
	_frames(0.6)
	_ok(c.phase == Activity.Phase.RING and not c.waiting and c.kind == "rave" and c.password == pw and _hud.card == "📞 MATI DZWONI", "Mati rings when his clock is out, the password kept (%s)" % _hud.card)
	_hud.press(1)
	_ok(c.idle() and not c.waiting and _hud.card == "" and _toast("Odrzucono. Mati pójdzie sam"), "a call declined: idle, with its words")
	_ok(c.tease_in >= Rave.NEXT_TEASE.x and c.tease_in <= Rave.NEXT_TEASE.y, "and LEKTI is far off again")

	# The rumour on another station, and nothing on the radio off.
	_radio.station = 0
	_ok(c.tease() and not c.heard and c.waiting and "mordor" in _radio.said.back().to_lower(), "on another station the host only passes the rumour (not heard)")
	c.ring()
	_hud.press(0)
	_ok(c.phase == Activity.Phase.OFFER and "Hasło? Trzeba było słuchać MORDOR FM" in _hud.body, "the offer after a rumour says the password was missed (%s)" % _hud.body.left(40))
	_hud.press(1)
	_ok(c.idle(), "declined")
	_radio.station = -1
	var said: int = _radio.said.size()
	_ok(not c.tease() and c.waiting and not c.heard and _radio.said.size() == said, "radio off: nothing on air, Mati still rings later")
	c.ring()
	_hud.press(1)
	_ok(c.idle() and not c.waiting, "and a declined call ends the wait")

	# The offer (LEKTI heard): the card, busy, not yet the rescue calls held.
	_radio.station = 3
	c.tease()
	pw = c.password
	c.ring()
	_hud.press(0)
	_ok(c.phase == Activity.Phase.OFFER and _hud.card == "📞 MATI" and _hud.buttons == 2 and _hud.card_is(c) and "Słyszałeś Lektiego" in _hud.body and not c.pickup.is_empty(),
			"answered: Mati's offer, two buttons, his own card, a kerb found (%s)" % _hud.card)
	_ok(c.busy() and _director.busy() and _director.busy_tag() == "rave" and _director.current() == c and not c.under_way(), "from the offer card on the night is busy, but not yet under way")
	_ok(not _calls._held() and not _director.may_start(_other), "the rescue calls are not held yet; the director refuses a second activity")
	_hud.toasts.clear()
	_hud.press(1)
	_ok(c.idle() and _toast("nie płacz") and not _toast("Odrzucono") and _hud.card == "" and c.pickup.is_empty(), "the offer declined: idle, with his words")
	c.ring()
	_hud.press(0)
	_hud.toasts.clear()
	_frames(Rave.RING_LIFE + 0.5)
	_ok(c.idle() and _hud.card == "" and _toast("Nieodebrane połączenie"), "an offer nobody answers goes too")
	_pos = Vector3(1.0e6, 0.0, 1.0e6)
	c.ring()
	_hud.press(0)
	_ok(c.idle() and _hud.card == "" and c.pickup.is_empty() and not c.busy(), "no kerb to meet at: the call ends where the offer would be")
	_pos = Vector3.ZERO

	# JADĘ!: Mati at his block.
	_radio.station = 0
	_to_pickup()
	b = c._beacon
	_ok(_is(Rave.Stage.PICKUP) and _calls._held() and _toast("Jedź po Matiego"), "JADĘ!: on the way to Mati, the rescue calls held")
	_ok(c.under_way() and c.busy() and c.has_target() and c.target_position() == c.pickup["at"] and c.target_colour() == Rave.PICK_COLOUR, "the target is Mati's kerb, in the pickup's amber")
	_ok(_director.targeted() == c and c.stop_spot() == Vector3.INF and c.target_label(50) == "50 m", "the director points at the night; no stop assist; the arrow says metres")
	_ok(b.visible and b.position == c.pickup["side"] and b.pattern == Beacon.Pattern.DASHED and is_equal_approx(b._ring_radius, Rave.PICK_R) and b._person.visible
			and b._colour == Rave.PICK_COLOUR, "the dashed amber ring on the pavement beside the kerb, Mati in it")
	_ok(not c._hood.visible, "no hooded man yet")
	var t: Vector3 = c.target_position()
	_pos = Vector3(t.x - 200.0, t.y, t.z + 80.0)
	_kmh = 40.0
	_frames(1.0)
	_ok(_hud.status_title == "MATI · pod blokiem" and _hud.tint == Rave.PICK_COLOUR and "Zatrzymaj się przy Matim" in _hud.status, "the status names Mati, in amber (%s)" % _hud.status_title)
	_park()
	_kmh = 12.0
	_frames(1.6)
	_ok(_is(Rave.Stage.PICKUP), "rolling through the ring is not stopping")
	_kmh = 0.0
	_pos = t + Vector3(Rave.PICK_R + 1.0, 0.0, 0.0)
	_frames(1.6)
	_ok(_is(Rave.Stage.PICKUP), "stopped a metre outside the ring is not at Mati's")
	_park()
	_frames(1.2)
	_ok(_is(Rave.Stage.MEET) and _radio.station == 3 and _calls._held(), "stopped in the ring: Mati is in, the radio on MORDOR FM, the calls still held")

	# The meeting point.
	var m: Dictionary = c.meeting
	_ok(not m.is_empty() and c.target_position() == m["at"] and c.target_label(50) == "???", "the arrow leads to the meeting point and says ???")
	_ok(b.visible and b.position == m["side"] and b.pattern == Beacon.Pattern.SOLID and not b._person.visible and b._colour == Rave.COLOUR and is_equal_approx(b._ring_radius, Rave.MEET_R),
			"the kit's ring at the meeting point, in the night's violet, nobody in it")
	_ok(c._hood.visible and c._hood._person.visible and not c._hood._ring.visible and not c._hood._column.visible and c._hood.position == m["side"], "the hooded man stands beside it, no ring, no column")
	_far_status()
	_ok(_hud.status_title == "??? · punkt zborny" and _hud.tint == Rave.COLOUR, "the status says ??? too (%s)" % _hud.status_title)
	_bubbles.said.clear()
	_hud.toasts.clear()
	_park()
	_frames(1.2)
	var spot: Dictionary = c.spots[c.quest_spot]
	_ok(_is(Rave.Stage.DRIVE) and _toast("Lokalizacja: " + String(spot["where"][0])) and not c._hood.visible, "the reveal: the toast names the place, the hooded man goes")
	_ok(_bubbles.said.size() >= 1 and String(spot["where"][0]) in _bubbles.said[0], "and the hooded man says it (%s)" % [_bubbles.said])

	# The door ring, in the night's colour, with the bouncer in it.
	var door: Dictionary = spot["door"]
	_ok(c.target_position() == door["at"] and c.target_colour() == Rave.COLOUR and c.target_label(50) == "50 m", "the arrow leads to the door's kerb")
	_ok(b.visible and b.position == door["side"] and b.pattern == Beacon.Pattern.SOLID and b._person.visible and b._colour == Rave.COLOUR
			and is_equal_approx(b._ring_radius, Rave.DOOR_R * 0.75), "the door ring beside the kerb, solid violet, the bouncer in it")
	_far_status()
	_ok(_hud.status_title == "%s · sekretny rave" % String(spot["name"]).to_upper() and "Zatrzymaj się przy bramce" in _hud.status, "the status names the spot (%s)" % _hud.status_title)
	# The rig stays on for the quest's spot from the reveal on.
	_focus = spot["at"] + Vector3(100.0, 0.0, 0.0)
	_frames(0.3)
	_ok(c.active == c.quest_spot and c.active_mode == "night", "the quest's spot is on while the door is the goal")
	_focus = Vector3(1.0e6, 0.0, 1.0e6)

	# The ✕ is the player's until the door.
	_park()
	_frames(1.2)
	var money: int = _wallet.money
	pw = c.password
	_ok(_is(Rave.Stage.DOOR) and _hud.card == "SELEKCJA 1/3" and _hud.stacked and _hud.buttons == 3 and _hud.card_is(c), "at the door: the first question, a stacked card with three answers (%s)" % _hud.card)
	_ok(not c.has_target() and not b.visible and _hud.status == "" and c.busy(), "no target, no ring, no status line at the door")
	_ok(c.quiz.size() == 3 and c.quiz.any(func(q: Array) -> bool: return q[0][0] == "Hasło?" and (q[1] as Array).any(func(a: Array) -> bool: return a[0] == pw)), "a secret rave asks the password and offers it among the answers")
	_hud.abort_pressed.emit()
	_ok(_is(Rave.Stage.DOOR) and _hud.card != "", "the ✕ does nothing while a door card is up")

	# A question nobody answers: out.
	_frames(Rave.DOOR_LIFE - 1.0)
	_ok(_is(Rave.Stage.DOOR) and _hud.card == "SELEKCJA 1/3", "the question waits for its life")
	var spot0: int = c.night_spot
	_frames(2.0)
	_ok(_is(Rave.Stage.RESULT) and c.last_pay.get("result", "") == "out" and _hud.card == "NIE DZIŚ" and _hud.buttons == 1 and c.rejected == 1,
			"no answer in %.0f s: out, the NOT TONIGHT card with OK" % Rave.DOOR_LIFE)
	_ok(_wallet.money - money == Rave.PAY / 2 and _wallet.respect == 0, "half the fare and no respect")
	_ok(c.busy() and _hud.card_is(c), "busy until the card closes")
	_hud.abort_pressed.emit()
	_ok(_is(Rave.Stage.RESULT), "the ✕ does nothing on the result card")
	_frames(Rave.RESULT_LIFE - 3.0)
	_ok(_hud.card == "NIE DZIŚ", "the out card waits its 12 s")
	_frames(4.0)
	_ok(c.idle() and _hud.card == "" and not _director.busy() and not _calls._held(), "then closes by itself: idle, the calls back as they were")
	_ok(c.night_spot == c.night_spots()[(c.night_spots().find(spot0) + 1) % c.night_spots().size()], "the next night spot after a secret rave's result")

	# A full night: three right answers, in; the cash for the club.
	_entered.clear()
	_reach(Rave.Stage.DOOR)
	_park()
	_frames(1.2)
	pw = c.password
	_ok(_is(Rave.Stage.DOOR), "the second night: at the door")
	_hud.press(int(c.quiz[0][2]))
	_ok(_hud.card == "SELEKCJA 2/3" and _hud.stacked, "a right answer: the second question")
	_hud.press(int(c.quiz[1][2]))
	_hud.toasts.clear()
	money = _wallet.money
	var respect: int = _wallet.respect
	spot0 = c.night_spot
	_hud.press(int(c.quiz[2][2]))
	_ok(_is(Rave.Stage.RESULT) and c.last_pay.get("result", "") == "in" and c.raves == 1 and c.last_pay.get("right", 0) == 3, "three right: in")
	_ok(_wallet.money - money == Rave.PAY and _wallet.respect - respect == Rave.RESPECT and _wallet.kinds.back() == "rave", "paid the fare and the respect")
	_ok(_hud.card == "SEKRETNY RAVE" and _hud.buttons == 2 and _hud.card_is(c) and not _hud.stacked and ("Bilet: %d zł" % Rave.ENTRY) in _hud.body and "3 na 3" in _hud.body,
			"the verdict card has PŁACĘ and POTEM, and the ticket's price (%s)" % _hud.card)
	_ok(c.busy() and c.under_way() and not c.has_target(), "still busy on the result card")
	_frames(Rave.RESULT_LIFE + 1.0)
	_ok(_hud.card == "SEKRETNY RAVE", "the two-button card outlives the plain one's 12 s")
	money = _wallet.money
	_hud.press(0)
	_ok(c.idle() and _hud.card == "" and _entered == [["SEKRETNY RAVE", "SECRET RAVE"]] and _wallet.money == money - Rave.ENTRY, "PŁACĘ with cash: the club opens once, the ticket is taken")
	_ok(not _toast("Za mało gotówki"), "no cash toast")
	_ok(c.night_spot == c.night_spots()[(c.night_spots().find(spot0) + 1) % c.night_spots().size()], "the next night spot after a secret rave's result")
	_ok(not _calls._held(), "the calls are back")

	# PŁACĘ without cash, POTEM, and the card's own 45 s.
	_entered.clear()
	_reach(Rave.Stage.DOOR)
	_park()
	_frames(1.2)
	_answer_all(true)
	_wallet.money = 0
	_hud.toasts.clear()
	_hud.press(0)
	_ok(c.idle() and _entered.is_empty() and _toast("Za mało gotówki") and _wallet.money == 0, "PŁACĘ without cash: the toast, no club, nothing taken")
	_reach(Rave.Stage.DOOR)
	_park()
	_frames(1.2)
	_answer_all(true)
	money = _wallet.money
	_hud.press(1)
	_ok(c.idle() and _entered.is_empty() and _wallet.money == money and _hud.card == "", "POTEM: no club, no cash taken")
	_reach(Rave.Stage.DOOR)
	_park()
	_frames(1.2)
	_answer_all(true)
	_wallet.money = 500
	_frames(Rave.PAY_LIFE - 1.0)
	_ok(_hud.card == "SEKRETNY RAVE" and _is(Rave.Stage.RESULT), "the pay card waits its %.0f s" % Rave.PAY_LIFE)
	_frames(2.0)
	_ok(c.idle() and _entered.is_empty() and _wallet.money == 500 and _hud.card == "", "and then closes with no club and no cash taken")

	# Without a club to enter, the plain card with OK and the 12 s.
	var club: Callable = c.enter_club
	c.enter_club = Callable()
	_reach(Rave.Stage.DOOR)
	_park()
	_frames(1.2)
	_answer_all(true)
	_ok(_hud.card == "SEKRETNY RAVE" and _hud.buttons == 1 and not ("Bilet" in _hud.body), "no club to enter: OK only, no ticket line")
	_frames(Rave.RESULT_LIFE + 1.0)
	_ok(c.idle() and _hud.card == "", "closes after 12 s")
	c.enter_club = club

	# The ✕ in each stage: the night bus, Mati's goodbye, the calls given back as they were.
	for row: Array in [[Rave.Stage.PICKUP, false], [Rave.Stage.MEET, true], [Rave.Stage.DRIVE, false]]:
		_calls.paused = bool(row[1])
		_reach(int(row[0]))
		_ok(_is(int(row[0])) and _calls._held(), "the ✕ night at stage %d is on" % int(row[0]))
		var kept: int = c.night_spot
		money = _wallet.money
		_hud.toasts.clear()
		_talk.said.clear()
		_hud.abort_pressed.emit()
		_ok(c.idle() and _hud.status == "" and not b.visible and not c._hood.visible and not c.has_target() and not _director.busy(), "the ✕ at stage %d ends the night: idle, nothing up" % int(row[0]))
		_ok(_toast("Mati łapie nocny autobus") and "rave_ziomek:abort" in _talk.said and _wallet.money == money, "with the night-bus words and Mati's goodbye, nothing paid")
		_ok(_calls.paused == bool(row[1]) and _calls._held() == bool(row[1]) and c.night_spot == kept, "the calls as they were (%s) and the night spot kept" % [row[1]])
		_ok(c.tease_in >= Rave.NEXT_TEASE.x and c.tease_in <= Rave.NEXT_TEASE.y, "LEKTI far off again")
	_calls.paused = false

	# Met in person: no pickup stage, no call.
	c.tease_in = 1.0e6
	_pos = Vector3.ZERO
	_hud.toasts.clear()
	var shown: int = _hud.shown
	_ok(c.meet_in_person("rave") and _is(Rave.Stage.MEET) and _calls._held() and c.kind == "rave" and not c.password.is_empty() and not c.heard, "met at his block: Mati is in, on to the meeting point, a password drawn, not heard")
	_nights += 1
	_ok(not _toast("Jedź po Matiego") and _hud.shown == shown and c.quest_spot == c.night_spot and c._hood.visible, "no call, no offer and no pickup")
	_ok(not c.meet_in_person("rave") and not c.ring() and not c.tease() and c.busy_kind("rave") and not c.busy_kind("smola"), "no second meeting or call during the night; busy for the rave only")
	_hud.abort_pressed.emit()
	_radio.station = 3
	c.tease()
	pw = c.password
	_ok(c.meet_in_person("rave") and c.password == pw and c.heard and _is(Rave.Stage.MEET), "met after LEKTI spoke: the password and 'heard' are kept")
	_nights += 1
	_hud.abort_pressed.emit()
	_ok(c.idle() and not c.waiting, "and the ✕ ends it")
	_ok(c.meet_in_person("smola") and _is(Rave.Stage.DRIVE) and c.kind == "smola" and c.password == "" and c.meeting.is_empty(), "met at the Smoła start: straight to the club, no password, no meeting point")
	_nights += 1
	_ok(c.busy_kind("smola") and not c.busy_kind("rave") and c.target_colour() == Rave.SMOLA_COLOUR and b._colour == Rave.SMOLA_COLOUR and b.visible and not c._hood.visible,
			"Smoła's night is busy for Smoła only, its ring and arrow in the gate's red")
	_ok(c.target_position() == c.smola["door"]["at"], "the arrow leads to Smoła's door")
	var kept_spot: int = c.night_spot
	_park()
	_frames(1.2)
	_ok(_is(Rave.Stage.DOOR) and c.quiz.size() == 3 and not c.quiz.any(func(q: Array) -> bool: return q[0][0] == "Hasło?"), "Smoła's door never asks the password")
	_answer_all(true)
	_ok(_hud.card == "SMOŁA" and _hud.buttons == 2, "Smoła's verdict card is Smoła's")
	_hud.press(0)
	_ok(c.idle() and _entered == [["SMOŁA", "SMOŁA"]] and c.night_spot == kept_spot, "paid, in; Smoła's night does not move the rave")
	_entered.clear()

	# A call for Smoła by the story's button: pickup in amber, the gate's red once aboard.
	_pos = Vector3.ZERO
	_ok(c.ring("smola") and c.kind == "smola", "ring(smola) rings for Smoła")
	_hud.press(0)
	_ok(c.phase == Activity.Phase.OFFER and "Smołę" in _hud.body, "the offer is about Smoła")
	_hud.press(0)
	_nights += 1
	_ok(_is(Rave.Stage.PICKUP) and c.target_colour() == Rave.PICK_COLOUR and b._colour == Rave.PICK_COLOUR, "JADĘ!: Mati waits in amber")
	_park()
	_frames(1.2)
	_ok(_is(Rave.Stage.DRIVE) and c.target_colour() == Rave.SMOLA_COLOUR and b._colour == Rave.SMOLA_COLOUR and b.pattern == Beacon.Pattern.SOLID and _radio.station == 3,
			"aboard: straight to the door, the gate's red, the radio on MORDOR FM")
	_hud.abort_pressed.emit()
	_ok(c.idle() and not _director.busy(), "the ✕ ends it")

	# The script's dice, draw for draw through one night (the kerbs and the door's questions come
	# from the same dice, so a draw added, dropped or moved would change every night after it).
	var dice := RandomNumberGenerator.new()
	dice.seed = 11
	c._rng.seed = 11
	_radio.station = 3
	_pos = Vector3.ZERO
	c.tease()
	var word: String = Rave.PASSWORDS[dice.randi() % Rave.PASSWORDS.size()]
	var due: float = dice.randf_range(Rave.CALL_AFTER.x, Rave.CALL_AFTER.y)
	_ok(c.password == word and c.call_in == due and c._rng.state == dice.state, "the dice: LEKTI draws the password, then Mati's call")
	c.ring()
	_hud.press(0)
	var kerb: Dictionary = Rave.kerb_ring(g, Vector2.ZERO, Rave.PICK_FROM, Rave.PICK_TO, Vector2.ZERO, dice)
	_ok(not kerb.is_empty() and c.pickup.get("at") == kerb.get("at") and c._rng.state == dice.state, "the dice: the offer draws Mati's kerb")
	_hud.press(0)
	_nights += 1
	_park()
	_frames(1.2)
	var rave_at: Vector3 = c.spots[c.quest_spot]["at"]
	var from := Vector2(rave_at.x, rave_at.z)
	var kerb_at: Vector3 = kerb.get("at", Vector3.ZERO)
	var point: Dictionary = Rave.kerb_ring(g, from, Rave.MEET_FROM, Rave.MEET_TO, (Vector2(kerb_at.x, kerb_at.z) - from).normalized(), dice)
	_ok(_is(Rave.Stage.MEET) and not point.is_empty() and c.meeting.get("at") == point.get("at") and c._rng.state == dice.state, "the dice: getting in draws the meeting point and nothing else")
	_park()
	_frames(1.2)
	_ok(_is(Rave.Stage.DRIVE) and c._rng.state == dice.state, "the dice: the reveal draws nothing")
	_park()
	_frames(1.2)
	var asked: Array = Rave.door_quiz(c.password, dice)
	_ok(_is(Rave.Stage.DOOR) and c.quiz == asked and c._rng.state == dice.state, "the dice: the door draws its three questions")
	_answer_all(true)
	_hud.press(1)
	var again: float = dice.randf_range(Rave.NEXT_TEASE.x, Rave.NEXT_TEASE.y)
	_ok(c.idle() and c.tease_in == again and c._rng.state == dice.state, "the dice: the end draws LEKTI's next line, and that is all")

	# The director and the kit's one meaning of busy.
	_ok(_director.may_start(_other), "idle: the director lets another activity start")
	_reach(Rave.Stage.PICKUP)
	_ok(not _director.may_start(_other) and not _other.free_now.call(), "under way: no other activity may start")
	_hud.abort_pressed.emit()
	_other.free()
	digest.append("the play: %d nights, %d checks" % [_nights, _plays])


## Parks the car far from the target and lets one status line be written.
func _far_status() -> void:
	var t: Vector3 = _rv.target_position()
	_pos = Vector3(t.x - 200.0, t.y, t.z + 80.0)
	_kmh = 40.0
	_frames(1.0)
