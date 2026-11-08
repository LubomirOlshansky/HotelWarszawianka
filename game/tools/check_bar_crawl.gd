extends SceneTree
## The bar crawl's rules and words (game/scripts/bar_crawl.gd, data/bar_crawl.json), without the
## city:
##  1. the groups: 4+, unique ids, a name and a speaker, the call (with {route} and {bars}), board,
##     late and the two end quotes, one ride line per stop, two+ in / out / bump lines; each
##     Polish and English, bubbles at most 70 characters (the call and the end quotes at most 150),
##     no denylisted brand;
##  2. the routes: 4+, unique ids, three stops each, every stop on the map box (its sign found in
##     the storefront tables, or its own lat/lon) and the stops more than 60 m apart;
##  3. the call's hours (20:00-04:00 across midnight), the clock (`leg_time`, `budget` with the
##     stays), the pay (per bar; the tip and the on-time bonus only for all three; respect for a
##     happy finish) and the clock text.
## Prints `check_bar_crawl: OK`, or the problems and their count (exit 1). Under a second.
##   godot --headless --path game --script res://tools/check_bar_crawl.gd

const BarCrawl := preload("res://scripts/bar_crawl.gd")
const ORIGIN := [52.234, 21.024]
## The map's box around the origin (m), loosely: what the stops must fall in.
const BOX := 3200.0

var _checks := 0
var _problems := 0


func _initialize() -> void:
	var n := _groups()
	var r := _routes()
	_rules()
	if _problems == 0:
		print("check_bar_crawl: OK (%d checks: %d groups, %d routes, hours, clock, pay)" % [_checks, n, r])
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
