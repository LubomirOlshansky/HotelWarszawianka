extends RefCounted
## The final's tandem of Bokiem na Narodowym (PR 3, docs/design/critique-drift.md changes 7 and 8; the
## plan's 0b.5): two cars on Ósemka's one line, the player and Hrabia, who is the drift bot stepped live
## on drift_model.gd (drift_bot.gd "hrabia", seeded by the attempt), not a recording. Pure and static, so
## check_drift_event.gd runs whole runs with no scene and drift_event.gd steps the same rules each frame.
##   - The gap is along the line, from the leader's rear bumper to the chaser's nose: the centres' s apart
##     less CAR_LEN. BLISKO (CLOSE, 0.5-4 m): the chaser's slide is worth BOOST times more (drift_score.gd
##     `boost`). KONTAKT: the two cars' boxes (HALF) overlap, a box test on the floor; the first one in a
##     run costs the chaser two chain steps and KONTAKT_V m/s, the second the pile. The chaser cannot pass:
##     it is held a bumper behind (the pass rule and "≤ 3 m aside" are gone, change 8e).
##   - Run 1, he leads and you chase: his run is his own; shallow and fast closes the gap, deep and slow
##     loses it (the model couples speed to depth, critique section 2).
##   - Run 2, you lead and he chases: no faster than his own solo pace × CHASE_PACE (`solo_pace`, the same
##     seed alone), never closer than KEEP_BACK m to a slower car (he lifts and, crawling, straightens:
##     his pile banks), BLISKO only while his gap is under CLOSE.y. Drive shallow and fast and he drops off
##     (UCIEKASZ! once he is past AWAY m after being close); drive deep and slow and he sits on you at ×1.5.
##   - Your spin in either run gives him GIFT points banked at once (PREZENT!).
## `said` (per frame): "close" (you are BLISKO, the first frame of it), "contact", "away", "gift".

const DriftModel := preload("res://scripts/drift_model.gd")
const DriftScore := preload("res://scripts/drift_score.gd")
const DriftInput := preload("res://scripts/drift_input.gd")
const DriftBot := preload("res://scripts/drift_bot.gd")

## A car's length (m) and its box's half width and half length on the floor (the centre to a side).
const CAR_LEN := 4.0
const HALF := Vector2(0.9, 2.0)
## BLISKO's gap (m) and what it multiplies.
const CLOSE := Vector2(0.5, 4.0)
const BOOST := 1.5
## Run 2: his pace cap over his own solo pace, and how near he comes to a slower car (m of gap).
const CHASE_PACE := 1.03
const KEEP_BACK := 2.0
## ...from this far beyond it (m), at this much speed a metre of gap left (m/s per m).
const KEEP_RAMP := 1.5
const KEEP_GAIN := 4.0
## Under this speed (m/s) behind a slower car he straightens and waits (no slow spin).
const CRAWL := 8.0
## UCIEKASZ!: his gap past this (m) after he was close.
const AWAY := 6.0
## PREZENT!: your spin gives him this many points.
const GIFT := 500.0
## KONTAKT: the speed the first one costs (m/s), the chain steps, and the time before the next counts (s).
## A touch pushes the chaser back to BLISKO's near edge (CLOSE.x) under the leader's speed; the next one
## counts only once the cars were apart again (Fable's review: no second KONTAKT while held).
const KONTAKT_V := 2.0
const KONTAKT_STEPS := 2
const KONTAKT_COOL := 1.0
## The second and later KONTAKT cost this share of the pile (and KONTAKT_STEPS chain steps), not all of it.
const KONTAKT_SHARE := 0.5
## No KONTAKT is the chaser's fault for EXCUSE_S s after the leader slows harder than SHARP (m/s²), nor in
## Hrabia's over-hold window (drift_bot.gd `wobbling`).
const SHARP := 9.0
const EXCUSE_S := 1.0
## Run 2: a leader under CRAWL for PARK_S s (after PARK_FROM s of the run) is parked: Hrabia drives his solo
## lap for the rest of it, through you (Fable's review: parking skipped run 2).
const PARK_S := 1.5
const PARK_FROM := 3.0
## The check's chasing bots hold the gas (deeper, slower) while the gap is under this (m): a thumb that
## sees the car in front.
const CHASE_DEEP := 3.5
const CHASE_MAX_DEG := 48.0
## Where the leader starts (m along the line; the chaser at 0): a car's length and a gap of 4 m.
const LEAD_AT := 8.0
const HZ := 60.0
## A run gives up after this (s, 0b.2).
const RUN_LIMIT := 45.0


## One run of the tandem: who leads, Hrabia's car (state, score, thumb, bot) and what happened.
class Duel:
	extends RefCounted
	## 1: he leads, you chase; 2: you lead, he chases.
	var run := 1
	var him := DriftModel.State.new()
	var him_sc := DriftScore.Score.new()
	var him_in := DriftInput.new()
	var him_fr := DriftModel.Frame.new()
	var bot: RefCounted
	## His solo pace by metre (m/s), run 2's cap.
	var pace := PackedFloat32Array()
	var gap := 0.0
	var contacts := 0
	var gifts := 0
	var contact_t := 0.0
	var was_close := false
	var you_close := false
	## Seconds the chaser was BLISKO in this run (you in run 1, him in run 2), and the run's time.
	var close_s := 0.0
	var t := 0.0
	var said: PackedStringArray = []
	## KONTAKT counts again (the cars were apart since the last one); the touches let off (excused).
	var armed := true
	var excused := 0
	var excuse_t := 0.0
	var lead_v := -1.0
	## Run 2: the leader's crawl time, and parked (he drives alone from then).
	var crawl_t := 0.0
	var solo := false


## A run of the final: Hrabia's bot with `him_seed` (and his over-hold when `wobble`), the leader placed.
## `you` is the player's state, placed here too.
static func make(run_no: int, him_seed: int, wobble: bool, line: RefCounted, p: Dictionary, you: DriftModel.State) -> Duel:
	var d := Duel.new()
	d.run = run_no
	d.bot = DriftBot.hrabia(him_seed, wobble)
	if run_no == 1:
		d.him.s = LEAD_AT
		you.s = 0.0
	else:
		d.him.s = 0.0
		you.s = LEAD_AT
		d.pace = solo_pace(him_seed, wobble, line, p)
	return d


## The gap (m) from the leader's rear bumper to the chaser's nose, along the line.
static func gap(lead_s: float, chase_s: float) -> float:
	return lead_s - chase_s - CAR_LEN


static func is_close(g: float) -> bool:
	return g >= CLOSE.x and g <= CLOSE.y


## Two boxes on the floor, centres `ca` and `cb`, headings `ya` and `yb` (rad, rotation.y), half sizes
## `half` (width, length): do they overlap? The separating axis test on the four edges' normals.
static func boxes_overlap(ca: Vector2, ya: float, cb: Vector2, yb: float, half := HALF) -> bool:
	var axes: Array[Vector2] = [Vector2(cos(ya), -sin(ya)), Vector2(sin(ya), cos(ya)), Vector2(cos(yb), -sin(yb)), Vector2(sin(yb), cos(yb))]
	var d := cb - ca
	for ax: Vector2 in axes:
		var ra := _extent(ax, ya, half)
		var rb := _extent(ax, yb, half)
		if absf(d.dot(ax)) > ra + rb:
			return false
	return true


## A box's half extent along `ax` (its width along its right, its length along its forward).
static func _extent(ax: Vector2, y: float, half: Vector2) -> float:
	var right := Vector2(cos(y), -sin(y))
	var fwd := Vector2(sin(y), cos(y))
	return absf(ax.dot(right)) * half.x + absf(ax.dot(fwd)) * half.y


## KONTAKT between two cars on the line (their bodies at course + slip; a spin's body too).
static func contact(a: DriftModel.State, b: DriftModel.State, line: RefCounted) -> bool:
	if absf(a.s - b.s) > CAR_LEN + 2.0 * HALF.x + 1.0:
		return false
	return boxes_overlap(DriftModel.centre(a, line), DriftModel.body_yaw(a, line), DriftModel.centre(b, line), DriftModel.body_yaw(b, line))


## Hrabia's solo pace by metre (m/s, the best speed he passes each metre at), the same seed alone.
static func solo_pace(him_seed: int, wobble: bool, line: RefCounted, p: Dictionary) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(ceil(line.length)) + 2)
	var bot: RefCounted = DriftBot.hrabia(him_seed, wobble)
	var st := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	var inp := DriftInput.new()
	var fr := DriftModel.Frame.new()
	var dt := 1.0 / HZ
	var t := 0.0
	while not st.finished and t < RUN_LIMIT:
		bot.tick(t, st, line, inp)
		fr.gas = inp.gas()
		fr.kick = inp.take_kick()
		fr.chain = sc.chain
		DriftModel.step(st, fr, line, p, dt)
		DriftScore.tick(sc, st, line, dt)
		var i := clampi(int(st.s), 0, out.size() - 1)
		out[i] = maxf(out[i], st.v)
		t += dt
	# A metre passed in under a frame keeps the speed before it.
	for i in range(1, out.size()):
		if out[i] <= 0.0:
			out[i] = out[i - 1]
	return out


## His pace cap at s (m/s): his solo pace there × CHASE_PACE (INF in run 1 or with no profile).
static func pace_cap(d: Duel, s: float) -> float:
	if d.pace.is_empty():
		return INF
	return d.pace[clampi(int(s), 0, d.pace.size() - 1)] * CHASE_PACE


## Hrabia's frame: his bot's thumb and his model's step (before the scores' ticks).
static func step_him(d: Duel, line: RefCounted, p: Dictionary, dt: float) -> void:
	d.bot.tick(d.t, d.him, line, d.him_in)
	d.him_fr.gas = d.him_in.gas()
	d.him_fr.kick = d.him_in.take_kick()
	d.him_fr.chain = d.him_sc.chain
	DriftModel.step(d.him, d.him_fr, line, p, dt)


## After both cars' steps and scores this frame: the gap, BLISKO's boost for the next frame, KONTAKT,
## his chase (run 2), PREZENT! on your spin. `you_events` are this frame's model events of the player.
static func couple(d: Duel, you: DriftModel.State, you_sc: DriftScore.Score, line: RefCounted, dt: float) -> void:
	d.said.clear()
	d.t += dt
	d.contact_t = maxf(0.0, d.contact_t - dt)
	if "spin" in you.events and not you.finished:
		d.him_sc.total += GIFT
		d.gifts += 1
		d.said.append("gift")
	var lead: DriftModel.State = d.him if d.run == 1 else you
	if d.lead_v >= 0.0 and (d.lead_v - lead.v) / maxf(dt, 0.0001) > SHARP:
		d.excuse_t = EXCUSE_S  # the leader braked hard (a brake check, a spin): a touch is his
	d.lead_v = lead.v
	d.excuse_t = maxf(0.0, d.excuse_t - dt)
	if d.run == 1 and d.bot != null and d.bot.has_method("wobbling") and bool(d.bot.wobbling(d.t)):
		d.excuse_t = maxf(d.excuse_t, dt)
	if d.run == 1:
		d.gap = gap(d.him.s, you.s)
		# A leader past the finish has left the line: nothing to touch, nothing to hold the chaser behind.
		var touching := not d.him.finished and contact(d.him, you, line)
		if touching or (d.gap < 0.0 and not d.him.finished):
			# No passing: a touch puts the chaser back at BLISKO's near edge, under the leader's speed.
			you.s = minf(you.s, d.him.s - CAR_LEN - CLOSE.x)
			you.v = minf(you.v, maxf(0.0, d.him.v - KONTAKT_V))
			d.gap = gap(d.him.s, you.s)
			_touch(d, you, you_sc)
		elif d.gap >= CLOSE.x:
			d.armed = true
		var near := is_close(d.gap) and not you.finished and not d.him.finished
		if near and not d.you_close:
			d.said.append("close")
		d.you_close = near
		you_sc.boost = BOOST if near else 1.0
		d.him_sc.boost = 1.0
		if near:
			d.close_s += dt
	else:
		var cap := pace_cap(d, d.him.s)
		d.gap = gap(you.s, d.him.s)
		d.crawl_t = d.crawl_t + dt if you.v < CRAWL and not you.finished and d.t > PARK_FROM else 0.0
		if d.crawl_t > PARK_S and not d.solo:
			d.solo = true  # parked: his solo lap from here, nobody to chase
			d.said.append("parked")
		if d.solo:
			d.gap = gap(you.s, d.him.s)
			d.him_sc.boost = 1.0
			you_sc.boost = 1.0
			return
		if d.gap < KEEP_BACK + KEEP_RAMP:
			# Behind a slower car he comes down to its speed by KEEP_BACK m of gap, and stops there behind a
			# stopped one (0b.7 R2: at least 2 m behind).
			cap = minf(cap, you.v + maxf(0.0, d.gap - KEEP_BACK) * KEEP_GAIN)
		if d.him.mode != DriftModel.Mode.SPIN:
			d.him.v = minf(d.him.v, cap)
		d.him.s = minf(d.him.s, you.s - CAR_LEN - CLOSE.x)
		d.gap = gap(you.s, d.him.s)
		if d.him.v < CRAWL and d.him.mode == DriftModel.Mode.DRIFT and d.gap < KEEP_BACK + 1.0:
			d.him.mode = DriftModel.Mode.GRIP  # crawling behind a stopped car: he straightens, his pile banks
			d.him.beta = 0.0
			DriftScore.bank(d.him_sc)
		if contact(you, d.him, line):
			d.him.s = minf(d.him.s, you.s - CAR_LEN - CLOSE.x)
			d.him.v = minf(d.him.v, maxf(0.0, you.v - KONTAKT_V))
			d.gap = gap(you.s, d.him.s)
			_touch(d, d.him, d.him_sc)
		elif d.gap >= CLOSE.x:
			d.armed = true
		var near := is_close(d.gap) and not d.him.finished
		if near:
			d.close_s += dt
			d.was_close = true
		elif d.was_close and d.gap > AWAY:
			d.was_close = false
			d.said.append("away")
		d.him_sc.boost = BOOST if near else 1.0
		you_sc.boost = 1.0


## The cars touched (the chaser `c` already pushed back): a KONTAKT once they were apart since the last
## one and the cooldown ran out, unless the leader caused it (`excuse_t`).
static func _touch(d: Duel, c: DriftModel.State, sc: DriftScore.Score) -> void:
	if not d.armed or d.contact_t > 0.0:
		return
	d.armed = false
	d.contact_t = KONTAKT_COOL
	if d.excuse_t > 0.0:
		d.excused += 1
		return
	_kontakt(d, c, sc)


## A KONTAKT on the chaser `c` (its state and score; the push back already took KONTAKT_V m/s): the first
## in the run costs KONTAKT_STEPS chain steps, any after it KONTAKT_SHARE of the pile as well.
static func _kontakt(d: Duel, c: DriftModel.State, sc: DriftScore.Score) -> void:
	d.contacts += 1
	d.said.append("contact")
	sc.chain = maxi(1, sc.chain - KONTAKT_STEPS)
	if d.contacts > 1:
		sc.pile *= 1.0 - KONTAKT_SHARE
		for k: String in sc.pile_parts:
			sc.pile_parts[k] *= 1.0 - KONTAKT_SHARE


## The bot chaser's one rule (the sim's and the game's --drift=quest:bot): close behind him in run 1
## it holds deeper to brake (critique section 2: "shallow to catch him, deep to brake").
static func chase_hold(d: Duel, you: DriftModel.State, inp: DriftInput, t: float) -> void:
	if d.run == 1 and d.gap < CHASE_DEEP and you.mode == DriftModel.Mode.DRIFT and absf(you.beta) < CHASE_MAX_DEG and not inp.down:
		inp.press(t)


## One whole run of the tandem with no scene (check_drift_event.gd): the player's bot `you_bot` (a
## drift_bot.gd, seeded by the caller) against Hrabia with `him_seed`. Ends when the player crosses the
## finish (or RUN_LIMIT); both piles bank then. Returns the two totals, the contacts, the gifts, BLISKO's
## seconds, the mean gap and the run's time.
static func run(run_no: int, you_bot: RefCounted, him_seed: int, wobble: bool, line: RefCounted, p: Dictionary, hold := false) -> Dictionary:
	var you := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	var inp := DriftInput.new()
	var fr := DriftModel.Frame.new()
	var d := make(run_no, him_seed, wobble, line, p, you)
	var dt := 1.0 / HZ
	var t := 0.0
	var gap_sum := 0.0
	var n := 0
	var away := 0
	var his_spins := 0
	while not you.finished and t < RUN_LIMIT:
		you_bot.tick(t, you, line, inp)
		if hold:
			chase_hold(d, you, inp, t)  # the in-game quest bot's rule only; a thumb has none
		fr.gas = inp.gas()
		fr.kick = inp.take_kick()
		fr.chain = sc.chain
		DriftModel.step(you, fr, line, p, dt)
		step_him(d, line, p, dt)
		DriftScore.tick(sc, you, line, dt)
		DriftScore.tick(d.him_sc, d.him, line, dt)
		couple(d, you, sc, line, dt)
		if "away" in d.said:
			away += 1
		if "spin" in d.him.events:
			his_spins += 1
		gap_sum += d.gap
		n += 1
		t += dt
	DriftScore.bank(sc)
	DriftScore.bank(d.him_sc)
	return {"you": sc.total, "him": d.him_sc.total, "contacts": d.contacts, "gifts": d.gifts, "close_s": d.close_s,
			"gap": gap_sum / maxf(1.0, float(n)), "time": t, "away": away, "you_spins": sc.spins, "him_spins": his_spins,
			"end_gap": d.gap, "excused": d.excused, "solo": d.solo}
