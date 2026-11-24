extends SceneTree
## A card that waits for the player's answer is never left off the screen (F 2026-11-24: Darek's call
## rang on the 16 Pro Max and nothing showed: the invite and the night line under the caller's made it
## taller than the room above GAS, so the HUD's layout hid it while the ringtone went on). Each call,
## offer and quiz card below, in the game's longest words, in both control schemes, with and without
## the nitro, a quest's status line and a person's line in the dialogue panel, on four screens:
##   - the card is up, whole, inside the safe area;
##   - a call with no status line up is clear of everything on the phones without the nitro (not
##     `forced`), off the car's spot;
##   - a card that had to take the status line's place gives it back when it goes;
##   - the phone's clock is the game's.
##   godot --headless --path game --script res://tools/check_call_cards.gd -- --nosave

const Hud := preload("res://scripts/hud.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const SCREENS := [Vector2i(2868, 1320), Vector2i(2532, 1170), Vector2i(1920, 1080), Vector2i(1334, 750)]
## [caller, words]: Darek by day as F got it, Mati by day, a plain call.
const CALLS := [["Darek „Bawarka”|Darek \"Bawarka\"", "Kumpel od aut. O swojej Bawarce mówi „ona”.\nDziś wieczorem, o 21:00? Powiedz tak, a zegar przeskoczy.\nZaprasza: Nocny spot"],
		["Mati", "Kumpel z osiedla. Wie o imprezie, zanim powstała.\nDziś wieczorem, o 22:00? Powiedz tak, a zegar przeskoczy.\nZaprasza: Sekretny rave"],
		["Szymek", "Kumpel z przystani. Ma motorówkę i zero cierpliwości."]]
const OFFER := "„Słuchaj, Wyścig! Pan Zdzisiek wyciągnął Złotą Rybkę, Kamil swój skuter. Płyniemy z Portu Czerniakowskiego pod Śląsko-Dąbrowski, przez kółka. Trzy pudła i odpadasz. Wchodzisz?”"

var problems: Array[String] = []
var states := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	for screen: Vector2i in SCREENS:
		await _check_screen(screen)
	for p in problems:
		print("  PROBLEM " + p)
	print("check_call_cards: %s" % ("OK (%d states)" % states if problems.is_empty() else "%d problems" % problems.size()))
	quit(0 if problems.is_empty() else 1)


func _check_screen(screen: Vector2i) -> void:
	var vp := SubViewport.new()
	vp.size = screen
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	hud.local_clock = func() -> Dictionary: return {"hour": 21.1}
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	var bubbles: Control = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	hud.add_speech(bubbles)
	hud.set_radio_skip(true)
	await process_frame
	for n in 64:
		var scheme := n & 1
		var arrows := n & 2 != 0
		var nitro := n & 4 != 0
		var status := n & 8 != 0
		var talk := n & 16 != 0
		var left := n & 32 != 0
		for k in CALLS.size() + 2:
			hud.clear_all()
			bubbles.clear()
			hud.set_scheme(scheme)
			hud.set_arrows_layout(arrows)
			hud.set_left_handed(left)
			hud.set_nitro(nitro, 1.0, 2, false)
			bubbles.chatter.clock += 100.0
			if talk:
				bubbles.say(Vector3(100, 300, 0), "Mati", "Pierwsza linia, całkiem długa, o imprezie na Smolnej.", "A long first line.")
			if k < CALLS.size():
				hud.show_call(CALLS[k][0], CALLS[k][1], Color.RED, CALLS[k][1])
			elif k == CALLS.size():
				hud.show_side_card("SZYMEK", OFFER, PackedStringArray(["PŁYNĘ!|I'M IN", "NIE DZIŚ|NOT TODAY"]), Color.RED, "Szymek", OFFER, false, "Szymek")
			else:
				hud.show_card("BRAMKARZ · SELEKCJA 1/3", "„Kto dziś gra? Odpowiadaj spokojnie, nie patrz w telefon.”",
						PackedStringArray(["Lekti, oczywiście", "Nie wiem, ktoś znany", "Ja"]), Color.RED, false, "", "", true)
			if status:
				hud.show_status("SMOŁA · Smolna 38", "", "840 m", "Jedź do znaku", 0.0, Color.RED)
			for i in 3:
				await process_frame
			states += 1
			var at := "%dx%d scheme %d arrows %s nitro %s status %s talk %s left %s card %d" % [screen.x, screen.y, scheme, arrows, nitro, status, talk, left, k]
			var card: Control = hud._card
			if not card.is_visible_in_tree() or not hud.unplaced().is_empty():
				problems.append("%s: not on screen (%s)" % [at, hud.unplaced()])
				continue
			if not hud.safe_rect().grow(1.0).encloses(card.get_global_rect()):
				problems.append("%s: %s is outside the safe area" % [at, card.get_global_rect()])
			if k < CALLS.size():
				if not status and not nitro and (not hud.forced().is_empty() or card.get_global_rect().intersects(hud.car_zone())):
					problems.append("%s: the call covers something" % at)
				if hud._call_clock.text != "21:06":
					problems.append("%s: the phone's clock says %s" % [at, hud._call_clock.text])
			if status:
				hud.hide_card()
				for i in 2:
					await process_frame
				if not (hud._status as Control).visible:
					problems.append("%s: the status line did not come back" % at)
	vp.queue_free()
