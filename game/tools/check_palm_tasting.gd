extends SceneTree
## The tasting at the Palm as Zbyszek's livestream (palm_tasting.gd's rules, palm_tasting_ui.gd's
## view; plan doc "First 10 minutes: Tajny klient", "The river scene and the viral moment"):
##   - the beats in order: the viewfinder, the hello, the chew (the chat frozen), the MLASK, his
##     verdict line by line, the drumroll, the grade, the fan's photo, the RECENZJA card, done; a tap too soon after
##     a line does nothing; the card holds CARD_S before its tap;
##   - the MLASK is held MLASK_S by itself (the autopilot does not cut it), a tap before MLASK_TAP_S does
##     nothing and one after cuts it short (Fable's critique 2026-11-26, section 2 row 1); its caption
##     (F's "…ALE DOBRY.", dialogue.json "tajny_klient" `mlask_caption`) fits the narrowest screen;
##   - a held × skips to the card; a perfect run's board reads 11;
##   - the chat: three lines at most, the viewers climb and jump at the MLASK and the grade;
##   - every line the rules and the view ask is in dialogue.json "palm_tasting" in both languages,
##     every chat bag has lines, all drawable by the kit's 5x7 pixel font (pixel_font.gd), and on
##     the narrowest screen (MIN_W) every chat line fits left of the bubble, every spoken line wraps
##     into the bubble below the chips, the MLASK's chat panel and the card's words fit;
##   - the scene plays itself (auto) to the end in under 30 s, and the view to `finished`, passing
##     every beat (FAN, SELFIE and CARD among them) and drawing each (a dry frame: no errors, the
##     rects within RECTS_MAX).
##   godot --headless --path game --script res://tools/check_palm_tasting.gd -- --nosave

const Tasting := preload("res://scripts/palm_tasting.gd")
const TastingUi := preload("res://scripts/palm_tasting_ui.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

## The most rects one frame of the view may draw (the back's included).
const RECTS_MAX := 9000

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
var _seen: Dictionary = {}
var _most := 0


func _initialize() -> void:
	_words()
	_beats()
	_mlask_hold()
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
		if _view.inside and _view.tasting != null:
			var ph := int(_view.tasting.phase)
			if not _seen.has(ph) or _steps % 5 == 0:
				_most = maxi(_most, _view.dry_frame())
			_seen[ph] = true
		return false
	for ph in range(Tasting.Phase.IN, Tasting.Phase.DONE):
		_expect(_seen.has(ph), "the view shows the beat %s" % Tasting.Phase.keys()[ph])
	_expect(_most > 0 and _most <= RECTS_MAX, "a frame of the view draws %d rects (at most %d)" % [_most, RECTS_MAX])
	_expect(_got.size() == 1, "the view's livestream ends with `finished` (after %d steps)" % _steps)
	if _got.size() == 1:
		_expect(not bool((_got[0] as Dictionary)["skipped"]), "the auto livestream is not skipped: %s" % _got[0])
	_expect(not _view.inside, "the view is closed after the card")
	for p in problems:
		print("  PROBLEM " + p)
	print("check_palm_tasting: %s" % ("OK (%d checks, the auto livestream in %.1f s, at most %d rects a frame)" % [checks, _steps / 30.0, _most] if problems.is_empty() else "%d problems" % problems.size()))
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
		"caption": ["…ALE DOBRY.", "…SO GOOD."],
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
	_run(s, Tasting.MLASK_TAP_S - 0.1)
	_expect(not s.tap() and s.phase == Tasting.Phase.MLASK, "a tap before %.1f s does not cut the MLASK" % Tasting.MLASK_TAP_S)
	_run(s, Tasting.MLASK_S - Tasting.MLASK_TAP_S + 0.15)
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


## The MLASK's hold: a tap after MLASK_TAP_S cuts it short; it lasts at least 2 s untouched and the
## staging lands in order.
func _mlask_hold() -> void:
	_expect(Tasting.MLASK_S >= 2.0, "the MLASK is held %.1f s (at least 2)" % Tasting.MLASK_S)
	_expect(Tasting.MLASK_FACE_AT < Tasting.MLASK_INSET_AT and Tasting.MLASK_INSET_AT < Tasting.MLASK_CHAT_AT
			and Tasting.MLASK_CHAT_AT < Tasting.MLASK_CAPTION_AT and Tasting.MLASK_CAPTION_AT < Tasting.MLASK_S,
			"the MLASK's staging in order: the face, Zbyszek, the chat, the caption")
	var s := Tasting.new(_spec(8.6))
	_run(s, Tasting.IN_S + 0.05)
	_run(s, Tasting.TAP_S)
	s.tap()
	_run(s, Tasting.CHEW_S + 0.05)
	_run(s, Tasting.MLASK_TAP_S + 0.05)
	_expect(s.tap() and s.phase == Tasting.Phase.VERDICT, "a tap after %.1f s cuts the MLASK short" % Tasting.MLASK_TAP_S)
	var words: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var cap: Array = []
	for l: Array in words.get("tajny_klient", []):
		if l.size() >= 3 and str((l[2] as Dictionary).get("only", "")) == "mlask_caption":
			cap = l
	_expect(cap.size() >= 2 and str(cap[0]).to_lower().contains("ale dobry"), "dialogue.json \"tajny_klient\" has F's caption \"…ale dobry\" (mlask_caption)")
	if cap.size() >= 2:
		_font("mlask_caption", cap)
		for lang in 2:
			var t := TastingUi.shown(str(cap[lang]))
			var sc := TastingUi.caption_scale(t, TastingUi.MIN_W)
			var w := Kit.text_w(t, sc) + 8 * sc
			_expect(w <= TastingUi.MIN_W - 16, "the MLASK caption \"%s\" fits the narrowest screen (%d of %d)" % [t, w, TastingUi.MIN_W - 16])


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
	var held := 0
	while not s.done() and n < 60 * 60:
		s.tick(1.0 / 60.0)
		if s.phase == Tasting.Phase.MLASK:
			held += 1
		n += 1
	_expect(held / 60.0 >= Tasting.MLASK_S - 0.05, "the autopilot lets the MLASK run its %.1f s (%.2f s)" % [Tasting.MLASK_S, held / 60.0])
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
		if Kit.text_w(str(h[0])) > Kit.text_w(widest):
			widest = str(h[0])
	for b: String in BAGS:
		if b == "handles":
			continue
		for l: Array in Tasting.lines_of(b):
			for lang in 2:
				var w := TastingUi.chat_line_w(widest, str(l[lang]))
				_expect(w <= chat_w, "the chat line \"%s\" fits left of the bubble (%d of %d units)" % [l[lang], w, chat_w])
				# the MLASK's chat panel: handle + text + padding, at most half the screen
				var pw := Kit.text_w(widest) + 4 + Kit.text_w(TastingUi.shown(str(l[lang]))) + 10
				_expect(pw <= TastingUi.MIN_W * 0.5, "the MLASK chat panel fits \"%s\" (%d units)" % [l[lang], pw])
	_fits()


## The spoken lines wrap into the bubble without climbing into the chips; the card's words fit.
func _fits() -> void:
	var probe := TastingUi.new()
	probe.W = TastingUi.MIN_W
	var bw := int(probe.line_w())
	probe.free()
	var spoken: Array = [Tasting.say("drumroll"), Tasting.say("fan_ask"), Tasting.say("fan_yes")]
	var spec := _spec(8.6)
	spoken.append(spec["hello"])
	spoken.append_array(spec["verdict"])
	for l: Array in spoken:
		for lang in 2:
			var lines := Kit.wrap(TastingUi.shown(str(l[lang])), bw - 10)
			for line in lines:
				_expect(Kit.text_w(line) <= bw - 10, "the bubble's line \"%s\" fits (%d of %d)" % [line, Kit.text_w(line), bw - 10])
			var top := TastingUi.H - 8.0 - lines.size() * 10.0 - 6.0 - 6.0
			_expect(top >= 34.0, "the bubble for \"%s\" stays below the chips (top %d)" % [l[lang], top])
	for tag: String in ["card_title", "place", "card_shot", "card_game", "card_order"]:
		for lang in 2:
			var w := Kit.text_w(TastingUi.shown(str(Tasting.say(tag)[lang]))) * (2 if tag == "card_title" else 1)
			_expect(w <= 184 - 12, "the card's \"%s\" fits (%d of 172)" % [Tasting.say(tag)[lang], w])
	var skip_w := 0
	for lang in 2:
		skip_w = maxi(skip_w, Kit.text_w(str(Tasting.say("skip")[lang])))
	var chips := 6 + 4 + Kit.text_w(str(Tasting.say("live")[0])) + 9 + 2 + Kit.text_w(str(Tasting.say("viewers")[0]).replace("{n}", "12 345")) + 9 + 30
	_expect(chips + skip_w + 10 + 8 <= TastingUi.MIN_W, "the top chips and skip fit side by side (%d of %d)" % [chips + skip_w + 18, TastingUi.MIN_W])


func _font(tag: String, p: Array) -> void:
	for s: String in [str(p[0]), str(p[1])]:
		_expect(s != "", "\"%s\" in both languages" % tag)
		var up := TastingUi.shown(s).to_upper().replace("\"", "\u201d").replace("{N}", "")
		for ch in up:
			if ch != " " and ch != "\n" and PixelFont.char_width(ch) == 0:
				problems.append("\"%s\": the kit's 5x7 font has no '%s': %s" % [tag, ch, s])
				break
