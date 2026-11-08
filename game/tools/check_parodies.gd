extends SceneTree
## Loop MW-2 (docs/design/parodies.md 2-10, vision.md 3.0 and section 5 row 3): the storefronts
## and parodies (scripts/storefronts.gd, the Pędzik couriers in scripts/city_life.gd), headless,
## from the committed map data (map/centrum.json) and data/places.json; seeded, no clock of its own:
##   1. the rules: the stamp card (one a shop a day, ten a day, the 10th the free hot dog), the
##      `detour` passenger's half star once (ride_rules.gd), the couriers' counts by day and night,
##      every venue line fits the neon atlas;
##   2. the city's picks: the Frogs (at a junction, 70 m apart off the triple corners, the density
##      caps, no landmark, two in the Old Town at most, three at each triple corner 60° apart), a
##      building's wall within the ray's reach of each (2D, from the buildings' outlines: the game's
##      rays need the sector colliders), the 17 venues with their names, the Leżaks and the metro
##      entrances off the lanes, one standing Leżak, the named kebab stands' places;
##   3. the words: no real brand (data/brand_denylist.json) in any sign, venue or line; every
##      line PL + EN, the Polish ≤ 70 characters (the house rule for bubbles); every world-text letter in the pixel font;
##   4. the wall ray on a synthetic facade (a box under a sector root): the sign on its face, 0.14 m
##      out (within 0.3 m), a wall too short for a shop refused;
##   5. the hooks on synthetic inputs: a stop at a Frogs door stamps once, not at speed, the free
##      hot dog on the 10th pays once; a car at a lying Leżak knocks it 1-3 m with one aside a
##      minute; the eggs easter_rechotka and easter_lezak fire on their stops only, each pays once;
##   6. the cost: the setup's ms, the hook's µs a frame, the meshes' triangles (parodies.md 8).
## Prints "check_parodies: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_parodies.gd [-- --verbose]

const Storefronts := preload("res://scripts/storefronts.gd")
const CityLife := preload("res://scripts/city_life.gd")
const RideRules := preload("res://scripts/ride_rules.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Neon := preload("res://scripts/neon_signs.gd")
const Props := preload("res://scripts/props.gd")

## Two older kebab_order lines (loop 2b) over the Polish bubbles' 70: not this loop's words to
## change (BACKLOG "From loop MW-2").
const OLD_LONG := ["Zamówienie dla pana Krzysztofa z Powiśla. W uwagach: „dużo czosnkowego”.",
		"Powiśle, kamienica bez windy. Klientka prosi: „tylko nie trąbić, sąsiedzi”."]
## The dialogue groups the parodies speak or show.
const GROUPS := ["rechotka", "easter_rechotka", "pedzik", "lezak", "easter_lezak", "kebab_vendor", "kebab_order", "signs",
		"column_posters", "mrozulo_review", "mrozulo_owner", "office"]


## A stand-in for dialogue.gd: the real lines, records each one asked for.
class FakeDialogue extends Node:
	var lines := {}
	var said: Array = []
	var bubbles: FakeBubbles

	func say(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _k := 0, _key := "") -> Array:
		said.append([speaker, group, tag])
		return ["…", "…"]

	func say_ambient(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false) -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func say_reaction(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false, _key := "") -> Array:
		return say(_anchor, speaker, group, tag, _s, _a, _h, _p)

	func line(group: String, tag := "", _prefer := false) -> Array:
		said.append(["", group, tag])
		return ["…", "…"]

	func count(group: String, tag: String) -> int:
		var n := 0
		for l: Array in said:
			n += int(l[1] == group and l[2] == tag)
		return n


class FakeBubbles extends Control:
	var n := 0
	func say(_anchor: Variant, _who: String, _pl: String, _en: String, _s := 3.0, _a := Color.WHITE, _h := 2.0) -> void:
		n += 1
	func say_ambient(_anchor: Variant, _who: String, _pl: String, _en: String, _s := 3.0, _a := Color.WHITE, _h := 2.0) -> void:
		n += 1


## Flat ground; a roof over the synthetic facade's box (z < -5 round x 0) for the wall test.
class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0
	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false
	func top_height(x: float, z: float, _r := 0.0) -> float:
		return 12.0 if z < -5.0 and z > -15.0 and absf(x - 5000.0) < 10.0 else 0.0


class FakeHud extends CanvasLayer:
	var toasts: Array = []
	var notes: Array = []
	func toast(pl: String, en := "") -> void:
		toasts.append([pl, en])
	func show_note(a: String, b: String, _c := Color.WHITE) -> void:
		notes.append([a, b])


var problems: Array[String] = []
var verbose := false
var veh: Array = [Vector3.INF, 0.0, false]


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	_check_rules()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("check_parodies: PROBLEM (no map/centrum.json or places.json)")
		quit(1)
		return
	var dlg := FakeDialogue.new()
	dlg.bubbles = FakeBubbles.new()
	dlg.add_child(dlg.bubbles)
	dlg.lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	root.add_child(dlg)
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var eggs: EggBook = EggBook.new()
	eggs.wallet = wallet
	root.add_child(eggs)
	eggs.set_process(false)
	_expect(eggs.load_eggs(), "data/eggs.json doesn't load")
	var map := FakeMap.new()
	root.add_child(map)
	var hud := FakeHud.new()
	root.add_child(hud)
	var graph := LaneGraph.new(data["graph"], map)
	var sf: Storefronts = Storefronts.new()
	sf.map = map
	sf.graph = graph
	sf.dialogue = dlg
	sf.hud = hud
	sf.wallet = wallet
	sf.egg_book = eggs
	sf.log_on = verbose
	sf.vehicle = func() -> Array: return veh
	root.add_child(sf)
	sf.set_process(false)
	sf.set_physics_process(false)
	var t0 := Time.get_ticks_usec()
	sf.setup(data, book.places)
	var setup_ms := (Time.get_ticks_usec() - t0) / 1000.0
	_check_picks(sf, data, book, graph)
	_check_words(dlg.lines)
	var wall := await _check_wall(sf)
	var tick_us := _check_hooks(sf, dlg, hud, wallet, eggs)
	var tris := _check_meshes()
	if problems.is_empty():
		print("check_parodies: OK (stamp card, detour once, couriers; %d Frogs, %d at 2 triple corners, %d venues, %d Leżaks in %d zones, %d metro entrances, %d Rowerilo docks; no brand, lines ≤ 70, font; wall %.2f m; stamps, free hot dog once, knock, eggs easter_rechotka easter_lezak once; setup %.0f ms, hook %.1f µs a frame; Frogs %d, Leżak %d, Pędzik %d triangles)" % [
				sf.shops.size(), _triple_n, sf.venues.size(), sf.scooters.size(), sf.zones.size(), sf.metros.size(), sf.docks.size(), wall,
				setup_ms, tick_us, tris[0], tris[1], tris[2]])
		quit(0)
	else:
		for p in problems:
			print("  problem: ", p)
		print("check_parodies: %d problems" % problems.size())
		quit(1)


var _triple_n := 0


# 1. ------------------------------------------------------------------------------------------

func _check_rules() -> void:
	# The card: a shop once a day, ten stamps a day, the 10th stamp the free hot dog.
	var r := Storefronts.stamp_rule(3, [], 0)
	_expect(r["stamp"] and not r["free"], "stamp_rule: a first stamp %s" % r)
	r = Storefronts.stamp_rule(3, [3], 1)
	_expect(not r["stamp"], "stamp_rule: the same shop twice a day stamps (%s)" % r)
	r = Storefronts.stamp_rule(4, [3], 9)
	_expect(r["stamp"] and r["free"], "stamp_rule: the 10th stamp isn't the free one (%s)" % r)
	var ten: Array = []
	for k in Storefronts.STAMPS_DAY:
		ten.append(100 + k)
	r = Storefronts.stamp_rule(5, ten, 2)
	_expect(not r["stamp"], "stamp_rule: an 11th stamp in a day (%s)" % r)
	# The detour passenger: half a star once.
	var rr := RideRules.new()
	var b0 := rr.bonus
	_expect(rr.detour() and not rr.detour(), "ride_rules.detour: not once")
	_expect(absf(rr.bonus - b0 - RideRules.BONUS) < 0.001, "ride_rules.detour: bonus %.2f (want %.2f)" % [rr.bonus - b0, RideRules.BONUS])
	# The couriers: 4 by day, 6 at night (× 1.5), Low's half, the pool.
	_expect(CityLife.pedzik_count(13.0) == 4 and CityLife.pedzik_count(1.0) == 6 and CityLife.pedzik_count(22.0) == 6,
			"pedzik_count: day %d, night %d (want 4, 6)" % [CityLife.pedzik_count(13.0), CityLife.pedzik_count(1.0)])
	_expect(CityLife.pedzik_count(13.0, 0.5) == 2 and CityLife.pedzik_count(1.0, 10.0) == CityLife.PEDZIK_CAP,
			"pedzik_count: the half and the cap")
	# Every venue line in the atlas's width.
	for id: String in Storefronts.VENUES:
		for l: String in Storefronts.VENUES[id][0]:
			_expect(Storefronts.line_px(l) <= Neon.ATLAS_W, "venue %s: \"%s\" is %d px (the atlas is %d)" % [id, l, Storefronts.line_px(l), Neon.ATLAS_W])


# 2. ------------------------------------------------------------------------------------------

func _check_picks(sf: Storefronts, data: Dictionary, book: Notebook, graph: LaneGraph) -> void:
	_expect(sf.triple_at.size() == Storefronts.TRIPLES.size(), "triple corners: %d junctions found (want %d)" % [sf.triple_at.size(), Storefronts.TRIPLES.size()])
	_expect(sf.shops.size() >= 130, "Frogs: %d picked (want 130 or more)" % sf.shops.size())
	var lm := Storefronts.landmark_index(data.get("landmarks", []))
	var per_triple := {}
	var plain: Array[Vector2] = []
	for s in sf.shops:
		var r: Vector2 = s["road"]
		if s["triple"] != "":
			if not s["spare"]:
				per_triple[s["triple"]] = int(per_triple.get(s["triple"], 0)) + 1
				_triple_n += 1
			continue
		plain.append(r)
		_expect(s.get("real", false), "Frogs at %.0f, %.0f is not a real convenience shop" % [r.x, r.y])
		_expect(not Storefronts.on_landmark(lm, s["bld"]), "Frogs at %.0f, %.0f on a landmark" % [r.x, r.y])
	for i in plain.size():
		for k in range(i + 1, plain.size()):
			_expect(plain[i].distance_to(plain[k]) >= Storefronts.SPACING - 0.01, "Frogs %.0f m apart at %.0f, %.0f" % [plain[i].distance_to(plain[k]), plain[i].x, plain[i].y])
	# Every plain Frogs is a `fr` convenience poi of the data.
	var fr_pois := 0
	for p: Dictionary in data.get("pois", []):
		fr_pois += int(str(p.get("k", "")) == "convenience" and int(p.get("fr", 0)) == 1)
	# 80 % rounded down: the 70 m spacing alone decides the last one or two (map review C, 2026-11-02:
	# with Złota car-free a corner shop's door moved round to Zgoda and the pick came to 130 of 163).
	_expect(plain.size() >= floori(fr_pois * 0.8) and plain.size() <= fr_pois, "Frogs: %d plain of %d convenience pois with fr" % [plain.size(), fr_pois])
	for id: String in Storefronts.TRIPLES:
		_expect(int(per_triple.get(id, 0)) == 3, "triple corner %s: %d Frogs (want 3)" % [id, per_triple.get(id, 0)])
		var angs: Array[float] = []
		for s in sf.shops:
			if s["triple"] == id and not s["spare"]:
				angs.append(((s["bld"] as Vector2) - sf.triple_at[id]).angle())
		for a in angs.size():
			for b in range(a + 1, angs.size()):
				_expect(absf(angle_difference(angs[a], angs[b])) >= deg_to_rad(59.0), "triple corner %s: two Frogs within 60°" % id)
	# A building's wall within reach of each (2D): the game's rays (_wall) find it on the colliders.
	var grid := _building_grid(data.get("buildings", []))
	var walled := 0
	var n := 0
	for s in sf.shops:
		if s.has("corner"):
			continue
		n += 1
		if _hit_building(grid, data["buildings"], s["road"], s["bld"], Storefronts.RAY_FAR, Storefronts.SHOP_ROOF):
			walled += 1
	_expect(walled >= n * 0.8, "Frogs: %d of %d have a building's wall within reach (want 80 %%)" % [walled, n])
	# The venues: every one, its name, its wall.
	var at := {}
	for p: Dictionary in book.places:
		at[str(p["id"])] = p
	var seen := {}
	for v in sf.venues:
		seen[v["id"]] = true
		if (Storefronts.CAFES.has(v["id"]) or Storefronts.LOUNGES.has(v["id"]) or Storefronts.TRENDY.has(v["id"])):
			continue
		# The food-hype venues (Storefronts.HYPE) aren't notebook places: no name to match, the wall still.
		if not Storefronts.HYPE.has(v["id"]) and not Storefronts.CINEMAS.has(v["id"]) and not Storefronts.NOWY_SWIAT.has(v["id"]) and not Storefronts.POWISLE.has(v["id"]) and not Storefronts.MARSZALKOWSKA.has(v["id"]) and not Storefronts.KRAKOWSKIE.has(v["id"]) and not Storefronts.ZBAWICIELA.has(v["id"]) and not Storefronts.NOWOGRODZKA.has(v["id"]) and not Storefronts.MAZOWIECKA.has(v["id"]) and not Storefronts.WILCZA.has(v["id"]) and not Storefronts.PRAGA.has(v["id"]) and not Storefronts.VIADUKT.has(v["id"]) and not Storefronts.zaglebie_table().has(v["id"]):
			var name := str(at[v["id"]]["name_pl"]).to_upper()
			var joined := " ".join(v["lines"] as Array)
			_expect(joined == name or name.begins_with(joined + " "), "venue %s: the sign says \"%s\", places.json \"%s\"" % [v["id"], joined, name])
		var ok := false
		var road: Vector2 = v["road"]
		for turn: float in [0.0, 0.3, -0.3, 0.6, -0.6, 1.0, -1.0, 1.57, -1.57, 2.2, -2.2, PI]:
			if _hit_building(grid, data["buildings"], road, road + ((v["bld"] as Vector2) - road).rotated(turn), Storefronts.CORNER_FAR, 2.0):
				ok = true
				break
		_expect(ok, "venue %s: no building's wall within reach of %.0f, %.0f" % [v["id"], road.x, road.y])
	for id: String in Storefronts.VENUES:
		if (Storefronts.CAFES.has(id) or Storefronts.LOUNGES.has(id) or Storefronts.TRENDY.has(id)):
			continue
		_expect(seen.has(id), "venue %s: not placed (no address, poi or road)" % id)
	var want_signs := 18 + Storefronts.CAFES.size() + Storefronts.LOUNGES.size() + Storefronts.TRENDY.size() + Storefronts.HYPE.size() + Storefronts.zaglebie_table().size() + Storefronts.CINEMAS.size() + Storefronts.NOWY_SWIAT.size() + Storefronts.POWISLE.size() + Storefronts.MARSZALKOWSKA.size() + Storefronts.KRAKOWSKIE.size() + Storefronts.ZBAWICIELA.size() + Storefronts.NOWOGRODZKA.size() + Storefronts.MAZOWIECKA.size() + Storefronts.WILCZA.size() + Storefronts.PRAGA.size() + Storefronts.VIADUKT.size()
	_expect(sf.venues.size() == want_signs, "venues: %d signs (want %d: 17 venues, Glon twice, %d Coffeechairs, %d shisha lounges, %d trend spots, %d food-hype spots, %d Zagłębie Kebabowe, %d cinemas, %d Nowy Świat shops, %d Powiśle shops, %d Marszałkowska shops, %d Krakowskie shops, %d Plac Zbawiciela cafés, %d Nowogrodzka bars, %d Mazowiecka clubs, %d Wilcza bars, %d Praga bars, %d viaduct bars)" % [sf.venues.size(), want_signs, Storefronts.CAFES.size(), Storefronts.LOUNGES.size(), Storefronts.TRENDY.size(), Storefronts.HYPE.size(), Storefronts.zaglebie_table().size(), Storefronts.CINEMAS.size(), Storefronts.NOWY_SWIAT.size(), Storefronts.POWISLE.size(), Storefronts.MARSZALKOWSKA.size(), Storefronts.KRAKOWSKIE.size(), Storefronts.ZBAWICIELA.size(), Storefronts.NOWOGRODZKA.size(), Storefronts.MAZOWIECKA.size(), Storefronts.WILCZA.size(), Storefronts.PRAGA.size(), Storefronts.VIADUKT.size()])
	# Leżaks and metro entrances: off the lanes; one standing.
	var standing := 0
	for s in sf.scooters:
		var p: Vector3 = s["at"]
		standing += int(s["up"])
		_expect(graph.snap(Vector2(p.x, p.z), 2.0).is_empty(), "Leżak on a lane at %.1f, %.1f" % [p.x, p.z])
	_expect(standing == 1, "Leżaks: %d standing (want 1, easter_lezak)" % standing)
	var nz := 0
	var nl := 0
	var nm := 0
	for p: Dictionary in data.get("pois", []):
		var k := str(p.get("k", ""))
		nz += int(k == "scooter_zone")
		nl += int(k == "scooter")
		nm += int(k == "subway_entrance" and int(p.get("u", 0)) != 1)
	_expect(sf.scooters.size() == nl and sf.zones.size() == nz, "Leżaks: %d in %d zones (the data has %d and %d)" % [sf.scooters.size(), sf.zones.size(), nl, nz])
	_expect(sf.metros.size() == nm and nm >= 60, "metro entrances: %d (the data has %d street ones)" % [sf.metros.size(), nm])
	var nd := 0
	for p: Dictionary in data.get("pois", []):
		nd += int(str(p.get("k", "")) == "bicycle_rental")
	_expect(sf.docks.size() == nd and nd >= 80, "Rowerilo docks: %d (the data has %d)" % [sf.docks.size(), nd])
	for d in sf.docks:
		_expect(int(d["n"]) >= 4 and int(d["n"]) <= 8, "a dock with %d bikes" % int(d["n"]))
	var stood := 0
	for z in sf.zones:
		stood += int(z["standing"])
	_expect(stood == 1, "zones: %d standing (want 1)" % stood)
	var roofs := 0
	for s in sf.scooters:
		var p: Vector3 = s["at"]
		roofs += int(p.y > sf.map.ground_height(p.x, p.z) + 2.0)
	_expect(roofs == 12, "Leżaks: %d on a shelter roof (want 12)" % roofs)
	for m in sf.metros:
		_expect(str(m["station"]) != "", "a metro entrance without a station")
	for id: String in Storefronts.NAMED_STANDS:
		_expect(at.has(id), "named kebab stand %s: no place" % id)
	for id: String in Storefronts.STAND_TAGS:
		_expect(at.has(id), "kebab stand tag %s: no place" % id)
	for w: String in Storefronts.BILLBOARDS:
		_expect(at.has(Storefronts.BILLBOARDS[w][0]), "billboard %s: no place %s" % [w, Storefronts.BILLBOARDS[w][0]])


func _building_grid(blds: Array) -> Dictionary:
	var grid := {}
	for i in blds.size():
		var p: Array = blds[i]["p"]
		var lo := Vector2(INF, INF)
		var hi := -lo
		for k in range(0, p.size(), 2):
			lo = lo.min(Vector2(p[k], p[k + 1]))
			hi = hi.max(Vector2(p[k], p[k + 1]))
		for cx in range(floori(lo.x / 64.0), floori(hi.x / 64.0) + 1):
			for cz in range(floori(lo.y / 64.0), floori(hi.y / 64.0) + 1):
				var c := Vector2i(cx, cz)
				if not grid.has(c):
					grid[c] = []
				(grid[c] as Array).append(i)
	return grid


## The first building outline the segment from `road` towards `bld` (up to `far` m) crosses is
## at least `tall` m high.
func _hit_building(grid: Dictionary, blds: Array, road: Vector2, bld: Vector2, far: float, tall: float) -> bool:
	var dir := (bld - road).normalized()
	var reach := minf(far, road.distance_to(bld) + 25.0)
	var to := road + dir * reach
	var best := INF
	var best_h := 0.0
	var seen := {}
	var steps := ceili(reach / 32.0) + 1
	for k in steps + 1:
		var q := road.lerp(to, float(k) / steps)
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for i: int in grid.get(Vector2i(floori(q.x / 64.0) + dx, floori(q.y / 64.0) + dz), []):
					if seen.has(i):
						continue
					seen[i] = true
					var p: Array = blds[i]["p"]
					var m := p.size() / 2
					for e in m:
						var a := Vector2(p[e * 2], p[e * 2 + 1])
						var b := Vector2(p[(e + 1) % m * 2], p[(e + 1) % m * 2 + 1])
						var x: Variant = Geometry2D.segment_intersects_segment(road, to, a, b)
						if x != null:
							var d := road.distance_to(x)
							if d < best:
								best = d
								best_h = float(blds[i]["h"])
	return best < INF and best_h >= tall


# 3. ------------------------------------------------------------------------------------------

func _check_words(lines: Dictionary) -> void:
	var deny := _denylist()
	var world: Array[String] = ["FROGS", "24", "M", "HOT DOG GRATIS! · FREE HOT DOG!"]
	for id: String in Storefronts.VENUES:
		for l: String in Storefronts.VENUES[id][0]:
			world.append(l)
	for id: String in Storefronts.NAMED_STANDS:
		world.append(Storefronts.NAMED_STANDS[id][0])
	for w: String in Storefronts.BILLBOARDS:
		world.append(w)
	# The landmarks' own signs (towers' crowns, Centrum LIM's tenants, the roof screens' adverts).
	for w: String in Neon.LANDMARK_WORDS:
		world.append(w)
	for g: String in GROUPS:
		_expect(lines.has(g), "dialogue.json: no group %s" % g)
		for l: Array in lines.get(g, []):
			_expect(l.size() >= 2 and str(l[0]) != "" and str(l[1]) != "", "%s: a line without PL + EN (%s)" % [g, l])
			var pl := str(l[0])
			_expect(pl.length() <= 70 or pl in OLD_LONG, "%s: %d characters: %s" % [g, pl.length(), pl])
			for k in mini(2, l.size()):
				var hit := _deny_hit(str(l[k]), deny)
				_expect(hit == "", "%s: a real name (%s) in \"%s\"" % [g, hit, l[k]])
			# The parodies' own signs and posters (the older ones are eggs.gd's: BACKLOG).
			if g in ["signs", "column_posters"]:
				for w in ["FROGS", "PODWÓZKA", "PĘDZIK", "LEŻAK"]:
					if pl.to_upper().contains(w):
						world.append(pl.to_upper())
						break
	for s in world:
		var hit := _deny_hit(s, deny)
		_expect(hit == "", "a real name (%s) on a sign: \"%s\"" % [hit, s])
		for c in s.to_upper():
			_expect(c == " " or PixelFont.GLYPHS.has(c) or PixelFont.MARKED.has(c), "the pixel font has no \"%s\" (in \"%s\")" % [c, s])


func _denylist() -> Array[String]:
	var out: Array[String] = []
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	if not json is Dictionary:
		problems.append("data/brand_denylist.json is missing or does not parse")
		return out
	for key in ["names", "rejected"]:
		for n in json.get(key, []):
			out.append(str(n).to_lower())
	return out


## The denylisted name `text` holds as a whole word or phrase (check_places.gd's rule), or "".
static func _deny_hit(text: String, deny: Array[String]) -> String:
	var low := text.to_lower()
	for n in deny:
		var from := 0
		while true:
			var i := low.find(n, from)
			if i < 0:
				break
			var before := low[i - 1] if i > 0 else " "
			var after := low[i + n.length()] if i + n.length() < low.length() else " "
			if not _wordy(before) and not _wordy(after):
				return n
			from = i + 1
	return ""


static func _wordy(c: String) -> bool:
	return c.to_upper() != c.to_lower() or c.is_valid_int()


# 4. ------------------------------------------------------------------------------------------

## A 20 m facade (a 20 × 10 × 10 m box under a sector root, its face at z = -5, x 4990-5010).
func _check_wall(sf: Storefronts) -> float:
	var sector := Node3D.new()
	sector.name = "s_9_0"
	root.add_child(sector)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 10.0, 10.0)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(5000.0, 5.0, -10.0)
	sector.add_child(body)
	var small := StaticBody3D.new()
	var sshape := CollisionShape3D.new()
	var sbox := BoxShape3D.new()
	sbox.size = Vector3(2.0, 10.0, 2.0)
	sshape.shape = sbox
	small.add_child(sshape)
	small.position = Vector3(5100.0, 5.0, -6.0)
	sector.add_child(small)
	await physics_frame
	await physics_frame
	var space := sf.get_world_3d().direct_space_state
	var w := sf._wall(space, Vector2(5003.0, 4.0), Vector2(5001.0, -10.0), Storefronts.SHOP_SIDE, Storefronts.SHOP_ROOF)
	var off := INF
	if w.is_empty():
		problems.append("wall: no wall found on the synthetic facade")
	else:
		var p: Vector3 = w["p"]
		var n: Vector3 = w["n"]
		_expect(absf(p.z + 5.0) < 0.05 and n.distance_to(Vector3(0, 0, 1)) < 0.01, "wall: at %s facing %s (want z -5, +z)" % [p, n])
		off = absf(p.z + 5.0) + 0.14
		_expect(off <= 0.3, "wall: a sign %.2f m off the facade (want within 0.3)" % off)
	var w2 := sf._wall(space, Vector2(5100.0, 4.0), Vector2(5100.0, -8.0), Storefronts.SHOP_SIDE, 0.5)
	_expect(w2.is_empty(), "wall: a 2 m wall taken for a shop's %.1f m" % (Storefronts.SHOP_SIDE * 2.0))
	sector.queue_free()
	return off


# 5. ------------------------------------------------------------------------------------------

func _check_hooks(sf: Storefronts, dlg: FakeDialogue, hud: FakeHud, wallet: Wallet, eggs: EggBook) -> float:
	# Twelve shops "on their walls" (the game's rays do this at sector load).
	var picked: Array[int] = []
	for i in sf.shops.size():
		if sf.shops[i]["triple"] != "" or picked.size() >= 12:
			continue
		var r: Vector2 = sf.shops[i]["road"]
		sf.shops[i]["door"] = r
		sf.shops[i]["state"] = 1
		picked.append(i)
	sf._index_doors()
	sf.stamps = 0
	wallet.keep["frogs_today"] = []
	wallet.keep["frogs_day"] = EggBook.today()
	var door: Vector2 = sf.shops[picked[0]]["door"]
	# At 30 km/h past the door: nothing.
	veh = [Vector3(door.x, 0.0, door.y), 30.0, false]
	_frames(sf, 4.0)
	_expect(sf.stamps == 0, "stamps: %d at 30 km/h (want 0)" % sf.stamps)
	# Stopped 3 s: one stamp, its toast and line.
	veh = [Vector3(door.x + 1.0, 0.0, door.y), 0.0, false]
	_frames(sf, 3.0)
	_expect(sf.stamps == 1 and hud.toasts.size() == 1 and dlg.count("rechotka", "stamp") == 1,
			"stamps: %d, %d toasts, %d stamp lines after a stop (want 1 each)" % [sf.stamps, hud.toasts.size(), dlg.count("rechotka", "stamp")])
	# Staying, and coming back: no second stamp today.
	_frames(sf, 5.0)
	veh = [Vector3(door.x + 300.0, 0.0, door.y), 0.0, false]
	_frames(sf, 1.0)
	veh = [Vector3(door.x + 1.0, 0.0, door.y), 0.0, false]
	_frames(sf, 3.0)
	_expect(sf.stamps == 1, "stamps: %d after the same shop again (want 1)" % sf.stamps)
	# The card at 9: the next shop is the free hot dog (+10 respect once), then a new card.
	sf.preset_stamps(9)
	var r0 := wallet.respect
	var d2: Vector2 = sf.shops[picked[1]]["door"]
	veh = [Vector3(d2.x, 0.0, d2.y), 0.0, false]
	_frames(sf, 3.0)
	_expect(wallet.respect - r0 == Storefronts.FREE_RESPECT and sf.stamps == 0 and hud.notes.size() == 1,
			"free hot dog: +%d respect, card %d, %d notes (want +%d, 0, 1)" % [wallet.respect - r0, sf.stamps, hud.notes.size(), Storefronts.FREE_RESPECT])
	_frames(sf, 4.0)
	_expect(wallet.respect - r0 == Storefronts.FREE_RESPECT, "free hot dog: paid again (+%d)" % (wallet.respect - r0))
	# The knock: the car through a lying Leżak at 20 km/h moves it 1-3 m, one aside a minute.
	var li := -1
	for i in sf.scooters.size():
		if not sf.scooters[i]["up"]:
			li = i
			break
	var at0: Vector3 = sf.scooters[li]["at"]
	veh = [at0 + Vector3(0.5, 0.0, 0.0), 20.0, false]
	sf._process(1.0 / 60.0)
	var moved := Vector2(at0.x, at0.z).distance_to(Vector2(sf.scooters[li]["at"].x, sf.scooters[li]["at"].z))
	_expect(moved >= 0.29 and moved <= 3.01, "knock: the Leżak moved %.2f m (want 1-3, or 0.3 by a lane)" % moved)
	_expect(dlg.bubbles.n == 1, "knock: %d asides (want 1)" % dlg.bubbles.n)
	var at1: Vector3 = sf.scooters[li]["at"]
	veh = [at1 + Vector3(0.3, 0.0, 0.0), 20.0, false]
	sf._process(1.0 / 60.0)
	_expect(dlg.bubbles.n == 1, "knock: a second aside within the minute")
	# The eggs on synthetic stops: within their reach, still, 2 s.
	for id: String in ["easter_rechotka", "easter_lezak"]:
		_expect(eggs.by_id.has(id), "eggs.json: no %s card" % id)
		if not eggs.by_id.has(id):
			continue
		var e: Dictionary = eggs.eggs[eggs.by_id[id]]
		var pos: Vector2 = e.get("at", Vector2.INF)
		_expect(pos != Vector2.INF, "%s: not placed (move_egg)" % id)
		if pos == Vector2.INF:
			continue
		var mem := {}
		var fired := false
		for k in 6:
			fired = EggBook.step(e, {"pos": Vector3(pos.x + 3.0, 0.0, pos.y), "kmh": 0.0, "hour": 23.0, "weekday": 5}, mem, 0.5) or fired
		_expect(fired, "%s: didn't fire on a 3 s stop at its place" % id)
		var mem2 := {}
		var bad := false
		for k in 10:
			bad = EggBook.step(e, {"pos": Vector3(pos.x + 3.0, 0.0, pos.y), "kmh": 40.0, "hour": 23.0, "weekday": 5}, mem2, 0.5) or bad
			bad = EggBook.step(e, {"pos": Vector3(pos.x + 80.0, 0.0, pos.y), "kmh": 0.0, "hour": 23.0, "weekday": 5}, mem2, 0.5) or bad
		_expect(not bad, "%s: fired at 40 km/h or 80 m away" % id)
		var rb := wallet.respect
		_expect(eggs.record(id) and not eggs.record(id), "%s: not recorded once" % id)
		_expect(wallet.respect - rb == int(e["reward"]["respect"]), "%s: paid %d (want %d)" % [id, wallet.respect - rb, e["reward"]["respect"]])
	# The cost: the hook a frame, moving past the doors (the 2 Hz tick and the knock's cells).
	sf.spent_usec = 0
	var frames := 3000
	for k in frames:
		var q := door + Vector2(float(k % 600) * 0.3, 0.0)
		veh = [Vector3(q.x, 0.0, q.y), 25.0, false]
		sf._process(1.0 / 60.0)
	var us := float(sf.spent_usec) / frames
	_expect(us < 50.0, "cost: %.1f µs a frame (budget 50)" % us)
	return us


func _frames(sf: Storefronts, seconds: float) -> void:
	for k in roundi(seconds * 60.0):
		sf._process(1.0 / 60.0)


# 6. ------------------------------------------------------------------------------------------

func _check_meshes() -> Array[int]:
	var out: Array[int] = []
	var rows: Array = [[Props.frogs_shop(), 600, "Frogs shop"], [Props.lezak(), 120, "Leżak"], [Props.pedzik_rider(), 300, "Pędzik rider"]]
	# The metro entrances: the three forms with a lift, each into a mesh of its own (≤ 900 triangles).
	for form: String in ["canopy", "steps", "footway"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Props.add_metro_entrance(st, Transform3D.IDENTITY, form, true)
		rows.append([st.commit(), 900, "metro entrance " + form])
	for row: Array in rows:
		var m: ArrayMesh = row[0]
		var n := 0
		for s in m.get_surface_count():
			var a := m.surface_get_arrays(s)
			var idx: Variant = a[Mesh.ARRAY_INDEX]
			n += (idx as PackedInt32Array).size() / 3 if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		_expect(n <= int(row[1]), "%s: %d triangles (budget %d)" % [row[2], n, row[1]])
		out.append(n)
	return out
