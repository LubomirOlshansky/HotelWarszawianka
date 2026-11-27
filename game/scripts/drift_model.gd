extends RefCounted
## The drift model of Bokiem na Narodowym (docs/design/drift-narodowy.md 0b.2 as amended by
## critique-drift.md changes 2 and 9; the grey box, section 4): the slip angle is a state, not tyre
## physics. Pure and static: `step(state, input, line, params, dt)` moves a `State` along a
## drift_line.gd line; the same inputs give the same state (check_drift M9), so the bots and the
## checks run it without a scene and the stadium's car (drift_car.gd) is only posed from it.
##
## Angles in degrees, β + left (the nose turned left of the course); a proper drift has β on the
## bend's side. Modes: GRIP (no slide), DRIFT (the needle: gas grows |β|, a lift shrinks it), FLIP (a
## transition crossing zero, 0.6 s), WRONG (the slip is on the wrong side after a crossover: pulled
## back to zero, it ends in grip and the pile banks: change 2), SPIN (1.5 s round to a stop).
## Events (strings in `state.events`, read and cleared by drift_score.gd each step): "kick", "slow"
## (a kick under KICK_KMH), "nobend" (a kick with no bend in reach), "flick:<timing>", "nudge" (a
## kick in a drift outside the window: -5°), "bank", "wrong", "spin", "end".

enum Mode { GRIP, DRIFT, FLIP, WRONG, SPIN }

## A kick needs this speed (km/h).
const KICK_KMH := 30.0
## The kick opens |β| to this (°) with this time constant (s).
const KICK_DEG := 30.0
const KICK_TAU := 0.10
## The gas grows |β| at RATE × (1 + CURVE_GAIN × |κ|) °/s (0b.2).
const RATE := 25.0
const CURVE_GAIN := 15.0
## A lift shrinks |β| at this (°/s).
const LIFT_RATE := 40.0
## Under GRIP_DEG for GRIP_S s: grip, the pile banks.
const GRIP_DEG := 8.0
const GRIP_S := 0.4
## The transition window: from FLICK_BEFORE s before the sign change to FLICK_AFTER s after it.
const FLICK_BEFORE := 0.8
const FLICK_AFTER := 0.4
## A transition crosses zero in FLICK_S s and lands at KICK_DEG on the other side.
const FLICK_S := 0.6
## The flick's timing is 1.0 within this (s) of the sign change, 0.5 elsewhere in the window (change 9).
const FLICK_PERFECT := 0.15
## A kick in a drift outside the window takes this off |β| (°, 0b.2).
const NUDGE_DEG := 5.0
## The wrong side is pulled back at this (°/s, change 2).
const WRONG_RATE := 60.0
## Slow and deep spins too (m/s, °).
const SPIN_SLOW := 6.0
const SPIN_SLOW_DEG := 45.0
## A spin lasts this (s).
const SPIN_S := 1.5
## Speed (m/s): dv/dt = PUSH × gas × (1 - v / TOP) - SIDE_DRAG × v × sin|β| - COAST × (1 - gas).
const PUSH := 9.0
const TOP := 28.0
const SIDE_DRAG := 0.3
const COAST := 1.5
## The gas pedal's travel (s from off to full and back, 0b.3).
const GAS_S := 0.15

## The tunables the bots tune (critique section 3: "all numbers are guesses for the bots"). The
## sticky band is the assist (PEŁNA): inside it the gas grows |β| at `sticky` + `heat` × (chain - 1)
## of the rate, capped at 1 (change 9's heat: the bigger the pile, the livelier the car).
const DEFAULTS := {
	"band_lo": 25.0, "band_hi": 50.0, "sticky": 0.35, "heat": 0.08, "spin_deg": 75.0,
}


## The car on the line.
class State:
	extends RefCounted
	var s := 0.0
	var v := 0.0
	var beta := 0.0
	var mode := Mode.GRIP
	var gas := 0.0
	var t := 0.0
	## Seconds under GRIP_DEG in a drift; the kick's clock; the spin's clock and speed at its start.
	var grip_t := 0.0
	var kick_t := -1.0
	var kick_sign := 0
	var spin_t := 0.0
	var spin_v := 0.0
	var spin_from := 0.0
	## FLIP: where β goes and how fast (°/s).
	var flip_to := 0.0
	var flip_rate := 0.0
	var finished := false
	var events: PackedStringArray = []

	func copy() -> State:
		var c := State.new()
		for k in ["s", "v", "beta", "mode", "gas", "t", "grip_t", "kick_t", "kick_sign", "spin_t", "spin_v", "spin_from", "flip_to", "flip_rate", "finished"]:
			c.set(k, get(k))
		return c

	## A short text of the state, for the determinism check (M9) and --drift-log.
	func hash_text() -> String:
		return "%d|%.5f|%.5f|%.5f|%.4f|%.4f" % [mode, s, v, beta, gas, grip_t]


## One input frame: the thumb's gas (0 or 1, the pedal ramps to it), a kick on this frame, and the
## score's chain for the heat (drift_score.gd).
class Frame:
	extends RefCounted
	var gas := 0.0
	var kick := false
	var chain := 1


static func params(over: Dictionary = {}) -> Dictionary:
	var p := DEFAULTS.duplicate()
	p.merge(over, true)
	return p


## The gas rate at |β| on curvature κ with the chain's heat (°/s).
static func gas_rate(abs_beta: float, k: float, chain: int, p: Dictionary) -> float:
	var r := RATE * (1.0 + CURVE_GAIN * absf(k))
	if abs_beta >= float(p["band_lo"]) and abs_beta < float(p["band_hi"]):
		r *= minf(1.0, float(p["sticky"]) + float(p["heat"]) * float(maxi(chain, 1) - 1))
	return r


## In the transition window at s and v (the line's nearest sign change).
static func in_window(line: RefCounted, s: float, v: float) -> bool:
	var dt: float = line.flip_dt(s, v)
	return dt >= -FLICK_BEFORE and dt <= FLICK_AFTER


static func step(st: State, inp: Frame, line: RefCounted, p: Dictionary, dt: float) -> void:
	st.events.clear()
	if st.finished:
		return
	st.t += dt
	var target_gas := clampf(inp.gas, 0.0, 1.0)
	st.gas = move_toward(st.gas, target_gas, dt / GAS_S)
	if inp.kick and st.mode != Mode.SPIN:
		_kick(st, line)
	match st.mode:
		Mode.GRIP:
			st.beta = 0.0
		Mode.DRIFT:
			_drift(st, inp, line, p, dt)
		Mode.FLIP:
			st.beta = move_toward(st.beta, st.flip_to, st.flip_rate * dt)
			if is_equal_approx(st.beta, st.flip_to):
				st.mode = Mode.DRIFT
				st.grip_t = 0.0
		Mode.WRONG:
			st.beta = move_toward(st.beta, 0.0, WRONG_RATE * dt)
			if absf(st.beta) < GRIP_DEG:
				st.grip_t += dt
				if st.grip_t >= GRIP_S or st.beta == 0.0:
					_to_grip(st)
		Mode.SPIN:
			st.spin_t += dt
			var k := clampf(st.spin_t / SPIN_S, 0.0, 1.0)
			# Round to a full turn, slowing as it goes (ease out).
			st.beta = signf(st.spin_from) * lerpf(absf(st.spin_from), 360.0, 1.0 - (1.0 - k) * (1.0 - k))
			st.v = st.spin_v * (1.0 - k)
			if k >= 1.0:
				st.mode = Mode.GRIP
				st.beta = 0.0
				st.v = 0.0
	if st.mode != Mode.SPIN:
		var sb := sin(deg_to_rad(minf(absf(st.beta), 90.0)))
		var dv := PUSH * st.gas * (1.0 - st.v / TOP) - SIDE_DRAG * st.v * sb - COAST * (1.0 - st.gas)
		st.v = maxf(0.0, st.v + dv * dt)
		# Spins: too deep, or deep and slow.
		if st.mode == Mode.DRIFT and (absf(st.beta) > float(p["spin_deg"]) or (st.v < SPIN_SLOW and absf(st.beta) > SPIN_SLOW_DEG)):
			st.mode = Mode.SPIN
			st.spin_t = 0.0
			st.spin_v = st.v
			st.spin_from = st.beta
			st.events.append("spin")
	st.s += st.v * dt
	if st.s >= line.length:
		st.s = line.length
		st.finished = true
		st.events.append("end")


static func _kick(st: State, line: RefCounted) -> void:
	match st.mode:
		Mode.GRIP, Mode.WRONG:
			if st.v * 3.6 < KICK_KMH:
				st.events.append("slow")
				return
			var side: int = line.bend_ahead(st.s)
			if side == 0:
				st.events.append("nobend")
				return
			if st.mode == Mode.WRONG:
				return  # the wrong side ends in grip first (change 2: a new kick after the bank)
			st.mode = Mode.DRIFT
			st.kick_t = 0.0
			st.kick_sign = side
			st.grip_t = 0.0
			st.events.append("kick")
		Mode.DRIFT:
			if in_window(line, st.s, st.v):
				var to := -signf(st.beta) * KICK_DEG
				if to == 0.0:
					to = float(line.bend_sign(st.s + 1.0)) * KICK_DEG
				st.flip_to = to
				st.flip_rate = (absf(st.beta) + KICK_DEG) / FLICK_S
				st.mode = Mode.FLIP
				st.kick_t = -1.0
				var off := absf(line.flip_dt(st.s, st.v))
				st.events.append("flick:%.2f" % (1.0 if off <= FLICK_PERFECT else 0.5))
			else:
				st.beta = signf(st.beta) * maxf(0.0, absf(st.beta) - NUDGE_DEG)
				st.events.append("nudge")


static func _drift(st: State, inp: Frame, line: RefCounted, p: Dictionary, dt: float) -> void:
	var k: float = line.kappa_at(st.s)
	if st.kick_t >= 0.0:
		# The kick: |β| towards KICK_DEG on the bend's side (τ KICK_TAU), the thumb's gas waits for it.
		st.kick_t += dt
		var to := float(st.kick_sign) * KICK_DEG
		st.beta += (to - st.beta) * (1.0 - exp(-dt / KICK_TAU))
		if absf(st.beta) >= KICK_DEG - 0.5 or st.kick_t > 0.4:
			st.kick_t = -1.0
		return
	var side := signf(st.beta)
	if side == 0.0:
		side = float(line.bend_sign(st.s))
	var ab := absf(st.beta)
	ab += st.gas * gas_rate(ab, k, inp.chain, p) * dt - (1.0 - st.gas) * LIFT_RATE * dt
	ab = maxf(ab, 0.0)
	st.beta = side * ab
	# Change 2: the slip opposite to the bend past the window is the wrong side.
	var bend: int = line.bend_sign(st.s)
	if bend != 0 and int(side) != bend and ab > GRIP_DEG * 0.5 and not in_window(line, st.s, st.v):
		st.mode = Mode.WRONG
		st.grip_t = 0.0
		st.events.append("wrong")
		return
	if ab < GRIP_DEG:
		st.grip_t += dt
		if st.grip_t >= GRIP_S:
			_to_grip(st)
	else:
		st.grip_t = 0.0


static func _to_grip(st: State) -> void:
	st.mode = Mode.GRIP
	st.beta = 0.0
	st.grip_t = 0.0
	st.events.append("bank")


## The car's body yaw on the floor (rad): the course plus the slip.
static func body_yaw(st: State, line: RefCounted) -> float:
	return float(line.yaw_at(st.s)) + deg_to_rad(st.beta)


## Points on the floor: the car's centre, its nose and its tail (2 m each way along the body).
static func centre(st: State, line: RefCounted) -> Vector2:
	return line.at(st.s)


static func nose(st: State, line: RefCounted) -> Vector2:
	return line.at(st.s) + line.dir(body_yaw(st, line)) * 2.0


static func tail(st: State, line: RefCounted) -> Vector2:
	return line.at(st.s) - line.dir(body_yaw(st, line)) * 2.0
