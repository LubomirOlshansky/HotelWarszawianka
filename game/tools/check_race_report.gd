extends SceneTree
## Racer AI step 6a (docs/design/race-ai.md 6.1): the race report (race_report.gd), what a street
## race's result card says beyond who won, and the card's picture slot (hud.gd `set_card_art`).
## Toy races on a straight line: two cars' places a frame. Checks that:
## - the ways are kept every STEP m, their metres and the seconds stood add up;
## - the cause is the route when the loser's way was longer (a yard named when the rival took
##   one, "the rival got lost" when the player won and the rival took a wrong turn), the standing
##   when the loser stood, the pace when the loser was slower on the move, and "an even race"
##   under NAMED s;
## - the three shares add up to the gap between the two cars' times;
## - the card's lines are there in Polish and English, short enough for the card, with a decimal
##   comma in the Polish kilometres, and the rival's moments list only what happened;
## - the picture's rectangle holds both ways and the finish in the control's own shape;
## - the HUD's card takes a picture beside its words, inside the screen (on a phone the card is
##   wider by the picture; on a small screen it keeps its width and the words wrap narrower), and
##   the next card, or the card's end, drops it and is as wide as before.
##   godot --headless --path game --script res://tools/check_race_report.gd

const RaceReport := preload("res://scripts/race_report.gd")
const Hud := preload("res://scripts/hud.gd")
const DT := 1.0 / 60.0
const MAX_LINE := 84

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  FAIL: " + what)


func _initialize() -> void:
	_run()


## A race into a report: each car drives `metres` at `speed` after standing `stood` s first (the
## player along x, the rival along x 5 m aside), until the first is home; returns the report
## closed with `counts`.
func _race(p_m: float, p_v: float, p_stood: float, r_m: float, r_v: float, r_stood: float, counts := {}) -> RaceReport:
	var rep := RaceReport.new()
	var p := 0.0
	var r := 0.0
	var t := 0.0
	while p < p_m and r < r_m:
		var pv := p_v if t >= p_stood else 0.0
		var rv := r_v if t >= r_stood else 0.0
		p += pv * DT
		r += rv * DT
		t += DT
		rep.tick(DT, Vector2(p, 0.0), pv, Vector2(r, 5.0), rv)
	var won := p >= p_m
	var left := (r_m - r) if won else (p_m - p)
	var margin := left / (r_v if won else p_v)
	rep.close(won, margin, left, counts)
	return rep


func _lines_ok(rep: RaceReport, what: String) -> void:
	var lines := rep.lines("Pani Halina")
	_expect(lines.size() >= 2, "%s: %d lines on the card, at least what decided it and the two ways" % [what, lines.size()])
	for l: Array in lines:
		_expect(l.size() == 2 and String(l[0]) != "" and String(l[1]) != "", "%s: a line without both languages: %s" % [what, l])
		for text: String in l:
			_expect(text.length() <= MAX_LINE, "%s: a line of %d characters (at most %d): %s" % [what, text.length(), MAX_LINE, text])
			_expect(not "%" in text and not "nan" in text.to_lower() and not "inf" in text.to_lower(), "%s: a broken line: %s" % [what, text])
	var texts := rep.texts("Pani Halina")
	_expect(texts.size() == 2 and String(texts[0]).count("\n") == lines.size() - 1, "%s: texts() is not a line each" % what)


func _run() -> void:
	await process_frame
	# The ways and the clock.
	var rep := _race(600.0, 20.0, 0.0, 700.0, 20.0, 2.0)
	_expect(absf(rep.player_m - 600.0) <= RaceReport.STEP and rep.player.size() >= 90, "600 m driven kept as %.0f m in %d points" % [rep.player_m, rep.player.size()])
	_expect(absf(rep.time - 30.0) < 0.1, "a race of 30 s timed as %.1f s" % rep.time)
	_expect(absf(rep.rival_still - 2.0) < 0.05 and rep.player_still < 0.05, "stood 2.0 s and 0 s counted as %.2f and %.2f" % [rep.rival_still, rep.player_still])
	_expect(rep.won and rep.closed, "the first car home did not win")

	# Lost on the route: the rival's way 200 m shorter through a yard.
	rep = _race(1000.0, 20.0, 0.0, 800.0, 20.0, 0.0, {"yards": 1})
	_expect(not rep.won and rep.cause == RaceReport.Cause.ROUTE, "a way 200 m longer at the same speed: cause %d, not the route" % rep.cause)
	_expect(absf(rep.cause_s - 10.0) < 1.0, "200 m at 20 m/s is worth %.1f s, not 10" % rep.cause_s)
	_expect(absf(rep.player_way - 1000.0) < RaceReport.STEP * 2.0 and absf(rep.rival_way - 800.0) < RaceReport.STEP, "the ways are %.0f and %.0f m, not 1000 and 800" % [rep.player_way, rep.rival_way])
	var first: Array = rep.lines("Pani Halina")[0]
	_expect("podwórko" in String(first[0]) and "yard" in String(first[1]) and "200 m" in String(first[0]), "a race lost to a yard does not say so: %s" % [first])
	_lines_ok(rep, "lost on the route")
	var ways: Array = rep.lines("Pani Halina")[1]
	_expect("1,00 km" in String(ways[0]) and "0,80 km" in String(ways[0]) and "1.00 km" in String(ways[1]), "the ways' line: %s" % [ways])
	var last: Array = rep.lines("Pani Halina")[rep.lines("Pani Halina").size() - 1]
	_expect(String(last[0]) == "Rywal: podwórka 1." and String(last[1]) == "The rival: yards 1.", "the rival's moments: %s" % [last])
	# ... and with no shortcut, the plain words; with none of the moments, no third line.
	rep = _race(1000.0, 20.0, 0.0, 800.0, 20.0, 0.0)
	_expect(rep.lines("Pani Halina").size() == 2, "a rival with no moments has a line of them")
	_expect("bliżej" in String(rep.lines("Pani Halina")[0][0]), "a shorter way with no shortcut: %s" % [rep.lines("Pani Halina")[0]])

	# Lost standing: the same way, the player stood 8 s.
	rep = _race(800.0, 20.0, 8.0, 800.0, 20.0, 0.0)
	_expect(not rep.won and rep.cause == RaceReport.Cause.STILL and absf(rep.cause_s - 8.0) < 0.5, "8 s stood: cause %d worth %.1f s" % [rep.cause, rep.cause_s])
	_expect("8 s" in String(rep.lines("Pani Halina")[0][0]), "the standing's line: %s" % [rep.lines("Pani Halina")[0]])
	_lines_ok(rep, "lost standing")

	# Lost on pace: the same way, 16 against 20 m/s.
	rep = _race(800.0, 16.0, 0.0, 800.0, 20.0, 0.0)
	_expect(not rep.won and rep.cause == RaceReport.Cause.PACE and absf(rep.cause_s - 10.0) < 1.0, "16 against 20 m/s over 800 m: cause %d worth %.1f s" % [rep.cause, rep.cause_s])
	_lines_ok(rep, "lost on pace")

	# Won on the route: the rival took a wrong turn (300 m more).
	rep = _race(800.0, 20.0, 0.0, 1100.0, 20.0, 0.0, {"wrong": 1, "passes": 2})
	_expect(rep.won and rep.cause == RaceReport.Cause.ROUTE and absf(rep.cause_s - 15.0) < 1.5, "the rival's 300 m more: cause %d worth %.1f s" % [rep.cause, rep.cause_s])
	_expect("zabłądził" in String(rep.lines("Słoik")[0][0]) and "got lost" in String(rep.lines("Słoik")[0][1]), "a race won by the rival's wrong turn does not say so: %s" % [rep.lines("Słoik")[0]])
	_expect(String(rep.lines("Słoik")[2][0]) == "Rywal: złe skręty 1 · wyprzedzenia 2.", "the rival's moments: %s" % [rep.lines("Słoik")[2]])
	_lines_ok(rep, "won on the route")
	# Won on pace, won standing.
	rep = _race(800.0, 22.0, 0.0, 800.0, 18.0, 0.0)
	_expect(rep.won and rep.cause == RaceReport.Cause.PACE, "22 against 18 m/s: cause %d, not the pace" % rep.cause)
	_lines_ok(rep, "won on pace")
	rep = _race(800.0, 20.0, 0.0, 800.0, 20.0, 6.0)
	_expect(rep.won and rep.cause == RaceReport.Cause.STILL, "the rival stood 6 s: cause %d, not the standing" % rep.cause)
	_lines_ok(rep, "won standing")

	# An even race, and the shares.
	rep = _race(800.0, 20.0, 0.0, 800.0, 19.8, 0.0)
	_expect(rep.cause == RaceReport.Cause.EVEN and rep.cause_s == 0.0, "a race won by 0.4 s has a cause (%d)" % rep.cause)
	_lines_ok(rep, "an even race")
	for row: Array in [[1000.0, 18.0, 3.0, 850.0, 21.0, 1.0], [700.0, 24.0, 0.0, 900.0, 19.0, 4.0], [900.0, 20.0, 5.0, 900.0, 20.0, 0.0]]:
		rep = _race(row[0], row[1], row[2], row[3], row[4], row[5])
		var gap: float = float(row[0]) / float(row[1]) + float(row[2]) - float(row[3]) / float(row[4]) - float(row[5])
		_expect(absf(rep.route_s + rep.still_s + rep.pace_s - gap) < 0.6, "the shares add up to %.1f s, the gap is %.1f s (%s)" % [rep.route_s + rep.still_s + rep.pace_s, gap, row])

	# The picture's rectangle.
	rep = _race(1000.0, 20.0, 0.0, 800.0, 20.0, 0.0)
	var art := RaceReport.Sketch.new()
	art.report = rep
	art.finish = Vector2(1000.0, 60.0)
	art.size = Vector2(150.0, 104.0)
	var box := art.bounds()
	var held := box.has_point(art.finish)
	for p in rep.player:
		held = held and box.has_point(p)
	for p in rep.rival:
		held = held and box.has_point(p)
	_expect(held, "the picture's rectangle %s leaves out a point of the ways or the finish" % box)
	var inner := art.size - Vector2.ONE * RaceReport.Sketch.PAD * 2.0
	_expect(absf(box.size.x / box.size.y - inner.x / inner.y) < 0.01, "the picture's rectangle is %.2f wide for its height, the control %.2f" % [box.size.x / box.size.y, inner.x / inner.y])
	art.free()

	# The HUD's card with a picture, on a phone and on a small screen.
	for screen: Vector2i in [Vector2i(2532, 1170), Vector2i(1280, 720)]:
		var vp := SubViewport.new()
		vp.size = screen
		vp.disable_3d = true
		root.add_child(vp)
		var hud: CanvasLayer = Hud.new()
		vp.add_child(hud)
		await process_frame
		hud.show_card("PRZEGRANA · 2. MIEJSCE", "Pani Halina pierwsza na mecie: Plac Trzech Krzyży. Zabrakło ci 120 m (o 6,2 s), czas 1:42.3.\n„Zjedz coś, dziecko, bo blade jesteś i wolne.”\n" + rep.texts("Pani Halina")[0],
				PackedStringArray(["OK"]), Color("#e2574c"), false, "Lose · 2nd", "x")
		for k in 4:
			await process_frame
		var card: Control = hud.find_child("card", true, false)
		var plain_w := card.size.x
		var plain_h := card.size.y
		var body_w: float = hud._card_body.custom_minimum_size.x
		_expect(not hud.card_has_art(), "a card has a picture nobody gave it")
		var pic := RaceReport.Sketch.new()
		pic.report = rep
		pic.custom_minimum_size = Vector2(150.0, 104.0) * hud.pt
		hud.set_card_art(pic)
		for k in 4:
			await process_frame
		_expect(hud.card_has_art() and pic.get_parent() != null, "set_card_art did not put the picture on the card")
		var wide := absf(card.size.x - (plain_w + pic.custom_minimum_size.x + Hud.CARD_ART_GAP * hud.pt)) <= 2.0
		_expect(wide == (screen.x == 2532), "on %d px the card with a picture is %.0f px wide, without %.0f (wider on the phone, as wide on a small screen)" % [screen.x, card.size.x, plain_w])
		_expect(wide or absf(card.size.x - plain_w) <= 2.0, "the card with a picture is %.0f px wide, without %.0f" % [card.size.x, plain_w])
		_expect(card.visible and card.position.x >= 0.0 and card.position.x + card.size.x <= screen.x, "the card with a picture is %.0f px wide at x %.0f on a screen of %d (shown: %s)" % [card.size.x, card.position.x, screen.x, card.visible])
		_expect(card.size.y <= plain_h + pic.custom_minimum_size.y, "the picture makes the card %.0f px tall, without %.0f" % [card.size.y, plain_h])
		_expect(pic.size.x >= 149.0 * hud.pt and pic.size.y >= 103.0 * hud.pt, "the picture is %s on the card" % pic.size)
		_expect(card.position.y >= 0.0 and card.position.y + card.size.y <= screen.y * 0.85, "the result card with its picture reaches %.0f px down a screen of %d" % [card.position.y + card.size.y, screen.y])
		print("  %dx%d: the result card with its picture is %.0f x %.0f px at y %.0f (%.0f pt tall)" % [screen.x, screen.y, card.size.x, card.size.y, card.position.y, card.size.y / hud.pt])
		hud.show_card("NASTĘPNA", "Inna karta.", PackedStringArray(["OK"]), Color.WHITE)
		for k in 4:
			await process_frame
		_expect(not hud.card_has_art(), "the next card keeps the last card's picture")
		_expect(absf(card.size.x - plain_w) <= 1.0 and is_equal_approx(hud._card_body.custom_minimum_size.x, body_w), "the next card stays wide: %.0f px, a plain card %.0f" % [card.size.x, plain_w])
		pic = RaceReport.Sketch.new()
		pic.custom_minimum_size = Vector2(150.0, 104.0) * hud.pt
		hud.set_card_art(pic)
		hud.hide_card()
		_expect(not hud.card_has_art(), "a closed card keeps its picture")
		vp.queue_free()
		await process_frame

	if _problems > 0:
		print("race_report: %d problems" % _problems)
		quit(1)
	else:
		print("race_report: OK (the two ways, what decided the race, the card's lines, the picture and its place on the card)")
		quit(0)
