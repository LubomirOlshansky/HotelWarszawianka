extends SceneTree
## The runtime city's hang (2026-11-28): since the Palace's Blender model became the default
## (#1100), the streamer's worker never finished building the Palace's sector. The build read the
## glb there (`load`, `Mesh.surface_get_arrays`), synchronous calls into the RenderingServer that
## wait for the main thread, while the main thread waited for the worker (sector_streamer.gd
## `_join_worker`, on a teleport, a tow, a respawn or a quit). tajny-run stopped after 900 s at the
## race to Kemal's; firstlife's EXIT HANG (#1153) and the jump wait (#1160) were the same wait.
##
## This check builds the sectors that hold the sites read from files (the Palace's glb) on a
## second thread while the main thread only sleeps, as `_join_worker` does: each build must end
## within the deadline. Prints `check_worker_build: OK`, else the sector and exit 1. From the map
## index alone, ~40 s.
##   godot --headless --path game --script res://tools/check_worker_build.gd [-- --seconds=S]

const MapBuilder := preload("res://scripts/map_builder.gd")
const INDEX_JSON := "res://map/index.json"
## The sites whose build reads a file; each one's sectors are built on the worker.
const SITES := ["palace"]
## A sector builds in ~15 s on one CI core; a stuck worker never ends.
const SECONDS := 120.0

var map: Node3D
var seconds := SECONDS


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.trim_prefix("--seconds="))
	if not FileAccess.file_exists(INDEX_JSON):
		print("check_worker_build: no map/index.json: run tools/setup_map.sh once")
		quit(1)
		return
	map = MapBuilder.new()
	root.add_child(map)
	map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	var keys: Array[Vector2i] = []
	for s: Dictionary in map._marks.sites:
		if not str(s["key"]) in SITES:
			continue
		var box: Rect2 = s["box"]
		for c in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			var k := MapBuilder.sector_of(c.x, c.y)
			if not k in keys:
				keys.append(k)
	if keys.is_empty():
		print("check_worker_build: none of %s in the map" % [SITES])
		quit(1)
		return
	for key in keys:
		var ms := _build_on_worker(key)
		if ms < 0:
			print("check_worker_build: the worker's build of %s did not end in %d s (it waits for the main thread)" % [
					MapBuilder.sector_name(key), int(seconds)])
			# The stuck thread cannot be joined: leave without waiting for it.
			OS.kill(OS.get_process_id())
			return
		print("check_worker_build: %s built on the worker in %d ms" % [MapBuilder.sector_name(key), ms])
	print("check_worker_build: OK")
	quit(0)


## Builds the sector on a second thread while this one only sleeps (no frame, no queue flushed),
## as the streamer's `_join_worker`. The ms it took, or -1 past the deadline.
func _build_on_worker(key: Vector2i) -> int:
	var t0 := Time.get_ticks_msec()
	var t := Thread.new()
	t.start(func() -> void:
		var r: Node3D = map.build_sector(key, false, false)
		if r != null:
			r.free())
	while t.is_alive():
		OS.delay_msec(5)
		if Time.get_ticks_msec() - t0 > int(seconds * 1000.0):
			return -1
	t.wait_to_finish()
	return Time.get_ticks_msec() - t0
