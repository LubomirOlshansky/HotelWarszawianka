extends SceneTree
## The message director (messages.gd, docs/design/hud-messages.md, F 2026-11-11: "the game starts
## to be overloaded and the user does not see the game"), with the real hud.gd, bubbles.gd and
## chatter.gd, no map and no game. Checks that:
## - the rules: each channel's lowest shown priority in free roam, a quest, a chase and a scripted
##   moment; the queue (a note waits, comes back after the settle, one every FLUSH_GAP s, the
##   highest first, at most MAX_QUEUED, gone after TTL); the calls (only in free roam, settled,
##   CALL_GAP apart);
## - F's night-race screenshot replayed (a police chase in a race with the TYGRAM pin, a partner,
##   the radio's news, the app-taxi's GPS line, an easter egg): no radio line, one bubble (the
##   partner's), the TYGRAM pin shows, the egg waits and shows once the chase is over, no friend's
##   call rings until then;
## - a station the player picked still shows its caption during a chase;
## - two toasts in a row: the second waits until the first was glanced at, then shows;
## - the compact quest card: no empty English line, the hint folds away after its reading time,
##   a hint that only counts (metres, seconds) stays folded, a new hint opens it again;
## - the challenge is a call to action: taller than a chip, the racer's name on it, popping in;
## - the road ahead: no boxes when parked, three ahead of the car when driving; a bubble whose
##   speaker is straight ahead stands off the road when there is room.
##   godot --headless --path game --script res://tools/check_messages.gd

const Messages := preload("res://scripts/messages.gd")
const Chatter := preload("res://scripts/chatter.gd")
const Hud := preload("res://scripts/hud.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const Missions := preload("res://scripts/missions.gd")

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_check_rules()
	_check_queue()
	_check_calls()
	await _check_hud()
	if _problems == 0:
		print("check_messages: OK")
		quit(0)
	else:
		print("check_messages: %d problems" % _problems)
		quit(1)


func _check_rules() -> void:
	var m := Messages.new()
	_expect(Messages.context_of(false, false, false) == Messages.FREE, "nothing on is not free roam")
	_expect(Messages.context_of(true, false, false) == Messages.QUEST, "a quest is not QUEST")
	_expect(Messages.context_of(true, true, false) == Messages.CHASE, "a chase in a quest is not CHASE")
	_expect(Messages.context_of(true, true, true) == Messages.FOCUS, "a scripted moment is not FOCUS")
	# [channel, priority, free, quest, chase, focus]
	var table := [
		["ticker", Messages.RADIO, Messages.SHOW, Messages.DROP, Messages.DROP, Messages.DROP],
		["ticker", Messages.ALERT, Messages.SHOW, Messages.SHOW, Messages.SHOW, Messages.SHOW],
		["toast", Messages.AMBIENT, Messages.SHOW, Messages.DROP, Messages.DROP, Messages.DROP],
		["toast", Messages.INFO, Messages.SHOW, Messages.SHOW, Messages.SHOW, Messages.DROP],
		["note", Messages.INFO, Messages.SHOW, Messages.DEFER, Messages.DEFER, Messages.DEFER],
		["note", Messages.QUEST_LINE, Messages.SHOW, Messages.SHOW, Messages.SHOW, Messages.DEFER],
	]
	for row: Array in table:
		for c in 4:
			m.tick(0.0, c)
			var got := m.decide(row[0], row[1])
			_expect(got == int(row[2 + c]), "%s at %s in %s: %d, not %d" % [row[0], Messages.PRIORITY_NAMES[row[1]],
					Messages.CONTEXT_NAMES[c], got, row[2 + c]])


func _check_queue() -> void:
	var m := Messages.new()
	m.tick(10.0, Messages.CHASE)
	m.defer("note", Messages.INFO, ["egg 1"], "egg 1")
	m.defer("note", Messages.INFO, ["egg 1"], "egg 1")
	_expect(m.queued() == 1, "the same note queued twice")
	m.defer("note", Messages.QUEST_LINE, ["pin"], "pin")
	_expect(m.next_ready().get("args", []) == ["pin"], "a quest's note held in the queue during the chase")
	_expect(m.next_ready().is_empty(), "an info note left the queue during the chase")
	m.tick(1.0, Messages.FREE)
	_expect(m.next_ready().is_empty(), "the queue spoke before the settle")
	m.tick(Messages.SETTLE, Messages.FREE)
	_expect(m.next_ready().get("args", []) == ["egg 1"], "the waiting note didn't come once the chase was over")
	m.defer("note", Messages.INFO, ["egg 2"], "egg 2")
	_expect(m.next_ready().is_empty(), "two notes inside FLUSH_GAP")
	m.tick(Messages.FLUSH_GAP, Messages.FREE)
	_expect(not m.next_ready().is_empty(), "the second note didn't come after FLUSH_GAP")
	m.tick(0.0, Messages.QUEST)
	for i in Messages.MAX_QUEUED + 3:
		m.defer("note", Messages.INFO if i > 0 else Messages.QUEST_LINE - 1, ["n%d" % i], "n%d" % i)
	_expect(m.queued() == Messages.MAX_QUEUED, "the queue holds %d, not %d" % [m.queued(), Messages.MAX_QUEUED])
	m.tick(Messages.TTL + 1.0, Messages.QUEST)
	_expect(m.queued() == 0, "notes outlived TTL in the queue")


func _check_calls() -> void:
	var m := Messages.new()
	m.tick(1.0, Messages.FREE)
	_expect(not m.call_ok(), "a call may ring in the first seconds")
	m.tick(Messages.CALL_SETTLE, Messages.FREE)
	_expect(m.call_ok(), "no call may ring in free roam")
	for c in [Messages.QUEST, Messages.CHASE, Messages.FOCUS]:
		m.tick(0.0, c)
		_expect(not m.call_ok(), "a call may ring in %s" % Messages.CONTEXT_NAMES[c])
	m.tick(0.0, Messages.FREE)
	_expect(not m.call_ok(), "a call may ring the moment a chase ended")
	m.tick(Messages.CALL_SETTLE, Messages.FREE)
	_expect(m.call_ok(), "no call after the settle")
	m.call_rang()
	m.tick(Messages.CALL_GAP - 1.0, Messages.FREE)
	_expect(not m.call_ok(), "two calls inside CALL_GAP")
	m.tick(1.0, Messages.FREE)
	_expect(m.call_ok(), "no call after CALL_GAP")


func _tick(hud: CanvasLayer, b: Control, seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.001:
		hud._frame(0.1)
		b._frame(0.1)
		t += 0.1


func _check_hud() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	var b: Control = Bubbles.new()
	b.pt = hud.pt
	b.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	hud.add_speech(b)
	hud.chatter = b.chatter
	await process_frame
	hud.process_mode = Node.PROCESS_MODE_DISABLED  # the check moves the clocks itself
	b.process_mode = Node.PROCESS_MODE_DISABLED
	var pt: float = hud.pt
	var mid := Vector2(vp.size) * 0.5
	_tick(hud, b, Messages.CALL_SETTLE + 1.0)
	_expect(hud.call_ok(), "hud: no call may ring in free roam")

	# F's night race (IMG_7733): the race's status with its position, the police chase's pill and
	# koguty, the TYGRAM pin, the partner's line, the radio's news, the GPS joke and an easter egg.
	hud.show_status("PARKING POD NARODOWYM · WYŚCIG", "", "2523 m", "Bądź pierwszy", 0.0, Color("#38f6ff"), "2/9", {},
			"Be first there")
	hud.set_koguty(1, 1)
	hud.police_pill("POŚCIG · KONIEC ZMIANY ZA 0:30", "CHASE · END OF SHIFT IN 0:30")
	_tick(hud, b, 0.2)
	_expect(hud.messages.context == Messages.CHASE, "the night race with the police isn't a chase (%s)" % Messages.CONTEXT_NAMES[hud.messages.context])
	hud.ticker("87,3 KEBAB FM:  Aleje Jerozolimskie: stłuczka.", Color("#ff5fc8"), "Aleje Jerozolimskie: a fender bender.")
	_expect(not hud._wants.get(hud._ticker, false), "the radio's news showed in the chase")
	hud.show_note("TYGRAM · WNRC", "📍 Parking pod Narodowym. Kto pierwszy, ten lepszy.", Color("#38f6ff"), Messages.QUEST_LINE)
	_expect(hud._wants.get(hud._note, false), "the TYGRAM pin (the quest's own message) waited in the chase")
	hud.show_note("SEKRET 2/5 · EASTER EGG", "Gołębie na placu Defilad", Color("#ff4fd8"))
	_expect(hud._note_title.text == "TYGRAM · WNRC", "an easter egg took the pin's place in the chase")
	_expect(hud.messages.queued() == 1, "the easter egg isn't waiting in the queue")
	hud.ambient_toast("Ładny wieczór", "Nice evening")
	_expect(not hud._wants.get(hud._toast_box, false), "a flavour toast showed in the chase")
	var partner := Vector3(mid.x + 300.0, mid.y + 200.0, 0.0)
	var taxi := Vector3(mid.x - 300.0, mid.y - 100.0, 0.0)
	b.say(partner, "Darek „Bawarka”", "Pierwszy na miejscu stawia.", "First one there buys.")
	_expect(not b.say_ambient(taxi, "Podwózka", "GPS kazał tu stanąć.", "The GPS said to stop here."),
			"the app-taxi's GPS line (ambient) showed in the chase")
	_expect(not b.say_reaction(taxi, "Kierowca", "Ej!", "Hey!"), "a driver's shout showed in the chase")
	b.say(Vector3(mid.x, mid.y + 250.0, 0.0), "Policja", "Proszę się zatrzymać!", "Please stop!", 3.5, Color("#8fb0ff"), 2.6, Chatter.POLICE)
	_expect(b.count() == 1, "%d bubbles in the chase (one voice at a time)" % b.count())
	_expect(not hud.call_ok(), "a friend's call may ring in the chase")
	hud.radio_touched()
	hud.ticker("87,3 KEBAB FM", Color("#ff5fc8"), "")
	_expect(hud._wants.get(hud._ticker, false), "the station the player picked didn't show its caption in the chase")
	# The chase and the race end: the egg comes after the settle.
	hud.set_koguty(0, 0)
	hud.police_pill("", "")
	hud.hide_status()
	_tick(hud, b, 1.0)
	_expect(hud._note_title.text == "TYGRAM · WNRC" or not hud._note.visible, "the egg came before the settle")
	_expect(not hud.call_ok(), "a call may ring right after the chase")
	_tick(hud, b, Messages.SETTLE + 6.0)
	_expect(hud._note_title.text == "SEKRET 2/5 · EASTER EGG", "the easter egg didn't come once the chase was over")
	_tick(hud, b, Messages.CALL_SETTLE)
	_expect(hud.call_ok(), "no call after the chase settled")
	hud.show_side_card("📞 IVAN DZWONI", "Kumpel.", PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), Color("#ffb020"))
	hud.hide_card()
	_expect(not hud.call_ok(), "a second call may ring right after one")
	# The rescue line asks the same gate (F 2026-11-11, "what logic do calls have when I cruise"):
	# its countdown runs out right after Ivan's call, so it waits CALL_GAP, then rings and counts.
	var rescue: Node = Missions.new()
	rescue.hud = hud
	rescue._hospitals.append({"name": "Szpital", "pos": Vector3.ZERO, "children": false})
	rescue.ring_in(0.05)
	for i in 20:
		rescue.tick(0.1, Vector3.ZERO, 0.0, false)
	_expect(rescue.state == Missions.State.CLOSED, "a rescue rang 2 s after a friend's call")
	_tick(hud, b, Messages.CALL_GAP + 1.0)
	var before: int = hud.messages.calls
	rescue.tick(0.1, Vector3.ZERO, 0.0, false)
	_expect(rescue.state == Missions.State.RINGING, "the waiting rescue never rang once calls were allowed")
	_expect(hud.messages.calls == before + 1 and not hud.call_ok(), "a rescue call didn't count as a call")
	rescue.free()
	hud.hide_pill()

	# Two toasts: the second waits until the first was glanced at.
	hud.clear_all()
	hud.toast("Pierwszy", "First")
	hud.toast("Drugi", "Second")
	_expect(hud._toast.text == "Pierwszy", "the second toast wiped the first at once")
	_tick(hud, b, hud.TOAST_GLANCE + 1.0)
	_expect(hud._toast.text == "Drugi" and hud._wants.get(hud._toast_box, false), "the waiting toast never came")

	# The compact quest card.
	hud.clear_all()
	hud.show_status("KEBAB → Wspólna 47/49", "GORĄCY 92%", "410 m", "Jedź do pomarańczowego światła", 0.0, Color("#ff9a3c"),
			"", {}, "Head for the orange beacon")
	hud._layout()
	var open_h: float = hud._status.get_combined_minimum_size().y
	_expect(hud._status_hint.visible, "the quest card's first hint didn't show")
	_expect(not hud._status_hint_en.visible, "the quest card keeps an empty English line")
	_expect(not hud._status_clock.text.begins_with(" "), "the clock line starts with spaces")
	_tick(hud, b, 13.0)
	hud.show_status("KEBAB → Wspólna 47/49", "GORĄCY 90%", "395 m", "Jedź do pomarańczowego światła", 0.0, Color("#ff9a3c"))
	_expect(not hud._status_hint.visible, "the quest card's hint never folded away")
	var folded_h: float = hud._status.get_combined_minimum_size().y
	_expect(folded_h < open_h - 10.0 * pt, "the folded quest card isn't smaller (%.0f vs %.0f pt)" % [folded_h / pt, open_h / pt])
	hud.show_status("WYŚCIG · Seba", "0:42", "620 m", "Seba: 40 m za tobą", 0.0, Color("#b45cff"), "2/9")
	_expect(hud._status_hint.visible, "a new hint didn't open the card")
	_tick(hud, b, 12.0)
	hud.show_status("WYŚCIG · Seba", "0:30", "500 m", "Seba: 35 m za tobą", 0.0, Color("#b45cff"), "2/9")
	_expect(not hud._status_hint.visible, "a hint that only counted opened the card again")
	print("quest card: %.0f pt open, %.0f pt folded" % [open_h / pt, folded_h / pt])

	# The challenge as a call to action.
	hud.clear_all()
	hud.show_challenge("WYŚCIG · PANI HALINA", Color("#ff6fa8"), "RACE · PANI HALINA", "Mruga do ciebie! Dotknij albo L",
			"Flashing you! Tap or L to race")
	hud._layout()
	_tick(hud, b, 0.1)
	var ch: Button = hud._challenge
	_expect(ch.visible, "the challenge isn't on screen")
	_expect(ch.size.y >= hud.CTA_H * pt - 0.5, "the challenge is %.0f pt tall, not a call to action" % (ch.size.y / pt))
	_expect(String((ch.get_child(0).get_child(0) as Label).text).contains("HALINA"), "the challenge doesn't name the racer")
	_expect(ch.scale.x > 1.05, "the challenge didn't pop in")
	_tick(hud, b, 1.0)
	_expect(ch.scale.x < 1.05, "the challenge kept growing")

	# The road ahead.
	hud.clear_all()
	b.clear()
	hud.set_speed(0)
	_expect(hud.keep_clear_rects().is_empty(), "the road ahead is kept clear while parked")
	hud.set_speed(60)
	hud.update_minimap(Vector2.ZERO, 0.0, 0.0)
	var ahead: Array[Rect2] = hud.keep_clear_rects()
	_expect(ahead.size() == 3, "%d boxes on the road ahead, not 3" % ahead.size())
	for r in ahead:
		_expect(r.get_center().y < mid.y, "a box on the road ahead isn't ahead of the car (%s)" % r)
	b.chatter.context = 0
	var ahead_at := Vector3(mid.x, mid.y - 140.0 * pt, 0.0)
	b.say(func() -> Vector3: return ahead_at, "Darek", "Za mną, w lewo przy Rondzie!", "Follow me, left at the roundabout!")
	var placed: Array = b.layout()
	_expect(placed.size() == 1, "the partner's bubble found no room (%d up, %d waiting)" % [b.count(), b.overlaps])
	if placed.size() == 1:
		var rect: Rect2 = placed[0][2]
		for r in ahead:
			_expect(not rect.intersects(r), "the partner's bubble %s covers the road ahead %s" % [rect, r])
	print(hud.messages.summary())
	print(b.chatter.summary())
	vp.queue_free()
