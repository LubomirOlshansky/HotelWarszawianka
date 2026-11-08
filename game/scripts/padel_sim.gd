extends RefCounted
## "Padel na Desce": the rules, the ball and the four players of the arcade padel match at WTS
## DESKA (padel_match.gd draws it; docs/design/padel.md, F's ask 2026-11-08). No nodes, no drawing:
## the view calls `step(dt)` every frame and drains `events`; the check (check_padel.gd) drives it
## headless with the human on autopilot.
##
## The court: x along its length 0..20 m (the net at 10; our pair, you and the friend, on x < 10),
## y across it 0..10 m (0 is the side nearest the camera), z up. Glass back walls 3 m high with the
## mesh on top to 4 m, the sides glass for 2 m at each end and mesh between, all walls play: the
## ball off the glass is part of the game. Over the 4 m fence it is out.
##
## The rules, padel's, a little simplified: a shot must cross the net and bounce once on the other
## side before it touches a wall there (else the hitter loses the point); after that bounce it may
## come off any wall, and a second bounce, or a ball over the fence, wins it for the hitter. You
## may volley (before the bounce) except the serve. Scoring 0/15/30/40 with the golden point (at
## 40:40 the next point takes the game), two games win the match. Serves are automatic and safe:
## the AI's after SERVE_WAIT s, yours on a tap (or after HUMAN_SERVE_WAIT s).
##
## The shots: UDERZ (a drive, a volley at the net, or a jumping SMASH when the ball is high) and
## LOB. A shot's quality 0..1 is the timing: how close the ball is to the racket's sweet spot when
## it is hit. A bad one scatters: long into the glass, wide into the side wall, low into the net.
## The AI reads the ball by simulating it ahead (`_plan`) and, by its skill and the incoming shot's
## pressure, sometimes misjudges it.

const LEN := 20.0
const WID := 10.0
const NET_X := 10.0
const NET_H := 0.92
const GLASS_H := 3.0
const WALL_H := 4.0
const SIDE_GLASS := 2.0
const G := 9.0
const R := 0.04
const FLOOR_E := 0.72
const FLOOR_F := 0.85
const GLASS_E := 0.64
const MESH_E := 0.32
const DRAG := 0.05
const SUB := 2
## Reach: horizontal metres from the player's middle; the highest normal contact; with a jump.
const REACH := 1.3
const REACH_H := 2.2
const JUMP_H := 3.2
## The human's swing: a tap opens a window this long in which the first reachable ball is hit.
const SWING_S := 0.34
const SWING_COOL := 0.2
## The racket's sweet spot height (m) for the quality.
const SWEET_Z := 1.05
const SERVE_WAIT := 1.2
const HUMAN_SERVE_WAIT := 4.0
const POINT_PAUSE := 1.9
const GAME_PAUSE := 3.2
const GAMES_TO_WIN := 2
const POINTS_TO_GAME := 4
## A rally never runs longer than this (s); a stuck ball goes to the side that hit it last. The
## check fails if it ever happens.
const RALLY_MAX := 40.0
## The stick, not touched this long (s), hands the human back to the auto-run.
const STICK_HOLD := 0.7
const CALLS := ["0", "15", "30", "40"]

enum Shot { DRIVE, LOB, SMASH, VOLLEY, SERVE }
enum Phase { SERVE, PLAY, POINT, GAME, OVER }

## Shot names [pl, en] for the callouts.
const SHOT_NAMES := [["DRIVE", "DRIVE"], ["LOB", "LOB"], ["SMECZ!", "SMASH!"], ["WOLEJ", "VOLLEY"], ["SERWIS", "SERVE"]]
## How far a poor shot scatters (m at quality 0), per Shot.
const SCATTER := [2.0, 1.5, 2.3, 1.7, 0.4]
## How hard each shot is to return at quality 1 (taken off the receiver's chance).
const PRESSURE := [0.08, 0.04, 0.38, 0.14, 0.0]


## The ball's flight: position and velocity; `step` moves it one sub-step and says what it hit.
class BallState:
	var p := Vector3.ZERO
	var v := Vector3.ZERO

	func copy() -> BallState:
		var b := BallState.new()
		b.p = p
		b.v = v
		return b

	## One sub-step of `h` s. Returns what happened: "" or one of "net", "cross", "floor",
	## "glass", "mesh", "out" (the first that did).
	func step(h: float) -> String:
		var prev := p
		v.z -= G * h
		v *= 1.0 - DRAG * h
		p += v * h
		var ev := ""
		# The net: a ball crossing x = 10 below the tape drops dead on the hitter's side.
		if (prev.x - NET_X) * (p.x - NET_X) < 0.0 and p.y > -0.2 and p.y < WID + 0.2:
			if p.z < NET_H:
				p.x = NET_X - signf(v.x) * 0.06
				v = Vector3(-v.x * 0.12, v.y * 0.35, minf(v.z, 0.0) * 0.3)
				return "net"
			ev = "cross"
		if p.z < R:
			p.z = R
			if v.z < 0.0:
				var impact := -v.z
				v.z = impact * FLOOR_E
				v.x *= FLOOR_F
				v.y *= FLOOR_F
				if impact > 0.7:
					return "floor"
				# Rolling: the ball stays on the floor.
				v.z = 0.0
				v.x *= 0.97
				v.y *= 0.97
		if p.x < 0.0 or p.x > LEN:
			if p.z > WALL_H:
				return "out"
			p.x = clampf(p.x, 0.0, LEN)
			var glass := p.z < GLASS_H
			v.x = -v.x * (GLASS_E if glass else MESH_E)
			v.y *= 0.9
			return "glass" if glass else "mesh"
		if p.y < 0.0 or p.y > WID:
			var end := p.x < SIDE_GLASS or p.x > LEN - SIDE_GLASS
			var top := WALL_H if end else GLASS_H
			if p.z > top:
				return "out"
			p.y = clampf(p.y, 0.0, WID)
			var g2 := end and p.z < GLASS_H
			v.y = -v.y * (GLASS_E if g2 else MESH_E)
			v.x *= 0.9
			return "glass" if g2 else "mesh"
		return ev


class Player:
	var team := 0
	var idx := 0
	var name := ""
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var target := Vector2.ZERO
	var speed := 4.5
	var skill := 0.7
	var human := false
	## Seconds since the swing began; < 0: not swinging.
	var swing := -1.0
	var swing_shot := Shot.DRIVE
	var cool := 0.0
	var jump := 0.0
	var jump_v := 0.0
	## Planned: the ball is to be taken at `plan_p` at sim time `plan_t`; false: misjudged.
	var planned := false
	var will_reach := true
	var plan_p := Vector3.ZERO
	var plan_t := 0.0
	## Sim time of the last hit (the racket smear), its quality.
	var hit_at := -10.0
	var hit_q := 0.0
	var run := 0.0


var players: Array[Player] = []
var ball := BallState.new()
var live := false
var held := true
var last_team := -1
var crossed := false
var bounces := 0
var serve_ball := false
var last_shot := Shot.SERVE
var last_q := 0.0
var server := 0
var points := [0, 0]
var games := [0, 0]
var phase := Phase.SERVE
var phase_t := 0.0
var time := 0.0
var rally_hits := 0
var point_team := -1
var reason := ""
## [kind, {data}] since the view last drained it: "hit", "bounce", "glass", "mesh", "net", "point",
## "game", "match", "serve_ready", "whiff".
var events: Array = []
var rng := RandomNumberGenerator.new()
## The human plays itself (the check, the shots, Autopilot).
var auto_human := false
## The stick, in court axes (x along, y away from the camera), -1..1, from the view.
var stick := Vector2.ZERO
var _stick_idle := 99.0
## The human's serve is waiting for a tap.
var serve_tap := false
var stalls := 0
var stats := {"hits": 0, "smashes": 0, "glass": 0, "rallies": 0, "longest": 0, "perfect": 0, "your_hits": 0}


## Four players: you and `partner` (team 0) against `rivals` (team 1). `seed` fixes the AI's dice.
func setup(seed: int, partner: String, rivals: Array) -> void:
	rng.seed = seed
	players.clear()
	var names := ["Ty", partner, String(rivals[0]), String(rivals[1])]
	var skills := [0.75, 0.7, 0.62, 0.68]
	var speeds := [5.4, 4.7, 4.5, 4.6]
	for i in 4:
		var pl := Player.new()
		pl.idx = i
		pl.team = 0 if i < 2 else 1
		pl.name = names[i]
		pl.skill = skills[i]
		pl.speed = speeds[i]
		pl.human = i == 0
		players.append(pl)
	points = [0, 0]
	games = [0, 0]
	start_point()


## The serving player this game: the teams take turns by game, each team's two players by turns.
func server_index() -> int:
	var g: int = games[0] + games[1]
	var team := g % 2
	var who := (g / 2) % 2
	return team * 2 + who


func side_of(x: float) -> int:
	return 0 if x < NET_X else 1


## The scoreboard call for `team`'s points this game: "0" "15" "30" "40".
func call_of(team: int) -> String:
	return CALLS[mini(int(points[team]), 3)]


func golden() -> bool:
	return int(points[0]) == 3 and int(points[1]) == 3


func start_point() -> void:
	server = server_index()
	var s := players[server]
	var dir := 1.0 if s.team == 0 else -1.0
	var lane := 2.6 if (int(points[0]) + int(points[1])) % 2 == 0 else 7.4
	for pl in players:
		pl.swing = -1.0
		pl.cool = 0.0
		pl.jump = 0.0
		pl.jump_v = 0.0
		pl.planned = false
		pl.vel = Vector2.ZERO
	var other := players[server ^ 1]
	s.pos = Vector2(NET_X - dir * 9.0, lane)
	other.pos = Vector2(NET_X - dir * 3.2, WID - lane)
	var rx := 1 - s.team
	var receiver := players[rx * 2 + (0 if s.idx % 2 == 0 else 1)]
	var rp := players[(rx * 2 + (0 if s.idx % 2 == 0 else 1)) ^ 1]
	receiver.pos = Vector2(NET_X + dir * 8.6, WID - lane)
	rp.pos = Vector2(NET_X + dir * 6.0, lane)
	for pl in players:
		pl.target = pl.pos
	held = true
	live = false
	serve_ball = false
	last_team = -1
	bounces = 0
	crossed = false
	rally_hits = 0
	ball.p = Vector3(s.pos.x + dir * 0.4, s.pos.y, 0.9)
	ball.v = Vector3.ZERO
	phase = Phase.SERVE
	phase_t = 0.0
	serve_tap = s.human and not auto_human
	events.append(["serve_ready", {"server": server}])


## The view's HIT / LOB buttons: a swing (or the serve when it's yours).
func press(shot: int) -> void:
	var me := players[0]
	if phase == Phase.SERVE and held and server == 0:
		_serve()
		return
	if phase != Phase.PLAY or me.cool > 0.0 or me.swing >= 0.0:
		return
	me.swing = 0.0
	me.swing_shot = shot


func step(dt: float) -> void:
	time += dt
	phase_t += dt
	_stick_idle = 0.0 if stick.length() > 0.15 else _stick_idle + dt
	match phase:
		Phase.SERVE:
			var s := players[server]
			var dir := 1.0 if s.team == 0 else -1.0
			ball.p = Vector3(s.pos.x + dir * 0.4, s.pos.y, 0.9 + absf(sin(phase_t * 5.0)) * 0.25)
			var wait := HUMAN_SERVE_WAIT if serve_tap else SERVE_WAIT
			if phase_t > wait:
				_serve()
		Phase.PLAY:
			var h := dt / SUB
			for _i in SUB:
				_ball_step(h)
				if phase != Phase.PLAY:
					break
			if phase == Phase.PLAY and phase_t > RALLY_MAX:
				stalls += 1
				_point(last_team if last_team >= 0 else 0, "stall")
		Phase.POINT:
			_ball_free(dt)
			if phase_t > POINT_PAUSE:
				if int(points[point_team]) >= POINTS_TO_GAME:
					_game(point_team)
				else:
					start_point()
		Phase.GAME:
			_ball_free(dt)
			if phase_t > GAME_PAUSE:
				if int(games[0]) >= GAMES_TO_WIN or int(games[1]) >= GAMES_TO_WIN:
					phase = Phase.OVER
					phase_t = 0.0
					events.append(["match", {"winner": 0 if int(games[0]) > int(games[1]) else 1}])
				else:
					points = [0, 0]
					start_point()
		Phase.OVER:
			_ball_free(dt)
	_players_step(dt)


func over() -> bool:
	return phase == Phase.OVER


# --- the ball and the rules -------------------------------------------------------------------

func _ball_free(dt: float) -> void:
	if held:
		return
	var h := dt / SUB
	for _i in SUB:
		ball.step(h)


func _ball_step(h: float) -> void:
	var ev := ball.step(h)
	match ev:
		"cross":
			if side_of(ball.p.x) != last_team:
				crossed = true
		"net":
			events.append(["net", {"p": ball.p}])
		"floor":
			var s := side_of(ball.p.x)
			events.append(["bounce", {"p": ball.p}])
			if s == last_team:
				if not crossed:
					_point(1 - last_team, "net" if absf(ball.p.x - NET_X) < 1.5 else "short")
				else:
					_point(last_team, "back")
			else:
				bounces += 1
				if bounces >= 2:
					_point(last_team, "winner")
		"glass", "mesh":
			var s := side_of(ball.p.x)
			events.append([ev, {"p": ball.p, "legal": bounces >= 1}])
			if s != last_team and crossed and bounces == 0:
				_point(s, "long" if ball.p.x < 0.5 or ball.p.x > LEN - 0.5 else "wide")
			elif s != last_team and bounces >= 1:
				stats["glass"] = int(stats["glass"]) + 1
		"out":
			var s := side_of(ball.p.x)
			if s != last_team and bounces >= 1:
				_point(last_team, "over")
			else:
				_point(1 - last_team, "out")


func _point(team: int, why: String) -> void:
	if phase != Phase.PLAY:
		return
	live = false
	points[team] = int(points[team]) + 1
	point_team = team
	reason = why
	phase = Phase.POINT
	phase_t = 0.0
	stats["rallies"] = int(stats["rallies"]) + 1
	stats["longest"] = maxi(int(stats["longest"]), rally_hits)
	events.append(["point", {"team": team, "why": why, "hits": rally_hits, "shot": last_shot}])


func _game(team: int) -> void:
	games[team] = int(games[team]) + 1
	phase = Phase.GAME
	phase_t = 0.0
	events.append(["game", {"team": team, "games": games.duplicate()}])


func _serve() -> void:
	var s := players[server]
	var dir := 1.0 if s.team == 0 else -1.0
	var from := Vector3(s.pos.x + dir * 0.4, s.pos.y, 0.95)
	var tx := NET_X + dir * rng.randf_range(3.6, 6.2)
	var ty := clampf(WID - s.pos.y + rng.randf_range(-1.0, 1.0), 1.2, WID - 1.2)
	held = false
	live = true
	phase = Phase.PLAY
	phase_t = 0.0
	serve_ball = true
	_launch(s, from, Vector2(tx, ty), 1.05, Shot.SERVE, 1.0)


## Sets the ball flying from `from` to land on `to` after `t` s (lengthened until it clears the net).
func _launch(pl: Player, from: Vector3, to: Vector2, t: float, shot: int, q: float) -> void:
	ball.p = from
	ball.v = solve(from, to, t)
	last_team = pl.team
	crossed = false
	bounces = 0
	last_shot = shot
	last_q = q
	rally_hits += 1
	pl.hit_at = time
	pl.hit_q = q
	pl.cool = SWING_COOL
	stats["hits"] = int(stats["hits"]) + 1
	if pl.human:
		stats["your_hits"] = int(stats["your_hits"]) + 1
	if shot == Shot.SMASH:
		stats["smashes"] = int(stats["smashes"]) + 1
	if q >= 0.9 and shot != Shot.SERVE:
		stats["perfect"] = int(stats["perfect"]) + 1
	events.append(["hit", {"who": pl.idx, "team": pl.team, "shot": shot, "q": q, "p": from}])
	_plan(1 - pl.team)
	_home(pl.team, shot)


## The launch velocity from `from` to land on `to` after `t` s, `t` stretched until the ball clears
## the net's tape by 0.15 m.
static func solve(from: Vector3, to: Vector2, t: float) -> Vector3:
	var v := Vector3.ZERO
	for _i in 14:
		v = Vector3((to.x - from.x) / t, (to.y - from.y) / t, (0.5 * G * t * t - from.z) / t)
		if absf(v.x) < 0.01:
			return v
		var tc := (NET_X - from.x) / v.x
		if tc <= 0.0 or tc >= t:
			return v
		var zc := from.z + v.z * tc - 0.5 * G * tc * tc
		if zc > NET_H + 0.15:
			return v
		t += 0.08
	return v


## Hits the ball for `pl` with `shot` (the shot's target, flight time and scatter) at quality `q`.
func _hit(pl: Player, shot: int, q: float) -> void:
	var dir := 1.0 if pl.team == 0 else -1.0
	var from := ball.p
	if shot == Shot.DRIVE and absf(from.x - NET_X) < 3.2 and bounces == 0:
		shot = Shot.VOLLEY
	if shot == Shot.SMASH:
		pl.jump_v = 3.2
	var to := Vector2.ZERO
	var t := 0.8
	match shot:
		Shot.LOB:
			to = Vector2(NET_X + dir * rng.randf_range(7.4, 9.0), _open_y(pl.team, 0.5))
			t = rng.randf_range(1.6, 1.9)
		Shot.SMASH:
			to = Vector2(NET_X + dir * rng.randf_range(3.0, 5.5), _open_y(pl.team, 1.0))
			t = maxf(Vector2(from.x, from.y).distance_to(to) / (21.0 + 5.0 * q), 0.26)
		Shot.VOLLEY:
			to = Vector2(NET_X + dir * rng.randf_range(3.5, 7.2), _open_y(pl.team, 1.0))
			t = Vector2(from.x, from.y).distance_to(to) / (14.0 + 3.0 * q)
		_:
			to = Vector2(NET_X + dir * rng.randf_range(5.2, 8.2), _open_y(pl.team, 1.0))
			t = Vector2(from.x, from.y).distance_to(to) / (12.5 + 4.0 * q)
	if q >= 0.9:
		t *= 0.9
	var err: float = (1.0 - q) * float(SCATTER[shot])
	to += Vector2(rng.randfn(0.0, err), rng.randfn(0.0, err * 0.8))
	to.y = clampf(to.y, -1.5, WID + 1.5)
	serve_ball = false
	_launch(pl, from, to, maxf(t, 0.25), shot, q)


## The y on the far side most away from the two rivals (`spread` 0..1: how hard it tries).
func _open_y(team: int, spread: float) -> float:
	var best := WID * 0.5
	var best_d := -1.0
	for k in 7:
		var y := 1.4 + (WID - 2.8) * k / 6.0
		var d := INF
		for pl in players:
			if pl.team != team:
				d = minf(d, absf(pl.pos.y - y))
		d += rng.randf() * (1.0 - spread) * 4.0
		if d > best_d:
			best_d = d
			best = y
	return best


## Where `team` waits after hitting `shot` (to the net after an attack, back after a defence) and
## for the side not taking the ball.
func _home(team: int, shot: int) -> void:
	var dir := 1.0 if team == 0 else -1.0
	var up := shot in [Shot.LOB, Shot.VOLLEY, Shot.SMASH, Shot.DRIVE]
	for pl in players:
		if pl.team != team:
			continue
		var x := NET_X - dir * (3.4 if up else 7.2)
		pl.target = Vector2(x, 2.8 if pl.idx % 2 == 0 else 7.2)
		pl.planned = false


## Reads the ball for `team`: simulates its flight ahead and picks, for the player who can get there
## first, the spot to take it (a comfortable height after the bounce, a volley near the net, or a
## smash); the other covers. The AI's dice: a misjudged ball is chased but not hit.
func _plan(team: int) -> void:
	var b := ball.copy()
	var bn := 0
	var cr := false
	var cands: Array = []
	var t := 0.0
	var h := 1.0 / 60.0
	var team_side := false
	while t < 3.4:
		var ev := b.step(h)
		t += h
		if ev == "out":
			break
		if ev == "cross":
			cr = true
		if ev == "floor" and side_of(b.p.x) == team:
			bn += 1
			if bn >= 2:
				break
		if ev in ["glass", "mesh"] and side_of(b.p.x) == team and bn == 0 and cr:
			break
		if side_of(b.p.x) != team:
			if team_side:
				break
			continue
		team_side = true
		var z := b.p.z
		var ok := false
		var smash := false
		if bn == 1 and z > 0.25 and z < REACH_H:
			ok = true
		elif bn == 0 and not serve_ball:
			if z > 1.9 and z < JUMP_H - 0.1:
				ok = true
				smash = true
			elif z > 0.3 and z < REACH_H and absf(b.p.x - NET_X) < 4.5:
				ok = true
		if ok:
			cands.append([time + t, b.p, smash, absf(z - SWEET_Z)])
	var mates: Array[Player] = []
	for pl in players:
		if pl.team == team:
			mates.append(pl)
	var best_pl: Player = null
	var best_c: Array = []
	var best_score := INF
	for pl in mates:
		for c: Array in cands:
			var p: Vector3 = c[1]
			var need := Vector2(p.x, p.y).distance_to(pl.pos) / pl.speed + 0.12
			if need - REACH / pl.speed > float(c[0]) - time:
				continue
			# Prefer the earliest comfortable ball; the human takes the near half.
			var score := float(c[0]) - time + float(c[3]) * 0.6
			if pl.human and p.y < WID * 0.5:
				score -= 0.5
			if not pl.human and pl.team == 0 and p.y < WID * 0.5:
				score += 0.5
			if score < best_score:
				best_score = score
				best_pl = pl
				best_c = c
			break
	if best_pl == null and not cands.is_empty():
		# Nobody gets there in time: the nearest chases the last chance.
		var last: Array = cands[-1]
		var lp: Vector3 = last[1]
		var nd := INF
		for pl in mates:
			var d := pl.pos.distance_to(Vector2(lp.x, lp.y))
			if d < nd:
				nd = d
				best_pl = pl
				best_c = last
	for pl in mates:
		pl.planned = false
	if best_pl == null:
		return
	var bp: Vector3 = best_c[1]
	var dir := 1.0 if team == 0 else -1.0
	best_pl.planned = true
	best_pl.plan_p = bp
	best_pl.plan_t = float(best_c[0])
	best_pl.target = Vector2(bp.x - dir * 0.35, bp.y + (0.3 if bp.y < WID * 0.5 else -0.3))
	var chance := 0.55 + 0.42 * best_pl.skill - float(PRESSURE[last_shot]) * last_q
	best_pl.will_reach = (best_pl.human and not auto_human) or rng.randf() < chance
	if not best_pl.will_reach:
		best_pl.target += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.6, 1.6))
	for pl in mates:
		if pl != best_pl:
			pl.target = Vector2(NET_X - dir * 4.0, 7.2 if best_pl.pos.y < WID * 0.5 else 2.8)


# --- the players ------------------------------------------------------------------------------

func _players_step(dt: float) -> void:
	for pl in players:
		pl.cool = maxf(pl.cool - dt, 0.0)
		if pl.jump_v != 0.0 or pl.jump > 0.0:
			pl.jump_v -= G * 1.4 * dt
			pl.jump = maxf(pl.jump + pl.jump_v * dt, 0.0)
			if pl.jump <= 0.0:
				pl.jump_v = 0.0
		var want := Vector2.ZERO
		var manual := pl.human and not auto_human and _stick_idle < STICK_HOLD
		if manual:
			want = stick.limit_length(1.0) * pl.speed
		else:
			var to := pl.target - pl.pos
			var sp := pl.speed * (0.9 if pl.human else 1.0)
			if phase != Phase.PLAY:
				sp *= 0.6
			if to.length() > 0.08:
				want = to.normalized() * minf(sp, to.length() * 6.0)
		pl.vel = pl.vel.lerp(want, minf(dt * 12.0, 1.0))
		pl.pos += pl.vel * dt
		var lo := 0.3 if pl.team == 0 else NET_X + 0.35
		var hi := NET_X - 0.35 if pl.team == 0 else LEN - 0.3
		pl.pos = Vector2(clampf(pl.pos.x, lo, hi), clampf(pl.pos.y, 0.3, WID - 0.3))
		pl.run += pl.vel.length() * dt
		if pl.swing >= 0.0:
			pl.swing += dt
			if can_hit(pl, pl.swing_shot == Shot.DRIVE):
				_human_hit(pl)
			elif pl.swing > SWING_S:
				pl.swing = -1.0
				pl.cool = SWING_COOL
				events.append(["whiff", {"who": pl.idx}])
		elif phase == Phase.PLAY and (not pl.human or auto_human):
			_ai_tick(pl)


## True when `pl` can hit the ball now: it is live, on their side, theirs to play (bounced at most
## once, the serve only after its bounce), in reach; `smash` allows a jumping contact.
func can_hit(pl: Player, smash := true) -> bool:
	if phase != Phase.PLAY or not live or last_team == pl.team or pl.cool > 0.0:
		return false
	if side_of(ball.p.x) != pl.team or bounces > 1 or (serve_ball and bounces == 0):
		return false
	var z := ball.p.z
	if z < 0.12 or z > (JUMP_H if smash else REACH_H):
		return false
	return Vector2(ball.p.x, ball.p.y).distance_to(pl.pos) < REACH


## The timing's quality: the ball near the middle of the reach at the sweet height is 1.
func quality(pl: Player) -> float:
	var d := Vector2(ball.p.x, ball.p.y).distance_to(pl.pos) / REACH
	var hz := absf(ball.p.z - SWEET_Z) / 1.4
	if ball.p.z > REACH_H:
		hz = 0.15
	return clampf(1.0 - 0.55 * d - 0.6 * hz, 0.0, 1.0)


func _human_hit(pl: Player) -> void:
	var shot := pl.swing_shot
	if shot == Shot.DRIVE and ball.p.z > 1.85 and bounces == 0:
		shot = Shot.SMASH
	var q := quality(pl)
	pl.swing = -1.0
	_hit(pl, shot, q)


## The AI (rivals, partner, the human on autopilot): hits a planned ball when it is at a good height
## or about to get away, with a shot by the situation.
func _ai_tick(pl: Player) -> void:
	if not pl.planned or not pl.will_reach or not can_hit(pl):
		return
	var z := ball.p.z
	var good := z > 0.45 and z < 1.75
	var smash := z > 1.95 and bounces == 0
	var going := (bounces == 1 and ball.v.z < 0.0 and z < 0.55) or time > pl.plan_t + 0.05
	if not (good or smash or going):
		return
	var shot := Shot.DRIVE
	if smash:
		shot = Shot.SMASH if rng.randf() < 0.55 + pl.skill * 0.4 else Shot.LOB
	else:
		var at_net := 0
		for o in players:
			if o.team != pl.team and absf(o.pos.x - NET_X) < 4.0:
				at_net += 1
		var lob_p := 0.55 if at_net == 2 else (0.25 if at_net == 1 else 0.12)
		if absf(ball.p.x - NET_X) < 3.0:
			lob_p *= 0.3
		if rng.randf() < lob_p:
			shot = Shot.LOB
	var q := clampf(pl.skill * rng.randf_range(0.8, 1.25) - (0.15 if going else 0.0), 0.0, 1.0)
	_hit(pl, shot, q)
	if pl.human:
		pl.swing = -1.0
