extends SceneTree
## The edge roadworks (2026-11-02, edge_roadworks.gd): every road that leaves the playable map is
## closed, from the committed map/centrum.json alone (no city built: CI runs it too):
##   W1 every road end at the map's outline is closed: the road crosses a closure's barrier line
##      where it crosses CLOSE_IN (or, running along the edge, ALONG_IN) m in; the ends that lead to
##      neither within WALK m (stubs inside the edge band) are counted and must stay few.
##   W2 the traffic's roads (the lane graph) too: every edge that ends at the outline with no way on
##      but back is shut (`e_shut`) SHUT_PAD short of a closure's barrier line, and every edge that
##      starts there opens (`e_open`) past one; no traffic spawn slot lies on a closed stretch.
##   W3 the barriers are solid: rays at bumper height along each closure (every metre across its
##      span) and along every shut lane hit the closures' collider before the edge wall.
##   W4 the budget: one surface per mesh, at most MAX_PIECE_TRIS triangles in a CHUNK square and
##      MAX_TRIS in all, the halos only in the night lights' group.
##   W5 the boards in both languages (lang.gd): English words, no wider than the Polish ones (the
##      board keeps its size by the barriers); a language change (`rebuild`) puts a new node with
##      its colliders and meshes in the old one's place.
## Prints `check_edge_roadworks: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_edge_roadworks.gd

const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

const MAX_PIECE_TRIS := 60000
const MAX_TRIS := 600000
## Road ends near the outline allowed to lead to no closure (a stub inside the edge band), at most.
const MAX_LOST := 10


## The map's shape without a city (as check_edge.gd): the outline, a flat world.
class FlatMap extends "res://scripts/map_builder.gd":
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func roof_height(_x: float, _z: float) -> float:
		return 0.0

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0

	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_edge_roadworks: no map/centrum.json")
		quit(1)
		return
	var map := FlatMap.new()
	var b: Array = data["bounds"]
	map.bounds = Rect2(b[0], b[1], float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	for o: Array in data.get("outside", []):
		map.outside.append(Rect2(o[0], o[1], float(o[2]) - float(o[0]), float(o[3]) - float(o[1])))
	map.data = data
	root.add_child(map)
	var list := EdgeRoadworks.closures(map)
	var w1 := _roads(map, data, list)
	var graph := LaneGraph.new(data["graph"], map)
	var w2 := _graph(map, graph, list)
	var works: Node3D = EdgeRoadworks.build(map, true)
	if works == null:
		problems.append("W3 no roadworks were built")
	else:
		map.add_child(works)
		map._build_edge_walls()
		for _i in 3:
			await physics_frame
		var w3 := _solid(map, graph, list, works)
		var w4 := _budget(works)
		w3 += "; " + _rails(map, works)
		w1 += "; W3 " + w3 + "; W4 " + w4 + "; W5 " + _boards() + ", " + await _relabel(map, works)
	map.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_edge_roadworks: OK (W1 %s; W2 %s)" % [w1, w2])
		quit(0)
	else:
		for p in problems.slice(0, 40):
			print("  PROBLEM " + p)
		print("check_edge_roadworks: %d problems" % problems.size())
		quit(1)


## Whether the piece of road from a to b crosses a closure's barrier line.
## `slack`: the line counts LaneGraph.END_SLACK longer at each end (the traffic's cut).
static func _closed_by(list: Array, a: Vector2, b: Vector2, slack := true) -> bool:
	for c: Dictionary in list:
		var d: Vector2 = c["dir"]
		var side := Vector2(d.y, -d.x) * (float(c["half"]) + (LaneGraph.END_SLACK if slack else 0.0))
		var at: Vector2 = c["at"]
		if at.distance_to(a) < 80.0 and Geometry2D.segment_intersects_segment(a, b, at - side, at + side) != null:
			return true
	return false


# --- W1 the roads ------------------------------------------------------------------------------

func _roads(map, data: Dictionary, list: Array) -> String:
	var ends := 0
	var along := 0
	var lost := 0
	var behind := 0
	var open := 0
	var roads: Array = data.get("roads", [])
	var joins := EdgeRoadworks._joins(roads)
	var segs := EdgeRoadworks._segments(roads)
	var tight := 0
	for ri in roads.size():
		var r: Dictionary = roads[ri]
		var flat: Array = r["p"]
		if flat.size() < 4:
			continue
		for first in [true, false]:
			var n := flat.size() / 2
			var i := 0 if first else n - 1
			if map.in_map(Vector2(flat[i * 2], flat[i * 2 + 1]), -EdgeRoadworks.EDGE_END):
				continue
			ends += 1
			var c := EdgeRoadworks.crossing(map, roads, joins, ri, first)
			if c.is_empty():
				c = EdgeRoadworks.crossing(map, roads, joins, ri, first, EdgeRoadworks.ALONG_IN)
				if not c.is_empty():
					along += 1
			if c.is_empty() and EdgeRoadworks.crossing(map, roads, joins, ri, first, 5.5).is_empty():
				behind += 1
				continue
			if c.is_empty():
				lost += 1
				if lost <= 60:
					print("  not closed: %s (%s) at %s" % [r.get("name", "?"), r.get("k", "?"), Vector2(flat[i * 2], flat[i * 2 + 1]).round()])
				continue
			var r0: Dictionary = roads[int(c["road"])]
			c["w"] = maxf(float(r0.get("w", 3.0)), 2.5)
			if EdgeRoadworks._tier_of(String(r0.get("k", "")), c["w"]) == EdgeRoadworks.Tier.SMALL \
					and EdgeRoadworks._tight(roads, segs, c):
				var out := EdgeRoadworks.crossing(map, roads, joins, ri, first, EdgeRoadworks.TIGHT_IN)
				if not out.is_empty():
					out["w"] = c["w"]
				if out.is_empty() or EdgeRoadworks._tight(roads, segs, out):
					tight += 1
					continue
				c = out
			var cd: Vector2 = c["dir"]
			if not _closed_by(list, (c["at"] as Vector2) - cd * 3.0, (c["at"] as Vector2) + cd * 3.0):
				open += 1
				if open <= 10:
					problems.append("W1 %s (%s) leaves the map at %s with no roadworks" % [r.get("name", "?"), r.get("k", "?"), (c["at"] as Vector2).round()])
	if lost > MAX_LOST:
		problems.append("W1 %d road ends near the outline lead to no closure (at most %d)" % [lost, MAX_LOST])
	var big := 0
	for c: Dictionary in list:
		if int(c["tier"]) == EdgeRoadworks.Tier.BIG:
			big += 1
	return "%d road ends at the outline, %d closures (%d big), %d closed along the edge, %d behind the wall, %d lanes beside a street left to the wall, %d lost in the edge band, %d open" % [ends, list.size(), big, along, behind, tight, lost, open]


# --- W2 the traffic -----------------------------------------------------------------------------

func _graph(map, g, list: Array) -> String:
	var dead := 0
	var bad := 0
	for e in g.e_a.size():
		var b: int = g.e_b[e]
		if not map.in_map(g.node_pos[b], -EdgeRoadworks.EDGE_END) and LaneGraph._dead_end(g.node_out[b], g.e_reverse[e]):
			dead += 1
			if g.e_shut[e] == INF:
				bad += 1
				problems.append("W2 edge %d (%s) runs off the map at %s and is not shut" % [e, g.e_name[e], g.node_pos[b].round()])
		var a: int = g.e_a[e]
		if not map.in_map(g.node_pos[a], -EdgeRoadworks.EDGE_END) and LaneGraph._dead_end(g.node_in[a], g.e_reverse[e]):
			dead += 1
			if g.e_open[e] == -INF:
				bad += 1
				problems.append("W2 edge %d (%s) comes in from the map's edge at %s and has no start past the barriers" % [e, g.e_name[e], g.node_pos[a].round()])
	# Where an edge is shut or opens part way, a closure's barrier line crosses it just beyond.
	var shut := 0
	var opened := 0
	var whole := 0
	for e in g.e_a.size():
		if g.e_shut[e] == 0.0 or g.e_open[e] == g.e_len[e]:
			whole += 1
		if g.e_shut[e] > 0.0 and g.e_shut[e] < INF:
			shut += 1
			var p: Vector2 = g.point_at(e, g.e_shut[e])
			if not _closed_by(list, p, p + g.direction(e, g.e_shut[e]) * 30.0):
				bad += 1
				problems.append("W2 edge %d (%s) is shut at %s, where no closure stands" % [e, g.e_name[e], p.round()])
		if g.e_open[e] > 0.0 and g.e_open[e] < g.e_len[e]:
			opened += 1
			var p: Vector2 = g.point_at(e, g.e_open[e])
			if not _closed_by(list, p, p - g.direction(e, g.e_open[e]) * 30.0):
				bad += 1
				problems.append("W2 edge %d (%s) opens at %s, where no closure stands" % [e, g.e_name[e], p.round()])
	return "%d traffic edges at the edge: %d shut and %d opened at a barrier line, %d wholly behind one, %d wrong" % [dead, shut, opened, whole, bad]


# --- W3 solid ------------------------------------------------------------------------------------

func _solid(map, g, list: Array, works: Node3D) -> String:
	var space: PhysicsDirectSpaceState3D = map.get_world_3d().direct_space_state
	var barriers := works.get_node("Barriers") as StaticBody3D
	var rays := 0
	var missed := 0
	for c: Dictionary in list:
		var d: Vector2 = c["dir"]
		var side := Vector2(d.y, -d.x)
		var half: float = c["half"]
		var x := -half + 0.3
		while x <= half - 0.3:
			var p: Vector2 = (c["at"] as Vector2) + side * x
			x += 1.0
			# A metre and a half each side of the line; not from behind the edge wall (no car there).
			if not map.in_map(p - d * 1.5, -5.5) or not map.in_map(p, -5.5):
				continue
			rays += 1
			if not _hits(space, p - d * 1.5, p + d * 1.5, barriers):
				missed += 1
				if missed <= 10:
					problems.append("W3 a car at %s drives through the roadworks %s (%s)" % [p.round(), (c["at"] as Vector2).round(), c["name"]])
	var lanes := 0
	var beside := 0
	for e in g.e_a.size():
		if g.e_shut[e] == INF or g.e_shut[e] <= 0.0:
			continue
		# A lane cut only for passing a line's end (END_SLACK) runs beside the barriers, not into them.
		var p0: Vector2 = g.point_at(e, g.e_shut[e])
		if not _closed_by(list, p0, p0 + g.direction(e, g.e_shut[e]) * 30.0, false):
			beside += 1
			continue
		for lane in g.e_lanes[e]:
			var off: float = g.lane_offset(e, lane)
			var a: Vector2 = g.point_at(e, maxf(g.e_shut[e] - 8.0, 0.0), off)
			# On straight past the shut point (the edge may end at a junction just before the line).
			var z: Vector2 = g.point_at(e, g.e_shut[e], off) + g.direction(e, g.e_shut[e]) * 32.0
			lanes += 1
			if not _hits(space, a, z, barriers):
				missed += 1
				if missed <= 20:
					problems.append("W3 lane %d of edge %d (%s) runs off the map at %s past the barriers" % [lane, e, g.e_name[e], z.round()])
	return "%d rays across %d closures and %d shut lanes (%d edges beside a line's end), %d through" % [rays, list.size(), lanes, beside, missed]


## Whether a ray at bumper height from a to b meets the barriers before anything else.
static func _hits(space: PhysicsDirectSpaceState3D, a: Vector2, b: Vector2, barriers: StaticBody3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(Vector3(a.x, 0.6, a.y), Vector3(b.x, 0.6, b.y))
	var hit := space.intersect_ray(q)
	return not hit.is_empty() and hit["collider"] == barriers


## PT-28 (2026-11-07, run 20261106-101542): the tram strip between Grochowska's two closed
## carriageways was open. Every tram strip between two closures is solid across (rays every half
## metre), and Grochowska's is one of them.
func _rails(map, works: Node3D) -> String:
	var space: PhysicsDirectSpaceState3D = map.get_world_3d().direct_space_state
	var barriers := works.get_node("Barriers") as StaticBody3D
	var gaps := EdgeRoadworks.rail_gaps(map)
	var rays := 0
	var grochowska := false
	for c: Dictionary in gaps:
		var d: Vector2 = c["dir"]
		var side := Vector2(d.y, -d.x)
		var half: float = c["half"]
		var at: Vector2 = c["at"]
		if at.distance_to(Vector2(2170, -1447)) < 15.0:
			grochowska = true
		var x := -half
		while x <= half:
			var p := at + side * x
			x += 0.5
			rays += 1
			if not _hits(space, p - d * 1.5, p + d * 1.5, barriers):
				problems.append("W3 the tram strip at %s is open past the barriers (PT-28)" % p.round())
	if not grochowska:
		problems.append("W3 Grochowska's tram strip at the east edge has no collider (PT-28)")
	return "%d tram strips closed (%d rays)" % [gaps.size(), rays]


# --- W5 the boards' languages ------------------------------------------------------------------

func _boards() -> String:
	var PixelFont := preload("res://scripts/pixel_font.gd")
	var out := []
	for pair: Array in [[EdgeRoadworks.works_lines(false), EdgeRoadworks.works_lines(true)],
			[EdgeRoadworks.detour_lines(false), EdgeRoadworks.detour_lines(true)]]:
		var w := [0, 0]
		for i in 2:
			for l: String in pair[i]:
				w[i] = maxi(w[i], PixelFont.width(l))
		if pair[0] == pair[1]:
			problems.append("W5 the board %s has no English" % " ".join(pair[0]))
		if w[1] > w[0]:
			problems.append("W5 the English board %s (%d px) is wider than the Polish (%d px)" % [" ".join(pair[1]), w[1], w[0]])
		out.append("%s/%s" % [" ".join(pair[0]), " ".join(pair[1])])
	return ", ".join(out)


## The language changes to English: the roadworks are made again, the old node gone.
func _relabel(map, old: Node3D) -> String:
	var Lang := preload("res://scripts/lang.gd")
	var polish := _tris(old)
	var was: String = Lang.code
	Lang.set_code(Lang.EN)
	EdgeRoadworks.rebuild(map)
	Lang.set_code(was)
	var works := map.get_node_or_null("EdgeRoadworks") as Node3D
	if works == null or works == old or is_instance_valid(old) and old.is_inside_tree():
		problems.append("W5 a language change did not make the roadworks again")
		return "no rebuild"
	if works.get_node_or_null("Barriers") == null:
		problems.append("W5 the rebuilt roadworks have no colliders")
	var t0 := Time.get_ticks_msec()
	var pieces := 0
	while Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		pieces = 0
		for n in works.get_children():
			if n is MeshInstance3D:
				pieces += 1
		if not works.has_meta(&"builder"):
			break
	if pieces == 0:
		problems.append("W5 the rebuilt roadworks have no meshes")
	# Other words, other glyphs: the same triangles would mean the boards stayed Polish.
	var english := _tris(works)
	if english == polish:
		problems.append("W5 the rebuilt roadworks have the Polish boards' triangles (%d)" % polish)
	return "rebuilt in English: %d pieces, %d -> %d triangles" % [pieces, polish, english]


static func _tris(works: Node3D) -> int:
	var n := 0
	for c in works.get_children():
		if c is MeshInstance3D:
			n += (c as MeshInstance3D).mesh.surface_get_array_len(0) / 3
	return n


# --- W4 the budget -------------------------------------------------------------------------------

func _budget(works: Node3D) -> String:
	var total := 0
	var pieces := 0
	var worst := 0
	var halos := 0
	for n in works.get_children():
		if n is MeshInstance3D:
			var mesh := (n as MeshInstance3D).mesh
			pieces += 1
			if mesh.get_surface_count() != 1:
				problems.append("W4 %s has %d surfaces (one draw call wanted)" % [n.name, mesh.get_surface_count()])
			var t: int = mesh.surface_get_array_len(0) / 3
			total += t
			worst = maxi(worst, t)
			if t > MAX_PIECE_TRIS:
				problems.append("W4 %s has %d triangles (at most %d)" % [n.name, t, MAX_PIECE_TRIS])
	var h := works.get_node_or_null("Halos")
	if h == null or not h.is_in_group("night_lights"):
		problems.append("W4 the halos are not in the night lights' group")
	else:
		for m in h.get_children():
			halos += (m as MultiMeshInstance3D).multimesh.instance_count
	if total > MAX_TRIS:
		problems.append("W4 %d triangles in all (at most %d)" % [total, MAX_TRIS])
	return "%d pieces, %d triangles (largest %d), %d halos" % [pieces, total, worst, halos]
