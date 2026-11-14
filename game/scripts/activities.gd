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
##   - `offering()`: a request card that leaves the player free is up (Podwózka's, the trend
##     job's), each joined activity's `request_up`.
## At most one activity of the kit is on at a time.
##
## Not here yet (they come as more activities join, see tech-debt TD-1): a priority table for
## who may interrupt whom, and the context `messages.gd` asks for.

const Activity := preload("res://scripts/activity.gd")

## main.gd's test for everything outside the kit; true when nothing there holds the player.
var world_free: Callable = func() -> bool: return true
var list: Array[Activity] = []
## An activity's own test in place of `world_free` (`add`'s second argument), by the activity.
var _own_world := {}


## An activity joins: from now on it asks the director whether it may phone. `world`: its own
## test for everything outside the kit, when `world_free` does not fit it (the EV tow starts from
## the air, which `world_free` refuses).
func add(a: Activity, world := Callable()) -> void:
	list.append(a)
	if world.is_valid():
		_own_world[a] = world
	a.free_now = may_start.bind(a)
	a.request_up = offering.bind(a)


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


## `a` may phone or start now: no activity of the kit is on, and nothing outside it either.
func may_start(a: Activity) -> bool:
	var on := current()
	if on != null and on != a:
		return false
	var world: Callable = _own_world.get(a, world_free)
	return bool(world.call())


## The activity that sends the player somewhere now, or null.
func targeted() -> Activity:
	for a in list:
		if a.has_target():
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
## its offer with `offer_busy` off (Podwózka's, the trend job's request beside the road). Each
## joined activity's `request_up`: a rival's challenge waits for it (rivals.gd, PT-15), which
## asked Podwózka by name before it joined.
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
