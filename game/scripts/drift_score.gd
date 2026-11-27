extends RefCounted
## The drift's score (Bokiem na Narodowym, docs/design/drift-narodowy.md 0b.2 with critique-drift.md
## changes 1, 2 and 9; the grey box, section 4). Pure and static: `tick(score, state, line, dt)` reads
## a drift_model.gd state and its events. Points are the only currency.
##   - Points a second = km/h × A(|β|) × chain, A by `angle_factor` (change 1: depth pays), 0 on the
##     wrong side (change 2), 0 under MIN_PROGRESS m/s of progress, past MAX_OFF m off the line or going
##     backwards (0b.2, the farming rules).
##   - The chain starts at ×1 on a kick, +1 every CHAIN_S s of unbroken drift and +1 per transition,
##     capped at CHAIN_CAP; a transition also pays FLICK_PTS × its timing (1.0 within 0.15 s of the
##     sign change: IDEALNIE!, 0.5 elsewhere in the window). Change 9 asked +1 every 4 s and ×6 with
##     "banking at both crossovers 55-75 % of flicking both" as its target; the bots (check_drift B5)
##     put 4 s / ×6 at 35 %, so the chain is tuned to its target: +1 every 2 s, ×4 (63 %; QUESTIONS.md).
##   - Zones pay ZONE_PTS × chain once per zone per run: ZONA the tail within ZONE_R m of the outer
##     board, KLIP the nose within ZONE_R m of the inner cones, both at |β| ≥ ZONE_DEG (change 1: 35°).
##   - Points pile up unbanked and go into the total on a clean end (the model's "bank": a lift to
##     grip, the wrong side pulled back, the run's end while drifting); the chain is ×1 again. A spin
##     (or a contact, later: the tandem) loses the pile: PRZEPADŁO.
##   - The three cards: LINIA (zones), KĄT (the angle's base points, chain ×1), STYL (what the chain
##     added, and the transitions). Only banked points reach them.

const DriftModel := preload("res://scripts/drift_model.gd")
const DriftLine := preload("res://scripts/drift_line.gd")

const CHAIN_S := 2.0
const CHAIN_CAP := 4
const FLICK_PTS := 400.0
const ZONE_PTS := 300.0
const ZONE_R := 1.5
const ZONE_DEG := 35.0
const MIN_PROGRESS := 8.0
const MAX_OFF := 6.0


## One run's score.
class Score:
	extends RefCounted
	var total := 0.0
	var pile := 0.0
	var chain := 1
	var chain_t := 0.0
	## The chain's step (s) and cap: CHAIN_S and CHAIN_CAP unless a tuning run sets them.
	var chain_s := CHAIN_S
	var chain_cap := CHAIN_CAP
	## The pile's parts and the banked cards: linia, kat, styl.
	var pile_parts := {"linia": 0.0, "kat": 0.0, "styl": 0.0}
	var cards := {"linia": 0.0, "kat": 0.0, "styl": 0.0}
	var zones_done: Array[int] = []
	var banks := 0
	var losses := 0
	var spins := 0
	var flicks := 0
	var drift_s := 0.0
	## What happened this tick for the UI: "bank:<points>", "lost:<points>", "zona", "klip", "flick",
	## "perfect", "wrong", "slow", "spin", "end".
	var said: PackedStringArray = []

	func reset_pile() -> void:
		pile = 0.0
		for k: String in pile_parts:
			pile_parts[k] = 0.0
		chain = 1
		chain_t = 0.0


## A(|β|), change 1: 0 under 15°, 0.5 at 25° (linear from 15°), linear to 1.0 at 45°, 1.0 to 55°,
## down to 0.5 at 70° and on to 0 at 85°.
static func angle_factor(deg: float) -> float:
	var a := absf(deg)
	if a < 15.0:
		return 0.0
	if a < 25.0:
		return 0.5 * (a - 15.0) / 10.0
	if a < 45.0:
		return 0.5 + 0.5 * (a - 25.0) / 20.0
	if a <= 55.0:
		return 1.0
	if a <= 70.0:
		return 1.0 - 0.5 * (a - 55.0) / 15.0
	return maxf(0.0, 0.5 - 0.5 * (a - 70.0) / 15.0)


## Points a second at speed v (m/s), slip deg and chain, with the farming rules (progress m/s along
## the line, offset m from it, backwards).
static func rate(v: float, deg: float, chain: int, progress := INF, offset := 0.0, backwards := false) -> float:
	var prog := v if progress == INF else progress
	if prog < MIN_PROGRESS or absf(offset) > MAX_OFF or backwards:
		return 0.0
	return v * 3.6 * angle_factor(deg) * float(chain)


static func bank(sc: Score) -> void:
	if sc.pile > 0.0:
		sc.total += sc.pile
		for k: String in sc.pile_parts:
			sc.cards[k] += sc.pile_parts[k]
		sc.banks += 1
		sc.said.append("bank:%d" % roundi(sc.pile))
	sc.reset_pile()


static func lose(sc: Score) -> void:
	if sc.pile > 0.0:
		sc.losses += 1
		sc.said.append("lost:%d" % roundi(sc.pile))
	sc.reset_pile()


static func add(sc: Score, card: String, pts: float) -> void:
	sc.pile += pts
	sc.pile_parts[card] += pts


## One step after drift_model.step: its events, the points of this dt, the chain and the zones.
## `offset` and `backwards` are the farming rules' inputs (the posed car is always on the line).
static func tick(sc: Score, st: DriftModel.State, line: RefCounted, dt: float, offset := 0.0, backwards := false) -> void:
	sc.said.clear()
	for e in st.events:
		if e == "kick":
			sc.reset_pile()
		elif e.begins_with("flick:"):
			var timing := float(e.get_slice(":", 1))
			sc.chain = mini(sc.chain_cap, sc.chain + 1)
			add(sc, "styl", FLICK_PTS * timing)
			sc.flicks += 1
			sc.said.append("perfect" if timing >= 1.0 else "flick")
		elif e == "bank":
			bank(sc)
		elif e == "spin":
			sc.spins += 1
			lose(sc)
			sc.said.append("spin")
		elif e == "wrong":
			sc.said.append("wrong")
		elif e == "slow":
			sc.said.append("slow")
		elif e == "end":
			bank(sc)
			sc.said.append("end")
	var sliding := st.mode == DriftModel.Mode.DRIFT or st.mode == DriftModel.Mode.FLIP
	if not sliding:
		return
	sc.drift_s += dt
	sc.chain_t += dt
	if sc.chain_t >= sc.chain_s:
		sc.chain_t -= sc.chain_s
		sc.chain = mini(sc.chain_cap, sc.chain + 1)
	var base := rate(st.v, st.beta, 1, st.v, offset, backwards) * dt
	add(sc, "kat", base)
	add(sc, "styl", base * float(sc.chain - 1))
	if absf(st.beta) < ZONE_DEG or st.mode != DriftModel.Mode.DRIFT:
		return
	for i in line.zones.size():
		if i in sc.zones_done:
			continue
		var z: Dictionary = line.zones[i]
		if st.s < float(z["s0"]) - 3.0 or st.s > float(z["s1"]) + 3.0:
			continue
		var p := DriftModel.tail(st, line) if z["kind"] == "zona" else DriftModel.nose(st, line)
		if DriftLine.board_distance(z, p) <= ZONE_R:
			sc.zones_done.append(i)
			add(sc, "linia", ZONE_PTS * float(sc.chain))
			sc.said.append(str(z["kind"]))
