extends SceneTree
## The museum and Plac Piłsudskiego loop (2026-10-31): the landmarks built in code at Muzeum
## Narodowe and on Plac Piłsudskiego's edges, checked headless from the committed map data alone
## (map/centrum.json; no terrain, LoD2 or sectors needed, so it runs in CI too):
##   - each site is found (muzeum, europejski, grob), and the museum is a model now, not a skin;
##   - what each replaces is dropped (the museum's OpenStreetMap outline, the LoD2 model's centre
##     in its forecourt, Hotel Europejski's outline, the Tomb's tiny 3D parts) and what stands
##     next to it is kept (the museum's garages, the papal cross, the Metropolitan's parts);
##   - built alone (`landmarks.gd`, a stub map with flat ground), its triangles are within
##     BUDGET, every one carries a landmark material code (UV2.x >= 2: the city's one building
##     material, so no draw call of its own), lies within the site's box + SITE_REACH (so a
##     sector that builds the site keeps all of it), and it adds car walls and tap cells;
##   - its info card has a name and Polish and English lines of at most 70 characters.
## Plac Piłsudskiego, part 2 (2026-10-31): the Metropolitan (a model now, not the fin skin) and
## Hotel Wiktoria (the 1976 hotel on Królewska, under a parody name: no card says the real one)
## the same way; the Królewska edge's skins (Dom bez Kantów, the Departament, the unnamed block on
## the square's south-east corner) are found and give the buildings under them their stone, and
## the unnamed one has no card (so it isn't on the picking grid).
## Prints a line per site, then `check_sites: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_sites.gd

const MapBuilderRef := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Chunked := preload("res://scripts/chunked_surface.gd")
## Triangles a site may hold (the museum and Plac loop's own models).
const BUDGET := {"muzeum": 3300, "europejski": 8000, "grob": 600, "metropolitan": 3200, "wiktoria": 900,
		"hotel_kasztel": 400, "hotel_canaletto": 400, "hotel_starowka": 400, "polonia": 1450, "ujazdowski": 1650, "sobieski": 1500,
		"zamek": 3200, "arkady": 2400, "kino_muranow": 6000, "dekalog_estate": 18000, "inflancka_pools": 1000}
## The Królewska edge's skins: key -> a point in a building the skin must cover.
const SKINNED := {"bez_kantow": Vector2(-580.0, -785.0), "departament": Vector2(-596.0, -702.0),
		"krolewska": Vector2(-660.0, -790.0)}
## Words no card may hold (the hotel's real brand and name).
const DENY := ["sofitel", "victoria"]
const MAX_LINE := 70

var problems: Array[String] = []


## A stand-in for map_builder.gd: flat ground, the roof grid's frame, the car walls.
class StubMap:
	const ROOF_CELL := 4.0
	var _roof_x0 := 0.0
	var _roof_z0 := 0.0
	var _roof_nx := 0
	var _roof_nz := 0
	var _wall_faces := PackedVector3Array()
	var roof_tris := 0

	## The sunken places (map_builder SUNKEN) on the flat ground: tops at 0, floors 3.4 m under it.
	var _sunk: Array[Dictionary] = []

	func _init() -> void:
		for e: Dictionary in MapBuilderRef.SUNKEN:
			var f := e.duplicate()
			if not is_nan(float(f["hb"])):
				f["hb"] = -3.4
			_sunk.append(MapBuilderRef.sunk_entry(f, 0.0, 10.0))

	func _grid_height(_x: float, _z: float) -> float:
		return 0.0

	func sunk_floor(x: float, z: float, _grown := false) -> float:
		for sk: Dictionary in _sunk:
			if Geometry2D.is_point_in_polygon(Vector2(x, z), sk["ring"]):
				return MapBuilderRef.sunk_level(sk, Vector2(x, z))
		return INF

	func sunk_level(sk: Dictionary, p: Vector2) -> float:
		return MapBuilderRef.sunk_level(sk, p)

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func tunnel_floor_under(_x: float, _z: float) -> float:
		return NAN

	func _roof_triangle(_a: Vector3, _b: Vector3, _c: Vector3, _is_roof: bool, _col := Color(0, 0, 0, 0)) -> void:
		roof_tris += 1


## A stand-in for the city's building surface: keeps what the landmark emits.
class Recorder:
	var pos := PackedVector3Array()
	var codes := PackedFloat32Array()
	var _uv2 := Vector2.ZERO

	func set_color(_c: Color) -> void:
		pass

	func set_normal(_n: Vector3) -> void:
		pass

	func set_uv(_uv: Vector2) -> void:
		pass

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		pos.append(p)
		codes.append(_uv2.x)


func _initialize() -> void:
	var text := FileAccess.get_file_as_string("res://map/centrum.json")
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		print("check_sites: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := StubMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	_check_zones(marks, data)
	for key: String in BUDGET:
		_check_site(marks, map, key)
	_check_skins(marks, data)
	if problems.is_empty():
		print("check_sites: OK")
		quit(0)
	else:
		print("check_sites: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


func _centre(flat: Array) -> Vector2:
	var c := Vector2.ZERO
	for i in range(0, flat.size() - 1, 2):
		c += Vector2(flat[i], flat[i + 1])
	return c / maxf(flat.size() / 2, 1)


func _check_zones(marks, data: Dictionary) -> void:
	for s: Dictionary in marks.sites:
		if s["key"] in ["muzeum", "metropolitan"] and s.has("skin"):
			problems.append("%s: still a skin site, not a model" % s["key"])
	var dropped := 0
	var kept := 0
	for bld: Dictionary in data["buildings"]:
		var c := _centre(bld["p"])
		var name := str(bld.get("name", ""))
		# The museum (its outline round the courtyards), Hotel Europejski, the Tomb's parts.
		var want_drop := (Rect2(-60, 170, 215, 135).has_point(c) and (bld["p"] as Array).size() > 40) \
				or name == "Hotel Europejski" \
				or (Rect2(-871.0, -776.0, 11.0, 15.0).has_point(c) and float(bld["h"]) < 7.0) \
				or (str(bld["c"]) in ["#9cafb3", "#a9adb2"] and Rect2(-870, -1000, 130, 120).has_point(c)) \
				or (str(bld.get("kind", "")) == "roof" and Rect2(-735, -670, 20, 15).has_point(c)) \
				or name in ["Zachęta", "Pałac Prezydencki"] \
				or (name == "Kościół Świętej Trójcy" and Rect2(-880, -535, 50, 55).has_point(c))
		var want_keep := (name == "Krzyż Papieski") or (str(bld.get("kind", "")) == "garage" and Rect2(80, 260, 40, 25).has_point(c)) \
				or name in ["Pałac Potockich", "Teatr Narodowy"] \
				or (str(bld.get("kind", "")) == "outbuilding" and Rect2(-735, -610, 25, 15).has_point(c))
		if want_drop:
			dropped += 1
			if marks.keeps_building(bld):
				problems.append("%s at %s is still drawn under a landmark" % [name if name != "" else "a building", c.round()])
		elif want_keep:
			kept += 1
			if not marks.keeps_building(bld):
				problems.append("%s at %s is dropped, but stands outside the landmarks" % [name if name != "" else str(bld.get("kind", "")), c.round()])
	# The museum's LoD2 model is one run round its courtyards: its box's centre is in one.
	if not marks.replaces(Vector2(47.5, 237.5)):
		problems.append("muzeum: a model centred in its east courtyard (the LoD2 run) would stay")
	# The Metropolitan's LoD2 model centres in its courtyard; the hotel's in its plot.
	if not marks.replaces(Landmarks.METRO_COURT):
		problems.append("metropolitan: a model centred in its courtyard (the LoD2 run) would stay")
	if not marks.replaces(Vector2(-720.0, -638.0)):
		problems.append("wiktoria: a model centred in the hotel's plot (the LoD2 run) would stay")
	if dropped < 3 or kept < 3:
		problems.append("the zone test found %d buildings to drop and %d to keep (map changed?)" % [dropped, kept])
	print("check_sites: zones: %d buildings dropped under the sites, %d neighbours kept" % [dropped, kept])


func _check_site(marks, map: StubMap, key: String) -> void:
	var k := -1
	for i in marks.sites.size():
		if marks.sites[i]["key"] == key:
			k = i
	if k < 0:
		problems.append("%s: site not found" % key)
		return
	var s: Dictionary = marks.sites[k]
	var rec := Recorder.new()
	marks.st = rec
	marks._pick.resize(map._roof_nx * map._roof_nz)
	marks._pick.fill(0)
	marks._id = k + 1
	var walls0 := map._wall_faces.size()
	match key:
		"muzeum":
			marks._build_muzeum(s)
		"europejski":
			marks._build_europejski(s)
		"grob":
			marks._build_grob(s)
		"metropolitan":
			marks._build_metropolitan(s)
		"wiktoria":
			marks._build_wiktoria(s)
		"polonia":
			marks._build_polonia(s)
		"ujazdowski":
			marks._build_ujazdowski(s)
		"sobieski":
			marks._build_sobieski(s)
		"zamek":
			marks._build_zamek(s)
		"arkady":
			marks._build_arkady(s)
		"dekalog_estate":
			marks._build_dekalog_estate(s)
		"inflancka_pools":
			marks._build_inflancka_pools(s)
		"kino_muranow":
			marks._build_kino_muranow(s)
		"hotel_kasztel", "hotel_canaletto", "hotel_starowka":
			marks._build_hotel(s)
	marks._id = 0
	var tris := rec.pos.size() / 3
	var reach: Rect2 = (s["box"] as Rect2).grow(Landmarks.SITE_REACH)
	var outside := 0
	var plain := 0
	var tiles := {}
	for t in tris:
		var c := (rec.pos[t * 3] + rec.pos[t * 3 + 1] + rec.pos[t * 3 + 2]) / 3.0
		if not reach.has_point(Vector2(c.x, c.z)):
			outside += 1
		if rec.codes[t * 3] < 2.0:
			plain += 1
		tiles[Chunked.tile_of(c)] = true
	var cells := 0
	for b in marks._pick:
		if b == k + 1:
			cells += 1
	var walls := (map._wall_faces.size() - walls0) / 6
	print("check_sites: %-10s %5d triangles (budget %d), %d tiles of the city mesh, %d car walls, %d tap cells" % [
			key, tris, BUDGET[key], tiles.size(), walls, cells])
	if tris == 0 or tris > BUDGET[key]:
		problems.append("%s: %d triangles (budget %d)" % [key, tris, BUDGET[key]])
	if outside > 0:
		problems.append("%s: %d triangles outside its box + SITE_REACH (a sector would cut them)" % [key, outside])
	if plain > 0:
		problems.append("%s: %d triangles without a landmark material code" % [key, plain])
	if walls < 4:
		problems.append("%s: no car walls" % key)
	if cells < 4:
		problems.append("%s: only %d tap cells" % [key, cells])
	var card: Array = Landmarks.INFO.get(key, [])
	if card.size() != 3 or str(card[0]) == "":
		problems.append("%s: no info card" % key)
	else:
		_check_card(key, card)


func _check_card(key: String, card: Array) -> void:
	for line: String in [card[1], card[2]]:
		if line == "" or line.length() > MAX_LINE:
			problems.append("%s: card line of %d characters: %s" % [key, line.length(), line])
	for word: String in DENY:
		if (" ".join(card)).to_lower().contains(word):
			problems.append("%s: its card names %s" % [key, word])


## The Królewska edge: each skin site is found, gives the building at its point its own colours
## and mode, and has a card when it is on the picking grid.
func _check_skins(marks, data: Dictionary) -> void:
	for key: String in SKINNED:
		var site: Dictionary = {}
		for s: Dictionary in marks.sites:
			if s["key"] == key:
				site = s
		if site.is_empty() or not site.has("skin"):
			problems.append("%s: skin site not found" % key)
			continue
		var at: Vector2 = SKINNED[key]
		var found := false
		for bld: Dictionary in data["buildings"]:
			var q := PackedVector2Array()
			for i in range(0, (bld["p"] as Array).size() - 1, 2):
				q.append(Vector2(bld["p"][i], bld["p"][i + 1]))
			if q.size() < 3 or not Geometry2D.is_point_in_polygon(at, q):
				continue
			found = true
			var box := Rect2(q[0], Vector2.ZERO)
			for v in q:
				box = box.expand(v)
			if not marks.keeps_building(bld):
				problems.append("%s: the building at %s is dropped (a skin keeps it)" % [key, at])
			var skin: Dictionary = marks.skin_at(box)
			if skin.is_empty() or skin["wall"] != site["skin"]["wall"]:
				problems.append("%s: the building at %s doesn't take its skin" % [key, at])
		if not found:
			problems.append("%s: no building at %s (map changed?)" % [key, at])
		var card: Array = Landmarks.INFO.get(key, [])
		if key == "krolewska":
			if not card.is_empty():
				problems.append("krolewska: has a card (the block's name isn't mapped)")
		elif card.size() != 3:
			problems.append("%s: no info card" % key)
		else:
			_check_card(key, card)
		print("check_sites: %-12s skin %s, mode %.2f, %s" % [key, (site["skin"]["wall"] as Color).to_html(false),
				float(site["skin"]["mode"]), "no card" if card.is_empty() else "card"])
