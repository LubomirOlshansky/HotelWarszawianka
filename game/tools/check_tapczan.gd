extends SceneTree
## THE TAPCZAN (tapczan.gd, tapczan_room.gd, tapczan_ui.gd, pong_sim.gd, pong_match.gd, tipsy.gd,
## data/tapczan.json), without the city:
##  1. the words: every "ui" key the scripts ask for, each rival's name, short, stake, the v2 table
##     (balls, sd, flick, swat, half, in_r, rim_r, glass, how, and the late / reset / bonus fields
##     where they apply; no skill, p_in or p_rim left) and its story lines, the people's names and
##     lines, the regulars, ten+ tipsy thoughts; each a [Polish, English] pair, none empty, bubbles
##     at most 150 characters, no denylisted brand, every pub UI letter in the 5x7 font;
##  2. beer pong v2's sim (docs/design/tapczan-pong-v2-physics-and-fun.md 5.4): the bots' win
##     rates in their bands (decent: crew 55-71 %, Gienia 40-56 %, Hubert 22-38 %, in that order;
##     the expert 10+ points over the decent against each), an idle finger wins none (every ball a
##     slip), a masher under 15 % against the crew, the decent mean length 40-65 s, none over 150 s,
##     every match to DONE; determinism; the ring is the truth (a lob and a bounce cross the mouth
##     plane within 0.01 px of the ring); the forced cases (clean and back once a turn, in, a rim
##     dropping or not by the roll, a flicked spinner never drops, a lip tick takes nothing, a cup's
##     side shoves the cup 0.5-2.5 px and never nearer than 9, a bounce-in takes two with no ball
##     back, the swat with eyes on and not off, a spent ball only inside 0.6 of the mouth); the turn
##     (one lung for the turn's balls, a gasp at zero, a carried press does not hold, a slip at
##     5 s); the match (the dare is a middle cup and a spin on it is flicked, the karniak takes a
##     rival ball, heat rises, empties and widens the core, the re-rack once a side, Gienia wakes at
##     three cups and at round 4, her nudge cancelled by an early throw and landing after a late
##     one, Hubert's re-set and his third ball after a blank turn, last orders count cups, sudden
##     death, a draw); `lost` is the cups the rival took; start_drinks widens the wobble;
##  3. the tipsy spell (tipsy.gd): the fade from the start to 0 at LONG, the pull wanders both ways;
##     the double-vision screen pass off at Low (tiers.gd screen_fx) and on at every higher level,
##     the camera's sway there at every level;
##  4. the room: its mesh builds (under 30k triangles), people to tap; the pixel UI on the ROOT
##     viewport (not the city's SubViewport: the 2x bug), its unit min(h / 216, 2 pt), every tile
##     and board row at least 44 pt to touch, the tiles open the board and the rival card;
##  5. the door (tapczan.gd on the activity kit, with stand-ins): the ring only near, the WEJDŹ pill
##     only stopped at the kerb, the pill starts the run (HUD hidden, the car's process off), a pint
##     costs its price and makes the drive tipsy, short of money the visit's first glass is on the
##     house and the second refused, the bar stops at four, a won game pays its stake, WYJDŹ ends the
##     run (HUD and car back, the tipsy spell on), the QUESTS entry at the door;
##  6. the sounds (with Fakes.Sfx): the pub's bed on inside and off after, a pour sounds;
##  7. the view: pong_match.gd plays a whole match by itself (auto_play) to `finished` and `closed`.
## Prints `check_tapczan: OK`, or the problems and their count (exit 1). About ten seconds.
##   godot --headless --path game --script res://tools/check_tapczan.gd

const Sim := preload("res://scripts/pong_sim.gd")
const Room := preload("res://scripts/tapczan_room.gd")
const Tiers := preload("res://scripts/tiers.gd")
const Tipsy := preload("res://scripts/tipsy.gd")
const Tapczan := preload("res://scripts/tapczan.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")
const PongMatch := preload("res://scripts/pong_match.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

## Every "ui" key the scripts read (tapczan.gd, tapczan_room.gd, tapczan_ui.gd, pong_match.gd, tipsy.gd).
const UI_KEYS := ["enter", "title", "leave", "pick", "back", "broke", "full", "taps_head", "taps_sub", "bill", "sip",
		"board", "drunk_toast", "drunk_over", "won", "lost", "rerack", "drink_up", "cup", "rim_in", "rim_out", "miss",
		"done", "quest_title", "hint", "hint_low", "clean", "flick_hint", "flicked", "round", "last_orders", "sudden",
		"draw", "breath", "rematch", "total", "tile_beer", "tile_play", "tile_leave", "bill_chip", "wallet_chip",
		"bounce_in", "swat", "dare", "karniak", "heat2", "heat3", "fluke", "gasp", "slip", "too_far", "you",
		"receipt_cups", "receipt_stake", "receipt_drunk", "receipt_respect", "last_won", "last_lost"]
## Lines every rival has: the hello, a hit and a miss, their win and loss, and the story (addendum 3.8).
const RIVAL_LINES := ["hello", "hit", "miss", "win", "lose", "you_lead", "they_lead", "last_cup", "again_won", "again_lost"]
const RIVAL_FIELDS := ["balls", "sd", "flick", "swat", "half", "in_r", "rim_r", "glass", "how", "stake"]
## The bands (addendum 5.4), matches a cell.
const GAMES := 300
const BANDS := {"office": Vector2(55, 71), "first": Vector2(40, 56), "sommelier": Vector2(22, 38)}

var _bad := 0


## After the tree is up (the room and the door need a viewport).
func _initialize() -> void:
	await process_frame
	_words()
	_ladder()
	_physics()
	_turn_and_match()
	_tipsy()
	_room_and_door()
	_view()
	if _bad == 0:
		print("check_tapczan: OK")
		quit(0)
	else:
		print("check_tapczan: %d problem(s)" % _bad)
		quit(1)


func _fail(msg: String) -> void:
	_bad += 1
	print("check_tapczan: " + msg)


func _pair_ok(where: String, p: Variant, longest := 150) -> void:
	if not (p is Array) or (p as Array).size() < 2 or str(p[0]).strip_edges() == "" or str(p[1]).strip_edges() == "":
		_fail("%s: not a [Polish, English] pair: %s" % [where, p])
		return
	for s: String in [str(p[0]), str(p[1])]:
		if s.length() > longest:
			_fail("%s: longer than %d: %s" % [where, longest, s])
		for brand: String in _denylist():
			if s.to_lower().contains(brand):
				_fail("%s: a denylisted brand (%s): %s" % [where, brand, s])


## Every letter of a pub line drawn by the 5x7 font (tapczan_ui.gd, pong_match.gd upper-case it).
func _font_ok(where: String, p: Variant) -> void:
	if not (p is Array):
		return
	for s: String in [str(p[0]), str(p[1])]:
		for ch in s.to_upper().replace("\"", "”"):
			if ch != " " and PixelFont.char_width(ch) == 0 and ch != "\n" and ch != "%":
				_fail("%s: the pixel font has no '%s': %s" % [where, ch, s])
				return


var _deny: Array = []
func _denylist() -> Array:
	if _deny.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
		if d is Dictionary:
			for k: String in d:
				if d[k] is Array:
					for b: Variant in d[k]:
						if b is String and (b as String).length() >= 4:
							_deny.append((b as String).to_lower())
		_deny.append("slack")
	return _deny


# --- 1. the words --------------------------------------------------------------------------------

func _words() -> void:
	var d := Room.data()
	if d.is_empty():
		_fail("data/tapczan.json did not load")
		return
	var ui: Dictionary = d.get("ui", {})
	for k: String in UI_KEYS:
		if not ui.has(k):
			_fail("ui: no \"%s\"" % k)
		else:
			_pair_ok("ui." + k, ui[k], 400)
	for k: String in ui:
		if k.begins_with("quest_") or k in ["door", "drink", "play", "stake_btn", "price", "bill_add", "drunk_toast", "drunk_over", "bill", "cups", "drinks", "their_turn"]:
			continue
		_font_ok("ui." + k, ui[k])
	for id: String in Room.RIVALS:
		var r := Room.rival(id)
		if r.is_empty():
			_fail("rival %s: missing" % id)
			continue
		_pair_ok(id + ".name", r.get("name"))
		_pair_ok(id + ".short", r.get("short"))
		_pair_ok(id + ".how", r.get("how"))
		_font_ok(id + ".short", r.get("short"))
		_font_ok(id + ".how", r.get("how"))
		for f: String in RIVAL_FIELDS:
			if not r.has(f):
				_fail("rival %s: no \"%s\" (addendum 5.5)" % [id, f])
		for f: String in ["skill", "late_skill", "p_in", "p_rim"]:
			if r.has(f):
				_fail("rival %s: the old field \"%s\" is still there" % [id, f])
		var keys: Array = RIVAL_LINES.duplicate()
		if r.has("late"):
			keys.append_array(["wake_says", "nudge_says"])
		if bool(r.get("reset_after_hit", false)):
			keys.append("reset")
		if bool(r.get("bonus_on_blank", false)):
			keys.append("bonus")
		for k: String in keys:
			var lines: Array = r.get(k, [])
			if lines.is_empty():
				_fail("rival %s: no %s lines" % [id, k])
			for l: Variant in lines:
				_pair_ok("%s.%s" % [id, k], l)
				_font_ok("%s.%s" % [id, k], l)
	var regs: Array = d.get("regulars", [])
	if regs.size() < 8:
		_fail("regulars: %d lines, want 8" % regs.size())
	for l: Variant in regs:
		_pair_ok("regulars", l, 40)
		_font_ok("regulars", l)
	var people: Dictionary = d.get("people", {})
	for row: Array in [["barman"], ["beard"], ["students"], ["tourists"], ["couple"]]:
		var p: Dictionary = people.get(row[0], {})
		_pair_ok(str(row[0]) + ".name", p.get("name"))
		_font_ok(str(row[0]) + ".name", p.get("name"))
		for l: Variant in p.get("lines", []):
			_pair_ok(str(row[0]) + ".line", l)
			_font_ok(str(row[0]) + ".line", l)
		if (p.get("lines", []) as Array).is_empty():
			_fail("%s: no lines" % row[0])
	var thoughts: Array = d.get("tipsy", [])
	if thoughts.size() < 10:
		_fail("tipsy: %d thoughts, want 10+" % thoughts.size())
	for l: Variant in thoughts:
		_pair_ok("tipsy", l, 70)
	# The TAP LIST: about six beers, each named, styled, with ABV, glass, price, a handle colour and
	# the barman's pick lines and the first sip's; one alcohol-free; strength grows with ABV.
	var taps: Array = Room.taps()
	if taps.size() < 5 or taps.size() > 8:
		_fail("taps: %d beers, want about six" % taps.size())
	var zero := false
	for t: Dictionary in taps:
		var id := str(t.get("id", ""))
		_pair_ok(id + ".name", t.get("name"))
		_pair_ok(id + ".style", t.get("style"))
		_font_ok(id + ".name", t.get("name"))
		_font_ok(id + ".style", t.get("style"))
		if int(t.get("price", 0)) <= 0 or int(t.get("ml", 0)) <= 0 or not t.has("abv") or not t.has("handle") or int(t.get("no", 0)) <= 0:
			_fail("tap %s: price, ml, abv, handle or number missing" % id)
		zero = zero or float(t.get("abv", 1.0)) == 0.0
		for k: String in ["pick", "sip"]:
			if (t.get(k, []) as Array).is_empty():
				_fail("tap %s: no %s lines" % [id, k])
			for l: Variant in t.get(k, []):
				_pair_ok("%s.%s" % [id, k], l, 150)
				_font_ok("%s.%s" % [id, k], l)
	if not zero:
		_fail("taps: no alcohol-free beer")
	if Room.strength(Room.tap("stout")) <= Room.strength(Room.tap("lager")):
		_fail("a stout should be stronger than the lager")
	for l: Variant in d.get("refusals", []):
		_pair_ok("refusals", l, 150)
		_font_ok("refusals", l)
	if (d.get("refusals", []) as Array).is_empty():
		_fail("no refusals for the broke")
	for l: Variant in d.get("house", []):
		_pair_ok("house", l, 150)
		_font_ok("house", l)
	if (d.get("house", []) as Array).is_empty():
		_fail("no barman's line for the first glass on the house")
	# The memes: every board in the room has its words (Polish pixel lines, the tap's pair).
	var memes := {}
	for m: Dictionary in d.get("memes", []):
		memes[str(m.get("id", ""))] = m
		_pair_ok("meme." + str(m.get("id", "")), m.get("say"), 150)
		_font_ok("meme." + str(m.get("id", "")), m.get("say"))
		if (m.get("world", []) as Array).is_empty():
			_fail("meme %s: no world lines" % m.get("id", ""))
	for mb: Array in Room.meme_boards():
		if not memes.has(str(mb[0])):
			_fail("meme board %s: no words in data" % mb[0])
	if not memes.has("wall"):
		_fail("meme wall: no words for BREW ENJOY EMPTY REPEAT")


# --- 2. beer pong v2: the ladder ---------------------------------------------------------------------

## A cell of seeded bot matches: [win %, mean s, longest s, stuck, mean lost].
func _cell(id: String, thumb: String, n: int, seed0 := 1000, drinks := 0) -> Array:
	var r := Room.rival(id)
	var won := 0
	var secs := 0.0
	var longest := 0.0
	var stuck := 0
	var lost := 0
	for i in n:
		var s: Sim = Sim.play_bot(r, thumb, seed0 + i, drinks)
		won += 1 if s.winner == 0 else 0
		var t := s.t * Sim.DT
		secs += t
		longest = maxf(longest, t)
		stuck += 1 if s.phase != Sim.DONE else 0
		lost += s.lost
		if thumb == "idle" and int(s.stats.get("throw", 0)) > 0:
			_fail("idle vs %s: a ball was thrown (seed %d)" % [id, seed0 + i])
	return [100.0 * won / n, secs / n, longest, stuck, float(lost) / n]


func _ladder() -> void:
	var line := "check_tapczan: decent / expert win %% of %d:" % GAMES
	var dec := {}
	for id: String in ["office", "first", "sommelier"]:
		var d := _cell(id, "decent", GAMES)
		var e := _cell(id, "expert", GAMES)
		dec[id] = float(d[0])
		line += " %s %.0f/%.0f (%.0f s)" % [id, d[0], e[0], d[1]]
		var band: Vector2 = BANDS[id]
		if float(d[0]) < band.x or float(d[0]) > band.y:
			_fail("decent vs %s: %.1f%%, want %d-%d%%" % [id, d[0], int(band.x), int(band.y)])
		if float(e[0]) < float(d[0]) + 10.0:
			_fail("expert vs %s: %.1f%%, want 10+ over the decent's %.1f%%" % [id, e[0], d[0]])
		if float(d[1]) < 40.0 or float(d[1]) > 65.0:
			_fail("decent vs %s: mean %.1f s, want 40-65 s" % [id, d[1]])
		for c: Array in [d, e]:
			if float(c[2]) > 150.0 or int(c[3]) > 0:
				_fail("vs %s: longest %.0f s, %d stuck (want none over 150 s, none stuck)" % [id, c[2], c[3]])
	print(line)
	if not (dec["office"] > dec["first"] and dec["first"] > dec["sommelier"]):
		_fail("the ladder: crew > Gienia > Hubert, got %s" % dec)
	var idle := _cell("office", "idle", 60)
	if float(idle[0]) > 0.0:
		_fail("an idle finger won %.1f%%" % idle[0])
	var mash := _cell("office", "masher", 200)
	if float(mash[0]) >= 15.0:
		_fail("a masher wins %.1f%% against the crew, want under 15%%" % mash[0])
	# Determinism: the same seed and input give the same events twice.
	var lists: Array = []
	for k in 2:
		var s := Sim.new(77, Room.rival("first"))
		s.bot_setup("decent", 99)
		var names := PackedStringArray()
		while s.phase != Sim.DONE and s.t < 400 * Sim.HZ:
			var f := s.bot_finger()
			s.tick(bool(f[0]), bool(f[1]))
			for e: Dictionary in s.events:
				names.append(str(e["name"]))
			s.events.clear()
		lists.append(names)
	if lists[0] != lists[1] or (lists[0] as PackedStringArray).size() < 20:
		_fail("determinism: two runs of seed 77 differ (%d / %d events)" % [(lists[0] as PackedStringArray).size(), (lists[1] as PackedStringArray).size()])
	# `lost` is the cups the rival took; pints at the bar widen the wobble, shorten the lung, are not reported.
	var m: Sim = Sim.play_bot(Room.rival("office"), "decent", 5)
	if m.lost != Sim.CUPS - m.cups_me.size() and m.sudden == 0:
		_fail("lost %d but %d cups gone" % [m.lost, Sim.CUPS - m.cups_me.size()])
	var sober := Sim.new(3, Room.rival("office"), 0)
	var two := Sim.new(3, Room.rival("office"), 2)
	if two.wobble_amp() <= sober.wobble_amp() or two.lung_full() >= sober.lung_full() or two.lost != 0:
		_fail("start_drinks: wobble %.2f vs %.2f, lung %.2f vs %.2f, lost %d" % [two.wobble_amp(), sober.wobble_amp(), two.lung_full(), sober.lung_full(), two.lost])


# --- 2. beer pong v2: the physics, the turn, the match -------------------------------------------

## A fresh sim mid-turn, your ball about to leave: eyes off unless `watch`, the roll forced or not.
func _fresh(id := "office", rival_over: Dictionary = {}, watch := false, roll := -1.0) -> Sim:
	var r := Room.rival(id).duplicate(true)
	r.merge(rival_over, true)
	if watch:
		r.erase("away_every")
	var s := Sim.new(11, r)
	s.thrower = Sim.ME
	s.balls = 0
	s.busy_until = 0 if watch else 1 << 30
	s.force_roll = roll
	s.round_no = 1
	return s


## One ball of yours from the ring at x_t to its end: the events' names.
func _throw(s: Sim, x_t: float, low := false) -> PackedStringArray:
	s.events.clear()
	s.launch(x_t, low)
	var n := 0
	while s.phase in [Sim.FLIGHT, Sim.SPIN] and n < 600:
		s.tick()
		n += 1
	var out := PackedStringArray()
	for e: Dictionary in s.events:
		out.append(str(e["name"]))
	return out


func _physics() -> void:
	# The ring is the truth: a lob and a bounce cross the mouth plane where the ring was.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var worst := 0.0
	for k in 50:
		var x_t := rng.randf_range(-10.0, 70.0)
		for low: bool in [false, true]:
			var s := _fresh()
			s.cups_them = PackedFloat64Array()
			s.ids_them = PackedInt32Array()
			_throw(s, x_t, low)
			if is_nan(s.mouth_x):
				_fail("ring: the %s at %.1f never crossed the mouth plane" % ["bounce" if low else "lob", x_t])
			else:
				worst = maxf(worst, absf(s.mouth_x - x_t))
	if worst > 0.01:
		_fail("the ring is not the truth: %.4f px off" % worst)
	# d 0: clean and the ball back, once a turn only.
	var s := _fresh()
	var ev := _throw(s, 0.0)
	if not ("clean" in ev and "back" in ev) or s.balls != 1 or s.cups_them.size() != 4:
		_fail("d 0: %s, balls %d, cups %d" % [ev, s.balls, s.cups_them.size()])
	s.phase = Sim.AIM
	ev = _throw(s, s.cups_them[0])
	if not "clean" in ev or "back" in ev:
		_fail("a second clean in the turn should not bring the ball back: %s" % ev)
	# d 1.5: in. d 2.5: a rim, dropping or not by the roll; a flicked one never drops.
	s = _fresh()
	ev = _throw(s, 1.5)
	if not "in" in ev or s.cups_them.size() != 4:
		_fail("d 1.5: %s" % ev)
	s = _fresh("office", {}, false, 0.0)
	ev = _throw(s, 2.5)
	if not ("rim" in ev and "rim_in" in ev) or s.cups_them.size() != 4:
		_fail("d 2.5, roll 0: %s" % ev)
	s = _fresh("office", {}, false, 0.99)
	ev = _throw(s, 2.5)
	if not ("rim" in ev and "rim_out" in ev) or s.cups_them.size() != 5:
		_fail("d 2.5, roll 0.99: %s" % ev)
	s = _fresh("office", {"flick": 1.0}, false, 0.0)
	ev = _throw(s, 2.5)
	if not "flicked" in ev or "rim_in" in ev or s.cups_them.size() != 5:
		_fail("a flicked spinner should never drop: %s" % ev)
	# d 4.5 on the far cup: a lip tick, nothing taken.
	s = _fresh()
	ev = _throw(s, 56.0 + 4.5)
	if not "rim_tick" in ev or s.cups_them.size() != 5:
		_fail("d 4.5: %s" % ev)
	# d -8 before the second cup: its side; shoved 0.5-2.5 px, never nearer than 9.
	s = _fresh()
	var before := s.cups_them[1]
	s.events.clear()
	s.launch(14.0 - 8.0, false)
	var slide := 0.0
	while s.phase in [Sim.FLIGHT, Sim.SPIN]:
		s.tick()
		for e: Dictionary in s.events:
			if str(e["name"]) == "body" and slide == 0.0:
				slide = absf(float(e["slide"]))
		s.events.clear()
	if slide < 0.5 - 1e-6 or slide > 2.5 + 1e-6 or is_equal_approx(s.cups_them[1], before):
		_fail("d -8: a side hit should shove the cup 0.5-2.5 px (slid %.2f)" % slide)
	for i in s.cups_them.size() - 1:
		if s.cups_them[i + 1] - s.cups_them[i] < Sim.MIN_GAP - 1e-6:
			_fail("cups %d and %d closer than %.0f" % [i, i + 1, Sim.MIN_GAP])
	# A bounce at d 0 on the front cup: two cups, no ball back.
	s = _fresh()
	ev = _throw(s, 0.0, true)
	if not ("bounce_in" in ev and "domino" in ev) or "back" in ev or s.cups_them.size() != 3:
		_fail("a bounce at d 0: %s, %d cups" % [ev, s.cups_them.size()])
	# The swat: eyes on with swat 1, yes; eyes off, no.
	s = _fresh("office", {"swat": 1.0}, true)
	ev = _throw(s, 0.0, true)
	if not "swat" in ev:
		_fail("a bounce with swat 1 and eyes on should be swatted: %s" % ev)
	s = _fresh("office", {"swat": 1.0}, false)
	ev = _throw(s, 0.0, true)
	if "swat" in ev:
		_fail("eyes off: no swat (%s)" % ev)
	# A spent ball takes a cup only inside 0.6 of the mouth (a fluke).
	for d: float in [1.0, 1.5]:
		s = _fresh()
		s.events.clear()
		s.launch(0.0, false)
		s.bx = d
		s.by = Sim.RIM_Y
		s.bvy = -100.0
		s.b_fresh = false
		var took := s._at_mouth()
		if took != (d <= Sim.IN_R * Sim.FLUKE_IN):
			_fail("a spent ball at %.1f px: took %s" % [d, took])


## Ticks until the sim is aiming (your ball) with the finger as given; false if it never was.
func _to_aim(s: Sim, finger := false, cap := 600) -> bool:
	var n := 0
	while not (s.phase == Sim.AIM and s.thrower == Sim.ME) and n < cap:
		s.tick(finger)
		n += 1
	if not finger:
		s.tick(false)  # the finger up once in the aim: armed
	return s.phase == Sim.AIM


func _turn_and_match() -> void:
	# One lung for the turn: hold 0.4 s, throw wide, and the second ball starts with what is left.
	var s := Sim.new(21, Room.rival("office"))
	_to_aim(s)
	var full := s.lung
	for k in 24:
		s.tick(true)
	s.tick(false)
	s.force_roll = 0.99
	while s.phase != Sim.AIM and s.thrower == Sim.ME and s.phase != Sim.DONE:
		s.tick(false)
	if s.phase == Sim.AIM and s.thrower == Sim.ME and not s.back_used and s.lung > full - 0.35:
		_fail("the lung should not refill between a turn's balls: %.2f of %.2f" % [s.lung, full])
	# A gasp at zero.
	s = Sim.new(22, Room.rival("office"))
	_to_aim(s)
	var gasp := false
	for k in 200:
		s.tick(true)
		for e: Dictionary in s.events:
			gasp = gasp or str(e["name"]) == "gasp"
		s.events.clear()
		if s.phase != Sim.AIM:
			break
	if not gasp or s.lung > 0.0:
		_fail("holding past the lung should gasp (lung %.2f)" % s.lung)
	# A press carried over from before the ball does not hold.
	s = Sim.new(23, Room.rival("office"))
	_to_aim(s, true)
	for k in 30:
		s.tick(true)
	if s.held > 0.0 or s.armed:
		_fail("a carried press should not hold (held %.2f)" % s.held)
	# A slip at 5 s.
	s = Sim.new(24, Room.rival("office"))
	_to_aim(s)
	s.events.clear()
	for k in int(Sim.SHOT_CLOCK * Sim.HZ) + 2:
		s.tick(false)
	if not s.events.any(func(e: Dictionary) -> bool: return str(e["name"]) == "slip"):
		_fail("no throw in 5 s should slip")
	# The dare: a middle cup; a spin on it is flicked; a drop on it is a karniak, a rival ball fewer.
	s = Sim.new(25, Room.rival("office"))
	_to_aim(s)
	var k := s.ids_them.find(s.dare_id)
	if k < 1 or k > s.ids_them.size() - 2:
		_fail("the dare should be a middle cup (index %d)" % k)
	var dx := s.cups_them[k]
	s.busy_until = 1 << 30
	var ev := _throw(s, dx + 2.5)
	if not "flicked" in ev:
		_fail("a spin on the dared cup should be flicked: %s" % ev)
	s.phase = Sim.AIM
	s.dare_id = s.ids_them[k]
	ev = _throw(s, s.cups_them[k])
	if not "karniak" in ev or not s.karniak or s.heat != Sim.HEAT_MAX:
		_fail("a drop on the dared cup should be a karniak: %s" % ev)
	s.balls = 0
	s._end_turn()
	if s.balls != int(Room.rival("office")["balls"]) - 1:
		_fail("after a karniak the crew should throw %d balls, got %d" % [int(Room.rival("office")["balls"]) - 1, s.balls])
	# Heat: rises with cups, widens the core, empties on a miss.
	s = _fresh()
	var c0 := s.clean_r()
	_throw(s, 1.5)
	if s.heat != 1 or s.clean_r() <= c0:
		_fail("heat after a cup: %d, core %.2f" % [s.heat, s.clean_r()])
	s.phase = Sim.AIM
	_throw(s, -80.0)
	if s.heat != 0:
		_fail("a miss should empty the heat: %d" % s.heat)
	# The re-rack at two, once a side.
	s = _fresh()
	var rr := 0
	for n in 3:
		s.phase = Sim.AIM
		for e: String in _throw(s, s.cups_them[0] + 1.5):
			rr += 1 if e == "rerack" else 0
	if rr != 1 or s.cups_them.size() != 2 or not is_equal_approx(s.cups_them[0], 21.0):
		_fail("the re-rack at two: %d times, cups %s" % [rr, s.cups_them])
	s.phase = Sim.AIM
	_throw(s, s.cups_them[0] + 1.5)
	if s.cups_them.size() != 1:
		_fail("down to one: %s" % s.cups_them)
	# Pani Gienia: awake at three cups, and at round 4.
	s = _fresh("first")
	for n in 2:
		s.phase = Sim.AIM
		_throw(s, s.cups_them[0] + 1.5)
	if not s.awake:
		_fail("Gienia should wake at three cups")
	s = Sim.new(26, Room.rival("first"))
	s.round_no = 3
	s._start_round()
	if not s.awake:
		_fail("Gienia should wake at round 4")
	# Her nudge: a throw before her hand moves cancels it; one after it lands under the ball.
	for early: bool in [true, false]:
		s = Sim.new(27, Room.rival("first"))
		s.awake = true
		_to_aim(s)
		s.nudge_at = 60
		var rel := 10 if early else 40
		var before := s.cups_them[0]
		while s.aim_t < rel - 1:
			s.tick(true)
		s.tick(false)
		var n := 0
		while s.phase in [Sim.FLIGHT, Sim.SPIN] and n < 400:
			s.tick(false)
			n += 1
		var moved := not is_equal_approx(s.cups_them[0] if s.cups_them.size() == 5 else before, before)
		var nudged := int(s.stats.get("nudge", 0)) > 0
		if nudged == early:
			_fail("Gienia's nudge: thrown at %d ticks, nudged %s" % [rel, nudged])
		if early and moved:
			_fail("an early throw should keep her cups still")
	# Pan Hubert: the re-set after a hit (eyes off), the third ball after a blank turn.
	s = _fresh("sommelier", {}, true)
	ev = _throw(s, 0.0)
	if not "reset" in ev or not s.rival_busy():
		_fail("Hubert should re-set his glasses after a hit: %s" % ev)
	s = _fresh("sommelier")
	s.turn_takes = 0
	s._end_turn()
	if s.balls != 3 or int(s.stats.get("bonus", 0)) != 1:
		_fail("a blank turn should give Hubert a third ball: %d" % s.balls)
	# Last orders after six rounds count cups; level: sudden death; level after it: a draw.
	s = Sim.new(28, Room.rival("office"))
	s.round_no = Sim.ROUNDS
	s.cups_me.remove_at(0)
	s.ids_me.remove_at(0)
	s._start_round()
	if s.winner != Sim.THEM or s.end != "bell":
		_fail("last orders with fewer cups of yours: winner %d (%s)" % [s.winner, s.end])
	s = Sim.new(29, Room.rival("office"))
	s.round_no = Sim.ROUNDS
	s._start_round()
	if s.sudden != 1 or s.balls != 1 or s.dare_id >= 0:
		_fail("level at the bell: sudden death, one ball, no dare (sudden %d, balls %d)" % [s.sudden, s.balls])
	s.sudden = Sim.SUDDEN
	s.thrower = Sim.THEM
	s.sudden_hit = [false, false]
	s._end_turn()
	if s.winner != 2 or s.end != "draw":
		_fail("still level after sudden death: a draw (winner %d)" % s.winner)
	s = Sim.new(30, Room.rival("office"))
	s.sudden = 1
	s.thrower = Sim.THEM
	s.sudden_hit = [true, false]
	s._end_turn()
	if s.winner != Sim.ME or s.end != "sudden":
		_fail("sudden death: you hit, they missed: winner %d" % s.winner)


# --- 3. tipsy --------------------------------------------------------------------------------------

func _tipsy() -> void:
	if absf(Tipsy.fade(1.0, 0.0) - 1.0) > 0.001 or Tipsy.fade(1.0, Tipsy.LONG) > 0.001:
		_fail("tipsy fade: %.3f at 0, %.3f at LONG" % [Tipsy.fade(1.0, 0.0), Tipsy.fade(1.0, Tipsy.LONG)])
	if Tipsy.fade(1.0, Tipsy.LONG * 0.5) <= Tipsy.fade(1.0, Tipsy.LONG * 0.8):
		_fail("tipsy should fade")
	var lo := 0.0
	var hi := 0.0
	for k in 600:
		var p := Tipsy.pull_at(1.0, k * 0.1)
		lo = minf(lo, p)
		hi = maxf(hi, p)
	if lo > -0.05 or hi < 0.05 or maxf(-lo, hi) > Tipsy.PULL * 1.5:
		_fail("tipsy pull should wander both ways, gently: %.3f .. %.3f" % [lo, hi])
	# Perf audit: the screen read (hint_screen_texture) is skipped at Low; the free parts stay.
	if Tipsy.screen_pass(Tiers.LOW):
		_fail("tipsy: the double-vision pass should be off at Low")
	for q in [Tiers.MEDIUM, Tiers.HIGH, Tiers.ULTRA, Tiers.EXPERIMENTAL]:
		if not Tipsy.screen_pass(q):
			_fail("tipsy: the double-vision pass should be on at %s" % Tiers.NAMES[q])
	var tp := Tipsy.new()
	tp.amount = 1.0
	tp._t = 1.0
	for q in [Tiers.LOW, Tiers.HIGH]:
		tp.level = q
		if tp.sway(Transform3D.IDENTITY).is_equal_approx(Transform3D.IDENTITY):
			_fail("tipsy: the camera should sway at %s" % Tiers.NAMES[q])
	tp.free()


# --- 4, 5. the room and the door -----------------------------------------------------------------

func _room_and_door() -> void:
	var mesh := Room.room_mesh()
	var tris := 0
	for i in mesh.get_surface_count():
		tris += (mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	if tris <= 0 or tris > 30000:
		_fail("room mesh: %d triangles" % tris)
	print("check_tapczan: room mesh %d triangles" % tris)
	var world := Node3D.new()
	root.add_child(world)
	var hud := Fakes.Hud.new()
	var wallet := Fakes.Wallet.new()
	wallet.money = 100
	var map := Fakes.FlatMap.new()
	var car := Node3D.new()
	car.set_script(null)
	for node: Node in [hud, wallet, map, car]:
		world.add_child(node)
	# The car's place and speed in one box (a lambda keeps its own copy of a plain local).
	var car_at := {"pos": Vector3(10000, 0, 10000), "kmh": 0.0}
	var t := Tapczan.new()
	t.hud = hud
	t.wallet = wallet
	t.map = map
	t.vehicle = func() -> Array: return [car_at["pos"], car_at["kmh"], false]
	t.world_node = world
	t._car_body = car
	world.add_child(t)
	t.setup(world)
	var sfx := Fakes.Sfx.new()
	world.add_child(sfx)
	t.sfx = sfx
	t.set_process(false)
	var director := Activities.new()
	director.add(t)
	var ring := Tapczan.ring_point()
	var step := func(s: float) -> void:
		for k in roundi(s / 0.05):
			t._process(0.05)
	step.call(0.5)
	if t._mark_on or hud.pill_shown(Tapczan.PILL):
		_fail("far away: no ring, no pill")
	car_at["pos"] = Vector3(ring.x + 60.0, 0, ring.y)
	car_at["kmh"] = 30.0
	step.call(0.5)
	if not t._mark_on:
		_fail("60 m off: the ring should glow")
	car_at["pos"] = Vector3(ring.x + 3.0, 0, ring.y)
	step.call(0.5)
	if hud.pill_shown(Tapczan.PILL):
		_fail("driving past at 30 km/h: no pill")
	car_at["kmh"] = 0.0
	step.call(0.5)
	if not hud.pill_shown(Tapczan.PILL) or hud.pill_word != str(Room.pair("enter")[0]):
		_fail("stopped by the ring: the WEJDŹ pill (%s)" % hud.pill_word)
	# The fake's pill_free answers like hud.gd's while a pill is up: not free for another.
	hud.pill_free = false
	step.call(1.0)
	if not hud.pill_shown(Tapczan.PILL):
		_fail("the WEJDŹ pill should stay up while stopped (it hid itself)")
	hud.pill_free = true
	hud.context_pressed.emit(Tapczan.PILL)
	if t.phase != Activity.Phase.RUN or not t.inside() or hud.visible or car.process_mode != Node.PROCESS_MODE_DISABLED:
		_fail("the pill should take the player in (phase %d, inside %s)" % [t.phase, t.inside()])
	if hud.pill_shown(Tapczan.PILL):
		_fail("inside: the pill should go")
	if not sfx.pub_on:
		_fail("inside: the pub's bed should play (sfx.gd pub_bed)")
	# The TAP LIST: WYPIJ PIWKO opens it; a beer's price goes out of the wallet and onto the bill;
	# short of money is a refusal with nothing poured; the alcohol-free adds no tipsiness.
	# The pixel UI: on the root viewport (not the city image's SubViewport, Fable's 2x finding), its
	# unit min(h / 216, 2 pt), the tiles open the board and the rival card, every target 44 pt+.
	var ui = t.room._ui
	if ui.get_viewport() != root:
		_fail("the pub's UI should be on the root viewport")
	var vs: Vector2 = root.get_visible_rect().size
	if absf(ui.u - minf(vs.y / 216.0, 2.0 * ui.pt)) > 0.001:
		_fail("the UI unit: %.3f" % ui.u)
	ui.anchors = {"beer": Vector3.ZERO, "play": Vector3.ZERO, "leave": Vector3.ZERO}
	ui.project = func(_p: Vector3) -> Vector2: return vs * 0.5
	ui.layout()
	var least := 1e9
	for k: String in ui._rects:
		if k.begins_with("t:"):
			var r: Rect2 = ui._rects[k]
			least = minf(least, minf(r.size.x, r.size.y) * ui.u / ui.pt)
	if least < 43.9:
		_fail("a tile's touch area is %.1f pt, want 44+" % least)
	ui.tile.emit("beer")
	if not ui.taps_open:
		_fail("PIWKO should open the tap list")
	ui.layout()
	for k: String in ui._rects:
		if k.begins_with("r:") or k == "close":
			var r: Rect2 = ui._rects[k]
			if minf(r.size.x, r.size.y) * ui.u / ui.pt < 43.9:
				_fail("the board's %s: %.1f pt to touch, want 44+" % [k, minf(r.size.x, r.size.y) * ui.u / ui.pt])
	var row: Rect2 = ui._rects.get("r:lager", Rect2())
	var cash := wallet.money
	if not ui.press((row.position + row.size * 0.5) * ui.u) or t.room.pints != 1 or ui.taps_open:
		_fail("a tap on the board's row should pour it (pints %d)" % t.room.pints)
	t.room.pints = 0
	t.room.bill = 0
	wallet.money = cash
	ui.tile.emit("play")
	if not ui.rivals_open or ui.rivals.size() != 3:
		_fail("GRAJ should open the rival card")
	ui.press(Vector2(1, vs.y - 1))
	if ui.rivals_open:
		_fail("a tap outside the card should close it")
	t.room.drink()
	if not ui.taps_open:
		_fail("WYPIJ PIWKO should open the tap list")
	# Short of money (0 zł): the visit's first glass is on the house (0 zł on the bill, the wallet
	# never below 0, the barman's "house" line), the second is refused, the bar still stops at four.
	wallet.money = 0
	if not t.room.order("neipa") or wallet.money != 0 or t.room.pints != 1 or t.room.bill != 0:
		_fail("0 zl, first glass: on the house (%d zl, %d pints, bill %d)" % [wallet.money, t.room.pints, t.room.bill])
	var said: String = t.room._ui.line_text
	if not (Room.data().get("house", []) as Array).any(func(p: Array) -> bool: return said == str(p[0]) or said == str(p[1])):
		_fail("the free glass should have the barman's house line: %s" % said)
	if t.room.order("lager") or wallet.money != 0 or t.room.pints != 1:
		_fail("0 zl, second glass: a refusal, nothing poured")
	wallet.money = 1000
	t.room.pints = Room.MAX_PINTS
	if t.room.order("lager") or wallet.money != 1000:
		_fail("four glasses: the bar stops")
	wallet.money = 100
	t.room.pints = 0
	t.room.bill = 0
	t.room.drink()
	var stout := Room.tap("stout")
	var price := int(stout.get("price", 0))
	if not t.room.order("stout") or wallet.money != 100 - price or t.room.pints != 1 or t.room.bill != price:
		_fail("a stout: %d zl left, %d pints, bill %d" % [wallet.money, t.room.pints, t.room.bill])
	if t.room._ui.taps_open:
		_fail("a pick should close the tap list")
	if not sfx.played.any(func(p: Array) -> bool: return p[0] == "beer_pour"):
		_fail("a pour should sound (beer_pour): %s" % [sfx.played])
	if t.room._ui.bill != price or t.room._ui.wallet != wallet.money:
		_fail("the bill chip should show %d zł: %d (wallet %d)" % [price, t.room._ui.bill, t.room._ui.wallet])
	var before := t.tipsy._start
	if not t.room.order("zero") or not is_equal_approx(t.tipsy._start, before):
		_fail("the alcohol-free should pour and add nothing to the tipsy spell")
	var spent := price + int(Room.tap("zero").get("price", 0))
	var keep := wallet.money
	wallet.money = 5
	if t.room.order("neipa") or wallet.money != 5 or t.room.pints != 2 or t.room.bill != spent:
		_fail("short of money: a refusal, nothing poured")
	wallet.money = keep
	t._on_pong(true, 120, 2)
	if wallet.money != keep + 120 or not "pong" in wallet.kinds:
		_fail("a won game should pay its stake: %d zl" % wallet.money)
	t.room.leave()
	if t.phase != Activity.Phase.IDLE or t.inside() or not hud.visible or car.process_mode != Node.PROCESS_MODE_INHERIT:
		_fail("WYJDŹ should end the run with the HUD and the car back")
	if sfx.pub_on:
		_fail("out: the pub's bed should stop")
	if not t.tipsy.on() or t.tipsy.amount < 0.9:
		_fail("a pint and two cups should make the drive tipsy: %.2f" % t.tipsy.amount)
	t.tipsy.set_level(Tiers.LOW)
	if t.tipsy._overlay.visible or not t.tipsy.on() or not t.tipsy.is_processing():
		_fail("at Low the spell should go on without its screen pass")
	t.tipsy.set_level(Tiers.HIGH)
	if not t.tipsy._overlay.visible:
		_fail("back at High the screen pass should return mid-spell")
	var e := t.quest_entry()
	if str(e["group"]) != "crawl" or (e["at"] as Vector2).distance_to(Tapczan.door()) > 0.1:
		_fail("the QUESTS entry: %s" % e)
	if not hud.markers.has("tapczan:door"):
		_fail("the maps' mark at the door")
	else:
		# F 2026-11-24: permanent on both maps, a beer mug named THE TAPCZAN (not in quest focus).
		var mk: Dictionary = hud.markers.owned("tapczan")[0]
		if int(mk["shape"]) != MapIcons.POI_MUG or str((mk["extra"] as Dictionary).get("name", "")) != "THE TAPCZAN":
			_fail("the pub's mark: a mug named THE TAPCZAN, got %s" % mk)
		for ctx in [MapMarkers.Context.FREE, MapMarkers.Context.AIR]:
			for view in [MapMarkers.View.MINIMAP, MapMarkers.View.FULL_MAP]:
				if not MapMarkers.shows(int(mk["layer"]), view, ctx):
					_fail("the pub's mark should show on both maps, free and in the air")
	t.tipsy._stop()
	t.room._ui_layer.queue_free()
	t.room.queue_free()


# --- 7. the view ---------------------------------------------------------------------------------

## pong_match.gd plays a whole match by itself (the expert against the crew, a seed it wins with):
## `finished` (won, the stake, the drinks) then `closed`; a draw would pay nothing.
func _view() -> void:
	var v := PongMatch.new()
	root.add_child(v)
	var got: Array = []
	var shut := [false]
	v.finished.connect(func(won: bool, st: int, dr: int) -> void: got.append([won, st, dr]))
	v.closed.connect(func() -> void: shut[0] = true)
	v.auto_play = true
	v.start("office", Room.rival("office"))
	var n := 0
	while v.inside and n < 6000:
		v._process(1.0 / 15.0)
		n += 1
	if got.size() != 1 or not shut[0]:
		_fail("the view: finished %s, closed %s after %d steps" % [got, shut[0], n])
	elif not bool(got[0][0]) or int(got[0][1]) != int(Room.rival("office")["stake"]) or int(got[0][2]) != v.sim.lost:
		_fail("the auto match should be won and paid: %s (lost %d)" % [got[0], v.sim.lost])
	else:
		print("check_tapczan: the view's auto match: won in %.0f s, %d cups lost" % [v.sim.t * Sim.DT, v.sim.lost])
	v.queue_free()
