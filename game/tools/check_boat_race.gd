extends SceneTree
## The boat race "Wiślana Szprotka" (boat_race.gd, boat.gd, docs/design/boat-race.md). Checks that:
## - game/data/boat_race.json (tools/boat_course.py) loads: the line runs MIN_LEN m or more down the
##   river, every ring stands in open water (its centre SHORE_MIN m from a bank, both ends of its
##   opening in the water) in order down the line, the finish is last;
## - the boat (boat.gd) gets up to speed on open water within PULL_S s, turns, and a bank pushes it
##   back instead of letting it through;
## - a race with all four boats driven by the rivals' driver (the player's boat too, as on
##   autopilot) ends with every boat finished or out inside RACE_MAX s, the player's careful boat
##   with at most CAREFUL_MISSES misses inside the expected time, the times spread (they are not one boat four times);
## - the course has 2+ jump ramps in open water and the boats take them (2026-11-08);
## - three misses put the player out (ODPADASZ!), JESZCZE RAZ starts the grid again, WYJDŹ ends it;
## - the free ride (F 2026-11-07): three boats moored in open water, clear of each other; each one
##   picked on the marina card goes out, gets away from the pontoon at full throttle without the
##   rivals or the rings, ✕ ends the ride and it is back at its mooring; and they feel different:
##   the offshore fastest, the jet ski quickest off the line and steering only on the gas, the turn
##   rates jet ski > electric > offshore;
## - the race's dialogue lines exist in Polish and English for every rival's situations;
## - the play (the activity kit, TD-1): a fresh race on a rig of its own, played through the kit's
##   frame: Szymek's clock and the call, the way to the pontoon, the grid, the race, out and the
##   finish, the pill and the marina's card, the free rides, the meeting, the straight ways in and
##   the script's dice (a mirror RNG), each fact one `_ok`; the dice again frame by frame through a
##   whole race on the race's own driver (`_p_race_dice`), and what the deliberate breaks of the
##   move found unwatched (`_p_breaks`: the cards' words in both languages, the shirt, the stage's
##   clock, the car's spot kept, the wake, a rival pushed off something solid).
##   godot --headless --path game --script res://tools/check_boat_race.gd

const BoatRace := preload("res://scripts/boat_race.gd")
const Boat := preload("res://scripts/boat.gd")
const BoatStreaks := preload("res://scripts/boat_streaks.gd")
const Fakes := preload("res://tools/fakes.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")

const MIN_LEN := 2800.0
const SHORE_MIN := 14.0
const PULL_S := 6.0
const RACE_MAX := 320.0
const PLAYER_TIME := Vector2(60.0, 150.0)  # 2026-11-10: boats ~1.9x faster (was 130-230)
const CAREFUL_MISSES := 1
const SITUATIONS := ["start", "pass", "passed", "miss", "out", "bump", "finish", "duck"]
const STEP := 1.0 / 60.0


## The map's water from water.bin's shore channel; flat ground.
class WaterMap extends Fakes.FlatMap:
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


## The play's own map: the water and the bank at different heights (the race's target stands at
## the water's, the pontoon's ring on the bank's).
class PlayMap extends WaterMap:
	func terrain_height(_x: float, _z: float) -> float:
		return -2.0

	func ground_height(_x: float, _z: float) -> float:
		return 1.5


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
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var race := _race(map, hud)
	_fail_path(race, hud)
	_free(race, map)
	_lines()
	await _play(map)
	if _fails.is_empty():
		print("check_boat_race: OK (the play: %d checks)" % _plays)
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
	# A bank scrapes, it does not stop (F 2026-11-26): half a second along a bank keeps most of the speed.
	b.place(p, 0.0)
	b.vel = Vector2(0.0, 30.0)
	b._contact = 0.0
	var v0 := b.vel.length()
	for i in 30:
		b._dt = STEP
		b._hit(Vector2(1.0, 0.0), true)
	if b.vel.length() < v0 * 0.6:
		_fail("half a second along a bank leaves only %.0f%% of the speed" % (100.0 * b.vel.length() / v0))
	b.queue_free()


func _make_race(map: WaterMap, hud: Fakes.Hud) -> Node:
	var race := BoatRace.new()
	race.hud = hud
	race.map = map
	race.autopilot = true
	race.log_on = OS.get_environment("BOAT_DEBUG") != ""
	# A fixed seed: the rivals' aims, mistakes and stunts are the same every run (the game randomises).
	# BOAT_SEED=n tries another; 12 seeds passed on 2026-11-12 (rings 24 m wide).
	race.rng_seed = int(OS.get_environment("BOAT_SEED")) if OS.get_environment("BOAT_SEED") != "" else 1
	race.seen = func(_p: Vector3) -> bool: return false
	root.add_child(race)
	race.setup(map)
	return race


func _race(map: WaterMap, hud: Fakes.Hud) -> Node:
	var race := _make_race(map, hud)
	race.board()
	var t := 0.0
	var stuck_t := 0.0
	var last_li := 0.0
	while t < RACE_MAX and race.stage in [BoatRace.Stage.COUNTDOWN, BoatRace.Stage.RACE]:
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
	while extra < 120.0 and race.stage == BoatRace.Stage.DONE:
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
		_fail("the race did not finish in %.0f s (stage %d, line %.1f)" % [RACE_MAX, race.stage, race.racers[0]["li"]])
		return race
	# The arcade pass: the autopilot rocket-starts and burns a full tank on a straight.
	print("check_boat_race: arcade: %d nitro burns, %d of %d sprats, %d bank hugs" % [race.nitro_burns, race.sprats, race.crates.size(), race.hugs])
	if race.nitro_burns < 1:
		_fail("the autopilot never burnt the nitro")
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
	# The pack runs close since the slipstream and the bank slalom (2026-11-08): keeping clear of
	# a boat alongside costs the careful driver a ring now and then, never two.
	if int(res["misses"]) > CAREFUL_MISSES:
		_fail("the careful driver missed %d rings" % int(res["misses"]))
	if race.ramps.size() < 2:
		_fail("only %d jump ramps on the course" % race.ramps.size())
	for rp: Dictionary in race.ramps:
		if map.shore_distance(float(rp["x"]), float(rp["z"])) < SHORE_MIN:
			_fail("the ramp at %.0f, %.0f is by the bank" % [float(rp["x"]), float(rp["z"])])
	if race.jumps == 0:
		_fail("nobody jumped a ramp")
	if float(res["time"]) < PLAYER_TIME.x or float(res["time"]) > PLAYER_TIME.y:
		_fail("the player's time %.1f s is outside %s" % [float(res["time"]), PLAYER_TIME])
	if spread.size() >= 2 and float(spread.max()) - float(spread.min()) < 1.0:
		_fail("the boats finish within a second of each other: %s" % [spread])
	return race


func _fail_path(race: Node, hud: Fakes.Hud) -> void:
	race.autopilot = false
	hud.press(0)
	# The player's boat goes flat out straight down the middle, never aiming for a ring.
	var t := 0.0
	while t < 120.0 and race.stage in [BoatRace.Stage.COUNTDOWN, BoatRace.Stage.RACE]:
		var b: Node3D = race.boats[0]
		var li := clampi(int(race.racers[0]["li"]) + 6, 0, race.line.size() - 1)
		var to: Vector2 = race.line[li] - b.pos
		b.target_dir = Vector3(to.x, 0.0, to.y).normalized()
		race._process(STEP)
		t += STEP
	if race.stage != BoatRace.Stage.OUT:
		_fail("three misses did not put the player out (stage %d, misses %d)" % [race.stage, int(race.racers[0]["misses"])])
		return
	if not hud.card.begins_with("ODPADASZ"):
		_fail("no ODPADASZ card (card: %s)" % hud.card)
	hud.press(0)
	if race.stage != BoatRace.Stage.COUNTDOWN:
		_fail("JESZCZE RAZ did not start the grid again")
	hud.abort_pressed.emit()
	if race.phase != Activity.Phase.IDLE or race.boating():
		_fail("WYJDŹ did not end the race")


func _free(race: Node, map: WaterMap) -> void:
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
		if race.stage != BoatRace.Stage.MENU:
			_fail("the pill did not open the marina card")
		race.hud.press(i)
		var name: String = BoatRace.FLEET[i]["name"]
		if race.stage != BoatRace.Stage.FREE or not race.boating() or race.player != race.fleet[i]:
			_fail("picking %s did not start its free ride (stage %d)" % [name, race.stage])
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
		if race.phase != Activity.Phase.IDLE or race.boating() or race.player == race.fleet[i]:
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


# --- the play -----------------------------------------------------------------------------------
# A fresh race on a rig of its own (the kit's director, a second activity to ask it about, the
# stand-in HUD, wallet and dialogue from fakes.gd), played one frame at a time through
# `_process`, the player pressing what a player presses: a card's button (`hud.press`), the ✕
# (`hud.abort_pressed`), the pill (`hud.context_pressed`).

var _plays := 0
var _pm: PlayMap
var _pw: Node3D
var _r: Node
var _h: Fakes.Hud
var _car: Node3D
var _wallet: Fakes.Wallet
var _dlg: Fakes.Dialogue
var _dir: Activities
var _other: Node
var _kmh := 0.0
var _flying := false
var _hour := 12.0
var _world_free := true
var _nb := 0
var _nl := 0


func _ok(cond: bool, what: String) -> void:
	_plays += 1
	if not cond:
		_fail("the play: " + what)


## A fresh race, its hud, wallet, dialogue, car and director; the car far away, idle, noon.
func _rig(seed_value := 5) -> void:
	if _pw != null:
		_pw.free()
	_pw = Node3D.new()
	root.add_child(_pw)
	_h = Fakes.Hud.new()
	_wallet = Fakes.Wallet.new()
	_dlg = Fakes.Dialogue.new()
	_car = Node3D.new()
	for n: Node in [_h, _wallet, _dlg, _car]:
		_pw.add_child(n)
	_kmh = 0.0
	_flying = false
	_hour = 12.0
	_world_free = true
	_nb = 0
	_nl = 0
	_far()
	_r = BoatRace.new()
	_r.hud = _h
	_r.dialogue = _dlg
	_r.wallet = _wallet
	_r.map = _pm
	_r.car = _car
	_r.log_on = OS.get_environment("BOAT_DEBUG") != ""
	_r.rng_seed = seed_value
	_r.vehicle = func() -> Array: return [_car.global_position, _kmh, _flying]
	_r.clock = func() -> float: return _hour
	_r.seen = func(_p: Vector3) -> bool: return false
	_pw.add_child(_r)
	_r.setup(_pw)
	_r.boarded.connect(func() -> void: _nb += 1)
	_r.left_boat.connect(func() -> void: _nl += 1)
	_dir = Activities.new()
	_dir.world_free = func() -> bool: return _world_free
	_dir.add(_r)
	_other = Activity.new()
	_other.hud = _h
	_other.map = _pm
	_other.vehicle = _r.vehicle
	_pw.add_child(_other)
	_other.setup(_pw)
	_dir.add(_other)


func _far() -> void:
	_car.global_position = Vector3(600.0, 1.5, 600.0)
	_kmh = 0.0
	_flying = false


## The car at the pontoon's car spot plus `off` metres.
func _at(off: Vector2, kmh := 0.0, flying := false) -> void:
	_car.global_position = Vector3(BoatRace.CAR_SPOT.x + off.x, 1.5, BoatRace.CAR_SPOT.y + off.y)
	_kmh = kmh
	_flying = flying


func _fr(seconds: float, steer := false) -> void:
	for i in roundi(seconds / STEP):
		if steer:
			_steer()
		_r._process(STEP)


## The player's boat flat out down the middle, never aiming for a ring (as `_fail_path`).
func _steer() -> void:
	var b: Node3D = _r.boats[0]
	var li := clampi(int(_r.racers[0]["li"]) + 6, 0, _r.line.size() - 1) if not _r.racers.is_empty() else 0
	var to: Vector2 = _r.line[li] - b.pos
	b.target_dir = Vector3(to.x, 0.0, to.y).normalized()


func _afloat() -> bool:
	return _r.phase == Activity.Phase.RUN and _r.stage in [BoatRace.Stage.COUNTDOWN, BoatRace.Stage.RACE]


## Three misses from the grid (the stage becomes OUT); false if it did not come.
func _to_out() -> bool:
	var t := 0.0
	while t < 120.0 and _afloat():
		_steer()
		_r._process(STEP)
		t += STEP
	return _r.stage == BoatRace.Stage.OUT


## The race's own driver takes the player's boat to the line (the stage becomes DONE).
func _to_done() -> bool:
	_r.autopilot = true
	var t := 0.0
	while t < RACE_MAX and _afloat():
		_r._process(STEP)
		t += STEP
	_r.autopilot = false
	return _r.stage == BoatRace.Stage.DONE


func _toast(text: String) -> bool:
	for t in _h.toasts:
		if text in t:
			return true
	return false


func _gap() -> float:
	return float(_r._next_call) - float(_r._session)


func _idle() -> bool:
	return _r.phase == Activity.Phase.IDLE and _r.stage == BoatRace.Stage.NONE


## The call taken and the offer taken, far from the pontoon: the way.
func _start_way() -> void:
	_r.ring()
	_h.press(0)
	_h.press(0)


func _visible_boats() -> int:
	var n := 0
	for b: Node3D in _r.boats:
		if b.visible:
			n += 1
	return n


func _nothing_up(what: String) -> void:
	_ok(_h.card == "" and _h.status == "" and _h.banner == "", "%s: no card, status line or banner up" % what)
	_ok(_visible_boats() == 0 and not _r._barge.visible and _h.mini_dots == 0, "%s: boats and barge away, no minimap dots" % what)
	var rings_up := 0
	for mi: MeshInstance3D in _r._ring_nodes:
		if mi.visible:
			rings_up += 1
	_ok(rings_up == 0, "%s: no ring left standing" % what)
	_ok(not _r.flown and not _r._beacon.visible and not _r.has_target() and not _r.boating(), "%s: not flown, no ring, no target" % what)


func _play(_water: WaterMap) -> void:
	# One engine frame first: the root is in the tree only then (the car's global_position needs it).
	await process_frame
	var t0 := Time.get_ticks_msec()
	_pm = PlayMap.new()
	root.add_child(_pm)
	_pm.load_water()
	_p_clock()
	_p_call()
	_p_chain()
	_p_way_out()
	_p_pill()
	_p_marina()
	_p_free()
	_p_meet()
	_p_straight()
	_p_dice()
	_p_race_dice()
	_p_ducks()
	_p_look()
	_p_scrub()
	_p_arcade()
	await _p_breaks()
	if OS.get_environment("BOAT_DEBUG") != "":
		print("check_boat_race: the play took %.1f s" % (float(Time.get_ticks_msec() - t0) / 1000.0))


# 1. Szymek's clock.
func _p_clock() -> void:
	_rig()
	_fr(BoatRace.FIRST_CALL - 5.0)
	_ok(_idle() and _h.card == "", "no call before FIRST_CALL")
	_hour = 23.0
	_fr(10.0)
	_ok(_idle(), "no call at 23:00")
	_hour = 6.5
	_fr(2.0)
	_ok(_idle(), "no call at 6:30")
	_hour = 12.0
	_flying = true
	_fr(2.0)
	_ok(_idle(), "no call in the air")
	_flying = false
	_world_free = false
	_fr(2.0)
	_ok(_idle(), "no call while the director's world_free says no")
	_world_free = true
	_fr(0.52)
	_ok(_r.phase == Activity.Phase.RING, "with everything right he rings within half a second")
	_ok(not _r.ring() and not _r.meet(), "ring() and meet() answer false while the phone rings")
	_rig()
	_r._session = _r._next_call
	_hour = 23.0
	_fr(1.0)
	_ok(_idle(), "at night he does not ring")
	_r.force_hours = true
	_fr(0.52)
	_ok(_r.phase == Activity.Phase.RING, "force_hours lets him ring at night")


# 2. The call and the offer.
func _p_call() -> void:
	_rig()
	_ok(_r.ring(), "ring() starts the call when idle")
	_ok(_h.card == "📞 SZYMEK DZWONI" and _h.accent == BoatRace.COLOUR and _h.buttons == 2, "the call card: Szymek, in COLOUR, 2 buttons")
	_ok(not _r.busy() and not _r.idle(), "ringing is neither busy nor idle")
	_h.abort_pressed.emit()
	_ok(_r.phase == Activity.Phase.RING and _h.card != "", "the ✕ does nothing while it rings")
	_fr(BoatRace.CARD_LIFE + 0.1)
	_ok(_idle() and _h.card == "", "a call nobody answers goes after CARD_LIFE")
	_ok(absf(_gap() - BoatRace.CALL_COOL * 0.5) < 0.2, "the next call after a missed one is CALL_COOL * 0.5 away")
	_r.ring()
	_h.press(1)
	_ok(_idle() and _h.card == "" and absf(_gap() - BoatRace.CALL_COOL) < 0.01, "ODRZUĆ: idle, the next call CALL_COOL away")
	_r.ring()
	_h.press(0)
	_ok(_h.card == "SZYMEK: „ŚCIGAMY SIĘ?”" and _h.buttons == 2 and _h.accent == BoatRace.COLOUR, "ODBIERZ: the offer, 2 buttons, in COLOUR")
	_ok(_r.busy() and not _r.idle(), "the offer is busy")
	_h.abort_pressed.emit()
	_ok(_r.phase == Activity.Phase.OFFER and _h.card != "", "the ✕ does nothing on the offer")
	_fr(BoatRace.CARD_LIFE + 0.1)
	_ok(_idle() and _h.card == "", "an offer nobody answers goes after CARD_LIFE")
	_r.ring()
	_h.press(0)
	_h.press(1)
	_ok(_idle() and _h.card == "" and absf(_gap() - BoatRace.CALL_COOL) < 0.01, "NIE DZIŚ: idle, the next call CALL_COOL away")


# 3 to 7. The way, the arrival, the grid, the race, out, the finish: one rig.
func _p_chain() -> void:
	_rig()
	_start_way()
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _r.phase == Activity.Phase.RUN, "PŁYNĘ! far away: the way to the pontoon")
	_ok(_toast("Na przystań"), "the toast 'Na przystań…'")
	var bc: Node3D = _r._beacon
	_ok(bc.visible and is_equal_approx(bc._ring_radius, BoatRace.ARRIVE - 0.5) and bc._person.visible, "the kit's ring stands at the pontoon, ARRIVE - 0.5 wide, with the figure")
	_ok(_r.has_target(), "the way has a target")
	_ok(_r.target_position().is_equal_approx(Vector3(BoatRace.CAR_SPOT.x, 1.5, BoatRace.CAR_SPOT.y)), "the target is CAR_SPOT at the bank's 1.5 m")
	_ok(_r.target_colour() == BoatRace.COLOUR and _r.target_arrow() and _r.stop_spot() == Vector3.INF, "target colour COLOUR, an arrow, no stop assist")
	_ok(not _r.flown and not _r.boating(), "on the way: not flown, not boating")
	_ok(_r.grounded() == ["Najpierw dokończ wyścig łodzi (albo ✕)", "Finish the boat race first (or ✕)"], "grounded() says the two sentences")
	_ok(_dir.targeted() == _r and _dir.busy() and _dir.busy_tag() == "boat race" and not _dir.may_start(_other), "the director: targeted, busy, 'boat race', nobody else may start")
	_ok(_r._auto_button() == 1, "TO_PIER: the autopilot's button is 1")
	# 4. Arriving.
	_at(Vector2.ZERO, 0.0, true)
	_fr(5 * STEP)
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _nb == 0, "not boarded in the air over the ring")
	_at(Vector2.ZERO, 40.0)
	_fr(5 * STEP)
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _nb == 0, "not boarded through the ring at 40 km/h")
	_at(Vector2(BoatRace.ARRIVE + 1.0, 0.0), 5.0)
	_fr(5 * STEP)
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _nb == 0, "not boarded 1 m outside ARRIVE")
	_h.show_pill("PRZYSTAŃ", "MARINA", "boat")
	_at(Vector2(3.0, 0.0), 5.0)
	_fr(2 * STEP)
	_ok(_nb == 1 and _r.stage == BoatRace.Stage.COUNTDOWN, "boarded within two frames of standing inside at 5 km/h: boarded once, the grid")
	_ok(not _r._beacon.visible and not _r.has_target(), "boarded: the ring gone, no target")
	_ok(_r.boating() and _r.flown and not _r.target_arrow(), "boarded: boating, flown, no arrow")
	_ok(_visible_boats() == 4 and _h.pill == "", "boarded: four boats, the pill down")
	_ok(_r._auto_button() == 1, "COUNTDOWN: the autopilot's button is 1")
	# 5. The grid and the race.
	var t_cd := 2 * STEP
	while _r.stage == BoatRace.Stage.COUNTDOWN and t_cd < 6.0:
		_fr(STEP)
		t_cd += STEP
	_ok(_r.stage == BoatRace.Stage.RACE and t_cd >= BoatRace.COUNT - 0.2 and t_cd <= BoatRace.COUNT + 0.6, "the countdown ends in the race within COUNT + 0.6 s")
	var seq: Array[String] = []
	for bn: String in _h.banners:
		if seq.is_empty() or seq[-1] != bn:
			seq.append(bn)
	_ok(seq == ["3", "2", "1", "START!"], "the banners 3, 2, 1, START! in order (got %s)" % [seq])
	_fr(0.5)
	_ok(_h.banner == "START!", "START! is up half a second into the race")
	_fr(0.6)
	_ok(_h.banner == "", "START! is down a second into the race")
	# The brief expected rings on the grid already; the script (old and new alike) shows them from
	# the first frame of the race (`_update_rings` runs before the stage is set and not in the
	# countdown), so that is what is pinned.
	var rings_up := 0
	for mi: MeshInstance3D in _r._ring_nodes:
		if mi.visible:
			rings_up += 1
	_ok(rings_up > 0 and rings_up <= 4, "the next rings stand in the race (%d up)" % rings_up)
	_ok(_r.has_target() and _r._auto_button() == 1, "in the race: a target (the minimap's dot)")
	var nr: Dictionary = _r.rings[mini(int(_r.racers[0]["next"]), _r.rings.size() - 1)]
	_ok(_r.target_position().is_equal_approx(Vector3(float(nr["x"]), -2.0, float(nr["z"]))), "the target is the next ring at the water's -2.0 m")
	_ok(_r.target_colour() == BoatRace.RING_NEXT and not _r.target_arrow(), "the race target is RING_NEXT, no arrow")
	_ok(_h.status_title == BoatRace.NAME and _h.tint == BoatRace.COLOUR, "the status line: NAME in COLOUR")
	_ok(_h.badge == ["1ST", "2ND", "3RD", "4TH"][_r.place_now() - 1], "the badge is the place_now() (%s)" % _h.badge)
	_ok(_h.mini_dots == 3, "three rivals on the minimap")
	# 6. Out.
	var ok_out := _to_out()
	_ok(ok_out and _r._auto_button() == 1, "three misses: OUT")
	_ok(_h.card == "ODPADASZ! Trzy pudła." and _h.accent == BoatRace.FAIL and _h.buttons == 2, "the ODPADASZ card in FAIL, 2 buttons")
	_ok(_h.banner == "ODPADASZ!", "the banner ODPADASZ!")
	_ok(_h.cues.count("count") == 3 and _h.cues.count("go") >= 1 and _h.cues[_h.cues.size() - 1] == "fail",
			"3, 2, 1 beep once each, START! goes, OUT fails (%s)" % str(_h.cues))
	var w0: float = _r.wave_t
	_fr(BoatRace.CARD_LIFE + 2.0)
	_ok(_r.stage == BoatRace.Stage.OUT and _h.card == "ODPADASZ! Trzy pudła.", "the result card has no life: still up CARD_LIFE + 2 s later")
	_h.abort_pressed.emit()
	_ok(_r.stage == BoatRace.Stage.OUT and _h.card != "", "the ✕ does nothing behind the card")
	_ok(_r.wave_t > w0 + 10.0, "the boats run on behind the card")
	_h.press(0)
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and int(_r.racers[0]["misses"]) == 0, "JESZCZE RAZ: the grid again, no misses")
	var nl0 := _nl
	_h.abort_pressed.emit()
	_ok(_idle() and _nl == nl0 + 1, "the ✕ on the grid: idle, left_boat once more")
	_nothing_up("after the ✕ on the grid")
	_ok(absf(_gap() - BoatRace.CALL_COOL) < 0.01, "the next call is CALL_COOL away")
	_ok(_dir.may_start(_other) and not _dir.busy(), "the director is free again")
	# 7. The finish.
	_r.board()
	var done := _to_done()
	_ok(done, "the race's own driver finishes (stage DONE)")
	if not done:
		return
	_ok(_h.card.begins_with("META! ") and _h.accent == BoatRace.COLOUR and _h.buttons == 2, "the META card in COLOUR, 2 buttons")
	_ok(_h.status == "", "the status line is down behind the card")
	var res: Dictionary = _r.last_result()
	var place := int(res.get("place", 0))
	_ok(place >= 1 and place <= 4, "last_result() has the place")
	var pay: Array = BoatRace.PAY[clampi(place - 1, 0, 3)]
	var cash := int(pay[0]) + BoatRace.CRATE_PAY * int(_r.sprats)
	_ok(_wallet.money == cash and _wallet.respect == int(pay[1]), "the pay is PAY[place - 1] and the crates (place %d, %d tins: %d zł, %d)" % [place, _r.sprats, _wallet.money, _wallet.respect])
	_ok(_wallet.kinds == (["boat_race"] if cash > 0 else []), "the pay's kind is boat_race, paid once")
	_ok(("Szprotki %d/%d" % [_r.sprats, _r.crates.size()]) in _h.body, "the card counts the sprats")
	_ok(_r._auto_button() == 1, "DONE: the autopilot's button is 1")
	var c0: float = _r.clock_t
	_fr(2.0)
	_ok(_r.clock_t > c0 + 1.5 and _r.stage == BoatRace.Stage.DONE, "clock_t runs on behind the card")
	_h.press(0)
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN, "REWANŻ: the grid again")
	_fr(BoatRace.COUNT + 1.0)
	_ok(_r.stage == BoatRace.Stage.RACE, "the rematch's race")
	nl0 = _nl
	_h.abort_pressed.emit()
	_ok(_idle() and _nl == nl0 + 1, "the ✕ in the race itself: idle, left_boat")
	_nothing_up("after the ✕ in the race")
	# The autopilot at a result card.
	_r.board()
	_r.autopilot = false
	_to_out()
	_r.autopilot = true
	_r._t = 0.0
	nl0 = _nl
	_fr(2.4)
	_ok(_r.stage == BoatRace.Stage.OUT and _h.card != "", "autopilot: the result card is still up 2.4 s after it went up")
	_fr(0.2)
	_ok(_idle() and _nl == nl0 + 1, "autopilot: WYJDŹ at 2.6 s (AUTO_CARD)")
	_r.autopilot = false


# 8. The ✕ and the clock on the way.
func _p_way_out() -> void:
	_rig()
	_start_way()
	_h.abort_pressed.emit()
	_ok(_idle() and not _r._beacon.visible and not _r.has_target() and _nl == 0, "the ✕ on the way: idle, the ring gone, no left_boat")
	_start_way()
	_r._stage_t = BoatRace.PLAY_LIMIT - 0.1
	_fr(0.3)
	_ok(_idle() and not _r._beacon.visible and not _r.has_target() and _nl == 0, "30 minutes on the way: idle, the ring gone, no left_boat")
	_ok(absf(_gap() - BoatRace.CALL_COOL) < 0.5, "30 minutes on the way: the next call CALL_COOL away")


# 9. The pill.
func _p_pill() -> void:
	_rig()
	_at(Vector2(BoatRace.PILL_R + 3.0, 0.0))
	_fr(2 * STEP)
	_ok(_h.pill == "", "no pill 3 m outside PILL_R")
	_at(Vector2(BoatRace.PILL_R - 1.0, 0.0), 0.0, true)
	_fr(2 * STEP)
	_ok(_h.pill == "", "no pill in the air")
	_flying = false
	_world_free = false
	_fr(2 * STEP)
	_ok(_h.pill == "", "no pill while world_free says no")
	_world_free = true
	_h.pill_free = false
	_fr(2 * STEP)
	_ok(_h.pill == "", "no pill while somebody else holds the button")
	_h.pill_free = true
	_r.walk_up_pill = false
	_fr(2 * STEP)
	_ok(_h.pill == "", "no pill with walk_up_pill off")
	_r.walk_up_pill = true
	_fr(2 * STEP)
	_ok(_h.pill == "boat" and _h.pill_word == "PRZYSTAŃ", "inside PILL_R, free: PRZYSTAŃ, whose 'boat'")
	_far()
	_fr(2 * STEP)
	_ok(_h.pill == "", "the pill goes when the car leaves")
	_at(Vector2(30.0, 0.0))
	_fr(2 * STEP)
	_h.context_pressed.emit("call")
	_ok(_idle() and _h.card == "" and _h.pill == "boat", "somebody else's button opens nothing")
	_r.ring()
	_fr(0.3)
	_ok(_h.pill == "boat", "the pill stays up through the call")
	_h.press(0)
	_fr(0.3)
	_ok(_h.pill == "boat", "the pill stays up through the offer")
	_h.press(0)
	_fr(0.3)
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _h.pill == "boat", "the pill stays up on the way")
	var shown0: int = _h.shown
	_h.context_pressed.emit("boat")
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _h.shown == shown0 and _h.card == "" and _h.pill == "boat", "a press of it on the way opens nothing and leaves it up")
	_at(Vector2(3.0, 0.0), 5.0)
	_fr(2 * STEP)
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and _h.pill == "", "the grid takes the pill down")
	_rig()
	_at(Vector2(30.0, 0.0))
	_fr(2 * STEP)
	_ok(_h.pill == "boat", "the pill is up before the meeting")
	_ok(_r.meet(), "meet() starts it")
	_ok(_h.pill == "", "meet() takes the pill down at once")


# 10. The marina's card.
func _p_marina() -> void:
	_rig()
	_at(Vector2(20.0, 0.0))
	_fr(2 * STEP)
	var nc0: float = _r._next_call
	_h.context_pressed.emit("boat")
	_ok(_r.stage == BoatRace.Stage.MENU and _r.phase == Activity.Phase.RUN, "the pill opens the marina's card")
	_ok(_h.card == "PRZYSTAŃ · wybierz łódź" and _h.buttons == BoatRace.FLEET.size() + 1 and _h.accent == BoatRace.FREE_COLOUR, "the marina's card: its title, a button a boat and WYŚCIG, in FREE_COLOUR")
	_ok(_h.pill == "" and _r.busy() and not _r.boating(), "the pill is down, busy, not boating")
	_ok(_r._auto_button() == -1, "MENU: the autopilot's button is -1")
	_r.autopilot = true
	_fr(5.0)
	_ok(_r.stage == BoatRace.Stage.MENU and _h.card != "", "with autopilot on nothing is pressed on the marina's card for 5 s")
	_r.autopilot = false
	_h.abort_pressed.emit()
	_ok(_r.stage == BoatRace.Stage.MENU and _h.card != "", "the ✕ does nothing on the marina's card")
	_fr(BoatRace.CARD_LIFE)
	_ok(_idle() and _h.card == "", "the marina's card goes after CARD_LIFE")
	_ok(_r._next_call == nc0, "its _next_call is what it was (CARD_LIFE)")
	_r._marina_card()
	_at(Vector2(BoatRace.PILL_R + 5.0, 0.0))
	_fr(2 * STEP)
	_ok(_idle() and _h.card == "", "the card goes within two frames of the car driving off")
	_ok(_r._next_call == nc0, "its _next_call is what it was (driving off)")
	_at(Vector2(20.0, 0.0))
	_r._marina_card()
	_h.press(BoatRace.FLEET.size())
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and _r.boating(), "WYŚCIG: the grid")


# 11. A free ride on each boat.
func _p_free() -> void:
	_rig()
	_at(Vector2(20.0, 0.0))
	for i in BoatRace.FLEET.size():
		var name: String = BoatRace.FLEET[i]["name"]
		var nc0: float = _r._next_call
		var nb0 := _nb
		var nl0 := _nl
		_r._marina_card()
		_fr(3.0)
		_h.press(i)
		_ok(_r.stage == BoatRace.Stage.FREE and _nb == nb0 + 1, "%s: the free ride, boarded" % name)
		_ok(_r.player == _r.fleet[i] and _r.flown and _r.boating(), "%s: the player's boat, flown" % name)
		_ok(_toast("jest twoja"), "%s: the toast 'jest twoja'" % name)
		_ok(_h.status_title == "Rejs · " + name and _h.tint == BoatRace.FREE_COLOUR, "%s: the status line 'Rejs · name' in FREE_COLOUR" % name)
		_ok(_h.count == "0:00.0", "%s: the clock starts at 0:00.0 (got %s)" % [name, _h.count])
		_ok(_r._auto_button() == 1, "FREE: the autopilot's button is 1")
		_fr(2.0)
		var secs := float(_h.count.substr(2))
		_ok(secs >= 1.6 and secs <= 2.05, "%s: the clock reads the stage's 2 s, not the card's (got %s)" % [name, _h.count])
		_h.abort_pressed.emit()
		_ok(_idle() and _nl == nl0 + 1, "%s: the ✕ ends it, left_boat" % name)
		var fb: Node3D = _r.fleet[i]
		_ok(fb.visible and fb.pos.distance_to(BoatRace.fleet_spot(i)) < 0.5, "%s: back at its mooring" % name)
		_ok(_r.player == _r.boats[0] and not _r._barge.visible, "%s: the player is the race's boat again, the barge hidden" % name)
		_ok(_r._next_call == nc0, "%s: _next_call is what it was" % name)


# 12 and 13. The meeting and the straight ways in.
func _p_meet() -> void:
	_rig()
	var shown0: int = _h.shown
	_ok(_r.meet() and _r.stage == BoatRace.Stage.TO_PIER, "meet() far away starts the way")
	_ok(_h.shown == shown0, "meet(): no card shown")
	_rig()
	_at(Vector2(2.0, 0.0))
	_ok(_r.meet() and _r.stage == BoatRace.Stage.COUNTDOWN and _nb == 1, "meet() beside the pontoon boards at once")
	# Every phase but idle: meet() is false and the straight ways change nothing.
	_rig()
	_r.ring()
	_probe("while the phone rings")
	_h.press(0)
	_probe("on the offer")
	_h.press(0)
	_probe("on the way")
	_at(Vector2(3.0, 0.0), 5.0)
	_fr(2 * STEP)
	_probe("on the grid")
	_h.abort_pressed.emit()
	_r.free_ride(2)
	_probe("in a free ride")
	_h.abort_pressed.emit()
	_r.board()
	_to_out()
	_probe("behind a result card")
	_h.press(1)
	_ok(_idle(), "WYJDŹ ends it")
	_r._marina_card()
	_probe("on the marina's card")


## `meet()` and the three straight ways, asked in a phase that is not idle: false, nothing changes.
func _probe(where: String) -> void:
	var s0 := _snap()
	_ok(not _r.meet(), "meet() is false %s" % where)
	_r.board()
	_r.free_ride(2)
	_r._marina_card()
	_ok(_snap() == s0, "board(), free_ride(2) and the marina's card change nothing %s" % where)


func _snap() -> Array:
	return [_r.phase, _r.stage, _h.card, _r.player, _nb, _nl, _h.shown, _r._first, _r.riding, _r._pick]


func _p_straight() -> void:
	_rig()
	_r.board()
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and _nb == 1, "board() when idle: the grid")
	_h.abort_pressed.emit()
	_ok(_idle(), "the ✕ on the grid")
	_ok(_r.meet() and _r.stage == BoatRace.Stage.TO_PIER, "after board() and a ✕ the next meet() far away goes to the pontoon")
	_rig()
	_r.free_ride(2)
	_ok(_r.stage == BoatRace.Stage.FREE and _r.player == _r.fleet[2] and _r.riding == 2, "free_ride(2) when idle: the third boat")
	_rig()
	_r._marina_card()
	_ok(_r.stage == BoatRace.Stage.MENU and _h.card == "PRZYSTAŃ · wybierz łódź", "the marina's card when idle")
	_rig()
	_r.free_ride(7)
	_ok(_r.stage == BoatRace.Stage.FREE and _r.player == _r.fleet[BoatRace.FLEET.size() - 1], "free_ride(7) takes the last boat")


# 14. The script's dice.
func _p_dice() -> void:
	var mir := RandomNumberGenerator.new()
	mir.seed = 5
	_rig(5)
	_ok(_r._rng.state == mir.state, "a fresh race's dice are the mirror's")
	_r.ring()
	_fr(BoatRace.CARD_LIFE + 0.1)
	_r.ring()
	_h.press(1)
	_r.ring()
	_h.press(0)
	_h.press(1)
	_ok(_r._rng.state == mir.state, "calls missed and declined draw nothing")
	_start_way()
	_h.abort_pressed.emit()
	_ok(_r._rng.state == mir.state, "the way and a ✕ draw nothing")
	_r._marina_card()
	_fr(BoatRace.CARD_LIFE + 0.2)
	_r.free_ride(1)
	_fr(1.0)
	_h.abort_pressed.emit()
	_ok(_idle() and _r._rng.state == mir.state, "the marina's card and a free ride draw nothing")
	_r.board()
	var aims: Array[float] = []
	for k in 4:
		aims.append(mir.randf_range(-1.0, 1.0))
	var same: bool = _r.racers.size() == 4
	for k in mini(4, _r.racers.size()):
		same = same and is_equal_approx(float(_r.racers[k]["aim"]), aims[k])
	_ok(same, "the first grid's aims are the mirror's four draws, in order")
	_ok(_r._rng.state == mir.state, "the first grid draws exactly four randf_range(-1, 1)")


# The dice in the race: every draw is the next of the one stream (the mirror follows it frame by
# frame): one for every ring a boat first aims at (the key "m<ring>" in its racer), the rest the
# rivals' stunts over the ramps.
func _p_race_dice() -> void:
	var mir := RandomNumberGenerator.new()
	mir.seed = 5
	_rig(5)
	_r.board()
	for k in 4:
		mir.randf_range(-1.0, 1.0)
	_r.autopilot = true
	var draws := 0
	var lost := false
	var t := 0.0
	while t < RACE_MAX and _afloat() and not lost:
		_r._process(STEP)
		t += STEP
		var n := 0
		while _r._rng.state != mir.state and n < 16:
			mir.randf()
			n += 1
		lost = _r._rng.state != mir.state
		draws += n
	_r.autopilot = false
	var aims := 0
	var stunts := 0
	for r: Dictionary in _r.racers:
		stunts += int(r["stunts"])
		for key: Variant in r.keys():
			if str(key).begins_with("m") and str(key).substr(1).is_valid_int():
				aims += 1
	_ok(not lost and _r.stage == BoatRace.Stage.DONE, "the race's dice stay on the one stream to the finish")
	_ok(aims >= 4 * 20, "every boat drew for the rings it aimed at (%d draws for rings)" % aims)
	_ok(draws >= aims + maxi(stunts, 1), "the race drew once a ring aimed at and at least once for a stunt (%d draws, %d rings aimed at, %d stunts)" % [draws, aims, stunts])
	if OS.get_environment("BOAT_DEBUG") != "":
		print("check_boat_race: the race's dice: %d draws, %d rings aimed at, %d stunts" % [draws, aims, stunts])


# The ducks (F 2026-11-26): three families between rings; a boat on the mother scatters them, loses
# speed and a rhythm pip, the family leaves the water; a new grid brings them back. Plus the
# record on the finish card.
func _p_ducks() -> void:
	_rig(7)
	_r.board()
	_ok(_r._ducks.size() == BoatRace.DUCK_SPOTS.size(), "three duck families on the course")
	_fr(BoatRace.COUNT + 1.5)
	_ok(_r.stage == BoatRace.Stage.RACE, "ducks: the race is on")
	var d: Dictionary = _r._ducks[1]
	var me: Boat = _r.boats[0]
	var mom: Vector2 = d["pos"]
	var before: Vector2 = Vector2(6.0, 0.0)
	me.place(mom + Vector2(0.0, 2.0), 0.0)
	me.vel = before
	_r.racers[0]["rhythm"] = 3
	_r._process(STEP)
	_ok(_r.ducks_scared >= 1 and int(d["state"]) == 1, "a boat on the mother scatters the family")
	_ok(int(_r.racers[0]["rhythm"]) == 2, "and loses a rhythm pip")
	_ok(me.vel.length() < before.length() * 0.95, "and some speed")
	_fr(BoatRace.DUCK_FLY + 0.3)
	_ok(int(d["state"]) == 2 and not (d["node"] as MeshInstance3D).visible, "the family flew off, nobody hurt")
	_h.abort_pressed.emit()
	_r.board()
	_ok(_r.ducks_scared == 0 and int(_r._ducks[1]["state"]) == 0, "a new grid brings the ducks back")
	for dd: Dictionary in _r._ducks:
		var q: Vector2 = dd["at"]
		var near := 1e9
		for g: Dictionary in _r.rings:
			near = minf(near, q.distance_to(Vector2(float(g["x"]), float(g["z"]))))
		_ok(near > 25.0, "a duck family is clear of every ring (%.0f m)" % near)


# The Szprotka look: view only, zero at a standstill, lower and rolling at speed, back to zero off the water.
func _p_look() -> void:
	_rig(7)
	_ok(_r.look(0.016) == Vector2.ZERO, "the look is flat before the race")
	_r.board()
	_fr(BoatRace.COUNT + 1.0)
	var me: Boat = _r.boats[0]
	me.vel = Vector2.from_angle(PI * 0.5 - me.yaw) * float(me.spec["top"]) * 0.9
	me.yaw_rate = 1.0
	var lk := Vector2.ZERO
	for i in 120:
		lk = _r.look(0.016)
	_ok(lk.x > 3.0 and lk.x < 12.0, "at speed the camera drops a few degrees (%.1f)" % lk.x)
	_ok(absf(lk.y) > 1.0 and absf(lk.y) <= BoatRace.LOOK_ROLL + 0.01, "a turn leans the view (%.1f deg)" % lk.y)
	_h.abort_pressed.emit()
	for i in 240:
		lk = _r.look(0.016)
	_ok(lk.length() < 0.2, "the look eases back to flat off the water")


# Banks scrub: half a second along a bank keeps most of the speed (the old x0.92 a frame left 8 %).
func _p_scrub() -> void:
	var b := Boat.new()
	b.setup(Boat.Kind.RUNABOUT, Boat.runabout_mesh(Color.ORANGE, Color.TAN, Color.WHITE, Color.BLACK), null)
	var n := Vector2(1.0, 0.0)
	b.vel = Vector2(-6.0, 20.0)
	b._dt = STEP
	b._hit(n)
	_ok(b.vel.length() < 20.9 * 0.93, "the first frame of a bank is the hard hit (%.1f of 20.9)" % b.vel.length())
	b.vel = Vector2(-0.1, 20.0)
	for i in 30:
		b._contact = 0.7
		b.vel.x = -0.1
		b._hit(n)
	_ok(b.vel.length() > 20.0 * 0.45, "half a second along a bank keeps over 45 %% of the speed (%.1f of 20)" % b.vel.length())


# The arcade pass (Fable's plan, 2026-11-26): the nitro fills and burns, the start's timing, the
# crates, the banks, Szymek's inside line, the streaks.
func _p_arcade() -> void:
	_rig(7)
	_r.board()
	_fr(BoatRace.COUNT - 0.5)
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and is_equal_approx(_r.nitro, BoatRace.NITRO_START), "nitro: the tank starts at NITRO_START")
	_fr(1.6)
	_ok(_r.stage == BoatRace.Stage.RACE, "nitro: the race is on")
	var me: Boat = _r.boats[0]
	_r.nitro = 0.1
	_r.nitro_hold = true
	_fr(STEP)
	_ok(not _r.nitro_on, "nitro: under NITRO_MIN it does not light")
	_r.nitro_hold = false
	_fr(STEP)
	_r.nitro = 0.6
	_r.nitro_hold = true
	_fr(STEP)
	_ok(_r.nitro_on and is_equal_approx(me.surge, BoatRace.NITRO_PULL) and is_equal_approx(me.turn_mult, BoatRace.NITRO_TURN), "nitro: held, it lights (pull x%.1f, rudder x%.2f)" % [me.surge, me.turn_mult])
	_ok(me.boost >= BoatRace.NITRO_BOOST - 0.001 and _r.boost_now(), "nitro: the top speed x NITRO_BOOST (boost %.2f)" % me.boost)
	_ok(_r._flame.visible and _r.shake >= 0.17, "nitro: the flame burns at the stern and the view shakes")
	var n0: float = _r.nitro
	_fr(0.5)
	_ok(_r.nitro < n0 - BoatRace.NITRO_BURN * 0.4 and _r.nitro_on, "nitro: it burns (%.2f -> %.2f in 0.5 s)" % [n0, _r.nitro])
	_ok(_r._spray.live() > 0, "nitro: the spray flies")
	var lk := Vector2.ZERO
	for i in 120:
		lk = _r.look(0.016)
	_r.nitro_hold = false
	_fr(STEP)
	_ok(not _r.nitro_on and is_equal_approx(me.surge, 1.0) and is_equal_approx(me.turn_mult, 1.0) and not _r._flame.visible, "nitro: let go, it goes out")
	_r.nitro = 0.25
	_r.nitro_hold = true
	_fr(1.0)
	_ok(not _r.nitro_on and _r.nitro <= 0.0, "nitro: it burns dry")
	_ok(_h.cues.has("tick"), "nitro: dry, a tick")
	_r._fill(0.5)
	_fr(STEP)
	_ok(not _r.nitro_on, "nitro: dry while held, it waits for the disc to be let go")
	_r.nitro_hold = false
	_fr(STEP)
	_r.nitro_hold = true
	_fr(STEP)
	_ok(_r.nitro_on, "nitro: pressed again, it lights")
	_r.nitro_hold = false
	_fr(STEP)
	_r.nitro = 0.5
	_r.racers[0]["misses"] = 0
	_r._miss(0, 3)
	_ok(is_equal_approx(_r.nitro, 0.5 - BoatRace.COST_MISS), "nitro: a miss costs COST_MISS")
	_r._fill(2.0)
	_ok(is_equal_approx(_r.nitro, 1.0), "nitro: the tank is full at 1")
	# The crates: in the water, one MultiMesh, the player takes one, three in a row are a shoal.
	_ok(_r.crates.size() >= 30 and _r.crates.size() <= BoatRace.CRATE_N, "crates: %d on the course" % _r.crates.size())
	var dry := 0
	for c: Vector2 in _r.crates:
		if _pm.shore_distance(c.x, c.y) < 3.0:
			dry += 1
	_ok(dry == 0, "crates: every one in open water (%d by the bank)" % dry)
	_ok(_r._crate_mm.visible and _r._crate_mm.multimesh.instance_count == _r.crates.size(), "crates: one MultiMesh, shown in the race")
	_r.nitro = 0.3
	var got0: int = _r.sprats
	for j in 3:
		var c: Vector2 = _r.crates[10 + j]
		me.place(c + Vector2(0.5, 0.0), me.yaw)
		_fr(STEP)
	_ok(_r.sprats == got0 + 3 and _r._crate_taken[10] and _r._crate_taken[12], "crates: the player takes them (%d)" % _r.sprats)
	_ok(_toast("ŁAWICA"), "crates: three inside SHOAL_T s are a shoal")
	_ok(_r.nitro >= minf(1.0, 0.3 + 3.0 * BoatRace.FILL_CRATE + BoatRace.FILL_SHOAL) - 0.05, "crates: each fills the tank, the shoal more (%.2f)" % _r.nitro)
	me.place(_r.crates[10] + Vector2(0.5, 0.0), me.yaw)
	_fr(STEP)
	_ok(_r.sprats == got0 + 3, "crates: a taken one is gone")
	# The banks: open water is no hug; a few metres off a bank at speed along it is.
	var li: int = _r.line.size() / 3
	var mid: Vector2 = _r.line[li]
	var along: Vector2 = (_r.line[li + 1] - _r.line[li - 1]).normalized()
	var across := Vector2(-along.y, along.x)
	_r.hug_t = 0.0
	for i in 60:
		me.pos = mid
		me.yaw = atan2(along.x, along.y)
		me.vel = along * float(me.spec["top"]) * 0.9
		_fr(STEP)
	_ok(not _r.hugging and _r.hug_t == 0.0, "banks: mid-river is no hug")
	var spot := mid
	for k in 400:
		spot = mid + across * float(k)
		if _pm.shore_distance(spot.x, spot.y) < 5.5:
			break
	var d_spot: float = _pm.shore_distance(spot.x, spot.y)
	_r.nitro = 0.2
	for i in 60:
		me.pos = spot
		me.yaw = atan2(along.x, along.y)
		me.vel = along * float(me.spec["top"]) * 0.9
		_fr(STEP)
	_ok(d_spot > BoatRace.HUG_IN and d_spot < BoatRace.HUG_D and _r.hugging, "banks: %.1f m off a bank at speed, a hug" % d_spot)
	_ok(_r.nitro > 0.2 + BoatRace.FILL_HUG * 0.3 and me.boost >= BoatRace.HUG_BOOST - 0.001, "banks: the hug fills the tank and lifts the top (%.2f, boost %.2f)" % [_r.nitro, me.boost])
	# Szymek's line leans to the inside of every ring.
	var sz: Dictionary = _r.racers[1]
	var aim0: float = sz["aim"]
	sz["aim"] = 0.0
	var g: Dictionary = _r.rings[2]
	sz.erase("m2")
	var a: Vector2 = _r._ring_aim(1, 2, BoatRace.RIVALS[0])
	var side := (a - Vector2(float(g["x"]), float(g["z"]))).dot(Vector2(cos(float(g["yaw"])), -sin(float(g["yaw"])))) * float(g["in"])
	_ok(bool(sz["m2"]) or side > 1.0, "Szymek aims at the inside of a ring (%.1f m)" % side)
	sz["aim"] = aim0
	_h.abort_pressed.emit()
	_ok(not _r.nitro_on and not _r._crate_mm.visible and _r._spray.live() == 0, "the ✕: no nitro, no crates, no spray")
	# The start: gas pressed just after START! is a rocket; gas held from the grid a false start.
	_rig(7)
	_r.board()
	_fr(BoatRace.COUNT - 0.5)
	while _r.stage == BoatRace.Stage.COUNTDOWN:
		_fr(STEP)
	_r.gas_hold = true
	_fr(STEP)
	_ok(_toast("START RAKIETA") and float(_r.racers[0]["inside_t"]) > 1.5 and _r.nitro >= BoatRace.NITRO_START + BoatRace.FILL_ROCKET - 0.01, "the start: gas on START! is a rocket start")
	_h.abort_pressed.emit()
	_rig(7)
	_r.board()
	_r.gas_hold = true
	_fr(BoatRace.COUNT + 0.8)
	_ok(_r.stage == BoatRace.Stage.RACE and _toast("FALSTART") and not _toast("START RAKIETA"), "the start: gas held from the grid is a false start")
	_ok(is_equal_approx(_r.boats[0].surge, BoatRace.FALSE_SURGE) or _r._false_t <= 0.0, "the start: the false start halves the pull a moment")
	_r.gas_hold = false
	_h.abort_pressed.emit()
	# The streaks: none at cruise, up past 80 % of the top, stronger on nitro.
	var st := BoatStreaks.new()
	_pw.add_child(st)
	for i in 60:
		st.set_speed(0.6, false, STEP)
	_ok(st.amount == 0.0 and not st.visible, "streaks: none at 60 % of the top")
	for i in 120:
		st.set_speed(1.2, false, STEP)
	_ok(absf(st.amount - BoatStreaks.MAX_A) < 0.02 and st.visible, "streaks: full at 120 %% (%.2f)" % st.amount)
	for i in 120:
		st.set_speed(1.0, true, STEP)
	_ok(absf(st.amount - BoatStreaks.NITRO_A) < 0.02, "streaks: stronger on nitro (%.2f)" % st.amount)
	st.free()


# What the deliberate breaks found missing above: 119 changes made on purpose to boat_race.gd
# were run against this play, and each one it let through got its check here.
func _p_breaks() -> void:
	_rig()
	# The words: who calls and what he is to the player; the offer in both languages, its buttons
	# in order, Szymek's face.
	var call: Dictionary = _r._call_card()
	_ok(call["who"] == "Szymek" and call["about"] == ["Kumpel z przystani. Ma motorówkę i zero cierpliwości.", "Your marina mate. Has a motorboat and zero patience."], "the call: Szymek and what he is to the player, in both languages")
	var offer: Dictionary = _r._offer_card()
	_ok(offer["title"] == ["SZYMEK: „ŚCIGAMY SIĘ?”", "Szymek: \"Race you?\""], "the offer's title in both languages")
	var body: Array = offer["body"]
	_ok(body.size() == 2 and BoatRace.NAME in str(body[0]) and BoatRace.NAME in str(body[1]), "the offer names the race in both languages")
	_ok("Trzy pudła i odpadasz" in str(body[0]) and "Three misses and you're out" in str(body[1]), "the offer says the rule (three misses) in both languages")
	_ok(Array(offer["buttons"]) == ["PŁYNĘ!|I'M IN!", "NIE DZIŚ|NOT TODAY"] and offer["face"] == "Szymek", "the offer's buttons in order, with Szymek's face")
	# The person in the pontoon's ring wears the marina's navy (beacon.gd: the third box of the person).
	_start_way()
	var shirt: Color = ((_r._beacon._person.get_child(2) as MeshInstance3D).mesh as BoxMesh).material.albedo_color
	_ok(shirt.is_equal_approx(Color("#1f3a5f")), "the person in the pontoon's ring wears the marina's navy")
	# The stage's clock starts again on the grid; the car's place on the bank is kept for the way back.
	_fr(2.0)
	_car.rotation.y = 0.7
	_at(Vector2(3.0, 1.0), 5.0)
	_fr(2 * STEP)
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and _r._stage_t < 0.05, "the stage's clock starts again on the grid")
	_ok(_r._car_spot.is_equal_approx(_car.global_position) and is_equal_approx(_r._car_yaw, 0.7), "the car's place and heading on the bank are kept at boarding")
	# Behind a result card the player is still on the water, and the finish's card waits too.
	_ok(_to_out() and _r.boating() and _r.flown, "behind the ODPADASZ card: still on the water")
	_h.press(0)
	var done := _to_done()
	_ok(done and _r.boating() and _r.flown, "behind the finish's card: still on the water")
	_fr(BoatRace.CARD_LIFE + 2.0)
	_ok(_r.stage == BoatRace.Stage.DONE and _h.card.begins_with("META! "), "the finish's card has no life: still up CARD_LIFE + 2 s later")
	_h.press(1)
	_ok(_idle(), "WYJDŹ on the finish's card ends it")
	# PŁYNĘ! taken beside the pontoon, and in the air over it.
	_rig()
	_at(Vector2(-10.0, 8.0))
	_start_way()
	_ok(_r.stage == BoatRace.Stage.COUNTDOWN and _nb == 1, "PŁYNĘ! 12.8 m from the pontoon boards at once")
	_rig()
	_at(Vector2(3.0, -2.0), 0.0, true)
	_start_way()
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _nb == 0, "PŁYNĘ! in the air over the pontoon does not board")
	# The marina's card: its life to the fifth of a second.
	_rig()
	_at(Vector2(20.0, 0.0))
	_r._marina_card()
	_fr(BoatRace.CARD_LIFE - 0.2)
	_ok(_r.stage == BoatRace.Stage.MENU and _h.card != "", "the marina's card is still up 0.2 s before CARD_LIFE")
	_fr(0.4)
	_ok(_idle() and _h.card == "", "the marina's card is gone 0.2 s after CARD_LIFE")
	# The pill: a meeting that is refused leaves it up; a free ride straight from the bank takes it down.
	_fr(2 * STEP)
	_start_way()
	_ok(_r.stage == BoatRace.Stage.TO_PIER and _h.pill == "boat", "the way taken 20 m from the pontoon, the pill still up")
	_ok(not _r.meet() and _h.pill == "boat", "a meeting refused on the way leaves the pill up")
	_h.abort_pressed.emit()
	_fr(2 * STEP)
	_ok(_idle() and _h.pill == "boat", "the pill is up by the pontoon when idle")
	_r.free_ride(1)
	_ok(_r.stage == BoatRace.Stage.FREE and _h.pill == "", "a free ride takes the pill down")
	# The wake: on the water at speed, and off it when the ride ends.
	_r.player.throttle = 1.0
	_fr(6.0)
	_ok(_r._foam_mesh.get_surface_count() > 0, "a free ride at speed leaves a wake on the water")
	_h.abort_pressed.emit()
	_ok(_idle() and _r._foam_mesh.get_surface_count() == 0, "the ✕ takes the wake off the water")
	# A thing standing in the water pushes a hull (the hull's test against the world's bodies):
	# a pile in the course's open water, 45 m down from the grid.
	var g1: Array = _r.grid[1]
	var at := Vector3(float(g1[0]) + _r.flow_dir.x * 45.0, _r.water_y, float(g1[1]) + _r.flow_dir.y * 45.0)
	var beside := at + Vector3(1.0, 0.0, 0.0)
	_ok(_r.solid_at(beside, 1.5) == Vector2.ZERO, "open water pushes nothing")
	var pile := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.5
	cyl.height = 8.0
	shape.shape = cyl
	pile.add_child(shape)
	root.add_child(pile)
	pile.global_position = at
	await physics_frame
	await physics_frame
	_ok(_r.solid_at(beside, 1.5).length() > 0.01, "a thing standing in the water pushes a hull")
	pile.queue_free()
