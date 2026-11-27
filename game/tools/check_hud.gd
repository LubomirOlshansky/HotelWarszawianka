extends SceneTree
## Loop 2e: the HUD at phone size. Builds the HUD (hud.gd with the speech bubbles and the
## settings panel) in a viewport the size of each screen below, as the game would on that
## phone (screen_points.gd: its points and safe area), and walks it through the states that
## matter: the first screen in each control scheme and in the helicopter, a call coming in, the
## call card, a payment, a rescue with the radio host and an easter egg, a kebab offer and a
## delivery with the customer talking where the radio ticker sits, a race, a rival to
## challenge, a landmark card, the tow toast, the same with the performance overlay on, every
## tab of the settings panel and the bench card; loop 3g-1: a police chase (the pill, the koguty,
## a megaphone bubble), the lizak, and the pull-over card (the pedals away); loop MW-6: the
## notebook's egg, tape and Kadr pages (a found card, one not found, the next page) and Fotka's
## photo-mode controls (fotka.gd, its own layer with the HUD hidden); F's asks (2026-10-30): the
## full-screen map (the ✕, its cards, a tap on the minimap, a pan and a pinch). In each state:
##   - every control the player can press is at least 44 pt each way and inside the safe area;
##   - every text is at least 11 pt, and the body texts (cards, ticker, toasts, hints) 13 pt;
##   - every HUD rect (the fixed controls, the panels, the pedals, the speech bubbles) is inside
##     the safe area and no two of them overlap; no panel was left without room (the passing
##     ones, the ticker, notes, bubbles and the overlay, may wait for room: listed); the passing
##     panels keep off the car's spot in the middle of the screen;
##   - the settings panel and the bench card fit without being shrunk;
##   - at larger text (x1.25) the same holds, a panel that must show stepping its own text down
##     to find room (hud.gd `_fit_text`), never below the normal size (each step listed).
## Prints a line per screen and state, then `check_hud: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_hud.gd [-- --verbose]

const Access := preload("res://scripts/access.gd")
const Hud := preload("res://scripts/hud.gd")
const TrendJob := preload("res://scripts/trend_job.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const Chatter := preload("res://scripts/chatter.gd")
## Loop 3g-1: the pull-over card (police.gd lays it out with the HUD's panels).
const PoliceBalloon := preload("res://scripts/police/police_balloon.gd")
## Loop MW-1: the notebook (the settings card's fifth tab), with some places found.
const Notebook := preload("res://scripts/notebook.gd")
const Wallet := preload("res://scripts/wallet.gd")
## Loop MW-6: the notebook's extra sections (eggs, then cards, Kadr spots) and Fotka's controls.
const EggBook := preload("res://scripts/egg_book.gd")
const Tape := preload("res://scripts/tape.gd")
const Fotka := preload("res://scripts/fotka.gd")
const MainLine := preload("res://scripts/main_line.gd")
const Hints := preload("res://scripts/hints.gd")
const MapTrack := preload("res://scripts/map_track.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")
## The garage loop: Warsztat u Mirka's paint card (garage.gd, garage_card.gd).
const Garage := preload("res://scripts/garage.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
## Loop 2d-1: Łuber's card words.
const RideRules := preload("res://scripts/ride_rules.gd")
## Width x height in pixels (landscape): the user's 6.9" Pro Max, the 6.1" class, a computer
## window (taken as a phone 390 pt tall), the SE (375 pt tall, no insets), the 13" iPad (the
## store's iPad screenshots) and a 4:3 window (taken as 667 pt wide).
const SCREENS := [Vector2i(2868, 1320), Vector2i(2532, 1170), Vector2i(1280, 720), Vector2i(1334, 750),
		Vector2i(2752, 2064), Vector2i(1600, 1200)]
const MIN_TOUCH := 44.0
const MIN_LABEL := 11.0
const MIN_BODY := 13.0

var problems: Array[String] = []
## The choice card's owner in the "choice card" state: remembers the index its card's ✕ pressed.
var _closer := Closer.new()


class Closer extends RefCounted:
	var got := -1

	func card_pressed(index: int) -> void:
		got = index
var verbose := false
var _speakers := {}
## Passing panels (the radio ticker, the note and landmark cards) and the performance overlay
## that waited for room: allowed, they show once there is some.
var _waits: Array[String] = []
## Large text: the panels that stepped their text down to find room (hud.gd `fitted`).
var _fitted: Array[String] = []


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


## Perf thread (2026-11-20): an Android phone's points come from its density (dpi / 160), not
## Godot's capped screen scale (the Samsung A56's 1.8 made the HUD 40 % smaller than an iPhone's).
func _check_android_points() -> void:
	var sp: GDScript = load("res://scripts/screen_points.gd")
	for c: Array in [[450, 1.8, 2.8125], [420, 1.8, 2.625], [0, 1.8, 1.8], [800, 1.8, 4.0]]:
		var got: float = sp.android_pt(int(c[0]), float(c[1]))
		if not is_equal_approx(got, float(c[2])):
			problems.append("android_pt(%d dpi, scale %.1f) = %.3f, wanted %.3f" % [c[0], c[1], got, c[2]])


## G16: while driving fast ambient bubbles are dropped and ambient toasts come one per 20 s.
func _check_quiet_driving() -> void:
	var hud: CanvasLayer = Hud.new()
	root.add_child(hud)
	var b: Control = Bubbles.new()
	b.pt = hud.pt
	var kmh: Array[float] = [60.0]
	b.kmh = func() -> float: return kmh[0]
	b.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	root.add_child(b)
	b.say_ambient(Vector3.ZERO, "", "x", "y")
	if b.count() != 0:
		problems.append("G16: an ambient bubble showed at 60 km/h")
	b.say(Vector3.ZERO, "", "x", "y")
	if b.count() != 1:
		problems.append("G16: a quest bubble was dropped at 60 km/h")
	b.clear()
	kmh[0] = 30.0
	b.chatter.clock += b.chatter.gap()  # Phase 0.2: past the budget's gap after the quest line
	b.say_ambient(Vector3.ZERO, "", "x", "y")
	if b.count() != 1:
		problems.append("G16: an ambient bubble was dropped at 30 km/h")
	hud.set_speed(40)
	hud.ambient_toast("a", "a")
	hud._toast_left = 0.0
	hud.ambient_toast("b", "b")
	if hud._toast.text != "a":
		problems.append("G16: a second ambient toast within 20 s showed while driving")
	hud.queue_free()
	b.queue_free()


## F 2026-11-11: a quest or police line from a person carries their face (the portrait, else the
## initial), a column on the bubble's left; ambient chatter and a non-person ("Nawigacja") don't.
func _check_faces() -> void:
	var b: Control = Bubbles.new()
	b.pt = 2.0
	b.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	root.add_child(b)
	var cases := [["Ivan", Chatter.QUEST, true, true], ["Bogdan", Chatter.QUEST, true, true],
			["Strażnik Henio", Chatter.POLICE, true, true], ["Nawigacja", Chatter.QUEST, false, false],
			["Kolka", Chatter.AMBIENT, false, false], ["", Chatter.QUEST, false, false]]
	for c in cases:
		b.clear()
		b.chatter.clock += b.chatter.gap() * 2.0
		if not b.say(Vector3(100, 300, 0), c[0], "Siema.", "Hi.", 4.0, Color.WHITE, 2.6, c[1]):
			problems.append("faces: %s's line did not show" % c[0])
			continue
		if c[2]:
			# F 2026-11-16: a person's line is the fixed panel's, not a floating bubble.
			if not b._bubbles.is_empty() or b._cur.is_empty():
				problems.append("faces: %s's line is not in the panel" % c[0])
				continue
			if (b._cur.get("tex") != null) != c[3]:
				problems.append("faces: %s's portrait %s" % [c[0], "missing" if c[3] else "unexpected"])
			continue
		if not b._cur.is_empty() or b._bubbles.is_empty() or bool(b._bubbles[0].get("face", false)):
			problems.append("faces: %s (%d) should be a name-only caption" % [c[0], c[1]])
	# One voice at a time: a second person queues behind the first; a thing or ambient line is dropped.
	b.clear()
	b.chatter.clock += b.chatter.gap() * 2.0
	b.say(Vector3(100, 300, 0), "Mati", "Pierwsza.", "Pierwsza.")
	b.say(Vector3(110, 300, 0), "Mati", "Druga.", "Druga.")
	b.say(Vector3(120, 300, 0), "Ivan", "Trzecia.", "Trzecia.")
	if b.panel_line() != "Pierwsza." or b._queue.size() != 2:
		problems.append("panel: lines must show one at a time and queue (now '%s', %d waiting)" % [b.panel_line(), b._queue.size()])
	if b.say(Vector3(1, 1, 0), "Palma", "Hej.", "Hej."):
		problems.append("panel: a thing's caption showed while a person talked")
	if Portraits.has_face("Palma") or Portraits.has_face("Barierka · Marszałkowska"):
		problems.append("faces: an object gets a face")
	b.clear()
	for who in ["Ty", "Winda", "Ktoś z tłumu", ""]:
		if Portraits.has_face(who):
			problems.append("faces: '%s' gets a face" % who)
	b.queue_free()


## 2026-11-08 (Autopilot, padel at DESKA): a new offer opened over a result card and the OK tap
## accepted it. While a card is up (a result or win card included), and for TrendJob.CARD_REST s
## after one closes, no offer opens; it is queued and shows afterwards.
func _check_offers_wait() -> void:
	var hud: CanvasLayer = Hud.new()
	root.add_child(hud)
	if hud.cards_up():
		problems.append("offers: cards_up() is true with no card showing")
	if TrendJob.hold_offers(100.0, 0.0, hud.cards_up()):
		problems.append("offers: held with no card up")
	hud.show_card("PADEL · 2:0 · +60 zł", "Wygrane!", PackedStringArray(["OK"]), Color("#40c0c0"))
	if not hud.cards_up():
		problems.append("offers: cards_up() is false with a result card showing")
	if not TrendJob.hold_offers(100.0, 0.0, hud.cards_up()):
		problems.append("offers: an offer may open over a result card")
	hud.hide_card()
	if hud.cards_up():
		problems.append("offers: cards_up() stays true after the card closed")
	if not TrendJob.hold_offers(101.0, 100.0 + TrendJob.CARD_REST, hud.cards_up()):
		problems.append("offers: an offer may open the moment a card closed")
	if TrendJob.hold_offers(103.0, 100.0 + TrendJob.CARD_REST, hud.cards_up()):
		problems.append("offers: still held after the rest")
	# F 2026-11-08: a friend's call (Mrożulo) never rings mid-mission, nor right after one, nor
	# over a rescue call already ringing; it rings once the rest is over.
	if not TrendJob.hold_calls(true, 500.0, 0.0, false):
		problems.append("calls: a friend's call may ring during a mission")
	if not TrendJob.hold_calls(false, 505.0, 500.0 + TrendJob.CALL_REST, false):
		problems.append("calls: a friend's call may ring the moment a mission ended")
	if not TrendJob.hold_calls(false, 900.0, 0.0, true):
		problems.append("calls: a friend's call may ring over a rescue call")
	if TrendJob.hold_calls(false, 500.0 + TrendJob.CALL_REST + 1.0, 500.0 + TrendJob.CALL_REST, false):
		problems.append("calls: still held after the rest")
	var tj: Node = TrendJob.new()
	tj.mission_on = true
	tj.mission_on = false
	if not TrendJob.hold_calls(tj.mission_on, 1.0, tj._call_rest, false):
		problems.append("calls: a mission's end does not start the call rest")
	tj.free()
	hud.queue_free()


func _run() -> void:
	await process_frame  # the tree is ready for nodes only once the first frame runs
	var states := 0
	for screen in SCREENS:
		states += await _check_screen(screen)
	_check_android_points()
	_check_quiet_driving()
	_check_offers_wait()
	_check_faces()
	for w in _waits:
		print("  waits for room: %s" % w)
	# The x1.25 pass is a gate (2026-11-02): a panel that must show and has no room at the larger
	# text steps its own text down (hud.gd `_fit_text`); listed here, never below the normal size.
	for f in _fitted:
		print("  text stepped down: %s" % f)
	if problems.is_empty():
		print("check_hud: OK (%d screens, %d states; a passing panel waited for room %d times; large text stepped down %d times)" % [SCREENS.size(), states, _waits.size(), _fitted.size()])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_hud: %d problems" % problems.size())
		quit(1)


func _check_screen(screen: Vector2i) -> int:
	var vp := SubViewport.new()
	vp.size = screen
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	var bubbles: Control = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	hud.add_speech(bubbles)  # above the target pointer, below the panels (PT-10)
	var talk: Control = PoliceBalloon.new()
	talk.pt = hud.pt
	hud.add_panel(talk, "bottom")
	hud.set_radio_skip(true)  # beta radio: DALEJ under RADIO (a station with several songs)
	await process_frame
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var tag := "%dx%d (%.0fx%.0f pt)" % [screen.x, screen.y, screen.x / pt, screen.y / pt]
	print("%s: %.2f px a point, safe area %.0f..%.0f x %.0f..%.0f pt" % [tag, pt, safe.position.x / pt, safe.end.x / pt,
			safe.position.y / pt, safe.end.y / pt])
	var count := 0
	var at := func(fx: float, fy: float) -> Vector2: return Vector2(screen.x * fx, screen.y * fy)
	_check_bubble_sweep(hud, bubbles, screen, tag)
	_check_ticker_slide(hud, tag)
	_check_target_pointer(hud, bubbles, screen, tag)
	_check_finger_hint(hud, bubbles, tag)
	_check_arrows(hud, tag)
	# The longest call the map gives (the longest hospital name), Polish over English as in missions.gd.
	var call_pl := "Ranny rowerzysta: Aleksandra Krywulta. Wystarczy auto albo helikopter.\nSzpital: Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego · czas 3:40"
	var call_en := "A cyclist is hurt: the car or the helicopter will do. Get them to the hospital in 3:40."
	# Loop G1: the last line is the quality, its pixel scale and the governor (the longest one;
	# loop G1b: with "fallback", and the longest level name).
	var perf_text := "60 fps · 16.7 ms · worst 18.2 · cap 60 fps\nCPU 11.2 + 0.3 + 14.1 ms · GPU n/a · 670 MB\ndraws 153 = 53 + 35 + 65 · 0.45 M tris\nMedium ×3 fallback · gov GPU 2/2 · CPU 2/2 · wide"
	# Desktop: --no-touch (trailer loop, 2026-10-29): a third pass with the touch-only controls
	# away; none may be left to press or take room.
	# Accessibility (2026-11-01): a fourth pass in the left-handed layout (the pedals bottom left).
	# Larger HUD text (2026-11-02): a fifth pass at Access.LARGE_TEXT (x1.25), the setting the phone's own text size will drive.
	for mode in ["", "perf", "no-touch", "left-handed", "large-text"]:
		var perf: bool = mode == "perf"
		for state in ["car, Point", "car, Classic", "car, Classic slider", "helicopter", "call came in", "call card", "rescued, paid",
				"rescue, host, egg", "kebab offer", "kebab delivery", "race", "rival ahead", "landmark card", "note card", "tow toast",
				"police chase", "lizak", "pull-over",
				"ride offer", "ride", "ride result", "ride result, police", "phone call", "quest offer", "drag shift", "choice card"]:
			if perf and not state in ["car, Point", "call card", "rescue, host, egg", "kebab offer", "kebab delivery", "landmark card"]:
				continue
			if mode == "no-touch" and not state in ["car, Point", "car, Classic", "helicopter", "kebab offer", "pull-over", "ride offer"]:
				continue
			if mode == "left-handed" and not state in ["car, Point", "car, Classic", "car, Classic slider", "helicopter", "rescue, host, egg", "kebab offer",
					"landmark card", "police chase", "pull-over", "ride offer", "ride", "phone call"]:
				continue
			if mode == "large-text" and not state in ["choice card", "car, Point", "call came in", "call card", "rescue, host, egg", "kebab offer",
					"kebab delivery", "race", "landmark card", "note card", "police chase", "pull-over", "ride offer", "ride", "ride result",
					"phone call", "quest offer"]:
				continue
			Access.text_scale = Access.LARGE_TEXT if mode == "large-text" else 1.0
			hud.apply_text_scale()
			hud.set_left_handed(mode == "left-handed")
			hud.clear_all()
			bubbles.clear()
			hud.set_touch_off(mode == "no-touch")
			hud.set_scheme(1 if state.begins_with("car, Classic") else 0)
			hud.set_arrows_layout(state != "car, Classic slider")  # F 2026-11-13 arrows; the slider is the default since 2026-11-14
			hud.set_flying(state == "helicopter")
			# N1: the nitro is owned in the car states, so its disc (above GAS in Classic) is
			# checked against every panel, the pedals and the safe area like the rest.
			hud.set_nitro(state.begins_with("car, "), 1.0, 2, false)
			if state == "helicopter":
				hud.set_speed(88, 45)
			else:
				hud.set_speed(142)
			hud.set_wallet(12345, 1234)
			hud.show_perf(perf)
			hud.set_perf(perf_text)
			match state:
				"call came in":
					hud.show_pill("WEZWANIE", "rescue call")
					hud.toast("Wezwanie ratunkowe!", "A rescue call came in: tap the button at the top.")
				"call card":
					hud.show_card("WEZWANIE 1 · RATUNEK NA ULICY", call_pl, PackedStringArray(["ACCEPT", "SKIP", "LATER"]),
							Color("#ffc23a"), false, "Call 1 · street rescue", call_en)
				"rescued, paid":
					hud.show_card("URATOWANI", "Cali i zdrowi: Szpital Praski.\nCzas 2:10 z 3:40 · punkty +1210 (razem 1210) · +97 zł",
							PackedStringArray(["NEXT CALL", "FREE ROAM"]), Color("#56d68a"), false, "Rescued",
							"Safe and sound at the hospital: time, score and pay above.")
					hud.set_wallet(12442, 1274, 97)
				"rescue, host, egg":
					hud.show_status("DO SZPITALA · Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego", "2:31", "640 m",
							"Pacjent na pokładzie: do zielonego światła", 0.3, Color("#ffc23a"), "", {}, "Patient on board: head for the green beacon")
					# The message director keeps the radio and an egg's note back during a quest; the worst
					# case left is a station the player picked and a quest's own note (COTAM).
					hud.radio_touched()
					hud.ticker("87,3 KEBAB FM:  Jest trzecia w nocy, a Rondo Dmowskiego wciąż stoi. Szacunek.", Color("#ff5fc8"),
							"It's 3 a.m. and Rondo Dmowskiego is still jammed. Respect.")
					hud.show_note("SEKRET 2/5 · EASTER EGG", "Gołębie na placu Defilad\nPigeons on Plac Defilad", Color("#ff4fd8"),
							hud.Messages.QUEST_LINE)
					_say(bubbles, "Ania", at.call(0.2, 0.86), "Szybciej, proszę!", "Faster, please!")
				"kebab offer":
					hud.show_card("ZAMÓWIENIE · KEBAB · 840 m", "Dla: Kasia, Wspólna 47/49. Za rzeką: „w sumie to centrum”. Im cieplejszy dojedzie, tym większy napiwek. Nocą ×1,5.",
							PackedStringArray(["GO!", "NOT NOW"]), Color("#ff9a3c"), true, "Kebab order · 840 m",
							"It cools on the way: the hotter, the bigger the tip. Across the river (\"basically the centre\"). Night pays ×1.5.")
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
					hud.toast("Jedziemy! Kasia czeka", "Go! Kasia is waiting")
					# PT-13: the GO counts down to the order's own start (jobs.gd _count_down).
					hud.set_card_button(0, "JEDZIEMY! · 9", "GO! · 9")
					if not hud.card_button_text(0).ends_with("· 9"):
						problems.append("%s %s PT-13: the order card's GO doesn't show its countdown (%s)" % [screen, state, hud.card_button_text(0)])
					_say(bubbles, "Marek", at.call(0.12, 0.82), "Z ostrym czy łagodnym?", "Hot sauce or mild?")
					# The vendor over the stand, mid-right, where shots/loop2e_kebab_offer_* see it.
					_say(bubbles, "Kebab 24h", at.call(0.62, 0.52), "Mięso z rożna, sos z serca. Dowieź, zanim wystygnie.",
							"Meat off the spit, sauce from the heart. Get it there before it cools.")
				"kebab delivery":
					hud.show_status("KEBAB → Wspólna 47/49", "GORĄCY 92%", "410 m", "Jedź do pomarańczowego światła", 0.0, Color("#ff9a3c"),
							"", {"heat": 0.9}, "Head for the orange beacon")
					hud.radio_touched()  # the player's own station: it shows in a quest or a chase
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
					# The case the user saw: the stand's bubble right where the ticker sits.
					_say(bubbles, "Kebab 24h", at.call(0.1, 0.9), "KEBAB 24H: najlepszy w mieście!", "The best in town!")
					_say(bubbles, "Kasia", at.call(0.55, 0.45), "Już jedziesz? Głodna jestem.", "On your way? I'm starving.")
				"race":
					hud.show_status("WYŚCIG · Seba z Pragi → Palma", "0:42", "620 m", "Seba z Pragi: 40 m za tobą", 0.0, Color("#b45cff"),
							"1ST", {}, "Seba z Pragi is 40 m behind")
					hud.show_banner("WYŚCIG DO PALMY", Color("#b45cff"))
					_say(bubbles, "Seba z Pragi", at.call(0.5, 0.42), "Ej, kierowniku! Do Palmy!", "Hey, boss! To the Palm!")
				"rival ahead":
					hud.show_challenge("MRUGNIJ ŚWIATŁAMI · SEBA Z PRAGI", Color("#b45cff"))
					hud.toast("Najpierw dokończ kurs: zamówienie jedzie autem", "Finish the job first: it rides in the car")
				"landmark card":
					hud.show_info("Pałac Kultury i Nauki", "Najwyższy budynek w Polsce do 2022 roku: 237 m z iglicą.",
							"Poland's tallest building until 2022: 237 m with the spire.")
					hud.ticker("87,3 KEBAB FM:  Pałac widać z każdego miejsca. Dlatego go lubimy.", Color("#ff5fc8"),
							"You can see the Palace from everywhere. That's why we like it.")
				# Landmark card fix: a note card with the radio ticker up and the car parked.
				"note card":
					hud.show_note("SEKRET 2/5 · EASTER EGG", "Gołębie na placu Defilad\nPigeons on Plac Defilad", Color("#ff4fd8"))
					hud.ticker("87,3 KEBAB FM:  Pałac widać z każdego miejsca. Dlatego go lubimy.", Color("#ff5fc8"),
							"You can see the Palace from everywhere. That's why we like it.")
				"tow toast":
					hud.toast("Pomoc drogowa: wyciągnięci!", "Towed free")
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				# Loop 3g-1: a koguty 2 chase (the pill and its gap bar, the koguty, a megaphone
				# bubble, the edge rooster), the lizak's pill, and the pull-over card with two replies.
				"police chase":
					hud.set_koguty(2, 1)
					hud.police_pill("UCIEKAJ", "GET AWAY", 0.6, 1)
					hud.police_fx(1.0, PackedVector2Array([at.call(0.5, 1.3)]), Vector2.INF)
					_say(bubbles, "Policja", at.call(0.5, 0.72), "Proszę się zatrzymać! Albo chociaż zwolnić, będzie miło.",
							"Please stop! Or at least slow down, that would be nice.")
					hud.radio_touched()  # the player's own station: it shows in a quest or a chase
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				"lizak":
					hud.set_koguty(0, 3)
					hud.police_pill("ZATRZYMAJ SIĘ PRZY POLICJANCIE", "PULL OVER BY THE OFFICER")
					hud.police_fx(0.0, PackedVector2Array(), at.call(0.56, 0.36))
					hud.toast("UCIECZKA!  +15", "ESCAPED!  +15 RESPECT")
				"pull-over":
					hud.set_koguty(1, 1)
					hud.set_pedals_hidden(true)
					# The longest opener with the longest English (the caution's) and the two widest replies.
					talk.show_line("Posterunkowy Kacper", "Kontrola drogowa. Wiesz, czemu cię zatrzymałem? Ja tak średnio.",
							"Consider yourself cautioned. Kacper, put it in the notebook. Neatly, not like last time.",
							[["Przepraszam, już nie będę.", "Sorry, won't happen again."], ["Suszarka? Mam krótkie włosy.", "Hair dryer? But I've got short hair."]])
					hud.show_panel(talk, true)
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				# Loop 2d-1: Łuber at its longest: the longest note, the MNOŻNIK for night and rain,
				# the longest destination; the result with every star note and a streak.
				"drag shift":
					hud.show_pill("⬆ BIEG", "⬆ SHIFT", "drag_shift")
				"ride offer":
					var offer := RideRules.offer_text({"name": "Krzysiek", "away": 588.0, "road": 2496.0, "their": 4.9,
							"note": ["Uwagi: „jestem tam, gdzie pinezka, tylko po drugiej stronie”.",
							"Note: \"I'm where the pin is, just on the other side.\""], "night": true, "rain": true, "rating": 4.87})
					hud.show_side_card(offer[0], offer[1], PackedStringArray(["ACCEPT", "SKIP"]), Color("#4fd8c4"), offer[2], offer[3])
					hud.show_pill("ŁUBER", "ŁUBER", "ride")
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				"ride":
					hud.show_status("ŁUBER → Plac Trzech Krzyży", RideRules.stars_text(4.5), "1840 m",
							"Cel to turkusowe światło. Kropki to pomysł aplikacji.", 0.4, Color("#4fd8c4"), "", {},
							"The goal is the teal beacon. The dots are the app's idea.")
					hud.toast("−½ ★ · hamowanie", "−½ star · harsh braking")
					_say(bubbles, "Nawigacja", at.call(0.55, 0.42), "Za dwieście metrów skręć w prawo. W Wisłę.",
							"In two hundred metres, turn right. Into the Vistula.")
					_say(bubbles, "Krzysiek", at.call(0.2, 0.8), "GPS mówi przez Wisłę. Może jest prom? Nie ma promu?",
							"The GPS says across the Vistula. Maybe there's a ferry? No ferry?")
				"ride result":
					# The longest a 5-star card gets: night and rain, in a hurry, a full streak, three notes.
					var pay := RideRules.pay(2496.0, 5.0, true, true, true, 5)
					var done := RideRules.result_text({"stars": 5.0, "name": "Krzysiek", "comment": ["Pięć gwiazdek i serduszko. Serduszko jest rzadkie.",
							"Five stars and a heart. The heart is rare."], "pay": pay, "rating": 4.88,
							"why": ["jazda −1, przed czasem +½, za aplikacją +½", "driving −1, early +½, followed the app +½"]})
					hud.show_side_card(done[0], done[1], PackedStringArray(), Color("#4fd8c4"), done[2], done[3])
					hud.set_wallet(12442, 1259, 97)
				"ride result, police":
					# The longest comment (pulled over), with the most a 4-star ride can lose and win back.
					var pay4 := RideRules.pay(2496.0, 4.0, true, true, false, 0)
					var done4 := RideRules.result_text({"stars": 4.0, "name": "Krzysiek", "comment": ["Policja w trakcie kursu? Gwiazdkę zabieram, anegdotę zostawiam.",
							"Police mid-ride? I'm taking a star, but keeping the anecdote."], "pay": pay4, "rating": 4.83,
							"why": ["jazda −½, policja −1, za aplikacją +½", "driving −½, police −1, followed the app +½"]})
					hud.show_side_card(done4[0], done4[1], PackedStringArray(), Color("#4fd8c4"), done4[2], done4[3])
				# F 2026-11-10: an incoming call in the phone view (the longest caller line, a name
				# without a portrait: the initial's fallback), then the quest offer with the face.
				"phone call":
					hud.show_call("Darek „Bawarka”|Darek \"Bawarka\"", "Z pracy. Bluza klubowa przed pierwszym meczem.",
							Color("#4fd8c4"), "From work. Club hoodie before her first match.")
					hud.ticker("87,3 KEBAB FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				"choice card":
					# F's playtest 2026-11-16: Halina's face, the title, the taunt and the reward (the longest the
					# words give: first10.gd `choice_words`), the three buttons one under the other with the first
					# gold and taller, and the ✕ for "just drive".
					hud.show_card("PANI HALINA MRUGA", "„Do Palmy, kto pierwszy?”\n12,8 km · 60 zł + 100 respektu. Pierwsza z sześciu rywali.",
							PackedStringArray(["ŚCIGAJ SIĘ · +60 zł|START RACE · +60 zł", "Łuber · od 15 zł|Give a lift · from 15 zł",
							"Lot · kaseta na dachu BUW|Fly · a mixtape on the BUW roof"]), Color("#ffd23f"), false,
							"Pani Halina is flashing you", "\"Race you to the Palm?\"\n12.8 km · 60 zł + 100 respect. First of six rivals.", true)
					hud.own_card(_closer)
					var face := Portraits.badge(72.0 * pt)
					Portraits.set_badge(face, "Pani Halina", Color("#86d3b0"))
					hud.set_card_art(face, true)
					hud.set_card_lead(0)
					hud.set_card_close(3)
				"quest offer":
					hud.show_side_card("📞 IVAN", "„Siema! Szisza dziś? Podjedź po mnie pod 19. Dzielnicę, weźmiemy jeszcze Bogdana z kortu. Ma być spokojnie.”",
							PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TONIGHT"]), Color("#7fd4a0"), "Ivan",
							"\"Hey! Shisha tonight? Pick me up at 19. Dzielnica, we'll grab Bogdan from the court too. Calm, this time.\"", false, "Ivan")
			await process_frame
			await process_frame
			bubbles.layout()
			if state == "phone call":
				var w := "%s phone call%s" % [tag, " + " + mode if mode != "" else ""]
				var rs2: Dictionary = hud.named_rects()
				if not hud.call_showing():
					problems.append("%s: the phone view is not up" % w)
				elif not rs2.has("card") or "card" in hud.waiting():
					problems.append("%s: the phone view is not placed (it waits for room)" % w)
				elif (rs2["card"] as Rect2).intersects(hud.car_zone()):
					problems.append("%s: the phone view %s is over the car's spot" % [w, _pts(rs2["card"], pt)])
				for i in 2:
					var b := (hud.get("_call_buttons") as Node).find_child("button%d" % i, true, false) as Control
					if b == null or not b.is_visible_in_tree():
						problems.append("%s: no round button %d" % [w, i])
					elif b.size.x < 44.0 * pt - 0.5 or b.size.y < 44.0 * pt - 0.5:
						problems.append("%s: round button %d is under 44 pt" % [w, i])
			if state == "choice card":
				_check_choice_card(hud, safe, pt, "%s choice card%s" % [tag, " + " + mode if mode != "" else ""])
				_check_card_close(hud, safe, pt, "%s choice card%s" % [tag, " + " + mode if mode != "" else ""])
			if state == "quest offer":
				var f := hud.get("_card_face") as Control
				if f == null or not f.is_visible_in_tree():
					problems.append("%s quest offer: no face on the card's head" % tag)
				if hud.call_showing():
					problems.append("%s quest offer: the phone view stayed up" % tag)
			_check_state(hud, bubbles, "%s %s%s" % [tag, state, " + " + mode if mode != "" else ""])
			if mode == "left-handed" and state in ["car, Point", "car, Classic", "helicopter"]:
				# The pressable discs all on the left half; the credit line is gone (credits page in Settings).
				var tt: Dictionary = hud.touch_targets()
				for k in ["brake", "gas", "nitro", "climb", "sink"]:
					if tt.has(k) and (tt[k] as Rect2).get_center().x > screen.x * 0.5:
						problems.append("%s %s + left-handed: %s is on the right" % [tag, state, k])
				if not hud.call("_stick_side", screen.x * 0.8, float(screen.x)) or hud.call("_stick_side", screen.x * 0.2, float(screen.x)):
					problems.append("%s %s + left-handed: the stick's side is not the right" % [tag, state])
				if hud.named_rects().has("credit"):
					problems.append("%s %s: the credit line is back on the main screen" % [tag, state])
			# Landmark card fix: with the ticker up and the car parked, a tapped landmark's card
			# (and a note card) must be on screen at once, not waiting for room, and not over the car.
			if state in ["landmark card", "note card"]:
				var card_name := "info" if state == "landmark card" else "note"
				var rs: Dictionary = hud.named_rects()
				var who := "%s %s%s" % [tag, state, " + " + mode if mode != "" else ""]
				if not rs.has(card_name) or card_name in hud.waiting():
					problems.append("%s: the %s card is not placed (it waits for room)" % [who, card_name])
				elif (rs[card_name] as Rect2).intersects(hud.car_zone()):
					problems.append("%s: the %s card %s is over the car's spot" % [who, card_name, _pts(rs[card_name], pt)])
			count += 1
	hud.set_touch_off(false)
	# The settings panel, every tab, and the bench card.
	hud.clear_all()
	bubbles.clear()
	# Loop MW-1: the notebook's page needs its places (no map) and a record: chapter 1 half found.
	var notes_wallet: Wallet = Wallet.new()
	notes_wallet.persistent = false
	vp.add_child(notes_wallet)
	var book: Notebook = Notebook.new()
	book.wallet = notes_wallet
	book.load_places()
	book.preset("1:4")
	hud.settings_panel.notebook = book
	# Loop MW-6: the extra sections, with a few found (and stamped on a date).
	var egg_book: EggBook = EggBook.new()
	egg_book.load_eggs()
	var tape: Tape = Tape.new()
	tape.load_cards()
	var kadr: Fotka = Fotka.new()
	kadr.load_spots()
	for id: String in ["palma", "e07", "e13", "e20"]:
		notes_wallet.find_egg(id, 20261030)
	notes_wallet.tapes["t_defilad_2012"] = 20261030
	notes_wallet.kadr["k01"] = 20261030
	hud.settings_panel.notebook_eggs = egg_book
	hud.settings_panel.notebook_tape = tape
	hud.settings_panel.notebook_kadr = kadr
	hud.open_settings({"controls": 1, "follow": false, "traffic": 2, "quality": 0, "auto": "Medium ostry", "master": 1.0, "music": 0.5,
			"effects": 1.0, "perf": 0, "fps": 0, "style": 0, "weather": 0, "time": 0})
	var panel: Control = hud.settings_panel
	# Loop MW-1: the tabs and the credits page (settings_panel.gd PAGES, by name), then the notebook with a
	# found card open and one not found yet.
	var views := ["page:game", "page:picture", "page:sound", "page:access", "page:general", "page:dev", "page:advanced", "page:credits", "page:notebook", "lusterko", "milosc_hipoteczna", "eggs", "e07", "e03", "e40", "tape", "t_defilad_2012",
			"t_stadion_2010", "kadr", "k01", "k10"]
	for t in views:
		if str(t).begins_with("page:"):
			panel.set_page(str(t).trim_prefix("page:"))
		else:
			panel.show_notebook(t)
		await process_frame
		await process_frame
		var where := "%s settings tab %s" % [tag, t]
		if not is_equal_approx(panel.card_scale(), 1.0):
			problems.append("%s: the panel is shrunk to %.2f to fit" % [where, panel.card_scale()])
		var card: Rect2 = panel.card_rect()
		if not safe.grow(0.5).encloses(card):
			problems.append("%s: the panel %s sticks out of the safe area %s" % [where, _pts(card, pt), _pts(safe, pt)])
		var buttons: Dictionary = panel.button_rects()
		for b in buttons:
			_check_touch(where + " " + b, buttons[b], pt, safe)
		_check_fonts(panel, where, pt)
		if verbose:
			print("  %s: %d buttons, panel %s" % [where, buttons.size(), _pts(card, pt)])
		count += 1
	panel.close()
	hud.set_left_handed(false)
	Access.text_scale = 1.0
	hud.apply_text_scale()
	book.free()
	egg_book.free()
	tape.free()
	kadr.free()
	notes_wallet.free()
	count += await _check_fotka(vp, hud, tag)
	count += await _check_garage(vp, hud, tag)
	var bench := "AROUND WARSAW bench (loop 2b) · BENCH · 2026-10-28 16:42:59\ndevice iPhone17,2 · iOS 26.0 · Apple A18 Pro GPU (metal, mobile) · Apple A18 Pro\nscreen 2868x1320 @ 120 Hz · image 1434x660 (×2) · view 80 m · quality Auto→High fallback (iPhone17,2) · traffic Normal · Day · Clear · cap 60 fps · Point\nthermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s\nfps 59.9 avg · 1% low 55.3 · worst frame 25.0 ms · late 0.4% (over 17.7 ms) · missed refreshes 12 (0.4%) · 3300 frames in 55 s\nfps per 10 s: 60 60 60 60 60 60 · governor held: GPU 2/2 · CPU 2/2, wide, 12 changes\nframe 16.69 ms · main thread: process 2.10, physics 0.40, draw 13.90 · 3D view: render CPU 0.60, GPU n/a (Metal)\ndraw calls 141 · objects 410 · triangles 0.42 M (all passes, as the overlay counts them)\nmain pass: 50 draws, 50 objects, 0.24 M tris · shadow pass: 33 draws, 33 objects, 0.13 M tris · 2D: 58 draws\nscripts 1.90 ms: traffic 0.70 · traffic bodies 0.05 · trams 0.25 · people 0.30 · rivals 0.05 · jobs+eggs 0.10\n  jobs physics 0.01 · sound 0.04 · hud+minimap 0.20 · bubbles 0.05 · dialogue 0.01\ncars on screen 15 · driving 31 · people 48\nmemory: static 640 MB · video 310 MB (textures 120, buffers 150) · 3 pipeline compilations"
	hud.show_bench_card(bench)
	await process_frame
	await process_frame
	var bw := "%s bench card" % tag
	var bcard: PanelContainer = hud.get("_bench_card")
	if not is_equal_approx(bcard.scale.x, 1.0):
		problems.append("%s: shrunk to %.2f to fit" % [bw, bcard.scale.x])
	if not safe.grow(0.5).encloses(bcard.get_global_rect()):
		problems.append("%s: %s sticks out of the safe area" % [bw, _pts(bcard.get_global_rect(), pt)])
	var targets: Dictionary = hud.touch_targets()
	for k in targets:
		if String(k).begins_with("bench"):
			_check_touch(bw + " " + k, targets[k], pt, safe)
	_check_fonts(bcard, bw, pt)
	count += 1
	hud.clear_all()
	count += await _check_full_map(hud, tag)
	if screen == SCREENS[0]:
		_check_radio_hold(hud)
	vp.queue_free()
	await process_frame
	return count


## F's asks (2026-10-30; the minimal map 2026-11-17): the full-screen map open (a tap on the
## minimap) shows only the ✕, the NEXT line and the big QUESTS button over the map (no title, no
## legend, no list, no ≡ or ? cards), each a MIN_TOUCH target inside the safe area, none
## overlapping (the NEW badge sits on QUESTS' corner), the texts big enough; a tap's touch on the
## minimap emits `map_pressed`; a pan and a pinch move and zoom it; the ✕ closes it and then
## nothing of it shows.
func _check_full_map(hud: CanvasLayer, tag: String) -> int:
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var where := "%s full map" % tag
	var tapped := [0]
	var on_tap := func() -> void: tapped[0] += 1
	hud.map_pressed.connect(on_tap)
	var mini: Rect2 = (hud.get("_minimap") as Control).get_global_rect()
	for down in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = mini.get_center()
		t.pressed = down
		hud._input(t)
	hud.map_pressed.disconnect(on_tap)
	if tapped[0] != 1:
		problems.append("%s: a tap on the minimap emitted map_pressed %d times (want 1)" % [where, tapped[0]])
	hud.markers.put_all("main", MainLine.map_marks(Vector2(300.0, -200.0)))
	hud.open_full_map(Vector2(10.0, 20.0), 0.5, PackedVector2Array([Vector2(100.0, 50.0)]))
	await process_frame
	await process_frame
	var fm: Control = hud.full_map
	fm.set_next(["Znajdź i mrugnij: Taksiarz Zbyszek z Pragi", "Find and flash: Taksiarz Zbyszek from Praga"], Vector2(300.0, -200.0))
	fm.set_book({"car": Vector2(10.0, 20.0), "stories": [_story_fact("rave", Vector2(200.0, 100.0), true)]})
	await process_frame
	var rs: Dictionary = fm.rects()
	for k in ["head", "hint", "districts", "cards", "goal", "legend", "help", "list"]:
		if rs.has(k):
			problems.append("%s: the minimal map still shows its %s" % [where, k])
	for k in ["close", "quests", "next"]:
		if not rs.has(k):
			problems.append("%s: no %s button" % [where, k])
			continue
		_check_touch(where + " " + k, rs[k], pt, safe)
	if rs.has("quests") and (rs["quests"] as Rect2).size.y < 56.0 * pt - 0.5:
		problems.append("%s: the QUESTS button is %.0f pt tall (want a big one, 56 pt or more)" % [where, (rs["quests"] as Rect2).size.y / pt])
	if not rs.has("badge") or (fm.get("_badge") as Label).text != "1":
		problems.append("%s: no NEW badge on QUESTS for the questline that invited (%s)" % [where, rs.has("badge")])
	elif rs.has("quests") and not (rs["badge"] as Rect2).intersects(rs["quests"]):
		problems.append("%s: the NEW badge is not on the QUESTS button" % where)
	var keys := rs.keys()
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			if "badge" in [keys[i], keys[j]]:
				continue
			if (rs[keys[i]] as Rect2).intersects(rs[keys[j]]):
				problems.append("%s: %s and %s overlap" % [where, keys[i], keys[j]])
	_check_fonts(fm, where, pt)
	# A tap on NEXT (the main line's next step) looks at its place.
	(fm.get("_next") as Button).pressed.emit()
	if fm.centre.distance_to(Vector2(300.0, -200.0)) > 1.0:
		problems.append("%s: a tap on NEXT did not look at its place (%s)" % [where, fm.centre])
	await _check_map_track(hud, fm, where, pt, safe)
	await _check_quests_screen(fm, where, pt, safe)
	await _check_map_coach(fm, where, pt, safe)
	# A one-finger pan of 100 px moves the map 100 px; a pinch to twice the span doubles the zoom.
	var c0: Vector2 = fm.centre
	var ppm0: float = fm.ppm
	var mid: Vector2 = fm.get_viewport().get_visible_rect().size * 0.5
	var ev := func(e: InputEvent) -> void: fm._input(e)
	var touch := func(i: int, at: Vector2, down: bool) -> InputEventScreenTouch:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = at
		e.pressed = down
		return e
	var drag := func(i: int, at: Vector2) -> InputEventScreenDrag:
		var e := InputEventScreenDrag.new()
		e.index = i
		e.position = at
		return e
	ev.call(touch.call(0, mid, true))
	ev.call(drag.call(0, mid + Vector2(100.0, 0.0)))
	ev.call(touch.call(0, mid + Vector2(100.0, 0.0), false))
	var moved: float = (c0 - fm.centre).x * ppm0
	if absf(moved - 100.0) > 1.0:
		problems.append("%s: a 100 px pan moved the map %.1f px" % [where, moved])
	fm.ppm = ppm0
	fm.centre = c0
	ev.call(touch.call(0, mid - Vector2(50.0, 0.0), true))
	ev.call(touch.call(1, mid + Vector2(50.0, 0.0), true))
	ev.call(drag.call(1, mid + Vector2(150.0, 0.0)))
	ev.call(touch.call(0, mid, false))
	ev.call(touch.call(1, mid, false))
	if fm.ppm <= ppm0 * 1.5:
		problems.append("%s: a pinch to twice the span zoomed %.2f×" % [where, fm.ppm / ppm0])
	(fm.get("_close") as Button).pressed.emit()
	await process_frame
	if fm.visible or hud.full_map_open():
		problems.append("%s: the ✕ did not close it" % where)
	await _check_map_hold(hud, where)
	if verbose:
		print("  %s: ✕ %s, QUESTS %s, NEXT %s; pan %.0f px, pinch %.2f×" % [where, _pts(rs.get("close", Rect2()), pt),
				_pts(rs.get("quests", Rect2()), pt), _pts(rs.get("next", Rect2()), pt), moved, fm.ppm / ppm0])
	return 1


## One questline's facts as main.gd `_fill_map_list` gives them (quest_book.gd `tabs`).
static func _story_fact(id: String, at: Vector2, is_new := false) -> Dictionary:
	return {"id": id, "pl": "Sekretny rave pod mostem Poniatowskiego", "en": "The secret rave under Poniatowski Bridge",
			"who": ["Mati", "Mati"], "blurb": ["Bas pod mostem", "Bass under the bridge"], "hello": ["„Wsiadam?”", "\"Can I get in?\""],
			"colour": Color("#b06cff"), "at": at, "open": true, "when": ["", ""], "new": is_new}


## The QUESTS screen (2026-11-17, quests_screen.gd over the map): with the longest names, its parts
## (‹ MAP, the tabs, the NOW line, the list, the detail and its buttons) inside the safe area and
## clear of each other, every row, tab and button MIN_TOUCH tall, the texts big enough; the tabs in
## order (First steps while they last; questlines, side jobs and rivals always); SHOW ON MAP pins the
## place, closes the screen and the map looks at it, then the item offers STOP TRACKING, which lets
## it go; a NEW questline loses its badge once its detail is seen (`seen`); a request closes the map
## and emits it; a rival's RACE calls them out; a drag on the list picks nothing; ‹ MAP goes back to
## the map; the pad: RB the next tab, D-pad the rows, A the first button; the NOW line's QUIT asks,
## then quits; --quest-pick's `pick_item`.
func _check_quests_screen(fm: Control, where: String, pt: float, safe: Rect2) -> void:
	const L := preload("res://scripts/quest_lines.gd")
	const FS := preload("res://scripts/first_steps.gd")
	where += " QUESTS"
	var e: Array = [
		L.entry("ride", "ride", L.Line.CAR, "Łuber · poproś o kurs", "Łuber · ask for a ride", Vector2.INF,
				Color("#4fd8c4"), "ride"),
		L.entry("garage", "garage", L.Line.CAR, "Warsztat u Mirka", "Mirek's garage", Vector2(400, 300), Color("#5aa0ff")),
		L.entry("k", "kebab", L.Line.CAR, "Kebab · Zakwas I Rożen", "Kebab · Zakwas I Rożen", Vector2(-1800, -2400),
				Color("#ff8a3d")),
		L.entry("s", "sloik", L.Line.CAR, "Słoiki · Dworzec Gdański", "Jars · Dworzec Gdański", Vector2(-2000, -2700),
				Color("#4fd8c4")),
		L.entry("c1", "cassette", L.Line.HELI, "Kaseta · Dach Pałacu Kultury", "Cassette · The Palace roof",
				Vector2(900, -100), Color("#ff5fa2")),
	]
	var steps: Array = []
	for id: String in FS.IDS:
		var nm: Array = FS.name_of(id)
		var en: Dictionary = {"kebab": e[2], "ride": e[0], "garage": e[1]}.get(id, {})
		steps.append({"id": id, "pl": nm[0], "en": nm[1], "done": id == "kebab", "entry": en})
	var chips: Array = []
	for i in 6:
		chips.append({"rung": i, "state": ["won", "open", "open", "open", "open", "locked"][i]})
	var f := {"car": Vector2(10.0, 20.0), "entries": e, "jobs": {"kebab": 3}, "now": {}, "friends": true, "steps": steps,
			"stories": [_story_fact("rave", Vector2(200.0, 100.0), true), _story_fact("boat", Vector2.INF)],
			"rivals": chips, "final": ["Po sześciu wygranych", "locked"], "night": false,
			"districts": [{"name_pl": "Śródmieście Północne", "name_en": "North City Centre", "found": true, "pct": 40}],
			"total": 21, "syrenki": [2, 10], "tapes": [1, 5], "places": [3, 40]}
	var picked: Array = []
	var on_pick := func(x: Dictionary) -> void: picked.append(x)
	fm.quest_picked.connect(on_pick)
	var called: Array = []
	var on_rival := func(r: int) -> void: called.append(r)
	fm.rival_called.connect(on_rival)
	var seen_ids: Array = []
	var on_seen := func(id: String) -> void: seen_ids.append(id)
	fm.seen.connect(on_seen)
	var hud0: CanvasLayer = fm.hud
	var reopen := func() -> void:
		if fm.visible:
			fm.close()
		hud0.open_full_map(Vector2(10.0, 20.0), 0.5, PackedVector2Array())
		fm.set_book(f.duplicate(true), fm.quest_pick)
	reopen.call()
	(fm.get("_quests_btn") as Button).pressed.emit()
	await process_frame
	await process_frame
	var scr: Control = fm.get("_screen")
	if not scr.visible:
		problems.append("%s: the QUESTS button did not open the screen" % where)
		_quests_screen_done(fm, on_pick, on_rival, on_seen)
		return
	var tab_keys: Array = (fm.tabs as Array).map(func(t: Dictionary) -> String: return str(t["key"]))
	if tab_keys != ["steps", "stories", "jobs", "rivals", "collection"] or str(scr.tab) != "steps":
		problems.append("%s: the tabs are %s, open on %s (want steps, stories, jobs, rivals, collection; on steps)" % [where, tab_keys, scr.tab])
	await _check_screen_layout(scr, where + " steps", pt, safe)
	# The picked row is in view once the list has settled (shots 2026-11-17: a tab with a wrapped head
	# line opened scrolled past it).
	var row_shown := func(tab: String) -> void:
		for i in 3:
			await process_frame
		var row := scr.find_child("row_%d" % int(scr.pick), true, false) as Control
		var box := (scr.get("_list_scroll") as Control).get_global_rect().grow(1.0)
		if row == null or not box.encloses(row.get_global_rect()):
			problems.append("%s %s: the picked row %d is out of the list's view (%s in %s)" % [where, tab, int(scr.pick),
					_pts(row.get_global_rect(), pt) if row != null else "none", _pts(box, pt)])
	await row_shown.call("steps")
	fm.open_screen("stories")
	await row_shown.call("stories")
	fm.open_screen("steps")
	await row_shown.call("steps again")
	# SHOW ON MAP on the nearest step (the garage): the screen closes, the map looks, the pin is set.
	var list: Array = scr.items()
	if list.is_empty() or str(list[0]["id"]) != "step_garage":
		problems.append("%s: the first step is %s (want the nearest place, the garage)" % [where, list[0]["id"] if not list.is_empty() else "none"])
	else:
		scr.select(0)
		await process_frame
		var map_b := scr.find_child("b_map", true, false) as Button
		if map_b == null:
			problems.append("%s: the garage step has no SHOW ON MAP" % where)
		else:
			map_b.pressed.emit()
			await process_frame
			if scr.visible or not fm.visible or str(fm.quest_pick.get("id", "")) != "garage" or picked.is_empty() \
					or fm.centre.distance_to(Vector2(400, 300)) > 1.0:
				problems.append("%s: SHOW ON MAP did not close the screen, pin the garage and look at it (%s)" % [where, fm.quest_pick.get("id", "")])
			fm.open_screen("", "step_garage")
			await process_frame
			var un := scr.find_child("b_untrack", true, false) as Button
			if un == null:
				problems.append("%s: the tracked step offers no STOP TRACKING" % where)
			else:
				un.pressed.emit()
				await process_frame
				if not (fm.quest_pick as Dictionary).is_empty() or not (picked.back() as Dictionary).is_empty():
					problems.append("%s: STOP TRACKING did not let the pin go" % where)
	# The questlines: the NEW one first; its detail seen, the badge goes.
	fm.open_screen("stories")
	await process_frame
	await _check_screen_layout(scr, where + " stories", pt, safe)
	if str(scr.picked().get("id", "")) != "story_rave" or not "story_rave" in seen_ids:
		problems.append("%s: the NEW questline is not first or not seen (%s, %s)" % [where, scr.picked().get("id", ""), seen_ids])
	if (fm.get("_badge") as Label).visible:
		problems.append("%s: the NEW badge stays once the questline was seen" % where)
	if scr.find_child("b_map", true, false) == null or scr.find_child("b_start", true, false) == null:
		problems.append("%s: a questline offers no SHOW ON MAP and CALL" % where)
	# Side jobs, the collection: laid out the same.
	for k in ["jobs", "collection"]:
		fm.open_screen(k)
		await process_frame
		await _check_screen_layout(scr, where + " " + k, pt, safe)
	# A request (the ride, a side job with no place): emits and closes the map.
	fm.open_screen("jobs")
	await process_frame
	var ride_i := -1
	for i in (scr.items() as Array).size():
		if str(scr.items()[i]["id"]) == "job_ride":
			ride_i = i
	if ride_i < 0:
		problems.append("%s: no ride in the side jobs" % where)
	else:
		scr.select(ride_i)
		await process_frame
		var n0 := picked.size()
		(scr.find_child("b_start", true, false) as Button).pressed.emit()
		await process_frame
		if picked.size() != n0 + 1 or str(picked.back().get("action", "")) != "ride" or fm.visible:
			problems.append("%s: a request did not emit and close the map" % where)
	# A rival's RACE: called out, the map closes.
	reopen.call()
	fm.open_screen("rivals")
	await process_frame
	await _check_screen_layout(scr, where + " rivals", pt, safe)
	scr.select(2)
	await process_frame
	var race := scr.find_child("b_race", true, false) as Button
	if race == null:
		problems.append("%s: an open rival has no RACE" % where)
	else:
		race.pressed.emit()
		await process_frame
		if called != [2] or fm.visible:
			problems.append("%s: RACE did not call the rival out and close the map (%s)" % [where, called])
	# A finger dragged on the list picks nothing; ‹ MAP goes back to the map.
	reopen.call()
	fm.open_screen("rivals")
	await process_frame
	var p0: int = scr.pick
	var row := scr.find_child("row_4", true, false) as Button
	if row != null:
		for i in 3:
			await process_frame  # the list settles on its pick (quests_screen.gd `_show_later`)
		(scr.get("_list_scroll") as ScrollContainer).ensure_control_visible(row)  # the finger lands on a row in view
		await process_frame
		var lr := row.get_global_rect()
		scr.touch(_touch_ev(0, lr.get_center(), true))
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = lr.get_center() + Vector2(0.0, 40.0 * pt)
		d.relative = Vector2(0.0, 40.0 * pt)
		scr.touch(d)
		row.pressed.emit()
		scr.touch(_touch_ev(0, d.position, false))
		if scr.pick != p0:
			problems.append("%s: the end of a drag on the list picked a row" % where)
		scr.touch(_touch_ev(0, Vector2.ZERO, true))  # a fresh touch: no drag any more
		scr.touch(_touch_ev(0, Vector2.ZERO, false))
	(scr.find_child("back", true, false) as Button).pressed.emit()
	await process_frame
	if scr.visible or not fm.visible:
		problems.append("%s: ‹ MAP did not go back to the map" % where)
	# The pad: Y opens QUESTS, RB the next tab, D-pad down the next row, A its first button.
	hud_pad(true)
	_pad_press(fm, JOY_BUTTON_Y)
	await process_frame
	if not scr.visible:
		problems.append("%s: pad Y did not open QUESTS" % where)
	else:
		var t0: String = scr.tab
		_pad_press(fm, JOY_BUTTON_RIGHT_SHOULDER)
		if scr.tab == t0:
			problems.append("%s: pad RB did not go to the next tab" % where)
		fm.open_screen("rivals")
		await process_frame
		scr.select(0)
		_pad_press(fm, JOY_BUTTON_DPAD_DOWN)
		if scr.pick != 1:
			problems.append("%s: pad down did not pick the next row (%d)" % [where, scr.pick])
		_pad_press(fm, JOY_BUTTON_A)
		await process_frame
		if called.size() != 2 or int(called.back()) != 1:
			problems.append("%s: pad A did not press the picked rival's RACE (%s)" % [where, called])
	hud_pad(false)
	# The quest under way: the NOW line, QUIT tapped twice closes the map and emits quit_quest.
	var now := L.entry("now", "now", L.Line.CAR, "Teraz · zlecenie na czasie", "Now · on-trend job", Vector2(-600, 200),
			Color("#ff7ac8"), L.NOW)
	f["now"] = now
	f["entries"] = [now]
	fm.quit_what = ["Sekretny rave", "Secret rave"]
	reopen.call()
	fm.open_screen()
	await process_frame
	await _check_screen_layout(scr, where + " now", pt, safe)
	var quits: Array = []
	var on_quit := func() -> void: quits.append(1)
	fm.quit_quest.connect(on_quit)
	var qb := scr.find_child("quit_quest", true, false) as Button
	if qb == null or not scr.rects().has("now"):
		problems.append("%s: no NOW line with QUIT while a quest runs" % where)
	else:
		var nm := scr.find_child("now_map", true, false) as Button
		if nm != null:
			nm.pressed.emit()
			await process_frame
			if scr.visible or fm.centre.distance_to(Vector2(-600, 200)) > 1.0:
				problems.append("%s: the NOW line's SHOW did not look at the target" % where)
			fm.open_screen()
			await process_frame
			qb = scr.find_child("quit_quest", true, false) as Button
		qb.pressed.emit()
		await process_frame
		if not quits.is_empty() or not fm.visible:
			problems.append("%s: one tap on QUIT already quit" % where)
		qb = scr.find_child("quit_quest", true, false) as Button
		if qb != null:
			qb.pressed.emit()
		await process_frame
		if quits.size() != 1 or fm.visible:
			problems.append("%s: the second tap on QUIT did not quit and close the map" % where)
	fm.quit_quest.disconnect(on_quit)
	fm.quit_what = []
	f["now"] = {}
	f["entries"] = e
	# --quest-pick=N: item N's first button, as a tap would (step 0, the garage: pinned).
	reopen.call()
	fm.pick_item(0)
	await process_frame
	if str(fm.quest_pick.get("id", "")) != "garage":
		problems.append("%s: pick_item(0) did not pin the garage (%s)" % [where, fm.quest_pick.get("id", "")])
	fm.quest_pick = {}
	_quests_screen_done(fm, on_pick, on_rival, on_seen)
	if not fm.visible:
		hud0.open_full_map(Vector2(10.0, 20.0), 0.5, PackedVector2Array())
	await process_frame


func _quests_screen_done(fm: Control, on_pick: Callable, on_rival: Callable, on_seen: Callable) -> void:
	fm.quest_picked.disconnect(on_pick)
	fm.rival_called.disconnect(on_rival)
	fm.seen.disconnect(on_seen)
	fm.set_book({})
	fm.close_screen()


## The QUESTS screen's layout on the tab shown: its parts inside the safe area and clear of each
## other (the detail's buttons inside the detail), MIN_TOUCH targets, the fonts.
func _check_screen_layout(scr: Control, where: String, pt: float, safe: Rect2) -> void:
	await process_frame
	var rs: Dictionary = scr.rects()
	for k in ["back", "tabs", "list", "detail"]:
		if not rs.has(k):
			problems.append("%s: no %s" % [where, k])
			return
	_check_touch(where + " back", rs["back"], pt, safe)
	for k in rs:
		if not safe.grow(0.5).encloses(rs[k]):
			problems.append("%s: the %s %s is outside the safe area %s" % [where, k, _pts(rs[k], pt), _pts(safe, pt)])
		if str(k).begins_with("b_"):
			_check_touch(where + " " + str(k), rs[k], pt, safe)
			if not (rs["detail"] as Rect2).grow(0.5).encloses(rs[k]):
				problems.append("%s: the button %s is outside the detail" % [where, k])
	var parts := ["back", "tabs", "list", "detail", "now"]
	for i in parts.size():
		for j in range(i + 1, parts.size()):
			if rs.has(parts[i]) and rs.has(parts[j]) and (rs[parts[i]] as Rect2).intersects(rs[parts[j]]):
				problems.append("%s: %s and %s overlap" % [where, parts[i], parts[j]])
	for b: Button in scr.find_children("row_*", "Button", true, false) + scr.find_children("tab_*", "Button", true, false):
		if b.get_global_rect().size.y < MIN_TOUCH * pt - 0.5:
			problems.append("%s: %s is %.0f pt tall (< %d)" % [where, b.name, b.get_global_rect().size.y / pt, MIN_TOUCH])
	_check_fonts(scr, where, pt)


static func _touch_ev(i: int, at: Vector2, down: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = at
	e.pressed = down
	return e


## G12b: a gamepad button press through the full map's input (as the pad sends it).
func _pad_press(fm: Control, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = true
	fm._input(ev)


## G12b: makes the pad (or a finger) the last input used (gamepad.gd `in_use`).
func hud_pad(on: bool) -> void:
	const Pad := preload("res://scripts/gamepad.gd")
	if on:
		var ev := InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTON_LEFT_SHOULDER
		ev.pressed = true
		Pad.note(ev)
	else:
		Pad.note(InputEventScreenTouch.new())


## F's ask (2026-10-31): the full map's hold to teleport. Held HOLD_S still, it emits `teleport`
## once with the map point under the finger and closes; let go early, dragged past the slop or
## joined by a second finger, nothing; refused (can_teleport gives a reason), no ring and the note
## card shows, inside the safe area and clear of the other cards.
func _check_map_hold(hud: CanvasLayer, where: String) -> int:
	var fm: Control = hud.full_map
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var got: Array[Vector2] = []
	var on_jump := func(p: Vector2) -> void: got.append(p)
	fm.teleport.connect(on_jump)
	var mid: Vector2 = fm.get_viewport().get_visible_rect().size * 0.5 + Vector2(0.0, 30.0 * pt)
	var touch := func(i: int, at: Vector2, down: bool) -> void:
		var e := InputEventScreenTouch.new()
		e.index = i
		e.position = at
		e.pressed = down
		fm._input(e)
	var hold := func(seconds: float) -> void:
		var t := 0.0
		while t < seconds and fm.visible:
			fm._process(0.05)
			t += 0.05
	var cases := [["let go early", 0.3, "early"], ["dragged", 1.0, "drag"], ["two fingers", 1.0, "two"],
			["refused", 1.0, "refused"], ["held", 1.0, "held"]]
	for c: Array in cases:
		hud.open_full_map(Vector2(10.0, 20.0), 0.5, PackedVector2Array())
		await process_frame
		got.clear()
		var why: Array = ["Nie teraz", "Not now"] if c[2] == "refused" else []
		fm.can_teleport = func() -> Array: return why
		var want: Vector2 = fm.to_map(mid)
		touch.call(0, mid, true)
		if c[2] == "drag":
			var d := InputEventScreenDrag.new()
			d.index = 0
			d.position = mid + Vector2(30.0 * pt, 0.0)
			fm._input(d)
		elif c[2] == "two":
			touch.call(1, mid + Vector2(80.0 * pt, 0.0), true)
		hold.call(float(c[1]))
		if c[2] == "refused":
			var rs: Dictionary = fm.rects()
			if not rs.has("note"):
				problems.append("%s hold %s: no note card" % [where, c[0]])
			else:
				if not safe.grow(0.5).encloses(rs["note"]):
					problems.append("%s hold: the note %s is outside the safe area" % [where, _pts(rs["note"], pt)])
				for k in rs:
					if k != "note" and (rs[k] as Rect2).intersects(rs["note"]):
						problems.append("%s hold: the note and %s overlap" % [where, k])
		touch.call(0, mid, false)
		touch.call(1, mid, false)
		var want_n := 1 if c[2] == "held" else 0
		if got.size() != want_n:
			problems.append("%s hold %s: teleport emitted %d times (want %d)" % [where, c[0], got.size(), want_n])
		elif want_n == 1:
			if got[0].distance_to(want) > 0.5:
				problems.append("%s hold: teleported to %s, the finger was over %s" % [where, got[0], want])
			if fm.visible:
				problems.append("%s hold: the map stayed open after the teleport" % where)
		if fm.visible:
			fm.close()
		await process_frame
	fm.teleport.disconnect(on_jump)
	fm.can_teleport = Callable()
	return 1


## Loop MW-6: Fotka open (the HUD hidden): its buttons 44 pt and inside the safe area, nothing
## overlapping, the texts big enough; closed, nothing of it shows and the HUD is back.
func _check_fotka(vp: SubViewport, hud: CanvasLayer, tag: String) -> int:
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var f: Fotka = Fotka.new()
	f.hud = hud
	f.pt = pt
	f.safe = safe
	vp.add_child(f)
	f.open(Vector3.ZERO, 45.0, 40.0, 110.0)
	await process_frame
	await process_frame
	var where := "%s fotka" % tag
	if hud.visible:
		problems.append("%s: the HUD still shows" % where)
	var rects: Dictionary = f.ui_rects()
	for k: String in ["fotka_close", "fotka_shutter", "fotka_zoom_in", "fotka_zoom_out", "fotka_hint"]:
		if not rects.has(k):
			problems.append("%s: no %s" % [where, k])
	var names := rects.keys()
	for a in names.size():
		var ra: Rect2 = rects[names[a]]
		if str(names[a]) != "fotka_hint":
			_check_touch("%s %s" % [where, names[a]], ra, pt, safe)
		elif not safe.grow(0.5).encloses(ra):
			problems.append("%s: the hint %s is outside the safe area" % [where, _pts(ra, pt)])
		for b in range(a + 1, names.size()):
			var rb: Rect2 = rects[names[b]]
			if ra.intersection(rb).get_area() > pt * pt:
				problems.append("%s: %s %s overlaps %s %s" % [where, names[a], _pts(ra, pt), names[b], _pts(rb, pt)])
	_check_fonts(f.layer, where, pt)
	if verbose:
		var parts := PackedStringArray()
		for k in rects:
			parts.append("%s %s" % [k, _pts(rects[k], pt)])
		print("  %s: %s" % [where, " · ".join(parts)])
	f.close()
	if f.layer.visible or not hud.visible:
		problems.append("%s: closing left its layer up or the HUD hidden" % where)
	f.queue_free()
	return 1


## The garage loop: the paint card open (the swatches, the action, WYJAZD), in three states (the
## paint on the car, one to buy, one short of money, the gold one locked): every button 44 pt and
## inside the safe area, the card inside it unshrunk, no two buttons overlapping, the texts big
## enough; WYJAZD closes it.
func _check_garage(vp: SubViewport, hud: CanvasLayer, tag: String) -> int:
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var w: Node = Wallet.new()
	w.persistent = false
	w.zl = 12345
	vp.add_child(w)
	var d: Node = Dialogue.new()
	vp.add_child(d)
	var g: Node = Garage.new()
	g.wallet = w
	g.hud = hud
	g.dialogue = d
	g.eggs_found = func() -> int: return 2
	vp.add_child(g)
	g.open_card()
	var states := 0
	for pick in ["red", "pink", "black", "gold"]:
		if pick == "black":
			w.zl = 7
		g.card.pick(pick)
		await process_frame
		await process_frame
		var where := "%s garage card (%s)" % [tag, pick]
		var rects: Dictionary = g.card.ui_rects()
		var card: Rect2 = rects["card"]
		if not safe.grow(0.5).encloses(card):
			problems.append("%s: the card %s sticks out of the safe area %s" % [where, _pts(card, pt), _pts(safe, pt)])
		var names := rects.keys()
		names.erase("card")
		for a in names.size():
			var ra: Rect2 = rects[names[a]]
			_check_touch("%s %s" % [where, names[a]], ra, pt, safe)
			if not card.grow(0.5).encloses(ra):
				problems.append("%s: %s is outside the card" % [where, names[a]])
			for b in range(a + 1, names.size()):
				if ra.intersection(rects[names[b]]).get_area() > pt * pt:
					problems.append("%s: %s overlaps %s" % [where, names[a], names[b]])
		_check_fonts(g.card, where, pt)
		if verbose:
			print("  %s: card %s, action %s" % [where, _pts(card, pt), _pts(rects["action"], pt)])
		states += 1
	# G13: the parts tab, with every cell's state (the TT to buy, short, owned; the nitro; a maxed part).
	g.card.show_tab("parts")
	w.zl = 12345
	for pick in ["tt", "nitro", "tyres", "engine", "hatch", "tt", "tyres"]:
		if pick == "tt" and states == 9:
			w.zl = 100  # short
		if pick == "tyres" and states == 10:
			w.tune = {"tyres": 3, "engine": 1}  # maxed
			w.nitro = true
		g.card.pick_item(pick)
		await process_frame
		await process_frame
		var where2 := "%s garage parts (%s)" % [tag, pick]
		var rects2: Dictionary = g.card.ui_rects()
		var card2: Rect2 = rects2["card"]
		if not safe.grow(0.5).encloses(card2):
			problems.append("%s: the card %s sticks out of the safe area %s" % [where2, _pts(card2, pt), _pts(safe, pt)])
		var names2 := rects2.keys()
		names2.erase("card")
		for a in names2.size():
			var ra2: Rect2 = rects2[names2[a]]
			_check_touch("%s %s" % [where2, names2[a]], ra2, pt, safe)
			if not card2.grow(0.5).encloses(ra2):
				problems.append("%s: %s is outside the card" % [where2, names2[a]])
			for b in range(a + 1, names2.size()):
				if ra2.intersection(rects2[names2[b]]).get_area() > pt * pt:
					problems.append("%s: %s overlaps %s" % [where2, names2[a], names2[b]])
		_check_fonts(g.card, where2, pt)
		states += 1
	(g.card.get("_leave") as Button).pressed.emit()
	await process_frame
	if g.card.visible or g.is_open():
		problems.append("%s garage card: WYJAZD did not close it" % tag)
	# G2: MOJE AUTO from the full map: the same card, its title, buys wait for the workshop.
	w.tune = {}
	w.zl = 12345
	g.open_card("parts", "mine")
	g.card.pick_item("engine")
	await process_frame
	var act := g.card.get("_action") as Button
	if not act.disabled or g.mode != "mine" or not (g.card.get("_title") as Label).text in ["MOJE AUTO", "MY CAR"]:
		problems.append("%s MOJE AUTO: a buy is not held for the workshop (%s)" % [tag, act.disabled])
	if not g.card.stage.visible or g.card.stage.mode != "mine":
		problems.append("%s MOJE AUTO: the stage is not up in its own mode" % tag)
	g.close_card()
	g.card.queue_free()
	g.queue_free()
	d.queue_free()
	w.queue_free()
	return states


## 2026-10-30: RADIO tapped changes the station; held RADIO_HOLD s it skips the track once and
## its release changes nothing (radio_hold_tick is given its own clock).
func _check_radio_hold(hud: CanvasLayer) -> void:
	var got: Array[String] = []
	hud.radio_pressed.connect(func(): got.append("station"))
	hud.radio_skip_pressed.connect(func(): got.append("skip"))
	var b: Button = hud.get("_radio_button")
	var hold_ms := int(hud.RADIO_HOLD * 1000.0)
	for held: int in [100, hold_ms + 50]:
		got.clear()
		b.button_down.emit()
		var t0: int = hud.get("_radio_down_ms")
		hud.radio_hold_tick(t0 + held / 2)
		hud.radio_hold_tick(t0 + held)
		hud.radio_hold_tick(t0 + held + 300)  # still down a while: one skip only
		b.pressed.emit()  # the release
		b.button_up.emit()
		var want := "station" if held < hold_ms else "skip"
		if got != [want]:
			problems.append("radio held %d ms: %s, want [%s]" % [held, got, want])


## PT-6 (2026-11-02): a speech bubble never covers the minimap or its +/- buttons, wherever its
## speaker stands on screen (the jogger's "On your left!" sat on them for ~4 s in the first drive).
## Sweeps a speaker over the screen and well past its edges (a speaker off screen pushes its bubble
## into the corner), in the car and the helicopter, with a short and a long
## line, and checks every bubble that gets a place against the minimap, the zoom buttons, the
## wallet and the top row.
func _check_bubble_sweep(hud: CanvasLayer, bubbles: Control, screen: Vector2i, tag: String) -> void:
	var lines := [["Lewa wolna! Lewa! No dobra, chodnik jest jeden.", "On your left! Left! Fine, there's only one pavement."],
			["Tak.", ""]]
	var n := 0
	var bad := 0
	var tails := 0
	for flying in [false, true]:
		hud.set_flying(flying)
		hud.clear_all()
		var keep: Array[Rect2] = []
		var named: Dictionary = hud.named_rects()
		for k in ["minimap", "zoom_in", "zoom_out", "wallet", "gear"]:
			if named.has(k):
				keep.append(named[k])
		for line in lines:
			for ix in 41:
				for iy in 41:
					bubbles.clear()
					_say(bubbles, "Biegacz", Vector2(screen.x * (ix - 10) / 20.0, screen.y * (iy - 10) / 20.0), line[0], line[1])
					for item in bubbles.layout():
						var r: Rect2 = item[2]
						n += 1
						# PT-9: the tail runs to the speaker (when it is within reach).
						var spot: Vector2 = item[1]
						var gap: float = bubbles.tail_gap(spot, r)
						if gap > 1.0 and hud.bubble_area().has_point(spot) and not r.grow(bubbles.TAIL * hud.pt * 2.0).has_point(spot) and r.get_center().distance_to(spot) < 90.0 * hud.pt:
							tails += 1
							if tails <= 3:
								problems.append("%s PT-9: a bubble's tail ends %.0f px short of its speaker at %d,%d" % [
										tag, gap, spot.x, spot.y])
						for k in keep:
							if (r as Rect2).intersection(k).get_area() > 1.0:
								bad += 1
								if bad <= 3:
									problems.append("%s PT-6: a bubble %s covers %s with the speaker at %d,%d" % [
											tag, _pts(r, hud.pt), _pts(k, hud.pt), screen.x * (ix - 10) / 20, screen.y * (iy - 10) / 20])
	bubbles.clear()
	hud.set_flying(false)
	if n == 0:
		problems.append("%s PT-6: the bubble sweep placed nothing" % tag)


## PT-9 (2026-11-02, run 10 at 1266x585): the radio ticker slid in from off screen, so mid-slide
## the screen edge cut its first words. Every step of its slide must stay inside the safe area.
func _check_ticker_slide(hud: CanvasLayer, tag: String) -> void:
	hud.clear_all()
	hud.ticker("KEBAB FM · Dzień dobry, Warszawo! Dobre popołudnie, Warszawo!", Color("#ff5fc8"), "")
	hud.panel_rects()
	var safe: Rect2 = hud.safe_rect()
	var box: Control = hud.get("_ticker")
	for k in 11:
		hud.call("_slide_ticker", k / 10.0)
		if box.visible and box.position.x < safe.position.x - 0.5:
			problems.append("%s PT-9: the ticker's slide puts it %.0f px past the safe area's left edge" % [
					tag, safe.position.x - box.position.x])
			break
	hud.clear_all()


## PT-10 (2026-11-02, run 10): the target pointer drew over speech bubbles and the banner, and at
## the screen edge its distance ran into its arrow. Checks the draw order, that the edge label
## stays clear of its arrow all round, and that the edge arrow gives way to a bubble in its spot
## and keeps off the fixed controls (the minimap, the wallet, the zoom buttons, the pedals).
func _check_target_pointer(hud: CanvasLayer, bubbles: Control, screen: Vector2i, tag: String) -> void:
	var overlay: Control = hud.get("_overlay")
	var banner: Control = hud.get("_banner")
	if not (overlay.get_index() < bubbles.get_index() and bubbles.get_index() < banner.get_index()):
		problems.append("%s PT-10: draw order is pointer %d, bubbles %d, banner %d (want pointer under both)" % [
				tag, overlay.get_index(), bubbles.get_index(), banner.get_index()])
	hud.clear_all()
	bubbles.clear()
	hud.panel_rects()
	var pt: float = hud.pt
	var centre := Vector2(screen) * 0.5
	var into := 0
	var under := 0
	# PT-27 (2026-11-07): both schemes (Classic's BRAKE sits left of GAS) and a job's long label.
	for k in 144:
		hud.set_scheme(0 if k < 72 else 1)
		var dir := Vector2.from_angle(TAU * (k % 72) / 72.0)
		hud.set_target(centre + dir * float(screen.x) * 2.0, "1888 m" if k % 2 == 0 else "KEBAB 1948 m", Color("#ff9a3c"), true)
		var e: Dictionary = hud.edge_pointer()
		if e.is_empty():
			continue
		var tip: Vector2 = e["tip"]
		var d: Vector2 = e["dir"]
		var label: Rect2 = e["label"]
		var near := INF
		for c in [label.position, Vector2(label.end.x, label.position.y), label.end, Vector2(label.position.x, label.end.y)]:
			near = minf(near, (tip - c).dot(d))
		if near < (hud.EDGE_ARROW + 2.5) * pt:
			into += 1
			if into <= 2:
				problems.append("%s PT-10: the edge distance runs into its arrow pointing %d°" % [tag, k * 5])
		if not Rect2(Vector2.ZERO, Vector2(screen)).encloses(label):
			problems.append("%s PT-10: the edge distance %s leaves the screen pointing %d°" % [tag, _pts(label, pt), k * 5])
		# 2026-11-03: the arrow and its distance keep off the minimap, the wallet, the zoom buttons
		# and the pedals (pointing up-left the arrow hid under the minimap and the wallet).
		var edge_box := label.merge(Rect2(tip, Vector2.ZERO).grow((hud.EDGE_ARROW + 2.0) * pt))
		var fixed: Dictionary = hud.named_rects()
		for n: String in fixed:
			if (n in ["minimap", "wallet", "zoom_in", "zoom_out"] or n.begins_with("pedal")) and (fixed[n] as Rect2).intersects(edge_box):
				under += 1
				if under <= 2:
					problems.append("%s: the edge arrow %s pointing %d° (scheme %d) sits under %s %s" % [tag, _pts(edge_box, pt), (k % 72) * 5, k / 72, n, _pts(fixed[n], pt)])
	# PT-35 (2026-11-08): with a Classic thumb down the steering strip is on screen, so the edge
	# arrow's "KEBAB n m" must treat it as a no-go rect (as it does the pedals), wherever the thumb
	# came down; with the thumb up only the resting hint is.
	hud.set_scheme(1)  # Classic, the slider layout (the arrows layout has no strip)
	hud.set_arrows_layout(false)
	# F 2026-11-14: the slider layout has the arrows layout's see-through pedals (the bigger HAMULEC).
	if not is_equal_approx(float(hud.call("_brake_r")), float(hud.ARROWS_BRAKE_R)) or not hud.call("_pedals_look"):
		problems.append("%s the slider layout's HAMULEC is not the pedal (%.0f pt)" % [tag, float(hud.call("_brake_r"))])
	var strip_at := Vector2(float(screen.x) * 0.3, float(screen.y) - 70.0 * pt)
	var strip_half: float = (float(hud.STICK_R) + 16.0) * pt
	var strip := Rect2(strip_at - Vector2(strip_half, 16.0 * pt), Vector2(strip_half * 2.0, 32.0 * pt))
	var covered_up := false
	for r: Rect2 in hud.call("_pedal_rects"):
		covered_up = covered_up or r.encloses(strip)
	hud.hold_stick(strip_at, Vector2.ZERO)
	var covered_down := false
	for r: Rect2 in hud.call("_pedal_rects"):
		covered_down = covered_down or r.encloses(strip)
	hud.release_all()
	hud.set_arrows_layout(true)
	if covered_up or not covered_down:
		problems.append("%s PT-35: the steering strip %s is %s the edge arrow's no-go rects with the thumb %s" % [tag, _pts(strip, pt), "missing from" if not covered_down else "wrongly in", "down" if not covered_down else "up"])
	# A bubble right where the left edge arrow points: the arrow moves along the edge, clear of it.
	hud.set_scheme(0)
	hud.set_target(Vector2(-float(screen.x), centre.y), "297 m", Color("#ff9a3c"), true)
	var before: Dictionary = hud.edge_pointer()
	if not before.is_empty():
		_say(bubbles, "Kierowca", (before["label"] as Rect2).get_center(), "Kierunkowskaz to nie opcja!", "The indicator isn't an optional extra!")
		bubbles.layout()
		var after: Dictionary = hud.edge_pointer()
		var tip: Vector2 = after["tip"]
		var box := (after["label"] as Rect2).merge(Rect2(tip, Vector2.ZERO).grow((hud.EDGE_ARROW + 3.0) * pt))
		for r: Rect2 in bubbles.rects:
			if r.intersects(box):
				problems.append("%s PT-10: the edge arrow %s stays under a bubble %s" % [tag, _pts(box, pt), _pts(r, pt)])
	hud.set_target(Vector2.ZERO, "", Color.WHITE, false)
	bubbles.clear()
	hud.clear_all()


## PT-26 (2026-11-07, run 20261106-004005): the roadworks sign's bubble by the start covered the
## ghost finger's steering hint. With the finger on, a bubble whose speaker stands right under the
## hint (both schemes) keeps off it, and the hint's room goes when the finger does.
## First hour step 6: the card's ✕ (`set_card_close`) shows on the card, is a full touch target
## inside the card and the safe area, sends its index to the card's owner, and goes with the card.
## F's playtest 2026-11-16: the choice card keeps its 440 pt, has her face on the left of the words, its three
## buttons one under the other inside the card and the safe area, the first gold and taller (1.4 x), the other two
## plain, and each button reaches the card's owner.
func _check_choice_card(hud: CanvasLayer, safe: Rect2, pt: float, where: String) -> void:
	var card := hud.get("_card") as Control
	var art := hud.get("_card_art") as Control
	if not hud.card_has_art() or art == null or not art.is_visible_in_tree():
		problems.append("%s: no face on the card" % where)
		return
	var cr := card.get_global_rect()
	var ar := art.get_global_rect()
	if cr.size.x > 440.0 * pt + 1.0:
		problems.append("%s: the card is %.0f pt wide, over 440" % [where, cr.size.x / pt])
	if absf(ar.size.x - 72.0 * pt) > 1.5 or not cr.grow(1.0).encloses(ar):
		problems.append("%s: the face is %.0f pt wide or outside the card (%s)" % [where, ar.size.x / pt, ar])
	var body := hud.get("_card_body") as Control
	if body.get_global_rect().position.x < ar.end.x - 1.0:
		problems.append("%s: the words start left of the face's end" % where)
	var bs: Array[Button] = []
	for i in 3:
		var b := (hud.get("_card_buttons") as Node).get_node_or_null("button%d" % i) as Button
		if b == null:
			problems.append("%s: no button %d" % [where, i])
			return
		bs.append(b)
		var r := b.get_global_rect()
		if not cr.grow(1.0).encloses(r) or not safe.grow(1.0).encloses(r):
			problems.append("%s: button %d %s is outside the card or the safe area" % [where, i, r])
		if r.size.y < MIN_TOUCH * pt - 0.5:
			problems.append("%s: button %d is %.0f pt tall, under 44" % [where, i, r.size.y / pt])
	if not (bs[0].get_global_rect().end.y <= bs[1].get_global_rect().position.y + 1.0 and bs[1].get_global_rect().end.y <= bs[2].get_global_rect().position.y + 1.0):
		problems.append("%s: the buttons are not one under the other" % where)
	var tall := bs[0].get_global_rect().size.y / maxf(bs[1].get_global_rect().size.y, 1.0)
	if tall < 1.35 or tall > 1.45 or absf(bs[1].get_global_rect().size.y - bs[2].get_global_rect().size.y) > 1.0:
		problems.append("%s: the lead button is %.2f x the plain ones (want 1.4), the plain two %.0f and %.0f px" % [where, tall,
				bs[1].get_global_rect().size.y, bs[2].get_global_rect().size.y])
	var gold := (bs[0].get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	var plain := (bs[1].get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	if gold.r < 0.8 or gold.g < 0.6 or gold.b > 0.5 or plain.v > 0.3:
		problems.append("%s: the lead button's fill %s is not gold or the plain one's %s is not dark" % [where, gold, plain])
	for i in 3:
		_closer.got = -1
		bs[i].pressed.emit()
		if _closer.got != i:
			problems.append("%s: button %d pressed %d for the card's owner" % [where, i, _closer.got])


func _check_card_close(hud: CanvasLayer, safe: Rect2, pt: float, where: String) -> void:
	var x := hud.get("_card_x") as Control
	var card := hud.get("_card") as Control
	if x == null or not x.is_visible_in_tree():
		problems.append("%s: the card's ✕ is not shown" % where)
		return
	var r := x.get_global_rect()
	if r.size.x < MIN_TOUCH * pt - 0.5 or r.size.y < MIN_TOUCH * pt - 0.5:
		problems.append("%s: the card's ✕ is %.0fx%.0f pt, under 44" % [where, r.size.x / pt, r.size.y / pt])
	if not card.get_global_rect().grow(1.0).encloses(r) or not safe.grow(1.0).encloses(r):
		problems.append("%s: the card's ✕ is outside the card or the safe area (%s)" % [where, r])
	if int(hud.card_close()) != 3:
		problems.append("%s: card_close() is %d, not 3" % [where, hud.card_close()])
	_closer.got = -1
	hud.press_card_close()
	if _closer.got != 3:
		problems.append("%s: the ✕ pressed %d for the card's owner, not 3" % [where, _closer.got])
	# Another card shown takes the ✕ away.
	hud.show_card("X", "y", PackedStringArray(["OK"]), Color.WHITE)
	if x.visible or int(hud.card_close()) != -1:
		problems.append("%s: the next card kept the ✕" % where)
	hud.hide_card()


func _check_finger_hint(hud: CanvasLayer, bubbles: Control, tag: String) -> void:
	for s in [0, 1, 2]:  # Point, Classic with the arrows, Classic with the slider
		hud.clear_all()
		bubbles.clear()
		hud.set_scheme(mini(s, 1))
		hud.set_arrows_layout(s != 2)
		hud.ghost_finger(true)
		var hint: Rect2 = hud.finger_hint_rect()
		if not hud.panel_rects().has(hint):
			problems.append("%s PT-26: scheme %d: the ghost finger's hint %s takes no room" % [tag, s, _pts(hint, hud.pt)])
		_say(bubbles, "", hint.get_center() + Vector2(0.0, hint.size.y), "MARSZAŁKOWSKA: REMONT · ETAP 47 Z 312", "MARSZAŁKOWSKA ROADWORKS · PHASE 47 OF 312")
		bubbles.layout()
		for r: Rect2 in bubbles.rects:
			if r.intersects(hint):
				problems.append("%s PT-26: scheme %d: a bubble %s covers the steering hint %s" % [tag, s, _pts(r, hud.pt), _pts(hint, hud.pt)])
		hud.ghost_finger(false)
		if hud.panel_rects().has(hint):
			problems.append("%s PT-26: the hint's room stays after the finger goes" % tag)
	hud.set_scheme(0)
	hud.set_arrows_layout(true)
	bubbles.clear()
	hud.clear_all()


## F 2026-11-13: the arrows layout (a Settings choice; the slider is the default since 2026-11-14). In both hands' layouts: the two arrows, GAZ
## and HAMULEC are touch targets of 44 pt or more, inside the safe area, apart from each other and
## in the HUD's no-go rects, the left arrow left of the right one; a finger down on an arrow steers
## that way, rolling onto the other switches, lifting lets go; and drive_controls.gd ramps a held
## arrow from ARROW_START to full lock in ARROW_RAMP s.
func _check_arrows(hud: CanvasLayer, tag: String) -> void:
	var pt: float = hud.pt
	var safe: Rect2 = hud.get("_safe")
	for lefty in [false, true]:
		hud.clear_all()
		hud.set_left_handed(lefty)
		hud.set_scheme(1)
		hud.set_arrows_layout(true)
		var side := "left-handed" if lefty else "right-handed"
		var tt: Dictionary = hud.touch_targets()
		var names := ["steer_left", "steer_right", "gas", "brake"]
		for n in names:
			if not tt.has(n):
				problems.append("%s arrows (%s): no %s" % [tag, side, n])
				continue
			var r: Rect2 = tt[n]
			if minf(r.size.x, r.size.y) < 44.0 * pt - 0.5:
				problems.append("%s arrows (%s): %s %s is under 44 pt" % [tag, side, n, _pts(r, pt)])
			if not safe.encloses(r):
				problems.append("%s arrows (%s): %s %s leaves the safe area" % [tag, side, n, _pts(r, pt)])
		if names.all(func(n): return tt.has(n)):
			for i in names.size():
				for j in range(i + 1, names.size()):
					if (tt[names[i]] as Rect2).intersects(tt[names[j]]):
						problems.append("%s arrows (%s): %s overlaps %s" % [tag, side, names[i], names[j]])
			if (tt["steer_left"] as Rect2).get_center().x >= (tt["steer_right"] as Rect2).get_center().x:
				problems.append("%s arrows (%s): the left arrow is not left of the right one" % [tag, side])
			var rects: Array = hud.call("_pedal_rects")
			for n in ["steer_left", "steer_right"]:
				if not rects.any(func(r: Rect2): return r.encloses(tt[n])):
					problems.append("%s arrows (%s): %s is not in the no-go rects" % [tag, side, n])
			var lc: Vector2 = (tt["steer_left"] as Rect2).get_center()
			var rc: Vector2 = (tt["steer_right"] as Rect2).get_center()
			hud.call("_input", _touch(5, lc, true))
			var a: int = hud.arrows()
			var drag := InputEventScreenDrag.new()
			drag.index = 5
			drag.position = rc
			hud.call("_input", drag)
			var b: int = hud.arrows()
			hud.call("_input", _touch(5, rc, false))
			var c: int = hud.arrows()
			if a != 1 or b != -1 or c != 0:
				problems.append("%s arrows (%s): left down, roll right, lift gave %d, %d, %d (want 1, -1, 0)" % [tag, side, a, b, c])
	hud.set_left_handed(false)
	hud.set_scheme(0)
	hud.clear_all()
	# The ramp.
	var controls = load("res://scripts/drive_controls.gd").new()
	var car = load("res://scripts/car.gd").new()
	controls.scheme = 1
	controls.arrows = 1
	controls.drive(car, Vector2.ZERO, false, {}, true, false, 0.0, 1.0 / 60.0)
	var first: float = car.steer
	for i in 30:
		controls.drive(car, Vector2.ZERO, false, {}, true, false, 0.0, 1.0 / 60.0)
	var full: float = car.steer
	controls.arrows = -1
	controls.drive(car, Vector2.ZERO, false, {}, true, false, 0.0, 1.0 / 60.0)
	var flip: float = car.steer
	controls.arrows = 0
	controls.drive(car, Vector2.ZERO, false, {}, true, false, 0.0, 1.0 / 60.0)
	var none: float = car.steer
	car.free()
	if absf(first - controls.ARROW_START) > 0.02 or not is_equal_approx(full, 1.0) or absf(flip + controls.ARROW_START) > 0.02 or none != 0.0:
		problems.append("%s arrows: the ramp gave %.2f at once, %.2f after 0.5 s, %.2f on the other arrow, %.2f let go (want %.2f, 1, -%.2f, 0)"
				% [tag, first, full, flip, none, controls.ARROW_START, controls.ARROW_START])


static func _touch(index: int, at: Vector2, down: bool) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = at
	t.pressed = down
	return t


## A speech bubble from a speaker standing at screen point `p`.
func _say(bubbles: Control, who: String, p: Vector2, pl: String, en: String) -> void:
	var anchor := func() -> Vector3: return Vector3(p.x, p.y, 0.0)
	_speakers[who] = anchor
	# A person's quest line is the fixed panel's now (F 2026-11-16); these scenes test where a floating
	# caption goes, so the speaker is a non-person ("Nawigacja") for the bubble's layout.
	var speaker := "Nawigacja" if Portraits.has_face(who) else who
	bubbles.say(anchor, speaker, pl, en, 4.0, Color("#ff9a3c"), 0.0)


func _check_state(hud: CanvasLayer, bubbles: Control, where: String) -> void:
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var targets: Dictionary = hud.touch_targets()
	for k in targets:
		_check_touch("%s %s" % [where, k], targets[k], pt, safe)
	var rects: Dictionary = hud.named_rects()
	if hud.touch_off:
		# Desktop: --no-touch: no pedal, brake or climb pad to press, none taking room.
		for k in targets.keys() + rects.keys():
			if String(k) in ["brake", "gas", "climb", "sink"] or String(k).begins_with("pedal"):
				problems.append("%s: %s is on screen with --no-touch" % [where, k])
	var i := 0
	for r in bubbles.rects:
		rects["bubble%d" % i] = r
		i += 1
	var names := rects.keys()
	for a in names.size():
		var ra: Rect2 = rects[names[a]]
		if not safe.grow(0.5).encloses(ra):
			problems.append("%s: %s %s is outside the safe area %s" % [where, names[a], _pts(ra, pt), _pts(safe, pt)])
		for b in range(a + 1, names.size()):
			var rb: Rect2 = rects[names[b]]
			if ra.intersection(rb).get_area() > pt * pt:
				problems.append("%s: %s %s overlaps %s %s" % [where, names[a], _pts(ra, pt), names[b], _pts(rb, pt)])
	# The passing panels keep clear of the player's car (the middle of the screen); loop 2d-1: so
	# does a Łuber card (the side card).
	var keep_clear := ["ticker", "toast", "note", "info", "perf", "banner"]
	if where.contains(" ride"):
		keep_clear.append("card")
	for n in keep_clear:
		if rects.has(n) and (rects[n] as Rect2).intersects(hud.car_zone()):
			problems.append("%s: %s %s covers the car's spot %s" % [where, n, _pts(rects[n], pt), _pts(hud.car_zone(), pt)])
	var unplaced: Array = hud.unplaced()
	if not unplaced.is_empty():
		problems.append("%s: no room for %s" % [where, ", ".join(unplaced)])
		if "card" in unplaced:
			# Loop 2d-1: how big the card wanted to be, in points.
			problems.append("%s:   (the card %s pt)" % [where, hud._card.get_combined_minimum_size() / pt])
	if not hud.forced().is_empty():
		problems.append("%s: the card stands over something (no clear spot)" % where)
	for n in hud.waiting():
		_waits.append("%s in %s" % [n, where])
	var fit: Dictionary = hud.fitted()
	for n in fit:
		if Access.text_scale <= 1.0:
			problems.append("%s: %s shrank its text at the normal size" % [where, n])
		elif float(fit[n]) < 1.0 - 0.001:
			problems.append("%s: %s's text is below the normal size (x%.2f)" % [where, n, fit[n]])
		else:
			_fitted.append("%s x%.2f in %s" % [n, fit[n], where])
	if bubbles.overlaps > 0:
		_waits.append("%d speech bubble(s) in %s" % [bubbles.overlaps, where])
	_check_fonts(hud, where, pt)
	for body in ["_card_body", "_card_body_en", "_ticker_label", "_ticker_sub", "_toast", "_toast_gloss", "_status_hint",
			"_status_hint_en", "_info_pl", "_info_en", "_note_body", "_police_pl", "_police_en"]:
		var l: Label = hud.get(body)
		if l.is_visible_in_tree() and l.get_theme_font_size("font_size") < MIN_BODY * pt - 0.5:
			problems.append("%s: %s is %.1f pt (body text needs %.0f)" % [where, body, l.get_theme_font_size("font_size") / pt, MIN_BODY])
	for s in [bubbles.LINE_SIZE, bubbles.SUB_SIZE]:
		if s < MIN_BODY:
			problems.append("%s: a speech bubble's text is %.0f pt" % [where, s])
	for s in [bubbles.NAME_SIZE, hud.T_LABEL]:
		if s < MIN_LABEL:
			problems.append("%s: a label is %.0f pt" % [where, s])
	if verbose:
		var parts := PackedStringArray()
		for k in rects:
			parts.append("%s %s" % [k, _pts(rects[k], pt)])
		print("  %s: %d targets · %s" % [where, targets.size(), " · ".join(parts)])


func _check_touch(where: String, r: Rect2, pt: float, safe: Rect2) -> void:
	if r.size.x < MIN_TOUCH * pt - 0.5 or r.size.y < MIN_TOUCH * pt - 0.5:
		problems.append("%s: %.0f x %.0f pt, under %.0f pt" % [where, r.size.x / pt, r.size.y / pt, MIN_TOUCH])
	if not safe.grow(0.5).encloses(r):
		problems.append("%s: %s is outside the safe area %s" % [where, _pts(r, pt), _pts(safe, pt)])


## Every visible label and button text under `node` is at least 11 pt.
func _check_fonts(node: Node, where: String, pt: float) -> void:
	for c in node.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		if (ctl is Label and (ctl as Label).text != "") or (ctl is Button and (ctl as Button).text != ""):
			var fs := ctl.get_theme_font_size("font_size")
			if fs < MIN_LABEL * pt - 0.5:
				problems.append("%s: '%s' is %.1f pt" % [where, ctl.get("text"), fs / pt])
			# The words on a button fit inside it (a label that isn't cut short on purpose).
			var button := _button_of(ctl)
			if ctl is Label and button != null and not (ctl as Label).clip_text:
				var w := ctl.get_theme_font("font").get_string_size((ctl as Label).text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				if w > button.size.x - 2.0:
					problems.append("%s: '%s' (%.0f pt) is wider than its button (%.0f pt)" % [where, (ctl as Label).text, w / pt, button.size.x / pt])


## The button a label sits on (two levels up: Button > words > Label), if any.
static func _button_of(c: Control) -> Button:
	var p := c.get_parent()
	if p != null and p.get_parent() is Button:
		return p.get_parent() as Button
	return null


static func _pts(r: Rect2, pt: float) -> String:
	return "(%.0f,%.0f %.0fx%.0f pt)" % [r.position.x / pt, r.position.y / pt, r.size.x / pt, r.size.y / pt]


## F's map ask (2026-11-16, map_track.gd; the minimal map 2026-11-17): a "?" for a First step not
## done is painted (not on the minimap), a tap on it tells the teaser and offers TRACK, which pins
## the step's place and the NEXT line shows it tracked (gold, ◆), a tap on NEXT looks at it; ticking
## the step takes the "?" away. A friend's dot (on the full map in any context) tapped: its name and
## line, ROUTE (its start becomes the pin) and DETAILS (the QUESTS screen on that questline), each a
## MIN_TOUCH target inside the safe area, clear of the note and of QUESTS.
func _check_map_track(hud: CanvasLayer, fm: Control, where: String, pt: float, safe: Rect2) -> void:
	where += " track"
	var mk: MapMarkers = hud.markers
	fm.set_next([], Vector2.INF)
	fm.set_book({"car": Vector2(10.0, 20.0)})
	await process_frame
	var picked: Array = []
	var on_pick := func(e: Dictionary) -> void: picked.append(e)
	fm.quest_picked.connect(on_pick)
	var tap := func(p: Vector2) -> void:
		fm.centre = p + Vector2(40.0, 40.0)
		fm.call("_place")
		var sp: Vector2 = fm.to_screen(p)
		for down in [true, false]:
			fm._input(_touch_ev(0, sp, down))
	# "?" marks.
	var at := Vector2(-250.0, -80.0)
	mk.put_all(MapTrack.OWNER, MapTrack.unknown_marks({}, {"garage": at}, {}))
	await process_frame
	var with_q := await _full_tris(hud, fm)
	mk.clear(MapTrack.OWNER)
	var without_q := await _full_tris(hud, fm)
	if with_q <= without_q:
		problems.append("%s: a \"?\" adds nothing to the full map's paint (%d, %d)" % [where, with_q, without_q])
	mk.put_all(MapTrack.OWNER, MapTrack.unknown_marks({}, {"garage": at}, {}))
	var mini_before := mk.shown(MapMarkers.Layer.UNKNOWN, MapMarkers.View.MINIMAP, MapMarkers.Context.FREE)["at"] as PackedVector2Array
	if not mini_before.is_empty():
		problems.append("%s: the \"?\" shows on the minimap" % where)
	tap.call(at)
	await process_frame
	var rs2: Dictionary = fm.rects()
	var note := fm.get("_note") as Control
	var teaser: Array = MapTrack.teaser("garage")
	var text := ((note.get_child(0) as VBoxContainer).get_child(0) as Label).text
	if not note.visible or not rs2.has("offer") or not (text == str(teaser[0]) or text == str(teaser[1])):
		problems.append("%s: a tap on the \"?\" did not tell the teaser and offer TRACK (note %s, offer %s, \"%s\")" % [where, note.visible, rs2.has("offer"), text])
	else:
		_check_touch(where + " offer", rs2["offer"], pt, safe)
		for k in ["note", "quests"]:
			if (rs2["offer"] as Rect2).intersects(rs2[k]) or (rs2["note"] as Rect2).intersects(rs2["quests"]):
				problems.append("%s: the TRACK offer or the note overlaps the %s" % [where, k])
		(fm.get("_offer") as Button).pressed.emit()
		await process_frame
		var nx := fm.get("_next") as Button
		if str(fm.quest_pick.get("id", "")) != "unknown_garage" or picked.is_empty() or picked.back()["id"] != "unknown_garage" or fm.quest_pick["at"] != at:
			problems.append("%s: TRACK on the \"?\" did not pin its place (%s)" % [where, fm.quest_pick])
		elif not nx.visible or not nx.text.begins_with("◆"):
			problems.append("%s: the NEXT line does not show the tracked \"?\" (%s)" % [where, nx.text])
		else:
			fm.centre = Vector2.ZERO
			nx.pressed.emit()
			if fm.centre.distance_to(at) > 1.0:
				problems.append("%s: a tap on the tracked NEXT line did not look at it" % where)
	# The step ticked: the "?" goes.
	mk.put_all(MapTrack.OWNER, MapTrack.unknown_marks({"fs_garage": 7}, {"garage": at}, {}))
	fm.quest_pick = {}
	var ticked := await _full_tris(hud, fm)
	if ticked != without_q:
		problems.append("%s: the \"?\" is still painted once its step is ticked (%d, want %d)" % [where, ticked, without_q])
	mk.clear(MapTrack.OWNER)
	# A friend's dot: the note, ROUTE and DETAILS.
	var dot := Vector2(220.0, 140.0)
	mk.put_all("stories", [{"layer": MapMarkers.Layer.STORY, "at": dot, "colour": Color.PURPLE, "group": "story",
			"extra": {"id": "rave", "name": "Sekretny rave pod mostem Poniatowskiego", "blurb": "Bas pod mostem, Lekti gra do rana", "small": false}}])
	fm.set_book({"car": Vector2(10.0, 20.0), "stories": [_story_fact("rave", dot)]})
	await process_frame
	tap.call(dot)
	await process_frame
	var rs3: Dictionary = fm.rects()
	if not rs3.has("note") or not rs3.has("offer") or not rs3.has("details"):
		problems.append("%s: a tap on a friend's dot did not show its line, ROUTE and DETAILS (%s)" % [where, rs3.keys()])
	else:
		for k in ["offer", "details"]:
			_check_touch(where + " dot " + k, rs3[k], pt, safe)
		var ks := ["note", "offer", "details", "quests", "close"]
		for i in ks.size():
			for j in range(i + 1, ks.size()):
				if (rs3[ks[i]] as Rect2).intersects(rs3[ks[j]]):
					problems.append("%s: the dot's %s and %s overlap" % [where, ks[i], ks[j]])
		_check_fonts(note, where + " dot", pt)
		(fm.get("_details") as Button).pressed.emit()
		await process_frame
		var scr: Control = fm.get("_screen")
		if not scr.visible or str(scr.picked().get("id", "")) != "story_rave":
			problems.append("%s: DETAILS did not open QUESTS on the questline (%s)" % [where, scr.picked().get("id", "")])
		fm.close_screen()
		tap.call(dot)
		await process_frame
		(fm.get("_offer") as Button).pressed.emit()
		await process_frame
		if str(fm.quest_pick.get("id", "")) != "start_rave" or fm.quest_pick.get("at", Vector2.INF) != dot:
			problems.append("%s: ROUTE on the dot did not pin the questline's start (%s)" % [where, fm.quest_pick])
	fm.quest_picked.disconnect(on_pick)
	mk.clear("stories")
	fm.quest_pick = {}
	fm.set_book({})
	await process_frame


## The full map's triangle count for one paint (its overlay draws in the HUD's batch).
func _full_tris(hud: CanvasLayer, fm: Control) -> int:
	var o: Control = fm.get("_overlay")
	var got := [-1]
	var read := func() -> void: got[0] = (hud.get("_tri_pts") as PackedVector2Array).size()
	o.draw.connect(read)
	o.queue_redraw()
	await process_frame
	await process_frame
	o.draw.disconnect(read)
	return got[0]


## The map's coach marks (hints.gd, 2026-11-17): QUESTS first (over its button), then a friend's dot
## (under the NEXT line), then the hold (bottom centre); each inside the safe area and clear of the
## buttons, gone when its thing is done or the QUESTS screen comes up, once each; none without hints.
func _check_map_coach(fm: Control, where: String, pt: float, safe: Rect2) -> void:
	where += " coach"
	var mk: MapMarkers = fm.markers
	var dot := Vector2(220.0, 140.0)
	mk.put_all("stories", [{"layer": MapMarkers.Layer.STORY, "at": dot, "colour": Color.PURPLE, "group": "story",
			"extra": {"id": "rave", "name": "Secret rave", "blurb": "Bass", "small": false}}])
	fm.set_next(["Znajdź i mrugnij: Bartek", "Find and flash: Bartek"], Vector2(100.0, 100.0))
	fm.set_book({"car": Vector2(10.0, 20.0), "stories": [_story_fact("rave", dot)]})
	fm.hints = Hints.new()
	await process_frame
	var clear_of := func(id: String, keys: Array) -> void:
		var rs: Dictionary = fm.rects()
		if not rs.has("coach"):
			problems.append("%s: no coach mark for %s" % [where, id])
			return
		if not safe.grow(0.5).encloses(rs["coach"]):
			problems.append("%s: the %s mark %s is outside the safe area" % [where, id, _pts(rs["coach"], pt)])
		for k in keys:
			if rs.has(k) and (rs["coach"] as Rect2).intersects(rs[k]):
				problems.append("%s: the %s mark covers the %s" % [where, id, k])
	fm.call("_process", 0.016)
	if fm.hints.coach != "map_quests":
		problems.append("%s: the first mark is %s (want map_quests)" % [where, fm.hints.coach])
	clear_of.call("QUESTS", ["quests", "next", "close"])
	for card: String in ["coach", "note"]:  # a tap goes through the map's cards (CI 2026-11-17: the ✕ under the mark)
		var stack: Array[Node] = [fm.get_node_or_null(card)]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is Control and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
				problems.append("%s: the %s card's %s takes taps meant for the map under it" % [where, card, n.get_class()])
			stack.append_array(n.get_children() if n != null else [])
	fm.open_screen()
	fm.call("_process", 0.016)
	if fm.rects().has("coach") or fm.hints.coach != "":
		problems.append("%s: a coach mark over the QUESTS screen (%s)" % [where, fm.hints.coach])
	fm.close_screen()
	fm.call("_process", 0.016)
	if fm.hints.coach != "map_pin":
		problems.append("%s: after QUESTS the mark is %s (want map_pin)" % [where, fm.hints.coach])
	clear_of.call("dot", ["quests", "next", "close"])
	fm.centre = dot + Vector2(40.0, 40.0)
	fm.call("_place")
	for down in [true, false]:
		fm._input(_touch_ev(0, fm.to_screen(dot), down))
	fm.call("_process", 0.016)
	if fm.hints.coach != "map_hold":
		problems.append("%s: a tapped dot did not bring the hold mark (%s)" % [where, fm.hints.coach])
	clear_of.call("hold", ["quests", "next", "close", "note", "offer", "details"])
	fm.call("_start_hold", 7, fm.get_viewport().get_visible_rect().size * 0.5)
	fm.call("_cancel_hold")
	fm.call("_process", 0.016)
	if fm.hints.coach != "" or fm.hints.seen.size() != 3 or not fm.hints.dirty:
		problems.append("%s: a hold did not end the coach marks (%s, seen %s)" % [where, fm.hints.coach, fm.hints.seen])
	fm.call("_process", 0.016)
	if fm.rects().has("coach"):
		problems.append("%s: a coach mark shows again once all three were seen" % where)
	var off := Hints.new()
	off.off = true
	fm.hints = off
	fm.call("_process", 0.016)
	if fm.rects().has("coach"):
		problems.append("%s: a coach mark shows in a run without hints" % where)
	fm.hints = null
	fm.call("_unselect")
	(fm.get("_note") as Control).visible = false
	mk.clear("stories")
	fm.set_next([], Vector2.INF)
	fm.set_book({})
	await process_frame
