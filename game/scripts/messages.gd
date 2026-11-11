extends RefCounted
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
## INFO (easter eggs, landmark notes, a district found), QUEST (a quest's own message: the TYGRAM
## pin, a partner), ALERT (a result, a warning, the player's own action: a station they picked).
##
## Incoming calls (F 2026-11-11: "also the incoming calls in this queue, with logic too"): a friend's
## call rings only in FREE, CALL_SETTLE s into a calm spell (never straight after a result or an
## escape) and CALL_GAP s after the last call of anyone (no two friends ringing back to back); the
## callers keep their own timers and ask `call_ok` before they ring (main.gd `_free_block`,
## trend_job.gd), and a call that rings tells `call_rang`. A call the player asked for (the
## WĄTKI list, a test flag) does not ask.
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
## Incoming calls: at least this long between two (s), and this long into a calm spell.
const CALL_GAP := 60.0
const CALL_SETTLE := 8.0

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


## A friend's call may ring now (see the top: FREE, settled, spaced from the last call).
func call_ok() -> bool:
	return context == FREE and clock - _calm_since >= CALL_SETTLE and clock - _call_at >= CALL_GAP


## A call rang just now (any caller).
func call_rang() -> void:
	_call_at = clock
	calls += 1


func queued() -> int:
	return _queue.size()


func clear() -> void:
	_queue.clear()


func summary() -> String:
	var parts := PackedStringArray()
	for c: String in CHANNELS:
		parts.append("%s %d/%d/%d" % [c, shown[c], deferred[c], dropped[c]])
	return "messages %s: shown/deferred/dropped %s, %d waiting, %d calls" % [CONTEXT_NAMES[context], ", ".join(parts), _queue.size(), calls]
