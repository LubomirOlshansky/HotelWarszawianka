extends SceneTree
## F's scooter chaos (2026-11-19, docs/design/kukuryznik.md): the Kukuryźnik riders of
## scripts/city_life.gd and the walkers' leap (scripts/pedestrians.gd), headless, from the committed
## map data (map/centrum.json: the lane graph, the paths, the kebab pois placed as jobs.gd places them)
## and data/dialogue.json; seeded, no clock of its own (every hour is synthetic):
##   1. the rules: riders by the hour, two on one deck a quarter of the time, the gang at one stand in
##      three a night (none by day), the mob's hours and gap, who goes for an overtake; a wheelie keeps
##      its back wheel on the ground;
##   2. the mesh: four shapes, ≤ 204 triangles;
##   3. the words: every situation has lines, each Polish with English, a bubble's length, no real
##      brand (data/brand_denylist.json); KEBAB FM's two tags;
##   4. the real city at 17:00 by a stand: the rule's riders near the view, drawn in their own
##      MultiMesh; walkers ahead leap (a shout at most every SHOUT_GAP s); an encounter stops one
##      rider (still, in the wipeout or the phone shape) and lets him go;
##   5. the overtake: the car at 54 km/h with a kerb rider behind it: he speeds past it, says his line,
##      and is back to his speed when it stops;
##   6. the mob at 23:30: a column on one road, still together after 20 s; the gang at a stand with
##      its line for a car rolling by; KEBAB FM's mob line; the step's cost.
## Prints "check_kukuryznik: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_kukuryznik.gd [-- --verbose]

const CityLife := preload("res://scripts/city_life.gd")
const Notebook := preload("res://scripts/notebook.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Jobs := preload("res://scripts/jobs.gd")
const Fakes := preload("res://tools/fakes.gd")

## The rider situations and the radio's tags, each with at least this many lines.
const TAGS := ["overtake", "gleba", "mama", "mob", "gang", "near_miss"]
const RADIO_TAGS := ["kukuryznik", "kukuryznik_mob"]
const MIN_LINES := 2
const BUBBLE_MAX := 75

var problems: Array[String] = []
var verbose := false
var now := {"hour": 17.0, "weekday": 3}
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
	_check_mesh()
	_check_words()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("check_kukuryznik: PROBLEM (no map data or places.json)")
		quit(1)
		return
	await _check_city(book, data)
	book.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_kukuryznik: OK (rules; mesh %s; words %s; city %s; overtake %s; mob %s; gang %s; radio %s; cost %s)" % [
				_summary.get("mesh", "?"), _summary.get("words", "?"), _summary.get("city", "?"), _summary.get("overtake", "?"),
				_summary.get("mob", "?"), _summary.get("gang", "?"), _summary.get("radio", "?"), _summary.get("cost", "?")])
		quit(0)
	else:
		print("check_kukuryznik: PROBLEM")
		for p in problems:
			print("  - " + p)
		quit(1)


# 1. ------------------------------------------------------------------------------------------

func _check_rules() -> void:
	_expect(CityLife.scoot_count(10.0) == 1 and CityLife.scoot_count(17.0) == 4 and CityLife.scoot_count(23.0) == 3
			and CityLife.scoot_count(1.0) == 2 and CityLife.scoot_count(4.0) == 0, "riders by the hour")
	_expect(CityLife.scoot_count(17.0, 0.5) == 2, "riders at half the amount")
	_expect(CityLife.scoot_shape(0.1) == CityLife.SC_DUO and CityLife.scoot_shape(0.9) == CityLife.SC_SOLO, "the shape's roll")
	# The gang: one stand in three a night, another set the next day, none by day.
	var on := 0
	for st in 30:
		on += int(CityLife.gang_on(st, 12, 23.5))
		_expect(not CityLife.gang_on(st, 12, 13.0), "a gang at stand %d by day" % st)
		_expect(CityLife.gang_on(st, 12, 23.5) != CityLife.gang_on(st, 13, 23.5) or not CityLife.gang_on(st, 12, 23.5),
				"stand %d has the gang two nights running" % st)
	_expect(on == 10, "the gang at %d of 30 stands (want 10)" % on)
	_expect(CityLife.mob_due(1000.0, 0.0, 23.0) and CityLife.mob_due(1000.0, 0.0, 1.0), "the mob at night")
	_expect(not CityLife.mob_due(1000.0, 0.0, 15.0), "the mob by day")
	_expect(not CityLife.mob_due(1000.0, 900.0, 23.0), "the mob inside its gap")
	_expect(CityLife.wants_overtake(50.0, 0.95, true, 10.0), "an overtake behind a fast car")
	_expect(not CityLife.wants_overtake(15.0, 0.95, true, 10.0), "an overtake of a slow car")
	_expect(not CityLife.wants_overtake(50.0, -0.9, true, 10.0), "an overtake the other way")
	_expect(not CityLife.wants_overtake(50.0, 0.95, false, 10.0), "an overtake from ahead")
	_expect(not CityLife.wants_overtake(50.0, 0.95, true, 30.0), "an overtake from far behind")
	# A wheelie: the back wheel's contact (0, 0, 0.56) stays at the ground, the front up.
	var buf := PackedFloat32Array()
	buf.resize(16)
	CityLife.put_scoot(buf, 0, Vector3(3, 1, 4), 0.7, Color.WHITE, CityLife.SC_SOLO, true)
	var xf := Transform3D(Basis(Vector3(buf[0], buf[4], buf[8]), Vector3(buf[1], buf[5], buf[9]), Vector3(buf[2], buf[6], buf[10])),
			Vector3(buf[3], buf[7], buf[11]))
	var back := xf * Vector3(0, 0, 0.56)
	var front := xf * Vector3(0, 0, -0.52)
	_expect(absf(back.y - 1.0) < 0.06, "a wheelie's back wheel %.2f m off the ground" % (back.y - 1.0))
	_expect(front.y > 1.25, "a wheelie's front only %.2f m up" % (front.y - 1.0))
	CityLife.put_scoot(buf, 0, Vector3(3, 1, 4), 0.7, Color.WHITE, CityLife.SC_DUO, false)
	_expect(absf(buf[7] - 1.0) < 0.001 and absf(buf[15] - CityLife.SC_DUO) < 0.001, "an upright one's height and shape")


# 2. ------------------------------------------------------------------------------------------

func _check_mesh() -> void:
	var mesh := CityLife.kukuryznik_mesh()
	var tris := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		tris += idx.size() / 3 if not idx.is_empty() else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	_expect(mesh.get_surface_count() == 1, "the mesh has %d surfaces (want 1: one draw call)" % mesh.get_surface_count())
	_expect(tris > 0 and tris <= 204, "the Kukuryźnik has %d triangles (want ≤ 204)" % tris)
	_summary["mesh"] = "%d tris, 4 shapes" % tris


# 3. ------------------------------------------------------------------------------------------

func _check_words() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = (deny.get("names", []) as Array) + (deny.get("rejected", []) as Array)
	var by := {}
	var all: Array = []
	for l: Array in d.get("kukuryznik", []):
		var only := str((l[2] as Dictionary).get("only", "")) if l.size() > 2 and l[2] is Dictionary else ""
		by[only] = int(by.get(only, 0)) + 1
		all.append(l)
	for tag: String in TAGS:
		_expect(int(by.get(tag, 0)) >= MIN_LINES, "kukuryznik %s: %d lines (want %d)" % [tag, int(by.get(tag, 0)), MIN_LINES])
	var walkers: Array = d.get("kukuryznik_walker", [])
	var plain := 0
	for l: Array in walkers:
		all.append(l)
		plain += int(l.size() < 3)
	_expect(plain >= 5, "kukuryznik_walker: %d lines for any street (want 5)" % plain)
	var radio := {}
	for l: Array in d.get("radio_host", []):
		if l.size() > 2 and l[2] is Dictionary and str((l[2] as Dictionary).get("only", "")) in RADIO_TAGS:
			var tg := str((l[2] as Dictionary)["only"])
			radio[tg] = int(radio.get(tg, 0)) + 1
			_check_line(l, names, 140)
	for tg: String in RADIO_TAGS:
		_expect(int(radio.get(tg, 0)) >= MIN_LINES, "radio_host %s: %d lines (want %d)" % [tg, int(radio.get(tg, 0)), MIN_LINES])
	for l: Array in all:
		_check_line(l, names, BUBBLE_MAX)
	_summary["words"] = "%d rider, %d walker, %d radio lines" % [(d.get("kukuryznik", []) as Array).size(), walkers.size(),
			int(radio.get("kukuryznik", 0)) + int(radio.get("kukuryznik_mob", 0))]


func _check_line(l: Array, names: Array, most: int) -> void:
	_expect(l.size() >= 2 and str(l[0]) != "" and str(l[1]) != "" and str(l[0]) != str(l[1]), "a line without its English: %s" % [l])
	_expect(str(l[0]).length() <= most, "%d characters: %s" % [str(l[0]).length(), l[0]])
	for side in 2:
		var low := " " + str(l[side]).to_lower() + " "
		for n: String in names:
			var rx := RegEx.create_from_string("(^|[^\\p{L}])" + n + "($|[^\\p{L}])")
			_expect(rx.search(low) == null, "a real name (%s) in: %s" % [n, l[side]])


# 4.-6. ----------------------------------------------------------------------------------------

func _check_city(nb: Notebook, data: Dictionary) -> void:
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	var world := Node3D.new()
	root.add_child(world)
	var jobs: Jobs = Jobs.new()
	jobs.graph = graph
	jobs.map = map
	for p: Dictionary in data.get("pois", []):
		if str(p["k"]) == "kebab":
			jobs.call("_add_stand", p, null, world)
	var stands: Array = jobs.stand_frames()
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["…", "…"]
	root.add_child(dlg)
	var walkers := Fakes.Walkers.new()
	root.add_child(walkers)
	var radio := Fakes.Radio.new()
	root.add_child(radio)
	var life: Node3D = CityLife.new()
	life.dialogue = dlg
	life.walkers = walkers
	life.radio = radio
	life.graph = graph
	life.stands = stands
	life.clock = func() -> Dictionary: return now
	life.calendar = func() -> Dictionary: return cal
	life.focus = func() -> Vector3: return eye
	life.vehicle = func() -> Array: return veh
	life.trend_day_flag = 3
	root.add_child(life)
	life.set_process(false)
	life.setup(nb.places, data, 7311)
	var waited := 0
	while life.get("_index_task") >= 0 and waited < 6000:
		if WorkerThreadPool.is_task_completed(life.get("_index_task")):
			break
		await process_frame
		waited += 1
	life._process(0.001)
	_expect(bool(life.get("_ready")), "the index never finished")
	# 4. 17:00 by a stand with room: the rule's riders near the view, drawn.
	var si := 0
	while si < stands.size() - 1 and (life.call("_gang_spots_of", si) as Array).size() < 2:
		si += 1
	var st: Vector3 = stands[si][0]
	eye = st
	now = {"hour": 17.0, "weekday": 3}
	life.set("_enc_t", 1000.0)
	for k in 30:
		life.tick(0.5)
	var scoots: Array = life.get("_scoots")
	_expect(scoots.size() == CityLife.scoot_count(17.0), "riders at 17:00: %d (want %d)" % [scoots.size(), CityLife.scoot_count(17.0)])
	var kerb := 0
	for m in scoots:
		_expect((m.p2 as Vector2).distance_to(Vector2(st.x, st.z)) <= CityLife.NEAR_R, "a rider %.0f m from the view" % (m.p2 as Vector2).distance_to(Vector2(st.x, st.z)))
		_expect(float(m.v) >= CityLife.SCOOT_V.x - 0.01 and float(m.v) <= CityLife.SCOOT_V.y + 0.01, "a rider at %.1f m/s" % m.v)
		kerb += int(int(m.ke) >= 0)
	life.call("_move", CityLife.MOVE_TICK)
	var mm: MultiMesh = life.get("_sc_mm")
	_expect(mm.visible_instance_count == mini(scoots.size(), CityLife.KUK_CAP), "the Kukuryznik MultiMesh draws %d (want %d)" % [
			mm.visible_instance_count, scoots.size()])
	# The walkers ahead leap (the fake says one did every time): the shouts at most every SHOUT_GAP s.
	walkers.leap_answer = 1
	var shouts0: int = life.scoot_shouts
	for k in 120:
		life.t = 100.0 + k * 0.5
		life.tick(0.5)
	_expect(walkers.leaps > 0 and life.scoot_leaps > 0, "no walker leapt (%d asks)" % walkers.leaps)
	var shouts: int = life.scoot_shouts - shouts0
	_expect(shouts >= 1 and shouts <= ceili(60.0 / CityLife.SHOUT_GAP) + 1, "%d shouts in 60 s (want 1 to %d)" % [shouts, ceili(60.0 / CityLife.SHOUT_GAP) + 1])
	_expect(dlg.count("kukuryznik_walker", "") + dlg.count("kukuryznik_walker", "zone") >= 1, "no walker's shout said")
	walkers.leap_answer = 0
	# An encounter: one rider stops (wipeout or call), still, in its shape, then rides on.
	life.on_screen = func(_p: Vector3, _h: float) -> bool: return true
	var enc_ok := false
	for m in life.get("_scoots"):
		m.vis = true
	life.set("_enc_t", 0.0)
	life.tick(0.5)
	var stopped: Variant = null
	for m in life.get("_scoots"):
		if float(m.stun) > 0.0:
			stopped = m
	var enc_note := "none in range"
	if stopped != null:
		var p0: Vector2 = stopped.p2
		var sh: int = stopped.shape
		_expect(sh == CityLife.SC_GLEBA or sh == CityLife.SC_PHONE, "a stopped rider in shape %d" % sh)
		_expect(life.scoot_glebas + life.scoot_mamas == 1, "%d encounters (want 1)" % (life.scoot_glebas + life.scoot_mamas))
		_expect(dlg.count("kukuryznik", "gleba") + dlg.count("kukuryznik", "mama") >= 1, "the encounter's line not asked")
		for k in 30:
			life.call("_move", CityLife.MOVE_TICK)
		_expect((stopped.p2 as Vector2).distance_to(p0) < 0.01, "a stopped rider moved %.2f m" % (stopped.p2 as Vector2).distance_to(p0))
		for k in 200:
			life.call("_move", CityLife.MOVE_TICK)
		_expect(float(stopped.stun) <= 0.0 and int(stopped.shape) == int(stopped.base), "the rider never got up (stun %.1f)" % stopped.stun)
		enc_ok = true
		enc_note = "a %s" % ("wipeout" if sh == CityLife.SC_GLEBA else "call to mum")
	_expect(enc_ok, "no rider for an encounter in %d riders" % (life.get("_scoots") as Array).size())
	_summary["city"] = "stand %d at 17:00: %d riders (%d on kerbs), %d leap asks, %d shouts in 60 s, %s" % [si, scoots.size(), kerb,
			walkers.leaps, shouts, enc_note]
	# 5. The overtake: a kerb rider, the car 8 m ahead of him on his line at 15 m/s.
	_check_overtake(life, dlg, graph)
	# 6. 23:30: the mob and the gang.
	now = {"hour": 23.5, "weekday": 5}
	var day: int = life.days_now()
	var gi := -1
	for i in stands.size():
		if CityLife.gang_on(i, day, 23.5) and (life.call("_gang_spots_of", i) as Array).size() >= 2:
			gi = i
			break
	_expect(gi >= 0, "no stand with the gang tonight")
	if gi >= 0:
		eye = stands[gi][0]
	life.set("_mob_t", -10000.0)
	life.t = 20000.0
	var mob: Array = []
	for k in 40:
		life.t += 10.0
		life.tick(0.5)
		mob = life.get("_mob")
		if not mob.is_empty():
			break
	_expect(mob.size() >= CityLife.MOB_N.x and mob.size() <= CityLife.MOB_N.y, "the mob of %d (want %d-%d)" % [mob.size(), CityLife.MOB_N.x, CityLife.MOB_N.y])
	var spread := 0.0
	if not mob.is_empty():
		var e0: int = mob[0].ke
		for m in mob:
			_expect(int(m.ke) == e0, "the mob starts on more than one road")
		for k in 300:
			life.call("_move", CityLife.MOVE_TICK)
		for m in mob:
			spread = maxf(spread, (m.p2 as Vector2).distance_to(mob[0].p2))
		_expect(spread <= (mob.size() - 1) * CityLife.MOB_GAP_M + 15.0, "the mob split up: %.0f m between the first and another" % spread)
		_expect(dlg.count("kukuryznik", "mob") >= 1, "the mob's line not asked")
	_summary["mob"] = "%d riders, %.0f m from first to last after 20 s" % [mob.size(), spread]
	# The gang at stand gi: drawn standing after the riders; a car rolling by gets a line.
	var gang: Array = life.get("_gang")
	var at_gi := 0
	for g: Array in gang:
		at_gi += int((g[0] as Vector3).distance_to(stands[gi][0]) < 8.0) if gi >= 0 else 0
	_expect(at_gi >= 2, "the gang at stand %d: %d (want 2 or more)" % [gi, at_gi])
	life.call("_write_all", Vector2(eye.x, eye.z), Vector2.INF)
	var movers: int = (life.get("_scoots") as Array).size() + (life.get("_mob") as Array).size()
	var buf: PackedFloat32Array = life.get("_sc_buf")
	if movers < CityLife.KUK_CAP and not gang.is_empty():
		_expect(absf(buf[movers * 16 + 15] - CityLife.SC_PHONE) < 0.01, "the gang drawn in shape %.1f (want the stop's)" % buf[movers * 16 + 15])
	if not gang.is_empty():
		var gp: Vector3 = gang[0][0]
		veh = [gp + Vector3(3, 0, 0), 10.0, false, 0.0, 0.0, Vector3(2.8, 0, 0)]
		life.set("_gang_t", -1000.0)
		life.tick(0.5)
		_expect(dlg.count("kukuryznik", "gang") >= 1, "no gang line for a car rolling by")
		veh = [Vector3.INF, 0.0, false, 0.0, 0.0]
	_summary["gang"] = "%d at stand %d" % [at_gi, gi]
	# KEBAB FM: the radio on, the mob seen, its gap passed: the mob's line.
	radio.station = 0
	dlg.line_notes["radio_host:kukuryznik_mob"] = {"only": "kukuryznik_mob"}
	dlg.line_notes["radio_host:kukuryznik"] = {"only": "kukuryznik"}
	life.set("_seen_mob", true)
	life.set("_sc_radio_t", -100000.0)
	var said0 := radio.said.size()
	life.tick(0.5)
	_expect(radio.said.size() == said0 + 1 and life.scoot_radio >= 1, "KEBAB FM said nothing on the mob")
	_expect(dlg.count("radio_host", "kukuryznik_mob") >= 1, "KEBAB FM didn't ask for the mob's line")
	life.tick(0.5)
	_expect(radio.said.size() == said0 + 1, "KEBAB FM spoke twice inside its gap")
	_summary["radio"] = "%d line(s)" % (radio.said.size() - said0)
	# The cost: 20 ticks and 200 moves (10 game seconds) at the busy hour.
	now = {"hour": 17.0, "weekday": 3}
	eye = st
	var t0 := Time.get_ticks_usec()
	for i in 20:
		life.tick(0.5)
		for k in 10:
			life.call("_move", CityLife.MOVE_TICK)
	_summary["cost"] = "%.0f µs per game second for all of city life" % ((Time.get_ticks_usec() - t0) / 10.0)
	if verbose:
		print("kukuryznik: %s" % life.scoot_summary())
	life.queue_free()
	dlg.queue_free()
	walkers.queue_free()
	radio.queue_free()
	world.queue_free()
	map.queue_free()
	jobs.free()
	await process_frame


## A kerb rider, the car 8 m ahead of him on his line going his way at 15 m/s (54 km/h): he goes
## for it, passes it, says his line; with the car stopped he is back to his own speed.
func _check_overtake(life: Node3D, dlg: Fakes.Dialogue, graph: LaneGraph) -> void:
	var m: Variant = null
	for k in 40:
		m = life.call("_spawn_kerb", Vector2(eye.x, eye.z), "scoot")
		if m != null and float(m.length) > 80.0:
			break
		m = null
	_expect(m != null, "no kerb road for the overtake")
	if m == null:
		return
	m.s = 5.0
	m.vis = true
	life.call("_place_mover", m)
	(life.get("_scoots") as Array).append(m)
	var own: float = m.v
	var car_s: float = 13.0
	var passed := false
	var top := 0.0
	for k in 80:
		var pts: PackedVector2Array = m.pts
		var cum: PackedFloat32Array = m.cum
		if car_s > float(m.length) - 2.0:
			break
		var car2: Vector2 = CityLife._point(pts, cum, car_s, -2.6)
		var dir: Vector2 = (CityLife._point(pts, cum, car_s + 1.0, -2.6) - car2).normalized()
		veh = [Vector3(car2.x, 0, car2.y), 54.0, false, 0.0, 0.0, Vector3(dir.x, 0, dir.y) * 15.0]
		life.call("_overtake", m, car2, dir * 15.0, 54.0)
		top = maxf(top, float(m.v))
		if verbose and k % 10 == 0:
			print("  overtake: s %.1f car %.1f v %.1f boost %.1f" % [m.s, car_s, m.v, m.boost])
		if float(m.s) > car_s + 5.0:
			passed = true
			break
		life.call("_move", CityLife.MOVE_TICK)
		car_s += 15.0 * CityLife.MOVE_TICK
	_expect(top > 15.0 and top <= CityLife.SCOOT_TOP, "the overtake's top speed %.1f m/s (want over the car's 15)" % top)
	_expect(passed, "the rider never got past the car (%.0f m of road)" % m.length)
	_expect(bool(m.said) and dlg.count("kukuryznik", "overtake") >= 1, "no overtake line")
	life.call("_overtake", m, m.p2 - Vector2(3, 0), Vector2.ZERO, 0.0)
	_expect(absf(float(m.v) - own) < 0.01 and float(m.boost) == 0.0, "back to %.1f m/s after the car stopped (want %.1f)" % [m.v, own])
	(life.get("_scoots") as Array).erase(m)
	veh = [Vector3.INF, 0.0, false, 0.0, 0.0]
	_summary["overtake"] = "%.0f km/h past a car at 54" % (top * 3.6)
