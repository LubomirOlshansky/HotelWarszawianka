extends RefCounted
## SZYBA, the Tajny klient's payoff at Kemal's window (Fable's critique 2026-11-26, section 3
## "Sticker and payoff", the default fix: a third 2D scene in the stand's grammar): the rules only,
## kemal_window_ui.gd draws them and tajny_klient.gd owns the mission (who won the race, Kebabulo's
## line, Kemal's line and the receipt's rows are handed in).
##
## The beats (one tap to play it, the rest by itself; about 6 s before the receipt):
##   IN       the block wipe opens on KEBAB U KEMALA from the pavement (IN_S);
##   READY    the round MLASK sticker in the winner's hand, his line (Kebabulo's race line); a tap
##            slaps it (the autopilot's after AUTO_S);
##   SLAP     two squash frames on the glass and PLASK! (SLAP_S, by itself);
##   FIVE     only when Kebabulo won: his hand slapped it, the player's hand gets the high five
##            (FIVE_S, by itself);
##   QUEUE    QUEUE_N people walk in from both sides and line up at the door (QUEUE_S, by itself);
##   CRY      Kemal's eyes fill, his line (CRY_S by itself, a tap after CRY_TAP_S cuts it short);
##   PARAGON  the one end card, a receipt: the order, the grade, the pay and respect, the badges,
##            the leak line (held CARD_S, then a tap);
##   DONE     the owner takes it from here (CO DALEJ?).
## Holding ✕ (SKIP_S) skips to the receipt; the sticker counts as slapped.
##
## Words: dialogue.json group "kemal_window" (one line per tag).

const WORDS_PATH := "res://data/dialogue.json"
const GROUP := "kemal_window"

enum Phase {IN, READY, SLAP, FIVE, QUEUE, CRY, PARAGON, DONE}

const IN_S := 0.45
const SLAP_S := 0.55
const FIVE_S := 0.75
const QUEUE_S := 2.2
const CRY_S := 2.4
## A tap in CRY before this does nothing (the line has to land first).
const CRY_TAP_S := 0.9
const CARD_S := 1.2
## A tap within this of a beat's start does nothing (a stray second tap must not eat a beat).
const TAP_S := 0.35
## The autopilot's (and the screenshot tool's) wait before its tap.
const AUTO_S := 1.4
const SKIP_S := 0.6
## The people who come for the queue, and the gap between their starts (from alternate sides).
const QUEUE_N := 8
const STAGGER_S := 0.18

var phase := Phase.IN
## Time in the phase.
var t := 0.0
## Time since the scene opened.
var total := 0.0
var auto_play := false
var skipped := false
## How long ✕ has been held (the view draws its bar).
var skip_t := 0.0

## Handed in by the owner: whether the player won the race (else Kebabulo's hand slaps it), the
## winner's line at READY ([pl, en]), Kemal's line at CRY, and the receipt.
var won := true
var line: Array = ["", ""]
var cry: Array = ["", ""]
## The receipt's rows: title, order ([pl, en] each), grade (the text, "9,4 / 10"), pay and respect
## (numbers), badges (an Array of [pl, en]), leak ([pl, en], or empty).
var title: Array = ["PARAGON", "THE RECEIPT"]
var order: Array = ["", ""]
var grade := ""
var pay := 0
var respect := 0
var badges: Array = []
var leak: Array = []

static var _words: Dictionary = {}


## `spec`: won, line, cry, title, order, grade, pay, respect, badges, leak.
func _init(spec: Dictionary = {}) -> void:
	won = bool(spec.get("won", won))
	line = spec.get("line", line)
	cry = spec.get("cry", cry)
	title = spec.get("title", title)
	order = spec.get("order", order)
	grade = str(spec.get("grade", grade))
	pay = int(spec.get("pay", pay))
	respect = int(spec.get("respect", respect))
	badges = spec.get("badges", [])
	leak = spec.get("leak", [])


# --- the words ------------------------------------------------------------------------------------

## The line of `tag` ([pl, en]); the tag itself when there is none.
static func say(tag: String) -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
		if d is Dictionary:
			for l: Variant in (d as Dictionary).get(GROUP, []):
				if l is Array and (l as Array).size() >= 3 and l[2] is Dictionary:
					_words[str((l[2] as Dictionary).get("only", ""))] = [str(l[0]), str(l[1])]
	return _words.get(tag, [tag, tag])


static func has_words(tag: String) -> bool:
	say(tag)
	return _words.has(tag)


# --- the beats ------------------------------------------------------------------------------------

func tick(dt: float, skip_held := false) -> void:
	if phase == Phase.DONE:
		return
	t += dt
	total += dt
	if skip_held and phase < Phase.PARAGON:
		skip_t += dt
		if skip_t >= SKIP_S:
			skip()
			return
	else:
		skip_t = 0.0
	match phase:
		Phase.IN:
			if t >= IN_S:
				_go(Phase.READY)
		Phase.SLAP:
			if t >= SLAP_S:
				_go(Phase.QUEUE if won else Phase.FIVE)
		Phase.FIVE:
			if t >= FIVE_S:
				_go(Phase.QUEUE)
		Phase.QUEUE:
			if t >= QUEUE_S:
				_go(Phase.CRY)
		Phase.CRY:
			if t >= CRY_S:
				_go(Phase.PARAGON)
	if auto_play:
		if phase == Phase.READY and t >= AUTO_S:
			tap()
		elif phase == Phase.PARAGON and t >= CARD_S + 0.6:
			tap()


## A tap anywhere: the slap, a cut through Kemal's line, the receipt's DALEJ. False when it did
## nothing.
func tap() -> bool:
	if t < TAP_S:
		return false
	match phase:
		Phase.READY:
			_go(Phase.SLAP)
		Phase.CRY:
			if t < CRY_TAP_S:
				return false
			_go(Phase.PARAGON)
		Phase.PARAGON:
			if t < CARD_S:
				return false
			_go(Phase.DONE)
		_:
			return false
	return true


## Held ✕: straight to the receipt.
func skip() -> void:
	if phase >= Phase.PARAGON:
		return
	skipped = true
	skip_t = 0.0
	_go(Phase.PARAGON)


func done() -> bool:
	return phase == Phase.DONE


## Whether the sticker is on the glass (from the slap on; a skip counts).
func stuck() -> bool:
	return phase >= Phase.SLAP


## How many of the queue have set off (QUEUE_N from CRY on).
func walkers() -> int:
	if phase < Phase.QUEUE:
		return 0
	if phase > Phase.QUEUE:
		return QUEUE_N
	return mini(QUEUE_N, int(t / STAGGER_S) + 1)


## The time since walker `i` set off (negative before it does; large after the queue).
func walked(i: int) -> float:
	if phase < Phase.QUEUE:
		return -1.0
	if phase > Phase.QUEUE:
		return 99.0
	return t - float(i) * STAGGER_S


func result() -> Dictionary:
	return {"skipped": skipped, "t": snappedf(total, 0.1), "won": won, "stuck": stuck()}


func summary() -> String:
	return "%s %s%s" % [Phase.keys()[phase], "won" if won else "kebabulo", " skipped" if skipped else ""]


func _go(p: Phase) -> void:
	phase = p
	t = 0.0
