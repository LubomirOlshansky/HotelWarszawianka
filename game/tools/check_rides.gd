extends SceneTree
## Loop 2d-1: Podwózka's rules on synthetic events (game/scripts/ride_rules.gd, the numbers in
## docs/design/parodies.md 3.3 and the section 11 defaults), without the city:
##  1. the star table: a hard bump (closing speed over 4 m/s), braking over 18 m/s² and a corner
##     over 15 m/s² cost half a star each, 2 s apart, at most 2.0 in all; lateness half a star per
##     15 s past the ETA, at most 1.5; a police pull-over exactly one star; arriving within 0.8 of
##     the ETA and (a believer) driving the app's leg half a star each; the final rating to the
##     nearest half, 1.0 to 5.0;
##  2. the pay table: 15 zł + 9 zł a km, the MNOŻNIK (night ×1.5, rain ×1.2, both ×1.8), the tip
##     by stars (0.40 / 0.25 / 0.10 / 0), in a hurry ×1.2, respect 25 / 10 / 0; the design's
##     example (1.8 km by day at 5 stars: 31 + 12 = 43 zł);
##  3. the 5-star streak: +10 zł for each 5-star ride before this one, at most +50; a 4.5 keeps
##     it, below 4.5 or a cancel ends it;
##  4. the cancel rules: the passenger gives up past 3 × the ETA (not at it); a cancel pays
##     nothing and ends the streak; the player's rating (the last 20 rides, a new save 4,87);
##  5. the words: the star text, every dialogue group and tag rides.gd and gps_moments.gd ask for
##     has a line, Polish and English, Polish bubbles at most 70 characters, card buttons at most
##     28;
##  6. the story rides (scripts/taxi_stories.gd, data/taxi_stories.json): at least 18 stories with
##     unique ids, each with a name, type, teaser, a real place to go to, three lines, a question and two answers (button,
##     reply, tip, outro), every text Polish and English, bubbles at most 70 characters, buttons at
##     most 28, the question at most 90, no brand from data/brand_denylist.json; the rotation (every
##     story heard once before any comes back, the night one only at night, a forced id wins); the
##     beats' timing (the first line after 3 s, 7.5 s apart, the question by 45 % of the way or
##     32 s); a good talk's half star once; the story tip on the pay (a negative one takes the tip
##     and the streak, never the fare).
## Prints `check_rides: OK`, or the problems and their count (exit 1). Under a second.
##   godot --headless --path game --script res://tools/check_rides.gd

const Rules := preload("res://scripts/ride_rules.gd")
const Stories := preload("res://scripts/taxi_stories.gd")

## The groups and tags the ride code asks dialogue.gd for ("" = an untagged line).
const NEEDED := {
	"podwozka_request": ["", "timber", "date"],
	"podwozka_pickup": ["", "offset"],
	"podwozka_gps": ["river", "zone", "oldtown", "rechotka", "reroute", "arrive"],
	"podwozka_passenger": ["", "believer", "hurry", "followed", "timber", "date"],
	"podwozka_rating": ["5", "4", "low", "police", "cancel"],
	"podwozka_driver": ["arrive", "reroute", "river"],
}
## The card buttons the job shows (hud.gd WORDS gives the Polish).
const BUTTONS := ["PRZYJMIJ · Accept", "POMIŃ · Skip", "OK", "PODWÓZKA · ride app"]

var _problems := 0
var _checks := 0


func _initialize() -> void:
	_star_table()
	_pay_table()
	_streak()
	_cancel_and_rating()
	_words()
	_stories()
	if _problems == 0:
		print("check_rides: OK (%d checks: stars, pay, streak, cancel, rating, words, stories)" % _checks)
		quit(0)
	else:
		print("check_rides: %d problems in %d checks" % [_problems, _checks])
		quit(1)


func _expect(what: String, got, want) -> void:
	_checks += 1
	var same: bool = is_equal_approx(float(got), float(want)) if (got is float or want is float) else got == want
	if not same:
		_problems += 1
		print("check_rides: %s: got %s, want %s" % [what, str(got), str(want)])


func _star_table() -> void:
	var r := Rules.new()
	r.begin(100.0)
	_expect("a new ride's stars", r.stars(), 5.0)
	_expect("a bump at 3.9 m/s is free", r.drive_event("bump", 3.9), false)
	_expect("a bump at 4.5 m/s costs", r.drive_event("bump", 4.5), true)
	_expect("after one bump", r.stars(), 4.5)
	r.tick(1.0)
	_expect("braking hard 1 s after the bump waits (2 s apart)", r.drive_event("brake", 25.0), false)
	r.tick(1.1)
	_expect("braking at 18 m/s² is free", r.drive_event("brake", 18.0), false)
	_expect("braking at 19 m/s² costs", r.drive_event("brake", 19.0), true)
	r.tick(2.05)
	_expect("a corner at 15 m/s² is free", r.drive_event("corner", 15.0), false)
	_expect("a corner at 16 m/s² costs", r.drive_event("corner", 16.0), true)
	r.tick(2.05)
	_expect("the fourth driving half star", r.drive_event("bump", 9.0), true)
	_expect("after four", r.stars(), 3.0)
	r.tick(2.05)
	_expect("driving costs at most 2.0", r.drive_event("bump", 9.0), false)
	_expect("still", r.stars(), 3.0)

	var late := Rules.new()
	late.begin(60.0)
	late.tick(74.9)
	_expect("14.9 s past the ETA is free", late.stars(), 5.0)
	_expect("15 s past the ETA costs half a star", late.tick(0.2), true)
	_expect("15 s late", late.stars(), 4.5)
	late.tick(15.0)
	_expect("30 s late", late.stars(), 4.0)
	late.tick(15.0)
	_expect("45 s late", late.stars(), 3.5)
	late.tick(200.0)
	_expect("lateness costs at most 1.5", late.stars(), 3.5)

	var police := Rules.new()
	police.begin(100.0)
	police.pull_over()
	_expect("a police pull-over takes exactly one star", police.stars(), 4.0)
	_expect("and is remembered for the comment", police.pulled_over, true)

	var early := Rules.new()
	early.begin(100.0)
	early.tick(80.0)
	_expect("at 0.8 of the ETA is early", early.arrive(), true)
	_expect("early at 5 stars stays 5", early.stars(), 5.0)
	var slow := Rules.new()
	slow.begin(100.0)
	slow.tick(80.5)
	_expect("past 0.8 of the ETA is not early", slow.arrive(), false)
	var bumped := Rules.new()
	bumped.begin(100.0)
	bumped.drive_event("bump", 6.0)
	_expect("a believer's leg earns half a star", bumped.follow(), true)
	_expect("once", bumped.follow(), false)
	_expect("bump then the app's leg", bumped.stars(), 5.0)

	var low := Rules.new()
	low.begin(100.0, 4.3)
	_expect("--stars=4.3 rounds to 4.5", low.final(), 4.5)
	low.begin(100.0, 4.2)
	_expect("4.2 rounds to 4.0", low.final(), 4.0)
	low.begin(100.0, 1.0)
	low.pull_over()
	low.tick(500.0)
	_expect("never below one star", low.final(), 1.0)


func _pay_table() -> void:
	var p := Rules.pay(1800.0, 5.0, false, false, false, 0)
	_expect("1.8 km by day, 5 stars: fare", p["fare"], 31)
	_expect("tip", p["tip"], 12)
	_expect("total (the design's 43 zł)", p["total"], 43)
	_expect("respect", p["respect"], 25)
	p = Rules.pay(1800.0, 5.0, true, false, false, 0)
	_expect("at night the fare ×1.5", p["fare"], 47)
	_expect("and the tip on it", p["tip"], 19)
	_expect("night multiplier", p["mult"], 1.5)
	p = Rules.pay(1800.0, 5.0, false, true, false, 0)
	_expect("in the rain ×1.2", p["fare"], 37)
	p = Rules.pay(1800.0, 5.0, true, true, false, 0)
	_expect("night and rain ×1.8", p["mult"], 1.8)
	_expect("night and rain fare", p["fare"], 56)
	p = Rules.pay(1800.0, 4.5, false, false, false, 0)
	_expect("4.5 stars: tip 0.25", p["tip"], 8)
	_expect("4.5 stars: respect 10", p["respect"], 10)
	p = Rules.pay(1800.0, 4.0, false, false, false, 0)
	_expect("4 stars: tip 0.10", p["tip"], 3)
	_expect("4 stars: respect 10", p["respect"], 10)
	p = Rules.pay(1800.0, 3.5, false, false, false, 0)
	_expect("3.5 stars: no tip", p["tip"], 0)
	_expect("3.5 stars: no respect", p["respect"], 0)
	_expect("3.5 stars still pays the fare", p["total"], 31)
	p = Rules.pay(1800.0, 5.0, false, false, true, 0)
	_expect("in a hurry: tip ×1.2", p["tip"], 15)
	_expect("ETA for 1.8 km", Rules.eta_for(1800.0), 220.0)
	_expect("ETA in a hurry ×0.8", Rules.eta_for(1800.0, true), 176.0)


func _streak() -> void:
	_expect("the first 5-star ride: no streak bonus", Rules.pay(1000.0, 5.0, false, false, false, 0)["streak"], 0)
	_expect("after one: +10", Rules.pay(1000.0, 5.0, false, false, false, 1)["streak"], 10)
	_expect("after three: +30", Rules.pay(1000.0, 5.0, false, false, false, 3)["streak"], 30)
	_expect("after five: +50", Rules.pay(1000.0, 5.0, false, false, false, 5)["streak"], 50)
	_expect("at most +50", Rules.pay(1000.0, 5.0, false, false, false, 9)["streak"], 50)
	_expect("a 4.5 pays no streak bonus", Rules.pay(1000.0, 4.5, false, false, false, 4)["streak"], 0)
	_expect("a 5 adds to it", Rules.next_streak(2, 5.0), 3)
	_expect("a 4.5 keeps it", Rules.next_streak(2, 4.5), 2)
	_expect("a 4 ends it", Rules.next_streak(2, 4.0), 0)
	_expect("a cancel ends it", Rules.next_streak(2, 5.0, true), 0)
	_expect("streak_after in the pay", Rules.pay(1000.0, 5.0, false, false, false, 2)["streak_after"], 3)


func _cancel_and_rating() -> void:
	var r := Rules.new()
	r.begin(100.0)
	r.tick(300.0)
	_expect("at 3 × the ETA the passenger still waits", r.overdue(), false)
	r.tick(0.1)
	_expect("past 3 × the ETA they cancel", r.overdue(), true)
	_expect("a new save's rating", Rules.rating([]), 4.87)
	_expect("after one 5-star ride", snappedf(Rules.rating([5.0]), 0.0001), 4.8765)
	var h: Array = []
	for i in 25:
		h = Rules.pushed(h, 5.0)
	_expect("the history keeps 20", h.size(), 20)
	_expect("20 perfect rides make 5.00", Rules.rating(h), 5.0)
	h = Rules.pushed(h, 1.0)
	_expect("one bad ride among 20", Rules.rating(h), 4.8)


func _words() -> void:
	_expect("4.5 stars", Rules.stars_text(4.5), "★★★★½ 4,5")
	_expect("5 stars", Rules.stars_text(5.0), "★★★★★ 5,0")
	_expect("3.7 rounds to 3.5", Rules.stars_text(3.7, false), "★★★½ 3.5")
	_expect("the MNOŻNIK at night", Rules.surge_text(true, false), "×1,5 · NOC")
	_expect("no MNOŻNIK by day", Rules.surge_text(false, false), "")
	var card := Rules.offer_text({"name": "Kasia", "away": 350.0, "road": 1800.0, "their": 4.9,
			"note": ["Uwagi: „stoję pod Frogsem”.", "Note: \"I'm outside the Frogs.\""], "night": true, "rain": false,
			"rating": 4.87})
	_expect("the request card's first line", String(card[1]).get_slice("\n", 0), "Kasia ★ 4,9 · 350 m · 1,8 km")
	_expect("the request card's MNOŻNIK (the title)", card[0], "PODWÓZKA · MNOŻNIK ×1,5")
	_expect("its gloss", card[2], "New ride · surge ×1.5 · night")
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	if not data is Dictionary:
		_expect("dialogue.json parses", false, true)
		return
	for group in NEEDED:
		var lines: Array = data.get(group, [])
		_expect("%s has lines" % group, lines.is_empty(), false)
		for tag in NEEDED[group]:
			var found := false
			for l in lines:
				var only = l[2].get("only", null) if l.size() > 2 and l[2] is Dictionary else null
				if (tag == "" and only == null) or (only is String and only == tag) or (only is Array and tag in only):
					found = true
			_expect("%s has a line for '%s'" % [group, tag], found, true)
		for l in lines:
			_expect("%s: Polish and English" % group, l.size() >= 2 and String(l[0]) != "" and String(l[1]) != "", true)
			if String(l[0]).length() > 70:
				_expect("%s: bubble ≤ 70 characters: %s" % [group, l[0]], String(l[0]).length(), 70)
	for b in BUTTONS:
		_checks += 1
		if String(b).length() > 28:
			_problems += 1
			print("check_rides: button '%s' over 28 characters" % b)


func _stories() -> void:
	var all: Array = Stories.load_all()
	_expect("story count ≥ 18", all.size() >= 18, true)
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var brands: Array = deny.get("names", []) + deny.get("rejected", [])
	var ids := {}
	for st in all:
		var id := String(st.get("id", ""))
		_expect("story id set", id != "", true)
		_expect("story id %s unique" % id, ids.has(id), false)
		ids[id] = true
		var texts: Array = []  # [text, limit]
		_expect("%s: a name" % id, String(st.get("name", "")) != "", true)
		for key in ["who", "teaser", "ask"]:
			texts.append([st.get(key, []), 90])
		var lines: Array = st.get("lines", [])
		_expect("%s: three lines" % id, lines.size(), 3)
		for l in lines:
			texts.append([l, 70])
		var answers: Array = st.get("answers", [])
		_expect("%s: two answers" % id, answers.size(), 2)
		for a in answers:
			texts.append([a.get("say", []), 28])
			texts.append([a.get("reply", []), 70])
			texts.append([a.get("outro", []), 90])
			_expect("%s: an answer's tip is a number" % id, typeof(a.get("tip")) in [TYPE_INT, TYPE_FLOAT], true)
			_expect("%s: an answer's star is true or false" % id, typeof(a.get("star")) == TYPE_BOOL, true)
		var to: Dictionary = st.get("to", {})
		_expect("%s: a real place to go to (to.name, to.at, to.r)" % id, to.has("name") and (to.get("at", []) as Array).size() == 2
				and float(to.get("r", 0)) > 0.0 and (to.get("drop", []) as Array).size() == 2, true)
		texts.append([to.get("name", []), 28])
		if st.has("silent"):
			texts.append([st["silent"], 70])
		for t in texts:
			var pair: Array = t[0]
			_expect("%s: Polish and English %s" % [id, str(pair)], pair.size() == 2 and String(pair[0]) != "" and String(pair[1]) != "", true)
			if pair.size() < 2:
				continue
			if String(pair[0]).length() > int(t[1]):
				_expect("%s: ≤ %d characters: %s" % [id, t[1], pair[0]], String(pair[0]).length(), t[1])
			for side in pair:
				var low := " %s " % String(side).to_lower()
				for b in brands:
					var rx := RegEx.create_from_string("(?<![\\p{L}\\p{N}])%s(?![\\p{L}\\p{N}])" % _escape(String(b)))
					if rx.search(low) != null:
						_expect("%s: no brand '%s' in %s" % [id, b, side], true, false)
	var night := all.filter(func(st: Dictionary) -> bool: return String(st.get("when", "")) == "night")
	# The rotation: a whole round by day hears each day story exactly once.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Array = []
	var day := all.size() - night.size()
	var heard := {}
	for i in day:
		var st: Dictionary = Stories.pick(all, seen, rng, false)
		_expect("a day pick is not a night story", String(st.get("when", "")) == "night", false)
		heard[st["id"]] = true
		seen = Stories.heard(seen, st["id"])
	_expect("one day round hears every day story once", heard.size(), day)
	var next: Dictionary = Stories.pick(all, seen, rng, false)
	_expect("after the round, not one of the last four", seen.slice(seen.size() - 4).has(next["id"]), false)
	if not night.is_empty():
		var by_night: Dictionary = Stories.pick(all, seen, rng, true)
		_expect("at night the unheard night story comes next", by_night["id"], night[0]["id"])
	_expect("a forced story", Stories.pick(all, [], rng, false, "mordor").get("id", ""), "mordor")
	_expect("heard() moves an id to the end", Stories.heard(["a", "b", "c"], "a"), ["b", "c", "a"])
	# The beats.
	_expect("no line before 3 s", Stories.due(0, 1.0, 2.0, 99.0), false)
	_expect("the first line at 3 s", Stories.due(0, 0.0, 3.0, 0.0), true)
	_expect("lines 7.5 s apart", Stories.due(1, 0.9, 20.0, 7.0), false)
	_expect("line 2 at 16 % of the way", Stories.due(1, 0.16, 5.0, 8.0), true)
	_expect("the question waits for 45 %", Stories.due(3, 0.44, 20.0, 9.0), false)
	_expect("the question at 45 %", Stories.due(3, 0.45, 20.0, 9.0), true)
	_expect("the question by 32 s anyway", Stories.due(3, 0.1, 32.0, 9.0), true)
	_expect("no beat after the question", Stories.due(4, 1.0, 99.0, 99.0), false)
	# The half star and the pay.
	var r := Rules.new()
	r.begin(100.0)
	r.drive_event("bump", 9.0)
	_expect("a good talk's half star", r.chat(), true)
	_expect("only once", r.chat(), false)
	_expect("stars after a bump and a good talk", r.stars(), 5.0)
	var plain := Rules.pay(1800.0, 5.0, false, false, false, 0)
	var talk := Rules.pay(1800.0, 5.0, false, false, false, 0, 12)
	_expect("a story tip adds to the total", int(talk["total"]) - int(plain["total"]), 12)
	var invest := Rules.pay(1800.0, 5.0, false, false, false, 0, -20)
	_expect("an investment of 20 zł takes the 12 zł tip, not the fare", int(invest["total"]), int(plain["fare"]))
	_expect("the result card says the story tip", String(Rules.result_text({"stars": 5.0, "pay": talk, "rating": 4.9})[1]).contains("rozmowa 12"), true)


func _escape(t: String) -> String:
	var out := ""
	for c in t:
		out += ("\\" + c) if ".+*?()[]{}|^$\\".contains(c) else c
	return out
