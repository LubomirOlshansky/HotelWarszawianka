extends SceneTree
## Loop jobs-2 (docs/design/parodies.md 4.3 and 5.3, vision.md 3.9 T17 and the egg E40): the courier
## race (scripts/courier_race.gd), the Leżak round-up (scripts/roundup_job.gd) and the payphone
## (scripts/storefronts.gd, props.gd), headless; seeded, no clock of its own (every step is a
## synthetic frame):
##   1. the courier race's rules: night only, 1 in 4 by the order's roll (about a quarter of 1,000
##      orders), forced by the flag; the way at most 1.6 × the straight line; +30 zł +30 respect
##      for a win, nothing for a loss;
##   2. the race on a synthetic footway: a straight way is challenged, a detour isn't; the rider
##      rides it at his pace (loop couriers: the road's time at 10 m/s) and gets to the door first
##      (no pay); a race the car wins pays +30 zł +30 respect once; a challenge not taken goes after
##      6 s; loop couriers: the pace on the default route (a decent drive wins about 2 in 3), the
##      challenger one of the couriers waiting at the stand (from his spot; he gets on his bike at
##      ŚCIGAJ), no challenge at night with none waiting, the --courier-v speed kept;
##   3. the round-up's rules: 8 zł a Leżak, +40 zł for all within 6 minutes, +40 respect for all;
##      the pick-up within 4 m under 15 km/h with room in the boot (5); the depots 1,200 m apart,
##      never the standing Leżak's zone;
##   4. the round-up on the real map (map/centrum.json's storefronts): the card, up to ten Leżaks (a
##      full boot of five, the unloads), the pay once; late (over 6 min): no bonus; ✕ pays the unloaded
##      only; the collected Leżaks are off the pavement and back by the morning;
##   5. the payphone: on the pavement within 70 m of Plac Konstytucji, off the lanes, its mesh;
##      E40 fires on a 2 s stop beside it (not at 20 m, not driving), +10 respect once;
##   6. the cost: the race's step and the round-up's idle step a frame;
##   7. the play (the round-up as an activity of the kit, on tools/fakes.gd's stand-ins and a store
##      laid by hand, a frame at a time through its own `_process`): the settings and depots, the
##      look (day, night, not free), the pull-in, the offer (unanswered, NOT NOW, driving off, the
##      keys, another card over it), GO!, the pick-ups, the unload, the result, the late round, the
##      ✕, too few, the morning, --roundup, the autopilot, meet() and the director.
## Prints "check_side_jobs: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_side_jobs.gd [-- --verbose]

const CourierRace := preload("res://scripts/courier_race.gd")
const RoundupJob := preload("res://scripts/roundup_job.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Props := preload("res://scripts/props.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Fakes := preload("res://tools/fakes.gd")

const DT := 1.0 / 60.0


class FakeDialogue extends Node:
	var said: Array = []
	var bubbles: Control = null

	func say(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _k := 0, _key := "") -> Array:
		said.append([speaker, group, tag])
		return ["…", "…"]

	func say_ambient(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false) -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func say_reaction(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _key := "") -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func line(group: String, tag := "", _prefer := false) -> Array:
		said.append(["", group, tag])
		return ["…", "…"]

	func count(group: String, tag: String) -> int:
		var n := 0
		for l: Array in said:
			n += int(l[1] == group and l[2] == tag)
		return n


class FakeHud extends CanvasLayer:
	signal card_pressed(index: int)
	signal abort_pressed
	signal challenge_pressed
	var toasts: Array = []
	var cards: Array = []
	var challenge := false
	var status := ""
	var pois := 0
	var _up := false
	var _owner: Object = null

	func toast(pl: String, en := "") -> void:
		toasts.append([pl, en])

	func show_note(_a: String, _b: String, _c := Color.WHITE) -> void:
		pass

	func show_card(title: String, _body: String, _b: PackedStringArray, _c: Color, _bottom := false, _te := "", _be := "", _s := false) -> void:
		cards.append(title)
		_up = true
		_owner = null

	func hide_card() -> void:
		_up = false
		_owner = null

	func own_card(o: Object) -> void:
		_owner = o

	func card_is(o: Object) -> bool:
		return _up and _owner == o

	func card_showing() -> bool:
		return _up

	func ticker_out() -> void:
		pass

	func show_status(title: String, _clock: String, _d: String, _h: String, _p: float, _c: Color, _badge := "", _i := {}, _he := "") -> void:
		status = title

	func hide_status() -> void:
		status = ""

	func show_challenge(_t: String, _c: Color, _g := "", _s := "", _se := "") -> void:
		challenge = true

	func hide_challenge() -> void:
		challenge = false

	func hide_pill() -> void:
		pass

	func set_minimap_pois(points: PackedVector2Array, _c: PackedColorArray, _s := PackedInt32Array()) -> void:
		pois = points.size()


class FakeMissions extends Node:
	var paused := false
	func close() -> void:
		pass


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
	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


class FakeCar extends CharacterBody3D:
	var vel := Vector3.ZERO
	var forward_speed := 0.0
	var throttle := 0.0
	func flash_lights() -> void:
		pass


## jobs.gd's side the round-up uses.
class FakeJobs extends Node:
	var flying := false
	var free := true
	var dirty := 0
	func _free() -> bool:
		return free
	func own_busy() -> bool:
		return false
	func _marker(_c: Color, _r: float) -> Node3D:
		return Node3D.new()
	func depots_shown(_on: bool) -> void:
		pass
	func places_dirty() -> void:
		dirty += 1


class FakeTod extends Node:
	var mode := 2


## Loop couriers: city_life.gd's side the race uses (the couriers waiting at a stand).
class FakeLife extends Node:
	var waiting: Array = []
	var taken := 0

	func waiting_at(_i: int) -> Array:
		return waiting.duplicate()

	func take_waiting(_i: int) -> Array:
		taken += 1
		var w: Variant = waiting.pop_back()
		return w if w != null else []


var problems: Array[String] = []
var verbose := false
var _summary := {}


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	_check_race_rules()
	await _check_race()
	_check_roundup_rules()
	_play()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var nb: Notebook = Notebook.new()
	root.add_child(nb)
	if not data is Dictionary or not nb.setup(data):
		print("check_side_jobs: PROBLEM (no map/centrum.json or places.json)")
		quit(1)
		return
	var map := FakeMap.new()
	root.add_child(map)
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var eggs: EggBook = EggBook.new()
	eggs.wallet = wallet
	root.add_child(eggs)
	eggs.set_process(false)
	_expect(eggs.load_eggs(), "data/eggs.json doesn't load")
	var graph := LaneGraph.new(data["graph"], map)
	var sf: Storefronts = Storefronts.new()
	sf.map = map
	sf.graph = graph
	sf.wallet = wallet
	sf.egg_book = eggs
	sf.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(sf)
	sf.set_process(false)
	sf.set_physics_process(false)
	sf.setup(data, nb.places)
	_check_roundup(sf, map, wallet)
	_check_payphone(sf, nb, graph, eggs, wallet)
	if problems.is_empty():
		print("check_side_jobs: OK (courier race: %s; round-up: %s; payphone %s; cost: race %s, round-up idle %s; the play: %s)" % [
				_summary.get("race", "?"), _summary.get("roundup", "?"), _summary.get("phone", "?"),
				_summary.get("race_us", "?"), _summary.get("idle_us", "?"), _summary.get("play", "?")])
		quit(0)
	else:
		for p in problems:
			print("  problem: ", p)
		print("check_side_jobs: %d problems" % problems.size())
		quit(1)


# 1. ------------------------------------------------------------------------------------------

func _check_race_rules() -> void:
	_expect(not CourierRace.challenges(false, 0.1), "a challenge by day")
	_expect(CourierRace.challenges(true, 0.1) and not CourierRace.challenges(true, 0.3), "the night's 1 in 4: 0.1 yes, 0.3 no")
	_expect(CourierRace.challenges(false, 0.9, true), "--courier-race doesn't force the challenge")
	var n := 0
	for k in 1000:
		n += int(CourierRace.challenges(true, CourierRace.roll(k)))
		_expect(CourierRace.roll(k) == CourierRace.roll(k), "order %d rolls twice differently" % k)
	_expect(n >= 200 and n <= 300, "%d of 1,000 night orders challenged (want about 250)" % n)
	_expect(CourierRace.fits(160.0, 100.0) and not CourierRace.fits(161.0, 100.0) and not CourierRace.fits(0.0, 100.0),
			"the 1.6 × detour rule")
	var w := CourierRace.result(true)
	var l := CourierRace.result(false)
	_expect(int(w["zl"]) == 30 and int(w["respect"]) == 30 and str(w["line"]) == "lose", "a win: %s" % [w])
	_expect(int(l["zl"]) == 0 and int(l["respect"]) == 0 and str(l["line"]) == "win", "a loss: %s" % [l])
	# Loop couriers: the pace. The default route (stand 0 to Oboźna 1, BACKLOG "From loop jobs-2"):
	# his way 1,013 m, the road 1,023 m: about 9.9 m/s, 102 s; a decent drive wins about 2 in 3.
	var v0 := CourierRace.pace(1013.0, 1023.0)
	var share := CourierRace.decent_wins(1013.0, 1023.0, v0)
	_expect(absf(v0 - 9.9) < 0.05 and absf(share - 2.0 / 3.0) < 0.02, "the default route's pace %.2f m/s, a decent drive wins %.2f (want 9.9, 0.67)" % [v0, share])
	_expect(CourierRace.decent_wins(1013.0, 1023.0, CourierRace.V) > 0.95, "at the old 6.5 m/s a decent drive should nearly always win")
	_expect(CourierRace.pace(400.0, 1600.0) == CourierRace.V_MIN and CourierRace.pace(1500.0, 1000.0) == CourierRace.V_MAX
			and CourierRace.pace(0.0, 100.0) == CourierRace.V, "the pace's bounds")
	# Over routes from 0.75 × to 1.1 × the road the share stays about 2 in 3 (the pace's point).
	for k in 8:
		var path := 1000.0 * (0.75 + 0.05 * k)
		var sh := CourierRace.decent_wins(path, 1000.0, CourierRace.pace(path, 1000.0))
		_expect(absf(sh - 2.0 / 3.0) < 0.02, "a way %.0f m against 1,000 m by road: a decent drive wins %.2f" % [path, sh])
	_summary["race"] = "%d of 1,000 night orders; the default route at %.1f m/s, a decent drive wins %.0f %%" % [n, v0, share * 100.0]


# 2. ------------------------------------------------------------------------------------------

## A footway as the map data has it.
static func _path(pts: Array, k := "foot") -> Dictionary:
	var flat: Array = []
	for p: Vector2 in pts:
		flat.append(p.x)
		flat.append(p.y)
	return {"k": k, "dk": -1, "p": flat}


func _check_race() -> void:
	var hud := FakeHud.new()
	root.add_child(hud)
	var dlg := FakeDialogue.new()
	root.add_child(dlg)
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var map := FakeMap.new()
	root.add_child(map)
	var car := FakeCar.new()
	root.add_child(car)
	var world := Node3D.new()
	root.add_child(world)
	var cr: CourierRace = CourierRace.new()
	cr.hud = hud
	cr.dialogue = dlg
	cr.wallet = wallet
	cr.map = map
	cr.car = car
	root.add_child(cr)
	cr.setup(world)
	# A straight footway 5 m off the road, a crossing at each end; and a detour 3 × as long.
	var straight := [_path([Vector2(0, 5), Vector2(100, 5), Vector2(200, 5), Vector2(300, 5)]),
			_path([Vector2(0, 0), Vector2(0, 5)], "zebra"), _path([Vector2(300, 5), Vector2(300, 0)], "zebra")]
	var detour := [_path([Vector2(0, 5), Vector2(0, 305), Vector2(300, 305), Vector2(300, 5)])]
	var r := CourierRace.route(straight, Vector2(0, 0), Vector2(300, 0))
	_expect(not r.is_empty() and absf(float(r["len"]) - 310.0) < 2.0, "the straight way: %s m (want 310)" % [r.get("len", "none")])
	var went := [0]
	var go := func() -> void: went[0] += 1
	# The detour: no challenge (forced, so the roll doesn't matter).
	cr.force = true
	cr.paths = detour
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 1, true, -1, 0.0, go)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	_expect(cr.state == CourierRace.State.IDLE and not hud.challenge, "a 3 × detour was challenged")
	# By day, unforced: nothing.
	cr.force = false
	cr.paths = straight
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 0, false, -1, 0.0, go)
	_expect(cr.state == CourierRace.State.IDLE, "a challenge by day")
	cr.force = true
	# The straight way: the challenge, accepted; the rider at the door first.
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 2, true, -1, 0.0, go)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	cr.step(DT)
	_expect(cr.state == CourierRace.State.OFFER and hud.challenge and dlg.count("pedzik", "challenge") == 1, "the straight way wasn't challenged")
	car.global_position = Vector3(0, 0, 0)
	cr.set_road(320.0)
	_expect(cr.accept() and cr.racing() and went[0] == 1 and not hud.challenge, "ŚCIGAJ didn't start the race and the delivery")
	_expect(not cr.accept(), "a second ŚCIGAJ")
	var frames := 0
	var t0 := Time.get_ticks_usec()
	while not cr.rider_first and frames < 60 * 120:
		cr.step(DT)
		frames += 1
	var race_us := float(Time.get_ticks_usec() - t0) / maxf(frames, 1.0)
	var secs := frames * DT
	var want_s := 310.0 / CourierRace.pace(310.0, 320.0)
	_expect(absf(cr.speed - CourierRace.pace(310.0, 320.0)) < 0.01, "the rider's speed %.2f m/s (want the pace %.2f)" % [cr.speed, CourierRace.pace(310.0, 320.0)])
	_expect(cr.rider_first and absf(secs - want_s) < 1.0, "the rider took %.1f s for 310 m (want %.1f)" % [secs, want_s])
	_expect(cr.badge() == "2ND" and dlg.count("pedzik", "win") == 1, "the rider first: badge %s, %d win lines" % [cr.badge(), dlg.count("pedzik", "win")])
	var zl := wallet.zl
	var rs := wallet.respect
	var res := cr.finish()
	_expect(not res.is_empty() and not bool(res["won"]) and wallet.zl == zl and wallet.respect == rs, "a lost race paid: %s" % [res])
	# The car first: +30 zł +30 respect, once.
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 3, true, -1, 0.0, go)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	hud.challenge_pressed.emit()
	_expect(cr.racing(), "the ŚCIGAJ button didn't start the race")
	for k in 600:
		cr.step(DT)
	car.global_position = Vector3(300, 0, 0)
	for k in 12:
		cr.step(DT)
	_expect(cr.badge() == "1ST", "the car at the door, the rider 10 s in: badge %s" % cr.badge())
	res = cr.finish()
	_expect(bool(res.get("won", false)) and wallet.zl - zl == 30 and wallet.respect - rs == 30, "a won race paid %d zł, %d respect (want 30, 30)" % [
			wallet.zl - zl, wallet.respect - rs])
	_expect(cr.finish().is_empty() and wallet.zl - zl == 30, "a race paid twice")
	_expect(dlg.count("pedzik", "lose") == 1, "the rider's lose line: %d" % dlg.count("pedzik", "lose"))
	# A challenge not taken: gone after 6 s.
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 4, true, -1, 0.0, go)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	for k in roundi((CourierRace.OFFER_S + 0.2) * 60.0):
		cr.step(DT)
	_expect(cr.state == CourierRace.State.IDLE and not hud.challenge and not cr.accept(), "the challenge stayed past 6 s")
	# Loop couriers: the challenger is a courier waiting at the stand. Unforced at night, none waiting:
	# no challenge.
	var life := FakeLife.new()
	root.add_child(life)
	cr.life = life
	cr.force = false
	var night_n := 0
	while not CourierRace.challenges(true, CourierRace.roll(night_n)):
		night_n += 1
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), night_n, true, -1, 0.0, go, 7)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	_expect(cr.state == CourierRace.State.IDLE and not hud.challenge, "a challenge with no courier waiting at the stand")
	# Two waiting: the challenge from the last one's spot; he stands (the race's rider hidden) until ŚCIGAJ.
	var spot := Vector3(2.0, 0.0, -3.0)
	life.waiting = [[Vector3(-2.0, 0.0, -3.0), 0.0], [spot, 0.0]]
	var said0 := dlg.count("pedzik", "challenge")
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), night_n, true, -1, 0.0, go, 7)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	cr.step(DT)
	var rider: MeshInstance3D = cr.get("_rider")
	_expect(cr.state == CourierRace.State.OFFER and dlg.count("pedzik", "challenge") == said0 + 1 and not rider.visible
			and rider.global_position.distance_to(spot) < 0.01, "the waiting courier's challenge: state %d, rider shown %s at %s" % [
			cr.state, rider.visible, rider.global_position])
	_expect(life.taken == 0, "a courier taken before ŚCIGAJ")
	cr.set_road(320.0)
	_expect(cr.accept() and life.taken == 1 and rider.visible and rider.global_position.distance_to(spot) < 0.01,
			"ŚCIGAJ: the waiting courier didn't get on his bike at his spot (taken %d, shown %s, at %s)" % [life.taken, rider.visible, rider.global_position])
	_expect(absf(cr.path_len - (310.0 + spot.distance_to(Vector3.ZERO))) < 2.5, "his way from his spot: %.0f m" % cr.path_len)
	cr.cancel()
	# Not taken: he stays waiting (nothing taken), the offer goes after 6 s.
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), night_n, true, -1, 0.0, go, 7)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	for k in roundi((CourierRace.OFFER_S + 0.2) * 60.0):
		cr.step(DT)
	_expect(cr.state == CourierRace.State.IDLE and life.taken == 1 and not rider.visible, "an offer not taken took a courier or showed the rider")
	# --courier-v keeps its speed.
	cr.force = true
	cr.fixed_speed = true
	cr.speed = 3.0
	cr.on_order(Vector3(0, 0, 0), Vector3(300, 0, 0), 5, true, -1, 0.0, go, 7)
	await _until(cr, func() -> bool: return cr.state != CourierRace.State.ROUTING)
	cr.set_road(320.0)
	_expect(cr.accept() and cr.speed == 3.0, "--courier-v's speed changed to %.2f" % cr.speed)
	cr.cancel()
	cr.life = null
	life.queue_free()
	_summary["race_us"] = "%.1f µs a frame" % race_us
	_summary["race"] = "%s; the 310 m way in %.1f s, a win +30/+30 once" % [_summary.get("race", "?"), secs]
	cr.queue_free()
	world.queue_free()
	await process_frame


## Steps `cr` frame by frame until `cond` holds (the worker's A*: waited for by its condition).
func _until(cr: Node, cond: Callable) -> void:
	var n := 0
	while not cond.call() and n < 600:
		await process_frame
		cr.step(DT)
		n += 1
	_expect(cond.call(), "the courier's way never came (%d frames)" % n)


# 3. ------------------------------------------------------------------------------------------

func _check_roundup_rules() -> void:
	var a := RoundupJob.pay(10, 10, 300.0)
	var b := RoundupJob.pay(10, 10, 400.0)
	var c := RoundupJob.pay(6, 10, 100.0)
	_expect(int(a["zl"]) == 120 and int(a["bonus"]) == 40 and int(a["respect"]) == 40, "all 10 in 5 min: %s" % [a])
	_expect(int(b["zl"]) == 80 and int(b["bonus"]) == 0 and int(b["respect"]) == 40, "all 10 in 6:40: %s" % [b])
	_expect(int(c["zl"]) == 48 and int(c["respect"]) == 0, "6 of 10: %s" % [c])
	_expect(RoundupJob.can_pick(3.9, 14.0, 4) and not RoundupJob.can_pick(4.1, 5.0, 0) and not RoundupJob.can_pick(2.0, 15.0, 0) \
			and not RoundupJob.can_pick(1.0, 5.0, 5), "the pick-up rule (4 m, 15 km/h, a boot of 5)")


# 4. ------------------------------------------------------------------------------------------

func _check_roundup(sf: Storefronts, map: FakeMap, wallet: Wallet) -> void:
	var deps := RoundupJob.pick_depots(sf.zones, RoundupJob.DEPOT_SPACING)
	_expect(deps.size() >= 2, "%d Leżak depots" % deps.size())
	for i in deps:
		_expect(not bool(sf.zones[i]["standing"]), "the standing Leżak's zone is a depot")
		for j in deps:
			if i < j:
				var d: float = (sf.zones[i]["at"] as Vector3).distance_to(sf.zones[j]["at"])
				_expect(d >= RoundupJob.DEPOT_SPACING, "depots %d and %d %.0f m apart" % [i, j, d])
	var hud := FakeHud.new()
	root.add_child(hud)
	var dlg := FakeDialogue.new()
	root.add_child(dlg)
	var car := FakeCar.new()
	root.add_child(car)
	var jobs := FakeJobs.new()
	root.add_child(jobs)
	var tod := FakeTod.new()
	root.add_child(tod)
	var world := Node3D.new()
	root.add_child(world)
	var ru: RoundupJob = RoundupJob.new()
	ru.hud = hud
	ru.dialogue = dlg
	ru.wallet = wallet
	ru.missions = FakeMissions.new()
	root.add_child(ru.missions)
	ru.map = map
	ru.car = car
	ru.tod = tod
	ru.jobs = jobs
	ru.store = sf
	ru.free_now = func() -> bool: return jobs._free() and not jobs.own_busy()
	root.add_child(ru)
	ru.set_process(false)
	ru.setup(world)
	_expect(ru.depots.size() == deps.size(), "%d depots set up (want %d)" % [ru.depots.size(), deps.size()])
	# The idle step's cost far from the depots.
	car.global_position = Vector3(9000, 0, 9000)
	var t0 := Time.get_ticks_usec()
	for k in 3000:
		ru._process(DT)
	_summary["idle_us"] = "%.2f µs a frame" % (float(Time.get_ticks_usec() - t0) / 3000.0)
	# Into depot 0's ring at night: the card; GO.
	var dep: Vector3 = ru.depots[0]["at"]
	car.global_position = dep
	for k in 40:
		ru._process(DT)
	_expect(ru.stage == RoundupJob.Stage.OFFER and hud.cards.size() == 1 and dlg.count("lezak", "start") == 1, "no card at the depot")
	var want := ru.targets.size()
	var picked: Array[int] = ru.targets.duplicate()
	_expect(want >= RoundupJob.AT_LEAST and want <= RoundupJob.WANT, "%d Leżaks to round up at depot 0 (want 4-10)" % want)
	_expect(ru.primary() and ru.stage == RoundupJob.Stage.COLLECT and hud.pois == want + 1, "GO didn't start it (pins %d)" % hud.pois)
	var zl := wallet.zl
	var rs := wallet.respect
	var loads := _drive_round(ru, car, dep, 0.0)
	_expect(ru.stage == RoundupJob.Stage.RESULT and loads >= 2 and _max_boot == RoundupJob.BOOT, "the round-up: state %d after %d loads, the boot at most %d (want the card, a full boot of 5)" % [
			ru.stage, loads, _max_boot])
	_expect(wallet.zl - zl == want * 8 + 40 and wallet.respect - rs == 40, "paid %d zł, %d respect (want %d, 40)" % [wallet.zl - zl,
			wallet.respect - rs, want * 8 + 40])
	_expect(dlg.count("lezak", "done") == 1, "the done line: %d" % dlg.count("lezak", "done"))
	for k in 60:
		ru._process(DT)
	_expect(wallet.zl - zl == want * 8 + 40, "the round-up paid twice")
	var gone := 0
	for i in picked:
		gone += int(sf.scooters[i].get("gone", false))
	_expect(gone == want and sf.lying_near(Vector2(dep.x, dep.z), RoundupJob.REACH, 50).all(func(i: int) -> bool: return not i in picked),
			"%d of %d collected Leżaks off the pavement" % [gone, want])
	ru.primary()
	_expect(ru.idle() and jobs.dirty == 1, "OK didn't close the card")
	# The morning: they lie about again.
	tod.mode = 0
	for k in 40:
		ru._process(DT)
	var back := 0
	for i in picked:
		back += int(not sf.scooters[i].get("gone", false))
	_expect(back == want, "%d of %d Leżaks back by the morning" % [back, want])
	# Late: 6:40 for the lot, no bonus.
	tod.mode = 2
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru._process(DT)
	car.global_position = dep
	for k in 40:
		ru._process(DT)
	_expect(ru.stage == RoundupJob.Stage.OFFER, "no second card")
	ru.primary()
	zl = wallet.zl
	rs = wallet.respect
	_drive_round(ru, car, dep, 400.0)
	_expect(wallet.zl - zl == ru.unloaded * 8 and int(ru.last_pay.get("bonus", -1)) == 0 and wallet.respect - rs == 40,
			"late: paid %d zł (want %d, no bonus)" % [wallet.zl - zl, ru.unloaded * 8])
	ru.primary()
	tod.mode = 0
	for k in 40:
		ru._process(DT)
	# ✕ after one load: the unloaded paid, no bonus, no respect.
	tod.mode = 2
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru._process(DT)
	car.global_position = dep
	for k in 40:
		ru._process(DT)
	ru.primary()
	zl = wallet.zl
	rs = wallet.respect
	_drive_round(ru, car, dep, 0.0, 1)
	var unl := ru.unloaded
	hud.abort_pressed.emit()
	_expect(ru.idle() and wallet.zl - zl == unl * 8 and wallet.respect == rs and unl > 0,
			"✕ after %d unloaded paid %d zł, %d respect" % [unl, wallet.zl - zl, wallet.respect - rs])
	# Nothing in the day.
	tod.mode = 0
	for k in 40:
		ru._process(DT)
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru._process(DT)
	car.global_position = dep
	for k in 40:
		ru._process(DT)
	_expect(ru.idle(), "a round-up card by day")
	_summary["roundup"] = "%d depots, %d Leżaks in %d unloads (a full boot of 5) +%d zł +40 respect once, late no bonus, ✕ pays %d unloaded, back by morning" % [
			deps.size(), want, loads, want * 8 + 40, unl]


## The car to each Leżak in turn (stopped), then the depot when the boot is full or none are left;
## `extra` s added to the clock before the last unload; stops after `max_loads` unloads (0: all).
## Returns the unloads.
var _max_boot := 0


func _drive_round(ru: RoundupJob, car: FakeCar, dep: Vector3, extra: float, max_loads := 0) -> int:
	var loads := 0
	_max_boot = 0
	var guard := 0
	car.vel = Vector3.ZERO
	while ru.stage == RoundupJob.Stage.COLLECT and guard < 200:
		guard += 1
		var to: Vector3 = ru.target_position()
		car.global_position = to + Vector3(1.0, 0, 0)
		var before := ru.unloaded
		if to.distance_to(dep) < 0.01 and ru.targets.is_empty():
			ru.secs += extra
		for k in 3:
			ru._process(DT)
			_max_boot = maxi(_max_boot, ru.boot)
		if ru.unloaded > before:
			loads += 1
			if max_loads > 0 and loads >= max_loads:
				break
	return loads


# 5. ------------------------------------------------------------------------------------------

func _check_payphone(sf: Storefronts, nb: Notebook, graph: LaneGraph, eggs: EggBook, wallet: Wallet) -> void:
	_expect(not sf.payphone.is_empty(), "no payphone placed")
	if sf.payphone.is_empty():
		return
	var at: Vector3 = sf.payphone["at"]
	var p := Vector2(at.x, at.z)
	var place := Vector2.INF
	for pl: Dictionary in nb.places:
		if str(pl["id"]) == Storefronts.PHONE_PLACE:
			place = pl["at"]
	_expect(place != Vector2.INF and p.distance_to(place) <= Storefronts.PHONE_REACH, "the payphone %.0f m from Plac Konstytucji" % p.distance_to(place))
	_expect(graph.snap(p, 2.0).is_empty(), "the payphone on a lane")
	for m in sf.metros:
		_expect(Vector2(m["at"].x, m["at"].z).distance_to(p) >= 8.0, "the payphone in a metro entrance")
	var m := SurfaceTool.new()
	m.begin(Mesh.PRIMITIVE_TRIANGLES)
	Props.add_payphone(m, Transform3D.IDENTITY)
	var mesh := m.commit()
	var tris := mesh.surface_get_array_len(0) / 3
	_expect(tris <= 150, "the payphone: %d triangles" % tris)
	# E40: moved to the payphone; a 2 s stop beside it, not 20 m off, not driving by; +10 once.
	var e: Dictionary = eggs.eggs[eggs.by_id["e40"]]
	_expect(not e.has("waits") and (e["at"] as Vector2).distance_to(p) < 0.01, "E40 isn't at the payphone (%s)" % [e.get("at", "none")])
	var mem := {}
	var fired := false
	for k in 5:
		fired = EggBook.step(e, {"pos": at + Vector3(4.0, 0, 0), "kmh": 0.0, "hour": 14.0, "weekday": 3}, mem, 0.5) or fired
	_expect(fired, "E40 didn't fire on a 2.5 s stop 4 m from the payphone")
	var mem2 := {}
	var bad := false
	for k in 10:
		bad = EggBook.step(e, {"pos": at + Vector3(20.0, 0, 0), "kmh": 0.0, "hour": 14.0, "weekday": 3}, mem2, 0.5) or bad
		bad = EggBook.step(e, {"pos": at + Vector3(3.0, 0, 0), "kmh": 30.0, "hour": 14.0, "weekday": 3}, mem2, 0.5) or bad
	_expect(not bad, "E40 fired 20 m off or driving by")
	var rb := wallet.respect
	_expect(eggs.record("e40") and not eggs.record("e40") and wallet.respect - rb == 10, "E40 paid %d (want 10, once)" % (wallet.respect - rb))
	_summary["phone"] = "%.0f m from the place, %d triangles, E40 +10 once" % [p.distance_to(place), tris]


# 7. the play ---------------------------------------------------------------------------------
# The round-up as an activity of the kit, on stand-ins (tools/fakes.gd, the two below) and a store
# laid by hand; a frame at a time through its own `_process`. No map data, no await.

## jobs.gd's side, counting what the round-up asks of it.
class PlayJobs extends Node:
	var flying := false
	var free := true
	var own := false
	## How often `_free()` was asked.
	var asks := 0
	## Every `depots_shown(on)`.
	var shown: Array[bool] = []
	var dirty := 0
	## Every `_marker(colour, radius)` as [colour, radius].
	var markers: Array = []

	func _free() -> bool:
		asks += 1
		return free

	func own_busy() -> bool:
		return own

	func _marker(c: Color, r: float) -> Node3D:
		markers.append([c, r])
		return Node3D.new()

	func depots_shown(on: bool) -> void:
		shown.append(on)

	func places_dirty() -> void:
		dirty += 1


## storefronts.gd's side: the zones and the Leżaks, `lying_near` as storefronts.gd has it.
class PlayStore extends Node:
	var zones: Array[Dictionary] = []
	var scooters: Array[Dictionary] = []
	var collected: Array[int] = []
	var restored: Array[int] = []

	func lying_near(p: Vector2, reach: float, n: int) -> Array[int]:
		var near: Array = []
		for i in scooters.size():
			var s := scooters[i]
			if s["up"] or s.get("gone", false):
				continue
			var d := Vector2(s["at"].x, s["at"].z).distance_to(p)
			if d <= reach:
				near.append([d, i])
		near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var out: Array[int] = []
		for k in mini(n, near.size()):
			out.append(int(near[k][1]))
		return out

	func collect(i: int) -> void:
		var s := scooters[i]
		if s.get("gone", false):
			return
		s["gone"] = true
		collected.append(i)

	func restore_collected() -> int:
		var n := 0
		for s in scooters:
			if s.get("gone", false):
				n += 1
				s.erase("gone")
		restored.append(n)
		return n


const PA := Vector2(100, -50)
const PB := Vector2(1600, -50)
const PC := Vector2(100, 2550)
const PD := Vector2(1600, 2550)
const FAR := Vector3(900, 0, 900)

var _plays := 0
var _rig_root: Node
var _hud: Fakes.Hud
var _dlg: Fakes.Dialogue
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _car: Fakes.Car
var _tod: FakeTod
var _pj: PlayJobs
var _ps: PlayStore
var _world: Node3D
var _ru: RoundupJob
var _dir: Activities
var _other: Activity
## The most in the boot at once while `_drive` ran.
var _peak := 0


func _ok(cond: bool, what: String) -> void:
	_plays += 1
	if not cond:
		problems.append("the play: " + what)


func _v3(v: Vector2) -> Vector3:
	return Vector3(v.x, 0.0, v.y)


## A fresh rig: the round-up on the hand-laid store (or with no zones), the director, a second
## empty activity, night (or day).
func _rig(zones := true, night := true) -> void:
	if _rig_root != null:
		_rig_root.queue_free()
	_rig_root = Node.new()
	root.add_child(_rig_root)
	_hud = Fakes.Hud.new()
	_dlg = Fakes.Dialogue.new()
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	_car = Fakes.Car.new()
	_tod = FakeTod.new()
	_pj = PlayJobs.new()
	_ps = PlayStore.new()
	_world = Node3D.new()
	var map := Fakes.FlatMap.new()
	for n: Node in [_hud, _dlg, _wallet, _calls, _car, _tod, _pj, _ps, _world, map]:
		_rig_root.add_child(n)
	_car.global_position = FAR
	_tod.mode = 2 if night else 0
	if zones:
		_lay_store()
	_ru = RoundupJob.new()
	_ru.hud = _hud
	_ru.dialogue = _dlg
	_ru.wallet = _wallet
	_ru.missions = _calls
	_ru.map = map
	_ru.car = _car
	_ru.tod = _tod
	_ru.jobs = _pj
	_ru.store = _ps
	_rig_root.add_child(_ru)
	_ru.set_process(false)
	_ru.setup(_world)
	_dir = Activities.new()
	_dir.add(_ru, func() -> bool: return _pj._free() and not _pj.own_busy())
	_other = Activity.new()
	_other.hud = _hud
	_other.dialogue = _dlg
	_other.wallet = _wallet
	_other.map = map
	_other.car = _car
	_rig_root.add_child(_other)
	_other.set_process(false)
	_other.setup(_world)
	_dir.add(_other)


## The zones and the Leżaks: A (14 round it, two standing, two out of reach), B (three), C (six), D (none).
func _lay_store() -> void:
	var zs: Array[Vector2] = [PA, Vector2(400, 150), Vector2(2100, -50), PB, PC, PD]
	for k in zs.size():
		_ps.zones.append({"at": _v3(zs[k]), "standing": k == 2})
	var spots: Array[Vector2] = []
	for k in 14:
		spots.append(PA + Vector2(cos(0.7 * k), sin(0.7 * k)) * (30.0 + 18.0 * k))
	spots[1] = spots[0]
	spots.append(PA + Vector2(0, 20))
	spots.append(PA + Vector2(0, -25))
	spots.append(PA + Vector2(640, 0))
	spots.append(PA + Vector2(0, 700))
	spots.append(PB + Vector2(50, 0))
	spots.append(PB + Vector2(0, 100))
	spots.append(PB + Vector2(-150, 0))
	for j in 6:
		spots.append(PC + Vector2(cos(1.1 * j), sin(1.1 * j)) * (40.0 + 40.0 * j))
	for k in spots.size():
		_ps.scooters.append({"at": _v3(spots[k]), "up": k == 14 or k == 15, "key": Vector2i.ZERO})


func _frames(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_ru._process(DT)


func _put(at: Vector3, speed := 0.0) -> void:
	_car.global_position = at
	_car.vel = Vector3(0, 0, speed)


func _dep(i: int) -> Vector3:
	return _ru.depots[i]["at"]


func _lez(k: int) -> Vector3:
	return _ps.scooters[k]["at"]


## The car `d` m from depot i's centre.
func _near(i: int, d: float, speed := 0.0) -> void:
	_put(_dep(i) + Vector3(d, 0, 0), speed)


func _is(stage: int) -> bool:
	return _ru.phase == Activity.Phase.RUN and _ru.stage == stage


## Pulls into depot i's ring and waits (at most `within` s) for the offer.
func _pull(i := 0, within := 0.7) -> bool:
	_near(i, 3.0)
	for f in roundi(within / DT):
		_ru._process(DT)
		if _is(RoundupJob.Stage.OFFER):
			return true
	return false


## Out to 30 m for a look, then back in.
func _reenter(i := 0) -> bool:
	_near(i, 30.0)
	_frames(0.6)
	return _pull(i)


## Into the ring and GO!
func _start_round(i := 0) -> bool:
	var up := _pull(i)
	_ok(up, "no offer at depot %d" % i)
	if not up:
		return false
	_hud.press(0)
	return _is(RoundupJob.Stage.COLLECT)


func _mmss(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Drives the collecting by the rules (12 m/s, 3 m/s for the last 12 m, stands within 0.3 m of the
## target) until `stop` says so; running out of `limit` s is a failed check.
func _drive(stop: Callable, limit: float, what: String) -> bool:
	for f in roundi(limit / DT):
		if bool(stop.call()):
			return true
		if _ru.has_target():
			var to := _ru.target_position() - _car.global_position
			to.y = 0.0
			var d := to.length()
			if d <= 0.3:
				_car.vel = Vector3.ZERO
			else:
				var v := 3.0 if d <= 12.0 else 12.0
				_car.global_position += to / d * minf(d, v * DT)
				_car.vel = to / d * v
		_ru._process(DT)
		_peak = maxi(_peak, _ru.boot)
	var done := bool(stop.call())
	_ok(done, what)
	return done


## The autopilot's car, as main.gd's `_slide_car`.
func _slide() -> void:
	if not _ru.has_target():
		return
	var to := _ru.target_position() - _car.global_position
	to.y = 0.0
	var d := to.length()
	_car.vel = Vector3.ZERO
	if d > 0.5:
		_car.global_position += to / d * minf(d, 22.0 * DT)


func _play() -> void:
	_p_settings()
	_p_look()
	_p_pull_in()
	_p_offer()
	_p_round()
	_p_late()
	_p_abort()
	_p_too_few()
	_p_morning()
	_p_force()
	_p_autopilot()
	_p_meet()
	_p_director()
	_rig_root.queue_free()
	_summary["play"] = "%d checks" % _plays


func _p_settings() -> void:
	_rig()
	_ok(_ru.tag == "roundup", "tag")
	_ok(_ru.colour == RoundupJob.COLOUR and _ru.dark == Color("#2f6fb5"), "colour and dark")
	_ok(_ru.is_job and _ru.cards_low and not _ru.flown, "a job, cards low, not flown")
	_ok(_ru.grounded().is_empty() and _ru._auto_button() == 0 and _ru.target_arrow(), "grounded, auto button, arrow")
	_ok(_ru.target_label(140) == "140 m", "the arrow's words")
	_ok(_ru.idle() and not _ru.busy() and not _ru.has_target(), "idle, not busy, no target")
	_ok(_ru.depots.size() == 4, "%d depots (want 4)" % _ru.depots.size())
	var zs := [0, 3, 4, 5]
	var pts := PackedVector2Array()
	for k in mini(4, _ru.depots.size()):
		var d: Dictionary = _ru.depots[k]
		_ok(int(d["zone"]) == zs[k] and d["at"] == _ps.zones[zs[k]]["at"], "depot %d is zone %d at its place" % [k, zs[k]])
		_ok(not d["cool"] and not (d["marker"] as Node3D).visible and (d["marker"] as Node3D).get_parent() == _world, "depot %d: not cool, marker hidden under the world" % k)
		pts.append(Vector2(d["at"].x, d["at"].z))
	_ok(_pj.markers.size() == 4 and _pj.markers.all(func(m: Array) -> bool: return m[0] == RoundupJob.COLOUR and m[1] == RoundupJob.DEPOT_R - 1.0),
			"four markers in COLOUR at DEPOT_R - 1")
	_ok(_ru.depot_points() == pts, "depot_points are the four places")
	# No zones: no depots, no questions, no start.
	_rig(false)
	_ok(_ru.depots.is_empty(), "a store with no zones has no depots")
	_frames(3.0)
	_ok(_pj.asks == 0, "3 s of night with no depots asked jobs %d times" % _pj.asks)
	_ok(not _ru.start_at_nearest(), "start_at_nearest with no depots")


func _p_look() -> void:
	_rig(true, false)
	_frames(1.0)
	_ok(not _ru._shown and _pj.shown.is_empty() and _pj.asks == 0, "by day: rings hidden, nobody asked (%d)" % _pj.asks)
	_rig()
	_frames(DT)
	_ok(_pj.shown.size() == 1 and _pj.shown[0], "by night the rings show within a frame")
	_ok(_ru.depots.all(func(d: Dictionary) -> bool: return (d["marker"] as Node3D).visible), "every ring visible")
	var a0 := _pj.asks
	_frames(3.0)
	_ok(_pj.asks - a0 >= 5 and _pj.asks - a0 <= 7, "3 s of night: %d looks (want 5-7, every LOOK_EVERY)" % (_pj.asks - a0))
	for how in 3:
		match how:
			0:
				_pj.free = false
			1:
				_pj.own = true
			2:
				_other.start()
		_near(0, 3.0)
		_frames(0.6)
		var what: String = ["jobs not free", "jobs' own job on", "another activity on"][how]
		_ok(not _pj.shown.back(), "%s: the rings hide" % what)
		_ok(_ru.idle() and _hud.card == "", "%s: no card in the ring" % what)
		if how == 2:
			_ok(not _dir.may_start(_ru), "the director refuses the round-up while another is on")
		_put(FAR)
		_pj.free = true
		_pj.own = false
		if how == 2:
			_other.finish()
		_frames(0.6)
		_ok(_pj.shown.back(), "%s over: the rings are back" % what)


func _p_pull_in() -> void:
	_rig()
	_near(0, 7.5)
	_frames(1.0)
	_ok(_ru.idle() and _hud.card == "", "7.5 m from the depot: no card")
	_near(0, 6.5, 9.0)
	_frames(1.0)
	_ok(_ru.idle() and _hud.card == "", "6.5 m at 9 m/s: no card")
	_near(0, 6.5, 7.9)
	_frames(0.6)
	_ok(_is(RoundupJob.Stage.OFFER), "6.5 m at 7.9 m/s: the card")


func _p_offer() -> void:
	_rig()
	var pills := _hud.pills_hidden
	var challenges := _hud.challenges_hidden
	_ok(_pull(0), "the offer at depot 0")
	var A := _dep(0)
	_ok(_is(RoundupJob.Stage.OFFER) and _ru.busy(), "phase RUN, stage OFFER, busy")
	_ok(_dir.current() == _ru and _dir.busy_tag() == "roundup" and not _dir.may_start(_other), "the director sees it")
	_ok(_hud.card == "ZBIERZ 10 LEŻAKÓW" and _hud.card_en == "Round up 10 Leżaks", "offer title: %s / %s" % [_hud.card, _hud.card_en])
	_ok(_hud.body == "Bagażnik mieści 5. 8 zł za sztukę, +40 zł za komplet w 6 min.", "offer body")
	_ok(_hud.body_en == "The boot holds 5. 8 zł each, +40 zł for all of them within 6 min.", "offer body, English")
	_ok(_hud.buttons == 2 and _hud.accent == RoundupJob.COLOUR and _hud.low and _hud.card_is(_ru), "two buttons, colour, low, its own")
	_ok(not _pj.shown.back(), "the rings hide at the offer")
	_ok(_calls.paused and _calls.closed == 1, "rescue calls paused and closed once")
	_ok(_hud.pills_hidden == pills + 1 and _hud.challenges_hidden == challenges + 1, "pill and challenge taken down once")
	_ok(_dlg.said.back() == "lezak:start" and _dlg.speakers.back() == "Leżak", "the lezak start line by Leżak")
	_ok((_dlg.anchors.back() as Callable).call() == A, "the line's anchor is depot 0")
	var near := _ps.lying_near(Vector2(A.x, A.z), RoundupJob.REACH, RoundupJob.WANT)
	_ok(_ru.targets == near and near.size() == 10 and not near.any(func(i: int) -> bool: return i >= 14 and i <= 17), "the ten nearest lying Leżaks")
	_ok(_ru.depot == 0 and _ru.boot == 0 and _ru.unloaded == 0, "depot 0, nothing in the boot")
	_ok(not _ru.has_target() and _dir.targeted() == null and _ru.stop_spot() == Vector3.INF, "no target at the offer")
	_hud.abort_pressed.emit()
	_ok(_is(RoundupJob.Stage.OFFER), "the ✕ does nothing at the offer")
	var shown := _hud.shown
	_ok(not _ru.offer(0) and _hud.shown == shown, "offer(0) while on: false, nothing shown")
	_ok(_wallet.kinds.is_empty() and _hud.toasts.is_empty(), "no pay, no toast at the offer")
	# Nobody answers.
	var pois := _hud.pois_set
	_frames(11.9)
	_ok(_is(RoundupJob.Stage.OFFER) and _hud.card != "", "the offer is still up at 11.9 s")
	_frames(0.2)
	_ok(_ru.idle() and _ru.stage == RoundupJob.Stage.NONE and _hud.card == "", "the offer is gone by 12.1 s")
	_ok(not _calls.paused and _calls.closed == 2 and _pj.dirty == 1, "unanswered: calls free, closed twice, jobs told")
	_ok(_hud.pois == 0 and _hud.pois_set == pois + 1, "unanswered: the pins set to none")
	_ok(_ru.depots[0]["cool"] and _ru.targets.is_empty(), "unanswered: depot 0 cool, targets empty")
	_ok(_hud.toasts.is_empty() and _wallet.kinds.is_empty(), "unanswered: no toast, no pay")
	_frames(0.6)
	_ok(_pj.shown.back(), "unanswered: the rings are back")
	# Cooling.
	_frames(2.0)
	_ok(_ru.idle(), "2 s on in the ring: no card")
	_near(0, 20.0)
	_frames(1.0)
	_near(0, 3.0)
	_frames(1.0)
	_ok(_ru.idle(), "1 s at 20 m and back in: no card")
	_near(0, 30.0)
	_frames(0.6)
	_near(0, 3.0)
	_frames(0.6)
	_ok(_is(RoundupJob.Stage.OFFER), "0.6 s at 30 m and back in: the card again")
	# NOT NOW.
	_rig()
	_ok(_pull(0), "offer for NOT NOW")
	pois = _hud.pois_set
	_hud.press(1)
	_ok(_ru.idle() and _hud.card == "" and not _calls.paused and _calls.closed == 2 and _pj.dirty == 1, "NOT NOW: idle, calls free, jobs told")
	_ok(_hud.pois == 0 and _hud.pois_set == pois + 1 and _ru.depots[0]["cool"] and _hud.toasts.is_empty(), "NOT NOW: pins none, cool, no toast")
	# Driving off.
	_rig()
	_ok(_pull(0), "offer for driving off")
	_near(0, RoundupJob.DEPOT_R + 6.9)
	_frames(1.0)
	_ok(_is(RoundupJob.Stage.OFFER), "13.9 m from the depot: the card stays")
	_near(0, RoundupJob.DEPOT_R + 7.2)
	_frames(DT)
	_ok(_ru.idle() and _hud.card == "" and _hud.toasts.is_empty(), "14.2 m away: gone as NOT NOW")
	# The keys.
	_rig()
	_ok(_pull(0), "offer for the keys")
	_ok(_ru.secondary() and _ru.idle(), "secondary() ends the offer")
	_ok(_reenter(0), "a new offer after leaving")
	_ok(_ru.primary() and _is(RoundupJob.Stage.COLLECT), "primary() takes the offer")
	_ok(not _ru.primary() and not _ru.secondary(), "no keys while collecting")
	_hud.abort_pressed.emit()
	_ok(_ru.idle() and not _ru.primary() and not _ru.secondary(), "no keys while idle")
	# Somebody else's card over the offer.
	_rig()
	_ok(_pull(0), "offer for another card")
	var broadcast := _hud.broadcast
	_hud.show_card("INNA", "…", PackedStringArray(["OK"]), Color.RED)
	_hud.press(0)
	_ok(_hud.broadcast == broadcast + 1 and _is(RoundupJob.Stage.OFFER), "a press of another card goes to every listener; the offer is on")
	_hud.hide_card()
	_frames(DT)
	_ok(_hud.card == "ZBIERZ 10 LEŻAKÓW" and _hud.low and _hud.card_is(_ru), "the offer's card is back, low, its own")
	_hud.press(0)
	_ok(_is(RoundupJob.Stage.COLLECT), "GO! works on the card that came back")


## GO!, the pick-ups, the unload, the result, then two more rounds.
func _p_round() -> void:
	_rig()
	var first_zl := 0
	_ok(_start_round(0), "GO! at depot 0")
	var A := _dep(0)
	var order: Array[int] = _ru.targets.duplicate()
	_ok(_is(RoundupJob.Stage.COLLECT), "stage COLLECT")
	_ok(_hud.toasts.back() == "Zbieraj Leżaki: podjedź powoli" and _hud.toasts_en.back() == "Collect the Leżaks: drive up slowly", "the GO toast")
	_ok(_hud.card == "", "no card after GO!")
	_ok(_hud.pois == 11, "%d pins (want 11)" % _hud.pois)
	var pins_ok := _hud.pois == 11
	for k in mini(order.size(), _hud.pois):
		var p := _lez(order[k])
		pins_ok = pins_ok and _hud.poi_points[k] == Vector2(p.x, p.z) and _hud.poi_colours[k] == RoundupJob.PIN_COLOUR \
				and _hud.poi_shapes[k] == MapIcons.POI_SCOOTER
	_ok(pins_ok, "the first ten pins at the Leżaks, violet, scooters")
	_ok(_hud.pois == 11 and _hud.poi_points[10] == Vector2(A.x, A.z) and _hud.poi_colours[10] == RoundupJob.COLOUR \
			and _hud.poi_shapes[10] == MapIcons.POI_DEPOT, "the last pin is the depot, teal")
	var nearest := order[0]
	for i in order:
		if _dist(_car.global_position, _lez(i)) < _dist(_car.global_position, _lez(nearest)):
			nearest = i
	_ok(_ru.has_target() and _dir.targeted() == _ru, "a target, the director's")
	_ok(_ru.target_position() == _lez(nearest) and _ru.target_colour() == RoundupJob.PIN_COLOUR and _ru.stop_spot() == Vector3.INF,
			"the target is the nearest Leżak, violet; no stop spot")
	_ok(not _ru._beacon.waving, "the beacon doesn't wave")
	_frames(DT)
	_ok(_hud.status_title == "LEŻAKI 0/10 · BAGAŻNIK 0/5" and _hud.count == "5:59", "status: %s %s" % [_hud.status_title, _hud.count])
	_ok(_hud.distance == "%d m" % roundi(_dist(_car.global_position, _lez(nearest))), "status distance %s" % _hud.distance)
	_ok(_hud.status == "Podjedź powoli do fioletowej pinezki" and _hud.hint_en == "Drive up slowly to a violet pin", "status hint")
	_ok(_hud.tint == RoundupJob.COLOUR and _hud.progress == _ru.secs / RoundupJob.LIMIT and not _ru._beacon.visible, "tint, progress, ring hidden")
	# Picking up.
	_put(_lez(5) + Vector3(3, 0, 0), 5.0)
	_frames(0.5)
	_ok(_ru.boot == 0 and _hud.status == "Wolniej! Poniżej 15 km/h" and _hud.hint_en == "Slower! Under 15 km/h", "3 m at 5 m/s: not picked, 'Wolniej!'")
	_put(_lez(5) + Vector3(3, 0, 0), 15.1 / 3.6)
	_frames(0.5)
	_ok(_ru.boot == 0, "at 15.1 km/h: not picked")
	_put(_lez(5) + Vector3(3, 0, 0), 14.8 / 3.6)
	var set0 := _hud.pois_set
	_frames(DT)
	_ok(_ps.collected == [5] and _ru.boot == 1 and not 5 in _ru.targets, "at 14.8 km/h: Leżak 5 picked")
	_ok(_hud.toasts.back() == "+1 LEŻAK · BAGAŻNIK 1/5" and _hud.toasts_en.back() == "+1 Leżak in the boot (1 of 5)", "the pick-up toast")
	_ok(_hud.pois_set == set0 + 1 and _hud.pois == 10, "the pins set again (%d)" % _hud.pois)
	_ok(_hud.status_title == "LEŻAKI 0/10 · BAGAŻNIK 1/5", "status after the pick-up: %s" % _hud.status_title)
	_put(_lez(6) + Vector3(4.05, 0, 0))
	_frames(0.5)
	_ok(_ru.boot == 1, "4.05 m: not picked")
	_put(_lez(6) + Vector3(3.95, 0, 0))
	_frames(2 * DT)
	_ok(_ru.boot == 2, "3.95 m: picked")
	_pj.flying = true
	_put(_lez(7))
	_frames(0.5)
	_ok(_ru.boot == 2 and _hud.status == "Wyląduj: Leżaki jadą w bagażniku" and _hud.hint_en == "Land: the Leżaks ride in the boot", "from the air: not picked, 'Wyląduj'")
	_pj.flying = false
	_frames(DT)
	_ok(_ru.boot == 3, "landed: picked at the next frame")
	var later := 0 if order.find(0) > order.find(1) else 1
	_put(_lez(0))
	_frames(DT)
	_ok(_ru.boot == 4 and _ps.collected.back() == later, "two on one spot: the later one in targets first")
	_frames(DT)
	_ok(_ru.boot == 5 and _hud.toasts.back().ends_with("BAGAŻNIK 5/5"), "the other one a frame later: boot 5/5")
	var n_col := _ps.collected.size()
	_put(_lez(2))
	_frames(0.5)
	_ok(_ps.collected.size() == n_col and _ru.boot == 5, "a full boot picks nothing")
	_ok(_ru.target_position() == A and _ru.target_colour() == RoundupJob.COLOUR and _ru.stop_spot() == A, "full boot: the depot is the target and the stop")
	var b: Node3D = _ru._beacon
	_ok(b.visible and b.global_position == A and b._ring_radius == RoundupJob.DEPOT_R - 0.5 and b._column.visible and not b._person.visible,
			"full boot: the ring stands at the depot")
	_ok(_hud.status == "Bagażnik pełny: wracaj do strefy" and _hud.hint_en == "The boot is full: back to the zone", "full boot hint")
	_ok(_hud.distance == "%d m" % roundi(_dist(_lez(2), A)), "full boot distance %s" % _hud.distance)
	# Unloading.
	_near(0, RoundupJob.UNLOAD_R + 0.2)
	_frames(1.0)
	_ok(_ru.unloaded == 0, "13.2 m: nothing unloaded")
	_near(0, RoundupJob.UNLOAD_R - 0.2, RoundupJob.UNLOAD_SPEED + 0.1)
	_frames(0.5)
	_ok(_ru.unloaded == 0, "12.8 m at 6.1 m/s: nothing unloaded")
	_pj.flying = true
	_put(A)
	_frames(0.5)
	_ok(_ru.unloaded == 0, "from the air at the centre: nothing unloaded")
	_pj.flying = false
	_put(A + Vector3(3, 0, 0), 10.0)
	_frames(0.5)
	_ok(_ru.unloaded == 0 and _hud.status == "Stań w strefie" and _hud.hint_en == "Stop in the zone", "3 m at 10 m/s: nothing, 'Stań w strefie'")
	_near(0, RoundupJob.UNLOAD_R - 0.2, RoundupJob.UNLOAD_SPEED - 0.1)
	_frames(DT)
	_ok(_ru.unloaded == 5 and _ru.boot == 0, "12.8 m at 5.9 m/s: unloaded 5")
	_ok(_hud.toasts.back() == "WYŁADOWANO 5 · RAZEM 5/10" and _hud.toasts_en.back() == "Unloaded 5 · 5 of 10 back", "the unload toast")
	_ok(_hud.status_title == "LEŻAKI 5/10 · BAGAŻNIK 0/5", "status after the unload: %s" % _hud.status_title)
	var tp := _ru.target_position()
	_ok(not _ru._beacon.visible and _ru.target_colour() == RoundupJob.PIN_COLOUR and _ru.stop_spot() == Vector3.INF \
			and _ru.targets.any(func(i: int) -> bool: return _lez(i) == tp), "after the unload: a Leżak is the target again")
	# The result.
	_peak = 0
	_drive(func() -> bool: return _ru.stage == RoundupJob.Stage.RESULT, 200.0, "the other five didn't come back")
	_ok(_is(RoundupJob.Stage.RESULT), "stage RESULT")
	_ok(_wallet.money == 120 and _wallet.respect == 40 and _wallet.kinds.size() == 1 and _wallet.kinds[0] == "roundup", "paid 120 zł, 40 respect, once")
	_ok(_ru.done == 1 and int(_ru.last_pay["zl"]) == 120 and int(_ru.last_pay["bonus"]) == 40 and int(_ru.last_pay["respect"]) == 40 and bool(_ru.last_pay["all"]),
			"done 1, last_pay")
	var mm := _mmss(_ru.secs)
	_ok(_hud.card == "ZEBRANE · 10 LEŻAKÓW · +120 zł" and _hud.card_en == "Rounded up · 10 Leżaks · +120 zł", "result title")
	_ok(_hud.body == "„…”\n10 × 8 zł + 40 zł premii, +40 szacunku · czas %s" % mm, "result body: %s" % _hud.body)
	_ok(_hud.body_en == "\"…\"\n10 × 8 zł + 40 zł bonus, +40 respect · time %s" % mm, "result body, English: %s" % _hud.body_en)
	_ok(_hud.buttons == 1 and _hud.low and _hud.accent == RoundupJob.COLOUR and _hud.card_is(_ru), "result: one button, low, colour, its own")
	_ok(_dlg.line_asks.back() == "lezak:done", "the done line asked for")
	_ok(_hud.status_title == "" and not _ru._beacon.visible and _hud.pois == 0 and _dir.targeted() == null, "result: status down, ring hidden, pins none, no target")
	var gone := order.all(func(i: int) -> bool: return _ps.scooters[i].get("gone", false))
	_ok(gone, "all ten are gone from the store")
	_hud.abort_pressed.emit()
	_ok(_is(RoundupJob.Stage.RESULT) and _hud.card != "", "the ✕ does nothing at the result")
	_ok(not _ru.secondary() and _hud.card != "", "secondary() is false at the result")
	var secs := _ru.secs
	var money := _wallet.money
	_frames(1.0)
	_ok(_ru.secs == secs, "the clock stands behind the card")
	_ok(_wallet.money == money, "paid once")
	_frames(10.9)
	_ok(_is(RoundupJob.Stage.RESULT) and _hud.card != "", "the result is still up at 11.9 s")
	_frames(0.2)
	_ok(_ru.idle() and _hud.card == "", "the result is gone by 12.1 s")
	_ok(_pj.dirty == 1 and not _calls.paused and _ru.depots[0]["cool"] and _ru.boot == 0 and _ru.targets.is_empty(), "after the result: jobs told, calls free, cool, nothing left")
	# A second round at depot 0: the four left, ended by OK.
	first_zl = _wallet.money
	_ok(_reenter(0), "the second offer at depot 0")
	_ok(_hud.card == "ZBIERZ 4 LEŻAKÓW", "the second round: %s" % _hud.card)
	_hud.press(0)
	_drive(func() -> bool: return _ru.boot == 4, 120.0, "the four weren't picked")
	_ok(_hud.status == "Wracaj do strefy i wyładuj" and _hud.hint_en == "Back to the zone to unload" and _ru.stop_spot() == A, "four in the boot: back to unload")
	_drive(func() -> bool: return _ru.stage == RoundupJob.Stage.RESULT, 120.0, "the second round didn't finish")
	_ok(_wallet.money - first_zl == 72 and _wallet.respect == 80 and _ru.done == 2, "the second round paid 72 zł and 40 respect")
	_ok(_hud.card == "ZEBRANE · 4 LEŻAKÓW · +72 zł", "second result: %s" % _hud.card)
	_hud.press(0)
	_ok(_ru.idle() and _hud.card == "" and _pj.dirty == 2, "OK ends the second result")
	# Depot 0 with none left.
	var t0 := _hud.toasts.size()
	_near(0, 30.0)
	_frames(0.6)
	_near(0, 3.0)
	_frames(0.7)
	_ok(_ru.idle() and _hud.toasts.size() == t0 + 1 and _hud.toasts.back() == "Tu już posprzątane. Na dziś", "depot 0 after both rounds: the tidy toast")
	# A third round at depot 2 (six: a boot of five and then one), no words from the dialogue, ended by the key.
	_dlg.line_words = []
	first_zl = _wallet.money
	_peak = 0
	_ok(_reenter(2), "the offer at depot 2")
	_ok(_hud.card == "ZBIERZ 6 LEŻAKÓW", "depot 2: %s" % _hud.card)
	_hud.press(0)
	_drive(func() -> bool: return _ru.stage == RoundupJob.Stage.RESULT, 200.0, "depot 2's six didn't come back")
	_ok(_peak == 5 and _wallet.money - first_zl == 88, "depot 2: a boot of five, paid 88 zł (%d)" % (_wallet.money - first_zl))
	_ok(_hud.body.begins_with("6 × 8 zł") and _hud.body_en.begins_with("6 × 8 zł"), "no words: the body has no quote line (%s)" % _hud.body)
	_ok(_ru.primary() and _ru.idle(), "primary() ends the result")


func _p_late() -> void:
	_rig()
	_ok(_start_round(2), "GO! at depot 2")
	_frames(DT)
	_ru.secs = 400.0
	_frames(DT)
	_ok(_hud.tint == RoundupJob.FAIL_COLOUR and _hud.count == "+0:40" and _hud.progress == 1.0, "late: red, +0:40, bar full (%s)" % _hud.count)
	_drive(func() -> bool: return _ru.stage == RoundupJob.Stage.RESULT, 200.0, "the late round didn't finish")
	_ok(_wallet.money == 48 and _wallet.respect == 40 and int(_ru.last_pay["bonus"]) == 0, "late: 48 zł, no bonus, 40 respect")
	_ok(not _hud.body.contains("premii") and not _hud.body_en.contains("bonus"), "late: the card has no bonus")


func _p_abort() -> void:
	_rig()
	_ok(_start_round(0), "GO! for the ✕")
	_drive(func() -> bool: return _ru.unloaded == 5, 200.0, "five didn't come back")
	_drive(func() -> bool: return _ru.boot == 2, 200.0, "two weren't picked")
	var money := _wallet.money
	var respect := _wallet.respect
	var dirty := _pj.dirty
	var done := _ru.done
	_hud.abort_pressed.emit()
	_ok(_ru.idle() and _wallet.money - money == 40 and _wallet.respect == respect and _wallet.kinds.back() == "roundup", "✕: 40 zł, no respect")
	_ok(_hud.toasts.back() == "Koniec zbierania · +40 zł" and _hud.toasts_en.back() == "Round-up given up · +40 zł", "✕: the toast")
	_ok(_hud.status_title == "" and _hud.pois == 0 and not _ru._beacon.visible and not _ru.has_target() and _dir.targeted() == null, "✕: status, pins, ring, target down")
	_ok(not _calls.paused and _pj.dirty == dirty + 1 and _ru.boot == 0 and _ru.targets.is_empty() and _ru.done == done and _ru.depots[0]["cool"], "✕: calls free, jobs told, boot and targets empty, done the same, cool")
	_ok(_ps.collected.size() == 7 and _ps.collected.all(func(i: int) -> bool: return _ps.scooters[i].get("gone", false)), "✕: the seven picked up stay gone")
	_rig()
	_ok(_start_round(0), "GO! for the empty ✕")
	_hud.abort_pressed.emit()
	_ok(_ru.idle() and _wallet.kinds.is_empty() and _wallet.money == 0, "✕ with none back: no pay")
	_ok(_hud.toasts.back() == "Koniec zbierania · +0 zł" and _hud.toasts_en.back() == "Round-up given up · +0 zł", "✕ with none back: +0 zł")


func _p_too_few() -> void:
	_rig()
	var shown := _hud.shown
	_near(1, 3.0)
	_frames(0.7)
	var tidy := "Tu już posprzątane. Na dziś"
	_ok(_ru.idle() and _hud.toasts.size() == 1 and _hud.toasts[0] == tidy and _hud.toasts_en[0] == "Already tidy round here. For tonight", "depot 1: the tidy toast")
	_frames(3.0)
	_ok(_hud.toasts.size() == 1, "3 s on: still one toast")
	_ok(_ru.depots[1]["cool"] and _calls.closed == 0 and _hud.shown == shown, "depot 1 cool, no calls closed, no card")
	_near(1, 30.0)
	_frames(0.6)
	_near(1, 3.0)
	_frames(0.6)
	_ok(_hud.toasts.size() == 2, "back in after 30 m: the toast once more")
	_near(3, 3.0)
	_frames(0.7)
	_ok(_ru.idle() and _hud.toasts.size() == 3 and _hud.toasts.back() == tidy and _ru.depots[3]["cool"], "depot 3 (none): the same toast")


func _p_morning() -> void:
	_rig()
	_ok(_start_round(0), "GO! for the morning")
	for k in 2:
		_put(_lez(_ru.targets[0]))
		_frames(DT)
	_ok(_ps.collected.size() == 2, "two Leżaks picked up")
	_hud.abort_pressed.emit()
	_put(FAR)
	_tod.mode = 0
	_frames(0.6)
	_ok(_ps.restored.size() == 1 and _ps.restored[0] == 2, "the morning restores 2 (%s)" % [_ps.restored])
	_ok(_ps.scooters.all(func(s: Dictionary) -> bool: return not s.get("gone", false)), "none gone any more")
	_ok(not _pj.shown.back(), "by day the rings are hidden")
	_near(0, 3.0)
	_frames(1.0)
	_ok(_ru.idle() and _hud.card == "", "by day, in a ring: no card")
	_put(FAR)
	_tod.mode = 2
	_frames(0.6)
	_tod.mode = 0
	_frames(0.6)
	_ok(_ps.restored.size() == 2 and _ps.restored[1] == 0, "night and day again: restored 0")


func _p_force() -> void:
	_rig(true, false)
	_ru.force = true
	_frames(0.6)
	_ok(_pj.shown.size() > 0 and _pj.shown.back(), "--roundup by day: the rings show")
	_near(0, 3.0)
	_frames(0.7)
	_ok(_is(RoundupJob.Stage.OFFER), "--roundup by day: the card")
	_rig(true, false)
	_put(Vector3(300, 0, 100), 5.0)
	_car.forward_speed = 5.0
	_ok(_ru.start_at_nearest(), "start_at_nearest from (300, 100)")
	_ok(_car.global_position == _dep(0) + Vector3(0, 0.1, 0) and _car.vel == Vector3.ZERO and _car.forward_speed == 0.0, "the car at depot 0, stopped")
	_ok(_is(RoundupJob.Stage.OFFER), "the offer is up")
	_rig(true, false)
	_put(FAR)
	_ok(not _ru.start_at_nearest(), "start_at_nearest from (900, 900): depot 1 has too few")
	_ok(_ru.idle() and _hud.toasts.size() == 1 and _hud.toasts[0] == "Tu już posprzątane. Na dziś" and _car.global_position == _dep(1) + Vector3(0, 0.1, 0), "the nearest was depot 1: the tidy toast")


func _p_autopilot() -> void:
	_rig()
	_ru.autopilot = true
	_ok(_pull(0), "autopilot: the offer")
	_frames(2.4)
	_ok(_is(RoundupJob.Stage.OFFER) and _hud.card != "", "autopilot: the offer is up at 2.4 s")
	_frames(0.2)
	_ok(_is(RoundupJob.Stage.COLLECT) and _hud.card == "", "autopilot: GO! taken by 2.6 s")
	var done := false
	for f in roundi(120.0 / DT):
		_slide()
		_ru._process(DT)
		if _is(RoundupJob.Stage.RESULT):
			done = true
			break
	_ok(done, "autopilot: the round didn't finish in 120 s")
	_ok(_ru.unloaded == 10 and _wallet.money == 120, "autopilot: ten back, +120 zł")
	_frames(2.4)
	_ok(_is(RoundupJob.Stage.RESULT) and _hud.card != "", "autopilot: the result is up at 2.4 s")
	_frames(0.2)
	_ok(_ru.idle() and _hud.card == "", "autopilot: the result is gone by 2.6 s")
	_rig()
	_ru.autopilot = true
	_near(0, 30.0)
	_ok(_ru.offer(0), "autopilot: an offer from 30 m")
	_frames(DT)
	_ok(_is(RoundupJob.Stage.COLLECT), "autopilot: driving off answers GO!, not NOT NOW")


func _p_meet() -> void:
	_rig()
	var shown := _hud.shown
	_ok(_ru.meet(), "meet() when idle: true")
	_ok(_hud.shown == shown and _ru.idle() and _hud.toasts.is_empty(), "meet(): no card, idle at once, no toast")
	_ok(_pull(0), "an offer after meet()")
	_ok(not _ru.meet(), "meet() on the offer: false")


func _p_director() -> void:
	_rig()
	_ok(_start_round(0), "GO! for the director")
	_ok(_dir.busy() and _dir.current() == _ru and _dir.targeted() == _ru and _dir.grounded().is_empty() and not _dir.may_start(_other), "the director while collecting")
	_hud.abort_pressed.emit()
	_ok(not _dir.busy() and _dir.may_start(_other), "the director after the ✕")
