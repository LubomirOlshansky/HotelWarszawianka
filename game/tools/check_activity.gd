extends SceneTree
## The activity kit (tech-debt TD-1, with TD-2 the target and TD-16 the card's owner): the base
## class activity.gd, the director activities.gd, the HUD's card owner, and every tour's data file.
## Checks that:
## - the phases: a call (not busy yet), the offer, the run; a call or an offer nobody answers goes
##   and the next comes after half the wait; NOT TODAY waits the whole of it;
## - the call's clock: only after the first wait, inside the hours, on the ground, when free;
## - a card the activity shows is its own: its press comes to it and to nobody else, the run's
##   clock stands while it is up, a press on somebody else's card never reaches it, it never takes
##   down somebody else's card, and a card of the run that something took down comes back;
## - the target: the beacon stands there at the ground's height, and the end clears it;
## - the end takes down the status line, the card and the target whatever the subclass left up;
## - what the second activity (bar_crawl.gd) needed: a call or an offer turned down tells the
##   subclass how (`_refused`), an activity with nothing to offer after all goes back to idle, a
##   card with a life closes by itself as its first button would, the status line takes its own
##   colour (and, since street_meet.gd, a badge beside its title: a race's place), and the
##   target's ring can stand beside the spot with its own radius;
## - what the third (shisha.gd) needed: a second ring that is not the target (`set_mark`: a door
##   to see from down the street), gone with the target; and a card with its buttons stacked;
## - the ✕ drops a run (not a call, an offer or a run with its card up), with the quit words; the
##   play limit drops it without them;
## - the autopilot answers the call, takes the offer and presses the run's cards;
## - what a ride (rides.gd) needed: cards the drive goes on under (`cards_hold` off: the run ticks
##   in every frame, the press and the life still work, the ✕ drops the run under them), a holding
##   card that still stops the run in the frame it closes, a card taken down without a press
##   (`close_card`, never somebody else's), a side card with its buttons stacked, and the
##   activity that drives the autopilot's car itself (`drive_player`);
## - the director: at most one activity of the kit on at a time, `world_free` holds all of them
##   (but one that joined with its own test for the world, as the EV tow does: that one is asked
##   instead), and it names the one that is on, the one with a target and why the helicopter is
##   refused;
## - the real HUD (hud.gd): a real button's press goes to the card's owner only, and an unowned
##   card's press to every listener, as before the kit;
## - every data/*_tour.json: all the keys tour.gd reads, both languages, known shot kinds, only the
##   {keys} tour.gd fills in, its line group in data/dialogue.json with the tags the tour says; and
##   the tour runs from the call to the pay by itself.
##   godot --headless --path game --script res://tools/check_activity.gd

const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Tour := preload("res://scripts/tour.gd")
const Hud := preload("res://scripts/hud.gd")
const Fakes := preload("res://tools/fakes.gd")

const STEP := 0.1
## The {keys} tour.gd fills into each of a tour's words.
const WORD_KEYS := {
	"status_leg": ["name", "episode", "tape"],
	"status_shot": ["name", "episode", "tape", "shot"],
	"status_got": ["name", "episode", "tape"],
	"got": ["pay"],
	"bump": ["left", "max", "cost"],
	"bump_last": [],
	"end": ["body", "reply", "mark", "pay", "respect", "shots", "of"],
	"mark_clean": [],
	"mark_bumped": [],
	"quit": [],
	"no_fly": [],
}
const WORDS_NEEDED := ["status_shot", "status_got", "got", "bump", "end", "quit", "no_fly"]


## The smallest activity: it counts what the kit calls.
class Probe extends Activity:
	var begun := 0
	var ticks := 0
	var pressed: Array[int] = []
	var ended := 0
	var may_abort := true
	## Each refusal: [the phase it came in, by the clock].
	var refused: Array = []
	var no_offer := false
	## A card whose life runs out is counted here and not pressed (`_card_expired` of its own).
	var own_expiry := false
	var expired := 0
	## Its own words on the arrow ("" for the kit's metres).
	var label := ""
	## The button the autopilot taps on a card of the run (the kit's own: the first).
	var auto_btn := 0
	## The caller's portrait when it is not under their name ("" for the kit's own: the name).
	var call_face := ""
	## It drives the autopilot's car itself (the kit's own: main.gd slides it).
	var drives := false
	## A press of a card of the run ends the run (a result card that goes by itself).
	var ends_on_press := false

	func _call_card() -> Dictionary:
		var c := {"who": "Próba", "about": ["Ktoś od prób.", "Somebody who tests."]}
		if call_face != "":
			c["face"] = call_face
		return c

	func _offer_card() -> Dictionary:
		if no_offer:
			return {}
		return {"title": ["PRÓBA: „JEDZIESZ?”", "PROBE: \"COMING?\""], "body": ["Jedź.", "Drive."], "face": "Próba"}

	func _refused(timed_out: bool) -> void:
		refused.append([int(phase), timed_out])

	func _begin() -> void:
		begun += 1
		set_target(Vector2(100.0, 50.0), true)
		status("Próba", "1/1", "0 m", ["jedź", "drive"], 0.0)

	func _run_tick(_dt: float) -> void:
		ticks += 1

	func _card_pressed(index: int) -> void:
		pressed.append(index)
		if ends_on_press:
			finish()

	func _card_expired() -> void:
		if own_expiry:
			expired += 1
		else:
			super._card_expired()

	func target_label(metres: int) -> String:
		return label if label != "" else super.target_label(metres)

	func _auto_button() -> int:
		return auto_btn

	func _can_abort() -> bool:
		return may_abort

	func _quit_words() -> Array:
		return ["Koniec próby", "The probe is over"]

	func grounded() -> Array:
		return ["Próba nie lata", "The probe doesn't fly"] if busy() else []

	func drive_player() -> bool:
		return drives if drives else super.drive_player()

	func _ended() -> void:
		ended += 1


class SlopeMap extends Node3D:
	func ground_height(x: float, _z: float) -> float:
		return 2.0 + x * 0.01


var _fails: Array[String] = []
var _pos := Vector3.ZERO
var _kmh := 0.0
var _fly := false
var _hour := 12.0
var _world: Node3D
var _map: SlopeMap


func _initialize() -> void:
	_go.call_deferred()


## After the first frame, so the beacons are in the tree.
func _go() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_map = SlopeMap.new()
	_world.add_child(_map)
	_phases()
	_clock()
	_cards()
	_target_and_end()
	_refusals_and_looks()
	_abort_and_limit()
	_autopilot()
	_job_cards()
	_ride_cards()
	_director()
	_real_hud()
	_tour_data()
	if _fails.is_empty():
		print("check_activity: OK")
		quit(0)
	else:
		for f in _fails:
			print("check_activity: FAIL " + f)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _hud() -> Fakes.Hud:
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	return hud


func _probe(hud: CanvasLayer, tag := "probe") -> Probe:
	var a := Probe.new()
	a.tag = tag
	a.hud = hud
	a.map = _map
	a.first_call = 10.0
	a.call_cool = 100.0
	a.hours = Vector2(8.0, 20.0)
	a.vehicle = func() -> Array: return [_pos, _kmh, _fly, 0.0]
	a.clock = func() -> float: return _hour
	root.add_child(a)
	a.setup(_world)
	a.set_process(false)
	return a


func _run(a: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		a._process(STEP)
		t += STEP


# --- the base class --------------------------------------------------------------------------------

func _phases() -> void:
	var hud := _hud()
	var a := _probe(hud)
	_expect(a.idle() and not a.busy(), "a new activity is idle")
	_expect(a.ring() and a.phase == Activity.Phase.RING, "ring(): the phone rings")
	_expect(not a.busy() and not a.idle(), "a ringing phone is not busy, and not idle")
	_expect(hud.card.contains("PRÓBA") and hud.card_is(a), "the call is up and is the activity's own (%s)" % hud.card)
	_expect(not a.ring() and not a.meet(), "ring() and meet() say no while it rings")
	# Nobody answers: the call goes, the next after half the wait.
	_run(a, a.card_life + 0.3)
	_expect(a.idle() and hud.card == "", "a call nobody answers goes")
	var left: float = a._next_call - a._session
	_expect(left <= a.call_cool * 0.5 and left > a.call_cool * 0.5 - 1.0, "then half the wait (%.1f s)" % left)
	# Declined: the whole wait.
	a.ring()
	hud.press(1)
	_expect(a.idle() and hud.card == "" and is_equal_approx(a._next_call - a._session, a.call_cool), "ODRZUĆ: idle, the whole wait")
	# Answered: the offer; NOT TODAY.
	a.ring()
	hud.press(0)
	_expect(a.phase == Activity.Phase.OFFER and a.busy(), "ODBIERZ: the offer, and now it is busy")
	_expect(hud.card.contains("JEDZIESZ") and hud.buttons == 2 and hud.card_is(a), "the offer card is up and its own (%s)" % hud.card)
	hud.press(1)
	_expect(a.idle() and a.begun == 0, "NIE DZIŚ: idle, nothing begun")
	# Taken.
	a.ring()
	hud.press(0)
	hud.press(0)
	_expect(a.phase == Activity.Phase.RUN and a.begun == 1 and hud.card == "", "JADĘ: the run begins")
	_run(a, 1.0)
	_expect(a.ticks >= 9, "the run ticks (%d)" % a.ticks)
	a.finish()
	_expect(a.idle() and a.ended >= 1, "finish(): idle")
	# Met in person: no call.
	_expect(a.meet() and a.phase == Activity.Phase.RUN and a.begun == 2, "meet(): it starts with no call")
	a.finish()
	_expect(hud.broadcast == 0, "no press of the activity's cards went to every listener (%d)" % hud.broadcast)


func _clock() -> void:
	var hud := _hud()
	var a := _probe(hud)
	var free := [true]
	a.free_now = func() -> bool: return free[0]
	_hour = 12.0
	_fly = false
	_run(a, 9.0)
	_expect(a.idle(), "no call before the first wait")
	_hour = 3.0
	_run(a, 3.0)
	_expect(a.idle(), "no call outside its hours")
	_hour = 12.0
	free[0] = false
	_run(a, 2.0)
	_expect(a.idle(), "no call while something else is on")
	free[0] = true
	_fly = true
	_run(a, 2.0)
	_expect(a.idle(), "no call in the air")
	_fly = false
	_run(a, 1.0)
	_expect(a.phase == Activity.Phase.RING, "then the phone rings by itself")
	hud.press(1)
	_hour = 3.0
	a.force_hours = true
	_run(a, a.call_cool + 1.0)
	_expect(a.phase == Activity.Phase.RING, "force_hours: at any hour, after the wait")
	hud.press(1)
	_hour = 12.0


func _cards() -> void:
	var hud := _hud()
	var a := _probe(hud)
	a.meet()
	_run(a, 0.5)
	var before := a.ticks
	a.show_card(["KARTA", "CARD"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	_expect(hud.card == "KARTA" and hud.card_is(a), "a card of the run is up and its own")
	_run(a, 1.0)
	_expect(a.ticks == before and is_zero_approx(a._run_t - 0.5), "the run stands while its card is up (%d ticks more)" % (a.ticks - before))
	hud.press(1)
	_expect(a.pressed == [1] and hud.card == "", "its press comes to it, and the card goes")
	_run(a, 0.5)
	_expect(a.ticks > before, "then the run goes on")
	# Somebody else's card (nobody owns it): the activity never hears its press, never hides it.
	var heard: Array[int] = []
	hud.card_pressed.connect(func(i: int) -> void: heard.append(i))
	hud.show_card("CUDZA", "x", PackedStringArray(["OK"]), Color.WHITE)
	hud.press(0)
	_expect(a.pressed == [1] and heard == [0], "a press on somebody else's card is not the activity's (%s / %s)" % [a.pressed, heard])
	a.finish()
	_expect(hud.card == "CUDZA", "the end leaves somebody else's card up")
	hud.hide_card()
	# A call, then somebody else's card over it: the call's time runs out, their card stays.
	a.ring()
	hud.show_card("CUDZA 2", "x", PackedStringArray(["OK"]), Color.WHITE)
	_run(a, a.card_life + 0.3)
	_expect(a.idle() and hud.card == "CUDZA 2", "a call that timed out under somebody else's card leaves theirs up")
	hud.hide_card()
	# A card of the run taken down by something else comes back; under another card it waits.
	a.meet()
	a.show_card(["KARTA 2", "CARD 2"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	hud.hide_card()
	_run(a, 0.2)
	_expect(hud.card == "KARTA 2" and hud.card_is(a), "a card of the run that something took down comes back")
	hud.show_card("CUDZA 3", "x", PackedStringArray(["OK"]), Color.WHITE)
	_run(a, 0.5)
	_expect(hud.card == "CUDZA 3", "it waits under somebody else's card")
	hud.press(0)
	hud.hide_card()
	_run(a, 0.2)
	_expect(hud.card == "KARTA 2" and a.pressed == [1], "and is back when theirs goes, their press not taken as its own")
	hud.press(0)
	_expect(a.pressed == [1, 0], "then its own press")
	a.finish()


func _target_and_end() -> void:
	var hud := _hud()
	var a := _probe(hud)
	_expect(not a.has_target() and not a._beacon.visible, "no target while idle")
	a.meet()
	var want := Vector3(100.0, _map.ground_height(100.0, 50.0), 50.0)
	_expect(a.has_target() and a.target_position().is_equal_approx(want) and a.stop_spot().is_equal_approx(want),
			"set_target: the point at the ground's height (%s)" % a.target_position())
	_expect(a._beacon.visible and a._beacon.position.is_equal_approx(want), "the beacon stands on the target")
	_expect(a.target_colour() == a.colour, "the target has the activity's colour")
	_expect(hud.status == "jedź", "the status line is up")
	# The subclass leaves everything up; the end takes it all down.
	a.show_card(["KARTA", "CARD"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	a.finish()
	_expect(a.idle() and not a.has_target() and not a._beacon.visible and hud.status == "" and hud.card == "",
			"the end takes down the target, the beacon, the status line and the card")
	_expect(a.ended == 1, "and tells the subclass once")
	a.meet()
	a.clear_target()
	_expect(not a.has_target() and not a._beacon.visible, "clear_target: no target, no beacon")
	a.finish()


## What the second activity needed of the kit (bar_crawl.gd).
func _refusals_and_looks() -> void:
	var hud := _hud()
	var a := _probe(hud)
	# A call or an offer turned down: the subclass hears how, with the phase still set.
	a.ring()
	_run(a, a.card_life + 0.3)
	a.ring()
	hud.press(1)
	a.ring()
	hud.press(0)
	hud.press(1)
	a.ring()
	hud.press(0)
	_run(a, a.card_life + 0.3)
	_expect(a.refused == [[Activity.Phase.RING, true], [Activity.Phase.RING, false], [Activity.Phase.OFFER, false], [Activity.Phase.OFFER, true]],
			"_refused: a call missed, a call declined, an offer declined, an offer missed (%s)" % [a.refused])
	a.ring()
	hud.press(0)
	hud.press(0)
	_expect(a.refused.size() == 4 and a.busy(), "an offer taken is not a refusal")
	a.finish()
	# Nothing to offer after all: back to idle, the whole wait until the next call.
	a.no_offer = true
	var ended := a.ended
	a.ring()
	hud.press(0)
	_expect(a.idle() and hud.card == "" and a.ended == ended + 1 and a.begun == 1, "no offer to make: idle again, no card, nothing begun")
	_expect(is_equal_approx(a._next_call - a._session, a.call_cool), "and the next call the whole wait away")
	a.no_offer = false
	# A card with a life closes by itself, as its first button would; one without waits.
	a.meet()
	a.pressed.clear()
	a.show_card(["WYNIK", "RESULT"], ["tekst", "text"], PackedStringArray(["OK|OK", "INNE|OTHER"]), 2.0)
	_run(a, 1.8)
	_expect(hud.card == "WYNIK" and a.pressed.is_empty(), "a card with a life is up until its life is over")
	_run(a, 0.4)
	_expect(hud.card == "" and a.pressed == [0], "then it closes as its first button would (%s)" % [a.pressed])
	a.show_card(["PYTANIE", "QUESTION"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_run(a, 30.0)
	_expect(hud.card == "PYTANIE" and a.pressed == [0], "a card without a life waits for its press")
	hud.press(0)
	# A subclass with its own `_card_expired` (the rave's door): the card goes down, no button is
	# pressed, the subclass hears it once, and the run goes on.
	a.own_expiry = true
	a.pressed.clear()
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 2.0)
	_run(a, 1.8)
	_expect(hud.card == "BRAMKA" and a.expired == 0, "a card with a life and its own expiry is up until its life is over")
	var ticks := a.ticks
	_run(a, 0.4)
	_expect(hud.card == "" and a.pressed.is_empty() and a.expired == 1 and not a._card_up,
			"then it goes down with no press, and the subclass hears it once (pressed %s, expired %d)" % [a.pressed, a.expired])
	_expect(a.busy() and a.ticks > ticks, "and the run goes on")
	_run(a, 5.0)
	_expect(a.expired == 1, "once only")
	# A press before the life is over is a press, not an expiry.
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 2.0)
	_run(a, 1.0)
	hud.press(1)
	_run(a, 3.0)
	_expect(a.pressed == [1] and a.expired == 1, "a press before the life is over is a press (pressed %s, expired %d)" % [a.pressed, a.expired])
	# The autopilot's tap comes first: it presses the first button, whatever the expiry would do.
	a.autopilot = true
	a.pressed.clear()
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 60.0)
	_run(a, Activity.AUTO_CARD + 0.3)
	_expect(a.pressed == [0] and a.expired == 1, "the autopilot presses the first button of a card with a life (pressed %s)" % [a.pressed])
	# Or the button the subclass names (the boat race's result card: its second, WYJDŹ).
	a.auto_btn = 1
	a.pressed.clear()
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 60.0)
	_run(a, Activity.AUTO_CARD + 0.3)
	_expect(a.pressed == [1] and a.expired == 1 and hud.card == "", "the autopilot presses the button the subclass names (pressed %s)" % [a.pressed])
	# Or none: the card waits for its life.
	a.auto_btn = -1
	a.pressed.clear()
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), Activity.AUTO_CARD + 1.0)
	_run(a, Activity.AUTO_CARD + 0.5)
	_expect(a.pressed.is_empty() and a.expired == 1 and hud.card == "BRAMKA", "with no button named the autopilot leaves the card up (pressed %s)" % [a.pressed])
	_run(a, 1.0)
	_expect(a.pressed.is_empty() and a.expired == 2 and hud.card == "", "until its life is over (expired %d)" % a.expired)
	a.auto_btn = 0
	a.autopilot = false
	a.own_expiry = false
	# A card's colour: the activity's, or its own; a card put back keeps it.
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	_expect(hud.accent == a.colour, "a card of the run has the activity's colour")
	hud.press(0)
	a.show_card(["BRAMKA", "DOOR"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 0.0, false, Color.RED)
	_expect(hud.accent == Color.RED, "or the colour it is given")
	hud.hide_card()
	hud.accent = Color.WHITE
	_run(a, 0.1)
	_expect(hud.card == "BRAMKA" and hud.accent == Color.RED, "and a card put back keeps that colour")
	hud.press(0)
	a.pressed.clear()
	# The arrow shows unless the subclass says otherwise (the boat race's rings lead on the water).
	_expect(a.target_arrow(), "target_arrow: the arrow shows by default")
	# The arrow's words: the metres, or the subclass's own.
	_expect(a.target_label(37) == "37 m", "target_label: the metres (%s)" % a.target_label(37))
	a.label = "???"
	_expect(a.target_label(37) == "???", "target_label: the subclass's own words")
	a.label = ""
	# The status line: the activity's colour, or its own.
	a.status("Próba", "1/1", "5 m", ["jedź", "drive"], 0.5)
	_expect(hud.tint == a.colour, "the status line has the activity's colour")
	a.status("Próba", "1/1", "5 m", ["jedź", "drive"], 0.5, Color.RED)
	_expect(hud.tint == Color.RED, "or the colour it is given")
	# The badge beside the title (a race's place): none unless asked for.
	_expect(hud.badge == "", "the status line has no badge unless it is given one")
	a.status("Próba", "1/1", "5 m", ["jedź", "drive"], 0.5, Color(0, 0, 0, 0), "2/9")
	_expect(hud.badge == "2/9" and hud.tint == a.colour, "the status line's badge reaches the HUD, in the activity's colour still")
	a.status("Próba", "1/1", "5 m", ["jedź", "drive"], 0.5)
	_expect(hud.badge == "", "and the next line without one has none")
	# The ring beside the spot, with its own radius.
	a.set_target(Vector2(10.0, 20.0))
	_expect(is_equal_approx(a._beacon._ring_radius, a.arrive - 0.5), "the ring's radius is the stop ring's by default")
	a.set_target(Vector2(10.0, 20.0), false, Vector3(12.0, 5.0, 22.0), 9.0)
	_expect(a.target_position().is_equal_approx(Vector3(10.0, _map.ground_height(10.0, 20.0), 20.0)), "set_target with a ring of its own: the target is still the spot")
	_expect(a._beacon.position.is_equal_approx(Vector3(12.0, 5.0, 22.0)) and is_equal_approx(a._beacon._ring_radius, 9.0),
			"and the ring stands where it is told, as wide as told (%s, %.1f)" % [a._beacon.position, a._beacon._ring_radius])
	# A mark: a second ring that is not the target (nobody waves there), gone with the target.
	_expect(a._mark == null, "no mark until one is asked for")
	a.set_mark(Vector3(40.0, 2.0, 60.0), 3.0, Color.GOLD)
	_expect(a._mark != null and a._mark.visible and a._mark.position.is_equal_approx(Vector3(40.0, 2.0, 60.0))
			and is_equal_approx(a._mark._ring_radius, 3.0) and not a._mark.waving, "set_mark: a ring where it is told, as wide as told, nobody waving")
	_expect(a._mark._colour == Color.GOLD and a._mark != a._beacon, "in its own colour, and not the target's beacon")
	_expect(a.target_position().is_equal_approx(Vector3(10.0, _map.ground_height(10.0, 20.0), 20.0)) and a._beacon.visible,
			"the mark moves no target")
	var first_mark: Node3D = a._mark
	a.set_mark(Vector3(41.0, 2.0, 61.0), 3.0, Color.RED)
	_expect(a._mark == first_mark and a._mark._colour == Color.RED and a._mark.position.is_equal_approx(Vector3(41.0, 2.0, 61.0)),
			"a second mark is the same ring, moved and recoloured")
	a.clear_target()
	_expect(not a._mark.visible and not a._beacon.visible, "clear_target takes the mark down too")
	a.set_mark(Vector3(40.0, 2.0, 60.0), 3.0, Color.GOLD)
	# A card with its buttons one under the other.
	a.show_card(["WYNIK", "RESULT"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_expect(hud.card == "WYNIK" and not hud.stacked, "a run's card has its buttons side by side by default")
	hud.press(0)
	a.show_card(["WYNIK", "RESULT"], ["tekst", "text"], PackedStringArray(["OK|OK"]), 0.0, true)
	_expect(hud.card == "WYNIK" and hud.stacked, "or one under the other when asked")
	hud.hide_card()
	_run(a, 0.1)
	_expect(hud.card == "WYNIK" and hud.stacked, "and a stacked card put back is still stacked")
	hud.press(0)
	# A job's cards sit at the bottom of the screen (the round-up's); the others in the middle.
	_expect(not a.cards_low and not a.is_job and not hud.low, "a run's card is in the middle of the screen by default, and an activity is no job unless it says so")
	a.cards_low = true
	a.show_card(["NISKO", "LOW"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_expect(hud.card == "NISKO" and hud.low, "cards_low: the card sits at the bottom")
	hud.hide_card()
	_run(a, 0.1)
	_expect(hud.card == "NISKO" and hud.low, "and a low card put back is still low")
	hud.press(0)
	a.cards_low = false
	a.show_card(["WYNIK", "RESULT"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_expect(hud.card == "WYNIK" and not hud.low, "the next card without it is in the middle again")
	hud.press(0)
	a.finish()
	_expect(not a._mark.visible, "the end takes the mark down")


func _abort_and_limit() -> void:
	var hud := _hud()
	var a := _probe(hud)
	a.ring()
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.RING, "the ✕ does nothing to a call")
	hud.press(0)
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.OFFER, "nor to an offer")
	hud.press(0)
	a.show_card(["KARTA", "CARD"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.RUN, "nor to a run with its card up")
	hud.press(0)
	a.may_abort = false
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.RUN, "nor when the subclass says not now")
	a.may_abort = true
	hud.toasts.clear()
	hud.abort_pressed.emit()
	_expect(a.idle() and hud.toasts == ["Koniec próby"], "the ✕ drops the run, with the quit words (%s)" % [hud.toasts])
	_expect(is_equal_approx(a._next_call - a._session, a.call_cool), "then the whole wait")
	# The play limit: dropped without the words.
	a.play_limit = 5.0
	a.meet()
	hud.toasts.clear()
	_run(a, 4.5)
	_expect(a.phase == Activity.Phase.RUN, "inside the play limit: still on")
	_run(a, 1.0)
	_expect(a.idle() and hud.toasts.is_empty(), "past the play limit: dropped, no words")


func _autopilot() -> void:
	var hud := _hud()
	var a := _probe(hud)
	a.autopilot = true
	a.ring()
	_run(a, Activity.AUTO_ANSWER - 0.3)
	_expect(a.phase == Activity.Phase.RING, "the autopilot waits a moment")
	_run(a, 0.5)
	_expect(a.phase == Activity.Phase.OFFER, "then answers")
	_run(a, Activity.AUTO_ANSWER + 0.2)
	_expect(a.phase == Activity.Phase.RUN, "and takes the offer")
	a.show_card(["KARTA", "CARD"], ["tekst", "text"], PackedStringArray(["OK|OK", "NIE|NO"]))
	_run(a, Activity.AUTO_CARD + 0.2)
	_expect(a.pressed == [0] and hud.card == "", "and presses a card of the run")
	a.finish()


## What a job with several kinds of order needed of the kit (trend_job.gd): a request card that
## leaves the player free, a caller with a face of their own, cards of the run beside the road.
func _job_cards() -> void:
	var hud := _hud()
	var a := _probe(hud)
	# The caller's face.
	a.ring()
	_expect(hud.side and hud.face == "" and hud.body_en == "Somebody who tests.", "a call names no face by default (the HUD takes the caller's name): \"%s\"" % hud.face)
	hud.press(1)
	a.call_face = "Zenek"
	a.ring()
	_expect(hud.face == "Zenek" and hud.card.contains("PRÓBA"), "_call_card's \"face\": the call shows that portrait, under the caller's name still (%s, %s)" % [hud.face, hud.card])
	a.call_face = ""
	# The offer: busy by default; with `offer_busy` off only the run is.
	hud.press(0)
	_expect(a.phase == Activity.Phase.OFFER and a.busy() and a.offer_busy, "an offer holds the player by default")
	_expect(hud.side and hud.face == "Próba" and hud.card_en == "PROBE: \"COMING?\"" and hud.body_en == "Drive.", "the offer sits beside the road, with its face and both languages (%s)" % hud.face)
	hud.press(1)
	a.offer_busy = false
	a.ring()
	_expect(not a.busy() and not a.idle(), "offer_busy off: a ringing phone is as before, not busy and not idle")
	hud.press(0)
	_expect(a.phase == Activity.Phase.OFFER and not a.busy() and not a.idle(), "offer_busy off: the offer card is up and the player is still free")
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.OFFER, "the ✕ still does nothing to it")
	_run(a, a.card_life + 0.3)
	_expect(a.idle() and hud.card == "" and a.refused.back() == [int(Activity.Phase.OFFER), true], "and it still goes when nobody takes it (%s)" % [a.refused])
	a.ring()
	hud.press(0)
	hud.press(0)
	_expect(a.phase == Activity.Phase.RUN and a.busy(), "taken: the run is busy, as always")
	# A card of the run beside the road.
	a.show_side_card(["BOK", "SIDE"], ["tekst", "text"], PackedStringArray(["OK|OK", "NIE|NO"]))
	_expect(hud.card == "BOK" and hud.side and hud.card_is(a) and hud.accent == a.colour and not hud.low and not hud.stacked and hud.face == "",
			"show_side_card: the run's card beside the road, its own, in the activity's colour, no face")
	_expect(hud.card_en == "SIDE" and hud.body == "tekst" and hud.body_en == "text" and hud.buttons == 2, "with both languages and its buttons")
	var ticks := a.ticks
	_run(a, 1.0)
	_expect(a.ticks == ticks, "the run stands while it is up")
	hud.hide_card()
	_run(a, 0.1)
	_expect(hud.card == "BOK" and hud.side and hud.card_is(a), "a side card that something took down comes back beside the road")
	a.pressed.clear()
	hud.press(1)
	_expect(a.pressed == [1] and hud.card == "", "its press comes to the activity")
	a.show_side_card(["BOK 2", "SIDE 2"], ["tekst", "text"], PackedStringArray(["OK|OK"]), 3.0, Color.CRIMSON)
	_expect(hud.side and hud.accent == Color.CRIMSON, "with a tint: in that colour")
	_run(a, 2.5)
	_expect(hud.card == "BOK 2" and a.pressed == [1], "with a life: up until it runs out")
	_run(a, 1.0)
	_expect(hud.card == "" and a.pressed == [1, 0], "then closed as its first button (%s)" % [a.pressed])
	a.autopilot = true
	a.show_side_card(["BOK 3", "SIDE 3"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_run(a, Activity.AUTO_CARD + 0.2)
	_expect(hud.card == "" and a.pressed == [1, 0, 0], "the autopilot taps a side card as any card of the run")
	a.autopilot = false
	a.show_card(["ŚRODEK", "MIDDLE"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_expect(hud.card == "ŚRODEK" and not hud.side, "the next show_card is in the middle again")
	hud.hide_card()
	_run(a, 0.1)
	_expect(hud.card == "ŚRODEK" and not hud.side, "and comes back in the middle")
	a.finish()
	_expect(a.idle() and hud.card == "", "the end takes a card down wherever it sat")
	a.show_side_card(["BOK 4", "SIDE 4"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	a.finish()
	_expect(hud.card == "", "a side card too")


## What a ride needed of the kit (rides.gd): cards the drive goes on under, the ✕ under them, a
## card taken down without a press, a side card with its buttons stacked, and the autopilot's car
## driven by the activity itself.
func _ride_cards() -> void:
	var hud := _hud()
	var a := _probe(hud)
	var frames := func(n: int) -> void:
		for i in n:
			a._process(STEP)
	_expect(a.cards_hold, "a card of the run holds the run by default")
	# A holding card stops the run in the frame it closes too (its life: 0.25 s, the third frame).
	a.meet()
	a.show_card(["KRÓTKA", "SHORT"], ["tekst", "text"], PackedStringArray(["OK|OK"]), 0.25)
	var ticks := a.ticks
	frames.call(3)
	_expect(hud.card == "" and a.pressed == [0] and a.ticks == ticks, "a holding card whose life ran out: no run tick in that frame (%d)" % (a.ticks - ticks))
	frames.call(1)
	_expect(a.ticks == ticks + 1, "the run goes on the frame after")
	a.finish()
	# Cards the drive goes on under.
	a.cards_hold = false
	a.pressed.clear()
	a.meet()
	a.show_side_card(["PYTA", "ASKS"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 0.0, Color(0, 0, 0, 0), true)
	_expect(hud.card == "PYTA" and hud.side and hud.stacked and hud.card_is(a) and hud.accent == a.colour,
			"show_side_card's `stacked`: beside the road, its buttons one under the other, in the activity's colour")
	ticks = a.ticks
	var run_t := a._run_t
	frames.call(10)
	_expect(a.ticks == ticks + 10 and hud.card == "PYTA", "cards_hold off: the run goes on under its card, every frame (%d of 10)" % (a.ticks - ticks))
	_expect(is_equal_approx(a._run_t - run_t, 10 * STEP), "and the run's clock with it")
	hud.hide_card()
	frames.call(1)
	_expect(hud.card == "PYTA" and hud.stacked and hud.card_is(a), "a card something took down still comes back, stacked as it was")
	hud.press(1)
	_expect(a.pressed == [1] and hud.card == "" and a.phase == Activity.Phase.RUN, "its press still comes to the activity")
	a.show_side_card(["WYNIK", "RESULT"], ["tekst", "text"], PackedStringArray(), 0.25)
	_expect(hud.card == "WYNIK" and not hud.stacked and hud.buttons == 0, "the next side card: not stacked, no buttons")
	ticks = a.ticks
	frames.call(3)
	_expect(hud.card == "" and a.pressed == [1, 0], "its life still closes it as its first button (%s)" % [a.pressed])
	_expect(a.ticks == ticks + 3, "and the run ticked in the frame it closed too (%d of 3)" % (a.ticks - ticks))
	# The autopilot's tap.
	a.autopilot = true
	a.show_side_card(["PYTA 2", "ASKS 2"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	a.auto_btn = 1
	_run(a, Activity.AUTO_CARD + 0.2)
	_expect(hud.card == "" and a.pressed == [1, 0, 1], "the autopilot taps such a card as any other (%s)" % [a.pressed])
	a.auto_btn = 0
	a.autopilot = false
	# The ✕: under a card that does not hold, the run drops and the card goes.
	a.show_side_card(["PYTA 3", "ASKS 3"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	a.may_abort = false
	hud.abort_pressed.emit()
	_expect(a.phase == Activity.Phase.RUN and hud.card == "PYTA 3", "cards_hold off: the ✕ still asks the subclass")
	a.may_abort = true
	hud.toasts.clear()
	hud.abort_pressed.emit()
	_expect(a.idle() and hud.card == "" and hud.toasts == ["Koniec próby"], "cards_hold off: the ✕ drops the run under its card, and the card goes (%s)" % [hud.toasts])
	# A card taken down without a press.
	a.meet()
	a.pressed.clear()
	a.close_card()
	_expect(a.phase == Activity.Phase.RUN and a.pressed.is_empty(), "close_card with no card up: nothing")
	a.show_side_card(["PYTA 4", "ASKS 4"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]), 0.25)
	a.close_card()
	_expect(hud.card == "" and a.pressed.is_empty() and a.phase == Activity.Phase.RUN, "close_card: the card is down, nothing was pressed, the run is on")
	frames.call(4)
	_expect(hud.card == "" and a.pressed.is_empty(), "and it neither comes back nor runs out afterwards")
	a.show_side_card(["PYTA 5", "ASKS 5"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	hud.show_card("CUDZA", "x", PackedStringArray(["OK"]), Color.WHITE)
	a.close_card()
	_expect(hud.card == "CUDZA", "close_card never takes down somebody else's card")
	hud.hide_card()
	frames.call(2)
	_expect(hud.card == "", "and the closed card does not come back once theirs is gone")
	a.finish()
	# A card whose press ends the run (the ride's result card, which goes by itself): the run does
	# not tick once more after its own end.
	a.meet()
	a.pressed.clear()
	a.ends_on_press = true
	a.show_side_card(["KONIEC", "THE END"], ["tekst", "text"], PackedStringArray(), 0.25)
	ticks = a.ticks
	var ends := a.ended
	frames.call(3)
	_expect(a.idle() and a.ended == ends + 1 and a.pressed == [0] and hud.card == "", "cards_hold off: a card whose life ends the run ends it (%s)" % [a.pressed])
	_expect(a.ticks == ticks + 2, "and the run does not tick in the frame of its own end (%d of 2)" % (a.ticks - ticks))
	frames.call(2)
	_expect(a.ticks == ticks + 2, "nor in the frames after it")
	a.ends_on_press = false
	# A holding activity is as before: the ✕ does nothing under its card (`_abort_and_limit`).
	# The autopilot's car.
	_expect(not a.drive_player(), "drive_player: false by default (main.gd slides the autopilot's car to the target)")
	a.drives = true
	_expect(a.drive_player(), "a subclass that drives the car itself says so")


# --- the director ----------------------------------------------------------------------------------

func _director() -> void:
	var hud := _hud()
	var d := Activities.new()
	var a := _probe(hud, "first")
	var b := _probe(hud, "second")
	d.add(a)
	d.add(b)
	_expect(not d.busy() and d.current() == null and d.busy_tag() == "" and d.targeted() == null and d.grounded().is_empty(),
			"nothing on: no current activity, no tag, no target, the helicopter free")
	_expect(d.may_start(a) and d.may_start(b), "both may start")
	# `world_free` is main.gd's test for everything outside the kit: here, no card up.
	d.world_free = func() -> bool: return not hud.card_showing()
	a.ring()
	_expect(not d.busy() and not d.may_start(b), "the first rings: not busy yet, but its call holds the second (world_free)")
	hud.press(0)
	_expect(d.busy() and d.current() == a and d.busy_tag() == "first", "the first on its offer: it is the current one")
	hud.press(0)
	_expect(d.targeted() == a and d.grounded() == ["Próba nie lata", "The probe doesn't fly"], "the first runs: its target, its word on the helicopter")
	_expect(not d.may_start(b) and d.may_start(a), "the second may not start while the first is on")
	_hour = 12.0
	_fly = false
	_run(b, 30.0)
	_expect(b.idle(), "so the second does not ring by its clock")
	a.finish()
	b.finish()
	_expect(not d.busy(), "both idle again")
	_run(b, 101.0)
	_expect(b.phase == Activity.Phase.RING, "now the second rings")
	hud.press(1)
	d.world_free = func() -> bool: return false
	_expect(not d.may_start(a) and not d.may_start(b), "world_free false: nobody may start")
	_run(a, 300.0)
	_expect(a.idle(), "and nobody rings")
	# An activity that brings its own test for the world (the EV tow may start from the air,
	# which `world_free` refuses): the director asks that one in place of `world_free`, and the
	# kit's own rule (one at a time) still holds.
	var own := [true]
	var c := _probe(hud, "third")
	d.add(c, func() -> bool: return own[0])
	_expect(d.may_start(c) and not d.may_start(a), "an activity joined with its own world test is asked that, not world_free")
	own[0] = false
	_expect(not d.may_start(c), "its own test says no: it may not start")
	own[0] = true
	d.world_free = func() -> bool: return true
	a.ring()
	hud.press(0)
	_expect(d.current() == a and not d.may_start(c), "another activity of the kit is on: it may not start, whatever its own test says")
	a.finish()
	_expect(d.may_start(c) and not c.flown, "free again; an activity is not flown unless it says so")
	# A job whose request card leaves the player free (`offer_busy` off): the director counts it
	# as on only once it runs, so its card holds nobody by itself.
	a.offer_busy = false
	a.ring()
	hud.press(0)
	_expect(a.phase == Activity.Phase.OFFER and not d.busy() and d.current() == null and d.busy_tag() == "" and d.grounded().is_empty(),
			"offer_busy off: with the offer card up the director has nobody on, and the helicopter is free")
	_expect(d.may_start(c), "and another activity may start")
	hud.press(0)
	_expect(d.current() == a and d.busy_tag() == "first" and not d.may_start(c), "taken: now it is the current one")
	a.finish()
	a.offer_busy = true


# --- the real HUD (TD-16) --------------------------------------------------------------------------

func _tap(hud: CanvasLayer, index: int) -> bool:
	var holder: Node = hud._call_buttons if hud.call_showing() else hud._card_buttons
	var b := holder.find_child("button%d" % index, true, false) as Button
	if b == null:
		return false
	b.pressed.emit()
	return true


func _real_hud() -> void:
	var hud: CanvasLayer = Hud.new()
	root.add_child(hud)
	var a := _probe(hud, "real")
	var heard: Array[int] = []
	hud.card_pressed.connect(func(i: int) -> void: heard.append(i))
	# An unowned card, as every activity outside the kit shows them.
	hud.show_card("CUDZA", "x", PackedStringArray(["OK|OK", "NIE|NO"]), Color.WHITE)
	_expect(hud.card_showing() and not hud.card_is(a), "hud.gd: an unowned card is up and not the activity's")
	_expect(_tap(hud, 1) and heard == [1], "hud.gd: an unowned card's press goes to every listener (%s)" % [heard])
	hud.hide_card()
	_expect(not hud.card_showing(), "hud.gd: hide_card takes the card down")
	# The activity's call, offer and card: to it alone.
	a.ring()
	_expect(hud.call_showing() and hud.card_is(a), "hud.gd: the activity's call is its own")
	_expect(_tap(hud, 0) and a.phase == Activity.Phase.OFFER, "hud.gd: the green button answers the activity's call")
	_expect(hud.card_is(a) and not hud.call_showing(), "hud.gd: the offer is its own")
	_expect(_tap(hud, 0) and a.phase == Activity.Phase.RUN and not hud.card_showing(), "hud.gd: JADĘ starts it")
	a.show_card(["KARTA", "CARD"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	_expect(_tap(hud, 1) and a.pressed == [1], "hud.gd: the run's card press comes to the activity (%s)" % [a.pressed])
	_expect(heard == [1], "hud.gd: and to nobody else (%s)" % [heard])
	# Somebody else's card over the activity's: the press is theirs; the activity's comes back.
	a.show_card(["KARTA 2", "CARD 2"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	hud.show_card("CUDZA 2", "x", PackedStringArray(["OK|OK"]), Color.WHITE)
	_expect(not hud.card_is(a), "hud.gd: a new card is nobody's until its maker owns it")
	_expect(_tap(hud, 0) and heard == [1, 0] and a.pressed == [1], "hud.gd: its press is not the activity's")
	hud.hide_card()
	_run(a, 0.2)
	_expect(hud.card_is(a), "hud.gd: the activity's card is back when theirs is gone")
	_expect(_tap(hud, 0) and a.pressed == [1, 0], "hud.gd: and takes its press")
	# A card of the run beside the road, and a call with a face that is not the caller's name.
	a.show_side_card(["BOK", "SIDE"], ["tekst", "text"], PackedStringArray(["TAK|YES", "NIE|NO"]))
	_expect(hud.card_is(a) and hud._card_side and not hud.call_showing(), "hud.gd: show_side_card puts the run's card beside the road, its own")
	_expect(_tap(hud, 1) and a.pressed == [1, 0, 1] and not hud.card_showing(), "hud.gd: and its press comes to the activity (%s)" % [a.pressed])
	a.show_card(["ŚRODEK", "MIDDLE"], ["tekst", "text"], PackedStringArray(["OK|OK"]))
	_expect(hud.card_is(a) and not hud._card_side, "hud.gd: the next show_card is in the middle again")
	a.finish()
	_expect(not hud.card_showing(), "hud.gd: nothing left up")
	a.ring()
	_expect(hud.call_showing() and hud._card_face_letter == "P", "hud.gd: a call's face is the caller's by default (%s)" % hud._card_face_letter)
	_tap(hud, 1)
	a.call_face = "Zenek"
	a.ring()
	_expect(hud.call_showing() and hud.card_is(a) and hud._card_face_letter == "Z", "hud.gd: _call_card's \"face\" is the portrait the call shows (%s)" % hud._card_face_letter)
	_tap(hud, 1)
	_expect(a.idle() and not hud.card_showing(), "hud.gd: declined, nothing left up")


# --- the tours' data -------------------------------------------------------------------------------

func _pair(v: Variant) -> bool:
	return v is Array and v.size() == 2 and v[0] is String and v[1] is String and v[0] != "" and v[1] != ""


func _keys_in(text: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("\\{([a-z_]+)\\}")
	for m in re.search_all(text):
		out.append(m.get_string(1))
	return out


func _tour_data() -> void:
	var ids: Array[String] = []
	for f in DirAccess.get_files_at("res://data"):
		if f.ends_with("_tour.json"):
			ids.append(f.trim_suffix("_tour.json"))
	_expect(ids.has("kino") and ids.has("dekalog"), "data/: the kino and dekalog tours are there (%s)" % [ids])
	var lines: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	for id in ids:
		var d := Tour.load_data(id)
		if d.is_empty():
			_expect(false, "%s_tour.json does not load" % id)
			continue
		var before := _fails.size()
		_tour_shape(id, d, lines)
		if _fails.size() == before:
			_tour_plays(id, d)


## The keys tour.gd reads, in both languages, and nothing it would print as "{key}".
func _tour_shape(id: String, d: Dictionary, lines: Dictionary) -> void:
	var w := "%s_tour.json: " % id
	_expect(str(d.get("id", "")) == id, w + "`id` is the file's name")
	for k: String in ["pay_kind", "speaker", "lines"]:
		_expect(str(d.get(k, "")) != "", w + "`%s` is missing" % k)
	_expect(_pair(d.get("name")), w + "`name` needs Polish and English")
	for k: String in ["colour", "dark"]:
		_expect(Color.html_is_valid(str(d.get(k, ""))), w + "`%s` is not a colour" % k)
	var h: Array = d.get("hours", [])
	_expect(h.size() == 2 and float(h[0]) >= 0.0 and float(h[0]) < float(h[1]) and float(h[1]) <= 24.0, w + "`hours` are not [from, to] in a day")
	for k: String in ["first_call", "call_cool", "play_limit"]:
		_expect(float(d.get(k, 0.0)) > 0.0, w + "`%s` must be more than 0" % k)
	var b: Array = d.get("banter", [])
	_expect(b.size() == 2 and float(b[0]) > 0.0 and float(b[0]) <= float(b[1]), w + "`banter` is not [min, max] seconds")
	_expect(int(d.get("bump_max", 0)) >= 1, w + "`bump_max` must be 1 or more")
	_expect(str(d.get("shots_of", "stops")) in ["stops", "shots"], w + "`shots_of` is \"stops\" or \"shots\"")
	var pay: Dictionary = d.get("pay", {})
	for k: String in ["base", "bump", "shot", "respect", "respect_bump"]:
		_expect(pay.has(k) and int(pay[k]) >= 0, w + "`pay.%s` is missing" % k)
	var c: Dictionary = d.get("call", {})
	_expect(str(c.get("who", "")) != "" and _pair(c.get("about")), w + "`call` needs who and about in two languages")
	var o: Dictionary = d.get("offer", {})
	_expect(_pair(o.get("title")) and _pair(o.get("body")) and str(o.get("face", "")) != "", w + "`offer` needs title, body and face")
	var p: Dictionary = d.get("pickup", {})
	_expect(p.get("at") is Array and p["at"].size() == 2 and str(p.get("name", "")) != "", w + "`pickup` needs at [x, z] and a name")
	for k: String in ["toast", "in", "status"]:
		_expect(_pair(p.get(k)), w + "`pickup.%s` needs Polish and English" % k)
	# Shots.
	var shots: Dictionary = d.get("shots", {})
	for sid: String in shots:
		var s: Dictionary = shots[sid]
		_expect(str(s.get("kind", "")) in Tour.KINDS, w + "shot %s: unknown kind `%s`" % [sid, s.get("kind", "")])
		_expect(float(s.get("need", 0.0)) > 0.0 and _pair(s.get("hint")), w + "shot %s needs `need` and a hint in two languages" % sid)
		if str(s.get("kind", "")) == "tunnel":
			var t: Dictionary = d.get("tunnel", {})
			_expect(t.get("line") is Array and t["line"].size() == 2 and float(t.get("width", 0.0)) > 0.0 and t.has("deep"),
					w + "a tunnel shot needs `tunnel` {line, width, deep}")
	for k: String in Tour.FILLING:
		_expect(k in Tour.KINDS, "tour.gd: FILLING's %s is not in KINDS" % k)
	# Stops.
	var stops: Array = d.get("stops", [])
	_expect(stops.size() >= 2, w + "a tour needs two stops or more")
	var seen := {}
	var bare_leg := false
	for s: Dictionary in stops:
		var sid := str(s.get("id", ""))
		_expect(sid != "" and not seen.has(sid), w + "stop `%s`: the id is missing or used twice" % sid)
		seen[sid] = true
		_expect(s.get("at") is Array and s["at"].size() == 2 and str(s.get("name", "")) != "", w + "stop %s needs at [x, z] and a name" % sid)
		_expect(_pair(s.get("title")) and _pair(s.get("body")), w + "stop %s needs a title and a body in two languages" % sid)
		var shot := str(s.get("shot", ""))
		_expect(shot == "" or shots.has(shot), w + "stop %s: unknown shot `%s`" % [sid, shot])
		bare_leg = bare_leg or shot == ""
	# The question at the last stop.
	if d.has("answers"):
		var answers: Array = d["answers"]
		_expect(answers.size() >= 2 and answers.size() <= 3, w + "`answers`: two or three")
		for a: Dictionary in answers:
			_expect(str(a.get("button", "")).contains("|") and _pair(a.get("reply")), w + "an answer needs a \"PL|EN\" button and a reply in two languages")
	# Words.
	var words: Dictionary = d.get("words", {})
	var needed: Array = WORDS_NEEDED.duplicate()
	if bare_leg:
		needed.append("status_leg")
	for k: String in needed:
		_expect(_pair(words.get(k)), w + "`words.%s` needs Polish and English" % k)
	for k: String in ["drive_on", "end_button"]:
		_expect(str(words.get(k, "")).contains("|"), w + "`words.%s` is a \"PL|EN\" button" % k)
	_expect(words.has("bump_last") == words.has("bump_last_tag"), w + "`words.bump_last` and `bump_last_tag` come together")
	for k: String in words:
		if not WORD_KEYS.has(k) or not words[k] is Array:
			continue
		for text: String in words[k]:
			for key in _keys_in(text):
				_expect(key in WORD_KEYS[k], w + "`words.%s` has {%s}, which the tour does not fill in" % [k, key])
	for key in _keys_in(str(p.get("status", ["", ""])[0]) + str(p.get("status", ["", ""])[1])):
		_expect(key == "name", w + "`pickup.status` has {%s}, which the tour does not fill in" % key)
	if words.has("end") and words["end"] is Array:
		var end := str(words["end"][0]) + str(words["end"][1])
		_expect(not end.contains("{reply}") or d.has("answers"), w + "`words.end` has {reply} but the tour asks no question")
		_expect(not end.contains("{mark}") or (words.has("mark_clean") and words.has("mark_bumped")), w + "`words.end` has {mark} but no mark_clean / mark_bumped")
	# The lines the guest says.
	var group := str(d.get("lines", ""))
	var general := 0
	var tags := {}
	for l: Array in lines.get(group, []):
		if l.size() > 2 and l[2] is Dictionary:
			tags[str(l[2].get("only", ""))] = true
		else:
			general += 1
	_expect(general >= 1, w + "no general lines in dialogue.json `%s` (the banter)" % group)
	var want: Array[String] = ["hello", "bump"]
	if words.has("bump_last_tag"):
		want.append(str(words["bump_last_tag"]))
	for sid: String in shots:
		want.append("shot_" + sid)
	for t in want:
		_expect(tags.has(t), w + "dialogue.json `%s` has no line for `%s`" % [group, t])


## From the call to the pay with nobody at the wheel: the autopilot presses, the car is put on
## each target. A new tour's data file gets this run without a check of its own.
func _tour_plays(id: String, d: Dictionary) -> void:
	var w := "%s_tour.json: " % id
	var hud := _hud()
	var dlg := Fakes.Dialogue.new()
	var wal := Fakes.Wallet.new()
	var car := Fakes.Car.new()
	for n: Node in [dlg, wal, car]:
		root.add_child(n)
	var t := Tour.new()
	t.configure(d)
	t.hud = hud
	t.dialogue = dlg
	t.wallet = wal
	t.car = car
	t.map = _map
	t.autopilot = true
	t.vehicle = func() -> Array: return [_pos, _kmh, false, 0.0]
	root.add_child(t)
	t.setup(_world)
	t.set_process(false)
	_expect(t.tag == id and t.title() == d["name"], w + "the tour takes its tag and name from the data")
	_expect(t.ring() and hud.card.contains(str(d["call"]["who"]).to_upper()), w + "the guest phones (%s)" % hud.card)
	var first := hud.shown
	var not_own := 0
	var steps := 0
	while steps < 6000 and not (t.idle() and not t.last_result().is_empty()):
		if t.has_target():
			_pos = t.target_position()
			_kmh = 0.0
		if hud.card != "" and not hud.card_is(t):
			not_own += 1
		t._process(STEP)
		steps += 1
	var cards := hud.shown - first + 1
	_expect(not_own == 0, w + "a card on the way was not the tour's own")
	var stops: Array = d["stops"]
	_expect(t.idle() and not t.last_result().is_empty(), w + "the tour does not reach its end by itself (stage %d, stop %d)" % [t.stage, t.stop])
	if t.last_result().is_empty():
		return
	# The call, the offer, a card at each stop, and the end card after a question.
	var want_cards := 2 + stops.size() + (1 if d.has("answers") else 0)
	_expect(cards == want_cards, w + "%d cards on the way (want %d)" % [cards, want_cards])
	_expect(wal.kinds == [str(d["pay_kind"])], w + "paid once, as `%s` (%s)" % [d["pay_kind"], wal.kinds])
	var res: Dictionary = t.last_result()
	var pay: Dictionary = d["pay"]
	_expect(int(res["bumps"]) == 0 and wal.money == int(pay["base"]) + int(pay["shot"]) * int(res["shots"]),
			w + "a tour with no hit pays the base and each shot (%d zł, %d shots)" % [wal.money, res["shots"]])
	_expect(wal.respect == int(pay["respect"]), w + "and the whole respect (%d)" % wal.respect)
	_expect(dlg.said.has("%s:hello" % d["lines"]), w + "the guest says hello getting in")
	_expect(not t.has_target() and hud.status == "" and hud.card == "", w + "nothing left up at the end")
	_expect(hud.broadcast == 0, w + "no press went to every listener")
