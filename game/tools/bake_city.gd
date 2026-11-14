extends SceneTree
## Builds the city once, sector by sector (loop 3c), so the exported game streams it instead of
## generating every mesh on the phone:
##   map/sectors/s_<i>_<j>.scn   each 512 m sector in full detail (map_builder.gd build_sector)
##   map/proxies.scn             one low-detail mesh per sector (sector_proxies.gd)
##   map/index.res               the global index: the map node with its heights, decks, tunnels,
##                               water test, roof and picking grids, kerbs, the game's data
##   map/shared/*.res            the materials, textures and meshes every sector shares (saved
##                               once; the sector scenes refer to them by path)
## Reads map/index.json and map/sectors/<i>_<j>.json (tools/bake_sectors.py), and checks the
## landmark sites found from the index's `site_parts` against the whole map's (centrum.json).
## Run with a real renderer (not --headless, which drops MultiMesh and texture data):
##   godot --path game --resolution 320x180 --script res://tools/bake_city.gd
## Loop 3d-1: everything it writes is derived and not committed (tools/setup_map.sh makes it on a
## fresh clone). It ends by writing map/sectors/city.stamp: the split's digest (sectors/split.stamp)
## and the SHA-256 of every input in CITY_INPUTS, so tools/check_map_data.py tells stale prebuilt
## sectors by content, not by file times.

const MapBuilder := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Proxies := preload("res://scripts/sector_proxies.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const SHARED := "res://map/shared/"
## index.json's keys only the map builder reads (the game's systems never do).
const BUILDER_ONLY := ["site_parts", "kerbs", "medians", "islands", "shore", "fills", "aprons", "lod2_cuts",
		"lod2_open", "towers", "garages", "dips"]

## Loop 3d-1: what the prebuilt sectors are built from besides the split (index.json and the
## sector files, covered by split.stamp's digest): the baked maps and the scripts the builder
## runs (shaders are referenced by path and need no rebuild). tools/check_map_data.py
## CITY_INPUTS is the same list.
const CITY_INPUTS := ["map/lod2.bin", "map/terrain.json", "map/ao.bin", "map/lights.bin", "map/water.bin",
		"scripts/map_builder.gd", "scripts/chunked_surface.gd", "scripts/neon_signs.gd", "scripts/landmarks.gd",
		"scripts/sector_proxies.gd", "scripts/models.gd", "scripts/pixel_font.gd", "scripts/index_pack.gd",
		"scripts/city_maps.gd", "tools/bake_city.gd", "data/courts.json", "scripts/solidity.gd", "data/object_palette.json",
		"scripts/city_barriers.gd"]


## Set at the end of _bake: a script error (a builder that doesn't compile) ends _bake early
## with its default return value, 0, which reads as OK; without this the bake reported OK in
## 49 ms having written nothing (found merging loop 3c).
var _finished := false


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var err := _bake()
	if err == OK and not _finished:
		push_error("bake_city: the bake stopped on a script error (see above); nothing complete was written")
		err = FAILED
	print("bake_city: %s in %d ms" % [error_string(err), Time.get_ticks_msec() - t0])
	quit(0 if err == OK else 1)


func _bake() -> Error:
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	if not index is Dictionary:
		push_error("bake_city: no map/index.json: run tools/bake_sectors.py first")
		return ERR_FILE_NOT_FOUND
	var building_mat := ShaderMaterial.new()
	building_mat.shader = load("res://shaders/building.gdshader")
	var flat_mat := ShaderMaterial.new()
	flat_mat.shader = load("res://shaders/ground.gdshader")
	var map: Node3D = MapBuilder.new()
	map.name = "City"
	map.setup_streamed(index, building_mat, flat_mat)
	if not _same_sites(map):
		map.free()
		return ERR_INVALID_DATA
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHARED))
	var err := _save_shared(map)
	if err != OK:
		map.free()
		return err
	for f in DirAccess.get_files_at("res://map/sectors/"):
		if f.ends_with(".scn"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("res://map/sectors/" + f))
	for d in DirAccess.get_directories_at("res://map/sectors/"):
		if d.begins_with("s_"):
			_remove_dir("res://map/sectors/" + d)
	var keys: Array[Vector2i] = []
	for k: Array in index["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	var total := 0
	# The loading fix: the sectors' builds note each roof-grid cell's roof and wall colours, for the
	# proxies (sector_proxies.gd); the grids aren't saved.
	map.proxy_colours = true
	for key in keys:
		var t := Time.get_ticks_msec()
		var root: Node3D = map.build_sector(key)
		_own(root, root)
		# The city objects plan, step 1: the colliders go into the scene one body per solid class,
		# `Solid_<class>` with its "solid" meta, saved with the scene (game/tools/check_solids.gd
		# compares them with the runtime build).
		for body in root.find_children("*", "StaticBody3D", true, false):
			if not body.has_meta(&"solid"):
				push_error("bake_city: %s: collider body %s has no solid class" % [MapBuilder.sector_name(key), body.name])
				root.free()
				map.free()
				return FAILED
		var pieces := _save_pieces(root, key)
		if pieces < 0:
			root.free()
			map.free()
			return FAILED
		map.sector_pieces[key] = pieces
		var packed := PackedScene.new()
		err = packed.pack(root)
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if err == OK:
			err = ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS)
		var size := FileAccess.get_file_as_bytes(path).size() if err == OK else 0
		size += _dir_bytes("res://map/sectors/%s/" % MapBuilder.sector_name(key))
		total += size
		print("  %s: %d nodes, %d pieces, %.2f MB, %d ms" % [path.get_file(), _count(root), pieces, size / 1048576.0, Time.get_ticks_msec() - t])
		root.free()
		if err != OK:
			push_error("bake_city: %s: %s" % [path, error_string(err)])
			map.free()
			return err
	map.measure_sectors()
	var proxies := Proxies.build_all(map, keys)
	_own(proxies, proxies)
	var packed_proxies := PackedScene.new()
	err = packed_proxies.pack(proxies)
	if err == OK:
		err = ResourceSaver.save(packed_proxies, "res://map/proxies.scn", ResourceSaver.FLAG_COMPRESS)
	var proxy_tris := 0
	for c in proxies.get_children():
		var m := (c as MeshInstance3D).mesh
		if m.get_surface_count() > 0:  # loop 3d-2a: a sector with nothing to show has an empty proxy
			proxy_tris = maxi(proxy_tris, m.surface_get_array_index_len(0) / 3)
	proxies.free()
	if err != OK:
		map.free()
		return err
	# The exported game keeps only the game's part of the index: what the builder alone reads (its
	# derived grids are in the map node by now) stays in index.json for the runtime path.
	var game_data: Dictionary = map.index_data.duplicate()
	for k in BUILDER_ONLY:
		game_data.erase(k)
	# The memory loop: saved with its coordinates packed (scripts/index_pack.gd).
	IndexPack.pack(game_data)
	map.index_data = game_data
	_own(map, map)
	var packed_index := PackedScene.new()
	err = packed_index.pack(map)
	if err == OK:
		err = ResourceSaver.save(packed_index, "res://map/index.res", ResourceSaver.FLAG_COMPRESS)
	map.free()
	print("bake_city: %d sector scenes %.1f MB, index.res %.1f MB, proxies.scn %.2f MB (at most %d triangles a sector)" % [
			keys.size(), total / 1048576.0, FileAccess.get_file_as_bytes("res://map/index.res").size() / 1048576.0,
			FileAccess.get_file_as_bytes("res://map/proxies.scn").size() / 1048576.0, proxy_tris])
	if err == OK:
		err = _write_stamp()
	_finished = true
	return err


## Loop 3d-2b: the sector's own meshes, MultiMeshes and collider patches (not the shared ones
## under map/shared/) saved one per file, map/sectors/s_<i>_<j>/<n>.res, the scene referring to them by path: the
## streamer's worker loads them one a frame (sector_streamer.gd _make), so the renderer makes
## their GPU buffers and the physics server their shapes a piece a frame instead of all of them
## in the frame the sector's load ends (BACKLOG "From loop G0+": 25-65 ms on the iPhone 11, one
## frame per load; on the Mac the collider, built on the main thread, was most of it). The number
## saved, or -1 on an error.
func _save_pieces(root: Node3D, key: Vector2i) -> int:
	var dir := "res://map/sectors/%s/" % MapBuilder.sector_name(key)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var n := 0
	for node in root.find_children("*", "", true, false):
		var res: Resource = null
		if node is MeshInstance3D:
			res = (node as MeshInstance3D).mesh
		elif node is MultiMeshInstance3D:
			res = (node as MultiMeshInstance3D).multimesh
		elif node is CollisionShape3D:
			res = (node as CollisionShape3D).shape  # the collider's patches (map_builder.gd COLLIDER_CHUNK)
		if res == null or res.resource_path != "":
			continue  # shared (map/shared/) or saved already
		var path := dir + "%d.res" % n
		var err := ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
		if err != OK:
			push_error("bake_city: %s: %s" % [path, error_string(err)])
			return -1
		res.take_over_path(path)
		n += 1
	return n


func _dir_bytes(dir: String) -> int:
	var total := 0
	if DirAccess.dir_exists_absolute(dir):
		for f in DirAccess.get_files_at(dir):
			total += FileAccess.get_file_as_bytes(dir + f).size()
	return total


func _remove_dir(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(f)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


## Loop 3d-1: map/sectors/city.stamp (see CITY_INPUTS).
func _write_stamp() -> Error:
	var split: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/sectors/split.stamp"))
	var inputs := {}
	for p: String in CITY_INPUTS:
		inputs[p] = FileAccess.get_sha256("res://" + p) if FileAccess.file_exists("res://" + p) else ""
	var stamp := {"split": (split as Dictionary).get("digest", "") if split is Dictionary else "", "inputs": inputs}
	var f := FileAccess.open("res://map/sectors/city.stamp", FileAccess.WRITE)
	if f == null:
		push_error("bake_city: can't write map/sectors/city.stamp")
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(stamp, " ", true))
	f.close()
	return OK


## The landmark sites found from the index's `site_parts` must be the whole map's (a landmark
## searching where tools/bake_sectors.py SITE_NAMES / SITE_AREAS don't look fails here).
func _same_sites(map: Node3D) -> bool:
	var whole: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var full = Landmarks.new(map, whole)
	var mine: Array = map.get("_marks").sites
	var ok: bool = full.sites.size() == mine.size()
	for k in mini(full.sites.size(), mine.size()):
		if var_to_str(full.sites[k]) != var_to_str(mine[k]):
			ok = false
			push_error("bake_city: landmark site %s differs from the whole map's (tools/bake_sectors.py SITE_NAMES / SITE_AREAS)" % full.sites[k]["key"])
	if ok:
		print("bake_city: %d landmark sites, the same as the whole map's" % mine.size())
	return ok


## Saves what the sectors share once under map/shared/, so every sector scene refers to the
## same materials, textures and meshes (one copy in memory, per-frame updates reach them all).
## Loop 3d-2b: the AO, lamp-light and surface maps are not among them any more: each sector
## scene carries its slices (map_builder.gd map_slices, city_maps.gd); the whole maps' old files
## go (the web's zstd streams with them: the web's sector packs carry the slices too).
func _save_shared(map: Node3D) -> Error:
	var shared: Dictionary = map.get("_shared")
	for old in ["ao_map.res", "light_map.res", "surface_map.res", "ao_map.zst", "light_map.zst"]:
		if FileAccess.file_exists(SHARED + old):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SHARED + old))
	var items := [
		["ground", map.flat_material],
		["building", map.building_material],
		["leaves", map.leaf_material],
	]
	for name: String in shared:
		items.append([name, shared[name]])
	for item: Array in items:
		var res: Resource = item[1]
		if res == null:
			continue
		var path: String = SHARED + String(item[0]) + ".res"
		var err := ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
		if err != OK:
			push_error("bake_city: %s: %s" % [path, error_string(err)])
			return err
		# From now on the scenes saved refer to it by this path instead of carrying a copy.
		res.take_over_path(path)
	return OK


func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_own(child, owner)


func _count(node: Node) -> int:
	var n := node.get_child_count()
	for c in node.get_children():
		n += _count(c)
	return n
