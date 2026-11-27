extends SceneTree
## The two quest lines (quest_lines.gd, G12): car quests hide while flying, heli-only quests always
## show; a flying player's calls turn into roof calls and a driver's roof calls into park calls
## (the street and river kinds stay); `prefer` never returns an empty list; a heli-only rescue
## takes the HELI colour and a rescue the car reaches the amber pickup; the ride start button's
## reach is wider than the stop ring (G10). G12 part 2, the ZADANIA lists: each tab lists only its
## line, requests first, then places nearest first, one per group (three cassettes), at most
## MAX_ROWS; the distance text and compass point; the pin is reached within PIN_REACH. G12c: the
## quest under way leads its tab. G12b: the pad's D-pad pick (`pad_move`) wraps round. First hour
## step 4, the one map list (`sections`): the sections in order, only Now while something runs,
## First steps cut to STEPS_SHOWN (places nearest first, then requests, then words), Around town
## one per kind with the requests first and no rivals, Friends only once opened, the final in
## Rivals. Prints `check_quest_lines: OK`, exits 1 on a problem.
##   godot --headless --path game --script res://tools/check_quest_lines.gd

const Lines := preload("res://scripts/quest_lines.gd")
const Missions := preload("res://scripts/missions.gd")
const Rides := preload("res://scripts/rides.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

var _problems := 0


func _expect(what: String, ok: bool) -> void:
	if not ok:
		_problems += 1
		print("check_quest_lines: %s" % what)


func _initialize() -> void:
	_expect("car quests show while driving", Lines.shows(Lines.Line.CAR, false))
	_expect("car quests hide while flying", not Lines.shows(Lines.Line.CAR, true))
	_expect("heli quests show while flying", Lines.shows(Lines.Line.HELI, true))
	_expect("a taken heli quest still shows to a driver", Lines.shows(Lines.Line.HELI, false))
	_expect("heli-only mission is HELI", Lines.of_mission({"heli": true}) == Lines.Line.HELI)
	_expect("a car-reachable mission is CAR", Lines.of_mission({"heli": false}) == Lines.Line.CAR)
	for k in 4:
		var fly := Lines.kind_for(k, true)
		var drive := Lines.kind_for(k, false)
		_expect("flying never gets street or park (kind %d -> %d)" % [k, fly], fly == 1 or fly == 2)
		_expect("driving never gets a roof (kind %d -> %d)" % [k, drive], drive != 1)
	var a := {"heli": true}
	var b := {"heli": false}
	_expect("flying prefers heli places", Lines.prefer([a, b], true) == [a])
	_expect("driving prefers car places", Lines.prefer([a, b], false) == [b])
	_expect("an empty preferred half falls back to the list", Lines.prefer([a], false) == [a])
	_expect("heli colour differs from the pickup and the ride", Lines.HELI_COLOUR != Missions.PICKUP_COLOUR \
			and Lines.HELI_COLOUR != Rides.COLOUR)
	_expect("START RIDE reaches beyond the stop ring", Rides.START_REACH > StopAssist.RING)
	_lists()
	_sections()
	if _problems == 0:
		print("check_quest_lines: OK")
		quit(0)
	else:
		quit(1)


## G12 part 2: the lists' rules (quest_lines.gd `rows`, `far_text`, `pin_reached`).
func _lists() -> void:
	var c := Color.WHITE
	var e: Array = [
		Lines.entry("k1", "kebab", Lines.Line.CAR, "Kebab A", "Kebab A", Vector2(0, -900), c),
		Lines.entry("k2", "kebab", Lines.Line.CAR, "Kebab B", "Kebab B", Vector2(0, -300), c),
		Lines.entry("s1", "sloik", Lines.Line.CAR, "Słoiki", "Jars", Vector2(1500, 0), c),
		Lines.entry("ride", "ride", Lines.Line.CAR, "Łuber", "Ride", Vector2.INF, c, "ride"),
		Lines.entry("g", "garage", Lines.Line.CAR, "Warsztat", "Garage", Vector2(-50, 0), c),
		Lines.entry("call", "call", Lines.Line.HELI, "Wezwanie", "Call", Vector2.INF, c, "call"),
	]
	for i in 5:
		e.append(Lines.entry("c%d" % i, "cassette", Lines.Line.HELI, "Kaseta", "Cassette", Vector2(100.0 * (i + 1), 0), c))
	var car := Lines.rows(e, Lines.Line.CAR, Vector2.ZERO)
	var ids := car.map(func(r: Dictionary) -> String: return str(r["id"]))
	_expect("car tab: requests first, then nearest, one kebab (%s)" % [ids], ids == ["ride", "g", "k2", "s1"])
	var heli := Lines.rows(e, Lines.Line.HELI, Vector2.ZERO)
	var hids := heli.map(func(r: Dictionary) -> String: return str(r["id"]))
	_expect("heli tab: the call, then three nearest cassettes (%s)" % [hids], hids == ["call", "c0", "c1", "c2"])
	_expect("no car quest on the heli tab", heli.all(func(r: Dictionary) -> bool: return int(r["line"]) == Lines.Line.HELI))
	_expect("at most MAX_ROWS rows", Lines.rows(e, Lines.Line.CAR, Vector2.ZERO, 2).size() == 2 and Lines.MAX_ROWS <= 4)
	_expect("a request has no distance", car[0]["far"] == ["", ""])
	_expect("300 m north reads '300 m płn.' / '300 m N' (%s)" % [car[2]["far"]], car[2]["far"] == ["300 m płn.", "300 m N"])
	_expect("1.5 km east reads '1,5 km wsch.' / '1.5 km E' (%s)" % [car[3]["far"]], car[3]["far"] == ["1,5 km wsch.", "1.5 km E"])
	_expect("south-west is 5", Lines.compass(Vector2.ZERO, Vector2(-10, 10)) == 5)
	_expect("the pin is reached within PIN_REACH", Lines.pin_reached(e[4], Vector2(-50 + Lines.PIN_REACH - 1.0, 0)))
	_expect("the pin is not reached farther", not Lines.pin_reached(e[4], Vector2(-50 + Lines.PIN_REACH + 5.0, 0)))
	_expect("a request is never 'reached'", not Lines.pin_reached(e[3], Vector2.ZERO))
	_expect("no pin is never reached", not Lines.pin_reached({}, Vector2.ZERO))
	# G12c: the quest under way leads its tab, with its distance; a moving group is named.
	var now := Lines.entry("now", "now", Lines.Line.CAR, "Teraz · zlecenie", "Now · job", Vector2(0, -500), c, Lines.NOW)
	var with_now := Lines.rows(e + [now], Lines.Line.CAR, Vector2.ZERO)
	_expect("the quest under way leads the tab (%s)" % [with_now.map(func(r: Dictionary) -> String: return str(r["id"]))],
			str(with_now[0]["id"]) == "now" and with_now[0]["far"] == ["500 m płn.", "500 m N"])
	_expect("a rival's pin moves with them", "rival" in Lines.MOVING)
	# G12b: the pad's pick: the first step down picks the first row, up the last; it wraps round.
	_expect("pad: down from none is row 0", Lines.pad_move(-1, 4, 1) == 0)
	_expect("pad: up from none is the last row", Lines.pad_move(-1, 4, -1) == 3)
	_expect("pad: down from the last wraps to 0", Lines.pad_move(3, 4, 1) == 0)
	_expect("pad: up from 0 wraps to the last", Lines.pad_move(0, 4, -1) == 3)
	_expect("pad: an empty tab picks nothing", Lines.pad_move(0, 0, 1) == -1)
	_expect("pad: a pick past a shrunk tab restarts", Lines.pad_move(5, 2, 1) == 0)


## First hour step 4: the one map list's sections (quest_lines.gd `sections`).
func _sections() -> void:
	var c := Color.WHITE
	var ride := Lines.entry("ride", "ride", Lines.Line.CAR, "Łuber", "Ride", Vector2.INF, c, "ride")
	var garage := Lines.entry("garage", "garage", Lines.Line.CAR, "Mirek", "Mirek", Vector2(0, -200), c)
	var k1 := Lines.entry("k1", "kebab", Lines.Line.CAR, "Kebab A", "Kebab A", Vector2(0, -900), c)
	var e: Array = [
		ride, garage, k1,
		Lines.entry("k2", "kebab", Lines.Line.CAR, "Kebab B", "Kebab B", Vector2(0, -1300), c),
		Lines.entry("call", "call", Lines.Line.HELI, "Wezwanie", "Call", Vector2.INF, c, "call"),
		Lines.entry("c1", "cassette", Lines.Line.HELI, "Kaseta", "Tape", Vector2(50, 0), c),
		Lines.entry("rival", "rival", Lines.Line.CAR, "Rywal", "Rival", Vector2(10, 10), c),
		Lines.entry("final", "final", Lines.Line.CAR, "Trzy mosty", "Three bridges", Vector2(800, 0), c),
		Lines.entry("st", "story", Lines.Line.STORY, "Wątek", "Story", Vector2(100, 0), c, "story"),
	]
	var race := Lines.entry("step_race", "rival", Lines.Line.CAR, "", "", Vector2.INF, c, Lines.RIVAL_CALL)
	var steps: Array = [
		{"id": "kebab", "pl": "Kebab", "en": "Kebab", "entry": k1},
		{"id": "ride", "pl": "Podwieź", "en": "Lift", "entry": ride},
		{"id": "race", "pl": "Wyścig", "en": "Race", "entry": race},
		{"id": "heli", "pl": "Heli", "en": "Heli", "entry": {}},
		{"id": "garage", "pl": "Warsztat", "en": "Garage", "entry": garage},
	]
	var secs := Lines.sections(e, Lines.Line.CAR, Vector2.ZERO, steps, false)
	var keys: Array = secs.map(func(x: Dictionary) -> String: return str(x["key"]))
	_expect("the list's sections in order, no friends before the third step (%s)" % [keys],
			keys == ["steps", "town", "rivals", "collection"])
	var st: Array = secs[0]["rows"]
	var sid: Array = st.map(func(x: Dictionary) -> String: return str(x["step"]))
	_expect("First steps shows three: the places nearest first, then the requests (%s)" % [sid],
			sid == ["garage", "kebab", "ride"])
	_expect("a step row takes the step's own words", str(st[0]["en"]) == "Garage" and not bool(st[0]["label"]))
	var few := Lines.sections(e, Lines.Line.CAR, Vector2.ZERO, [steps[3]], false)
	_expect("a step done by a button is words, not a row", bool((few[0]["rows"] as Array)[0]["label"]))
	var town: Array = secs[1]["rows"]
	var tid: Array = town.map(func(x: Dictionary) -> String: return str(x["id"]))
	_expect("Around town: requests, the car's places one per kind, then the heli's, no rivals, none First steps shows (%s)" % [tid],
			tid == ["call", "c1"])
	var fl: Array = secs[2]["rows"]
	_expect("the final is a row of Rivals", fl.size() == 1 and str(fl[0]["id"]) == "final")
	var flying := Lines.sections(e, Lines.Line.HELI, Vector2.ZERO, [], true)
	var ftown: Array = (flying.filter(func(x: Dictionary) -> bool: return x["key"] == "town")[0] as Dictionary)["rows"]
	_expect("flying: the heli's places lead Around town", str(ftown[2]["id"]) == "c1")
	var fkeys: Array = flying.map(func(x: Dictionary) -> String: return str(x["key"]))
	_expect("no First steps left: no section; Friends once opened (%s)" % [fkeys],
			fkeys == ["town", "rivals", "friends", "collection"])
	var now := Lines.entry("now", "now", Lines.Line.HELI, "Teraz", "Now", Vector2(0, 50), c, Lines.NOW)
	var ns := Lines.sections([now], Lines.Line.CAR, Vector2.ZERO, steps, true)
	_expect("something under way: only Now, its one row", ns.size() == 1 and str(ns[0]["key"]) == "now" \
			and (ns[0]["rows"] as Array).size() == 1)
