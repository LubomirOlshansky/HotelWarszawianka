extends SceneTree
## Loop 10a: where can the car get into the water at ground level? Checked for the whole map
## without looking (the user drove onto the Vistula, and across it at 91 km/h). The water is
## the surface map's (water.bin: the river, the ponds, the fountains, map_builder.shore_distance);
## the city is built by the real map builder, the car is the real car script.
##
##  1. The water's edge, every 2 m round every water body: the car's collision box drives at it
##     from the land (straight on and 40° either side, from 2.5-8 m inland: the first start where
##     a car fits), 0.5 m at a time at the height drive_height gives it (as the car's is),
##     testing for overlap at every step; a wall stops it, or its centre gets 6 m past the edge
##     (a fountain: to its middle) and that is a gap. Neighbouring gaps are one place, named by
##     kind: under (or within 8 m of) a bridge, a fountain, a pond, the river. Within 6 m of the
##     map's rim the edge walls close it (counted apart); "no room" is edge no car fits beside.
##  2. Bridge decks over the water: every 2 m along each deck piece, the box steps sideways off
##     the piece (and past its ends) at deck height; where nothing stops it and drive_height
##     then drops it onto the water, it fell off the bridge: a deck gap.
##  3. Who else could end up in the water: lane-graph lanes (traffic, rivals, the tow), tram
##     tracks and the footways people walk (pedestrians.gd's own list and filter), at ground
##     level a metre or more past the edge.
##  4. The real car at 91 km/h, flat out, straight at the edge every 10 m: how many end up in
##     the water after 1.5 s (the walls hold at speed; nothing tunnels).
##  5. The game's own decisions (main.gd's functions on a detached copy): landing the helicopter
##     to take the car is refused over the water; the free spot next to a landed helicopter or
##     at the end of a tow is never in the water; the tow out of the water ends on dry land on
##     (or within a few metres of) a lane on the car's level; no rescue the car can do, hospital,
##     side-job door or the spawn is in the water.
##
## Prints the places and `check_water: OK` when nothing lets a car into the water (1, 2, 4),
## nobody walks or drives in it (3) and the game's decisions hold (5); else the count of
## problems and exit 1. ~17 s (6 s of it building the city).
##   godot --headless --path game --script res://tools/check_water.gd [-- --verbose --list=OUT.txt --debug=X,Z]
## --verbose lists every footway, --list writes every gap sample (x z kind) for an overlay,
## --debug prints every step of the edge probes within 2 m of X,Z, --prebuilt checks the city
## the exported game loads (the prebuilt sectors, loop 3c: their colliders and the stored water
## map) instead of building every sector from its file.

const MapBuilder := preload("res://scripts/map_builder.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Car := preload("res://scripts/car.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")
const MAP_PATH := "res://map/centrum.json"

## The car's collision box (car.gd) and how far it is lifted off the ground.
const BOX := Vector3(1.8, 1.2, 4.0)
const BOX_LIFT := 0.8
const STEP := 0.5
## Water bodies under this area are ponds (tools/bake_water.py's RIVER_AREA).
const RIVER_AREA := 20000.0
## 91 km/h: the user's screenshot.
const RAM_SPEED := 91.0 / 3.6
## The dynamic cars live on their own layer: they meet the walls (layer 1), not each other.
const CAR_LAYER := 2
## A tow ends this close to a lane (the free spot moves the car off a lane point that is taken).
const LANE_NEAR := 8.0

var map: Node3D
var graph: LaneGraph
var space: PhysicsDirectSpaceState3D
var verbose := false
var prebuilt := false
var list_path := ""
## --debug=X,Z: print every step of the edge probes within 2 m of that point.
var debug_at := Vector2.INF
var _debug := false
var _query: PhysicsShapeQueryParameters3D
var _frames := 0
var _phase := 0
var _cars: Array[Dictionary] = []
var _ram_frames := 0
## Every gap sample: [x, z, kind].
var _samples: Array = []
var _failures := 0
## Loop 3d-1: places of the demo box where a finding is listed, not failed (centre, radius, why):
## structures loop 3e builds (docs/DEMO.md 4.6). Printed with each run.
const ALLOWED := [
	# A footbridge over the basin by Czerniakowska (south-east corner, 2,316 m2 of water): its
	# deck has no parapet collider over the water yet.
	[Vector2(1605.0, 1654.0), 15.0, "the footbridge over the basin by Czerniakowska (no parapet yet)"],
	# The Wisłostrada tunnel's lanes under the river's edge by the Copernicus Science Centre: a tow
	# from the river there takes a lane point in the tunnel, which the surface map calls water.
	[Vector2(386.0, -848.0), 12.0, "the Wisłostrada tunnel's lanes by the Copernicus Science Centre (a tow picks a tunnel lane)"],
]
var allowed := 0
var _t0 := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
		elif a == "--prebuilt":
			prebuilt = true
		elif a.begins_with("--list="):
			list_path = a.trim_prefix("--list=")
		elif a.begins_with("--debug="):
			var xz := a.trim_prefix("--debug=").split(",")
			debug_at = Vector2(float(xz[0]), float(xz[1]))
	_t0 = Time.get_ticks_msec()
	# Loop 3c: the streamed city, every sector: the prebuilt sector scenes (--prebuilt) or the
	# sectors built from their files (the runtime path).
	map = SectorStreamer.open_whole(root, prebuilt)
	graph = LaneGraph.new(map.data["graph"], map)
	_query = PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = BOX
	_query.shape = box
	_query.collision_mask = 1
	print("check_water: %s in %d ms" % ["the prebuilt sectors loaded" if prebuilt else "the sectors built", Time.get_ticks_msec() - _t0])


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _phase == 0:
		space = map.get_world_3d().direct_space_state
		var t := Time.get_ticks_msec()
		_check_edges()
		_check_decks()
		_check_walkers()
		_check_tunnel_lanes()
		print("check_water: static checks in %d ms" % (Time.get_ticks_msec() - t))
		_start_ramming()
		_phase = 1
		return false
	if _phase == 1:
		_ram_frames += 1
		if _ram_frames < 90:
			return false
		_end_ramming()
		for c in _cars:
			c["car"].free()
		_cars.clear()
		_failures += _check_game()
		_write_list()
		if allowed > 0:
			print("check_water: %d findings allowed (ALLOWED)" % allowed)
		print("check_water: %s" % ("OK" if _failures == 0 else "%d FAILED" % _failures))
		map.free()
		quit(0 if _failures == 0 else 1)
		_phase = 2
	return false


# --- 1. the water's edge --------------------------------------------------------------

## Every water body's outline: [ring, kind] with kind river, pond or fountain.
func _water_rings() -> Array:
	var out: Array = []
	for a in map.data["areas"]:
		if a["k"] == "water":
			var ring := _pts(a["p"])
			out.append([ring, "river" if absf(_area(ring)) >= RIVER_AREA else "pond"])
	for s in map.data.get("surfaces", []):
		if s["k"] == "fountain":
			out.append([_pts(s["p"]), "fountain"])
	return out


func _check_edges() -> void:
	var b: Rect2 = map.bounds
	var counts := {}
	var rim := 0.0
	var no_room := 0.0
	var walled := 0.0
	var places: Array = []
	for item in _water_rings():
		var ring: PackedVector2Array = item[0]
		var kind: String = item[1]
		var centre := Vector2.ZERO
		for q in ring:
			centre += q
		centre /= maxf(ring.size(), 1)
		var run: Array = []
		var n := ring.size()
		for i in n:
			var a := ring[i]
			var c := ring[(i + 1) % n]
			var length := a.distance_to(c)
			if length < 0.01:
				continue
			var t := (c - a) / length
			var normal := Vector2(-t.y, t.x)
			# The land side: the side that isn't inside the ring.
			var land := normal if not Geometry2D.is_point_in_polygon(a.lerp(c, 0.5) + normal * 0.5, ring) else -normal
			var steps := maxi(1, ceili(length / 2.0))
			for k in steps:
				var p := a.lerp(c, (k + 0.5) / steps)
				if not map.in_map(p, -6.0):   # map north: the rim along the map's shape
					rim += length / steps
					run = _close_run(run, places)
					continue
				var target := centre if kind == "fountain" else p - land * 6.0
				_debug = p.distance_to(debug_at) < 2.0
				var result := _probe_edge(p, land, target, kind == "fountain")
				if _debug:
					print("debug: edge %s land %s -> %s" % [p, land, result])
				if result == "wall":
					walled += length / steps
					run = _close_run(run, places)
				elif result == "room":
					no_room += length / steps
					run = _close_run(run, places)
				else:
					var why := _gap_kind(p, kind)
					_samples.append([p.x, p.y, why])
					counts[why] = counts.get(why, 0.0) + length / steps
					run.append([p, why, length / steps])
		run = _close_run(run, places)
	var total := 0.0
	for k in counts:
		total += counts[k]
	print("1. water's edge: %.0f m walled, %.0f m behind the map's edge walls, %.0f m with no room for a car, %.0f m open: %s" % [
			walled, rim, no_room, total, _kinds(counts)])
	print("   %d places where a car drives into the water at ground level:" % places.size())
	places.sort_custom(func(x: Array, y: Array) -> bool: return x[1] > y[1])
	for pl in places:
		print("   %-12s %5.0f m at %6.0f, %6.0f" % [pl[0], pl[1], pl[2].x, pl[2].y])
	_failures += places.size()


## The car's box driven at `p` from the land, straight on and 40° either side, starting 2.5 to
## 8 m inland (the first start where a car fits), on to 6 m past the edge (a fountain: to
## `target`, its middle): "gap" if any of them gets there untouched, "wall" if all are
## stopped, "room" if no car fits on the land side at all.
func _probe_edge(p: Vector2, land: Vector2, target: Vector2, fountain: bool) -> String:
	var fits := false
	for angle in [0.0, 40.0, -40.0]:
		var dir := (-land).rotated(deg_to_rad(angle))
		var basis := Basis(Vector3.UP, atan2(-dir.x, -dir.y))
		for inland in [2.5, 4.0, 6.0, 8.0]:
			var start: Vector2 = p - dir * inland
			if map.shore_distance(start.x, start.y) > 0.0:
				continue
			var y: float = map.drive_height(start.x, start.y, map.terrain_height(start.x, start.y))
			_query.transform = Transform3D(basis, Vector3(start.x, y + BOX_LIFT, start.y))
			_query.motion = Vector3.ZERO
			if not space.intersect_shape(_query, 1).is_empty():
				continue
			fits = true
			if _walk(Vector3(start.x, y, start.y), basis, target if fountain else p + dir * 6.0):
				return "gap"
			break
	return "wall" if fits else "room"


## Steps the box from `from` towards `to` (x, z), 0.5 m at a time, its height from
## drive_height after every step (as the car's is), testing for overlap at every step: true if
## it gets there without touching anything. (Godot's cast_motion misses some of the concave
## shape's thin walls; at 0.5 m steps a box at least 1.8 m deep can't step over one.)
func _walk(from: Vector3, basis: Basis, to: Vector2) -> bool:
	var pos := from
	var left := Vector2(pos.x, pos.z).distance_to(to)
	var dir := (to - Vector2(pos.x, pos.z)) / maxf(left, 0.001)
	_query.motion = Vector3.ZERO
	while left > 0.01:
		var d := minf(STEP, left)
		pos += Vector3(dir.x, 0.0, dir.y) * d
		pos.y = map.drive_height(pos.x, pos.z, pos.y)
		left -= d
		_query.transform = Transform3D(basis, pos + Vector3(0.0, BOX_LIFT, 0.0))
		var hit := not space.intersect_shape(_query, 1).is_empty()
		if _debug:
			print("debug:   at %s hit %s ground %.2f" % [pos, hit, map.terrain_height(pos.x, pos.z)])
		if hit:
			return false
	return true


func _gap_kind(p: Vector2, kind: String) -> String:
	# A bridge over the edge or near it (the bake left the edge open within 6 m of a deck).
	if kind == "fountain":
		return kind
	for r in [0.0, 4.0, 8.0]:
		for k in 8 if r > 0.0 else 1:
			var q: Vector2 = p + Vector2.from_angle(TAU * k / 8.0) * r
			if map.ground_height(q.x, q.y) > map.terrain_height(q.x, q.y) + 0.5:
				return "bridge"
	return kind


func _close_run(run: Array, places: Array) -> Array:
	if run.is_empty():
		return []
	var length := 0.0
	var mid := Vector2.ZERO
	for s in run:
		length += s[2]
		mid += s[0]
	var kind: String = run[0][1]
	for s in run:
		if s[1] == "bridge":
			kind = "bridge"
	places.append([kind, length, mid / run.size()])
	return []


# --- 2. bridge decks over the water ---------------------------------------------------

func _check_decks() -> void:
	var counts := {}
	var places: Array = []
	var probes := 0
	for d: Dictionary in map._decks:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var cum: PackedFloat32Array = d["cum"]
		var run: Array = []
		var length := cum[cum.size() - 1]
		var s := 1.0
		var k := 0
		while s < length - 1.0:
			while k < pts.size() - 2 and cum[k + 1] < s:
				k += 1
			var seg := maxf(cum[k + 1] - cum[k], 0.001)
			var u := clampf((s - cum[k]) / seg, 0.0, 1.0)
			var c := pts[k].lerp(pts[k + 1], u)
			var t := (pts[k + 1] - pts[k]).normalized()
			var right := Vector2(-t.y, t.x)
			var h := lerpf(hs[k], hs[k + 1], u)
			var gap := ""
			for side in [-1.0, 1.0]:
				var half: float = float(d["r"]) if side > 0.0 else float(d["l"])
				var lat: Vector2 = right * side
				var out: Vector2 = c + lat * (half + 3.0)
				if not _falls(out, h):
					continue
				probes += 1
				var start: Vector2 = c + lat * maxf(half - 2.2, 0.0)
				var y: float = map.drive_height(start.x, start.y, h + 0.5)
				if absf(y - h) > 1.0:
					continue
				var basis := Basis(Vector3.UP, atan2(-lat.x, -lat.y))
				_query.transform = Transform3D(basis, Vector3(start.x, y + BOX_LIFT, start.y))
				_query.motion = Vector3.ZERO
				if not space.intersect_shape(_query, 1).is_empty():
					continue
				if _walk(Vector3(start.x, y, start.y), basis, out):
					gap = "deck side (%s)" % d["k"]
			if gap != "":
				_samples.append([c.x, c.y, gap])
				counts[gap] = counts.get(gap, 0.0) + 2.0
				run.append([c, gap, 2.0])
			else:
				run = _close_run(run, places)
			s += 2.0
		run = _close_run(run, places)
		# Past each end, along the piece.
		for e in [[pts[0], (pts[0] - pts[1]).normalized(), hs[0]],
				[pts[pts.size() - 1], (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized(), hs[hs.size() - 1]]]:
			var end: Vector2 = e[0]
			var along: Vector2 = e[1]
			var out: Vector2 = end + along * 4.0
			if not _falls(out, e[2]):
				continue
			probes += 1
			var start: Vector2 = end - along * 3.0
			var y: float = map.drive_height(start.x, start.y, float(e[2]) + 0.5)
			var basis := Basis(Vector3.UP, atan2(-along.x, -along.y))
			_query.transform = Transform3D(basis, Vector3(start.x, y + BOX_LIFT, start.y))
			_query.motion = Vector3.ZERO
			if space.intersect_shape(_query, 1).is_empty() and _walk(Vector3(start.x, y, start.y), basis, out):
				var why := "deck end (%s)" % d["k"]
				_samples.append([end.x, end.y, why])
				counts[why] = counts.get(why, 0.0) + 1.0
				places.append([why, 0.0, end])
	print("2. bridge decks over the water: %d places off a deck's side or end into the water (%d probes): %s" % [
			places.size(), probes, _kinds(counts)])
	for pl in places:
		print("   %-18s %5.0f m at %6.0f, %6.0f%s" % [pl[0], pl[1], pl[2].x, pl[2].y, "  (allowed: %s)" % _allowed(pl[2]) if _allowed(pl[2]) != "" else ""])
		if _allowed(pl[2]) != "":
			allowed += 1
		else:
			_failures += 1


## Loop 3d-1: why a finding at p is allowed (ALLOWED), or "".
func _allowed(p: Vector2) -> String:
	for a: Array in ALLOWED:
		if p.distance_to(a[0]) <= float(a[1]):
			return String(a[2])
	return ""


## A car at deck height h that rolled to `p` would drop onto the water there.
func _falls(p: Vector2, h: float) -> bool:
	if map.shore_distance(p.x, p.y) < 1.0:
		return false
	return map.drive_height(p.x, p.y, h + 0.5) < h - 2.0


# --- 3. lanes, trams and people -------------------------------------------------------

func _check_walkers() -> void:
	var lanes := 0
	var rim := 0
	var lane_where := {}
	for e in graph.e_a.size():
		if graph.e_tn[e] >= 0:
			continue  # loop 3a: a tunnel's lanes run under the ground (and the water), not on it
		var s := 0.0
		while s <= graph.e_len[e]:
			var y := graph.height(e, s)
			for lane in graph.e_lanes[e]:
				var q := graph.point_at(e, s, graph.lane_offset(e, lane))
				if map.shore_distance(q.x, q.y) >= 1.0 and y < map.terrain_height(q.x, q.y) + 0.5:
					if not map.in_map(q, -6.0):
						rim += 1  # beyond the edge walls: a lane running off the map
						continue
					lanes += 1
					lane_where[graph.e_name[e]] = q.round()
			s += 2.0
	var trams := 0
	for t in map.data.get("trams", []):
		if int(t.get("dk", -1)) >= 0:
			continue
		var line := _pts(t["p"])
		for i in line.size() - 1:
			var steps := maxi(1, ceili(line[i].distance_to(line[i + 1]) / 2.0))
			for k in steps:
				var q := line[i].lerp(line[i + 1], float(k) / steps)
				if map.shore_distance(q.x, q.y) >= 1.0:
					trams += 1
	# The footways people walk: pedestrians.gd's own list and the stretch of each it lets them
	# walk (a footway into the water ends a metre short of it; one through the water is left
	# out), checked again every quarter metre.
	var people := Pedestrians.new()
	people.setup(map, null, null, map.data)
	var walk := 0
	var wet_ways := 0
	var cut_ways := 0
	var walk_where := {}
	for i in people._first.size():
		if people._deck[i] >= 0:
			continue
		if people.is_wet(i):
			wet_ways += 1
			continue
		if people._lo[i] > 0.0 or people._hi[i] < people._len[i]:
			cut_ways += 1
		var s: float = people._lo[i]
		while s <= people._hi[i]:
			var q: Vector2 = people._at(i, s)
			if map.shore_distance(q.x, q.y) >= 1.0:
				walk += 1
				walk_where[i] = q.round()
			s += 0.25
	people.free()
	print("3. at ground level in the water: %d lane points (every 2 m, each lane; %d more past the map's edge walls), %d tram-track points, %d footway points people walk (%d footways; %d footways into the water now end short of it, %d through it nobody walks)" % [
			lanes, rim, trams, walk, walk_where.size(), cut_ways, wet_ways])
	for n in lane_where:
		print("   lane: %s at %s" % [n, lane_where[n]])
	if verbose:
		for i in walk_where:
			print("   footway %d at %s" % [i, walk_where[i]])
	_failures += lanes + trams + walk_where.size()


## A tunnel's own lanes run under the ground, and where the tunnel passes under the river's edge
## the surface map says water above them. The car on its tunnel lane is not in the water
## (PT stall: a careful driver in Tunel Wisłostrady "splashed" at (527,-671) and (382,-847) and was
## towed): map.in_water must be false at every tunnel lane point, at the lane's own height.
func _check_tunnel_lanes() -> void:
	var wet := 0
	var points := 0
	var where := {}
	for e in graph.e_a.size():
		if graph.e_tn[e] < 0:
			continue
		var s := 0.0
		while s <= graph.e_len[e]:
			var y := graph.height(e, s)
			for lane in graph.e_lanes[e]:
				var q := graph.point_at(e, s, graph.lane_offset(e, lane))
				points += 1
				if map.in_water(q.x, q.y, y):
					wet += 1
					where[graph.e_name[e]] = q.round()
			s += 2.0
	print("3b. tunnel lane points the car would be in the water at: %d of %d (every 2 m, each lane)" % [wet, points])
	for n in where:
		print("   tunnel lane: %s at %s" % [n, where[n]])
	_failures += wet


# --- 4. the real car at speed -----------------------------------------------------------

func _start_ramming() -> void:
	var b: Rect2 = map.bounds
	for item in _water_rings():
		var ring: PackedVector2Array = item[0]
		if item[1] == "fountain":
			continue
		var n := ring.size()
		var next := 0.0
		var run := 0.0
		for i in n:
			var a := ring[i]
			var c := ring[(i + 1) % n]
			var length := a.distance_to(c)
			if length < 0.01:
				continue
			var t := (c - a) / length
			var normal := Vector2(-t.y, t.x)
			var land := normal if not Geometry2D.is_point_in_polygon(a.lerp(c, 0.5) + normal * 0.5, ring) else -normal
			while next < run + length:
				var p := a + t * (next - run)
				next += 10.0
				if not map.in_map(p, -12.0):   # map north: the rim along the map's shape
					continue
				var start := p + land * 8.0
				if map.shore_distance(start.x, start.y) > 0.0 or map.shore_distance(p.x - land.x * 8.0, p.y - land.y * 8.0) < map.WET:
					continue
				var y: float = map.drive_height(start.x, start.y, map.terrain_height(start.x, start.y))
				var basis := Basis(Vector3.UP, atan2(land.x, land.y))
				_query.transform = Transform3D(basis, Vector3(start.x, y + BOX_LIFT, start.y))
				_query.motion = Vector3.ZERO
				if not space.intersect_shape(_query, 1).is_empty():
					continue
				var car: CharacterBody3D = Car.new()
				car.ground_height = map.drive_height
				root.add_child(car)
				car.collision_layer = CAR_LAYER
				car.collision_mask = 1
				car.global_position = Vector3(start.x, y, start.y)
				car.rotation.y = atan2(land.x, land.y)
				car.vel = Vector3(-land.x, 0.0, -land.y) * RAM_SPEED
				car.throttle = 1.0
				_cars.append({"car": car, "edge": p})
			run += length


func _end_ramming() -> void:
	var wet := 0
	for c in _cars:
		var car: CharacterBody3D = c["car"]
		var p := car.global_position
		if map.in_water(p.x, p.z, p.y):
			wet += 1
			var e: Vector2 = c["edge"]
			_samples.append([e.x, e.y, "rammed in"])
			if verbose or wet <= 20:
				print("   in the water: the car rammed at %.0f, %.0f is at %.0f, %.0f" % [e.x, e.y, p.x, p.z])
	print("4. the car at %.0f km/h flat out at the water's edge every 10 m: %d of %d end up in the water" % [
			RAM_SPEED * 3.6, wet, _cars.size()])
	_failures += wet


# --- 5. the game's own decisions -----------------------------------------------------------

func _check_game() -> int:
	var game: Node = load("res://scripts/main.gd").new()
	game.map = map
	game.graph = graph
	var car: CharacterBody3D = Car.new()
	root.add_child(car)
	car.collision_layer = CAR_LAYER
	car.global_position = Vector3(0.0, -500.0, 0.0)
	game.car = car
	var failures := 0
	var b: Rect2 = map.bounds.grow(-10.0)
	# a) Landing to give the car back: every 20 m over the map.
	var refused := 0
	var deck_ok := 0
	var wrong_land := 0
	# (Before loop 10a main.gd had no _landing_problem: only a roof stopped a landing.)
	var landing_test := game.has_method("_landing_problem")
	for z in range(ceili(b.position.y), floori(b.end.y), 20):
		for x in range(ceili(b.position.x), floori(b.end.x), 20):
			if not map.in_map(Vector2(x, z), -10.0):
				continue  # map north: the corner left outside
			var g: float = map.ground_height(x, z)
			var why: Array = game._landing_problem(Vector3(x, g, z)) if landing_test \
					else ([] if map.top_height(x, z, 3.0) <= g + 1.0 else ["roof", ""])
			# The third item names the reason (sweep 1 gave the roof toast a gloss too).
			var water_msg: bool = not why.is_empty() and (why[2] == "water" if why.size() > 2 else why[1] != "")
			if map.in_water(x, z, g):
				if water_msg or not why.is_empty():
					refused += 1  # the water, or a roof over it first (the stadium's)
				else:
					wrong_land += 1
					if wrong_land <= 5:
						print("   landing allowed on the water at %d, %d" % [x, z])
			elif water_msg:
				wrong_land += 1
				print("   landing refused on dry land at %d, %d" % [x, z])
			elif map.shore_distance(x, z) >= map.WET:
				deck_ok += 1
	print("5a. landing to give the car back, every 20 m: refused over the water at %d points, allowed on bridge decks over it at %d, wrong at %d" % [
			refused, deck_ok, wrong_land])
	failures += wrong_land
	# b) The free spot for the car (next to a landed helicopter, at the end of a tow): every
	#    10 m round the water, on the edge, 3 m out into the water and 3 m inland.
	var spots := 0
	var wet_spots := 0
	for item in _water_rings():
		if item[1] == "fountain":
			continue
		var ring: PackedVector2Array = item[0]
		var run := 0.0
		for i in ring.size():
			var a := ring[i]
			var c := ring[(i + 1) % ring.size()]
			var length := a.distance_to(c)
			if length < 0.01:
				continue
			var t := (c - a) / length
			var n := Vector2(-t.y, t.x)
			var next := ceilf(run / 10.0) * 10.0
			while next < run + length:
				var p := a + t * (next - run)
				next += 10.0
				if not map.in_map(p, -20.0):
					continue
				for o in [0.0, 3.0, -3.0]:
					var q: Vector2 = p + n * o
					var at: Vector3 = game._free_car_spot(Vector3(q.x, map.terrain_height(q.x, q.y), q.y), 0.0)
					spots += 1
					if map.in_water(at.x, at.z, at.y):
						wet_spots += 1
						if wet_spots <= 10:
							print("   free spot in the water: asked at %s, got %s" % [q.round(), Vector2(at.x, at.z).round()])
			run += length
	print("5b. the car's free spot (a landed helicopter, a tow) round the water's edge: %d of %d in the water" % [wet_spots, spots])
	failures += wet_spots
	# c) The tow out of the water: every 40 m over the water at ground level, with no place on dry
	#    land known (the worst case) and from the nearest bank.
	var tows := 0
	var bad_tows := 0
	var lane_off := PackedFloat32Array()
	var far := 0.0
	var far_at := Vector2.ZERO
	var has_tow := game.has_method("_water_tow_spot")
	for z in range(ceili(b.position.y), floori(b.end.y), 40):
		for x in range(ceili(b.position.x), floori(b.end.x), 40):
			if not map.in_map(Vector2(x, z), -10.0):
				continue  # map north: the corner left outside
			var g: float = map.terrain_height(x, z)
			if not map.in_water(x, z, g) or map.ground_height(x, z) > g + 0.5:
				continue
			if not has_tow:
				tows += 2  # before loop 10a nothing took the car out of the water
				bad_tows += 2
				continue
			for from in [Vector3.INF, _bank(Vector2(x, z))]:
				var spot: Array = game._water_tow_spot(Vector3(x, g, z), from, 0.0)
				var at: Vector3 = spot[0]
				tows += 1
				# On a lane, or beside one when the lane point itself was taken (a parked car, a wall:
				# the free spot moves it up to a few metres), on the car's level.
				var off := _lane_distance(game, at)
				var on_lane := off < LANE_NEAR
				if on_lane:
					lane_off.append(off)
				var d := Vector2(x, z).distance_to(Vector2(at.x, at.z))
				if d > far:
					far = d
					far_at = Vector2(x, z)
				if (map.shore_distance(at.x, at.z) > 0.0 or not on_lane) and _allowed(Vector2(at.x, at.z)) != "":
					allowed += 1
				elif map.shore_distance(at.x, at.z) > 0.0 or not on_lane:
					bad_tows += 1
					if bad_tows <= 10:
						print("   tow from %d, %d ended at %s (%s, %s)" % [x, z, Vector2(at.x, at.z).round(),
								"wet" if map.shore_distance(at.x, at.z) > 0.0 else "dry", "on a lane" if on_lane else "off the lanes"])
	lane_off.sort()
	var on_spot := 0
	for o in lane_off:
		if o < 0.5:
			on_spot += 1
	print("5c. the tow out of the water from %d points (every 40 m, twice): %d not by a lane on dry land; %d right on the lane, the rest %.1f m off at most (the lane point was taken); farthest tow %.0f m (from %s)" % [
			tows, bad_tows, on_spot, lane_off[lane_off.size() - 1] if not lane_off.is_empty() else 0.0, far, far_at.round()])
	failures += bad_tows
	# d) Places the game sends the car: rescue spots the car can do, hospitals, the side jobs'
	#    doors and stands, the spawn.
	var rescue: RefCounted = load("res://scripts/rescue_places.gd").new()
	rescue.map = map
	rescue.collect_road_names(map.data["roads"])
	rescue.find_streets(map.data["roads"])
	rescue.find_pois(map.data.get("pois", []))
	var places := 0
	var wet_places: Array = []
	for k in rescue.by_kind:
		for pl: Dictionary in rescue.by_kind[k]:
			if pl["heli"]:
				continue
			places += 1
			var pos: Vector3 = pl["pos"]
			if map.in_water(pos.x, pos.z, pos.y):
				wet_places.append("%s at %s" % [pl["short"], Vector2(pos.x, pos.z).round()])
	for h: Dictionary in rescue.hospitals:
		places += 1
		var pos: Vector3 = h["pos"]
		if map.in_water(pos.x, pos.z, pos.y):
			wet_places.append("hospital at %s" % Vector2(pos.x, pos.z).round())
	for poi in map.data.get("pois", []):
		if poi.has("door"):
			places += 1
			var dx: float = poi["door"][0]
			var dz: float = poi["door"][1]
			if map.in_water(dx, dz, map.terrain_height(dx, dz)):
				wet_places.append("%s door at %s" % [poi["k"], Vector2(dx, dz).round()])
	var sp: Dictionary = map.data["spawn"]
	places += 1
	if map.in_water(sp["x"], sp["z"], map.ground_height(sp["x"], sp["z"])):
		wet_places.append("the spawn")
	print("5d. places the game sends the car (rescues by car, hospitals, job doors, the spawn): %d of %d in the water %s" % [
			wet_places.size(), places, wet_places])
	failures += wet_places.size()
	game.free()
	car.free()
	return failures


## How far `at` is from the nearest lane on its level (main.gd's own rule: the ground, or within
## 4 m on a deck), over the lane graph's cells round it; INF if none within ~60 m.
func _lane_distance(game: Node, at: Vector3) -> float:
	var p := Vector2(at.x, at.z)
	var best := INF
	var seen := {}
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			for e in graph.grid.get(graph.cell_key(p + Vector2(dx, dz) * graph.CELL), []):
				if seen.has(e):
					continue
				seen[e] = true
				var s := clampf(graph.project(e, p), graph.e_s0[e], graph.e_s1[e])
				var h := graph.height(e, s)
				for lane in graph.e_lanes[e]:
					var q := graph.point_at(e, s, graph.lane_offset(e, lane))
					if game._same_level(at, q, h):
						best = minf(best, q.distance_to(p))
	return best


## The nearest dry point to p, as the place the car last stood on (at ground level).
func _bank(p: Vector2) -> Vector3:
	var q: Vector2 = map.nearest_dry(p.x, p.y)
	return Vector3(q.x, map.terrain_height(q.x, q.y), q.y)


# --- helpers ---------------------------------------------------------------------------------

func _kinds(counts: Dictionary) -> String:
	if counts.is_empty():
		return "none"
	var parts: PackedStringArray = []
	for k in counts:
		parts.append("%s %.0f m" % [k, counts[k]])
	return ", ".join(parts)


func _write_list() -> void:
	if list_path == "":
		return
	var f := FileAccess.open(list_path, FileAccess.WRITE)
	for s in _samples:
		f.store_line("%.1f %.1f %s" % [s[0], s[1], String(s[2]).replace(" ", "_")])
	f.close()
	print("check_water: %d samples written to %s" % [_samples.size(), list_path])


static func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[k], flat[k + 1]))
	return out


static func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		var a := poly[i]
		var c := poly[(i + 1) % poly.size()]
		s += a.x * c.y - c.x * a.y
	return s * 0.5
