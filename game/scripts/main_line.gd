extends RefCounted
## The main line (docs/design/main-line.md, F's ask 2026-10-31): the one story thread through the
## demo, told apart from the side quests on the minimap and the full map. Chapter 1 is the first
## ten minutes (first10.gd's guide: everything it points at is the main line); chapter 2 is the
## rival ladder (ladder.gd: the next rung's rival, wherever they cruise); chapter 3 is the final
## "Trzy mosty" at night and the end card (END_JOBS jobs). After the end card the main line is done
## and only the side quests show.
##
## `step` is a pure function of the facts (main.gd gathers them at STEP_EVERY), so
## check_main_line.gd tests it without the map. Its result: {id, chapter, pl, en, at} where `at` is
## the main-line marker's map point (x, z), INF when this step has no place (earn respect, wait for
## night, finish jobs: the side quests are the way then).

## Seconds between two looks at the main line's step (main.gd; the rival's dot moves a few metres).
const STEP_EVERY := 0.25
## The main line's gold (first10.gd HINT_COLOUR, the final's beacon is the same family).
const COLOUR := Color("#ffd23f")
## The marker's dark rim (hud.gd OUTLINE's family, a touch warmer so the star reads on the water).
const RIM := Color("#2a1d05")

const Ladder := preload("res://scripts/ladder.gd")

## F (2026-11-08): "for now the main line is only the first task, the kebab". After the first job
## (or with no guide on this save) the star, the goal card and the nudge stay off, so they never
## point away from a quest the player took. The chapters below stay written (`step`); `now` gates
## them. Back on: false here, and `now` returns `step` again.
const FIRST_JOB_ONLY := true


## The facts `step` reads (main.gd fills them; a check passes its own):
## - guide (bool): the first-ten-minutes guide is running; guide_at (Vector2, INF: no arrow) and
##   guide_word (String): its arrow;
## - target (Vector2, INF: none) and target_main (bool): the active target and whether it belongs to
##   the main line (anything during the guide; a race for the next rung; the final);
## - next (int): ladder.next_rung(); open (bool): that rung is open; respect, need (int): the
##   wallet's respect and the rung's threshold; rival (String): the rung's rival; rival_at
##   (Vector2, INF: not on the map);
## - night (bool); final_at (Vector2, INF: not shown yet: the start marker is on at night only);
## - jobs (int): jobs done; end_jobs (int); end_seen (bool): the end card was shown.
static func step(f: Dictionary) -> Dictionary:
	var target: Vector2 = f.get("target", Vector2.INF)
	if bool(f.get("guide", false)):
		if bool(f.get("target_main", false)) and target != Vector2.INF:
			return _out("guide_target", 1, "Pierwsze kroki", "First steps", target)
		var word := str(f.get("guide_word", ""))
		var at: Vector2 = f.get("guide_at", Vector2.INF)
		if at != Vector2.INF:
			return _out("guide_" + word.to_lower(), 1, "Pierwsze kroki: %s" % word, "First steps: %s" % word, at)
		return _out("guide", 1, "Jeździj: miasto samo cię znajdzie", "Just drive: the city finds you", Vector2.INF)
	var nxt := int(f.get("next", 0))
	if bool(f.get("target_main", false)) and target != Vector2.INF:
		if nxt >= Ladder.FINAL:
			return _out("final_race", 3, "Finał: Trzy mosty", "The final: Three bridges", target)
		return _out("race", 2, "Wyścig: %s" % f.get("rival", ""), "Race: %s" % f.get("rival", ""), target)
	if nxt < Ladder.FINAL:
		var rival := str(f.get("rival", ""))
		if not bool(f.get("open", false)):
			return _out("respect", 2, "Zdobądź szacunek: %d/%d, potem %s" % [int(f.get("respect", 0)), int(f.get("need", 0)), rival],
					"Earn respect: %d/%d, then %s" % [int(f.get("respect", 0)), int(f.get("need", 0)), rival], Vector2.INF)
		return _out("rival", 2, "Znajdź i mrugnij: %s" % rival, "Find and flash: %s" % rival, f.get("rival_at", Vector2.INF))
	if nxt == Ladder.FINAL:
		if not bool(f.get("open", false)):
			return _out("respect", 3, "Zdobądź szacunek: %d/%d, potem finał" % [int(f.get("respect", 0)), int(f.get("need", 0))],
					"Earn respect: %d/%d, then the final" % [int(f.get("respect", 0)), int(f.get("need", 0))], Vector2.INF)
		if not bool(f.get("night", false)):
			return _out("wait_night", 3, "Finał w nocy: Rondo Daszyńskiego", "The final is at night: Rondo Daszyńskiego", Vector2.INF)
		return _out("final", 3, "Finał: Seba czeka na Rondzie Daszyńskiego", "The final: Seba waits at Rondo Daszyńskiego",
				f.get("final_at", Vector2.INF))
	if bool(f.get("end_seen", false)):
		return _out("done", 3, "", "", Vector2.INF)
	var left := maxi(1, int(f.get("end_jobs", 10)) - int(f.get("jobs", 0)))
	return _out("jobs", 3, "Jeszcze %d %s do końca dema" % [left, jobs_word(left)],
			"%d more %s to the demo's end" % [left, "job" if left == 1 else "jobs"], Vector2.INF)


## The main line as the game shows it: `step` while FIRST_JOB_ONLY lets it through (the guide is
## on and no job is done yet: f.jobs), else "done" (no star, no goal line, no nudge).
static func now(f: Dictionary) -> Dictionary:
	if FIRST_JOB_ONLY and (not bool(f.get("guide", false)) or int(f.get("jobs", 0)) >= 1):
		return _out("done", 1, "", "", Vector2.INF)
	return step(f)


## Polish "zlecenie" for `n`: 1 zlecenie, 2-4 zlecenia (not 12-14), else zleceń.
static func jobs_word(n: int) -> String:
	if n == 1:
		return "zlecenie"
	if n % 10 in [2, 3, 4] and not (n % 100 in [12, 13, 14]):
		return "zlecenia"
	return "zleceń"


static func _out(id: String, chapter: int, pl: String, en: String, at: Vector2) -> Dictionary:
	return {"id": id, "chapter": chapter, "pl": pl, "en": en, "at": at}
