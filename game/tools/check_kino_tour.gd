extends SceneTree
## The cinema tour "Kino objazdowe" (kino_tour.gd, docs/design/kino-tour.md). Checks that:
## - the pickup and every cinema stop stand on a drivable road of game/map/centrum.json (ON_ROAD m),
##   each cinema stop within DOOR_MAX m of its cinema's door (the OSM point), in order south to north;
## - the call (ODBIERZ, JADĘ) starts the tour, stopping at the pickup takes Wiktor in, each cinema
##   gives its pitch card and DRIVE ON leads to the next, Muranów ends it with the pay;
## - each leg's shot (long take, static, reverse, rush) fills only when driven its way;
## - a hit scratches one frame, a second hit inside BUMP_WAIT does not, the reel never goes below 0;
## - the pay is PAY_BASE - PAY_FRAME a lost frame + PAY_SHOT a shot, the ✕ drops the tour;
## - every line group the tour speaks (`kino_wiktor` and its tags) has Polish and English lines.
##   godot --headless --path game --script res://tools/check_kino_tour.gd

const KinoTour := preload("res://scripts/kino_tour.gd")

const ON_ROAD := 4.0
const DOOR_MAX := 80.0
## The cinemas' doors (OpenStreetMap points, game x/z).
const DOORS := {"amondo": Vector2(-555.9, 588.5), "atlantic": Vector2(-781.9, 267.2), "kinoteka": Vector2(-1195.7, 296.1),
		"muranow": Vector2(-1653.5, -1212.1)}
const DRIVE := ["primary", "secondary", "tertiary", "residential", "unclassified", "living_street", "service",
		"primary_link", "secondary_link", "tertiary_link"]
const TAGS := ["hello", "bump", "ruined", "shot_long", "shot_static", "shot_reverse", "shot_rush"]
const STEP := 0.1


class FakeHud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	var card := ""
	var status := ""
	func show_card(title: String, _b: String, _btn: PackedStringArray, _a: Color, _bottom := false, _te := "", _be := "", _s := false) -> void:
		card = title
	func show_side_card(title: String, _b: String, _btn: PackedStringArray, _a: Color, _te := "", _be := "", _s := false) -> void:
		card = title
	func hide_card() -> void:
		card = ""
	func toast(_a: String, _b := "") -> void:
		pass
	func show_status(_t: String, _c: String, _d: String, h: String, _p: float, _a: Color, _badge := "", _i := {}, _he := "") -> void:
		status = h
	func hide_status() -> void:
		status = ""
	func ticker_out() -> void:
		pass


class FakeDialogue extends Node:
	var said: Array[String] = []
	func say(_anchor: Variant, _who: String, group: String, tag := "", _s := 4.0, _c := Color.WHITE, _h := 2.6, _p := false) -> Array:
		said.append(group + ":" + tag)
		return []


class FakeWallet extends Node:
	var money := 0
	var respect := 0
	func pay(amount: int, gain := 0, _kind := "") -> void:
		money += amount
		respect += gain


class FlatMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0


var _fails: Array[String] = []
var _pos := Vector3.ZERO
var _kmh := 0.0
var _fwd := 0.0


func _initialize() -> void:
	_go.call_deferred()


## After the first frame, so the tour's beacon is in the tree.
func _go() -> void:
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
	var spots: Array = [["pickup", KinoTour.PICKUP["at"]]]
	for s: Dictionary in KinoTour.STOPS:
		spots.append([s["id"], s["at"]])
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
	for s: Dictionary in KinoTour.STOPS:
		var sz: float = (s["at"] as Vector2).y
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
	var hud := FakeHud.new()
	var dlg := FakeDialogue.new()
	var wal := FakeWallet.new()
	var map := FlatMap.new()
	root.add_child(hud)
	root.add_child(dlg)
	root.add_child(wal)
	root.add_child(map)
	var k := KinoTour.new()
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


func _at(p: Vector2, kmh := 0.0, fwd := 0.0) -> void:
	_pos = Vector3(p.x, 0.0, p.y)
	_kmh = kmh
	_fwd = fwd


func _tour() -> void:
	var parts := _new()
	var k: KinoTour = parts[0]
	var hud: FakeHud = parts[1]
	var wal: FakeWallet = parts[3]
	_at(Vector2(0, 0), 30.0)
	_expect(k.ring() and k.state == KinoTour.State.RING and hud.card.contains("WIKTOR"), "the call rings")
	hud.card_pressed.emit(0)
	_expect(k.state == KinoTour.State.OFFER, "ODBIERZ: the offer")
	hud.card_pressed.emit(0)
	_expect(k.state == KinoTour.State.TO_PICKUP and k.has_target() and k.busy(), "JADĘ: to the pickup")
	_run(k, 1.0)
	_expect(k.state == KinoTour.State.TO_PICKUP, "far from the pickup: still going there")
	_at(KinoTour.PICKUP["at"], 3.0)
	_run(k, 1.5)
	_expect(k.state == KinoTour.State.LEG and k.stop == 0, "stopped at the pickup: Wiktor gets in (state %d)" % k.state)
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
	_expect(k.frames == KinoTour.FRAMES - 1, "one hit, one scratch (%d frames)" % k.frames)
	k.on_bump(null, 1.0)
	_run(k, KinoTour.BUMP_WAIT + 0.2)
	k.on_bump(null, 1.0)
	_expect(k.frames == KinoTour.FRAMES - 1, "a soft touch: no scratch")
	k.on_bump(null, 6.0)
	_expect(k.frames == KinoTour.FRAMES - 2, "a second hit later: a second scratch (%d)" % k.frames)
	# Each cinema: arrive, the pitch card, DRIVE ON.
	for i in KinoTour.STOPS.size():
		var s: Dictionary = KinoTour.STOPS[i]
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
		_at(s["at"], 2.0)
		_run(k, 1.5)
		if i < KinoTour.STOPS.size() - 1:
			_expect(k.state == KinoTour.State.PITCH and hud.card != "", "%s: the pitch card" % s["id"])
			hud.card_pressed.emit(0)
			_expect(k.state == KinoTour.State.LEG and k.stop == i + 1, "%s: DRIVE ON to the next" % s["id"])
	_expect(k.state == KinoTour.State.DONE and hud.card.contains("MURANÓW"), "Muranów: the premiere card")
	var want := KinoTour.PAY_BASE - 2 * KinoTour.PAY_FRAME + 3 * KinoTour.PAY_SHOT
	_expect(wal.money == want, "the pay: %d zł (want %d: two frames lost, three shots)" % [wal.money, want])
	_expect(wal.respect == KinoTour.RESPECT - 2 * KinoTour.RESPECT_FRAME, "the respect: %d" % wal.respect)
	hud.card_pressed.emit(0)
	_expect(k.state == KinoTour.State.IDLE and not k.busy(), "BRAVO: back to idle")
	# The reel never goes below nothing.
	k.start()
	_at(KinoTour.PICKUP["at"], 0.0)
	_run(k, 1.5)
	for n in 8:
		k.on_bump(null, 8.0)
		_run(k, KinoTour.BUMP_WAIT + 0.1)
	_expect(k.frames == 0, "eight hits: the reel at 0 (%d)" % k.frames)
	# The ✕ drops the tour.
	hud.abort_pressed.emit()
	_expect(k.state == KinoTour.State.IDLE and not k.has_target(), "✕: the tour dropped")
