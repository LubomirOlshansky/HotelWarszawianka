extends SceneTree
## SZYBA, the Tajny klient's payoff at Kemal's window (kemal_window.gd's rules, kemal_window_ui.gd's
## view; Fable's critique 2026-11-26, section 3 "Sticker and payoff"):
##   - the beats in order for both endings: the wipe in, the sticker in the winner's hand, the tap,
##     the slap, the high five only when Kebabulo won, the queue, Kemal's tears, PARAGON, done; a tap
##     too soon does nothing, a tap mid-queue does nothing, a tap in the tears after CRY_TAP_S cuts
##     them, the receipt holds CARD_S before its tap; about 6 s from the tap to the receipt;
##   - the queue: QUEUE_N people set off one by one, all of them by the tears;
##   - a held × skips to the receipt with the sticker counted as slapped;
##   - the words: every tag the view asks is in dialogue.json "kemal_window" in both languages and
##     drawable by the kit's 5x7 font; at the narrowest screen (MIN_W) the winner's line and Kemal's
##     (dialogue.json "tajny_klient") wrap into the bubble under the sign and over the counter, the
##     tap hints and the shouts fit, and the receipt's rows fit its width and the screen's height in
##     the worst case (a two-line order, two badges, the leak);
##   - the view plays both endings by itself to `finished`, drawing every beat (a dry frame: no
##     errors, the rects within RECTS_MAX).
##   godot --headless --path game --script res://tools/check_kemal_window.gd -- --nosave

const Win := preload("res://scripts/kemal_window.gd")
const WinUi := preload("res://scripts/kemal_window_ui.gd")
const Kit := preload("res://scripts/pixel_kit.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Lang := preload("res://scripts/lang.gd")

## The most rects one frame of the view may draw (the back and the front included).
const RECTS_MAX := 7000
## Every tag the rules and the view ask.
const TAGS := ["sign", "plask", "piona", "tap_slap", "tap_five", "skip", "name_kemal", "name_kebabulo", "r_place", "r_qty",
		"r_grade", "r_pay", "r_respect", "r_note", "r_zl", "btn_next", "sticker_word"]
## The lines tajny_klient.gd hands in.
const HANDED := ["race_won", "race_lost", "kemal_cry", "result_title", "leak", "badge_gold", "badge_cam", "badge_sold"]

var problems: Array[String] = []
var checks := 0
var _tk: Dictionary = {}
var _views: Array = []
var _got: Array = []
var _steps := 0
var _seen: Dictionary = {}
var _most := 0


func _initialize() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	for l: Array in d.get("tajny_klient", []):
		if l.size() >= 3:
			_tk[str((l[2] as Dictionary).get("only", ""))] = [str(l[0]), str(l[1])]
	_words()
	_beats(true)
	_beats(false)
	_skip()
	_auto()
	for won: bool in [true, false]:
		var v := WinUi.new()
		v.auto_play = true
		root.add_child(v)
		v.finished.connect(func(r: Dictionary) -> void: _got.append(r))
		v.open(_spec(won, not won))
		_views.append(v)


func _process(_dt: float) -> bool:
	var live := false
	for v: WinUi in _views:
		if v.inside:
			live = true
			v._process(1.0 / 30.0)
			if v.inside and v.win != null:
				var key := "%s_%d" % ["won" if v.win.won else "lost", int(v.win.phase)]
				if not _seen.has(key) or _steps % 5 == 0:
					_most = maxi(_most, v.dry_frame())
				_seen[key] = true
	_steps += 1
	if live and _steps < 1200:
		return false
	for won: bool in [true, false]:
		for ph in range(Win.Phase.IN, Win.Phase.DONE):
			if ph == Win.Phase.FIVE and won:
				continue
			_expect(_seen.has("%s_%d" % ["won" if won else "lost", ph]), "the view (%s) shows the beat %s" % ["won" if won else "lost", Win.Phase.keys()[ph]])
	_expect(not _seen.has("won_%d" % Win.Phase.FIVE), "no high five when the player won")
	_expect(_most > 0 and _most <= RECTS_MAX, "a frame of the view draws %d rects (at most %d)" % [_most, RECTS_MAX])
	_expect(_got.size() == 2, "both views end with `finished` (%d, after %d steps)" % [_got.size(), _steps])
	for r: Dictionary in _got:
		_expect(not bool(r["skipped"]) and bool(r["stuck"]), "the auto window is not skipped and the sticker is on: %s" % r)
	for v: WinUi in _views:
		_expect(not v.inside, "the view is closed after the receipt")
	for p in problems:
		print("  PROBLEM " + p)
	print("check_kemal_window: %s" % ("OK (%d checks, both endings by themselves in %.1f s, at most %d rects a frame)" % [checks, _steps / 30.0, _most] if problems.is_empty() else "%d problems" % problems.size()))
	quit(0 if problems.is_empty() else 1)
	return true


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		problems.append(what)


func _t(tag: String) -> Array:
	return _tk.get(tag, ["", ""])


func _spec(won: bool, worst := false) -> Dictionary:
	var badges: Array = [_t("badge_cam"), _t("badge_sold")] if worst else [_t("badge_gold")]
	return {
		"won": won,
		"line": _t("race_won" if won else "race_lost"),
		"cry": _t("kemal_cry"),
		"title": _t("result_title"),
		"order": ["W BUŁCE · CZOSNKOWY · EXTRA", "IN A BUN · GARLIC · EXTRA"] if worst else ["XXL · CZOSNKOWY", "XXL · GARLIC"],
		"grade": "9,4 / 10",
		"pay": 120,
		"respect": 30,
		"badges": badges,
		"leak": _t("leak") if worst else [],
	}


func _run(s: Win, secs: float) -> void:
	for i in int(secs * 60.0):
		s.tick(1.0 / 60.0)


func _beats(won: bool) -> void:
	var tag := "won" if won else "lost"
	var s := Win.new(_spec(won))
	_expect(s.phase == Win.Phase.IN and not s.tap(), "%s: it opens on the wipe and a tap does nothing" % tag)
	_run(s, Win.IN_S + 0.05)
	_expect(s.phase == Win.Phase.READY and not s.stuck(), "%s: then the sticker in the hand" % tag)
	_expect(not s.tap(), "%s: a tap right away does nothing" % tag)
	_run(s, 3.0)
	_expect(s.phase == Win.Phase.READY, "%s: it waits for the tap" % tag)
	_expect(s.tap() and s.phase == Win.Phase.SLAP and s.stuck(), "%s: a tap slaps it" % tag)
	var t0 := s.total
	_run(s, Win.SLAP_S + 0.05)
	if won:
		_expect(s.phase == Win.Phase.QUEUE, "won: then the queue (no high five)")
	else:
		_expect(s.phase == Win.Phase.FIVE, "lost: then the high five")
		_run(s, Win.FIVE_S)
		_expect(s.phase == Win.Phase.QUEUE, "lost: then the queue")
	_expect(s.walkers() >= 1, "%s: the first of the queue sets off" % tag)
	_run(s, Win.TAP_S + 0.05)
	_expect(not s.tap() and s.phase == Win.Phase.QUEUE, "%s: a tap mid-queue does nothing" % tag)
	_run(s, Win.QUEUE_S)
	_expect(s.phase == Win.Phase.CRY and s.walkers() == Win.QUEUE_N, "%s: then Kemal's tears, all %d of the queue on their way" % [tag, Win.QUEUE_N])
	_run(s, Win.TAP_S + 0.05)
	_expect(not s.tap(), "%s: his line lands before a tap cuts it" % tag)
	_run(s, Win.CRY_S)
	_expect(s.phase == Win.Phase.PARAGON, "%s: then PARAGON by itself" % tag)
	var secs := s.total - t0
	_expect(secs >= 4.5 and secs <= 8.0, "%s: about 6 s from the tap to the receipt (%.1f s)" % [tag, secs])
	_run(s, Win.TAP_S + 0.05)
	_expect(not s.tap(), "%s: the receipt holds before its tap" % tag)
	_run(s, Win.CARD_S)
	_expect(s.tap() and s.done(), "%s: a tap and done" % tag)
	_expect(bool(s.result()["won"]) == won and bool(s.result()["stuck"]), "%s: the result: %s" % [tag, s.result()])
	# a tap after CRY_TAP_S cuts the tears short
	var c := Win.new(_spec(won))
	c.auto_play = true
	var n := 0
	while c.phase != Win.Phase.CRY and n < 1200:
		c.tick(1.0 / 60.0)
		n += 1
	c.auto_play = false
	_run(c, Win.CRY_TAP_S + 0.05)
	_expect(c.tap() and c.phase == Win.Phase.PARAGON, "%s: a tap after %.1f s cuts the tears short" % [tag, Win.CRY_TAP_S])


func _skip() -> void:
	var s := Win.new(_spec(true))
	_run(s, Win.IN_S + 0.05)
	for i in int(Win.SKIP_S * 60.0) + 2:
		s.tick(1.0 / 60.0, true)
	_expect(s.phase == Win.Phase.PARAGON and s.skipped and s.stuck(), "a held × skips to the receipt, the sticker on")
	_expect(s.walkers() == Win.QUEUE_N, "after a skip the whole queue stands there")


func _auto() -> void:
	for won: bool in [true, false]:
		var s := Win.new(_spec(won))
		s.auto_play = true
		var n := 0
		while not s.done() and n < 60 * 30:
			s.tick(1.0 / 60.0)
			n += 1
		_expect(s.done() and n / 60.0 < 15.0, "the auto window (%s) ends in under 15 s (%.1f s)" % ["won" if won else "lost", n / 60.0])


func _words() -> void:
	for t: String in TAGS:
		_expect(Win.has_words(t), "dialogue.json \"%s\" has no line \"%s\"" % [Win.GROUP, t])
		_font(t, Win.say(t))
	for t: String in HANDED:
		_expect(_tk.has(t), "dialogue.json \"tajny_klient\" has no line \"%s\"" % t)
		_font(t, _t(t))
	var probe := WinUi.new()
	probe.W = WinUi.MIN_W
	var bw := int(probe.bubble_w())
	var right := WinUi.MIN_W - 6.0
	for t: String in ["race_won", "race_lost", "kemal_cry"]:
		for lang in 2:
			var lines := Kit.wrap(WinUi.shown(str(_t(t)[lang])), bw - 10)
			for line in lines:
				_expect(Kit.text_w(line) <= bw - 10, "the bubble's line \"%s\" fits (%d of %d)" % [line, Kit.text_w(line), bw - 10])
			var top := WinUi.bubble_bottom() - 6.0 - lines.size() * 10.0 - 6.0
			_expect(top >= 60.0, "the bubble for \"%s\" stays under the sign (top %d)" % [t, top])
	for t: String in ["tap_slap", "tap_five"]:
		for lang in 2:
			_expect(Kit.text_w(str(Win.say(t)[lang])) + 8 <= 140, "the hint \"%s\" fits by the hand (%d)" % [Win.say(t)[lang], Kit.text_w(str(Win.say(t)[lang]))])
	for t: String in ["plask", "piona"]:
		for lang in 2:
			var w := PixelFont.width(str(Win.say(t)[lang]).to_upper()) * (3 if t == "plask" else 2)
			_expect(w <= right * 0.5, "the shout \"%s\" fits (%d)" % [Win.say(t)[lang], w])
	var sw := 0
	for lang in 2:
		sw = maxi(sw, Kit.text_w(str(Win.say("sign")[lang])) * 2)
	_expect(sw <= WinUi.MIN_W - 40, "the sign fits the narrowest screen (%d)" % sw)
	probe.free()
	for code: String in ["pl", "en"]:
		Lang.set_code(code)
		for worst: bool in [false, true]:
			var w := Win.new(_spec(true, worst))
			var rows := WinUi.receipt_rows(w, WinUi.MIN_W)
			var h := WinUi.receipt_h(rows)
			_expect(h <= WinUi.H - 8, "the receipt (%s%s) fits the screen's height (%d of %d)" % [code, ", the worst case" if worst else "", h, WinUi.H - 8])
			for r: Array in rows:
				var kind := str(r[0])
				var wide := 0
				match kind:
					"title":
						wide = Kit.text_w(str(r[1]), 2)
					"pair":
						wide = Kit.text_w(str(r[1])) + 6 + Kit.text_w(str(r[2]))
					"badge":
						wide = Kit.text_w(str(r[1])) + 12
					"centre", "line", "leak":
						wide = Kit.text_w(str(r[1]))
				_expect(wide <= WinUi.RECEIPT_W - 14, "the receipt's row \"%s\" (%s) fits (%d of %d)" % [str(r.slice(1)), code, wide, WinUi.RECEIPT_W - 14])
				if r.size() > 1:
					_font("receipt " + kind, [str(r[1]), str(r[1])])
	Lang.set_code("pl")


func _font(tag: String, p: Array) -> void:
	for s: String in [str(p[0]), str(p[1])]:
		if s == "" and tag.begins_with("receipt"):
			continue
		_expect(s != "", "\"%s\" in both languages" % tag)
		var up := WinUi.shown(s).to_upper().replace("\"", "”").replace("{N}", "")
		for ch in up:
			if ch != " " and ch != "\n" and PixelFont.char_width(ch) == 0:
				problems.append("\"%s\": the kit's 5x7 font has no '%s': %s" % [tag, ch, s])
				break
