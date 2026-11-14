extends RefCounted
## Racer AI step 6b part 3 (docs/design/crazy-drivers.md 3, docs/design/race-ai.md 6.3): the crazy
## drivers' fares, one object that crazy_drivers.gd and the race bench's `crazy` races
## (game/tools/race_bench.gd) both drive, so the bench measures the rule the game drives by.
##
## - **A fare** (`_pick`): a junction FARE_NEAR to FARE_FAR m from the car as the crow flies, in the
##   strongly connected part of the roads (`node_scc`), out of the edge roadworks' band (where the
##   band of cars would put the car down at the barriers), roughly ahead of the car's heading (within
##   AHEAD rad), and whose way from the car's street does not start back the way it came; drawn by
##   the fares' own generator (`_rng`, FARE_SEED: traffic.gd's `_crazy_rng` and `_rng` never move for
##   it). At the fare (`arrived`) the next one is taken (picked a little before, NEXT_AT m out, so the
##   car does not stand at the old one); a fare it has not reached in FARE_LATE s, or one its metres
##   no longer reach, is dropped for a new one.
## - **The racers' driver**: each crazy driver is the one racer of its own RaceSession
##   (race_session.gd; one session with one goal does not fit drivers with their own goals), with
##   ladder.gd's CRAZY profile of its kind: a plan by its own seconds to the fare, the racing line,
##   honest braking, the reroutes after `turned_back` / `hop_refused`. Its top is traffic.gd
##   CRAZY_TOP, its cap over the road's limit CRAZY_OVER (traffic.gd, after the plan's speed). The
##   distances are bounded (MAX_COST m); a fare's distances are searched in one frame, the car is
##   sent in another, and a slice of one car's plan is searched a frame (`round_robin` across the
##   cars), never in a frame that searched or sent. No effort by the gap (no race), no lights (they
##   are town cars to the eye), no finish circle. Its shortcuts are its kind's, made once (`setup`).
## - Without `planned` (the race bench's `old`) nothing joins: a crazy driver wanders with racer
##   corners and no route, as before this step (traffic.gd keeps that path for one without a plan).

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Ladder := preload("res://scripts/ladder.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const RaceSession := preload("res://scripts/race_session.gd")

## A fare: FARE_NEAR to FARE_FAR m away as the crow flies, within AHEAD rad of the car's heading;
## up to TRIES junctions looked at a pick (the rest the frame after).
const FARE_NEAR := 600.0
const FARE_FAR := 1500.0
const AHEAD := 1.2
const TRIES := 40
## Dropped when not reached in FARE_LATE s.
const FARE_LATE := 240.0
## The distances to a fare searched no further than MAX_COST m.
const MAX_COST := 2000.0
## The next fare is picked once the car has less than NEXT_AT m to the one it drives to.
const NEXT_AT := 150.0
const FARE_SEED := 2031
## The shortcuts' curves and a race link's speeds are worked out ahead (RacePlanner `warm_link`):
## at `setup` (the city's load: about 110 ms for the three kinds on the cloud machine, the first
## time a planner is warmed), else a step at a time in a frame while it has spent less than
## WARM_USEC microseconds. The first time a plan met a long yard link it worked it out in one frame
## of its search (1.2 to 2.7 ms). The numbers are the same whenever they are worked out.
const WARM_USEC := 1000
## A slice of a plan's search a frame: SLICE states (traffic.gd PLAN_SLICE's 150 for a fresh plan
## were 3 to 8 ms on the cloud machine: the first look at each street works out its speed there).
const SLICE := 40


## One crazy driver's fares.
class Ride:
	var d
	var session: RaceSession
	## Its racer in the session (null until its first fare).
	var racer
	## The fare it drives to (-1: none yet) and since when (the route's clock, s).
	var fare := -1
	var since := 0.0
	## The next fare, picked before it reaches this one, and its distances.
	var next := -1
	var next_dist := PackedFloat32Array()
	## Fares reached.
	var reached := 0
	## Its fare is to be sent the next frame (searched this one).
	var to_send := false


var graph: LaneGraph
## The traffic the crazy drivers drive in (traffic.gd).
var traffic
var planner: RacePlanner
## The crazy drivers drive the racers' driver (false: as before, the race bench's `old`).
var planned := true
var rides: Array = []
## The route's clock (s; `frame`'s dt added up).
var clock := 0.0
## Fares reached and fares dropped (late or out of reach), all cars.
var reached := 0
var dropped := 0
## The script work of the last frame (microseconds; `frame`, and the joins and reroutes since the
## frame before).
var last_usec := 0
## -> void (text): a line for the log (crazy_drivers.gd's `--crazy-log`).
var log_line := Callable()
var _rng := RandomNumberGenerator.new()
## The junctions a fare may be at.
var _fares := PackedInt32Array()
## Each kind's shortcuts (RaceCuts.links: [table, links into nodes]), by `crazy`.
var _cuts := {}
var _turn := 0
## The shortcuts still to work out ahead: [edge, onto, grip, top] each (`_warm`).
var _warm_list: Array = []
var _usec := 0


## The map's lane graph, the traffic, a route planner for it and the city's shortcuts (null: none);
## with `warm` the shortcuts worked out now (WARM_USEC above), else over the first frames.
func setup(lane_graph: LaneGraph, traffic_node, race_planner: RacePlanner, race_cuts: RaceCuts, warm := true) -> void:
	graph = lane_graph
	traffic = traffic_node
	planner = race_planner
	_rng.seed = FARE_SEED
	_fares = PackedInt32Array()
	for n in graph.node_pos.size():
		if graph.node_scc[n] != 0 and not graph.in_works_band(graph.node_pos[n]):
			_fares.append(n)
	for k in range(1, Ladder.CRAZY.size() + 1):
		var p: Dictionary = Ladder.CRAZY[k - 1]
		_cuts[k] = race_cuts.links(float(p["cuts"]), hash(_name(k)), float(p["yards"]), float(p["narrow"]), float(p["hops"]), {}, p["home"]) \
				if race_cuts != null else [{}, {}]
		# Every shortcut state its plans can make: from each road into the node a cut leaves, at
		# the kind's grip and its plans' top on a link (Plan.speed's road speed under LINK_TOP).
		var table: Dictionary = _cuts[k][0]
		for a: int in table:
			var list: PackedFloat32Array = table[a]
			for i in range(0, list.size(), 2):
				for e in graph.node_in[a]:
					var road := maxf(minf(float(Traffic.CRAZY_TOP[k]), Traffic.RACE_CLASS_TOP[graph.e_class[e]]) * float(p["share"]), 1.0)
					_warm_list.append([e, int(list[i]), float(p["lat"]), minf(RaceCuts.LINK_TOP, road)])
	if warm:
		while not _warm_list.is_empty():
			_warm(Time.get_ticks_usec() + 1000000)


static func _name(kind: int) -> String:
	return "crazy%d" % kind


## The ride of Driver `d` (null: none).
func ride_of(d) -> Ride:
	for r: Ride in rides:
		if r.d == d:
			return r
	return null


## Traffic made a crazy driver (`crazy_spawned`): with `planned`, a ride of its own (its first fare
## is picked in a frame after).
func join(d) -> void:
	if not planned or d.crazy <= 0 or ride_of(d) != null:
		return
	var u0 := Time.get_ticks_usec()
	var r := Ride.new()
	r.d = d
	r.session = RaceSession.new()
	r.session.setup(graph, traffic, planner, null, {})
	r.session.round_robin = true
	r.session.max_cost = MAX_COST
	rides.append(r)
	_usec += Time.get_ticks_usec() - u0


## Traffic let a crazy driver go (`crazy_released`): its ride is over (its car is the pool's again,
## nothing is sent to it).
func leave(d) -> void:
	var r := ride_of(d)
	if r != null:
		rides.erase(r)


## Every frame (`dt` s): one heavy thing at most (a fare's distances, or a car sent to its fare),
## else a slice of one car's plan.
func frame(dt: float) -> void:
	var u0 := Time.get_ticks_usec()
	clock += dt
	_frame()
	_warm(u0)
	last_usec = Time.get_ticks_usec() - u0 + _usec
	_usec = 0


func _frame() -> void:
	if rides.is_empty():
		return
	for r: Ride in rides:
		if r.to_send:
			_send(r)
			return
	for r: Ride in rides:
		var d = r.d
		if not d.active:
			continue
		if r.fare < 0:
			if _fare_for(r):
				return
			continue
		if d.arrived:
			r.reached += 1
			reached += 1
			_say("%s at its fare (%d)" % [_name(d.crazy), r.reached])
			if r.next >= 0:
				_take_next(r)
				return
			if _fare_for(r):
				return
			continue
		var left: float = traffic.remaining(d)
		if clock - r.since > FARE_LATE or left == INF:
			dropped += 1
			_say("%s drops its fare (%s)" % [_name(d.crazy), "late" if left < INF else "out of reach"])
			r.next = -1
			if _fare_for(r):
				return
			continue
		if r.next < 0 and left < NEXT_AT:
			# The next fare, before this one is reached (its distances now, the send at the fare).
			var n := _pick(d, graph.node_pos[r.fare])
			if n >= 0:
				var dist := graph.distances_to(n, MAX_COST, true, planner.links(n, {}, r.racer.cut_in))
				if dist[r.fare] < INF:
					r.next = n
					r.next_dist = dist
			return
	# A slice of one car's plan, the next car's from the last one's on (round robin).
	var n := rides.size()
	for i in n:
		var k := (_turn + i) % n
		var r: Ride = rides[k]
		if r.racer == null or not r.racer.started or not r.d.active:
			continue
		var e: int = r.d.next_edge if r.d.in_conn else r.d.edge
		if e < 0:
			continue
		var p: RacePlanner.Plan = r.session.plan(r.racer, 0)
		if p == null or p.step(e, 0):
			continue
		p.step(e, SLICE)
		_turn = k + 1
		return


## Works the shortcuts out ahead (`_warm_list`) while this frame (begun at `u0`) has spent less than
## WARM_USEC.
func _warm(u0: int) -> void:
	while not _warm_list.is_empty() and Time.get_ticks_usec() - u0 < WARM_USEC:
		var w: Array = _warm_list[_warm_list.size() - 1]
		if planner.warm_link(w[0], w[1], w[2], w[3]):
			_warm_list.pop_back()


## A fare for ride `r`: picked, and its distances searched (as RaceSession `distances` searches a
## leg's: its kind's shortcuts, no further than MAX_COST m); the car is sent the frame after. A pick
## out of the metres' reach of its street, or whose way starts back the way it came, is let go and
## another drawn the next frame. True when it searched (the frame's heavy thing).
func _fare_for(r: Ride) -> bool:
	var d = r.d
	var street: int = d.next_edge if d.in_conn else d.edge
	if street < 0:
		return false
	var n := _pick(d, Vector2(d.pos.x, d.pos.z))
	if n < 0:
		return false
	var kind: int = d.crazy
	var dist := graph.distances_to(n, MAX_COST, true, planner.links(n, {}, _cuts[kind][1]))
	if dist[graph.e_b[street]] == INF or _first_back(street, dist):
		return true
	var s: RaceSession = r.session
	if r.racer == null:
		s.course(PackedInt32Array([n]))
		r.racer = s.add(d, _name(kind), Ladder.CRAZY[kind - 1], Vector2(d.speed_factor, d.accel_factor),
				{"top": Traffic.CRAZY_TOP[kind], "cuts": false, "dice": _rng.randi()})
		r.racer.table = _cuts[kind][0]
		r.racer.cut_in = _cuts[kind][1]
		r.racer.knows_cuts = not (r.racer.table as Dictionary).is_empty()
	else:
		s.retarget(n, MAX_COST, false)
	r.racer.dists[0] = dist
	r.fare = n
	r.next = -1
	r.to_send = true
	return true


## Ride `r` at its fare with the next one ready: sent there now (its distances were searched before).
func _take_next(r: Ride) -> void:
	r.session.retarget(r.next, MAX_COST, false)
	r.racer.dists[0] = r.next_dist
	r.fare = r.next
	r.next = -1
	r.next_dist = PackedFloat32Array()
	_send(r)


## Ride `r` sent to its fare: armed with its profile at its first, then by the fare's distances and
## a fresh plan (`race_to`: until the plan knows its street it goes by the metres).
func _send(r: Ride) -> void:
	r.to_send = false
	var d = r.d
	d.goal = graph.node_pos[r.fare]
	r.since = clock
	if not r.racer.started:
		r.session.start(r.racer)
	else:
		r.session.resend(r.racer)
	_say("%s takes a fare %.0f m off" % [_name(d.crazy), Vector2(d.pos.x, d.pos.z).distance_to(graph.node_pos[r.fare])])


## A fare for Driver `d` from ground point `from` (its place, or the fare it is about to reach): a
## junction of `_fares` FARE_NEAR to FARE_FAR m away within AHEAD rad of its heading; -1 when none
## of TRIES drawn fits.
func _pick(d, from: Vector2) -> int:
	if _fares.is_empty():
		return -1
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	for t in TRIES:
		var n: int = _fares[_rng.randi() % _fares.size()]
		var to: Vector2 = graph.node_pos[n] - from
		var far := to.length()
		if far < FARE_NEAR or far > FARE_FAR:
			continue
		if absf(fwd.angle_to(to)) > AHEAD:
			continue
		return n
	return -1


## The way to the fare by the metres of `dist` starts back the way the car came: the best way on
## from the end of `street` is its reverse.
func _first_back(street: int, dist: PackedFloat32Array) -> bool:
	var rev := graph.e_reverse[street]
	if rev < 0:
		return false
	var best := -1
	var best_d := INF
	for f in graph.node_out[graph.e_b[street]]:
		var c: float = graph.e_len[f] + dist[graph.e_b[f]]
		if c < best_d:
			best_d = c
			best = f
	return best == rev


## The traffic's `turned_back` / `hop_refused` for a crazy driver on a ride (its metres left
## without the street it found blocked); null for another car.
func turned_back(d):
	var u0 := Time.get_ticks_usec()
	var r := ride_of(d)
	var out = r.session.turned_back(d) if r != null and r.racer != null else null
	_usec += Time.get_ticks_usec() - u0
	return out


func hop_refused(d):
	var u0 := Time.get_ticks_usec()
	var r := ride_of(d)
	var out = r.session.hop_refused(d) if r != null and r.racer != null else null
	_usec += Time.get_ticks_usec() - u0
	return out


func _say(text: String) -> void:
	if log_line.is_valid():
		log_line.call(text)
