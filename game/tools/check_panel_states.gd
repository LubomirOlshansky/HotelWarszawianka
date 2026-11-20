extends SceneTree
## W6 of the walls look (docs/design/walls-true-to-life.md 7): the broken panels shown
## (scripts/panel_states.gd) on a real sector built in the `panels` look, on both city paths. In
## SECTOR (the stadium's grounds: bars, mesh, chain link and hedges) a car is driven square through
## one soft line of each broken kind (soft_things.gd's own sweep, as check_soft_things drives it):
##   S1 a hit sets the right pieces: every instance of a panel `broke` named has its row's state
##      (down 1, torn 2, stub 3), a `down` piece the transform PanelStates.down_transform makes of
##      its baked one (on the far side of the hit: the side the car went to), every other instance
##      float for float as baked;
##   S2 the sector leaves the tree and comes back (a new root, as the streamer loads it): the same
##      pieces in the same states and transforms;
##   S3 `repair_near` stands them up: the whole buffer float for float as baked; broken again, then
##      `reset` (every `repaired` at once): as baked again;
##   S4 soft off (`set_soft(false)`, the setting and --no-soft): driving through breaks nothing and
##      writes nothing;
##   S5 the script time of a hit (a tile already read): HIT_USEC at most, over HITS panels (the 95th
##      centile and the median; the most and a tile's first read are reported);
##   S6 under `typed` (no Panels) a hit writes nothing.
## The prebuilt path: the prebuilt sector when the prebuilt city is baked `panels`
## (map/sectors/city.stamp), else the runtime sector packed and saved as a scene and loaded back
## (the MultiMesh's buffer through a .scn, as bake_city.gd saves it). Runs headless (the renderer's
## per-instance writes are then read from panel_states' `keep_live` copy) and with a renderer (then
## the MultiMesh's own buffer is compared too).
## Prints `check_panel_states: OK (...)` (exit 0) or the problems (exit 1). Needs the sector split
## (tools/setup_map.sh).
##   godot --headless --path game --script res://tools/check_panel_states.gd [-- --verbose]

const PanelStates := preload("res://scripts/panel_states.gd")
const SoftThings := preload("res://scripts/soft_things.gd")
const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")

const SECTOR := Vector2i(3, -1)
const DT := 1.0 / 60.0
const HIT_USEC := 100.0
const HITS := 200
const SAVED := "user://check_panel_states_sector.scn"

var problems: Array[String] = []
var verbose := false
var notes: Array[String] = []
var _runtime: Node3D
var _renderer := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
	_renderer = DisplayServer.get_name() != "headless"
	await process_frame
	if not FileAccess.file_exists("res://map/index.json"):
		print("PROBLEM no sector split (map/index.json): run tools/setup_map.sh")
		print("check_panel_states: 1 problems")
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	Solidity.set_barrier_look(&"panels")
	_runtime = MapBuilder.new()
	root.add_child(_runtime)
	_runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	# The edge roadworks' halos attach over a few frames (edge_roadworks.gd _attach): let them finish
	# before the map is freed at the end.
	for _i in 120:
		await process_frame
	await _path("runtime", _build_runtime)
	var baked := _baked_look()
	if baked == &"panels":
		await _path("prebuilt", _load_prebuilt)
	else:
		_save_standin()
		await _path("prebuilt (stand-in: the runtime sector through a .scn; the prebuilt city is %s)" % baked, _load_standin)
	_s6_typed()
	_runtime.free()
	if problems.is_empty():
		print("check_panel_states: OK (%s; %s; %d ms)" % ["; ".join(notes), "a renderer" if _renderer else "headless",
				Time.get_ticks_msec() - t0])
		quit(0)
	else:
		for p in problems:
			print("PROBLEM %s" % p)
		print("check_panel_states: %d problems" % problems.size())
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)
	elif verbose:
		print("   ok  %s" % what)


func _baked_look() -> StringName:
	if not FileAccess.file_exists("res://map/sectors/city.stamp"):
		return &"none"
	var stamp: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/sectors/city.stamp"))
	return StringName(str((stamp as Dictionary).get("barrier_look", "classic"))) if stamp is Dictionary else &"none"


func _build_runtime() -> Node3D:
	return _runtime.build_sector(SECTOR)


func _load_prebuilt() -> Node3D:
	var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(SECTOR)
	return (ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()


## The stand-in for a prebuilt city baked in another look: the runtime sector's Panels and its metas
## in a scene saved as bake_city.gd saves a sector.
func _save_standin() -> void:
	var built: Node3D = _runtime.build_sector(SECTOR)
	var keep := Node3D.new()
	keep.name = built.name
	for m: StringName in [&"panels", &"soft"]:
		keep.set_meta(m, built.get_meta(m))
	var panels := built.get_node(^"Panels").duplicate()
	keep.add_child(panels)
	panels.owner = keep
	built.free()
	var packed := PackedScene.new()
	var err := packed.pack(keep)
	if err == OK:
		err = ResourceSaver.save(packed, SAVED, ResourceSaver.FLAG_COMPRESS)
	keep.free()
	_expect(err == OK, "the stand-in sector saved (%s)" % error_string(err))


func _load_standin() -> Node3D:
	return (ResourceLoader.load(SAVED, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()


## S1 to S5 on one path: `make` gives the sector's root, as that path loads it.
func _path(name: String, make: Callable) -> void:
	var sec: Node3D = make.call()
	root.add_child(sec)
	var node := sec.get_node_or_null(^"Panels") as MultiMeshInstance3D
	if node == null or not sec.has_meta(&"panels") or not sec.has_meta(&"soft"):
		problems.append("%s %s: no Panels, panels meta or soft list" % [name, SECTOR])
		sec.free()
		return
	var baked := _gpu(node) if _renderer else node.multimesh.buffer
	var soft := SoftThings.new()
	root.add_child(soft)
	soft.set_physics_process(false)
	soft.add_sector(sec)
	var ps := PanelStates.new()
	ps.soft = soft
	ps.keep_live = true
	soft.broke.connect(ps.on_broke)
	soft.repaired.connect(ps.on_repaired)
	ps.add_sector(sec)
	var broke: Array = []
	soft.broke.connect(func(id: String, panel: int, _k: StringName, _at: Vector3, d: Vector3, _s: float) -> void:
		broke.append([id, panel, d]))
	var car := Car.new()
	root.add_child(car)
	car.set_physics_process(false)
	soft.car = car
	var targets := _targets(sec, baked, ps)
	_expect(targets.size() == 3, "%s: a soft line of each broken kind in %s (%s)" % [name, SECTOR, targets.keys()])
	# S1: one crossing per kind.
	var spots: Array[Vector3] = []
	for state: float in targets:
		var t: Array = targets[state]
		var before := broke.size()
		spots.append(_cross(soft, car, t))
		var got := broke.slice(before)
		var hit := false
		for e: Array in got:
			hit = hit or e[0] == t[0]
		_expect(hit, "%s S1: driving through %s (state %d) broke it (%d panels)" % [name, t[0], int(state), got.size()])
	var down := _down_of(broke)
	await _settle(ps)
	var live := _live(ps, node)
	_expect(_states(name + " S1", sec, baked, live, down, ps) > 0, "%s S1: some pieces written" % name)
	notes.append("%s: %d panels down, %d pieces written" % [name.get_slice(" ", 0), down.size(), ps.writes])
	# S2: the sector leaves and comes back.
	var before_live := live.duplicate()
	sec.free()
	await process_frame
	sec = make.call()
	root.add_child(sec)
	soft.add_sector(sec)
	ps.add_sector(sec)
	node = sec.get_node(^"Panels") as MultiMeshInstance3D
	await _settle(ps)
	live = _live(ps, node)
	_expect(live == before_live, "%s S2: after the sector left and came back the pieces are as they were (%d floats differ)" % [
			name, _differ(live, before_live)])
	# S3: repair_near, then broken again and reset.
	var stood := 0
	for at in spots:
		stood += soft.repair_near(at, 30.0)
	await _settle(ps)
	live = _live(ps, node)
	_expect(stood > 0 and soft.broken_count() == 0 and live == baked,
			"%s S3: repair_near stood %d panels up, the buffer as baked (%d floats differ, %d still broken)" % [
			name, stood, _differ(live, baked), soft.broken_count()])
	for state: float in targets:
		_cross(soft, car, targets[state])
	var again := soft.broken_count()
	soft.reset()
	await _settle(ps)
	live = _live(ps, node)
	_expect(again > 0 and live == baked, "%s S3: broken again (%d) and reset: the buffer as baked (%d floats differ)" % [
			name, again, _differ(live, baked)])
	# S5: the script time of a hit, the tile read already.
	_s5_time(name, sec, ps, soft)
	# S4: soft off.
	soft.set_soft(false)
	var writes := ps.writes
	var n_broke := broke.size()
	for state: float in targets:
		_cross(soft, car, targets[state])
	await _settle(ps)
	_expect(broke.size() == n_broke and ps.writes == writes and _live(ps, node) == baked,
			"%s S4: soft off, driving through broke %d panels and wrote %d pieces" % [name, broke.size() - n_broke,
			ps.writes - writes])
	car.free()
	soft.free()
	sec.free()
	await process_frame


## Until no write waits for a tile's read (a RenderingDevice's asynchronous read: two frames), and a
## frame more.
func _settle(ps: PanelStates) -> void:
	for _i in 30:
		await process_frame
		if ps.pending() == 0:
			break
	await process_frame
	_expect(ps.pending() == 0, "the writes waiting for a tile's read are done (%d left)" % ps.pending())


## The live buffer of `node`: the renderer's own with a renderer (and the keep_live copy the same),
## the keep_live copy headless. A tile not written yet: as baked.
func _live(ps: PanelStates, node: MultiMeshInstance3D) -> PackedFloat32Array:
	var tile: Dictionary = {}
	for k: Vector2i in ps._tiles:
		if is_same(ps._tiles[k]["node"], node):
			tile = ps._tiles[k]
	var mine: PackedFloat32Array = tile.get("live", PackedFloat32Array())
	if mine.is_empty():
		mine = _gpu(node)
	if _renderer:
		var theirs := _gpu(node)
		var first := -1
		for i in mini(theirs.size(), mine.size()):
			if theirs[i] != mine[i]:
				if first < 0:
					first = i
				if verbose:
					print("   differ at %d (instance %d float %d): renderer %s, mine %s" % [i, i / 16, i % 16, theirs[i], mine[i]])
		_expect(theirs == mine, "the renderer's buffer is panel_states' (%d floats differ; the first at %d: %s, %s)" % [
				_differ(theirs, mine), first, theirs[first] if first >= 0 else 0.0, mine[first] if first >= 0 else 0.0])
	return mine


## Per broken kind (state), one soft line in the sector: [id, a, b, foot, run at a] of a segment of it
## at least 5 m long, its first piece's row in that state.
func _targets(sec: Node3D, baked: PackedFloat32Array, ps: PanelStates) -> Dictionary:
	var meta: Dictionary = sec.get_meta(&"panels")
	var soft: Dictionary = sec.get_meta(&"soft")
	var stride := baked.size() / (sec.get_node(^"Panels") as MultiMeshInstance3D).multimesh.instance_count
	var segs: PackedFloat64Array = soft["segs"]
	var soft_ids: PackedStringArray = soft["ids"]
	var out := {}
	var ids: PackedStringArray = meta["ids"]
	for k in ids.size():
		var i: int = (meta["first"] as PackedInt32Array)[k]
		var state := ps._state_of_row(int(baked[i * stride + stride - 4] + 0.5))
		if state == PanelStates.WHOLE or out.has(state):
			continue
		var line := soft_ids.find(ids[k])
		for o in range(0, segs.size(), CityBarriers.SOFT_STRIDE):
			var a := Vector2(segs[o + 1], segs[o + 2])
			var b := Vector2(segs[o + 3], segs[o + 4])
			if int(segs[o]) == line and a.distance_to(b) >= 5.0:
				out[state] = [ids[k], a, b, segs[o + 5], segs[o + 9]]
				break
	return out


## Drives the car square through target `t` (the middle of its segment) at 10 m/s; the spot.
func _cross(soft: SoftThings, car: Car, t: Array) -> Vector3:
	var a: Vector2 = t[1]
	var b: Vector2 = t[2]
	var mid := (a + b) * 0.5
	var n := (b - a).normalized().orthogonal()
	var at := Vector3(mid.x, float(t[3]), mid.y)
	car.global_position = at - Vector3(n.x, 0.0, n.y) * 5.0
	car.rotation.y = atan2(n.x, n.y)
	car.vel = Vector3(n.x, 0.0, n.y) * 10.0
	soft.reset_motion()
	soft.step(DT)
	for _i in 60:
		car.global_position += car.vel * DT
		soft.step(DT)
	return at


## "id#panel" -> the hit's direction, for every panel broken and not repaired since.
func _down_of(broke: Array) -> Dictionary:
	var out := {}
	for e: Array in broke:
		out["%s#%d" % [e[0], e[1]]] = e[2]
	return out


## S1: every instance against the panels down: the state, the transform, the rest as baked. The
## pieces written.
func _states(what: String, sec: Node3D, baked: PackedFloat32Array, live: PackedFloat32Array, down: Dictionary,
		ps: PanelStates) -> int:
	var meta: Dictionary = sec.get_meta(&"panels")
	var ids: PackedStringArray = meta["ids"]
	var panel: PackedInt32Array = meta["panel"]
	var n_inst := panel.size()
	var stride := baked.size() / n_inst
	var c := stride - 4
	var owner := PackedStringArray()
	owner.resize(n_inst)
	for k in ids.size():
		for i in range((meta["first"] as PackedInt32Array)[k], (meta["first"] as PackedInt32Array)[k] + (meta["count"] as PackedInt32Array)[k]):
			owner[i] = ids[k]
	var written := 0
	var bad := 0
	var first_bad := ""
	for i in n_inst:
		var o := i * stride
		var key := "%s#%d" % [owner[i], panel[i]]
		var want := ps._state_of_row(int(baked[o + c] + 0.5)) if owner[i] != "" and down.has(key) else PanelStates.WHOLE
		var ok := true
		if want == PanelStates.WHOLE:
			for k in stride:
				ok = ok and live[o + k] == baked[o + k]
		else:
			written += 1
			ok = live[o + c + 2] == want and live[o + c] == baked[o + c] and live[o + c + 1] == baked[o + c + 1] \
					and live[o + c + 3] == baked[o + c + 3]
			var xf := PanelStates._transform(live, o)
			var want_xf := PanelStates._transform(baked, o)
			if want == PanelStates.DOWN:
				want_xf = PanelStates.down_transform(want_xf, down[key], owner[i], panel[i])
				# On the far side: the laid panel's far end is where the car went.
				var dir: Vector3 = down[key]
				var far := xf.origin + xf.basis.y
				ok = ok and Vector2(far.x - xf.origin.x, far.z - xf.origin.z).dot(Vector2(dir.x, dir.z)) > 0.0
				ok = ok and absf(xf.basis.z.y) > 0.9 * xf.basis.z.length()
			ok = ok and xf.is_equal_approx(want_xf)
		if not ok:
			bad += 1
			if first_bad == "":
				first_bad = "%s (instance %d, want state %d, has %.0f)" % [key, i, int(want), live[o + c + 2]]
	_expect(bad == 0, "%s: %d of %d instances not in their state or not as baked (first %s)" % [what, bad, n_inst, first_bad])
	return written


## S5: HITS panels of the sector's soft lines broken one by one through on_broke (the tile read
## already), each timed; then stood up.
func _s5_time(name: String, sec: Node3D, ps: PanelStates, soft: SoftThings) -> void:
	var meta: Dictionary = sec.get_meta(&"panels")
	var ids: PackedStringArray = meta["ids"]
	var first: PackedInt32Array = meta["first"]
	var panel: PackedInt32Array = meta["panel"]
	var at := Vector3((SECTOR.x + 0.5) * 512.0, 0.0, (SECTOR.y + 0.5) * 512.0)
	var times: Array[float] = []
	var done := []
	var step := maxi(1, ids.size() / HITS)
	for k in range(0, ids.size(), step):
		var id := ids[k]
		var p := panel[first[k]]
		var t0 := Time.get_ticks_usec()
		ps.on_broke(id, p, &"fence", at, Vector3.RIGHT, 10.0)
		times.append(float(Time.get_ticks_usec() - t0))
		done.append([id, p])
	for e: Array in done:
		ps.on_repaired(e[0], e[1])
	times.sort()
	var med := times[times.size() / 2]
	var p95 := times[int(times.size() * 0.95)]
	_expect(p95 <= HIT_USEC, "%s S5: a hit's script time %.0f µs at the 95th centile (median %.0f, most %.0f; at most %.0f)" % [
			name, p95, med, times[-1], HIT_USEC])
	notes.append("%s S5: a hit %.0f µs median, %.0f at the 95th centile, %.0f most, over %d; a tile's first read %d µs (%d reads, %s)" % [
			name.get_slice(" ", 0), med, p95, times[-1], times.size(), ps.read_usec / maxi(1, ps.reads), ps.reads,
			"asynchronous" if ps._rd != null else "at once"])


## S6: the typed look builds no Panels: panel_states notes nothing and a hit writes nothing.
func _s6_typed() -> void:
	Solidity.set_barrier_look(&"typed")
	var sec: Node3D = _runtime.build_sector(SECTOR)
	root.add_child(sec)
	var ps := PanelStates.new()
	ps.add_sector(sec)
	var soft: Dictionary = sec.get_meta(&"soft", {})
	var ids: PackedStringArray = soft.get("ids", PackedStringArray())
	if not ids.is_empty():
		ps.on_broke(ids[0], 0, &"fence", Vector3.ZERO, Vector3.RIGHT, 10.0)
	_expect(sec.get_node_or_null(^"Panels") == null and ps._tiles.is_empty() and ps.writes == 0 and ps.hits == 0,
			"S6 typed: no Panels, nothing noted, a hit writes nothing (%d tiles, %d writes)" % [ps._tiles.size(), ps.writes])
	sec.free()


## The MultiMesh's buffer as the GPU has it (the RenderingDevice's own buffer, read at once: the
## renderer's MultiMesh.buffer can answer from a copy of its own).
static func _gpu(node: MultiMeshInstance3D) -> PackedFloat32Array:
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		return node.multimesh.buffer
	return rd.buffer_get_data(RenderingServer.multimesh_get_buffer_rd_rid(node.multimesh.get_rid())).to_float32_array()


## How many floats differ between two buffers (all of the longer one's extra).
static func _differ(a: PackedFloat32Array, b: PackedFloat32Array) -> int:
	var n := absi(a.size() - b.size())
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			n += 1
	return n
