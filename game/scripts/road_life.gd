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
## **"Zielone!"** The player's car stands at a light that went green GREEN_WAIT s ago with a car
## behind it: that car honks (sfx.gd `horn`) and its driver shouts (dialogue.json `road_life`
## "green"); at most once every HONK_GAP s.
##
## Nothing draws (the ambulance is in the police MultiMesh, the mark in the HUD's police overlay);
## the work is a tick at TICK (4 Hz) and one shortest-path table per hospital, made the first
## time that hospital is wanted and kept.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Rules := preload("res://scripts/road_rules.gd")
const Messages := preload("res://scripts/messages.gd")

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
var log_on := false
## The ambulance on or off (--ambulance=0), the honk on or off.
var ambulance_on := true
var honk_on := true

## Seconds to the next ambulance; the run now ({} = none).
var wait := 0.0
var run := {}
## This session: ambulances sent, let through, blocked, hit at fault, honks at a green.
var sent := 0
var thanked := 0
var blocked := 0
var hits := 0
var honks := 0
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


## A road life installed from the ctx, quiet while `hush` says so, added under `parent` and set up;
## or null (freed, so a --no-police run leaks no node at exit) when there is no traffic or police.
static func make(ctx, parent: Node, hush: Callable) -> Node:
	var life: Node = (load("res://scripts/road_life.gd") as GDScript).new()
	if not life.install(ctx):
		life.free()
		return null
	life.name = "RoadLife"
	life.hushed = hush
	parent.add_child(life)
	life.setup()
	return life


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
	if ctx.bubbles != null:
		project = ctx.bubbles.project
	if ctx.missions != null:
		hospitals = ctx.missions.places.hospitals
	# Its test flags (dev_flags.gd): off in a test run unless asked for, as the crash scenes.
	var f = ctx.flags
	if f != null:
		log_on = f.road_log
		_test_now = f.ambulance_flag == "now"
		ambulance_on = f.ambulance_flag != "0" and (f._crash_auto or f.ambulance_flag != "")
		honk_on = f._crash_auto or f.ambulance_flag != ""
	return true


func setup(seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	wait = _rng.randf_range(FIRST.x, FIRST.y)
	_honk_wait = 30.0
	if traffic.has_signal("bumped_police"):
		traffic.bumped_police.connect(_on_bumped)
	if _test_now:
		get_tree().create_timer(2.0).timeout.connect(func() -> void: send(true))
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
		_log("end (%d sent, %d let through, %d blocked, %d hit, %d honks)" % [sent, thanked, blocked, hits, honks])


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


## Sends an ambulance up behind the player (`near`: a test's, 40-60 m back and maybe in view).
## True if one set off.
func send(near: bool) -> bool:
	if not run.is_empty() or police == null:
		return false
	var road := _player_road()
	if road.is_empty() or hospitals.is_empty():
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
	if not near and traffic.on_screen(Vector3(at.x, graph.height(e, s), at.y), 2.6):
		return false
	if not traffic.lane_free(e, lane, s - 6.0, s + 6.0, 2.0):
		return false
	var goal := _hospital_for(e, s, road["fwd"])
	if goal.is_empty():
		return false
	var d = police.ambulance_car(e, lane, s)
	if d == null:
		return false
	_arm(d)
	traffic.race_to(d, int(goal["node"]), goal["dist"])
	d.v = 12.0
	sent += 1
	run = {"d": d, "age": 0.0, "way_t": 0.0, "warned": false, "was_in_way": false, "thanked": false,
			"blocked": false, "hit": false, "done": false, "linger": 0.0, "goal": goal["name"], "lane0": -1}
	_log("ambulance %d from %d,%d (edge %d, %.0f m back) to %s, %.0f m by road" % [sent, roundi(at.x), roundi(at.y),
			e, back, goal["name"], traffic.remaining(d)])
	_announce(graph.e_name[e], "ambulance")
	return true


## The ambulance's racer stats (traffic.gd's racer mode, as a crazy driver's, but careful: no
## blocks, no mistakes).
func _arm(d) -> void:
	d.race_top = TOP
	d.race_accel = ACCEL
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
			_log("ambulance at %s (%.0f s)" % [run["goal"], run["age"]] if there else "ambulance gave up after %.0f s" % run["age"])
		elif not bool(v[2]):
			_rules(d, amb, me, v)
	else:
		run["linger"] = float(run["linger"]) + dt
	if (bool(run["done"]) or dist > FAR) and (not seen or float(run["linger"]) > LINGER):
		_end("done" if bool(run["done"]) else "far")
		return
	if sfx != null:
		sfx.ambulance_siren(Vector3.INF if bool(run["done"]) else d.pos + Vector3.UP * 1.6)
	if hud != null and hud.has_method("ambulance_edge"):
		var mark := not bool(run["done"]) and not seen and dist < MARK_NEAR and project.is_valid()
		hud.ambulance_edge(project.call(d.pos + Vector3.UP * 1.2) if mark else Vector2.INF)


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
			_toast("amb_behind", 0)
		var lanes: int = graph.e_lanes[d.edge] if not d.in_conn else 1
		if not bool(run["blocked"]) and not bool(run["thanked"]) and Rules.blocking(float(run["way_t"]), pv, lanes):
			run["blocked"] = true
			blocked += 1
			var took: int = wallet.lose_respect(Rules.BLOCK_LOSS, Rules.respect_floor(int(wallet.respect))) if wallet != null else 0
			_toast("amb_block", took)
			_shout(d, "medic_block")
			if sfx != null:
				sfx.horn(d.pos)
			_log("blocked the ambulance %.1f s at %.0f km/h: -%d respect" % [run["way_t"], pv * 3.6, took])
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
			_toast("amb_thanks", Rules.THANKS_GAIN)
			_shout(d, "medic_thanks")
			_log("let the ambulance through: +%d respect" % Rules.THANKS_GAIN)


## traffic.gd's bumped_police: the player's car hit a police-pool car; ours only.
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
		_log("bumped by the ambulance (%.1f m/s lost): not the player's fault" % speed)
		return
	run["hit"] = true
	hits += 1
	var took: int = wallet.lose_respect(Rules.HIT_LOSS, Rules.respect_floor(int(wallet.respect))) if wallet != null else 0
	_toast("amb_hit", took)
	_shout(d, "medic_hit")
	_announce(graph.e_name[d.edge] if d.edge >= 0 else "", "ambulance_hit")
	_log("hit the ambulance at %.1f m/s lost: -%d respect" % [speed, took])


## The run ends: the siren and the mark off, the ambulance back to the pool, the next one's time.
func _end(why: String) -> void:
	var d = run.get("d")
	if sfx != null:
		sfx.ambulance_siren(Vector3.INF)
	if hud != null and hud.has_method("ambulance_edge"):
		hud.ambulance_edge(Vector2.INF)
	if d != null and d.active and police != null:
		police.scene_leave(d)
	run = {}
	wait = _rng.randf_range(GAP.x, GAP.y)
	_log("ambulance run over (%s); next in %.0f s" % [why, wait])


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
		if o.kind >= 4 or o.parked or o.v > 1.0:
			continue
		var rel := Vector2(o.pos.x, o.pos.z) - me
		var along := rel.dot(fwd)
		if along > -2.0 or absf(rel.cross(fwd)) > Rules.WAY_SIDE:
			continue
		if -along < best_d:
			best_d = -along
			best = o
	return best


# --- words -----------------------------------------------------------------------------------

## A toast from dialogue.json `road_life` (`tag`), {n} the respect.
func _toast(tag: String, n: int) -> void:
	if hud == null or dialogue == null:
		return
	if tag != "amb_behind" and n <= 0:
		return  # nothing taken (at the floor): no toast saying it was
	var l: Array = dialogue.line(LINES, tag, true)
	if l.is_empty():
		return
	hud.toast(String(l[0]).replace("{n}", str(n)), String(l[1]).replace("{n}", str(n)), Messages.INFO)


## A line over driver d (the paramedic, the driver behind).
func _shout(d, tag: String) -> void:
	if dialogue == null:
		return
	var pos: Vector3 = d.pos
	var anchor := func() -> Vector3: return d.pos if d.active else pos
	dialogue.say_ambient(anchor, "", LINES, tag, 3.0, MEDIC, 2.9, true)


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
