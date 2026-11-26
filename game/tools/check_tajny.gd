extends SceneTree
## The Tajny klient opening's rules without the map (tajny_klient.gd, F 2026-11-26):
##   - Kebabulo's grade: 6.0-9.8 from the dish, the heat, the bumps and the stand's pour; 11 only for
##     the perfect run (the XXL, hot, no bump, for himself, the sauce just right); the camera's VIP
##     kebab and a dry or spilt pour cost tenths; the roast names what cost the most;
##   - the grade's text ("9,4 / 10", "11 / 10");
##   - when it is due: a fresh save and one where it was taken, never once done, never on a save
##     with play in it;
##   - KEBAB U KEMALA's line: nobody before the MLASK, the long line after it, short in the small hours;
##   - every line the mission asks for is in dialogue.json's "tajny_klient" group, both languages,
##     and F's three phrases are there; the shop is in the storefronts' tables;
##   - the times are in pacing.json "tajny";
##   - the 2D stand gives the city back on every way out: WYJDŹ (`_stand_done`, in a run or not) and
##     the run's end (`_ended`: the ✕, a drop, the clock); held, the city is off and the car stopped.
##   godot --headless --path game --script res://tools/check_tajny.gd -- --nosave

const Tajny := preload("res://scripts/tajny_klient.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const StandUi := preload("res://scripts/kebab_stand_ui.gd")
const PalmUi := preload("res://scripts/palm_tasting_ui.gd")
const Dialogue := preload("res://scripts/dialogue.gd")

var problems: Array[String] = []
var checks := 0


class FakeWallet extends Node:
	var intro := {}
	var zl := 0
	var ladder := {}
	var jobs := {}

	func jobs_done() -> int:
		return jobs.size()


func _initialize() -> void:
	_grades()
	_due()
	_queue()
	_words()
	_tables()
	_stand_exits()
	_palm_exits()
	for p in problems:
		print("  PROBLEM " + p)
	print("check_tajny: %s" % ("OK (%d checks)" % checks if problems.is_empty() else "%d problems" % problems.size()))
	quit(0 if problems.is_empty() else 1)


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		problems.append(what)


func _grades() -> void:
	var perfect := Tajny.grade_of(3, 0.1, 0, false)
	_expect(perfect == 11.0, "the perfect run (XXL, hot, no bump, for himself) is 11, got %.1f" % perfect)
	_expect(Tajny.grade_of(3, 0.1, 0, true) < 11.0, "the VIP kebab for the camera is never 11")
	_expect(Tajny.grade_of(3, 0.1, 1, false) < 11.0, "one bump spoils the 11")
	_expect(Tajny.grade_of(2, 0.1, 0, false) < 11.0, "only the XXL can be 11")
	_expect(Tajny.grade_of(3, 0.1, 0, false, "dry") < 11.0, "a dry pour spoils the 11")
	_expect(Tajny.grade_of(3, 0.1, 0, false, "jacket") < 11.0, "sauce on the jacket spoils the 11")
	for d in 4:
		for cool: float in [0.0, 0.3, 0.6, 1.0, 2.0]:
			for b in [0, 1, 3, 9]:
				for c: bool in [false, true]:
					for po: String in Tajny.POURS:
						var g := Tajny.grade_of(d, cool, b, c, po)
						if g >= 11.0:
							continue
						_expect(g >= 6.0 and g <= 9.8, "grade %.1f out of 6.0-9.8 (dish %d, cool %.1f, bumps %d, cam %s, pour %s)" % [g, d, cool, b, c, po])
	_expect(Tajny.grade_of(1, 0.2, 0, false) > Tajny.grade_of(1, 0.2, 0, false, "dry"), "a dry pour costs tenths")
	_expect(Tajny.grade_of(1, 0.2, 0, false) > Tajny.grade_of(1, 0.2, 0, false, "jacket"), "sauce on the jacket costs tenths")
	_expect(Tajny.roast_of(0.2, 0, false, 8.5, "dry") == "dry", "a dry pour is roasted")
	_expect(Tajny.roast_of(0.2, 0, false, 8.5, "jacket") == "jacket", "the jacket is roasted")
	_expect(Tajny.grade_of(0, 0.0, 0, false) > Tajny.grade_of(0, 1.0, 0, false), "a warm kebab grades higher than a cold one")
	_expect(Tajny.grade_of(1, 0.2, 0, false) > Tajny.grade_of(1, 0.2, 3, false), "bumps cost tenths")
	_expect(Tajny.grade_of(1, 0.2, 0, false) > Tajny.grade_of(1, 0.2, 0, true), "the camera's VIP kebab costs tenths")
	_expect(Tajny.roast_of(0.1, 0, false, 11.0) == "perfect", "11 is the perfect roast")
	_expect(Tajny.roast_of(0.1, 3, false, 8.5) == "bumps", "bumps are roasted first")
	_expect(Tajny.roast_of(0.9, 0, false, 8.5) == "cold", "a cold kebab is roasted")
	_expect(Tajny.roast_of(0.2, 0, true, 8.5) == "cam", "the VIP kebab is roasted")
	_expect(Tajny.roast_of(0.2, 0, false, 9.1) == "fine", "a good run gets the fine roast")
	_expect(Tajny.grade_text(9.4) == "9,4 / 10", "9.4 reads \"9,4 / 10\", got \"%s\"" % Tajny.grade_text(9.4))
	_expect(Tajny.grade_text(11.0) == "11 / 10", "11 reads \"11 / 10\"")


func _due() -> void:
	var w := FakeWallet.new()
	_expect(Tajny.is_due(w), "a fresh save gets the opening")
	w.zl = 40
	_expect(not Tajny.is_due(w), "a save with money and nothing taken does not")
	w.intro[Tajny.STAGE_KEY] = Tajny.Saved.BOUGHT
	_expect(Tajny.is_due(w), "a save where it was taken goes on with it")
	w.intro[Tajny.STAGE_KEY] = Tajny.Saved.DONE
	_expect(not Tajny.is_due(w), "never again once done")
	var w2 := FakeWallet.new()
	w2.intro["done"] = 1
	_expect(not Tajny.is_due(w2), "a save whose guide is done does not get it")
	_expect(not Tajny.is_due(null), "no wallet, no opening")
	w.free()
	w2.free()


func _queue() -> void:
	for h: float in [0.0, 9.0, 14.0, 20.0, 23.5]:
		_expect(int(Crowds.kemal_queue(h, false)[0]) == 0, "nobody at Kemal's before the MLASK (%.1f h)" % h)
	_expect(int(Crowds.kemal_queue(13.0, true)[0]) == Crowds.KEMAL_MAX, "the long line by day after the MLASK")
	_expect(int(Crowds.kemal_queue(4.0, true)[0]) == Crowds.KEMAL_NIGHT, "a short line in the small hours")
	_expect(str(Crowds.kemal_queue(13.0, true)[1]) == "kemal", "the line's tag is \"kemal\"")


func _words() -> void:
	var f := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var group: Array = data.get(Tajny.WORDS, [])
	var tags := {}
	var all := ""
	for l: Array in group:
		_expect(l.size() >= 3 and str(l[0]) != "" and str(l[1]) != "", "a line in both languages: %s" % str(l))
		if l.size() >= 3:
			tags[str((l[2] as Dictionary).get("only", ""))] = true
		all += str(l[0]) + "\n"
	# The tags the script asks for: every w("...") and _b("...") in its source.
	var src := FileAccess.get_file_as_string("res://scripts/tajny_klient.gd")
	var re := RegEx.new()
	re.compile("(?:\\bw|_b)\\(\"([a-z_0-9]+)\"\\)")
	var asked := 0
	for m in re.search_all(src):
		asked += 1
		_expect(tags.has(m.get_string(1)), "dialogue.json \"%s\" has no line \"%s\"" % [Tajny.WORDS, m.get_string(1)])
	for t: String in ["roast_perfect", "roast_bumps", "roast_cold", "roast_dry", "roast_jacket", "roast_cam", "roast_fine"]:
		_expect(tags.has(t), "dialogue.json \"%s\" has no line \"%s\" (built by name)" % [Tajny.WORDS, t])
	_expect(asked >= 25, "the script's lines were found (%d)" % asked)
	for phrase: String in ["Ale dobry", "nie za sucha", "z Berlina"]:
		_expect(all.contains(phrase), "F's phrase \"%s\" is in the mission" % phrase)
	_expect(not all.to_upper().contains("MUALA"), "never the trademark word")
	var kemal := 0
	for l: Array in data.get("viral", []):
		if l.size() >= 3 and str((l[2] as Dictionary).get("only", "")) == "kemal":
			kemal += 1
	_expect(kemal >= 3, "the queue at Kemal's has its own lines (viral \"kemal\": %d)" % kemal)


func _tables() -> void:
	_expect(Storefronts.HYPE.has(Crowds.KEMAL_ID), "KEBAB U KEMALA has its place (Storefronts.HYPE)")
	_expect(Storefronts.VENUES.has(Crowds.KEMAL_ID), "KEBAB U KEMALA has its sign (Storefronts.VENUES)")
	var pacing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/pacing.json"))
	var p: Dictionary = pacing.get("tajny", {})
	for k: String in ["call_at", "retry", "ring_life", "warm", "bribe_at", "bribe_life", "banner"]:
		_expect(p.has(k), "pacing.json \"tajny\" has %s" % k)
	_expect(float(p.get("bribe_at", 0)) < float(p.get("warm", 0)), "the bribe comes while the kebab is warm")


## Every way out of the stand gives the city back (GameCtx.city_drawn), as the pub's pong does.
func _stand_exits() -> void:
	var drawn: Array[bool] = []
	var car := Node3D.new()
	root.add_child(car)
	for way: String in ["leave", "leave_out_of_run", "ended"]:
		var t := Tajny.new()
		root.add_child(t)
		t._city_drawn = func(on: bool) -> void: drawn.append(on)
		t.car = car
		t._stand_ui = StandUi.new()
		root.add_child(t._stand_ui)
		t._stand_ui.open("kemal", true)
		t._hold_world(true)
		_expect(drawn.back() == false and car.process_mode == Node.PROCESS_MODE_DISABLED, "%s: the stand holds the city off and the car still" % way)
		match way:
			"leave":
				# WYJDŹ in a run (the order's own way on, to the Palm, is the play-through's: tajny-run)
				t.phase = t.Phase.RUN
				t.stage = Tajny.Stage.TASTE
				t._stand_done({"dish": 0, "sauce": 0, "cam": false, "pour": "good", "price": 0})
			"leave_out_of_run":
				t._stand_done({})
			"ended":
				t._ended()
		_expect(drawn.back() == true, "%s: the city is drawn again" % way)
		_expect(car.process_mode == Node.PROCESS_MODE_INHERIT, "%s: the car moves again" % way)
		if way == "ended":
			_expect(not t._stand_ui.inside, "ended: the stand is taken down")
		t._stand_ui.queue_free()
		t.queue_free()
	car.queue_free()


## The livestream at the Palm: what it is handed, and every way out brings the city and the car back.
func _palm_exits() -> void:
	var dlg := Dialogue.new()
	root.add_child(dlg)
	if dlg.lines.is_empty():
		dlg._ready()  # _initialize runs before the tree's ready
	var t0 := Tajny.new()
	t0.dialogue_node = dlg
	t0.dish = 3
	t0.cam = false
	t0.bribe = 2
	t0.grade = Tajny.grade_of(3, 0.1, 0, false, "good")
	var spec := t0.tasting_spec()
	var v: Array = spec["verdict"]
	_expect(v.size() == 4, "the verdict: the bite, the bun, Berlin and DŻEMINI (%d lines)" % v.size())
	var said := ""
	for l: Array in v:
		said += str(l[0]) + " "
	for phrase: String in ["Ale dobry", "nie za sucha", "z Berlina"]:
		_expect(said.contains(phrase), "the livestream says F's \"%s\"" % phrase)
	_expect(str(spec["grade_label"]) == "11 / 10" and str((spec["roast"] as Array)[0]).contains("Jedenaście"), "a perfect run is 11/10 with its roast: %s" % spec["grade_label"])
	t0.free()
	var drawn: Array[bool] = []
	var car := Node3D.new()
	root.add_child(car)
	for way: String in ["done_out_of_run", "ended"]:
		var t := Tajny.new()
		root.add_child(t)
		t.dialogue_node = dlg
		t._city_drawn = func(on: bool) -> void: drawn.append(on)
		t.car = car
		t._palm_ui = PalmUi.new()
		root.add_child(t._palm_ui)
		t._palm_ui.open(t.tasting_spec())
		t._hold_world(true)
		_expect(drawn.back() == false and car.process_mode == Node.PROCESS_MODE_DISABLED, "palm %s: the city off and the car still" % way)
		match way:
			"done_out_of_run":
				t._palm_done({})
			"ended":
				t._ended()
		_expect(drawn.back() == true, "palm %s: the city is drawn again" % way)
		_expect(car.process_mode == Node.PROCESS_MODE_INHERIT, "palm %s: the car moves again" % way)
		if way == "ended":
			_expect(not t._palm_ui.inside, "palm ended: the livestream is taken down")
		t._palm_ui.queue_free()
		t.queue_free()
	car.queue_free()
	dlg.queue_free()
