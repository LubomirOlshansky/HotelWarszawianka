extends RefCounted
## The race bench (docs/design/race-ai.md, "How we test it"): one rival's race, start to finish, on
## the committed map's lane graph (map/centrum.json) with the real traffic (traffic.gd) and the
## game's own race code (the race session, race_session.gd, that rivals.gd races on: the course,
## the rival's shortcuts, distances, plans, effort and lights; and rivals.gd's `first_start_step`,
## `finish_node`, `lane_behind`), but without the city, the car, the HUD or a
## renderer, so a race takes a second or two and the same race runs the same way every time.
##
## A race is a `spec` (see `race`): the rival, the tuning (a ladder race or the guided first
## race), the start and the finish, a situation and a test player.
##   Situations: "clear" (no traffic), "low" and "heavy" (Settings -> Traffic: Low, Busy), "blocked" (clear
##   roads and a wall of parked cars across a street of the rival's own route), "crash" (clear
##   roads, a wreck in the rival's lanes and a knock from the side).
##   Test players (the player is a ghost driver, as the game's --autopilot): "none", "stopped"
##   (never leaves the line), "slow" and "average" (--ghost-pace 0.5 and 1.8), "fast"
##   (--ghost-pace=racer), "follower" (sits FOLLOW_GAP m behind the rival whatever the rival does).
## What comes back is what happened (`Probe`): the time, the route, how long the rival crawled on
## a free straight road, sat behind a slower car, stood still, drove through another car, was
## passed by the town's traffic, and what its car did (top speed, pull, sideways grip, brakes).
## `judge` turns a set of races into the pass marks the design names: finishes, independence, no
## crawl, passes traffic, no ghosting, re-routes, recovers, honest car, route sense, skill ladder,
## same race twice. check_race_bench.gd runs the matrix and holds the marks against
## data/race_bench.json; tools/race_bench.sh is the way to run it.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Ladder := preload("res://scripts/ladder.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const RaceSignals := preload("res://scripts/race_signals.gd")
const RaceSession := preload("res://scripts/race_session.gd")
const TrzyMosty := preload("res://scripts/trzy_mosty.gd")
const Settings := preload("res://scripts/settings.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")

## The game's frame and the race's ranking tick (rivals.gd `_track`: 5 times a second).
const DT := 1.0 / 60.0
const TICK := 0.2
## Before the start both cars stand for the challenge line (2.6 s) and the countdown (3 s)
## while the traffic flows (rivals.gd `_frame`).
const LEAD_IN := 5.6
## A race not over by then never finishes (the longest honest one here takes about three minutes).
const TIME_LIMIT := 420.0
## The player's car: its top speed (car.gd `max_speed`, the starter car), its pull (`accel`) and
## the most it pulls sideways (car.gd PROFILES, the default Cruise: turn_pull + turn_floor x speed,
## 19 m/s² at its top; the Grounded profile holds 12), measured over GRIP_WINDOW m of the way, and
## its brakes (`brake_decel`): a car that stops harder was stopped by something else.
const PLAYER_TOP := 30.0
const PLAYER_ACCEL := 15.0
const PLAYER_GRIP := 19.0
const GRIP_WINDOW := 8.0
const PLAYER_BRAKE := 30.0
## The grid: a challenged rival stands START_AHEAD m in front of the car (rivals.gd `put_ahead`);
## in the guided first race she has rolled up FIRST_BEHIND m behind it (`_first_call_tick`).
const START_AHEAD := 14.0
const FIRST_BEHIND := 12.0
## The game's view (main.gd: yaw 45, FollowCamera's pitch and size): what "seen" means.
const VIEW_YAW := 45.0
const VIEW_BACK := 150.0
## The test players (main.gd --ghost-pace: 0.5 a slow driver, 1.8 an average one, "racer").
const SLOW_PACE := 0.5
const AVERAGE_PACE := 1.8
const FOLLOW_GAP := 15.0
const FOLLOW_ROLL := 8.0

## Situations: the Traffic setting's level (-1: no traffic at all), a wall, a wreck and a knock.
## `low` is the whole game's own level (Settings → Traffic: Low), `heavy` its Busy.
const SITUATIONS := {
	"clear": {"traffic": -1},
	"low": {"traffic": 1},
	"heavy": {"traffic": 3},
	"blocked": {"traffic": -1, "wall": true},
	"crash": {"traffic": -1, "wreck": true},
	# Step 5b: clear roads and one car parked on the hop course's one-way block of Żelazna
	# (HOP_BLOCK), which a wrong-way hop runs down: the street is not empty.
	"parked": {"traffic": -1, "hop_car": true},
}
const PLAYERS := ["none", "stopped", "slow", "average", "fast", "follower"]
## The prototype race (F 2026-11-09: Powiśle to Plac Trzech Krzyży) from two starts: where F
## teleported to (Tamka: one obvious way), and north Powiśle by Leszczyńska, where three useful
## routes lie within 15 s of each other (ROUTES: a point each is forced through).
const FINISH := "Plac Trzech Krzyży"
const STARTS := {
	"tamka": Vector2(200.0, -400.0),
	"leszczynska": Vector2(300.0, -790.0),
	"marszalkowska": Vector2(-1161.8, -456.9),
	"spawn": Vector2(-911.6, 278.6),
	"poniatowski": Vector2(1000.0, -153.0),
	"yard": Vector2(-2314.0, -60.0),
	"hop": Vector2(-2611.7, -895.8),
}
## Racer AI step 5: a start in Wola from which the way to Rondo ONZ is 670 m shorter through a
## yard (the race link from the junction at (-2461, -21), 3.5 m wide: Halina dares it, Słoik knows
## none; by road 1726 m).
const YARD_START := "yard"
const YARD_FINISH := "Rondo ONZ"
## Racer AI step 5b: a start on Żelazna in Wola from which the way to Rondo ONZ is quicker the
## wrong way down one block of one-way Żelazna (a wrong-way hop of 112 m: Seba and Mike dare it,
## nobody else does).
const HOP_START := "hop"
const HOP_FINISH := "Rondo ONZ"
## The middle of that block (the "parked" situation's car stands on the hop nearest to it).
const HOP_BLOCK := Vector2(-2614.0, -831.0)
## A finish whose circle another road runs through (race_planner.gd `ends`): the Palace, whose
## junction is on one carriageway of Emilii Plater while the other passes 14 m from it, 600 m
## short of it by road. The guided first race went there from Marszałkowska in the whole game
## (first10-run, 2026-11-12), and the plan to the junction alone gave the race 101 s where the
## way through the circle took 66 s.
const PALACE := "Pałac Kultury i Nauki"
const PALACE_START := "marszalkowska"
## ... and from the map's spawn, the course of the whole game's `--race=0` (step 4b: the courses
## that had only been measured with scratch specs).
const SPAWN_START := "spawn"
## The final's last stretch (a spec's tuning `final`: Seba with the final's racer, ladder.gd
## FINAL_RACER, to Trzy mosty's finish by the stadium): from the middle of Most Poniatowskiego,
## 557 m, flat out, with the jog at the bridge's end.
const FINAL_START := "poniatowski"
const FINAL_RIVAL := "Seba z Pragi"
const ROUTES := {
	"dobra": [Vector2(292.0, -471.0), Vector2(477.0, -210.0)],
	"topiel": [Vector2(114.0, -430.0)],
	"solec": [Vector2(520.0, -280.0), Vector2(669.0, 394.0)],
}

## The pass marks' limits (docs/design/race-ai.md):
## the rival's time may move this share whatever the player does: a race on clear roads by
## itself (the same race on any machine), a race among the town's cars together with the other
## draws of the town's cars it was run in (a pair's seconds with the player over all its draws
## against its seconds alone over the same draws: one race in traffic is 5 to 12 % from the
## next draw's with nothing changed, and the worst of thirty such races passed or failed with the
## draw, step 4a), and no single race in traffic more than INDEPENDENCE_ONE (a rival that does
## something else altogether because of the player: the turn back behind a car that only waits);
const INDEPENDENCE := 0.15
const INDEPENDENCE_ONE := 0.4
## A pair is held to INDEPENDENCE over its draws only with INDEPENDENCE_DRAWS of them or more: one
## race's time moves 11 to 12 % with the draw of the town's cars by itself (tools/race_traffic.sh,
## step 4b's fit), and a rival out of the player's sight pays the mean of them. With fewer (the
## quick matrix has one draw) each race is held to INDEPENDENCE_ONE only.
const INDEPENDENCE_DRAWS := 3
## a count over races in traffic is also given draw by draw for the draws with this many races
## or more (the whole set run again with other dice);
const DRAW_RACES := 10
## boxed in: a race the rival never finishes because the player's own stopped car stood in front
## of it with no lane to pass in (a one-lane one-way street) for more than this share of the race
## is not Independence's to judge: that is a block, not the rival's pace following the player's
## (Finishes counts the race, and step 4b's driver has to get round);
const BOXED_SHARE := 0.5
## crawling: under CRAWL_SHARE of the road's racing speed for more than CRAWL_MAX s in a row with
## nobody within FREE_AHEAD m in front (nor a car crossing its way that near) and the next STRAIGHT_AHEAD m of its own way bending under
## STRAIGHT_BEND rad. Pulling away after the game stopped it dead is not a crawl (Honest car
## counts every dead stop): from the stop until its speed is back at CRAWL_SHARE of the road's,
## DEAD_AWAY s at most, so a racer that stays slow after one is still caught;
const CRAWL_SHARE := 0.5
const CRAWL_MAX := 3.0
const DEAD_AWAY := 4.0
const FREE_AHEAD := 30.0
const FREE_NEAR := 6.0
const FREE_NEAR_SIDE := 3.2
const STRAIGHT_AHEAD := 40.0
const STRAIGHT_BEND := 0.3
## behind the same slower car (under BEHIND_SLOW of the road's racing speed, within BEHIND_GAP m)
## for more than BEHIND_MAX s while a lane beside it is free: another lane of its road with no
## slow car from PASS_BACK m behind to PASS_AHEAD m ahead, or, for a rival in the lane by the
## centre line, the oncoming lane with no car at all for ONCOMING_AHEAD m;
const BEHIND_SLOW := 0.7
const BEHIND_GAP := 12.0
const BEHIND_MAX := 4.0
const PASS_BACK := 6.0
const PASS_AHEAD := 30.0
const ONCOMING_AHEAD := 80.0
## inside another car's box (traffic.gd's own test) for GHOST_MIN s or more: driven through it
## (less is a touch: the bump of a collision);
const GHOST_MIN := 0.25
## a blocked street: the time may be REROUTE_SLACK of the clear time stretched to the way of a
## driver who finds out at the wall (plan_wall's turn_m), and REROUTE_GRACE s for turning round;
const REROUTE_SLACK := 1.2
const REROUTE_GRACE := 8.0
## a wreck and a knock may cost RECOVER_LOSS s;
const RECOVER_LOSS := 12.0
## the free choice may be ROUTE_SENSE of the best forced route's time;
const ROUTE_SENSE := 1.05
## flat out on clear roads each rival up the ladder is as fast as the one below it (to
## LADDER_ORDER) and the top one at least LADDER_SPREAD faster than the first.
const LADDER_ORDER := 1.01
const LADDER_SPREAD := 0.1
## Step 6a, the ladder's curve of times: over the courses every rung has driven alone on clear
## roads (the mean of each rung's times, as a ratio), each rung is CURVE_LEAST to CURVE_MOST
## quicker than the one below it: no rung is a copy of the last and none is a wall.
const CURVE_LEAST := 0.03
const CURVE_MOST := 0.12

## A frame's flags (Probe.flag): nobody in the rival's way for FREE_AHEAD m; held at the line or
## knocked; on a junction's curve; stopped dead by the game in this frame; pulling away after
## that (DEAD_AWAY above).
const FREE := 1
const HELD := 2
const CONN := 4
const DEAD := 8
const AWAY := 16
## A traffic step that takes longer than this (microseconds) counts as a slow one (`steps_slow`:
## how often a race hitches, beside `step_most_usec`, how badly).
const SLOW_STEP := 1000


## The map traffic.gd asks for heights: flat ground, no decks, tunnels or roofs (the pattern of
## check_crazy_drivers.gd).
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


## What one racer did in one race, sampled every frame: the bench's eyes. It reads only what a
## spectator could see (where the car is, how fast, which way it points, the cars round it), so
## it measures the next driver the same way as this one; the two `slips` counts alone look at
## traffic.gd's own "squeeze" (the game moving a stuck racer through a car).
class Probe:
	var graph: LaneGraph
	var d
	var v := PackedFloat32Array()
	var yaw := PackedFloat32Array()
	var top := PackedFloat32Array()
	var cum := PackedFloat32Array()
	var flag := PackedByteArray()
	var edge_at := PackedInt32Array()
	var px := PackedFloat32Array()
	var pz := PackedFloat32Array()
	var driven := 0.0
	var top_v := 0.0
	var stopped := 0.0
	var jumps := 0
	var jumps_seen := 0
	var accel_max := 0.0
	var brake_max := 0.0
	var hard_stops := 0
	var hard_log: Array = []
	## Set by the bench in the frame it knocks the car (the "crash" situation): that stop is its own.
	var knocked := false
	var seen := 0
	var frames := 0
	var overlap_s := 0.0
	var overlaps := 0
	## Of them, the cars that came the other way (a pass over the centre line that met one).
	var head_ons := 0
	## Step 5b, while it drives a wrong-way hop: the town's cars on the street it hops or on a
	## curve into it (each once: the street is held for it, so none), and the cars it went through.
	var hop_met := 0
	var hop_overlaps := 0
	var _hop_seen := {}
	var touches := 0
	var overlap_log: Array = []
	var slips := 0
	var slips_seen := 0
	var passes := 0
	var overtaken := 0
	var behind_longest := 0.0
	var behind_room_longest := 0.0
	## Seconds stopped behind the player's own stopped car with no lane to pass in (BOXED_SHARE).
	var boxed := 0.0
	## Out of the town's cars (traffic.gd AWAY_*): the seconds it covered less ground than its
	## speed, and the seconds that cost it (the expected traffic delay it paid).
	var away := 0.0
	var away_paid := 0.0
	## Turning back (traffic.gd BACK_*): the states it went through, in order (each once per run
	## of frames): 2 and 5 are a U-turn in the street, 3 and 4 backing out to the junction behind.
	var backs := PackedInt32Array()
	var _back := 0
	## The edges driven, in order (each once per visit), and the race time (s) it came onto each
	## (an edge's seconds run to the next one's: the junction's curve at its end counts with it).
	var edges := PackedInt32Array()
	var edge_t := PackedFloat32Array()
	var cars := 0
	## The traffic's step: its microseconds in all, the most in one frame (a hitch: a racing line
	## built, a plan searched) with the race time of that frame, and the frames over SLOW_STEP.
	var usec := 0
	var usec_most := 0
	var usec_most_t := 0.0
	var slow_steps := 0
	var _pv := 0.0
	var _ppos := Vector3.ZERO
	var _pseen := false
	var _started := false
	var _free := true
	var _over := {}
	var _squeezing := false
	## When the game last stopped it dead (race time), while it is still pulling away; else -1.
	var _dead_t := -1.0
	var _ahead := {}
	var _behind := {}
	var _leader = null
	var _leader_t := 0.0
	var _leader_room_t := 0.0
	var _last_edge := -1

	## One frame at race time `t`: `held` while the rival waits at the line, `ghost` the test
	## player's driver (null: none; `player_live`: still in the race).
	func sample(t: float, traffic: Node3D, ghost, held: bool, player_live: bool) -> void:
		frames += 1
		var dead := false
		var p: Vector3 = d.pos
		# Its speed over the ground: out of the town's cars a racer covers less of it than its
		# speedometer says (traffic.gd `away_pace`), and a spectator sees the ground.
		var pace: float = d.away_pace if "away_pace" in d else 1.0
		var gv: float = d.v * pace
		if pace < 0.999:
			away += DT
			if d.v > 2.0:
				away_paid += (1.0 - pace) * DT
		if _started:
			var moved := Vector2(p.x - _ppos.x, p.z - _ppos.z).length()
			if moved > maxf(_pv, gv) * DT * 3.0 + 1.5:
				# Put somewhere else by the game (a rescue); in view it is a fault.
				jumps += 1
				if d.visible or _pseen:
					jumps_seen += 1
				if OS.is_stdout_verbose():
					print("    put elsewhere at %.1f s: %.1f m in a frame, from (%.1f, %.1f) to (%.1f, %.1f) on %s: v %.1f edge %d s %.1f conn %s cu %.1f/%.1f off %.1f back %d" % [
							t, moved, _ppos.x, _ppos.z, p.x, p.z, _street(d.edge), d.v, d.edge, d.s, d.in_conn, d.cu, d.conn_len, d.off, d.get("back") if "back" in d else 0])
			var a: float = (gv - _pv) / DT
			accel_max = maxf(accel_max, a)
			if not knocked:
				brake_max = maxf(brake_max, -a)
				if a < -PLAYER_BRAKE - 2.0:
					# Stopped by the game, not by its brakes (traffic.gd: no room left to the car ahead).
					dead = true
					hard_stops += 1
					if hard_log.size() < 6:
						hard_log.append("%.1f s from %.0f km/h on %s" % [t, _pv * 3.6, _street(d.edge)])
					if OS.is_stdout_verbose():
						print("    stopped dead at %.1f s: from %.1f to %.1f m/s on %s: edge %d s %.1f conn %s cu %.1f/%.1f next %d back %d" % [
								t, _pv, gv, _street(d.edge), d.edge, d.s, d.in_conn, d.cu, d.conn_len, d.next_edge, d.get("back") if "back" in d else 0])
		knocked = false
		_started = true
		_pv = gv
		_ppos = p
		_pseen = d.visible
		driven += gv * DT
		top_v = maxf(top_v, gv)
		if gv < 1.0 and not held:
			stopped += DT
		if d.visible:
			seen += 1
		if not d.in_conn and d.edge != _last_edge:
			_last_edge = d.edge
			edges.append(d.edge)
			edge_t.append(t)
		if "back" in d and d.back != _back:
			_back = d.back
			if _back != 0:
				backs.append(_back)
		if "squeeze" in d and "pass_t" in d:
			var squeezing: bool = d.squeeze > 0.0 and d.pass_t <= 0.0
			if squeezing and not _squeezing:
				slips += 1
				if d.visible:
					slips_seen += 1
			_squeezing = squeezing
		if frames % 2 == 0:
			_scan(t, traffic, ghost, player_live)
		cars += traffic.drivers().size() - (1 if ghost == null else 2)
		usec += traffic.last_usec
		if traffic.last_usec > usec_most:
			usec_most = traffic.last_usec
			usec_most_t = t
		if traffic.last_usec > SLOW_STEP:
			slow_steps += 1
		var road_top: float = minf(PLAYER_TOP, Traffic.RACE_CLASS_TOP[graph.e_class[d.edge]])
		if dead:
			_dead_t = t
		elif _dead_t >= 0.0 and (t - _dead_t > DEAD_AWAY or gv >= CRAWL_SHARE * road_top):
			_dead_t = -1.0
		v.append(gv)
		yaw.append(d.yaw)
		top.append(road_top)
		cum.append(driven)
		edge_at.append(d.edge)
		px.append(p.x)
		pz.append(p.z)
		# (Out of the town's cars it is in the traffic it does not see: no free road to crawl on.)
		# (Nor is its road free while it gives way to a car that crosses it at a junction.)
		flag.append((FREE if _free and pace >= 0.999 and d.cross_gap >= FREE_AHEAD else 0) | (HELD if held or d.held or d.daze > 0.0 or d.stun > 0.0 else 0) | (CONN if d.in_conn else 0)
				| (DEAD if dead else 0) | (AWAY if _dead_t >= 0.0 else 0))

	## The cars round the rival (every other frame): a car in its box, the car it sits behind,
	## whether the road ahead is free, who it passed and who passed it.
	func _scan(t: float, traffic: Node3D, ghost, player_live: bool) -> void:
		var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
		var here := Vector2(d.pos.x, d.pos.z)
		var road_top: float = minf(PLAYER_TOP, Traffic.RACE_CLASS_TOP[graph.e_class[d.edge]])
		_free = true
		var hop := -1
		if d.hop_go and d.in_conn:
			hop = RaceCuts.hop(graph.e_b[d.edge], graph.e_a[d.next_edge])
		var road: Vector2 = fwd if d.in_conn else graph.direction(d.edge, clampf(d.s, 0.0, graph.e_len[d.edge]))
		var lead = null
		var lead_gap := INF
		var over := {}
		var inside := false
		for o in traffic.drivers():
			if o == d or (o.ghost and not player_live) or o.clip < 1.0:
				continue
			if hop >= 0 and not o.ghost and not _hop_seen.has(o) and ((o.edge == hop and not o.in_conn) or (o.in_conn and o.next_edge == hop)):
				_hop_seen[o] = true
				hop_met += 1
			var rel := Vector2(o.pos.x - here.x, o.pos.z - here.y)
			var d2 := rel.length_squared()
			if d2 > 3600.0 or absf(o.pos.y - d.pos.y) > 2.5:
				continue
			var along := rel.dot(fwd)
			var side := absf(rel.cross(fwd))
			var room: float = (o.length + d.length) * 0.5
			# (The bench's map is flat: a street on a viaduct and the street under it are one
			# place here. Away from a junction a bridge's car and a ground street's never meet.)
			var level: bool = d.in_conn or o.in_conn or graph.e_bridge[d.edge] == graph.e_bridge[o.edge]
			if level and d2 < (room + 1.0) * (room + 1.0) and Traffic._boxes_overlap(d, o, rel):
				var was := float(_over.get(o, 0.0))
				over[o] = was + DT * 2.0
				if over[o] >= GHOST_MIN:
					inside = true
					if was < GHOST_MIN:
						overlaps += 1
						if hop >= 0:
							hop_overlaps += 1
						if not o.parked and fwd.dot(Vector2(-sin(o.yaw), -cos(o.yaw))) < -0.5:
							head_ons += 1
						if overlap_log.size() < 6:
							overlap_log.append("%.1f s %s on %s" % [t, "the player" if o.ghost else ("a parked car" if o.parked else "a car"), _street(d.edge)])
						if OS.is_stdout_verbose():
							print("    through a car at %.1f s on %s (%.0f, %.0f): rival v %.1f conn %s off %.1f pass %.1f squeeze %.1f lane %d edge %d · other kind %d v %.1f conn %s parked %s edge %d lane %d · along %.1f side %.1f" % [
									t, _street(d.edge), here.x, here.y, d.v, d.in_conn, d.off, d.pass_t, d.squeeze, d.lane, d.edge, o.kind, o.v, o.in_conn, o.parked, o.edge, o.lane, along, side])
							# (Its racing line, traffic.gd LINE_*: how far the line has it from its lane's own.)
							var rail: Vector2 = traffic._rail_at(d)
							print("      its line: %s, beside it %.2f m, stepping over %.2f m, %.2f m from its lane's line; the other car %.2f m from its own" % [
									"on" if d.line != null else "none", d.line_dyn, d.line_carry.length(), here.distance_to(rail),
									Vector2(o.pos.x, o.pos.z).distance_to(traffic._rail_at(o))])
			# (Ahead by the street's direction, not the car's nose: a car that stopped half way
			# into the next lane stands askew, with its queue beside its nose.)
			# A car just ahead in the next lane's width is in front too (a car at the head of a
			# queue that turns across a rival passing it: the rival brakes for it, FREE_NEAR).
			if rel.dot(road) > 0.0 and ((rel.dot(road) - room < FREE_AHEAD and absf(rel.cross(road)) < 2.2) \
					or (rel.dot(road) - room < FREE_NEAR and absf(rel.cross(road)) < FREE_NEAR_SIDE)):
				_free = false
			if along > 0.0 and side < 1.8 and along - room < lead_gap:
				lead_gap = along - room
				lead = o
			if o.ghost or o.parked or fwd.dot(Vector2(-sin(o.yaw), -cos(o.yaw))) < 0.5:
				continue
			# Passing: a car going the same way that was in front and is now behind (and the reverse).
			if along > room + 1.0 and along < 30.0 and side < 7.0:
				if _behind.has(o) and t - float(_behind[o]) < 20.0:
					overtaken += 1
				_behind.erase(o)
				_ahead[o] = t
			elif along < -room - 1.0 and along > -30.0 and side < 7.0:
				if _ahead.has(o) and t - float(_ahead[o]) < 20.0:
					passes += 1
				_ahead.erase(o)
				_behind[o] = t
		for o in _over:
			if not over.has(o) and float(_over[o]) < GHOST_MIN:
				touches += 1
		if inside:
			overlap_s += DT * 2.0
		_over = over
		if lead != null and lead_gap < BEHIND_GAP and lead.v < BEHIND_SLOW * road_top and not d.held:
			if lead != _leader:
				_leader = lead
				_leader_t = 0.0
				_leader_room_t = 0.0
			_leader_t += DT * 2.0
			var free_lane := _room(traffic, fwd, here, road_top, player_live)
			var room_was := _leader_room_t
			_leader_room_t = _leader_room_t + DT * 2.0 if free_lane else 0.0
			if OS.is_stdout_verbose() and (room_was <= BEHIND_MAX) != (_leader_room_t <= BEHIND_MAX):
				print("    behind a slower car with a free lane beside it %s at %.1f s on %s (%.0f, %.0f): rival v %.1f lane %d of %d off %.1f pass %.1f squeeze %.1f hold %.1f still %.1f · the car v %.1f lane %d edge %d conn %s, %.1f m ahead" % [
						"for %.0f s" % BEHIND_MAX if _leader_room_t > BEHIND_MAX else "ended after %.1f s" % room_was, t, _street(d.edge), here.x, here.y, d.v, d.lane, traffic.graph.e_lanes[d.edge], d.off, d.pass_t, d.squeeze, d.lane_hold, d.race_still, lead.v, lead.lane, lead.edge, lead.in_conn, lead_gap])
			behind_longest = maxf(behind_longest, _leader_t)
			behind_room_longest = maxf(behind_room_longest, _leader_room_t)
			if lead.ghost and lead.v < 0.5 and d.v < 0.5 and not free_lane:
				boxed += DT * 2.0
		else:
			_leader = null

	## Whether a lane beside the rival is free to pass in (PASS_BACK, PASS_AHEAD and ONCOMING_AHEAD
	## above): another lane of its own road, or the oncoming road's nearest lane.
	func _room(traffic: Node3D, fwd: Vector2, here: Vector2, road_top: float, player_live: bool) -> bool:
		if d.in_conn:
			return false
		var e: int = d.edge
		# Each lane to pass in: where it lies across the road from the rival (signed), and whether
		# it is the oncoming one.
		var across := PackedFloat32Array()
		var oncoming := PackedByteArray()
		for k in graph.e_lanes[e]:
			if k != d.lane:
				across.append((graph.point_at(e, d.s, graph.lane_offset(e, k)) - here).cross(fwd))
				oncoming.append(0)
		var rev := graph.e_reverse[e]
		# (Only from the lane by the centre line: a car in another lane has a lane of cars between
		# it and the oncoming one, and that lane is judged by itself above.)
		if rev >= 0 and d.lane == 0:
			var nearest := INF
			for k in graph.e_lanes[rev]:
				var x := (graph.point_at(rev, graph.e_len[e] - d.s, graph.lane_offset(rev, k)) - here).cross(fwd)
				if absf(x) < absf(nearest):
					nearest = x
			across.append(nearest)
			oncoming.append(1)
		for i in across.size():
			var open := true
			for o in traffic.drivers():
				if o == d or (o.ghost and not player_live) or o.clip < 1.0 or absf(o.pos.y - d.pos.y) > 2.5:
					continue
				var rel := Vector2(o.pos.x - here.x, o.pos.z - here.y)
				var along := rel.dot(fwd)
				if absf(rel.cross(fwd) - across[i]) > 1.7 or along < -PASS_BACK:
					continue
				if oncoming[i] == 1:
					open = along > ONCOMING_AHEAD
				else:
					open = along > PASS_AHEAD or (along > 8.0 and o.v >= BEHIND_SLOW * road_top)
				if not open:
					break
			if open:
				return true
		return false

	func _street(e: int) -> String:
		var n: String = graph.e_name[e]
		return n if n != "" else "an unnamed link"

	## Crawling (CRAWL_SHARE above): [seconds in all, the longest stretch].
	## The sample at which the longest crawl ended (for the trace).
	var crawl_end := -1

	func crawl() -> Vector2:
		var n := v.size()
		var j := 0
		var run := 0
		var longest := 0
		var total := 0
		for i in n:
			j = maxi(j, i)
			while j < n - 1 and cum[j] < cum[i] + STRAIGHT_AHEAD:
				j += 1
			var slow := v[i] < CRAWL_SHARE * top[i]
			if slow and flag[i] == FREE and absf(angle_difference(yaw[i], yaw[j])) < STRAIGHT_BEND:
				run += 1
				total += 1
				if run > longest:
					longest = run
					crawl_end = i
			else:
				run = 0
		return Vector2(total, longest) * DT

	## The sideways pull (m/s²) the car's way asks for, v² / radius over every GRIP_WINDOW m of it
	## (a rail car's heading steps at each point of the lane's line; a body feels the bend), not
	## counting a stretch where it was knocked or held, or stopped dead by the game (counted by
	## itself, `hard_stops`: its heading swings as it stands): {p95, max, and where the most was: at (s of
	## the race), where (the ground point), street, junction (on a junction's curve), speed (m/s),
	## turn (rad over the window)}.
	func sideways() -> Dictionary:
		var out := {"p95": 0.0, "max": 0.0, "at": 0.0, "where": Vector2.ZERO, "street": "", "junction": false, "speed": 0.0, "turn": 0.0}
		var pulls := PackedFloat32Array()
		var n := v.size()
		var held := PackedInt32Array()
		held.resize(n + 1)
		for i in n:
			held[i + 1] = held[i] + (1 if flag[i] & (HELD | DEAD) else 0)
		var j := 0
		for i in n:
			j = maxi(j, i)
			while j < n - 1 and cum[j] < cum[i] + GRIP_WINDOW:
				j += 1
			var run := cum[j] - cum[i]
			if run < GRIP_WINDOW:
				break
			if held[j + 1] - held[i] > 0:
				continue
			var speed := (v[i] + v[j]) * 0.5
			var turn := absf(angle_difference(yaw[i], yaw[j]))
			var pull := speed * speed * turn / run
			pulls.append(pull)
			if pull > float(out["max"]):
				var mid := (i + j) / 2
				out = {"p95": 0.0, "max": pull, "at": (mid + 1) * DT, "where": Vector2(px[mid], pz[mid]), "street": _street(edge_at[mid]),
						"junction": flag[mid] & CONN != 0, "speed": speed, "turn": turn}
		if pulls.is_empty():
			return out
		pulls.sort()
		out["p95"] = pulls[int((pulls.size() - 1) * 0.95)]
		return out

	## The streets driven, in order (each once per visit).
	func streets() -> PackedStringArray:
		var out := PackedStringArray()
		for e in edges:
			var n: String = graph.e_name[e]
			if n != "" and (out.is_empty() or out[out.size() - 1] != n):
				out.append(n)
		return out


var graph: LaneGraph
var cuts: RaceCuts
## The route planner (race_planner.gd): one for the map, a plan a race (and a leg of a forced route).
var planner: RacePlanner
## Why `open` or the last `race` could not run ("" when they did).
var error := ""
var _root: Node
var _map: Node3D
var _data := {}
var _roads := {}
var _links := {}
var _racer := {}


## Reads the committed map's lane graph and the shortcuts; false (see `error`) without the map.
func open(root: Node) -> bool:
	if not FileAccess.file_exists("res://map/centrum.json"):
		error = "no map/centrum.json"
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not parsed is Dictionary or not (parsed as Dictionary).has("graph"):
		error = "map/centrum.json has no lane graph"
		return false
	_root = root
	_map = FakeMap.new()
	root.add_child(_map)
	graph = LaneGraph.new(parsed["graph"], _map)
	_data = {"landmarks": parsed.get("landmarks", []), "pois": parsed.get("pois", [])}
	cuts = RaceCuts.new()
	cuts.load_cuts(graph)
	planner = RacePlanner.new(graph)
	return true


func close() -> void:
	if _map != null:
		_map.free()
		_map = null


static func rival_index(name: String) -> int:
	for i in Rivals.RIVALS.size():
		if Rivals.RIVALS[i]["name"] == name:
			return i
	return -1


## A race's name: the rival's ladder id, the tuning, the start, the situation (and the traffic's
## draw when it is not the first), the player (and the forced route).
static func race_id(spec: Dictionary) -> String:
	var rung := Ladder.rung_of(String(spec["rival"]))
	var who := String(Ladder.RUNGS[rung]["id"]) if rung >= 0 else String(spec["rival"])
	var situation := String(spec.get("situation", "clear"))
	if int(spec.get("seed", 0)) != 0:
		situation += "-s%d" % int(spec["seed"])
	var id := "%s/%s/%s/%s/%s" % [who, spec.get("tuning", "ladder"), spec.get("start_name", "start"), situation, spec.get("player", "none")]
	if spec.has("via_name"):
		id += "/via-" + String(spec["via_name"])
	return id


## The finish named `name` (rivals.gd FINISHES): {name, node, at, ends (the roads through its
## circle, race_planner.gd `ends`: the race is over on them too, rivals.gd `_track`)} or {}.
func finish(name: String) -> Dictionary:
	for f: Dictionary in Rivals.FINISHES:
		if f["name"] == name:
			var node := Rivals.finish_node(graph, _data, f)
			if node >= 0:
				return {"name": name, "node": node, "at": graph.node_pos[node], "ends": planner.ends(node, graph.node_pos[node], RaceSession.FINISH_RADIUS)}
	return {}


## Trzy mosty's finish by the stadium, as rivals.gd `start_final` has it: {node, at, ends (the
## roads through its circle), from (the junction its last leg starts at: the last bridge's far
## end)}; {} if the route does not build on this map.
func final_finish() -> Dictionary:
	var route := TrzyMosty.new()
	if not route.build(graph, _data):
		return {}
	var at := Vector2(route.finish["pos"].x, route.finish["pos"].z)
	var node: int = route.finish["node"]
	return {"node": node, "at": at, "ends": planner.ends(node, at, RaceSession.FINISH_RADIUS), "from": route.legs[route.legs.size() - 2]}


## The roads' distances to `node` (rivals.gd `_distances`).
func roads_to(node: int) -> PackedFloat32Array:
	if not _roads.has(node):
		_roads[node] = graph.distances_to(node)
	return _roads[node]


## The shortcuts rival `name` knows (rivals.gd `_use_cuts`): [its table, the routing's links].
## Without the hops along `no_hop` and the cuts onto the roads of `shut` (both {edge: true}).
func links_of(name: String, no_hop := {}, shut := {}) -> Array:
	var stats := Ladder.racer(Ladder.rung_of(name))
	if not no_hop.is_empty() or not shut.is_empty():
		return cuts.links(float(stats["cuts"]), hash(name), float(stats.get("yards", 0.0)), float(stats.get("narrow", 99.0)), float(stats.get("hops", 0.0)), no_hop, stats.get("home", []), shut)
	if not _links.has(name):
		_links[name] = cuts.links(float(stats["cuts"]), hash(name), float(stats.get("yards", 0.0)), float(stats.get("narrow", 99.0)), float(stats.get("hops", 0.0)), {}, stats.get("home", []))
	return _links[name]


## The race's distances to `node` for rival `name`: with its shortcuts (rivals.gd `_race_distances`),
## and to a finish with `ends` (its circle's roads) the metres to where each road enters it
## (rivals.gd `start_race`).
func racer_to(name: String, node: int, ends := {}) -> PackedFloat32Array:
	var extra: Dictionary = planner.links(node, ends, links_of(name)[1])
	if extra.is_empty():
		return roads_to(node)
	var key := "%s|%d|%s" % [name, node, "circle" if not ends.is_empty() else "junction"]
	if not _racer.has(key):
		_racer[key] = graph.distances_to(node, INF, true, extra)
	return _racer[key]


## ... and with the edges `shut` closed: the best other way (the game's own routing, lane_graph.gd
## `distances_to`'s `shut`).
func racer_avoiding(name: String, node: int, shut: PackedInt32Array, ends := {}) -> PackedFloat32Array:
	var closed := {}
	for e in shut:
		closed[e] = true
	return graph.distances_to(node, INF, true, planner.links(node, ends, links_of(name, {}, closed)[1], closed), closed)


## The grid of a race from ground point `p`: the car on the nearest lane (rivals.gd `put_ahead`),
## on the side of the road that leads to the finish (by `dist`), and the rival START_AHEAD m in
## front of it, or in the guided first race (`first`) FIRST_BEHIND m behind it:
## {car: [edge, lane, s], rival: [edge, lane, s]} or {}.
func grid(p: Vector2, dist: PackedFloat32Array, first: bool) -> Dictionary:
	var hit := graph.snap(p, 40.0, Vector2.ZERO, true)
	if hit.is_empty():
		return {}
	var e: int = hit[0]
	var lane: int = hit[1]
	var s: float = hit[2]
	var rev := graph.e_reverse[e]
	if rev >= 0 and graph.remaining(dist, rev, graph.e_len[e] - s) < graph.remaining(dist, e, s):
		s = graph.e_len[e] - s
		e = rev
		lane = mini(lane, graph.e_lanes[e] - 1)
	s = clampf(s, graph.e_s0[e] + 2.0, maxf(graph.e_s1[e] - START_AHEAD - 6.0, graph.e_s0[e] + 2.0))
	if first:
		return {"car": [e, lane, s], "rival": Rivals.lane_behind(graph, e, lane, s, FIRST_BEHIND)}
	return {"car": [e, lane, s], "rival": [e, lane, s + START_AHEAD]}


## Where the "blocked" situation's wall goes: the street of the rival's own route (`edges`, from
## its clear run) nearest 45 % of the way that is long enough, on the ground, and has another way
## round at most 1.6 times as long: {edge, s, street, base_m (its route), alt_m (the best other way
## from the start), turn_m (the way of a driver who finds out at the wall: to it, back to the
## junction behind, and round from there)} or {}.
func plan_wall(spec: Dictionary, edges: PackedInt32Array) -> Dictionary:
	var name := String(spec["rival"])
	var fin := finish(String(spec.get("finish", FINISH)))
	var dist := racer_to(name, fin["node"], fin["ends"])
	var places := grid(spec["start"], dist, spec.get("tuning", "ladder") == "first")
	if places.is_empty():
		return {}
	var spot: Array = places["rival"]
	var base := graph.remaining(dist, spot[0], spot[2])
	var total := 0.0
	for e in edges:
		total += graph.e_len[e]
	var best := {}
	var best_off := INF
	var at := 0.0
	for e in edges:
		var before := at
		var share := (at + graph.e_len[e] * 0.5) / maxf(total, 1.0)
		at += graph.e_len[e]
		if share < 0.25 or share > 0.7 or absf(share - 0.45) >= best_off:
			continue
		if e == spot[0] or graph.e_s1[e] - graph.e_s0[e] < 50.0 or graph.e_bridge[e] == 1 or graph.e_tn[e] >= 0:
			continue
		var shut := PackedInt32Array([e])
		if graph.e_reverse[e] >= 0:
			shut.append(graph.e_reverse[e])
		var other := racer_avoiding(name, fin["node"], shut, fin["ends"])
		var alt := graph.remaining(other, spot[0], spot[2])
		if alt == INF or alt > base * 1.6 or other[graph.e_a[e]] == INF:
			continue
		var mid := (graph.e_s0[e] + graph.e_s1[e]) * 0.5
		best_off = absf(share - 0.45)
		best = {"edge": e, "s": mid, "street": graph.e_name[e], "base_m": base, "alt_m": alt,
				"turn_m": before - float(spot[2]) + mid + mid + other[graph.e_a[e]]}
	return best


## Where the "crash" situation's wreck goes: the street of the rival's own route nearest 35 % of
## the way with room to go round (a second lane, or an oncoming one): {edge, s, street} or {}.
func plan_wreck(spec: Dictionary, edges: PackedInt32Array) -> Dictionary:
	var total := 0.0
	for e in edges:
		total += graph.e_len[e]
	var best := {}
	var best_off := INF
	var at := 0.0
	for k in edges.size():
		var e := edges[k]
		var share := (at + graph.e_len[e] * 0.5) / maxf(total, 1.0)
		at += graph.e_len[e]
		if k == 0 or share < 0.2 or share > 0.55 or absf(share - 0.35) >= best_off:
			continue
		if graph.e_s1[e] - graph.e_s0[e] < 70.0 or graph.e_bridge[e] == 1 or graph.e_tn[e] >= 0:
			continue
		if graph.e_lanes[e] < 2 and graph.e_reverse[e] < 0:
			continue
		best_off = absf(share - 0.35)
		best = {"edge": e, "s": (graph.e_s0[e] + graph.e_s1[e]) * 0.5, "street": graph.e_name[e]}
	return best


## Runs one race and returns what happened. `spec`:
##   rival      the rival's name (rivals.gd RIVALS)
##   tuning     "ladder" (a challenge) or "first" (the guided first race)
##   start      a ground point (Vector2) and start_name, its name for the race's id
##   finish     a finish's name (rivals.gd FINISHES; FINISH when left out)
##   situation  a SITUATIONS key; "blocked" needs `wall` (plan_wall), "crash" `wreck` (plan_wreck)
##   player     a PLAYERS entry
##   seed       0 (the traffic's own seed) or another traffic draw
##   via        ground points the rival is routed through in order (a forced route), via_name
##   ease       how much an easier rematch slows the rival (ladder.gd `ease_of`; 0 when left out)
##   skill      for tuning: racer stats to drive in place of the rival's own (ladder.gd's keys)
##   traffic    for tuning: a Settings.TRAFFIC level (0 Almost empty .. 3 Busy) in place of the
##              situation's
##   no_plan    for tuning: the rival drives the shortest way in metres, without a plan
##   view       for the checks: a ground point the view stays on (Vector2) in place of the test
##              player or the rival: far from the race, the rival is out of the town's cars all
##              the way (traffic.gd AWAY_*)
##   trace      print what the rival does once a second
func race(spec: Dictionary) -> Dictionary:
	var wall0 := Time.get_ticks_msec()
	error = ""
	var out := {"id": race_id(spec), "rival": spec["rival"], "tuning": spec.get("tuning", "ladder"), "start": spec.get("start_name", "start"),
			"situation": spec.get("situation", "clear"), "player": spec.get("player", "none"), "seed": int(spec.get("seed", 0)),
			"finished": false, "time": TIME_LIMIT, "hold_s": 0.0}
	if spec.has("via_name"):
		out["via"] = spec["via_name"]
	var name := String(spec["rival"])
	var who := rival_index(name)
	var rung := Ladder.rung_of(name)
	var first: bool = out["tuning"] == "first"
	var sit: Dictionary = SITUATIONS.get(out["situation"], {})
	var kind := String(out["player"])
	var fin := finish(String(spec.get("finish", FINISH)))
	if out["tuning"] == "final":
		# The final: its own racer and Trzy mosty's finish (rivals.gd `start_final`).
		rung = Ladder.FINAL
		fin = final_finish()
	if who < 0 or rung < 0 or fin.is_empty() or sit.is_empty() or not kind in PLAYERS:
		error = "%s: unknown rival, finish, situation or player" % out["id"]
		out["error"] = error
		return out
	var table: Dictionary = links_of(name)[0]
	var dist := racer_to(name, fin["node"], fin["ends"])
	var plain := roads_to(fin["node"])
	var places := grid(spec["start"], dist, first)
	if places.is_empty():
		error = "%s: no lane near %s" % [out["id"], spec["start"]]
		out["error"] = error
		return out
	var spot: Array = places["rival"]
	var e0: int = spot[0]
	var lane0: int = spot[1]
	var s0: float = spot[2]
	var goal := Vector3(fin["at"].x, 0.0, fin["at"].y)
	out["route_m"] = graph.remaining(dist, e0, s0)
	out["road_m"] = graph.remaining(plain, e0, s0)
	# The course: the forced route's points' nodes, the finish last (its circle on the last leg).
	var legs := PackedInt32Array()
	for p: Vector2 in spec.get("via", []):
		legs.append(graph.nearest_node(p))
	legs.append(fin["node"])

	# This race's world: a fresh traffic system (its own seeds) and the lights' clock at zero.
	graph.clock = 0.0
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = FollowCamera.DEFAULT_SIZE
	_root.add_child(cam)
	var traffic: Node3D = Traffic.new()
	_root.add_child(traffic)
	traffic.setup(graph, _map, cam, {})
	traffic.set_process(false)
	traffic.set_physics_process(false)
	var level := int(spec.get("traffic", sit.get("traffic", -1)))
	traffic.spawning = level >= 0
	if level >= 0:
		traffic.density = float(Settings.TRAFFIC[level])
	if int(out["seed"]) != 0:
		traffic._rng.seed = 2026 + int(out["seed"])
	var body := Node3D.new()
	traffic.add_child(body)
	var d = traffic.add_node_driver(body, Rivals.RIVALS[who]["size"], e0, lane0, s0)
	d.held = true
	var ghost = null
	if kind != "none":
		ghost = traffic.add_ghost(places["car"][0], places["car"][1], places["car"][2])
		ghost.held = true
	if sit.has("wall"):
		var wall: Dictionary = spec.get("wall", {})
		if wall.is_empty():
			error = "%s: no street to block" % out["id"]
		else:
			_park_wall(traffic, int(wall["edge"]), float(wall["s"]))
			out["wall"] = {"street": wall["street"], "base_m": snappedf(float(wall["base_m"]), 1.0), "alt_m": snappedf(float(wall["alt_m"]), 1.0),
					"turn_m": snappedf(float(wall["turn_m"]), 1.0)}
	if sit.has("hop_car"):
		var hop := -1
		var best := 60.0
		for h: int in RaceCuts._against.values():
			var gap := graph.point_at(h, graph.e_len[h] * 0.5, 0.0).distance_to(HOP_BLOCK)
			if gap < best:
				best = gap
				hop = h
		if hop < 0:
			error = "%s: no wrong-way hop at HOP_BLOCK" % out["id"]
		else:
			_park(traffic, hop, graph.e_len[hop] * 0.5, 0, 0.0)
	var knock_left := -1.0
	if sit.has("wreck"):
		var wreck: Dictionary = spec.get("wreck", {})
		if wreck.is_empty():
			error = "%s: no street for the wreck" % out["id"]
		else:
			_park_wreck(traffic, int(wreck["edge"]), float(wreck["s"]))
			out["wreck"] = {"street": wreck["street"]}
			knock_left = float(out["route_m"]) * 0.4
	if error != "":
		out["error"] = error
		traffic.free()
		cam.free()
		return out

	# The race session (race_session.gd), as rivals.gd races: the rival its one racer, with its
	# rung's pace and racer stats (the final's in the final, Halina's gentle day in the first race),
	# the shortcuts of its rung (the bench's own rule: the rival's rung's, also in the final), its own
	# dice (the same for this rival and draw whoever the test player is). The metres left are summed
	# leg by leg (`exact_left`), as the bench always did; every leg's distances now.
	var session := RaceSession.new()
	session.setup(graph, traffic, planner, cuts, _roads)
	session.course(legs, fin["at"], RaceSession.FINISH_RADIUS)
	session.exact_left = true
	var r := session.add(d, name, Ladder.FIRST_RACER if first else Ladder.racer(rung), Ladder.pace(rung), {
			"top": PLAYER_TOP, "ease": float(spec.get("ease", 0.0)), "dice": hash("%s/%d" % [name, int(out["seed"])]),
			"cuts_of": Ladder.racer(Ladder.rung_of(name)), "plan": not spec.get("no_plan", false)})
	session.prepare()
	# A street the rival finds blocked, a wrong-way hop it refused (step 5b): the metres it has left
	# are counted without it from then on (rivals.gd `_on_turned_back`, `_on_hop_refused`).
	traffic.turned_back.connect(func(who) -> void: session.turned_back(who))
	traffic.hop_refused.connect(func(who) -> void: session.hop_refused(who))
	var probe := Probe.new()
	probe.graph = graph
	probe.d = d
	var stats := {}
	# Step 6a: the rival's lights (race_signals.gd, the session's `signals`), and of the turns it
	# made how many it had indicated as it went into the junction.
	var sig := r.sig
	var sig_conn := false
	var turns := 0
	var turns_lit := 0
	var t := -LEAD_IN
	var started := false
	var hold := false
	var tick := 0.0
	var player_live := ghost != null
	var rival_left := INF
	var player_left := INF
	var next_trace := 0.0
	# The plan's own clock: the seconds it gave the race at the start (a forced route: leg by leg).
	var plan_s := 0.0
	while t < TIME_LIMIT:
		# The test player as the game's traffic sees the car, and the view that follows it (the
		# rival itself when there is no player: a spectator's view).
		if player_live:
			traffic.player_on_road = true
			traffic.player_pos = ghost.pos
			traffic.player_vel = Vector3(-sin(ghost.yaw), 0.0, -cos(ghost.yaw)) * ghost.v
		else:
			traffic.player_on_road = false
			traffic.player_pos = d.pos + Vector3(5000.0, 0.0, 0.0)
			traffic.player_vel = Vector3.ZERO
		if spec.get("view") is Vector2:
			_look(cam, Vector3(spec["view"].x, 0.0, spec["view"].y))
		else:
			_look(cam, ghost.pos if ghost != null else d.pos)
		if not started and t >= 0.0:
			started = true
			t = 0.0
			if spec.has("skill"):
				# Tuning: racer stats to try in place of the rival's own (share, race_accel, brake, lat),
				# armed and planned with.
				r.stats = r.stats.duplicate()
				r.stats.merge(spec["skill"], true)
			stats = r.stats
			# The rival's plan (rivals.gd `_go`): a table of times to the finish (its circle) for its
			# own driving, and one to each point of a forced route (a junction), all made now for
			# the town's traffic as it is; then it is armed and sets off (`start`).
			for k in legs.size():
				session.plan(r, k)
			session.start(r)
			plan_s = _plan_time(d)
			# PT-11: in the first race she waits at the line until the player moves.
			hold = first and ghost != null
			d.held = hold
			if ghost != null:
				# The test player's own plan, where it needs one: the follower takes the rival's
				# streets (the quickest for her, not the shortest), and at a wall every test player
				# turns round as a person would (without a plan it stood behind the rival, in her
				# way back, and then slipped through her and the wall).
				var own = null
				if not spec.get("no_plan", false) and (kind == "follower" or sit.has("wall")):
					own = planner.plan(fin["node"], stats, PLAYER_TOP, table if kind == "follower" else {}, 0.0, PackedInt32Array(), fin["at"], RaceSession.FINISH_RADIUS)
				_arm_player(traffic, ghost, kind, fin["node"], plain, dist, table, own)
		if started:
			if hold and Rivals.first_start_step(t, ghost.v) == "release":
				hold = false
				d.held = false
				out["hold_s"] = snappedf(t, 0.01)
			if r.leg < legs.size() - 1 and not d.in_conn and graph.e_b[d.edge] == legs[r.leg]:
				# The clock: what the last leg's plan still held for this street is in the next one's.
				plan_s -= _plan_time(d)
				session.next_leg(r)
				plan_s += _plan_time(d)
			if kind == "follower" and player_live:
				# The follower: as fast as it takes to sit FOLLOW_GAP m behind the rival; while it is
				# still in front of her (the first race's grid) it rolls off at FOLLOW_ROLL and lets her by.
				var back: float = traffic.remaining(ghost) - traffic.remaining(d)
				var cap: float = minf(ghost.race_top, Traffic.RACE_CLASS_TOP[graph.e_class[ghost.edge]])
				var want: float = FOLLOW_ROLL if back < 0.0 else d.v + (back - FOLLOW_GAP) * 0.8
				ghost.race_effort = clampf(want / maxf(cap, 1.0), 0.0, 1.3)
				ghost.race_corner = ghost.race_effort
			tick -= DT
			if tick <= 0.0:
				tick = TICK
				if ghost == null:
					player_left = INF
				elif player_live:
					player_left = RaceSession.remaining_from(graph, dist, Vector2(ghost.pos.x, ghost.pos.z), goal, fin["ends"])
				else:
					player_left = 0.0
				# The metres left and the effort (RaceSession.pace_tick) for each racer.
				session.rank(player_left)
				rival_left = r.left
				var mult: float = d.race_effort
				if knock_left > 0.0 and rival_left < knock_left:
					# The knock: a full hit from the side (traffic.gd on_player_bump's daze and slide).
					knock_left = -1.0
					d.daze = Traffic.DAZE
					d.slide = Traffic.SHOVE_SLIDE
					d.v *= 0.4
					probe.knocked = true
					out["knock_s"] = snappedf(t, 0.1)
				if spec.get("trace", false) and t >= next_trace:
					next_trace += 1.0
					print("  trace %s: t %.0f s · rival %.1f m/s, effort x%.2f, class %d, left %.0f m, %s · player %.1f m/s, left %.0f m · the rival's lead %.0f m · seen %s · %d cars" % [
							out["id"], t, d.v, mult, graph.e_class[d.edge], rival_left, probe._street(d.edge), ghost.v if ghost != null else 0.0,
							player_left, player_left - rival_left, d.visible, traffic.drivers().size()])
		traffic._process(DT)
		t += DT
		if not started:
			continue
		probe.sample(t, traffic, ghost, hold, player_live)
		session.signals(DT)
		if d.in_conn and not sig_conn and RaceSignals.turn_side(d, graph) != 0:
			turns += 1
			if sig.indicating():
				turns_lit += 1
		sig_conn = d.in_conn
		if player_live and kind != "stopped" and (ghost.arrived or RaceSession.home_at(graph, ghost.pos, goal, fin["ends"])):
			# The player is home first (the game's own test: the circle, or level with it on a road
			# through it): the game's race ends here; the bench lets the rival drive on to the line
			# (its time is what is measured) with the player's car out of the way.
			player_live = false
			out["player_time"] = snappedf(t, 0.01)
		if r.leg == legs.size() - 1 and session.arrived(r):
			out["finished"] = true
			out["time"] = snappedf(t, 0.01)
			break

	var crawl := probe.crawl()
	if OS.is_stdout_verbose() and crawl.y > CRAWL_MAX and probe.crawl_end >= 0:
		print("    longest crawl %.1f s ended at %.1f s on %s (%.0f, %.0f) at %.1f m/s" % [crawl.y, probe.crawl_end * DT, probe._street(probe.edge_at[probe.crawl_end]), probe.px[probe.crawl_end], probe.pz[probe.crawl_end], probe.v[probe.crawl_end]])
	var n := maxi(probe.frames, 1)
	out["winner"] = "player" if out.has("player_time") else ("rival" if out["finished"] else "nobody")
	out["left_m"] = snappedf(session.metres_left(r), 1.0) if not out["finished"] else 0.0
	out["driven_m"] = snappedf(probe.driven, 1.0)
	out["mean_kmh"] = snappedf(probe.driven / maxf(float(out["time"]) - float(out["hold_s"]), 1.0) * 3.6, 0.1)
	out["top_kmh"] = snappedf(probe.top_v * 3.6, 0.1)
	out["stopped_s"] = snappedf(probe.stopped, 0.1)
	out["crawl_s"] = snappedf(crawl.x, 0.1)
	out["crawl_longest_s"] = snappedf(crawl.y, 0.1)
	out["behind_longest_s"] = snappedf(probe.behind_longest, 0.1)
	out["behind_room_longest_s"] = snappedf(probe.behind_room_longest, 0.1)
	out["boxed_s"] = snappedf(probe.boxed, 0.1)
	out["away_s"] = snappedf(probe.away, 0.1)
	out["away_paid_s"] = snappedf(probe.away_paid, 0.1)
	out["passes"] = probe.passes
	out["overtaken"] = probe.overtaken
	out["slips"] = probe.slips
	out["slips_seen"] = probe.slips_seen
	out["overlaps"] = probe.overlaps
	out["head_ons"] = probe.head_ons
	out["overlap_s"] = snappedf(probe.overlap_s, 0.1)
	out["overlap_log"] = probe.overlap_log
	out["touches"] = probe.touches
	out["jumps"] = probe.jumps
	out["jumps_seen"] = probe.jumps_seen
	out["accel_max"] = snappedf(probe.accel_max, 0.1)
	out["brake_max"] = snappedf(probe.brake_max, 0.1)
	out["hard_stops"] = probe.hard_stops
	out["hard_log"] = probe.hard_log
	var pull := probe.sideways()
	out["lat_p95"] = snappedf(float(pull["p95"]), 0.1)
	out["lat_max"] = snappedf(float(pull["max"]), 0.1)
	out["lat_at"] = "%.0f km/h through %.0f° in %.0f m %s %s (%.0f, %.0f) at %.1f s" % [float(pull["speed"]) * 3.6, rad_to_deg(pull["turn"]), GRIP_WINDOW,
			"in a junction of" if pull["junction"] else "on", pull["street"], pull["where"].x, pull["where"].y, pull["at"]]
	out["seen_share"] = snappedf(float(probe.seen) / n, 0.01)
	out["cuts"] = d.cuts_taken
	out["links"] = d.links_taken
	out["hops"] = d.hops_taken
	out["hops_refused"] = d.hops_refused
	out["hop_met"] = probe.hop_met
	out["hop_overlaps"] = probe.hop_overlaps
	out["mistakes"] = d.mistakes
	out["wrong_turns"] = d.wrong_turns
	out["blocks"] = d.blocks
	out["centre_passes"] = d.race_passes
	out["lights"] = {"brakes": sig.brakes, "indications": sig.indications, "flashes": sig.flashes, "hazards": sig.hazards, "turns": turns, "turns_lit": turns_lit}
	out["pace_lo"] = snappedf(r.effort.lo, 0.01)
	out["pace_hi"] = snappedf(r.effort.hi, 0.01)
	out["share"] = snappedf(d.race_share, 0.001)
	out["plan_s"] = snappedf(plan_s, 0.1)
	out["turned_back"] = d.turns_back
	out["back"] = Array(probe.backs)
	out["cars"] = snappedf(float(probe.cars) / n, 0.1)
	out["step_usec"] = roundi(float(probe.usec) / n)
	out["step_most_usec"] = probe.usec_most
	out["step_most_at"] = snappedf(probe.usec_most_t, 0.1)
	out["steps_slow"] = probe.slow_steps
	out["streets"] = Array(probe.streets())
	out["edges"] = Array(probe.edges)
	# The seconds on each of them (the last: to the finish, or to where the race was stopped).
	var edge_s: Array = []
	for k in probe.edge_t.size():
		edge_s.append(snappedf((probe.edge_t[k + 1] if k + 1 < probe.edge_t.size() else t) - probe.edge_t[k], 0.01))
	out["edge_s"] = edge_s
	traffic.free()
	cam.free()
	out["wall_ms"] = Time.get_ticks_msec() - wall0
	return out


## The seconds the rival's plan gives it from where it is to its plan's finish (0: no plan).
func _plan_time(d) -> float:
	if d.plan == null:
		return 0.0
	var t: float = d.plan.left(d.edge, d.s, d.v)
	return t if t < INF else 0.0


## The view: the game's camera on `focus` (yaw VIEW_YAW, FollowCamera's pitch and size).
func _look(cam: Camera3D, focus: Vector3) -> void:
	var basis := Basis(Vector3.UP, deg_to_rad(VIEW_YAW)) * Basis(Vector3.RIGHT, deg_to_rad(-FollowCamera.DEFAULT_PITCH))
	cam.global_transform = Transform3D(basis, focus + basis.z * VIEW_BACK)


## The test player sets off (rivals.gd `_start_ghost`): the roads only, at its pace; the follower
## takes the rival's own way (its shortcuts too) so it can stay behind it.
func _arm_player(traffic: Node3D, ghost, kind: String, node: int, plain: PackedFloat32Array, dist: PackedFloat32Array, table: Dictionary,
		plan = null) -> void:
	if kind == "stopped":
		return
	var pace := SLOW_PACE if kind == "slow" else AVERAGE_PACE
	ghost.speed_factor = pace
	ghost.accel_factor = 2.2 * pace / 1.8
	if kind == "fast" or kind == "follower":
		# --ghost-pace=racer: a skilled player, racer mode at the car's own top on the roads.
		ghost.speed_factor = 1.8
		ghost.race_top = PLAYER_TOP
		ghost.race_accel = 12.0
		ghost.race_lat = 8.5
	if kind == "follower":
		ghost.cuts = table
		traffic.race_to(ghost, node, dist, plan)
	else:
		traffic.race_to(ghost, node, plain, plan)
	ghost.held = false


## A wall of parked cars across every lane of edge e at s, both ways.
func _park_wall(traffic: Node3D, e: int, s: float) -> void:
	for side in 2:
		var f := e if side == 0 else graph.e_reverse[e]
		if f < 0:
			continue
		var at := s if side == 0 else graph.e_len[e] - s
		for k in graph.e_lanes[f]:
			_park(traffic, f, at, k, 0.0)


## A wreck on edge e at s: a car across every lane but the kerb's (on a one-lane road: its lane,
## the way round is the oncoming one).
func _park_wreck(traffic: Node3D, e: int, s: float) -> void:
	for k in maxi(1, graph.e_lanes[e] - 1):
		_park(traffic, e, s + 5.0 * k, k, 0.45)


func _park(traffic: Node3D, e: int, s: float, lane: int, turned: float) -> void:
	var p := graph.point_at(e, s, graph.lane_offset(e, lane))
	var dir := graph.direction(e, s)
	traffic.add_parked_car(e, s, Vector3(p.x, graph.height(e, s), p.y), atan2(-dir.x, -dir.y) + turned, lane, 0, Color("#c9c9c9"))


# --- the pass marks ---------------------------------------------------------------------------

## The pass marks of a set of races (`race` results): a list of {id, title, pass (true, false, or
## null when the set has no race that could show it), value (the number that decided), worst (the
## race to look at)}.
static func judge(results: Array) -> Array:
	var by_id := {}
	var groups := {}
	var repeats: Array = []
	for r: Dictionary in results:
		if r.has("error"):
			continue
		if by_id.has(r["id"]):
			repeats.append(r)
			continue
		by_id[r["id"]] = r
		if not r.has("via"):
			var key := "%s/%s/%s" % [String(r["id"]).get_slice("/", 0), r["tuning"], r["start"]]
			if not groups.has(key):
				groups[key] = {}
			groups[key]["%s/%s" % [String(r["id"]).get_slice("/", 3), r["player"]]] = r
	var out: Array = []

	# Finishes.
	var unfinished := 0
	var worst := ""
	# Whether the set has races among the town's cars (a mark that counts them is a traffic mark:
	# check_race_bench.gd records its pass only from two machines).
	var traffic := false
	for r: Dictionary in by_id.values():
		if _in_traffic(r):
			traffic = true
	for r: Dictionary in by_id.values():
		if not r["finished"]:
			unfinished += 1
			if worst == "":
				worst = r["id"]
	out.append(_mark("finishes", "Finishes", unfinished == 0 if not by_id.is_empty() else null,
			"%d of %d races finished" % [by_id.size() - unfinished, by_id.size()], worst, traffic))

	# Independence: the rival's time whatever the player does, against its time with no player on
	# the same roads. (In traffic too, both ways: the town's cars are where the player is, and a
	# rival that leaves them behind owes the delay they would have cost it, traffic.gd AWAY_*.
	# Before step 3 only slower counted there: a player left behind meant empty streets.)
	var judged := 0
	var dev := 0.0
	var one := 0.0
	var lost := 0
	var boxed := 0
	worst = ""
	var worst_lost := ""
	var worst_one := ""
	# In traffic: a pair's seconds with the player and alone, over its draws; and the draws.
	var pairs := {}
	var draws := {}
	for key: String in groups:
		var g: Dictionary = groups[key]
		for sp: String in g:
			var base: Dictionary = g.get(sp.get_slice("/", 0) + "/none", {})
			if base.is_empty() or sp.ends_with("/none") or not base["finished"]:
				continue
			var r: Dictionary = g[sp]
			if not r["finished"] and float(r.get("boxed_s", 0.0)) > BOXED_SHARE * _run(r):
				# Boxed in behind the player's stopped car (BOXED_SHARE): Finishes' race, not this mark's.
				boxed += 1
				continue
			judged += 1
			if not r["finished"]:
				lost += 1
				if worst_lost == "":
					worst_lost = r["id"]
				continue
			var x := absf(_run(r) / maxf(_run(base), 1.0) - 1.0)
			if not _in_traffic(r):
				if x > dev:
					dev = x
					worst = r["id"]
				continue
			if x > one:
				one = x
				worst_one = r["id"]
			var pair := "%s/%s/%s" % [key, r["situation"], r["player"]]
			if not pairs.has(pair):
				pairs[pair] = [0.0, 0.0, 0]
			pairs[pair][0] += _run(r)
			pairs[pair][1] += _run(base)
			pairs[pair][2] += 1
			draws[int(r["seed"])] = true
	var pair_dev := 0.0
	var worst_pair := ""
	for pair: String in pairs:
		# (One draw of the town's cars is no measure of a pair: INDEPENDENCE_DRAWS.)
		if int(pairs[pair][2]) < INDEPENDENCE_DRAWS:
			continue
		var x := absf(float(pairs[pair][0]) / maxf(float(pairs[pair][1]), 1.0) - 1.0)
		if x > pair_dev:
			pair_dev = x
			worst_pair = "%s over %d draws" % [pair, pairs[pair][2]]
	var indep_ok := dev <= INDEPENDENCE and pair_dev <= INDEPENDENCE and one <= INDEPENDENCE_ONE and lost == 0
	var indep_worst := worst_lost
	if dev > INDEPENDENCE:
		indep_worst = worst
	elif pair_dev > INDEPENDENCE:
		indep_worst = worst_pair
	elif one > INDEPENDENCE_ONE:
		indep_worst = worst_one
	out.append(_mark("independence", "Independence", indep_ok if judged > 0 else null,
			"the rival's time moves with the player up to %d %% on clear roads (limit %d %%)%s%s%s" % [roundi(dev * 100.0), roundi(INDEPENDENCE * 100.0),
			"; in traffic up to %d %% for a pair over its draws (limit %d %%; %d pairs, %d draws) and %d %% in one race (limit %d %%)" % [
				roundi(pair_dev * 100.0), roundi(INDEPENDENCE * 100.0), pairs.size(), draws.size(), roundi(one * 100.0), roundi(INDEPENDENCE_ONE * 100.0)] if not pairs.is_empty() else "",
			"; %d of %d races it finishes alone it never finishes with the player" % [lost, judged] if lost > 0 else "",
			"; %d not judged here: boxed in behind the player's stopped car with no lane to pass in (Finishes counts it)" % boxed if boxed > 0 else ""],
			indep_worst, not pairs.is_empty()))

	# No crawl.
	var crawl := -1.0
	worst = ""
	for r: Dictionary in by_id.values():
		if float(r["crawl_longest_s"]) > crawl:
			crawl = float(r["crawl_longest_s"])
			worst = r["id"]
	out.append(_mark("no_crawl", "No crawl", (crawl <= CRAWL_MAX) if crawl >= 0.0 else null,
			"longest crawl on a free straight road %.1f s (limit %.0f)" % [crawl, CRAWL_MAX], worst, traffic))

	# Passes traffic: among the town's cars.
	var behind := -1.0
	var behind_n := 0
	var behind_of := 0
	worst = ""
	for r: Dictionary in by_id.values():
		if not _in_traffic(r):
			continue
		behind_of += 1
		if float(r["behind_room_longest_s"]) > BEHIND_MAX:
			behind_n += 1
		if float(r["behind_room_longest_s"]) > behind:
			behind = float(r["behind_room_longest_s"])
			worst = r["id"]
	out.append(_mark("passes_traffic", "Passes traffic", (behind <= BEHIND_MAX) if behind >= 0.0 else null,
			"longest behind one slower car with a free lane beside it %.1f s (limit %.0f), longer than that in %d of %d races in traffic" % [behind, BEHIND_MAX, behind_n, behind_of], worst, true))

	# No ghosting.
	var through := 0
	var through_s := 0.0
	worst = ""
	for r: Dictionary in by_id.values():
		through += int(r["overlaps"])
		through_s += float(r["overlap_s"])
		if int(r["overlaps"]) > 0 and worst == "":
			worst = r["id"]
	out.append(_mark("no_ghosting", "No ghosting", through == 0 if not by_id.is_empty() else null,
			"drove through %d cars (%.1f s inside one; %.2f s or more counts)%s" % [through, through_s, GHOST_MIN, _by_draw(by_id, ["overlaps"])], worst, traffic))

	# Re-routes: the blocked street, against the same race on clear roads.
	var blocked := 0
	var rerouted := 0
	worst = ""
	var note := ""
	for key: String in groups:
		var g: Dictionary = groups[key]
		for sp: String in g:
			var r: Dictionary = g[sp]
			if r["situation"] != "blocked" or not r.has("wall"):
				continue
			var base := _clear_of(g, r)
			if base.is_empty():
				continue
			blocked += 1
			var allowed: float = _run(base) * float(r["wall"]["turn_m"]) / maxf(float(r["wall"]["base_m"]), 1.0) * REROUTE_SLACK + REROUTE_GRACE
			if r["finished"] and int(r["overlaps"]) == 0 and _run(r) <= allowed:
				rerouted += 1
			elif worst == "":
				worst = r["id"]
				note = "%s shut: %s%.1f s, %d cars driven through (allowed %.1f s and none)" % [r["wall"]["street"], "" if r["finished"] else "never home, ", _run(r), int(r["overlaps"]), allowed]
	out.append(_mark("reroutes", "Re-routes", rerouted == blocked if blocked > 0 else null,
			"%d of %d blocked streets taken another way%s" % [rerouted, blocked, "; " + note if note != "" else ""], worst))

	# Recovers: never moved by the game while seen, and the wreck and the knock cost little.
	var moved := 0
	var crashes := 0
	var recovered := 0
	worst = ""
	note = ""
	for r: Dictionary in by_id.values():
		moved += int(r["slips_seen"]) + int(r["jumps_seen"])
		if int(r["slips_seen"]) + int(r["jumps_seen"]) > 0 and worst == "":
			worst = r["id"]
	for key: String in groups:
		var g: Dictionary = groups[key]
		for sp: String in g:
			var r: Dictionary = g[sp]
			if r["situation"] != "crash":
				continue
			var base := _clear_of(g, r)
			if base.is_empty():
				continue
			crashes += 1
			if r["finished"] and int(r["overlaps"]) == 0 and _run(r) <= _run(base) + RECOVER_LOSS:
				recovered += 1
			elif note == "":
				worst = r["id"]
				note = "the wreck and the knock cost %s%.1f s, %d cars driven through (allowed %.0f s and none)" % ["" if r["finished"] else "the race: ", _run(r) - _run(base), int(r["overlaps"]), RECOVER_LOSS]
	out.append(_mark("recovers", "Recovers", (moved == 0 and recovered == crashes) if not by_id.is_empty() else null,
			"moved by the game in view %d times%s; %d of %d crashes recovered%s" % [moved, _by_draw(by_id, ["slips_seen", "jumps_seen"]), recovered, crashes, "; " + note if note != "" else ""], worst, traffic))

	# Honest car: the player's car's limits (top speed, pull, sideways grip, brakes).
	var top := 0.0
	var pull := 0.0
	var grip := 0.0
	var dead := 0
	var honest := true
	worst = ""
	note = ""
	for r: Dictionary in by_id.values():
		if float(r["top_kmh"]) > PLAYER_TOP * 3.6 * 1.02 or float(r["accel_max"]) > PLAYER_ACCEL + 0.5 or float(r["lat_max"]) > PLAYER_GRIP or int(r["hard_stops"]) > 0:
			honest = false
			if worst == "":
				worst = r["id"]
		top = maxf(top, float(r["top_kmh"]))
		pull = maxf(pull, float(r["accel_max"]))
		dead += int(r["hard_stops"])
		if float(r["lat_max"]) > grip:
			grip = float(r["lat_max"])
			note = String(r["lat_at"])
			if grip > PLAYER_GRIP:
				worst = r["id"]
	out.append(_mark("honest_car", "Honest car", honest if not by_id.is_empty() else null,
			"top %.0f km/h (the car's %.0f), pull %.1f m/s² (%.0f), sideways %.1f m/s² (%.0f): %s; stopped dead by the game %d times (its brakes: %.0f m/s²)%s" % [
			top, PLAYER_TOP * 3.6, pull, PLAYER_ACCEL, grip, PLAYER_GRIP, note, dead, PLAYER_BRAKE, _by_draw(by_id, ["hard_stops"])], worst, traffic))

	# Route sense: the free choice against the forced routes.
	var sense_n := 0
	var sense_ok := 0
	worst = ""
	note = ""
	for free: Dictionary in by_id.values():
		if free.has("via"):
			continue
		var best := INF
		var best_name := ""
		for o: Dictionary in by_id.values():
			if o.has("via") and o["finished"] and String(o["id"]).get_slice("/via-", 0) == free["id"] and _run(o) < best:
				best = _run(o)
				best_name = o["via"]
		if best_name == "":
			continue
		sense_n += 1
		var text := "%s on %s roads: its own choice %s%.1f s, the best forced route (%s) %.1f s" % [
				free["start"], free["situation"], "" if free["finished"] else "never home, ", _run(free), best_name, best]
		if free["finished"] and _run(free) <= best * ROUTE_SENSE:
			sense_ok += 1
			if note == "":
				note = text
		elif worst == "":
			worst = free["id"]
			note = text
	out.append(_mark("route_sense", "Route sense", sense_ok == sense_n if sense_n > 0 else null,
			"%d of %d free choices within %d %% of the best forced route; %s" % [sense_ok, sense_n, roundi((ROUTE_SENSE - 1.0) * 100.0), note], worst, traffic))

	# The skill ladder: flat out on clear roads, rung by rung.
	var ladder := {}
	for r: Dictionary in by_id.values():
		if r["tuning"] == "ladder" and r["situation"] == "clear" and r["player"] == "none" and not r.has("via") and r["finished"] and int(r["seed"]) == 0 \
				and r["start"] != YARD_START and r["start"] != HOP_START:
			# (The yard course tests who knows the yard, not pace, and the hop course who dares
			# the wrong way: their own marks below.)
			if not ladder.has(r["start"]):
				ladder[r["start"]] = {}
			ladder[r["start"]][Ladder.rung_of(String(r["rival"]))] = r
	var ladder_n := 0
	var ladder_ok := true
	worst = ""
	note = ""
	for start: String in ladder:
		var rungs: Array = ladder[start].keys()
		if rungs.size() < 2:
			continue
		rungs.sort()
		ladder_n += 1
		var names := PackedStringArray()
		var out_of_order := 0
		for k in rungs.size():
			var r: Dictionary = ladder[start][rungs[k]]
			names.append("%s %.1f s" % [r["rival"], _run(r)])
			if k > 0 and _run(r) > _run(ladder[start][rungs[k - 1]]) * LADDER_ORDER:
				out_of_order += 1
		var spread: float = _run(ladder[start][rungs[0]]) / maxf(_run(ladder[start][rungs[rungs.size() - 1]]), 1.0) - 1.0
		note = "%s; the top rival %d %% faster than the first (at least %d %%), %d slower than the one below" % [", ".join(names), roundi(spread * 100.0), roundi(LADDER_SPREAD * 100.0), out_of_order]
		if out_of_order > 0 or spread < LADDER_SPREAD:
			ladder_ok = false
			worst = ladder[start][rungs[0]]["id"]
	out.append(_mark("skill_ladder", "Skill ladder", ladder_ok if ladder_n > 0 else null, "flat out on clear roads: " + note, worst))

	# The ladder's curve (racer AI step 6a): over the courses all six rungs drove, rung by rung.
	var curve_n := 0
	var curve_log := PackedFloat32Array()
	curve_log.resize(Ladder.RUNGS.size())
	for start: String in ladder:
		if ladder[start].size() < Ladder.RUNGS.size():
			continue
		curve_n += 1
		for k in Ladder.RUNGS.size():
			curve_log[k] += log(maxf(_run(ladder[start][k]), 1.0))
	var curve_ok := true
	var steps := PackedStringArray()
	worst = ""
	for k in range(1, Ladder.RUNGS.size()):
		if curve_n == 0:
			break
		var quicker := 1.0 - exp((curve_log[k] - curve_log[k - 1]) / curve_n)
		steps.append("%s %.1f %%" % [Ladder.RUNGS[k]["short"], quicker * 100.0])
		if quicker < CURVE_LEAST or quicker > CURVE_MOST:
			curve_ok = false
			if worst == "":
				worst = "%s/ladder" % Ladder.RUNGS[k]["id"]
	out.append(_mark("ladder_curve", "Ladder curve", curve_ok if curve_n > 0 else null,
			"each rung quicker than the one below, over %d courses on clear roads (%d to %d %%): %s" % [curve_n, roundi(CURVE_LEAST * 100.0), roundi(CURVE_MOST * 100.0), ", ".join(steps)], worst))

	# Told apart (step 6a): a rival's lights are its own. One that indicates (ladder.gd
	# `indicate`) has its indicator on into every turn it makes, one that never does (Seba) never
	# has; one that never flashes its headlights (`flash` 0) never does, behind however slow a
	# car; and every wrong turn is followed by the hazard lights.
	var told_n := 0
	var told_ok := true
	var turns_all := 0
	var turns_lit := 0
	var never_n := 0
	var never_lit := 0
	var wrong_n := 0
	var wrong_shown := 0
	var flashes := {}
	var over := {}
	var over_n := {}
	worst = ""
	for r: Dictionary in by_id.values():
		if not r.has("lights") or not r["finished"]:
			continue
		var traits: Dictionary = Ladder.FINAL_RACER if r["tuning"] == "final" else Ladder.racer(Ladder.rung_of(String(r["rival"])))
		var l: Dictionary = r["lights"]
		told_n += 1
		var bad := false
		if float(traits["indicate"]) > 0.0:
			turns_all += int(l["turns"])
			turns_lit += int(l["turns_lit"])
			bad = int(l["turns_lit"]) < int(l["turns"])
		else:
			never_n += 1
			never_lit += int(l["indications"])
			bad = int(l["indications"]) > 0
		flashes[r["rival"]] = int(flashes.get(r["rival"], 0)) + int(l["flashes"])
		over[r["rival"]] = int(over.get(r["rival"], 0)) + int(r.get("centre_passes", 0))
		over_n[r["rival"]] = int(over_n.get(r["rival"], 0)) + 1
		if float(traits["flash"]) <= 0.0 and int(l["flashes"]) > 0:
			bad = true
		wrong_n += int(r["wrong_turns"])
		wrong_shown += mini(int(l["hazards"]), int(r["wrong_turns"]))
		if int(l["hazards"]) < int(r["wrong_turns"]):
			bad = true
		if bad:
			told_ok = false
			if worst == "":
				worst = r["id"]
	var flash_names := PackedStringArray()
	for who: String in flashes:
		flash_names.append("%s %d" % [who, flashes[who]])
	flash_names.sort()
	# Read, not judged: how often each went out over the centre line depends on the traffic it
	# met (the careful ones, `dare` over 1, should go least).
	var over_names := PackedStringArray()
	for who: String in over:
		over_names.append("%s %d in %d races" % [who, over[who], over_n[who]])
	over_names.sort()
	out.append(_mark("told_apart", "Told apart", told_ok if told_n > 0 else null,
			"%d of %d turns indicated by the rivals who indicate; %d indications in %d races of the one who never does; headlight flashes: %s; %d of %d wrong turns followed by the hazard lights; passes over the centre line: %s" % [
			turns_lit, turns_all, never_lit, never_n, ", ".join(flash_names), wrong_shown, wrong_n, ", ".join(over_names)], worst))

	# The yard (racer AI step 5): on the course through a Wola yard, on clear roads, a rival who
	# knows every yard takes a race link and one who knows none goes round by the streets.
	var yard_n := 0
	var yard_ok := true
	var yard_names := PackedStringArray()
	worst = ""
	for r: Dictionary in by_id.values():
		if r["start"] != YARD_START or r["situation"] != "clear" or r["player"] != "none" or int(r["seed"]) != 0 or r.has("via"):
			continue
		var knows := float(Ladder.racer(Ladder.rung_of(String(r["rival"]))).get("yards", 0.0))
		if knows > 0.0 and knows < 1.0:
			continue
		yard_n += 1
		var took := int(r.get("links", 0))
		yard_names.append("%s %d (%.1f s)" % [r["rival"], took, _run(r)])
		if not r["finished"] or (took > 0) != (knows >= 1.0):
			yard_ok = false
			if worst == "":
				worst = r["id"]
	yard_names.sort()
	out.append(_mark("yard_links", "Yard links", yard_ok if yard_n > 0 else null,
			"race links taken on the yard course, clear roads (all yards known: at least one; none known: none): " + ", ".join(yard_names), worst))

	# The wrong-way hops (racer AI step 5b). On the hop course without the town's cars: on clear
	# roads a rival who dares takes a hop and one who does not takes none, and with a car parked
	# on the street the one who dares looks, refuses and still finishes. And in the races in
	# traffic (its own mark: it counts the town's cars) no car of the town's is on a street
	# while a racer hops it, or driven through there, and nobody hops who does not dare.
	var hop_n := 0
	var hop_ok := true
	var hop_names := PackedStringArray()
	var hop_races := 0
	var hop_safe := true
	var hop_taken := 0
	var hop_refused := 0
	var hop_met := 0
	var hop_hit := 0
	var hop_worst := ""
	worst = ""
	for r: Dictionary in by_id.values():
		var dares: bool = float(Ladder.racer(Ladder.rung_of(String(r["rival"]))).get("hops", 0.0)) >= 1.0 or r["tuning"] == "final"
		if _in_traffic(r):
			hop_races += 1
			hop_taken += int(r.get("hops", 0))
			hop_refused += int(r.get("hops_refused", 0))
			hop_met += int(r.get("hop_met", 0))
			hop_hit += int(r.get("hop_overlaps", 0))
			if int(r.get("hop_met", 0)) + int(r.get("hop_overlaps", 0)) > 0 or (int(r.get("hops", 0)) > 0 and not dares):
				hop_safe = false
				if hop_worst == "":
					hop_worst = r["id"]
			continue
		if r["start"] != HOP_START or r["player"] != "none" or r.has("via"):
			continue
		if r["situation"] == "parked":
			hop_n += 1
			hop_names.append("%s with a car parked there %d, refused %d (%.1f s)" % [r["rival"], int(r.get("hops", 0)), int(r.get("hops_refused", 0)), _run(r)])
			if not r["finished"] or int(r.get("hops", 0)) > 0 or (int(r.get("hops_refused", 0)) > 0) != dares:
				hop_ok = false
				if worst == "":
					worst = r["id"]
		elif r["situation"] == "clear":
			hop_n += 1
			hop_names.append("%s %d (%.1f s)" % [r["rival"], int(r.get("hops", 0)), _run(r)])
			if not r["finished"] or (int(r.get("hops", 0)) > 0) != dares or int(r.get("hops_refused", 0)) > 0:
				hop_ok = false
				if worst == "":
					worst = r["id"]
	hop_names.sort()
	out.append(_mark("wrong_way", "Wrong-way hops", hop_ok if hop_n > 0 else null,
			"hops taken on the hop course without the town's cars (who dares: at least one on clear roads, none and a refusal with a car parked on the street; the others: none): " + ", ".join(hop_names), worst))
	out.append(_mark("wrong_way_traffic", "Wrong-way hops in traffic", hop_safe if hop_races > 0 and hop_taken + hop_refused > 0 else null,
			"in %d races in traffic %d hops taken and %d refused (the street was not empty), %d of the town's cars met on a hopped street, %d driven through there" % [
			hop_races, hop_taken, hop_refused, hop_met, hop_hit], hop_worst, true))

	# The same race twice.
	var same := 0
	worst = ""
	for r: Dictionary in repeats:
		var o: Dictionary = by_id[r["id"]]
		if r["time"] == o["time"] and r["streets"] == o["streets"] and r["driven_m"] == o["driven_m"]:
			same += 1
		elif worst == "":
			worst = r["id"]
	out.append(_mark("same_twice", "Same race twice", same == repeats.size() if not repeats.is_empty() else null,
			"%d of %d repeated races came out the same" % [same, repeats.size()], worst))
	return out


## The race to hold r (a blocked street, a crash) against: the same group's race on clear roads
## with the same player, or with none, whichever finished ({}: neither).
static func _clear_of(g: Dictionary, r: Dictionary) -> Dictionary:
	for key: String in ["clear/%s" % r["player"], "clear/none"]:
		var base: Dictionary = g.get(key, {})
		if not base.is_empty() and base["finished"]:
			return base
	return {}


## A race's time once the rival is let go (the first race's wait at the line is not racing).
static func _run(r: Dictionary) -> float:
	return float(r["time"]) - float(r["hold_s"])


## Whether race r ran among the town's cars (its situation's Traffic level).
static func _in_traffic(r: Dictionary) -> bool:
	return int(SITUATIONS.get(r["situation"], {}).get("traffic", -1)) >= 0


## A count over the races in Busy traffic, draw by draw of the town's cars (the sum of `fields`
## in each draw that has DRAW_RACES races or more): "; in Busy traffic by draw 0: 52, 3: 48" or "".
static func _by_draw(by_id: Dictionary, fields: Array) -> String:
	var sums := {}
	var races := {}
	for r: Dictionary in by_id.values():
		if r["situation"] != "heavy":
			continue
		var draw := int(r["seed"])
		races[draw] = int(races.get(draw, 0)) + 1
		for f: String in fields:
			sums[draw] = int(sums.get(draw, 0)) + int(r[f])
	var keys: Array = races.keys()
	keys.sort()
	var parts := PackedStringArray()
	for draw: int in keys:
		if int(races[draw]) >= DRAW_RACES:
			parts.append("%d: %d" % [draw, int(sums.get(draw, 0))])
	return "; in Busy traffic by draw %s" % ", ".join(parts) if parts.size() > 1 else ""


## `traffic`: the mark counts races among the town's cars (another draw on another machine).
static func _mark(id: String, title: String, passed: Variant, value: String, worst: String, traffic := false) -> Dictionary:
	return {"id": id, "title": title, "pass": passed, "value": value if passed != null else "", "worst": worst if passed == false else "", "traffic": traffic}
