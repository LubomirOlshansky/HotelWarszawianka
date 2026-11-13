extends RefCounted
## One race's mechanics (racer AI step 6b, docs/design/race-ai.md 5 "RaceSession"): the course
## (the junctions to drive through in order, the last the finish, and the finish's circle), the
## racers on it (their traffic Drivers, their profiles, shortcuts, distances and plans), their
## effort and the order. No HUD, no cards, no words, no pay: whoever runs the race (rivals.gd for
## the ladder, the guided first race and the final "Trzy mosty"; the race bench,
## game/tools/race_bench.gd `race`) keeps those, and calls this in the order a race needs it, so
## the bench measures the code that races in the game.
##
## A race, in calls: `setup` once, `course`, `add` each racer, `distances` / `prepare_step` /
## `prepare` and `plan_tick` before the start (the searches spread over frames), `start` each
## racer, then every frame `advance` and `signals`, five times a second `rank`, the reroutes from
## the traffic's `turned_back` and `hop_refused`, and `end`.
##
## Step 6b part 1a moved the statics here from rivals.gd (`Pace`, `arm_racer`, `race_stats`,
## `pace_tick`, `effort_of`, `own_pace`, `home_at`, `remaining_from` and their constants): the
## race bench and the checks drive the same functions without the game.
##
## Step 6b part 1b: the night club's pack (street_meet.gd, the race bench's `pack`), eight racers
## on one course: `round_robin` (their plans one racer a frame), `home_within` (home that near the
## finish as well), the distances shared by racers who know the same shortcuts, and `signals`'
## `seen_only`. A one-racer race is the same as before.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Ladder := preload("res://scripts/ladder.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const RaceSignals := preload("res://scripts/race_signals.gd")

## The finish's circle (m on the ground), the same line for both cars.
const FINISH_RADIUS := 16.0
## On a road through the finish's circle a car is home level with the circle in whichever lane
## (`home_at`): this near one of that road's lanes (m), so on the road and not beside it.
const HOME_SNAP := 5.0
## Effort (docs/design/race-ai.md 6): the one thing left of "keeping the race close". A rival
## drives its own skill (ladder.gd: fixed for the race) times an effort that follows the TIME gap
## to the player and nothing else, never the player's speed: level with the player or just ahead
## it drives its own pace (1.0); leading by more than EASE_FROM s it starts to manage the lead,
## down to EFFORT_EASE of its pace from EASE_FULL s on; more than PUSH_FROM s behind it pushes,
## up to EFFORT_PUSH from PUSH_FULL s on (the corners harder too, traffic.gd, and PUSH_MISTAKES
## times its mistakes). So its whole time moves by about a tenth at most whatever the player does
## (the race bench's Independence mark allows 15 %), nobody waits, and nobody lifts off before
## the finish. The effort moves at most EFFORT_RATE a second (a driver settles into a pace).
const EFFORT_EASE := 0.9
const EFFORT_PUSH := 1.04
const EASE_FROM := 3.0
const EASE_FULL := 10.0
const PUSH_FROM := 1.0
const PUSH_FULL := 5.0
const EFFORT_RATE := 0.05
const PUSH_MISTAKES := 1.5
## The time gap is the metres between the cars over the rival's own usual speed: this share of
## its straight-line speed on a main road (a town route's bends and junctions; the bench's
## clear-road races average 0.8), so a rival's seconds are its own and not the player's.
const GAP_PACE := 0.8
## A plan made for another traffic than the town has now is made again (`plan_tick` when its
## caller allows it) once the two are further apart than this share of the larger one.
const PLAN_STALE := 0.2


## One race's pace memory: the route's length at the start, the rival's effort now (`effort_of`,
## settled at EFFORT_RATE), and its range for the race log.
class Pace:
	var route_total := 0.0
	var effort := 1.0
	var lo := 1.0
	var hi := 1.0


## One car in the race.
class Racer:
	## Its traffic Driver.
	var d
	## Its name, for the log and its shortcut dice (hash(name), as RaceCuts.links wants it).
	var name := ""
	## The racer stats it was added with (ladder.gd's keys), before easing; and the profile its
	## shortcuts come from (rivals.gd's rung's own, also on Halina's gentle day; the bench's the
	## rival's rung's, also in the final).
	var profile := {}
	var cuts_of := {}
	## The stats as armed (`profile` eased by `ease`): what its plans and its lights read.
	var stats := {}
	var ease := 0.0
	## [speed_factor, accel_factor] (Ladder.pace), the car's top speed (m/s) and its dice's seed.
	var pace := Vector2.ONE
	var top := 30.0
	var dice := 0
	## Whether it knows shortcuts at all (opts "cuts") and drives by a plan (opts "plan").
	var knows_cuts := true
	var planned := true
	## The street it will set off from (opts "from"; -1: its Driver's): its plan is searched
	## towards that one before the start, also while it has no Driver yet (step 6b part 1b: Darek
	## and Lena get theirs at the road, and their whole search fell on the start's frame).
	var from_e := -1
	## Its shortcuts (RaceCuts.links: [table, links into nodes]).
	var table := {}
	var cut_in := {}
	## Per leg: the distances to the leg's junction (PackedFloat32Array) and the plan
	## (RacePlanner.Plan), each made on demand and kept (null: not yet); and the metres of course
	## left after each leg (`prepare`).
	var dists: Array = []
	var plans: Array = []
	var after := PackedFloat32Array()
	## The leg it drives now, its effort and its lights.
	var leg := 0
	var effort := Pace.new()
	var sig := RaceSignals.State.new()
	## Metres of course left (5 Hz, `rank`), started, and once home: when and its place.
	var left := INF
	var started := false
	var home := false
	var home_t := 0.0
	var place := 0


var graph: LaneGraph
## The race's traffic (traffic.gd; untyped: check_street_meet.gd races on a stand-in).
var traffic
var planner: RacePlanner
var cuts: RaceCuts
## The course: the junctions in order (the last is the finish), the finish's ground point and
## circle (INF / 0: the junction alone) and the roads through it (RacePlanner.ends).
var legs := PackedInt32Array()
var at := Vector2.INF
var radius := 0.0
var ends := {}
## A racer on the last leg inside the finish's circle is home, as well as one that arrived
## (rivals.gd's ladder races and the bench; off for Trzy mosty, whose Seba is home on arriving).
var home_circle := true
## The metres left summed leg by leg at full precision (the race bench's way) instead of the
## driver's metres plus the leg's `after` (rivals.gd's, kept in 32 bits). One leg: the same.
var exact_left := false
## Step 6b part 1b, the pack: the racers' plans are searched one racer a frame (`plan_tick`: a
## slice of one plan, so eight racers cost a frame what one does), and a racer on the last leg
## with less than `home_within` m left is home too (0: off; street_meet.gd's 12 m, as before).
var round_robin := false
var home_within := 0.0
var _turn := 0
## The shortcut tables made for a cuts profile that every name knows alike (`_learn_cuts`).
var _links := {}
var racers: Array[Racer] = []
## Node -> the roads' own distances to it (the owner's cache, kept across races).
var _roads := {}


## The map's lane graph, the race's traffic, the map's planner and shortcuts, and the owner's
## cache of the roads' distances (`roads`: {node: PackedFloat32Array}, shared, may be empty).
func setup(lane_graph: LaneGraph, traffic_node, race_planner: RacePlanner, race_cuts: RaceCuts, roads := {}) -> void:
	graph = lane_graph
	traffic = traffic_node
	planner = race_planner
	cuts = race_cuts
	_roads = roads


## The junctions to drive through in order, the last the finish; with `finish_at` the finish is
## the circle of `circle` m round that ground point, for the last leg only (its plan ends on every
## road through it). Clears the racers.
func course(junctions: PackedInt32Array, finish_at := Vector2.INF, circle := 0.0) -> void:
	legs = junctions
	at = finish_at
	radius = circle
	ends = planner.ends(legs[legs.size() - 1], at, radius) if radius > 0.0 and at != Vector2.INF else {}
	racers.clear()


## A racer on Driver `d`: `name`, `profile` (ladder.gd's racer stats, before easing), `pace`
## (Ladder.pace). `opts`: "top" (the car's top speed, m/s; 30), "ease" (Ladder.ease_of; 0),
## "dice" (the seed of its own dice; 0), "cuts_of" (the profile its shortcuts come from; `profile`),
## "cuts": false (no shortcuts), "plan": false (no plan: the shortest way in metres).
func add(d, name: String, profile: Dictionary, pace: Vector2, opts := {}) -> Racer:
	var r := Racer.new()
	r.d = d
	r.name = name
	r.profile = profile
	r.cuts_of = opts.get("cuts_of", profile)
	r.ease = float(opts.get("ease", 0.0))
	r.stats = race_stats_of(profile, r.ease)
	r.pace = pace
	r.top = float(opts.get("top", 30.0))
	r.dice = int(opts.get("dice", 0))
	r.knows_cuts = bool(opts.get("cuts", true))
	r.planned = bool(opts.get("plan", true))
	r.from_e = int(opts.get("from", -1))
	if r.knows_cuts:
		_learn_cuts(r)
	r.dists.resize(legs.size())
	r.plans.resize(legs.size())
	racers.append(r)
	return r


## Racer `r`'s shortcuts from its `cuts_of` profile, without the hops along `no_hop` and the cuts
## onto the roads of `shut` (both {edge: true}; a plan's, after a refusal or a blocked street).
func _learn_cuts(r: Racer, no_hop := {}, shut := {}) -> void:
	var p := r.cuts_of
	# Step 6b part 1b: a profile that knows every cut and yard and dares no hop has the same
	# tables whatever its name (RaceCuts.knows ignores the dice at 1.0 and 0.0): made once for the
	# pack's eight (2 to 4 ms each) and shared; the tables are only read.
	var key := ""
	if no_hop.is_empty() and shut.is_empty() and float(p["cuts"]) >= 1.0 and float(p.get("yards", 0.0)) >= 1.0 and float(p.get("hops", 0.0)) <= 0.0:
		key = "%s/%s" % [p.get("narrow", 99.0), p.get("home", [])]
		if _links.has(key):
			r.table = _links[key][0]
			r.cut_in = _links[key][1]
			return
	var both := cuts.links(float(p["cuts"]), hash(r.name), float(p.get("yards", 0.0)), float(p.get("narrow", 99.0)), float(p.get("hops", 0.0)), no_hop, p.get("home", []), shut)
	r.table = both[0]
	r.cut_in = both[1]
	if key != "":
		_links[key] = both


## The roads' own distances to `node` (cached in the owner's `roads`).
func roads_to(node: int) -> PackedFloat32Array:
	if not _roads.has(node):
		_roads[node] = graph.distances_to(node)
	return _roads[node]


## Racer `r`'s distances to the junction of leg `leg`: with its shortcuts, and on the last leg of
## a finish with a circle the metres to where each road through it enters (RacePlanner.links);
## the roads' own when neither adds a way. Made once and kept for the race; another racer's when
## it knows the same shortcuts (the pack's locals: one search for all eight).
func distances(r: Racer, leg: int) -> PackedFloat32Array:
	if typeof(r.dists[leg]) == TYPE_NIL:
		for o in racers:
			if o != r and typeof(o.dists[leg]) != TYPE_NIL and o.cut_in == r.cut_in:
				r.dists[leg] = o.dists[leg]
				return r.dists[leg]
		var node := legs[leg]
		var extra := planner.links(node, ends if leg == legs.size() - 1 else {}, r.cut_in)
		r.dists[leg] = roads_to(node) if extra.is_empty() else graph.distances_to(node, INF, true, extra)
	return r.dists[leg]


## Racer `r`'s plan to leg `leg` (null with opts "plan": false): its own stats, its shortcuts and
## the town's traffic as it is at the moment it is made (the first time it is asked for).
func plan(r: Racer, leg: int) -> RacePlanner.Plan:
	if not r.planned:
		return null
	if r.plans[leg] == null:
		var last := leg == legs.size() - 1 and radius > 0.0 and at != Vector2.INF
		r.plans[leg] = planner.plan(legs[leg], r.stats, r.top, r.table, traffic.race_density(), PackedInt32Array(),
				at if last else Vector2.INF, radius if last else 0.0)
	return r.plans[leg]


## One missing distances array a call (about 8 ms each on the Linux container), the first racer's
## first; false when none is missing.
func prepare_step() -> bool:
	for r in racers:
		for j in legs.size():
			if typeof(r.dists[j]) == TYPE_NIL:
				distances(r, j)
				if _all_there(r):
					_sum_legs(r)
				return true
	return false


## Every racer's distances now, and the metres of course left after each leg.
func prepare() -> void:
	for r in racers:
		for j in legs.size():
			distances(r, j)
		if r.after.size() != legs.size():
			_sum_legs(r)


## Every racer's distances are there.
func ready() -> bool:
	for r in racers:
		if not _all_there(r):
			return false
	return true


func _all_there(r: Racer) -> bool:
	for j in legs.size():
		if typeof(r.dists[j]) == TYPE_NIL:
			return false
	return true


## The metres of course left after each leg (leg j runs from legs[j - 1] to legs[j]).
func _sum_legs(r: Racer) -> void:
	var n := legs.size()
	r.after.resize(n)
	r.after[n - 1] = 0.0
	for j in range(n - 2, -1, -1):
		r.after[j] = r.after[j + 1] + distances(r, j + 1)[legs[j]]


## A slice of each racer's plan a frame (Traffic.PLAN_SLICE states, 0.6 ms on a desktop) once its
## distances are there: the ways on from where it stands, and once those are settled the next
## leg's, whose start it has not reached (the whole search at the start, or at a junction of the
## course, would be one frame of 12 to 55 ms). With `may_remake` a plan made for another traffic
## than the town has now (the traffic setting, the quality's share or the governor moved it) is
## dropped and made again: only while there is time to search the new one before the start.
func plan_tick(may_remake: bool) -> void:
	if not ready():
		return
	if round_robin:
		_plan_round()
		return
	for r in racers:
		if not r.planned:
			continue
		if may_remake and r.plans[r.leg] != null and _stale(r.plans[r.leg]):
			r.plans.fill(null)
		if plan(r, r.leg).step(r.d.edge, Traffic.PLAN_SLICE) and r.leg + 1 < legs.size():
			plan(r, r.leg + 1).work(Traffic.PLAN_SLICE)


## `round_robin`: one slice of one racer's plan, the next racer's from the last one's on whose
## plan does not know the ways on from its street yet (before the start the street it sets off
## from, `from_e`, if given; a racer with neither, or home, waits). The search of a plan the racer
## drives already goes on through the race the same way.
func _plan_round() -> void:
	var n := racers.size()
	for i in n:
		var k := (_turn + i) % n
		var r := racers[k]
		if not r.planned or r.home:
			continue
		var e: int = r.from_e if not r.started and r.from_e >= 0 else (r.d.edge if r.d != null else -1)
		if e < 0:
			continue
		var p := plan(r, r.leg)
		if p.step(e, 0):
			continue
		p.step(e, Traffic.PLAN_SLICE)
		_turn = k + 1
		return


## Plan `p` was made for another traffic than the town has now (PLAN_STALE).
func _stale(p: RacePlanner.Plan) -> bool:
	var now: float = traffic.race_density()
	return absf(p.density - now) > PLAN_STALE * maxf(p.density, now)


## Racer `r` sets off: its Driver armed (`arm_racer`) and sent to its leg's junction.
func start(r: Racer) -> void:
	r.stats = arm_racer(r.d, r.stats, r.pace, r.top, r.table, r.dice)
	r.started = true
	traffic.race_to(r.d, legs[r.leg], distances(r, r.leg), plan(r, r.leg))


## Racer `r` on to its next leg (`advance` when it arrives; the bench's forced route by its own rule).
func next_leg(r: Racer) -> void:
	r.leg += 1
	traffic.race_to(r.d, legs[r.leg], distances(r, r.leg), plan(r, r.leg))


## Racer `r` has reached the end of its leg: its Driver arrived, or on the last leg with
## `home_circle` it is inside the finish's circle.
func arrived(r: Racer) -> bool:
	if r.d.arrived:
		return true
	if home_within > 0.0 and r.leg == legs.size() - 1 and traffic.remaining(r.d) < home_within:
		return true
	return home_circle and r.leg == legs.size() - 1 and radius > 0.0 \
			and Vector2(r.d.pos.x, r.d.pos.z).distance_to(at) < radius


## Every frame: a racer that arrived goes on to its next leg, or is home (at `now`, the race's
## clock, in the place it came).
func advance(now: float) -> void:
	for r in racers:
		if not r.started or r.home or not arrived(r):
			continue
		if r.leg < legs.size() - 1:
			next_leg(r)
		else:
			var homes := 0
			for o in racers:
				if o.home:
					homes += 1
			r.home = true
			r.home_t = now
			r.place = homes + 1


## The metres of course racer `r` has left (INF: not racing).
func metres_left(r: Racer) -> float:
	var left: float = traffic.remaining(r.d)
	if not exact_left:
		if r.after.size() != legs.size():
			_sum_legs(r)
		return left + r.after[r.leg]
	for k in range(r.leg, legs.size() - 1):
		left += distances(r, k + 1)[legs[k]]
	return left


## 5 times a second: each racing racer's metres left (`left`) and its effort (`pace_tick`) against
## the player's `player_left` metres (INF: no player).
func rank(player_left: float) -> void:
	for r in racers:
		if not r.started or r.home:
			continue
		r.left = metres_left(r)
		pace_tick(r.effort, r.d, float(r.stats.get("mistake", 0.0)), r.left, player_left)


## The place of a car with `metres` of course left: 1 + the racers home + those with less left.
func place_of(metres: float) -> int:
	var n := 1
	for r in racers:
		if r.home or (r.started and r.left < metres):
			n += 1
	return n


## The racer on Driver `d` (null: none).
func racer_of(d) -> Racer:
	for r in racers:
		if r.d == d:
			return r
	return null


## A racer found its street blocked and turns back (traffic.gd `turned_back`: its plan has shut
## the street): its shortcuts again without one onto the blocked street, and its metres left
## counted without that street (the plan's `no_hop` and `shut` both, or it ping-pongs back).
## The racer, or null when `d` is none racing with a plan.
func turned_back(d) -> Racer:
	var r := racer_of(d)
	if r == null or d.plan == null:
		return null
	if r.knows_cuts:
		_learn_cuts(r, d.plan.no_hop, d.plan.shut)
	_reroute(r)
	return r


## A racer found the one-way street of a wrong-way hop not empty and takes another way
## (traffic.gd `hop_refused`: its plan has dropped the hop): its metres left without that hop.
func hop_refused(d) -> Racer:
	var r := racer_of(d)
	if r == null or d.plan == null or not r.knows_cuts:
		return null
	_learn_cuts(r, d.plan.no_hop, d.plan.shut)
	_reroute(r)
	return r


func _reroute(r: Racer) -> void:
	var d = r.d
	traffic.reroute(d, graph.distances_to(d.finish, INF, true, planner.links(d.finish, d.plan.ends, r.cut_in, d.plan.shut), d.plan.shut))


## Every frame: the lights of each racer that races (race_signals.gd; the owner shows them); with
## `seen_only` only of those in view (the pack: a light nobody sees is not worked out).
func signals(dt: float, seen_only := false) -> void:
	for r in racers:
		if r.started and not r.home and (not seen_only or r.d.visible):
			RaceSignals.tick(r.sig, r.d, graph, r.stats, dt)


## The race is over: every racer out of racer mode on the traffic, its plans dropped.
func end() -> void:
	for r in racers:
		if r.d != null:
			traffic.stop_racing(r.d)
		r.plans.fill(null)


# --- the race core, static: the bench and the checks drive these without a session ----------------

## Effort (EFFORT_EASE above): how much of its own pace a rival drives when it leads the player
## by `lead_s` seconds (< 0: it is behind). 1.0 from PUSH_FROM s behind to EASE_FROM s ahead.
static func effort_of(lead_s: float) -> float:
	if lead_s >= 0.0:
		return lerpf(1.0, EFFORT_EASE, smoothstep(EASE_FROM, EASE_FULL, lead_s))
	return lerpf(1.0, EFFORT_PUSH, smoothstep(PUSH_FROM, PUSH_FULL, -lead_s))


## The rival's own usual speed (m/s) for the time gap (GAP_PACE above), from its car's top speed
## `top` (m/s) and its skill's share of the road's speed.
static func own_pace(top: float, share: float) -> float:
	return maxf(minf(top, Traffic.RACE_CLASS_TOP[0]) * share * GAP_PACE, 5.0)


## The racer stats of a race on rung `rung` (ladder.gd; Ladder.FINAL: the final's): in the guided
## first race (`first`) Halina's gentle ones, eased by `ease` (Ladder.ease_of: an easier rematch).
static func race_stats(rung: int, first := false, ease := 0.0) -> Dictionary:
	return race_stats_of(Ladder.FIRST_RACER if first else Ladder.racer(rung), ease)


## ... the same from a profile (ladder.gd's keys) itself.
static func race_stats_of(profile: Dictionary, ease := 0.0) -> Dictionary:
	return Ladder.eased(profile, ease)


## Racer mode on traffic driver `d` as a race starts: racer stats `stats` (`race_stats`), its pace
## `pace` ([speed_factor, accel_factor], Ladder.pace), `top` the player's car's top speed (m/s),
## `cuts` the shortcuts it knows (race_cuts.gd `links`), `dice` the seed of its own dice for this
## race (its wrong turns and mistakes: traffic.gd `race_rng`). Returns the stats.
static func arm_racer(d, stats: Dictionary, pace: Vector2, top: float, cuts: Dictionary, dice := 0) -> Dictionary:
	# Loop 3h slice 3: each rung's own pace (Halina 1.25 ... Mike 1.5; the final 1.45), was 1.45 flat.
	d.speed_factor = pace.x
	d.accel_factor = pace.y
	# Racer mode: the player's own car, and the skill that says how much of it this rival uses.
	d.race_top = top
	d.race_share = float(stats["share"])
	d.race_accel = float(stats["race_accel"])
	d.race_brake = float(stats["brake"])
	d.race_lat = float(stats["lat"])
	d.race_effort = 1.0
	d.race_corner = 1.0
	d.race_still = 0.0
	d.race_passes = 0
	# Human rivals: shortcuts, mistakes, wrong turns, blocking (ladder.gd's personality).
	d.cuts = cuts
	d.race_mistake = float(stats.get("mistake", 0.0))
	d.race_wrong = int(stats.get("wrong", 0))
	d.race_block = float(stats.get("block", 0.0))
	d.race_dare = float(stats.get("dare", 1.0))
	d.race_rng = RandomNumberGenerator.new()
	d.race_rng.seed = dice
	d.cuts_taken = 0
	d.links_taken = 0
	d.mistakes = 0
	d.wrong_turns = 0
	d.blocks = 0
	return stats


## 5 times a second, the rival's effort from the time gap (`effort_of`): sets `d.race_effort` (and
## returns it) from the metres of route the rival and the player have left (INF: unknown, as with
## no player: its own pace). `mistake` is the rival's own chance of a mistake at a corner (its
## stats'); a rival that pushes makes more. `pace` is this race's memory. Nothing here reads the
## player's speed, and the effort never takes the car past its own top speed: on a straight it
## is cut to 1 / share (`d.race_effort`), in a corner it is whole (`d.race_corner`: grip is the
## car's to use at any speed, so a rival at the road's full speed still pushes through the bends).
static func pace_tick(pace: Pace, d, mistake: float, rival_left: float, player_left: float) -> float:
	if pace.route_total <= 0.0 and player_left < INF:
		pace.route_total = maxf(player_left, rival_left)
	var want := 1.0
	if rival_left < INF and player_left < INF:
		want = effort_of((player_left - rival_left) / own_pace(d.race_top, d.race_share))
	pace.effort = move_toward(pace.effort, want, EFFORT_RATE * 0.2)
	var effort := minf(pace.effort, 1.0 / maxf(d.race_share, 0.01))
	d.race_effort = effort
	d.race_corner = pace.effort
	d.race_mistake = mistake * lerpf(1.0, PUSH_MISTAKES, clampf((pace.effort - 1.0) / (EFFORT_PUSH - 1.0), 0.0, 1.0))
	pace.lo = minf(pace.lo, effort)
	pace.hi = maxf(pace.hi, effort)
	return effort


## Whether a car at `p` has reached the finish at `goal`: inside its circle (FINISH_RADIUS m on the
## ground), or on a road that runs through the circle (`ends`, RacePlanner.ends), level with it in
## whichever lane. The finish line runs across the carriageway, for the player as for a rival
## (traffic.gd `race_to`): the outer lanes of a wide street pass the circle a lane or two out (at
## the Palace two of Emilii Plater's three), and a car in them has passed the finish all the same.
## On that road only: within HOME_SNAP m of one of its lanes and at its height, so not from the
## pavement beside it and not from the street under a bridge.
static func home_at(lane_graph: LaneGraph, p: Vector3, goal: Vector3, finish_ends: Dictionary) -> bool:
	var gap := Vector2(p.x - goal.x, p.z - goal.z).length()
	if gap < FINISH_RADIUS:
		return true
	if finish_ends.is_empty() or gap > FINISH_RADIUS + RacePlanner.END_REACH:
		return false
	var hit := lane_graph.snap(Vector2(p.x, p.z), HOME_SNAP)
	if hit.is_empty() or not finish_ends.has(hit[0]):
		return false
	var e: int = hit[0]
	var s: float = hit[2]
	return s >= finish_ends[e].x and s <= finish_ends[e].y and absf(p.y - lane_graph.height(e, s)) < RacePlanner.END_LEVEL


## The driving distance from ground point `p` to the node of `dist` (at `goal`): from the nearest
## lane (either direction of the road), or the straight line if `p` is off the roads. With `ends`
## (RacePlanner.ends: the roads through the finish's circle, `dist` made with their links) a road
## through the circle counts to where it enters.
static func remaining_from(lane_graph: LaneGraph, dist: PackedFloat32Array, p: Vector2, goal: Vector3, finish_ends := {}) -> float:
	var hit := lane_graph.snap(p, 25.0)
	if hit.is_empty():
		return p.distance_to(Vector2(goal.x, goal.z)) * 1.3
	var e: int = hit[0]
	var s: float = hit[2]
	var best := _metres_on(lane_graph, dist, e, s, finish_ends)
	var rev := lane_graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, _metres_on(lane_graph, dist, rev, lane_graph.e_len[e] - s, finish_ends) + 25.0)
	return best


## The metres from s on edge e to the finish of `dist`, or to where e enters the finish's circle.
static func _metres_on(lane_graph: LaneGraph, dist: PackedFloat32Array, e: int, s: float, finish_ends: Dictionary) -> float:
	if finish_ends.has(e) and s <= finish_ends[e].y:
		return maxf(finish_ends[e].x - s, 0.0)
	return lane_graph.remaining(dist, e, s)
