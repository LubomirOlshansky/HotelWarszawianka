class_name HouseTypes
extends RefCounted
## House types (docs/design/house-types.md, PR 1): the one owner of what an ordinary house is
## (a Warsaw type: kamienica, Praga brick, MDM, Muranów, a panel slab, an insulated block ...),
## which drawn facade rhythm it takes today, and its wall colour. Pure and static: the map
## builder asks at load time, the same on both city paths, every pick seeded by the house's
## place. Zones, types and palettes live in game/data/house_types.json.
##
## Precedence (who colours a wall): a landmark's skin and the photo fronts (their own builders),
## then the street lists still in map_builder.gd (the Old Town, Nowy Świat, Powiśle and Tamka,
## Aleja Jana Pawła II; tech-debt TD-37 moves them here), then the zone's type palette. A real
## OpenStreetMap colour tag beats the palette; an empty or grey one gives way to it.

const PATH := "res://data/house_types.json"
## Roof dress classes (roof_dress.gd's `kind`: 1 tenement chimneys, 2 slab, 3 office coping).
const RHYTHM_GENERIC := 0
const RHYTHM_TENEMENT := 1
const RHYTHM_SLAB := 2
const RHYTHM_OFFICE := 3
## Rows of building.gdshader's HOUSE_* tables: a typed wall's UV2.x is 1 + (T + 0.96 seed) / ROWS.
const ROWS := 16
## The Old Town and New Town (map_builder _tenement_facades), drawn by the shader's own function.
const OLD_TOWN := 4
## map_builder's R4 kinds (_building_type: 1 tenement, 2 slab, 3 office) as types, for the houses
## the street lists still type (TD-37).
const FROM_R4 := {1: 1, 2: 8, 3: 11, 4: OLD_TOWN}

static var _data: Dictionary = {}
static var _zones: Array = []  # [id, PackedVector2Array, Rect2, mix Dictionary, grey_override]


## The JSON, read once.
static func data() -> Dictionary:
	if _data.is_empty():
		# Built in locals and assigned last, so a reader never sees the data without its zones.
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var d: Dictionary = parsed if parsed is Dictionary else {"types": {}, "zones": []}
		var zones: Array = []
		for z: Dictionary in d.get("zones", []):
			var p: Array = z.get("p", [])
			var poly := PackedVector2Array()
			for i in range(0, p.size() - 1, 2):
				poly.append(Vector2(float(p[i]), float(p[i + 1])))
			if poly.size() < 3:
				continue  # check_house_types reports it
			var box := Rect2(poly[0], Vector2.ZERO)
			for q in poly:
				box = box.expand(q)
			zones.append([str(z["id"]), poly, box, z.get("mix", {}), bool(z.get("grey_override", true)),
					clampf(float(z.get("parked", 1.0)), 0.0, 1.0)])
		_zones = zones
		_data = d
	return _data


## The zone a point stands in (first match in the file's order), or -1 for the default.
static func zone_at(at: Vector2) -> int:
	data()
	for i in _zones.size():
		if (_zones[i][2] as Rect2).has_point(at) and Geometry2D.is_point_in_polygon(at, _zones[i][1]):
			return i
	return -1


## The share of the bake's parked cars kept at `at` (the zone's "parked", 1 outside the zones):
## the estates stay full, the office belt runs thin.
static func parked_keep(at: Vector2) -> float:
	var z := zone_at(at)
	return 1.0 if z < 0 else float(_zones[z][5])


## Whether the parked car at `at` stays: a hash of its place (half a metre) against the zone's
## share, so both city paths and every sector keep the same cars.
static func keeps_parked(at: Vector2) -> bool:
	var keep := parked_keep(at)
	if keep >= 1.0:
		return true
	var h := (roundi(at.x * 2.0) * 73856093) ^ (roundi(at.y * 2.0) * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h ^= h >> 16
	return float(h & 0xFFFFFF) / 16777216.0 < keep


## A zone index's id from the JSON ("default" for -1).
static func zone_id(zone: int) -> String:
	return "default" if zone < 0 else str(_zones[zone][0])


## The house's family from what it shows: floor height (metres per storey, 0 unknown), height,
## footprint (`long`, `short`: its least-area box), a courtyard next to it, and the zone's own
## family (`zone_fam`, zone_family()). "" = no evidence. Floor height decides when known; shape
## is weak evidence: in a pre-war zone a long frontage is a row of kamienice, not a slab, so
## there only a very tall house reads post-war.
static func family(kind_office: bool, h: float, floor_h: float, long: float, short: float, court: bool,
		zone_fam: String = "") -> String:
	if kind_office:
		return "office"
	var d := data()
	if floor_h > 0.0:
		if floor_h >= float(d.get("floor_prewar", 3.6)):
			return "prewar"
		if floor_h <= float(d.get("floor_postwar", 3.05)):
			return "postwar"
	if zone_fam == "prewar":
		return "postwar" if h >= 40.0 else ""
	if h >= 30.0 or (long >= 45.0 and short <= 16.0 and h >= 14.0):
		return "postwar"
	if court and floor_h <= 0.0:
		return "prewar"
	return ""


## The family most of a zone's mix belongs to (by weight).
static func zone_family(zone: int) -> String:
	var d := data()
	var types: Dictionary = d.get("types", {})
	var mix: Dictionary = d.get("default_mix", {}) if zone < 0 else _zones[zone][3]
	var w := {}
	for key in mix:
		var f := str(types.get(str(key), {}).get("family", ""))
		w[f] = float(w.get(f, 0.0)) + float(mix[key])
	var best := ""
	for f in w:
		if best == "" or float(w[f]) > float(w[best]):
			best = f
	return best


## A house's type (1..15, the keys of "types"; 0 none) in zone `zone`, given its family evidence
## and a seed from its place (0..1). The zone's mix decides; evidence narrows the mix to that
## family, or falls back to the family's default where the zone has none of it.
static func pick(zone: int, fam: String, h: float, long: float, short: float, seed: float) -> int:
	var d := data()
	var types: Dictionary = d.get("types", {})
	var mix: Dictionary = d.get("default_mix", {}) if zone < 0 else _zones[zone][3]
	var total := 0.0
	var allowed: Array = []
	for key in mix:
		var t: Dictionary = types.get(str(key), {})
		if t.is_empty():
			continue
		if fam != "" and str(t.get("family", "")) != fam:
			continue
		allowed.append([int(key), float(mix[key])])
		total += float(mix[key])
	var picked := 0
	if allowed.is_empty() or total <= 0.0:
		var fallback: Dictionary = d.get("family_default", {})
		picked = int(fallback.get(fam if fam != "" else "prewar", "1"))
	else:
		var r := seed * total
		picked = int(allowed[-1][0])
		for a in allowed:
			r -= float(a[1])
			if r < 0.0:
				picked = int(a[0])
				break
	# A tall near-square post-war block is a point block.
	if types.has("10") and str(types.get(str(picked), {}).get("family", "")) == "postwar" and picked != 13 \
			and h >= 40.0 and long > 0.0 and long / maxf(short, 1.0) < 1.7:
		picked = 10
	return picked


## A wall's UV2.x for type `type` (1..15) and seed 0..1, the shader's encoding; 0 keeps the seed.
static func encode(type: int, seed: float) -> float:
	if type <= 0 or type >= ROWS:
		return seed
	return 1.0 + (float(type) + 0.96 * clampf(seed, 0.0, 0.999)) / float(ROWS)


## The type a UV2.x carries (0 untyped, a landmark code or out of range).
static func decode(x: float) -> int:
	if x < 1.0 or x >= 2.0:
		return 0
	return clampi(int((x - 1.0) * ROWS), 0, ROWS - 1)


## The roof dress class of a type (0 generic, 1 tenement, 2 slab, 3 office).
static func rhythm(type: int) -> int:
	return int(data().get("types", {}).get(str(type), {}).get("rhythm", RHYTHM_GENERIC))


## A type's short name from the JSON ("generic" for none).
static func type_name(type: int) -> String:
	return str(data().get("types", {}).get(str(type), {}).get("name", "generic"))


## The type's wall colour for a house with seed `seed` (0..1), as linear-free sRGB Color.
static func wall(type: int, seed: float) -> Color:
	var walls: Array = data().get("types", {}).get(str(type), {}).get("walls", [])
	if walls.is_empty():
		return Color(0, 0, 0, 0)
	return Color(str(walls[int(fposmod(seed * 7.31, 1.0) * walls.size()) % walls.size()]))


## Whether an OpenStreetMap colour tag should give way to the zone's palette: empty, or a mid
## grey (the map's usual `#666666`, `gray`, `#999999`) where the zone allows the override. White
## and black tags are someone's real reading of the house and stay.
static func replaces_osm(zone: int, value: Variant) -> bool:
	var s := str(value).strip_edges().to_lower().replace("grey", "gray")
	if s == "":
		return true
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	if c.a == 0.0:
		return true
	var grey_ok: bool = true if zone < 0 else bool(_zones[zone][4])
	return grey_ok and c.s < 0.12 and c.v >= 0.25 and c.v <= 0.85


## The least-area box of a footprint along one of its own edges: Vector2(long, short).
static func footprint(poly: PackedVector2Array) -> Vector2:
	var best := Vector2(INF, INF)
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() < 2.0:
			continue
		var dn := e.normalized()
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q in poly:
			var r := Vector2(q.dot(dn), q.dot(Vector2(-dn.y, dn.x)))
			lo = lo.min(r)
			hi = hi.max(r)
		var size := hi - lo
		if size.x * size.y < best.x * best.y:
			best = size
	if best.x == INF:
		return Vector2.ZERO
	return Vector2(maxf(best.x, best.y), minf(best.x, best.y))


## Storeys from a baked height: tools/bake_osm.py writes h = levels * 3.3 + 1 when OSM has no
## height tag; 0 when h is not on that grid (a measured height says nothing about storeys).
static func levels_from_h(h: float) -> int:
	var lv := (h - 1.0) / 3.3
	var n := roundi(lv)
	return n if n >= 1 and absf(lv - n) < 0.02 else 0
