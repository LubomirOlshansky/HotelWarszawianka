extends RefCounted
## Beta values (2026-11-04): the way to a goal by road, as a polyline for the minimap's dotted
## route (hud.gd set_minimap_route), the one Podwózka's app draws. The kebab and słoiki deliveries,
## the way to the next kebab stand and the street races use it: the edge arrow alone points
## straight at the goal, through blocks and against one-way streets.
##
## The off-map links (LaneGraph portals) are left out: the edge roadworks close every road out, so
## the player can't drive them.
##
## The distances to the goal are worked out once (one LaneGraph.distances_to per goal); after
## that, every REFRESH s the line is walked again from the lane the car is on (a greedy walk
## down those distances, no new search), so it follows the car after a wrong turn.

const LaneGraph := preload("res://scripts/lane_graph.gd")

## Seconds between two walks of the line from the car.
const REFRESH := 1.0
## The car's lane is looked for this far out (m), first along the car's heading.
const SNAP := 40.0
## The longest walk (junctions), a guard against a loop in the distances.
const MAX_STEPS := 600

var graph: LaneGraph
## The distances to `_node` (LaneGraph.distances_to), the goal's lane point (`_e`, `_s`; -1: none,
## the line ends at `_node`), and the last stretch off the roads to `_tail` (INF: none).
var _dist := PackedFloat32Array()
var _node := -1
var _e := -1
var _s := 0.0
var _tail := Vector2.INF
## A goal that is a circle round `_node` (a street race's finish): the roads that run through it,
## {edge: Vector2(the s where it enters, the s where it leaves)} (race_planner.gd `ends`; none:
## the line ends at the node). The line ends where the road it comes by enters the circle.
var _ends := {}
var _t := 0.0
var points := PackedVector2Array()


func _init(lane_graph: LaneGraph) -> void:
	graph = lane_graph


## A goal on lane point (e, s), the polyline ending at `tail` (the ring; INF: the lane point).
## `dist` may be passed when the caller already has distances_to(e_a[e]).
func to_lane(e: int, s: float, tail := Vector2.INF, dist := PackedFloat32Array()) -> void:
	_e = e
	_s = s
	_node = graph.e_a[e]
	_dist = dist if not dist.is_empty() else graph.distances_to(_node, INF, false)
	_tail = tail
	_ends = {}
	_t = REFRESH


## A goal at node `node` (with its distances, or worked out here), then straight to `tail`. With
## `ends` the goal is a circle round the node and `dist` holds the links of the roads through it
## (race_planner.gd `ends` and `links`): the line ends where its road enters the circle.
func to_node(node: int, tail := Vector2.INF, dist := PackedFloat32Array(), ends := {}) -> void:
	_e = -1
	_s = 0.0
	_node = node
	_dist = dist if not dist.is_empty() else graph.distances_to(node, INF, false)
	_tail = tail
	_ends = ends
	_t = REFRESH


func clear() -> void:
	_node = -1
	_dist = PackedFloat32Array()
	_ends = {}
	points = PackedVector2Array()


func active() -> bool:
	return _node >= 0


## Walks the line again from the car every REFRESH s; true when `points` changed (send it to the hud).
func update(car_at: Vector2, heading: Vector2, dt: float) -> bool:
	if _node < 0:
		return false
	_t += dt
	if _t < REFRESH:
		return false
	_t = 0.0
	var hit := graph.snap(car_at, SNAP, heading, true)
	if hit.is_empty():
		hit = graph.snap(car_at, SNAP * 1.5, Vector2.ZERO, true)
	var out := PackedVector2Array()
	if hit.is_empty():
		# Off the roads (a plaza, the helicopter's landing): the straight line to the goal.
		out.append(car_at)
	else:
		walk(int(hit[0]), float(hit[2]), out)
	if _tail != Vector2.INF:
		out.append(_tail)
	points = out
	return true


## The polyline from lane point (e, s) to the goal (appended to `out`).
func walk(e: int, s: float, out: PackedVector2Array) -> void:
	if _e >= 0 and e == _e and _s >= s:
		out.append(graph.point_at(e, s))
		_edge_points(e, s, _s, out)
		return
	out.append(graph.point_at(e, s))
	if _ends.has(e) and s <= _ends[e].y:
		# On a road through the goal's circle: to where it enters (or here, inside it already).
		_edge_points(e, s, maxf(_ends[e].x, s), out)
		return
	_edge_points(e, s, graph.e_len[e], out)
	var n: int = graph.e_b[e]
	var steps := 0
	while n != _node and steps < MAX_STEPS:
		steps += 1
		var best := -1
		var best_d := INF
		var best_to := -1.0
		for f in graph.node_out[n]:
			var c: float = graph.e_len[f] + _dist[graph.e_b[f]]
			var to := -1.0
			if _ends.has(f) and _ends[f].x < c:
				# This road runs through the goal's circle: its metres end where it enters.
				c = _ends[f].x
				to = c
			if c < best_d:
				best_d = c
				best = f
				best_to = to
		if best < 0 or best_d >= INF or best_d > _dist[n] + 1.0:
			break
		if best_to >= 0.0:
			_edge_points(best, 0.0, best_to, out)
			return
		_edge_points(best, 0.0, graph.e_len[best], out)
		n = graph.e_b[best]
	if _e >= 0 and n == _node:
		_edge_points(_e, 0.0, _s, out)


func _edge_points(e: int, a: float, b: float, out: PackedVector2Array) -> void:
	var i0: int = graph.e_first[e]
	for k in graph.e_count[e]:
		var c: float = graph.cum[i0 + k]
		if c > a and c < b:
			out.append(graph.pts[i0 + k])
	out.append(graph.point_at(e, b))
