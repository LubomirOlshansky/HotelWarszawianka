extends SceneTree
## The tasting at the Palm as Zbyszek's livestream (palm_tasting.gd's rules, palm_tasting_ui.gd's
## view; plan doc "First 10 minutes: Tajny klient", "The river scene and the viral moment"):
##   - the beats in order: the viewfinder, the hello, the chew (the chat frozen), the MLASK, his
##     verdict line by line, the drumroll, the grade, the fan's photo, the RECENZJA card, done; a tap too soon after
##     a line does nothing; the card holds CARD_S before its tap;
##   - a held × skips to the card; a perfect run's board reads 11;
##   - the chat: three lines at most, the viewers climb and jump at the MLASK and the grade;
##   - every line the rules and the view ask is in dialogue.json "palm_tasting" in both languages,
##     every chat bag has lines, all drawable by the scene's font, and every chat line fits the
##     chat's scrim on the narrowest screen;
##   - the scene plays itself (auto) to the end in under 30 s, and the view to `finished`.
##   godot --headless --path game --script res://tools/check_palm_tasting.gd -- --nosave

const Tasting := preload("res://scripts/palm_tasting.gd")
const TastingUi := preload("res://scripts/palm_tasting_ui.gd")
const Pen := preload("res://scripts/toon_pen.gd")

## Every tag the rules and the view ask (the chat bags and "name_" + the speaker built by name).
const TAGS := ["live", "viewers", "channel", "rec", "skip", "tap", "drumroll", "mlask", "card_title", "card_order",
		"card_grade", "card_badge", "card_game", "card_shot", "cracked", "btn_next", "name_kebabulo", "name_zbyszek",
		"place", "name_fan", "fan_ask", "fan_yes", "snap", "print_caption"]
const BAGS := ["chat_in", "chat_cam", "chat_hello", "chat_mlask", "chat_verdict", "chat_grade", "chat_perfect", "chat_fan", "handles"]

var problems: Array[String] = []
var checks := 0
var _view: TastingUi
var _got: Array = []
var _steps := 0


func _initialize() -> void:
	_words()
	_beats()
	_skip_and_perfect()
	_auto()
	_view = TastingUi.new()
	_view.auto_play = true
	root.add_child(_view)
	_view.finished.connect(func(r: Dictionary) -> void: _got.append(r))
	_view.open(_spec(8.6))


func _process(_dt: float) -> bool:
	if _got.is_empty() and _steps < 3000:
		_view._process(1.0 / 30.0)
		_steps += 1
		return false
	_expect(_got.size() == 1, "the view's livestream ends with `finished` (after %d steps)" % _steps)
	if _got.size() == 1:
		_expect(not bool((_got[0] as Dictionary)["skipped"]), "the auto livestream is not skipped: %s" % _got[0])
	_expect(not _view.inside, "the view is closed after the card")
	for p in problems:
		print("  PROBLEM " + p)
	print("check_palm_tasting: %s" % ("OK (%d checks, the auto livestream in %.1f s)" % [checks, _steps / 30.0] if problems.is_empty() else "%d problems" % problems.size()))
	quit(0 if problems.is_empty() else 1)
	return true


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		problems.append(what)


func _spec(g: float) -> Dictionary:
	return {
		"hello": ["„Nie mów nic. Gryzę.”", "\"Don't say a thing. I'm biting.\""],
		"verdict": [["Ale dobry.", "So good."], ["Buła nie za sucha.", "The bun's not too dry."], ["Jak z Berlina.", "Like Berlin."]],
		"roast": ["Uczciwie.", "Fair."],
		"grade": g,
		"grade_label": "11 / 10" if g >= 11.0 else "%.1f / 10" % g,
		"order": ["XXL · CZOSNKOWY", "XXL · GARLIC"],
		"badge": ["ZŁOTY MLASK", "GOLDEN SMACK"],
	}


func _run(s: Tasting, secs: float) -> void:
	var n := int(secs * 60.0)
	for i in n:
		s.tick(1.0 / 60.0)


func _beats() -> void:
	var s := Tasting.new(_spec(8.6))
	_expect(s.phase == Tasting.Phase.IN, "it opens on the viewfinder")
	_expect(not s.tap(), "a tap in the viewfinder does nothing")
	_run(s, Tasting.IN_S + 0.05)
	_expect(s.phase == Tasting.Phase.HELLO and s.who == "kebabulo", "then his hello")
	_expect(not s.tap(), "a tap right after a line does nothing")
	_run(s, Tasting.TAP_S)
	_expect(s.tap() and s.phase == Tasting.Phase.CHEW, "a tap: the bite")
	var chat_n := s.chat.size()
	var last: Dictionary = s.chat.back() if chat_n > 0 else {}
	_run(s, Tasting.CHEW_S * 0.9)
	_expect(s.chat.size() == chat_n and (chat_n == 0 or s.chat.back() == last), "the chat is frozen while he chews")
	var v0 := s.viewers
	_run(s, Tasting.CHEW_S * 0.1 + 0.05)
	_expect(s.phase == Tasting.Phase.MLASK and s.viewers > v0, "then the MLASK, the viewers jump (%d to %d)" % [v0, s.viewers])
	_run(s, Tasting.MLASK_S)
	_expect(s.phase == Tasting.Phase.VERDICT and s.line_i == 0, "then his verdict")
	for i in 2:
		_run(s, Tasting.TAP_S + 0.05)
		s.tap()
	_expect(s.phase == Tasting.Phase.VERDICT and s.line_i == 2 and str(s.line[0]).contains("Berlina"), "line by line, a tap each")
	_run(s, Tasting.TAP_S + 0.05)
	s.tap()
	_expect(s.phase == Tasting.Phase.DRUM and s.who == "zbyszek", "then Zbyszek's drumroll")
	_run(s, Tasting.DRUM_S + 0.05)
	_expect(s.phase == Tasting.Phase.GRADE and s.board_text() == "8,6", "then the grade: %s" % s.board_text())
	_run(s, Tasting.TAP_S + 0.05)
	s.tap()
	_expect(s.phase == Tasting.Phase.FAN and s.who == "fan", "then a fan asks for a photo")
	_run(s, Tasting.TAP_S + 0.05)
	_expect(not s.tap(), "a tap while the fan walks up does nothing")
	_run(s, Tasting.FAN_WALK_S)
	_expect(s.tap() and s.phase == Tasting.Phase.FAN and s.who == "kebabulo", "a tap: his yes")
	_run(s, Tasting.TAP_S + 0.05)
	_expect(s.tap() and s.phase == Tasting.Phase.SELFIE, "a tap: the selfie")
	_run(s, Tasting.SELFIE_S + 0.05)
	_expect(s.phase == Tasting.Phase.CARD, "then the RECENZJA card")
	_run(s, Tasting.TAP_S + 0.05)
	_expect(not s.tap(), "the card holds before its tap")
	_run(s, Tasting.CARD_S)
	_expect(s.tap() and s.done(), "then done")
	_expect(s.chat.size() <= Tasting.CHAT_MAX and s.chat.size() > 0, "the chat keeps %d lines at most (%d)" % [Tasting.CHAT_MAX, s.chat.size()])
	_expect(s.viewers > Tasting.VIEWERS_0 + 500, "the viewers climbed (%d)" % s.viewers)


func _skip_and_perfect() -> void:
	var s := Tasting.new(_spec(9.0))
	_run(s, Tasting.IN_S + 0.05)
	for i in int(Tasting.SKIP_S * 60.0) + 2:
		s.tick(1.0 / 60.0, true)
	_expect(s.phase == Tasting.Phase.CARD and s.skipped, "a held × skips to the card")
	s = Tasting.new(_spec(11.0))
	_expect(s.perfect and s.board_text() == "11", "a perfect run reads 11 on the board")
	s = Tasting.new({"cam": true})
	_expect(s.viewers > Tasting.VIEWERS_0, "the camera's stream starts with more viewers")


func _auto() -> void:
	var s := Tasting.new(_spec(8.6))
	s.auto_play = true
	var n := 0
	while not s.done() and n < 60 * 60:
		s.tick(1.0 / 60.0)
		n += 1
	_expect(s.done() and n / 60.0 < 30.0, "the auto livestream ends in under 30 s (%.1f s)" % (n / 60.0))


func _words() -> void:
	for t: String in TAGS:
		_expect(Tasting.has_words(t), "dialogue.json \"%s\" has no line \"%s\"" % [Tasting.GROUP, t])
		_font(t, Tasting.say(t))
	var probe := TastingUi.new()
	probe.W = TastingUi.MIN_W
	var chat_w := probe.chat_w()
	probe.free()
	for b: String in BAGS:
		var lines := Tasting.lines_of(b)
		_expect(lines.size() >= (3 if b != "handles" else 6), "the chat bag \"%s\" has lines (%d)" % [b, lines.size()])
		for l: Array in lines:
			_font(b, l)
	var widest := ""
	for h: Array in Tasting.lines_of("handles"):
		if Pen.text_w(str(h[0]), TastingUi.T_CHAT) > Pen.text_w(widest, TastingUi.T_CHAT):
			widest = str(h[0])
	for b: String in BAGS:
		if b == "handles":
			continue
		for l: Array in Tasting.lines_of(b):
			for lang in 2:
				var w := TastingUi.chat_line_w(widest, str(l[lang]))
				_expect(w <= chat_w, "the chat line \"%s\" fits the chat's scrim (%d of %d units)" % [l[lang], w, chat_w])


func _font(tag: String, p: Array) -> void:
	var f := Pen.font()
	for s: String in [str(p[0]), str(p[1])]:
		_expect(s != "", "\"%s\" in both languages" % tag)
		for ch in s:
			if ch != " " and ch != "\n" and not f.has_char(ch.unicode_at(0)):
				problems.append("\"%s\": the scene's font has no '%s': %s" % [tag, ch, s])
				break
