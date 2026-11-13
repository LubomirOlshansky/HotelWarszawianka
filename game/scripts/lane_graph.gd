extends RefCounted
## The road network the AI traffic and the rivals drive on, from the "graph"
## section of centrum.json (baked by tools/bake_osm.py): directed edges with their
## lanes, the curves that join lanes across a junction, the traffic-light
## controllers, a spatial grid for spawning and snapping, and shortest-path
## distances for the street races.
##
## Positions along an edge are metres along its centreline (s). A lane is the
## centreline shifted right by the lane's offset; Poland drives on the right.

const CELL := 64.0
## Heights along an edge are sampled this far apart (the terrain grid is 10 m).
const HEIGHT_STEP := 8.0
## Loop 3a (R4): tunnel edges are in the data with their heights. Loop 3b builds the tunnels
## (portals, walls, the floor the car drives: map_builder.gd `tunnel_floor`), so they are in
## the adjacency and the spatial grid: traffic routes, spawns and snaps through them (and is
## hidden deeper inside than TUNNEL_HIDE, traffic.gd). False keeps them out (loop 3a).
const TUNNELS_DRIVEN := true
## Loop 3b: how far into a tunnel (from a portal) traffic stays drawn.
const TUNNEL_HIDE := 15.0
## Light states.
const GREEN := 0
const AMBER := 1
const RED := 2
const RED_AMBER := 3
## Two-group cycle: green, amber, all red; then the other axis. Polish lights show
## red and amber together for a second before green.
const GREEN_TIME := 18.0
const AMBER_TIME := 3.0
const CLEAR_TIME := 2.0
const CYCLE := 2.0 * (GREEN_TIME + AMBER_TIME + CLEAR_TIME)
## Mid-block pedestrian lights: long green for the cars, a short red.
const PED_GREEN := 26.0
const PED_CYCLE := 40.0

var node_pos := PackedVector2Array()
var node_scc := PackedByteArray()
var node_out: Array[PackedInt32Array] = []
var node_in: Array[PackedInt32Array] = []

var e_a := PackedInt32Array()
var e_b := PackedInt32Array()
var e_first := PackedInt32Array()
var e_count := PackedInt32Array()
var e_len := PackedFloat32Array()
var e_s0 := PackedFloat32Array()
var e_s1 := PackedFloat32Array()
var e_lanes := PackedInt32Array()
var e_off0 := PackedFloat32Array()
var e_lw := PackedFloat32Array()
var e_speed := PackedFloat32Array()
## 0 primary/secondary, 1 tertiary and links, 2 residential, 3 living street.
var e_class := PackedInt32Array()
var e_bridge := PackedByteArray()
## Loop 3a (R8): the deck group (tools/bake_roads.py) or the tunnel each edge lies on, -1 for
## the ground; its lanes take their heights from that piece only (never "the highest deck
## over the point", which is wrong where structures stack).
var e_dk := PackedInt32Array()
var e_tn := PackedInt32Array()
## Loop 3b: which ends of a tunnel edge are portals (1 its start, 2 its end; bake `po`).
var e_po := PackedByteArray()
## Streets closed to cars since the map was drawn (tools/car_free.py `cf`: Złota's linear park):
## kept so edge indices stay put, but out of the adjacency and the spawn grid.
var e_cf := PackedByteArray()
var e_name := PackedStringArray()
## The same road the other way (for U-turns at dead ends), or -1.
var e_reverse := PackedInt32Array()
## First lane id of each edge; lane ids index per-lane lists in the traffic.
var e_lane0 := PackedInt32Array()
var lane_count := 0
## Stop lines: per edge, flat [s, controller, group, ...] sorted by s.
var e_stops: Array[PackedFloat32Array] = []

var pts := PackedVector2Array()
var cum := PackedFloat32Array()
## Right-hand normal at each point, mitred so an offset lane keeps its width round bends.
var nrm := PackedVector2Array()

var ctrl_pos := PackedVector2Array()
var ctrl_groups := PackedInt32Array()
var ctrl_axis := PackedFloat32Array()
var ctrl_offset := PackedFloat32Array()
## Signal poles drawn by the city: controller and group per pole (-1 = unlit).
var poles := PackedInt32Array()
## Off-map links (the bake's "portals"): a road leaving the map joins a road coming
## back in nearby on the same side. Route planning uses them; nobody drives them, but a
## rival that leaves the map comes back in through one.
var portal_from := PackedInt32Array()
var portal_to := PackedInt32Array()
var portal_cost := PackedFloat32Array()
## Per edge: indices of the links from its far end (exits only).
var e_portals: Array[PackedInt32Array] = []
## The edge roadworks (edge_roadworks.gd, 2026-11-02): a road that leaves the map is closed by a
## barrier line EdgeRoadworks.CLOSE_IN metres inside the outline. Per edge, `e_shut` is where a car
## going out has to stop (s along the edge; INF: the road is open) and `e_open` where a car coming
## in from the edge starts (-INF: everywhere). The traffic stops, spawns and comes back through a
## portal by them, so no car drives through the barriers.
var e_shut := PackedFloat32Array()
var e_open := PackedFloat32Array()
## Per node: flat [other node, cost, ...] links in and out, for the shortest paths.
var _portal_in: Array[PackedFloat32Array] = []
var _portal_out: Array[PackedFloat32Array] = []

## Cell key -> edges passing through it.
var grid := {}
## Seconds on the shared traffic-light clock.
var clock := 0.0

var _map: Node3D
## Metres along the lane short of the barrier line where a car's nose stops (and past it where one
## starts).
const SHUT_PAD := 3.0
## ... and at least this far further in from the map's outline than the line (m).
const SHUT_CLEAR := 2.5
## Metres past each end of a barrier line that still cut a lane crossing there.
const END_SLACK := 3.0
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
var _heights: Array[PackedFloat32Array] = []


func _init(graph: Dictionary, map: Node3D) -> void:
	_map = map
	var flat: Array = graph["nodes"]
	var scc: Array = graph["scc"]
	for i in range(0, flat.size() - 1, 2):
		node_pos.append(Vector2(flat[i], flat[i + 1]))
		node_scc.append(int(scc[i / 2]))
		node_out.append(PackedInt32Array())
		node_in.append(PackedInt32Array())
	var by_ends := {}
	var lane_id := 0
	for e in graph["edges"]:
		var i := e_a.size()
		var a := int(e["a"])
		var b := int(e["b"])
		e_a.append(a)
		e_b.append(b)
		e_dk.append(int(e.get("dk", -1)))
		e_tn.append(int(e.get("tn", -1)))
		e_po.append(int(e.get("po", 0)))
		e_cf.append(int(e.get("cf", 0)))
		if (TUNNELS_DRIVEN or e_tn[i] < 0) and e_cf[i] == 0:
			node_out[a].append(i)
			node_in[b].append(i)
		var p: Array = e["p"]
		e_first.append(pts.size())
		e_count.append(p.size() / 2)
		var run := 0.0
		for k in range(0, p.size() - 1, 2):
			var q := Vector2(p[k], p[k + 1])
			if k > 0:
				run += q.distance_to(pts[pts.size() - 1])
			pts.append(q)
			cum.append(run)
		e_len.append(run)
		e_s0.append(float(e["s0"]))
		e_s1.append(maxf(float(e["s1"]), float(e["s0"]) + 0.1))
		e_lanes.append(int(e["n"]))
		e_off0.append(float(e["o"]))
		e_lw.append(float(e["lw"]))
		e_speed.append(float(e["v"]))
		e_class.append(_class_of(String(e["k"])))
		e_bridge.append(int(e.get("br", 0)))
		e_name.append(String(e.get("name", "")))
		e_lane0.append(lane_id)
		lane_id += int(e["n"])
		var stops := PackedFloat32Array()
		for st in e.get("st", []):
			stops.append_array(PackedFloat32Array([float(st[0]), float(st[1]), float(st[2])]))
		e_stops.append(stops)
		by_ends[Vector2i(a, b)] = i
		_heights.append(PackedFloat32Array())
	lane_count = lane_id
	e_reverse.resize(e_a.size())
	for i in e_a.size():
		e_reverse[i] = by_ends.get(Vector2i(e_b[i], e_a[i]), -1)
	_build_normals()
	_build_grid()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1944
	for c in graph["ctrl"]:
		ctrl_pos.append(Vector2(c[0], c[1]))
		ctrl_groups.append(int(c[2]))
		ctrl_axis.append(float(c[3]) if c.size() > 3 else 0.0)
		ctrl_offset.append(rng.randf() * CYCLE)
	for v in graph.get("poles", []):
		poles.append(int(v))
	for e in e_a.size():
		e_portals.append(PackedInt32Array())
	for n in node_pos.size():
		_portal_in.append(PackedFloat32Array())
		_portal_out.append(PackedFloat32Array())
	_find_closures()
	for link in graph.get("portals", []):
		var i := portal_from.size()
		var from := int(link[0])
		var to := int(link[1])
		portal_from.append(from)
		portal_to.append(to)
		portal_cost.append(float(link[2]))
		e_portals[from].append(i)
		_portal_out[e_b[from]].append_array(PackedFloat32Array([e_a[to], float(link[2])]))
		_portal_in[e_a[to]].append_array(PackedFloat32Array([e_b[from], float(link[2])]))


## Where the edge roadworks close each edge (`e_shut`, `e_open`). First every edge whose centreline
## crosses a closure's barrier line (edge_roadworks.gd `closures`, the same placement the city draws):
## going out it is shut SHUT_PAD along the lane short of the line and SHUT_CLEAR in from it (a slanted
## road's bus corner), coming in it opens as far past it. Then from every dead end at the map's
## outline (within EDGE_END of it: no way on but back) the road is followed inwards, edge by edge (the
## straightest at a fork), to the first edge already cut, or failing that to where it crosses the
## CLOSE_IN line; the edges on the way lie wholly behind the barriers. Needs a map with `in_map`.
func _find_closures() -> void:
	var n := e_a.size()
	e_shut.resize(n)
	e_shut.fill(INF)
	e_open.resize(n)
	e_open.fill(-INF)
	if _map == null or not _map.has_method("in_map") or _map.bounds.size == Vector2.ZERO:
		return
	for c: Dictionary in EdgeRoadworks.closures(_map):
		_cut_at(c)
	for e in n:
		var b := e_b[e]
		if not _map.in_map(node_pos[b], -EdgeRoadworks.EDGE_END) and _dead_end(node_out[b], e_reverse[e]):
			_shut_back(e)
		var a := e_a[e]
		if not _map.in_map(node_pos[a], -EdgeRoadworks.EDGE_END) and _dead_end(node_in[a], e_reverse[e]):
			_open_on(e)


## The edges crossing closure c's barrier line, shut or opened there.
func _cut_at(c: Dictionary) -> void:
	var out: Vector2 = c["dir"]
	# A lane passing just beyond the line's end (a bus's corner would catch it) counts as crossing.
	var side := Vector2(out.y, -out.x) * (float(c["half"]) + END_SLACK)
	var at: Vector2 = c["at"]
	var la := at - side
	var lb := at + side
	var seen := {}
	var steps := maxi(1, ceili(la.distance_to(lb) / (CELL * 0.5)))
	for j in steps + 1:
		for e in grid.get(cell_key(la.lerp(lb, float(j) / steps)), PackedInt32Array()):
			if seen.has(e):
				continue
			seen[e] = true
			var i0 := e_first[e]
			for k in e_count[e] - 1:
				var a := pts[i0 + k]
				var b := pts[i0 + k + 1]
				var hit: Variant = Geometry2D.segment_intersects_segment(a, b, la, lb)
				if hit == null:
					continue
				var s := cum[i0 + k] + a.distance_to(hit)
				# Clear of the line: SHUT_PAD along the lane, SHUT_CLEAR across the line's normal.
				if (b - a).dot(out) > 0.0:
					var stop := s - SHUT_PAD
					while stop > 0.0 and _clearance(e, stop, at, out) < SHUT_CLEAR:
						stop -= 1.0
					e_shut[e] = minf(e_shut[e], maxf(stop, 0.0))
				else:
					var go := s + SHUT_PAD
					while go < e_len[e] and _clearance(e, go, at, out) < SHUT_CLEAR:
						go += 1.0
					e_open[e] = maxf(e_open[e], minf(go, e_len[e]))


## How far in from a barrier line (through `at`, facing out along `out`) the nearest corner of a wide
## vehicle on any of edge e's lanes at s stands (m).
func _clearance(e: int, s: float, at: Vector2, out: Vector2) -> float:
	var worst := INF
	for lane in [0, e_lanes[e] - 1]:
		var p := point_at(e, s, lane_offset(e, lane))
		var across := Vector2(-direction(e, s).y, direction(e, s).x) * 1.4
		for q: Vector2 in [p + across, p - across]:
			worst = minf(worst, (at - q).dot(out))
	return worst


## Whether a point lies in the band at the map's edge where the roadworks stand (no traffic starts there).
func in_works_band(p: Vector2) -> bool:
	return _map != null and _map.has_method("in_map") and _map.bounds.size != Vector2.ZERO \
			and not _map.in_map(p, -(EdgeRoadworks.CLOSE_IN + SHUT_CLEAR))


## Going out along e towards the edge: to the first edge already cut, or shut where it crosses the
## CLOSE_IN line, the edges before wholly.
func _shut_back(e: int) -> void:
	var inset := EdgeRoadworks.CLOSE_IN
	var cur := e
	var walked := 0.0
	while cur >= 0 and walked <= EdgeRoadworks.WALK + 20.0:
		if e_shut[cur] < INF:
			return
		var s := e_len[cur]
		while s > 0.0 and not _map.in_map(point_at(cur, s), -inset):
			s -= 1.0
		if _map.in_map(point_at(cur, s), -inset):
			var stop := s - SHUT_PAD
			while stop > 0.0 and not _map.in_map(point_at(cur, stop), -inset - SHUT_CLEAR):
				stop -= 1.0
			e_shut[cur] = maxf(stop, 0.0)
			return
		e_shut[cur] = 0.0
		walked += e_len[cur]
		var here := direction(cur, 0.0)
		var next := -1
		var best := -0.2
		for f in node_in[e_a[cur]]:
			if f == e_reverse[cur]:
				continue
			var d := direction(f, e_len[f]).dot(here)
			if d > best:
				best = d
				next = f
		cur = next


## Coming in along e from the edge: to the first edge already cut, or open past the CLOSE_IN line,
## the edges before closed wholly.
func _open_on(e: int) -> void:
	var inset := EdgeRoadworks.CLOSE_IN
	var cur := e
	var walked := 0.0
	while cur >= 0 and walked <= EdgeRoadworks.WALK + 20.0:
		if e_open[cur] > -INF:
			return
		var s := 0.0
		while s < e_len[cur] and not _map.in_map(point_at(cur, s), -inset):
			s += 1.0
		if _map.in_map(point_at(cur, s), -inset):
			var go := s + SHUT_PAD
			while go < e_len[cur] and not _map.in_map(point_at(cur, go), -inset - SHUT_CLEAR):
				go += 1.0
			e_open[cur] = minf(go, e_len[cur])
			return
		e_open[cur] = e_len[cur]
		walked += e_len[cur]
		var here := direction(cur, e_len[cur])
		var next := -1
		var best := -0.2
		for f in node_out[e_b[cur]]:
			if f == e_reverse[cur]:
				continue
			var d := direction(f, 0.0).dot(here)
			if d > best:
				best = d
				next = f
		cur = next


## Whether a node's edges (out or in) are at most the way back: a dead end.
static func _dead_end(edges: PackedInt32Array, rev: int) -> bool:
	for f in edges:
		if f != rev:
			return false
	return true


## Whether s on edge e lies past its barrier line (the closed stretch at the map's edge).
func closed_at(e: int, s: float) -> bool:
	return s > e_shut[e] or s < e_open[e]


static func _class_of(kind: String) -> int:
	if kind in ["primary", "secondary", "trunk", "motorway"]:
		return 0
	if kind in ["residential", "unclassified"]:
		return 2
	if kind == "living_street":
		return 3
	return 1


func _build_normals() -> void:
	nrm.resize(pts.size())
	for e in e_a.size():
		var i0 := e_first[e]
		var n := e_count[e]
		for k in n:
			var i := i0 + k
			var back := _seg_dir(i - 1) if k > 0 else Vector2.ZERO
			var ahead := _seg_dir(i) if k < n - 1 else Vector2.ZERO
			if back == Vector2.ZERO:
				back = ahead
			if ahead == Vector2.ZERO:
				ahead = back
			var r0 := Vector2(-back.y, back.x)
			var r1 := Vector2(-ahead.y, ahead.x)
			var m := (r0 + r1).normalized()
			if m == Vector2.ZERO:
				m = r1
			nrm[i] = m / maxf(m.dot(r1), 0.5)


func _seg_dir(i: int) -> Vector2:
	return (pts[i + 1] - pts[i]).normalized()


func _build_grid() -> void:
	for e in e_a.size():
		if (e_tn[e] >= 0 and not TUNNELS_DRIVEN) or e_cf[e] != 0:
			continue
		var seen := {}
		var i0 := e_first[e]
		for k in e_count[e] - 1:
			var a := pts[i0 + k]
			var b := pts[i0 + k + 1]
			var steps := maxi(1, ceili(a.distance_to(b) / (CELL * 0.5)))
			for j in steps + 1:
				var key := cell_key(a.lerp(b, float(j) / steps))
				if not seen.has(key):
					seen[key] = true
					if not grid.has(key):
						grid[key] = PackedInt32Array()
					grid[key].append(e)


static func cell_key(p: Vector2) -> int:
	return (floori(p.x / CELL) + 512) * 1024 + floori(p.y / CELL) + 512


# --- geometry -------------------------------------------------------------------

## Lateral offset of lane k on edge e, metres right of the centreline.
func lane_offset(e: int, k: int) -> float:
	return e_off0[e] + e_lw[e] * k


## Index of the polyline point at or before s, starting the search at `hint`.
func seek(e: int, s: float, hint: int) -> int:
	var i0 := e_first[e]
	var last := i0 + e_count[e] - 2
	var i := clampi(hint, i0, last)
	while i < last and cum[i + 1] <= s:
		i += 1
	while i > i0 and cum[i] > s:
		i -= 1
	return i


## The point s along edge e, `off` metres right of the centreline; i from seek().
func point(e: int, s: float, off: float, i: int) -> Vector2:
	var seg := cum[i + 1] - cum[i]
	var t := clampf((s - cum[i]) / seg, 0.0, 1.0) if seg > 0.0001 else 0.0
	return pts[i].lerp(pts[i + 1], t) + nrm[i].lerp(nrm[i + 1], t) * off


func direction(e: int, s: float) -> Vector2:
	var i := seek(e, s, e_first[e])
	return (pts[i + 1] - pts[i]).normalized()


func point_at(e: int, s: float, off := 0.0) -> Vector2:
	return point(e, s, off, seek(e, s, e_first[e]))


## Distance along edge e's centreline to the point nearest p.
func project(e: int, p: Vector2) -> float:
	var best := 0.0
	var best_d := INF
	var i0 := e_first[e]
	for k in e_count[e] - 1:
		var a := pts[i0 + k]
		var ab := pts[i0 + k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.0001:
			continue
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d := p.distance_squared_to(a + ab * t)
		if d < best_d:
			best_d = d
			best = cum[i0 + k] + t * sqrt(l2)
	return best


## The road surface under the centreline at s (bridge decks included). Loop 3a: the last
## knot sits at the edge's end (it used to be taken as if 8 m on, so edges meeting at a
## node on a slope disagreed by a few tenths of a metre).
func height(e: int, s: float) -> float:
	var h := _heights[e]
	if h.is_empty():
		h = _sample_heights(e)
	var k := clampi(int(s / HEIGHT_STEP), 0, h.size() - 2)
	var s0 := k * HEIGHT_STEP
	var seg := minf(HEIGHT_STEP, e_len[e] - s0)
	return lerpf(h[k], h[k + 1], clampf((s - s0) / seg, 0.0, 1.0) if seg > 0.001 else 0.0)


## Sampled the first time a car uses the edge. Loop 3a (R8): from the edge's own deck
## or tunnel (a road under a bridge stays on the terrain, a lane on a stacked deck on its own).
func _sample_heights(e: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	var n := maxi(2, ceili(e_len[e] / HEIGHT_STEP - 0.001) + 1)
	h.resize(n)
	var i := e_first[e]
	for k in n:
		var s := minf(k * HEIGHT_STEP, e_len[e])
		i = seek(e, s, i)
		var p := point(e, s, 0.0, i)
		h[k] = surface(e, p)
	_heights[e] = h
	return h


## Loop 3b: how far inside its tunnel a point s along tunnel edge e lies, from the nearest
## portal end (INF when neither end is a portal; 0 for an edge in the open).
func tunnel_depth(e: int, s: float) -> float:
	if e_tn[e] < 0:
		return 0.0
	var depth := INF
	if e_po[e] & 1:
		depth = s
	if e_po[e] & 2:
		depth = minf(depth, e_len[e] - s)
	return depth


## Loop 3a (R8): the road surface of edge e at a point beside it: its tunnel, its deck or
## the terrain.
func surface(e: int, p: Vector2) -> float:
	if e_tn[e] >= 0:
		return _map.tunnel_height(e_tn[e], p.x, p.y)
	if e_dk[e] >= 0:
		return _map.deck_height(e_dk[e], p.x, p.y)
	return _map.terrain_height(p.x, p.y)


## The lane point nearest to p within `reach` metres among edges whose direction
## agrees with `heading` (any direction if heading is zero): [edge, lane, s] or [].
## `ground_only` leaves out bridges; `no_tunnel` leaves out tunnel edges (GAMEPLAY_PLAN 0.1: a
## teleport or tow asked for on the street must not land on the tunnel's floor under it).
func snap(p: Vector2, reach: float, heading := Vector2.ZERO, scc_only := false, ground_only := false,
		no_tunnel := false) -> Array:
	var best: Array = []
	var best_d := reach
	var seen := {}
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var key := cell_key(p + Vector2(dx, dz) * CELL * 0.5)
			if seen.has(key) or not grid.has(key):
				continue
			seen[key] = true
			for e in grid[key]:
				if scc_only and (node_scc[e_a[e]] == 0 or node_scc[e_b[e]] == 0):
					continue
				if ground_only and e_bridge[e] == 1:
					continue
				if no_tunnel and e_tn[e] >= 0:
					continue
				var i0 := e_first[e]
				for k in e_count[e] - 1:
					var a := pts[i0 + k]
					var b := pts[i0 + k + 1]
					var ab := b - a
					var l2 := ab.length_squared()
					if l2 < 0.0001:
						continue
					if heading != Vector2.ZERO and ab.dot(heading) < 0.5 * sqrt(l2):
						continue
					var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
					var s := cum[i0 + k] + t * sqrt(l2)
					s = clampf(s, e_s0[e], e_s1[e])
					for lane in e_lanes[e]:
						var q := point(e, s, lane_offset(e, lane), seek(e, s, i0 + k))
						var d := q.distance_to(p)
						if d < best_d:
							best_d = d
							best = [e, lane, s]
	return best


## The curve across a junction from lane (e, k) to lane (f, j): cubic Bezier
## control points, flat [p0, p1, p2, p3].
func connector(e: int, k: int, f: int, j: int) -> PackedVector2Array:
	var p0 := point_at(e, e_s1[e], lane_offset(e, k))
	var d0 := direction(e, e_s1[e])
	var p3 := point_at(f, e_s0[f], lane_offset(f, j))
	var d3 := direction(f, e_s0[f])
	var reach := maxf(p0.distance_to(p3) * 0.42, 1.0)
	if f == e_reverse[e]:
		reach = maxf(reach, 4.0)  # a U-turn swings out
	return PackedVector2Array([p0, p0 + d0 * reach, p3 - d3 * reach, p3])


## The point at t (0-1) of a cubic Bezier [p0, p1, p2, p3], or of a chain of them [p0, c1, c2,
## p1, c1, c2, p2, ...] (a race link, race_cuts.gd `chain`: pieces of one length, t shared out
## evenly between them).
static func bezier(c: PackedVector2Array, t: float) -> Vector2:
	if c.size() > 4:
		var n := (c.size() - 1) / 3
		var x := clampf(t, 0.0, 1.0) * n
		var i := mini(int(x), n - 1)
		var b := i * 3
		var w := x - i
		var v := 1.0 - w
		return c[b] * (v * v * v) + c[b + 1] * (3.0 * v * v * w) + c[b + 2] * (3.0 * v * w * w) + c[b + 3] * (w * w * w)
	var u := 1.0 - t
	return c[0] * (u * u * u) + c[1] * (3.0 * u * u * t) + c[2] * (3.0 * u * t * t) + c[3] * (t * t * t)


static func bezier_length(c: PackedVector2Array) -> float:
	var length := 0.0
	var prev := c[0]
	var m := 8 * maxi((c.size() - 1) / 3, 1)
	for k in range(1, m + 1):
		var q := bezier(c, float(k) / m)
		length += prev.distance_to(q)
		prev = q
	return maxf(length, 0.5)


## The lane on edge f to continue in after lane k of edge e: right turns take the
## rightmost lane, left turns the leftmost, straight on keeps the position.
func next_lane(e: int, k: int, f: int) -> int:
	var n := e_lanes[f]
	if n == 1:
		return 0
	var turn := direction(e, e_s1[e]).angle_to(direction(f, e_s0[f]))
	if turn > 0.6:
		return n - 1   # right turn (+angle turns clockwise seen from above: +x to +z)
	if turn < -0.6:
		return 0
	return clampi(k + (n - e_lanes[e]) / 2, 0, n - 1)


# --- traffic lights ---------------------------------------------------------------

## GREEN, AMBER, RED or RED_AMBER for one approach group of a controller.
func light(c: int, group: int) -> int:
	var t := fposmod(clock + ctrl_offset[c], CYCLE if ctrl_groups[c] > 1 else PED_CYCLE)
	if ctrl_groups[c] <= 1:
		if t < PED_GREEN:
			return GREEN
		if t < PED_GREEN + AMBER_TIME:
			return AMBER
		return RED_AMBER if t > PED_CYCLE - 1.0 else RED
	var half := GREEN_TIME + AMBER_TIME + CLEAR_TIME
	if group == 1:
		t = fposmod(t - half, CYCLE)
	if t < GREEN_TIME:
		return GREEN
	if t < GREEN_TIME + AMBER_TIME:
		return AMBER
	return RED_AMBER if t > CYCLE - 1.0 else RED


# --- routing ----------------------------------------------------------------------

## Shortest driving distance from every node to `target` (INF where it can't be
## reached): Dijkstra over the reversed edges with a small binary heap. Loop 3g-1: with
## `max_cost` the search stops there (a police chaser's 800 m: a few hundred nodes, not the
## whole graph); nodes further away are INF or an upper bound, and the driver heads for its
## `goal` at junctions the route doesn't reach (traffic.gd _choose_next).
## Beta values (2026-11-04): `portals` false leaves the off-map links out: the player's car can't
## drive them (the edge roadworks close every road out), so the player's own routes skip them.
## Street races R3 (2026-11-05): `extra_in` adds links into a node, {node: [from, cost, from, cost...]}
## (a racer's shortcuts, race_cuts.gd), searched like the portals.
## The racer AI rebuild, step 3 (2026-11-10): `shut` ({edge: anything}) leaves those edges out: the
## streets a racer found blocked (race_planner.gd Plan.shut), for the metres it has left.
func distances_to(target: int, max_cost := INF, portals := true, extra_in := {}, shut := {}) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(node_pos.size())
	dist.fill(INF)
	dist[target] = 0.0
	var heap_d := PackedFloat32Array([0.0])
	var heap_n := PackedInt32Array([target])
	var closed := not shut.is_empty()
	while not heap_n.is_empty():
		var d := heap_d[0]
		var n := heap_n[0]
		_heap_pop(heap_d, heap_n)
		if d > dist[n]:
			continue
		if d > max_cost:
			break
		for e in node_in[n]:
			if closed and shut.has(e):
				continue
			var m := e_a[e]
			var nd := d + e_len[e]
			if nd < dist[m]:
				dist[m] = nd
				_heap_push(heap_d, heap_n, nd, m)
		if extra_in.has(n):
			var cuts: PackedFloat32Array = extra_in[n]
			for k in range(0, cuts.size(), 2):
				var m := int(cuts[k])
				var nd := d + cuts[k + 1]
				if nd < dist[m]:
					dist[m] = nd
					_heap_push(heap_d, heap_n, nd, m)
		if not portals:
			continue
		var links := _portal_in[n]
		for k in range(0, links.size(), 2):
			var m := int(links[k])
			var nd := d + links[k + 1]
			if nd < dist[m]:
				dist[m] = nd
				_heap_push(heap_d, heap_n, nd, m)
	return dist


## Shortest driving distance from `source` to every node (INF where it can't be
## reached): the side jobs measure their trips with it.
## (`portals` false: without the off-map links, see distances_to.)
func distances_from(source: int, portals := true) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(node_pos.size())
	dist.fill(INF)
	dist[source] = 0.0
	var heap_d := PackedFloat32Array([0.0])
	var heap_n := PackedInt32Array([source])
	while not heap_n.is_empty():
		var d := heap_d[0]
		var n := heap_n[0]
		_heap_pop(heap_d, heap_n)
		if d > dist[n]:
			continue
		for e in node_out[n]:
			var m := e_b[e]
			var nd := d + e_len[e]
			if nd < dist[m]:
				dist[m] = nd
				_heap_push(heap_d, heap_n, nd, m)
		if not portals:
			continue
		var links := _portal_out[n]
		for k in range(0, links.size(), 2):
			var m := int(links[k])
			var nd := d + links[k + 1]
			if nd < dist[m]:
				dist[m] = nd
				_heap_push(heap_d, heap_n, nd, m)
	return dist


## Driving distance from lane point (e1, s1) to lane point (e2, s2), given
## distances_from(e_b[e1]).
func trip(from_end: PackedFloat32Array, e1: int, s1: float, e2: int, s2: float) -> float:
	if e1 == e2 and s2 >= s1:
		return s2 - s1
	return (e_len[e1] - s1) + from_end[e_a[e2]] + s2


func _heap_push(hd: PackedFloat32Array, hn: PackedInt32Array, d: float, n: int) -> void:
	hd.append(d)
	hn.append(n)
	var i := hd.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if hd[p] <= hd[i]:
			break
		var td := hd[p]
		hd[p] = hd[i]
		hd[i] = td
		var tn := hn[p]
		hn[p] = hn[i]
		hn[i] = tn
		i = p


func _heap_pop(hd: PackedFloat32Array, hn: PackedInt32Array) -> void:
	var last := hd.size() - 1
	hd[0] = hd[last]
	hn[0] = hn[last]
	hd.resize(last)
	hn.resize(last)
	var i := 0
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < last and hd[l] < hd[m]:
			m = l
		if r < last and hd[r] < hd[m]:
			m = r
		if m == i:
			break
		var td := hd[m]
		hd[m] = hd[i]
		hd[i] = td
		var tn := hn[m]
		hn[m] = hn[i]
		hn[i] = tn
		i = m


## Distance left to the target from a point s along edge e, given distances_to().
func remaining(dist: PackedFloat32Array, e: int, s: float) -> float:
	return (e_len[e] - s) + dist[e_b[e]]


## The connected graph node nearest to p.
func nearest_node(p: Vector2, scc_only := true) -> int:
	var best := -1
	var best_d := INF
	for n in node_pos.size():
		if scc_only and node_scc[n] == 0:
			continue
		var d := node_pos[n].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = n
	return best
