extends Node
## Side jobs (v0.65): kebab delivery and the słoiki run.
##
## Kebab: stands at real places (the mapped kebab places and a few busy corners,
## `kebab` pois) glow on the minimap and wear a ring on the road. Pull into one and
## the vendor hands over an order for a real address 400-1500 m away by road
## (sometimes across the river, "basically the centre"). There is no hard clock: a
## heat meter (the steam over the kebab) fades as you drive, the tip goes with the
## heat, nights pay more. The customer waits at the door and says how it arrived.
##
## Słoiki: Sunday evening at Dworzec Centralny, a newcomer with mum's jars needs a
## lift to a rented flat in Powiśle. Hard bumps (the car's closing speed), heavy
## braking and fast corners stress the jars; too much and one breaks. Careful
## driving at speed is fine. The passenger talks on the way; the fare goes by the
## jars that arrive whole.
##
## One activity at a time: a job starts only when no rescue or race runs (and not
## from the helicopter); while it runs, rescue calls and race challenges wait.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Access := preload("res://scripts/access.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Beacon := preload("res://scripts/beacon.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const CourierRace := preload("res://scripts/courier_race.gd")
const Zaglebie := preload("res://scripts/zaglebie.gd")
const RouteLine := preload("res://scripts/route_line.gd")

const KEBAB_COLOUR := Color("#ff8a3d")
const SLOIK_COLOUR := Color("#4fd8c4")
const FAIL_COLOUR := Color("#e2574c")
const PULL_IN := 7.0          # stop in this ring to start a job...
const PULL_IN_SPEED := 8.0    # ...going slower than this (m/s): pulling in, not passing
const ARRIVE := StopAssist.RING          # the door's ring
const ARRIVE_SPEED := StopAssist.STOP_SPEED
## PT-16 (2026-11-03): a result card (delivered, or the order dropped) goes by itself RESULT_LIFE s
## after it comes up, or once the car is RESULT_OFF m from where it came up (OK closes it at once),
## as Podwózka's does (rides.gd). It waited for OK: the playtest agent never pressed it, drove
## back to the customer still standing in the ring six times, and every beat of the guide waited.
const RESULT_LIFE := 12.0
const RESULT_OFF := 25.0
const ORDER_MIN := 400.0
const ORDER_MAX := 1500.0
## Across the river it is "basically the centre": the customer's word, not the map's.
## (Rondo Dmowskiego to the Saska Kępa streets is 3-3.9 km by road, round by Rondo
## Waszyngtona just off the map.)
const ACROSS_MAX := 3600.0
const JARS := 6
## Słoiki pay (the designer pass, 2026-11-01, docs/design/pay-tables.md): a fare plus a sum per
## jar that arrives whole (was 50 + 35 a jar: about twice a kebab's złoty a minute).
const SLOIK_BASE := 40
const SLOIK_PER_JAR := 30
const NIGHT_BONUS := 1.5
## Jar stress: braking harder than this (m/s²), and cornering harder than this
## (lateral m/s²), add to it; a bump adds by its closing speed above BUMP_FREE.
const BRAKE_FREE := 16.0
const CORNER_FREE := 14.0
const BUMP_FREE := 3.0
## Loop 3h slice 4 (docs/DEMO.md 6.2, 0:30): the guided first order. The stand by the
## Marszałkowska × Świętokrzyska corner (the stand nearest FIRST_STAND), its first order a door
## on FIRST_STREET about FIRST_ROAD m on by road, straight on from the stand (first10.gd pins it;
## any other stand's first order is an ordinary one). The first-10 polish: a short, easy first job
## (it was ~920 m past the Rotunda, a U-turn and two junctions away).
const FIRST_STAND := Vector2(-1060.0, -230.0)
const FIRST_STREET := "Marszałkowska"
const FIRST_ROAD := 300.0
const CUSTOMERS := ["Ania", "Kasia", "Ola", "Magda", "Zosia", "Ewa", "Basia", "Marta",
		"Tomek", "Kuba", "Piotrek", "Michał", "Paweł", "Marek", "Wojtek", "Krzysiek"]
const NEWCOMERS := ["Kuba", "Ola", "Bartek", "Kasia", "Michał", "Magda"]
## DEMO 6.3: the second słoiki station, Dworzec Gdański (the bake maps only Warszawa Centralna as a
## "station" POI; the platforms of Gdańska lie past the north edge, its hall and forecourt inside).
## `door` is a point on Słomińskiego by the hall (the kerb search snaps to the lane graph within 30 m),
## `x`/`z` the building. Its newcomers go to Muranów, the blocks south of the station: a flat of
## `dest` (a box x0, z0, x1, z1 in map metres, offices left out) 600 to 2000 m by road. The first
## station's flats are in Powiśle, 1000 to 2400 m by road (data "d" = powisle).
const GDANSKI := {"k": "station", "name": "Dworzec Gdański", "x": -2008.0, "z": -2700.0,
		"door": [-2001.0, -2664.0], "w": 10.0, "dest": "muranow", "dest_pl": "Muranów", "dest_en": "Muranów",
		"box": [-2700.0, -2700.0, -1500.0, -1500.0], "lo": 600.0, "hi": 2000.0, "tag": "gdanski"}
const CENTRALNY_DEST := {"dest": "powisle", "dest_pl": "Powiśle", "dest_en": "Powiśle", "lo": 1000.0, "hi": 2400.0,
		"tag": "centralny"}

enum Job { NONE, KEBAB, SLOIK }
enum State { IDLE, ORDER, DELIVER, RESULT }

var hud: CanvasLayer
var bubbles: Control
var dialogue: Node
var wallet: Node
var missions: Node
var rivals: Node
var graph: LaneGraph
var traffic: Node3D
var map: Node3D
var car: CharacterBody3D
var tod: Node
var state := State.IDLE
var job := Job.NONE
## How long the last update took, for --bench.
var last_usec := 0
## Set by the game each frame.
var flying := false
## Testing (--autopilot): drive the job's route on a ghost driver.
var autopilot := false
## Testing: the kebab's starting heat (--heat=), jars already broken (--sloik=K).
var start_heat := 1.0
var start_broken := 0
## Loop 2d-1: the Podwózka job (rides.gd), so the two never run at once.
var rides: Node
## () -> bool: something else runs (main.gd `_quest_running`: a questline, a tow): no stands' rings.
var others_busy: Callable
## Loop MW-4: the "Na czasie" job (trend_job.gd), likewise.
var trend: Node
## Loop 3g-2 (police.md 8.3): the kebab's heat stands still while a pull-over's card is open
## (police.gd sets it).
var heat_frozen := false
## Loop jobs-2 (parodies.md 4.3): the courier race (courier_race.gd, a child: it rides along a
## kebab order) and the Leżak round-up (roundup_job.gd, a child too; main.gd makes it). Both step
## in this script's _process, so the bench's "jobs+eggs" line holds them.
var courier: CourierRace
var roundup: Node

## Stands: {ring: Vector3, at: Vector3, yaw, heading, node, marker, cool, across; loop MW-2: xf (the
## kiosk's transform), name (its board, "" for KEBAB only), tag (the vendor's line tag)}.
var _stands: Array[Dictionary] = []
## Loop MW-2: the generic stands' MultiMeshes, one per 512 m tile (parodies.md 6.1, 8: ≈ ±0 draw
## calls, fewer nodes), and where they go.
var _stand_tiles: Array[MultiMeshInstance3D] = []
var _stand_mesh: ArrayMesh
var _world: Node3D
## The station pick-up: {ring, at, yaw, heading, person, marker, cool}.
## Every słoiki station (the OSM one, then Dworzec Gdański), and the one a run is on.
var _stations: Array[Dictionary] = []
var _station: Dictionary = {}
## Addresses: {name, door: Vector2, at: Vector2, office, d}.
var _addresses: Array[Dictionary] = []
var _order: Dictionary = {}
var _orders := 0
var _t := 0.0
## PT-13: the seconds the order card's GO last showed (-1: not counted yet).
var _go_left := -1
var _clock := 0.0
var _heat := 1.0
var _jars := JARS
var _stress := 0.0
var _brake_s := 0.0
var _lat_s := 0.0
var _last_v := 0.0
var _last_yaw := 0.0
var _have_last := false
var _bump_wait := 0.0
var _warn_wait := 0.0
var _chat_t := 0.0
var _said_order := false
var _beacon: Node3D
var _ghost = null
var _slide := false
var _stall := 0.0
var _ring_mats := {}
var _stand_halo: ArrayMesh
var _halo_mat: ShaderMaterial
var _places_shown := false
## The free-ride boat's mooring (boat_race.gd fleet_spot(1), set by main.gd; INF: none) and its mark's colour.
var boat_spot := Vector2.INF
const BOAT_COLOUR := Color("#1f4fa8")
var _rng := RandomNumberGenerator.new()
## Loop 3h slice 4: the stand whose next order is the guided first order (first10.gd `pin_first`;
## -1: none). Cleared once that order is made.
var pinned := -1
## PT-16: where the car was when the result card came up.
var _result_at := Vector3.ZERO
## Zagłębie Kebabowe: Kino Femina's point (the welcome line), whether the craft kebab's wait runs (s
## left; the order's "premium" is set when it ends) and whether the welcome played this session.
var _femina := Vector2.INF
var _craft_t := 0.0
var _welcomed := false
## Testing: --craft=plain makes the autopilot take the plain kebab at the craft shop.
var craft_plain := false
## Beta values (2026-11-04): the way to the door (or to the next stand) on the minimap, and the
## stand the delivered card's NASTĘPNE picked (-1: none). The pointer goes once the car pulls in
## there, or as soon as anything else (a ride, a race, a rescue, the helicopter) is on.
var _route: RouteLine
var _route_on := false
var next_stand := -1
## The result card up now is a delivery (not a dropped order): NASTĘPNE is on it.
var _delivered := false


func setup(nodes: Dictionary, data: Dictionary, world: Node3D) -> void:
	hud = nodes["hud"]
	bubbles = nodes["bubbles"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	missions = nodes["missions"]
	rivals = nodes["rivals"]
	graph = nodes["graph"]
	traffic = nodes["traffic"]
	map = nodes["map"]
	car = nodes["car"]
	tod = nodes["tod"]
	_rng.randomize()
	_route = RouteLine.new(graph)
	var t0 := Time.get_ticks_msec()
	var stand_mesh := Props.kebab_stand()
	_stand_halo = Props.halo(7.5, Color(1.0, 0.5, 0.25, 0.5))
	_halo_mat = Props.glow_material(true)
	var pois: Array = data.get("pois", []).duplicate()
	# Zagłębie Kebabowe (docs/design/zaglebie-kebabowe.md): five shops on Al. Solidarności by Kino Femina.
	pois.append_array(Zaglebie.extra_pois(data.get("origin", [52.234, 21.024])))
	for p in pois:
		match String(p["k"]):
			"kebab":
				_add_stand(p, stand_mesh, world)
			"station":
				_add_station(p, world)
			"address":
				var door: Array = p["door"]
				_addresses.append({"name": p["name"], "door": Vector2(door[0], door[1]), "at": Vector2(p["x"], p["z"]),
						"office": p.has("o"), "d": String(p.get("d", ""))})
	if not _station_near(Vector2(GDANSKI["x"], GDANSKI["z"])):
		_add_station(GDANSKI, world)
	_world = world
	_stand_mesh = stand_mesh
	_femina = Zaglebie.femina_at(data.get("origin", [52.234, 21.024]))
	_build_stand_tiles()
	_name_zaglebie()
	for s in _stands:
		s["across"] = _district_near(Vector2(s["ring"].x, s["ring"].z)) == "praga"
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(KEBAB_COLOUR, Color("#2f6fb5"))
	# Loop jobs-2: the courier race rides along the kebab orders.
	courier = CourierRace.new()
	courier.name = "CourierRace"
	courier.dialogue = dialogue
	courier.bubbles = bubbles
	courier.hud = hud
	courier.wallet = wallet
	courier.map = map
	courier.car = car
	courier.graph = graph
	courier.paths = data.get("paths", [])
	courier.autopilot = autopilot
	courier.set_process(false)
	add_child(courier)
	courier.setup(world)
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func():
		if state == State.ORDER or state == State.DELIVER:
			_abandon())
	car.bumped.connect(_on_bump)
	var where := PackedStringArray()
	for st in _stands:
		where.append("%d,%d" % [roundi(st["at"].x), roundi(st["at"].z)])
	print("jobs: %d kebab stands (%s), %d addresses, stations %s in %d ms" % [_stands.size(), " ".join(where), _addresses.size(),
			" ".join(_stations.map(func(st: Dictionary) -> String: return "%s %d,%d" % [st["name"], roundi(st["ring"].x), roundi(st["ring"].z)])) \
			if not _stations.is_empty() else "none", Time.get_ticks_msec() - t0])


# --- loop MW-2: the stands' drawing, names and tags (storefronts.gd) ---------------------------

## Zagłębie Kebabowe's five stands wear their shops' boards and vendor tags.
func _name_zaglebie() -> void:
	for i in _stands.size():
		var shop := Zaglebie.shop(String(_stands[i]["zag"]))
		if not shop.is_empty():
			name_stand(i, String(shop["board"]), String(shop["tag"]))


## The generic stands' kiosks: one MultiMesh per 512 m tile (made again when a stand is named).
func _build_stand_tiles() -> void:
	for t in _stand_tiles:
		t.queue_free()
	_stand_tiles.clear()
	if _world == null or _stand_mesh == null:
		return
	var tiles := {}
	for st in _stands:
		if st["name"] != "":
			continue
		var o: Vector3 = (st["xf"] as Transform3D).origin
		var key := Vector2i(floori(o.x / 512.0), floori(o.z / 512.0))
		if not tiles.has(key):
			tiles[key] = []
		(tiles[key] as Array).append(st["xf"])
	for key: Vector2i in tiles:
		var xfs: Array = tiles[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _stand_mesh
		mm.instance_count = xfs.size()
		var box := AABB((xfs[0] as Transform3D).origin, Vector3.ZERO)
		for k in xfs.size():
			mm.set_instance_transform(k, xfs[k])
			box = box.expand((xfs[k] as Transform3D).origin)
		mm.custom_aabb = box.grow(6.0)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "KebabStands"
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		# A small prop's sun shadow: on High only, as the map's small casters (main.gd _apply_extras).
		mmi.add_to_group("small_casters", true)
		_world.add_child(mmi)
		_stand_tiles.append(mmi)


## Where the stands are (their kiosks), in their order.
func stand_points() -> PackedVector2Array:
	var out := PackedVector2Array()
	for st in _stands:
		out.append(Vector2(st["at"].x, st["at"].z))
	return out


## Loop couriers: each stand's kiosk as [at, yaw] (the counter faces the road), in their order: the
## couriers waiting there at night (city_life.gd).
func stand_frames() -> Array:
	var out: Array = []
	for st in _stands:
		out.append([st["at"], (st["xf"] as Transform3D).basis.get_euler().y])
	return out


## Stand i gets a name board under KEBAB (props.gd named_kebab_stand) and its vendor's tag.
func name_stand(i: int, words: String, tag: String) -> void:
	if i < 0 or i >= _stands.size() or _stands[i]["name"] != "":
		return
	_stands[i]["name"] = words
	_stands[i]["tag"] = tag
	var mi := MeshInstance3D.new()
	mi.name = "NamedStand"
	mi.mesh = Props.named_kebab_stand(words)
	mi.material_override = Models.material()
	mi.add_to_group("small_casters", true)
	(_stands[i]["node"] as Node3D).add_child(mi)
	_build_stand_tiles()


func stand_tag(i: int) -> String:
	return String(_stands[i]["tag"]) if i >= 0 and i < _stands.size() else ""


func tag_stand(i: int, tag: String) -> void:
	if i >= 0 and i < _stands.size():
		_stands[i]["tag"] = tag


# --- places ---------------------------------------------------------------------------

## Where a job place meets the road: a point on the lane graph's centreline near
## the baked door (a connected road if there is one), the road's direction there,
## the side (unit normal) the place is on, and a free spot on the pavement `half` +
## one of `offsets` metres from the centre (no roof over it, no lane under it). If the
## door's own spot has no room, it looks up to 40 m along the road, then across it.
func _kerb(door: Vector2, at: Vector2, half: float, offsets: Array) -> Dictionary:
	# A stand or a pick-up belongs on a street, not up on a bridge.
	var hit := graph.snap(door, 30.0, Vector2.ZERO, true, true)
	if hit.is_empty():
		hit = graph.snap(door, 30.0, Vector2.ZERO, false, true)
	if hit.is_empty():
		return {}
	var e: int = hit[0]
	for flip in [1.0, -1.0]:
		for shift in [0.0, 8.0, -8.0, 16.0, -16.0, 24.0, -24.0, 32.0, -32.0, 40.0, -40.0]:
			var s := clampf(float(hit[2]) + shift, graph.e_s0[e] + 2.0, graph.e_s1[e] - 2.0)
			var centre := graph.point_at(e, s)
			var dir := graph.direction(e, s)
			var right := Vector2(-dir.y, dir.x)
			var side := right if (at - centre).dot(right) >= 0.0 else -right
			side *= flip
			for off in offsets:
				var p: Vector2 = centre + side * (half + float(off))
				var ground: float = map.terrain_height(p.x, p.y)
				# Free pavement: no roof, no bridge deck overhead, no lane.
				if map.top_height(p.x, p.y, 1.8) > ground + 0.5 or not graph.snap(p, 3.0).is_empty():
					continue
				# Cars keep right: on the place's side they drive along `dir` if that side is the right.
				return {"centre": centre, "side": side, "heading": dir if side == right else -dir, "edge": e, "s": s, "spot": p}
	return {}


func _add_stand(p: Dictionary, _mesh: ArrayMesh, world: Node3D) -> void:
	var door: Array = p["door"]
	var half := float(p.get("w", 7.0)) * 0.5
	var k := _kerb(Vector2(door[0], door[1]), Vector2(p["x"], p["z"]), half, [2.4, 1.6, 3.4, 4.4])
	if k.is_empty():
		print("jobs: no room for the kebab stand at %d,%d" % [roundi(float(p["x"])), roundi(float(p["z"]))])
		return
	var spot: Vector2 = k["spot"]
	var side: Vector2 = k["side"]
	var ring2: Vector2 = k["centre"] + side * maxf(half - 2.0, 0.0)
	var ring := Vector3(ring2.x, _road_y(ring2, k["edge"]), ring2.y)
	var at := Vector3(spot.x, map.terrain_height(spot.x, spot.y), spot.y)
	var yaw := atan2(side.x, side.y)  # the counter faces the road
	var node := Node3D.new()
	# Loop MW-2 (parodies.md 6.1): the stand's kiosk is drawn by its tile's MultiMesh
	# (_build_stand_tiles); a named stand gets a mesh of its own (name_stand).
	# Solid: the car stops at the kiosk.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 2.6, 2.1)
	shape.shape = box
	shape.position.y = 1.3
	body.add_child(shape)
	node.add_child(body)
	# The board's glow at night.
	var halo := MeshInstance3D.new()
	halo.mesh = _stand_halo
	halo.material_override = _halo_mat
	halo.position = Vector3(0, 3.9, 0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.visible = false
	halo.add_to_group("night_lights")
	node.add_child(halo)
	world.add_child(node)
	node.global_position = at
	node.rotation.y = yaw
	var marker := _marker(KEBAB_COLOUR, PULL_IN - 1.0)
	world.add_child(marker)
	marker.global_position = ring
	_stands.append({"ring": ring, "at": at, "heading": k["heading"], "node": node, "marker": marker, "cool": false,
			"edge": k["edge"], "s": k["s"], "xf": Transform3D(Basis(Vector3.UP, yaw), at), "name": "", "tag": "",
			"zag": String(p.get("zag", ""))})


func _add_station(p: Dictionary, world: Node3D) -> void:
	var door: Array = p["door"]
	var half := float(p.get("w", 7.0)) * 0.5
	var k := _kerb(Vector2(door[0], door[1]), Vector2(p["x"], p["z"]), half, [1.2, 2.0, 3.0])
	if k.is_empty():
		return
	var spot: Vector2 = k["spot"]
	var side: Vector2 = k["side"]
	var ring2: Vector2 = k["centre"] + side * maxf(half - 2.0, 0.0)
	var ring := Vector3(ring2.x, _road_y(ring2, k["edge"]), ring2.y)
	var person := MeshInstance3D.new()
	person.mesh = Props.person(Color("#3b8f5a"), Color("#2d3442"), true)
	person.material_override = Models.material()
	person.scale = Vector3.ONE * 1.35
	world.add_child(person)
	person.global_position = Vector3(spot.x, map.terrain_height(spot.x, spot.y), spot.y)
	person.rotation.y = atan2(side.x, side.y)
	var marker := _marker(SLOIK_COLOUR, PULL_IN - 1.0)
	world.add_child(marker)
	marker.global_position = ring
	var dest: Dictionary = p if p.has("dest") else CENTRALNY_DEST
	_stations.append({"ring": ring, "at": person.global_position, "heading": k["heading"], "person": person,
			"marker": marker, "cool": false, "edge": k["edge"], "s": k["s"], "name": String(p["name"]),
			"dest": dest.get("dest", "powisle"), "dest_pl": dest.get("dest_pl", "Powiśle"),
			"dest_en": dest.get("dest_en", "Powiśle"), "box": dest.get("box", []), "lo": dest.get("lo", 1000.0),
			"hi": dest.get("hi", 2400.0), "tag": dest.get("tag", "centralny")})


## A słoiki station of the OSM data already stands within 150 m of `at` (a later bake that maps
## Gdańska itself must not get a second one).
func _station_near(at: Vector2) -> bool:
	for st in _stations:
		if _flat(Vector3(at.x, 0.0, at.y), st["ring"]) < 150.0:
			return true
	return false


## A ring on the road: "pull in here" (the stand's own sign and the minimap mark
## the place from afar).
func _marker(colour: Color, radius: float) -> Node3D:
	var root := Node3D.new()
	if not _ring_mats.has(colour):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = colour
		_ring_mats[colour] = m
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		var y := Vector3(0, 0.4, 0)
		# Dashed: every other segment, so it reads as a pull-in bay, not a beacon.
		if i % 2 == 1:
			continue
		for v in [o0 * radius, o1 * radius, o0 * (radius - 0.5), o1 * radius, o1 * (radius - 0.5), o0 * (radius - 0.5)]:
			st.add_vertex(v + y)
	var ring := MeshInstance3D.new()
	ring.mesh = st.commit()
	ring.material_override = _ring_mats[colour]
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	return root


## The road surface at a point beside lane graph edge e: its own deck (loop 3a, R8: never
## another deck over it) or the ground (a street under a bridge stays on the ground).
func _road_y(p: Vector2, e: int) -> float:
	return graph.surface(e, p)


## The district of the address nearest a point ("praga" across the river).
func _district_near(p: Vector2) -> String:
	var best := INF
	var d := ""
	for a in _addresses:
		var dd: float = (a["at"] as Vector2).distance_squared_to(p)
		if dd < best:
			best = dd
			d = a["d"]
	return d


# --- the flow ---------------------------------------------------------------------------

## Loop 3g-2: the kebab's heat now (0..1; police.gd logs it around a pull-over).
func heat() -> float:
	return _heat


func busy() -> bool:
	# Loop 2d-1: a Podwózka ride counts as a job for everything that waits on one.
	return state != State.IDLE or (rides != null and rides.busy()) or (trend != null and trend.busy()) or round_busy()


## PT-15 (2026-11-03): a Podwózka request card is up (rides.gd OFFER, not "busy"): a rival's
## prompt and Halina's first-race call wait for it, so two offers never share the screen.
func ride_offered() -> bool:
	return rides != null and rides.offering()


## Loop jobs-2: the Leżak round-up is on (its card included).
func round_busy() -> bool:
	return roundup != null and roundup.busy()


## Loop 2d-1: a kebab or słoiki job of this script's own is on (rides.gd asks this); loop jobs-2:
## or the Leżak round-up.
func own_busy() -> bool:
	return state != State.IDLE or round_busy()


## Loop MW-4: this script's own job or the "Na czasie" one (its card included) is on: rides.gd
## offers nothing then.
func side_busy() -> bool:
	return own_busy() or (trend != null and trend.state != 0)


func has_target() -> bool:
	if round_busy():
		return roundup.has_target()  # loop jobs-2
	return state == State.DELIVER or _pointing()


## Beta values: the delivered card's NASTĘPNE points at a stand while nothing else is on.
func _pointing() -> bool:
	return state == State.IDLE and next_stand >= 0 and next_stand < _stands.size()


func target_position() -> Vector3:
	if round_busy():
		return roundup.target_position()
	if _pointing():
		return _stands[next_stand]["ring"]
	return _order["ring"]


## Where the car should stop now (stop_assist.gd): the door, the next stand, or the round-up's
## depot to unload.
func stop_spot() -> Vector3:
	if round_busy():
		return roundup.stop_spot()
	if _pointing():
		return _stands[next_stand]["ring"]
	return _order["ring"] if state == State.DELIVER else Vector3.INF


func target_colour() -> Color:
	if round_busy():
		return roundup.target_colour()
	return KEBAB_COLOUR if job == Job.KEBAB or _pointing() else SLOIK_COLOUR


## Nothing else on: no rescue under way, no race, not flying.
func _free() -> bool:
	if flying or missions.has_target():
		return false
	if others_busy.is_valid() and state == State.IDLE and bool(others_busy.call()):
		return false  # story_quests.gd: a questline (boat race, rave...) is on
	if rides != null and rides.busy():
		return false  # loop 2d-1: one activity at a time
	if trend != null and trend.busy():
		return false  # loop MW-4
	if round_busy():
		return false  # loop jobs-2
	return rivals == null or not rivals.busy()


func _process(dt: float) -> void:
	if graph == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	# Loop jobs-2: the courier race and the round-up step here (idle: a match on their state).
	if courier.state != CourierRace.State.IDLE:
		courier.step(dt)
	if roundup != null:
		roundup.step(dt)
	match state:
		State.IDLE:
			_look_for_work()
			_route_tick(dt)
		State.ORDER:
			_order_tick()
		State.DELIVER:
			_deliver_tick(dt)
			_route_tick(dt)
		State.RESULT:
			if _t > RESULT_LIFE or _flat(car.global_position, _result_at) > RESULT_OFF:
				print("jobs: the result card went by itself (%s)" % ("%.0f s" % _t if _t > RESULT_LIFE else "drove off"))
				_release()
	last_usec = Time.get_ticks_usec() - t0


func _look_for_work() -> void:
	_welcome()
	var free := _free()
	_show_places(free)
	if not free:
		if next_stand >= 0:
			# Something else is on now: the pointer to the next stand goes, and its route (unless the
			# other activity has drawn its own since: hud.gd's owner rule).
			print("jobs: the pointer to stand %d went (another activity)" % next_stand)
			next_stand = -1
			_route_off(true)
		return
	var p := car.global_position
	var slow: bool = car.vel.length() < PULL_IN_SPEED
	for i in _stands.size():
		var s := _stands[i]
		var d := _flat(p, s["ring"])
		if s["cool"]:
			s["cool"] = d < 25.0
		elif d < PULL_IN and slow:
			_begin_kebab(i, _orders)
			return
	for st in _stations:
		var d := _flat(p, st["ring"])
		if st["cool"]:
			st["cool"] = d < 25.0
		elif d < PULL_IN and slow:
			_station = st
			_begin_sloik(_orders)
			return


## G12 part 2: the job places the AUTO list may name now ([{group, at (map x, z), name [pl, en],
## colour}]): the kebab stands and słoiki stations while no job, ride, rescue or race is on (the
## helicopter too: the list is for planning), the Leżak depots while they are out (night).
func offer_places() -> Array:
	var out: Array = []
	if state != State.IDLE or missions.has_target() or (rides != null and rides.busy()) \
			or (trend != null and trend.busy()) or round_busy() or (rivals != null and rivals.busy()):
		return out
	for s in _stands:
		var who: String = "Kebab 24h" if s["name"] == "" else String(s["name"]).capitalize()
		out.append({"group": "kebab", "at": Vector2(s["ring"].x, s["ring"].z), "colour": KEBAB_COLOUR,
				"name": ["Kebab · %s" % who, "Kebab · %s" % who]})
	for st in _stations:
		out.append({"group": "sloik", "at": Vector2(st["ring"].x, st["ring"].z), "colour": SLOIK_COLOUR,
				"name": ["Słoiki · %s" % st["name"], "Jars · %s" % st["name"]]})
	if roundup != null and roundup._shown:
		for q: Vector2 in roundup.depot_points():
			out.append({"group": "lezak", "at": q, "colour": roundup.COLOUR,
					"name": ["Leżaki · zbiórka", "Leżak round-up"]})
	return out


## Rings, columns and minimap squares for the job places while nothing else runs.
func _show_places(on: bool, again := false) -> void:
	if on == _places_shown and not again:
		return
	_places_shown = on
	for s in _stands:
		(s["marker"] as Node3D).visible = on
	for st in _stations:
		(st["marker"] as Node3D).visible = on
	var pts := PackedVector2Array()
	var colours := PackedColorArray()
	var shapes := PackedInt32Array()
	if on:
		for s in _stands:
			pts.append(Vector2(s["ring"].x, s["ring"].z))
			colours.append(KEBAB_COLOUR)
			shapes.append(MapIcons.POI_KEBAB)
		for st in _stations:
			pts.append(Vector2(st["ring"].x, st["ring"].z))
			colours.append(SLOIK_COLOUR)
			shapes.append(MapIcons.POI_STATION)
	# The free-ride boat at the start pontoon (boat_race.gd): its mark stays with the places.
	if on and boat_spot != Vector2.INF:
		pts.append(boat_spot)
		colours.append(BOAT_COLOUR)
		shapes.append(MapIcons.POI_BOAT)
	# Loop jobs-2: the Leżak depots at night.
	if roundup != null and roundup._shown and not round_busy():
		for q: Vector2 in roundup.depot_points():
			pts.append(q)
			colours.append(roundup.COLOUR)
			shapes.append(MapIcons.POI_DEPOT)
	hud.set_minimap_pois(pts, colours, shapes)


## Loop jobs-2: the round-up's depots came on or went (night, a job): the minimap squares again.
func depots_shown(_on: bool) -> void:
	if not round_busy():
		_show_places(_places_shown, true)


## Loop jobs-2: the round-up is over: the places' squares at the next look.
func places_dirty() -> void:
	_places_shown = not _free()
	_show_places(not _places_shown)


## Other activities stop offering themselves while a job runs.
func _claim() -> void:
	_show_places(false)
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()


func _release() -> void:
	state = State.IDLE
	job = Job.NONE
	_beacon.visible = false
	hud.hide_card()
	hud.hide_status()
	missions.paused = false
	missions.close()
	for st in _stations:
		(st["person"] as Node3D).visible = true
	_remove_ghost()
	if next_stand < 0:
		_route_off(true)


# --- the route on the minimap (beta values, 2026-11-04) -----------------------------------------

## Walks the minimap's route again from the car now and then (route_line.gd).
func _route_tick(dt: float) -> void:
	if not _route.active():
		return
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	if _route.update(Vector2(car.global_position.x, car.global_position.z), heading, dt):
		hud.set_minimap_route(_route.points, target_colour(), "jobs")
		_route_on = true


## The route to `ring` on lane point (e, s), or (not `reached`, over the river) to node `finish`.
func _route_to(e: int, s: float, ring: Vector3, reached := true, finish := -1) -> void:
	var tail := Vector2(ring.x, ring.z)
	if reached and e >= 0:
		_route.to_lane(e, s, tail)
	elif finish >= 0:
		_route.to_node(finish, tail)
	else:
		_route.clear()
		return
	_route_tick(RouteLine.REFRESH)
	print("jobs: route on the minimap to %d,%d, %d points" % [roundi(ring.x), roundi(ring.z), _route.points.size()])


## The route goes; `hud_too`: off the minimap as well (unless another activity drew one since).
func _route_off(hud_too: bool) -> void:
	_route.clear()
	if _route_on and hud_too:
		hud.clear_minimap_route("jobs")
	_route_on = false


## The delivered card's NASTĘPNE: the stand nearest the car by road (one search from the car's
## lane), its arrow, ring and route until the car pulls in or something else starts.
func point_next_stand() -> int:
	if _stands.is_empty():
		return -1
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	var best := -1
	var best_d := INF
	var dist := PackedFloat32Array()
	if not hit.is_empty():
		dist = graph.distances_from(graph.e_b[int(hit[0])], false)
	for i in _stands.size():
		var s := _stands[i]
		var d := INF
		if not dist.is_empty():
			d = graph.trip(dist, int(hit[0]), float(hit[2]), int(s["edge"]), float(s["s"]))
		if d >= INF:
			d = Vector2(s["ring"].x, s["ring"].z).distance_to(p) * 1.4
		if d < best_d:
			best_d = d
			best = i
	if best < 0:
		return -1
	next_stand = best
	_stands[best]["cool"] = false
	var st := _stands[best]
	_route_to(int(st["edge"]), float(st["s"]), st["ring"])
	var who: String = "Kebab 24h" if st["name"] == "" else String(st["name"]).capitalize()
	hud.toast("Następne zamówienie: %s, %d m" % [who, roundi(best_d)], "Next order: %s, %d m" % [who, roundi(best_d)])
	print("jobs: next order pointer to stand %d (%s), %d m by road" % [best, who, roundi(best_d)])
	return best


# --- kebab -------------------------------------------------------------------------------

## Order n from stand i (the same n always gives the same order). Loop 3h slice 4: `first`, the
## guided first order: a short trip straight on up the stand's street (first_pick).
func _make_kebab_order(i: int, n: int, first := false) -> Dictionary:
	var s := _stands[i]
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7907 + i * 131 + 3
	# Now and then the customer is across the river from the stand.
	var want_across := rng.randf() < 0.3 and not first
	var from := Vector2(s["ring"].x, s["ring"].z)
	var pick := first_pick(i) if first else {}
	# Zagłębie Kebabowe: a shop may send only longer trips (Zestaw Królewski).
	var zag: String = s["zag"]
	var lo := maxf(ORDER_MIN, float(Zaglebie.shop(zag).get("min_road", 0.0)))
	if pick.is_empty():
		pick = _pick_address(s["edge"], s["s"], from, lo, ACROSS_MAX if want_across else ORDER_MAX, rng,
				func(a: Dictionary) -> bool: return want_across == ((a["d"] == "praga") != bool(s["across"])))
	if pick.is_empty():
		pick = _pick_address(s["edge"], s["s"], from, ORDER_MIN, ORDER_MAX, rng, func(_a: Dictionary) -> bool: return true)
	if pick.is_empty():
		return {}
	var across: bool = (pick["d"] == "praga") != bool(s["across"])
	var tag := "praga" if pick["d"] == "praga" else ("office" if pick["office"] else String(pick["d"]))
	# Across the river the customer's line says so; elsewhere any line that fits.
	var l: Array = dialogue.line("kebab_order", tag, across)
	var customer: String = dialogue.notes(l).get("customer", CUSTOMERS[rng.randi() % CUSTOMERS.size()])
	pick["customer"] = customer
	pick["line"] = l
	pick["across"] = across
	pick["stand"] = i
	pick["n"] = n
	# A decent drive takes about this long; the kebab is lukewarm by then.
	pick["fair"] = (25.0 + float(pick["road"]) / 8.0) * Zaglebie.fair(zag, false)
	pick["zag"] = zag
	pick["premium"] = false
	return pick


## An address `lo`-`hi` metres by road from lane point (e, s) that passes `test`,
## picked with `rng`; with its door's ring, the trip length and the way there.
## Loop 3h slice 4: `aim` > 0 looks at every fitting address (up to 400, unshuffled) and returns
## the one whose trip is nearest `aim` m (the guided first order).
func _pick_address(e: int, s: float, from: Vector2, lo: float, hi: float, rng: RandomNumberGenerator, test: Callable,
		aim := 0.0) -> Dictionary:
	# Beta values (2026-11-04): without the off-map links. The player can't drive them (the edge
	# roadworks close every road out), yet ~1 order in 30 counted one: a "1,053 m" trip that was
	# really much longer by the roads on the map, with a clock (and a heat) to match the short one.
	var dist := graph.distances_from(graph.e_b[e], false)
	var list: Array[Dictionary] = []
	for a in _addresses:
		var d: float = (a["door"] as Vector2).distance_to(from)
		if d >= lo * 0.55 and d <= hi and test.call(a):
			list.append(a)
	# Shuffle with the order's own random numbers.
	if aim <= 0.0:
		for k in range(list.size() - 1, 0, -1):
			var j := rng.randi() % (k + 1)
			var t := list[k]
			list[k] = list[j]
			list[j] = t
	var best: Dictionary = {}
	for a in list.slice(0, 400 if aim > 0.0 else 80):
		var hit := graph.snap(a["door"], 30.0)
		if hit.is_empty():
			continue
		var road := graph.trip(dist, e, s, hit[0], hit[2])
		var reached := road < INF
		var finish: int = graph.e_b[hit[0]]
		if not reached:
			# The little streets over the river join the network outside the map: drive
			# to the connected junction nearest the door, then the last stretch.
			finish = graph.nearest_node(a["door"])
			if finish < 0 or dist[finish] >= INF:
				continue
			road = (graph.e_len[e] - s) + dist[finish] + graph.node_pos[finish].distance_to(a["door"]) * 1.3
		if road < lo or road > hi:
			continue
		var out: Dictionary = a.duplicate()
		var door: Vector2 = a["door"]
		var side: Vector2 = ((a["at"] as Vector2) - door).normalized()
		var ring2 := door + side * 2.0
		out["ring"] = Vector3(ring2.x, _road_y(ring2, hit[0]), ring2.y)
		out["road"] = road
		out["edge"] = hit[0]
		out["s"] = hit[2]
		out["reached"] = reached
		out["finish"] = finish
		if aim <= 0.0:
			return out
		if best.is_empty() or absf(road - aim) < absf(float(best["road"]) - aim):
			best = out
	return best


func _begin_kebab(i: int, n: int) -> void:
	var o := _make_kebab_order(i, n, i == pinned)
	if i == pinned:
		pinned = -1
	if o.is_empty():
		hud.toast("Brak zamówień", "No orders right now")
		_stands[i]["cool"] = true
		return
	_orders += 1
	next_stand = -1
	_route_off(true)
	job = Job.KEBAB
	state = State.ORDER
	_t = 0.0
	_order = o
	_go_left = -1
	_said_order = false
	_claim()
	var stand: Node3D = _stands[i]["node"]
	# Loop MW-2: a stand's own vendor lines (zdzich, cienkim, hala, stadium) first.
	var vtag: String = _stands[i]["tag"]
	var who: String = "Kebab 24h" if _stands[i]["name"] == "" else String(_stands[i]["name"]).capitalize()
	dialogue.say(stand, who, "kebab_vendor", vtag, 2.4, KEBAB_COLOUR, 5.2, vtag != "")
	var where := "%s, %s" % [o["customer"], o["name"]]
	var extra := " Across the river (\"basically the centre\")." if o["across"] else ""
	var night := " Night pays ×%.1f." % NIGHT_BONUS if _night() else ""
	var extra_pl := " Za rzeką: „w sumie to centrum”." if o["across"] else ""
	var night_pl := (" Nocą ×%s." % ("%.1f" % NIGHT_BONUS).replace(".", ",")) if _night() else ""
	var zag: Dictionary = Zaglebie.shop(String(_stands[i]["zag"]))
	_craft_t = 0.0
	if bool(zag.get("craft", false)):
		# Zagłębie Kebabowe's craft kebab: the card's two buttons are the choice (not GO / NOT NOW).
		o["craft"] = true
		hud.show_card("ZAMÓWIENIE · ROŻEN · %d m" % roundi(o["road"]),
				"Dla: %s.%s Rzemieślnik kroi ręcznie, z zakwasu: poczekaj %d s, a kebab pójdzie ×%s i wolniej stygnie. Albo weź zwykły.%s" % [
				where, extra_pl, roundi(Zaglebie.CRAFT_WAIT), ("%.1f" % Zaglebie.CRAFT_PAY).replace(".", ","), night_pl],
				PackedStringArray(["POCZEKAM", "ZWYKŁY"]), KEBAB_COLOUR, true, "Craft kebab · %d m" % roundi(o["road"]),
				"Hand-carved, on sourdough: wait %d s and it pays ×%.1f and cools slower. Or take a plain one.%s%s" % [
				roundi(Zaglebie.CRAFT_WAIT), Zaglebie.CRAFT_PAY, extra, night])
	else:
		hud.show_card("ZAMÓWIENIE · KEBAB · %d m" % roundi(o["road"]),
				"Dla: %s.%s Im cieplejszy dojedzie, tym większy napiwek.%s%s" % [where, extra_pl, night_pl,
				(" " + String(zag["set"]) + ": ×%s.") % ("%.2f" % Zaglebie.pay(String(zag["tag"]), false, false)).replace(".", ",")
				if not zag.is_empty() and float(zag["pay"]) > 1.0 else ""],
				PackedStringArray(["GO!", "NOT NOW"]), KEBAB_COLOUR, true, "Kebab order · %d m" % roundi(o["road"]),
				"It cools on the way: the hotter, the bigger the tip.%s%s" % [extra, night])
	print("kebab order %d: stand %d -> %s (%s), %d m by road%s" % [n, i, o["name"], o["customer"], roundi(o["road"]),
			", across the river" if o["across"] else ""])
	# The autopilot answers the craft kebab's card: it waits for the hand-carved one (--craft=plain: no).
	if autopilot and bool(o.get("craft", false)):
		_on_card(1 if craft_plain else 0)
	# Loop jobs-2 (parodies.md 4.3): a courier waiting here may challenge (at night, 1 in 4).
	courier.set_road(float(o["road"]))
	courier.on_order(_stands[i]["at"], o["ring"], n, _night(), int(o["edge"]) if bool(o["reached"]) else -1, float(o["s"]), func() -> void:
		if state == State.ORDER and job == Job.KEBAB:
			_go(), i)


## The order line follows the vendor's; the job goes when the player drives off,
## presses GO, or after a few seconds.
func _order_tick() -> void:
	var at: Vector3 = _stands[_order["stand"]]["ring"] if job == Job.KEBAB else _station["ring"]
	if job == Job.KEBAB and not _said_order and _t > 2.6:
		_said_order = true
		var l: Array = _order["line"]
		if not l.is_empty():
			bubbles.say(_stands[_order["stand"]]["node"], "Kebab 24h", l[0], l[1], 3.5, KEBAB_COLOUR, 5.2)
	if job == Job.KEBAB and _craft_t > 0.0:
		# The craft kebab's wait: done, or the car drove off (then the plain one goes).
		if _t >= _craft_t:
			_order["premium"] = true
			_order["fair"] = float(_order["fair"]) * Zaglebie.CRAFT_FAIR
			_go()
		elif _flat(car.global_position, at) > PULL_IN + 7.0:
			_go()
		return
	var craft := bool(_order.get("craft", false))
	var limit := 4.0 if autopilot else (14.0 if craft else 9.0)
	_count_down(ceili(limit - _t), craft)
	if _flat(car.global_position, at) > PULL_IN + 7.0 or _t > limit:
		_go()


## PT-13 (2026-11-02): the order goes by itself after a few seconds, so the button that will
## happen counts them down ("JEDZIEMY! · 7"; the craft kebab's ZWYKŁY), relabelled once a second.
func _count_down(left: int, craft: bool) -> void:
	if left == _go_left or left < 0:
		return
	_go_left = left
	if craft:
		hud.set_card_button(1, "ZWYKŁY · %d" % left, "PLAIN · %d" % left)
	else:
		hud.set_card_button(0, "JEDZIEMY! · %d" % left, "GO! · %d" % left)


func _go() -> void:
	_craft_t = 0.0
	state = State.DELIVER
	_t = 0.0
	_clock = 0.0
	hud.hide_card()
	var ring: Vector3 = _order["ring"]
	_beacon.waving = true
	_beacon.recolour(KEBAB_COLOUR if job == Job.KEBAB else SLOIK_COLOUR)
	_beacon.place(ring, ARRIVE - 0.5)
	# Beta values: the way there on the minimap (the edge arrow alone points through the blocks).
	_route_to(int(_order["edge"]), float(_order["s"]), ring, bool(_order["reached"]), int(_order["finish"]))
	if job == Job.KEBAB:
		_heat = start_heat
		_beacon.recolour(KEBAB_COLOUR)
		hud.toast("Jedziemy! %s czeka" % _order["customer"], "Go! %s is waiting" % _order["customer"])
	else:
		_jars = JARS - clampi(start_broken, 0, JARS)
		_stress = 0.0
		_have_last = false
		_chat_t = 9.0
		_warn_wait = 0.0
		(_station["person"] as Node3D).visible = false
		_beacon.recolour(SLOIK_COLOUR)
		# Nobody waits at the flat: the passenger rides with you.
		_beacon.place(ring, ARRIVE - 0.5, true, false)
		hud.toast("Jedź płynnie, bo słoiki się tłuką", "Drive smoothly: hard bumps, braking and fast corners break jars")
	_slide = false


func _deliver_tick(dt: float) -> void:
	_clock += dt
	var target: Vector3 = _order["ring"]
	var p := car.global_position
	var d := _flat(p, target)
	var speed: float = car.vel.length()
	if job == Job.KEBAB and not heat_frozen:
		_heat = maxf(0.0, _heat - dt * 0.6 / float(_order["fair"]))
	if d < ARRIVE and speed < ARRIVE_SPEED and not flying:
		_arrive()
		return
	# Loop 2e: [Polish, English].
	var hint := ["", ""]
	if flying:
		hint = ["Wyląduj i weź auto: zamówienie jedzie autem", "Land and take the car: the order rides in the car"]
	elif d > 40.0:
		hint = ["Jedź do pomarańczowego światła", "Head for the orange beacon"] if job == Job.KEBAB \
				else ["Jedź do turkusowego światła", "Head for the teal beacon"]
		if job == Job.KEBAB:
			hint = heat_hint()
	elif d < ARRIVE:
		hint = ["Stań pod drzwiami", "Stop at the door"]
	else:
		hint = ["Stań w kręgu", "Pull up inside the ring"]
	if job == Job.KEBAB:
		var word := "GORĄCY" if _heat >= 0.7 else ("CIEPŁY" if _heat >= 0.4 else "ZIMNY")
		# Loop jobs-2: racing the courier, the rivals' badge and the gap.
		var race: Array = courier.hint()
		if not race.is_empty() and not flying and d > ARRIVE:
			hint = race
		hud.show_status("KEBAB → %s" % _order["name"], "%s %d%%" % [word, roundi(_heat * 100.0)], "%d m" % roundi(d),
				hint[0], 0.0, KEBAB_COLOUR, courier.badge(), {"heat": _heat}, hint[1])
	else:
		_chat_t -= dt
		if _chat_t <= 0.0 and not bubbles.is_talking(car):
			_chat_t = _rng.randf_range(20.0, 32.0)
			dialogue.say(car, _order["customer"], "passenger", "", 4.5, SLOIK_COLOUR, 2.4)
		if _stress > 0.55 and d > ARRIVE:
			hint = ["Spokojnie! Słoiki dzwonią", "Easy! The jars are rattling"]
		hud.show_status("SŁOIKI → %s" % _order["name"], _clock_text(_clock), "%d m" % roundi(d),
				hint[0], _stress, SLOIK_COLOUR, "", {"jars": [_jars, JARS], "shake": clampf(_stress, 0.0, 1.0)}, hint[1])


## Beta values (2026-11-04): the kebab's clock in words [pl, en]: how long it stays hot (the tip's
## top band), then warm (a tip at all), from the heat's own decay (_deliver_tick: 0.6 / fair a
## second). It was a bare "GORĄCY 85 %" that never said how long was left.
func heat_hint() -> Array:
	var rate := 0.6 / maxf(float(_order.get("fair", 60.0)), 1.0)
	if _heat >= 0.7:
		var s := ceili((_heat - 0.7) / rate - 0.01)
		return ["Gorący jeszcze %d s" % s, "Hot for %d s more" % s]
	if _heat >= 0.4:
		var s := ceili((_heat - 0.4) / rate - 0.01)
		return ["Ciepły jeszcze %d s, potem bez napiwku" % s, "Warm for %d s, then no tip" % s]
	return ["Zimny: bez napiwku, kurs się liczy", "Cold: no tip, the fare still counts"]


func _arrive() -> void:
	state = State.RESULT
	_delivered = true
	_result_shown()
	hud.hide_status()
	_remove_ghost()
	# The passenger's chatter stops: the last word is at the door.
	bubbles.hush(car)
	var ring: Vector3 = _order["ring"]
	# The customer (or the passenger, home at last) stands at the door.
	_beacon.waving = false
	_beacon.place(ring, ARRIVE - 0.5, false, true)
	if job == Job.KEBAB:
		_kebab_result()
	else:
		_sloik_result()
	Access.buzz(120, 0.8)


## PT-16: the result card's clock and spot (it goes by itself, see RESULT_LIFE).
func _result_shown() -> void:
	_t = 0.0
	_result_at = car.global_position


func _kebab_result() -> void:
	var hot := _heat >= 0.4
	var road: float = _order["road"]
	var fare := roundi(12.0 + road * 0.015)
	var zag := String(_order.get("zag", ""))
	var tip := roundi(_heat * (10.0 + road * 0.02) * Zaglebie.tip(zag)) if hot else 0
	var bonus := NIGHT_BONUS if _night() else 1.0
	var total := roundi((fare + tip) * bonus * Zaglebie.pay(zag, _night(), bool(_order.get("premium", false))))
	wallet.pay(total, 10 if hot else 0, "kebab")
	_trail(zag)
	# Loop jobs-2: the courier race, if one ran (its +30 zł +30 respect are paid by courier_race.gd).
	var race := courier.finish()
	var race_pl := ""
	var race_en := ""
	if not race.is_empty():
		if bool(race["won"]):
			race_pl = "\nPędzik w tyle: +%d zł, +%d szacunku" % [int(race["zl"]), int(race["respect"])]
			race_en = "\nYou beat the courier: +%d zł, +%d respect" % [int(race["zl"]), int(race["respect"])]
		else:
			race_pl = "\nPędzik był pierwszy. Kebab i tak dojechał"
			race_en = "\nThe courier got there first. The kebab still made it"
	var key := "kebab:%d:%s" % [_order["stand"], _order["name"]]
	var best: float = wallet.best_time(key)
	var record: bool = wallet.record(key, _clock)
	var l: Array = dialogue.say(_beacon, _order["customer"], "kebab_hot" if hot else "kebab_cold", "", 5.0,
			KEBAB_COLOUR if hot else Color("#7fb8de"), 3.6)
	var quote := "„%s”\n" % l[0] if not l.is_empty() else ""
	var quote_en := "%s\n" % l[1] if not l.is_empty() else ""
	var money := "Fare %d zł + tip %d zł%s = %d zł · wallet %s" % [fare, tip,
			(" · night ×%.1f" % NIGHT_BONUS) if bonus > 1.0 else "", total, _money(wallet.zl)]
	var money_pl := "Kurs %d zł + napiwek %d zł%s = %d zł · w portfelu %s" % [fare, tip,
			(" · noc ×%s" % ("%.1f" % NIGHT_BONUS).replace(".", ",")) if bonus > 1.0 else "", total, _money(wallet.zl)]
	var times := "%s at %d%% heat%s" % [_clock_text(_clock), roundi(_heat * 100.0),
			" · new best!" if record and best > 0.0 else (" · best %s" % _clock_text(best) if best > 0.0 else "")]
	var times_pl := "%s, ciepło %d%%%s" % [_clock_text(_clock), roundi(_heat * 100.0),
			" · nowy rekord!" if record and best > 0.0 else (" · rekord %s" % _clock_text(best) if best > 0.0 else "")]
	hud.show_card("DOWIEZIONE · " + ("WCIĄŻ GORĄCY" if _heat >= 0.7 else ("CIEPŁY" if hot else "ZIMNY")),
			"%s%s, %s: %s\n%s%s" % [quote, _order["customer"], _order["name"], times_pl, money_pl, race_pl],
			PackedStringArray(["OK", "NASTĘPNE"]), KEBAB_COLOUR if hot else Color("#7fb8de"), true,
			"Delivered · " + ("still hot" if _heat >= 0.7 else ("warm" if hot else "cold")),
			"%s%s · %s%s" % [quote_en, times, money, race_en])
	print("kebab delivered: %s in %.1f s, heat %d%%, %s, paid %d zł (wallet %d zł)" % [_order["name"], _clock,
			roundi(_heat * 100.0), "hot" if hot else "cold", total, wallet.zl])


## Szlak Szpili: one delivery from each of the Zagłębie's five shops pays TRAIL_ZL once.
func _trail(zag: String) -> void:
	if Zaglebie.shop(zag).is_empty():
		return
	var r: Array = Zaglebie.trail_add(String(wallet.keep.get(Zaglebie.KEEP_TRAIL, "")), zag)
	wallet.keep[Zaglebie.KEEP_TRAIL] = r[0]
	if bool(r[1]):
		wallet.pay(Zaglebie.TRAIL_ZL, Zaglebie.TRAIL_RESPECT)
		hud.toast("SZLAK SZPILI: pięć kebabów, pięć zagłębi! +%d zł" % Zaglebie.TRAIL_ZL,
				"Skewer Trail: five kebabs from five shops! +%d zł" % Zaglebie.TRAIL_ZL)
		print("jobs: Szlak Szpili complete")


## The Zagłębie's welcome line, once, when the car first comes near Kino Femina.
func _welcome() -> void:
	if _welcomed or _femina == Vector2.INF or _flat(car.global_position, Vector3(_femina.x, 0.0, _femina.y)) > Zaglebie.WELCOME_R:
		return
	_welcomed = true
	if int(wallet.keep.get(Zaglebie.KEEP_SEEN, 0)) > 0:
		return
	wallet.keep[Zaglebie.KEEP_SEEN] = 1
	var l: Array = dialogue.line("zaglebie", "welcome")
	if not l.is_empty():
		hud.toast(l[0], l[1])


# --- słoiki ------------------------------------------------------------------------------

func _begin_sloik(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 3571 + 11
	var from := Vector2(_station["ring"].x, _station["ring"].z)
	var box: Array = _station["box"]
	var dest: String = _station["dest"]
	var pick := _pick_address(_station["edge"], _station["s"], from, _station["lo"], _station["hi"], rng, func(a: Dictionary) -> bool:
		if a["office"]:
			return false
		if box.is_empty():
			return a["d"] == dest
		var at: Vector2 = a["at"]
		return at.x >= box[0] and at.y >= box[1] and at.x <= box[2] and at.y <= box[3])
	if pick.is_empty():
		hud.toast("Nikt nie potrzebuje podwózki", "Nobody needs a lift right now")
		_station["cool"] = true
		_station = {}
		return
	_orders += 1
	next_stand = -1
	_route_off(true)
	job = Job.SLOIK
	state = State.ORDER
	_t = 0.0
	_order = pick
	_go_left = -1
	_order["customer"] = NEWCOMERS[rng.randi() % NEWCOMERS.size()]
	_claim()
	var person: Node3D = _station["person"]
	dialogue.say(person, _order["customer"], "sloik_start", _station["tag"], 4.0, SLOIK_COLOUR, 2.9)
	hud.show_card("SŁOIKI · NIEDZIELNY WIECZÓR",
			"%s wraca od mamy z %d słoikami. Cel: %s, %s (%d m). Dziury, hamowanie i szybkie zakręty tłuką słoiki." % [
			_order["customer"], JARS, _order["name"], _station["dest_pl"], roundi(_order["road"])],
			PackedStringArray(["GO!", "NOT NOW"]), SLOIK_COLOUR, true, "The słoiki run · Sunday evening",
			"Back from home with %d of mum's jars, to a rented flat in %s. Bumps, braking and fast corners break jars." % [JARS, _station["dest_en"]])
	print("słoiki run %d: %s to %s, %d m by road" % [n, _order["customer"], _order["name"], roundi(_order["road"])])


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _step(dt: float) -> void:
	_bump_wait = maxf(0.0, _bump_wait - dt)
	_warn_wait = maxf(0.0, _warn_wait - dt)
	if job != Job.SLOIK or state != State.DELIVER or dt <= 0.0:
		_have_last = false
		return
	var v: float = car.forward_speed
	var yaw := car.rotation.y
	if not _have_last:
		_last_v = v
		_last_yaw = yaw
		_have_last = true
		return
	var a_long: float = (v - _last_v) / dt
	var lat := absf(v * angle_difference(_last_yaw, yaw) / dt)
	_last_v = v
	_last_yaw = yaw
	# A crash shows as a huge jump here; the bump has already counted it.
	if absf(a_long) < 60.0:
		var k := 1.0 - exp(-dt / 0.12)
		_brake_s = lerpf(_brake_s, maxf(0.0, -a_long * signf(v)), k)
		_lat_s = lerpf(_lat_s, minf(lat, 60.0), k)
	_stress += dt * (maxf(0.0, _brake_s - BRAKE_FREE) / 10.0 + maxf(0.0, _lat_s - CORNER_FREE) / 10.0)
	_stress = maxf(0.0, _stress - dt * 0.12)
	_check_jars()


## v0.9: the jars in the boot (sfx.gd): 0 = they clink, 1 = one broke.
signal jars(kind: int)


func _on_bump(_collider: Object, speed: float) -> void:
	if job == Job.SLOIK and state == State.DELIVER and _bump_wait <= 0.0 and _jars > 0:
		jars.emit(0)
	if job != Job.SLOIK or state != State.DELIVER or _bump_wait > 0.0 or speed < BUMP_FREE:
		return
	_bump_wait = 0.4
	_stress += (speed - BUMP_FREE) / 5.0
	_check_jars()


func _check_jars() -> void:
	var broke := false
	while _stress >= 1.0 and _jars > 0:
		_jars -= 1
		_stress -= 0.75
		broke = true
	if _jars == 0:
		_stress = minf(_stress, 0.99)
	if broke:
		print("słoiki: a jar broke at %.1f s, %d/%d left" % [_clock, _jars, JARS])
		jars.emit(1)
		Access.buzz(90, 0.9)
		dialogue.say(car, _order["customer"], "sloik_crash", "", 3.5, FAIL_COLOUR, 2.4)
		hud.toast("Trzask! Pękł słoik · zostało %d z %d" % [_jars, JARS], "Crash! A jar broke · %d of %d left" % [_jars, JARS])
		_warn_wait = 3.0
		_chat_t = maxf(_chat_t, 8.0)
	elif _stress > 0.6 and _warn_wait <= 0.0 and _jars > 0:
		_warn_wait = 7.0
		jars.emit(0)
		dialogue.say(car, _order["customer"], "sloik_bump", "", 2.5, Color("#ffb05a"), 2.4)
		Access.buzz(40, 0.4)


func _sloik_result() -> void:
	var intact := _jars
	var group := "sloik_done" if intact >= 3 else "sloik_broken"
	var pay := SLOIK_BASE + SLOIK_PER_JAR * intact
	wallet.pay(pay, 30 if intact == JARS else 0, "sloik")
	var best: float = wallet.best_time("sloik")
	var record: bool = intact == JARS and wallet.record("sloik", _clock)
	var l: Array = dialogue.say(_beacon, _order["customer"], group, "all" if intact == JARS else "some", 5.0,
			SLOIK_COLOUR if intact >= 3 else FAIL_COLOUR, 3.6)
	var quote := "„%s”\n" % l[0] if not l.is_empty() else ""
	var quote_en := "%s\n" % l[1] if not l.is_empty() else ""
	var times := _clock_text(_clock)
	var times_pl := times
	if record and best > 0.0:
		times += " · new best!"
		times_pl += " · nowy rekord!"
	elif best > 0.0:
		times += " · best with every jar %s" % _clock_text(best)
		times_pl += " · rekord z kompletem %s" % _clock_text(best)
	hud.show_card("DOWIEZIONE · %d/%d SŁOIKÓW" % [intact, JARS],
			"%s%s, %s: %s\nKurs %d zł + %d × %d zł za słoiki = %d zł · w portfelu %s" % [quote, _order["customer"], _order["name"],
			times_pl, SLOIK_BASE, intact, SLOIK_PER_JAR, pay, _money(wallet.zl)],
			PackedStringArray(["OK"]), SLOIK_COLOUR if intact >= 3 else FAIL_COLOUR, true, "Delivered · %d/%d jars" % [intact, JARS],
			"%s%s · fare %d zł + %d jars × %d zł = %d zł" % [quote_en, times, SLOIK_BASE, intact, SLOIK_PER_JAR, pay])
	print("słoiki delivered: %s in %.1f s, %d/%d jars, paid %d zł (wallet %d zł)" % [_order["name"], _clock, intact, JARS,
			pay, wallet.zl])


# --- cards, giving up ------------------------------------------------------------------------

func _on_card(index: int) -> void:
	match state:
		State.ORDER:
			if bool(_order.get("craft", false)):
				# Craft kebab: POCZEKAM (0) waits for the hand-carved one, ZWYKŁY (1) goes at once.
				if index == 0 and _craft_t <= 0.0:
					_craft_t = _t + Zaglebie.CRAFT_WAIT
					hud.hide_card()
					hud.toast("Rzemieślnik kroi… %d s" % roundi(Zaglebie.CRAFT_WAIT), "Carving by hand… %d s" % roundi(Zaglebie.CRAFT_WAIT))
				elif index == 1:
					_craft_t = 0.0
					_go()
			elif index == 0:
				_go()
			else:
				# Not now: the place waits until the car has driven off.
				if job == Job.KEBAB:
					_stands[_order["stand"]]["cool"] = true
				else:
					_station["cool"] = true
				bubbles.hush(_stands[_order["stand"]]["node"] if job == Job.KEBAB else _station["person"])
				courier.cancel()
				_release()
		State.RESULT:
			# Beta values: the delivered kebab card's NASTĘPNE points at the nearest stand.
			var next := index == 1 and job == Job.KEBAB and _delivered
			_release()
			if next:
				point_next_stand()


## Loop jobs-2: key L or the ŚCIGAJ button takes the courier's challenge (false when there is none).
func flash() -> bool:
	return courier != null and courier.accept()


## Keyboard: M answers a job card's first button (GO, OK), K its second (NOT NOW).
## Returns false when no job card is up.
func primary() -> bool:
	if round_busy():
		return roundup.primary()  # loop jobs-2
	if state == State.ORDER or state == State.RESULT:
		_on_card(0)
		return true
	return false


func secondary() -> bool:
	if round_busy():
		return roundup.secondary()
	if state == State.ORDER or (state == State.RESULT and _delivered and job == Job.KEBAB):
		_on_card(1)
		return true
	return false


func _abandon() -> void:
	state = State.RESULT
	_delivered = false
	_result_shown()
	courier.cancel()
	hud.hide_status()
	_beacon.visible = false
	_remove_ghost()
	if job == Job.KEBAB:
		hud.show_card("ZAMÓWIENIE PRZEPADŁO", "%s (%s) się nie dowie. Gołębie z placu Defilad miały ucztę." % [
				_order["customer"], _order["name"]], PackedStringArray(["OK"]), FAIL_COLOUR, true, "Order dropped",
				"%s at %s will never know. The pigeons on Plac Defilad had a feast." % [_order["customer"], _order["name"]])
	else:
		hud.show_card("KURS PRZERWANY", "%s: taksówka. Ze słoikami. Mama już wie." % _order["customer"],
				PackedStringArray(["OK"]), FAIL_COLOUR, true, "Run abandoned",
				"%s took a taxi. With the jars. Mum has been told." % _order["customer"])


# --- testing aids --------------------------------------------------------------------------

## --kebab=N: puts the car in stand (N mod stands)'s ring and starts order N.
# --- loop 3h slice 4: the guided first order (first10.gd) ----------------------------------

## The stand nearest FIRST_STAND (the Marszałkowska × Świętokrzyska corner), or -1 (none within
## 120 m).
func first_stand() -> int:
	var best := -1
	var best_d := 120.0
	for i in _stands.size():
		var d := Vector2(_stands[i]["at"].x, _stands[i]["at"].z).distance_to(FIRST_STAND)
		if d < best_d:
			best_d = d
			best = i
	return best


## The guided first order's door from stand `i`: a door on FIRST_STREET (the stand's own street:
## no turn to find), the trip nearest FIRST_ROAD m on from the stand's lane (150-600 m by road, no
## turning round); any door in that reach if the street has none; {} if none at all.
func first_pick(i: int) -> Dictionary:
	if i < 0 or i >= _stands.size():
		return {}
	var s := _stands[i]
	var from := Vector2(s["ring"].x, s["ring"].z)
	var street := func(a: Dictionary) -> bool:
		return String(a["name"]).begins_with(FIRST_STREET) and a["d"] != "praga"
	var lo := FIRST_ROAD - 150.0
	var hi := FIRST_ROAD + 300.0
	var pick := _pick_address(s["edge"], s["s"], from, lo, hi, _rng, street, FIRST_ROAD)
	if pick.is_empty():
		pick = _pick_address(s["edge"], s["s"], from, lo, hi, _rng, func(a: Dictionary) -> bool: return a["d"] != "praga", FIRST_ROAD)
	print("jobs: the guided first order from stand %d: %s" % [i,
			"%s, %d m by road" % [pick["name"], roundi(float(pick["road"]))] if not pick.is_empty() else "none in reach"])
	return pick


## The next order from stand `i` is the guided first one (first10.gd).
func pin_first(i: int) -> void:
	pinned = i


## --first10: the car at stand `i` and its guided first order at once. False if none came.
func start_first(i: int) -> bool:
	if i < 0 or i >= _stands.size() or state != State.IDLE:
		return false
	pin_first(i)
	_put_car(_stands[i])
	_begin_kebab(i, _orders)
	return state == State.ORDER


## Kebab orders made since the start (the guide's "order" beat).
func orders_started() -> int:
	return _orders


## The ring of stand `i` (Vector3.INF if none): the guide's pointer.
func stand_ring(i: int) -> Vector3:
	return _stands[i]["ring"] if i >= 0 and i < _stands.size() else Vector3.INF


func start_kebab(n: int) -> bool:
	if _stands.is_empty():
		return false
	var i := posmod(n, _stands.size())
	_put_car(_stands[i])
	_begin_kebab(i, n)
	return state == State.ORDER


## --sloik: puts the car at station `station` (0 Centralny, 1 Gdański) and starts the run (`broken` jars already gone).
func start_sloik(broken := 0, station := 0) -> bool:
	if _stations.is_empty():
		return false
	_station = _stations[posmod(station, _stations.size())]
	start_broken = broken
	_put_car(_station)
	_begin_sloik(0)
	return state == State.ORDER


func _put_car(place: Dictionary) -> void:
	var ring: Vector3 = place["ring"]
	var heading: Vector2 = place["heading"]
	car.global_position = ring
	car.rotation.y = atan2(-heading.x, -heading.y)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()


## The autopilot drives the job's route (returns true while it does): on a ghost
## driver along the lane graph, then straight to the door's ring.
func drive_player() -> bool:
	if roundup != null and roundup.drive_player():
		return true  # loop jobs-2
	if not autopilot or state != State.DELIVER:
		return false
	var target: Vector3 = _order["ring"]
	if _ghost == null and not _slide:
		_start_ghost()
		if _ghost == null:
			_slide = true
	if _ghost != null:
		if _ghost.arrived or _flat(_ghost.pos, target) < 22.0:
			_remove_ghost()
			_slide = true
		else:
			# Stuck behind a knot of cars (the autopilot car ghosts anyway): slip through.
			_stall = _stall + get_process_delta_time() if _ghost.v < 0.5 else 0.0
			if _stall > 4.0:
				_stall = 0.0
				_ghost.squeeze = 3.0
			_follow(_ghost.pos, _ghost.yaw, _ghost.v)
			return true
	var to := Vector3(target.x - car.global_position.x, 0.0, target.z - car.global_position.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	if d > 0.5:
		var dt := get_process_delta_time()
		car.global_position += to / d * minf(d, 12.0 * dt)
		car.rotation.y = atan2(-to.x, -to.z)
	return true


func _start_ghost() -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		hit = graph.snap(p, 60.0, Vector2.ZERO, true)
	if hit.is_empty():
		return
	# The door's road, or (over the river) the connected junction nearest to it.
	var finish: int = _order["finish"]
	_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	# Kebabs go fast; mum's jars go gently.
	_ghost.speed_factor = 1.3 if job == Job.KEBAB else 0.95
	_ghost.accel_factor = 1.5 if job == Job.KEBAB else 0.9
	traffic.race_to(_ghost, finish, graph.distances_to(finish, INF, false))


func _remove_ghost() -> void:
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null


func _follow(at: Vector3, yaw: float, speed: float) -> void:
	car.collision_mask = 0
	car.global_position = at
	car.rotation.y = yaw
	car.vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


# --- helpers ---------------------------------------------------------------------------------

func _night() -> bool:
	return tod != null and tod.mode == 2


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _clock_text(seconds: float) -> String:
	var tenths := maxi(0, int(seconds * 10.0))
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out + " zł"
