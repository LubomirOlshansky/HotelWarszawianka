extends SceneTree
## The arcade padel match at WTS DESKA (padel_sim.gd, padel_match.gd; docs/design/padel.md).
## Checks that:
## - the trajectory solver lands a ball where it was aimed and clears the net;
## - SEEDS whole matches with the human on autopilot each end (one side two games) inside MATCH_MAX
##   s of play, with no stuck rally, real rallies (on average RALLY_MIN hits or more), both pairs
##   winning points, smashes and balls off the glass across the set, the score always legal
##   (0/15/30/40, the golden point at 40:40);
## - an idle human (no taps) loses every point it should play: the rivals win 2:0;
## - the committed swing (critique-padel.md 3.1): a tap books the best contact the ball's flight offers
##   and grades its timing against the closing ring (CZYSTO, DOBRZE, ...). Three hands, SEEDS matches
##   each: a tap on the ring (45 ms error) wins at least 55%, a clumsy one (110 ms) fewer, a button
##   masher at most 25%; each prints its win rate, its share of the pair's balls and the match time;
## - the rules: a ball into the net, one into the glass before its bounce, a second bounce and a
##   ball over the fence after the bounce each give the point to the right side;
## - the match's view (padel_match.gd) has every line in Polish and English (dialogue.json group
##   padel_match, one key each in PadelMatch.KEYS).
##   godot --headless --path game --script res://tools/check_padel.gd

const PadelSim := preload("res://scripts/padel_sim.gd")
const PadelMatch := preload("res://scripts/padel_match.gd")

const SEEDS := 24
const STEP := 1.0 / 60.0
const MATCH_MAX := 900.0
const RALLY_MIN := 5.0
const DECENT_S := 0.045
const CLUMSY_S := 0.11

var fails: Array[String] = []


func _init() -> void:
	_solver()
	_grades()
	_matches()
	_idle()
	_hands()
	_warmup()
	_rules()
	_lines()
	if fails.is_empty():
		print("check_padel: OK")
		quit(0)
	else:
		for f in fails:
			print("check_padel: FAIL " + f)
		quit(1)


func _fail(s: String) -> void:
	fails.append(s)


## The tap's grade: CZYSTO inside CLEAN_S, then 0.8, 0.6, 0.4, early or late alike.
func _grades() -> void:
	var want := [[0.0, 1.0], [PadelSim.CLEAN_S - 0.005, 1.0], [-PadelSim.CLEAN_S - 0.005, 0.8], [PadelSim.GOOD_S - 0.005, 0.8],
			[-PadelSim.GOOD_S - 0.005, 0.6], [PadelSim.OK_S - 0.005, 0.6], [0.3, 0.4], [-0.3, 0.4]]
	for w: Array in want:
		if not is_equal_approx(PadelSim.grade(float(w[0])), float(w[1])):
			_fail("grade(%.3f) is %.1f, want %.1f" % [float(w[0]), PadelSim.grade(float(w[0])), float(w[1])])


func _solver() -> void:
	var from := Vector3(3.0, 2.5, 1.0)
	var to := Vector2(16.0, 7.0)
	var v := PadelSim.solve(from, to, 0.8)
	var b := PadelSim.BallState.new()
	b.p = from
	b.v = v
	var t := 0.0
	var landed := Vector2.INF
	var cleared := false
	while t < 3.0:
		var ev := b.step(1.0 / 240.0)
		t += 1.0 / 240.0
		if ev == "cross":
			cleared = true
		if ev == "net":
			break
		if ev == "floor":
			landed = Vector2(b.p.x, b.p.y)
			break
	if not cleared:
		_fail("solver: a drive from the baseline did not clear the net")
	elif landed == Vector2.INF or landed.distance_to(to) > 0.6:
		_fail("solver: aimed at %s, landed at %s" % [to, landed])


## One match. `bot`: "auto" the human on autopilot (the AI plays you), "idle" no taps, "mash" taps four times a second, "decent" / "clumsy" tap on the ring with a normal error
## of DECENT_S / CLUMSY_S seconds.
func _play(seed: int, bot: String) -> PadelSim:
	var sim := PadelSim.new()
	sim.auto_human = bot == "auto"
	sim.setup(seed, "Kuba", ["Prezes", "Zbyszek"])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + 3
	var sigma := DECENT_S if bot == "decent" else CLUMSY_S
	var t := 0.0
	var noise := 0.0
	var ball_n := -1
	while not sim.over() and t < MATCH_MAX:
		if sim.phase == PadelSim.Phase.PLAY:
			var me := sim.players[0]
			if bot == "mash":
				if me.swing < 0.0 and me.cool <= 0.0 and int(sim.time * 60.0) % 15 == 0:
					sim.press(PadelSim.Shot.DRIVE)
			elif bot == "decent" or bot == "clumsy":
				if sim.rally_hits != ball_n:
					ball_n = sim.rally_hits
					noise = rng.randfn(0.0, sigma)
				if sim.cue_at >= 0.0 and me.swing < 0.0 and sim.time >= sim.cue_at - PadelSim.LEAD + noise:
					sim.press(PadelSim.Shot.DRIVE)
		if (bot == "mash" or bot == "decent" or bot == "clumsy") and sim.phase == PadelSim.Phase.SERVE and sim.server == 0 and sim.phase_t > 0.5:
			sim.press(PadelSim.Shot.DRIVE)
		sim.step(STEP)
		t += STEP
		_score_ok(sim, seed)
		sim.events.clear()
	if not sim.over():
		_fail("seed %d: the match did not end in %.0f s (games %s, points %s)" % [seed, MATCH_MAX, sim.games, sim.points])
	return sim


func _score_ok(sim: PadelSim, seed: int) -> void:
	for k in 2:
		if int(sim.points[k]) > PadelSim.POINTS_TO_GAME or int(sim.games[k]) > PadelSim.GAMES_TO_WIN:
			_fail("seed %d: an illegal score %s / %s" % [seed, sim.points, sim.games])


func _matches() -> void:
	var hits := 0
	var mine := 0
	var pair := 0
	var rallies := 0
	var won := [0, 0]
	var smashes := 0
	var glass := 0
	var times := []
	for seed in SEEDS:
		var sim := _play(seed, "auto")
		if sim.stalls > 0:
			_fail("seed %d: %d rallies got stuck" % [seed, sim.stalls])
		hits += int(sim.stats["hits"])
		mine += int(sim.stats["your_hits"])
		pair += int(sim.stats["pair_hits"])
		rallies += int(sim.stats["rallies"])
		smashes += int(sim.stats["smashes"])
		glass += int(sim.stats["glass"])
		won[0 if int(sim.games[0]) > int(sim.games[1]) else 1] += 1
		times.append(sim.time)
	var avg := float(hits) / maxf(rallies, 1)
	print("check_padel: %d matches, %d rallies, %.1f hits a rally, matches won %s, %d smashes, %d off the glass, %.0f-%.0f s, you (autopilot) play %.0f%% of the pair's balls" % [SEEDS, rallies, avg, won, smashes, glass, times.min(), times.max(), 100.0 * mine / maxf(pair, 1)])
	if avg < RALLY_MIN:
		_fail("rallies too short: %.1f hits on average" % avg)
	if won[0] == 0 or won[1] == 0:
		_fail("one pair won every match: %s" % [won])
	if smashes == 0 or glass == 0:
		_fail("no smash (%d) or no ball off the glass (%d)" % [smashes, glass])


func _idle() -> void:
	var sim := _play(7, "idle")
	if int(sim.games[1]) != 2 or int(sim.games[0]) != 0:
		_fail("an idle human should lose 0:2, got %s" % [sim.games])


## Three hands against the same rivals, SEEDS matches each: a tap on the ring (decent, clumsy) and the
## old tap-the-moment-it-is-in-reach. Prints the win rate, your share of the pair's balls, the match
## time and the taps; the timing must matter (decent > clumsy > rim).
func _hands() -> void:
	var rates := {}
	for bot: String in ["decent", "clumsy", "mash"]:
		var won := 0
		var mine := 0
		var pair := 0
		var clean := 0
		var times := []
		for seed in SEEDS:
			var sim := _play(100 + seed, bot)
			if int(sim.games[0]) > int(sim.games[1]):
				won += 1
			mine += int(sim.stats["your_hits"])
			pair += int(sim.stats["pair_hits"])
			clean += int(sim.stats["clean"])
			times.append(sim.time)
		rates[bot] = float(won) / SEEDS
		var avg_t := 0.0
		for x: float in times:
			avg_t += x
		avg_t /= times.size()
		print("check_padel: %s hand wins %d of %d, plays %.0f%% of the pair's balls, %.1f clean a match, %.0f s a match (%.0f-%.0f)" % [bot, won, SEEDS,
				100.0 * mine / maxf(pair, 1), float(clean) / SEEDS, avg_t, times.min(), times.max()])
		if mine < 20:
			_fail("%s: made only %d hits in %d matches" % [bot, mine, SEEDS])
	if float(rates["decent"]) < 0.55:
		_fail("a hand that taps on the ring (45 ms) won only %.0f%% of matches" % (100.0 * float(rates["decent"])))
	if float(rates["clumsy"]) >= float(rates["decent"]):
		_fail("timing does not matter: clumsy %.0f%%, decent %.0f%%" % [100.0 * float(rates["clumsy"]), 100.0 * float(rates["decent"])])
	if float(rates["mash"]) > 0.25:
		_fail("a button masher won %.0f%% of matches" % (100.0 * float(rates["mash"])))


## The warm-up (the how-to's three feeds): nothing counts, it ends by itself after WARM_BALLS hits
## (or WARM_MAX s for a hand that never taps), then a whole match is played from 0:0.
func _warmup() -> void:
	for bot: String in ["decent", "idle"]:
		var sim := PadelSim.new()
		sim.setup(5, "Kuba", ["Prezes", "Zbyszek"], true)
		if not sim.warming():
			_fail("warm-up: did not start")
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var t := 0.0
		var ball_n := -1
		var noise := 0.0
		while sim.warming() and t < PadelSim.WARM_MAX + 10.0:
			if bot == "decent" and sim.phase == PadelSim.Phase.PLAY:
				if sim.rally_hits != ball_n:
					ball_n = sim.rally_hits
					noise = rng.randfn(0.0, DECENT_S)
				if sim.cue_at >= 0.0 and sim.players[0].swing < 0.0 and sim.time >= sim.cue_at - PadelSim.LEAD + noise:
					sim.press(PadelSim.Shot.DRIVE)
			sim.step(STEP)
			t += STEP
			if int(sim.points[0]) + int(sim.points[1]) > 0:
				_fail("warm-up (%s): a point counted (%s)" % [bot, sim.points])
				return
			sim.events.clear()
		if sim.warming():
			_fail("warm-up (%s): still on after %.0f s" % [bot, t])
		elif bot == "decent" and t > 25.0:
			_fail("warm-up: three timed hits took %.0f s" % t)
		if int(sim.stats["hits"]) != 0 or sim.server != sim.server_index():
			_fail("warm-up (%s): the match did not start fresh (stats %s, server %d)" % [bot, sim.stats, sim.server])
		print("check_padel: warm-up (%s hand) over in %.1f s" % [bot, t])


func _rules() -> void:
	# A ball into the net: the hitter's side loses.
	var sim := _fresh()
	sim.ball.p = Vector3(8.0, 5.0, 0.5)
	sim.ball.v = Vector3(8.0, 0.0, 0.0)
	_run_point(sim)
	_expect(sim, 1, "into the net")
	# Straight into the far glass: long.
	sim = _fresh()
	sim.ball.p = Vector3(9.0, 5.0, 2.0)
	sim.ball.v = Vector3(30.0, 0.0, 1.0)
	_run_point(sim)
	_expect(sim, 1, "into the glass before the bounce")
	# A ball that bounces twice on the far side with nobody there: the hitter wins.
	sim = _fresh()
	for pl in sim.players:
		if pl.team == 1:
			pl.pos = Vector2(19.5, 9.5)
			pl.target = pl.pos
			pl.planned = false
	sim.ball.p = Vector3(9.0, 2.0, 1.2)
	sim.ball.v = PadelSim.solve(sim.ball.p, Vector2(13.0, 2.0), 0.9)
	sim.players[2].will_reach = false
	sim.players[3].will_reach = false
	_run_point(sim, true)
	_expect(sim, 0, "a second bounce")


func _fresh() -> PadelSim:
	var sim := PadelSim.new()
	sim.setup(3, "Kuba", ["Prezes", "Zbyszek"])
	sim.held = false
	sim.live = true
	sim.phase = PadelSim.Phase.PLAY
	sim.last_team = 0
	sim.crossed = false
	sim.bounces = 0
	sim.serve_ball = false
	return sim


func _run_point(sim: PadelSim, freeze := false) -> void:
	var t := 0.0
	while sim.phase == PadelSim.Phase.PLAY and t < 10.0:
		if freeze:
			for pl in sim.players:
				pl.planned = false
		sim.step(STEP)
		t += STEP


func _expect(sim: PadelSim, team: int, what: String) -> void:
	if sim.phase != PadelSim.Phase.POINT or sim.point_team != team:
		_fail("rules, %s: expected the point to team %d, got phase %d team %d (%s)" % [what, team, sim.phase, sim.point_team, sim.reason])


func _lines() -> void:
	for key: String in PadelMatch.KEYS:
		var row: Array = PadelMatch.lines_of(key)
		if row.is_empty():
			_fail("lines: %s has no words in dialogue.json group %s" % [key, PadelMatch.GROUP])
		for pair: Array in row:
			if pair.size() != 2 or String(pair[0]) == "" or String(pair[1]) == "":
				_fail("lines: %s has a line without Polish or English" % key)
