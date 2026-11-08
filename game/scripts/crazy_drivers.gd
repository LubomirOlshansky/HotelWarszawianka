extends Node
## Crazy drivers (F, 2026-11-05; docs/design/crazy-drivers.md): the Szkoda Oktawia taxis, the
## Szprynter couriers and the Pasatini 1.9 TDJ drive in traffic.gd's racer mode with no route
## (traffic.gd CRAZY_*, `Driver.crazy`). This node only gives them a voice: when one cuts in front
## of the player's car or blocks it (traffic.gd's `blocks` or `race_passes` count goes up within
## CUT_NEAR m of the player), it honks (`horn`) and its driver says a line over the car through
## the chatter budget (dialogue.say_reaction, key "crazy"), at most one line per car; and KEBAB
## FM's host reports a Pasatini sighting (`radio_host` "pasatini") at most once every RADIO_GAP s
## when it passes near the view. Everything ticks at TICK (4 Hz): no per-frame work, no drawing.
## PT-25 (2026-11-07): a line the budget refuses at the cut (the player over Chatter.MUTE_KMH, the
## reaction window, the car struggling, the car off screen) no longer spends that car's one line:
## the cut stays pending for PENDING s and the line comes as soon as the budget lets it while the
## car is on screen within SPEAK_NEAR m.

## A cut-in or block counts within this of the player's car (m).
const CUT_NEAR := 25.0
## The Pasatini is "sighted" within this of the view's focus (m), on screen.
const SIGHT_NEAR := 45.0
const RADIO_GAP := 600.0
const TICK := 0.25
## A refused line is tried again for this long after the cut (s), while the car is close.
const PENDING := 6.0
## The pending line is said only while the car is within this of the player's car (m).
const SPEAK_NEAR := 40.0
## The line groups by `crazy` (0 unused).
const GROUPS := ["", "crazy_taxi", "crazy_courier", "crazy_pasatini"]
const BUBBLE := Color("#f3c72b")

var traffic: Node
var sfx: Node
var dialogue: Node
var radio: Node
## -> Vector3: the view's focus.
var focus: Callable
var log_on := false
## Counters for the checks and the log.
var cuts := 0
var lines := 0
var horns := 0
var radio_lines := 0
## Cuts whose line never came (the budget kept refusing for PENDING s, or the car left).
var lost_lines := 0

var _t := 0.0
## Driver -> [blocks, race_passes] last tick; Driver -> true once it has spoken.
var _seen := {}
var _talked := {}
## Driver -> seconds left to say its pending line.
var _pending := {}
var _radio_wait := 0.0


func _process(dt: float) -> void:
	_t += dt
	if _t < TICK:
		return
	step(_t)
	_t = 0.0


## One tick of `dt` seconds.
func step(dt: float) -> void:
	if traffic == null:
		return
	_radio_wait = maxf(_radio_wait - dt, 0.0)
	var me: Vector3 = traffic.player_pos
	var me2 := Vector2(me.x, me.z)
	var ear2 := me2
	if focus.is_valid():
		var f: Vector3 = focus.call()
		ear2 = Vector2(f.x, f.z)
	var now := {}
	for d in traffic.drivers():
		if d.crazy <= 0:
			continue
		var counts := [int(d.blocks), int(d.race_passes)]
		now[d] = counts
		var was: Array = _seen.get(d, counts)
		var at2 := Vector2(d.pos.x, d.pos.z)
		if (counts[0] > int(was[0]) or counts[1] > int(was[1])) and traffic.player_on_road and at2.distance_to(me2) < CUT_NEAR:
			_cut(d)
		if d.crazy == 3 and d.visible and at2.distance_to(ear2) < SIGHT_NEAR:
			_announce()
	_seen = now
	for d in _talked.keys():
		if not now.has(d):
			_talked.erase(d)
	for d in _pending.keys():
		var left: float = float(_pending[d]) - dt
		var at2 := Vector2(d.pos.x, d.pos.z)
		if not now.has(d) or not d.active or _talked.has(d):
			_pending.erase(d)
			if not _talked.has(d):
				lost_lines += 1
		elif d.visible and at2.distance_to(me2) < SPEAK_NEAR and _speak(d):
			_pending.erase(d)
		elif left <= 0.0:
			_pending.erase(d)
			lost_lines += 1
			_log("%s line lost" % GROUPS[d.crazy])
		else:
			_pending[d] = left


## A crazy driver cut in or blocked near the player: a horn, and a line once per car.
func _cut(d: Object) -> void:
	cuts += 1
	if sfx != null:
		sfx.play_at("horn", (d.pos as Vector3) + Vector3.UP * 0.5)
		horns += 1
	_log("%s cut in at %.0f, %.0f" % [GROUPS[d.crazy], d.pos.x, d.pos.z])
	if _talked.has(d) or dialogue == null:
		return
	if not (d.visible and _speak(d)):
		_pending[d] = PENDING


## Says the car's one line if the budget lets it; only a line really shown spends it.
func _speak(d: Object) -> bool:
	var kind: int = d.crazy
	var anchor := func() -> Vector3:
		return (d.pos as Vector3) + Vector3(0.0, 1.5, 0.0) if d.active and d.crazy == kind else Vector3.INF
	if dialogue.say_reaction(anchor, "", GROUPS[kind], "", 3.4, BUBBLE, 2.0, true, "crazy").is_empty():
		return false
	_talked[d] = true
	lines += 1
	return true


## KEBAB FM's host: a Pasatini sighting (once per RADIO_GAP, a station on).
func _announce() -> void:
	if _radio_wait > 0.0 or radio == null or dialogue == null or radio.station < 0:
		return
	var l: Array = dialogue.line("radio_host", "pasatini", true)
	if l.is_empty() or dialogue.notes(l).get("only", "") != "pasatini":
		return
	_radio_wait = RADIO_GAP
	radio_lines += 1
	radio.announce(String(l[0]), String(l[1]))
	_log("radio: %s" % l[0])


func _log(text: String) -> void:
	if log_on:
		print("crazy: %s" % text)
