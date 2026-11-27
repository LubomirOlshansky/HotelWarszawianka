extends SceneTree
## The quit fix (CI's firstlife EXIT HANG, 2026-11-27): quitting while the streamer's worker builds a
## runtime sector ends within seconds, not after the whole build (33-63 s on 2 cores).
##
## Sets up the runtime map (map_builder.gd `setup_streamed`, as sector_streamer.gd `open` does,
## without the roof pass), builds sector SLOW whole on the main thread (its time is
## what a quit waited before), then twice starts a streamer's worker on it and takes the streamer
## out of the tree, which is what quitting does (`_exit_tree`), at STOP_AT of that time. Checks: the
## worker was still building when the quit came (else the check proves nothing), the quit waited
## at most MAX_STOP_SHARE of the whole build (or MIN_STOP_MS), the builder handed back the map's
## own data and output node (`data`, `_out`), its flag is down again, and a small sector built
## afterwards by the same builder has the same nodes as one from a fresh builder (a stopped build
## leaves nothing behind for the next).
## Headless is enough (it times the build and counts nodes; no mesh data is compared).
##   godot --headless --path game --script res://tools/check_stream_quit.gd
## Needs the sector split (tools/bake_sectors.py). Prints `check_stream_quit: OK` (exit 0) or the
## problems (exit 1).

const MapBuilder := preload("res://scripts/map_builder.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")
## The sector the quit waited on in CI's firstlife hang: by the start (Plac Defilad, the Christmas
## market's site, whose build alone takes 20-23 s of the sector's 30 s on 4 cores). With no such
## sector, the biggest sector file.
const SLOW := Vector2i(-2, 1)
## When the quit comes, as shares of the sector's whole build: in the flat layers, and in the walls.
const STOP_AT: Array[float] = [0.15, 0.6]
## A quit may wait at most this share of the whole build (before the fix: the rest of it), or MIN_STOP_MS.
const MAX_STOP_SHARE := 0.35
const MIN_STOP_MS := 300

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(SectorStreamer.INDEX_JSON))
	if not index is Dictionary:
		print("check_stream_quit: FAIL (no %s: run tools/bake_sectors.py)" % SectorStreamer.INDEX_JSON)
		quit(1)
		return
	var keys := _by_size(index)
	var big := SLOW
	var small: Vector2i = keys[0]
	if not big in keys:
		big = keys[-1]
	var map: Node3D = MapBuilder.new()
	root.add_child(map)
	map.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var whole: Dictionary = map.data
	# The whole build of the busiest sector first, on the main thread: how long a quit waited before
	# (and the builder's lazy caches are warm, as in a game that has streamed a while).
	var t_full := Time.get_ticks_msec()
	map.build_sector(big, false, false).free()
	var full_ms := Time.get_ticks_msec() - t_full
	var stops: Array[String] = []
	for share: float in STOP_AT:
		var stop_ms := await _quit_during(map, big, int(full_ms * share))
		stops.append("%d ms at %d %%" % [stop_ms, roundi(share * 100.0)])
		if stop_ms > maxi(MIN_STOP_MS, int(full_ms * MAX_STOP_SHARE)):
			problems.append("the quit %d %% into the build of %s waited %d ms for the worker (the whole build takes %d ms; at most %d %% of it, or %d ms)" % [
					roundi(share * 100.0), MapBuilder.sector_name(big), stop_ms, full_ms, roundi(MAX_STOP_SHARE * 100.0), MIN_STOP_MS])
		if not is_same(map.data, whole):
			problems.append("the stopped build left the builder on the sector's data")
		if map._out != map:
			problems.append("the stopped build left the builder's output on the sector's root")
		if map.cancel_build:
			problems.append("cancel_build stays set after the quit")
	# Nothing of the stopped build carries into the next one.
	var after := _shape(map.build_sector(small))
	var fresh_map: Node3D = MapBuilder.new()
	root.add_child(fresh_map)
	fresh_map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(SectorStreamer.INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	var fresh := _shape(fresh_map.build_sector(small))
	if after != fresh:
		problems.append("%s built after the stopped build differs from a fresh builder's (%d nodes against %d)" % [
				MapBuilder.sector_name(small), after.size(), fresh.size()])
	map.free()
	fresh_map.free()
	if problems.is_empty():
		print("check_stream_quit: OK (%s builds in %d ms; a quit during it waited %s; %s rebuilt the same after)" % [
				MapBuilder.sector_name(big), full_ms, ", ".join(stops), MapBuilder.sector_name(small)])
		quit(0)
	else:
		for p in problems:
			print("check_stream_quit: " + p)
		print("check_stream_quit: FAIL (%d problems)" % problems.size())
		quit(1)


## Starts the streamer's worker on `key` as `_poll_worker` does, lets it run `after_ms`, then takes
## the streamer out of the tree as quitting does (`_exit_tree`): the ms that took.
func _quit_during(map: Node3D, key: Vector2i, after_ms: int) -> int:
	var streamer := SectorStreamer.new()
	streamer.map = map
	streamer.prebuilt = false
	root.add_child(streamer)
	streamer._task_key = key
	streamer._thread = Thread.new()
	streamer._thread.start(streamer._make.bind(key), Thread.PRIORITY_LOW)
	var t_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_wait < after_ms:
		await process_frame
	if not streamer._thread.is_alive():
		problems.append("the build of %s ended within %d ms, before the quit: nothing was stopped" % [MapBuilder.sector_name(key), after_ms])
	var t0 := Time.get_ticks_msec()
	root.remove_child(streamer)
	var ms := Time.get_ticks_msec() - t0
	if streamer._thread != null:
		problems.append("the streamer still holds its worker after _exit_tree")
	streamer.free()
	return ms


## The index's sector keys, the smallest sector file first.
func _by_size(index: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var size := {}
	for k: Array in index["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		var f := FileAccess.open(MapBuilder.SECTOR_DIR + "%d_%d.json" % [key.x, key.y], FileAccess.READ)
		size[key] = f.get_length() if f != null else 0
		out.append(key)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return size[a] < size[b])
	return out


## A built sector's nodes (path, class, and a mesh's vertex count and a MultiMesh's instances),
## sorted; the root is freed.
func _shape(sector: Node3D) -> Array[String]:
	var out: Array[String] = []
	for n in sector.find_children("*", "", true, false):
		var s := "%s %s" % [sector.get_path_to(n), n.get_class()]
		var mm := n as MultiMeshInstance3D
		if mm != null and mm.multimesh != null:
			s += " x%d" % mm.multimesh.instance_count
		out.append(s)
	out.sort()
	sector.free()
	return out
