extends SceneTree
## House types (scripts/house_types.gd, game/data/house_types.json, docs/design/house-types.md):
## the JSON is sound (every zone a polygon inside the map, every mix names known types with
## positive weights, every palette colour parses and is not loud), the rules hold on made-up
## houses (tall floors read pre-war, low floors post-war, an office stays an office, a tall
## square post-war block is a point block, a grey OSM tag gives way and a coloured one stays),
## and the photo fronts (game/data/photo_fronts.json, drawn from F's photos) score at least
## MIN_CLASSIC (share of "classic" fronts landing in a pre-war type) and MIN_MODERN (share of
## "fins" and "ribbon" fronts landing in a post-war or office type), each on its own so always
## answering one family cannot pass. Prints an estimate of the typed houses per zone by the OSM
## rule (the game's own count is the build's `house types:` line).
##   godot --headless --path game --script res://tools/check_house_types.gd

## The photo-front scores recorded 2026-11-26 (PR 1), by the OSM rule (no floor heights).
const MIN_CLASSIC := 0.6
const MIN_MODERN := 0.65
## The most saturated a palette colour may be (HSV), so the city never reads as a toy.
const MAX_SATURATION := 0.62

var failed := 0


func _initialize() -> void:
	var d := HouseTypes.data()
	var types: Dictionary = d.get("types", {})
	_expect(not types.is_empty(), "types listed")
	for key in types:
		var t: Dictionary = types[key]
		_expect(int(t.get("rhythm", -1)) in [0, 1, 2, 3], "type %s has a drawn rhythm 0-3" % key)
		_expect(str(t.get("family", "")) in ["prewar", "postwar", "office"], "type %s has a family" % key)
		for c in t.get("walls", []):
			var col := Color.from_string(str(c), Color(0, 0, 0, 0))
			_expect(col.a > 0.0, "type %s colour %s parses" % [key, c])
			_expect(col.s <= MAX_SATURATION, "type %s colour %s is not loud (s %.2f)" % [key, c, col.s])
	var map = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var bounds := Rect2(-4000, -4000, 8000, 8000)
	if map is Dictionary and map.has("bounds"):
		var b: Array = map["bounds"]
		bounds = Rect2(Vector2(b[0], b[1]), Vector2(b[2] - b[0], b[3] - b[1])).grow(400.0)
	var ids := {}
	for z: Dictionary in d.get("zones", []):
		var id := str(z.get("id", ""))
		_expect(id != "" and not ids.has(id), "zone id %s is unique" % id)
		ids[id] = true
		var p: Array = z.get("p", [])
		_expect(p.size() >= 6 and p.size() % 2 == 0, "zone %s is a polygon" % id)
		for i in range(0, p.size() - 1, 2):
			_expect(bounds.has_point(Vector2(p[i], p[i + 1])), "zone %s inside the map" % id)
		var mix: Dictionary = z.get("mix", {})
		_expect(not mix.is_empty(), "zone %s has a mix" % id)
		for k in mix:
			_expect(types.has(str(k)) and float(mix[k]) > 0.0, "zone %s mixes known type %s" % [id, k])

	# The rules on made-up houses.
	_expect(HouseTypes.family(false, 18.0, 3.9, 30.0, 14.0, false) == "prewar", "3.9 m floors read pre-war")
	_expect(HouseTypes.family(false, 18.0, 2.8, 30.0, 14.0, false) == "postwar", "2.8 m floors read post-war")
	_expect(HouseTypes.family(true, 18.0, 3.9, 30.0, 14.0, false) == "office", "an office stays an office")
	_expect(HouseTypes.family(false, 18.0, 0.0, 30.0, 14.0, true) == "prewar", "beside a courtyard reads pre-war")
	_expect(HouseTypes.family(false, 40.0, 0.0, 30.0, 14.0, false) == "postwar", "40 m with unknown floors reads post-war")
	for seed in [0.05, 0.35, 0.65, 0.95]:
		var t := HouseTypes.pick(-1, "postwar", 50.0, 24.0, 20.0, seed)
		_expect(t == 10 or t == 13, "a tall square post-war block is a point block (or a new build), got %d" % t)
		var pre := HouseTypes.pick(-1, "prewar", 18.0, 30.0, 14.0, seed)
		_expect(str(types.get(str(pre), {}).get("family", "")) == "prewar", "a pre-war pick stays pre-war, got %d" % pre)
	_expect(HouseTypes.replaces_osm(-1, ""), "no colour gives way")
	_expect(HouseTypes.replaces_osm(-1, "#666666"), "a grey colour gives way")
	_expect(HouseTypes.replaces_osm(-1, "gray"), "the word grey gives way")
	_expect(not HouseTypes.replaces_osm(-1, "#c8733f"), "a real colour stays")
	_expect(not HouseTypes.replaces_osm(-1, "white"), "a white tag stays")
	_expect(not HouseTypes.replaces_osm(-1, "#111111"), "a black tag stays")
	_expect(HouseTypes.levels_from_h(5 * 3.3 + 1.0) == 5, "5 storeys from the bake's height")
	_expect(HouseTypes.levels_from_h(17.4) == 0, "a measured height gives no storeys")
	# PR 2a: the shader's encoding and its tables.
	for t in [1, 4, 8, 15]:
		for sd in [0.0, 0.5, 0.999]:
			_expect(HouseTypes.decode(HouseTypes.encode(t, sd)) == t, "type %d seed %.3f round-trips" % [t, sd])
			# Half precision (the mesh's UV2 may be stored as 16-bit floats) keeps the type.
			var half := snappedf(HouseTypes.encode(t, sd), 1.0 / 1024.0)
			_expect(HouseTypes.decode(half) == t, "type %d seed %.3f survives half precision" % [t, sd])
	_expect(HouseTypes.encode(0, 0.3) == 0.3, "untyped keeps its seed")
	_expect(HouseTypes.decode(2.5) == 0 and HouseTypes.decode(0.5) == 0, "landmarks and seeds decode as untyped")
	var shader := FileAccess.get_file_as_string("res://shaders/building.gdshader")
	for key in types:
		var f: Array = types[key].get("facade", [])
		_expect(f.size() == 16, "type %s has 16 facade numbers" % key)
		if f.size() == 16:
			for i in 4:
				var row := ", ".join(f.slice(i * 4, i * 4 + 4).map(func(v): return _g(float(v))))
				var rows := _table(shader, "ABCD"[i])
				_expect(rows.size() == 16 and rows[int(key)] == row,
						"building.gdshader HOUSE_%s row %s is type %s's (run tools/house_zones.py)" % ["ABCD"[i], key, key])
	var muranow := HouseTypes.zone_at(Vector2(-2099, -1262))
	_expect(HouseTypes.zone_id(muranow) == "muranow", "Nowolipki is in Muranów (got %s)" % HouseTypes.zone_id(muranow))

	# Parked cars by zone: every share in 0..1, the estates full, the office belt thinner, and the
	# pick a pure function of the place (both city paths keep the same cars).
	for z: Dictionary in d.get("zones", []):
		var share := float(z.get("parked", 1.0))
		_expect(share >= 0.0 and share <= 1.0, "zone %s parks a share in 0..1 (%s)" % [z.get("id"), share])
	_expect(is_equal_approx(HouseTypes.parked_keep(Vector2(-2099, -1262)), 1.0), "Muranów keeps all its parked cars")
	var kept := 0
	var wola := Vector2(-2400, 450)
	var share_w := HouseTypes.parked_keep(wola)
	_expect(share_w < 1.0, "the Wola office belt parks thinner (%.2f)" % share_w)
	for i in 2000:
		var at := wola + Vector2(fmod(i * 7.31, 150.0), fmod(i * 3.17, 90.0))
		if HouseTypes.keeps_parked(at):
			kept += 1
		_expect(HouseTypes.keeps_parked(at) == HouseTypes.keeps_parked(at), "keeps_parked is the same twice")
	_expect(absf(kept / 2000.0 - share_w) < 0.06, "Wola keeps about its share of parked cars (%.2f of %.2f)" % [kept / 2000.0, share_w])

	# The photo fronts and the census, from the baked map.
	_expect(map is Dictionary, "res://map/centrum.json loads (run tools/setup_map.sh)")
	if map is Dictionary:
		_photo_score(map, types)
		_census(map)
	if failed == 0:
		print("check_house_types: OK")
	quit(1 if failed > 0 else 0)


## Each judged photo front: its family from the OSM house under it, as the OSM path decides
## (zone and shape; floor heights need the LoD2 run, which this check does not load).
func _photo_score(map: Dictionary, types: Dictionary) -> void:
	var fronts = JSON.parse_string(FileAccess.get_file_as_string("res://data/photo_fronts.json"))
	if not fronts is Array:
		return
	var houses: Array = map.get("buildings", [])
	var judged := {"classic": 0, "modern": 0}
	var right := {"classic": 0, "modern": 0}
	for f: Dictionary in fronts:
		var want := ""
		match str(f.get("style", "")):
			"classic":
				want = "prewar"
			"fins", "ribbon":
				want = "postwar/office"
		if want == "":
			continue
		var o: Array = f.get("outline", [])
		var poly := PackedVector2Array()
		for i in range(0, o.size() - 1, 2):
			poly.append(Vector2(o[i], o[i + 1]))
		if poly.size() < 3:
			continue
		var centre := Vector2.ZERO
		for q in poly:
			centre += q
		centre /= poly.size()
		var h := 0.0
		var kind := "yes"
		for bld: Dictionary in houses:
			var p: Array = bld["p"]
			if absf(float(p[0]) - centre.x) > 200.0 or absf(float(p[1]) - centre.y) > 200.0:
				continue
			var bp := PackedVector2Array()
			for i in range(0, p.size() - 1, 2):
				bp.append(Vector2(p[i], p[i + 1]))
			if Geometry2D.is_point_in_polygon(centre, bp):
				h = float(bld.get("h", 0.0))
				kind = str(bld.get("kind", "yes"))
				break
		var zone := HouseTypes.zone_at(centre)
		var fp := HouseTypes.footprint(poly)
		var fam := HouseTypes.family(kind in ["office", "commercial", "government", "hotel"], h, 0.0, fp.x, fp.y, false, HouseTypes.zone_family(zone))
		var t := HouseTypes.pick(zone, fam, h, fp.x, fp.y, fposmod(centre.x * 0.0731 + centre.y * 0.0417, 1.0))
		var got := str(types.get(str(t), {}).get("family", ""))
		var cls := "classic" if want == "prewar" else "modern"
		judged[cls] += 1
		if (want == "prewar" and got == "prewar") or (want == "postwar/office" and got in ["postwar", "office"]):
			right[cls] += 1
	var classic := float(right["classic"]) / maxf(judged["classic"], 1.0)
	var modern := float(right["modern"]) / maxf(judged["modern"], 1.0)
	print("house types: photo fronts classic %d of %d pre-war, modern %d of %d post-war or office" % [right["classic"],
			judged["classic"], right["modern"], judged["modern"]])
	_expect(classic >= MIN_CLASSIC, "classic photo fronts %.2f at least %.2f" % [classic, MIN_CLASSIC])
	_expect(modern >= MIN_MODERN, "modern photo fronts %.2f at least %.2f" % [modern, MIN_MODERN])


## Typed houses per zone and type by the OSM path's rule (zone and shape; the LoD2 runs add
## floor heights at build time and print their own census, `house types:`): the PR's table.
func _census(map: Dictionary) -> void:
	var per := {}
	for bld: Dictionary in map.get("buildings", []):
		var p: Array = bld["p"]
		var kind := str(bld.get("kind", ""))
		var h := float(bld.get("h", 0.0))
		if p.size() < 6 or h < 10.0 or not kind in ["yes", "apartments", "residential", "house", "retail", "office", "commercial", "government", "hotel"]:
			continue
		var poly := PackedVector2Array()
		for i in range(0, p.size() - 1, 2):
			poly.append(Vector2(p[i], p[i + 1]))
		var centre := Vector2.ZERO
		for q in poly:
			centre += q
		centre /= poly.size()
		var zone := HouseTypes.zone_at(centre)
		var fp := HouseTypes.footprint(poly)
		var fam := HouseTypes.family(kind in ["office", "commercial", "government", "hotel"], h, 0.0, fp.x, fp.y, false, HouseTypes.zone_family(zone))
		var t := HouseTypes.pick(zone, fam, h, fp.x, fp.y, fposmod(centre.x * 0.0731 + centre.y * 0.0417, 1.0))
		var zid := HouseTypes.zone_id(zone)
		if not per.has(zid):
			per[zid] = {}
		per[zid][HouseTypes.type_name(t)] = int(per[zid].get(HouseTypes.type_name(t), 0)) + 1
	var zones := per.keys()
	zones.sort()
	for z in zones:
		var row: Dictionary = per[z]
		var names := row.keys()
		names.sort_custom(func(a, b): return row[a] > row[b])
		print("  %-22s %s" % [z, ", ".join(names.map(func(n): return "%s %d" % [n, row[n]]))])


## The rows of building.gdshader's `const vec4 HOUSE_<name>[16]`, each as its numbers' text.
func _table(shader: String, name: String) -> PackedStringArray:
	var at := shader.find("const vec4 HOUSE_%s[16] = vec4[16](vec4(" % name)
	if at < 0:
		return PackedStringArray()
	var line := shader.substr(at, shader.find("\n", at) - at)
	line = line.substr(line.find("(vec4(") + 6)
	line = line.substr(0, line.rfind("));"))
	return line.split("), vec4(")


## A number as Python's "%g" writes it (house_zones.py's shader rows).
func _g(v: float) -> String:
	return str(int(v)) if v == floorf(v) else String.num(v, 6)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		print("FAIL: ", what)
