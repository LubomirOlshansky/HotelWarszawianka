extends SceneTree
## The main line (main_line.gd, docs/design/main-line.md): its step from the facts, without the map.
## Checks that:
## - during the guide the guide's target or arrow is the main line (chapter 1) and with neither the
##   step says "just drive" with no marker;
## - after the guide: a race for the next rung is the main line's target; an open rung points at its
##   rival's dot; a locked one asks for respect with no marker (the side quests are the way);
## - the final: respect first, then "at night" with no marker by day, the start by night, its race
##   in chapter 3; then the jobs left to the end card (Polish plurals), then done (no line);
## - every line is Polish and English, at most MAX_CHARS characters (the full map's goal card);
## - the pacing (the retune of 2026-10-31): race wins alone stop at rung 2, and the side quests'
##   respect the ladder needs in all (the final's threshold less six wins) is SIDE_MIN-SIDE_MAX;
## - the nudge on the driving screen (main_nudge.gd): the guide's end brings the goal line after
##   TOAST_DELAY s and the gold arrow for SHOW s, both only while free and not quiet; busy pauses
##   the arrow; it comes back after GAP s of free driving; a step with no place gives the goal line
##   and no arrow; "done" gives neither;
## - the gate (F 2026-11-08, main_line.gd FIRST_JOB_ONLY): `now` is the guide's step until the
##   first job is done, then "done" (no star, no line), and "done" with no guide at all.
##   godot --headless --path game --script res://tools/check_main_line.gd

const MainLine := preload("res://scripts/main_line.gd")
const MainNudge := preload("res://scripts/main_nudge.gd")
const Ladder := preload("res://scripts/ladder.gd")
const MAX_CHARS := 60
const SIDE_MIN := 150
const SIDE_MAX := 300

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _words(st: Dictionary) -> void:
	for k in ["pl", "en"]:
		var t := str(st[k])
		_expect(t.length() <= MAX_CHARS, "%s line too long (%d): %s" % [k, t.length(), t])
	_expect((str(st["pl"]) == "") == (str(st["en"]) == ""), "a line in one language only: %s" % [st])


func _step(f: Dictionary) -> Dictionary:
	var st := MainLine.step(f)
	_words(st)
	return st


func _check_gate(here: Vector2) -> void:
	var st := MainLine.now({"guide": true, "jobs": 0, "target": here, "target_main": true})
	_expect(st["id"] == "guide_target" and st["at"] == here, "gate: the first kebab is the main line: %s" % [st])
	st = MainLine.now({"guide": true, "jobs": 0, "guide_at": here, "guide_word": "KEBAB"})
	_expect(st["id"] == "guide_kebab", "gate: the guide's arrow before the first job: %s" % [st])
	if MainLine.FIRST_JOB_ONLY:
		st = MainLine.now({"guide": true, "jobs": 1, "target": here, "target_main": true})
		_expect(st["id"] == "done" and st["at"] == Vector2.INF and st["pl"] == "", "gate: after the first job: %s" % [st])
		st = MainLine.now({"next": 1, "open": true, "rival": "Pani Halina", "rival_at": here, "jobs": 3})
		_expect(st["id"] == "done" and st["at"] == Vector2.INF, "gate: the ladder's rival is off: %s" % [st])
		st = MainLine.now({"guide": false, "jobs": 0})
		_expect(st["id"] == "done", "gate: no guide, no main line: %s" % [st])


func _initialize() -> void:
	var here := Vector2(10, 20)
	# Chapter 1: the guide.
	var st := _step({"guide": true, "target": here, "target_main": true})
	_expect(st["id"] == "guide_target" and st["chapter"] == 1 and st["at"] == here, "guide target: %s" % [st])
	st = _step({"guide": true, "guide_at": here, "guide_word": "KEBAB"})
	_expect(st["id"] == "guide_kebab" and st["at"] == here and str(st["pl"]).contains("KEBAB"), "guide arrow: %s" % [st])
	st = _step({"guide": true})
	_expect(st["id"] == "guide" and st["at"] == Vector2.INF, "guide idle: %s" % [st])
	# A side job during the guide is not passed as main by main.gd: target_main false.
	st = _step({"guide": true, "target": here, "target_main": false})
	_expect(st["id"] == "guide" and st["at"] == Vector2.INF, "guide with a side target: %s" % [st])
	# Chapter 2: the ladder.
	var rival := Vector2(-300, 50)
	st = _step({"next": 1, "open": true, "rival": "Słoik z Radomia", "rival_at": rival})
	_expect(st["id"] == "rival" and st["chapter"] == 2 and st["at"] == rival and str(st["en"]).contains("Słoik"), "open rung: %s" % [st])
	st = _step({"next": 2, "open": false, "respect": 180, "need": 220, "rival": "Bulwar Bartek", "rival_at": rival})
	_expect(st["id"] == "respect" and st["at"] == Vector2.INF and str(st["pl"]).contains("180/220"), "locked rung: %s" % [st])
	st = _step({"next": 2, "open": true, "rival": "Bulwar Bartek", "target": here, "target_main": true})
	_expect(st["id"] == "race" and st["at"] == here, "next rung's race: %s" % [st])
	st = _step({"next": 2, "open": true, "rival": "Bulwar Bartek", "rival_at": rival, "target": here, "target_main": false})
	_expect(st["id"] == "rival" and st["at"] == rival, "a side target keeps the rival's marker: %s" % [st])
	# Chapter 3: the final.
	st = _step({"next": Ladder.FINAL, "open": false, "respect": 700, "need": Ladder.FINAL_RESPECT})
	_expect(st["id"] == "respect" and st["chapter"] == 3 and st["at"] == Vector2.INF, "final locked: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": false, "final_at": here})
	_expect(st["id"] == "wait_night" and st["at"] == Vector2.INF, "final by day: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": true, "final_at": here})
	_expect(st["id"] == "final" and st["at"] == here, "final by night: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": true, "target": rival, "target_main": true})
	_expect(st["id"] == "final_race" and st["at"] == rival, "final race: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 7, "end_jobs": 10})
	_expect(st["id"] == "jobs" and str(st["pl"]).contains("3 zlecenia") and str(st["en"]).contains("3 more jobs"), "jobs left: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 9, "end_jobs": 10})
	_expect(str(st["pl"]).contains("1 zlecenie") and str(st["en"]).contains("1 more job "), "one job left: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 12, "end_jobs": 10, "end_seen": true})
	_expect(st["id"] == "done" and st["pl"] == "" and st["at"] == Vector2.INF, "done: %s" % [st])
	for n: int in [1, 2, 4, 5, 12, 13, 22, 25]:
		var want := "zlecenie" if n == 1 else ("zlecenia" if n in [2, 4, 22] else "zleceń")
		_expect(MainLine.jobs_word(n) == want, "jobs_word(%d) = %s" % [n, MainLine.jobs_word(n)])
	# The pacing: wins alone (+100 each) open rungs 0 and 1 only.
	var respect := 0
	var stuck := -1
	for i in Ladder.RUNGS.size():
		if respect < Ladder.threshold(i):
			stuck = i
			break
		respect += 100
	_expect(stuck == 2, "race wins alone stop at rung %d (want 2)" % stuck)
	var side := Ladder.FINAL_RESPECT - 100 * Ladder.RUNGS.size()
	_expect(side >= SIDE_MIN and side <= SIDE_MAX, "side quests' respect to the final: %d (want %d-%d)" % [side, SIDE_MIN, SIDE_MAX])
	_check_nudge()
	_check_gate(here)
	if _problems == 0:
		print("main_line: OK (side respect to the final %d)" % side)
		quit(0)
	else:
		print("main_line: %d problems" % _problems)
		quit(1)


## Runs the nudge for `seconds` in 0.25 s looks; returns [toasts, seconds with the arrow].
func _run(n: MainNudge, step: Dictionary, seconds: float, free := true, quiet := false) -> Array:
	var toasts := 0
	var arrow := 0.0
	var t := 0.0
	while t < seconds - 0.001:
		var o := n.tick(0.25, step, free, quiet)
		toasts += 1 if o["toast"] else 0
		arrow += 0.25 if o["arrow"] else 0.0
		t += 0.25
	return [toasts, arrow]


func _check_nudge() -> void:
	var guide := MainLine.step({"guide": true})
	var rival := MainLine.step({"next": 1, "open": true, "rival": "Słoik z Radomia", "rival_at": Vector2(-300, 50)})
	var locked := MainLine.step({"next": 2, "open": false, "respect": 180, "need": 220, "rival": "Bulwar Bartek"})
	var done := MainLine.step({"next": Ladder.FINAL + 1, "end_seen": true})
	var n := MainNudge.new()
	var r := _run(n, guide, 60.0)
	_expect(r[0] == 0 and r[1] == 0.0, "the guide's own steps get no nudge: %s" % [r])
	# The guide ends: the goal line after TOAST_DELAY, the arrow for SHOW.
	r = _run(n, rival, MainNudge.TOAST_DELAY - 0.5)
	_expect(r[0] == 0, "goal line waits %.0f s: %s" % [MainNudge.TOAST_DELAY, r])
	r = _run(n, rival, 1.0)
	_expect(r[0] == 1, "goal line after the delay: %s" % [r])
	var rest := MainNudge.SHOW - MainNudge.TOAST_DELAY - 0.5
	r = _run(n, rival, rest)
	_expect(r[0] == 0 and absf(r[1] - rest) < 0.3 and n.show_left() < 0.01, "arrow for SHOW s in all: %s" % [r])
	r = _run(n, rival, MainNudge.GAP - 2.0)
	_expect(r[1] == 0.0, "no arrow between nudges: %s" % [r])
	r = _run(n, rival, 30.0, false)
	_expect(r[1] == 0.0, "busy: no arrow: %s" % [r])
	r = _run(n, rival, MainNudge.GAP - 2.0)
	_expect(r[1] == 0.0, "busy restarts the free count: %s" % [r])
	r = _run(n, rival, 4.0)
	_expect(r[1] > 0.0, "the arrow comes back after GAP s free: %s" % [r])
	# A busy player keeps the step change's nudge until free; quiet holds it too.
	n = MainNudge.new()
	r = _run(n, rival, 40.0, false)
	_expect(r[0] == 0 and r[1] == 0.0, "busy at the change: held: %s" % [r])
	r = _run(n, rival, 40.0, true, true)
	_expect(r[0] == 0 and r[1] == 0.0, "quiet: held: %s" % [r])
	r = _run(n, rival, MainNudge.SHOW + 5.0)
	_expect(r[0] == 1 and r[1] >= MainNudge.SHOW - 0.3, "free again: line and arrow: %s" % [r])
	# No place: the line only; done: nothing.
	r = _run(n, locked, MainNudge.GAP * 2.0)
	_expect(r[0] == 1 and r[1] == 0.0, "respect step: line, no arrow: %s" % [r])
	r = _run(n, done, MainNudge.GAP * 2.0)
	_expect(r[0] == 0 and r[1] == 0.0, "done: nothing: %s" % [r])
