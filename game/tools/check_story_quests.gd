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

var _problems := 0


func _expect(what: String, ok: bool) -> void:
	if not ok:
		_problems += 1
		print("check_story_quests: %s" % what)


## A stand-in HUD: the card the friend shows, and its buttons.
class FakeHud extends CanvasLayer:
	signal card_pressed(index: int)
	var card := ""
	var buttons := PackedStringArray()
	func show_side_card(title: String, _body: String, b: PackedStringArray, _accent: Color, _t_en := "", _b_en := "") -> void:
		card = title
		buttons = b
	func hide_card() -> void:
		card = ""


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
		{"id": "night", "pl": "Nocny", "en": "Night", "who": ["Ziomek", "Ziomek"], "at": Vector2(10, 0), "hours": Vector2(22, 4)},
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
	var hud := FakeHud.new()
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
	_expect("the friend walks up, in person (no phone): %s" % hud.card, s.talking() and hud.card.begins_with("👋") and hud.buttons.size() == 2)
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
	_expect("closed: says when, one OK button", s.talking() and hud.buttons.size() == 1)
	hud.card_pressed.emit(0)
	_expect("closed: OK starts nothing", met[0] == 1)
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
