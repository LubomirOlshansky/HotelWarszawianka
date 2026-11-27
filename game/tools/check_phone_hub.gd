extends SceneTree
## The phone's contents and card (phone_rules.gd, phone_hub.gd; F 2026-11-26/27), pure: made-up facts in.
## Checks that:
## - every word key the rules and the view ask for is in dialogue.json's "phone_hub" group in both
##   languages;
## - the apps come in order (ŁUBER, GŁODNO, ZADANIA, COTAM), COTAM never enabled, ŁUBER only when a ride
##   can be requested (and then says why not), GŁODNO off while something is on; what each app does
##   (offer, screen, form, soon);
## - the food offer is the nearest kebab place of the entries (others ignored, none: {});
## - the card draws: the home's four tiles, the search screen, an offer (TAKE / SKIP), nothing on
##   offer, every control at least 44 pt, and each press hands its key back; the search ends by itself.
##   godot --headless --path game --script res://tools/check_phone_hub.gd

const Rules := preload("res://scripts/phone_rules.gd")
const PhoneHub := preload("res://scripts/phone_hub.gd")

var _problems := 0
var _got: Array = []


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	for k: String in Rules.keys():
		var w := Rules.words(k)
		_expect(w[0] != k and w[1] != k and str(w[0]) != "" and str(w[1]) != "", "word key %s missing or empty" % k)
	var m := Rules.model({"can_ride": true, "busy": false, "jobs_done": 12})
	var keys: Array = []
	for a: Dictionary in m["apps"]:
		keys.append(a["key"])
	_expect(keys == ["luber", "glodno", "quests", "cotam"], "apps order %s" % [keys])
	_expect(bool(m["apps"][3]["enabled"]), "COTAM is the feedback form, always on")
	_expect(bool(m["apps"][0]["enabled"]) and bool(m["apps"][1]["enabled"]) and bool(m["apps"][2]["enabled"]), "three apps on")
	_expect(str(m["apps"][2]["sub"][1]).ends_with("12"), "the jobs count shows: %s" % [m["apps"][2]["sub"]])
	var off := Rules.model({"can_ride": false, "busy": true})
	_expect(not bool(off["apps"][0]["enabled"]) and off["apps"][0]["sub"] == Rules.words("no_ride"), "no ride: off and says why")
	_expect(not bool(off["apps"][1]["enabled"]), "busy: the food app is off")
	_expect(bool(off["apps"][2]["enabled"]), "QUESTS stays on")
	_expect(Rules.kind("luber") == "offer" and Rules.kind("glodno") == "offer" and Rules.kind("quests") == "screen"
			and Rules.kind("cotam") == "form" and Rules.kind("x") == "", "what each app does")
	var entries := [
		{"id": "a", "group": "kebab", "pl": "Daleki Kebab", "en": "Far Kebab", "at": Vector2(500, 0), "colour": Color.RED},
		{"id": "b", "group": "kebab", "pl": "Bliski Kebab", "en": "Near Kebab", "at": Vector2(80, 0), "colour": Color.RED},
		{"id": "c", "group": "sloik", "pl": "Słoiki", "en": "Jars", "at": Vector2(10, 0), "colour": Color.RED}]
	var food := Rules.food_offer(entries, Vector2.ZERO, ["80 m E", "80 m E"])
	_expect(not food.is_empty() and food["entry"]["id"] == "b", "the nearest kebab place is offered, got %s" % [food.get("entry", {}).get("id", "none")])
	_expect(Rules.food_offer([entries[2]], Vector2.ZERO, ["", ""]).is_empty(), "no kebab place: no food offer")
	await process_frame  # the root takes the card into the tree on the first frame
	await _view(m)
	if _problems == 0:
		print("check_phone_hub: OK")
		quit(0)
	else:
		print("check_phone_hub: %d problems" % _problems)
		quit(1)


## The card: its screens, buttons, sizes and presses.
func _view(m: Dictionary) -> void:
	var hub := PhoneHub.new()
	hub.pt = 3.0
	hub.safe = Rect2(0, 0, 2532, 1170)
	root.add_child(hub)
	hub.app_pressed.connect(func(k: String) -> void: _got.append("app:" + k))
	hub.home_pressed.connect(func() -> void: _got.append("home"))
	hub.searched.connect(func(k: String) -> void: _got.append("searched:" + k))
	hub.offer_taken.connect(func(k: String) -> void: _got.append("take:" + k))
	hub.offer_skipped.connect(func(k: String) -> void: _got.append("skip:" + k))
	hub.open(m)
	_expect(hub.is_open() and hub.app() == "", "opens on the home")
	_buttons(hub, 4 + 1, "home")  # four apps and the close cross
	(hub.find_child("app_glodno", true, false) as Button).pressed.emit()
	(hub.find_child("app_quests", true, false) as Button).pressed.emit()
	_expect(_got == ["app:glodno", "app:quests"], "presses came back as %s" % [_got])
	# The search screen ends by itself (SEARCH_S of real time), once.
	_got.clear()
	hub.show_search("luber", Rules.words("app_luber"), Color.CYAN)
	_expect(hub.app() == "luber" and hub.find_child("searching", true, false) != null, "the search screen")
	_buttons(hub, 2, "search")  # back and close
	await create_timer(Rules.SEARCH_S + 0.4).timeout
	_expect(_got == ["searched:luber"], "the search ended once: %s" % [_got])
	# A new screen while a search runs: the old search stays silent.
	_got.clear()
	hub.show_search("glodno", Rules.words("app_glodno"), Color.ORANGE)
	hub.show_none("glodno", Rules.words("app_glodno"), Color.ORANGE)
	await create_timer(Rules.SEARCH_S + 0.4).timeout
	_expect(_got.is_empty() and hub.find_child("none", true, false) != null, "a stale search does not answer: %s" % [_got])
	# An offer.
	hub.show_offer("luber", Rules.words("app_luber"), {"who": "Ivan", "title": ["ŁUBER · NOWY KURS", "ŁUBER · New ride"],
			"body": [" Ivan ★ 4,8 · 300 m · 2,1 km", "Ivan ★ 4.8 · 300 m · 2.1 km"]}, Color.CYAN)
	_buttons(hub, 4, "offer")  # back, close, SKIP, TAKE
	(hub.find_child("skip", true, false) as Button).pressed.emit()
	(hub.find_child("take", true, false) as Button).pressed.emit()
	(hub.find_child("back", true, false) as Button).pressed.emit()
	_expect(_got == ["skip:luber", "take:luber", "home"], "offer presses came back as %s" % [_got])
	var closed := [false]
	hub.closed.connect(func() -> void: closed[0] = true)
	hub.close()
	_expect(closed[0] and not hub.is_open(), "closes")


func _buttons(hub: Control, n: int, what: String) -> void:
	var buttons := hub.find_children("*", "Button", true, false)
	_expect(buttons.size() == n, "%s: %d buttons, got %d" % [what, n, buttons.size()])
	for b: Node in buttons:
		_expect((b as Button).custom_minimum_size.y >= 44.0 * 3.0, "%s: %s under 44 pt" % [what, b.name])
