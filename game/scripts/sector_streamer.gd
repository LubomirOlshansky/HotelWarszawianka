extends Node
## Loop 3c: the city in 512 m sectors, streamed round the camera (docs/DEMO.md 2.4).
##
## The map node (map_builder.gd) is the global index: heights, decks, tunnels, the water test,
## the roof and picking grids, the kerbs the car feels, the game's data (prebuilt: loaded from
## map/index.res; runtime: set up from map/index.json). Under it, `Sectors` holds the sectors
## in full detail and `Proxies` one low-detail mesh per sector (sector_proxies.gd).
##
## Which sectors are in full detail: the 3 x 3 round the focus's sector (the car's physics
## needs its colliders), the next row once the focus comes within 192 m of its sector's edge,
## and every sector the camera's view needs: its box, from its lowest ground to its tallest
## roof and grown by 128 m, meets the camera's frustum (a tower two sectors off can stand in
## the view). A sector goes again once it is 256 m past that reach (hysteresis) and out of
## the view grown by 256 m.
##
## Loading never stalls the frame: one sector at a time, a worker thread loads and instantiates
## its scene (prebuilt: map/sectors/s_<i>_<j>.scn) or builds it from its file (the runtime,
## editor path: map/sectors/<i>_<j>.json, map_builder.gd build_sector). The main thread then
## adds its nodes a few a frame under a hidden root, spending at most BUDGET_USEC; the root
## shows (and the proxy hides) once every node is in. A sector the car stands in that isn't
## in yet (a jump: a tow, a race start) loads at once.
##
## Loop 3d-2b: the look-ahead wants the sectors the focus will need LOOK_AHEAD seconds on (its
## square and the view moved along its velocity), a sector in the view first; a prebuilt sector's
## pieces (its meshes, MultiMeshes and collider patches, one file each) load one a frame on the
## worker, so no frame takes a whole sector's GPU buffers and physics shapes (the one slow frame
## per load); each sector brings its slices of the AO, lamp-light and surface maps into a slot of
## city_maps.gd's arrays (at most CityMaps.SLOTS sectors in full detail at once).
##
## The loading fix (2026-10-31; docs/DEVELOPMENT.md "The loading fix"): the proxies the player saw
## close up came from the camera's look at a new target (a rescue or a delivery: the camera flies
## 0.6-3 km off and back) and from jumps (a tow, a race start). Now the view is tested wherever it
## reaches (its frustum cut to the map's heights as a rectangle on the map, not 1,800 m round the
## focus); the order of loads is the sectors in the view now (nearest the view's centre first),
## then those a coming view needs (`expect_shot`: main.gd holds the look until they are in, at
## most 1.5 s), then the rest by the look-ahead; a worker busy with a later class gives its sector
## up for one in the view; for a few frames after a jump the sectors whose ground is in the view
## load at once with the car's; under the title screen a sector's pieces load all at once
## (`hurry`), and the title offers "tap to drive" once the start's sectors are in.
##
## --sectors=all loads every sector at the start and keeps them (the old behaviour, pixel
## diffs); --stream-log prints every load and unload with its frame and main-thread ms, and (loop
## G0+) each worker load: its load and instantiate ms and the slowest frame while it ran, split
## into the frame's phases (process after the streamer, draw, to the next physics frame, physics).

const MapBuilder := preload("res://scripts/map_builder.gd")
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
const Proxies := preload("res://scripts/sector_proxies.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const CityMaps := preload("res://scripts/city_maps.gd")
const INDEX_SCENE := "res://map/index.res"
const INDEX_JSON := "res://map/index.json"
const PROXY_SCENE := "res://map/proxies.scn"
const SECTOR := MapBuilder.SECTOR
## The focus's 3 x 3, and the next row within 192 m of its sector's edge (a square round the
## focus this far out); a sector stays loaded until it is KEEP_REACH out.
const LOAD_REACH := SECTOR + 192.0
const KEEP_REACH := LOAD_REACH + 256.0
## At the start, the sectors within this much of the start go in at once (what the view there
## shows); the rest of the ring streams in over the first seconds.
const START_REACH := 320.0
## The view's boxes are grown this much to load, and this much to keep. The loading fix: a sector
## is tested against the view wherever it is (the view's rectangle on the map rules the far ones
## out); before, one over VIEW_RANGE (1,800 m) from the focus was never in view, so a look at a
## target 2-3 km off showed proxies only.
const VIEW_GROW := 128.0
const VIEW_KEEP := 256.0
## The car's physics needs every sector within this of it in (a wall or parapet across a border).
const CAR_REACH := 40.0
## The frames at the start the frame-time numbers leave out (shaders compiling on first sight).
const WARM_UP := 120
## Main-thread time a frame for adding sector nodes (microseconds).
const BUDGET_USEC := 3000
## Loop 3d-2b: the look-ahead. The sectors the focus will need this many seconds on (its square
## and the view moved along the focus's velocity) are wanted now, nearest the view first; at
## most LOOK_AHEAD_MAX metres ahead. A focus that moves more than JUMP metres a frame jumped
## (a tow, a race start): no velocity from that.
const LOOK_AHEAD := 4.0
const LOOK_AHEAD_MAX := 400.0
const JUMP := 60.0
## The look-ahead's tests run for a sector every this many frames (a share of them each frame).
const AHEAD_EVERY := 4

## A sector's root got its nodes (before they go into the tree, and again once all are in):
## main.gd gives them the time of day, the quality's shadows, the fine detail and --exp.
signal sector_ready(root: Node3D)

enum { QUEUED, WANTED, LOADING, ADDING, IN }

var map: Node3D
var prebuilt := false
var load_all := false
## --sectors=proxies: only the sectors the car needs, the rest as proxies (to look at them).
var proxies_only := false
var log := false
## Loop 3d-2b: --stream-ahead=0 switches the look-ahead off (a before/after on one build);
## --stream-slow=MS makes every worker load MS ms longer (a phone's slower loads on the Mac).
var look_ahead := true
var slow_ms := 0
## Loop 3d-2b: --stream-gate=0 loads a sector's pieces with its scene at once (the old way).
var gate_pieces := true
var keys: Array[Vector2i] = []
var _sectors: Node3D
var _proxies: Node3D
var _proxy := {}   # key -> MeshInstance3D
## key -> {"s": state, "root", "queue": nodes still to add, "t0": usec it was wanted, "ms": main-thread ms}
var _state := {}
## The worker: a thread per sector (joined when it is done, so nothing it made lingers at the
## end the way a pool thread's would), its sector and the root it made.
var _thread: Thread
var _task_key := Vector2i.ZERO
var _task_root: Node3D
## Loop 3d-2b: the worker loads a prebuilt sector's pieces (its meshes, MultiMeshes and collider
## patches, saved one per file by tools/bake_city.gd) one a frame: after each it waits at this gate, which the main
## thread opens once a frame (update), so the renderer makes a piece's GPU buffers a frame instead
## of the whole sector's in one (BACKLOG "From loop G0+": 25-65 ms frames on the iPhone 11).
var _gate := Semaphore.new()
var _gate_lock := Mutex.new()
var _gate_waiting := false
var _quitting := false
## The main thread waits for the worker (a sector needed at once): no more gates.
var _rush := false
## Pieces the worker loads before it waits at the gate: 1, or URGENT_PIECES while a sector in the
## view isn't in yet (its proxy shows: better a busier frame than a longer gap).
var _pieces_per_frame := 1
const URGENT_PIECES := 4
## The loading fix: under the title screen nothing on screen can hitch, so a sector's pieces load
## this many a frame (main.gd sets `hurry` while the title shows).
const HURRY_PIECES := 64
var hurry := false
## The loading fix: the order of loads. A sector in the camera's view now goes first (nearest the
## view's centre first), then one a view about to come needs (expect_shot: a look at a new target),
## then the rest the focus wants (nearest the point the look-ahead puts it). A worker loading a
## sector of a later class gives it up (back in the queue) when one of the first two waits.
const FIRST_SEEN := 0.0
const FIRST_EXPECTED := 1000.0
const FIRST_REST := 2000.0
## The loading fix: views about to come: [{sector: its order within them}, until (the streamer's
## clock, s), rank]. The west-sectors fix (2026-11-01): the sectors are the ones the views'
## frusta meet (expect_shot), not a square round the target, and the clock is the game's.
var _expect: Array = []
## The west-sectors fix: the game's time (s), summed from the frames' deltas: an expectation lasts
## as long as the look it was made for (which runs on the game's clock), however slow the frames.
var _clock := 0.0
## The loading fix: frames left after a jump (a forced load) in which a sector whose ground is in
## the view loads at once too (the cut shows the city, not its proxies), and how many did.
const JUMP_FRAMES := 3
var _jump_left := 0
var jump_loads := 0
var aborts := 0
var _abort := false
## Loop 3d-2b: the slowest frame (usec) while the sector now loading was loaded and added, and
## per streamed sector that slowest frame (ms): what a load costs the frame, wherever it lands.
var _window_max := 0
var _window_on := false
var load_frame_ms := PackedFloat32Array()
## --stream-log (loop G0+): when the worker started, loaded and instantiated (usec), and each
## update's start in the meantime, to name the slowest frame during a load and what it overlapped.
var _task_t := PackedInt64Array([0, 0, 0])
var _task_ticks := PackedInt64Array()
## The same frames' phases (usec stamps of frame_pre_draw, frame_post_draw, the first physics_frame
## after it, process_frame): where the time of a slow one went.
var _task_phases: Array[PackedInt64Array] = []
var _stamps := PackedInt64Array([0, 0, 0, 0])
var frame := 0
## Per frame: the main thread's streaming time (usec) and the frame's own (usec, wall clock).
var stream_usec := PackedInt32Array()
var frame_usec := PackedInt32Array()
## The same, only for the frames that loaded, added or unloaded something (0 for the others).
var busy_usec := PackedInt32Array()
var _worked := false
## What adding a node of each class cost lately (usec, a slowly falling maximum).
var _add_cost := {}
var _last_tick := 0
## Frames where the car's sector or a sector the view needs wasn't in yet, and the forced loads.
var missing_frames := 0
var forced := 0
var loads := 0
var unloads := 0
## Loop 3d-2b: the most sectors in full detail (or being added) at once, and the loads that waited
## for a map slot (or took one from a sector kept only by the hysteresis).
var max_loaded := 0
## Loop 3d-2b: the first frames that missed a sector in view: frame, sector, its state.
var missing_log: Array[String] = []
var slot_waits := 0
var evictions := 0
var _view_planes: Array[Plane] = []
## The loading fix (2026-10-31): the view's frustum cut to the map's heights (its lowest ground to
## its tallest roof) as a rectangle on the map (x, z; `_view_ok` false: no camera); a sector whose
## square misses it is out of the view without the planes' tests. `_y_range`: the map's lowest
## ground and tallest roof (from sector_heights).
var _view_rect := Rect2()
var _view_ok := false
var _y_range := Vector2(-30.0, 320.0)
var _cam: Camera3D
## The loading fix: what the player sees of the proxies. Of the frames with a sector in the view still
## a proxy (missing_frames): the nearest such sector's square to the view's centre on the ground (m; 0:
## the centre stands in it), the most of the view's ground the proxies covered (share), the frames they
## covered over PROXY_SHARE of it, and the longest one sector stayed a proxy in the view (frames).
var proxy_near := INF
var proxy_share := 0.0
var proxy_share_frames := 0
var proxy_run := 0
var proxy_run_key := ""
const PROXY_SHARE := 0.05
## Loop 3d-2b: the view's planes moved along the look-ahead, the focus's velocity (m/s, smoothed)
## and where it was the frame before.
var _ahead_planes: Array[Plane] = []
var _focus_vel := Vector3.ZERO
var _last_focus := Vector3.INF
var ahead := Vector3.ZERO
## Loop G0+: each streamed sector's main-thread ms (the forced and start-up loads apart), and per
## kind of step (a node class added, the hand-over, the finish, an unload) its count, total and
## worst usec, for the soak's result.
var sector_ms := PackedFloat32Array()
var _kinds := {}


## Opens the city: the index, the proxies and the sectors round `at` (in full, before the first
## frame; the spawn when `at` is INF). Returns the game's data (index.json's).
func open(world: Node3D, use_prebuilt: bool, building_mat: ShaderMaterial, flat_mat: ShaderMaterial, at: Vector3) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	prebuilt = use_prebuilt and ResourceLoader.exists(INDEX_SCENE)
	if prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
	else:
		map = MapBuilder.new()
		var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON))
		if not index is Dictionary:
			push_error("sectors: no %s (run tools/bake_sectors.py)" % INDEX_JSON)
			return {}
		map.setup_streamed(index, building_mat, flat_mat)
	map.name = "City"
	world.add_child(map)
	if prebuilt:
		ready_prebuilt(map)
	for k: Array in map.index_data["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	# Loop 3d-2b: the baked maps' slots, one per sector in full detail (all of them with --sectors=all).
	map.open_maps(keys, keys.size() if load_all else CityMaps.SLOTS)
	var t_index := Time.get_ticks_msec() - t0
	if not prebuilt:
		# The runtime path: every sector's cells of the roof and picking grids first (missions,
		# eggs and the helicopter read them over the whole map at the start). The loading fix: and
		# the roofs' and walls' colours when it must make the proxies itself (no proxies.scn).
		map.proxy_colours = not ResourceLoader.exists(PROXY_SCENE)
		for key in keys:
			map.build_sector(key, true).free()
		map.measure_sectors()
	var t_roofs := Time.get_ticks_msec() - t0 - t_index
	# The loading fix: the map's lowest ground and tallest roof (the view's rectangle is cut to them).
	var y_lo := INF
	var y_hi := -INF
	for k in map.sector_heights:
		var h: Vector2 = map.sector_heights[k]
		y_lo = minf(y_lo, h.x)
		y_hi = maxf(y_hi, h.y)
	if y_lo < y_hi:
		_y_range = Vector2(y_lo, y_hi)
	_sectors = Node3D.new()
	_sectors.name = "Sectors"
	# Loop G0+: the city stands still, so its nodes take no physics interpolation (as the people's
	# and the pigeons' MultiMeshes already didn't). With it on (the project's setting), adding a
	# MultiMesh node cost the main thread 14 ms on average on the iPhone 11 (37 ms at worst; the
	# Mac 1.4 ms), a sector 188 ms spread over its frames, every load frame over the 3 ms budget;
	# off, 0.002 ms and 0.35 ms a sector. Every sector, the proxies and what they hold inherit this;
	# nothing in them moves on the physics tick.
	_sectors.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	map.add_child(_sectors)
	var t_proxies := Time.get_ticks_msec()
	# The runtime path takes the baked proxies too when there are any (they only show while a
	# sector loads: an older bake's shapes for a moment do no harm); else it makes them (~1 s).
	if ResourceLoader.exists(PROXY_SCENE):
		_proxies = (load(PROXY_SCENE) as PackedScene).instantiate()
	else:
		_proxies = Proxies.build_all(map, keys)
	# The loading fix: the colour grids were for the proxies only (10 MB on the demo map).
	map.proxy_colours = false
	map.roof_rgba = PackedInt32Array()
	map.wall_rgba = PackedInt32Array()
	t_proxies = Time.get_ticks_msec() - t_proxies
	_proxies.name = "Proxies"
	_proxies.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	map.add_child(_proxies)
	for c in _proxies.get_children():
		_proxy[_key_of(c.name)] = c
	for key in keys:
		_state[key] = {"s": QUEUED}
	if at == Vector3.INF:
		var spawn: Dictionary = map.index_data.get("spawn", {})
		at = Vector3(float(spawn.get("x", 0.0)), 0.0, float(spawn.get("z", 0.0)))
	var start := 0
	var t_start := Time.get_ticks_msec()
	for key in keys:
		if load_all or (_in_reach(key, at, CAR_REACH if proxies_only else START_REACH) or key == MapBuilder.sector_of(at.x, at.z)):
			_load_now(key)
			start += 1
	print("sectors: %s city, %d sectors of %d m; index %d ms%s, proxies %d ms, %d sectors in full at the start in %d ms" % [
			"prebuilt" if prebuilt else "runtime", keys.size(), SECTOR, t_index,
			("" if prebuilt else ", roof pass %d ms" % t_roofs), t_proxies, start, Time.get_ticks_msec() - t_start])
	_last_tick = Time.get_ticks_usec()
	# The memory loop: the index's coordinates packed (the prebuilt index is saved packed).
	IndexPack.pack(map.index_data)
	return map.index_data


## The prebuilt map (map/index.res) as the runtime one is after its set-up. The game's data is the
## index on both paths: the runtime map has it as `data` from setup_streamed, the prebuilt one only as
## `index_data` (`data` is not saved); without it a reader of `map.data` (the place scripts: the
## Spire's lights, Tamka's bollards and plates; the people on the University Library's roof garden)
## found nothing on the phone (2026-11-15). Then the heights the scene does not keep
## (map_builder.gd restore_heights) and the edge's roadworks.
static func ready_prebuilt(map: Node3D) -> void:
	map.data = map.index_data
	map.restore_heights()
	EdgeRoadworks.rebuild(map)


## The whole streamed city at once, for the checks that sweep the map (check_drive, check_water,
## check_landmarks): the index and every sector under `parent`, prebuilt (map/index.res and the
## sector scenes) or built from the files (the runtime path). `data` is set to the game's data.
static func open_whole(parent: Node, use_prebuilt: bool) -> Node3D:
	var map: Node3D
	var keys: Array[Vector2i] = []
	if use_prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
		parent.add_child(map)
		ready_prebuilt(map)
	else:
		map = MapBuilder.new()
		parent.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	for k: Array in map.index_data["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	for key in keys:
		var root: Node3D
		if use_prebuilt:
			root = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate()
		else:
			root = map.build_sector(key)
		map.add_child(root)
	if not use_prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	return map


## Quitting: the worker's load or build ends before the map it reads goes, and what is not in
## the tree (its result, the nodes still queued) is freed. A runtime build is told to stop at its
## next step (map_builder.gd `cancel_build`): the main thread waited out a whole sector's build
## before (CI's firstlife EXIT HANG, 2026-11-27); the partial root it hands back is freed below.
func _exit_tree() -> void:
	_gate_lock.lock()
	_quitting = true
	if _gate_waiting:
		_gate_waiting = false
		_gate.post()
	_gate_lock.unlock()
	if _thread != null:
		var t0 := Time.get_ticks_msec()
		if map != null and not prebuilt:
			map.cancel_build = true
		# A line every 10 s while it runs: a stop that never comes (a stuck worker, not a slow
		# step) shows in the log above the CI watch's backtrace.
		var said := 0
		while _thread.is_alive():
			OS.delay_msec(5)
			if Time.get_ticks_msec() - t0 >= (said + 1) * 10000:
				said += 1
				print("stream: quit: still waiting for the worker's %s %s after %d s" % [
						"load of" if prebuilt else "build of", MapBuilder.sector_name(_task_key), said * 10])
		_thread.wait_to_finish()
		_thread = null
		if map != null and not prebuilt:
			map.cancel_build = false
		print("stream: quit: the worker's %s %s stopped in %d ms" % [
				"load of" if prebuilt else "build of", MapBuilder.sector_name(_task_key), Time.get_ticks_msec() - t0])
	if _task_root != null:
		_task_root.free()
		_task_root = null
	for key in keys:
		for c: Node in _state[key].get("queue", []):
			c.free()
		_state[key]["queue"] = []


## Every frame (main.gd, after the camera moved): what to load, add, unload. `focus` is the
## camera's focus, `car` where the car (or helicopter) is.
func update(focus: Vector3, car: Vector3, cam: Camera3D) -> void:
	var t0 := Time.get_ticks_usec()
	frame_usec.append(t0 - _last_tick)
	_last_tick = t0
	frame += 1
	_open_gate()
	if _window_on and frame > WARM_UP:
		_window_max = maxi(_window_max, frame_usec[-1])
	if log:
		if _thread != null:
			_task_ticks.append(t0)
			_task_phases.append(_stamps.duplicate())
		_stamps.fill(0)
	_worked = false
	if load_all:
		stream_usec.append(0)
		busy_usec.append(0)
		return
	_view_planes = cam.get_frustum() if cam != null else []
	_view_box(cam)
	_look_ahead(focus)
	var focus2 := focus + ahead
	var car_key := MapBuilder.sector_of(car.x, car.z)
	var missing := false
	# The car's own sector must be in, and any within CAR_REACH of it (their colliders): load them
	# now if a jump put the car somewhere new.
	for key in keys:
		if _state[key]["s"] != IN and (key == car_key or _in_reach(key, car, CAR_REACH)):
			missing = true
			forced += 1
			_load_now(key)
			_jump_left = JUMP_FRAMES
	_clock += get_process_delta_time()
	while not _expect.is_empty() and float(_expect[0][1]) < _clock:
		_expect.pop_front()
	var centre := _view_centre()
	var first_waits := false
	if proxies_only:
		stream_usec.append(Time.get_ticks_usec() - t0)
		busy_usec.append(stream_usec[-1] if _worked else 0)
		return
	var in_full := 0
	var shown: Array[Vector2i] = []
	for ki in keys.size():
		var key := keys[ki]
		var st: Dictionary = _state[key]
		if st["s"] == IN or st["s"] == ADDING:
			in_full += 1
		# Loop 3d-2b: the cheap square tests first, the view's only where they don't decide (the
		# view tests were most of the streamer's frame once the look-ahead doubled them).
		var near := _in_reach(key, focus, LOAD_REACH)
		var want := near
		var keep := near or _in_reach(key, focus, KEEP_REACH)
		var seen := false
		# The loading fix: the view's rectangle first (cheap), the planes only for a sector over it.
		if _rect_meets(key, VIEW_KEEP, _view_rect):
			if (not want or st["s"] != IN) and _rect_meets(key, VIEW_GROW, _view_rect) and _in_view(key, VIEW_GROW):
				want = true
				seen = st["s"] != IN and _in_view(key, 0.0)  # in the view itself: it shows its proxy
			if not keep and (want or _in_view(key, VIEW_KEEP)):
				keep = true
		var expected := false
		var expect_prio := INF
		for e: Array in _expect:
			var order: Variant = (e[0] as Dictionary).get(key)
			if order != null:
				expected = true
				expect_prio = minf(expect_prio, float(e[2]) * 100.0 + float(order))
				want = true
				keep = true
		# And where the focus will be: its square, the view moved there. A quarter of the sectors a
		# frame (the answer is seconds ahead; a frame's delay is nothing), kept in between.
		var later: int = st.get("ahead", 0)
		if ahead == Vector3.ZERO:
			later = 0
		elif (ki + frame) % AHEAD_EVERY == 0:
			var ahead_range := _rect_meets(key, VIEW_KEEP, Rect2(_view_rect.position + Vector2(ahead.x, ahead.z), _view_rect.size))
			later = 0
			if _in_reach(key, focus2, LOAD_REACH) or (ahead_range and _in_view(key, VIEW_GROW, _ahead_planes)):
				later = 2
			elif _in_reach(key, focus2, KEEP_REACH) or (ahead_range and _in_view(key, VIEW_KEEP, _ahead_planes)):
				later = 1
		st["ahead"] = later
		want = want or later == 2
		keep = keep or want or later >= 1
		st["want"] = want
		# The loading fix: which wanted sector loads first: one in the view now (nearest the view's
		# centre), then one a coming view needs, then the nearest the focus ahead.
		var mid := Vector2(key) + Vector2(0.5, 0.5)
		if seen:
			st["prio"] = FIRST_SEEN + mid.distance_squared_to(centre / SECTOR)
		elif expected:
			st["prio"] = FIRST_EXPECTED + expect_prio
		else:
			st["prio"] = FIRST_REST + mid.distance_squared_to(Vector2(focus2.x, focus2.z) / SECTOR)
		if want and st["s"] == QUEUED:
			_state[key] = {"s": WANTED, "t0": Time.get_ticks_usec(), "ms": 0.0, "want": true, "prio": st["prio"], "ahead": later}
		elif not keep and st["s"] != QUEUED:
			_unload(key)
		elif seen and st["s"] != IN and _jump_left > 0 and ground_in_view(key, 0.0, 25.0, _view_planes):
			# The loading fix: just after a jump, a sector whose ground is in the view loads at once
			# (the frame of the cut is already a stall: better the city than its proxy for a second).
			forced += 1
			jump_loads += 1
			_load_now(key)
		elif seen and st["s"] != IN:
			missing = true
			shown.append(key)
		if _state[key]["s"] == WANTED and float(_state[key].get("prio", FIRST_REST)) < FIRST_REST:
			first_waits = true
		if not seen or st["s"] == IN:
			st.erase("vis_from")
	if not shown.is_empty():
		_count_proxies(shown)
	if missing:
		missing_frames += 1
	_jump_left = maxi(_jump_left - 1, 0)
	var urgent := missing or first_waits or (_thread != null and _state.has(_task_key) \
			and float(_state[_task_key].get("prio", FIRST_REST)) < FIRST_REST)
	_pieces_per_frame = HURRY_PIECES if hurry else (URGENT_PIECES if urgent else 1)
	_check_abort(first_waits)
	max_loaded = maxi(max_loaded, in_full)
	var t1 := Time.get_ticks_usec()
	# One step a frame: a finished sector handed over (its state applied, its nodes queued), or
	# its queued nodes added within the budget.
	if not _poll_worker(focus):
		_add_nodes(t0)
	var t2 := Time.get_ticks_usec()
	stream_usec.append(t2 - t0)
	busy_usec.append(t2 - t0 if _worked else 0)
	_window_on = _thread != null or _any_adding()
	if log and t2 - t0 > BUDGET_USEC:
		print("stream: frame %d took %.2f ms (the tests %.2f, loading and adding %.2f)" % [frame, (t2 - t0) / 1000.0,
				(t1 - t0) / 1000.0, (t2 - t1) / 1000.0])


## Loop 3d-2b: lets the worker load its next piece (once a frame, when it waits for it).
func _open_gate() -> void:
	_gate_lock.lock()
	if _gate_waiting:
		_gate_waiting = false
		_gate.post()
	_gate_lock.unlock()


## Loop 3d-2b, on the worker: waits for the main thread's next frame.
func _wait_gate() -> void:
	_gate_lock.lock()
	if _rush or _quitting:
		_gate_lock.unlock()
		return
	_gate_waiting = true
	_gate_lock.unlock()
	_gate.wait()


func _any_adding() -> bool:
	for key in keys:
		if _state[key]["s"] == ADDING:
			return true
	return false


## Loop 3d-2b: the focus's velocity (smoothed over a quarter second; a jump resets it) and the
## look-ahead from it: `ahead` and the view's planes moved by it.
func _look_ahead(focus: Vector3) -> void:
	var dt := maxf(get_process_delta_time(), 1e-3)
	if _last_focus == Vector3.INF or Vector2(focus.x - _last_focus.x, focus.z - _last_focus.z).length() > JUMP:
		_focus_vel = Vector3.ZERO
	else:
		var v := Vector3(focus.x - _last_focus.x, 0.0, focus.z - _last_focus.z) / dt
		_focus_vel = _focus_vel.lerp(v, 1.0 - exp(-dt * 4.0))
	_last_focus = focus
	ahead = Vector3.ZERO
	_ahead_planes.clear()
	if not look_ahead or _focus_vel.length() < 2.0:
		return
	ahead = _focus_vel * LOOK_AHEAD
	if ahead.length() > LOOK_AHEAD_MAX:
		ahead = ahead.normalized() * LOOK_AHEAD_MAX
	for pl in _view_planes:
		_ahead_planes.append(Plane(pl.normal, pl.d + pl.normal.dot(ahead)))


## Loads and adds every sector the view needs now (blocking): before a screenshot.
func finish_view(focus: Vector3, cam: Camera3D) -> void:
	_view_planes = cam.get_frustum()
	for key in keys:
		if _state[key]["s"] != IN and (_in_reach(key, focus, LOAD_REACH) or _in_view(key, VIEW_GROW)):
			_load_now(key)


## Loop 3d-2b: the numbers start over (a scripted pass, once its start is loaded).
func reset_stats() -> void:
	stream_usec.clear()
	frame_usec.clear()
	busy_usec.clear()
	sector_ms.clear()
	load_frame_ms.clear()
	_window_max = 0
	_kinds.clear()
	missing_frames = 0
	forced = 0
	loads = 0
	unloads = 0
	max_loaded = 0
	missing_log.clear()
	proxy_near = INF
	proxy_share = 0.0
	proxy_share_frames = 0
	proxy_run = 0
	proxy_run_key = ""
	slot_waits = 0
	evictions = 0
	jump_loads = 0
	aborts = 0
	frame = 0
	_last_tick = Time.get_ticks_usec()


## Loop 3d-2b: nothing wanted, loading or being added.
func idle() -> bool:
	if _thread != null:
		return false
	for key in keys:
		var s: int = _state[key]["s"]
		if s == WANTED or s == LOADING or s == ADDING:
			return false
	return true


## The loading bar (main.gd `_title_frame`): sectors still wanted, loading or being added (the
## worker's own counts once while it runs).
func pending() -> int:
	var n := 0
	for key in keys:
		var s: int = _state[key]["s"]
		if s == WANTED or s == LOADING or s == ADDING:
			n += 1
	return n


## Sectors in full detail now.
func loaded() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key in keys:
		if _state[key]["s"] == IN:
			out.append(key)
	return out


## The streaming numbers (tools/check_streaming.gd reads them): frames, loads, unloads, the
## main thread's streaming ms a frame (max, 99th percentile over all frames and over the frames
## that streamed), the slowest frame that streamed (ms), missing frames, forced loads.
func stats() -> Dictionary:
	var busy := []
	var worst := 0
	var worst_frame := -1
	var slow := 0
	var slow_busy := 0
	for i in stream_usec.size():
		# A frame's own time is measured at the next update; the first WARM_UP frames (the first
		# sight of every shader) are left out of the frame times.
		var ft := frame_usec[i + 1] if i + 1 < frame_usec.size() and i >= WARM_UP else 0
		if ft > 33333:
			slow += 1
		if i < busy_usec.size() and busy_usec[i] > 0:
			busy.append(busy_usec[i])
			if ft > 33333:
				slow_busy += 1
			if ft > worst:
				worst = ft
				worst_frame = i + 1
	busy.sort()
	var all := Array(stream_usec)
	all.sort()
	var over_budget := 0
	for us in stream_usec:
		if us > BUDGET_USEC:
			over_budget += 1
	# The frames over 33 ms past the warm-up: frame, its ms, the streaming ms in it (0: none).
	var slow_list := []
	for i in range(WARM_UP, frame_usec.size() - 1):
		if frame_usec[i + 1] > 33333 and slow_list.size() < 60:
			slow_list.append([i + 1, snappedf(frame_usec[i + 1] / 1000.0, 0.1),
					snappedf(busy_usec[i] / 1000.0, 0.01) if i < busy_usec.size() else 0.0])
	var per_sector := Array(sector_ms)
	per_sector.sort()
	var windows := Array(load_frame_ms)
	windows.sort()
	var plain := []
	for i in range(WARM_UP, frame_usec.size()):
		plain.append(frame_usec[i] / 1000.0)
	plain.sort()
	var kinds := {}
	for k: String in _kinds:
		var v: Array = _kinds[k]
		kinds[k] = {"n": v[0], "total_ms": snappedf(v[1] / 1000.0, 0.01), "max_ms": snappedf(v[2] / 1000.0, 0.01)}
	return {"frames": frame, "loads": loads, "unloads": unloads,
			"max_ms": all[-1] / 1000.0 if not all.is_empty() else 0.0,
			"p99_ms": all[mini(all.size() - 1, int(all.size() * 0.99))] / 1000.0 if not all.is_empty() else 0.0,
			"busy_frames": busy.size(),
			"busy_p99_ms": busy[mini(busy.size() - 1, int(busy.size() * 0.99))] / 1000.0 if not busy.is_empty() else 0.0,
			"slowest_busy_frame_ms": worst / 1000.0, "slowest_busy_frame": worst_frame,
			"frames_over_33ms": slow, "frames_over_33ms_streaming": slow_busy,
			"missing_frames": missing_frames, "forced": forced, "max_loaded": max_loaded,
			"slot_waits": slot_waits, "evictions": evictions, "missing_log": missing_log,
			"jump_loads": jump_loads, "aborts": aborts,
			"frames_over_budget": over_budget, "slow_frames": slow_list,
			"sector_ms": {"n": per_sector.size(),
				"median": per_sector[per_sector.size() / 2] if not per_sector.is_empty() else 0.0,
				"p99": per_sector[mini(per_sector.size() - 1, int(per_sector.size() * 0.99))] if not per_sector.is_empty() else 0.0,
				"max": per_sector[-1] if not per_sector.is_empty() else 0.0},
			"kinds": kinds,
			"proxy_near_m": snappedf(proxy_near, 0.1) if proxy_near < INF else -1.0,
			"proxy_share_max": snappedf(proxy_share, 0.001), "proxy_share_frames": proxy_share_frames,
			"proxy_run_frames": proxy_run, "proxy_run_sector": proxy_run_key,
			"frame_median_ms": plain[plain.size() / 2] if not plain.is_empty() else 0.0,
			"load_frame_ms": {"n": windows.size(),
				"median": windows[windows.size() / 2] if not windows.is_empty() else 0.0,
				"p90": windows[mini(windows.size() - 1, int(windows.size() * 0.9))] if not windows.is_empty() else 0.0,
				"max": windows[-1] if not windows.is_empty() else 0.0}}


## The streaming numbers for a log line.
func summary() -> String:
	var st := stats()
	return "%d frames, %d loads, %d unloads, streaming %.2f ms max, %.2f ms p99 over all frames, %.2f ms p99 over the %d frames that streamed, slowest frame that streamed %.1f ms (frame %d), %d frames over 33 ms (%d of them streaming), %d frames missing a needed sector, %d forced loads" % [
			st["frames"], st["loads"], st["unloads"], st["max_ms"], st["p99_ms"], st["busy_p99_ms"], st["busy_frames"],
			st["slowest_busy_frame_ms"], st["slowest_busy_frame"], st["frames_over_33ms"], st["frames_over_33ms_streaming"],
			st["missing_frames"], st["forced"]]


# --- loading -----------------------------------------------------------------------------

## The worker: hands its finished sector to the adding queue, then starts on the wanted sector
## nearest the focus.
func _poll_worker(focus: Vector3) -> bool:
	var handed := false
	if _thread != null:
		if _thread.is_alive():
			return false
		_thread.wait_to_finish()
		_thread = null
		var root := _task_root
		_task_root = null
		if log:
			_log_task()
		if _state[_task_key]["s"] == LOADING and root != null:
			_start_adding(_task_key, root)
			handed = true
		elif root != null:
			root.free()
		elif _state[_task_key]["s"] == LOADING:
			_state[_task_key]["s"] = WANTED  # the loading fix: given up; it loads again in its turn
		_abort = false
	# The next load starts once every sector handed over is in (the loader's uploads and the main
	# thread's adds don't then compete for the renderer).
	for key in keys:
		if _state[key]["s"] == ADDING:
			return handed
	var best := Vector2i.ZERO
	var best_d := INF
	for key in keys:
		if _state[key]["s"] == WANTED:
			var d: float = _state[key].get("prio", (Vector2(key) + Vector2(0.5, 0.5)).distance_squared_to(Vector2(focus.x, focus.z) / SECTOR))
			if d < best_d:
				best_d = d
				best = key
	if best_d < INF:
		# Loop 3d-2b: a map slot for it first (a sector kept only by the hysteresis gives its up);
		# with none, it waits (its proxy shows).
		if not _make_room(focus, false):
			slot_waits += 1
			return handed
		_state[best]["s"] = LOADING
		_task_key = best
		_task_ticks.clear()
		_task_ticks.append(Time.get_ticks_usec())
		_task_phases.clear()
		if log and not RenderingServer.frame_post_draw.is_connected(_on_post_draw):
			RenderingServer.frame_pre_draw.connect(_on_pre_draw)
			RenderingServer.frame_post_draw.connect(_on_post_draw)
			get_tree().physics_frame.connect(_on_physics_frame)
			get_tree().process_frame.connect(_on_process_frame)
		_thread = Thread.new()
		_thread.start(_make.bind(best), Thread.PRIORITY_LOW)
	return handed


## On the worker (or the main thread when it can't wait): one sector's root, not in the tree.
func _make(key: Vector2i) -> void:
	_task_t[0] = Time.get_ticks_usec()
	if slow_ms > 0 and _thread != null and OS.get_thread_caller_id() != OS.get_main_thread_id():
		OS.delay_msec(slow_ms)
	if prebuilt:
		# Loop 3d-2b: on the worker, the sector's pieces first, one a frame (held here until the
		# scene, which refers to them by path, has them from the cache).
		var held: Array[Resource] = []
		if gate_pieces and OS.get_thread_caller_id() != OS.get_main_thread_id():
			for n in int(map.sector_pieces.get(key, 0)):
				if _quitting or _abort:
					break
				held.append(ResourceLoader.load(_piece_path(key, n)))
				if (n + 1) % _pieces_per_frame == 0:
					_wait_gate()
		if _abort:
			_task_root = null
			return  # the loading fix: given up for a sector in the view (it goes back in the queue)
		var scene := ResourceLoader.load(_scene_path(key), "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		_task_t[1] = Time.get_ticks_usec()
		_task_root = scene.instantiate() as Node3D if scene != null else null
		_task_t[2] = Time.get_ticks_usec()
	else:
		_task_root = map.build_sector(key, false, false)


## --stream-log: the worker's load and instantiate times, and the slowest frame (update to update)
## while it ran: what part of the worker's run it overlapped.
func _log_task() -> void:
	var t := _task_ticks
	t.append(Time.get_ticks_usec())
	var worst := 0
	var at := 0
	for i in range(1, t.size()):
		if t[i] - t[i - 1] > worst:
			worst = t[i] - t[i - 1]
			at = i
	var part := "-"
	if at > 0:
		var a := t[at - 1]
		var b := t[at]
		part = "instantiate" if b > _task_t[1] and a < _task_t[2] else ("load" if b > _task_t[0] and a < _task_t[1] else "after")
		if part == "instantiate" and a < _task_t[1]:
			part = "load end + instantiate"
	# The slow interval's phases: the rest of the process after the streamer, the draw, from the draw
	# to the next physics frame (frame pacing, events), physics, the process up to the streamer.
	var split := "-"
	if at > 0 and at - 1 < _task_phases.size():
		var ph := _task_phases[at - 1]
		if ph[0] > 0 and ph[1] > 0 and ph[3] > 0:
			var phys := ph[2] if ph[2] > 0 else ph[3]
			split = "process after %.1f, draw %.1f, to physics %.1f, physics %.1f, process before %.1f" % [
					(ph[0] - t[at - 1]) / 1000.0, (ph[1] - ph[0]) / 1000.0, (phys - ph[1]) / 1000.0,
					(ph[3] - phys) / 1000.0, (t[at] - ph[3]) / 1000.0]
	print("stream: frame %d worker %s: load %.1f ms, instantiate %.1f ms, %d frames; slowest frame %.1f ms (overlapping the %s; %s)" % [
			frame, MapBuilder.sector_name(_task_key), (_task_t[1] - _task_t[0]) / 1000.0, (_task_t[2] - _task_t[1]) / 1000.0,
			t.size() - 1, worst / 1000.0, part, split])


func _on_pre_draw() -> void:
	_stamps[0] = Time.get_ticks_usec()


func _on_post_draw() -> void:
	_stamps[1] = Time.get_ticks_usec()


func _on_physics_frame() -> void:
	if _stamps[2] == 0 and _stamps[1] > 0:
		_stamps[2] = Time.get_ticks_usec()


func _on_process_frame() -> void:
	_stamps[3] = Time.get_ticks_usec()


## Waits for the worker and keeps what it made when it is still wanted.
func _drop_task() -> void:
	if _thread == null:
		return
	_gate_lock.lock()
	_abort = false  # the loading fix: the main thread waits for this one: no giving up
	_rush = true
	if _gate_waiting:
		_gate_waiting = false
		_gate.post()
	_gate_lock.unlock()
	_thread.wait_to_finish()
	_rush = false
	_thread = null
	if _task_root != null:
		if _state.has(_task_key) and _state[_task_key]["s"] == LOADING:
			_start_adding(_task_key, _task_root)
		else:
			_task_root.free()
	elif _state.has(_task_key) and _state[_task_key]["s"] == LOADING:
		_state[_task_key]["s"] = WANTED  # the loading fix: an aborted load goes back in the queue
	_task_root = null


## main.gd's state goes onto the new nodes, then they wait in a queue, the root (hidden) in the
## tree.
func _start_adding(key: Vector2i, root: Node3D) -> void:
	var t := Time.get_ticks_usec()
	_worked = true
	root.visible = false
	sector_ready.emit(root)
	# Loop 3d-2b: its slices of the baked maps go into a map slot first, one map a step.
	var slices: Array = root.get_meta("map_slices", [])
	if root.has_meta("map_slices"):
		root.remove_meta("map_slices")
	var queue: Array[Node] = []
	for c in root.get_children():
		root.remove_child(c)
		_drop_owner(c)
		queue.append(c)
	# Colliders first: the car may be about to need them.
	queue.sort_custom(func(a: Node, b: Node) -> bool: return a is StaticBody3D and not b is StaticBody3D)
	_sectors.add_child(root)
	var st: Dictionary = _state[key]
	st["s"] = ADDING
	st["root"] = root
	st["queue"] = queue
	st["maps"] = slices
	st["map_part"] = 0
	st["ms"] = float(st.get("ms", 0.0)) + (Time.get_ticks_usec() - t) / 1000.0
	_count_kind("(hand-over)", Time.get_ticks_usec() - t)


func _count_kind(kind: String, us: int) -> void:
	var k: Array = _kinds.get(kind, [0, 0, 0])
	k[0] += 1
	k[1] += us
	k[2] = maxi(k[2], us)
	_kinds[kind] = k


## A scene's nodes leave their owner (its root) before going back in one by one.
static func _drop_owner(node: Node) -> void:
	node.owner = null
	for c in node.get_children():
		_drop_owner(c)


## Adds queued nodes until the frame's budget is spent; a finished sector shows.
func _add_nodes(t0: int) -> void:
	for key in keys:
		var st: Dictionary = _state[key]
		if st["s"] != ADDING:
			continue
		var queue: Array = st["queue"]
		var root: Node3D = st["root"]
		var added := 0
		var slices: Array = st.get("maps", [])
		while not slices.is_empty() and int(st["map_part"]) < 3:
			# Loop 3d-2b: one map's slice a step, as a node is (~0.5 MB to the GPU each).
			var expect_map: int = _add_cost.get("(maps)", 300)
			if added > 0 and Time.get_ticks_usec() - t0 + expect_map > BUDGET_USEC:
				return
			var tm := Time.get_ticks_usec()
			if not map.city_maps.attach(key, slices, int(st["map_part"])):
				push_warning("sectors: no map slot for %s" % MapBuilder.sector_name(key))
				st["map_part"] = 3
				break
			st["map_part"] = int(st["map_part"]) + 1
			_worked = true
			added += 1
			var um := Time.get_ticks_usec() - tm
			_add_cost["(maps)"] = maxi(um, int(_add_cost.get("(maps)", 0) * 0.9))
			_count_kind("(maps)", um)
			st["ms"] = float(st["ms"]) + um / 1000.0
		if int(st.get("map_part", 3)) >= 3:
			st["maps"] = []
		while not queue.is_empty():
			var node: Node = queue.front()
			# The next node goes in only if what that kind cost lately still fits the budget
			# (a MultiMesh costs far more than a mesh); one always goes in, so nothing waits forever.
			var expect: int = _add_cost.get(node.get_class(), 200)
			if added > 0 and Time.get_ticks_usec() - t0 + expect > BUDGET_USEC:
				return
			var t := Time.get_ticks_usec()
			queue.pop_front()
			_worked = true
			root.add_child(node)
			added += 1
			var us := Time.get_ticks_usec() - t
			_add_cost[node.get_class()] = maxi(us, int(_add_cost.get(node.get_class(), 0) * 0.9))
			_count_kind(node.get_class(), us)
			var ms := us / 1000.0
			if log and ms > 1.0:
				print("stream: frame %d adding %s's %s %s took %.2f ms" % [frame, root.name, node.get_class(), node.name, ms])
			st["ms"] = float(st["ms"]) + ms
			if ms > float(st.get("worst", 0.0)):
				st["worst"] = ms
				st["worst_node"] = node.get_class()
		var t1 := Time.get_ticks_usec()
		_finish(key)
		var fin := Time.get_ticks_usec() - t1
		_count_kind("(finish)", fin)
		st["ms"] = float(st["ms"]) + fin / 1000.0
		sector_ms.append(float(st["ms"]))


func _finish(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	var root: Node3D = st["root"]
	root.visible = true
	map.city_maps.show(key)  # loop 3d-2b: the shaders read its map slices from now on
	if _proxy.has(key):
		(_proxy[key] as MeshInstance3D).visible = false
	st["s"] = IN
	loads += 1
	if _window_max > 0:
		load_frame_ms.append(_window_max / 1000.0)
	_window_max = 0
	sector_ready.emit(root)
	if log:
		print("stream: frame %d in %s, %.2f ms on the main thread (slowest node %.2f: %s), %.0f ms after it was wanted" % [
				frame, root.name, float(st["ms"]), float(st.get("worst", 0.0)), st.get("worst_node", "-"),
				(Time.get_ticks_usec() - int(st.get("t0", Time.get_ticks_usec()))) / 1000.0])


## Loads (or builds) and adds a sector at once (the start, a jump, a screenshot).
func _load_now(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	if st["s"] == IN:
		return
	var t := Time.get_ticks_usec()
	_worked = true
	if st["s"] != ADDING:
		_drop_task()  # the worker's sector (this one or another) goes into its queue
		if _state[key]["s"] != ADDING:
			_state[key] = {"s": LOADING, "t0": int(st.get("t0", t)), "ms": 0.0}
			_make(key)
			var root := _task_root
			_task_root = null
			if root == null:
				push_error("sectors: can't load %s" % MapBuilder.sector_name(key))
				_state[key] = {"s": QUEUED}
				return
			_start_adding(key, root)
	var queue: Array = _state[key]["queue"]
	var parent: Node3D = _state[key]["root"]
	var slices: Array = _state[key].get("maps", [])
	if not slices.is_empty() and int(_state[key].get("map_part", 0)) < 3:
		if not map.city_maps.has(key):
			_make_room(Vector3((key.x + 0.5) * SECTOR, 0.0, (key.y + 0.5) * SECTOR), true, key)
		if not map.city_maps.attach(key, slices):
			push_warning("sectors: no map slot for %s" % MapBuilder.sector_name(key))
		_state[key]["maps"] = []
		_state[key]["map_part"] = 3
	while not queue.is_empty():
		parent.add_child(queue.pop_front())
	_state[key]["ms"] = (Time.get_ticks_usec() - t) / 1000.0
	_finish(key)


## Loop 3d-2b: a free map slot (city_maps.gd SLOTS) for a sector about to load. Takes one from
## the farthest sector in full detail that is no longer wanted (kept only by the hysteresis);
## with `force` (a sector needed at once) from the farthest one not round the car's either.
## False when there is none to take.
func _make_room(focus: Vector3, force: bool, keep := Vector2i(1 << 20, 0)) -> bool:
	if map.city_maps.free_slots() > 0:
		return true
	var best := Vector2i.ZERO
	var best_d := -1.0
	for pass_force in ([false, true] if force else [false]):
		for key in keys:
			var st: Dictionary = _state[key]
			if st["s"] != IN or key == keep or (not pass_force and bool(st.get("want", false))):
				continue
			var d := (Vector2(key) + Vector2(0.5, 0.5)).distance_squared_to(Vector2(focus.x, focus.z) / SECTOR)
			if d > best_d:
				best_d = d
				best = key
		if best_d >= 0.0:
			break
	if best_d < 0.0:
		return false
	_unload(best)
	evictions += 1
	return map.city_maps.free_slots() > 0


func _unload(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	if st["s"] == LOADING:
		return  # the worker finishes it; it goes in, then out
	if st["s"] == WANTED:
		_state[key] = {"s": QUEUED}
		return
	var root: Node3D = st.get("root")
	if root != null:
		_worked = true
		var t := Time.get_ticks_usec()
		for c: Node in st.get("queue", []):
			c.free()
		root.queue_free()
		_count_kind("(unload)", Time.get_ticks_usec() - t)
	map.city_maps.detach(key)  # loop 3d-2b: its map slot is free again
	_state[key] = {"s": QUEUED}
	if _proxy.has(key):
		(_proxy[key] as MeshInstance3D).visible = true
	unloads += 1
	if log:
		print("stream: frame %d out %s" % [frame, MapBuilder.sector_name(key)])


# --- which sectors ------------------------------------------------------------------------

## The loading fix: the camera's frustum (its 8 corners, 12 edges) cut to the map's heights, as a
## rectangle on the map. Every point of a sector's box that is in the view lies over it.
func _view_box(cam: Camera3D) -> void:
	_cam = cam
	_view_ok = false
	if cam == null or not cam.is_inside_tree():
		return
	var vp := cam.get_viewport().get_visible_rect().size
	var fwd := -cam.global_transform.basis.z
	var eye := cam.global_position
	var near := PackedVector3Array()
	var far := PackedVector3Array()
	for c in [Vector2.ZERO, Vector2(vp.x, 0.0), vp, Vector2(0.0, vp.y)]:
		var o := cam.project_ray_origin(c)
		var d := cam.project_ray_normal(c)
		var o_depth := (o - eye).dot(fwd)
		var near_p := o + d * maxf(cam.near - o_depth, 0.0) / maxf(d.dot(fwd), 1e-4)
		near.append(near_p)
		far.append(o + d * maxf(cam.far - o_depth, 0.0) / maxf(d.dot(fwd), 1e-4))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 4:
		for e in [[near[i], near[(i + 1) % 4]], [far[i], far[(i + 1) % 4]], [near[i], far[i]]]:
			var a: Vector3 = e[0]
			var b: Vector3 = e[1]
			var t0 := 0.0
			var t1 := 1.0
			var dy := b.y - a.y
			if absf(dy) < 1e-6:
				if a.y < _y_range.x or a.y > _y_range.y:
					continue
			else:
				var ta := (_y_range.x - a.y) / dy
				var tb := (_y_range.y - a.y) / dy
				t0 = maxf(t0, minf(ta, tb))
				t1 = minf(t1, maxf(ta, tb))
				if t0 > t1:
					continue
			for t in [t0, t1]:
				var p: Vector3 = a.lerp(b, t)
				lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
				hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
	if lo.x <= hi.x:
		_view_rect = Rect2(lo, hi - lo)
		_view_ok = true


## The loading fix: whether the sector's square, grown by `grow`, meets `rect`.
func _square_meets(key: Vector2i, grow: float, rect: Rect2) -> bool:
	var x0 := key.x * SECTOR - grow
	var z0 := key.y * SECTOR - grow
	return x0 < rect.end.x and x0 + SECTOR + 2.0 * grow > rect.position.x and z0 < rect.end.y and z0 + SECTOR + 2.0 * grow > rect.position.y


## The west-sectors fix (2026-11-01): the views a look at a new target will show (camera_shots.gd:
## orthographic, turned `yaw` and tipped `pitch` degrees, `aspect` wide), each [centre, size (m
## tall)] in the order the camera passes them: every sector whose box (its ground to its tallest
## roof) meets one of their frusta is wanted, as the view's own test will want it once the camera
## is there (a square round the target missed the corners of a view turned 45° and tipped 30°, and
## the towers behind it: s_-6_0 west of a look at -2400, 600 loaded after the camera arrived).
## In order: the views' order, then the nearest their centres.
func expect_shot(views: Array, yaw: float, pitch: float, aspect: float, seconds: float, rank := 0) -> void:
	var want := {}
	for i in views.size():
		var at: Vector3 = views[i][0]
		var planes := ortho_planes(at, float(views[i][1]), yaw, pitch, aspect)
		for key in keys:
			if not want.has(key) and _in_view(key, 0.0, planes):
				want[key] = float(i) + (Vector2(key) + Vector2(0.5, 0.5)).distance_squared_to(Vector2(at.x, at.z) / SECTOR) * 0.01
	_add_expect(want, seconds, rank)


func _add_expect(want: Dictionary, seconds: float, rank: int) -> void:
	_expect.append([want, _clock + seconds, rank])
	_expect.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))


## The west-sectors fix: the views about to come last at least `seconds` more (main.gd, when the
## look it held for its sectors starts: the wait is over, the look itself is still to run).
func hold_expected(seconds: float) -> void:
	for e: Array in _expect:
		e[1] = maxf(float(e[1]), _clock + seconds)
	_expect.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))


## The sectors the views about to come want (of rank `max_rank` or lower), for the log and checks.
func expected_keys(max_rank := 1 << 20) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for e: Array in _expect:
		if int(e[2]) <= max_rank:
			for key: Vector2i in e[0]:
				if not out.has(key):
					out.append(key)
	return out


## The west-sectors fix: an orthographic view's four side planes (facing out, as Camera3D's
## get_frustum: a point is inside where normal . p <= d), centred on `at`, `size` m tall,
## `aspect` times as wide, the camera turned `yaw` and tipped `pitch` degrees (camera_shots.gd's
## basis). No near or far plane: a sector's box is bounded in height, so the column meets it only
## round the view's ground.
static func ortho_planes(at: Vector3, size: float, yaw: float, pitch: float, aspect: float) -> Array[Plane]:
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0))
	var hw := size * aspect * 0.5
	var hh := size * 0.5
	return [Plane(b.x, b.x.dot(at) + hw), Plane(-b.x, -b.x.dot(at) + hw),
			Plane(b.y, b.y.dot(at) + hh), Plane(-b.y, -b.y.dot(at) + hh)]


## The loading fix: whether every sector the views about to come need (of rank `max_rank` or
## lower) is in full detail.
func expected_in(max_rank := 1 << 20) -> bool:
	for e: Array in _expect:
		if int(e[2]) > max_rank:
			continue
		for key: Vector2i in e[0]:
			if _state[key]["s"] != IN:
				return false
	return true


## The loading fix: the screen's centre on the ground (x, z), where the view's nearest-first order
## measures from (the car, or where a look took the camera).
func _view_centre() -> Vector2:
	if _cam == null or not _view_ok:
		return Vector2.ZERO
	var vp := _cam.get_viewport().get_visible_rect().size
	var p := _on_ground(vp * 0.5, 0.0)
	for i in 2:
		p = _on_ground(vp * 0.5, map.ground_height(p.x, p.z))
	return Vector2(p.x, p.z)


## The loading fix: the worker gives up a sector of the last class (wanted only round the focus or
## ahead) when one in the view or a coming view waits; it stops at its next piece and the sector
## goes back in the queue.
func _check_abort(first_waits: bool) -> void:
	if not first_waits or _thread == null or _abort or _rush or not _state.has(_task_key):
		return
	if float(_state[_task_key].get("prio", FIRST_REST)) < FIRST_REST:
		return
	_abort = true
	aborts += 1
	if log:
		print("stream: frame %d the worker gives up %s for a sector in the view" % [frame, MapBuilder.sector_name(_task_key)])


## The loading fix: whether the sector's square, grown by `grow`, meets `rect` (the view's).
func _rect_meets(key: Vector2i, grow: float, rect: Rect2) -> bool:
	if not _view_ok:
		return false
	var x0 := key.x * SECTOR - grow
	var z0 := key.y * SECTOR - grow
	return x0 < rect.end.x and x0 + SECTOR + 2.0 * grow > rect.position.x and z0 < rect.end.y and z0 + SECTOR + 2.0 * grow > rect.position.y


## The loading fix's numbers, on a frame where `shown` sectors are in the view as proxies: the view's
## ground (the screen's corners and centre on the ground there), each proxy's distance from its
## centre and their share of it, and how long each has been there.
func _count_proxies(shown: Array[Vector2i]) -> void:
	if _cam == null:
		return
	var vp := _cam.get_viewport().get_visible_rect().size
	var centre := _on_ground(vp * 0.5, 0.0)
	var gy: float = map.ground_height(centre.x, centre.z)
	centre = _on_ground(vp * 0.5, gy)
	var foot := PackedVector2Array()
	for c in [Vector2.ZERO, Vector2(vp.x, 0.0), vp, Vector2(0.0, vp.y)]:
		var p := _on_ground(c, gy)
		foot.append(Vector2(p.x, p.z))
	var area := absf(_area(foot))
	var c2 := Vector2(centre.x, centre.z)
	var covered := 0.0
	for key in shown:
		var r := Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR))
		var d := Vector2(maxf(maxf(r.position.x - c2.x, 0.0), c2.x - r.end.x), maxf(maxf(r.position.y - c2.y, 0.0), c2.y - r.end.y)).length()
		proxy_near = minf(proxy_near, d)
		var sq := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		var part := 0.0
		for poly in Geometry2D.intersect_polygons(foot, sq):
			part += absf(_area(poly))
		covered += part
		var st: Dictionary = _state[key]
		if not st.has("vis_from"):
			st["vis_from"] = frame
		var run := frame - int(st["vis_from"]) + 1
		if run > proxy_run:
			proxy_run = run
			proxy_run_key = MapBuilder.sector_name(key)
		if missing_log.size() < 40:
			missing_log.append("%d %s %s %.0f m %.0f %%" % [frame, MapBuilder.sector_name(key),
					["queued", "wanted", "loading", "adding", "in"][int(st["s"])], d, part / maxf(area, 1.0) * 100.0])
	var share := covered / maxf(area, 1.0)
	proxy_share = maxf(proxy_share, share)
	if share >= PROXY_SHARE:
		proxy_share_frames += 1


## A screen point's ray on the plane y = `y` (the camera's own ray, ortho or not).
func _on_ground(px: Vector2, y: float) -> Vector3:
	var o := _cam.project_ray_origin(px)
	var d := _cam.project_ray_normal(px)
	if absf(d.y) < 1e-4:
		return o
	return o + d * ((y - o.y) / d.y)


static func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

## Whether the sector's square meets the square of half-size `reach` round `p`.
func _in_reach(key: Vector2i, p: Vector3, reach: float) -> bool:
	var x0 := key.x * SECTOR
	var z0 := key.y * SECTOR
	return p.x + reach > x0 and p.x - reach < x0 + SECTOR and p.z + reach > z0 and p.z - reach < z0 + SECTOR


## Whether the sector's box (its ground to its tallest roof, grown by `grow` metres round)
## meets the camera's frustum.
func _in_view(key: Vector2i, grow: float, planes: Array[Plane] = _view_planes) -> bool:
	if planes.is_empty():
		return false
	var h: Vector2 = map.sector_heights.get(key, Vector2(-30.0, 120.0))
	var lo := Vector3(key.x * SECTOR - grow, h.x, key.y * SECTOR - grow)
	var hi := Vector3((key.x + 1) * SECTOR + grow, h.y, (key.y + 1) * SECTOR + grow)
	# Loop 3d-2b: the box is out when its corner deepest inside a plane (the frustum's planes face
	# out) is still over it: one corner a plane, not eight (the look-ahead doubled these tests).
	for plane in planes:
		var n := plane.normal
		var inner := Vector3(hi.x if n.x < 0.0 else lo.x, hi.y if n.y < 0.0 else lo.y, hi.z if n.z < 0.0 else lo.z)
		if n.dot(inner) > plane.d:
			return false
	return true


## Loop 3d-2b: whether the sector's ground and low buildings (its lowest ground to its highest
## ground + `tall` metres, grown by `grow`) meet the camera's view: a sector in view with only its
## towers is the far level's.
func ground_in_view(key: Vector2i, grow: float, tall: float, planes: Array[Plane]) -> bool:
	var h: Vector2 = map.sector_heights.get(key, Vector2(-30.0, 120.0))
	var top: float = float(map.sector_ground.get(key, h.y)) + tall
	var lo := Vector3(key.x * SECTOR - grow, h.x, key.y * SECTOR - grow)
	var hi := Vector3((key.x + 1) * SECTOR + grow, top, (key.y + 1) * SECTOR + grow)
	for plane in planes:
		var n := plane.normal
		if n.dot(Vector3(hi.x if n.x < 0.0 else lo.x, hi.y if n.y < 0.0 else lo.y, hi.z if n.z < 0.0 else lo.z)) > plane.d:
			return false
	return true


func _scene_path(key: Vector2i) -> String:
	return "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)


func _piece_path(key: Vector2i, n: int) -> String:
	return "res://map/sectors/%s/%d.res" % [MapBuilder.sector_name(key), n]


static func _key_of(node_name: String) -> Vector2i:
	var parts := node_name.trim_prefix("p_").split("_")
	return Vector2i(int(parts[0]), int(parts[1]))
