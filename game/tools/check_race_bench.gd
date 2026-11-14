extends SceneTree
## The race bench's check (docs/design/race-ai.md, "How we test it"; F 2026-11-09: "racing is the
## big part of the app ... build something progressive and reliable"). Headless, from the committed
## map (map/centrum.json), seeded, no city: runs a matrix of races with tools/race_bench.gd (the
## real traffic and the game's own race code), prints one line a race and the pass marks, and
## holds the marks against the ones recorded for its matrix in data/race_bench.json:
##   - a mark recorded "pass" that fails is a problem (exit 1): a change made the racers worse;
##   - a mark recorded "fail" that passes prints "racebench: WARN ..." (verify.sh shows WARN):
##     record the win with tools/race_bench.sh --write in the same change;
##   - a mark recorded "fail" that fails is the known state of the rebuild, listed in the OK line;
##   - a mark recorded "once:<machine>" passed on that machine only and is not held yet. A mark
##     that counts races among the town's cars is recorded "pass" only when it has passed on two
##     machines (Linux and macOS: a race in traffic is another draw of the town's cars on each,
##     docs/design/race-ai.md 7.5): `--write` on the first records "once:Linux", `--write` on the
##     other turns that into "pass", and a fail on either puts it back to "fail";
##   - a mark recorded "unsteady" is not held either way: it passes with one draw of the town's
##     cars and fails with the next, and the step that fixes it has not been built (the quick
##     matrix's Passes traffic: 8.3 s or 2.2 s behind a slower car with the same driver). It is set
##     by hand in data/race_bench.json, `--write` leaves it, and the step that owns the mark
##     records it as a pass when it passes with room to spare.
## The quick matrix (the default: the prototype race Powiśle -> Plac Trzech Krzyży with Pani
## Halina, under a minute) is what tools/verify.sh and CI run; `--full` adds the second start, the
## guided first race under every situation, two more draws of the traffic, all six rivals, and
## the first race to the Palace, a finish whose circle another road runs through (a few minutes;
## tools/race_bench.sh).
##   godot --headless --path game --script res://tools/check_race_bench.gd [-- OPTIONS]
##   --full          the full matrix          --only=TEXT   only races whose id contains TEXT
##   --trace         once a second, what the rival does (use with --only)
##   --json=PATH     write every race's numbers to PATH (a file outside the repo's tracked data)
##   --against=PATH  show an earlier run's numbers (its --json file) beside this run's
##   --write         record this run's marks (its matrix's) in data/race_bench.json
##   --list          print the races' ids and quit
##   --part=K/N      run only every Nth race of the matrix, from the Kth (0 to N-1): its races go to
##                   --json and no mark is judged (tools/race_bench.sh --jobs=N runs the N parts
##                   side by side)
##   --merge=A,B,..  run no race: judge the races of these --part files together, as one run
## With Godot's own --verbose (before the --) every car driven through is printed where it happens.
## Prints "check_race_bench: OK (...)" or the problems (exit 1).

const RaceBench := preload("res://tools/race_bench.gd")
const BASELINE := "res://data/race_bench.json"
const HALINA := "Pani Halina"
const SEBA := "Seba z Pragi"
## The full matrix's other draws of the town's cars (a spec's `seed`), beside each race's own.
const DRAWS := [3, 4]

var _bench: RaceBench
var _results: Array = []
var _by_id := {}
var _problems: Array[String] = []
## Races that did not run to their end (a script error): a problem, never an OK.
var _broken := 0
## --against: the earlier run's races and marks by id.
var _before := {}
var _before_marks := {}
## --merge: the seconds the parts' races took, added up.
var _merged_secs := 0.0


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var full := "--full" in args
	var only := ""
	var json_path := ""
	var part := -1
	var parts := 1
	var merge := PackedStringArray()
	for a in args:
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--json="):
			json_path = a.trim_prefix("--json=")
		elif a.begins_with("--part="):
			part = int(a.trim_prefix("--part=").get_slice("/", 0))
			parts = maxi(int(a.trim_prefix("--part=").get_slice("/", 1)), 1)
		elif a.begins_with("--merge="):
			merge = a.trim_prefix("--merge=").split(",", false)
		elif a.begins_with("--against="):
			_load_before(a.trim_prefix("--against="))
	_bench = RaceBench.new()
	if not _bench.open(root):
		print("check_race_bench: %s" % _bench.error)
		quit(1)
		return
	var specs := _matrix(full)
	for k in specs.size():
		specs[k]["n"] = k
	if only != "":
		specs = specs.filter(func(s: Dictionary) -> bool: return RaceBench.race_id(s).contains(only))
	if part >= 0:
		specs = specs.filter(func(s: Dictionary) -> bool: return int(s["n"]) % parts == part)
	if "--list" in args:
		for s: Dictionary in specs:
			print(RaceBench.race_id(s))
		_bench.close()
		quit(0)
		return
	if specs.is_empty():
		print("check_race_bench: no race's id contains '%s' (--list prints the ids)" % only)
		_bench.close()
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	if merge.is_empty():
		for s: Dictionary in specs:
			s["trace"] = "--trace" in args
			if not _race(s):
				_broken += 1
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	if not merge.is_empty():
		# (The parts' own seconds, added up: what the races took, not the wait for them.)
		secs = 0.0
		_broken = specs.size() - _merge(merge)
		secs = _merged_secs
	_bench.close()
	if part >= 0:
		# A part of a run: its races only (the marks are judged over all the parts, --merge).
		if json_path != "":
			_write_json(json_path, {"part": part, "seconds": secs, "races": _results})
		print("check_race_bench: part %d of %d, %d races in %.0f s%s" % [part, parts, _results.size(), secs, ", %d did not run" % _broken if _broken > 0 else ""])
		quit(1 if _broken > 0 else 0)
		return
	for c in root.get_children():
		c.queue_free()
	await process_frame
	# Every race of the matrix has to have run. (Found on the Mac, 2026-11-09: on a clone Godot had
	# never imported, the game's scripts did not load, no race ran, and this check said OK.)
	if _broken > 0:
		_problems.append("%d of %d races did not run (a script error above? a clone Godot has never opened needs `godot --headless --path game --import` first; tools/race_bench.sh and tools/verify.sh do it)" % [
				_broken, specs.size()])

	var marks := RaceBench.judge(_results)
	var matrix := "full" if full else "quick"
	# --write records what this run found, so its marks are not held against the old record
	# (a race that could not run stays a problem).
	var writing := "--write" in args and only == ""
	var recorded := _recorded(matrix, writing)
	var passing := PackedStringArray()
	var known := PackedStringArray()
	var unsteady := PackedStringArray()
	var once := PackedStringArray()
	print("")
	for m: Dictionary in marks:
		var want := String(recorded.get(m["id"], "?"))
		var now := "not run" if m["pass"] == null else ("pass" if m["pass"] else "FAIL")
		print("  %-16s %-8s recorded %-10s %s%s" % [m["title"], now, want, m["value"], "  [%s]" % m["worst"] if m["worst"] != "" else ""])
		if _before_marks.has(m["id"]) and String(_before_marks[m["id"]]["value"]) != String(m["value"]):
			print("  %-16s %-8s before: %s" % ["", "", _before_marks[m["id"]]["value"]])
		if m["pass"] == null:
			# A mark with a record that a whole run of its matrix cannot judge: its races are gone.
			if recorded.has(m["id"]) and only == "":
				_problems.append("%s is recorded as %s and this run did not judge it" % [m["title"], want])
			continue
		if want == "unsteady":
			unsteady.append("%s (%s this run)" % [m["title"], "passes" if m["pass"] else "fails"])
		elif want.begins_with("once:"):
			once.append("%s (%s here; passed on %s)" % [m["title"], "passes" if m["pass"] else "fails", want.trim_prefix("once:")])
			if only == "" and not writing and (not m["pass"] or want != "once:" + OS.get_name()):
				print("racebench: WARN %s %s on %s and is recorded as passing on %s only: record it (tools/race_bench.sh --write)" % [
						m["title"], "passes" if m["pass"] else "fails", OS.get_name(), want.trim_prefix("once:")])
		elif m["pass"]:
			passing.append(m["title"])
			if want == "fail" and only == "" and not writing:
				print("racebench: WARN %s now passes: record it in game/data/race_bench.json (tools/race_bench.sh --write)" % m["title"])
		else:
			known.append(m["title"])
			if want != "fail" and only == "" and not writing:
				_problems.append("%s fails and is recorded as %s: %s [%s]" % [m["title"], want, m["value"], m["worst"]])
	# Racer AI step 6b part 2: the police chase, old against new on clear roads, a line a chaser.
	var table: PackedStringArray = RaceBench.chase_balance(_results.filter(func(r: Dictionary) -> bool: return r.get("tuning", "") == "chase" and not r.has("error")))["table"]
	if not table.is_empty():
		print("\n  The police chase, old / new on clear roads:")
		for line in table:
			print("    " + line)
	for r: Dictionary in _results:
		if r.has("error"):
			_problems.append(String(r["error"]))
	if json_path != "":
		_write_json(json_path, {"matrix": matrix, "seconds": secs, "marks": marks, "races": _results})
	if writing:
		_record(matrix, marks)
	if _problems.is_empty():
		print("check_race_bench: OK (%s matrix, %d races in %.0f s · pass: %s · known fails of the rebuild: %s%s%s)" % [
				matrix, _results.size(), secs, ", ".join(passing) if not passing.is_empty() else "none",
				", ".join(known) if not known.is_empty() else "none",
				" · unsteady, not held: %s" % ", ".join(unsteady) if not unsteady.is_empty() else "",
				" · passed on one machine, not held: %s" % ", ".join(once) if not once.is_empty() else ""])
		quit(0)
	else:
		for p in _problems:
			print("  PROBLEM " + p)
		print("check_race_bench: %d problems" % _problems.size())
		quit(1)


## The races to run. Quick: the prototype race from Tamka (where F raced) with Pani Halina: a
## ladder race on clear roads against every test player, in heavy traffic, with the street
## blocked and with a crash; the guided first race; the three forced routes from Leszczyńska;
## one race twice. Full: both starts and both tunings under everything, all six rivals, and the
## guided first race to the Palace from Marszałkowska (RaceBench.PALACE: the finish's circle).
func _matrix(full: bool) -> Array:
	var out: Array = []
	for player: String in RaceBench.PLAYERS:
		out.append(_spec(HALINA, "ladder", "tamka", "clear", player))
	for player: String in (RaceBench.PLAYERS if full else ["none", "stopped", "average", "follower"]):
		out.append(_spec(HALINA, "ladder", "tamka", "heavy", player))
	for situation: String in ["blocked", "crash"]:
		for player: String in (["none", "average", "follower"] if full else ["none"]):
			out.append(_spec(HALINA, "ladder", "tamka", situation, player))
	for player: String in (RaceBench.PLAYERS if full else ["none", "stopped", "average", "follower"]):
		out.append(_spec(HALINA, "first", "tamka", "clear", player))
	# Route sense: the free choice from Leszczyńska and each of the three routes forced.
	out.append(_spec(HALINA, "ladder", "leszczynska", "clear", "none"))
	for route: String in RaceBench.ROUTES:
		var s := _spec(HALINA, "ladder", "leszczynska", "clear", "none")
		s["via"] = RaceBench.ROUTES[route]
		s["via_name"] = route
		out.append(s)
	# The same race twice (heavy traffic: the most there is to differ).
	out.append(_spec(HALINA, "ladder", "tamka", "heavy", "average"))
	# Racer AI step 5b: the wrong-way hop (one block of one-way Żelazna): Seba dares it on clear
	# roads and refuses it with a car parked on the street, Zbyszek does not dare it.
	for pair: Array in [[SEBA, "clear"], [SEBA, "parked"], ["Taksiarz Zbyszek", "clear"]]:
		var hop := _spec(pair[0], "ladder", RaceBench.HOP_START, pair[1], "none")
		hop["finish"] = RaceBench.HOP_FINISH
		out.append(hop)
	if not full:
		out.append_array(_pack_matrix(false))
		out.append_array(_chase_matrix(false))
		return out
	# Route sense in traffic: the free choice from Leszczyńska is in the loop below.
	for route: String in RaceBench.ROUTES:
		var s := _spec(HALINA, "ladder", "leszczynska", "heavy", "none")
		s["via"] = RaceBench.ROUTES[route]
		s["via_name"] = route
		out.append(s)
	# Two more draws of the town's cars.
	for draw: int in [1, 2]:
		for player: String in ["none", "average"]:
			var s := _spec(HALINA, "ladder", "tamka", "heavy", player)
			s["seed"] = draw
			out.append(s)
	for situation: String in ["heavy", "blocked", "crash"]:
		for player: String in (RaceBench.PLAYERS if situation == "heavy" else ["none", "average"]):
			out.append(_spec(HALINA, "first", "tamka", situation, player))
	for tuning: String in ["ladder", "first"]:
		for situation: String in RaceBench.SITUATIONS:
			for player: String in RaceBench.PLAYERS:
				if tuning == "ladder" and situation == "clear" and player == "none":
					continue
				if situation in ["blocked", "crash"] and not player in ["none", "average"]:
					continue
				if situation == "parked":
					continue  # the hop course's own situation (step 5b, below)
				out.append(_spec(HALINA, tuning, "leszczynska", situation, player))
	for rung: Dictionary in RaceBench.Ladder.RUNGS:
		if rung["rival"] == HALINA:
			continue
		for situation: String in ["clear", "heavy"]:
			for player: String in ["none", "stopped", "average"]:
				out.append(_spec(rung["rival"], "ladder", "tamka", situation, player))
	# A finish whose circle another road runs through: the first race to the Palace as the whole
	# game ran it, on clear roads and in traffic, alone and with a player about.
	for situation: String in ["clear", "heavy"]:
		for player: String in ["none", "average"]:
			var s := _spec(HALINA, "first", RaceBench.PALACE_START, situation, player)
			s["finish"] = RaceBench.PALACE
			out.append(s)
	# Step 4b's courses (docs/design/race-ai.md 7.1; each had only been measured with a scratch
	# spec). Every rung alone on clear roads on the two other courses: the ladder holds on a
	# course with a choice of routes and on a wide, short one.
	for rung: Dictionary in RaceBench.Ladder.RUNGS:
		if rung["rival"] != HALINA:
			out.append(_spec(rung["rival"], "ladder", "leszczynska", "clear", "none"))
		var s := _spec(rung["rival"], "ladder", RaceBench.PALACE_START, "clear", "none")
		s["finish"] = RaceBench.PALACE
		out.append(s)
	# A wide street (Marszałkowska to the Palace, two and three lanes each way) in Busy traffic
	# with a player who never leaves the line: the rival is out of the town's cars all the way
	# and pays the delay it expects there, which was fitted on narrower streets.
	for player: String in ["none", "stopped", "average"]:
		var s := _spec(SEBA, "ladder", RaceBench.PALACE_START, "heavy", player)
		s["finish"] = RaceBench.PALACE
		out.append(s)
	# The whole game's `--race=0`: Seba from the map's spawn to the Palace, on clear roads and in
	# the game's own Low traffic.
	for situation: String in ["clear", "low"]:
		for player: String in (["none", "average"] if situation == "low" else ["none"]):
			var s := _spec(SEBA, "ladder", RaceBench.SPAWN_START, situation, player)
			s["finish"] = RaceBench.PALACE
			out.append(s)
	# Low traffic on the prototype race, alone and with the average player.
	for player: String in ["none", "average"]:
		out.append(_spec(HALINA, "ladder", "tamka", "low", player))
		out.append(_spec(HALINA, "first", "tamka", "low", player))
	# The final's last stretch: from the middle of Most Poniatowskiego to Trzy mosty's finish.
	for situation: String in ["clear", "low"]:
		out.append(_spec(RaceBench.FINAL_RIVAL, "final", RaceBench.FINAL_START, situation, "none"))
	# Racer AI step 5: the race through a yard (race links), on clear roads and in Low traffic: Halina
	# and Zbyszek know the yard, Słoik knows none.
	for who: String in [HALINA, "Słoik z Radomia", "Taksiarz Zbyszek"]:
		for situation: String in ["clear", "low"]:
			var s := _spec(who, "ladder", RaceBench.YARD_START, situation, "none")
			s["finish"] = RaceBench.YARD_FINISH
			out.append(s)
	# Racer AI step 5b: the rest of the hop course (Seba and Zbyszek on clear roads and Seba with
	# a car parked on the street are in the quick matrix): Mike dares it too, Halina does not;
	# and all four in Low traffic.
	for who: String in [SEBA, "Mordor Mike", "Taksiarz Zbyszek", HALINA]:
		for situation: String in ["clear", "parked", "low"]:
			if situation != "low" and (who == SEBA or (who == "Taksiarz Zbyszek" and situation == "clear")):
				continue
			var s := _spec(who, "ladder", RaceBench.HOP_START, situation, "none")
			s["finish"] = RaceBench.HOP_FINISH
			out.append(s)
	# Other draws of the town's cars: every race in traffic above again with each of DRAWS, so a
	# mark that counts them is read over three draws and not one (Independence: a pair's time
	# over its draws; the contact counts: draw by draw). Draws 3 and 4 are the ones in which
	# step 3's and step 4a's rival turned back behind a player's car that only waited.
	# (The race run twice is in the list twice: each draw of it once.)
	var seen := {}
	for s: Dictionary in out.duplicate():
		if RaceBench._in_traffic(s) and not s.has("seed") and not s.has("via"):
			for draw: int in DRAWS:
				var again: Dictionary = s.duplicate()
				again["seed"] = draw
				var id := RaceBench.race_id(again)
				if not seen.has(id):
					seen[id] = true
					out.append(again)
	# Racer AI step 6b part 1b: the night club's pack (last, so the races above keep their numbers).
	out.append_array(_pack_matrix(true))
	# Racer AI step 6b part 2: the police chase, old and new (after the pack, for the same reason).
	out.append_array(_chase_matrix(true))
	return out


## The night club's pack race (RaceBench `pack`: a row per racer, and on clear roads alone each
## racer by itself first). Quick: on clear roads alone. Full: clear roads and Busy traffic, alone
## and with the average test player.
func _pack_matrix(full: bool) -> Array:
	var out: Array = []
	for situation: String in (["clear", "heavy"] if full else ["clear"]):
		for player: String in (["none", "average"] if full else ["none"]):
			out.append({"rival": "club", "tuning": "pack", "start_name": RaceBench.PACK_START, "situation": situation, "player": player})
	return out


## The police chase (RaceBench `chase`: a row per chaser). Quick: one chaser on the racers' driver
## after the average player on clear roads. Full: every course, clear roads and Busy traffic, the
## average and the fast player, one and two chasers, the old driver and the new.
func _chase_matrix(full: bool) -> Array:
	var out: Array = []
	if not full:
		out.append({"rival": "chase", "tuning": "chase", "mode": "new", "course": "powisle", "situation": "clear", "player": "average", "chasers": 1})
		return out
	for course: String in RaceBench.CHASE_COURSES:
		for situation: String in ["clear", "heavy"]:
			for player: String in RaceBench.CHASE_PLAYERS:
				for n in [1, 2]:
					for mode: String in ["old", "new"]:
						out.append({"rival": "chase", "tuning": "chase", "mode": mode, "course": course, "situation": situation, "player": player, "chasers": n})
	return out


func _spec(rival: String, tuning: String, start: String, situation: String, player: String) -> Dictionary:
	return {"rival": rival, "tuning": tuning, "start": RaceBench.STARTS[start], "start_name": start, "situation": situation, "player": player}


## Runs one race (first the clear one it is planned from, for a wall or a wreck) and prints it.
## False when its code stopped on a script error (printed above): nothing to judge.
func _race(spec: Dictionary) -> bool:
	var situation := String(spec["situation"])
	if situation == "blocked" or situation == "crash":
		var plan := spec.duplicate()
		plan["situation"] = "clear"
		plan["player"] = "none"
		plan.erase("trace")
		var ref_id := RaceBench.race_id(plan)
		if not _by_id.has(ref_id):
			# (A reference race of its own, not one of the matrix's: n -1, so a run in parts
			# does not count it twice.)
			plan["n"] = -1
			_race(plan)
		if not _by_id.has(ref_id):
			return false
		var edges := PackedInt32Array(_by_id[ref_id].get("edges", []))
		if situation == "blocked":
			spec["wall"] = _bench.plan_wall(spec, edges)
		else:
			spec["wreck"] = _bench.plan_wreck(spec, edges)
	if spec.get("tuning", "") == "chase":
		# The police chase: a row per chaser, each printed as a race.
		var all := true
		for row: Dictionary in _bench.chase(spec):
			all = _row(row, spec) and all
		return all
	if spec.get("tuning", "") == "pack":
		# The pack: a row per racer, each printed as a race.
		var ok := true
		for row: Dictionary in _bench.pack(spec):
			ok = _row(row, spec) and ok
		return ok
	return _row(_bench.race(spec), spec)


## One race's row (`race`, or a racer's of `pack`): kept and printed.
func _row(r: Dictionary, spec: Dictionary) -> bool:
	if not r.has("id"):
		return false
	r["n"] = int(spec.get("n", -1))
	_results.append(r)
	if r.has("error"):
		print("  %s: %s" % [r["id"], r["error"]])
		return true
	var ratio := ""
	if not _by_id.has(r["id"]):
		_by_id[r["id"]] = r
	var base: Dictionary = _by_id.get("%s/none" % String(r["id"]).get_slice("/via-", 0).rsplit("/", true, 1)[0], {})
	if not base.is_empty() and base["finished"] and r["finished"] and not r.has("via"):
		ratio = "x%.2f" % ((float(r["time"]) - float(r["hold_s"])) / maxf(float(base["time"]) - float(base["hold_s"]), 1.0))
	var extras := PackedStringArray()
	if float(r["hold_s"]) > 0.0:
		extras.append("waited %.0f s at the line" % r["hold_s"])
	if float(r["boxed_s"]) >= 1.0:
		extras.append("boxed in %.0f s behind the player's stopped car, no lane to pass in" % r["boxed_s"])
	if int(r.get("turned_back", 0)) > 0:
		var how := PackedStringArray()
		var back: Array = r.get("back", [])
		if 5 in back:
			how.append("a U-turn in the street")
		if 3 in back or 4 in back:
			how.append("backed out to the junction behind")
		extras.append("turned back %d times%s" % [r["turned_back"], " (%s)" % ", ".join(how) if not how.is_empty() else ""])
	if float(r.get("away_s", 0.0)) >= 1.0:
		extras.append("out of the town's cars %.0f s, paid %.1f s of the delay it expects there" % [r["away_s"], r["away_paid_s"]])
	if r.has("player_time"):
		extras.append("the player home in %.1f s" % r["player_time"])
	if int(r["overlaps"]) > 0:
		extras.append("THROUGH %d cars (%s)" % [r["overlaps"], ", ".join(PackedStringArray(r["overlap_log"]))])
	if int(r["slips"]) > 0:
		extras.append("%d slips (%d seen)" % [r["slips"], r["slips_seen"]])
	if int(r["jumps"]) > 0:
		extras.append("put elsewhere by the game %d times (%d seen)" % [r["jumps"], r["jumps_seen"]])
	if int(r["touches"]) > 0:
		extras.append("touched %d cars" % r["touches"])
	if int(r["hard_stops"]) > 0:
		extras.append("stopped dead %d times (%s)" % [r["hard_stops"], ", ".join(PackedStringArray(r["hard_log"]))])
	if float(r["lat_max"]) > RaceBench.PLAYER_GRIP:
		extras.append("sideways %.0f m/s²: %s" % [r["lat_max"], r["lat_at"]])
	if int(r["overtaken"]) > 0:
		extras.append("passed by %d town cars" % r["overtaken"])
	if r.has("wall"):
		extras.append("wall on %s (its way %d m, the best other way %d m, turning round at the wall %d m)" % [r["wall"]["street"], r["wall"]["base_m"], r["wall"]["alt_m"], r["wall"]["turn_m"]])
	if r.has("wreck"):
		extras.append("wreck on %s, knocked at %.0f s" % [r["wreck"]["street"], r.get("knock_s", -1.0)])
	if float(r.get("plan_s", 0.0)) > 0.0 and r["finished"] and r["situation"] == "clear":
		extras.append("the plan's clock %.1f s (%+.0f %%)" % [r["plan_s"], (float(r["plan_s"]) / maxf(float(r["time"]) - float(r["hold_s"]), 1.0) - 1.0) * 100.0])
	if r.get("tuning", "") == "chase":
		extras.append("gap %s m (along the roads %s) at %s s, closest %.0f m, %s, %d rams, %d times in front, the chase's script %.2f ms at most a frame, %.3f median" % [
				",".join(PackedStringArray(r["gap_m"].map(func(v): return "%.0f" % v))), ",".join(PackedStringArray(r["road_gap_m"].map(func(v): return "%.0f" % v))),
				",".join(PackedStringArray(RaceBench.CHASE_AT.map(func(v): return "%.0f" % v))), r["closest_m"],
				"escaped at %.1f s" % r["escape_s"] if float(r["escape_s"]) >= 0.0 else "no escape", r["rams"], r["ahead"], r["chase_most_ms"], r["chase_median_ms"]])
	if r.has("session_most_usec"):
		extras.append("place %d · the session's work %.2f ms at most in a frame, %.1f ms at the start" % [int(r.get("place", 0)), float(r["session_most_usec"]) / 1000.0, float(r["session_start_usec"]) / 1000.0])
	if _before.has(r["id"]):
		var b: Dictionary = _before[r["id"]]
		extras.append("before: %s%.1f s, crawl %.1f s, behind %.1f s, through %d cars" % [
				"" if b["finished"] else "DNF ", float(b["time"]), float(b["crawl_longest_s"]), float(b["behind_room_longest_s"]), int(b["overlaps"])])
	print("  %-46s %s %6.1f s %-6s %3.0f km/h (top %3.0f) · crawl %5.1f s (longest %5.1f) · behind %4.1f s · stood %4.1f s · passed %d · effort x%.2f-%.2f · %s · %.0f cars, %.1f s%s" % [
			r["id"], "    " if r["finished"] else "DNF ", r["time"], ratio, r["mean_kmh"], r["top_kmh"], r["crawl_s"], r["crawl_longest_s"],
			r["behind_room_longest_s"], r["stopped_s"], r["passes"], r["pace_lo"], r["pace_hi"], " > ".join(PackedStringArray(r["streets"])),
			r["cars"], float(r["wall_ms"]) / 1000.0, "\n      " + " · ".join(extras) if not extras.is_empty() else ""])
	return true


## --merge: the races of a run made in parts (`--part` files), in the matrix's order. A reference
## race a part ran for itself (n -1) is not one of the matrix's and is left out. Returns the
## matrix's races found.
func _merge(paths: PackedStringArray) -> int:
	var all: Array = []
	for path in paths:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if not parsed is Dictionary:
			_problems.append("cannot read %s" % path)
			continue
		all.append_array(parsed.get("races", []))
		_merged_secs += float(parsed.get("seconds", 0.0))
	all = all.filter(func(r: Dictionary) -> bool: return int(r.get("n", -1)) >= 0)
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["n"]) < int(b["n"]))
	_results = all
	return all.size()


## --against: an earlier run's races and marks (the file --json wrote).
func _load_before(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		_problems.append("cannot read %s" % path)
		return
	for r: Dictionary in parsed.get("races", []):
		if not _before.has(r["id"]):
			_before[r["id"]] = r
	for m: Dictionary in parsed.get("marks", []):
		_before_marks[m["id"]] = m


## The marks recorded for `matrix` ("quick" or "full"): {mark id: "pass" | "fail" | "unsteady"}.
## None recorded is a problem, unless this run is the one that records them (`writing`).
func _recorded(matrix: String, writing: bool) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE)) if FileAccess.file_exists(BASELINE) else null
	if parsed is Dictionary and (parsed as Dictionary).get(matrix) is Dictionary:
		return parsed[matrix]
	if not writing:
		_problems.append("%s has no marks for the %s matrix (record them: tools/race_bench.sh --write)" % [BASELINE, matrix])
	return {}


## --write: this run's marks become the ones recorded for its matrix (a mark this run did not
## judge keeps its record, and so does one recorded "unsteady"; the other matrix's stay as they are).
func _record(matrix: String, marks: Array) -> void:
	var doc := {}
	if FileAccess.file_exists(BASELINE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
		if parsed is Dictionary:
			doc = parsed
	var gates: Dictionary = doc[matrix] if doc.get(matrix) is Dictionary else {}
	for m: Dictionary in marks:
		var was := str(gates.get(m["id"], ""))
		if m["pass"] == null or was == "unsteady":
			continue
		if not m["pass"]:
			gates[m["id"]] = "fail"
		elif was == "pass" or not m.get("traffic", false) or (was.begins_with("once:") and was != "once:" + OS.get_name()):
			gates[m["id"]] = "pass"
		else:
			# A mark that counts races in traffic, passing here for the first time: one machine's
			# draw of the town's cars. The other machine's --write makes it a pass.
			gates[m["id"]] = "once:" + OS.get_name()
			print("check_race_bench: %s passes on %s; it is recorded as a pass when it also passes on the other machine (tools/race_bench.sh --write there)" % [m["title"], OS.get_name()])
	doc["about"] = "The race bench's pass marks as recorded (docs/design/race-ai.md, game/tools/check_race_bench.gd), for the quick matrix (verify and CI) and the full one (tools/race_bench.sh): a mark recorded pass that fails is a problem; one recorded fail that passes is a warning until it is recorded here (tools/race_bench.sh --write); one recorded once:<machine> counts races in traffic and has passed on that machine only (--write on the other machine makes it a pass; not held until then); one recorded unsteady (set by hand: it passes or fails with the draw of the town's cars, and its step is not built) is not held and --write leaves it."
	doc[matrix] = gates
	_write_json(BASELINE, doc)
	print("check_race_bench: recorded the %s matrix's marks in %s" % [matrix, BASELINE])


func _write_json(path: String, doc: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_problems.append("cannot write %s" % path)
		return
	f.store_string(JSON.stringify(doc, "\t", false) + "\n")
	f.close()
