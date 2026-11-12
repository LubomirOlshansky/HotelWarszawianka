extends RefCounted
## The activity director (tech-debt TD-1): the one place that knows which activity is on.
##
## Before the kit main.gd named every activity in every question: "is the player busy?" had
## three lists and eight variants, and the arrow, the stop assist and the helicopter's refusal
## each walked the activities by name. An activity of the kit (activity.gd) joins here once with
## `add`, and main.gd asks the director:
##   - `busy()`, `current()`, `busy_tag()`: is one on, and which;
##   - `may_start(a)`: nothing of the kit is on, and `world_free` (main.gd's test for everything
##     that is not in the kit yet: a race, a job, a card, the air) agrees. It is each joined
##     activity's `free_now`;
##   - `targeted()`: the one that sends the player somewhere now (the arrow, the stop assist);
##   - `grounded()`: why the helicopter is refused.
## At most one activity of the kit is on at a time.
##
## Not here yet (they come as more activities join, see tech-debt TD-1): a priority table for
## who may interrupt whom, and the context `messages.gd` asks for.

const Activity := preload("res://scripts/activity.gd")

## main.gd's test for everything outside the kit; true when nothing there holds the player.
var world_free: Callable = func() -> bool: return true
var list: Array[Activity] = []


## An activity joins: from now on it asks the director whether it may phone.
func add(a: Activity) -> void:
	list.append(a)
	a.free_now = may_start.bind(a)


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
	return bool(world_free.call())


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
