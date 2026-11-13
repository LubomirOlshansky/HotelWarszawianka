extends SceneTree
## Loop 3h slice 1: the districts (districts.gd, data/districts.json; DEMO 2.3 and G3), map-free.
## Checks that:
## - every district has its names, a Polish line of at most 70 characters with its English, a
##   jobs goal, and a label inside itself; DEMO 2.3's five hero districts are flagged;
## - the areas cover the map's bounds (a 50 m grid: every point in some district) and known
##   places fall where they should (the Palace, the Market Square, the stadium, ...);
## - every place (places.json) and egg (eggs.json) names a district; a place's district is the
##   one its `near` hint falls in, an egg's is its place's; every hero district has at least
##   three places (its "?" marks);
## - discovery: the start's district quietly (no card, no respect), a new one with its card
##   ("Odkryto: Powiśle" above "Powiśle discovered") and +10 respect, once; the "?" marks are three
##   per discovered district, only its places not found, refilled when one is found;
## - completion: places + eggs + Syrenki found plus jobs up to the goal, over the same in all;
##   a job paid in a district counts there; the Syrenki hook adds to both sides;
## - a save from before districts (v1: places found) discovers their districts quietly;
## - the full map's fog covers the undiscovered districts only (full_map.gd `set_districts`);
## - the lookup is cheap (µs a check at 3 Hz).
## Nothing is saved (the wallet is not persistent).
##   godot --headless --path game --script res://tools/check_districts.gd

const Districts := preload("res://scripts/districts.gd")
const Lang := preload("res://scripts/lang.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Wallet := preload("res://scripts/wallet.gd")
const FullMap := preload("res://scripts/full_map.gd")
const Fakes := preload("res://tools/fakes.gd")
## The map's bounds (centrum.json `bounds` since map north, 2026-10-31: the L-shaped map's box).
const BOUNDS := Rect2(-3136.1, -2775.4, 5317.8, 4511.4)
const HEROES := ["srodmiescie", "trakt", "stare_miasto", "powisle", "praga"]
const KNOWN := {"palac_kultury": [Vector2(-1227, 243), "srodmiescie"], "rynek": [Vector2(-804, -1736), "stare_miasto"],
		"stadion": [Vector2(1486, -608), "praga"], "kopernik": [Vector2(307, -874), "powisle"],
		"rondo_daszynskiego": [Vector2(-2795, 442), "wola"], "trzech_krzyzy": [Vector2(-123, 575), "trakt"],
		"zbawiciela": [Vector2(-477, 1592), "poludnie"], "arkadia": [Vector2(-2529, -2565), "muranow"],
		"sejm": [Vector2(307, 984), "lazienki"], "palma": [Vector2(-170, 332), "srodmiescie"],
		"spawn": [Vector2(-911.6, 278.6), "srodmiescie"]}


var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	var d := Districts.new()
	_expect(d.load_data(), "districts.json loads")
	_data(d)
	var points := _points()
	_ties(d, points)
	_flow(points)
	_v1(points)
	_fog(points)
	_cost(d)
	d.free()
	if _problems == 0:
		print("check_districts: OK")
		quit(0)
	else:
		print("check_districts: %d problem(s)" % _problems)
		quit(1)


## Place id -> its `near` hint in map metres (no map).
func _points() -> Dictionary:
	var book := Notebook.new()
	book.load_places()
	var out := {}
	for p in book.places:
		var near: Array = p["near"]
		out[str(p["id"])] = Notebook.project([52.234, 21.024], float(near[0]), float(near[1]))
	book.free()
	return out


func _data(d: Districts) -> void:
	_expect(d.districts.size() >= 8, "%d districts" % d.districts.size())
	var heroes := []
	for x in d.districts:
		var id := str(x["id"])
		var line: Array = x.get("line", [])
		_expect(str(x.get("name_pl", "")) != "" and str(x.get("name_en", "")) != "", "%s: names" % id)
		_expect(line.size() == 2 and str(line[0]) != "" and str(line[1]) != "", "%s: line [pl, en]" % id)
		if line.size() == 2:
			_expect(str(line[0]).length() <= 70, "%s: Polish line %d characters" % [id, str(line[0]).length()])
		_expect(int(x.get("jobs_goal", 0)) > 0, "%s: jobs_goal" % id)
		_expect(d.district_at(x["at"]) == id, "%s: its label is in %s" % [id, d.district_at(x["at"])])
		if x.get("hero", false):
			heroes.append(id)
		var card := d.card_text(id)
		_expect(card[0].length() <= 70 and card[0].begins_with("Odkryto: "), "%s: card title %s" % [id, card[0]])
		# One language at a time (lang.gd): the Polish card has the Polish line, the English one the English.
		_expect(card[1].begins_with(str(line[0])), "%s: card's Polish %s" % [id, card[1].get_slice("\n", 0)])
		Lang.set_code("en")
		var card_en := d.card_text(id)
		Lang.set_code("pl")
		_expect(card_en[0] == "Discovered: %s" % x["name_en"] and card_en[1].begins_with(str(line[1])), "%s: card in English %s" % [id, card_en])
	heroes.sort()
	var want := HEROES.duplicate()
	want.sort()
	_expect(heroes == want, "hero districts %s" % [heroes])
	var holes := 0
	var x0 := BOUNDS.position.x
	while x0 <= BOUNDS.end.x:
		var z0 := BOUNDS.position.y
		while z0 <= BOUNDS.end.y:
			if d.district_at(Vector2(x0, z0)) == "":
				holes += 1
			z0 += 50.0
		x0 += 50.0
	_expect(holes == 0, "%d grid points of the map in no district" % holes)
	for k in KNOWN:
		var got := d.district_at(KNOWN[k][0])
		_expect(got == KNOWN[k][1], "%s in %s, wanted %s" % [k, got, KNOWN[k][1]])


func _ties(d: Districts, points: Dictionary) -> void:
	var places: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Districts.PLACES_PATH))
	var of_place := {}
	for p: Dictionary in places["places"]:
		var id := str(p["id"])
		var dist := str(p.get("district", ""))
		of_place[id] = dist
		_expect(d.by_id.has(dist), "place %s: district '%s'" % [id, dist])
		_expect(d.district_at(points[id]) == dist, "place %s: near falls in %s, says %s" % [id, d.district_at(points[id]), dist])
	var eggs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Districts.EGGS_PATH))
	for e: Dictionary in eggs["eggs"]:
		var dist := str(e.get("district", ""))
		_expect(d.by_id.has(dist), "egg %s: district '%s'" % [e["id"], dist])
		if of_place.has(str(e.get("place", ""))):
			_expect(of_place[e["place"]] == dist, "egg %s: district %s, its place's %s" % [e["id"], dist, of_place[e["place"]]])
	for h in HEROES:
		_expect((d.districts[d.by_id[h]]["places"] as Array).size() >= Districts.MARKS, "%s: fewer than %d places" % [h, Districts.MARKS])


func _flow(points: Dictionary) -> void:
	var w := Wallet.new()
	w.persistent = false
	var hud := Fakes.Hud.new()
	var d := Districts.new()
	d.wallet = w
	d.hud = hud
	_expect(d.setup(points), "setup")
	d.tick(KNOWN["spawn"][0])
	_expect(d.current == "srodmiescie" and w.district == "srodmiescie", "at the spawn: %s / %s" % [d.current, w.district])
	_expect(d.is_discovered("srodmiescie") and hud.notes.is_empty() and w.respect == 0, "the start's district: quietly (cards %d, respect %d)" % [
			hud.notes.size(), w.respect])
	_expect(d.marks().size() == Districts.MARKS, "marks after the start: %d" % d.marks().size())
	d.tick(KNOWN["kopernik"][0])
	_expect(d.is_discovered("powisle") and hud.notes.size() == 1 and w.respect == Districts.DISCOVER_RESPECT,
			"Powiśle discovered: cards %d, respect %d" % [hud.notes.size(), w.respect])
	if hud.notes.size() == 1:
		_expect(hud.note_titles[0] == "Odkryto: Powiśle" and str(hud.note_texts[0]).begins_with(str(d.districts[d.by_id["powisle"]]["line"][0])), "the card: %s / %s" % [hud.note_titles[0], hud.note_texts[0]])
	d.tick(KNOWN["kopernik"][0])
	d.tick(KNOWN["spawn"][0])
	d.tick(KNOWN["kopernik"][0])
	_expect(hud.notes.size() == 1, "a district's card more than once (%d)" % hud.notes.size())
	d.tick(KNOWN["stadion"][0], true)
	_expect(not d.is_discovered("praga") and d.current == "powisle", "away: nothing happens")
	var marks := d.marks()
	_expect(marks.size() == 2 * Districts.MARKS, "marks with two districts: %d" % marks.size())
	for m in marks:
		var in_d := d.district_at(m)
		_expect(in_d == "powisle" or in_d == "srodmiescie", "a mark in %s" % in_d)
	# A marked place found: it goes, the next one takes its place.
	var first: String = d._order["powisle"][0]
	w.notes[first] = 20261031
	var after := d.marks()
	_expect(after.size() == 2 * Districts.MARKS and not after.has(points[first]), "marks after a find: %d" % after.size())
	# Completion: Powiśle's places + eggs + goal.
	var x: Dictionary = d.districts[d.by_id["powisle"]]
	var total := (x["places"] as Array).size() + (x["eggs"] as Array).size() + int(x["jobs_goal"])
	_expect(d.progress("powisle") == Vector2i(1, total), "Powiśle after one place: %s of %d" % [d.progress("powisle"), total])
	w.pay(20, 1, "kebab")
	w.pay(20, 1, "kebab")
	_expect(int(w.district_jobs.get("powisle", 0)) == 2 and d.progress("powisle").x == 3, "two jobs in Powiśle: %s" % [d.progress("powisle")])
	for i in 5:
		w.pay(1, 0, "sloik")
	_expect(d.progress("powisle").x == 1 + int(x["jobs_goal"]), "jobs over the goal count up to it: %s" % [d.progress("powisle")])
	w.eggs[(x["eggs"] as Array)[0]] = 20261031
	_expect(d.progress("powisle").x == 2 + int(x["jobs_goal"]), "an egg: %s" % [d.progress("powisle")])
	d.add_syrenka("s_test", "powisle")
	_expect(d.progress("powisle").y == total + 1, "a Syrenka listed: %s" % [d.progress("powisle")])
	w.syrenki["s_test"] = 20261031
	_expect(d.progress("powisle").x == 3 + int(x["jobs_goal"]), "a Syrenka found: %s" % [d.progress("powisle")])
	for p in x["places"]:
		w.notes[p] = 1
	for e in x["eggs"]:
		w.eggs[e] = 1
	_expect(d.percent("powisle") == 100 and is_equal_approx(d.completion("powisle"), 1.0), "all of Powiśle: %d%%" % d.percent("powisle"))
	_expect(d.percent("praga") == 0 and d.percent_total() > 0 and d.percent_total() < 100, "Praga %d%%, all %d%%" % [d.percent("praga"), d.percent_total()])
	_expect(d.marks().size() == Districts.MARKS, "Powiśle complete: its marks gone (%d)" % d.marks().size())
	# --district= shows the card even for a district found already; --districts= presets.
	d.force_card = "srodmiescie"
	d.tick(KNOWN["kopernik"][0])
	_expect(hud.notes.size() == 2 and hud.note_titles[1] == "Odkryto: Śródmieście", "--district=: %d cards" % hud.notes.size())
	d.preset("none")
	_expect(w.districts.is_empty(), "--districts=none")
	d.preset("praga:2,wola")
	_expect(w.districts.has("praga") and w.districts.has("wola") and int(w.district_jobs.get("praga", 0)) == 2, "--districts=praga:2,wola: %s" % [w.districts])
	d.preset("all")
	_expect(w.districts.size() == d.districts.size(), "--districts=all")
	_expect(d.view().size() == d.districts.size() and d.view()[0].has("pct"), "view()")
	d.free()
	hud.free()
	w.free()


func _v1(points: Dictionary) -> void:
	var w := Wallet.new()
	w.persistent = false
	w.notes["stadion_narodowy"] = 20261028
	w.eggs["e17"] = 20261029  # Fontanny Podzamcze: the Old Town
	var d := Districts.new()
	d.wallet = w
	d.setup(points)
	_expect(w.districts.get("praga", 0) == 20261028 and w.districts.get("stare_miasto", 0) == 20261029 and w.districts.size() == 2,
			"a v1 record discovers its districts quietly: %s" % [w.districts])
	d.free()
	w.free()


func _fog(points: Dictionary) -> void:
	var w := Wallet.new()
	w.persistent = false
	var d := Districts.new()
	d.wallet = w
	d.setup(points)
	var fm := FullMap.new()
	fm.bounds = BOUNDS
	fm.set_districts(d.view(), d.percent_total())
	var all_fog := fm._fog.size()
	_expect(all_fog > 0 and all_fog % 3 == 0, "fog over nothing found: %d points" % all_fog)
	var area := 0.0
	for i in range(0, fm._fog.size() - 2, 3):
		area += absf((fm._fog[i + 1] - fm._fog[i]).cross(fm._fog[i + 2] - fm._fog[i])) * 0.5
	_expect(absf(area - BOUNDS.get_area()) < BOUNDS.get_area() * 0.01, "the fog covers %.0f of the bounds' %.0f m²" % [area, BOUNDS.get_area()])
	d.preset("all")
	fm.set_districts(d.view(), d.percent_total())
	_expect(fm._fog.is_empty(), "fog left with every district found: %d" % fm._fog.size())
	fm.free()
	d.free()
	w.free()


func _cost(d: Districts) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pts := PackedVector2Array()
	for i in 3000:
		pts.append(Vector2(rng.randf_range(BOUNDS.position.x, BOUNDS.end.x), rng.randf_range(BOUNDS.position.y, BOUNDS.end.y)))
	var t0 := Time.get_ticks_usec()
	for p in pts:
		d.district_at(p)
	var us := float(Time.get_ticks_usec() - t0) / pts.size()
	print("districts: %d districts, a lookup %.1f µs (3 a second)" % [d.districts.size(), us])
	_expect(us < 100.0, "a lookup takes %.1f µs" % us)
