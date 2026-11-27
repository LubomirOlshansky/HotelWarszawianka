extends RefCounted
## The drift's bots (Bokiem na Narodowym, docs/design/drift-narodowy.md 0b.7 as amended by
## critique-drift.md change 3; the grey box, section 4). Pure and seeded: a bot is a thumb, it presses
## and releases a drift_input.gd at times of its own and sees only what a player sees (the angle, a
## little late; the line's bends and flick spots). `run` plays one whole run at 60 Hz with no scene,
## for check_drift.gd and for the stadium's `--drift=osemka:bot` (shots).
##   - "decent" (B1, the follower the qualifying line is set from): holds under NEEDLE°, lifts over it,
##     REACT s late, kicks at the first chance, flicks both crossovers with a timing error σ 80 ms.
##   - "clumsy" (B2): the same with σ 200 ms, eyes 0.35 s late and a needle that wanders.
##   - "pulse": one kick at the first chance, then a fixed hold / lift clock, eyes shut.
##   - "cycle" (B3, the PR review): eyes shut from the start: the gas held CYCLE_FROM s, then from a
##     start phase a fixed cycle of tap 0.1 s, gap 0.1 s, hold H, lift L, over and over: a blind
##     rhythm that kicks again every cycle.
##   - "hold" (B4): the gas held to the end, kicking again whenever it is back in grip.
##   - "bank" (B5): the decent bot that banks before each crossover and kicks again after it.
##   - "none" (B6): the gas held, never a kick.

const DriftModel := preload("res://scripts/drift_model.gd")
const DriftScore := preload("res://scripts/drift_score.gd")
const DriftInput := preload("res://scripts/drift_input.gd")

const HZ := 60.0
## The decent bot's needle (°) and how late its eyes are (s).
const NEEDLE := 42.0
const REACT := 0.2
## The eyes' lateness wobbles by this (s, σ, a new value about twice a second): a thumb is not a
## clock, so a deep needle overshoots into a spin in some seeds, not in all or none (the review's B7).
const REACT_SIGMA := 0.05
## The clumsy bot: σ 200 ms on its flicks (0b.7), eyes 0.35 s late and a needle that wanders by 6°
## (σ, a new aim about once a second): a thumb that overshoots into spins now and then.
const CLUMSY_SIGMA := 0.2
const CLUMSY_REACT := 0.35
const CLUMSY_WANDER := 6.0
## A run gives up after this (s, 0b.2).
const RUN_LIMIT := 45.0
## A tap-tap from a hold: lift, tap, press (the press kicks): its edges after the start (s).
const TAPTAP := [0.0, 0.10, 0.20, 0.33]
## The cycle bot: the gas held this long first (s), then tap and gap (s) before each hold.
const CYCLE_FROM := 2.5
const CYCLE_TAP := 0.1
const CYCLE_GAP := 0.1

var kind := "decent"
var rng := RandomNumberGenerator.new()
## The timing error of a flick (s, σ), the eyes' lateness (s), the needle and its wander (°).
var sigma := 0.08
var react := REACT
var needle := NEEDLE
var wander := 0.0
## The pulse and cycle bots' clock: hold, lift (s); the cycle's start phase (0-1 of a cycle).
var hold_s := 1.0
var lift_s := 0.4
var phase := 0.0

var _queue: Array = []
var _seen: Array[float] = []
var _kicks := 0
var _flip_aim := INF
var _flip_err := 0.0
var _pulse_t := 0.0
var _banking := false
var _banked_for := INF
var _needle_now := NEEDLE
var _jit := 0.0


static func make(bot_kind: String, run_seed: int, hold := 1.0, lift := 0.4, start_phase := 0.0, needle_deg := NEEDLE) -> RefCounted:
	var b := new()
	b.kind = bot_kind
	b.rng.seed = run_seed
	b.hold_s = hold
	b.lift_s = lift
	b.phase = start_phase
	b.needle = needle_deg
	match bot_kind:
		"clumsy":
			b.sigma = CLUMSY_SIGMA
			b.react = CLUMSY_REACT
			b.wander = CLUMSY_WANDER
	b._needle_now = b.needle
	return b


## This frame's edges for the thumb `inp` at time t (s), from what the bot sees of `st`.
func tick(t: float, st: DriftModel.State, line: RefCounted, inp: DriftInput) -> void:
	_seen.append(absf(st.beta))
	if rng.randf() < 2.0 / HZ:
		_jit = clampf(rng.randfn(0.0, REACT_SIGMA), -0.1, 0.15)
	var lag := int(round(maxf(0.0, react + _jit) * HZ))
	var seen: float = _seen[maxi(0, _seen.size() - 1 - lag)]
	if _seen.size() > 120:
		_seen.remove_at(0)
	if not _queue.is_empty():
		while not _queue.is_empty() and float(_queue[0][0]) <= t + 1e-6:
			var e: Array = _queue.pop_front()
			if bool(e[1]):
				inp.press(t)
			else:
				inp.release(t)
		return
	if kind == "cycle":
		_cycle(t, inp)
		return
	var grip := st.mode == DriftModel.Mode.GRIP
	var drifting := st.mode == DriftModel.Mode.DRIFT
	# The kick: at the first chance (the pulse bot once only; "none" never).
	if grip and kind != "none" and not (kind == "pulse" and _kicks > 0):
		if st.v * 3.6 >= DriftModel.KICK_KMH + 1.0 and line.bend_ahead(st.s + st.v * 0.35) != 0:
			_tap_tap(t + maxf(0.0, rng.randfn(0.0, sigma * 0.5)), inp)
			_kicks += 1
			return
	match kind:
		"none", "hold":
			_hold(inp, t, true)
			return
		"pulse":
			if grip and _kicks == 0:
				_hold(inp, t, true)
				return
			_pulse_t += 1.0 / HZ
			var cyc := fmod(_pulse_t, hold_s + lift_s)
			_hold(inp, t, cyc < hold_s)
			return
	# decent, clumsy, bank: the flick, the bank, the needle.
	if drifting:
		var f: float = line.flip_near(st.s)
		var to_f := (f - st.s) / maxf(st.v, 1.0) if f != INF else INF
		if kind == "bank":
			var seg: Dictionary = line.segments[line.segment_at(st.s)]
			if f != INF and f >= float(seg["s0"]) and f <= float(seg["s1"]) and st.s < f and _banked_for != f:
				_banking = true
				_banked_for = f
		elif to_f != INF and to_f > 0.0 and to_f < 2.0:
			if _flip_aim != f:
				_flip_aim = f
				_flip_err = rng.randfn(0.0, sigma)
			if to_f + _flip_err <= TAPTAP[3] + 0.5 / HZ:
				_tap_tap(t, inp)
				return
	if grip:
		_banking = false
	if _banking:
		_hold(inp, t, false)
		return
	if not drifting:
		_hold(inp, t, true)
		return
	if wander > 0.0 and rng.randf() < 1.0 / HZ:
		_needle_now = needle + rng.randfn(0.0, wander)
	_hold(inp, t, seen < _needle_now)


## The blind cycle: tap, gap, hold, lift from its phase, whatever the car does.
func _cycle(t: float, inp: DriftInput) -> void:
	if t < CYCLE_FROM:
		_hold(inp, t, true)
		return
	var period := CYCLE_TAP + CYCLE_GAP + hold_s + lift_s
	var c := fmod(t - CYCLE_FROM + phase * period, period)
	_hold(inp, t, c < CYCLE_TAP or (c >= CYCLE_TAP + CYCLE_GAP and c < CYCLE_TAP + CYCLE_GAP + hold_s))


func _hold(inp: DriftInput, t: float, on: bool) -> void:
	if on and not inp.down:
		inp.press(t)
	elif not on and inp.down:
		inp.release(t)


## Queue a tap-tap whose kicking press lands TAPTAP[3] s after `at` (from a hold the lift comes first).
func _tap_tap(at: float, inp: DriftInput) -> void:
	_queue.clear()
	if inp.down:
		_queue.append([at + TAPTAP[0], false])
	_queue.append([at + TAPTAP[1], true])
	_queue.append([at + TAPTAP[2], false])
	_queue.append([at + TAPTAP[3], true])


## One whole run of `bot_kind` with `run_seed` on `line` (60 Hz, no scene): the score, the time, the
## spins, the flicks, the banks, the losses, the zones, the cards and the mean speed.
static func run(bot_kind: String, run_seed: int, line: RefCounted, p: Dictionary, hold := 1.0, lift := 0.4, score_over := {}, start_phase := 0.0, needle_deg := NEEDLE) -> Dictionary:
	var bot: RefCounted = make(bot_kind, run_seed, hold, lift, start_phase, needle_deg)
	var st := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	for k: String in score_over:
		sc.set(k, score_over[k])
	var inp := DriftInput.new()
	var fr := DriftModel.Frame.new()
	var dt := 1.0 / HZ
	var t := 0.0
	var v_sum := 0.0
	var n := 0
	var max_beta := 0.0
	while not st.finished and t < RUN_LIMIT:
		bot.tick(t, st, line, inp)
		fr.gas = inp.gas()
		fr.kick = inp.take_kick()
		fr.chain = sc.chain
		DriftModel.step(st, fr, line, p, dt)
		DriftScore.tick(sc, st, line, dt)
		t += dt
		v_sum += st.v
		n += 1
		if st.mode != DriftModel.Mode.SPIN:
			max_beta = maxf(max_beta, absf(st.beta))
	if not st.finished:
		DriftScore.bank(sc)  # the run's end while drifting banks (0b.2)
	return {"total": sc.total, "time": t, "finished": st.finished, "spins": sc.spins, "flicks": sc.flicks,
			"banks": sc.banks, "losses": sc.losses, "zones": sc.zones_done.size(), "cards": sc.cards.duplicate(),
			"kmh": v_sum / maxf(1.0, float(n)) * 3.6, "kicks": inp.kicks, "drift_s": sc.drift_s, "max_beta": max_beta}
