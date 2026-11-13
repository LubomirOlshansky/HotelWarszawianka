extends RefCounted
## Street races R3 (docs/design/street-races.md, F 2026-11-05: "they go only by the roads, never
## the skróty"): the racers' shortcuts. game/data/race_cuts.json (tools/race_cuts.py) lists straight
## cuts between two junctions across a plaza, a forecourt, a car park, a lawn or a wide pavement,
## checked for a clear 2.8 m corridor and level ground. Here they are snapped to the lane graph's
## nodes and handed out by knowledge: a rival knowing `share` of them gets each cut whose hash
## (cut, rival) falls under it, the same ones every race (Zbyszek knows all, Słoik none).
##
## A cut is driven both ways, and joins the far junction's roads only where the cut doesn't turn
## more than EXIT_TURN off the road's way (worked out once, at load: `exits`). `links(share, seed)`
## gives the racer's table (traffic.gd Driver.cuts: {node: [edge on, metres, ...]}) and the
## routing's extra links (lane_graph.gd distances_to's `extra_in`: {node: [from, cost, ...]}: the
## cut, a metre of it costing COST metres of road, plus the edge on and GAIN, the metres it must save), so the
## race's distances, the gap and the band count exactly the shortcuts the rival takes, and a
## racer never circles a cut it can't drive.
##
## Racer AI step 5 (docs/design/race-ai.md 5.4): the race links. game/data/race_links.json
## (tools/race_links.py) adds ways with a real shape through yards, car parks and alleys, each
## from junction A along the street out of it, through the yard and along the next street to
## junction B. They are handed out like the cuts, by their own share (ladder.gd `yards`) and to a
## racer who dares their width (`narrow`: the narrowest link it takes), one way only, and only
## once the player's own car has driven them in the built city (the link's `proof`, set by
## check_lane_drive.gd --links --write): a racer goes only where the player can. A link is driven
## as one curve like a cut's (`curve`): a chain of cubic pieces through its points (LaneGraph
## `bezier` takes a chain), at LINK_TOP at most and the speed its bends allow (`speeds`).

const LaneGraph := preload("res://scripts/lane_graph.gd")

const PATH := "res://data/race_cuts.json"
const LINKS_PATH := "res://data/race_links.json"
## A link's points are spaced again this far apart for its curve (m): pieces of one length, so a
## curve's parameter runs with its metres.
const LINK_STEP := 3.0
## The fastest a racer drives a link (m/s, 43 km/h; a cut across a plaza: CUT_TOP, 58 km/h): a
## yard's way is narrow, with kerbs, posts and parked cars beside it.
const LINK_TOP := 12.0
## Shown with the knowledge hash so a link's draw is not a cut's of the same number.
const LINK_SEED := 7919
## A cut's end must lie this close to a graph node (a re-bake that moves junctions further drops
## the cut; check_race_cuts.gd fails when many do).
const SNAP := 4.0
## A metre across a plaza (kerbs, people, a slower line) is worth this much road in the routing.
const COST := 1.15
## The most a cut may turn into the road it joins (rad).
const EXIT_TURN := 1.75
## A cut is taken only when it saves this many metres (traffic.gd best_cut, through `cost`).
const GAIN := 12.0

var a := PackedInt32Array()
var b := PackedInt32Array()
var length := PackedFloat32Array()
## Per cut, the edges it may join: a -> b in exits_ab, b -> a in exits_ba.
var exits_ab: Array[PackedInt32Array] = []
var exits_ba: Array[PackedInt32Array] = []
## Per cut, its points between the two junctions for a race link (empty: a straight cut), its
## narrowest width (m; 99 for a straight cut) and its kind ("cut", "yard", "park").
var shape: Array[PackedVector2Array] = []
var width := PackedFloat32Array()
var kind := PackedStringArray()
## Per race link (from `first_link` on), its id in the file.
var link_id := PackedStringArray()
## Cuts in the file whose ends found no node.
var missed := 0
var total := 0
## Race links in their file, those with no proof that matches their points (never handed out),
## those whose ends found no node.
var links_total := 0
## The first race link's number (the cuts come first).
var first_link := 0
var links_unproven := 0
var links_missed := 0
## Load the links with no proof too (the proof drive: check_lane_drive.gd --links).
var with_unproven := false
## The links' points by the junctions they join, {Vector2i(a, b): PackedVector2Array}: the same
## for every RaceCuts loaded from the committed map (there is one), so a racer's table of plain
## numbers (`links`) finds a link's shape from the junctions alone (`curve`).
static var _shapes := {}
var _graph


## Reads the file and snaps every cut to the graph (an exact match first: the file is made from
## the same centrum.json; else the nearest node within SNAP).
func load_cuts(graph, path := PATH) -> void:
	a.clear()
	b.clear()
	length.clear()
	exits_ab.clear()
	exits_ba.clear()
	shape.clear()
	width.clear()
	kind.clear()
	link_id.clear()
	missed = 0
	total = 0
	_graph = graph
	var pending := _load_links(graph, LINKS_PATH if path == PATH else "")
	_read_cuts(graph, path)
	# The links after the cuts, so a cut keeps its number (and so who knows it, `knows`).
	first_link = a.size()
	for l: Array in pending:
		var na: int = l[0]
		var nb: int = l[1]
		var pts: PackedVector2Array = l[2]
		a.append(na)
		b.append(nb)
		length.append(l[3])
		exits_ab.append(_exits_along(graph, nb, (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()))
		exits_ba.append(PackedInt32Array())
		shape.append(pts)
		width.append(l[4])
		kind.append(l[5])
		link_id.append(l[6])


func _read_cuts(graph, path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("race cuts: %s does not parse" % path)
		return
	var exact := {}
	for n in graph.node_pos.size():
		var p: Vector2 = graph.node_pos[n]
		exact[Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))] = n
	for c: Array in parsed.get("cuts", []):
		total += 1
		var na := _node(graph, exact, Vector2(c[0], c[1]))
		var nb := _node(graph, exact, Vector2(c[2], c[3]))
		if na < 0 or nb < 0 or na == nb:
			missed += 1
			continue
		a.append(na)
		b.append(nb)
		length.append(graph.node_pos[na].distance_to(graph.node_pos[nb]))
		# A race link between the same two junctions: the link is that way (its curve, `curve`), the
		# cut is the other way only.
		exits_ab.append(PackedInt32Array() if _shapes.has(Vector2i(na, nb)) else _exits(graph, na, nb))
		exits_ba.append(PackedInt32Array() if _shapes.has(Vector2i(nb, na)) else _exits(graph, nb, na))
		shape.append(PackedVector2Array())
		width.append(99.0)
		kind.append("cut")


## The race links of `path` with a proof (none for ""): each a one-way cut from a to b with its
## points, as [a, b, points, metres, width, kind, id]; a link between two junctions that another link
## joins already is left out. Fills `_shapes`.
func _load_links(graph, path: String) -> Array:
	links_total = 0
	links_unproven = 0
	links_missed = 0
	_shapes.clear()
	var pending := []
	if path == "" or not FileAccess.file_exists(path):
		return pending
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("race links: %s does not parse" % path)
		return pending
	var exact := {}
	for n in graph.node_pos.size():
		var p: Vector2 = graph.node_pos[n]
		exact[Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))] = n
	for l: Dictionary in parsed.get("links", []):
		links_total += 1
		if String(l.get("proof", "")) != String(l.get("id", "")) or String(l.get("id", "")) == "":
			links_unproven += 1
			if not with_unproven:
				continue
		var na := _node(graph, exact, Vector2(l["a"][0], l["a"][1]))
		var nb := _node(graph, exact, Vector2(l["b"][0], l["b"][1]))
		if na < 0 or nb < 0 or na == nb or _shapes.has(Vector2i(na, nb)):
			links_missed += 1
			continue
		var flat: Array = l["p"]
		var pts := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[k], flat[k + 1]))
		if pts.size() < 2:
			links_missed += 1
			continue
		var metres: float = graph.node_pos[na].distance_to(pts[0]) + graph.node_pos[nb].distance_to(pts[pts.size() - 1])
		for k in range(1, pts.size()):
			metres += pts[k].distance_to(pts[k - 1])
		_shapes[Vector2i(na, nb)] = pts
		pending.append([na, nb, pts, metres, float(l.get("w", 3.5)), String(l.get("kind", "yard")), String(l.get("id", ""))])
	return pending


## The roads out of `to` a cut from `from` may join (open, turning at most EXIT_TURN).
static func _exits(graph, from: int, to: int) -> PackedInt32Array:
	return _exits_along(graph, to, (graph.node_pos[to] - graph.node_pos[from]).normalized())


## The roads out of junction `to` that a way coming in heading `chord` may join.
static func _exits_along(graph, to: int, chord: Vector2) -> PackedInt32Array:
	var out := PackedInt32Array()
	for g: int in graph.node_out[to]:
		if graph.e_shut[g] < INF:
			continue
		if absf(chord.angle_to(graph.direction(g, graph.e_s0[g]))) <= EXIT_TURN:
			out.append(g)
	return out


func _node(graph, exact: Dictionary, p: Vector2) -> int:
	var key := Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))
	if exact.has(key):
		return int(exact[key])
	var n: int = graph.nearest_node(p)
	if n >= 0 and graph.node_pos[n].distance_to(p) <= SNAP:
		return n
	return -1


## Whether a rival knowing `share` of the cuts (0-1), seeded by `seed` (its name), knows cut i.
static func knows(i: int, share: float, seed: int) -> bool:
	if share <= 0.0:
		return false
	if share >= 1.0:
		return true
	return posmod(hash(Vector2i(i, seed)), 1000) < int(share * 1000.0)


## The racer's cuts {node: PackedFloat32Array [edge on, metres, ...]} and the routing's links into
## each node {node: PackedFloat32Array [from, cost, ...]}, as [table, extra_in]: the straight cuts
## of `share`, and the race links of `yards` the racer dares (`narrow`: the narrowest it takes, m).
func links(share: float, seed: int, yards := 0.0, narrow := 99.0) -> Array:
	var table := {}
	var extra := {}
	for i in a.size():
		if shape[i].is_empty():
			if not knows(i, share, seed):
				continue
		elif width[i] < narrow or not knows(i - first_link + LINK_SEED, yards, seed):
			continue
		for way in 2:
			var from := a[i] if way == 0 else b[i]
			var exits: PackedInt32Array = exits_ab[i] if way == 0 else exits_ba[i]
			for g in exits:
				if not table.has(from):
					table[from] = PackedFloat32Array()
				table[from].append_array(PackedFloat32Array([g, length[i]]))
				var end: int = _end_of(g)
				if not extra.has(end):
					extra[end] = PackedFloat32Array()
				extra[end].append_array(PackedFloat32Array([from, cost(length[i], _len_of(g))]))
	return [table, extra]


## What a cut of `metres` then `edge_len` m of road costs in the routing.
static func cost(metres: float, edge_len: float) -> float:
	return metres * COST + edge_len + GAIN


func _end_of(g: int) -> int:
	return _graph.e_b[g]


func _len_of(g: int) -> float:
	return _graph.e_len[g]


## The curve a racer drives from the end of edge e (lane `lane`) over the cut or race link that
## joins edge g, into g's lane of the same number (or its last): a cut's one cubic piece, or a
## link's chain of pieces through its points (LaneGraph `bezier` and `bezier_length` take both).
static func curve(graph, e: int, lane: int, g: int) -> PackedVector2Array:
	var p0: Vector2 = graph.point_at(e, graph.e_s1[e], graph.lane_offset(e, lane))
	var d0: Vector2 = graph.direction(e, graph.e_s1[e])
	var p3: Vector2 = graph.point_at(g, graph.e_s0[g], graph.lane_offset(g, mini(lane, graph.e_lanes[g] - 1)))
	var d3: Vector2 = graph.direction(g, graph.e_s0[g])
	var key := Vector2i(graph.e_b[e], graph.e_a[g])
	if not _shapes.has(key):
		var reach := clampf(p0.distance_to(p3) * 0.25, 1.0, 8.0)
		return PackedVector2Array([p0, p0 + d0 * reach, p3 - d3 * reach, p3])
	var pts := PackedVector2Array([p0])
	pts.append_array(_shapes[key])
	pts.append(p3)
	return chain(pts, d0, d3)


## Whether a curve is a race link's chain (more than one cubic piece).
static func is_link(c: PackedVector2Array) -> bool:
	return c.size() > 4


## A chain of cubic pieces through `pts` (spaced again LINK_STEP m apart), leaving the first
## heading `d0` and arriving heading `d3`: [p0, c1, c2, p1, c1, c2, p2, ...], 3n + 1 points.
static func chain(pts: PackedVector2Array, d0: Vector2, d3: Vector2) -> PackedVector2Array:
	var cum := PackedFloat32Array([0.0])
	for k in range(1, pts.size()):
		cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
	var total := cum[cum.size() - 1]
	var n := maxi(ceili(total / LINK_STEP), 2)
	var even := PackedVector2Array([pts[0]])
	var k := 1
	for i in range(1, n):
		var at := total * i / n
		while k < pts.size() - 1 and cum[k] < at:
			k += 1
		var seg := maxf(cum[k] - cum[k - 1], 0.0001)
		even.append(pts[k - 1].lerp(pts[k], clampf((at - cum[k - 1]) / seg, 0.0, 1.0)))
	even.append(pts[pts.size() - 1])
	var m := even.size()
	var out := PackedVector2Array([even[0]])
	for i in m - 1:
		var before: Vector2 = even[i - 1] if i > 0 else even[0] - d0 * even[0].distance_to(even[1])
		var after: Vector2 = even[i + 2] if i + 2 < m else even[m - 1] + d3 * even[m - 1].distance_to(even[m - 2])
		out.append(even[i] + (even[i + 1] - before) / 6.0)
		out.append(even[i + 1] - (after - even[i]) / 6.0)
		out.append(even[i + 1])
	return out


## The speed (m/s) at each of a curve's `samples` + 1 points for a racer of grip `lat` (m/s²):
## what the bend there allows, `top` at most.
static func speeds(c: PackedVector2Array, lat: float, top: float, samples: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(samples + 1)
	var pull := lat
	var q := PackedVector2Array()
	for k in samples + 1:
		q.append(LaneGraph.bezier(c, float(k) / samples))
	for k in samples + 1:
		var a0 := q[maxi(k - 2, 0)]
		var a1 := q[k]
		var a2 := q[mini(k + 2, samples)]
		var turn := absf((a1 - a0).angle_to(a2 - a1))
		var arc := a0.distance_to(a1) + a1.distance_to(a2)
		var v := top
		if turn > 0.01 and arc > 0.01:
			v = minf(v, sqrt(pull * arc / turn))
		out[k] = v
	return out


## The slowest speed a curve's bends allow a racer of grip `lat` (m/s), `top` at most.
static func bend_speed(c: PackedVector2Array, lat: float, top: float) -> float:
	var v := top
	for x in speeds(c, lat, top, maxi(ceili(LaneGraph.bezier_length(c) / 2.0), 8)):
		v = minf(v, x)
	return v


## The seconds a racer of grip `lat` takes over a curve at its bends' speeds, `top` at most.
static func drive_time(c: PackedVector2Array, lat: float, top: float) -> float:
	var length := LaneGraph.bezier_length(c)
	var n := maxi(ceili(length / 2.0), 8)
	var v := speeds(c, lat, top, n)
	var t := 0.0
	for k in n:
		t += (length / n) / maxf((v[k] + v[k + 1]) * 0.5, 1.0)
	return t
