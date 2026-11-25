extends RefCounted
## Beer pong v2 "Rzut na raz" at THE TAPCZAN: the pure rules and the ball (docs/design/
## tapczan-pong-v2-physics-and-fun.md, section 2 and 5.2). A method-for-method port of the reference
## sim `docs/design/tapczan-pong-v2-physics-sim.py` (`Sim`, and `Bot` as `bot_*`): a deterministic
## 60 Hz sim driven by two booleans a tick, `finger` (down) and `low` (dragged down: the bounce
## shot). No nodes, no engine time, no Vector2 (the ring-is-the-truth rule needs 64-bit floats).
##
## Units: canvas px of the 216-row pixel canvas and seconds. Every throw is in the thrower's frame:
## x along the table towards the rack thrown at (0 = the first cup's centre in a full rack), y up
## from the table top. pong_match.gd mirrors the rival's throws.
##
## The one rule above the rest: the gold ring's offset from a cup's centre at the release is the
## only aim error; the launch is solved so the ball comes down through the mouth plane at the ring.
## From there it is physics the player can watch: lip spins and skips, table tocks, shoved cups.
##
## The rival's numbers come from data/tapczan.json (rivals: balls, sd, flick, swat, away_every,
## away_len, half, in_r, rim_r, wake_cups, wake_round, late{}, reset_after_hit, reset_busy,
## bonus_on_blank). The view drains `events` (Array of {"name": ..., more}) every frame.
##
## Cost: a few floats; nothing allocated in a tick but the events' small dictionaries. About 3 100
## ticks a match.

const HZ := 60
const DT := 1.0 / 60.0

# --- the table, the cups, the ball (addendum 2.3) ---
const G := 600.0
const BALL_R := 1.5
const HAND_X := -150.0
const HAND_Y := 34.0
const TABLE_LO := -190.0
const TABLE_HI := 93.0
const CUPS := 5
const PITCH := 14.0
const RIM_Y := 13.0
const CUP_HALF := 4.5
const IN_R := 2.0
const RIM_R := 5.5
const MIN_GAP := 9.0
const A_LOB := 64.0
const A_BOUNCE := 44.0
const E_TABLE := 0.62
const F_TABLE := 0.80
const E_CUP := 0.35
const E_SPENT := 0.30
const FLUKE_IN := 0.6
const V_REST := 35.0
const MAX_BOUNCES := 3
const MAX_FLIGHT := 3.0
const SLIDE_PER_V := 1.0 / 110.0
const SLIDE_MIN := 0.5
const SLIDE_MAX := 2.5

# --- the rim ---
const K_BOUNCE := 0.85
const SPIN_S := 0.50
const P_RIM_0 := 0.75
const P_RIM_S := 0.65
const P_RIM_SIDE := 0.08
const P_RIM_FLAT := 0.25
const SKIP_UP := 0.35
const SKIP_ON := 0.45
const SKIP_BACK := -0.25
const T_SPIN_0 := 0.50
const T_SPIN_S := 0.45
const FLICK_FIRST := 0.25
const FLICK_LAP := 0.40
const FLICK_HALF := 0.085

# --- the swing and the breath ---
const M_LO := 16.0
const M_HI := 12.0
const P_REF := 1.20
const A_REF := 42.0
const P_MIN := 0.80
const P_MAX := 1.45
const HOLD_SLOW := 0.40
const HOLD_RAMP := 0.60
const LUNG := 1.30
const LUNG_DRINK := 0.10
const LUNG_MIN := 0.70
const LUNG_BACK := 0.40
const GASP_V := 1.15
const GASP_WOB := 0.8
const SWEEP_V_DRINK := 0.05
const WOB_0 := 0.3
const WOB_DRINK := 0.8
const WOB_MAX := 5.0
const SHOT_CLOCK := 5.0

# --- the match ---
const BALLS := 2
const ROUNDS := 6
const SUDDEN := 3
const RERACK_AT := 2
const CLEAN_R := 0.8
const CLEAN_HEAT := 0.3
const HEAT_MAX := 3
const DARE_MIN_CUPS := 3
const T_INTRO := 2.0
const T_BANNER := 0.6
const T_BEAT := 0.45
const T_RIVAL_WIND := 0.5
const T_RERACK := 0.7
const T_HITSTOP := 0.07
const NUDGE_WARN := 0.4
const NUDGE_BUSY := 0.6

enum { AIM, FLIGHT, SPIN, WAIT, DONE }
const ME := 0
const THEM := 1
enum After { START_ROUND, NEXT_BALL, RIVAL_THROW }

## The bots (the prototype's thumbs): a release-time error (s), the flick chance, how much of the
## wobble they do not see, whether they read the rival's tells. `bot_*` below is `Bot.act`.
const THUMBS := {
	"novice": {"sd": 0.085, "flick": 0.35, "blind": 0.9, "tells": false},
	"decent": {"sd": 0.048, "flick": 0.60, "blind": 0.6, "tells": true},
	"expert": {"sd": 0.026, "flick": 0.85, "blind": 0.3, "tells": true},
}
const HABITS := {
	"novice": {"cup": "mid", "hold": "deep", "bounce": "never"},
	"decent": {"cup": "far", "hold": "deep", "bounce": "read"},
	"expert": {"cup": "dare", "hold": "even", "bounce": "read"},
}
const READ_SWAT := 0.3

static var LOB_VY := sqrt(2.0 * G * (A_LOB - HAND_Y))
static var LOB_T := (LOB_VY + sqrt(LOB_VY * LOB_VY + 2.0 * G * (HAND_Y - RIM_Y))) / G
static var BNC_VY := sqrt(2.0 * G * (A_BOUNCE - HAND_Y))
static var BNC_T1 := (BNC_VY + sqrt(BNC_VY * BNC_VY + 2.0 * G * (HAND_Y - BALL_R))) / G
static var BNC_T2 := _bnc_t2()

var rng := RandomNumberGenerator.new()
## The rival's table of numbers (data/tapczan.json), and its "late" (awake) part or {}.
var r: Dictionary = {}
var late: Dictionary = {}
## The cups each side DEFENDS (x in the thrower's frame) with a parallel id each, so the dare and
## the view's sprites follow a cup when its neighbours go.
var cups_me := PackedFloat64Array()
var cups_them := PackedFloat64Array()
var ids_me := PackedInt32Array()
var ids_them := PackedInt32Array()
var reracked: Array[bool] = [false, false]
var t := 0
var phase := WAIT
var wait := int(T_INTRO * HZ)
var after := After.START_ROUND
var round_no := 0
var sudden := 0
var sudden_hit: Array[bool] = [false, false]
var thrower := ME
var balls := 0
var back_used := false
var turn_takes := 0
var heat := 0
## Pints at the bar count; every cup lost adds one (the wobble and the lung).
var drinks := 0
## Cups the rival took: what the view reports as `drinks`.
var lost := 0
var took := 0
var awake := false
var busy_until := 0
var away_phase := 0.0
## The dared cup's id (-1: none).
var dare_id := -1
var karniak := false
## -1 playing, 0 you, 1 rival, 2 draw.
var winner := -1
## "clear", "lost", "bell", "sudden", "draw".
var end := ""
var ball_no := 0
var events: Array[Dictionary] = []
var stats: Dictionary = {}
## Keep every event in `events` until the view drains it (false: the check's long runs clear it).
var keep_events := true
## The check's hooks: where the ball's centre crossed the mouth plane going down on its last
## planned pass (after the bounce for a bounce shot; NAN before), and a forced roll (-1: the
## generator) for the spin's drop, the flick and the swat.
var mouth_x := NAN
var force_roll := -1.0

# the ball
var ball_live := false
var bx := 0.0
var by := 0.0
var bvx := 0.0
var bvy := 0.0
var b_low := false
var b_fresh := false
var b_bounces := 0
var b_age := 0
var b_aim := 0.0

# the aim
var phi := 0.0
var aim_t := 0
var held := 0.0
var lung := 0.0
var gasp := false
var armed := false
var was_down := false
var nudge_at := -1
var sweep_c := 0.0
var sweep_a := 1.0
var sweep_w := 1.0
var low := false

# the spin (spin_cup -1: none)
var spin_cup := -1
var spin_d := 0.0
var spin_s := 0.0
var spin_drop := false
var spin_left := 0
var spin_len := 0
var spin_age := 0
var spin_flicked := false
var spin_tapped := false
var spin_vx := 0.0

var _next_id := 0


static func _bnc_t2() -> float:
	var vy := sqrt(2.0 * G * (A_BOUNCE - HAND_Y))
	var t1 := (vy + sqrt(vy * vy + 2.0 * G * (HAND_Y - BALL_R))) / G
	var v_up := E_TABLE * (G * t1 - vy)
	return (v_up + sqrt(v_up * v_up - 2.0 * G * (RIM_Y - BALL_R))) / G


func _init(seed_value: int, rival: Dictionary, start_drinks := 0) -> void:
	rng.seed = seed_value
	r = rival
	late = r.get("late", {}) if r.get("late", {}) is Dictionary else {}
	for i in CUPS:
		cups_me.append(i * PITCH)
		ids_me.append(_new_id())
		cups_them.append(i * PITCH)
		ids_them.append(_new_id())
	drinks = start_drinks
	away_phase = rng.randf() * 3.0


func _new_id() -> int:
	_next_id += 1
	return _next_id


# ---- helpers ----

func _ev(name: String, more: Dictionary = {}) -> void:
	if keep_events:
		var e := more.duplicate() if not more.is_empty() else {}
		e["name"] = name
		events.append(e)
	stats[name] = int(stats.get(name, 0)) + 1


func rf(key: String, fallback := 0.0) -> float:
	return float(r.get(key, fallback))


## The numbers in force: the late (awake) set once woken, else the rival's own.
func cfg(key: String) -> float:
	if awake and not late.is_empty() and late.has(key):
		return float(late[key])
	return float(r.get(key, 0.0))


func xs(side: int) -> PackedFloat64Array:
	return cups_me if side == ME else cups_them


func ids(side: int) -> PackedInt32Array:
	return ids_me if side == ME else ids_them


func _put(side: int, x: PackedFloat64Array, i: PackedInt32Array) -> void:
	if side == ME:
		cups_me = x
		ids_me = i
	else:
		cups_them = x
		ids_them = i


## The x of the cup `id` on `side` (NAN when it is gone).
func cup_x(side: int, id: int) -> float:
	var k := ids(side).find(id)
	return xs(side)[k] if k >= 0 else NAN


## Eyes off the table (now, or `ahead` ticks on): no swat. The view shows the pose.
func rival_busy(ahead := 0) -> bool:
	var tt := t + ahead
	if tt < busy_until:
		return true
	if r.has("away_every"):
		return fmod(tt * DT + away_phase, rf("away_every")) < rf("away_len")
	return false


func wobble_amp() -> float:
	return minf(WOB_MAX, WOB_0 + WOB_DRINK * drinks) + (GASP_WOB if gasp else 0.0)


func wobble() -> float:
	var s := t * DT
	return wobble_amp() * (0.7 * sin(6.912 * s) + 0.3 * sin(16.96 * s + 1.0))


func ring_x() -> float:
	return sweep_c - sweep_a * cos(phi) + wobble()


func hold_factor() -> float:
	if gasp:
		return GASP_V
	return 1.0 - HOLD_SLOW * minf(held / HOLD_RAMP, 1.0)


func clean_r() -> float:
	return CLEAN_R + CLEAN_HEAT * heat


## The turn's full lung (for the bar's scale).
func lung_full() -> float:
	return maxf(LUNG_MIN, LUNG - LUNG_DRINK * drinks)


## Gienia's hand is on the table edge (the warning before the nudge is due).
func nudge_warned() -> bool:
	return nudge_at >= 0 and aim_t >= nudge_at - int(NUDGE_WARN * HZ)


# ---- the round ----

func _start_round() -> void:
	if sudden == 0 and round_no >= ROUNDS:
		_bell()
		return
	round_no += 1
	if not late.is_empty() and not awake and round_no >= int(rf("wake_round", 99)):
		_wake()
	_ev("round", {"n": round_no})
	thrower = ME
	balls = 1 if sudden else BALLS
	back_used = false
	turn_takes = 0
	lung = lung_full()
	dare_id = -1
	if cups_them.size() >= DARE_MIN_CUPS and not sudden:
		dare_id = ids_them[1 + rng.randi() % (cups_them.size() - 2)]
		_ev("dare", {"id": dare_id})
	_pause(T_BANNER, After.NEXT_BALL)


func _wake() -> void:
	awake = true
	_ev("wake")


func _pause(secs: float, then: int) -> void:
	phase = WAIT
	wait = maxi(1, roundi(secs * HZ))
	after = then


func _next_ball() -> void:
	if winner >= 0:
		return
	if balls <= 0:
		_end_turn()
		return
	balls -= 1
	ball_no += 1
	if thrower == ME:
		var lo := INF
		var hi := -INF
		for x in cups_them:
			lo = minf(lo, x)
			hi = maxf(hi, x)
		lo -= M_LO
		hi += M_HI
		var a := (hi - lo) * 0.5
		var period := clampf(P_REF * sqrt(a / A_REF), P_MIN, P_MAX) / (1.0 + SWEEP_V_DRINK * drinks)
		sweep_c = (lo + hi) * 0.5
		sweep_a = a
		sweep_w = TAU / period
		phi = 0.0
		aim_t = 0
		held = 0.0
		gasp = false
		armed = false
		nudge_at = -1
		if cfg("nudge") > 0.0 and rng.randf() < cfg("nudge_p"):
			nudge_at = int((0.6 + 0.8 * rng.randf()) * HZ)
		phase = AIM
	else:
		_pause(T_RIVAL_WIND, After.RIVAL_THROW)


func _end_turn() -> void:
	if thrower == ME:
		thrower = THEM
		var n := int(rf("balls", 2))
		if sudden:
			n = 1
		else:
			if bool(r.get("bonus_on_blank", false)) and turn_takes == 0:
				n += 1
				_ev("bonus")
			if karniak:
				n = maxi(1, n - 1)
		karniak = false
		balls = n
		turn_takes = 0
		_pause(T_BANNER, After.NEXT_BALL)
	elif sudden:
		var a := sudden_hit[ME]
		var b := sudden_hit[THEM]
		if a != b:
			_over(ME if a else THEM, "sudden")
			return
		if sudden >= SUDDEN:
			_over(2, "draw")
			return
		sudden += 1
		sudden_hit = [false, false]
		_start_round()
	else:
		_start_round()


func _bell() -> void:
	_ev("last_orders")
	var mine := cups_me.size()
	var theirs := cups_them.size()
	if mine != theirs:
		_over(ME if theirs < mine else THEM, "bell")
		return
	sudden = 1
	sudden_hit = [false, false]
	_ev("sudden")
	_start_round()


func _over(who: int, how: String) -> void:
	winner = who
	end = how
	phase = DONE
	_ev("over", {"winner": who, "how": how})


# ---- throws ----

## The ball leaves the hand so that it comes down through the mouth plane exactly at x_t: straight
## there (a lob), or after one bounce off the table (low).
func launch(x_t: float, is_low: bool) -> void:
	if is_low:
		bvx = (x_t - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
		bvy = BNC_VY
	else:
		bvx = (x_t - HAND_X) / LOB_T
		bvy = LOB_VY
	bx = HAND_X
	by = HAND_Y
	b_low = is_low
	b_fresh = true
	b_bounces = 0
	b_age = 0
	b_aim = x_t
	mouth_x = NAN
	ball_live = true
	phase = FLIGHT
	_ev("throw" if thrower == ME else "rival_throw", {"low": is_low, "aim": x_t})


func _rival_throw() -> void:
	var k := rng.randi() % cups_me.size()
	launch(cups_me[k] + rng.randfn(0.0, cfg("sd")), false)


func _aim_tick(finger: bool, is_low: bool) -> void:
	aim_t += 1
	if nudge_at >= 0:
		if aim_t == nudge_at - int(NUDGE_WARN * HZ):
			_ev("nudge_warn")
			busy_until = t + int((NUDGE_WARN + NUDGE_BUSY) * HZ)
		if aim_t == nudge_at:
			_nudge()
	if not finger and not was_down:
		armed = true
	if finger and armed:
		if lung > 0.0:
			held += DT
			lung -= DT
			if lung <= 0.0:
				lung = 0.0
				gasp = true
				_ev("gasp")
	var released := armed and was_down and not finger
	was_down = finger and armed
	if released:
		if nudge_at >= 0 and aim_t < nudge_at - int(NUDGE_WARN * HZ):
			nudge_at = -1
		low = is_low
		launch(ring_x(), is_low)
		return
	if aim_t >= int(SHOT_CLOCK * HZ):
		_ev("slip")
		was_down = false
		_ball_done()
		return
	phi += sweep_w * hold_factor() * DT


func _nudge() -> void:
	var d := cfg("nudge") * (1.0 if rng.randf() < 0.5 else -1.0)
	for i in cups_them.size():
		cups_them[i] += d
	nudge_at = -2
	_ev("nudge", {"d": d})


# ---- the ball ----

func _flight_tick() -> void:
	b_age += 1
	if thrower == ME and nudge_at >= 0:
		aim_t += 1
		if aim_t == nudge_at:
			_nudge()
	var rem := DT
	for _k in 8:
		var t_rim := _fall_time(RIM_Y)
		var t_tab := _fall_time(BALL_R)
		var st := minf(minf(t_rim, t_tab), rem)
		bx += bvx * st
		by += bvy * st - 0.5 * G * st * st
		bvy -= G * st
		rem -= st
		if st == t_rim and t_rim <= t_tab:
			by = RIM_Y
			if is_nan(mouth_x) and b_bounces == (1 if b_low else 0):
				mouth_x = bx
			if _at_mouth():
				return
			by = RIM_Y - 1e-6
		elif st == t_tab:
			by = BALL_R
			if _on_table():
				return
		_walls()
		if rem <= 1e-9:
			break
	if by < -30.0 or b_age > MAX_FLIGHT * HZ:
		_ball_done()


## Seconds until the ball's centre comes DOWN through `level` (INF if it does not).
func _fall_time(level: float) -> float:
	var disc := bvy * bvy + 2.0 * G * (by - level)
	if disc < 0.0:
		return INF
	var tt := (bvy + sqrt(disc)) / G
	return tt if tt > 1e-9 else INF


func _on_table() -> bool:
	if bx < TABLE_LO or bx > TABLE_HI:
		by = BALL_R - 1e-6
		return false
	b_bounces += 1
	var v_in := -bvy
	bvy = (E_TABLE if b_fresh else E_SPENT) * v_in
	bvx *= F_TABLE
	_ev("tock", {"v": v_in, "x": bx})
	if b_low and b_fresh and b_bounces == 1 and thrower == ME:
		if not rival_busy() and _roll() < cfg("swat"):
			_ev("swat", {"x": bx})
			_ball_done()
			return true
	if b_bounces > MAX_BOUNCES or bvy < V_REST:
		_ball_done()
		return true
	return false


func _walls() -> void:
	if by >= RIM_Y or by < BALL_R - 1e-3:
		return
	var reach := (rf("half", CUP_HALF) if thrower == ME else CUP_HALF) + BALL_R
	var side_t := 1 - thrower
	var cx := xs(side_t)
	var n := cx.size()
	for i in n:
		var c := cx[i]
		var d := bx - c
		if absf(d) >= reach:
			continue
		var side := (1.0 if d > 0.0 else -1.0) if absf(d) > reach - 1.6 else (-1.0 if bvx > 0.0 else 1.0)
		bx = c + side * (reach + 0.01)
		if bvx * side < 0.0:
			var push := clampf(absf(bvx) * SLIDE_PER_V, SLIDE_MIN, SLIDE_MAX) * -side
			var lo := cx[i - 1] + MIN_GAP if i > 0 else -40.0
			var hi := cx[i + 1] - MIN_GAP if i + 1 < n else TABLE_HI - 8.0
			var nx := minf(hi, maxf(lo, c + push))
			_ev("body", {"slide": nx - c, "clink": nx != c + push, "id": ids(side_t)[i], "side": side_t})
			bx += nx - c
			cx[i] = nx
			_put(side_t, cx, ids(side_t))
			bvx *= -E_CUP
		b_fresh = false
		return


## The ball's centre is on the mouth plane, going down. True when the flight ended here.
func _at_mouth() -> bool:
	var side_t := 1 - thrower
	var cx := xs(side_t)
	if cx.is_empty():
		return false
	var k := 0
	var best := INF
	for i in cx.size():
		var dd := absf(cx[i] - bx)
		if dd < best:
			best = dd
			k = i
	var cup := cx[k]
	var id := ids(side_t)[k]
	var d := bx - cup
	var a := absf(d)
	var in_r0 := rf("in_r", IN_R) if thrower == ME else IN_R
	var rim_r := rf("rim_r", RIM_R) if thrower == ME else RIM_R
	var kk := K_BOUNCE if b_bounces > 0 else 1.0
	var in_r := in_r0 * kk
	if not b_fresh and a <= in_r * FLUKE_IN:
		return _take(id, "fluke")
	if a <= in_r and b_fresh:
		if b_bounces > 0:
			return _take(id, "bounce_in")
		return _take(id, "clean" if a <= clean_r() * kk else "in")
	if a > rim_r:
		return false
	var s := (a - in_r) / (rim_r - in_r)
	if not b_fresh or s > SPIN_S:
		b_fresh = false
		if -bvy < 25.0:
			bx = cup + (rim_r + 0.05) * (1.0 if d > 0.0 else -1.0)
			return false
		bvy = SKIP_UP * -bvy
		bvx *= SKIP_ON if d > 0.0 else SKIP_BACK
		by = RIM_Y + 0.01
		_ev("rim_tick", {"side": 1 if d > 0.0 else -1, "id": id})
		return false
	var p := P_RIM_0 - P_RIM_S * s / SPIN_S + (P_RIM_SIDE if d > 0.0 else -P_RIM_SIDE) - P_RIM_FLAT * (1.0 - kk)
	p = clampf(p, 0.05, 0.95)
	var drop := _roll() < p
	var secs := T_SPIN_0 + T_SPIN_S * s / SPIN_S
	var flick := false
	if thrower == ME:
		flick = _roll() < cfg("flick") or id == dare_id
	spin_cup = id
	spin_d = d
	spin_s = s
	spin_drop = drop
	spin_left = int(secs * HZ)
	spin_len = spin_left
	spin_age = 0
	spin_flicked = flick
	spin_tapped = false
	spin_vx = bvx
	phase = SPIN
	_ev("rim", {"s": s, "side": 1 if d > 0.0 else -1, "id": id})
	return true


func _spin_tick(finger: bool) -> void:
	spin_age += 1
	if thrower == THEM and finger and not was_down and not spin_tapped:
		spin_tapped = true
		var ts := spin_age * DT
		var k := roundi((ts - FLICK_FIRST) / FLICK_LAP)
		if k >= 0 and absf(ts - (FLICK_FIRST + k * FLICK_LAP)) <= FLICK_HALF:
			spin_flicked = true
			spin_left = mini(spin_left, 2)
	was_down = finger
	spin_left -= 1
	if spin_left > 0:
		return
	var id := spin_cup
	spin_cup = -1
	was_down = false
	if spin_flicked:
		_ev("flicked", {"by": "them" if thrower == ME else "you"})
		_ball_done()
		return
	if spin_drop:
		_take(id, "rim_in")
		return
	_ev("rim_out")
	var side := 1.0 if spin_d > 0.0 else -1.0
	bx = cup_x(1 - thrower, id) + side * (RIM_R + 0.3)
	by = RIM_Y + 0.5
	bvx = side * 45.0 + 0.15 * spin_vx
	bvy = 55.0
	b_fresh = false
	phase = FLIGHT


## A ball is in cup `id`. how: clean, in, rim_in, bounce_in (worth the neighbour too), fluke.
func _take(id: int, how: String) -> bool:
	var side := 1 - thrower
	var cx := xs(side)
	var ci := ids(side)
	var i := ci.find(id)
	var n := 1
	var gone := [id]
	cx.remove_at(i)
	ci.remove_at(i)
	if how == "bounce_in" and not cx.is_empty():
		var j := i if i < cx.size() else i - 1
		gone.append(ci[j])
		cx.remove_at(j)
		ci.remove_at(j)
		n = 2
		_ev("domino")
	_put(side, cx, ci)
	_ev(how if thrower == ME else "rival_cup", {"n": n, "ids": gone, "how": how})
	turn_takes += n
	if thrower == ME:
		took += n
		heat = mini(HEAT_MAX, heat + n)
		if sudden:
			sudden_hit[ME] = true
		if id == dare_id:
			dare_id = -1
			karniak = true
			heat = HEAT_MAX
			_ev("karniak")
			if not back_used and not sudden:
				how = "clean"
		if how == "clean" and not back_used and not sudden:
			back_used = true
			balls += 1
			lung += LUNG_BACK
			_ev("back")
	else:
		lost += n
		drinks += n
		if sudden:
			sudden_hit[THEM] = true
	if cx.is_empty() and not sudden:
		ball_live = false
		_over(thrower, "clear" if thrower == ME else "lost")
		return true
	if sudden and cx.is_empty():
		cx.append(2.0 * PITCH)
		ci.append(_new_id())
		_put(side, cx, ci)
	if thrower == ME:
		if not late.is_empty() and not awake and cx.size() <= int(rf("wake_cups", 0)):
			_wake()
		if bool(r.get("reset_after_hit", false)) and cx.size() > 1:
			var pitch := 11.0 + 6.0 * rng.randf()
			var x0 := cx[0] - 4.0 + 10.0 * rng.randf()
			x0 = minf(x0, TABLE_HI - 10.0 - pitch * (cx.size() - 1))
			for j in cx.size():
				cx[j] = x0 + j * pitch
			_put(side, cx, ci)
			busy_until = t + int(rf("reset_busy") * HZ)
			_ev("reset")
	var extra := 0.0
	if cx.size() == RERACK_AT and not reracked[side] and not sudden:
		reracked[side] = true
		var mid := 2.0 * PITCH
		cx[0] = mid - PITCH * 0.5
		cx[1] = mid + PITCH * 0.5
		_put(side, cx, ci)
		extra = T_RERACK
		_ev("rerack", {"side": side})
	ball_live = false
	_pause((0.1 if n == 2 else T_HITSTOP) + T_BEAT + extra, After.NEXT_BALL)
	return true


func _roll() -> float:
	return force_roll if force_roll >= 0.0 else rng.randf()


func _ball_done() -> void:
	if thrower == ME:
		heat = 0
		_ev("miss")
	else:
		_ev("rival_miss")
	ball_live = false
	_pause(T_BEAT, After.NEXT_BALL)


## The one entry point: one 1/60 s.
func tick(finger := false, is_low := false) -> void:
	if phase == DONE:
		return
	t += 1
	match phase:
		WAIT:
			was_down = finger
			wait -= 1
			if wait <= 0:
				match after:
					After.START_ROUND:
						_start_round()
					After.NEXT_BALL:
						_next_ball()
					After.RIVAL_THROW:
						_rival_throw()
		AIM:
			_aim_tick(finger, is_low)
		FLIGHT:
			_flight_tick()
		SPIN:
			_spin_tick(finger)


## The aim preview: 12 points (x, y pairs, the thrower's frame) of the launch's parabola(s) from the
## hand to the mouth plane, then 1.0 at [24] if a bounce's hop runs into the front cup (else 0.0).
func preview(x_t: float, is_low: bool) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(25)
	var vx: float
	var vy: float
	if is_low:
		vx = (x_t - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
		vy = BNC_VY
		var xb := HAND_X + vx * BNC_T1
		for i in 6:
			var tt := BNC_T1 * (i + 1) / 6.0
			out[i * 2] = HAND_X + vx * tt
			out[i * 2 + 1] = HAND_Y + vy * tt - 0.5 * G * tt * tt
		var v_up := E_TABLE * (G * BNC_T1 - vy)
		for i in 6:
			var tt := BNC_T2 * (i + 1) / 6.0
			out[12 + i * 2] = xb + F_TABLE * vx * tt
			out[12 + i * 2 + 1] = BALL_R + v_up * tt - 0.5 * G * tt * tt
		out[24] = 1.0 if hop_blocked(x_t) else 0.0
	else:
		vx = (x_t - HAND_X) / LOB_T
		vy = LOB_VY
		for i in 12:
			var tt := LOB_T * (i + 1) / 12.0
			out[i * 2] = HAND_X + vx * tt
			out[i * 2 + 1] = HAND_Y + vy * tt - 0.5 * G * tt * tt
	return out


## A bounce aimed at x_t would meet the front standing cup's side on its hop (Bot._bounce_cup's test).
func hop_blocked(x_t: float) -> bool:
	if cups_them.is_empty():
		return false
	var front := cups_them[0]
	if x_t <= front + 0.5:
		return false
	var vx := F_TABLE * (x_t - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
	var xb := x_t - vx * BNC_T2
	var tt := (front - rf("half", CUP_HALF) - BALL_R - xb) / vx
	return not (tt > 0.0 and BALL_R + E_TABLE * (G * BNC_T1 - BNC_VY) * tt - 0.5 * G * tt * tt > RIM_Y + BALL_R + 1.0)


# ==== the bot: a port of the prototype's Bot.act (for auto_play and the check) ==================

var _b_th: Dictionary = {}
var _b_cup := "far"
var _b_hold := "deep"
var _b_bounce := "read"
## "" a thinking thumb, "masher" taps at a random moment, "idle" never touches.
var _b_mode := ""
var _b_rng := RandomNumberGenerator.new()
var _b_ball := -1
var _b_low := false
var _b_read := false
var _b_ref := -1
var _b_ref_x := 0.0
var _b_h := 0.0
var _b_noise := 0.0
var _b_holding := false
var _b_gbase := 0.0
var _b_gsign := 1.0
var _b_will := false
var _b_mash := -1
## The kind of the bot's last planned throw ("far", "near", "mid", "dare", "bounce").
var bot_kind := ""


## A thumb ("novice", "decent", "expert", "masher", "idle") with its habit or `policy`
## {cup: far|near|mid|dare|smart, hold: deep|even|none, bounce: never|always|read}.
func bot_setup(thumb: String, bot_seed: int, policy: Dictionary = {}) -> void:
	_b_rng.seed = bot_seed
	_b_mode = thumb if thumb in ["masher", "idle"] else ""
	_b_th = THUMBS.get(thumb, THUMBS["decent"])
	var hb: Dictionary = HABITS.get(thumb, HABITS["decent"])
	_b_cup = str(policy.get("cup", hb["cup"]))
	_b_hold = str(policy.get("hold", hb["hold"]))
	_b_bounce = str(policy.get("bounce", hb["bounce"]))
	_b_ball = -1


func _b_plan() -> void:
	_b_ball = ball_no
	var n := cups_them.size()
	_b_low = false
	_b_read = false
	if _b_bounce == "always":
		_b_low = true
	elif _b_bounce == "read" and n >= 2:
		_b_low = cfg("swat") <= READ_SWAT
		_b_read = not _b_low and bool(_b_th["tells"])
	var kind := "near" if _b_read else _b_cup
	if kind == "smart":
		kind = "dare" if (dare_id >= 0 and float(_b_th["sd"]) < 0.04 and not _b_low) else "far"
	if _b_low:
		_b_ref = _b_bounce_cup()
		bot_kind = "bounce"
	elif kind == "dare" and dare_id >= 0:
		_b_ref = dare_id
		bot_kind = "dare"
	elif kind == "near":
		_b_ref = ids_them[0]
		bot_kind = "near"
	elif kind == "mid" and n >= 3:
		_b_ref = ids_them[n / 2]
		bot_kind = "mid"
	else:
		_b_ref = ids_them[n - 1]
		bot_kind = "far"
	_b_ref_x = cup_x(THEM, _b_ref)
	var lg := lung - 0.12
	if _b_hold == "none" or lg < 0.15:
		_b_h = 0.0
	elif _b_hold == "even":
		_b_h = minf(lg / maxi(1, balls + 1), HOLD_RAMP + 0.1)
	else:
		_b_h = minf(lg, HOLD_RAMP + 0.1)
	_b_noise = _b_rng.randfn(0.0, float(_b_th["sd"]))
	_b_holding = false


## The furthest cup a bounce can reach over the ones in front (the first two or three): an id.
func _b_bounce_cup() -> int:
	var best := 0
	var n := cups_them.size()
	for k in range(1, mini(3, n)):
		var c := cups_them[k]
		var vx := F_TABLE * (c - HAND_X) / (BNC_T1 + F_TABLE * BNC_T2)
		var xb := c - vx * BNC_T2
		var tt := (cups_them[0] - rf("half", CUP_HALF) - BALL_R - xb) / vx
		if tt > 0 and BALL_R + E_TABLE * (G * BNC_T1 - BNC_VY) * tt - 0.5 * G * tt * tt > RIM_Y + BALL_R + 1.0:
			best = k
	return ids_them[0] if best == 0 else ids_them[mini(1, n - 1)]


## This tick's [finger, low] from the bot (call before `tick`).
func bot_finger() -> Array:
	if _b_mode == "idle":
		return [false, false]
	if _b_mode == "masher":
		if phase != AIM:
			return [false, false]
		if ball_no != _b_ball:
			_b_ball = ball_no
			_b_mash = int((0.3 + 1.2 * _b_rng.randf()) * HZ)
		return [aim_t == _b_mash, false]
	if phase == SPIN:
		if thrower == THEM and not spin_tapped:
			if spin_age == 0:
				_b_will = _b_rng.randf() < float(_b_th["flick"])
			return [_b_will and spin_age == int(FLICK_FIRST * HZ) - 1, false]
		return [false, false]
	if phase != AIM:
		return [false, false]
	if ball_no != _b_ball:
		_b_plan()
	if bool(_b_th["tells"]) and nudge_warned() and not _b_holding:
		return [false, _b_low]
	var c := sweep_c
	var a := sweep_a
	var w := sweep_w
	var x := cup_x(THEM, _b_ref)
	if not is_nan(x):
		_b_ref_x = x
	var want := _b_ref_x - (1.0 - float(_b_th["blind"])) * wobble()
	var cosv := clampf((c - want) / a, -1.0, 1.0)
	var p1 := acos(cosv)
	var lead: float
	if _b_h <= HOLD_RAMP:
		lead = w * (_b_h - HOLD_SLOW * _b_h * _b_h / (2.0 * HOLD_RAMP))
	else:
		lead = w * (_b_h * (1.0 - HOLD_SLOW) + HOLD_SLOW * HOLD_RAMP * 0.5)
	var track := maxf(lead, 0.25 * w)
	if not _b_holding:
		if not armed:
			return [false, _b_low]
		var base := floorf(phi / TAU) * TAU
		var goal := INF
		for k in 4:
			for q in 2:
				var g := base + k * TAU + (p1 if q == 0 else TAU - p1)
				if g - phi >= track - w * DT and g < goal:
					goal = g
					_b_gbase = base + k * TAU
					_b_gsign = 1.0 if q == 0 else -1.0
		if goal - phi > track + w * DT * 0.5:
			return [false, _b_low]
		_b_holding = true
	var goal2 := _b_gbase + (p1 if _b_gsign > 0.0 else TAU - p1)
	var t_go := (goal2 - phi) / (w * hold_factor())
	var lo := _b_low or (_b_read and rival_busy() and rival_busy(int(BNC_T1 * HZ) + 3))
	if _b_h <= 0.0:
		if was_down:
			if lo:
				bot_kind = "bounce"
			return [false, lo]
		return [t_go - DT <= -_b_noise, lo]
	if t_go <= -_b_noise and was_down:
		if lo:
			bot_kind = "bounce"
		return [false, lo]
	return [goal2 - phi <= lead + w * DT * 0.5 or was_down, lo]


## One whole match by the bot (the check, and nothing else): the sim at its end.
static func play_bot(rival: Dictionary, thumb: String, seed_value: int, start_drinks := 0, policy: Dictionary = {}) -> RefCounted:
	var s: RefCounted = (load("res://scripts/pong_sim.gd") as GDScript).new(seed_value, rival, start_drinks)
	s.keep_events = false
	s.bot_setup(thumb, seed_value * 7919 + 13, policy)
	while s.phase != DONE and s.t < 400 * HZ:
		var f: Array = s.bot_finger()
		s.tick(bool(f[0]), bool(f[1]))
	return s
