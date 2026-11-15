extends SceneTree
## A sector is the same whatever was built before it (docs/DEMO.md 2.4; the streamer builds them in
## whatever order the car drives, bake_city.gd in index order).
##
## Builds every sector from its file twice, with two fresh builders: in index order and in reverse
## order, and compares each sector's meshes, MultiMeshes and collider faces (the same hashes as
## check_streaming.gd's identity part, but per sector, so a difference names the sector that
## changed). A difference means `build_sector` reads state an earlier sector left behind.
## `--dump=FILE` also writes every sector's hashes (index order) as JSON, to diff two builds of the code.
## Needs a renderer and the sector split (tools/bake_sectors.py): a window opens.
##   godot --path game --resolution 320x180 --script res://tools/check_sector_order.gd [-- --verbose]
## A mesh whose vertices are the same set in another order is counted apart (`order only`), not a failure.
## Prints `check_sector_order: OK` (exit 0) or the sectors that differ (exit 1).

const MapBuilder := preload("res://scripts/map_builder.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var verbose := "--verbose" in OS.get_cmdline_user_args()
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var keys: Array = index["sectors"]["keys"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sectors="):
			var want := a.trim_prefix("--sectors=").split(",")
			keys = keys.filter(func(k: Array) -> bool: return ("%d_%d" % [int(k[0]), int(k[1])]) in want)
	var fwd := _build_all(index, keys)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dump="):
			# Every sector's hashes in index order, for comparing two builds of the code (before/after a change).
			var f := FileAccess.open(a.trim_prefix("--dump="), FileAccess.WRITE)
			f.store_string(JSON.stringify(fwd, "", true))
			f.close()
	var rev_keys := keys.duplicate()
	rev_keys.reverse()
	var rev := _build_all(index, rev_keys)
	var bad := 0
	var order_only := 0
	if keys.is_empty() or fwd.size() != keys.size() or rev.size() != keys.size():
		print("check_sector_order: FAIL (built %d and %d of %d sectors)" % [fwd.size(), rev.size(), keys.size()])
		quit(1)
		return
	for k in fwd:
		var a: Dictionary = fwd[k]
		var b: Dictionary = rev.get(k, {})
		var diff := 0
		for item: String in a:
			if b.has(item) and a[item] == b[item]:
				continue
			# A mesh or MultiMesh whose vertices and instances are the same set in another order (its
			# "as a set" entry matches) differs in triangle order only: drawn the same, counted apart.
			if not item.ends_with(" (vertices as a set)") and not item.ends_with(" (instances as a set)") and \
					(a.has(item + " (vertices as a set)") or a.has(item + " (instances as a set)")):
				var twin := item + (" (vertices as a set)" if a.has(item + " (vertices as a set)") else " (instances as a set)")
				if b.has(twin) and a[twin] == b[twin]:
					order_only += 1
					if verbose:
						print("  sector %s: %s: triangle or instance order only" % [k, item])
					continue
			diff += 1
			if verbose:
				print("  sector %s: %s differs: %s vs %s" % [k, item, a[item], b.get(item)])
		for item in b:
			if not a.has(item):
				diff += 1
		if diff > 0:
			bad += 1
			print("  sector %s: %d meshes, MultiMeshes or collider sets differ by build order" % [k, diff])
	if bad == 0:
		print("check_sector_order: OK (%d sectors, forward and reverse order give the same geometry; %d meshes differ in triangle order only)" % [keys.size(), order_only])
		quit(0)
	else:
		print("check_sector_order: FAIL (%d of %d sectors depend on the build order)" % [bad, keys.size()])
		quit(1)


## sector key -> {item: [count, hash]}; a fresh builder, the sectors built in `order`.
func _build_all(index: Dictionary, order: Array) -> Dictionary:
	var parts: Node3D = MapBuilder.new()
	root.add_child(parts)
	parts.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var out := {}
	for k: Array in order:
		var sector: Node3D = parts.build_sector(Vector2i(int(k[0]), int(k[1])))
		parts.add_child(sector)
		out["%d_%d" % [int(k[0]), int(k[1])]] = _collect(sector, parts)
	parts.free()
	return out


func _collect(node: Node, builder: Node3D) -> Dictionary:
	var out := {}
	var faces := {}
	for n in node.find_children("*", "", true, false):
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh is ArrayMesh:
			var arrays := (mi.mesh as ArrayMesh).surface_get_arrays(0)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var c := (v[0] + v[1] + v[2]) / 3.0
			var key := "mesh %s tile %d,%d" % [_kind(mi.material_override, builder), floori(c.x / 256.0), floori(c.z / 256.0)]
			out[key] = [v.size(), hash(arrays)]
			var sum := 0
			for i in v.size():
				sum += hash(v[i])
			out[key + " (vertices as a set)"] = [v.size(), sum]
			continue
		var mmi := n as MultiMeshInstance3D
		if mmi != null and mmi.multimesh.instance_count > 0:
			var mm := mmi.multimesh
			var o := mm.get_instance_transform(0).origin
			var key := "multimesh %s %s tile %d,%d" % [_kind(mmi.material_override, builder),
					n.get_parent().name if n.get_parent().name in ["LampHalos", "Neon"] else "", floori(o.x / 512.0), floori(o.z / 512.0)]
			# Node names are numbered in build order; sibling MultiMeshes of one kind are told apart by their place in the sector.
			var base_key := key
			var dup := 1
			while out.has(key):
				dup += 1
				key = "%s #%d" % [base_key, dup]
			out[key] = [mm.instance_count, hash(mm.buffer)]
			var isum := 0
			for i in mm.instance_count:
				isum += hash(mm.get_instance_transform(i))
			out[key + " (instances as a set)"] = [mm.instance_count, isum]
			continue
		var cs := n as CollisionShape3D
		if cs != null and cs.shape is ConcavePolygonShape3D:
			var f := (cs.shape as ConcavePolygonShape3D).get_faces()
			for i in range(0, f.size() - 2, 3):
				var h := hash([f[i], f[i + 1], f[i + 2]])
				faces[h] = int(faces.get(h, 0)) + 1
		elif cs != null and cs.shape is BoxShape3D:
			var h := hash([cs.position, (cs.shape as BoxShape3D).size])
			faces[h] = int(faces.get(h, 0)) + 1
	var fsum := 0
	for h in faces:
		fsum += int(h) * 31 + int(faces[h])
	out["colliders"] = [faces.size(), fsum]
	return out


func _kind(m: Material, builder: Node3D) -> String:
	if m == builder.flat_material:
		return "ground"
	if m == builder.building_material:
		return "buildings"
	if m == builder.leaf_material:
		return "leaves"
	if m is ShaderMaterial and (m as ShaderMaterial).shader != null:
		return (m as ShaderMaterial).shader.resource_path.get_file().get_basename()
	return m.get_class() if m != null else "none"
