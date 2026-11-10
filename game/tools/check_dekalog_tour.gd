extends SceneTree
## The Kieślowski tour "Dekalog na kółkach" (dekalog_tour.gd, docs/design/dekalog-tour.md). Checks that:
## - the pickup and every stop stand on a drivable road of game/map/centrum.json (ON_ROAD m), each
##   stop within PLACE_MAX m of its real filming place (OpenStreetMap points, mapadekalogu.pl);
## - the call (ODBIERZ, JADĘ) starts the tour, stopping at Centralna takes Claire in, each stop gives
##   its KADR card and DRIVE ON leads to the next, the estate asks her question, either answer ends it
##   with the pay;
## - each leg's shot (quiet, rush, long take, static, the W-Z tunnel) counts only when driven its way;
## - a hit counts once inside BUMP_WAIT, never past HITS_MAX, a soft touch not at all;
## - the pay is PAY_BASE - PAY_HIT a hit + PAY_SHOT a shot, the ✕ drops the tour;
## - every line group the tour speaks (`dekalog_claire` and its tags) has Polish and English lines.
##   godot --headless --path game --script res://tools/check_dekalog_tour.gd

const DekalogTour := preload("res://scripts/dekalog_tour.gd")

const ON_ROAD := 4.0
const PLACE_MAX := 90.0
## The filming places (OpenStreetMap address points and outlines, game x/z): Warszawa Centralna,
## Noakowskiego 12, the church of St Alexander, the University gate (Krakowskie Przedmieście 26/28),
## Krakowskie Przedmieście 13 (the Europejski), 27 (the café) and Inflancka 15, the block facing Dzika 6.
const PLACES := {"pickup": Vector2(-1419.0, 577.0), "noakowskiego": Vector2(-913.0, 1422.0),
		"trzech_krzyzy": Vector2(-111.0, 543.0), "uniwersytet": Vector2(-463.0, -646.0),
		"europejski": Vector2(-610.0, -894.0), "kawiarnia": Vector2(-685.0, -1104.0),
		"osiedle": Vector2(-2429.0, -2227.0)}
## The Inflancka pools (Ośrodek Sportowy Inflancka 8): the last stop sits between them and the estate.
const POOLS := Vector2(-2373.0, -2382.0)
const DRIVE := ["primary", "secondary", "tertiary", "residential", "unclassified", "living_street", "service",
		"primary_link", "secondary_link", "tertiary_link"]
const TAGS := ["hello", "bump", "shot_quiet", "shot_rush", "shot_long", "shot_static", "shot_tunnel"]
const STEP := 0.1


class FakeHud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	var card := ""
	var buttons := 0
	var status := ""
	func show_card(title: String, _b: String, btn: PackedStringArray, _a: Color, _bottom := false, _te := "", _be := "", _s := false) -> void:
		card = title
		buttons = btn.size()
	func show_side_card(title: String, _b: String, btn: PackedStringArray, _a: Color, _te := "", _be := "", _s := false) -> void:
		card = title
		buttons = btn.size()
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


func _initialize() -> void:
	_go.call_deferred()


## After the first frame, so the tour's beacon is in the tree.
func _go() -> void:
	_roads()
	_lines()
	_tour()
	_tunnel()
	if _fails.is_empty():
		print("check_dekalog_tour: OK")
		quit(0)
	else:
		for f in _fails:
			print("check_dekalog_tour: FAIL " + f)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _roads() -> void:
	var spots: Array = [["pickup", DekalogTour.PICKUP["at"]]]
	for s: Dictionary in DekalogTour.STOPS:
		spots.append([s["id"], s["at"]])
		_expect(s["shot"] == "" or DekalogTour.SHOTS.has(s["shot"]), "%s: an unknown shot %s" % [s["id"], s["shot"]])
	for sp: Array in spots:
		_expect(PLACES.has(sp[0]), "%s: no filming place to check against" % sp[0])
		if PLACES.has(sp[0]):
			var dd: float = (sp[1] as Vector2).distance_to(PLACES[sp[0]])
			_expect(dd <= PLACE_MAX, "%s: the stop is %.0f m from its place" % [sp[0], dd])
	var last: Vector2 = DekalogTour.STOPS[-1]["at"]
	_expect(last.distance_to(POOLS) < 120.0, "the estate stop: %.0f m from the Inflancka pools" % last.distance_to(POOLS))
	var text := FileAccess.get_file_as_string("res://map/centrum.json")
	if text == "":
		print("check_dekalog_tour: (no centrum.json, the road test skipped)")
		return
	var data: Dictionary = JSON.parse_string(text)
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
	# The tunnel's portals are the map's own (piece 9, Aleja „Solidarności”).
	var portals: Array = data.get("tunnels", {}).get("portals", [])
	var found := 0
	for pt: Array in portals:
		for t: Vector2 in DekalogTour.TUNNEL:
			if Vector2(float(pt[0]), float(pt[1])).distance_to(t) < 1.0:
				found += 1
	_expect(found == 2, "the W-Z tunnel: %d of 2 portals match centrum.json" % found)


func _lines() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var lines: Array = d.get(DekalogTour.GROUP, [])
	var general := 0
	var tags := {}
	for l: Array in lines:
		_expect(l.size() >= 2 and String(l[0]) != "" and String(l[1]) != "", "a %s line without Polish or English" % DekalogTour.GROUP)
		if l.size() > 2 and l[2] is Dictionary:
			tags[String(l[2].get("only", ""))] = true
		else:
			general += 1
	_expect(general >= 12, "%s: %d general lines (want 12+)" % [DekalogTour.GROUP, general])
	for t: String in TAGS:
		_expect(tags.has(t), "%s: no line for %s" % [DekalogTour.GROUP, t])


func _new() -> Array:
	var hud := FakeHud.new()
	var dlg := FakeDialogue.new()
	var wal := FakeWallet.new()
	var map := FlatMap.new()
	root.add_child(hud)
	root.add_child(dlg)
	root.add_child(wal)
	root.add_child(map)
	var k := DekalogTour.new()
	k.hud = hud
	k.dialogue = dlg
	k.wallet = wal
	k.map = map
	k.vehicle = func() -> Array: return [_pos, _kmh, false, 0.0]
	root.add_child(k)
	k.setup(map)
	k.set_process(false)
	return [k, hud, dlg, wal]


func _run(k: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		k._process(STEP)
		t += STEP


func _at(p: Vector2, kmh := 0.0, y := 0.0) -> void:
	_pos = Vector3(p.x, y, p.y)
	_kmh = kmh


func _arrive(k: DekalogTour, hud: FakeHud, i: int) -> void:
	var s: Dictionary = DekalogTour.STOPS[i]
	_at(s["at"], 2.0)
	_run(k, 1.5)
	if i < DekalogTour.STOPS.size() - 1:
		_expect(k.state == DekalogTour.State.FRAME and hud.card.begins_with("DEKALOG"), "%s: the KADR card (%s)" % [s["id"], hud.card])
		hud.card_pressed.emit(0)
		_expect(k.state == DekalogTour.State.LEG and k.stop == i + 1, "%s: DRIVE ON to the next" % s["id"])


func _tour() -> void:
	var parts := _new()
	var k: DekalogTour = parts[0]
	var hud: FakeHud = parts[1]
	var wal: FakeWallet = parts[3]
	_at(Vector2(0, 0), 30.0)
	_expect(k.ring() and k.state == DekalogTour.State.RING and hud.card.contains("CLAIRE"), "the call rings")
	hud.card_pressed.emit(0)
	_expect(k.state == DekalogTour.State.OFFER, "ODBIERZ: the offer")
	hud.card_pressed.emit(0)
	_expect(k.state == DekalogTour.State.TO_PICKUP and k.has_target() and k.busy(), "JADĘ: to the pickup")
	_run(k, 1.0)
	_expect(k.state == DekalogTour.State.TO_PICKUP, "far from the pickup: still going there")
	_at(DekalogTour.PICKUP["at"], 3.0)
	_run(k, 1.5)
	_expect(k.state == DekalogTour.State.LEG and k.stop == 0, "stopped at Centralna: Claire gets in (state %d)" % k.state)
	# Leg 0, quiet: no hit on the way, the shot on arrival.
	_at(Vector2(-1200, 1000), 30.0)
	_run(k, 20.0)
	_arrive(k, hud, 0)
	_expect(k.shots_done.has("quiet"), "quiet: a leg with no hit")
	# Leg 1, the rush: too slow (RUSH + 5 s) gives no shot.
	_at(Vector2(-500, 1000), 30.0)
	_run(k, DekalogTour.RUSH + 5.0)
	_arrive(k, hud, 1)
	_expect(not k.shots_done.has("rush"), "the rush: not after %.0f s" % (DekalogTour.RUSH + 5.0))
	# Leg 2, the long take: 10 s fast does nothing, 16 s at 20 km/h does it; then two hits.
	_at(Vector2(-300, 0), 70.0)
	_run(k, 10.0)
	_expect(not k.shots_done.has("long"), "the long take: not at 70 km/h")
	_at(Vector2(-300, 0), 20.0)
	_run(k, 16.0)
	_expect(k.shots_done.has("long"), "the long take: 16 s at 20 km/h")
	k.on_bump(null, 6.0)
	k.on_bump(null, 6.0)
	_expect(k.hits == 1, "one hit counted once (%d)" % k.hits)
	_run(k, DekalogTour.BUMP_WAIT + 0.2)
	k.on_bump(null, 1.0)
	_expect(k.hits == 1, "a soft touch: not counted")
	k.on_bump(null, 6.0)
	_expect(k.hits == 2, "a second hit later: counted (%d)" % k.hits)
	_arrive(k, hud, 2)
	# Leg 3, static: 5.5 s standing.
	_at(Vector2(-560, -800), 0.0)
	_run(k, 5.5)
	_expect(k.shots_done.has("static"), "the static shot: 5.5 s standing")
	_arrive(k, hud, 3)
	# Leg 4, no shot; leg 5, the tunnel: over it on the street (y 0) nothing, under it the shot.
	_arrive(k, hud, 4)
	var mid: Vector2 = (DekalogTour.TUNNEL[0] as Vector2).lerp(DekalogTour.TUNNEL[1], 0.5)
	_at(mid, 40.0, 0.0)
	_run(k, 1.0)
	_expect(not k.shots_done.has("tunnel"), "the tunnel: not on the street above it")
	_at(mid, 40.0, -6.0)
	_run(k, 0.5)
	_expect(k.shots_done.has("tunnel"), "the tunnel: under Plac Zamkowy")
	_at(DekalogTour.STOPS[-1]["at"], 2.0)
	_run(k, 1.5)
	_expect(k.state == DekalogTour.State.ASK and hud.buttons == 2, "the estate: her question with two answers")
	hud.card_pressed.emit(1)
	_expect(k.state == DekalogTour.State.DONE and k.answer == 1, "an answer: the end card")
	var want := DekalogTour.PAY_BASE - 2 * DekalogTour.PAY_HIT + 4 * DekalogTour.PAY_SHOT
	_expect(wal.money == want, "the pay: %d zł (want %d: two hits, four shots)" % [wal.money, want])
	_expect(wal.respect == DekalogTour.RESPECT - 2 * DekalogTour.RESPECT_HIT, "the respect: %d" % wal.respect)
	hud.card_pressed.emit(0)
	_expect(k.state == DekalogTour.State.IDLE and not k.busy(), "MERCI: back to idle")
	# Hits never pass HITS_MAX; a hit spoils the quiet leg.
	k.start()
	_at(DekalogTour.PICKUP["at"], 0.0)
	_run(k, 1.5)
	for n in 10:
		k.on_bump(null, 8.0)
		_run(k, DekalogTour.BUMP_WAIT + 0.1)
	_expect(k.hits == DekalogTour.HITS_MAX, "ten hits: capped at %d (%d)" % [DekalogTour.HITS_MAX, k.hits])
	_arrive(k, hud, 0)
	_expect(not k.shots_done.has("quiet"), "quiet: not after a hit")
	# The ✕ drops the tour.
	hud.abort_pressed.emit()
	_expect(k.state == DekalogTour.State.IDLE and not k.has_target(), "✕: the tour dropped")


## The tunnel test against the map's own heights: the street over the tunnel is higher than the road in it.
func _tunnel() -> void:
	var parts := _new()
	var k: DekalogTour = parts[0]
	var mid: Vector2 = (DekalogTour.TUNNEL[0] as Vector2).lerp(DekalogTour.TUNNEL[1], 0.5)
	_expect(not k.in_tunnel(Vector3(DekalogTour.TUNNEL[0].x, -6.0, DekalogTour.TUNNEL[0].y)), "the tunnel: not at the portal's ramp")
	_expect(not k.in_tunnel(Vector3(mid.x + 30.0, -6.0, mid.y + 30.0)), "the tunnel: not beside it")
	_expect(k.in_tunnel(Vector3(mid.x, -6.0, mid.y)), "the tunnel: in its middle")
