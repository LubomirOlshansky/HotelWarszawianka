extends SceneTree
## Packs (docs/design/packs.md): scripts/packs.gd's rules, routes and drawing, and city_life.gd's big
## guys with tiny dogs, headless, from the committed map data (map/centrum.json: the footways and
## cycle paths) and data/dialogue.json:
##   1. the hours: each club's windows on synthetic clocks (the Day look's Friday 14:00 has two
##      running clubs, a cycling pack and a rave out; the Night look's 01:30 nothing), the raves'
##      cafés (one a weekday, two different ones at a weekend) and sizes, --packs-now;
##   2. the formation (rows of three and two) and the loop's head wrapping;
##   3. build_loop on a synthetic grid (out and back: the loop ends where it starts);
##   4. the real map: every club finds a loop of 600 m or more, a cycling pack mostly on cycle paths;
##   5. the meshes' budgets (the roadie family ≤ 200 triangles a shape, the booth ≤ 6,000 vertices);
##   6. the lines: the groups and their tags, ≤ 70 characters in Polish, no real brand
##      (data/brand_denylist.json), the parody gear names used;
##   7. a node on the real map with --packs-now: the packs drawn near the view (as many figures as
##      the clubs near, none far), the booths only near, the moves' cost;
##   8. the big guys: their scales, a slow car hears the `tiny` line once per 40 s.
## Prints "check_packs: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_packs.gd [-- --verbose]

const Packs := preload("res://scripts/packs.gd")
const CityLife := preload("res://scripts/city_life.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Fakes := preload("res://tools/fakes.gd")


var problems: Array[String] = []
var verbose := false
var now := {"hour": 14.0, "weekday": 5}
var eye := Vector3.ZERO


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_hours(digest)
	_check_formation()
	_check_grid()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_check_real_routes(data, digest)
	_check_meshes(digest)
	_check_lines(digest)
	await _check_node(data, digest)
	_check_big_guys(digest)
	if problems.is_empty():
		print("check_packs: OK (%s)" % "; ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("check_packs: %s" % p)
		quit(1)


# 1. -------------------------------------------------------------------------------------------

func _on_count(hour: float, weekday: int, specs: Dictionary) -> int:
	var n := 0
	for id: String in specs:
		if Packs.club_count(specs[id], hour, weekday) > 0:
			n += 1
	return n


func _check_hours(digest: PackedStringArray) -> void:
	var day := TimeOfDay.look_clock("Day", 0.0)
	_expect(_on_count(day["hour"], day["weekday"], Packs.RUN_CLUBS) >= 2, "the Day look (Friday 14:00) has fewer than two running clubs out")
	_expect(_on_count(day["hour"], day["weekday"], Packs.RIDE_CLUBS) >= 1, "the Day look has no cycling pack out")
	var raves := 0
	for id: String in Storefronts.CAFES:
		if Packs.rave_count(id, day["hour"], day["weekday"]) > 0:
			raves += 1
	_expect(raves == 1, "the Day look has %d raves (want 1)" % raves)
	var night := TimeOfDay.look_clock("Night", 0.0)
	var dark := _on_count(night["hour"], night["weekday"], Packs.RUN_CLUBS) + _on_count(night["hour"], night["weekday"], Packs.RIDE_CLUBS)
	for id: String in Storefronts.CAFES:
		dark += 1 if Packs.rave_count(id, night["hour"], night["weekday"]) > 0 else 0
	_expect(dark == 0, "the Night look (01:30) has %d packs or raves out" % dark)
	# Every club has hours on a weekday and at a weekend.
	for specs: Dictionary in [Packs.RUN_CLUBS, Packs.RIDE_CLUBS]:
		for id: String in specs:
			var wk := false
			var we := false
			for h in range(0, 96):
				wk = wk or Packs.club_on(specs[id]["hours"], h * 0.25, 2)
				we = we or Packs.club_on(specs[id]["hours"], h * 0.25, 6)
			_expect(wk and we, "%s has no weekday or no weekend hours" % id)
	# The raves: one café on a weekday, two different ones at a weekend; the hours and sizes.
	for wd in range(1, 8):
		var v := Packs.rave_venues(wd)
		_expect(v.size() == (2 if wd >= 6 else 1), "weekday %d has %d rave cafés" % [wd, v.size()])
		if v.size() == 2:
			_expect(v[0] != v[1], "weekday %d's two raves are the same café" % wd)
	var sat := Packs.rave_venues(6)[0]
	_expect(Packs.rave_count(sat, 10.0, 6) == Packs.RAVE_WEEKEND, "a Saturday rave at 10:00 has %d dancers" % Packs.rave_count(sat, 10.0, 6))
	_expect(Packs.rave_count(sat, 8.5, 6) == 0, "a Saturday rave is on at 08:30")
	_expect(Packs.rave_count(sat, 15.0, 6) == 0, "a rave is on at 15:00")
	var mon := Packs.rave_venues(1)[0]
	_expect(Packs.rave_count(mon, 8.0, 1) == Packs.RAVE_WEEK, "a Monday rave at 08:00 has %d dancers" % Packs.rave_count(mon, 8.0, 1))
	_expect(Packs.rave_count(mon, 9.0, 1, 0.5) == roundi(Packs.RAVE_WEEK * 0.5), "the Low tier doesn't halve the dancers")
	_expect(Packs.rave_count(mon, 3.0, 2, 1.0, true) == Packs.RAVE_WEEK, "--packs-now doesn't put every café on at any hour")
	_expect(Packs.club_count(Packs.RUN_CLUBS["tempo_na_kawe"], 3.0, 2, 1.0, true) == 24, "--packs-now doesn't send a club out at 03:00")
	digest.append("Day look: %d runs, %d rides, %d rave" % [_on_count(day["hour"], day["weekday"], Packs.RUN_CLUBS),
			_on_count(day["hour"], day["weekday"], Packs.RIDE_CLUBS), raves])


# 2. -------------------------------------------------------------------------------------------

func _check_formation() -> void:
	_expect(Packs.slot_of("run", 0) == Vector2(0.0, Packs.COLS_RUN[0]), "the first runner isn't at the head's left")
	_expect(is_equal_approx(Packs.slot_of("run", 3).x, Packs.ROW_RUN), "the fourth runner isn't in the second row")
	_expect(is_equal_approx(Packs.slot_of("ride", 2).x, Packs.ROW_RIDE), "the third rider isn't in the second row")
	_expect(is_equal_approx(Packs.head_at(100.0, 3.0, 10.0, 40.0), 30.0), "the head doesn't wrap round the loop")
	_expect(Packs.head_at(100.0, 3.0, 0.0, 1e6) < 100.0, "the head runs off the loop")


# 3. -------------------------------------------------------------------------------------------

func _check_grid() -> void:
	# A 3 × 3 grid of 50 m streets; the loop from one corner via the middle to the far one.
	var paths: Array = []
	for i in 3:
		var a := PackedVector2Array()
		var b := PackedVector2Array()
		for j in 3:
			a.append(Vector2(i * 50.0, j * 50.0))
			b.append(Vector2(j * 50.0, i * 50.0))
		paths.append([a, -1])
		paths.append([b, -1])
	var loop := Packs.build_loop(paths, [Vector2(0, 0), Vector2(50, 50), Vector2(100, 100)])
	_expect(not loop.is_empty(), "no loop on the grid")
	if loop.is_empty():
		return
	var pts: PackedVector2Array = loop["pts"]
	_expect(pts[0].distance_to(pts[pts.size() - 1]) < 0.1, "the grid's loop doesn't end where it starts")
	var run := 0.0
	for k in pts.size() - 1:
		run += pts[k].distance_to(pts[k + 1])
	_expect(is_equal_approx(run, 400.0), "the grid's loop is %.0f m (want 400: 200 out, 200 back)" % run)
	_expect(Packs.build_loop(paths, [Vector2(0, 0), Vector2(5000, 5000)]).is_empty(), "a loop to nowhere was found")


# 4. -------------------------------------------------------------------------------------------

func _check_real_routes(data: Dictionary, digest: PackedStringArray) -> void:
	var origin: Array = data.get("origin", [52.234, 21.024])
	var lens := PackedStringArray()
	for kind in ["run", "ride"]:
		var specs: Dictionary = Packs.RUN_CLUBS if kind == "run" else Packs.RIDE_CLUBS
		for id: String in specs:
			var via: Array = []
			for ll: Array in specs[id]["via"]:
				via.append(load("res://scripts/notebook.gd").project(origin, float(ll[0]), float(ll[1])))
			var t0 := Time.get_ticks_msec()
			var paths := Packs.paths_for(data.get("paths", []), kind, via)
			var loop := Packs.build_loop(paths, via)
			_expect(not loop.is_empty(), "%s finds no loop on the real map" % id)
			if loop.is_empty():
				continue
			var pts: PackedVector2Array = loop["pts"]
			var run := 0.0
			for k in pts.size() - 1:
				run += pts[k].distance_to(pts[k + 1])
			_expect(run >= 600.0, "%s's loop is only %.0f m" % [id, run])
			# Every via point is passed within 80 m (no leg skipped).
			for v: Vector2 in via:
				var best := INF
				for q in pts:
					best = minf(best, q.distance_to(v))
				_expect(best < 80.0, "%s's loop passes %.0f m from a via point" % [id, best])
			# A pack's share of corners on its own kind of path (riders: the cycle paths).
			var own := _share_on(data, pts, kind)
			if kind == "ride":
				_expect(own >= 0.5, "%s rides only %.0f %% on cycle paths" % [id, own * 100.0])
			lens.append("%s %.1f km, %.0f %% %s (%d ms)" % [id, run / 1000.0, own * 100.0, "cycle" if kind == "ride" else "foot",
					Time.get_ticks_msec() - t0])
	digest.append("loops: %s" % ", ".join(lens))


## The share of a loop's corners that are corners of a path of the pack's own kind.
func _share_on(data: Dictionary, pts: PackedVector2Array, kind: String) -> float:
	var keys := {}
	for p: Dictionary in data.get("paths", []):
		var k := str(p.get("k", ""))
		if (kind == "ride" and k in ["cycle", "cyclecross"]) or (kind == "run" and k in ["foot", "zebra"]):
			var flat: Array = p["p"]
			for i in flat.size() / 2:
				keys[Vector2i(roundi(float(flat[i * 2]) * 2.0), roundi(float(flat[i * 2 + 1]) * 2.0))] = true
	var hit := 0
	for q in pts:
		if keys.has(Vector2i(roundi(q.x * 2.0), roundi(q.y * 2.0))):
			hit += 1
	return float(hit) / maxf(pts.size(), 1.0)


# 5. -------------------------------------------------------------------------------------------

func _check_meshes(digest: PackedStringArray) -> void:
	var rm := Packs.roadie_mesh()
	var tris := rm.surface_get_array_index_len(0) / 3 if rm.get_surface_count() > 0 else 0
	# The family mesh holds one set of boxes (the shapes morph in the shader).
	_expect(rm.get_surface_count() == 1 and tris > 0 and tris <= 200, "the roadie mesh: %d surfaces, %d triangles" % [rm.get_surface_count(), tris])
	var bm := Packs.booth_mesh()
	var verts := (bm.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(bm.get_surface_count() == 1 and verts <= 6000, "the booth mesh: %d surfaces, %d vertices" % [bm.get_surface_count(), verts])
	digest.append("roadie %d tris, booth %d verts" % [tris, verts])


# 6. -------------------------------------------------------------------------------------------

func _check_lines(digest: PackedStringArray) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = (deny["names"] as Array) + (deny["rejected"] as Array)
	for n in ["canyon", "strava", "garmin", "cervélo"]:
		_expect(n in names, "brand_denylist.json lacks '%s'" % n)
	var want := {"run_club": {"": 10, "car": 3}, "peleton": {"": 10, "car": 3}, "coffee_rave": {"": 10, "dj": 3}, "dog_walkers": {"tiny": 5}}
	var all_text := ""
	for g: String in want:
		_expect(d.has(g), "dialogue.json has no '%s'" % g)
		var counts := {}
		for l: Array in d.get(g, []):
			var tag := ""
			if l.size() > 2:
				tag = str((l[2] as Dictionary).get("only", ""))
			counts[tag] = int(counts.get(tag, 0)) + 1
			_expect(str(l[0]).length() <= 70, "%s: a Polish line of %d characters" % [g, str(l[0]).length()])
			_expect(str(l[1]) != "", "%s: a line without English" % g)
			all_text += " " + str(l[0]).to_lower() + " " + str(l[1]).to_lower()
		for tag: String in want[g]:
			_expect(int(counts.get(tag, 0)) >= int(want[g][tag]), "%s has %d '%s' lines (want %d)" % [g, int(counts.get(tag, 0)), tag, want[g][tag]])
	var rx := RegEx.new()
	for n: String in names:
		rx.compile("(^|[^\\p{L}])" + n.replace(".", "\\.") + "($|[^\\p{L}])")
		_expect(rx.search(all_text) == null, "a packs line names '%s'" % n)
	for parody in ["wąwóz", "cegła", "garnek", "szpan", "specjał"]:
		_expect(all_text.contains(parody), "no line uses the parody '%s'" % parody)
	digest.append("lines run %d, peleton %d, rave %d" % [(d["run_club"] as Array).size(), (d["peleton"] as Array).size(), (d["coffee_rave"] as Array).size()])


# 7. -------------------------------------------------------------------------------------------

func _check_node(data: Dictionary, digest: PackedStringArray) -> void:
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["x", "x"]
	root.add_child(dlg)
	var p := Packs.new()
	p.map = map
	p.dialogue = dlg
	p.force = true
	p.clock = func() -> Dictionary: return now
	p.focus = func() -> Vector3: return eye
	p.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(p)
	p.setup(data, [])
	_expect(p.raves.size() == Storefronts.CAFES.size(), "%d of %d cafés got a rave booth" % [p.raves.size(), Storefronts.CAFES.size()])
	for r: Dictionary in p.raves:
		_expect((r["slots"] as Array).size() >= Packs.RAVE_WEEKEND, "%s has room for %d dancers" % [r["id"], (r["slots"] as Array).size()])
	var waited := 0
	while p._route_task >= 0 and waited < 600:
		await process_frame
		waited += 1
	_expect(p._route_task < 0, "the routes' thread didn't finish in 600 frames")
	# Far from everything: nothing drawn.
	eye = Vector3(5000, 0, 5000)
	p.tick(0.5)
	p.move_packs()
	p.dance()
	_expect(not p._run_mmi.visible and not p._ride_mmi.visible and not p._dance_mmi.visible, "packs drawn 5 km from the view")
	# At each club's head: its pack drawn, as many as it has.
	for c: Dictionary in p.clubs:
		if (c["route"] as Dictionary).is_empty():
			continue
		var h := Packs._route_point(c["route"], Packs.head_at(float(c["route"]["len"]), float(c["v"]), float(c["phase"]), p.t))
		eye = h
		p.tick(0.5)
		p.move_packs()
		var mm: MultiMesh = p._run_mm if c["kind"] == "run" else p._ride_mm
		var near := 0
		for o: Dictionary in p.clubs:
			if bool(o["near"]) and o["kind"] == c["kind"]:
				near += int(o["n"])
		_expect(bool(c["near"]) and mm.visible_instance_count == near, "%s at the view: %d drawn (want %d)" % [c["id"], mm.visible_instance_count, near])
		_expect(int(c["n"]) == int(c["max"]), "%s has %d out with --packs-now (want %d)" % [c["id"], c["n"], c["max"]])
	# At a rave: its booth shown, the DJ and the dancers drawn; the others' booths hidden if far.
	var r0: Dictionary = p.raves[0]
	eye = r0["at"]
	p.tick(0.5)
	p.dance()
	_expect((r0["booth"] as MeshInstance3D).visible, "the booth at the view is hidden")
	_expect(p._dance_mm.visible_instance_count >= int(r0["n"]) + 1, "the rave at the view draws %d figures" % p._dance_mm.visible_instance_count)
	# The lines: on screen near the view, a rave speaks within LINE_GAP.
	var before := dlg.said.size()
	for i in 120:
		p.t += 0.5
		p.tick(0.5)
	_expect(dlg.said.size() > before, "a rave at the view said nothing in a minute")
	# The cost: the moves with every club and rave near (the worst case), averaged.
	for c: Dictionary in p.clubs:
		c["near"] = not (c["route"] as Dictionary).is_empty()
	for r: Dictionary in p.raves:
		r["near"] = true
	var t0 := Time.get_ticks_usec()
	for i in 60:
		p.t += Packs.MOVE_TICK
		p.move_packs()
		p.dance()
	var us := (Time.get_ticks_usec() - t0) / 60.0
	_expect(us < 2500.0, "a move of every pack and rave takes %.0f µs" % us)
	digest.append("node: %d booths, the worst move %.0f µs, %d lines" % [p.raves.size(), us, dlg.said.size()])
	p.queue_free()
	map.queue_free()
	dlg.queue_free()
	await process_frame


# 8. -------------------------------------------------------------------------------------------

func _check_big_guys(digest: PackedStringArray) -> void:
	var big := CityLife.dog_scales(true)
	var plain := CityLife.dog_scales(false)
	_expect((big[0] as Vector3).y > 1.05 and (big[0] as Vector3).x > 1.2, "the big guy isn't big: %s" % big[0])
	_expect((big[1] as Vector3).y < (plain[1] as Vector3).y * 0.5, "the tiny dog isn't tiny: %s vs %s" % [big[1], plain[1]])
	_expect(CityLife.dog_count(13.0, false) > 0, "no dog walkers at lunchtime (the Day look)")
	digest.append("big guys %.2f×, tiny dogs %.2f×" % [(big[0] as Vector3).y, (big[1] as Vector3).y / (plain[1] as Vector3).y])
