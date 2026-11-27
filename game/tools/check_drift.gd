extends SceneTree
## Bokiem na Narodowym, the grey box (docs/design/drift-narodowy.md 0b.7 as amended by
## critique-drift.md change 3; section 4 scopes the first PR to M, I, S, B). No scene, no map: the
## pure scripts (drift_model, drift_score, drift_input, drift_line, drift_bot) at 60 Hz. Checks that:
## - M (the model): M1 a kick at 60 km/h on r 25 m reaches |β| 25-40° by 0.35 s; M2 a kick under 30 km/h
##   gives no drift; M3 the gas held from 30° reaches 50° and spins no sooner than M3_SWEEPER on the
##   sweeper (r 24 m, change 3) and M3_HAIRPIN on the hairpin (r 18 m, the PR review); M4 a lift from
##   40°: under 8° by 0.9 s, grip and banked by 1.3 s; M5 a transition inside the window lands 20° or
##   more on the other side by 0.7 s, outside it a tap-tap does nothing (change 10); M6 with no assist
##   (sticky 1, spin 70°) the gas held spins before 2.5 s and stops 1.5 s after; M8 the decent bot
##   holds 50-75 km/h on the sweeper; M9 the same inputs twice give the same state; M10 10,000 random
##   frames give no NaN; M11 car.gd names no drift script; W (change 2) a drift held on the old side
##   past the sign change is the wrong side once the window closes (0.5 + FLICK_AFTER s), scores
##   nothing from the sign change on, is pulled back, banked, the chain ×1;
## - I (the thumb): I1 tap 0.1 s, gap 0.15 s, press: a kick on the second press, gas held after; I2 a
##   0.3 s press is no tap; I3 a 0.35 s gap is no kick; I4 a long hold, then tap-tap kicks; I5 a second
##   finger is ignored; I6 three dabs of 0.15 s are one kick, the gas follows them, and in a drift
##   outside the window that kick changes nothing;
## - S (the score): S1 A(β) and the points a second at known values (change 1); S2 the chain: the
##   clock to CHAIN_CAP, each flick +1 and the cap one higher up to FLICK_CAP; S3 a bank adds the pile
##   and resets the chain; S4 a spin loses the pile and leaves the total; S5 no points under 8 m/s of
##   progress, past 6 m off or backwards; S6 ZONA and KLIP pay per metre at 1.5 m and 35° or more, their
##   name said once; S7 the run's end while drifting banks everything, its own step's points too;
## - B (the bots on Ósemka, SEEDS seeds each; change 3: the lines come from the bots): Q_LINE is
##   Q_SHARE of the decent (follower) bot's median; B1 the decent bot passes it in B1_RATE of seeds;
##   B2 the clumsy one passes in a band; B3 (the review) every blind cycle (tap 0.1 s, gap 0.1 s, hold
##   0.2-2.0 s, lift 0.1-0.8 s, CYCLE_PHASES start phases) scores under PULSE_MAX of Q_LINE; B4 the gas
##   held, kicking again after each grip, spins every run and scores under 40 % of Q_LINE; B5 banking at
##   both crossovers scores 55-75 % of the follower; B6 no kick scores 0; B7 the follower at a 55°
##   needle spins in DEEP_SPIN_MIN of seeds or more; B9 the follower's runs last 28-40 s.
##   godot --headless --path game --script res://tools/check_drift.gd

const DriftLine := preload("res://scripts/drift_line.gd")
const DriftModel := preload("res://scripts/drift_model.gd")
const DriftScore := preload("res://scripts/drift_score.gd")
const DriftInput := preload("res://scripts/drift_input.gd")
const DriftBot := preload("res://scripts/drift_bot.gd")

const DT := 1.0 / 60.0
const SEEDS := 32
const Q_SHARE := 0.55
const B1_RATE := 0.875
const B2_BAND := Vector2(0.25, 0.75)
const PULSE_MAX := 0.60
const HOLD_MAX := 0.40
const BANK_BAND := Vector2(0.55, 0.75)
const TIME_BAND := Vector2(28.0, 40.0)
## M3's floors (s to 50°, s to the spin) on the sweeper (change 3) and the hairpin (the review).
const M3_SWEEPER := Vector2(1.3, 1.9)
const M3_HAIRPIN := Vector2(1.15, 1.65)
## B3's grid: hold 0.2-2.0 s by 0.1, lift 0.1-0.8 s by 0.05, CYCLE_PHASES start phases.
const CYCLE_PHASES := 10
## B7: the follower pushed to a 55° needle spins in this share of seeds or more (the review: depth
## must carry risk).
const DEEP_NEEDLE := 55.0
const DEEP_SPIN_MIN := 0.15

var fails: Array[String] = []
var osemka: RefCounted
var p: Dictionary = DriftModel.params()


func _init() -> void:
	osemka = DriftLine.load_track("osemka")
	if osemka == null:
		print("check_drift: no track")
		quit(1)
		return
	_line()
	_model()
	_input()
	_score()
	_bots()
	if fails.is_empty():
		print("check_drift: OK")
		quit(0)
	else:
		for f in fails:
			print("check_drift: PROBLEM " + f)
		print("check_drift: %d problems" % fails.size())
		quit(1)


func _fail(what: String) -> void:
	fails.append(what)


## A test line: a straight of `run_in` m into an arc of radius r (sweep deg, a left bend), or two
## opposite bends joined by a straight (a crossover) with `cross`.
func _test_line(r: float, run_in := 40.0, cross := 0.0) -> RefCounted:
	var segs: Array = [{"straight": run_in}, {"arc": [r, 300.0, 1]}]
	if cross > 0.0:
		segs = [{"straight": run_in}, {"arc": [r, 90.0, 1]}, {"straight": cross}, {"arc": [r, 300.0, -1]}]
	var ln := DriftLine.new()
	ln.key = "test"
	ln.build({"start": [0.0, 0.0], "yaw": 0.0, "segments": segs})
	return ln


func _frame(gas: float, kick := false, chain := 1) -> DriftModel.Frame:
	var f := DriftModel.Frame.new()
	f.gas = gas
	f.kick = kick
	f.chain = chain
	return f


## A state at s on ln at speed v (m/s) in DRIFT at beta (° on the bend's side).
func _drifting(ln: RefCounted, s: float, v: float, beta: float) -> DriftModel.State:
	var st := DriftModel.State.new()
	st.s = s
	st.v = v
	st.gas = 1.0
	st.mode = DriftModel.Mode.DRIFT
	st.beta = beta * float(ln.bend_sign(s))
	return st


# --- the line -------------------------------------------------------------------------------------

func _line() -> void:
	var ln: RefCounted = osemka
	# The figure eight's geometry: about 450 m, both crossovers flick, zones on their boards.
	if ln.length < 420.0 or ln.length > 500.0:
		_fail("line: Ósemka is %.0f m (420-500)" % ln.length)
	if ln.flips.size() != 2:
		_fail("line: %d flick spots (2)" % ln.flips.size())
	if ln.zones.size() != 5:
		_fail("line: %d zones (5)" % ln.zones.size())
	for i in ln.pos.size():
		var q: Vector2 = ln.pos[i]
		if absf(q.x) > 70.0 or absf(q.y) > 40.0:
			_fail("line: sample %d at %s is off the floor" % [i, str(q)])
			break
	var pr: Vector2 = ln.project(ln.at(100.0) + DriftLine.left(ln.yaw_at(100.0)) * 3.0)
	if absf(pr.x - 100.0) > 0.6 or absf(pr.y - 3.0) > 0.1:
		_fail("line: project gives %s for s 100, 3 m left" % str(pr))
	print("check_drift: line Ósemka %.1f m, flicks at %s, %d kick boxes, %d zones" % [ln.length, str(ln.flips), ln.kick_boxes.size(), ln.zones.size()])


# --- M: the model ---------------------------------------------------------------------------------

func _model() -> void:
	var r25 := _test_line(25.0)
	# M1
	var st := DriftModel.State.new()
	st.s = 30.0
	st.v = 60.0 / 3.6
	st.gas = 1.0
	var t := 0.0
	DriftModel.step(st, _frame(1.0, true), r25, p, DT)
	t += DT
	while t < 0.35 - 1e-6:
		DriftModel.step(st, _frame(1.0), r25, p, DT)
		t += DT
	if absf(st.beta) < 25.0 or absf(st.beta) > 40.0:
		_fail("M1: a kick at 60 km/h reached %.1f° by 0.35 s (25-40)" % absf(st.beta))
	# M2
	st = DriftModel.State.new()
	st.s = 30.0
	st.v = 25.0 / 3.6
	DriftModel.step(st, _frame(1.0, true), r25, p, DT)
	var slow := "slow" in st.events
	for i in 59:
		DriftModel.step(st, _frame(1.0), r25, p, DT)
	if absf(st.beta) >= 5.0 or not slow:
		_fail("M2: a kick at 25 km/h gave %.1f° at 1 s (under 5, ZA WOLNO said: %s)" % [absf(st.beta), str(slow)])
	# M3: the gas held from 30°, sweeper (r 24) and hairpin (r 18).
	for r in [24.0, 18.0]:
		var ln := _test_line(r)
		st = _drifting(ln, 45.0, 15.0, 30.0)
		var t50 := -1.0
		var tspin := -1.0
		t = 0.0
		while t < 4.0 and tspin < 0.0:
			DriftModel.step(st, _frame(1.0), ln, p, DT)
			t += DT
			if t50 < 0.0 and absf(st.beta) >= 50.0:
				t50 = t
			if st.mode == DriftModel.Mode.SPIN:
				tspin = t
		print("check_drift: M3 r %.0f m: 50° at %.2f s, spin at %.2f s" % [r, t50, tspin])
		var lo := M3_SWEEPER if r == 24.0 else M3_HAIRPIN
		if t50 < lo.x or tspin < lo.y:
			_fail("M3: r %.0f m reached 50° at %.2f s (>= %.2f) and spun at %.2f s (>= %.2f)" % [r, t50, lo.x, tspin, lo.y])
	# M4: a lift from 40°.
	st = _drifting(r25, 45.0, 15.0, 40.0)
	var t8 := -1.0
	var tg := -1.0
	t = 0.0
	var banked := false
	while t < 2.0 and tg < 0.0:
		DriftModel.step(st, _frame(0.0), r25, p, DT)
		t += DT
		if t8 < 0.0 and absf(st.beta) < 8.0:
			t8 = t
		if "bank" in st.events:
			banked = true
		if st.mode == DriftModel.Mode.GRIP:
			tg = t
	if t8 < 0.0 or t8 > 0.9 + DT or tg < 0.0 or tg > 1.3 + DT or not banked:
		_fail("M4: a lift from 40°: under 8° at %.2f s (<= 0.9), grip at %.2f s (<= 1.3), banked %s" % [t8, tg, str(banked)])
	# M5: a transition in the window, and one outside it.
	var cr := _test_line(25.0, 40.0, 40.0)
	var f: float = cr.flips[0]
	st = _drifting(cr, f - 0.3 * 15.0, 15.0, 35.0)
	var before := signf(st.beta)
	DriftModel.step(st, _frame(1.0, true), cr, p, DT)
	var flicked := st.mode == DriftModel.Mode.FLIP
	t = DT
	while t < 0.7 - 1e-6:
		DriftModel.step(st, _frame(1.0), cr, p, DT)
		t += DT
	if not flicked or signf(st.beta) == before or absf(st.beta) < 20.0:
		_fail("M5: a flick in the window: FLIP %s, %.1f° at 0.7 s (20 or more, the other side)" % [str(flicked), st.beta])
	# Change 10: outside the window a tap-tap does nothing (no flip, no trim).
	st = _drifting(cr, f - 1.5 * 15.0, 15.0, 35.0)
	var twin := st.copy()
	DriftModel.step(st, _frame(1.0, true), cr, p, DT)
	DriftModel.step(twin, _frame(1.0), cr, p, DT)
	if st.mode != DriftModel.Mode.DRIFT or absf(st.beta - twin.beta) > 1e-4 or not st.events.is_empty():
		_fail("M5: a kick 1.5 s before the flick spot did something (mode %d, %.2f° against %.2f°, %s)" % [st.mode, st.beta, twin.beta, str(st.events)])
	# M6: no assist.
	var brak := DriftModel.params({"sticky": 1.0, "heat": 0.0, "spin_deg": 70.0})
	st = DriftModel.State.new()
	st.s = 30.0
	st.v = 15.0
	st.gas = 1.0
	DriftModel.step(st, _frame(1.0, true), r25, brak, DT)
	t = DT
	var spun := -1.0
	var stopped := -1.0
	while t < 5.0 and stopped < 0.0:
		DriftModel.step(st, _frame(1.0), r25, brak, DT)
		t += DT
		if spun < 0.0 and st.mode == DriftModel.Mode.SPIN:
			spun = t
		if spun > 0.0 and st.mode == DriftModel.Mode.GRIP:
			stopped = t
	if spun < 0.0 or spun > 2.5 or stopped < 0.0 or stopped - spun > 1.5 + 2.0 * DT:
		_fail("M6: no assist with the gas held spun at %.2f s (< 2.5), stopped %.2f s after (1.5)" % [spun, stopped - spun])
	# M8: the decent bot's speed on the sweeper (Ósemka's first bend).
	var kmh := _bot_sweeper_kmh(1)
	print("check_drift: M8 the decent bot on the sweeper: %.1f km/h" % kmh)
	if kmh < 50.0 or kmh > 75.0:
		_fail("M8: the decent bot holds %.1f km/h on the sweeper (50-75)" % kmh)
	# M9: the same inputs twice.
	var h1 := _random_run(7, 600)
	var h2 := _random_run(7, 600)
	if h1 != h2:
		_fail("M9: the same inputs gave %s and %s" % [h1, h2])
	# M10: 10,000 random frames.
	var h3 := _random_run(11, 10000)
	if "nan" in h3.to_lower() or "inf" in h3.to_lower():
		_fail("M10: 10,000 random frames ended in %s" % h3)
	# M11: car.gd names no drift script.
	var car_src := FileAccess.get_file_as_string("res://scripts/car.gd")
	for n in ["drift_model", "drift_car", "drift_score", "drift_stadium", "drift_input", "drift_line", "drift_bot"]:
		if n in car_src:
			_fail("M11: car.gd names %s" % n)
	# W (change 2): a drift held on the old side across a crossover.
	# Held 0.5 s before the sign change (the flick spot) at 15 m/s: the window closes FLICK_AFTER s
	# past it, so WRONG comes at 0.5 + FLICK_AFTER s (0.75 s; 0.9 s before the review narrowed the
	# window); from the sign change on, no points.
	st = _drifting(cr, f - 0.5 * 15.0, 15.0, 35.0)
	st.gas = 0.6
	var sc := DriftScore.Score.new()
	sc.chain = 3
	var wrong_at := -1.0
	var sign_at := -1.0
	var pts_wrong := 0.0
	var banked_wrong := false
	t = 0.0
	while t < 3.0 and not banked_wrong:
		var pile0 := sc.pile
		# Hold the angle about 35° (the pedal's travel, not a thumb): the speed stays near 15 m/s.
		DriftModel.step(st, _frame(1.0 if absf(st.beta) < 35.0 else 0.0), cr, p, DT)
		DriftScore.tick(sc, st, cr, DT)
		t += DT
		if sign_at < 0.0 and st.s >= f:
			sign_at = t
		if st.mode == DriftModel.Mode.WRONG and wrong_at < 0.0:
			wrong_at = t
		if sign_at >= 0.0 and st.mode == DriftModel.Mode.DRIFT:
			pts_wrong += sc.pile - pile0
		if "bank" in st.events:
			banked_wrong = true
	var w_at := 0.5 + DriftModel.FLICK_AFTER
	if absf(wrong_at - w_at) > 0.06 or pts_wrong > 0.0 or not banked_wrong or sc.chain != 1:
		_fail("W: the old side past the crossover: sign change at %.2f s, wrong at %.2f s (%.2f), %.0f points from the sign change on (0), banked %s, chain ×%d" % [sign_at, wrong_at, w_at, pts_wrong, str(banked_wrong), sc.chain])
	print("check_drift: W sign change at %.2f s, wrong at %.2f s, %.0f points between" % [sign_at, wrong_at, pts_wrong])


## The decent bot's mean speed (km/h) while it drifts on Ósemka's first bend.
func _bot_sweeper_kmh(seed_n: int) -> float:
	var bot: RefCounted = DriftBot.make("decent", seed_n)
	var st := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	var inp := DriftInput.new()
	var seg: Dictionary = osemka.segments[1]
	var sum := 0.0
	var n := 0
	var t := 0.0
	while st.s < float(seg["s1"]) and t < 30.0:
		bot.tick(t, st, osemka, inp)
		DriftModel.step(st, _frame(inp.gas(), inp.take_kick(), sc.chain), osemka, p, DT)
		DriftScore.tick(sc, st, osemka, DT)
		t += DT
		if st.s > float(seg["s0"]) + 10.0 and st.mode == DriftModel.Mode.DRIFT:
			sum += st.v * 3.6
			n += 1
	return sum / maxf(1.0, float(n))


## `frames` random frames on Ósemka from a seed: the end state's text.
func _random_run(seed_n: int, frames: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var st := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	for i in frames:
		DriftModel.step(st, _frame(float(rng.randf() < 0.6), rng.randf() < 0.05, sc.chain), osemka, p, rng.randf_range(0.0, 0.05))
		DriftScore.tick(sc, st, osemka, DT)
		if st.finished:
			st = DriftModel.State.new()
	return st.hash_text() + "|%.3f" % sc.total


# --- I: the thumb ---------------------------------------------------------------------------------

func _input() -> void:
	var a := DriftInput.new()
	a.press(0.0)
	a.release(0.1)
	a.press(0.25)
	var k1 := a.take_kick()
	var g1 := a.gas()
	if not k1 or g1 != 1.0:
		_fail("I1: tap 0.1, gap 0.15, press: kick %s, gas %.0f" % [str(k1), g1])
	a = DriftInput.new()
	a.press(0.0)
	a.release(0.3)
	a.press(0.4)
	if a.take_kick():
		_fail("I2: a 0.3 s press counted as a tap")
	a = DriftInput.new()
	a.press(0.0)
	a.release(0.1)
	a.press(0.45)
	if a.take_kick():
		_fail("I3: a 0.35 s gap kicked")
	a = DriftInput.new()
	a.press(0.0)
	a.release(5.0)
	a.press(5.1)
	a.release(5.2)
	a.press(5.35)
	if not a.take_kick() or a.gas() != 1.0:
		_fail("I4: a long hold, then tap-tap did not kick")
	a = DriftInput.new()
	a.press(0.0, 0)
	a.press(0.05, 1)
	a.release(0.08, 1)
	if not a.down:
		_fail("I5: a second finger's release lifted the first")
	a.release(0.1, 0)
	a.press(0.2, 1)
	if not a.take_kick():
		_fail("I5: the first finger's tap then another's press did not kick (it is the first finger now)")
	a.press(0.25, 0)
	a.release(0.3, 0)
	if not a.down:
		_fail("I5: a second finger lifted the gas")
	# The press that kicked starts no second kick.
	a = DriftInput.new()
	a.press(0.0)
	a.release(0.1)
	a.press(0.2)
	a.release(0.3)
	a.press(0.4)
	a.take_kick()
	var kicks := a.kicks
	if kicks != 1:
		_fail("I: tap-tap-tap gave %d kicks (1)" % kicks)
	# I6, the dab (critique 0b.6: a good thumb holds the needle with quick dabs): three presses of
	# 0.15 s with 0.15 s gaps are one kick, the gas follows the thumb, and in a drift outside the window
	# that kick changes nothing (change 10).
	a = DriftInput.new()
	var dab_kicks := 0
	var gas_ok := true
	for i in 3:
		a.press(0.3 * i)
		if a.take_kick():
			dab_kicks += 1
		gas_ok = gas_ok and a.gas() == 1.0
		a.release(0.3 * i + 0.15)
		gas_ok = gas_ok and a.gas() == 0.0
	var cr := _test_line(25.0, 40.0, 40.0)
	var st := _drifting(cr, float(cr.flips[0]) - 1.5 * 15.0, 15.0, 35.0)
	var twin := st.copy()
	for i in 54:
		var on := fmod(float(i) * DT, 0.3) < 0.15
		DriftModel.step(st, _frame(1.0 if on else 0.0, i == 18), cr, p, DT)
		DriftModel.step(twin, _frame(1.0 if on else 0.0), cr, p, DT)
	if dab_kicks != 1 or not gas_ok or absf(st.beta - twin.beta) > 1e-4 or st.mode != twin.mode:
		_fail("I6: three dabs: %d kicks (1), gas follows %s, in a drift %.2f° against %.2f° without the kick" % [dab_kicks, str(gas_ok), st.beta, twin.beta])


# --- S: the score ---------------------------------------------------------------------------------

func _score() -> void:
	# S1
	var want := {10.0: 0.0, 20.0: 0.25, 25.0: 0.5, 35.0: 0.75, 45.0: 1.0, 55.0: 1.0, 62.5: 0.75, 70.0: 0.5}
	for d: float in want:
		var a := DriftScore.angle_factor(d)
		if absf(a - float(want[d])) > 0.001 or absf(DriftScore.angle_factor(-d) - a) > 0.001:
			_fail("S1: A(%.1f°) is %.3f (%.3f)" % [d, a, float(want[d])])
	var r := DriftScore.rate(62.0 / 3.6, 25.0, 1)
	if absf(r - 31.0) > 0.01:
		_fail("S1: 62 km/h at 25° pays %.2f a second (31)" % r)
	if absf(DriftScore.rate(55.0 / 3.6, 45.0, 3) - 165.0) > 0.01:
		_fail("S1: 55 km/h at 45° on ×3 pays %.2f a second (165)" % DriftScore.rate(55.0 / 3.6, 45.0, 3))
	var ln := _test_line(25.0, 40.0)
	# S2: the chain.
	var st := _drifting(ln, 45.0, 15.0, 40.0)
	var sc := DriftScore.Score.new()
	var chain_at := {}
	var t := 0.0
	while t < 30.0:
		st.events.clear()
		st.s = 45.0
		DriftScore.tick(sc, st, ln, DT)
		t += DT
		if not chain_at.has(sc.chain):
			chain_at[sc.chain] = t
	if not chain_at.has(2) or absf(float(chain_at[2]) - DriftScore.CHAIN_S) > 0.05 or sc.chain != DriftScore.CHAIN_CAP:
		_fail("S2: the chain reached ×2 at %s s (%.1f), ends at ×%d (×%d)" % [str(chain_at.get(2, -1)), DriftScore.CHAIN_S, sc.chain, DriftScore.CHAIN_CAP])
	sc = DriftScore.Score.new()
	st.events = PackedStringArray(["flick:1.00"])
	DriftScore.tick(sc, st, ln, DT)
	if sc.chain != 2 or sc.pile < DriftScore.FLICK_PTS or not "perfect" in sc.said:
		_fail("S2: a perfect flick gave ×%d and %.0f (×2, 400 or more, IDEALNIE!)" % [sc.chain, sc.pile])
	st.events = PackedStringArray(["flick:0.50"])
	var p0 := sc.pile
	DriftScore.tick(sc, st, ln, DT)
	if sc.chain != 3 or sc.pile - p0 < DriftScore.FLICK_PTS * 0.5 or sc.pile - p0 > DriftScore.FLICK_PTS * 0.5 + 50.0:
		_fail("S2: a late flick gave ×%d and %.0f (×3, about 200)" % [sc.chain, sc.pile - p0])
	# The clock stops at CHAIN_CAP; each flick raises the cap by one, up to FLICK_CAP.
	var sc2 := DriftScore.Score.new()
	var st2 := _drifting(ln, 45.0, 15.0, 40.0)
	var chains: Array[int] = []
	for k in 4:
		for i in int(30.0 / DT):
			st2.events.clear()
			st2.s = 45.0
			DriftScore.tick(sc2, st2, ln, DT)
		chains.append(sc2.chain)
		st2.events = PackedStringArray(["flick:1.00"])
		st2.s = 45.0
		DriftScore.tick(sc2, st2, ln, DT)
	if chains != [DriftScore.CHAIN_CAP, DriftScore.CHAIN_CAP + 1, DriftScore.FLICK_CAP, DriftScore.FLICK_CAP]:
		_fail("S2: 30 s on the clock between flicks gave %s (×%d, ×%d, ×%d, ×%d)" % [str(chains), DriftScore.CHAIN_CAP, DriftScore.CHAIN_CAP + 1, DriftScore.FLICK_CAP, DriftScore.FLICK_CAP])
	# S3: a bank.
	var pile := sc.pile
	st.events = PackedStringArray(["bank"])
	st.mode = DriftModel.Mode.GRIP
	DriftScore.tick(sc, st, ln, DT)
	if absf(sc.total - pile) > 0.01 or sc.pile != 0.0 or sc.chain != 1:
		_fail("S3: a bank of %.0f gave total %.0f, pile %.0f, ×%d" % [pile, sc.total, sc.pile, sc.chain])
	# S4: a spin loses the pile.
	st = _drifting(ln, 45.0, 15.0, 40.0)
	for i in 60:
		st.events.clear()
		DriftScore.tick(sc, st, ln, DT)
	var total := sc.total
	st.events = PackedStringArray(["spin"])
	st.mode = DriftModel.Mode.SPIN
	DriftScore.tick(sc, st, ln, DT)
	if sc.pile != 0.0 or absf(sc.total - total) > 0.01 or not "spin" in sc.said:
		_fail("S4: a spin left pile %.0f, total %.0f (was %.0f)" % [sc.pile, sc.total, total])
	# S5: the farming rules.
	if DriftScore.rate(7.5, 40.0, 1) != 0.0 or DriftScore.rate(15.0, 40.0, 1, 15.0, 6.5) != 0.0 \
			or DriftScore.rate(15.0, 40.0, 1, 15.0, 0.0, true) != 0.0 or DriftScore.rate(15.0, 40.0, 1, 5.0) != 0.0:
		_fail("S5: points under 8 m/s, past 6 m off or backwards")
	if DriftScore.rate(15.0, 40.0, 1, 15.0, 5.5) <= 0.0:
		_fail("S5: no points 5.5 m off the line")
	# S6: the zones.
	for zi in osemka.zones.size():
		var z: Dictionary = osemka.zones[zi]
		var mid := (float(z["s0"]) + float(z["s1"])) * 0.5
		sc = DriftScore.Score.new()
		st = _drifting(osemka, mid, 15.0, 34.0)
		st.events.clear()
		DriftScore.tick(sc, st, osemka, DT)
		if zi in sc.zones_done:
			_fail("S6: %s %d paid at 34°" % [z["kind"], zi])
		st.beta = 37.0 * float(osemka.bend_sign(mid))
		var l0 := float(sc.pile_parts["linia"])
		DriftScore.tick(sc, st, osemka, DT)
		var paid := float(sc.pile_parts["linia"]) - l0
		var per_tick := DriftScore.ZONE_PTS_M * float(sc.chain) * st.v * DT
		if not zi in sc.zones_done or not str(z["kind"]) in sc.said or absf(paid - per_tick) > 0.01:
			var tp: Vector2 = DriftModel.tail(st, osemka) if z["kind"] == "zona" else DriftModel.nose(st, osemka)
			_fail("S6: %s %d paid %.2f at 37° (%.2f a metre held; %.2f m from its board)" % [z["kind"], zi, paid, per_tick, DriftLine.board_distance(z, tp)])
		DriftScore.tick(sc, st, osemka, DT)
		if str(z["kind"]) in sc.said:
			_fail("S6: %s %d said its name twice" % [z["kind"], zi])
	# A tail well off the board does not pay (the shallow 15° drift).
	sc = DriftScore.Score.new()
	st = _drifting(osemka, (float(osemka.zones[0]["s0"]) + float(osemka.zones[0]["s1"])) * 0.5, 15.0, 15.0)
	DriftScore.tick(sc, st, osemka, DT)
	if not sc.zones_done.is_empty():
		_fail("S6: a zone paid at 15°")
	# S7: the run's end while drifting banks.
	sc = DriftScore.Score.new()
	st = _drifting(ln, 45.0, 15.0, 40.0)
	for i in 60:
		st.events.clear()
		DriftScore.tick(sc, st, ln, DT)
	pile = sc.pile
	st.events = PackedStringArray(["end"])
	DriftScore.tick(sc, st, ln, DT)
	# The end's own step adds its points before the bank: the total is the pile and one step more.
	var one_step := DriftScore.rate(st.v, st.beta, sc.chain) * DT + 0.01
	if pile <= 0.0 or sc.total < pile - 0.01 or sc.total > pile + one_step or sc.pile != 0.0:
		_fail("S7: the end while drifting: pile %.0f, total %.0f, left %.0f" % [pile, sc.total, sc.pile])


# --- B: the bots on Ósemka --------------------------------------------------------------------------

func _median(xs: Array) -> float:
	var a := xs.duplicate()
	a.sort()
	if a.is_empty():
		return 0.0
	return (float(a[(a.size() - 1) / 2]) + float(a[a.size() / 2])) * 0.5


func _runs(kind: String) -> Array:
	var out := []
	for i in SEEDS:
		out.append(DriftBot.run(kind, i + 1, osemka, p))
	return out


func _bots() -> void:
	var t0 := Time.get_ticks_msec()
	var decent := _runs("decent")
	var totals := decent.map(func(r: Dictionary) -> float: return float(r["total"]))
	var med := _median(totals)
	var q_line := Q_SHARE * med
	var times := decent.map(func(r: Dictionary) -> float: return float(r["time"]))
	var spins: int = decent.reduce(func(acc: int, r: Dictionary) -> int: return acc + int(r["spins"]), 0)
	var flicks: int = decent.reduce(func(acc: int, r: Dictionary) -> int: return acc + int(r["flicks"]), 0)
	var zones: int = decent.reduce(func(acc: int, r: Dictionary) -> int: return acc + int(r["zones"]), 0)
	var kmh: float = float(decent.reduce(func(acc: float, r: Dictionary) -> float: return acc + float(r["kmh"]), 0.0)) / SEEDS
	print("check_drift: B1 decent: median %.0f (min %.0f, max %.0f), Q_LINE %.0f, %.1f-%.1f s, %.1f km/h, %d spins, %.2f flicks, %.2f zones a run" % [med,
			totals.min(), totals.max(), q_line, times.min(), times.max(), kmh, spins, float(flicks) / SEEDS, float(zones) / SEEDS])
	var c0: Dictionary = decent[0]["cards"]
	print("check_drift: B1 seed 1 cards: linia %.0f, kat %.0f, styl %.0f" % [float(c0["linia"]), float(c0["kat"]), float(c0["styl"])])
	var pass_rate := float(totals.filter(func(x: float) -> bool: return x >= q_line).size()) / SEEDS
	if pass_rate < B1_RATE:
		_fail("B1: the decent bot passes Q_LINE in %.0f %% of seeds (%.0f %% or more)" % [pass_rate * 100.0, B1_RATE * 100.0])
	if times.min() < TIME_BAND.x or times.max() > TIME_BAND.y:
		_fail("B9: the decent bot's runs last %.1f-%.1f s (28-40)" % [times.min(), times.max()])
	# B2: the clumsy bot.
	var clumsy := _runs("clumsy")
	var ct := clumsy.map(func(r: Dictionary) -> float: return float(r["total"]))
	var c_rate := float(ct.filter(func(x: float) -> bool: return x >= q_line).size()) / SEEDS
	var c_spins: int = clumsy.reduce(func(acc: int, r: Dictionary) -> int: return acc + int(r["spins"]), 0)
	print("check_drift: B2 clumsy: median %.0f (min %.0f, max %.0f), passes %.0f %%, %d spins" % [_median(ct), ct.min(), ct.max(), c_rate * 100.0, c_spins])
	if c_rate < B2_BAND.x or c_rate > B2_BAND.y:
		_fail("B2: the clumsy bot passes in %.0f %% of seeds (%.0f-%.0f %%)" % [c_rate * 100.0, B2_BAND.x * 100.0, B2_BAND.y * 100.0])
	# B3 (the review): every blind cycle (tap 0.1, gap 0.1, hold H, lift L, again) from every start
	# phase scores under PULSE_MAX of Q_LINE.
	var best_pulse := 0.0
	var best_at := Vector3.ZERO
	var cycles := 0
	var over := 0
	for hi in 19:
		for li in 15:
			for ph in CYCLE_PHASES:
				var h := 0.2 + 0.1 * hi
				var l := 0.1 + 0.05 * li
				var r: Dictionary = DriftBot.run("cycle", 1, osemka, p, h, l, {}, float(ph) / CYCLE_PHASES)
				cycles += 1
				if float(r["total"]) >= PULSE_MAX * q_line:
					over += 1
				if float(r["total"]) > best_pulse:
					best_pulse = float(r["total"])
					best_at = Vector3(h, l, float(ph) / CYCLE_PHASES)
	print("check_drift: B3 blind cycles: %d, best %.0f (%.0f %% of Q_LINE) at hold %.1f s, lift %.2f s, phase %.1f; %d at %.0f %% or over" % [cycles,
			best_pulse, best_pulse / q_line * 100.0, best_at.x, best_at.y, best_at.z, over, PULSE_MAX * 100.0])
	if over > 0:
		_fail("B3: %d blind cycles score %.0f %% of Q_LINE or more (best %.0f at hold %.1f s, lift %.2f s, phase %.1f)" % [over, PULSE_MAX * 100.0, best_pulse, best_at.x, best_at.y, best_at.z])
	# B4: the gas held, kicking again whenever it grips.
	var hold := _runs("hold")
	var h_max := 0.0
	for r: Dictionary in hold:
		h_max = maxf(h_max, float(r["total"]))
		if int(r["spins"]) < 1:
			_fail("B4: the gas held with re-kicks did not spin")
			break
	print("check_drift: B4 hold: best %.0f (%.0f %% of Q_LINE)" % [h_max, h_max / q_line * 100.0])
	if h_max >= HOLD_MAX * q_line:
		_fail("B4: the gas held with re-kicks scores %.0f (under %.0f)" % [h_max, HOLD_MAX * q_line])
	# B5: banking at both crossovers.
	var bank := _runs("bank")
	var bt := bank.map(func(r: Dictionary) -> float: return float(r["total"]))
	var share := _median(bt) / maxf(med, 1.0)
	print("check_drift: B5 bank at both crossovers: median %.0f, %.0f %% of the follower" % [_median(bt), share * 100.0])
	if share < BANK_BAND.x or share > BANK_BAND.y:
		_fail("B5: banking at both crossovers scores %.0f %% of the follower (%.0f-%.0f %%)" % [share * 100.0, BANK_BAND.x * 100.0, BANK_BAND.y * 100.0])
	# B7: the follower with a 55° needle spins in some seeds (depth carries risk).
	var deep := []
	for i in SEEDS:
		deep.append(DriftBot.run("decent", i + 1, osemka, p, 1.0, 0.4, {}, 0.0, DEEP_NEEDLE))
	var dt_ := deep.map(func(r: Dictionary) -> float: return float(r["total"]))
	var spun_seeds := deep.filter(func(r: Dictionary) -> bool: return int(r["spins"]) > 0).size()
	var decent_spun := decent.filter(func(r: Dictionary) -> bool: return int(r["spins"]) > 0).size()
	print("check_drift: B7 needle %.0f°: median %.0f, spins in %d of %d seeds (the 42° follower: %d)" % [DEEP_NEEDLE, _median(dt_), spun_seeds, SEEDS, decent_spun])
	if float(spun_seeds) / SEEDS < DEEP_SPIN_MIN:
		_fail("B7: the follower at a %.0f° needle spins in %d of %d seeds (%.0f %% or more)" % [DEEP_NEEDLE, spun_seeds, SEEDS, DEEP_SPIN_MIN * 100.0])
	# B6: no kick.
	var none: Dictionary = DriftBot.run("none", 1, osemka, p)
	if float(none["total"]) != 0.0:
		_fail("B6: no kick scored %.0f" % float(none["total"]))
	print("check_drift: bots in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
