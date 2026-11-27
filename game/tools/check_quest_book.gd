extends SceneTree
## The QUESTS screen's contents (quest_book.gd, F's ask 2026-11-17), pure: made-up facts in, tabs
## out, no map, no game. Checks that:
## - every word key the builder and the screen use is in dialogue.json's "quest_book" group in both
##   languages (a missing one would show its key), and every "%" line takes its arguments;
## - the tabs come in TABS' order; First steps only while some are left (with n/7); questlines,
##   side jobs and rivals always (an empty one says why); the collection only after a find;
## - First steps: the ones left first, the nearest place first, done ones ticked at the bottom;
##   a step with a place offers SHOW ON MAP, which turns to STOP TRACKING when it is the pin;
## - questlines: a NEW one first, open ones by distance, one with no start only CALL; the NEW count
##   and the badge (`new_count`); the runs counted where the wallet counts them;
## - side jobs: one item per kind on offer (the nearest place), the count of jobs done, a request's
##   own START words; nothing but NOW while a quest runs;
## - rivals: the six with their state, RACE only for one not locked, the final last;
## - a turned-down invite (`mark_invite`) marks only a questline of the list NEW, with the toast's
##   words naming it; an unknown id marks nothing and says nothing; `story_facts` opens each
##   questline by its hours and marks the NEW one;
## - `find` and `first_tab`; every item has an icon key in ICONS, and every icon's file loads; the
##   beta card's SHOWCASE tiles name icons and words.
##   godot --headless --path game --script res://tools/check_quest_book.gd

const QuestBook := preload("res://scripts/quest_book.gd")
const Rules := preload("res://scripts/ride_rules.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const Ladder := preload("res://scripts/ladder.gd")

## The keys the code asks for besides the ones built from ids (tab_*, job_*, step_*_about ...).
const KEYS := ["quests", "new", "next", "tracked", "invite", "invite_later", "quit", "quit_sure", "empty", "busy",
		"b_map", "b_notebook", "b_untrack", "b_phone", "b_start", "b_race", "b_race_any", "b_night", "b_back", "b_route",
		"b_details", "b_show_quests", "b_show_drive", "show_title", "show_body", "show_body_open", "pad_map", "v_zl",
		"steps_head", "stories_head", "friends_wait", "rivals_head", "final", "final_about", "rival_about",
		"r_step", "r_step3", "r_step7", "v_step_done", "v_any", "v_hours", "v_closed", "hello_later", "call_night", "v_open", "v_times",
		"v_not_yet", "v_no_start", "v_on_request", "v_found", "f_done", "f_reward", "f_where", "f_with",
		"f_when", "f_nearest", "f_stake", "f_skill", "f_turf", "f_found", "v_rival_won", "v_rival_open",
		"v_rival_locked", "col_districts", "col_districts_about", "col_syrenki", "col_syrenki_about",
		"col_tapes", "col_tapes_about", "col_places", "col_places_about"]

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_words()
	var f := _facts()
	_tabs(f)
	_steps(f)
	_stories(f)
	_jobs(f)
	_rivals(f)
	_icons(f)
	_invites()
	if _problems == 0:
		print("check_quest_book: OK (%d tabs, %d words, %d icons named)" % [QuestBook.tabs(f).size(), KEYS.size(), QuestBook.ICONS.size()])
		quit(0)
	else:
		print("check_quest_book: %d problems" % _problems)
		quit(1)


func _words() -> void:
	var keys: Array = KEYS.duplicate()
	for t: String in QuestBook.TABS:
		keys.append("tab_" + t)
	for g: String in QuestBook.JOB_KINDS:
		keys.append_array(["job_" + g, "job_%s_about" % g])
	for id: String in FirstSteps.IDS:
		keys.append("step_%s_about" % id)
	for pair: Array in QuestBook.SHOWCASE:
		keys.append(str(pair[1]))
	for k: String in keys:
		var w := QuestBook.words(k)
		_expect(str(w[0]) != k and str(w[1]) != k and str(w[0]) != "" and str(w[1]) != "", "words for %s in both languages: %s" % [k, w])
	# Lines with arguments take them (both languages the same count).
	for k: String in ["invite", "invite_later", "v_zl", "v_times", "b_phone", "b_race"]:
		var w := QuestBook.words(k)
		_expect(str(w[0]).count("%") == str(w[1]).count("%") and str(w[0]).count("%") >= 1, "%s takes its argument in both languages: %s" % [k, w])
	var inv := QuestBook.fmt("invite", [["Sekretny rave", "Secret rave"]])
	_expect(str(inv[1]).contains("Secret rave") and str(inv[0]).contains("Sekretny rave"), "the call card's invite line: %s" % [inv])


func _facts() -> Dictionary:
	var L := Lines
	var e: Array = [
		L.entry("ride", "ride", L.Line.CAR, "Łuber", "Ride", Vector2.INF, Color.CYAN, "ride"),
		L.entry("garage", "garage", L.Line.CAR, "Warsztat u Mirka", "Mirek's garage", Vector2(400, 0), Color.BLUE),
		L.entry("k_far", "kebab", L.Line.CAR, "Kebab daleko", "Kebab far", Vector2(3000, 0), Color.ORANGE),
		L.entry("k_near", "kebab", L.Line.CAR, "Kebab blisko", "Kebab near", Vector2(100, 0), Color.ORANGE),
		L.entry("c1", "cassette", L.Line.HELI, "Kaseta", "Cassette", Vector2(900, 0), Color.PINK),
	]
	var steps: Array = []
	for id: String in FirstSteps.IDS:
		var nm: Array = FirstSteps.name_of(id)
		var en: Dictionary = {"kebab": e[3], "ride": e[0], "garage": e[1]}.get(id, {})
		steps.append({"id": id, "pl": nm[0], "en": nm[1], "done": id == "heli", "entry": en})
	var chips: Array = []
	for i in Ladder.RUNGS.size():
		chips.append({"rung": i, "state": "won" if i == 0 else ("locked" if i == Ladder.RUNGS.size() - 1 else "open")})
	var story := func(id: String, at: Vector2, is_new: bool) -> Dictionary:
		return {"id": id, "pl": id.to_upper(), "en": id.capitalize(), "who": ["Mati", "Mati"], "blurb": ["b", "b"],
				"hello": ["h", "h"], "colour": Color.PURPLE, "at": at, "open": true, "when": ["", ""], "new": is_new}
	return {"car": Vector2.ZERO, "entries": e, "jobs": {"kebab": 3, "boat_race": 2}, "now": {}, "friends": true,
			"steps": steps, "stories": [story.call("boat", Vector2(800, 0), false), story.call("rave", Vector2(2000, 0), true),
			story.call("tesla", Vector2.INF, false), story.call("kino", Vector2(300, 0), false)],
			"rivals": chips, "final": ["po sześciu", "locked"], "night": false, "districts": [], "total": 0}


func _tabs(f: Dictionary) -> void:
	var keys := QuestBook.tabs(f).map(func(t: Dictionary) -> String: return str(t["key"]))
	_expect(keys == ["steps", "stories", "jobs", "rivals"], "the tabs in order, no collection before a find: %s" % [keys])
	_expect(QuestBook.first_tab(QuestBook.tabs(f)) == "steps", "QUESTS opens on First steps while they last")
	var g := f.duplicate(true)
	for s: Dictionary in g["steps"]:
		s["done"] = true
	g["syrenki"] = [1, 10]
	keys = QuestBook.tabs(g).map(func(t: Dictionary) -> String: return str(t["key"]))
	_expect(keys == ["stories", "jobs", "rivals", "collection"], "all seven done: no First steps; a find: the collection: %s" % [keys])
	_expect(QuestBook.first_tab(QuestBook.tabs(g)) == "stories", "then QUESTS opens on the questlines")
	var empty := QuestBook.tabs({})
	keys = empty.map(func(t: Dictionary) -> String: return str(t["key"]))
	_expect(keys == QuestBook.ALWAYS, "with nothing known the three that always show: %s" % [keys])
	_expect(str(empty[1]["head"][1]) != "", "an empty side jobs tab says why")
	# F 2026-11-20: the taxi app's account is a tab of its own once main.gd hands the fact over.
	var h := f.duplicate(true)
	var keep := {}
	Rules.record(keep, 80, 2)
	Rules.record(keep, 40, 0)
	h["taxi"] = Rules.account(keep, 2)
	var with_taxi := QuestBook.tabs(h)
	keys = with_taxi.map(func(t: Dictionary) -> String: return str(t["key"]))
	_expect(keys == ["steps", "stories", "jobs", "taxi", "rivals"], "the taxi app's tab sits after the side jobs: %s" % [keys])
	var taxi: Dictionary = with_taxi[3]["items"][0]
	_expect(taxi["facts"].size() == 7 and str(taxi["facts"][0][1][0]) == "120 zł" and str(taxi["facts"][1][1][0]) == "60 zł" and str(taxi["facts"][2][1][1]).contains("4.87"),
			"the account: earned 120 zł, average 60 zł, the new driver's 4.87: %s" % [taxi["facts"]])


func _steps(f: Dictionary) -> void:
	var t: Dictionary = QuestBook.tabs(f)[0]
	var items: Array = t["items"]
	_expect(str(t["badge"]) == "1/7", "First steps n/7: %s" % t["badge"])
	_expect(items.size() == 7 and str(items[0]["id"]) == "step_kebab" and str(items[1]["id"]) == "step_garage",
			"the nearest place first: %s" % [items.map(func(x: Dictionary) -> String: return str(x["id"]))])
	_expect(str(items[6]["id"]) == "step_heli" and bool(items[6]["done"]) and (items[6]["buttons"] as Array).is_empty(), "the done step ticked at the bottom")
	_expect(str(items[0]["buttons"][0]["key"]) == "map", "a step with a place: SHOW ON MAP")
	var g := f.duplicate(true)
	g["tracked"] = "k_near"
	var tracked: Array = QuestBook.tabs(g)[0]["items"]
	_expect(str(tracked[0]["buttons"][0]["key"]) == "untrack", "the pin's step: STOP TRACKING")
	var ride := -1
	for i in items.size():
		if str(items[i]["id"]) == "step_ride":
			ride = i
	_expect(ride >= 0 and str(items[ride]["buttons"][0]["key"]) == "start", "a request's step: its own START")


func _stories(f: Dictionary) -> void:
	var t: Dictionary = QuestBook.tabs(f)[1]
	var ids: Array = (t["items"] as Array).map(func(x: Dictionary) -> String: return str(x["id"]))
	_expect(ids == ["story_rave", "story_kino", "story_boat", "story_tesla"], "NEW first, then the nearest, no start last: %s" % [ids])
	_expect(int(t["new"]) == 1 and QuestBook.new_count(f) == 1, "one NEW questline (tab %d, button %d)" % [int(t["new"]), QuestBook.new_count(f)])
	var tesla: Dictionary = t["items"][3]
	_expect((tesla["buttons"] as Array).size() == 1 and str(tesla["buttons"][0]["key"]) == "start", "no start spot: only CALL")
	var boat: Dictionary = t["items"][2]
	var counted := false
	for fact: Array in boat["facts"]:
		counted = counted or str(fact[1][1]).contains("2")
	_expect(counted, "the boat race's runs counted (wallet boat_race 2): %s" % [boat["facts"]])
	_expect(QuestBook.find(QuestBook.tabs(f), "story_boat") == ["stories", 2], "find: %s" % [QuestBook.find(QuestBook.tabs(f), "story_boat")])
	_expect(QuestBook.find(QuestBook.tabs(f), "nope") == ["", -1], "find: none")
	var g := f.duplicate(true)
	g["friends"] = false
	_expect(QuestBook.tabs(g)[1]["head"] == QuestBook.words("friends_wait"), "before the friends open the questlines say the friends call later")


func _jobs(f: Dictionary) -> void:
	var t: Dictionary = QuestBook.tabs(f)[2]
	var ids: Array = (t["items"] as Array).map(func(x: Dictionary) -> String: return str(x["id"]))
	_expect(ids == ["job_kebab", "job_ride", "job_cassette", "job_garage"], "one per kind, in JOB_KINDS' order: %s" % [ids])
	var kebab: Dictionary = t["items"][0]
	_expect(kebab["at"] == Vector2(100, 0), "the nearest kebab stand: %s" % kebab["at"])
	_expect(str(kebab["sub"][1]).contains("3"), "kebabs done: 3 (%s)" % [kebab["sub"]])
	var ride: Dictionary = t["items"][1]
	_expect(str(ride["buttons"][0]["key"]) == "start" and ride["buttons"][0]["words"] == QuestBook.words("b_ride"), "a request: its own START words")
	var now := Lines.entry("now", "now", Lines.Line.CAR, "Teraz", "Now", Vector2(5, 5), Color.RED, Lines.NOW)
	var g := f.duplicate(true)
	g["entries"] = [now]
	g["now"] = now
	var busy: Dictionary = QuestBook.tabs(g)[2]
	_expect((busy["items"] as Array).is_empty() and busy["head"] == QuestBook.words("busy"), "while a quest runs: no jobs, it says why")


func _rivals(f: Dictionary) -> void:
	var t: Dictionary = QuestBook.tabs(f)[3]
	var items: Array = t["items"]
	_expect(items.size() == Ladder.RUNGS.size() + 1 and str(items.back()["id"]) == "final", "the six and the final last (%d)" % items.size())
	_expect(str(t["badge"]) == "1/%d" % Ladder.RUNGS.size(), "rivals won: %s" % t["badge"])
	_expect(bool(items[0]["done"]) and str(items[0]["buttons"][0]["key"]) == "race", "a beaten rival can be raced again")
	_expect((items[Ladder.RUNGS.size() - 1]["buttons"] as Array).is_empty(), "a locked rival: no RACE")
	_expect(int(items[1]["buttons"][0]["entry"]["rung"]) == 1 and str(items[1]["buttons"][0]["entry"]["action"]) == Lines.RIVAL_CALL,
			"RACE calls that rung out")


func _icons(f: Dictionary) -> void:
	var g := f.duplicate(true)
	g["syrenki"] = [1, 10]
	g["districts"] = [{"name_pl": "A", "name_en": "A", "found": true, "pct": 10}]
	for t: Dictionary in QuestBook.tabs(g):
		for it: Dictionary in t["items"]:
			_expect(QuestBook.ICONS.has(str(it["icon"])), "%s has an icon name (%s)" % [it["id"], it["icon"]])
	for pair: Array in QuestBook.SHOWCASE:
		_expect(QuestBook.ICONS.has(str(pair[0])), "the beta tile %s has an icon name" % pair[0])
	# Each named icon is a file in game/art/quest_icons (the Codex set, 2026-11-17) that loads.
	for k: String in QuestBook.ICONS:
		var tex := QuestBook.icon(k)
		_expect(tex != null and tex.get_width() >= 128, "the icon %s (%s.png) is missing or smaller than 128 px" % [k, QuestBook.ICONS[k]])


func _invites() -> void:
	var defs := [{"id": "boat", "pl": "Wyścig łodzi", "en": "Boat race"}, {"id": "rave", "pl": "Rave", "en": "Rave"}]
	var intro := {}
	_expect(QuestBook.mark_invite(intro, defs, "ghost").is_empty() and intro.is_empty(),
			"an invite id that is no questline marks nothing NEW and shows no toast")
	_expect(QuestBook.mark_invite(intro, defs, "").is_empty() and intro.is_empty(), "an empty invite id marks nothing")
	var w := QuestBook.mark_invite(intro, defs, "boat")
	_expect(intro.keys() == [QuestBook.NEW_KEY + "boat"], "a turned-down questline is marked NEW, only that one: %s" % [intro])
	_expect(w.size() == 2 and "Wyścig łodzi" in str(w[0]) and "Boat race" in str(w[1]),
			"the toast names the questline in both languages: %s" % [w])
	_expect(not QuestBook.mark_invite(intro, defs, "boat").is_empty() and intro.size() == 1,
			"turning the same questline down again keeps one NEW mark")
	# A questline played to its end (F 2026-11-25): remembered per id, drops its NEW mark, no other id.
	_expect(not QuestBook.is_done(intro, "boat"), "a questline is not done before it is played")
	QuestBook.mark_done(intro, "boat")
	_expect(QuestBook.is_done(intro, "boat") and not QuestBook.is_done(intro, "rave"), "mark_done closes only that questline: %s" % [intro])
	_expect(not intro.has(QuestBook.NEW_KEY + "boat"), "a finished questline is no longer NEW: %s" % [intro])
	intro.erase(QuestBook.DONE_KEY + "boat")
	intro.erase(QuestBook.NEW_KEY + "boat")
	QuestBook.mark_invite(intro, defs, "boat")
	# The questlines' facts (`story_facts`): open by their hours at the clock, NEW by the mark.
	defs[1]["who"] = "Mati"
	defs[1]["hours"] = Vector2(22.0, 4.0)
	defs[0]["who"] = "Wiesiek"
	var sf := QuestBook.story_facts(defs, [12.0, 3], intro)
	_expect(sf.size() == 2 and bool(sf[0]["new"]) and not bool(sf[1]["new"]) and bool(sf[0]["open"]) and not bool(sf[1]["open"]),
			"story_facts: the boat NEW and open, the rave closed at noon: %s" % [sf])
	_expect(sf.size() == 2 and str(sf[1]["when"][1]) == "22:00-4:00" and sf[0]["at"] == Vector2.INF,
			"story_facts: the rave's hours, no start for a def without one: %s" % [sf])
