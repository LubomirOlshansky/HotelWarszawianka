extends RefCounted
## The wall builder (docs/design/city-objects-plan.md 3.2, step 2): the city's walls, fences,
## hedges, rails and guard rails, taken out of map_builder.gd as they were. It draws them into the
## map's building surface and files their collider faces through `map._solid(class, faces)`; the
## looks are the palette's barrier types (game/data/object_palette.json "types", read through
## solidity.gd: no look is kept in code). It decides no type or class beyond what the map's barrier
## code always did (the rules below, `barrier_class`).
## W2 of the walls look (docs/design/walls-true-to-life.md 6.1-6.3): under a look other than classic
## (solidity.gd `barrier_look`, the palette's key or `--barriers=`) a line whose chain ends generic
## is drawn from its type's `looks` row instead (`_typed`, `rail_lite_along`); classic, the default,
## runs none of that and draws as main does.
## W4 (walls doc 6.4): under `panels` the lines whose `looks` row is marked `panel` are not drawn in
## the city mesh: `panel_along` cuts them into 2 m panel pieces (the panel index of soft_things.gd,
## `PANEL`) and keeps them per 512 m tile (`panel_tiles`); map_builder.gd
## `_build_panels` makes one `Panels` MultiMesh of them per sector (panel.gdshader). Their colliders
## are the typed ones, filed the same way.
## W5 (walls doc 10): every light row but the tram's railing is a panel row; the stadium's own
## railing (#808, `stadium_fence_line`) is panels too under `panels`, and only there; a row whose
## posts are `in_mesh` (bars_pier's piers until W7) keeps its posts in the city mesh.
## W7 (walls doc 6.5, the heavy kit): under typed and panels a heavy or low slab row is drawn by
## `wall_kit` (foot, bays, cap, piers, proud posts, end pieces, a parapet's rail, a stone wall's top
## rail) and a row with piers (bars_pier) gets its plinth and piers from `_pier_fence_kit`, with a
## diamond collider per pier on a soft line; every other collider is the one W2 to W6 filed.
##
## A RefCounted the map makes once (map_builder.gd `barriers`), with the map as its reference, the
## way landmarks.gd is called: the map swaps `data` for every sector it builds, and the caches here
## (the flights, the islands, the street pass's overrides) follow that swap as they did inside the
## map. The map's own structures (the cutting's fence, a deck's railing, a tram island's railing)
## draw their rails with `railing_along`.

const Solidity := preload("res://scripts/solidity.gd")
const PanelRule := preload("res://scripts/panel_rule.gd")

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
	# The University's escarpment wall over Powiśle: the site `uw_skarpa` builds it in brick (2026-11-15).
	[Vector2(-210.5, -650.9), ""],
	[Vector2(-1639.7, -1217.3), ""],
	[Vector2(-1667.0, -1217.7), "balustrade_white"],
	[Vector2(-1657.7, -1219.1), "balustrade_white"],
	[Vector2(-1644.7, -1190.0), "balustrade_white"],
	[Vector2(-1656.4, -1197.6), "balustrade_white"],
	[Vector2(-1624.6, -1230.3), "balustrade_rail"],
	[Vector2(-1621.2, -1219.2), "balustrade_rail"],
	[Vector2(-1625.5, -1232.3), "balustrade_rail"],
	[Vector2(-1628.1, -1232.1), "balustrade_rail"],
	# The two plain fences round the lawn bit south of Metro Centrum's big glass pavilion (F asked in his thread, 2026-11-19, to remove the two buildings and the wall by it).
	[Vector2(-964.8, 238.7), ""],
	[Vector2(-957.9, 234.2), ""],
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

## The pocket inside Most Poniatowskiego's west ramp loop (Autopilot hunt 20261114-003742, 65 s at
## 6-8 km/h among the ramps; docs/PLAYTEST.md PT-54): the grass embankment between the ramps rises
## 3-8 m from the quay road to the decks' side skirts, 3.5-4.4 m sheer walls with nothing in front
## of them, so a car that cut the corner climbed in, hit a skirt, was turned out and hit the next
## one. The lanes themselves drive clean (check_lane_drive). A hedge along the embankment's foot,
## a metre up the slope, keeps the car on the road; it stays 6 m or more off every lane of the loop.
## Lines of points, drawn as `hedge` (the palette's type, solid class hedge).
const POCKET_HEDGES := [
	[Vector2(856.5, -89.0), Vector2(860.0, -86.0), Vector2(864.0, -82.5), Vector2(868.0, -78.5), Vector2(871.0, -75.5),
			Vector2(875.0, -73.0), Vector2(880.0, -73.0), Vector2(886.0, -72.0), Vector2(892.0, -71.5), Vector2(897.5, -70.0)],
]

## Stadion Narodowy's perimeter (F, 2026-11-15, a street-level photo by Brama 5; docs/landmarks/specs/
## stadium-grounds.md): OSM maps the park's boundary as plain mesh-panel, chain-link and plain fences
## 200-345 m from the stadium's centre; the real one is a tall black vertical-bar steel fence, so those
## lines are drawn in the palette's stadium_fence type. The ball-stop nets, the railway's fence
## (`hz`) and anything with a mapped height keep their own look. praga.gd puts the numbered gates
## where footpaths and roads cross it (`stadium_fence_line` is the one rule both use). W3 of the walls
## look: the bake gives those 19 lines the type stadium_fence by id (tools/object_types.py fix_types,
## game/data/road_objects.json `types`), so the rule looks for that type too.
const STADIUM_CENTRE := Vector2(1480.5, -605.1)
const STADIUM_FENCE_R := Vector2(195.0, 345.0)
const STADIUM_FENCE_TYPES := ["mesh_panel", "chain_link", "fence_plain", "stadium_fence"]
## The gates: where a footpath or a road under 7 m wide meets that fence, one per 15 m of fence:
## two dark stone piers, two black leaves with a solid dark panel on each, and a red board on two
## poles with a pale stripe for the writing ("Do zobaczenia! See you! Brama N Gate") and a white
## number plate (at 10-17 cm a pixel the writing is stripes).
const GATE_HALF := 3.2
const GATE_MIN_APART := 15.0
const GATE_STONE := Color("#3a3c40")
const GATE_LEAF := Color("#16181b")
const GATE_PANEL := Color("#25282c")
const GATE_RED := Color("#b8232a")
const GATE_PALE := Color("#ece8dc")

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

## Step 7 (docs/design/drivable-city-build.md item 3): `--no-soft` (main.gd and the checks set it
## before a build): every fence and hedge collides as it did before step 7 (the same faces, in the
## same order), and no soft list is made.
static var soft_off := false
## Step 7: the styles that stay hard on a fence whatever its class: a tram bed's railing and a
## stair's balustrades guard a track's edge or a stair's hole (the build plan, item 3).
const HARD_RAILS: Array[StringName] = [&"tram_railing", &"balustrade", &"balustrade_rail", &"balustrade_white"]
## Step 7: a smash line's 2 m panels (the look thread's instanced panels use the same length).
const PANEL := 2.0
## Step 7: fence types (object_types.py `ty`) whose panels sound and break as wood, for a line whose
## type has no `debris` in its looks row (W6: the row's `debris` decides, Solidity.debris_of).
const WOOD_TYPES := ["wood", "hoarding"]
## Step 7: an S line inside or within this of a landmark site's ring (landmarks.gd `sites` "zone":
## the outlines its model replaces; the sites with a card, as check_landmarks drives its car rays
## at) stays hard (m): many sites are closed to the car at
## bumper height only by their railing or garden fence (the Tomb of the Unknown Soldier from the
## Saxon Garden: its arcade is open), and a monument's fence is not a thing to smash.
const LANDMARK_GUARD := 10.0

var map  # map_builder.gd: terrain, decks, the building surface's helpers, `_solid`
## Step 7: the soft lines of the last build_barriers (one sector, or the whole map): per line its
## stable id (barrier_id), kind, debris for the sound and the burst (W6: its looks row's `debris`,
## "metal", "wood", "sheet" or "leaf"; Solidity.debris_of) and panel count; per segment SOFT_STRIDE numbers (soft_data).
var soft_ids := PackedStringArray()
var soft_kinds := PackedStringArray()
var soft_mats := PackedStringArray()
var soft_panels := PackedInt32Array()
var soft_segs := PackedFloat64Array()
## The line being drawn soft ({"i": its index in soft_ids}; empty: the line collides as always),
## and the metres drawn along it so far (a segment's start, for its panels).
var _soft_line := {}
var _soft_run := 0.0
var guard_joins := 0
## W2: what the last build_barriers did with each line under a typed look, {what: lines}: `rail`,
## `slab` (drawn from the line's `looks` row), `none` (left out by its row), `keep` (its row keeps
## the classic chain), `classic` (a rule, a site, `st` or a street pass gave it its look; or a
## platform), `unknown` (no `ty`, or a type with no row: drawn classic, check_barrier_look's gate);
## low_typed, the stable ids of typed lines drawn under BARRIER_SOLID_MIN (they stop colliding);
## default_lines, the lines drawn in the barrier_default type (none on today's map).
var look_counts := {}
## W5: under panels, the light-family lines (by `ty`) still drawn in the city mesh, {ty: lines}
## (check_barrier_look 7 names them: the kept rows and the chains a rule or a site gave a look).
var mesh_light := {}
var low_typed := PackedStringArray()
var default_lines := 0
## W4: the panel pieces of the last build_barriers under `panels`, per 512 m tile (Vector2i, the
## sector's key: a PanelTile): `buf` the MultiMesh buffer (PANEL_FLOATS a piece: the transform's
## 12 floats, then the custom data: the line's row in the rows texture, the metres along the line
## at the piece's start, the state (0 whole; W6 writes the others), the line's colour seed);
## `ids`, `first`, `count`: each soft line's stable id, its first instance and its pieces in this
## tile; `panel` every instance's panel index; `box` their AABB. `panel_pieces` all of them.
## Empty under classic and typed.
var panel_tiles := {}
var panel_pieces := 0
## W7: the pier diamonds the last build_barriers filed (`_pier_diamond`; check_barrier_look counts them).
var kit_diamonds := 0
## W8: the last build_barriers' gated lines, gaps, gate posts and open leaves (check_barrier_look prints them).
var gate_counts := {}
## W4: the metres drawn along the line so far (a panel piece's start; the same count as
## `_soft_run`, which soft_things.gd's panels are cut by), and a serial per line (two lines with
## one stable id stay two entries in a tile).
var _panel_run := 0.0
var _panel_serial := 0
var _object_overrides := {}
## Step 7: road_objects.json "hard_lines" ({stable id: reason}): soft lines kept hard by id, the
## `--wander` run's traps (rule R6: a trap is hard or a hole to close).
var _hard_lines := {}
## Step 7: the landmark sites' rings (made once, from the map's landmarks.gd sites with a card),
## and each ring's box grown by LANDMARK_GUARD.
var _guard_rings: Array[PackedVector2Array] = []
var _guard_boxes: Array[Rect2] = []
var _guards_made := false
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
			_slab_solid(cls, a, b, hw, ga, gb, height)
			_soft_run += d.length()


## A slab's collider from a to b (`slab_faces`), filed under `cls`, or the soft line's segment.
func _slab_solid(cls: StringName, a: Vector2, b: Vector2, hw: float, ga: float, gb: float, height: float) -> void:
	var faces := slab_faces(a, b, hw, ga, gb, height)
	if _soft_line.is_empty():
		map._solid(cls, faces, {"same": true, "h": height})
	else:
		_soft_seg(cls, faces, a, b, hw, ga, gb, height)


## The two long faces of a slab's collider from a to b (half width `hw`, its foot `ga`, `gb` on
## the ground): from 0.3 m under the ground to `height` + 1.5 m, as the barriers have always
## collided. Step 7: one function, so a soft line's faces made again from its segment
## (soft_things.gd `hard_faces`, `--no-soft` on the prebuilt city) are these very faces.
static func slab_faces(a: Vector2, b: Vector2, hw: float, ga: float, gb: float, height: float) -> PackedVector3Array:
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x) * hw
	var corners := [a + side, b + side, b - side, a - side]
	var g := [ga, gb, gb, ga]
	var bottom: Array[Vector3] = []
	for k in 4:
		var c: Vector2 = corners[k]
		bottom.append(Vector3(c.x, float(g[k]) - 0.3, c.y))
	var up := Vector3(0, height + 1.5, 0)
	var out := PackedVector3Array()
	for k in [0, 2]:
		var p0: Vector3 = bottom[k]
		var p1: Vector3 = bottom[(k + 1) % 4]
		out.append_array([p0, p1, p1 + up, p0, p1 + up, p0 + up])
	return out


## A railing's collider from a to b: one upright face, from 0.3 m under its foot to `height` + 1.5 m.
static func rail_faces(a: Vector2, b: Vector2, ga: float, gb: float, height: float) -> PackedVector3Array:
	return PackedVector3Array([Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + height + 1.5, b.y),
			Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + height + 1.5, b.y), Vector3(a.x, ga + height + 1.5, a.y)])


## Step 7: one segment of soft line `_soft_line` (a slab: half width `hw`; a railing: `hw` 0) where
## its collider faces would have been. Kept when its middle or one of those faces' centres lies in
## the sector (the faces are cut by centre, `_build_collision`); `own` (its middle in the sector)
## says which sector's soft_things entry it is, so a segment counts once. The faces go only into
## the R2 check's notes (`none: soft`: drawn on purpose with no collider).
func _soft_seg(cls: StringName, faces: PackedVector3Array, a: Vector2, b: Vector2, hw: float, ga: float, gb: float,
		height: float) -> void:
	var own := true
	if map._in_sector:
		var rect: Rect2 = map._sector_rect
		own = rect.has_point((a + b) * 0.5)
		var keep := own
		for i in range(0, faces.size() - 2, 3):
			var c := (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
			keep = keep or rect.has_point(Vector2(c.x, c.z))
		if not keep:
			return
	soft_segs.append_array([float(_soft_line["i"]), a.x, a.y, b.x, b.y, ga, gb, hw, height, _soft_run, 1.0 if own else 0.0])
	if map.note_solids:
		map._note_solid(cls, faces, {"none": "soft", "same": true, "h": height})


## Step 7: the numbers per segment in `soft_segs`: line index, a.x, a.z, b.x, b.z, the ground at a
## and at b, half width (0: a railing's single face), drawn height, metres along the line at a, own.
const SOFT_STRIDE := 11


## Step 7: the soft list of the last build_barriers, for the sector's root (its "soft" meta, saved
## with the prebuilt scene) or the whole city's map node: {} when it has none.
func soft_data() -> Dictionary:
	if soft_segs.is_empty():
		return {}
	return {"ids": soft_ids, "kinds": soft_kinds, "mats": soft_mats, "panels": soft_panels, "segs": soft_segs}


## Step 7: whether barrier line `l`, drawn in `style` and solid, breaks instead of stopping the car:
## a fence or hedge the bake classed S (tools/object_types.py `sc`; the game decides no class), not a
## stair's balustrade (`cls` stair_wall), not drawn as a tram railing or a balustrade, not kept
## hard by id (game/data/road_objects.json: a street's HARD verdict, or "hard_lines": the
## `--wander` run's traps), and not within LANDMARK_GUARD m of a landmark site.
func _is_soft(l: Dictionary, style: Array, cls: StringName, solid: bool) -> bool:
	if soft_off or not solid or str(l.get("sc", "")) != "S" or (cls != &"fence" and cls != &"hedge"):
		return false
	for id: StringName in HARD_RAILS:
		if style == _s(id):
			return false
	var bid := barrier_id(l["k"], l["p"])
	if _hard_lines.has(bid):
		return false
	if not _object_overrides.is_empty():
		var o: Variant = _object_overrides.get(bid)
		if o is Array and str(o[0]) == "HARD":
			return false
	return not near_landmark(l["p"])


## Step 7: whether a line (flat x, z points) runs inside or within LANDMARK_GUARD m of a landmark
## site's ring.
func near_landmark(flat: Array) -> bool:
	if not _guards_made:
		_guards_made = true
		var marks: Variant = map.get("_marks")
		var carded := {}
		for info: Dictionary in map.landmark_info:
			if str(info.get("pl", "")) != "":
				carded[info["key"]] = true
		if marks != null:
			for s: Dictionary in marks.sites:
				if not carded.has(s.get("key", "")):
					continue
				for ring: PackedVector2Array in s.get("zone", []):
					if ring.size() < 3:
						continue
					var lo := Vector2(INF, INF)
					var hi := Vector2(-INF, -INF)
					for v in ring:
						lo = lo.min(v)
						hi = hi.max(v)
					_guard_rings.append(ring)
					_guard_boxes.append(Rect2(lo, hi - lo).grow(LANDMARK_GUARD))
	if _guard_boxes.is_empty() or flat.size() < 4:
		return false
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in range(0, flat.size() - 1, 2):
		lo = lo.min(Vector2(flat[i], flat[i + 1]))
		hi = hi.max(Vector2(flat[i], flat[i + 1]))
	var line_box := Rect2(lo, hi - lo)
	for k in _guard_boxes.size():
		if not _guard_boxes[k].intersects(line_box, true):
			continue
		var ring := _guard_rings[k]
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var b := Vector2(flat[i + 2], flat[i + 3])
			if Geometry2D.is_point_in_polygon(a, ring):
				return true
			for j in ring.size():
				var pq := Geometry2D.get_closest_points_between_segments(a, b, ring[j], ring[(j + 1) % ring.size()])
				if pq[0].distance_to(pq[1]) <= LANDMARK_GUARD:
					return true
	return false


## Step 7: starts soft line `l` (its id, kind, material and panels into the soft list).
func _begin_soft(l: Dictionary, pts: PackedVector2Array) -> void:
	var length := 0.0
	for i in pts.size() - 1:
		length += pts[i].distance_to(pts[i + 1])
	var k := str(l["k"])
	var ty := str(l.get("ty", ""))
	_soft_line = {"i": soft_ids.size()}
	_soft_run = 0.0
	soft_ids.append(barrier_id(k, l["p"]))
	soft_kinds.append(k)
	var debris := Solidity.debris_of(StringName(ty))
	if debris == "":
		debris = "leaf" if k == "hedge" else ("wood" if ty in WOOD_TYPES or str(l.get("ft", "")) == "wood" else "metal")
	soft_mats.append(debris)
	soft_panels.append(maxi(1, ceili(length / PANEL)))


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
			var faces := rail_faces(a, b, ga, gb, height)
			if _soft_line.is_empty():
				map._solid(cls, faces, {"same": true, "h": height})
			else:
				_soft_seg(cls, faces, a, b, 0.0, ga, gb, height)
		_soft_run += length


## W2 (walls doc 6.3): a rail's height, a typed rail row's foot's thickness, and how far the second
## rail's bottom stands over the foot's top (m): the draw kind's own shape, the same for every row.
const LITE_RAIL := 0.06
const LITE_FOOT := 0.2
const LITE_LOW_RAIL := 0.35


## W2 (walls doc 6.3): a typed rail row along `poly`, the cheap see-through fence (about 2.5
## triangles a metre against railing_along's 7.5): a post every `row.post.every` m along the whole
## line (the run carries over the segments) and one at its last point, each two crossed upright
## quads `post.w` wide from the foot's top to `height`; `row.rails` upright quads LITE_RAIL tall,
## one with its top at `height`, a second LITE_LOW_RAIL over the foot's top; the row's foot, a
## slab LITE_FOOT thick that does not collide. One quad shows from both sides (the building shader
## is cull_disabled), in vertex colour with the line's side normal, the prop code the caller set in
## `map._uv2`. The colliders are railing_along's: one `rail_faces` per segment at `height`, or the
## soft line's segment (`hw` 0), with `_soft_run` advanced the same way, so a typed city has the
## same soft lines, ids, panels and segments as the classic one.
## W7: with `kit` (a row with piers, `_pier_fence_kit` drew them and the plinth) no posts and no foot.
func rail_lite_along(st, poly: PackedVector2Array, row: Dictionary, height: float, colour: Color, collide: bool,
		cls: StringName, kit := false) -> void:
	var post: Dictionary = row.get("post", {})
	var every := float(post.get("every", 0.0))
	var pw := float(post.get("w", 0.0)) * 0.5
	var post_col := Color(str(post["colour"])) if post.has("colour") else colour
	var rails := int(row.get("rails", 0))
	var foot: Dictionary = row.get("foot", {})
	var foot_h := float(foot.get("h", 0.0))
	# W7: `kit`, the heavy kit stands the posts (piers) and the foot (a plinth): the rails alone.
	if kit:
		every = 0.0
	if foot_h > 0.0 and not kit:
		var foot_col := Color(str(foot["colour"])) if foot.has("colour") else colour.darkened(float(foot.get("darken", 0.0)))
		wall_along(st, poly, LITE_FOOT, foot_h, foot_col, false, cls)
	var run := 0.0
	var next_post := 0.0
	var last_post := Vector2(INF, INF)
	var last_dir := Vector2.ZERO
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var dir := (b - a) / length
		last_dir = dir
		var side := Vector2(-dir.y, dir.x)
		var n := Vector3(side.x, 0.0, side.y)
		var ga: float = map.terrain_height(a.x, a.y)
		var gb: float = map.terrain_height(b.x, b.y)
		var bands: Array[float] = []
		if rails >= 1:
			bands.append(height - LITE_RAIL)
		if rails >= 2:
			bands.append(foot_h + LITE_LOW_RAIL)
		for y0 in bands:
			map._quad(st, Vector3(a.x, ga + y0, a.y), Vector3(b.x, gb + y0, b.y), Vector3(b.x, gb + y0 + LITE_RAIL, b.y),
					Vector3(a.x, ga + y0 + LITE_RAIL, a.y), n, colour)
		if every > 0.0 and pw > 0.0:
			while next_post <= run + length:
				var p := a + dir * (next_post - run)
				_lite_post(st, p, lerpf(ga, gb, (next_post - run) / length), dir, pw, foot_h, height, n, post_col)
				last_post = p
				next_post += every
		run += length
		if collide:
			var faces := rail_faces(a, b, ga, gb, height)
			if _soft_line.is_empty():
				map._solid(cls, faces, {"same": true, "h": height})
			else:
				_soft_seg(cls, faces, a, b, 0.0, ga, gb, height)
		_soft_run += length
	# The post at the line's last point (unless the rhythm put one there already).
	if last_dir != Vector2.ZERO and every > 0.0 and pw > 0.0:
		var end := poly[poly.size() - 1]
		if last_post.distance_to(end) > 0.05:
			_lite_post(st, end, map.terrain_height(end.x, end.y), last_dir, pw, foot_h, height,
					Vector3(-last_dir.y, 0.0, last_dir.x), post_col)


## W2: one rail_lite post at `p` (the ground there `y`): two crossed upright quads, along and across
## the line (`dir`), `pw` half wide, from `foot_h` to `height` over the ground, normal `n`.
func _lite_post(st, p: Vector2, y: float, dir: Vector2, pw: float, foot_h: float, height: float, n: Vector3, col: Color) -> void:
	for d: Vector2 in [dir * pw, Vector2(-dir.y, dir.x) * pw]:
		map._quad(st, Vector3(p.x - d.x, y + foot_h, p.y - d.y), Vector3(p.x + d.x, y + foot_h, p.y + d.y),
				Vector3(p.x + d.x, y + height, p.y + d.y), Vector3(p.x - d.x, y + height, p.y - d.y), n, col)


## W7 (walls doc 6.5): the heavy kit's own shape, the same for every row (the rows hold the rest):
## how far it reaches into the ground (wall_along's slabs: 0.3 m), how far a pier and a proud post
## rise over the wall's top, a proud post's stand-off where the row gives none, how much darker a
## post is than its wall where the row gives it no colour (so the rhythm reads), how much lighter
## a pier's top is where the row has no cap, a plinth's thickness where the row gives none, and the
## sharpest corner that is mitred (the cosine of half the turn: past 120 degrees the sides just meet).
const KIT_SINK := 0.3
const KIT_PIER_RISE := 0.15
const KIT_POST_RISE := 0.08
const KIT_PROUD := 0.03
const KIT_POST_SHADE := 0.1
const KIT_TOP_LIGHT := 0.1
const KIT_PLINTH := 0.3
const KIT_MITRE_MIN := 0.5
## W7: a parapet's or a top rail's posts (m wide), as rail_lite's thin posts.
const KIT_RAIL_POST := 0.05
## W7: a pier's collider on a soft line: a square this wide (m) turned 45 degrees to the line, so a
## car that clips a pier is turned into the bay instead of stopped (walls doc 6.5, F's answer 1).
const KIT_DIAMOND := 0.5
## No top face (`_kit_box`).
const NO_TOP := Color(0, 0, 0, 0)


## W7: whether a typed `slab` row is drawn by the heavy kit: a heavy or low row with a foot, a cap,
## bays or piers (walls doc 6.2's heavy columns). The light slabs (hedges, boards, hoardings) are not.
static func kit_row(row: Dictionary) -> bool:
	return str(row.get("family", "")) != "light" and (row.has("foot") or row.has("cap") or row.has("bay") or row.has("pier"))


## W7 (walls doc 6.5): a heavy row's line `poly` (its `look` from `_typed`) as shaped geometry in the
## city mesh, vertex colour on the building shader's prop path (`map._uv2`, as every barrier): the
## foot band, the body cut into bays a shade step apart, the cap with its overhang (with none, a
## band: a noise screen's pale top), the piers or proud posts at the bays' joints with one at each
## end of the run (the end piece; a run with neither gets end faces), a parapet's rail on posts
## over its upstand, a stone wall's top rail where the bake's hazard reason is in the row's
## `top_rail.hz`. The colliders are wall_along's at the row's thickness and the line's height,
## face for face, with `_soft_run` advanced as wall_along advances it (`_slab_colliders`).
func wall_kit(st, poly: PackedVector2Array, look: Dictionary, collide: bool, cls: StringName) -> void:
	var row: Dictionary = look["row"]
	var height := float(look["h"])
	var k := _kit_spec(row, height, look["colour"], int(look.get("alt", -1)))
	var top_rail: Dictionary = row.get("top_rail", {})
	if not top_rail.is_empty() and str(look.get("hz", "")) in (top_rail.get("hz", []) as Array):
		k["top_rail"] = top_rail
	_kit_draw(st, poly, k)
	_slab_colliders(poly, float(row["thick"]) * 0.5, height, collide, cls)


## W7: wall_along's colliders alone along `poly`: the same faces in the same order.
func _slab_colliders(poly: PackedVector2Array, hw: float, height: float, collide: bool, cls: StringName) -> void:
	if not collide:
		return
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.05:
			continue
		_slab_solid(cls, a, b, hw, map.terrain_height(a.x, a.y), map.terrain_height(b.x, b.y), height)
		_soft_run += d.length()


## W7: a pier-and-iron fence's stone part along `poly` (a light row with a `pier`: bars_pier): the
## plinth (the row's foot, KIT_PLINTH thick unless the foot says) and a pier every `pier.every` m
## and at the run's end, rising KIT_PIER_RISE over the fence's `height`. What stands between the
## piers is the row's rails (typed) or its panels. On a soft line each pier files a diamond
## collider (KIT_DIAMOND, class wall): the panel falls, the piers stand.
func _pier_fence_kit(st, poly: PackedVector2Array, row: Dictionary, height: float) -> void:
	var foot: Dictionary = row.get("foot", {})
	var pier: Dictionary = row["pier"]
	var fc := Color(str(foot["colour"])) if foot.has("colour") else Color(str(row["colour"]))
	var k := _kit_spec({"thick": float(foot.get("thick", KIT_PLINTH))}, minf(float(foot.get("h", 0.0)), height), fc, -1)
	k["pier_every"] = float(pier["every"])
	k["pier_w"] = float(pier["w"])
	k["pier_col"] = Color(str(pier["colour"])) if pier.has("colour") else fc
	k["pier_top"] = height + KIT_PIER_RISE
	k["pier_top_col"] = (k["pier_col"] as Color).lightened(KIT_TOP_LIGHT)
	k["diamonds"] = not _soft_line.is_empty()
	_kit_draw(st, poly, k)


## W7: the kit's numbers for a row at `height` in `colour` (`alt`: the alt colour the line took, -1
## its own; a cap's own `alt` goes with it): see `_kit_draw`.
func _kit_spec(row: Dictionary, height: float, colour: Color, alt: int) -> Dictionary:
	var k := {"hw": float(row["thick"]) * 0.5, "h": height, "col": colour, "foot_h": 0.0, "foot_col": colour,
			"cap": "", "cap_h": 0.0, "cap_over": 0.0, "cap_col": colour, "upstand": 0.0, "rail_col": colour,
			"rail_every": 0.0, "bay_len": 0.0, "bay_step": 0.0, "pier_every": 0.0, "pier_w": 0.0, "pier_col": colour,
			"pier_top": height + KIT_PIER_RISE, "pier_top_col": colour.lightened(KIT_TOP_LIGHT), "post_w": 0.0,
			"post_proud": KIT_PROUD, "post_col": colour.darkened(KIT_POST_SHADE), "diamonds": false, "top_rail": {}}
	var cap: Dictionary = row.get("cap", {})
	if cap.has("upstand"):
		k["cap"] = "upstand"
		k["upstand"] = minf(float(cap["upstand"]), height)
		k["rail_col"] = Color(str(cap.get("rail_colour", row.get("colour"))))
		k["rail_every"] = float(cap.get("rail_post_every", 2.0))
	elif cap.has("h"):
		k["cap_h"] = minf(float(cap["h"]), height * 0.5)
		k["cap_over"] = float(cap.get("over", 0.0))
		k["cap"] = "over" if float(k["cap_over"]) > 0.0 else "band"
		var cc := colour.lightened(float(cap.get("lighten", 0.0)))
		if cap.has("colour"):
			cc = Color(str(cap["alt"] if alt >= 0 and cap.has("alt") else cap["colour"]))
		k["cap_col"] = cc
		k["pier_top_col"] = cc
	var body_hi: float = k["upstand"] if k["cap"] == "upstand" else height - float(k["cap_h"])
	var foot: Dictionary = row.get("foot", {})
	if float(foot.get("h", 0.0)) > 0.0:
		k["foot_h"] = minf(float(foot["h"]), body_hi * 0.5)
		k["foot_col"] = Color(str(foot["colour"])) if foot.has("colour") else colour.darkened(float(foot.get("darken", 0.0)))
	var bay: Dictionary = row.get("bay", {})
	k["bay_len"] = float(bay.get("len", 0.0))
	k["bay_step"] = float(bay.get("step", 0.0))
	if float(bay.get("post_w", 0.0)) > 0.0 and float(k["bay_len"]) > 0.0:
		k["post_w"] = float(bay["post_w"])
		k["post_proud"] = float(bay.get("proud", KIT_PROUD))
		if bay.has("post_colour"):
			k["post_col"] = Color(str(bay["post_colour"]))
	var pier: Dictionary = row.get("pier", {})
	if float(pier.get("every", 0.0)) > 0.0 and float(pier.get("w", 0.0)) > 0.0:
		k["pier_every"] = float(pier["every"])
		k["pier_w"] = float(pier["w"])
		if pier.has("colour"):
			k["pier_col"] = Color(str(pier["colour"]))
	return k


## W7: the kit along `poly` by spec `k` (`_kit_spec`), into the city mesh `st`. The long faces are
## mitred at the line's corners (no end faces inside a run, no notch at an outer corner); the
## rhythm (bays, piers, posts) runs on along the whole run as rail_lite's posts do. All the
## vertical faces are shaded as wall_along shades its sides (darkened 0.08), the tops not.
func _kit_draw(st, poly: PackedVector2Array, k: Dictionary) -> void:
	var pts := PackedVector2Array()
	for p in poly:
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) >= 0.05:
			pts.append(p)
	var n := pts.size()
	if n < 2:
		return
	# A closed ring (its last point on its first): ends on its first point exactly, its last
	# segment no shorter than any other.
	var closed := n > 3 and pts[0].distance_to(pts[n - 1]) < 0.1
	if closed:
		pts.remove_at(n - 1)
		while pts.size() > 2 and pts[pts.size() - 1].distance_to(pts[0]) < 0.05:
			pts.remove_at(pts.size() - 1)
		pts.append(pts[0])
		n = pts.size()
		closed = n > 3
	var g := PackedFloat32Array()
	for p in pts:
		g.append(map.terrain_height(p.x, p.y))
	# Each segment's normal, and the offsets (per metre of half width) at its two ends: the mitre
	# shared with the next segment, or its own normal at an open end or a corner too sharp.
	var dirs := PackedVector2Array()
	var norms := PackedVector2Array()
	for i in n - 1:
		var d := (pts[i + 1] - pts[i]).normalized()
		dirs.append(d)
		norms.append(Vector2(-d.y, d.x))
	var oa := PackedVector2Array()
	var ob := PackedVector2Array()
	for i in n - 1:
		var s := norms[i]
		var e := norms[i]
		if i > 0 or closed:
			s = _mitre(norms[posmod(i - 1, n - 1)], norms[i], s)
		if i < n - 2 or closed:
			e = _mitre(norms[i], norms[(i + 1) % (n - 1)], e)
		oa.append(s)
		ob.append(e)
	var hw: float = k["hw"]
	var h: float = k["h"]
	var col: Color = k["col"]
	var foot_h: float = k["foot_h"]
	var cap: String = k["cap"]
	var cap_h: float = k["cap_h"]
	var body_lo := foot_h if foot_h > 0.0 else -KIT_SINK
	var body_hi: float = k["upstand"] if cap == "upstand" else h - cap_h
	var body_top := col if cap == "" or cap == "upstand" else NO_TOP
	var bay_len: float = k["bay_len"]
	var step: float = k["bay_step"]
	var cut := bay_len > 0.0 and step > 0.0
	var tr: Dictionary = k["top_rail"]
	var run := 0.0
	for i in n - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var length := a.distance_to(b)
		if h > 0.0:
			if foot_h > 0.0:
				_kit_box(st, a, b, g[i], g[i + 1], oa[i], ob[i], 0.0, 1.0, hw, -KIT_SINK, foot_h, k["foot_col"], NO_TOP)
			# The body, bay by bay: every other bay `step` darker.
			var bay := floori(run / bay_len) if cut else 0
			while true:
				var s0 := maxf(run, bay * bay_len) if cut else run
				var s1 := minf(run + length, (bay + 1) * bay_len) if cut else run + length
				if s1 - s0 > 0.01:
					var bc := col.darkened(step) if cut and bay % 2 == 1 else col
					_kit_box(st, a, b, g[i], g[i + 1], oa[i], ob[i], (s0 - run) / length, (s1 - run) / length, hw, body_lo,
							body_hi, bc, bc if body_top.a > 0.0 else NO_TOP)
				if not cut or (bay + 1) * bay_len >= run + length:
					break
				bay += 1
			if cap == "over":
				_kit_box(st, a, b, g[i], g[i + 1], oa[i], ob[i], 0.0, 1.0, hw + float(k["cap_over"]), h - cap_h, h, k["cap_col"], k["cap_col"])
			elif cap == "band":
				_kit_box(st, a, b, g[i], g[i + 1], oa[i], ob[i], 0.0, 1.0, hw, h - cap_h, h, k["cap_col"], k["cap_col"])
		var nrm := Vector3(norms[i].x, 0.0, norms[i].y)
		if cap == "upstand":
			_kit_rail(st, a, b, g[i], g[i + 1], h, nrm, k["rail_col"])
		if not tr.is_empty():
			_kit_rail(st, a, b, g[i], g[i + 1], h + float(tr["h"]), nrm, Color(str(tr["colour"])))
		run += length
	var piers: float = k["pier_every"]
	var posts: float = bay_len if float(k["post_w"]) > 0.0 else 0.0
	# The run's two ends: a pier or a post stands there (the end piece), else end faces close it.
	if not closed and h > 0.0 and piers <= 0.0 and posts <= 0.0:
		for e: Array in [[pts[0], g[0], oa[0], -dirs[0]], [pts[n - 1], g[n - 1], ob[n - 2], dirs[n - 2]]]:
			var p: Vector2 = e[0]
			var ge: float = e[1]
			var o: Vector2 = e[2]
			var out: Vector2 = e[3]
			if foot_h > 0.0:
				_kit_end(st, p, ge, o, hw, -KIT_SINK, foot_h, out, k["foot_col"])
			_kit_end(st, p, ge, o, hw, body_lo, body_hi, out, col)
			if cap == "over":
				_kit_end(st, p, ge, o, hw + float(k["cap_over"]), h - cap_h, h, out, k["cap_col"])
			elif cap == "band":
				_kit_end(st, p, ge, o, hw, h - cap_h, h, out, k["cap_col"])
	if piers > 0.0:
		var across := maxf(float(k["pier_w"]), hw * 2.0 + KIT_PROUD * 2.0)
		for m: Array in _kit_marks(pts, g, dirs, piers, closed):
			_kit_block(st, m[0], m[1], m[2], k["pier_w"], across, -KIT_SINK, k["pier_top"], k["pier_col"], k["pier_top_col"])
			if k["diamonds"]:
				_pier_diamond(m[0], m[1], m[2], float(k["pier_top"]))
	if posts > 0.0:
		var across := hw * 2.0 + float(k["post_proud"]) * 2.0
		for m: Array in _kit_marks(pts, g, dirs, posts, closed):
			_kit_block(st, m[0], m[1], m[2], k["post_w"], across, -KIT_SINK, h + KIT_POST_RISE, k["post_col"], k["post_col"])
	if cap == "upstand":
		for m: Array in _kit_marks(pts, g, dirs, float(k["rail_every"]), closed):
			var d: Vector2 = m[2]
			_lite_post(st, m[0], m[1], d, KIT_RAIL_POST * 0.5, k["upstand"], h, Vector3(-d.y, 0.0, d.x), k["rail_col"])
	if not tr.is_empty():
		for m: Array in _kit_marks(pts, g, dirs, float(tr.get("every", 2.0)), closed):
			var d: Vector2 = m[2]
			_lite_post(st, m[0], m[1], d, KIT_RAIL_POST * 0.5, h, h + float(tr["h"]), Vector3(-d.y, 0.0, d.x), Color(str(tr["colour"])))


## W7: the offset (per metre of half width) at a corner between two segments with unit normals `n0`
## and `n1`: the mitre, or `own` where the corner is sharper than KIT_MITRE_MIN allows.
static func _mitre(n0: Vector2, n1: Vector2, own: Vector2) -> Vector2:
	var m := n0 + n1
	if m.length_squared() < 1e-8:
		return own
	m = m.normalized()
	var c := m.dot(n0)
	return own if c < KIT_MITRE_MIN else m / c


## W7: the places along a run (points `pts`, ground `g`, segment directions `dirs`) of a rhythm every
## `every` m from its start, and its last point unless one stands within 0.05 m of it (a closed
## ring: not again at its start): [point, ground, direction] each.
func _kit_marks(pts: PackedVector2Array, g: PackedFloat32Array, dirs: PackedVector2Array, every: float, closed: bool) -> Array:
	var out: Array = []
	if every <= 0.0:
		return out
	var run := 0.0
	var next := 0.0
	var last := Vector2(INF, INF)
	for i in pts.size() - 1:
		var length := pts[i].distance_to(pts[i + 1])
		while next <= run + length + 1e-4:
			var t := clampf((next - run) / length, 0.0, 1.0)
			var p := pts[i].lerp(pts[i + 1], t)
			if not (closed and i == pts.size() - 2 and p.distance_to(pts[0]) < 0.05):
				out.append([p, lerpf(g[i], g[i + 1], t), dirs[i]])
				last = p
			next += every
		run += length
	var end := pts[pts.size() - 1]
	if not closed and last.distance_to(end) > 0.05:
		out.append([end, g[g.size() - 1], dirs[dirs.size() - 1]])
	return out


## W7: the long faces of stretch t0..t1 of a kit segment a..b (ground `ga`, `gb`; offsets `oa`, `ob`
## per metre of half width): a box `w` half wide from `lo` to `hi` over the ground, both sides in
## `col` darkened 0.08, its top in `top` (NO_TOP: none).
func _kit_box(st, a: Vector2, b: Vector2, ga: float, gb: float, oa: Vector2, ob: Vector2, t0: float, t1: float, w: float,
		lo: float, hi: float, col: Color, top: Color) -> void:
	var p0 := a.lerp(b, t0)
	var p1 := a.lerp(b, t1)
	var o0 := oa.lerp(ob, t0) * w
	var o1 := oa.lerp(ob, t1) * w
	var g0 := lerpf(ga, gb, t0)
	var g1 := lerpf(ga, gb, t1)
	var d := (b - a).normalized()
	var nrm := Vector3(-d.y, 0.0, d.x)
	var face := col.darkened(0.08)
	for sgn: float in [1.0, -1.0]:
		var q0 := p0 + o0 * sgn
		var q1 := p1 + o1 * sgn
		map._quad(st, Vector3(q0.x, g0 + lo, q0.y), Vector3(q1.x, g1 + lo, q1.y), Vector3(q1.x, g1 + hi, q1.y),
				Vector3(q0.x, g0 + hi, q0.y), nrm * sgn, face)
	if top.a > 0.0:
		map._quad(st, Vector3(p0.x + o0.x, g0 + hi, p0.y + o0.y), Vector3(p1.x + o1.x, g1 + hi, p1.y + o1.y),
				Vector3(p1.x - o1.x, g1 + hi, p1.y - o1.y), Vector3(p0.x - o0.x, g0 + hi, p0.y - o0.y), Vector3.UP, top)


## W7: an end face across a run's end `p` (ground `g`, offset `o` per metre of half width), `w` half
## wide from `lo` to `hi`, facing `out`.
func _kit_end(st, p: Vector2, g: float, o: Vector2, w: float, lo: float, hi: float, out: Vector2, col: Color) -> void:
	var q0 := p + o * w
	var q1 := p - o * w
	map._quad(st, Vector3(q0.x, g + lo, q0.y), Vector3(q1.x, g + lo, q1.y), Vector3(q1.x, g + hi, q1.y),
			Vector3(q0.x, g + hi, q0.y), Vector3(out.x, 0.0, out.y), col.darkened(0.08))


## W7: a pier or a proud post at `p` (ground `g`): a block `along` x `across` turned to the line
## (`dir`), from `lo` to `hi` over the ground: its four sides in `col` darkened 0.08 and its top.
func _kit_block(st, p: Vector2, g: float, dir: Vector2, along: float, across: float, lo: float, hi: float, col: Color,
		top: Color) -> void:
	var u := dir * along * 0.5
	var v := Vector2(-dir.y, dir.x) * across * 0.5
	var c: Array[Vector2] = [p - u - v, p + u - v, p + u + v, p - u + v]
	var face := col.darkened(0.08)
	for i in 4:
		var c0 := c[i]
		var c1 := c[(i + 1) % 4]
		var m := ((c0 + c1) * 0.5 - p).normalized()
		map._quad(st, Vector3(c0.x, g + lo, c0.y), Vector3(c1.x, g + lo, c1.y), Vector3(c1.x, g + hi, c1.y),
				Vector3(c0.x, g + hi, c0.y), Vector3(m.x, 0.0, m.y), face)
	map._quad(st, Vector3(c[0].x, g + hi, c[0].y), Vector3(c[1].x, g + hi, c[1].y), Vector3(c[2].x, g + hi, c[2].y),
			Vector3(c[3].x, g + hi, c[3].y), Vector3.UP, top)


## W7: a rail along a..b (ground `ga`, `gb`) with its top `top` over the ground: one upright quad
## LITE_RAIL tall on the line, as rail_lite's.
func _kit_rail(st, a: Vector2, b: Vector2, ga: float, gb: float, top: float, n: Vector3, col: Color) -> void:
	var y0 := top - LITE_RAIL
	map._quad(st, Vector3(a.x, ga + y0, a.y), Vector3(b.x, gb + y0, b.y), Vector3(b.x, gb + top, b.y),
			Vector3(a.x, ga + top, a.y), n, col)


## W7: a pier's diamond collider at `p` (ground `g`, the line's `dir`): a KIT_DIAMOND m square turned
## 45 degrees to the line, its four faces from 0.3 m under the ground to `height` + 1.5 m as a
## slab's (`slab_faces`), filed as class wall. Its corners stand 0.1 m past the drawn pier's faces:
## a car meets a point, not a face, and is turned along the line.
func _pier_diamond(p: Vector2, g: float, dir: Vector2, height: float) -> void:
	var r := KIT_DIAMOND * sqrt(0.5)
	var across := Vector2(-dir.y, dir.x)
	var c: Array[Vector2] = [p + dir * r, p + across * r, p - dir * r, p - across * r]
	var up := Vector3(0.0, height + 1.5, 0.0)
	var faces := PackedVector3Array()
	for i in 4:
		var p0 := Vector3(c[i].x, g - 0.3, c[i].y)
		var p1 := Vector3(c[(i + 1) % 4].x, g - 0.3, c[(i + 1) % 4].y)
		faces.append_array([p0, p1, p1 + up, p0, p1 + up, p0 + up])
	map._solid(&"wall", faces, {"h": height})
	kit_diamonds += 1


func _load_object_overrides() -> void:
	_object_overrides = {}
	_hard_lines = {}
	if not FileAccess.file_exists(OBJECT_OVERRIDES):
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECT_OVERRIDES))
	if j is Dictionary and (j as Dictionary).get("items") is Dictionary:
		_object_overrides = j["items"]
	if j is Dictionary and (j as Dictionary).get("hard_lines") is Dictionary:
		_hard_lines = j["hard_lines"]


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
						Vector3(a.x, ga, a.y), Vector3(b.x, tops[j] + 1.5, b.y), Vector3(a.x, tops[i] + 1.5, a.y)], {"same": true, "h": h})
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


## Whether a fence line is part of Stadion Narodowy's perimeter fence (see STADIUM_CENTRE).
static func stadium_fence_line(l: Dictionary) -> bool:
	if str(l.get("k", "")) != "fence" or l.has("h") or l.has("hz") or l.has("ft") or l.has("st"):
		return false
	if not STADIUM_FENCE_TYPES.has(str(l.get("ty", ""))):
		return false
	var flat: Array = l["p"]
	var n := flat.size() / 2
	if n < 2:
		return false
	var c := Vector2.ZERO
	for i in n:
		c += Vector2(flat[i * 2], flat[i * 2 + 1])
	var r := (c / n).distance_to(STADIUM_CENTRE)
	return r >= STADIUM_FENCE_R.x and r <= STADIUM_FENCE_R.y


## The perimeter fence's gates (see GATE_HALF): `segs` are the fence segments [a, b] this build drew.
## A gate belongs to the sector holding the crossing, so two sectors never draw the same one.
func _stadium_gates(st, segs: Array) -> void:
	if segs.is_empty():
		return
	var at: Array[Vector2] = []
	var dirs: Array[Vector2] = []
	for kind in ["paths", "roads"]:
		for o: Dictionary in map.data.get(kind, []):
			if kind == "roads" and float(o.get("w", 6.0)) > 7.0:
				continue
			var q: PackedVector2Array = map._pts(o["p"])
			for i in q.size() - 1:
				var r := q[i].distance_to(STADIUM_CENTRE)
				if r < STADIUM_FENCE_R.x - 20.0 or r > STADIUM_FENCE_R.y + 20.0:
					continue
				for s: Array in segs:
					var hit: Variant = Geometry2D.segment_intersects_segment(q[i], q[i + 1], s[0], s[1])
					if not hit is Vector2 or (map._in_sector and not map._sector_rect.has_point(hit)):
						continue
					var near := false
					for p in at:
						if p.distance_to(hit) < GATE_MIN_APART:
							near = true
							break
					if not near:
						at.append(hit)
						dirs.append((s[1] - s[0]).normalized())
	for k in at.size():
		_gate(st, at[k], dirs[k])


func _gate(st, at: Vector2, d: Vector2) -> void:
	var g: float = map.terrain_height(at.x, at.y)
	var n := Vector2(-d.y, d.x)
	var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
	for sgn in [-1.0, 1.0]:
		var pier: Vector2 = at + d * GATE_HALF * sgn
		map._box_oriented(st, Vector3(pier.x, g + 1.325, pier.y), basis, Vector3(0.56, 3.3, 0.56), GATE_STONE)
		# The piers stand (F, 2026-11-15: iron panels break, piers stand): a hard box, class pier.
		map._solid(&"pier", slab_faces(pier - d * 0.28, pier + d * 0.28, 0.28, g, g, 2.95), {"same": true, "h": 2.95})
		var mid: Vector2 = at + d * (GATE_HALF * 0.5) * sgn
		map._box_oriented(st, Vector3(mid.x, g + 1.15, mid.y), basis, Vector3(0.04, 2.1, GATE_HALF - 0.6), GATE_LEAF)
		map._box_oriented(st, Vector3(mid.x, g + 0.75, mid.y), basis, Vector3(0.13, 1.0, GATE_HALF - 1.0), GATE_PANEL)
		var pole: Vector2 = at + d * 2.5 * sgn
		map._box_oriented(st, Vector3(pole.x, g + 3.2, pole.y), basis, Vector3(0.1, 2.0, 0.1), GATE_STONE)
	map._box_oriented(st, Vector3(at.x, g + 3.825, at.y), basis, Vector3(0.1, 0.85, 5.8), GATE_RED)
	for side in [-1.0, 1.0]:
		var o: Vector2 = at + n * (side as float) * 0.065
		for bar in [[-0.5, 0.51, 3.8], [-0.5, 0.24, 2.6]]:
			var c2: Vector2 = o + d * (bar[0] as float)
			map._box_oriented(st, Vector3(c2.x, g + 3.4 + (bar[1] as float), c2.y), basis, Vector3(0.025, 0.1, bar[2] as float), GATE_PALE)
		var c3: Vector2 = o + d * 2.15
		map._box_oriented(st, Vector3(c3.x, g + 3.4 + 0.42, c3.y), basis, Vector3(0.025, 0.6, 0.6), GATE_PALE)


## Every barrier line of `data` (`lines`: hedge, fence, wall, platform) in its type, by the rules
## above, into the building surface `st`.
## W2 (walls doc 6.1): with `Solidity.barrier_look()` other than classic, a line whose chain ends
## generic (its kind's own row, or what `_mapped_style` made of it; a wall that only got its mapped
## `h` stays generic) is drawn from its `ty`'s `looks` row (`_typed`); every line a rule, a site, the
## bake's `st` or a street pass gave a look keeps it. Under classic nothing of that runs.
func build_barriers(st) -> void:
	map._uv2 = Vector2(0.5, -1.0)
	_load_object_overrides()
	soft_ids = PackedStringArray()
	soft_kinds = PackedStringArray()
	soft_mats = PackedStringArray()
	soft_panels = PackedInt32Array()
	soft_segs = PackedFloat64Array()
	_soft_line = {}
	look_counts = {}
	mesh_light = {}
	low_typed = PackedStringArray()
	default_lines = 0
	panel_tiles = {}
	panel_pieces = 0
	_panel_serial = 0
	kit_diamonds = 0
	gate_counts = {"lines": 0, "gaps": 0, "posts": 0, "leaves": 0}
	var typed_on := Solidity.barrier_look() != &"classic"
	# W4: panels, unless this GPU gets the typed look instead (gpu_quirks.gd).
	var panels_on := Solidity.barrier_look() == &"panels" and GpuQuirks.panels()
	_stairs_for_walls()
	var gate_segs: Array = []
	for l in map.data.get("lines", []):
		var site_wall: Array = _site_wall(l["p"]) if l["k"] == "wall" or l["k"] == "fence" else []
		if not site_wall.is_empty() and str(site_wall[1]) == "":
			continue
		if l["k"] != "platform" and map._in_pkin_forecourt(l["p"]):
			continue
		if map._in_trybuna(l["p"]):
			continue
		if (l["k"] == "fence" or l["k"] == "wall") and map._on_markiewicz(map._pts(l["p"])):
			continue  # Wiadukt Markiewicza's balustrades and their colliders are the landmark's (landmarks/karowa.gd)
		if l["k"] == "fence" and _over_river(l["p"]):
			continue
		var style: Array = _placed(str(l["k"]))
		# W2: whether the chain below ends at the kind's own row or what _mapped_style makes of it.
		var generic := not style.is_empty()
		if style.is_empty():
			style = _s(&"barrier_default")
		if not site_wall.is_empty():
			style = _placed(str(site_wall[1]))
			generic = false
		elif l["k"] == "wall":
			if _garden_ring(l["p"]):
				style = _s(&"garden_ring")
				generic = false
			elif _low_wall(l["p"]):
				style = _s(&"low_wall")
				generic = false
			elif _in_island(l["p"]):
				style = _s(&"island_edge")
				generic = false
			elif _in_pkin_zone(l["p"]):
				style = _placed("balustrade") if _by_steps(l["p"]) else _s(&"pkin_wall")
				generic = false
			elif l.has("h"):
				var wh := float(l["h"])
				var wall := Solidity.type_row(&"wall")
				style = [style[0], float(wall["low_thickness"]) if wh <= float(wall["low_height"]) else float(wall["thickness"]), wh]
			elif _rim_ring(map._pts(l["p"])):
				style = _s(&"basin_rim")
				generic = false
			elif _wraps_stairwell(map._pts(l["p"])):
				style = _placed("balustrade_rail")
				generic = false
		style = _mapped_style(l, style)
		if stadium_fence_line(l):
			style = _placed("stadium_fence")
			var gp: PackedVector2Array = map._pts(l["p"])
			for gi in gp.size() - 1:
				gate_segs.append([gp[gi], gp[gi + 1]])
			generic = false  # W2: the stadium's own fence (#808) keeps its look in every look
		# Street objects unslopped (tools/object_fixes.py, 2026-11-07): a barrier's own style, the
		# balustrade of a wall or fence beside a flight of steps that OSM gives no height, material or
		# fence type (tools/barrier_tags.py's tags win: object_fixes leaves tagged lines alone).
		# A street pass's override still wins.
		if site_wall.is_empty() and l.has("st") and is_style(str(l["st"])):
			style = _placed(str(l["st"]))
			generic = false
		if not _object_overrides.is_empty() and l["k"] != "platform":
			var o: Variant = _object_overrides.get(barrier_id(l["k"], l["p"]))
			if o is Array:
				if str(o[0]) == "REMOVE":
					continue
				if (o as Array).size() > 1 and is_style(str(o[1])):
					style = _placed(str(o[1]))
					generic = false
		# W2: the typed drawing ({}: `style` as ever; draw none: left out, as REMOVE is).
		var look := {}
		if typed_on:
			look = _typed(l, generic)
			if look.get("draw", &"") == &"none":
				continue
			# W5: the stadium's railing (#808) keeps its look under typed; under panels it is
			# panels of its row at its types row's height, colliding as railing_along does.
			var row_ty := StringName(str(l.get("ty", "")))
			if panels_on and look.is_empty() and style == _placed("stadium_fence") and PanelRule.is_panel(&"stadium_fence"):
				row_ty = &"stadium_fence"
				look = {"draw": &"rail", "row": Solidity.look_row(row_ty), "h": float(style[2]), "colour": Color(style[0])}
			# W4: a row marked `panel` is drawn as panel pieces (panel_along).
			if panels_on and not look.is_empty() and bool((look["row"] as Dictionary).get("panel", false)):
				look["panel"] = PanelRule.row_of(row_ty)
				look["seed"] = PanelRule.seed(barrier_id(l["k"], l["p"]))
				_panel_run = 0.0
				_panel_serial += 1
				_count_look(&"panel")
			elif panels_on and str(Solidity.look_row(row_ty).get("family", "")) == "light":
				mesh_light[str(row_ty)] = int(mesh_light.get(str(row_ty), 0)) + 1
		if style == _s(&"barrier_default"):
			default_lines += 1
		var pts: PackedVector2Array = map._pts(l["p"])
		var solid: bool = l["k"] != "platform" and float(style[2]) >= BARRIER_SOLID_MIN
		var cls := barrier_class(l)
		# Step 7: a soft line is drawn as before and files no collider faces (soft_things.gd breaks it).
		# W2: decided on the classic style, so a typed city has the same soft lines.
		if _is_soft(l, style, cls, solid or style.size() > 3):
			_begin_soft(l, pts)
		if not look.is_empty():
			# W2: a typed line collides at its drawn height (rule R2), by the same rule as a slab.
			solid = l["k"] != "platform" and float(look["h"]) >= BARRIER_SOLID_MIN
			if not solid:
				low_typed.append(barrier_id(l["k"], l["p"]))
		# W8: a line with gates (tools/barrier_gates.py `g`, `ge`), under typed and panels only and only
		# where the line is drawn by its typed look (walls doc 6.1: every hand-placed and F-approved
		# look, the stadium's railing with its own gates among them, stays as it is): its pieces between
		# the gaps, each drawn as a whole line is, with the runs along the line (soft segments, panel
		# indices) carried on from where the piece starts, then its gate posts and leaves.
		if typed_on and not look.is_empty() and not stadium_fence_line(l) and (l.has("g") or l.has("ge")):
			gate_counts["lines"] += 1
			gate_counts["gaps"] += (l.get("g", []) as Array).size()
			var cut := gate_pieces(pts, l.get("g", []))
			for pc: Array in cut:
				_soft_run = float(pc[1])
				_panel_run = float(pc[1])
				_draw_line(st, l, pc[0], style, look, solid, cls)
			_gate_kit(st, l, pts, style, look, cls)
		else:
			_draw_line(st, l, pts, style, look, solid, cls)
		_soft_line = {}
	_pocket_hedges(st)
	_stadium_gates(st, gate_segs)
	map._uv2 = Vector2.ZERO


## One barrier line `l` (or, W8, one piece `pts` of it between its gaps) by its classic `style` or
## typed `look`: an OSM-mapped railing (railing_along), a wall's pieces off a sunken ring's edge or
## between stair gaps, or the line as one piece (_draw_piece).
func _draw_line(st, l: Dictionary, pts: PackedVector2Array, style: Array, look: Dictionary, solid: bool, cls: StringName) -> void:
	if look.is_empty() and style.size() > 3:
		var open: Array = style[3]
		# A railing OSM maps (tools/barrier_tags.py) has a post every `posts_mapped` m: 30 km of them.
		railing_along(st, pts, float(style[2]), float(open[0]), Color(style[0]), Color(str(open[1])), true, cls,
				float(open[3]) if l.has("ft") or (l["k"] == "fence" and float(l.get("h", 0.0)) > float(_kit["fence_max"])) else float(open[2]))
		return
	# Loop 3b: a stop's platform is kerb height (0.25 m), not a wall: like the kerbs and
	# islands, the car drives over it (check_drive.gd found buses brushing them).
	if l["k"] == "wall" and not map._sunk.is_empty() and map._sunk_box.grow(2.0).intersects(map._box_of_pts(pts)):
		# The pieces off a sunken ring's edge (the site builds the walls on it).
		if map._walls_in_ramp(pts):
			return
		var piece := PackedVector2Array()
		for i in pts.size():
			if i > 0 and map._on_sunk_edge(pts[i - 1], pts[i]):
				if piece.size() >= 2:
					_draw_piece(st, piece, style, look, solid, cls)
				piece = PackedVector2Array()
			piece.append(pts[i])
		if piece.size() >= 2:
			_draw_piece(st, piece, style, look, solid, cls)
		return
	if l["k"] == "wall" and not _stair_idx.is_empty():
		for piece in _stair_gaps(pts):
			_draw_piece(st, piece, style, look, solid, cls)
		return
	_draw_piece(st, pts, style, look, solid, cls)


## One piece of a barrier line: in classic `style` with wall_along as ever, or (W2) by `look`, the
## line's `_typed` drawing: a slab at the row's thickness, or posts and rails (`rail_lite_along`).
## W7: a heavy or low slab row by the heavy kit (`wall_kit`); a row with piers gets them and its
## plinth from `_pier_fence_kit`, its rails from rail_lite_along without its posts and foot.
func _draw_piece(st, piece: PackedVector2Array, style: Array, look: Dictionary, solid: bool, cls: StringName) -> void:
	if look.is_empty():
		wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), solid, cls)
	elif look.has("panel"):
		panel_along(st, piece, look, solid, cls)
	elif look["draw"] == &"slab":
		if kit_row(look["row"]):
			wall_kit(st, piece, look, solid, cls)
		else:
			wall_along(st, piece, float((look["row"] as Dictionary)["thick"]), float(look["h"]), look["colour"], solid, cls)
	else:
		# W7: a row with piers (bars_pier) stands its plinth and piers by the kit, its rails between.
		var piers := (look["row"] as Dictionary).has("pier")
		if piers:
			_pier_fence_kit(st, piece, look["row"], float(look["h"]))
		rail_lite_along(st, piece, look["row"], float(look["h"]), look["colour"], solid, cls, piers)


## W4 (walls doc 6.4): a panel line's piece `poly` (a line, or one piece of it between stair gaps
## or a sunken ring's edges), drawn by its `look` (`_typed`, with the panel's row and seed): no
## triangles in the city mesh, but its 2 m panel pieces (`_panel_segment`), and the colliders its
## typed drawing files, the same faces in the same order (a `rail` row: `rail_faces`, as
## rail_lite_along; a `slab` row: `slab_faces` at the row's thickness, as wall_along), with
## `_soft_run` advanced as each of them advances it, so a panels city has the typed city's
## colliders and soft lines.
## W5: a row whose posts are `in_mesh` (bars_pier) keeps them in the city mesh `st` as typed draws
## them (`_mesh_posts`); its panels draw no posts (panel_rule.gd row_texels).
## W7: a row with piers (bars_pier) stands its piers and plinth by the kit (`_pier_fence_kit`) as
## typed does, in the same order before the line's colliders, so the two looks file the same faces.
func panel_along(st, poly: PackedVector2Array, look: Dictionary, collide: bool, cls: StringName) -> void:
	var row: Dictionary = look["row"]
	var slab: bool = look["draw"] == &"slab"
	var height := float(look["h"])
	var thick := float(row["thick"])
	if row.has("pier"):
		_pier_fence_kit(st, poly, row, height)
	elif bool((row.get("post", {}) as Dictionary).get("in_mesh", false)):
		_mesh_posts(st, poly, row, height, look["colour"])
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var ga: float = map.terrain_height(a.x, a.y)
		var gb: float = map.terrain_height(b.x, b.y)
		_panel_segment(a, b, ga, gb, length, height, thick, look)
		_panel_run += length
		if collide:
			var faces := slab_faces(a, b, thick * 0.5, ga, gb, height) if slab else rail_faces(a, b, ga, gb, height)
			if _soft_line.is_empty():
				map._solid(cls, faces, {"same": true, "h": height})
			else:
				_soft_seg(cls, faces, a, b, thick * 0.5 if slab else 0.0, ga, gb, height)
			if slab:
				_soft_run += length
		if not slab:
			_soft_run += length


## W5: rail_lite_along's posts alone along `poly` (row `row`, the line's `height` and `colour`): one
## every `post.every` m of the whole line and one at its last point, the same quads at the same
## places, so a row's posts stand under panels where typed stands them.
func _mesh_posts(st, poly: PackedVector2Array, row: Dictionary, height: float, colour: Color) -> void:
	var post: Dictionary = row.get("post", {})
	var every := float(post.get("every", 0.0))
	var pw := float(post.get("w", 0.0)) * 0.5
	if every <= 0.0 or pw <= 0.0:
		return
	var post_col := Color(str(post["colour"])) if post.has("colour") else colour
	var foot_h := float((row.get("foot", {}) as Dictionary).get("h", 0.0))
	var run := 0.0
	var next_post := 0.0
	var last_post := Vector2(INF, INF)
	var last_dir := Vector2.ZERO
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var dir := (b - a) / length
		last_dir = dir
		var n := Vector3(-dir.y, 0.0, dir.x)
		var ga: float = map.terrain_height(a.x, a.y)
		var gb: float = map.terrain_height(b.x, b.y)
		while next_post <= run + length:
			var p := a + dir * (next_post - run)
			_lite_post(st, p, lerpf(ga, gb, (next_post - run) / length), dir, pw, foot_h, height, n, post_col)
			last_post = p
			next_post += every
		run += length
	if last_dir != Vector2.ZERO:
		var end := poly[poly.size() - 1]
		if last_post.distance_to(end) > 0.05:
			_lite_post(st, end, map.terrain_height(end.x, end.y), last_dir, pw, foot_h, height,
					Vector3(-last_dir.y, 0.0, last_dir.x), post_col)


## W4: segment a..b (its ground `ga`, `gb`, `length` m) cut at every PANEL m of the line's run
## (`_panel_run` at a): one piece per panel it crosses, a piece under 0.05 m left out.
func _panel_segment(a: Vector2, b: Vector2, ga: float, gb: float, length: float, height: float, thick: float,
		look: Dictionary) -> void:
	var r0 := _panel_run
	var r1 := r0 + length
	var k := floori(r0 / PANEL)
	while true:
		var s0 := maxf(r0, k * PANEL)
		var s1 := minf(r1, (k + 1) * PANEL)
		if s1 - s0 >= 0.05:
			var t0 := (s0 - r0) / length
			var t1 := (s1 - r0) / length
			_panel_piece(a.lerp(b, t0), a.lerp(b, t1), lerpf(ga, gb, t0), lerpf(ga, gb, t1), (b - a) / length, s0, k,
					height, thick, look)
		if (k + 1) * PANEL >= r1:
			break
		k += 1


## Floats a panel piece takes in a PanelTile's `buf`: a 3D transform (12) and the custom data (4).
const PANEL_FLOATS := 16


## W4: one tile's panel pieces (see `panel_tiles`).
class PanelTile:
	var buf := PackedFloat32Array()
	var ids := PackedStringArray()
	var first := PackedInt32Array()
	var count := PackedInt32Array()
	var panel := PackedInt32Array()
	var box := AABB()
	var last := -1

	## The tile's `panels` meta (map_builder.gd `_build_panels`).
	func meta() -> Dictionary:
		return {"ids": ids, "first": first, "count": count, "panel": panel}


## W4: one panel piece p0..p1 (its foot g0..g1, the line's direction `dir`, `run` m along the line
## at p0, panel index `panel`) into its tile's buffer: the unit box of map_builder.gd `panel_box`
## (x 0..1 along, y 0..1 up, z -0.5..0.5 across) stretched to the piece, from PanelRule.SINK under
## its foot to `height` over it, `thick` across, its posts upright on a slope (the slope is in its
## x axis). A piece belongs to the tile holding its middle, so the sectors together hold every
## piece once.
func _panel_piece(p0: Vector2, p1: Vector2, g0: float, g1: float, dir: Vector2, run: float, panel: int, height: float,
		thick: float, look: Dictionary) -> void:
	var mid := (p0 + p1) * 0.5
	var key := Vector2i(floori(mid.x / map.SECTOR), floori(mid.y / map.SECTOR))
	if map._in_sector and key != map._sector:
		return
	var x := Vector3(p1.x - p0.x, g1 - g0, p1.y - p0.y)
	var y := Vector3(0.0, height + PanelRule.SINK, 0.0)
	var z := Vector3(-dir.y, 0.0, dir.x) * thick
	var o := Vector3(p0.x, g0 - PanelRule.SINK, p0.y)
	var t: PanelTile = panel_tiles.get(key)
	if t == null:
		t = PanelTile.new()
		t.box = AABB(o, Vector3.ZERO)
		panel_tiles[key] = t
	t.buf.append_array([x.x, y.x, z.x, o.x, x.y, y.y, z.y, o.y, x.z, y.z, z.z, o.z,
			float(look["panel"]), run, 0.0, float(look["seed"])])
	if not _soft_line.is_empty():
		if t.last != _panel_serial:
			t.last = _panel_serial
			t.ids.append(soft_ids[int(_soft_line["i"])])
			t.first.append(t.panel.size())
			t.count.append(0)
		t.count[t.count.size() - 1] += 1
	t.panel.append(panel)
	for c: Vector3 in [o - z * 0.5, o + z * 0.5, o + x + y - z * 0.5, o + x + y + z * 0.5]:
		t.box = t.box.expand(c)
	panel_pieces += 1


## W8 (walls doc 6.6 row 9): a gate post stands GATE_RISE m over its line, GATE_POST_W m square (or the
## line's thickness and GATE_POST_PROUD more, a wall's pier), sunk GATE_SINK m, wholly inside the line
## at the piece's end (the opening keeps the gap's or the bake's cut's width for the car); it files no
## collider of its own (the line's faces reach height + 1.5 m over it, as the line's own posts). A
## drive's open leaf: GATE_LEAF_LEN m long (half a 3.6 m drive gate) or the gap's half width, lying
## along the line on the yard side GATE_LEAF_OFF m off its face, GATE_LEAF_LIFT m over the ground, a
## frame and a bar every GATE_BAR m, in GATE_LEAF's colour; no collider (it lies against the line).
const GATE_RISE := 0.3
const GATE_POST_W := 0.14
const GATE_POST_PROUD := 0.08
const GATE_SINK := 0.2
const GATE_LEAF_LEN := 1.8
const GATE_LEAF_OFF := 0.06
const GATE_LEAF_LIFT := 0.05
const GATE_BAR := 0.3
const GATE_FRAME := 0.06
const GATE_POST := Color("#2b2e33")


## W8: the pieces of polyline `pts` left between the gaps `g` ([[s, w, leaf], ...]: from s m along it,
## w m long; tools/barrier_gates.py): [[piece, metres along the line where it starts], ...], pieces
## under 0.05 m left out. With no gap: the line itself from 0.
static func gate_pieces(pts: PackedVector2Array, g: Array) -> Array:
	var spans: Array = []
	for x: Array in g:
		spans.append([float(x[0]), float(x[0]) + float(x[1])])
	spans.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var out: Array = []
	var start := 0.0
	for sp: Array in spans + [[total + 1.0, total + 1.0]]:
		var end := minf(float(sp[0]), total)
		if end - start >= 0.05:
			out.append([line_cut(pts, start, end), start])
		start = maxf(start, float(sp[1]))
	return out


## W8: the part of polyline `pts` from `s0` to `s1` m along it (its own points between, the cut points
## at both ends).
static func line_cut(pts: PackedVector2Array, s0: float, s1: float) -> PackedVector2Array:
	var out := PackedVector2Array([line_at(pts, s0)])
	var run := 0.0
	for i in pts.size() - 1:
		run += pts[i].distance_to(pts[i + 1])
		if run > s0 + 1e-6 and run < s1 - 1e-6 and i + 1 < pts.size() - 1:
			out.append(pts[i + 1])
	out.append(line_at(pts, s1))
	return out


## W8: the point `s` m along polyline `pts` (clamped to its ends).
static func line_at(pts: PackedVector2Array, s: float) -> Vector2:
	var run := 0.0
	for i in pts.size() - 1:
		var length := pts[i].distance_to(pts[i + 1])
		if run + length >= s and length > 1e-9:
			return pts[i].lerp(pts[i + 1], clampf((s - run) / length, 0.0, 1.0))
		run += length
	return pts[pts.size() - 1] if s > 0.0 else pts[0]


## W8: the unit direction of polyline `pts` at `s` m along it.
static func line_dir(pts: PackedVector2Array, s: float) -> Vector2:
	var run := 0.0
	for i in pts.size() - 1:
		var length := pts[i].distance_to(pts[i + 1])
		if length > 1e-9 and (run + length >= s or i == pts.size() - 2):
			return (pts[i + 1] - pts[i]) / length
		run += length
	return Vector2.RIGHT


## W8: what a line's gates stand, as data (check_barrier_look tests it): [[kind, metres along the line,
## out], ...], kind &"post" (out: +1 the opening lies further along the line, -1 before it) or
## &"leaf" (out as the post's; the leaf's side in [3]: +1 left of the line's direction, -1 right).
## A gap's two edges inside the line get a post each; an `ge` end a post, and with +-2 a leaf.
static func gate_marks(pts: PackedVector2Array, g: Array, ge: Array) -> Array:
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var out: Array = []
	for x: Array in g:
		var s0 := float(x[0])
		var s1 := s0 + float(x[1])
		var leaf := int(x[2]) if x.size() > 2 else 0
		for edge: Array in [[s0, 1.0], [s1, -1.0]]:
			var s := float(edge[0])
			if s <= 0.01 or s >= total - 0.01:
				continue
			out.append([&"post", s, float(edge[1]), 0])
			if leaf != 0:
				out.append([&"leaf", s, float(edge[1]), leaf])
	for e in mini(ge.size(), 2):
		var v := int(ge[e])
		if v == 0:
			continue
		var s := 0.0 if e == 0 else total
		var o := -1.0 if e == 0 else 1.0
		out.append([&"post", s, o, 0])
		if absi(v) == 2:
			out.append([&"leaf", s, o, signi(v)])
	return out


## W8: line `l`'s gate posts and open leaves (gate_marks) into the city mesh `st`, at its drawn height
## (`look`'s, else the classic `style`'s) and thickness. A sector keeps the triangles whose centre lies
## in it (chunked_surface.gd), as for the line itself.
func _gate_kit(st, l: Dictionary, pts: PackedVector2Array, style: Array, look: Dictionary, cls: StringName) -> void:
	var height := float(style[2]) if look.is_empty() else float(look["h"])
	var thick := float(style[1]) if look.is_empty() else float((look["row"] as Dictionary).get("thick", GATE_POST_W))
	var wall := cls == &"wall"
	var post_w := maxf(GATE_POST_W, thick + GATE_POST_PROUD) if wall else GATE_POST_W
	var colour: Color = Color(style[0]) if look.is_empty() else look["colour"]
	var post_col := colour.lightened(0.08) if wall else GATE_POST
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	for m: Array in gate_marks(pts, l.get("g", []), l.get("ge", [])):
		var out := float(m[2])
		# The post's middle half its width back from the opening, so it stands wholly inside the line.
		var s := clampf(float(m[1]) - out * post_w * 0.5, 0.0, total)
		var p := line_at(pts, s)
		var dir := line_dir(pts, s)
		var y: float = map.terrain_height(p.x, p.y)
		if m[0] == &"post":
			gate_counts["posts"] += 1
			var top := y + height + GATE_RISE
			var bottom := y - GATE_SINK
			map._box_oriented(st, Vector3(p.x, (top + bottom) * 0.5, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)),
					Vector3(post_w, top - bottom, post_w), post_col)
			continue
		# A leaf: from the post's face back along the line (away from the opening), on the yard side.
		var gap_half := GATE_LEAF_LEN
		for x: Array in l.get("g", []):
			if absf(float(x[0]) - float(m[1])) < 0.01 or absf(float(x[0]) + float(x[1]) - float(m[1])) < 0.01:
				gap_half = float(x[1]) * 0.5
		# As long as the line behind the post allows (a leaf does not reach past the line's far end).
		var behind := s - post_w * 0.5 if out > 0.0 else total - s - post_w * 0.5
		var length := minf(gap_half, behind)
		if length < 0.3:
			continue
		gate_counts["leaves"] += 1
		var n := Vector2(-dir.y, dir.x) * float(m[3])
		var off := n * (thick * 0.5 + GATE_LEAF_OFF)
		var a := p + off - dir * out * post_w * 0.5
		var b := a - dir * out * length
		_gate_leaf(st, a, b, map.terrain_height(a.x, a.y), map.terrain_height(b.x, b.y),
				minf(height, 2.2), Vector3(n.x, 0.0, n.y))


## W8: one open leaf from `a` (its hinge, by the post) to `b`, its foot `ga`, `gb` on the ground,
## `height` tall: a frame (top and bottom rails, the far stile) and a bar every GATE_BAR m, upright
## quads in GATE_LEAF (one quad shows from both sides: the building shader is cull_disabled).
func _gate_leaf(st, a: Vector2, b: Vector2, ga: float, gb: float, height: float, n: Vector3) -> void:
	var lo := GATE_LEAF_LIFT
	var hi := height - 0.1
	for y0: float in [lo, hi - GATE_FRAME]:
		map._quad(st, Vector3(a.x, ga + y0, a.y), Vector3(b.x, gb + y0, b.y), Vector3(b.x, gb + y0 + GATE_FRAME, b.y),
				Vector3(a.x, ga + y0 + GATE_FRAME, a.y), n, GATE_LEAF)
	var length := a.distance_to(b)
	var dir := (b - a) / length
	var bars := maxi(1, floori(length / GATE_BAR))
	for k in range(1, bars + 1):
		var t := minf(1.0, float(k) * GATE_BAR / length) if k < bars else 1.0
		var c := a.lerp(b, t)
		var w := dir * (GATE_FRAME if k == bars else 0.02)
		var g := lerpf(ga, gb, t)
		map._quad(st, Vector3(c.x - w.x, g + lo, c.y - w.y), Vector3(c.x, g + lo, c.y), Vector3(c.x, g + hi, c.y),
				Vector3(c.x - w.x, g + hi, c.y - w.y), n, GATE_LEAF)

## W2: line `l`'s typed drawing, from its `ty`'s `looks` row (solidity.gd `look_row`), or {} when it
## keeps its classic style: a line whose chain did not end `generic`, a platform, no `ty`, a type
## with no row, or a row drawn `keep`. {"draw": &"none"} for a row not drawn; else {"draw": &"slab"
## or &"rail", "row", "h", "colour"}. The height is OSM's `h`, else the bake's `hs` (each clamped to
## the row's `h_range` when it has one), else the row's `h`; the colour the row's, or one of its
## `alt` colours, picked by a hash of the line's stable id so a line is the same on both paths.
func _typed(l: Dictionary, generic: bool) -> Dictionary:
	if not generic or l["k"] == "platform":
		_count_look(&"classic")
		return {}
	var row := Solidity.look_row(StringName(str(l.get("ty", ""))))
	var draw := StringName(str(row.get("draw", "")))
	if draw == &"none":
		_count_look(&"none")
		return {"draw": &"none"}
	if draw != &"slab" and draw != &"rail":
		_count_look(&"keep" if draw == &"keep" else &"unknown")
		return {}
	var h := float(row["h"])
	if l.has("h"):
		h = float(l["h"])
	elif l.has("hs"):
		h = float(l["hs"])
	if (l.has("h") or l.has("hs")) and row.has("h_range"):
		h = clampf(h, float(row["h_range"][0]), float(row["h_range"][1]))
	var colour := Color(str(row["colour"]))
	var alt: Array = row.get("alt", [])
	var picked := -1
	if not alt.is_empty():
		var pick := posmod(hash(barrier_id(l["k"], l["p"])), 1000)
		var upto := 0.0
		for i in alt.size():
			upto += float(alt[i][1]) * 1000.0
			if pick < upto:
				colour = Color(str(alt[i][0]))
				picked = i
				break
	_count_look(draw)
	# W7: which alt colour the line took (-1: the row's own; a cap's `alt` goes with it) and the
	# bake's hazard reason (a stone wall's top rail stands over water or a drop).
	return {"draw": draw, "row": row, "h": h, "colour": colour, "alt": picked, "hz": str(l.get("hz", ""))}


## W2: one more line (or rail piece) under `what` in `look_counts`.
func _count_look(what: StringName) -> void:
	look_counts[what] = int(look_counts.get(what, 0)) + 1


## POCKET_HEDGES, each piece (two points) in the sector that holds its middle, so a runtime city
## and the prebuilt sectors get every piece once.
func _pocket_hedges(st) -> void:
	var style := _placed("hedge")
	if style.is_empty():
		return
	for line: Array in POCKET_HEDGES:
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			if map._in_sector and not map._sector_rect.has_point((a + b) * 0.5):
				continue
			wall_along(st, PackedVector2Array([a, b]), float(style[1]), float(style[2]), Color(style[0]), true, &"hedge")


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
		# On Wiadukt Markiewicza the guard lines are the roadway's kerbs (landmarks/karowa.gd draws them):
		# no rail, the collider kept.
		var kerb_only: bool = dk >= 0 and map._on_markiewicz(poly)
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
			if kerb_only:
				run += length
				map._solid(guard, [Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + 1.6, b.y),
						Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + 1.6, b.y), Vector3(a.x, ga + 1.6, a.y)], {"site": "wiadukt_markiewicza"})
				continue
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
					Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + 1.6, b.y), Vector3(a.x, ga + 1.6, a.y)], {"same": true, "h": 0.85})
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
						Vector3(p0.x, y0 - 0.3, p0.y), Vector3(p1.x, y1 + 1.6, p1.y), Vector3(p0.x, y0 + 1.6, p0.y)], {"none": "join"})
			guard_joins += 1
	map._uv2 = Vector2.ZERO
