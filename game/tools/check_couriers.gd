extends SceneTree
## Loop couriers (docs/design/parodies.md 4.2): the Pędzik couriers waiting at the kebab stands at
## night, the riders on the road's kerb edge and their dodge (scripts/city_life.gd), headless, from
## the committed map data (map/centrum.json: the lane graph, the paths, the kebab pois placed as
## jobs.gd places them) and data/places.json; seeded, no clock of its own (every hour is synthetic):
##   1. the rules: the kerb riders' counts (3 by day, 5 at night, × the amount), 1 or 2 couriers
##      waiting by each stand at night and none by day (the same night always the same), the roads
##      a kerb rider takes;
##   2. the dodge on synthetic inputs: the closest approach over the next second, a swerve within
##      4 m where there is room, a hop where there is none, nothing for a car passing wide, going
##      away or still far; the hop's 0.3 s arc;
##   3. the near miss's line: at most one in 30 s (10 in 300 s of near misses every 2 s at 30 km/h,
##      none under 10 km/h), through the real function;
##   4. the real city at night by a stand: its couriers (as many as its rule and free spots give, by
##      the kiosk, off the lanes), drawn after the riders in the Pedzik MultiMesh with the standing
##      shape; one taken by the race is gone until the stand leaves the band; none by day;
##   5. the kerb riders on the real lane graph: as many as the rule in the band round the view, on
##      their roads' kerb line (the outer lane's kerb, KERB_IN in), still riding kerb roads after 20 s;
##   6. a car driven at a kerb rider along his line: he swerves (or hops), never inside the car's
##      footprint, and says one line; the step's cost.
## Prints "check_couriers: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_couriers.gd [-- --verbose]

const CityLife := preload("res://scripts/city_life.gd")
const Notebook := preload("res://scripts/notebook.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Jobs := preload("res://scripts/jobs.gd")
const Props := preload("res://scripts/props.gd")
const Fakes := preload("res://tools/fakes.gd")


## The map's heights flat at 0 and no roofs (the stands' kerb test and the lane graph's heights).
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
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0


var problems: Array[String] = []
var verbose := false
var now := {"hour": 1.5, "weekday": 6}
var cal := {"live": false, "month": 7, "date": 0, "look": "Night", "rain": false}
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
	_check_dodge()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("check_couriers: PROBLEM (no map data or places.json)")
		quit(1)
		return
	await _check_city(book, data)
	book.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_couriers: OK (kerb riders %d by day, %d at night; waiting %s; dodge %s; near-miss lines %s; city %s; drive-at %s; cost %s)" % [
				CityLife.kerb_count(13.0), CityLife.kerb_count(1.5), _summary.get("wait", "?"), _summary.get("dodge", "?"),
				_summary.get("lines", "?"), _summary.get("city", "?"), _summary.get("drive", "?"), _summary.get("cost", "?")])
		quit(0)
	else:
		for p in problems:
			print("  problem: ", p)
		print("check_couriers: %d problems" % problems.size())
		quit(1)


# 1. -------------------------------------------------------------------------------------------

func _check_rules() -> void:
	_expect(CityLife.kerb_count(13.0) == 3 and CityLife.kerb_count(1.5) == 5 and CityLife.kerb_count(21.5) == 5
			and CityLife.kerb_count(6.5) == 3, "kerb riders: day %d, night %d (want 3, 5)" % [CityLife.kerb_count(13.0), CityLife.kerb_count(1.5)])
	_expect(CityLife.kerb_count(13.0, 0.5) == 2 and CityLife.kerb_count(1.5, 10.0) == CityLife.PEDZIK_CAP, "kerb riders: the Low tier's half and the cap")
	# 1 or 2 at night by every stand, none by day; the same night always the same; both counts occur.
	var ones := 0
	var twos := 0
	for day in 30:
		for stand in 42:
			_expect(CityLife.waiting_count(stand, day, 13.0) == 0 and CityLife.waiting_count(stand, day, 20.5) == 0,
					"couriers waiting by day (stand %d, day %d)" % [stand, day])
			var n := CityLife.waiting_count(stand, day, 23.0)
			_expect(n >= 1 and n <= CityLife.WAIT_MAX, "stand %d day %d at night: %d waiting (want 1-2)" % [stand, day, n])
			# 23:00 and the small hours after it (the next day's 02:00) are one night.
			_expect(CityLife.waiting_count(stand, day + 1, 2.0) == n, "stand %d: the night of day %d changes at midnight" % [stand, day])
			_expect(CityLife.waiting_count(stand, day, 23.0) == n, "stand %d day %d counts twice differently" % [stand, day])
			ones += int(n == 1)
			twos += int(n == 2)
	_expect(ones > 300 and twos > 300, "waiting couriers over 1,260 stand-nights: %d with 1, %d with 2 (want both, about half)" % [ones, twos])
	_expect(CityLife.kerb_road(3.0, 0, -1, 40.0) and CityLife.kerb_road(3.25, 2, -1, 40.0), "a 3 m lane isn't a kerb road")
	_expect(not CityLife.kerb_road(2.75, 2, -1, 40.0) and not CityLife.kerb_road(3.0, 3, -1, 40.0)
			and not CityLife.kerb_road(3.0, 1, 4, 40.0) and not CityLife.kerb_road(3.0, 1, -1, 3.0), "a narrow lane, a living street, a tunnel or a stub as a kerb road")
	_summary["wait"] = "1 or 2 by night (%d / %d of 1,260), none by day" % [ones, twos]


# 2. -------------------------------------------------------------------------------------------

func _check_dodge() -> void:
	var up := Vector2(0, -1)
	# A rider at the origin riding -z at 6 m/s; the car 12 m ahead of him coming at 10 m/s: they'd meet.
	var head_on := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(0, -12), -up * 10.0, CityLife.DODGE_T)
	_expect(head_on < 0.01, "head on: %.2f m (want 0)" % head_on)
	_expect(CityLife.dodge(head_on, true) == CityLife.DODGE_SWERVE and CityLife.dodge(head_on, false) == CityLife.DODGE_HOP,
			"head on: a swerve with room, a hop without")
	# The car overtaking him 3 m to his left: within 4 m.
	var overtaken := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(-3, 8), up * 14.0, CityLife.DODGE_T)
	_expect(absf(overtaken - 3.0) < 0.01 and CityLife.dodge(overtaken, true) == CityLife.DODGE_SWERVE, "overtaken 3 m aside: %.2f m" % overtaken)
	# Wide (6 m aside), going away, still far, parked beside: nothing.
	var wide := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(-6, 8), up * 14.0, CityLife.DODGE_T)
	var away := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(0, -6), up * 12.0, CityLife.DODGE_T)
	var far := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(0, -30), -up * 10.0, CityLife.DODGE_T)
	var parked := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(-5, -3), Vector2.ZERO, CityLife.DODGE_T)
	for row: Array in [[wide, "6 m aside"], [away, "going away"], [far, "30 m off"], [parked, "parked 5 m aside"]]:
		_expect(CityLife.dodge(float(row[0]), true) == CityLife.DODGE_NONE, "%s: a dodge at %.2f m" % [row[1], row[0]])
	# Parked on his line 4 m ahead: he dodges it.
	var blocked := CityLife.closest_approach(Vector2.ZERO, up * 6.0, Vector2(0, -4), Vector2.ZERO, CityLife.DODGE_T)
	_expect(CityLife.dodge(blocked, true) == CityLife.DODGE_SWERVE, "a car parked on his line: %.2f m" % blocked)
	# The hop: 0.3 s, up and down, HOP_H at its top.
	_expect(CityLife.hop_height(0.0) == 0.0 and CityLife.hop_height(CityLife.HOP_T) == 0.0
			and absf(CityLife.hop_height(CityLife.HOP_T * 0.5) - CityLife.HOP_H) < 0.001
			and CityLife.hop_height(CityLife.HOP_T * 0.25) > 0.0, "the hop's arc")
	_summary["dodge"] = "head on %.1f, overtaken %.1f, wide %.1f, away %.1f, far %.1f m" % [head_on, overtaken, wide, away, far]


# 4.-6. ----------------------------------------------------------------------------------------

func _check_city(nb: Notebook, data: Dictionary) -> void:
	var map := FakeMap.new()
	root.add_child(map)
	var graph := LaneGraph.new(data["graph"], map)
	# The stands as jobs.gd places them (its kerb test on the lane graph).
	var world := Node3D.new()
	root.add_child(world)
	var jobs: Jobs = Jobs.new()
	jobs.graph = graph
	jobs.map = map
	for p: Dictionary in data.get("pois", []):
		if str(p["k"]) == "kebab":
			jobs.call("_add_stand", p, null, world)
	var stands: Array = jobs.stand_frames()
	_expect(stands.size() >= 40, "%d kebab stands placed (want 42)" % stands.size())
	var dlg := Fakes.Dialogue.new()
	dlg.say_words = ["…", "…"]
	root.add_child(dlg)
	var life: Node3D = CityLife.new()
	life.dialogue = dlg
	life.graph = graph
	life.stands = stands
	life.clock = func() -> Dictionary: return now
	life.calendar = func() -> Dictionary: return cal
	life.focus = func() -> Vector3: return eye
	life.vehicle = func() -> Array: return veh
	life.trend_day_flag = 3
	root.add_child(life)
	life.set_process(false)
	life.setup(nb.places, data, 5150)
	var waited := 0
	while life.get("_index_task") >= 0 and waited < 6000:
		if WorkerThreadPool.is_task_completed(life.get("_index_task")):
			break
		await process_frame
		waited += 1
	life._process(0.001)
	_expect(bool(life.get("_ready")), "the index never finished")
	# Every stand's spots: off the lanes, beside its kiosk.
	var with_two := 0
	var none := 0
	for i in stands.size():
		var spots: Array = life.call("_spots_of", i)
		with_two += int(spots.size() == CityLife.WAIT_MAX)
		none += int(spots.is_empty())
		for sp: Array in spots:
			var q: Vector3 = sp[0]
			_expect(q.distance_to(stands[i][0]) < 5.0, "stand %d: a courier %.1f m from the kiosk" % [i, q.distance_to(stands[i][0])])
			_expect(graph.snap(Vector2(q.x, q.z), 1.8).is_empty(), "stand %d: a courier on a lane" % i)
	_expect(none <= stands.size() / 10, "%d of %d stands have no room for a courier" % [none, stands.size()])
	# 4. Night (01:30) at stand 0: its couriers by the rule; drawn after the riders, standing.
	var si := 0
	while si < stands.size() - 1 and (life.call("_spots_of", si) as Array).size() < CityLife.WAIT_MAX:
		si += 1
	var st: Vector3 = stands[si][0]
	eye = st
	now = {"hour": 1.5, "weekday": 6}
	for k in 30:
		life.tick(0.5)
	var day: int = life.days_now()
	var want: int = mini(CityLife.waiting_count(si, day, 1.5), (life.call("_spots_of", si) as Array).size())
	var at_si := 0
	for w: Array in life.get("_waiting"):
		at_si += int(int(w[0]) == si)
	_expect(at_si == want and (life.waiting_at(si) as Array).size() == want, "stand %d at 01:30: %d waiting (want %d)" % [si, at_si, want])
	life.call("_move", CityLife.MOVE_TICK)
	var ped_mm: MultiMesh = life.get("_ped_mm")
	var riders: int = (life.get("_pedziks") as Array).size() + (life.get("_kerbers") as Array).size()
	var drawn := mini(riders + (life.get("_waiting") as Array).size(), CityLife.PEDZIK_CAP)
	_expect(ped_mm.visible_instance_count == drawn, "the Pedzik MultiMesh draws %d (want %d: %d riders and the waiting)" % [
			ped_mm.visible_instance_count, drawn, riders])
	var buf: PackedFloat32Array = life.get("_ped_buf")
	if drawn > riders:
		_expect(absf(buf[riders * 16 + 15] - Props.PEDZIK_STANDING) < 0.01, "a waiting courier drawn with shape %.1f (want the standing %.1f)" % [
				buf[riders * 16 + 15], Props.PEDZIK_STANDING])
	for k in riders:
		_expect(buf[k * 16 + 15] < 0.01, "rider %d drawn with shape %.1f (want 0, riding)" % [k, buf[k * 16 + 15]])
	# The kerb riders at night: the rule's count in the band, on their kerb lines.
	var kerbers: Array = life.get("_kerbers")
	_expect(kerbers.size() == CityLife.kerb_count(1.5), "kerb riders at 01:30: %d (want %d)" % [kerbers.size(), CityLife.kerb_count(1.5)])
	var off_kerb := 0
	var night_kerb := kerbers.size()
	for m in kerbers:
		_expect((m.p2 as Vector2).distance_to(Vector2(st.x, st.z)) <= CityLife.NEAR_R, "a kerb rider %.0f m from the view" % (m.p2 as Vector2).distance_to(Vector2(st.x, st.z)))
		off_kerb += int(_kerb_miss(graph, m) > 0.35)
	_expect(off_kerb == 0, "%d of %d kerb riders off their kerb line" % [off_kerb, kerbers.size()])
	# F, 2026-11-05: none of them on a road with a cycle path beside it (the bikes use the path).
	var beside := 0
	for m in kerbers:
		beside += int(life.call("_cycle_path_beside", int(m.ke)))
	_expect(beside == 0, "%d of %d kerb riders on a road with a cycle path beside it" % [beside, kerbers.size()])
	# And the real graph: a long Marszałkowska edge with the red path beside it is excluded.
	var mk_all := 0
	var mk_open := 0
	for e in graph.e_name.size():
		if graph.e_name[e].begins_with("Marszałkowska") and CityLife.kerb_road(graph.e_lw[e], graph.e_class[e], graph.e_tn[e], graph.e_s1[e] - graph.e_s0[e]):
			mk_all += 1
			mk_open += int(not life.call("_cycle_path_beside", e))
	_expect(mk_open < mk_all, "no Marszałkowska kerb edge excluded for a cycle path beside it")
	print("couriers: Marszałkowska kerb edges %d, %d left open (no cycle path beside)" % [mk_all, mk_open])
	# The race takes one: one fewer there, back when the stand has left the band (and come back).
	var taken: Array = life.take_waiting(si)
	_expect(not taken.is_empty() and (life.waiting_at(si) as Array).size() == want - 1, "the race's take: %d left (want %d)" % [
			(life.waiting_at(si) as Array).size(), want - 1])
	eye = st + Vector3(400.0, 0.0, 0.0)
	life.tick(0.5)
	eye = st
	life.tick(0.5)
	_expect((life.waiting_at(si) as Array).size() == want, "the taken courier didn't come back after the stand left the band")
	# 5. 20 s of riding: the kerb riders still on kerb roads (the junctions crossed).
	for k in 300:
		life.call("_move", CityLife.MOVE_TICK)
		if k % 8 == 0:
			life.tick(0.5)
	for m in life.get("_kerbers"):
		_expect(int(m.ke) >= 0 and CityLife.kerb_road(graph.e_lw[m.ke], graph.e_class[m.ke], graph.e_tn[m.ke], graph.e_s1[m.ke] - graph.e_s0[m.ke]),
				"a kerb rider on edge %d, not a kerb road" % m.ke)
	# By day: none waiting; the day's kerb riders.
	now = {"hour": 13.0, "weekday": 6}
	life.on_screen = func(_p: Vector3, _h: float) -> bool: return false
	for k in 6:
		life.tick(0.5)
	_expect((life.get("_waiting") as Array).is_empty() and (life.waiting_at(si) as Array).is_empty(), "couriers waiting at 13:00")
	_expect((life.get("_kerbers") as Array).size() == CityLife.kerb_count(13.0), "kerb riders at 13:00: %d (want %d)" % [
			(life.get("_kerbers") as Array).size(), CityLife.kerb_count(13.0)])
	_summary["city"] = "%d stands (%d with room for 2, %d for none), stand %d: %d waiting at 01:30, %d kerb riders at night, %d by day" % [
			stands.size(), with_two, none, si, want, night_kerb, (life.get("_kerbers") as Array).size()]
	# 3. The near miss's rate through the real function: a near miss every 2 s for 300 s.
	var m0: Variant = (life.get("_kerbers") as Array)[0] if not (life.get("_kerbers") as Array).is_empty() else null
	if m0 != null:
		var lines0: int = life.pedzik_lines
		life.set("_pedzik_t", -INF)
		life.set("_car_kmh", 5.0)
		for k in 150:
			life.t = 1000.0 + k * 2.0
			life.call("_near_miss", m0)
		_expect(life.pedzik_lines == lines0, "near-miss lines at 5 km/h: %d" % (life.pedzik_lines - lines0))
		life.set("_car_kmh", 30.0)
		for k in 150:
			life.t = 2000.0 + k * 2.0
			life.call("_near_miss", m0)
		var n_lines: int = life.pedzik_lines - lines0
		_expect(n_lines == 10, "near-miss lines in 300 s at 30 km/h, one every 2 s: %d (want 10)" % n_lines)
		_summary["lines"] = "%d in 300 s at 30 km/h, 0 under 10 km/h" % n_lines
	# 6. The car driven along a kerb rider's line at him, 10 m/s: he swerves or hops, never under it.
	await _drive_at(life, dlg, graph)
	life.queue_free()
	dlg.queue_free()
	world.queue_free()
	map.queue_free()
	jobs.free()
	await process_frame


## How far a kerb rider is off his road's kerb line (m; 0 on it, his swerve aside).
func _kerb_miss(graph: LaneGraph, m: Variant) -> float:
	var e: int = m.ke
	var p: Vector2 = m.p2
	var s := graph.project(e, p)
	if s < graph.e_s0[e] - 0.5 or s > graph.e_s1[e] + 0.5:
		return 0.0  # crossing a junction to the next road
	var off := graph.lane_offset(e, graph.e_lanes[e] - 1) + graph.e_lw[e] * 0.5 - CityLife.KERB_IN + float(m.off)
	return graph.point_at(e, s, off).distance_to(p - (m.shove as Vector2))


func _drive_at(life: Node3D, dlg: Fakes.Dialogue, graph: LaneGraph) -> void:
	now = {"hour": 1.5, "weekday": 6}
	veh = [Vector3.INF, 0.0, false, 0.0, 0.0]
	for k in 4:
		life.tick(0.5)
	var kerbers: Array = life.get("_kerbers")
	# One with room for a swerve if there is one (else he hops: a bridge, a wall, another road).
	var target: Variant = null
	var room := false
	for m in kerbers:
		if m.s > 5.0 and m.length - m.s > 40.0 and (target == null or (not room and bool(life.call("_room", m)))):
			target = m
			room = bool(life.call("_room", m))
	if target == null:
		_expect(false, "no kerb rider with 40 m of road ahead to drive at")
		return
	var dir: Vector2 = (target.udir as Vector2) * float(target.dir)
	# The car on his road's kerb lane 30 m ahead, coming at him at 10 m/s.
	var e: int = target.ke
	var s_r := graph.project(e, target.p2)
	var car2 := graph.point_at(e, minf(s_r + 30.0, graph.e_s1[e]), graph.lane_offset(e, graph.e_lanes[e] - 1))
	var vel := -dir * 10.0
	var yaw := atan2(dir.x, dir.y)
	var lines0 := dlg.count("pedzik", "")
	if verbose:
		var dq := dir
		var q: Vector2 = (target.p2 as Vector2) + Vector2(-dq.y, dq.x) * (CityLife.KERB_IN + CityLife.SWERVE_OUT)
		print("  drive-at: edge %d (%s, %d lanes of %.2f m, bridge %d), the swerve's spot %.1f, %.1f: lanes there %s" % [e, graph.e_name[e],
				graph.e_lanes[e], graph.e_lw[e], graph.e_bridge[e], q.x, q.y, graph.snap(q, 1.2)])
	life.set("_pedzik_t", -INF)
	life.t = 5000.0
	var sw0: int = life.pedzik_swerves
	var hop0: int = life.pedzik_hops
	var over := 0
	var closest := INF
	var max_off := 0.0
	var t0 := Time.get_ticks_usec()
	var steps := 0
	for k in 75:
		veh = [Vector3(car2.x, 0.0, car2.y), 36.0, false, yaw, 0.0, Vector3(vel.x, 0.0, vel.y)]
		life.t += CityLife.MOVE_TICK
		life.call("_move", CityLife.MOVE_TICK)
		steps += 1
		for m in life.get("_kerbers"):
			over += int(CityLife.overlaps_car(m.p2, car2, yaw))
		for m in life.get("_pedziks"):
			over += int(CityLife.overlaps_car(m.p2, car2, yaw))
		closest = minf(closest, (target.p2 as Vector2).distance_to(car2))
		max_off = maxf(max_off, float(target.off))
		car2 += vel * CityLife.MOVE_TICK
	var per_step := float(Time.get_ticks_usec() - t0) / maxf(steps, 1.0)
	var dodged: int = life.pedzik_swerves - sw0 + life.pedzik_hops - hop0
	_expect(life.pedzik_swerves - sw0 == int(room) and life.pedzik_hops - hop0 == int(not room),
			"room %s: %d swerves, %d hops (want a %s)" % [room, life.pedzik_swerves - sw0, life.pedzik_hops - hop0, "swerve" if room else "hop"])
	if room:
		_expect(max_off > CityLife.KERB_IN + 0.5, "the swerve didn't take him onto the footway (%.2f m out)" % max_off)
		_expect(float(target.off) < 0.01, "he didn't come back to his line after the car (%.2f m out)" % float(target.off))
	_expect(dodged >= 1, "the kerb rider didn't dodge the car (swerves %d, hops %d)" % [
			life.pedzik_swerves - sw0, life.pedzik_hops - hop0])
	_expect(over == 0, "a Pędzik rider inside the car's footprint %d times" % over)
	_expect(dlg.count("pedzik", "") - lines0 == 1, "near-miss lines on the pass: %d (want 1)" % (dlg.count("pedzik", "") - lines0))
	_summary["drive"] = "%d swerves (%.1f m aside), %d hops, closest %.1f m, overlaps %d" % [life.pedzik_swerves - sw0, max_off, life.pedzik_hops - hop0, closest, over]
	_summary["cost"] = "%.1f µs a step at a stand at night" % per_step
	await process_frame
