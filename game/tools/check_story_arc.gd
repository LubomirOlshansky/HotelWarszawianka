extends SceneTree
## The story "Doba w Warszawie" (story_arc.gd, F 2026-11-26), pure: made-up saves in, chapters out,
## no map, no game. Checks that:
## - data/story_arc.json has the six chapters in F's order (tajny, padel, tesla, meet, smola, boat), each
##   with a title and a friend in both languages and a story hour in 0-24;
## - a fresh save has nothing done and chapter 1 next; `qdone_` marks finish a chapter; played out
##   of order, `next_id` is the first one not done; all six done: no next, header 6/6;
## - chapter 1: the Tajny klient stage 3 finishes it; stage 1 or 2 (under way) does not, even with a
##   job done; a save that never saw it (stage 0) counts the old guide's end or any job;
## - an old save (before qdone_) counts the night meet and the boat by their job counts, never the
##   TESŁO (strangers' tows count there too), padel (paid as "trend") or Smoła (paid as "rave");
## - gold only with `qgold_`; `newly_done` returns each done chapter once and marks it seen;
## - the rows carry the next flag on one chapter only;
## - every chapter but "tajny" is a story_quests.gd questline id (main.gd `stories.add`), the id its
##   finish marks `qdone_` with.
##   godot --headless --path game --script res://tools/check_story_arc.gd

const StoryArc := preload("res://scripts/story_arc.gd")

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	var ids := StoryArc.ids()
	_expect(Array(ids) == ["tajny", "padel", "tesla", "meet", "smola", "boat"], "the chapters are %s, not F's six in order" % ids)
	for c: Dictionary in StoryArc.chapters():
		for k: String in ["title", "friend"]:
			var v: Variant = c.get(k)
			_expect(v is Array and (v as Array).size() == 2 and str(v[0]) != "" and str(v[1]) != "", "%s has no %s in both languages" % [c.get("id"), k])
		var h := float(c.get("hour", -1.0))
		_expect(h >= 0.0 and h < 24.0, "%s's story hour %.1f is not in 0-24" % [c.get("id"), h])
	# Every chapter but the opening is a questline of story_quests.gd (main.gd `stories.add`), so its
	# finish (activity.gd `finish` -> QuestBook.mark_done) writes `qdone_<the same id>`.
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var re := RegEx.create_from_string("stories\\.add\\(\\{\"id\": \"([a-z_]+)\"")
	var defs := re.search_all(main_src).map(func(m: RegExMatch) -> String: return m.get_string(1))
	for id in ids:
		_expect(id == StoryArc.TAJNY_KEY or id in defs, "chapter %s is not a questline id in main.gd's stories.add (%s)" % [id, defs])
	_expect(StoryArc.number("meet") == 4 and StoryArc.number("x") == 0, "chapter numbers")
	_expect(is_equal_approx(StoryArc.hour("boat"), 6.5) and StoryArc.hour("x") < 0.0, "story hours")

	# A fresh save.
	var intro := {}
	var jobs := {}
	_expect(StoryArc.done_count(intro, jobs) == 0 and StoryArc.next_id(intro, jobs) == "tajny", "a fresh save is not at chapter 1")
	# Chapter 1 under way: not done, even with a job paid on the way.
	intro["tajny"] = 2
	jobs["kebab"] = 1
	_expect(not StoryArc.is_done("tajny", intro, jobs), "the Tajny klient under way (stage 2) counts as done")
	intro["tajny"] = 3
	_expect(StoryArc.is_done("tajny", intro, jobs) and StoryArc.next_id(intro, jobs) == "padel", "stage 3 does not finish chapter 1")
	# A save that never saw the opening: the old guide's end, or any job.
	_expect(StoryArc.is_done("tajny", {"done": 1}, {}), "the old guide's end does not count chapter 1")
	_expect(StoryArc.is_done("tajny", {}, {"podwozka": 2}), "a job on an old save does not count chapter 1")
	_expect(not StoryArc.is_done("tajny", {}, {}), "an empty old save counts chapter 1")

	# Out of order: the boat first, then the next is still padel.
	intro["qdone_boat"] = 1
	_expect(StoryArc.is_done("boat", intro, jobs) and StoryArc.next_id(intro, jobs) == "padel", "a chapter played out of order moved the next one")
	_expect(StoryArc.done_count(intro, jobs) == 2, "two chapters done counted %d" % StoryArc.done_count(intro, jobs))
	var rows := StoryArc.rows(intro, jobs)
	var nexts := rows.filter(func(r: Dictionary) -> bool: return bool(r["next"]))
	_expect(rows.size() == 6 and nexts.size() == 1 and str(nexts[0]["id"]) == "padel", "the rows' next flag")

	# Old saves: job counts for the meet and the boat, never for TESŁO, padel or Smoła.
	var old := {"meet_race": 1, "ev_tow": 3, "trend": 4, "rave": 2}
	_expect(StoryArc.is_done("meet", {}, old), "an old save's night race does not count the night meet")
	_expect(not StoryArc.is_done("tesla", {}, old), "a stranger's tow counts the TESŁO chapter")
	_expect(not StoryArc.is_done("padel", {}, old), "a trend job counts padel")
	_expect(not StoryArc.is_done("smola", {}, old), "a secret rave counts Smoła")

	# Gold and the quiet count.
	_expect(not StoryArc.is_gold("boat", intro), "a finish without a win is gold")
	intro["qgold_boat"] = 1
	_expect(StoryArc.is_gold("boat", intro), "a win is not gold")
	var first := StoryArc.newly_done(intro, jobs)
	_expect(Array(first) == ["tajny", "boat"], "newly done gave %s" % first)
	_expect(StoryArc.newly_done(intro, jobs).is_empty(), "newly done gave a chapter twice")

	# All six.
	for id in ids:
		intro["qdone_" + id] = 1
	_expect(StoryArc.next_id(intro, jobs) == "" and StoryArc.header(intro, jobs)[0] == "DOBA W WARSZAWIE 6/6", "all six done: %s" % [StoryArc.header(intro, jobs)])

	if _problems == 0:
		print("check_story_arc: OK (%d chapters: %s)" % [ids.size(), ", ".join(ids)])
	else:
		print("check_story_arc: %d problems" % _problems)
	quit(1 if _problems > 0 else 0)
