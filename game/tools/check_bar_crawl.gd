extends SceneTree
## The bar crawl's rules, words and play (game/scripts/bar_crawl.gd, data/bar_crawl.json), without
## the city:
##  1. the groups: 4+, unique ids, a name and a speaker, the call (with {route} and {bars}), board,
##     late and the two end quotes, one ride line per stop, two+ in / out / bump lines; each
##     Polish and English, bubbles at most 70 characters (the call and the end quotes at most 150),
##     no denylisted brand;
##  2. the routes: 4+, unique ids, three stops each, every stop on the map box (its sign found in
##     the storefront tables, or its own lat/lon) and the stops more than 60 m apart;
##  3. the call's hours (20:00-04:00 across midnight), the clock (`leg_time`, `budget` with the
##     stays), the pay (per bar; the tip and the on-time bonus only for all three; respect for a
##     happy finish) and the clock text;
##  4. the play, on the activity kit (activity.gd) with stand-ins for the HUD, the bubbles, the
##     wallet and the rescue calls, three bars on a line and a kerb for the group: the call's own
##     clock (free play at night only), a call and an offer missed or declined with their words,
##     no kerb for the group, the pickup's dashed ring with the group beside the kerb, boarding
##     only when stopped, the clock and the mood (a knock, a hard stop, calm driving, waiting
##     away from the bar), the lines (board, each leg once, in, out, late once), the stays, the
##     result and its pay, the card that closes by itself, out of time, the ✕, the rescue calls
##     held and given back as they were, the director (busy from the offer card to the result
##     card's close, nothing rings while something else is on), and the autopilot.
## Prints `check_bar_crawl: OK`, or the problems and their count (exit 1). About a second.
##   godot --headless --path game --script res://tools/check_bar_crawl.gd

const BarCrawl := preload("res://scripts/bar_crawl.gd")
const Activity := preload("res://scripts/activity.gd")
const Activities := preload("res://scripts/activities.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Fakes := preload("res://tools/fakes.gd")
const DT := 1.0 / 60.0
const ORIGIN := [52.234, 21.024]
## The map's box around the origin (m), loosely: what the stops must fall in.
const BOX := 3200.0

## The crawl with a kerb for the group given by the check (no lane graph here).
class Probe extends BarCrawl:
	var kerb := {}

	func _find_pickup() -> bool:
		pickup = kerb
		return not pickup.is_empty()


var _checks := 0
var _problems := 0
## The play's stand-ins and inputs.
var _crawl: Probe
var _hud: Fakes.Hud
var _bubbles: Fakes.Bubbles
var _wallet: Fakes.Wallet
var _calls: Fakes.Calls
var _director: Activities
var _pos := Vector3.ZERO
var _kmh := 0.0
var _hour := 22.0
var _world_free := true


func _initialize() -> void:
	_go.call_deferred()


## After the first frame, so the crawl's beacon is in the tree.
func _go() -> void:
	var n := _groups()
	var r := _routes()
	_rules()
	_play()
	if _problems == 0:
		print("check_bar_crawl: OK (%d checks: %d groups, %d routes, hours, clock, pay, the play)" % [_checks, n, r])
		quit(0)
	else:
		print("check_bar_crawl: %d problems in %d checks" % [_problems, _checks])
		quit(1)


func _expect(what: String, got, want) -> void:
	_checks += 1
	var same: bool = is_equal_approx(float(got), float(want)) if (got is float or want is float) else got == want
	if not same:
		_problems += 1
		print("check_bar_crawl: %s: got %s, want %s" % [what, str(got), str(want)])


func _groups() -> int:
	var all: Array = BarCrawl.load_groups()
	_expect("bar_crawl.json has 4+ groups", all.size() >= 4, true)
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	var stops := (BarCrawl.ROUTES[0]["stops"] as Array).size()
	var ids := {}
	for g: Dictionary in all:
		var id := String(g.get("id", ""))
		_expect("a group has an id", id != "", true)
		_expect("group id %s is unique" % id, ids.has(id), false)
		ids[id] = true
		_expect("%s has a speaker" % id, String(g.get("speaker", "")) != "", true)
		var call: Array = g.get("call", [])
		_expect("%s: the call names {route} and {bars}" % id, call.size() >= 2 and "{route}" in String(call[0]) and "{bars}" in String(call[0])
				and "{route}" in String(call[1]) and "{bars}" in String(call[1]), true)
		var lines: Array = [[g.get("name", []), 40], [call, 150], [g.get("board", []), 70], [g.get("late", []), 70],
				[g.get("end_good", []), 150], [g.get("end_late", []), 150]]
		_expect("%s: a ride line per stop" % id, (g.get("ride", []) as Array).size() >= stops, true)
		for tag in ["ride", "in", "out", "bump"]:
			var many: Array = g.get(tag, [])
			_expect("%s: two+ %s lines" % [id, tag], many.size() >= 2, true)
			for l: Array in many:
				lines.append([l, 70])
		for pair: Array in lines:
			var l: Array = pair[0]
			_expect("%s: Polish and English" % id, l.size() >= 2 and String(l[0]).strip_edges() != "" and String(l[1]).strip_edges() != "", true)
			if l.size() < 2:
				continue
			if String(l[0]).length() > int(pair[1]):
				_expect("%s: at most %d characters: %s" % [id, pair[1], l[0]], String(l[0]).length(), pair[1])
			for text: String in [String(l[0]).to_lower(), String(l[1]).to_lower()]:
				for b in banned:
					var rx := RegEx.create_from_string("(^|[^\\p{L}])" + String(b).to_lower() + "($|[^\\p{L}])")
					if rx.search(text) != null:
						_expect("%s: no real brand (%s)" % [id, b], text, "")
	return all.size()


func _routes() -> int:
	_expect("4+ routes", BarCrawl.ROUTES.size() >= 4, true)
	var ids := {}
	for r: Dictionary in BarCrawl.ROUTES:
		var id := String(r["id"])
		_expect("route id %s is unique" % id, ids.has(id), false)
		ids[id] = true
		_expect("%s: a name in Polish and English" % id, (r["name"] as Array).size(), 2)
		var stops: Array = r["stops"]
		_expect("%s: three stops" % id, stops.size(), 3)
		var prev := Vector2.INF
		for s: Dictionary in stops:
			var p := BarCrawl.stop_point(s, ORIGIN)
			_expect("%s: %s is found" % [id, s["name"]], p != Vector2.INF, true)
			if p == Vector2.INF:
				continue
			_expect("%s: %s is on the map (%d, %d)" % [id, s["name"], roundi(p.x), roundi(p.y)], absf(p.x) < BOX and absf(p.y) < BOX, true)
			if prev != Vector2.INF:
				_expect("%s: %s is 60+ m from the last stop" % [id, s["name"]], prev.distance_to(p) > 60.0, true)
			prev = p
	return BarCrawl.ROUTES.size()


func _rules() -> void:
	_expect("calls at 22:00", BarCrawl.call_hours(22.0), true)
	_expect("calls at 02:00", BarCrawl.call_hours(2.0), true)
	_expect("no call at 12:00", BarCrawl.call_hours(12.0), false)
	_expect("no call at 04:30", BarCrawl.call_hours(4.5), false)
	_expect("a 500 m leg", BarCrawl.leg_time(500.0), 500.0 * BarCrawl.DETOUR / BarCrawl.LEG_SPEED + BarCrawl.LEG_SLACK)
	var pts := [Vector2.ZERO, Vector2(400, 0), Vector2(400, 300), Vector2(0, 300)]
	var want := BarCrawl.leg_time(400.0) + BarCrawl.leg_time(300.0) + BarCrawl.leg_time(400.0) + 2.0 * BarCrawl.STAY
	_expect("the budget: three legs and two stays", BarCrawl.budget(pts), want)
	_expect("a budget of 3-12 minutes for a 1.1 km crawl", want > 180.0 and want < 720.0, true)
	var full: Array = BarCrawl.pay_for(3, 3, 100.0, true)
	_expect("all three, full mood, on time", full[0], 3 * BarCrawl.PER_BAR + BarCrawl.TIP + BarCrawl.ON_TIME)
	_expect("all three, happy: respect", full[1], 3 * BarCrawl.RESPECT_BAR + BarCrawl.RESPECT_HAPPY)
	var half: Array = BarCrawl.pay_for(3, 3, 50.0, true)
	_expect("all three at 50 mood", half[0], 3 * BarCrawl.PER_BAR + BarCrawl.TIP / 2 + BarCrawl.ON_TIME)
	_expect("all three at 50 mood: no happy respect", half[1], 3 * BarCrawl.RESPECT_BAR)
	var late: Array = BarCrawl.pay_for(1, 3, 100.0, false)
	_expect("one bar, out of time: no tip", late[0], BarCrawl.PER_BAR)
	_expect("none: nothing", BarCrawl.pay_for(0, 3, 90.0, false)[0], 0)
	_expect("more mood, more pay", BarCrawl.pay_for(3, 3, 80.0, true)[0] > BarCrawl.pay_for(3, 3, 40.0, true)[0], true)
	_expect("clock 125 s", BarCrawl.clock_text(125.0), "2:05")
	_expect("clock under zero", BarCrawl.clock_text(-3.0), "0:00")
	_expect("mood words", BarCrawl.mood_word(90.0)[0] != BarCrawl.mood_word(10.0)[0], true)


# --- the play ---------------------------------------------------------------------------------------

func _kerb(x: float, z: float) -> Dictionary:
	return {"at": Vector3(x, 1.5, z), "side": Vector3(x, 1.5, z + 3.0)}


func _make() -> void:
	var world := Node3D.new()
	root.add_child(world)
	_hud = Fakes.Hud.new()
	_bubbles = Fakes.Bubbles.new()
	_wallet = Fakes.Wallet.new()
	_calls = Fakes.Calls.new()
	var map := Fakes.FlatMap.new()
	for node: Node in [_hud, _bubbles, _wallet, _calls, map]:
		world.add_child(node)
	_crawl = Probe.new()
	_crawl.hud = _hud
	_crawl.bubbles = _bubbles
	_crawl.wallet = _wallet
	_crawl.map = map
	_crawl.rng_seed = 7
	_crawl.vehicle = func() -> Array: return [_pos, _kmh, false]
	_crawl.clock = func() -> float: return _hour
	world.add_child(_crawl)
	_crawl.setup(world)
	_crawl.set_process(false)
	_crawl.kerb = _kerb(300.0, 0.0)
	# One route of three bars on a line, 400 m apart (no lane graph: the kerbs are given).
	_crawl.routes = [{"id": "proba", "name": ["Próbna", "The Trial"], "stops": [
			{"name": "PIERWSZY", "at": _kerb(700.0, 0.0)}, {"name": "DRUGI", "at": _kerb(1100.0, 0.0)},
			{"name": "TRZECI", "at": _kerb(1500.0, 0.0)}]}]
	_director = Activities.new()
	_director.world_free = func() -> bool: return _world_free
	_director.add(_crawl)
	_director.add(_calls)


func _run(seconds: float) -> void:
	for i in roundi(seconds / DT):
		_crawl._process(DT)


func _park() -> void:
	_pos = _crawl.target_position()
	_kmh = 0.0


func _far(kmh: float) -> void:
	var t: Vector3 = _crawl.target_position()
	_pos = Vector3(t.x - 200.0, t.y, t.z + 80.0)
	_kmh = kmh


func _is(stage: int) -> bool:
	return _crawl.phase == Activity.Phase.RUN and _crawl.stage == stage


## From idle to the group in the car.
func _aboard() -> void:
	_pos = Vector3.ZERO
	_crawl.ring()
	_hud.press(0)
	_hud.press(0)
	_park()
	_run(1.4)


func _toast_has(text: String) -> bool:
	for t in _hud.toasts:
		if text in t:
			return true
	return false


func _play() -> void:
	_make()
	var c := _crawl
	_expect("the play: one route, 4+ groups", c.routes.size() == 1 and c.groups.size() >= 4, true)

	# The call's own clock: seconds of free play at night.
	var first: float = c.call_in
	_expect("the first call is 4 to 7 minutes of free play away", first >= BarCrawl.FIRST_CALL.x and first <= BarCrawl.FIRST_CALL.y, true)
	_run(2.0)
	_expect("the call's clock counts at night", c.call_in < first - 1.5 and c.call_in > first - 2.5, true)
	var left: float = c.call_in
	_hour = 13.0
	_run(2.0)
	_expect("not by day", c.call_in, left)
	_hour = 23.0
	_world_free = false
	_run(2.0)
	_expect("not while something else is on", c.call_in, left)
	_world_free = true
	c.auto = false
	_run(2.0)
	_expect("not when the timer is off (a test run)", c.call_in, left)
	c.auto = true
	c.call_in = 0.5
	_run(1.0)
	_expect("it rings when the clock is out", c.phase, Activity.Phase.RING)
	_expect("the call names the group", "DZWONI" in _hud.card and _hud.card_is(c), true)
	_expect("a ringing phone is not busy", c.busy() or _director.busy(), false)
	_expect("a second call is refused while it rings", c.ring(), false)

	# Nobody answers; declined; the offer declined.
	_run(BarCrawl.RING_LIFE + 0.5)
	_expect("a call nobody answers goes", c.idle() and _hud.card == "", true)
	_expect("with the missed call's words", _toast_has("Nieodebrane połączenie"), true)
	_expect("and the next call 20 to 30 minutes of free play away", c.call_in >= BarCrawl.NEXT_CALL.x - 1.0 and c.call_in <= BarCrawl.NEXT_CALL.y, true)
	c.ring()
	_hud.press(1)
	_expect("a call declined: idle, with its words", c.idle() and _toast_has("Odrzucono"), true)
	var next_call: float = c.call_in
	c.ring()
	_hud.press(1)
	_expect("the next call is drawn anew each time", c.call_in != next_call, true)
	c.force_group = "sesja"
	c.ring()
	_hud.press(0)
	_expect("answered: the offer", c.phase, Activity.Phase.OFFER)
	var name_pl: String = c._group_name()[0]
	_expect("the offer is the forced group's and the crawl's own card", _hud.card == name_pl and String(c._group().get("id", "")) == "sesja" and _hud.card_is(c), true)
	var budget := BarCrawl.budget([Vector2(300, 0), Vector2(700, 0), Vector2(1100, 0), Vector2(1500, 0)])
	_expect("the offer says the route, the bars and the clock", "„Próbna”" in _hud.body and "PIERWSZY → DRUGI → TRZECI" in _hud.body
			and ("Czas: %s." % BarCrawl.clock_text(budget)) in _hud.body, true)
	_expect("the offer has two buttons", _hud.buttons, 2)
	_expect("from the offer card on the crawl is busy (the kit's one meaning)", c.busy() and _director.busy() and _director.busy_tag() == "crawl", true)
	_expect("but the rescue calls are not held yet", _calls._held(), false)
	_hud.press(1)
	_expect("the offer declined: idle, with its words", c.idle() and _toast_has("Trudno!"), true)
	c.ring()
	_hud.press(0)
	_run(BarCrawl.RING_LIFE + 0.5)
	_expect("an offer nobody answers goes too", c.idle() and _hud.card == "", true)
	c.force_group = ""

	# No kerb for the group: no offer.
	c.kerb = {}
	c.ring()
	_hud.press(0)
	_expect("no kerb for the group: no offer, idle", c.idle() and _hud.card == "", true)
	c.kerb = _kerb(300.0, 0.0)

	# Taken: the group at the kerb.
	_calls.paused = false
	_pos = Vector3.ZERO
	c.ring()
	_hud.press(0)
	_hud.toasts.clear()
	_hud.press(0)
	_expect("the offer taken: on the way to the group", _is(BarCrawl.Stage.PICKUP), true)
	_expect("the rescue calls are held", _calls._held(), true)
	_expect("the toast sends the player", _toast_has("Jedź po grupę"), true)
	_expect("the target is the kerb", c.has_target() and c.target_position() == Vector3(300.0, 1.5, 0.0), true)
	_expect("in the pickup's amber", c.target_colour(), BarCrawl.PICK_COLOUR)
	_expect("the director points at the crawl", _director.targeted() == c, true)
	_expect("no stop assist at the kerb (as before the kit)", c.stop_spot(), Vector3.INF)
	var b: Node3D = c._beacon
	_expect("the ring stands on the pavement beside the kerb", b.visible and b.position == Vector3(300.0, 1.5, 3.0), true)
	_expect("dashed, the pickup's size, with the group in it", b.pattern == Beacon.Pattern.DASHED and is_equal_approx(b._ring_radius, BarCrawl.PICK_R)
			and b._person.visible and b._colour == BarCrawl.PICK_COLOUR, true)
	_far(40.0)
	_run(1.0)
	_expect("the status on the way has the group's name", _hud.status_title, String(c._group_name()[0]))
	_expect("the status on the way is amber", _hud.tint, BarCrawl.PICK_COLOUR)
	c.on_bump(9.0)
	_expect("a knock before the group is in costs nothing", c.mood, BarCrawl.MOOD_START)

	# Boarding: only when stopped in the ring.
	_park()
	_kmh = 12.0
	_run(1.5)
	_expect("rolling through the ring is not stopping", _is(BarCrawl.Stage.PICKUP), true)
	_kmh = 0.0
	_bubbles.said.clear()
	_run(1.4)
	_expect("stopped: the group is in", _is(BarCrawl.Stage.DRIVE), true)
	_expect("the board line is said", _bubbles.said.size() == 1 and _bubbles.said[0] == String(c._group()["board"][0]), true)
	_expect("the clock is the budget", absf(c.time_left - budget) < 0.6, true)
	_expect("the target is the first bar, in the crawl's orange", c.target_position() == Vector3(700.0, 1.5, 0.0) and c.target_colour() == BarCrawl.COLOUR, true)
	_expect("a solid ring of the bar's size, nobody in it", b.pattern == Beacon.Pattern.SOLID and is_equal_approx(b._ring_radius, BarCrawl.BAR_R)
			and not b._person.visible and b.position == Vector3(700.0, 1.5, 3.0), true)

	# The drive: the status, the leg's line once, the mood.
	_far(40.0)
	_bubbles.said.clear()
	_run(4.0)
	_expect("the status says the route and the bar", _hud.status_title == "PRÓBNA · 1/3" and "PIERWSZY" in _hud.status and "nastrój" in _hud.status, true)
	_expect("in the crawl's orange", _hud.tint, BarCrawl.COLOUR)
	_expect("the leg's line is said", _bubbles.said.size() == 1 and _bubbles.said[0] == String(c._group()["ride"][0][0]), true)
	_run(40.0)
	_expect("and only once a leg", _bubbles.said.size(), 1)
	_expect("calm driving lifts the mood, a point every 8 s", c.mood, BarCrawl.MOOD_START + 5.0)
	c.on_bump(1.0)
	_expect("a soft touch costs nothing", c.mood, BarCrawl.MOOD_START + 5.0)
	c.on_bump(6.0)
	c.on_bump(6.0)
	_expect("a knock costs 7, once a second", c.mood, BarCrawl.MOOD_START - 2.0)
	_expect("and the group says so", _bubbles.said.size(), 2)
	_run(1.5)
	_kmh = 50.0
	_run(1.0)
	var before: float = c.mood
	_kmh = 8.0
	_run(0.6)
	_expect("a hard stop costs 3", c.mood, before - BarCrawl.BRAKE_MOOD)

	# The first bar: the stay.
	_park()
	_bubbles.said.clear()
	_run(1.4)
	_expect("stopped at the first bar: they go in", _is(BarCrawl.Stage.WAIT) and c.bar == 0, true)
	_expect("with a line", _bubbles.said.size(), 1)
	_run(5.0)
	_expect("the stay counts down at the kerb", c.stay_left < BarCrawl.STAY - 4.0 and c.stay_left > BarCrawl.STAY - 6.0, true)
	var stay: float = c.stay_left
	before = c.mood
	_pos += Vector3(60.0, 0.0, 0.0)
	_run(4.0)
	_expect("away from the bar the stay stands", c.stay_left, stay)
	_expect("and the mood drops 1.5 a second", absf((before - c.mood) - BarCrawl.AWAY_MOOD * 4.0) < 0.5, true)
	_expect("the status calls the player back", "Wracaj pod bar" in _hud.status, true)
	_park()
	_bubbles.said.clear()
	_run(stay + 0.6)
	_expect("the stay over: on to the second bar", _is(BarCrawl.Stage.DRIVE) and c.bar == 1 and c.target_position() == Vector3(1100.0, 1.5, 0.0), true)
	_expect("with a line on the way out", _bubbles.said.size() >= 1, true)

	# The next leg's line waits a few seconds after a bar.
	_far(40.0)
	_bubbles.said.clear()
	_run(5.0)
	_expect("the next leg's line waits 6 s after a bar", _bubbles.said.is_empty(), true)
	_run(1.5)
	_expect("then it is said", _bubbles.said.size() == 1 and _bubbles.said[0] == String(c._group()["ride"][1][0]), true)

	# Late, once.
	_far(40.0)
	_bubbles.said.clear()
	c.time_left = BarCrawl.LATE_AT - 1.0
	_run(2.0)
	var late_pl: String = c._group()["late"][0]
	_expect("under 45 s left: the late line", late_pl in _bubbles.said, true)
	_run(3.0)
	_expect("once", _bubbles.said.count(late_pl), 1)
	c.time_left = 300.0

	# The second bar, the third: the result.
	_park()
	_run(1.4)
	_run(BarCrawl.STAY + 0.6)
	_expect("out of the second bar", _is(BarCrawl.Stage.DRIVE) and c.bar == 2, true)
	_park()
	var mood: float = c.mood
	_run(1.4)
	_expect("the third bar is the end: the result", _is(BarCrawl.Stage.RESULT), true)
	var want: Array = BarCrawl.pay_for(3, 3, mood, true)
	_expect("paid for three bars, the tip by the mood and the bonus", _wallet.money == int(want[0]) and _wallet.respect == int(want[1]) and _wallet.kinds == ["crawl"], true)
	_expect("the result card is the crawl's own", _hud.card == "RAJD PO BARACH" and _hud.card_is(c) and "3 z 3 barów" in _hud.body, true)
	_expect("no target, no beacon, no status line under it", not c.has_target() and not b.visible and _hud.status == "", true)
	_expect("still busy until the card closes, the calls still held", c.busy() and _calls._held(), true)
	_run(BarCrawl.RESULT_LIFE - 1.0)
	_expect("the card stays for its life", _hud.card, "RAJD PO BARACH")
	_run(1.5)
	_expect("then closes by itself: idle", c.idle() and _hud.card == "" and not _director.busy(), true)
	_expect("the rescue calls are back on", _calls._held(), false)
	_expect("one crawl done", c.crawls == 1 and int(c.last_pay["done"]) == 3 and bool(c.last_pay["on_time"]), true)

	# Out of time after one bar: paid for that bar, no tip; the calls go back to what they were.
	_calls.paused = true
	_aboard()
	_expect("aboard again", _is(BarCrawl.Stage.DRIVE), true)
	_park()
	_run(1.4)
	_run(BarCrawl.STAY + 0.6)
	_expect("past the first bar", _is(BarCrawl.Stage.DRIVE) and c.bar == 1, true)
	var money := _wallet.money
	_far(40.0)
	c.time_left = 0.3
	_run(0.6)
	_expect("out of time: last orders", _is(BarCrawl.Stage.RESULT) and _hud.card == "OSTATNIE ZAMÓWIENIA", true)
	_expect("paid for the one bar, no tip, no bonus", _wallet.money - money, BarCrawl.PER_BAR)
	_hud.press(0)
	_expect("OK closes it", c.idle() and _hud.card == "", true)
	_expect("the calls were off before the crawl and are off after it", _calls.paused, true)
	_expect("the calls are still held after the crawl", _calls._held(), true)
	_calls.paused = false

	# The ✕ on a leg: they walk, nothing paid.
	_aboard()
	money = _wallet.money
	_far(40.0)
	_run(2.0)
	_hud.toasts.clear()
	_hud.abort_pressed.emit()
	_expect("the ✕ ends the crawl: idle, nothing up", c.idle() and _hud.status == "" and not b.visible, true)
	_expect("with the walking words, nothing paid, the calls back", _toast_has("idzie dalej pieszo") and _wallet.money == money and not _calls._held(), true)
	# The ✕ on the result card does nothing.
	_aboard()
	c.time_left = 0.3
	_run(0.6)
	_hud.abort_pressed.emit()
	_expect("the ✕ does nothing on the result card", _is(BarCrawl.Stage.RESULT), true)
	_hud.press(0)

	# The autopilot: it answers, takes the offer and lets the result go; the car stands on each target.
	c.autopilot = true
	var crawls: int = c.crawls
	_pos = Vector3.ZERO
	c.ring()
	for i in 60 * 120:
		if c.has_target():
			_park()
		c._process(DT)
		if c.crawls > crawls and c.idle():
			break
	_expect("the autopilot finishes a crawl by itself", c.crawls == crawls + 1 and c.idle() and bool(c.last_pay["on_time"]), true)
	c.autopilot = false
