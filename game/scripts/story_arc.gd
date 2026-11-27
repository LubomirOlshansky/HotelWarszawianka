extends RefCounted
## The story, "Doba w Warszawie · 24 hours in Warsaw" (F 2026-11-26: "make the story from those 5
## quests ... separate from the garage and the bar, the side jobs to grind, the racing with rivals;
## First steps just bonuses"). The design: docs/design/story-structure.md. Six chapters, one game
## day, one vehicle each, in data/story_arc.json's order: Tajny klient (Kebabulo, noon), Padel na
## Desce (Kuba), Stanęło TESŁO (Bartek, dusk), Nocny spot (Darek, night), Smoła (Mati, late night;
## F 2026-11-27: "a strong quest"), Wiślana Szprotka
## (Szymek, dawn).
##
## Gates are calls, never doors: every chapter can be played at any time from QUESTS or its spot,
## in any order; the order only says which friend rings next and where the gold star points
## (later phases). Losing still finishes a chapter (silver); winning makes it gold.
##
## Pure (no nodes): it reads the save's facts (wallet.gd `intro` and `jobs`), so
## game/tools/check_story_arc.gd tests it with made-up saves.
## - done: `qdone_<id>` (quest_book.gd DONE_KEY, set by activity.gd `finish` since 2026-11-25);
##   older saves: the chapter's `old_job` count in `jobs`. Chapter 1 (the Tajny klient opening):
##   its own stage 3 (tajny_klient.gd STAGE_KEY), or, on a save that never saw it (stage 0: an
##   older save, or the opening off), the old guide's end (`intro.done`) or any job done.
## - gold: `qgold_<id>` (written by the chapter's result, phase 3).
## - seen: `qseen_<id>`, so a chapter found done on an old save is counted once, quietly.

const DATA_PATH := "res://data/story_arc.json"
const DONE_KEY := "qdone_"
const GOLD_KEY := "qgold_"
const SEEN_KEY := "qseen_"
## tajny_klient.gd STAGE_KEY and its Saved.DONE (not preloaded: that script is a node with a map).
const TAJNY_KEY := "tajny"
const TAJNY_DONE := 3

static var _data: Dictionary = {}


## data/story_arc.json, read once ({} when missing).
static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if d is Dictionary:
			_data = d
	return _data


## The chapters in order: [{id, title, friend, hour, vehicle, old_job}, ...].
static func chapters() -> Array:
	return data().get("chapters", [])


## The chapters' ids in order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for c: Dictionary in chapters():
		out.append(str(c["id"]))
	return out


## Chapter `id`'s row ({} for an id that is not a chapter).
static func chapter(id: String) -> Dictionary:
	for c: Dictionary in chapters():
		if str(c["id"]) == id:
			return c
	return {}


## Its number from 1 (0 when `id` is not a chapter).
static func number(id: String) -> int:
	return ids().find(id) + 1


## The chapter's story hour (the hour DALEJ jumps to; -1 for an id that is not a chapter).
static func hour(id: String) -> float:
	var c := chapter(id)
	return float(c["hour"]) if not c.is_empty() else -1.0


## Chapter `id` was played to its end, from the save's facts (`intro`, `jobs`: wallet.gd's).
static func is_done(id: String, intro: Dictionary, jobs: Dictionary) -> bool:
	if intro.has(DONE_KEY + id):
		return true
	if id == TAJNY_KEY:
		var stage := int(intro.get(TAJNY_KEY, 0))
		if stage >= TAJNY_DONE:
			return true
		return stage == 0 and (intro.has("done") or _jobs_total(jobs) > 0)
	var old := str(chapter(id).get("old_job", ""))
	return old != "" and int(jobs.get(old, 0)) > 0


## Won, not only finished (gold); a finish without it is silver.
static func is_gold(id: String, intro: Dictionary) -> bool:
	return intro.has(GOLD_KEY + id)


## How many chapters are done.
static func done_count(intro: Dictionary, jobs: Dictionary) -> int:
	var n := 0
	for id in ids():
		if is_done(id, intro, jobs):
			n += 1
	return n


## The first chapter in order not done yet ("" when all six are).
static func next_id(intro: Dictionary, jobs: Dictionary) -> String:
	for id in ids():
		if not is_done(id, intro, jobs):
			return id
	return ""


## The rows a screen shows: [{id, n, title, friend, hour, done, gold, next}, ...] in order.
static func rows(intro: Dictionary, jobs: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var nxt := next_id(intro, jobs)
	for c: Dictionary in chapters():
		var id := str(c["id"])
		out.append({"id": id, "n": number(id), "title": c["title"], "friend": c["friend"], "hour": float(c["hour"]),
				"done": is_done(id, intro, jobs), "gold": is_gold(id, intro), "next": id == nxt})
	return out


## Chapters done but not counted yet (an old save's, or one just finished): marks them seen in
## `intro` and returns their ids, so a caller logs or toasts each once.
static func newly_done(intro: Dictionary, jobs: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for id in ids():
		if is_done(id, intro, jobs) and not intro.has(SEEN_KEY + id):
			intro[SEEN_KEY + id] = 1
			out.append(id)
	return out


## "DOBA W WARSZAWIE 2/5" in [pl, en].
static func header(intro: Dictionary, jobs: Dictionary) -> Array:
	var t: Array = data().get("title", ["DOBA W WARSZAWIE", "24 HOURS IN WARSAW"])
	var n := done_count(intro, jobs)
	var of := chapters().size()
	return ["%s %d/%d" % [t[0], n, of], "%s %d/%d" % [t[1], n, of]]


## Every job counted in `jobs` (wallet.gd's kinds), for chapter 1 on a save that never saw it.
static func _jobs_total(jobs: Dictionary) -> int:
	var n := 0
	for k: Variant in jobs:
		n += int(jobs[k])
	return n
