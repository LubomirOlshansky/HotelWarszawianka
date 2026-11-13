extends SceneTree
## The questlines (story_quests.gd, F's ask 2026-11-07): the hours wrap past midnight and a night
## after midnight belongs to the day before; the start nearest the car within reach; the friend
## walks up only close, slow and on the ground; the map's badges go in quest focus; the WĄTKI tab
## lists every questline, open ones first, nearest first, with a start action; a def joins with
## defaults; the in-person card starts the quest (meet) on WCHODZĘ and does nothing on NIE TERAZ,
## and a closed questline only says when to come back. Prints `check_story_quests: OK`, exits 1 on
## a problem.
##   godot --headless --path game --script res://tools/check_story_quests.gd

const Story := preload("res://scripts/story_quests.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const Fakes := preload("res://tools/fakes.gd")

var _problems := 0


func _expect(what: String, ok: bool) -> void:
	if not ok:
		_problems += 1
		print("check_story_quests: %s" % what)


func _initialize() -> void:
	_expect("any time is open", Story.hours_ok(Vector2(-1, -1), 3.0))
	_expect("7-22 open at noon", Story.hours_ok(Vector2(7, 22), 12.0))
	_expect("7-22 closed at 23", not Story.hours_ok(Vector2(7, 22), 23.0))
	_expect("19-4 open at 1:00", Story.hours_ok(Vector2(19, 4), 1.0))
	_expect("19-4 closed at noon", not Story.hours_ok(Vector2(19, 4), 12.0))
	var rave := {"hours": Vector2(19, 4), "days": [4, 5, 6]}
	_expect("Saturday 1:00 is Friday's night (open)", Story.open_at(rave, 1.0, 6))
	_expect("Sunday 1:00 is Saturday's night (open)", Story.open_at(rave, 1.0, 7))
	_expect("Monday 1:00 is Sunday's night (closed)", not Story.open_at(rave, 1.0, 1))
	_expect("Wednesday 21:00 closed", not Story.open_at(rave, 21.0, 3))
	_expect("Thursday 21:00 open", Story.open_at(rave, 21.0, 4))
	_expect("when text", Story.when_text(rave, true) == "czw.-sob. 19:00-4:00" and Story.when_text({"hours": Vector2(7, 22)}, false) == "7:00-22:00")
	var list := [{"id": "a", "at": Vector2(0, 0)}, {"id": "b", "at": Vector2(100, 0)}, {"id": "c", "at": Vector2.INF}]
	_expect("nearest within reach", Story.nearest(list, Vector2(90, 0), 50.0) == 1)
	_expect("nothing within reach", Story.nearest(list, Vector2(50, 300), 50.0) == -1)
	_expect("nearest skips the greeted", Story.nearest(list, Vector2(90, 0), 200.0, {"b": true}) == 0)
	_expect("greet: close and slow", Story.greet_ready(Vector2(10, 0), Vector2.ZERO, 15.0, false))
	_expect("greet: not too fast", not Story.greet_ready(Vector2(10, 0), Vector2.ZERO, 50.0, false))
	_expect("greet: not too far", not Story.greet_ready(Vector2(Story.GREET_R + 5.0, 0), Vector2.ZERO, 5.0, false))
	_expect("greet: not flying", not Story.greet_ready(Vector2(10, 0), Vector2.ZERO, 5.0, true))
	var m: Array = Story.marks(list, false)
	_expect("two badges (one has no start)", (m[0] as PackedVector2Array).size() == 2)
	_expect("no badges in quest focus", (Story.marks(list, true)[0] as PackedVector2Array).is_empty())
	# The WĄTKI tab.
	var defs := [
		{"id": "far", "pl": "Daleki", "en": "Far", "who": ["Ala", "Ala"], "at": Vector2(900, 0)},
		{"id": "near", "pl": "Bliski", "en": "Near", "who": ["Ola", "Ola"], "at": Vector2(100, 0)},
		{"id": "night", "pl": "Nocny", "en": "Night", "who": ["Mati", "Mati"], "at": Vector2(10, 0), "hours": Vector2(22, 4)},
		{"id": "none", "pl": "Bez startu", "en": "No start", "who": ["", ""], "at": Vector2.INF},
	]
	var e := Story.entries(defs, 12.0, 3)
	_expect("one entry each", e.size() == 4 and e.all(func(x: Dictionary) -> bool: return int(x["line"]) == Lines.Line.STORY and str(x["action"]) == "story"))
	var rows := Lines.rows(e, Lines.Line.STORY, Vector2.ZERO)
	var ids := rows.map(func(r: Dictionary) -> String: return str(r["story"]))
	_expect("open first, nearest first, closed last: %s" % [ids], ids == ["near", "far", "none", "night"])
	_expect("a start's row has its distance", str(rows[0]["far"][1]) == "100 m E")
	_expect("the car tab has no questlines", Lines.rows(e, Lines.Line.CAR, Vector2.ZERO).is_empty())
	var twelve: Array = []
	for i in 14:
		twelve.append(Lines.entry("s%d" % i, "story", Lines.Line.STORY, "x", "x", Vector2(i, 0), Color.WHITE, "story"))
	_expect("the tab lists up to STORY_ROWS", Lines.rows(twelve, Lines.Line.STORY, Vector2.ZERO).size() == Lines.STORY_ROWS)
	# The friend in person.
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var s := Story.new()
	s.hud = hud
	var world := Node3D.new()
	root.add_child(world)
	world.add_child(s)
	await process_frame  # the start beacon is placed by its global position: in the tree first
	s.setup(world)
	var met := [0]
	var called := [0]
	var car := [Vector3(500, 0, 0), 0.0, false]
	var hour := [12.0]
	s.vehicle = func() -> Array: return car
	s.clock = func() -> Array: return [hour[0], 3]
	var i := s.add({"id": "boat", "pl": "Łódki", "en": "Boats", "who": ["Szymek", "Szymek"], "hello": ["Siema", "Hi"],
			"closed": ["Za dnia", "By day"], "at": Vector2.ZERO, "hours": Vector2(7, 22),
			"meet": func() -> bool:
				met[0] += 1
				return true,
			"call": func() -> bool:
				called[0] += 1
				return true})
	_expect("a def gets defaults", i == 0 and s.defs[0]["days"] == [] and s.defs[0]["colour"] == Story.COLOUR)
	s.step()
	_expect("no greeting far away", not s.talking())
	car[0] = Vector3(12, 0, 0)
	car[1] = 60.0
	s.step()
	_expect("no greeting at speed", not s.talking())
	car[1] = 10.0
	s.step()
	_expect("the friend walks up, in person (no phone): %s" % hud.card, s.talking() and hud.card.begins_with("👋") and hud.button_words.size() == 2)
	hud.card_pressed.emit(1)
	_expect("NIE TERAZ starts nothing", met[0] == 0 and not s.talking())
	s.step()
	_expect("no second greeting before driving off", not s.talking())
	car[0] = Vector3(300, 0, 0)
	s.step()
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("greets again after driving off", s.talking())
	hud.card_pressed.emit(0)
	_expect("WCHODZĘ starts it in person", met[0] == 1 and called[0] == 0)
	car[0] = Vector3(300, 0, 0)
	s.step()
	hour[0] = 23.0
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("closed: says when, one OK button (no clock to jump)", s.talking() and hud.button_words.size() == 1)
	hud.card_pressed.emit(0)
	_expect("closed: OK starts nothing", met[0] == 1)
	# F, 2026-11-08: stopped in the night meet's ring by day, nothing could start it. A closed
	# questline now offers to wait for its opening hour: the clock jumps, the quest starts.
	var jumped := [-1.0]
	s.skip_to = func(h: float) -> bool:
		jumped[0] = h
		hour[0] = h
		return true
	car[0] = Vector3(300, 0, 0)
	s.step()
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("closed: CZEKAM DO 7:00 / NIE TERAZ: %s" % [hud.button_words], s.talking() and hud.button_words.size() == 2 and hud.button_words[0].begins_with("CZEKAM DO 7:00"))
	hud.card_pressed.emit(1)
	_expect("closed: NIE TERAZ neither waits nor starts", met[0] == 1 and jumped[0] < 0.0)
	car[0] = Vector3(300, 0, 0)
	s.step()
	hour[0] = 23.0
	car[0] = Vector3(12, 0, 0)
	s.step()
	hud.card_pressed.emit(0)
	_expect("closed: CZEKAM jumps to the opening hour and starts it (%.2f)" % jumped[0], met[0] == 2 and absf(jumped[0] - 7.05) < 0.001)
	_expect("the opening hour is inside the window", Story.open_at(s.defs[0], Story.open_hour(s.defs[0]), 3))
	_expect("a night meet's hour opens it (21-4)", Story.open_at({"hours": Vector2(21, 4)}, Story.open_hour({"hours": Vector2(21, 4)}), 5))
	_expect("any-time questlines have no opening hour", Story.open_hour({"hours": Vector2(-1, -1)}) < 0.0)
	_expect("looks: 21:00 Night, 14:00 Day, 19:00 Dusk, 6:00 Dawn",
			Story.look_for(21.05) == "Night" and Story.look_for(14.05) == "Day" and Story.look_for(19.05) == "Dusk" and Story.look_for(6.05) == "Dawn")
	# The night meet's def (jump): outside its hours the friend says hello with WCHODZĘ; the tap
	# jumps the clock and starts it, no CZEKAM card.
	s.defs[0]["jump"] = true
	car[0] = Vector3(300, 0, 0)
	s.step()
	hour[0] = 23.0
	jumped[0] = -1.0
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("jump: closed, still WCHODZĘ: %s" % [hud.button_words], s.talking() and hud.button_words.size() == 2 and hud.button_words[0].begins_with("WCHODZĘ"))
	hud.card_pressed.emit(0)
	_expect("jump: WCHODZĘ jumps the clock and starts it", met[0] == 3 and absf(jumped[0] - 7.05) < 0.001)
	s.defs[0]["jump"] = false
	s.skip_to = Callable()
	# A card nobody answered (the car passed by, the card ran out): stopping in the ring after a
	# short drive out of the greeting circle brings the friend back (was: 80 m away first).
	car[0] = Vector3(300, 0, 0)
	s.step()
	hour[0] = 12.0
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("greets on the way past", s.talking())
	s._process(Story.CARD_LIFE + 0.1)
	_expect("the card runs out", not s.talking())
	car[0] = Vector3(Story.GREET_R + 5.0, 0, 0)
	s.step()
	car[0] = Vector3(2, 0, 0)
	car[1] = 0.0
	s.step()
	_expect("stopped in the ring after a lapsed card: the friend comes back", s.talking())
	hud.card_pressed.emit(1)
	_expect("the list's start phones (any hour)", s.start("boat") and called[0] == 1)
	_expect("an unknown id starts nothing", not s.start("nope"))
	s.focus = true
	car[0] = Vector3(300, 0, 0)
	s.step()
	car[0] = Vector3(12, 0, 0)
	s.step()
	_expect("no greeting while a quest runs", not s.talking())
	if _problems == 0:
		print("check_story_quests: OK")
	quit(1 if _problems > 0 else 0)
