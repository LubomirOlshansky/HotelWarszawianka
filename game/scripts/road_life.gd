extends Node
## Road life (F, 2026-11-23: "оживити дороги"; plan https://claude.ai/artifact/SrDXMWUXdudeWwfqSXg6wB,
## docs/design/road-life.md): the moving things on the roads that the player meets, beside the
## standing scenes (crash_scenes.gd: the fender bender and the taxi check).
##
## **The ambulance on a call (karetka na sygnale).** Every FIRST, then GAP seconds, with nothing
## hushing it (`hushed`: a race, a police chase or pull-over, the first minutes' guide, the
## helicopter), an ambulance comes up behind the player's car on the road they drive, AHEAD m back
## and out of sight, its blue lamps going and its own yelp (sfx.gd `ambulance_siren`, not the
## police's two tones), racing to a hospital (rescue_places.gd, the rescues' own) by the racers'
## driver (traffic.gd `race_to`: through reds with care, round slower cars; the traffic ahead pulls
## over for it as for any light bar, `_give_way_to_sirens`). It is the police pool's shape 2
## (police.gd `ambulance_car`, role "ambulance": +0 draw calls, a bump is never an offence).
## Off screen near the player its mark sits at the screen's edge (hud.gd `ambulance_edge`: a yellow
## disc with a red cross). KEBAB FM's host reads it out (`radio_host` "ambulance").
##
## The player's part (road_rules.gd, F's choice "−10, але чесно"): in its way, a toast says
## KARETKA Z TYŁU; letting it pass gives +3 respect (KORYTARZ ŻYCIA!) and a paramedic's thanks;
## driving on in its way for 4 s on a road with room to pull aside costs 3; hitting it costs 10,
## only when it was the player's fault and never below the ladder rung reached, with a shout from
## the paramedic and the radio. Once each per ambulance.
##
## **The fire engine on a call (stage 3, F 2026-11-23 "мені всі ідеї подобаються").** FIRE_SHARE of
## the runs are a fire engine instead (the BUS pool's models.gd BUS_FIRE, traffic.gd
## `add_fire_engine`: +0 draw calls), a little slower (FIRE_TOP), with its own slow wail (sfx.gd
## `ambulance_siren(at, true)`) and edge mark (a red disc with a white flame), racing to a fire: a
## graph node FIRE_RUN m ahead the way the player drives. The same rules and respect as the
## ambulance, a firefighter's lines; a bump comes by traffic.gd `bumped_siren`. Done, it switches
## its lights off and joins the traffic until the band lets it go out of sight.
##
## **"Zielone!"** The player's car stands at a light that went green GREEN_WAIT s ago with a car
## behind it: that car honks (sfx.gd `horn`) and its driver shouts (dialogue.json `road_life`
## "green"); at most once every HONK_GAP s.
##
## **The Elka (2026-11-26).** traffic.gd dresses a few of the band's cars as a driving school's
## Elka (ELKA_CHANCE, the L box on the roof: models.gd `_dress`, +0 draw calls), slow and careful.
## Tailing one for ELKA_TAIL s, its instructor or learner speaks up (`road_life` "elka_*"); the
## player's horn behind one (`honk`) gets the instructor's look.
##
## **The wedding convoy (orszak weselny, 2026-11-26).** Now and then by day (WED_HOURS) WED_CARS
## cars with white ribbons and a bouquet on the bonnet (traffic.gd `add_car`, DRESS_WEDDING: the
## CAR MultiMesh) drive in a column a little slower than the town, ahead of the player the way they
## drive, to a far junction (their church; one bounded route shared by the column), never through
## a red. Near the player they honk all the way (sfx.gd horns, WED_HONK) and shout "Gorzko!"; the
## player's horn by them makes them a wedding guest once a convoy (+WED_GUEST_GAIN respect).
##
## Nothing draws (the ambulance is in the police MultiMesh, the mark in the HUD's police overlay);
## the work is a tick at TICK (4 Hz) and one shortest-path table per hospital, made the first
## time that hospital is wanted and kept.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Rules := preload("res://scripts/road_rules.gd")
const Messages := preload("res://scripts/messages.gd")
const Models := preload("res://scripts/models.gd")
const Traffic := preload("res://scripts/traffic.gd")

const TICK := 0.25
## Seconds to the first ambulance, and from one leaving to the next.
const FIRST := Vector2(150.0, 300.0)
const GAP := Vector2(210.0, 400.0)
## Where it starts: this many metres back along the player's road (out of sight).
const AHEAD := Vector2(110.0, 170.0)
## Its pace: top speed (m/s, ~72 km/h; RACE_CLASS_TOP caps it by road), pull and corner grip.
const TOP := 20.0
const ACCEL := 3.2
const LAT := 6.0
## A hospital it heads to is at least this far (m) from where it starts, by road.
const MIN_RUN := 500.0
## It leaves: at the hospital (or REACHED m from it), after LIFE s, or FAR m from the player out of
## sight; after arriving in view it drives on, lights off, until out of sight (at most LINGER s).
const REACHED := 25.0
const LIFE := 150.0
const FAR := 520.0
const LINGER := 40.0
## Its edge mark and the "behind you" toast: within MARK_NEAR m of the player.
const MARK_NEAR := 130.0
const BEHIND_TOAST := 70.0
## The honk at a green: at most once every HONK_GAP s, and only HONK_CHANCE of the times it could.
const HONK_GAP := 120.0
const HONK_CHANCE := 0.6
const LINES := "road_life"
const RADIO_GROUP := "radio_host"
const MEDIC := Color("#ffd23f")
## Stage 3: the share of runs that are a fire engine, its racer stats, how far its fire is (straight
## line, m), the search bound of its one route (m), and its crew's bubble colour.
const FIRE_SHARE := 0.35
const FIRE_TOP := 16.5
const FIRE_ACCEL := 2.4
const FIRE_RUN := Vector2(500.0, 1100.0)
const FIRE_ROUTE := 2600.0
const FIREMAN := Color("#ff7a3d")
## The Elka: how near ahead (m) and how long (s) the player tails one before a line, the side room
## (m) of "behind it", the least gap between its lines (s), the horn's reach (m), its bubble colour.
const ELKA_NEAR := 18.0
const ELKA_TAIL := 3.0
const ELKA_SIDE := 1.8
const ELKA_GAP := 35.0
const ELKA_HONK := 25.0
const ELKA_BUBBLE := Color("#5b9bf0")
## The wedding convoy: seconds to the first and between them, its hours, its cars, their spacing (m),
## where it starts ahead of the player (m along their road), how far its church is (m, straight;
## reached by road within WED_ROUTE m), its pace (× the road's speed), its longest run (s), where
## its horns are heard (m), the gap between honks (s), its shouts at most and their gap (s), the
## guest's reach (m) and respect, and its bubble colour.
const WED_FIRST := Vector2(200.0, 420.0)
const WED_GAP := Vector2(480.0, 900.0)
const WED_HOURS := Vector2(12.0, 21.0)
const WED_CARS := 4
const WED_SPACING := 10.0
const WED_AHEAD := Vector2(110.0, 160.0)
const WED_RUN := Vector2(600.0, 1200.0)
const WED_ROUTE := 2800.0
const WED_PACE := 0.8
const WED_LIFE := 220.0
const WED_HEAR := 45.0
const WED_HONK := Vector2(0.5, 1.6)
const WED_SHOUTS := 3
const WED_SHOUT_GAP := 3.5
const WED_GUEST_NEAR := 30.0
const WED_GUEST_GAIN := 1
const WED_BUBBLE := Color("#f29bb8")
const WED_LEADER_PAINTS := ["#f4f4f0", "#1c1d20"]

## Set by `install` (game_ctx.gd).
var traffic: Node3D
var graph: LaneGraph
var police: Node
var dialogue: Node
var radio: Node
var hud: Node
var wallet: Node
var sfx: Node
var car: Node3D
## [position, km/h, flying, forward m/s] of the player's vehicle.
var vehicle: Callable
## A world point on the HUD (pixels), for the edge mark.
var project: Callable
## The hospitals (rescue_places.gd `hospitals`: {pos, ...}).
var hospitals: Array = []
## True while no ambulance may start (main.gd: a race, a chase, the guide).
var hushed: Callable
## The hour of the local clock (game_ctx.gd `hour`, 0-24; empty: noon).
var hour: Callable
var log_on := false
## The ambulance on or off (--ambulance=0), the honk on or off.
var ambulance_on := true
var honk_on := true
## The wedding convoys on or off (--wedding=0), the Elkas' lines on or off.
var wedding_on := true
var elka_on := true
## The wedding convoy now ({} = none), the seconds to the next; this session's convoys, guests,
## honks, shouts and Elka lines (the checks, the log).
var convoy := {}
var wed_wait := 0.0
var convoys := 0
var guests := 0
var wed_honks := 0
var wed_shouts := 0
var elka_lines := 0
var _elka_t := 0.0
var _elka_wait := 0.0
var _elka_turn := 0
var _elka_honk_at := -INF
var _wed_now := false

## Seconds to the next ambulance; the run now ({} = none).
var wait := 0.0
var run := {}
## This session: ambulances sent, let through, blocked, hit at fault, honks at a green.
var sent := 0
var thanked := 0
var blocked := 0
var hits := 0
var honks := 0
var fires := 0
## The fire engines' share now (a check sets 0 or 1).
var fire_share := FIRE_SHARE
## The last ambulance reached its hospital (the check).
var reached := false
var spent_usec := 0
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _clock := 0.0
## Hospital graph node -> distances_to it (made once each).
var _routes := {}
var _green_t := 0.0
var _honk_wait := 0.0
## --ambulance=now: one comes up close behind soon after the start.
var _test_now := false


## Copies what it needs from the ctx; false when there is no traffic or police (nothing to drive).
func install(ctx) -> bool:
	traffic = ctx.traffic
	police = ctx.police
	if traffic == null or police == null:
		return false
	graph = ctx.graph
	dialogue = ctx.dialogue
	radio = ctx.radio
	hud = ctx.hud
	wallet = ctx.wallet
	sfx = ctx.sfx
	car = ctx.car
	vehicle = ctx.vehicle
	hour = ctx.hour
	if ctx.bubbles != null:
		project = ctx.bubbles.project
	if ctx.missions != null:
		hospitals = ctx.missions.places.hospitals
	# Its test flags (dev_flags.gd): off in a test run unless asked for, as the crash scenes.
	var f = ctx.flags
	if f != null:
		log_on = f.road_log
		_test_now = f.ambulance_flag == "now" or f.ambulance_flag == "fire"
		if f.ambulance_flag == "fire":
			fire_share = 1.0
		ambulance_on = f.ambulance_flag != "0" and (f._crash_auto or f.ambulance_flag != "")
		honk_on = f._crash_auto or f.ambulance_flag != ""
		wedding_on = f.wedding_flag != "0" and (f._crash_auto or f.wedding_flag != "")
		_wed_now = f.wedding_flag == "now"
		elka_on = f._crash_auto or f.elka_flag > 0.0
	return true


func setup(seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	wait = _rng.randf_range(FIRST.x, FIRST.y)
	_honk_wait = 30.0
	wed_wait = _rng.randf_range(WED_FIRST.x, WED_FIRST.y)
	if traffic.has_signal("bumped_police"):
		traffic.bumped_police.connect(_on_bumped)
	if traffic.has_signal("bumped_siren"):
		traffic.bumped_siren.connect(_on_bumped)
	if _test_now:
		get_tree().create_timer(2.0).timeout.connect(func() -> void: send(true))
	if _wed_now:
		get_tree().create_timer(2.0).timeout.connect(func() -> void: send_convoy(true))
	_log("first ambulance in %.0f s (%d hospitals)" % [wait, hospitals.size()])


func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	if _t >= TICK:
		step(_t)
		_t = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func _exit_tree() -> void:
	if log_on:
		_log("end (%d sent, %d of them fire engines, %d let through, %d blocked, %d hit, %d honks; %d convoys, %d guests, %d Elka lines)" % [
				sent, fires, thanked, blocked, hits, honks, convoys, guests, elka_lines])


## One tick, `dt` seconds after the last.
func step(dt: float) -> void:
	_clock += dt
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false, 0.0]
	if ambulance_on:
		if run.is_empty():
			wait -= dt
			if wait <= 0.0:
				if bool(v[2]) or (hushed.is_valid() and bool(hushed.call())):
					wait = 5.0
				elif not send(false):
					wait = 4.0  # nowhere fitting now: soon again
		else:
			_follow(dt, v)
	if honk_on:
		_green_step(dt, v)
	if wedding_on:
		if convoy.is_empty():
			wed_wait -= dt
			if wed_wait <= 0.0:
				var h: float = float(hour.call()) if hour.is_valid() else 12.0
				if bool(v[2]) or (hushed.is_valid() and bool(hushed.call())) or not run.is_empty() \
						or h < WED_HOURS.x or h >= WED_HOURS.y:
					wed_wait = 20.0
				elif not send_convoy(false):
					wed_wait = 6.0
		else:
			_convoy_step(dt, v)
	if elka_on:
		_elka_step(dt, v)


# --- the ambulance ---------------------------------------------------------------------------

## The player's road and heading now: {e, s, fwd} (the edge whose direction goes their way), or {}.
func _player_road() -> Dictionary:
	if car == null:
		return {}
	var p := Vector2(car.global_position.x, car.global_position.z)
	var b := car.global_transform.basis.z
	var fwd := -Vector2(b.x, b.z).normalized()
	var hit: Array = graph.snap(p, 8.0, fwd, true, false, true)
	if hit.is_empty():
		return {}
	var e: int = hit[0]
	if graph.direction(e, hit[2]).dot(fwd) < 0.5:
		return {}
	return {"e": e, "lane": int(hit[1]), "s": float(hit[2]), "fwd": fwd}


## The lane the player's car is in now (the lane graph's index on their road), or -1.
func _player_lane() -> int:
	var road := _player_road()
	return int(road["lane"]) if not road.is_empty() else -1


## A start `back` metres behind (e, s) along the roads into it (the straightest way in at each
## junction, main and secondary roads first): {e, lane, s}, or {} when the roads run out.
func _behind(e: int, s: float, back: float) -> Dictionary:
	var left := back
	for hop in 8:
		var room := s - graph.e_s0[e] - 4.0
		if room >= left:
			return {"e": e, "lane": 0, "s": s - left}
		left -= maxf(room, 0.0)
		var best := -1
		var best_k := -INF
		var into: Vector2 = graph.direction(e, graph.e_s0[e])
		for f: int in graph.node_in[graph.e_a[e]]:
			if graph.e_tn[f] >= 0 or graph.e_dk[f] >= 0:
				continue
			var k := graph.direction(f, graph.e_s1[f]).dot(into) - 0.4 * graph.e_class[f]
			if k > best_k:
				best_k = k
				best = f
		if best < 0:
			return {}
		e = best
		s = graph.e_s1[e]
	return {}


## Sends an ambulance (or, FIRE_SHARE of the time, a fire engine) up behind the player (`near`: a
## test's, 40-60 m back and maybe in view). True if one set off.
func send(near: bool) -> bool:
	if not run.is_empty() or police == null:
		return false
	var road := _player_road()
	if road.is_empty():
		return false
	var fire := _rng.randf() < fire_share
	if not fire and hospitals.is_empty():
		return false
	var back := _rng.randf_range(40.0, 60.0) if near else _rng.randf_range(AHEAD.x, AHEAD.y)
	var start := _behind(int(road["e"]), float(road["s"]), back)
	if start.is_empty():
		return false
	var e: int = start["e"]
	var s: float = start["s"]
	# The lane by the centre line (lane 0): the traffic pulls over to the kerb for it.
	var lane := 0
	var at := graph.point_at(e, s, graph.lane_offset(e, lane))
	if not near and traffic.on_screen(Vector3(at.x, graph.height(e, s), at.y), 3.4 if fire else 2.6):
		return false
	var room := 8.0 if fire else 6.0
	if not traffic.lane_free(e, lane, s - room, s + room, 2.0):
		return false
	var goal := _fire_for(e, s, road["fwd"]) if fire else _hospital_for(e, s, road["fwd"])
	if goal.is_empty():
		return false
	var d = traffic.add_fire_engine(e, lane, s) if fire else police.ambulance_car(e, lane, s)
	if d == null:
		return false
	if fire:
		traffic.set_lights(d, true)
		fires += 1
	_arm(d, fire)
	traffic.race_to(d, int(goal["node"]), goal["dist"])
	d.v = 10.0 if fire else 12.0
	sent += 1
	run = {"d": d, "fire": fire, "age": 0.0, "way_t": 0.0, "warned": false, "was_in_way": false, "thanked": false,
			"blocked": false, "hit": false, "done": false, "linger": 0.0, "goal": goal["name"], "lane0": -1}
	_log("%s %d from %d,%d (edge %d, %.0f m back) to %s, %.0f m by road" % [_what(), sent, roundi(at.x), roundi(at.y),
			e, back, goal["name"], traffic.remaining(d)])
	_announce(graph.e_name[e], "fire" if fire else "ambulance")
	return true


## "fire engine" or "ambulance" for the log.
func _what() -> String:
	return "fire engine" if bool(run.get("fire", false)) else "ambulance"


## The ambulance's racer stats (traffic.gd's racer mode, as a crazy driver's, but careful: no
## blocks, no mistakes); `fire`: the fire engine's, slower.
func _arm(d, fire := false) -> void:
	d.race_top = FIRE_TOP if fire else TOP
	d.race_accel = FIRE_ACCEL if fire else ACCEL
	d.race_lat = LAT
	d.race_block = 0.0
	d.race_mistake = 0.0
	d.race_share = 1.0
	d.race_effort = 1.0
	d.race_corner = 1.0
	d.race_boost = 1.0
	d.speed_factor = 1.0


## The hospital it heads for from (e, s): reachable, at least MIN_RUN m by road, the one most the
## way the player drives (`fwd`), so its road runs with theirs a while: {node, dist, name}.
func _hospital_for(e: int, s: float, fwd: Vector2) -> Dictionary:
	var from := graph.point_at(e, s)
	var best := {}
	var best_k := -INF
	for h: Dictionary in hospitals:
		var hp := Vector2((h["pos"] as Vector3).x, (h["pos"] as Vector3).z)
		var node := _node_near(hp)
		if node < 0:
			continue
		var k := (hp - from).normalized().dot(fwd)
		if k <= best_k:
			continue
		var dist := _route_to(node)
		var left := graph.remaining(dist, e, s)
		if left == INF or left < MIN_RUN:
			continue
		best_k = k
		best = {"node": node, "dist": dist, "name": str(h.get("name", "?"))}
	return best


## The fire engine's fire from (e, s): a graph node FIRE_RUN m away the way the player drives
## (`fwd`, the most ahead of a few drawn at random), at least MIN_RUN m by road and reachable
## within FIRE_ROUTE m (one bounded shortest-path search, not kept): {node, dist, name}, or {}.
func _fire_for(e: int, s: float, fwd: Vector2) -> Dictionary:
	return _node_ahead(e, s, fwd, FIRE_RUN, FIRE_ROUTE, "a fire")


## A graph node `run` m away (straight line) from (e, s) the way `fwd` points (the most ahead of a
## few drawn at random), at least MIN_RUN m by road and reachable within `bound` m (one bounded
## shortest-path search, not kept): {node, dist, name} (`what` by node n), or {}.
func _node_ahead(e: int, s: float, fwd: Vector2, run_m: Vector2, bound: float, what: String) -> Dictionary:
	var from := graph.point_at(e, s)
	var n_all: int = graph.node_pos.size()
	if n_all == 0:
		return {}
	var picks: Array = []
	for i in 48:
		var n := _rng.randi() % n_all
		var q: Vector2 = graph.node_pos[n] - from
		var far := q.length()
		if far < run_m.x or far > run_m.y or graph.node_in[n].is_empty():
			continue
		var k := q.normalized().dot(fwd)
		if k > 0.3:
			picks.append([k, n])
	picks.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for i in mini(picks.size(), 3):
		var node: int = picks[i][1]
		var dist := graph.distances_to(node, bound)
		var left := graph.remaining(dist, e, s)
		if left != INF and left >= MIN_RUN:
			return {"node": node, "dist": dist, "name": "%s by node %d" % [what, node]}
	return {}


## The graph node nearest a hospital's door (the nearer end of the road nearest it), or -1.
func _node_near(p: Vector2) -> int:
	var hit: Array = graph.snap(p, 120.0, Vector2.ZERO, true)
	if hit.is_empty():
		return -1
	var e: int = hit[0]
	var node: int = graph.e_b[e]
	if graph.node_pos[graph.e_a[e]].distance_to(p) < graph.node_pos[node].distance_to(p):
		node = graph.e_a[e]
	return node


func _route_to(node: int) -> PackedFloat32Array:
	if not _routes.has(node):
		_routes[node] = graph.distances_to(node)
	return _routes[node]


## The run's tick: where the ambulance is against the player, the rules, its sound and mark, and
## its end.
func _follow(dt: float, v: Array) -> void:
	var d = run["d"]
	if not d.active:
		_end("gone")
		return
	run["age"] = float(run["age"]) + dt
	var amb := Vector2(d.pos.x, d.pos.z)
	var p: Vector3 = v[0]
	var me := Vector2(p.x, p.z)
	var dist := amb.distance_to(me)
	var seen: bool = traffic.on_screen(d.pos, d.size.y)
	if not bool(run["done"]):
		# An ambulance on a call owes nothing of the town's delay out of sight (traffic.gd AWAY_*):
		# the traffic gives way to it.
		d.away_debt = 0.0
		var there: bool = d.arrived or traffic.remaining(d) < REACHED
		if there or float(run["age"]) > LIFE:
			run["done"] = true
			traffic.stop_racing(d)
			traffic.set_lights(d, false)
			reached = there
			_log("%s at %s (%.0f s)" % [_what(), run["goal"], run["age"]] if there else "%s gave up after %.0f s" % [_what(), run["age"]])
		elif not bool(v[2]):
			_rules(d, amb, me, v)
	else:
		run["linger"] = float(run["linger"]) + dt
	if (bool(run["done"]) or dist > FAR) and (not seen or float(run["linger"]) > LINGER):
		_end("done" if bool(run["done"]) else "far")
		return
	var fire := bool(run["fire"])
	if sfx != null:
		sfx.ambulance_siren(Vector3.INF if bool(run["done"]) else d.pos + Vector3.UP * (2.6 if fire else 1.6), fire)
	if hud != null and hud.has_method("ambulance_edge"):
		var mark := not bool(run["done"]) and not seen and dist < MARK_NEAR and project.is_valid()
		hud.ambulance_edge(project.call(d.pos + Vector3.UP * 1.2) if mark else Vector2.INF, fire)


## The player's part (road_rules.gd): the warning, giving way, blocking.
func _rules(d, amb: Vector2, me: Vector2, v: Array) -> void:
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	var b := car.global_transform.basis.z
	var pf := -Vector2(b.x, b.z).normalized()
	var rel := Rules.relative(amb, fwd, me)
	var pv: float = float(v[3]) if v.size() > 3 else float(v[1]) / 3.6
	var way := Rules.in_way(rel, fwd, pf)
	if way:
		if not bool(run["was_in_way"]):
			run["lane0"] = _player_lane()
		run["was_in_way"] = true
		run["way_t"] = float(run["way_t"]) + TICK
		if not bool(run["warned"]) and rel.x < BEHIND_TOAST:
			run["warned"] = true
			_toast(_tag("behind"), 0)
		var lanes: int = graph.e_lanes[d.edge] if not d.in_conn else 1
		if not bool(run["blocked"]) and not bool(run["thanked"]) and Rules.blocking(float(run["way_t"]), pv, lanes):
			run["blocked"] = true
			blocked += 1
			var took: int = wallet.lose_respect(Rules.BLOCK_LOSS, Rules.respect_floor(int(wallet.respect))) if wallet != null else 0
			_toast(_tag("block"), took)
			_shout(d, _crew("block"))
			if sfx != null:
				sfx.horn(d.pos)
			_log("blocked the %s %.1f s at %.0f km/h: -%d respect" % [_what(), run["way_t"], pv * 3.6, took])
	else:
		run["way_t"] = 0.0
		if bool(run["was_in_way"]) and not bool(run["thanked"]) and not bool(run["blocked"]) and not bool(run["hit"]) \
				and rel.x < -Rules.PASSED and rel.y < 8.0:
			if not Rules.gave_way(int(run["lane0"]), _player_lane(), pv):
				run["was_in_way"] = false  # it went round a car driving on: no thanks
				return
			run["thanked"] = true
			thanked += 1
			if wallet != null:
				wallet.add_respect(Rules.THANKS_GAIN)
			_toast(_tag("thanks"), Rules.THANKS_GAIN)
			_shout(d, _crew("thanks"))
			_log("let the %s through: +%d respect" % [_what(), Rules.THANKS_GAIN])


## The road_life toast tag for `what` ("behind", "block", ...): the ambulance's or the fire engine's.
func _tag(what: String) -> String:
	return ("fire_" if bool(run.get("fire", false)) else "amb_") + what


## The crew's line tag for `what`: the paramedic's or the firefighter's.
func _crew(what: String) -> String:
	return ("fireman_" if bool(run.get("fire", false)) else "medic_") + what


## traffic.gd's bumped_police (the ambulance) or bumped_siren (the fire engine): the player's car
## hit a car with its lights on; ours only.
func _on_bumped(d, speed: float) -> void:
	if run.is_empty() or d != run["d"] or bool(run["hit"]) or bool(run["done"]):
		return
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false, 0.0]
	if bool(v[2]):
		return
	var p: Vector3 = v[0]
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	var rel := Rules.relative(Vector2(d.pos.x, d.pos.z), fwd, Vector2(p.x, p.z))
	var pv: float = float(v[3]) if v.size() > 3 else float(v[1]) / 3.6
	if not Rules.at_fault(speed, pv, rel, d.v):
		_log("bumped by the %s (%.1f m/s lost): not the player's fault" % [_what(), speed])
		return
	run["hit"] = true
	hits += 1
	var took: int = wallet.lose_respect(Rules.HIT_LOSS, Rules.respect_floor(int(wallet.respect))) if wallet != null else 0
	_toast(_tag("hit"), took)
	_shout(d, _crew("hit"))
	_announce(graph.e_name[d.edge] if d.edge >= 0 else "", "fire_hit" if bool(run["fire"]) else "ambulance_hit")
	_log("hit the %s at %.1f m/s lost: -%d respect" % [_what(), speed, took])


## The run ends: the siren and the mark off, the ambulance back to the pool (the fire engine: out
## of sight, back to its pool; in view, lights off, it drives on as traffic until the band lets it
## go), the next one's time.
func _end(why: String) -> void:
	var d = run.get("d")
	var what := _what()
	if sfx != null:
		sfx.ambulance_siren(Vector3.INF)
	if hud != null and hud.has_method("ambulance_edge"):
		hud.ambulance_edge(Vector2.INF)
	if d != null and d.active:
		if bool(run.get("fire", false)):
			if not d.route.is_empty():
				traffic.stop_racing(d)
			traffic.set_lights(d, false)
			if traffic.on_screen(d.pos, d.size.y):
				d.persistent = false
			else:
				traffic.remove(d)
		elif police != null:
			police.scene_leave(d)
	run = {}
	wait = _rng.randf_range(GAP.x, GAP.y)
	_log("%s run over (%s); next in %.0f s" % [what, why, wait])


# --- "Zielone!" ------------------------------------------------------------------------------

## The honk at a green (road_rules.gd honk_at_green).
func _green_step(dt: float, v: Array) -> void:
	_honk_wait -= dt
	if bool(v[2]) or car == null or float(v[1]) / 3.6 > Rules.STILL:
		_green_t = 0.0
		return
	var road := _player_road()
	if road.is_empty():
		_green_t = 0.0
		return
	var e: int = road["e"]
	var front: float = float(road["s"]) + 2.0
	var stops := graph.e_stops[e]
	var to_line := -1.0
	for k in range(0, stops.size(), 3):
		if stops[k] < front - 0.5:
			continue
		if graph.light(int(stops[k + 1]), int(stops[k + 2])) == LaneGraph.GREEN:
			to_line = stops[k] - front
		break
	if to_line < 0.0:
		_green_t = 0.0
		return
	_green_t += dt
	if _honk_wait > 0.0 or _green_t < Rules.GREEN_WAIT:
		return
	var behind = _car_behind(road["fwd"])
	if behind == null or not Rules.honk_at_green(_green_t, to_line, Vector2(behind.pos.x, behind.pos.z).distance_to(
			Vector2(car.global_position.x, car.global_position.z))):
		return
	_honk_wait = HONK_GAP
	if _rng.randf() > HONK_CHANCE:
		return
	honks += 1
	if sfx != null:
		sfx.horn(behind.pos)
	_shout(behind, "green")
	_log("honked at a green after %.1f s" % _green_t)


## The traffic car standing right behind the player's car in their lane, or null.
func _car_behind(fwd: Vector2):
	var me := Vector2(car.global_position.x, car.global_position.z)
	var best = null
	var best_d := Rules.BEHIND_NEAR + 0.001
	for o in traffic.drivers():
		if o.kind >= 4 or o.parked or o.v > 1.0 or o.tag == "fire":
			continue
		var rel := Vector2(o.pos.x, o.pos.z) - me
		var along := rel.dot(fwd)
		if along > -2.0 or absf(rel.cross(fwd)) > Rules.WAY_SIDE:
			continue
		if -along < best_d:
			best_d = -along
			best = o
	return best


# --- the Elka -------------------------------------------------------------------------------

## The Elka ahead of the player's car in their way (ELKA_NEAR m, ELKA_SIDE m to the side, going
## their way), or null.
func _elka_ahead(fwd: Vector2):
	var me := Vector2(car.global_position.x, car.global_position.z)
	var best = null
	var best_d := ELKA_NEAR
	for o in traffic.drivers():
		if o.dress != Traffic.DRESS_ELKA:
			continue
		var rel := Vector2(o.pos.x, o.pos.z) - me
		var along := rel.dot(fwd)
		if along < 2.0 or along > best_d or absf(rel.cross(fwd)) > ELKA_SIDE:
			continue
		if Vector2(-sin(o.yaw), -cos(o.yaw)).dot(fwd) < Rules.WAY_COS:
			continue
		best_d = along
		best = o
	return best


## Tailing an Elka: after ELKA_TAIL s behind it, its instructor or learner speaks (in turns), at
## most every ELKA_GAP s.
func _elka_step(dt: float, v: Array) -> void:
	_elka_wait -= dt
	if bool(v[2]) or car == null:
		_elka_t = 0.0
		return
	var b := car.global_transform.basis.z
	var elka = _elka_ahead(-Vector2(b.x, b.z).normalized())
	if elka == null:
		_elka_t = 0.0
		return
	_elka_t += dt
	if _elka_t < ELKA_TAIL or _elka_wait > 0.0:
		return
	_elka_wait = ELKA_GAP
	elka_lines += 1
	_elka_turn += 1
	_shout(elka, "elka_learner" if _elka_turn % 2 == 0 else "elka_instructor", ELKA_BUBBLE)
	_log("tailing an Elka: a line")


## The player's horn (main.gd `_honk`) at `at`: an Elka near ahead gets the instructor's word, a
## wedding convoy near makes the player a guest (once a convoy) and honks back.
func honk(at: Vector3) -> void:
	var me := Vector2(at.x, at.z)
	if elka_on and _clock - _elka_honk_at > 6.0:
		for o in traffic.drivers():
			if o.dress == Traffic.DRESS_ELKA and Vector2(o.pos.x, o.pos.z).distance_to(me) < ELKA_HONK:
				_elka_honk_at = _clock
				elka_lines += 1
				_shout(o, "elka_honked", ELKA_BUBBLE)
				_log("honked at an Elka")
				break
	if convoy.is_empty() or bool(convoy["guest"]):
		return
	for d in convoy["cars"]:
		if d.active and Vector2(d.pos.x, d.pos.z).distance_to(me) < WED_GUEST_NEAR:
			convoy["guest"] = true
			guests += 1
			if wallet != null:
				wallet.add_respect(WED_GUEST_GAIN)
			_toast("wed_guest", WED_GUEST_GAIN)
			_shout(d, "wedding_guest", WED_BUBBLE)
			convoy["honk_t"] = 0.0
			_log("the player honked with the wedding: a guest, +%d respect" % WED_GUEST_GAIN)
			return


# --- the wedding convoy ----------------------------------------------------------------------

## A start `ahead` metres along the roads out of (e, s) (the straightest way on at each junction,
## main and secondary roads first): {e, s}, or {} when the roads run out.
func _ahead(e: int, s: float, ahead: float) -> Dictionary:
	var left := ahead
	for hop in 8:
		var room := graph.e_s1[e] - s - 4.0
		if room >= left:
			return {"e": e, "s": s + left}
		left -= maxf(room, 0.0)
		var best := -1
		var best_k := -INF
		var out: Vector2 = graph.direction(e, graph.e_s1[e])
		for f: int in graph.node_out[graph.e_b[e]]:
			if graph.e_tn[f] >= 0 or graph.e_dk[f] >= 0 or graph.e_reverse[e] == f:
				continue
			var k := graph.direction(f, graph.e_s0[f]).dot(out) - 0.4 * graph.e_class[f]
			if k > best_k:
				best_k = k
				best = f
		if best < 0:
			return {}
		e = best
		s = graph.e_s0[e]
	return {}


## Sends a wedding convoy onto the player's road ahead of them, the way they drive (`near`: a
## test's, 50-70 m ahead and maybe in view). True if it set off.
func send_convoy(near: bool) -> bool:
	if not convoy.is_empty():
		return false
	var road := _player_road()
	if road.is_empty():
		return false
	var start := _ahead(int(road["e"]), float(road["s"]), _rng.randf_range(50.0, 70.0) if near else _rng.randf_range(WED_AHEAD.x, WED_AHEAD.y))
	if start.is_empty():
		return false
	var e: int = start["e"]
	var lane: int = graph.e_lanes[e] - 1
	var s_front: float = start["s"]
	var s_back := s_front - float(WED_CARS - 1) * WED_SPACING
	if s_back < graph.e_s0[e] + 4.0:
		s_front += graph.e_s0[e] + 4.0 - s_back
		s_back = graph.e_s0[e] + 4.0
		if s_front > graph.e_s1[e] - 4.0:
			return false
	if not traffic.lane_free(e, lane, s_back - 6.0, s_front + 6.0, 2.0):
		return false
	for i in WED_CARS:
		var s := s_front - float(i) * WED_SPACING
		var q := graph.point_at(e, s, graph.lane_offset(e, lane))
		if not near and traffic.on_screen(Vector3(q.x, graph.height(e, s), q.y), 1.6):
			return false
	var goal := _node_ahead(e, s_front, road["fwd"], WED_RUN, WED_ROUTE, "the church")
	if goal.is_empty():
		return false
	var cars: Array = []
	for i in WED_CARS:
		var shape := 1 if i == 0 else _rng.randi() % 4
		var paints: Array = Models.TRAFFIC[0][shape]["paint"]
		var paint := Color(WED_LEADER_PAINTS[_rng.randi() % 2]) if i == 0 else Color(paints[_rng.randi() % paints.size()])
		var d = traffic.add_car(e, lane, s_front - float(i) * WED_SPACING, shape, paint, Traffic.DRESS_WEDDING)
		if d == null:
			for o in cars:
				traffic.remove(o)
			return false
		d.speed_factor = WED_PACE
		d.accel_factor = 0.8
		cars.append(d)
	for d in cars:
		traffic.race_to(d, int(goal["node"]), goal["dist"])
		d.v = graph.e_speed[e] * 0.5
	convoys += 1
	convoy = {"cars": cars, "age": 0.0, "honk_t": 0.0, "shout_t": 0.0, "shouts": 0, "guest": false, "goal": goal["name"]}
	_log("wedding convoy %d on edge %d (%s) to %s, %.0f m by road" % [convoys, e, graph.e_name[e], goal["name"],
			traffic.remaining(cars[0])])
	_announce(graph.e_name[e], "wedding")
	return true


## The convoy's tick: its horns and shouts near the player, its end at the church, after WED_LIFE s
## or out of sight far away (the cars drive on as town traffic, still dressed, until the band lets
## them go).
func _convoy_step(dt: float, v: Array) -> void:
	convoy["age"] = float(convoy["age"]) + dt
	var p: Vector3 = v[0]
	var me := Vector2(p.x, p.z)
	var near := INF
	var near_car = null
	var seen := false
	var arrived := false
	for d in convoy["cars"]:
		if not d.active:
			continue
		var dd := Vector2(d.pos.x, d.pos.z).distance_to(me)
		if dd < near:
			near = dd
			near_car = d
		if traffic.on_screen(d.pos, d.size.y):
			seen = true
		if d.arrived or traffic.remaining(d) < REACHED:
			arrived = true
	if near_car == null or arrived or float(convoy["age"]) > WED_LIFE or (near > FAR and not seen):
		_end_convoy("at the church" if arrived else "gone" if near_car == null else "over")
		return
	if near > WED_HEAR or not seen or bool(v[2]):
		return
	convoy["honk_t"] = float(convoy["honk_t"]) - dt
	if float(convoy["honk_t"]) <= 0.0:
		convoy["honk_t"] = _rng.randf_range(WED_HONK.x, WED_HONK.y)
		var live: Array = (convoy["cars"] as Array).filter(func(o) -> bool: return o.active)
		var who = live[_rng.randi() % live.size()]
		wed_honks += 1
		if sfx != null:
			sfx.play_at("horn_double" if _rng.randf() < 0.5 else "horn", who.pos, _rng.randf_range(-4.0, -1.0))
	convoy["shout_t"] = float(convoy["shout_t"]) - dt
	if int(convoy["shouts"]) < WED_SHOUTS and float(convoy["shout_t"]) <= 0.0:
		convoy["shout_t"] = WED_SHOUT_GAP
		convoy["shouts"] = int(convoy["shouts"]) + 1
		wed_shouts += 1
		_shout(near_car, "wedding", WED_BUBBLE)


func _end_convoy(why: String) -> void:
	for d in convoy["cars"]:
		if not d.active:
			continue
		if not d.route.is_empty():
			traffic.stop_racing(d)
		d.persistent = false
	_log("wedding convoy over (%s, %.0f s)" % [why, convoy["age"]])
	convoy = {}
	wed_wait = _rng.randf_range(WED_GAP.x, WED_GAP.y)


# --- words -----------------------------------------------------------------------------------

## A toast from dialogue.json `road_life` (`tag`), {n} the respect.
func _toast(tag: String, n: int) -> void:
	if hud == null or dialogue == null:
		return
	if not tag.ends_with("_behind") and n <= 0:
		return  # nothing taken (at the floor): no toast saying it was
	var l: Array = dialogue.line(LINES, tag, true)
	if l.is_empty():
		return
	hud.toast(String(l[0]).replace("{n}", str(n)), String(l[1]).replace("{n}", str(n)), Messages.INFO)


## A line over driver d (the paramedic, the firefighter, the driver behind, an Elka, a wedding
## car), in `colour` (none: the paramedic's or the firefighter's).
func _shout(d, tag: String, colour := Color(0, 0, 0, 0)) -> void:
	if dialogue == null:
		return
	var pos: Vector3 = d.pos
	var anchor := func() -> Vector3: return d.pos if d.active else pos
	var high := 3.0 if not tag.begins_with("fireman") else 3.8
	if colour.a == 0.0:
		colour = FIREMAN if tag.begins_with("fireman") else MEDIC
	dialogue.say_ambient(anchor, "", LINES, tag, high, colour, 2.9, true)


## KEBAB FM's host (`radio_host` lines tagged `tag`, {street} the road's name).
func _announce(street: String, tag: String) -> void:
	if radio == null or dialogue == null or radio.station < 0:
		return
	var l: Array = dialogue.line(RADIO_GROUP, tag, true)
	if l.is_empty() or dialogue.notes(l).get("only", "") != tag:
		return
	var pl := street if street != "" else "Ulica bez nazwy"
	var en := street if street != "" else "A street with no name"
	radio.announce(String(l[0]).replace("{street}", pl), String(l[1]).replace("{street}", en))


func _log(text: String) -> void:
	if log_on:
		print("road: %s (%.1f s)" % [text, _clock])
