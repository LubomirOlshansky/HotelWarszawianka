extends Node
## The activity kit's base class (tech-debt TD-1; TD-2 the target and TD-16 the card's owner are
## parts of it).
##
## An activity is one thing the player does from a call (or a meeting) to a result card: a tour,
## a job, a race. Before the kit each of the 15 had its own copy of the same parts; here they are
## once:
##   - the phases: IDLE, RING (the phone rings; the player is still free), OFFER (the offer card
##     is up), RUN (under way: the subclass's own stages);
##   - the call's clock (the first call, the wait between calls, the hours) and the card's life;
##   - the cards: a card this activity shows is its own, and the HUD sends its buttons here only
##     (`hud.own_card`), so nothing asks "was that my card?"; it takes down only its own card, and
##     puts a card of the run back if something else took it down;
##   - the target: `set_target` places the beacon, and the arrow, the metres, the minimap and the
##     stop assist read it through the director; ending clears it;
##   - the ✕, the autopilot's taps and the log;
##   - the end: `_end` takes down the status line, the card and the target, whatever the subclass
##     was doing, and starts the wait for the next call.
## The director (activities.gd) knows which activity is on and who may start.
##
## A subclass gives the words (`_call_card`, `_offer_card`, `_refused`) and the play (`_begin`,
## `_run_tick`, `_card_pressed`), and uses `set_target`, `show_card`, `status`, `finish` and
## `drop`. One with its own clock for the call gives `_idle_tick` too. The first one is tour.gd;
## bar_crawl.gd is the first with a call clock, a ring and a result card of its own; shisha.gd the
## first with a stage somewhere else (the lounge) and a second ring (`set_mark`); ev_tow.gd the
## first that is flown (`flown`) and that starts without a call too (a stranger's car: `start`);
## rave.gd the first whose cards can run out unanswered (`_card_expired`) and whose arrow has its
## own words (`target_label`); street_meet.gd the first with a race in it (the place as the status
## line's `badge`) and with stages that are not the kit's at all (a raid, a drag on a tree of lights);
## boat_race.gd the first the player leaves the car for (the rings lead on the water, no arrow:
## `target_arrow`), with a card in a colour of its own (`show_card`'s `tint`) and with a result
## card the autopilot leaves by its second button (`_auto_button`); roundup_job.gd the first side
## job (`is_job`), with no call at all (a pull-in starts it), its cards at the bottom of the
## screen (`cards_low`) and a target that is not the kit's ring (the nearest Leżak); trend_job.gd
## the first with several kinds of order in one script: a request card that leaves the player
## free (`offer_busy`), a caller with a face of their own (`_call_card`'s "face") and cards of the
## run beside the road (`show_side_card`); rides.gd the first whose cards the drive goes on under
## (`cards_hold` off: a passenger's question on the way, a result card that goes once the car
## drives off; the ✕ still drops the run under them), with a card taken down without a press
## (`close_card`: the door reached before the answer) and with the autopilot's car driven by the
## activity itself (`drive_player`: the app's route on a ghost driver); jobs.gd (the kebab and the
## słoiki) the first with small pictures on its status line (`status`'s `icons`: the kebab's heat,
## the jars) and the one the M and K keys' path was built for (`primary`, `secondary`: the director
## asks each activity in turn).

const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

enum Phase { IDLE, RING, OFFER, RUN }

## The autopilot's taps: s after a call or an offer shows, and after a card of the run.
const AUTO_ANSWER := 1.5
const AUTO_CARD := 2.5
const OFFER_BUTTONS := ["JADĘ|ON MY WAY", "NIE DZIŚ|NOT TODAY"]

## Handed in by main.gd, as to every activity before the kit.
var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var map: Node3D
var car: Node3D
var log_on := false
var autopilot := false
## [position, speed km/h, flying, forward speed m/s].
var vehicle: Callable
var clock: Callable = func() -> float: return 12.0
## Nothing else is on (the director sets this when the activity joins it).
var free_now: Callable = func() -> bool: return true
## Another activity's request card that leaves the player free is up (`offer_busy` off: Podwózka's,
## the trend job's). The director sets this too; a rival's challenge waits for it (rivals.gd, PT-15).
var request_up: Callable = func() -> bool: return false
## Testing aid: calls at any hour.
var force_hours := false

## What the subclass sets before `setup`: its name in the log, its colours, the call's clock.
var tag := "activity"
var colour := Color.WHITE
var dark := Color.BLACK
## The call rings between these hours, after `first_call` s of play, then every `call_cool` s.
var hours := Vector2(0.0, 24.0)
var first_call := 600.0
var call_cool := 1800.0
## A call or an offer nobody answers goes after this long (s).
var card_life := 12.0
## The run gives up after this long (s) without finishing; 0 for no limit.
var play_limit := 0.0
## The target ring's radius (m): the stop assist's ring.
var arrive := StopAssist.RING
## The player is not in the car for this one (the EV tow is flown; the boat race sets it while the
## player is on the water): its arrow shows in the air too, and neither the stop assist nor the
## autopilot's car is sent to its target (main.gd).
var flown := false
## One of the side jobs (a kebab, a ride, the round-up): while the first minutes' guide runs its
## target is the main line's (the first job is the guide's goal: main.gd `_show_target`), and the
## other jobs are not told the player is away on a tour (main.gd's "touring").
var is_job := false
## The cards of the run sit at the bottom of the screen (hud.gd `show_card`'s `bottom`), as a
## job's cards do: the road ahead stays in view.
var cards_low := false
## The offer card holds the player, as a call's does once it is answered. False for a job whose
## request card (ACCEPT / SKIP as the player drives past) leaves them free: such a job is on only
## once it runs, so everything that asks "is a job on?" answers as before the card was taken.
var offer_busy := true
## A card of the run stops the run until it is pressed (or its life runs out). False for a job
## whose cards sit beside the road while the drive goes on: `_run_tick` keeps running under them
## and the ✕ still drops the run (a passenger's question, a result that goes once the car is off).
var cards_hold := true

var phase := Phase.IDLE
## Seconds in this phase, or since the run's last card went up.
var _t := 0.0
var _session := 0.0
var _run_t := 0.0
var _next_call := 0.0
var _beacon: Node3D
## A second ring beside the target (`set_mark`), made the first time one is asked for.
var _mark: Node3D
var _target := Vector3.INF
## A card of the run is up and waits for a press.
var _card_up := false
## That card as it was shown: [title, body, buttons, stacked, tint, beside the road] (`_put_card`).
var _card_args: Array = []
## That card closes by itself after this long (s) (`_card_expired`); 0: it waits for a press.
var _card_life := 0.0
var _status_up := false


func setup(world: Node3D) -> void:
	_next_call = first_call
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(colour, dark)
	_beacon.visible = false
	hud.abort_pressed.connect(abort)


## The player has taken it on (the offer card or anything after it; with `offer_busy` off only
## the run); a ringing phone is not busy.
func busy() -> bool:
	return phase == Phase.RUN or (phase == Phase.OFFER and offer_busy)


## Not ringing, not on (a questline may start it now: story_quests.gd).
func idle() -> bool:
	return phase == Phase.IDLE


# --- the target (TD-2) -------------------------------------------------------------------------

## Where the player is sent now: the beacon stands there, and main.gd reads it (through the
## director) for the arrow, the metres, the minimap's dot and the stop assist. `person`: someone
## waits in the ring. `ring_at` and `radius`: the ring's own place and size when it is not on the
## spot the player is sent to (a group on the pavement beside the kerb the car stops at).
func set_target(at: Vector2, person := false, ring_at := Vector3.INF, radius := 0.0) -> void:
	_target = Vector3(at.x, _ground(at), at.y)
	_beacon.visible = true
	_beacon.place(_target if ring_at == Vector3.INF else ring_at, radius if radius > 0.0 else arrive - 0.5, true, person)


## A second ring beside the target, in its own colour and with nobody in it: the door to walk to
## while the car stops at the kerb's ring. It goes when the target goes.
func set_mark(at: Vector3, radius: float, tint: Color) -> void:
	if _mark == null:
		_mark = Beacon.new()
		_beacon.get_parent().add_child(_mark)
		_mark.setup(tint, dark)
		_mark.waving = false
	_mark.recolour(tint)
	_mark.place(at, radius, true, false)


func clear_target() -> void:
	_target = Vector3.INF
	_beacon.visible = false
	if _mark != null:
		_mark.visible = false


func has_target() -> bool:
	return _target != Vector3.INF


func target_position() -> Vector3:
	return _target


func target_colour() -> Color:
	return colour


## The words on the arrow for a target `metres` away (main.gd `_show_target`). The rave's meeting
## point says "???": Mati knows only that much.
func target_label(metres: int) -> String:
	return "%d m" % metres


## The arrow shows for the target (main.gd `_show_target`). On the water the boat race's rings
## lead by themselves: the minimap keeps the dot, the arrow stays down.
func target_arrow() -> bool:
	return true


## What main.gd's camera calls a new target (`_new_target`): "race" gets no look at it (a race's
## finish: the race is on), anything else may get the camera's look while the car is slow.
func target_source() -> String:
	return "job"


## The target is the main line's now (main.gd `_put_target`: the minimap's star in place of a pin):
## a side job's while the first minutes' guide runs (`guide`: the first job is the guide's goal).
## A race says its own (rivals.gd: any race while the guide runs, and the ladder's next rung).
func main_target(guide: bool) -> bool:
	return is_job and guide


## The stop assist's spot (main.gd `_stop_assist`): the ring the car glides into.
func stop_spot() -> Vector3:
	return _target


func _ground(at: Vector2) -> float:
	return map.ground_height(at.x, at.y) if map != null else 0.0


# --- the frame ---------------------------------------------------------------------------------

func _process(dt: float) -> void:
	_t += dt
	_session += dt
	_tick(dt)
	match phase:
		Phase.IDLE:
			_idle_tick(dt)
		Phase.RING, Phase.OFFER:
			if _t > card_life:
				_hide_own_card()
				_refused(true)
				_end(call_cool * 0.5)
			elif autopilot and _t > AUTO_ANSWER:
				card_pressed(0)
		Phase.RUN:
			# A card that holds stops the run for this frame, pressed in it or not.
			var held := _card_up and cards_hold
			if _card_up:
				if not hud.card_is(self):
					# Something else took the card down or put its own up. Ours goes back once
					# the card is free: the run waits for a press, and nobody else gets it.
					if not hud.card_showing():
						_put_card()
						_log("card put back")
				elif autopilot and _t > AUTO_CARD and _auto_button() >= 0:
					card_pressed(_auto_button())
				elif _card_life > 0.0 and _t > _card_life:
					_card_up = false
					_hide_own_card()
					_card_expired()
			if not held and phase == Phase.RUN:
				_run_t += dt
				if play_limit > 0.0 and _run_t > play_limit:
					drop(false)
				else:
					_run_tick(dt)


## Twice a second while idle: is it time to phone?
func _idle_tick(dt: float) -> void:
	if _session < _next_call or int(_session * 2.0) == int((_session - dt) * 2.0):
		return
	if vehicle.is_valid() and bool(vehicle.call()[2]):
		return
	var h: float = clock.call()
	if not force_hours and (h < hours.x or h >= hours.y):
		return
	if not free_now.call():
		return
	ring()


# --- the call, the offer, the start --------------------------------------------------------------

## The phone rings. False unless idle.
func ring() -> bool:
	if phase != Phase.IDLE:
		return false
	phase = Phase.RING
	_t = 0.0
	var c := _call_card()
	var about: Array = c.get("about", ["", ""])
	hud.show_call(str(c.get("who", "")), str(about[0]), colour, str(about[1]), str(c.get("face", "")))
	_own_card()
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


func _offer() -> void:
	var c := _offer_card()
	if c.is_empty():
		_end(call_cool)  # nothing to offer after all (no place to meet): the next call later
		return
	phase = Phase.OFFER
	_t = 0.0
	var title: Array = c.get("title", ["", ""])
	var body: Array = c.get("body", ["", ""])
	hud.show_side_card(str(title[0]), str(body[0]), PackedStringArray(c.get("buttons", OFFER_BUTTONS)), colour,
			str(title[1]), str(body[1]), false, str(c.get("face", "")))
	_own_card()


## Met in person (the quest map's start, story_quests.gd): no call, it starts. False unless idle.
func meet() -> bool:
	if phase != Phase.IDLE:
		return false
	_log(_met_words())
	start()
	return true


## It starts (the offer taken, a meeting, a test flag).
func start() -> void:
	phase = Phase.RUN
	_t = 0.0
	_run_t = 0.0
	_card_up = false
	_begin()


# --- the cards (TD-16) ---------------------------------------------------------------------------

## A card of the run, in the middle of the screen (at its bottom with `cards_low`): this
## activity's own, so its buttons come to `_card_pressed` and to nobody else. The run's clock
## stands while it is up (unless `cards_hold` is off). With `life` the card closes by itself after
## that many seconds (`_card_expired`: as if its first button were pressed, a result card nobody
## has to tap). `stacked`: its buttons one under the other. `tint`: the card's colour when it is
## not the activity's (the boat race's ODPADASZ! is red).
func show_card(title: Array, body: Array, buttons: PackedStringArray, life := 0.0, stacked := false, tint := Color(0, 0, 0, 0)) -> void:
	_card_args = [title, body, buttons, stacked, tint, false]
	_card_life = life
	_card_up = true
	_t = 0.0
	_put_card()


## A card of the run beside the road, where an offer sits (hud.gd `show_side_card`): what a job
## says when it is done, with the street still in view. Otherwise as `show_card`.
func show_side_card(title: Array, body: Array, buttons: PackedStringArray, life := 0.0, tint := Color(0, 0, 0, 0), stacked := false) -> void:
	_card_args = [title, body, buttons, stacked, tint, true]
	_card_life = life
	_card_up = true
	_t = 0.0
	_put_card()


func _put_card() -> void:
	var title: Array = _card_args[0]
	var body: Array = _card_args[1]
	var tint: Color = _card_args[4]
	var accent := colour if tint.a == 0.0 else tint
	if bool(_card_args[5]):
		hud.show_side_card(str(title[0]), str(body[0]), _card_args[2], accent, str(title[1]), str(body[1]), _card_args[3])
	else:
		hud.show_card(str(title[0]), str(body[0]), _card_args[2], accent, cards_low, str(title[1]), str(body[1]), _card_args[3])
	_own_card()


func _own_card() -> void:
	hud.own_card(self)


## Takes the card down if it is still this activity's (never somebody else's).
func _hide_own_card() -> void:
	if hud.card_is(self):
		hud.hide_card()


## A card of the run comes down without a press: the run went on under it (`cards_hold` off) and
## got past what the card asked (the door reached before the passenger's question was answered).
func close_card() -> void:
	if _card_up:
		_card_up = false
		_hide_own_card()


## A button on a card this activity showed (the HUD calls this on the card's owner only).
func card_pressed(index: int) -> void:
	match phase:
		Phase.RING:
			_hide_own_card()
			if index == 0:
				_offer()
			else:
				_refused(false)
				_end(call_cool)
		Phase.OFFER:
			_hide_own_card()
			if index == 0:
				start()
			else:
				_refused(false)
				_end(call_cool)
		Phase.RUN:
			if _card_up:
				_card_up = false
				_hide_own_card()
				_card_pressed(index)


## The status line at the top while the run is on, in the activity's colour or in `tint`. `badge`:
## a short word beside the title (a race's place: "2/9", "1ST"). `icons`: the line's small pictures
## (hud.gd `show_status`: {"heat": 0..1} the kebab's steam, {"jars": [whole, all], "shake": 0..1}).
func status(title: String, count: String, distance: String, hint: Array, progress: float, tint := Color(0, 0, 0, 0), badge := "",
		icons := {}) -> void:
	_status_up = true
	hud.show_status(title, count, distance, str(hint[0]), progress, colour if tint.a == 0.0 else tint, badge, icons, str(hint[1]))


func hide_status() -> void:
	if _status_up:
		_status_up = false
		hud.hide_status()


# --- the end -------------------------------------------------------------------------------------

## The ✕ on the status line. Only a run that is under way drops, and not under a card of its own
## that holds it (`cards_hold`).
func abort() -> void:
	if phase == Phase.RUN and not (_card_up and cards_hold) and _can_abort():
		drop(true)


## The run is given up: by the player (the ✕) or by the clock.
func drop(by_player: bool) -> void:
	_end(call_cool)
	if by_player:
		var w := _quit_words()
		if not w.is_empty():
			hud.toast(str(w[0]), str(w[1]))
	_log("quit")


## The run is over and its last card closed.
func finish() -> void:
	_end(call_cool)


## Back to idle, the next call `cool` s away. Everything this activity put up comes down here,
## so a subclass can't leave a status line, a card or a beacon behind.
func _end(cool: float) -> void:
	hide_status()
	_card_up = false
	_hide_own_card()
	clear_target()
	phase = Phase.IDLE
	_t = 0.0
	_next_call = _session + cool
	_ended()


func _log(msg: String) -> void:
	if log_on:
		print("%s: %s" % [tag, msg])


# --- what a subclass gives -----------------------------------------------------------------------

## The call: {"who": the caller's name, "about": [Polish, English] what they are to the player,
## "face": whose portrait when it is not under the caller's name}.
func _call_card() -> Dictionary:
	return {}


## The offer: {"title": [pl, en], "body": [pl, en], "face": whose portrait, "buttons": optional}.
func _offer_card() -> Dictionary:
	return {}


## The call or the offer was turned down, by a button or (`timed_out`) by nobody answering;
## `phase` still says which. A subclass says its own words here; the card is already down.
func _refused(_timed_out: bool) -> void:
	pass


## The log's line when the player meets them in person.
func _met_words() -> String:
	return "met in person"


## The run begins: the first stage, the first target.
func _begin() -> void:
	pass


## Every frame of the run while no card of its own is up (under one too, with `cards_hold` off).
func _run_tick(_dt: float) -> void:
	pass


## Every frame, whatever the phase (a subclass's own small clocks).
func _tick(_dt: float) -> void:
	pass


## A button on a card of the run (`show_card`); the card is already down.
func _card_pressed(_index: int) -> void:
	pass


## A card of the run closed by itself (`show_card`'s `life` ran out); the card is already down.
## As a press of its first button, unless the subclass says otherwise (the rave's door: nobody
## answered the bouncer, which is no answer at all).
func _card_expired() -> void:
	_card_pressed(0)


## The button the autopilot taps on a card of the run, AUTO_CARD s after it went up: the first,
## unless the subclass says otherwise (the boat race's result card: its second, WYJDŹ, or a test
## run would race for ever). -1: none; the card waits for its life or a press.
func _auto_button() -> int:
	return 0


## The ✕ may drop the run now.
func _can_abort() -> bool:
	return true


## What the player reads when they drop it with the ✕: [Polish, English], or [] for nothing.
func _quit_words() -> Array:
	return []


## Why the player may not take the helicopter while this is on: [Polish, English], or [] when
## they may.
func grounded() -> Array:
	return []


## The M key (the pad's A): this activity takes it now (a card of its own is up: its first
## button, or what the subclass says the key does). False: not this one's, and the director asks
## the next (activities.gd `primary`; after the last, the rescue line's own card).
func primary() -> bool:
	return false


## The K key (the pad's X): the second button of a card of its own, as `primary`.
func secondary() -> bool:
	return false


## The activity drives the autopilot's car itself this frame (main.gd `_autopilot`, a test run):
## a ride follows the app's route on a ghost driver in traffic. False: main.gd slides the car
## straight to the target.
func drive_player() -> bool:
	return false


## Back to idle: a subclass clears its own run here.
func _ended() -> void:
	pass
