extends SceneTree
## The phone's contents (phone_rules.gd, F 2026-11-26), pure: made-up facts in, the model out. Checks that:
## - every word key the rules and the view ask for is in dialogue.json's "phone_hub" group in both
##   languages;
## - the apps come in order (ŁUBER, ZLECENIA, ZADANIA, COTAM), COTAM never enabled, ŁUBER only when a ride
##   can be requested and then says why not;
## - the featured quests come in F's order (night meet, Rave, TESŁO), only the ones that exist, a played
##   one marked done, all of them off while something is on;
## - the card draws (phone_hub.gd): the apps, the rows and CLOSE as buttons of at least 44 pt, and a press
##   hands its key or id back.
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
	var all := {"can_ride": true, "busy": false, "stories": ["rave", "meet", "tesla", "boat"], "done": ["rave"], "jobs_done": 3}
	var m := Rules.model(all)
	var keys: Array = []
	for a: Dictionary in m["apps"]:
		keys.append(a["key"])
	_expect(keys == ["luber", "jobs", "quests", "cotam"], "apps order %s" % [keys])
	_expect(not bool(m["apps"][3]["enabled"]), "COTAM is not built yet")
	_expect(bool(m["apps"][0]["enabled"]) and bool(m["apps"][1]["enabled"]) and bool(m["apps"][2]["enabled"]), "all three apps on")
	var ids: Array = []
	for r: Dictionary in m["featured"]:
		ids.append(r["id"])
	_expect(ids == ["meet", "rave", "tesla"], "featured order %s" % [ids])
	_expect(not bool(m["featured"][0]["done"]) and bool(m["featured"][1]["done"]), "a played quest is done")
	_expect(str(m["apps"][1]["sub"][1]).ends_with("3"), "the jobs count shows: %s" % [m["apps"][1]["sub"]])
	var no_ride := Rules.model({"can_ride": false, "busy": true, "stories": ["meet"], "done": []})
	_expect(not bool(no_ride["apps"][0]["enabled"]) and no_ride["apps"][0]["sub"] == Rules.words("no_ride"), "no ride: off and says why")
	_expect(no_ride["featured"].size() == 1 and not bool(no_ride["featured"][0]["enabled"]), "busy: the one quest there is, off")
	_expect(Rules.model({})["featured"].is_empty(), "no questlines: no rows")
	await process_frame  # the root takes the card into the tree on the first frame
	_view(m)
	if _problems == 0:
		print("check_phone_hub: OK")
		quit(0)
	else:
		print("check_phone_hub: %d problems" % _problems)
		quit(1)


## The card for the model: its buttons, their size, and the presses.
func _view(m: Dictionary) -> void:
	var hub := PhoneHub.new()
	hub.pt = 3.0
	hub.safe = Rect2(0, 0, 2532, 1170)
	root.add_child(hub)
	hub.app_pressed.connect(func(k: String) -> void: _got.append("app:" + k))
	hub.featured_pressed.connect(func(i: String) -> void: _got.append("feat:" + i))
	hub.open(m)
	_expect(hub.is_open(), "opens")
	var buttons := hub.find_children("*", "Button", true, false)
	_expect(buttons.size() == 4 + 3 + 1, "8 buttons (4 apps, 3 rows, close), got %d" % buttons.size())
	for b: Node in buttons:
		_expect((b as Button).custom_minimum_size.y >= 44.0 * 3.0, "%s under 44 pt" % b.name)
	(hub.find_child("app_jobs", true, false) as Button).pressed.emit()
	(hub.find_child("feat_rave", true, false) as Button).pressed.emit()
	_expect(_got == ["app:jobs", "feat:rave"], "presses came back as %s" % [_got])
	var closed := [false]
	hub.closed.connect(func() -> void: closed[0] = true)
	hub.close()
	_expect(closed[0] and not hub.is_open(), "closes")
