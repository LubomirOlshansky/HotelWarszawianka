extends SceneTree
## Driving-first P14 and P16 (docs/PLAYTEST.md §5, GAMEPLAY_PLAN 1.6) without the Autopilot bill:
## the real car (car.gd) steered along real lane-graph routes in the whole city (the sectors built
## from their files, or the prebuilt sector scenes with --prebuilt), no traffic. A simple driver
## points the stick (car.target_dir, the point-to-steer input) at a spot LOOK m ahead on the route
## and holds a speed that the next bends allow, as a careful player would. A route fails on a stall
## (under STALL m/s for over STALL_TIME s), an unstick, the car leaving the route (OFF_ROUTE m) or
## sinking under `drive_height`, or not reaching the end in time.
##
## PT-21 (2026-11-04, Autopilot run 20261104-102329): with the gas held and no steering, the car
## slowed hard at bends on Frascati, Hoża, Ordynacka and Sienna. This drives those streets end to
## end, steered: a fail here is a road problem, a pass means the run hit the corners' walls.
## P16: the Trzy mosty route (trzy_mosty.gd legs), bridge by bridge at full speed.
##
## --streets=A,B (with --box=x0,z0,x1,z1, metres): drive those streets instead, only their lanes inside
## the box, and no Trzy mosty; --route=NAME:x,z>x,z[>...][;NAME2:...] adds a route through the graph
## nodes nearest those points (into and out of side roads) (a road design check: tools/road_design.py streets driven end to end).
##
##
## Racer AI step 5 (docs/design/race-ai.md 5.4): --links drives the proven race links of
## game/data/race_links.json instead (every link with --write; tools/race_links.py; no streets, no
## Trzy mosty): the very
## curve a rival drives over it (race_cuts.gd `curve`, from the straightest street into its first
## junction to the straightest way on from its last), with LINK_IN m of that street before it and
## LINK_OUT m of the way on after, at the rivals' LINK_TOP at most. A link passes only if the car
## stays within LINK_OFF m of the curve and never touches anything fixed (a wall, a fence, a post:
## LINK_TOUCH frames at most); --write=FILE lists the ids that passed and why the others failed, for
## `python3 -I tools/race_links.py --proofs=FILE` (tools/race_links.sh does both). A rival is
## handed only a link with a proof, so a racer goes only where the player's car can.
##
## The city objects plan, step 3 (docs/design/drivable-city-build.md, item 1): --contacts=FILE writes
## the contact log (contact_log.gd: one line per contact episode, what was touched and how hard, and
## the km per street) for tools/drive_report.py. --driver=sloppy drives like a hurried phone player
## instead of the careful driver above, on the game's own Classic inputs (drive_controls.gd: the
## fixed arrows, all-or-nothing GAS and BRAKE, the lane assist on as in the default settings,
## --assist=off without it): it aims up to SLOPPY_SIDE m off the lane's centre and SLOPPY_HEAD deg
## off its heading (slow noise from a fixed seed, --seed=N, per route), looks a third shorter, and
## holds SLOPPY_PACE of the street's limit until SLOPPY_LATE m before a bend. It is expected to
## touch things: a route never fails on a contact; where a player would call the tow (stuck
## Car.STALL_TIME s, in the water WATER_TOW s, off the route, under the road) it is towed
## SLOPPY_TOW m on and the contact log says so; after SLOPPY_TOWS tows the route is given up.
## --set=A drives route set A (the census's top 25 streets, the first ten minutes' streets, the P14
## streets, Trzy mosty: SET_A; street ends behind the edge roadworks left out, a street whose far
## ends are one-way driven the one way).
## The careful driver's lines and results do not move with any of this (the log only watches).
## Step 7: the soft things (soft_things.gd) run as in the game. Settings rows (2026-11-14): by
## default as the game's default (Settings → Łamliwe płoty off): the sectors are built soft and
## soft_things gives every S fence and hedge its collider back as the sector loads, so the output is
## the city before step 7's. --soft drives with them breakable (no collider; the car breaks through at
## their cost, their contacts are `soft` lines in the log: route set A's drive log and --wander use
## it); --no-soft builds them hard (CityBarriers.soft_off, as before step 7, both paths): the default's
## output must equal it.
## --wander (step 7, the R6 trap): no routes; the car is aimed at the soft lines instead. For every
## S fence or hedge line within WANDER_NEAR m of a ground lane (one test a line, at its segment
## nearest a lane), the car starts on that lane at WANDER_SPEED, drives at the line (square to it
## when the way there runs within WANDER_SQUARE deg of the line), on WANDER_PAST m beyond it, and
## then tries to leave as a player would: reversing back out through its own gap (WANDER_BACK s),
## then turning and driving back (WANDER_TURN s). A line is a `trap` where the car does not get back
## within WANDER_HOME m of its start, a `fall` where it does not get back after dropping over
## WANDER_DROP m under the line's foot (a cutting, a wall's top: `ok` with the drop noted when it
## climbs back), `sink` where it went under the surface (drive_height: ground with no surface),
## `water` where it ended in the river; `miss` where it never reached the line (something hard in
## the way, another level). Sector by sector (each with its neighbours loaded); --box=
## limits it; --write=FILE writes every test as a TSV. It reports and exits 0 (a survey, not a gate).
## --dry lists the routes and their length and drives nothing. --spent prints the car script's time
## a physics frame (the collision preset's cost).
## The city objects plan, step 6: --collide=v1|soft|mid|firm drives the car with that collision answer
## (collide_rules.gd; v1, today's, by default: the output and the contact log do not move with it).
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_lane_drive.gd [-- --prebuilt --handling=grounded --verbose --only=NAME[|NAME2] --streets=A,B --box=... --links --write=FILE --driver=careful|sloppy --contacts=FILE --set=A --seed=N --assist=on|off --collide=PRESET --dry --soft --no-soft --wander]

const LaneGraph := preload("res://scripts/lane_graph.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")
const Car := preload("res://scripts/car.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const Solidity := preload("res://scripts/solidity.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
## Sectors within this of a route point are built.
const REACH := 60.0
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const ContactLog := preload("res://scripts/contact_log.gd")
const DriveControls := preload("res://scripts/drive_controls.gd")
const LaneAssist := preload("res://scripts/lane_assist.gd")
const SoftThings := preload("res://scripts/soft_things.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
## --links: the metres of street before a link and of the way on after it, the most a link's
## drive may stray from its curve (m), and the frames it may touch something fixed.
const LINK_IN := 25.0
const LINK_OUT := 15.0
const LINK_OFF := 2.5
const LINK_TOUCH := 3

## The narrow streets of P14 (lanes under 2.5 m in the GAMEPLAY_PLAN audit): each driven from one
## end of its named edges to the other, both ways.
const STREETS := ["Frascati", "Hoża", "Ordynacka", "Sienna", "Aleja 3 Maja"]
## Route points every STEP m; the stick aims LOOK m ahead (more at speed).
const STEP := 3.0
const LOOK := 5.0
const STALL := 2.0
const STALL_TIME := 1.5
const OFF_ROUTE := 12.0
## Speeds (m/s) for the sharpest turn within the next BEND_AHEAD m.
const BEND_AHEAD := 35.0
const CRUISE_NARROW := 14.0
const CRUISE_FAST := 30.0

## Route set A (item 1's baseline, about 60 km): the census's top 25 named streets (tools/road_objects.py:
## the most solid metres within 3 m of a lane's edge, main 2026-11-14), the streets of the first ten
## minutes (docs/DEMO.md 6.2: the start, the first order and stand, Halina's race to the Palm, the
## boulevards) not among them, the P14 streets (STREETS) and the three Trzy mosty legs. Each street
## from one end to the other, both ways.
const SET_A_CENSUS := ["Aleja Armii Ludowej", "Aleje Jerozolimskie", "Aleja Jana Pawła II", "Tunel Wisłostrady",
		"Most Łazienkowski", "Most Księcia Józefa Poniatowskiego", "Most Świętokrzyski", "Wybrzeże Kościuszkowskie",
		"Aleja „Solidarności”", "Prosta", "Marszałkowska", "Generała Władysława Andersa", "Most Śląsko-Dąbrowski",
		"Okopowa", "Tytusa Chałubińskiego", "Krucza", "Kozia", "Towarowa", "Wybrzeże Szczecińskie", "Czeska",
		"Kolejowa", "Grzybowska", "Aleja Księcia Józefa Poniatowskiego", "Jana Zamoyskiego", "Lipska"]
const SET_A_FIRST10 := ["Świętokrzyska", "Nowy Świat", "Emilii Plater"]
## Step 8a (drivable-city-build.md item 4, step 5): the parking streets of Śródmieście Południowe,
## lined both sides with parked cars (Krucza and Hoża are in the set already).
const SET_A_PARKED := ["Wspólna", "Polna", "Stanisława Noakowskiego"]

## The sloppy driver (--driver=sloppy): how far off the lane's centre it aims (m), how far off its
## heading (deg), how much shorter it looks than the careful one, its share of the street's limit, how
## late it slows for a bend (m), how often it may change what it presses (s: a thumb, not a servo),
## the heading error it lets go (deg), the noise's knots along the route (m), and its tows.
const SLOPPY_SIDE := 1.5
const SLOPPY_HEAD := 10.0
const SLOPPY_LOOK := 2.0 / 3.0
const SLOPPY_PACE := 0.9
const SLOPPY_LATE := 15.0
const SLOPPY_REACT := 0.1
const SLOPPY_DEAD := 3.0
const SLOPPY_SIDE_KNOT := 30.0
const SLOPPY_HEAD_KNOT := 12.0
const SLOPPY_TOW := 12.0
const SLOPPY_TOWS := 5
## --wander: the reach from a soft line's segment to a ground lane (m), the speed at it (m/s), the
## least angle it is crossed at (deg), the metres beyond it, the seconds out, back (reversing) and
## round (driving), the distance home that counts as back (m), the drop under the line's foot that
## is a fall (m), and the levels apart (m) that are another level (a deck over it, a wall's top).
const WANDER_NEAR := 10.0
const WANDER_SPEED := 12.0
const WANDER_SQUARE := 35.0
const WANDER_PAST := 6.0
const WANDER_OUT := 6.0
const WANDER_BACK := 8.0
const WANDER_TURN := 12.0
const WANDER_HOME := 3.0
const WANDER_DROP := 2.5
const WANDER_LEVEL := 3.0
## In the water this long (s): the game's tow out of it (main.gd `_tow_out_of_water`, about 2 s).
const WATER_TOW := 2.0
const SEED := 20261114

var prebuilt := false
## --handling=cruise|sport|grounded: drive the routes in that profile (-1: the car's default, Cruise).
var handling := -1
## --collide=v1|soft|mid|firm (the city objects plan, step 6): the car's collision answer
## (collide_rules.gd; v1, today's, by default).
var collide := &"v1"
## Step 6: the v2 answer's head-on kicks and corner pivots over every route (printed for a v2 preset).
var _kicks := 0
var _pivots := 0
## --spent (step 6): print the car script's time per physics frame over every route (car.gd
## `spent_usec`), for the preset's cost; nothing else changes.
var spent := false
var _spent_usec := 0
var _car_frames := 0
var verbose := false
var only := ""
var streets: Array = STREETS
var box := Rect2()
var extra := ""
var map: Node3D
var graph: LaneGraph
var car: CharacterBody3D
var routes: Array[Dictionary] = []
var _r := -1
var _path := PackedVector3Array()
var _idx := 0
var _t := 0.0
var _stalled := 0.0
var _worst := 0.0
var _worst_at := Vector3.ZERO
var _sink := 0.0
var _off := 0.0
var _min_v := INF
var _failures := 0
var _frames := 0
var _cruise := CRUISE_NARROW
var _over := false
## --links: drive the race links; --write=FILE: where the ids that passed go.
var links := false
var write_to := ""
var _touch := 0
var _passed: Array[String] = []
var _failed := {}
## Item 1: the driver, the contact log, the route set, the noise's seed, the lane assist, --dry.
var sloppy := false
var contacts_to := ""
var clog: ContactLog
var set_a := false
var noise_seed := SEED
var assist := true
var dry := false
var _controls: DriveControls
var _edges := PackedInt32Array()
var _names := PackedStringArray()
var _rng_side := PackedFloat32Array()
var _rng_head := PackedFloat32Array()
var _react := 0.0
var _arrow := 0
var _gas := false
var _brake := false
var _lane_t := 0.0
var _tows := 0
var _wet := 0.0
var _gave_up := false
var _ep0 := 0
var _total_m := 0.0
## Step 7: the soft things; --soft (breakable) and --no-soft (built hard).
var soft: SoftThings
var soft_on := false
var no_soft := false
## --wander's state: the sector keys to visit, the one now, the loaded sectors (key: root), the
## tests of this sector ([id, kind, mat, start, a, b, dir, foot, key]), the phase (0 settle, 1 out,
## 2 back, 3 round), its clock, whether the car got over the line, the most it dropped, the rows
## and the verdict counts.
var wander := false
var _w_keys: Array[Vector2i] = []
var _w_k := -1
var _w_loaded := {}
var _w_have := {}
var _w_tests: Array = []
var _w_i := 0
var _w_phase := 0
var _w_t := 0.0
var _w_frames := 0
var _w_crossed := false
var _w_low := 0.0
var _w_rows := PackedStringArray()
var _w_counts := {}
var _w_seen := {}
var _w_t0 := 0


func _initialize() -> void:
	# W2 of the walls look: --barriers=classic|typed builds the city in that look (the palette's by default).
	Solidity.barrier_look_from(OS.get_cmdline_user_args())
	for a in OS.get_cmdline_user_args():
		if a == "--prebuilt":
			prebuilt = true
		elif a == "--verbose":
			verbose = true
		elif a.begins_with("--handling="):
			handling = Car.parse_handling(a.trim_prefix("--handling="))
		elif a.begins_with("--collide="):
			collide = Car.CollideRules.parse(a.trim_prefix("--collide="))
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--streets="):
			streets = Array(a.trim_prefix("--streets=").split(","))
		elif a.begins_with("--route="):
			extra = a.trim_prefix("--route=")
		elif a == "--links":
			links = true
		elif a.begins_with("--write="):
			write_to = a.trim_prefix("--write=")
		elif a.begins_with("--driver="):
			sloppy = a.trim_prefix("--driver=") == "sloppy"
			if not a.trim_prefix("--driver=") in ["careful", "sloppy"]:
				_fail_build("--driver= is careful or sloppy, not %s" % a.trim_prefix("--driver="))
		elif a.begins_with("--contacts="):
			contacts_to = a.trim_prefix("--contacts=")
		elif a == "--set=A":
			set_a = true
		elif a.begins_with("--seed="):
			noise_seed = int(a.trim_prefix("--seed="))
		elif a.begins_with("--assist="):
			assist = a.trim_prefix("--assist=") != "off"
		elif a == "--spent":
			spent = true
		elif a == "--dry":
			dry = true
		elif a == "--no-soft":
			no_soft = true
		elif a == "--soft":
			soft_on = true
		elif a == "--wander":
			wander = true
		elif a.begins_with("--box="):
			var b := a.trim_prefix("--box=").split_floats(",")
			box = Rect2(minf(b[0], b[2]), minf(b[1], b[3]), absf(b[2] - b[0]), absf(b[3] - b[1]))
	var t0 := Time.get_ticks_msec()
	if wander and not no_soft:
		soft_on = true  # --wander tests the breakable lines: --soft is implied
	soft_on = soft_on and not no_soft
	CityBarriers.soft_off = no_soft
	soft = SoftThings.new()
	soft.no_soft = not soft_on
	root.add_child(soft)
	# The index first (the lane graph needs only it), then just the sectors within REACH of a route.
	if prebuilt:
		map = (load(SectorStreamer.INDEX_SCENE) as PackedScene).instantiate()
		root.add_child(map)
		# The phone's map as the game opens it: its data, the heights it does not keep, the roadworks.
		SectorStreamer.ready_prebuilt(map)
	else:
		map = MapBuilder.new()
		root.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(SectorStreamer.INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	graph = LaneGraph.new(map.data["graph"], map)
	soft.graph = graph  # step 8a: a pushed parked car never rests in a lane, as in the game
	soft.ground_at = map.terrain_height
	_names = ContactLog.street_names(map.data["graph"])
	if wander:
		_start_wander(t0)
		return
	if links:
		streets = []
		_add_links()
	if set_a:
		streets = []
		for st: String in SET_A_CENSUS + SET_A_FIRST10 + STREETS + SET_A_PARKED:
			if not streets.has(st):
				streets.append(st)
	for street: String in streets:
		var ends := _street_ends(street)
		if ends.is_empty():
			_fail_build("no lanes named %s" % street)
			continue
		for way in 2:
			var a: int = ends[way]
			var b: int = ends[1 - way]
			_add_route("%s %s" % [street, "→" if way == 0 else "←"], PackedInt32Array([a, b]), CRUISE_NARROW)
	for spec: String in extra.split(";", false):
		var parts := spec.split(":")
		var stops := PackedInt32Array()
		for xz: String in parts[1].split(">"):
			var f := xz.split_floats(",")
			stops.append(graph.nearest_node(Vector2(f[0], f[1])))
		_add_route(parts[0], stops, CRUISE_NARROW)
	var tm := TrzyMosty.new()
	if (streets != STREETS and not set_a) or extra != "" or links:
		pass
	elif not tm.build(graph, map.data):
		_fail_build("Trzy mosty: %s" % tm.error)
	else:
		var start := graph.nearest_node(Vector2(tm.start_pos.x, tm.start_pos.z))
		var stops := PackedInt32Array([start])
		stops.append_array(tm.legs)
		# One episode a bridge: start → span's far end, then on to the next span's far end, then the finish.
		var cut := [0, 2, 4, stops.size() - 1]
		for i in 3:
			var part := stops.slice(cut[i], cut[i + 1] + 1)
			_add_route("Trzy mosty leg %d (%s)" % [i + 1, TrzyMosty.BRIDGES[i]["pl"]], part, CRUISE_FAST)
	if dry:
		var km := 0.0
		for r: Dictionary in routes:
			km += float(r["len"]) / 1000.0
			print("route %s: %.0f m (--at=%.0f,%.0f)" % [r["name"], float(r["len"]), r["pts"][0].x, r["pts"][0].z])
		print("check_lane_drive: %d routes, %.1f km (--dry: nothing driven)" % [routes.size(), km])
		_over = true
		quit(1 if _failures > 0 else 0)
		return
	var n := 0
	for k: Array in map.index_data["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := Rect2(key.x * MapBuilder.SECTOR, key.y * MapBuilder.SECTOR, MapBuilder.SECTOR, MapBuilder.SECTOR).grow(REACH)
		var near := false
		for r: Dictionary in routes:
			for q: Vector3 in r["pts"]:
				if rect.has_point(Vector2(q.x, q.z)):
					near = true
					break
			if near:
				break
		if not near:
			continue
		var sector: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
				if prebuilt else map.build_sector(key)
		map.add_child(sector)
		soft.add_sector(sector)
		n += 1
	if not prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	print("check_lane_drive: %d routes, %d sectors %s in %d ms" % [routes.size(), n, "loaded" if prebuilt else "built", Time.get_ticks_msec() - t0])
	if sloppy or contacts_to != "":
		clog = ContactLog.new()
		clog.street_at = _street_at
		if contacts_to != "" and not clog.open(contacts_to):
			_fail_build("cannot write the contact log %s" % contacts_to)
		print("check_lane_drive: %s driver%s, contact log %s" % ["sloppy" if sloppy else "careful",
				" (Classic, lane assist %s, seed %d)" % ["on" if assist else "off", noise_seed] if sloppy else "",
				contacts_to if contacts_to != "" else "on stdout"])
		clog.echo = contacts_to == "" or verbose
		soft.contacts = clog
	print("check_lane_drive: soft things %s: %d segments in %d sectors" % [_soft_word(),
			soft.segment_count(), n])


func _fail_build(why: String) -> void:
	print("FAIL %s" % why)
	_failures += 1


## The two graph nodes of a street's edges that lie furthest apart (in the connected part).
func _street_ends(street: String) -> Array:
	var nodes: Array[int] = []
	for e in graph.e_a.size():
		if graph.e_name[e] == street:
			for n: int in [graph.e_a[e], graph.e_b[e]]:
				# Route set A: not from behind the edge roadworks (the closed band at the map's edge).
				if set_a and graph.in_works_band(graph.node_pos[n]):
					continue
				if graph.node_scc[n] != 0 and not nodes.has(n) and (box.size == Vector2.ZERO or box.has_point(graph.node_pos[n])):
					nodes.append(n)
	if nodes.size() < 2:
		return []
	var best := [nodes[0], nodes[1]]
	var best_d := -1.0
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var d := graph.node_pos[nodes[i]].distance_squared_to(graph.node_pos[nodes[j]])
			if d > best_d:
				best_d = d
				best = [nodes[i], nodes[j]]
	return best


## --links: one route a race link, every link of the file (proven or not): LINK_IN m of the street
## into its first junction that meets the link straightest, the curve a rival drives
## (RaceCuts.curve), and LINK_OUT m of the straightest way on.
func _add_links() -> void:
	var cuts := RaceCuts.new()
	# The proof (--write) drives every link; the check, the proven ones (the others never race).
	cuts.with_unproven = write_to != ""
	cuts.load_cuts(graph)
	if cuts.links_missed > 0:
		_fail_build("race links: %d of %d did not snap to the lane graph" % [cuts.links_missed, cuts.links_total])
	if cuts.a.size() == cuts.first_link:
		_fail_build("race links: none to drive")
	for i in range(cuts.first_link, cuts.a.size()):
		var lid := cuts.link_id[i - cuts.first_link]
		var name := "link %s %s %.0f m" % [lid, cuts.kind[i], cuts.length[i]]
		if not _wanted(name):
			continue
		var pts: PackedVector2Array = cuts.shape[i]
		var first := (pts[1] - pts[0]).normalized()
		var e_in := -1
		var best := -2.0
		for e: int in graph.node_in[cuts.a[i]]:
			var dot := graph.direction(e, graph.e_s1[e]).dot(first)
			# (Not the one-way street a wrong-way hop drives against: no racer turns round into it.)
			if graph.e_tn[e] < 0 and dot > best and RaceCuts.hop(cuts.a[i], cuts.b[i]) != e:
				best = dot
				e_in = e
		var exits: PackedInt32Array = cuts.exits_ab[i]
		if e_in < 0 or exits.is_empty():
			_fail_build("%s: no street into it or no way on (--at=%.0f,%.0f)" % [name, pts[0].x, pts[0].y])
			_failed[lid] = "no street into it or no way on"
			continue
		var last := (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()
		var g := exits[0]
		best = -2.0
		for f: int in exits:
			var dot := graph.direction(f, graph.e_s0[f]).dot(last)
			if dot > best:
				best = dot
				g = f
		var route := PackedVector3Array()
		var edges := PackedInt32Array()
		var off := graph.lane_offset(e_in, 0)
		var s := maxf(graph.e_s1[e_in] - LINK_IN, graph.e_s0[e_in])
		while s < graph.e_s1[e_in]:
			var q := graph.point_at(e_in, s, off)
			route.append(Vector3(q.x, graph.height(e_in, s), q.y))
			edges.append(e_in)
			s += STEP
		var c := RaceCuts.curve(graph, e_in, 0, g)
		var y0 := graph.height(e_in, graph.e_s1[e_in])
		var y1 := graph.height(g, graph.e_s0[g])
		var cn := maxi(2, int(LaneGraph.bezier_length(c) / STEP))
		for k in range(0, cn + 1):
			var q := LaneGraph.bezier(c, float(k) / cn)
			var x := Vector2(q.x, q.y)
			route.append(Vector3(q.x, map.drive_height(x.x, x.y, lerpf(y0, y1, float(k) / cn)), q.y))
			edges.append(g)
		s = graph.e_s0[g] + STEP
		off = graph.lane_offset(g, 0)
		while s < minf(graph.e_s0[g] + LINK_OUT, graph.e_s1[g]):
			var q := graph.point_at(g, s, off)
			route.append(Vector3(q.x, graph.height(g, s), q.y))
			edges.append(g)
			s += STEP
		var length := 0.0
		for k in range(1, route.size()):
			length += route[k].distance_to(route[k - 1])
		routes.append({"name": name, "pts": route, "cruise": RaceCuts.LINK_TOP, "len": length, "link": lid, "edges": edges})


## --only=A|B: a route whose name contains any of the parts (all routes without --only).
func _wanted(name: String) -> bool:
	if only == "":
		return true
	for part: String in only.split("|", false):
		if name.contains(part):
			return true
	return false


## The shortest lane path through `stops` (graph nodes), as points on lane 0 every STEP m.
func _add_route(name: String, stops: PackedInt32Array, cruise: float) -> void:
	if not _wanted(name):
		return
	var pts := PackedVector3Array()
	var edges := PackedInt32Array()
	var prev := -1
	var lane := 0
	for i in stops.size() - 1:
		var dist := graph.distances_to(stops[i + 1])
		var n := stops[i]
		var guard := 0
		while n != stops[i + 1]:
			guard += 1
			var best := -1
			var best_c := INF
			for e in graph.node_out[n]:
				var c: float = graph.e_len[e] + dist[graph.e_b[e]]
				if c < best_c:
					best_c = c
					best = e
			if best < 0 or best_c == INF or guard > 5000:
				if set_a:
					# Route set A takes each street both ways where it can: a street whose far ends
					# are one-way (a dual carriageway's, the map's edge) is driven the one way.
					print("skip %s: no lane path from node %d to %d" % [name, n, stops[i + 1]])
				else:
					_fail_build("%s: no lane path from node %d to %d" % [name, n, stops[i + 1]])
				return
			# Across the junction as traffic drives it: the lane traffic would take and the curve.
			if prev >= 0:
				var j := graph.next_lane(prev, lane, best)
				var c := graph.connector(prev, lane, best, j)
				var hy := graph.height(prev, graph.e_s1[prev])
				var hy2 := graph.height(best, graph.e_s0[best])
				var cn := maxi(2, int(LaneGraph.bezier_length(c) / STEP))
				for k in range(1, cn):
					var q := LaneGraph.bezier(c, float(k) / cn)
					pts.append(Vector3(q.x, lerpf(hy, hy2, float(k) / cn), q.y))
					edges.append(best)
				lane = j
			prev = best
			var off := graph.lane_offset(best, lane)
			var s := graph.e_s0[best]
			while s < graph.e_s1[best]:
				var q := graph.point_at(best, s, off)
				pts.append(Vector3(q.x, graph.height(best, s), q.y))
				edges.append(best)
				s += STEP
			n = graph.e_b[best]
	if pts.size() < 4:
		_fail_build("%s: route under %d points" % [name, pts.size()])
		return
	var length := 0.0
	for i in range(1, pts.size()):
		length += pts[i].distance_to(pts[i - 1])
	if verbose:
		for i in range(0, pts.size(), 5):
			print("   route %s point %d: %.1f, %.1f, %.1f" % [name, i, pts[i].x, pts[i].z, pts[i].y])
	routes.append({"name": name, "pts": pts, "cruise": cruise, "len": length, "edges": edges})


func _next() -> bool:
	if car != null:
		car.queue_free()
		car = null
	_r += 1
	if _r >= routes.size():
		return false
	var r: Dictionary = routes[_r]
	_path = r["pts"]
	_edges = r["edges"]
	_cruise = float(r["cruise"])
	car = Car.new()
	if handling >= 0:
		car.set_handling(handling)
	car.collide = collide
	if clog != null:
		clog.reset()
		clog.tag = str(r["name"])
		_ep0 = clog.lines.size()
	if sloppy:
		_start_sloppy(str(r["name"]), float(r["len"]))
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	soft.car = car
	soft.reset_motion()
	var d := _path[1] - _path[0]
	car.global_position = _path[0]
	car.rotation.y = atan2(-d.x, -d.z)
	car.reset_physics_interpolation()
	_idx = 0
	_t = 0.0
	_stalled = 0.0
	_worst = 0.0
	_sink = 0.0
	_off = 0.0
	_min_v = INF
	_touch = 0
	return true


## The sharpest heading change (radians) over the route's next `ahead` metres from point i.
func _bend(i: int, ahead: float) -> float:
	var worst := 0.0
	var steps := int(ahead / STEP)
	var j0 := mini(i + 1, _path.size() - 1)
	var d0 := Vector2(_path[j0].x - _path[i].x, _path[j0].z - _path[i].z)
	for k in range(2, steps):
		var j := i + k
		if j + 1 >= _path.size():
			break
		var d := Vector2(_path[j + 1].x - _path[j].x, _path[j + 1].z - _path[j].z)
		if d.length() > 0.01 and d0.length() > 0.01:
			worst = maxf(worst, absf(d0.angle_to(d)))
	return worst


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _frames < 3 or _over:
		return false
	if wander:
		_wander_step(dt)
		return false
	if car == null:
		if not _next():
			_finish()
		return false
	_t += dt
	var p := car.global_position
	# Progress: the nearest route point a little way on from the last one.
	var best := _idx
	var best_d := INF
	for j in range(_idx, mini(_idx + 20, _path.size())):
		var dd := Vector2(_path[j].x - p.x, _path[j].z - p.z).length()
		if dd < best_d:
			best_d = dd
			best = j
	_idx = best
	var v := Vector2(car.vel.x, car.vel.z).length()
	if clog != null:
		# Before the car's step: the collisions and the velocity its last step left (contact_log.gd).
		clog.observe(car, dt)
	if sloppy:
		_drive_sloppy(dt, p, v, best_d)
		return false
	var look := LOOK + v * 0.3
	var ahead := mini(_idx + int(ceil(look / STEP)), _path.size() - 1)
	var aim := _path[ahead] - p
	aim.y = 0.0
	# Grounded brakes at ~1.1 g, not 3 g: a careful driver looks a stopping distance further on.
	var bend := _bend(_idx, BEND_AHEAD + v + (v * v / 18.0 if car.weighty else 0.0))
	var want := _bend_speed(bend, _cruise)
	if car.weighty:
		# Grounded turns with ~1.2 g at most: no faster than 80 % of that grip allows on the bend's radius.
		var reach := BEND_AHEAD + v
		var curve := _bend(_idx, reach)
		if curve > 0.02:
			want = minf(want, maxf(6.0, sqrt(0.8 * car.turn_pull * reach / curve)))
	car.target_dir = aim.normalized() if aim.length() > 0.5 else Vector3.ZERO
	car.throttle = clampf(want / car.top_speed(), 0.0, 1.0)
	car.braking = v > want + 4.0
	# Findings.
	_stalled = _stalled + dt if v < STALL and _t > 2.0 else 0.0
	if _stalled > _worst:
		_worst = _stalled
		_worst_at = p
	if links:
		# Off the curve itself, not off its nearest point (they lie STEP m apart).
		for j in [best - 1, best]:
			if j >= 0 and j + 1 < _path.size():
				var a2 := Vector2(_path[j].x, _path[j].z)
				var b2 := Vector2(_path[j + 1].x, _path[j + 1].z)
				best_d = minf(best_d, Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), a2, b2).distance_to(Vector2(p.x, p.z)))
	_off = maxf(_off, best_d)
	_min_v = minf(_min_v, v) if _t > 3.0 else _min_v
	var h: float = map.drive_height(p.x, p.z, p.y)
	_sink = maxf(_sink, h - p.y)
	if links:
		for k in car.get_slide_collision_count():
			var who := car.get_slide_collision(k).get_collider()
			if who is StaticBody3D and not who is AnimatableBody3D:
				_touch += 1
				if verbose:
					print("   touch t=%.2f at %.1f, %.1f  %s" % [_t, p.x, p.z, (who as Node).get_path()])
				break
	if verbose and car.get_slide_collision_count() > 0:
		var c := car.get_slide_collision(0)
		var who: Object = c.get_collider()
		print("   hit t=%.2f at %.1f, %.1f  %s normal %s point %s" % [_t, p.x, p.z,
				(who as Node).get_path() if who is Node else str(who), c.get_normal(), c.get_position()])
	if verbose and int(_t / dt) % 30 == 0:
		print("   t=%.1f at %.0f, %.0f  %.1f m/s (want %.0f) point %d/%d%s" % [_t, p.x, p.z, v, want, _idx, _path.size(),
				"  touching" if car.get_slide_collision_count() > 0 else ""])
	var r: Dictionary = routes[_r]
	var limit: float = float(r["len"]) / 4.0 + 20.0
	var done := _idx >= _path.size() - 3
	var why: Array[String] = []
	if _worst > STALL_TIME:
		why.append("stalled %.1f s at %.0f, %.0f" % [_worst, _worst_at.x, _worst_at.z])
	if int(car.unsticks) > 0:
		why.append("unstuck %d×" % int(car.unsticks))
	if _off > (LINK_OFF if links else OFF_ROUTE):
		why.append("%.1f m off the route at %.0f, %.0f" % [_off, p.x, p.z])
	if links and _touch > LINK_TOUCH:
		why.append("touched something fixed %d frames (first at %.0f, %.0f)" % [_touch, p.x, p.z])
	if _sink > 1.0:
		why.append("%.1f m under drive_height" % _sink)
	if not why.is_empty() or done or _t > limit:
		if not done and why.is_empty():
			why.append("not at the end after %.0f s (at %.0f, %.0f, point %d/%d)" % [_t, p.x, p.z, _idx, _path.size()])
		print("%s %s: %.0f m in %.1f s (%.0f km/h on average), slowest %.1f m/s%s  (--at=%.0f,%.0f)" % [
				"FAIL" if not why.is_empty() else "ok  ", r["name"], float(r["len"]), _t,
				float(r["len"]) / maxf(_t, 0.1) * 3.6, 0.0 if _min_v == INF else _min_v,
				"" if why.is_empty() else " · " + ", ".join(why), _path[0].x, _path[0].z])
		if not why.is_empty():
			_failures += 1
			if r.has("link"):
				_failed[String(r["link"])] = ", ".join(why)
		elif r.has("link"):
			_passed.append(String(r["link"]))
		if clog != null:
			clog.flush()
		if not _next():
			_finish()
	return false


## The careful driver's speed for the sharpest bend ahead (rad), at most `cruise`.
func _bend_speed(bend: float, cruise: float) -> float:
	if bend > deg_to_rad(70.0):
		return 6.0
	if bend > deg_to_rad(40.0):
		return 9.0
	if bend > deg_to_rad(20.0):
		return minf(cruise, 14.0)
	return cruise


## The contact log's street: the route's own edge at the car's progress (its name and limit), so the
## km and the contacts of a street count the same metres.
func _street_at(_x: float, _z: float) -> Array:
	if _edges.is_empty():
		return ["", 0.0]
	var e := _edges[clampi(_idx, 0, _edges.size() - 1)]
	return [_names[e], graph.e_speed[e]]


## A new route for the sloppy driver: Classic controls, the lane assist as set, the route's noise.
func _start_sloppy(name: String, length: float) -> void:
	_controls = DriveControls.new()
	_controls.scheme = DriveControls.CLASSIC
	car.lane_assist = assist
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%d" % [name, noise_seed])
	_rng_side = PackedFloat32Array()
	for _i in int(length / SLOPPY_SIDE_KNOT) + 3:
		_rng_side.append(rng.randf_range(-1.0, 1.0))
	_rng_head = PackedFloat32Array()
	for _i in int(length / SLOPPY_HEAD_KNOT) + 3:
		_rng_head.append(rng.randf_range(-1.0, 1.0))
	_react = 0.0
	_arrow = 0
	_gas = false
	_brake = false
	_lane_t = 0.0
	_tows = 0
	_wet = 0.0
	_gave_up = false


## Slow noise: the knots' values, eased between them, at `d` m along the route.
static func _noise(knots: PackedFloat32Array, knot: float, d: float) -> float:
	var u := maxf(d, 0.0) / knot
	var i := mini(int(u), knots.size() - 2)
	var f := clampf(u - i, 0.0, 1.0)
	return lerpf(knots[i], knots[i + 1], f * f * (3.0 - 2.0 * f))


## The sloppy driver's frame: what it presses (the arrows, GAS, BRAKE, through drive_controls.gd as
## the HUD does), the tow when a player would call it, and the route's end. Never fails a route.
func _drive_sloppy(dt: float, p: Vector3, v: float, off_now: float) -> void:
	var d := _idx * STEP
	var look := (LOOK + v * 0.3) * SLOPPY_LOOK
	var ahead := mini(_idx + int(ceil(look / STEP)), _path.size() - 1)
	var nxt := mini(ahead + 1, _path.size() - 1)
	var along := Vector2(_path[nxt].x - _path[ahead].x, _path[nxt].z - _path[ahead].z)
	if along.length() < 0.01:
		along = Vector2(_path[ahead].x - p.x, _path[ahead].z - p.z)
	along = along.normalized()
	var side := Vector2(-along.y, along.x) * SLOPPY_SIDE * _noise(_rng_side, SLOPPY_SIDE_KNOT, d)
	var aim := (Vector2(_path[ahead].x, _path[ahead].z) + side - Vector2(p.x, p.z))
	aim = aim.rotated(deg_to_rad(SLOPPY_HEAD) * _noise(_rng_head, SLOPPY_HEAD_KNOT, d))
	var e := _edges[clampi(_idx, 0, _edges.size() - 1)]
	var limit := graph.e_speed[e] if graph.e_speed[e] > 1.0 else 13.9
	var want := _bend_speed(_bend(_idx, SLOPPY_LATE), SLOPPY_PACE * limit)
	_react -= dt
	if _react <= 0.0:
		_react = SLOPPY_REACT
		var fwd := Vector3(-sin(car.rotation.y), 0.0, -cos(car.rotation.y))
		var err := rad_to_deg(fwd.signed_angle_to(Vector3(aim.x, 0.0, aim.y), Vector3.UP)) if aim.length() > 0.5 else 0.0
		_arrow = 1 if err > SLOPPY_DEAD else (-1 if err < -SLOPPY_DEAD else 0)
		_brake = v > want + 4.0
		_gas = not _brake and v < want
	if assist:
		_lane_t -= dt
		if _lane_t <= 0.0:
			_lane_t = 0.1
			var f2 := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
			var h2 := LaneAssist.lane_heading(graph, Vector2(p.x, p.z), f2, v)
			car.lane_dir = Vector3(h2.x, 0.0, h2.y)
	_controls.arrows = _arrow
	_controls.drive(car, Vector2.ZERO, false, {}, _gas, _brake, 0.0, dt)
	if verbose and int(_t / dt) % 30 == 0:
		print("   t=%.1f at %.0f, %.0f  %.1f m/s (want %.0f) point %d/%d arrow %d%s%s%s" % [_t, p.x, p.z, v, want, _idx,
				_path.size(), _arrow, " gas" if _gas else "", " brake" if _brake else "",
				"  touching" if car.get_slide_collision_count() > 0 else ""])
	_min_v = minf(_min_v, v) if _t > 3.0 else _min_v
	var r: Dictionary = routes[_r]
	var done := _idx >= _path.size() - 3
	var under: float = map.drive_height(p.x, p.z, p.y) - p.y
	var tow := ""
	_wet = _wet + dt if car.in_water else 0.0
	if _wet > WATER_TOW:
		tow = "in the water"
	elif car.stalled > Car.STALL_TIME:
		tow = "stuck %.0f s" % car.stalled
	elif off_now > OFF_ROUTE:
		tow = "%.0f m off the route" % off_now
	elif under > 1.0:
		tow = "%.1f m under the road" % under
	if tow != "" and not done:
		if _tows >= SLOPPY_TOWS:
			_gave_up = true
		else:
			_tow(tow, p)
	var limit_t: float = float(r["len"]) / 4.0 + 40.0 + 30.0 * _tows
	if not (done or _gave_up or _t > limit_t):
		return
	if clog != null:
		clog.flush()
	var n := 0
	var dead := 0
	var smash := 0
	for i in range(_ep0, clog.lines.size()):
		if clog.lines[i].begins_with("contact\t") and clog.lines[i].contains("flags=soft"):
			smash += 1
		elif clog.lines[i].begins_with("contact\t"):
			n += 1
			dead += 1 if clog.lines[i].contains("dead_stop") else 0
	var how := "ok      " if done else ("gave up " if _gave_up else "timeout ")
	print("%s %s: %.0f m in %.1f s (%.0f km/h on average), slowest %.1f m/s · %d contacts, %d dead stops, %d unsticks, %d tows%s  (--at=%.0f,%.0f)" % [
			how, r["name"], float(r["len"]), _t, float(r["len"]) / maxf(_t, 0.1) * 3.6, 0.0 if _min_v == INF else _min_v,
			n, dead, int(car.unsticks), _tows, ", %d smashes" % smash if smash > 0 else "", _path[0].x, _path[0].z])
	_total_m += float(r["len"]) if done else _idx * STEP
	_kicks += int(car.kicks)
	_pivots += int(car.pivots)
	_spent_usec += int(car.spent_usec)
	_car_frames += int(round(_t * 60.0))
	if not _next():
		_finish()


func _smashes() -> int:
	var n := 0
	for k: String in clog.soft_counts:
		n += int(clog.soft_counts[k])
	return n


## The player's tow, as the game's (main.gd `_tow_to_lane`): the car stopped and put back on the
## route SLOPPY_TOW m on from where it is, facing along it.
func _tow(why: String, p: Vector3) -> void:
	_tows += 1
	var j := mini(_idx + int(SLOPPY_TOW / STEP), _path.size() - 2)
	var d := _path[j + 1] - _path[j]
	car.global_position = _path[j]
	car.rotation.y = atan2(-d.x, -d.z)
	if car.in_water:
		car.leave_water()
	car.reset_motion()
	soft.reset_motion()
	car.reset_physics_interpolation()
	_idx = j
	_wet = 0.0
	if clog != null:
		clog.mark("tow")
	print("   tow %d on %s: %s at %.0f, %.0f" % [_tows, routes[_r]["name"], why, p.x, p.z])


func _finish() -> void:
	if _over:
		return
	_over = true
	if clog != null:
		clog.close()
		var by := {}
		var n := 0
		for line: String in clog.lines:
			if line.begins_with("contact\t") and not line.contains("flags=soft"):
				n += 1
				var cls := String(ContactLog.parse(line).get("class", ""))
				by[cls] = int(by.get(cls, 0)) + 1
		var parts: Array[String] = []
		var keys: Array = by.keys()
		keys.sort()
		for k: String in keys:
			parts.append("%s %d" % [k, by[k]])
		print("check_lane_drive: %d contacts (%s), %d unknown%s" % [n, ", ".join(parts), clog.unknown.size(),
				"" if clog.unknown.is_empty() else ": " + ", ".join(clog.unknown.slice(0, 5))])
		var sp: Array[String] = []
		for k: String in clog.soft_counts:
			sp.append("%s %d" % [k, clog.soft_counts[k]])
		print("check_lane_drive: soft things: %d smashes (%s), %d panels broken" % [_smashes(),
				", ".join(sp), soft.panels_broken])
		if soft_on:
			print("check_lane_drive: parked cars: %d pushes, %d walls (%d by the lane rule), %d chain pushes, %d towed" % [
					soft.pushes, soft.wedges, soft.lane_wedges, soft.chains, soft.towed])
		if sloppy:
			print("check_lane_drive: sloppy driver over %.1f km" % (_total_m / 1000.0))
	if collide != &"v1":
		print("check_lane_drive: collide %s, %d head-on kicks, %d corner pivots" % [collide, _kicks, _pivots])
	if spent:
		print("check_lane_drive: car script %.1f us a physics frame on average (%d frames, collide %s)" % [
				float(_spent_usec) / maxf(_car_frames, 1.0), _car_frames, collide])
	if write_to != "":
		var f := FileAccess.open(write_to, FileAccess.WRITE)
		f.store_string(JSON.stringify({"passed": _passed, "failed": _failed}) + "\n")
		f.close()
		print("check_lane_drive: %d links passed -> %s" % [_passed.size(), write_to])
	if _failures == 0:
		print("check_lane_drive: OK")
	else:
		print("check_lane_drive: %d of %d routes fail" % [_failures, routes.size()])
	quit(1 if _failures > 0 else 0)


## --wander: the sectors to visit (those meeting --box when given), column by column so the
## loaded neighbours carry over from one to the next.
func _start_wander(t0: int) -> void:
	_w_t0 = t0
	for k: Array in map.index_data["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		_w_have[key] = true
		var rect := Rect2(Vector2(key) * MapBuilder.SECTOR, Vector2(MapBuilder.SECTOR, MapBuilder.SECTOR))
		if box.size == Vector2.ZERO or rect.intersects(box):
			_w_keys.append(key)
	_w_keys.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.x < q.x or (p.x == q.x and p.y < q.y))
	IndexPack.pack(map.index_data)
	print("check_lane_drive: wander over %d sectors (%s city), soft things %s" % [_w_keys.size(),
			"prebuilt" if prebuilt else "runtime", _soft_word()])
	_w_rows.append("id\tkind\tmat\tx\tz\tverdict\tsecs\tdrop\tunsticks\tsector\twhy")


## --wander: sector `key` built or loaded (once while it is in reach), its soft list indexed.
func _w_load(key: Vector2i) -> Node3D:
	if _w_loaded.has(key):
		return _w_loaded[key]
	if not _w_have.has(key):
		return null
	var sector: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
			if prebuilt else map.build_sector(key)
	map.add_child(sector)
	soft.add_sector(sector)
	_w_loaded[key] = sector
	return sector


## --wander: on to the next sector with soft lines to test, its neighbours loaded and the sectors
## out of its reach freed; false when there is none left.
func _w_next_sector() -> bool:
	while true:
		_w_k += 1
		if _w_k >= _w_keys.size():
			return false
		var key := _w_keys[_w_k]
		for k: Vector2i in _w_loaded.keys():
			if maxi(absi(k.x - key.x), absi(k.y - key.y)) > 1:
				(_w_loaded[k] as Node3D).queue_free()
				_w_loaded.erase(k)
		var sector := _w_load(key)
		if sector == null or not sector.has_meta(&"soft"):
			continue
		_w_tests = _w_targets(key, sector.get_meta(&"soft"))
		if _w_tests.is_empty():
			continue
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				_w_load(key + Vector2i(dx, dz))
		_w_i = 0
		return true
	return false


## --wander: one test per soft line of the sector (its own segments, a line once however many
## sectors it crosses): the segment whose middle is nearest a ground lane within WANDER_NEAR m,
## the start on that lane and the way across. [id, kind, mat, start, a, b, dir, foot, key].
func _w_targets(key: Vector2i, sd: Dictionary) -> Array:
	var n := CityBarriers.SOFT_STRIDE
	var segs: PackedFloat64Array = sd["segs"]
	var best := {}
	for i in segs.size() / n:
		var o := i * n
		if segs[o + 10] < 0.5:
			continue
		var li := int(segs[o])
		var id := str(sd["ids"][li])
		if _w_seen.has(id):
			continue
		var a := Vector2(segs[o + 1], segs[o + 2])
		var b := Vector2(segs[o + 3], segs[o + 4])
		var m := (a + b) * 0.5
		if box.size != Vector2.ZERO and not box.has_point(m):
			continue
		var sn := graph.snap(m, WANDER_NEAR, Vector2.ZERO, true, true, true)
		if sn.is_empty():
			continue
		var e := int(sn[0])
		var q := graph.point_at(e, float(sn[2]), graph.lane_offset(e, int(sn[1])))
		var c := Geometry2D.get_closest_point_to_segment(q, a, b)
		var d := c.distance_to(q)
		if best.has(id) and float(best[id][0]) <= d:
			continue
		var u := (b - a).normalized()
		var way := (c - q).normalized() if d > 0.5 else Vector2.ZERO
		var hy := graph.height(e, float(sn[2]))
		if way == Vector2.ZERO or absf(way.dot(u)) > cos(deg_to_rad(WANDER_SQUARE)):
			# Square to the line, from the lane's point slid along the line to face the segment
			# (the lane runs along the line there), or from 3 m off a line on the lane itself.
			var nrm := u.orthogonal()
			way = nrm if nrm.dot(c - q) >= 0.0 else -nrm
			q = q + u * (c - q).dot(u) if d > 0.5 else c - way * 3.0
		var foot := minf(segs[o + 5], segs[o + 6])
		best[id] = [d, id, str(sd["kinds"][li]), str(sd["mats"][li]), Vector3(q.x, hy, q.y), a, b,
				Vector3(way.x, 0.0, way.y), foot, key]
	var out: Array = []
	for id: String in best:
		_w_seen[id] = true
		out.append((best[id] as Array).slice(1))
	return out


## --wander: one physics frame of the test now (see the header), or on to the next test or sector.
func _wander_step(dt: float) -> void:
	if _w_i >= _w_tests.size():
		if car != null:
			car.queue_free()
			car = null
		if not _w_next_sector():
			_wander_finish()
			return
		_w_phase = 0
		_w_frames = 0
		return
	var t: Array = _w_tests[_w_i]
	var start: Vector3 = t[3]
	var a: Vector2 = t[4]
	var b: Vector2 = t[5]
	var dir: Vector3 = t[6]
	var foot: float = t[7]
	if _w_phase == 0:
		# The sectors' bodies are in the space a step after they enter the tree.
		_w_frames += 1
		if _w_frames < 3:
			return
		_w_t = 0.0
		_w_low = 0.0
		if absf(start.y - foot) > WANDER_LEVEL:
			_w_done("miss", "another level (the lane at %.1f m, the line's foot at %.1f m)" % [start.y, foot])
			return
		car = Car.new()
		if handling >= 0:
			car.set_handling(handling)
		car.collide = collide
		car.ground_height = map.drive_height
		car.water_at = map.in_water
		car.kerb_feel = map.kerb_feel
		root.add_child(car)
		car.global_position = Vector3(start.x, map.drive_height(start.x, start.z, start.y + 1.0), start.z)
		car.rotation.y = atan2(-dir.x, -dir.z)
		car.vel = dir * WANDER_SPEED
		car.reset_physics_interpolation()
		soft.car = car
		soft.reset()
		soft.reset_motion()
		_w_phase = 1
		_w_crossed = false
		return
	_w_t += dt
	var p := car.global_position
	var p2 := Vector2(p.x, p.z)
	var u := (b - a).normalized()
	var nrm := u.orthogonal()
	var side0 := signf(nrm.dot(Vector2(start.x, start.z) - a))
	if side0 == 0.0:
		side0 = 1.0
	var beyond := -nrm.dot(p2 - a) * side0
	var along := (p2 - a).dot(u)
	if beyond > 0.0 and along > -2.0 and along < a.distance_to(b) + 2.0:
		_w_crossed = true
	var h: float = map.drive_height(p.x, p.z, p.y)
	_w_low = maxf(_w_low, minf(start.y, foot) - p.y)
	if p.y < -100.0 or h - p.y > 1.0:
		_w_done("sink", "%.1f m under the surface" % (h - p.y))
		return
	if car.in_water:
		_w_done("water", "in the water")
		return
	var home := p2.distance_to(Vector2(start.x, start.z))
	var back := Vector3(start.x - p.x, 0.0, start.z - p.z).normalized()
	match _w_phase:
		1:
			car.target_dir = dir
			car.braking = false
			car.throttle = clampf(WANDER_SPEED / car.top_speed(), 0.0, 1.0)
			if beyond > WANDER_PAST or _w_t > WANDER_OUT:
				if not _w_crossed:
					_w_done("miss", "never over the line in %.1f s (something hard before it)" % _w_t)
					return
				_w_phase = 2
				_w_t = 0.0
		2:
			# Reversing: the brake held, the tail goes where the stick points.
			car.target_dir = back
			car.throttle = 0.0
			car.braking = true
			if home < WANDER_HOME:
				_w_done("ok", "reversed out" + _w_drop())
				return
			if _w_t > WANDER_BACK:
				_w_phase = 3
				_w_t = 0.0
		3:
			car.target_dir = back
			car.braking = false
			car.throttle = clampf(8.0 / car.top_speed(), 0.0, 1.0)
			if home < WANDER_HOME:
				_w_done("ok", "turned and drove out" + _w_drop())
				return
			if _w_t > WANDER_TURN:
				_w_done("fall" if _w_low > WANDER_DROP else "trap", "%.0f m from its lane after reversing %.0f s and driving %.0f s%s" % [
						home, WANDER_BACK, WANDER_TURN, _w_drop()])


## --wander: the drop under the line's foot, when it is over WANDER_DROP, for the verdict's text.
func _w_drop() -> String:
	return " (down %.1f m under the line's foot)" % _w_low if _w_low > WANDER_DROP else ""


## --wander: the test's verdict into the rows (and printed when it is a finding), on to the next.
func _w_done(verdict: String, why: String) -> void:
	var t: Array = _w_tests[_w_i]
	var c: Vector2 = ((t[4] as Vector2) + (t[5] as Vector2)) * 0.5
	var key: Vector2i = t[8]
	_w_counts[verdict] = int(_w_counts.get(verdict, 0)) + 1
	var stuck := int(car.unsticks) if car != null else 0
	_w_rows.append("%s\t%s\t%s\t%.1f\t%.1f\t%s\t%.1f\t%.1f\t%d\t%d,%d\t%s" % [t[0], t[1], t[2], c.x, c.y, verdict, _w_t,
			_w_low, stuck, key.x, key.y, why])
	if verdict in ["trap", "fall", "sink", "water"] or verbose:
		print("%s %s %s (%s) at --at=%.0f,%.0f: %s" % [verdict.to_upper(), t[0], t[1], t[2], c.x, c.y, why])
	if car != null:
		car.queue_free()
		car = null
	_w_i += 1
	_w_phase = 0
	_w_frames = 0


func _wander_finish() -> void:
	if _over:
		return
	_over = true
	if write_to != "":
		var f := FileAccess.open(write_to, FileAccess.WRITE)
		f.store_string("\n".join(_w_rows) + "\n")
		f.close()
	var parts: Array[String] = []
	for k: String in ["ok", "miss", "trap", "fall", "sink", "water"]:
		parts.append("%s %d" % [k, int(_w_counts.get(k, 0))])
	print("check_lane_drive: wander: %d soft lines tested in %d sectors (%s)%s, %d ms" % [_w_rows.size() - 1,
			_w_keys.size(), ", ".join(parts), (" -> " + write_to) if write_to != "" else "", Time.get_ticks_msec() - _w_t0])
	quit(0)


## How the run's fences and hedges are, for its lines.
func _soft_word() -> String:
	if no_soft:
		return "off (--no-soft)"
	return "on (--soft)" if soft_on else "off (hard, the default)"
