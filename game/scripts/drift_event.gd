extends "res://scripts/drift_stadium.gd"
## Bokiem na Narodowym, PR 3: the side quest itself (F 2026-11-26: a side quest under ZADANIA / QUESTS,
## not a story chapter; docs/design/drift-narodowy.md 0b.5 with critique-drift.md changes 7, 8 and 11).
## An activity of the kit by way of the stadium (drift_stadium.gd, the venue: its floor, cars, camera and
## practice), so one activity joins the director and the venue owner (venues.gd) with one line of main.gd.
##   - The gate: Darek „Bawarka" calls only once the first night meet is done (wallet.gd `jobs` "meet_race"
##     + "meet_drag" ≥ 1, read only; street_meet.gd is not edited), FIRST_CALL s after it opens, again
##     NEXT_CALL s after a no (pacing.json "bokiem"), through the kit's `_ring_turn` and the call gate; never
##     again once the quest is won (the kit's `story_closed`: the MISSIONS RULE). Until the gate opens the
##     questline is not on the map nor in QUESTS (story_quests.gd `shown`).
##   - The call (WCHODZĘ / NIE DZIŚ) sends the player to the night meet's car park "Parking pod Narodowym"
##     (street_meet.gd MEETS `narodowy`); stopping in its ring opens the stadium (never in a chase: „Najpierw
##     zgub ogon”). Darek also waits there in person (story_quests.gd's start), and QUESTS phones him.
##   - Inside: ROZGRZEWKA (one unscored lap, Lena's tips by the car's state, over early after a 3 s drift
##     and one flick), KWALIFIKACJE (a run's total against Q_LINE, best kept, PONÓW without limit; WYJDŹ
##     after a run short of it: out, 100 zł), FINAŁ (two tandem runs against Hrabia, drift_tandem.gd: run 1
##     he leads, run 2 you lead; the live bar TY vs HRABIA; a draw is one more pair), the result card.
##   - Pay (wallet.gd, once, at the gate): a win 800 zł, 150 respect and the "Bokiem" paint (garage.gd
##     PAINTS `bokiem`), the quest done; a lost final 250 zł, the rematch starts at the final (`keep`
##     FINAL_KEY); out in qualifying 100 zł, the quest open; ✕ inside: back at the gate, nothing paid.
##   - After the win the questline is "Bokiem: trening" in QUESTS: the stadium's free practice, its best
##     kept in `keep` BEST_KEY (nothing saved under --nosave: wallet.gd's `persistent`).
## Words: dialogue.json "bokiem" (each line's `who`), the stadium's words in drift_tracks.json.
## Add-ons: Dialogue Manager not used (a two-button call and the stadium's cards; no branching scene);
## Beehave not used (Hrabia is the drift bot on the line: a needle and a thumb, no behaviours to pick).
## Flags (dev_flags.gd): --drift=quest (the gate forced open, Darek calls at once), --drift=quest:bot (the
## whole quest played by itself: the call answered, the car put at the gate, the decent bot drives, every
## card pressed; it logs "drift: quest over: ..."), --drift=final:bot (the same, straight to the final as a
## rematch).

const DriftTandem := preload("res://scripts/drift_tandem.gd")
const StreetMeet := preload("res://scripts/street_meet.gd")
const Notebook := preload("res://scripts/notebook.gd")
const GameTimeX := preload("res://scripts/game_time.gd")
const Lang := preload("res://scripts/lang.gd")

const ID := "bokiem"
## The car park's row in street_meet.gd MEETS.
const GATE_ROW := "narodowy"
const PRIZE_ZL := 800
const PRIZE_RESPECT := 150
const LOST_ZL := 250
const OUT_ZL := 100
const PAINT_ID := "bokiem"
## wallet.gd `keep`: the practice's best on Ósemka, and "qualified once" (a rematch starts at the final).
const BEST_KEY := "bokiem_best_osemka"
const FINAL_KEY := "bokiem_final"
## The night meets that open the gate (wallet.gd `jobs`).
const GATE_JOBS := ["meet_race", "meet_drag"]
## The warm-up ends early after a drift held this long (s) and one flick.
const WARM_HOLD := 3.0
## Lena's tips come at most this often (s) and show this long.
const TIP_GAP := 4.0
const TIP_S := 3.6
## Final totals this close (points) are a draw: one more pair.
const DRAW_PTS := 50
## Stopped in the gate's ring: under this (km/h).
const STOP_KMH := 8.0
## --drift=quest:bot: the cards are pressed this long after they show (s).
const BOT_CARD := 1.5

static var HOURS: Vector2 = Pacer.span("bokiem", "hours")
static var FIRST_CALL: Vector2 = Pacer.span("bokiem", "first_call")
static var NEXT_CALL: Vector2 = Pacer.span("bokiem", "next_call")
static var RETRY: float = Pacer.num("bokiem", "retry")

enum Stage { NONE, DRIVE, WARMUP, QUALI, FINAL, PODIUM }

## The questline's def as story_quests.gd keeps it (main.gd sets it after `stories.add`): its name turns
## into "Bokiem: trening" once the quest is won.
var story: Dictionary = {}
## The car park's ring (map x, z); INF without the map's origin.
var gate := Vector2.INF
var stage := Stage.NONE
## This visit is the free practice (the DEV page, --drift=osemka, or the questline once won).
var practice := false
## The qualifying cut (drift_tracks.json "event") and the board's other names.
var q_line := 7700
var board: Array = []
## What the stadium calls on arrival (the check counts it).
var enter_hook: Callable
## The run's outcome once closed: "won", "lost", "out", "quit".
var outcome := ""
var quali_runs := 0
var quali_best := 0
## The final: its attempt (seeds Hrabia), the run of the pair (1, 2), the tiebreak pairs, the totals.
var final_try := 0
var final_run := 1
var pair := 0
var you_runs: Array[int] = []
var him_runs: Array[int] = []
var duel: DriftTandem.Duel
## Every [tag, pl, en, who] said this session (check_drift_event E7).
var said_lines: Array = []
## The questline's gate opened by itself (check and the --drift=quest flags).
var force_gate := false
var quest_bot := false
var police: Node
var dialogue_node: Node

var _call_in := INF
var _gate_was := false
var _dev_in := false
var _rng := RandomNumberGenerator.new()
var _him_car: DriftCar
var _warm_t := 0.0
var _warm_said := {}
var _tip_t := 0.0
var _shallow_t := 0.0
var _says: Array = []
var _bot_t := 0.0
var _paid := 0
var _lost_paid := false


# --- the wiring ----------------------------------------------------------------------------------

func _init() -> void:
	rescue_calls = RescueCalls.HOLD  # Darek's night holds the rescue line's countdown (0b.5, E6)


func install(ctx: GameCtx) -> bool:
	if not super(ctx):
		return false
	tag = "drift"
	dialogue_node = ctx.dialogue
	police = ctx.police
	run_hours = HOURS
	var org: Array = ctx.data.get("origin", []) if ctx.data is Dictionary else []
	if org.size() == 2:
		gate = gate_point(org)
	_rng.randomize()
	return true


## The car park's ring on the map from the map's origin ([lat, lon]).
## The car park's name [pl, en] (street_meet.gd MEETS).
static func gate_name() -> Array:
	for row: Dictionary in StreetMeet.MEETS:
		if str(row["id"]) == GATE_ROW:
			return row["name"]
	return ["", ""]


static func gate_point(org: Array) -> Vector2:
	for row: Dictionary in StreetMeet.MEETS:
		if str(row["id"]) == GATE_ROW:
			return Notebook.project(org, float(row["ll"][0]), float(row["ll"][1]))
	return Vector2.INF


func setup(world: Node3D) -> void:
	super.setup(world)
	enter_hook = _enter_stadium
	var ev: Dictionary = DriftLine.data().get("event", {})
	q_line = int(ev.get("q_line", q_line))
	board = ev.get("board", [])


func joined(ctx: GameCtx) -> void:
	super.joined(ctx)
	var parts := _flag.split(":")
	if parts.is_empty() or not parts[0] in ["quest", "final"]:
		return
	force_gate = true
	quest_bot = parts.has("bot")
	autopilot = autopilot or quest_bot
	if quest_bot:
		_bot = DriftBot.make("decent", 1)
	if parts[0] == "final" and wallet != null:
		wallet.keep[FINAL_KEY] = 1
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if phase == Phase.IDLE:
			_log("quest: the call (%s)" % _flag)
			ring())


## The questline for story_quests.gd (main.gd `_build_stories`, one line): its name, Darek, the gate.
func story_def() -> Dictionary:
	var call := _words("call")
	var name := quest_name()
	return {"id": ID, "pl": str(name[0]), "en": str(name[1]), "who": [StreetMeet.FRIEND, StreetMeet.FRIEND],
			"hello": [call[0], call[1]], "at": gate, "colour": colour, "hours": HOURS, "days": [],
			"call": ring, "meet": meet, "busy": busy, "idle": idle, "shown": shown}


## The questline's name now: the quest, or "Bokiem: trening" once won.
func quest_name() -> Array:
	return DriftLine.word("practice") if won() else DriftLine.word("quest_name")


## The quest was won (the kit's `story_closed`, main.gd: wallet.gd `intro` qdone_bokiem).
func won() -> bool:
	return story_closed_now(ID)


## The questline shows on the map and in QUESTS: its gate is open (or it was won).
func shown() -> bool:
	return gate_open() or won()


## The gate (0b.5, E1): the first night meet is done, read only from wallet.gd `jobs`.
func gate_open() -> bool:
	return force_gate or (wallet != null and gate_jobs(wallet.get("jobs") if wallet.get("jobs") is Dictionary else {}))


static func gate_jobs(jobs: Dictionary) -> bool:
	var n := 0
	for k: String in GATE_JOBS:
		n += int(jobs.get(k, 0))
	return n >= 1


# --- the call ------------------------------------------------------------------------------------

## Darek's own clock (pacing.json "bokiem"): FIRST_CALL s after the gate opens, NEXT_CALL after a no or
## a run that did not win, RETRY while something holds it; never once the quest is won (`_ring_turn`).
func _idle_tick(dt: float) -> void:
	if won() or not gate_open():
		return
	if not _gate_was:
		_gate_was = true
		_call_in = _rng.randf_range(FIRST_CALL.x, FIRST_CALL.y)
		_log("gate open: Darek calls in %.0f s" % _call_in)
	_call_in -= dt
	if _call_in > 0.0:
		return
	_call_in = RETRY
	if vehicle.is_valid() and bool(vehicle.call()[2]):
		return
	if not force_hours and not GameTimeX.may_call(HOURS, float(clock.call())):
		return
	if not free_now.call():
		return
	if _ring_turn(ID) and ring():
		_call_in = INF


func _call_card() -> Dictionary:
	var w := _words("practice" if won() else ("rematch" if _rematch() else "call"))
	return {"who": StreetMeet.FRIEND, "about": [w[0], w[1]]}


func _offer_card() -> Dictionary:
	var name := quest_name()
	var body := _words("car") if not won() and not _rematch() else _words("gate")
	var yes := DriftLine.word("in")
	var no := DriftLine.word("not_today")
	return {"title": [str(name[0]).to_upper(), str(name[1]).to_upper()], "body": [body[0], body[1]], "face": StreetMeet.FRIEND,
			"buttons": PackedStringArray(["%s|%s" % [yes[0], yes[1]], "%s|%s" % [no[0], no[1]]])}


func _refused(timed_out: bool) -> void:
	var w := _words("decline")
	hud.toast(w[0], w[1])
	_call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)
	_log("call %s: Darek calls again in %.0f s" % ["rang out" if timed_out else "turned down", _call_in])


## A rematch is due: qualified once, not won yet.
func _rematch() -> bool:
	return wallet != null and int(wallet.keep.get(FINAL_KEY, 0)) > 0 and not won()


# --- the run -------------------------------------------------------------------------------------

## The DEV page's BOKIEM is the free practice (the stadium's own), never the quest.
func _ask_in() -> void:
	_dev_in = true
	super._ask_in()
	if phase != Phase.RUN:
		_dev_in = false


func _begin() -> void:
	practice = _dev_in or _pose != Vector2.INF or _flag.begins_with(TRACK) or won()
	outcome = ""
	_paid = 0
	_lost_paid = false
	if practice:
		run_story = ""  # a practice before the win must not close the quest (activity.gd `finish`)
		stage = Stage.NONE
		if not _dev_in and won() and gate != Vector2.INF:
			_to_gate()  # Bokiem: trening from QUESTS: drive to the gate first
			return
		_enter_stadium()
		return
	_to_gate()


func _to_gate() -> void:
	stage = Stage.DRIVE
	if gate == Vector2.INF:
		_arrive()
		return
	set_target(gate)
	if quest_bot and _player_car != null:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if stage == Stage.DRIVE and phase == Phase.RUN:
				var y := _ground(gate)
				_player_car.global_position = Vector3(gate.x, y + 0.05, gate.y)
				_player_car.set("vel", Vector3.ZERO)
				_player_car.set("forward_speed", 0.0)
				_player_car.reset_physics_interpolation()
				_log("quest: the car put at the gate %.0f, %.0f" % [gate.x, gate.y]))
	_log("quest: to the gate %.0f, %.0f" % [gate.x, gate.y])


func _run_tick(_dt: float) -> void:
	if stage != Stage.DRIVE:
		return
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var at: Vector3 = v[0]
	var far := Vector2(at.x, at.z).distance_to(gate) if at != Vector3.INF else INF
	var name := gate_name()
	status(str(quest_name()[0]).to_upper(), "", "%d m" % int(far) if far != INF else "", [name[0], name[1]], 0.0)
	if far <= arrive and float(v[1]) <= STOP_KMH and not bool(v[2]):
		if police != null and police.has_method("chasing") and bool(police.chasing()):
			var w := DriftLine.word("tail")
			hud.toast(str(w[0]), str(w[1]))
			return
		_arrive()


func _arrive() -> void:
	stage = Stage.NONE
	clear_target()
	hide_status()
	_log("quest: at the gate, in")
	if enter_hook.is_valid():
		enter_hook.call()


func stop_spot() -> Vector3:
	return _target if stage == Stage.DRIVE else Vector3.INF


func grounded() -> Array:
	return DriftLine.word("grounded") if inside() else []


func _can_abort() -> bool:
	return stage == Stage.DRIVE


## Into the stadium at the gate: the practice, the warm-up, or (a rematch) the final.
func _entered() -> void:
	best = int(wallet.keep.get(BEST_KEY, 0)) if wallet != null else 0
	_ui.stage = ""
	_ui.scored = true
	_ui.bar_on = false
	if practice:
		super._entered()
		return
	_queue_say("gate")
	if _rematch():
		_open_final()
	else:
		_start_warmup()


func _start_warmup() -> void:
	stage = Stage.WARMUP
	_warm_t = 0.0
	_warm_said = {}
	_ui.stage = _w("warmup")
	_ui.scored = false
	_queue_say("tip")
	_new_run()
	_log("quest: warm-up")


func _new_run() -> void:
	super._new_run()
	_shallow_t = 0.0
	_bot_t = 0.0
	if _him_car != null:
		_him_car.visible = stage == Stage.FINAL
	if stage == Stage.FINAL:
		var him_seed := final_try * 10 + pair * 2 + final_run
		duel = DriftTandem.make(final_run, him_seed, final_try % 4 == 0, line, params, st)
		_make_him_car()
		_him_car.state = duel.him
		_him_car.visible = true
		_him_car.reset_physics_interpolation()
		_ui.bar_on = true
		_log("final: run %d (pair %d, try %d, Hrabia's seed %d%s)" % [final_run, pair, final_try, him_seed, ", his wobble" if final_try % 4 == 0 else ""])
	else:
		duel = null


## Hrabia's car, made on the first final (the stadium's second DriftCar: black with gold stripes).
func _make_him_car() -> void:
	if _him_car != null:
		return
	_him_car = DriftCar.new()
	_him_car.name = "HrabiaCar"
	_him_car.line = line
	_him_car.origin = PLACE
	_him_car.floor_y = PLACE.y
	_root.add_child(_him_car)
	_him_car.set_paint(Color("#15151a"), Color("#d6a630"))
	_cars.append(_him_car)
	_flood_lit(_him_car)


# --- the frame ------------------------------------------------------------------------------------

## --drift=quest:bot: the bot chaser keeps the sim's rule (drift_tandem.gd chase_hold), or it drives into him.
func _bot_more() -> void:
	if stage == Stage.FINAL and duel != null and quest_bot:
		DriftTandem.chase_hold(duel, st, thumb, _clock)


func _tick_more(dt: float) -> void:
	match stage:
		Stage.WARMUP:
			_warm_frame(dt)
		Stage.FINAL:
			if duel == null:
				return
			DriftTandem.step_him(duel, line, params, dt)
			DriftScore.tick(duel.him_sc, duel.him, line, dt)
			DriftTandem.couple(duel, st, score, line, dt)
			for w in duel.said:
				match w:
					"contact", "gift":
						_ui.flash(w, "", UiKit.ALERT)
						Access.buzz(40, 0.8)
					"close", "away":
						_ui.flash(w, "", UiKit.GO)
				_log("tandem: %s (gap %.1f m)" % [w, duel.gap])


## Lena's tips by the car's state, and the warm-up's early end (critique change 11).
func _warm_frame(dt: float) -> void:
	_tip_t -= dt
	if st.mode in [DriftModel.Mode.DRIFT, DriftModel.Mode.FLIP]:
		_warm_t += dt
	else:
		_warm_t = 0.0
	_shallow_t = _shallow_t + dt if st.mode == DriftModel.Mode.DRIFT and absf(st.beta) < 25.0 else 0.0
	if _warm_t >= WARM_HOLD and score.flicks >= 1:
		_queue_say("warm_done")
		_warm_over()
		return
	var tip := ""
	if "spin" in score.said:
		tip = "spin"
	elif score.flicks >= 1 and not _warm_said.has("transition"):
		tip = "transition"
	elif st.mode == DriftModel.Mode.GRIP and st.v * 3.6 > DriftModel.KICK_KMH and line.bend_ahead(st.s) != 0:
		tip = "warm_kick"
	elif st.mode == DriftModel.Mode.DRIFT and absf(st.beta) > 58.0:
		tip = "warm_deep"
	elif _shallow_t > 0.8:
		tip = "warm_shallow"
	elif st.mode == DriftModel.Mode.DRIFT and float(line.flip_dt(st.s, st.v)) > -1.3 and float(line.flip_dt(st.s, st.v)) < -0.4:
		tip = "warm_flick"
	if tip == "" or _tip_t > 0.0 or (_warm_said.has(tip) and tip != "spin"):
		return
	_warm_said[tip] = true
	_tip_t = TIP_GAP
	var l := _words(tip)
	_ui.say(str(l[2]), Lang.pick(str(l[0]), str(l[1])), TIP_S)


func _warm_over() -> void:
	_over = true
	st.v = 0.0
	st.beta = 0.0
	st.gas = 0.0
	st.mode = DriftModel.Mode.GRIP
	stage = Stage.QUALI
	_ui.stage = _w("quali")
	_ui.scored = true
	_ui.show_card(_quali_board(), [["start", "start"]])
	_queue_say("bjorn")
	_log("quest: warm-up over (%.1f s, %d flicks), qualifying" % [_clock, score.flicks])


## The qualifying card's board: the cut and the other two names with their scores.
func _quali_board() -> String:
	var lines := PackedStringArray(["%s · %s %s" % [_w("quali"), _w("q_line"), DriftUi.num(q_line)], ""])
	for b: Array in board:
		lines.append("%s  %s" % [str(b[0]), DriftUi.num(int(b[1]))])
	if quali_best > 0:
		lines.append("%s  %s" % [_w("you"), DriftUi.num(quali_best)])
	return "\n".join(lines)


func _frame_visuals(dt: float) -> void:
	super._frame_visuals(dt)
	if _him_car != null and _him_car.visible and duel != null and not _over:
		var h := duel.him
		if h.mode in [DriftModel.Mode.DRIFT, DriftModel.Mode.FLIP, DriftModel.Mode.SPIN] and absf(h.beta) > 12.0 and _rng.randf() < h.v * dt / PUFF_EVERY:
			var side := signf(h.beta) if h.beta != 0.0 else 1.0
			_puff(_him_car.global_transform * Vector3(0.78 * side, 0.4, 1.3))
	if stage == Stage.FINAL:
		_ui.bar_on = true
		# Live: the banked runs, this run's bank and the pile still at stake (a KONTAKT or a spin drops it).
		var mine := _sum(you_runs) + (roundi(score.total + score.pile) if not _over else 0)  # over: in you_runs
		var his := _sum(him_runs) + (roundi(duel.him_sc.total + duel.him_sc.pile) if duel != null and not _over else 0)
		_ui.bar_you = mine
		_ui.bar_him = his
	else:
		_ui.bar_on = false


func _process(dt: float) -> void:
	super(dt)
	if not inside() or _ui == null:
		return
	if not _says.is_empty() and not _ui.saying():
		var l: Array = _says.pop_front()
		_ui.say(str(l[2]), Lang.pick(str(l[0]), str(l[1])), TIP_S)
	if quest_bot and _ui.result_up():
		_bot_t += dt
		if _bot_t >= BOT_CARD:
			_bot_t = 0.0
			_ui.press_card(bot_button(_ui.card_ids(), quali_runs))
	else:
		_bot_t = 0.0


## The button the test bot presses: the way on (START, DO FINAŁU, DALEJ, JESZCZE RAZ, ODBIERZ), PONÓW
## for a short qualifying run up to twice, else WYJDŹ (a lost final ends the test run).
static func bot_button(ids: PackedStringArray, runs_done: int) -> String:
	for id in ["take", "start", "to_final", "next", "again"]:
		if id in ids:
			return id
	if "retry" in ids and runs_done < 3:
		return "retry"
	return "leave" if "leave" in ids else (ids[0] if not ids.is_empty() else "")


# --- the cards inside ------------------------------------------------------------------------------

func _run_card(total: int) -> void:
	match stage:
		Stage.NONE:
			super._run_card(total)
			_keep_best(total)
		Stage.WARMUP:
			_warm_over()
		Stage.QUALI:
			quali_runs += 1
			quali_best = maxi(quali_best, total)
			_keep_best(total)
			if total >= q_line:
				_ui.show_card("%s\n%s · %s\n%s %s" % [_w("passed"), _w("run"), DriftUi.num(total), _w("q_line"), DriftUi.num(q_line)], [["to_final", "to_final"]])
				_queue_say("quali_pass")
				hud.cue("win")
			else:
				_ui.show_card("%s\n%s · %s\n%s %s · %s %s" % [_w("short"), _w("run"), DriftUi.num(total), _w("q_line"), DriftUi.num(q_line),
						_w("best"), DriftUi.num(quali_best)], [["retry", "retry"], ["leave", "leave"]])
				_queue_say("retry")
				hud.cue("fail")
			_log("qualifying: run %d, %d (cut %d, best %d)" % [quali_runs, total, q_line, quali_best])
		Stage.FINAL:
			DriftScore.bank(duel.him_sc)
			you_runs.append(total)
			him_runs.append(roundi(duel.him_sc.total))
			_log("final: run %d over: you %d, Hrabia %d (%d contacts, %d gifts, close %.1f s)" % [final_run, total, roundi(duel.him_sc.total),
					duel.contacts, duel.gifts, duel.close_s])
			if final_run == 1:
				final_run = 2
				_ui.show_card("%s\n%s %s · %s %s" % [_w("run2"), _w("you"), DriftUi.num(_sum(you_runs)), _w("hrabia"), DriftUi.num(_sum(him_runs))], [["next", "start"]])
				_queue_say("hrabia_run2")
			else:
				final_result(_sum(you_runs), _sum(him_runs))


## The final's two (or more) runs are in: a win, a loss or a draw (one more pair).
func final_result(you: int, him: int) -> void:
	_ui.bar_on = false
	var line_t := "%s %s · %s %s" % [_w("you"), DriftUi.num(you), _w("hrabia"), DriftUi.num(him)]
	if absi(you - him) < DRAW_PTS:
		_ui.show_card("%s\n%s" % [_w("draw"), line_t], [["again", "again"]])
		_queue_say("draw")
		_log("final: a draw %d to %d, one more pair" % [you, him])
		return
	if you > him:
		stage = Stage.PODIUM
		_ui.show_card("%s\n%s\n\n%s" % [_w("won"), line_t, _prize_words()], [["take", "take"]])
		_queue_say("hrabia_lost")
		_queue_say("podium")
		_fire_flames()
		_wave()
		hud.cue("win")
	else:
		if not _lost_paid and wallet != null:
			_lost_paid = true
			_paid += LOST_ZL
			wallet.pay(LOST_ZL, 0, "")
		_ui.show_card("%s\n%s\n\n%s" % [_w("lost_final"), line_t, DriftUi.w("paid") % DriftUi.num(LOST_ZL)], [["rematch", "rematch"], ["leave", "leave"]])
		_queue_say("hrabia_won")
		hud.cue("fail")
	_log("final: %s %d to %d" % ["won" if you > him else "lost", you, him])


func _prize_words() -> String:
	var w := DriftLine.word("prize")
	return Lang.pick(str(w[0]) % [DriftUi.num(PRIZE_ZL), PRIZE_RESPECT], str(w[1]) % [DriftUi.num(PRIZE_ZL), PRIZE_RESPECT])


func _card_button(id: String) -> void:
	match id:
		"start", "next":
			_ui.hide_result()
			_new_run()
		"to_final", "rematch":
			_open_final()
		"again":
			pair += 1
			final_run = 1
			_ui.hide_result()
			_new_run()
		"take":
			_close("won")


## The final's first card: Hrabia's words, START.
func _open_final() -> void:
	stage = Stage.FINAL
	final_try += 1
	final_run = 1
	pair = 0
	you_runs.clear()
	him_runs.clear()
	_lost_paid = false
	if wallet != null and int(wallet.keep.get(FINAL_KEY, 0)) == 0:
		wallet.keep[FINAL_KEY] = 1
		wallet.save()
	_over = true
	_ui.stage = _w("final")
	_ui.scored = true
	_ui.show_card(_w("run1"), [["start", "start"]])
	_queue_say("hrabia_intro")
	_queue_say("chase")
	_log("final: try %d" % final_try)


## PONÓW: the practice's and the qualifying's without limit, the warm-up's again; none in the final.
func _retry() -> void:
	if not inside() or stage in [Stage.FINAL, Stage.PODIUM]:
		return
	_ui.hide_result()
	_new_run()


## ✕ and WYJDŹ: the practice's end; WYJDŹ on a short qualifying card is out (100 zł), on a lost final's
## card the loss; the ✕ anywhere else is back at the gate with nothing paid (E5).
func _leave() -> void:
	if phase != Phase.RUN:
		return
	if stage == Stage.NONE:
		_keep_best(best)
		_close("practice")
		return
	var card := _ui.result_up()
	if card and stage == Stage.QUALI and quali_runs > 0 and quali_best < q_line:
		_close("out")
	elif card and stage == Stage.FINAL and _lost_paid:
		_close("lost")
	elif card and stage == Stage.PODIUM:
		_close("won")
	else:
		_close("quit")


## The run ends at the gate: what it pays, the toast, the log line, the questline's state.
func _close(how: String) -> void:
	outcome = how
	_exit_stadium()
	var w: Array = []
	match how:
		"won":
			_paid += PRIZE_ZL
			if wallet != null:
				var paints: Variant = wallet.get("paints")
				if paints is Dictionary:
					(paints as Dictionary)[PAINT_ID] = int(Time.get_date_string_from_system().replace("-", ""))
				wallet.pay(PRIZE_ZL, PRIZE_RESPECT, ID)
			var p := DriftLine.word("prize")
			w = [str(p[0]) % [DriftUi.num(PRIZE_ZL), PRIZE_RESPECT], str(p[1]) % [DriftUi.num(PRIZE_ZL), PRIZE_RESPECT]]
		"out":
			_paid += OUT_ZL
			if wallet != null:
				wallet.pay(OUT_ZL, 0, "")
			var o := _words("out")
			w = [o[0], o[1]]
		"lost":
			var r := _words("rematch")
			w = [r[0], r[1]]
	if not w.is_empty():
		hud.toast(str(w[0]), str(w[1]))
	print("drift: quest over: %s, paid %d zł, qualifying %d runs (best %d, cut %d), final %s" % [how, _paid, quali_runs, quali_best, q_line,
			"%s to %s" % [_sum(you_runs), _sum(him_runs)] if not you_runs.is_empty() else "not driven"])
	if how == "won":
		finish()  # the kit marks the quest done (story_finished): Darek never calls about it again
		if not story.is_empty():
			var n := quest_name()
			story["pl"] = str(n[0])
			story["en"] = str(n[1])
	else:
		end_how = "quit" if how == "quit" else "done"
		run_story = ""
		_end(call_cool)
	if not story.is_empty():
		# Darek met at the gate (story_quests.gd `_greet`) says what the call would: the rematch, the practice.
		var hi: Array = _call_card()["about"]
		story["hello"] = [hi[0], hi[1]]
	if how != "won" and how != "practice":
		_call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)


func _ended() -> void:
	super._ended()
	stage = Stage.NONE
	_dev_in = false
	duel = null
	_says.clear()
	if _him_car != null:
		_him_car.visible = false


func _keep_best(total: int) -> void:
	if wallet == null or total <= int(wallet.keep.get(BEST_KEY, 0)):
		return
	wallet.keep[BEST_KEY] = total
	wallet.save()


# --- words ---------------------------------------------------------------------------------------

## A line of dialogue.json "bokiem" with `tag`: [pl, en, who] ([tag, tag, ""] when it is missing).
func _words(tag_: String) -> Array:
	var l: Array = []
	if dialogue_node != null and dialogue_node.has_method("line"):
		l = dialogue_node.line(ID, tag_, true)
	if l.size() < 2:
		push_warning("drift_event.gd: no line '%s' in dialogue.json \"%s\"" % [tag_, ID])
		return [tag_, tag_, ""]
	var notes: Dictionary = l[2] if l.size() > 2 and l[2] is Dictionary else {}
	var out := [str(l[0]), str(l[1]), str(notes.get("who", ""))]
	said_lines.append([tag_] + out)
	return out


func _queue_say(tag_: String) -> void:
	_says.append(_words(tag_))


func _w(id: String) -> String:
	return DriftUi.w(id)


static func _sum(a: Array[int]) -> int:
	var n := 0
	for x in a:
		n += x
	return n
