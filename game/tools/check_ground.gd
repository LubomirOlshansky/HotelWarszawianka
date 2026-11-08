extends SceneTree
## Loop 3d-2a: the ground mesh over the whole map, from the builder's own meshes
## (map_builder.gd `_build_ground`: the terrain grid's two triangles per 10 m cell, 1 m sub-cells
## where an apron lowers the ground, the earth walls at the map's edge).
##
## 1. Counts: the ground's triangles and vertices (10 m cells, apron sub-cells, edge walls), each
##    flat layer's vertices, and with --sectors the ground per 512 m sector.
## 2. Hidden ground (the defect class): ground triangles a flat layer on the ground (roads and
##    carriageway areas, the water, grass, parks, plazas, sand, paving, footways, steps, rail
##    beds) covers whole, grown by MapBuilder.COVER_MARGIN: drawn for nothing (Slop New York's
##    "faces over roads"). "under roads" counts those the road surface alone covers; the cells
##    MapBuilder.ground_kept keeps (the map's edge, near approaches and aprons) are listed apart.
## 3. Holes: a 10 m cell's triangle with no ground drawn that the flat layers don't cover
##    (grown the same way): bare sky through the map. Must be 0.
## 4. Heights: every ground vertex lies on the height rule (`_drawn_height`, what
##    check_roads.py `Map.drawn` mirrors) within HEIGHT_TOL. Must hold.
## 5. Flatness: the share of 10 m cells whose four corners lie within 0.02 / 0.15 m of a plane.
##
## Prints `check_ground: OK` when 3 and 4 hold and the hidden ground is at most HIDDEN_MAX
## triangles; else exit 1. ~2 min (the city built in one go, then the cover tests).
##   godot --headless --path game --script res://tools/check_ground.gd [-- --sectors --verbose --whole]
## --whole builds the ground as before loop 3d-2a (MapBuilder.ground_lean off): the before count.
## --dump=FILE writes the drawn ground triangles and the 10 m halves left out (JSON, map metres) for
## tools/overlay_ground.py (the ground's wireframe over the aerial photo).

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"
const HEIGHT_TOL := 0.02
## Hidden ground triangles allowed. Before loop 3d-2a 99,401 (1,284 under roads alone); the
## builder leaves out what its own quick point tests and Clipper agree on, and a handful of
## triangles whose test points fall on a seam between two pieces stay (6 on the demo map).
const HIDDEN_MAX := 30
## The flat layers that hide the ground under them are told by their depth bias (UV.x): the ones
## the builder laid while it noted cover (MapBuilder.cover_biases: the areas 0.01, paving 0.08,
## footways and steps 0.1, the cutting's floor 0.16, rail beds 0.18 / 0.2, minor roads 0.25, roads
## 0.3), tested by height below. Islands, medians, kerbs, markings and rails lie over these. A
## list kept here by hand fell behind three new covering layers, and their ground read as holes.
const ROAD_LAYER := 6
## A cover triangle is on the ground when its centre lies within MapBuilder.COVER_GRADE of the grid
## (decks over it, tunnels under it, approaches over the grid and pieces sunk under a hump are not).


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var verbose := "--verbose" in args
	var per_sector := "--sectors" in args
	var t0 := Time.get_ticks_msec()
	var map: Node3D = MapBuilder.new()
	map.ground_lean = not "--whole" in args
	root.add_child(map)
	var flat := ShaderMaterial.new()
	map.build(MAP_PATH, ShaderMaterial.new(), flat)
	var t_build := Time.get_ticks_msec() - t0
	var terrain: Dictionary = map._terrain
	var step := float(terrain["step"])
	var gx := float(terrain["x0"])
	var gz := float(terrain["z0"])
	var nx := int(terrain["nx"])
	var nz := int(terrain["nz"])
	var th: PackedFloat32Array = map._t_h
	map._fine_index()
	var fine: Dictionary = map._fine_cells

	var layer_verts := {}
	var ground := PackedVector3Array()  # 3 per triangle
	var walls := 0
	var cover := PackedVector2Array()  # 3 per triangle
	var cover_road := PackedByteArray()
	var off_grade := PackedVector3Array()  # diagnostics: cover-layer triangles off the ground's height (y: dy, layer)
	var worst_h := 0.0
	var worst_at := Vector2.ZERO
	for c in map.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.material_override != flat or mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count := idx.size() if idx.size() > 0 else v.size()
			for t in range(0, count, 3):
				var i0 := idx[t] if idx.size() > 0 else t
				var a := v[i0]
				var b := v[idx[t + 1] if idx.size() > 0 else t + 1]
				var cc := v[idx[t + 2] if idx.size() > 0 else t + 2]
				var id := int(round(uv[i0].y))
				var bias := uv[i0].x
				layer_verts[id] = int(layer_verts.get(id, 0)) + 3
				if id < 0:
					var up := absf((b - a).cross(cc - a).normalized().y)
					if up < 0.3:
						walls += 1
						continue
					ground.append_array([a, b, cc])
					for p: Vector3 in [a, b, cc, (a + b + cc) / 3.0]:
						var dh: float = absf(p.y - map._drawn_height(p.x, p.z))
						if dh > worst_h:
							worst_h = dh
							worst_at = Vector2(p.x, p.z)
					continue
				if not map.cover_biases.has(snappedf(bias, 0.0001)):
					continue
				var m := (a + b + cc) / 3.0
				var dy: float = m.y - map._grid_height(m.x, m.z)
				if dy < MapBuilder.COVER_GRADE.x or dy > MapBuilder.COVER_GRADE.y:
					off_grade.append_array([Vector3(a.x, dy, a.z), Vector3(b.x, id, b.z), Vector3(cc.x, 0.0, cc.z)])
					continue
				cover.append_array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(cc.x, cc.z)])
				cover_road.append(1 if id == ROAD_LAYER else 0)

	# The cover triangles per 10 m cell of the grid (by their boxes).
	var cells := {}
	var ncov := cover.size() / 3
	for k in ncov:
		var a := cover[k * 3]
		var b := cover[k * 3 + 1]
		var cc := cover[k * 3 + 2]
		var lo := a.min(b).min(cc)
		var hi := a.max(b).max(cc)
		for j in range(floori((lo.y - gz) / step), floori((hi.y - gz) / step) + 1):
			for i in range(floori((lo.x - gx) / step), floori((hi.x - gx) / step) + 1):
				var key := Vector2i(i, j)
				var list: PackedInt32Array = cells.get(key, PackedInt32Array())
				list.append(k)
				cells[key] = list

	# The ground drawn: per 10 m cell's half (0: the u >= v triangle, 1: the other) and per sector.
	var drawn := {}
	var sector_tris := {}
	var n_ground := ground.size() / 3
	var n_fine := 0
	var hidden := 0
	var hidden_road := 0
	var hidden_kept := 0
	var hidden_spots: Array = []
	for k in n_ground:
		var a := ground[k * 3]
		var b := ground[k * 3 + 1]
		var cc := ground[k * 3 + 2]
		var m := (a + b + cc) / 3.0
		var fx := (m.x - gx) / step
		var fz := (m.z - gz) / step
		var cell := Vector2i(floori(fx), floori(fz))
		var sk := Vector2i(floori(m.x / 512.0), floori(m.z / 512.0))
		sector_tris[sk] = int(sector_tris.get(sk, 0)) + 1
		if fine.has(cell):
			n_fine += 1
			continue
		var half := 0 if fx - cell.x >= fz - cell.y else 1
		drawn[Vector3i(cell.x, cell.y, half)] = true
		var tri := _cell_tri(gx + cell.x * step, gz + cell.y * step, step, half)
		var got := _covered(tri, cell, cells, cover, cover_road)
		if got > 0 and map.ground_kept(cell.x, cell.y):
			hidden_kept += 1
		elif got > 0:
			hidden += 1
			if got == 2:
				hidden_road += 1
			if hidden_spots.size() < 20:
				hidden_spots.append(Vector2(m.x, m.z))

	# Holes: a 10 m cell's triangle not drawn and not covered.
	var holes := 0
	var dropped := 0
	var hole_spots: Array = []
	for j in nz - 1:
		for i in nx - 1:
			var cell := Vector2i(i, j)
			if fine.has(cell):
				continue
			# Map north: no ground where the map isn't (map_builder _cell_outside: the corner left outside).
			if map.has_method("_cell_outside") and not map.outside.is_empty() and map._cell_outside(gx + i * step, gz + j * step, step):
				continue
			for half in 2:
				if drawn.has(Vector3i(i, j, half)):
					continue
				dropped += 1
				var x := gx + i * step
				var z := gz + j * step
				var tri := _cell_tri(x, z, step, half)
				if _covered(tri, cell, cells, cover, cover_road) == 0:
					if verbose:
						var box := Rect2(x - 1.0, z - 1.0, step + 2.0, step + 2.0)
						var notes := PackedStringArray()
						for q in range(0, off_grade.size(), 3):
							if box.has_point(Vector2(off_grade[q].x, off_grade[q].z)):
								notes.append("L%d dy %.2f" % [int(off_grade[q + 1].y), off_grade[q].y])
						print("  hole at --at=%.0f,%.0f half %d; off-grade layers there: %s" % [x + 5.0, z + 5.0, half, ", ".join(notes.slice(0, 6))])
					holes += 1
					if hole_spots.size() < 20:
						hole_spots.append(Vector2(x + step * 0.5, z + step * 0.5))

	# Flatness of the 10 m cells: the four corners' distance from their best plane is |twist| / 4.
	var flat2 := 0
	var flat15 := 0
	for j in nz - 1:
		for i in nx - 1:
			var k := j * nx + i
			var twist := absf(th[k] - th[k + 1] - th[k + nx] + th[k + nx + 1]) * 0.25
			flat2 += 1 if twist <= 0.02 else 0
			flat15 += 1 if twist <= 0.15 else 0
	var n_cells := (nx - 1) * (nz - 1)

	var total_flat := 0
	for id in layer_verts:
		total_flat += int(layer_verts[id])
	print("check_ground: ground %d triangles (%d vertices): %d in 10 m cells' halves of %d, %d in the 1 m sub-cells of %d apron cells, %d edge-wall triangles · the flat mesh %d vertices" % [
			n_ground, n_ground * 3, n_ground - n_fine, n_cells * 2, n_fine, fine.size(), walls, total_flat])
	var ids := layer_verts.keys()
	ids.sort()
	var parts := PackedStringArray()
	for id in ids:
		parts.append("%d: %d" % [id, int(layer_verts[id])])
	print("check_ground: flat-mesh vertices by layer (UV.y; -1 the ground and edge walls): %s" % ", ".join(parts))
	print("check_ground: hidden ground (covered whole by the flat layers on it, grown %.1f m): %d triangles, %d of them under roads alone · %d more kept on purpose (map edge, approaches, aprons) · 10 m halves not drawn %d" % [
			MapBuilder.COVER_MARGIN, hidden, hidden_road, hidden_kept, dropped])
	print("check_ground: holes (not drawn, not covered): %d" % holes)
	print("check_ground: heights: the worst ground point %.3f m off the height rule at %.0f, %.0f (allowed %.2f)" % [
			worst_h, worst_at.x, worst_at.y, HEIGHT_TOL])
	print("check_ground: flat 10 m cells (corners within 0.02 / 0.15 m of a plane): %.1f %% / %.1f %% of %d" % [
			100.0 * flat2 / n_cells, 100.0 * flat15 / n_cells, n_cells])
	if per_sector:
		var keys := sector_tris.keys()
		keys.sort()
		for key: Vector2i in keys:
			print("  sector %d_%d: %d ground triangles" % [key.x, key.y, int(sector_tris[key])])
	if verbose:
		for p: Vector2 in hidden_spots:
			print("  hidden at --at=%.0f,%.0f" % [p.x, p.y])
		for p: Vector2 in hole_spots:
			print("  HOLE at --at=%.0f,%.0f" % [p.x, p.y])
	for arg in args:
		if arg.begins_with("--dump="):
			var tris := PackedFloat32Array()
			for p in ground:
				tris.append_array([snappedf(p.x, 0.01), snappedf(p.z, 0.01)])
			var left := PackedInt32Array()
			for j in nz - 1:
				for i in nx - 1:
					for half in 2:
						if not fine.has(Vector2i(i, j)) and not drawn.has(Vector3i(i, j, half)):
							left.append_array([i, j, half])
			var f := FileAccess.open(arg.trim_prefix("--dump="), FileAccess.WRITE)
			f.store_string(JSON.stringify({"x0": gx, "z0": gz, "step": step, "ground": Array(tris), "left": Array(left)}))
			f.close()
	# The covering layers' biases must be theirs alone, or a layer over them would count as cover.
	var shared := PackedStringArray()
	for b: float in map.cover_biases:
		if map.other_biases.has(b):
			shared.append("%.4f" % b)
	var cb := PackedStringArray()
	for b: float in map.cover_biases:
		cb.append("%.3f" % b)
	cb.sort()
	print("check_ground: covering layers' depth biases %s%s" % [", ".join(cb),
			(" · ALSO used by layers that don't cover: %s" % ", ".join(shared)) if not shared.is_empty() else ""])
	var ok: bool = holes == 0 and worst_h <= HEIGHT_TOL and hidden <= HIDDEN_MAX and shared.is_empty() and not map.cover_biases.is_empty()
	print("check_ground: %s · ground %d triangles (%d 10 m halves left out), hidden %d (max %d), holes %d, heights off by %.3f m · %d ms (build %d)" % [
			"OK" if ok else "FAIL", n_ground, dropped, hidden, HIDDEN_MAX, holes, worst_h, Time.get_ticks_msec() - t0, t_build])
	map.free()
	quit(0 if ok else 1)


## A 10 m cell's triangle as the builder tests it (half 0: (0,0)-(1,0)-(1,1)), wound the same way.
func _cell_tri(x: float, z: float, step: float, half: int) -> PackedVector2Array:
	if half == 0:
		return PackedVector2Array([Vector2(x, z), Vector2(x + step, z), Vector2(x + step, z + step)])
	return PackedVector2Array([Vector2(x, z), Vector2(x + step, z + step), Vector2(x, z + step)])


## 0: not covered; 1: covered by the flat layers; 2: by the road surface alone.
func _covered(tri: PackedVector2Array, cell: Vector2i, cells: Dictionary, cover: PackedVector2Array,
		cover_road: PackedByteArray) -> int:
	var grown: PackedVector2Array = Geometry2D.offset_polygon(tri, MapBuilder.COVER_MARGIN, Geometry2D.JOIN_SQUARE)[0]
	var lo := grown[0]
	var hi := grown[0]
	for q in grown:
		lo = lo.min(q)
		hi = hi.max(q)
	var seen := {}
	var pieces: Array[PackedVector2Array] = []
	var roads: Array[PackedVector2Array] = []
	for dj in range(-1, 2):
		for di in range(-1, 2):
			for k: int in cells.get(cell + Vector2i(di, dj), PackedInt32Array()):
				if seen.has(k):
					continue
				seen[k] = true
				var p := PackedVector2Array([cover[k * 3], cover[k * 3 + 1], cover[k * 3 + 2]])
				var plo := p[0].min(p[1]).min(p[2])
				var phi := p[0].max(p[1]).max(p[2])
				if plo.x < hi.x and phi.x > lo.x and plo.y < hi.y and phi.y > lo.y:
					pieces.append(p)
					if cover_road[k] == 1:
						roads.append(p)
	if pieces.is_empty() or not MapBuilder.covers(grown, pieces):
		return 0
	return 2 if not roads.is_empty() and MapBuilder.covers(grown, roads) else 1
