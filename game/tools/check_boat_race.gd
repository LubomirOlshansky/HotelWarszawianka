extends SceneTree
## The boat race "Wiślana Szprotka" (boat_race.gd, boat.gd, docs/design/boat-race.md). Checks that:
## - game/data/boat_race.json (tools/boat_course.py) loads: the line runs MIN_LEN m or more down the
##   river, every ring stands in open water (its centre SHORE_MIN m from a bank, both ends of its
##   opening in the water) in order down the line, the finish is last;
## - the boat (boat.gd) gets up to speed on open water within PULL_S s, turns, and a bank pushes it
##   back instead of letting it through;
## - a race with all four boats driven by the rivals' driver (the player's boat too, as on
##   autopilot) ends with every boat finished or out inside RACE_MAX s, the player's careful boat
##   with no miss inside the expected time, the times spread (they are not one boat four times);
## - three misses put the player out (ODPADASZ!), JESZCZE RAZ starts the grid again, WYJDŹ ends it;
## - the free ride (F 2026-11-07): three boats moored in open water, clear of each other; each one
##   picked on the marina card goes out, gets away from the pontoon at full throttle without the
##   rivals or the rings, ✕ ends the ride and it is back at its mooring; and they feel different:
##   the offshore fastest, the jet ski quickest off the line and steering only on the gas, the turn
##   rates jet ski > electric > offshore;
## - the race's dialogue lines exist in Polish and English for every rival's situations.
##   godot --headless --path game --script res://tools/check_boat_race.gd

const BoatRace := preload("res://scripts/boat_race.gd")
const Boat := preload("res://scripts/boat.gd")

const MIN_LEN := 2800.0
const SHORE_MIN := 14.0
const PULL_S := 6.0
const RACE_MAX := 320.0
const PLAYER_TIME := Vector2(130.0, 230.0)
const SITUATIONS := ["start", "pass", "passed", "miss", "out", "bump", "finish"]
const STEP := 1.0 / 60.0


## The map's water from water.bin's shore channel; flat ground.
class WaterMap extends Node3D:
	var _r := PackedByteArray()
	var _w := 0
	var _h := 0
	var _x0 := 0.0
	var _z0 := 0.0
	var _px := 2.0

	func load_water() -> bool:
		if not FileAccess.file_exists("res://map/water.bin"):
			return false
		var b := FileAccess.get_file_as_bytes("res://map/water.bin")
		_w = b.decode_u32(0)
		_h = b.decode_u32(4)
		_x0 = b.decode_float(8)
		_z0 = b.decode_float(12)
		_px = b.decode_float(16)
		var img := Image.create_from_data(_w, _h, false, Image.FORMAT_RGBA8, b.slice(20, 20 + _w * _h * 4))
		img.convert(Image.FORMAT_R8)
		_r = img.get_data()
		return true

	func shore_distance(x: float, z: float) -> float:
		var fx := (x - _x0) / _px - 0.5
		var fz := (z - _z0) / _px - 0.5
		var i := floori(fx)
		var j := floori(fz)
		if i < 0 or j < 0 or i >= _w - 1 or j >= _h - 1:
			return 0.0
		var k := j * _w + i
		var u := fx - i
		var near := lerpf(_r[k], _r[k + 1], u)
		var far := lerpf(_r[k + _w], _r[k + _w + 1], u)
		return lerpf(near, far, fz - j) * 0.25

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0


## The HUD's calls the race makes, recorded.
class FakeHud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	signal context_pressed(owner: String)
	var card := ""
	var banner := ""
	var pill := ""
	func show_card(title: String, _b: String, _btn: PackedStringArray, _a: Color, _bottom := false, _te := "", _be := "", _s := false) -> void:
		card = title
	func show_side_card(title: String, _b: String, _btn: PackedStringArray, _a: Color, _te := "", _be := "", _s := false) -> void:
		card = title
	func hide_card() -> void:
		card = ""
	func toast(_a: String, _b := "") -> void:
		pass
	func ambient_toast(_a: String, _b := "") -> void:
		pass
	func show_status(_t: String, _c: String, _d: String, _h: String, _p: float, _a: Color, _badge := "", _i := {}, _he := "") -> void:
		pass
	func hide_status() -> void:
		pass
	func show_banner(t: String, _c: Color) -> void:
		banner = t
	func hide_banner() -> void:
		banner = ""
	func set_minimap_dots(_p: PackedVector2Array, _c: PackedColorArray) -> void:
		pass
	func show_pill(pl: String, _en := "", _o := "") -> void:
		pill = pl
	func hide_pill() -> void:
		pill = ""
	func pill_shown(_o: String) -> bool:
		return pill != ""
	func pill_free_for(_o: String) -> bool:
		return true
	func ticker_out() -> void:
		pass


var _fails: Array[String] = []


func _initialize() -> void:
	var map := WaterMap.new()
	root.add_child(map)
	if not map.load_water():
		print("check_boat_race: SKIP (no game/map/water.bin)")
		quit(0)
		return
	_course(map)
	_boat(map)
	var hud := FakeHud.new()
	root.add_child(hud)
	var race := _race(map, hud)
	_fail_path(race, hud)
	_free(race, map)
	_lines()
	if _fails.is_empty():
		print("check_boat_race: OK")
		quit(0)
	else:
		for f in _fails:
			print("check_boat_race: FAIL ", f)
		quit(1)


func _fail(s: String) -> void:
	_fails.append(s)


func _course(map: WaterMap) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BoatRace.COURSE))
	var line: Array = data["line"]
	var length := 0.0
	for i in range(1, line.size()):
		length += Vector2(line[i][0], line[i][1]).distance_to(Vector2(line[i - 1][0], line[i - 1][1]))
	if length < MIN_LEN:
		_fail("the course is %.0f m, under %.0f" % [length, MIN_LEN])
	var rings: Array = data["rings"]
	var last := -1
	for k in rings.size():
		var g: Dictionary = rings[k]
		var c := Vector2(g["x"], g["z"])
		if map.shore_distance(c.x, c.y) < SHORE_MIN * (0.6 if bool(g["finish"]) else 1.0):
			_fail("ring %d at %s is %.1f m from the bank" % [k, c, map.shore_distance(c.x, c.y)])
		var yaw := float(g["yaw"])
		var across := Vector2(cos(yaw), -sin(yaw))
		for s: float in [-1.0, 1.0]:
			var e := c + across * s * float(g["w"]) * 0.5
			if map.shore_distance(e.x, e.y) < 2.0:
				_fail("ring %d's end at %s is on the bank" % [k, e])
		if int(g["i"]) <= last:
			_fail("ring %d is not further down the line than the one before" % k)
		last = int(g["i"])
		if bool(g["finish"]) != (k == rings.size() - 1):
			_fail("ring %d: the finish must be the last ring" % k)
	print("check_boat_race: course %.0f m, %d rings" % [length, rings.size()])


func _boat(map: WaterMap) -> void:
	var b := Boat.new()
	root.add_child(b)
	b.setup(Boat.Kind.RUNABOUT, Boat.runabout_mesh(Color.ORANGE, Color.TAN, Color.WHITE, Color.BLACK), null)
	b.shore = map.shore_distance
	# Open water by the course's start, heading downstream.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BoatRace.COURSE))
	var p := Vector2(data["line"][30][0], data["line"][30][1])
	var f := Vector2(data["flow"][0], data["flow"][1])
	b.place(p, atan2(f.x, f.y))
	b.throttle = 1.0
	var t := 0.0
	while t < PULL_S and b.forward_speed() < 0.8 * b.top():
		b.step(STEP)
		t += STEP
	if b.forward_speed() < 0.8 * b.top():
		_fail("the runabout reaches only %.1f m/s in %.0f s" % [b.forward_speed(), PULL_S])
	var yaw0: float = b.yaw
	b.steer = 1.0
	for i in 60:
		b.step(STEP)
	if absf(wrapf(b.yaw - yaw0, -PI, PI)) < 0.6:
		_fail("the runabout turns only %.2f rad in a second at speed" % absf(b.yaw - yaw0))
	# Straight at the bank: it must stay in the water.
	b.place(p, atan2(f.x, f.y) + PI * 0.5)
	b.throttle = 1.0
	b.steer = 0.0
	var worst := 99.0
	for i in 60 * 20:
		b.step(STEP)
		worst = minf(worst, map.shore_distance(b.pos.x, b.pos.y))
	if worst < 1.0:
		_fail("the runabout got %.1f m from the shore line (through the bank)" % worst)
	# Pinned nose-first against that bank at full throttle: it must still turn off it (the
	# rudder's contact bite), not sit there until the player reverses.
	var yaw1: float = b.yaw
	b.steer = 1.0
	for i in 60 * 3:
		b.step(STEP)
	if absf(wrapf(b.yaw - yaw1, -PI, PI)) < 0.8:
		_fail("the runabout pinned on a bank turns only %.2f rad in 3 s" % absf(wrapf(b.yaw - yaw1, -PI, PI)))
	b.queue_free()


func _make_race(map: WaterMap, hud: FakeHud) -> Node3D:
	var race := BoatRace.new()
	race.hud = hud
	race.map = map
	race.autopilot = true
	race.seen = func(_p: Vector3) -> bool: return false
	root.add_child(race)
	race.setup(map)
	return race


func _race(map: WaterMap, hud: FakeHud) -> Node3D:
	var race := _make_race(map, hud)
	race._start_grid()
	var t := 0.0
	var stuck_t := 0.0
	var last_li := 0.0
	while t < RACE_MAX and race.state in [BoatRace.State.COUNTDOWN, BoatRace.State.RACE]:
		race._process(STEP)
		t += STEP
		var li: float = race.racers[0]["li"]
		stuck_t = 0.0 if li > last_li + 0.05 else stuck_t + STEP
		last_li = maxf(last_li, li)
		if stuck_t > 8.0:
			_fail("the player's boat is stuck at %s (line %.1f)" % [race.boats[0].pos, li])
			break
	# Let the rest come in.
	var extra := 0.0
	while extra < 120.0 and race.state == BoatRace.State.DONE:
		var all := true
		for r: Dictionary in race.racers:
			all = all and (bool(r["finished"]) or bool(r["out"]))
		if all:
			break
		race._t = 0.0  # the autopilot's WYJDŹ waits
		race._process(STEP)
		extra += STEP
		if OS.get_environment("BOAT_DEBUG") != "" and int(extra * 60) % 120 == 0:
			var zb: Node3D = race.boats[2]
			print("dbg %.0f pos %s yaw %.2f v %.1f next %d steer %.2f thr %.1f" % [extra, zb.pos, zb.yaw, zb.forward_speed(), race.racers[2]["next"], zb.steer, zb.throttle])
	var res: Dictionary = race.last_result()
	if res.is_empty():
		_fail("the race did not finish in %.0f s (state %d, line %.1f)" % [RACE_MAX, race.state, race.racers[0]["li"]])
		return race
	var times: Array[String] = []
	var spread := []
	for k in race.racers.size():
		var r: Dictionary = race.racers[k]
		times.append("%s %s (%d misses)" % [r["name"], ("%.1f s" % float(r["time"])) if bool(r["finished"]) else ("OUT" if bool(r["out"]) else "at line %.0f" % float(r["li"])), int(r["misses"])])
		if bool(r["finished"]):
			spread.append(float(r["time"]))
		elif not bool(r["out"]):
			_fail("%s neither finished nor dropped out" % r["name"])
	print("check_boat_race: race %s; player %d." % [", ".join(times), int(res["place"])])
	if int(res["misses"]) > 0:
		_fail("the careful driver missed %d rings" % int(res["misses"]))
	if float(res["time"]) < PLAYER_TIME.x or float(res["time"]) > PLAYER_TIME.y:
		_fail("the player's time %.1f s is outside %s" % [float(res["time"]), PLAYER_TIME])
	if spread.size() >= 2 and float(spread.max()) - float(spread.min()) < 1.0:
		_fail("the boats finish within a second of each other: %s" % [spread])
	return race


func _fail_path(race: Node3D, hud: FakeHud) -> void:
	race.autopilot = false
	race._start_grid()
	# The player's boat goes flat out straight down the middle, never aiming for a ring.
	var t := 0.0
	while t < 120.0 and race.state in [BoatRace.State.COUNTDOWN, BoatRace.State.RACE]:
		var b: Node3D = race.boats[0]
		var li := clampi(int(race.racers[0]["li"]) + 6, 0, race.line.size() - 1)
		var to: Vector2 = race.line[li] - b.pos
		b.target_dir = Vector3(to.x, 0.0, to.y).normalized()
		race._process(STEP)
		t += STEP
	if race.state != BoatRace.State.OUT:
		_fail("three misses did not put the player out (state %d, misses %d)" % [race.state, int(race.racers[0]["misses"])])
		return
	if not hud.card.begins_with("ODPADASZ"):
		_fail("no ODPADASZ card (card: %s)" % hud.card)
	race._on_card(0)
	if race.state != BoatRace.State.COUNTDOWN:
		_fail("JESZCZE RAZ did not start the grid again")
	race._quit()
	if race.state != BoatRace.State.IDLE or race.boating():
		_fail("WYJDŹ did not end the race")


func _free(race: Node3D, map: WaterMap) -> void:
	var n: int = BoatRace.FLEET.size()
	if n != 3 or race.fleet.size() != n:
		_fail("the marina has %d boats, not 3" % race.fleet.size())
		return
	for i in n:
		var m: Vector2 = BoatRace.fleet_spot(i)
		if map.shore_distance(m.x, m.y) < float(race.fleet[i].spec["r"]) + 0.8:
			_fail("%s's mooring %s is %.1f m from the bank" % [BoatRace.FLEET[i]["name"], m, map.shore_distance(m.x, m.y)])
		for k in range(i + 1, n):
			if m.distance_to(BoatRace.fleet_spot(k)) < float(race.fleet[i].spec["r"]) + float(race.fleet[k].spec["r"]):
				_fail("the moorings of %s and %s overlap" % [BoatRace.FLEET[i]["name"], BoatRace.FLEET[k]["name"]])
	var stats := []
	for i in n:
		race._marina_card()
		if race.state != BoatRace.State.MENU:
			_fail("the pill did not open the marina card")
		race._on_card(i)
		var name: String = BoatRace.FLEET[i]["name"]
		if race.state != BoatRace.State.FREE or not race.boating() or race.player != race.fleet[i]:
			_fail("picking %s did not start its free ride (state %d)" % [name, race.state])
			return
		var b: Node3D = race.fleet[i]
		var m: Vector2 = BoatRace.fleet_spot(i)
		# Full throttle, bow to the river: out past the pontoon and up on the plane, then on down
		# the middle of the river (the course's line) so the turns below are in open water.
		b.throttle = 1.0
		var t := 0.0
		var best := 0.0
		var t10 := -1.0
		while t < 14.0:
			if t > 3.0:
				var li := clampi(race.line.size() / 6, 0, race.line.size() - 1)
				var to: Vector2 = race.line[li] - b.pos
				b.target_dir = Vector3(to.x, 0.0, to.y).normalized()
			race._process(STEP)
			t += STEP
			best = maxf(best, b.forward_speed())
			if t10 < 0.0 and b.forward_speed() >= 10.0:
				t10 = t
		var gone: float = b.pos.distance_to(m)
		if gone < 60.0:
			_fail("%s got only %.0f m from its mooring in 14 s (stuck by the pontoon?)" % [name, gone])
		# The turn at speed with the gas on, then coasting with the wheel over.
		b.target_dir = Vector3.ZERO
		b.throttle = 1.0
		var y0: float = b.yaw
		b.steer = 1.0
		for f in 60:
			race._process(STEP)
		var turn_gas := absf(wrapf(b.yaw - y0, -PI, PI))
		b.throttle = 0.0
		for f in 30:
			race._process(STEP)
		var y1: float = b.yaw
		for f in 30:
			race._process(STEP)
		var turn_coast := absf(wrapf(b.yaw - y1, -PI, PI)) * 2.0
		stats.append({"best": best, "t10": t10, "gas": turn_gas, "coast": turn_coast})
		print("check_boat_race: free ride %s: %.0f m out, top %.1f m/s, 10 m/s in %.1f s, turn %.2f rad/s on gas, %.2f coasting" % [name, gone, best, t10, turn_gas, turn_coast])
		for k in race.boats.size():
			if race.boats[k].visible:
				_fail("a race boat is out during the free ride")
		if i == FLEET_PIN:
			_pin(race, b, m)
		race.hud.abort_pressed.emit()
		if race.state != BoatRace.State.IDLE or race.boating() or race.player == race.fleet[i]:
			_fail("✕ did not end the free ride in %s" % name)
		if race.fleet[i].pos.distance_to(m) > 0.5 or not race.fleet[i].visible:
			_fail("%s is not back at its mooring" % name)
	# Their own physics: the offshore is the fastest, the jet ski the quickest off the line and the
	# only one that hardly turns off the gas, the electric quicker to 10 m/s than the heavy offshore.
	var sk: Dictionary = stats[0]
	var el: Dictionary = stats[1]
	var of: Dictionary = stats[2]
	if not (float(of["best"]) > float(sk["best"]) + 3.0 and float(of["best"]) > float(el["best"]) + 3.0):
		_fail("the offshore is not clearly the fastest (%.1f vs %.1f, %.1f)" % [of["best"], sk["best"], el["best"]])
	if not (float(sk["t10"]) < float(el["t10"]) and float(el["t10"]) < float(of["t10"])):
		_fail("off the line: jet ski %.1f s, electric %.1f s, offshore %.1f s to 10 m/s (want that order)" % [sk["t10"], el["t10"], of["t10"]])
	if not (float(sk["coast"]) < 0.5 * float(sk["gas"])):
		_fail("the jet ski turns %.2f rad/s off the gas (jet steering wants under half of %.2f)" % [sk["coast"], sk["gas"]])
	if not (float(of["gas"]) < float(el["gas"]) and float(el["gas"]) < float(sk["gas"])):
		_fail("turn rates on the gas: jet ski %.2f, electric %.2f, offshore %.2f (want that order)" % [sk["gas"], el["gas"], of["gas"]])


## The long offshore nosed into the bank at full throttle, wheel straight: it must not sit pinned
## there (the pin push-off in boat.gd; Autopilot found it stuck 12 s on 2026-11-07).
const FLEET_PIN := 2


func _pin(race: Node, b: Node3D, m: Vector2) -> void:
	var to: Vector2 = BoatRace.CAR_SPOT - m
	b.place(m, atan2(to.x, to.y))
	b.target_dir = Vector3.ZERO
	b.steer = 0.0
	b.throttle = 1.0
	var still := 0.0
	var worst := 0.0
	for f in int(8.0 / STEP):
		race._process(STEP)
		still = still + STEP if b.vel.length() < 0.5 else 0.0
		worst = maxf(worst, still)
	b.throttle = 0.0
	print("check_boat_race: pinned on the bank at most %.1f s" % worst)
	if worst > 2.5:
		_fail("%s sat pinned on the bank for %.1f s at full throttle" % [BoatRace.FLEET[FLEET_PIN]["name"], worst])


func _lines() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var group: Array = data.get("boat_race", [])
	for rv: Dictionary in BoatRace.RIVALS:
		for s: String in SITUATIONS:
			var tag := "%s_%s" % [rv["tag"], s]
			var n := 0
			for l: Array in group:
				if l.size() > 2 and l[2] is Dictionary and str(l[2].get("only", "")) == tag:
					n += 1
					if str(l[0]).strip_edges() == "" or str(l[1]).strip_edges() == "":
						_fail("a %s line lacks Polish or English" % tag)
			if n == 0:
				_fail("no boat_race line for %s" % tag)
