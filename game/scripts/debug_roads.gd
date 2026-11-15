extends Node3D
## Loop 3a: `--debug-roads` draws what the road bake decided round the car, with the Debug
## Draw add-on (HardPixel, MIT, game/addons/debug_draw): the bridge decks' corridors at their
## height (orange roads, yellow footways, red tracks), the approaches that correct the ground
## (green), the tunnels (magenta), every lane at the height the traffic uses (blue; violet in a
## tunnel; RT-4: from its edge's s0 to s1, with the links across each node in amber) and the piers under the decks (cyan boxes; loop 3b: the bake's `decks.piers`). A testing aid
## only: nothing loads the add-on without the flag.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const REACH := 140.0
const REFRESH := 30.0

var map: Node3D
var graph: LaneGraph
var focus: Callable
var _draw: Node3D
var _centre := Vector2(INF, INF)
## Cached strips near the focus: [PackedVector3Array, Color] each, and pier boxes
## [Vector3 centre, Quaternion, Vector3 size].
var _strips: Array = []
var _boxes: Array = []
## Loop 3b: the bake's pier boxes (`decks.piers`; the prebuilt city keeps no map data).
var _pier_list: Array = []


func setup(map_node: Node3D, lane_graph: LaneGraph, focus_fn: Callable, map_data := {}) -> void:
	map = map_node
	_pier_list = map_data.get("decks", {}).get("piers", [])
	graph = lane_graph
	focus = focus_fn
	_draw = (load("res://addons/debug_draw/debug_draw_3d.tscn") as PackedScene).instantiate()
	add_child(_draw)
	# The game's post pass (post.gdshader) is a transparent quad that redraws the screen from
	# the opaque pass: the add-on's lines (transparent, drawn first) must come after it.
	for child in _draw.get_children():
		if child is MultiMeshInstance3D and (child as MultiMeshInstance3D).material_override != null:
			(child as MultiMeshInstance3D).material_override.render_priority = Material.RENDER_PRIORITY_MAX


func _process(_delta: float) -> void:
	var f: Vector3 = focus.call()
	var p := Vector2(f.x, f.z)
	if p.distance_to(_centre) > REFRESH:
		_centre = p
		_collect()
	for s in _strips:
		_draw.draw_line_strip(s[0], s[1], 3.0)
	for b in _boxes:
		_draw.draw_box(b[0], b[1], b[2], Color(0.2, 0.9, 1.0), 3.0)


func _collect() -> void:
	_strips.clear()
	_boxes.clear()
	var area := Rect2(_centre - Vector2.ONE * REACH, Vector2.ONE * REACH * 2.0)
	var decks := 0
	for d: Dictionary in map._decks:
		var pts: PackedVector2Array = d["pts"]
		if not _touches(pts, area):
			continue
		decks += 1
		var col := Color(1.0, 0.55, 0.1)
		match String(d["k"]):
			"path":
				col = Color(1.0, 0.9, 0.2)
			"tram", "rail":
				col = Color(1.0, 0.25, 0.25)
		_edges(pts, d["h"], float(d["l"]), float(d["r"]), 0.1, col)
	_piers(area)
	var fills := 0
	for d: Dictionary in map._fills:
		if _touches(d["pts"], area):
			fills += 1
			_edges(d["pts"], d["h"], float(d["l"]), float(d["r"]), 0.15, Color(0.3, 1.0, 0.4))
	var tunnels := 0
	for d: Dictionary in map._tunnels:
		if _touches(d["pts"], area):
			tunnels += 1
			_edges(d["pts"], d["h"], float(d["l"]), float(d["r"]), 0.1, Color(1.0, 0.3, 1.0))
	var lanes := 0
	if graph != null:
		for e in graph.e_a.size():
			var i0 := graph.e_first[e]
			var near := false
			for k in graph.e_count[e]:
				if area.has_point(graph.pts[i0 + k]):
					near = true
					break
			if not near:
				continue
			for lane in graph.e_lanes[e]:
				lanes += 1
				var line := PackedVector3Array()
				var s := graph.e_s0[e]
				while true:
					var q := graph.point_at(e, s, graph.lane_offset(e, lane))
					line.append(Vector3(q.x, graph.height(e, s) + 0.3, q.y))
					if s >= graph.e_s1[e]:
						break
					s = minf(s + 4.0, graph.e_s1[e])
				_strips.append([line, Color(0.75, 0.35, 1.0) if graph.e_tn[e] >= 0 else Color(0.3, 0.55, 1.0)])
				# RT-4: the links a car drives across the node, lane to lane (lane_graph.gd
				# `connector`), so a lane that jumps sideways between two ways shows
				_links(e, lane)
	print("debug roads: near (%.0f, %.0f): %d deck pieces, %d approaches, %d tunnel pieces, %d lanes, %d piers" % [
			_centre.x, _centre.y, decks, fills, tunnels, lanes, _boxes.size()])


## The curves from lane k of edge e into each way on it may take (amber), at the traffic's height.
func _links(e: int, k: int) -> void:
	var y0 := graph.height(e, graph.e_s1[e]) + 0.3
	for f: int in graph.node_out[graph.e_b[e]]:
		if f == graph.e_reverse[e] or not graph.lane_allows(e, k, f):
			continue
		var c := graph.connector(e, k, f, graph.next_lane(e, k, f))
		var y1 := graph.height(f, graph.e_s0[f]) + 0.3
		var line := PackedVector3Array()
		for i in 13:
			var t := i / 12.0
			var q := LaneGraph.bezier(c, t)
			line.append(Vector3(q.x, lerpf(y0, y1, t), q.y))
		_strips.append([line, Color(1.0, 0.7, 0.1)])


func _touches(pts: PackedVector2Array, area: Rect2) -> bool:
	for q in pts:
		if area.has_point(q):
			return true
	return false


## The corridor's two edges at the piece's height, lifted a little off the surface.
func _edges(pts: PackedVector2Array, hs: PackedFloat32Array, l: float, r: float, lift: float, col: Color) -> void:
	for side in [-l, r]:
		var line := PackedVector3Array()
		for k in pts.size():
			var a := pts[maxi(k - 1, 0)]
			var b := pts[mini(k + 1, pts.size() - 1)]
			var dir := (b - a).normalized()
			var q: Vector2 = pts[k] + Vector2(-dir.y, dir.x) * side
			line.append(Vector3(q.x, hs[k] + lift, q.y))
		_strips.append([line, col])


## Loop 3b: the bake's piers, portal legs and cap beams (`decks.piers`) inside the area.
func _piers(area: Rect2) -> void:
	for p: Dictionary in _pier_list:
		var c := Vector2(float(p["c"][0]), float(p["c"][1]))
		if not area.has_point(c):
			continue
		var dir := Vector2(float(p["d"][0]), float(p["d"][1]))
		var y0 := float(p["y"][0])
		var y1 := float(p["y"][1])
		_boxes.append([Vector3(c.x, (y0 + y1) * 0.5, c.y), Quaternion(Vector3.UP, atan2(-dir.x, -dir.y)),
				Vector3(float(p["s"][0]), y1 - y0, float(p["s"][1]))])
