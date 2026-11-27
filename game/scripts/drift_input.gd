extends RefCounted
## The one-thumb scheme of Bokiem na Narodowym, JEDEN KCIUK (docs/design/drift-narodowy.md 0b.3; the
## grey box, critique-drift.md section 4): touches in, gas and kicks out. Pure: the stadium (and the
## bots, drift_bot.gd) call `press` and `release` with the time of the edge, and read `gas()` and
## `take_kick()` each physics frame.
##   - Down is gas, up is a lift; only the first finger counts (a second one is ignored until the
##     first is up), so no left-handed mirror is needed.
##   - Tap-tap is the kick: a tap is a press of TAP_S s or less, and the kick fires on the second
##     press if it comes within GAP_S s of the first tap's release (no added latency); a finger that
##     stays down after it is gas. The press that kicked never starts another tap-tap.

const TAP_S := 0.18
const GAP_S := 0.25

var down := false
var finger := -1
var _press_t := -INF
var _release_t := -INF
## The last press was a tap (and not one that already kicked).
var _was_tap := false
## This press kicked (it cannot be the first half of another tap-tap).
var _kicked_press := false
var _kick := false
## How many kicks fired (the checks and --drift-log).
var kicks := 0


func press(t: float, index := 0) -> void:
	if down:
		return  # a second finger
	down = true
	finger = index
	_kicked_press = false
	if _was_tap and t - _release_t <= GAP_S + 1e-6:
		_kick = true
		_kicked_press = true
		kicks += 1
	_was_tap = false
	_press_t = t


func release(t: float, index := 0) -> void:
	if not down or index != finger:
		return
	down = false
	finger = -1
	_was_tap = t - _press_t <= TAP_S + 1e-6 and not _kicked_press
	_release_t = t


## The gas the thumb asks for (the model's pedal ramps to it).
func gas() -> float:
	return 1.0 if down else 0.0


## A kick fired since the last call (once).
func take_kick() -> bool:
	var k := _kick
	_kick = false
	return k


## Everything up, nothing pending (a new run).
func reset() -> void:
	down = false
	finger = -1
	_press_t = -INF
	_release_t = -INF
	_was_tap = false
	_kicked_press = false
	_kick = false
