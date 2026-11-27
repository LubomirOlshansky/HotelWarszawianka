extends SceneTree
## The garage loop (2026-10-31): Warsztat u Mirka's rules without the map (garage.gd,
## garage_card.gd's words, wallet.gd's [garage] section, car.gd `set_paint`, eggs E01 and E21).
##   - the paints: 8, ids unique, the factory red free and the default, black and green there
##     (the eggs need them), the gold one behind GOLD_EGGS egg cards, prices 50-150 zł (beta, F 2026-11-17) (ten paints since loop 3h slice 2: the Syrenki ones are free, opened by 5 and 20 Syrenki);
##   - the rule: on / switch / buy / short / locked for each case; when it shows (`open_rule`);
##   - the place (F 2026-11-24): SPOT is mirek.gd's forecourt, FACE its door, off the street;
##     MOJE AUTO (`mine_shows`) lists only the cars and paints owned;
##   - buying with enough money pays the price once and owns the paint; too little pays nothing;
##     switching to an owned paint (or the factory red) is free; the gold one opens at 5 eggs;
##   - a seeded walk of 200 taps (10 seeds): the złoty never go below 0, what was paid is the sum
##     of the prices of what was bought, nothing is bought twice;
##   - the save: paint and owned paints survive a save and a load (a scratch file);
##   - the car: `set_paint` recolours the body (its vertex colours), keeps its material and its
##     node count;
##   - Mirek's lines (dialogue.json "garage"): every tag the card asks for, Polish and English,
##     at most 70 characters;
##   - E01 (crowds.gd `door_egg` at Lusterko, egg_book.gd `fire` with its conditions: black, a
##     Friday or Saturday night, 23-06) and E21 (stop 2 s at Glon, green) fire on synthetic inputs,
##     not without their paint or time, and reward once (+50, +15).
## Prints `check_garage: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_garage.gd

const Garage := preload("res://scripts/garage.gd")
const Wallet := preload("res://scripts/wallet.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Car := preload("res://scripts/car.gd")
const Upgrades := preload("res://scripts/upgrades.gd")
const SCRATCH := "user://check_garage.cfg"
const TAGS := ["hello", "buy", "black", "green", "gold", "switch", "short", "locked", "parts", "tt", "nitro", "part", "max",
		"mine", "ask", "ask_yes", "ask_no", "cars", "style", "wing", "neon", "wing_buy", "neon_buy"]
const GarageCard := preload("res://scripts/garage_card.gd")
## F 2026-11-24: the workshop's building (the forecourt the game stops the car on is its frame's).
const Mirek := preload("res://scripts/landmarks/mirek.gd")

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_check_paints()
	_check_rules()
	_check_place()
	_check_buying()
	for seed_value in 10:
		_check_walk(seed_value + 1)
	_check_save()
	await _check_car()
	_check_lines()
	_check_eggs()
	_check_shop_rules()
	_check_shop_buying()
	_check_shop_save()
	await _check_shop_car()
	await _check_looks()
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	if problems.is_empty():
		print("check_garage: OK (%d paints, the rules, buying and switching, 10 seeded walks, the save, the car's paint, Mirek's %d tags, E01 and E21 once; G13: %d cars, nitro, %d parts x 3 levels, the shop's rules, buying, save, the car's model, tuning and nitro tank; %d looks)" % [
				Garage.PAINTS.size(), TAGS.size(), Upgrades.CARS.size(), Upgrades.PARTS.size(), Upgrades.LOOKS.size()])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_garage: %d problems" % problems.size())
		quit(1)


func _wallet(zl := 0) -> Node:
	var w: Node = Wallet.new()
	w.persistent = false
	w.zl = zl
	root.add_child(w)
	return w


func _garage(w: Node, eggs := 0) -> Node:
	var g: Node = Garage.new()
	g.wallet = w
	g.eggs_found = func() -> int: return eggs
	return g


func _check_paints() -> void:
	var ids := {}
	for p: Dictionary in Garage.PAINTS:
		var id := str(p["id"])
		if ids.has(id):
			problems.append("paint %s twice" % id)
		ids[id] = true
		var name: Array = p["name"]
		if name.size() != 2 or str(name[0]) == "" or str(name[1]) == "":
			problems.append("paint %s: a name without Polish and English" % id)
		var price := int(p["price"])
		if id == Garage.DEFAULT or p.has("eggs") or p.has("syrenki"):
			if price != 0:
				problems.append("paint %s: %d zł (want free)" % [id, price])
		elif price < 50 or price > 150:
			problems.append("paint %s: %d zł (want 50-150)" % [id, price])
	if Garage.PAINTS.size() < 6 or Garage.PAINTS.size() > 10:
		problems.append("%d paints (want 6-10)" % Garage.PAINTS.size())
	for need in ["red", "black", "green", "gold"]:
		if not ids.has(need):
			problems.append("no %s paint" % need)
	if int(Garage.find("black")["price"]) != 120:
		problems.append("black costs %d zł (want 120)" % int(Garage.find("black")["price"]))
	if int(Garage.find("gold").get("eggs", 0)) != Garage.GOLD_EGGS:
		problems.append("gold wants %d eggs (want %d)" % [int(Garage.find("gold").get("eggs", 0)), Garage.GOLD_EGGS])


func _expect(what: String, got: Variant, want: Variant) -> void:
	if got != want:
		problems.append("%s: %s (want %s)" % [what, got, want])


func _check_rules() -> void:
	var owned := {"blue": 1}
	_expect("rule red on", Garage.rule("red", "red", 0, {}, 0), "on")
	_expect("rule red from blue", Garage.rule("red", "blue", 0, owned, 0), "switch")
	_expect("rule blue owned", Garage.rule("blue", "red", 0, owned, 0), "switch")
	var black_zl := int(Garage.find("black")["price"])
	_expect("rule black at its price", Garage.rule("black", "red", black_zl, {}, 0), "buy")
	_expect("rule black a złoty short", Garage.rule("black", "red", black_zl - 1, {}, 0), "short")
	_expect("rule gold 4 eggs", Garage.rule("gold", "red", 9999, {}, 4), "locked")
	_expect("rule scale 4 syrenki", Garage.rule("scale", "red", 9999, {}, 99, 4), "locked")
	_expect("rule scale 5 syrenki", Garage.rule("scale", "red", 0, {}, 0, 5), "switch")
	_expect("rule gold 5 eggs", Garage.rule("gold", "red", 0, {}, 5), "switch")
	_expect("rule nothing", Garage.rule("chrome", "red", 0, {}, 0), "")
	_expect("shown, nothing earned", Garage.open_rule({}, 0, {}), false)
	_expect("shown, a kebab done", Garage.open_rule({"kebab": 1}, 0, {}), true)
	_expect("shown, money", Garage.open_rule({}, 25, {}), true)
	_expect("shown, a paint bought, spent out", Garage.open_rule({}, 0, {"black": 1}), true)


## F 2026-11-24: the forecourt (SPOT) is the building's (mirek.gd WM_FORECOURT), the door faces the
## way the car is put there (FACE), the place is off the street (RING clear of the carriageway's
## middle, WM_O), and MOJE AUTO shows only what is owned (garage_card.gd `mine_shows`).
func _check_place() -> void:
	var f: Vector2 = Mirek.mr_world(Mirek.WM_FORECOURT.x, Mirek.WM_FORECOURT.y)
	if f.distance_to(Garage.SPOT) > 0.3:
		problems.append("place: SPOT %s is %.2f m from mirek.gd's forecourt %s" % [Garage.SPOT, f.distance_to(Garage.SPOT), f])
	var v: Vector2 = Mirek.mr_world(0.0, 1.0) - Mirek.mr_world(0.0, 0.0)
	if v.dot(Garage.FACE) < 0.999:
		problems.append("place: FACE %s is not the hall's way in %s" % [Garage.FACE, v])
	if Mirek.WM_FORECOURT.y - Garage.RING < 5.0:
		problems.append("place: the forecourt's ring reaches the carriageway (v %.1f)" % (Mirek.WM_FORECOURT.y - Garage.RING))
	_expect("mine: a car owned", GarageCard.mine_shows("car", "switch"), true)
	_expect("mine: the car driven", GarageCard.mine_shows("car", "on"), true)
	_expect("mine: a car not bought", GarageCard.mine_shows("car", "buy"), false)
	_expect("mine: a car too dear", GarageCard.mine_shows("car", "short"), false)
	_expect("mine: a part", GarageCard.mine_shows("part", "on"), false)
	_expect("mine: the nitro owned", GarageCard.mine_shows("nitro", "owned"), false)
	_expect("mine: a paint owned", GarageCard.mine_shows("paint", "switch"), true)
	_expect("mine: a paint not bought", GarageCard.mine_shows("paint", "buy"), false)
	_expect("mine: a locked paint", GarageCard.mine_shows("paint", "locked"), false)


func _check_buying() -> void:
	var w := _wallet(119)
	var g := _garage(w)
	_expect("buy black with 119 zł", g.choose("black"), "short")
	_expect("119 zł after", int(w.zl), 119)
	_expect("black owned after short", w.paints.has("black"), false)
	w.zl = 270
	_expect("buy black with 270 zł", g.choose("black"), "buy")
	_expect("zł after black", int(w.zl), 150)
	_expect("black owned", w.paints.has("black"), true)
	_expect("paint after buying", str(w.paint), "black")
	_expect("black again", g.choose("black"), "on")
	_expect("back to red", g.choose("red"), "switch")
	_expect("zł after red", int(w.zl), 150)
	_expect("back to black", g.choose("black"), "switch")
	_expect("zł after switching", int(w.zl), 150)
	_expect("gold with 4 eggs", g.choose("gold"), "locked")
	g.eggs_found = func() -> int: return 5
	_expect("gold with 5 eggs", g.choose("gold"), "switch")
	_expect("zł after gold", int(w.zl), 150)
	_expect("gold kept", w.paints.has("gold"), true)
	g.free()
	w.free()


## 200 seeded taps on random paints with random money coming in.
func _check_walk(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919
	var w := _wallet(0)
	var eggs := [0]
	var g := _garage(w)
	g.eggs_found = func() -> int: return eggs[0]
	var paid := 0
	var earned := 0
	var bought := {}
	for i in 200:
		if rng.randf() < 0.3:
			var pay := rng.randi_range(10, 120)
			w.zl += pay
			earned += pay
		if rng.randf() < 0.03:
			eggs[0] += 1
		var p: Dictionary = Garage.PAINTS[rng.randi() % Garage.PAINTS.size()]
		var id := str(p["id"])
		var before := int(w.zl)
		var r: String = g.choose(id)
		if r == "buy":
			if bought.has(id):
				problems.append("seed %d: %s bought twice" % [seed_value, id])
			bought[id] = true
			paid += int(p["price"])
			if before - int(w.zl) != int(p["price"]):
				problems.append("seed %d: %s took %d zł (price %d)" % [seed_value, id, before - int(w.zl), int(p["price"])])
		elif int(w.zl) != before:
			problems.append("seed %d: a %s tap on %s changed the wallet" % [seed_value, r, id])
		if int(w.zl) < 0:
			problems.append("seed %d: the wallet went to %d zł" % [seed_value, w.zl])
		if r in ["buy", "switch"] and str(w.paint) != id:
			problems.append("seed %d: %s chosen, %s on the car" % [seed_value, id, w.paint])
	if earned - paid != int(w.zl):
		problems.append("seed %d: earned %d, paid %d, left %d" % [seed_value, earned, paid, w.zl])
	g.free()
	w.free()


func _check_save() -> void:
	var w := _wallet(500)
	w.persistent = true
	w.path = SCRATCH
	var g := _garage(w)
	g.choose("green")
	g.choose("blue")
	w.save()
	var back := _wallet(0)
	back.persistent = true
	back.path = SCRATCH
	back.load_save()
	_expect("saved paint", str(back.paint), "blue")
	_expect("saved owned", back.paints.keys().size(), 2)
	_expect("saved zł", int(back.zl), 500 - int(Garage.find("green")["price"]) - int(Garage.find("blue")["price"]))
	_expect("green kept", back.paints.has("green"), true)
	# An old save (no [garage] section): the factory red, nothing owned.
	var old := ConfigFile.new()
	old.set_value("wallet", "zl", 77)
	old.save(SCRATCH)
	var w2 := _wallet(0)
	w2.persistent = true
	w2.path = SCRATCH
	w2.load_save()
	_expect("old save's paint", str(w2.paint), "red")
	_expect("old save's zł", int(w2.zl), 77)
	_expect("old save's paints", w2.paints.size(), 0)
	g.free()
	for n in [w, back, w2]:
		n.free()


func _check_car() -> void:
	var car: CharacterBody3D = Car.new()
	root.add_child(car)
	await process_frame
	var body: MeshInstance3D = car.get("_body_mesh")
	if body == null:
		problems.append("car: no body mesh")
		car.free()
		return
	var mat := body.material_override
	var nodes := car.find_children("*", "", true, false).size()
	var w := _wallet(1000)
	var g := _garage(w)
	g.car = car
	g.choose("black")
	var black: Dictionary = Garage.find("black")
	if car.get("paint") != black["paint"]:
		problems.append("car: paint %s after black (want %s)" % [car.get("paint"), black["paint"]])
	if body.material_override != mat:
		problems.append("car: the body's material changed")
	if car.find_children("*", "", true, false).size() != nodes:
		problems.append("car: %d nodes after painting (was %d)" % [car.find_children("*", "", true, false).size(), nodes])
	var cols: PackedColorArray = (body.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var has_black := false
	var has_red := false
	for c in cols:
		has_black = has_black or c.is_equal_approx(black["paint"])
		has_red = has_red or c.is_equal_approx(Color("#d8432f"))
	if not has_black or has_red:
		problems.append("car: the body's colours after black: black %s, red %s" % [has_black, has_red])
	g.free()
	w.free()
	car.free()


func _check_lines() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var group: Array = (d as Dictionary).get("garage", []) if d is Dictionary else []
	var seen := {}
	for l: Array in group:
		if l.size() < 2 or str(l[0]) == "" or str(l[1]) == "":
			problems.append("garage line without Polish and English: %s" % [l])
			continue
		if str(l[0]).length() > 70:
			problems.append("garage line over 70 characters: %s" % l[0])
		var only: Variant = (l[2] as Dictionary).get("only", "") if l.size() > 2 and l[2] is Dictionary else ""
		seen[str(only)] = true
	for t in TAGS:
		if not seen.has(t):
			problems.append("no garage line for '%s'" % t)


func _check_eggs() -> void:
	var w := _wallet(0)
	var book: EggBook = EggBook.new()
	book.wallet = w
	root.add_child(book)
	if not book.load_eggs():
		problems.append("eggs: no eggs.json")
		return
	for id in ["e01", "e21"]:
		if not id in book.reachable():
			problems.append("%s still waits" % id)
	# E01: the black car at Lusterko's door (crowds.gd), its night and hours (egg_book.gd).
	_expect("door egg, black at Lusterko", Crowds.door_egg("lusterko", "black"), "e01")
	_expect("door egg, red at Lusterko", Crowds.door_egg("lusterko", "red"), "")
	_expect("door egg, black at Smoła", Crowds.door_egg("smola", "black"), "")
	var night := {"pos": Vector3.ZERO, "kmh": 3.0, "look": "Night", "hour": 1.5, "weekday": 6, "paint": "black"}
	var tue := night.duplicate()
	tue["weekday"] = 3
	var early := night.duplicate()
	early["hour"] = 21.0
	early["weekday"] = 5
	var sun_night := night.duplicate()
	sun_night["weekday"] = 7  # Sunday 01:30 is Saturday's night
	var red := night.duplicate()
	red["paint"] = "red"
	_expect("E01 red", book.fire("e01", red), false)
	_expect("E01 Tuesday night", book.fire("e01", tue), false)
	_expect("E01 Friday 21:00", book.fire("e01", early), false)
	var r0 := int(w.respect)
	_expect("E01 Saturday's night, 01:30 Sunday", book.fire("e01", sun_night), true)
	_expect("E01 again", book.fire("e01", night), false)
	_expect("E01 respect", int(w.respect) - r0, 50)
	# E21: stop 2 s within 25 m of Glon, green.
	var e21: Dictionary = book.eggs[book.by_id["e21"]].duplicate(true)
	e21["at"] = Vector2(100.0, 200.0)
	var green := {"pos": Vector3(110.0, 0.0, 200.0), "kmh": 0.0, "flying": false, "paint": "green"}
	var not_green := green.duplicate()
	not_green["paint"] = "red"
	var mem := {}
	var fired := false
	for i in 8:
		if EggBook.step(e21, not_green, mem, 0.5):
			fired = true
	_expect("E21 red", fired, false)
	mem = {}
	var n := -1
	for i in 8:
		if EggBook.step(e21, green, mem, 0.5):
			n = i
			break
	_expect("E21 green, steps of 0.5 s to fire", n, 3)
	var r1 := int(w.respect)
	_expect("E21 recorded", book.record("e21"), true)
	_expect("E21 again", book.record("e21"), false)
	_expect("E21 respect", int(w.respect) - r1, 15)
	book.free()
	w.free()


# --- G13: the upgrade shop (upgrades.gd) ---------------------------------------------------------

func _check_shop_rules() -> void:
	var tt := Upgrades.car("tt")
	var hatch := Upgrades.car("hatch")
	if tt.is_empty() or hatch.is_empty():
		problems.append("shop: the hatch or the TT is missing")
		return
	_expect("TT price", int(tt["price"]), 1500)
	_expect("nitro price", int(Upgrades.NITRO["price"]), 350)
	_expect("hatch is free", int(hatch["price"]), 0)
	for k in ["top", "pull", "grip"]:
		if float(tt[k]) <= float(hatch[k]):
			problems.append("shop: the TT's %s is not above the hatch's" % k)
	for p: Dictionary in Upgrades.PARTS:
		var prices: Array = p["prices"]
		if prices.size() != Upgrades.MAX_LEVEL:
			problems.append("shop: %s has %d levels" % [p["id"], prices.size()])
		for i in prices.size():
			if int(prices[i]) < 100 or int(prices[i]) > 400:
				problems.append("shop: %s level %d costs %d zł (want 100-400)" % [p["id"], i + 1, int(prices[i])])
			if i > 0 and int(prices[i]) <= int(prices[i - 1]):
				problems.append("shop: %s level %d is not dearer than the last" % [p["id"], i + 1])
	for id: String in Upgrades.ORDER:
		var row := Upgrades.find(id)
		var said: bool = Upgrades.kind(id) == "look" or (row.get("blurb", []) as Array).size() == 2
		if row.is_empty() or (row["name"] as Array).size() != 2 or not said:
			problems.append("shop: %s without names or blurbs in both languages" % id)
		# The card's tile shows the short name whole (F 2026-11-24: everything reads).
		for n: String in (row.get("short", row["name"]) as Array):
			if n.length() > 15:
				problems.append("shop: %s's tile name \"%s\" is over 15 characters" % [id, n])
		if GarageCard.tab_of(id) == "paint":
			problems.append("shop: %s is on no tab of the card" % id)
		if str(row["name"][0]).length() > 32:
			problems.append("shop: %s's Polish name is over 32 characters" % id)
	var st := {"car": "hatch", "cars": {}, "nitro": false, "tune": {}}
	_expect("rule tt 1500", Upgrades.rule("tt", 1500, st), "buy")
	_expect("rule tt 1499", Upgrades.rule("tt", 1499, st), "short")
	_expect("rule hatch on", Upgrades.rule("hatch", 0, st), "on")
	_expect("rule nitro 350", Upgrades.rule("nitro", 350, st), "buy")
	_expect("rule nitro 349", Upgrades.rule("nitro", 349, st), "short")
	_expect("rule tyres 100", Upgrades.rule("tyres", 100, st), "buy")
	_expect("rule engine 119", Upgrades.rule("engine", 119, st), "short")
	_expect("rule nothing", Upgrades.rule("turbo", 9999, st), "")
	st = {"car": "tt", "cars": {"tt": 1}, "nitro": true, "tune": {"tyres": 3, "engine": 1}}
	_expect("rule tt on", Upgrades.rule("tt", 0, st), "on")
	_expect("rule hatch back", Upgrades.rule("hatch", 0, st), "switch")
	_expect("rule nitro owned", Upgrades.rule("nitro", 0, st), "owned")
	_expect("rule tyres max", Upgrades.rule("tyres", 9999, st), "max")
	_expect("rule engine level 2", Upgrades.rule("engine", 220, st), "buy")
	_expect("engine 2 price", Upgrades.price("engine", st["tune"]), 220)
	_expect("tyres maxed price", Upgrades.price("tyres", st["tune"]), 0)
	# The numbers: the hatch as it was, the TT and the parts above it.
	var base := Upgrades.stats("hatch", {}, false)
	_expect("hatch top speed km/h", int(base["top_kmh"]), 108)
	_expect("hatch pull", float(base["pull"]), 1.0)
	_expect("hatch grip", float(base["grip"]), 1.0)
	var fast := Upgrades.stats("tt", {"tyres": 3, "engine": 3}, true)
	if int(fast["top_kmh"]) <= int(Upgrades.stats("tt", {}, false)["top_kmh"]) or int(Upgrades.stats("tt", {}, false)["top_kmh"]) <= 108:
		problems.append("shop: the TT and the engine do not add speed")
	if float(fast["grip"]) <= float(Upgrades.stats("tt", {}, false)["grip"]):
		problems.append("shop: the tyres do not add grip")
	_expect("after the TT", int(Upgrades.stats_after("tt", {"car": "hatch", "tune": {}, "nitro": false})["top_kmh"]), int(Upgrades.stats("tt", {})["top_kmh"]))
	_expect("after the nitro", bool(Upgrades.stats_after("nitro", {"car": "hatch", "tune": {}, "nitro": false})["nitro"]), true)
	_check_meme_cars()


## C1a/C1b (F 2026-11-27): the meme cars and the Bawarka: their classes (the TT and the Bawarka
## A, so the Trzy mosty final stays the hardest race; the Bawarka never S), a body each, the
## Bawarka locked until the night meet's drag, and the drag's prize.
func _check_meme_cars() -> void:
	const Ladder := preload("res://scripts/ladder.gd")
	const Models := preload("res://scripts/models.gd")
	var want := {"hatch": 0, "lanos": 0, "bolonez": 0, "paszat": 1, "mjata": 1, "szupra": 2, "tt": 3, "bawarka": 3}
	for id: String in want:
		var c := Upgrades.car(id)
		if c.is_empty():
			problems.append("cars: %s is missing" % id)
			continue
		_expect("class of %s" % id, Ladder.car_class(float(c["top"]), float(c["pull"])), int(want[id]))
		if not Models.PLAYER_BODIES.has(id):
			problems.append("cars: %s has no body" % id)
		if not (id in (Upgrades.TABS["cars"] as Array)):
			problems.append("cars: %s is not on AUTA" % id)
	var maxed := Upgrades.stats("bawarka", {"engine": Upgrades.MAX_LEVEL})
	if Ladder.car_class(float(maxed["top_mult"]), float(maxed["pull"])) > 4:
		problems.append("cars: the Bawarka with engine 3 is above S")
	if float(Upgrades.car("bawarka")["price"]) <= float(Upgrades.car("tt")["price"]):
		problems.append("cars: the Bawarka is not dearer than the TT")
	for c: Dictionary in Upgrades.CARS:
		var f: Dictionary = c.get("feel", {})
		for k: String in f:
			if not Car.FEEL_PLAIN.has(k) or float(f[k]) < 0.5 or float(f[k]) > 1.7:
				problems.append("cars: %s's feel %s = %s (a known key, 0.5-1.7)" % [c["id"], k, f[k]])
	var st := {"car": "hatch", "cars": {}, "nitro": false, "tune": {}, "open": []}
	_expect("bawarka locked", Upgrades.rule("bawarka", 99999, st), "locked")
	_expect("lanos to buy", Upgrades.rule("lanos", 200, st), "buy")
	st["open"] = ["bawarka"]
	_expect("bawarka open", Upgrades.rule("bawarka", 2500, st), "buy")
	_expect("bawarka open, short", Upgrades.rule("bawarka", 2499, st), "short")
	var cars := {}
	var keep := {}
	_expect("drag lost: opened", Upgrades.meet_prize(cars, keep, false, 20261127), "opened")
	_expect("drag lost again", Upgrades.meet_prize(cars, keep, false, 20261127), "")
	_expect("drag won: given", Upgrades.meet_prize(cars, keep, true, 20261127), "given")
	_expect("the Bawarka owned", cars.has("bawarka"), true)
	_expect("drag won again", Upgrades.meet_prize(cars, keep, true, 20261128), "")
	_expect("bawarka owned rule", Upgrades.rule("bawarka", 0, {"car": "hatch", "cars": cars, "tune": {}}), "switch")


## Buying walks: exact prices, levels stop at 3, the nitro once, a car once then free to switch.
func _check_shop_buying() -> void:
	var w := _wallet(0)
	var g := _garage(w)
	_expect("tyres with 0 zł", g.choose_item("tyres"), "short")
	w.zl = 100 + 180 + 280 + 120 + 220 + 320 + 350 + 1500 + 10
	var total := int(w.zl)
	for lv in 3:
		_expect("tyres level %d" % (lv + 1), g.choose_item("tyres"), "buy")
	_expect("tyres level after", Upgrades.level(w.tune, "tyres"), 3)
	_expect("tyres past 3", g.choose_item("tyres"), "max")
	for lv in 3:
		_expect("engine level %d" % (lv + 1), g.choose_item("engine"), "buy")
	_expect("engine past 3", g.choose_item("engine"), "max")
	_expect("nitro", g.choose_item("nitro"), "buy")
	_expect("nitro owned", bool(w.nitro), true)
	_expect("nitro again", g.choose_item("nitro"), "owned")
	_expect("the TT", g.choose_item("tt"), "buy")
	_expect("the TT on the road", str(w.car), "tt")
	_expect("zł left", int(w.zl), 10)
	_expect("the TT again", g.choose_item("tt"), "on")
	_expect("back to the hatch (free)", g.choose_item("hatch"), "switch")
	_expect("on the hatch", str(w.car), "hatch")
	_expect("the TT, owned, free", g.choose_item("tt"), "switch")
	_expect("zł after switching", int(w.zl), 10)
	_expect("paid in all", total - int(w.zl), 100 + 180 + 280 + 120 + 220 + 320 + 350 + 1500)
	g.free()
	w.free()


func _check_shop_save() -> void:
	var w := _wallet(5000)
	w.persistent = true
	w.path = SCRATCH
	var g := _garage(w)
	g.choose_item("tt")
	g.choose_item("nitro")
	g.choose_item("tyres")
	g.choose_item("tyres")
	g.choose_item("engine")
	w.save()
	var back := _wallet(0)
	back.persistent = true
	back.path = SCRATCH
	back.load_save()
	_expect("saved car", str(back.car), "tt")
	_expect("saved cars", back.cars.has("tt"), true)
	_expect("saved nitro", bool(back.nitro), true)
	_expect("saved tyres", Upgrades.level(back.tune, "tyres"), 2)
	_expect("saved engine", Upgrades.level(back.tune, "engine"), 1)
	_expect("saved zł", int(back.zl), 5000 - 1500 - 350 - 100 - 180 - 120)
	_expect("has progress", back.has_progress(), true)
	# A save from before G13 (a [garage] section with paints only): the hatch, untuned, no nitro.
	var old := ConfigFile.new()
	old.set_value("wallet", "zl", 40)
	old.set_value("garage", "paint", "blue")
	old.set_value("garage", "own_blue", 20261030)
	old.save(SCRATCH)
	var w2 := _wallet(0)
	w2.persistent = true
	w2.path = SCRATCH
	w2.load_save()
	_expect("old save's car", str(w2.car), "hatch")
	_expect("old save's nitro", bool(w2.nitro), false)
	_expect("old save's tune", w2.tune.size(), 0)
	_expect("old save's paint", str(w2.paint), "blue")
	# An edited file naming a car that was never bought, and a level of 9: the hatch, level 3.
	var edited := ConfigFile.new()
	edited.set_value("garage", "car", "tt")
	edited.set_value("garage", "tune_tyres", 9)
	edited.save(SCRATCH)
	var w3 := _wallet(0)
	w3.persistent = true
	w3.path = SCRATCH
	w3.load_save()
	_expect("an unowned car in the file", str(w3.car), "hatch")
	_expect("a level of 9 in the file", Upgrades.level(w3.tune, "tyres"), 3)
	w3.reset()
	_expect("reset car", str(w3.car), "hatch")
	_expect("reset nitro", bool(w3.nitro), false)
	g.free()
	for n in [w, back, w2, w3]:
		n.free()


## The car: the model swap (the same nodes), the tuning's multipliers, the nitro tank, and a real
## 12 s run of the car script on the gas for each model, with and without the nitro.
func _check_shop_car() -> void:
	var car: CharacterBody3D = Car.new()
	root.add_child(car)
	await process_frame
	var nodes := car.find_children("*", "", true, false).size()
	var mesh_before: Mesh = (car.get("_body_mesh") as MeshInstance3D).mesh
	var w := _wallet(100000)
	var g := _garage(w)
	g.car = car
	g.choose_item("tt")
	_expect("car model", str(car.get("model")), "tt")
	if (car.get("_body_mesh") as MeshInstance3D).mesh == mesh_before:
		problems.append("car: the TT left the hatch's mesh on")
	# The TT alone carries one more node, its active spoiler (car.gd _fit_spoiler).
	_expect("car nodes after the swap", car.find_children("*", "", true, false).size(), nodes + 1)
	if car.find_child("Spoiler", true, false) == null:
		problems.append("car: the TT has no active spoiler")
	var st := Upgrades.stats("tt", {}, false)
	_expect("car top_mult", is_equal_approx(float(car.get("top_mult")), float(st["top_mult"])), true)
	g.choose_item("tyres")
	var grip_cruise := float(car.get("grip"))
	var base_grip: float = float(Car.PROFILES[Car.Handling.CRUISE]["grip"])
	if grip_cruise <= base_grip * 1.1:
		problems.append("car: grip %.1f with the TT and tyres 1 (profile %.1f)" % [grip_cruise, base_grip])
	car.set_handling(Car.Handling.SPORT)
	if float(car.get("grip")) <= float(Car.PROFILES[Car.Handling.SPORT]["grip"]):
		problems.append("car: the tuning's grip is lost on switching to Sport")
	car.set_handling(Car.Handling.CRUISE)
	g.choose_item("hatch")
	_expect("car back on the hatch", str(car.get("model")), "hatch")
	await process_frame
	if car.find_child("Spoiler", true, false) != null:
		problems.append("car: the hatch kept the TT's spoiler")
	# C1a: each car's own feel: the Szupra turns quicker than the hatch, the Bolonez slower, and the
	# hatch is back to the plain numbers after them.
	var plain_turn := float(car.get("turn_cap"))
	g.choose_item("szupra")
	_expect("car model szupra", str(car.get("model")), "szupra")
	if float(car.get("turn_cap")) <= plain_turn or float(car.get("engine_note")) <= 1.0:
		problems.append("car: the Szupra turns %.2f (hatch %.2f), note %.2f" % [float(car.get("turn_cap")), plain_turn, float(car.get("engine_note"))])
	g.choose_item("bolonez")
	if float(car.get("turn_cap")) >= plain_turn or float(car.get("steer_time")) <= float(Car.PROFILES[Car.Handling.CRUISE]["steer_time"]):
		problems.append("car: the Bolonez is not heavier to steer than the hatch")
	g.choose_item("hatch")
	_expect("hatch's turn back", is_equal_approx(float(car.get("turn_cap")), plain_turn), true)
	_expect("hatch's note back", float(car.get("engine_note")), 1.0)
	# N1 nitro: not owned = never on; owned: a press (the tap) fires one bottle for NITRO_BURN s,
	# holding adds nothing, the next press fires the next bottle, an empty kit stays off, a bottle
	# refills in NITRO_REFILL s, BRAKE ends a burn and keeps the rest, a press on the drag's line
	# (`nitro_wait`) waits for the green, a press while parked is kept only NITRO_KEEP s.
	var press := func() -> void:
		car.set("nitro_hold", false)
		car.call("_nitro_tick", 0.0)
		car.set("nitro_hold", true)
	press.call()
	car.call("_nitro_tick", 0.1)
	_expect("nitro without owning", bool(car.get("nitro_on")), false)
	g.choose_item("nitro")
	_expect("car owns the nitro", bool(car.get("nitro_owned")), true)
	_expect("the kit holds two bottles", int(car.get("nitro_bottles")), 2)
	var lit := [0]
	car.connect("nitro_started", func() -> void: lit[0] += 1)
	car.set("nitro_charge", 1.0)
	press.call()
	car.call("_nitro_tick", 0.1)
	_expect("nitro on after a tap", bool(car.get("nitro_on")), true)
	car.call("_nitro_tick", 0.1)
	_expect("nitro_started fires once per burn (G13b)", lit[0], 1)
	if absf(float(car.call("top_speed")) - float(car.get("max_speed")) * Car.NITRO_TOP) > 0.01:
		problems.append("car: top speed %.1f with the nitro on" % float(car.call("top_speed")))
	var t := 0.2
	while bool(car.get("nitro_on")) and t < 10.0:
		car.call("_nitro_tick", 0.05)  # the button stays held: it adds nothing
		t += 0.05
	if absf(t - Car.NITRO_BURN) > 0.15:
		problems.append("car: a bottle burned %.2f s, button held (want %.1f)" % [t, Car.NITRO_BURN])
	_expect("one bottle left after a burn", int(car.call("nitro_ready")), 1)
	press.call()
	car.call("_nitro_tick", 0.05)
	_expect("the second tap fires the second bottle", bool(car.get("nitro_on")), true)
	for i in int(Car.NITRO_BURN / 0.05) + 4:
		car.call("_nitro_tick", 0.05)
	_expect("both bottles burned", int(car.call("nitro_ready")), 0)
	press.call()
	car.call("_nitro_tick", 0.05)
	_expect("an empty kit stays off", bool(car.get("nitro_on")), false)
	car.set("nitro_hold", false)
	for i in int(Car.NITRO_REFILL / 0.05) + 4:
		car.call("_nitro_tick", 0.05)
	_expect("a bottle refills in NITRO_REFILL s", int(car.call("nitro_ready")), 1)
	for i in int(Car.NITRO_REFILL / 0.05) + 4:
		car.call("_nitro_tick", 0.05)
	if float(car.get("nitro_charge")) < 0.999:
		problems.append("car: the kit is at %.2f after %.0f s" % [float(car.get("nitro_charge")), 2.0 * Car.NITRO_REFILL])
	_expect("lit once a bottle", lit[0], 2)
	# BRAKE ends the burn; what is left of the bottle stays.
	press.call()
	car.call("_nitro_tick", 0.5)
	car.set("braking", true)
	car.call("_nitro_tick", 0.05)
	car.set("braking", false)
	_expect("BRAKE ends the burn", bool(car.get("nitro_on")), false)
	var left := float(car.get("nitro_charge"))
	if left < 0.75:
		problems.append("car: a burn braked after 0.5 s left the kit at %.2f (want the rest kept)" % left)
	car.set("nitro_charge", 1.0)
	# The drag's line: a tap waits for the green, however long, then fires.
	car.set("nitro_wait", true)
	press.call()
	for i in 100:
		car.call("_nitro_tick", 0.05)
	_expect("a tap on the line waits", bool(car.get("nitro_on")), false)
	car.set("nitro_wait", false)
	car.call("_nitro_tick", 0.05)
	_expect("the kept tap fires with the green", bool(car.get("nitro_on")), true)
	for i in int(Car.NITRO_BURN / 0.05) + 4:
		car.call("_nitro_tick", 0.05)
	car.set("nitro_charge", 1.0)
	# Parked: a tap is kept only NITRO_KEEP s.
	car.set("parked", true)
	press.call()
	for i in int(Car.NITRO_KEEP / 0.05) + 6:
		car.call("_nitro_tick", 0.05)
	car.set("parked", false)
	car.call("_nitro_tick", 0.05)
	_expect("an old tap from a stop does not fire later", bool(car.get("nitro_on")), false)
	car.set("nitro_hold", false)
	car.call("_nitro_tick", 0.0)
	# A run on the gas, 12 s: the TT is quicker than the hatch, the nitro quicker still.
	var tops := {}
	for run in [["hatch", false], ["tt", false], ["hatch", true], ["tt", true]]:
		g.choose_item(str(run[0]))
		car.global_position = Vector3.ZERO
		car.rotation = Vector3.ZERO
		car.vel = Vector3.ZERO
		car.set("nitro_charge", 1.0)
		car.set("throttle", 1.0)
		car.set("target_dir", Vector3.ZERO)
		car.set("nitro_hold", bool(run[1]))
		var peak := 0.0
		for i in 720:
			car.call("_nitro_tick", 0.0)
			car.call("_step", 1.0 / 60.0)
			peak = maxf(peak, car.vel.length())
			if bool(run[1]) and i == 120:
				car.set("nitro_hold", false)
		tops["%s%s" % [run[0], "+nitro" if run[1] else ""]] = peak
	if not (tops["tt"] > tops["hatch"] + 1.0 and tops["hatch+nitro"] > tops["hatch"] + 1.0 and tops["tt+nitro"] > tops["tt"] + 1.0):
		problems.append("car: top speeds %s (want TT > hatch, nitro > none)" % [tops])
	g.free()
	w.free()
	car.free()


## F 2026-11-24 (upgrades.gd LOOKS): the GT wing and the underglow are bought once, kept, change
## no numbers, show on the car (the wing in the body's mesh, the underglow a pad), and MOJE AUTO
## lists them once owned.
func _check_looks() -> void:
	var st := {"car": "hatch", "cars": {}, "nitro": false, "tune": {}}
	_expect("rule wing 250", Upgrades.rule("wing", 250, st), "buy")
	_expect("rule neon 299", Upgrades.rule("neon", 299, st), "short")
	_expect("look kind", Upgrades.kind("neon"), "look")
	_expect("mine: a look owned", GarageCard.mine_shows("look", "owned"), true)
	_expect("mine: a look not bought", GarageCard.mine_shows("look", "buy"), false)
	var car: CharacterBody3D = Car.new()
	root.add_child(car)
	await process_frame
	var mesh_before: Mesh = (car.get("_body_mesh") as MeshInstance3D).mesh
	var w := _wallet(600)
	var g := _garage(w)
	g.car = car
	var stats_before := Upgrades.stats("hatch", w.tune, false)
	_expect("buy the wing", g.choose_item("wing"), "buy")
	_expect("the wing again", g.choose_item("wing"), "owned")
	_expect("buy the underglow", g.choose_item("neon"), "buy")
	_expect("zł after the looks", int(w.zl), 600 - 250 - 300)
	_expect("looks change no numbers", Upgrades.stats("hatch", w.tune, false), stats_before)
	_expect("car wing", bool(car.get("wing")), true)
	if (car.get("_body_mesh") as MeshInstance3D).mesh == mesh_before:
		problems.append("looks: the wing left the plain body on")
	var pad := car.find_child("Underglow", true, false) as MeshInstance3D
	if pad == null or not pad.visible:
		problems.append("looks: no underglow under the car after buying it")
	car.set_model("tt")
	_expect("the wing kept on the TT", bool(car.get("wing")), true)
	car.set_model("bike")
	if pad != null and pad.visible:
		problems.append("looks: the underglow stays on under the ROWERILO bike")
	car.set_model("hatch")
	if pad != null and not pad.visible:
		problems.append("looks: the underglow did not come back off the bike")
	g.free()
	w.free()
	car.queue_free()
	await process_frame
