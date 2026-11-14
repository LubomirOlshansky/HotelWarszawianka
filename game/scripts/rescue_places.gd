extends RefCounted
## Where the rescue line's people wait and where they are taken: the places of each kind (the roof
## of a named building, a named street, the Vistula's beaches, shore and sandbars, a park or a
## square), the Łazienki peacock's roof and the hospitals, all from the baked map data (landmarks,
## roads and pois in centrum.json). missions.gd builds one in `setup` and picks its calls from it;
## cassettes.gd asks it for a roof's spot (`roof_spot`), and check_water, check_edge and
## check_landmarks ask it what the rescue line would find.
##
## It was the second half of missions.gd until the rescue line's move to the activity kit
## (tech-debt TD-1, step M0): the activity keeps the calls, the run and the result, this keeps
## the places, unchanged.

const MapBuilder := preload("res://scripts/map_builder.gd")

enum Kind { STREET, ROOF, RIVER, PARK }

const MIN_ROOF := 20.0       # a roof rescue is at least this high above the street
## A rescue roof named after a real chain shows our parody instead (found 2026-11-01): lower-case
## fragment of the OSM name, then the name the player reads. The landmark keeps its OSM name as the key.
const ROOF_PARODIES := {"puro": "Hotel Piure", "caffè nero": "Green Caffè Nerwo", "caffe nero": "Green Caffè Nerwo"}
const ROOF_LOW := 6.0        # cassettes.gd: a roof for a cassette is at least this high
const OPEN_RADIUS := 4.5     # street spots need this much open sky for the helicopter
## Map north: rescue spots keep this far inside the map's outline (map_builder.gd `in_map`; it was
## the bounding box shrunk by as much, which let a spot fall in the corner left outside).
const EDGE_PAD := 40.0
## DEMO 6.3: the Łazienki peacock. Łazienki itself lies just south of the demo map; its peacocks
## wander north over Agrykola and Ujazdów, so one ends up on a roof by Park Ujazdowski: the first of
## these buildings with a roof the helicopter can land on (else the nearest roof rescue within
## PEACOCK_NEAR of PEACOCK_ANCHOR, map metres). A roof call within PEACOCK_REACH of the player
## offers the peacock first, once per session (missions.gd).
const PEACOCK_ROOFS := ["Zamek Ujazdowski", "Główna Biblioteka Lekarska im. Stanisława Konopki",
		"Instytut Teatralny im. Z. Raszewskiego", "Laboratorium"]
const PEACOCK_ANCHOR := Vector2(450.0, 1620.0)
const PEACOCK_NEAR := 700.0
const PEACOCK_REACH := 2600.0
const PEACOCK_NAME := "Pan Paw"

## The map the places are found on: its heights, roofs, outline and open sky.
var map: Node3D
## Kind -> places: {kind, name, short, text, pos, heli, child}.
var by_kind := {}
## Landmark name -> its outlines (PackedVector2Array each), for `roof_spot`.
var outlines := {}
## The peacock's call (a ROOF place with "peacock": true), {} if no roof near Ujazdów fits.
var peacock: Dictionary = {}
var hospitals: Array[Dictionary] = []
var road_points := PackedVector2Array()
var road_names := PackedStringArray()


func _init() -> void:
	for k: int in Kind.values():
		by_kind[k] = []


## The nearest hospital; the children's hospital takes only children.
func hospital_for(place: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for h in hospitals:
		if h["children"] and not place["child"]:
			continue
		if best.is_empty() or flat(place["pos"], h["pos"]) < flat(place["pos"], best["pos"]):
			best = h
	return best if not best.is_empty() else hospitals[0]


# --- finding places -------------------------------------------------------------

## The name a roof is shown under: the parody when the OSM name holds a real chain.
static func roof_shown(name: String) -> String:
	var low := name.to_lower()
	for frag: String in ROOF_PARODIES:
		if low.contains(frag):
			return ROOF_PARODIES[frag]
	return name


func find_roofs(landmarks: Array) -> void:
	var best := {}
	for l in landmarks:
		var name: String = l["name"]
		var poly := _pts(l["p"])
		if not outlines.has(name):
			outlines[name] = []
		(outlines[name] as Array).append(poly)
		var spot := flat_roof(poly)
		if spot == Vector3.INF or (best.has(name) and (best[name]["pos"] as Vector3).y >= spot.y):
			continue
		var up := roundi(spot.y - map.ground_height(spot.x, spot.z))
		var shown := roof_shown(name)
		best[name] = {"kind": Kind.ROOF, "name": name, "short": "roof of " + shown, "pos": spot, "heli": true, "child": false,
				"short_pl": "dach: " + shown, "gloss": "Someone is stuck on a roof %d m up: helicopter only." % up,
				"text": "Someone is stranded on the roof of %s, %d m up. Only the helicopter can reach them." % [shown, up],
				"text_pl": "Ktoś utknął na dachu: %s, %d m nad ulicą. Dotrze tylko helikopter." % [shown, up]}
	by_kind[Kind.ROOF].append_array(best.values())


## DEMO 6.3: the peacock's roof (see PEACOCK_ROOFS); {} when none fits.
func find_peacock() -> void:
	var roof := ""
	var spot := Vector3.INF
	for name in PEACOCK_ROOFS:
		spot = roof_spot(name)
		if spot != Vector3.INF:
			roof = name
			break
	if spot == Vector3.INF:
		var best := PEACOCK_NEAR
		for p: Dictionary in by_kind[Kind.ROOF]:
			var d := Vector2(p["pos"].x, p["pos"].z).distance_to(PEACOCK_ANCHOR)
			if d < best:
				best = d
				roof = p["name"]
				spot = p["pos"]
	if spot == Vector3.INF:
		return
	var up := roundi(spot.y - map.ground_height(spot.x, spot.z))
	roof = roof_shown(roof)
	peacock = {"kind": Kind.ROOF, "name": PEACOCK_NAME, "short": "peacock on " + roof, "pos": spot, "heli": true,
			"child": false, "peacock": true, "short_pl": "paw na dachu: " + roof,
			"gloss": "A peacock escaped from Łazienki and sits on a roof %d m up: helicopter only." % up,
			"text": "A peacock has escaped from Łazienki and is strutting on the roof of %s, %d m up. Only the helicopter can reach it." % [roof, up],
			"text_pl": "Paw uciekł z Łazienek i paraduje po dachu: %s, %d m nad ulicą. Dotrze tylko helikopter." % [roof, up]}


## The first-10 polish (cassettes.gd): the roof spot of the landmark `name`: the rescue's own pick
## (its highest flat spot), else the highest flat spot at least ROOF_LOW m up (a roof too low for a
## rescue, like the University Library's garden roof); Vector3.INF if it has none.
func roof_spot(name: String) -> Vector3:
	for p: Dictionary in by_kind.get(Kind.ROOF, []):
		if p["name"] == name:
			return p["pos"]
	var best := Vector3.INF
	for poly: PackedVector2Array in outlines.get(name, []):
		var spot := flat_roof(poly, ROOF_LOW)
		if spot != Vector3.INF and (best == Vector3.INF or spot.y > best.y):
			best = spot
	return best


## The highest spot on a building's roof that is flat enough to land on (the
## cells around it within a metre of it), or Vector3.INF.
func flat_roof(poly: PackedVector2Array, min_up := MIN_ROOF) -> Vector3:
	if poly.size() < 3:
		return Vector3.INF
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var cell := MapBuilder.ROOF_CELL
	var best := Vector3.INF
	var best_h := -INF
	var z := lo.y + cell * 0.5
	while z < hi.y:
		var x := lo.x + cell * 0.5
		while x < hi.x:
			var p := Vector2(x, z)
			var h: float = map.roof_height(x, z)
			if h > best_h and map.in_map(p, -EDGE_PAD) and Geometry2D.is_point_in_polygon(p, poly) \
					and h - map.ground_height(x, z) >= min_up and _is_flat(x, z, h, cell):
				best_h = h
				best = Vector3(x, h, z)
			x += cell
		z += cell
	return best


func _is_flat(x: float, z: float, h: float, cell: float) -> bool:
	for j in range(-1, 2):
		for i in range(-1, 2):
			if absf(map.roof_height(x + i * cell, z + j * cell) - h) > 1.0:
				return false
	return true


## One spot per named street: the open point nearest the middle of its longest piece.
func find_streets(roads: Array) -> void:
	var best := {}
	for r in roads:
		var name: String = r["name"]
		if name == "" or r["k"] == "service":
			continue
		var poly := _pts(r["p"])
		var length := 0.0
		for i in poly.size() - 1:
			length += poly[i].distance_to(poly[i + 1])
		if best.has(name) and float(best[name][0]) >= length:
			continue
		var s := 0.0
		while s <= length * 0.5:
			var spot := Vector3.INF
			for along in [length * 0.5 + s, length * 0.5 - s]:
				var p := _point_along(poly, along)
				if _is_open(p.x, p.y):
					spot = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
					break
			if spot != Vector3.INF:
				best[name] = [length, spot]
				break
			s += 6.0
	for name in best:
		var at := "at" if name.begins_with("Plac") or name.begins_with("Rondo") else "on"
		by_kind[Kind.STREET].append({"kind": Kind.STREET, "name": name, "short": name, "pos": best[name][1],
				"heli": false, "child": false, "short_pl": name, "gloss": "A cyclist is hurt: the car or the helicopter will do.",
				"text": "A cyclist is hurt %s %s. The car or the helicopter will do." % [at, name],
				"text_pl": "Ranny rowerzysta: %s. Wystarczy auto albo helikopter." % name})


func find_pois(pois: Array) -> void:
	for p in pois:
		var kind: String = p["k"]
		# The side jobs' and easter eggs' places (kebab stands, addresses...) are not calls.
		if not kind in ["hospital", "beach", "shore", "sandbar", "park", "square"]:
			continue
		var name: String = p["name"]
		var x := float(p["x"])
		var z := float(p["z"])
		if kind == "hospital":
			var door: Array = p["door"]
			var spot := _open_near(float(door[0]), float(door[1]), 40.0)
			if spot != Vector3.INF:
				hospitals.append({"name": name, "pos": spot, "children": name.to_lower().contains("dzieci")})
			continue
		var spot := _open_near(x, z, 24.0)
		if spot == Vector3.INF:
			continue
		var place := {"name": name, "pos": spot, "heli": false, "child": false}
		match kind:
			"beach":
				place["kind"] = Kind.RIVER
				if name != "":
					place["short"] = name + " beach"
					place["short_pl"] = "plaża " + name
					place["gloss"] = "A swimmer is in trouble on a Vistula beach."
					place["text"] = "A swimmer is in trouble at %s, the beach on the Vistula." % name
					place["text_pl"] = "Pływak w tarapatach: plaża %s nad Wisłą." % name
				else:
					place["short"] = "Vistula beach"
					place["short_pl"] = "plaża nad Wisłą"
					place["gloss"] = "A swimmer is in trouble on a Vistula beach."
					place["text"] = "A swimmer is in trouble on a Vistula beach near %s." % nearest_road(x, z)
					place["text_pl"] = "Pływak w tarapatach na plaży nad Wisłą (okolice: %s)." % nearest_road(x, z)
			"shore":
				place["kind"] = Kind.RIVER
				place["short"] = "Vistula shore"
				place["short_pl"] = "brzeg Wisły"
				place["gloss"] = "Someone slipped on the Vistula shore: car or helicopter."
				place["text"] = "Someone slipped on the Vistula shore near %s. The car or the helicopter will do." % nearest_road(x, z)
				place["text_pl"] = "Ktoś poślizgnął się na brzegu Wisły (okolice: %s). Wystarczy auto albo helikopter." % nearest_road(x, z)
			"sandbar":
				place["kind"] = Kind.RIVER
				place["heli"] = true
				place["short"] = "Vistula sandbar"
				place["short_pl"] = "łacha na Wiśle"
				place["gloss"] = "Someone is stranded on a Vistula sandbar: helicopter only."
				place["text"] = "Someone is stranded on a sandbar in the Vistula near %s. Only the helicopter can reach them." % nearest_road(x, z)
				place["text_pl"] = "Ktoś utknął na łasze na Wiśle (okolice: %s). Dotrze tylko helikopter." % nearest_road(x, z)
			"park":
				place["kind"] = Kind.PARK
				place["child"] = true
				place["short"] = name
				place["short_pl"] = name
				place["text"] = "A child fell off a climbing frame in %s." % name
				place["text_pl"] = "Dziecko spadło z drabinek: %s." % name
				place["gloss"] = "A child fell off a climbing frame."
			"square":
				place["kind"] = Kind.PARK
				place["short"] = name
				place["short_pl"] = name
				place["text"] = "A tourist fainted at %s." % name
				place["text_pl"] = "Turystka zemdlała: %s." % name
				place["gloss"] = "A tourist fainted."
			_:
				continue
		by_kind[place["kind"]].append(place)


## Open sky: no building within OPEN_RADIUS, so the helicopter can come down too.
func _is_open(x: float, z: float) -> bool:
	return map.in_map(Vector2(x, z), -EDGE_PAD) and map.top_height(x, z, OPEN_RADIUS) <= map.ground_height(x, z) + 1.5


## The point itself if it's open, else the nearest open point within `reach` metres.
func _open_near(x: float, z: float, reach: float) -> Vector3:
	var r := 0.0
	while r <= reach:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * k / steps
			var px := x + cos(a) * r
			var pz := z + sin(a) * r
			if _is_open(px, pz):
				return Vector3(px, map.ground_height(px, pz), pz)
		r += 4.0
	return Vector3.INF


func collect_road_names(roads: Array) -> void:
	for r in roads:
		if r["name"] == "" or r["k"] == "service":
			continue
		var flat_pts: Array = r["p"]
		for i in range(0, flat_pts.size() - 1, 2):
			road_points.append(Vector2(flat_pts[i], flat_pts[i + 1]))
			road_names.append(r["name"])


func nearest_road(x: float, z: float) -> String:
	var best := INF
	var name := "the river"
	var p := Vector2(x, z)
	for i in road_points.size():
		var d := p.distance_squared_to(road_points[i])
		if d < best:
			best = d
			name = road_names[i]
	return name


# --- helpers --------------------------------------------------------------------

func _point_along(poly: PackedVector2Array, s: float) -> Vector2:
	for i in poly.size() - 1:
		var seg := poly[i].distance_to(poly[i + 1])
		if s <= seg and seg > 0.0:
			return poly[i].lerp(poly[i + 1], s / seg)
		s -= seg
	return poly[poly.size() - 1]


func _pts(flat_pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat_pts.size() - 1, 2):
		out.append(Vector2(flat_pts[i], flat_pts[i + 1]))
	return out


## The distance in plan (metres) between two points.
static func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
