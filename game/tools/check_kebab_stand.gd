extends SceneTree
## The 2D kebab stand (kebab_stand.gd's rules, kebab_stand_ui.gd's view; plan doc "First 10
## minutes: Tajny klient", "The 2D kebab stand"):
##   - every stand in data/kebab_stand.json has four dishes with a price and a grade bonus, three
##     sauces with a speed and a colour, and a pour green inside the bottle;
##   - the pour: under the green is dry, over it the jacket; a tap is not a pour; held on, it stops
##     at the spill as the jacket; auto-pour (DOSTĘP) lands in the green; never a fail;
##   - an order to the end: the picks, the price (nothing for the camera's VIP kebab), the tip once;
##     a stand that does not ask "Dla kogo?" goes from the sauce to the build;
##   - every line the stand and its view ask is in dialogue.json "kebab_stand" in both languages,
##     drawable by the pixel font, and the buttons' words fit their buttons on the narrowest screen;
##   - the view plays a whole order by itself (auto) to `finished`.
##   godot --headless --path game --script res://tools/check_kebab_stand.gd -- --nosave

const Stand := preload("res://scripts/kebab_stand.gd")
const StandUi := preload("res://scripts/kebab_stand_ui.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

## Every tag the rules and the view ask (literal or built: "pour_" + the verdict, the dish's number).
const TAGS := ["hello", "hello_note", "menu", "sauce", "who", "build", "hot", "vip", "pour", "pour_hint", "pour_auto",
		"pour_good", "pour_dry", "pour_jacket", "pay", "pay_cam", "paid", "paid_cam", "tip", "flyer", "dish_0", "dish_1",
		"dish_2", "dish_3", "dish_3_note", "sauce_0", "sauce_1", "sauce_2", "who_0", "who_1", "build_shave", "build_fill",
		"build_roll", "btn_leave", "blip_paid", "blip_free", "card_1", "card_2", "enter", "price", "wallet", "flyer_name", "tip_jar",
		"setting_auto_pour"]

var problems: Array[String] = []
var checks := 0
var _view: StandUi
var _got: Array = []
var _steps := 0


func _initialize() -> void:
	_data()
	_pour()
	_orders()
	_words()
	_view = StandUi.new()
	_view.auto_play = true
	root.add_child(_view)
	_view.finished.connect(func(r: Dictionary) -> void: _got.append(r))
	_view.open("kemal", true)


func _process(_dt: float) -> bool:
	if _got.is_empty() and _steps < 3000:
		_view._process(1.0 / 30.0)
		_steps += 1
		return false
	_expect(_got.size() == 1, "the view's auto order ends with `finished` (after %d steps)" % _steps)
	if _got.size() == 1:
		var r: Dictionary = _got[0]
		_expect(int(r["dish"]) == 0 and int(r["sauce"]) == 0 and not bool(r["cam"]), "the auto order is the first of each: %s" % r)
		_expect(str(r["pour"]) == "good", "the auto pour lands in the green: %s" % r)
		_expect(int(r["price"]) == 24, "the auto order costs the bun's 24 zł: %s" % r)
		_expect(_steps / 30.0 < 30.0, "the auto order takes under 30 s (%.1f s)" % (_steps / 30.0))
	_expect(not _view.inside, "the view is closed after WYJDŹ")
	for p in problems:
		print("  PROBLEM " + p)
	print("check_kebab_stand: %s" % ("OK (%d checks, the auto order in %.1f s)" % [checks, _steps / 30.0] if problems.is_empty() else "%d problems" % problems.size()))
	quit(0 if problems.is_empty() else 1)
	return true


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		problems.append(what)


func _data() -> void:
	var stands: Dictionary = Stand.data().get("stands", {})
	_expect(stands.has("kemal"), "data/kebab_stand.json has Kemal's stand")
	for id: String in stands:
		var s: Dictionary = stands[id]
		var dishes: Array = s.get("dishes", [])
		var sauces: Array = s.get("sauces", [])
		_expect(dishes.size() == 4, "%s: four dishes (the board's four panels), got %d" % [id, dishes.size()])
		for d: Dictionary in dishes:
			_expect(int(d.get("price", 0)) > 0 and int(d.get("price", 0)) <= 60, "%s: %s has a price" % [id, d.get("id")])
			var b := float(d.get("bonus", -1.0))
			_expect(b >= 0.0 and b <= 0.5, "%s: %s's grade bonus is 0-0.5" % [id, d.get("id")])
			_expect(str(d.get("id", "")) in ["bun", "wrap", "box", "xxl"], "%s: the view draws %s" % [id, d.get("id")])
		_expect(sauces.size() == 3, "%s: three sauces (the three bottles), got %d" % [id, sauces.size()])
		for c: Dictionary in sauces:
			_expect(float(c.get("speed", 0)) > 0.2 and float(c.get("speed", 0)) < 1.5, "%s: %s pours at a sane speed" % [id, c.get("id")])
			_expect(str(c.get("colour", "")) in ["white", "pink", "red"], "%s: %s has a colour the view knows" % [id, c.get("id")])
		var st := Stand.new(id)
		var g := st.green()
		_expect(g.x > 0.1 and g.x < g.y and g.y < st.spill(), "%s: the green %s sits inside the bottle (spill %.2f)" % [id, g, st.spill()])
		# the hot one is the hardest: it must still leave time to let go in the green (a 0.15 s window at least)
		for c: Dictionary in sauces:
			_expect((g.y - g.x) / float(c.get("speed", 1.0)) >= 0.15, "%s: %s's green lasts long enough to hit" % [id, c.get("id")])


func _pour() -> void:
	var g := Vector2(0.56, 0.8)
	_expect(Stand.judge(0.3, g) == "dry", "under the green is dry")
	_expect(Stand.judge(0.7, g) == "good", "in the green is good")
	_expect(Stand.judge(0.9, g) == "jacket", "over the green is the jacket")


## An order to the pour; returns the stand there.
func _to_pour(who := true, cam := false, sauce := 0) -> Stand:
	var s := Stand.new("kemal", who)
	s.tick(Stand.HELLO_S + 0.01, false)
	_expect(s.phase == Stand.Phase.DISH, "the hello gives way to the board")
	s.pick(3)
	s.pick(sauce)
	if who:
		_expect(s.phase == Stand.Phase.WHO, "after the sauce: \"Dla kogo?\"")
		s.pick(1 if cam else 0)
	_expect(s.phase == Stand.Phase.BUILD, "then Kemal builds it")
	s.tick(Stand.BUILD_S + 0.01, false)
	_expect(s.phase == Stand.Phase.POUR, "then the pour")
	return s


func _orders() -> void:
	# held into the green, let go
	var s := _to_pour(true, true)
	var n := 0
	while s.level < (s.green().x + s.green().y) * 0.5 and n < 400:
		s.tick(1.0 / 60.0, true)
		n += 1
	s.tick(1.0 / 60.0, false)
	_expect(s.pour == "good", "held to the middle of the green and let go: good (%.2f)" % s.level)
	s.tick(1.3, false)
	_expect(s.phase == Stand.Phase.PAY, "then BLIP")
	s.tick(Stand.PAY_S + 0.01, false)
	_expect(s.phase == Stand.Phase.DONE and s.leave(), "then WYJDŹ")
	var r := s.result()
	_expect(int(r["price"]) == 0 and bool(r["cam"]) and int(r["dish"]) == 3, "the camera's VIP XXL is on the house: %s" % r)
	# let go early: dry
	s = _to_pour()
	for i in 20:
		s.tick(1.0 / 60.0, true)
	s.tick(1.0 / 60.0, false)
	_expect(s.pour == "dry", "let go early: dry (%.2f)" % s.level)
	_expect(int(s.result()["price"]) == 39, "the XXL for himself costs 39 zł")
	# held on: the jacket, by itself at the spill
	s = _to_pour(true, false, 2)
	for i in 600:
		s.tick(1.0 / 60.0, true)
	_expect(s.pour == "jacket" and is_equal_approx(s.level, s.spill()), "held on: it stops at the spill on the jacket (%.2f)" % s.level)
	# a tap is not a pour
	s = _to_pour()
	s.tick(0.03, true)
	s.tick(0.03, false)
	_expect(s.pour == "" and s.level == 0.0, "a tap shorter than TAP_S pours nothing")
	# auto-pour
	s = _to_pour()
	s.auto_pour = true
	for i in 300:
		s.tick(1.0 / 60.0, false)
	_expect(s.pour == "good", "auto-pour lands in the green (%.2f)" % s.level)
	# a stand that does not ask who
	_to_pour(false)
	# the tip, once
	s = Stand.new()
	_expect(s.tip() and not s.tip(), "the tip jar takes 2 zł once")
	# picks out of range do nothing
	s = Stand.new()
	s.tap_hello()
	_expect(not s.pick(7) and s.phase == Stand.Phase.DISH, "a pick off the board does nothing")


func _words() -> void:
	var st := Stand.new()
	for t: String in TAGS:
		_expect(Stand.has_words(t, st.words()), "dialogue.json \"%s\" has no line \"%s\"" % [Stand.GROUP, t])
		var p: Array = Stand.say(t, st.words())
		for s: String in [str(p[0]), str(p[1])]:
			_expect(s != "", "\"%s\" in both languages" % t)
			for ch in s.to_upper().replace("\"", "”").replace("{ZL}", "0"):
				if ch != " " and ch != "\n" and PixelFont.char_width(ch) == 0:
					problems.append("\"%s\": the pixel font has no '%s': %s" % [t, ch, s])
					break
	# the buttons' words on the narrowest canvas (MIN_W, 6 px margins): four, three, two to a row
	for lang in 2:
		var n := 4
		var bw := floorf((StandUi.MIN_W - 12.0 - 4.0 * (n - 1)) / n)
		for i in 4:
			var l := "%s %s" % [str(Stand.say("dish_%d" % i)[lang]), str(Stand.say("price")[lang]).format({"zl": int(st.dishes()[i]["price"])})]
			_expect(Kit.text_w(l) <= bw - 4, "the dish button \"%s\" fits (%d of %d px)" % [l, Kit.text_w(l), bw])
		bw = floorf((StandUi.MIN_W - 12.0 - 8.0) / 3)
		for i in 3:
			var l := str(Stand.say("sauce_%d" % i)[lang])
			_expect(Kit.text_w(l) <= bw - 4, "the sauce button \"%s\" fits" % l)
		bw = minf(floorf((StandUi.MIN_W - 12.0 - 4.0) / 2), 150.0)
		for i in 2:
			var l := str(Stand.say("who_%d" % i)[lang])
			_expect(Kit.text_w(l) <= bw - 4, "the who button \"%s\" fits (%d of %d px)" % [l, Kit.text_w(l), bw])
