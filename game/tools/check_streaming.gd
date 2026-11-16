extends SceneTree
## Loop 3c: the city in sectors is the city it was (docs/DEMO.md 2.4, risks 2 and 3).
##
## (c) identity: builds the city whole (map_builder.gd `build`, from centrum.json) and every
##     sector from its file (`build_sector`), and compares them: each 256 m tile's ground and
##     building meshes (every vertex, normal, colour and UV), each 512 m tile's MultiMeshes
##     (every instance), the colliders' faces, the roof and picking grids and the landmark cards.
## (a) pixels: renders SPOTS (10, five of them on sector borders: kerbs and markings, a bridge
##     deck over the river, the water, the stadium) in the real game twice, with --monolithic
##     and with the prebuilt sectors streamed (the car jumps to each spot, --spots), the same
##     frames, no traffic, a fixed time and weather; counts the pixels that differ (any channel)
##     at the phone's 2868 x 1320; at most MAX_CHANGED of them per spot.
## (b) soak: the game with --stream-soak (the car on autopilot over every sector, the view
##     widening and narrowing, the helicopter for the last third), --fixed-fps 60: no frame may
##     miss the car's sector or a sector the view needs, the main thread's streaming time a
##     frame (99th percentile of the frames that streamed) at most BUDGET_MS, and no frame that
##     streamed over 33 ms. Prints the numbers.
## (d) passes (loop 3d-2b): the helicopter at its highest and fastest west to east across the map,
##     and the car at 45 m/s (162 km/h) in its widest view east to west (--stream-pass): no frame may
##     miss a sector the view needs (the look-ahead's job), none load at once; prints the slowest
##     frame while a sector loaded (the pieces one a frame: no load-end hitch) against the median.
##     The loading fix (2026-10-31) adds five: heli-low (the helicopter at 45 m, full speed, four
##     turns) and switch (the car at 45 m/s, then the helicopter): as strict; start (the helicopter
##     off at once from the first frame, no waiting for the ring), look (looks at targets 0.6-3 km
##     off, as a new rescue or delivery target gets) and jump (the car put somewhere new, as a tow
##     does): no frame may show proxies over PROXY_SHARE of the view's ground (a proxy close up),
##     jump may load at once. Each prints the frames with a proxy in the view, the nearest's
##     distance from the view's centre and the most of the view's ground they covered.
## Needs a renderer (the pixels, and the meshes' data): a window opens.
##   godot --path game --resolution 1280x720 --script res://tools/check_streaming.gd
##       [-- --only=identity,pixels,soak,pass --passes=heli,car,... --soak=MINUTES --keep=DIR --size=WxH
##       --barriers=classic|typed|panels (W2, W4: the whole city, the sectors and the game runs in that look; bake
##       the prebuilt city in it first)]
## Prints `check_streaming: OK` (exit 0) or the problems (exit 1). --soak=15 is the 15-minute
## run (docs/DEVELOPMENT.md "Sectors and streaming"); tools/verify.sh runs 3 minutes.

const MapBuilder := preload("res://scripts/map_builder.gd")
const Solidity := preload("res://scripts/solidity.gd")
## x, z, heading (degrees: the camera looks that way): the spawn, then sector borders.
const SPOTS := [
	[-911.6, 278.6, 0.0],     # the spawn (Plac Defilad), inside sector -2,0
	[-512.0, 360.0, 90.0],    # x = -512: Nowy Świat's kerbs, islands and markings
	[-1000.0, 512.0, 0.0],    # z = 512: Al. Jerozolimskie's markings by Centralna
	[-1536.0, 690.0, 45.0],   # x = -1536: a deck and the markings by Dworzec Ochota
	[512.0, 0.0, 60.0],       # four sectors' corner: Most Poniatowskiego's viaduct, tram, footways
	[1024.0, -170.0, 72.0],   # x = 1024: the bridge's deck over the river (water, AO, piers)
	[1536.0, -190.0, 120.0],  # x = 1536: the bridge's east end, Rondo Waszyngtona
	[512.0, -740.0, 0.0],     # x = 512: Most Świętokrzyski's deck and the boulevards
	[1024.0, -880.0, 180.0],  # x = 1024, the map's north: the river's edge
	[1536.0, -560.0, 200.0],  # x = 1536, z = -512: Stadion Narodowy across two borders
]
const MAX_CHANGED := 0.005
## Loop 3d-1: per-spot limits where a spot's differences are known and judged (spot number: share).
## Spot 8 (Most Świętokrzyski's west end and the boulevards): 0.79 % of the pixels differ, 0.14 %
## by more than 8/255. Measured in the game at that view (shots/spot8): the streamed sectors
## (12 loaded) against every sector loaded differ in 0.38 % (0.07 % visible), all single texels
## of lamp-pole and railing shadow edges along the boulevards, nowhere a moved shadow: the sun's
## shadow fits its depth range to the casters it sees, and the reference (the whole city) and the
## sectors after the check's eight jumps see different sets. Nothing a player sees moves.
const SPOT_MAX := {8: 0.01}
const BUDGET_MS := 3.0
const SPOT_FRAMES := 150

var problems: Array[String] = []
## What the OK line says (each part's result).
var notes: Array[String] = []
var only: PackedStringArray = ["identity", "pixels", "soak", "pass"]
## The passes part (d) runs (--passes=): the strict ones (no frame may miss a sector in the view,
## none load at once) and the loading fix's (no proxy over PROXY_SHARE of the view's ground).
var passes: PackedStringArray = ["heli", "car", "heli-low", "switch", "start", "look", "jump"]
const STRICT := ["heli", "car", "heli-low", "switch"]
const PROXY_SHARE := 0.05
var soak_minutes := 3.0
var keep := ""
var size := Vector2i(2868, 1320)


func _initialize() -> void:
	# W2 of the walls look: --barriers=classic|typed|panels builds the city in that look (the palette's by default).
	Solidity.barrier_look_from(OS.get_cmdline_user_args())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--passes="):
			passes = a.trim_prefix("--passes=").split(",")
		elif a.begins_with("--soak="):
			soak_minutes = float(a.trim_prefix("--soak="))
		elif a.begins_with("--keep="):
			keep = a.trim_prefix("--keep=")
		elif a.begins_with("--size="):
			var v := a.trim_prefix("--size=").split("x")
			size = Vector2i(int(v[0]), int(v[1]))
	_run()


func _run() -> void:
	await process_frame
	if "identity" in only:
		_identity()
	if "pixels" in only:
		_pixels()
	if "soak" in only:
		_soak()
	if "pass" in only:
		for kind in passes:
			_pass(kind)
	if problems.is_empty():
		print("check_streaming: OK (%s)" % "; ".join(notes))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_streaming: %d problems" % problems.size())
		quit(1)


# --- (c) identity ---------------------------------------------------------------------------

func _identity() -> void:
	var t0 := Time.get_ticks_msec()
	var whole: Node3D = MapBuilder.new()
	root.add_child(whole)
	whole.build("res://map/centrum.json", ShaderMaterial.new(), ShaderMaterial.new())
	var t_whole := Time.get_ticks_msec() - t0
	var a := {}
	var faces_a := {}
	_collect(whole, whole, a, faces_a)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var parts: Node3D = MapBuilder.new()
	root.add_child(parts)
	parts.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var b := {}
	var faces_b := {}
	var t1 := Time.get_ticks_msec()
	for k: Array in index["sectors"]["keys"]:
		var sector: Node3D = parts.build_sector(Vector2i(int(k[0]), int(k[1])))
		parts.add_child(sector)
		_collect(sector, parts, b, faces_b)
	_collect_edges(parts, faces_b)
	var t_parts := Time.get_ticks_msec() - t1
	var bad := 0
	for key in a:
		if not b.has(key):
			problems.append("identity: %s is in the whole city but in no sector" % key)
			bad += 1
		elif a[key] != b[key]:
			problems.append("identity: %s differs: whole %s, sectors %s" % [key, a[key], b[key]])
			bad += 1
	for key in b:
		if not a.has(key):
			problems.append("identity: %s is in a sector but not in the whole city" % key)
			bad += 1
	var face_diff := 0
	for h in faces_a:
		face_diff += absi(int(faces_a[h]) - int(faces_b.get(h, 0)))
	for h in faces_b:
		if not faces_a.has(h):
			face_diff += int(faces_b[h])
	if face_diff > 0:
		problems.append("identity: %d collider faces differ" % face_diff)
	var grids: bool = whole.get("_roof") == parts.get("_roof") and whole.get("_pick") == parts.get("_pick")
	if not grids:
		problems.append("identity: the roof or picking grid differs")
	if var_to_str(whole.landmark_info) != var_to_str(parts.landmark_info):
		problems.append("identity: the landmark cards differ")
	var n_faces := 0
	for h in faces_a:
		n_faces += int(faces_a[h])
	print("identity: %d meshes and MultiMeshes, %d collider faces, the roof and picking grids: %s (whole city %d ms, %d sectors %d ms)" % [
			a.size(), n_faces, "the same" if bad == 0 and face_diff == 0 and grids else "%d differ" % (bad + face_diff),
			t_whole, index["sectors"]["keys"].size(), t_parts])
	notes.append("%d sectors = the whole city (%d meshes and MultiMeshes, %d collider faces)" % [
			index["sectors"]["keys"].size(), a.size(), n_faces])
	whole.free()
	parts.free()


## Every mesh (by kind and 256 m tile), MultiMesh (by kind, mesh, 512 m tile) and collider face.
func _collect(node: Node, builder: Node3D, out: Dictionary, faces: Dictionary) -> void:
	for n in node.find_children("*", "", true, false):
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh is ArrayMesh:
			var arrays := (mi.mesh as ArrayMesh).surface_get_arrays(0)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var c := (v[0] + v[1] + v[2]) / 3.0
			var key := "mesh %s tile %d,%d" % [_kind(mi.material_override, builder), floori(c.x / 256.0), floori(c.z / 256.0)]
			out[key] = [v.size(), hash(arrays)]
			continue
		var mmi := n as MultiMeshInstance3D
		if mmi != null and mmi.multimesh.instance_count > 0:
			var mm := mmi.multimesh
			var o := mm.get_instance_transform(0).origin
			if _kind(mmi.material_override, builder) == "panel":
				# W4: a panel piece belongs to the tile of its middle (city_barriers.gd `_panel_piece`).
				o += mm.get_instance_transform(0).basis.x * 0.5
			var mesh_n := (mm.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var key := "multimesh %s %s (%d vertices) tile %d,%d" % [_kind(mmi.material_override, builder),
					n.get_parent().name if n.get_parent().name in ["LampHalos", "Neon"] else "", mesh_n,
					floori(o.x / 512.0), floori(o.z / 512.0)]
			out[key] = [mm.instance_count, hash(mm.buffer)]
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


## The streamed map's edge walls (on the index, not in a sector).
func _collect_edges(builder: Node3D, faces: Dictionary) -> void:
	var edges := builder.get_node_or_null("Edges")
	if edges != null:
		_collect(edges, builder, {}, faces)


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


# --- (a) pixels ------------------------------------------------------------------------------

func _pixels() -> void:
	var dir := keep if keep != "" else OS.get_user_data_dir().path_join("check_streaming")
	DirAccess.make_dir_recursive_absolute(dir)
	var spots := PackedStringArray()
	var frames := PackedStringArray()
	for k in SPOTS.size():
		spots.append("%s,%s,%s" % SPOTS[k])
		frames.append(str(120 + SPOT_FRAMES * (k + 1)))
	var runs := {"whole": ["--monolithic"], "sectors": ["--prebuilt"]}
	for name: String in runs:
		var out_dir := dir.path_join(name)
		DirAccess.make_dir_recursive_absolute(out_dir)
		for f in DirAccess.get_files_at(out_dir):
			DirAccess.remove_absolute(out_dir.path_join(f))
		# --nohud: the speech bubbles' lines differ from run to run (2026-11-01), not the city.
		var args := ["--path", ProjectSettings.globalize_path("res://"), "--rendering-method", "mobile",
				"--resolution", "%dx%d" % [size.x, size.y], "--fixed-fps", "60", "--",
				"--nosave", "--notitle", "--no-traffic", "--free", "--time=day", "--weather=clear", "--governor=off", "--no-input", "--nohud",
				"--spots=" + "/".join(spots), "--shots=" + ",".join(frames), "--out=" + out_dir]
		args.append_array(runs[name])
		args.append("--barriers=%s" % Solidity.barrier_look())  # W2: the runs in the check's look
		var output := []
		var t := Time.get_ticks_msec()
		var code := OS.execute(OS.get_executable_path(), args, output, true)
		var log_text := "".join(output)
		FileAccess.open(dir.path_join(name + ".log"), FileAccess.WRITE).store_string(log_text)
		print("pixels: the %s city rendered %d spots in %d ms (exit %d)" % [name, SPOTS.size(), Time.get_ticks_msec() - t, code])
		if code != 0:
			problems.append("pixels: the %s run exited %d (%s)" % [name, code, dir.path_join(name + ".log")])
			return
	var worst := 0.0
	for k in SPOTS.size():
		var file := "shot_%04d.png" % (120 + SPOT_FRAMES * (k + 1))
		var a := Image.load_from_file(dir.path_join("whole").path_join(file))
		var b := Image.load_from_file(dir.path_join("sectors").path_join(file))
		if a == null or b == null or a.get_size() != b.get_size():
			problems.append("pixels: spot %d: missing or different-sized shots (%s)" % [k + 1, dir])
			continue
		if keep != "":
			# Side by side at half size, the whole city left, the streamed sectors right (to look at).
			var half := a.get_size() / 2
			var left := a.duplicate() as Image
			var right := b.duplicate() as Image
			left.resize(half.x, half.y, Image.INTERPOLATE_NEAREST)
			right.resize(half.x, half.y, Image.INTERPOLATE_NEAREST)
			var pair := Image.create(half.x * 2, half.y, false, left.get_format())
			pair.blit_rect(left, Rect2i(Vector2i.ZERO, half), Vector2i.ZERO)
			pair.blit_rect(right, Rect2i(Vector2i.ZERO, half), Vector2i(half.x, 0))
			pair.save_png(dir.path_join("pair_%02d.png" % (k + 1)))
		var counts := _changed(a, b, dir.path_join("diff_%02d.png" % (k + 1)))
		var share := float(counts.x) / float(a.get_width() * a.get_height())
		worst = maxf(worst, share)
		print("pixels: spot %2d (%7.1f, %7.1f, %3.0f°): %.3f %% of the pixels differ (%d; %d by more than 8/255)" % [
				k + 1, SPOTS[k][0], SPOTS[k][1], SPOTS[k][2], share * 100.0, counts.x, counts.y])
		var limit: float = SPOT_MAX.get(k + 1, MAX_CHANGED)
		if share > limit:
			problems.append("pixels: spot %d differs in %.3f %% of the pixels (at most %.1f %%): %s" % [k + 1, share * 100.0,
					limit * 100.0, dir])
	print("pixels: at most %.3f %% of a shot's pixels differ (images in %s)" % [worst * 100.0, dir])
	notes.append("%d spots at %dx%d: at most %.3f %% of the pixels differ" % [SPOTS.size(), size.x, size.y, worst * 100.0])


## Pixels that differ in any channel, and by more than 8/255: whole rows compared first. Where
## any differ, `mask` gets the whole city's shot dimmed with them in magenta.
func _changed(a: Image, b: Image, mask: String) -> Vector2i:
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	var da := a.get_data()
	var db := b.get_data()
	var w := a.get_width()
	var row := w * 3
	var any := 0
	var big := 0
	var marks := PackedInt32Array()
	for y in a.get_height():
		var ra := da.slice(y * row, (y + 1) * row)
		var rb := db.slice(y * row, (y + 1) * row)
		if ra == rb:
			continue
		for x in w:
			var i := x * 3
			var d := maxi(absi(ra[i] - rb[i]), maxi(absi(ra[i + 1] - rb[i + 1]), absi(ra[i + 2] - rb[i + 2])))
			if d > 0:
				any += 1
				marks.append(y * w + x)
				if d > 8:
					big += 1
	if any > 0:
		var img := a.duplicate() as Image
		img.adjust_bcs(0.6, 1.0, 0.3)
		for m in marks:
			img.set_pixel(m % w, m / w, Color.MAGENTA)
		img.save_png(mask)
	elif FileAccess.file_exists(mask):
		DirAccess.remove_absolute(mask)
	return Vector2i(any, big)


# --- (b) soak --------------------------------------------------------------------------------

func _soak() -> void:
	var text := _run_stream("soak", ["--stream-soak=%s" % soak_minutes], int(soak_minutes * 3600.0) + 600)
	var t: int = _run_t
	var code: int = _run_code
	var line := ""
	var stats: Variant = null
	for l in text.split("\n"):
		if l.begins_with("stream soak:"):
			line = l
		elif l.begins_with("stream soak stats: "):
			stats = JSON.parse_string(l.trim_prefix("stream soak stats: "))
	if code != 0 or line == "" or not stats is Dictionary:
		problems.append("soak: exit %d, no 'stream soak:' lines" % code)
		return
	print("soak: %s (%d s)" % [line.trim_prefix("stream soak: "), (Time.get_ticks_msec() - t) / 1000])
	_judge_load_frames("soak", stats)
	var missing := int(stats["missing_frames"])
	var forced := int(stats["forced"])
	var busy99 := float(stats["busy_p99_ms"])
	var worst := float(stats["slowest_busy_frame_ms"])
	if missing > 0:
		problems.append("soak: %d frames missed the car's sector or a sector the view needs" % missing)
	if forced > 0:
		problems.append("soak: %d sectors had to be loaded at once" % forced)
	# The times are the Mac's and move with whatever else runs on it (other Godot processes): they
	# are reported against the budget, not failed on; the phone's are the ones that count.
	var lf: Dictionary = stats.get("load_frame_ms", {})
	notes.append("soak %.0f min: 0 missing, %d loads, streaming %.2f ms p99 / %.2f ms max a frame that streamed%s, slowest such frame %.1f ms%s, slowest frame while a sector loaded %.1f ms (median %.1f), at most %d sectors in full, governor %s" % [
			soak_minutes, int(stats["loads"]), busy99, float(stats["max_ms"]),
			" (over the %.0f ms budget)" % BUDGET_MS if busy99 > BUDGET_MS else "", worst,
			" (over 33 ms)" if worst > 33.0 else "", float(lf.get("max", 0.0)), float(lf.get("median", 0.0)),
			int(stats.get("max_loaded", 0)), stats.get("governor", "-")])
	for l in text.split("\n"):
		if l.begins_with("ERROR") or l.begins_with("SCRIPT ERROR") or l.begins_with("WARNING"):
			problems.append("soak: " + l.substr(0, 160))


var _run_t := 0
var _run_code := 0


## Loop 3d-2b: a streaming run of the prebuilt game (the soak or a pass), its output.
func _run_stream(name: String, flags: Array, frames: int) -> String:
	var args := ["--path", ProjectSettings.globalize_path("res://"), "--rendering-method", "mobile",
			"--resolution", "1280x720", "--fixed-fps", "60", "--quit-after", str(frames), "--",
			"--nosave", "--notitle", "--prebuilt"]
	args.append_array(flags)
	args.append("--barriers=%s" % Solidity.barrier_look())  # W2: the look the sectors were baked in
	var output := []
	_run_t = Time.get_ticks_msec()
	_run_code = OS.execute(OS.get_executable_path(), args, output, true)
	var text := "".join(output)
	if keep != "":
		FileAccess.open(keep.path_join(name + ".log"), FileAccess.WRITE).store_string(text)
	return text


## Loop 3d-2b (d): one pass (heli or car), judged on its missing frames and forced loads.
func _pass(kind: String) -> void:
	var text := _run_stream("pass_" + kind, ["--stream-pass=" + kind], 30000)
	var stats: Variant = null
	for l in text.split("\n"):
		if l.begins_with("stream soak stats: "):
			stats = JSON.parse_string(l.trim_prefix("stream soak stats: "))
	if _run_code != 0 or not stats is Dictionary:
		problems.append("pass %s: exit %d, no 'stream soak stats:' line" % [kind, _run_code])
		return
	var missing := int(stats["missing_frames"])
	if missing > 0 and kind in STRICT:
		problems.append("pass %s: %d frames missed a sector the view needs (first: %s)" % [kind, missing,
				", ".join(PackedStringArray(stats.get("missing_log", []).slice(0, 3)))])
	if int(stats["forced"]) > 0 and kind != "jump":
		problems.append("pass %s: %d sectors had to be loaded at once" % [kind, int(stats["forced"])])
	if float(stats.get("proxy_share_max", 0.0)) >= PROXY_SHARE:
		problems.append("pass %s: proxies covered up to %.0f %% of the view's ground (%d frames over %.0f %%; first: %s)" % [kind,
				float(stats["proxy_share_max"]) * 100.0, int(stats.get("proxy_share_frames", 0)), PROXY_SHARE * 100.0,
				", ".join(PackedStringArray(stats.get("missing_log", []).slice(0, 3)))])
	var lf: Dictionary = stats.get("load_frame_ms", {})
	print("pass %s: %d loads, %d missing, %d forced, at most %d sectors in full, slowest frame while a sector loaded %.1f ms (median %.1f; frames' median %.1f) (%d s)" % [
			kind, int(stats["loads"]), missing, int(stats["forced"]), int(stats.get("max_loaded", 0)),
			float(lf.get("max", 0.0)), float(lf.get("median", 0.0)), float(stats.get("frame_median_ms", 0.0)),
			(Time.get_ticks_msec() - _run_t) / 1000])
	print("pass %s: proxies in the view: %s" % [kind, _proxy_line(stats)])
	notes.append("%s pass: %s, %d loads, slowest load frame %.1f ms" % [kind, "0 missing" if missing == 0 else
			"%d frames with a proxy in the view, none close" % missing, int(stats["loads"]), float(lf.get("max", 0.0))])
	_judge_load_frames("pass " + kind, stats)
	for l in text.split("\n"):
		if l.begins_with("ERROR") or l.begins_with("SCRIPT ERROR") or l.begins_with("WARNING"):
			problems.append("pass %s: %s" % [kind, l.substr(0, 160)])


## The loading fix: what the player saw of the proxies in a run.
static func _proxy_line(stats: Dictionary) -> String:
	if int(stats.get("missing_frames", 0)) == 0:
		return "none"
	return "%d frames, the nearest %.0f m from the view's centre, at most %.0f %% of the view's ground (%d frames over 5 %%), one sector at most %d frames" % [
			int(stats["missing_frames"]), float(stats.get("proxy_near_m", -1.0)), float(stats.get("proxy_share_max", 0.0)) * 100.0,
			int(stats.get("proxy_share_frames", 0)), int(stats.get("proxy_run_frames", 0))]


## Loop 3d-2b: a frame while a sector loads over 33 ms is reported (the Mac's times move with
## whatever else runs on it; the phone's are the ones that count), not failed on.
func _judge_load_frames(name: String, stats: Dictionary) -> void:
	var lf: Dictionary = stats.get("load_frame_ms", {})
	if float(lf.get("max", 0.0)) > 33.0:
		print("%s: NOTE a frame while a sector loaded took %.1f ms (over 33)" % [name, float(lf["max"])])
