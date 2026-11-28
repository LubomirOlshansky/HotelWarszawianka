extends RefCounted
## The QUESTS screen's contents (F's ask 2026-11-17: "make the map minimalistic and a separate
## quests screen with a big QUESTS button on the map, tabs like questlines, side jobs and so on,
## where the player taps and sees a description, and what is done, how many deliveries"). The plan:
## https://claude.ai/artifact/EdLnFk5DtfTakCMq2JeRzn; the research behind it (Fable, 2026-11-17):
## the map answers "where", the journal answers "what and how far along", and the bridge between
## them is one action, SHOW ON MAP (Chinatown Wars' PDA, Zelda's Adventure Log, Genshin's quest menu).
##
## Pure (no nodes): main.gd `_fill_map_list` gathers the facts, full_map.gd hands them to `tabs`,
## quests_screen.gd draws what comes back, and game/tools/check_quest_book.gd drives it with made-up
## facts. The words are dialogue.json's group "quest_book" (TD-19), one line per key: `words(key)`.
##
## The tabs, in order (a tab with nothing in it is left out, but QUESTLINES, SIDE JOBS and RIVALS
## always show so the player learns where things live):
##   steps       FIRST STEPS, until all seven are done (first_steps.gd): each step,
##               done ones ticked at the bottom, with the place or request that does it;
##   stories     QUESTLINES: every friend's questline (story_quests.gd), open ones first,
##               nearest first, "new" ones (invited, not opened here yet) on top;
##   jobs        SIDE JOBS: one entry per kind of job on offer now (the nearest place of
##               that kind), with how many the player has done (wallet.gd `jobs`);
##   taxi        ŁUBER: the taxi app's driver account (F 2026-11-20): earned ever, the average fare,
##               the rating, rides, best ride and streaks (ride_rules.gd `account`); only when main.gd
##               hands over the `taxi` fact;
##   rivals      RIVALS: the Six (ladder.gd) and the final;
##   collection  COLLECTION: districts, Syrenki, tapes, places found.
##
## One item: {"id", "tab", "title": [pl, en], "sub": [pl, en] (the list row's second line),
## "colour", "who" (the face: a name portraits.gd knows, "" for none), "about": [pl, en],
## "facts": [[label [pl, en], value [pl, en]], ...], "done": bool, "new": bool, "at" (map point or
## INF), "icon": a key of ICONS ("" none), "buttons": [{"key", "words": [pl, en], "entry": the quest_lines entry it hands back,
## "gold": bool}]}. A button's key: "map" (SHOW ON MAP: the entry becomes the quest pin and the map
## looks at it), "untrack" (the pin goes), "start" (a request: a ride, a rescue call, a friend's call,
## the night for the final: main.gd `_on_quest_picked`), "race" (a rival called out: `rung`).

const Lines := preload("res://scripts/quest_lines.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const Ladder := preload("res://scripts/ladder.gd")
const StoryQuests := preload("res://scripts/story_quests.gd")
const Rules := preload("res://scripts/ride_rules.gd")

const DIALOGUE_PATH := "res://data/dialogue.json"
const GROUP := "quest_book"
## The tabs, in the order the screen shows them.
const TABS := ["steps", "stories", "jobs", "taxi", "rivals", "collection"]
## The tabs that show even when empty.
const ALWAYS := ["stories", "jobs", "rivals"]
## The side jobs' kinds, in the tab's order, and the wallet.gd `jobs` key that counts each ("" none).
const JOB_KINDS := ["kebab", "ride", "call", "sloik", "lezak", "trend", "mlask", "drop", "peacock", "cassette", "garage", "crawl"]
const JOB_COUNT := {"kebab": "kebab", "ride": "podwozka", "call": "rescue", "sloik": "sloik", "lezak": "roundup",
		"trend": "trend", "mlask": "trend", "drop": "trend", "peacock": "", "cassette": "", "garage": "", "crawl": "crawl"}
## A questline's wallet.gd `jobs` key, where its runs are counted on their own ("" none: the coffee
## run and padel are paid as "trend", with the other trend jobs).
const STORY_COUNT := {"boat": "boat_race", "rave": "rave", "dekalog": "dekalog_tour", "kino": "kino_tour", "meet": "meet_race",
		"tesla": "ev_tow", "bokiem": "bokiem"}
## Each item's icon (game/art/quest_icons/<name>.png, made with Codex on 2026-11-17 for F's ask "an
## icon for each quest"): by questline id, job group, First step id or tab. A missing file draws the
## item's colour dot instead (`icon`).
const ICON_DIR := "res://art/quest_icons/"
## The wallet intro key prefix that marks a questline NEW in QUESTS (a turned-down invite, `mark_invite`).
const NEW_KEY := "qnew_"
## The wallet intro key prefix of a questline played to its end (F 2026-11-25: its friend never phones
## again; the QUESTS screen and the start spot still start it on purpose).
const DONE_KEY := "qdone_"
const ICONS := {"kebab": "kebab", "ride": "ride", "call": "rescue", "rescue": "rescue", "sloik": "jars", "lezak": "scooter",
		"trend": "trend", "mlask": "foodvan", "drop": "drop", "peacock": "peacock", "cassette": "cassette", "garage": "garage", "crawl": "club",
		"boat": "boat", "rave": "rave", "smola": "club", "dekalog": "film_tour", "kawa": "coffee", "padel": "padel",
		"meet": "meet", "bokiem": "meet", "kino": "cinema", "tesla": "ev_tow", "race": "rivals", "rivals": "rivals", "final": "rivals",
		"heli": "heli", "police": "police", "districts": "collection", "syrenki": "collection", "tapes": "cassette",
		"places": "collection", "collection": "collection"}
## The beta card's tiles (F 2026-11-17: "in the first minutes introduce that there are the different
## activities"): [icon key, words key], in the order the card shows them (first10.gd `beta`).
const SHOWCASE := [["kebab", "show_kebab"], ["ride", "show_ride"], ["rivals", "show_race"], ["rescue", "show_rescue"],
		["boat", "show_stories"], ["collection", "show_collect"]]
const GOLD := Color("#ffd23f")
const RIVAL_COLOUR := Color("#ff4f6d")
const COLLECTION_COLOUR := Color("#ffd23f")

## dialogue.json's "quest_book" lines by key, read once; the icons loaded so far (null: no file).
static var _words: Dictionary = {}
static var _icons: Dictionary = {}


## The icon for `key` (ICONS), null when there is none (the list draws the colour dot).
static func icon(key: String) -> Texture2D:
	var name := str(ICONS.get(key, ""))
	if name == "":
		return null
	if not _icons.has(name):
		var path := ICON_DIR + name + ".png"
		_icons[name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[name]


## [Polish, English] for one key of dialogue.json's "quest_book" group ([key, key] when missing).
static func words(key: String) -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_PATH)) if FileAccess.file_exists(DIALOGUE_PATH) else null
		var lines: Variant = d.get(GROUP, []) if d is Dictionary else []
		for l: Variant in lines:
			if l is Array and l.size() >= 3 and l[2] is Dictionary and l[2].has("only"):
				_words[str(l[2]["only"])] = [str(l[0]), str(l[1])]
	return _words.get(key, [key, key])


## The words of `key` with `args` put in (both languages; each arg a value, or [pl, en]).
static func fmt(key: String, args: Array) -> Array:
	var w := words(key)
	var pl: Array = []
	var en: Array = []
	for a: Variant in args:
		pl.append(a[0] if a is Array else a)
		en.append(a[1] if a is Array else a)
	return [str(w[0]) % pl, str(w[1]) % en]


## The `stories` facts for `tabs`: one per questline of `defs` (story_quests.gd, with main.gd's
## blurbs), open or closed at `clock` ([hour, weekday]), NEW while `intro` (wallet.gd) marks it.
static func story_facts(defs: Array, clock: Array, intro: Dictionary) -> Array:
	var out: Array = []
	for d: Dictionary in defs:
		if not StoryQuests.shown(d):
			continue  # a gated questline (drift_event.gd before the first night meet)
		out.append({"id": d["id"], "pl": d["pl"], "en": d["en"], "who": d["who"], "blurb": d.get("blurb", ["", ""]),
				"hello": d.get("hello", ["", ""]), "colour": d.get("colour", Lines.STORY_COLOUR), "at": d.get("at", Vector2.INF),
				"open": StoryQuests.open_at(d, float(clock[0]), int(clock[1])), "new": intro.has(NEW_KEY + str(d["id"])),
				"when": [StoryQuests.when_text(d, true), StoryQuests.when_text(d, false)]})
	return out


## Is questline `id` finished for good (`intro` is wallet.gd's)?
static func is_done(intro: Dictionary, id: String) -> bool:
	return intro.has(DONE_KEY + id)


## Questline `id` was played to its end: remember it, and drop its NEW mark.
static func mark_done(intro: Dictionary, id: String) -> void:
	intro[DONE_KEY + id] = 1
	intro.erase(NEW_KEY + id)


## A questline's call was turned down or rang out (activity.gd `declined`): mark it NEW in QUESTS in
## `intro` (wallet.gd) and return the toast's words, or [] and mark nothing for an id that is no
## questline of `defs` (story_quests.gd). It can't be one under way: `declined` fires only from that
## activity's ringing or offer card. A finished questline never phones again (`mark_done`), but a played one can be started again from QUESTS.
static func mark_invite(intro: Dictionary, defs: Array, id: String) -> Array:
	for d: Dictionary in defs:
		if str(d.get("id", "")) == id:
			intro[NEW_KEY + id] = 1
			return fmt("invite_later", [[str(d.get("pl", id)), str(d.get("en", id))]])
	return []


## The tabs for these facts: [{"key", "title": [pl, en], "badge": String ("2/7", "" none), "head":
## [pl, en] (a line over the list, ["", ""] none), "new": how many of its items are new, "items":
## [item, ...]}]. Facts (all optional):
##   car: Vector2; tracked: the quest pin's id ("" none); now: the entry under way ({} none);
##   entries: main.gd `_quest_entries` (places and requests; empty while something runs);
##   steps: [{"id", "pl", "en", "done", "entry"}] all seven in order (first_steps.gd), [] once done;
##   friends: the friends call now (the third First step);
##   stories: [{"id", "pl", "en", "who", "blurb", "hello", "colour", "at", "open", "when", "new"}];
##   jobs: wallet.gd `jobs`; taxi: ride_rules.gd `account` ({} none); rivals: ladder.gd `chips`; final: [text, state] (ladder `rows`' last);
##   night: the final's night button shows; districts: [{"name_pl", "name_en", "found", "pct"}];
##   total: the districts' per cent; syrenki, tapes, places: [found, of].
static func tabs(f: Dictionary) -> Array[Dictionary]:
	var car: Vector2 = f.get("car", Vector2.ZERO)
	var out: Array[Dictionary] = []
	for key: String in TABS:
		var t := {"key": key, "title": words("tab_" + key), "badge": "", "head": ["", ""], "items": [], "new": 0}
		match key:
			"steps":
				var steps: Array = f.get("steps", [])
				if steps.is_empty():
					continue
				var n := 0
				for s: Dictionary in steps:
					n += 1 if bool(s.get("done", false)) else 0
				if n >= steps.size():
					continue
				t["badge"] = "%d/%d" % [n, steps.size()]
				t["head"] = fmt("steps_head", [FirstSteps.STEP_ZL, FirstSteps.RESPECT_ALL])
				t["items"] = _steps(steps, n, car, str(f.get("tracked", "")))
			"stories":
				t["items"] = _stories(f.get("stories", []), car, str(f.get("tracked", "")), f.get("jobs", {}))
				t["head"] = words("stories_head") if bool(f.get("friends", true)) else words("friends_wait")
				for it: Dictionary in t["items"]:
					t["new"] = int(t["new"]) + (1 if bool(it["new"]) else 0)
			"jobs":
				t["items"] = _jobs(f.get("entries", []), car, str(f.get("tracked", "")), f.get("jobs", {}))
				if (t["items"] as Array).is_empty():
					t["head"] = words("busy") if not (f.get("now", {}) as Dictionary).is_empty() else words("empty")
			"taxi":
				if (f.get("taxi", {}) as Dictionary).is_empty():
					continue
				t["items"] = _taxi(f["taxi"])
			"rivals":
				t["items"] = _rivals(f.get("rivals", []), f.get("final", []), bool(f.get("night", false)), f.get("entries", []), car)
				var won := 0
				for c: Dictionary in f.get("rivals", []):
					won += 1 if str(c.get("state", "")) == "won" else 0
				t["badge"] = "%d/%d" % [won, Ladder.RUNGS.size()]
				t["head"] = words("rivals_head")
			"collection":
				t["items"] = _collection(f)
				if (t["items"] as Array).is_empty():
					continue
				t["badge"] = "%d%%" % int(f.get("total", 0))
		if (t["items"] as Array).is_empty() and not key in ALWAYS:
			continue
		out.append(t)
	return out


## How many things the QUESTS button counts as new (questlines invited and not opened here yet).
static func new_count(f: Dictionary) -> int:
	var n := 0
	for s: Dictionary in f.get("stories", []):
		n += 1 if bool(s.get("new", false)) else 0
	return n


## The tab the screen opens on: the First steps while they last, else the questlines.
static func first_tab(tabs_list: Array) -> String:
	return str(tabs_list[0]["key"]) if not tabs_list.is_empty() else "stories"


## The tab and the index of the item with `id` ("" / -1 none), to open the screen on it.
static func find(tabs_list: Array, id: String) -> Array:
	for t: Dictionary in tabs_list:
		var items: Array = t["items"]
		for i in items.size():
			if str(items[i]["id"]) == id:
				return [str(t["key"]), i]
	return ["", -1]


# --- the tabs ------------------------------------------------------------------------------------

static func _item(id: String, tab: String, title: Array, colour: Color, icon_key := "") -> Dictionary:
	return {"id": id, "tab": tab, "title": title, "sub": ["", ""], "colour": colour, "who": "", "about": ["", ""],
			"facts": [], "done": false, "new": false, "at": Vector2.INF, "buttons": [], "icon": icon_key}


## SHOW ON MAP for a place (STOP TRACKING when it is the pin already), a request's own button, or none.
static func _place_buttons(e: Dictionary, tracked: String, start_words: Array = []) -> Array:
	if e.is_empty():
		return []
	var action := str(e.get("action", ""))
	if action == "" and e.get("at", Vector2.INF) != Vector2.INF:
		if str(e["id"]) == tracked and tracked != "":
			return [{"key": "untrack", "words": words("b_untrack"), "entry": e, "gold": false}]
		return [{"key": "map", "words": words("b_map"), "entry": e, "gold": true}]
	if action == Lines.RIVAL_CALL:
		return [{"key": "race", "words": start_words if not start_words.is_empty() else words("b_race_any"), "entry": e, "gold": true}]
	if action != "" and action != Lines.NOW:
		return [{"key": "start", "words": start_words if not start_words.is_empty() else words("b_start"), "entry": e, "gold": true}]
	return []


static func _far(car: Vector2, at: Vector2) -> Array:
	if at == Vector2.INF:
		return ["", ""]
	return [Lines.far_text(car, at, true), Lines.far_text(car, at, false)]


## The seven First steps: the ones left first (the nearest place first, then requests, then the
## ones a button does), the done ones ticked at the bottom. The reward each step left pays is the
## one the next tick pays (the third: a paint and the friends; the seventh: a paint and respect).
static func _steps(steps: Array, n: int, car: Vector2, tracked: String) -> Array:
	var left: Array = []
	var done: Array = []
	var reward := fmt("r_step", [FirstSteps.STEP_ZL])
	if n + 1 == FirstSteps.NOTICED_AT:
		reward = fmt("r_step3", [FirstSteps.STEP_ZL])
	elif n + 1 == FirstSteps.IDS.size():
		reward = fmt("r_step7", [FirstSteps.STEP_ZL, FirstSteps.RESPECT_ALL])
	for s: Dictionary in steps:
		var id := str(s["id"])
		var it := _item("step_" + id, "steps", [str(s["pl"]), str(s["en"])], GOLD, id)
		it["about"] = words("step_%s_about" % id)
		var e: Dictionary = s.get("entry", {})
		if bool(s.get("done", false)):
			it["done"] = true
			it["sub"] = words("v_step_done")
			it["facts"] = [[words("f_done"), words("v_step_done")]]
			done.append(it)
			continue
		it["at"] = e.get("at", Vector2.INF) if not e.is_empty() else Vector2.INF
		it["sub"] = _far(car, it["at"]) if it["at"] != Vector2.INF else reward
		it["facts"] = [[words("f_reward"), reward]]
		if it["at"] != Vector2.INF:
			it["facts"].append([words("f_where"), _far(car, it["at"])])
		it["buttons"] = _place_buttons(e, tracked)
		it["d"] = car.distance_to(it["at"]) if it["at"] != Vector2.INF else (1e8 if not e.is_empty() else 1e9)
		left.append(it)
	left.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	return left + done


## Every questline: new ones first, then open ones nearest first, then closed ones, then those with
## no start spot. The row's second line is when and how far; the detail is the friend's own words.
static func _stories(stories: Array, car: Vector2, tracked: String, jobs: Dictionary) -> Array:
	var out: Array = []
	for s: Dictionary in stories:
		var id := str(s["id"])
		var colour: Color = s.get("colour", Lines.STORY_COLOUR)
		var name := [str(s["pl"]), str(s["en"])]
		var it := _item("story_" + id, "stories", name, colour, id)
		var who: Array = s.get("who", ["", ""])
		it["who"] = str(who[1])
		it["new"] = bool(s.get("new", false))
		var at: Vector2 = s.get("at", Vector2.INF)
		it["at"] = at
		var blurb: Array = s.get("blurb", ["", ""])
		var hello: Array = s.get("hello", ["", ""])
		it["about"] = blurb
		if str(hello[1]) != "":
			it["about"] = [("%s\n\n%s" % [blurb[0], hello[0]]).strip_edges(), ("%s\n\n%s" % [blurb[1], hello[1]]).strip_edges()]
		var open := bool(s.get("open", true))
		var when: Array = s.get("when", ["", ""])
		var when_v: Array = words("v_any") if str(when[1]) == "" else (fmt("v_hours", [when]) if open else fmt("v_closed", [when]))
		if open and str(when[1]) != "":
			when_v = words("v_open")
		var count_key := str(STORY_COUNT.get(id, ""))
		var done_v: Array = []
		if count_key != "":
			var n := int(jobs.get(count_key, 0))
			done_v = fmt("v_times", [n]) if n > 0 else words("v_not_yet")
		var far := _far(car, at)
		it["sub"] = [("%s · %s" % [when_v[0], far[0]]) if far[0] != "" else str(when_v[0]),
				("%s · %s" % [when_v[1], far[1]]) if far[1] != "" else str(when_v[1])]
		it["facts"] = [[words("f_with"), [str(who[0]), str(who[1])]], [words("f_when"), when_v],
				[words("f_where"), far if far[1] != "" else words("v_no_start")]]
		if not done_v.is_empty():
			it["facts"].append([words("f_done"), done_v])
		var buttons: Array = []
		if at != Vector2.INF:
			var pin := Lines.entry("start_" + id, "story", Lines.Line.STORY, str(name[0]), str(name[1]), at, colour)
			buttons.append_array(_place_buttons(pin, tracked))
		var call := Lines.entry("story_" + id, "story", Lines.Line.STORY, str(name[0]), str(name[1]), Vector2.INF, colour, "story")
		call["story"] = id
		buttons.append({"key": "start", "words": fmt("b_phone", [[str(who[0]).to_upper(), str(who[1]).to_upper()]]),
				"entry": call, "gold": at == Vector2.INF})
		it["buttons"] = buttons
		it["d"] = (0.0 if it["new"] else 1e7) + (car.distance_to(at) if at != Vector2.INF else 1e6) + (0.0 if open else 1e8)
		out.append(it)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	return out


## One entry per kind of side job on offer now: its nearest place (or its request), its count.
static func _jobs(entries: Array, car: Vector2, tracked: String, jobs: Dictionary) -> Array:
	var best := {}
	for e: Dictionary in entries:
		var g := str(e["group"])
		if not g in JOB_KINDS or str(e.get("action", "")) == Lines.NOW:
			continue
		var at: Vector2 = e.get("at", Vector2.INF)
		var d := car.distance_to(at) if at != Vector2.INF else -1.0
		if not best.has(g) or (at != Vector2.INF and d < float(best[g]["d"])):
			best[g] = {"e": e, "d": d}
	var out: Array = []
	for g: String in JOB_KINDS:
		if not best.has(g):
			continue
		var e: Dictionary = best[g]["e"]
		var it := _item("job_" + g, "jobs", words("job_" + g), e.get("colour", GOLD), g)
		it["about"] = words("job_%s_about" % g)
		it["at"] = e.get("at", Vector2.INF)
		var far := _far(car, it["at"])
		var key := str(JOB_COUNT.get(g, ""))
		var n := int(jobs.get(key, 0)) if key != "" else -1
		var place := [str(e["pl"]), str(e["en"])]
		it["sub"] = far if far[1] != "" else words("v_on_request")
		if n > 0:
			var done := fmt("v_times", [n])
			it["sub"] = [("%s · %s" % [it["sub"][0], done[0]]), ("%s · %s" % [it["sub"][1], done[1]])]
		it["facts"] = []
		if far[1] != "":
			it["facts"].append([words("f_nearest"), [("%s · %s" % [place[0], far[0]]), ("%s · %s" % [place[1], far[1]])]])
		if n >= 0:
			it["facts"].append([words("f_done"), fmt("v_times", [n]) if n > 0 else words("v_not_yet")])
		var start_words: Array = words("b_" + g) if str(e.get("action", "")) != "" else []
		it["buttons"] = _place_buttons(e, tracked, start_words)
		out.append(it)
	return out


## The taxi app's driver account: one entry, the numbers of ride_rules.gd `account` (also what a later
## online leaderboard reads).
static func _taxi(a: Dictionary) -> Array:
	var it := _item("taxi_account", "taxi", words("taxi_title"), Color("#4fd8c4"), "ride")
	it["about"] = words("taxi_about")
	var stars := Rules.stars_text(float(a["rating"])).split(" ")[0] + " " + Rules.num(float(a["rating"]), 2)
	var stars_en := Rules.stars_text(float(a["rating"])).split(" ")[0] + " " + Rules.num(float(a["rating"]), 2, false)
	var earned := fmt("v_zl", [int(a["earned"])])
	it["sub"] = ["%s · %s" % [earned[0], stars], "%s · %s" % [earned[1], stars_en]]
	it["facts"] = [[words("f_earned"), earned],
			[words("f_avg_fare"), fmt("v_zl", [int(a["average"])])],
			[words("f_rating"), [stars, stars_en]],
			[words("f_rides"), fmt("v_times", [int(a["rides"])])],
			[words("f_best_ride"), fmt("v_zl", [int(a["best"])])],
			[words("f_streak"), fmt("v_times", [int(a["streak"])])],
			[words("f_best_streak"), fmt("v_times", [int(a["best_streak"])])]]
	return [it]


## The Six as ladder.gd's chips say (won, open, locked) and the final's line.
static func _rivals(chips: Array, final: Array, night: bool, entries: Array, car: Vector2) -> Array:
	var out: Array = []
	for c: Dictionary in chips:
		var i := int(c["rung"])
		if i < 0 or i >= Ladder.RUNGS.size():
			continue
		var r: Dictionary = Ladder.RUNGS[i]
		var who := str(r["rival"])
		var state := str(c.get("state", "locked"))
		var it := _item("rival_%d" % i, "rivals", [who, who], RIVAL_COLOUR, "rivals")
		it["who"] = who
		var den := Ladder.den(i)
		it["about"] = fmt("rival_about", [who, [str(den[1]), str(den[2])]])
		var st: Array = words("v_rival_" + state)
		it["done"] = state == "won"
		var zl := fmt("v_zl", [int(r["stake"])])
		it["sub"] = ["%s · %s · %s" % [st[0], Ladder.pip_text(i), zl[0]], "%s · %s · %s" % [st[1], Ladder.pip_text(i), zl[1]]]
		it["facts"] = [[words("f_stake"), zl], [words("f_skill"), [Ladder.pip_text(i), Ladder.pip_text(i)]],
				[words("f_turf"), [str(den[1]), str(den[2])]], [words("f_done"), st]]
		if state != "locked":
			var e := Lines.entry("rival_%d" % i, "rival", Lines.Line.CAR, who, who, Vector2.INF, RIVAL_COLOUR, Lines.RIVAL_CALL)
			e["rung"] = i
			it["buttons"] = [{"key": "race", "words": fmt("b_race", [[str(r["short"]), str(r["short"])]]), "entry": e, "gold": state != "won"}]
		out.append(it)
	if final.size() == 2:
		var it := _item("final", "rivals", words("final"), Color("#8fa8ff"), "final")
		it["who"] = "Seba"
		it["about"] = words("final_about")
		it["sub"] = [str(final[0]), str(final[0])]
		it["done"] = str(final[1]) == "won"
		it["facts"] = [[words("f_stake"), fmt("v_zl", [Ladder.FINAL_ZL])]]
		for e: Dictionary in entries:
			if str(e["group"]) == "final" and e.get("at", Vector2.INF) != Vector2.INF:
				it["at"] = e["at"]
				it["facts"].append([words("f_where"), _far(car, e["at"])])
				it["buttons"].append({"key": "map", "words": words("b_map"), "entry": e, "gold": true})
		if night:
			var n := Lines.entry("night", "night", Lines.Line.CAR, "", "", Vector2.INF, Color("#8fa8ff"), Lines.NIGHT)
			it["buttons"].append({"key": "start", "words": words("b_night"), "entry": n, "gold": it["buttons"].is_empty()})
		out.append(it)
	return out


## Districts, Syrenki, tapes and places found: one entry each (the districts' one lists them all).
static func _collection(f: Dictionary) -> Array:
	var out: Array = []
	var ds: Array = f.get("districts", [])
	if not ds.is_empty():
		var it := _item("col_districts", "collection", words("col_districts"), COLLECTION_COLOUR, "districts")
		it["about"] = words("col_districts_about")
		it["sub"] = ["%d%%" % int(f.get("total", 0)), "%d%%" % int(f.get("total", 0))]
		for d: Dictionary in ds:
			var v := ["%d%%" % int(d["pct"]), "%d%%" % int(d["pct"])] if bool(d["found"]) else ["?", "?"]
			it["facts"].append([[str(d["name_pl"]), str(d["name_en"])], v])
		out.append(it)
	for key: String in ["syrenki", "tapes", "places"]:
		var n: Array = f.get(key, [])
		if n.size() != 2 or int(n[1]) <= 0:
			continue
		var it := _item("col_" + key, "collection", words("col_" + key), COLLECTION_COLOUR, key)
		it["about"] = words("col_%s_about" % key)
		var v := fmt("v_found", [int(n[0]), int(n[1])])
		it["sub"] = v
		it["done"] = int(n[0]) >= int(n[1])
		it["facts"] = [[words("f_found"), v]]
		# Settings redesign step 2 (F 2026-11-23): the notebook (MOJA WARSZAWA) left the settings tabs;
		# its places and tapes open it from here (full_map.gd `notebook`, at the tapes' chapter).
		if key != "syrenki":
			it["buttons"].append({"key": "notebook", "words": words("b_notebook"), "gold": true,
					"entry": {"id": "col_" + key, "target": "tape" if key == "tapes" else ""}})
		out.append(it)
	return out
