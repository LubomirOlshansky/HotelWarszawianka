extends Node
## Dym u Senatorka: the shisha lounge quest (F's ask 2026-11-08; docs/design/shisha-lounge.md, the
## script docs/design/shisha-lounge-script.md, the lines in data/shisha.json).
##
## Ivan phones ("📞 IVAN DZWONI", ODBIERZ / ODRZUĆ, then JADĘ! / NIE DZIŚ) any evening 17:00-02:00,
## or walks up in person at his block in 19. Dzielnica (story_quests.gd). Pick him up at his block,
## then Bogdan at the courts on Żelazna (straight from tennis: a draw, the Wola shisha champion),
## then drive to the Warsaw Financial Centre, Emilii Plater 53. On the way the two only argue (car
## bubbles: the flavour, the strength). The entrance is marked (F 2026-11-11: "I don't see how to
## enter"): a teal stop ring on Emilii Plater's kerb and a gold ring with its column at the revolving
## door under the SENATOREK canopy. Stop in either and the three walk in: no card outside. Inside
## (lounge.gd) the doorman and the lift play as the arrival, then the waiter, then at the table the
## three choices on the lounge's own panel: whose flavour (Ivan's watermelon-mint, Bogdan's cucumber
## ice cream, or the master's pick), how strong (1 tea, 3 a date, 5 politics: Bogdan likes it
## strong, Ivan can't take it) and the pipe's name; then the mini-game with Mistrz Dymek and PALIĆ /
## TARAS / WYJDŹ. After: drop Bogdan at the courts and Ivan at his block; the pay.
##
## Bubbles in the car come from data/shisha.json "scenes", one line every SCENE_GAP s. Cards use the
## hud's call cards; this script answers card_pressed only while its own card is up (`_card`).
## ✕ gives up (Ivan catches the night bus). The calls (missions.gd) are paused while it runs.
##
## Cost: idle a 0.25 s timer; during the quest one pickup beacon (as the rave's), on the way to the
## lounge a second one at the door.
##
## Flags (main.gd): --shisha-call (Ivan rings now), --shisha-meet (he gets in now, the rest as
## after a pickup), --shisha-door (both in, the car 25 m from the lounge's entrance), --shisha-lounge
## (straight into the lounge), --shisha=0 (none), --shisha-log.

const Beacon := preload("res://scripts/beacon.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Rave := preload("res://scripts/rave.gd")
const Access := preload("res://scripts/access.gd")
const Landmarks := preload("res://scripts/landmarks.gd")

const DATA := "res://data/shisha.json"
const NAME := ["Dym u Senatorka", "Smoke at Senatorek"]
const FRIEND := "Ivan"
const FRIEND2 := "Bogdan"
const COLOUR := Color("#2fb8a0")        ## the quest's colour: lounge teal
const PICK_COLOUR := Color("#ffc23a")   ## a friend waiting (the rides' amber)
const BUBBLE := Color("#7fe0cf")
const GOLD := Color("#e2bf7a")

## Ivan's block in 19. Dzielnica (Kolejowa / Przyokopowa; landmarks.gd D19 estate).
const IVAN_LL := [52.22735, 20.98147]
## The courts on Żelazna, halfway between the estate and the tower (courts.json; F 2026-11-08:
## WTS DESKA is too far).
const COURT_LL := [52.23065, 20.99282]
## The Warsaw Financial Centre's portico on Emilii Plater (Emilii Plater 53).
const LOUNGE_LL := [52.23348, 21.00250]
const LOUNGE_STREET := "Plater"
## The revolving door under the canopy (landmarks.gd `_wcf_street`: WCF_LOW's first edge at
## WCF_DOOR_T), the canopy's front this far out of the facade.
const ENTRY_OUT := 7.5
const ENTRY_R := 6.0

## The quest's hours (any day): from the evening to the small hours.
const HOURS := Vector2(17.0, 2.0)
## Ivan's first call and the next, in free-play seconds.
const FIRST_CALL := Vector2(240.0, 420.0)
const NEXT_CALL := Vector2(1500.0, 2400.0)
const RING_LIFE := 25.0
## Stopping: within these metres of the ring, under STOP_KMH, for HOLD s.
const PICK_R := 7.0
const DOOR_R := 12.0
const STOP_KMH := 9.0
const HOLD := 0.8
## Bubbles: one scene line every SCENE_GAP s.
const SCENE_GAP := 3.4
const BUBBLE_S := 3.2
## Pay: the friends' fare and respect; leaving early pays half and no respect.
const PAY := 120
const RESPECT := 30
const RESULT_LIFE := 14.0

enum State { IDLE, RING, OFFER, TO_IVAN, TO_BOGDAN, TO_LOUNGE, INSIDE, DROP_BOGDAN, DROP_IVAN, RESULT }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var missions: Node
var map: Node3D
var graph: LaneGraph
## [position, km/h, flying] of the player's vehicle.
var vehicle: Callable
## {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## True when nothing else is on (main.gd).
var free_now: Callable
## Into the lounge (main.gd `_enter_lounge`: lounge.gd) with the votes dictionary, empty: the lounge
## asks them at the table and fills this same dictionary (the result card reads the pipe's name).
var enter_lounge: Callable
var log_on := false
var auto := true
var origin := [52.234, 21.024]

var state := State.IDLE
## The kerbs on this map ({at, side, street, ...} as Rave.kerb_near), {} where none.
var home := {}
var court := {}
var door := {}
## The votes: flavour "ivan" / "bogdan" / "master", strength 1..5, the pipe's name (lounge.gd).
var votes := {}
## The revolving door's point on the pavement (Vector3.INF if no WCF door kerb).
var entry := Vector3.INF
## The lounge's outcome: "smoke", "terrace", "leave"; its score 0..9.
var outcome := ""
var score := 0
var last_pay := {}
var nights := 0
var scenes := {}

var call_in := 0.0
var _rng := RandomNumberGenerator.new()
var _tick := 0.0
var _hold_t := 0.0
var _ring_t := 0.0
var _result_t := 0.0
var _card := false
var _queue: Array = []
var _scene_t := 0.0
var _calls_were := false
var _pick: Node3D
var _door: Node3D
const TICK := 0.25


func setup(world: Node3D, seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	call_in = _rng.randf_range(FIRST_CALL.x, FIRST_CALL.y)
	scenes = load_scenes()
	if graph != null:
		var f := find_kerbs(graph, origin)
		home = f["home"]
		court = f["court"]
		door = f["door"]
	_pick = Beacon.new()
	world.add_child(_pick)
	_pick.setup(PICK_COLOUR, Color("#16161a"))
	_pick.pattern = Beacon.Pattern.DASHED
	_pick.visible = false
	_door = Beacon.new()
	world.add_child(_door)
	_door.setup(GOLD, Color("#16161a"))
	_door.waving = false
	_door.visible = false
	if not door.is_empty():
		entry = entry_point(door["at"])
		if map != null and map.has_method("ground_height"):
			entry.y = map.ground_height(entry.x, entry.z)
	if hud != null:
		hud.card_pressed.connect(_on_card)
		hud.abort_pressed.connect(func() -> void:
			if state in [State.TO_IVAN, State.TO_BOGDAN, State.TO_LOUNGE]:
				_give_up())
	_log("home %s, court %s, door %s; Ivan rings in %.0f s" % [_where(home), _where(court), _where(door), call_in])


# --- the rules (static: check_shisha.gd runs them) --------------------------------------------

## data/shisha.json: {scenes, taps, jars}.
static func load_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return parsed if parsed is Dictionary else {}


static func load_scenes() -> Dictionary:
	return load_data().get("scenes", {})


## The quest's three places on this map: Ivan's block, the courts, the lounge's door (on Emilii
## Plater), each the nearest ground kerb ({} if none).
static func find_kerbs(g: LaneGraph, org: Array) -> Dictionary:
	var h := Notebook.project(org, float(IVAN_LL[0]), float(IVAN_LL[1]))
	var c := Notebook.project(org, float(COURT_LL[0]), float(COURT_LL[1]))
	var d := Notebook.project(org, float(LOUNGE_LL[0]), float(LOUNGE_LL[1]))
	return {"home": Rave.kerb_near(g, h, 120.0), "court": Rave.kerb_near(g, c, 120.0),
			"door": kerb_named(g, d, 80.0, LOUNGE_STREET)}


## As Rave.kerb_near, but only on a street whose name has `name` in it (falls back to any).
static func kerb_named(g: LaneGraph, q: Vector2, reach: float, name: String) -> Dictionary:
	for r: float in [0.0, 15.0, 30.0, 45.0, 60.0, 80.0]:
		if r > reach:
			break
		for k in (1 if r == 0.0 else 12):
			var p: Vector2 = q + Vector2(r, 0).rotated(TAU * k / 12.0)
			var kerb := Rave.kerb_near(g, p, 20.0)
			if not kerb.is_empty() and name in String(kerb["street"]):
				return kerb
	return Rave.kerb_near(g, q, reach)


## The revolving door's pavement point, under the canopy's front, from landmarks.gd's WCF footprint;
## `toward` (the door kerb) picks the facade's street side.
static func entry_point(toward: Vector3) -> Vector3:
	var a0: Vector2 = Landmarks.WCF_LOW[0]
	var a1: Vector2 = Landmarks.WCF_LOW[1]
	var d := a0.lerp(a1, Landmarks.WCF_DOOR_T)
	var n := (a1 - a0).normalized().orthogonal()
	if n.dot(Vector2(toward.x, toward.z) - d) < 0.0:
		n = -n
	var p := d + n * ENTRY_OUT
	return Vector3(p.x, toward.y, p.y)


## In the quest's hours (they wrap past midnight).
static func open_at(hour: float) -> bool:
	return Rave.in_hours(hour, HOURS)


## The pay: [złoty, respect] for an outcome and the mini-game's score (0..9).
static func pay_for(how: String, mix_score: int) -> Array:
	if how == "leave":
		return [PAY / 2, 0]
	return [PAY, RESPECT + 2 * clampi(mix_score, 0, 9)]


## The votes' defaults when a card times out or the car gets there first.
static func default_vote(k: int) -> int:
	return [2, 1, 0][k]


## A vote card: [title pl, title en, body pl, body en, buttons].
static func vote_card(k: int) -> Array:
	match k:
		0:
			return ["KTO WYBIERA SMAK?", "WHO PICKS THE FLAVOUR?",
					"Ivan chce arbuz z miętą. Bogdan chce lody z ogórka.", "Ivan wants watermelon-mint. Bogdan wants cucumber ice cream.",
					PackedStringArray(["IVAN|IVAN", "BOGDAN|BOGDAN", "MISTRZ|MASTER"])]
		1:
			return ["JAK MOCNA?", "HOW STRONG?",
					"Bogdan: mocna. Ivan: lekka, mocnej nie da rady. Skala: herbata 1, Sejm 5.", "Bogdan: strong. Ivan: light, he can't take strong. Scale: tea 1, politics 5.",
					PackedStringArray(["HERBATA|TEA", "RANDKA|DATE", "SEJM|POLITICS"])]
		_:
			return ["JAK NAZYWAMY FAJKĘ?", "WHAT DO WE CALL THE PIPE?",
					"Bogdan już wie: Forhend.", "Bogdan already knows: Forehand.",
					PackedStringArray(["FORHEND|FOREHAND", "KAZIK|KAZIK", "TRAMWAJ|TRAM"])]


## A vote's answer into the votes dictionary.
static func apply_vote(v: Dictionary, k: int, i: int) -> void:
	match k:
		0:
			v["flavour"] = ["ivan", "bogdan", "master"][clampi(i, 0, 2)]
		1:
			v["strength"] = [1, 3, 5][clampi(i, 0, 2)]
		_:
			v["name"] = [["Forhend", "Forehand"], ["Kazik", "Kazik"], ["Tramwaj", "Tram"]][clampi(i, 0, 2)]


## The scene the car plays after a vote.
static func vote_scene(v: Dictionary, k: int) -> String:
	match k:
		0:
			return "flavour_" + String(v.get("flavour", "master"))
		1:
			var s := int(v.get("strength", 3))
			return "strength_low" if s <= 2 else ("strength_high" if s >= 4 else "strength_mid")
	return "name"


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	_tick += dt
	if _tick >= TICK:
		step(_tick)
		_tick = 0.0


func step(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var kmh: float = v[1]
	_play(dt)
	match state:
		State.IDLE:
			if auto and _free() and open_at(_hour()):
				call_in -= dt
				if call_in <= 0.0 and not ring():
					call_in = 20.0
		State.RING, State.OFFER:
			_ring_t += dt
			if _ring_t > RING_LIFE:
				_close_card()
				hud.toast("Nieodebrane połączenie: %s" % FRIEND, "Missed call: %s" % FRIEND)
				_reset()
		State.TO_IVAN:
			_status("IVAN · 19. Dzielnica", "Zatrzymaj się przy Ivanie", "Stop by Ivan", at, home["at"], PICK_COLOUR)
			if _arrived(dt, at, kmh, home["at"], PICK_R):
				_board_ivan()
		State.TO_BOGDAN:
			_status("BOGDAN · korty na Żelaznej", "Zatrzymaj się przy kortach", "Stop by the courts", at, court["at"], PICK_COLOUR)
			if _arrived(dt, at, kmh, court["at"], PICK_R):
				_board_bogdan()
		State.TO_LOUNGE:
			_status("SENATOREK · Emilii Plater 53", "Stań w kręgu: wejście pod złotym SENATOREK",
					"Stop in the ring: the way in is under the gold SENATOREK", at, door["at"], COLOUR)
			if at_entrance(at, kmh, dt):
				_go_inside()
		State.DROP_BOGDAN:
			_status("BOGDAN · do domu", "Podrzuć Bogdana pod korty", "Drop Bogdan at the courts", at, court["at"], PICK_COLOUR)
			if _arrived(dt, at, kmh, court["at"], PICK_R):
				_drop_bogdan()
		State.DROP_IVAN:
			_status("IVAN · do domu", "Podrzuć Ivana na 19. Dzielnicę", "Drop Ivan at 19. Dzielnica", at, home["at"], PICK_COLOUR)
			if _arrived(dt, at, kmh, home["at"], PICK_R):
				_drop_ivan()
		State.RESULT:
			_result_t += dt
			if _result_t > RESULT_LIFE:
				_close_card()
				_finish()


func _free() -> bool:
	return free_now.is_valid() and bool(free_now.call()) and not home.is_empty() and not court.is_empty() and not door.is_empty()


func _hour() -> float:
	var c: Dictionary = clock.call() if clock.is_valid() else {"hour": 20.0}
	return float(c["hour"])


func busy() -> bool:
	return state in [State.TO_IVAN, State.TO_BOGDAN, State.TO_LOUNGE, State.INSIDE, State.DROP_BOGDAN, State.DROP_IVAN]


func idle() -> bool:
	return state == State.IDLE


func has_target() -> bool:
	return state in [State.TO_IVAN, State.TO_BOGDAN, State.TO_LOUNGE, State.DROP_BOGDAN, State.DROP_IVAN]


func target_position() -> Vector3:
	match state:
		State.TO_IVAN, State.DROP_IVAN:
			return home["at"]
		State.TO_BOGDAN, State.DROP_BOGDAN:
			return court["at"]
		State.TO_LOUNGE:
			return door["at"]
	return Vector3.ZERO


func target_colour() -> Color:
	return COLOUR if state == State.TO_LOUNGE else PICK_COLOUR


func _status(title: String, hint: String, hint_en: String, at: Vector3, to: Vector3, colour: Color) -> void:
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)))
	hud.show_status(title, "", "%d m" % m, hint, _hold_t / HOLD, colour, "", {}, hint_en)


## Stopped in the kerb's ring or at the revolving door itself (a car driven up the forecourt).
func at_entrance(at: Vector3, kmh: float, dt: float) -> bool:
	if entry != Vector3.INF and Vector2(at.x, at.z).distance_to(Vector2(entry.x, entry.z)) <= ENTRY_R:
		return _arrived(dt, at, kmh, entry, ENTRY_R)
	return _arrived(dt, at, kmh, door["at"], DOOR_R)


func _arrived(dt: float, at: Vector3, kmh: float, to: Vector3, r: float) -> bool:
	if Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)) <= r and kmh < STOP_KMH:
		_hold_t += dt
	else:
		_hold_t = 0.0
	if _hold_t >= HOLD:
		_hold_t = 0.0
		return true
	return false


# --- the call ---------------------------------------------------------------------------------

## The phone rings (--shisha-call, the WĄTKI list). False without the places or while busy.
func ring() -> bool:
	if state != State.IDLE or home.is_empty() or court.is_empty() or door.is_empty():
		return false
	state = State.RING
	_ring_t = 0.0
	_card = true
	hud.show_call(FRIEND, "Kumpel. Zawsze coś kombinuje. Zwykle w garniturze.", COLOUR,
			"Your mate. Always up to something. Usually in a suit.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


## Met in person at his block (story_quests.gd: WCHODZĘ): he gets in, on to Bogdan.
func meet_in_person() -> bool:
	if state != State.IDLE or home.is_empty() or court.is_empty() or door.is_empty():
		return false
	_hold_calls()
	_log("met Ivan in person")
	_board_ivan()
	return true


func _offer() -> void:
	state = State.OFFER
	_ring_t = 0.0
	_show_side("📞 IVAN", "„Siema! Szisza dziś? Podjedź po mnie pod 19. Dzielnicę, weźmiemy jeszcze Bogdana z kortu. Ma być spokojnie.”",
			PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TONIGHT"]), FRIEND,
			"\"Hey! Shisha tonight? Pick me up at 19. Dzielnica, we'll grab Bogdan from the court too. Calm, this time.\"", false, FRIEND)


func _on_card(i: int) -> void:
	if not _card:
		return
	_card = false
	match state:
		State.RING:
			hud.hide_card()
			if i == 0:
				_offer()
			else:
				hud.toast("Odrzucono. Ivan pójdzie na szyszę sam.", "Declined. Ivan will go for a shisha alone.")
				_reset()
		State.OFFER:
			hud.hide_card()
			if i == 0:
				accept()
			else:
				hud.toast("Ivan: „Dobra, ale następnym razem ty stawiasz.”", "Ivan: \"Fine, but next time you're paying.\"")
				_reset()
		State.RESULT:
			hud.hide_card()
			_finish()


## JADĘ!: Ivan waiting at his block.
func accept() -> void:
	_hold_calls()
	state = State.TO_IVAN
	_hold_t = 0.0
	_place_pick(home)
	hud.toast("Jedź po Ivana na 19. Dzielnicę", "Go and pick up Ivan at 19. Dzielnica")
	_log("accepted: to Ivan")


func _board_ivan() -> void:
	state = State.TO_BOGDAN
	_hold_t = 0.0
	votes = {}
	_place_pick(court)
	_scene("board_ivan")
	_scene("leg1", 3)
	_log("Ivan in; to the courts at %s" % _where(court))


func _board_bogdan() -> void:
	state = State.TO_LOUNGE
	_hold_t = 0.0
	_queue.clear()
	_scene("court")
	_scene("board_bogdan")
	_scene("flavour")
	_scene("strength", 3)
	_show_entrance()
	_log("Bogdan in; to Emilii Plater 53 (kerb %s, door %s)" % [_where(door), "-" if entry == Vector3.INF else "%d,%d" % [roundi(entry.x), roundi(entry.z)]])


## The way in: the teal stop ring on the kerb (no waving person: nobody waits there) and the gold
## ring and column at the revolving door, so the canopy reads as the goal from down the street.
func _show_entrance() -> void:
	var side: Vector3 = door["side"]
	_pick.recolour(COLOUR)
	_pick.pattern = Beacon.Pattern.SOLID
	_pick.place(Vector3(side.x, door["at"].y, side.z), PICK_R, true, false)
	_pick.visible = true
	if entry != Vector3.INF:
		_door.place(entry, ENTRY_R * 0.5, true, false)
		_door.visible = true


func _hide_entrance() -> void:
	_door.visible = false
	_pick.visible = false
	_pick.recolour(PICK_COLOUR)
	_pick.pattern = Beacon.Pattern.DASHED


# --- the lounge -------------------------------------------------------------------------------

## Stopped at the entrance: the three walk in, straight into the lounge (the doorman, the lift and
## the choices play inside, lounge.gd), the car waiting at the kerb.
func _go_inside() -> void:
	state = State.INSIDE
	_close_card()
	_hide_entrance()
	hud.hide_status()
	_queue.clear()
	_log("into the lounge")
	if enter_lounge.is_valid():
		enter_lounge.call(votes)
	else:
		for k in 3:
			apply_vote(votes, k, default_vote(k))
		lounge_done("smoke", 5)


## From lounge.gd: how it ended ("smoke", "terrace", "leave") and the mix's score (0..9).
func lounge_done(how: String, mix_score: int) -> void:
	if state != State.INSIDE:
		return
	outcome = how
	score = mix_score
	state = State.DROP_BOGDAN
	_hold_t = 0.0
	_place_pick(court)
	_scene("leave" if how == "leave" else "after")
	_log("out of the lounge: %s, score %d" % [how, mix_score])


func _drop_bogdan() -> void:
	_scene("drop_bogdan")
	state = State.DROP_IVAN
	_hold_t = 0.0
	_place_pick(home)
	_log("Bogdan dropped")


func _drop_ivan() -> void:
	_pick.visible = false
	hud.hide_status()
	_scene("drop_ivan")
	var p := pay_for(outcome, score)
	last_pay = {"zl": p[0], "respect": p[1], "outcome": outcome, "score": score}
	if wallet != null:
		wallet.pay(p[0], p[1], "shisha")
	nights += 1
	state = State.RESULT
	_result_t = 0.0
	var pipe: Array = votes.get("name", ["Forhend", "Forehand"])
	var pl := "Ivan i Bogdan dziękują. Za kurs: %d zł. +%d szacunku. Fajka „%s” zapisana w zeszycie." % [p[0], p[1], pipe[0]]
	var en := "Ivan and Bogdan say thanks. For the ride: %d zł. +%d respect. The pipe \"%s\" goes in the notebook." % [p[0], p[1], pipe[1]]
	if outcome == "leave":
		pl = "Ivan wzdycha: „Ogórek został w słoiku.” Za kurs: %d zł." % p[0]
		en = "Ivan sighs: \"The cucumber stayed in the jar.\" For the ride: %d zł." % p[0]
	_show_card("DYM U SENATORKA", pl, PackedStringArray(["OK"]), "SMOKE AT SENATOREK", en)
	_log("done: %s, score %d, +%d zł +%d respect" % [outcome, score, p[0], p[1]])


func _give_up() -> void:
	hud.hide_status()
	_close_card()
	_queue.clear()
	_scene("abort")
	hud.toast("Ivan łapie nocny autobus", "Ivan catches the night bus")
	_log("gave up")
	_finish()


func _finish() -> void:
	_hide_entrance()
	hud.hide_status()
	if missions != null:
		missions.paused = _calls_were
	_reset()


func _reset() -> void:
	state = State.IDLE
	_card = false
	_hold_t = 0.0
	call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)


func _hold_calls() -> void:
	_calls_were = missions.paused if missions != null else false
	if missions != null:
		missions.paused = true


func _place_pick(k: Dictionary) -> void:
	_hide_entrance()
	var side: Vector3 = k["side"]
	_pick.place(Vector3(side.x, k["at"].y, side.z), PICK_R, true, true)
	_pick.visible = true


# --- cards and bubbles ------------------------------------------------------------------------

func _show_side(title: String, body: String, buttons: PackedStringArray, title_en: String, body_en: String, stacked := false,
		face := "") -> void:
	_card = true
	hud.show_side_card(title, body, buttons, COLOUR, title_en, body_en, stacked, face)


func _show_card(title: String, body: String, buttons: PackedStringArray, title_en: String, body_en: String) -> void:
	_card = true
	hud.show_card(title, body, buttons, COLOUR, false, title_en, body_en, true)


func _close_card() -> void:
	if _card:
		hud.hide_card()
	_card = false


## Queues a scene's lines (data/shisha.json), `take` of them picked at random in order (0: all).
func _scene(id: String, take := 0) -> void:
	var rows: Array = scenes.get(id, [])
	if take > 0 and rows.size() > take:
		var pick: Array = []
		var idx := range(rows.size())
		idx.shuffle()
		idx = idx.slice(0, take)
		idx.sort()
		for i: int in idx:
			pick.append(rows[i])
		rows = pick
	_queue.append_array(rows)


func _play(dt: float) -> void:
	_scene_t -= dt
	if _scene_t > 0.0 or _queue.is_empty():
		return
	_scene_t = SCENE_GAP
	var row: Array = _queue.pop_front()
	if dialogue == null or dialogue.bubbles == null:
		return
	var anchor := func() -> Vector3:
		var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
		return v[0]
	dialogue.bubbles.say(anchor, String(row[0]), String(row[1]), String(row[2]), BUBBLE_S,
			BUBBLE if String(row[0]) != "Bramkarz" else GOLD, 2.2)


func _where(k: Dictionary) -> String:
	return "-" if k.is_empty() else "%d,%d (%s)" % [roundi(k["at"].x), roundi(k["at"].z), k["street"]]


func _log(text: String) -> void:
	if log_on:
		print("shisha: " + text)
