extends SceneTree
## Loop MW-6 (docs/design/vision.md section 8): the notebook's egg cards (data/eggs.json,
## egg_book.gd), headless, no map:
##   - every card has its name and line in Polish and English (a `line_ref` resolving to a
##     dialogue.json line), each at most 70 characters, a reward (respect), a trigger kind, a
##     place that exists (places.json, or eggs.gd's five spots); a waiting egg names what it
##     waits for; unique ids; 48 cards (5 of v0.65 + vision's 40 + loop MW-2's two: the Frogs
##     triple corner and the standing Leżak, and the Mrożulo van's easter_mlask);
##   - every reachable egg fires on synthetic inputs of its kind (the vehicle at its place, its
##     time, day and weather; a lap, a street, a circle driven), and an egg with a condition does
##     not fire without it (by day, too fast, in the rain, another station);
##   - a find pays its reward once (the second find pays nothing), an egg's track goes through
##     radio.gd's `unlock_track` (and E31's, open already, opens the next locked one), its then
##     card is stamped, the tape eggs fire from `tape_played` only with their conditions;
##   - Fat Thursday by the computus (2026: 12 February, 2027: 4 February).
## Prints `check_eggs: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_eggs.gd [-- --verbose]

const EggBook := preload("res://scripts/egg_book.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Fakes := preload("res://tools/fakes.gd")
const MAX_PL := 70
const OLD_SPOTS := ["palma", "pigeons", "barriers", "patelnia", "syrenka"]
const KINDS := ["stop", "pass", "hover", "land", "circle", "lap", "street", "between", "tape", "legacy", "waits", "event"]


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var book: EggBook = EggBook.new()
	book.wallet = wallet
	root.add_child(book)
	if not book.load_eggs():
		print("check_eggs: no data/eggs.json")
		quit(1)
		return
	var nb: Notebook = Notebook.new()
	nb.load_places()
	_check_data(book, nb)
	_check_roads(book, nb)
	nb.free()
	var fired := _check_triggers(book)
	_check_rewards(book, wallet)
	if EggBook.fat_thursday(2026) != 20260212 or EggBook.fat_thursday(2027) != 20270204:
		problems.append("Fat Thursday: 2026 %d, 2027 %d (want 20260212, 20270204)" % [EggBook.fat_thursday(2026), EggBook.fat_thursday(2027)])
	var reach := book.reachable().size()
	var total := book.eggs.size()
	book.free()
	wallet.free()
	if problems.is_empty():
		print("check_eggs: OK (%d cards, %d reachable now: %d fire on their inputs and not without their conditions; %d waiting)" % [
				total, reach, fired, total - reach])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_eggs: %d problems" % problems.size())
		quit(1)


func _check_data(book: EggBook, nb: Notebook) -> void:
	if book.eggs.size() != 48:
		problems.append("%d cards, want 48 (5 of v0.65 + vision's 40 + MW-2's two + easter_mlask)" % book.eggs.size())
	var ids := {}
	for e in book.eggs:
		var id := str(e["id"])
		if ids.has(id):
			problems.append("%s: the id twice" % id)
		ids[id] = true
		var name: Array = e.get("name", [])
		var line := book.line_of(e)
		for pair: Array in [name, line]:
			if pair.size() != 2 or str(pair[0]).strip_edges() == "" or str(pair[1]).strip_edges() == "":
				problems.append("%s: a name or line without Polish and English (%s)" % [id, pair])
				continue
			for k in 2:
				if str(pair[k]).length() > MAX_PL:
					problems.append("%s: '%s' is %d characters (at most %d)" % [id, pair[k], str(pair[k]).length(), MAX_PL])
		var t: Dictionary = e.get("trigger", {})
		if not str(t.get("kind", "")) in KINDS:
			problems.append("%s: trigger kind '%s'" % [id, t.get("kind", "")])
		if int(e.get("reward", {}).get("respect", 0)) <= 0:
			problems.append("%s: no reward" % id)
		var pid := str(e.get("place", ""))
		if not nb.by_id.has(pid) and not pid in OLD_SPOTS:
			problems.append("%s: place '%s' is neither in places.json nor one of eggs.gd's spots" % [id, pid])
		if e.has("waits") and not book.waits.has(str(e["waits"])):
			problems.append("%s: waits for '%s', which the file doesn't name" % [id, e["waits"]])
		if str(t.get("kind", "")) == "waits" and not e.has("waits"):
			problems.append("%s: a waiting trigger without `waits`" % id)
		if verbose:
			print("  %s %s · %s: %s%s" % [id, name[0], name[1], t.get("kind", ""), " (waits: %s)" % e["waits"] if e.has("waits") else ""])


## A `street` or `road` names a road of the map (centrum.json); a `road` anchor lands on it
## within 400 m of the egg's place.
func _check_roads(book: EggBook, nb: Notebook) -> void:
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return
	var roads: Array = data.get("roads", [])
	var names := {}
	for r: Dictionary in roads:
		names[str(r.get("name", ""))] = true
	for e in book.eggs:
		var t: Dictionary = e["trigger"]
		for key: String in ["street", "road"]:
			if t.has(key) and not names.has(str(t[key])):
				problems.append("%s: no road named '%s' in the map" % [e["id"], t[key]])
		if t.has("road") and nb.by_id.has(str(e["place"])):
			var at: Vector2 = nb.places[nb.by_id[str(e["place"])]]["at"]
			var on := EggBook.nearest_on_road(roads, str(t["road"]), at)
			if on.distance_to(at) > 400.0:
				problems.append("%s: its road is %.0f m from the place" % [e["id"], on.distance_to(at)])


## The state a trigger wants: its time of day, clock, day, date and station, dry.
static func want_state(t: Dictionary) -> Dictionary:
	var s := {"pos": Vector3.ZERO, "kmh": 0.0, "flying": false, "alt": 0.0, "roof": 0.0, "look": "Day", "hour": 14.0,
			"weekday": 5, "month": 7, "live": false, "sun": 30.0, "rain": false, "station": "kebab_fm", "date": 0, "roadworks": ""}
	if bool(t.get("night", false)) or t.has("after"):
		s["look"] = "Night"
		s["hour"] = 1.5
		s["weekday"] = 6
	if str(t.get("look", "")) == "Dusk":
		s["look"] = "Dusk"
		s["hour"] = 19.5
	if t.has("hours"):
		var h: Array = t["hours"]
		s["hour"] = float(h[0]) + 0.25
	if t.has("weekday"):
		s["weekday"] = int((t["weekday"] as Array)[0])
	if t.has("date"):
		s["live"] = true
		s["date"] = EggBook.fat_thursday(2027)
		s["month"] = 2
		s["weekday"] = 4
	if t.has("station"):
		s["station"] = str(t["station"])
	if t.has("roadworks"):
		s["roadworks"] = str(t["roadworks"])
	# The garage loop: the car's paint.
	if t.has("paint"):
		s["paint"] = str(t["paint"])
	# Loop MW-3: the crowd the trigger wants is out (at its level).
	if t.has("crowd"):
		var c: Variant = t["crowd"]
		s["crowds"] = {str(c[0]) if c is Array else str(c): 1.0}
	return s


## The same state with one of the trigger's conditions broken ({} if it has none).
static func broken_state(t: Dictionary, s: Dictionary) -> Dictionary:
	var b := s.duplicate()
	# Loop MW-4: a window alone is broken an hour after it closes (a 9-17 window held 16.5).
	if t.has("hours") and not bool(t.get("night", false)) and not t.has("after"):
		b["look"] = "Day"
		b["hour"] = fmod(float((t["hours"] as Array)[1]) + 1.0, 24.0)
		return b
	if bool(t.get("night", false)) or t.has("after") or t.has("hours"):
		b["look"] = "Day"
		b["hour"] = 10.0 if not t.has("hours") or float((t["hours"] as Array)[0]) > 11.0 else 16.5
		return b
	if t.has("look"):
		b["look"] = "Day"
		return b
	if t.has("weekday"):
		b["weekday"] = 3 if not 3 in (t["weekday"] as Array) else 7
		return b
	if t.has("date"):
		b["date"] = 20270205
		return b
	if t.has("station"):
		b["station"] = "kebab_fm"
		return b
	if t.has("crowd"):
		b["crowds"] = {}
		return b
	if t.has("paint"):
		b["paint"] = "red"  # the garage loop: the factory paint
		return b
	if t.has("max_kmh"):
		b["kmh"] = float(t["max_kmh"]) + 15.0
		return b
	return {}


## Runs egg `e`'s trigger on a synthetic path for its kind from state `s`; the steps it took to
## fire (-1: it didn't within 600 steps of 0.5 s).
static func run(e: Dictionary, s0: Dictionary) -> int:
	var t: Dictionary = e["trigger"]
	var kind := str(t.get("kind", ""))
	var mem := {}
	var at: Vector2 = e["at"]
	for i in 600:
		var s := s0.duplicate()
		var p := at
		var speed := minf(float(t.get("max_kmh", 60.0)) * 0.9, 60.0) if not s0.has("kmh_force") else float(s0["kmh_force"])
		match kind:
			"stop", "pass", "hover", "land", "between":
				p = at + Vector2(float(t.get("within", 30.0)) * 0.5, 0.0) if kind != "between" else at
				if kind in ["hover", "land", "between"]:
					s["flying"] = true
					s["alt"] = float(t.get("min_alt", 0.0)) + 10.0 if kind != "land" else 0.5
					s["roof"] = float(t.get("roof", 0.0)) + 2.0
				if kind == "pass":
					s["kmh"] = speed if t.has("max_kmh") else 40.0
			"circle", "lap":
				var r: Array = t["r"]
				var mid := (float(r[0]) + float(r[1])) * 0.5
				p = at + Vector2(cos(i * 0.12), sin(i * 0.12)) * mid
				s["flying"] = kind == "circle"
				s["alt"] = 60.0 if kind == "circle" else 0.0
				s["kmh"] = speed
			"street":
				var pieces: PackedVector2Array = e["pieces"]
				p = pieces[mini(i % (pieces.size() + 4), pieces.size() - 1)]
				s["kmh"] = speed
		if s0.has("kmh_force"):
			s["kmh"] = float(s0["kmh_force"])
		s["pos"] = Vector3(p.x, 0.0, p.y)
		if EggBook.step(e, s, mem, 0.5):
			return i
	return -1


func _check_triggers(book: EggBook) -> int:
	var fired := 0
	for e0 in book.eggs:
		var e := e0.duplicate(true)
		var id := str(e["id"])
		var t: Dictionary = e["trigger"]
		var kind := str(t.get("kind", ""))
		if e.has("waits") or kind in ["legacy", "tape", "waits", "event"]:
			# Never fires by itself.
			if EggBook.step(e, want_state(t), {}, 0.5):
				problems.append("%s: a %s egg fired from step()" % [id, kind if not e.has("waits") else "waiting"])
			continue
		e["at"] = Vector2(100.0, 200.0)
		if kind == "street":
			var pieces := PackedVector2Array()
			for k in 12:
				pieces.append(Vector2(100.0 + k * 20.0, 200.0))
			e["pieces"] = pieces
		if kind == "between":
			e["a"] = Vector2(0.0, 200.0)
			e["b"] = Vector2(200.0, 200.0)
		var s := want_state(t)
		var n := run(e, s)
		if n < 0:
			problems.append("%s: its %s trigger never fired on its inputs (%s)" % [id, kind, EggBook.describe_state(s)])
			continue
		var b := broken_state(t, s)
		if not b.is_empty():
			var bad := b.duplicate()
			if bad.has("kmh") and float(bad["kmh"]) > float(t.get("max_kmh", 999.0)):
				bad["kmh_force"] = bad["kmh"]
			if run(e, bad) >= 0:
				problems.append("%s: fired without its conditions (%s)" % [id, EggBook.describe_state(bad)])
		# Away from it: nothing.
		var far := s.duplicate()
		far["pos"] = Vector3(5000.0, 0.0, 5000.0)
		var mem := {}
		for k in 40:
			if EggBook.step(e, far, mem, 0.5):
				problems.append("%s: fired 5 km away" % id)
				break
		fired += 1
		if verbose:
			print("  %s fires after %d checks (%.1f s)" % [id, n + 1, (n + 1) * 0.5])
	# The rain stops E14 (dry), a car stops the helicopter's eggs, the helicopter the car's.
	var e14: Dictionary = book.eggs[book.by_id["e14"]].duplicate(true)
	e14["at"] = Vector2.ZERO
	var wet := want_state(e14["trigger"])
	wet["rain"] = true
	if run(e14, wet) >= 0:
		problems.append("e14: fired in the rain")
	var e05: Dictionary = book.eggs[book.by_id["e05"]].duplicate(true)
	e05["at"] = Vector2.ZERO
	var low := want_state(e05["trigger"])
	var mem5 := {}
	low["flying"] = true
	low["alt"] = 20.0
	for k in 20:
		if EggBook.step(e05, low, mem5, 0.5):
			problems.append("e05: fired 20 m up (wants 60)")
			break
	return fired


func _check_rewards(book: EggBook, wallet: Wallet) -> void:
	var radio := Fakes.Radio.new()
	radio.open = {1: true, 2: true}
	var tape := Fakes.Tape.new()
	root.add_child(radio)
	root.add_child(tape)
	book.radio = radio
	book.tape = tape
	var before := wallet.respect
	var e07: Dictionary = book.eggs[book.by_id["e07"]]
	if not book.record("e07"):
		problems.append("e07: the first find didn't record")
	if wallet.respect - before != int(e07["reward"]["respect"]):
		problems.append("e07: paid %d respect, want %d" % [wallet.respect - before, e07["reward"]["respect"]])
	var mid := wallet.respect
	if book.record("e07") or wallet.respect != mid:
		problems.append("e07: the second find paid again")
	if int(wallet.eggs.get("e07", 0)) < 20000101:
		problems.append("e07: the save has no day for it (%s)" % wallet.eggs.get("e07"))
	# E14: PÓŁNOC FM track 5 through the radio.
	book.record("e14")
	if radio.unlocks.is_empty() or int(radio.unlocks[0][0]) != 5:
		problems.append("e14: didn't ask the radio for track 5 (%s)" % [radio.unlocks])
	# E31: track 2 is free already, so the lowest locked one opens (track 3).
	radio.unlocks.clear()
	book.record("e31")
	if radio.unlocks.size() != 2 or int(radio.unlocks[0][0]) != 2 or int(radio.unlocks[1][0]) != 3:
		problems.append("e31: the radio calls %s (want track 2, then 3)" % [radio.unlocks])
	# E38: the then card stamped.
	book.record("e38")
	if not "t_palac_2020" in tape.stamped:
		problems.append("e38: its then card t_palac_2020 wasn't stamped (%s)" % [tape.stamped])
	# The tape eggs: E36 at its card; E37 only with the roadworks on Świętokrzyska.
	var s := want_state({})
	book.tape_played("t_stadion_2010", s)
	if not book.is_found("e36"):
		problems.append("e36: KASETA at t_stadion_2010 didn't find it")
	book.tape_played("t_swietokrzyska_2012", s)
	if book.is_found("e37"):
		problems.append("e37: found without the roadworks on Świętokrzyska")
	s["roadworks"] = "Świętokrzyska"
	book.tape_played("t_swietokrzyska_2012", s)
	if not book.is_found("e37"):
		problems.append("e37: KASETA with the roadworks didn't find it")
	# A waiting egg is never recorded by its trigger, but the old eggs' record works (eggs.gd).
	if not book.record("palma") or not book.is_found("palma"):
		problems.append("palma: eggs.gd's find didn't record its card")
	if book.found_total() != 7:
		problems.append("found %d after the rewards' run, want 7" % book.found_total())
	radio.free()
	tape.free()
