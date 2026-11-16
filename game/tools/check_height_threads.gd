extends SceneTree
## The NaN car (2026-11-16): the runtime city builds its sectors on the streamer's thread
## (sector_streamer.gd `_make`) while the car, the traffic and the skids read the map's heights on
## the main thread. Every height read must give the same number whatever the other thread is
## doing. map_builder.gd's ground used to pass "a ground profile set it" through a member
## (`_set_hit`) that both threads wrote: a read outside any profile could see the other thread's
## true and return its own NAN, and the car's position went NaN (the first-10 replay's `car:
## state not a number` at the first rescue, about once in ten replays).
##
## This check reads drive_height, terrain_height and ground_height on the main thread at points in
## the approaches' corridors (inside a ground profile and outside one), while a second thread reads
## the heights inside ground profiles as fast as it can, then builds the sectors round the points
## (the streamer's real work). Each main-thread read must equal the same read made with no other
## thread running. Prints `check_height_threads: OK`, else the count and exit 1. From the map index
## alone, ~40 s.
##   godot --headless --path game --script res://tools/check_height_threads.gd [-- --seconds=S]

const MapBuilder := preload("res://scripts/map_builder.gd")
const INDEX_JSON := "res://map/index.json"
## Points of each kind (in a profile, outside one) taken along the approaches.
const POINTS := 48
## How long the main thread reads against each kind of other-thread work.
const SECONDS := 6.0
const SHOW := 8

var map: Node3D
var seconds := SECONDS
var _stop := false
var _other_reads := 0
var _built := 0
## Points inside a ground profile ("s" fills): where the other thread's reads say "set".
var _in_set: PackedVector2Array = []
## Points in an approach's corridor that no ground profile sets: where a stray "set" turned the
## height into NAN.
var _off_set: PackedVector2Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.trim_prefix("--seconds="))
	if not FileAccess.file_exists(INDEX_JSON):
		print("check_height_threads: no map/index.json: run tools/setup_map.sh once")
		quit(1)
		return
	map = MapBuilder.new()
	root.add_child(map)
	map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	_pick_points()
	if _in_set.size() < 4 or _off_set.size() < 4:
		print("check_height_threads: too few points (%d in a ground profile, %d outside)" % [_in_set.size(), _off_set.size()])
		quit(1)
		return
	var probes := PackedVector2Array(_off_set)
	probes.append_array(_in_set)
	# The answers with no other thread running.
	var want: Array[PackedFloat64Array] = []
	for p in probes:
		want.append(_reads(p))
	var bad := 0
	var reads := 0
	for mode in ["heights", "sectors"]:
		_stop = false
		var th := Thread.new()
		th.start(_other_heights if mode == "heights" else _other_sectors.bind(probes))
		var t0 := Time.get_ticks_msec()
		var k := 0
		while Time.get_ticks_msec() - t0 < seconds * 1000.0:
			var i := k % probes.size()
			var got := _reads(probes[i])
			reads += 1
			for j in got.size():
				if got[j] != want[i][j]:
					bad += 1
					if bad <= SHOW:
						print("  %s at (%.2f, %.2f) with the other thread %s: %s, alone %s" % [
								["drive_height", "terrain_height", "ground_height"][j], probes[i].x, probes[i].y,
								mode, got[j], want[i][j]])
			k += 1
		_stop = true
		th.wait_to_finish()
	print("check_height_threads: %d main-thread reads at %d points (%d in ground profiles), %d on the other thread, %d sectors built" % [
			reads, probes.size(), _in_set.size(), _other_reads, _built])
	if bad > 0:
		print("check_height_threads: %d reads differ from the same read alone" % bad)
		quit(1)
		return
	print("check_height_threads: OK")
	quit(0)


## Points along the approaches: each piece's first segment's middle, sorted by whether a ground
## profile sets the ground there.
func _pick_points() -> void:
	for d: Dictionary in map._fills:
		var pts: PackedVector2Array = d["pts"]
		if pts.size() < 2:
			continue
		var p := (pts[0] + pts[1]) * 0.5
		if map._set_hit_at(p.x, p.y):
			if _in_set.size() < POINTS:
				_in_set.append(p)
		elif not bool(d["s"]) and _off_set.size() < POINTS:
			_off_set.append(p)
		if _in_set.size() >= POINTS and _off_set.size() >= POINTS:
			return


## The heights the car and the traffic read at `p`, at the ground's own level.
func _reads(p: Vector2) -> PackedFloat64Array:
	var g: float = map.terrain_height(p.x, p.y)
	return PackedFloat64Array([map.drive_height(p.x, p.y, g), g, map.ground_height(p.x, p.y)])


## The other thread, first kind: the heights inside ground profiles, as a sector's ground asks.
func _other_heights() -> void:
	var k := 0
	while not _stop:
		var p := _in_set[k % _in_set.size()]
		map.terrain_height(p.x, p.y)
		map._drawn_corner_raw(p.x, p.y)
		_other_reads += 1
		k += 1


## The other thread, second kind: the sectors round the points, built as the streamer builds them.
func _other_sectors(probes: PackedVector2Array) -> void:
	var keys: Array[Vector2i] = []
	for p in probes:
		var key: Vector2i = map.sector_of(p.x, p.y)
		if not keys.has(key):
			keys.append(key)
	var k := 0
	while not _stop:
		var r: Node3D = map.build_sector(keys[k % keys.size()], false, false)
		r.free()
		_built += 1
		k += 1
