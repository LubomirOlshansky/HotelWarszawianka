extends SceneTree
## Zagłębie Kebabowe (scripts/zaglebie.gd, docs/design/zaglebie-kebabowe.md), headless, from
## data/dialogue.json and the committed map data (map/centrum.json):
##   1. the shops' data: five, unique ids and tags, every neon line drawable in the pixel font, a
##      sign for Kino Femina and for each shop in Storefronts.VENUES, no real brand on any sign;
##   2. the words: each shop has 2+ `kebab_vendor` lines under its tag and the welcome has 4+,
##      Polish and English, the Polish at most 70 characters, no real brand;
##   3. the places on the real map: every shop's door and Femina within 150 m of each other, the
##      doors 15 m or more apart, each door within 25 m of a lane of the lane graph, Femina's sign
##      on a building's wall within reach;
##   4. the pay rules: the Royal Set pays ×1.25, Stambuł ×1.25 at night only, the craft kebab ×1.6
##      when waited for and its fair time ×1.5 longer, Erdal's tip doubles, a stand of the map's own
##      pays as before;
##   5. Szlak Szpili: the trail completes on the fifth different shop once (repeats and a stand of the
##      map's own never complete it twice).
## Prints "check_zaglebie: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_zaglebie.gd

const Zaglebie := preload("res://scripts/zaglebie.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Fakes := preload("res://tools/fakes.gd")
const BUBBLE := 70

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		problems.append(msg)


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	var dlg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	_check_shops(deny, digest)
	_check_words(dlg, deny, digest)
	_check_rules(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := Fakes.FlatMap.new()
	root.add_child(map)
	_check_places(data, LaneGraph.new(data["graph"], map), digest)
	if problems.is_empty():
		print("check_zaglebie: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_zaglebie: %d problems" % problems.size())
		quit(1)


static func _deny_hit(text: String, deny: Dictionary) -> String:
	var t := text.to_lower()
	for n: String in deny["names"]:
		if t.contains(n):
			return n
	return ""


func _check_shops(deny: Dictionary, digest: PackedStringArray) -> void:
	_expect(Zaglebie.SHOPS.size() == 5, "%d shops (want 5)" % Zaglebie.SHOPS.size())
	var ids := {}
	var tags := {}
	var crafts := 0
	var venues := Storefronts.VENUES
	_expect(venues.has(Zaglebie.FEMINA_ID), "no sign for Kino Femina")
	for s: Dictionary in Zaglebie.SHOPS:
		_expect(not ids.has(s["id"]) and not tags.has(s["tag"]), "duplicate shop %s" % s["id"])
		ids[s["id"]] = true
		tags[s["tag"]] = true
		crafts += 1 if bool(s.get("craft", false)) else 0
		_expect(venues.has(s["id"]), "shop %s has no sign in Storefronts.VENUES" % s["id"])
		var lines: Array = s["lines"]
		_expect(lines == (venues[s["id"]][0] if venues.has(s["id"]) else lines), "shop %s: the sign and zaglebie.gd differ" % s["id"])
		for l: String in lines + [s["board"]]:
			_expect(PixelFont.width(l) > 0 and _drawable(l), "shop %s: \"%s\" has a letter the pixel font lacks" % [s["id"], l])
			_expect(_deny_hit(l, deny) == "", "shop %s: a real name in \"%s\"" % [s["id"], l])
	_expect(crafts == 1, "%d craft shops (want 1)" % crafts)
	for l: String in venues[Zaglebie.FEMINA_ID][0]:
		_expect(_drawable(l), "Femina: \"%s\" has a letter the pixel font lacks" % l)
	digest.append("5 shops + Femina sign, drawable, no brand")


static func _drawable(text: String) -> bool:
	for ch in text:
		if ch != " " and PixelFont.char_width(ch) == 0:
			return false
	return true


func _check_words(dlg: Dictionary, deny: Dictionary, digest: PackedStringArray) -> void:
	var n := 0
	for s: Dictionary in Zaglebie.SHOPS:
		var have := 0
		for l: Array in dlg.get("kebab_vendor", []):
			if l.size() > 2 and l[2] is Dictionary and l[2].get("only", "") == s["tag"]:
				have += 1
				n += 1
				_check_line(l, deny, "kebab_vendor/" + str(s["tag"]))
		_expect(have >= 2, "kebab_vendor: %d lines for %s (want 2+)" % [have, s["tag"]])
	var welcome := 0
	for l: Array in dlg.get("zaglebie", []):
		welcome += 1
		_check_line(l, deny, "zaglebie")
	_expect(welcome >= 4, "zaglebie: %d welcome lines (want 4+)" % welcome)
	digest.append("%d vendor lines + %d lore lines, PL ≤ %d, PL + EN" % [n, welcome, BUBBLE])


func _check_line(l: Array, deny: Dictionary, where: String) -> void:
	_expect(l.size() >= 2 and str(l[0]) != "" and str(l[1]) != "", "%s: a line without PL + EN" % where)
	_expect(str(l[0]).length() <= BUBBLE, "%s: %d characters: %s" % [where, str(l[0]).length(), l[0]])
	for k in mini(2, l.size()):
		var hit := _deny_hit(str(l[k]), deny)
		_expect(hit == "", "%s: a real name (%s) in \"%s\"" % [where, hit, l[k]])


func _check_rules(digest: PackedStringArray) -> void:
	_expect(is_equal_approx(Zaglebie.pay("zag_krol", false, false), 1.25), "Royal Set: ×%f" % Zaglebie.pay("zag_krol", false, false))
	_expect(is_equal_approx(Zaglebie.pay("zag_stambul", false, false), 1.0), "Stambuł by day should pay ×1")
	_expect(is_equal_approx(Zaglebie.pay("zag_stambul", true, false), 1.25), "Stambuł at night should pay ×1,25")
	_expect(is_equal_approx(Zaglebie.pay("zag_rozen", false, true), Zaglebie.CRAFT_PAY), "the craft kebab waited for pays ×%f" % Zaglebie.CRAFT_PAY)
	_expect(is_equal_approx(Zaglebie.pay("zag_rozen", false, false), 1.0), "the plain one from the craft shop pays ×1")
	_expect(is_equal_approx(Zaglebie.fair("zag_rozen", true), Zaglebie.CRAFT_FAIR), "the craft kebab cools slower")
	_expect(Zaglebie.fair("zag_pasza", false) < 1.0, "Pasza's kebab is the quick one (a shorter fair time)")
	_expect(is_equal_approx(Zaglebie.tip("zag_erdal"), 2.0) and is_equal_approx(Zaglebie.tip("zag_krol"), 1.0), "only Erdal's tip doubles")
	_expect(is_equal_approx(Zaglebie.pay("", true, false), 1.0) and is_equal_approx(Zaglebie.fair("", false), 1.0), "a stand of the map's own pays as before")
	# The trail.
	var saved := ""
	var done_at := -1
	var k := 0
	for tag in ["zag_krol", "zag_krol", "", "zag_stambul", "zag_pasza", "zag_erdal", "zag_rozen", "zag_rozen", "zag_krol"]:
		var r := Zaglebie.trail_add(saved, tag)
		saved = r[0]
		if bool(r[1]):
			_expect(done_at < 0, "the trail completed twice (at %d and %d)" % [done_at, k])
			done_at = k
		k += 1
	_expect(done_at == 6, "the trail completed at step %d (want 6, the fifth different shop)" % done_at)
	_expect(Zaglebie.trail_done(saved).size() == 5, "the trail holds %d shops (want 5)" % Zaglebie.trail_done(saved).size())
	digest.append("pay ×1.25 / night ×1.25 / craft ×%.1f, trail pays once" % Zaglebie.CRAFT_PAY)


func _check_places(data: Dictionary, g: LaneGraph, digest: PackedStringArray) -> void:
	var origin: Array = data["origin"]
	var femina := Zaglebie.femina_at(origin)
	var pois := Zaglebie.extra_pois(origin)
	_expect(pois.size() == 5, "%d extra pois (want 5)" % pois.size())
	var worst := 0.0
	var tight := INF
	for i in pois.size():
		var p := Vector2(float(pois[i]["x"]), float(pois[i]["z"]))
		worst = maxf(worst, p.distance_to(femina))
		var door: Array = pois[i]["door"]
		var hit: Array = g.snap(Vector2(door[0], door[1]), 25.0)
		_expect(not hit.is_empty(), "shop %s: no lane within 25 m of its door (%.0f, %.0f)" % [pois[i]["zag"], p.x, p.y])
		for j in range(i + 1, pois.size()):
			tight = minf(tight, p.distance_to(Vector2(float(pois[j]["x"]), float(pois[j]["z"]))))
	_expect(worst <= 150.0, "a shop is %.0f m from Femina (want 150 or less)" % worst)
	_expect(tight >= 15.0, "two shops %.0f m apart (want 15 or more)" % tight)
	# Femina's pin is on a building's footprint or within 25 m of one.
	var near := INF
	for b: Dictionary in data["buildings"]:
		var pts: Array = b["p"]
		for k in range(0, pts.size(), 2):
			near = minf(near, femina.distance_to(Vector2(float(pts[k]), float(pts[k + 1]))))
	_expect(near <= 25.0, "Femina's pin is %.0f m from any building corner" % near)
	digest.append("shops within %.0f m of Femina, ≥ %.0f m apart, on lanes, Femina by a building (%.0f m)" % [worst, tight, near])
