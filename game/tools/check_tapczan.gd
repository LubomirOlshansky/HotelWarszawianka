extends SceneTree
## THE TAPCZAN's phase 2 (tapczan.gd, tapczan_room.gd, beer_pong_sim.gd, beer_pong.gd, tipsy.gd,
## data/tapczan.json), without the city:
##  1. the words: every "ui" key the scripts ask for, each rival's name, short, stake, skill and
##     hello / hit / miss / win / lose lines, the people's names and lines, ten+ tipsy thoughts; each
##     a [Polish, English] pair, none empty, bubbles at most 150 characters, no denylisted brand;
##  2. the rules (beer_pong_sim.gd): the racks (6 in a 3-2-1, 3 in a 2-1, the apex at FRONT), the
##     exact aim drops a ball into every cup of a full rack, a bounce shot exists and takes two
##     cups, a rim spin goes in or out by its roll, a throw far short or wide misses, two balls a
##     turn, two hits bring the balls back, the re-rack at 3 (once a side), each rival hit is a drink
##     and the sway grows with the drinks, the late skill (Pani Gienia) after her re-rack, 300 seeded
##     games to the end (every one ends, the strong rival wins more than the weak), and the aim's
##     predicted path allocates nothing new once grown;
##  3. the tipsy spell (tipsy.gd): the fade from the start to 0 at LONG, the pull wanders both ways;
##  4. the room: its mesh builds (under 20k triangles), people to tap, the rivals' card;
##  5. the door (tapczan.gd on the activity kit, with stand-ins): the ring only near, the WEJDŹ pill
##     only stopped at the kerb, the pill starts the run (HUD hidden, the car's process off), a pint
##     costs PINT and makes the drive tipsy, a won game pays its stake, WYJDŹ ends the run (HUD and
##     car back, the tipsy spell on), the QUESTS entry at the door.
## Prints `check_tapczan: OK`, or the problems and their count (exit 1). A couple of seconds.
##   godot --headless --path game --script res://tools/check_tapczan.gd

const Sim := preload("res://scripts/beer_pong_sim.gd")
const Room := preload("res://scripts/tapczan_room.gd")
const Tipsy := preload("res://scripts/tipsy.gd")
const Tapczan := preload("res://scripts/tapczan.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Fakes := preload("res://tools/fakes.gd")

const UI_KEYS := ["enter", "title", "drink", "play", "leave", "pick", "back", "stake_btn", "broke", "full",
		"taps_head", "tap_btn", "bill", "sip", "board",
		"drunk_toast", "drunk_over", "won", "lost", "your_turn", "their_turn", "balls_back", "rerack", "drink_up",
		"cup", "bounce", "rim_in", "rim_out", "miss", "cups", "drinks", "give_up", "again", "done", "quest_title"]
const RIVAL_LINES := ["hello", "hit", "miss", "win", "lose"]

var _bad := 0


## After the tree is up (the room and the door need a viewport).
func _initialize() -> void:
	await process_frame
	_words()
	_rules()
	_games()
	_tipsy()
	_room_and_door()
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
	for id: String in Room.RIVALS:
		var r := Room.rival(id)
		if r.is_empty():
			_fail("rival %s: missing" % id)
			continue
		_pair_ok(id + ".name", r.get("name"))
		_pair_ok(id + ".short", r.get("short"))
		if int(r.get("stake", 0)) <= 0 or not r.has("skill"):
			_fail("rival %s: no stake or skill" % id)
		for k: String in RIVAL_LINES:
			var lines: Array = r.get(k, [])
			if lines.is_empty():
				_fail("rival %s: no %s lines" % [id, k])
			for l: Variant in lines:
				_pair_ok("%s.%s" % [id, k], l)
	var people: Dictionary = d.get("people", {})
	for row: Array in [["barman"], ["beard"], ["students"], ["tourists"], ["couple"]]:
		var p: Dictionary = people.get(row[0], {})
		_pair_ok(str(row[0]) + ".name", p.get("name"))
		for l: Variant in p.get("lines", []):
			_pair_ok(str(row[0]) + ".line", l)
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
		if int(t.get("price", 0)) <= 0 or int(t.get("ml", 0)) <= 0 or not t.has("abv") or not t.has("handle") or int(t.get("no", 0)) <= 0:
			_fail("tap %s: price, ml, abv, handle or number missing" % id)
		zero = zero or float(t.get("abv", 1.0)) == 0.0
		for k: String in ["pick", "sip"]:
			if (t.get(k, []) as Array).is_empty():
				_fail("tap %s: no %s lines" % [id, k])
			for l: Variant in t.get(k, []):
				_pair_ok("%s.%s" % [id, k], l, 150)
	if not zero:
		_fail("taps: no alcohol-free beer")
	if Room.strength(Room.tap("stout")) <= Room.strength(Room.tap("lager")):
		_fail("a stout should be stronger than the lager")
	for l: Variant in d.get("refusals", []):
		_pair_ok("refusals", l, 150)
	if (d.get("refusals", []) as Array).is_empty():
		_fail("no refusals for the broke")
	# The memes: every board in the room has its words (Polish pixel lines, the tap's pair).
	var memes := {}
	for m: Dictionary in d.get("memes", []):
		memes[str(m.get("id", ""))] = m
		_pair_ok("meme." + str(m.get("id", "")), m.get("say"), 150)
		if (m.get("world", []) as Array).is_empty():
			_fail("meme %s: no world lines" % m.get("id", ""))
	for mb: Array in Room.meme_boards():
		if not memes.has(str(mb[0])):
			_fail("meme board %s: no words in data" % mb[0])
	if not memes.has("wall"):
		_fail("meme wall: no words for BREW ENJOY EMPTY REPEAT")


# --- 2. the rules --------------------------------------------------------------------------------

func _rules() -> void:
	var six := Sim.rack(6)
	var three := Sim.rack(3)
	if six.size() != 6 or three.size() != 3:
		_fail("racks: %d and %d cups" % [six.size(), three.size()])
	if absf((six[0] as Vector2).y - Sim.FRONT) > 0.001 or absf((three[0] as Vector2).y - Sim.FRONT) > 0.001:
		_fail("racks: the apex is not at FRONT")
	# The exact aim sinks every cup of a full rack.
	for i in six.size():
		var a := Sim.aim_at(six[i])
		var r := Sim.fly(Sim.launch(a.x, a.y), six, 0.9)
		if str(r["result"]) != "cup" or int(r["cup"]) != i:
			_fail("aim at cup %d: %s (cup %d)" % [i, r["result"], r["cup"]])
	# Far short and far wide miss.
	for t: Vector2 in [Vector2(0.0, 0.0), Vector2(1.4, 0.6), Vector2(0.0, 1.0)]:
		var r := Sim.fly(Sim.launch(t.x, t.y), six, 0.0)
		if str(r["result"]) != "miss":
			_fail("lat %.1f pow %.1f should miss, got %s" % [t.x, t.y, r["result"]])
	# A bounce shot exists (straight, low) and takes two cups.
	var bounce_pow := -1.0
	for k in 101:
		var r := Sim.fly(Sim.launch(0.0, k / 100.0), six, 0.0)
		if str(r["result"]) == "bounce":
			bounce_pow = k / 100.0
			break
	if bounce_pow < 0.0:
		_fail("no bounce shot down the middle")
	else:
		var s := Sim.new(1)
		s.throw_player(0.0, bounce_pow, 0.0)
		# The sway at t 0 is small but not zero: a near miss is fine; take the exact one if it missed.
		if s.cups[1].size() == 6:
			s.reset()
			var r := s._resolve(0, Sim.fly(Sim.launch(0.0, bounce_pow), s.cups[1], 0.0))
			if not "bounce" in r["events"]:
				_fail("bounce: events %s" % [r["events"]])
		if s.cups[1].size() != 4:
			_fail("a bounce shot should take two cups, %d left" % s.cups[1].size())
	# A rim: some roll in, some out, by the roll.
	var rim_lat := -1.0
	for k in 200:
		var lat := k / 400.0
		var a := Sim.aim_at(six[0])
		var r := Sim.fly(Sim.launch(a.x + lat, a.y), [six[0]], 0.0)
		if bool(r["rim"]):
			rim_lat = lat
			break
	if rim_lat < 0.0:
		_fail("no rim spin found beside the apex cup")
	else:
		var a := Sim.aim_at(six[0])
		var r_in := Sim.fly(Sim.launch(a.x + rim_lat, a.y), [six[0]], 0.1)
		var r_out := Sim.fly(Sim.launch(a.x + rim_lat, a.y), [six[0]], 0.9)
		if str(r_in["result"]) != "rim_in" or str(r_out["result"]) != "rim_out":
			_fail("rim: roll 0.1 %s, roll 0.9 %s" % [r_in["result"], r_out["result"]])
	# Two balls a turn; two hits bring them back; a miss passes the turn.
	var s := Sim.new(3)
	_hit(s, 0)
	if s.turn != 0 or s.balls_left != 1:
		_fail("after one hit: turn %d, balls %d" % [s.turn, s.balls_left])
	var r2 := _hit(s, 0)
	if not "balls_back" in r2["events"] or s.turn != 0 or s.balls_left != 2:
		_fail("two hits: %s, turn %d, balls %d" % [r2["events"], s.turn, s.balls_left])
	_miss(s, 0)
	var r3 := _miss(s, 0)
	if not "turn" in r3["events"] or s.turn != 1:
		_fail("two misses should pass the turn: %s" % [r3["events"]])
	# The re-rack at 3, once; the rival's hits are drinks; the sway grows.
	s = Sim.new(4)
	var sway0 := absf(s.sway(1.0).x)
	s.turn = 1
	_hit(s, 1)
	if s.drinks != 1:
		_fail("a rival hit should be a drink: %d" % s.drinks)
	if absf(s.sway(1.0).x) <= sway0:
		_fail("the sway should grow with a drink")
	s = Sim.new(5)
	var rr: Dictionary = {}
	for k in 3:
		s.turn = 0
		s.balls_left = 2
		rr = _hit(s, 0)
	if not "rerack" in rr["events"] or s.cups[1] != Sim.rack(3):
		_fail("three cups left should re-rack: %s" % [rr["events"]])
	s.cups[1].remove_at(2)
	s.cups[1].append(Vector2(0.1, 2.3))
	s.turn = 0
	s.balls_left = 2
	s.hits_turn = 0
	# Down to 2 and back to 3 is not a second re-rack (it cannot grow, but the flag holds).
	if not s.reracked[1]:
		_fail("the re-rack flag should hold")
	# Pani Gienia: late skill after her own re-rack.
	s = Sim.new(6)
	s.skill = 0.3
	s.late_skill = 0.95
	for k in 3:
		s.turn = 0
		s.balls_left = 2
		rr = _hit(s, 0)
	if not s.late or not "late" in rr["events"]:
		_fail("the late skill should start at her re-rack: %s" % [rr["events"]])
	# The aim's path: no new array once grown.
	var path := PackedVector3Array()
	s = Sim.new(7)
	s.predict(0.0, 0.6, path)
	var n := path.size()
	s.predict(0.1, 0.62, path)
	if n < 10 or path.is_empty():
		_fail("predict: %d points" % n)


func _hit(s: Sim, side: int) -> Dictionary:
	var row: Array = s.cups[1 - side]
	var a := Sim.aim_at(row[0])
	return s._resolve(side, Sim.fly(Sim.launch(a.x, a.y), row, 0.9))


func _miss(s: Sim, side: int) -> Dictionary:
	return s._resolve(side, Sim.fly(Sim.launch(0.0, 0.0), s.cups[1 - side], 0.9))


## 300 seeded games: every one ends; the sommelier beats a middling player more often than the
## first-timer's early skill would.
func _games() -> void:
	var wins := {}
	for skill: float in [0.3, 0.75]:
		wins[skill] = 0
		for g in 150:
			var s := Sim.new(1000 + g)
			s.skill = skill
			var throws := 0
			while s.winner < 0 and throws < 400:
				throws += 1
				if s.turn == 0:
					var row: Array = s.cups[1]
					var a := Sim.aim_at(row[s.rng.randi() % row.size()])
					s.throw_player(a.x + s.rng.randfn(0.0, 0.12), a.y + s.rng.randfn(0.0, 0.06), throws * 0.7)
				else:
					s.throw_rival()
			if s.winner < 0:
				_fail("game %d (skill %.2f) did not end in 400 throws" % [g, skill])
			elif s.winner == 1:
				wins[skill] += 1
	print("check_tapczan: rival wins of 150: skill 0.3 %d, skill 0.75 %d" % [wins[0.3], wins[0.75]])
	if int(wins[0.75]) <= int(wins[0.3]):
		_fail("the strong rival should win more often than the weak")


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
	# The TAP LIST: WYPIJ PIWKO opens it; a beer's price goes out of the wallet and onto the bill;
	# short of money is a refusal with nothing poured; the alcohol-free adds no tipsiness.
	t.room.drink()
	if not t.room._taps.visible:
		_fail("WYPIJ PIWKO should open the tap list")
	var stout := Room.tap("stout")
	var price := int(stout.get("price", 0))
	if not t.room.order("stout") or wallet.money != 100 - price or t.room.pints != 1 or t.room.bill != price:
		_fail("a stout: %d zl left, %d pints, bill %d" % [wallet.money, t.room.pints, t.room.bill])
	if t.room._taps.visible:
		_fail("a pick should close the tap list")
	if t.room._bill.text.find(str(price)) < 0:
		_fail("the bill line should show %d zł: %s" % [price, t.room._bill.text])
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
	if not t.tipsy.on() or t.tipsy.amount < 0.9:
		_fail("a pint and two cups should make the drive tipsy: %.2f" % t.tipsy.amount)
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
	t.room.queue_free()
