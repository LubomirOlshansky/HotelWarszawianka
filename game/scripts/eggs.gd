extends Node3D
## Easter eggs on the map (v0.65), all built at startup from the map data, cheap
## (a node or two each, one MultiMesh for the pigeons, one for the crowd):
##
## - the Palm on Rondo de Gaulle'a, on the roundabout's island, with a neon ring
##   and uplights at night;
## - pigeons on Plac Defilad, pecking; they burst into the air when the car (or the
##   helicopter) comes close, circle, and land again once it has gone;
## - roadwork barriers with a REMONT sign round a dig on a different street every
##   day (seeded by the date); the car knocks them about;
## - a crowd waiting at Patelnia by Metro Centrum;
## - the Mermaid with her sword and shield on the Powiśle boulevard.
##
## The first time the player comes close, the egg speaks a line from its group in
## dialogue.json and, if it is new to the save, a small card counts it ("EASTER EGG
## 2/5"). Joke billboards with the `signs` lines in pixel letters stand near some of
## them; driving past one shows its text with the English underneath. Loop 1: one
## advertising column in six wears a joke poster (`column_posters`), read the same way.

const Lang := preload("res://scripts/lang.gd")
const Access := preload("res://scripts/access.gd")
const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Wallet := preload("res://scripts/wallet.gd")
const River := preload("res://scripts/landmarks/river.gd")

const EGG_COLOUR := Color("#ff4fd8")
const NEAR := 30.0
const PIGEONS := 26
const CROWD := 22
## The driving-feel loop (2026-10-30): the share of its speed the car keeps knocking a barrier or
## a cone away (was 0.85: a run through the roadworks felt like a wall of them).
const KNOCK_KEEP := 0.95
## The roadworks loop (2026-10-30): traffic knocks the barriers too (the AI drove through the ones
## knocked into its lane), and the helicopter under DOWNWASH_HEIGHT m over them blows the ones
## within DOWNWASH_REACH m outwards at up to DOWNWASH_PUSH m/s.
const DOWNWASH_HEIGHT := 14.0
const DOWNWASH_REACH := 9.0
const DOWNWASH_PUSH := 3.5
const SHIRTS := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#2b2c2f", "#c96b2c", "#5aa9c9"]

var hud: CanvasLayer
var bubbles: Control
var dialogue: Node
var wallet: Node
var map: Node3D
var graph: LaneGraph
## Set by the game each frame: the vehicle, its velocity, whether it flies.
var player := Vector3.ZERO
var player_vel := Vector3.ZERO
var flying := false
## Testing: the day the barriers are placed for (yyyymmdd); 0 = today.
var day := 0
## Loop MW-6: the street today's roadworks are on (E37's condition: egg_book.gd), and a street
## they must go on (`--egg=e37`: the egg's own street, so its run needs no rare date).
var barrier_street := ""
var force_street := ""
## Loop MW-6: the notebook's egg cards (egg_book.gd): a find goes there, with its reward and card.
var book: Node
## Where the eggs are, for screenshots and the log.
var spots := {}
## How long the last update took, for --bench.
var last_usec := 0

## Eggs: {id, at: Vector3, anchor, group, speaker, height, near, inside, cool}.
var _eggs: Array[Dictionary] = []
var _signs: Array[Dictionary] = []
var _blocked := {}          # 8 m cell -> true where a parked car or a tree stands
var _t := 0.0
## The taxis on the Party House's inner road (_build_gaulle_lawn).
var _inner_mm: MultiMesh
var _inner_path := PackedVector2Array()
var _inner_len := 0.0
## One thing talks at a time: a sign waits while an egg speaks, and the other way round.
var _quiet := 0.0

# Pigeons: home spots, where they are, and the flock's state.
enum Flock { GROUND, AIR, LANDING }
var _flock := Flock.GROUND
var _flock_t := 0.0
var _home := PackedVector3Array()
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _yaw := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _ground_mm: MultiMesh
var _air_mm: MultiMesh
var _flock_centre := Vector3.ZERO

# Barriers and cones: {node, vel: Vector3, spin}.
var _knockables: Array[Dictionary] = []
var _barrier_centre := Vector3.INF
var _knock_wait := 0.0
var _car: CharacterBody3D
## The roadworks loop: the traffic, whose cars near the roadworks knock barriers and cones too.
var _traffic: Node

# The crowd at Patelnia.
var _crowd_mm: MultiMesh
var _crowd_yaw := PackedFloat32Array()
var _crowd_pos := PackedVector3Array()
var _crowd_tick := 0.0
var _rng := RandomNumberGenerator.new()


func setup(nodes: Dictionary, data: Dictionary) -> void:
	hud = nodes["hud"]
	bubbles = nodes["bubbles"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	map = nodes["map"]
	graph = nodes["graph"]
	_car = nodes["car"]
	_traffic = nodes.get("traffic")
	_rng.seed = 1955
	var t0 := Time.get_ticks_msec()
	_index_obstacles(data)
	var pois := {}
	for p in data.get("pois", []):
		if not pois.has(p["k"]):
			pois[p["k"]] = p
	var palm := _build_palm(data)
	_build_gaulle_lawn()
	_build_waiting(data)
	var square := _defilad(data, pois)
	if square != Vector2.INF:
		_build_pigeons(square)
	_build_barriers(data)
	if pois.has("patelnia"):
		_build_crowd(Vector2(pois["patelnia"]["x"], pois["patelnia"]["z"]))
	if pois.has("syrenka"):
		# The statue's measured spot (landmarks/river.gd, 2026-11-20): the bake's point is a guess
		# on the lower promenade (OSM maps no artwork there), 48 m from where she stands.
		_build_mermaid(Vector3(River.POWISLE_SYRENKA.x, 0.0, River.POWISLE_SYRENKA.y), River.POWISLE_SYRENKA_YAW)
	_build_billboards(data, palm)
	_build_column_posters(data)
	var where := PackedStringArray()
	for k in spots:
		var v: Vector3 = spots[k]
		where.append("%s %d,%d" % [k, roundi(v.x), roundi(v.z)])
	print("eggs: %s in %d ms" % [", ".join(where), Time.get_ticks_msec() - t0])


# --- finding room ---------------------------------------------------------------------

## Parked cars and tree trunks in 8 m cells, so props don't land on them.
func _index_obstacles(data: Dictionary) -> void:
	var parked: Array = data.get("parked", [])
	for i in range(0, parked.size() - 3, 4):
		_blocked[_cell(float(parked[i]), float(parked[i + 1]))] = true
	for key in ["trees3d", "trees"]:
		var list: Array = data.get(key, [])
		var step := 6 if key == "trees3d" else 4
		for i in range(0, list.size() - step + 1, step):
			_blocked[_cell(float(list[i]), float(list[i + 1]))] = true


static func _cell(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / 8.0), floori(z / 8.0))


## Open ground at p: no building within `clear` metres, no lane within `road`
## metres, no parked car or tree in its 8 m cell (or, `wide`, the cells around it).
func _open(p: Vector2, clear: float, road: float, wide := false) -> bool:
	var ground: float = map.ground_height(p.x, p.y)
	if map.top_height(p.x, p.y, clear) > ground + 0.5:
		return false
	if road > 0.0 and not graph.snap(p, road).is_empty():
		return false
	var c := _cell(p.x, p.y)
	if not wide:
		return not _blocked.has(c)
	for j in range(-1, 2):
		for i in range(-1, 2):
			if _blocked.has(c + Vector2i(i, j)):
				return false
	return true


## The open spot nearest `near` between `lo` and `hi` metres from it, or INF.
func _find_spot(near: Vector2, lo: float, hi: float, clear: float, road: float, wide := false) -> Vector2:
	var r := lo
	while r <= hi:
		var steps := 1 if r == 0.0 else maxi(8, int(TAU * r / 4.0))
		for k in steps:
			var a := TAU * k / steps
			var p := near + Vector2(cos(a), sin(a)) * r
			if _open(p, clear, road, wide):
				return p
		r += 3.0
	return Vector2.INF


## Plac Defilad, the square in front of the Palace of Culture's east side (the
## bus station's point lies in the car park that fills the rest of it).
func _defilad(data: Dictionary, pois: Dictionary) -> Vector2:
	for l in data.get("landmarks", []):
		if l["name"] == "Pałac Kultury i Nauki":
			var flat: Array = l["p"]
			var east := -INF
			var z := 0.0
			for i in range(0, flat.size() - 1, 2):
				east = maxf(east, float(flat[i]))
				z += float(flat[i + 1])
			return Vector2(east + 20.0, z / (flat.size() / 2.0))
	if pois.has("defilad"):
		return Vector2(pois["defilad"]["x"], pois["defilad"]["z"])
	return Vector2.INF


func _on_ground(p: Vector2) -> Vector3:
	return Vector3(p.x, map.ground_height(p.x, p.y), p.y)


func _add_egg(id: String, at: Vector3, anchor: Variant, group: String, speaker: String, height: float, near := NEAR) -> void:
	_eggs.append({"id": id, "at": at, "anchor": anchor, "group": group, "speaker": speaker, "height": height,
			"near": near, "inside": false, "cool": 0.0})
	spots[id] = at


# --- the Palm ---------------------------------------------------------------------------

## On the roundabout's island where the laser scan found it (loop 1); else off the tram
## tracks that cross the island, on whichever side has more room.
func _build_palm(data: Dictionary) -> Vector3:
	var sum := Vector2.ZERO
	var n := 0
	for r in data["roads"]:
		if String(r["name"]).begins_with("Rondo Generała Charles'a de Gaulle'a"):
			var flat: Array = r["p"]
			for i in range(0, flat.size() - 1, 2):
				sum += Vector2(flat[i], flat[i + 1])
				n += 1
	if n == 0:
		return Vector3.INF
	var c := sum / n
	# The tracks across the island: step off them sideways.
	var track_dir := Vector2.RIGHT
	var best := INF
	for t in data.get("trams", []):
		var flat: Array = t["p"]
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var b := Vector2(flat[i + 2], flat[i + 3])
			var q := Geometry2D.get_closest_point_to_segment(c, a, b)
			if q.distance_to(c) < best and a.distance_to(b) > 0.5:
				best = q.distance_to(c)
				track_dir = (b - a).normalized()
	var across := Vector2(-track_dir.y, track_dir.x)
	# Loop 1: the 14.5 m "tree" the laser scan found alone on the island is the Palm itself
	# (tools/bake_osm.py GUGIK_NOT_TREES leaves it out of trees3d and writes where it
	# stands as "palm"): the Palm stands there. Without it, the v0.8 search below.
	var scanned: Array = data.get("palm", [])
	if scanned.size() == 2:
		return _place_palm(Vector2(float(scanned[0]), float(scanned[1])))
	# v0.8: the laser-scanned trees (trees3d) on the island: the Palm keeps clear of
	# their crowns, so both read (one stood 5 m from it, crown to fronds).
	var crowns: Array[Vector3] = []
	var real: Array = data.get("trees3d", [])
	for i in range(0, real.size() - 5, 6):
		var t := Vector2(float(real[i]), float(real[i + 1]))
		if t.distance_to(c) < 30.0:
			crowns.append(Vector3(t.x, t.y, float(real[i + 3])))
	var spot := c
	var room := -INF
	for off in [7.5, -7.5, 9.5, -9.5]:
		var p: Vector2 = c + across * off
		var free := 0.0
		for t in crowns:
			var clear := p.distance_to(Vector2(t.x, t.y)) - t.z - 4.0  # crown radius + the fronds
			if clear < 3.0:
				free -= 20.0 + (3.0 - clear) * 4.0
		for k in 12:
			var q: Vector2 = p + Vector2(cos(TAU * k / 12.0), sin(TAU * k / 12.0)) * 3.0
			if not _blocked.has(_cell(q.x, q.y)):
				free += 1.0
		if graph.snap(p, 3.5).is_empty():
			free += 6.0
		if free > room:
			room = free
			spot = p
	return _place_palm(spot)


func _place_palm(spot: Vector2) -> Vector3:
	var at := _on_ground(spot)
	var palm := MeshInstance3D.new()
	palm.mesh = Props.palm()
	palm.material_override = Models.material()
	add_child(palm)
	palm.global_position = at
	palm.rotation.y = 0.6
	_build_palm_garden(spot)
	var anchor := Node3D.new()
	add_child(anchor)
	anchor.global_position = at + Vector3(0.6, 0, -0.2)
	_add_egg("palma", at, anchor, "easter_palma", "Palma", 14.5, 40.0)
	return at


## The island's two halves round the palm (centrum.json's kerbs and the tram ballast's edge
## near the scanned palm, 2026-11-20): planted since the autumn 2026 greening.
const PALM_BEDS := [
	[-232.0, 246.6, -231.4, 242.4, -230.2, 240.0, -227.5, 237.2, -223.4, 235.1, -218.0, 233.7,
			-212.1, 233.2, -209.4, 233.7, -207.2, 234.6, -205.1, 236.0, -204.6, 238.5, -205.6, 240.1,
			-203.6, 240.8],
	[-201.2, 245.6, -200.7, 247.6, -200.6, 250.0, -200.7, 251.5, -202.6, 254.8, -204.6, 256.6,
			-207.6, 258.1, -212.9, 259.2, -218.1, 259.8, -222.7, 259.9, -224.7, 259.1, -226.4, 258.2,
			-227.9, 257.0, -229.0, 255.4],
]


## The lawn by the de Gaulle statue and the cobbled inner road in front of the Party House
## (F, 2026-11-20: "a lot of people chilling there on summer evenings", "taxis on the inner road
## near the monument", "these lamps"): deckchairs with people in them on the lawn, facing the
## palm, a few taxis waiting along the inner road, and the plaza's five-lantern lamps. Three
## draw calls; static (the deckchair sitters don't move).
const LAWN_CHAIRS := [
	# [x, z, sitter] on the lawn east of the statue (centrum.json's grass, its steps kept clear).
	# F (2026-11-21, before main): "less people on the lawn, a few left and a few deckchairs".
	[-158.6, 270.0, 1], [-154.3, 271.0, 0], [-158.9, 273.6, 1], [-152.2, 275.8, 1],
	[-156.5, 277.0, 0], [-160.3, 280.9, 1], [-164.4, 282.7, 0],
]
## The cobbled inner road in front of the Party House (OSM's service way), the way the taxis drive
## it (F, 2026-11-20: "cars parked on the pavement, make them drive by this road").
const INNER_ROAD := [-158.9, 258.4, -166.3, 260.6, -173.5, 263.2, -176.4, 265.2, -178.4, 267.6, -179.7, 269.8,
		-180.5, 273.0, -180.7, 276.9, -179.5, 281.1, -177.7, 285.1]
const INNER_TAXIS := 3
const INNER_SPEED := 6.5
const INNER_GAP := 17.0
## The taxis stand at the rank (F, 2026-11-21) rather than drive the loop.
const INNER_RANK := true
const LAMP_SPOTS := [[-149.0, 281.5], [-161.5, 285.0], [-174.4, 281.5], [-157.5, 265.4]]


func _build_gaulle_lawn() -> void:
	var palm := Vector2(-213.9, 238.5)
	var spots: Array = []
	for ci in LAWN_CHAIRS.size():
		var c: Array = LAWN_CHAIRS[ci]
		var p := Vector2(float(c[0]), float(c[1]))
		var to := (palm - p).normalized()
		# Facing the palm across the rondo, each turned a little its own way.
		var yaw := atan2(-to.x, -to.y) + sin(p.x * 1.7 + p.y) * 0.35 + PI
		spots.append([p.x, p.y, yaw, map.ground_height(p.x, p.y), int(c[2])])
	var chairs := MeshInstance3D.new()
	chairs.name = "LawnChairs"
	chairs.mesh = Props.deckchairs(spots, 515)
	chairs.material_override = Models.material()
	add_child(chairs)
	# The taxis: one MultiMesh of the taxi family (the city taxi and Łuber) driving the inner
	# road one after another, each coming back to its start (_inner_taxis).
	_inner_path.clear()
	for i in range(0, INNER_ROAD.size() - 1, 2):
		_inner_path.append(Vector2(INNER_ROAD[i], INNER_ROAD[i + 1]))
	_inner_len = 0.0
	for i in range(1, _inner_path.size()):
		_inner_len += _inner_path[i - 1].distance_to(_inner_path[i])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = Models.traffic_mesh(1)
	mm.instance_count = INNER_TAXIS
	var paints := [Color("#f2f2ee"), Color("#1c1d20"), Color("#24324a")]
	for i in INNER_TAXIS:
		var paint: Color = paints[i % paints.size()]
		mm.set_instance_custom_data(i, Color(paint.r, paint.g, paint.b, float(i % 2)))
	_inner_mm = mm
	# The road's own paving: red-brown brick in a herringbone (F's Street View), as bands of two
	# tones every half metre across a ribbon over the asphalt.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bricks := [Color("#8a5848"), Color("#7a4a3c"), Color("#94624f")]
	var run := 0.0
	for k in range(1, _inner_path.size()):
		var a := _inner_path[k - 1]
		var b := _inner_path[k]
		var e := (b - a).normalized()
		var nrm := Vector2(-e.y, e.x) * 2.4
		var seg := a.distance_to(b)
		var n := maxi(1, int(seg / 0.5))
		for j in n:
			var p0 := a + e * seg * j / n
			var p1 := a + e * seg * (j + 1) / n
			var col: Color = bricks[int(run / 0.5) % bricks.size()]
			run += seg / n
			var q := [p0 - nrm, p1 - nrm, p1 + nrm, p0 + nrm]
			var ys := []
			for c: Vector2 in q:
				ys.append(map.ground_height(c.x, c.y) + 0.07)
			for idx in [0, 2, 1, 0, 3, 2]:
				st.set_color(col)
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(Models.FIXED, 0.0))
				st.add_vertex(Vector3(q[idx].x, ys[idx], q[idx].y))
	var paving := MeshInstance3D.new()
	paving.name = "InnerRoadPaving"
	paving.mesh = st.commit()
	paving.material_override = Models.material()
	paving.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(paving)
	var taxis := MultiMeshInstance3D.new()
	taxis.name = "InnerRoadTaxis"
	taxis.multimesh = mm
	taxis.material_override = Models.material()
	taxis.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(taxis)
	_inner_taxis(0.0)
	var lamps := MultiMesh.new()
	lamps.transform_format = MultiMesh.TRANSFORM_3D
	lamps.mesh = Props.candelabra()
	lamps.instance_count = LAMP_SPOTS.size()
	for i in LAMP_SPOTS.size():
		var l: Array = LAMP_SPOTS[i]
		lamps.set_instance_transform(i, Transform3D(Basis.IDENTITY, _on_ground(Vector2(float(l[0]), float(l[1])))))
	var lmi := MultiMeshInstance3D.new()
	lmi.name = "PlazaLamps"
	lmi.multimesh = lamps
	lmi.material_override = Models.material()
	add_child(lmi)


## F (2026-11-21, teaser 4: "more pedestrians waiting and walking"): people waiting at the
## kerb of every zebra round Rondo de Gaulle'a (centrum.json's `zebra` paths within WAIT_REACH m
## of the palm), two to four at each end a step back from the stripes, facing across, now and then
## one with a dog. One static mesh (+1 draw call), the walkers' own crowd stays as it is.
const WAIT_REACH := 95.0
func _build_waiting(data: Dictionary) -> void:
	var palm := Vector2(-213.9, 238.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2111
	var spots: Array = []
	for w: Dictionary in data.get("paths", []):
		if str(w.get("k", "")) != "zebra":
			continue
		var pts: Array = w["p"]
		if pts.size() < 4:
			continue
		var a := Vector2(float(pts[0]), float(pts[1]))
		var b := Vector2(float(pts[pts.size() - 2]), float(pts[pts.size() - 1]))
		if (a + b).distance_to(palm * 2.0) > WAIT_REACH * 2.0 or a.distance_to(b) < 6.0:
			continue
		for end: Array in [[a, b], [b, a]]:
			var at: Vector2 = end[0]
			var across: Vector2 = (end[1] - at).normalized()
			var side := Vector2(-across.y, across.x)
			var n := rng.randi_range(2, 4)
			for i in n:
				var p := at - across * rng.randf_range(0.9, 2.0) + side * rng.randf_range(-1.8, 1.8)
				var yaw := atan2(-across.x, -across.y) + PI + rng.randf_range(-0.4, 0.4)
				var dog := 1 if rng.randf() < 0.4 else 0
				spots.append([p.x, p.y, yaw, map.ground_height(p.x, p.y), dog])
	if spots.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "ZebraWaiting"
	mi.mesh = Props.standers(spots, 2111)
	mi.material_override = Models.material()
	add_child(mi)
	print("eggs: %d people waiting at the rondo's zebras" % spots.size())


## The inner road's taxis: each `INNER_GAP` m behind the one before, at `INNER_SPEED`, round the
## road and back to its start (out of sight under the next car's length). Skipped far from the player.
func _inner_taxis(dt: float) -> void:
	if _inner_mm == null or _inner_len <= 0.0:
		return
	if Vector2(player.x - _inner_path[0].x, player.z - _inner_path[0].y).length() > 400.0 and dt > 0.0:
		return
	var loop := maxf(_inner_len + 8.0, INNER_GAP * INNER_TAXIS)
	for i in INNER_TAXIS:
		# F (2026-11-21, teaser 4: "the taxis by the monument appear and disappear"): they wait at
		# the rank, nose to tail, instead of looping round and popping out at the road's end.
		var s := clampf(_inner_len * 0.55 - i * 6.0, 2.0, _inner_len - 2.0) if INNER_RANK else fposmod(_t * INNER_SPEED - i * INNER_GAP, loop)
		if s > _inner_len:
			_inner_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001), Vector3(0, -50, 0)))
			continue
		var at := _inner_path[0]
		var dir := Vector2.UP
		var run := 0.0
		for k in range(1, _inner_path.size()):
			var seg := _inner_path[k - 1].distance_to(_inner_path[k])
			if run + seg >= s:
				dir = (_inner_path[k] - _inner_path[k - 1]).normalized()
				at = _inner_path[k - 1] + dir * (s - run)
				break
			run += seg
		var yaw := atan2(-dir.x, -dir.y)
		_inner_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, map.ground_height(at.x, at.y), at.y)))


## The planted island round the palm (Props.palm_garden), when the palm stands where the
## laser scan put it (the beds are drawn round that spot).
func _build_palm_garden(spot: Vector2) -> void:
	if spot.distance_to(Vector2(-213.9, 238.5)) > 3.0:
		return
	var beds: Array = []
	for flat: Array in PALM_BEDS:
		var poly := PackedVector2Array()
		for i in range(0, flat.size() - 1, 2):
			poly.append(Vector2(flat[i], flat[i + 1]))
		if Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
		beds.append(poly)
	# The north half's straight side is the ballast's edge: close it along the tracks.
	var north: PackedVector2Array = beds[0]
	north.append(Vector2(-231.9, 249.5))
	if Geometry2D.is_polygon_clockwise(north):
		north.reverse()
	beds[0] = north
	var garden := MeshInstance3D.new()
	garden.name = "PalmGarden"
	garden.mesh = Props.palm_garden(beds, func(p: Vector2) -> float: return map.ground_height(p.x, p.y),
			Vector3(spot.x, spot.y, 3.4), 2002)
	garden.material_override = Models.material()
	add_child(garden)


# --- pigeons -------------------------------------------------------------------------

func _build_pigeons(near: Vector2) -> void:
	# Plac Defilad is mostly a car park: the paving nearest the bus station that is
	# clear of cars, lanes and buildings.
	var home := _find_spot(near, 0.0, 140.0, 7.0, 9.0, true)
	if home == Vector2.INF:
		return
	_flock_centre = _on_ground(home)
	for i in PIGEONS:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * 5.5
		var p := home + Vector2(cos(a), sin(a)) * r
		var at := _on_ground(p)
		_home.append(at)
		_pos.append(at)
		_vel.append(Vector3.ZERO)
		_yaw.append(_rng.randf() * TAU)
		_phase.append(_rng.randf() * TAU)
	_ground_mm = _pigeon_mm(Props.pigeon(false))
	_air_mm = _pigeon_mm(Props.pigeon(true))
	_write_pigeons()
	var anchor := Node3D.new()
	add_child(anchor)
	anchor.global_position = _flock_centre
	_add_egg("pigeons", _flock_centre, anchor, "easter_pigeons", "Gołąb", 2.2, 24.0)


func _pigeon_mm(mesh: ArrayMesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = PIGEONS
	InstanceBuffers.whiten(mm)
	mm.custom_aabb = AABB(_flock_centre - Vector3(80, 10, 80), Vector3(160, 80, 160))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Models.material()
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mm


## v0.9: the flock flushed (sfx.gd plays the wings).
signal flushed(at: Vector3)


func _pigeons(dt: float) -> void:
	if _home.is_empty():
		return
	var flat := Vector2(player.x - _flock_centre.x, player.z - _flock_centre.z).length()
	var low := player.y - _flock_centre.y < 35.0
	var scare := (flat < 13.0 and (player_vel.length() > 1.0 or flying)) or (flying and flat < 30.0 and low)
	_flock_t += dt
	match _flock:
		Flock.GROUND:
			if scare:
				_flock = Flock.AIR
				_flock_t = 0.0
				for i in PIGEONS:
					var away := Vector3(_pos[i].x - player.x, 0.0, _pos[i].z - player.z).normalized()
					if away == Vector3.ZERO:
						away = Vector3.FORWARD
					away = away.rotated(Vector3.UP, _rng.randf_range(-0.8, 0.8))
					_vel[i] = away * _rng.randf_range(3.0, 6.0) + Vector3.UP * _rng.randf_range(4.0, 7.0)
				flushed.emit(_flock_centre)
				_found("pigeons")
			elif flat > 260.0:
				return
		Flock.AIR:
			# Up to the rooftops, a wide lazy circle, and back once it is quiet.
			if _flock_t > 9.0 and flat > 28.0 and not scare:
				_flock = Flock.LANDING
				_flock_t = 0.0
		Flock.LANDING:
			if scare:
				_flock = Flock.AIR
				_flock_t = 0.0
				flushed.emit(_flock_centre)
	for i in PIGEONS:
		var p := _pos[i]
		if _flock == Flock.GROUND:
			# Peck about: a step now and then, turning.
			if _rng.randf() < dt * 0.4:
				_yaw[i] += _rng.randf_range(-1.2, 1.2)
			var step := Vector3(-sin(_yaw[i]), 0.0, -cos(_yaw[i])) * 0.25 * dt * float(sin(_t * 2.0 + _phase[i]) > 0.3)
			var q := p + step
			if Vector2(q.x - _home[i].x, q.z - _home[i].z).length() < 1.8:
				p = q
			else:
				_yaw[i] += PI * dt
		elif _flock == Flock.AIR:
			var climb := clampf(16.0 + float(i % 5) * 2.0 - (p.y - _flock_centre.y), -2.0, 4.0)
			var orbit := Vector3(-(p.z - _flock_centre.z), 0.0, p.x - _flock_centre.x).normalized() * 6.0
			var pull := Vector3(_flock_centre.x - p.x, 0.0, _flock_centre.z - p.z) * 0.06
			var want := orbit + pull + Vector3(0, climb, 0)
			_vel[i] = _vel[i].lerp(want, 1.0 - exp(-1.2 * dt))
			p += _vel[i] * dt
			_yaw[i] = atan2(-_vel[i].x, -_vel[i].z)
		else:
			var to := _home[i] - p
			var d := to.length()
			if d < 0.15:
				p = _home[i]
			else:
				_vel[i] = _vel[i].lerp(to / d * minf(7.0, d * 1.2 + 0.5), 1.0 - exp(-2.0 * dt))
				p += _vel[i] * dt
				_yaw[i] = atan2(-_vel[i].x, -_vel[i].z) if Vector2(_vel[i].x, _vel[i].z).length() > 0.3 else _yaw[i]
		_pos[i] = p
	if _flock == Flock.LANDING:
		var done := true
		for i in PIGEONS:
			if _pos[i].distance_to(_home[i]) > 0.15:
				done = false
				break
		if done:
			_flock = Flock.GROUND
	_write_pigeons()


func _write_pigeons() -> void:
	for i in PIGEONS:
		var p := _pos[i]
		var up: float = p.y - map.ground_height(p.x, p.z) if _flock != Flock.GROUND else 0.0
		var on_ground := up < 0.3
		var b := Basis(Vector3.UP, _yaw[i])
		var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), p)
		if on_ground:
			# Pecking: the body tips forward every second or so.
			var peck := maxf(0.0, sin(_t * 5.0 + _phase[i] * 3.0)) * 0.5
			_ground_mm.set_instance_transform(i, Transform3D(b * Basis(Vector3.RIGHT, -peck), p))
			_air_mm.set_instance_transform(i, hidden)
		else:
			var flap := 0.45 + 0.55 * absf(sin(_t * 16.0 + _phase[i]))
			_air_mm.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3(flap, 1.0, 1.0)), p))
			_ground_mm.set_instance_transform(i, hidden)


# --- the wandering barriers -------------------------------------------------------------

## A different street every day: the date seeds which named street, which stretch,
## which side. The barriers fence a dig on the pavement by the kerb.
func _build_barriers(data: Dictionary) -> void:
	var today := day
	if today == 0:
		var d := Time.get_date_dict_from_system()
		today = int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
	var rng := RandomNumberGenerator.new()
	rng.seed = today
	# Map north: 120 m inside the map's outline (it was the bounding box; the corner left outside).
	var segs: Array = []
	for r in data["roads"]:
		if String(r["name"]) == "" or not String(r["k"]) in ["primary", "secondary", "tertiary", "residential", "unclassified"]:
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var c := Vector2(flat[i + 2], flat[i + 3])
			if force_street != "" and String(r["name"]) != force_street:
				continue
			if a.distance_to(c) >= 26.0 and map.in_map(a, -120.0) and map.in_map(c, -120.0):
				segs.append([a, c, float(r["w"]), String(r["name"])])
	for attempt in 300:
		if segs.is_empty():
			return
		var s: Array = segs[rng.randi() % segs.size()]
		var a: Vector2 = s[0]
		var c: Vector2 = s[1]
		var dir := (c - a).normalized()
		var side := Vector2(-dir.y, dir.x) * (1.0 if rng.randf() < 0.5 else -1.0)
		var mid := a.lerp(c, rng.randf_range(0.3, 0.7))
		var centre: Vector2 = mid + side * (float(s[2]) * 0.5 + 2.2)
		# Room for the dig: pavement, not a building, a lane or a parked car.
		var ok := true
		for k in [-5.0, 0.0, 5.0]:
			if not _open(centre + dir * k, 2.0, 2.0):
				ok = false
				break
		if not ok:
			continue
		_place_barriers(centre, dir, side, String(s[3]))
		print("barriers for %d: %s at %d,%d" % [today, s[3], roundi(centre.x), roundi(centre.y)])
		return


func _place_barriers(centre: Vector2, dir: Vector2, side: Vector2, street: String) -> void:
	var at := _on_ground(centre)
	_barrier_centre = at
	barrier_street = street
	var yaw := atan2(-dir.x, -dir.y)
	var basis := Basis(Vector3.UP, yaw)
	var dig := MeshInstance3D.new()
	dig.mesh = Props.dig(9.0, 2.0)
	dig.material_override = Models.material()
	add_child(dig)
	dig.global_transform = Transform3D(basis, at)
	var barrier := Props.barrier()
	var cone := Props.cone()
	# Barriers round the dig (local: x across the pavement, z along the street): a closed
	# fence of 2 m barriers, four a side and one at each end (loop 1).
	var layout := [[Vector3(0, 0, -5.0), 0.0], [Vector3(0, 0, 5.0), 0.0]]
	for x in [-1.45, 1.45]:
		for z in [-3.3, -1.1, 1.1, 3.3]:
			layout.append([Vector3(x, 0, z), PI / 2])
	var road_side := 1.0 if Vector2(basis.x.x, basis.x.z).dot(-side) > 0.0 else -1.0
	var lamp_glow := Props.glow_material(true, 0.8)
	lamp_glow.set_shader_parameter("blink", true)
	var lamp_halo := Props.halo(1.3, Color(1.0, 0.62, 0.12, 0.85))
	for spot in layout:
		var node := _knockable(barrier, at + basis * spot[0], yaw + float(spot[1]))
		# A halo round the amber lamp, blinking with it at dusk and at night.
		var halo := MeshInstance3D.new()
		halo.mesh = lamp_halo
		halo.material_override = lamp_glow
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.position = Vector3(-0.78, 1.4, 0)
		halo.visible = false
		halo.add_to_group("night_lights")
		node.add_child(halo)
	for k in 4:
		_knockable(cone, at + basis * Vector3(road_side * 2.4, 0, -4.5 + k * 3.0), yaw)
	# A sign at each end, facing away from the dig (the text is on both faces).
	var board := MeshInstance3D.new()
	board.mesh = Props.work_sign("REMONT")
	board.material_override = Models.material()
	add_child(board)
	board.global_transform = Transform3D(Basis(Vector3.UP, yaw), at + basis * Vector3(0, 0, -6.4))
	var detour := MeshInstance3D.new()
	detour.mesh = Props.work_sign("OBJAZD →")
	detour.material_override = Models.material()
	add_child(detour)
	detour.global_transform = Transform3D(Basis(Vector3.UP, yaw + PI), at + basis * Vector3(0, 0, 6.4))
	var anchor := Node3D.new()
	add_child(anchor)
	anchor.global_position = at + basis * Vector3(0, 0, -6.4)
	_add_egg("barriers", at, anchor, "easter_barriers", "Barierka · " + street, 2.9, 26.0)


func _knockable(mesh: ArrayMesh, at: Vector3, yaw: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Models.material()
	add_child(mi)
	mi.global_position = Vector3(at.x, map.ground_height(at.x, at.z), at.z)
	mi.rotation.y = yaw
	_knockables.append({"node": mi, "vel": Vector3.ZERO, "spin": 0.0})
	return mi


## Light collision: the car shoves barriers and cones out of its way (and keeps KNOCK_KEEP of
## its speed); they slide, turn and stop. The roadworks loop: traffic cars shove them the same
## way (the AI never brakes for them), and the helicopter's downwash blows them about. Nothing
## to do when nothing is near.
func _barriers(dt: float) -> void:
	if _barrier_centre == Vector3.INF:
		return
	var p := _car.global_position
	_knock_wait = maxf(0.0, _knock_wait - dt)
	var near := Vector2(p.x - _barrier_centre.x, p.z - _barrier_centre.z).length() < 30.0 and not flying
	# Traffic near the roadworks: where each moving car is, its heading, speed and half length.
	var cars: Array[Vector3] = []
	var car_fwd: Array[Vector3] = []
	var car_v := PackedFloat32Array()
	var car_half := PackedFloat32Array()
	if _traffic != null:
		for d in _traffic.drivers():
			if d.ghost or d.v < 0.8 or Vector2(d.pos.x - _barrier_centre.x, d.pos.z - _barrier_centre.z).length() > 30.0:
				continue
			cars.append(d.pos)
			car_fwd.append(Vector3(-sin(d.yaw), 0.0, -cos(d.yaw)))
			car_v.append(d.v)
			car_half.append(d.length * 0.5)
	var blow: bool = flying and Vector2(player.x - _barrier_centre.x, player.z - _barrier_centre.z).length() < 30.0 \
			and player.y - map.ground_height(player.x, player.z) < DOWNWASH_HEIGHT
	for k in _knockables:
		var node: Node3D = k["node"]
		var v: Vector3 = k["vel"]
		for c in cars.size():
			# Under the car's box (its footprint and a little): knocked along and to the side.
			var rel_c := Vector3(node.global_position.x - cars[c].x, 0.0, node.global_position.z - cars[c].z)
			var right_c := car_fwd[c].cross(Vector3.UP)
			if absf(rel_c.dot(car_fwd[c])) < car_half[c] + 0.4 and absf(rel_c.dot(right_c)) < 1.3:
				var shove: Vector3 = car_fwd[c] * car_v[c] * 0.75 + right_c * signf(rel_c.dot(right_c)) * 1.5
				if shove.length() > v.length():
					v = shove
					k["spin"] = _rng.randf_range(-4.0, 4.0)
		if blow:
			var rel_h := Vector3(node.global_position.x - player.x, 0.0, node.global_position.z - player.z)
			var reach := rel_h.length()
			if reach < DOWNWASH_REACH and reach > 0.01:
				var gust := rel_h / reach * DOWNWASH_PUSH * (1.0 - reach / DOWNWASH_REACH)
				if gust.length() > v.length():
					v = gust
					k["spin"] = _rng.randf_range(-2.0, 2.0)
		if near:
			var rel := Vector3(node.global_position.x - p.x, 0.0, node.global_position.z - p.z)
			var speed: float = _car.vel.length()
			if rel.length() < 2.3 and speed > 0.8:
				var push: Vector3 = _car.vel * 0.75 + rel.normalized() * 1.5
				if push.length() > v.length():
					v = push
					k["spin"] = _rng.randf_range(-4.0, 4.0)
					if _knock_wait <= 0.0:
						_knock_wait = 0.25
						_car.vel *= KNOCK_KEEP
						Access.buzz(25, 0.3)
		if v.length_squared() > 0.0001:
			node.global_position += v * dt
			node.rotation.y += float(k["spin"]) * dt
			node.global_position.y = map.ground_height(node.global_position.x, node.global_position.z)
			v = v.move_toward(Vector3.ZERO, 7.0 * dt)
			k["spin"] = move_toward(float(k["spin"]), 0.0, 6.0 * dt)
		k["vel"] = v


# --- Patelnia -------------------------------------------------------------------------

## People waiting in small groups, facing each other: the city's meeting point.
func _build_crowd(near: Vector2) -> void:
	var centre := _find_spot(near, 0.0, 30.0, 3.0, 6.0)
	if centre == Vector2.INF:
		centre = near
	_crowd_mm = MultiMesh.new()
	_crowd_mm.transform_format = MultiMesh.TRANSFORM_3D
	_crowd_mm.use_custom_data = true
	InstanceBuffers.prepare(_crowd_mm)
	_crowd_mm.mesh = Models.person_mesh()
	_crowd_mm.instance_count = CROWD
	InstanceBuffers.whiten(_crowd_mm)
	_crowd_mm.custom_aabb = AABB(_on_ground(centre) - Vector3(40, 10, 40), Vector3(80, 30, 80))
	var placed := 0
	var groups := 0
	while placed < CROWD and groups < 30:
		groups += 1
		var a := _rng.randf() * TAU
		var g := centre + Vector2(cos(a), sin(a)) * _rng.randf_range(1.0, 9.0)
		if not _open(g, 1.0, 4.0):
			continue
		var size := mini(_rng.randi_range(2, 5), CROWD - placed)
		for k in size:
			var b := TAU * k / size + _rng.randf_range(-0.3, 0.3)
			var p := g + Vector2(cos(b), sin(b)) * (0.7 + 0.15 * size)
			var at := _on_ground(p)
			# Facing the middle of the group.
			var yaw := atan2(p.x - g.x, p.y - g.y)
			_crowd_pos.append(at)
			_crowd_yaw.append(yaw)
			_crowd_mm.set_instance_transform(placed, Transform3D(Basis(Vector3.UP, yaw), at))
			var shirt := Color(SHIRTS[_rng.randi() % SHIRTS.size()])
			_crowd_mm.set_instance_custom_data(placed, Color(shirt.r, shirt.g, shirt.b, _rng.randf() * 0.99))
			placed += 1
	for i in range(placed, CROWD):
		_crowd_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), _on_ground(centre)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = _crowd_mm
	mi.material_override = Models.material()
	add_child(mi)
	var anchor := Node3D.new()
	add_child(anchor)
	anchor.global_position = _on_ground(centre)
	_add_egg("patelnia", _on_ground(centre), anchor, "easter_patelnia", "Patelnia", 3.0, 30.0)


## Now and then someone in the crowd turns to look about.
func _crowd(dt: float) -> void:
	if _crowd_pos.is_empty():
		return
	_crowd_tick -= dt
	if _crowd_tick > 0.0:
		return
	_crowd_tick = 0.6
	var i := _rng.randi() % _crowd_pos.size()
	var yaw := _crowd_yaw[i] + _rng.randf_range(-0.7, 0.7)
	_crowd_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), _crowd_pos[i]))


# --- the Mermaid ------------------------------------------------------------------------

func _build_mermaid(at: Vector3, yaw: float) -> void:
	# The statue's own spot (no search for room: the monument is the landmark site's, solid itself).
	at.y = map.ground_height(at.x, at.z)
	var node := Node3D.new()
	add_child(node)
	node.global_position = at
	node.rotation.y = yaw
	# The statue itself is the "syrenka_powisle" landmark (landmarks.gd), on a plinth at this
	# spot; the egg keeps only the trigger and the night floodlight.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.0, 2.2)
	shape.shape = box
	shape.position.y = 1.0
	body.add_child(shape)
	node.add_child(body)
	# A cool floodlight at night.
	var halo := MeshInstance3D.new()
	halo.mesh = Props.halo(6.5, Color(0.45, 0.95, 1.0, 0.45))
	halo.material_override = Props.glow_material(true, 1.5)
	halo.position = Vector3(0, 5.2, 0)  # round the bronze, 3.3 m up on her pedestal
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.visible = false
	halo.add_to_group("night_lights")
	node.add_child(halo)
	_add_egg("syrenka", at, node, "easter_syrenka", "Syrenka", 5.6, 28.0)


# --- joke billboards ----------------------------------------------------------------------

## A billboard with each `signs` line near a place it fits: the pigeons, the palm,
## a kebab stand, Marszałkowska, the barriers.
func _build_billboards(data: Dictionary, palm: Vector3) -> void:
	var signs: Array = dialogue.lines.get("signs", [])
	var by_start := {}
	for l in signs:
		by_start[String(l[0]).get_slice(" ", 0)] = l
	var places: Array = []
	if spots.has("pigeons"):
		places.append([by_start.get("UWAGA:"), spots["pigeons"], Color("#f2c12e"), Color("#1d1b19"), 14.0])
	if palm != Vector3.INF:
		# Off the roundabout, looking at it.
		places.append([by_start.get("PALMA"), palm, Color("#ff4fd8"), Color("#fbf7ee"), 34.0])
	# The kebab stand nearest the Patelnia (loop MW-2: the one at -782,418 left the map's data, so
	# the nearest within 400 m now; the board was missing, 4 of DEMO's 5 stood).
	var kebab := Vector2.INF
	for p in data.get("pois", []):
		var kp := Vector2(p["x"], p["z"])
		if p["k"] == "kebab" and kp.distance_to(Vector2(-782, 418)) < 400.0 and (kebab == Vector2.INF
				or kp.distance_to(Vector2(-782, 418)) < kebab.distance_to(Vector2(-782, 418))):
			kebab = kp
	if kebab != Vector2.INF:
		places.append([by_start.get("KEBAB"), Vector3(kebab.x, 0, kebab.y), Color("#2a1f3a"), Color("#ffd23f"), 14.0])
	var marsz := Vector2.INF
	for r in data["roads"]:
		if r["name"] == "Marszałkowska":
			var flat: Array = r["p"]
			for i in range(0, flat.size() - 1, 2):
				var q := Vector2(flat[i], flat[i + 1])
				if marsz == Vector2.INF or q.distance_to(Vector2(-1010, -40)) < marsz.distance_to(Vector2(-1010, -40)):
					marsz = q
	if marsz != Vector2.INF:
		places.append([by_start.get("REMONT"), Vector3(marsz.x, 0, marsz.y), Color("#ff6a13"), Color("#fbf7ee"), 14.0])
	if _barrier_centre != Vector3.INF:
		places.append([by_start.get("OBJAZD"), _barrier_centre, Color("#f4f1ea"), Color("#c8282a"), 18.0])
	for place in places:
		if place[0] == null:
			continue
		var at: Vector3 = place[1]
		var spot := _find_spot(Vector2(at.x, at.z), place[4], 80.0, 6.0, 7.0)
		if spot == Vector2.INF:
			continue
		_billboard(place[0], spot, place[2], place[3])


## Loop MW-2 (parodies.md 6.2, storefronts.gd): the `signs` line starting with `word` on a
## billboard near `near` (the same spot rules as the others); false if no line or no spot.
func billboard_line(word: String, near: Vector2, paper: Color, ink: Color) -> bool:
	for l in dialogue.lines.get("signs", []):
		if String(l[0]).get_slice(" ", 0) != word:
			continue
		var spot := _find_spot(near, 18.0, 90.0, 6.0, 7.0)
		if spot == Vector2.INF:
			return false
		_billboard(l, spot, paper, ink)
		return true
	return false


func _billboard(l: Array, spot: Vector2, paper: Color, ink: Color) -> void:
	var text := String(l[0])
	var px := 0.1
	var cols := 96
	var lines := PixelFont.wrap_lines(text, cols - 8)
	var rows := lines.size() * PixelFont.LINE + 6
	var img := Image.create_empty(cols, rows, false, Image.FORMAT_RGBA8)
	img.fill(paper)
	# A border two pixels in, in the ink colour.
	for x in cols:
		for y in [1, rows - 2]:
			img.set_pixel(x, y, ink)
	for y in rows:
		for x in [1, cols - 2]:
			img.set_pixel(x, y, ink)
	for i in lines.size():
		var w := PixelFont.width(lines[i])
		PixelFont.draw(img, lines[i], (cols - w) / 2, 3 + i * PixelFont.LINE, ink)
	var tex := ImageTexture.create_from_image(img)
	var w_m := cols * px
	var h_m := rows * px
	var y0 := 3.2
	var node := Node3D.new()
	add_child(node)
	node.global_position = _on_ground(spot)
	# Facing the nearest road.
	var hit := graph.snap(spot, 80.0)
	if not hit.is_empty():
		var q := graph.point_at(hit[0], hit[2])
		node.rotation.y = atan2(-(q.x - spot.x), -(q.y - spot.y))
	var frame := MeshInstance3D.new()
	frame.mesh = Props.billboard_frame(w_m, h_m, y0)
	frame.material_override = Models.material()
	node.add_child(frame)
	var poster := MeshInstance3D.new()
	poster.mesh = Props.poster_quad(w_m, h_m, y0)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/poster.gdshader")
	mat.set_shader_parameter("poster", tex)
	poster.material_override = mat
	node.add_child(poster)
	_signs.append({"node": node, "line": l, "at": node.global_position, "inside": false, "height": y0 + h_m + 0.6,
			"colour": paper if paper.get_luminance() < 0.8 else ink})
	spots["sign " + text.get_slice(" ", 0).trim_suffix(":")] = node.global_position
	# For screenshots: --yaw= this to look at its face.
	print("billboard \"%s\" at %d,%d, seen from the front with --yaw=%d" % [text, roundi(spot.x), roundi(spot.y),
			roundi(fposmod(rad_to_deg(node.rotation.y) + 180.0, 360.0))])


# --- joke posters on the advertising columns (loop 1) ------------------------------------

## A poster wraps the column's band (map_builder.gd: radius 0.6 m, 0.5-2.9 m up) with its
## `column_posters` line in pixel letters twice, one copy facing the nearest road and one
## the far side; 4 cm letter pixels, so at most four lines of eight letters.
const POSTER_PX := 0.04
const POSTER_W := 96          # pixels round the column (two copies of 48)
const POSTER_H := 53          # pixels high: 0.62-2.74 m
const POSTER_SHARE := 6       # one column in six
const POSTER_PAPER := ["#ffd23f", "#f4f1ea", "#5ad1e6", "#ff8fd8", "#ff7a2f", "#9be36b", "#2a1f3a"]


## One column in POSTER_SHARE, picked by a hash of where it stands (the same every day),
## gets a poster; the lines go round in a shuffled order. All posters share one material
## (an atlas, a row of pixels per line) and one mesh per line.
func _build_column_posters(data: Dictionary) -> void:
	var lines: Array = dialogue.lines.get("column_posters", [])
	var cols: Array = data.get("columns", [])
	if lines.is_empty() or cols.size() < 3:
		return
	var picks: Array = []
	for i in range(0, cols.size() - 2, 3):
		var x := float(cols[i])
		var z := float(cols[i + 1])
		picks.append([fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0), x, z])
	picks.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	picks.resize(roundi(picks.size() / float(POSTER_SHARE)))
	var atlas := Image.create_empty(POSTER_W, POSTER_H * lines.size(), false, Image.FORMAT_RGBA8)
	var meshes: Array[ArrayMesh] = []
	var colours: Array[Color] = []
	for k in lines.size():
		var l: Array = lines[k]
		var rows: Array = l[2].get("poster", [l[0]]) if l.size() > 2 and l[2] is Dictionary else [l[0]]
		var paper := Color(POSTER_PAPER[k % POSTER_PAPER.size()])
		var ink := Color("#ffd23f") if paper.get_luminance() < 0.3 else Color("#1d1b19")
		_poster_image(atlas, k * POSTER_H, rows, paper, ink)
		meshes.append(_poster_band(float(k) / lines.size(), float(k + 1) / lines.size()))
		colours.append(paper if paper.get_luminance() < 0.8 else ink)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/poster.gdshader")
	mat.set_shader_parameter("poster", ImageTexture.create_from_image(atlas))
	var order := range(lines.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 2031
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	for n in picks.size():
		var k: int = order[n % order.size()]
		var spot := Vector2(picks[n][1], picks[n][2])
		var node := MeshInstance3D.new()
		node.mesh = meshes[k]
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		node.global_position = _on_ground(spot)
		var hit := graph.snap(spot, 60.0)
		if not hit.is_empty():
			var q := graph.point_at(hit[0], hit[2])
			node.rotation.y = atan2(-(q.x - spot.x), -(q.y - spot.y))
		var l: Array = lines[k]
		_signs.append({"node": node, "line": [l[0], l[1]], "at": node.global_position, "inside": false,
				"height": 3.9, "colour": colours[k], "near": 12.0})
	var first := PackedStringArray()
	for n in mini(3, picks.size()):
		first.append("\"%s\" at %d,%d" % [String(lines[order[n % order.size()]][0]), roundi(picks[n][1]), roundi(picks[n][2])])
	print("column posters: %d of %d columns, %d lines; %s" % [picks.size(), cols.size() / 3, lines.size(), ", ".join(first)])


## One poster into the atlas at row y0: paper, an ink band top and bottom, the lines
## centred in each half (one copy per side of the column).
func _poster_image(img: Image, y0: int, rows: Array, paper: Color, ink: Color) -> void:
	img.fill_rect(Rect2i(0, y0, POSTER_W, POSTER_H), paper)
	img.fill_rect(Rect2i(0, y0, POSTER_W, 2), ink)
	img.fill_rect(Rect2i(0, y0 + POSTER_H - 2, POSTER_W, 2), ink)
	var half := POSTER_W / 2
	var top := y0 + 3 + (4 - mini(rows.size(), 4)) * PixelFont.LINE / 2
	for i in mini(rows.size(), 4):
		var text := String(rows[i])
		var w := PixelFont.width(text)
		if w > half - 1:
			push_warning("column poster line too wide (%d px of %d): %s" % [w, half - 1, text])
		for side in 2:
			PixelFont.draw(img, text, side * half + (half - w) / 2, top + i * PixelFont.LINE, ink)
	# A thin seam between the two copies.
	img.fill_rect(Rect2i(half - 1, y0 + 2, 1, POSTER_H - 4), paper.darkened(0.25))
	img.fill_rect(Rect2i(POSTER_W - 1, y0 + 2, 1, POSTER_H - 4), paper.darkened(0.25))


## The poster band: a 16-sided strip round the column a hair outside its band, its UVs
## taking rows v0..v1 of the atlas; u runs to the right as seen from outside, and the
## middle of the first copy (u = 0.25) faces -Z.
func _poster_band(v0: float, v1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.615
	var y0 := 0.62
	var y1 := y0 + POSTER_H * POSTER_PX
	var sides := 16
	for i in sides:
		var u0 := float(i) / sides
		var u1 := float(i + 1) / sides
		# u = 0.25 at -Z; u grows to the right as seen from outside.
		var a0 := -TAU * u0
		var a1 := -TAU * u1
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var q := [p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0), p1 + Vector3(0, y0, 0), p0 + Vector3(0, y0, 0)]
		var uv := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
		var idx := [0, 1, 2, 0, 2, 3]
		if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
			idx = [0, 2, 1, 0, 3, 2]
		for k in idx:
			st.set_normal(n)
			st.set_uv(uv[k])
			st.add_vertex(q[k])
	return st.commit()


# --- the frame ---------------------------------------------------------------------------

func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_t += dt
	_pigeons(dt)
	_barriers(dt)
	_inner_taxis(dt)
	_crowd(dt)
	_quiet = maxf(0.0, _quiet - dt)
	for e in _eggs:
		e["cool"] = maxf(0.0, float(e["cool"]) - dt)
		var at: Vector3 = e["at"]
		var d := Vector2(player.x - at.x, player.z - at.z).length()
		var inside: bool = d < float(e["near"]) and (not flying or player.y - at.y < 90.0)
		if inside and not e["inside"] and e["cool"] <= 0.0 and _quiet <= 0.0 and bubbles.count() == 0:
			e["cool"] = 60.0
			_quiet = 5.0
			dialogue.say(e["anchor"], e["speaker"], e["group"], "", 4.5, EGG_COLOUR, e["height"])
			_found(e["id"])
			e["inside"] = true
		elif not inside:
			e["inside"] = false
	for s in _signs:
		var at: Vector3 = s["at"]
		var inside := Vector2(player.x - at.x, player.z - at.z).length() < float(s.get("near", 26.0))
		if inside and not s["inside"] and _quiet <= 0.0 and bubbles.count() == 0:
			_quiet = 4.0
			var l: Array = s["line"]
			bubbles.say(s["node"], "", l[0], l[1], 3.5, s["colour"], s["height"])
			s["inside"] = true
		elif not inside:
			s["inside"] = false
	last_usec = Time.get_ticks_usec() - t0


## Loop 2e: the eggs' names in Polish, for the note card (wallet.gd EGGS has the English).
const EGGS_PL := {"palma": "Palma na rondzie de Gaulle'a", "pigeons": "Gołębie na placu Defilad",
		"barriers": "Wędrujące roboty drogowe", "patelnia": "Patelnia przy metrze Centrum",
		"syrenka": "Syrenka na bulwarze"}


## Counts an egg the first time it is ever found, with a small card. Loop MW-6: the notebook's
## egg cards take it (egg_book.gd: the card, its reward, the note); the old card without them.
func _found(id: String) -> void:
	if book != null:
		book.record(id)
		return
	if wallet == null or not wallet.find_egg(id):
		return
	hud.show_note(Lang.pick("SEKRET %d/%d", "EASTER EGG %d/%d") % [wallet.eggs_found(), Wallet.EGGS.size()],
			Lang.pick(EGGS_PL.get(id, ""), Wallet.EGGS[id]), EGG_COLOUR)
	print("easter egg found: %s (%d/%d)" % [id, wallet.eggs_found(), Wallet.EGGS.size()])
