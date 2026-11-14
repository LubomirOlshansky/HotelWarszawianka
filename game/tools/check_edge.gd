extends SceneTree
## The L-shaped map loop (2026-10-31; docs/BACKLOG.md "From map north"): the gameplay that used the
## map's bounding rectangle keeps to its outline (map_builder.gd `in_map`, `map_outline`), from the
## committed map/centrum.json alone (no city built: CI runs it too):
##   E1 the helicopter's clamp (heli.gd `clamp_to_map`): 4,000 random moves from points on the map
##      end `in_map(p, -12)`; four flights past the inner corner (by the part left `outside`) with
##      the stick held into the part: inside every frame, sliding along the side it meets and
##      round the corner without a step back (jitter) or a stop; a push across a side slides
##      along it; a point inside the part (a teleport) goes out by the nearest inner side.
##   E2 the rescue spots (rescue_places.gd: streets, parks, the river, the hospitals) are all
##      `in_map(p, -40)`; the count the old rectangle would have let into the corner is printed.
##   E3 the minimap's mesh (hud.gd `_minimap_mesh`, the full map draws the same): no park, street or
##      tunnel triangle in a part left outside; the off-map ground covers each part whole; the
##      edge line has a vertex at the inner corner.
## Prints `check_edge: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_edge.gd

const Heli := preload("res://scripts/heli.gd")
const RescuePlaces := preload("res://scripts/rescue_places.gd")
const Hud := preload("res://scripts/hud.gd")

## The map's shape without a city: map_builder.gd's `in_map` and `map_outline` on the committed
## bounds and outside parts, a flat world with no roofs.
class FlatMap extends "res://scripts/map_builder.gd":
	func top_height(_x: float, _z: float, _r := 0.0) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func roof_height(_x: float, _z: float) -> float:
		return 0.0

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_edge: no map/centrum.json")
		quit(1)
		return
	var map := FlatMap.new()
	var b: Array = data["bounds"]
	map.bounds = Rect2(b[0], b[1], float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	for o: Array in data.get("outside", []):
		map.outside.append(Rect2(o[0], o[1], float(o[2]) - float(o[0]), float(o[3]) - float(o[1])))
	root.add_child(map)
	if map.outside.is_empty():
		problems.append("centrum.json has no `outside` part (the map is a box again?)")
	var e1 := _heli(map)
	var e2 := _missions(map, data)
	var e3 := await _minimap(map, data)
	map.free()
	if problems.is_empty():
		print("check_edge: OK (E1 %s; E2 %s; E3 %s)" % [e1, e2, e3])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_edge: %d problems" % problems.size())
		quit(1)


# --- E1 the helicopter -------------------------------------------------------------------------

func _heli(map: Node3D) -> String:
	var heli: Node3D = Heli.new()
	map.add_child(heli)
	heli.set_map(map)
	var pad: float = Heli.PAD
	# Random moves: from a point on the map (pad in), up to 60 m in any direction.
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var r: Rect2 = map.bounds
	var moves := 0
	var out := 0
	while moves < 4000:
		var from := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		if not map.in_map(from, -pad):
			continue
		var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 60.0)
		var got: Vector2 = heli.clamp_to_map(from, to)
		moves += 1
		if not map.in_map(got, -pad + 0.001):
			out += 1
			if out <= 3:
				problems.append("E1 a move %s -> %s ended at %s, off the map's outline (12 m in)" % [from.round(), to.round(), got])
	# The inner corner: the outline's point that turns the other way.
	var ring: PackedVector2Array = map.map_outline(-pad)
	var corner := Vector2.INF
	for k in ring.size():
		if not map._outline_convex(ring, k):
			corner = ring[k]
	if corner == Vector2.INF:
		problems.append("E1 the outline has no inner corner")
		heli.free()
		return "no corner"
	var g: Rect2 = heli.keep_out[0]
	# Past the inner corner: the map lies on the corner's sx side in x and sz side in z (for the
	# north-east part: west and south). Four flights with the stick held, each meeting a side of
	# the part and sliding along it round the corner.
	var sx := -1.0 if is_equal_approx(corner.x, g.position.x) else 1.0
	var sz := 1.0 if is_equal_approx(corner.y, g.end.y) else -1.0
	var flights := [
		["diagonal", corner + Vector2(sx, sz) * 40.0, Vector2(-sx, -sz)],
		["under, then up the side", corner + Vector2(sx * 60.0, sz * 2.0), Vector2(-sx, -sz * 0.1)],
		["down the side, round the corner", corner + Vector2(sx * 30.0, -sz * 30.0), Vector2(-sx, sz * 0.6)],
		["along the part's side, round the corner", corner + Vector2(-sx * 30.0, sz * 30.0), Vector2(sx * 0.6, -sz)],
	]
	var notes := PackedStringArray()
	for f: Array in flights:
		notes.append(_fly(map, heli, f[0], f[1], f[2], corner, pad))
	# Slides: pushed into the part across one side, it moves along the side, not stuck.
	var slide_x: Vector2 = heli.clamp_to_map(corner + Vector2(sx * 0.0, -sz * 50.0) + Vector2(sx * 1.0, 0.0),
			corner + Vector2(0.0, -sz * 52.0) + Vector2(-sx * 3.0, 0.0))
	if not is_equal_approx(slide_x.x, corner.x) or absf(slide_x.y - (corner.y - sz * 52.0)) > 0.01:
		problems.append("E1 a push across the part's side %s stopped at %s, not slid along it" % [corner, slide_x])
	# A teleport into the part: out by the nearest inner side.
	var inside := Vector2(g.position.x + 5.0, g.end.y - 8.0)
	var out_of: Vector2 = heli.clamp_to_map(inside, inside)
	if not map.in_map(out_of, -pad + 0.001) or out_of.distance_to(inside) > 8.01:
		problems.append("E1 a point inside the part %s went to %s (want the nearest inner side, 5 m)" % [inside, out_of])
	heli.free()
	return "%d random moves %d off; corner %s: %s" % [moves, out, corner.round(), ", ".join(notes)]


## One flight with the stick held, 20 s at 60 Hz through heli.gd's own step: never off the
## outline, never a step back against the way it moves (jitter), never stuck on a side, and it
## passes within 15 m of the corner.
func _fly(map: Node3D, heli: Node3D, name: String, start: Vector2, dir: Vector2, corner: Vector2, pad: float) -> String:
	heli.global_position = Vector3(start.x, 45.0, start.y)
	heli.vel = Vector3.ZERO
	heli.input_dir = Vector3(dir.x, 0.0, dir.y).normalized()
	var dt := 1.0 / 60.0
	var off := 0
	var back := 0
	var stuck := 0
	var touched := 0
	var nearest := INF
	var prev := start
	var step := Vector2.ZERO
	for k in 1200:
		heli._step(dt)
		var p := Vector2(heli.global_position.x, heli.global_position.z)
		if not map.in_map(p, -pad + 0.001):
			off += 1
		if heli.vel.x == 0.0 or heli.vel.z == 0.0:
			touched += 1
		var d := p - prev
		if k > 60 and d.dot(step) < -1e-7:
			back += 1
		if k > 60 and d.length() < 0.05:
			stuck += 1
		nearest = minf(nearest, p.distance_to(corner))
		step = d
		prev = p
	heli.input_dir = Vector3.ZERO
	if off > 0:
		problems.append("E1 %s: %d frames off the outline (12 m in)" % [name, off])
	if back > 0:
		problems.append("E1 %s: %d frames stepped back against its way (jitter at the edge)" % [name, back])
	if stuck > 0:
		problems.append("E1 %s: %d frames stuck on the edge (moved under 5 cm a frame)" % [name, stuck])
	if nearest > 15.0:
		problems.append("E1 %s: passed %.1f m from the corner (the flight misses it)" % [name, nearest])
	if touched == 0:
		problems.append("E1 %s: never met a side of the part" % name)
	return "%s: %d frames on a side, %.1f m from the corner" % [name, touched, nearest]


# --- E2 the rescue spots -----------------------------------------------------------------------

func _missions(map: Node3D, data: Dictionary) -> String:
	var m := RescuePlaces.new()
	m.map = map
	m.collect_road_names(data["roads"])
	m.find_streets(data["roads"])
	m.find_pois(data.get("pois", []))
	var n := 0
	var bad := 0
	var old_box := 0
	var inner: Rect2 = map.bounds.grow(-RescuePlaces.EDGE_PAD)
	var all: Array = []
	for k in m.by_kind:
		all.append_array(m.by_kind[k])
	all.append_array(m.hospitals)
	for pl: Dictionary in all:
		var at: Vector3 = pl.get("at", pl.get("pos", Vector3.INF))
		if at == Vector3.INF:
			continue
		var q := Vector2(at.x, at.z)
		n += 1
		if not map.in_map(q, -RescuePlaces.EDGE_PAD):
			bad += 1
			if bad <= 3:
				problems.append("E2 a rescue spot at %s is off the map's outline (40 m in)" % q.round())
	# What the bounding rectangle let in (the outline's corner, 40 m in): as a control.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 20000:
		var q := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if not map.in_map(q, -RescuePlaces.EDGE_PAD):
			old_box += 1
	if n == 0:
		problems.append("E2 no rescue spots found")
	return "%d rescue spots, %d off (the old box's area %.1f %% off the outline)" % [n, bad, old_box / 200.0]


# --- E3 the minimap --------------------------------------------------------------------------

func _minimap(map: Node3D, data: Dictionary) -> String:
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	hud.setup_minimap(data, map.map_outline(), map.outside)
	await process_frame
	var mesh: ArrayMesh = hud.get("_mini_mesh")
	var s: float = hud.get("_mini_scale")
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var drawn := 0
	var cover := {}
	var corner_vertex := false
	var corner := Vector2.INF
	var ring: PackedVector2Array = map.map_outline()
	for k in ring.size():
		if not map._outline_convex(ring, k):
			corner = ring[k]
	for t in range(0, verts.size() - 2, 3):
		var mid := (verts[t] + verts[t + 1] + verts[t + 2]) / (3.0 * s)
		var col := cols[t]
		for i in map.outside.size():
			var o: Rect2 = map.outside[i]
			if not o.has_point(mid):
				continue
			if col.is_equal_approx(Hud.OFF_MAP):
				var a := verts[t] / s
				var c := verts[t + 1] / s
				var e := verts[t + 2] / s
				cover[i] = float(cover.get(i, 0.0)) + absf((c - a).cross(e - a)) * 0.5
			elif not col.is_equal_approx(Color("#6a503b")):
				drawn += 1
		for v in 3:
			if (verts[t + v] / s).distance_to(corner) < 3.0 * hud.pt / s:
				corner_vertex = true
	if drawn > 0:
		problems.append("E3 %d park, street or tunnel triangles of the minimap lie in a part left outside" % drawn)
	for i in map.outside.size():
		var o: Rect2 = (map.outside[i] as Rect2).intersection(map.bounds)
		var area := float(cover.get(i, 0.0))
		if absf(area - o.get_area()) > o.get_area() * 0.001:
			problems.append("E3 the off-map ground covers %.0f m² of the outside part's %.0f m²" % [area, o.get_area()])
	if not corner_vertex:
		problems.append("E3 the minimap's edge line has no vertex at the inner corner %s" % corner)
	vp.free()
	return "%d triangles, 0 drawn in the corner left outside, the off-map ground over it whole" % (verts.size() / 3)
