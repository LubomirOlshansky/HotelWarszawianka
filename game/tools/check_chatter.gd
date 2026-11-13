extends SceneTree
## The chatter budget (chatter.gd, docs/GAMEPLAY_PLAN.md 0.2 and test D5), with the real bubbles.gd,
## dialogue.gd and the ride's drive toasts (rides.gd), no map and no game. Checks that:
## - 60 s pinned against a wall with traffic and people near (a bump and a held-up driver every
##   second, near misses, horns, crowds and dog walkers talking): at most 2 bubbles and 1 toast,
##   and no ambient or reaction line at all while it struggles; a quest line (the tow offer) still
##   shows; the quiet lasts QUIET_AFTER s after it frees itself, then the city talks again;
## - free driving at walking pace with the same spam: never more than 2 bubbles on screen, at least
##   gap() s between two new ones, one reaction in REACTION_WINDOW s, a near miss once a minute, a
##   driver's shout at a bump only for a hit of BUMP_MIN_KMH or more;
## - above MUTE_KMH: no bubble but quest and police; a quest line jumps the cap and makes room by
##   dropping an ambient bubble, never going over 2 on screen;
## - a card up: ambient waits, quest shows;
## - the setting: Mało, Średnio, Dużo give 8, 4 and 2.5 s between bubbles;
## - the ride's star toasts: ten bumps a quarter-second apart give one "−… ★ · stłuczki" toast, 3 s
##   after the last, and none when the ride ends first.
##   godot --headless --path game --script res://tools/check_chatter.gd

const Chatter := preload("res://scripts/chatter.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Rides := preload("res://scripts/rides.gd")
const Fakes := preload("res://tools/fakes.gd")
const DT := 0.1

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


## A traffic car for dialogue.gd's shouts (traffic.gd Driver's fields it reads).
class FakeDriver extends RefCounted:
	var node: Node = null
	var ghost := false
	var active := true
	var slot := 3
	var kind := 0
	var pos := Vector3(4, 0, 0)
	var size := Vector3(1.8, 1.5, 4.2)


var bubbles: Control
var dialogue: Node
var stuck := false
var speed := 0.0
var card := false
## The most bubbles seen on screen at once, and every new bubble's clock time and class.
var peak := 0
var news: Array = []
var _seen := 0


func _initialize() -> void:
	bubbles = Bubbles.new()
	bubbles.struggle = func() -> bool: return stuck
	bubbles.kmh = func() -> float: return speed
	bubbles.cards_up = func() -> bool: return card
	root.add_child(bubbles)
	dialogue = Dialogue.new()
	dialogue.bubbles = bubbles
	root.add_child(dialogue)
	await process_frame
	bubbles.set_process(false)
	dialogue.set_process(false)

	_pinned()
	_free_slow()
	_fast()
	_cards()
	_levels()
	_ride_toasts()
	_reading_time()
	print(bubbles.chatter.summary())
	print("check_chatter: %s" % ("OK" if _problems == 0 else "%d problems" % _problems))
	quit(0 if _problems == 0 else 1)


func _reset(level := Chatter.DEFAULT_LEVEL) -> void:
	bubbles.clear()
	bubbles.chatter = Chatter.new()
	bubbles.chatter.level = level
	stuck = false
	speed = 0.0
	card = false
	peak = 0
	news.clear()
	_seen = 0


## Everything that wants to talk round a player who keeps hitting things: a shout at each bump,
## one at a held-up driver, a near miss, a dog walker at the horn, a crowd and a bus stop.
func _spam(i: int, anchors: Array) -> void:
	var c: Chatter = bubbles.chatter
	var d := FakeDriver.new()
	d.slot = i
	c.hit(22.0 if i % 2 == 0 else 8.0)
	dialogue.on_driver_bumped(d)
	dialogue.on_driver_blocked(d)
	dialogue._shout_wait = 0.0  # dialogue.gd's own 9 s gap off: the budget alone is under test
	dialogue.say_reaction(anchors[0], "Pędzik", "pedzik", "", 4.0, Color.WHITE, 2.2, false, "near_miss")
	dialogue.say_reaction(anchors[1], "", "dog_walkers", "horn", 4.0, Color.WHITE, 2.2, true)
	dialogue.say_ambient(anchors[2], "", "bus_stop", "", 4.0, Color.WHITE, 2.2)
	bubbles.say_ambient(anchors[3], "", "Ale korek!", "What a jam!", 4.0)


func _anchors() -> Array:
	var out := []
	for k in 4:
		var at := Vector3(k * 3.0, 2.0, 0.0)
		out.append(func() -> Vector3: return at)
	return out


## Runs `seconds` of frames, spamming every `every` s; records what came up.
func _run(seconds: float, every: float, spam := true) -> void:
	var anchors := _anchors()
	var steps := roundi(seconds / DT)
	var next := 0.0
	for s in steps:
		var c: Chatter = bubbles.chatter
		if spam and c.clock >= next:
			next += every
			_spam(s, anchors)
		bubbles._frame(DT)
		_note()


func _note() -> void:
	var c: Chatter = bubbles.chatter
	peak = maxi(peak, bubbles.count())
	var total := 0
	for k in 4:
		total += c.shown[k]
	while _seen < total:
		_seen += 1
		news.append([c.clock, bubbles.count()])


func _pinned() -> void:
	_reset()
	stuck = true
	speed = 3.0
	_run(60.0, 1.0)
	var c: Chatter = bubbles.chatter
	_expect(c.shown[Chatter.REACTION] == 0 and c.shown[Chatter.AMBIENT] == 0,
			"pinned 60 s: %d reaction and %d ambient lines showed (want none)" % [c.shown[Chatter.REACTION], c.shown[Chatter.AMBIENT]])
	_expect(peak <= 2, "pinned 60 s: %d bubbles at once (at most 2)" % peak)
	_expect(c.dropped[Chatter.REACTION] > 50, "pinned: the shouts and near misses were not even tried (%d dropped)" % c.dropped[Chatter.REACTION])
	# The stuck offer is a quest line: it shows.
	var tow := func() -> Vector3: return Vector3(0, 2, 0)
	_expect(bubbles.say(tow, "Pomoc drogowa", "Utknąłeś?", "Stuck?"), "pinned: a quest line (the tow) was dropped")
	_expect(not bubbles.chatter.toast_ok(), "pinned: a flavour toast may show")
	# Freed: still quiet for QUIET_AFTER s, then the city may talk.
	stuck = false
	bubbles.clear()
	_run(Chatter.QUIET_AFTER - 0.5, 1.0)
	_expect(c.shown[Chatter.REACTION] + c.shown[Chatter.AMBIENT] == 0, "freed: a line came within QUIET_AFTER s")
	_run(2.0, 0.5)
	_expect(c.shown[Chatter.REACTION] + c.shown[Chatter.AMBIENT] > 0, "freed: still silent %.1f s after" % (Chatter.QUIET_AFTER + 1.5))
	_expect(c.toast_ok(), "freed: flavour toasts still blocked")
	print("pinned 60 s: 0 city lines (%d dropped), the tow line shows, quiet %.0f s after" % [c.dropped[Chatter.REACTION] + c.dropped[Chatter.AMBIENT], Chatter.QUIET_AFTER])


func _free_slow() -> void:
	_reset()
	speed = 20.0
	_run(120.0, 0.5)
	var c: Chatter = bubbles.chatter
	_expect(peak <= Chatter.MAX_ON_SCREEN, "slow, free: %d bubbles at once" % peak)
	for i in range(1, news.size()):
		var gap: float = float(news[i][0]) - float(news[i - 1][0])
		_expect(gap >= c.gap() - DT * 0.5, "slow, free: two bubbles %.1f s apart (gap %.1f)" % [gap, c.gap()])
	var reactions: int = c.shown[Chatter.REACTION]
	_expect(reactions <= ceili(120.0 / Chatter.REACTION_WINDOW), "slow, free: %d reactions in 120 s (one in %.0f s)" % [reactions, Chatter.REACTION_WINDOW])
	_expect(reactions >= 3, "slow, free: only %d reactions in 120 s" % reactions)
	_expect(c.shown[Chatter.AMBIENT] > 0, "slow, free: no ambient line at all")
	print("free at 20 km/h, 120 s: %d bubbles (%d reactions), peak %d on screen" % [news.size(), reactions, peak])
	# The keys: near misses once a minute; a soft hit draws no shout.
	_reset()
	var c2: Chatter = bubbles.chatter
	var a := func() -> Vector3: return Vector3.ZERO
	_expect(bubbles.say_reaction(a, "", "Uważaj!", "", 4.0, Color.WHITE, 2.0, "near_miss"), "the first near miss was dropped")
	for s in roundi(30.0 / DT):
		bubbles._frame(DT)
	bubbles.clear()
	_expect(not bubbles.say_reaction(a, "", "Uważaj!", "", 4.0, Color.WHITE, 2.0, "near_miss"), "a second near miss 30 s later showed")
	for s in roundi(31.0 / DT):
		bubbles._frame(DT)
	c2.hit(10.0)
	_expect(not bubbles.allows(Chatter.REACTION, "bump"), "a 10 km/h bump may draw a shout")
	c2.hit(30.0)
	_expect(bubbles.allows(Chatter.REACTION, "bump"), "a 30 km/h bump may not draw a shout")
	_expect(bubbles.say_reaction(a, "", "Uważaj!", "", 4.0, Color.WHITE, 2.0, "near_miss"), "a near miss 61 s later was dropped")


func _fast() -> void:
	_reset()
	speed = 60.0
	_run(30.0, 0.5)
	var c: Chatter = bubbles.chatter
	_expect(c.shown[Chatter.REACTION] + c.shown[Chatter.AMBIENT] == 0, "60 km/h: %d city lines" % (c.shown[Chatter.REACTION] + c.shown[Chatter.AMBIENT]))
	# A quest line and a police line show at speed; a third makes room, never 3 on screen.
	speed = 20.0
	for s in roundi(10.0 / DT):
		bubbles._frame(DT)
	var amb := func() -> Vector3: return Vector3(9, 2, 0)
	_expect(bubbles.say_ambient(amb, "", "Hej", "Hey"), "20 km/h: an ambient line was dropped")
	speed = 60.0
	var q1 := func() -> Vector3: return Vector3(1, 2, 0)
	var q2 := func() -> Vector3: return Vector3(2, 2, 0)
	_expect(bubbles.say(q1, "Seba", "Ej!", "Hey!"), "60 km/h: a quest line was dropped")
	_expect(bubbles.say(q2, "Policja", "Stój!", "Stop!", 3.5, Color.WHITE, 2.6, Chatter.POLICE), "60 km/h: a police line was dropped")
	_expect(bubbles.count() == 2, "quest + police with an ambient up: %d on screen (want 2)" % bubbles.count())
	_expect(not bubbles.is_talking(amb), "the ambient bubble did not make room for the quest line")
	print("60 km/h, 30 s: 0 city lines; quest and police show and make room (2 on screen)")


func _cards() -> void:
	_reset()
	card = true
	speed = 10.0
	var a := func() -> Vector3: return Vector3.ZERO
	_expect(not bubbles.say_ambient(a, "", "Hej", "Hey"), "a card up: an ambient line showed")
	_expect(bubbles.say(a, "Klient", "Jedziemy?", "Shall we?"), "a card up: a quest line was dropped")


func _levels() -> void:
	var want := [8.0, 4.0, 2.5]
	for level in 3:
		_reset(level)
		speed = 20.0
		_run(60.0, 0.25)
		var shortest := INF
		for i in range(1, news.size()):
			shortest = minf(shortest, float(news[i][0]) - float(news[i - 1][0]))
		_expect(absf(bubbles.chatter.gap() - want[level]) < 0.01, "level %d: gap %.1f (want %.1f)" % [level, bubbles.chatter.gap(), want[level]])
		_expect(shortest >= want[level] - DT * 0.5, "level %d: two bubbles %.1f s apart (want ≥ %.1f)" % [level, shortest, want[level]])
		print("level %s: %d bubbles in 60 s, shortest gap %.1f s" % [Chatter.LEVEL_NAMES[level], news.size(), shortest])


## F 2026-11-05: a line stays up as long as it takes to read, so longer text lives longer.
func _reading_time() -> void:
	var short := Chatter.read_time("Hej!")
	var long := Chatter.read_time("Przepraszam, czy mógłby Pan podrzucić mnie pod Pałac Kultury, bo spieszę się na pociąg do Gdańska?")
	_expect(short >= Chatter.READ_MIN, "reading time: a short line %.1f s (want ≥ %.1f)" % [short, Chatter.READ_MIN])
	_expect(long > short + 3.0, "reading time: a long line %.1f s is not clearly longer than a short one %.1f s" % [long, short])
	_expect(Chatter.read_time("x".repeat(2000)) <= Chatter.READ_MAX * 1.26, "reading time: no cap")


func _ride_toasts() -> void:
	var hud := Fakes.Hud.new()
	root.add_child(hud)
	var rides := Rides.new()
	rides.hud = hud
	rides.phase = Rides.Phase.RUN
	rides.stage = Rides.Stage.RIDE
	for i in 10:
		rides._drive_note("bump", ["stłuczka", "stłuczki", "bump", "bumps"])
		for s in 2:
			rides._drive_tick(0.125)
	_expect(hud.toasts.is_empty(), "ride: a toast came while still bumping: %s" % [hud.toasts])
	for s in roundi(3.2 / DT):
		rides._drive_tick(DT)
	_expect(hud.toasts.size() == 1, "ride: ten bumps gave %d toasts (want 1): %s" % [hud.toasts.size(), hud.toasts])
	if hud.toasts.size() == 1:
		_expect(hud.toasts[0].contains("stłuczki") and hud.toasts[0].begins_with("−5"), "ride: the merged toast reads \"%s\"" % hud.toasts[0])
		print("ride: ten bumps, one toast: %s" % hud.toasts[0])
	# A penalty, then the ride ends before the merge: no toast.
	hud.toasts.clear()
	hud.toasts_en.clear()
	rides._drive_note("corner", ["zakręt", "zakręty", "fast corner", "fast corners"])
	rides.stage = Rides.Stage.RESULT
	for s in roundi(4.0 / DT):
		rides._drive_tick(DT)
	_expect(hud.toasts.is_empty(), "ride: a drive toast after the ride ended")
	rides.free()
	hud.queue_free()
