extends SceneTree
## Kibice (docs/design/city-life-satire.md 7): scripts/fans.gd's rules, layout and drawing, headless,
## from the committed map data (map/centrum.json: roads, buildings, footways) and data/dialogue.json:
##   1. the match evenings on synthetic clocks (Wednesday, Saturday and Sunday evenings out; a
##      Friday afternoon, a Monday and the small hours home) and --fans-now;
##   2. the chant's jump (never below the ground, at most JUMP), the smoke sticks' cycles (each lit
##      SMOKE_ON of SMOKE_CYCLE s, one of a group's two lit most of the time) and the puffs (rising,
##      growing then shrinking);
##   3. the real map: every group finds its pavement within SNAP m of its anchor and room for all
##      its fans, a drummer, two smoke holders and a kid; no fan on a road (ROAD_CLEAR from its edge)
##      or inside a building, every fan within 260 m of the stadium, none closer than GAP to another;
##   4. the meshes' budgets (the props family ≤ 1,000 vertices, a puff ≤ 150, the kit ≤ 20,000);
##   5. the lines: the groups and their tags, ≤ 70 characters in Polish, English on each, no real
##      brand (data/brand_denylist.json), no club named and nothing about rival fans or a fight;
##   6. a node on the real map with --fans-now: nothing drawn far from the stadium, every fan drawn
##      near it with the kit shown, a chant raising the scarves, the horn starting a chant and a
##      `honk` line, lines in a minute, the moves' cost;
##   7. match day: the phases on synthetic clocks (walkers in before kick-off, none during the
##      match, out after full time, a few late runners), every route found on the real walkways,
##      ending at its group, off the roads except at a zebra; walkers drawn walking in, then home
##      the other way after a win or a draw with its toast and lines;
##   8. making way for the car: `dodge_target` (out of a moving car's path, round a stopped one,
##      nothing for a car behind or well to the side), a walker stepping out of the way of a car
##      coming at it and back after, a group fan stepping off a car driven onto the pavement, and
##      the groups filing in during the match (MATCH_SHARE left outside, no smoke) and back out.
## Prints "check_fans: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_fans.gd [-- --verbose]

const Fans := preload("res://scripts/fans.gd")
const Fakes := preload("res://tools/fakes.gd")


var problems: Array[String] = []
var verbose := false
var now := {"hour": 18.0, "weekday": 6}
var eye := Vector3.ZERO
var car_at := Vector3.INF


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
	_check_motion()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_check_layout(data, digest)
	_check_meshes(digest)
	_check_lines(digest)
	_check_node(data, digest)
	_check_match_day(data, digest)
	_check_dodge(data, digest)
	if problems.is_empty():
		print("check_fans: OK (%s)" % "; ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("check_fans: %s" % p)
		quit(1)


# 1. -------------------------------------------------------------------------------------------

func _check_hours(digest: PackedStringArray) -> void:
	var on := [[3, 18.0], [3, 21.0], [6, 15.5], [6, 20.0], [7, 14.0], [7, 19.9]]
	var off := [[1, 18.0], [2, 19.0], [4, 18.0], [5, 14.0], [5, 20.0], [3, 12.0], [3, 21.5], [6, 1.5], [6, 22.0], [7, 21.0]]
	for c: Array in on:
		_expect(Fans.match_on(float(c[1]), int(c[0])), "no match on day %d at %.1f" % [c[0], c[1]])
	for c: Array in off:
		_expect(not Fans.match_on(float(c[1]), int(c[0])), "a match on day %d at %.1f" % [c[0], c[1]])
	_expect(Fans.group_count(24, 14.0, 5) == 0, "fans out on the Day look's Friday 14:00")
	_expect(Fans.group_count(24, 14.0, 5, 1.0, true) == 24, "--fans-now: not all out")
	_expect(Fans.group_count(24, 18.0, 6, 0.5) == 12, "--crowd=0.5 doesn't halve a group")
	var hours := 0.0
	for d in range(1, 8):
		for k in 96:
			hours += 0.25 if Fans.match_on(k * 0.25, d) else 0.0
	_expect(hours >= 15.0 and hours <= 20.0, "%.1f match hours a week (want 15-20)" % hours)
	digest.append("%.1f match hours a week" % hours)


# 2. -------------------------------------------------------------------------------------------

func _check_motion() -> void:
	var top := 0.0
	for i in 400:
		var y := Fans.jump_at(i * 0.0173, -1.0 + (i % 21) * 0.1)
		_expect(y >= 0.0, "a jump below the ground")
		top = maxf(top, y)
	_expect(top <= Fans.JUMP + 0.001 and top > Fans.JUMP * 0.8, "the jump peaks at %.2f m" % top)
	for ph: float in [0.0, 13.0, 60.0]:
		var lit := [0, 0]
		var any := 0
		for i in 750:
			var s := i * 0.1
			var a := Fans.smoke_lit(s, 0, ph)
			var b := Fans.smoke_lit(s, 1, ph)
			lit[0] += 1 if a else 0
			lit[1] += 1 if b else 0
			any += 1 if a or b else 0
		for k in 2:
			var share := float(lit[k]) / 750.0
			_expect(absf(share - Fans.SMOKE_ON / Fans.SMOKE_CYCLE) < 0.02, "stick %d lit %.0f%% of a cycle" % [k, share * 100.0])
		_expect(any >= 700, "both of a group's sticks out %.0f%% of the time" % (100.0 - any / 7.5))
	var a0: Array = Fans.puff_at(0.05, 0)
	var a1: Array = Fans.puff_at(0.5, 0)
	var a2: Array = Fans.puff_at(0.95, 0)
	_expect((a1[0] as Vector3).y > (a0[0] as Vector3).y and (a2[0] as Vector3).y > (a1[0] as Vector3).y, "the puffs don't rise")
	_expect(float(a1[1]) > float(a0[1]) and float(a1[1]) > float(a2[1]), "a puff doesn't grow and then shrink")
	_expect(float(a1[1]) <= Fans.PUFF_SIZE + 0.25, "a puff of %.2f m" % float(a1[1]))


# 3. -------------------------------------------------------------------------------------------

func _check_layout(data: Dictionary, digest: PackedStringArray) -> void:
	var obs := Fans.obstacles(data, Fans.STADIUM, 330.0)
	var foot := Fans.pavements(data, Fans.STADIUM, 330.0)
	_expect((obs[0] as Array).size() > 5 and (obs[1] as Array).size() > 3 and foot.size() > 10,
			"the stadium's surroundings: %d roads, %d buildings, %d footways" % [(obs[0] as Array).size(), (obs[1] as Array).size(), foot.size()])
	var sizes := PackedStringArray()
	for id: String in Fans.GROUPS:
		var spec: Dictionary = Fans.GROUPS[id]
		var n := int(spec["n"])
		var lay := Fans.layout(spec["at"], n, foot, obs[0], obs[1], hash(id))
		_expect(not lay.is_empty(), "%s: no pavement within %.0f m of its anchor" % [id, Fans.SNAP])
		if lay.is_empty():
			continue
		var slots: Array = lay["slots"]
		_expect(slots.size() >= n, "%s: room for %d of %d fans" % [id, slots.size(), n])
		var roles := {}
		for s: Array in slots:
			var p: Vector2 = s[0]
			roles[s[1]] = int(roles.get(s[1], 0)) + 1
			_expect(Fans.clear_at(p, obs[0], obs[1]), "%s: a fan at %.1f, %.1f on a road or in a building" % [id, p.x, p.y])
			_expect(p.distance_to(Fans.STADIUM) < 260.0, "%s: a fan %.0f m from the stadium" % [id, p.distance_to(Fans.STADIUM)])
			for o: Array in slots:
				if o != s and (o[0] as Vector2).distance_to(p) < Fans.GAP - 0.01:
					_expect(false, "%s: two fans %.2f m apart" % [id, (o[0] as Vector2).distance_to(p)])
					break
		_expect(int(roles.get("drum", 0)) == 1, "%s: %d drummers" % [id, int(roles.get("drum", 0))])
		_expect(int(roles.get("smoke", 0)) == 2, "%s: %d smoke holders" % [id, int(roles.get("smoke", 0))])
		_expect(int(roles.get("kid", 0)) == 1, "%s: %d kids" % [id, int(roles.get("kid", 0))])
		var face: Vector2 = lay["face"]
		var ban: Vector2 = lay["banner"]
		_expect((ban - (lay["at"] as Vector2)).dot(face) < 0.0, "%s: the banner isn't behind the fans" % id)
		_expect(Fans.clear_at(ban, obs[0], obs[1]), "%s: the banner on a road or in a building" % id)
		sizes.append("%s %d (%.0f m deep)" % [id, slots.size(), float(lay["back"])])
		if verbose:
			print("  %s at %.0f, %.0f facing %.2f, %.2f: %s" % [id, (lay["at"] as Vector2).x, (lay["at"] as Vector2).y, face.x, face.y, roles])
	digest.append("groups " + ", ".join(sizes))


# 4. -------------------------------------------------------------------------------------------

func _check_meshes(digest: PackedStringArray) -> void:
	var props := Fans.props_mesh()
	var pv := (props.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(props.get_surface_count() == 1 and pv <= 1000, "the props: %d surfaces, %d vertices" % [props.get_surface_count(), pv])
	var puff := Fans.puff_mesh()
	var uv := (puff.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(uv <= 150, "a puff of %d vertices" % uv)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Fans.kit_mesh(st, 4.0, 7.0, Fans.GROUPS["brama"]["banner"], [[Vector3(-5, 0, 1), "drum"], [Vector3(2, 2.25, 0), "smoke"]])
	var kit := st.commit()
	var kv := (kit.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(kv <= 20000 / 3, "one group's kit of %d vertices" % kv)
	digest.append("props %d, puff %d, kit %d vertices" % [pv, uv, kv])


# 5. -------------------------------------------------------------------------------------------

func _check_lines(digest: PackedStringArray) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = (deny["names"] as Array) + (deny["rejected"] as Array)
	# Colours only: no club named, nothing about rivals, no fight words (whole words, lower case).
	var never := ["legia", "legii", "legią", "polonia", "widzew", "lech", "wisła", "cracovia", "jagiellonia", "zgoda", "ustawka",
			"kibol", "kibole", "chuligan", "chuligani", "bić", "bijemy", "wróg", "wrogów", "kosa", "petarda", "raca w ręku",
			"hooligan", "fight", "enemy", "rivals"]
	var want := {"kibice": {"": 10, "chant": 5, "honk": 3, "car": 4, "kid": 3, "walk": 5, "late": 2, "win": 4, "draw": 3, "dodge": 4, "match": 4},
			"police_kibice": {"": 5}}
	var all_text := ""
	var total := 0
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
			total += 1
		for tag: String in want[g]:
			_expect(int(counts.get(tag, 0)) >= int(want[g][tag]), "%s has %d '%s' lines (want %d)" % [g, int(counts.get(tag, 0)), tag, want[g][tag]])
	for spec: Dictionary in Fans.GROUPS.values():
		for s: String in spec["banner"]:
			all_text += " " + s.to_lower()
	var rx := RegEx.new()
	for n: String in names + never:
		rx.compile("(^|[^\\p{L}])" + n.replace(".", "\\.") + "($|[^\\p{L}])")
		_expect(rx.search(all_text) == null, "a fans' line or banner says '%s'" % n)
	digest.append("%d lines" % total)


# 6. -------------------------------------------------------------------------------------------

func _check_node(data: Dictionary, digest: PackedStringArray) -> void:
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["x", "x"]
	root.add_child(dlg)
	var f := Fans.new()
	f.map = map
	f.dialogue = dlg
	f.force = true
	f.clock = func() -> Dictionary: return now
	f.focus = func() -> Vector3: return eye
	f.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(f)
	f.setup(data)
	# A Saturday evening after the match (the groups all out, nobody walking).
	now = {"hour": 20.0, "weekday": 6}
	_expect(f.groups.size() == Fans.GROUPS.size(), "%d of %d groups set up" % [f.groups.size(), Fans.GROUPS.size()])
	# Far: nothing.
	eye = Vector3(-3000, 0, -3000)
	f.tick(0.5)
	f.move(0.1)
	_expect(not f._fan_mmi.visible and not f._kit.visible and not f._puff_mmi.visible, "fans drawn 4 km from the stadium")
	# Near: every fan, the kit, some smoke.
	eye = Vector3(Fans.STADIUM.x, 0, Fans.STADIUM.y - 100.0)
	f.tick(0.5)
	f.move(0.1)
	var want := 0
	for g: Dictionary in f.groups:
		want += int(g["n"])
	_expect(f.near and f._kit.visible and f._fan_mm.visible_instance_count == want,
			"near the stadium: %d fans drawn (want %d), kit %s" % [f._fan_mm.visible_instance_count, want, f._kit.visible])
	_expect(f._puff_mm.visible_instance_count >= Fans.PUFFS, "no smoke near the stadium (%d puffs)" % f._puff_mm.visible_instance_count)
	# A chant: the scarves go up (a raised prop sits higher than a neck one).
	var g0: Dictionary = f.groups[0]
	g0["chant"] = 0.0
	g0["next"] = 0.0
	f.tick(0.5)
	_expect(float(g0["chant"]) > 0.0, "a group's timer ran out and it didn't sing")
	f.t += 0.11
	f.move(0.1)
	# The horn by a quiet group starts it singing, with a `honk` line.
	var g1: Dictionary = f.groups[1]
	g1["chant"] = 0.0
	g1["next"] = 99.0
	g1["honk_t"] = 0.0
	var before := dlg.said.size()
	var a1: Vector2 = g1["at"]
	f.honk(Vector3(a1.x, 0, a1.y + 5.0))
	_expect(float(g1["chant"]) > 0.0, "the horn by the %s group didn't start a chant" % g1["id"])
	var honked := false
	for i in range(before, dlg.said.size()):
		honked = honked or dlg.tags[i] == "honk"
	_expect(honked, "no honk line after the horn")
	# Lines in a minute at the gate.
	before = dlg.said.size()
	eye = Vector3((g0["at"] as Vector2).x, 0, (g0["at"] as Vector2).y)
	for i in 120:
		f.t += 0.5
		f.tick(0.5)
	_expect(dlg.said.size() - before >= 2, "the gate's fans said %d lines in a minute" % (dlg.said.size() - before))
	# The cost: the moves with every group near.
	var t0 := Time.get_ticks_usec()
	for i in 200:
		f.t += 0.1
		f.move(0.1)
	var us := float(Time.get_ticks_usec() - t0) / 200.0
	_expect(us < 2500.0, "a move costs %.0f µs" % us)
	digest.append("node: %d fans near, %d puffs, a move %.0f µs" % [want, f._puff_mm.visible_instance_count, us])
	f.queue_free()


# 7. -------------------------------------------------------------------------------------------

func _check_match_day(data: Dictionary, digest: PackedStringArray) -> void:
	# The phases: Saturday's window opens at 15:00, kick-off 16:30.
	var kick := 15.0 + Fans.KICK_AFTER
	_expect(Fans.phase_at(kick - 1.0, 6)[0] == "arrive", "no walkers an hour before kick-off")
	_expect(Fans.phase_at(kick + 0.5, 6)[0] == "match", "not the match half an hour after kick-off")
	_expect(Fans.phase_at(kick + Fans.FULL_TIME + 0.2, 6)[0] == "leave", "nobody going home after full time")
	_expect(Fans.phase_at(kick - 1.0, 5)[0] == "", "walkers on a Friday")
	_expect(Fans.phase_at(kick + Fans.FULL_TIME + Fans.LEAVE + 0.1, 6)[0] == "", "still walking home long after")
	for d: int in Fans.MATCHES:
		var w: Array = Fans.MATCHES[d]
		var k := float(w[0]) + Fans.KICK_AFTER
		_expect(k - Fans.ARRIVE >= float(w[0]) - 0.001, "day %d: walkers before the evening starts" % d)
		_expect(k + Fans.FULL_TIME + Fans.LEAVE <= float(w[1]) + 0.001, "day %d: walkers after the evening ends" % d)
	_expect(Fans.walk_density("arrive", 0.8) > Fans.walk_density("arrive", 0.1), "the stream doesn't grow towards kick-off")
	_expect(Fans.walk_density("arrive", 0.97) > 0.0 and Fans.running("arrive", 0.97) and not Fans.running("arrive", 0.5),
			"no late runners just before kick-off")
	_expect(Fans.walk_density("leave", 0.05) > 0.9 and Fans.walk_density("leave", 0.99) < 0.05, "the way home doesn't thin out")
	_expect(Fans.walk_density("match", 0.5) == 0.0, "walkers during the match")
	# The routes on the real map.
	# The streets (not the service ways: driveways and the bus stops' loop are crossed anywhere).
	var streets: Array = []
	for r: Dictionary in data.get("roads", []):
		if str(r.get("k", "")) == "service" or bool(r.get("bridge", false)):
			continue
		var flat: Array = r["p"]
		var pts := PackedVector2Array()
		var close := false
		for i in flat.size() / 2:
			pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
			close = close or pts[i].distance_to(Fans.STADIUM) < 750.0
		if close:
			streets.append([pts, float(r.get("w", 6.0)) * 0.5, str(r.get("name", ""))])
	var ways := Fans.walkways(data, Fans.STADIUM, 650.0)
	var zebras: Array = []
	for w: Array in ways:
		if bool(w[2]):
			zebras.append(w[0])
	var g := Fans.walk_graph(ways)
	var lens := PackedStringArray()
	for id: String in Fans.ROUTES:
		var spec: Dictionary = Fans.ROUTES[id]
		var to: Vector2 = Fans.GROUPS[spec["to"]]["at"]
		var pts := Fans.walk_route(g, spec["from"], to)
		_expect(not pts.is_empty(), "%s: no walkway route to the %s group" % [id, spec["to"]])
		if pts.is_empty():
			continue
		var l := Fans.path_length(pts)
		_expect(pts[0].distance_to(spec["from"]) < 30.0 and pts[pts.size() - 1].distance_to(to) < 30.0, "%s: the route misses its ends" % id)
		_expect(l > 100.0 and l <= Fans.ROUTE_MAX, "%s: a route of %.0f m" % [id, l])
		# Every metre on a walkway's ground: off the carriageways, except where it crosses at a zebra.
		var bad := 0
		for j in pts.size() - 1:
			var m := maxi(1, ceili(pts[j].distance_to(pts[j + 1])))
			for i in m:
				var q := pts[j].lerp(pts[j + 1], float(i) / m)
				if _on_carriageway(q, streets) and not _near_zebra(q, zebras):
					bad += 1
					if verbose and bad % 5 == 1:
						print("  %s on a street at %.1f, %.1f %s" % [id, q.x, q.y, _road_at(q, streets)])
		_expect(bad == 0, "%s: %d m of the route on a street away from a zebra" % [id, bad])
		lens.append("%s %.0f m" % [id, l])
		if verbose:
			var marks := PackedStringArray()
			for k in 5:
				var a: Array = Fans.along_route(pts, _cum(pts), l * (k + 0.5) / 5.0)
				marks.append("%.0f,%.0f" % [(a[0] as Vector2).x, (a[0] as Vector2).y])
			print("  %s: %s" % [id, " -> ".join(marks)])
	digest.append("routes " + ", ".join(lens))
	# A node: walking in, then home after a win and after a draw.
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["x", "x"]
	root.add_child(dlg)
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var f := Fans.new()
	f.map = map
	f.dialogue = dlg
	f.hud = hud
	f.clock = func() -> Dictionary: return now
	f.focus = func() -> Vector3: return eye
	f.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(f)
	f.setup(data)
	_expect(f.routes.size() == Fans.ROUTES.size(), "%d of %d routes set up" % [f.routes.size(), Fans.ROUTES.size()])
	now = {"hour": kick - 0.3, "weekday": 6}
	eye = Vector3(Fans.STADIUM.x, 0, Fans.STADIUM.y - 100.0)
	f.tick(0.5)
	f.move(0.1)
	_expect(f.phase == "arrive" and f._walk_mm.visible_instance_count > f.walker_count / 2,
			"before kick-off: %s, %d of %d walking" % [f.phase, f._walk_mm.visible_instance_count, f.walker_count])
	# They walk towards their group.
	var w0 := -1
	for i in f.walker_count:
		if f.w_show[i] == 1 and f.w_s[i] < float(f.routes[f.w_route[i]]["len"]) - 30.0:
			w0 = i
			break
	_expect(w0 >= 0, "no walker on its way in")
	if w0 >= 0:
		var gat: Vector2 = f.groups[int(f.routes[f.w_route[w0]]["to"])]["at"]
		var p0: Vector3 = f.walker_at(w0)
		for i in 60:
			f.t += 0.1
			f.move(0.1)
		var p1: Vector3 = f.walker_at(w0)
		var d0 := Vector2(p0.x, p0.z).distance_to(gat)
		var d1 := Vector2(p1.x, p1.z).distance_to(gat)
		_expect(p0.distance_to(p1) > 4.0 and p0.distance_to(p1) < 12.0, "a walker went %.1f m in 6 s" % p0.distance_to(p1))
		_expect(d1 < d0 + 1.0, "a walker going away from the gate before kick-off (%.0f -> %.0f m)" % [d0, d1])
	var before := dlg.said.size()
	for i in 120:
		f.t += 0.5
		f.tick(0.5)
	var walk_lines := 0
	for i in range(before, dlg.said.size()):
		walk_lines += 1 if dlg.tags[i] == "walk" or dlg.tags[i] == "car" else 0
	_expect(walk_lines >= 1, "the walkers said nothing in a minute")
	# The match: the walkers' way is empty once everyone is in.
	now = {"hour": kick + 0.6, "weekday": 6}
	f.tick(0.5)
	f.move(0.1)
	_expect(f.phase == "match" and f._walk_mm.visible_instance_count > 0, "the last walkers vanished at kick-off")
	for i in 3000:
		f.t += 0.1
		f.move(0.1)
	_expect(f.phase == "match" and f._walk_mm.visible_instance_count == 0, "walkers 5 minutes into the match (%d)" % f._walk_mm.visible_instance_count)
	# Full time, a win: the toast, faster chants, the walkers going home.
	f.force_result = "win"
	now = {"hour": kick + Fans.FULL_TIME + 0.05, "weekday": 6}
	f.tick(0.5)
	_expect(f.phase == "leave" and f.result == "win" and f.celebrating(), "no win at full time (%s, %s)" % [f.phase, f.result])
	_expect(hud.ambient.size() == 1 and str(hud.ambient[0]).contains("wygrana"), "no full-time toast after a win (%s)" % [hud.ambient])
	for i in 3000:
		f.t += 0.1
		f.move(0.1)
	_expect(f._walk_mm.visible_instance_count > f.walker_count / 3, "after full time only %d walking home" % f._walk_mm.visible_instance_count)
	# On the way home they walk away from the gate.
	var h0 := -1
	for i in f.walker_count:
		if f.w_show[i] == 1 and f.w_s[i] > 20.0 and f.w_s[i] < float(f.routes[f.w_route[i]]["len"]) - 30.0:
			h0 = i
			break
	if h0 >= 0:
		var gat: Vector2 = f.groups[int(f.routes[f.w_route[h0]]["to"])]["at"]
		var q0: Vector3 = f.walker_at(h0)
		for i in 60:
			f.t += 0.1
			f.move(0.1)
		var q1: Vector3 = f.walker_at(h0)
		_expect(Vector2(q1.x, q1.z).distance_to(gat) > Vector2(q0.x, q0.z).distance_to(gat) - 1.0, "a walker going back to the gate after full time")
	var tags := {}
	before = dlg.said.size()
	for i in 240:
		f.t += 0.5
		f.tick(0.5)
	for i in range(before, dlg.said.size()):
		tags[dlg.tags[i]] = true
	_expect(tags.has("win"), "no win lines on the way home (%s)" % [tags.keys()])
	# The next match ends in a draw.
	now = {"hour": kick + 0.6, "weekday": 6}
	f.tick(0.5)
	f.force_result = "draw"
	now = {"hour": kick + Fans.FULL_TIME + 0.05, "weekday": 6}
	f.tick(0.5)
	_expect(f.result == "draw" and not f.celebrating() and hud.ambient.size() == 2 and str(hud.ambient_en[1]).contains("draw"),
			"no draw at the next full time (%s, %s)" % [f.result, hud.ambient])
	# The cost of a move with the walkers out.
	var t0 := Time.get_ticks_usec()
	for i in 200:
		f.t += 0.1
		f.move(0.1)
	var us := float(Time.get_ticks_usec() - t0) / 200.0
	_expect(us < 3000.0, "a move with walkers costs %.0f µs" % us)
	digest.append("match day: %d walkers, a move %.0f µs" % [f.walker_count, us])
	f.queue_free()


## On a road's carriageway (more than half a metre inside its edge)?
static func _on_carriageway(q: Vector2, roads: Array) -> bool:
	for r: Array in roads:
		var pts: PackedVector2Array = r[0]
		var hw := float(r[1]) - 0.5
		for j in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(q, pts[j], pts[j + 1]).distance_to(q) < hw:
				return true
	return false


static func _near_zebra(q: Vector2, zebras: Array) -> bool:
	for z: PackedVector2Array in zebras:
		for j in z.size() - 1:
			if Geometry2D.get_closest_point_to_segment(q, z[j], z[j + 1]).distance_to(q) < 4.0:
				return true
	return false


static func _road_at(q: Vector2, roads: Array) -> String:
	for r: Array in roads:
		var pts: PackedVector2Array = r[0]
		for j in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(q, pts[j], pts[j + 1]).distance_to(q) < float(r[1]) - 0.5:
				return "(half width %.1f, %s)" % [float(r[1]), r[2] if r.size() > 2 else ""]
	return ""


static func _cum(pts: PackedVector2Array) -> PackedFloat32Array:
	var c := PackedFloat32Array([0.0])
	for j in range(1, pts.size()):
		c.append(c[j - 1] + pts[j - 1].distance_to(pts[j]))
	return c


# 8. -------------------------------------------------------------------------------------------

func _check_dodge(data: Dictionary, digest: PackedStringArray) -> void:
	# The rule: a car coming at 10 m/s along +x.
	var v := Vector2(10.0, 0.0)
	var ahead := Fans.dodge_target(Vector2(8.0, 0.5), Vector2.ZERO, v)
	_expect(ahead.y > 0.0 and absf(0.5 + ahead.y) >= Fans.DODGE_MISS and ahead.x == 0.0,
			"a fan 8 m ahead of the car, 0.5 m left of its path, steps %s" % ahead)
	_expect(Fans.dodge_target(Vector2(8.0, -0.3), Vector2.ZERO, v).y < 0.0, "a fan right of the path steps to the left")
	_expect(Fans.dodge_target(Vector2(8.0, 4.0), Vector2.ZERO, v) == Vector2.ZERO, "a fan 4 m to the side steps")
	_expect(Fans.dodge_target(Vector2(-6.0, 0.0), Vector2.ZERO, v) == Vector2.ZERO, "a fan behind the car steps")
	_expect(Fans.dodge_target(Vector2(40.0, 0.0), Vector2.ZERO, v) == Vector2.ZERO, "a fan 40 m ahead steps already")
	_expect(Fans.dodge_target(Vector2(1.0, 0.0), Vector2.ZERO, v).length() <= Fans.DODGE_MAX + 0.001, "a step longer than DODGE_MAX")
	var round := Fans.dodge_target(Vector2(1.0, 0.0), Vector2.ZERO, Vector2.ZERO)
	_expect(round.x > 0.0 and absf(1.0 + round.x - Fans.CAR_CLEAR) < 0.01, "a fan by a stopped car doesn't walk round it (%s)" % round)
	_expect(Fans.dodge_target(Vector2(4.0, 0.0), Vector2.ZERO, Vector2.ZERO) == Vector2.ZERO, "a fan 4 m from a stopped car steps")
	# The match's share outside.
	_expect(Fans.group_share("arrive", 0.5) == 1.0 and Fans.group_share("leave", 0.2) == 1.0 and Fans.group_share("", 0.0) == 1.0,
			"the groups thin out outside the match")
	_expect(Fans.group_share("match", 0.0) == 1.0 and absf(Fans.group_share("match", 0.5) - Fans.MATCH_SHARE) < 0.001
			and Fans.group_share("match", 0.999) > 0.9, "the match's share: %.2f, %.2f, %.2f" % [Fans.group_share("match", 0.0),
			Fans.group_share("match", 0.5), Fans.group_share("match", 0.999)])
	# A node before kick-off: a car comes at a walker head on at 12 m/s.
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["x", "x"]
	root.add_child(dlg)
	var f := Fans.new()
	f.map = map
	f.dialogue = dlg
	f.clock = func() -> Dictionary: return now
	f.focus = func() -> Vector3: return eye
	f.vehicle = func() -> Array: return [car_at, 43.0, false]
	root.add_child(f)
	f.setup(data)
	var kick := float(Fans.MATCHES[6][0]) + Fans.KICK_AFTER
	now = {"hour": kick - 0.3, "weekday": 6}
	eye = Vector3(Fans.STADIUM.x, 0, Fans.STADIUM.y - 100.0)
	car_at = Vector3.INF
	f.tick(0.5)
	f.move(0.1)
	var w := -1
	for i in f.walker_count:
		if f.w_show[i] == 1 and f.w_s[i] > 40.0 and f.w_s[i] < float(f.routes[f.w_route[i]]["len"]) - 60.0:
			w = i
			break
	_expect(w >= 0, "no walker to drive at")
	var closest := 99.0
	if w >= 0:
		var p0: Vector3 = f.walker_at(w)
		var fwd := Vector2(-sin(f.w_yaw[w]), -cos(f.w_yaw[w]))
		var c := Vector2(p0.x, p0.z) + fwd * 22.0
		for k in 40:
			c -= fwd * 1.2
			car_at = Vector3(c.x, 0, c.y)
			f.t += 0.1
			f.move(0.1)
			var b: Vector3 = f.walker_at(w)
			var shown := Vector2(b.x, b.z) + f.w_off[w]
			closest = minf(closest, shown.distance_to(c))
		_expect(closest >= Fans.DODGE_MISS - 0.4, "a walker let the car come within %.1f m" % closest)
		_expect(f.dodges >= 1, "no dodge counted")
		# The car gone: back on the footway.
		car_at = Vector3.INF
		for k in 60:
			f.t += 0.1
			f.move(0.1)
		_expect(f.w_off[w].length() < 0.05, "a walker still %.1f m off its way 6 s after the car" % f.w_off[w].length())
	var said_dodge := 0
	for i in dlg.said.size():
		said_dodge += 1 if dlg.tags[i] == "dodge" else 0
	# A car driven slowly through the gate's group.
	var g: Dictionary = f.groups[0]
	var a: Vector2 = g["at"]
	var along: Vector2 = g["along"]
	var slots: Array = g["slots"]
	var s0: Dictionary = slots[mini(5, slots.size() - 1)]
	var sp: Vector3 = s0["p"]
	var cg := Vector2(sp.x, sp.z) - along * 12.0
	var gclose := 99.0
	_expect(a.distance_to(Vector2(sp.x, sp.z)) < 40.0, "the group's fan far from its anchor")
	for k in 40:
		cg += along * 0.6
		car_at = Vector3(cg.x, 0, cg.y)
		f.t += 0.1
		f.move(0.1)
		var o: Vector2 = s0["off"]
		gclose = minf(gclose, (Vector2(sp.x, sp.z) + o).distance_to(cg))
	_expect(gclose >= Fans.DODGE_MISS - 0.4, "a group's fan let the car come within %.1f m" % gclose)
	car_at = Vector3.INF
	# The match: most go in, no smoke; back out just before full time.
	var full := f._fan_mm.visible_instance_count
	now = {"hour": kick + 0.9, "weekday": 6}
	f.tick(0.5)
	f.move(0.1)
	var inside := f._fan_mm.visible_instance_count
	_expect(inside > 0 and inside < full * 0.35 and f._puff_mm.visible_instance_count == 0,
			"during the match %d of %d fans outside, %d puffs" % [inside, full, f._puff_mm.visible_instance_count])
	var match_lines := 0
	var before := dlg.said.size()
	eye = Vector3(a.x, 0, a.y)
	for i in 240:
		f.t += 0.5
		f.tick(0.5)
	for i in range(before, dlg.said.size()):
		match_lines += 1 if dlg.tags[i] == "match" else 0
		_expect(dlg.tags[i] != "kid", "the kid talks outside during the match")
	_expect(match_lines >= 1, "no match lines from those left outside")
	now = {"hour": kick + Fans.FULL_TIME - 0.01, "weekday": 6}
	f.tick(0.5)
	f.move(0.1)
	_expect(f._fan_mm.visible_instance_count > inside * 2, "nobody back out by full time (%d)" % f._fan_mm.visible_instance_count)
	digest.append("dodge: walker %.1f m, group %.1f m, %d dodge lines; match: %d of %d outside" % [closest, gclose, said_dodge,
			inside, full])
	f.queue_free()
