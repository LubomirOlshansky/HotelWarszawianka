extends Node
## Loop 3h slice 4 (docs/DEMO.md 6.2 "The first 10 minutes", 6.3 "The end of the demo"): the guide
## for a fresh save, and the end card.
##
## **The guide is a director, not rails.** On a fresh save (`guide_due`: no jobs done, no złoty,
## no ladder rung, the guide not finished before) it ticks five times a second (TICK; no per-frame
## work, no scans) on the seconds of play since the title, and makes each beat of 6.2 happen if it
## hasn't by itself (`decide`, a pure function of the facts so check_first10.gd tests it without
## the map). A beat the player reaches alone is "met"; one the director pushes is "fired". Every
## beat waits while a job, a race, a rescue, a police stop or a card is on (`free`). While a beat
## is due and waits for that free moment (`due`), the guide holds what would come by itself (a
## Podwózka request, a "Na czasie" offer: `offers_held`), so a player who takes every ride still
## meets Halina and the first call in their windows (run 12: the call 83 s late behind a ride).
##
## | beat | the 6.2 time | what the director does (and its fallback) |
## | --- | --- | --- |
## | finger | 0:05 | the ghost finger (hud.gd) after FINGER_IDLE s with no touch or key; it goes at the first one |
## | stand | 0:15 | the edge arrow to the kebab stand by Świętokrzyska (jobs.gd FIRST_STAND), straight ahead of the start (START), until an order starts |
## | order | 0:30 | that stand's next order is the guided one (~250 m straight on up Marszałkowska, jobs.gd `pin_first`) |
## | race | 1:30 | RACE_AFTER s after the first delivery's card, not before RACE_EARLIEST (or at RACE_LATEST without one) Pani Halina rolls up behind and flashes (rivals.gd `call_first`): the ladder's first rung, a race to the Palm she loses narrowly; declined, she tries twice more, RACE_RETRY s apart |
## | trap | 3:00 | the police's scripted first contact (police.gd), armed by the race; without a race the director arms it at TRAP_LATEST |
## | rescue | 4:00 | the first call is held (missions.gd `held`) until RESCUE_AT and the race (or RESCUE_LATEST), then rings RESCUE_RING s later |
## | heli | ~5:00 | a hint toast for the helicopter (open from the first second since 2026-11-01; HELI and H are never locked) |
## | tape | 6:00 | the arrow to the mixtape on the University Library's roof (cassettes.gd, CASSETTE_ID), picked up from the helicopter: it opens the next PÓŁNOC FM track ("a new song"); without it, KASETA on the boulevards (TAPE_ID) as before |
## | powisle | 8:00 | "Powiśle discovered" comes from districts.gd; not by POWISLE_AT, the arrow to Powiśle |
## | garage | 10:00 | Mirek's garage (garage.gd `held`) waits for GARAGE_AT and the first earnings, then its toast and an arrow |
##
## The guide ends at the garage (or GUIDE_END s): every hold is let go and `done` is saved. Its
## progress is the save's [intro] section (wallet.gd `intro`: beat id -> the day); an old save
## with progress never sees it, so it never locks anything for a returning player.
##
## **The end card** (any save): once `Ladder.final_won()` (the "Trzy mosty" win, `trzy_mosty` in
## [ladder]) and END_JOBS jobs done (wallet.gd `jobs_done`), shown once when nothing else is on:
## "Dzięki za grę! / Thanks for playing!", the demo's end, the credits line, the repo's name and
## "Jedź dalej · Free roam" (everything stays unlocked); `end_seen` saved in [intro].
##
## --first10 scripts the beats' triggers for a headless replay with --autopilot (the car taken to
## the stand, the flash back, the call answered, the tape played, the cards closed), prints a
## `first10:` line per beat and `first10: OK` when each fired within its window (WINDOWS), and
## quits. --end-card shows the end card at once, --first-race has Halina roll up a second in
## (screenshots).

const Ladder := preload("res://scripts/ladder.gd")
const Missions := preload("res://scripts/missions.gd")

## Five looks a second.
const TICK := 0.2
## The beats in order, and the window (seconds of play) each one's trigger must fall in for the
## --first10 replay and check_first10.gd: a beat met by the player before its window is fine (an
## early order is good); a beat the director fires is fired inside it.
const BEATS := ["finger", "stand", "order", "race", "trap", "rescue", "heli", "tape", "powisle", "garage"]
const WINDOWS := {
	"finger": Vector2(4.0, 8.0), "stand": Vector2(10.0, 25.0), "order": Vector2(15.0, 60.0),
	"race": Vector2(60.0, 200.0), "trap": Vector2(120.0, 330.0), "rescue": Vector2(220.0, 330.0),
	"heli": Vector2(240.0, 450.0), "tape": Vector2(330.0, 450.0), "powisle": Vector2(300.0, 540.0),
	"garage": Vector2(570.0, 660.0),
}
## Where a guided run starts (main.gd `_guide_start`): the northbound carriageway of Marszałkowska
## level with the Museum of Modern Art, the Palace on the left, facing north up the street to the
## Świętokrzyska stand ~350 m ahead (jobs.gd FIRST_STAND). The map's spawn (centrum.json) faces
## south with the stand behind it; the bench and the other test runs keep that one.
const START := Vector2(-961.6, 95.0)
## Compass degrees (main.gd `start_heading`): along the carriageway, north-north-west.
const START_HEADING := 339.8
const FINGER_IDLE := 4.0
const STAND_AT := 10.0
## --first10: the car is taken to the stand at ORDER_AT s.
const ORDER_AT := 15.0
const RACE_AFTER := 6.0
## The first-10 polish: the short first order is done by ~0:45, so Halina waits for this second
## (6.2's 1:30 beat; a minute of free driving after the first delivery's card).
const RACE_EARLIEST := 75.0
const RACE_LATEST := 180.0
const RACE_RETRY := 60.0
const RACE_TRIES := 3
const TRAP_LATEST := 270.0
const RESCUE_AT := 225.0
const RESCUE_LATEST := 300.0
const RESCUE_RING := 12.0
const HELI_LATEST := 420.0
const TAPE_AT := 330.0
const TAPE_ID := "t_bulwary_2018"
## The guide's cassette (cassettes.json): on the BUW roof by the boulevards.
const CASSETTE_ID := "c01_buw"
const POWISLE_AT := 450.0
const GARAGE_AT := 570.0
## The garage beat stops waiting for a free moment here (its window ends at 660 s).
const GARAGE_LATEST := 640.0
const GUIDE_END := 900.0
## The beats that wait for a free moment; while one of them is due the guide holds new offers.
const HOLD_BEATS := ["race", "trap", "rescue", "tape", "powisle", "garage"]
## A beat this close (s) holds new offers too.
const HOLD_AHEAD := 45.0
## The replay judges by here at the latest (after the last window, before verify.sh's 48000 frames).
const REPLAY_DEADLINE := 700.0
## An arrow stays at most this long (s), unless its beat is met first.
const HINT_S := 150.0
const GARAGE_HINT_S := 90.0
const HINT_COLOUR := Color("#ffd23f")
## The end card: the jobs it needs, its words ([Polish, English]), its button ("POLISH|ENGLISH",
## hud.gd) and the repo's name (README's; as text, no link).
const END_JOBS := 10
const REPO := "aroundwarsaw.app"
const END_TITLE := ["DZIĘKI ZA GRĘ!", "Thanks for playing!"]
const END_BODY := [
	"To już koniec dema. Trzy mosty twoje, kebaby dowiezione, a Palma… dalej sztuczna.",
	"That's the end of the demo. Three bridges won, kebabs delivered, and the Palm… still fake.",
]
const END_FREE := ["Miasto zostaje otwarte: jedź, dokąd chcesz. Syrenki i kasety czekają.",
	"The city stays open: drive wherever you like. Syrenki and tapes still wait."]
## One line for both languages (the card has room for one): the data, the licence, the code.
const END_CREDITS := "© OpenStreetMap (ODbL), GUGiK"
const END_BUTTON := "JEDŹ DALEJ|FREE ROAM"
const END_COLOUR := Color("#ffd23f")
## The director's words, [Polish, English] (each at most 70 characters).
const LINES := {
	"stand": ["Kebab przy Świętokrzyskiej czeka z twoim pierwszym zamówieniem.", "The kebab stand by Świętokrzyska has your first order."],
	"heli": ["Pogotowie lotnicze pożycza ci stary śmigłowiec: HELI", "The air ambulance lends you its old helicopter: HELI"],
	"heli_locked": ["Helikopter? Najpierw jedno wezwanie ratunkowe.", "The helicopter comes after your first rescue call."],
	"tape": ["Na dachu BUW leży kaseta z muzyką. Leć po nią helikopterem.", "A mixtape lies on the BUW roof: fly the helicopter to it."],
	"tape_ground": ["Na bulwarach czeka KASETA. Zwolnij przy niej.", "A KASETA waits on the boulevards: slow down by it."],
	"powisle": ["Pod skarpą jest Powiśle. Zjedź w dół, do Wisły.", "Powiśle is below the escarpment: head down to the river."],
}

signal beat(id: String, how: String, at: float)

## Set by main.gd.
var wallet: Node
var hud: CanvasLayer
var map: Node3D
var car: CharacterBody3D
var jobs: Node
var rivals: Node
var missions: Node
var police: Node
var tape: Node
var radio: Node
var districts: Node
var garage: Node
## cassettes.gd: the guide's 6:00 cassette (null or not placed: KASETA's then card instead).
var cassettes: Node
## main.gd: the vehicle is the helicopter now.
var flying: Callable
## --first10: the replay's scripted triggers (with --autopilot), its lines, the check and the quit.
var scripted := false
## The guide runs on this save (`guide_due` at `begin`).
var guide := false
## --first-race: Halina rolls up this many seconds into the run, whatever the guide (screenshots,
## the race's feel); -1: off.
var race_at := -1.0
## --end-card: the second the end card shows (the start's own cards and toasts are done by then).
var end_at := -1.0
## Seconds of play since `begin` (the title dismissed).
var t := 0.0
## Beat id -> the second it triggered, and how ("fired": the director; "met": the player).
var fired := {}
var how := {}
## The arrow: the point (INF: none), its word and when it goes.
var hint_at := Vector3.INF
var hint_word := ""
var hint_until := 0.0
## The bench's "first10" line.
var spent_usec := 0
var _running := false
var _tick_t := 0.0
var _delivered_t := -1.0
var _race_tries := 0
var _race_next := 0.0
var _retry_at := -1.0
var _stand := -1
var _end_up := false
var _song := false
var _card_t := 0.0
var _call_t := 0.0
## The replay: the car's last finite position (for the NaN report).
var _last_pos := Vector3.ZERO
var _done_t := -1.0
var _input_base := 0
## A beat is due and waits for a free moment: new offers are held (`due`).
var offers_held := false


# --- the rules (static: check_first10.gd tests them without the map) ---------------------------

## The guide runs on a fresh save: no jobs done, no złoty, no rung beaten, and not finished before.
static func guide_due(w: Node) -> bool:
	if w == null:
		return false
	return w.jobs_done() == 0 and int(w.zl) == 0 and w.ladder.is_empty() and not w.intro.has("done")


## The end card is due: the final won, END_JOBS jobs done, not seen yet.
static func end_due(w: Node) -> bool:
	if w == null:
		return false
	return w.ladder.has(Ladder.FINAL_ID) and w.jobs_done() >= END_JOBS and not w.intro.has("end_seen")


## The beats the facts say happened by themselves (the player's doing).
## Facts: input, ordered, raced, trap, rang, tape, powisle, garage (bools).
static func met(f: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if f.get("input", false):
		out.append("finger")
	if f.get("ordered", false):
		out.append_array(["stand", "order"])
	if f.get("raced", false):
		out.append("race")
	if f.get("trap", false):
		out.append("trap")
	if f.get("rang", false):
		out.append("rescue")
	if f.get("tape", false):
		out.append("tape")
	if f.get("powisle", false):
		out.append("powisle")
	if f.get("garage", false):
		out.append("garage")
	return out


## The beats the director fires now, at second `now`, from the facts `f` (met's, plus: free,
## delivered_t (-1: no delivery yet), calling (a rival is rolling up), race_next, rescued, earned,
## heli_call (a helicopter-only call is up), scripted) and the beats already triggered
## (`done`: beat -> second). "done" too, when the guide is over.
static func decide(now: float, f: Dictionary, done: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var free: bool = f.get("free", false)
	var is_done := func(id: String) -> bool: return done.has(id)
	if not is_done.call("finger") and not f.get("input", false) and now >= FINGER_IDLE:
		out.append("finger")
	if not is_done.call("stand") and not f.get("ordered", false) and now >= STAND_AT and free:
		out.append("stand")
	if not is_done.call("order") and f.get("scripted", false) and not f.get("ordered", false) and now >= ORDER_AT and free:
		out.append("order")
	var delivered: float = f.get("delivered_t", -1.0)
	if not is_done.call("race") and not f.get("raced", false) and not f.get("calling", false) and free \
			and now >= float(f.get("race_next", 0.0)) and ((delivered >= 0.0 and now >= maxf(delivered + RACE_AFTER, RACE_EARLIEST)) or now >= RACE_LATEST):
		out.append("race")
	if not is_done.call("trap") and not f.get("trap", false) and now >= TRAP_LATEST and free:
		out.append("trap")
	if not is_done.call("rescue") and not f.get("rang", false) and now >= RESCUE_AT and free \
			and (f.get("raced", false) or now >= RESCUE_LATEST):
		out.append("rescue")
	if not is_done.call("heli") and (f.get("rescued", false) or f.get("heli_call", false) or now >= HELI_LATEST):
		out.append("heli")
	if not is_done.call("tape") and not f.get("tape", false) and is_done.call("heli") and now >= TAPE_AT and free:
		out.append("tape")
	if not is_done.call("powisle") and not f.get("powisle", false) and now >= POWISLE_AT and free:
		out.append("powisle")
	# The garage's toast waits for a free moment, but not past its window: a long ride (Podwózka)
	# would hold it for minutes, so near the window's end it shows over whatever is running.
	if not is_done.call("garage") and not f.get("garage", false) and now >= GARAGE_AT and f.get("earned", false) \
			and (free or now >= GARAGE_LATEST):
		out.append("garage")
	if not is_done.call("done") and (now >= GUIDE_END or (is_done.call("garage") and f.get("garage", false))):
		out.append("done")
	return out


## The beats due now (or within HOLD_AHEAD s) that only wait for a free moment: the ones `decide`
## would fire then if nothing were on. While this is not empty the guide holds new offers
## (`offers_held`): a 2-minute ride taken 5 s before a beat would push it past its window.
static func due(now: float, f: Dictionary, done: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if done.has("done"):
		return out
	var g := f.duplicate()
	g["free"] = true
	# A call under way ends in a rescue, and the helicopter's hint (which never waits) follows it,
	# so the tape's beat behind them counts as near too.
	g["rescued"] = bool(f.get("rescued", false)) or bool(f.get("rang", false))
	var seen := done.duplicate()
	for pass_i in 2:  # twice: a beat that fires at once (the heli hint) opens the next (the tape)
		for id in decide(now + HOLD_AHEAD, g, seen):
			if not seen.has(id):
				seen[id] = now
			if id in HOLD_BEATS and not id in out:
				out.append(id)
	return out


## [problems] for a run's triggers against WINDOWS: a beat missing, late, or fired before its window.
static func judge(done: Dictionary, ways: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in BEATS:
		var w: Vector2 = WINDOWS[id]
		if not done.has(id):
			out.append("%s never triggered (window %.0f-%.0f s)" % [id, w.x, w.y])
			continue
		var at := float(done[id])
		if at > w.y + 0.5:
			out.append("%s late: %.1f s (window %.0f-%.0f s)" % [id, at, w.x, w.y])
		elif str(ways.get(id, "")) == "fired" and at < w.x - 0.5:
			out.append("%s fired early: %.1f s (window %.0f-%.0f s)" % [id, at, w.x, w.y])
	return out


## The end card's words: [title, body, title_en, body_en].
static func end_words() -> PackedStringArray:
	return PackedStringArray([END_TITLE[0],
			"%s %s\n%s · %s" % [END_BODY[0], END_FREE[0], END_CREDITS, REPO],
			END_TITLE[1],
			"%s %s" % [END_BODY[1], END_FREE[1]]])


static func _today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


# --- the node ----------------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Hooks up the cards and the tape, and holds what the guide holds (on a fresh save). Called once
## the city is built (before the title is dismissed).
func setup(want_guide: bool) -> void:
	guide = want_guide and guide_due(wallet)
	if hud != null:
		hud.card_pressed.connect(_on_card)
	if tape != null and tape.has_signal("played"):
		tape.played.connect(_on_tape)
	if guide:
		if missions != null:
			missions.held = true
		if garage != null:
			garage.held = true
		# 2026-11-01 (F, beta): the helicopter and the map teleport are open from the first second;
		# the "heli" beat below stays as a hint.
		if jobs != null:
			_stand = jobs.first_stand()
			if _stand >= 0:
				jobs.pin_first(_stand)
	print("first10: guide %s%s%s" % ["on" if guide else "off", " (scripted)" if scripted else "",
			", first stand %d" % _stand if guide else ""])


## The clock starts (the title is gone, or there was none).
func begin() -> void:
	_running = true
	# The tap that closed the title is not "the first touch" of the drive.
	_input_base = int(hud.input_ms) if hud != null else 0


func _process(dt: float) -> void:
	if not _running:
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	_tick_t += dt
	if _tick_t >= TICK:
		_tick_t = 0.0
		tick()
	spent_usec += Time.get_ticks_usec() - t0


## The helicopter is still locked (the guide's heli beat hasn't come).
func heli_locked() -> bool:
	return false  # 2026-11-01 (F, beta): open from the start; the beat only toasts


## The H key or HELI while locked: the toast that says why.
func heli_refused() -> void:
	if hud != null:
		hud.toast(LINES["heli_locked"][0], LINES["heli_locked"][1])


## The guide is running now (a fresh save, not finished yet): everything it points at is the main
## line's first chapter (main_line.gd).
func guide_on() -> bool:
	return guide and _running and not fired.has("done")


## An arrow is up.
func hint_shown() -> bool:
	return hint_at != Vector3.INF


## One look: the facts, the beats met and fired, the arrow, the end card.
func tick() -> void:
	var f := facts()
	if guide and not fired.has("done"):
		for id in met(f):
			if not fired.has(id):
				_trigger(id, "met")
		for id in decide(t, f, fired):
			_fire(id)
		_follow_up(f)
	_hold_offers(guide and not due(t, f, fired).is_empty())
	if hint_shown() and (t > hint_until or _hint_met(f)):
		hint_at = Vector3.INF
	if not _end_up and f["free"] and not f["rang"] and end_due(wallet):
		show_end_card()
	if end_at >= 0.0 and t >= end_at:
		end_at = -1.0
		show_end_card()
	if race_at >= 0.0 and t >= race_at and rivals != null:
		if rivals.call_first():
			race_at = -1.0
	if scripted:
		_script(f)


## Holds (or lets go of) what comes by itself: Podwózka's requests and the "Na czasie" offers.
## A ride already under way runs on; only new ones wait (the PODWÓZKA button still asks for one).
func _hold_offers(on: bool) -> void:
	if on == offers_held:
		return
	offers_held = on
	if jobs == null:
		return
	for n: Variant in [jobs.get("rides"), jobs.get("trend")]:
		if n is Node and "guide_hold" in n:
			n.guide_hold = on
	if scripted:
		print("first10: offers %s at %.1f s" % ["held" if on else "free", t])


## What the director knows now (see `decide`).
func facts() -> Dictionary:
	var air: bool = flying.is_valid() and bool(flying.call())
	# PT-15: a ride request's card up counts (Halina won't roll up over it).
	var busy: bool = (jobs != null and (jobs.busy() or jobs.ride_offered())) or (rivals != null and (rivals.busy() or rivals.first_waiting())) \
			or (missions != null and (missions.has_target() or int(missions.state) in [Missions.State.OFFER, Missions.State.RESULT])) \
			or (police != null and int(police.phase) != 0) or (garage != null and garage.is_open()) or _end_up
	var orders: int = jobs.orders_started() if jobs != null else 0
	if _delivered_t < 0.0 and wallet != null and wallet.jobs_done() > 0 and not busy:
		_delivered_t = t
	return {
		"input": hud != null and int(hud.input_ms) > _input_base,
		"free": not busy,
		"ordered": orders > 0,
		"delivered_t": _delivered_t,
		"raced": rivals != null and (str(rivals.first_result) in ["won", "lost"] or rivals.raced()),
		"calling": rivals != null and rivals.first_waiting(),
		"race_next": _race_next,
		"trap": police != null and police.first_armed(),
		"rang": missions != null and int(missions.state) in [Missions.State.RINGING, Missions.State.OFFER, Missions.State.PICKUP, Missions.State.DROPOFF, Missions.State.RESULT],
		"rescued": wallet != null and int(wallet.jobs.get("rescue", 0)) > 0,
		"heli_call": missions != null and missions.has_method("call_needs_heli") and missions.call_needs_heli(),
		"tape": _tape_done(),
		"powisle": districts != null and districts.is_discovered("powisle"),
		"garage": garage != null and garage.is_shown(),
		"earned": wallet != null and (wallet.jobs_done() > 0 or int(wallet.zl) > 0),
		"scripted": scripted,
		"flying": air,
	}


func _trigger(id: String, way: String) -> void:
	if fired.has(id):
		return
	fired[id] = snappedf(t, 0.1)
	how[id] = way
	if wallet != null and id in BEATS + ["done"]:
		wallet.intro[id] = _today()
		wallet.save()
	var w: Vector2 = WINDOWS.get(id, Vector2(-1, -1))
	print("first10: %s %s at %.1f s%s" % [id, way, t, " (window %.0f-%.0f s)" % [w.x, w.y] if w.x >= 0.0 else ""])
	beat.emit(id, way, t)


## The director pushes beat `id`.
func _fire(id: String) -> void:
	match id:
		"finger":
			if hud != null:
				hud.ghost_finger(true)
		"stand":
			if jobs != null and _stand >= 0:
				_hint(jobs.stand_ring(_stand), "KEBAB", HINT_S)
				hud.toast(LINES["stand"][0], LINES["stand"][1])
		"order":
			# --first10 only: the car at the stand, the guided order.
			if jobs == null or _stand < 0 or not jobs.start_first(_stand):
				return
		"race":
			_race_tries += 1
			if rivals == null or not rivals.call_first():
				_race_next = t + 2.0
				_race_tries -= 1
				return
		"trap":
			if police == null:
				return
			police.arm_first_contact()
		"rescue":
			if missions == null:
				return
			missions.held = false
			missions.ring_in(RESCUE_RING)
		"heli":
			if hud != null:
				hud.set_vehicle_shown(true)
				hud.toast(LINES["heli"][0], LINES["heli"][1])
		"tape":
			var at := _tape_at()
			if at != Vector3.INF:
				_hint(at, "KASETA", HINT_S)
				var words: Array = LINES["tape"] if _cassette() >= 0 else LINES["tape_ground"]
				hud.toast(words[0], words[1])
		"powisle":
			var at := powisle_at()
			if at != Vector3.INF:
				_hint(at, "POWIŚLE", HINT_S)
				hud.toast(LINES["powisle"][0], LINES["powisle"][1])
		"garage":
			if garage == null:
				return
			garage.held = false
			_hint(garage.at, "MIREK", GARAGE_HINT_S)
		"done":
			_end_guide()
	_trigger(id, "fired")


## What runs between the beats: the call kept coming once let through, Halina's retries.
func _follow_up(f: Dictionary) -> void:
	if fired.has("rescue") and not f["rang"] and f["free"] and missions != null and int(missions.state) == Missions.State.CLOSED \
			and missions.call_in() > RESCUE_RING + 1.0:
		missions.ring_in(RESCUE_RING)
	if fired.has("race") and rivals != null and str(rivals.first_result) == "declined" and _race_tries < RACE_TRIES:
		if _retry_at < 0.0:
			_retry_at = t + RACE_RETRY
		elif t >= _retry_at and f["free"] and not f["raced"]:
			rivals.first_result = ""
			if rivals.call_first():
				_race_tries += 1
				_retry_at = -1.0
				print("first10: Halina tries again (%d of %d)" % [_race_tries, RACE_TRIES])
			else:
				rivals.first_result = "declined"
				_retry_at = t + 2.0


## The guide is over: every hold let go.
func _end_guide() -> void:
	if missions != null:
		missions.held = false
	if garage != null:
		garage.held = false
	if hud != null:
		hud.set_vehicle_shown(true)
		hud.ghost_finger(false)
	if not fired.has("heli"):
		fired["heli"] = snappedf(t, 0.1)
		how["heli"] = "fired"
	_done_t = t


func _hint(at: Vector3, word: String, seconds: float) -> void:
	if at == Vector3.INF:
		return
	hint_at = at
	hint_word = word
	hint_until = t + seconds


## Where the Powiśle arrow points: the district's label (districts.gd), or INF with no districts.
## PT-30: `by_id` holds the district's index, not the district; reading "at" off it failed every
## frame from the beat's time, so the beat never fired and the guide stalled there.
func powisle_at() -> Vector3:
	if districts == null or not districts.by_id.has("powisle"):
		return Vector3.INF
	var p: Vector2 = districts.districts[int(districts.by_id["powisle"])]["at"]
	return Vector3(p.x, map.ground_height(p.x, p.y) if map != null else 0.0, p.y)


## The beat the arrow is for has been met.
func _hint_met(f: Dictionary) -> bool:
	match hint_word:
		"KEBAB":
			return f["ordered"]
		"KASETA":
			return f["tape"]
		"POWIŚLE":
			return f["powisle"]
		"MIREK":
			return garage != null and car != null and Vector2(car.global_position.x - garage.at.x, car.global_position.z - garage.at.z).length() < 30.0
	return false


## The guide's cassette's index in cassettes.gd, -1 if it isn't placed (then KASETA stands in).
func _cassette() -> int:
	if cassettes == null:
		return -1
	var i: int = cassettes.index_of(CASSETTE_ID)
	return i if i >= 0 and cassettes.at(i) != Vector3.INF else -1


## The tape beat is met: the cassette picked up (or, without one, KASETA played).
func _tape_done() -> bool:
	if _cassette() >= 0:
		return cassettes.is_taken(CASSETTE_ID)
	return wallet != null and wallet.tapes.has(TAPE_ID)


## The 6:00 beat's spot: the cassette on its roof, else the boulevard tape's (Vector3.INF if none).
func _tape_at() -> Vector3:
	var c := _cassette()
	if c >= 0:
		return cassettes.at(c)
	return _ground_tape_at()


## KASETA's boulevard spot (Vector3.INF if the notebook has no place for it).
func _ground_tape_at() -> Vector3:
	if tape == null:
		return Vector3.INF
	var i: int = tape.index_of(TAPE_ID)
	if i < 0:
		return Vector3.INF
	var p: Vector2 = tape.spots[i]["at"]
	if p == Vector2.INF:
		return Vector3.INF
	return Vector3(p.x, map.ground_height(p.x, p.y) if map != null else 0.0, p.y)


## KASETA played: the boulevard's, during the guide and only with no cassette to find (the cassette
## brings its own song), opens the next PÓŁNOC FM track once.
func _on_tape(card_id: String) -> void:
	if not guide or _song or card_id != TAPE_ID or radio == null or _cassette() >= 0:
		return
	_song = true
	var n: int = radio.next_locked()
	if n > 0:
		radio.unlock_track(n, "tape")
	print("first10: the boulevard tape opened PÓŁNOC FM track %d" % n)


# --- the end card ----------------------------------------------------------------------------

func show_end_card() -> void:
	if hud == null:
		return
	_end_up = true
	var w := end_words()
	hud.show_card(w[0], w[1], PackedStringArray([END_BUTTON]), END_COLOUR, false, w[2], w[3])
	if wallet != null and not wallet.intro.has("end_seen"):
		wallet.intro["end_seen"] = _today()
		wallet.save()
	print("first10: the end card (final won %s, %d jobs)" % [wallet != null and wallet.ladder.has(Ladder.FINAL_ID),
			wallet.jobs_done() if wallet != null else 0])


func end_card_shown() -> bool:
	return _end_up


func _on_card(_index: int) -> void:
	if not _end_up:
		return
	_end_up = false
	hud.hide_card()
	print("first10: the end card closed: free roam")


# --- the --first10 replay ----------------------------------------------------------------------

## The replay's player: closes each result card after a moment, flashes back at Halina, answers
## the first call (later ones ring on), plays the boulevard tape, then judges the run and quits.
func _script(f: Dictionary) -> void:
	# A car that left the numbers (NaN) fails the replay at once with what was going on, not
	# a hang till the time limit.
	if car != null and not car.global_position.is_finite():
		push_error("first10: the car's position is not a number at %.1f s (last seen at %s; missions %d, police chasing %s, rivals %d, jobs %d, beats %s)"
				% [t, _last_pos, int(missions.state) if missions != null else -1,
				police.chasing() if police != null else false, int(rivals.state) if rivals != null else -1,
				int(jobs.state) if jobs != null else -1, fired.keys()])
		get_tree().quit(1)
		return
	if car != null:
		_last_pos = car.global_position
	if hud != null and hud.finger_shown() and t > FINGER_IDLE + 3.0 \
			and not (rivals != null and rivals.has_method("first_nudging") and rivals.first_nudging()):
		hud.ghost_finger(false)
	var card := (jobs != null and int(jobs.state) == 3) or (rivals != null and int(rivals.state) == 5) \
			or (missions != null and int(missions.state) == Missions.State.RESULT)
	_card_t = _card_t + TICK if card else 0.0
	if _card_t > 3.0:
		_card_t = 0.0
		hud.card_pressed.emit(1)  # OK / FREE ROAM (a rescue's index 1 is FREE ROAM)
	if rivals != null and rivals.first_waiting() and int(rivals.state) == 1:
		rivals.flash()
	if missions != null and int(missions.state) == Missions.State.RINGING and not f["rescued"]:
		_call_t += TICK
		if _call_t > 2.0:
			_call_t = 0.0
			missions.offer(missions.number + 1)
			missions.accept()
	if fired.has("tape") and not f["tape"] and f["free"] and _cassette() >= 0 and missions != null \
			and int(missions.state) in [Missions.State.CLOSED, Missions.State.IDLE]:
		# The player would fly there over Powiśle: the car is put on the boulevard below (KASETA's
		# spot there, a street; districts.gd discovers Powiśle from it, as the flight would), then
		# the cassette is taken (the pickup rule itself: check_cassettes.gd).
		var below := _ground_tape_at()
		if car != null and below != Vector3.INF:
			car.global_position = below + Vector3(0, 0.5, 0)
			car.vel = Vector3.ZERO
			car.reset_physics_interpolation()
		cassettes.take(CASSETTE_ID)
	elif fired.has("tape") and not f["tape"] and f["free"] and tape != null and missions != null \
			and int(missions.state) in [Missions.State.CLOSED, Missions.State.IDLE]:
		var at := _tape_at()
		if at != Vector3.INF and car != null:
			car.global_position = at + Vector3(0, 0.5, 0)
			car.vel = Vector3.ZERO
			car.reset_physics_interpolation()
			tape.play(tape.index_of(TAPE_ID))
	# The replay's own deadline: past every window with no verdict yet, judge now (missing beats
	# fail) rather than run into --quit-after with no line and exit 0.
	if not fired.has("done") and t > REPLAY_DEADLINE:
		fired["done"] = t
		_done_t = t - 2.0
	if fired.has("done") and _done_t >= 0.0 and t > _done_t + 1.0:
		_done_t = -1.0
		var bad := judge(fired, how)
		for b in bad:
			push_error("first10: %s" % b)
		var parts := PackedStringArray()
		for id: String in BEATS:
			parts.append("%s %s %.0f" % [id, how.get(id, "-"), float(fired.get(id, -1.0))])
		if bad.is_empty():
			print("first10: OK (%s)" % ", ".join(parts))
		else:
			print("first10: %d problem(s) (%s)" % [bad.size(), ", ".join(parts)])
		get_tree().quit(0 if bad.is_empty() else 1)
