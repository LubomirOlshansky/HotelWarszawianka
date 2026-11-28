extends RefCounted

const Pacer := preload("res://scripts/pacer.gd")
## The message director (docs/design/hud-messages.md, F 2026-11-11: "the game starts to be
## overloaded and the user does not see the game"). Every line of text the HUD can put up goes
## through one decision here: SHOW it now, DEFER it to the queue, or DROP it. The decision takes
## the line's channel, its priority and the game's context now.
##
## Contexts (hud.gd works out which one each frame):
## - FREE: driving round the city. Everything shows; the radio host talks.
## - QUEST: a job, a ride, a rescue, a tour or a questline runs (the status card is up). The radio
##   host and the flavour toasts keep quiet; easter-egg notes wait in the queue.
## - CHASE: a race, a police chase or a countdown. Only the quest's own lines, one bubble at a
##   time (chatter.gd), no radio at all, info notes wait.
## - FOCUS: a scripted moment (the drag's rev counter, hud.gd `hush`). Only alerts; the rest waits.
##
## Priorities, low to high: AMBIENT (flavour toasts), RADIO (the host, the news, a new track),
## INFO (easter eggs, landmark notes, a district found), QUEST (a quest's own message: the COTAM
## pin, a partner), ALERT (a result, a warning, the player's own action: a station they picked).
##
## Incoming calls (F 2026-11-11: "also the incoming calls in this queue, with logic too"): a friend's
## call rings only in FREE, CALL_SETTLE s into a calm spell (never straight after a result or an
## escape), CALL_GAP s after the last call of anyone ended (no two friends ringing back to back;
## F 2026-11-19: "1 minute between calls is too fast", and the gap counts from the call's end, not
## its ring), DECLINE_GAP s after a call the player turned down or let ring out (DECLINE_MAX after
## two in a row: a player who keeps saying no is left alone; an answer resets it), and
## CALL_QUIET s after the last run of an activity ended (the quiet time after a finish: TD-3, F
## 2026-11-15; the director tells `finished`); the callers keep their own timers and ask `call_ok`
## before they ring (main.gd `_free_block`, trend_job.gd, and the rescue line in missions.gd, which
## waits at zero), and a call that rings tells `call_rang`. The ride app's requests and Bartek's
## calls, which do not ask `call_ok`, wait for the quiet time alone (`quiet`). A call the player
## asked for (the WĄTKI or HELI list, a test flag) does not ask.
##
## Offer spacing (F 2026-11-19: "I had a few calls in 10 seconds"): any card that comes by itself
## (a call, an offer such as a ride request or a drive-past order, a guide's card) waits
## OFFER_SPACING s after the last card of any kind closed (`spaced`). `offer_ok` is the gate for an
## offer (free roam, settled, spaced, past the quiet time), `call_ok` adds the call gap to it.
##
## The queue holds deferred notes until the context lets them through (in arrival order within a
## priority, the highest first), one every FLUSH_GAP s, each for at most TTL s; past MAX_QUEUED the
## oldest lowest one goes. Pure state on its own clock: game/tools/check_messages.gd drives it.

enum {FREE, QUEST, CHASE, FOCUS}
enum {AMBIENT, RADIO, INFO, QUEST_LINE, ALERT}
enum {SHOW, DEFER, DROP}

const CONTEXT_NAMES := ["free", "quest", "chase", "focus"]
const PRIORITY_NAMES := ["ambient", "radio", "info", "quest", "alert"]
const CHANNELS := ["ticker", "toast", "note"]

## The lowest priority each channel shows at once in each context; below it a line is deferred
## (`note`) or dropped (`ticker`, `toast`: a radio line or a flavour toast is stale a minute later).
const SHOW_FROM := {
	"ticker": [AMBIENT, INFO, ALERT, ALERT],
	"toast": [AMBIENT, RADIO, INFO, ALERT],
	"note": [AMBIENT, QUEST_LINE, QUEST_LINE, ALERT],
}
## Channels whose lines wait in the queue instead of being dropped.
const DEFERS := ["note"]

const FLUSH_GAP := 2.0
const TTL := 240.0
const MAX_QUEUED := 6
## After a quest or a chase ends, a moment of calm before the queue speaks (the result card first).
const SETTLE := 3.0
## Incoming calls: at least this long between two (s), this long into a calm spell, and this long
## after a run ended.
static var CALL_GAP: float = Pacer.num("calls", "gap")
static var CALL_SETTLE: float = Pacer.num("calls", "settle")
static var CALL_QUIET: float = Pacer.num("calls", "quiet")
## Any card that comes by itself: at least this long after the last card closed (or showed) (s).
static var OFFER_SPACING: float = Pacer.num("calls", "spacing")
## After a call turned down or rung out: the next call waits this long; after two or more in a row, DECLINE_MAX.
static var DECLINE_GAP: float = Pacer.num("calls", "decline_gap")
static var DECLINE_MAX: float = Pacer.num("calls", "decline_max")

var context := FREE
var clock := 0.0
## Shown, deferred and dropped lines by channel (check_messages.gd, the bench log).
var shown := {"ticker": 0, "toast": 0, "note": 0}
var deferred := {"ticker": 0, "toast": 0, "note": 0}
var dropped := {"ticker": 0, "toast": 0, "note": 0}

var _queue: Array[Dictionary] = []
var _flushed_at := -INF
var _calm_since := 0.0
var _call_at := -INF
var _done_at := -INF
## The last card shown or closed (`spaced`).
var _card_at := -INF
## A call's card is up and not answered or turned down yet (`call_closed`).
var _call_open := false
## Calls turned down or rung out in a row (`gap_now`); an answered one resets it.
var declines := 0
var calls := 0


## Works out the context from what runs now: a scripted moment (`focus`), a race, a police chase
## or a countdown (`chase`), a job, a ride or a questline (`quest`).
static func context_of(quest: bool, chase: bool, focus: bool) -> int:
	if focus:
		return FOCUS
	if chase:
		return CHASE
	return QUEST if quest else FREE


## Moves the clock and sets the context (hud.gd, each frame).
func tick(dt: float, now_context: int) -> void:
	clock += dt
	if now_context != context:
		context = now_context
		if context == FREE:
			_calm_since = clock
	for i in range(_queue.size() - 1, -1, -1):
		if clock - float(_queue[i]["at"]) > TTL:
			_queue.remove_at(i)


## SHOW, DEFER or DROP a line on `channel` at `priority` now. Counts the outcome.
func decide(channel: String, priority: int) -> int:
	var rule: Array = SHOW_FROM.get(channel, [AMBIENT, AMBIENT, AMBIENT, AMBIENT])
	var out := SHOW if priority >= int(rule[context]) else (DEFER if channel in DEFERS else DROP)
	match out:
		SHOW:
			shown[channel] = int(shown.get(channel, 0)) + 1
		DEFER:
			deferred[channel] = int(deferred.get(channel, 0)) + 1
		DROP:
			dropped[channel] = int(dropped.get(channel, 0)) + 1
	return out


## Holds a deferred line: `args` are what its show call takes again later.
func defer(channel: String, priority: int, args: Array, key := "") -> void:
	if key != "":
		for q in _queue:
			if String(q["key"]) == key:
				return  # the same note is already waiting
	_queue.append({"channel": channel, "priority": priority, "args": args, "at": clock, "key": key})
	while _queue.size() > MAX_QUEUED:
		var low := 0
		for i in _queue.size():
			if int(_queue[i]["priority"]) < int(_queue[low]["priority"]):
				low = i
		_queue.remove_at(low)


## The next waiting line the context lets through now (and takes it off the queue), or {}: the
## highest priority first, then the oldest; one every FLUSH_GAP s, SETTLE s into a calm spell.
func next_ready() -> Dictionary:
	if _queue.is_empty() or clock - _flushed_at < FLUSH_GAP:
		return {}
	if context == FREE and clock - _calm_since < SETTLE:
		return {}
	var best := -1
	for i in _queue.size():
		var q := _queue[i]
		var rule: Array = SHOW_FROM.get(String(q["channel"]), [AMBIENT, AMBIENT, AMBIENT, AMBIENT])
		if int(q["priority"]) < int(rule[context]):
			continue
		if best < 0 or int(q["priority"]) > int(_queue[best]["priority"]):
			best = i
	if best < 0:
		return {}
	_flushed_at = clock
	var out := _queue[best]
	_queue.remove_at(best)
	return out


## A friend's call may ring now (see the top: an offer may come, and the call gap since the last
## call ended has passed).
func call_ok() -> bool:
	return offer_ok() and clock - _call_at >= gap_now()


## An offer that comes by itself may show now: FREE, settled, spaced from the last card, past the
## quiet time.
func offer_ok() -> bool:
	return context == FREE and clock - _calm_since >= CALL_SETTLE and spaced() and not quiet()


## OFFER_SPACING s since the last card showed or closed.
func spaced() -> bool:
	return clock - _card_at >= OFFER_SPACING


## The call gap now: CALL_GAP, or longer after calls the player turned down (DECLINE_GAP, then
## DECLINE_MAX after two in a row).
func gap_now() -> float:
	if declines <= 0:
		return CALL_GAP
	return maxf(CALL_GAP, minf(DECLINE_MAX, DECLINE_GAP * float(declines)))


## A call rang just now (any caller). `card`: its card waits for an answer (`call_closed`); the
## rescue line's pill (false) counts from its ring.
func call_rang(card := true) -> void:
	_call_at = clock
	_card_at = clock
	_call_open = card
	calls += 1


## The call's card went: answered (the gap again, the no's forgotten) or not (turned down, rung
## out, taken away: the next call waits longer). The gap counts from now.
func call_closed(answered: bool) -> void:
	if not _call_open:
		return
	_call_open = false
	_call_at = clock
	_card_at = clock
	declines = 0 if answered else declines + 1


## A call's card is up, not answered yet.
func call_open() -> bool:
	return _call_open


## A card showed or closed now (hud.gd): the next offer waits OFFER_SPACING.
func card_seen() -> void:
	_card_at = clock


## A run of an activity ended just now (the director, activities.gd): the quiet time starts.
func finished() -> void:
	_done_at = clock


## The quiet time after a finish is on: no offer comes by itself for CALL_QUIET s after a run ended.
func quiet() -> bool:
	return clock - _done_at < CALL_QUIET


func queued() -> int:
	return _queue.size()


func clear() -> void:
	_queue.clear()


func summary() -> String:
	var parts := PackedStringArray()
	for c: String in CHANNELS:
		parts.append("%s %d/%d/%d" % [c, shown[c], deferred[c], dropped[c]])
	return "messages %s: shown/deferred/dropped %s, %d waiting, %d calls (%d turned down in a row)" % [CONTEXT_NAMES[context], ", ".join(parts), _queue.size(), calls, declines]
