extends RefCounted
## Racer AI step 6b part 2 (docs/design/race-ai.md 6.3): the police chasers' way to the player, one
## object that police.gd and the race bench's `chase` races (game/tools/race_bench.gd) both drive,
## so the bench measures the rule the game chases by.
##
## - **The replan rule** (police.gd's since loop 3g-1): a chaser's route once REPLAN s, one chaser a
##   frame (those that asked first: a unit that has just started to pursue), to the end of the
##   player's street when that lies within GOAL_NEAR m of the car, else to the junction nearest the
##   car (`goal_of`; the street by `player_street`, police.gd's perception at 5 Hz), the search
##   bounded at MAX_COST m.
## - **The racers' driver** (`planned`): the chasers are the racers of one RaceSession
##   (race_session.gd) while the chase is on, with ladder.gd's POLICE profile: a plan by their own
##   seconds, the racing line, the arc a car can turn, honest braking, the reroutes after
##   `turned_back`. Their goal moves: only when the goal junction has changed is anything remade
##   (`RaceSession.retarget`: one search of the distances for all of them, a fresh plan each, the
##   Driver sent again); a plan is searched a slice a frame, one chaser's a frame (`round_robin`),
##   and until it knows the chaser's street the Driver goes by the metres. No effort by the gap
##   (a chaser's pace is its own: its top is the chase's, police.gd `chase_top`, by `v_cap`), no
##   race lights (its light bar), no finish circle.
## - Without `planned` (the race bench's `old`) a chaser is no racer of the session and is sent as
##   before step 6b: `race_to` by the metres, no plan, no line.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Ladder := preload("res://scripts/ladder.gd")
const RacePlanner := preload("res://scripts/race_planner.gd")
const RaceSession := preload("res://scripts/race_session.gd")

## A chaser's route: once REPLAN s, its search (the distances) bounded at MAX_COST m.
const MAX_COST := 800.0
const REPLAN := 1.0
## The goal is the end of the player's street while that end is within GOAL_NEAR m of the car.
const GOAL_NEAR := 400.0
## The player's street: the lane within SNAP m of the car, by its heading once it moves faster than
## SNAP_MOVING m/s.
const SNAP := 7.0
const SNAP_MOVING := 1.0

var graph: LaneGraph
## The traffic the chasers drive in (traffic.gd; untyped: check_police.gd chases on a stand-in).
var traffic
## The chase's race: its racers are the chasers on the racers' driver.
var session: RaceSession
## The chasers drive the racers' driver (false: the old driver, the race bench's `old`).
var planned := true
## The session's goal junction now (-1: none yet).
var goal := -1
## The replan rule's state: the chasers that asked (in order), and each one's last route (clock s).
var _asked: Array = []
var _last := {}
## A goal was remade or a chaser sent this frame (`send`, `join`): no plan slice in the same frame;
## and the chasers still to be sent to a new goal, one a frame (each send builds a racing line: a
## send and a slice were 1.5 to 4.3 ms and 2 to 3 ms on the cloud machine, together 5 to 6).
var _busy := false
var _resend: Array = []


## The map's lane graph, the traffic and a route planner for it (one per graph: its turns are
## worked out once and shared).
func setup(lane_graph: LaneGraph, traffic_node, race_planner: RacePlanner) -> void:
	graph = lane_graph
	traffic = traffic_node
	session = RaceSession.new()
	session.setup(graph, traffic, race_planner, null, {})
	session.round_robin = true
	session.max_cost = MAX_COST


## The player's street from where the car is (`p`), its heading `fwd` and its speed (m/s):
## LaneGraph.snap's [edge, lane, s, ...] or [] off the roads (police.gd `_track_player`).
static func player_street(lane_graph: LaneGraph, p: Vector2, fwd: Vector2, speed: float) -> Array:
	return lane_graph.snap(p, SNAP, fwd if speed > SNAP_MOVING else Vector2.ZERO)


## The junction a chaser is sent to: the end of the player's street `street` (-1: none) while it
## lies within GOAL_NEAR m of the car at `p`, else the junction nearest the car (-1: none).
static func goal_of(lane_graph: LaneGraph, street: int, p: Vector2) -> int:
	if street >= 0 and lane_graph.node_pos[lane_graph.e_b[street]].distance_to(p) < GOAL_NEAR:
		return lane_graph.e_b[street]
	return lane_graph.nearest_node(p)


## `key` (police.gd: a unit; the bench: a Driver) wants a route at once (it has just started to
## pursue, or to search).
func ask(key) -> void:
	if not key in _asked:
		_asked.append(key)


## `key` is gone (its car released).
func forget(key) -> void:
	_asked.erase(key)
	_last.erase(key)


## The replan rule: the one chaser to route this frame, or null. Those that asked first; else the
## first of `keys` (for which `chaser`, if given, is true) whose last route is REPLAN s old at
## `clock`. The caller routes it and says so (`routed`), unless its car cannot be routed now.
func next(keys: Array, clock: float, chaser := Callable()):
	if _asked.is_empty():
		for k in keys:
			if (not chaser.is_valid() or chaser.call(k)) and clock - float(_last.get(k, -99.0)) >= REPLAN:
				_asked.append(k)
				break
	if _asked.is_empty():
		return null
	return _asked.pop_front()


## `key` was routed at `clock`: its next route is REPLAN s later.
func routed(key, clock: float) -> void:
	_last[key] = clock


## Chaser Driver `d` starts to pursue (police_unit.gd `arm_chase`): with `planned`, a racer of the
## chase's session with the POLICE profile, top speed `top` (m/s) and pace `pace` (Ladder.pace's
## meaning), armed now; sent to the goal at once when there is one, else at its first route.
func join(d, top: float, pace: Vector2) -> void:
	if not planned or session.racer_of(d) != null:
		return
	var r := session.add(d, "police", Ladder.POLICE, pace, {"top": top, "cuts": false})
	r.stats = RaceSession.arm_racer(d, r.stats, r.pace, r.top, r.table, r.dice)
	if goal >= 0:
		d.goal = graph.node_pos[goal]
		session.start(r)
		_busy = true


## Chaser Driver `d` stops pursuing (another behaviour, or its car released): out of the session;
## a car still racing to the goal goes on there by the metres (no plan: no slice is searched for
## it any more).
func leave(d) -> void:
	if d == null:
		return
	var r := session.racer_of(d)
	if r == null:
		return
	session.remove(r)
	_resend.erase(r)
	if d.active and d.plan != null and not d.route.is_empty():
		traffic.race_to(d, d.finish, d.route)
	if session.racers.is_empty():
		goal = -1


## Sends chaser Driver `d` to junction `node` (the rule's goal, `goal_of`). On the racers' driver
## only a new goal remakes anything (all the chasers' distances and plans, `RaceSession.retarget`);
## the same goal again sends nothing (`race_to` resets the car's way). The old driver: the metres.
func send(d, node: int) -> void:
	var r := session.racer_of(d) if planned else null
	if r == null:
		d.goal = graph.node_pos[node]
		traffic.race_to(d, node, graph.distances_to(node, MAX_COST))
		return
	if node != goal:
		goal = node
		for o in session.racers:
			o.d.goal = graph.node_pos[node]
		# The chaser routed now first, the others in the frames after (`frame`).
		session.retarget(node, MAX_COST, false)
		_resend.clear()
		for o in session.racers:
			if o.started and o != r:
				_resend.append(o)
		if r.started:
			session.resend(r)
		_busy = true
	for o in session.racers:
		if not o.started:
			session.start(o)
			_busy = true


## Every frame: a chaser still to be sent to a new goal sent, or else a slice of one chaser's plan
## (`round_robin`); neither in a frame that remade a goal.
func frame() -> void:
	if _busy:
		_busy = false
		return
	while not _resend.is_empty():
		var r = _resend.pop_front()
		if r in session.racers:
			session.resend(r)
			return
	if goal >= 0 and not session.racers.is_empty():
		session.plan_tick(false)


## The traffic's `turned_back` / `hop_refused` for a chaser of the session (its metres left
## without the street it found blocked); null for another car.
func turned_back(d):
	return session.turned_back(d)


func hop_refused(d):
	return session.hop_refused(d)
