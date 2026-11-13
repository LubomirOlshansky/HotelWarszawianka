extends SceneTree
## The vintage-tram loop (docs/design/vision.md 8, egg E39): scripts/old_tram.gd's rules and the
## old set on trams.gd's real tracks, headless, from the committed map data (map/centrum.json:
## the lane graph, the tracks and platforms) and data/eggs.json; seeded, no clock of its own:
##   1. the window (Saturday and Sunday 09:00-19:00; with Live June-September only; the fixed
##      looks' clock: Day is Friday 14:00, Day from --clock=10 is Saturday) and one run an hour
##      (a seeded start in the first half hour, 25 minutes, the same twice);
##   2. the follow count on synthetic inputs (adds the set's metres within 40 m behind or beside,
##      holds farther out, not ahead of its nose nor in the helicopter, starts again past 80 m);
##   3. the look and the draw-call budget: two cars of one surface each (at most 1,600 vertices)
##      on the one actor material, a recruited tram showing at most 2 car meshes (a modern one 3) with no node
##      added, its meshes back on the way out;
##   4. a run on the real tracks: a scheduled run takes the tram out of sight, the car kept 20 m
##      behind it while it drives (lights, stops) finds E39 once (+30 respect) after 300 m; 100 m
##      back starts the count again; the run's end turns it modern out of sight.
## Prints "check_old_tram: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_old_tram.gd [-- --verbose]

const OldTram := preload("res://scripts/old_tram.gd")
const Trams := preload("res://scripts/trams.gd")
const Models := preload("res://scripts/models.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")


var problems: Array[String] = []
var verbose := false
var car := Vector3.ZERO
var now := {"hour": 11.0, "weekday": 6}


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_window(digest)
	_check_follow(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var g := LaneGraph.new(data["graph"], null)
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var trams: Trams = Trams.new()
	root.add_child(trams)
	trams.setup(g, map, data)
	trams.player_on_road = false
	_check_look(trams, digest)
	await _check_run(trams, g, digest)
	trams.free()
	map.free()
	if problems.is_empty():
		print("check_old_tram: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_old_tram: %d problems" % problems.size())
		quit(1)


func _check_window(digest: PackedStringArray) -> void:
	# [live, month, weekday, hour, want]
	var cases := [[false, 7, 6, 10.0, true], [false, 7, 7, 18.99, true], [false, 7, 6, 19.0, false],
			[false, 7, 6, 8.99, false], [false, 7, 5, 14.0, false], [false, 1, 6, 12.0, true],
			[true, 6, 6, 9.0, true], [true, 9, 7, 15.5, true], [true, 10, 6, 12.0, false], [true, 5, 7, 12.0, false],
			[true, 7, 1, 12.0, false], [true, 8, 6, 20.0, false], [true, 8, 7, 3.0, false]]
	for c: Array in cases:
		if OldTram.window(c[0], c[1], c[2], c[3]) != c[4]:
			problems.append("window %s: %s" % [c, OldTram.window(c[0], c[1], c[2], c[3])])
	# The fixed looks' clock (time_of_day.gd): Day is Friday 14:00; from --clock=10, Saturday 10:00.
	var day := TimeOfDay.look_clock("Day", 0.0)
	var sat := TimeOfDay.look_clock("Day", 0.0, 10.0)
	var dawn := TimeOfDay.look_clock("Dawn", 4.0)
	if OldTram.window(false, 7, int(day["weekday"]), float(day["hour"])):
		problems.append("window: on in the Day look's Friday 14:00")
	if not OldTram.window(false, 7, int(sat["weekday"]), float(sat["hour"])):
		problems.append("window: off on the Day look from --clock=10 (%s)" % sat)
	if not OldTram.window(false, 7, int(dawn["weekday"]), float(dawn["hour"])):
		problems.append("window: off 4 h after the Dawn look's Saturday 05:45 (%s)" % dawn)
	# One run an hour: a seeded start in [0, RUN_START), RUN minutes long, the same twice.
	var starts := {}
	var on_minutes := 0
	var hours := 0
	for key: int in [6, 7, 20260704, 20260705, 20260913]:
		for h in range(int(OldTram.DAY_FROM), int(OldTram.DAY_TO)):
			hours += 1
			var st := OldTram.run_start(key, h)
			if st != OldTram.run_start(key, h):
				problems.append("run %d/%d: not the same twice" % [key, h])
			if st < 0 or st >= OldTram.RUN_START:
				problems.append("run %d/%d starts at minute %d" % [key, h, st])
			starts[st] = true
			var n := 0
			for m in 60:
				n += int(OldTram.run_on(key, h + (m + 0.5) / 60.0))
			if n != int(OldTram.RUN):
				problems.append("run %d/%d: on %d minutes, want %d" % [key, h, n, int(OldTram.RUN)])
			on_minutes += n
	if starts.size() < 8:
		problems.append("runs: only %d different start minutes" % starts.size())
	digest.append("window Sat-Sun 09-19 (Live Jun-Sep), %d hours: one %d-min run each, %d start minutes" % [
			hours, int(OldTram.RUN), starts.size()])


func _check_follow(digest: PackedStringArray) -> void:
	var p := 0.0
	for k in 60:
		p = OldTram.follow_step(p, 20.0, -25.0, 4.0, false)
	if absf(p - 240.0) > 0.01:
		problems.append("follow: 60 ticks of 4 m 20 m behind: %.1f m, want 240" % p)
	var held := OldTram.follow_step(p, 60.0, -60.0, 4.0, false)
	var beside := OldTram.follow_step(p, 6.0, -10.0, 4.0, false)
	var ahead := OldTram.follow_step(p, 5.0, 8.0, 4.0, false)
	var flying := OldTram.follow_step(p, 10.0, -20.0, 4.0, true)
	var gone := OldTram.follow_step(p, 81.0, -81.0, 4.0, false)
	var edge := OldTram.follow_step(p, 80.0, -80.0, 4.0, false)
	if held != p or beside != p + 4.0 or ahead != p or flying != p or gone != 0.0 or edge != p:
		problems.append("follow: held %.0f, beside %.0f, ahead %.0f, flying %.0f, past 80 m %.0f, at 80 m %.0f (from %.0f)" % [
				held, beside, ahead, flying, gone, edge, p])
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(0, 10), Vector2(0, 21)])
	if absf(OldTram.body_gap(Vector2(5, 15), pts) - 5.0) > 0.01 or absf(OldTram.body_gap(Vector2(0, 41), pts) - 20.0) > 0.01:
		problems.append("follow: the gap to the body")
	digest.append("follow +within 40 m, hold to 80, reset past it")


func _check_look(trams: Trams, digest: PackedStringArray) -> void:
	var meshes := OldTram.vintage_meshes()
	if meshes.size() != 2 or OldTram.vintage_meshes()[0] != meshes[0]:
		problems.append("look: %d meshes (or made again)" % meshes.size())
		return
	var modern := Models.tram_mesh(true)
	var mv := (modern.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var vs := PackedStringArray()
	for m: ArrayMesh in meshes:
		var v := (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		vs.append(str(v))
		var box := m.get_aabb()
		if m.get_surface_count() != 1:
			problems.append("look: a car of %d surfaces" % m.get_surface_count())
		if box.size.x > 2.6 or box.size.z > Trams.CAR + 0.5 or box.size.y > 4.0 or box.position.y < 0.0:
			problems.append("look: a car's box %s" % box)
		# The phone's frame grows with draw calls, not vertices (DEVELOPMENT.md "Performance
		# budgets"): a cap against a runaway shape only.
		if v > 1600:
			problems.append("look: %d vertices (a modern car %d, the cap 1600)" % [v, mv])
	var nodes_before := _mesh_nodes(trams)
	var t: Trams.Tram = trams.trams[0]
	var before: Array = []
	for b in t.cars:
		before.append((b.get_child(0) as MeshInstance3D).mesh)
	trams.set_vintage(t, true, meshes, OldTram.CRUISE)
	trams._pose(t)
	var shown := 0
	for b in t.cars:
		if b.visible:
			shown += 1
			var mi := b.get_child(0) as MeshInstance3D
			if mi.material_override != Models.material() or not mi.mesh in meshes:
				problems.append("look: a shown car without the old mesh or the actor material")
	if shown != 2 or t.n_cars != 2 or absf(Trams.length_of(t) - (2.0 * Trams.CAR + Trams.JOINT)) > 0.01:
		problems.append("look: the old set shows %d cars (%d, %.1f m), want 2" % [shown, t.n_cars, Trams.length_of(t)])
	if _mesh_nodes(trams) != nodes_before:
		problems.append("look: mesh nodes %d -> %d" % [nodes_before, _mesh_nodes(trams)])
	trams.set_vintage(t, false)
	trams._pose(t)
	var back := 0
	for k in t.cars.size():
		back += int((t.cars[k].get_child(0) as MeshInstance3D).mesh == before[k] and t.cars[k].visible)
	if back != 3 or t.cruise != Trams.CRUISE:
		problems.append("look: %d of 3 modern cars back" % back)
	digest.append("2 cars of 1 surface (%s vertices, a modern cab car %d), shown 2 of 3 mesh nodes: -1 draw call" % [" / ".join(vs), mv])


func _mesh_nodes(trams: Trams) -> int:
	var n := 0
	for c in trams.find_children("*", "MeshInstance3D", true, false):
		n += 1
	return n


func _check_run(trams: Trams, g: LaneGraph, digest: PackedStringArray) -> void:
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var book: EggBook = EggBook.new()
	book.wallet = wallet
	root.add_child(book)
	if not book.load_eggs():
		problems.append("no data/eggs.json")
		return
	var e: Dictionary = book.eggs[book.by_id["e39"]]
	if e.has("waits") or str(e["trigger"].get("kind", "")) != "event" or int(e["reward"].get("respect", 0)) != 30:
		problems.append("e39: not a +30 event (%s)" % e)
	var old: OldTram = OldTram.new()
	old.trams = trams
	old.egg_book = book
	var start := OldTram.run_start(6, 11)
	now = {"hour": 11.0 + (start + 1.0) / 60.0, "weekday": 6}
	old.clock = func() -> Dictionary: return now
	old.calendar = func() -> Dictionary: return {"live": false, "month": 7, "date": 0}
	old.vehicle = func() -> Array: return [car, 30.0, false]
	old.focus = func() -> Vector3: return car
	old.probe = func() -> Dictionary: return {"pos": car, "hour": float(now["hour"]), "weekday": 6, "kmh": 30.0, "look": "Day"}
	old.log_on = verbose
	root.add_child(old)
	old.setup()
	old.set_process(false)
	# The view far from every tram: the run takes the one out of sight nearest the car.
	car = Vector3(-800.0, 0.0, 400.0)
	trams.view_at = Vector2(car.x, car.z)
	trams.view_reach = 1.0
	old.tick(0.5)
	if old.tram == null or not old.tram.vintage:
		problems.append("run: no set taken at minute %d" % (start + 1))
		return
	var t := old.tram
	var dt := 1.0 / 30.0
	var r0: int = wallet.respect
	var frames := 0
	var found_at := -1.0
	var reset_ok := false
	var stage := 0
	while frames < 30 * 400:
		frames += 1
		g.clock += dt
		trams._process(dt)
		if frames % 15 != 0:
			continue
		# The car 20 m behind the set's tail on its rails (stage 2: 100 m back).
		var back := Trams.length_of(t) + (20.0 if stage != 1 else 100.0)
		var p := trams.body_point(t, back)
		car = Vector3(p.x, 0.0, p.y)
		trams.view_at = Vector2(car.x, car.z)
		trams.view_reach = 300.0
		old.tick(0.5)
		if stage == 0 and wallet.respect > r0:
			found_at = old.followed
			stage = 1
		elif stage == 1:
			reset_ok = old.followed == 0.0
			stage = 2
		elif stage == 2 and old.followed >= 60.0:
			break
	var r1: int = wallet.respect
	var again := book.fire("e39", old.probe.call())
	if found_at < OldTram.FOLLOW_M or found_at > OldTram.FOLLOW_M + 10.0 or r1 - r0 != 30 or again or old.moments != 1:
		problems.append("run: E39 at %.0f m followed, +%d respect, again %s, %d moments (want once at 300 m, +30)" % [
				found_at, r1 - r0, again, old.moments])
	if not reset_ok:
		problems.append("run: 100 m back did not start the count again")
	if stage != 2 or old.followed < 60.0:
		problems.append("run: the set stopped (stage %d, %.0f m followed again after %d frames)" % [stage, old.followed, frames])
	# The run's end: still in sight it stays; out of sight it turns modern.
	now = {"hour": 11.0 + (start + OldTram.RUN + 1.0) / 60.0, "weekday": 6}
	old.tick(0.5)
	var stayed := old.tram == t and t.vintage
	trams.view_at = Vector2(1e6, 1e6)
	old.tick(0.5)
	if not stayed or old.tram != null or t.vintage or t.n_cars != 3:
		problems.append("run: at its end the set %s in sight, %s out of it" % ["stayed" if stayed else "did not stay",
				"still old" if t.vintage else "modern again"])
	digest.append("a run on the real tracks: E39 once at %.0f m (+%d), the count reset 100 m back, modern again out of sight (%d frames)" % [
			found_at, r1 - r0, frames])
	old.free()
	book.free()
	wallet.free()
