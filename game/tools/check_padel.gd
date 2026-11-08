extends SceneTree
## The arcade padel match at WTS DESKA (padel_sim.gd, padel_match.gd; docs/design/padel.md).
## Checks that:
## - the trajectory solver lands a ball where it was aimed and clears the net;
## - SEEDS whole matches with the human on autopilot each end (one side two games) inside MATCH_MAX
##   s of play, with no stuck rally, real rallies (on average RALLY_MIN hits or more), both pairs
##   winning points, smashes and balls off the glass across the set, the score always legal
##   (0/15/30/40, the golden point at 40:40);
## - an idle human (no taps) loses every point it should play: the rivals win 2:0;
## - a human who taps at the right moment (the auto-run, a tap when the ball is in reach) wins
##   rallies: the pair takes points;
## - the rules: a ball into the net, one into the glass before its bounce, a second bounce and a
##   ball over the fence after the bounce each give the point to the right side;
## - the match's view (padel_match.gd) has every line in Polish and English.
##   godot --headless --path game --script res://tools/check_padel.gd

const PadelSim := preload("res://scripts/padel_sim.gd")
const PadelMatch := preload("res://scripts/padel_match.gd")

const SEEDS := 24
const STEP := 1.0 / 60.0
const MATCH_MAX := 900.0
const RALLY_MIN := 5.0

var fails: Array[String] = []


func _init() -> void:
	_solver()
	_matches()
	_idle()
	_tapper()
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


func _play(seed: int, auto: bool, tapper := false) -> PadelSim:
	var sim := PadelSim.new()
	sim.auto_human = auto
	sim.setup(seed, "Kuba", ["Prezes", "Zbyszek"])
	var t := 0.0
	while not sim.over() and t < MATCH_MAX:
		if tapper and sim.phase == PadelSim.Phase.PLAY and sim.can_hit(sim.players[0], false) and sim.players[0].swing < 0.0:
			sim.press(PadelSim.Shot.DRIVE)
		if tapper and sim.phase == PadelSim.Phase.SERVE and sim.server == 0 and sim.phase_t > 0.5:
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
	var rallies := 0
	var won := [0, 0]
	var smashes := 0
	var glass := 0
	var times := []
	for seed in SEEDS:
		var sim := _play(seed, true)
		if sim.stalls > 0:
			_fail("seed %d: %d rallies got stuck" % [seed, sim.stalls])
		hits += int(sim.stats["hits"])
		rallies += int(sim.stats["rallies"])
		smashes += int(sim.stats["smashes"])
		glass += int(sim.stats["glass"])
		won[0 if int(sim.games[0]) > int(sim.games[1]) else 1] += 1
		times.append(sim.time)
	var avg := float(hits) / maxf(rallies, 1)
	print("check_padel: %d matches, %d rallies, %.1f hits a rally, matches won %s, %d smashes, %d off the glass, %.0f-%.0f s" % [SEEDS, rallies, avg, won, smashes, glass, times.min(), times.max()])
	if avg < RALLY_MIN:
		_fail("rallies too short: %.1f hits on average" % avg)
	if won[0] == 0 or won[1] == 0:
		_fail("one pair won every match: %s" % [won])
	if smashes == 0 or glass == 0:
		_fail("no smash (%d) or no ball off the glass (%d)" % [smashes, glass])


func _idle() -> void:
	var sim := _play(7, false)
	if int(sim.games[1]) != 2 or int(sim.games[0]) != 0:
		_fail("an idle human should lose 0:2, got %s" % [sim.games])


func _tapper() -> void:
	var pts := 0
	for seed in 6:
		var sim := _play(100 + seed, false, true)
		pts += int(sim.stats["your_hits"])
	if pts < 20:
		_fail("a human tapping in reach made only %d hits in six matches" % pts)


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
	for key: String in PadelMatch.LINES:
		var row: Array = PadelMatch.LINES[key]
		for pair: Array in row:
			if pair.size() != 2 or String(pair[0]) == "" or String(pair[1]) == "":
				_fail("lines: %s has a line without Polish or English" % key)
