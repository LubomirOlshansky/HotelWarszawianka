extends SceneTree
## Road life (scripts/road_life.gd, road_rules.gd, crash_scenes.gd's taxi check; F 2026-11-23,
## docs/design/road-life.md): its rules headless, from the committed map data and dialogue.json:
##   1. the rules (road_rules.gd): the respect floor keeps an opened ladder rung open; a hit costs
##      10 only at fault (not standing, not the ambulance into the back of the car); blocking
##      counts only moving, 4 s, with room to pull aside; giving way needs a lane change or a slow
##      car; the honk at a green;
##   2. the words: every taxi check speaker (officer, driver, passenger, onlooker) and Odholowanie
##      speaker (operator, guard, owner, onlooker) has 3+ lines,
##      every road_life tag its lines ({n} in the respect toasts), KEBAB FM's taxi_check, ambulance,
##      ambulance_hit and tow lines name {street}; Polish and English, bubbles under 70 characters, no
##      real brand;
##   3. the taxi check's layout on 60 seeded spots of the real lane graph: the patrol car behind
##      the taxi in the kerb lane without overlapping, nobody inside a car, the passenger and the
##      onlooker off the carriageway;
##   4. on a straight two-lane road with the real traffic: a taxi check (a TAXI from the pool, 0
##      draw calls of its own) is passed by six cars going round it, and the taxi is back in the
##      pool after clear();
##   5. the ambulance on that road (the police pool's shape 2, through a stand-in police): it
##      comes up behind the player's car and the toast warns; a player who moves to the kerb lane
##      is passed and gains 3; one who keeps on at 30 km/h on an empty road is gone round (no
##      thanks, no loss); one who keeps on while parked cars fill the kerb lane (no way round)
##      loses 3; it reaches the hospital at the road's end and goes back to the pool; a hit at
##      fault costs 10, near the floor what is left over it, at the floor nothing; its siren
##      follows it and stops at the end;
##   6. road life stage 2, the laweta: the VAN family's four shapes have the same parts (family()),
##      the shares add up; the Odholowanie's layout on 60 real-graph spots (the car behind the
##      laweta without overlapping, nobody inside either, the guard, the owner and the onlooker on
##      the footway); the lift's path starts at the car and ends where the loaded shape draws its
##      car; on the test road the player coming near starts the lift, the car goes back to its pool,
##      the laweta turns loaded, pulls out and drives off as traffic, the scene's pools come back.
## Prints "check_road_life: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_road_life.gd [-- --verbose]

const CrashScenes := preload("res://scripts/crash_scenes.gd")
const RoadLife := preload("res://scripts/road_life.gd")
const Rules := preload("res://scripts/road_rules.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Traffic := preload("res://scripts/traffic.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Fakes := preload("res://tools/fakes.gd")
const Models := preload("res://scripts/models.gd")
const BUBBLE := 70


## police.gd for the ambulance: its car from the pool, lights on; and its leaving.
class Police extends Node:
	var traffic: Node3D
	var phase := 0

	func ambulance_car(e: int, lane: int, s: float):
		var d = traffic.add_police(e, lane, s, 2)
		if d != null:
			traffic.set_lights(d, true)
		return d

	func scene_leave(d) -> void:
		if d != null and d.active:
			traffic.remove(d)


## What road_life.gd's install reads (game_ctx.gd's fields it uses).
class Ctx extends RefCounted:
	var traffic: Node3D
	var police: Node
	var graph: RefCounted
	var dialogue: Node
	var radio: Node
	var hud: CanvasLayer
	var wallet: Node
	var sfx: Node
	var car: Node3D
	var vehicle: Callable
	var bubbles: Control
	var missions: Node
	var flags: Variant


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_rules(digest)
	_check_lines(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_taxi_spots(g, digest)
	await _check_taxi_traffic(map, digest)
	await _check_ambulance(map, digest, "aside")
	await _check_ambulance(map, digest, "round")
	await _check_ambulance(map, digest, "blocked")
	await _check_hit(map, digest)
	_check_tow_shapes(digest)
	_check_tow_spots(g, digest)
	await _check_tow_traffic(map, digest)
	if problems.is_empty():
		print("check_road_life: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_road_life: %d problems" % problems.size())
		quit(1)


# --- 1. the rules ------------------------------------------------------------------------------

func _check_rules(digest: PackedStringArray) -> void:
	var t0 := Ladder.threshold(0)
	var t1 := Ladder.threshold(1)
	_want(Rules.respect_floor(0) == 0, "floor at 0 respect is %d" % Rules.respect_floor(0))
	_want(Rules.respect_floor(t1 + 5) == t1, "floor at %d is %d (want rung 1's %d)" % [t1 + 5, Rules.respect_floor(t1 + 5), t1])
	_want(Rules.loss_from(t1 + 5, Rules.HIT_LOSS) == 5, "a hit at %d takes %d (want 5: rung 1 stays open)" % [t1 + 5, Rules.loss_from(t1 + 5, Rules.HIT_LOSS)])
	_want(Rules.loss_from(t1, Rules.HIT_LOSS) == 0, "a hit right at rung 1's respect takes %d (want 0)" % Rules.loss_from(t1, Rules.HIT_LOSS))
	_want(Rules.loss_from(t0 + 50, Rules.HIT_LOSS) == mini(Rules.HIT_LOSS, 50), "a hit 50 over rung 0 takes %d" % Rules.loss_from(t0 + 50, Rules.HIT_LOSS))
	var fwd := Vector2(1, 0)
	var ahead := Rules.relative(Vector2.ZERO, fwd, Vector2(20, 0.5))
	_want(Rules.in_way(ahead, fwd, fwd), "a car 20 m ahead in its lane is not in its way")
	_want(not Rules.in_way(Rules.relative(Vector2.ZERO, fwd, Vector2(20, 3.2)), fwd, fwd), "a car in the next lane is in its way")
	_want(not Rules.in_way(ahead, fwd, -fwd), "an oncoming car is in its way")
	_want(not Rules.in_way(Rules.relative(Vector2.ZERO, fwd, Vector2(-8, 0)), fwd, fwd), "a car behind it is in its way")
	# The hit: lost speed driving into it is the player's fault; standing, or it from behind, not.
	_want(Rules.at_fault(6.0, 8.0, Vector2(-5.0, 0.4), 10.0), "driving into the ambulance's back is not at fault")
	_want(not Rules.at_fault(6.0, 0.3, Vector2(-5.0, 0.4), 10.0), "a standing car is at fault")
	_want(not Rules.at_fault(4.0, 5.0, Vector2(4.0, 0.3), 14.0), "the ambulance into the car's back counts as the player's fault")
	_want(not Rules.at_fault(1.0, 8.0, Vector2(-5.0, 0.4), 10.0), "a brush under BUMP is at fault")
	_want(Rules.blocking(4.5, 8.0, 2), "4.5 s in its way at 29 km/h on two lanes is not blocking")
	_want(not Rules.blocking(4.5, 1.0, 2), "a car standing in a queue is blocking")
	_want(not Rules.blocking(4.5, 8.0, 1), "a one-lane road is blocking")
	_want(not Rules.blocking(3.0, 8.0, 2), "3 s is blocking")
	_want(Rules.gave_way(0, 1, 9.0) and Rules.gave_way(0, 0, 2.0) and not Rules.gave_way(0, 0, 9.0), "gave_way's three cases")
	_want(Rules.honk_at_green(3.0, 4.0, 7.0), "no honk 3 s into a green, 4 m from the line, a car 7 m behind")
	_want(not Rules.honk_at_green(1.0, 4.0, 7.0) and not Rules.honk_at_green(3.0, 30.0, 7.0) and not Rules.honk_at_green(3.0, 4.0, 20.0),
			"a honk too soon, too far from the line or with nobody behind")
	digest.append("rules ok (floor %d at %d)" % [Rules.respect_floor(t1 + 5), t1 + 5])


func _want(ok: bool, problem: String) -> void:
	if not ok:
		problems.append("rules: " + problem)


# --- 2. the words ------------------------------------------------------------------------------

func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var counts := {}
	for group: String in ["taxi_check", "tow_scene", "road_life"]:
		var by_tag := {}
		for l: Array in all.get(group, []):
			var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
			by_tag[only] = int(by_tag.get(only, 0)) + 1
			_line_ok(group, l, banned)
			if only in ["amb_thanks", "amb_block", "amb_hit"] and (not String(l[0]).contains("{n}") or not String(l[1]).contains("{n}")):
				problems.append("%s: a respect toast without {n}: %s" % [group, l[0]])
		if by_tag.has(""):
			problems.append("%s: %d lines without a tag" % [group, by_tag[""]])
		counts[group] = by_tag
	for p: Array in CrashScenes.TAXI_PEOPLE:
		if int(counts["taxi_check"].get(p[0], 0)) < 3:
			problems.append("taxi_check: %d lines for %s (want 3+)" % [int(counts["taxi_check"].get(p[0], 0)), p[0]])
	for p: Array in CrashScenes.TOW_PEOPLE:
		if int(counts["tow_scene"].get(p[0], 0)) < 3:
			problems.append("tow_scene: %d lines for %s (want 3+)" % [int(counts["tow_scene"].get(p[0], 0)), p[0]])
	for tag: String in ["amb_behind", "amb_thanks", "amb_block", "amb_hit", "medic_block", "medic_hit", "medic_thanks", "green"]:
		if not counts["road_life"].has(tag):
			problems.append("road_life: no line for %s" % tag)
	var radio := {}
	for l: Array in all.get("radio_host", []):
		var only = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
		if only in ["taxi_check", "ambulance", "ambulance_hit", "tow"]:
			radio[only] = int(radio.get(only, 0)) + 1
			if not String(l[0]).contains("{street}") or not String(l[1]).contains("{street}"):
				problems.append("radio %s line without {street}: %s" % [only, l[0]])
			_line_ok("radio_host", l, banned, 200)
	for tag: String in ["taxi_check", "ambulance", "ambulance_hit", "tow"]:
		if int(radio.get(tag, 0)) < 2:
			problems.append("radio_host: %d %s lines (want 2+)" % [int(radio.get(tag, 0)), tag])
	digest.append("lines taxi %d, tow %d, road %d, radio %s" % [all.get("taxi_check", []).size(), all.get("tow_scene", []).size(), all.get("road_life", []).size(), radio])


func _line_ok(group: String, l: Array, banned: Array, most := BUBBLE) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without its Polish or English: %s" % [group, l])
		return
	if String(l[0]).length() >= most or String(l[1]).length() >= most:
		problems.append("%s: over %d characters: %s" % [group, most, l[0]])
	for text: String in [String(l[0]).to_lower(), String(l[1]).to_lower()]:
		for b in banned:
			var rx := RegEx.create_from_string("(^|[^\\p{L}])" + _escape(String(b)) + "($|[^\\p{L}])")
			if rx.search(text) != null:
				problems.append("%s: a real brand (%s): %s" % [group, b, l[0]])


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += "\\" + c if c in ".+*?^$()[]{}|\\" else c
	return out


# --- 3. the taxi check's layout -----------------------------------------------------------------

func _check_taxi_spots(g: LaneGraph, digest: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var found := 0
	for k in 60:
		var from := g.node_pos[rng.randi() % g.node_pos.size()]
		var spot := CrashScenes.pick_spot(g, from, Vector2.UP.rotated(rng.randf_range(-PI, PI)), rng)
		if spot.is_empty():
			continue
		found += 1
		var lay := CrashScenes.layout(g, spot, "taxi")
		var cars: Array = lay["cars"]
		if cars.size() != 2 or cars[0][0] != "police" or cars[1][0] != "taxi":
			problems.append("taxi spot %d: vehicles %s" % [k, cars.map(func(c): return c[0])])
			continue
		var e: int = spot["e"]
		var d := g.direction(e, float(spot["s0"]))
		var gap := (Vector2(cars[1][1].x, cars[1][1].z) - Vector2(cars[0][1].x, cars[0][1].z)).dot(d)
		if gap < (4.7 + 4.6) * 0.5 + 0.5:
			problems.append("taxi spot %d: the patrol car and the taxi %.1f m apart (they overlap)" % [k, gap])
		var people: Array = lay["people"]
		if people.size() != CrashScenes.TAXI_PEOPLE.size():
			problems.append("taxi spot %d: %d people" % [k, people.size()])
			continue
		for i in people.size():
			var p: Vector3 = people[i][0]
			for c: Array in cars:
				var rel := Vector2(p.x - c[1].x, p.z - c[1].z)
				var fwd := Vector2(-sin(c[2]), -cos(c[2]))
				if absf(rel.dot(fwd)) < 2.35 and absf(rel.cross(fwd)) < 0.95:
					problems.append("taxi spot %d: %s stands inside the %s" % [k, CrashScenes.TAXI_PEOPLE[i][0], c[0]])
		# The passenger and the onlooker on the footway: past the kerb.
		var lo := g.lane_offset(e, int(spot["lane"]))
		var kerb := lo + g.e_lw[e] * 0.5
		for i in [3, 4]:
			var p: Vector3 = people[i][0]
			var s := g.project(e, Vector2(p.x, p.z))
			var side := (Vector2(p.x, p.z) - g.point_at(e, s)).dot(Vector2(-g.direction(e, s).y, g.direction(e, s).x))
			if absf(side) < kerb + 1.0:
				problems.append("taxi spot %d: the %s %.1f m from the centre line (kerb at %.1f)" % [k, CrashScenes.TAXI_PEOPLE[i][0], absf(side), kerb])
	if found < 30:
		problems.append("taxi spots: %d of 60 found one (want half)" % found)
	digest.append("taxi layout %d/60 spots" % found)


# --- 4. the taxi check in traffic ----------------------------------------------------------------

func _road(map: Node3D) -> Array:
	var gd := {"nodes": [0.0, 0.0, 1200.0, 0.0], "scc": [1, 1], "ctrl": [], "poles": [], "portals": [],
			"edges": [{"a": 0, "b": 1, "p": [0.0, 0.0, 1200.0, 0.0], "k": "primary", "n": 2, "lw": 3.25, "o": 1.6,
				"v": 13.9, "s0": 1.0, "s1": 1199.0, "name": "Testowa"}]}
	var g := LaneGraph.new(gd, map)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 40.0
	root.add_child(cam)
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 50.0, 9000.0))
	var traffic: Node3D = Traffic.new()
	root.add_child(traffic)
	traffic.setup(g, map, cam, {})
	traffic.spawning = false
	traffic.player_on_road = false
	traffic.set_process(false)
	traffic.set_physics_process(false)
	return [g, traffic, cam]


func _dialogue() -> Node:
	var dlg := Dialogue.new()
	dlg.bubbles = Fakes.Bubbles.new()
	root.add_child(dlg)
	root.add_child(dlg.bubbles)
	return dlg


func _check_taxi_traffic(map: Node3D, digest: PackedStringArray) -> void:
	var made := _road(map)
	var g: LaneGraph = made[0]
	var traffic: Node3D = made[1]
	await process_frame
	var cs := CrashScenes.new()
	cs.traffic = traffic
	cs.graph = g
	cs.map = map
	cs.walkers = Fakes.Walkers.new()
	root.add_child(cs.walkers)
	cs.dialogue = _dialogue()
	cs.set_process(false)
	root.add_child(cs)
	cs.setup(3)
	var taxis0: int = traffic.get("_counts")[1]
	if not cs.place(Vector2(440.0, 1.6), Vector2(1, 0), true, Vector2(520.0, 3.2), "taxi"):
		problems.append("taxi traffic: no taxi check placed on the test road")
		return
	if cs.scene.get("kind", "") != "taxi" or (cs.scene["drivers"] as Array).size() != 1:
		problems.append("taxi traffic: the scene is %s with %d vehicles (want a taxi; no police here)" % [cs.scene.get("kind", ""), (cs.scene["drivers"] as Array).size()])
	if (cs.walkers as Fakes.Walkers).scenes.size() != CrashScenes.TAXI_PEOPLE.size():
		problems.append("taxi traffic: %d people (want %d)" % [(cs.walkers as Fakes.Walkers).scenes.size(), CrashScenes.TAXI_PEOPLE.size()])
	var taxi = cs.scene["drivers"][0]
	if taxi.kind != 1:
		problems.append("taxi traffic: the taxi is of kind %d (want TAXI)" % taxi.kind)
	var lane: int = cs.scene["lane"]
	var cars: Array = []
	for i in 6:
		var n := Node3D.new()
		root.add_child(n)
		var d = traffic.add_node_driver(n, Vector3(1.8, 1.5, 4.4), 0, lane, taxi.s - 180.0 + i * 25.0)
		d.speed_factor = 1.0
		cars.append(d)
	var passed := {}
	var inside := 0
	for f in 60 * 90:
		traffic.call("_process", 1.0 / 60.0)
		for d in cars:
			if d.s > taxi.s + 8.0 and d.s < 1100.0:
				passed[d] = true
			if absf(d.s - taxi.s) < (d.length + taxi.length) * 0.5 and absf(d.off - g.lane_offset(0, lane)) < 1.2:
				inside += 1
		if passed.size() == cars.size():
			break
	if passed.size() < cars.size():
		problems.append("taxi traffic: %d of %d cars got past in 90 s" % [passed.size(), cars.size()])
	if inside > 0:
		problems.append("taxi traffic: %d frames with a car inside the taxi" % inside)
	cs.clear()
	if traffic.get("_counts")[1] != taxis0 or taxi.active:
		problems.append("taxi traffic: the taxi is not back in the pool after clear()")
	digest.append("taxi check passed by %d/%d cars" % [passed.size(), cars.size()])
	for d in cars:
		traffic.remove(d)
	cs.queue_free()
	traffic.queue_free()
	(made[2] as Node).queue_free()
	await process_frame


# --- 5. the ambulance ----------------------------------------------------------------------------

## A road life on the test road with stand-ins; [road life, traffic, player car, wallet, hud, sfx, cam].
func _life(map: Node3D, respect: int) -> Array:
	var made := _road(map)
	var traffic: Node3D = made[1]
	var police := Police.new()
	police.traffic = traffic
	root.add_child(police)
	var ctx := Ctx.new()
	ctx.traffic = traffic
	ctx.police = police
	ctx.graph = made[0]
	ctx.dialogue = _dialogue()
	ctx.hud = Fakes.Hud.new()
	root.add_child(ctx.hud)
	ctx.wallet = Fakes.Wallet.new()
	ctx.wallet.respect = respect
	root.add_child(ctx.wallet)
	ctx.sfx = Fakes.Sfx.new()
	root.add_child(ctx.sfx)
	var car := Node3D.new()
	root.add_child(car)
	ctx.car = car
	var speed := [0.0]
	ctx.vehicle = func() -> Array: return [car.global_position, speed[0] * 3.6, false, speed[0]]
	var life := RoadLife.new()
	if not life.install(ctx):
		problems.append("ambulance: install refused with traffic and police")
	life.hospitals = [{"name": "Szpital Testowy", "pos": Vector3(1195.0, 0.0, 0.0), "children": false}]
	life.honk_on = false
	life.log_on = verbose
	life.set_process(false)
	root.add_child(life)
	life.setup(7)
	return [life, traffic, car, ctx.wallet, ctx.hud, ctx.sfx, made[2], speed]


## The player drives east at 30 km/h in the lane by the centre line; `mode` "aside": they move to
## the kerb lane once warned; "round": they keep on, the road empty; "blocked": they keep on, cars
## parked along the kerb lane from 230 to 560 m.
func _check_ambulance(map: Node3D, digest: PackedStringArray, mode: String) -> void:
	var aside := mode == "aside"
	var t1 := Ladder.threshold(1)
	var bits := _life(map, t1 + 40)
	var life = bits[0]
	var traffic: Node3D = bits[1]
	var car: Node3D = bits[2]
	var wallet = bits[3]
	var hud = bits[4]
	var sfx = bits[5]
	var speed: Array = bits[7]
	await process_frame
	var g: LaneGraph = traffic.graph
	if mode == "blocked":
		for k in 60:
			var s := 230.0 + k * 5.5
			var at := g.point_at(0, s, g.lane_offset(0, 1))
			traffic.add_parked_car(0, s, Vector3(at.x, 0.0, at.y), atan2(-1.0, 0.0), 1, 0, Color.GRAY)
	var x := 300.0
	var lane_off := g.lane_offset(0, 0)
	speed[0] = 8.3
	car.global_transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(x, 0.0, lane_off))
	traffic.player_on_road = true
	if not life.send(true):
		problems.append("ambulance (%s): send() found no start" % mode)
		return
	var d = life.run["d"]
	if d.shape != 2 or d.kind != 4 or not d.lights:
		problems.append("ambulance: kind %d shape %d lights %s (want the police pool's ambulance, lights on)" % [d.kind, d.shape, d.lights])
	var start_gap: float = x - d.pos.x
	var warned := false
	var t := 0.0
	var siren_heard := false
	var dt := 1.0 / 60.0
	var tick := 0.0
	while t < 120.0 and not life.run.is_empty():
		t += dt
		var p := car.global_position
		p.x = minf(p.x + speed[0] * dt, 1150.0)
		if aside and warned:
			lane_off = move_toward(lane_off, g.lane_offset(0, 1), 1.5 * dt)
		p.z = lane_off
		car.global_position = p
		traffic.player_pos = p
		traffic.player_vel = Vector3(speed[0], 0.0, 0.0)
		traffic.call("_process", dt)
		tick += dt
		if tick >= RoadLife.TICK:
			life.step(tick)
			tick = 0.0
		if (hud.toasts as Array).size() > 0:
			warned = true
		if sfx.siren != Vector3.INF:
			siren_heard = true
	var want: int = {"aside": Rules.THANKS_GAIN, "round": 0, "blocked": -Rules.BLOCK_LOSS}[mode]
	var got: int = wallet.respect - (t1 + 40)
	if got != want:
		problems.append("ambulance (%s): respect %+d (want %+d; toasts %s)" % [mode, got, want, hud.toasts])
	if not warned:
		problems.append("ambulance (%s): no KARETKA Z TYŁU toast" % mode)
	if not siren_heard or sfx.siren != Vector3.INF:
		problems.append("ambulance: the siren %s" % ("never played" if not siren_heard else "still plays after the run"))
	if not life.run.is_empty():
		problems.append("ambulance (%s): still out after %.0f s" % [mode, t])
	if d.active:
		problems.append("ambulance: not back in the pool after its run")
	if mode != "blocked" and not life.reached:
		problems.append("ambulance (%s): never reached the hospital" % mode)
	digest.append("ambulance %s: started %.0f m back, %+d respect, run %.0f s" % [mode, start_gap, got, t])
	_free(bits)
	await process_frame


## The hit: at fault 10 taken (rung kept), at the floor nothing.
func _check_hit(map: Node3D, digest: PackedStringArray) -> void:
	var t1 := Ladder.threshold(1)
	for r: int in [t1 + 30, t1 + 4, t1]:
		var bits := _life(map, r)
		var life = bits[0]
		var traffic: Node3D = bits[1]
		var car: Node3D = bits[2]
		var wallet = bits[3]
		await process_frame
		car.global_transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(400.0, 0.0, traffic.graph.lane_offset(0, 0)))
		(bits[7] as Array)[0] = 9.0
		if not life.send(true):
			problems.append("hit: send() found no start")
			_free(bits)
			continue
		var d = life.run["d"]
		# The player's car drives into the ambulance's back: it is ahead of them.
		d.pos = Vector3(406.0, 0.0, traffic.graph.lane_offset(0, 0))
		d.v = 3.0
		life._on_bumped(d, 7.0)
		life._on_bumped(d, 7.0)  # once per ambulance
		var want := mini(Rules.HIT_LOSS, r - Rules.respect_floor(r))
		if r - wallet.respect != want:
			problems.append("hit at %d respect: took %d (want %d)" % [r, r - wallet.respect, want])
		_free(bits)
		await process_frame
	digest.append("hits at fault take 10 / 4 / 0 above rung 1")


func _free(bits: Array) -> void:
	var life = bits[0]
	if not life.run.is_empty():
		life._end("test")
	for b in bits:
		if b is Node:
			(b as Node).queue_free()


# --- 6. the laweta and the Odholowanie -----------------------------------------------------------

func _check_tow_shapes(digest: PackedStringArray) -> void:
	var looks: Array = Models.TRAFFIC[2]
	if looks.size() != 4 or looks[Models.VAN_TOW]["name"] != "tow truck" or looks[Models.VAN_TOW_LOADED]["name"] != "tow truck loaded":
		problems.append("laweta: the VAN family's shapes are %s" % [looks.map(func(l): return l["name"])])
		return
	var share := 0.0
	for l: Dictionary in looks:
		share += float(l["share"])
	if absf(share - 1.0) > 0.001:
		problems.append("laweta: the VAN shares add up to %.2f" % share)
	var counts: Array = []
	for i in 4:
		counts.append(Models._van(i).pos.size())
	if counts.count(counts[0]) != 4:
		problems.append("laweta: the VAN family's shapes have %s vertices (want the same)" % [counts])
	if float(looks[2]["share"]) != 0.0 or float(looks[3]["share"]) != 0.0:
		problems.append("laweta: a random van share for the laweta (traffic.gd TOW_CHANCE picks them)")
	digest.append("laweta: VAN family 4 shapes of %d vertices, tow trucks %.0f %% of vans" % [counts[0], 100.0 * Traffic.TOW_CHANCE])


func _check_tow_spots(g: LaneGraph, digest: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var found := 0
	var worst := 0.0
	for k in 60:
		var from := g.node_pos[rng.randi() % g.node_pos.size()]
		var spot := CrashScenes.pick_spot(g, from, Vector2.UP.rotated(rng.randf_range(-PI, PI)), rng)
		if spot.is_empty():
			continue
		found += 1
		var lay := CrashScenes.layout(g, spot, "tow")
		var cars: Array = lay["cars"]
		if cars.size() != 2 or cars[0][0] != "car" or cars[1][0] != "tow":
			problems.append("tow spot %d: vehicles %s" % [k, cars.map(func(c): return c[0])])
			continue
		var e: int = spot["e"]
		var d := g.direction(e, float(spot["s0"]))
		var gap := (Vector2(cars[1][1].x, cars[1][1].z) - Vector2(cars[0][1].x, cars[0][1].z)).dot(d)
		if gap < (3.95 + 6.6) * 0.5 + 1.0:
			problems.append("tow spot %d: the car and the laweta %.1f m apart (they overlap)" % [k, gap])
		var people: Array = lay["people"]
		if people.size() != CrashScenes.TOW_PEOPLE.size():
			problems.append("tow spot %d: %d people" % [k, people.size()])
			continue
		var lens := {"car": 3.95, "tow": 6.6}
		for i in people.size():
			var p: Vector3 = people[i][0]
			for c: Array in cars:
				var rel := Vector2(p.x - c[1].x, p.z - c[1].z)
				var fwd := Vector2(-sin(c[2]), -cos(c[2]))
				if absf(rel.dot(fwd)) < float(lens[c[0]]) * 0.5 + 0.3 and absf(rel.cross(fwd)) < 1.35:
					problems.append("tow spot %d: the %s stands inside the %s" % [k, CrashScenes.TOW_PEOPLE[i][0], c[0]])
		var lo := g.lane_offset(e, int(spot["lane"]))
		var kerb := lo + g.e_lw[e] * 0.5
		for i in [1, 2, 3]:
			var p: Vector3 = people[i][0]
			var s := g.project(e, Vector2(p.x, p.z))
			var side := (Vector2(p.x, p.z) - g.point_at(e, s)).dot(Vector2(-g.direction(e, s).y, g.direction(e, s).x))
			if absf(side) < kerb + 1.0:
				problems.append("tow spot %d: the %s %.1f m from the centre line (kerb at %.1f)" % [k, CrashScenes.TOW_PEOPLE[i][0], absf(side), kerb])
		# The lift: from the car where it stands to where the loaded shape draws its car.
		var a: Array = CrashScenes.load_path(cars[0][1], cars[0][2], cars[1][1], cars[1][2], 0.0)
		var b: Array = CrashScenes.load_path(cars[0][1], cars[0][2], cars[1][1], cars[1][2], 1.0)
		var on: Vector3 = cars[1][1] + Basis(Vector3.UP, cars[1][2]) * Models.TOW_LOAD_AT
		worst = maxf(worst, maxf((a[0] as Vector3).distance_to(cars[0][1]), (b[0] as Vector3).distance_to(on)))
		if absf(angle_difference(float(b[1]), float(cars[1][2]))) > 0.001:
			problems.append("tow spot %d: the lifted car ends turned %.2f rad off the laweta" % [k, angle_difference(float(b[1]), float(cars[1][2]))])
	if worst > 0.01:
		problems.append("tow spots: the lift's path misses its ends by %.2f m" % worst)
	if found < 30:
		problems.append("tow spots: %d of 60 found one (want half)" % found)
	digest.append("tow layout %d/60 spots" % found)


func _check_tow_traffic(map: Node3D, digest: PackedStringArray) -> void:
	var made := _road(map)
	var g: LaneGraph = made[0]
	var traffic: Node3D = made[1]
	await process_frame
	var cs := CrashScenes.new()
	cs.traffic = traffic
	cs.graph = g
	cs.map = map
	cs.walkers = Fakes.Walkers.new()
	root.add_child(cs.walkers)
	cs.dialogue = _dialogue()
	var player := [Vector3(150.0, 0.0, 1.6)]
	cs.vehicle = func() -> Array: return [player[0], 0.0, false]
	cs.set_process(false)
	root.add_child(cs)
	cs.setup(5)
	var counts0: Array = (traffic.get("_counts") as Array).duplicate()
	if not cs.place(Vector2(440.0, 1.6), Vector2(1, 0), true, Vector2(520.0, 3.2), "tow"):
		problems.append("tow traffic: no Odholowanie placed on the test road")
		return
	var drivers: Array = cs.scene["drivers"]
	if cs.scene.get("kind", "") != "tow" or drivers.size() != 2:
		problems.append("tow traffic: the scene is %s with %d vehicles (want the car and the laweta)" % [cs.scene.get("kind", ""), drivers.size()])
		return
	var car = drivers[0]
	var tow = drivers[1]
	if car.kind != 0 or car.paint != Models.TOW_LOAD_PAINT or tow.kind != 2 or tow.shape != Models.VAN_TOW:
		problems.append("tow traffic: car kind %d paint %s, laweta kind %d shape %d" % [car.kind, car.paint.to_html(false), tow.kind, tow.shape])
	if (cs.walkers as Fakes.Walkers).scenes.size() != CrashScenes.TOW_PEOPLE.size():
		problems.append("tow traffic: %d people (want %d)" % [(cs.walkers as Fakes.Walkers).scenes.size(), CrashScenes.TOW_PEOPLE.size()])
	# Far away nothing happens; near, the lift starts, ends on the platform, and the laweta goes.
	var dt := 1.0 / 60.0
	var start_s: float = tow.s
	var loaded_at := -1.0
	var left_at := -1.0
	var jump := 0.0
	for f in 60 * 40:
		var t := f * dt
		if t > 6.0:
			player[0] = Vector3(cs.scene["mid"].x - 30.0, 0.0, 1.6) if not cs.scene.is_empty() else player[0]
		var before: Vector3 = car.pos
		cs.call("_process", dt)
		traffic.call("_process", dt)
		if car.active and loaded_at < 0.0:
			jump = maxf(jump, before.distance_to(car.pos))
		if t < 6.0 and cs.scene.get("tow_stage", 0) != 0:
			problems.append("tow traffic: the lift started with the player %.0f m away" % player[0].distance_to(tow.pos))
			break
		if loaded_at < 0.0 and cs.scene.get("tow_stage", 0) >= 2:
			loaded_at = t
		if left_at < 0.0 and cs.towed > 0:
			left_at = t
		if left_at > 0.0 and t > left_at + 8.0:
			break
	if loaded_at < 0.0:
		problems.append("tow traffic: the car never got onto the laweta")
	elif car.active or tow.shape != Models.VAN_TOW_LOADED:
		problems.append("tow traffic: loaded, but the car is %s and the laweta's shape %d" % ["still out" if car.active else "back", tow.shape])
	if jump > 0.5:
		problems.append("tow traffic: the lifted car jumped %.2f m in a frame" % jump)
	if left_at < 0.0:
		problems.append("tow traffic: the loaded laweta never left")
	elif tow.parked or tow.persistent or tow.s - start_s < 15.0:
		problems.append("tow traffic: the laweta left but is parked %s, persistent %s, %.0f m on" % [tow.parked, tow.persistent, tow.s - start_s])
	cs.clear()
	if tow.active:
		traffic.remove(tow)
	var counts1: Array = traffic.get("_counts")
	if counts1[0] != counts0[0] or counts1[2] != counts0[2]:
		problems.append("tow traffic: pools CAR %d → %d, VAN %d → %d after the scene" % [counts0[0], counts1[0], counts0[2], counts1[2]])
	digest.append("Odholowanie: loaded %.1f s in, left %.1f s later, %.0f m on" % [loaded_at, left_at - loaded_at, tow.s - start_s])
	cs.queue_free()
	traffic.queue_free()
	(made[2] as Node).queue_free()
	await process_frame
