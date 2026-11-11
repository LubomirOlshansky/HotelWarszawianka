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
##   6. the cost: the race's step and the round-up's idle step a frame.
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

	func toast(pl: String, en := "") -> void:
		toasts.append([pl, en])

	func show_note(_a: String, _b: String, _c := Color.WHITE) -> void:
		pass

	func show_card(title: String, _body: String, _b: PackedStringArray, _c: Color, _bottom := false, _te := "", _be := "") -> void:
		cards.append(title)

	func hide_card() -> void:
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
		print("check_side_jobs: OK (courier race: %s; round-up: %s; payphone %s; cost: race %s, round-up idle %s)" % [
				_summary.get("race", "?"), _summary.get("roundup", "?"), _summary.get("phone", "?"),
				_summary.get("race_us", "?"), _summary.get("idle_us", "?")])
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
	root.add_child(ru)
	ru.set_process(false)
	ru.setup(world)
	_expect(ru.depots.size() == deps.size(), "%d depots set up (want %d)" % [ru.depots.size(), deps.size()])
	# The idle step's cost far from the depots.
	car.global_position = Vector3(9000, 0, 9000)
	var t0 := Time.get_ticks_usec()
	for k in 3000:
		ru.step(DT)
	_summary["idle_us"] = "%.2f µs a frame" % (float(Time.get_ticks_usec() - t0) / 3000.0)
	# Into depot 0's ring at night: the card; GO.
	var dep: Vector3 = ru.depots[0]["at"]
	car.global_position = dep
	for k in 40:
		ru.step(DT)
	_expect(ru.state == RoundupJob.State.OFFER and hud.cards.size() == 1 and dlg.count("lezak", "start") == 1, "no card at the depot")
	var want := ru.targets.size()
	var picked: Array[int] = ru.targets.duplicate()
	_expect(want >= RoundupJob.AT_LEAST and want <= RoundupJob.WANT, "%d Leżaks to round up at depot 0 (want 4-10)" % want)
	_expect(ru.primary() and ru.state == RoundupJob.State.COLLECT and hud.pois == want + 1, "GO didn't start it (pins %d)" % hud.pois)
	var zl := wallet.zl
	var rs := wallet.respect
	var loads := _drive_round(ru, car, dep, 0.0)
	_expect(ru.state == RoundupJob.State.RESULT and loads >= 2 and _max_boot == RoundupJob.BOOT, "the round-up: state %d after %d loads, the boot at most %d (want the card, a full boot of 5)" % [
			ru.state, loads, _max_boot])
	_expect(wallet.zl - zl == want * 8 + 40 and wallet.respect - rs == 40, "paid %d zł, %d respect (want %d, 40)" % [wallet.zl - zl,
			wallet.respect - rs, want * 8 + 40])
	_expect(dlg.count("lezak", "done") == 1, "the done line: %d" % dlg.count("lezak", "done"))
	for k in 60:
		ru.step(DT)
	_expect(wallet.zl - zl == want * 8 + 40, "the round-up paid twice")
	var gone := 0
	for i in picked:
		gone += int(sf.scooters[i].get("gone", false))
	_expect(gone == want and sf.lying_near(Vector2(dep.x, dep.z), RoundupJob.REACH, 50).all(func(i: int) -> bool: return not i in picked),
			"%d of %d collected Leżaks off the pavement" % [gone, want])
	ru.primary()
	_expect(ru.state == RoundupJob.State.IDLE and jobs.dirty == 1, "OK didn't close the card")
	# The morning: they lie about again.
	tod.mode = 0
	for k in 40:
		ru.step(DT)
	var back := 0
	for i in picked:
		back += int(not sf.scooters[i].get("gone", false))
	_expect(back == want, "%d of %d Leżaks back by the morning" % [back, want])
	# Late: 6:40 for the lot, no bonus.
	tod.mode = 2
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru.step(DT)
	car.global_position = dep
	for k in 40:
		ru.step(DT)
	_expect(ru.state == RoundupJob.State.OFFER, "no second card")
	ru.primary()
	zl = wallet.zl
	rs = wallet.respect
	_drive_round(ru, car, dep, 400.0)
	_expect(wallet.zl - zl == ru.unloaded * 8 and int(ru.last_pay.get("bonus", -1)) == 0 and wallet.respect - rs == 40,
			"late: paid %d zł (want %d, no bonus)" % [wallet.zl - zl, ru.unloaded * 8])
	ru.primary()
	tod.mode = 0
	for k in 40:
		ru.step(DT)
	# ✕ after one load: the unloaded paid, no bonus, no respect.
	tod.mode = 2
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru.step(DT)
	car.global_position = dep
	for k in 40:
		ru.step(DT)
	ru.primary()
	zl = wallet.zl
	rs = wallet.respect
	_drive_round(ru, car, dep, 0.0, 1)
	var unl := ru.unloaded
	hud.abort_pressed.emit()
	_expect(ru.state == RoundupJob.State.IDLE and wallet.zl - zl == unl * 8 and wallet.respect == rs and unl > 0,
			"✕ after %d unloaded paid %d zł, %d respect" % [unl, wallet.zl - zl, wallet.respect - rs])
	# Nothing in the day.
	tod.mode = 0
	for k in 40:
		ru.step(DT)
	car.global_position = Vector3(9000, 0, 9000)
	for k in 40:
		ru.step(DT)
	car.global_position = dep
	for k in 40:
		ru.step(DT)
	_expect(ru.state == RoundupJob.State.IDLE, "a round-up card by day")
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
	while ru.state == RoundupJob.State.COLLECT and guard < 200:
		guard += 1
		var to: Vector3 = ru.target_position()
		car.global_position = to + Vector3(1.0, 0, 0)
		var before := ru.unloaded
		if to.distance_to(dep) < 0.01 and ru.targets.is_empty():
			ru.clock += extra
		for k in 3:
			ru.step(DT)
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
