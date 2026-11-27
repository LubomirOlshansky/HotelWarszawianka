extends Node
## Loop 3h slice 4 (docs/DEMO.md 6.2 "The first 10 minutes", 6.3 "The end of the demo"): the guide
## for a fresh save, the First steps list, and the end card.
##
## **The guide is a director, not rails.** On a fresh save (`guide_due`: no jobs done, no złoty,
## no ladder rung, the guide not finished before) it ticks five times a second (TICK; no per-frame
## work, no scans) on the seconds of play since the title, and makes each beat happen if it hasn't
## by itself (`decide`, a pure function of the facts so check_first10.gd tests it without the map).
## A beat the player reaches alone is "met"; one the director pushes is "fired". Every beat waits
## while a job, a race, a rescue, a police stop or a card is on (`free`).
##
## **First hour, step 3** (the spec "First hour for the beta", F 2026-11-15): after the first
## minute the guide no longer fires beats by the clock. It shows ONE choice card (RACE, RIDES, FLY,
## or JUST DRIVE, the card's ✕; the guide's neutral voice, no call), then, whenever the player has been free
## NEXT_GAP s (and NEXT_GAP s after the last intro), it introduces the next thing on the First
## steps list (first_steps.gd) the player has not done yet, once each, in the order of INTROS. A
## player who skipped the kebab still gets the race and the rescue; one who already flew is not
## told about the helicopter (the intro is "met" by the step's tick).
##
## | beat | when | what the director does |
## | --- | --- | --- |
## | finger | 0:05 | the ghost finger (hud.gd) after FINGER_IDLE s with no touch or key; it goes at the first one |
## | stand | 0:10 | the edge arrow to the kebab stand by Świętokrzyska (jobs.gd FIRST_STAND), straight ahead of the start (START), until an order starts or LURE_LATEST (then one toast: the kebab will wait, step 1) |
## | order | 0:15 | --first10 only: that stand's guided order (~250 m straight on up Marszałkowska, jobs.gd `pin_first`) |
## | beta | ~1:15 | BETA_AFTER s after the first delivery (or the kebab let go), BETA_LATEST at the latest, when free and no card is up (F 2026-11-17: "the game is in beta, in the first minutes introduce that there are the different activities"): one card, "That was just a kebab": six tiles (kebabs, rides, races, rescues, friends' quests, the collection; quest_book.gd SHOWCASE) and SEE QUESTS (the map's QUESTS screen, `open_quests`) or DRIVE ON; once, never again (BETA_LIFE s unanswered: DRIVE ON). The choice card then waits BETA_GAP s of free driving |
## | choice | ~1:30 | CHOICE_AFTER s after the first delivery (or the kebab let go), CHOICE_LATEST at the latest, when calls may ring (hud.gd `call_ok`): Pani Halina rolls up and stops behind the car (rivals.gd `call_first`, no prompt), then the choice card (her face, the route and the reward; START RACE gold, RIDES, FLY, ✕). START RACE starts the race at once; any other answer sends her off (no cooldown) and its pick is introduced; JUST DRIVE (or no answer in CHOICE_LIFE s) is never asked again |
## | race | intro | Pani Halina rolls up behind and flashes (rivals.gd `call_first`), once: refused, she joins the others on the map; START RACE on the choice card has made it already |
## | trap | intro | the police's scripted first contact (police.gd), armed by the race; without one the director arms it |
## | rescue | intro | the first call (held by missions.gd `held` until then) rings RESCUE_RING s later |
## | heli | intro | the helicopter's toast; at once when a rescue is done or a call needs the helicopter |
## | tape | intro | the arrow to the mixtape on the University Library's roof (cassettes.gd, CASSETTE_ID), from the air; without it, KASETA on the boulevards (TAPE_ID) |
## | ride | intro | the first Łuber request (rides.gd `offer_now`) |
## | powisle | intro | the arrow to Powiśle, unless districts.gd discovered it |
## | garage | intro | Mirek's garage (garage.gd `held`), after the first earnings: its toast and an arrow; it comes right after the race (the race's tick toast names it) |
## | kebab | intro | the arrow to the stand again, for a player who never delivered one |
##
## The guide ends when every intro was made or met (or at GUIDE_END s): every hold is let go and
## `done` is saved. Its progress is the save's [intro] section (wallet.gd `intro`: beat id -> the
## day); an old save with progress never sees it, so it never locks anything for a returning player.
##
## **It remembers** (the first-15-minutes review, 2026-11-22: PostHog showed the finger and the
## kebab arrow two and three times to the same player): a beat saved in [intro] is not made again
## in a later session (`restored`), the opening flyover and the Palace start come on the first
## launch only (`first_launch`, OPENED_KEY), and a guide once started (GUIDE_KEY) carries on in
## later sessions until `done`, even with złoty in the wallet (a First steps tick pays 50 zł, which
## used to switch the guide off for good, so Halina, Mirek and the first call never came).
##
## **First steps** (first_steps.gd, any save): the seven steps tick here from the facts, each with
## its reward; the third opens the friends' calls early (`friends_wait`: until FRIENDS_STEPS steps or
## FRIENDS_AFTER s of just driving, saved as FRIENDS_KEY for later sessions, then at most one new
## friend every NEW_FRIEND_GAP s while the guide runs; main.gd `_free_block`), all seven bring the "First steps done" card. With steps left, WHAT_NEXT s of free
## driving bring the gold arrow to the nearest one that has a place, for WHAT_NEXT_SHOW s.
##
## **The end card** (any save): once `Ladder.final_won()` (the "Trzy mosty" win, `trzy_mosty` in
## [ladder]) and END_JOBS jobs done (wallet.gd `jobs_done`), shown once when nothing else is on:
## "Dzięki za grę! / Thanks for playing!", the demo's end, the credits line, the repo's name and
## "Jedź dalej · Free roam" (everything stays unlocked); `end_seen` saved in [intro].
##
## --first10 scripts the beats' triggers for a headless replay with --autopilot (the car taken to
## the stand, RACE on the choice card, the call answered, the tape played, the cards
## closed), prints a `first10:` line per beat and `first10: OK` when each came by its window's end
## (WINDOWS), and quits. --end-card shows the end card at once, --first-race has Halina roll up a
## second in (screenshots).

const Ladder := preload("res://scripts/ladder.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const Pacer := preload("res://scripts/pacer.gd")
const Rules := preload("res://scripts/ride_rules.gd")
const Access := preload("res://scripts/access.gd")
const QuestBook := preload("res://scripts/quest_book.gd")
const QuestsScreen := preload("res://scripts/quests_screen.gd")
const Lang := preload("res://scripts/lang.gd")

## Five looks a second.
const TICK := 0.2
## The intros after the choice card, in the order the guide brings them (the garage right after the
## race: the race pays, and Mirek is where the money goes).
const INTROS := ["race", "garage", "trap", "rescue", "heli", "tape", "ride", "powisle", "kebab"]
## The intro a First steps tick makes "met" (the step done by the player: no intro for it).
const INTRO_STEP := {"race": "race", "trap": "police", "rescue": "rescue", "heli": "heli", "ride": "ride",
		"garage": "garage", "kebab": "kebab"}
## The beats a --first10 replay must see, and the window (seconds of play) each one's trigger must
## fall in for the replay and check_first10.gd: a beat met by the player before its window is fine
## (an early order is good); a beat the director fires is fired inside it. Since step 3 the intros'
## windows are wide: they follow the player, not the clock ("kebab" is met by the first delivery,
## so the replay does not ask for it).
const BEATS := ["finger", "stand", "order", "beta", "choice", "race", "trap", "rescue", "heli", "tape", "ride", "powisle", "garage"]
const WINDOWS := {
	"finger": Vector2(4.0, 8.0), "stand": Vector2(10.0, 25.0), "order": Vector2(15.0, 60.0),
	"beta": Vector2(40.0, 240.0), "choice": Vector2(60.0, 260.0), "race": Vector2(60.0, 330.0), "trap": Vector2(60.0, 480.0),
	"rescue": Vector2(100.0, 560.0), "heli": Vector2(100.0, 640.0), "tape": Vector2(100.0, 700.0),
	"ride": Vector2(100.0, 740.0), "powisle": Vector2(100.0, 740.0), "garage": Vector2(100.0, 760.0),
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
## First hour, step 1: the kebab is a lure, not a duty. With no order started by LURE_LATEST s the
## stand's arrow goes with one toast ("lure", not a beat of 6.2: no window), and the free minute
## before the choice card starts then, as after a delivery (or after the first order went back
## quietly, jobs.gd `first_gone`).
const LURE_LATEST := 90.0
## [intro] keys: the guide began on this save (it then carries on in later sessions until `done`),
## and the opening (the flyover, the Palace start) was seen.
const GUIDE_KEY := "guide"
const OPENED_KEY := "opened"
## A beat restored from the save counts as made this many seconds into the session (`restored`):
## after the kebab let go (`lure`) the beta card comes BETA_AFTER s after it, not in the first seconds.
const RESTORED_AT := 15.0
## --first10: the car is taken to the stand at ORDER_AT s.
const ORDER_AT := 15.0
## The beta card (2026-11-17): seconds after the first delivery (or the kebab let go), its latest
## second without either, how long it stays up unanswered, and the free seconds after it before the
## choice card. Its tiles: QuestBook.SHOWCASE, BETA_TILE points each.
static var BETA_AFTER: float = Pacer.num("first_steps", "beta_after")
static var BETA_LATEST: float = Pacer.num("first_steps", "beta_latest")
static var BETA_GAP: float = Pacer.num("first_steps", "choice_after_beta")
const BETA_LIFE := 40.0
const BETA_TILE := 44.0
const BETA_COLOUR := Color("#ffd23f")
## First hour, step 3: the choice card's free minute after the first delivery (or the kebab let
## go), its latest second without either, and how long it stays up unanswered (then: just drive).
static var CHOICE_AFTER: float = Pacer.num("first_steps", "choice_after")
static var CHOICE_LATEST: float = Pacer.num("first_steps", "choice_latest")
const CHOICE_LIFE := 30.0
## The choice card waits for Pani Halina to stop behind the car (rivals.gd `call_first` with no
## prompt) at most this long, then shows anyway.
const CHOICE_HALINA_WAIT := 12.0
## Seconds of free driving, and since the last intro, before the next intro.
static var NEXT_GAP: float = Pacer.num("first_steps", "next_gap")
## The friends' calls (main.gd `_free_block`) wait for FRIENDS_STEPS ticked steps or FRIENDS_AFTER s
## of play, then at most one new friend every NEW_FRIEND_GAP s while the guide runs. F 2026-11-22: a
## player who skips the First steps and just drives must get the calls too (they are how the
## questlines are found), so FRIENDS_AFTER is a few minutes (was 12), and once open they stay open
## in later sessions (FRIENDS_KEY saved in [intro]).
static var FRIENDS_STEPS: float = Pacer.num("first_steps", "friends_steps")
static var FRIENDS_AFTER: float = Pacer.num("first_steps", "friends_after")
static var NEW_FRIEND_GAP: float = Pacer.num("first_steps", "new_friend_gap")
const FRIENDS_KEY := "friends_open"
## A friend's call yields to the guide's next intro once the player has been free this long (the
## intro itself comes at NEXT_GAP s).
const FRIENDS_YIELD := 20.0
## "What next?": the gold arrow to the nearest step left after this much free driving, for so long.
const WHAT_NEXT := 90.0
const WHAT_NEXT_SHOW := 25.0
## An intro that cannot be made now (Halina has no lane near, no ride request fits) is tried again
## after this many seconds, and given up after FIRE_TRIES tries (so the guide never stalls on it).
const FIRE_RETRY := 2.0
const FIRE_TRIES := 15
const RESCUE_RING := 12.0
const TAPE_ID := "t_bulwary_2018"
## The guide's cassette (cassettes.json): on the BUW roof by the boulevards.
const CASSETTE_ID := "c01_buw"
const GUIDE_END := 1200.0
## The replay judges by here at the latest (after the last window, before verify.sh's 48000 frames).
const REPLAY_DEADLINE := 770.0
## An arrow stays at most this long (s), unless its beat is met first.
const HINT_S := 150.0
const GARAGE_HINT_S := 90.0
const HINT_COLOUR := Color("#ffd23f")
## The choice card (step 3, F's playtest 2026-11-16: a hook, not three equal buttons): Pani Halina
## flashes behind the car, her face on the left (`Portraits.badge`, her colour), the title, one taunt
## line with the route and the reward, and below three buttons one under the other: START RACE gold
## and taller (hud.gd `set_card_lead`), RIDES and FLY plain. The words are dialogue.json's
## first_steps group (`choice_words` fills in the numbers); CHOICE_LOG names the buttons in the log.
## What each button introduces, in order. JUST DRIVE is the card's ✕ (hud.gd `set_card_close`, the
## critique's point 1): the press CHOICE_CLOSE, past the three buttons, with no pick.
const CHOICE_LOG := ["START RACE", "RIDES", "FLY"]
const CHOICE_CLOSE := 3
const CHOICE_PICKS := [["race"], ["ride"], ["heli", "tape"], []]
const CHOICE_COLOUR := Color("#ffd23f")
## Her badge on the card: the name Portraits looks the face up by, her colour (rivals.gd) and its size (pt).
const CHOICE_WHO := "Pani Halina"
const CHOICE_FACE := Color("#86d3b0")
const CHOICE_FACE_PT := 72.0
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
	"lure": ["Kebab poczeka na stoisku. Wpadnij, kiedy chcesz.", "The kebab will wait at the stand. Come by anytime."],
	"heli": ["Pogotowie lotnicze pożycza ci stary śmigłowiec: HELI", "The air ambulance lends you its old helicopter: HELI"],
	"heli_locked": ["Helikopter? Najpierw jedno wezwanie ratunkowe.", "The helicopter comes after your first rescue call."],
	"tape": ["Na dachu BUW leży kaseta z muzyką. Leć po nią helikopterem.", "A mixtape lies on the BUW roof: fly the helicopter to it."],
	"tape_ground": ["Na bulwarach czeka KASETA. Zwolnij przy niej.", "A KASETA waits on the boulevards: slow down by it."],
	"powisle": ["Pod skarpą jest Powiśle. Zjedź w dół, do Wisły.", "Powiśle is below the escarpment: head down to the river."],
}

signal beat(id: String, how: String, at: float)
## A First steps tick (first_steps.gd): the step, how many are done now, and whether it was quiet
## (an old save's progress at the start: no reward).
signal step_ticked(id: String, n: int, quiet: bool)

## Set by main.gd.
var wallet: Node
var hud: CanvasLayer
var map: Node3D
var car: CharacterBody3D
var jobs: Node
## () -> bool: one of the side jobs is on (main.gd: the director's `job_on`: a kebab, the słoiki,
## a ride, the round-up, a trend job). jobs.gd answered for all of them before it joined the kit.
var job_on: Callable = func() -> bool: return false
var rivals: Node
var missions: Node
var police: Node
var tape: Node
var radio: Node
var districts: Node
var garage: Node
## cassettes.gd: the guide's cassette (null or not placed: KASETA's then card instead).
var cassettes: Node
## main.gd: the vehicle is the helicopter now.
var flying: Callable
## --first10: the replay's scripted triggers (with --autopilot), its lines, the check and the quit.
var scripted := false
## The guide runs on this save (`guide_due` at `begin`).
var guide := false
## This launch is the guide's first (`first_launch`): the opening flyover and the Palace start.
var opening := false
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
var _stand := -1
var _end_up := false
var _song := false
var _card_t := 0.0
var _call_t := 0.0
## The replay: the car's last finite position (for the NaN report).
var _last_pos := Vector3.ZERO
var _done_t := -1.0
var _input_base := 0
## An intro is close and waits for a free moment: new offers are held (`due`).
var offers_held := false
## Seconds the player has been free without a break (`facts`' free_for).
var _free_for := 0.0
## The choice card is up (since `_choice_t`); the intros its pick asks for first (`want`).
var _choice_up := false
var _choice_t := 0.0
## The choice beat asked Halina to roll up and the card waits for her to stop (since `_choice_wait_t`);
## `_choice_halina`: she is behind the car for the card (START RACE starts her race at once).
var _choice_pending := false
var _choice_wait_t := 0.0
var _choice_halina := false
var _want: Array[String] = []
## The beta card is up (since `_beta_t`).
var _beta_up := false
var _beta_t := 0.0
## The beta card's SEE QUESTS: the full map with the QUESTS screen up (main.gd).
var open_quests: Callable
## An intro that could not be made: not before this second again, and its tries.
var _retry_t := 0.0
var _tries := {}
## Jobs done (wallet.gd `jobs_done`) when the last intro came (`due`: one job between two intros).
var _jobs_at_intro := 0
## The First steps facts the signals latch (the race run, the call answered, the helicopter flown,
## the police met, the garage opened).
var _raced := false
var _answered := false
var _flown := false
var _police_met := false
var _garage_opened := false
## The "First steps done" card is due (shown when free) or up.
var _all_due := false
var _all_up := false
## The friends' calls: the friends heard this session, and when the last new one rang (-1: none).
var _friends := {}
var _friend_t := -1.0
## An intro waits and the player has been free FRIENDS_YIELD s: it goes before a friend's call.
var _intro_next := false
## "What next?": free seconds counted, and the arrow is the one it showed.
var _next_free := 0.0
var _what_next := false


# --- the rules (static: check_first10.gd tests them without the map) ---------------------------

## The guide runs on a fresh save (no jobs done, no złoty, no rung beaten), and on a save where it
## began (GUIDE_KEY) and has not finished yet, whatever was earned since.
static func guide_due(w: Node) -> bool:
	if w == null or w.intro.has("done"):
		return false
	if w.intro.has(GUIDE_KEY):
		return true
	return w.jobs_done() == 0 and int(w.zl) == 0 and w.ladder.is_empty()


## The first launch of the guide: the opening flyover, the song from its first bar and the start at
## the Palace (main.gd). Once seen (OPENED_KEY), a later session starts where the last one left off.
static func first_launch(w: Node) -> bool:
	return guide_due(w) and not w.intro.has(OPENED_KEY)


## The beats an earlier session made, from the save's [intro] (beat id -> RESTORED_AT): the guide
## does not make them again. The kebab arrow shown (`stand`) with no order taken counts as let go
## (`lure`): the next session does not point at the stand again, and the free minute before the
## beta and choice cards starts at once (the "kebab" intro still brings the stand back later).
static func restored(intro: Dictionary) -> Dictionary:
	var out := {}
	for id: String in BEATS + ["lure", "kebab"]:
		if intro.has(id):
			out[id] = RESTORED_AT
	if out.has("stand") and not out.has("order") and not out.has("lure"):
		out["lure"] = RESTORED_AT
	return out


## The end card is due: the final won, END_JOBS jobs done, not seen yet.
static func end_due(w: Node) -> bool:
	if w == null:
		return false
	return w.ladder.has(Ladder.FINAL_ID) and w.jobs_done() >= END_JOBS and not w.intro.has("end_seen")


## The beats the facts say happened by themselves (the player's doing).
## Facts: input, ordered, raced, trap, rang, tape, powisle, garage (bools), and `steps` (the First
## steps ticked: an intro whose step is done is met).
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
	var steps: Array = f.get("steps", [])
	for id: String in INTROS:
		if INTRO_STEP.has(id) and str(INTRO_STEP[id]) in steps and not id in out:
			out.append(id)
	return out


## The beats the director fires now, at second `now`, from the facts `f` (met's, plus: free,
## free_for (seconds free without a break), delivered_t (-1: no delivery yet), calling (a rival is
## rolling up), rescued, earned, heli_call (a helicopter-only call is up), want (the intros the
## choice card's pick asks for first), retry_t (no intro before this second), ways (beat -> "fired"
## or "met", as `how`), scripted) and the beats already triggered (`done`: beat -> second). "done"
## too, when the guide is over.
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
	if not is_done.call("lure") and is_done.call("stand") and not f.get("ordered", false) and now >= LURE_LATEST and free:
		out.append("lure")
	var delivered: float = f.get("delivered_t", -1.0)
	if delivered < 0.0 and is_done.call("lure"):
		delivered = float(done["lure"])
	if not is_done.call("beta") and not is_done.call("choice") and free \
			and ((delivered >= 0.0 and now >= delivered + BETA_AFTER) or now >= BETA_LATEST):
		out.append("beta")
	# The choice card: CHOICE_AFTER s after the delivery, and BETA_GAP s of free driving after the beta card.
	var after_beta: bool = not is_done.call("beta") or float(f.get("free_for", 0.0)) >= BETA_GAP
	if not is_done.call("choice") and free and not "beta" in out and after_beta \
			and ((delivered >= 0.0 and now >= delivered + CHOICE_AFTER) or now >= CHOICE_LATEST):
		out.append("choice")
	# The helicopter's toast never waits once a rescue is done or a call needs it.
	if not is_done.call("heli") and (f.get("rescued", false) or f.get("heli_call", false)):
		out.append("heli")
	if is_done.call("choice"):
		var nxt := next_intro(now, f, done)
		if nxt != "":
			out.append(nxt)
	if not is_done.call("done") and (now >= GUIDE_END or (is_done.call("choice") and _all_intros(done, out))):
		out.append("done")
	return out


## The intro the director makes now ("" for none): the choice card's pick first (`want`), at once
## when free; else the first in INTROS not done yet whose turn it can be (`_intro_ready`), once the player
## has been free NEXT_GAP s and the last intro (or the choice) is NEXT_GAP s back.
static func next_intro(now: float, f: Dictionary, done: Dictionary) -> String:
	if not f.get("free", false) or now < float(f.get("retry_t", 0.0)):
		return ""
	for id: String in f.get("want", []):
		if not done.has(id) and _intro_ready(id, f, done):
			return id
	if float(f.get("free_for", 0.0)) < NEXT_GAP or now - last_intro(done, f.get("ways", {})) < NEXT_GAP:
		return ""
	return waiting_intro(f, done)


## The first intro in INTROS not done yet that may come now, free or not ("" for none).
static func waiting_intro(f: Dictionary, done: Dictionary) -> String:
	for id: String in INTROS:
		if not done.has(id) and _intro_ready(id, f, done):
			return id
	return ""


## The second of the last intro the director made, or of the choice card (-INF: none yet). `ways`
## (beat -> "fired" or "met"): a step the player did alone does not count.
static func last_intro(done: Dictionary, ways := {}) -> float:
	var last := -INF
	for id: String in INTROS + ["choice"]:
		if done.has(id) and str(ways.get(id, "fired")) == "fired":
			last = maxf(last, float(done[id]))
	return last


## An intro's own condition: Halina is not rolling up already; the tape after the helicopter; the
## garage after the first earnings.
static func _intro_ready(id: String, f: Dictionary, done: Dictionary) -> bool:
	match id:
		"race":
			return not f.get("calling", false)
		"tape":
			return done.has("heli")
		"garage":
			return f.get("earned", false)
	return true


static func _all_intros(done: Dictionary, now_out: Array) -> bool:
	for id: String in INTROS:
		if not done.has(id) and not id in now_out:
			return false
	return true


## What the guide holds new offers for now (empty: nothing): the choice card before it has come
## (the first Łuber request comes after it), then the intro waiting once a job was done since the
## last intro (`jobs_since`): one job between two intros, so a player who takes every ride still
## meets each intro (run 12, 2026-11-03: the call came 83 s late behind a ride), and a rider gets
## rides between them.
static func due(_now: float, f: Dictionary, done: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if done.has("done"):
		return out
	if not done.has("choice"):
		out.append("choice")
		return out
	if f.get("jobs_since", false) or not f.get("want", []).is_empty():
		var w := waiting_intro(f, done)
		if w != "":
			out.append(w)
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


## The friends' calls wait (`friends_wait`): `steps` ticked, `now` s of play, the last new friend's
## call at `friend_t` (-1: none yet); `intro_next`: one of the guide's intros waits and the player has
## been free FRIENDS_YIELD s, so it goes first (one thing at a time: the replay of 2026-11-15 took
## Szymek's boat race between two intros and Mirek's garage never came in its window).
## `opened`: an earlier session already opened them (FRIENDS_KEY in [intro]), so a player who only
## drives in short sessions is not held again each time (F 2026-11-22).
static func friends_held(steps: int, now: float, friend_t: float, intro_next := false, opened := false) -> bool:
	if not opened and steps < int(FRIENDS_STEPS) and now < FRIENDS_AFTER:
		return true
	if intro_next:
		return true
	return friend_t >= 0.0 and now - friend_t < NEW_FRIEND_GAP


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


## Hooks up the cards, the tape and the First steps' signals, and holds what the guide holds (on a
## fresh save). Called once the city is built (before the title is dismissed).
func setup(want_guide: bool) -> void:
	guide = want_guide and guide_due(wallet)
	opening = guide and first_launch(wallet)
	if guide:
		fired = restored(wallet.intro)
		for id: String in fired:
			how[id] = "saved"
		if not wallet.intro.has(GUIDE_KEY):
			wallet.intro[GUIDE_KEY] = _today()
			wallet.save()
	if hud != null:
		hud.card_pressed.connect(_on_card)
	if tape != null and tape.has_signal("played"):
		tape.played.connect(_on_tape)
	if missions != null and missions.has_signal("accepted"):
		missions.accepted.connect(func() -> void: _answered = true)
	if police != null and police.has_signal("chase_ended"):
		police.chase_ended.connect(_on_police_end)
	if garage != null and garage.has_signal("opened"):
		# G2: MOJE AUTO opens the same card from the map; only a visit at Mirek's ticks the step.
		garage.opened.connect(func() -> void:
			if str(garage.get("mode")) != "mine":
				_garage_opened = true)
	if guide:
		# What an earlier session's intros let go stays let go.
		if missions != null:
			missions.held = not fired.has("rescue")
		if garage != null:
			garage.held = not fired.has("garage")
		# 2026-11-01 (F, beta): the helicopter and the map teleport are open from the first second;
		# the "heli" intro stays as a hint.
		if jobs != null:
			_stand = jobs.first_stand()
			if _stand >= 0:
				jobs.pin_first(_stand)
	# First steps: what an existing save already shows ticks quietly, with no reward.
	if wallet != null:
		for id in FirstSteps.from_wallet(wallet.jobs, wallet.ladder):
			_tick_step(id, true)
	print("first10: guide %s%s%s%s; first steps %d/%d" % ["on" if guide else "off", " (scripted)" if scripted else "",
			", first stand %d" % _stand if guide else "",
			", resumed: %s" % ", ".join(PackedStringArray(fired.keys())) if guide and not fired.is_empty() else "",
			steps_done(), FirstSteps.IDS.size()])


## The clock starts (the title is gone, or there was none).
func begin() -> void:
	_running = true
	# The tap that closed the title is not "the first touch" of the drive.
	_input_base = int(hud.input_ms) if hud != null else 0
	if opening and wallet != null and not wallet.intro.has(OPENED_KEY):
		wallet.intro[OPENED_KEY] = _today()
		wallet.save()


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


## First steps ticked in this save (first_steps.gd).
func steps_done() -> int:
	return FirstSteps.count(wallet.intro) if wallet != null else 0


## The friends' calls wait now (main.gd `_free_block`, `_ev_free`): while the guide runs, until
## FRIENDS_STEPS steps or FRIENDS_AFTER s, then while an intro waits for its turn (`_intro_next`) and
## NEW_FRIEND_GAP s after each new friend's first call.
## Before step 3 the whole guide held them (it ran about ten minutes).
func friends_wait() -> bool:
	return guide_on() and friends_held(steps_done(), t, _friend_t, _intro_next, _friends_saved())


## The friends may call at all (the QUESTLINES tab's head, main.gd `_fill_map_list`): no guide, or
## FRIENDS_STEPS steps, FRIENDS_AFTER s of play, or an earlier session opened them. The one-at-a-time
## spacing after that is `friends_wait`'s.
func friends_open() -> bool:
	return not guide_on() or _friends_saved() or steps_done() >= int(FRIENDS_STEPS) or t >= FRIENDS_AFTER


func _friends_saved() -> bool:
	return wallet != null and wallet.intro.has(FRIENDS_KEY)


## The friends opened in this session (steps or time): saved, so the next session doesn't hold them.
func _friends_save() -> void:
	if wallet == null or not guide_on() or _friends_saved():
		return
	if steps_done() < int(FRIENDS_STEPS) and t < FRIENDS_AFTER:
		return
	wallet.intro[FRIENDS_KEY] = _today()
	wallet.save()
	print("first10: the friends may call (%d steps, %.1f s)" % [steps_done(), t])


## An activity of the kit's phone rang (main.gd, the director's `rang`): `tag` names it. A friend
## heard for the first time this session starts the NEW_FRIEND_GAP s wait for the next new one.
func friend_rang(tag: String) -> void:
	if _friends.has(tag):
		return
	_friends[tag] = t
	if guide_on():
		_friend_t = t
		print("first10: a new friend rang (%s) at %.1f s" % [tag, t])


## One look: the facts, the First steps, the beats met and fired, the arrow, the cards.
func tick() -> void:
	var f := facts()
	_free_for = _free_for + TICK if f["free"] else 0.0
	f["free_for"] = _free_for
	_steps_tick(f)
	_friends_save()
	f["steps"] = FirstSteps.done(wallet.intro) if wallet != null else []
	if guide and not fired.has("done"):
		for id in met(f):
			if not fired.has(id):
				_trigger(id, "met")
		for id in decide(t, f, fired):
			_fire(id)
		_follow_up(f)
	_hold_offers(guide and not due(t, f, fired).is_empty())
	_intro_next = guide and fired.has("choice") and not fired.has("done") and _free_for >= FRIENDS_YIELD \
			and waiting_intro(f, fired) != ""
	if _choice_pending and (t - _choice_wait_t > CHOICE_HALINA_WAIT or rivals == null or rivals.first_stopped() or not rivals.first_waiting()):
		_choice_pending = false
		_show_choice()
	if _choice_up and t - _choice_t > CHOICE_LIFE:
		_pick(CHOICE_PICKS.size() - 1, "unanswered")
	if _beta_up and t - _beta_t > BETA_LIFE:
		_beta_pressed(1, "unanswered")
	if hint_shown() and (t > hint_until or _hint_met(f)):
		hint_at = Vector3.INF
		_what_next = false
	_what_next_tick(f)
	if _all_due and not _all_up and f["free"] and not f["rang"]:
		_show_all_card()
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


## Holds (or lets go of) what comes by itself: Łuber's requests and the "Na czasie" offers.
## A ride already under way runs on; only new ones wait (the ŁUBER button still asks for one).
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


## Other quests that make the moment not free (main.gd: out on the water in the boat race or a free
## ride, not on the way to the pontoon; Autopilot 2026-11-09: the
## guide's kebab-stand note came up mid-race on a fresh save).
var side_busy: Callable = func() -> bool: return false


## What the director knows now (see `decide`).
func facts() -> Dictionary:
	var air: bool = flying.is_valid() and bool(flying.call())
	# PT-15: a ride request's card up counts (Halina won't roll up over it).
	# Everything that makes the moment not free, a job of the player's aside.
	var other: bool = (jobs != null and jobs.ride_offered()) or (rivals != null and (rivals.busy() or rivals.first_waiting())) \
			or (missions != null and missions.busy()) \
			or (police != null and int(police.phase) != 0) or (garage != null and garage.is_open()) or _end_up \
			or _choice_up or _choice_pending or _all_up or _beta_up or bool(side_busy.call())
	var busy: bool = other or (jobs != null and bool(job_on.call()))
	var orders: int = jobs.orders_started() if jobs != null else 0
	var gone: bool = jobs != null and jobs.get("first_gone") == true
	if _delivered_t < 0.0 and ((wallet != null and wallet.jobs_done() > 0) or gone) and not busy:
		_delivered_t = t
	if air:
		_flown = true
	if rivals != null and (str(rivals.first_result) in ["won", "lost"] or rivals.raced()):
		_raced = true
	return {
		"input": hud != null and int(hud.input_ms) > _input_base,
		"free": not busy,
		"ordered": orders > 0,
		"delivered_t": _delivered_t,
		"raced": _raced,
		"calling": rivals != null and rivals.first_waiting(),
		"trap": police != null and police.first_armed(),
		"rang": missions != null and not missions.idle(),
		"rescued": wallet != null and int(wallet.jobs.get("rescue", 0)) > 0,
		"heli_call": missions != null and missions.has_method("call_needs_heli") and missions.call_needs_heli(),
		"tape": _tape_done(),
		"powisle": districts != null and districts.is_discovered("powisle"),
		"garage": garage != null and garage.is_shown(),
		"earned": wallet != null and (wallet.jobs_done() > 0 or int(wallet.zl) > 0),
		"scripted": scripted,
		"flying": air,
		"want": _want,
		"retry_t": _retry_t,
		"ways": how,
		"jobs_since": wallet != null and wallet.jobs_done() > _jobs_at_intro,
	}


## The First steps the facts show now (first_steps.gd `from_facts`), ticked once each.
func _steps_tick(f: Dictionary) -> void:
	if wallet == null:
		return
	var sf := {
		"kebab": int(wallet.jobs.get("kebab", 0)) > 0,
		"ride": int(wallet.jobs.get("podwozka", 0)) > 0,
		"race": _raced or int(wallet.jobs.get("race", 0)) > 0,
		"rescue": _answered or bool(f["rescued"]),
		"heli": _flown,
		"police": _police_met,
		"garage": _garage_opened,
	}
	for id in FirstSteps.from_facts(sf):
		if not wallet.intro.has(FirstSteps.KEY + id):
			_tick_step(id, false)


## Ticks step `id` in the save; `quiet` (an old save's progress at the start) brings no reward.
## Else the step's reward (first_steps.gd `reward`): złoty, a paint at the third and the seventh
## (owned in Mirek's garage, not put on), the toast, and at the seventh the card when free.
func _tick_step(id: String, quiet: bool) -> void:
	if wallet == null or wallet.intro.has(FirstSteps.KEY + id):
		return
	wallet.intro[FirstSteps.KEY + id] = maxi(1, roundi(t))
	var n := steps_done()
	print("first10: first step %s ticked%s at %.1f s (%d/%d)" % [id, " quietly" if quiet else "", t, n, FirstSteps.IDS.size()])
	if quiet:
		wallet.save()
		step_ticked.emit(id, n, true)
		return
	var r := FirstSteps.reward(n)
	var paint := str(r["paint"])
	if paint != "" and not wallet.paints.has(paint):
		wallet.paints[paint] = _today()
	wallet.pay(int(r["zl"]), int(r["respect"]), "")  # saves
	if hud != null:
		var w := FirstSteps.tick_words(id, n, id == "race" and not _garage_opened and not wallet.intro.has(FirstSteps.KEY + "garage"))
		hud.toast(w[0], w[1])
		if bool(r["noticed"]):
			var noticed: Array = FirstSteps.words("noticed")
			hud.toast(noticed[0], noticed[1])
	if bool(r["card"]):
		_all_due = true
	step_ticked.emit(id, n, false)


func _on_police_end(how_: String) -> void:
	# Stopped (a pull-over), got away, the end of a shift, or off in the helicopter: met. A guard's
	# talk is not the police's; a meet given up is not the player's chase.
	if how_ != "guard" and how_ != "quit":
		_police_met = true


func _trigger(id: String, way: String) -> void:
	if fired.has(id):
		return
	fired[id] = snappedf(t, 0.1)
	how[id] = way
	_want.erase(id)
	if way == "fired" and (id in INTROS or id == "choice") and wallet != null:
		_jobs_at_intro = wallet.jobs_done()
	if wallet != null and id in BEATS + ["done", "lure", "kebab"]:
		wallet.intro[id] = _today()
		wallet.save()
	var w: Vector2 = WINDOWS.get(id, Vector2(-1, -1))
	print("first10: %s %s at %.1f s%s" % [id, way, t, " (window %.0f-%.0f s)" % [w.x, w.y] if w.x >= 0.0 else ""])
	beat.emit(id, way, t)


## The director pushes beat `id`; an intro that cannot be made now is tried again FIRE_RETRY s later
## (and counted as made after FIRE_TRIES tries).
func _fire(id: String) -> void:
	var ok := true
	match id:
		"finger":
			if hud != null:
				hud.ghost_finger(true)
		"stand":
			if jobs != null and _stand >= 0:
				_hint(jobs.stand_ring(_stand), "KEBAB", HINT_S)
				hud.toast(LINES["stand"][0], LINES["stand"][1])
		"lure":
			if hint_word == "KEBAB":
				hint_at = Vector3.INF
			if hud != null:
				hud.toast(LINES["lure"][0], LINES["lure"][1])
		"order":
			# --first10 only: the car at the stand, the guided order.
			if jobs == null or _stand < 0 or not jobs.start_first(_stand):
				return
		"beta":
			# Over another card (the delivery's result) it waits a tick; without a HUD it is made.
			if hud != null:
				# ... and a breath after it (F 2026-11-19: no cards back to back; the beta card is the
				# guide's own explanation, so it does not wait the quiet time after the delivery).
				if hud.cards_up() or not hud.messages.spaced():
					return
				_show_beta()
		"choice":
			# The one offer, in the guide's neutral voice, when calls may ring (hud.gd `call_ok`).
			if hud == null or not hud.call_ok():
				return
			# Halina rolls up first (no prompt: she stops behind the car, held, and says her line); the
			# card shows when she has stopped, after CHOICE_HALINA_WAIT s, or at once when she cannot.
			if rivals != null and rivals.call_first(CHOICE_WHO, false):
				_choice_pending = true
				_choice_wait_t = t
				_choice_halina = true
			else:
				_choice_halina = false
				_show_choice()
		"race":
			# Halina's flash is an offer: it waits like one (hud.gd `offer_ok`, F 2026-11-19).
			if hud != null and not hud.offer_ok():
				return
			ok = rivals != null and rivals.call_first()
		"trap":
			if police != null:
				police.arm_first_contact()
		"rescue":
			if missions != null:
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
		"ride":
			if hud != null and not hud.offer_ok():
				return  # the request is a card: it waits like any offer (F 2026-11-19)
			var ride: Variant = jobs.get("rides") if jobs != null else null
			ok = ride is Node and ride.has_method("offer_now") and bool(ride.call("offer_now"))
			if ok and hud != null:
				var ride_words: Array = FirstSteps.words("intro_ride")
				hud.toast(ride_words[0], ride_words[1])
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
		"kebab":
			if jobs != null and _stand >= 0:
				_hint(jobs.stand_ring(_stand), "KEBAB", HINT_S)
				var kebab_words: Array = FirstSteps.words("intro_kebab")
				hud.toast(kebab_words[0], kebab_words[1])
		"done":
			_end_guide()
	if not ok:
		_tries[id] = int(_tries.get(id, 0)) + 1
		if int(_tries[id]) < FIRE_TRIES:
			_retry_t = t + FIRE_RETRY
			return
		print("first10: %s could not be made in %d tries: given up" % [id, FIRE_TRIES])
		if id == "race":
			_race_ring()
	_trigger(id, "fired")


## What runs between the beats: the call kept coming once let through.
func _follow_up(f: Dictionary) -> void:
	if fired.has("rescue") and how.get("rescue") == "fired" and not f["rang"] and f["free"] and missions != null \
			and missions.idle() and missions.call_in() > RESCUE_RING + 1.0:
		missions.ring_in(RESCUE_RING)


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


# --- the beta card (2026-11-17) ----------------------------------------------------------------

## The beta card: what else the city has (six tiles under the words) and where it all is (SEE
## QUESTS). Lead: SEE QUESTS; ✕ is DRIVE ON.
func _show_beta() -> void:
	_beta_up = true
	_beta_t = t
	var w := beta_words(wallet != null and int(wallet.jobs.get("kebab", 0)) > 0)
	hud.show_card(w["title"][0], w["body"][0], w["buttons"], BETA_COLOUR, false, w["title"][1], w["body"][1])
	hud.own_card(self)
	hud.set_card_art(beta_tiles(hud.pt), false, true)
	hud.set_card_lead(0)
	hud.set_card_close(1)
	print("first10: the beta card at %.1f s" % t)


## The beta card's words: {"title": [pl, en], "body": [pl, en], "buttons": PackedStringArray
## ("POLISH|ENGLISH" each): SEE QUESTS, DRIVE ON}. `kebab`: a kebab was delivered ("That was just a
## kebab"); else the body says nothing of one (most new players let it go). Pure: check_first10.gd.
static func beta_words(kebab := false) -> Dictionary:
	var see := QuestBook.words("b_show_quests")
	var drive := QuestBook.words("b_show_drive")
	return {"title": QuestBook.words("show_title"), "body": QuestBook.words("show_body" if kebab else "show_body_open"),
			"buttons": PackedStringArray(["%s|%s" % [see[0], see[1]], "%s|%s" % [drive[0], drive[1]]])}


## The strip of tiles under the beta card's words: QuestBook.SHOWCASE's icons (the QUESTS screen's
## look, quests_screen.gd `icon_tile`), each with its word under it; `pt` the HUD's point.
static func beta_tiles(pt: float) -> Control:
	var row := HBoxContainer.new()
	row.name = "beta_tiles"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(6.0 * pt))
	for pair: Array in QuestBook.SHOWCASE:
		var words := QuestBook.words(str(pair[1]))
		var name := Lang.pick(str(words[0]), str(words[1]))
		var tile := VBoxContainer.new()
		tile.name = "tile_" + str(pair[0])
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_theme_constant_override("separation", roundi(2.0 * pt))
		tile.custom_minimum_size.x = (BETA_TILE + 18.0) * pt
		var icon := QuestsScreen.icon_tile(str(pair[0]), BETA_COLOUR, name, BETA_TILE * pt)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.add_child(icon)
		var label := Label.new()
		label.text = name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = (BETA_TILE + 18.0) * pt
		label.add_theme_font_size_override("font_size", roundi(11.0 * pt))
		label.add_theme_color_override("font_color", Color("#fbf7ee"))
		tile.add_child(label)
		row.add_child(tile)
	return row


## The beta card's button `index` (0 SEE QUESTS, 1 DRIVE ON or ✕), or "unanswered".
func _beta_pressed(index: int, why := "pressed") -> void:
	_beta_up = false
	if hud != null and hud.card_is(self):
		hud.hide_card()
	print("first10: the beta card: %s (%s) at %.1f s" % ["SEE QUESTS" if index == 0 else "DRIVE ON", why, t])
	if wallet != null:
		wallet.intro["beta_pick"] = 1 if index == 0 else 2
		wallet.save()
	if index == 0 and open_quests.is_valid():
		open_quests.call()


# --- first hour, step 3: the choice card, the First steps card, "what next?" ---------------------

func _show_choice() -> void:
	_choice_up = true
	_choice_t = t
	var km := -1.0
	if rivals != null and rivals.has_method("first_route_m"):
		var m := float(rivals.first_route_m())
		km = snappedf(m / 1000.0, 0.1) if m >= 0.0 else -1.0
	var w := choice_words(km)
	hud.show_card(w["title"][0], w["body"][0], w["buttons"], CHOICE_COLOUR, false, w["title"][1], w["body"][1], true)
	hud.own_card(self)
	var face := Portraits.badge(CHOICE_FACE_PT * hud.pt)
	Portraits.set_badge(face, CHOICE_WHO, Access.tint(CHOICE_FACE))
	hud.set_card_art(face, true)
	hud.set_card_lead(0)
	hud.set_card_close(CHOICE_CLOSE)


## The choice card's words with the game's own numbers in them: {"title": [pl, en], "body": [pl, en],
## "buttons": PackedStringArray ("POLISH|ENGLISH" each)}. `km` is the road to the finish in km (rivals.gd
## `first_route_m`, rounded to 0.1; below 0: unknown, "?"); the reward is the ladder's first stake and
## WIN_GAIN, the ride chip's "from" Łuber's base fare (ride_rules.gd BASE). A pure function: check_first10.gd.
static func choice_words(km: float) -> Dictionary:
	var stake: int = int(Ladder.RUNGS[0]["stake"])
	var title: Array = FirstSteps.words("choice_title")
	var body: Array = FirstSteps.words("choice_body")
	var race: Array = FirstSteps.words("choice_race")
	var ride: Array = FirstSteps.words("choice_ride")
	var fly: Array = FirstSteps.words("choice_fly")
	var km_en := "%.1f" % km if km >= 0.0 else "?"
	var km_pl := km_en.replace(".", ",")
	var from := int(Rules.BASE)
	return {
		"title": title,
		"body": [str(body[0]) % [km_pl, stake, Ladder.WIN_GAIN], str(body[1]) % [km_en, stake, Ladder.WIN_GAIN]],
		"buttons": PackedStringArray(["%s|%s" % [str(race[0]) % stake, str(race[1]) % stake],
				"%s|%s" % [str(ride[0]) % from, str(ride[1]) % from],
				"%s|%s" % [fly[0], fly[1]]]),
	}


## The choice card's button `index` (0 to 2, CHOICE_LOG; CHOICE_CLOSE is the ✕), or "unanswered": the intros it asks for come
## first (`want`), at once when free; JUST DRIVE asks for none, and the card never comes again.
func _pick(index: int, why := "pressed") -> void:
	_choice_up = false
	if hud != null and hud.card_is(self):
		hud.hide_card()
	var picks: Array = CHOICE_PICKS[clampi(index, 0, CHOICE_PICKS.size() - 1)]
	var raced := false
	if _choice_halina and rivals != null:
		# START RACE goes straight to the race (no flash back, no second prompt); every other answer, and
		# the card's end, sends her off without the cooldown, so the race intro can still come later.
		if index == 0 and rivals.first_waiting():
			raced = bool(rivals.first_start())
		elif rivals.first_waiting():
			rivals.first_decline()
	# START RACE with no Halina behind the car (no lane to roll up on): the arrow to her ring at once,
	# so the button does something; the race intro still comes when she can roll up.
	if index == 0 and not raced and not _choice_halina:
		_race_ring()
	_choice_halina = false
	for id: String in picks:
		if raced and id == "race":
			continue  # the race is on: its beat is made below
		if not fired.has(id) and not id in _want:
			_want.append(id)
	if raced:
		_trigger("race", "fired")
	var word: String = CHOICE_LOG[index] if index >= 0 and index < CHOICE_LOG.size() else "JUST DRIVE (✕)"
	print("first10: the choice card: %s (%s) at %.1f s%s" % [word, why, t, ", the race started" if raced else ""])
	if wallet != null:
		wallet.intro["choice_pick"] = clampi(index, 0, CHOICE_PICKS.size() - 1) + 1
		wallet.save()


## The arrow to Pani Halina's ring and its toast (START RACE with no Halina behind the car, or her
## roll-up given up): the race is still there to start.
func _race_ring() -> void:
	var at := _step_at("race")
	if at == Vector3.INF:
		return
	_hint(at, "HALINA", HINT_S)
	if hud != null:
		var w: Array = FirstSteps.words("race_ring")
		hud.toast(w[0], w[1])
	print("first10: the arrow to Halina's ring")


## A button of a card the guide owns (hud.gd `own_card`): the choice card's, or the First steps
## card's.
func card_pressed(index: int) -> void:
	if _beta_up:
		_beta_pressed(index)
	elif _choice_up:
		_pick(index)
	elif _all_up:
		_all_up = false
		if hud != null and hud.card_is(self):
			hud.hide_card()
		print("first10: the First steps card closed")


func _show_all_card() -> void:
	if hud == null or hud.cards_up():
		return
	_all_due = false
	_all_up = true
	var title: Array = FirstSteps.words("all_title")
	var body: Array = FirstSteps.words("all_body")
	hud.show_card(title[0], body[0], PackedStringArray([FirstSteps.ALL_BUTTON]),
			CHOICE_COLOUR, false, title[1], body[1])
	hud.own_card(self)
	print("first10: the First steps card (7/7)")


## "What next?": WHAT_NEXT s of free driving with steps left and no other arrow up, the gold arrow
## to the nearest step left that has a place (a kebab stand, Pani Halina, Mirek's garage), for
## WHAT_NEXT_SHOW s. Not while the guide still has intros to make (they come sooner).
func _what_next_tick(f: Dictionary) -> void:
	_next_free = _next_free + TICK if f["free"] and not hint_shown() else 0.0
	if _next_free < WHAT_NEXT or wallet == null or car == null:
		return
	_next_free = 0.0
	if guide_on() and waiting_intro(f, fired) != "":
		return
	var left := FirstSteps.left(wallet.intro)
	if left.is_empty():
		return
	var best := Vector3.INF
	var word := ""
	var here := car.global_position
	for id in left:
		var at := _step_at(id)
		if at != Vector3.INF and (best == Vector3.INF or here.distance_to(at) < here.distance_to(best)):
			best = at
			word = {"kebab": "KEBAB", "race": "HALINA", "garage": "MIREK"}[id]
	if best == Vector3.INF:
		return
	_hint(best, word, WHAT_NEXT_SHOW)
	_what_next = true
	if hud != null:
		var next_words: Array = FirstSteps.words("what_next")
		hud.toast(next_words[0] % left.size(), next_words[1] % left.size())
	print("first10: what next: %s, %d steps left" % [word, left.size()])


## Where step `id` can be done, for "what next?" (INF: nowhere to point at).
func _step_at(id: String) -> Vector3:
	match id:
		"kebab":
			if jobs != null:
				var i: int = jobs.first_stand()
				if i >= 0:
					return jobs.stand_ring(i)
		"race":
			if rivals != null:
				var p: Vector2 = rivals.rival_at("Pani Halina")
				if p != Vector2.INF:
					return Vector3(p.x, map.ground_height(p.x, p.y) if map != null else 0.0, p.y)
		"garage":
			if garage != null and garage.is_shown() and garage.at != Vector3.INF:
				return garage.at
	return Vector3.INF


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
		"HALINA":
			return f["raced"]
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

## The replay's player: closes each result card after a moment, starts Halina's race from the choice card, answers
## the first call (later ones ring on), plays the boulevard tape, then judges the run and quits.
func _script(f: Dictionary) -> void:
	# A car that left the numbers (NaN) fails the replay at once with what was going on, not
	# a hang till the time limit.
	if car != null and not car.global_position.is_finite():
		push_error("first10: the car's position is not a number at %.1f s (last seen at %s; missions %d, police chasing %s, rivals %d, jobs %d, beats %s)"
				% [t, _last_pos, int(missions.state) if missions != null else -1,
				police.chasing() if police != null else false, int(rivals.state) if rivals != null else -1,
				int(jobs.stage) if jobs != null else -1, fired.keys()])
		get_tree().quit(1)
		return
	if car != null:
		_last_pos = car.global_position
	if hud != null and hud.finger_shown() and t > FINGER_IDLE + 3.0 \
			and not (rivals != null and rivals.has_method("first_nudging") and rivals.first_nudging()):
		hud.ghost_finger(false)
	var card: bool = (jobs != null and int(jobs.stage) == 3) or (rivals != null and int(rivals.state) == 5) \
			or (missions != null and missions.result_up())
	_card_t = _card_t + TICK if card else 0.0
	if _card_t > 3.0:
		_card_t = 0.0
		hud.card_pressed.emit(1)  # OK on a card of no one's own
		# The rescue's result card is its own (M1): its FREE ROAM (index 1), as the press above did
		# when missions.gd listened to every card.
		if missions != null and missions.result_up():
			missions.card_pressed(1)
		# A job's result card is its own (the activity kit): its second button (NASTĘPNE) where it
		# has one, else its first, as index 1 did when jobs.gd listened to every card.
		if jobs != null and int(jobs.stage) == 3 and not jobs.secondary():
			jobs.primary()
		# The race's result card is its own too: its OK, as the press above did when rivals.gd
		# listened to every card.
		if rivals != null and int(rivals.state) == 5 and rivals.has_method("card_pressed"):
			rivals.card_pressed(1 if rivals.next_offered() else 0)  # not the NEXT rival's call-out
	# First hour, step 3: RACE on the choice card after a moment (the race, then the police's first
	# contact, as before the card); the First steps card's button the same way.
	if _choice_up and t - _choice_t > 2.0:
		card_pressed(0)
	if _beta_up and t - _beta_t > 2.0:
		card_pressed(1)  # DRIVE ON: the map would pause the replay
	if _all_up:
		card_pressed(0)
	if rivals != null and rivals.first_waiting() and int(rivals.state) == 1:
		rivals.flash()
	if missions != null and missions.ringing() and not f["rescued"]:
		_call_t += TICK
		if _call_t > 2.0:
			_call_t = 0.0
			missions.answer()
	if fired.has("tape") and not f["tape"] and f["free"] and _cassette() >= 0 and missions != null \
			and missions.idle():
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
			and missions.idle():
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
