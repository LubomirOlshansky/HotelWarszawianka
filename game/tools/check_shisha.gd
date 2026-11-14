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
##      the revolving door on the kerb's side (F 2026-11-11);
##   6. the play (the night on the activity kit, with the shared stand-ins of tools/fakes.gd and
##      three kerbs on a line): Ivan's own call clock (the lounge's hours, past midnight, held
##      while something else is on); a call missed, declined, the offer declined and missed, each
##      with its words; the pickups (the dashed amber ring beside the kerb, stopped inside it for
##      a moment, not rolling through and not a metre outside); the lines over the car in order;
##      the entrance's two rings (teal at the kerb, gold at the door) and both ways in; inside (no
##      target, no ✕, the lounge opened once with the night's votes); the way home, the pay, the
##      stacked result card and its life; a night that left early; a meeting in person; the ✕
##      only on the way there; the rescue calls held and given back as they were; the director;
##      the autopilot.
## Prints "check_shisha: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_shisha.gd [-- --verbose]

const Shisha := preload("res://scripts/shisha.gd")
const Lounge := preload("res://scripts/lounge.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Fakes := preload("res://tools/fakes.gd")
const DT := 1.0 / 60.0
const BUBBLE := 90
const SCENES := ["board_ivan", "leg1", "court", "board_bogdan", "flavour", "flavour_ivan", "flavour_bogdan",
		"flavour_master", "strength", "strength_low", "strength_mid", "strength_high", "name", "door", "lift",
		"order", "jars", "two_hoses", "soup", "coal", "coal_good", "coal_early", "coal_late", "draw_good",
		"draw_bad", "result_high", "result_mid", "result_low", "smoke", "terrace", "ring", "leave", "after",
		"drop_bogdan", "drop_ivan", "abort"]
const TAPPED := ["Kelner", "Barman", "Goście", "Oliwka", "Mistrz", "Ivan", "Bogdan", "Bramkarz", "Recepcja"]


var problems: Array[String] = []
var verbose := false
## The play's stand-ins and inputs.
var _night: Shisha
var _hud: Fakes.Hud
var _bubbles: Fakes.Bubbles
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _director: Activities
var _pos := Vector3.ZERO
var _kmh := 0.0
var _hour := 21.0
var _world_free := true
var _entered: Array = []
var _plays := 0


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
	await _check_arrival(digest)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var g := LaneGraph.new(m["graph"], map)
	_check_map(g, m.get("origin", [52.234, 21.024]), digest)
	_play(digest)
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
	for where: String in ["sala", "taras", "lobby", "winda"]:
		var pose := Lounge.light_pose(where, 3.0)
		if pose.size() != 6:
			problems.append("light pose %s: %d cones (6)" % [where, pose.size()])
		for row: Array in pose:
			var t: Transform3D = row[0]
			if not t.origin.is_finite() or not t.basis.x.is_finite():
				problems.append("light pose NaN")
	# The arrival (F 2026-11-11): the lobby and the cabin stand apart from the room, the terrace
	# and each other (out of each other's view); the walk stays on the lobby's floor until it goes
	# through our lift's door, which is in the left wall; the cabin's spots inside the cabin.
	var hx := Lounge.LOB.x * 0.5
	var hz := Lounge.LOB.y * 0.5
	var spots := {"room": Vector3.ZERO, "terrace": Lounge.TERRACE, "lobby": Lounge.LOBBY, "cabin": Lounge.CAB}
	for a: String in spots:
		for b: String in spots:
			if a < b and (spots[a] as Vector3).distance_to(spots[b]) < 50.0:
				problems.append("%s and %s only %.0f m apart (50 min)" % [a, b, (spots[a] as Vector3).distance_to(spots[b])])
	for p: Vector3 in [Lounge.REV_IN, Lounge.MEET, Lounge.LIFT_FRONT, Lounge.DOORMAN]:
		if absf(p.x) > hx - 0.5 or absf(p.z) > hz - 0.3:
			problems.append("lobby point %s off the floor" % p)
	if not Lounge.LIFT_IN.x < -hx - 0.3 or absf(Lounge.LIFT_IN.z - Lounge.LIFT_Z) > 0.01 or not Lounge.LIFT_Z in Lounge.LIFTS_Z:
		problems.append("lift %s: not behind our lift's door in the left wall" % Lounge.LIFT_IN)
	for p: Vector3 in Lounge.CAB_SPOTS:
		if absf(p.x) > Lounge.CAB_SIZE.x * 0.5 - 0.2 or absf(p.z) > Lounge.CAB_SIZE.y * 0.5 - 0.2:
			problems.append("cabin spot %s outside the cabin" % p)
	# Big enough to tap on the phone (F 2026-11-11): the answers a thumb high, full width; the jars.
	if Lounge.CHOICE_BTN.y < 52.0 or Lounge.CHOICE_BTN.x < 260.0 or Lounge.JAR_BTN.y < 48.0:
		problems.append("buttons: answers %s, jars %s (52 pt high and 260 wide; jars 48 high)" % [Lounge.CHOICE_BTN, Lounge.JAR_BTN])
	digest.append("lounge %d tris, lobby and lift" % tris)


## The arrival played on a clock (F 2026-11-11): from the kerb into the lobby, the doorman's lines
## while the three walk up, our lift's doors open and shut, the ride with the floor number up to
## 38, the cabin's doors open, then the room, the waiter and the first choice at the table.
func _check_arrival(digest: PackedStringArray) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var l := Lounge.new()
	root.add_child(l)
	await process_frame
	l.set_process(false)
	l.enter(world, {})
	var seen: Array = [l.step_now]
	var door_max := 0.0
	var cab_max := 0.0
	var floor_max := 0
	var lobby_floor_min := 99
	var t := 0.0
	while t < 120.0 and l.step_now != Lounge.Step.CHOOSE:
		l._process(0.1)
		t += 0.1
		if seen.back() != l.step_now:
			seen.append(l.step_now)
		door_max = maxf(door_max, l._door)
		cab_max = maxf(cab_max, l._cab_door)
		if l.step_now == Lounge.Step.LIFT:
			floor_max = maxi(floor_max, l._floor_now)
		elif l.step_now == Lounge.Step.LOBBY and l._floor_now >= 0:
			lobby_floor_min = mini(lobby_floor_min, l._floor_now)
	var want := [Lounge.Step.LOBBY, Lounge.Step.LIFT, Lounge.Step.ORDER, Lounge.Step.CHOOSE]
	if seen != want:
		problems.append("arrival steps %s (want LOBBY, LIFT, ORDER, CHOOSE)" % [seen.map(func(s: int) -> String: return Lounge.Step.keys()[s])])
	if door_max < 1.0 or cab_max < 1.0:
		problems.append("arrival: the lift doors opened %.2f (lobby) and %.2f (cabin), not fully" % [door_max, cab_max])
	if floor_max != Lounge.FLOOR or lobby_floor_min != 0:
		problems.append("arrival: the floor number went down to %d in the lobby and up to %d in the lift (0 and %d)" % [lobby_floor_min, floor_max, Lounge.FLOOR])
	if l.area != "sala" or (l._choice_btns[0] as Button).custom_minimum_size.y < Lounge.CHOICE_BTN.y:
		problems.append("arrival: at the table in %s, answer %s high" % [l.area, (l._choice_btns[0] as Button).custom_minimum_size.y])
	digest.append("arrival %.0f s to the first choice" % t)
	l.queue_free()
	world.queue_free()


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


# --- the play ---------------------------------------------------------------------------------

func _ok(cond: bool, what: String) -> void:
	_plays += 1
	if not cond:
		problems.append("the play: " + what)


func _kerb(x: float, street: String) -> Dictionary:
	return {"at": Vector3(x, 1.5, 0.0), "side": Vector3(x, 1.5, 3.0), "street": street}


func _make() -> void:
	var world := Node3D.new()
	root.add_child(world)
	_hud = Fakes.Hud.new()
	_bubbles = Fakes.Bubbles.new()
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	var talk := Fakes.Dialogue.new()
	talk.bubbles = _bubbles
	var map := Fakes.FlatMap.new()
	for node: Node in [_hud, _bubbles, _wallet, _calls, talk, map]:
		world.add_child(node)
	_night = Shisha.new()
	_night.hud = _hud
	_night.dialogue = talk
	_night.wallet = _wallet
	_night.map = map
	_night.rng_seed = 7
	_night.vehicle = func() -> Array: return [_pos, _kmh, false]
	_night.clock = func() -> float: return _hour
	world.add_child(_night)
	_night.setup(world)
	_night.set_process(false)
	_director = Activities.new()
	_director.world_free = func() -> bool: return _world_free
	_director.add(_night)
	_director.add(_calls)


func _step(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_night._process(DT)


func _park() -> void:
	_pos = _night.target_position()
	_kmh = 0.0


func _far(kmh: float) -> void:
	var t: Vector3 = _night.target_position()
	_pos = Vector3(t.x - 200.0, t.y, t.z + 80.0)
	_kmh = kmh


func _at(stage: int) -> bool:
	return _night.phase == Activity.Phase.RUN and _night.stage == stage


func _toast(text: String) -> bool:
	for t in _hud.toasts:
		if text in t:
			return true
	return false


func _line(scene: String, i := 0) -> String:
	return String(_night.scenes[scene][i][1])


func _play(digest: PackedStringArray) -> void:
	_make()
	var c := _night
	var b: Node3D = c._beacon

	# Without the three places: no call, no meeting, the clock stands.
	_ok(not c.ring() and not c.meet() and c.idle() and _hud.card == "", "without the three places Ivan neither rings nor is met")
	var first: float = c.call_in
	_ok(first >= Shisha.FIRST_CALL.x and first <= Shisha.FIRST_CALL.y, "the first call is 4 to 7 minutes of free play away (%.0f s)" % first)
	_step(2.0)
	_ok(c.call_in == first, "without the places the call's clock stands")
	c.home = _kerb(300.0, "Sokołowska")
	c.court = _kerb(700.0, "Żelazna")
	c.door = _kerb(1100.0, "Emilii Plater")
	c.entry = Vector3(1100.0, 0.0, 30.0)

	# Ivan's own clock: seconds of free play in the lounge's hours.
	_step(2.0)
	_ok(c.call_in < first - 1.5 and c.call_in > first - 2.5, "the call's clock counts in the evening (%.2f of %.2f)" % [c.call_in, first])
	var left: float = c.call_in
	_hour = 10.0
	_step(2.0)
	_ok(c.call_in == left, "not by day")
	_hour = 1.0
	_step(2.0)
	_ok(c.call_in < left - 1.5, "past midnight, before the lounge shuts, it counts")
	_hour = 2.5
	left = c.call_in
	_step(2.0)
	_ok(c.call_in == left, "not after the lounge shuts")
	_hour = 21.0
	_world_free = false
	_step(2.0)
	_ok(c.call_in == left, "not while something else is on")
	_world_free = true
	c.auto = false
	_step(2.0)
	_ok(c.call_in == left, "not when the timer is off (a test run)")
	c.auto = true
	c.call_in = 0.5
	_step(1.0)
	_ok(c.phase == Activity.Phase.RING and "IVAN" in _hud.card and _hud.card_is(c), "it rings when the clock is out: Ivan's call, the night's own card (%s)" % _hud.card)
	_ok(not c.busy() and not _director.busy(), "a ringing phone is not busy")
	_ok(not c.ring() and not c.meet(), "no second call and no meeting while it rings")

	# Nobody answers; declined; the offer declined; the offer missed.
	_step(Shisha.RING_LIFE + 0.5)
	_ok(c.idle() and _hud.card == "" and _toast("Nieodebrane połączenie: Ivan"), "a call nobody answers goes, with the missed call's words")
	_ok(c.call_in >= Shisha.NEXT_CALL.x - 1.0 and c.call_in <= Shisha.NEXT_CALL.y, "and the next call 25 to 40 minutes of free play away (%.0f s)" % c.call_in)
	c.ring()
	_hud.press(1)
	_ok(c.idle() and _toast("Odrzucono"), "a call declined: idle, with its words")
	var next_call: float = c.call_in
	c.ring()
	_hud.press(0)
	_ok(c.call_in == next_call, "the next call is not drawn while this one is on")
	_ok(c.phase == Activity.Phase.OFFER and _hud.card == "📞 IVAN" and _hud.buttons == 2 and _hud.card_is(c) and "Szisza dziś?" in _hud.body,
			"answered: Ivan's offer, two buttons, the night's own card (%s)" % _hud.card)
	_ok(c.busy() and _director.busy() and _director.busy_tag() == "shisha" and _director.current() == c, "from the offer card on the night is busy (the kit's one meaning)")
	_ok(not _calls._held(), "but the rescue calls are not held yet")
	_hud.toasts.clear()
	_hud.press(1)
	_ok(c.idle() and _toast("następnym razem ty stawiasz") and not _toast("Odrzucono"), "the offer declined: idle, with Ivan's words")
	_ok(c.call_in != next_call, "and the next call drawn anew")
	c.ring()
	_hud.press(0)
	_hud.toasts.clear()
	_step(Shisha.RING_LIFE + 0.5)
	_ok(c.idle() and _hud.card == "" and _toast("Nieodebrane połączenie"), "an offer nobody answers goes too")

	# JADĘ!: Ivan at his kerb.
	_pos = Vector3.ZERO
	c.ring()
	_hud.press(0)
	_hud.toasts.clear()
	_hud.press(0)
	_ok(_at(Shisha.Stage.TO_IVAN), "JADĘ!: on the way to Ivan")
	_ok(_calls._held(), "the rescue calls are held")
	_ok(_toast("Jedź po Ivana"), "the toast sends the player")
	_ok(c.has_target() and c.target_position() == Vector3(300.0, 1.5, 0.0) and c.target_colour() == Shisha.PICK_COLOUR, "the target is Ivan's kerb, in the pickup's amber")
	_ok(_director.targeted() == c and c.stop_spot() == Vector3.INF, "the director points at the night; no stop assist at the kerb (as before the kit)")
	_ok(b.visible and b.position == Vector3(300.0, 1.5, 3.0) and b.pattern == Beacon.Pattern.DASHED and is_equal_approx(b._ring_radius, Shisha.PICK_R)
			and b._person.visible and b._colour == Shisha.PICK_COLOUR, "the dashed amber ring on the pavement beside the kerb, Ivan in it")
	_ok(c._mark == null or not c._mark.visible, "no door ring yet")
	_far(40.0)
	_step(1.0)
	_ok(_hud.status_title == "IVAN · 19. Dzielnica" and _hud.tint == Shisha.PICK_COLOUR and "Zatrzymaj się przy Ivanie" in _hud.status, "the status on the way names Ivan, in amber (%s)" % _hud.status_title)

	# Boarding: only when stopped in the ring.
	_park()
	_kmh = 12.0
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_IVAN), "rolling through the ring is not stopping")
	_kmh = 0.0
	_pos = c.target_position() + Vector3(Shisha.PICK_R + 1.0, 0.0, 0.0)
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_IVAN), "stopped a metre outside the ring is not at Ivan's")
	_park()
	_step(0.5)
	_pos += Vector3(40.0, 0.0, 0.0)
	_step(0.5)
	_park()
	_step(0.5)
	_ok(_at(Shisha.Stage.TO_IVAN), "half a second twice is not the stop: the hold starts again")
	_bubbles.said.clear()
	_step(1.1)
	_ok(_at(Shisha.Stage.TO_BOGDAN), "stopped in the ring: Ivan is in")
	_ok(c.target_position() == Vector3(700.0, 1.5, 0.0) and b.position == Vector3(700.0, 1.5, 3.0) and b._person.visible, "the target is the courts' kerb, Bogdan in its ring")
	_ok(_bubbles.said.size() == 1 and _bubbles.said[0] == _line("board_ivan"), "Ivan's first line as he gets in (%s)" % [_bubbles.said])
	_far(40.0)
	var lines: int = c.scenes["board_ivan"].size() + 3
	_step(Shisha.SCENE_GAP * lines + 1.0)
	_ok(_bubbles.said.size() == lines and _bubbles.said[1] == _line("board_ivan", 1), "then his other line and three of the leg's, one every %.1f s (%d said)" % [Shisha.SCENE_GAP, _bubbles.said.size()])
	var leg: Array = c.scenes["leg1"].map(func(r: Array) -> String: return String(r[1]))
	_ok(_bubbles.said.slice(2).all(func(l: String) -> bool: return l in leg), "the three are the leg's lines")
	_step(10.0)
	_ok(_bubbles.said.size() == lines, "and no more")
	_ok(_hud.status_title == "BOGDAN · korty na Żelaznej" and "Zatrzymaj się przy kortach" in _hud.status, "the status names the courts (%s)" % _hud.status)

	# The ✕ on the way there: Ivan takes the night bus.
	var money := _wallet.money
	_hud.toasts.clear()
	_bubbles.said.clear()
	_hud.abort_pressed.emit()
	_ok(c.idle() and _hud.status == "" and not b.visible and not c.has_target() and not _director.busy(), "the ✕ on the way there ends the night: idle, nothing up")
	_ok(_toast("nocny autobus") and _wallet.money == money and not _calls._held() and c.nights == 0, "with the night-bus words, nothing paid, the calls back, no night counted")
	_step(1.0)
	_ok(_bubbles.said.size() == 1 and _bubbles.said[0] == _line("abort"), "and his goodbye is still said (%s)" % [_bubbles.said])

	# Met in person, with the rescue calls already off: Ivan is in at once.
	_calls.paused = true
	_hud.toasts.clear()
	_ok(c.meet() and _at(Shisha.Stage.TO_BOGDAN), "met at his block: Ivan is in at once, on to the courts")
	_ok(not _toast("Jedź po Ivana") and _hud.shown > 0 and _hud.card == "", "no call, no offer and no 'go and get Ivan'")
	_ok(not c.meet() and not c.ring(), "no second meeting and no call during the night")
	_park()
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_LOUNGE), "stopped at the courts: Bogdan is in")

	# The entrance: the teal ring at the kerb, the gold one at the revolving door.
	_ok(c.target_position() == Vector3(1100.0, 1.5, 0.0) and c.target_colour() == Shisha.COLOUR, "the target is the lounge's kerb, in the lounge's teal")
	_ok(b.visible and b.position == Vector3(1100.0, 1.5, 3.0) and b.pattern == Beacon.Pattern.SOLID and not b._person.visible
			and b._colour == Shisha.COLOUR and is_equal_approx(b._ring_radius, Shisha.PICK_R), "a solid teal ring at the kerb, nobody in it")
	var m: Node3D = c._mark
	_ok(m != null and m.visible and m.position == c.entry and is_equal_approx(m._ring_radius, Shisha.ENTRY_R * 0.5) and m._colour == Shisha.GOLD,
			"the gold ring at the revolving door")
	_bubbles.said.clear()
	_far(40.0)
	_step(Shisha.SCENE_GAP)
	_ok(_hud.status_title == "SENATOREK · Emilii Plater 53" and _hud.tint == Shisha.COLOUR and "Stań w kręgu" in _hud.status, "the status names the lounge, in teal")
	_ok(_bubbles.said.size() == 1 and _bubbles.said[0] == _line("court"), "Ivan's lines for the first leg are dropped at the courts: the next one said is the courts' (%s)" % [_bubbles.said])

	# In: stopped within the kerb's reach.
	_entered.clear()
	c.enter_lounge = func(v: Dictionary) -> void: _entered.append(v)
	_pos = c.target_position() + Vector3(Shisha.DOOR_R + 1.0, 0.0, 0.0)
	_kmh = 0.0
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_LOUNGE), "stopped a metre past the lounge's reach: not there yet")
	_pos = c.target_position() + Vector3(Shisha.DOOR_R - 1.0, 0.0, 0.0)
	_step(1.6)
	_ok(c.inside() and _entered.size() == 1 and is_same(_entered[0], c.votes), "stopped within %d m of the kerb: the three go in, the lounge opens once with the night's votes" % Shisha.DOOR_R)
	_ok(not c.has_target() and not b.visible and not m.visible and _hud.status == "", "inside: no target, no ring, no status line")
	_ok(c.busy() and _director.current() == c and _calls._held(), "busy inside, the calls still held")
	_hud.abort_pressed.emit()
	_ok(c.inside(), "the ✕ does nothing inside (the lounge has its own way out)")
	_bubbles.said.clear()
	_step(8.0)
	_ok(_bubbles.said.is_empty() and c.inside(), "the car's lines stop at the door")

	# Out: Bogdan home first, then Ivan, the pay, the card.
	c.lounge_done("smoke", 7)
	_ok(_at(Shisha.Stage.DROP_BOGDAN) and c.outcome == "smoke" and c.score == 7, "out of the lounge: Bogdan home first")
	_ok(c.target_position() == Vector3(700.0, 1.5, 0.0) and b.visible and b.pattern == Beacon.Pattern.DASHED and b._colour == Shisha.PICK_COLOUR
			and not m.visible, "the amber dashed ring at the courts again, the gold one gone")
	c.lounge_done("leave", 0)
	_ok(c.outcome == "smoke" and c.score == 7, "a second word from the lounge changes nothing")
	_hud.abort_pressed.emit()
	_ok(_at(Shisha.Stage.DROP_BOGDAN), "the ✕ does nothing on the way home")
	_far(40.0)
	_step(1.0)
	_ok(_hud.status_title == "BOGDAN · do domu" and "Podrzuć Bogdana pod korty" in _hud.status and _hud.tint == Shisha.PICK_COLOUR, "the status takes Bogdan home, in amber (%s)" % _hud.status)
	_ok(_bubbles.said.size() == 1 and _bubbles.said[0] == _line("after"), "with the evening's first line (%s)" % [_bubbles.said])
	_park()
	_bubbles.said.clear()
	_step(1.6)
	_ok(_at(Shisha.Stage.DROP_IVAN) and c.target_position() == Vector3(300.0, 1.5, 0.0), "stopped at the courts: Bogdan is out, Ivan's kerb next")
	_far(40.0)
	_step(Shisha.SCENE_GAP * 5.0)
	_ok(_line("drop_bogdan") in _bubbles.said and _hud.status_title == "IVAN · do domu" and "Podrzuć Ivana na 19. Dzielnicę" in _hud.status, "Bogdan's goodbye is said, the status takes Ivan home (%s)" % _hud.status)
	_park()
	money = _wallet.money
	_step(1.6)
	_ok(_at(Shisha.Stage.RESULT), "stopped at Ivan's: the night's result")
	var want := Shisha.pay_for("smoke", 7)
	_ok(_wallet.money - money == int(want[0]) and _wallet.respect == int(want[1]) and _wallet.kinds == ["shisha"], "paid for the ride, the respect by the mix (%d zł, %d)" % [_wallet.money - money, _wallet.respect])
	_ok(_hud.card == "DYM U SENATORKA" and _hud.card_is(c) and _hud.stacked and _hud.buttons == 1
			and ("Za kurs: %d zł" % int(want[0])) in _hud.body and "„Forhend”" in _hud.body, "the result card is the night's own, stacked, with the pay and the pipe's name")
	_ok(not c.has_target() and not b.visible and _hud.status == "", "no target, no ring, no status line under it")
	_ok(c.busy() and _calls._held(), "still busy until the card closes")
	_ok(c.nights == 1 and c.last_pay == {"zl": want[0], "respect": want[1], "outcome": "smoke", "score": 7}, "one night done, its pay kept (%s)" % [c.last_pay])
	_hud.abort_pressed.emit()
	_ok(_at(Shisha.Stage.RESULT) and _hud.card != "", "the ✕ does nothing on the result card")
	_hud.press(0)
	_ok(c.idle() and _hud.card == "" and not _director.busy(), "OK closes it: idle")
	_ok(_calls.paused, "the calls were off before the night and are off after it")
	_ok(_calls._held(), "the calls are still held after the night")
	_calls.paused = false
	_ok(c.call_in >= Shisha.NEXT_CALL.x and c.call_in <= Shisha.NEXT_CALL.y and b.pattern == Beacon.Pattern.DASHED and b._colour == Shisha.PICK_COLOUR,
			"the next call drawn, the ring a friend's again")
	_step(Shisha.SCENE_GAP + 1.0)
	_ok(_line("drop_ivan") in _bubbles.said, "Ivan's thanks are said after the card")

	# No lounge to open (a run without one): the default votes, straight out. In by the gold ring.
	c.enter_lounge = Callable()
	c.meet()
	_park()
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_LOUNGE), "the second night: at the courts")
	_pos = c.entry + Vector3(Shisha.ENTRY_R + 1.0, 0.0, 0.0)
	_kmh = 0.0
	_step(1.6)
	_ok(_at(Shisha.Stage.TO_LOUNGE), "stopped a metre outside the gold ring, far from the kerb: not in")
	_pos = c.entry + Vector3(Shisha.ENTRY_R - 1.0, 0.0, 0.0)
	_step(1.6)
	_ok(_at(Shisha.Stage.DROP_BOGDAN) and c.outcome == "smoke" and c.score == 5 and c.votes.size() >= 3,
			"stopped in the gold ring at the door: in; with no lounge to open, the default votes and out (%s)" % [c.votes.keys()])
	_park()
	_step(1.6)
	_park()
	_step(1.6)
	_ok(_at(Shisha.Stage.RESULT) and ("„%s”" % String(c.votes["name"][0])) in _hud.body, "home again: the card names the pipe they voted for")
	_step(Shisha.RESULT_LIFE - 1.0)
	_ok(_hud.card == "DYM U SENATORKA", "the card stays for its life")
	_step(1.5)
	_ok(c.idle() and _hud.card == "" and c.nights == 2 and not _calls._held(), "then closes by itself: idle, two nights, the calls back on")

	# A night they left early: half the pay, no respect, Ivan's sigh.
	c.enter_lounge = func(v: Dictionary) -> void: _entered.append(v)
	c.meet()
	_ok(c.votes.is_empty(), "a new night starts with no votes (the last night's are not kept)")
	_park()
	_step(1.6)
	_park()
	_step(1.6)
	_ok(c.inside() and is_same(_entered.back(), c.votes) and c.votes.is_empty(), "the third night: inside, the lounge given this night's empty votes")
	_step(Shisha.SCENE_GAP)
	c.lounge_done("leave", 4)
	_bubbles.said.clear()
	_step(1.0)
	_ok(_bubbles.said.size() == 1 and _bubbles.said[0] == _line("leave"), "left early: Ivan's line for it")
	_park()
	_step(1.6)
	_park()
	money = _wallet.money
	var respect := _wallet.respect
	_step(1.6)
	_ok(_at(Shisha.Stage.RESULT) and _wallet.money - money == Shisha.PAY / 2 and _wallet.respect == respect, "half the pay and no respect for a night they left")
	_ok("Ogórek został w słoiku" in _hud.body and not "szacunku" in _hud.body, "the card has Ivan's sigh, no respect on it")
	_hud.press(0)

	# The autopilot: it answers, takes the offer and lets the result go; the car stands on each target.
	c.enter_lounge = Callable()
	c.autopilot = true
	var nights: int = c.nights
	_pos = Vector3.ZERO
	c.ring()
	for i in 60 * 120:
		if c.has_target():
			_park()
		c._process(DT)
		if c.nights > nights and c.idle():
			break
	_ok(c.nights == nights + 1 and c.idle() and _hud.card == "", "the autopilot plays a night by itself")
	c.autopilot = false
	digest.append("the play: %d nights, %d checks" % [c.nights, _plays])

