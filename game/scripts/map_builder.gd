extends Node3D
## Builds the city: terrain, parks, paths, roads with lane markings and tram
## rails laid over it, GUGiK LoD2 buildings (plus OpenStreetMap extrusions where
## LoD2 has nothing), trees, the collision the car drives against, and a grid of
## roof heights the helicopter flies over.

# Godot treats clockwise triangles as front faces, so a front face's
# (b - a) x (c - a) points away from the viewer.
const CLOCKWISE_FRONT := true
const Chunked := preload("res://scripts/chunked_surface.gd")
const Neon := preload("res://scripts/neon_signs.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const CityMaps := preload("res://scripts/city_maps.gd")
## Loop 2c: the parked cars' mesh and paints come from the vehicles' models (one source).
const Models := preload("res://scripts/models.gd")
const Trains := preload("res://scripts/trains.gd")
const RailCut := preload("res://scripts/rail_cut.gd")
const RailYard := preload("res://scripts/rail_yard.gd")
const StationLines := preload("res://scripts/station_lines.gd")
const MapEdge := preload("res://scripts/map_edge.gd")
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
const RatuszHub := preload("res://scripts/ratusz_hub.gd")
## Pasaż Wiecha's white Y masts stand where the map has its lamps (first_scene.gd PASAZ).
const FirstScene := preload("res://scripts/first_scene.gd")
## Tile size for instanced things (trees, lamps, parked cars). Loop 2b: 512 m (was 256): one
## MultiMesh is one draw call, and the iPhone pays per draw call, not per instance.
const INSTANCE_TILE := 512.0
## Loop 2b: things under a metre tall (benches, bins, bike racks) cast no sun shadow (a few
## texels at most) and hide when the view is wider than main.gd's FINE_VIEW metres, where
## they are under two pixels: the group "fine_detail".
const FINE_GROUP := "fine_detail"
## Loop 2b: lamps, signals, parked cars, advertising columns and shelters: they cast sun shadows
## on High only (main.gd QUALITY); the group "small_casters".
const SMALL_CASTERS := "small_casters"

## Landmarks 0.3 (2026-10-31): the site key of `--solo=KEY` (main.gd); while set, a run builds
## that landmark alone (no ground, roads, buildings, trees or props) for the judge's unlit and
## silhouette shots. Static, because the streamer makes the builder. Runtime path only.
static var solo_site := ""
## Direction of the Śródmieście street grid (Marszałkowska), for paving on open areas.
const CITY_GRID := Vector2(0.342, 0.940)
## Ground-shader layer ids (UV.y).
const L_GROUND := 0.0
const L_GREEN := 1.0
const L_PLAZA := 2.0
const L_WATER := 3.0
const L_FOOT := 4.0
const L_CYCLE := 5.0
const L_ROAD := 6.0
const L_MARK := 7.0
const L_RAIL := 8.0
const L_BALLAST := 9.0
const L_STEPS := 10.0
const L_FLOWERS := 11.0
const L_DIRT := 12.0
const L_PLAY := 13.0
const L_ISLAND := 14.0
const L_GRAVEL := 15.0
## Loop 3b-2: dry sand (beaches, sandbars), the wet band of a natural bank or a sandbar's rim
## (its colour from the vertex: sand or earth) and the foam line on the waterline.
const L_SAND := 16.0
const L_WET := 17.0
const L_FOAM := 18.0
## Loop 3b-2: the tram bed's concrete track slabs (joints across it every 3 m).
const L_TRAMBED := 19.0
## First-scene item 5 (2026-11-02): the tactile warning pads where a crossing meets a kerb.
const L_TACTILE := 20.0
## Smooth roads loop 7 (F's ChatGPT target, 2026-11-05): a tram track's sleepers on its own bed.
const L_SLEEPERS := 21.0

const Y_GROUND := 0.0
const Y_AREA := 0.02
## Each green kind's height over Y_AREA (merging loop 3c): a fixed order where they overlap,
## park under grass under pitch, all under the sand (0.006 and up) and over the plazas (0).
const GREEN_Y := {"park": 0.003, "grass": 0.004, "pitch": 0.005}
## The stadium's grass embankment (_build_areas) under the plazas (Y_AREA) and over the ground.
const BANK_Y := -0.008
const Y_PATH := 0.04
const Y_ROAD := 0.06
const Y_MARK := 0.08
const FLOOR_HEIGHT := 3.3

const COL := {
	"ground": Color("#bdb6a3"),
	"plaza": Color("#d9d1bf"),
	"park": Color("#7fb04f"),
	"grass": Color("#8fbd58"),
	"pitch": Color("#6fa94f"),
	"water": Color("#5ea8d8"),
	"road": Color("#4f535a"),
	"road_minor": Color("#4f535a"),
	# R3 of docs/design/start-area-real.md: Warsaw's footways are light grey concrete, not sand.
	"foot": Color("#dddcd6"),
	"cycle": Color("#c86e5c"),
	"mark": Color("#f4f1e8"),
	"rail": Color("#3d3a37"),
}
const FACADES := ["#e9dcc2", "#d8c6a6", "#cfc4b2", "#e3c993", "#c9b08e", "#b9bec4", "#d9b98f", "#b59c7e", "#e6dccd", "#c98f6b", "#a8a49d", "#d6a77a"]
## RF4 (OsmRoofs): the pitched roofs' districts: aged copper, red sheet metal, ceramic tile.
const PATINA := "#6f9c88"
const RED_SHEET := "#93493b"
const TILE_RED := "#a85a40"
const MDM_REACH := 430.0   ## m from Plac Konstytucji: Marszałkowska's socialist-realist blocks
const ROOFS := ["#8d8882", "#7d726a", "#9b9187", "#72777c", "#857a70"]
const GLASS := ["#8fb4cb", "#9fbfd2", "#7ea4bd", "#a9c3cf"]
const CANOPY_SUMMER := ["#4e8a3b", "#5d9a44", "#437c36", "#6aa64c", "#5a8f3e"]
const CANOPY_AUTUMN := ["#4f8a3b", "#5f9640", "#7a9a35", "#a59a32", "#cfa22b", "#de8b2b", "#c8642c", "#4a8038", "#93a03a"]
const NEEDLE := ["#2f5e3a", "#376b40", "#2a5434"]

## "autumn" or "summer": picks the leaf colours.
var season := "autumn"
var data: Dictionary
## Tree crowns; the game feeds it the car position so crowns can open up around the car.
@export_storage var leaf_material: ShaderMaterial
## The materials the game updates every frame (car position for the see-through hole).
@export_storage var building_material: ShaderMaterial
@export_storage var flat_material: ShaderMaterial
## Every material that opens a see-through hole around the car (trees, parked cars).
@export_storage var fade_materials: Array[ShaderMaterial] = []
## The street-lamp light map's rectangle (tools/bake_lights.py; _sodium_at reads it).
@export_storage var light_rect := Vector4(0, 0, 1, 1)
## v0.9: the surface map's rectangle (tools/bake_water.py: distance to the shore, the river's
## flow, what reflects, bridge-deck heights; the ground shader and the post pass read it).
@export_storage var water_rect := Vector4(0, 0, 1, 1)
## Loop 3d-2b: the AO, lamp-light and surface maps reach the GPU per sector (city_maps.gd): their
## grids, "fine" (the AO and lamp-light maps) and "surface", each x0, z0, metres a texel, 0. The
## whole images stay on the CPU only while sectors are built (map_slices), never in index.res.
@export_storage var map_grids := {}
## Loop 3d-2b: per sector key, how many of its meshes and MultiMeshes tools/bake_city.gd saved as
## files of their own (map/sectors/s_<i>_<j>/<n>.res): the streamer's worker loads them one a
## frame before the sector's scene, so the GPU buffers they make reach the renderer a few a frame.
@export_storage var sector_pieces := {}
## Loop 3d-2b: the loaded sectors' map slices on the GPU (sector_streamer.gd, or main.gd for
## --monolithic: every sector's).
var city_maps: CityMaps
## Loop 3d-2b: the AO and surface maps' files and sizes: a sector's slices are read from them
## (rows of the file), so the whole maps never sit in memory (the lamp-light map's image does,
## for the lamp heads' colours).
var _ao_file := ""
var _ao_size := Vector2i.ZERO
var _water_file := ""
var _water_size := Vector2i.ZERO
## Loop 10a: the surface map's shore distance (its R channel: a quarter metre per step inside
## water, 0 on dry land), one byte per texel, kept on the CPU for the car's water test
## (`shore_distance`); stored zstd-packed so the prebuilt city carries it too (the export
## leaves water.bin out), unpacked on first use.
@export_storage var _shore_zip := PackedByteArray()
@export_storage var _shore_size := Vector2i.ZERO
var _shore := PackedByteArray()
var _light_image: Image
## Lamps the light bake added where OpenStreetMap maps none (the bridges): x, z, yaw.
var _extra_lamps := PackedFloat32Array()
var _lod2_footprints: Array = []
## Loop 3c: stored, so the prebuilt index (map/index.res) has the map's rectangle too.
@export_storage var bounds: Rect2
## Map north (2026-10-31): the parts of `bounds` that are not map (centrum.json `outside`; today
## the north-east corner, east of the extension to Rondo Radosława and Arkadia). Each holds a
## corner of `bounds` (tools/map_shape.py, the bakes' twin of in_map, map_outline, clip_to_map).
@export_storage var outside: Array[Rect2] = []
var _wall_faces := PackedVector3Array()

## Terrain heights in metres relative to the bake's base height; empty means a flat world.
@export_storage var _terrain: Dictionary = {}
@export_storage var _t_h := PackedFloat32Array()
## While the flat layers are built, triangles are subdivided and laid onto the
## ground. The value is the depth bias (metres towards the camera) that keeps a
## layer above the one under it; -1 means "not draping".
var _drape_bias := -1.0
## Ground-shader layer id written to UV.y (see ground.gdshader) and the second UV:
## along/across metres for paths and roads (paving runs with the street), the
## building style seed and wall top for facades.
var _layer := 0.0
var _axis := Vector2.ZERO
var _uv2 := Vector2.ZERO
## Bridge decks (tools/bake_roads.py): pieces with a height every few metres, one per
## bridge road, footway, tram track or railway, in groups (one structure each). Each
## piece: pts, cum (metres along), h, l/r (corridor left/right of its line), g (group),
## k (road, path, tram, rail), o (per point: 1 = left side outer, 2 = right side outer),
## box (bounds, for quick rejection).
@export_storage var _decks: Array[Dictionary] = []
## Loop 3d-1: per deck piece, 1 if its start meets another piece's end of the same deck, 2 its
## end (a joint: _decks_at lets a point DECK_JOINT_SLACK past it count); made with the cells.
var _deck_joints := PackedByteArray()
const DECK_JOINT_SLACK := 1.5
## Loop 3a (R1): the approaches of the bridges (tools/bake_roads.py `fills`: abutments,
## embankments, the ways onto a bridge where the 10 m terrain grid blurs the abutment into a
## slope): pieces like the decks' (pts, cum, h, l, r) that correct the ground under their
## corridor, so the road, its markings, the lanes and the car there sit on the solved
## profile instead of the blur. `terrain_height` includes them; the ground mesh does not.
@export_storage var _fills: Array[Dictionary] = []
## Fill segments per FILL_CELL cell (cell key -> piece << 12 | segment), built on load.
@export_storage var _fill_cells := {}
## Loop 3b: the aprons (tools/bake_structures.py `aprons`: where a deck's or tunnel's end meets
## the ground, the ground blends from the end's flat height to the terrain): per apron x0, z0,
## the unit direction, the length, the end's height, left and right reach, the inside part's
## length; and per cell.
@export_storage var _aprons: Array[PackedFloat32Array] = []
## An apron (of a map baked without `i`) starts this far inside the structure's end (the ground
## held under it there).
const APRON_IN := 4.0
## Map round 2 (D5): an apron fades out over this past its corridor's sides.
const APRON_TAPER := 3.0
@export_storage var _apron_cells := {}
const FILL_CELL := 16.0
## Loop 3a (R4): tunnel pieces (tools/bake_roads.py `tunnels`): pts, h, g (one tunnel each).
## Only their heights are used so far (the lane graph's tunnel edges); loop 3b builds them.
@export_storage var _tunnels: Array[Dictionary] = []
## While a flat layer is built: the deck group it lies on (-1: the terrain).
var _dk := -1
## Loop 3b: ...or the tunnel it lies in (-1: none).
var _tn := -1
var _has_lod2 := false
## Building tops on a grid of ROOF_CELL squares (NO_ROOF in the open), so the
## helicopter can treat buildings as solid without a physics query per frame.
const ROOF_CELL := 4.0
const NO_ROOF := -1000.0
@export_storage var _roof := PackedFloat32Array()
@export_storage var _roof_x0 := 0.0
@export_storage var _roof_z0 := 0.0
@export_storage var _roof_nx := 0
@export_storage var _roof_nz := 0
## v0.8 landmarks (landmarks.gd): what each one's info card says, and which landmark
## (1-based, 0 for none) covers each roof-grid cell, for tapping.
@export_storage var landmark_info: Array[Dictionary] = []
@export_storage var _pick := PackedByteArray()
## The loading fix (2026-10-31): what colour tops each roof-grid cell, for the proxies
## (sector_proxies.gd), from the same buildings the sectors are built from: the roof's colour where
## a roof gives the cell its height (RGBA8, 0 for none), and the colour of a wall standing in it.
## Recorded only while `proxy_colours` is on (tools/bake_city.gd, or the runtime path when it makes
## the proxies itself): not saved, not in the exported game.
var proxy_colours := false
var roof_rgba := PackedInt32Array()
var wall_rgba := PackedInt32Array()
var _scratch_rgba := PackedInt32Array()
var _scratch_wall := PackedInt32Array()

# --- Loop 3c: sectors -------------------------------------------------------------------
## The city in 512 m sectors (docs/DEMO.md 2.4): tools/bake_sectors.py splits the map data
## into map/index.json (the whole map's: lane graph, decks, tunnels, points of interest...)
## and map/sectors/<i>_<j>.json (each sector's features, a border-crossing one in both);
## `build_sector` builds one sector from its file and keeps only the triangles, instances
## and collider faces whose centre lies in it, so the sectors together are what `build`
## makes in one go (tools/check_streaming.gd compares them). sector_streamer.gd loads them.
const SECTOR := 512.0
const SECTOR_DIR := "res://map/sectors/"
## The split's margin (tools/bake_sectors.py MARGIN): a sector's file holds what lies this
## close to it, so what it builds may reach this far (the landmarks and bridges it builds).
const SECTOR_MARGIN := 48.0
## The game's data for the whole map (index.json: what traffic, missions, the minimap read),
## kept in the prebuilt index (map/index.res) so the exported game needs no JSON.
@export_storage var index_data: Dictionary = {}
## Per sector key: Vector2(lowest ground - 15 m, highest roof or treetop), for the streamer's
## view test (a tall tower in a sector off the view's ground can still stand in the view).
@export_storage var sector_heights: Dictionary = {}
## Loop 3d-2b: per sector key, its highest ground (the far level: a sector whose ground and low
## buildings are out of the view, only its towers in it).
@export_storage var sector_ground: Dictionary = {}
## While one sector is built: it, its square, the square grown by the split's margin, its
## 2 x 2 tiles, and the roof grid its buildings mark (merged into _roof for its own cells).
var _in_sector := false
var _sector := Vector2i.ZERO
var _sector_rect := Rect2()
var _near := Rect2()
var _scratch_roof := PackedFloat32Array()
## The node the builder's meshes and bodies go under: this one, or the sector being built.
var _out: Node3D
## Whether a sector's build writes its cells of the roof and picking grids (build_sector).
var _merge := true
## The landmark sites, found once from the index (the streamed city).
var _marks
## The water's edge runs over the whole map, found once (the streamed city): [poly, side, kind, box].
var _global_shore: Array = []
## The terrain grid's smooth normals, found once.
var _gn := PackedVector3Array()
## Materials and meshes every sector shares (trees, lamps, signals, parked cars, props,
## halos, neon), made once: one per city, never one per sector.
var _shared := {}


func build(path: String, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> Dictionary:
	_out = self
	_setup(JSON.parse_string(FileAccess.get_file_as_string(path)), building_mat, flat_mat)
	# v0.8: the landmarks replace whatever LoD2 or OpenStreetMap lump stood in their place.
	var marks := Landmarks.new(self, data)
	_marks = marks
	landmark_info = marks.info
	_build_parts(marks, false)
	_build_collision()
	_index_raised()
	return data


## Loop 3c: the streamed city's global part (both city paths): what `build` sets up first,
## then what every sector build shares: the landmark sites and their info cards (from the
## index's `site_parts`), the water's edge, the kerbs and islands the car feels, the shared
## materials and meshes, and the walls at the map's edge.
func setup_streamed(index: Dictionary, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> void:
	_out = self
	_setup(index, building_mat, flat_mat)
	index_data = index
	# `areas`: the lawns of the University Library's roof garden (landmarks.gd _find_buw);
	# `platforms`: Powiśle's canopies stand on its platforms (landmarks.gd _find_powisle).
	_marks = Landmarks.new(self, {"landmarks": index.get("landmarks", []), "towers": index.get("towers", []),
			"buildings": index.get("site_parts", []), "areas": index.get("areas", []),
			"platforms": index.get("platforms", [])})
	landmark_info = _marks.info
	_pick.resize(_roof_nx * _roof_nz)
	_pick.fill(0)
	_index_decks()
	_ground_normals()
	_global_shore = _find_shore_lines()
	_index_raised()
	_make_shared()
	_build_edge_walls()
	var edge: Node3D = MapEdge.build(self)
	if edge != null:
		add_child(edge)
	# 2026-11-02: roadworks close every road that leaves the map (edge_roadworks.gd).
	var works: Node3D = EdgeRoadworks.build(self)
	if works != null:
		add_child(works)


## Loop 3c: each sector's lowest ground (- 20 m: tunnels, the river bed) and its highest roof
## or treetop (the terrain + 40 m at least), from the finished roof grid: the streamer loads a
## sector whose box meets the camera's view (sector_streamer.gd).
func measure_sectors() -> void:
	sector_heights.clear()
	sector_ground.clear()
	var step := float(_terrain.get("step", 10.0))
	for k: Array in index_data.get("sectors", {}).get("keys", []):
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := clip_to_map(Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR)))
		var lo := INF
		var hi := -INF
		var z := rect.position.y
		while z <= rect.end.y:
			var x := rect.position.x
			while x <= rect.end.x:
				var g := _grid_height(x, z)
				lo = minf(lo, g)
				hi = maxf(hi, g)
				x += step
			z += step
		var top := hi + 40.0
		var i0 := clampi(floori((rect.position.x - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
		var i1 := clampi(floori((rect.end.x - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
		var j0 := clampi(floori((rect.position.y - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
		var j1 := clampi(floori((rect.end.y - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				top = maxf(top, _roof[j * _roof_nx + i])
		sector_heights[key] = Vector2((lo if lo < INF else 0.0) - 20.0, top + 2.0)
		sector_ground[key] = hi if hi > -INF else 0.0


## Loop 3c: the key of the sector holding a point.
static func sector_of(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / SECTOR), floori(z / SECTOR))


# --- Map north (2026-10-31): the map's shape, `bounds` without its `outside` corners ---------

## An outside part as the map grown by d metres sees it: its sides on the bounds move out with
## them, its inner sides in (tools/map_shape.py Shape.grow).
func _outside_grown(o: Rect2, d: float) -> Rect2:
	var x0 := o.position.x - d if o.position.x <= bounds.position.x else o.position.x + d
	var z0 := o.position.y - d if o.position.y <= bounds.position.y else o.position.y + d
	var x1 := o.end.x + d if o.end.x >= bounds.end.x else o.end.x - d
	var z1 := o.end.y + d if o.end.y >= bounds.end.y else o.end.y - d
	return Rect2(x0, z0, x1 - x0, z1 - z0)


## Map north: whether p lies on the map grown by `pad` metres (shrunk for pad < 0): inside the
## bounds and in no outside part.
func in_map(p: Vector2, pad := 0.0) -> bool:
	if not bounds.grow(pad).has_point(p):
		return false
	for o in outside:
		var g := _outside_grown(o, pad)
		if p.x > g.position.x and p.x < g.end.x and p.y > g.position.y and p.y < g.end.y:
			return false
	return true


## Map north: the map's outline grown by `pad`: the bounds' corners clockwise from the north-west
## (+z south), each corner an outside part holds replaced by the part's inner corner and the two
## points where its sides meet the bounds (six points with the north extension).
func map_outline(pad := 0.0) -> PackedVector2Array:
	var r := bounds.grow(pad)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var out := PackedVector2Array()
	for k in 4:
		var c: Vector2 = corners[k]
		var notch := Rect2()
		var found := false
		for o in outside:
			var g := _outside_grown(o, pad)
			if c.x >= g.position.x - 0.01 and c.x <= g.end.x + 0.01 and c.y >= g.position.y - 0.01 and c.y <= g.end.y + 0.01:
				notch = g
				found = true
		if not found:
			out.append(c)
			continue
		var ix := notch.end.x if is_equal_approx(c.x, r.position.x) else notch.position.x
		var iz := notch.end.y if is_equal_approx(c.y, r.position.y) else notch.position.y
		var prev: Vector2 = corners[(k + 3) % 4]
		var nxt: Vector2 = corners[(k + 1) % 4]
		out.append(Vector2(ix, c.y) if is_equal_approx(prev.y, c.y) else Vector2(c.x, iz))
		out.append(Vector2(ix, iz))
		out.append(Vector2(ix, c.y) if is_equal_approx(nxt.y, c.y) else Vector2(c.x, iz))
	return out


## Map north: rect cut to the map: to the bounds, then by any outside part that spans it whole
## in one direction (one that only bites a corner of it leaves it as it is).
func clip_to_map(rect: Rect2) -> Rect2:
	var r := rect.intersection(bounds)
	for o in outside:
		if not r.intersects(o):
			continue
		if o.position.y <= r.position.y and o.end.y >= r.end.y:
			if o.position.x <= r.position.x and o.end.x >= r.end.x:
				return Rect2(r.position, Vector2.ZERO)
			if o.position.x <= r.position.x:
				r = Rect2(o.end.x, r.position.y, r.end.x - o.end.x, r.size.y)
			elif o.end.x >= r.end.x:
				r = Rect2(r.position.x, r.position.y, o.position.x - r.position.x, r.size.y)
		elif o.position.x <= r.position.x and o.end.x >= r.end.x:
			if o.position.y <= r.position.y:
				r = Rect2(r.position.x, o.end.y, r.size.x, r.end.y - o.end.y)
			elif o.end.y >= r.end.y:
				r = Rect2(r.position.x, r.position.y, r.size.x, o.position.y - r.position.y)
	return r


## Map north: whether the 10 m ground cell [x, x + step] x [z, z + step] lies wholly in an outside
## part (no ground there; a cell across the outline is drawn, as on the box's own edges).
func _cell_outside(x: float, z: float, step: float) -> bool:
	for o in outside:
		var g := o.grow(0.01)
		# A side on the bounds runs on past them (the grid's last row reaches past the map's edge).
		var x0 := -INF if o.position.x <= bounds.position.x + 0.05 else g.position.x
		var z0 := -INF if o.position.y <= bounds.position.y + 0.05 else g.position.y
		var x1 := INF if o.end.x >= bounds.end.x - 0.05 else g.end.x
		var z1 := INF if o.end.y >= bounds.end.y - 0.05 else g.end.y
		if x >= x0 and x + step <= x1 and z >= z0 and z + step <= z1:
			return true
	return false


static func sector_name(key: Vector2i) -> String:
	return "s_%d_%d" % [key.x, key.y]


## Loop 3c: one sector from map/sectors/<i>_<j>.json, under a new node (not in the tree):
## ground, roads and markings, buildings and the landmarks' parts in it, trees, lamps,
## signals, parked cars and props, and its colliders. Its cells of the roof and picking grids
## go into the map's. Needs `setup_streamed`. `roofs_only`: no nodes, only those cells (the
## runtime path's pass over the whole map, which missions, eggs and the helicopter read).
## `merge` false leaves the map's grids alone (a sector built on a worker thread after that
## pass: the grids are complete, and the main thread reads them meanwhile).
func build_sector(key: Vector2i, roofs_only := false, merge := true) -> Node3D:
	var root := Node3D.new()
	root.name = sector_name(key)
	var path := SECTOR_DIR + "%d_%d.json" % [key.x, key.y]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		push_error("map: no sector file %s (run tools/bake_sectors.py)" % path)
		return root
	var whole := data
	data = parsed
	_out = root
	_in_sector = true
	_sector = key
	_sector_rect = Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR))
	# What the sector's file reaches (tools/bake_sectors.py: its buildings' surroundings, for
	# their shop signs): the landmarks and the water's edge in it are built too.
	var ctx: Array = data.get("context", [])
	_near = Rect2(ctx[0], ctx[1], ctx[2] - ctx[0], ctx[3] - ctx[1]) if ctx.size() == 4 else _sector_rect.grow(SECTOR_MARGIN)
	_wall_faces.clear()
	_scratch_roof.resize(_roof.size())
	_scratch_roof.fill(NO_ROOF)
	if proxy_colours:
		_open_colours()
		_scratch_rgba.resize(_roof.size())
		_scratch_rgba.fill(0)
		_scratch_wall.resize(_roof.size())
		_scratch_wall.fill(0)
	_merge = merge
	_build_parts(_marks, roofs_only)
	if not roofs_only:
		_build_collision()
		# Loop 3d-2b: the sector's slices of the baked maps travel with it (saved in its scene).
		var slices := map_slices(key)
		if not slices.is_empty():
			root.set_meta("map_slices", slices)
	if merge:
		_merge_roofs()
	_merge = true
	_wall_faces.clear()
	data = whole
	_out = self
	_in_sector = false
	return root


## Loop 3c: everything but the colliders, in build order (one sector or the whole map).
func _build_parts(marks, roofs_only: bool) -> void:
	if solo_site != "":
		# Landmarks 0.3: one site's triangles and nothing else (`marks.build`'s `only`).
		var solo_walls := _new_surface()
		solo_walls.none = roofs_only
		marks.build(solo_walls, _near if _in_sector else Rect2(), solo_site)
		if not roofs_only:
			_add_mesh(solo_walls, building_material, true)
		return
	if not roofs_only:
		var flat := _new_surface()
		# Loop 3d-2a: the ground is built last, so it can leave out what the flat layers on it
		# cover whole (`_cover_on`: they note their outlines while they are laid).
		_cover_reset()
		# Wide gaps between the depth biases: two layers that fit a slope with different
		# triangles can differ by a few centimetres, and must not poke through each other.
		# Loop 3b-2: the areas lie exactly on the ground's own triangles (_fill_on_grid), so their
		# few millimetres of height order them over the ground and each other without a depth bias
		# to speak of (0.05 before); the thin strips laid over them (paths at 0.1) keep a margin for
		# their pieces' sag over the grid's folds (game/tools/check_drape.gd counts it).
		_drape_bias = 0.01
		_cover_on = true
		_build_areas(flat)
		_build_cut_banks(flat)
		_cover_on = false
		# The sandbars over the water (fill 0.02, rim 0.07, foam 0.09) and the natural banks' wet
		# bands and foam (0.07, 0.09), under the paving and the paths.
		_drape_bias = 0.02
		_build_sandbars(flat)
		_drape_bias = 0.07
		_build_banks(flat)
		_cover_on = true
		_drape_bias = 0.08
		_build_surfaces(flat)
		_drape_bias = 0.1
		_build_paths(flat)
		_build_steps(flat)
		# The cutting's floor under the tracks' gravel shoulders (0.18): it had their bias, the
		# same layer at the same height, and the two greys z-fought (F's phone videos, 2026-11-07).
		_drape_bias = 0.16
		_build_cut_floor(flat)
		_drape_bias = 0.2
		_build_rail_beds(flat)
		_drape_bias = 0.3
		_build_roads(flat)
		_build_tunnel_roads(flat)
		_build_carriageways(flat)
		_cover_on = false
		_drape_bias = 0.34
		_build_islands(flat)
		_build_medians(flat)
		# Smooth roads loop 7: the sleepers over the tram bed, the crossings over them, and the
		# cycle crossings (0.36) and kerbs over both.
		_drape_bias = 0.35
		_build_tram_sleepers(flat)
		_drape_bias = 0.355
		_build_tram_crossings(flat)
		_drape_bias = 0.357
		_build_tram_noses(flat)
		_drape_bias = 0.36
		_build_kerbs(flat)
		_build_shore_stone(flat)
		_drape_bias = 0.38
		_build_markings(flat)
		_build_symbols(flat)
		_build_crossings(flat)
		_build_tactile(flat)
		_drape_bias = 0.46
		_build_trams(flat)
		_build_rails(flat)
		_drape_bias = -1.0
		_dk = -1
		_build_ground(flat)
		_cover_reset()
		_add_mesh(flat, flat_material, false)

	var walls := _new_surface()
	walls.none = roofs_only
	var keep := _build_lod2(walls, marks)
	var t_parts := Time.get_ticks_msec()
	_build_buildings(walls, keep, marks)
	if not _in_sector:
		print("buildings: %d floating parts: %d lowered (%d to the ground), %d tiny left out · %d ms" % [floating_parts,
				floating_parts - floating_dropped, floating_to_ground, floating_dropped, Time.get_ticks_msec() - t_parts])
	marks.build(walls, _near if _in_sector else Rect2())
	if not _in_sector:
		_pick = marks.pick_grid()
	elif _merge:
		_merge_pick(marks.pick_grid())
	if roofs_only:
		return
	_build_platforms(walls)
	_build_barriers(walls)
	_build_stair_flights(walls)
	_build_city_walls(walls)
	_build_bridge_structures(walls)
	_build_walls(walls)
	_build_portals(walls)
	_build_rail_portals(walls)
	_build_cutting(walls)
	_build_yard_platforms(walls)
	_build_footbridge_stairs(walls)
	_build_station_furniture(walls)
	_build_catenary(walls)
	_build_srednicowy(walls)
	_build_poniatowski(walls)
	_build_powisle(walls)
	_build_garage_doors(walls)
	_build_guard_rails(walls)
	_build_shore()
	_add_mesh(walls, building_material, true)
	_build_neon(keep, marks)
	_build_landmark_signs(marks)

	_build_trees()
	_build_street_furniture()
	_build_props()
	_bridge_pockets(keep, marks)


## Loop 3c: a chunked surface keeping only the sector's tiles while one is built.
func _new_surface() -> Chunked:
	var st := Chunked.new()
	if _in_sector:
		st.only = Rect2i(_sector * 2, Vector2i(2, 2))
	return st


## Loop 3c: the sector's own cells (their centres in it) of the roof grid its build marked.
func _merge_roofs() -> void:
	var r := _cell_range()
	for j in range(r.position.y, r.end.y):
		for i in range(r.position.x, r.end.x):
			var k := j * _roof_nx + i
			if _scratch_roof[k] > _roof[k]:
				_roof[k] = _scratch_roof[k]
			if proxy_colours:
				if _scratch_rgba[k] != 0:
					roof_rgba[k] = _scratch_rgba[k]
				if _scratch_wall[k] != 0:
					wall_rgba[k] = _scratch_wall[k]


## Loop 3c: the sector's own cells of the landmarks' picking grid.
func _merge_pick(grid: PackedByteArray) -> void:
	var r := _cell_range()
	for j in range(r.position.y, r.end.y):
		for i in range(r.position.x, r.end.x):
			var k := j * _roof_nx + i
			_pick[k] = grid[k]


## Loop 3c: the roof-grid cells whose centres lie in the sector being built (i, j from, to).
func _cell_range() -> Rect2i:
	var i0 := clampi(ceili((_sector_rect.position.x - _roof_x0) / ROOF_CELL - 0.5), 0, _roof_nx)
	var i1 := clampi(ceili((_sector_rect.end.x - _roof_x0) / ROOF_CELL - 0.5), 0, _roof_nx)
	var j0 := clampi(ceili((_sector_rect.position.y - _roof_z0) / ROOF_CELL - 0.5), 0, _roof_nz)
	var j1 := clampi(ceili((_sector_rect.end.y - _roof_z0) / ROOF_CELL - 0.5), 0, _roof_nz)
	return Rect2i(i0, j0, i1 - i0, j1 - j0)


## Loop 3c: whether a triangle (or a piece) can have its centre in the sector being built
## (its box meets the sector): the drape skips the rest before the costly height lookups.
func _touches(a: Vector3, b: Vector3, c: Vector3, pad := 0.01) -> bool:
	var r := _sector_rect
	return maxf(a.x, maxf(b.x, c.x)) >= r.position.x - pad and minf(a.x, minf(b.x, c.x)) <= r.end.x + pad \
			and maxf(a.z, maxf(b.z, c.z)) >= r.position.y - pad and minf(a.z, minf(b.z, c.z)) <= r.end.y + pad


## Loop 3c: the bounds, roof grid, surface maps, terrain, approaches, aprons, decks and
## tunnels from a map's data (the whole map's, or the index's).
func _setup(d: Dictionary, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> void:
	building_material = building_mat
	flat_material = flat_mat
	data = d
	var b: Array = data["bounds"]
	bounds = Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
	outside.clear()
	for o: Array in data.get("outside", []):
		outside.append(Rect2(o[0], o[1], float(o[2]) - float(o[0]), float(o[3]) - float(o[1])))
	_roof_x0 = bounds.position.x
	_roof_z0 = bounds.position.y
	# Map north: the 4 m roof grid keeps the box's own cells (its lines through the box's north-west
	# corner, which an outside part's inner edge marks): grown from the extension's edge, every
	# cell of the box moved 1.8 m and the helicopter's heights, the roof rescues and the landmarks'
	# tap cells with it (check_landmarks: the Presidential Palace's tallest cell lost its tap).
	for o in outside:
		if o.position.y <= bounds.position.y + 0.05 and o.end.y < bounds.end.y:
			_roof_z0 = o.end.y - ceilf((o.end.y - bounds.position.y) / ROOF_CELL - 1e-4) * ROOF_CELL
		if o.position.x <= bounds.position.x + 0.05 and o.end.x < bounds.end.x:
			_roof_x0 = o.end.x - ceilf((o.end.x - bounds.position.x) / ROOF_CELL - 1e-4) * ROOF_CELL
	_roof_nx = ceili((bounds.end.x - _roof_x0) / ROOF_CELL)
	_roof_nz = ceili((bounds.end.y - _roof_z0) / ROOF_CELL)
	_roof.resize(_roof_nx * _roof_nz)
	_roof.fill(NO_ROOF)
	map_grids.clear()
	_load_ao()
	_load_water()
	_load_lights()
	_set_floodlit(building_material)
	if FileAccess.file_exists("res://map/terrain.json"):
		_terrain = JSON.parse_string(FileAccess.get_file_as_string("res://map/terrain.json"))
		_t_h = PackedFloat32Array(_terrain["h"])

	_load_fills()
	_load_sunken()
	_load_cut()
	_load_aprons()
	_load_decks()
	_index_cut_decks()
	_load_tunnels()


func _add_mesh(st, material: Material, shadows: bool) -> void:
	for mesh in st.meshes():
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_out.add_child(mi)


## The baked occlusion map (tools/bake_ao.py): red the buildings' shade (the occlusion ghost
## lifts it), green the parked cars' and trees'. Loop 3d-2b: kept as an image for the sectors'
## slices (map_slices); the ground shader reads them per sector (city_maps.gdshaderinc).
func _load_ao() -> void:
	if not FileAccess.file_exists("res://map/ao.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/ao.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	# Loop 1: two bytes per metre (the buildings' shade, then the parked cars' and trees').
	if bytes.size() < 20 + w * h * 2:
		push_error("map: ao.bin is a one-byte map (re-run tools/bake_ao.py)")
		return
	_ao_file = "res://map/ao.bin"
	_ao_size = Vector2i(w, h)
	map_grids["fine"] = Vector4(x0, z0, px, 0.0)


## The surface map (tools/bake_water.py): RGBA per 2 m. Loop 3d-2b: kept as an image for the
## sectors' slices; the ground shader and the post pass read them per sector.
func _load_water() -> void:
	if not FileAccess.file_exists("res://map/water.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/water.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	var image := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes.slice(20, 20 + w * h * 4))
	_water_file = "res://map/water.bin"
	_water_size = Vector2i(w, h)
	water_rect = Vector4(x0, z0, w * px, h * px)
	map_grids["surface"] = Vector4(x0, z0, px, 0.0)
	# Loop 10a: the R channel alone, for the car's water test (the convert keeps red).
	var red := image.duplicate() as Image
	red.convert(Image.FORMAT_R8)
	_shore = red.get_data()
	_shore_size = Vector2i(w, h)
	_shore_zip = _shore.compress(FileAccess.COMPRESSION_ZSTD)


## The baked street-lamp pools (tools/bake_lights.py): two bytes per metre, sodium
## and LED. Kept as an image: each lamp's head glows in its pool's colour, and (loop 3d-2b)
## the sectors' slices come from it. Its grid is the AO map's.
func _load_lights() -> void:
	if not FileAccess.file_exists("res://map/lights.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/lights.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	var end := 20 + w * h * 2
	_light_image = Image.create_from_data(w, h, false, Image.FORMAT_RG8, bytes.slice(20, end))
	light_rect = Vector4(x0, z0, w * px, h * px)
	if map_grids.has("fine") and not Vector4(x0, z0, px, 0.0).is_equal_approx(map_grids["fine"]):
		push_error("map: lights.bin's grid differs from ao.bin's (one slice grid for both: re-run tools/bake_lights.py)")
	if bytes.size() >= end + 4:
		var n := bytes.decode_u32(end)
		_extra_lamps = bytes.slice(end + 4, end + 4 + n * 12).to_float32_array()


## Loop 3d-2b: a sector's slices of the AO, lamp-light and surface maps ([ao, light, surface],
## city_maps.gd cut), or [] when the whole maps aren't loaded (the prebuilt index: its sectors
## carry their slices).
func map_slices(key: Vector2i) -> Array:
	if _ao_file == "" or _light_image == null or _water_file == "":
		return []
	var fine: Vector4 = map_grids["fine"]
	var ao := _slice_from_file(_ao_file, _ao_size, 2, Image.FORMAT_RG8, fine, key)
	var water := _slice_from_file(_water_file, _water_size, 4, Image.FORMAT_RGBA8, map_grids["surface"], key)
	if ao == null or water == null:
		return []
	return [ao, CityMaps.cut(_light_image, fine, key), water]


## Loop 3d-2b: a sector's slice of a baked map file (20-byte header, then `bpp` bytes a texel, row
## by row): only the rows and columns the slice reaches inside the map are read, then cut as from
## the whole image (city_maps.gd cut, the map's edge repeated past it).
func _slice_from_file(path: String, size: Vector2i, bpp: int, format: Image.Format, grid: Vector4, key: Vector2i) -> Image:
	var n := CityMaps.slice_texels(grid.z)
	var tx := CityMaps.slice_start(key.x * SECTOR, grid.x, grid.z)
	var tz := CityMaps.slice_start(key.y * SECTOR, grid.y, grid.z)
	var x0 := clampi(tx, 0, size.x - 1)
	var x1 := clampi(tx + n, x0 + 1, size.x)
	var z0 := clampi(tz, 0, size.y - 1)
	var z1 := clampi(tz + n, z0 + 1, size.y)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data := PackedByteArray()
	for z in range(z0, z1):
		f.seek(20 + (z * size.x + x0) * bpp)
		data.append_array(f.get_buffer((x1 - x0) * bpp))
	var part := Image.create_from_data(x1 - x0, z1 - z0, false, format, data)
	# The part as if it were the whole map: its grid starts at its first texel.
	return CityMaps.cut(part, Vector4(grid.x + x0 * grid.z, grid.y + z0 * grid.z, grid.z, 0.0), key)


## Loop 3d-2b: the slices on the GPU for `keys` (every sector of the whole city when `all`, for
## --monolithic), the arrays sized for `count` sectors (city_maps.gd).
func open_maps(keys: Array[Vector2i], count: int) -> void:
	city_maps = CityMaps.new()
	city_maps.setup(keys, map_grids.get("fine", Vector4(0, 0, 1, 0)), map_grids.get("surface", Vector4(0, 0, 2, 0)), count)


## Loop 3d-2b, --monolithic: the whole city's sectors' slices all on the GPU at once.
func open_maps_whole() -> void:
	var keys: Array[Vector2i] = []
	var a := sector_of(bounds.position.x - SECTOR_MARGIN, bounds.position.y - SECTOR_MARGIN)
	var b := sector_of(bounds.end.x + SECTOR_MARGIN, bounds.end.y + SECTOR_MARGIN)
	for j in range(a.y, b.y + 1):
		for i in range(a.x, b.x + 1):
			keys.append(Vector2i(i, j))
	open_maps(keys, keys.size())
	for key in keys:
		city_maps.attach(key, map_slices(key))
		city_maps.show(key)


## Sodium (true) or LED (false) light at a point of the light map.
func _sodium_at(x: float, z: float) -> bool:
	if _light_image == null:
		return true
	var i := clampi(int((x - light_rect.x) / light_rect.z * _light_image.get_width()), 0, _light_image.get_width() - 1)
	var j := clampi(int((z - light_rect.y) / light_rect.w * _light_image.get_height()), 0, _light_image.get_height() - 1)
	var c := _light_image.get_pixel(i, j)
	return c.r >= c.g


## The Palace of Culture's floodlights: its centre and reach, from its outline.
func _set_floodlit(material: Material) -> void:
	if not (material is ShaderMaterial):
		return
	for l in data.get("landmarks", []):
		if l["name"] != "Pałac Kultury i Nauki":
			continue
		var pts := _pts(l["p"])
		var centre := Vector2.ZERO
		for q in pts:
			centre += q
		centre /= maxf(pts.size(), 1)
		var reach := 0.0
		for q in pts:
			reach = maxf(reach, q.distance_to(centre))
		(material as ShaderMaterial).set_shader_parameter("floodlit", Vector4(centre.x, centre.y, reach + 12.0, 0.0))
		return

# --- heights ------------------------------------------------------------------

func terrain_height(x: float, z: float) -> float:
	var h := _fill_height(x, z)
	if _apron_cells.is_empty():
		return h
	# Loop 3b: an apron where a structure's end meets the ground: under its last APRON_IN metres
	# the ground is held under the end's height, then it blends from that height (flat across,
	# as the deck or tunnel is) to the terrain.
	var list: PackedInt32Array = _apron_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	for k in list:
		var a: PackedFloat32Array = _aprons[k]
		var along := (x - a[0]) * a[2] + (z - a[1]) * a[3]
		var lat := (z - a[1]) * a[2] - (x - a[0]) * a[3]
		# Map round 2 (D5): past the corridor's sides the apron fades out over APRON_TAPER (it
		# stopped at a 0.65 m step inside a carriageway wider than the deck at the viaduct's west
		# end; the drawn ground follows a slope, not a step).
		var out := maxf(-a[6] - lat, lat - a[7])
		if along >= 0.0 and along <= a[4] and out < APRON_TAPER:
			var target := minf(h, a[5]) if along < a[8] else lerpf(a[5], h, (along - a[8]) / (a[4] - a[8]))
			h = target if out <= 0.0 else lerpf(target, h, out / APRON_TAPER)
	return h


## The grid raised to any approach whose corridor holds the point (terrain_height before the
## aprons), then the railway cutting's floor and banks (`_cut`, rail_cut.gd): the floor never
## rises over the ground; a bank or its shoulder replaces the grid unless an approach raised it.
func _fill_height(x: float, z: float) -> float:
	var h := _fill_height_base(x, z)
	if not _cut.box.has_point(Vector2(x, z)):
		return h
	# Under an island platform (rail_yard.gd) the ground is the tracks' bed: the 10 m grid keeps
	# the old platforms as a blurred 0.5-0.8 m rise, which the new slab sits on, not in.
	var yb := _yard.base_at(Vector2(x, z))
	if not is_nan(yb):
		return minf(h, yb)
	# A bridge over the cut lands on its rims: no bank cut into the ground at a deck's end (the
	# apron's corridor, from 3 m under the deck on), or the car drops off it (check_drive).
	if _near_apron(x, z):
		return h
	var land := _landing_blend(x, z)
	if land <= 0.0:
		return h
	var g := _grid_height(x, z)
	var c: Vector3 = _cut.at(x, z, g)
	if c.y < 0.5:
		return h
	if land < 1.0:
		# Blending out of a landing's ring: no step at its edge (check_drape).
		c.x = lerpf(h, c.x, land)
	if c.y < 1.5:
		# Within half a metre of the grid the floor is left to it (the areas laid on the grid's
		# own triangles poked under a shallow cut's edge: check_drape).
		return h if g - c.x < 0.5 else minf(h, c.x)
	if h > g + 0.05:
		return h
	# By a bridge over the cut the bank never digs under the grid: its abutment stands on the
	# rim (Grójecka's viaduct by Ochota: the lanes ran off the deck end onto the bank).
	if c.x < g and _by_cut_deck(x, z):
		return g
	return c.x


## Deck segments over the cut box by 16 m cell (_index_cut_decks, after the decks load).
var _cut_deck_cells := {}
const CUT_DECK_REACH := 7.0


func _index_cut_decks() -> void:
	_cut_deck_cells.clear()
	_cut_landings.clear()
	var box: Rect2 = _cut.box.grow(20.0)
	for d: Dictionary in _decks:
		if not box.intersects(d["box"]):
			continue
		var pts: PackedVector2Array = d["pts"]
		var w := maxf(float(d["l"]), float(d["r"])) + CUT_DECK_REACH
		var hs: PackedFloat32Array = d["h"]
		for k: int in [0, pts.size() - 1]:
			if hs.size() == pts.size() and absf(hs[k] - _grid_height(pts[k].x, pts[k].y)) < 2.0:
				_cut_landings.append(Vector3(pts[k].x, pts[k].y, maxf(float(d["l"]), float(d["r"])) + 4.0))
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var lo := a.min(b) - Vector2.ONE * w
			var hi := a.max(b) + Vector2.ONE * w
			for cz in range(floori(lo.y / 16.0), floori(hi.y / 16.0) + 1):
				for cx in range(floori(lo.x / 16.0), floori(hi.x / 16.0) + 1):
					var list: PackedVector3Array = _cut_deck_cells.get(Vector2i(cx, cz), PackedVector3Array())
					list.append_array(PackedVector3Array([Vector3(a.x, a.y, w), Vector3(b.x, b.y, w)]))
					_cut_deck_cells[Vector2i(cx, cz)] = list


## Where a deck over the cut box lands on the ground (an end within 2 m of the grid): the ground
## round it keeps its height, cut or not (the car rolls off the deck there).
var _cut_landings := PackedVector3Array()


## 0 within a landing's ring, rising to 1 over LANDING_BLEND past it.
const LANDING_BLEND := 6.0


func _landing_blend(x: float, z: float) -> float:
	var t := 1.0
	for e in _cut_landings:
		var r := e.z + LANDING_BLEND
		if absf(x - e.x) < r and absf(z - e.y) < r:
			t = minf(t, clampf((Vector2(x - e.x, z - e.y).length() - e.z) / LANDING_BLEND, 0.0, 1.0))
	return t


func _by_cut_deck(x: float, z: float) -> bool:
	var list: PackedVector3Array = _cut_deck_cells.get(Vector2i(floori(x / 16.0), floori(z / 16.0)), PackedVector3Array())
	var p := Vector2(x, z)
	for k in range(0, list.size(), 2):
		var a := Vector2(list[k].x, list[k].y)
		var b := Vector2(list[k + 1].x, list[k + 1].y)
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < list[k].z:
			return true
	return false


func _near_apron(x: float, z: float) -> bool:
	if _apron_cells.is_empty():
		return false
	var list: PackedInt32Array = _apron_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	for k in list:
		var a: PackedFloat32Array = _aprons[k]
		var along := (x - a[0]) * a[2] + (z - a[1]) * a[3]
		var lat := (z - a[1]) * a[2] - (x - a[0]) * a[3]
		if along >= -3.0 and along <= a[4] and lat >= -a[6] - 1.0 and lat <= a[7] + 1.0:
			return true
	return false


func _fill_height_base(x: float, z: float) -> float:
	var h := _grid_height(x, z)
	_set_hit = false
	# A sunken place's floor (SUNKEN) wins over the grid and the approaches.
	if _sunk_box.has_point(Vector2(x, z)):
		var f := sunk_floor(x, z)
		if f < h:
			return f
	if _fill_cells.is_empty():
		return h
	var codes: PackedInt32Array = _fill_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	if codes.is_empty():
		return h
	# Loop 3a: inside an approach's corridor the ground is its profile (never lower).
	# Loop 3e: inside a ground profile's ("s": the 1 m NMT's level of a way by a structure,
	# tools/bake_roads.py `_ground_profiles`) it is that level, up or down: the nearest one's,
	# its corridor with round joins (a disc at each vertex).
	var p := Vector2(x, z)
	var set_h := NAN
	var set_d := INF
	for code in codes:
		var d: Dictionary = _fills[code >> 12]
		var k := code & 4095
		var pts: PackedVector2Array = d["pts"]
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var hs: PackedFloat32Array = d["h"]
		var is_set: bool = d["s"]
		if is_set:
			var w := minf(float(d["l"]), float(d["r"]))
			var da := p.distance_to(a)
			if da <= w and da < set_d:
				set_h = hs[k]
				set_d = da
			var db := p.distance_to(pts[k + 1])
			if db <= w and db < set_d:
				set_h = hs[k + 1]
				set_d = db
		var u := (p - a).dot(ab) / l2
		if (u < 0.0 and k > 0) or (u > 1.0 and k < pts.size() - 2) or u < -0.05 or u > 1.05:
			continue
		var t := clampf(u, 0.0, 1.0)
		var lat := ab.cross(p - a) / sqrt(l2)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			var v := lerpf(hs[k], hs[k + 1], t)
			if is_set:
				if absf(lat) < set_d:
					set_h = v
					set_d = absf(lat)
			else:
				h = maxf(h, v)
	_set_hit = not is_nan(set_h)
	if _set_hit:
		return set_h
	return h


## The GUGiK terrain grid alone (the two triangles per cell `_build_ground` draws).
func _grid_height(x: float, z: float) -> float:
	if _t_h.is_empty():
		return 0.0
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var fx := clampf((x - float(_terrain["x0"])) / step, 0.0, nx - 1.0001)
	var fz := clampf((z - float(_terrain["z0"])) / step, 0.0, nz - 1.0001)
	var i := int(fx)
	var j := int(fz)
	var u := fx - i
	var v := fz - j
	var h00 := _t_h[j * nx + i]
	var h10 := _t_h[j * nx + i + 1]
	var h01 := _t_h[(j + 1) * nx + i]
	var h11 := _t_h[(j + 1) * nx + i + 1]
	# The same two triangles per cell that _build_ground draws.
	if u >= v:
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	return h00 + (h11 - h01) * u + (h01 - h00) * v


## The top surface at a point: the terrain, or the highest bridge deck over it.
func ground_height(x: float, z: float) -> float:
	var h := terrain_height(x, z)
	for d in _decks_at(x, z):
		h = maxf(h, d)
	return h


## Where a vehicle at height `near_y` drives: of the terrain and the decks over the
## point, the highest one it can step onto (a ramp rises gently; a deck 5 m over the
## road stays overhead). The car and the skid marks use it.
func drive_height(x: float, z: float, near_y: float) -> float:
	var best := terrain_height(x, z)
	var on_ground := true
	var feet := []
	var hs := _decks_at(x, z, feet)
	for k in hs.size():
		var d := hs[k]
		# G6: on a ramp's foot (its first DECK_FOOT metres from an end that stands on the ground)
		# a car on the ground beside it climbs on even where that ground lies lower than the
		# slab's step (it came in at an angle, off the approach's fill: it drove under the slab).
		var reach := near_y + 1.2
		if bool(feet[k]) and near_y >= d - DECK_FOOT_UP:
			reach = d
		if d <= reach and d > best:
			best = d
			on_ground = false
	# Loop 3b: in a tunnel's corridor, a vehicle down at its floor drives the floor.
	var t := tunnel_floor(x, z, near_y)
	if not is_nan(t):
		return t
	# Loop 3b-2: on a traffic island or a grass median the car rides KERB_UP higher.
	if on_ground and not _raise_cells.is_empty():
		best += raise_at(x, z)
	return best


## Loop 3b-2: kerbs you feel. The raised ground at street level: traffic islands and grass
## medians (KERB_UP over the road), and the kerb lines (the bake's kerbs and the islands'
## outlines), in RAISE_CELL cells; stored in the scene so the prebuilt city has them too.
## drive_height lifts the car onto an island or a median; the car (car.gd kerb_feel) loses a
## little speed with a bounce when it hops a kerb line and rolls slower on the raised ground.
## Traffic keeps to its lanes (lane_graph heights) and never feels them.
const RAISE_CELL := 8.0
@export_storage var _raise_polys: Array[PackedVector2Array] = []
@export_storage var _raise_cells := {}
@export_storage var _kerb_segs := PackedVector2Array()
@export_storage var _kerb_cells := {}


func _index_raised() -> void:
	_raise_polys.clear()
	_raise_cells.clear()
	_kerb_segs.clear()
	_kerb_cells.clear()
	var raised: Array[PackedVector2Array] = []
	for a in data.get("islands", []):
		if int(a.get("dk", -1)) < 0:
			raised.append(_pts(a["p"]))
	for m in data.get("medians", []):
		if m["k"] != "grass" or int(m.get("dk", -1)) >= 0:
			continue
		var s4: Array = m["s"]
		for i in range(0, s4.size() - 7, 4):
			raised.append(PackedVector2Array([Vector2(s4[i], s4[i + 1]), Vector2(s4[i + 2], s4[i + 3]),
					Vector2(s4[i + 6], s4[i + 7]), Vector2(s4[i + 4], s4[i + 5])]))
	for poly in raised:
		if poly.size() < 3:
			continue
		var id := _raise_polys.size()
		_raise_polys.append(poly)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		for cz in range(floori(box.position.y / RAISE_CELL), floori(box.end.y / RAISE_CELL) + 1):
			for cx in range(floori(box.position.x / RAISE_CELL), floori(box.end.x / RAISE_CELL) + 1):
				var key := Vector2i(cx, cz)
				var list: PackedInt32Array = _raise_cells.get(key, PackedInt32Array())
				list.append(id)
				_raise_cells[key] = list
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		_add_kerb_line(ring)
	for k in data.get("kerbs", []):
		if int(k.get("dk", -1)) < 0:
			_add_kerb_line(_pts(k["p"]))


func _add_kerb_line(poly: PackedVector2Array) -> void:
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		if a.distance_squared_to(b) < 0.0004:
			continue
		var id := _kerb_segs.size() / 2
		_kerb_segs.append(a)
		_kerb_segs.append(b)
		var lo := a.min(b)
		var hi := a.max(b)
		for cz in range(floori(lo.y / RAISE_CELL), floori(hi.y / RAISE_CELL) + 1):
			for cx in range(floori(lo.x / RAISE_CELL), floori(hi.x / RAISE_CELL) + 1):
				var key := Vector2i(cx, cz)
				var list: PackedInt32Array = _kerb_cells.get(key, PackedInt32Array())
				list.append(id)
				_kerb_cells[key] = list


## Loop 3b-2: how far the ground at (x, z) stands over the road at street level: KERB_UP on an
## island or a grass median, else 0.
func raise_at(x: float, z: float) -> float:
	var p := Vector2(x, z)
	for id: int in _raise_cells.get(Vector2i(floori(x / RAISE_CELL), floori(z / RAISE_CELL)), PackedInt32Array()):
		if Geometry2D.is_point_in_polygon(p, _raise_polys[id]):
			return KERB_UP
	return 0.0


## Loop 3b-2: for a car that moved from `from` to `to` at height y: x = the raise under `to`
## (raise_at), y = 1 if the move crossed a kerb line. Nothing on a deck or in a tunnel (the car
## more than a little over or under the street).
func kerb_feel(from: Vector2, to: Vector2, y: float) -> Vector2:
	if _kerb_cells.is_empty() and _raise_cells.is_empty():
		return Vector2.ZERO
	var g := terrain_height(to.x, to.y)
	if y > g + KERB_UP + 0.4 or y < g - 0.4:
		return Vector2.ZERO
	var crossed := 0.0
	var c0 := Vector2i(floori(from.x / RAISE_CELL), floori(from.y / RAISE_CELL))
	var c1 := Vector2i(floori(to.x / RAISE_CELL), floori(to.y / RAISE_CELL))
	for cz in range(mini(c0.y, c1.y), maxi(c0.y, c1.y) + 1):
		for cx in range(mini(c0.x, c1.x), maxi(c0.x, c1.x) + 1):
			for id: int in _kerb_cells.get(Vector2i(cx, cz), PackedInt32Array()):
				if Geometry2D.segment_intersects_segment(from, to, _kerb_segs[id * 2], _kerb_segs[id * 2 + 1]) != null:
					crossed = 1.0
					break
			if crossed > 0.0:
				break
		if crossed > 0.0:
			break
	return Vector2(raise_at(to.x, to.y), crossed)


## Loop 3b: the floor of the tunnel whose corridor holds (x, z), for a vehicle at height
## near_y that is at it (within 1.2 m); NAN otherwise (on the street over a tunnel, the
## street; at the portal the floor meets the open road's height).
func tunnel_floor(x: float, z: float, near_y: float) -> float:
	if _tunnels.is_empty():
		return NAN
	var p := Vector2(x, z)
	for d in _tunnels:
		if not (d["box"] as Rect2).has_point(p):
			continue
		var hit := _deck_hit(d, p)
		if hit.z > 0.0 and near_y <= hit.x + 1.2 and near_y >= hit.x - 1.2:
			return hit.x
	return NAN


## Loop 3b: the floor of a tunnel whose corridor holds (x, z), whatever the height (NAN when
## none): main.gd's --tunnel start.
func tunnel_floor_under(x: float, z: float) -> float:
	for d in _tunnels:
		if (d["box"] as Rect2).has_point(Vector2(x, z)):
			var hit := _deck_hit(d, Vector2(x, z))
			if hit.z > 0.0:
				return hit.x
	return NAN


## Loop 3b: a vehicle at (x, y, z) is inside a tunnel (on its floor, more than 2 m under the
## ground): main.gd shows the car through the ground then (its x-ray).
func in_tunnel(x: float, z: float, y: float) -> bool:
	var t := tunnel_floor(x, z, y)
	return not is_nan(t) and terrain_height(x, z) - t > 2.0


## GAMEPLAY_PLAN 3.5 (0.3): a bridge or viaduct deck stands between the point `at` (the car's
## middle) and the camera, `to_cam` the unit direction up to it (the ortho camera's back axis):
## the ray meets a deck's slab (from UNDER_DECK_SLAB under its road to its parapet's top) between
## UNDER_DECK and UNDER_DECK_TOP m over the point. Trasa Łazienkowska over Łazienkowska and
## Myśliwiecka, Most Łazienkowski's land spans, the Poniatowski viaduct: main.gd shows the car
## through the deck then, as in a tunnel. A car beside a deck, or under one the camera sees past,
## stays drawn as it is. Up to ~18 deck lookups (drive_height does one): main.gd asks every
## DECK_XRAY_EVERY frames.
func deck_hides(at: Vector3, to_cam: Vector3) -> bool:
	if to_cam.y < 0.05 or _decks.is_empty():
		return false
	if _deck_cells.is_empty():
		_index_decks()
	# Most of the map has no deck near: the deck cells along the ray first (4 points, under a
	# cell apart), the costly corridor tests only if one holds a deck.
	var any := false
	for k in 4:
		var q := at + to_cam * (lerpf(UNDER_DECK, UNDER_DECK_TOP, k / 3.0) / to_cam.y)
		if _deck_any.has(Vector2i(floori(q.x / DECK_CELL), floori(q.z / DECK_CELL))):
			any = true
			break
	if not any:
		return false
	var h := UNDER_DECK
	while h <= UNDER_DECK_TOP:
		var p := at + to_cam * (h / to_cam.y)
		var y := at.y + h
		for d in _decks_at(p.x, p.z):
			if y >= d - UNDER_DECK_SLAB and y <= d + 1.0:
				return true
		h += UNDER_DECK_SLAB * 0.75
	return false


## Loop 10a: how far into the water (river, pond or fountain) a point lies, in metres from
## the nearest dry texel, interpolated between the 2 m texels' centres; 0 on dry land and
## off the map. Four byte reads: cheap enough for the car every frame.
func shore_distance(x: float, z: float) -> float:
	if _shore.is_empty():
		if _shore_zip.is_empty():
			return 0.0
		_shore = _shore_zip.decompress(_shore_size.x * _shore_size.y, FileAccess.COMPRESSION_ZSTD)
	var px := water_rect.z / maxf(_shore_size.x, 1)
	var fx := (x - water_rect.x) / px - 0.5
	var fz := (z - water_rect.y) / px - 0.5
	var i := floori(fx)
	var j := floori(fz)
	if i < 0 or j < 0 or i >= _shore_size.x - 1 or j >= _shore_size.y - 1:
		return 0.0
	var k := j * _shore_size.x + i
	var u := fx - i
	var near := lerpf(_shore[k], _shore[k + 1], u)
	var far := lerpf(_shore[k + _shore_size.x], _shore[k + _shore_size.x + 1], u)
	return lerpf(near, far, fz - j) * 0.25


## Loop 10a: how far past the water's edge a vehicle's centre must be to count as in the water
## (metres, from shore_distance). The first water texel's centre lies 0-2 m past the mapped
## edge, so this is ~1-2.5 m in: a car stopped by the shore edge (its centre a metre or two
## inland) never counts, a car that rolled in does.
const WET := 2.5


## Loop 10a: a vehicle at height y over (x, z) is in the water: well past the water's edge
## and down at the water's level (a bridge deck over the river is not the water).
func in_water(x: float, z: float, y: float) -> bool:
	return shore_distance(x, z) >= WET and y < terrain_height(x, z) + 0.5


## Loop 10a: the nearest dry point to (x, z) inside the edge walls (the point itself when it
## is dry): 72 rays out, each jumping ahead by the water's own distance to the shore (shore
## distance is a distance field: a few hundred lookups even from mid-river).
func nearest_dry(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	if shore_distance(x, z) == 0.0:
		return p
	var best := p
	var best_r := 800.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 0.0
		while r < best_r:
			var q := p + d * r
			if not in_map(q, -6.0):
				break
			var w := shore_distance(q.x, q.y)
			if w == 0.0:
				best_r = r
				best = q
				break
			r += maxf(w - 2.0, 1.0)
	return best


## Heights of the deck pieces whose corridor holds the point (usually none). With `feet`, also
## whether each one is on a ramp's foot there (G6: `_index_deck_feet`), in the same order.
func _decks_at(x: float, z: float, feet = null) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if _decks.is_empty():
		return out
	if _deck_cells.is_empty():
		_index_decks()
	var codes: PackedInt32Array = _deck_any.get(Vector2i(floori(x / DECK_CELL), floori(z / DECK_CELL)), PackedInt32Array())
	if codes.is_empty():
		return out
	var p := Vector2(x, z)
	# The nearest segment of each piece near here, then whether p is in its corridor.
	var near := {}
	for code in codes:
		var i := code >> 12
		var k := code & 4095
		var pts: PackedVector2Array = _decks[i]["pts"]
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := maxf(ab.length_squared(), 0.000001)
		var u := (p - a).dot(ab) / l2
		var d2 := p.distance_squared_to(a + ab * clampf(u, 0.0, 1.0))
		if not near.has(i) or d2 < float(near[i][0]):
			near[i] = [d2, k, u]
	for i: int in near:
		var d: Dictionary = _decks[i]
		var k: int = near[i][1]
		var u: float = near[i][2]
		var pts: PackedVector2Array = d["pts"]
		if (k == 0 and u < 0.0) or (k == pts.size() - 2 and u > 1.0):
			# Past the deck's end, unless the end is a joint with the next piece of its deck: on
			# the outside of a bend a point can be past one piece's end and before the next one's
			# start (loop 3d-1: Most Świętokrzyski's pylon joint dropped the car 7.6 m to the river).
			var joint := (_deck_joints[i] & (1 if k == 0 else 2)) != 0
			var past := (-u if k == 0 else u - 1.0) * (pts[k + 1] - pts[k]).length()
			if not joint or past > DECK_JOINT_SLACK:
				continue
		var ab := pts[k + 1] - pts[k]
		var lat := ab.cross(p - pts[k]) / maxf(ab.length(), 0.001)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			var hs: PackedFloat32Array = d["h"]
			out.append(lerpf(hs[k], hs[k + 1], clampf(u, 0.0, 1.0)))
			if feet != null:
				if _deck_feet.is_empty():
					_index_deck_feet()
				var cum: PackedFloat32Array = d["cum"]
				var s := cum[k] + clampf(u, 0.0, 1.0) * (cum[k + 1] - cum[k])
				(feet as Array).append(((_deck_feet[i] & 1) != 0 and s <= DECK_FOOT)
						or ((_deck_feet[i] & 2) != 0 and cum[cum.size() - 1] - s <= DECK_FOOT))
	return out


## The height of deck group g at a point (its nearest piece, projected onto it), or the
## terrain for g < 0. Things baked onto a bridge (markings, kerbs, tram tracks) use it.
## PT-18: the nearest point of deck group g's centrelines to p (p itself when there is none).
func _deck_centre(g: int, p: Vector2) -> Vector2:
	if _deck_cells.is_empty():
		_index_decks()
	var best := INF
	var out := p
	var cell := Vector2i(floori(p.x / DECK_CELL), floori(p.y / DECK_CELL))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for code: int in _deck_cells.get(Vector3i(cell.x + dx, cell.y + dz, g), PackedInt32Array()):
				var pts: PackedVector2Array = _decks[code >> 12]["pts"]
				var k := code & 4095
				var a := pts[k]
				var ab := pts[k + 1] - a
				var q := a + ab * clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
				if p.distance_squared_to(q) < best:
					best = p.distance_squared_to(q)
					out = q
	return out


func deck_height(g: int, x: float, z: float) -> float:
	if g < 0:
		return terrain_height(x, z)
	if _deck_cells.is_empty():
		_index_decks()
	var p := Vector2(x, z)
	var best := INF
	var h := terrain_height(x, z)
	var cell := Vector2i(floori(x / DECK_CELL), floori(z / DECK_CELL))
	# Segments of the group's pieces in this cell and around it; the far ones only if none.
	for pass_ in 2:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for code: int in _deck_cells.get(Vector3i(cell.x + dx, cell.y + dz, g), PackedInt32Array()):
					var d: Dictionary = _decks[code >> 12]
					var k := code & 4095
					var pts: PackedVector2Array = d["pts"]
					var a := pts[k]
					var ab := pts[k + 1] - a
					var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
					var d2 := p.distance_squared_to(a + ab * t)
					if d2 < best:
						best = d2
						var hs: PackedFloat32Array = d["h"]
						h = lerpf(hs[k], hs[k + 1], t)
		if best < INF:
			return h
		for d in _decks:
			if int(d["g"]) == g:
				var hit := _deck_hit(d, p)
				if hit.y < best:
					best = hit.y
					h = hit.x
		return h
	return h


## GAMEPLAY_PLAN 3.5 (deck_hides): the camera ray's heights over the car tested for a deck (from
## over the car's roof to the highest flyover over a street) and a deck's slab and girders under
## its road.
const UNDER_DECK := 2.5
const UNDER_DECK_TOP := 24.0
const UNDER_DECK_SLAB := 1.6

const DECK_CELL := 16.0
## (cell x, cell z, group) -> segment codes (piece << 12 | segment), built on first use;
## and per cell, every segment whose corridor reaches into it.
var _deck_cells := {}
var _deck_any := {}
## G6 (F: "when I was entering the bridge I went down under it"): a road deck piece's end that is
## no joint and stands within DECK_FOOT_STEP of the ground under its middle is a ramp's foot
## (bit 1 the first end, 2 the last). The ground beside the approach's fill can lie 1.5-2.4 m
## lower (Most Poniatowskiego's north ramps, Towarowa over the cutting, Wybrzeże Szczecińskie):
## a car coming in at an angle there was more than 1.2 m under the slab and drove on under it.
## On the first DECK_FOOT metres of a foot, a car up to DECK_FOOT_UP under the slab climbs on.
## check_drive's entries pass drives onto every foot across the deck's width.
var _deck_feet := PackedByteArray()
const DECK_FOOT := 10.0
const DECK_FOOT_UP := 3.0
const DECK_FOOT_STEP := 1.2


func _index_deck_feet() -> void:
	if _deck_cells.is_empty():
		_index_decks()
	_deck_feet.resize(_decks.size())
	_deck_feet.fill(0)
	for i in _decks.size():
		var d: Dictionary = _decks[i]
		if String(d.get("k", "road")) != "road":
			continue
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var n := pts.size()
		for end in 2:
			var bit := 1 if end == 0 else 2
			if (_deck_joints[i] & bit) != 0:
				continue
			var p := pts[0] if end == 0 else pts[n - 1]
			var h := hs[0] if end == 0 else hs[n - 1]
			if h - terrain_height(p.x, p.y) <= DECK_FOOT_STEP:
				_deck_feet[i] |= bit


func _index_decks() -> void:
	# Loop 3d-1: which piece ends meet another piece's end of the same deck (a joint).
	_deck_joints.resize(_decks.size())
	_deck_joints.fill(0)
	for i in _decks.size():
		var pi: PackedVector2Array = _decks[i]["pts"]
		for j in _decks.size():
			if j == i or int(_decks[j]["g"]) != int(_decks[i]["g"]):
				continue
			var pj: PackedVector2Array = _decks[j]["pts"]
			for e in [pj[0], pj[pj.size() - 1]]:
				if pi[0].distance_to(e) < 0.6:
					_deck_joints[i] |= 1
				if pi[pi.size() - 1].distance_to(e) < 0.6:
					_deck_joints[i] |= 2
	for i in _decks.size():
		var d: Dictionary = _decks[i]
		var pts: PackedVector2Array = d["pts"]
		var g := int(d["g"])
		var reach := maxf(float(d["l"]), float(d["r"])) + 1.0
		for k in pts.size() - 1:
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for cz in range(floori(lo.y / DECK_CELL), floori(hi.y / DECK_CELL) + 1):
				for cx in range(floori(lo.x / DECK_CELL), floori(hi.x / DECK_CELL) + 1):
					var key := Vector3i(cx, cz, g)
					var list: PackedInt32Array = _deck_cells.get(key, PackedInt32Array())
					list.append((i << 12) | k)
					_deck_cells[key] = list
					var key2 := Vector2i(cx, cz)
					var any: PackedInt32Array = _deck_any.get(key2, PackedInt32Array())
					any.append((i << 12) | k)
					_deck_any[key2] = any


## Against one deck piece: (height at the nearest point, squared distance to it,
## 1 if the point is inside its corridor else 0).
func _deck_hit(d: Dictionary, p: Vector2) -> Vector3:
	var pts: PackedVector2Array = d["pts"]
	var cum: PackedFloat32Array = d["cum"]
	var hs: PackedFloat32Array = d["h"]
	var best := INF
	var height := 0.0
	var inside := 0.0
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var u := (p - a).dot(ab) / l2
		var t := clampf(u, 0.0, 1.0)
		var q := a + ab * t
		var d2 := p.distance_squared_to(q)
		if d2 < best:
			best = d2
			height = lerpf(hs[k], hs[k + 1], t)
			var lat := ab.cross(p - a) / sqrt(l2)  # right of the line is +
			var along := cum[k] + t * (cum[k + 1] - cum[k])
			var ends := (k == 0 and u < 0.0) or (k == pts.size() - 2 and u > 1.0)
			inside = 1.0 if not ends and along >= 0.0 and lat >= -float(d["l"]) and lat <= float(d["r"]) else 0.0
	return Vector3(height, best, inside)


## F, 2026-11-05: footbridges over a road in a trench (Aleja Armii Ludowej, (380, 1500)) or over
## the Ochota cutting ((-2170, 880), (-2324, 927)) came down to the floor under them: the bake
## solved their height off the 10 m grid, which has the trench's floor between its two rims, so the
## deck sank 4-6 m below its ends onto the road or the tracks. A path deck whose lowest point
## sits within SAG_ON_GROUND of the ground and under the straight line between its ends by more
## than SAG_DIP is lifted onto that line (never lowered), a level bridge over the gap.
const SAG_DIP := 2.0
const SAG_ON_GROUND := 0.6


func _lift_sagging_deck(pts: PackedVector2Array, cum: PackedFloat32Array, hs: PackedFloat32Array) -> void:
	var n := pts.size()
	var total := cum[n - 1]
	if n < 3 or total < 1.0 or hs.size() != n:
		return
	var worst := 0.0
	var at := -1
	for i in range(1, n - 1):
		var dip := lerpf(hs[0], hs[n - 1], cum[i] / total) - hs[i]
		if dip > worst:
			worst = dip
			at = i
	if worst < SAG_DIP or hs[at] - terrain_height(pts[at].x, pts[at].y) > SAG_ON_GROUND:
		return
	for i in range(1, n - 1):
		hs[i] = maxf(hs[i], lerpf(hs[0], hs[n - 1], cum[i] / total))


## Footbridges over a rail yard (F, 2026-11-06: the kładka over Warszawa Główna, from Kolejowa
## to the towers on Jerozolimskie, came down to the ballast twice where OSM ties the stairs to
## its platforms): a path deck crossing RAIL_BRIDGE_MIN tracks holds RAIL_BRIDGE_CLEAR over the
## highest of them from its first track to its last (the catenary under it), its ends climbing
## to that from where they land. Each: {"pts", "cum", "h", "a", "b"} (the level run's ends along
## it), for the stairs and lifts down to the platforms (_build_footbridge_stairs).
const RAIL_BRIDGE_MIN := 4
const RAIL_BRIDGE_CLEAR := 7.4
var _rail_bridges: Array[Dictionary] = []


func _lift_rail_footbridge(pts: PackedVector2Array, cum: PackedFloat32Array, hs: PackedFloat32Array) -> void:
	var n := pts.size()
	if n < 2 or hs.size() != n:
		return
	var box := Rect2(pts[0], Vector2.ZERO)
	for q in pts:
		box = box.expand(q)
	var first := INF
	var last := -INF
	var top := -INF
	var count := 0
	for r: Dictionary in data.get("rails", []):
		if r.has("dk") and int(r["dk"]) >= 0:
			continue
		var f: Array = r["p"]
		for i in range(0, f.size() - 3, 2):
			var a := Vector2(f[i], f[i + 1])
			var b := Vector2(f[i + 2], f[i + 3])
			if not box.grow(1.0).intersects(Rect2(a, Vector2.ZERO).expand(b)):
				continue
			for k in n - 1:
				var x: Variant = Geometry2D.segment_intersects_segment(pts[k], pts[k + 1], a, b)
				if x == null:
					continue
				var along := cum[k] + pts[k].distance_to(x)
				first = minf(first, along)
				last = maxf(last, along)
				top = maxf(top, terrain_height((x as Vector2).x, (x as Vector2).y))
				count += 1
	if count < RAIL_BRIDGE_MIN:
		return
	var level := top + RAIL_BRIDGE_CLEAR
	var total := cum[n - 1]
	var a0 := maxf(first - 3.0, 0.0)
	var b0 := minf(last + 3.0, total)
	for i in n:
		var c := cum[i]
		var want := level
		if c < a0:
			want = lerpf(hs[0], level, c / a0)
		elif c > b0:
			want = lerpf(level, hs[n - 1], (c - b0) / maxf(total - b0, 0.01))
		hs[i] = maxf(hs[i], want)
	_rail_bridges.append({"pts": pts, "cum": cum, "h": hs, "a": a0, "b": b0})


func _load_decks() -> void:
	_decks.clear()
	_rail_bridges.clear()
	var data_decks: Dictionary = data.get("decks", {})
	for piece in data_decks.get("pieces", []):
		var pts := _pts(piece["p"])
		var cum := PackedFloat32Array([0.0])
		for k in range(1, pts.size()):
			cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		var reach := maxf(float(piece["l"]), float(piece["r"])) + 1.0
		var hs := PackedFloat32Array(piece["h"])
		if String(piece["k"]) == "path":
			_lift_sagging_deck(pts, cum, hs)
			_lift_rail_footbridge(pts, cum, hs)
		_decks.append({"pts": pts, "cum": cum, "h": hs, "l": float(piece["l"]),
				"r": float(piece["r"]), "g": int(piece["g"]), "k": String(piece["k"]),
				"o": PackedByteArray(piece.get("o", [])), "box": box.grow(reach)})


# --- sunken places ---------------------------------------------------------------------------

## Sunken places (F's aerial and photos, 2026-11-05): ground metres under the street within a
## few metres, which the 10 m GUGiK grid can only draw as a blurred slope (the Patelnia by Metro
## Centrum lay in a soft bowl; the Rotunda's stair to the underpass was a walled box at street
## level). Each: `ring`, the plan outline (the retaining walls' line); the floor falls from the
## grid's height at `a` (a stair's top) to `hb` at `b` (its foot), flat past either end, or lies
## flat at `hb` when `a` == `b`; `sub`, the drawn ground's sub-cells per 10 m cell there.
## terrain_height (the car, people, props) takes the floor inside the ring; the drawn ground
## (`_drawn_corner`) takes it over the ring grown by one sub-cell's diagonal, so no sub-cell's
## slope shows inside the walls (the band outside is under the coping the landmark site `sunken`
## lays, landmarks.gd, with the walls, stair treads and railings). A wall line (`lines` k wall)
## lying on a ring is the site's, so _build_barriers leaves it out (SINK_WALL_REACH).
## Patelnia: the plaza (centrum.json `areas` k plaza) and Metro Centrum's pavilions (`landmarks`
## "Metro Centrum"), floor 10.0 (the grid's own bottom there, 9.9-10.2); its north-east stair to
## Marszałkowska (`steps` between the walls) and the wide west stair ("Schody Kokota"). Rotunda:
## the wedge between the planters north-west of Rotunda PKO, the stair down to its lower floor and
## the underpass (`steps` 11 m, 3.6 m down, then the landing under the Rotunda's edge).
const SUNKEN := [
	{"key": "patelnia", "sub": 10, "hb": 10.0, "a": Vector2(-911.5, 400.0), "b": Vector2(-911.5, 400.0),
		"ring": [Vector2(-884.1, 424.3), Vector2(-883.7, 422.1), Vector2(-884.9, 416.0), Vector2(-886.1, 410.0),
			Vector2(-887.7, 402.3), Vector2(-888.3, 401.5), Vector2(-885.5, 393.2), Vector2(-889.4, 376.1),
			Vector2(-892.8, 376.6), Vector2(-897.1, 377.7), Vector2(-901.5, 368.3), Vector2(-909.8, 372.5),
			Vector2(-928.5, 381.4), Vector2(-939.0, 386.2), Vector2(-934.3, 395.7), Vector2(-938.6, 397.7),
			Vector2(-933.2, 408.9), Vector2(-935.7, 410.1), Vector2(-938.1, 411.2), Vector2(-937.3, 413.6),
			Vector2(-937.3, 414.5), Vector2(-938.0, 416.3), Vector2(-939.5, 417.6), Vector2(-938.5, 420.5),
			Vector2(-937.4, 423.5), Vector2(-935.7, 422.9), Vector2(-931.4, 422.3), Vector2(-926.2, 422.4),
			Vector2(-919.0, 424.0), Vector2(-913.2, 425.9), Vector2(-908.4, 426.7), Vector2(-904.0, 426.6),
			Vector2(-894.9, 424.9), Vector2(-889.3, 424.2), Vector2(-886.2, 424.1)]},
	{"key": "patelnia_ne", "sub": 10, "hb": 10.0, "a": Vector2(-893.2, 367.0), "b": Vector2(-891.0, 377.0),
		"ring": [Vector2(-894.7, 368.2), Vector2(-891.3, 367.5), Vector2(-889.4, 376.1), Vector2(-892.8, 376.6)]},
	{"key": "patelnia_kokota", "sub": 10, "hb": 10.0, "a": Vector2(-952.4, 425.4), "b": Vector2(-938.6, 420.4),
		"ring": [Vector2(-939.5, 417.6), Vector2(-944.5, 419.4), Vector2(-951.8, 422.0), Vector2(-953.0, 426.9),
			Vector2(-949.7, 427.7), Vector2(-935.7, 422.9), Vector2(-937.4, 423.5), Vector2(-938.5, 420.5)]},
	{"key": "rotunda_stair", "sub": 10, "hb": NAN, "drop": 3.6, "a": Vector2(-819.6, 366.3), "b": Vector2(-815.5, 377.4),
		"ring": [Vector2(-820.5, 366.4), Vector2(-819.1, 365.9), Vector2(-813.4, 363.8), Vector2(-808.3, 377.8),
			Vector2(-810.0, 380.0), Vector2(-811.4, 382.2), Vector2(-812.4, 384.3), Vector2(-813.1, 386.8)]},
	# The underpass under Aleje Jerozolimskie at Emilii Plater (F, 2026-11-06: "add stairs and
	# arrange it like in real life with people going in and out"; site `underpass`, spec
	# docs/landmarks/specs/underpass-emilii-plater.md). `at`/`top`: a lower flight's top lies `top`
	# under the grid at `at` (the flight above's own top); `style` the edge (granite parapet, or a
	# low parapet under a steel canopy); `walk` the walkers' way from the street down and on under
	# the street through the mouth (its last point hidden in the passage, pedestrians.gd).
	# The north-east well in the lawn (the mapped walls, line 421): a flight down to a landing,
	# a second flight on south into the passage under the pavement.
	{"key": "epl_ne", "site": "underpass", "style": "parapet", "sub": 20, "hb": NAN, "drop": 1.7,
		"a": Vector2(-1254.1, 550.2), "b": Vector2(-1252.3, 555.6),
		"ring": [Vector2(-1256.0, 551.2), Vector2(-1251.6, 549.8), Vector2(-1249.8, 554.7), Vector2(-1245.3, 553.2),
			Vector2(-1244.3, 556.2), Vector2(-1243.3, 559.1), Vector2(-1247.9, 560.7), Vector2(-1253.3, 562.6),
			Vector2(-1255.4, 556.4), Vector2(-1254.4, 556.1)]},
	{"key": "epl_ne_low", "site": "underpass", "style": "parapet", "sub": 20, "hb": NAN, "drop": 1.9,
		"at": Vector2(-1254.1, 550.2), "top": 1.7, "a": Vector2(-1250.4, 561.6), "b": Vector2(-1248.1, 568.4),
		"ring": [Vector2(-1247.9, 560.7), Vector2(-1245.6, 567.6), Vector2(-1248.1, 568.4), Vector2(-1249.8, 569.0),
			Vector2(-1252.0, 562.5), Vector2(-1253.2, 562.9), Vector2(-1253.3, 562.6)],
		"walk": [Vector2(-1254.1, 550.2), Vector2(-1252.3, 555.6), Vector2(-1250.4, 561.6), Vector2(-1248.1, 568.4),
			Vector2(-1246.8, 572.2)]},
	# The north-west box on Centralna's forecourt (line 419): one flight south from footway 8754's end.
	{"key": "epl_nw", "site": "underpass", "style": "parapet", "sub": 20, "hb": NAN, "drop": 3.6,
		"a": Vector2(-1309.3, 579.9), "b": Vector2(-1307.0, 586.5),
		"ring": [Vector2(-1307.0, 579.1), Vector2(-1304.2, 587.1), Vector2(-1306.4, 587.9), Vector2(-1308.7, 588.7),
			Vector2(-1311.5, 581.0), Vector2(-1311.6, 580.7)],
		"walk": [Vector2(-1309.3, 579.9), Vector2(-1307.0, 586.5), Vector2(-1305.1, 591.7)]},
	# The north pavement's flight (steps 76) under its dark steel-and-glass canopy.
	{"key": "epl_n", "site": "underpass", "style": "canopy_dark", "sub": 20, "hb": NAN, "drop": 3.6,
		"a": Vector2(-1227.5, 572.7), "b": Vector2(-1239.0, 576.7),
		"ring": [Vector2(-1227.7, 571.3), Vector2(-1241.3, 576.0), Vector2(-1240.4, 578.7), Vector2(-1226.8, 573.9)],
		"walk": [Vector2(-1227.5, 572.7), Vector2(-1239.0, 576.7), Vector2(-1244.7, 578.7)]},
	# The south pavement's two flights to Warszawa Śródmieście (steps 36, 220) under green canopies.
	{"key": "epl_s1", "site": "underpass", "style": "canopy_green", "sub": 20, "hb": NAN, "drop": 3.6,
		"a": Vector2(-1247.6, 619.9), "b": Vector2(-1236.4, 616.2),
		"ring": [Vector2(-1247.4, 621.3), Vector2(-1234.1, 616.9), Vector2(-1234.9, 614.2), Vector2(-1248.3, 618.7)],
		"walk": [Vector2(-1247.6, 619.9), Vector2(-1236.4, 616.2), Vector2(-1230.7, 614.3)]},
	{"key": "epl_s2", "site": "underpass", "style": "canopy_green", "sub": 20, "hb": NAN, "drop": 3.6,
		"a": Vector2(-1215.4, 609.1), "b": Vector2(-1226.7, 612.9),
		"ring": [Vector2(-1215.6, 607.7), Vector2(-1229.0, 612.2), Vector2(-1228.1, 614.9), Vector2(-1214.7, 610.3)],
		"walk": [Vector2(-1215.4, 609.1), Vector2(-1226.7, 612.9), Vector2(-1232.4, 614.8)]},
]
## How far past a ring's grown outline the drawn ground's cells go fine (a sub-cell touching it).
const SINK_MARGIN := 0.5
## A wall line's segment with both ends this close to a sunken ring's edge is the site's.
const SINK_WALL_REACH := 0.6
## The rings as built: {"key", "ring", "grown", "box", "a", "b", "ha", "hb", "sub", "site", "style", "walk"}.
var _sunk: Array[Dictionary] = []
var _sunk_box := Rect2()


func _load_sunken() -> void:
	_sunk.clear()
	_sunk_box = Rect2()
	if _t_h.is_empty():
		return
	for e: Dictionary in SUNKEN:
		var at: Vector2 = e.get("at", e["a"])
		var sk := sunk_entry(e, _grid_height(at.x, at.y), float(_terrain["step"]))
		_sunk.append(sk)
		_sunk_box = sk["box"] if not _sunk_box.has_area() else _sunk_box.merge(sk["box"])


## One SUNKEN entry as built, its stair's top at height `ha` less its `top` (a flat floor: `hb`, or
## the top less its `drop`); `step` the terrain grid's cell. The landmark checks' stub maps build theirs with this.
static func sunk_entry(e: Dictionary, ha: float, step: float) -> Dictionary:
	var ring := PackedVector2Array(e["ring"])
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	var sub := int(e["sub"])
	var grown_list := Geometry2D.offset_polygon(ring, step / sub * 1.42, Geometry2D.JOIN_MITER)
	var grown: PackedVector2Array = grown_list[0] if not grown_list.is_empty() else ring
	var box := Rect2(grown[0], Vector2.ZERO)
	for q in grown:
		box = box.expand(q)
	ha -= float(e.get("top", 0.0))
	var hb := float(e["hb"])
	if is_nan(hb):
		hb = ha - float(e["drop"])
	return {"key": e["key"], "ring": ring, "grown": grown, "box": box, "a": e["a"], "b": e["b"], "ha": ha, "hb": hb, "sub": sub,
			"site": e.get("site", "sunken"), "style": e.get("style", "rail"), "walk": PackedVector2Array(e.get("walk", []))}


## A sunken ring's floor at a point (its ring, or `grown` its ring grown for the drawn ground),
## the lowest of those holding it; INF where none does.
func sunk_floor(x: float, z: float, grown := false) -> float:
	var p := Vector2(x, z)
	var best := INF
	for sk: Dictionary in _sunk:
		if not (sk["box"] as Rect2).has_point(p):
			continue
		if not Geometry2D.is_point_in_polygon(p, sk["grown"] if grown else sk["ring"]):
			continue
		best = minf(best, sunk_level(sk, p))
	return best


## The floor of sunken ring `sk` at plan point p (from its stair's top to its foot, flat past them).
static func sunk_level(sk: Dictionary, p: Vector2) -> float:
	var a: Vector2 = sk["a"]
	var ab: Vector2 = (sk["b"] as Vector2) - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return float(sk["hb"])
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return lerpf(float(sk["ha"]), float(sk["hb"]), t)


## The railway cutting west of Centralna (rail_cut.gd), from every rail of the map (the index's in
## streamed mode), the tunnel's stretch cut away as trains.gd does.
var _cut = RailCut.new()


## Platforms OSM maps only as footways between two tracks (rail_yard.gd).
var _yard = RailYard.new()


## A footway's lift over the ground (an island platform OSM maps as a footway: RailYard.HEIGHT),
## by its ends (RailYard.key); pedestrians.gd asks.
func footway_lift(line: PackedVector2Array) -> float:
	return float(_yard.lifts.get(RailYard.key(line), 0.0)) if line.size() >= 2 else 0.0


func _load_cut() -> void:
	_cut = RailCut.new()
	_yard = RailYard.new()
	_yard.setup(data.get("paths", []), Trains.trim_rails(data.get("rails", [])), data.get("platforms", []))
	if _t_h.is_empty():
		return
	var t0 := Time.get_ticks_msec()
	_yard.set_bases(_grid_height)
	_cut.setup(Trains.trim_rails(data.get("rails", [])), _grid_height)
	var samples := 0
	for t: Dictionary in _cut.tracks:
		for c in (t["cut"] as PackedByteArray):
			samples += c
	var runs := _cut.edges()
	var walled := 0
	var banked := 0
	for r: Dictionary in runs:
		for w in (r["wall"] as PackedByteArray):
			walled += w
			banked += 1 - w
	print("rail yard: %d footways are island platforms, %d footway rings platform outlines" % [_yard.platforms.size(), _yard.rings.size()])
	print("rail cut: %d tracks, %d samples in the cutting (%.1f km), %d edge runs (%d bank, %d wall samples), %d ms" % [
			_cut.tracks.size(), samples, samples * RailCut.STEP / 1000.0, runs.size(), banked, walled, Time.get_ticks_msec() - t0])


## Whether plan point (x, z) lies in a SUNKEN ring (static: no map needed; the prebuilt path's
## street props ask before the city is loaded).
static func in_sunken(x: float, z: float) -> bool:
	for e: Dictionary in SUNKEN:
		if Geometry2D.is_point_in_polygon(Vector2(x, z), PackedVector2Array(e["ring"])):
			return true
	return false


## Whether wall segment a-b lies on a sunken ring's edge (the site walls it).
func _on_sunk_edge(a: Vector2, b: Vector2) -> bool:
	if not _sunk_box.grow(1.0).has_point(a):
		return false
	for sk: Dictionary in _sunk:
		var ring: PackedVector2Array = sk["ring"]
		var near_a := false
		var near_b := false
		for i in ring.size():
			var p := ring[i]
			var q := ring[(i + 1) % ring.size()]
			near_a = near_a or Geometry2D.get_closest_point_to_segment(a, p, q).distance_to(a) < SINK_WALL_REACH
			near_b = near_b or Geometry2D.get_closest_point_to_segment(b, p, q).distance_to(b) < SINK_WALL_REACH
		if near_a and near_b:
			return true
	return false


## Loop 3a (R1): the approaches' pieces and their cell index (`terrain_height` reads them).
func _load_fills() -> void:
	_fills.clear()
	_fill_cells.clear()
	for piece in data.get("fills", []):
		var pts := _pts(piece["p"])
		var i := _fills.size()
		_fills.append({"pts": pts, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]), "r": float(piece["r"]),
				"s": int(piece.get("s", 0)) == 1})
		var reach := maxf(float(piece["l"]), float(piece["r"])) + 0.5
		for k in pts.size() - 1:
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for cz in range(floori(lo.y / FILL_CELL), floori(hi.y / FILL_CELL) + 1):
				for cx in range(floori(lo.x / FILL_CELL), floori(hi.x / FILL_CELL) + 1):
					var key := (cx + 1024) * 4096 + cz + 1024
					var list: PackedInt32Array = _fill_cells.get(key, PackedInt32Array())
					list.append((i << 12) | k)
					_fill_cells[key] = list


## Loop 3b (R6): retaining walls where an approach (a fill) stands above the ground beside it
## (tools/bake_structures.py `walls`): a stone face (roads; concrete under tracks) from the
## ground outside to the fill's top, a light coping, and on roads where the drop is a metre or
## more a parapet with its inner face; solid where the bake says so (not where a way joins the
## approach). Into the walls' tile meshes, like the slabs. The same runs line the tunnels
## (kind "tunnel": dark, from the floor up, solid only inside) and their open ramps (kind
## "concrete", facing the road in its trench). Loop 3a drew plain faces
## (`_build_fill_sides`, still used for a map baked without `walls`).
const WALL_STONE := Color("#a69d8f")
const WALL_CONCRETE := Color("#a59f95")
const WALL_COPING := Color("#c9c4b8")
const WALL_TUNNEL := Color("#6e6a63")
const WALL_PARAPET := 0.9


func _build_walls(st) -> void:
	if not data.has("walls"):
		_build_fill_sides(st)
		return
	_uv2 = Vector2(0.5, -1.0)
	for w: Dictionary in data["walls"]:
		var pts := _pts(w["p"])
		var tops: Array = w["t"]
		var lows: Array = w["b"]
		var flags: Array = w["f"]
		var tunnel: bool = w["k"] == "tunnel"
		var face := WALL_STONE if w["k"] == "stone" else (WALL_TUNNEL if tunnel else WALL_CONCRETE)
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var out := Vector2(-dir.y, dir.x)
			var n := Vector3(out.x, 0.0, out.y)
			var flag := int(flags[i])
			var ta := float(tops[i]) - (0.2 if tunnel else 0.0)
			var tb := float(tops[i + 1]) - (0.2 if tunnel else 0.0)
			var lift := WALL_PARAPET if flag & 2 else 0.0
			# Blocks: every other stretch a shade lighter, so a long wall reads as masonry.
			var col := face.lightened(0.04) if i % 2 == 0 else face.darkened(0.03)
			_quad(st, Vector3(a.x, float(lows[i]) - 0.3, a.y), Vector3(b.x, float(lows[i + 1]) - 0.3, b.y),
					Vector3(b.x, tb + lift, b.y), Vector3(a.x, ta + lift, a.y), n, col)
			# The coping (and the parapet's top), WALL_OUT wide back to the fill's corridor.
			var ai := a - out * 0.3
			var bi := b - out * 0.3
			if not tunnel:
				_quad(st, Vector3(a.x, ta + lift, a.y), Vector3(b.x, tb + lift, b.y), Vector3(bi.x, tb + lift, bi.y),
						Vector3(ai.x, ta + lift, ai.y), Vector3.UP, WALL_COPING)
			if lift > 0.0:
				_quad(st, Vector3(ai.x, ta - 0.05, ai.y), Vector3(bi.x, tb - 0.05, bi.y), Vector3(bi.x, tb + lift, bi.y),
						Vector3(ai.x, ta + lift, ai.y), -n, face.lightened(0.08))
			if flag & 4:
				# Inside a tunnel: solid from its floor to over a bus, not up to the street above.
				var fa := float(lows[i])
				var fb := float(lows[i + 1])
				_wall_faces.append_array([Vector3(a.x, fa - 1.0, a.y), Vector3(b.x, fb - 1.0, b.y), Vector3(b.x, fb + 4.5, b.y),
						Vector3(a.x, fa - 1.0, a.y), Vector3(b.x, fb + 4.5, b.y), Vector3(a.x, fa + 4.5, a.y)])
			elif flag & 1:
				var y0a := float(lows[i]) - 1.0
				var y0b := float(lows[i + 1]) - 1.0
				_wall_faces.append_array([Vector3(a.x, y0a, a.y), Vector3(b.x, y0b, b.y), Vector3(b.x, tb + 1.6, b.y),
						Vector3(a.x, y0a, a.y), Vector3(b.x, tb + 1.6, b.y), Vector3(a.x, ta + 1.6, a.y)])
	_uv2 = Vector2.ZERO


## Loop 3b: a frame at each tunnel portal (`tunnels.frames`, tools/bake_structures.py): a
## concrete headwall over the mouth up to the ground above it, two posts and a dark mouth a
## little inside (the tunnel's road and walls show in it); the headwall and posts are solid.
const PORTAL_CONCRETE := Color("#b3ada3")
const PORTAL_DARK := Color("#1f1d22")
const PORTAL_MOUTH := 4.8


func _build_portals(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for f: Dictionary in data.get("tunnels", {}).get("frames", []):
		var c := Vector2(float(f["c"][0]), float(f["c"][1]))
		var d := Vector2(float(f["d"][0]), float(f["d"][1]))
		var side := Vector2(-d.y, d.x)
		var w := float(f["w"])
		var y := float(f["y"])
		var top := maxf(float(f["top"]), y + PORTAL_MOUTH + 0.8) + 0.6
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var head := c + d * 0.5
		# The headwall over the mouth, the posts either side, the mouth's dark back.
		_box_oriented(st, Vector3(head.x, (y + PORTAL_MOUTH + top) * 0.5, head.y), basis,
				Vector3(w + 2.4, top - y - PORTAL_MOUTH, 1.0), PORTAL_CONCRETE)
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = head + side * sgn * (w * 0.5 + 0.6)
			_box_oriented(st, Vector3(p.x, (y - 0.5 + y + PORTAL_MOUTH) * 0.5, p.y), basis,
					Vector3(1.2, PORTAL_MOUTH + 0.5, 1.0), PORTAL_CONCRETE.darkened(0.06))
		var back := c + d * 3.0
		var l0 := back - side * w * 0.5
		var r0 := back + side * w * 0.5
		_quad(st, Vector3(l0.x, y - 0.2, l0.y), Vector3(r0.x, y - 0.2, r0.y), Vector3(r0.x, y + PORTAL_MOUTH, r0.y),
				Vector3(l0.x, y + PORTAL_MOUTH, l0.y), Vector3(-d.x, 0.0, -d.y), PORTAL_DARK)
		# The headwall's front face is solid (the street above can't drive off into the ramp).
		var a := head - d * 0.5 - side * (w * 0.5 + 1.2)
		var b := head - d * 0.5 + side * (w * 0.5 + 1.2)
		_wall_faces.append_array([Vector3(a.x, y + PORTAL_MOUTH, a.y), Vector3(b.x, y + PORTAL_MOUTH, b.y), Vector3(b.x, top + 1.6, b.y),
				Vector3(a.x, y + PORTAL_MOUTH, a.y), Vector3(b.x, top + 1.6, b.y), Vector3(a.x, top + 1.6, a.y)])
	_uv2 = Vector2.ZERO


## The railway cutting west of Centralna (rail_cut.gd, F 2026-11-06): its banks in grass and its
## floor in ballast (flat layers), and on the walls surface the concrete retaining walls where the
## cutting is too narrow for a bank (by the tunnel's mouth) and the fence along every bank's top,
## both solid, both broken where a street or footway meets them.
const CUT_FLOOR := Color("#7b7368")
const CUT_FENCE := Color("#7d838a")
const CUT_PARAPET := 1.05
const CUT_PILASTER := 6.0


func _build_cut_banks(st) -> void:
	if _cut.tracks.is_empty():
		return
	var keep := _layer
	_layer = L_GREEN
	var streets := _cut_street_cells()
	for run: Dictionary in _cut.edges():
		var toe: PackedVector2Array = run["toe"]
		var top: PackedVector2Array = run["top"]
		var wall: PackedByteArray = run["wall"]
		for k in toe.size() - 1:
			if wall[k] == 1 or wall[k + 1] == 1:
				continue
			var quad := PackedVector2Array([toe[k], toe[k + 1], top[k + 1], top[k]])
			# A path or street down the bank keeps its own surface (check_drape: the grass lay
			# over the Ochota footbridge's foot).
			var mid := (toe[k] + toe[k + 1] + top[k] + top[k + 1]) * 0.25
			if _cut_by_street(streets, mid) or _cut_by_street(streets, top[k]) or _cut_by_street(streets, toe[k]):
				continue
			if Geometry2D.is_polygon_clockwise(quad):
				quad.reverse()
			_fill_on_grid(st, quad, Y_AREA + BANK_Y, COL["grass"])
	_layer = keep


## The cutting's floor between its tracks: ballast, under the tracks' own beds.
func _build_cut_floor(st) -> void:
	if _cut.tracks.is_empty():
		return
	var keep := _layer
	_layer = L_GRAVEL
	_exact_strip = true
	for t: Dictionary in _cut.tracks:
		var pts: PackedVector2Array = t["p"]
		var cut: PackedByteArray = t["cut"]
		var run := PackedVector2Array()
		for k in pts.size():
			if cut[k] == 1:
				run.append(pts[k])
			elif run.size() > 0:
				if run.size() >= 2:
					_strip(st, run, RailCut.FLOOR_W * 2.0, Y_PATH, CUT_FLOOR, false)
				run = PackedVector2Array()
		if run.size() >= 2:
			_strip(st, run, RailCut.FLOOR_W * 2.0, Y_PATH, CUT_FLOOR, false)
	_exact_strip = false
	_layer = keep


## Street and footway segments near the cutting (16 m cells), for the walls' and fences' gaps.
func _cut_street_cells() -> Dictionary:
	var cells := {}
	var box: Rect2 = _cut.box.grow(10.0)
	for key in ["roads", "paths", "trams"]:
		for r: Dictionary in data.get(key, []):
			var poly := _pts(r["p"])
			var w := float(r.get("w", 3.0)) * 0.5
			for i in poly.size() - 1:
				var a := poly[i]
				var b := poly[i + 1]
				if not box.has_point(a) and not box.has_point(b):
					continue
				var lo := a.min(b) - Vector2.ONE * (w + 3.0)
				var hi := a.max(b) + Vector2.ONE * (w + 3.0)
				for cz in range(floori(lo.y / 16.0), floori(hi.y / 16.0) + 1):
					for cx in range(floori(lo.x / 16.0), floori(hi.x / 16.0) + 1):
						var list: Array = cells.get(Vector2i(cx, cz), [])
						list.append([a, b, w])
						cells[Vector2i(cx, cz)] = list
	return cells


func _cut_by_street(cells: Dictionary, p: Vector2) -> bool:
	for seg: Array in cells.get(Vector2i(floori(p.x / 16.0), floori(p.y / 16.0)), []):
		var q := Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])
		if q.distance_to(p) < float(seg[2]) + 1.5:
			return true
	return false


func _build_cutting(st) -> void:
	if _cut.tracks.is_empty():
		return
	var streets := _cut_street_cells()
	_uv2 = Vector2(0.5, -1.0)
	for run: Dictionary in _cut.edges():
		var toe: PackedVector2Array = run["toe"]
		var top: PackedVector2Array = run["top"]
		var fh: PackedFloat32Array = run["fh"]
		var rh: PackedFloat32Array = run["rh"]
		var outs: PackedVector2Array = run["out"]
		var wall: PackedByteArray = run["wall"]
		var fence := PackedVector2Array()
		var along := 0.0
		for k in toe.size():
			var free := not _cut_by_street(streets, top[k])
			var mine := not _in_sector or _sector_rect.has_point(top[k])
			# The fence along a bank's top, in runs between the streets and the walls.
			if wall[k] == 0 and free and mine:
				fence.append(top[k])
			else:
				if fence.size() >= 2:
					_railing_along(st, fence, 1.7, 0.0, CUT_FENCE, CUT_FENCE.darkened(0.2), true)
				fence = PackedVector2Array()
				if wall[k] == 0 and free and mine and k > 0:
					fence.append(top[k])
			if k == toe.size() - 1:
				break
			var seg := toe[k].distance_to(toe[k + 1])
			if wall[k] == 1 and wall[k + 1] == 1 and seg > 0.05:
				var mid := (toe[k] + toe[k + 1]) * 0.5
				if mine or (not _in_sector or _sector_rect.has_point(mid)):
					if not _in_sector or _sector_rect.has_point(mid):
						_cut_wall_piece(st, toe[k], toe[k + 1], outs[k], outs[k + 1], fh[k], fh[k + 1], rh[k], rh[k + 1],
								free and not _cut_by_street(streets, top[k + 1]), along)
			along += seg
		if fence.size() >= 2:
			_railing_along(st, fence, 1.7, 0.0, CUT_FENCE, CUT_FENCE.darkened(0.2), true)
	_uv2 = Vector2.ZERO


## One piece of retaining wall from a to b (its face over the floor's edge, `out` towards the
## street): the face from under the floor to the parapet's top, the parapet's cap and back, the
## wall's top (a concrete band WALL_W wide over the ground's climb behind it), a pilaster every
## CUT_PILASTER m, the parapet solid where no street meets it.
func _cut_wall_piece(st, a: Vector2, b: Vector2, oa: Vector2, ob: Vector2, fa: float, fb: float, ra: float, rb: float,
		parapet: bool, along: float) -> void:
	var lift := CUT_PARAPET if parapet else 0.12
	var ta := ra + lift
	var tb := rb + lift
	var a1 := a + oa * 0.3
	var b1 := b + ob * 0.3
	var a2 := a + oa * (RailCut.WALL_W + 0.4)
	var b2 := b + ob * (RailCut.WALL_W + 0.4)
	var nin := Vector3(-(oa.x + ob.x), 0.0, -(oa.y + ob.y)).normalized()
	_quad(st, Vector3(a.x, fa - 0.3, a.y), Vector3(b.x, fb - 0.3, b.y), Vector3(b.x, tb, b.y), Vector3(a.x, ta, a.y),
			nin, WALL_CONCRETE)
	# A darker plinth band over the floor (the drainage channel's kerb).
	var pa := a - Vector2(nin.x, nin.z) * 0.02
	var pb := b - Vector2(nin.x, nin.z) * 0.02
	_quad(st, Vector3(pa.x, fa - 0.3, pa.y), Vector3(pb.x, fb - 0.3, pb.y), Vector3(pb.x, fb + 0.6, pb.y),
			Vector3(pa.x, fa + 0.6, pa.y), nin, WALL_CONCRETE.darkened(0.18))
	_quad(st, Vector3(a.x, ta, a.y), Vector3(b.x, tb, b.y), Vector3(b1.x, tb, b1.y), Vector3(a1.x, ta, a1.y), Vector3.UP, WALL_COPING)
	_quad(st, Vector3(a1.x, ra + 0.1, a1.y), Vector3(b1.x, rb + 0.1, b1.y), Vector3(b2.x, rb + 0.1, b2.y),
			Vector3(a2.x, ra + 0.1, a2.y), Vector3.UP, WALL_COPING.darkened(0.08))
	if parapet:
		_quad(st, Vector3(a1.x, ra + 0.1, a1.y), Vector3(b1.x, rb + 0.1, b1.y), Vector3(b1.x, tb, b1.y), Vector3(a1.x, ta, a1.y),
				-nin, WALL_CONCRETE.darkened(0.05))
		_wall_faces.append_array([Vector3(a1.x, ra - 0.5, a1.y), Vector3(b1.x, rb - 0.5, b1.y), Vector3(b1.x, tb + 1.5, b1.y),
				Vector3(a1.x, ra - 0.5, a1.y), Vector3(b1.x, tb + 1.5, b1.y), Vector3(a1.x, ta + 1.5, a1.y)])
	# The top band's outer edge, down to the street's ground.
	_quad(st, Vector3(a2.x, ra - 0.6, a2.y), Vector3(b2.x, rb - 0.6, b2.y), Vector3(b2.x, rb + 0.1, b2.y),
			Vector3(a2.x, ra + 0.1, a2.y), -nin, WALL_CONCRETE.darkened(0.05))
	# Pilasters where a multiple of CUT_PILASTER falls on the piece.
	var seg := a.distance_to(b)
	var next := ceilf(along / CUT_PILASTER) * CUT_PILASTER
	while next < along + seg:
		var t := (next - along) / seg
		var p := a.lerp(b, t)
		var d := (b - a) / seg
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var lo := lerpf(fa, fb, t) - 0.3
		var hi := lerpf(ta, tb, t)
		_box_oriented(st, Vector3(p.x + nin.x * 0.12, (lo + hi) * 0.5, p.y + nin.z * 0.12), basis,
				Vector3(0.24, hi - lo, 0.7), WALL_CONCRETE.darkened(0.07))
		next += CUT_PILASTER


## Island platforms OSM maps as footways (rail_yard.gd): the tiled top RailYard.HEIGHT over the
## ground between the two tracks' edges, white edge bands and the yellow line 0.9 m in, the
## sides down to the ballast, a lamp every PLATFORM_LAMP m down the middle.
const PLATFORM_LAMP := 24.0


func _build_yard_platforms(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for pl: Dictionary in _yard.platforms:
		var pts: PackedVector2Array = pl["p"]
		var hl: PackedFloat32Array = pl["l"]
		var hr: PackedFloat32Array = pl["r"]
		var n := pts.size()
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var nms := PackedVector2Array()
		var ys := PackedFloat32Array()
		for k in n:
			var d := (pts[mini(k + 1, n - 1)] - pts[maxi(k - 1, 0)]).normalized()
			var nm := Vector2(-d.y, d.x)
			nms.append(nm)
			left.append(pts[k] + nm * hl[k])
			right.append(pts[k] - nm * hr[k])
			ys.append(terrain_height(pts[k].x, pts[k].y) + RailYard.HEIGHT)
		var run := 0.0
		for k in n - 1:
			var mid := (pts[k] + pts[k + 1]) * 0.5
			var seg := pts[k].distance_to(pts[k + 1])
			if _in_sector and not _sector_rect.has_point(mid):
				run += seg
				continue
			var y0 := ys[k]
			var y1 := ys[k + 1]
			_quad(st, Vector3(left[k].x, y0, left[k].y), Vector3(left[k + 1].x, y1, left[k + 1].y),
					Vector3(right[k + 1].x, y1, right[k + 1].y), Vector3(right[k].x, y0, right[k].y), Vector3.UP, PLATFORM_TILES)
			for side in 2:
				var e0 := left[k] if side == 0 else right[k]
				var e1 := left[k + 1] if side == 0 else right[k + 1]
				var in0 := -nms[k] if side == 0 else nms[k]
				var in1 := -nms[k + 1] if side == 0 else nms[k + 1]
				for band: Array in [[0.0, 0.35, PLATFORM_EDGE], [0.85, 0.99, PLATFORM_LINE], [1.1, 1.5, PLATFORM_TACTILE]]:
					var a0 := e0 + in0 * float(band[0])
					var a1 := e1 + in1 * float(band[0])
					var b0 := e0 + in0 * float(band[1])
					var b1 := e1 + in1 * float(band[1])
					_quad(st, Vector3(a0.x, y0 + 0.006, a0.y), Vector3(a1.x, y1 + 0.006, a1.y), Vector3(b1.x, y1 + 0.006, b1.y),
							Vector3(b0.x, y0 + 0.006, b0.y), Vector3.UP, band[2])
				var g0 := ys[k] - RailYard.HEIGHT - 0.3
				var g1 := ys[k + 1] - RailYard.HEIGHT - 0.3
				var out := Vector3(-in0.x - in1.x, 0.0, -in0.y - in1.y).normalized()
				_quad(st, Vector3(e0.x, g0, e0.y), Vector3(e1.x, g1, e1.y), Vector3(e1.x, y1, e1.y), Vector3(e0.x, y0, e0.y),
						out, PLATFORM_TILES.darkened(0.25))
			# A lamp where a multiple of PLATFORM_LAMP falls on this piece.
			var next := ceilf((run + 6.0) / PLATFORM_LAMP) * PLATFORM_LAMP - 6.0
			if next < run + seg and next >= run:
				var p := pts[k].lerp(pts[k + 1], (next - run) / seg)
				var y := lerpf(y0, y1, (next - run) / seg)
				_box_oriented(st, Vector3(p.x, y + 2.7, p.y), Basis.IDENTITY, Vector3(0.14, 5.4, 0.14), MAST_COL)
				_box_oriented(st, Vector3(p.x, y + 5.45, p.y), Basis(Vector3.UP, atan2(-nms[k].x, -nms[k].y)),
						Vector3(0.3, 0.16, 1.4), MAST_COL.darkened(0.2))
			run += seg
		# The two ends' faces.
		for k: int in [0, n - 1]:
			if _in_sector and not _sector_rect.has_point(pts[k]):
				continue
			var g := ys[k] - RailYard.HEIGHT - 0.3
			var d := (pts[mini(k + 1, n - 1)] - pts[maxi(k - 1, 0)]).normalized() * (-1.0 if k == 0 else 1.0)
			_quad(st, Vector3(left[k].x, g, left[k].y), Vector3(right[k].x, g, right[k].y), Vector3(right[k].x, ys[k], right[k].y),
					Vector3(left[k].x, ys[k], left[k].y), Vector3(d.x, 0.0, d.y), PLATFORM_TILES.darkened(0.25))
	for ring: PackedVector2Array in _yard.rings:
		var c := Vector2.ZERO
		for q in ring:
			c += q
		c /= ring.size()
		if _in_sector and not _sector_rect.has_point(c):
			continue
		_platform_slab(st, ring, RailYard.HEIGHT)
	_uv2 = Vector2.ZERO


## Station furniture (F, 2026-11-06: "the infrastructure for all the stations on my map, with
## people, trains stopping"): along every railway platform (OSM's 0.9 m slabs beside a track,
## rail_yard.gd's islands at Główna) lamp masts, glass shelters where no station roof stands
## over it, benches, bins and the blue station name boards. The benches and bins join the
## street's MultiMeshes (_build_props: no new draw call); the rest is built into the walls.
## The waiting people are trains.gd's (_gather).
const STATION_LAMP := 24.0
const STATION_BENCH := 16.0
const STATION_BOARD := 48.0
const STATION_SHELTER := 64.0
## A track this close beside a platform's edge: its side faces it.
const STATION_TRACK_SIDE := 4.0
const STATION_BOARD_COL := Color("#1d3c78")
const STATION_FRAME := Color("#3d4146")
const STATION_GLASS := Color("#9fbac6")
## Where a station's own roof covers its platforms (landmarks.gd): no shelter under it.
## Rect2s; Warszawa Wschodnia's platform roofs (WSC_CANOPY_X, to the map's edge), Stadion's
## canopies (STP_CANOPY from its hall), Ochota's saddle pavilion.
const STATION_ROOFED := [Rect2(1855.0, -2050.0, 270.0, 230.0), Rect2(1300.0, -1330.0, 100.0, 100.0),
		Rect2(-2335.0, 905.0, 45.0, 45.0)]
var _station_benches: Array[Transform3D] = []
var _station_bins: Array[Transform3D] = []


func _station_roofed(p: Vector2) -> bool:
	for r: Rect2 in STATION_ROOFED:
		if r.has_point(p):
			return true
	return false


func _build_station_furniture(st) -> void:
	_station_benches.clear()
	_station_bins.clear()
	var tracks := StationLines.tracks(Trains.trim_rails(data.get("rails", [])))
	_uv2 = Vector2(0.5, -1.0)
	for line: Array in StationLines.lines(data.get("platforms", []), tracks, _yard, terrain_height):
		var pts: PackedVector2Array = line[0]
		var tops: PackedFloat32Array = line[1]
		var halves: PackedFloat32Array = line[2]
		var cum := PackedFloat32Array([0.0])
		for k in pts.size() - 1:
			cum.append(cum[k] + pts[k].distance_to(pts[k + 1]))
		var total := cum[cum.size() - 1]
		if total < 25.0:
			continue
		# The shelters' places: the middle and every STATION_SHELTER either way.
		var shelters := PackedFloat32Array()
		var at := total * 0.5
		while at - STATION_SHELTER > 12.0:
			at -= STATION_SHELTER
		while at < total - 12.0:
			shelters.append(at)
			at += STATION_SHELTER
		var boards := PackedFloat32Array()
		at = 24.0
		while at < total - 8.0:
			boards.append(at)
			at += STATION_BOARD
		if not bool(line[3]):
			at = 6.0
			while at < total - 4.0:
				var f := _station_at(pts, tops, halves, cum, at)
				_station_lamp(st, f)
				at += STATION_LAMP
		for s in boards:
			_station_board(st, _station_at(pts, tops, halves, cum, s))
		var placed := PackedFloat32Array()
		for s in shelters:
			var f := _station_at(pts, tops, halves, cum, s)
			if float(f[3]) < 2.0 or _station_roofed(f[0]):
				continue
			_station_shelter(st, f, tracks)
			placed.append(s)
		at = 10.0
		var n := 0
		while at < total - 6.0:
			var clear := true
			for s in placed:
				clear = clear and absf(at - s) > 5.0
			for s in boards:
				clear = clear and absf(at - s) > 3.0
			if clear:
				_station_seat(_station_at(pts, tops, halves, cum, at), tracks, n % 2 == 0)
				n += 1
			at += STATION_BENCH
	_uv2 = Vector2.ZERO


## The platform at `s` along its centre line: [point, top, direction, half width].
func _station_at(pts: PackedVector2Array, tops: PackedFloat32Array, halves: PackedFloat32Array,
		cum: PackedFloat32Array, s: float) -> Array:
	var k := clampi(cum.bsearch(s) - 1, 0, pts.size() - 2)
	var f := clampf((s - cum[k]) / maxf(cum[k + 1] - cum[k], 0.01), 0.0, 1.0)
	return [pts[k].lerp(pts[k + 1], f), lerpf(tops[k], tops[k + 1], f), (pts[k + 1] - pts[k]).normalized(),
			lerpf(halves[k], halves[k + 1], f)]


## Which sides of the platform at `f` a track runs along: Vector2i(left, right), 1 for a track.
func _station_sides(f: Array, tracks: Array) -> Vector2i:
	var p: Vector2 = f[0]
	var d: Vector2 = f[2]
	var nm := Vector2(-d.y, d.x)
	var reach := float(f[3]) + 2.0
	return Vector2i(1 if StationLines.near_track(p + nm * reach, tracks) < STATION_TRACK_SIDE else 0,
			1 if StationLines.near_track(p - nm * reach, tracks) < STATION_TRACK_SIDE else 0)


func _station_lamp(st, f: Array) -> void:
	var p: Vector2 = f[0]
	if _in_sector and not _sector_rect.has_point(p):
		return
	var y := float(f[1])
	var d: Vector2 = f[2]
	_box_oriented(st, Vector3(p.x, y + 2.7, p.y), Basis.IDENTITY, Vector3(0.14, 5.4, 0.14), MAST_COL)
	_box_oriented(st, Vector3(p.x, y + 5.45, p.y), Basis(Vector3.UP, atan2(-d.x, -d.y) + PI * 0.5),
			Vector3(0.3, 0.16, 1.4), MAST_COL.darkened(0.2))


## The station's name board: a blue panel with a white band (the name's line) on two posts.
func _station_board(st, f: Array) -> void:
	var p: Vector2 = f[0]
	if _in_sector and not _sector_rect.has_point(p):
		return
	var y := float(f[1])
	var d: Vector2 = f[2]
	var b := Basis(Vector3.UP, atan2(-d.y, d.x))
	for sx: float in [-1.35, 1.35]:
		var q := p + d * sx
		_box_oriented(st, Vector3(q.x, y + 1.35, q.y), b, Vector3(0.08, 2.7, 0.08), STATION_FRAME)
	_box_oriented(st, Vector3(p.x, y + 2.55, p.y), b, Vector3(3.0, 0.62, 0.08), STATION_BOARD_COL)
	_box_oriented(st, Vector3(p.x, y + 2.55, p.y), b, Vector3(2.3, 0.12, 0.1), Color("#f2f2ee"))


## A platform shelter: a flat roof on four posts, a glass wall down the middle (across the back
## on a platform with a track on one side only), a bench on each open side.
func _station_shelter(st, f: Array, tracks: Array) -> void:
	var p: Vector2 = f[0]
	var y := float(f[1])
	var d: Vector2 = f[2]
	var nm := Vector2(-d.y, d.x)
	var sides := _station_sides(f, tracks)
	var half := minf(float(f[3]) - 0.9, 1.4)
	# One track: the glass along the far side, the roof leaning over the track side.
	var shift := 0.0
	if sides.x + sides.y == 1:
		shift = -half * 0.6 if sides.x == 1 else half * 0.6
	var b := Basis(Vector3.UP, atan2(-d.y, d.x))
	var wall := p + nm * shift
	if not (_in_sector and not _sector_rect.has_point(p)):
		_box_oriented(st, Vector3(p.x, y + 2.75, p.y), b, Vector3(6.4, 0.14, half * 2.0 + 0.6), STATION_FRAME)
		_box_oriented(st, Vector3(p.x, y + 2.83, p.y), b, Vector3(6.0, 0.04, half * 2.0 + 0.3), STATION_GLASS.darkened(0.15))
		for sx: float in [-2.9, 2.9]:
			for sz: float in [-half, half]:
				var q := p + d * sx + nm * sz
				_box_oriented(st, Vector3(q.x, y + 1.35, q.y), b, Vector3(0.1, 2.7, 0.1), STATION_FRAME)
		_box_oriented(st, Vector3(wall.x, y + 1.3, wall.y), b, Vector3(5.6, 2.0, 0.05), STATION_GLASS)
		_box_oriented(st, Vector3(wall.x, y + 0.1, wall.y), b, Vector3(5.7, 0.12, 0.08), STATION_FRAME)
	# The benches under it, facing out from the glass towards each track.
	var yaw := atan2(-d.y, d.x)
	for side: int in [1, -1]:
		if sides.x + sides.y == 1 and (side == 1) != (sides.x == 1):
			continue
		var q := wall + nm * side * 0.45
		_station_benches.append(Transform3D(Basis(Vector3.UP, yaw + (PI if side == 1 else 0.0)), Vector3(q.x, y, q.y)))


## Benches along the open platform: back to back on an island, facing the track on a side
## platform; a bin beside every other one.
func _station_seat(f: Array, tracks: Array, bin: bool) -> void:
	var p: Vector2 = f[0]
	var y := float(f[1])
	var d: Vector2 = f[2]
	var nm := Vector2(-d.y, d.x)
	if float(f[3]) < 1.7:
		return
	var sides := _station_sides(f, tracks)
	var yaw := atan2(-d.y, d.x)
	for side: int in [1, -1]:
		var one := sides.x + sides.y == 1
		if one and (side == 1) != (sides.x == 1):
			continue
		# On a side platform the bench stands back from the edge, towards the far side.
		var q := p + nm * side * (0.3 if not one else -minf(float(f[3]) - 1.6, 1.2))
		_station_benches.append(Transform3D(Basis(Vector3.UP, yaw + (PI if side == 1 else 0.0)), Vector3(q.x, y, q.y)))
	if bin:
		var q := p + d * 1.4
		_station_bins.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(q.x, y, q.y)))


## The rail footbridges' (_rail_bridges) glass parapets along their level run, and where one
## crosses a platform (rail_yard.gd's, a footway ring's, OSM's), a stair down to it along the
## platform and a glass lift shaft on the other side of the deck (F, 2026-11-06; the 2021
## street photos of the Główna kładka show concrete stair and lift towers onto each island).
const BRIDGE_GLASS := Color("#6f8791")
const BRIDGE_STEEL := Color("#4a4f55")
const STAIR_COL := Color("#9a9893")


func _build_footbridge_stairs(st) -> void:
	if _rail_bridges.is_empty():
		return
	_uv2 = Vector2(0.5, -1.0)
	# Each platform: [axis segments (pairs), top height].
	var plats: Array = []
	for pl: Dictionary in _yard.platforms:
		var pp: PackedVector2Array = pl["p"]
		plats.append([pp, false, -1.0])
	for ring: PackedVector2Array in _yard.rings:
		plats.append([ring, true, _min_ground(ring) + RailYard.HEIGHT])
	for a in data.get("platforms", []):
		if float(a["h"]) >= 0.7:
			var poly := _pts(a["p"])
			if poly.size() >= 3:
				plats.append([poly, true, _min_ground(poly) + float(a["h"]) + 0.1])
	for br: Dictionary in _rail_bridges:
		var pts: PackedVector2Array = br["pts"]
		var cum: PackedFloat32Array = br["cum"]
		var hs: PackedFloat32Array = br["h"]
		var a0: float = br["a"]
		var b0: float = br["b"]
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		# The parapets: a glass pane 1.15 m high on a steel kerb, a steel handrail on top.
		for k in pts.size() - 1:
			if cum[k + 1] < a0 or cum[k] > b0:
				continue
			var mid := (pts[k] + pts[k + 1]) * 0.5
			if _in_sector and not _sector_rect.has_point(mid):
				continue
			var d := pts[k + 1] - pts[k]
			if d.length() < 0.05:
				continue
			d = d.normalized()
			var nm := Vector2(-d.y, d.x)
			for side: float in [-1.0, 1.0]:
				var o := nm * side * 1.45
				var p0 := pts[k] + o
				var p1 := pts[k + 1] + o
				var y0 := hs[k]
				var y1 := hs[k + 1]
				var out := Vector3(nm.x * side, 0.0, nm.y * side)
				for nn: Vector3 in [out, -out]:
					_quad(st, Vector3(p0.x, y0 + 0.2, p0.y), Vector3(p1.x, y1 + 0.2, p1.y), Vector3(p1.x, y1 + 1.15, p1.y),
							Vector3(p0.x, y0 + 1.15, p0.y), nn, BRIDGE_GLASS)
					_quad(st, Vector3(p0.x, y0 - 0.45, p0.y), Vector3(p1.x, y1 - 0.45, p1.y), Vector3(p1.x, y1 + 0.2, p1.y),
							Vector3(p0.x, y0 + 0.2, p0.y), nn, BRIDGE_STEEL)
				var c := (p0 + p1) * 0.5
				_box_oriented(st, Vector3(c.x, (y0 + y1) * 0.5 + 1.2, c.y), Basis(Vector3.UP, atan2(d.x, d.y)),
						Vector3(0.08, 0.1, p0.distance_to(p1) + 0.05), BRIDGE_STEEL)
		# Stairs and lifts onto the platforms it crosses.
		for plat: Array in plats:
			var poly: PackedVector2Array = plat[0]
			var closed: bool = plat[1]
			var pb := Rect2(poly[0], Vector2.ZERO)
			for q in poly:
				pb = pb.expand(q)
			if not pb.grow(2.0).intersects(box):
				continue
			var hits: Array = []  # [point, edge direction, along the bridge]
			var m := poly.size() if closed else poly.size() - 1
			for e in m:
				var e0 := poly[e]
				var e1 := poly[(e + 1) % poly.size()]
				for k in pts.size() - 1:
					var x: Variant = Geometry2D.segment_intersects_segment(pts[k], pts[k + 1], e0, e1)
					if x != null:
						hits.append([x, (e1 - e0).normalized(), cum[k] + pts[k].distance_to(x)])
			if hits.is_empty():
				continue
			var at := Vector2.ZERO
			var along := 0.0
			for hh: Array in hits:
				at += hh[0]
				along += float(hh[2])
			at /= hits.size()
			along /= hits.size()
			if along < a0 or along > b0:
				continue
			if _in_sector and not _sector_rect.has_point(at):
				continue
			var axis: Vector2 = hits[0][1]
			var top := float(plat[2]) if float(plat[2]) >= 0.0 else terrain_height(at.x, at.y) + RailYard.HEIGHT
			var k := cum.bsearch(along) - 1
			k = clampi(k, 0, pts.size() - 2)
			var level := lerpf(hs[k], hs[k + 1], clampf((along - cum[k]) / maxf(cum[k + 1] - cum[k], 0.01), 0.0, 1.0))
			_platform_stair(st, at, axis, top, level)
			_lift_shaft(st, at - axis * 3.2, axis, top, level)
	_uv2 = Vector2.ZERO


func _min_ground(poly: PackedVector2Array) -> float:
	var g := INF
	for q in poly:
		g = minf(g, terrain_height(q.x, q.y))
	return g


## A stair from the deck (level `level` at `at`) down along `axis` onto the platform top `top`:
## treads 0.17 m by 0.3 m, 2.4 m wide, glass side panes, a steel stringer.
func _platform_stair(st, at: Vector2, axis: Vector2, top: float, level: float) -> void:
	var rise := level - top
	if rise < 1.0:
		return
	var n := ceili(rise / 0.17)
	var tread := 0.3
	var start := at + axis * 1.6
	var basis := Basis(Vector3.UP, atan2(axis.x, axis.y))
	var side := Vector2(-axis.y, axis.x)
	for j in n:
		var y := level - (j + 1) * rise / n
		var c := start + axis * (tread * (j + 0.5))
		_box_oriented(st, Vector3(c.x, y - 0.2 + rise / n * 0.5, c.y), basis, Vector3(2.4, 0.4 + rise / n, tread + 0.02), STAIR_COL)
	var end := start + axis * tread * n
	for sd: float in [-1.0, 1.0]:
		var o := side * sd * 1.22
		var p0 := start + o
		var p1 := end + o
		var nn := Vector3(side.x * sd, 0.0, side.y * sd)
		for nf: Vector3 in [nn, -nn]:
			_quad(st, Vector3(p0.x, level - 0.5, p0.y), Vector3(p1.x, top - 0.5, p1.y), Vector3(p1.x, top + 1.0, p1.y),
					Vector3(p0.x, level + 1.0, p0.y), nf, BRIDGE_GLASS)
	# The landing under the deck's edge.
	_box_oriented(st, Vector3(at.x + axis.x * 0.8, level - 0.2, at.y + axis.y * 0.8), basis, Vector3(2.6, 0.4, 1.8), STAIR_COL)


## A lift shaft by the deck: a glass box on steel corners from the platform `top` to over the
## deck, its machine room a dark cap.
func _lift_shaft(st, c: Vector2, axis: Vector2, top: float, level: float) -> void:
	var basis := Basis(Vector3.UP, atan2(axis.x, axis.y))
	var h := level + 3.0 - top
	_box_oriented(st, Vector3(c.x, top + h * 0.5, c.y), basis, Vector3(2.3, h, 2.3), BRIDGE_GLASS.darkened(0.15))
	for cx: float in [-1.15, 1.15]:
		for cz: float in [-1.15, 1.15]:
			var q := c + Vector2(-axis.y, axis.x) * cx + axis * cz
			_box_oriented(st, Vector3(q.x, top + h * 0.5, q.y), basis, Vector3(0.16, h + 0.02, 0.16), BRIDGE_STEEL)
	_box_oriented(st, Vector3(c.x, level + 3.1, c.y), basis, Vector3(2.5, 0.4, 2.5), BRIDGE_STEEL.darkened(0.2))
	# The bridge from the deck's edge to the lift's door.
	var d := c + axis * 1.6
	_box_oriented(st, Vector3(d.x, level - 0.2, d.y), basis, Vector3(2.0, 0.4, 1.4), STAIR_COL)


## A railway platform's slab on polygon `poly`, `h` over its lowest ground: tiles, the white
## edge band, the yellow line 0.9 m in and the tactile strip, its sides down to the ballast.
func _platform_slab(st, poly: PackedVector2Array, h: float) -> void:
	var ground := INF
	for q in poly:
		ground = minf(ground, terrain_height(q.x, q.y))
	var top := ground + h
	_fill(st, poly, top, PLATFORM_TILES)
	var ring := poly.duplicate()
	ring.append(poly[0])
	_strip(st, ring, 0.35, top + 0.006, PLATFORM_EDGE, false)
	for inset: Array in [[-0.9, 0.14, PLATFORM_LINE], [-1.25, 0.4, PLATFORM_TACTILE]]:
		for inner: PackedVector2Array in Geometry2D.offset_polygon(poly, float(inset[0]), Geometry2D.JOIN_MITER):
			if Geometry2D.is_polygon_clockwise(inner):
				continue
			var loop := inner.duplicate()
			loop.append(inner[0])
			_strip(st, loop, float(inset[1]), top + 0.01, inset[2], false)
	for i in poly.size():
		var p0 := poly[i]
		var p1 := poly[(i + 1) % poly.size()]
		var e := p1 - p0
		if e.length() < 0.05:
			continue
		var n := Vector3(e.y, 0.0, -e.x).normalized()
		_quad(st, Vector3(p0.x, ground - 0.3, p0.y), Vector3(p1.x, ground - 0.3, p1.y), Vector3(p1.x, top, p1.y),
				Vector3(p0.x, top, p0.y), n, PLATFORM_TILES.darkened(0.25))


## The railway's tunnel mouths (L3 of docs/design/railway.md): where the cross-city tunnel's
## tracks end in the map (west of Ochota's cutting, under Powiśle's upper pavilion, trains.gd
## PORTALS), a concrete headwall over a dark mouth 6.4 m high (the catenary's height), two
## posts and the dark back a few metres in, across all the tracks that end there. The trains
## slide in and out of it (trains.gd cuts them at the tracks' ends).
const RAIL_MOUTH := 6.4


func _build_rail_portals(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for q: Vector2 in Trains.PORTALS:
		if _in_sector and not _sector_rect.has_point(q):
			continue  # a sector holds every rail it touches whole: one sector owns each mouth
		var ends := PackedVector2Array()
		var dir := Vector2.ZERO
		var y := INF
		for r in Trains.trim_rails(data.get("rails", [])):
			var poly := _pts(r["p"])
			if poly.size() < 2:
				continue
			for k: int in [0, poly.size() - 1]:
				if poly[k].distance_to(q) < Trains.PORTAL_R:
					ends.append(poly[k])
					var inner := poly[1] if k == 0 else poly[poly.size() - 2]
					dir += (poly[k] - inner).normalized()
					y = minf(y, deck_height(int(r.get("dk", -1)), poly[k].x, poly[k].y))
		if ends.size() < 2 or dir.length() < 0.5:
			continue
		var d := dir.normalized()
		var side := Vector2(-d.y, d.x)
		var lo := INF
		var hi := -INF
		var along := -INF
		var c := Vector2.ZERO
		for e in ends:
			c += e
		c /= ends.size()
		for e in ends:
			lo = minf(lo, (e - c).dot(side))
			hi = maxf(hi, (e - c).dot(side))
			along = maxf(along, (e - c).dot(d))
		var mid := c + side * (lo + hi) * 0.5 + d * along
		var w := hi - lo + 5.0
		var inside := mid + d * 10.0
		var top := maxf(terrain_height(inside.x, inside.y), y + RAIL_MOUTH + 1.0) + 0.5
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var head := mid + d * 0.6
		_box_oriented(st, Vector3(head.x, (y + RAIL_MOUTH + top) * 0.5, head.y), basis,
				Vector3(w + 2.4, top - y - RAIL_MOUTH, 1.2), PORTAL_CONCRETE)
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = head + side * sgn * (w * 0.5 + 0.6)
			_box_oriented(st, Vector3(p.x, (y - 0.5 + top) * 0.5, p.y), basis, Vector3(1.2, top - y + 0.5, 1.2),
					PORTAL_CONCRETE.darkened(0.06))
		var back := mid + d * 3.5
		var l0 := back - side * w * 0.5
		var r0 := back + side * w * 0.5
		_quad(st, Vector3(l0.x, y - 0.3, l0.y), Vector3(r0.x, y - 0.3, r0.y), Vector3(r0.x, y + RAIL_MOUTH, r0.y),
				Vector3(l0.x, y + RAIL_MOUTH, l0.y), Vector3(-d.x, 0.0, -d.y), PORTAL_DARK)
		# The mouth's inner walls and roof, from the headwall to the dark back.
		for sgn in [-1.0, 1.0]:
			var a: Vector2 = mid + side * sgn * w * 0.5
			var b: Vector2 = back + side * sgn * w * 0.5
			var n := Vector3(-side.x * sgn, 0.0, -side.y * sgn)
			_quad(st, Vector3(a.x, y - 0.3, a.y), Vector3(b.x, y - 0.3, b.y), Vector3(b.x, y + RAIL_MOUTH, b.y),
					Vector3(a.x, y + RAIL_MOUTH, a.y), n, PORTAL_DARK.lightened(0.1))
		var la := mid - side * w * 0.5
		var ra := mid + side * w * 0.5
		_quad(st, Vector3(la.x, y + RAIL_MOUTH, la.y), Vector3(ra.x, y + RAIL_MOUTH, ra.y), Vector3(r0.x, y + RAIL_MOUTH, r0.y),
				Vector3(l0.x, y + RAIL_MOUTH, l0.y), Vector3.DOWN, PORTAL_DARK)
	_uv2 = Vector2.ZERO


## The railway's overhead line (L2 of docs/design/railway.md): a steel mast where a track crosses
## a CATENARY_STEP grid line (so masts stand in step on parallel tracks and in every sector alike),
## on the track's outer side (the side with no other track within reach), its arm out over the
## track, and the contact wire along every track 5.6 m over the rails. Into the walls' surface
## (no draw call of its own); not solid (the car never reaches the tracks' sides at that height).
const CATENARY_STEP := 55.0
const CATENARY_H := 5.6
const MAST_H := 7.4
const MAST_OUT := 2.9
const MAST_COL := Color("#6c7176")
const WIRE_COL := Color("#2a2c2f")


func _build_catenary(st) -> void:
	var rails: Array = Trains.trim_rails(data.get("rails", []))
	if rails.is_empty():
		return
	_uv2 = Vector2(0.5, -1.0)
	var crossings := {}
	# Every track's segments in 8 m cells, to find a neighbouring track beside a mast.
	var grid := {}
	for r in rails:
		var poly := _pts(r["p"])
		for i in poly.size() - 1:
			for p: Vector2 in [poly[i], poly[i + 1], (poly[i] + poly[i + 1]) * 0.5]:
				var key := Vector2i(floori(p.x / 8.0), floori(p.y / 8.0))
				var segs: PackedVector2Array = grid.get(key, PackedVector2Array())
				segs.append_array(PackedVector2Array([poly[i], poly[i + 1]]))
				grid[key] = segs
	for r in rails:
		var poly := _pts(r["p"])
		var dk := int(r.get("dk", -1))
		for i in poly.size() - 1:
			var a := poly[i]
			var b := poly[i + 1]
			var len := a.distance_to(b)
			if len < 0.05:
				continue
			var d := (b - a) / len
			var n := Vector2(-d.y, d.x)
			# The wire, in pieces of up to 10 m, each end at the rails' height.
			var pieces := maxi(1, ceili(len / 10.0))
			for k in pieces:
				var p0 := a.lerp(b, float(k) / pieces)
				var p1 := a.lerp(b, float(k + 1) / pieces)
				if _in_sector and not _sector_rect.has_point((p0 + p1) * 0.5):
					continue  # the sector holding the piece's middle draws it
				var y0 := deck_height(dk, p0.x, p0.y) + CATENARY_H
				var y1 := deck_height(dk, p1.x, p1.y) + CATENARY_H
				var w := n * 0.05
				_quad(st, Vector3(p0.x - w.x, y0, p0.y - w.y), Vector3(p1.x - w.x, y1, p1.y - w.y),
						Vector3(p1.x + w.x, y1, p1.y + w.y), Vector3(p0.x + w.x, y0, p0.y + w.y), Vector3.UP, WIRE_COL)
			# Masts where the segment crosses a grid line across it.
			var axis := 0 if absf(d.x) >= absf(d.y) else 1
			var u0 := a[axis]
			var u1 := b[axis]
			var g0 := ceili(minf(u0, u1) / CATENARY_STEP)
			var g1 := floori(maxf(u0, u1) / CATENARY_STEP)
			for g in range(g0, g1 + 1):
				var t := (g * CATENARY_STEP - u0) / (u1 - u0) if absf(u1 - u0) > 0.001 else 0.0
				var p := a.lerp(b, clampf(t, 0.0, 1.0))
				var key := Vector3i(axis, g, dk)
				var list: Array = crossings.get(key, [])
				list.append([p, n, d, deck_height(dk, p.x, p.y)])
				crossings[key] = list
	# Each grid line's crossings in rows across the tracks: two or more tracks side by side get a
	# portal (a mast beyond each outer track and a lattice beam over them all, F 2026-11-06: the
	# masts stood only beside the outer tracks and the wires over the inner ones hung from
	# nothing), a lone track its mast on its free side.
	for key: Vector3i in crossings:
		var list: Array = crossings[key]
		var along := 1 - key.x  # the grid line runs along the other axis
		list.sort_custom(func(l: Array, r: Array) -> bool: return (l[0] as Vector2)[along] < (r[0] as Vector2)[along])
		var row: Array = []
		for k in list.size() + 1:
			if k < list.size() and (row.is_empty() or (list[k][0] as Vector2).distance_to(row[row.size() - 1][0]) < GANTRY_GAP):
				row.append(list[k])
				continue
			if row.size() >= 2:
				_gantry(st, row)
			elif row.size() == 1:
				var p: Vector2 = row[0][0]
				var n: Vector2 = row[0][1]
				if not _in_sector or _sector_rect.has_point(p):
					var free := [not _track_near(grid, p + n * 4.5, 2.5), not _track_near(grid, p - n * 4.5, 2.5)]
					if free[0] or free[1]:
						_mast(st, p, n * (1.0 if free[0] else -1.0), row[0][2], row[0][3])
			row = [] if k >= list.size() else [list[k]]
	_uv2 = Vector2.ZERO


## Tracks this close where they cross a grid line share a portal.
const GANTRY_GAP := 9.0


## A portal over a row of tracks ([point, normal, dir, rails' height] each, in order across): a
## lattice mast MAST_OUT beyond each outer track, two chords between them over the wires with
## verticals and diagonals, and a dropper down to each track's wire.
func _gantry(st, row: Array) -> void:
	var first: Vector2 = row[0][0]
	var last: Vector2 = row[row.size() - 1][0]
	var mid := (first + last) * 0.5
	if _in_sector and not _sector_rect.has_point(mid):
		return
	var across := (last - first).normalized()
	var y := -INF
	for r: Array in row:
		y = maxf(y, float(r[3]))
	var a := first - across * MAST_OUT
	var b := last + across * MAST_OUT
	var span := a.distance_to(b)
	var d: Vector2 = row[0][2]
	var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
	var beam_basis := Basis(Vector3.UP, atan2(-across.x, -across.y))
	var lo := y + CATENARY_H + 0.9
	var hi := y + CATENARY_H + 1.7
	for p: Vector2 in [a, b]:
		var foot := minf(terrain_height(p.x, p.y), y)
		_box_oriented(st, Vector3(p.x, (foot - 0.3 + hi + 0.2) * 0.5, p.y), basis, Vector3(0.45, hi + 0.5 - foot, 0.45), MAST_COL)
		_box_oriented(st, Vector3(p.x, foot + 0.15, p.y), basis, Vector3(0.9, 0.5, 0.9), PORTAL_CONCRETE)
	var c := (a + b) * 0.5
	for h: float in [lo, hi]:
		_box_oriented(st, Vector3(c.x, h, c.y), beam_basis, Vector3(0.14, 0.14, span), MAST_COL.darkened(0.1))
	# The lattice: a vertical every ~1.6 m, a diagonal in every other bay.
	var bays := maxi(2, roundi(span / 1.6))
	for k in bays + 1:
		var p := a.lerp(b, float(k) / bays)
		_box_oriented(st, Vector3(p.x, (lo + hi) * 0.5, p.y), beam_basis, Vector3(0.07, hi - lo, 0.07), MAST_COL.darkened(0.1))
		if k < bays and k % 2 == 0:
			var q := a.lerp(b, float(k + 1) / bays)
			var m := (p + q) * 0.5
			var len := sqrt(p.distance_squared_to(q) + (hi - lo) * (hi - lo))
			var tilt := Basis(Vector3.UP, atan2(-across.x, -across.y)) * Basis(Vector3.RIGHT, atan2(hi - lo, p.distance_to(q)))
			_box_oriented(st, Vector3(m.x, (lo + hi) * 0.5, m.y), tilt, Vector3(0.06, 0.06, len), MAST_COL.darkened(0.1))
	for r: Array in row:
		var p: Vector2 = r[0]
		var wy := float(r[3]) + CATENARY_H
		_box_oriented(st, Vector3(p.x, (wy + lo) * 0.5, p.y), basis, Vector3(0.05, lo - wy, 0.05), WIRE_COL)
		_box_oriented(st, Vector3(p.x, wy + 0.15, p.y), basis, Vector3(0.06, 0.06, 1.4), WIRE_COL)


func _track_near(grid: Dictionary, p: Vector2, reach: float) -> bool:
	var segs: PackedVector2Array = grid.get(Vector2i(floori(p.x / 8.0), floori(p.y / 8.0)), PackedVector2Array())
	for i in range(0, segs.size(), 2):
		var a := segs[i]
		var ab := segs[i + 1] - a
		var l2 := ab.length_squared()
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
		if p.distance_to(a + ab * t) < reach:
			return true
	return false


## One mast `out` of the track at p (rails at height y): an H-section post, the arm back over the
## track at the wire's height and a stay above it.
func _mast(st, p: Vector2, out: Vector2, d: Vector2, y: float) -> void:
	var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
	var foot := p + out * MAST_OUT
	_box_oriented(st, Vector3(foot.x, y + MAST_H * 0.5 - 0.3, foot.y), basis, Vector3(0.32, MAST_H + 0.6, 0.32), MAST_COL)
	var arm := basis.rotated(Vector3.UP, 0.0)
	var mid := p + out * MAST_OUT * 0.5
	var sideways := Basis(Vector3.UP, atan2(-out.x, -out.y))
	_box_oriented(st, Vector3(mid.x, y + CATENARY_H + 0.35, mid.y), sideways, Vector3(0.12, 0.12, MAST_OUT + 0.4), MAST_COL.darkened(0.15))
	_box_oriented(st, Vector3(mid.x, y + CATENARY_H + 1.2, mid.y), sideways, Vector3(0.08, 0.08, MAST_OUT + 0.2), MAST_COL.darkened(0.15))
	_box_oriented(st, Vector3(p.x, y + CATENARY_H + 0.2, p.y), arm, Vector3(0.06, 0.4, 0.06), WIRE_COL)


## Railway L4 (Mac photo check 2026-11-01): Most Średnicowy, the cross-city line's bridge over
## the Vistula. The real one is steel arch-truss spans (a shallow arch for the bottom chord,
## verticals and diagonals under the deck) on a few massive stone piers; the bake gives it the
## rows of thin piers every road bridge gets. Over the river and the Praga floodplain those are
## skipped (`_srednicowy_skips`) and this draws granite piers with cutwaters and the trusses
## between them, in the walls surface (no new draw calls). Found from the deck piece that starts
## at MS_A; a bake without it keeps the thin piers.
const MS_A := Vector2(746.8, -389.1)
## Along the bridge from MS_A: the stone piers (the bake's pier rows at 96, 172 ... 476 m).
const MS_PIERS: Array[float] = [96.0, 172.0, 248.0, 324.0, 400.0, 476.0]
## Across it (from MS_A's track, + towards the north-east side): the four truss planes, two per
## pair of tracks, and the piers' sides.
const MS_TRUSS: Array[float] = [-10.9, -3.5, -1.3, 5.7]
const MS_SIDE := Vector2(-13.0, 7.8)
const MS_HALF := 3.5        ## half a pier's thickness along the bridge
const MS_DEPTH_END := 8.0   ## truss depth over a pier (the arch's springing)
const MS_DEPTH_MID := 2.4   ## and at mid-span (the arch's crown)
const MS_PANELS := 10
const MS_STEEL := Color("#58625d")
const MS_STONE := Color("#a59d90")


## The bridge's frame [origin, along, across, deck group], or [] when the bake has no such deck.
func _srednicowy_frame() -> Array:
	for d: Dictionary in _decks:
		if d["k"] != "rail":
			continue
		var pts: PackedVector2Array = d["pts"]
		if pts[0].distance_to(MS_A) < 2.0 and pts[0].distance_to(pts[pts.size() - 1]) > 400.0:
			var u := (pts[pts.size() - 1] - pts[0]).normalized()
			return [pts[0], u, Vector2(-u.y, u.x), int(d["g"])]
	return []


## True for a bake pier the stone piers and trusses replace.
func _srednicowy_skips(f: Array, c: Vector2) -> bool:
	if f.is_empty():
		return false
	var q: Vector2 = c - f[0]
	var s: float = q.dot(f[1])
	var t: float = q.dot(f[2])
	return s > MS_PIERS[0] - 20.0 and s < MS_PIERS[MS_PIERS.size() - 1] + 20.0 and t > MS_SIDE.x - 2.0 and t < MS_SIDE.y + 2.0


func _build_srednicowy(st) -> void:
	var f := _srednicowy_frame()
	if f.is_empty():
		return
	_uv2 = Vector2(0.5, -1.0)
	var o: Vector2 = f[0]
	var u: Vector2 = f[1]
	var n: Vector2 = f[2]
	var g: int = f[3]
	var u3 := Vector3(u.x, 0.0, u.y)
	var n3 := Vector3(n.x, 0.0, n.y)
	var mid_t := (MS_SIDE.x + MS_SIDE.y) * 0.5
	for s: float in MS_PIERS:
		var c := o + u * s + n * mid_t
		if _in_sector and not _sector_rect.has_point(c):
			continue
		var top := deck_height(g, c.x, c.y) - 1.4 - MS_DEPTH_END - 0.45
		_ms_pier(st, o, u, n, s, top)
	for k in MS_PIERS.size() - 1:
		var s0: float = MS_PIERS[k] + MS_HALF
		var s1: float = MS_PIERS[k + 1] - MS_HALF
		for t: float in MS_TRUSS:
			var tops: Array[Vector3] = []
			var bots: Array[Vector3] = []
			for i in MS_PANELS + 1:
				var a := float(i) / MS_PANELS
				var p := o + u * lerpf(s0, s1, a) + n * t
				var yt := deck_height(g, p.x, p.y) - 1.4
				var depth := MS_DEPTH_MID + (MS_DEPTH_END - MS_DEPTH_MID) * pow(2.0 * a - 1.0, 2.0)
				tops.append(Vector3(p.x, yt, p.y))
				bots.append(Vector3(p.x, yt - depth, p.y))
			for i in MS_PANELS:
				var m := (tops[i] + bots[i + 1]) * 0.5
				if _in_sector and not _sector_rect.has_point(Vector2(m.x, m.z)):
					continue  # the sector holding the panel's middle draws it
				_ms_strut(st, tops[i] + Vector3.DOWN * 0.4, tops[i + 1] + Vector3.DOWN * 0.4, 0.6, 0.8, n3)
				_ms_strut(st, bots[i], bots[i + 1], 0.7, 0.9, n3)
				if i > 0:
					_ms_strut(st, bots[i], tops[i], 0.45, 0.45, n3)
				# Diagonals falling towards mid-span, as in a Pratt truss.
				if i * 2 < MS_PANELS:
					_ms_strut(st, tops[i], bots[i + 1], 0.35, 0.35, n3)
				else:
					_ms_strut(st, bots[i], tops[i + 1], 0.35, 0.35, n3)
			# The end posts over the piers.
			for i in [0, MS_PANELS]:
				var e: Vector3 = bots[i]
				if not _in_sector or _sector_rect.has_point(Vector2(e.x, e.z)):
					_ms_strut(st, bots[i] + Vector3.DOWN * 0.45, tops[i], 0.7, 0.7, n3)
		# Cross beams between each pair's two planes at the bottom chord, every other panel point.
		for pair in [[MS_TRUSS[0], MS_TRUSS[1]], [MS_TRUSS[2], MS_TRUSS[3]]]:
			for i in range(1, MS_PANELS, 2):
				var a := float(i) / MS_PANELS
				var s := lerpf(s0, s1, a)
				var p0 := o + u * s + n * float(pair[0])
				var p1 := o + u * s + n * float(pair[1])
				var pm := (p0 + p1) * 0.5
				if _in_sector and not _sector_rect.has_point(pm):
					continue
				var depth := MS_DEPTH_MID + (MS_DEPTH_END - MS_DEPTH_MID) * pow(2.0 * a - 1.0, 2.0)
				var y := deck_height(g, pm.x, pm.y) - 1.4 - depth
				_ms_strut(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), 0.4, 0.5, u3)
	_uv2 = Vector2.ZERO


## A steel member from a to b, w wide (along `side`, horizontal) and h deep.
func _ms_strut(st, a: Vector3, b: Vector3, w: float, h: float, side: Vector3) -> void:
	var z := b - a
	var length := z.length()
	if length < 0.05:
		return
	z /= length
	var x := (side - z * side.dot(z)).normalized()
	var basis := Basis(x, z.cross(x), z)
	_box_oriented(st, (a + b) * 0.5, basis, Vector3(w, h, length), MS_STEEL)


## One granite pier at s along the bridge, from below the ground to `top`: a long block across
## the bridge's whole width with a pointed cutwater at each end, a paler cap, solid for the car.
func _ms_pier(st, o: Vector2, u: Vector2, n: Vector2, s: float, top: float) -> void:
	var local := [Vector2(-MS_HALF, MS_SIDE.x), Vector2(0.0, MS_SIDE.x - 2.5), Vector2(MS_HALF, MS_SIDE.x),
			Vector2(MS_HALF, MS_SIDE.y), Vector2(0.0, MS_SIDE.y + 2.5), Vector2(-MS_HALF, MS_SIDE.y)]
	var c := o + u * s + n * (MS_SIDE.x + MS_SIDE.y) * 0.5
	var ground := INF
	var poly := PackedVector2Array()
	var cap := PackedVector2Array()
	for q: Vector2 in local:
		var p := o + u * (s + q.x) + n * q.y
		poly.append(p)
		cap.append(p + (p - c).normalized() * 0.45)
		ground = minf(ground, terrain_height(p.x, p.y))
	var y0 := ground - 1.5
	var y1 := top - 0.7
	for ring in [[poly, y0, y1, MS_STONE], [cap, y1, top, MS_STONE.lightened(0.12)]]:
		var pts: PackedVector2Array = ring[0]
		var lo: float = ring[1]
		var hi: float = ring[2]
		var col: Color = ring[3]
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			var e := (b - a).normalized()
			var nn := Vector2(e.y, -e.x)
			if nn.dot((a + b) * 0.5 - c) < 0.0:
				nn = -nn
			# Courses: the shaft in bands a shade apart every 1.2 m, as dressed stone reads.
			var y := lo
			var band := 0
			while y < hi - 0.01:
				var y2 := minf(y + 1.2, hi) if pts == poly else hi
				var shade := col.darkened(0.06) if band % 2 == 1 else col
				_quad(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(b.x, y2, b.y), Vector3(a.x, y2, a.y),
						Vector3(nn.x, 0.0, nn.y), shade)
				y = y2
				band += 1
		_fill(st, pts, hi, col.lightened(0.05))
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		_wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, top, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y)])


## Most Poniatowskiego's river spans (CITY_INVENTORY #14), from the Mac photo set (report
## docs/landmarks/photo-reports/poniatowski.md, spec docs/landmarks/specs/poniatowski.md): a
## steel deck-arch bridge, 506 m (Szyller, Marszewski and Paszkowski, 1914; the spans rebuilt
## after 1915 and 1944). The bake gives it pairs of thin concrete posts every 38 m like any road
## bridge; over the river those are skipped (`_poniatowski_skips`) and this draws the grey granite
## piers with rounded cutwaters and, between them, grey steel open-web arch ribs under the deck
## (the rib, posts and diagonal bracing up to a straight deck girder), the red fascia girder and
## the black cast-iron balustrade along both edges, and over each pier a granite pedestal with
## a cartouche standing out of the railing; in the walls surface (no new draw call).
## Found from the north carriageway's deck piece that starts at PN_A; a bake without it keeps the
## thin posts. The towers on the abutments are landmarks.gd's (`_build_towers`).
const PN_A := Vector2(939.4, -132.6)
## From PN_A to the bridge's frame: along it back to the west towers' line, across to its axis.
const PN_BACK := 8.9
const PN_AXIS := -6.67
## Along the bridge from the west towers' line (the east towers stand at 515.6 m): the abutments'
## river faces (the stone walls the bake seats there) and the river piers. The report reads three
## pier centres off the orthophoto, (1036, -171), (1106, -195), (1178, -219), and estimates two
## more on the east floodplain every ~72 m in x, (1250, -243), (1322, -267); the gravel rubble
## OpenStreetMap maps round piers (s 163-195, 252-276) and the terrain grid's ridges (s 178, 265)
## agree. F's look check (2026-11-03): the bridge has 8 spans, so 7 piers. The Mac's check of photos
## 22 and 1 and the ortho (/mnt/project-files/poniatowski_piers.md) found the west-bank pier at the
## waterline under a coat-of-arms pedestal, about (985, -159) ±8 m (s ~58): it stands at s 64, the
## nearest place within that clear of the bank promenade's footway and cycle path (measured with the
## piers' outline +0.4 m); the 7th on the east floodplain, about (1375, -284) ±15 m (s 467, clear).
const PN_ENDS := Vector2(6.0, 509.5)
const PN_PIERS: Array[float] = [64.0, 109.9, 183.9, 259.8, 335.7, 411.6, 467.0]
## Across the bridge from its axis (+ towards the south): the four girder planes (under the
## footways' outer edges and between the carriageways and the tram tracks) and the piers' sides.
const PN_GIRDERS: Array[float] = [-12.4, -4.6, 4.6, 12.4]
const PN_SIDE := 12.0       ## the pier's straight sides end here; the cutwaters round past them
## The deck's outer edges (the walks' outer parapets, map_builder's deck pieces: the walk's
## half width + 1.6 m), north and south: the fascia girder and the railing on them.
const PN_EDGE := Vector2(-14.7, 14.45)
const PN_RAIL_STEP := 2.4
const PN_HALF := 4.5        ## half a pier's thickness along the bridge (photo 29: ~9 m)
const PN_SLAB := 1.3        ## the deck's road surface over the girders' top chord
const PN_DEPTH_END := 7.5   ## girder depth at a pier (the arch's springing)
const PN_DEPTH_MID := 1.6   ## and at mid-span (the arch's crown)
const PN_PANELS := 12
const PN_STEEL := Color("#7c8288")
const PN_STONE := Color("#9c9a94")
const PN_FASCIA := Color("#b8484e")
const PN_IRON := Color("#1f1f22")


## The bridge's frame [origin on its axis at the west towers, along, across, deck group], or []
## when the bake has no such deck.
func _poniatowski_frame() -> Array:
	for d: Dictionary in _decks:
		if d["k"] != "road":
			continue
		var pts: PackedVector2Array = d["pts"]
		if pts[0].distance_to(PN_A) < 2.0 and pts[0].distance_to(pts[pts.size() - 1]) > 400.0:
			var u := (pts[pts.size() - 1] - pts[0]).normalized()
			var n := Vector2(-u.y, u.x)
			return [pts[0] - u * PN_BACK + n * PN_AXIS, u, n, int(d["g"])]
	return []


## True for a bake pier the stone piers and arch girders replace (the river part).
func _poniatowski_skips(f: Array, c: Vector2) -> bool:
	if f.is_empty():
		return false
	var q: Vector2 = c - f[0]
	var s: float = q.dot(f[1])
	var t: float = q.dot(f[2])
	return s > PN_ENDS.x and s < PN_ENDS.y and absf(t) < PN_SIDE + PN_HALF + 2.0


func _build_poniatowski(st) -> void:
	var f := _poniatowski_frame()
	if f.is_empty():
		return
	_uv2 = Vector2(0.5, -1.0)
	var o: Vector2 = f[0]
	var u: Vector2 = f[1]
	var n: Vector2 = f[2]
	var g: int = f[3]
	var u3 := Vector3(u.x, 0.0, u.y)
	var n3 := Vector3(n.x, 0.0, n.y)
	for s: float in PN_PIERS:
		var c := o + u * s
		if _in_sector and not _sector_rect.has_point(c):
			continue
		var top := INF
		for t: float in PN_GIRDERS:
			var p := o + u * s + n * t
			top = minf(top, deck_height(g, p.x, p.y) - PN_SLAB - PN_DEPTH_END - 0.45)
		_pn_pier(st, o, u, n, s, top)
	var stops: Array[float] = [PN_ENDS.x]
	for s: float in PN_PIERS:
		stops.append(s - PN_HALF)
		stops.append(s + PN_HALF)
	stops.append(PN_ENDS.y)
	for k in range(0, stops.size(), 2):
		var s0: float = stops[k]
		var s1: float = stops[k + 1]
		for t: float in PN_GIRDERS:
			var tops: Array[Vector3] = []
			var bots: Array[Vector3] = []
			for i in PN_PANELS + 1:
				var a := float(i) / PN_PANELS
				var p := o + u * lerpf(s0, s1, a) + n * t
				var yt := deck_height(g, p.x, p.y) - PN_SLAB
				var depth := PN_DEPTH_MID + (PN_DEPTH_END - PN_DEPTH_MID) * pow(2.0 * a - 1.0, 2.0)
				tops.append(Vector3(p.x, yt, p.y))
				bots.append(Vector3(p.x, yt - depth, p.y))
			for i in PN_PANELS:
				var m := (tops[i] + bots[i + 1]) * 0.5
				if _in_sector and not _sector_rect.has_point(Vector2(m.x, m.z)):
					continue  # the sector holding the panel's middle draws it
				# The arch rib (the bottom chord, deeper), the top chord under the deck, the posts.
				_pn_strut(st, bots[i], bots[i + 1], 0.8, 1.1, n3)
				_pn_strut(st, tops[i] + Vector3.DOWN * 0.35, tops[i + 1] + Vector3.DOWN * 0.35, 0.6, 0.7, n3)
				if i > 0:
					_pn_strut(st, bots[i], tops[i], 0.4, 0.4, n3)
				# The spandrel lattice: one diagonal per panel, falling towards mid-span.
				if i * 2 < PN_PANELS:
					_pn_strut(st, tops[i], bots[i + 1], 0.3, 0.3, n3)
				else:
					_pn_strut(st, bots[i], tops[i + 1], 0.3, 0.3, n3)
			for i in [0, PN_PANELS]:
				var e: Vector3 = bots[i]
				if not _in_sector or _sector_rect.has_point(Vector2(e.x, e.z)):
					_pn_strut(st, bots[i] + Vector3.DOWN * 0.45, tops[i], 0.8, 0.8, n3)
		# Cross bracing between neighbouring girders at the arch rib, every other panel point.
		for j in PN_GIRDERS.size() - 1:
			for i in range(1, PN_PANELS, 2):
				var a := float(i) / PN_PANELS
				var s := lerpf(s0, s1, a)
				var p0 := o + u * s + n * PN_GIRDERS[j]
				var p1 := o + u * s + n * PN_GIRDERS[j + 1]
				var pm := (p0 + p1) * 0.5
				if _in_sector and not _sector_rect.has_point(pm):
					continue
				var depth := PN_DEPTH_MID + (PN_DEPTH_END - PN_DEPTH_MID) * pow(2.0 * a - 1.0, 2.0)
				var y := deck_height(g, pm.x, pm.y) - PN_SLAB - depth
				_pn_strut(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), 0.35, 0.45, u3)
	_pn_edges(st, o, u, n, g)
	_uv2 = Vector2.ZERO


## Along both outer edges over the river: the red fascia girder on the parapet's face, the black
## cast-iron railing on its top (posts, two rails), and over each pier a granite pedestal that
## stands out of the railing with a cartouche (the governorates' arms) and a small turret top.
func _pn_edges(st, o: Vector2, u: Vector2, n: Vector2, g: int) -> void:
	var n3 := Vector3(n.x, 0.0, n.y)
	for side in 2:
		var e: float = PN_EDGE[side]
		var sgn := signf(e)
		var out := n * sgn
		var out3 := n3 * sgn
		var s := PN_ENDS.x
		while s < PN_ENDS.y - 0.1:
			var s2 := minf(s + PN_RAIL_STEP, PN_ENDS.y)
			var p0 := o + u * s + n * e
			var p1 := o + u * s2 + n * e
			var pm := (p0 + p1) * 0.5
			var on_pier := false
			for ps: float in PN_PIERS:
				if absf((s + s2) * 0.5 - ps) < 1.6:
					on_pier = true
			if _in_sector and not _sector_rect.has_point(pm):
				s = s2
				continue
			var y0 := deck_height(g, p0.x, p0.y)
			var y1 := deck_height(g, p1.x, p1.y)
			var f0 := p0 + out * 0.08
			var f1 := p1 + out * 0.08
			_quad(st, Vector3(f0.x, y0 - 1.35, f0.y), Vector3(f1.x, y1 - 1.35, f1.y), Vector3(f1.x, y1 + 0.5, f1.y),
					Vector3(f0.x, y0 + 0.5, f0.y), out3, PN_FASCIA)
			if not on_pier:
				var r0 := p0 - out * 0.15
				var r1 := p1 - out * 0.15
				_pn_strut(st, Vector3(r0.x, y0 + 1.2, r0.y), Vector3(r1.x, y1 + 1.2, r1.y), 0.09, 0.12, out3, PN_IRON)
				_pn_strut(st, Vector3(r0.x, y0 + 0.75, r0.y), Vector3(r1.x, y1 + 0.75, r1.y), 0.05, 0.05, out3, PN_IRON)
				_pn_strut(st, Vector3(r0.x, y0 + 0.55, r0.y), Vector3(r0.x, y0 + 1.2, r0.y), 0.1, 0.1, out3, PN_IRON)
				# The ornamental panel's scroll, a diagonal pair between the posts.
				var rm := (r0 + r1) * 0.5
				var ym := (y0 + y1) * 0.5
				_pn_strut(st, Vector3(r0.x, y0 + 0.6, r0.y), Vector3(rm.x, ym + 1.15, rm.y), 0.04, 0.04, out3, PN_IRON)
				_pn_strut(st, Vector3(rm.x, ym + 1.15, rm.y), Vector3(r1.x, y1 + 0.6, r1.y), 0.04, 0.04, out3, PN_IRON)
			s = s2
		for ps: float in PN_PIERS:
			var c := o + u * ps + n * (e + sgn * 0.3)
			if _in_sector and not _sector_rect.has_point(c):
				continue
			var y := deck_height(g, c.x, c.y)
			var basis := Basis(Vector3.UP, atan2(-u.x, -u.y))
			_box_oriented(st, Vector3(c.x, y - 0.1, c.y), basis, Vector3(1.4, 3.6, 2.6), PN_STONE.lightened(0.08))
			_box_oriented(st, Vector3(c.x, y + 1.85, c.y), basis, Vector3(1.7, 0.3, 2.9), PN_STONE.lightened(0.16))
			_box_oriented(st, Vector3(c.x, y + 2.3, c.y), basis, Vector3(0.9, 0.6, 1.2), PN_STONE.lightened(0.08))
			var k := c + out * 0.72
			_box_oriented(st, Vector3(k.x, y + 0.6, k.y), basis, Vector3(0.06, 1.2, 1.0), Color("#a8323a"))


## A steel member from a to b, w wide (along `side`, horizontal) and h deep.
func _pn_strut(st, a: Vector3, b: Vector3, w: float, h: float, side: Vector3, col := PN_STEEL) -> void:
	var z := b - a
	var length := z.length()
	if length < 0.05:
		return
	z /= length
	var x := (side - z * side.dot(z)).normalized()
	_box_oriented(st, (a + b) * 0.5, Basis(x, z.cross(x), z), Vector3(w, h, length), col)


## One granite pier at s along the bridge, from below the river bed to `top`: a block across the
## whole deck with a rounded cutwater at each end, a paler cap, dressed courses, solid.
func _pn_pier(st, o: Vector2, u: Vector2, n: Vector2, s: float, top: float) -> void:
	var local: Array[Vector2] = []
	for end in [-1.0, 1.0]:
		for k in 5:
			var ang := PI * k / 4.0
			local.append(Vector2(-cos(ang) * PN_HALF * end, end * (PN_SIDE + sin(ang) * PN_HALF)))
	var c := o + u * s
	var ground := INF
	var poly := PackedVector2Array()
	var cap := PackedVector2Array()
	for q: Vector2 in local:
		var p := o + u * (s + q.x) + n * q.y
		poly.append(p)
		cap.append(p + (p - c).normalized() * 0.45)
		ground = minf(ground, terrain_height(p.x, p.y))
	var y0 := ground - 1.5
	var y1 := top - 0.7
	for ring in [[poly, y0, y1, PN_STONE], [cap, y1, top, PN_STONE.lightened(0.12)]]:
		var pts: PackedVector2Array = ring[0]
		var lo: float = ring[1]
		var hi: float = ring[2]
		var col: Color = ring[3]
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			var e := (b - a).normalized()
			var nn := Vector2(e.y, -e.x)
			if nn.dot((a + b) * 0.5 - c) < 0.0:
				nn = -nn
			var y := lo
			var band := 0
			while y < hi - 0.01:
				var y2 := minf(y + 1.2, hi) if pts == poly else hi
				var shade := col.darkened(0.06) if band % 2 == 1 else col
				_quad(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(b.x, y2, b.y), Vector3(a.x, y2, a.y),
						Vector3(nn.x, 0.0, nn.y), shade)
				y = y2
				band += 1
		_fill(st, pts, hi, col.lightened(0.05))
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		_wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, top, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y)])


## Most Poniatowskiego's viaduct over Powiśle (the photo report's "viaduct" section, photos 17, 19,
## 20, 32 and ortho_west): west of the towers the deck runs on for ~700 m from the escarpment by
## the National Museum to Wybrzeże Kościuszkowskie as a reinforced-concrete arch viaduct, wide
## shallow arches with thick ribbed spandrels in light grey concrete #b8b6b0, its pier buildings
## (OpenStreetMap's buildings at the deck's edges, kept: the arches spring from their sides)
## flanking the big arches over Kruczkowskiego and Solec, a big arch over Wybrzeże at the east
## end, and Al. 3 Maja beside and under it. The bake gives it a flat slab on pairs of thin posts;
## this draws, along both outer edges (the parapets' plane), the arcade: square pilaster piers
## from the ground to the slab with a plinth and an impost band, a segmental arch between each
## pair (the spandrel wall from the slab down to the arch, its inner face and soffit, a paler
## archivolt ring, vertical ribs on the spandrels) and a cornice under the slab. In the walls
## surface (no new draw call); the pilasters are solid from the ground to the slab.
## Found from the deck piece that starts at PV_A (the carriageway heading east), whose deck group
## is the viaduct's; a bake without it keeps the slab on posts.
const PV_A := Vector2(449.1, 30.6)
## The frame's range along (s, from PV_A towards the towers): the deck ends at -272 (the west
## abutment's fill) and 426 (the fill on to the west towers, at s ~510).
const PV_S := Vector2(-275.0, 435.0)
## The piers along each side, [s, half length, kind]: 0 a pilaster (solid), 1 a pier building
## (OpenStreetMap's, drawn as a building: the arches spring from its sides), 2 the west
## abutment pier (solid), 3 the east one standing in the fill (drawn only). Spans ~19 m, set
## with tools' measurement (2026-11-03) so that every solid pier stands at least 0.05 m clear of
## the half width (+1 m for roads, +0.4 m for footways) of every way on the ground under the
## edge: Kruczkowskiego (s 26), Solec (s 239-276), Wybrzeże Kościuszkowskie (s 400-426) and
## their footways pass under the big arches; Al. 3 Maja runs under the south edge from s 295,
## where that side's arcade stands back on PV_INSET instead.
const PV_NORTH: Array[Vector3] = [Vector3(-264.0, 1.5, 2), Vector3(-244.9, 1.2, 0), Vector3(-225.7, 1.2, 0),
		Vector3(-206.6, 1.2, 0), Vector3(-187.4, 1.2, 0), Vector3(-168.3, 1.2, 0), Vector3(-149.1, 1.2, 0),
		Vector3(-130.0, 1.2, 0), Vector3(-114.9, 1.2, 0), Vector3(-91.7, 1.2, 0), Vector3(-72.6, 1.2, 0),
		Vector3(-53.4, 1.2, 0), Vector3(-35.3, 1.2, 0), Vector3(-19.1, 1.2, 0), Vector3(11.0, 7.0, 1),
		Vector3(48.5, 6.5, 1), Vector3(73.0, 1.2, 0), Vector3(91.0, 1.2, 0), Vector3(109.0, 1.2, 0), Vector3(127.0, 1.2, 0),
		Vector3(145.0, 1.2, 0), Vector3(163.0, 1.2, 0), Vector3(181.0, 1.2, 0), Vector3(199.0, 1.2, 0),
		Vector3(224.0, 7.0, 1), Vector3(288.0, 7.0, 1), Vector3(313.3, 1.2, 0), Vector3(331.7, 1.2, 0),
		Vector3(350.0, 1.2, 0), Vector3(368.3, 1.2, 0), Vector3(404.5, 1.2, 0), Vector3(427.4, 1.4, 3)]
const PV_SOUTH: Array[Vector3] = [Vector3(-264.0, 1.5, 2), Vector3(-244.9, 1.2, 0), Vector3(-225.7, 1.2, 0),
		Vector3(-206.6, 1.2, 0), Vector3(-187.4, 1.2, 0), Vector3(-168.3, 1.2, 0), Vector3(-149.1, 1.2, 0),
		Vector3(-130.0, 1.2, 0), Vector3(-110.9, 1.2, 0), Vector3(-91.7, 1.2, 0), Vector3(-72.6, 1.2, 0),
		Vector3(-53.4, 1.2, 0), Vector3(-35.3, 1.2, 0), Vector3(-19.1, 1.2, 0), Vector3(11.0, 7.0, 1),
		Vector3(48.5, 6.5, 1), Vector3(73.0, 1.2, 0), Vector3(91.0, 1.2, 0), Vector3(109.0, 1.2, 0),
		Vector3(127.0, 1.2, 0), Vector3(145.0, 1.2, 0), Vector3(163.0, 1.2, 0), Vector3(181.0, 1.2, 0),
		Vector3(199.0, 1.2, 0), Vector3(224.0, 7.0, 1), Vector3(289.0, 7.0, 1), Vector3(313.3, 1.2, 0),
		Vector3(331.7, 1.2, 0), Vector3(350.0, 1.2, 0), Vector3(368.3, 1.2, 0), Vector3(382.7, 1.2, 0),
		Vector3(427.4, 1.4, 3)]
## The south arcade's plane from s INSET.x on: t = INSET.y (the deck overhangs Al. 3 Maja).
const PV_INSET := Vector2(296.0, 0.0)
const PV_RING := 1.6        ## the arch ring's (and the spandrel wall's) thickness
const PV_PROUD := 0.4       ## how far a pilaster stands out of the arcade's plane
const PV_CLEAR := 4.5       ## the arches' springing at least this over the ground
const PV_CROWN := 1.0       ## spandrel depth at the crown, under the slab
const PV_RIB := 3.2         ## spacing of the spandrels' ribs
const PV_CONCRETE := Color("#b8b6b0")
## F's look check (2026-11-03): the deck is steel and rests on two rows of reinforced-concrete arch
## ribs with struts (photo 19); the engineering study counts 27 arched spans and 4 spans carried
## otherwise. Each row here: 31 spans, the PV_BEAMS by the west abutment (where the deck is lowest
## over the escarpment's foot) on deep steel girders, the 27 others open ribs. The north row's
## piers at s -19.1 and 404.5 (measured clear like the rest) give it the south row's count.
const PV_BEAMS := 4
const PV_RIB_CROWN := 0.9    ## the rib's depth at the crown
const PV_RIB_SPRING := 1.8   ## and at the springings
const PV_STRUT := 0.55       ## a strut's thickness along the span
const PV_GIRDER := 1.1       ## the steel edge girder's depth under the slab
const PV_BEAM_GIRDER := 1.9  ## a beam span's girder
const PV_STEEL := Color("#8e979c")
## Photo 17: the bays between Kruczkowskiego's and Solec's pier buildings (s range) are closed by
## rendered walls with doors and windows, PV_INFILL_IN in from the arcade's face (behind the rib).
const PV_INFILL := Vector2(52.0, 220.0)
const PV_INFILL_IN := 0.9
const PV_INFILL_RENDER := Color("#cfc9bc")
## F (2026-11-03): bars and restaurants in the closed bays. [side, the bay's middle s]; their
## neon fascias are storefronts.gd VIADUKT, the people outside crowds.gd VIADUKT (parody names).
const PV_BARS: Array[Vector2] = [Vector2(-1, 100.0), Vector2(-1, 154.0), Vector2(1, 82.0), Vector2(1, 118.0), Vector2(1, 172.0)]
const PV_BAR_GLASS := Color("#d99a52")
const PV_DARK_GLASS := Color("#3a434c")
const PV_TABLE := Color("#ece6d8")
const PV_CHAIR := Color("#5b4636")
const PV_PARASOL := Color("#efe6cf")
const M_LAMP_CODE := 10.0   ## building.gdshader M_LAMP: the colour glows at night


## The viaduct's frame [origin, along, across, deck group, the north edge's t per metre of s
## from PV_S.x, the south one's], or [] when the bake has no such deck.
func _powisle_frame() -> Array:
	for d: Dictionary in _decks:
		if d["k"] != "road":
			continue
		var pts: PackedVector2Array = d["pts"]
		if pts[0].distance_to(PV_A) < 2.0 and pts[0].distance_to(pts[pts.size() - 1]) > 400.0:
			var u := (pts[pts.size() - 1] - pts[0]).normalized()
			var n := Vector2(-u.y, u.x)
			var g := int(d["g"])
			# The outer edges: the outermost piece's parapet line at each metre along.
			var bins := int(PV_S.y - PV_S.x) + 1
			var lo := PackedFloat32Array()
			var hi := PackedFloat32Array()
			lo.resize(bins)
			hi.resize(bins)
			lo.fill(INF)
			hi.fill(-INF)
			for e: Dictionary in _decks:
				if int(e["g"]) != g:
					continue
				var ep: PackedVector2Array = e["pts"]
				for k in ep.size() - 1:
					var a := ep[k] - pts[0]
					var b := ep[k + 1] - pts[0]
					var sa := a.dot(u)
					var sb := b.dot(u)
					if absf(sb - sa) < 0.01:
						continue
					# Left of the piece's direction is -t when it heads +u, +t when it heads back.
					var left := float(e["l"]) + 0.2
					var right := float(e["r"]) + 0.2
					var fwd := sb > sa
					for i in range(maxi(0, ceili(minf(sa, sb) - PV_S.x)), mini(bins - 1, floori(maxf(sa, sb) - PV_S.x)) + 1):
						var f := (i + PV_S.x - sa) / (sb - sa)
						var t := lerpf(a.dot(n), b.dot(n), f)
						lo[i] = minf(lo[i], t - (left if fwd else right))
						hi[i] = maxf(hi[i], t + (right if fwd else left))
			return [pts[0], u, n, g, lo, hi]
	return []


## The arcade's plane (t) on one side (-1 north, +1 south) at s.
func _pv_plane(f: Array, side: int, s: float) -> float:
	if side > 0 and s >= PV_INSET.x:
		return PV_INSET.y
	var edge: PackedFloat32Array = f[4] if side < 0 else f[5]
	var i := clampi(roundi(s - PV_S.x), 0, edge.size() - 1)
	var t := edge[i]
	if is_inf(t):
		# Past a piece's end: the nearest metre that has one.
		for k in range(1, 12):
			for j in [i - k, i + k]:
				if j >= 0 and j < edge.size() and not is_inf(edge[j]):
					return edge[j]
		return 0.0
	return t


## True for a bake post the arcade replaces (within 3 m of an arcade's plane).
func _powisle_skips(f: Array, c: Vector2) -> bool:
	if f.is_empty():
		return false
	var q: Vector2 = c - f[0]
	var s: float = q.dot(f[1])
	if s < PV_S.x or s > PV_S.y:
		return false
	var t: float = q.dot(f[2])
	return absf(t - _pv_plane(f, -1, s)) < 3.0 or absf(t - _pv_plane(f, 1, s)) < 3.0


func _build_powisle(st) -> void:
	var f := _powisle_frame()
	if f.is_empty():
		return
	_uv2 = Vector2(0.5, -1.0)
	for side in [-1, 1]:
		var piers: Array[Vector3] = PV_NORTH if side < 0 else PV_SOUTH
		for k in piers.size():
			_pv_pier(st, f, side, piers[k], k)
			if k + 1 < piers.size():
				_pv_span(st, f, side, piers[k].x + piers[k].y, piers[k + 1].x - piers[k + 1].y, k)
	_uv2 = Vector2.ZERO


## A point on side's arcade plane at s, `out` metres outwards of it (towards the street).
func _pv_at(f: Array, side: int, s: float, out := 0.0) -> Vector2:
	var o: Vector2 = f[0]
	var u: Vector2 = f[1]
	var n: Vector2 = f[2]
	return o + u * s + n * (_pv_plane(f, side, s) + side * out)


## The slab's underside over side's plane at s.
func _pv_soffit(f: Array, side: int, s: float) -> float:
	var p := _pv_at(f, side, s)
	return deck_height(int(f[3]), p.x, p.y) - 1.38


## One pier: a pilaster or an abutment pier (with its plinth, impost band and collider); a pier
## building is OpenStreetMap's (not drawn here).
func _pv_pier(st, f: Array, side: int, p: Vector3, k: int) -> void:
	var kind := int(p.z)
	if kind == 1:
		return
	var c := _pv_at(f, side, p.x, (PV_PROUD - PV_RING) * 0.5)
	if _in_sector and not _sector_rect.has_point(c):
		return
	var u: Vector2 = f[1]
	var n: Vector2 = f[2]
	var u3 := Vector3(u.x, 0.0, u.y)
	var n3 := Vector3(n.x, 0.0, n.y)
	var basis := Basis(n3, Vector3.UP, -u3)
	var ground := INF
	for q in [_pv_at(f, side, p.x - p.y, PV_PROUD), _pv_at(f, side, p.x + p.y, PV_PROUD),
			_pv_at(f, side, p.x - p.y, -PV_RING), _pv_at(f, side, p.x + p.y, -PV_RING)]:
		ground = minf(ground, terrain_height(q.x, q.y))
	var top := _pv_soffit(f, side, p.x)
	var across := PV_RING + PV_PROUD
	var y0 := ground - 0.5
	_box_oriented(st, Vector3(c.x, (y0 + top) * 0.5, c.y), basis, Vector3(across, top - y0, p.y * 2.0), PV_CONCRETE)
	# Plinth, and the impost band the arches spring from.
	var spring := _pv_spring(f, side, p.x)
	_box_oriented(st, Vector3(c.x, ground + 0.4, c.y), basis, Vector3(across + 0.3, 1.8, p.y * 2.0 + 0.3), PV_CONCRETE.darkened(0.12))
	_box_oriented(st, Vector3(c.x, spring - 0.2, c.y), basis, Vector3(across + 0.24, 0.4, p.y * 2.0 + 0.24), PV_CONCRETE.lightened(0.1))
	if kind == 3:
		return
	var corners: Array[Vector2] = []
	for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(c + u * q.x * p.y + n * q.y * across * 0.5)
	for i in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		_wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, top, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y)])


## The springing height at a pier: the impost of the arches either side (the lower of the two
## spans' own, so the band is one height round the pier).
func _pv_spring(f: Array, side: int, s: float) -> float:
	var piers: Array[Vector3] = PV_NORTH if side < 0 else PV_SOUTH
	var best := INF
	for k in piers.size():
		if absf(piers[k].x - s) > 0.01:
			continue
		if k > 0:
			best = minf(best, _pv_arch(f, side, piers[k - 1].x + piers[k - 1].y, s - piers[k].y).y)
		if k + 1 < piers.size():
			best = minf(best, _pv_arch(f, side, s + piers[k].y, piers[k + 1].x - piers[k + 1].y).y)
	return best if best < INF else _pv_soffit(f, side, s) - PV_CROWN - 3.0


## A span's arch between pier faces s0 and s1: [crown height, springing height] (a segmental
## arch, its rise at most 0.3 of the span, springing at least PV_CLEAR over the highest ground
## under it, or a flat lintel PV_CROWN + 1 m deep where the deck is too low for an arch).
func _pv_arch(f: Array, side: int, s0: float, s1: float) -> Vector2:
	var crown := INF
	var ground := -INF
	for i in 9:
		var s := lerpf(s0, s1, i / 8.0)
		crown = minf(crown, _pv_soffit(f, side, s) - PV_CROWN)
		for o in [PV_PROUD, -PV_RING]:
			var q := _pv_at(f, side, s, o)
			ground = maxf(ground, terrain_height(q.x, q.y))
	var spring := maxf(crown - 0.3 * (s1 - s0), ground + PV_CLEAR)
	return Vector2(crown, minf(spring, crown - 1.0))


## One span between pier faces s0 and s1 (F's look check, 2026-11-03, photos 17 and 19): an open
## reinforced-concrete arch rib with square struts standing on it up to the steel edge girder that
## carries the deck (photo 19: the spandrels are open, the sky shows between the struts); one of
## the PV_BEAMS spans by the west abutment instead rests on a deep steel girder alone; a bay inside
## PV_INFILL is closed by a rendered wall under its arch with an arched door and windows (photo 17),
## a bar's (PV_BARS) lit from inside, with café tables in front.
func _pv_span(st, f: Array, side: int, s0: float, s1: float, k: int) -> void:
	var span := s1 - s0
	if span < 2.0:
		return
	var mid := _pv_at(f, side, (s0 + s1) * 0.5)
	if _in_sector and not _sector_rect.has_point(mid):
		return  # the sector holding the span's middle draws it
	var n: Vector2 = f[2]
	var u: Vector2 = f[1]
	var out3 := Vector3(n.x, 0.0, n.y) * side
	var down := Vector3(0.0, -1.0, 0.0)
	var basis := Basis(Vector3(n.x, 0.0, n.y), Vector3.UP, -Vector3(u.x, 0.0, u.y))
	var segs := clampi(roundi(span / 1.6), 8, 28)
	var face := PackedVector2Array()   # on the plane
	var back := PackedVector2Array()   # the rib's inner side
	var tops := PackedFloat32Array()
	for i in segs + 1:
		var s := lerpf(s0, s1, float(i) / segs)
		face.append(_pv_at(f, side, s))
		back.append(_pv_at(f, side, s, -PV_RING))
		tops.append(_pv_soffit(f, side, s))
	var beam := k < PV_BEAMS
	var arch := _pv_arch(f, side, s0, s1)
	var crown := arch.x
	var rise := crown - arch.y
	var girder := PV_BEAM_GIRDER if beam else PV_GIRDER
	# The steel edge girder under the slab, the length of the span: its face 0.15 m proud, its foot.
	for i in segs:
		var a := face[i] + n * side * 0.15
		var b := face[i + 1] + n * side * 0.15
		_quad(st, Vector3(a.x, tops[i] - girder, a.y), Vector3(b.x, tops[i + 1] - girder, b.y), Vector3(b.x, tops[i + 1], b.y),
				Vector3(a.x, tops[i], a.y), out3, PV_STEEL)
		var ia := back[i]
		var ib := back[i + 1]
		_quad(st, Vector3(a.x, tops[i] - girder, a.y), Vector3(b.x, tops[i + 1] - girder, b.y), Vector3(ib.x, tops[i + 1] - girder, ib.y),
				Vector3(ia.x, tops[i] - girder, ia.y), down, PV_STEEL.darkened(0.3))
		_quad(st, Vector3(ia.x, tops[i] - girder, ia.y), Vector3(ib.x, tops[i + 1] - girder, ib.y), Vector3(ib.x, tops[i + 1], ib.y),
				Vector3(ia.x, tops[i], ia.y), -out3, PV_STEEL.darkened(0.2))
	# The stiffeners on the girder's face, one every PV_RIB.
	var stiff := maxi(1, floori(span / PV_RIB))
	for r in stiff + 1:
		var s := s0 + span * r / stiff
		var p := _pv_at(f, side, s, 0.2)
		var y1 := _pv_soffit(f, side, s)
		_box_oriented(st, Vector3(p.x, y1 - girder * 0.5, p.y), basis, Vector3(0.1, girder, 0.18), PV_STEEL.lightened(0.08))
	if beam or rise < 0.6:
		return
	# The rib: an arch ring PV_RING wide across, deep PV_RIB_CROWN at the crown thickening to
	# PV_RIB_SPRING at the springings, its back clamped under the girder.
	var radius := (span * span * 0.25 + rise * rise) / (2.0 * rise)
	var under := PackedFloat32Array()   # the intrados
	var over := PackedFloat32Array()    # the extrados
	for i in segs + 1:
		var x := lerpf(s0, s1, float(i) / segs) - (s0 + s1) * 0.5
		var y := crown - radius + sqrt(maxf(radius * radius - x * x, 0.0))
		var e := pow(absf(x) / (span * 0.5), 2.0)
		under.append(y)
		over.append(minf(y + lerpf(PV_RIB_CROWN, PV_RIB_SPRING, e), tops[i] - girder))
	var rib := PV_CONCRETE
	for i in segs:
		var a := face[i]
		var b := face[i + 1]
		var ia := back[i]
		var ib := back[i + 1]
		_quad(st, Vector3(a.x, under[i], a.y), Vector3(b.x, under[i + 1], b.y), Vector3(b.x, over[i + 1], b.y),
				Vector3(a.x, over[i], a.y), out3, rib)
		_quad(st, Vector3(ia.x, under[i], ia.y), Vector3(ib.x, under[i + 1], ib.y), Vector3(ib.x, over[i + 1], ib.y),
				Vector3(ia.x, over[i], ia.y), -out3, rib.darkened(0.25))
		_quad(st, Vector3(a.x, under[i], a.y), Vector3(b.x, under[i + 1], b.y), Vector3(ib.x, under[i + 1], ib.y),
				Vector3(ia.x, under[i], ia.y), down, rib.darkened(0.18))
		_quad(st, Vector3(a.x, over[i], a.y), Vector3(b.x, over[i + 1], b.y), Vector3(ib.x, over[i + 1], ib.y),
				Vector3(ia.x, over[i], ia.y), Vector3.UP, rib.lightened(0.05))
	# The struts: square posts on the rib's back up to the girder, PV_RIB apart, open between.
	var struts := floori(span / PV_RIB)
	for r in struts:
		var s := s0 + span * (r + 0.5) / struts
		var x := s - (s0 + s1) * 0.5
		var e := pow(absf(x) / (span * 0.5), 2.0)
		var y0 := crown - radius + sqrt(maxf(radius * radius - x * x, 0.0)) + lerpf(PV_RIB_CROWN, PV_RIB_SPRING, e) - 0.1
		var y1 := _pv_soffit(f, side, s) - girder
		if y1 - y0 < 0.3:
			continue
		var p := _pv_at(f, side, s, -PV_RING * 0.5)
		_box_oriented(st, Vector3(p.x, (y0 + y1) * 0.5, p.y), basis, Vector3(PV_RING - 0.2, y1 - y0, PV_STRUT), PV_CONCRETE.lightened(0.03))
	if (s0 + s1) * 0.5 < PV_INFILL.x or (s0 + s1) * 0.5 > PV_INFILL.y:
		return
	_pv_infill(st, f, side, s0, s1, under, segs)


## A closed bay (photo 17): a rendered wall PV_INFILL_IN in from the plane, from the ground up to
## the rib's intrados, with an arched door in the middle and a window either side; a bar's bay
## (PV_BARS) has warm glass lit from inside (M_LAMP glows at night), the rest dark glass; every
## wall is solid (`_wall_faces`), so the bars' neon signs (storefronts.gd VIADUKT) find it.
func _pv_infill(st, f: Array, side: int, s0: float, s1: float, under: PackedFloat32Array, segs: int) -> void:
	var n: Vector2 = f[2]
	var u: Vector2 = f[1]
	var out3 := Vector3(n.x, 0.0, n.y) * side
	var basis := Basis(Vector3(n.x, 0.0, n.y), Vector3.UP, -Vector3(u.x, 0.0, u.y))
	var ground := INF
	for i in segs + 1:
		var q := _pv_at(f, side, lerpf(s0, s1, float(i) / segs), -PV_INFILL_IN)
		ground = minf(ground, terrain_height(q.x, q.y))
	var y0 := ground - 0.3
	for i in segs:
		var a := _pv_at(f, side, lerpf(s0, s1, float(i) / segs), -PV_INFILL_IN)
		var b := _pv_at(f, side, lerpf(s0, s1, float(i + 1) / segs), -PV_INFILL_IN)
		_quad(st, Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, under[i + 1], b.y),
				Vector3(a.x, under[i], a.y), out3, PV_INFILL_RENDER)
	# The wall is solid: one rectangle up to the springing (the rib's foot) is enough for the car.
	var wa := _pv_at(f, side, s0, -PV_INFILL_IN)
	var wb := _pv_at(f, side, s1, -PV_INFILL_IN)
	var wt := minf(under[0], under[segs]) + 1.0
	_wall_faces.append_array([Vector3(wa.x, y0, wa.y), Vector3(wb.x, y0, wb.y), Vector3(wb.x, wt, wb.y),
			Vector3(wa.x, y0, wa.y), Vector3(wb.x, wt, wb.y), Vector3(wa.x, wt, wa.y)])
	var bar := _pv_bar(side, (s0 + s1) * 0.5)
	var glass := PV_BAR_GLASS if bar else PV_DARK_GLASS
	var midd := (s0 + s1) * 0.5
	# A plinth band along the wall's foot.
	var pc := _pv_at(f, side, midd, -PV_INFILL_IN + 0.06)
	_box_oriented(st, Vector3(pc.x, ground + 0.25, pc.y), basis, Vector3(0.12, 0.5, s1 - s0), PV_CONCRETE.darkened(0.12))
	# The door (2.4 m by 3.4 m, a round head) and two windows (1.6 m by 2.8 m on a 0.9 m sill) each
	# side of it, the openings' frames 0.08 m proud and their glass 0.04 m.
	var openings: Array[Vector3] = [Vector3(midd, 2.4, 0.0)]   # [s centre, width, sill]
	var room := (s1 - s0) * 0.5 - 2.0
	if room > 2.4:
		for d in [-1.0, 1.0]:
			openings.append(Vector3(midd + d * minf(room * 0.55 + 1.2, 4.6), 1.6, 0.9))
	if room > 6.2:
		for d in [-1.0, 1.0]:
			openings.append(Vector3(midd + d * minf(room * 0.55 + 1.2, 4.6) + d * 2.4, 1.2, 0.9))
	if bar:
		_uv2 = Vector2(M_LAMP_CODE, 0.0)
	for o in openings:
		var hgt := 3.4 if o.z == 0.0 else 2.8
		var x := o.x - (s0 + s1) * 0.5
		var cap := INF
		for i in segs + 1:
			var si := lerpf(s0, s1, float(i) / segs)
			if absf(si - o.x) <= o.y * 0.5 + 0.3:
				cap = minf(cap, under[i])
		var top := minf(ground + o.z + hgt, cap - 0.5)
		if top - (ground + o.z) < 1.2:
			continue
		var g := _pv_at(f, side, o.x, -PV_INFILL_IN + 0.04)
		_box_oriented(st, Vector3(g.x, (ground + o.z + top) * 0.5, g.y), basis, Vector3(0.04, top - ground - o.z, o.y), glass)
		# A round head: a half disc of glass over the opening.
		var hc := Vector3(g.x, top, g.y)
		var r := o.y * 0.5
		for j in 6:
			var a0 := PI * j / 6.0
			var a1 := PI * (j + 1) / 6.0
			var d0 := Vector3(u.x, 0.0, u.y) * cos(a0) * r + Vector3.UP * sin(a0) * r
			var d1 := Vector3(u.x, 0.0, u.y) * cos(a1) * r + Vector3.UP * sin(a1) * r
			_tri(st, hc, hc + d0, hc + d1, out3, glass)
			_tri(st, hc, hc + d1, hc + d0, out3, glass)
	_uv2 = Vector2(0.5, -1.0)
	for o in openings:
		var g := _pv_at(f, side, o.x, -PV_INFILL_IN + 0.08)
		# The frame's sill (doors: a step) and jambs.
		_box_oriented(st, Vector3(g.x, ground + maxf(o.z, 0.1) - 0.05, g.y), basis, Vector3(0.14, 0.1 if o.z > 0.0 else 0.2, o.y + 0.3), PV_CONCRETE.lightened(0.12))
	if not bar:
		return
	# Café tables in front of the bar under its arch: a row of round-ish tables, two chairs each,
	# a cream parasol over each; low, so the car can pass the arcade's face (not solid).
	var tables := maxi(2, floori((s1 - s0 - 2.0) / 3.2))
	for t in tables:
		var s := s0 + 1.6 + (s1 - s0 - 3.2) * (t + 0.5) / tables
		if absf(s - midd) < 1.8:
			continue
		var c := _pv_at(f, side, s, -PV_INFILL_IN + 1.6)
		var y := terrain_height(c.x, c.y)
		_box_oriented(st, Vector3(c.x, y + 0.37, c.y), basis, Vector3(0.1, 0.74, 0.1), PV_STEEL.darkened(0.4))
		_box_oriented(st, Vector3(c.x, y + 0.76, c.y), basis, Vector3(0.7, 0.04, 0.7), PV_TABLE)
		for d in [-1.0, 1.0]:
			var ch: Vector2 = c + u * float(d) * 0.65
			_box_oriented(st, Vector3(ch.x, y + 0.23, ch.y), basis, Vector3(0.42, 0.46, 0.42), PV_CHAIR)
			var bk: Vector2 = c + u * float(d) * 0.86
			_box_oriented(st, Vector3(bk.x, y + 0.7, bk.y), basis, Vector3(0.42, 0.5, 0.06), PV_CHAIR)
		_box_oriented(st, Vector3(c.x, y + 1.4, c.y), basis, Vector3(0.05, 1.3, 0.05), PV_STEEL.darkened(0.4))
		var umb := _pv_at(f, side, s, -PV_INFILL_IN + 1.6)
		var uy := y + 2.15
		var rim: Array[Vector3] = []
		for j in 8:
			var ang := TAU * j / 8.0
			rim.append(Vector3(umb.x + cos(ang) * 1.2, uy - 0.35, umb.y + sin(ang) * 1.2))
		for j in 8:
			var p0 := rim[j]
			var p1 := rim[(j + 1) % 8]
			var apex := Vector3(umb.x, uy, umb.y)
			_tri(st, apex, p1, p0, ((p1 - apex).cross(p0 - apex)).normalized(), PV_PARASOL)
			_tri(st, apex, p0, p1, ((p0 - apex).cross(p1 - apex)).normalized(), PV_PARASOL.darkened(0.2))


## True when the bay centred at s on side is a bar's (PV_BARS).
func _pv_bar(side: int, s: float) -> bool:
	for b: Vector2 in PV_BARS:
		if int(b.x) == side and absf(b.y - s) < 6.0:
			return true
	return false


## Loop 3b: a garage door at each ramp top where R9 ended a service way (`garage_doors`): a
## concrete frame and a grey roller shutter across the way, solid.
func _build_garage_doors(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for g: Dictionary in data.get("garage_doors", []):
		var c := Vector2(float(g["c"][0]), float(g["c"][1]))
		var d := Vector2(float(g["d"][0]), float(g["d"][1])).normalized()
		var side := Vector2(-d.y, d.x)
		var w := float(g["w"])
		var y := float(g["y"])
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var at := c + d * 0.6
		_box_oriented(st, Vector3(at.x, y + 1.2, at.y), basis, Vector3(w, 2.4, 0.15), Color("#8e9196"))
		_box_oriented(st, Vector3(at.x, y + 2.65, at.y), basis, Vector3(w + 0.8, 0.5, 0.4), PORTAL_CONCRETE)
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = at + side * sgn * (w * 0.5 + 0.2)
			_box_oriented(st, Vector3(p.x, y + 1.2, p.y), basis, Vector3(0.4, 2.4, 0.4), PORTAL_CONCRETE)
		var a := at - side * (w * 0.5 + 0.4)
		var b := at + side * (w * 0.5 + 0.4)
		_wall_faces.append_array([Vector3(a.x, y - 0.5, a.y), Vector3(b.x, y - 0.5, b.y), Vector3(b.x, y + 2.9, b.y),
				Vector3(a.x, y - 0.5, a.y), Vector3(b.x, y + 2.9, b.y), Vector3(a.x, y + 2.9, a.y)])
	_uv2 = Vector2.ZERO


## Loop 3b: the aprons and their cell index (`terrain_height` reads them).
func _load_aprons() -> void:
	_aprons.clear()
	_apron_cells.clear()
	for a in data.get("aprons", []):
		var p: Array = a["p"]
		var d := Vector2(float(p[2]) - float(p[0]), float(p[3]) - float(p[1]))
		var length := maxf(d.length(), 0.01)
		d /= length
		var k := _aprons.size()
		_aprons.append(PackedFloat32Array([float(p[0]), float(p[1]), d.x, d.y, length, float(a["h"]), float(a["l"]),
				float(a["r"]), float(a.get("i", APRON_IN))]))
		var reach := maxf(float(a["l"]), float(a["r"])) + APRON_TAPER + length
		for cz in range(floori((float(p[1]) - reach) / FILL_CELL), floori((float(p[1]) + reach) / FILL_CELL) + 1):
			for cx in range(floori((float(p[0]) - reach) / FILL_CELL), floori((float(p[0]) + reach) / FILL_CELL) + 1):
				var key := (cx + 1024) * 4096 + cz + 1024
				var list: PackedInt32Array = _apron_cells.get(key, PackedInt32Array())
				list.append(k)
				_apron_cells[key] = list


## Loop 3a: where an approach stands above the terrain grid (the grid's blur at an abutment),
## a plain concrete face down each side of its corridor, so it doesn't float (a map baked
## before loop 3b; `_build_walls` draws the retaining walls instead).
func _build_fill_sides(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var concrete := Color("#b8b2a7").darkened(0.1)
	for d in _fills:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var right := Vector2(-(b - a).y, (b - a).x) / length
			for side in [-1.0, 1.0]:
				var off := float(d["r"]) if side > 0.0 else float(d["l"])
				var p0: Vector2 = a + right * side * off
				var p1: Vector2 = b + right * side * off
				var g0 := _grid_height(p0.x, p0.y)
				var g1 := _grid_height(p1.x, p1.y)
				if hs[i] - g0 < 0.35 and hs[i + 1] - g1 < 0.35:
					continue
				var n := Vector3(right.x * side, 0.0, right.y * side)
				_quad(st, Vector3(p0.x, minf(g0, hs[i]) - 0.3, p0.y), Vector3(p1.x, minf(g1, hs[i + 1]) - 0.3, p1.y),
						Vector3(p1.x, hs[i + 1] - 0.02, p1.y), Vector3(p0.x, hs[i] - 0.02, p0.y), n, concrete)
	_uv2 = Vector2.ZERO


## Loop 3a (R4): the tunnel pieces, for their heights (`tunnel_height`).
func _load_tunnels() -> void:
	_tunnels.clear()
	for piece in data.get("tunnels", {}).get("pieces", []):
		var pts := _pts(piece["p"])
		var cum := PackedFloat32Array([0.0])
		for k in range(1, pts.size()):
			cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		_tunnels.append({"pts": pts, "cum": cum, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]),
				"r": float(piece["r"]), "g": int(piece["g"]), "box": box.grow(maxf(float(piece["l"]), float(piece["r"])) + 1.0)})


## Loop 3a (R4): the height of tunnel t at a point (its nearest piece, projected), or the
## terrain if there is no such tunnel. The lane graph's tunnel edges use it (once per edge).
func tunnel_height(t: int, x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	var h := terrain_height(x, z)
	for d in _tunnels:
		if int(d["g"]) != t:
			continue
		var hit := _deck_hit(d, p)
		if hit.y < best:
			best = hit.y
			h = hit.x
	return h


## The highest roof over the grid cell holding a point, or NO_ROOF in the open.
func roof_height(x: float, z: float) -> float:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return NO_ROOF
	return _roof[j * _roof_nx + i]


## Loop 3c: roof_height while the city is built: a sector's own grid during its build.
func _built_roof(x: float, z: float) -> float:
	if not _in_sector:
		return roof_height(x, z)
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return NO_ROOF
	return _scratch_roof[j * _roof_nx + i]


## The top of whatever stands within `radius` of a point: ground, bridge deck or roof.
## Nine samples, so a radius up to one cell can't slip between them.
func top_height(x: float, z: float, radius := 0.0) -> float:
	var h := ground_height(x, z)
	if radius <= 0.0:
		return maxf(h, roof_height(x, z))
	for sz in _SPREAD:
		for sx in _SPREAD:
			h = maxf(h, roof_height(x + sx * radius, z + sz * radius))
	return h


const _SPREAD := [-1.0, 0.0, 1.0]


## The tallest roof in the square `reach` m round (x, z), read every 8 m of the roof grid (or the
## ground's height there when nothing stands): the helicopter's height cap (heli.gd `ceiling_at`).
func tallest_near(x: float, z: float, reach: float) -> float:
	var top := ground_height(x, z)
	if _roof_nx <= 0 or _roof_nz <= 0:
		return top
	var i0 := clampi(floori((x - reach - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
	var i1 := clampi(floori((x + reach - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
	var j0 := clampi(floori((z - reach - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
	var j1 := clampi(floori((z + reach - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
	for j in range(j0, j1 + 1, 2):
		var row := j * _roof_nx
		for i in range(i0, i1 + 1, 2):
			top = maxf(top, _roof[row + i])
	return top


## The landmark (an index into landmark_info, or -1) a ray from the camera meets first:
## it walks the ray in 1 m steps against the roof grid (whatever stands in a cell is
## treated as filling it up to its top) and the ground.
func pick_landmark(origin: Vector3, dir: Vector3) -> int:
	if dir.y > -0.01:
		return -1
	var t := maxf(0.0, (origin.y - 340.0) / -dir.y)
	var end := t + 2600.0
	while t < end:
		var p := origin + dir * t
		var top := roof_height(p.x, p.z)
		if top != NO_ROOF and p.y <= top:
			return landmark_at(p.x, p.z)
		if p.y < terrain_height(p.x, p.z) - 0.5:
			return -1
		t += 1.0
	return -1


## The landmark (an index into landmark_info, or -1) whose model covers a point.
func landmark_at(x: float, z: float) -> int:
	if _pick.is_empty():
		return -1
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return -1
	return int(_pick[j * _roof_nx + i]) - 1


## Marks the cell holding a point as at least `y` high.
func _roof_mark(x: float, z: float, y: float) -> void:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return
	# Loop 3c: a sector's build marks its own grid (merged into _roof for its cells).
	if _in_sector:
		if y > _scratch_roof[j * _roof_nx + i]:
			_scratch_roof[j * _roof_nx + i] = y
	elif y > _roof[j * _roof_nx + i]:
		_roof[j * _roof_nx + i] = y


## A LoD2 triangle into the roof grid. Every corner marks its cell (that catches
## spires, chimneys and wall tops); roof triangles also give each cell centre
## they cover the roof's height there.
func _roof_triangle(a: Vector3, b: Vector3, c: Vector3, is_roof: bool, col := Color(0, 0, 0, 0)) -> void:
	_roof_mark(a.x, a.z, a.y)
	_roof_mark(b.x, b.z, b.y)
	_roof_mark(c.x, c.z, c.y)
	if not is_roof:
		if proxy_colours and col.a > 0.0:
			var m := (a + b + c) / 3.0
			_colour_mark(m.x, m.z, col, true, 0.0)
		return
	var d := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(d) < 0.01:
		return
	# Only the cells whose centres lie inside the triangle's bounding box.
	var i0 := maxi(ceili((minf(a.x, minf(b.x, c.x)) - _roof_x0) / ROOF_CELL - 0.5), 0)
	var i1 := mini(floori((maxf(a.x, maxf(b.x, c.x)) - _roof_x0) / ROOF_CELL - 0.5), _roof_nx - 1)
	var j0 := maxi(ceili((minf(a.z, minf(b.z, c.z)) - _roof_z0) / ROOF_CELL - 0.5), 0)
	var j1 := mini(floori((maxf(a.z, maxf(b.z, c.z)) - _roof_z0) / ROOF_CELL - 0.5), _roof_nz - 1)
	for j in range(j0, j1 + 1):
		var z := _roof_z0 + (j + 0.5) * ROOF_CELL
		for i in range(i0, i1 + 1):
			var x := _roof_x0 + (i + 0.5) * ROOF_CELL
			var l1 := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / d
			var l2 := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / d
			var l3 := 1.0 - l1 - l2
			if l1 < -0.001 or l2 < -0.001 or l3 < -0.001:
				continue
			var y := l1 * a.y + l2 * b.y + l3 * c.y
			var k := j * _roof_nx + i
			if proxy_colours and col.a > 0.0:
				_colour_mark(x, z, col, false, y)
			if _in_sector:
				if y > _scratch_roof[k]:
					_scratch_roof[k] = y
			elif y > _roof[k]:
				_roof[k] = y


## A flat-roofed OpenStreetMap building into the roof grid.
func _roof_polygon(poly: PackedVector2Array, top: float, roof_col := Color(0, 0, 0, 0), wall_col := Color(0, 0, 0, 0)) -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in poly:
		_roof_mark(q.x, q.y, top)
		lo = lo.min(q)
		hi = hi.max(q)
	var i0 := maxi(ceili((lo.x - _roof_x0) / ROOF_CELL - 0.5), 0)
	var i1 := mini(floori((hi.x - _roof_x0) / ROOF_CELL - 0.5), _roof_nx - 1)
	var j0 := maxi(ceili((lo.y - _roof_z0) / ROOF_CELL - 0.5), 0)
	var j1 := mini(floori((hi.y - _roof_z0) / ROOF_CELL - 0.5), _roof_nz - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var p := Vector2(_roof_x0 + (i + 0.5) * ROOF_CELL, _roof_z0 + (j + 0.5) * ROOF_CELL)
			var k := j * _roof_nx + i
			if proxy_colours and roof_col.a > 0.0 and Geometry2D.is_point_in_polygon(p, poly):
				_colour_mark(p.x, p.y, roof_col, false, top)
				_colour_mark(p.x, p.y, wall_col, true, 0.0)
			if _in_sector:
				if top > _scratch_roof[k] and Geometry2D.is_point_in_polygon(p, poly):
					_scratch_roof[k] = top
			elif top > _roof[k] and Geometry2D.is_point_in_polygon(p, poly):
				_roof[k] = top


## The loading fix: the colour grids sized to the roof grid (empty until a build records them).
func _open_colours() -> void:
	if roof_rgba.size() != _roof.size():
		roof_rgba.resize(_roof.size())
		roof_rgba.fill(0)
		wall_rgba.resize(_roof.size())
		wall_rgba.fill(0)


## The loading fix: `col` for the cell holding a point: a wall's (`wall`), or a roof's at height `y`
## when it is the cell's highest so far (within a metre: a wall top or a spire's corner marks
## the height first) or the cell has no roof colour yet.
func _colour_mark(x: float, z: float, col: Color, wall: bool, y: float) -> void:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return
	var k := j * _roof_nx + i
	var c := Color(col.r, col.g, col.b, 1.0).to_rgba32()
	if _in_sector:
		if wall:
			_scratch_wall[k] = c
		elif _scratch_rgba[k] == 0 or y >= _scratch_roof[k] - 1.0:
			_scratch_rgba[k] = c
	else:
		_open_colours()
		if wall:
			wall_rgba[k] = c
		elif roof_rgba[k] == 0 or y >= _roof[k] - 1.0:
			roof_rgba[k] = c


## The loading fix (sector_proxies.gd): the roof's and the wall's colour over the cell holding a
## point (alpha 0: none recorded).
func roof_colour(x: float, z: float) -> Color:
	return _grid_colour(roof_rgba, x, z)


func wall_colour(x: float, z: float) -> Color:
	return _grid_colour(wall_rgba, x, z)


func _grid_colour(grid: PackedInt32Array, x: float, z: float) -> Color:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if grid.is_empty() or i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz or grid[j * _roof_nx + i] == 0:
		return Color(0, 0, 0, 0)
	return Color.hex(grid[j * _roof_nx + i])


## The surface a flat layer is laid on: the terrain, or the deck it was baked onto.
func _surface_height(x: float, z: float) -> float:
	if _tn >= 0:
		return tunnel_height(_tn, x, z)
	return deck_height(_dk, x, z) if _dk >= 0 else terrain_height(x, z)


# --- primitives -------------------------------------------------------------

func _tri(st, a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color,
		ua := Vector2(-1, -1), ub := Vector2(-1, -1), uc := Vector2(-1, -1)) -> void:
	if _drape_bias >= 0.0:
		_draped_tri(st, a, b, c, col, 0)
		return
	var facing_viewer := (b - a).cross(c - a).dot(n) > 0.0
	if facing_viewer == CLOCKWISE_FRONT:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(v[1])
		st.set_uv2(_uv2)
		st.add_vertex(v[0])


## A flat-layer triangle laid on the ground: split until no edge is longer than
## the terrain grid, then lifted to the surface (its own y is the layer offset).
func _draped_tri(st, a: Vector3, b: Vector3, c: Vector3, col: Color, depth: int) -> void:
	if _in_sector and not _touches(a, b, c, COVER_REACH if _cover_on else 0.01):
		return  # loop 3c: no piece of it can lie in the sector being built
	# Split the longest edge in two until every edge fits the terrain grid; long thin
	# strips (rails, lane lines) then cost a handful of triangles, not thousands.
	var ab := Vector2(a.x - b.x, a.z - b.z).length()
	var bc := Vector2(b.x - c.x, b.z - c.z).length()
	var ca := Vector2(c.x - a.x, c.z - a.z).length()
	if maxf(ab, maxf(bc, ca)) > _drape_edge(a, b, c) and depth < 16 and not _t_h.is_empty():
		if ab >= bc and ab >= ca:
			var m := (a + b) * 0.5
			_draped_tri(st, a, m, c, col, depth + 1)
			_draped_tri(st, m, b, c, col, depth + 1)
		elif bc >= ca:
			var m := (b + c) * 0.5
			_draped_tri(st, a, b, m, col, depth + 1)
			_draped_tri(st, a, m, c, col, depth + 1)
		else:
			var m := (c + a) * 0.5
			_draped_tri(st, a, b, m, col, depth + 1)
			_draped_tri(st, m, b, c, col, depth + 1)
		return
	_emit_draped(st, a, b, c, col)


## The longest edge a draped triangle keeps (m): the terrain grid's, or for the railway's ballast
## and gravel (`_exact_strip`) in the cutting's cells, drawn in 2 m sub-cells (rail_cut.gd SUB),
## the sub-cells' own size, so the pieces bend where its banks and floor do. Only in the cutting:
## elsewhere the 10 m pieces sag a few centimetres (their bias covers it), and the aprons' 1 m
## sub-cells map-wide would have cost ~400k triangles. The rails keep their pieces (bias 0.46).
func _drape_edge(a: Vector3, b: Vector3, c: Vector3) -> float:
	if not _exact_strip or _dk >= 0 or _tn >= 0 or _layer == L_RAIL:
		return 12.0
	if not (_cut.box.has_point(Vector2(a.x, a.z)) or _cut.box.has_point(Vector2(b.x, b.z)) or _cut.box.has_point(Vector2(c.x, c.z))):
		return 12.0
	_fine_index()
	if _fine_cells.is_empty():
		return 12.0
	var step := float(_terrain["step"])
	var fine := 0
	for p: Vector3 in [a, b, c]:
		var key := Vector2i(floori((p.x - float(_terrain["x0"])) / step), floori((p.z - float(_terrain["z0"])) / step))
		fine = maxi(fine, int(_fine_cells.get(key, 0)))
	return 12.0 if fine == 0 else maxf(step / fine, step / RailCut.SUB) * 1.2


## One flat-layer triangle lifted onto the surface (each corner's own y is the layer offset),
## wound to face up, with the layer's bias and id and the street axes in the UVs. Loop 3d-2a: true
## when it was noted as covering the ground (`_cover_on`).
func _emit_draped(st, a: Vector3, b: Vector3, c: Vector3, col: Color) -> bool:
	var p := [a, b, c]
	for k in 3:
		var v: Vector3 = p[k]
		var h := _surface_height(v.x, v.z)
		if _on_grid and _dk < 0 and _tn < 0:
			# Never under the drawn ground (map round 2: the drawn ground, which follows an
			# apron in its sub-cells).
			h = maxf(h, _drawn_height(v.x, v.z))
		p[k] = Vector3(v.x, h + v.y, v.z)
	if ((p[1] - p[0]).cross(p[2] - p[0]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
		p = [p[0], p[2], p[1]]
	var noted := false
	if _cover_on and _dk < 0 and _tn < 0:
		# Loop 3d-2a: a triangle of a layer that hides the ground, noted if it lies at the ground's
		# height (game/tools/check_ground.gd reads the meshes by the same rule).
		var mid: Vector3 = (p[0] + p[1] + p[2]) / 3.0
		var dy := mid.y - _grid_height(mid.x, mid.z)
		if dy >= COVER_GRADE.x and dy <= COVER_GRADE.y:
			_cover_add(PackedVector2Array([Vector2(p[0].x, p[0].z), Vector2(p[1].x, p[1].z), Vector2(p[2].x, p[2].z)]))
			noted = true
	var axis := _axis if _axis != Vector2.ZERO else CITY_GRID
	for v in p:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(_drape_bias, _layer))
		st.set_uv2(Vector2(v.x * axis.x + v.z * axis.y, -v.x * axis.y + v.z * axis.x))
		st.add_vertex(v)
	return noted


func _quad(st, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	_tri(st, a, b, c, n, col)
	_tri(st, a, c, d, n, col)


func _pts(flat_list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat_list.size() - 1, 2):
		out.append(Vector2(flat_list[i], flat_list[i + 1]))
	return out


func _fill(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	if poly.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(poly)
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		_tri(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, col)


## Loop 3b-2: a polygon laid exactly on the terrain grid's own triangles (the two per cell that
## _build_ground draws), for the areas (water, grass, parks, plazas, sand) and the sandbars.
## The drape's pieces (up to 12 m, each a plane through three terrain points) cut under the
## grid's folds, and there the bare earth poked through as jagged beige patches: the 10 m
## grid holds the river's sandbars and a ridge along Most Poniatowskiego's piers (the "torn
## paper" sandbars in the river), lumps in the parks (game/tools/check_drape.gd). Cells the
## outline doesn't cross go in whole (two triangles), the ones it crosses are clipped. Off
## the grid (a flat world) or when not draping it is `_fill`.
func _fill_on_grid(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	if poly.size() < 3 or _t_h.is_empty() or _drape_bias < 0.0:
		_fill(st, poly, y, col)
		return
	_on_grid = true
	_fill_grid_cells(st, poly, y, col)
	_on_grid = false


## While _fill_on_grid lays a polygon: its corners never go under the drawn ground.
var _on_grid := false


## _fill_on_grid's work: the grid cells under the polygon's box, whole or clipped.
func _fill_grid_cells(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var lo := poly[0]
	var hi := poly[0]
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var i0 := clampi(floori((lo.x - gx) / step), 0, nx - 2)
	var i1 := clampi(floori((hi.x - gx) / step), 0, nx - 2)
	var j0 := clampi(floori((lo.y - gz) / step), 0, nz - 2)
	var j1 := clampi(floori((hi.y - gz) / step), 0, nz - 2)
	if _in_sector:
		# Loop 3c: only the cells that reach into the sector being built (the others' pieces
		# all have their centres outside it).
		i0 = maxi(i0, floori((_sector_rect.position.x - gx) / step) - 1)
		i1 = mini(i1, floori((_sector_rect.end.x - gx) / step) + 1)
		j0 = maxi(j0, floori((_sector_rect.position.y - gz) / step) - 1)
		j1 = mini(j1, floori((_sector_rect.end.y - gz) / step) + 1)
		if i0 > i1 or j0 > j1:
			return
	var w := i1 - i0 + 1
	var h := j1 - j0 + 1
	var crossed := PackedByteArray()
	crossed.resize(w * h)
	var n := poly.size()
	for k in n:
		_mark_cells(crossed, (poly[k] - Vector2(gx, gz)) / step - Vector2(i0, j0),
				(poly[(k + 1) % n] - Vector2(gx, gz)) / step - Vector2(i0, j0), w, h)
	_fine_index()
	for j in h:
		var z := gz + (j0 + j) * step
		for i in w:
			var x := gx + (i0 + i) * step
			var a := Vector2(x, z)
			var b := Vector2(x + step, z)
			var c := Vector2(x + step, z + step)
			var d := Vector2(x, z + step)
			if _fine_cells.has(Vector2i(i0 + i, j0 + j)):
				# Map round 2 (D5): a cell an apron reaches is drawn in sub-cells; lay the
				# polygon on their triangles, each clipped.
				var sub: int = _fine_cells[Vector2i(i0 + i, j0 + j)]
				var s := step / sub
				for sj in sub:
					for si in sub:
						var sa := Vector2(x + si * s, z + sj * s)
						var sb := sa + Vector2(s, 0)
						var sc := sa + Vector2(s, s)
						var sd := sa + Vector2(0, s)
						for tri in [PackedVector2Array([sa, sb, sc]), PackedVector2Array([sa, sc, sd])]:
							for piece in Geometry2D.intersect_polygons(tri, poly):
								var pidx := Geometry2D.triangulate_polygon(piece)
								for t in range(0, pidx.size(), 3):
									var p0 := piece[pidx[t]]
									var p1 := piece[pidx[t + 1]]
									var p2 := piece[pidx[t + 2]]
									if absf((p1 - p0).cross(p2 - p0)) < 0.0002:
										continue
									_emit_draped(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), col)
				continue
			if crossed[j * w + i] == 0:
				if Geometry2D.is_point_in_polygon(Vector2(x + step * 0.5, z + step * 0.5), poly):
					var upper := _emit_draped(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), col)
					var lower := _emit_draped(st, Vector3(a.x, y, a.y), Vector3(c.x, y, c.y), Vector3(d.x, y, d.y), col)
					if upper and lower:
						_cover_whole[Vector2i(i0 + i, j0 + j)] = true  # loop 3d-2a
				continue
			# The cell's two triangles (the diagonal _grid_height uses), each clipped.
			for tri in [PackedVector2Array([a, b, c]), PackedVector2Array([a, c, d])]:
				for piece in Geometry2D.intersect_polygons(tri, poly):
					var idx := Geometry2D.triangulate_polygon(piece)
					for t in range(0, idx.size(), 3):
						var p0 := piece[idx[t]]
						var p1 := piece[idx[t + 1]]
						var p2 := piece[idx[t + 2]]
						if absf((p1 - p0).cross(p2 - p0)) < 0.0002:
							continue
						_emit_draped(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), col)


## Marks the cells of a w x h grid (cell units, from its corner) that the segment p-q passes
## through: a grid walk, one cell at a time.
static func _mark_cells(mask: PackedByteArray, p: Vector2, q: Vector2, w: int, h: int) -> void:
	var ci := floori(p.x)
	var cj := floori(p.y)
	var ei := floori(q.x)
	var ej := floori(q.y)
	var d := q - p
	var si := 1 if d.x > 0.0 else -1
	var sj := 1 if d.y > 0.0 else -1
	var tdx := absf(1.0 / d.x) if absf(d.x) > 1e-9 else INF
	var tdz := absf(1.0 / d.y) if absf(d.y) > 1e-9 else INF
	var tmx := ((ci + 1 - p.x) if d.x > 0.0 else (p.x - ci)) * tdx if tdx != INF else INF
	var tmz := ((cj + 1 - p.y) if d.y > 0.0 else (p.y - cj)) * tdz if tdz != INF else INF
	for guard in 100000:
		if ci >= 0 and cj >= 0 and ci < w and cj < h:
			mask[cj * w + ci] = 1
		if ci == ei and cj == ej:
			return
		if tmx < tmz:
			if tmx > 1.0:
				return
			tmx += tdx
			ci += si
		else:
			if tmz > 1.0:
				return
			tmz += tdz
			cj += sj


func _disc(st, p: Vector2, r: float, y: float, col: Color, segments := 8) -> void:
	var centre := Vector3(p.x, y, p.y)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		_tri(st, centre, Vector3(p.x + cos(a0) * r, y, p.y + sin(a0) * r),
				Vector3(p.x + cos(a1) * r, y, p.y + sin(a1) * r), Vector3.UP, col)


## Loop 3b-2: strips laid at this depth bias or less (footways, cycle paths, steps: just over the
## areas) follow the grid's triangles exactly; the ones higher up (roads 0.3, markings) keep the
## 10 m pieces, their bias covers any sag.
const EXACT_STRIP_BIAS := 0.12
## Flicker fix (F's phone videos, 2026-11-07): the railway's flat layers (the cutting's floor, the
## tracks' gravel shoulders and dark beds, the rails) keep their corners on or over the drawn
## ground, and in the cutting bend with its 2 m sub-cells (`_drape_edge`). In 10 m pieces they
## sagged up to a metre under it (the cutting's banks and floor bend between the grid's points),
## and from the helicopter the beige ground tore through the ballast and cut the rails into
## dashes that crawled as the view moved. check_drape.gd's rail pass counts what it still hides.
var _exact_strip := false


## A polyline as a flat band; square caps overlap at the joints.
func _strip(st, poly: PackedVector2Array, width: float, y: float, col: Color, extend := true) -> void:
	var hw := width * 0.5
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.01:
			continue
		var dir := d.normalized()
		_axis = dir
		if extend:
			a -= dir * hw
			b += dir * hw
		var side := Vector2(-dir.y, dir.x) * hw
		if _drape_bias >= 0.0 and _drape_bias <= EXACT_STRIP_BIAS and _dk < 0 and _tn < 0 and not _t_h.is_empty():
			# Loop 3b-2: a footway, cycle path or flight of steps on the ground follows the grid's
			# own triangles (clipped to them, as the areas are), so it never sags under the area
			# it crosses (the Praga beach's footpath was dashed by its sand; check_drape.gd).
			_on_grid = true
			_fill_grid_cells(st, PackedVector2Array([a + side, b + side, b - side, a - side]), y, col)
			_on_grid = false
			continue
		# Draped: cut into pieces no longer than the terrain grid, so a long thin strip
		# costs two triangles per piece instead of a fan of slivers.
		var pieces := maxi(1, ceili(a.distance_to(b) / 10.0)) if _drape_bias >= 0.0 else 1
		# The railway's layers in the cutting: their corners never under the drawn ground
		# (`_emit_draped`). Only there: the drawn ground's height costs the cut's own lookups, and
		# map-wide it made the build (and check_drape) minutes slower for a few hundred m2.
		_on_grid = _exact_strip and _dk < 0 and _tn < 0 and _cut.box.grow(hw).intersects(Rect2(a, Vector2.ZERO).expand(b))
		for k in pieces:
			var p := a.lerp(b, float(k) / pieces)
			var q := a.lerp(b, float(k + 1) / pieces)
			_quad(st, Vector3(p.x + side.x, y, p.y + side.y), Vector3(q.x + side.x, y, q.y + side.y),
					Vector3(q.x - side.x, y, q.y - side.y), Vector3(p.x - side.x, y, p.y - side.y), Vector3.UP, col)
		_on_grid = false
	_axis = Vector2.ZERO


# --- layers -------------------------------------------------------------------

## The map ends like a diorama: earth walls drop from the terrain edge.
func _build_edges(st) -> void:
	var step := float(_terrain["step"])
	var x0 := float(_terrain["x0"])
	var z0 := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var bottom: float = Array(_t_h).min() - 14.0
	var top_col := Color("#7d6a52")
	var soil := Color("#6a503b")
	var deep := Color("#45342a")
	# Loop 3d-1: the walls stand on the map's edge, not the grid's: the demo box's grid reaches
	# 4 m past its north edge, past the sector grid too (check_streaming: walls in no sector).
	# Where the grid ends on the edge (the first box) this is the same as before.
	# Map north: one wall per side of the map's outline (six with the north extension). Along a
	# side the corners are the grid's columns or rows; at a convex corner of the outline the wall
	# runs on to the grid's next node past it (as the box's four always did), at the inner corner
	# it stops on the corner (past it would stand inside the map).
	var lx1 := x0 + (nx - 1) * step
	var lz1 := z0 + (nz - 1) * step
	var ring := map_outline()
	var sides := []
	for k in ring.size():
		var a := ring[k - 1]
		var c := ring[k]
		var along_x := absf(c.x - a.x) > absf(c.y - a.y)
		var mid := (a + c) * 0.5
		var n := Vector3.ZERO
		if along_x:
			n = Vector3.FORWARD if not in_map(mid + Vector2(0, -1)) else Vector3.BACK
		else:
			n = Vector3.LEFT if not in_map(mid + Vector2(-1, 0)) else Vector3.RIGHT
		var fixed := clampf(a.y if along_x else a.x, z0 if along_x else x0, lz1 if along_x else lx1)
		var lo0 := x0 if along_x else z0
		var lo1 := lx1 if along_x else lz1
		var ends := [a.x if along_x else a.y, c.x if along_x else c.y]
		var convex := [_outline_convex(ring, k - 1), _outline_convex(ring, k)]
		var vals := PackedFloat64Array()
		var u0 := minf(ends[0], ends[1])
		var u1 := maxf(ends[0], ends[1])
		var lo_convex: bool = convex[0] if ends[0] < ends[1] else convex[1]
		var hi_convex: bool = convex[1] if ends[0] < ends[1] else convex[0]
		var first := ceili((u0 - lo0) / step - 1e-6)
		var last := floori((u1 - lo0) / step + 1e-6)
		if lo_convex:
			first = maxi(floori((u0 - lo0) / step + 1e-6), 0)
		else:
			vals.append(u0)
		for q in range(first, last + 1):
			var u := lo0 + q * step
			if u > lo1 + 1e-6:
				break
			if (vals.is_empty() or u > vals[vals.size() - 1] + 1e-6) and (lo_convex or u > u0 + 1e-6) and (hi_convex or u < u1 - 1e-6):
				vals.append(u)
		if hi_convex:
			var past := lo0 + ceili((u1 - lo0) / step - 1e-6) * step
			if past <= lo1 + 1e-6 and (vals.is_empty() or past > vals[vals.size() - 1] + 1e-6):
				vals.append(past)
		else:
			vals.append(u1)
		var pts: Array[Vector3] = []
		for u in vals:
			var px := u if along_x else fixed
			var pz := fixed if along_x else u
			pts.append(Vector3(px, _grid_height(px, pz), pz))
		sides.append([pts, n])
	for side in sides:
		var pts: Array[Vector3] = side[0]
		var n: Vector3 = side[1]
		for k in pts.size() - 1:
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[k + 1]
			var a1 := Vector3(a.x, a.y - 0.8, a.z)
			var b1 := Vector3(b.x, b.y - 0.8, b.z)
			var a2 := Vector3(a.x, bottom, a.z)
			var b2 := Vector3(b.x, bottom, b.z)
			var none := Vector2(-1, -1)
			_tri_shaded(st, a, b, b1, n, top_col, top_col, soil, none, none, none)
			_tri_shaded(st, a, b1, a1, n, top_col, soil, soil, none, none, none)
			_tri_shaded(st, a1, b1, b2, n, soil, soil, deep, none, none, none)
			_tri_shaded(st, a1, b2, a2, n, soil, deep, deep, none, none, none)


## Map north: whether the outline's corner k turns the way the outline does (a corner of the map,
## not its inner corner by the part left outside).
func _outline_convex(ring: PackedVector2Array, k: int) -> bool:
	var n := ring.size()
	var a := ring[(k - 1 + n) % n]
	var b := ring[(k + n) % n]
	var c := ring[(k + 1) % n]
	var turn := (b - a).cross(c - b)
	var area := 0.0
	for i in n:
		area += ring[i].cross(ring[(i + 1) % n])
	return turn * area > 0.0


## Smooth normals from the height gradient, so slopes shade softly instead of in facets
## (loop 3c: found once, every sector's ground uses them).
func _ground_normals() -> PackedVector3Array:
	if not _gn.is_empty() or _t_h.is_empty():
		return _gn
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	_gn.resize(nx * nz)
	for j in nz:
		for i in nx:
			var hl := _t_h[j * nx + maxi(i - 1, 0)]
			var hr := _t_h[j * nx + mini(i + 1, nx - 1)]
			var hu := _t_h[maxi(j - 1, 0) * nx + i]
			var hd := _t_h[mini(j + 1, nz - 1) * nx + i]
			_gn[j * nx + i] = Vector3(hl - hr, 2.0 * step, hu - hd).normalized()
	return _gn


# --- Map round 2 (2026-10-29, D5): the drawn ground follows the aprons ------------------------
# An apron (loop 3b) holds terrain_height under a structure's end below the 10 m grid (the end
# is flat across, the grid on the cross slope isn't), and everything drawn at terrain_height
# there (the road, its carriageway area, kerbs, tram and rail beds) lay under the drawn grid:
# the beige wedge of bare ground across the viaduct's west end (0.65 m), the Wisłostrada and
# abutment-link portals (up to 1 m), the Kruczkowskiego rail viaduct, two ramps' feet
# (check_roads C11). The grid cells an apron reaches are drawn as GROUND_SUB x GROUND_SUB
# sub-cells at min(grid, terrain_height) (`_drawn_height`), with the same diagonal as the grid,
# so where nothing is lowered they are the grid's own planes; the flat layers laid on the grid
# (_fill_grid_cells) use the same sub-cells and never go under them. check_roads `Map.drawn`
# mirrors this.

## The sub-cells per grid cell side under an apron (1 m on the 10 m grid).
const GROUND_SUB := 10
## Loop 3e: a cell only a ground profile reaches (no apron) in SET_SUB x SET_SUB sub-cells (1 m,
## as the aprons': 2 m ones left the drawn ground over the road at a trench's edge, check_roads C11).
const SET_SUB := 10
## Grid cells (Vector2i(i, j)) an apron's corridor reaches, from `_aprons` (built on first use,
## the same for the whole city and each sector); loop 3e: and a lowering ground profile's, each
## with its sub-cells a side (GROUND_SUB, SET_SUB).
var _fine_cells := {}
var _fine_ready := false


func _fine_index() -> void:
	if _fine_ready:
		return
	_fine_ready = true
	_fine_cells.clear()
	_corner_cache.clear()
	if _t_h.is_empty():
		return
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	# Loop 3e: the cells a ground profile reaches (where it lowers the ground, the drawn ground
	# follows it in the 1 m sub-cells; check_roads Map.drawn the same).
	for d in _fills:
		if not bool(d["s"]):
			continue
		var reach := maxf(float(d["l"]), float(d["r"]))
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		for k in pts.size() - 1:
			# Only where it lowers the ground (a raised one stands on the grid, like an approach).
			if not _set_lowers(pts[k], pts[k + 1], minf(hs[k], hs[k + 1]), reach):
				continue
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for j in range(clampi(floori((lo.y - gz) / step), 0, nz - 2), clampi(floori((hi.y - gz) / step), 0, nz - 2) + 1):
				for i in range(clampi(floori((lo.x - gx) / step), 0, nx - 2), clampi(floori((hi.x - gx) / step), 0, nx - 2) + 1):
					_fine_cells[Vector2i(i, j)] = maxi(int(_fine_cells.get(Vector2i(i, j), 0)), SET_SUB)
	# The railway cutting: every cell its floor, banks and shoulders reach (rail_cut.gd SUB).
	var cut_cells: Dictionary = _cut.cells(gx, gz, step)
	for c: Vector2i in cut_cells:
		if c.x >= 0 and c.y >= 0 and c.x <= nx - 2 and c.y <= nz - 2:
			_fine_cells[c] = maxi(int(_fine_cells.get(c, 0)), int(cut_cells[c]))
	# Sunken places: every cell their grown ring reaches, in their own sub-cells.
	for sk: Dictionary in _sunk:
		var r: Rect2 = (sk["box"] as Rect2).grow(SINK_MARGIN)
		for j in range(clampi(floori((r.position.y - gz) / step), 0, nz - 2), clampi(floori((r.end.y - gz) / step), 0, nz - 2) + 1):
			for i in range(clampi(floori((r.position.x - gx) / step), 0, nx - 2), clampi(floori((r.end.x - gx) / step), 0, nx - 2) + 1):
				_fine_cells[Vector2i(i, j)] = maxi(int(_fine_cells.get(Vector2i(i, j), 0)), int(sk["sub"]))
	for a in _aprons:
		var o := Vector2(a[0], a[1])
		var u := Vector2(a[2], a[3])
		var n := Vector2(-u.y, u.x)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for along in [0.0, a[4]]:
			for lat in [-a[6] - APRON_TAPER, a[7] + APRON_TAPER]:
				var p: Vector2 = o + u * float(along) + n * float(lat)
				lo = lo.min(p)
				hi = hi.max(p)
		for j in range(clampi(floori((lo.y - gz) / step), 0, nz - 2), clampi(floori((hi.y - gz) / step), 0, nz - 2) + 1):
			for i in range(clampi(floori((lo.x - gx) / step), 0, nx - 2), clampi(floori((hi.x - gx) / step), 0, nx - 2) + 1):
				_fine_cells[Vector2i(i, j)] = GROUND_SUB


## Loop 3e: whether a ground profile's segment a-b (its lower end at h) lies under the grid
## anywhere over its corridor (its ends and the corridor's corners, `reach` out).
func _set_lowers(a: Vector2, b: Vector2, h: float, reach: float) -> bool:
	var ab := b - a
	var n := Vector2(-ab.y, ab.x).normalized() * reach if ab.length_squared() > 0.000001 else Vector2.ZERO
	for p: Vector2 in [a, b, a + n, a - n, b + n, b - n]:
		if h < _grid_height(p.x, p.y) - SET_FINE:
			return true
	return false


## The drawn ground's height at a sub-cell corner: the grid, or terrain_height where an apron
## holds the ground under it.
func _drawn_corner(x: float, z: float) -> float:
	# The same sub-cell corners are asked for again and again (every flat layer's vertex in an
	# apron or the cutting, check_drape's samples), and each costs the cut's and aprons' lookups:
	# kept by the centimetre, for the fine index's lifetime (its inputs don't change after it).
	var key := Vector2i(roundi(x * 100.0), roundi(z * 100.0))
	var known: Variant = _corner_cache.get(key)
	if known != null:
		return float(known)
	var h := _drawn_corner_raw(x, z)
	_corner_cache[key] = h
	return h


var _corner_cache := {}


func _drawn_corner_raw(x: float, z: float) -> float:
	var g := _grid_height(x, z)
	var t := terrain_height(x, z)
	# Loop 3e: under a ground profile that lowers the ground, SET_SINK lower still (the 1 m
	# sub-cells between two profiles' levels or across a corridor's edge stay under the road).
	if _set_hit and t < g - 0.001:
		t -= SET_SINK
	# Over a sunken place grown by its sub-cell's diagonal: its floor (no sub-cell's slope inside).
	if _sunk_box.has_point(Vector2(x, z)):
		t = minf(t, sunk_floor(x, z, true))
	# The railway cutting's banks and shoulders may stand over the grid (its blurred slope).
	# Not where an approach's fill holds the ground up (the grid's own drawing stays under it).
	if _cut.box.has_point(Vector2(x, z)) and _cut.at(x, z, g).y > 1.5:
		var hit := _set_hit
		var held := _fill_height_base(x, z) > g + 0.05
		_set_hit = hit
		if not held:
			return t
	return minf(g, t)


## Loop 3e: the drawn ground's sink under a lowering ground profile (`_drawn_corner`;
## check_roads Map.drawn the same), and whether the last `_fill_height` was in one's corridor.
const SET_SINK := 0.1
## Loop 3e: a ground profile's segment gets the 1 m sub-cells where it lies this far under the grid
## anywhere (a raised one doesn't; a lowered one left out would meet its sub-celled neighbour in a
## crack at their shared edge: check_ground's height rule).
const SET_FINE := 0.001
var _set_hit := false


## The drawn ground's height at a point (the mesh `_build_ground` draws): the grid's two
## triangles per cell, or in a cell an apron reaches the sub-cells' (GROUND_SUB).
func _drawn_height(x: float, z: float) -> float:
	_fine_index()
	if _fine_cells.is_empty():
		return _grid_height(x, z)
	var step := float(_terrain["step"])
	var fx := clampf((x - float(_terrain["x0"])) / step, 0.0, int(_terrain["nx"]) - 1.0001)
	var fz := clampf((z - float(_terrain["z0"])) / step, 0.0, int(_terrain["nz"]) - 1.0001)
	var i := int(fx)
	var j := int(fz)
	if not _fine_cells.has(Vector2i(i, j)):
		return _grid_height(x, z)
	var sub: int = _fine_cells[Vector2i(i, j)]
	var s := step / sub
	var si := clampi(int((fx - i) * sub), 0, sub - 1)
	var sj := clampi(int((fz - j) * sub), 0, sub - 1)
	var x0 := float(_terrain["x0"]) + i * step + si * s
	var z0 := float(_terrain["z0"]) + j * step + sj * s
	var u := clampf((x - x0) / s, 0.0, 1.0)
	var v := clampf((z - z0) / s, 0.0, 1.0)
	var h00 := _drawn_corner(x0, z0)
	var h10 := _drawn_corner(x0 + s, z0)
	var h01 := _drawn_corner(x0, z0 + s)
	var h11 := _drawn_corner(x0 + s, z0 + s)
	if u >= v:
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	return h00 + (h11 - h01) * u + (h01 - h00) * v


## One grid cell an apron reaches. Map round 2 drew it as GROUND_SUB x GROUND_SUB sub-cells of
## the drawn ground; loop 3d-2a keeps the 1 m sub-cells only where they touch a lowered point (the
## ground under an apron, below the grid by over a millimetre) and draws the rest of each half of
## the cell (the grid's two triangles) in runs along the sub-rows, which lie on the half's own
## plane: a half with no lowered point is the grid's triangle itself. The heights are the same
## (`_drawn_height`, check_roads `Map.drawn`); 339 apron cells, 67,697 triangles before.
func _ground_fine_cell(st, i: int, j: int, normals: PackedVector3Array, colour: Color) -> void:
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var cx := float(_terrain["x0"]) + i * step
	var cz := float(_terrain["z0"]) + j * step
	var sub: int = _fine_cells[Vector2i(i, j)]
	var s := step / sub
	var n00 := normals[j * nx + i]
	var n10 := normals[j * nx + i + 1]
	var n01 := normals[(j + 1) * nx + i]
	var n11 := normals[(j + 1) * nx + i + 1]
	var side := sub + 1
	# The lattice: each point's height, normal and whether an apron lowers it.
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var low := PackedByteArray()
	pos.resize(side * side)
	nrm.resize(side * side)
	low.resize(side * side)
	for b in side:
		for a in side:
			var x := cx + a * s
			var z := cz + b * s
			var g := _grid_height(x, z)
			var h := _drawn_corner(x, z)
			var k := b * side + a
			pos[k] = Vector3(x, h, z)
			low[k] = 1 if absf(g - h) > 0.001 or not ground_lean else 0
			var fu := float(a) / sub
			var fv := float(b) / sub
			var n := (n00.lerp(n10, fu)).lerp(n01.lerp(n11, fu), fv).normalized()
			if absf(g - h) > 0.01:
				# Lowered (or a cutting's bank raised): the slope of the drawn ground itself.
				n = Vector3(_drawn_corner(x - s, z) - _drawn_corner(x + s, z), 2.0 * s,
						_drawn_corner(x, z - s) - _drawn_corner(x, z + s)).normalized()
			nrm[k] = n
	for half in 2:
		# Half 0 is the grid's triangle (0,0)-(1,0)-(1,1) (u >= v), half 1 (0,0)-(1,1)-(0,1).
		var lowered := false
		for b in side:
			for a in side:
				if low[b * side + a] == 1 and ((a >= b) if half == 0 else (a <= b)):
					lowered = true
		if not lowered:
			var far := Vector2i(sub, 0) if half == 0 else Vector2i(0, sub)
			_ground_lattice_tri(st, pos, nrm, side, [Vector2i(0, 0), far, Vector2i(sub, sub)], colour)
			continue
		for sj in sub:
			var run := -1
			for si in sub + 1:
				var inside := si < sub and ((si >= sj) if half == 0 else (si <= sj))
				var sub_low := inside and (low[sj * side + si] == 1 or low[sj * side + si + 1] == 1
						or low[(sj + 1) * side + si] == 1 or low[(sj + 1) * side + si + 1] == 1)
				if inside and not sub_low:
					if run < 0:
						run = si
					continue
				if run >= 0:
					_ground_run(st, pos, nrm, side, half, sj, run, si - 1, colour)
					run = -1
				if sub_low:
					# The sub-cell's part of this half at 1 m (both triangles off the diagonal).
					var c00 := Vector2i(si, sj)
					var c10 := Vector2i(si + 1, sj)
					var c11 := Vector2i(si + 1, sj + 1)
					var c01 := Vector2i(si, sj + 1)
					if half == 0 or si != sj:
						_ground_lattice_tri(st, pos, nrm, side, [c00, c10, c11], colour)
					if half == 1 or si != sj:
						_ground_lattice_tri(st, pos, nrm, side, [c00, c11, c01], colour)


## Loop 3d-2a: a run of unlowered sub-cells si0..si1 in sub-row sj of one half of an apron cell,
## as one quad (or a triangle at the diagonal) on the half's plane.
func _ground_run(st, pos: PackedVector3Array, nrm: PackedVector3Array, side: int, half: int, sj: int,
		si0: int, si1: int, colour: Color) -> void:
	var lb := Vector2i(si0, sj)
	var lt := Vector2i(si0, sj + 1)
	var rb := Vector2i(si1 + 1, sj)
	var rt := Vector2i(si1 + 1, sj + 1)
	if half == 0 and si0 == sj:
		lt = Vector2i(sj + 1, sj + 1)  # starts with the diagonal sub-cell's upper triangle
	if half == 1 and si1 == sj:
		rb = Vector2i(sj, sj)  # ends with the diagonal sub-cell's lower triangle
	if lb != rb and rb != rt:
		_ground_lattice_tri(st, pos, nrm, side, [lb, rb, rt], colour)
	if lt != rt and lb != lt:
		_ground_lattice_tri(st, pos, nrm, side, [lb, rt, lt], colour)


## Loop 3d-2a: one ground triangle between three lattice points of an apron cell, wound to face up.
func _ground_lattice_tri(st, pos: PackedVector3Array, nrm: PackedVector3Array, side: int, pts: Array,
		colour: Color) -> void:
	var ks: Array[int] = []
	for p: Vector2i in pts:
		ks.append(p.y * side + p.x)
	var order := [0, 1, 2]
	if ((pos[ks[1]] - pos[ks[0]]).cross(pos[ks[2]] - pos[ks[0]]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
		order = [0, 2, 1]
	for o in order:
		st.set_color(colour)
		st.set_normal(nrm[ks[o]])
		st.set_uv(Vector2(-1, -1))
		st.add_vertex(pos[ks[o]])
# --- end of map round 2 (D5) ------------------------------------------------------------------


## Loop 3d-2a: whether the pieces (flat polygons) together cover `poly` whole, to COVER_EPS m2:
## `poly` minus each piece in turn (Clipper). A piece that would cut a hole in what is left (it
## lies inside without touching its edge) is tried again after the others; the answer doesn't
## depend on the pieces' order. game/tools/check_ground.gd uses it too.
const COVER_EPS := 0.01
const COVER_SLIVER := 0.0001
## Loop 3d-2a: whether Clipper's results hold a hole: wound against the biggest one (an outline
## and the hole a piece lying wholly inside it cuts). Slivers under COVER_SLIVER m2 are dropped
## first: their windings and middles say nothing.
static func _has_hole(out: Array[PackedVector2Array]) -> bool:
	if out.size() < 2:
		return false
	var big := 0.0
	for o in out:
		var a := _poly_area(o)
		if absf(a) > absf(big):
			big = a
	for o in out:
		if _poly_area(o) * big < 0.0:
			return true
	return false


## Loop 3d-2a: how far past a ground triangle the flat layers must reach for it to be left out:
## a layer lies up to ~0.3 m over the drawn ground (a road's pieces over the grid's folds), and
## at the camera's 30 degree pitch a sight line under its edge reaches 1.7 times that inwards.
const COVER_MARGIN := 0.5
## Loop 3d-2a: a covering triangle counts when its centre lies this far under / over the grid: a
## road sunk under the ground (a hump the grid has and its pieces cut through) or standing over it
## (an approach) leaves a gap a sight line can reach, so the ground stays there.
const COVER_GRADE := Vector2(-0.25, 0.3)
## Loop 3d-2a: a sector lays the covering layers' pieces this far past its edge too (the ground
## triangles reaching out of it need them), and drops what lies outside by their tiles as before.
const COVER_REACH := 12.0
static func covers(poly: PackedVector2Array, pieces: Array[PackedVector2Array], area_test := true) -> bool:
	if area_test:
		var need := absf(_poly_area(poly)) - COVER_EPS
		var have := 0.0
		for p in pieces:
			have += absf(_poly_area(p))
		if have < need:
			return false
	var left: Array[PackedVector2Array] = [poly]
	var todo := pieces.duplicate()
	# Once no piece is left that cuts without a hole (`loose`), the rest are taken by their
	# outlines alone: what is left can only be overstated, never a gap missed.
	var loose := false
	while not todo.is_empty():
		var later: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in todo:
			var next: Array[PackedVector2Array] = []
			var holed := false
			for r in left:
				var res := Geometry2D.clip_polygons(r, piece)
				if res.size() < 2:
					next.append_array(res)
					continue
				var out: Array[PackedVector2Array] = []
				for o in res:
					if absf(_poly_area(o)) > COVER_SLIVER:
						out.append(o)
				if not _has_hole(out):
					next.append_array(out)
				elif loose:
					next.append_array(_outlines(out))
				else:
					holed = true  # an outline and a hole: keep r whole for now
					next.append(r)
			left = next
			if left.is_empty():
				return true
			if holed:
				later.append(piece)
		if _area_of(left) < COVER_EPS:
			return true
		if later.size() == todo.size():
			loose = true
		todo = later
	return _area_of(left) < COVER_EPS


static func _area_of(list: Array[PackedVector2Array]) -> float:
	var s := 0.0
	for r in list:
		s += absf(_poly_area(r))
	return s


## Loop 3d-2a: Clipper's results without their holes (wound like the biggest).
static func _outlines(out: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var big := 0.0
	for o in out:
		var a := _poly_area(o)
		if absf(a) > absf(big):
			big = a
	var keep: Array[PackedVector2Array] = []
	for o in out:
		if _poly_area(o) * big > 0.0:
			keep.append(o)
	return keep


# --- Loop 3d-2a (2026-10-30): no ground under what covers it ----------------------------------
# The flat layers laid on the ground (the areas: water, grass, parks, plazas, sand; paving,
# footways, steps, rail beds, roads and carriageway areas) are opaque and lie on or over the
# drawn ground, so a ground triangle one of them covers whole is drawn for nothing (Slop New
# York's "no ground under roads"). While those layers are laid (`_cover_on`) they note their
# outlines in plan per 10 m cell of the grid; the ground, built after them, leaves out a 10 m
# triangle they cover whole grown by COVER_MARGIN, so no sight line under a layer's edge reaches
# the gap. Not left out: the apron cells (their own drawing), the cells near an approach or an
# apron (the road there stands over the grid), the grid's outer row (the map's edge walls).
# Only at grade: a layer on a deck or in a tunnel notes nothing. game/tools/check_ground.gd
# counts what is still hidden and that nothing is left open.

## Ground triangles left out by the last build (a sector's, or the whole city's).
var ground_hidden := 0
## False: the ground as before loop 3d-2a (nothing left out, every apron sub-cell drawn), for
## check_ground.gd's before count (`--whole`).
var ground_lean := true
var _cover_on := false
var _cover: Array[PackedVector2Array] = []
var _cover_box: Array[Rect2] = []
## Grid cell (Vector2i) -> indices into _cover of the outlines whose boxes (grown by COVER_MARGIN)
## meet it.
var _cover_cells := {}
## Grid cells an area covers whole (its two triangles laid as they are).
var _cover_whole := {}
## Grid cell -> the summed area of the outlines filed under it (a quick "can't be covered").
var _cover_area := {}


func _cover_reset() -> void:
	_cover.clear()
	_cover_box.clear()
	_cover_cells.clear()
	_cover_whole.clear()
	_cover_area.clear()


## One outline (plan) of a flat layer on the ground, filed under the grid cells its box meets.
func _cover_add(poly: PackedVector2Array) -> void:
	if _t_h.is_empty() or poly.size() < 3:
		return
	var lo := poly[0]
	var hi := poly[0]
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	if _in_sector:
		# A sector tests the ground triangles in it: what lies over 24 m off can't cover them.
		var r := _sector_rect.grow(24.0)
		if hi.x < r.position.x or lo.x > r.end.x or hi.y < r.position.y or lo.y > r.end.y:
			return
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var k := _cover.size()
	_cover.append(poly)
	_cover_box.append(Rect2(lo, hi - lo))
	var area := absf(_poly_area(poly))
	# Filed under every cell its box grown by COVER_MARGIN meets (and a little: the grown outline's
	# square corners reach 0.6 m): a ground triangle's grown outline lies in its cell grown the
	# same, so its cell's list holds all that can cover it.
	var pad := COVER_MARGIN + 0.25
	for j in range(floori((lo.y - pad - gz) / step), floori((hi.y + pad - gz) / step) + 1):
		for i in range(floori((lo.x - pad - gx) / step), floori((hi.x + pad - gx) / step) + 1):
			var key := Vector2i(i, j)
			var list: PackedInt32Array = _cover_cells.get(key, PackedInt32Array())
			list.append(k)
			_cover_cells[key] = list
			_cover_area[key] = float(_cover_area.get(key, 0.0)) + area


## Whether the ground of the 10 m cell (i, j) stays whatever covers it: the grid's outer row (the
## map's edge walls meet it) and the cells near an approach or an apron (the road there stands
## over or under the grid; the apron cells are drawn on their own). check_ground.gd asks too.
func ground_kept(i: int, j: int) -> bool:
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	if i <= 0 or j <= 0 or i >= nx - 2 or j >= nz - 2:
		return true
	var step := float(_terrain["step"])
	var x := float(_terrain["x0"]) + i * step
	var z := float(_terrain["z0"]) + j * step
	for cz in range(floori((z - COVER_MARGIN) / FILL_CELL), floori((z + step + COVER_MARGIN) / FILL_CELL) + 1):
		for cx in range(floori((x - COVER_MARGIN) / FILL_CELL), floori((x + step + COVER_MARGIN) / FILL_CELL) + 1):
			var key := (cx + 1024) * 4096 + cz + 1024
			if _fill_cells.has(key) or _apron_cells.has(key):
				return true
	return false


## Whether the flat layers cover the 10 m cell (i, j)'s triangle whole, grown by COVER_MARGIN
## (`upper`: the u >= v one, (0,0)-(1,0)-(1,1)).
func _ground_hidden(i: int, j: int, upper: bool) -> bool:
	var step := float(_terrain["step"])
	var key := Vector2i(i, j)
	# What lies over the triangle is filed under its cell: less than its area can't cover it.
	if float(_cover_area.get(key, 0.0)) < step * step * 0.5 - COVER_EPS or ground_kept(i, j):
		return false
	# Inside an area (the river, a park): the cell and the eight round it covered whole.
	var whole := true
	for dj in range(-1, 2):
		for di in range(-1, 2):
			if whole and not _cover_whole.has(key + Vector2i(di, dj)):
				whole = false
	if whole:
		return true
	var x := float(_terrain["x0"]) + i * step
	var z := float(_terrain["z0"]) + j * step
	var tri := PackedVector2Array([Vector2(x, z), Vector2(x + step, z), Vector2(x + step, z + step)]) if upper \
			else PackedVector2Array([Vector2(x, z), Vector2(x + step, z + step), Vector2(x, z + step)])
	var list: PackedInt32Array = _cover_cells[key]
	# Quick no: the triangle's middle (nudged off the lines where pieces meet) under no piece.
	var mid := (tri[0] + tri[1] + tri[2]) / 3.0
	if not _cover_point(mid + Vector2(0.0011, 0.0007), list):
		return false
	var grown: PackedVector2Array = Geometry2D.offset_polygon(tri, COVER_MARGIN, Geometry2D.JOIN_SQUARE)[0]
	var lo := grown[0]
	var hi := grown[0]
	for p in grown:
		lo = lo.min(p)
		hi = hi.max(p)
	var pieces: Array[PackedVector2Array] = []
	for k: int in list:
		var box := _cover_box[k]
		if box.position.x < hi.x and box.end.x > lo.x and box.position.y < hi.y and box.end.y > lo.y:
			pieces.append(_cover[k])
	# ...then its grown corners and the middles of its sides.
	var n := grown.size()
	for s in n:
		for p: Vector2 in [grown[s], (grown[s] + grown[(s + 1) % n]) * 0.5]:
			if not _cover_point(p.lerp(mid, 0.013) + Vector2(0.0011, 0.0007), list):
				return false
	return covers(grown, pieces, false)


## Loop 3d-2a: whether a point lies under one of the listed outlines.
func _cover_point(p: Vector2, list: PackedInt32Array) -> bool:
	for k in list:
		if _cover_box[k].has_point(p) and Geometry2D.is_point_in_polygon(p, _cover[k]):
			return true
	return false
# --- end of loop 3d-2a ------------------------------------------------------------------------


func _build_ground(st) -> void:
	if _t_h.is_empty():
		var r := bounds
		_quad(st, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y),
				Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y), Vector3.UP, COL["ground"])
		return
	_build_edges(st)
	var step := float(_terrain["step"])
	var x0 := float(_terrain["x0"])
	var z0 := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var normals := _ground_normals()
	var colour: Color = COL["ground"]
	# Loop 3c: one sector builds only the cells that reach into it.
	var ci := Vector2i(0, nx - 1)
	var cj := Vector2i(0, nz - 1)
	if _in_sector:
		ci = Vector2i(clampi(floori((_sector_rect.position.x - x0) / step) - 1, 0, nx - 1),
				clampi(floori((_sector_rect.end.x - x0) / step) + 1, 0, nx - 1))
		cj = Vector2i(clampi(floori((_sector_rect.position.y - z0) / step) - 1, 0, nz - 1),
				clampi(floori((_sector_rect.end.y - z0) / step) + 1, 0, nz - 1))
	_fine_index()
	var hidden := 0
	for j in range(cj.x, cj.y):
		for i in range(ci.x, ci.y):
			if not outside.is_empty() and _cell_outside(x0 + i * step, z0 + j * step, step):
				continue  # map north: no ground where the map isn't
			if _fine_cells.has(Vector2i(i, j)):
				_ground_fine_cell(st, i, j, normals, colour)  # map round 2 (D5), loop 3d-2a
				continue
			var k00 := j * nx + i
			var k10 := k00 + 1
			var k01 := k00 + nx
			var k11 := k01 + 1
			for tri in [[k00, k10, k11], [k00, k11, k01]]:
				# Loop 3d-2a: not under a flat layer that covers it whole (a sector tests only its own:
				# the rest is dropped by its tile anyway).
				var mid := Vector2(x0 + (i + (0.6667 if tri[1] == k10 else 0.3333)) * step,
						z0 + (j + (0.3333 if tri[1] == k10 else 0.6667)) * step)
				if ground_lean and (not _in_sector or _sector_rect.has_point(mid)) and _ground_hidden(i, j, tri[1] == k10):
					hidden += 1
					continue
				var corners: Array[Vector3] = []
				for k in tri:
					corners.append(Vector3(x0 + (int(k) % nx) * step, _t_h[k], z0 + (int(k) / nx) * step))
				var order := [0, 1, 2]
				if ((corners[1] - corners[0]).cross(corners[2] - corners[0]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
					order = [0, 2, 1]
				for o in order:
					st.set_color(colour)
					st.set_normal(normals[tri[o]])
					st.set_uv(Vector2(-1, -1))
					st.add_vertex(corners[o])

	ground_hidden += hidden


func _build_areas(st) -> void:
	# Plazas first so parks, sand and water sit on top of them. Loop 3b-2: laid on the
	# terrain grid's own triangles (_fill_on_grid), so the bare earth never pokes through;
	# the beaches' sand (bake_banks.py) goes in under the water, which covers any of it
	# mapped past the edge.
	# Stadion Narodowy's grass embankment (landmarks.gd `embankment`): under every mapped
	# area, a few millimetres over the bare ground, so only the bank's bare slopes turn green.
	if _marks != null:
		_layer = L_GREEN
		for poly: PackedVector2Array in _marks.embankment:
			_fill_on_grid(st, poly, Y_AREA + BANK_Y, COL["grass"])
	for pass_kind in ["plaza", "green", "sand", "water"]:
		if pass_kind == "sand":
			_layer = L_SAND
			# Gap fills (`f`) under the sand, gravel over it: a millimetre apart, so where they
			# overlap the nearer one is always the same.
			for a in data.get("sand", []):
				var y := Y_AREA + (0.006 if a.has("f") else (0.008 if a.has("g") else 0.007))
				_fill_on_grid(st, _pts(a["p"]), y, GRAVEL if a.has("g") else SAND)
			continue
		for a in data["areas"]:
			var k: String = a["k"]
			var group := "plaza" if k == "plaza" else ("water" if k == "water" else "green")
			if group != pass_kind:
				continue
			# Green kinds a millimetre apart (park under grass under pitch), like the sand: laid on
			# the same grid triangles since loop 3b-2, a lawn inside a park was exactly coplanar
			# with it, and which colour won depended on the draw order (loop 3c's sectors split
			# the triangles differently, so the streamed park showed darker triangles).
			var green_y: float = GREEN_Y.get(k, 0.005)
			var y := Y_AREA + (green_y if group == "green" else 0.0) + (0.01 if group == "water" else 0.0)
			_layer = L_GREEN if group == "green" else (L_WATER if group == "water" else L_PLAZA)
			_fill_on_grid(st, _pts(a["p"]), y, COL[k])
	_layer = L_GROUND


## Loop 3b-2: sand, wet sand and earth, foam (sRGB). Sand is a little warmer and quieter than
## the bare ground (the art bible's day chroma: the ground is calmer than what you drive).
const SAND := Color("#c8b995")
const GRAVEL := Color("#a8a091")
const WET_GRAVEL := Color("#878071")
const WET_SAND := Color("#9c8c6d")
const DAMP_SAND := Color("#b0a07f")
const WET_EARTH := Color("#5f5f45")
const DAMP_EARTH := Color("#727253")
const FOAM := Color("#dce4e2")
## The natural bank's two wet bands (from the waterline inland) and the foam line (from the
## waterline out), metres; a sandbar's wet rim inside its outline. Pieces at most BAND_PIECE
## long, so the thin strips stay on the ground's folds.
const BAND_W := 0.9
const FOAM_W := 0.22
const RIM_W := 1.1
const BAND_PIECE := 2.0
## The sandbars' rim and foam depth biases (their fill lies on the grid at the caller's).
const SANDBAR_RIM_BIAS := 0.07
const SANDBAR_FOAM_BIAS := 0.09
var _sandbars: Array[PackedVector2Array] = []
var _sandbar_boxes: Array[Rect2] = []


## Loop 3b-2: the sandbars on the river (bake_banks.py: smoothed, no slivers), over the water:
## sand on the grid's triangles, a darker wet rim inside the outline and a foam line round it.
## The water test (water.bin) still counts them as river: the car never gets there.
func _build_sandbars(st) -> void:
	_sandbars.clear()
	_sandbar_boxes.clear()
	var gravel: Array[bool] = []
	for b in data.get("sandbars", []):
		var poly := _pts(b["p"])
		if poly.size() < 3:
			continue
		_sandbars.append(poly)
		gravel.append(b.has("g"))
		var box := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			box = box.expand(p)
		_sandbar_boxes.append(box.grow(0.5))
	var keep := _drape_bias
	for k in _sandbars.size():
		var poly := _sandbars[k]
		_drape_bias = keep
		_layer = L_SAND
		_fill_on_grid(st, poly, Y_AREA + 0.012, GRAVEL if gravel[k] else SAND)
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		var inside := _inside_sign(ring)
		_drape_bias = SANDBAR_RIM_BIAS
		_layer = L_WET
		_band(st, ring, inside, 0.0, RIM_W, WET_GRAVEL if gravel[k] else WET_SAND, Y_AREA + 0.03)
		_drape_bias = SANDBAR_FOAM_BIAS
		_layer = L_FOAM
		_band(st, ring, -inside, 0.0, FOAM_W, FOAM, Y_AREA + 0.04)
	_drape_bias = keep
	_layer = L_GROUND


## Which side of a closed ring its inside is on: +1 the side Vector2(-d.y, d.x) points to.
func _inside_sign(ring: PackedVector2Array) -> float:
	return 1.0 if _ring_area(ring) > 0.0 else -1.0


## A band along a polyline between `off0` and `off1` metres out on the side `sign` (+1 the side
## Vector2(-d.y, d.x) points to), mitred at the bends (as the shore stone is), laid on the
## surface (`y` over it) in pieces of at most BAND_PIECE. `skip` (optional) leaves out the
## pieces whose middle it says yes to.
func _band(st, poly: PackedVector2Array, sign: float, off0: float, off1: float, col: Color, y: float, skip := Callable()) -> void:
	var n := poly.size()
	if n < 2:
		return
	var closed := poly[0].distance_to(poly[n - 1]) < 0.05
	var mit := PackedVector2Array()
	mit.resize(n)
	for i in n:
		var prev := i - 1 if i > 0 else (n - 2 if closed else -1)
		var next := i + 1 if i < n - 1 else (1 if closed else -1)
		var na := Vector2.ZERO
		var nb := Vector2.ZERO
		if prev >= 0 and poly[i].distance_to(poly[prev]) > 0.01:
			var d := (poly[i] - poly[prev]).normalized()
			na = Vector2(-d.y, d.x)
		if next >= 0 and poly[next].distance_to(poly[i]) > 0.01:
			var d := (poly[next] - poly[i]).normalized()
			nb = Vector2(-d.y, d.x)
		var m := na + nb
		if m.length() < 0.01:
			m = na if na != Vector2.ZERO else nb
		m = m.normalized()
		var cos_half := maxf(m.dot(nb if nb != Vector2.ZERO else na), 0.5)
		mit[i] = m * (sign / cos_half)
	for i in n - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.02:
			continue
		var pieces := maxi(1, ceili(seg / BAND_PIECE))
		for k in pieces:
			var t0 := float(k) / pieces
			var t1 := float(k + 1) / pieces
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			if skip.is_valid() and skip.call((p0 + p1) * 0.5):
				continue
			var m0 := mit[i].lerp(mit[i + 1], t0)
			var m1 := mit[i].lerp(mit[i + 1], t1)
			_quad(st, Vector3(p0.x + m0.x * off0, y, p0.y + m0.y * off0), Vector3(p1.x + m1.x * off0, y, p1.y + m1.y * off0),
					Vector3(p1.x + m1.x * off1, y, p1.y + m1.y * off1), Vector3(p0.x + m0.x * off1, y, p0.y + m0.y * off1),
					Vector3.UP, col)


## Whether a point lies on a sandbar (a natural bank's foam stops where a sandbar meets it).
func _on_sandbar(p: Vector2) -> bool:
	for k in _sandbars.size():
		if _sandbar_boxes[k].has_point(p) and Geometry2D.is_point_in_polygon(p, _sandbars[k]):
			return true
	return false


func _build_paths(st) -> void:
	for p in data["paths"]:
		if p["k"] in ["cyclecross", "zebra"]:
			continue  # these lie on the road; the crossing builder paints them
		if p["k"] == "foot" and _in_pkin_forecourt(p["p"]):
			continue  # Teatr Studio's forecourt is one granite square, its bands drawn with it
		var col: Color = COL["cycle"] if p["k"] == "cycle" else COL["foot"]
		var y := Y_PATH + (0.005 if p["k"] == "cycle" else 0.0)
		_layer = L_CYCLE if p["k"] == "cycle" else L_FOOT
		_dk = int(p.get("dk", -1))
		_strip(st, _pts(p["p"]), float(p["w"]), y, col)
	_dk = -1
	_layer = L_GROUND


## Smooth roads loop 2: the depth bias of service roads and living streets (the streets' 0.3).
const MINOR_ROAD_BIAS := 0.25


## Roads as strips `w` wide around their centreline shifted `c` to the right, except
## where a mapped carriageway area already covers them ("hide": metres along the road).
func _build_roads(st) -> void:
	_layer = L_ROAD
	var keep := _drape_bias
	for r in data["roads"]:
		var minor: bool = r["k"] in ["service", "living_street"]
		var col: Color = COL["road_minor"] if minor else COL["road"]
		var w := float(r["w"])
		var y := Y_ROAD - (0.005 if minor else 0.0)
		# Smooth roads loop 2 (F's crop by the PKiN driveway): a service road's 10 m pieces sag
		# over the grid's folds unlike the street's they run into, so 5 mm under it was not enough
		# and its paler asphalt poked up through the street in flags cut along the grid lines.
		# A lower depth bias (between the rail beds' and the roads') keeps it under every street.
		_drape_bias = MINOR_ROAD_BIAS if minor and keep >= 0.0 else keep
		_dk = int(r.get("dk", -1))
		var full := _pts(r["p"])
		var tapered: bool = r.has("wv")
		for run in _visible_runs(full, r.get("hide", [])):
			if tapered:
				# Smooth roads (tools/road_smooth.py): a join's width step tapered over 20-30 m,
				# one mitred band whose ends are as wide as the next way's, so the round patches
				# at its ends and bends no longer bulge past the narrower way.
				var prof := _profile(r, full, run[3])
				var rp: PackedVector2Array = run[0]
				# Smooth roads loop 3: where the band goes under a mapped carriageway area, it runs
				# on half its width under the area (as a plain strip's square cap does), so an
				# area whose outline starts at a slant leaves no bare triangle by the kerb.
				var ws: PackedFloat32Array = prof[0]
				var cs: PackedFloat32Array = prof[1]
				if run[1] and rp.size() >= 2:
					rp.insert(0, rp[0] - (rp[1] - rp[0]).normalized() * ws[0] * 0.5)
					ws.insert(0, ws[0])
					cs.insert(0, cs[0])
				if run[2] and rp.size() >= 2:
					var e := rp.size() - 1
					rp.append(rp[e] + (rp[e] - rp[e - 1]).normalized() * ws[e] * 0.5)
					ws.append(ws[e])
					cs.append(cs[e])
				prof = [ws, cs]
				_band_var(st, rp, prof[0], prof[1], y, col)
				var mid := _offset_var(rp, prof[1])
				for i in rp.size():
					if i > 0 and i < rp.size() - 1:
						if absf((rp[i] - rp[i - 1]).angle_to(rp[i + 1] - rp[i])) <= 0.12:
							continue
					elif (i == 0 and run[1]) or (i == rp.size() - 1 and run[2]):
						continue
					# At a tapered join both ways are this wide: the patch only rounds the joint.
					_disc(st, mid[i], prof[0][i] * 0.5, y, col)
				continue
			var poly := _offset(run[0], float(r.get("c", 0.0)))
			# Smooth roads loop 6 (F's crop at Marszałkowska by Złota): the same half-width run
			# under a mapped carriageway area for a plain strip too, or an area outline that starts
			# at a slant leaves a bare triangle of pavement between the street and the tram bed.
			if run[1] and poly.size() >= 2:
				poly.insert(0, poly[0] - (poly[1] - poly[0]).normalized() * w * 0.5)
			if run[2] and poly.size() >= 2:
				var pe := poly.size() - 1
				poly.append(poly[pe] + (poly[pe] - poly[pe - 1]).normalized() * w * 0.5)
			_strip(st, poly, w, y, col, false)
			# Round patches fill the gaps at the ends and wherever the road bends; not
			# where an area takes over (the area has the exact shape there).
			for i in poly.size():
				var bend := 1.0
				if i > 0 and i < poly.size() - 1:
					bend = absf((poly[i] - poly[i - 1]).angle_to(poly[i + 1] - poly[i]))
				elif (i == 0 and run[1]) or (i == poly.size() - 1 and run[2]):
					continue
				if bend > 0.12:
					_disc(st, poly[i], w * 0.5, y, col)
	_drape_bias = keep
	_dk = -1
	_layer = L_GROUND


## Loop 3b: the tunnels' roads (`tunnels.roads`), on their tunnel's floor, with a centre line;
## under the ground, so seen only in the portals' mouths (and the car's x-ray inside).
func _build_tunnel_roads(st) -> void:
	_layer = L_ROAD
	for r in data.get("tunnels", {}).get("roads", []):
		_tn = int(r.get("tn", -1))
		if _tn < 0:
			continue
		var poly := _pts(r["p"])
		_strip(st, poly, float(r["w"]), Y_ROAD, COL["road"], true)
		_layer = L_MARK
		_dashes(st, poly, 0.0, 3.0, 6.0, 0.15)
		_layer = L_ROAD
	_tn = -1
	_layer = L_GROUND


## The stretches of a polyline outside the hidden [s0, s1] ranges: [points, cut at
## the start, cut at the end] each.
func _visible_runs(poly: PackedVector2Array, hide: Array) -> Array:
	if hide.is_empty():
		var all_s := PackedFloat32Array([0.0])
		for i in range(1, poly.size()):
			all_s.append(all_s[i - 1] + poly[i].distance_to(poly[i - 1]))
		return [[poly, false, false, all_s]]
	var runs := []
	var cur := PackedVector2Array()
	var cur_s := PackedFloat32Array()
	var cut_start := false
	var s := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		var cuts := [0.0, length]
		for h in hide:
			for c in [float(h[0]) - s, float(h[1]) - s]:
				if c > 0.0 and c < length:
					cuts.append(c)
		cuts.sort()
		for k in cuts.size() - 1:
			var c0: float = cuts[k]
			var c1: float = cuts[k + 1]
			if c1 - c0 < 0.001:
				continue
			var mid := s + (c0 + c1) * 0.5
			var hidden := false
			for h in hide:
				if mid >= float(h[0]) and mid <= float(h[1]):
					hidden = true
			var p0 := a.lerp(b, c0 / length) if length > 0.0 else a
			var p1 := a.lerp(b, c1 / length) if length > 0.0 else b
			if hidden:
				if cur.size() >= 2:
					runs.append([cur, cut_start, true, cur_s])
				cur = PackedVector2Array()
				cur_s = PackedFloat32Array()
				cut_start = true
			else:
				if cur.is_empty():
					cur.append(p0)
					cur_s.append(s + c0)
				cur.append(p1)
				cur_s.append(s + c1)
		s += length
	if cur.size() >= 2:
		runs.append([cur, cut_start, false, cur_s])
	return runs


## Smooth roads: a tapered road's (`wv`, `cv`: width and centre offset per point of `p`) width
## and offset at each distance in `along` (metres from its first point), by its cumulative length.
func _profile(r: Dictionary, full: PackedVector2Array, along: PackedFloat32Array) -> Array:
	var wv: Array = r["wv"]
	var cv: Array = r["cv"]
	var ws := PackedFloat32Array()
	var cs := PackedFloat32Array()
	var k := 0
	var s0 := 0.0
	for s in along:
		while k < full.size() - 2 and s0 + full[k].distance_to(full[k + 1]) < s:
			s0 += full[k].distance_to(full[k + 1])
			k += 1
		var ln := full[k].distance_to(full[k + 1]) if k < full.size() - 1 else 0.0
		var t := clampf((s - s0) / ln, 0.0, 1.0) if ln > 0.0 else 0.0
		var k1 := mini(k + 1, wv.size() - 1)
		ws.append(lerpf(float(wv[k]), float(wv[k1]), t))
		cs.append(lerpf(float(cv[k]), float(cv[k1]), t))
	return [ws, cs]


## A polyline moved off[i] metres to its right at point i, mitred at the corners.
static func _offset_var(poly: PackedVector2Array, off: PackedFloat32Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var back := (poly[i] - poly[i - 1]).normalized() if i > 0 else Vector2.ZERO
		var ahead := (poly[i + 1] - poly[i]).normalized() if i < n - 1 else Vector2.ZERO
		if back == Vector2.ZERO:
			back = ahead
		if ahead == Vector2.ZERO:
			ahead = back
		var r0 := Vector2(-back.y, back.x)
		var r1 := Vector2(-ahead.y, ahead.x)
		var m := (r0 + r1).normalized()
		if m == Vector2.ZERO:
			m = r1
		out.append(poly[i] + m * off[i] / maxf(m.dot(r1), 0.5))
	return out


## A band between two offset lines of `poly` (widths and centre offsets per point): one quad per
## piece, shared edges, so its width can change smoothly along it (cut into the 10 m pieces the
## draped strips use).
func _band_var(st, poly: PackedVector2Array, ws: PackedFloat32Array, cs: PackedFloat32Array, y: float, col: Color) -> void:
	var lo := PackedFloat32Array()
	var hi := PackedFloat32Array()
	for i in poly.size():
		lo.append(cs[i] - ws[i] * 0.5)
		hi.append(cs[i] + ws[i] * 0.5)
	var left := _offset_var(poly, lo)
	var right := _offset_var(poly, hi)  # + is to the right, as _strip's `side`
	for i in poly.size() - 1:
		var d := poly[i + 1] - poly[i]
		if d.length() < 0.01:
			continue
		_axis = d.normalized()
		var pieces := maxi(1, ceili(d.length() / 10.0)) if _drape_bias >= 0.0 else 1
		for k in pieces:
			var t0 := float(k) / pieces
			var t1 := float(k + 1) / pieces
			var a := right[i].lerp(right[i + 1], t0)
			var b := right[i].lerp(right[i + 1], t1)
			var c := left[i].lerp(left[i + 1], t1)
			var e := left[i].lerp(left[i + 1], t0)
			_quad(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3(e.x, y, e.y), Vector3.UP, col)
	_axis = Vector2.ZERO


## A polyline moved `off` metres to its right, mitred at the corners.
static func _offset(poly: PackedVector2Array, off: float) -> PackedVector2Array:
	if absf(off) < 0.001:
		return poly
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var back := (poly[i] - poly[i - 1]).normalized() if i > 0 else Vector2.ZERO
		var ahead := (poly[i + 1] - poly[i]).normalized() if i < n - 1 else Vector2.ZERO
		if back == Vector2.ZERO:
			back = ahead
		if ahead == Vector2.ZERO:
			ahead = back
		var r0 := Vector2(-back.y, back.x)
		var r1 := Vector2(-ahead.y, ahead.x)
		var m := (r0 + r1).normalized()
		if m == Vector2.ZERO:
			m = r1
		out.append(poly[i] + m * off / maxf(m.dot(r1), 0.5))
	return out


## Mapped carriageway areas (area:highway): the exact road surface, junction boxes
## and bus bays included; hatched areas are asphalt too (the hatching comes later).
func _build_carriageways(st) -> void:
	_layer = L_ROAD
	var keep := _drape_bias
	for c in data.get("carriage", []):
		_dk = int(c.get("dk", -1))
		var minor: bool = c["k"] in ["service", "living_street"]
		_drape_bias = MINOR_ROAD_BIAS if minor and keep >= 0.0 else keep
		_fill(st, _pts(c["p"]), Y_ROAD - (0.005 if minor else 0.0), COL["road_minor"] if minor else COL["road"])
	# Round 3 (F: "one clean asphalt surface"): the bare pockets walled in by roads where a
	# driveway leaves a street (`asphalt_fills`, tools/road_smooth.py fill_pockets).
	_drape_bias = MINOR_ROAD_BIAS if keep >= 0.0 else keep
	for f in data.get("asphalt_fills", []):
		_fill(st, _pts(f["p"]), Y_ROAD - 0.005, COL["road"])
	_drape_bias = keep
	_dk = -1
	_layer = L_GROUND


const SURFACE_STYLE := {
	"paving": ["#ddd6c8", 4.0],
	# Krajobraz K2 (2026-11-02): Chmielna's new granite slabs (tools/planted_trees.py re-tags its
	# pedestrian areas), a cooler grey than the old concrete setts' warm paving.
	"granite": ["#c9c7c1", 4.0],
	"ballast": ["#8f887d", 15.0],
	"flowerbed": ["#6c9844", 11.0],
	"construction": ["#a48b6a", 12.0],
	"playground": ["#c98a64", 13.0],
	"fountain": ["#5ea8d8", 3.0],
}


## Paved surfaces that are really lawn (OpenStreetMap tags them `paving`): the Royal Castle's
## Lower Garden's sunken lawn carpet (Ogród Dolny, restored 2019; GUGiK orthophoto and the
## castle's photos, docs/landmarks/specs/zamek.md "Gardens"). Each is the outline's vertex mean.
const LAWN_CARPETS := [Vector2(-484.6, -1614.6)]
const LAWN_CARPET := "#78a84a"


func _is_lawn_carpet(flat: Array) -> bool:
	var c := Vector2.ZERO
	var n := 0
	for i in range(0, flat.size() - 1, 2):
		c += Vector2(flat[i], flat[i + 1])
		n += 1
	if n == 0:
		return false
	c /= n
	for at: Vector2 in LAWN_CARPETS:
		if c.distance_to(at) < 3.0:
			return true
	return false


## Loop 3b-2: a surface the bake put on a bridge deck (`dk`: a bridge's pavement or tram bed,
## bake_roads.py level_surfaces) is laid on the deck; the rest on the ground's own triangles.
func _build_surfaces(st) -> void:
	var platforms := _rail_platform_polys()
	for a in data.get("surfaces", []):
		var style: Array = SURFACE_STYLE.get(a["k"], ["#cfc7b5", 0.0])
		if a["k"] == "paving" and _is_lawn_carpet(a["p"]):
			style = [LAWN_CARPET, style[1]]
		_layer = float(style[1])
		_dk = int(a.get("dk", -1))
		if _dk >= 0:
			_fill(st, _pts(a["p"]), Y_AREA + 0.01, Color(style[0]))
		elif a["k"] == "ballast":
			for part in _cut_out(_pts(a["p"]), platforms):
				_fill_on_grid(st, part, Y_AREA + 0.01, Color(style[0]))
		else:
			_fill_on_grid(st, _pts(a["p"]), Y_AREA + 0.01, Color(style[0]))
	_dk = -1
	_build_pkin_ground(st)
	_layer = L_GROUND


## OSM's railway platforms (0.9 m) as outlines with their boxes. The ballast (landuse=railway)
## round them is laid on the ground's triangles, which rise onto a platform's top: drawn there it
## covered Stadion's and Wschodnia's platforms in brown stones (2026-11-06), so it is cut away.
func _rail_platform_polys() -> Array:
	var out := []
	for a in data.get("platforms", []):
		if float(a["h"]) < 0.7:
			continue
		var poly := _pts(a["p"])
		if poly.size() < 3:
			continue
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		out.append([box, poly])
	return out


## `poly` without the outlines in `holes` ([box, outline] each): a hole wholly inside is split
## off by a line through its middle first (a polygon fill has no holes).
func _cut_out(poly: PackedVector2Array, holes: Array) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = [poly]
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	for h: Array in holes:
		if not box.intersects(h[0]):
			continue
		var hole: PackedVector2Array = h[1]
		var next: Array[PackedVector2Array] = []
		for p in parts:
			var cut := Geometry2D.clip_polygons(p, hole)
			var holed := false
			for c in cut:
				holed = holed or Geometry2D.is_polygon_clockwise(c)
			if not holed:
				next.append_array(cut)
				continue
			var hb: Rect2 = h[0]
			var mid := hb.get_center()
			var big := 1.0e5
			for half: PackedVector2Array in [
					PackedVector2Array([Vector2(-big, -big), Vector2(mid.x, -big), Vector2(mid.x, big), Vector2(-big, big)]),
					PackedVector2Array([Vector2(mid.x, -big), Vector2(big, -big), Vector2(big, big), Vector2(mid.x, big)])]:
				for piece in Geometry2D.intersect_polygons(p, half):
					if Geometry2D.is_polygon_clockwise(piece):
						continue
					for c in Geometry2D.clip_polygons(piece, hole):
						if not Geometry2D.is_polygon_clockwise(c):
							next.append(c)
		parts = next
	return parts


func _build_steps(st) -> void:
	_layer = L_STEPS
	# Smooth roads loop 7 (F's ChatGPT target, 2026-11-05): a flight that ends at a metro
	# entrance (`down`, tools/road_smooth.py metro_steps) goes down into it: its treads darken
	# towards the entrance's deep end.
	for p in data.get("steps", []):
		var poly := _pts(p["p"])
		var deep := int(p.get("down", -1))
		if deep < 0 or poly.size() != 2:
			_strip(st, poly, 2.4, Y_PATH + 0.01, Color("#d2cabb"))
			continue
		var top := poly[1 - deep]
		var bottom := poly[deep]
		var length := top.distance_to(bottom)
		var n := maxi(2, int(length / 0.34))
		var dir := (bottom - top) / length
		for i in n:
			var k := float(i) / float(n - 1)
			var tone := Color("#d2cabb").lerp(Color("#34363b"), k * k * 0.85 + k * 0.15)
			var a := top + dir * (length * float(i) / float(n))
			var b := top + dir * (length * float(i + 1) / float(n))
			_strip(st, PackedVector2Array([a, b]), 2.4, Y_PATH + 0.01, tone, false)
	_layer = L_GROUND


# --- stairs across the city ----------------------------------------------------

## Stairs across the city (F, 2026-11-07: "look on the map to the places where we have stairs,
## map them and improve"). Every OSM flight was a flat beige strip on the ground with painted
## tread lines (_build_steps), so Kamienne Schodki, the Skarpa's stairs and the stairs off the
## viaducts read as a ramp of paint on a slope. Where the flight drops at least STAIR_MIN_DROP
## (over the drawn ground, or from a deck the flight starts on) it is now a stone flight: flat
## treads and risers of about STAIR_RISER each (a stretch where the ground levels off becomes a
## landing), cheek walls down to the ground on both sides, the handrails OSM maps (`hr`) and
## the pram channels of a ramp (`rp`). The tags come from tools/stairs.py (`n`, `w`, `hr`, `rp`,
## `sf`, `br`). They go into the building meshes (no new draw call) and don't collide: the car
## drives the ground under them as before. Flights in a sunken place (SUNKEN: its site draws the
## treads), escalators (`cv`) and those in STAIR_SKIP (a landmark that builds its own) stay flat.
const STAIR_MIN_DROP := 0.35
const STAIR_RISER := 0.16
## Treads at least this deep (a short steep flight gets taller risers, not paper-thin treads).
const STAIR_MIN_TREAD := 0.26
const STAIR_SAMPLE := 0.25
const STAIR_CHEEK_W := 0.28
const STAIR_CHEEK_UP := 0.16
const STAIR_TONE := {"stone": "#c6c0b4", "concrete": "#b7b3aa", "sett": "#a29b91", "metal": "#767b81",
		"wood": "#8d6e50", "": "#c2bcb0"}
const STAIR_CHEEK := Color("#a49e93")
const STAIR_RAIL := Color("#2c3035")
## Places whose stairs a landmark builds itself (centre, half size): Most Poniatowskiego's tower
## stairs (landmarks._pt_ramp).
const STAIR_SKIP: Array[Rect2] = []


## Every flight's 3D build (see above). Returns how many flights were built.
func _build_stair_flights(st) -> int:
	_uv2 = Vector2(0.5, -1.0)
	var built := 0
	for s in data.get("steps", []):
		if int(s.get("cv", 0)) == 1:
			continue
		var poly := _pts(s["p"])
		if poly.size() < 2 or _stair_skipped(poly):
			continue
		if _stair_flight(st, s, poly):
			built += 1
	_uv2 = Vector2.ZERO
	return built


func _stair_skipped(poly: PackedVector2Array) -> bool:
	for q in [poly[0], poly[poly.size() - 1]]:
		if not _sunk.is_empty() and _sunk_box.grow(1.0).has_point(q) and not is_inf(sunk_floor(q.x, q.y, true)):
			return true
		for r: Rect2 in STAIR_SKIP:
			if r.has_point(q):
				return true
	return false


## How far over the ground the flight's end `at` stands: a deck's height when the flight starts
## on one (a stair off a viaduct or a bridge: its step count, or OSM's bridge tag, says it climbs
## that far), else 0.
func _stair_end_lift(s: Dictionary, at: Vector2, other: Vector2) -> float:
	var g := terrain_height(at.x, at.y)
	var want := float(s.get("n", 0)) * STAIR_RISER
	var best := 0.0
	for d in _decks_at(at.x, at.y):
		var lift := d - g
		if lift < 1.2 or lift > 16.0:
			continue
		var fits := absf(lift - want) < maxf(2.0, want * 0.45) if want > 0.0 else int(s.get("br", 0)) == 1
		if not fits:
			continue
		# A flight under the deck (both ends under it) stays on the ground.
		var under := false
		for e in _decks_at(other.x, other.y):
			if absf(e - d) < 0.5:
				under = true
		if not under:
			best = maxf(best, lift)
	return best


## One flight as stone steps; false when it drops too little to show (it stays a painted strip).
func _stair_flight(st, s: Dictionary, poly: PackedVector2Array) -> bool:
	var lengths := PackedFloat32Array([0.0])
	for i in poly.size() - 1:
		lengths.append(lengths[i] + poly[i].distance_to(poly[i + 1]))
	var total := lengths[lengths.size() - 1]
	if total < 0.6:
		return false
	var lift0 := _stair_end_lift(s, poly[0], poly[poly.size() - 1])
	var lift1 := _stair_end_lift(s, poly[poly.size() - 1], poly[0])
	var hw := clampf(float(s.get("w", 2.4)), 1.0, 30.0) * 0.5
	# The profile: the drawn ground under the line (its highest point across the flight, so no
	# tread sinks into a side slope), plus a deck end's lift blended along it.
	var n_samp := maxi(2, ceili(total / STAIR_SAMPLE) + 1)
	var at: Array[Vector2] = []
	var dirs: Array[Vector2] = []
	var prof := PackedFloat32Array()
	var seg := 0
	for k in n_samp:
		var d := total * float(k) / float(n_samp - 1)
		while seg < poly.size() - 2 and d > lengths[seg + 1]:
			seg += 1
		var a := poly[seg]
		var b := poly[seg + 1]
		var sl := maxf(lengths[seg + 1] - lengths[seg], 0.001)
		var p := a.lerp(b, clampf((d - lengths[seg]) / sl, 0.0, 1.0))
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x) * hw
		var g := maxf(terrain_height(p.x, p.y), maxf(terrain_height(p.x + side.x, p.y + side.y),
				terrain_height(p.x - side.x, p.y - side.y)))
		var t := d / total
		at.append(p)
		dirs.append(dir)
		prof.append(g + lift0 * (1.0 - t) + lift1 * t)
	var low_first := prof[0] <= prof[n_samp - 1]
	var drop := absf(prof[n_samp - 1] - prof[0])
	if drop < STAIR_MIN_DROP:
		return false
	# Monotone from the foot up (a hump in the ground is the flight's own climb), then cut into
	# risers of drop / n: each sample's tread is the level at or over its ground.
	var risers := clampi(roundi(drop / STAIR_RISER), 2, maxi(2, floori(total / STAIR_MIN_TREAD)))
	var rise := drop / float(risers)
	var foot := minf(prof[0], prof[n_samp - 1])
	var level := PackedInt32Array()
	level.resize(n_samp)
	var run_max := -INF
	for j in n_samp:
		var k := j if low_first else n_samp - 1 - j
		run_max = maxf(run_max, prof[k])
		level[k] = clampi(ceili((run_max - foot) / rise - 0.001), 0, risers)
	var tone := Color(str(STAIR_TONE.get(str(s.get("sf", "")), STAIR_TONE[""])))
	var riser_col := tone.darkened(0.22)
	# Treads: the sample pieces at one level along one straight piece of the line are one quad at
	# that level (the step's top), with a riser where the level changes.
	var nosing := PackedVector3Array()   # the line over each tread's front edge, for cheeks and rails
	var run0 := 0
	for k in n_samp - 1:
		var lv := maxi(level[k], level[k + 1])
		var y := foot + rise * float(lv)
		nosing.append(Vector3(at[k].x, y, at[k].y))
		var last := k + 1 >= n_samp - 1
		var lv2 := lv if last else maxi(level[k + 1], level[k + 2])
		if not last and lv2 == lv and dirs[k + 1].is_equal_approx(dirs[k]):
			continue
		var a := at[run0]
		var b := at[k + 1]
		var side := Vector2(-dirs[k].y, dirs[k].x) * hw
		var shade := tone if (lv % 2 == 0) else tone.darkened(0.035)
		_quad(st, Vector3(a.x + side.x, y, a.y + side.y), Vector3(b.x + side.x, y, b.y + side.y),
				Vector3(b.x - side.x, y, b.y - side.y), Vector3(a.x - side.x, y, a.y - side.y), Vector3.UP, shade)
		run0 = k + 1
		if not last and lv2 != lv:
			var y2 := foot + rise * float(lv2)
			var face := Vector3(dirs[k].x, 0.0, dirs[k].y) * (1.0 if lv2 < lv else -1.0)
			_quad(st, Vector3(b.x + side.x, minf(y, y2), b.y + side.y), Vector3(b.x - side.x, minf(y, y2), b.y - side.y),
					Vector3(b.x - side.x, maxf(y, y2), b.y - side.y), Vector3(b.x + side.x, maxf(y, y2), b.y + side.y), face, riser_col)
	nosing.append(Vector3(at[n_samp - 1].x, foot + rise * float(level[n_samp - 1]), at[n_samp - 1].y))
	# The end risers down to the ground at the foot (a deck end's flight stands on its block).
	for e in [0, n_samp - 1]:
		var p: Vector2 = at[e]
		var dir: Vector2 = dirs[mini(e, n_samp - 2)]
		var side := Vector2(-dir.y, dir.x) * hw
		var y := foot + rise * float(level[e])
		var g := terrain_height(p.x, p.y) - 0.3
		if y - g > 0.35:
			var face := Vector3(dir.x, 0.0, dir.y) * (1.0 if e == n_samp - 1 else -1.0)
			_quad(st, Vector3(p.x + side.x, g, p.y + side.y), Vector3(p.x - side.x, g, p.y - side.y),
					Vector3(p.x - side.x, y, p.y - side.y), Vector3(p.x + side.x, y, p.y + side.y), face, riser_col)
	# Cheeks: a wall each side, its top over the nosings (simplified), its foot in the ground.
	var line := _stair_simplify(nosing, 0.1)
	for sgn in [1.0, -1.0]:
		_stair_cheek(st, line, hw * sgn, sgn)
	var hr := int(s.get("hr", 0))
	if hr & 1:
		_stair_rail(st, line, hw - 0.12)
	if hr & 2:
		_stair_rail(st, line, -(hw - 0.12))
	if hr & 4 and hw > 1.6:
		_stair_rail(st, line, 0.0)
	if int(s.get("rp", 0)) == 1 and hw > 0.9:
		_stair_channels(st, line, -(hw - 0.5))
	return true


## Keeps the points of a polyline that bend it by more than `tol` (Douglas-Peucker in 3D).
static func _stair_simplify(pts: PackedVector3Array, tol: float) -> PackedVector3Array:
	if pts.size() <= 2:
		return pts
	var keep := PackedByteArray()
	keep.resize(pts.size())
	keep[0] = 1
	keep[pts.size() - 1] = 1
	var stack: Array[Vector2i] = [Vector2i(0, pts.size() - 1)]
	while not stack.is_empty():
		var r: Vector2i = stack.pop_back()
		var a := pts[r.x]
		var b := pts[r.y]
		var worst := -1
		var far := tol
		for i in range(r.x + 1, r.y):
			var d := Geometry3D.get_closest_point_to_segment(pts[i], a, b).distance_to(pts[i])
			if d > far:
				far = d
				worst = i
		if worst > 0:
			keep[worst] = 1
			stack.append(Vector2i(r.x, worst))
			stack.append(Vector2i(worst, r.y))
	var out := PackedVector3Array()
	for i in pts.size():
		if keep[i]:
			out.append(pts[i])
	return out


## The plan offset `off` to the left of the line's direction at point i.
static func _stair_off(line: PackedVector3Array, i: int, off: float) -> Vector3:
	var a := line[maxi(i - 1, 0)]
	var b := line[mini(i + 1, line.size() - 1)]
	var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
	return Vector3(-dir.y * off, 0.0, dir.x * off)


func _stair_cheek(st, line: PackedVector3Array, off: float, sgn: float) -> void:
	for i in line.size() - 1:
		var o0 := _stair_off(line, i, off)
		var o1 := _stair_off(line, i + 1, off)
		var w0 := _stair_off(line, i, off + STAIR_CHEEK_W * sgn)
		var w1 := _stair_off(line, i + 1, off + STAIR_CHEEK_W * sgn)
		var a := line[i]
		var b := line[i + 1]
		var ta := a.y + STAIR_CHEEK_UP
		var tb := b.y + STAIR_CHEEK_UP
		var ga := terrain_height(a.x + w0.x, a.z + w0.z) - 0.3
		var gb := terrain_height(b.x + w1.x, b.z + w1.z) - 0.3
		var ia := Vector3(a.x + o0.x, ta, a.z + o0.z)
		var ib := Vector3(b.x + o1.x, tb, b.z + o1.z)
		var oa := Vector3(a.x + w0.x, ta, a.z + w0.z)
		var ob := Vector3(b.x + w1.x, tb, b.z + w1.z)
		var out_n := Vector3(w0.x - o0.x, 0.0, w0.z - o0.z).normalized()
		_quad(st, ia, ib, ob, oa, Vector3.UP, STAIR_CHEEK.lightened(0.06))
		_quad(st, Vector3(oa.x, ga, oa.z), Vector3(ob.x, gb, ob.z), ob, oa, out_n, STAIR_CHEEK)
		_quad(st, Vector3(ia.x, minf(a.y, ga), ia.z), Vector3(ib.x, minf(b.y, gb), ib.z), ib, ia, -out_n, STAIR_CHEEK.darkened(0.05))
	# The cheeks' end faces.
	for e in [0, line.size() - 1]:
		var p := line[e]
		var o := _stair_off(line, e, off)
		var w := _stair_off(line, e, off + STAIR_CHEEK_W * sgn)
		var g := terrain_height(p.x + w.x, p.z + w.z) - 0.3
		var t := p.y + STAIR_CHEEK_UP
		var n := Vector3(line[mini(e + 1, line.size() - 1)] - line[maxi(e - 1, 0)]).normalized() * (-1.0 if e == 0 else 1.0)
		n.y = 0.0
		_quad(st, Vector3(p.x + o.x, g, p.z + o.z), Vector3(p.x + w.x, g, p.z + w.z), Vector3(p.x + w.x, t, p.z + w.z),
				Vector3(p.x + o.x, t, p.z + o.z), n.normalized(), STAIR_CHEEK)


## A steel handrail `off` to the left of the flight's line, 0.9 m over the nosings, on posts.
func _stair_rail(st, line: PackedVector3Array, off: float) -> void:
	var run := 0.0
	var next_post := 0.3
	for i in line.size() - 1:
		var a := line[i] + _stair_off(line, i, off)
		var b := line[i + 1] + _stair_off(line, i + 1, off)
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		if length < 0.05:
			continue
		var up := Vector3(0.0, 0.9, 0.0)
		var dir := (b - a).normalized()
		var basis := Basis.looking_at(dir, Vector3.UP)
		_box_oriented(st, (a + b) * 0.5 + up, basis, Vector3(0.05, 0.05, a.distance_to(b)), STAIR_RAIL)
		while next_post <= run + length:
			var p := a.lerp(b, (next_post - run) / length)
			_box_oriented(st, p + Vector3(0.0, 0.45, 0.0), Basis.IDENTITY, Vector3(0.045, 0.9, 0.045), STAIR_RAIL)
			next_post += 1.8
		run += length


## A pram ramp: two shallow steel channels running down the flight over the treads.
func _stair_channels(st, line: PackedVector3Array, off: float) -> void:
	for d in [-0.28, 0.28]:
		for i in line.size() - 1:
			var a := line[i] + _stair_off(line, i, off + d)
			var b := line[i + 1] + _stair_off(line, i + 1, off + d)
			var s0 := _stair_off(line, i, 0.07)
			var s1 := _stair_off(line, i + 1, 0.07)
			var lift := Vector3(0.0, 0.04, 0.0)
			_quad(st, a + s0 + lift, b + s1 + lift, b - s1 + lift, a - s0 + lift, Vector3.UP, Color("#8a8f94"))


## Kerbs: raised granite strips along the carriageway edges, KERB_UP high.
const KERB_UP := 0.14
const KERB_W := 0.3
const KERB_TOP := Color("#b9b6ae")
const KERB_FACE := Color("#8d8a83")


## Traffic islands, raised to kerb height (their kerb comes with the kerbs).
func _build_islands(st) -> void:
	_layer = L_ISLAND
	for a in data.get("islands", []):
		_dk = int(a.get("dk", -1))
		_fill(st, _pts(a["p"]), KERB_UP, Color("#d3cdc1"))
	_dk = -1
	_layer = L_GROUND


## Loop 3b-2: the tram bed (a median with trams) a concrete track slab, darker than the
## pavements (its pale grey read as pavement, and with dark rails on it as a barcode), and the
## tram rails thinner and closer to it in tone.
const TRAM_BED := Color("#8f887d")
const TRAM_RAIL := Color("#6a6761")
const TRAM_RAIL_W := 0.16
const TRAM_SLEEPER_W := 2.4
const TRAM_GRAVEL := Color("#958e83")
const TRAM_XING := Color("#a9a69f")


## Dual-carriageway medians: raised grass, or the tram bed at road level where trams run.
func _build_medians(st) -> void:
	for m in data.get("medians", []):
		_dk = int(m.get("dk", -1))
		var grass: bool = m["k"] == "grass"
		# Smooth roads loop 7 (F's ChatGPT target): the bed is gravel, as the ballast round it.
		_layer = L_GREEN if grass else L_GRAVEL
		var col: Color = COL["grass"] if grass else TRAM_BED
		var y := KERB_UP if grass else Y_ROAD + 0.005
		var s4: Array = m["s"]
		for i in range(0, s4.size() - 7, 4):
			var a := Vector3(s4[i], y, s4[i + 1])
			var b := Vector3(s4[i + 2], y, s4[i + 3])
			var c := Vector3(s4[i + 6], y, s4[i + 7])
			var d := Vector3(s4[i + 4], y, s4[i + 5])
			# The street's axes in UV2 (the slab joints run across the bed).
			_axis = Vector2(d.x - a.x, d.z - a.z).normalized() if not grass else Vector2.ZERO
			_quad(st, a, b, c, d, Vector3.UP, col)
	_axis = Vector2.ZERO
	_dk = -1
	_layer = L_GROUND


func _build_kerbs(st) -> void:
	_layer = L_ISLAND
	# Baked edges: the outside (pavement, median) is on the line's right.
	for k in data.get("kerbs", []):
		_dk = int(k.get("dk", -1))
		_kerb(st, _pts(k["p"]), 1.0)
	# Islands: kerbed all round, the face looking out at the road.
	for a in data.get("islands", []):
		_dk = int(a.get("dk", -1))
		var poly := _pts(a["p"])
		if poly.size() < 3:
			continue
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		# With +z south, a clockwise ring seen from above has its inside on the right.
		var cw := _ring_area(poly) > 0.0
		_kerb(st, ring, 1.0 if cw else -1.0)
	_dk = -1
	_layer = L_GROUND


static func _ring_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## A kerb along a polyline: the raised side `side` (1 = right, -1 = left) gets a granite
## top KERB_W wide; the face drops to the road along the line.
func _kerb(st, poly: PackedVector2Array, side: float) -> void:
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		var length := d.length()
		if length < 0.02:
			continue
		var dir := d / length
		var out := Vector2(-dir.y, dir.x) * side
		# Overlap the next piece a little, so corners don't open up.
		var a2 := a - dir * 0.05
		var b2 := b + dir * 0.05
		var pieces := maxi(1, ceili(length / 10.0))
		for k in pieces:
			var p := a2.lerp(b2, float(k) / pieces)
			var q := a2.lerp(b2, float(k + 1) / pieces)
			var po := p + out * KERB_W
			var qo := q + out * KERB_W
			_quad(st, Vector3(p.x, KERB_UP, p.y), Vector3(q.x, KERB_UP, q.y), Vector3(qo.x, KERB_UP, qo.y),
					Vector3(po.x, KERB_UP, po.y), Vector3.UP, KERB_TOP)
		_draped_wall(st, a2, b2, Y_ROAD - 0.02, KERB_UP, -out, KERB_FACE)


## A vertical face laid along the surface from a to b, between heights y0 and y1 above
## it, looking towards `facing` (so it shows from that side only).
func _draped_wall(st, a: Vector2, b: Vector2, y0: float, y1: float, facing: Vector2, col: Color) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / 10.0))
	var normal := Vector3(facing.x, 0.0, facing.y).normalized()
	for k in n:
		var p := a.lerp(b, float(k) / n)
		var q := a.lerp(b, float(k + 1) / n)
		if _in_sector and not _touches(Vector3(p.x, 0.0, p.y), Vector3(q.x, 0.0, q.y), Vector3(p.x, 0.0, p.y)):
			continue  # loop 3c
		var hp := _surface_height(p.x, p.y)
		var hq := _surface_height(q.x, q.y)
		var v := [Vector3(p.x, hp + y0, p.y), Vector3(q.x, hq + y0, q.y), Vector3(q.x, hq + y1, q.y), Vector3(p.x, hp + y1, p.y)]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var t0: Vector3 = v[tri[0]]
			var t1: Vector3 = v[tri[1]]
			var t2: Vector3 = v[tri[2]]
			var order := [t0, t1, t2]
			if ((t1 - t0).cross(t2 - t0).dot(normal) > 0.0) == CLOCKWISE_FRONT:
				order = [t0, t2, t1]
			for w in order:
				st.set_color(col)
				st.set_normal(normal)
				st.set_uv(Vector2(_drape_bias, _layer))
				st.set_uv2(Vector2.ZERO)
				st.add_vertex(w)


## Railway track bed (L1 of docs/design/railway.md): a pale ballast shoulder 4.6 m wide, and on
## it the dark bed 2.7 m wide that the shader (ground.gdshader, layer 9) cuts into concrete
## sleepers every 0.65 m. Same mesh and material as before: no new draw call.
func _build_rail_beds(st) -> void:
	var bias := _drape_bias
	_exact_strip = true
	for r in Trains.trim_rails(data.get("rails", [])):
		_dk = int(r.get("dk", -1))
		var poly := _pts(r["p"])
		_layer = L_GRAVEL
		_drape_bias = bias - 0.02
		_strip(st, poly, 4.6, Y_PATH, Color("#8d8579"))
		_layer = L_BALLAST
		_drape_bias = bias
		_strip(st, poly, 2.7, Y_PATH, Color("#615b54"))
	_drape_bias = bias
	_exact_strip = false
	_dk = -1
	_layer = L_GROUND


func _build_rails(st) -> void:
	_layer = L_RAIL
	_exact_strip = true
	for r in Trains.trim_rails(data.get("rails", [])):
		_dk = int(r.get("dk", -1))
		var poly := _pts(r["p"])
		for side in [-0.72, 0.72]:
			var rail := PackedVector2Array()
			for i in poly.size():
				var d: Vector2 = (poly[mini(i + 1, poly.size() - 1)] - poly[maxi(i - 1, 0)]).normalized()
				rail.append(poly[i] + Vector2(-d.y, d.x) * side)
			_strip(st, rail, 0.2, Y_MARK + 0.005, Color("#3b3836"))
			# The rail head: a thin worn-steel line along the top, so the pair reads as rails.
			_strip(st, rail, 0.07, Y_MARK + 0.008, Color("#a29d94"))
	_exact_strip = false
	_dk = -1
	_layer = L_GROUND


## A solid along a polyline whose foot follows the terrain: hedges, fences, walls,
## platforms drawn as lines. Goes into the building meshes (UV.x < 0: no windows).
func _wall_along(st, poly: PackedVector2Array, width: float, height: float, col: Color, collide: bool) -> void:
	var hw := width * 0.5
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.05:
			continue
		var dir := d.normalized()
		var side := Vector2(-dir.y, dir.x) * hw
		var ga := terrain_height(a.x, a.y)
		var gb := terrain_height(b.x, b.y)
		var corners := [a + side, b + side, b - side, a - side]
		var g := [ga, gb, gb, ga]
		var top: Array[Vector3] = []
		var bottom: Array[Vector3] = []
		for k in 4:
			var c: Vector2 = corners[k]
			top.append(Vector3(c.x, float(g[k]) + height, c.y))
			bottom.append(Vector3(c.x, float(g[k]) - 0.3, c.y))
		_quad(st, top[0], top[1], top[2], top[3], Vector3.UP, col)
		for k in 4:
			var n := Vector3(corners[(k + 1) % 4].x - corners[k].x, 0, corners[(k + 1) % 4].y - corners[k].y).cross(Vector3.UP).normalized()
			_quad(st, bottom[k], bottom[(k + 1) % 4], top[(k + 1) % 4], top[k], -n, col.darkened(0.08))
		if collide:
			for k in [0, 2]:
				var p0: Vector3 = bottom[k]
				var p1: Vector3 = bottom[(k + 1) % 4]
				var up := Vector3(0, height + 1.5, 0)
				_wall_faces.append_array([p0, p1, p1 + up, p0, p1 + up, p0 + up])


const BARRIER_STYLE := {
	"hedge": ["#4f7d39", 0.9, 1.2],
	"fence": ["#7d838a", 0.12, 1.6],
	"wall": ["#a49d92", 0.35, 1.9],
	"platform": ["#d2cdc3", 2.4, 0.25],
	# Operation Unslop (2026-11-05, docs/streets/marszalkowska-centrum-audit.md "Wanted models"):
	# styles a street pass gives single barriers by id (OBJECT_OVERRIDES). The tram railing is the
	# black steel railing along tram beds and platform edges (1.1 m); the balustrades go round stairs
	# instead of the 1.9 m grey wall: granite at metro entrances, a concrete upstand with a rail
	# at platform and underpass stairs.
	# A 4th entry makes the style an open railing (F, 2026-11-05: the solid 1.1 m black strip read
	# as a black wall): [upstand height, rail colour]; posts every 2 m and two rails, see-through.
	"tram_railing": ["#22262a", 0.06, 1.1, [0.0, "#22262a"]],
	"balustrade": ["#8f8f8a", 0.3, 1.0],
	"balustrade_rail": ["#a9a59d", 0.2, 1.0, [0.45, "#2a2e33"]],
	# Kino Muranów's white balustrade (the terrace's, landmarks KM_BALUSTER) down its stairs.
	"balustrade_white": ["#ece8dc", 0.26, 1.05],
}


## An open railing along `poly`: an optional concrete upstand, then round-ish posts every 2 m and a
## top and a middle rail you can see through (Operation Unslop's tram railing and stair balustrade).
## It collides like a wall of the same height, so driving stays as it was.
func _railing_along(st, poly: PackedVector2Array, height: float, upstand: float, up_col: Color, rail_col: Color, collide: bool, post_every := 2.0) -> void:
	if upstand > 0.0:
		_wall_along(st, poly, 0.2, upstand, up_col, false)
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
		var ga := terrain_height(a.x, a.y)
		var gb := terrain_height(b.x, b.y)
		var n := Vector3(side.x, 0, side.y).normalized()
		for h in [low, height - 0.05]:
			for sgn in [1.0, -1.0]:
				var o: Vector2 = side * sgn
				_quad(st, Vector3(a.x + o.x, ga + h, a.y + o.y), Vector3(b.x + o.x, gb + h, b.y + o.y),
						Vector3(b.x + o.x, gb + h + 0.05, b.y + o.y), Vector3(a.x + o.x, ga + h + 0.05, a.y + o.y), n * sgn, rail_col)
			_quad(st, Vector3(a.x + side.x, ga + h + 0.05, a.y + side.y), Vector3(b.x + side.x, gb + h + 0.05, b.y + side.y),
					Vector3(b.x - side.x, gb + h + 0.05, b.y - side.y), Vector3(a.x - side.x, ga + h + 0.05, a.y - side.y), Vector3.UP, rail_col.lightened(0.12))
		while next_post <= run + length:
			var p := a + dir * (next_post - run)
			var y := lerpf(ga, gb, (next_post - run) / length)
			var bottom := maxf(upstand, 0.0)
			_box_oriented(st, Vector3(p.x, y + (bottom + height) * 0.5, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)),
					Vector3(0.06, height - bottom, 0.06), rail_col)
			next_post += post_every
		run += length
		if collide:
			_wall_faces.append_array([Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + height + 1.5, b.y),
					Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + height + 1.5, b.y), Vector3(a.x, ga + height + 1.5, a.y)])

## Operation Unslop's per-object decisions (tools/street_pass.py --apply writes them from the street
## records): {"items": {id: [verdict, style]}}. The id is road-objects.md's stable id: class, kind
## and the outline's mean rounded to a 2 m cell ("barrier:fence:-870:392"), so a re-bake keeps it.
## REMOVE leaves the barrier out; RETEXTURE / REPLACE draw it in the named BARRIER_STYLE.
const OBJECT_OVERRIDES := "res://data/road_objects.json"
var _object_overrides := {}


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


## The Royal Castle's gardens map their fountain basins, the vases' round beds and the round
## path nodes as small closed `wall` rings; drawn 1.9 m high they stood as grey drums. Inside
## GARDEN_RINGS a closed wall ring under 6 m across is a low stone kerb instead.
const GARDEN_RINGS := Rect2(-620.0, -1700.0, 190.0, 220.0)
const GARDEN_RING := ["#d8d2c4", 0.3, 0.45]


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


## Walls OpenStreetMap maps that stand low, not 1.9 m (F's screenshots, 2026-11-05): the 25 m
## planter edge along Wars's south front on Widok (it stood as a grey slab before the shop
## windows), and the planters round the Rotunda's stair down to the underpass (with the stair
## sunk, SUNKEN, a 1.9 m loop of wall round it read as a walled pit). Each is the line's first
## point. Also the straight wall beside Kino Muranów's fountain steps (F, 2026-11-07: a barrier
## where the square has steps).
const LOW_WALLS := [Vector2(-820.1, 345.4), Vector2(-807.1, 378.0), Vector2(-1627.1, -1219.5)]
const LOW_WALL := ["#b3ada3", 0.4, 0.55]


func _low_wall(flat: Array) -> bool:
	if flat.size() < 4:
		return false
	var first := Vector2(flat[0], flat[1])
	for at: Vector2 in LOW_WALLS:
		if first.distance_to(at) < 0.5:
			return true
	return false


## Operation Unslop, Świętokrzyska (2026-11-06): OSM maps the planter edges inside traffic islands (Emilii Plater's median by the Palace: two wavy walls 95 m long) as `wall`; drawn 1.9 m high they read as a twisting beige ribbon across the junction. A wall lying inside a traffic island is a low planter edge (13 on the map), like the garden rings. They are a planting bed's granite kerb (Mapillary 2995066364107910, 2020-07), 0.2 m.
const ISLAND_EDGE := ["#8e8b84", 0.25, 0.2]
var _island_boxes: Array = []
var _island_src: Array = []


## The Palace of Culture's grounds (F, 2026-11-07, "the barriers and the lawns round the Palace"):
## game/data/pkin_grounds.json (tools/bake_pkin_grounds.py from the raw OSM). OSM maps the
## granite planters and the raised lawns' retaining walls round the Palace as `wall` (59 of them
## barrier=retaining_wall, a few tagged 0.5 or 1 m); drawn 1.9 m high they stood round every bed
## and lawn like grey crowd barriers. Mapillary 1174856613029600 (2021-03, the south court) and
## 2909087812705418 (2020-12, Emilii Plater) show them knee high: inside the zone a wall is
## PKIN_WALL, or a 1 m granite balustrade where it rims a flight of steps. The file also gives the
## lots (asphalt, or grey pavers at the kerbside lots), their bays and the shrub beds, which the
## main bake folds into nothing and into lawn.
const PKIN_FILE := "res://data/pkin_grounds.json"
const PKIN_WALL := ["#aaa69e", 0.4, 0.65]
const PKIN_ASPHALT := Color("#55585d")
const PKIN_PAVERS := Color("#9a968f")
const PKIN_BAY := Color("#eceae3")
const PKIN_SCRUB := Color("#4d7334")
## Teatr Studio's forecourt (F's photos 2026-11-07): light granite slabs, Plac Defilad's dark
## bands every 6 m (0.45 m wide).
const PKIN_GRANITE := Color("#c9c6bf")
const PKIN_GRANITE_BAND := Color("#86837d")
const PKIN_BUSH := [Color("#3f6a2c"), Color("#4b7a33"), Color("#365e27"), Color("#56853a")]
static var _pkin: Dictionary = {}
var _pkin_zone := PackedVector2Array()
var _pkin_forecourt := PackedVector2Array()


static func pkin_grounds() -> Dictionary:
	if _pkin.is_empty():
		_pkin = {"zone": [], "parking": [], "bays": [], "scrub": []}
		if FileAccess.file_exists(PKIN_FILE):
			var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(PKIN_FILE))
			if j is Dictionary:
				_pkin = j
	return _pkin


func _in_pkin_zone(flat: Array) -> bool:
	if _pkin_zone.is_empty():
		_pkin_zone = _pts(pkin_grounds().get("zone", []))
		if _pkin_zone.is_empty():
			return false
	var n := flat.size() / 2
	if n < 1:
		return false
	var c := Vector2.ZERO
	for i in n:
		c += Vector2(flat[i * 2], flat[i * 2 + 1])
	return Geometry2D.is_point_in_polygon(c / n, _pkin_zone)


## Whether a barrier line's centre lies on Teatr Studio's open forecourt (pkin_grounds.json
## `forecourt`): OSM still maps the TR Warszawa site's old fence along the Palace there; the
## 2025 photos show the square open, with Bar Studio's tables on it.
func _in_pkin_forecourt(flat: Array) -> bool:
	if _pkin_forecourt.is_empty():
		_pkin_forecourt = _pts(pkin_grounds().get("forecourt", {}).get("p", []))
		if _pkin_forecourt.is_empty():
			return false
	var n := flat.size() / 2
	if n < 1:
		return false
	var c := Vector2.ZERO
	for i in n:
		c += Vector2(flat[i * 2], flat[i * 2 + 1])
	return Geometry2D.is_point_in_polygon(c / n, _pkin_forecourt)


## Whether a wall line passes within 2.5 m of a flight of steps (the underpass and terrace stairs).
func _by_steps(flat: Array) -> bool:
	var pts := _pts(flat)
	var box := _box_of_pts(pts).grow(2.5)
	for s in data.get("steps", []):
		var sp := _pts(s["p"])
		if sp.is_empty() or not box.intersects(_box_of_pts(sp)):
			continue
		for q in sp:
			for i in pts.size() - 1:
				if Geometry2D.get_closest_point_to_segment(q, pts[i], pts[i + 1]).distance_to(q) < 2.5:
					return true
	return false


## Whether a feature centred at c is this build's: every one on the whole map, a sector's own.
func _owns(c: Vector2) -> bool:
	return not _in_sector or _sector_rect.has_point(c)


static func _centre_of(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q in poly:
		c += q
	return c / maxf(poly.size(), 1)


## The lots (on the ground's grid, so the sector clip is the fill's own) and the shrub beds' soil.
func _build_pkin_ground(st) -> void:
	var g := pkin_grounds()
	_layer = L_ROAD
	for lot: Dictionary in g.get("parking", []):
		var asphalt := str(lot.get("s", "")) == "asphalt"
		_layer = L_ROAD if asphalt else L_PLAZA
		_fill_on_grid(st, _pts(lot["p"]), Y_AREA + 0.008, PKIN_ASPHALT if asphalt else PKIN_PAVERS)
	var court := _pts(g.get("forecourt", {}).get("p", []))
	if court.size() >= 3:
		_layer = L_PLAZA
		_fill_on_grid(st, court, Y_AREA + 0.007, PKIN_GRANITE)
	_layer = L_GREEN
	for bed: Array in g.get("scrub", []):
		_fill_on_grid(st, _pts(bed), Y_AREA + 0.009, PKIN_SCRUB)
	_layer = L_GROUND


## The bays' white lines (0.15 m) round each mapped parking space.
func _build_pkin_bays(st) -> void:
	_layer = L_MARK
	for bay: Array in pkin_grounds().get("bays", []):
		var poly := _pts(bay)
		if poly.size() < 3 or not _owns(_centre_of(poly)):
			continue
		poly.append(poly[0])
		_strip(st, poly, 0.15, Y_MARK, PKIN_BAY, false)
	for b: Array in pkin_grounds().get("forecourt", {}).get("bands", []):
		var a := Vector2(b[0], b[1])
		var c := Vector2(b[2], b[3])
		if _owns((a + c) * 0.5):
			_strip(st, PackedVector2Array([a, c]), 0.45, Y_MARK - 0.01, PKIN_GRANITE_BAND, false)
	_layer = L_GROUND


## The shrub beds' bushes: low domes about 1.1 m high on a 1.6 m grid with a hashed jitter, so
## the beds read as clipped yew and box, not lawn. No collider (the beds lie inside the planters).
func _build_pkin_bushes(st) -> void:
	for bed: Array in pkin_grounds().get("scrub", []):
		var poly := _pts(bed)
		if poly.size() < 3 or not _owns(_centre_of(poly)):
			continue
		var box := _box_of_pts(poly)
		var x := box.position.x + 0.8
		while x < box.end.x:
			var z := box.position.y + 0.8
			while z < box.end.y:
				var h := absi(hash(Vector2i(roundi(x * 10.0), roundi(z * 10.0))))
				var p := Vector2(x + float(h % 7 - 3) * 0.12, z + float((h / 7) % 7 - 3) * 0.12)
				if Geometry2D.is_point_in_polygon(p, poly):
					var r := 0.75 + float((h / 49) % 5) * 0.08
					_bush(st, p, r, 0.8 + float((h / 245) % 5) * 0.1, PKIN_BUSH[(h / 1225) % PKIN_BUSH.size()])
				z += 1.6
			x += 1.6


## One bush: an eight-sided dome (a ring at the foot, a wider one at 55 %, a top point).
func _bush(st, c: Vector2, r: float, h: float, col: Color) -> void:
	var g := terrain_height(c.x, c.y) + Y_AREA
	var top := Vector3(c.x, g + h, c.y)
	var low: Array[Vector3] = []
	var mid: Array[Vector3] = []
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector2(cos(a), sin(a))
		low.append(Vector3(c.x + d.x * r * 0.8, g, c.y + d.y * r * 0.8))
		mid.append(Vector3(c.x + d.x * r, g + h * 0.55, c.y + d.y * r))
	for i in 8:
		var j := (i + 1) % 8
		var out := Vector3((mid[i].x + mid[j].x) * 0.5 - c.x, 0.0, (mid[i].z + mid[j].z) * 0.5 - c.y).normalized()
		_quad(st, low[i], low[j], mid[j], mid[i], out, col.darkened(0.12))
		_tri(st, mid[i], mid[j], top, (out + Vector3.UP).normalized(), col)


func _in_island(flat: Array) -> bool:
	# `data` is swapped for every sector the builder makes: rebuild the boxes when it changes
	# (a cache from the first sector left every later sector's median walls at 1.9 m).
	var src: Array = data.get("islands", [])
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


## Stairs across the city (2026-11-07): the walls by the stairs. Every OSM wall stood 1.9 m high,
## so a basin's rim or a planter's edge by a flight read as a grey drum (Kino Muranów's fountain
## steps, F), a terrace's retaining wall drawn across a flight shut it, and the walls round a
## stair going down into an underpass boxed it in. Now: a wall OSM gives a height stands that high
## (`h`, tools/stairs.py); a closed ring round a fountain basin, or a small ring by a flight, is a
## low stone rim (BASIN_RIM); a wall crossing a flight opens STAIR_GAP past its sides (not at a
## flight's dead end, the back wall of a stairwell going on underground); a short wall wrapping a
## stair that goes down below the drawn ground (a stairwell: the grid shows under half a metre of
## its mapped drop) is a balustrade.
const BASIN_RIM := ["#cfc9bd", 0.35, 0.45]
const STAIR_GAP := 0.25
const STAIR_RING_R := 6.0
var _stair_src: Array = []
var _stair_idx: Array = []
var _fountain_rings: Array = []


## The flights of `data` for the wall rules: [poly, half width, box, end open flags, stairwell].
func _stairs_for_walls() -> Array:
	var src: Array = data.get("steps", [])
	if is_same(src, _stair_src):
		return _stair_idx
	_stair_src = src
	_stair_idx = []
	_fountain_rings = []
	var on_path := {}    # 1 m cells holding a footway's point
	var flight_ends := {}  # 1 m cells holding a flight's end: how many
	for p in data.get("paths", []):
		var fp: Array = p["p"]
		for i in fp.size() / 2:
			on_path[Vector2i(floori(fp[i * 2]), floori(fp[i * 2 + 1]))] = true
	for s in src:
		var fp: Array = s["p"]
		for i in [0, fp.size() / 2 - 1]:
			var c := Vector2i(floori(fp[i * 2]), floori(fp[i * 2 + 1]))
			flight_ends[c] = int(flight_ends.get(c, 0)) + 1
	for s in src:
		var poly := _pts(s["p"])
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
		var mapped := float(s.get("n", 0)) * STAIR_RISER
		var grid := absf(terrain_height(poly[0].x, poly[0].y) - terrain_height(poly[poly.size() - 1].x, poly[poly.size() - 1].y))
		var well := mapped >= 1.0 and grid < 0.5
		_stair_idx.append([poly, clampf(float(s.get("w", 2.4)), 1.0, 30.0) * 0.5, _box_of_pts(poly).grow(4.0), open, well])
	for a in data.get("surfaces", []):
		if a.get("k") == "fountain":
			var ring := _pts(a["p"])
			_fountain_rings.append([ring, _box_of_pts(ring).grow(1.5)])
	return _stair_idx


## Whether closed wall ring `pts` is a basin's or planter's rim: it follows a fountain's
## outline, or it is under STAIR_RING_R across and stands within 4 m of a flight.
func _rim_ring(pts: PackedVector2Array) -> bool:
	if pts.size() < 4 or pts[0].distance_to(pts[pts.size() - 1]) > 0.3:
		return false
	var box := _box_of_pts(pts)
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
	var box := _box_of_pts(pts)
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
	var box := _box_of_pts(pts)
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
## noise barrier with no height stands 4 m); a fence OSM calls a railing (`ft`: railing, bars,
## balustrade, metal) is an open steel railing you see through, a chain-link one an open grey mesh,
## a wooden one brown boards; a hedge or fence keeps its mapped height (`h`). A solid fence mapped
## over FENCE_SOLID_MAX (the 6 m ball-stop nets round the pitches) is a mesh, not a 6 m grey band.
## A style a rule above picked for its place (a basin rim, a garden ring, a stairwell) stays.
const WALL_MATERIAL := {"brick": "#a8644b", "stone": "#b9b2a5", "concrete": "#a9a69f", "gabion": "#8f897e",
		"glass": "#a9bcc0", "wood": "#7f6248", "metal": "#7b8085", "noise": "#7e8a84"}
const FENCE_SOLID_MAX := 2.5


func _mapped_style(l: Dictionary, style: Array) -> Array:
	var k: String = l["k"]
	var base: Variant = BARRIER_STYLE.get(k)
	if base == null or style != base:
		# Already a wall height (`h`, the stairs pass) or a placed style: only a colour for a wall.
		if k == "wall" and l.has("m") and style.size() == 3 and style != GARDEN_RING and style != BASIN_RIM \
				and style != LOW_WALL and style != ISLAND_EDGE:
			return [WALL_MATERIAL.get(str(l["m"]), style[0]), style[1], style[2]]
		return style
	var h := float(l.get("h", -1.0))
	match k:
		"wall":
			var col: String = WALL_MATERIAL.get(str(l.get("m", "")), style[0])
			var wh := h if h > 0.0 else (4.0 if str(l.get("m", "")) == "noise" else float(style[2]))
			return [col, style[1], wh]
		"fence":
			var ft := str(l.get("ft", ""))
			if ft == "railing":
				return ["#2a2e33", 0.05, clampf(h, 0.8, 2.5) if h > 0.0 else 1.2, [0.0, "#2a2e33"]]
			if ft == "mesh" or h > FENCE_SOLID_MAX:
				return ["#8b9196", 0.05, clampf(h, 1.0, 8.0) if h > 0.0 else 1.8, [0.0, "#8b9196"]]
			if ft == "wood":
				return ["#7f6248", 0.08, h if h > 0.0 else 1.5]
			if h > 0.0:
				return [style[0], style[1], clampf(h, 0.5, FENCE_SOLID_MAX)]
		"hedge":
			if h > 0.0:
				return [style[0], style[1], clampf(h, 0.4, 3.0)]
	return style


## The Old Town's defence walls (OSM barrier=city_wall areas, `citywalls`, tools/barrier_tags.py):
## they were not on the map at all, only the Barbakan and two towers. Brick, each its mapped height
## (Baszta Rycerska 13.5 m; the rebuilt curtain walls 5-6 m; the ruins' stubs 1-1.5 m), the coping a
## shade darker; from 1 m up they stop the car like any wall.
const CITY_WALL := Color("#b8704f")


func _build_city_walls(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for w in data.get("citywalls", []):
		var ring := _pts(w["p"])
		if ring.size() < 3:
			continue
		var h := float(w.get("h", 5.0))
		var tops := PackedFloat32Array()
		var foot := INF
		for q in ring:
			foot = minf(foot, terrain_height(q.x, q.y))
		for q in ring:
			tops.append(maxf(terrain_height(q.x, q.y), foot) + h)
		var idx := Geometry2D.triangulate_polygon(ring)
		for i in range(0, idx.size(), 3):
			var a := ring[idx[i]]
			var b := ring[idx[i + 1]]
			var c := ring[idx[i + 2]]
			_tri(st, Vector3(a.x, tops[idx[i]], a.y), Vector3(b.x, tops[idx[i + 1]], b.y), Vector3(c.x, tops[idx[i + 2]], c.y),
					Vector3.UP, CITY_WALL.darkened(0.12))
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
			var ga := terrain_height(a.x, a.y) - 0.3
			var gb := terrain_height(b.x, b.y) - 0.3
			var shade := CITY_WALL.darkened(0.04 * float(i % 3))
			_quad(st, Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, tops[j], b.y), Vector3(a.x, tops[i], a.y), n, shade)
			if h >= 1.0:
				_wall_faces.append_array([Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, tops[j] + 1.5, b.y),
						Vector3(a.x, ga, a.y), Vector3(b.x, tops[j] + 1.5, b.y), Vector3(a.x, tops[i] + 1.5, a.y)])
	_uv2 = Vector2.ZERO


## Walls (and fences) drawn otherwise than OSM's 1.9 m grey wall, by the line's first point: [point, style],
## the style a BARRIER_STYLE key, or "" when a landmark site builds the wall itself. Kino
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


## The SITE_WALLS entry for a wall line, or [] when it has none.
func _site_wall(flat: Array) -> Array:
	if flat.size() < 4:
		return []
	var first := Vector2(flat[0], flat[1])
	for e: Array in SITE_WALLS:
		if first.distance_to(e[0]) < 0.5:
			return e
	return []


func _build_barriers(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	_load_object_overrides()
	_stairs_for_walls()
	for l in data.get("lines", []):
		var site_wall: Array = _site_wall(l["p"]) if l["k"] == "wall" or l["k"] == "fence" else []
		if not site_wall.is_empty() and str(site_wall[1]) == "":
			continue
		if l["k"] != "platform" and _in_pkin_forecourt(l["p"]):
			continue
		var style: Array = BARRIER_STYLE.get(l["k"], ["#999999", 0.3, 1.0])
		if not site_wall.is_empty():
			style = BARRIER_STYLE[str(site_wall[1])]
		elif l["k"] == "wall":
			if _garden_ring(l["p"]):
				style = GARDEN_RING
			elif _low_wall(l["p"]):
				style = LOW_WALL
			elif _in_island(l["p"]):
				style = ISLAND_EDGE
			elif _in_pkin_zone(l["p"]):
				style = BARRIER_STYLE["balustrade"] if _by_steps(l["p"]) else PKIN_WALL
			elif l.has("h"):
				var wh := float(l["h"])
				style = [style[0], 0.3 if wh <= 1.0 else 0.35, wh]
			elif _rim_ring(_pts(l["p"])):
				style = BASIN_RIM
			elif _wraps_stairwell(_pts(l["p"])):
				style = BARRIER_STYLE["balustrade_rail"]
		style = _mapped_style(l, style)
		if not _object_overrides.is_empty() and l["k"] != "platform":
			var o: Variant = _object_overrides.get(barrier_id(l["k"], l["p"]))
			if o is Array:
				if str(o[0]) == "REMOVE":
					continue
				if (o as Array).size() > 1 and BARRIER_STYLE.has(str(o[1])):
					style = BARRIER_STYLE[str(o[1])]
		var pts := _pts(l["p"])
		if style.size() > 3:
			var open: Array = style[3]
			# A railing OSM maps (tools/barrier_tags.py) has a post every 3 m: 30 km of them.
			_railing_along(st, pts, float(style[2]), float(open[0]), Color(style[0]), Color(str(open[1])), true,
					3.0 if l.has("ft") or (l["k"] == "fence" and float(l.get("h", 0.0)) > FENCE_SOLID_MAX) else 2.0)
			continue
		# Loop 3b: a stop's platform is kerb height (0.25 m), not a wall: like the kerbs and
		# islands, the car drives over it (check_drive.gd found buses brushing them).
		if l["k"] == "wall" and not _sunk.is_empty() and _sunk_box.grow(2.0).intersects(_box_of_pts(pts)):
			# The pieces off a sunken ring's edge (the site builds the walls on it).
			var piece := PackedVector2Array()
			for i in pts.size():
				if i > 0 and _on_sunk_edge(pts[i - 1], pts[i]):
					if piece.size() >= 2:
						_wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), true)
					piece = PackedVector2Array()
				piece.append(pts[i])
			if piece.size() >= 2:
				_wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), true)
			continue
		if l["k"] == "wall" and not _stair_idx.is_empty():
			for piece in _stair_gaps(pts):
				_wall_along(st, piece, float(style[1]), float(style[2]), Color(style[0]), true)
			continue
		_wall_along(st, pts, float(style[1]), float(style[2]), Color(style[0]), l["k"] != "platform")
	_build_pkin_bushes(st)
	_uv2 = Vector2.ZERO


static func _box_of_pts(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO) if not pts.is_empty() else Rect2()
	for q in pts:
		r = r.expand(q)
	return r


## Under every deck piece: its slab (concrete top, underside) and a parapet girder on the
## sides that face out of the structure; sides that face another piece of the same bridge
## reach over to meet it. Loop 3b (R5): the piers are the bake's (`decks.piers`,
## tools/bake_structures.py: slid along the deck clear of the roads, tracks and kerbs under
## it, portal legs where nothing else fits), drawn into the same tile meshes and solid.
## Loop 3b-2: two pieces of one bridge (its road, tram bed and footways) further apart than the
## bake's 1.2 m look each got an outer parapet and the river showed through the gap between them
## (Most Poniatowskiego). Up to DECK_JOIN apart, the slabs now meet half way across the gap, the
## parapets there go and a low kerb marks each piece's edge (the car still can't cross it: the
## parapet's collider stays where there is a drop under it).
const DECK_JOIN := 6.0


## Per point of deck piece `di`, how far across the gap on each side another piece of its bridge
## starts (x: left, y: right; -1 none within DECK_JOIN), for the sides the bake made outer.
func _deck_gaps(di: int) -> PackedVector2Array:
	var d: Dictionary = _decks[di]
	var pts: PackedVector2Array = d["pts"]
	var outer: PackedByteArray = d["o"]
	var g := int(d["g"])
	var out := PackedVector2Array()
	out.resize(pts.size())
	if _deck_cells.is_empty():
		_index_decks()
	for i in pts.size():
		var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var right := Vector2(-dir.y, dir.x)
		var gap := Vector2(-1.0, -1.0)
		var bits := int(outer[i]) if i < outer.size() else 3
		for side in [0, 1]:
			if not (bits & (1 << side)):
				continue
			var sgn := -1.0 if side == 0 else 1.0
			var edge := float(d["l"]) if side == 0 else float(d["r"])
			var t := 0.5
			while t <= DECK_JOIN:
				if _other_piece_at(di, g, pts[i] + right * sgn * (edge + t)):
					if side == 0:
						gap.x = t
					else:
						gap.y = t
					break
				t += 0.5
		out[i] = gap
	return out


## Whether a piece of deck group g other than `skip` holds the point in its corridor.
func _other_piece_at(skip: int, g: int, p: Vector2) -> bool:
	for code: int in _deck_cells.get(Vector3i(floori(p.x / DECK_CELL), floori(p.y / DECK_CELL), g), PackedInt32Array()):
		var i := code >> 12
		if i == skip:
			continue
		var d: Dictionary = _decks[i]
		var pts: PackedVector2Array = d["pts"]
		var k := code & 4095
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var u := (p - a).dot(ab) / l2
		if (u < 0.0 and k > 0) or (u > 1.0 and k < pts.size() - 2) or u < -0.02 or u > 1.02:
			continue
		var lat := ab.cross(p - a) / sqrt(l2)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			return true
	return false


func _build_bridge_structures(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var concrete := Color("#b8b2a7")
	var joined := 0.0
	for di in _decks.size():
		var d: Dictionary = _decks[di]
		if _in_sector and not (d["box"] as Rect2).grow(8.0).intersects(_sector_rect):
			continue  # loop 3c: none of this piece reaches the sector being built
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var outer: PackedByteArray = d["o"]
		var piers: bool = d["k"] in ["road", "rail"]
		var l := float(d["l"]) + 0.2
		var r := float(d["r"]) + 0.2
		var gaps := _deck_gaps(di)
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var right := Vector2(-dir.y, dir.x)
			var ya := hs[i] - 0.08
			var yb := hs[i + 1] - 0.08
			var bits := outer[i] & outer[i + 1] if outer.size() > i + 1 else 3
			# A side whose gap to its bridge's next piece is bridged at both ends: no parapet,
			# the slab out to half way across, a kerb at the piece's own edge.
			var join := 0
			var lo := l if bits & 1 else l + 1.6
			var ro := r if bits & 2 else r + 1.6
			if bits & 1 and gaps[i].x > 0.0 and gaps[i + 1].x > 0.0:
				join |= 1
				lo = float(d["l"]) + maxf(gaps[i].x, gaps[i + 1].x) * 0.5 + 0.1
			if bits & 2 and gaps[i].y > 0.0 and gaps[i + 1].y > 0.0:
				join |= 2
				ro = float(d["r"]) + maxf(gaps[i].y, gaps[i + 1].y) * 0.5 + 0.1
			if join:
				joined += length * ((join & 1) + (join >> 1))
			bits &= ~join
			var al := a - right * lo
			var bl := b - right * lo
			var ar := a + right * ro
			var br := b + right * ro
			# Slab top (shows between the pieces) and underside.
			_quad(st, Vector3(al.x, ya, al.y), Vector3(bl.x, yb, bl.y), Vector3(br.x, yb, br.y), Vector3(ar.x, ya, ar.y), Vector3.UP, concrete.darkened(0.15))
			_quad(st, Vector3(al.x, ya - 1.3, al.y), Vector3(bl.x, yb - 1.3, bl.y), Vector3(br.x, yb - 1.3, br.y), Vector3(ar.x, ya - 1.3, ar.y), Vector3.DOWN, concrete.darkened(0.3))
			for side in [-1.0, 1.0]:
				var is_outer := bool(bits & (1 if side < 0.0 else 2))
				var p0 := al if side < 0.0 else ar
				var p1 := bl if side < 0.0 else br
				var n := Vector3(right.x * side, 0.0, right.y * side)
				var top := 0.55 if is_outer else 0.0
				_quad(st, Vector3(p0.x, ya - 1.3, p0.y), Vector3(p1.x, yb - 1.3, p1.y),
						Vector3(p1.x, yb + top, p1.y), Vector3(p0.x, ya + top, p0.y), n, concrete)
				if is_outer:
					# The parapet's top and inner face.
					var q0: Vector2 = p0 - right * side * 0.3
					var q1: Vector2 = p1 - right * side * 0.3
					_quad(st, Vector3(p0.x, ya + top, p0.y), Vector3(p1.x, yb + top, p1.y), Vector3(q1.x, yb + top, q1.y),
							Vector3(q0.x, ya + top, q0.y), Vector3.UP, concrete.lightened(0.1))
					_quad(st, Vector3(q0.x, ya, q0.y), Vector3(q1.x, yb, q1.y), Vector3(q1.x, yb + top, q1.y),
							Vector3(q0.x, ya + top, q0.y), -n, concrete.darkened(0.05))
					# Solid where there is a drop beside it (loop 3b: where the deck runs within a
					# metre of the ground beside it, as at its ends, the parapet is a kerb to the car).
					var drop := maxf(ya - terrain_height(p0.x, p0.y), yb - terrain_height(p1.x, p1.y))
					if (piers or d["k"] == "path") and drop > 1.0:
						_wall_faces.append_array([Vector3(p0.x, ya - 0.2, p0.y), Vector3(p1.x, yb - 0.2, p1.y), Vector3(p1.x, yb + 1.6, p1.y),
								Vector3(p0.x, ya - 0.2, p0.y), Vector3(p1.x, yb + 1.6, p1.y), Vector3(p0.x, ya + 1.6, p0.y)])
			for side in [-1.0, 1.0]:
				if not (join & (1 if side < 0.0 else 2)):
					continue
				# The joined side: a low kerb on the piece's own edge, and the parapet's collider
				# kept where the deck stands over a drop (the gap between is no road).
				var e := (float(d["l"]) if side < 0.0 else float(d["r"])) + 0.05
				var k0: Vector2 = a + right * side * e
				var k1: Vector2 = b + right * side * e
				var k2: Vector2 = a + right * side * (e + 0.3)
				var k3: Vector2 = b + right * side * (e + 0.3)
				var kn := Vector3(right.x * side, 0.0, right.y * side)
				_quad(st, Vector3(k0.x, ya + 0.08, k0.y), Vector3(k1.x, yb + 0.08, k1.y), Vector3(k3.x, yb + 0.22, k3.y),
						Vector3(k2.x, ya + 0.22, k2.y), Vector3.UP, concrete.lightened(0.05))
				_quad(st, Vector3(k0.x, ya, k0.y), Vector3(k1.x, yb, k1.y), Vector3(k1.x, yb + 0.22, k1.y),
						Vector3(k0.x, ya + 0.22, k0.y), -kn, concrete.darkened(0.08))
				var drop2 := maxf(ya - terrain_height(k0.x, k0.y), yb - terrain_height(k1.x, k1.y))
				if (piers or d["k"] == "path" or d["k"] == "tram") and drop2 > 1.0:
					_wall_faces.append_array([Vector3(k0.x, ya - 0.2, k0.y), Vector3(k1.x, yb - 0.2, k1.y), Vector3(k1.x, yb + 1.6, k1.y),
							Vector3(k0.x, ya - 0.2, k0.y), Vector3(k1.x, yb + 1.6, k1.y), Vector3(k0.x, ya + 1.6, k0.y)])
	var ms := _srednicowy_frame()
	var pn := _poniatowski_frame()
	var pv := _powisle_frame()
	for p: Dictionary in data.get("decks", {}).get("piers", []):
		if _srednicowy_skips(ms, Vector2(float(p["c"][0]), float(p["c"][1]))):
			continue  # Most Średnicowy's stone piers stand here (`_build_srednicowy`)
		if _poniatowski_skips(pn, Vector2(float(p["c"][0]), float(p["c"][1]))):
			continue  # Most Poniatowskiego's stone piers and arches stand here (`_build_poniatowski`)
		if _powisle_skips(pv, Vector2(float(p["c"][0]), float(p["c"][1]))):
			continue  # the Powiśle viaduct's arcade stands here (`_build_powisle`)
		_pier(st, p, concrete.darkened(0.1))
	_uv2 = Vector2.ZERO
	if not _in_sector:
		print("decks: %.0f m of deck edges joined across a gap to the bridge's next piece (loop 3b-2)" % joined)


## Loop 3b (R5): one of the bake's pier boxes (a pier, a portal leg or its cap beam): drawn
## and, for the ones that reach the ground, solid from the ground up (one concave shape,
## like the walls).
func _pier(st, p: Dictionary, col: Color) -> void:
	var c := Vector2(float(p["c"][0]), float(p["c"][1]))
	var dir := Vector2(float(p["d"][0]), float(p["d"][1]))
	var y0 := float(p["y"][0])
	var y1 := float(p["y"][1])
	var across := float(p["s"][0])
	var along := float(p["s"][1])
	_box_oriented(st, Vector3(c.x, (y0 + y1) * 0.5, c.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)),
			Vector3(across, y1 - y0, along), col if p["k"] != "cap" else col.lightened(0.06))
	if p["k"] == "cap":
		return
	var right := Vector2(-dir.y, dir.x)
	var corners: Array[Vector2] = []
	for uv in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(c + dir * uv.x * along * 0.5 + right * uv.y * across * 0.5)
	for k in 4:
		var a := corners[k]
		var b := corners[(k + 1) % 4]
		_wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)])


## Guard rails (bridge edges and mapped barrier=guard_rail): a steel beam on posts,
## solid for the car.
## Two rails' ends closer than this get a collider across the gap (narrower than a car).
const GUARD_JOIN := 1.5
## ...the V's depth behind the rail's line, at most (and under half the gap).
const GUARD_POCKET := 0.4
var guard_joins := 0
func _build_guard_rails(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var ends: Array = []  # [the end, its deck, which rail]
	var steel := Color("#a7abb0")
	var post := Color("#6c7075")
	for g in data.get("guards", []):
		var poly := _pts(g["p"])
		var dk := int(g.get("dk", -1))
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
			var ga := deck_height(dk, a.x, a.y)
			var gb := deck_height(dk, b.x, b.y)
			# The beam: two faces and a top, 0.55-0.85 m up.
			var n := Vector3(side.x, 0, side.y).normalized()
			for sgn in [1.0, -1.0]:
				var o: Vector2 = side * sgn
				_quad(st, Vector3(a.x + o.x, ga + 0.55, a.y + o.y), Vector3(b.x + o.x, gb + 0.55, b.y + o.y),
						Vector3(b.x + o.x, gb + 0.85, b.y + o.y), Vector3(a.x + o.x, ga + 0.85, a.y + o.y), n * sgn, steel)
			_quad(st, Vector3(a.x + side.x, ga + 0.85, a.y + side.y), Vector3(b.x + side.x, gb + 0.85, b.y + side.y),
					Vector3(b.x - side.x, gb + 0.85, b.y - side.y), Vector3(a.x - side.x, ga + 0.85, a.y - side.y), Vector3.UP, steel.lightened(0.15))
			while next_post <= run + length:
				var p := a + dir * (next_post - run)
				var y := lerpf(ga, gb, (next_post - run) / length)
				_box_oriented(st, Vector3(p.x, y + 0.35, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)), Vector3(0.1, 0.7, 0.1), post)
				next_post += 4.0
			run += length
			_wall_faces.append_array([Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + 1.6, b.y),
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
			if nrm.dot(mid - _deck_centre(e0[1], mid)) < 0.0:
				nrm = -nrm
			var m := mid + nrm * minf(GUARD_POCKET, gap * 0.45)
			var ga := deck_height(e0[1], a.x, a.y)
			var gm := deck_height(e0[1], m.x, m.y)
			var gb := deck_height(e0[1], b.x, b.y)
			for seg in [[a, ga, m, gm], [m, gm, b, gb]]:
				var p0: Vector2 = seg[0]
				var p1: Vector2 = seg[2]
				var y0: float = seg[1]
				var y1: float = seg[3]
				_wall_faces.append_array([Vector3(p0.x, y0 - 0.3, p0.y), Vector3(p1.x, y1 - 0.3, p1.y), Vector3(p1.x, y1 + 1.6, p1.y),
						Vector3(p0.x, y0 - 0.3, p0.y), Vector3(p1.x, y1 + 1.6, p1.y), Vector3(p0.x, y0 + 1.6, p0.y)])
			guard_joins += 1
	_uv2 = Vector2.ZERO


## Loop 10a: the water's edge, a low granite edge the car can see and can't cross (until
## loop 10a it was an invisible wall along the bake's runs only).
## Where: the bake's `shore` runs (the river's and ponds' edges); the stretches the bake left
## open within 6 m of a bridge deck, wherever the deck over them is at least SHORE_CLEAR up (a
## car on the boulevard under a bridge drove straight into the river there: 9 places, ~210 m),
## plus two short gaps (a road ending at a canal, a seam between two runs); and round every
## fountain (they had no edge at all: 35 places a car drove into). The map's rim stays open:
## the edge walls close it.
## How: the stone is drawn like the kerbs, into the ground's mesh (its material and tiles: no
## draw call, no shadow; under a metre tall), SHORE_UP over the ground on the water's side of
## the line, so the car's bumper meets its face, laid on the ground like the kerbs. The
## collider stands on the line, SHORE_WALL over the ground (under any deck above it), in pieces
## of at most SHORE_PIECE with the ground's height at each end.
const SHORE_W := 0.5
const SHORE_UP := 0.45
const SHORE_WALL := 3.0
const SHORE_PIECE := 2.0
const SHORE_CLEAR := 3.2
## A water area's edge this far out on the water (water.bin) is a seam, not a shore.
const SEAM_WET := 6.0
const SHORE_TOP := Color("#c9c4b8")
const SHORE_FACE := Color("#8d8a83")
## The runs, each [polyline, water side (+1 left, -1 right), natural (0 built, 1 a sandy bank,
## 2 a green one: bake_banks.py)], found once for the stone, the natural banks and the collider.
var _shore_lines: Array = []
var _shore_baked := 0
var _shore_fountains := 0


## Loop 3b-2: the runs of the water's edge (see above), and the natural ones drawn: a wet band
## and a damper one inland from the waterline (sand or earth, by what the bank is), and a
## 1-px foam line on the water (not where a sandbar meets the bank). Built runs get the stone
## later (_build_shore_stone). The collider is the same on both (_build_shore): on a natural
## bank the car stops at the foam, on the wet sand.
func _build_banks(st) -> void:
	_shore_lines.clear()
	if _in_sector:
		# Loop 3c: the runs found once for the whole map, those near the sector.
		for line in _global_shore:
			if (line[3] as Rect2).intersects(_near):
				_shore_lines.append(line)
	else:
		_shore_lines = _find_shore_lines()
	_shore_fountains = 0
	for s in data.get("surfaces", []):
		if s["k"] != "fountain":
			continue
		var ring := _pts(s["p"])
		if ring.size() < 3:
			continue
		ring.append(ring[0])
		# The water is inside the ring: on the left of its way round if it runs anticlockwise
		# (a positive area here).
		_shore_lines.append([ring, 1.0 if _ring_area(ring) > 0.0 else -1.0, 0, _poly_box(ring).grow(2.0)])
		_shore_fountains += 1
	var keep := _drape_bias
	for line in _shore_lines:
		var kind: int = line[2]
		if kind == 0:
			continue
		var side: float = line[1]
		_drape_bias = keep
		_layer = L_WET
		_band(st, line[0], -side, 0.0, BAND_W, WET_EARTH if kind == 2 else WET_SAND, Y_AREA + 0.02)
		_band(st, line[0], -side, BAND_W, BAND_W * 2.0, DAMP_EARTH if kind == 2 else DAMP_SAND, Y_AREA + 0.02)
		_drape_bias = keep + 0.02
		_layer = L_FOAM
		_band(st, line[0], side, 0.0, FOAM_W, FOAM, Y_AREA + 0.04, _on_sandbar)
	_drape_bias = keep
	_layer = L_GROUND


## Loop 3c: the water's edge runs (the bake's and the ones by the decks), each [polyline,
## water side, natural kind, box]: over the whole map, so a sector takes the same runs.
func _find_shore_lines() -> Array:
	var lines := []
	var runs: Array[PackedVector2Array] = []
	var kinds: Array[int] = []
	for sh in data.get("shore", []):
		runs.append(_pts(sh["p"]))
		kinds.append(int(sh.get("n", 0)))
	_shore_baked = runs.size()
	var extra := _shore_under_decks(runs)
	runs.append_array(extra)
	for k in extra.size():
		kinds.append(0)
	for i in runs.size():
		lines.append([runs[i], _water_side(runs[i]), kinds[i], _poly_box(runs[i]).grow(2.0)])
	return lines


## The built runs' granite edge goes into the ground's mesh `st` (see above).
func _build_shore_stone(st) -> void:
	var length := 0.0
	var natural := 0.0
	var layer := _layer
	_layer = L_ISLAND
	for line in _shore_lines:
		if int(line[2]) != 0:
			var poly: PackedVector2Array = line[0]
			for i in poly.size() - 1:
				natural += poly[i].distance_to(poly[i + 1])
			continue
		length += _shore_edge(st, line[0], line[1])
	_layer = layer
	if not _in_sector:
		print("shore: %d baked runs, %d more by bridges, %d fountains, %.1f km of stone, %.1f km natural bank" % [_shore_baked,
			_shore_lines.size() - _shore_baked - _shore_fountains, _shore_fountains, length / 1000.0, natural / 1000.0])


## The colliders along the runs _build_shore_stone found.
func _build_shore() -> void:
	for line in _shore_lines:
		var poly: PackedVector2Array = line[0]
		for i in poly.size() - 1:
			var a := poly[i]
			var b := poly[i + 1]
			var pieces := maxi(1, ceili(a.distance_to(b) / SHORE_PIECE))
			for k in pieces:
				var p0 := a.lerp(b, float(k) / pieces)
				var p1 := a.lerp(b, float(k + 1) / pieces)
				var g0 := terrain_height(p0.x, p0.y)
				var g1 := terrain_height(p1.x, p1.y)
				var h0 := _shore_wall_top(p0, g0)
				var h1 := _shore_wall_top(p1, g1)
				_wall_faces.append_array([Vector3(p0.x, g0 - 1.0, p0.y), Vector3(p1.x, g1 - 1.0, p1.y), Vector3(p1.x, h1, p1.y),
						Vector3(p0.x, g0 - 1.0, p0.y), Vector3(p1.x, h1, p1.y), Vector3(p0.x, h0, p0.y)])


## Which side of a run the water is on: +1 left (the side Vector2(-d.y, d.x) points to), -1
## right; by the surface map a metre and a half either side of each segment.
func _water_side(poly: PackedVector2Array) -> float:
	var vote := 0.0
	for i in poly.size() - 1:
		var d := poly[i + 1] - poly[i]
		if d.length() < 0.05:
			continue
		var m := (poly[i] + poly[i + 1]) * 0.5
		var left := Vector2(-d.y, d.x).normalized() * 1.5
		vote += (shore_distance(m.x + left.x, m.y + left.y) - shore_distance(m.x - left.x, m.y - left.y)) * d.length()
	return 1.0 if vote >= 0.0 else -1.0


## The edge stone along one run, draped on the ground (the caller sets the drape bias and the
## layer); returns its length.
func _shore_edge(st, poly: PackedVector2Array, side: float) -> float:
	var n := poly.size()
	if n < 2:
		return 0.0
	# Mitred offsets towards the water at every point, so the stone keeps its width round bends.
	var off := PackedVector2Array()
	off.resize(n)
	var closed := poly[0].distance_to(poly[n - 1]) < 0.05
	for i in n:
		var prev := i - 1 if i > 0 else (n - 2 if closed else -1)
		var next := i + 1 if i < n - 1 else (1 if closed else -1)
		var na := Vector2.ZERO
		var nb := Vector2.ZERO
		if prev >= 0 and poly[i].distance_to(poly[prev]) > 0.01:
			var d := (poly[i] - poly[prev]).normalized()
			na = Vector2(-d.y, d.x)
		if next >= 0 and poly[next].distance_to(poly[i]) > 0.01:
			var d := (poly[next] - poly[i]).normalized()
			nb = Vector2(-d.y, d.x)
		var m := na + nb
		if m.length() < 0.01:
			m = na if na != Vector2.ZERO else nb
		m = m.normalized()
		var cos_half := maxf(m.dot(nb if nb != Vector2.ZERO else na), 0.4)
		off[i] = m * (SHORE_W * side / cos_half)
	var length := 0.0
	for i in n - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.05:
			continue
		length += seg
		var dir := (b - a) / seg
		var land := Vector2(-dir.y, dir.x) * -side
		# One piece per segment: the drape lays it on the ground in pieces of the terrain grid.
		var qa := a + off[i]
		var qb := b + off[i + 1]
		_quad(st, Vector3(a.x, SHORE_UP, a.y), Vector3(b.x, SHORE_UP, b.y), Vector3(qb.x, SHORE_UP, qb.y),
				Vector3(qa.x, SHORE_UP, qa.y), Vector3.UP, SHORE_TOP)
		_draped_wall(st, a, b, 0.0, SHORE_UP, land, SHORE_FACE)
		_draped_wall(st, qa, qb, 0.0, SHORE_UP, -land, SHORE_FACE.darkened(0.12))
		if i == 0 and not closed:
			_draped_wall(st, a, a + off[0], 0.0, SHORE_UP, -dir, SHORE_FACE)
		if i == n - 2 and not closed:
			_draped_wall(st, b, b + off[n - 1], 0.0, SHORE_UP, dir, SHORE_FACE)
	return length


## The shore collider's top at a point: SHORE_WALL over the ground, or under the lowest deck
## over it (a car on the deck must never touch it).
func _shore_wall_top(p: Vector2, g: float) -> float:
	var top := g + SHORE_WALL
	for d in _decks_at(p.x, p.y):
		if d > g:
			top = minf(top, d - 1.4)
	return maxf(top, g + 1.6)


## The water's edge the bake left open near bridge decks (and in a few short gaps), where the
## deck over it is high enough to drive under: runs of points a metre apart, each run reaching
## a metre into the baked edge on both ends. Not at the map's rim (the edge walls close it).
func _shore_under_decks(baked: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	const CELL := 8.0
	var grid := {}
	for poly in baked:
		for i in poly.size() - 1:
			var lo := poly[i].min(poly[i + 1]) - Vector2.ONE
			var hi := poly[i].max(poly[i + 1]) + Vector2.ONE
			for cz in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
				for cx in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
					var key := Vector2i(cx, cz)
					var list: PackedVector2Array = grid.get(key, PackedVector2Array())
					list.append_array(PackedVector2Array([poly[i], poly[i + 1]]))
					grid[key] = list
	var out: Array[PackedVector2Array] = []
	for a in data["areas"]:
		if a["k"] != "water":
			continue
		var ring := _pts(a["p"])
		var samples := PackedVector2Array()
		for i in ring.size():
			var p := ring[i]
			var q := ring[(i + 1) % ring.size()]
			var steps := maxi(1, ceili(p.distance_to(q)))
			for k in steps:
				samples.append(p.lerp(q, float(k) / steps))
		# open[k]: wall this sample (not covered, not the rim, nothing low overhead).
		var open := PackedByteArray()
		open.resize(samples.size())
		var start := -1
		for k in samples.size():
			var p := samples[k]
			# Not a seam between two water areas out on the water (the Vistula's polygons meet
			# across the river by Most Śląsko-Dąbrowski: a wall there stopped the boat race).
			var want := in_map(p, -1.0) and not _near_segments(grid, CELL, p, 0.75) \
					and shore_distance(p.x, p.y) < SEAM_WET
			if want:
				var g := terrain_height(p.x, p.y)
				for d in _decks_at(p.x, p.y):
					if d > g - 0.5 and d < g + SHORE_CLEAR:
						want = false
			open[k] = 1 if want else 0
			if not want and start < 0:
				start = k
		if start < 0:
			# Nothing baked round this water at all: the whole ring.
			ring.append(ring[0])
			out.append(ring)
			continue
		var run := PackedVector2Array()
		var count := samples.size()
		for j in count + 1:
			var k := (start + j) % count
			if open[k] == 1:
				if run.is_empty():
					run.append(samples[(k - 1 + count) % count])
				run.append(samples[k])
			elif not run.is_empty():
				run.append(samples[k])
				if run.size() >= 3:
					out.append(run)
				run = PackedVector2Array()
	return out


static func _near_segments(grid: Dictionary, cell: float, p: Vector2, reach: float) -> bool:
	var segs: PackedVector2Array = grid.get(Vector2i(floori(p.x / cell), floori(p.y / cell)), PackedVector2Array())
	for i in range(0, segs.size(), 2):
		var a := segs[i]
		var ab := segs[i + 1] - a
		var l2 := ab.length_squared()
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
		if p.distance_to(a + ab * t) < reach:
			return true
	return false


func _box_oriented(st, centre: Vector3, basis: Basis, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := n * h[axis]
			_quad(st, centre + basis * (c - u - v), centre + basis * (c + u - v), centre + basis * (c + u + v),
					centre + basis * (c - u + v), basis * n, col)


## Tram and bus stop islands and railway platforms: raised concrete slabs.
## PT-1 (2026-11-02): a platform at least SOLID_PLATFORM high (OSM railway=platform: 0.9 m, the
## stations' and some tram stops', like Centrum's on Marszałkowska) is solid at its edges. The car
## used to drive inside the slab (drive_height doesn't lift it 0.9 m) and stop dead on the shelter
## standing on it, boxed in by the fence along the kerb. The low 0.25 m stop islands stay drivable.
const SOLID_PLATFORM := 0.5
## An edge whose ends or middle lie within a road's half width plus this of its centre line is
## left open (check_drive: OSM's tram platforms overlap the outer lanes of Prosta, Niepodległości,
## Okopowa..., where a wall would stop traffic and the car in lane 0). The fence or kerb is there.
const PLATFORM_ROAD_CLEAR := 1.8


## The road centre-line segments near the high platforms (a, b, reach), for _by_road.
func _platform_roads() -> Array:
	var box := Rect2()
	var any := false
	for a in data.get("platforms", []):
		if float(a["h"]) < SOLID_PLATFORM:
			continue
		for q in _pts(a["p"]):
			if any:
				box = box.expand(q)
			else:
				box = Rect2(q, Vector2.ZERO)
				any = true
	var out := []
	if not any:
		return out
	box = box.grow(30.0)
	for r in data.get("roads", []):
		var pts := _pts(r["p"])
		var reach := float(r.get("w", 6.0)) * 0.5 + PLATFORM_ROAD_CLEAR
		for i in pts.size() - 1:
			var seg := Rect2(pts[i], Vector2.ZERO).expand(pts[i + 1])
			if seg.intersects(box, true):
				out.append([pts[i], pts[i + 1], reach])
	return out


## Whether a platform edge runs along or across a road (see PLATFORM_ROAD_CLEAR; across: Powiśle
## station's platforms are drawn at the ground and reach over Wybrzeże Kościuszkowskie).
func _by_road(p0: Vector2, p1: Vector2, roads: Array) -> bool:
	for r: Array in roads:
		var c := Geometry2D.get_closest_points_between_segments(p0, p1, r[0], r[1])
		if c[0].distance_to(c[1]) < float(r[2]):
			return true
	return false


const PLATFORM_TILES := Color("#b9b8b3")
const PLATFORM_EDGE := Color("#e4e2dc")
const PLATFORM_LINE := Color("#f0c419")
const PLATFORM_TACTILE := Color("#d2cfc6")


func _build_platforms(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var roads := _platform_roads()
	for a in data.get("platforms", []):
		var poly := _pts(a["p"])
		if poly.size() < 3:
			continue
		var h := float(a["h"])
		var ground := INF
		for q in poly:
			ground = minf(ground, terrain_height(q.x, q.y))
		var col := Color("#d4cfc5")
		var rail := h >= 0.7  # a railway platform (OSM 0.9 m), not a tram or bus island
		if rail:
			col = PLATFORM_TILES
		_fill(st, poly, ground + h + 0.1, col)
		if rail:
			# F 2026-11-06 (photos of Warszawa Główna's new platforms): a white edge band and the
			# yellow safety line 0.9 m in, the tactile strip inside it.
			var top := ground + h + 0.1
			var ring := poly.duplicate()
			ring.append(poly[0])
			_strip(st, ring, 0.35, top + 0.006, PLATFORM_EDGE, false)
			for inset: Array in [[-0.9, 0.14, PLATFORM_LINE], [-1.25, 0.4, PLATFORM_TACTILE]]:
				for inner: PackedVector2Array in Geometry2D.offset_polygon(poly, float(inset[0]), Geometry2D.JOIN_MITER):
					if Geometry2D.is_polygon_clockwise(inner):
						continue  # a hole
					var loop := inner.duplicate()
					loop.append(inner[0])
					_strip(st, loop, float(inset[1]), top + 0.01, inset[2], false)
		for i in poly.size():
			var p0 := poly[i]
			var p1 := poly[(i + 1) % poly.size()]
			var e := p1 - p0
			if e.length() < 0.05:
				continue
			var n := Vector3(e.y, 0.0, -e.x).normalized()
			_quad(st, Vector3(p0.x, ground - 0.3, p0.y), Vector3(p1.x, ground - 0.3, p1.y),
					Vector3(p1.x, ground + h + 0.1, p1.y), Vector3(p0.x, ground + h + 0.1, p0.y), n, col.darkened(0.12))
			if h >= SOLID_PLATFORM and not _by_road(p0, p1, roads):
				var b0 := Vector3(p0.x, terrain_height(p0.x, p0.y) - 0.3, p0.y)
				var b1 := Vector3(p1.x, terrain_height(p1.x, p1.y) - 0.3, p1.y)
				var up := Vector3(0.0, ground + h + 1.6 - minf(b0.y, b1.y), 0.0)
				_wall_faces.append_array([b0, b1, b1 + up, b0, b1 + up, b0 + up])
	_uv2 = Vector2.ZERO


## A cycle crossing's edge squares (P-11): their side in metres, a gap as long between them.
const CROSS_SQ := 0.4
## How far each row of squares lies from the crossing's middle (the red strip is 2.2 m wide).
const CROSS_EDGE := 1.1


## Cycle crossings in red across the road, and zebra stripes on pedestrian crossings.
func _build_crossings(st) -> void:
	var keep_bias := _drape_bias
	_layer = L_CYCLE
	_drape_bias = keep_bias - 0.02
	for p in data["paths"]:
		if p["k"] == "cyclecross":
			_dk = int(p.get("dk", -1))
			_strip(st, _pts(p["p"]), 2.2, Y_MARK, COL["cycle"])
	_drape_bias = keep_bias
	_layer = L_MARK
	# Idea #9 (2026-11-02): Warsaw's cycle crossings (P-11) are edged by two rows of white
	# squares; a row of CROSS_SQ squares a gap apart down each side of the red strip.
	for p in data["paths"]:
		if p["k"] != "cyclecross":
			continue
		_dk = int(p.get("dk", -1))
		var cpoly := _pts(p["p"])
		for i in cpoly.size() - 1:
			var a := cpoly[i]
			var seg := cpoly[i + 1] - a
			var length := seg.length()
			if length < CROSS_SQ:
				continue
			var dir := seg / length
			var side := Vector2(-dir.y, dir.x) * CROSS_EDGE
			var t := CROSS_SQ * 0.5
			while t < length - CROSS_SQ * 0.5:
				var c := a + dir * t
				for s in [side, -side]:
					_strip(st, PackedVector2Array([c + s - dir * CROSS_SQ * 0.5, c + s + dir * CROSS_SQ * 0.5]),
							CROSS_SQ, Y_MARK, COL["mark"], false)
				t += CROSS_SQ * 2.0
	for p in data["paths"]:
		if p["k"] != "zebra":
			continue
		_dk = int(p.get("dk", -1))
		var poly := _pts(p["p"])
		# Road design (tools/road_design.py): a zebra may say how wide it is (`w`, 4-10 m in the
		# centre); the bars run 0.2 m short of each edge. Without it the old 3.6 m.
		var bar := _zebra_bar(p)
		for i in poly.size() - 1:
			var a := poly[i]
			var seg := poly[i + 1] - a
			var length := seg.length()
			if length < 1.0:
				continue
			var dir := seg / length
			var t := 0.6
			while t < length - 0.4:
				var c := a + dir * t
				_strip(st, PackedVector2Array([c - dir * 0.25, c + dir * 0.25]), bar, Y_MARK, COL["mark"], false)
				t += 1.0
	_dk = -1


## A zebra's bar length across the crossing: its `w` less 0.4 m, else 3.6 m (TACTILE_WIDE).
static func _zebra_bar(p: Dictionary) -> float:
	return maxf(2.0, float(p["w"]) - 0.4) if p.has("w") else TACTILE_WIDE


## First-scene item 5 (2026-11-02): Warsaw's crossings end in a strip of yellow tactile paving
## on the pavement (and on the refuge islands) just past the kerb's granite top. Where a zebra's
## end lies within TACTILE_REACH of a kerb line (the bake's kerbs and the islands' rims, the
## index _index_raised keeps), a pad TACTILE_DEEP deep and as wide as the stripes is laid on the
## far side of that kerb, KERB_W out. Ends with no kerb near (a crossing over a footway, a deck)
## get none. Two triangles a pad in the flat mesh: +0 draw calls.
const TACTILE_DEEP := 0.6
const TACTILE_REACH := 2.6
const TACTILE_WIDE := 3.6
const TACTILE_COL := Color("#c6ad60")


func _build_tactile(st) -> void:
	if _kerb_segs.is_empty():
		_index_raised()
	_layer = L_TACTILE
	for p in data["paths"]:
		if p["k"] != "zebra" or int(p.get("dk", -1)) >= 0:
			continue
		var poly := _pts(p["p"])
		var n := poly.size()
		if n < 2 or poly[0].distance_to(poly[n - 1]) < 1.0:
			continue
		var wide := _zebra_bar(p)
		_tactile_pad(st, poly[0], (poly[0] - poly[1]).normalized(), wide)
		_tactile_pad(st, poly[n - 1], (poly[n - 1] - poly[n - 2]).normalized(), wide)
	_layer = L_GROUND


## The pad at a zebra's end `end`, `out` pointing off the carriageway: on the kerb line nearest
## the end along the zebra's line (from 1.5 m back inside to TACTILE_REACH beyond).
func _tactile_pad(st, end: Vector2, out: Vector2, wide: float = TACTILE_WIDE) -> void:
	var from := end - out * 1.5
	var to := end + out * TACTILE_REACH
	var best := INF
	var hit := Vector2.ZERO
	var c0 := Vector2i(floori(minf(from.x, to.x) / RAISE_CELL), floori(minf(from.y, to.y) / RAISE_CELL))
	var c1 := Vector2i(floori(maxf(from.x, to.x) / RAISE_CELL), floori(maxf(from.y, to.y) / RAISE_CELL))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			for id: int in _kerb_cells.get(Vector2i(cx, cz), PackedInt32Array()):
				var x: Variant = Geometry2D.segment_intersects_segment(from, to, _kerb_segs[id * 2], _kerb_segs[id * 2 + 1])
				if x != null and (x as Vector2).distance_to(end) < best:
					best = (x as Vector2).distance_to(end)
					hit = x
	if best == INF:
		return
	var a := hit + out * KERB_W
	var b := a + out * TACTILE_DEEP
	var mid := (a + b) * 0.5
	_strip(st, PackedVector2Array([a, b]), wide, Y_MARK + raise_at(mid.x, mid.y), TACTILE_COL, false)
	_lowered_kerb(st, hit, out, wide)


## First-scene item 5, lowered kerbs (2026-11-02): a crossing's kerb is dropped. A concrete wedge
## TACTILE_WIDE wide climbs from the road, RAMP_RUN before the kerb line, to the granite top, so
## the kerb's dark face is covered where the zebra meets it and the line of the kerb breaks. It
## lies in front of the face, flat on the granite to the tactile pad. Four triangles a pad in the
## flat mesh: +0 draw calls. Only where a pad is (a kerb line within TACTILE_REACH of the end).
const RAMP_RUN := 0.55
const RAMP_COL := Color("#aeaca5")


func _lowered_kerb(st, hit: Vector2, out: Vector2, wide: float = TACTILE_WIDE) -> void:
	var side := Vector2(-out.y, out.x) * (wide * 0.5)
	var foot := hit - out * RAMP_RUN
	var top := hit + out * KERB_W
	var keep := _layer
	_layer = L_GROUND
	_quad(st, Vector3(foot.x - side.x, Y_ROAD + 0.01, foot.y - side.y), Vector3(foot.x + side.x, Y_ROAD + 0.01, foot.y + side.y),
			Vector3(hit.x + side.x, KERB_UP + 0.01, hit.y + side.y), Vector3(hit.x - side.x, KERB_UP + 0.01, hit.y - side.y),
			Vector3.UP, RAMP_COL)
	_quad(st, Vector3(hit.x - side.x, KERB_UP + 0.01, hit.y - side.y), Vector3(hit.x + side.x, KERB_UP + 0.01, hit.y + side.y),
			Vector3(top.x + side.x, KERB_UP + 0.01, top.y + side.y), Vector3(top.x - side.x, KERB_UP + 0.01, top.y - side.y),
			Vector3.UP, RAMP_COL)
	_layer = keep


## Painted lines (tools/bake_roads.py), already cut where other roads cross: edge
## lines, lane lines (dashed), solid centre lines, stop lines, the bus lanes' wide
## line, cycle lanes (line and red surface), hatching stripes.
const MARK_STYLE := {
	"edge": [0.0, 0.2], "lane": [3.0, 0.22], "centre": [0.0, 0.2], "stop": [0.0, 0.5],
	"bus": [0.0, 0.3], "cycle": [0.0, 0.18], "stripe": [0.0, 0.45],
}


func _build_markings(st) -> void:
	var keep_bias := _drape_bias
	for m in data.get("markings", []):
		var poly := _pts(m["p"])
		_dk = int(m.get("dk", -1))
		var kind: String = m["k"]
		if kind == "cyclefill":
			# Under the white lines: a touch lower in the depth order.
			_layer = L_CYCLE
			_drape_bias = keep_bias - 0.015
			_strip(st, poly, float(m.get("w", 1.4)), Y_MARK - 0.005, COL["cycle"], false)
			_drape_bias = keep_bias
			continue
		_layer = L_MARK
		var style: Array = MARK_STYLE.get(kind, [0.0, 0.2])
		if float(style[0]) > 0.0:
			_dashes(st, poly, 0.0, float(style[0]), 5.0, float(style[1]))
		else:
			_dashes(st, poly, 0.0, 1000000.0, 0.0, float(style[1]))
	_dk = -1
	_build_pkin_bays(st)
	_layer = L_GROUND


## Turn arrows, BUS and bike symbols painted on the road, from pixel shapes: rows of
## "#" (paint) and "." whose top row lies furthest along the direction of travel and
## whose columns run across the lane, left to right as the driver sees them.
const ARROW_T := [
	"..#..", ".###.", "#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..",
]
const ARROW_L := [
	"..#......", ".##......", "#######..", ".##...#..", "..#...#..", "......#..", "......#..", "......#..",
	"......#..", "......#..",
]
const ARROW_TL := [
	"......#..", ".....###.", "....#####", "......#..", "..#...#..", ".##...#..", "#######..", ".##...#..",
	"..#...#..", "......#..",
]
## Loop 3b-2: the combined arrows 9 cells wide (they were 11: at the default view their
## 0.22 m cells and one-cell gaps ran together), the same width as the others.
const ARROW_LR := [
	".#.....#.", "##.....##", "#########", "##..#..##", ".#..#..#.", "....#....", "....#....",
	"....#....", "....#....", "....#....",
]
const ARROW_LTR := [
	"....#....", "...###...", "..#####..", "....#....", ".#..#..#.", "##..#..##", "#########",
	"##..#..##", ".#..#..#.", "....#....", "....#....",
]
## Round 4 (F): the U-turn (left and back, through a median's opening) and straight on with it.
const ARROW_U := [
	"...####..", "..#...#..", "..#...#..", "..#...#..", "#####.#..", ".###..#..", "..#...#..", "......#..",
	"......#..", "......#..",
]
const ARROW_TU := [
	"......#..", ".....###.", "....#####", "......#..", "...####..", "..#...#..", "#####.#..", ".###..#..",
	"..#...#..", "......#..",
]
const BIKE := [
	"....##..", "...#..#.", ".###....", "#..#.##.", "#..##..#", "#.#.#..#", ".#...##.",
]
## The sharrow's two chevrons (P-27), pointing the way of travel.
const CHEVRONS := [
	"..##..", ".#..#.", "#....#", "..##..", ".#..#.", "#....#",
]
const BUS_TEXT := [
	"###..#..#..###", "#..#.#..#.#...", "###..#..#..##.", "#..#.#..#....#", "###...##..###.",
]


func _build_symbols(st) -> void:
	_layer = L_MARK
	for m in data.get("symbols", []):
		_dk = int(m.get("dk", -1))
		var at := Vector2(m["x"], m["z"])
		var d: Array = m["d"]
		var fwd := Vector2(d[0], d[1]).normalized()
		match String(m["k"]):
			"arrow":
				var rows: Array = ARROW_T
				var mirror := false
				match String(m["t"]):
					"L":
						rows = ARROW_L
					"R":
						rows = ARROW_L
						mirror = true
					"LT":
						rows = ARROW_TL
					"TR":
						rows = ARROW_TL
						mirror = true
					"LR":
						rows = ARROW_LR
					"LTR":
						rows = ARROW_LTR
					"U":
						rows = ARROW_U
					"TU":
						rows = ARROW_TU
				# Loop 3b-2: cells up to 0.3 m across, the arrow up to 2.7 m wide (a lane is 3+ m),
				# so a 9-cell arrow keeps whole 0.3 m strokes and gaps (2.4 m made them 0.27).
				_pixel_shape(st, rows, at, fwd, minf(0.3, 2.7 / String(rows[0]).length()), 0.5, mirror)
			"bike":
				_pixel_shape(st, BIKE, at, fwd, 0.16, 0.2, false)
				# Idea #9 (tools/bike_network.py): a contraflow street's bike has an arrow ahead
				# of it (the riders' way, against the cars), a sharrow (P-27) two chevrons.
				match String(m.get("on", "")):
					"contra":
						_pixel_shape(st, ARROW_T, at + fwd * 1.5, fwd, 0.16, 0.11, false)
					"sharrow":
						_pixel_shape(st, CHEVRONS, at + fwd * 1.4, fwd, 0.2, 0.2, false)
			"bus":
				_pixel_shape(st, BUS_TEXT, at, fwd, 0.19, 0.5, false)
	_dk = -1
	_layer = L_GROUND


## A pixel shape on the road centred on `at`, its top row towards `fwd`; cells `cw`
## wide (across the road) and `cl` long (along it); `mirror` flips it left to right.
func _pixel_shape(st, rows: Array, at: Vector2, fwd: Vector2, cw: float, cl: float, mirror: bool) -> void:
	var right := Vector2(-fwd.y, fwd.x)
	var h := rows.size()
	var w := String(rows[0]).length()
	for j in h:
		var row := String(rows[j])
		var i := 0
		while i < w:
			if row[i] != "#":
				i += 1
				continue
			# A run of paint in a row becomes one rectangle.
			var i1 := i
			while i1 + 1 < w and row[i1 + 1] == "#":
				i1 += 1
			var x0 := float(i) - w * 0.5
			var x1 := float(i1 + 1) - w * 0.5
			if mirror:
				var t := -x1
				x1 = -x0
				x0 = t
			var y0 := h * 0.5 - float(j + 1)
			var y1 := h * 0.5 - float(j)
			var c: Array[Vector2] = []
			for corner in [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]:
				c.append(at + right * (corner.x * cw) + fwd * (corner.y * cl))
			_quad(st, Vector3(c[0].x, Y_MARK, c[0].y), Vector3(c[1].x, Y_MARK, c[1].y),
					Vector3(c[2].x, Y_MARK, c[2].y), Vector3(c[3].x, Y_MARK, c[3].y), Vector3.UP, COL["mark"])
			i = i1 + 1


func _dashes(st, poly: PackedVector2Array, offset: float, on: float, off: float, width: float) -> void:
	var phase := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := b - a
		var length := seg.length()
		if length < 0.01:
			continue
		var dir := seg / length
		var side := Vector2(-dir.y, dir.x)
		a += side * offset
		var t := -phase
		while t < length:
			var s0 := maxf(t, 0.0)
			var s1 := minf(t + on, length)
			if s1 > s0:
				var dash := PackedVector2Array([a + dir * s0, a + dir * s1])
				_strip(st, dash, width, Y_MARK, COL["mark"], false)
			t += on + off
		phase = fposmod(phase + length, on + off)


## Smooth roads loop 7 (F's ChatGPT target): where a tram track runs on its own bed
## (`trams[].bed`, metres along it, tools/road_smooth.py tram_beds) a 2.4 m band of gravel under
## it that the shader (ground.gdshader, layer 21) cuts into sleepers every 0.6 m. Same mesh and
## material: no new draw call.
func _build_tram_sleepers(st) -> void:
	_layer = L_SLEEPERS
	for t in data["trams"]:
		if not t.has("bed"):
			continue
		var poly := _pts(t["p"])
		_dk = int(t.get("dk", -1))
		for b in t["bed"]:
			var run := _sub_poly(poly, float(b[0]), float(b[1]))
			if run.size() >= 2:
				_strip(st, run, TRAM_SLEEPER_W, Y_ROAD + 0.008, TRAM_GRAVEL, false)
	_dk = -1
	_layer = L_GROUND


## Smooth roads loop 7: a road or a footway across a tram bed (`tram_xings`,
## tools/road_smooth.py tram_crossings): one mitred band over the bed and its sleepers, under the
## rails: the road's asphalt, or a footway's pale concrete panels (the road under the bed showed
## only its lines and kerbs, curving across the tracks).
func _build_tram_crossings(st) -> void:
	for x in data.get("tram_xings", []):
		# Round 4 (F): a road's opening through a median is one paved footprint (`foot`), flush,
		# its noses rounded over it (_build_tram_noses).
		# Asphalt like the carriageways it joins, so the opening reads as one flush road.
		if x.has("foot"):
			_layer = L_ROAD
			_fill_quad_fine(st, _pts(x["foot"]), Y_ROAD + 0.01, COL["road"])
			continue
		# A road keeps its asphalt across the tracks; a footway gets the pale panels.
		var road: bool = x.get("k", "") == "road"
		_layer = L_ROAD if road else L_TRAMBED
		var poly := _pts(x["p"])
		var ws := PackedFloat32Array()
		var cs := PackedFloat32Array()
		for i in poly.size():
			ws.append(float(x["w"]))
			cs.append(0.0)
		_band_var(st, poly, ws, cs, Y_ROAD + 0.01, COL["road"] if road else TRAM_XING)
	_axis = Vector2.ZERO
	_layer = L_GROUND


## Round 4: a four-cornered polygon in cells of about a metre, so it follows the ground like
## the bed's sleeper strips under it (one flat 12 m triangle sank under them mid-span).
func _fill_quad_fine(st, q: PackedVector2Array, y: float, col: Color) -> void:
	if q.size() != 4:
		_fill(st, q, y, col)
		return
	var nu := maxi(1, ceili(q[0].distance_to(q[1])))
	var nv := maxi(1, ceili(q[1].distance_to(q[2])))
	for i in nu:
		for j in nv:
			var u0 := float(i) / nu
			var u1 := float(i + 1) / nu
			var v0 := float(j) / nv
			var v1 := float(j + 1) / nv
			var a := _bilerp(q, u0, v0)
			var b := _bilerp(q, u1, v0)
			var c := _bilerp(q, u1, v1)
			var d := _bilerp(q, u0, v1)
			_fill(st, PackedVector2Array([a, b, c, d]), y, col)


func _bilerp(q: PackedVector2Array, u: float, v: float) -> Vector2:
	return q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), v)


## Round 4 (F): the rounded ends of a tram median at a road's opening (`tram_noses`,
## tools/road_smooth.py shape_openings): gravel like the bed, over the opening's paving; their
## kerbs come with the kerbs.
func _build_tram_noses(st) -> void:
	_layer = L_GRAVEL
	for n in data.get("tram_noses", []):
		# in rings round the middle, so it follows the ground over the opening's paving
		var ring := _pts(n["p"])
		var mid := Vector2.ZERO
		for q in ring:
			mid += q
		mid /= maxf(1.0, ring.size())
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			for k in 4:
				var t0 := k / 4.0
				var t1 := (k + 1) / 4.0
				_fill(st, PackedVector2Array([mid.lerp(a, t0), mid.lerp(a, t1), mid.lerp(b, t1), mid.lerp(b, t0)]),
					Y_ROAD + 0.03, TRAM_BED)
	_layer = L_GROUND


## The part of a polyline from s0 to s1 metres along it.
func _sub_poly(poly: PackedVector2Array, s0: float, s1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var s := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		if length > 0.0 and s + length >= s0 and s <= s1:
			var f0 := clampf((s0 - s) / length, 0.0, 1.0)
			var f1 := clampf((s1 - s) / length, 0.0, 1.0)
			if out.is_empty():
				out.append(a.lerp(b, f0))
			out.append(a.lerp(b, f1))
		s += length
	return out


func _build_trams(st) -> void:
	_layer = L_RAIL
	for t in data["trams"]:
		var poly := _pts(t["p"])
		_dk = int(t.get("dk", -1))
		for side in [-0.72, 0.72]:
			var rail := PackedVector2Array()
			for i in poly.size():
				var d: Vector2
				if i < poly.size() - 1:
					d = (poly[i + 1] - poly[i]).normalized()
				else:
					d = (poly[i] - poly[i - 1]).normalized()
				rail.append(poly[i] + Vector2(-d.y, d.x) * side)
			_strip(st, rail, TRAM_RAIL_W, Y_MARK + 0.005, TRAM_RAIL)
	_dk = -1


## Loop 3d-1: whether a wall at p stands in one of `lod2_open`'s boxes (a wall in a lane's
## corridor, tools/bake_structures.py open_lod2: LoD2 and, since loop 3d-1, OSM buildings).
func _open_wall(p: Vector2, open: Array) -> bool:
	for o: Array in open:
		if absf(p.x - float(o[0])) < float(o[2]) and absf(p.y - float(o[1])) < float(o[2]):
			return true
	return false


func _build_buildings(st, keep: Array, marks) -> void:
	var list: Array = data["buildings"]
	var open: Array = data.get("lod2_open", [])
	var drawn: Array[int] = []
	for index in (keep if _has_lod2 else range(list.size())):
		var bld: Dictionary = list[int(index)]
		if (bld["p"] as Array).size() < 6 or bld.has("br") or bld.has("cutd"):
			continue  # a 3D-mapped bridge (the decks draw it), or left out under a deck (loop 3b)
		if not marks.keeps_building(bld):
			continue  # a landmark (landmarks.gd) stands here
		if float(bld["h"]) <= float(bld["mh"]):
			continue
		drawn.append(int(index))
	var bottoms := _part_bottoms(list, drawn, marks)
	var royal := _royal_segments()
	for index in drawn:
		var bld: Dictionary = list[index]
		var poly := _pts(bld["p"])
		var h := float(bld["h"])
		var mh := float(bottoms.get(index, bld["mh"]))
		if mh < 0.0:
			continue  # a tiny floating bit (_part_bottoms)
		var ground := INF
		for q in poly:
			ground = minf(ground, terrain_height(q.x, q.y))
		if bld.has("pil"):
			# Loop 3b: a viaduct's mapped pillar, fitted to the slab it carries.
			h = float(bld["cut"]) - ground
		elif bld.has("cut"):
			# Loop 3b: under a deck, cut to the slab's bottom - 0.5 m (tools/bake_structures.py).
			h = minf(h, float(bld["cut"]) - ground)
		var hsh := absi(int(poly[0].x * 73.0 + poly[0].y * 31.0))
		var glass := h > 55.0
		var wall := _osm_colour(bld["c"], Color(GLASS[hsh % GLASS.size()] if glass else FACADES[hsh % FACADES.size()]))
		var roof := _osm_colour(bld["rc"], Color(ROOFS[hsh % ROOFS.size()]))
		if glass and str(bld["rc"]) == "":
			roof = wall.darkened(0.25)
		# Alpha tells the building shader which window pattern to draw.
		wall.a = 0.5 if glass else 1.0
		_uv2 = Vector2(fposmod(hsh * 0.6180339887, 1.0), h)
		var plan := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			plan = plan.expand(q)
		var skin: Dictionary = marks.skin_at(plan)
		var pitched := {}
		if not skin.is_empty():
			wall = skin["wall"]
			roof = skin["roof"]
			_uv2.x = skin["mode"]
		elif not glass and not _historic(plan.get_center(), 0.0):
			_uv2.x = typed_seed(_building_type(str(bld["kind"]), poly, h), _uv2.x)
			if not bld.has("pil") and not bld.has("cut") and mh < 1.0:
				pitched = OsmRoofs.shape(poly, h, str(bld["kind"]))
		# RF4: a small low house gets a pitched roof in its district's material (the walls stop
		# at the eave, the ridge stands where the flat lid did).
		var rise := float(pitched.get("rise", 0.0))
		var wall_h := h - rise
		if rise > 0.0:
			_uv2.y = wall_h
			if str(bld["rc"]) == "":
				roof = _district_roof(plan.get_center(), hsh, str(bld["kind"]), royal)
		if skin.is_empty() and not glass and _nowy_swiat(plan.get_center()):
			wall = Color(NOWY_PASTELS[(hsh / 7) % NOWY_PASTELS.size()]).lerp(wall, 0.25)
		elif skin.is_empty() and not glass and _powisle_house(bld, poly, plan.get_center()):
			wall = Color(POWISLE_PASTELS[(hsh / 7) % POWISLE_PASTELS.size()]).lerp(wall, 0.25)

		var run := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var edge := b - a
			var length := edge.length()
			if length < 0.05:
				continue
			# Polygons are counter-clockwise in x/z, so the outward normal is to the right.
			var n := Vector3(edge.y, 0.0, -edge.x).normalized()
			var bottom := ground + mh - (0.4 if mh < 0.5 else 0.0)
			var p0 := Vector3(a.x, bottom, a.y)
			var p1 := Vector3(b.x, bottom, b.y)
			var p2 := Vector3(b.x, ground + wall_h, b.y)
			var p3 := Vector3(a.x, ground + wall_h, a.y)
			var base_col := wall.darkened(0.12) if mh < 1.0 else wall
			var u0 := Vector2(run, mh)
			var u1 := Vector2(run + length, mh)
			var u2 := Vector2(run + length, wall_h)
			var u3 := Vector2(run, wall_h)
			_tri_shaded(st, p0, p1, p2, n, base_col, base_col, wall, u0, u1, u2)
			_tri_shaded(st, p0, p2, p3, n, base_col, wall, wall, u0, u2, u3)
			run += length
			if mh < 2.0 and not _open_wall((a + b) * 0.5, open):
				var g0 := ground - 1.0
				# Loop 3b: never over the building's own top (a viaduct's pillar ends under its slab).
				var g1 := ground + minf(5.0, h)
				_wall_faces.append_array([Vector3(a.x, g0, a.y), Vector3(b.x, g0, b.y), Vector3(b.x, g1, b.y),
						Vector3(a.x, g0, a.y), Vector3(b.x, g1, b.y), Vector3(a.x, g1, a.y)])
		if rise > 0.0:
			_pitched_gables(st, pitched, ground + wall_h, wall_h, wall)
		_uv2 = Vector2(_uv2.x, -1.0)
		if rise > 0.0:
			_pitched_roof_slopes(st, pitched, ground + wall_h, roof)
		else:
			_fill(st, poly, ground + h, roof)
		_roof_polygon(poly, ground + h, roof, wall)
	_uv2 = Vector2.ZERO


## RF4: the gable ends of an OsmRoofs.shape standing on the eave at `eave` (wall triangles, so
## they take the building's windows' pattern and the wall colour; `_uv2` is still the wall's).
func _pitched_gables(st, pitched: Dictionary, eave: float, wall_h: float, wall: Color) -> void:
	for t: Array in pitched["gables"]:
		var a: Vector3 = t[0] + Vector3(0.0, eave, 0.0)
		var b: Vector3 = t[1] + Vector3(0.0, eave, 0.0)
		var c: Vector3 = t[2] + Vector3(0.0, eave, 0.0)
		var n := Vector3(b.z - a.z, 0.0, a.x - b.x).normalized()  # outward: to the right of a to b
		_tri_shaded(st, a, b, c, n, wall, wall, wall, Vector2(a.x + a.z, wall_h + t[0].y), Vector2(b.x + b.z, wall_h + t[1].y),
				Vector2(c.x + c.z, wall_h + t[2].y))


## RF4: the roof slopes of an OsmRoofs.shape (the roof branch of the building shader, UV2.y < 0).
func _pitched_roof_slopes(st, pitched: Dictionary, eave: float, roof: Color) -> void:
	for t: Array in pitched["roof"]:
		var a: Vector3 = t[0] + Vector3(0.0, eave, 0.0)
		var b: Vector3 = t[1] + Vector3(0.0, eave, 0.0)
		var c: Vector3 = t[2] + Vector3(0.0, eave, 0.0)
		var n := (b - a).cross(c - a)
		if n.length() < 0.001:
			continue
		n = n.normalized()
		if n.y < 0.0:
			n = -n
		_tri(st, a, b, c, n, roof)


## RF4: a pitched roof's colour by district where OpenStreetMap has none: the Royal Route's
## palaces under copper (green with age) or red sheet metal, MDM's blocks under dark red sheet,
## small houses under ceramic tile, the rest under painted sheet in grey or red-brown.
func _district_roof(at: Vector2, hsh: int, kind: String, royal: Array) -> Color:
	var pick := fposmod(hsh * 0.6180339887, 1.0)
	var jitter := 0.92 + 0.16 * fposmod(hsh * 0.3819660113, 1.0)
	var col: Color
	if _on_royal_route(at.x, at.y, royal):
		col = Color(PATINA) if pick < 0.55 else Color(RED_SHEET)
	elif at.distance_to(Vector2(CANDELABRAS.x, CANDELABRAS.y)) < MDM_REACH:
		col = Color(RED_SHEET).darkened(0.1)
	elif kind == "house" or kind == "detached" or kind == "semidetached_house" or kind == "terrace":
		col = Color(TILE_RED)
	elif pick < 0.4:
		col = Color(TILE_RED)
	elif pick < 0.7:
		col = Color(RED_SHEET)
	else:
		col = Color(ROOFS[hsh % ROOFS.size()])
	return Color(col.r * jitter, col.g * jitter, col.b * jitter, 1.0)


## Loop 1: OpenStreetMap building parts that would float. A part is drawn from its
## min_height up; where the parts under it are not mapped (Varso 2's 80-90 m top hung over
## nothing, a "broken lamp post" from the south-west), it hangs in the air. A part that
## starts FLOAT_MIN or more up (lower ones are real: canopies, passages, pilotis) and rests on something under less than half of its
## footprint (another drawn part reaching to within FLOAT_GAP of its bottom, or, within
## FLOAT_SLACK, a LoD2 building or a landmark: those outlines differ a little from
## OpenStreetMap's) is lowered to the highest roof below it that carries at least half of
## it, or to the ground; a tiny one (under FLOAT_TINY m2: a mast's or a sign's bits, the
## spire of a tower that stands off the map) is left out instead. Lowest parts first, so a
## part resting on a left-out one is judged without it. Returns index -> new bottom in
## metres (-1: left out); `floating_parts` / `floating_to_ground` / `floating_dropped` count.
const FLOAT_MIN := 10.0
const FLOAT_GAP := 3.0
const FLOAT_SLACK := 2.5
const FLOAT_TINY := 12.0
const FLOAT_CELL := 32.0
var floating_parts := 0
var floating_to_ground := 0
var floating_dropped := 0


func _part_bottoms(list: Array, drawn: Array[int], marks) -> Dictionary:
	var out := {}
	var polys := {}
	var boxes := {}
	var grid := {}
	for index in drawn:
		var poly := _pts(list[index]["p"])
		var box := _poly_box(poly)
		polys[index] = poly
		boxes[index] = box
		_grid_add(grid, box, index)
	# LoD2 buildings stand on the ground and carry what sits on them: negative keys.
	var lod := {}
	for k in _lod2_footprints.size():
		var poly := _pts(_lod2_footprints[k])
		if poly.size() < 3:
			continue
		var box := _poly_box(poly)
		lod[-1 - k] = poly
		boxes[-1 - k] = box
		_grid_add(grid, box, -1 - k)
	var high: Array[int] = []
	for index in drawn:
		if float(list[index]["mh"]) >= FLOAT_MIN:
			high.append(index)
	high.sort_custom(func(a: int, b: int) -> bool: return float(list[a]["mh"]) < float(list[b]["mh"]))
	for index in high:
		var mh := float(list[index]["mh"])
		var poly: PackedVector2Array = polys[index]
		var box: Rect2 = boxes[index]
		# Up to 8 x 8 points over the footprint.
		var step := maxf(1.0, maxf(box.size.x, box.size.y) / 8.0)
		var samples := PackedVector2Array()
		var y := box.position.y + step * 0.5
		while y < box.end.y:
			var x := box.position.x + step * 0.5
			while x < box.end.x:
				if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
					samples.append(Vector2(x, y))
				x += step
			y += step
		if samples.is_empty():
			samples.append(box.get_center())
		var under: Array[int] = []
		var seen := {}
		var near := box.grow(FLOAT_SLACK)
		for key in _grid_keys(near):
			for j in grid.get(key, []):
				if j == index or seen.has(j) or not (boxes[j] as Rect2).intersects(near):
					continue
				seen[j] = true
				if j < 0 or (float(list[j]["mh"]) < mh and float(out.get(j, 0.0)) >= 0.0):
					under.append(j)
		if _carried(list, samples, under, polys, lod, marks, mh) >= 0.5:
			continue
		floating_parts += 1
		if absf(_poly_area(poly)) < FLOAT_TINY:
			out[index] = -1.0
			floating_dropped += 1
			continue
		var tops: Array[float] = []
		for j in under:
			if j >= 0 and float(list[j]["h"]) < mh and not tops.has(float(list[j]["h"])):
				tops.append(float(list[j]["h"]))
		tops.sort()
		tops.reverse()
		var bottom := 0.0
		for t in tops:
			if t >= FLOAT_MIN and _carried(list, samples, under, polys, lod, marks, t) >= 0.5:
				bottom = t
				break
		out[index] = bottom
		if bottom == 0.0:
			floating_to_ground += 1
	return out


## The share of `samples` resting on something at `level`: a part that starts below it and
## reaches up to within FLOAT_GAP of it, or (within FLOAT_SLACK) a LoD2 building or a landmark.
func _carried(list: Array, samples: PackedVector2Array, under: Array[int], polys: Dictionary, lod: Dictionary, marks, level: float) -> float:
	var held := 0
	var slack: Array[Vector2] = [Vector2.ZERO, Vector2(FLOAT_SLACK, 0), Vector2(-FLOAT_SLACK, 0), Vector2(0, FLOAT_SLACK), Vector2(0, -FLOAT_SLACK)]
	for q in samples:
		var ok := false
		for j in under:
			if j < 0:
				for o in slack:
					if Geometry2D.is_point_in_polygon(q + o, lod[j]):
						ok = true
						break
			elif float(list[j]["mh"]) < level and float(list[j]["h"]) >= level - FLOAT_GAP \
					and Geometry2D.is_point_in_polygon(q, polys[j]):
				ok = true
			if ok:
				break
		if not ok:
			for o in slack:
				if marks.replaces(q + o):
					ok = true
					break
		if ok:
			held += 1
	return float(held) / float(samples.size())


static func _poly_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


static func _poly_box(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	return box


static func _grid_keys(box: Rect2) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for i in range(floori(box.position.x / FLOAT_CELL), floori(box.end.x / FLOAT_CELL) + 1):
		for j in range(floori(box.position.y / FLOAT_CELL), floori(box.end.y / FLOAT_CELL) + 1):
			keys.append(Vector2i(i, j))
	return keys


static func _grid_add(grid: Dictionary, box: Rect2, index: int) -> void:
	for key in _grid_keys(box):
		if not grid.has(key):
			grid[key] = []
		grid[key].append(index)


## GUGiK LoD2 buildings from the baked mesh. Returns the OpenStreetMap
## buildings that still need drawing (empty when there is no LoD2 bake).
func _build_lod2(walls, marks) -> Array:
	if not FileAccess.file_exists("res://map/lod2.bin"):
		return []
	var meta: Dictionary = {}
	var count := 0
	var f := PackedFloat32Array()
	# Loop 3c: one sector reads only its buildings (the split's `lod2_runs`: vertex ranges of
	# lod2.bin, one per building) and keeps them apart by that table, not by their seeds.
	var runs := PackedInt32Array()
	if _in_sector:
		_lod2_footprints = data.get("lod2_footprints", [])
		var picked := _read_lod2_runs(data.get("lod2_runs", []))
		count = picked[0]
		f = picked[1]
		runs = picked[2]
	else:
		meta = JSON.parse_string(FileAccess.get_file_as_string("res://map/lod2.json"))
		_lod2_footprints = meta.get("footprints", [])
		var bytes := FileAccess.get_file_as_bytes("res://map/lod2.bin")
		count = bytes.decode_u32(0)
		f = bytes.slice(4).to_float32_array()
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	pos.resize(count)
	nrm.resize(count)
	col.resize(count)
	uv.resize(count)
	var uv2 := PackedVector2Array()
	uv2.resize(count)
	var o_n := count * 3
	var o_c := count * 6
	var o_u := count * 10
	var o_u2 := count * 12
	for i in count:
		var k := i * 3
		pos[i] = Vector3(f[k], f[k + 1], f[k + 2])
		nrm[i] = Vector3(f[o_n + k], f[o_n + k + 1], f[o_n + k + 2])
		var c := o_c + i * 4
		col[i] = Color(f[c], f[c + 1], f[c + 2], f[c + 3])
		uv[i] = Vector2(f[o_u + i * 2], f[o_u + i * 2 + 1])
		uv2[i] = Vector2(f[o_u2 + i * 2], f[o_u2 + i * 2 + 1])
	# Loop 3b: LoD2 buildings under a bridge deck, cut to the slab's bottom - 0.5 m or left
	# out (tools/bake_structures.py `lod2_cuts`; the Poniatowski viaduct's arcades).
	var cuts: Array = data.get("lod2_cuts", [])
	if not cuts.is_empty():
		var clipped := _clip_lod2(pos, nrm, col, uv, uv2, cuts, runs)
		pos = clipped[0]
		nrm = clipped[1]
		col = clipped[2]
		uv = clipped[3]
		uv2 = clipped[4]
		runs = clipped[5]
		count = pos.size()
	# F's look check (2026-11-03): kept LoD2 parts a landmark's model replaces above a height
	# (the Royal Castle's Clock Tower under its copper helm).
	if not marks.lod2_tops.is_empty():
		var topped := _top_lod2(pos, nrm, col, uv, uv2, marks.lod2_tops, runs)
		pos = topped[0]
		nrm = topped[1]
		col = topped[2]
		uv = topped[3]
		uv2 = topped[4]
		runs = topped[5]
		count = pos.size()
	# v0.8: whole LoD2 buildings that stand where a landmark is built are left out. The
	# bake writes each building's triangles in one run sharing its style seed (UV2.x).
	var dropped := PackedByteArray()
	dropped.resize(count / 3)
	# R4: each kept building's triangle run, typed after the historic districts' pass.
	var building_runs: Array[Vector3i] = []
	var t0 := 0
	var ri := 0
	while t0 < count:
		var seed := uv2[t0].x
		var first := Vector2(pos[t0].x, pos[t0].z)
		var lo := first
		var hi := first
		var t1 := t0
		if not runs.is_empty():
			var end := t0 + runs[ri]
			ri += 1
			while t1 < end:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
			if t1 == t0:
				continue
		else:
			while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		if marks.replaces((lo + hi) * 0.5):
			# A modelled block on a LoD2 roof: only the walls go, the measured roof stays.
			var roofs: bool = marks.keeps_lod2_roof((lo + hi) * 0.5)
			for t in range(t0, t1, 3):
				if not roofs or absf(nrm[t].y) < 0.3:
					dropped[t / 3] = 1
		else:
			# The landmarks loop: a kept building in a landmark's own stone (Muzeum Narodowe).
			var skin: Dictionary = marks.skin_at(Rect2(lo, hi - lo))
			if not skin.is_empty():
				_skin_run(skin, pos, nrm, col, uv2, t0, t1)
			else:
				building_runs.append(Vector3i(t0, t1, 0))
		t0 = t1
	var facades := _tenement_facades(pos, nrm, col, uv2, dropped)
	col = facades[0]
	uv2 = facades[1]
	uv2 = _typed_lod2(pos, col, uv2, building_runs)
	col = _boulevard_dress(pos, nrm, col, building_runs)
	var dress: Dictionary = facades[2]
	if not walls.none:
		_roof_dress(pos, nrm, col, uv, uv2, building_runs, dress)
	# Split into tiles by triangle, like the other city meshes (not on the roof pass).
	var tiles := {}
	for t in range(0, count if not walls.none else 0, 3):
		if dropped[t / 3]:
			continue
		var centre := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
		var key := Chunked.tile_of(centre)
		if not tiles.has(key):
			tiles[key] = [[], [], [], [], []]
		var tile: Array = tiles[key]
		for k in 3:
			(tile[0] as Array).append(pos[t + k])
			(tile[1] as Array).append(nrm[t + k])
			(tile[2] as Array).append(col[t + k])
			(tile[3] as Array).append(uv[t + k])
			(tile[4] as Array).append(uv2[t + k])
	# The Old Town's dormers and chimneys: extra triangles in the same tiles (no collision).
	var dress_pos: PackedVector3Array = dress["pos"]
	for t in range(0, dress_pos.size() if not walls.none else 0, 3):
		var key := Chunked.tile_of((dress_pos[t] + dress_pos[t + 1] + dress_pos[t + 2]) / 3.0)
		if not tiles.has(key):
			tiles[key] = [[], [], [], [], []]
		var tile: Array = tiles[key]
		for k in 3:
			(tile[0] as Array).append(dress_pos[t + k])
			(tile[1] as Array).append((dress["nrm"] as PackedVector3Array)[t + k])
			(tile[2] as Array).append((dress["col"] as PackedColorArray)[t + k])
			(tile[3] as Array).append(Vector2(-1.0, -1.0))
			(tile[4] as Array).append(Vector2(0.5, -1.0))
	# Loop 2b: into the walls' tile meshes (same material): one draw call per tile, not two.
	for key in tiles:
		var tile: Array = tiles[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(tile[0])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(tile[1])
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(tile[2])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(tile[3])
		arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(tile[4])
		walls.add_arrays(key, arrays)
	# Walls are what the car bumps into; roofs (and wall tops) are what the helicopter can't fly through.
	# Loop 3b: not where a wall stands in a lane (`lod2_open`, tools/bake_structures.py).
	var open: Array = data.get("lod2_open", [])
	for t in range(0, count, 3):
		if dropped[t / 3]:
			continue
		var flat_ish := absf(nrm[t].y) >= 0.3
		if not flat_ish:
			var solid := true
			if not open.is_empty():
				# Loop 3d-1: the triangle's edges, not its centre (a long wall's triangle reaches
				# into the lane with its centre metres away: 5 lanes in the demo box).
				var ta := Vector2(pos[t].x, pos[t].z)
				var tb := Vector2(pos[t + 1].x, pos[t + 1].z)
				var tc := Vector2(pos[t + 2].x, pos[t + 2].z)
				for o: Array in open:
					var oc := Vector2(float(o[0]), float(o[1]))
					var r := float(o[2])
					if Geometry2D.get_closest_point_to_segment(oc, ta, tb).distance_to(oc) < r \
							or Geometry2D.get_closest_point_to_segment(oc, tb, tc).distance_to(oc) < r \
							or Geometry2D.get_closest_point_to_segment(oc, tc, ta).distance_to(oc) < r:
						solid = false
						break
			if solid:
				_wall_faces.append_array([pos[t], pos[t + 1], pos[t + 2]])
		_roof_triangle(pos[t], pos[t + 1], pos[t + 2], flat_ish, col[t])
	_has_lod2 = true
	if not _in_sector:
		return meta["keep_osm"]
	# Loop 3c: the split marks the OpenStreetMap buildings LoD2 keeps (`keep`).
	var keep := []
	var list: Array = data["buildings"]
	for i in list.size():
		if list[i].has("keep"):
			keep.append(i)
	return keep


## Loop 3c: the LoD2 vertex ranges [t0, t1, ...] read from lod2.bin: [vertex count, the
## floats in lod2.bin's layout (positions, normals, colours, UV, UV2), each range's count].
func _read_lod2_runs(ranges: Array) -> Array:
	var file := FileAccess.open("res://map/lod2.bin", FileAccess.READ)
	var total := file.get_32()
	var runs := PackedInt32Array()
	var count := 0
	for r in range(0, ranges.size() - 1, 2):
		runs.append(int(ranges[r + 1]) - int(ranges[r]))
		count += runs[-1]
	var bytes := PackedByteArray()
	for block: Vector2i in [Vector2i(0, 3), Vector2i(total * 3, 3), Vector2i(total * 6, 4), Vector2i(total * 10, 2),
			Vector2i(total * 12, 2)]:
		for r in range(0, ranges.size() - 1, 2):
			var t0 := int(ranges[r])
			file.seek(4 + (block.x + t0 * block.y) * 4)
			bytes.append_array(file.get_buffer((int(ranges[r + 1]) - t0) * block.y * 4))
	return [count, bytes.to_float32_array(), runs]


## Loop 3b: the LoD2 triangles with the cut buildings clipped. A building is a run of
## triangles sharing its style seed (as `_build_lod2` finds them); a run whose box centre is a
## cut's ([x, z, top, left out]) loses everything over the top: walls are clipped at it, roof
## triangles over it are laid flat at it (they cover the footprint, so the cut is closed).
func _clip_lod2(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array, cuts: Array, runs := PackedInt32Array()) -> Array:
	# Loop 3c: `runs` (a sector's table of buildings) comes back with each one's new count.
	var o_runs := PackedInt32Array()
	var ri := 0
	var o_pos := PackedVector3Array()
	var o_nrm := PackedVector3Array()
	var o_col := PackedColorArray()
	var o_uv := PackedVector2Array()
	var o_uv2 := PackedVector2Array()
	var count := pos.size()
	var t0 := 0
	var n_cut := 0
	while t0 < count:
		var seed := uv2[t0].x
		var first := Vector2(pos[t0].x, pos[t0].z)
		var lo := first
		var hi := first
		var t1 := t0
		if not runs.is_empty():
			var end := t0 + runs[ri]
			ri += 1
			while t1 < end:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		else:
			while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		var before := o_pos.size()
		var centre := (lo + hi) * 0.5
		var cut := INF
		var drop := false
		for c: Array in cuts:
			if absf(float(c[0]) - centre.x) < 0.3 and absf(float(c[1]) - centre.y) < 0.3:
				cut = float(c[2])
				drop = int(c[3]) == 1
				break
		if drop:
			n_cut += 1
		elif cut == INF:
			o_pos.append_array(pos.slice(t0, t1))
			o_nrm.append_array(nrm.slice(t0, t1))
			o_col.append_array(col.slice(t0, t1))
			o_uv.append_array(uv.slice(t0, t1))
			o_uv2.append_array(uv2.slice(t0, t1))
		else:
			n_cut += 1
			for t in range(t0, t1, 3):
				var roof := nrm[t].y >= 0.3
				var below: Array = []   # [pos, colour, uv] corners of the part under the cut
				var above: Array = []
				for k in 3:
					var a := t + k
					var b := t + (k + 1) % 3
					var a_up := pos[a].y > cut
					var b_up := pos[b].y > cut
					(above if a_up else below).append([pos[a], col[a], uv[a]])
					if a_up != b_up:
						var f := (cut - pos[a].y) / (pos[b].y - pos[a].y)
						var corner := [pos[a].lerp(pos[b], f), col[a].lerp(col[b], f), uv[a].lerp(uv[b], f)]
						below.append(corner)
						above.append(corner)
				for pi in (2 if roof else 1):
					var part: Array = below if pi == 0 else above
					var flat := pi == 1
					for k in range(1, part.size() - 1):
						for v: Array in [part[0], part[k], part[k + 1]]:
							var p: Vector3 = v[0]
							o_pos.append(Vector3(p.x, cut, p.z) if flat else p)
							o_nrm.append(Vector3.UP if flat else nrm[t])
							o_col.append(v[1])
							o_uv.append(v[2])
							o_uv2.append(uv2[t])
		o_runs.append(o_pos.size() - before)
		t0 = t1
	if not _in_sector:
		print("lod2: %d buildings cut under a deck (loop 3b)" % n_cut)
	return [o_pos, o_nrm, o_col, o_uv, o_uv2, o_runs if not runs.is_empty() else PackedInt32Array()]


## A kept LoD2 building in a landmark's skin (`skin_at`): its roof colour on faces flatter than
## the skin's `steep` (0.7 unless it says: a steeper LoD2 slope reads as wall), its wall colour on
## the rest, and its `pale` colour on the walls along one front (`pale`: {wall, edges: pairs of
## outline ends, near}: walls whose centre is within `near` m of one of those edges). F's look
## check (2026-11-03): the Royal Castle's steep roof slopes and LoD2's walls standing up to 0.9 m
## proud of the model's Vistula front showed as a salmon band over the pale river front.
func _skin_run(skin: Dictionary, pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		uv2: PackedVector2Array, t0: int, t1: int) -> void:
	var steep: float = skin.get("steep", 0.7)
	var pale: Dictionary = skin.get("pale", {})
	for t in range(t0, t1, 3):
		var c: Color = skin["wall"]
		var n := nrm[t]
		if n.y >= steep:
			c = skin["roof"]
		elif not pale.is_empty() and absf(n.y) < 0.3:
			var mid3 := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
			var mid := Vector2(mid3.x, mid3.z)
			var edges: PackedVector2Array = pale["edges"]
			for e in range(0, edges.size() - 1, 2):
				if Geometry2D.get_closest_point_to_segment(mid, edges[e], edges[e + 1]).distance_to(mid) < float(pale["near"]):
					c = pale["wall"]
					break
		for k in 3:
			col[t + k] = c
			uv2[t + k].x = skin["mode"]


## F's look check (2026-11-03): the triangles of kept LoD2 buildings whose centre stands inside one
## of the landmarks' `lod2_tops` rings ([ring, metres over the ground at `at`, at]) cut at that
## height: the part above it left out, a roof face's part flattened onto it (like the deck cuts
## of `_clip_lod2`, which this mirrors). `runs` comes back with each building's new count.
func _top_lod2(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array, tops: Array, runs := PackedInt32Array()) -> Array:
	var rings: Array[PackedVector2Array] = []
	var boxes: Array[Rect2] = []
	var cuts: Array[float] = []
	for e: Array in tops:
		var ring: PackedVector2Array = e[0]
		var box := Rect2(ring[0], Vector2.ZERO)
		for q in ring:
			box = box.expand(q)
		var at: Vector2 = e[2]
		rings.append(ring)
		boxes.append(box)
		cuts.append(terrain_height(at.x, at.y) + float(e[1]))
	var o_pos := PackedVector3Array()
	var o_nrm := PackedVector3Array()
	var o_col := PackedColorArray()
	var o_uv := PackedVector2Array()
	var o_uv2 := PackedVector2Array()
	var o_runs := PackedInt32Array()
	var ends := PackedInt32Array()
	if runs.is_empty():
		ends.append(pos.size())
	else:
		var e := 0
		for r in runs:
			e += r
			ends.append(e)
	var t := 0
	for end in ends:
		var before := o_pos.size()
		while t < end:
			var mid := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
			var cut := INF
			for i in rings.size():
				if boxes[i].has_point(Vector2(mid.x, mid.z)) and Geometry2D.is_point_in_polygon(Vector2(mid.x, mid.z), rings[i]):
					cut = cuts[i]
					break
			if cut == INF or maxf(pos[t].y, maxf(pos[t + 1].y, pos[t + 2].y)) <= cut:
				for k in 3:
					o_pos.append(pos[t + k])
					o_nrm.append(nrm[t + k])
					o_col.append(col[t + k])
					o_uv.append(uv[t + k])
					o_uv2.append(uv2[t + k])
			else:
				var roof := nrm[t].y >= 0.3
				var below: Array = []
				var above: Array = []
				for k in 3:
					var a := t + k
					var b := t + (k + 1) % 3
					var a_up := pos[a].y > cut
					var b_up := pos[b].y > cut
					(above if a_up else below).append([pos[a], col[a], uv[a]])
					if a_up != b_up:
						var f := (cut - pos[a].y) / (pos[b].y - pos[a].y)
						var corner := [pos[a].lerp(pos[b], f), col[a].lerp(col[b], f), uv[a].lerp(uv[b], f)]
						below.append(corner)
						above.append(corner)
				for pi in (2 if roof else 1):
					var part: Array = below if pi == 0 else above
					var flat := pi == 1
					for k in range(1, part.size() - 1):
						for v: Array in [part[0], part[k], part[k + 1]]:
							var p: Vector3 = v[0]
							o_pos.append(Vector3(p.x, cut, p.z) if flat else p)
							o_nrm.append(Vector3.UP if flat else nrm[t])
							o_col.append(v[1])
							o_uv.append(v[2])
							o_uv2.append(uv2[t])
			t += 3
		o_runs.append(o_pos.size() - before)
	return [o_pos, o_nrm, o_col, o_uv, o_uv2, o_runs if not runs.is_empty() else PackedInt32Array()]


## Like _tri, but with a colour per corner (walls darken towards the ground).
func _tri_shaded(st, a: Vector3, b: Vector3, c: Vector3, n: Vector3,
		ca: Color, cb: Color, cc: Color, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var facing_viewer := (b - a).cross(c - a).dot(n) > 0.0
	var verts := [[a, ca, ua], [b, cb, ub], [c, cc, uc]]
	if facing_viewer == CLOCKWISE_FRONT:
		verts = [verts[0], verts[2], verts[1]]
	for v in verts:
		st.set_color(v[1])
		st.set_normal(n)
		st.set_uv(v[2])
		st.set_uv2(_uv2)
		st.add_vertex(v[0])


func _osm_colour(value, fallback: Color) -> Color:
	var s := str(value).strip_edges().to_lower().replace("grey", "gray")
	if s == "":
		return fallback
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	if c.a == 0.0:
		return fallback
	# Pull mapped colours slightly towards the palette so the city reads as one piece.
	return c.lerp(fallback, 0.3)


## A landmark keeps this spot clear of trees (landmarks.gd tree_free: Powiśle's saucer).
func _tree_blocked(x: float, z: float) -> bool:
	# Not on the railway cutting's floor or at its banks' feet (rail_cut.gd).
	if _cut.box.has_point(Vector2(x, z)):
		var c: Vector3 = _cut.at(x, z, _grid_height(x, z))
		if c.y > 0.5 and c.y < 1.5 or (c.y > 1.5 and c.y < 2.5 and c.z < 2.0):
			return true
	if _marks == null:
		return false
	for c: Array in _marks.tree_free:
		# [centre, radius], or [plan, 0, its box] (Towarowa 22's blocks).
		if c.size() > 2:
			if (c[2] as Rect2).has_point(Vector2(x, z)) and Geometry2D.is_point_in_polygon(Vector2(x, z), c[0]):
				return true
		elif Vector2(x, z).distance_to(c[0]) < float(c[1]):
			return true
	return false


func _build_trees() -> void:
	var list: Array = data.get("trees", [])
	var canopy: Array = CANOPY_AUTUMN if season == "autumn" else CANOPY_SUMMER
	var all_spots: Array[Transform3D] = []
	var broad: Array[Transform3D] = []
	var broad_col: Array[Color] = []
	var needle: Array[Transform3D] = []
	var needle_col: Array[Color] = []
	for i in range(0, list.size() - 3, 4):
		var x := float(list[i])
		var z := float(list[i + 1])
		if _tree_blocked(x, z):
			continue
		var s := float(list[i + 2])
		var h := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
		var t := Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(s, s * (0.9 + h * 0.3), s)), Vector3(x, terrain_height(x, z) - 0.2, z))
		all_spots.append(t)
		if int(list[i + 3]) == 1:
			needle.append(t)
			needle_col.append(Color(NEEDLE[int(h * 100.0) % NEEDLE.size()]))
		else:
			broad.append(t)
			broad_col.append(Color(canopy[int(h * 1000.0) % canopy.size()]))

	# GUGiK trees from the 2023 laser scan: each crown is stretched to the tree's real
	# radius and spans its real crown base to its top; the trunk fills the gap below.
	var real: Array = data.get("trees3d", [])
	# Loop 3b-2: each crown's scale in hundredths (bake_osm.py crown_scales: 75 within 12 m of
	# a road, full size in the parks); its radius and depth shrink, its base stays (it still
	# clears a bus).
	var crowns: Array = data.get("trees3d_crown", [])
	var real_trunks: Array[Transform3D] = []
	for i in range(0, real.size() - 5, 6):
		var x := float(real[i])
		var z := float(real[i + 1])
		if _tree_blocked(x, z):
			continue
		var f := float(crowns[i / 6]) / 100.0 if i / 6 < crowns.size() else 1.0
		var base := minf(float(real[i + 4]), float(real[i + 2]) - 1.5)
		var top := base + (float(real[i + 2]) - base) * f
		var radius := float(real[i + 3]) * f
		var is_needle := int(real[i + 5]) == 1
		var h := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
		var ground := terrain_height(x, z) - 0.2
		# Crown meshes in model space: broadleaf spans y 2.09-6.51 at radius 2.3, conifer 1.6-7.4 at 2.2.
		var low := 1.6 if is_needle else 2.09
		var sy := (top - base) / (5.8 if is_needle else 4.42)
		var sxz := clampf(radius / (2.2 if is_needle else 2.3), 0.45, 7.0)
		var t := Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(sxz, sy, sxz)),
				Vector3(x, ground + base - low * sy, z))
		if is_needle:
			needle.append(t)
			needle_col.append(Color(NEEDLE[int(h * 100.0) % NEEDLE.size()]))
		else:
			broad.append(t)
			broad_col.append(Color(canopy[int(h * 1000.0) % canopy.size()]))
		var trunk_h := base + (top - base) * 0.3
		var girth := clampf(0.55 + top / 28.0, 0.6, 1.7)
		real_trunks.append(Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(girth, trunk_h / 2.8, girth)),
				Vector3(x, ground + trunk_h * 0.5, z)))

	_make_shared()
	var lifted: Array[Transform3D] = []
	for t in all_spots:
		lifted.append(Transform3D(t.basis, t.origin + Vector3(0, 1.4 * t.basis.get_scale().y, 0)))
	lifted.append_array(real_trunks)
	var no_colours: Array[Color] = []
	_tree_multimesh(_shared["trunk"], _shared["trunk_mat"], lifted, no_colours)
	_tree_multimesh(_shared["broadleaf"], leaf_material, broad, broad_col)
	_tree_multimesh(_shared["conifer"], leaf_material, needle, needle_col)


## Loop 3c: the materials and meshes of the trees, lamps, signals, parked cars, props, lamp
## halos and neon signs, made once for the whole city (every sector's MultiMeshes share them;
## tools/bake_city.gd saves them once under map/shared/). The leaves and the parked cars'
## paint are `fade_materials` (the see-through hole round the car).
func _make_shared() -> void:
	if not _shared.is_empty():
		return
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.3
	trunk.height = 2.8
	trunk.radial_segments = 5
	trunk.rings = 1
	_shared["trunk"] = trunk
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("#5e4636")
	_shared["trunk_mat"] = trunk_mat
	leaf_material = ShaderMaterial.new()
	leaf_material.shader = load("res://shaders/foliage.gdshader")
	_shared["broadleaf"] = _broadleaf_mesh()
	_shared["conifer"] = _conifer_mesh()

	var metal := StandardMaterial3D.new()
	metal.vertex_color_use_as_albedo = true
	metal.vertex_color_is_srgb = true
	metal.roughness = 0.7
	_shared["metal"] = metal
	var lamp := SurfaceTool.new()
	lamp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grey := Color("#43474c")
	_box(lamp, Vector3(0, 3.5, 0), Vector3(0.16, 7.0, 0.16), grey)
	_box(lamp, Vector3(0.6, 6.95, 0), Vector3(1.3, 0.1, 0.12), grey)
	_box(lamp, Vector3(1.2, 6.85, 0), Vector3(0.55, 0.16, 0.3), LAMP_HEAD)
	_shared["lamp"] = _mark_head(lamp.commit())
	# The landmarks loop (street furniture): the Royal Route's and the Old Town's cast-iron
	# lantern, a dark green post with a fluted foot, a collar and a four-sided lantern under a
	# cap and finial. The pole stands on the spot; the lantern is LANTERN_HEAD up.
	var lantern := SurfaceTool.new()
	lantern.begin(Mesh.PRIMITIVE_TRIANGLES)
	var iron := Color("#283029")
	_box(lantern, Vector3(0, 0.3, 0), Vector3(0.42, 0.6, 0.42), iron)
	_box(lantern, Vector3(0, 0.66, 0), Vector3(0.3, 0.12, 0.3), iron)
	_box(lantern, Vector3(0, 2.3, 0), Vector3(0.13, 3.2, 0.13), iron)
	_box(lantern, Vector3(0, 3.92, 0), Vector3(0.3, 0.1, 0.3), iron)
	_box(lantern, Vector3(0, 4.0, 0), Vector3(0.24, 0.08, 0.24), iron)
	_box(lantern, LANTERN_HEAD, Vector3(0.44, 0.6, 0.44), LAMP_HEAD)
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		_box(lantern, LANTERN_HEAD + Vector3(c.x * 0.22, 0, c.y * 0.22), Vector3(0.05, 0.62, 0.05), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.34, 0), Vector3(0.58, 0.08, 0.58), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.45, 0), Vector3(0.34, 0.14, 0.34), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.62, 0), Vector3(0.06, 0.22, 0.06), iron)
	_shared["lantern"] = _mark_head(lantern.commit())
	# Plac Konstytucji's candelabras (MDM, 1952): a stone plinth, a tall iron column and three
	# lanterns, two on a crossarm and one on top. The pole stands on the spot.
	var candelabra := SurfaceTool.new()
	candelabra.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(candelabra, Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), Color("#a59b88"))
	_box(candelabra, Vector3(0, 1.1, 0), Vector3(0.6, 0.2, 0.6), iron)
	_box(candelabra, Vector3(0, 4.2, 0), Vector3(0.24, 6.0, 0.24), iron)
	_box(candelabra, Vector3(0, 7.2, 0), Vector3(2.1, 0.14, 0.16), iron)
	for x in [-1.0, 1.0]:
		_box(candelabra, Vector3(x, 7.4, 0), Vector3(0.08, 0.3, 0.08), iron)
	_box(candelabra, Vector3(0, 7.7, 0), Vector3(0.1, 0.9, 0.1), iron)
	for c: Vector3 in [Vector3(-1.0, 7.9, 0), Vector3(1.0, 7.9, 0), CANDELABRA_HEAD]:
		_box(candelabra, c, Vector3(0.5, 0.7, 0.5), LAMP_HEAD)
		_box(candelabra, c + Vector3(0, 0.4, 0), Vector3(0.62, 0.1, 0.62), iron)
		_box(candelabra, c + Vector3(0, 0.55, 0), Vector3(0.08, 0.22, 0.08), iron)
	_shared["candelabra"] = _mark_head(candelabra.commit())
	var fixture := ShaderMaterial.new()
	fixture.shader = load("res://shaders/fixture.gdshader")
	_shared["fixture"] = fixture
	var signal_mesh := SurfaceTool.new()
	signal_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color("#26282b")
	_box(signal_mesh, Vector3(0, 1.8, 0), Vector3(0.14, 3.6, 0.14), dark)
	_box(signal_mesh, Vector3(0, 3.35, 0.2), Vector3(0.34, 1.0, 0.28), dark)
	_box(signal_mesh, Vector3(0, 3.65, 0.35), Vector3(0.16, 0.16, 0.04), Color("#c8432f"))
	_box(signal_mesh, Vector3(0, 3.05, 0.35), Vector3(0.16, 0.16, 0.04), Color("#4f9a52"))
	_shared["signal"] = signal_mesh.commit()
	_shared["parked"] = Models.parked_mesh()
	var car_paint := leaf_material.duplicate() as ShaderMaterial
	car_paint.set_shader_parameter("sway", 0.0)
	_shared["car_paint"] = car_paint
	fade_materials.clear()
	fade_materials.append(leaf_material)
	fade_materials.append(car_paint)

	var halo := ShaderMaterial.new()
	halo.shader = load("res://shaders/glow.gdshader")
	halo.set_shader_parameter("billboard", true)
	halo.set_shader_parameter("radial", true)
	halo.set_shader_parameter("lift", 1.5)
	halo.render_priority = 1
	_shared["halo"] = halo
	_shared["halo_quad"] = halo_quad(4.6)
	var neon := ShaderMaterial.new()
	neon.shader = load("res://shaders/neon.gdshader")
	neon.set_shader_parameter("words", Neon.atlas())
	neon.set_shader_parameter("rows", float(Neon.all_words().size()))
	_shared["neon"] = neon
	_shared["neon_quad"] = Neon.quad()

	var prop_metal := StandardMaterial3D.new()
	prop_metal.vertex_color_use_as_albedo = true
	prop_metal.vertex_color_is_srgb = true
	prop_metal.roughness = 0.75
	_shared["prop_metal"] = prop_metal
	var bench := SurfaceTool.new()
	bench.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color("#8b6a48")
	_box(bench, Vector3(0, 0.45, 0), Vector3(1.7, 0.08, 0.5), wood)
	_box(bench, Vector3(0, 0.78, 0.22), Vector3(1.7, 0.36, 0.07), wood)
	for x in [-0.7, 0.7]:
		_box(bench, Vector3(x, 0.22, 0), Vector3(0.08, 0.44, 0.45), Color("#2e3033"))
	_shared["bench"] = bench.commit()
	# The Chopin bench: black granite, a plain seat and a low back, the steel button on the arm.
	var chopin := SurfaceTool.new()
	chopin.begin(Mesh.PRIMITIVE_TRIANGLES)
	var granite := Color("#26282b")
	_box(chopin, Vector3(0, 0.3, 0), Vector3(1.8, 0.6, 0.5), granite)
	_box(chopin, Vector3(0, 0.8, 0.22), Vector3(1.8, 0.4, 0.1), granite)
	_box(chopin, Vector3(0.82, 0.64, -0.1), Vector3(0.14, 0.04, 0.14), Color("#c4c8cc"))
	_shared["bench_chopin"] = chopin.commit()
	var bin := SurfaceTool.new()
	bin.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(bin, Vector3(0, 0.45, 0), Vector3(0.45, 0.9, 0.45), Color("#3e5a44"))
	_box(bin, Vector3(0, 0.92, 0), Vector3(0.5, 0.06, 0.5), Color("#2c2e30"))
	_shared["bin"] = bin.commit()
	var rack := SurfaceTool.new()
	rack.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-0.9, -0.3, 0.3, 0.9]:
		_box(rack, Vector3(0, 0.45, z), Vector3(0.7, 0.07, 0.07), Color("#8c9096"))
		for x in [-0.33, 0.33]:
			_box(rack, Vector3(x, 0.22, z), Vector3(0.06, 0.45, 0.06), Color("#8c9096"))
	_shared["rack"] = rack.commit()
	# Advertising column: green foot and cap, a poster band tinted per column.
	var column := SurfaceTool.new()
	column.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := Color("#2f5a46")
	_cylinder(column, Vector3.ZERO, 0.66, 0.5, 10, green)
	_cylinder(column, Vector3(0, 0.5, 0), 0.6, 2.4, 10, Color.WHITE)
	_cylinder(column, Vector3(0, 2.9, 0), 0.7, 0.18, 10, green)
	_cylinder(column, Vector3(0, 3.08, 0), 0.45, 0.35, 8, green)
	_cylinder(column, Vector3(0, 3.43, 0), 0.12, 0.3, 6, Color("#c9a24a"))
	_shared["column"] = column.commit()
	# Bus and tram shelter. The landmarks loop (2026-10-30): Warsaw's glass shelter, as seen
	# from the game's camera: a pale glass roof in a graphite frame overhanging the kerb, a
	# dark fascia, glass back and end, three posts, a bench, a lit poster box at the far end
	# (its faces glow at night: SHELTER_POSTER, fixture.gdshader) and the stop's blue sign
	# (D-15) on its own pole. The road is on its -z side.
	var shelter := SurfaceTool.new()
	shelter.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := Color("#b8d3df")
	var graphite := Color("#33363b")
	# The Rondo photos (2026-10-31): Warsaw's shelter has a red frame: the roof's edge, the
	# posts and a red loop round the glass end, with an ad panel in a black case.
	var red := Color("#c8282a")
	_box(shelter, Vector3(0, 2.5, 0.08), Vector3(4.3, 0.12, 1.95), graphite)
	_box(shelter, Vector3(0, 2.57, 0.08), Vector3(4.0, 0.03, 1.7), Color("#a7c2cf"))
	_box(shelter, Vector3(0, 2.38, -0.86), Vector3(4.3, 0.3, 0.06), red)
	_box(shelter, Vector3(0, 1.3, 0.75), Vector3(3.85, 2.05, 0.04), glass)
	_box(shelter, Vector3(0, 0.12, 0.75), Vector3(3.9, 0.1, 0.06), graphite)
	_box(shelter, Vector3(-1.95, 1.3, 0.17), Vector3(0.04, 2.05, 1.15), glass)
	for x in [-1.95, 0.0, 1.95]:
		_box(shelter, Vector3(x, 1.25, 0.78), Vector3(0.09, 2.5, 0.09), red)
	# The red loop round the glass end: a post at each corner and a bar along the foot.
	_box(shelter, Vector3(-1.95, 0.05, 0.17), Vector3(0.06, 0.06, 1.2), red)
	_box(shelter, Vector3(-1.95, 2.4, -0.4), Vector3(0.06, 0.2, 0.06), red)
	# The poster box: a graphite case, a poster on each face.
	_box(shelter, Vector3(1.95, 1.2, 0.12), Vector3(0.2, 1.95, 1.3), graphite)
	for sx in [-0.11, 0.11]:
		_box(shelter, Vector3(1.95 + sx, 1.5, 0.12), Vector3(0.02, 1.0, 1.12), SHELTER_POSTER[0])
		_box(shelter, Vector3(1.95 + sx, 0.78, 0.12), Vector3(0.02, 0.44, 1.12), SHELTER_POSTER[1])
	_box(shelter, Vector3(-0.2, 0.46, 0.5), Vector3(2.2, 0.06, 0.38), Color("#5c6168"))
	for x in [-1.1, 0.7]:
		_box(shelter, Vector3(x, 0.22, 0.5), Vector3(0.06, 0.44, 0.3), graphite)
	# The stop's sign: a grey pole, a blue square with a white bus.
	_box(shelter, Vector3(-2.45, 1.35, -0.7), Vector3(0.07, 2.7, 0.07), Color("#9aa0a6"))
	_box(shelter, Vector3(-2.45, 2.45, -0.7), Vector3(0.56, 0.56, 0.05), Color("#1f5fae"))
	for sz in [-0.03, 0.03]:
		_box(shelter, Vector3(-2.45, 2.47, -0.7 + sz), Vector3(0.34, 0.2, 0.02), Color("#f2f2ee"))
		_box(shelter, Vector3(-2.45, 2.34, -0.7 + sz), Vector3(0.3, 0.05, 0.02), Color("#f2f2ee"))
	# The Rondo photos' ad panel: a big lit panel in a black case on the glass end, a poster
	# (orange over cream, SHELTER_POSTER) on both faces, glowing at night.
	_box(shelter, Vector3(-2.3, 1.3, 0.3), Vector3(0.12, 1.95, 1.2), Color("#141518"))
	for sx: float in [-0.075, 0.075]:
		_box(shelter, Vector3(-2.3 + sx, 1.5, 0.3), Vector3(0.02, 1.4, 1.02), SHELTER_POSTER[0])
		_box(shelter, Vector3(-2.3 + sx, 0.72, 0.3), Vector3(0.02, 0.2, 1.02), SHELTER_POSTER[1])
	_shared["shelter"] = _mark_glow(shelter.commit(), SHELTER_POSTER)


func _tree_multimesh(mesh: Mesh, material: Material, spots: Array[Transform3D], colours: Array[Color],
		custom: Array[Color] = [], parent: Node = null) -> Array[MultiMeshInstance3D]:
	var made: Array[MultiMeshInstance3D] = []
	# One MultiMesh per tile, so off-screen tiles are skipped.
	var tiles := {}
	for i in spots.size():
		var o := spots[i].origin
		var key := Vector2i(floori(o.x / INSTANCE_TILE), floori(o.z / INSTANCE_TILE))
		if not tiles.has(key):
			tiles[key] = []
		(tiles[key] as Array).append(i)
	for key: Vector2i in tiles:
		if _in_sector and key != _sector:
			continue  # loop 3c: another sector's tile
		var members: Array = tiles[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = not colours.is_empty()
		mm.use_custom_data = not custom.is_empty()
		mm.mesh = mesh
		mm.instance_count = members.size()
		var box := AABB(spots[members[0]].origin, Vector3.ZERO)
		for k in members.size():
			var i: int = members[k]
			mm.set_instance_transform(k, spots[i])
			box = box.expand(spots[i].origin)
			if mm.use_colors:
				mm.set_instance_color(k, colours[i])
			if mm.use_custom_data:
				mm.set_instance_custom_data(k, custom[i])
		# Saved MultiMeshes don't recompute their bounds on load (the prebuilt city
		# would cull every tile), so store them explicitly.
		mm.custom_aabb = box.grow(12.0)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = material
		(parent if parent != null else _out).add_child(mmi)
		made.append(mmi)
	return made


## A faceted crown: an icosahedron, stretched a little, flat-shaded.
func _broadleaf_mesh() -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
			[11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
			[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var centre := Vector3(0, 4.3, 0)
	var stretch := Vector3(2.4, 2.6, 2.4) / Vector3(1, t, 1).length()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = centre + v[f[0]] * stretch
		var b: Vector3 = centre + v[f[1]] * stretch
		var c: Vector3 = centre + v[f[2]] * stretch
		var n := (b - a).cross(c - a).normalized()
		if n.dot((a + b + c) / 3.0 - centre) < 0.0:
			n = -n
		_tri(st, a, b, c, n, Color.WHITE)
	return st.commit()


## A conifer: three stacked six-sided cones, flat-shaded.
func _conifer_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tier in [[1.6, 2.2, 4.4], [3.4, 1.7, 6.0], [5.0, 1.1, 7.4]]:
		var base_y: float = tier[0]
		var radius: float = tier[1]
		var apex := Vector3(0, tier[2], 0)
		for i in 6:
			var a := Vector3(cos(TAU * i / 6.0) * radius, base_y, sin(TAU * i / 6.0) * radius)
			var b := Vector3(cos(TAU * (i + 1) / 6.0) * radius, base_y, sin(TAU * (i + 1) / 6.0) * radius)
			var n := (b - a).cross(apex - a).normalized()
			if n.dot((a + b) * 0.5 - Vector3(0, base_y, 0)) < 0.0:
				n = -n
			_tri(st, a, b, apex, n, Color.WHITE)
	return st.commit()


## The parked cars' paints, picked by the bake's index (loop 2c: models.gd, the red one slate).
const CAR_PAINT := Models.PARKED_PAINT


func _box(st, centre: Vector3, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := centre + n * h[axis]
			_quad(st, c - u - v, c + u - v, c + u + v, c - u + v, n, col)


func _build_street_furniture() -> void:
	_make_shared()
	var metal: Material = _shared["metal"]
	var spots: Array[Transform3D] = []
	var glows: Array[Color] = []
	var lanterns: Array[Transform3D] = []
	var lantern_glows: Array[Color] = []
	var royal := _royal_segments()
	var candelabras: Array[Transform3D] = []
	var candelabra_glows: Array[Color] = []
	var list: Array = data.get("lamps", [])
	for i in range(0, list.size() - 1, 2):
		var x := float(list[i])
		var z := float(list[i + 1])
		if FirstScene.on_pasaz(Vector2(x, z)):
			continue  # first_scene.gd's Y mast stands here
		var t := Transform3D(Basis(Vector3.UP, fposmod(x * 0.37 + z * 0.11, TAU)), Vector3(x, terrain_height(x, z), z))
		if Vector2(x, z).distance_to(Vector2(CANDELABRAS.x, CANDELABRAS.y)) < CANDELABRAS.z:
			candelabras.append(t)
			candelabra_glows.append(SODIUM_GLOW)
			continue
		if _on_royal_route(x, z, royal):
			lanterns.append(t)
			lantern_glows.append(SODIUM_GLOW if _sodium_at(x, z) else LED_GLOW)
			continue
		spots.append(t)
		var head := t * Vector3(1.2, 0.0, 0.0)
		glows.append(SODIUM_GLOW if _sodium_at(head.x, head.z) else LED_GLOW)
	# The bake's own lamps (bridges; map round 2: the streets' unlit stretches too): on the deck or
	# the kerb, arm over the carriageway, sodium or LED as the light map has them at the head.
	for i in range(0, _extra_lamps.size() - 2, 3):
		var x := _extra_lamps[i]
		var z := _extra_lamps[i + 1]
		var t := Transform3D(Basis(Vector3.UP, _extra_lamps[i + 2]), Vector3(x, ground_height(x, z), z))
		spots.append(t)
		var head := t * Vector3(1.2, 0.0, 0.0)
		glows.append(SODIUM_GLOW if _sodium_at(head.x, head.z) else LED_GLOW)
	var none: Array[Color] = []
	for mmi in _tree_multimesh(_shared["lamp"], _shared["fixture"], spots, none, glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	for mmi in _tree_multimesh(_shared["lantern"], _shared["fixture"], lanterns, none, lantern_glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	for mmi in _tree_multimesh(_shared["candelabra"], _shared["fixture"], candelabras, none, candelabra_glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	var heads: Array[Transform3D] = []
	for t in spots:
		heads.append(Transform3D(Basis(), t * Vector3(1.2, 6.78, 0.0)))
	for t in lanterns:
		heads.append(Transform3D(Basis(), t * LANTERN_HEAD))
	for t in candelabras:
		heads.append(Transform3D(Basis(), t * Vector3(0, 7.9, 0)))
	glows.append_array(lantern_glows)
	glows.append_array(candelabra_glows)
	_build_lamp_halos(heads, glows)

	spots = []
	list = data.get("signals", [])
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	for mmi in _tree_multimesh(_shared["signal"], metal, spots, none):
		mmi.add_to_group(SMALL_CASTERS, true)

	# Parked cars: white body and dark glass, tinted per car by the instance colour (loop 2c:
	# the shape is models.gd's parked_mesh(), a small saloon like the traffic's).
	spots = []
	var paints: Array[Color] = []
	list = data.get("parked", [])
	for i in range(0, list.size() - 3, 4):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
		paints.append(Color(CAR_PAINT[int(list[i + 3]) % CAR_PAINT.size()]))
	for mmi in _tree_multimesh(_shared["parked"], _shared["car_paint"], spots, paints):
		mmi.add_to_group(SMALL_CASTERS, true)
	# Parked cars are obstacles too.
	var footprint := [Vector3(-0.9, 0, -2.1), Vector3(0.9, 0, -2.1), Vector3(0.9, 0, 2.1), Vector3(-0.9, 0, 2.1)]
	for t in spots:
		for k in 4:
			var a: Vector3 = t * footprint[k]
			var b: Vector3 = t * footprint[(k + 1) % 4]
			var up := Vector3(0, 1.5, 0)
			_wall_faces.append_array([a, b, b + up, a, b + up, a + up])


## Street-lamp heads, and the light they give off at night (linear; alpha = halo brightness).
const LAMP_HEAD := Color("#d9d4c3")
## The landmarks loop: the shelter's poster box faces (an orange poster over a cream band),
## lit at night in SHELTER_GLOW through the street lamps' fixture.gdshader.
const SHELTER_POSTER := [Color("#e8603f"), Color("#f1e7cf")]
const SHELTER_GLOW := Color(0.62, 0.66, 0.72)
const SODIUM_GLOW := Color(1.0, 0.45, 0.12, 0.6)
const LED_GLOW := Color(0.72, 0.82, 1.0, 0.5)


## The landmarks loop (street furniture): the historic lantern's glass centre above its spot.
const LANTERN_HEAD := Vector3(0, 4.38, 0)
## Streets whose lamps are the historic lanterns (the Royal Route and round the Old Town),
## within ROYAL_REACH metres of the carriageway's edge; and the Old Town itself, a circle.
const ROYAL_STREETS := ["Krakowskie Przedmieście", "Nowy Świat", "Senatorska", "Miodowa", "Podwale",
		"Kozia", "Brzozowa"]
const ROYAL_REACH := 8.0
const OLD_TOWN := Vector3(-760.0, -1680.0, 190.0)
## Plac Konstytucji (x, z, radius): its lamps are MDM's candelabras, three lanterns each.
const CANDELABRAS := Vector3(-533.8, 1282.4, 75.0)
const CANDELABRA_HEAD := Vector3(0, 8.5, 0)

## The landmarks loop (Old Town): the historic districts (x, z, radius), the Old Town and the
## New Town, where GUGiK models a whole block of tenements as one building (Rynek's sides are
## 49 and 84 OpenStreetMap houses in one model), so it stood in one colour like a modern block.
const HISTORIC := [Vector3(-760.0, -1680.0, 200.0), Vector3(-830.0, -1920.0, 170.0), Vector3(-724.2, -1465.4, 105.0)]
## Plac Zamkowy's houses (F, 2026-11-01): OpenStreetMap's colours there are muddy (olive,
## mustard, brown), so within PLAC_PALETTE_R of the column a house takes one of these pastels
## (the rebuilt Old Town's cream, apricot, rose, sage, powder blue, sand), a quarter of the
## mapped colour left in for variety.
const PLAC_PALETTE_R := 110.0
const PLAC_PASTELS := ["#ecd9a4", "#e9bda8", "#e3b5b0", "#c6d3b3", "#bfd2e0", "#efe4cf", "#e6cba0", "#d9c6d6"]
## Mariensztat (the Mariensztat review, 2026-11-01): the 1948-49 estate under the escarpment
## (Rynek Mariensztacki, Mariensztat, Sowia, Garbarska, Furmańska and lower Bednarska), small
## pastel houses under steep red tile roofs with dormers, so it takes the Old Town's dress too.
## A polygon, not a circle: its edges run along the streets and the party walls (Kamienica
## Wernera's west wall, the corner of the L block at Bednarska 21-23), so no house is cut in two
## (each of its 47 OpenStreetMap houses is wholly in or out).
const MARIENSZTAT := [Vector2(-546.7, -1395.0), Vector2(-333.3, -1395.0), Vector2(-283.3, -1300.0),
		Vector2(-246.7, -1236.7), Vector2(-270.0, -1223.3), Vector2(-306.7, -1260.0), Vector2(-350.0, -1233.3),
		Vector2(-403.3, -1233.3), Vector2(-403.3, -1205.0), Vector2(-506.8, -1195.9), Vector2(-509.8, -1210.3),
		Vector2(-534.3, -1213.4), Vector2(-544.0, -1236.5), Vector2(-546.7, -1286.7)]
## Nowy Świat (the street-by-street pass 2, 2026-11-02): the street's houses were rebuilt after
## 1945 in a classicist dress and stand in plaster of their own, house by house (ivory, butter,
## ochre, salmon, grey-green, powder blue, sand), not in the one grey the aerial photo gives. Within
## NOWY_REACH metres of the street's centre line (south of NOWY_END_Z, Al. Jerozolimskie) a house
## takes one of these, a quarter of the mapped colour left in. Walls only: no tiles, dormers or
## gables (the roofs stay the flat and hipped roofs the aerial photo shows). A *guess* from
## memory of the street until the Mac photo check (QUESTIONS).
const NOWY_PASTELS := ["#efe3c8", "#e8d49a", "#dcc08a", "#e4b5a2", "#e8c3c0", "#c3cfb4", "#b9cbd8", "#e6d8bd",
		"#d8c7a4", "#cdbfd0"]
const NOWY_REACH := 30.0
const NOWY_END_Z := 262.0
const NOWY_STREET := "Nowy Świat"
## Dobra and Tamka (Powiśle street by street, 2026-11-02): the pre-war tenements along the two
## streets stand in plasters of their own, house by house (sooty cream, ochre, faded rose, sage,
## grey, sand), not in the aerial photo's one grey, with a cornice, a string course and shop
## fronts (TenementTrim). Within POWISLE_REACH metres of a street's centre line, tenements only
## (R4 type 1: slabs, offices and the landmarks keep their own look). A *guess* from memory of the
## streets until the Mac photo check (QUESTIONS).
const POWISLE_STREETS := ["Dobra", "Tamka"]
const POWISLE_REACH := 24.0
const POWISLE_SHOP_REACH := 15.0
const POWISLE_PASTELS := ["#d6cbb2", "#cdb996", "#dcc7a0", "#c9b0a0", "#b9c0aa", "#d3c0bb", "#c8ccd0", "#e0d3ab",
		"#bda78d", "#d8bb9e"]

## Their tenements' own colours where OpenStreetMap has none (ochre, salmon, cream, terracotta,
## pale yellow, sage, blue-grey, peach, oxblood): the rebuilt Old Town's palette.
const TENEMENTS := ["#d9a441", "#e1968f", "#ebe1d1", "#c8733f", "#efd9a0", "#a9b98a", "#9fb6cf",
		"#f0c1ab", "#9c4a43", "#e8c07a", "#cf8c59", "#dcc9a3"]
## Their pitched roofs' tiles, half mixed into the aerial photo's colour (which reads pale pink).
const TILES := ["#9c4a35", "#a85a3e", "#8a4434", "#b0603f", "#94503c", "#7a3b30", "#c0714a", "#b2663a",
		"#84483a", "#a4503a", "#5f6168", "#6b6d73", "#8c9299", "#6e8f80"]
## G7: how often each tile appears (same order): terracotta ones common, slate and zinc grey and
## the odd green copper rare.
const TILE_WEIGHTS := [10, 10, 8, 8, 8, 5, 5, 5, 5, 5, 3, 2, 2, 1]
## Kinds whose walls keep their own colour there (the churches: a skin or brick of their own).
const NOT_TENEMENTS := ["church", "cathedral", "chapel", "monastery", "convent", "religious"]


## R4 of docs/design/start-area-real.md (2026-11-01): an ordinary building's type for the facade
## shader (building.gdshader typed_facade), from its OpenStreetMap kind, footprint and height:
## 1 a pre-war tenement (kamienica: 10-26 m, the city's usual block), 2 a 1960s-80s large-panel
## slab or point block (26 m and up, or a long thin bar 14 m and up), 3 a post-war office with
## ribbon windows (offices, shops, hotels, ministries 12 m and up), 0 untyped (the seed's look:
## sheds, schools, low houses and the rest).
const TYPED_HOMES := ["yes", "apartments", "residential", "house", "retail"]
const TYPED_OFFICES := ["office", "commercial", "government", "hotel"]
static func _building_type(kind: String, poly: PackedVector2Array, h: float) -> int:
	if h < 8.0:
		return 0
	if TYPED_OFFICES.has(kind):
		return 3 if h >= 12.0 else 0
	if not TYPED_HOMES.has(kind):
		return 0
	if h >= 26.0:
		return 2
	if h < 10.0:
		return 0
	# The footprint's least-area box along one of its own edges: a long thin bar is a slab.
	var best := Vector2(INF, INF)
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() < 2.0:
			continue
		var d := e.normalized()
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q in poly:
			var r := Vector2(q.dot(d), q.dot(Vector2(-d.y, d.x)))
			lo = lo.min(r)
			hi = hi.max(r)
		var size := hi - lo
		if size.x * size.y < best.x * best.y:
			best = size
	var long := maxf(best.x, best.y)
	var short := minf(best.x, best.y)
	if long >= 45.0 and short <= 16.0 and h >= 14.0:
		return 2
	return 1


## Aleja Jana Pawła II's frontage (F, 2026-11-01): the street was laid out after the war and
## rebuilt in the 1950s-70s, so its buildings are not the Old Town's pastel tenements nor the
## default palette: mid-century plasters (cream, grey, ochre, sage, salmon, blue-grey, brown),
## each building its own (a landmark's skin keeps its own: only plain LoD2 buildings are dressed).
const BOULEVARD_NAME := "Aleja Jana Pawła II"
const BOULEVARD_REACH := 42.0
const BOULEVARD_PLASTERS := ["#d8cfb8", "#c9c5b8", "#d4b896", "#bfc7b4", "#d6b8a6", "#c4c9cf", "#e2dccb", "#b9a99a"]


## The boulevard's centreline sampled every ~12 m into a grid of 48 m cells (point lists).
func _boulevard_grid() -> Dictionary:
	var grid := {}
	for road in data.get("roads", []):
		if str(road.get("name", "")) != BOULEVARD_NAME:
			continue
		var line := _pts(road["p"])
		for i in range(line.size() - 1):
			var a := line[i]
			var b := line[i + 1]
			var n := maxi(1, ceili(a.distance_to(b) / 12.0))
			for k in n + 1:
				var q := a.lerp(b, float(k) / n)
				var key := Vector2i(floori(q.x / 48.0), floori(q.y / 48.0))
				if not grid.has(key):
					grid[key] = PackedVector2Array()
				(grid[key] as PackedVector2Array).append(q)
	return grid


func _near_boulevard(grid: Dictionary, at: Vector2) -> bool:
	var cx := floori(at.x / 48.0)
	var cz := floori(at.y / 48.0)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q: Vector2 in grid.get(Vector2i(cx + dx, cz + dz), PackedVector2Array()):
				if q.distance_to(at) <= BOULEVARD_REACH:
					return true
	return false


## Each building run (one building) within BOULEVARD_REACH of the boulevard takes a plaster by
## its position's hash; walls only (roofs and glass towers keep theirs). Returns the colours.
func _boulevard_dress(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		runs: Array[Vector3i]) -> PackedColorArray:
	var grid := _boulevard_grid()
	if grid.is_empty():
		return col
	for run in runs:
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for t in range(run.x, run.y):
			lo = lo.min(pos[t])
			hi = hi.max(pos[t])
		var mid := Vector2((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5)
		if hi.y - lo.y < 12.0 or _historic(mid, 0.0) or not _near_boulevard(grid, mid):
			continue
		var plaster := Color(BOULEVARD_PLASTERS[absi(int(mid.x * 73.0 + mid.y * 31.0)) % BOULEVARD_PLASTERS.size()])
		for t in range(run.x, run.y):
			if nrm[t].y < 0.7 and col[t].a >= 0.9:
				col[t] = Color(plaster.r, plaster.g, plaster.b, col[t].a)
	return col


## A wall's UV2.x for type `kind` (1-3) and seed 0..1: [1, 2) in quarters; 0 keeps the seed.
static func typed_seed(kind: int, seed: float) -> float:
	if kind <= 0:
		return seed
	return 1.0 + 0.25 * float(kind - 1) + 0.24 * clampf(seed, 0.0, 0.999)


## R4 for the LoD2 buildings: each run (one building) takes the type of the OpenStreetMap house
## under its middle, its height from its own triangles. Glass walls, landmarks' skins and the
## historic districts (_tenement_facades) keep theirs. Load time only, both city paths.
func _typed_lod2(pos: PackedVector3Array, col: PackedColorArray, uv2: PackedVector2Array,
		runs: Array[Vector3i]) -> PackedVector2Array:
	var cell := 48.0
	var grid := {}
	var polys: Array[PackedVector2Array] = []
	var kinds: Array[String] = []
	for bld in data.get("buildings", []):
		var p: Array = bld["p"]
		if p.size() < 6 or not (TYPED_HOMES.has(str(bld["kind"])) or TYPED_OFFICES.has(str(bld["kind"]))):
			continue
		var poly := _pts(p)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		var k := polys.size()
		polys.append(poly)
		kinds.append(str(bld["kind"]))
		for gx in range(floori(box.position.x / cell), floori(box.end.x / cell) + 1):
			for gz in range(floori(box.position.y / cell), floori(box.end.y / cell) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(k)
	for run in runs:
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for t in range(run.x, run.y):
			lo = lo.min(pos[t])
			hi = hi.max(pos[t])
		var mid := Vector2((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5)
		if _historic(mid, 0.0):
			continue
		var found := -1
		for k in grid.get(Vector2i(floori(mid.x / cell), floori(mid.y / cell)), []):
			if Geometry2D.is_point_in_polygon(mid, polys[k]):
				found = k
				break
		if found < 0:
			continue
		var kind := _building_type(kinds[found], polys[found], hi.y - lo.y)
		if kind == 0:
			continue
		for t in range(run.x, run.y):
			if uv2[t].x < 1.0 and col[t].a >= 0.9:
				uv2[t].x = typed_seed(kind, uv2[t].x)
	return uv2


## The roofs lane (docs/design/roofs.md, RF2-RF3): each kept LoD2 building's parapets,
## tenement chimneys (RoofDress) into `dress`, the walls' own tile meshes.
## Its R4 type from the UV2 _typed_lod2 gave its walls. Load time only, both city paths.
func _roof_dress(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		uv: PackedVector2Array, uv2: PackedVector2Array, runs: Array[Vector3i], dress: Dictionary) -> void:
	var before := RoofDress.triangles
	for run in runs:
		var kind := 0
		var lo := Vector2(INF, INF)
		var hi := -lo
		for t in range(run.x, run.y, 3):
			lo = lo.min(Vector2(pos[t].x, pos[t].z))
			hi = hi.max(Vector2(pos[t].x, pos[t].z))
			if kind == 0 and uv2[t].x >= 1.0 and uv2[t].x < 2.0:
				kind = int((uv2[t].x - 1.0) * 4.0) + 1
		var extra := RoofDress.building(pos, nrm, col, uv, run.x, run.y, kind, _historic((lo + hi) * 0.5, 0.0))
		if not (extra["pos"] as PackedVector3Array).is_empty():
			_add_dress(dress, extra)
	if not _in_sector:
		print("roofs: %d parapet edges, %d chimneys, %d triangles (RF2-RF3)" % [RoofDress.parapets,
				RoofDress.chimneys, RoofDress.triangles - before])


## The historic districts: each LoD2 wall in them takes the colour and window seed of the
## OpenStreetMap house it stands on (its centre a metre inside the wall), so a block reads as
## a row of tenements, each its own colour and window rhythm, under a tiled roof. Load time only, both city paths
## (the house's own data, never which sector it came in). Returns [colours, UV2s] (packed
## arrays are copies).
func _tenement_facades(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		uv2: PackedVector2Array, dropped: PackedByteArray) -> Array:
	var dress := {"pos": PackedVector3Array(), "nrm": PackedVector3Array(), "col": PackedColorArray()}
	var cell := 24.0
	var grid := {}
	var polys: Array[PackedVector2Array] = []
	var looks: Array[Color] = []
	var seeds: Array[float] = []
	var roofs: Array[Color] = []
	var plain: Array[bool] = []  # Nowy Świat's and Dobra and Tamka's houses: the plaster only
	var trim: Array[bool] = []  # Dobra and Tamka's: the cornice and shop fronts too
	for bld in data.get("buildings", []):
		var p: Array = bld["p"]
		if p.size() < 6 or NOT_TENEMENTS.has(str(bld.get("kind", ""))):
			continue
		var poly := _pts(p)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		var nowy := _nowy_swiat(box.get_center())
		var powisle := not nowy and _powisle_house(bld, poly, box.get_center())
		if not nowy and not powisle and not _historic(box.get_center(), 40.0):
			continue
		var hsh := absi(int(poly[0].x * 73.0 + poly[0].y * 31.0))
		var k := polys.size()
		polys.append(poly)
		plain.append(nowy or powisle)
		trim.append(powisle)
		var look := _osm_colour(bld["c"], Color(TENEMENTS[hsh % TENEMENTS.size()]))
		if nowy:
			look = Color(NOWY_PASTELS[(hsh / 7) % NOWY_PASTELS.size()]).lerp(look, 0.25)
		elif powisle:
			look = Color(POWISLE_PASTELS[(hsh / 7) % POWISLE_PASTELS.size()]).lerp(look, 0.25)
		if box.get_center().distance_to(OldTownRoofs.PLAC) < PLAC_PALETTE_R:
			look = Color(PLAC_PASTELS[hsh % PLAC_PASTELS.size()]).lerp(look, 0.25)
		looks.append(look)
		seeds.append(fposmod(hsh * 0.6180339887, 1.0))
		roofs.append(_tile_colour(hsh))
		for gx in range(floori(box.position.x / cell), floori(box.end.x / cell) + 1):
			for gz in range(floori(box.position.y / cell), floori(box.end.y / cell) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(k)
	if polys.is_empty():
		return [col, uv2, dress]
	var covered := _gable_ends(pos, nrm)
	for t in range(0, pos.size(), 3):
		if dropped[t / 3] or uv2[t].x >= 1.0 or col[t].a < 0.9 or nrm[t].y > 0.95 or nrm[t].y < -0.3:
			continue  # a landmark's, glass, a flat roof or an underside
		var pitched := nrm[t].y >= 0.3
		var c := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
		# A wall's house is a metre behind it; a roof slope's is under its centre.
		var probe := Vector2(c.x, c.z) if pitched else Vector2(c.x, c.z) - Vector2(nrm[t].x, nrm[t].z).normalized()
		var cands: Array = grid.get(Vector2i(floori(probe.x / cell), floori(probe.y / cell)), [])
		if cands.is_empty():
			continue
		var in_old := _historic(probe, 0.0)
		for k in cands:
			if (in_old or plain[k]) and Geometry2D.is_point_in_polygon(probe, polys[k]):
				if plain[k]:
					if not pitched:
						for v in 3:
							col[t + v] = looks[k]
							uv2[t + v].x = seeds[k]
						if trim[k] and absf(nrm[t].y) < 0.05:
							_powisle_trim(pos, nrm, t, looks[k], dress)
					break
				for v in 3:
					if pitched:
						col[t + v] = col[t + v].lerp(roofs[k], 0.5)
					else:
						col[t + v] = looks[k]
						uv2[t + v].x = seeds[k]
				if pitched:
					# Old Town roof detail (OldTownRoofs): a dormer, now and then a chimney. The
					# seed from the slope's place, not its index (a sector's batch numbers its
					# triangles differently from the whole map's: check_streaming's identity).
					var extra := OldTownRoofs.dress(pos[t], pos[t + 1], pos[t + 2], nrm[t], looks[k], roofs[k],
							fposmod(seeds[k] + pos[t].x * 0.0731 + pos[t].z * 0.0417, 1.0))
					if not extra.is_empty():
						_add_dress(dress, extra)
				else:
					_square_gables(pos, nrm, t, polys, grid, cell, looks, seeds, covered, dress)
				break
	return [col, uv2, dress]


## G7: a house's roof colour from its hash: a weighted pick from TILES, then a lightness shift of
## up to +-9 per cent so neighbours of one tile still differ.
func _tile_colour(hsh: int) -> Color:
	var total := 0
	for w: int in TILE_WEIGHTS:
		total += w
	var pick := (hsh * 7) % total
	var i := 0
	while pick >= TILE_WEIGHTS[i]:
		pick -= TILE_WEIGHTS[i]
		i += 1
	var shade := (float((hsh / 11) % 100) / 99.0 - 0.5) * 0.18
	var col := Color(TILES[i])
	return col.lightened(shade) if shade > 0.0 else col.darkened(-shade)


## Appends `extra` ("pos", "nrm", "col") to `dress`. Packed arrays are copies when read out of
## a Dictionary, so they are written back.
func _add_dress(dress: Dictionary, extra: Dictionary) -> void:
	for key: String in ["pos", "nrm", "col"]:
		var merged = dress[key]
		merged.append_array(extra[key])
		dress[key] = merged


## The key of a horizontal edge (both ends at one height), ends in either order.
func _edge_key(p: Vector3, q: Vector3) -> String:
	var a := "%d,%d,%d" % [roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0)]
	var b := "%d,%d,%d" % [roundi(q.x * 10.0), roundi(q.y * 10.0), roundi(q.z * 10.0)]
	return a + ">" + b if a < b else b + ">" + a


## The horizontal wall edges round the Old Town square that have a triangle ABOVE them (a real
## LoD2 gable end or a taller storey): those take no stepped gable. Returns {key: true}.
func _gable_ends(pos: PackedVector3Array, nrm: PackedVector3Array) -> Dictionary:
	var covered := {}
	for t in range(0, pos.size(), 3):
		if absf(nrm[t].y) > 0.3 or not _near_square(Vector2(pos[t].x, pos[t].z)):
			continue
		for i in 3:
			var p := pos[t + i]
			var q := pos[t + (i + 1) % 3]
			var o := pos[t + (i + 2) % 3]
			if absf(p.y - q.y) < 0.02 and o.y > p.y + 0.3:
				covered[_edge_key(p, q)] = true
	return covered


func _near_square(at: Vector2) -> bool:
	var d := at.distance_to(OldTownRoofs.RYNEK)
	if d > OldTownRoofs.GABLE_NEAR and d < OldTownRoofs.GABLE_FAR:
		return true
	var p := at.distance_to(OldTownRoofs.PLAC)
	return p > OldTownRoofs.PLAC_NEAR and p < OldTownRoofs.PLAC_FAR


## Stepped gables (OldTownRoofs.gable) on the top edge of a wall triangle `t` of a house round
## the Old Town market square's east side, facing the square: one per house-width bay. Their
## triangles join `dress` (the walls' own tile meshes, so no draw call is added).
func _square_gables(pos: PackedVector3Array, nrm: PackedVector3Array, t: int, polys: Array[PackedVector2Array],
		grid: Dictionary, cell: float, looks: Array[Color], seeds: Array[float], covered: Dictionary,
		dress: Dictionary) -> void:
	var n := Vector3(nrm[t].x, 0.0, nrm[t].z)
	if n.length() < 0.9:
		return  # a sloped wall: not a plain front
	n = n.normalized()
	for i in 3:
		var p := pos[t + i]
		var q := pos[t + (i + 1) % 3]
		var o := pos[t + (i + 2) % 3]
		if absf(p.y - q.y) > 0.02 or o.y > p.y - 0.5:
			continue  # not a top edge
		var mid := (p + q) * 0.5
		var at := Vector2(mid.x, mid.z)
		if covered.has(_edge_key(p, q)) or not _near_square(at):
			continue
		# Rynek: the east side only (right of the square's centre), the front turned towards it.
		# Plac Zamkowy: every front turned towards the column, in a mix of gable kinds.
		var on_plac := at.distance_to(OldTownRoofs.PLAC) < OldTownRoofs.PLAC_FAR
		var centre := OldTownRoofs.PLAC if on_plac else OldTownRoofs.RYNEK
		if not on_plac and at.x < OldTownRoofs.RYNEK.x + 8.0:
			continue
		if n.dot(Vector3(centre.x - mid.x, 0.0, centre.y - mid.z).normalized()) < 0.6:
			continue
		var length := p.distance_to(q)
		var bays := maxi(1, roundi(length / OldTownRoofs.GABLE_BAY))
		for k in bays:
			var a := p.lerp(q, float(k) / bays)
			var b := p.lerp(q, float(k + 1) / bays)
			var bm := (a + b) * 0.5
			var probe := Vector2(bm.x, bm.z) - Vector2(n.x, n.z)
			var wall := Color("#d9c9a8")
			var seed := fposmod(float(k) * 0.37 + bm.x * 0.013, 1.0)
			for h in grid.get(Vector2i(floori(probe.x / cell), floori(probe.y / cell)), []):
				if Geometry2D.is_point_in_polygon(probe, polys[h]):
					wall = looks[h]
					seed = seeds[h]
					break
			var extra := OldTownRoofs.plac_gable(a, b, n, wall, seed) if on_plac else OldTownRoofs.gable(a, b, n, wall, seed)
			if not extra.is_empty():
				_add_dress(dress, extra)


## Whether an OpenStreetMap house is one of Dobra's or Tamka's pre-war tenements: its centre
## within POWISLE_REACH of either street (outside the historic districts) and R4 type 1.
func _powisle_house(bld: Dictionary, poly: PackedVector2Array, centre: Vector2) -> bool:
	if _historic(centre, 0.0) or _powisle_distance(centre) > POWISLE_REACH:
		return false
	var kind := str(bld.get("kind", ""))
	return _building_type(kind, poly, float(bld.get("h", 0.0))) == 1


## The distance from a point to the nearest Dobra or Tamka centre line (INF beyond 80 m).
func _powisle_distance(at: Vector2) -> float:
	if _powisle_segs.is_empty():
		for r in data.get("roads", []):
			if not POWISLE_STREETS.has(str(r.get("name", ""))) or bool(r.get("bridge", false)):
				continue
			var p: Array = r["p"]
			for i in range(0, p.size() - 3, 2):
				_powisle_segs.append([Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3]))])
	var best := INF
	for sg: Array in _powisle_segs:
		if absf(at.x - sg[0].x) > 80.0 or absf(at.y - sg[0].y) > 80.0:
			continue
		best = minf(best, Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at))
	return best
var _powisle_segs: Array = []


## One wall triangle `t` of a Dobra or Tamka tenement: its cornice, string course and, when the
## wall faces the street, its shop front (TenementTrim) into `dress`.
func _powisle_trim(pos: PackedVector3Array, nrm: PackedVector3Array, t: int, plaster: Color, dress: Dictionary) -> void:
	var n := Vector3(nrm[t].x, 0.0, nrm[t].z)
	if n.length() < 0.9:
		return
	n = n.normalized()
	var mid := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
	var at := Vector2(mid.x, mid.z)
	# the wall faces the street when a point 8 m out is nearer to it than the wall itself
	var street := _powisle_distance(at) < POWISLE_SHOP_REACH and \
			_powisle_distance(at + Vector2(n.x, n.z) * 8.0) < _powisle_distance(at)
	var out := {"pos": [], "nrm": [], "col": []}
	TenementTrim.wall(out, pos[t], pos[t + 1], pos[t + 2], n, plaster, street)
	if not (out["pos"] as Array).is_empty():
		_add_dress(dress, {"pos": PackedVector3Array(out["pos"]), "nrm": PackedVector3Array(out["nrm"]),
				"col": PackedColorArray(out["col"])})


## Whether a point is within `slack` metres of a historic district (HISTORIC), or inside
## Mariensztat (MARIENSZTAT, whose edges already keep whole houses: no slack there).
func _historic(at: Vector2, slack: float) -> bool:
	for d in HISTORIC:
		if at.distance_to(Vector2(d.x, d.y)) < d.z + slack:
			return true
	if _mariensztat.is_empty():
		_mariensztat = PackedVector2Array(MARIENSZTAT)
	return Geometry2D.is_point_in_polygon(at, _mariensztat)
var _mariensztat := PackedVector2Array()


## Whether a point stands in the houses of Nowy Świat (NOWY_REACH of its centre line, short of
## Al. Jerozolimskie), apart from the historic districts, which keep their own dress.
func _nowy_swiat(at: Vector2) -> bool:
	if _nowy_segs.is_empty():
		for r in data.get("roads", []):
			if str(r.get("name", "")) != NOWY_STREET or bool(r.get("bridge", false)):
				continue
			var p: Array = r["p"]
			for i in range(0, p.size() - 3, 2):
				var a := Vector2(float(p[i]), float(p[i + 1]))
				var b := Vector2(float(p[i + 2]), float(p[i + 3]))
				if a.y < NOWY_END_Z and b.y < NOWY_END_Z:
					_nowy_segs.append([a, b])
	for sg: Array in _nowy_segs:
		if absf(at.x - sg[0].x) > 80.0 or absf(at.y - sg[0].y) > 80.0:
			continue
		if Geometry2D.get_closest_point_to_segment(at, sg[0], sg[1]).distance_to(at) < NOWY_REACH:
			return not _historic(at, 0.0)
	return false
var _nowy_segs: Array = []


## The named Royal Route streets' segments in this map or sector: [a, b, half width + reach].
func _royal_segments() -> Array:
	var out := []
	for r in data.get("roads", []):
		if not ROYAL_STREETS.has(r.get("name", "")):
			continue
		var p: Array = r["p"]
		var reach := float(r.get("w", 6.0)) * 0.5 + ROYAL_REACH
		for i in range(0, p.size() - 3, 2):
			out.append([Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3])), reach])
	return out


## Whether a lamp at (x, z) is one of the historic lanterns.
func _on_royal_route(x: float, z: float, royal: Array) -> bool:
	var at := Vector2(x, z)
	if at.distance_to(Vector2(OLD_TOWN.x, OLD_TOWN.y)) < OLD_TOWN.z:
		return true
	for s in royal:
		if absf(at.x - s[0].x) > 100.0 or absf(at.y - s[0].y) > 100.0:
			continue
		if Geometry2D.get_closest_point_to_segment(at, s[0], s[1]).distance_to(at) < float(s[2]):
			return true
	return false


## Marks the lamp head's vertices (its colour) with UV.x = 1, so fixture.gdshader
## knows what glows.
func _mark_head(mesh: ArrayMesh) -> ArrayMesh:
	return _mark_glow(mesh, [LAMP_HEAD])


## The landmarks loop: _mark_head for any parts, by their colours (the shelter's posters).
func _mark_glow(mesh: ArrayMesh, glowing: Array) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in colours.size():
		var lit := false
		for c: Color in glowing:
			lit = lit or colours[i].is_equal_approx(c)
		uv[i] = Vector2(1.0, 1.0) if lit else Vector2(-1.0, -1.0)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## A soft glow round every lamp head (glow.gdshader, billboards; `heads` in world space),
## under a "LampHalos" node the game shows only when the lights are on.
func _build_lamp_halos(heads: Array[Transform3D], glows: Array[Color]) -> void:
	var holder := Node3D.new()
	holder.name = "LampHalos"
	# Loop 3c: in the group main.gd shows at night, so every sector's halos follow the lights.
	holder.add_to_group("night_lights", true)
	_out.add_child(holder)
	var none: Array[Color] = []
	_tree_multimesh(_shared["halo_quad"], _shared["halo"], heads, glows, none, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A square of `size` metres centred on the origin, UV 0..1, white: a halo sprite.
static func halo_quad(size: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var corners := [Vector3(-h, h, 0), Vector3(h, h, 0), Vector3(h, -h, 0), Vector3(-h, -h, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(Color.WHITE)
		st.set_uv(uvs[k])
		st.add_vertex(corners[k])
	return st.commit()


## Neon shop signs (neon_signs.gd) on the ground floor of about a third of the
## buildings with a street in front: on the longest wall facing it, if the word
## fits. They go under a "Neon" node the game shows only when the lights are on.
## The landmarks loop: the landmarks' own big signs (`marks.signs`: word, the middle of its
## bottom edge, the wall's outward normal, the scale over a shop sign), lit by day and night
## (INSTANCE_CUSTOM.z = 2), so not under the night lights' holder.
## Loop 3e merge: the sectors share one Landmarks, whose `signs` grow with every landmark it
## builds, and a landmark can be built by more than one sector; so each sector takes only the
## signs standing in it, and the list is emptied after each build.
func _build_landmark_signs(marks) -> void:
	var list: Array = marks.signs.duplicate()
	marks.signs.clear()
	if _in_sector:
		list = list.filter(func(s: Array) -> bool: return _sector_rect.has_point(Vector2((s[1] as Vector3).x, (s[1] as Vector3).z)))
	if list.is_empty():
		return
	_make_shared()
	var spots: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	var all := Neon.all_words()
	for sign: Array in list:
		var word: String = sign[0]
		var t := Neon.place(word, sign[1], sign[2])
		var k: float = sign[3]
		t.basis = Basis(t.basis.x * k, t.basis.y * k, t.basis.z)
		t.origin = sign[1] + Vector3.UP * (t.basis.y.length() * 0.5) + (sign[2] as Vector3).normalized() * 0.4
		spots.append(t)
		colours.append(sign[4])
		custom.append(Color(all.find(word), float(Neon.word_width(word) + 2 * Neon.PAD) / Neon.ATLAS_W, 2.0, 0.0))
	var holder := Node3D.new()
	holder.name = "LandmarkSigns"
	_out.add_child(holder)
	_tree_multimesh(_shared["neon_quad"], _shared["neon"], spots, colours, custom, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_neon(keep: Array, marks) -> void:
	var streets := {}
	for r in data["roads"]:
		if String(r["k"]) in ["service", "footway", "path", "track"]:
			continue
		var half := float(r["w"]) * 0.5
		var pts := _pts(r["p"])
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var steps := maxi(1, ceili(a.distance_to(b) / 5.0))
			for k in steps + 1:
				var q := a.lerp(b, float(k) / steps)
				var key := Vector2i(floori(q.x / 24.0), floori(q.y / 24.0))
				# Packed arrays are values: append to the copy, then put it back.
				var cell: PackedVector3Array = streets.get(key, PackedVector3Array())
				cell.append(Vector3(q.x, q.y, half))
				streets[key] = cell
	var polys: Array[PackedVector2Array] = []
	for f in _lod2_footprints:
		polys.append(_pts(f))
	var list: Array = data["buildings"]
	for index in (keep if _has_lod2 else range(list.size())):
		var bld: Dictionary = list[int(index)]
		if float(bld["mh"]) < 0.5 and not bld.has("br"):
			polys.append(_pts(bld["p"]))

	var spots: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	for poly in polys:
		if poly.size() < 3:
			continue
		var mid_p := Vector2.ZERO
		for q in poly:
			mid_p += q
		if marks.replaces(mid_p / poly.size()):
			continue  # no shop signs on the landmarks
		var pick := fposmod(sin(poly[0].x * 12.9898 + poly[0].y * 78.233) * 43758.5453, 1.0)
		if pick > 0.36:
			continue
		var best := -1.0
		var best_mid := Vector2.ZERO
		var best_out := Vector2.ZERO
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var length := a.distance_to(b)
			if length < 7.0 or length <= best:
				continue
			var mid := (a + b) * 0.5
			var e := (b - a) / length
			var out := Vector2(e.y, -e.x)
			if Geometry2D.is_point_in_polygon(mid + out * 0.3, poly):
				out = -out
			var front := mid + out * 4.5
			if _built_roof(front.x, front.y) != NO_ROOF or not _street_ahead(streets, mid, out):
				continue
			var ground := terrain_height(mid.x, mid.y)
			var inside := mid - out * 2.5
			if _built_roof(inside.x, inside.y) < ground + 6.0:
				continue
			best = length
			best_mid = mid
			best_out = out
		if best < 0.0:
			continue
		var word := ""
		for attempt in 4:
			var w: String = Neon.WORDS[int(fposmod(pick * 97.0 + attempt * 3.0, 1.0) * Neon.WORDS.size()) % Neon.WORDS.size()]
			if Neon.length_of(w) + 1.5 <= best:
				word = w
				break
		if word == "":
			continue
		var row := Neon.WORDS.find(word)
		var ground := terrain_height(best_mid.x, best_mid.y)
		spots.append(Neon.place(word, Vector3(best_mid.x, ground + 2.7, best_mid.y), Vector3(best_out.x, 0.0, best_out.y)))
		var tone := fposmod(pick * 53.7, 1.0)
		colours.append(Neon.colour_for(word, tone))
		var width := float(Neon.word_width(word) + 2 * Neon.PAD) / Neon.ATLAS_W
		var plate := 1.0 if fposmod(pick * 19.3, 1.0) < 0.45 else 0.0
		custom.append(Color(row, width, plate, fposmod(pick * 71.9, 1.0)))
	if spots.is_empty():
		return
	_make_shared()
	var holder := Node3D.new()
	holder.name = "Neon"
	holder.add_to_group("night_lights", true)  # loop 3c, as the lamp halos
	_out.add_child(holder)
	_tree_multimesh(_shared["neon_quad"], _shared["neon"], spots, colours, custom, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if holder.get_child_count() == 0:
		holder.free()  # loop 3c: this sector's signs all stand in its neighbours
	if not _in_sector:
		print("neon signs: ", spots.size())


## True when a street's carriageway lies 3–16 m in front of a wall.
func _street_ahead(streets: Dictionary, mid: Vector2, out: Vector2) -> bool:
	for d: float in [3.0, 7.0, 11.0, 16.0]:
		var q: Vector2 = mid + out * d
		var key := Vector2i(floori(q.x / 24.0), floori(q.y / 24.0))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var near: PackedVector3Array = streets.get(key + Vector2i(dx, dz), PackedVector3Array())
				for p in near:
					if Vector2(p.x, p.y).distance_to(q) < p.z + 2.5:
						return true
	return false


const POSTER := ["#e8d36a", "#e07a5f", "#81b29a", "#f2cc8f", "#9db4d8", "#e8a6b8", "#f4f1de"]


func _cylinder(st, centre: Vector3, radius: float, height: float, sides: int, col: Color) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := centre + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 := centre + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var up := Vector3(0, height, 0)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		_quad(st, p0, p1, p1 + up, p0 + up, n, col)
		_tri(st, centre + up, p1 + up, p0 + up, Vector3.UP, col)


## Benches, bins, bike racks, bus shelters and Warsaw's advertising columns. The easy-driving
## Benches OSM puts down loosely that stand in a straight row: [the row's middle, its direction,
## the point it faces, the radius that takes OSM's benches in]. Kino Muranów's square (F,
## 2026-11-07, a street photo): the four benches by the metro parapet stand in one line, square to
## the fountain; OSM had them on a crooked line, one turned round.
const BENCH_ROWS := [[Vector2(-1623.8, -1213.9), Vector2(-0.49, 0.872), Vector2(-1636.8, -1221.6), 4.5]]
const BENCH_GAP := 2.3


## `list` ([x, z, yaw] flat) with BENCH_ROWS' benches set in their rows.
static func _bench_rows(list: Array) -> Array:
	var out := list.duplicate()
	for row: Array in BENCH_ROWS:
		var mid: Vector2 = row[0]
		var dir: Vector2 = (row[1] as Vector2).normalized()
		var idx: Array[int] = []
		for i in range(0, out.size() - 2, 3):
			if Vector2(float(out[i]), float(out[i + 1])).distance_to(mid) < float(row[3]):
				idx.append(i)
		# In order along the row, evenly spaced about its middle, all facing the point's side.
		idx.sort_custom(func(a: int, b: int) -> bool:
			return Vector2(float(out[a]), float(out[a + 1])).dot(dir) < Vector2(float(out[b]), float(out[b + 1])).dot(dir))
		var f := Vector2(-dir.y, dir.x)
		if f.dot((row[2] as Vector2) - mid) < 0.0:
			f = -f
		for k in idx.size():
			var p := mid + dir * BENCH_GAP * (k - (idx.size() - 1) * 0.5)
			out[idx[k]] = p.x
			out[idx[k] + 1] = p.y
			out[idx[k] + 2] = atan2(-f.x, -f.y)
	return out


## loop (2026-10-30, the user's call): the small ones (benches, bins, bike racks, columns) are not
## obstacles, the car drives through them like the lamps and signal poles; shelters stay solid.
func _build_props() -> void:
	_make_shared()
	var metal: Material = _shared["prop_metal"]
	var none: Array[Color] = []
	var split := _split_chopin_benches(_bench_rows(data.get("benches", [])))
	_props(_shared["bench"], metal, split[0], 0.0, none, true, [], _station_benches)
	_props(_shared["bench_chopin"], metal, split[1], 0.0, none, true)
	_props(_shared["bin"], metal, data.get("bins", []), 0.0, none, true, [], _station_bins)
	_props(_shared["rack"], metal, data.get("bikes", []), 0.0, none, true)
	var tints: Array[Color] = []
	var list: Array = data.get("columns", [])
	for i in range(0, list.size() - 2, 3):
		tints.append(Color(POSTER[int(absf(float(list[i]) * 7.0 + float(list[i + 1]) * 3.0)) % POSTER.size()]))
	_props(_shared["column"], metal, list, 0.0, tints)
	# The Ratusz Arsenał hub's platforms carry their own arched canopies (ratusz_hub.gd): no
	# generic shelter there.
	var hub := RatuszHub.hub_platforms(data)
	var shelters: Array = []
	var all_shelters: Array = data.get("shelters", [])
	for i in range(0, all_shelters.size() - 2, 3):
		if not RatuszHub.covers(float(all_shelters[i]), float(all_shelters[i + 1]), hub):
			shelters.append_array([all_shelters[i], all_shelters[i + 1], all_shelters[i + 2]])
	var glows: Array[Color] = []
	glows.resize(shelters.size() / 3)
	glows.fill(SHELTER_GLOW)
	_props(_shared["shelter"], _shared["fixture"], shelters, 4.0, none, false, glows)


## The Royal Route's black granite benches (the Chopin benches, with the button that plays him):
## the benches within CHOPIN_REACH m of Krakowskie Przedmieście or Nowy Świat, split from the
## rest as [other triples, Chopin triples]. A 32 m grid of the two streets' segments keeps it
## to a few thousand lookups at load.
const CHOPIN_REACH := 14.0
const CHOPIN_STREETS := ["Krakowskie Przedmieście", "Nowy Świat"]


func _split_chopin_benches(list: Array) -> Array:
	var cells := {}
	for r: Dictionary in data.get("roads", []):
		if not CHOPIN_STREETS.has(str(r.get("name", ""))):
			continue
		var p: Array = r["p"]
		for i in range(0, p.size() - 3, 2):
			var seg := [float(p[i]), float(p[i + 1]), float(p[i + 2]), float(p[i + 3])]
			var x0 := floori((minf(seg[0], seg[2]) - CHOPIN_REACH) / 32.0)
			var x1 := floori((maxf(seg[0], seg[2]) + CHOPIN_REACH) / 32.0)
			var z0 := floori((minf(seg[1], seg[3]) - CHOPIN_REACH) / 32.0)
			var z1 := floori((maxf(seg[1], seg[3]) + CHOPIN_REACH) / 32.0)
			for cx in range(x0, x1 + 1):
				for cz in range(z0, z1 + 1):
					var key := Vector2i(cx, cz)
					if not cells.has(key):
						cells[key] = []
					(cells[key] as Array).append(seg)
	var rest := []
	var chopin := []
	for i in range(0, list.size() - 2, 3):
		var at := Vector2(float(list[i]), float(list[i + 1]))
		var near := false
		for seg: Array in cells.get(Vector2i(floori(at.x / 32.0), floori(at.y / 32.0)), []):
			var c := Geometry2D.get_closest_point_to_segment(at, Vector2(seg[0], seg[1]), Vector2(seg[2], seg[3]))
			if c.distance_to(at) <= CHOPIN_REACH:
				near = true
				break
		var dest: Array = chopin if near else rest
		dest.append_array([list[i], list[i + 1], list[i + 2]])
	return [rest, chopin]


## Instances of one prop at (x, z, yaw) triples; props bigger than `solid` metres
## across become obstacles. `fine`: under a metre tall (loop 2b: no shadow, FINE_GROUP).
func _props(mesh: Mesh, material: Material, list: Array, solid: float, tints: Array[Color], fine := false,
		custom: Array[Color] = [], extra: Array[Transform3D] = []) -> void:
	var spots: Array[Transform3D] = []
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	spots.append_array(extra)
	for mmi in _tree_multimesh(mesh, material, spots, tints, custom):
		if fine:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.add_to_group(FINE_GROUP, true)
		else:
			mmi.add_to_group(SMALL_CASTERS, true)
	if solid < 1.3:
		return
	for t in spots:
		var r := solid * 0.5
		var c := [t * Vector3(-r, 0, -0.5), t * Vector3(r, 0, -0.5), t * Vector3(r, 0, 0.5), t * Vector3(-r, 0, 0.5)]
		for k in 4:
			var a: Vector3 = c[k]
			var b: Vector3 = c[(k + 1) % 4]
			var up := Vector3(0, 2.0, 0)
			_wall_faces.append_array([a, b, b + up, a, b + up, a + up])


## PT-7 (2026-11-02): the car pinned in the dents of a building block's ground outline. Where
## two outlines stand under SLIT * 2 apart (the 0.5 m slit between two LoD2 buildings at Chmielna
## and Bracka) or a block's front has a notch at most POCKET_MOUTH wide and POCKET_DEPTH deep
## (the 3 m notch at its north-west corner, by Zgoda), a car sliding along the wall caught its
## front corner in it, sat pinned and was towed. Each such gap gets a low collider wall across its
## mouth (from under the ground to POCKET_WALL above it; nothing drawn), so the car slides past.
## Not on a road's carriageway, in a `lod2_open` box or near a garage door.
const SLIT := 0.45
const POCKET_MOUTH := 4.5
const POCKET_DEPTH := 3.0
const POCKET_WALL := 2.4
## How far a pocket's walls run beyond its mouth, at least: shorter is a corner, not a notch.
const POCKET_DETOUR := 0.6
## PT-17 (2026-11-03): a long shallow bay in a block's front (Jasna by Plac Dąbrowskiego: 24 m
## long, 2.3 m deep between two rounded piers 2 m proud) took a car whose stick pointed into the
## block: it slid along the bay at 15 m/s into one pier, was turned out along the wall, slid into
## the other pier, back and forth (70 s in the playtest) until the tow. A bay up to BAY_MOUTH
## wide and only BAY_DEPTH deep (less than a car's length: nobody parks in it) gets a wall across
## its mouth too. Deeper recesses stay open (the 9 m x 3 m one on Bracka: a car fits).
const BAY_MOUTH := 30.0
const BAY_DEPTH := 2.5
## A step out of a block's front, STEP_MIN to STEP_MAX proud of the wall before it (the corner of
## the next building, 0.3 m out at Chmielna and Bracka), caught the front corner of a car sliding
## along that wall nose on: a collider wall fairs it in, STEP_TAPER times its height long (~9°).
const STEP_MIN := 0.08
const STEP_MAX := 0.6
const STEP_TAPER := 6.0
## The walls added so far, all builds (check_stuck_spots prints it): ~22,600 for the whole city
## (~15,100 before the PT-17 bays),
## ~300 ms of a sector's build in the cloud (none on the prebuilt path: baked in).
var pocket_walls := 0


func _bridge_pockets(keep: Array, marks) -> void:
	var area := _sector_rect.grow(16.0) if _in_sector else Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6)
	var polys: Array[PackedVector2Array] = []
	for f in _lod2_footprints:
		var poly := _pts(f)
		if poly.size() < 3:
			continue
		var box := _poly_box(poly)
		if box.intersects(area) and not marks.replaces(box.get_center()):
			polys.append(poly)
	# Landmark models that ask for it (their mapped outline as the car's walls): bridged like a house.
	for poly: PackedVector2Array in marks.pocket_rings:
		if _poly_box(poly).intersects(area):
			polys.append(poly)
	var list: Array = data["buildings"]
	for index in (keep if _has_lod2 else range(list.size())):
		var bld: Dictionary = list[int(index)]
		if (bld["p"] as Array).size() < 6 or bld.has("br") or bld.has("cutd") or float(bld["mh"]) >= 0.5:
			continue
		if float(bld["h"]) <= float(bld["mh"]) or not marks.keeps_building(bld):
			continue
		var poly := _pts(bld["p"])
		if _poly_box(poly).intersects(area):
			polys.append(poly)
	# Grown by SLIT, outlines that overlap are one block: clusters by their grown boxes.
	var grown: Array[PackedVector2Array] = []
	var boxes: Array[Rect2] = []
	var grid := {}
	for poly in polys:
		var g := Geometry2D.offset_polygon(poly, SLIT, Geometry2D.JOIN_MITER)
		if g.is_empty():
			continue
		grown.append(g[0])
		boxes.append(_poly_box(g[0]))
		_grid_add(grid, boxes[-1], grown.size() - 1)
	var parent := PackedInt32Array()
	for i in grown.size():
		parent.append(i)
	for cell in grid:
		var ids: Array = grid[cell]
		for a in ids.size():
			for b in range(a + 1, ids.size()):
				var i: int = ids[a]
				var j: int = ids[b]
				if boxes[i].intersects(boxes[j]):
					var ri := _root(parent, i)
					var rj := _root(parent, j)
					if ri != rj:
						parent[ri] = rj
	var clusters := {}
	for i in grown.size():
		var r := _root(parent, i)
		if not clusters.has(r):
			clusters[r] = []
		clusters[r].append(i)
	var walls: Array[Vector2] = []
	for r in clusters:
		var ids: Array = clusters[r]
		var outs: Array[PackedVector2Array] = []
		for i: int in ids:
			var p: PackedVector2Array = grown[i]
			var merged := true
			while merged:
				merged = false
				for k in outs.size():
					if not _poly_box(outs[k]).intersects(_poly_box(p)) or Geometry2D.intersect_polygons(outs[k], p).is_empty():
						continue
					for m in Geometry2D.merge_polygons(outs[k], p):
						if not Geometry2D.is_polygon_clockwise(m):
							p = m
					outs.remove_at(k)
					merged = true
					break
			outs.append(p)
		var originals: Array[PackedVector2Array] = []
		for i: int in ids:
			originals.append(polys[i])
		for o in outs:
			for ring in Geometry2D.offset_polygon(o, -SLIT, Geometry2D.JOIN_MITER):
				if Geometry2D.is_polygon_clockwise(ring):
					continue
				_ring_bridges(ring, originals, walls)
				_ring_fairings(ring, walls)
				ring.reverse()
				_ring_fairings(ring, walls, -1.0)
	var open: Array = data.get("lod2_open", [])
	var doors: Array = data.get("garage_doors", [])
	var roads: Array = data.get("roads", [])
	for w in range(0, walls.size(), 2):
		var a := walls[w]
		var b := walls[w + 1]
		var mid := (a + b) * 0.5
		if _in_sector and not _sector_rect.has_point(mid):
			continue
		if _open_wall(a, open) or _open_wall(b, open) or _open_wall(mid, open):
			continue
		var near_door := false
		for d: Dictionary in doors:
			var c: Array = d["c"]
			near_door = near_door or mid.distance_to(Vector2(c[0], c[1])) < 8.0
		if near_door or _on_road(a, b, roads):
			continue
		var ga := terrain_height(a.x, a.y)
		var gb := terrain_height(b.x, b.y)
		var p0 := Vector3(a.x, ga - 0.5, a.y)
		var p1 := Vector3(b.x, gb - 0.5, b.y)
		var q0 := Vector3(a.x, ga + POCKET_WALL, a.y)
		var q1 := Vector3(b.x, gb + POCKET_WALL, b.y)
		_wall_faces.append_array([p0, p1, q1, p0, q1, q0])
		pocket_walls += 1


static func _root(parent: PackedInt32Array, i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i


## A block's closed outline (counter-clockwise): its edges over open ground (a slit it closed) and
## the mouths of its notches, as pairs of points appended to `walls`.
func _ring_bridges(ring: PackedVector2Array, originals: Array[PackedVector2Array], walls: Array[Vector2]) -> void:
	var n := ring.size()
	if n < 3:
		return
	var covered := PackedByteArray()
	covered.resize(n)
	# The notches: from vertex i the furthest j (up to 12 on) whose mouth is short, outside the
	# block, with every vertex between on the block's side within POCKET_DEPTH of it.
	var i := 0
	while i < n:
		var best := -1
		for step in range(12, 1, -1):
			if step < n - 1 and _ring_span(ring, i, step, 0.3, POCKET_MOUTH, POCKET_DEPTH):
				best = (i + step) % n
				break
		if best >= 0:
			walls.append_array([ring[i], ring[best]])
			var k := i
			while k != best:
				covered[k] = 1
				k = (k + 1) % n
			i = i + ((best - i + n) % n)
		else:
			i += 1
	# PT-17: then the long shallow bays (wider than a notch, at most BAY_DEPTH deep), on their own
	# pass so a notch inside one keeps its own wall.
	i = 0
	while i < n:
		var best := -1
		for step in range(12, 1, -1):
			if step < n - 1 and _ring_span(ring, i, step, POCKET_MOUTH, BAY_MOUTH, BAY_DEPTH):
				best = (i + step) % n
				break
		if best >= 0:
			walls.append_array([ring[i], ring[best]])
			i = i + ((best - i + n) % n)
		else:
			i += 1
	# The slits it closed: an edge with open ground just inside it (in no original outline).
	for e in n:
		if covered[e]:
			continue
		var a := ring[e]
		var b := ring[(e + 1) % n]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var inward := -(b - a).orthogonal() / length  # left of a→b (the block's side)
		# Open ground just inside it anywhere along it (the closed slit's mouth may share the
		# edge with a corner of the wall beside it).
		var open_ground := false
		for t: float in [0.1, 0.3, 0.5, 0.7, 0.9]:
			var probe := a.lerp(b, t) + inward * 0.12
			var solid := false
			for o in originals:
				if Geometry2D.is_point_in_polygon(probe, o):
					solid = true
					break
			if not solid:
				open_ground = true
				break
		if open_ground:
			walls.append_array([a, b])


## Whether ring[i] to ring[i + step] is the mouth of a dent: the mouth from `lo` to `hi` m long,
## outside the block, every vertex between on the block's side within `depth` of it, and the way
## round longer than the mouth by POCKET_DETOUR.
func _ring_span(ring: PackedVector2Array, i: int, step: int, lo: float, hi: float, depth: float) -> bool:
	var n := ring.size()
	var a := ring[i]
	var b := ring[(i + step) % n]
	var mouth := a.distance_to(b)
	if mouth > hi or mouth < lo:
		return false
	var path := 0.0
	var dir := (b - a) / mouth
	for k in step:
		var p := ring[(i + k) % n]
		var q := ring[(i + k + 1) % n]
		path += p.distance_to(q)
		if k > 0:
			# Counter-clockwise ring: the block lies to the left of a→b; a notch goes in there.
			var side := dir.cross(p - a)
			if side < -0.05 or side > depth:
				return false
	if path < mouth + POCKET_DETOUR:
		return false
	for t: float in [0.25, 0.5, 0.75]:
		if Geometry2D.is_point_in_polygon(a.lerp(b, t), ring):
			return false
	return true


## The steps out of a block's front met by a car sliding along it (the ring's way; `turn` -1 for
## the reversed ring, whose block lies to the right): a wall from the wall before the step,
## STEP_TAPER times the step back, to the step's outermost corner.
func _ring_fairings(ring: PackedVector2Array, walls: Array[Vector2], turn := 1.0) -> void:
	var n := ring.size()
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var length := a.distance_to(b)
		if length < 1.0:
			continue
		var d := (b - a) / length
		var best := -1
		var proud := 0.0
		var path := 0.0
		var prev := b
		for k in range(1, 6):
			var q := ring[(i + 1 + k) % n]
			path += prev.distance_to(q)
			prev = q
			if path > 1.6:
				break
			var out := -turn * d.cross(q - a)  # out of the block
			if out > STEP_MAX:
				best = -1
				break
			var ahead := (q - b).dot(d)
			if out >= STEP_MIN and out > proud and ahead > -0.2 and ahead < 1.5:
				proud = out
				best = (i + 1 + k) % n
		if best < 0:
			continue
		var back := minf(proud * STEP_TAPER, length)
		if back < proud * 3.0:
			continue
		walls.append_array([b - d * back, ring[best]])


## Whether a→b crosses a road or comes within its carriageway (`roads`' polylines and widths,
## with a 0.3 m margin): a service way into a yard or a gate is often flush with the walls.
func _on_road(a: Vector2, b: Vector2, roads: Array) -> bool:
	for r: Dictionary in roads:
		var pts: Array = r["p"]
		var half := float(r.get("w", 6.0)) * 0.5 + 0.3
		var box := Rect2(a, Vector2.ZERO).expand(b).grow(half)
		for k in range(0, pts.size() - 3, 2):
			var p := Vector2(pts[k], pts[k + 1])
			var q := Vector2(pts[k + 2], pts[k + 3])
			if not box.intersects(Rect2(p, Vector2.ZERO).expand(q)):
				continue
			if Geometry2D.segment_intersects_segment(a, b, p, q) != null:
				return true
			var gap := minf(minf(Geometry2D.get_closest_point_to_segment(a, p, q).distance_to(a),
					Geometry2D.get_closest_point_to_segment(b, p, q).distance_to(b)),
					minf(Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p),
					Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q)))
			if gap < half:
				return true
	return false


func _build_collision() -> void:
	var faces := _wall_faces
	if _in_sector:
		# Loop 3c: the faces whose centre lies in the sector (each face in exactly one).
		faces = PackedVector3Array()
		for i in range(0, _wall_faces.size() - 2, 3):
			var c := (_wall_faces[i] + _wall_faces[i + 1] + _wall_faces[i + 2]) / 3.0
			if _sector_rect.has_point(Vector2(c.x, c.z)):
				faces.append_array([_wall_faces[i], _wall_faces[i + 1], _wall_faces[i + 2]])
		if faces.is_empty():
			return
	var body := StaticBody3D.new()
	if _in_sector:
		# Loop 3d-2b: a sector's faces in shapes of at most COLLIDER_CHUNK faces, sorted by 64 m
		# cell (each shape a compact patch). The physics server builds a shape made on the
		# streamer's worker on the main thread, at once: a sector's 7,000-19,000 faces as one shape
		# stalled the frame its load ended 5-20 ms on the Mac; the prebuilt sector's worker loads
		# these one a frame (tools/bake_city.gd saves each as a piece). The faces are the same.
		for part in _collider_chunks(faces):
			var cs := CollisionShape3D.new()
			var piece := ConcavePolygonShape3D.new()
			piece.backface_collision = true
			piece.set_faces(part)
			cs.shape = piece
			body.add_child(cs)
		_out.add_child(body)
		return
	var shape := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.backface_collision = true
	concave.set_faces(faces)
	shape.shape = concave
	body.add_child(shape)
	_add_edge_walls(body)
	add_child(body)


## Loop 3d-2b: a sector's collider faces, at most this many to a shape (_build_collision).
const COLLIDER_CHUNK := 1000


## Loop 3d-2b: the faces (three vertices each) in runs of at most COLLIDER_CHUNK, sorted by the
## 64 m cell of each face's centre (row by row), so each run is a compact patch.
func _collider_chunks(faces: PackedVector3Array) -> Array[PackedVector3Array]:
	var order := []
	for i in range(0, faces.size() - 2, 3):
		var c := (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
		order.append([floori(c.z / 64.0) * 4096 + floori(c.x / 64.0), i])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array[PackedVector3Array] = []
	var part := PackedVector3Array()
	for o: Array in order:
		var i: int = o[1]
		part.append_array([faces[i], faces[i + 1], faces[i + 2]])
		if part.size() >= COLLIDER_CHUNK * 3:
			out.append(part)
			part = PackedVector3Array()
	if not part.is_empty():
		out.append(part)
	return out


## Loop 3c: the walls at the map's edge on their own body (the streamed city's index).
func _build_edge_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Edges"
	_add_edge_walls(body)
	add_child(body)


## Invisible walls at the edge of the baked area (map north: along the map's outline, 5 m in;
## four walls for a box, six with the north extension).
func _add_edge_walls(body: StaticBody3D) -> void:
	var ring := map_outline(-5.0)
	for k in ring.size():
		var a := ring[k - 1]
		var c := ring[k]
		var mid := (a + c) * 0.5
		var along_x := absf(c.x - a.x) > absf(c.y - a.y)
		var edge := [Vector3(mid.x, 50, mid.y),
				Vector3(absf(c.x - a.x), 200, 1) if along_x else Vector3(1, 200, absf(c.y - a.y))]
		var wall := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = edge[1]
		wall.shape = box
		wall.position = edge[0]
		body.add_child(wall)
