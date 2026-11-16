extends SceneTree
## The turntable's cameras (tools/turntable.sh): builds ONE landmark site alone, the way the mesh
## check does (the shared Fakes.BuilderMap and mesh_probe.gd's Recorder, flat ground), takes the
## bounding box of its triangles and prints the `--cams` value that looks at it from all round, plus
## the `--lift` to go with it.
##   godot --headless --path game --script res://tools/site_cams.gd -- --site=rotunda [--tile=480x360]
## Output: `site_cams: KEY centre X,Z size W x D x H m, N tris`, `cams: ...`, `lift: M`.
## A kept skin (SKINS, a recoloured LoD2 building) is framed by its LoD2 buildings' box.
## Unknown key, or a site that builds nothing: a message and exit 1.
## The maths (box_for, cams_for) is static, so tools/check_turntable.gd calls the same code.

const MeshQuality := preload("res://tools/mesh_probe.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Fakes := preload("res://tools/fakes.gd")
## The free margin round the model in every tile (the brief: about 15 %).
const MARGIN := 1.15
## The eight compass yaws of the turntable, degrees, and the two ring pitches and the top's.
const YAWS: Array[int] = [0, 45, 90, 135, 180, 225, 270, 315]
const PITCH_LO := -25.0
const PITCH_HI := -50.0
const PITCH_TOP := -89.0


## The box of a site's triangles: {"min": Vector3, "max": Vector3, "tris": int}, or {} when the
## key is unknown or builds nothing.
static func box_for(key: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		return {}
	var map := Fakes.BuilderMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	var known := false
	for s: Dictionary in marks.sites:
		if s["key"] == key:
			known = true
	if not known:
		map.free()  # the map is a Node3D (Fakes.BuilderMap): not counted, so freed by hand
		return {}
	var rec := MeshQuality.Recorder.new()
	marks.build(rec, Rect2(), key)
	if rec.pos.is_empty():
		# A kept skin (SKINS) builds nothing of its own: the box of the LoD2 buildings it recolours
		var skin: Dictionary = marks.skin_of(key)
		var sbox := {} if skin.is_empty() else skin_box(marks, skin)
		map.free()  # the map is a Node3D (Fakes.BuilderMap): not counted, so freed by hand
		return sbox
	var lo := rec.pos[0]
	var hi := rec.pos[0]
	for p: Vector3 in rec.pos:
		lo = lo.min(p)
		hi = hi.max(p)
	map.free()
	return {"min": lo, "max": hi, "tris": rec.pos.size() / 3}


## The box of the LoD2 buildings a kept skin recolours: lod2.bin's buildings split the way the
## runtime city splits them (map_builder.gd _build_lod2: one style seed (UV2.x) a building, within
## 300 m of its first vertex), those whose plan `skin_at` gives this very skin. {} when none.
static func skin_box(marks, skin: Dictionary) -> Dictionary:
	if not FileAccess.file_exists("res://map/lod2.bin"):
		return {}
	var bytes := FileAccess.get_file_as_bytes("res://map/lod2.bin")
	var count := bytes.decode_u32(0)
	var f := bytes.slice(4).to_float32_array()
	var o_u2 := count * 12
	var lo := Vector3.INF
	var hi := -Vector3.INF
	var tris := 0
	var t0 := 0
	while t0 < count:
		var seed := f[o_u2 + t0 * 2]
		var first := Vector2(f[t0 * 3], f[t0 * 3 + 2])
		var plo := first
		var phi := first
		var blo := Vector3.INF
		var bhi := -Vector3.INF
		var t1 := t0
		while t1 < count and f[o_u2 + t1 * 2] == seed and Vector2(f[t1 * 3], f[t1 * 3 + 2]).distance_to(first) < 300.0:
			for k in 3:
				var p := Vector3(f[(t1 + k) * 3], f[(t1 + k) * 3 + 1], f[(t1 + k) * 3 + 2])
				plo = plo.min(Vector2(p.x, p.z))
				phi = phi.max(Vector2(p.x, p.z))
				blo = blo.min(p)
				bhi = bhi.max(p)
			t1 += 3
		if is_same(marks.skin_at(Rect2(plo, phi - plo)), skin):
			lo = lo.min(blo)
			hi = hi.max(bhi)
			tris += (t1 - t0) / 3
		t0 = t1
	if tris == 0:
		return {}
	return {"min": lo, "max": hi, "tris": tris}


## The view height (m) that shows a box of footprint `diag` (its diagonal, the widest it can look
## from any yaw) and height `h` whole at `pitch`, with MARGIN, in a tile `aspect` wide (w / h):
## the box's screen height is h cos(pitch) + diag sin(pitch), its width at most diag.
static func view_size(diag: float, h: float, pitch: float, aspect: float) -> float:
	var p := deg_to_rad(absf(pitch))
	var tall := h * cos(p) + diag * sin(p)
	return maxf(tall, diag / aspect) * MARGIN


## The cameras for a box: {"cams": the --cams text, "lift": metres, "names": Array[String]}.
## Aimed at the box's centre (X and Z; Y is left to the ground plus `lift`, the box's mid height).
static func cams_for(box: Dictionary, aspect: float) -> Dictionary:
	var lo: Vector3 = box["min"]
	var hi: Vector3 = box["max"]
	var size := hi - lo
	var diag := Vector2(size.x, size.z).length()
	var cx := (lo.x + hi.x) * 0.5
	var cz := (lo.z + hi.z) * 0.5
	var parts: PackedStringArray = []
	var names: Array[String] = []
	var rings := [["lo", PITCH_LO], ["hi", PITCH_HI]]
	for ring: Array in rings:
		var sz := view_size(diag, size.y, float(ring[1]), aspect)
		for yaw in YAWS:
			var nm := "%s_%03d" % [ring[0], yaw]
			names.append(nm)
			parts.append("%s:%.2f,,%.2f,%d,%d,%.1f" % [nm, cx, cz, yaw, int(ring[1]), sz])
	names.append("top")
	parts.append("top:%.2f,,%.2f,0,%d,%.1f" % [cx, cz, int(PITCH_TOP), view_size(diag, size.y, PITCH_TOP, aspect)])
	return {"cams": "+".join(parts), "lift": (lo.y + hi.y) * 0.5, "names": names}


func _initialize() -> void:
	var key := ""
	var aspect := 480.0 / 360.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--site="):
			key = a.trim_prefix("--site=")
		elif a.begins_with("--tile="):
			var wh := a.trim_prefix("--tile=").split("x")
			if wh.size() == 2 and float(wh[1]) > 0.0:
				aspect = float(wh[0]) / float(wh[1])
	var box := box_for(key)
	if box.is_empty():
		print("site_cams: '%s' is not a landmark site that builds triangles or a kept skin (see game/scripts/landmarks.gd)" % key)
		quit(1)
		return
	var lo: Vector3 = box["min"]
	var hi: Vector3 = box["max"]
	var s := hi - lo
	var out := cams_for(box, aspect)
	print("site_cams: %s centre %.1f,%.1f size %.1f x %.1f x %.1f m, %d tris" % [key, (lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5, s.x, s.z, s.y, box["tris"]])
	print("cams: " + out["cams"])
	print("lift: %.2f" % out["lift"])
	quit(0)
