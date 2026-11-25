extends RefCounted
## Beer pong at THE TAPCZAN (F's ask 2026-11-24, docs/design/tapczan-pub.md): the rules and the
## ball, pure (no nodes), so check_tapczan.gd plays whole games with a seed. beer_pong.gd draws it
## and reads the player's slingshot; this script decides everything.
##
## The table: L m long, W wide, the thrower at z = 0, the cups they aim at standing with the apex
## cup at z = FRONT (each side's cups are kept in that "seen by the thrower" frame; the view turns
## the player's own cups round). Six cups a side in a 3-2-1 triangle; at RERACK_AT cups left a side
## is re-racked once into a 2-1 triangle. Two balls a turn; two hits in one turn and the balls come
## back (another two). A ball that bounces on the table once and then drops in is a bounce shot: it
## takes two cups (the one hit and the nearest other). A ball that meets a rim spins round it and
## drops in (RIM_IN of the time) or pops out. Every cup the rival takes is a drink for the player,
## and each drink widens the sway of the player's aim (`sway`).
##
## The throw: a slingshot gives `lateral` (-1..1, the aim's sideways turn, YAW_MAX at the ends) and
## `power` (0..1, the launch speed between SPEED.x and SPEED.y) at a fixed ANGLE; `fly` integrates
## the ball at DT under gravity, checks the rims, the cups' sides and the table, and returns the
## outcome and the path to draw. The rivals aim with `aim_at` (the exact launch for a cup) and a
## scatter that shrinks with their skill. Cost: a throw is ~300 small steps, once per throw.

const L := 2.44
const W := 0.61
const CUP_R := 0.046
const CUP_H := 0.12
const BALL_R := 0.02
## Cup centres' spacing in the rack (m) and the apex cup's distance from the thrower's edge.
const GAP := 0.096
const FRONT := 2.06
## Where the ball leaves the hand (over the near edge, a little above the table).
const RELEASE := Vector3(0.0, 0.38, -0.15)
## The launch angle (rad, 48°) and the speed range (m/s) for power 0..1.
const ANGLE := 0.8378
const SPEED := Vector2(3.0, 5.4)
const YAW_MAX := 0.2
const G := 9.81
const DT := 1.0 / 120.0
## The share of rim spins that end in the cup: three in four (2026-11-25, tools/pong_calibrate.gd;
## was half, which left a decent player ~2 throws longer per game for the same odds).
const RIM_IN := 0.75
const CUPS := 6
const RERACK_AT := 3
const BALLS := 2
## The table's bounce: the vertical speed kept (reversed) and the horizontal speed kept.
const BOUNCE_UP := 0.38
const BOUNCE_ALONG := 0.7
## The player's aim sway (lateral units): sober, and added per drink.
const SWAY_BASE := 0.015
const SWAY_DRINK := 0.035
## A rival's scatter at skill 0 and skill 1 (lateral, power units).
const SCATTER_LO := Vector2(0.3, 0.15)
const SCATTER_HI := Vector2(0.015, 0.008)

## The cups standing on each side: [0] the player's (the rival aims at them), [1] the rival's;
## Vector2(x, z) in the thrower's frame.
var cups: Array = [[], []]
## Whose throw: 0 the player, 1 the rival.
var turn := 0
var balls_left := BALLS
var hits_turn := 0
var reracked := [false, false]
## Cups the rival has taken: the player's drinks this game.
var drinks := 0
## The player's throws so far (the dotted arc shows for the first two).
var throws := 0
## -1 while playing, else the side that won.
var winner := -1
## The rival: skill 0..1, and `late_skill` (Pani Gienia) once her own cups are re-racked.
var skill := 0.5
var late_skill := -1.0
var late := false
var rng := RandomNumberGenerator.new()


func _init(seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	reset()


func reset() -> void:
	cups = [rack(CUPS), rack(CUPS)]
	turn = 0
	balls_left = BALLS
	hits_turn = 0
	reracked = [false, false]
	drinks = 0
	throws = 0
	winner = -1
	late = false


## A rack of `n` cups (6: 3-2-1, 3: 2-1, else a row), the apex towards the thrower at FRONT.
static func rack(n: int) -> Array:
	var out: Array = []
	var dz := GAP * 0.866
	var rows := [1, 2, 3] if n == 6 else ([1, 2] if n == 3 else [n])
	for r in rows.size():
		var k: int = rows[r]
		for i in k:
			out.append(Vector2((i - (k - 1) * 0.5) * GAP, FRONT + r * dz))
	return out


## The launch velocity for a slingshot's `lateral` (-1..1) and `power` (0..1).
static func launch(lateral: float, power: float) -> Vector3:
	var yaw := clampf(lateral, -1.5, 1.5) * YAW_MAX
	var speed := lerpf(SPEED.x, SPEED.y, clampf(power, 0.0, 1.0))
	return Vector3(sin(yaw) * cos(ANGLE), sin(ANGLE), cos(yaw) * cos(ANGLE)) * speed


## The exact `lateral` and `power` that drop the ball into the cup at `target` (thrower's frame).
static func aim_at(target: Vector2) -> Vector2:
	var dx := target.x - RELEASE.x
	var dz := target.y - RELEASE.z
	var d := sqrt(dx * dx + dz * dz)
	var h := RELEASE.y - CUP_H
	var c := cos(ANGLE)
	var v := sqrt(G * d * d / (2.0 * c * c * (d * tan(ANGLE) + h)))
	var yaw := atan2(dx, dz)
	return Vector2(yaw / YAW_MAX, inverse_lerp(SPEED.x, SPEED.y, v))


## The player's aim sway at time `t` (s), as Vector2(lateral, power) offsets: it grows per drink.
func sway(t: float) -> Vector2:
	var amp := SWAY_BASE + SWAY_DRINK * drinks
	return Vector2(sin(t * 1.9) + 0.5 * sin(t * 3.3 + 1.0), 0.4 * sin(t * 1.3 + 2.0)) * amp / 1.5


## The outcomes `trace` returns (with the cup's index: code + 8 * (cup + 1)).
const R_MISS := 0
const R_CUP := 1
const R_BOUNCE := 2
const R_RIM_IN := 3
const R_RIM_OUT := 4
const RESULTS := ["miss", "cup", "bounce", "rim_in", "rim_out"]


## The ball's flight against `targets` (Vector2 cups) into `path` (filled in place, a point every
## two steps; no allocation once it has grown): returns the outcome code + 8 * (the cup's index + 1).
## `roll` decides a rim spin (below RIM_IN: in).
static func trace(vel: Vector3, targets: Array, roll: float, path: PackedVector3Array) -> int:
	var p := RELEASE
	var v := vel
	var prev := p
	var bounced := false
	path.resize(0)
	path.append(p)
	for step in 480:
		v.y -= G * DT
		p += v * DT
		if step % 2 == 1:
			path.append(p)
		# Across the rims' height going down: in, on a rim, or past.
		if prev.y > CUP_H and p.y <= CUP_H:
			var q := prev.lerp(p, (prev.y - CUP_H) / (prev.y - p.y))
			var flat := Vector2(q.x, q.z)
			for i in targets.size():
				var d := flat.distance_to(targets[i])
				if d < CUP_R - BALL_R * 0.5:
					path.append(Vector3(targets[i].x, CUP_H * 0.4, targets[i].y))
					return (R_BOUNCE if bounced else R_CUP) + 8 * (i + 1)
				if d < CUP_R + BALL_R:
					path.append(q)
					if roll < RIM_IN:
						return (R_BOUNCE if bounced else R_RIM_IN) + 8 * (i + 1)
					return R_RIM_OUT + 8 * (i + 1)
		# Into a cup's side below the rim: knocked off.
		if p.y < CUP_H and p.y > 0.0:
			for i in targets.size():
				if Vector2(p.x, p.z).distance_to(targets[i]) < CUP_R + BALL_R:
					return R_MISS
		# The table: one bounce; a second touch is a miss, off the end it falls.
		if p.y <= BALL_R and prev.y > BALL_R:
			if absf(p.x) < W * 0.5 and p.z > 0.0 and p.z < L:
				if bounced:
					return R_MISS
				bounced = true
				p.y = BALL_R
				v = Vector3(v.x * BOUNCE_ALONG, -v.y * BOUNCE_UP, v.z * BOUNCE_ALONG)
		if p.y < -0.9:
			break
		prev = p
	return R_MISS


## `trace` as a dictionary, once per throw: {"result": a name of RESULTS, "cup": the index (-1),
## "rim": it spun on a rim, "path": the points, "at": the last}.
static func fly(vel: Vector3, targets: Array, roll: float) -> Dictionary:
	var path := PackedVector3Array()
	var code := trace(vel, targets, roll, path)
	var res: int = code & 7
	var rim := res in [R_RIM_IN, R_RIM_OUT] or (res == R_BOUNCE and path.size() > 0 and path[path.size() - 1].y > CUP_H * 0.5)
	return {"result": RESULTS[res], "cup": (code >> 3) - 1, "rim": rim, "path": path, "at": path[path.size() - 1]}


## The player throws with the slingshot's `lateral` and `power` at time `t` (the sway is added).
## Returns `fly`'s result with "events" (see `_resolve`). Nothing when it is not their turn.
func throw_player(lateral: float, power: float, t: float) -> Dictionary:
	if turn != 0 or winner >= 0:
		return {}
	var s := sway(t)
	throws += 1
	var r := fly(launch(lateral + s.x, power + s.y), cups[1], rng.randf())
	return _resolve(0, r)


## The rival throws: picks a cup (front ones more often), aims at it and scatters by skill.
func throw_rival() -> Dictionary:
	if turn != 1 or winner >= 0:
		return {}
	var mine: Array = cups[0]
	var target: Vector2 = mine[rng.randi() % mine.size()]
	if rng.randf() < 0.5:
		for c: Vector2 in mine:
			if c.y < target.y:
				target = c
	var a := aim_at(target)
	var k := late_skill if late and late_skill >= 0.0 else skill
	var sc := SCATTER_LO.lerp(SCATTER_HI, clampf(k, 0.0, 1.0))
	var r := fly(launch(a.x + rng.randfn(0.0, sc.x), a.y + rng.randfn(0.0, sc.y)), mine, rng.randf())
	return _resolve(1, r)


## A throw's outcome on the cups and the turn. "events": what the view says, in order: one of
## "cup", "bounce", "rim_in", "rim_out", "miss"; then "drink" (the rival hit), "rerack",
## "late" (Pani Gienia stops pretending), "balls_back", "turn", "win".
func _resolve(side: int, r: Dictionary) -> Dictionary:
	var target := 1 - side
	var row: Array = cups[target]
	var res := str(r["result"])
	var ev: Array = [res]
	var taken := 0
	if res in ["cup", "rim_in", "bounce"]:
		var hit: Vector2 = row[int(r["cup"])]
		row.remove_at(int(r["cup"]))
		taken = 1
		if res == "bounce" and not row.is_empty():
			var near := 0
			for i in row.size():
				if (row[i] as Vector2).distance_to(hit) < (row[near] as Vector2).distance_to(hit):
					near = i
			row.remove_at(near)
			taken = 2
		hits_turn += 1
	if taken > 0 and side == 1:
		drinks += taken
		ev.append("drink")
	balls_left -= 1
	if row.is_empty():
		winner = side
		ev.append("win")
		r["events"] = ev
		return r
	if row.size() == RERACK_AT and not reracked[target]:
		reracked[target] = true
		cups[target] = rack(RERACK_AT)
		ev.append("rerack")
		if target == 1 and late_skill >= 0.0 and not late:
			late = true
			ev.append("late")
	if balls_left <= 0:
		if hits_turn >= BALLS:
			ev.append("balls_back")
		else:
			turn = 1 - turn
			ev.append("turn")
		balls_left = BALLS
		hits_turn = 0
	r["events"] = ev
	return r


## The predicted flight for the dotted arc (no sway, no spin decided), into `out` (reused).
func predict(lateral: float, power: float, out: PackedVector3Array) -> void:
	trace(launch(lateral, power), cups[1], 0.0, out)
