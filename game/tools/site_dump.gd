extends SceneTree
## Parity proof for refactors of the landmark code (the facade kit, the split of landmarks.gd):
## builds every site alone through `landmarks.gd`, the way `check_mesh_quality.gd` does (the shared
## `Fakes.BuilderMap` and flat ground, the committed `map/centrum.json` only), and writes each site's vertices
## to `<out>/<key>.bin`: per vertex 14 float32 (position 3, normal 3, colour 4, uv 2, uv2 2: see
## `Dump.add_vertex`), in the order they were emitted. Run it before and after a change and
## compare the two folders with `python3 -I tools/site_parity.py before after`: a refactor that
## must not change the city shows every site identical.
##   godot --headless --path game --script res://tools/site_dump.gd -- --out=/abs/dir [--only=key,key]

const Fakes := preload("res://tools/fakes.gd")
const Quality := preload("res://tools/mesh_probe.gd")
const Landmarks := preload("res://scripts/landmarks.gd")


class Dump:
	var floats := PackedFloat32Array()
	var _c := Color.WHITE
	var _n := Vector3.UP
	var _uv := Vector2.ZERO
	var _uv2 := Vector2.ZERO

	func set_color(c: Color) -> void:
		_c = c

	func set_normal(n: Vector3) -> void:
		_n = n

	func set_uv(uv: Vector2) -> void:
		_uv = uv

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		floats.append_array(PackedFloat32Array([p.x, p.y, p.z, _n.x, _n.y, _n.z, _c.r, _c.g, _c.b, _c.a,
				_uv.x, _uv.y, _uv2.x, _uv2.y]))


func _initialize() -> void:
	var out := ""
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	if out == "" or not DirAccess.dir_exists_absolute(out):
		print("site_dump: --out=<an existing folder> is needed")
		quit(2)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("site_dump: map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := Fakes.BuilderMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	var keys := {}
	for s: Dictionary in marks.sites:
		keys[String(s["key"])] = true
	var names: Array = keys.keys()
	names.sort()
	var written := 0
	var verts := 0
	for key: String in names:
		if not only.is_empty() and not only.has(key):
			continue
		var rec := Dump.new()
		marks.build(rec, Rect2(), key)
		var f := FileAccess.open(out.path_join(key + ".bin"), FileAccess.WRITE)
		f.store_buffer(rec.floats.to_byte_array())
		f.close()
		written += 1
		verts += rec.floats.size() / 14
	# The words on the walls and the picking grid are part of what a site builds.
	var extra := FileAccess.open(out.path_join("_signs.txt"), FileAccess.WRITE)
	for s in marks.signs:
		extra.store_line(str(s))
	extra.close()
	map.free()  # the map is a Node3D (Fakes.BuilderMap): freed by hand
	print("site_dump: %d sites, %d triangles in %s" % [written, verts / 3, out])
	quit(0)
