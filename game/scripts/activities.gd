extends RefCounted
## The activity director (tech-debt TD-1): the one place that knows which activity is on.
##
## Before the kit main.gd named every activity in every question: "is the player busy?" had
## three lists and eight variants, and the arrow, the stop assist and the helicopter's refusal
## each walked the activities by name. An activity of the kit (activity.gd) joins here once with
## `add`, and main.gd asks the director:
##   - `busy()`, `current()`, `busy_tag()`: is one on, and which;
##   - `may_start(a)`: nothing of the kit is on, and `world_free` (main.gd's test for everything
##     that is not in the kit yet: a race, a job, a card, the air) agrees, or the activity's own
##     test given to `add` (the EV tow's: it may start from the air). It is each joined
##     activity's `free_now`;
##   - `targeted()`: the one that sends the player somewhere now (the arrow, the stop assist);
##   - `grounded()`: why the helicopter is refused;
##   - `job_on()`: one of the side jobs is on (`is_job`: a kebab, the słoiki, a ride, the round-up,
##     a trend job), which the rest of the game asked jobs.gd by name before it joined;
##   - `primary()`, `secondary()`: the M and K keys (the pad's A and X) go to the activity whose
##     card takes them;
##   - `abort()`: the ✕ (hud.abort_pressed) goes to one activity, the first that takes it
##     (`takes_abort`), where every joined activity heard it and dropped its run before (TD-16's rule
##     for the cards, for the ✕; 2026-11-15: one ✕ ended a tour's run and a rescue at once);
##   - `offering()`: a request card that leaves the player free is up (Łuber's, the trend
##     job's), each joined activity's `request_up`;
##   - `holds_calls(a)`: another activity's run holds the rescue calls (its `rescue_calls`), or one of
##     main.gd's own holds does (`hold_calls`, `release_calls`: the phone bench, a boat ride, with the
##     same values), each joined activity's `calls_held`; `call_on_pill(a)`: another activity's call
##     waits on the context button (the rescue line's WEZWANIE), each joined activity's
##     `call_waiting`; `rescue_busy(a)`: the rescue line's card or run is up (the ride app, the
##     deliveries and the trend job ask it, as they asked missions.gd by name before);
##   - `my_turn(a)`: TD-3's variety (F 2026-11-15): the activity whose phone rang last (`on_ring`) does
##     not ring again by its own clock while another's call is due and waits (`call_waits`), each joined
##     activity's `my_turn`;
##   - and it passes on each run's start and end (`on_start`, `on_end`) to every other activity
##     (`other_started`, `other_ended`): the rescue line puts off its call for a job or a race
##     (`calls_put_off`), as each of them did by name before the rescue line joined (TD-1's last
##     activity); a run's end starts the message director's quiet time (`finished`, TD-3).
## At most one activity of the kit is on at a time: the rescue line's card counts as its run does
## (TD-3, F 2026-11-15).
##
## Not here yet (they come as more activities join, see tech-debt TD-1): a priority table for
## who may interrupt whom, and the context `messages.gd` asks for.

const Activity := preload("res://scripts/activity.gd")

## A run of the kit started (play_stats.gd counts it).
signal run_started(a: Activity)
## A run of the kit ended: `how` is the activity's `end_how`, `seconds` its time in the run.
signal run_ended(a: Activity, how: String, seconds: float)

## main.gd's test for everything outside the kit; true when nothing there holds the player.
var world_free: Callable = func() -> bool: return true
## main.gd's: a run of an activity has ended (the message director's `finished`: the quiet time after a
## finish, TD-3).
var finished: Callable
## main.gd's: an activity's phone rang (`on_ring`), with the activity (the first hour's guide counts
## the new friends, first10.gd `friend_rang`).
var rang: Callable
var list: Array[Activity] = []
## An activity's own test in place of `world_free` (`add`'s second argument), by the activity.
var _own_world := {}
## The activity whose phone rang last (`on_ring`), or null (`my_turn`).
var _last: Activity = null
## main.gd's own holds of the rescue calls, by name ("bench": the phone bench's minute; "boat": a ride on
## the water): what each does to them, an `Activity.RescueCalls` as an activity's run has.
var _holds := {}


## An activity joins: from now on it asks the director whether it may phone. `world`: its own
## test for everything outside the kit, when `world_free` does not fit it (the EV tow starts from
## the air, which `world_free` refuses).
func add(a: Activity, world := Callable()) -> void:
	list.append(a)
	if world.is_valid():
		_own_world[a] = world
	a.free_now = may_start.bind(a)
	a.request_up = offering.bind(a)
	a.calls_held = holds_calls.bind(a)
	a.call_waiting = call_on_pill.bind(a)
	a.rescue_busy = rescue_busy.bind(a)
	a.my_turn = my_turn.bind(a)
	a.on_start = _started.bind(a)
	a.on_end = _ended.bind(a)
	a.on_ring = _rang.bind(a)
	_hear_abort(a)


## The activity that is on, or null.
func current() -> Activity:
	for a in list:
		if a.busy():
			return a
	return null


func busy() -> bool:
	return current() != null


## The log name of the one that is on ("" when none): main.gd's `_free_block` reason.
func busy_tag() -> String:
	var a := current()
	return "" if a == null else a.tag


## `a` may phone or start now: no activity of the kit is on, and nothing outside it either. The rescue
## line's card counts as its run does (TD-3, F 2026-11-15: a call's card on screen holds the other
## offers; before, only a rescue that sent the player somewhere counted here, and its cards held the
## others through their own tests).
func may_start(a: Activity) -> bool:
	var on := current()
	if on != null and on != a:
		return false
	var world: Callable = _own_world.get(a, world_free)
	return bool(world.call())


## `a` may ring now by its own clock (TD-3's variety, F 2026-11-15): unless its phone rang last and
## another activity's call is due and waits (`call_waits`: held by the call gate or by this rule), which
## then goes first. A call the player asks for does not ask.
func my_turn(a: Activity) -> bool:
	if a != _last:
		return true
	for o in list:
		if o != a and o.call_waits():
			return false
	return true


## The activity that sends the player somewhere now, or null. `flying`: only one whose target shows
## in the air (`flown`: the EV tow, the rescue line), as main.gd's arrow asks.
func targeted(flying := false) -> Activity:
	for a in list:
		if a.has_target() and (not flying or a.flown):
			return a
	return null


## Why the helicopter is refused now: [Polish, English] from the activity that is on, or [].
func grounded() -> Array:
	var a := current()
	return [] if a == null else a.grounded()


## One of the side jobs is on (an activity with `is_job`: from its order or request taken to the
## close of its result card). A job's request card that leaves the player free is not "on".
func job_on() -> bool:
	for a in list:
		if a.is_job and a.busy():
			return true
	return false


## A request card that leaves the player free is up: an activity of the kit other than `a` is in
## its offer with `offer_busy` off (Łuber's, the trend job's request beside the road). Each
## joined activity's `request_up`: a rival's challenge waits for it (rivals.gd, PT-15), which
## asked Łuber by name before it joined.
func offering(a: Activity = null) -> bool:
	for o in list:
		if o != a and not o.offer_busy and o.phase == Activity.Phase.OFFER:
			return true
	return false


## The M key (the pad's A): the first activity, in the order they joined, that takes it (a card
## of its own is up). False when none does (main.gd goes on to the rescue line's card).
func primary() -> bool:
	for a in list:
		if a.primary():
			return true
	return false


## The K key (the pad's X), as `primary`.
func secondary() -> bool:
	for a in list:
		if a.secondary():
			return true
	return false


## The ✕ (hud.abort_pressed): to the first activity, in the order they joined, that takes it now
## (`takes_abort`: a run under way, not under a card that holds it), and to nobody after it. False when
## none does. With one thing up this is that one's ✕, as before.
func abort() -> bool:
	for a in list:
		if a.takes_abort():
			a.abort()
			return true
	return false


## `a` hears the ✕ through the director from now on: its own line to the signal (activity.gd `setup`,
## missions.gd `setup`) goes, and the director's is made once per HUD.
func _hear_abort(a: Activity) -> void:
	if a.hud == null:
		return
	var sig: Signal = a.hud.abort_pressed
	if sig.is_connected(a.abort):
		sig.disconnect(a.abort)
	if not sig.is_connected(abort):
		sig.connect(abort)


## The rescue calls wait for a run (`a` aside): an activity whose `rescue_calls` holds or restarts them is
## in its run, or one of main.gd's own holds is on (`hold_calls`).
func holds_calls(a: Activity = null) -> bool:
	if not _holds.is_empty():
		return true
	for o in list:
		if o != a and o.rescue_calls != Activity.RescueCalls.GO_ON and o.phase == Activity.Phase.RUN:
			return true
	return false


## One of main.gd's own holds of the rescue calls begins (`key`: "bench", "boat"), with what it does to
## them (`how`: HOLD stands still; RESTART puts off a ringing call now and counts from NEXT_CALL again at
## its end), as an activity's run with that `rescue_calls` does (TD-3, F 2026-11-15: where main.gd wrote
## missions.gd's `paused` and called its `close` before). A hold already on stays as it is.
func hold_calls(key: String, how: Activity.RescueCalls) -> void:
	if _holds.has(key):
		return
	_holds[key] = how
	if how == Activity.RescueCalls.RESTART:
		_put_off()


## ...and ends.
func release_calls(key: String) -> void:
	if not _holds.has(key):
		return
	var how: Activity.RescueCalls = _holds[key]
	_holds.erase(key)
	if how == Activity.RescueCalls.RESTART:
		_put_off()


## A call waits on the context button (`a` aside): an activity with `pill_call` rings.
func call_on_pill(a: Activity = null) -> bool:
	for o in list:
		if o != a and o.pill_call and o.phase == Activity.Phase.RING:
			return true
	return false


## A call has come to the context button and the player has had PILL_HOLDS s to take it or not: for that
## long it keeps the other friends' phones quiet (main.gd `_free_block`), no longer. F 2026-11-24: it
## waits until it is pressed, so one nobody pressed kept every friend from calling for the whole drive
## ("10 minutes and no calls"). The friend who rings then puts it off (`rang`, main.gd).
const PILL_HOLDS := 45.0

func call_fresh() -> bool:
	for o in list:
		if o.pill_call and o.phase == Activity.Phase.RING and o._t < PILL_HOLDS:
			return true
	return false


## The rescue line's card or run is up (`a` aside): an activity with `pill_call` is busy.
func rescue_busy(a: Activity = null) -> bool:
	for o in list:
		if o != a and o.pill_call and o.busy():
			return true
	return false


## `a`'s phone rang (a call that came by itself or one the player asked for): it rang last.
func _rang(a: Activity) -> void:
	_last = a
	if not a.pill_call:
		print("friend call: %s rings" % a.tag)  # the hands-off soak counts them (tools/verify.sh `calls-soak`)
	if rang.is_valid():
		rang.call(a)


## `a`'s run has started: every other activity hears it, and a run that restarts the rescue calls puts
## them off.
func _started(a: Activity) -> void:
	run_started.emit(a)
	for o in list:
		if o != a:
			o.other_started(a)
			if a.rescue_calls == Activity.RescueCalls.RESTART:
				o.calls_put_off()


## `a`'s run has ended: every other activity hears it (and the rescue calls count from NEXT_CALL again
## after a run that restarts them), and the quiet time after a finish starts (`finished`).
func _ended(a: Activity) -> void:
	run_ended.emit(a, a.end_how, a._run_t)
	for o in list:
		if o != a:
			o.other_ended(a)
			if a.rescue_calls == Activity.RescueCalls.RESTART:
				o.calls_put_off()
	if finished.is_valid():
		finished.call()


## A main.gd hold that restarts the rescue calls begins or ends: every activity hears it (`calls_put_off`).
func _put_off() -> void:
	for o in list:
		o.calls_put_off()
