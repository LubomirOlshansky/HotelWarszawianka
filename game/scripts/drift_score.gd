extends RefCounted
## The drift's score (Bokiem na Narodowym, docs/design/drift-narodowy.md 0b.2 with critique-drift.md
## changes 1, 2 and 9; the grey box, section 4, and its PR review). Pure and static:
## `tick(score, state, line, dt)` reads a drift_model.gd state and its events. Points are the only
## currency.
##   - Points a second = km/h × A(|β|) × chain, A by `angle_factor` (change 1: depth pays), 0 with the
##     slip on the wrong side of the bend (change 2), 0 under MIN_PROGRESS m/s of progress, past
##     MAX_OFF m off the line or going backwards (0b.2, the farming rules).
##   - The chain starts at ×1 on a kick and climbs +1 every CHAIN_S s of unbroken drift up to the
##     pile's cap, CHAIN_CAP at first; a transition raises the cap by one (to FLICK_CAP at most) and
##     the chain +1 with it, so ×5 and ×6 come only from flicks (the review: a flick's +1 was worth
##     nothing once the clock had reached the cap). A transition also pays FLICK_PTS × its timing
##     (1.0 within 0.15 s of the sign change: IDEALNIE!, 0.5 elsewhere in the window).
##   - Zones pay ZONE_PTS_M × chain per metre held with the tail within ZONE_R m of the outer board
##     (ZONA) or the nose within ZONE_R m of the inner cones (KLIP), at |β| ≥ ZONE_DEG (change 1: 35°);
##     the review: a zone paid in full on one frame let a blind rhythm brush it. The first metre says
##     its name once per zone.
##   - Points pile up unbanked and go into the total on a clean end (the model's "bank": a lift to
##     grip, the wrong side pulled back, the run's end while drifting); the chain is ×1 again. A spin
##     (or a contact, later: the tandem) loses the pile: PRZEPADŁO.
##   - The three cards: LINIA (zones), KĄT (the angle's base points, chain ×1), STYL (what the chain
##     added, and the transitions). Only banked points reach them.

const DriftModel := preload("res://scripts/drift_model.gd")
const DriftLine := preload("res://scripts/drift_line.gd")

const CHAIN_S := 1.5
const CHAIN_CAP := 4
const CHAIN_DEG := 32.0
const FLICK_CAP := 6
const FLICK_PTS := 400.0
const ZONE_PTS_M := 25.0
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
	## The chain's step (s) and the clock's cap: CHAIN_S and CHAIN_CAP unless a tuning run sets them;
	## `cap` is this pile's cap (flicks raise it to FLICK_CAP).
	var chain_s := CHAIN_S
	var chain_cap := CHAIN_CAP
	var cap := CHAIN_CAP
	## The chain's clock runs only at |β| ≥ this (°): a shallow slide holds the chain, it does not build it.
	var chain_deg := CHAIN_DEG
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
		cap = chain_cap


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
	var ending := false
	for e in st.events:
		if e == "kick":
			sc.reset_pile()
		elif e.begins_with("flick:"):
			var timing := float(e.get_slice(":", 1))
			sc.cap = mini(FLICK_CAP, maxi(sc.cap, sc.chain_cap) + 1)
			sc.chain = mini(sc.cap, sc.chain + 1)
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
			ending = true
	_slide(sc, st, line, dt, offset, backwards)
	# The run's end banks after this step's points are in the pile (none left behind).
	if ending:
		bank(sc)
		sc.said.append("end")


## The points of one sliding step: the angle, the chain's clock, the zones.
static func _slide(sc: Score, st: DriftModel.State, line: RefCounted, dt: float, offset: float, backwards: bool) -> void:
	var sliding := st.mode == DriftModel.Mode.DRIFT or st.mode == DriftModel.Mode.FLIP
	if not sliding:
		return
	sc.drift_s += dt
	if absf(st.beta) >= sc.chain_deg:
		sc.chain_t += dt
	if sc.chain_t >= sc.chain_s:
		sc.chain_t -= sc.chain_s
		if sc.chain < sc.chain_cap:
			sc.chain += 1
	if st.mode == DriftModel.Mode.DRIFT and wrong_side(st, line):
		return
	var base := rate(st.v, st.beta, 1, st.v, offset, backwards) * dt
	add(sc, "kat", base)
	add(sc, "styl", base * float(sc.chain - 1))
	if absf(st.beta) < ZONE_DEG or st.mode != DriftModel.Mode.DRIFT:
		return
	for i in line.zones.size():
		var z: Dictionary = line.zones[i]
		if st.s < float(z["s0"]) - 3.0 or st.s > float(z["s1"]) + 3.0:
			continue
		var p := DriftModel.tail(st, line) if z["kind"] == "zona" else DriftModel.nose(st, line)
		if DriftLine.board_distance(z, p) <= ZONE_R:
			add(sc, "linia", ZONE_PTS_M * float(sc.chain) * st.v * dt)
			if not i in sc.zones_done:
				sc.zones_done.append(i)
				sc.said.append(str(z["kind"]))


## The slip is on the other side of the bend under the car (change 2: no points; past the window
## the model turns it into WRONG).
static func wrong_side(st: DriftModel.State, line: RefCounted) -> bool:
	var bend: int = line.bend_sign(st.s)
	return bend != 0 and st.beta != 0.0 and int(signf(st.beta)) != bend
