extends SceneTree
## Bokiem na Narodowym, PR 3: the side quest (drift_event.gd) and the final's tandem (drift_tandem.gd),
## docs/design/drift-narodowy.md 0b.7 E1-E7 with critique-drift.md changes 7, 8 and 11. No city: the pure
## tandem at 60 Hz, and the event with the stand-ins of fakes.gd (the HUD, the wallet; the real dialogue.gd
## for the words) entering the real stadium. Checks that:
## - T (the tandem): T1 the gap is the centres less a car, BLISKO 0.5-4 m; T2 the box test (end to end
##   and side by side at their edges, and turned); T3 a touch pushes the chaser back to 0.5 m under the
##   leader's speed, the first KONTAKT costs two chain steps, a held touch no second, the next after the cars
##   were apart half the pile, and a touch after the leader's hard braking or in his over-hold none; T4 in run 2 he is no faster than his
##   solo pace × 1.03 and stops at least 2 m behind a stopped player (R2); T4b a parked leader loses run 2; T5 your spin gives him 500
##   (PREZENT!); T6 run 2: a shallow fast player (needle SHALLOW°) pulls away (UCIEKASZ!, his BLISKO under
##   SHALLOW_CLOSE of the run) and a deep slow one (DEEP°) is caught (his BLISKO over DEEP_CLOSE, the mean
##   gap under 4 m); T7 run 1: a shallow chaser sits closer than a deep one; T8 the finals by skill over
##   SEEDS seeds (two runs each, Hrabia live, no chase help): the decent player wins in DECENT_WINS, the
##   clumsy and the shallow ones in at most CLUMSY_WINS, the deep one at least DEEP_WINS; T9 Hrabia is seeded (the same seed twice is the same run), never spins in the first
##   final and has his over-hold only in a fourth try; T10 the cut (drift_tracks.json "event" q_line) is
##   within Q_TOL of 55 % of the follower's median over Q_SEEDS seeds;
## - E (the event): E1 no call and no QUESTS row before a night meet, a call within FIRST_CALL after one;
##   E2 WCHODZĘ sets the gate's target, stopping in its ring calls the stadium's hook once; E3 short
##   qualifying runs and WYJDŹ pay 100 zł (once ever) and keep the quest open; a run over the cut goes to the final;
##   E4 a win pays 800 zł, 150 respect and the paint, closes the quest and saves on its card (and Darek
##   never rings again by his clock; QUESTS still starts the practice); a loss pays 250 zł once ever and
##   offers REWANŻ, which starts at the final; a draw (within 1 %) is one more pair; a fresh event on a won
##   wallet is "Bokiem: trening" with the practice's hello, after a lost final the rematch's; E5 ✕ inside,
##   on run 2's card, on the podium (the win kept) and on the drive (Darek rings again later); E6 the rescue calls are HOLD; no way in during a chase; E7 every line the event says comes from
##   dialogue.json "bokiem" with both languages and a speaker; the stadium's words have both;
##   W the warm-up ends early after a held 3 s drift and one flick, with Lena's tips by state.
## Prints `check_drift_event: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_drift_event.gd

const Fakes := preload("res://tools/fakes.gd")
const DriftLine := preload("res://scripts/drift_line.gd")
const DriftModel := preload("res://scripts/drift_model.gd")
const DriftScore := preload("res://scripts/drift_score.gd")
const DriftBot := preload("res://scripts/drift_bot.gd")
const DriftInput := preload("res://scripts/drift_input.gd")
const T := preload("res://scripts/drift_tandem.gd")
const DriftEvent := preload("res://scripts/drift_event.gd")
const Activity := preload("res://scripts/activity.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const QuestBook := preload("res://scripts/quest_book.gd")
const StoryQuests := preload("res://scripts/story_quests.gd")
const Garage := preload("res://scripts/garage.gd")

const DT := 1.0 / 60.0
const SEEDS := 8
const SHALLOW := 30.0
const DEEP := 52.0
const SHALLOW_CLOSE := 0.25
const DEEP_CLOSE := 0.6
const DECENT_WINS := Vector2i(2, 6)
const CLUMSY_WINS := 2
const DEEP_WINS := 3
const Q_SEEDS := 32
const Q_TOL := 0.03
## The tags drift_event.gd asks dialogue.json "bokiem" for.
const TAGS := ["call", "car", "gate", "decline", "practice", "rematch", "out", "tip", "retry", "bank", "transition", "zone", "spin",
		"warm_kick", "warm_shallow", "warm_deep", "warm_flick", "warm_done", "quali_pass", "chase", "draw", "podium", "bjorn", "kaska",
		"hrabia_intro", "hrabia_run2", "hrabia_lost", "hrabia_won"]
## The 13 lines of 0b.5 (the second tip as critique change 11 has it; its retry line about the wall dropped).
const OB_TAGS := ["call", "car", "gate", "tip", "bank", "transition", "zone", "spin", "bjorn", "hrabia_lost", "out", "retry"]
const WORDS := ["warmup", "quali", "final", "start", "to_final", "rematch", "again", "next", "take", "q_line", "you", "hrabia",
		"close", "contact", "away", "gift", "run1", "run2", "won", "lost_final", "draw", "passed", "short", "prize", "paid", "practice",
		"quest_name", "in", "not_today", "tail", "blurb"]


## The wallet with what the event reads beyond fakes.gd's: the jobs (the gate), the paints and the intro.
class EventWallet extends Fakes.Wallet:
	var jobs := {}
	var paints := {}
	var intro := {}


## A thumb that never touches the screen (the parking test, T4b).
class Idle extends RefCounted:
	func tick(_t: float, _st: RefCounted, _line: RefCounted, _inp: RefCounted) -> void:
		pass


class Police extends Node:
	var chase := false

	func chasing() -> bool:
		return chase


var fails: Array[String] = []
var line: RefCounted
var p: Dictionary = DriftModel.params()
var world: Node3D
var dlg: Node
var _file_lines := {}
var _said := 0


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	line = DriftLine.load_track("osemka")
	p = DriftModel.params()
	_tandem_rules()
	_tandem_bots()
	world = Node3D.new()
	root.add_child(world)
	dlg = Dialogue.new()
	root.add_child(dlg)
	_words()
	_e1_gate()
	_e2_drive()
	_e3_qualifying()
	_e4_final()
	_e5_quit()
	_e6_holds()
	_warmup()
	_e7_lines()
	if fails.is_empty():
		print("check_drift_event: OK")
		quit(0)
	else:
		for f in fails:
			print("check_drift_event: FAIL " + f)
		print("check_drift_event: %d problems" % fails.size())
		quit(1)


func _fail(what: String) -> void:
	fails.append(what)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fail(what)


# --- T: the tandem ---------------------------------------------------------------------------------

func _tandem_rules() -> void:
	# T1
	_expect(is_equal_approx(T.gap(20.0, 10.0), 6.0), "T1: gap of centres 10 m apart is %.2f (want 6)" % T.gap(20.0, 10.0))
	_expect(not T.is_close(0.4) and T.is_close(0.5) and T.is_close(4.0) and not T.is_close(4.1), "T1: BLISKO is 0.5-4 m")
	# T2
	var y := 0.7
	var f := DriftLine.dir(y)
	var side := DriftLine.left(y)
	_expect(T.boxes_overlap(Vector2.ZERO, y, f * 3.9, y) and not T.boxes_overlap(Vector2.ZERO, y, f * 4.1, y), "T2: end to end at 4 m")
	_expect(T.boxes_overlap(Vector2.ZERO, y, side * 1.7, y) and not T.boxes_overlap(Vector2.ZERO, y, side * 1.9, y), "T2: side by side at 1.8 m")
	# Turned 40°, its half length along the other's line is 2 cos 40° + 0.9 sin 40° = 2.11 m: they touch under 4.11 m.
	_expect(T.boxes_overlap(Vector2.ZERO, y, f * 4.05, y + deg_to_rad(40.0)) and not T.boxes_overlap(Vector2.ZERO, y, f * 4.2, y + deg_to_rad(40.0)),
			"T2: a car turned 40° behind another touches it under 4.11 m, not at 4.2 m")
	# T3: run 1, you driven into his bumper.
	var you := DriftModel.State.new()
	var sc := DriftScore.Score.new()
	var d := T.make(1, 1, false, line, p, you)
	d.him.s = 60.0
	d.him.v = 12.0
	you.s = 57.0
	you.v = 15.0
	sc.chain = 4
	sc.pile = 1000.0
	T.couple(d, you, sc, line, DT)
	_expect("contact" in d.said and sc.chain == 2 and absf(you.v - 10.0) < 0.01 and sc.pile == 1000.0,
			"T3: the first KONTAKT: said %s, chain %d (want 2), v %.1f (want 10: his 12 less 2), pile %.0f kept" % [d.said, sc.chain, you.v, sc.pile])
	_expect(you.s <= d.him.s - T.CAR_LEN - T.CLOSE.x + 0.001, "T3: the chaser pushed back to BLISKO's edge (s %.2f, his %.2f)" % [you.s, d.him.s])
	# Held against him (a thumb that keeps the gas): no second KONTAKT while the cars never came apart.
	for k in int(2.0 / DT):
		you.s = d.him.s - T.CAR_LEN + 0.2
		you.v = d.him.v + 1.0
		T.couple(d, you, sc, line, DT)
	_expect(d.contacts == 1 and sc.pile == 1000.0, "T3: held against him 2 s, still one KONTAKT (%d, pile %.0f)" % [d.contacts, sc.pile])
	# Apart, then in again: the second costs half the pile, not all of it.
	you.s = d.him.s - T.CAR_LEN - 2.0
	T.couple(d, you, sc, line, DT)
	sc.chain = 4
	you.s = d.him.s - T.CAR_LEN + 0.2
	T.couple(d, you, sc, line, DT)
	_expect(d.contacts == 2 and absf(sc.pile - 500.0) < 0.01 and sc.chain == 2 and sc.losses == 0,
			"T3: the second KONTAKT costs half the pile and two steps (%d contacts, pile %.0f, chain %d, %d losses)" % [d.contacts, sc.pile, sc.chain, sc.losses])
	# The leader brakes hard (a brake check, his over-hold): the touch is his, no KONTAKT.
	you = DriftModel.State.new()
	sc = DriftScore.Score.new()
	sc.pile = 800.0
	d = T.make(1, 1, false, line, p, you)
	d.him.s = 60.0
	d.him.v = 14.0
	you.s = 50.0
	you.v = 14.0
	T.couple(d, you, sc, line, DT)
	d.him.v = 10.0  # 4 m/s in one frame: 240 m/s²
	you.s = d.him.s - T.CAR_LEN + 0.2
	T.couple(d, you, sc, line, DT)
	_expect(d.contacts == 0 and d.excused == 1 and sc.pile == 800.0, "T3: a touch after his hard braking is excused (%d contacts, %d excused)" % [d.contacts, d.excused])
	_expect(DriftBot.hrabia(41, true).wobbling(DriftBot.hrabia(41, true).wobble_t + 0.3) and not DriftBot.hrabia(11, false).wobbling(10.0),
			"T3: his over-hold window excuses a touch")
	# T4: run 2, his pace cap and his stop behind a stopped player.
	you = DriftModel.State.new()
	sc = DriftScore.Score.new()
	d = T.make(2, 3, false, line, p, you)
	d.him.s = 100.0
	d.him.v = 40.0
	you.s = 140.0
	you.v = 20.0
	T.couple(d, you, sc, line, DT)
	var cap := T.pace_cap(d, 100.0)
	_expect(d.him.v <= cap + 0.001 and cap < 25.0, "T4: his speed %.1f m/s under his cap %.1f (his solo × %.2f)" % [d.him.v, cap, T.CHASE_PACE])
	you.s = 120.0
	you.v = 0.0
	d.him.s = 100.0
	d.him.v = 14.0
	var min_gap := INF
	for k in 600:
		d.him.s += d.him.v * DT
		T.couple(d, you, sc, line, DT)
		min_gap = minf(min_gap, d.gap)
	_expect(d.him.v < 0.05 and min_gap >= T.KEEP_BACK - 0.05, "T4: behind a stopped player he stops %.2f m back (min %.2f, v %.2f; want ≥ 2)" % [d.gap, min_gap, d.him.v])
	# T4b: a parked leader loses run 2: past PARK_S s at a crawl he drives his solo lap.
	var parked := T.run(2, Idle.new(), 12, false, line, p)
	var solo := T.run(2, Idle.new(), 12, false, line, p)
	print("check_drift_event: T4b run 2 with you parked: you %.0f, Hrabia %.0f (solo after the park: %s)" % [parked["you"], parked["him"], parked["solo"]])
	_expect(bool(parked["solo"]) and float(parked["him"]) > 5000.0 and float(parked["you"]) < float(parked["him"]),
			"T4b: parked leader loses run 2 (you %.0f, Hrabia %.0f, solo %s)" % [parked["you"], parked["him"], parked["solo"]])
	_expect(is_equal_approx(float(solo["him"]), float(parked["him"])), "T4b: the parked run is seeded")
	# T5
	you = DriftModel.State.new()
	sc = DriftScore.Score.new()
	d = T.make(1, 5, false, line, p, you)
	you.events.append("spin")
	var before := d.him_sc.total
	T.couple(d, you, sc, line, DT)
	_expect("gift" in d.said and is_equal_approx(d.him_sc.total - before, T.GIFT), "T5: your spin gives him %.0f (want %.0f)" % [d.him_sc.total - before, T.GIFT])


func _tandem_bots() -> void:
	# T6: run 2, shallow against deep.
	var sh := _runs(2, "decent", SHALLOW, 300)
	var dp := _runs(2, "decent", DEEP, 400)
	print("check_drift_event: T6 run 2, you lead: shallow %.0f° his BLISKO %.0f %% of the run, mean gap %.1f m, UCIEKASZ %.1f a run; deep %.0f° his BLISKO %.0f %%, mean gap %.1f m" % [
			SHALLOW, sh["close"] * 100.0, sh["gap"], sh["away"], DEEP, dp["close"] * 100.0, dp["gap"]])
	_expect(sh["close"] < SHALLOW_CLOSE and sh["away"] >= 0.5, "T6: the shallow fast leader pulls away (his BLISKO %.0f %%, UCIEKASZ %.1f)" % [sh["close"] * 100.0, sh["away"]])
	_expect(dp["close"] > DEEP_CLOSE and dp["gap"] < T.CLOSE.y, "T6: the deep slow leader is caught (his BLISKO %.0f %%, gap %.1f m)" % [dp["close"] * 100.0, dp["gap"]])
	# T7: run 1, the chaser.
	var c_sh := _runs(1, "decent", SHALLOW, 500)
	var c_dp := _runs(1, "decent", DEEP, 600)
	print("check_drift_event: T7 run 1, you chase: shallow mean gap %.1f m, BLISKO %.0f %%, %.1f contacts; deep mean gap %.1f m, BLISKO %.0f %%" % [
			c_sh["gap"], c_sh["close"] * 100.0, c_sh["contacts"], c_dp["gap"], c_dp["close"] * 100.0])
	_expect(c_sh["gap"] < c_dp["gap"], "T7: a shallow chaser sits closer (%.1f m) than a deep one (%.1f m)" % [c_sh["gap"], c_dp["gap"]])
	# T8: whole finals by skill, the player's bot with no chase help (a thumb has none; Fable's review).
	var rows := PackedStringArray()
	var wins := {}
	for kind: Array in [["decent", DriftBot.NEEDLE], ["clumsy", DriftBot.NEEDLE], ["shallow", SHALLOW], ["deep", DEEP]]:
		var w := 0
		var draws := 0
		var you_sum := 0.0
		var him_sum := 0.0
		for sd in range(1, SEEDS + 1):
			var bot_kind := "clumsy" if kind[0] == "clumsy" else "decent"
			var a := T.run(1, DriftBot.make(bot_kind, 100 + sd, 1.0, 0.4, 0.0, float(kind[1])), sd * 10 + 1, false, line, p)
			var b := T.run(2, DriftBot.make(bot_kind, 200 + sd, 1.0, 0.4, 0.0, float(kind[1])), sd * 10 + 2, false, line, p)
			var y_t := float(a["you"]) + float(b["you"])
			var h_t := float(a["him"]) + float(b["him"])
			you_sum += y_t
			him_sum += h_t
			var r := DriftEvent.final_outcome(roundi(y_t), roundi(h_t))
			if r == "won":
				w += 1
			elif r == "draw":
				draws += 1
		wins[kind[0]] = w
		rows.append("%s %d-%d-%d (you %.0f, Hrabia %.0f)" % [kind[0], w, draws, SEEDS - w - draws, you_sum / SEEDS, him_sum / SEEDS])
	print("check_drift_event: T8 finals by skill over %d seeds, won-draw-lost: %s" % [SEEDS, ", ".join(rows)])
	_expect(int(wins["decent"]) >= DECENT_WINS.x and int(wins["decent"]) <= DECENT_WINS.y, "T8: the decent player wins %d of %d (want %d-%d)" % [wins["decent"], SEEDS, DECENT_WINS.x, DECENT_WINS.y])
	_expect(int(wins["clumsy"]) <= CLUMSY_WINS, "T8: the clumsy player wins %d of %d (want ≤ %d)" % [wins["clumsy"], SEEDS, CLUMSY_WINS])
	_expect(int(wins["shallow"]) <= CLUMSY_WINS, "T8: the shallow (fast, close, touching) player wins %d of %d (want ≤ %d)" % [wins["shallow"], SEEDS, CLUMSY_WINS])
	_expect(int(wins["deep"]) >= DEEP_WINS, "T8: the deep (slow, safe) player wins %d of %d (want ≥ %d)" % [wins["deep"], SEEDS, DEEP_WINS])
	# T9: Hrabia seeded, no spin in the first final, his wobble only in a fourth try.
	var r1 := T.run(1, DriftBot.make("decent", 7), 11, false, line, p)
	var r1b := T.run(1, DriftBot.make("decent", 7), 11, false, line, p)
	_expect(is_equal_approx(float(r1["him"]), float(r1b["him"])) and is_equal_approx(float(r1["you"]), float(r1b["you"])), "T9: the same seeds twice, the same run")
	var spins := 0
	for run_no in [1, 2]:
		spins += int(T.run(run_no, DriftBot.make("decent", 50 + run_no), 10 + run_no, false, line, p)["him_spins"])
	_expect(spins == 0, "T9: Hrabia spins %d times in the first final (want none)" % spins)
	_expect(DriftBot.hrabia(41, true).wobble_t != INF and DriftBot.hrabia(11, false).wobble_t == INF, "T9: his over-hold only when asked (a fourth try)")
	# T10: the cut from the follower.
	var totals: Array[float] = []
	for sd in range(1, Q_SEEDS + 1):
		totals.append(float(DriftBot.run("decent", sd, line, p)["total"]))
	totals.sort()
	var med := (totals[Q_SEEDS / 2 - 1] + totals[Q_SEEDS / 2]) * 0.5
	var q := int(DriftLine.data().get("event", {}).get("q_line", 0))
	print("check_drift_event: T10 the cut %d, 55 %% of the follower's median %.0f is %.0f" % [q, med, 0.55 * med])
	_expect(absf(float(q) - 0.55 * med) <= Q_TOL * 0.55 * med, "T10: the cut %d is off 55 %% of the follower's median (%.0f) by more than %.0f %%" % [q, 0.55 * med, Q_TOL * 100.0])


## SEEDS runs of the tandem's `run_no` with the player's bot at `needle`: the means of his (run 2) or
## your (run 1) BLISKO share, the gap, the UCIEKASZ and the contacts.
func _runs(run_no: int, kind: String, needle: float, seed0: int) -> Dictionary:
	var close := 0.0
	var gap := 0.0
	var away := 0.0
	var contacts := 0.0
	for sd in range(1, SEEDS + 1):
		var r := T.run(run_no, DriftBot.make(kind, seed0 + sd, 1.0, 0.4, 0.0, needle), sd * 10 + run_no, false, line, p)
		close += float(r["close_s"]) / maxf(float(r["time"]), 1.0)
		gap += float(r["gap"])
		away += float(r["away"])
		contacts += float(r["contacts"])
	return {"close": close / SEEDS, "gap": gap / SEEDS, "away": away / SEEDS, "contacts": contacts / SEEDS}


# --- E: the event ----------------------------------------------------------------------------------

## An event as main.gd wires it, with stand-ins; `where` is the player's place and speed (the check moves it).
func _event(where: Dictionary, jobs := {}) -> DriftEvent:
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var w := EventWallet.new()
	w.jobs = jobs
	root.add_child(w)
	var ev := DriftEvent.new()
	ev.hud = hud
	ev.wallet = w
	ev.dialogue_node = dlg
	ev.log_on = true
	ev.tag = "drift"
	ev.colour = Color.ORANGE
	ev.gate = Vector2(1326.0, -787.0)
	ev.vehicle = func() -> Array: return [where["at"], where["kmh"], false, 0.0]
	ev.clock = func() -> float: return 22.0
	var car := Fakes.Car.new()
	world.add_child(car)
	ev._player_car = car
	ev.story_closed = func(id: String) -> bool: return QuestBook.is_done(w.intro, id)
	ev.story_finished = func(id: String) -> void: QuestBook.mark_done(w.intro, id)
	ev.invites = {"bokiem": ["Bokiem na Narodowym", "Sideways at the Narodowy"]}
	world.add_child(ev)
	ev.setup(world)
	ev.set_process(false)  # the check steps it
	ev.set_physics_process(false)
	return ev


## Every line the event said is a line of dialogue.json "bokiem" with both languages and a speaker (E7).
func _free(ev: DriftEvent) -> void:
	if _file_lines.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
		for l: Variant in (d.get("bokiem", []) if d is Dictionary else []):
			_file_lines[str(l[0])] = str(l[1])
	for l: Array in ev.said_lines:
		_said += 1
		_expect(_file_lines.get(str(l[1]), "") == str(l[2]) and str(l[3]) != "", "E7: said a line that is not dialogue.json's: %s" % [l])
	ev.hud.queue_free()
	ev.wallet.queue_free()
	ev._player_car.queue_free()
	if ev._ui_layer != null:
		ev._ui_layer.queue_free()
	ev.queue_free()


func _e1_gate() -> void:
	_expect(not DriftEvent.gate_jobs({}) and DriftEvent.gate_jobs({"meet_race": 1}) and DriftEvent.gate_jobs({"meet_drag": 2})
			and not DriftEvent.gate_jobs({"kebab": 9}), "E1: the gate is a night meet's race or drag")
	var where := {"at": Vector3(0, 0, 0), "kmh": 0.0}
	var ev := _event(where)
	var def := ev.story_def()
	_expect(not StoryQuests.shown(def) and QuestBook.story_facts([def], [22.0, 5], {}).is_empty(), "E1: before a night meet the questline is not in QUESTS")
	for k in 3600 * 2:
		ev._idle_tick(0.5)
	_expect(ev.phase == Activity.Phase.IDLE, "E1: Darek rang before the first night meet")
	(ev.wallet as EventWallet).jobs = {"meet_race": 1}
	var t := 0.0
	while ev.phase == Activity.Phase.IDLE and t < DriftEvent.FIRST_CALL.y + DriftEvent.RETRY + 1.0:
		ev._idle_tick(0.25)
		t += 0.25
	_expect(ev.phase == Activity.Phase.RING and t >= DriftEvent.FIRST_CALL.x, "E1: after a night meet Darek rings at %.0f s (want %.0f-%.0f)" % [t, DriftEvent.FIRST_CALL.x, DriftEvent.FIRST_CALL.y])
	_expect(StoryQuests.shown(def) and QuestBook.story_facts([def], [22.0, 5], {}).size() == 1, "E1: after a night meet the questline is in QUESTS")
	# A no: he rings again after NEXT_CALL, not before.
	ev.card_pressed(1)
	var t2 := 0.0
	while ev.phase == Activity.Phase.IDLE and t2 < DriftEvent.NEXT_CALL.y + DriftEvent.RETRY + 1.0:
		ev._idle_tick(0.5)
		t2 += 0.5
	_expect(ev.phase == Activity.Phase.RING and t2 >= DriftEvent.NEXT_CALL.x, "E1: after a no he rings again at %.0f s (want %.0f-%.0f)" % [t2, DriftEvent.NEXT_CALL.x, DriftEvent.NEXT_CALL.y])
	_expect((ev.hud as Fakes.Hud).toasts.size() > 0, "E1: a no gets Darek's line")
	_free(ev)


func _e2_drive() -> void:
	var where := {"at": Vector3(900, 0, -400), "kmh": 30.0}
	var ev := _event(where, {"meet_race": 1})
	var entered := [0]
	ev.enter_hook = func() -> void: entered[0] += 1
	ev.ring()
	ev.card_pressed(0)  # the call: answered
	var hud := ev.hud as Fakes.Hud
	_expect(ev.phase == Activity.Phase.OFFER and "WCHODZĘ" in str(hud.button_words), "E2: the offer's buttons are %s (want WCHODZĘ / NIE DZIŚ)" % hud.button_words)
	ev.card_pressed(0)  # WCHODZĘ
	var tp := ev.target_position()
	_expect(ev.phase == Activity.Phase.RUN and Vector2(tp.x, tp.z).distance_to(ev.gate) < 0.01, "E2: WCHODZĘ sets the gate's target (%s)" % tp)
	for k in 30:
		ev._run_tick(DT)
	_expect(entered[0] == 0, "E2: entered before the gate")
	where["at"] = Vector3(ev.gate.x + 2.0, 0.0, ev.gate.y)
	where["kmh"] = 20.0
	ev._run_tick(DT)
	_expect(entered[0] == 0, "E2: entered at 20 km/h (must stop in the ring)")
	where["kmh"] = 2.0
	for k in 30:
		ev._run_tick(DT)
	_expect(entered[0] == 1, "E2: stopping in the ring calls the stadium's hook %d times (want once)" % entered[0])
	_expect(ev.rescue_calls == Activity.RescueCalls.HOLD, "E6: the rescue calls are HOLD")
	_free(ev)


## An event in the stadium (the real one) at the stage the quest's run has reached.
func _inside(jobs := {"meet_race": 1}) -> DriftEvent:
	var where := {"at": Vector3.ZERO, "kmh": 0.0}
	var ev := _event(where, jobs)
	where["at"] = Vector3(ev.gate.x, 0.0, ev.gate.y)
	ev.ring()
	ev.card_pressed(0)
	ev.card_pressed(0)
	ev._run_tick(DT)
	return ev


func _e3_qualifying() -> void:
	var ev := _inside()
	_expect(ev.inside() and ev.stage == DriftEvent.Stage.WARMUP, "E3: in at the gate, the warm-up first (inside %s, stage %d)" % [ev.inside(), ev.stage])
	_expect((ev._player_car as Node).process_mode == Node.PROCESS_MODE_DISABLED, "E5: the car waits at the gate with its process off")
	ev._warm_over()
	_expect(ev.stage == DriftEvent.Stage.QUALI and "start" in ev._ui.card_ids(), "E3: qualifying's card with START")
	ev._card_button("start")
	ev._run_card(1000)
	_expect("retry" in ev._ui.card_ids() and "leave" in ev._ui.card_ids(), "E3: a short run offers PONÓW and WYJDŹ (%s)" % ev._ui.card_ids())
	ev._retry()
	ev._run_card(2000)
	ev._leave()
	var w := ev.wallet as EventWallet
	_expect(ev.outcome == "out" and w.money == DriftEvent.OUT_ZL and not ev.won() and ev.phase == Activity.Phase.IDLE,
			"E3: two short runs and WYJDŹ: %s, %d zł (want out, %d), quest open %s" % [ev.outcome, w.money, DriftEvent.OUT_ZL, not ev.won()])
	_expect(int(w.keep.get(DriftEvent.BEST_KEY, 0)) == 2000, "E3: the best run is kept (%s)" % w.keep)
	_free(ev)
	# The 100 zł is paid once ever: out again on a wallet that had it pays nothing.
	ev = _inside()
	ev.wallet.keep[DriftEvent.OUT_PAID_KEY] = 1
	ev._warm_over()
	ev._card_button("start")
	ev._run_card(1000)
	ev._leave()
	_expect(ev.outcome == "out" and (ev.wallet as EventWallet).money == 0, "E3: a second out pays %d zł (want 0: once ever)" % (ev.wallet as EventWallet).money)
	_free(ev)
	ev = _inside()
	ev._warm_over()
	ev._card_button("start")
	ev._run_card(ev.q_line + 10)
	_expect("to_final" in ev._ui.card_ids(), "E3: a run over the cut offers DO FINAŁU (%s)" % ev._ui.card_ids())
	ev._card_button("to_final")
	_expect(ev.stage == DriftEvent.Stage.FINAL and int(ev.wallet.keep.get(DriftEvent.FINAL_KEY, 0)) == 1, "E3: DO FINAŁU opens the final and remembers it")
	_free(ev)


func _e4_final() -> void:
	# A win.
	var ev := _inside()
	ev._open_final()
	ev._card_button("start")
	_expect(ev.duel != null and ev.duel.run == 1 and ev._him_car != null and ev._him_car.visible, "E4: the final's run 1 with Hrabia's car")
	var saves := (ev.wallet as EventWallet).saves
	ev.final_result(30000, 20000)
	var w := ev.wallet as EventWallet
	_expect("take" in ev._ui.card_ids(), "E4: a win's card has ODBIERZ (%s)" % ev._ui.card_ids())
	_expect(w.money == DriftEvent.PRIZE_ZL and w.respect == DriftEvent.PRIZE_RESPECT and w.paints.has(DriftEvent.PAINT_ID) and ev.won() and w.saves > saves,
			"E4: a win is paid, done and saved on its card, before ODBIERZ: %d zł, %d respect, paints %s, done %s, saves %d→%d" % [w.money, w.respect, w.paints, ev.won(), saves, w.saves])
	ev._card_button("take")
	_expect(w.money == DriftEvent.PRIZE_ZL and ev.outcome == "won", "E4: ODBIERZ only closes (%d zł, %s)" % [w.money, ev.outcome])
	_expect(not Garage.find(DriftEvent.PAINT_ID).is_empty() and Garage.rule(DriftEvent.PAINT_ID, "red", 0, w.paints, 0) == "switch", "E4: the Bokiem paint is in the garage and owned")
	_expect(str(ev.quest_name()[0]) == str(DriftLine.word("practice")[0]), "E4: after the win the questline is %s" % [ev.quest_name()])
	# Never again by his clock; QUESTS still starts the practice.
	for k in 4000:
		ev._idle_tick(0.5)
	_expect(ev.phase == Activity.Phase.IDLE, "E4: Darek rang by his clock after the quest was won")
	_expect(not ev._ring_turn(DriftEvent.ID), "E4: the kit's ring turn refuses a won quest")
	ev.ring()
	ev.card_pressed(0)
	ev.card_pressed(0)
	_expect(ev.practice and ev.run_story == "", "E4: QUESTS' call after the win is the practice (practice %s)" % ev.practice)
	_free(ev)
	# A loss, the rematch, a draw.
	ev = _inside()
	ev._open_final()
	ev.final_result(10000, 20000)
	w = ev.wallet as EventWallet
	_expect(w.money == DriftEvent.LOST_ZL and "rematch" in ev._ui.card_ids(), "E4: a loss pays %d zł (want 250) and offers REWANŻ (%s)" % [w.money, ev._ui.card_ids()])
	ev._card_button("rematch")
	_expect(ev.stage == DriftEvent.Stage.FINAL and ev.final_try == 2, "E4: REWANŻ starts the final again (try %d)" % ev.final_try)
	ev.final_result(20000, 20020)
	_expect("again" in ev._ui.card_ids(), "E4: a draw offers JESZCZE RAZ (%s)" % ev._ui.card_ids())
	ev._card_button("again")
	_expect(ev.pair == 1 and ev.stage == DriftEvent.Stage.FINAL, "E4: a draw is one more pair")
	ev.final_result(1000, 20000)
	ev._leave()
	_expect(ev.outcome == "lost" and not ev.won() and w.money == DriftEvent.LOST_ZL, "E4: a second loss pays nothing more: %s, %d zł (want %d)" % [ev.outcome, w.money, DriftEvent.LOST_ZL])
	_free(ev)
	# Once ever: a wallet that had the 250 zł gets none on a new visit's loss.
	ev = _inside()
	ev.wallet.keep[DriftEvent.LOST_PAID_KEY] = 1
	ev._open_final()
	ev.final_result(1000, 20000)
	_expect((ev.wallet as EventWallet).money == 0 and "rematch" in ev._ui.card_ids(), "E4: a loss after the paid one pays %d zł (want 0)" % (ev.wallet as EventWallet).money)
	_free(ev)
	# A draw is within 1 % of the larger total.
	_expect(DriftEvent.final_outcome(30000, 29800) == "draw" and DriftEvent.final_outcome(30000, 29600) == "won" and DriftEvent.final_outcome(29600, 30000) == "lost",
			"E4: a draw within 1 %% (30000-29800 %s, 30000-29600 %s)" % [DriftEvent.final_outcome(30000, 29800), DriftEvent.final_outcome(30000, 29600)])
	# After a reload: a won quest's name, invite and hello are the practice's (main.gd wires story_closed after story_def).
	ev = _event({"at": Vector3.ZERO, "kmh": 0.0}, {"meet_race": 1})
	ev.story = ev.story_def()
	QuestBook.mark_done((ev.wallet as EventWallet).intro, DriftEvent.ID)
	ev._idle_tick(0.1)
	var pr := DriftLine.word("practice")
	_expect(str(ev.story["pl"]) == str(pr[0]) and str(ev.invites[DriftEvent.ID][0]) == str(pr[0]) and _is_line(ev.story["hello"], "practice"),
			"E4: a fresh event on a won wallet: %s, invite %s, hello %s" % [ev.story["pl"], ev.invites[DriftEvent.ID], ev.story["hello"]])
	_free(ev)
	# ...and a final lost before: the rematch's hello.
	ev = _event({"at": Vector3.ZERO, "kmh": 0.0}, {"meet_race": 1})
	ev.story = ev.story_def()
	ev.wallet.keep[DriftEvent.FINAL_KEY] = 1
	ev._idle_tick(0.1)
	_expect(_is_line(ev.story["hello"], "rematch"), "E4: after a lost final Darek's hello is the rematch's (%s)" % [ev.story["hello"]])
	_free(ev)
	# The rematch from QUESTS starts at the final.
	ev = _inside()
	ev.wallet.keep[DriftEvent.FINAL_KEY] = 1
	ev._close("quit")
	ev.ring()
	ev.card_pressed(0)
	ev.card_pressed(0)
	ev._run_tick(DT)
	_expect(ev.inside() and ev.stage == DriftEvent.Stage.FINAL, "E4: a rematch starts at the final (stage %d)" % ev.stage)
	_free(ev)


func _e5_quit() -> void:
	var ev := _inside()
	ev._warm_over()
	ev._card_button("start")
	ev._leave()  # the ✕ mid-run
	var w := ev.wallet as EventWallet
	_expect(ev.outcome == "quit" and w.money == 0 and not ev.inside() and (ev._player_car as Node).process_mode == Node.PROCESS_MODE_INHERIT
			and ev.hud.visible, "E5: ✕ inside: %s, %d zł, inside %s, car process %d" % [ev.outcome, w.money, ev.inside(), (ev._player_car as Node).process_mode])
	_free(ev)
	# ✕ on run 2's card (the final under way): quit, nothing paid, the final kept for a rematch.
	ev = _inside()
	ev._open_final()
	ev._card_button("start")
	ev.you_runs.append(9000)
	ev.him_runs.append(8000)
	ev.final_run = 2
	ev._ui.show_card("run 2", [["next", "next"]])
	ev._leave()
	w = ev.wallet as EventWallet
	_expect(ev.outcome == "quit" and w.money == 0 and not ev.won() and ev._rematch(), "E5: ✕ on run 2's card: %s, %d zł, rematch %s" % [ev.outcome, w.money, ev._rematch()])
	_free(ev)
	# ✕ on the podium card: the win stays (paid on the card).
	ev = _inside()
	ev._open_final()
	ev.final_result(30000, 20000)
	ev._leave()
	w = ev.wallet as EventWallet
	_expect(ev.outcome == "won" and w.money == DriftEvent.PRIZE_ZL and ev.won(), "E5: ✕ on the podium: %s, %d zł, won %s" % [ev.outcome, w.money, ev.won()])
	_free(ev)
	# ✕ on the drive to the gate: Darek calls again later, not never.
	var where := {"at": Vector3(900, 0, -400), "kmh": 30.0}
	ev = _event(where, {"meet_race": 1})
	ev._idle_tick(0.1)
	ev.ring()
	ev.card_pressed(0)
	ev.card_pressed(0)
	_expect(ev.stage == DriftEvent.Stage.DRIVE and ev.takes_abort(), "E5: on the drive the ✕ takes the run (stage %d)" % ev.stage)
	ev.abort()
	var t := 0.0
	while ev.phase == Activity.Phase.IDLE and t < DriftEvent.NEXT_CALL.y + DriftEvent.RETRY + 1.0:
		ev._idle_tick(0.5)
		t += 0.5
	_expect(ev.phase == Activity.Phase.RING, "E5: ✕ on the drive, Darek rings again at %.0f s (want by %.0f)" % [t, DriftEvent.NEXT_CALL.y])
	_free(ev)


## `pair` (a [pl, en]) is one of dialogue.json "bokiem"'s lines tagged `tag_`.
func _is_line(pair: Variant, tag_: String) -> bool:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	for l: Variant in (d.get("bokiem", []) if d is Dictionary else []):
		if (l as Array).size() > 2 and str((l[2] as Dictionary).get("only", "")) == tag_ and str(l[0]) == str(pair[0]):
			return true
	return false


func _e6_holds() -> void:
	var where := {"at": Vector3.ZERO, "kmh": 0.0}
	var ev := _event(where, {"meet_race": 1})
	var pol := Police.new()
	pol.chase = true
	root.add_child(pol)
	ev.police = pol
	var entered := [0]
	ev.enter_hook = func() -> void: entered[0] += 1
	where["at"] = Vector3(ev.gate.x, 0.0, ev.gate.y)
	ev.ring()
	ev.card_pressed(0)
	ev.card_pressed(0)
	ev._run_tick(DT)
	_expect(entered[0] == 0 and (ev.hud as Fakes.Hud).toasts.size() > 0, "E6: no way in during a chase (a toast says lose the tail)")
	pol.chase = false
	ev._run_tick(DT)
	_expect(entered[0] == 1, "E6: in once the chase is over")
	pol.queue_free()
	_free(ev)


## W: the warm-up played by the decent bot in the real stadium, the frames stepped by hand.
func _warmup() -> void:
	var ev := _inside()
	ev._bot = DriftBot.make("decent", 3)
	var frames := 0
	var tips := {}
	while ev.stage == DriftEvent.Stage.WARMUP and frames < 60 * 45:
		ev._physics_process(DT)
		frames += 1
	for l: Array in ev.said_lines:
		tips[str(l[0])] = true
	print("check_drift_event: W the warm-up ended at %.1f s with %d flicks; Lena said %s" % [ev._clock, ev.score.flicks, tips.keys()])
	_expect(ev.stage == DriftEvent.Stage.QUALI and ev._clock < 40.0, "W: the warm-up ends early after a 3 s drift and a flick (%.1f s, stage %d)" % [ev._clock, ev.stage])
	_expect(tips.has("tip") and tips.has("warm_done") and tips.size() >= 4, "W: Lena's tips by state (%s)" % [tips.keys()])
	_expect(ev.score.total == 0.0 or not ev._ui.scored, "W: the warm-up is not scored")
	_free(ev)


func _words() -> void:
	for id: String in WORDS:
		var w := DriftLine.word(id)
		_expect(w.size() >= 2 and str(w[0]) != "" and str(w[1]) != "" and str(w[0]) != id, "E7: the stadium's word %s has both languages" % id)


func _e7_lines() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var group: Array = d.get("bokiem", []) if d is Dictionary else []
	var tags := {}
	for l: Variant in group:
		var ok: bool = l is Array and (l as Array).size() == 3 and str(l[0]) != "" and str(l[1]) != "" and l[2] is Dictionary and l[2].has("who") and l[2].has("only")
		_expect(ok, "E7: a \"bokiem\" line without both languages, a tag and a speaker: %s" % [l])
		if ok:
			tags[str(l[2]["only"])] = true
	for t: String in TAGS:
		_expect(tags.has(t), "E7: dialogue.json \"bokiem\" has no %s line" % t)
	for t: String in OB_TAGS:
		_expect(tags.has(t), "E7: 0b.5's %s line is missing" % t)
	_expect(group.size() >= 13, "E7: %d \"bokiem\" lines (0b.5 has 13)" % group.size())
	print("check_drift_event: E7 %d \"bokiem\" lines, %d tags; the events said %d lines, all from the file" % [group.size(), tags.size(), _said])
