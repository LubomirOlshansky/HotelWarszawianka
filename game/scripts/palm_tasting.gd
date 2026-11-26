extends RefCounted
## The tasting at the Palm, as Zbyszek's livestream (plan doc "First 10 minutes: Tajny klient",
## "The river scene and the viral moment"; F moved the meeting to the Palm at Rondo de Gaulle'a):
## the rules only, palm_tasting_ui.gd draws them and tajny_klient.gd owns the mission and
## Kebabulo's words (his hello, his verdict, the grade and its roast are handed in).
##
## The beats, every tap advances and nothing waits on a timer the player has to beat:
##   IN      Zbyszek's viewfinder closes in: the REC frame, the mosaic down to the canvas (IN_S);
##   HELLO   Kebabulo: "Don't say a thing. I'm biting." (a tap);
##   CHEW    the close-up on his face, chewing, eyes shut, the chat frozen (CHEW_S, by itself);
##   MLASK   the pop, the sticker-shaped burst, the shake, the chat erupting (MLASK_S, by itself);
##   VERDICT his lines one by one: the bite, the bun, Berlin, DŻEMINI or the quiet one (a tap each);
##   DRUM    the drumroll, the scoreboard's digits rolling (DRUM_S, by itself);
##   GRADE   the decimal grade and the roast of the player's own run (a tap; 11/10 cracks the board);
##   CARD    the RECENZJA card: the order, the grade, the badge, the game's name (held CARD_S, then
##           a tap);
##   DONE    the owner takes it from here (the race call).
## Holding ✕ (SKIP_S) skips to the card, so a replay can get past it in a second.
##
## The chat: a line from the beat's bag ("chat_" + the beat) every CHAT_S, three on screen, none
## during CHEW; the viewer count climbs and jumps at the MLASK and the grade. Seeded, so a check
## and a screenshot see the same lines.
##
## Words: dialogue.json group "palm_tasting" (several lines may share a tag: the chat bags).

const WORDS_PATH := "res://data/dialogue.json"
const GROUP := "palm_tasting"

enum Phase {IN, HELLO, CHEW, MLASK, VERDICT, DRUM, GRADE, CARD, DONE}

const IN_S := 1.4
const CHEW_S := 1.5
const MLASK_S := 1.1
const DRUM_S := 1.4
const CARD_S := 3.0
## A tap within this of a line's start does nothing (a stray second tap must not eat a line).
const TAP_S := 0.35
## The autopilot's (and the screenshot tool's) time on each tap beat.
const AUTO_S := 1.8
const SKIP_S := 0.6
const CHAT_S := 1.1
const CHAT_MAX := 3
const VIEWERS_0 := 1240

var phase := Phase.IN
## Time in the phase.
var t := 0.0
## Time since the scene opened.
var total := 0.0
## The line on screen now ([pl, en]) and who says it ("kebabulo", "zbyszek" or "").
var line: Array = ["", ""]
var who := ""
## Which verdict line is up.
var line_i := 0
var auto_play := false
var skipped := false
## How long ✕ has been held (the view draws its ring).
var skip_t := 0.0
var viewers := VIEWERS_0
## The chat on screen, oldest first: [{"name", "pl", "en", "t"}].
var chat: Array = []

## Handed in by the owner.
var hello: Array = ["", ""]
var verdict: Array = []
var roast: Array = ["", ""]
var grade := 8.0
var grade_label := "8,0 / 10"
var perfect := false
var cam := false
## The card's lines: the order ([pl, en]) and the badge ([pl, en], or empty).
var order: Array = ["", ""]
var badge: Array = []

var _chat_t := 0.0
var _rng := RandomNumberGenerator.new()
var _used: Dictionary = {}

static var _words: Dictionary = {}


## `spec`: hello, verdict (an Array of [pl, en]), roast, grade, grade_label, cam, order, badge,
## seed.
func _init(spec: Dictionary = {}) -> void:
	hello = spec.get("hello", hello)
	verdict = spec.get("verdict", verdict)
	roast = spec.get("roast", roast)
	grade = float(spec.get("grade", grade))
	grade_label = str(spec.get("grade_label", grade_label))
	perfect = grade >= 11.0
	cam = bool(spec.get("cam", false))
	order = spec.get("order", order)
	badge = spec.get("badge", [])
	_rng.seed = int(spec.get("seed", 87))
	if cam:
		viewers = VIEWERS_0 * 3


# --- the words ------------------------------------------------------------------------------------

## The first line of `tag` ([pl, en]); the tag itself when there is none.
static func say(tag: String) -> Array:
	var bag := lines_of(tag)
	return bag[0] if not bag.is_empty() else [tag, tag]


## Every line of `tag` (the chat bags hold several).
static func lines_of(tag: String) -> Array:
	if _words.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
		if d is Dictionary:
			for l: Variant in (d as Dictionary).get(GROUP, []):
				if l is Array and (l as Array).size() >= 3 and l[2] is Dictionary:
					var k := str((l[2] as Dictionary).get("only", ""))
					if not _words.has(k):
						_words[k] = []
					(_words[k] as Array).append([str(l[0]), str(l[1])])
	return _words.get(tag, [])


static func has_words(tag: String) -> bool:
	return not lines_of(tag).is_empty()


# --- the beats ------------------------------------------------------------------------------------

func tick(dt: float, skip_held := false) -> void:
	if phase == Phase.DONE:
		return
	t += dt
	total += dt
	if skip_held and phase < Phase.CARD:
		skip_t += dt
		if skip_t >= SKIP_S:
			skip()
			return
	else:
		skip_t = 0.0
	match phase:
		Phase.IN:
			if t >= IN_S:
				_go(Phase.HELLO)
		Phase.CHEW:
			if t >= CHEW_S:
				_go(Phase.MLASK)
		Phase.MLASK:
			if t >= MLASK_S:
				_go(Phase.VERDICT)
		Phase.DRUM:
			if t >= DRUM_S:
				_go(Phase.GRADE)
	if auto_play and t >= (CARD_S if phase == Phase.CARD else AUTO_S):
		tap()
	_chat_tick(dt)


## A tap anywhere: the next line, the next beat. False when it did nothing.
func tap() -> bool:
	if t < TAP_S:
		return false
	match phase:
		Phase.HELLO:
			_go(Phase.CHEW)
		Phase.VERDICT:
			if line_i + 1 < verdict.size():
				line_i += 1
				_set_line(verdict[line_i], "kebabulo")
				t = 0.0
			else:
				_go(Phase.DRUM)
		Phase.GRADE:
			_go(Phase.CARD)
		Phase.CARD:
			if t < CARD_S:
				return false
			_go(Phase.DONE)
		_:
			return false
	return true


## Held ✕: straight to the card.
func skip() -> void:
	if phase >= Phase.CARD:
		return
	skipped = true
	skip_t = 0.0
	_go(Phase.CARD)


func done() -> bool:
	return phase == Phase.DONE


func result() -> Dictionary:
	return {"skipped": skipped, "t": snappedf(total, 0.1), "viewers": viewers}


## The scoreboard while it rolls: a random-looking decimal settling on the grade.
func board_text() -> String:
	if phase == Phase.DRUM:
		var k := int(t * 14.0)
		return "%d,%d" % [5 + (k * 7) % 5, (k * 3) % 10]
	if perfect:
		return "11"
	return ("%.1f" % grade).replace(".", ",")


func summary() -> String:
	return "%s grade %s viewers %d%s" % [Phase.keys()[phase], grade_label, viewers, " skipped" if skipped else ""]


func _go(p: Phase) -> void:
	phase = p
	t = 0.0
	match p:
		Phase.HELLO:
			_set_line(hello, "kebabulo")
			_chat_burst("chat_hello", 1)
		Phase.CHEW:
			_set_line(["", ""], "")
		Phase.MLASK:
			viewers += 380 + _rng.randi_range(0, 120)
			_chat_burst("chat_mlask", 3)
		Phase.VERDICT:
			line_i = 0
			_set_line(verdict[0] if not verdict.is_empty() else ["", ""], "kebabulo")
		Phase.DRUM:
			_set_line(say("drumroll"), "zbyszek")
		Phase.GRADE:
			_set_line(roast, "kebabulo")
			viewers += 900 if perfect else 260
			_chat_burst("chat_perfect" if perfect else "chat_grade", 2)
		Phase.CARD:
			_set_line(["", ""], "")


func _set_line(l: Array, by: String) -> void:
	line = [str(l[0]), str(l[1])] if l.size() >= 2 else ["", ""]
	who = by if line[0] != "" else ""


func _chat_bag() -> String:
	match phase:
		Phase.IN, Phase.HELLO:
			return "chat_cam" if cam else "chat_in"
		Phase.MLASK:
			return "chat_mlask"
		Phase.VERDICT, Phase.DRUM:
			return "chat_verdict"
		Phase.GRADE, Phase.CARD:
			return "chat_perfect" if perfect else "chat_grade"
	return ""


func _chat_tick(dt: float) -> void:
	for c: Dictionary in chat:
		c["t"] = float(c["t"]) + dt
	if phase == Phase.CHEW or phase == Phase.DONE:
		return
	_chat_t += dt
	if _chat_t >= CHAT_S:
		_chat_t = 0.0
		_chat_add(_chat_bag())
		viewers += _rng.randi_range(3, 40)


func _chat_burst(bag: String, n: int) -> void:
	for i in n:
		_chat_add(bag)
	_chat_t = 0.0


## The next line from `bag` (each bag shuffled, every line once before any repeats) under a
## made-up handle.
func _chat_add(bag: String) -> void:
	var lines := lines_of(bag)
	if lines.is_empty():
		return
	var order: Array = _used.get(bag, [])
	if order.is_empty():
		order = range(lines.size())
		for k in range(order.size() - 1, 0, -1):
			var j := _rng.randi_range(0, k)
			var tmp: int = order[k]
			order[k] = order[j]
			order[j] = tmp
	var i: int = order.pop_back()
	_used[bag] = order
	var names := lines_of("handles")
	var h: Array = names[_rng.randi_range(0, names.size() - 1)] if not names.is_empty() else ["WIDZ", "VIEWER"]
	chat.append({"name": str(h[0]), "pl": str(lines[i][0]), "en": str(lines[i][1]), "t": 0.0})
	while chat.size() > CHAT_MAX:
		chat.pop_front()
