extends SceneTree
## Loop MW-4 (docs/design/vision.md 3.4, 3.7): everyday life and trends (scripts/city_life.gd,
## scripts/trend_job.gd), headless, from the committed map data (map/centrum.json) and
## data/places.json; seeded, no clock of its own (every hour and date is synthetic):
##   1. the dogs' hours and caps, the riders' and runners' hours, Kolka's evening and size;
##   2. the horn: a bark at most every 2 s per dog, the walker's line at most once a minute (a
##      horn every 0.5 s for 300 s near a real dog walker);
##   3. the Wiralek cycle on synthetic dates: days 1-8, the queue by day, the three slots' offsets,
##      the shop's hours, the sync (E19) once every 12 cycles, the sessions without Live;
##   4. the "Na czasie" job's pay: base + per km, the tip, late at half, days 6-7 no tip (and its
##      "to już niemodne" line);
##   5. the Zając: 600 m beside the club at 9-14 km/h pays once; too fast, too far or a long gap
##      starts again;
##   6. Fat Thursday from Easter (2026, 2027, 2028) and Lukrownia's queue on it only;
##   7. the eggs E16 E18 E19 E20 E27 E28 E29 E30 on synthetic inputs, each only with its conditions,
##      each reward once;
##   8. the meshes (each dog ≤ 120 triangles), the car's clearance, and the real city: walkers at
##      Plac Zbawiciela at 07:30, none at 11:00, the dock, Kolka's route, the tick's cost;
##   9. loop jobs-2: the armchair man (E34): one day in three, there and back, his two ends on a
##      synthetic street; on the real map his way on Mokotowska, his guest and the chair near the
##      view (none far), the car beside him counted; E34 an event egg, once.
## Prints "check_city_life: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_city_life.gd [-- --verbose]

const CityLife := preload("res://scripts/city_life.gd")
const TrendJob := preload("res://scripts/trend_job.gd")
const Crowds := preload("res://scripts/crowds.gd")
const ScooterZones := preload("res://scripts/scooter_zones.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Props := preload("res://scripts/props.gd")


## A stand-in for dialogue.gd: records each line asked for.
class FakeDialogue extends Node:
	var said: Array = []

	func say(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _k := 0, _key := "") -> Array:
		said.append([speaker, group, tag])
		return ["…", "…"]

	func say_ambient(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false) -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func say_reaction(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _key := "") -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func count(group: String, tag: String) -> int:
		var n := 0
		for l: Array in said:
			n += int(l[1] == group and l[2] == tag)
		return n


var problems: Array[String] = []
var verbose := false
var now := {"hour": 7.5, "weekday": 5}
var cal := {"live": false, "month": 7, "date": 0, "look": "Day", "rain": false}
var eye := Vector3.ZERO
var veh: Array = [Vector3.INF, 0.0, false, 0.0, 0.0]
var _summary := {}


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	_check_rules()
	_check_trends()
	_check_scooter_zones()
	_check_pay()
	_check_zajac()
	_check_fat_thursday()
	_check_meshes()
	_check_armchair_rules()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("check_city_life: PROBLEM (no map data or places.json)")
		quit(1)
		return
	_check_eggs(book)
	await _check_city(book, data)
	book.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_city_life: OK (dog hours and caps, riders, runners, Kolka; horn %s; trend cycle on synthetic dates, sync every %d cycles; pay %s; Zając once; Fat Thursday %s; eggs E16 E18 E19 E20 E27 E28 E29 E30 E34 once each; dogs %d tris; city %s; the armchair man %s, his way %s)" % [
				_summary.get("horn", "?"), CityLife.SYNC_EVERY, _summary.get("pay", "?"), _summary.get("fat", "?"),
				_summary.get("tris", 0), _summary.get("city", "?"), _summary.get("armchair", "?"), _summary.get("armchair_city", "?")])
		quit(0)
	else:
		for p in problems:
			print("  problem: ", p)
		print("check_city_life: %d problems" % problems.size())
		quit(1)


# 1. -------------------------------------------------------------------------------------------

func _check_rules() -> void:
	# [hour, zone, want walkers]
	for row: Array in [[5.0, false, 0], [6.4, true, 0], [6.5, false, 5], [7.5, true, 10], [8.99, false, 5], [9.0, true, 0],
			[13.0, true, 10], [14.5, true, 0], [18.9, false, 0], [19.0, false, 5], [22.4, true, 10], [22.5, true, 0], [2.0, true, 0]]:
		var n := CityLife.dog_count(row[0], row[1])
		_expect(n == int(row[2]), "dog walkers at %.2f (zone %s): %d (want %d)" % [row[0], row[1], n, row[2]])
	_expect(CityLife.dog_count(7.5, true, 0.5) == 5, "the Low tier halves the walkers: %d" % CityLife.dog_count(7.5, true, 0.5))
	_expect(CityLife.dog_count(7.5, true, 2.0) <= CityLife.DOGS_MAX * 2 and CityLife.DOGS_MAX * 2 + 3 <= CityLife.DOG_CAP,
			"--life=2: %d walkers, the cap %d (+3 for the barriers' and the ball's room)" % [CityLife.dog_count(7.5, true, 2.0), CityLife.DOG_CAP])
	_expect(CityLife.dog_count(7.5, false, 0.0) == 0, "--life=0 still has walkers")
	# Riders: 06-22, twice at rush hours.
	for row: Array in [[5.5, 0], [6.5, 4], [8.0, 8], [12.0, 4], [17.0, 8], [21.9, 4], [22.0, 0]]:
		var n := CityLife.rider_count(row[0])
		_expect(n == int(row[1]), "riders at %.1f: %d (want %d)" % [row[0], n, row[1]])
	_expect(CityLife.rider_count(8.0, 2.0) <= CityLife.BIKE_CAP, "riders at --life=2 over the cap")
	# F, 2026-11-01: the Vistula boulevards: twice the riders, capped, still 06-22 only.
	_expect(CityLife.rider_count(12.0, 1.0, true) == 8 and CityLife.rider_count(8.0, 1.0, true) == CityLife.BLVD_RIDERS_MAX
			and CityLife.rider_count(5.5, 1.0, true) == 0, "boulevard riders: 8 midday, %d at rush, none before 06" % CityLife.BLVD_RIDERS_MAX)
	_expect(CityLife.rider_count(8.0, 2.0, true) + 6 <= CityLife.BIKE_CAP * 2 and CityLife.BLVD_V.x > 8.0 and CityLife.BLVD_FAST < 1.0,
			"boulevard riders: fast ones are a share, not all")
	var kinds := [0, 0, 0, 0]
	for i in 100:
		kinds[CityLife.rider_kind(i / 100.0)] += 1
	_expect(kinds[CityLife.ROWERILO] == 30 and kinds[CityLife.CARGO] == 15, "rider kinds %s (want 55/30/15)" % [kinds])
	# Runners: by the boulevards and parks only, 06-08 and 18-21.
	for row: Array in [[7.0, true, 6], [7.0, false, 0], [9.0, true, 0], [18.5, true, 6], [21.0, true, 0]]:
		_expect(CityLife.runner_count(row[0], row[1]) == int(row[2]), "runners at %.1f (zone %s): %d" % [row[0], row[1], CityLife.runner_count(row[0], row[1])])
	# Kolka: Wednesdays, 18:45 gather, 19:00 run, 19:45 home.
	for row: Array in [[18.5, 3, ""], [18.8, 3, "gather"], [19.2, 3, "run"], [19.75, 3, ""], [19.2, 4, ""], [19.2, 6, ""]]:
		_expect(CityLife.kolka_phase(row[0], row[1]) == str(row[2]), "Kolka at %.2f day %d: '%s' (want '%s')" % [row[0], row[1], CityLife.kolka_phase(row[0], row[1]), row[2]])
	for d in [20261028, 20261104, 20261111, 20261118]:
		var n := CityLife.kolka_size(d)
		_expect(n >= 12 and n <= 20 and n == CityLife.kolka_size(d), "Kolka's size on %d: %d (want 12-20, the same all evening)" % [d, n])
	_expect(is_equal_approx(CityLife.kolka_run(19.25, 4000.0), 900.0 * CityLife.KOLKA_V) and CityLife.kolka_run(18.9, 4000.0) == 0.0,
			"Kolka's leader at 19:15: %.0f m (want %.0f)" % [CityLife.kolka_run(19.25, 4000.0), 900.0 * CityLife.KOLKA_V])
	_expect(CityLife.kolka_run(21.0, 1000.0) == 2000.0, "Kolka home by the end")
	# Hyrax: Saturday 09-17; the hurry riders 07-10 that morning.
	_expect(CityLife.hyrax_on(10.0, 6) and not CityLife.hyrax_on(10.0, 5) and not CityLife.hyrax_on(17.0, 6) and not CityLife.hyrax_on(8.9, 6),
			"Hyrax's hours")
	_expect(CityLife.hurry_to_stadium(8.0, 6) and not CityLife.hurry_to_stadium(8.0, 5) and not CityLife.hurry_to_stadium(10.0, 6),
			"the hurry rides' window")
	# The car's room: a body inside the box (grown by its radius) overlaps; clear_of_car is CLEAR away.
	_expect(CityLife.overlaps_car(Vector2(0.5, 1.5), Vector2.ZERO, 0.0) and not CityLife.overlaps_car(Vector2(1.5, 0.0), Vector2.ZERO, 0.0),
			"the car's box at yaw 0")
	_expect(CityLife.overlaps_car(Vector2(1.5, 0.0), Vector2.ZERO, PI / 2.0) and not CityLife.overlaps_car(Vector2(0.0, 1.5), Vector2.ZERO, PI / 2.0),
			"the car's box turned a quarter")
	for a in 16:
		for yaw in [0.0, 0.7, 2.1]:
			var q := CityLife.clear_of_car(Vector2.from_angle(a * TAU / 16.0) * 0.4, Vector2.ZERO)
			_expect(not CityLife.overlaps_car(q, Vector2.ZERO, yaw), "a body pushed clear still overlaps at %s yaw %.1f" % [q, yaw])


# 2. (in _check_city: a real walker) -----------------------------------------------------------

func _check_horn(life: Node, dlg: FakeDialogue) -> void:
	var dogs: Array = life.get("_dogs")
	if dogs.is_empty():
		problems.append("no walkers to honk at")
		return
	var at: Vector2 = dogs[0].d2  # a CityLife.Mover
	var lines0 := dlg.count("dog_walkers", "horn")
	var barks0: int = life.barks
	var t0: float = life.t
	# A horn every 0.5 s for 300 s, 5 m from the dog (it stays put: the walkers aren't moved here).
	for i in 600:
		life.t = t0 + i * 0.5
		life.horn(Vector3(at.x + 5.0, 0.0, at.y))
	var lines: int = dlg.count("dog_walkers", "horn") - lines0
	var barks: int = life.barks - barks0
	var dogs_near := 0
	for x in dogs:
		dogs_near += int((x.d2 as Vector2).distance_to(at + Vector2(5.0, 0.0)) <= CityLife.HORN_R)
	_expect(lines == 5, "horn lines in 300 s: %d (want 5: once a minute)" % lines)
	_expect(barks == 150 * dogs_near, "barks in 300 s: %d for %d dogs (want 150 each: once per 2 s)" % [barks, dogs_near])
	# Far away: nothing.
	life.t = t0 + 1000.0
	life.horn(Vector3(at.x + 40.0, 0.0, at.y))
	_expect(life.barks - barks0 == barks, "a dog barked at a horn 40 m away")
	_summary["horn"] = "%d lines and %d barks in 300 s" % [lines, barks]


# 3. -------------------------------------------------------------------------------------------

func _check_scooter_zones() -> void:
	var sz := ScooterZones.new()
	_expect(sz.at(100000.0, 100000.0) == "", "scooter zones: a far point is inside one")
	for id: String in ScooterZones.ZONES:
		var z: Array = ScooterZones.ZONES[id]
		var c := Notebook.project([52.234, 21.024], float(z[0]), float(z[1]))
		_expect(sz.at(c.x, c.y) == id, "scooter zone %s: its centre reads %s" % [id, sz.at(c.x, c.y)])
		_expect(sz.at(c.x + ScooterZones.RADIUS + 5.0, c.y) != id, "scooter zone %s: outside its radius" % id)
		_expect(ScooterZones.toast_for(id).size() == 2, "scooter zone %s: toast" % id)


func _check_trends() -> void:
	_expect(CityLife.day_number(20260105) == 0 and CityLife.day_number(20260108) == 3 and CityLife.day_number(20270105) == 365,
			"day numbers: %d %d %d" % [CityLife.day_number(20260105), CityLife.day_number(20260108), CityLife.day_number(20270105)])
	# The brief's line: day 2 since the epoch, slot 1 is on day 3 with a queue of 20.
	var s := CityLife.slot_state(2, 0)
	_expect(int(s["day"]) == 3 and int(s["queue"]) == 20, "trend: slot 1 day %d queue %d (want day 3 queue 20)" % [s["day"], s["queue"]])
	# The limited drop: 40 zł + 10 zł a km, a 15 zł tip on time, half and nothing late.
	var dp := TrendJob.drop_pay(2000.0, true)
	var dl := TrendJob.drop_pay(2000.0, false)
	_expect(int(dp["base"]) == 60 and int(dp["zl"]) == 75 and int(dp["respect"]) == TrendJob.DROP_RESPECT, "drop pay on time: %s" % [dp])
	_expect(int(dl["zl"]) == 30 and int(dl["respect"]) == 0 and int(dl["tip"]) == 0, "drop pay late: %s" % [dl])
	# "Czwarty": 45 zł + 8 zł a km there and back, tip 15 on time, half and nothing late.
	var cp := TrendJob.cz_pay(1500.0, true)
	var cl := TrendJob.cz_pay(1500.0, false)
	_expect(int(cp["base"]) == 69 and int(cp["zl"]) == 84 and int(cp["respect"]) == TrendJob.CZ_RESPECT, "czwarty pay on time: %s" % [cp])
	_expect(int(cl["zl"]) == 35 and int(cl["respect"]) == 0, "czwarty pay late: %s" % [cl])
	# The DESKA call: a bio for every caller, three distinct rallies, each with a shot to win it;
	# 6 zł and 2 respect a point won, 5 more respect for landing by helicopter.
	for who: String in TrendJob.DESKI_CALLERS:
		_expect(TrendJob.DESKI_BIOS.has(who), "deski call: no bio for %s" % who)
	for seed_n in 12:
		var rl: Array = TrendJob.match_rallies(seed_n)
		var seen := {}
		for k: int in rl:
			seen[k] = true
		_expect(rl.size() == TrendJob.DESKI_POINTS and seen.size() == rl.size(), "deski match rallies %d: %s" % [seed_n, rl])
	for rally: Array in TrendJob.RALLIES:
		_expect(int(rally[1]) >= 0 and int(rally[1]) < TrendJob.SHOTS.size(), "deski rally best shot: %s" % [rally[0][1]])
	_expect(TrendJob.MATCH_SCORES.size() == TrendJob.DESKI_POINTS + 1, "deski match scores: one per result")
	var dm := TrendJob.match_pay(3, true)
	_expect(int(dm["zl"]) == 18 and int(dm["respect"]) == 11 and int(TrendJob.match_pay(0, false)["zl"]) == 0, "deski match pay: %s" % [dm])
	# "Mlask" (docs/design/gaulle-and-food-hype.md G5): 40 zł + 10 zł a km both ways, tip 15 when
	# warm and on time, half otherwise; his grade's Polish forms; the van's spots and hours, its mesh.
	var mp := TrendJob.ml_pay(1500.0, true, true)
	var mc := TrendJob.ml_pay(1500.0, false, true)
	_expect(int(mp["base"]) == 70 and int(mp["zl"]) == 85 and int(mp["respect"]) == TrendJob.ML_RESPECT, "mlask pay: %s" % [mp])
	_expect(int(mc["zl"]) == 35 and int(mc["tip"]) == 0 and int(mc["respect"]) == 0, "mlask pay cold: %s" % [mc])
	_expect(TrendJob.grade_words(7.5) == ["7,5 MLASKA", "7.5 SMACKS"] and TrendJob.grade_words(3.0)[0] == "3 MLASKI"
			and TrendJob.grade_words(9.0)[0] == "9 MLASKÓW" and TrendJob.grade_words(1.0) == ["1 MLASK", "1 SMACK"],
			"mlask grades: %s %s %s" % [TrendJob.grade_words(7.5), TrendJob.grade_words(3.0), TrendJob.grade_words(9.0)])
	_expect(TrendJob.van_out(12.0) and not TrendJob.van_out(10.5) and not TrendJob.van_out(21.0), "Mrożulo's van hours")
	var spots := {}
	for wd in range(1, 8):
		spots[TrendJob.van_spot(wd)] = true
	_expect(spots.size() == TrendJob.ML_SPOTS.size(), "Mrożulo's van: %d spots over the week" % spots.size())
	var vm := TrendJob.van_mesh()
	var vtris := (vm.surface_get_array_len(0) + vm.surface_get_array_len(1)) / 3
	_expect(vtris <= 800, "Mrożulo's van: %d triangles (budget 800, with the MROŻULO TV lettering)" % vtris)
	_summary["mlask"] = "%d zł warm, %d cold, van %d tris" % [int(mp["zl"]), int(mc["zl"]), vtris]
	# "Dżemini" (G5b, F 2026-11-06): 60 zł + 10 zł a km, tip 20 and +25 respect warm; cold half, no
	# tip, no respect. DŻEMINI's line: a handful before the MLASK, the longest in town after it, a
	# little shorter 02-07. The sticker mesh stays small.
	var dw := TrendJob.dz_pay(1500.0, true)
	var dc := TrendJob.dz_pay(1500.0, false)
	_expect(int(dw["base"]) == 75 and int(dw["zl"]) == 95 and int(dw["respect"]) == TrendJob.DZ_RESPECT, "dzemini pay: %s" % [dw])
	_expect(int(dc["zl"]) == 38 and int(dc["tip"]) == 0 and int(dc["respect"]) == 0, "dzemini pay cold: %s" % [dc])
	_expect(Crowds.dzemini_queue(13.0, false) == [Crowds.DZEMINI_NEW, "dzemini_new"]
			and Crowds.dzemini_queue(13.0, true) == [Crowds.DZEMINI_MAX, "dzemini"]
			and Crowds.dzemini_queue(4.0, true) == [Crowds.DZEMINI_NIGHT, "dzemini"]
			and Crowds.dzemini_queue(23.5, true)[0] == Crowds.DZEMINI_MAX, "DŻEMINI's queue before and after the MLASK")
	var sm := TrendJob.sticker_mesh()
	var stris := sm.surface_get_array_len(0) / 3
	_expect(stris <= 400, "the MLASK sticker: %d triangles (budget 400)" % stris)
	_summary["dzemini"] = "%d zł warm, %d cold, queue %d after the MLASK, sticker %d tris" % [int(dw["zl"]), int(dc["zl"]),
			Crowds.DZEMINI_MAX, stris]
	# Each slot runs days 1-8 in turn, the queue by day, the word until WKRÓTCE.
	for slot in 3:
		var last_trend := -1
		for days in range(0, 8 * 11):
			var st := CityLife.slot_state(days, slot)
			var want := posmod(days + int(CityLife.SLOT_OFFSET[slot]), CityLife.CYCLE) + 1
			_expect(int(st["day"]) == want, "slot %d on day number %d: day %d (want %d)" % [slot + 1, days, st["day"], want])
			_expect(int(st["queue"]) == int(CityLife.QUEUE_BY_DAY[want - 1]), "slot %d day %d: queue %d" % [slot + 1, want, st["queue"]])
			if want == CityLife.CYCLE:
				_expect(str(st["word"]).begins_with("WKRÓTCE") and str(st["tag"]) == "", "slot %d's day 8: '%s'" % [slot + 1, st["word"]])
			else:
				_expect(str(st["word"]) == str(CityLife.TRENDS[int(st["trend"])][0]), "slot %d's word" % [slot + 1])
			if want == 1:
				_expect(int(st["trend"]) != last_trend, "slot %d kept its trend into a new cycle" % [slot + 1])
				last_trend = int(st["trend"])
			_expect(str(st["tag"]) == ("new" if want == 1 else ("queue" if want <= 5 else ("gone" if want < 8 else ""))), "slot %d day %d's tag '%s'" % [slot + 1, want, st["tag"]])
	# The shop's hours.
	var q1 := CityLife.slot_state(0, 0)
	_expect(CityLife.slot_queue(q1, 7.9) == 0 and CityLife.slot_queue(q1, 8.0) == 30 and CityLife.slot_queue(q1, 20.0) == 0 and CityLife.slot_queue(q1, 12.0, 0.5) == 15,
			"slot queue by hour and amount")
	# The three slots differ (offsets 0, 2, 4) except in the sync cycle, where all are on day 1 (E19).
	var syncs: Array[int] = []
	for days in range(0, 8 * 30):
		if CityLife.all_new(days):
			syncs.append(days)
	_expect(syncs.size() == 2 and syncs[0] == 8 * (CityLife.SYNC_EVERY - 1) and syncs[1] == 8 * (2 * CityLife.SYNC_EVERY - 1),
			"all three new on days %s (want one day every %d cycles)" % [syncs, CityLife.SYNC_EVERY])
	# Without Live: a trend lives four sessions (days 1, 4, 6, 8), then the next one.
	var seen: Array[int] = []
	for n in 8:
		seen.append(int(CityLife.slot_state(CityLife.session_days(n), 0)["day"]))
	_expect(seen == [1, 4, 6, 8, 1, 4, 6, 8], "slot 1's days over eight sessions: %s" % [seen])
	_expect(int(CityLife.slot_state(CityLife.session_days(4), 0)["trend"]) != int(CityLife.slot_state(CityLife.session_days(0), 0)["trend"]),
			"the fifth session kept the trend")
	# The job is offered on days 1-7 in the shop's hours only.
	_expect(TrendJob.offers(CityLife.slot_state(0, 0), 12.0) and not TrendJob.offers(CityLife.slot_state(7, 0), 12.0)
			and not TrendJob.offers(CityLife.slot_state(0, 0), 21.0), "the job's offers")


# 4. -------------------------------------------------------------------------------------------

func _check_pay() -> void:
	var a := TrendJob.pay(2000.0, 3, true)
	_expect(int(a["base"]) == 41 and int(a["tip"]) == 10 and int(a["zl"]) == 51 and int(a["respect"]) == 15 and not bool(a["out"]),
			"pay 2 km on day 3: %s (want 41 + 10 tip, 15 respect)" % a)
	var b := TrendJob.pay(2000.0, 3, false)
	_expect(int(b["zl"]) == 21 and int(b["tip"]) == 0 and int(b["respect"]) == 0, "late: %s (want half of 41, no tip)" % b)
	for day in [6, 7]:
		var c := TrendJob.pay(2000.0, day, true)
		_expect(int(c["tip"]) == 0 and int(c["zl"]) == 41 and bool(c["out"]), "day %d: %s (want no tip: to już niemodne)" % [day, c])
	var d := TrendJob.pay(500.0, 1, true)
	_expect(int(d["zl"]) == 25 + 4 + 10, "pay 500 m: %s" % d)
	# The day-6 joke is a `viral` line for `late`.
	var lines: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var found := false
	if lines is Dictionary:
		for l: Array in (lines as Dictionary).get("viral", []):
			if l.size() > 2 and str((l[2] as Dictionary).get("only", "")) == "late" and "niemodne" in str(l[0]):
				found = true
	_expect(found, "no `viral` line for `late` (to już niemodne)")
	_summary["pay"] = "%d zł on time, %d late, %d on day 6" % [int(a["zl"]), int(b["zl"]), int(TrendJob.pay(2000.0, 6, true)["zl"])]


# 5. -------------------------------------------------------------------------------------------

func _check_zajac() -> void:
	# Beside the club at 12 km/h (3.33 m/s), steps of 0.5 s: 600 m in 360 steps.
	var mem := {}
	var fired := -1
	for i in 400:
		if CityLife.zajac_step(mem, 10.0, 12.0, 12.0 / 3.6 * 0.5, 0.5):
			fired = i
			break
	_expect(fired >= 355 and fired <= 361, "the Zając at 12 km/h fired at step %d (want ~360: 600 m)" % fired)
	for row: Array in [[10.0, 20.0, "too fast"], [10.0, 6.0, "too slow"], [30.0, 12.0, "too far"]]:
		var m := {}
		var any := false
		for i in 800:
			any = any or CityLife.zajac_step(m, row[0], row[1], row[1] / 3.6 * 0.5, 0.5)
		_expect(not any, "the Zając fired %s" % row[2])
	# A short gap (a lamp post, 1.5 s) keeps the metres; a long one (3 s) starts again.
	var g := {}
	for i in 200:
		CityLife.zajac_step(g, 10.0, 12.0, 1.67, 0.5)
	for i in 3:
		CityLife.zajac_step(g, 40.0, 12.0, 1.67, 0.5)
	_expect(float(g["m"]) > 300.0, "a 1.5 s gap lost the metres: %.0f" % float(g["m"]))
	for i in 7:
		CityLife.zajac_step(g, 40.0, 12.0, 1.67, 0.5)
	_expect(float(g["m"]) == 0.0, "a 3.5 s gap kept the metres: %.0f" % float(g["m"]))


# 6. -------------------------------------------------------------------------------------------

func _check_fat_thursday() -> void:
	# Easter 2026-04-05, 2027-03-28, 2028-04-16: Fat Thursday 52 days before.
	for row: Array in [[2026, 20260212], [2027, 20270204], [2028, 20280224]]:
		_expect(EggBook.fat_thursday(row[0]) == int(row[1]), "Fat Thursday %d: %d (want %d)" % [row[0], EggBook.fat_thursday(row[0]), row[1]])
	_expect(CityLife.fat_queue(true, 20260212, 10.0) == CityLife.FAT_QUEUE, "Lukrownia's queue on Fat Thursday")
	_expect(CityLife.fat_queue(true, 20260212, 19.0) == 0 and CityLife.fat_queue(true, 20260212, 5.0) == 0, "Lukrownia's queue out of hours")
	_expect(CityLife.fat_queue(true, 20260213, 10.0) == 0 and CityLife.fat_queue(false, 20260212, 10.0) == 0 and CityLife.fat_queue(true, 0, 10.0) == 0,
			"Lukrownia's queue on another day or without Live / --date")
	_summary["fat"] = "2026-02-12, 2027-02-04, 2028-02-24"


# 7. -------------------------------------------------------------------------------------------

func _state(at: Vector2, extra: Dictionary) -> Dictionary:
	var s := {"pos": Vector3(at.x + 3.0, 0.0, at.y), "kmh": 0.0, "flying": false, "alt": 0.0, "roof": 0.0, "look": "Day",
			"hour": 14.0, "weekday": 5, "month": 7, "live": false, "sun": 30.0, "rain": false, "station": "", "date": 0,
			"roadworks": "", "crowds": {}}
	for k in extra:
		s[k] = extra[k]
	return s


func _check_eggs(nb: Notebook) -> void:
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var book: EggBook = EggBook.new()
	book.wallet = wallet
	root.add_child(book)
	if not book.load_eggs():
		problems.append("no eggs.json")
		return
	var places := {}
	for p: Dictionary in nb.places:
		places[str(p["id"])] = p["at"]
	book.setup(places, {}, {})
	for id in ["e16", "e18", "e19", "e20", "e27", "e28", "e29", "e30"]:
		_expect(book.by_id.has(id) and not book.eggs[book.by_id[id]].has("waits"), "%s still waits" % id)
	# Loop jobs-2: the armchair man is built: E34 is an event egg now.
	_expect(not book.eggs[book.by_id["e34"]].has("waits"), "e34 (the armchair) still waits")
	# Events: [id, a state that misses, a state that meets].
	var ev: Array = [
		["e16", {"hour": 22.0}, {"hour": 10.0}],
		["e28", {"hour": 23.0}, {"hour": 8.0}],
		["e29", {"hour": 19.2, "weekday": 4}, {"hour": 19.2, "weekday": 3}],
		["e18", {}, {}],
		["e19", {}, {}],
		["e34", {}, {}],
	]
	for row: Array in ev:
		var id: String = row[0]
		var at: Vector2 = book.eggs[book.by_id[id]]["at"]
		var before := wallet.respect
		var want := int((book.eggs[book.by_id[id]].get("reward", {}) as Dictionary).get("respect", 0))
		if not (row[1] as Dictionary).is_empty():
			_expect(not book.fire(id, _state(at, row[1])), "%s fired without its conditions" % id)
		# step() never fires an event egg, wherever the car is.
		var mem := {}
		for i in 20:
			_expect(not EggBook.step(book.eggs[book.by_id[id]], _state(at, row[2]), mem, 0.5), "%s fired from step()" % id)
		_expect(book.fire(id, _state(at, row[2])), "%s didn't fire on its moment" % id)
		_expect(not book.fire(id, _state(at, row[2])) and wallet.respect - before == want, "%s: +%d respect (want %d, once)" % [id, wallet.respect - before, want])
	# Crowd eggs through step(): [id, extra state, the crowd level, a level that isn't enough].
	var cases: Array = [
		["e27", {"hour": 10.0}, {"influencer": 1.0}, {"influencer": 0.0}],
		["e30", {"hour": 10.0, "weekday": 6}, {"hyrax": 1.0}, {}],
		["e20", {"hour": 10.0, "weekday": 4, "live": true, "date": 20270204, "month": 2}, {"lukrownia": 1.0}, {}],
	]
	for row: Array in cases:
		var e: Dictionary = book.eggs[book.by_id[row[0]]]
		var at: Vector2 = e["at"]
		var t: Dictionary = e["trigger"]
		var path := func(s: Dictionary, i: int) -> Dictionary:
			var out := s.duplicate()
			if str(t["kind"]) == "lap":
				var r: Array = t["r"]
				var mid := (float(r[0]) + float(r[1])) * 0.5
				var p := at + Vector2(cos(i * 0.12), sin(i * 0.12)) * mid
				out["pos"] = Vector3(p.x, 0.0, p.y)
				out["kmh"] = 15.0
			elif str(t["kind"]) == "pass":
				out["kmh"] = 30.0
			return out
		var bad: Dictionary = _state(at, row[1])
		bad["crowds"] = row[3]
		var mem := {}
		var fired_bad := false
		for i in 300:
			fired_bad = fired_bad or EggBook.step(e, path.call(bad, i), mem, 0.5)
		_expect(not fired_bad, "%s fired without its crowd" % row[0])
		var good: Dictionary = _state(at, row[1])
		good["crowds"] = row[2]
		var fired := false
		mem = {}
		for i in 300:
			if EggBook.step(e, path.call(good, i), mem, 0.5):
				fired = true
				break
		_expect(fired, "%s never fired with its crowd" % row[0])
		var before := wallet.respect
		_expect(book.record(row[0]) and not book.record(row[0]), "%s recorded twice" % row[0])
		_expect(wallet.respect - before == int((e.get("reward", {}) as Dictionary).get("respect", 0)), "%s's reward" % row[0])
	# The rules behind the events: E18 (day 1, 4 and WKRÓTCE of one trend), E16's ball.
	var m18 := {}
	var hits: Array[int] = []
	for days in range(0, 24):
		if CityLife.e18_step(m18, CityLife.slot_state(days, 0)) and hits.is_empty():
			hits.append(days)
	_expect(hits == [7], "E18 on slot 1 seen every day: fired on day number %s (want 7: its WKRÓTCE)" % [hits])
	var m18b := {}
	var skip := false
	for days in [0, 1, 2, 7, 8, 10, 15]:
		skip = skip or CityLife.e18_step(m18b, CityLife.slot_state(days, 0))
	_expect(not skip, "E18 fired without day 4 of one trend")
	var mb := {}
	var ball := Vector3(0, 30, 0)
	var dog := Vector3(200, 0, 0)
	_expect(not CityLife.aport_step(mb, Vector3(200, 10, 0), 10.0, ball, dog), "E16 without the ball")
	_expect(not CityLife.aport_step(mb, Vector3(1, 31, 0), 31.0, ball, dog) and str(mb["state"]) == "carried", "E16: the ball picked up")
	_expect(not CityLife.aport_step(mb, Vector3(203, 40, 0), 40.0, ball, dog), "E16: dropped from 40 m")
	_expect(CityLife.aport_step(mb, Vector3(203, 12, 0), 12.0, ball, dog) and str(mb["state"]) == "home", "E16: the ball brought to the dog")
	_expect(not CityLife.aport_step(mb, Vector3(203, 12, 0), 12.0, ball, dog), "E16 twice")
	book.queue_free()
	wallet.queue_free()


# 8. -------------------------------------------------------------------------------------------

func _check_meshes() -> void:
	var dm := CityLife.dog_mesh()
	var tris := dm.surface_get_array_index_len(0) / 3 if dm.surface_get_array_index_len(0) > 0 else dm.surface_get_array_len(0) / 3
	_expect(tris <= 120, "a dog has %d triangles (want ≤ 120)" % tris)
	var bm := CityLife.bike_mesh()
	var btris := bm.surface_get_array_index_len(0) / 3 if bm.surface_get_array_index_len(0) > 0 else bm.surface_get_array_len(0) / 3
	_expect(btris <= 200, "a bike has %d triangles" % btris)
	_expect(dm.get_surface_count() == 1 and bm.get_surface_count() == 1, "a mesh with more than one surface (a draw call each)")
	_summary["tris"] = tris


## 9. Loop jobs-2: the armchair man's rules on synthetic days and a synthetic street.
func _check_armchair_rules() -> void:
	var days := 0
	for d in 600:
		days += int(CityLife.armchair_day(d))
	_expect(days >= 150 and days <= 250, "the armchair man out %d days of 600 (want about 200: 1 in 3)" % days)
	_expect(CityLife.armchair_day(77) == CityLife.armchair_day(77), "armchair_day isn't the same twice")
	# There and back on a 90 m way at 0.9 m/s: 100 s out, 100 s back.
	var a0 := CityLife.armchair_at(0.0, 90.0)
	var a1 := CityLife.armchair_at(50.0, 90.0)
	var a2 := CityLife.armchair_at(150.0, 90.0)
	var a3 := CityLife.armchair_at(200.0, 90.0)
	_expect(is_equal_approx(a0.x, 0.0) and a0.y > 0.0 and is_equal_approx(a1.x, 45.0) and a1.y > 0.0, "the armchair man's way out: %s %s" % [a0, a1])
	_expect(is_equal_approx(a2.x, 45.0) and a2.y < 0.0 and absf(a3.x) < 0.01, "the armchair man's way back: %s %s" % [a2, a3])
	# A straight street 600 m long through the place: the ends ARMCHAIR_HALF each way.
	var pieces := PackedVector2Array()
	for k in 31:
		pieces.append(Vector2(-300.0 + k * 20.0, 5.0))
	var ends := CityLife.armchair_ends(pieces, Vector2(0.0, 0.0))
	_expect(ends.size() == 2 and absf((ends[0] as Vector2).distance_to(ends[1]) - 2.0 * CityLife.ARMCHAIR_HALF) <= 45.0,
			"the armchair man's ends on a straight street: %s" % [ends])
	_expect(CityLife.armchair_ends(pieces, Vector2(0.0, 900.0)).is_empty(), "armchair ends with the street far from the place")
	var cm := Props.carried_armchair()
	var ctris := cm.surface_get_array_len(0) / 3
	_expect(cm.get_surface_count() == 1 and ctris <= 150, "the armchair: %d triangles, %d surfaces" % [ctris, cm.get_surface_count()])
	_summary["armchair"] = "%d of 600 days, %d tris" % [days, ctris]


func _check_city(nb: Notebook, data: Dictionary) -> void:
	var dlg := FakeDialogue.new()
	root.add_child(dlg)
	var life: Node3D = CityLife.new()
	life.dialogue = dlg
	life.clock = func() -> Dictionary: return now
	life.calendar = func() -> Dictionary: return cal
	life.focus = func() -> Vector3: return eye
	life.vehicle = func() -> Array: return veh
	life.trend_day_flag = 0
	root.add_child(life)
	life.set_process(false)
	life.setup(nb.places, data)
	var plac: Vector2 = Vector2.INF
	for p: Dictionary in nb.places:
		if str(p["id"]) == "plac_zbawiciela":
			plac = p["at"]
	eye = Vector3(plac.x, 0.0, plac.y)
	# The index is built in a worker thread: wait for it (no clock: by the condition).
	var waited := 0
	while life.get("_index_task") >= 0 and waited < 6000:
		if WorkerThreadPool.is_task_completed(life.get("_index_task")):
			break
		await process_frame
		waited += 1
	life._process(0.001)
	_expect(bool(life.get("_ready")), "the index never finished")
	var kolka: Dictionary = life.get("_kolka")
	_expect(not kolka.is_empty() and float(kolka["len"]) > 800.0, "Kolka has no route to Most Poniatowskiego")
	_expect(not (life.get("_docks") as Array).is_empty(), "no Rowerilo dock placed")
	if verbose and not kolka.is_empty():
		var kp: PackedVector2Array = kolka["pts"]
		var line := PackedStringArray()
		for i in range(0, kp.size(), maxi(1, kp.size() / 24)):
			line.append("%.0f,%.0f" % [kp[i].x, kp[i].y])
		print("  Kolka's route (%d points): %s" % [kp.size(), " ".join(line)])
	# 07:30 on a Friday at Plac Zbawiciela: the zone's walkers.
	now = {"hour": 7.5, "weekday": 5}
	for i in 20:
		life.tick(0.5)
	var dogs: Array = life.get("_dogs")
	var n_dogs := dogs.size()
	_expect(dogs.size() == CityLife.dog_count(7.5, true), "walkers at Plac Zbawiciela at 07:30: %d (want %d)" % [dogs.size(), CityLife.dog_count(7.5, true)])
	for d in dogs:
		_expect((d.p2 as Vector2).distance_to(plac) <= CityLife.NEAR_R, "a walker %.0f m from the view" % (d.p2 as Vector2).distance_to(plac))
	_check_horn(life, dlg)
	# The car parked among them: after the movers' steps none overlaps it.
	if not dogs.is_empty():
		var d0: Vector2 = dogs[0].d2
		veh = [Vector3(d0.x, 0.0, d0.y), 0.0, false, 0.0, 0.0]
		var over := 0
		for i in 200:
			life.call("_move", CityLife.MOVE_TICK)
			for m in life.get("_dogs"):
				over += int(CityLife.overlaps_car(m.p2, d0, 0.0)) + int(CityLife.overlaps_car(m.d2, d0, 0.0))
		_expect(over == 0, "walkers overlapped a parked car %d times in 10 s" % over)
		veh = [Vector3.INF, 0.0, false, 0.0, 0.0]
	# The tick's cost (20 ticks and 200 moves at the zone's busiest).
	var t0 := Time.get_ticks_usec()
	for i in 20:
		life.tick(0.5)
		for k in 10:
			life.call("_move", CityLife.MOVE_TICK)
	var per_s := (Time.get_ticks_usec() - t0) / 10.0
	# 11:00: the walkers go home (the ones off screen at once).
	now = {"hour": 11.0, "weekday": 5}
	var ftest := func(_p: Vector3, _h: float) -> bool: return false
	life.on_screen = ftest
	for i in 4:
		life.tick(0.5)
	var left: int = (life.get("_dogs") as Array).size()
	_expect(left == 0, "walkers at 11:00: %d (want 0)" % left)
	# Loop jobs-2: the armchair man on Mokotowska (forced out), the view on him: his guest, the chair.
	var arm: Dictionary = life.get("_arm")
	_expect(not arm.is_empty() and float(arm.get("len", 0.0)) > 150.0, "the armchair man has no way on Mokotowska (%s)" % [arm.get("len", "none")])
	var arm_note := "none"
	if not arm.is_empty():
		life.armchair_flag = true
		now = {"hour": 11.0, "weekday": 2}
		var pose: Array = life.armchair_pose()
		var ap: Vector3 = pose[0]
		var mok := Vector2.INF
		for p: Dictionary in nb.places:
			if str(p["id"]) == CityLife.ARMCHAIR_PLACE:
				mok = p["at"]
		_expect(mok != Vector2.INF and Vector2(ap.x, ap.z).distance_to(mok) <= CityLife.ARMCHAIR_HALF + 60.0,
				"the armchair man %.0f m from Mokotowska's place" % Vector2(ap.x, ap.z).distance_to(mok))
		eye = ap
		veh = [ap + Vector3(4.0, 0.0, 0.0), 10.0, false, 0.0, 0.0]
		var met0: int = life.met_armchair
		for i in 3:
			life.tick(0.5)
			for k in 4:
				life.call("_move", CityLife.MOVE_TICK)
		var chair: MeshInstance3D = life.get("_chair")
		_expect(chair.visible and chair.global_position.distance_to(life.armchair_pose()[0]) < 0.5, "the chair isn't on the man's head")
		_expect(int(life.get("_shown")) & CityLife.ARM_BIT != 0, "the armchair man isn't among the shown guests")
		_expect(int(life.met_armchair) > met0, "the car beside the armchair man wasn't counted")
		# Not his day, not forced: gone.
		life.armchair_flag = false
		var off_day := 0
		while CityLife.armchair_day(off_day):
			off_day += 1
		life.trend_day_flag = off_day
		veh = [Vector3.INF, 0.0, false, 0.0, 0.0]
		for i in 2:
			life.tick(0.5)
		_expect(not bool(life.get("_arm_on")), "the armchair man out on day %d (not his day)" % off_day)
		life.trend_day_flag = 0
		arm_note = "%.0f m" % float(arm["len"])
	_summary["armchair_city"] = arm_note
	# Far from everything (the Vistula's far side, 4 km out): nothing active, nothing drawn.
	eye = Vector3(5000.0, 0.0, 5000.0)
	now = {"hour": 7.5, "weekday": 5}
	for i in 4:
		life.tick(0.5)
	_expect(not bool(life.get("_active")), "city life active far from everything")
	_expect(not (life.get("_chair") as MeshInstance3D).visible, "the chair shown far from the view")
	# F, 2026-11-05: no kerb rider on a road with a cycle path beside it: a path 5 m off and parallel
	# counts, one crossing at right angles or 30 m off does not.
	var idx := CityLife.build_index([{"k": "cycle", "dk": -1, "w": 2.0, "p": [0.0, 5.0, 100.0, 5.0]}], [], Vector2.INF, Vector2.INF)
	_expect(CityLife.cycle_path_near(idx["cyc"], idx["cyc_grid"], Vector2(50.0, 0.0), Vector2.RIGHT, 9.0), "a parallel cycle path 5 m off not found")
	_expect(CityLife.cycle_path_near(idx["cyc"], idx["cyc_grid"], Vector2(50.0, 0.0), Vector2.LEFT, 9.0), "the path beside is direction-blind")
	_expect(not CityLife.cycle_path_near(idx["cyc"], idx["cyc_grid"], Vector2(50.0, 0.0), Vector2.DOWN, 9.0), "a crossing road counted as beside")
	_expect(not CityLife.cycle_path_near(idx["cyc"], idx["cyc_grid"], Vector2(50.0, 30.0), Vector2.RIGHT, 9.0), "a path 25 m off counted as beside")
	_summary["city"] = "%d walkers at Plac Zbawiciela 07:30, Kolka %.0f m, dock %d bikes, %.0f µs per game second" % [
			n_dogs, float(kolka.get("len", 0.0)), int((life.get("_docks") as Array)[0]["n"]) if not (life.get("_docks") as Array).is_empty() else 0, per_s]
	life.queue_free()
	dlg.queue_free()
