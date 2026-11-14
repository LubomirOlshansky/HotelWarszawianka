extends RefCounted
## The wall builder (docs/design/city-objects-plan.md 3.2, step 2): the city's walls, fences,
## hedges, rails and guard rails, taken out of map_builder.gd as they were. It draws them into the
## map's building surface and files their collider faces through `map._solid(class, faces)`; the
## looks are the palette's barrier types (game/data/object_palette.json "types", read through
## solidity.gd: no look is kept in code). It decides no type or class beyond what the map's barrier
## code always did (the rules below, `barrier_class`).
##
## A RefCounted the map makes once (map_builder.gd `barriers`), with the map as its reference, the
## way landmarks.gd is called: the map swaps `data` for every sector it builds, and the caches here
## (the flights, the islands, the street pass's overrides) follow that swap as they did inside the
## map. The map's own structures (the cutting's fence, a deck's railing, a tram island's railing)
## draw their rails with `railing_along`.

const Solidity := preload("res://scripts/solidity.gd")

## Operation Unslop's per-object decisions (tools/street_pass.py --apply writes them from the street
## records): {"items": {id: [verdict, style]}}. The id is road-objects.md's stable id: class, kind
## and the outline's mean rounded to a 2 m cell ("barrier:fence:-870:392"), so a re-bake keeps it.
## REMOVE leaves the barrier out; RETEXTURE / REPLACE draw it in the named placed type.
const OBJECT_OVERRIDES := "res://data/road_objects.json"

## The Royal Castle's gardens map their fountain basins, the vases' round beds and the round
## path nodes as small closed `wall` rings; drawn 1.9 m high they stood as grey drums. Inside
## GARDEN_RINGS a closed wall ring under 6 m across is a low stone kerb instead (type garden_ring).
const GARDEN_RINGS := Rect2(-620.0, -1700.0, 190.0, 220.0)

## Walls OpenStreetMap maps that stand low, not 1.9 m (F's screenshots, 2026-11-05): the 25 m
## planter edge along Wars's south front on Widok (it stood as a grey slab before the shop
## windows), and the planters round the Rotunda's stair down to the underpass (with the stair
## sunk, SUNKEN, a 1.9 m loop of wall round it read as a walled pit). Each is the line's first
## point. Also the straight wall beside Kino Muranów's fountain steps (F, 2026-11-07: a barrier
## where the square has steps). Type low_wall.
const LOW_WALLS := [Vector2(-820.1, 345.4), Vector2(-807.1, 378.0), Vector2(-1627.1, -1219.5)]

## Operation Unslop, Świętokrzyska (2026-11-06): OSM maps the planter edges inside traffic islands
## (Emilii Plater's median by the Palace: two wavy walls 95 m long) as `wall`; drawn 1.9 m high they
## read as a twisting beige ribbon across the junction. A wall lying inside a traffic island is a
## low planter edge (13 on the map), like the garden rings: a planting bed's granite kerb
## (Mapillary 2995066364107910, 2020-07), type island_edge, 0.2 m.
## Emilii Plater's invisible wall (F, 2026-11-08, a screenshot of the car stopped on the paved median
## by the Palace): the planter edges drew at island_edge's 0.2 m but kept the 1.9 m wall's collider
## (1.7 m of invisible wall, twisting across the median). A barrier drawn lower than this is a kerb
## the car climbs, like the stop platforms and the islands' own kerbs: drawn, not solid.
const BARRIER_SOLID_MIN := 0.3

## Stairs across the city (2026-11-07): the walls by the stairs. Every OSM wall stood 1.9 m high,
## so a basin's rim or a planter's edge by a flight read as a grey drum (Kino Muranów's fountain
## steps, F), a terrace's retaining wall drawn across a flight shut it, and the walls round a
## stair going down into an underpass boxed it in. Now: a wall OSM gives a height stands that high
## (`h`, tools/stairs.py); a closed ring round a fountain basin, or a small ring by a flight, is a
## low stone rim (type basin_rim); a wall crossing a flight opens STAIR_GAP past its sides (not at a
## flight's dead end, the back wall of a stairwell going on underground); a short wall wrapping a
## stair that goes down below the drawn ground (a stairwell: the grid shows under half a metre of
## its mapped drop) is a balustrade.
const STAIR_GAP := 0.25
const STAIR_RING_R := 6.0

## The Rynek's middle: a city wall's face pointing away from it faces out of the town.
const OLD_TOWN_HEART := Vector2(-805.0, -1745.0)

## Walls (and fences) drawn otherwise than OSM's 1.9 m grey wall, by the line's first point: [point, type],
## the type a placed palette type, or "" when a landmark site builds the wall itself. Kino
## Muranów's square (F, 2026-11-07, with a street photo and the aerial): the fountain basin's ring
## is the site's; the metro Ratusz Arsenał stair by the fountain has a granite parapet with a
## steel rail round it, not walls; the stairs up to the cinema's roof terrace at both ends of the
## pavilion have the terrace's white balustrade down their sides (photos 2 and 4).
const SITE_WALLS := [
	[Vector2(-1639.7, -1217.3), ""],
	[Vector2(-1667.0, -1217.7), "balustrade_white"],
	[Vector2(-1657.7, -1219.1), "balustrade_white"],
	[Vector2(-1644.7, -1190.0), "balustrade_white"],
	[Vector2(-1656.4, -1197.6), "balustrade_white"],
	[Vector2(-1624.6, -1230.3), "balustrade_rail"],
	[Vector2(-1621.2, -1219.2), "balustrade_rail"],
	[Vector2(-1625.5, -1232.3), "balustrade_rail"],
	[Vector2(-1628.1, -1232.1), "balustrade_rail"],
	# The pair of `fence` lines along the ramp south of the fountain: its handrails.
	[Vector2(-1635.1, -1234.3), "tram_railing"],
	[Vector2(-1635.7, -1235.6), "tram_railing"],
]

## A fence OSM maps along a bridge (its railing) is the deck's own parapet, which the bridge
## builds; drawn from the ground at its two ends it ran as a straight slanting fence through the
## river, and its collider stopped every boat under Most Świętokrzyski (F, 2026-11-08; two 300 m
## fences there, two 70 m ones by Most Łazienkowski). A fence with RIVER_FENCE_SHARE or more of
## its length over open water (RIVER_FENCE_M m past the shore, water.bin) is left out.
const RIVER_FENCE_M := 8.0
const RIVER_FENCE_SHARE := 0.3

## Guard rails: two rails' ends closer than this get a collider across the gap (narrower than a car).
const GUARD_JOIN := 1.5
## ...the V's depth behind the rail's line, at most (and under half the gap).
const GUARD_POCKET := 0.4

## The palette's slab and railing types as the style arrays the drawing reads, made once when the
## script loads (on the main thread; the streamer's worker only reads them): "style" {id: [colour,
## thickness, height] or, for a railing, [colour, thickness, height, [upstand, rail colour, posts,
## posts_mapped]]}, read-only; "material" {OSM `m`: id}; "fence_max" the fence type's highest
## mapped height (a solid fence mapped over it is a mesh: the 6 m ball-stop nets round the pitches).
static var _kit: Dictionary = _load_kit()

var map  # map_builder.gd: terrain, decks, the building surface's helpers, `_solid`
var guard_joins := 0
var _object_overrides := {}
var _island_boxes: Array = []
var _island_src: Array = []
var _pkin_zone := PackedVector2Array()
var _stair_src: Array = []
var _stair_idx: Array = []
var _fountain_rings: Array = []


func _init(builder) -> void:
	map = builder


static func _load_kit() -> Dictionary:
	var styles := {}
	var material := {}
	for id: StringName in Solidity.types():
		var row := Solidity.type_row(id)
		var draw := str(row["draw"])
		if draw != "slab" and draw != "railing":
			continue
		var s: Array = [str(row["colour"]), float(row["thickness"]), float(row["height"])]
		if draw == "railing":
			s.append([float(row["upstand"]), str(row["rail"]), float(row["posts"]), float(row["posts_mapped"])])
		s.make_read_only()
		styles[id] = s
		if row.has("material"):
			material[str(row["material"])] = id
	var fence := Solidity.type_row(&"fence")
	var fence_max := float((fence["h_range"] as Array)[1]) if fence.has("h_range") else INF
	return {"style": styles, "material": material, "fence_max": fence_max}


## Whether `id` names a placed type: one a street pass, the bake's `st` or SITE_WALLS may give a
## barrier (game/tools/check_object_overrides.gd).
static func is_style(id: String) -> bool:
	return bool(Solidity.type_row(StringName(id)).get("placed", false)) and (_kit["style"] as Dictionary).has(StringName(id))


## A type's style array (see `_kit`).
static func _s(id: StringName) -> Array:
	return _kit["style"][id]


## The placed type's style for `id` (an OSM line kind, a SITE_WALLS entry, `st`, an override), or
## [] when it names none.
static func _placed(id: String) -> Array:
	return _s(StringName(id)) if is_style(id) else []


## A wall material's type's value under `key` (colour, height), or `default` for a material the
## palette has no row for.
static func _material(m: String, key: String, default: Variant) -> Variant:
	var id: Variant = (_kit["material"] as Dictionary).get(m)
	return default if id == null else Solidity.type_row(id)[key]


## Type `id`'s height for a line with mapped height `h` (none: h <= 0): the type's own, or the
## mapped one clamped to the type's h_range when it has one.
static func _height(id: StringName, h: float) -> float:
	var row := Solidity.type_row(id)
	if not h > 0.0:
		return float(row["height"])
	if row.has("h_range"):
		return clampf(h, float(row["h_range"][0]), float(row["h_range"][1]))
	return h


## Type `id`'s style at mapped height `h`.
static func _sized(id: StringName, h: float) -> Array:
	var s := _s(id)
	var out: Array = [s[0], s[1], _height(id, h)]
	if s.size() > 3:
		out.append(s[3])
	return out


## A solid along a polyline whose foot follows the terrain: hedges, fences, walls,
## platforms drawn as lines. Goes into the building meshes (UV.x < 0: no windows).
func wall_along(st, poly: PackedVector2Array, width: float, height: float, col: Color, collide: bool, cls: StringName) -> void:
	var hw := width * 0.5
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.05:
			continue
		var dir := d.normalized()
		var side := Vector2(-dir.y, dir.x) * hw
		var ga: float = map.terrain_height(a.x, a.y)
		var gb: float = map.terrain_height(b.x, b.y)
		var corners := [a + side, b + side, b - side, a - side]
		var g := [ga, gb, gb, ga]
		var top: Array[Vector3] = []
		var bottom: Array[Vector3] = []
		for k in 4:
			var c: Vector2 = corners[k]
			top.append(Vector3(c.x, float(g[k]) + height, c.y))
			bottom.append(Vector3(c.x, float(g[k]) - 0.3, c.y))
		map._quad(st, top[0], top[1], top[2], top[3], Vector3.UP, col)
		for k in 4:
			var n := Vector3(corners[(k + 1) % 4].x - corners[k].x, 0, corners[(k + 1) % 4].y - corners[k].y).cross(Vector3.UP).normalized()
			map._quad(st, bottom[k], bottom[(k + 1) % 4], top[(k + 1) % 4], top[k], -n, col.darkened(0.08))
		if collide:
			for k in [0, 2]:
				var p0: Vector3 = bottom[k]
				var p1: Vector3 = bottom[(k + 1) % 4]
				var up := Vector3(0, height + 1.5, 0)
				map._solid(cls, [p0, p1, p1 + up, p0, p1 + up, p0 + up])


## An open railing along `poly`: an optional concrete upstand, then round-ish posts every 2 m and a
## top and a middle rail you can see through (Operation Unslop's tram railing and stair balustrade;
## also the map's own: the cutting's fence, a deck's railing, a tram island's railing).
## It collides like a wall of the same height, so driving stays as it was.
func railing_along(st, poly: PackedVector2Array, height: float, upstand: float, up_col: Color, rail_col: Color, collide: bool,
		cls: StringName, post_every := 2.0, base := NAN, base_end := NAN) -> void:
	if upstand > 0.0:
		wall_along(st, poly, 0.2, upstand, up_col, false, cls)
	var run := 0.0
	var next_post := 0.0
	var low := maxf(upstand, 0.0) + (0.1 if upstand > 0.0 else 0.35)
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var dir := (b - a) / length
		var side := Vector2(-dir.y, dir.x) * 0.03
		# `base`: the railing stands on a slab at that height (a tram island), not on the ground.
		var ga: float = map.terrain_height(a.x, a.y) if is_nan(base) else base
		var gb: float = map.terrain_height(b.x, b.y) if is_nan(base) else (base if is_nan(base_end) else base_end)
		var n := Vector3(side.x, 0, side.y).normalized()
		for h in [low, height - 0.05]:
			for sgn in [1.0, -1.0]:
				var o: Vector2 = side * sgn
				map._quad(st, Vector3(a.x + o.x, ga + h, a.y + o.y), Vector3(b.x + o.x, gb + h, b.y + o.y),
						Vector3(b.x + o.x, gb + h + 0.05, b.y + o.y), Vector3(a.x + o.x, ga + h + 0.05, a.y + o.y), n * sgn, rail_col)
			map._quad(st, Vector3(a.x + side.x, ga + h + 0.05, a.y + side.y), Vector3(b.x + side.x, gb + h + 0.05, b.y + side.y),
					Vector3(b.x - side.x, gb + h + 0.05, b.y - side.y), Vector3(a.x - side.x, ga + h + 0.05, a.y - side.y), Vector3.UP, rail_col.lightened(0.12))
		while next_post <= run + length:
			var p := a + dir * (next_post - run)
			var y := lerpf(ga, gb, (next_post - run) / length)
			var bottom := maxf(upstand, 0.0)
			map._box_oriented(st, Vector3(p.x, y + (bottom + height) * 0.5, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)),
					Vector3(0.06, height - bottom, 0.06), rail_col)
			next_post += post_every
		run += length
		if collide:
			map._solid(cls, [Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + height + 1.5, b.y),
					Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + height + 1.5, b.y), Vector3(a.x, ga + height + 1.5, a.y)])


func _load_object_overrides() -> void:
	_object_overrides = {}
	if not FileAccess.file_exists(OBJECT_OVERRIDES):
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECT_OVERRIDES))
	if j is Dictionary and (j as Dictionary).get("items") is Dictionary:
		_object_overrides = j["items"]


## The stable id of a barrier line (tools/street_pass.py stable_id: the mean of its points, each
## coordinate floor(c / 2 + 0.5) * 2).
static func barrier_id(kind: String, flat: Array) -> String:
	var n := flat.size() / 2
	var cx := 0.0
	var cz := 0.0
	for i in n:
		cx += float(flat[i * 2])
		cz += float(flat[i * 2 + 1])
	cx /= maxf(n, 1)
	cz /= maxf(n, 1)
	return "barrier:%s:%d:%d" % [kind, int(floor(cx / 2.0 + 0.5)) * 2, int(floor(cz / 2.0 + 0.5)) * 2]


func _garden_ring(flat: Array) -> bool:
	var n := flat.size() / 2
	if n < 4 or not GARDEN_RINGS.has_point(Vector2(flat[0], flat[1])):
		return false
	var first := Vector2(flat[0], flat[1])
	if first.distance_to(Vector2(flat[n * 2 - 2], flat[n * 2 - 1])) > 0.3:
		return false
	var c := Vector2.ZERO
	for i in n - 1:
		c += Vector2(flat[i * 2], flat[i * 2 + 1])
	c /= n - 1
	for i in n:
		if c.distance_to(Vector2(flat[i * 2], flat[i * 2 + 1])) > 6.0:
			return false
	return true


func _low_wall(flat: Array) -> bool:
	if flat.size() < 4:
		return false
	var first := Vector2(flat[0], flat[1])
	for at: Vector2 in LOW_WALLS:
		if first.distance_to(at) < 0.5:
			return true
	return false


## Whether a wall line's centre lies in the Palace of Culture's grounds (map_builder.gd
## pkin_grounds, `zone`): there a wall is the knee-high type pkin_wall, or a 1 m granite
## balustrade where it rims a flight of steps (Mapillary 1174856613029600, 2021-03, the south
## court; 2909087812705418, 2020-12, Emilii Plater).
func _in_pkin_zone(flat: Array) -> bool:
	if _pkin_zone.is_empty():
		_pkin_zone = map._pts(map.pkin_grounds().get("zone", []))
		if _pkin_zone.is_empty():
			return false
	var n := flat.size() / 2
	if n < 1:
		return false
	var c := Vector2.ZERO
	for i in n:
		c += Vector2(flat[i * 2], flat[i * 2 + 1])
	return Geometry2D.is_point_in_polygon(c / n, _pkin_zone)


## Whether a wall line passes within 2.5 m of a flight of steps (the underpass and terrace stairs).
func _by_steps(flat: Array) -> bool:
	var pts: PackedVector2Array = map._pts(flat)
	var box: Rect2 = map._box_of_pts(pts).grow(2.5)
	for s in map.data.get("steps", []):
		var sp: PackedVector2Array = map._pts(s["p"])
		if sp.is_empty() or not box.intersects(map._box_of_pts(sp)):
			continue
		for q in sp:
			for i in pts.size() - 1:
				if Geometry2D.get_closest_point_to_segment(q, pts[i], pts[i + 1]).distance_to(q) < 2.5:
					return true
	return false


func _in_island(flat: Array) -> bool:
	# `data` is swapped for every sector the builder makes: rebuild the boxes when it changes
	# (a cache from the first sector left every later sector's median walls at 1.9 m).
	var src: Array = map.data.get("islands", [])
	if not is_same(src, _island_src):
		_island_src = src
		_island_boxes.clear()
		for isl in src:
			var poly := PackedVector2Array()
			var fp: Array = isl["p"]
			for i in fp.size() / 2:
				poly.append(Vector2(fp[i * 2], fp[i * 2 + 1]))
			var box := Rect2(poly[0], Vector2.ZERO)
			for q in poly:
				box = box.expand(q)
			_island_boxes.append([box, poly])
	var n := flat.size() / 2
	if n < 2:
		return false
	for e in _island_boxes:
		var box: Rect2 = e[0]
		if not box.has_point(Vector2(flat[0], flat[1])):
			continue
		var inside := 0
		for i in n:
			if Geometry2D.is_point_in_polygon(Vector2(flat[i * 2], flat[i * 2 + 1]), e[1]):
				inside += 1
		if inside * 5 >= n * 4:
			return true
	return false


## The flights of `data` for the wall rules: [poly, half width, box, end open flags, stairwell].
func _stairs_for_walls() -> Array:
	var src: Array = map.data.get("steps", [])
	if is_same(src, _stair_src):
		return _stair_idx
	_stair_src = src
	_stair_idx = []
	_fountain_rings = []
	var on_path := {}    # 1 m cells holding a footway's point
	var flight_ends := {}  # 1 m cells holding a flight's end: how many
	for p in map.data.get("paths", []):
		var fp: Array = p["p"]
		for i in fp.size() / 2:
			on_path[Vector2i(floori(fp[i * 2]), floori(fp[i * 2 + 1]))] = true
	for s in src:
		var fp: Array = s["p"]
		for i in [0, fp.size() / 2 - 1]:
			var c := Vector2i(floori(fp[i * 2]), floori(fp[i * 2 + 1]))
			flight_ends[c] = int(flight_ends.get(c, 0)) + 1
	for s in src:
		var poly: PackedVector2Array = map._pts(s["p"])
		if poly.size() < 2:
			continue
		var open := PackedByteArray([0, 0])
		for e in 2:
			var q := poly[0] if e == 0 else poly[poly.size() - 1]
			var own := Vector2i(floori(q.x), floori(q.y))
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					var c := own + Vector2i(dx, dz)
					# A footway's point, or another flight's end (its own counts once).
					if on_path.has(c) or int(flight_ends.get(c, 0)) > (1 if c == own else 0):
						open[e] = 1
		var mapped: float = float(s.get("n", 0)) * map.STAIR_RISER
		var grid := absf(map.terrain_height(poly[0].x, poly[0].y) - map.terrain_height(poly[poly.size() - 1].x, poly[poly.size() - 1].y))
		var well: bool = mapped >= 1.0 and grid < 0.5
		_stair_idx.append([poly, clampf(float(s.get("w", 2.4)), 1.0, 30.0) * 0.5, map._box_of_pts(poly).grow(4.0), open, well])
	for a in map.data.get("surfaces", []):
		if a.get("k") == "fountain":
			var ring: PackedVector2Array = map._pts(a["p"])
			_fountain_rings.append([ring, map._box_of_pts(ring).grow(1.5)])
	return _stair_idx


## Whether closed wall ring `pts` is a basin's or planter's rim: it follows a fountain's
## outline, or it is under STAIR_RING_R across and stands within 4 m of a flight.
func _rim_ring(pts: PackedVector2Array) -> bool:
	if pts.size() < 4 or pts[0].distance_to(pts[pts.size() - 1]) > 0.3:
		return false
	var box: Rect2 = map._box_of_pts(pts)
	for f in _fountain_rings:
		if not (f[1] as Rect2).intersects(box):
			continue
		var ring: PackedVector2Array = f[0]
		var near := 0
		for q in pts:
			if _dist_to_ring(q, ring) < 1.5:
				near += 1
		if near * 5 >= pts.size() * 3:
			return true
	var c := box.get_center()
	for q in pts:
		if q.distance_to(c) > STAIR_RING_R:
			return false
	for e in _stair_idx:
		if not (e[2] as Rect2).intersects(box):
			continue
		var poly: PackedVector2Array = e[0]
		for q in pts:
			if _dist_to_line(q, poly) < 4.0:
				return true
	return false


static func _dist_to_line(p: Vector2, poly: PackedVector2Array) -> float:
	var best := INF
	for i in poly.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, poly[i], poly[i + 1])))
	return best


static func _dist_to_ring(p: Vector2, ring: PackedVector2Array) -> float:
	var best := _dist_to_line(p, ring)
	if ring.size() > 2:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, ring[ring.size() - 1], ring[0])))
	return best


## Whether wall `pts` wraps a stairwell (all of it within its half width + 2.5 m, at most 30 m).
func _wraps_stairwell(pts: PackedVector2Array) -> bool:
	var box: Rect2 = map._box_of_pts(pts)
	var length := 0.0
	for i in pts.size() - 1:
		length += pts[i].distance_to(pts[i + 1])
	if length > 30.0:
		return false
	for e in _stair_idx:
		if not bool(e[4]) or not (e[2] as Rect2).intersects(box):
			continue
		var all_near := true
		for q in pts:
			if _dist_to_line(q, e[0]) > float(e[1]) + 2.5:
				all_near = false
				break
		if all_near:
			return true
	return false


## Wall `pts` cut open where it crosses a flight (STAIR_GAP past the flight's sides along the
## wall), except at a flight's dead end. Returns the pieces.
func _stair_gaps(pts: PackedVector2Array) -> Array[PackedVector2Array]:
	var cuts: Array[Vector2] = []   # (distance along the wall, half gap)
	var box: Rect2 = map._box_of_pts(pts)
	var run := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var l := a.distance_to(b)
		for e in _stair_idx:
			if not (e[2] as Rect2).intersects(box):
				continue
			var poly: PackedVector2Array = e[0]
			for j in poly.size() - 1:
				var x: Variant = Geometry2D.segment_intersects_segment(a, b, poly[j], poly[j + 1])
				if x == null:
					continue
				var hit: Vector2 = x
				# At a dead end (within 1 m of an end no path meets) the wall stays shut.
				var open: PackedByteArray = e[3]
				if (hit.distance_to(poly[0]) < 1.0 and open[0] == 0) or (hit.distance_to(poly[poly.size() - 1]) < 1.0 and open[1] == 0):
					continue
				var sin_a := absf((b - a).normalized().cross((poly[j + 1] - poly[j]).normalized()))
				var half := minf((float(e[1]) + STAIR_GAP) / maxf(sin_a, 0.35), 8.0)
				cuts.append(Vector2(run + a.distance_to(hit), half))
		run += l
	var out: Array[PackedVector2Array] = []
	if cuts.is_empty():
		out.append(pts)
		return out
	# Walk the wall keeping what lies outside every cut.
	var piece := PackedVector2Array()
	run = 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var l := a.distance_to(b)
		var marks: Array[float] = [0.0, l]
		for c: Vector2 in cuts:
			for t in [c.x - c.y - run, c.x + c.y - run]:
				if t > 0.0 and t < l:
					marks.append(t)
		marks.sort()
		for m in marks.size() - 1:
			var t0: float = marks[m]
			var t1: float = marks[m + 1]
			var mid := run + (t0 + t1) * 0.5
			var inside := false
			for c: Vector2 in cuts:
				if absf(mid - c.x) < c.y:
					inside = true
			var p0 := a.lerp(b, t0 / maxf(l, 0.0001))
			var p1 := a.lerp(b, t1 / maxf(l, 0.0001))
			if inside:
				if piece.size() >= 2:
					out.append(piece)
				piece = PackedVector2Array()
			else:
				if piece.is_empty() or piece[piece.size() - 1].distance_to(p0) > 0.001:
					piece.append(p0)
				piece.append(p1)
		run += l
	if piece.size() >= 2:
		out.append(piece)
	return out


## Walls, fences and hedges from the map's own data (F, 2026-11-07: "what else can you improve in
## the city environment?"; tools/barrier_tags.py). A wall's material (`m`) gives its colour (a
## noise barrier with no height stands 4 m: the wall_<material> types); a fence OSM calls a railing
## (`ft`: railing, bars, balustrade, metal) is an open steel railing you see through (fence_railing),
## a chain-link one an open grey mesh (fence_mesh), a wooden one brown boards (fence_wood); a hedge
## or fence keeps its mapped height (`h`, in its type's h_range). A solid fence mapped over the
## fence type's range (the 6 m ball-stop nets round the pitches) is a mesh, not a 6 m grey band.
## A style a rule above picked for its place (a basin rim, a garden ring, a stairwell) stays.
func _mapped_style(l: Dictionary, style: Array) -> Array:
	var k: String = l["k"]
	var base := _placed(k)
	if base.is_empty() or style != base:
		# Already a wall height (`h`, the stairs pass) or a placed style: only a colour for a wall.
		if k == "wall" and l.has("m") and style.size() == 3 and style != _s(&"garden_ring") and style != _s(&"basin_rim") \
				and style != _s(&"low_wall") and style != _s(&"island_edge"):
			return [_material(str(l["m"]), "colour", style[0]), style[1], style[2]]
		return style
	var h := float(l.get("h", -1.0))
	match k:
		"wall":
			var m := str(l.get("m", ""))
			var col: String = _material(m, "colour", style[0])
			var wh := h if h > 0.0 else float(_material(m, "height", style[2]))
			return [col, style[1], wh]
		"fence":
			var ft := str(l.get("ft", ""))
			if ft == "railing":
				return _sized(&"fence_railing", h)
			if ft == "mesh" or h > float(_kit["fence_max"]):
				return _sized(&"fence_mesh", h)
			if ft == "wood":
				return _sized(&"fence_wood", h)
			if h > 0.0:
				return [style[0], style[1], _height(&"fence", h)]
		"hedge":
			if h > 0.0:
				return [style[0], style[1], _height(&"hedge", h)]
	return style


## The Old Town's defence walls (OSM barrier=city_wall areas, `citywalls`, tools/barrier_tags.py):
## they were not on the map at all, only the Barbakan and two towers. Brick, each its mapped height
## (Baszta Rycerska 13.5 m; the rebuilt curtain walls 5-6 m; the ruins' stubs 1-1.5 m), the coping a
## shade darker; from 1 m up they stop the car like any wall.
## The trailer pass (F, 2026-11-08, F's photos E14-E16 of Międzymurze Biegańskiego and Podwale): the
## coping a pale brick cap, and the curtain walls from the type's merlon_from m up crenellated on
## their outer face (the one facing away from the Rynek): wide merlons with narrow embrasures. The
## look is the palette's city_wall type.
func build_city_walls(st) -> void:
	var kit := Solidity.type_row(&"city_wall")
	var cap := Color(str(kit["cap"]))
	var body := Color(str(kit["colour"]))
	map._uv2 = Vector2(0.5, -1.0)
	for w in map.data.get("citywalls", []):
		var ring: PackedVector2Array = map._pts(w["p"])
		if ring.size() < 3:
			continue
		var h := float(w.get("h", 5.0))
		var tops := PackedFloat32Array()
		var foot := INF
		for q in ring:
			foot = minf(foot, map.terrain_height(q.x, q.y))
		for q in ring:
			tops.append(maxf(map.terrain_height(q.x, q.y), foot) + h)
		var idx := Geometry2D.triangulate_polygon(ring)
		for i in range(0, idx.size(), 3):
			var a := ring[idx[i]]
			var b := ring[idx[i + 1]]
			var c := ring[idx[i + 2]]
			map._tri(st, Vector3(a.x, tops[idx[i]], a.y), Vector3(b.x, tops[idx[i + 1]], b.y), Vector3(c.x, tops[idx[i + 2]], c.y),
					Vector3.UP, cap)
		var ccw := 0.0
		for i in ring.size():
			ccw += ring[i].cross(ring[(i + 1) % ring.size()])
		for i in ring.size():
			var j := (i + 1) % ring.size()
			var a := ring[i]
			var b := ring[j]
			var d := b - a
			if d.length() < 0.02:
				continue
			# The outward normal (the ring's winding decides which side is out).
			var n := Vector3(d.y, 0.0, -d.x).normalized() * (1.0 if ccw > 0.0 else -1.0)
			var ga: float = map.terrain_height(a.x, a.y) - 0.3
			var gb: float = map.terrain_height(b.x, b.y) - 0.3
			var shade := body.darkened(0.04 * float(i % 3))
			map._quad(st, Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, tops[j], b.y), Vector3(a.x, tops[i], a.y), n, shade)
			if h >= 1.0:
				map._solid(&"wall", [Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, tops[j] + 1.5, b.y),
						Vector3(a.x, ga, a.y), Vector3(b.x, tops[j] + 1.5, b.y), Vector3(a.x, tops[i] + 1.5, a.y)])
			if h >= float(kit["merlon_from"]) and Vector2(n.x, n.z).dot((a + b) * 0.5 - OLD_TOWN_HEART) > 0.0:
				_merlons(st, kit, a, b, tops[i], tops[j], Vector2(n.x, n.z), _wall_depth(ring))
		if _is_wall_tower(ring, h):
			_tower_roof(st, kit, ring, maxf(tops[0], tops[ring.size() / 2]))
	map._uv2 = Vector2.ZERO


## Whether a city-wall ring is a tower (Baszta Rycerska, the Altana): compact (at most 12 m
## across, 15-60 m2) and at least 5 m high. The wall strips are long and thin; the little stairs
## and rubble rings are lower or smaller.
func _is_wall_tower(ring: PackedVector2Array, h: float) -> bool:
	if h < 5.0 or ring.size() < 6:
		return false
	var lo := Vector2(INF, INF)
	var hi := -lo
	var area := 0.0
	for i in ring.size():
		lo = lo.min(ring[i])
		hi = hi.max(ring[i])
		area += ring[i].cross(ring[(i + 1) % ring.size()])
	return absf(area) * 0.5 >= 15.0 and absf(area) * 0.5 <= 60.0 and maxf(hi.x - lo.x, hi.y - lo.y) <= 12.0


## A tower's tile cone (F, 2026-11-09, photos E14-E16): the ring pushed out 0.45 m into an eave
## at the tower's top, a steep cone in the city_wall type's roof colour over the ring's middle, a
## ball and a spike.
func _tower_roof(st, kit: Dictionary, ring: PackedVector2Array, top: float) -> void:
	var tile := Color(str(kit["roof"]))
	var c := Vector2.ZERO
	for q in ring:
		c += q
	c /= ring.size()
	var rad := 0.0
	for q in ring:
		rad = maxf(rad, q.distance_to(c))
	var rise := rad * 1.7 + 1.5
	var apex := Vector3(c.x, top + rise, c.y)
	var scale := 1.0 + 0.45 / maxf(rad, 1.0)
	for i in ring.size():
		var a := c + (ring[i] - c) * scale
		var b := c + (ring[(i + 1) % ring.size()] - c) * scale
		var pa := Vector3(a.x, top, a.y)
		var pb := Vector3(b.x, top, b.y)
		var n := (pb - pa).cross(apex - pa).normalized()
		if n.y < 0.0:
			n = -n
		map._tri(st, pa, pb, apex, n, tile.darkened(0.04 * float(i % 3)))
	map._tri(st, Vector3(c.x - 0.1, top + rise, c.y), Vector3(c.x + 0.1, top + rise, c.y), Vector3(c.x, top + rise + 1.6, c.y), Vector3.UP,
			Color(str(kit["cap"])))


## A wall ring's thickness, about: twice its area over its perimeter (a long thin strip), at most
## 1.2 m (a merlon on a tower's ring would otherwise be as deep as the tower).
func _wall_depth(ring: PackedVector2Array) -> float:
	var area := 0.0
	var per := 0.0
	for i in ring.size():
		var q := ring[(i + 1) % ring.size()]
		area += ring[i].cross(q)
		per += ring[i].distance_to(q)
	return clampf(absf(area) / maxf(per, 0.1), 0.45, 1.2)


## Merlons along one outer edge of a city wall (a..b, its top at ta..tb, `out` its outward
## normal): a row of brick blocks the city_wall type's `merlon` wide, `crenel` apart, set in from
## the edge's ends, each with a pale cap.
func _merlons(st, kit: Dictionary, a: Vector2, b: Vector2, ta: float, tb: float, out: Vector2, depth: float) -> void:
	var body := Color(str(kit["colour"]))
	var merlon := float(kit["merlon"])
	var crenel := float(kit["crenel"])
	var length := a.distance_to(b)
	var step := merlon + crenel
	var count := floori((length - crenel) / step)
	if count < 1:
		return
	var d := (b - a) / length
	var inward := -out.normalized()
	var start := (length - (count * step - crenel)) * 0.5
	for k in count:
		var s0 := start + k * step
		var s1 := s0 + merlon
		var top0 := lerpf(ta, tb, s0 / length)
		var top1 := lerpf(ta, tb, s1 / length)
		var p0 := a + d * s0
		var p1 := a + d * s1
		var q0 := p0 + inward * depth
		var q1 := p1 + inward * depth
		var up0 := top0 + float(kit["merlon_h"])
		var up1 := top1 + float(kit["merlon_h"])
		var o3 := Vector3(out.x, 0.0, out.y).normalized()
		var d3 := Vector3(d.x, 0.0, d.y)
		map._quad(st, Vector3(p0.x, top0, p0.y), Vector3(p1.x, top1, p1.y), Vector3(p1.x, up1, p1.y), Vector3(p0.x, up0, p0.y), o3, body)
		map._quad(st, Vector3(q1.x, top1, q1.y), Vector3(q0.x, top0, q0.y), Vector3(q0.x, up0, q0.y), Vector3(q1.x, up1, q1.y), -o3, body.darkened(0.08))
		map._quad(st, Vector3(q0.x, top0, q0.y), Vector3(p0.x, top0, p0.y), Vector3(p0.x, up0, p0.y), Vector3(q0.x, up0, q0.y), -d3, body.darkened(0.04))
		map._quad(st, Vector3(p1.x, top1, p1.y), Vector3(q1.x, top1, q1.y), Vector3(q1.x, up1, q1.y), Vector3(p1.x, up1, p1.y), d3, body.darkened(0.04))
		map._quad(st, Vector3(p0.x, up0, p0.y), Vector3(p1.x, up1, p1.y), Vector3(q1.x, up1, q1.y), Vector3(q0.x, up0, q0.y), Vector3.UP,
				Color(str(kit["cap"])))


## The SITE_WALLS entry for a wall line, or [] when it has none.
func _site_wall(flat: Array) -> Array:
	if flat.size() < 4:
		return []
	var first := Vector2(flat[0], flat[1])
	for e: Array in SITE_WALLS:
		if first.distance_to(e[0]) < 0.5:
			return e
	return []


## The city objects plan, step 1: a barrier line's solid class, from its kind (`fence`, `hedge`,
## `wall`; a `platform` line never collides); a wall or fence the bake gave a stair's balustrade
## style (`st`, tools/object_fixes.py: beside a flight of steps) is a `stair_wall`, whatever style
## a street pass draws it in.
static func barrier_class(l: Dictionary) -> StringName:
	if str(l.get("st", "")).begins_with("balustrade"):
		return &"stair_wall"
	return StringName(str(l["k"]))


## Every barrier line of `data` (`lines`: hedge, fence, wall, platform) in its type, by the rules
## above, into the building surface `st`.
func build_barriers(st) -> void:
	map._uv2 = Vector2(0.5, -1.0)
	_load_object_overrides()
	_stairs_for_walls()
	for l in map.data.get("lines", []):
		var site_wall: Array = _site_wall(l["p"]) if l["k"] == "wall" or l["k"] == "fence" else []
		if not site_wall.is_empty() and str(site_wall[1]) == "":
			continue
		if l["k"] != "platform" and map._in_pkin_forecourt(l["p"]):
			continue
		if map._in_trybuna(l["p"]):
			continue
		if l["k"] == "fence" and _over_river(l["p"]):
			continue
		var style: Array = _placed(str(l["k"]))
		if style.is_empty():
			style = _s(&"barrier_default")
		if not site_wall.is_empty():
			style = _placed(str(site_wall[1]))
		elif l["k"] == "wall":
			if _garden_ring(l["p"]):
				style = _s(&"garden_ring")
			elif _low_wall(l["p"]):
				style = _s(&"low_wall")
			elif _in_island(l["p"]):
				style = _s(&"island_edge")
			elif _in_pkin_zone(l["p"]):
				style = _placed("balustrade") if _by_steps(l["p"]) else _s(&"pkin_wall")
			elif l.has("h"):
				var wh := float(l["h"])
				var wall := Solidity.type_row(&"wall")
				style = [style[0], float(wall["low_thickness"]) if wh <= float(wall["low_height"]) else float(wall["thickness"]), wh]
			elif _rim_ring(map._pts(l["p"])):
				style = _s(&"basin_rim")
			elif _wraps_stairwell(map._pts(l["p"])):
				style = _placed("balustrade_rail")
		style = _mapped_style(l, style)
		# Street objects unslopped (tools/object_fixes.py, 2026-11-07): a barrier's own style, the
		# balustrade of a wall or fence beside a flight of steps that OSM gives no height, material or
		# fence type (tools/barrier_tags.py's tags win: object_fixes leaves tagged lines alone).
		# A street pass's override still wins.
		if site_wall.is_empty() and l.has("st") and is_style(str(l["st"])):
			style = _placed(str(l["st"]))
		if not _object_overrides.is_empty() and l["k"] != "platform":
			var o: Variant = _object_overrides.get(barrier_id(l["k"], l["p"]))
			if o is Array:
				if str(o[0]) == "REMOVE":
					continue
				if (o as Array).size() > 1 and is_style(str(o[1])):
					style = _placed(str(o[1]))
		var pts: PackedVector2Array = map._pts(l["p"])
		var solid: bool = l["k"] != "platform" and float(style[2]) >= BARRIER_SOLID_MIN
		var cls := barrier_class(l)
		if style.size() > 3:
			var open: Array = style[3]
			# A railing OSM maps (tools/barrier_tags.py) has a post every `posts_mapped` m: 30 km of them.
			railing_along(st, pts, float(style[2]), float(open[0]), Color(style[0]), Color(str(open[1])), true, cls,
					float(open[3]) if l.has("ft") or (l["k"] == "fence" and float(l.get("h", 0.0)) > float(_kit["fence_max"])) else float(open[2]))
			continue
		# Loop 3b: a stop's platform is kerb height (0.25 m), not a wall: like the kerbs and
		# islands, the car drives over it (check_drive.gd found buses brushing them).
		if l["k"] == "wall" and not map._sunk.is_empty() and map._sunk_box.grow(2.0).intersects(map._box_of_pts(pts)):
			# The pieces off a sunken ring's edge (the site builds the walls on it).
			if map._walls_in_ramp(pts):
				continue
			var piece := PackedVector2Array()
			for i in pts.size():
				if i > 0 and map._on_sunk_edge(pts[i - 1], pts[i]):
					if piece.size() >= 2:
						wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), solid, cls)
					piece = PackedVector2Array()
				piece.append(pts[i])
			if piece.size() >= 2:
				wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), solid, cls)
			continue
		if l["k"] == "wall" and not _stair_idx.is_empty():
			for piece in _stair_gaps(pts):
				wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), solid, cls)
			continue
		wall_along(st, pts, float(style[1]), float(style[2]), Color(style[0]), solid, cls)
	map._uv2 = Vector2.ZERO


func _over_river(flat: Array) -> bool:
	if map._shore_zip.is_empty() and map._shore.is_empty():
		return false
	var wet := 0
	var n := 0
	for i in range(0, flat.size() - 3, 2):
		var a := Vector2(float(flat[i]), float(flat[i + 1]))
		var b := Vector2(float(flat[i + 2]), float(flat[i + 3]))
		var k := maxi(1, int(a.distance_to(b) / 3.0))
		for t in k:
			var q := a.lerp(b, float(t) / k)
			n += 1
			if map.shore_distance(q.x, q.y) > RIVER_FENCE_M:
				wet += 1
	return n > 0 and wet >= 6 and float(wet) / n >= RIVER_FENCE_SHARE


## Guard rails (bridge edges and mapped barrier=guard_rail): a steel beam on posts, solid for the
## car; the look is the palette's guard_rail type.
func build_guard_rails(st) -> void:
	var kit := Solidity.type_row(&"guard_rail")
	map._uv2 = Vector2(0.5, -1.0)
	var ends: Array = []  # [the end, its deck, which rail]
	var steel := Color(str(kit["colour"]))
	var post := Color(str(kit["post"]))
	var every := float(kit["posts"])
	for g in map.data.get("guards", []):
		var poly: PackedVector2Array = map._pts(g["p"])
		var dk := int(g.get("dk", -1))
		var guard := &"guard_deck" if dk >= 0 else &"guard_ground"
		var run := 0.0
		var next_post := 0.0
		for i in poly.size() - 1:
			var a := poly[i]
			var b := poly[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var side := Vector2(-dir.y, dir.x) * 0.06
			var ga: float = map.deck_height(dk, a.x, a.y)
			var gb: float = map.deck_height(dk, b.x, b.y)
			# The beam: two faces and a top, 0.55-0.85 m up.
			var n := Vector3(side.x, 0, side.y).normalized()
			for sgn in [1.0, -1.0]:
				var o: Vector2 = side * sgn
				map._quad(st, Vector3(a.x + o.x, ga + 0.55, a.y + o.y), Vector3(b.x + o.x, gb + 0.55, b.y + o.y),
						Vector3(b.x + o.x, gb + 0.85, b.y + o.y), Vector3(a.x + o.x, ga + 0.85, a.y + o.y), n * sgn, steel)
			map._quad(st, Vector3(a.x + side.x, ga + 0.85, a.y + side.y), Vector3(b.x + side.x, gb + 0.85, b.y + side.y),
					Vector3(b.x - side.x, gb + 0.85, b.y - side.y), Vector3(a.x - side.x, ga + 0.85, a.y - side.y), Vector3.UP, steel.lightened(0.15))
			while next_post <= run + length:
				var p := a + dir * (next_post - run)
				var y := lerpf(ga, gb, (next_post - run) / length)
				map._box_oriented(st, Vector3(p.x, y + 0.35, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)), Vector3(0.1, 0.7, 0.1), post)
				next_post += every
			run += length
			map._solid(guard, [Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + 1.6, b.y),
					Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + 1.6, b.y), Vector3(a.x, ga + 1.6, a.y)])
		if poly.size() > 1:
			ends.append([poly[0], dk, ends.size() / 2])
			ends.append([poly[poly.size() - 1], dk, ends.size() / 2])
	# PT-18: the gaps under GUARD_JOIN between two rails' ends on a deck (on Solec's ramp up to the
	# Trasa the rail comes in pieces 0.9 m apart, cut where a bus's box brushes it, the parapet 0.5 m
	# behind) get a shallow V behind the rail's line: a car's front corner that slid into the gap
	# caught the next piece's end and was pinned; now it glides out. Behind the line, so the lanes
	# the cut cleared stay clear.
	for i in ends.size():
		for j in range(i + 1, ends.size()):
			var e0: Array = ends[i]
			var e1: Array = ends[j]
			if e0[2] == e1[2] or e0[1] != e1[1] or int(e0[1]) < 0:
				continue
			var a: Vector2 = e0[0]
			var b: Vector2 = e1[0]
			var gap := a.distance_to(b)
			if gap < 0.05 or gap > GUARD_JOIN:
				continue
			var mid := (a + b) * 0.5
			var nrm := Vector2(-(b - a).y, (b - a).x) / gap
			if nrm.dot(mid - map._deck_centre(e0[1], mid)) < 0.0:
				nrm = -nrm
			var m := mid + nrm * minf(GUARD_POCKET, gap * 0.45)
			var ga: float = map.deck_height(e0[1], a.x, a.y)
			var gm: float = map.deck_height(e0[1], m.x, m.y)
			var gb: float = map.deck_height(e0[1], b.x, b.y)
			for seg in [[a, ga, m, gm], [m, gm, b, gb]]:
				var p0: Vector2 = seg[0]
				var p1: Vector2 = seg[2]
				var y0: float = seg[1]
				var y1: float = seg[3]
				map._solid(&"guard_deck", [Vector3(p0.x, y0 - 0.3, p0.y), Vector3(p1.x, y1 - 0.3, p1.y), Vector3(p1.x, y1 + 1.6, p1.y),
						Vector3(p0.x, y0 - 0.3, p0.y), Vector3(p1.x, y1 + 1.6, p1.y), Vector3(p0.x, y0 + 1.6, p0.y)])
			guard_joins += 1
	map._uv2 = Vector2.ZERO
