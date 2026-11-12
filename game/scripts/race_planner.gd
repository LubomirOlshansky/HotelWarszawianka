extends RefCounted
## RacePlanner (docs/design/race-ai.md 5, step 3 of the racer AI rebuild; F 2026-11-09, the
## friend's point 3: "choose routes by expected arrival time: route score = driving time +
## traffic delay + risk penalty"): which streets a racer takes, by the seconds they cost THIS
## racer. Before, every rival took the shortest way in metres, fixed at the start, so all six
## drove the same streets and nobody reacted to a blocked one.
##
## A `Plan` is one search backwards from the finish over the lane graph's turns. A state is "at
## the end of edge e, taking way on o": o is a road out of the junction ahead, or a shortcut the
## racer knows (race_cuts.gd) with the road it joins. A state's time is the seconds from there
## to the finish, built from what traffic.gd's racer does with the racer's own numbers
## (ladder.gd): the junction's curve at the speed its grip gives it (`lat`), the next street from
## that speed up to its share of the road's racing speed (`share`, `race_accel`) and down again
## to its next corner's speed (`brake`), a little for each traffic light it runs, the traffic
## delay it expects there (`knows`: how much of the town's traffic it counts), and the risk of a
## street with no way past a stopped car, weighed by its `caution`. Two rivals with different
## numbers get different tables from the same map, and so different streets.
##
## The racer asks its plan at every junction (`choose`), so a wrong turn or a shove costs
## nothing to plan: the table already holds the time from wherever it is. A street found blocked
## is told to the plan (`block`), which searches again without it. A racer holds the way it has
## chosen on a street unless another saves SWITCH_GAIN s (it does not dither).
##
## A race's finish is not a junction but a circle on the ground (rivals.gd FINISH_RADIUS round the
## finish's point: whoever is inside is home), and a road that only passes the finish's junction
## can run through it: the other carriageway of the same street, the main road beside the end of
## a side road. A plan made with the circle (`plan`'s `at` and `radius`) ends on those roads too,
## where each one enters it (`ends`); made to the junction alone, Halina's plan to the Palace gave
## the race 101 s by a way that missed the circle, where the way through it took her 66 s.
##
## The planner itself (this script's instance) is one per lane graph: the turns' geometry, worked
## out once per turn the first time a plan asks, and shared by every plan.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const RaceCuts := preload("res://scripts/race_cuts.gd")

## A racer keeps the way on it has chosen for its street unless another is this much quicker (s).
const SWITCH_GAIN := 3.0
## The pull the clock counts with, as a share of the racer's `race_accel`: traffic.gd's racer
## pulls a x (1 - (v / v0)^4), which loses about a third more time on the way up to speed than a
## steady pull (0.75: fitted on the race bench's clear races, `clock` in its lines).
const PULL := 0.75
## A light run on red: within Traffic.RACE_RED_LOOK m of the line the racer holds
## Traffic.RACE_RED_SLOW of its speed (at least RED_FLOOR m/s), and about RED_SHARE of the lights
## it meets show red.
const RED_SHARE := 0.5
const RED_FLOOR := Traffic.SIREN_SLOW * 1.4
## The search stops this many seconds past the time of the state it was asked for (the rest of the
## map stays unknown until a racer strays there: `choose` searches on).
const REACH := 45.0
## A junction's ways on are final once the search is this many seconds past the best of them.
const KNOWN := 12.0
## A wrong turn (a racer who does not know the town: traffic.gd `race_wrong`) is a road that costs
## this many seconds over its best way on: a mistake that shows, and never a hopeless one. (The
## next best road, which the metres rule took, costs a racer with a plan a second or less: on the
## race bench Słoik lost nothing by his wrong turn, and came home in front of Bartek.)
const WRONG_LEAST := 4.0
const WRONG_MOST := 15.0
## The finish's circle (`ends`): a road runs through it when one of its lanes comes END_MARGIN m
## inside (a lane that only grazes the edge is nobody's finish), on the finish's own level (within
## END_LEVEL m: not the viaduct over it or the street under it). Its lanes are looked at every
## END_STEP m, and no lane lies further than END_REACH m from its road's centre line.
const END_MARGIN := 1.0
const END_LEVEL := 3.0
const END_STEP := 0.5
const END_REACH := 14.0

var graph: LaneGraph
## Per edge: its first state (state = first[e] + k: at the end of e, taking its k-th road out).
var first := PackedInt32Array()
## Per edge: its place among the roads out of the node it starts at.
var slot := PackedInt32Array()
## Per road state: the edge it is at the end of, and the edge it takes.
var state_edge := PackedInt32Array()
var state_next := PackedInt32Array()
## Road states in all (a plan's shortcut states come after them).
var states := 0
## Per road state: the junction curve's length (m) and how far it turns (rad); NAN until asked.
var _curve := PackedFloat32Array()
var _turn := PackedFloat32Array()
## The roads through each finish's circle, worked out once ({Vector4(node, x, z, radius): `ends`}),
## and what a plan to a junction alone has of them: none.
var _ends := {}
var _no_ends := {}


func _init(lane_graph: LaneGraph) -> void:
	graph = lane_graph
	var edges := graph.e_a.size()
	first.resize(edges)
	slot.resize(edges)
	for n in graph.node_out.size():
		var outs := graph.node_out[n]
		for k in outs.size():
			slot[outs[k]] = k
	for e in edges:
		first[e] = states
		for f in graph.node_out[graph.e_b[e]]:
			state_edge.append(e)
			state_next.append(f)
			states += 1
	_curve.resize(states)
	_curve.fill(NAN)
	_turn.resize(states)
	_turn.fill(0.0)


## The junction curve of road state y: [the metres a racer drives through it (traffic.gd
## `race_turn_length`: the arc a car can turn where the curve is tighter), how far it turns (rad)].
func curve(y: int) -> Vector2:
	if is_nan(_curve[y]):
		var e := state_edge[y]
		var f := state_next[y]
		_turn[y] = absf(graph.direction(e, graph.e_s1[e]).angle_to(graph.direction(f, graph.e_s0[f])))
		_curve[y] = Traffic.race_turn_length(LaneGraph.bezier_length(graph.connector(e, 0, f, graph.next_lane(e, 0, f))), _turn[y])
	return Vector2(_curve[y], _turn[y])


## A plan to graph node `finish` for a racer with `stats` (ladder.gd's racer stats: share,
## race_accel, brake, lat; knows and caution when it has them) in a car of top speed `top` (m/s),
## knowing the shortcuts `cuts` (race_cuts.gd `links`' table), with the town's traffic at
## `density` (traffic.gd's; 0: none on the road), and the edges of `shut` closed to it. With
## `radius` (m) the finish is the circle of that size round ground point `at`, and the plan ends
## on every road through it (`ends`); without, at the junction alone (a leg of the final, whose
## checkpoints the rival takes at their junctions).
func plan(finish: int, stats: Dictionary, top: float, cuts := {}, density := 0.0, shut := PackedInt32Array(),
		at := Vector2.INF, radius := 0.0) -> Plan:
	var p := Plan.new()
	p.planner = self
	p.graph = graph
	p._roads = states
	p._first = first
	p._slot = slot
	p._state_edge = state_edge
	p._state_next = state_next
	p._node_in = graph.node_in
	p._e_a = graph.e_a
	p._e_s0 = graph.e_s0
	p._e_s1 = graph.e_s1
	p.finish = finish
	p.top = top
	p.share = float(stats.get("share", 1.0))
	p.accel = maxf(float(stats.get("race_accel", 10.0)) * PULL, 0.5)
	p.brake = maxf(float(stats.get("brake", 0.0)), 0.0)
	if p.brake <= 0.0:
		p.brake = Traffic.RACE_DECEL * 0.7
	p.lat = maxf(float(stats.get("lat", 7.0)), 0.5)
	p.knows = clampf(float(stats.get("knows", 1.0)), 0.0, 1.0)
	p.caution = maxf(float(stats.get("caution", 0.5)), 0.0)
	p.density = maxf(density, 0.0)
	p.cuts = cuts
	p.ends = ends(finish, at, radius) if radius > 0.0 and at != Vector2.INF else _no_ends
	for e in shut:
		p.shut[e] = true
	p.restart()
	return p


## The roads through the finish's circle (`radius` m round ground point `at`; the finish's
## junction is node `finish`), other than the roads of that junction itself (a road into it ends
## at the finish, and one out of it starts inside the circle, where a racer has arrived already):
## {edge: Vector2(the s where it enters the circle, the s where it leaves)}, by the edge's lanes
## that run through it. A racer on one of them is home where it enters, in whichever of its lanes
## (traffic.gd `arrived`), as it is at the end of a road into the junction: the finish line runs
## across the carriageway. Worked out once per finish.
func ends(finish: int, at: Vector2, radius: float) -> Dictionary:
	var key := Vector4(finish, at.x, at.y, radius)
	if _ends.has(key):
		return _ends[key]
	var out := {}
	_ends[key] = out
	# The finish's own level: where a road into its junction (or out of it) ends.
	var level := 0.0
	if not graph.node_in[finish].is_empty():
		var f := graph.node_in[finish][0]
		level = graph.height(f, graph.e_s1[f])
	elif not graph.node_out[finish].is_empty():
		var f := graph.node_out[finish][0]
		level = graph.height(f, graph.e_s0[f])
	var seen := {}
	var box := radius + END_REACH
	for cx in range(floori((at.x - box) / LaneGraph.CELL), floori((at.x + box) / LaneGraph.CELL) + 1):
		for cz in range(floori((at.y - box) / LaneGraph.CELL), floori((at.y + box) / LaneGraph.CELL) + 1):
			var cell := LaneGraph.cell_key(Vector2(cx + 0.5, cz + 0.5) * LaneGraph.CELL)
			if not graph.grid.has(cell):
				continue
			for e: int in graph.grid[cell]:
				if seen.has(e) or graph.e_b[e] == finish or graph.e_a[e] == finish:
					continue
				seen[e] = true
				var stretch := _inside(e, at, radius, level)
				if stretch.x <= stretch.y:
					out[e] = stretch
	return out


## The stretch of edge e inside the circle of `radius` m round `at` (see `ends`): Vector2(from, to)
## along it, or (INF, -INF) when none of its lanes runs through or the road is on another level
## than `level` (m).
func _inside(e: int, at: Vector2, radius: float, level: float) -> Vector2:
	var none := Vector2(INF, -INF)
	var s0 := graph.e_s0[e]
	var s1 := graph.e_s1[e]
	if s1 <= s0:
		return none
	var near := clampf(graph.project(e, at), s0, s1)
	var width := maxf(absf(graph.lane_offset(e, 0)), absf(graph.lane_offset(e, graph.e_lanes[e] - 1)))
	if graph.point_at(e, near).distance_to(at) > radius + width + 1.0 or absf(graph.height(e, near) - level) > END_LEVEL:
		return none
	var out := none
	for k in graph.e_lanes[e]:
		var off := graph.lane_offset(e, k)
		var reach := radius + absf(off) + 2.0
		var first_s := maxf(s0, near - reach)
		var last_s := minf(s1, near + reach)
		var from := INF
		var to := -INF
		var closest := INF
		for i in maxi(ceili((last_s - first_s) / END_STEP), 1) + 1:
			var s := minf(first_s + i * END_STEP, last_s)
			var dd := graph.point_at(e, s, off).distance_to(at)
			closest = minf(closest, dd)
			if dd < radius:
				if from == INF:
					from = s
				to = s
			elif from != INF:
				break
		if closest < radius - END_MARGIN:
			out = Vector2(minf(out.x, from), maxf(out.y, to))
	return out


## `extra_in` (LaneGraph.distances_to's links into a node: a racer's shortcuts) with `roads` (the
## `ends` of the finish at node `finish`) added, for the metres to a finish that is a circle: from
## each road's start it is the metres to where the road enters, not on to the junction and round.
## The roads of `shut` are left out. (`extra_in` itself when there is nothing to add.)
func links(finish: int, roads: Dictionary, extra_in := {}, shut := {}) -> Dictionary:
	var list := PackedFloat32Array()
	for f: int in roads:
		if not shut.has(f) and graph.e_shut[f] == INF:
			list.append(graph.e_a[f])
			list.append(roads[f].x)
	if list.is_empty():
		return extra_in
	var out := extra_in.duplicate()
	if out.has(finish):
		var both: PackedFloat32Array = out[finish]
		list = both + list
	out[finish] = list
	return out


## One racer's table of times to one finish (see the top of this script).
class Plan:
	extends RefCounted

	var planner
	var graph: LaneGraph
	var finish := -1
	## The racer: the car's top speed (m/s), the share of a road's racing speed it holds, its pull
	## (already x PULL) and brakes (m/s²), its grip in a corner (m/s²), how much of the town's
	## traffic it counts on (0-1) and how it weighs a risky street.
	var top := 30.0
	var share := 1.0
	var accel := 7.5
	var brake := 7.0
	var lat := 8.0
	var knows := 1.0
	var caution := 0.5
	## The town's traffic (traffic.gd `density`; 0: none).
	var density := 0.0
	## The shortcuts it knows ({node: [edge on, metres, ...]}) and the edges closed to it.
	var cuts := {}
	var shut := {}
	## The roads through the finish's circle (RacePlanner.ends: {edge: Vector2(the s it enters at,
	## the s it leaves at)}; none: the finish is the junction alone).
	var ends := {}
	## Searches run (the first, and one for each `block`), and states settled by the last.
	var searches := 0
	var settled := 0
	## The planner's and the graph's arrays (shared, not copied), and the road states' count.
	var _roads := 0
	var _first: PackedInt32Array
	var _slot: PackedInt32Array
	var _state_edge: PackedInt32Array
	var _state_next: PackedInt32Array
	var _node_in: Array[PackedInt32Array]
	var _e_a: PackedInt32Array
	var _e_s0: PackedFloat32Array
	var _e_s1: PackedFloat32Array
	## Per state: seconds to the finish (INF: not reached), and whether that is final.
	var _time := PackedFloat32Array()
	var _done := PackedByteArray()
	var _heap_t := PackedFloat32Array()
	var _heap_y := PackedInt32Array()
	## Per state, kept from search to search (a closed street changes neither): the speed through
	## its curve (m/s; 0: not worked out yet) and the seconds the curve takes.
	var _thru := PackedFloat32Array()
	var _cross := PackedFloat32Array()
	## Per edge: the speed the racer holds along it (0: not worked out yet), the seconds its
	## lights and its risk add, and where the finish is on it (0: nowhere, 1: at its end, 2: where
	## it runs through the finish's circle, `ends`).
	var _speed := PackedFloat32Array()
	var _extra := PackedFloat32Array()
	var _last := PackedByteArray()
	## The shortcut states (ids from `_roads` on): {edge at << 16 | edge on: id} and each one's edge.
	var _cut_id := {}
	var _cut_e := PackedInt32Array()
	## {edge on: [node the shortcut leaves, ...]}: the shortcuts that join each edge.
	var _cut_into := {}
	## The last `choose`: its way on's time, and the road a wrong turn would take there with its
	## time (-1: none: no road out costs WRONG_LEAST to WRONG_MOST s more).
	var chosen_time := INF
	var wrong := -1
	var wrong_time := INF
	var chosen_cut := false

	## Starts the search again from the finish (after `shut` changed).
	func restart() -> void:
		searches += 1
		settled = 0
		if _thru.is_empty():
			_thru.resize(_roads)
			_thru.fill(0.0)
			_cross.resize(_roads)
			_cross.fill(0.0)
			var edges := _e_a.size()
			_speed.resize(edges)
			_speed.fill(0.0)
			_extra.resize(edges)
			_extra.fill(0.0)
			_last.resize(edges)
			for a: int in cuts:
				var list: PackedFloat32Array = cuts[a]
				for k in range(0, list.size(), 2):
					var g := int(list[k])
					if not _cut_into.has(g):
						_cut_into[g] = PackedInt32Array()
					if not a in _cut_into[g]:
						_cut_into[g].append(a)
		_time.resize(_thru.size())
		_time.fill(INF)
		_done.resize(_thru.size())
		_done.fill(0)
		_heap_t.clear()
		_heap_y.clear()
		_last.fill(0)
		for f in _node_in[finish]:
			if shut.has(f) or graph.e_shut[f] < INF:
				continue
			_last[f] = 1
			_into(f, speed(f), 0.0)
		for f: int in ends:
			if shut.has(f) or graph.e_shut[f] < INF:
				continue
			_last[f] = 2
			_into(f, speed(f), 0.0, maxf(ends[f].x - _e_s0[f], 0.0))

	## The speed (m/s) the racer holds along edge f: its share of the road's racing speed.
	func speed(f: int) -> float:
		var v := _speed[f]
		if v <= 0.0:
			v = maxf(minf(top, Traffic.RACE_CLASS_TOP[graph.e_class[f]]) * share, 1.0)
			_speed[f] = v
			# Each light on the way: run on red about half the time, a little slower.
			var slow := maxf(RED_FLOOR, v * Traffic.RACE_RED_SLOW)
			var extra := 0.0
			if slow < v:
				extra = RED_SHARE * Traffic.RACE_RED_LOOK * (1.0 / slow - 1.0 / v) * (graph.e_stops[f].size() / 3)
			# The town's traffic, as far as the racer knows it, and the risk of a street with no
			# way past as it weighs that (Traffic.race_delay).
			if density > 0.0 and knows > 0.0:
				extra += knows * Traffic.race_delay(graph, f, v, density, caution)
			_extra[f] = extra
		return v

	## The speed (m/s) through the curve of state y (worked out, with the curve's seconds, the
	## first time): a junction's curve by the racer's grip; a U-turn (the way back, or a hairpin
	## onto another road: Traffic.RACE_HAIRPIN) at Traffic.UTURN_SPEED.
	func _through(y: int) -> float:
		var c := _thru[y]
		if c > 0.0:
			return c
		var e := _state_edge[y]
		var bend: Vector2 = planner.curve(y)
		if _state_next[y] == graph.e_reverse[e] or bend.y > Traffic.RACE_HAIRPIN:
			c = minf(Traffic.UTURN_SPEED, speed(e))
		else:
			c = minf(Traffic.race_turn_speed(bend.x, bend.y, lat), speed(e))
		_thru[y] = c
		_cross[y] = bend.x / c
		return c

	## Seconds along `length` m of a street held at `v`, coming in at `u` and leaving at `w` (m/s).
	func _street(length: float, u: float, w: float, v: float) -> float:
		u = minf(u, v)
		w = minf(w, v)
		if length <= 0.0:
			return 0.0
		var up := (v * v - u * u) / (2.0 * accel)
		var down := (v * v - w * w) / (2.0 * brake)
		if up + down <= length:
			return (v - u) / accel + (v - w) / brake + (length - up - down) / v
		# Too short to reach its speed: up to a peak and down again.
		var peak := sqrt((2.0 * accel * brake * length + brake * u * u + accel * w * w) / (accel + brake))
		if peak >= u and peak >= w:
			return (peak - u) / accel + (peak - w) / brake
		return 2.0 * length / maxf(u + w, 1.0)

	## A state at the end of edge f is settled (or f ends at the finish): every way INTO f gets its
	## time: through its curve, along f leaving at `w` m/s, and `t` s from f's end. With `part` the
	## way along f is that many metres only (to where f enters the finish's circle), and its lights
	## and traffic count by the same share. (The search's inner loop: `_street` and the heap's push
	## are written out here, a call each costs as much as the sums.)
	func _into(f: int, w: float, t: float, part := -1.0) -> void:
		var v := _speed[f]
		if v <= 0.0:
			v = speed(f)
		var length := _e_s1[f] - _e_s0[f]
		var base := t + _extra[f]
		if part >= 0.0:
			base = t + _extra[f] * part / maxf(length, 0.01)
			length = part
		var a := accel
		var b := brake
		if w > v:
			w = v
		var down := (v * v - w * w) / (2.0 * b)
		var tail := (v - w) / b
		var back := _slot[f]
		var ins := _node_in[_e_a[f]]
		var n := ins.size()
		var cut_from: PackedInt32Array
		var cut_k := -1
		if not _cut_into.is_empty() and _cut_into.has(f):
			cut_from = _cut_into[f]
			cut_k = 0
		var i := 0
		while true:
			var y := -1
			if i < n:
				y = _first[ins[i]] + back
				i += 1
			elif cut_k >= 0:
				# The shortcuts that join f: from each edge that ends where one leaves.
				if cut_k >= cut_from.size():
					break
				ins = _node_in[cut_from[cut_k]]
				cut_k += 1
				for p in ins:
					_relax(_cut_state(p, f), length, v, w, down, tail, base)
				continue
			else:
				break
			if _done[y] == 1:
				continue
			var u := _thru[y]
			if u <= 0.0:
				u = _through(y)
			var cand := _cross[y] + base
			if u > v:
				u = v
			var up := (v * v - u * u) / (2.0 * a)
			if up + down <= length:
				cand += (v - u) / a + tail + (length - up - down) / v
			else:
				var peak := sqrt((2.0 * a * b * length + b * u * u + a * w * w) / (a + b))
				if peak >= u and peak >= w:
					cand += (peak - u) / a + (peak - w) / b
				else:
					cand += 2.0 * length / maxf(u + w, 1.0)
			if cand < _time[y]:
				_time[y] = cand
				var h := _heap_t.size()
				_heap_t.append(cand)
				_heap_y.append(y)
				while h > 0:
					var q := (h - 1) >> 1
					if _heap_t[q] <= cand:
						break
					_heap_t[h] = _heap_t[q]
					_heap_y[h] = _heap_y[q]
					h = q
				_heap_t[h] = cand
				_heap_y[h] = y

	## `_into` for one shortcut state y (few of them: by the calls).
	func _relax(y: int, length: float, v: float, w: float, down: float, tail: float, base: float) -> void:
		if y < 0 or _done[y] == 1:
			return
		var u := minf(_thru[y], v)
		var cand := _cross[y] + base
		var up := (v * v - u * u) / (2.0 * accel)
		if up + down <= length:
			cand += (v - u) / accel + tail + (length - up - down) / v
		else:
			cand += _street(length, u, w, v)
		if cand < _time[y]:
			_time[y] = cand
			graph._heap_push(_heap_t, _heap_y, cand, y)

	## The state "at the end of edge e, over the shortcut that joins edge g" (made the first time):
	## the curve traffic.gd `_cut_to` drives, at its speed, a metre of it counted as RaceCuts.COST
	## metres with RaceCuts.GAIN m on top (what a shortcut must save to be worth taking).
	func _cut_state(e: int, g: int) -> int:
		var key := (e << 16) | g
		if _cut_id.has(key):
			return _cut_id[key]
		var p0 := graph.point_at(e, graph.e_s1[e], graph.lane_offset(e, 0))
		var d0 := graph.direction(e, graph.e_s1[e])
		var p3 := graph.point_at(g, graph.e_s0[g], graph.lane_offset(g, 0))
		var d3 := graph.direction(g, graph.e_s0[g])
		var reach := clampf(p0.distance_to(p3) * 0.25, 1.0, 8.0)
		var length := LaneGraph.bezier_length(PackedVector2Array([p0, p0 + d0 * reach, p3 - d3 * reach, p3]))
		var chord := (p3 - p0).normalized()
		var turn := maxf(absf(d0.angle_to(chord)), absf(chord.angle_to(d3)))
		var id := _thru.size()
		_cut_id[key] = id
		_cut_e.append(e)
		var c := minf(minf(Traffic.CUT_TOP, Traffic.race_turn_speed(length, turn * 2.0, lat)), speed(e))
		_thru.append(c)
		_cross.append((length * RaceCuts.COST + RaceCuts.GAIN) / c)
		_time.append(INF)
		_done.append(0)
		return id

	## Searches on until the ways on from the end of edge e are final: its best one, and every
	## other within REACH s of it. With `most` it stops after that many states (a slice of the
	## search for one frame: `step`).
	func _reach(e: int, most := -1) -> void:
		var until := _best_at(e) + REACH if e >= 0 else INF
		while not _heap_y.is_empty():
			var t := _heap_t[0]
			if t > until or most == 0:
				return
			most -= 1
			var y := _heap_y[0]
			# The heap's pop, written out.
			var last := _heap_t.size() - 1
			var lt := _heap_t[last]
			var ly := _heap_y[last]
			_heap_t.resize(last)
			_heap_y.resize(last)
			if last > 0:
				var h := 0
				while true:
					var l := h * 2 + 1
					if l >= last:
						break
					var r := l + 1
					if r < last and _heap_t[r] < _heap_t[l]:
						l = r
					if _heap_t[l] >= lt:
						break
					_heap_t[h] = _heap_t[l]
					_heap_y[h] = _heap_y[l]
					h = l
				_heap_t[h] = lt
				_heap_y[h] = ly
			if _done[y] == 1 or t > _time[y]:
				continue
			_done[y] = 1
			settled += 1
			var at := _state_edge[y] if y < _roads else _cut_e[y - _roads]
			if at == e and until == INF:
				until = t + REACH
			if not shut.has(at) and graph.e_shut[at] == INF:
				_into(at, _thru[y], t)

	## One slice of the search towards the ways on from edge e: at most `most` states (the game
	## spreads a plan over the frames before a start, and a new one over a turn round). True when
	## those ways are final.
	func step(e: int, most: int) -> bool:
		if _known(e):
			return true
		_reach(e, most)
		return _known(e)

	## One slice of the search with no racer on its way yet (the next leg of a race in legs, whose
	## start nobody knows the street of): at most `most` states of whatever is left of the map.
	## True when nothing is left.
	func work(most: int) -> bool:
		if not _heap_y.is_empty():
			_reach(-1, most)
		return _heap_y.is_empty()

	## The least time of the settled ways on from the end of edge e (INF: none settled yet).
	func _best_at(e: int) -> float:
		var lo := INF
		var y0: int = planner.first[e]
		for k in graph.node_out[graph.e_b[e]].size():
			if _done[y0 + k] == 1:
				lo = minf(lo, _time[y0 + k])
		if cuts.has(graph.e_b[e]):
			var list: PackedFloat32Array = cuts[graph.e_b[e]]
			for k in range(0, list.size(), 2):
				var y: int = _cut_id.get((e << 16) | int(list[k]), -1)
				if y >= 0 and _done[y] == 1:
					lo = minf(lo, _time[y])
		return lo

	## Whether the ways on from the end of edge e are final: the search is over, or it has gone
	## KNOWN s past the best of them (any way that could still beat it is settled).
	func _known(e: int) -> bool:
		return _heap_y.is_empty() or _heap_t[0] > _best_at(e) + KNOWN

	## The way on for a racer on edge e at s, doing v m/s: the edge to take from the junction ahead
	## (-1: the plan knows no way from here), over a shortcut when `chosen_cut`. `held` is the way
	## it has chosen for this street already (-1: none; `held_cut`: over a shortcut): kept unless
	## another saves SWITCH_GAIN s. Also sets `chosen_time` (s to the finish that way) and `wrong`
	## / `wrong_time` (the road a wrong turn takes from this junction; -1: none).
	func choose(e: int, s: float, v: float, held := -1, held_cut := false) -> int:
		chosen_time = INF
		chosen_cut = false
		wrong = -1
		wrong_time = INF
		if ends_on(e, s):
			# The finish is on this street, at its end or where it enters the finish's circle: any
			# way on, straight for choice.
			var to: float = graph.e_s1[e] if _last[e] == 1 else ends[e].x
			chosen_time = _street(maxf(to - s, 0.0), v, speed(e), speed(e))
			return _straight_on(e)
		if not _known(e):
			_reach(e)
		var rest := maxf(graph.e_s1[e] - s, 0.0)
		var top_v := speed(e)
		var best := -1
		var best_time := INF
		var best_cut := false
		var held_time := INF
		var y0: int = planner.first[e]
		var outs := graph.node_out[graph.e_b[e]]
		var times := PackedFloat32Array()
		times.resize(outs.size())
		for k in outs.size():
			var y := y0 + k
			var f := outs[k]
			times[k] = INF
			if _done[y] == 0 or shut.has(f):
				continue
			var t := _street(rest, v, _through(y), top_v) + _time[y]
			times[k] = t
			if f == held and not held_cut:
				held_time = t
			if t < best_time:
				best = f
				best_time = t
		if cuts.has(graph.e_b[e]):
			var list: PackedFloat32Array = cuts[graph.e_b[e]]
			for k in range(0, list.size(), 2):
				var g := int(list[k])
				var y: int = _cut_id.get((e << 16) | g, -1)
				if y < 0 or _done[y] == 0 or shut.has(g):
					continue
				var t := _street(rest, v, _through(y), top_v) + _time[y]
				if g == held and held_cut:
					held_time = t
				if t < best_time:
					best = g
					best_time = t
					best_cut = true
		if held >= 0 and held_time < INF and held_time - best_time < SWITCH_GAIN:
			best = held
			best_time = held_time
			best_cut = held_cut
		# A wrong turn from here: the road that costs the most without being hopeless (never the
		# way back, which no driver takes by mistake).
		var rev := graph.e_reverse[e]
		var most := 0.0
		for k in outs.size():
			var over := times[k] - best_time
			if over >= WRONG_LEAST and over <= WRONG_MOST and over > most and outs[k] != rev and (best_cut or outs[k] != best):
				most = over
				wrong = outs[k]
				wrong_time = times[k]
		chosen_time = best_time
		chosen_cut = best_cut
		return best

	## Whether a racer at s on edge e has the finish on that street ahead of it (or is in it): the
	## street ends at the finish's junction, or runs through its circle and s is not past it.
	func ends_on(e: int, s: float) -> bool:
		return _last[e] == 1 or (_last[e] == 2 and s <= ends[e].y)

	## The stretch of edge e inside the finish's circle, Vector2(from, to) along it; (INF, -INF)
	## when it has none, or the street is shut to this racer.
	func end_of(e: int) -> Vector2:
		return ends[e] if _last[e] == 2 else Vector2(INF, -INF)

	## The metres from s on edge e to the finish: by `dist` (LaneGraph.distances_to, with
	## RacePlanner.links), or on a road through the finish's circle to where it enters.
	func metres(dist: PackedFloat32Array, e: int, s: float) -> float:
		if _last[e] == 2 and s <= ends[e].y:
			return maxf(ends[e].x - s, 0.0)
		return graph.remaining(dist, e, s)

	## Seconds to the finish from edge e at s, doing v m/s (INF: no way known). Leaves the last
	## `choose` as it was.
	func left(e: int, s: float, v: float) -> float:
		var keep := [chosen_time, chosen_cut, wrong, wrong_time]
		choose(e, s, v)
		var out := chosen_time
		chosen_time = keep[0]
		chosen_cut = keep[1]
		wrong = keep[2]
		wrong_time = keep[3]
		return out

	## The road out of the junction ahead of edge e that turns least.
	func _straight_on(e: int) -> int:
		var best := -1
		var best_turn := INF
		var here := graph.direction(e, graph.e_s1[e])
		for f in graph.node_out[graph.e_b[e]]:
			var turn := absf(here.angle_to(graph.direction(f, graph.e_s0[f])))
			if turn < best_turn and not shut.has(f):
				best_turn = turn
				best = f
		return best

	## Closes `edges` to this racer (a street it found blocked) and plans again; false when they
	## were closed already.
	func block(edges: PackedInt32Array) -> bool:
		var news := false
		for e in edges:
			if e >= 0 and not shut.has(e):
				shut[e] = true
				news = true
		if news:
			restart()
		return news

	## The streets from edge e at s to the finish, as the plan would drive them now (for the
	## logs and the checks): the edges in order, the first included. At most `most` edges.
	func route(e: int, s := 0.0, most := 400) -> PackedInt32Array:
		var out := PackedInt32Array([e])
		var at := e
		var v := speed(e)
		var pos := s
		while not ends_on(at, pos) and out.size() < most:
			var f := choose(at, pos, v)
			if f < 0:
				break
			out.append(f)
			at = f
			pos = graph.e_s0[f]
			v = speed(f)
		return out
