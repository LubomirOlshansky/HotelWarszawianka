extends SceneTree
## 2026-11-02 (F: "Polish or English, not two simultaneously"): the language choice. Checks that
##   - lang.gd decides right: the phone's language when nothing is saved (Polish phones get Polish,
##     every other English), the saved choice over it, an unknown code falls back, `pick` falls back
##     to the Polish for a text with no English (a street, a parody name), `split` takes the half;
##   - settings.gd keeps `lang` ("" until chosen, then "pl" / "en"), and --nosave writes nothing;
##   - in EACH language no screen shows both: the HUD's entry points (toast, ticker, call and side
##     cards with their buttons, the status panel, the landmark card, the police pill, the context
##     button, the challenge button, the main line's goal, a speech bubble, the pull-over card) show
##     the chosen language's text and never the other's; the settings panel shows every option's
##     name in the chosen language only, on every tab; the title screen too, and its POLSKI /
##     ENGLISH buttons switch it;
##   - the credits and the loop's stock words come out in one language.
## Drawn text (the notebook page, the pedals' words) is checked by hand on the phone: parked in
## docs/QUESTIONS.md. Prints `check_language: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_language.gd

const Hud := preload("res://scripts/hud.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const PoliceBalloon := preload("res://scripts/police/police_balloon.gd")
const Lang := preload("res://scripts/lang.gd")
const Settings := preload("res://scripts/settings.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")
const Title := preload("res://scripts/title.gd")
const Credits := preload("res://scripts/credits.gd")
const Ladder := preload("res://scripts/ladder.gd")
const SCRATCH := "user://language_check.cfg"

## A sample for each surface: the Polish text, the English text. Unique words, so a leak is found
## by a plain search for the other language's sentence.
const SAMPLES := {
	"toast": ["Jedziemy, Kasia czeka", "Go now, Kasia is waiting"],
	"ticker": ["Radio mówi: korki na Rondzie", "The radio says: jams at the roundabout"],
	"card_title": ["WEZWANIE PIERWSZE", "FIRST CALL OUT"],
	"card_body": ["Ranny rowerzysta czeka przy skrzyżowaniu.", "A hurt cyclist waits at the crossing."],
	"status_hint": ["Stań w zielonym kółku", "Stop inside the green ring"],
	"info": ["Pałac Kultury, dar narodu radzieckiego.", "Palace of Culture, a gift from the Soviet people."],
	"police": ["POŚCIG, KONIEC ZMIANY ZA 0:30", "CHASE, END OF SHIFT IN 0:30"],
	"pill": ["WEZWANIE RATUNKOWE", "RESCUE CALL INCOMING"],
	"challenge": ["MRUGNIJ ŚWIATŁAMI", "FLASH YOUR LIGHTS"],
	"goal": ["Jedź na Rondo Dmowskiego", "Drive to Rondo Dmowskiego"],
	"bubble": ["Szybciej, proszę!", "Faster, please!"],
	"talk": ["Dzień dobry, kontrola drogowa.", "Good day, a traffic check."],
}

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_check_resolve()
	_check_settings()
	for code in Lang.CODES:
		Lang.set_code(code)
		await _check_hud(code)
		await _check_panel(code)
		await _check_title(code)
		_check_stock(code)
	Lang.set_code(Lang.PL)
	if problems.is_empty():
		print("check_language: OK (pl and en: the HUD, the settings panel, the title, the credits; one language on each)")
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_language: %d problems" % problems.size())
		quit(1)


func _fail(msg: String) -> void:
	problems.append(msg)


## lang.gd's rules.
func _check_resolve() -> void:
	if Lang.resolve("pl") != "pl" or Lang.resolve("en") != "en":
		_fail("a saved choice must win over the phone's language")
	if not Lang.resolve("") in Lang.CODES or not Lang.resolve("xx") in Lang.CODES:
		_fail("no or an unknown saved choice must fall back to the phone's language, pl or en")
	if Lang.resolve("") != Lang.EN or Lang.resolve("xx") != Lang.EN:
		_fail("with nothing saved the game starts in English, whatever the phone's language")
	Lang.set_code("zz")
	if Lang.code != Lang.PL:
		_fail("set_code with an unknown code must stay Polish")
	Lang.set_code(Lang.EN)
	if Lang.pick("Ulica", "") != "Ulica" or Lang.pick("Tak", "Yes") != "Yes":
		_fail("pick: English where there is some, the Polish for a name")
	if Lang.split("TAK · YES") != "YES" or Lang.split("Nazwa") != "Nazwa":
		_fail("split: the English half, a text with no pair whole")
	Lang.set_code(Lang.PL)
	if Lang.pick("Tak", "Yes") != "Tak" or Lang.split("TAK · YES") != "TAK":
		_fail("pick and split must give the Polish in Polish")
	if Lang.pair("a", "b").size() != 2 or Lang.pair("a", "b")[1] != "":
		_fail("pair must leave the second slot empty")
	Lang.set_code(Lang.EN)
	if Lang.title("WYŚCIG · A → B") != "RACE · A → B":
		_fail("title: stock Polish words in English (%s)" % Lang.title("WYŚCIG · A → B"))
	Lang.set_code(Lang.PL)


## settings.gd keeps the choice; --nosave does not.
func _check_settings() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	var fresh := Settings.new()
	fresh.path = SCRATCH
	fresh.load_file()
	if fresh.lang != "":
		_fail("a missing settings file must leave the language unchosen (\"\"), not '%s'" % fresh.lang)
	var s := Settings.new()
	s.path = SCRATCH
	s.lang = "en"
	s.save()
	var back := Settings.new()
	back.path = SCRATCH
	back.load_file()
	if back.lang != "en":
		_fail("the language must round-trip through settings.cfg (got '%s')" % back.lang)
	var cfg := ConfigFile.new()
	cfg.load(SCRATCH)
	cfg.set_value("game", "lang", "klingon")
	cfg.save(SCRATCH)
	back = Settings.new()
	back.path = SCRATCH
	back.load_file()
	if back.lang != "":
		_fail("an unknown saved language must load as unchosen")
	var off := Settings.new()
	off.path = SCRATCH + ".off"
	off.persistent = false
	off.lang = "pl"
	off.save()
	if FileAccess.file_exists(SCRATCH + ".off"):
		_fail("--nosave must not write the language")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))


## Every visible text in a tree (Labels and Buttons).
func _texts(node: Node, out: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	if node is Label and (node as Label).is_visible_in_tree() and (node as Label).text != "":
		out.append((node as Label).text)
	elif node is Button and (node as Button).is_visible_in_tree() and (node as Button).text != "":
		out.append((node as Button).text)
	for c in node.get_children():
		_texts(c, out)
	return out


func _joined(node: Node) -> String:
	return "\n".join(_texts(node))


## `shown` is in the screen's text and `hidden` is nowhere in it.
func _expect(where: String, text: String, shown: String, hidden: String, code: String) -> void:
	if not text.contains(shown):
		_fail("[%s] %s: '%s' is missing" % [code, where, shown])
	if text.contains(hidden):
		_fail("[%s] %s: the other language shows too: '%s'" % [code, where, hidden])


func _pair(key: String, code: String) -> Array:
	var s: Array = SAMPLES[key]
	return [s[0] if code == Lang.PL else s[1], s[1] if code == Lang.PL else s[0]]


func _check_hud(code: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	var bubbles: Control = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	hud.add_child(bubbles)
	var talk: Control = PoliceBalloon.new()
	talk.pt = hud.pt
	hud.add_panel(talk, "bottom")
	await process_frame
	var s := SAMPLES
	# One surface at a time: the passing panels wait for room beside each other.
	for key in ["toast", "ticker", "card", "info", "police", "pill", "challenge", "goal"]:
		hud.clear_all()
		match key:
			"toast":
				hud.toast(s["toast"][0], s["toast"][1])
			"ticker":
				hud.ticker(s["ticker"][0], Color.WHITE, s["ticker"][1])
			"card":
				hud.show_card(s["card_title"][0], s["card_body"][0], PackedStringArray(["ACCEPT", "SKIP", "LATER"]), Color("#ffc23a"),
						false, s["card_title"][1], s["card_body"][1])
			"info":
				hud.show_info("Pałac Kultury", s["info"][0], s["info"][1])
			"police":
				hud.police_pill(s["police"][0], s["police"][1])
			"pill":
				hud.show_pill(s["pill"][0], s["pill"][1])
			"challenge":
				hud.show_challenge(s["challenge"][0], Color.WHITE, s["challenge"][1])
			"goal":
				hud.set_main_line(Vector2(10, 10), s["goal"][0], s["goal"][1])
		await process_frame
		var all := _joined(hud)
		match key:
			"card":
				for k2 in ["card_title", "card_body"]:
					var p := _pair(k2, code)
					_expect("HUD " + k2, all, p[0], p[1], code)
				# The card's buttons: ACCEPT / SKIP / LATER in the chosen language only.
				var buttons := ["PRZYJMIJ", "POMIŃ", "PÓŹNIEJ"] if code == Lang.PL else ["Accept", "Skip", "Later"]
				var others := ["Accept", "Skip", "Later"] if code == Lang.PL else ["PRZYJMIJ", "POMIŃ", "PÓŹNIEJ"]
				for i in buttons.size():
					_expect("card button %d" % i, all, buttons[i], others[i], code)
			"goal":
				pass  # drawn on the full map; its card is checked with the map (hud.main_goal below)
			_:
				var p := _pair(key, code)
				_expect("HUD " + key, all, p[0], p[1], code)
	if hud.main_goal[0] != _pair("goal", code)[0] or hud.main_goal[1] != "":
		_fail("[%s] the main line's goal is '%s' / '%s'" % [code, hud.main_goal[0], hud.main_goal[1]])
	hud.clear_all()
	bubbles.say(Vector3.ZERO, "Ania", s["bubble"][0], s["bubble"][1])
	talk.show_line("Policjant", s["talk"][0], s["talk"][1], [["Tak, proszę pana", "Yes, officer"]])
	hud.show_panel(talk, true)
	await process_frame
	_expect("speech bubble", " ".join([bubbles._bubbles[0]["line"], bubbles._bubbles[0]["sub"]]), _pair("bubble", code)[0],
			_pair("bubble", code)[1], code)
	if str(bubbles._bubbles[0]["sub"]) != "":
		_fail("[%s] a speech bubble still has a subtitle" % code)
	var balloon := _joined(talk)
	_expect("pull-over card", balloon, _pair("talk", code)[0], _pair("talk", code)[1], code)
	_expect("pull-over reply", balloon, "Tak, proszę pana" if code == Lang.PL else "Yes, officer",
			"Yes, officer" if code == Lang.PL else "Tak, proszę pana", code)
	# The status panel (a new card replaces the call card).
	hud.clear_all()
	bubbles.clear()
	hud.show_status("WYŚCIG · A → B", "2:31", "640 m", s["status_hint"][0], 0.3, Color("#ffc23a"), "", {}, s["status_hint"][1])
	await process_frame
	var status := _joined(hud)
	var hint := _pair("status_hint", code)
	_expect("status hint", status, hint[0], hint[1], code)
	if code == Lang.EN and status.contains("WYŚCIG"):
		_fail("[en] the status title keeps its Polish stock word 'WYŚCIG'")
	if code == Lang.PL and status.contains("RACE"):
		_fail("[pl] the status title turned English")
	# The radio button and the vehicle button.
	hud.set_radio_name("OFF")
	var buttons_text := _joined(hud)
	_expect("radio button", buttons_text, "RADIO wył." if code == Lang.PL else "RADIO off", "RADIO off" if code == Lang.PL else "RADIO wył.", code)
	hud.queue_free()
	vp.queue_free()


## The settings panel on every tab: each option's name in one language.
func _check_panel(code: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	await process_frame
	var panel = hud.settings_panel
	panel.open({"controls": 0, "follow": true, "traffic": 1, "quality": 0, "auto": "High", "master": 1.0, "music": 1.0, "effects": 1.0,
			"fps": 0, "weather": 0, "time": 0, "lang": Lang.CODES.find(code)})
	var pairs: Array = []
	for group in [SettingsPanel.CAMERA, SettingsPanel.TIME, SettingsPanel.WEATHER, SettingsPanel.TRAFFIC,
			SettingsPanel.ON_OFF, SettingsPanel.FPS, SettingsPanel.MODE, SettingsPanel.CONTROLS_SAY, SettingsPanel.TABS]:
		pairs.append_array(group)
	for tab in 6:
		panel.set_tab(tab)
		await process_frame
		var text := _joined(panel)
		for pr: Array in pairs:
			var pl := str(pr[0])
			var en := str(pr[1]).to_upper() if SettingsPanel.TABS.has(pr) else str(pr[1])
			var shown := pl if code == Lang.PL else en
			var hidden := en if code == Lang.PL else pl
			if pl == en or shown == hidden:
				continue
			# Only this tab's own options are visible; a leak is the other language's word as a whole text.
			if text.split("\n").has(hidden) and not text.split("\n").has(shown) and not _word_shared(hidden, code):
				_fail("[%s] settings tab %d shows '%s' (the other language) instead of '%s'" % [code, tab, hidden, shown])
	# The language row itself is there, with both languages named in their own tongue.
	panel.set_tab(SettingsPanel.SOUND_TAB)
	await process_frame
	var sound := _joined(panel)
	if not sound.contains("Polski") or not sound.contains("English"):
		_fail("[%s] Settings → DŹWIĘK has no Polski / English choice" % code)
	# Heading rows are one label: no " · " pair in a heading.
	for line in sound.split("\n"):
		if line.to_upper() == line and " · " in line and "ENGLISH" in line:
			_fail("[%s] a heading shows both languages: '%s'" % [code, line])
	# Rebuilding in the other language must work with the panel open.
	var other: String = Lang.EN if code == Lang.PL else Lang.PL
	Lang.set_code(other)
	panel.rebuild({"controls": 0, "follow": true, "traffic": 1, "quality": 0, "auto": "High", "master": 1.0, "music": 1.0,
			"effects": 1.0, "fps": 0, "weather": 0, "time": 0, "lang": Lang.CODES.find(other)})
	await process_frame
	var rebuilt := _joined(panel)
	panel.set_tab(0)
	await process_frame
	rebuilt = _joined(panel)
	var want := "Wł." if other == Lang.PL else "On"
	var not_want := "On" if other == Lang.PL else "Wł."
	if not rebuilt.split("\n").has(want) or rebuilt.split("\n").has(not_want):
		_fail("[%s→%s] the settings panel was not rebuilt in the new language" % [code, other])
	Lang.set_code(code)
	hud.queue_free()
	vp.queue_free()


## A word the same in both languages in another sense (Auto, Ultra, Radio ...) is not a leak.
func _word_shared(word: String, _code: String) -> bool:
	return word in ["Auto", "Ultra", "Radio", "60", "30"]


## The title screen: the tagline and prompt in one language, and the buttons switch it.
func _check_title(code: String) -> void:
	var title: CanvasLayer = Title.new()
	root.add_child(title)
	await process_frame
	var picked: Array[String] = []
	title.language_chosen.connect(func(c: String) -> void: picked.append(c))
	title.set_ready()
	await process_frame
	var text := _joined(title)
	var tag_pl: String = Title.TAGLINE_PL
	var tag_en: String = Title.TAGLINE_EN
	_expect("title tagline", text, tag_pl if code == Lang.PL else tag_en, tag_en if code == Lang.PL else tag_pl, code)
	_expect("title prompt", text, "DOTKNIJ, BY JECHAĆ" if code == Lang.PL else "TAP TO DRIVE",
			"TAP TO DRIVE" if code == Lang.PL else "DOTKNIJ, BY JECHAĆ", code)
	if not text.contains("POLSKI") or not text.contains("ENGLISH"):
		_fail("[%s] the title has no POLSKI / ENGLISH buttons" % code)
	var other: String = Lang.EN if code == Lang.PL else Lang.PL
	title.choose_language(other)
	await process_frame
	text = _joined(title)
	_expect("title after switching to " + other, text, tag_pl if other == Lang.PL else tag_en, tag_en if other == Lang.PL else tag_pl, other)
	if picked != [other] or Lang.code != other:
		_fail("[%s] choosing %s on the title must set the language and tell main.gd (%s, %s)" % [code, other, picked, Lang.code])
	title.can_resume = true
	title.resume_line = "1 000 zł"
	title.screen = Title.CONFIRM
	title._set_prompt()
	text = _joined(title)
	var yes := "TAK, OD NOWA" if other == Lang.PL else "YES, START OVER"
	var no_yes := "YES, START OVER" if other == Lang.PL else "TAK, OD NOWA"
	_expect("title question", text, yes, no_yes, other)
	Lang.set_code(code)
	title.queue_free()


## Stock text outside the widgets: the credits, the ladder rows.
func _check_stock(code: String) -> void:
	for sec in Credits.sections():
		for line in sec[2]:
			var shown := Lang.split(str(line), " ‖ ")
			if " ‖ " in shown:
				_fail("[%s] a credits line keeps its pair separator: '%s'" % [code, line])
	for row in Ladder.new().rows(true):
		var t := str(row[0])
		var polish := t.contains("szacunek") or t.contains("otwarty") or t.contains("w nocy") or t.contains("Finał")
		var english := t.contains("respect") or t.contains("open") or t.contains("at night") or t.contains("Final")
		if polish and english:
			_fail("[%s] a ladder row shows both languages: '%s'" % [code, t])
		if code == Lang.EN and polish:
			_fail("[en] a ladder row is in Polish: '%s'" % t)
		if code == Lang.PL and english:
			_fail("[pl] a ladder row is in English: '%s'" % t)
