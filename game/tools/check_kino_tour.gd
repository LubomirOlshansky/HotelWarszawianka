extends SceneTree
## The cinema tour "Kino objazdowe" (tour.gd with data/kino_tour.json, docs/design/kino-tour.md).
## Checks that:
## - the pickup and every cinema stop stand on a drivable road of game/map/centrum.json (ON_ROAD m),
##   each cinema stop within DOOR_MAX m of its cinema's door (the OSM point), in order south to north;
## - the call (ODBIERZ, JADĘ) starts the tour, stopping at the pickup takes Wiktor in, each cinema
##   gives its pitch card and DRIVE ON leads to the next, Muranów ends it with the pay;
## - each leg's shot (long take, static, reverse, rush) fills only when driven its way;
## - a hit scratches one frame, a second hit inside BUMP_WAIT does not, the reel never goes below 0
##   and the last frame has its own line;
## - the pay is the data's base - a lost frame's price + a shot's bonus, the ✕ drops the tour;
## - every line group the tour speaks (`kino_wiktor` and its tags) has Polish and English lines.
##   godot --headless --path game --script res://tools/check_kino_tour.gd

const Tour := preload("res://scripts/tour.gd")
const Fakes := preload("res://tools/fakes.gd")

const ON_ROAD := 4.0
const DOOR_MAX := 80.0
## The cinemas' doors (OpenStreetMap points, game x/z).
const DOORS := {"amondo": Vector2(-555.9, 588.5), "atlantic": Vector2(-781.9, 267.2), "kinoteka": Vector2(-1195.7, 296.1),
		"muranow": Vector2(-1653.5, -1212.1)}
const DRIVE := ["primary", "secondary", "tertiary", "residential", "unclassified", "living_street", "service",
		"primary_link", "secondary_link", "tertiary_link"]
const TAGS := ["hello", "bump", "ruined", "shot_long", "shot_static", "shot_reverse", "shot_rush"]
const STEP := 0.1


var _fails: Array[String] = []
var _pos := Vector3.ZERO
var _kmh := 0.0
var _fwd := 0.0
## The tour's data file and its stops.
var _data: Dictionary = {}
var _stops: Array = []


func _initialize() -> void:
	_go.call_deferred()


## After the first frame, so the tour's beacon is in the tree.
func _go() -> void:
	_data = Tour.load_data("kino")
	if _data.is_empty():
		print("check_kino_tour: FAIL data/kino_tour.json does not load")
		quit(1)
		return
	_stops = _data["stops"]
	_roads()
	_lines()
	_tour()
	if _fails.is_empty():
		print("check_kino_tour: OK")
		quit(0)
	else:
		for f in _fails:
			print("check_kino_tour: FAIL " + f)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _roads() -> void:
	var text := FileAccess.get_file_as_string("res://map/centrum.json")
	if text == "":
		print("check_kino_tour: (no centrum.json, the road test skipped)")
		return
	var data: Dictionary = JSON.parse_string(text)
	var spots: Array = [["pickup", Tour.spot(_data["pickup"]["at"])]]
	for s: Dictionary in _stops:
		spots.append([s["id"], Tour.spot(s["at"])])
	for sp: Array in spots:
		var at: Vector2 = sp[1]
		var best := INF
		for r: Dictionary in data["roads"]:
			if not String(r["k"]) in DRIVE:
				continue
			var p: Array = r["p"]
			for i in range(0, p.size() - 3, 2):
				var a := Vector2(float(p[i]), float(p[i + 1]))
				var b := Vector2(float(p[i + 2]), float(p[i + 3]))
				best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)))
		_expect(best <= ON_ROAD, "%s: %.1f m from a drivable road" % [sp[0], best])
		if DOORS.has(sp[0]):
			var dd: float = at.distance_to(DOORS[sp[0]])
			_expect(dd <= DOOR_MAX, "%s: the stop is %.0f m from the door" % [sp[0], dd])
	var z := INF
	for s: Dictionary in _stops:
		var sz: float = Tour.spot(s["at"]).y
		_expect(sz < z, "%s: not north of the stop before" % s["id"])
		z = sz


func _lines() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var lines: Array = d.get("kino_wiktor", [])
	var general := 0
	var tags := {}
	for l: Array in lines:
		_expect(l.size() >= 2 and String(l[0]) != "" and String(l[1]) != "", "a kino_wiktor line without Polish or English")
		if l.size() > 2 and l[2] is Dictionary:
			tags[String(l[2].get("only", ""))] = true
		else:
			general += 1
	_expect(general >= 15, "kino_wiktor: %d general lines (want 15+)" % general)
	for t: String in TAGS:
		_expect(tags.has(t), "kino_wiktor: no line for %s" % t)


func _new() -> Array:
	var hud := Fakes.Hud.new()
	var dlg := Fakes.Dialogue.new()
	var wal := Fakes.Wallet.new()
	var map := Fakes.FlatMap.new()
	root.add_child(hud)
	root.add_child(dlg)
	root.add_child(wal)
	root.add_child(map)
	var k := Tour.new()
	k.configure(_data)
	k.hud = hud
	k.dialogue = dlg
	k.wallet = wal
	k.map = map
	k.vehicle = func() -> Array: return [_pos, _kmh, false, _fwd]
	root.add_child(k)
	k.setup(map)
	k.set_process(false)
	return [k, hud, dlg, wal]


func _run(k: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		k._process(STEP)
		t += STEP


## The tour is at this point of its way: "IDLE", "RING", "OFFER", or a stage of the run.
func _is(k: Tour, what: String) -> bool:
	match what:
		"IDLE":
			return k.phase == Tour.Phase.IDLE
		"RING":
			return k.phase == Tour.Phase.RING
		"OFFER":
			return k.phase == Tour.Phase.OFFER
	return k.phase == Tour.Phase.RUN and k.stage == Tour.Stage[what]


## Frames of the reel left.
func _frames(k: Tour) -> int:
	return k.bump_max - k.bumps


func _at(p: Vector2, kmh := 0.0, fwd := 0.0) -> void:
	_pos = Vector3(p.x, 0.0, p.y)
	_kmh = kmh
	_fwd = fwd


func _tour() -> void:
	var parts := _new()
	var k: Tour = parts[0]
	var hud: Fakes.Hud = parts[1]
	var dlg: Fakes.Dialogue = parts[2]
	var wal: Fakes.Wallet = parts[3]
	_at(Vector2(0, 0), 30.0)
	_expect(k.ring() and _is(k, "RING") and hud.card.contains("WIKTOR"), "the call rings")
	hud.press(0)
	_expect(_is(k, "OFFER"), "ODBIERZ: the offer")
	hud.press(0)
	_expect(_is(k, "TO_PICKUP") and k.has_target() and k.busy(), "JADĘ: to the pickup")
	_run(k, 1.0)
	_expect(_is(k, "TO_PICKUP"), "far from the pickup: still going there")
	_at(k.pickup_at(), 3.0)
	_run(k, 1.5)
	_expect(_is(k, "LEG") and k.stop == 0, "stopped at the pickup: Wiktor gets in (stage %d)" % k.stage)
	# Leg 0, the long take: 10 s fast does nothing, 16 s at 20 km/h does it.
	_at(Vector2(-500, 1200), 70.0)
	_run(k, 10.0)
	_expect(not k.shots_done.has("long"), "the long take: not at 70 km/h")
	_at(Vector2(-500, 1200), 20.0)
	_run(k, 16.0)
	_expect(k.shots_done.has("long"), "the long take: 16 s at 20 km/h")
	# Hits: one scratch, none more inside BUMP_WAIT, then another.
	k.on_bump(null, 6.0)
	k.on_bump(null, 6.0)
	_expect(_frames(k) == k.bump_max - 1, "one hit, one scratch (%d frames)" % _frames(k))
	k.on_bump(null, 1.0)
	_run(k, Tour.BUMP_WAIT + 0.2)
	k.on_bump(null, 1.0)
	_expect(_frames(k) == k.bump_max - 1, "a soft touch: no scratch")
	k.on_bump(null, 6.0)
	_expect(_frames(k) == k.bump_max - 2, "a second hit later: a second scratch (%d)" % _frames(k))
	# Each cinema: arrive, the pitch card, DRIVE ON.
	for i in _stops.size():
		var s: Dictionary = _stops[i]
		match String(s["shot"]):
			"static":
				_at(Vector2(-700, 450), 0.0)
				_run(k, 5.5)
				_expect(k.shots_done.has("static"), "the static shot: 5.5 s standing")
			"reverse":
				var p := Vector2(-900, 340)
				for n in 260:
					p.x -= 0.1
					_at(p, 3.6, -1.0)
					k._process(STEP)
				_expect(k.shots_done.has("reverse"), "reverse chronology: 26 m backwards")
			"rush":
				_at(Vector2(-1400, -400), 50.0)
				_run(k, 5.0)
				_expect(not k.shots_done.has("rush"), "the rush: not at 50 km/h")
		_at(Tour.spot(s["at"]), 2.0)
		_run(k, 1.5)
		if i < _stops.size() - 1:
			_expect(_is(k, "STOP") and hud.card != "", "%s: the pitch card" % s["id"])
			hud.press(0)
			_expect(_is(k, "LEG") and k.stop == i + 1, "%s: DRIVE ON to the next" % s["id"])
	_expect(_is(k, "DONE") and hud.card.contains("MURANÓW"), "Muranów: the premiere card")
	var want := int(k.pay["base"]) - 2 * int(k.pay["bump"]) + 3 * int(k.pay["shot"])
	_expect(wal.money == want, "the pay: %d zł (want %d: two frames lost, three shots)" % [wal.money, want])
	_expect(wal.respect == int(k.pay["respect"]) - 2 * int(k.pay["respect_bump"]), "the respect: %d" % wal.respect)
	hud.press(0)
	_expect(_is(k, "IDLE") and not k.busy(), "BRAVO: back to idle")
	# The reel never goes below nothing.
	k.start()
	_at(k.pickup_at(), 0.0)
	_run(k, 1.5)
	for n in 8:
		k.on_bump(null, 8.0)
		_run(k, Tour.BUMP_WAIT + 0.1)
	_expect(_frames(k) == 0, "eight hits: the reel at 0 (%d)" % _frames(k))
	_expect(dlg.said.count("kino_wiktor:ruined") == 1, "the last frame: Wiktor's own line, once (%d)" % dlg.said.count("kino_wiktor:ruined"))
	# The ✕ drops the tour.
	hud.abort_pressed.emit()
	_expect(_is(k, "IDLE") and not k.has_target(), "✕: the tour dropped")
