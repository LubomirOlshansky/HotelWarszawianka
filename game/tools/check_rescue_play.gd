extends SceneTree
## The rescue line (scripts/missions.gd), played headless: the real Missions on the shared
## stand-ins of tools/fakes.gd (a HUD, a dialogue, a wallet) and a small city of its own (eight
## roads, six roofs, two hospitals, the Vistula's beaches, shore and sandbar, a park, a square),
## no map data. The first check that plays a rescue (tech-debt TD-1, step M0): it is the baseline
## the rescue line's move to the activity kit (M1) and the offer pacer (M2) are held to. Numbers
## and words are literals here; a call's place is read once from where its beacon stands
## (`target_position`) and judged by the rig's own data. Per fact, what the rescue line does:
##   A. what `setup` finds in the rig (the places of each kind, the peacock's roof, the hospitals);
##   B. the countdown: the first call, its three holds (`paused`, Spacer's `calls_off`, the guide's
##      `held`), the HUD's call gate, `ring_in`, `call_in`;
##   C. the ring: the WEZWANIE pill, the toast (with a pad too), waiting with no time limit;
##   D. the call card: its words, the distance and the compass, the hospital, the time; ACCEPT,
##      SKIP (the next call at once), LATER (the countdown at 90 s); refused while `paused`;
##   E. under way by car: the pickup's beacon, the status line and every hint, holding still in
##      the ring, the person's line, the drop-off, the pay, the score and the card;
##   F. by helicopter: a roof only it reaches, the too-high and off-the-ring hints, the stop spot;
##   G. the end without a rescue: the clock running out, the ✕, TRY AGAIN, NEXT CALL, FREE ROAM;
##   H. the calls: the kinds in their order, the same call for the same number, the nearest
##      hospital (the children's for a child), the line split by the vehicle, the peacock once,
##      the HELI list's two requests;
##   I. the police escort's `board` and `add_time`;  J. the keys (M and K);
##   K. the record of every session: each card, status line, toast and pill in order, then each
##      line said and each payment, hashed into the OK line, so two scripts that play the same
##      print the same line (`-- --trace` prints the record itself, one line each).
## Prints "check_rescue_play: OK (N facts; ...)" or one "  problem: ..." line per failed fact under
## "check_rescue_play: PROBLEMS" (exit 1).
##   godot --headless --path game --script res://tools/check_rescue_play.gd [-- --trace]

const Missions := preload("res://scripts/missions.gd")
const Fakes := preload("res://tools/fakes.gd")
const Lines := preload("res://scripts/quest_lines.gd")

## The rig's map: flat ground at 0 inside a 4 km square, with roofs over boxes.
class RescueMap extends Fakes.FlatMap:
	## The roofs: [Rect2 in plan, height] each.
	var roofs: Array = []

	func in_map(p: Vector2, pad := 0.0) -> bool:
		return Rect2(-2000.0, -2000.0, 4000.0, 4000.0).grow(pad).has_point(p)

	func roof_height(x: float, z: float) -> float:
		var best := roof_level
		for r: Array in roofs:
			if (r[0] as Rect2).has_point(Vector2(x, z)):
				best = maxf(best, float(r[1]))
		return best

	func top_height(x: float, z: float, radius := 0.0) -> float:
		var best := 0.0
		for r: Array in roofs:
			if (r[0] as Rect2).grow(radius).has_point(Vector2(x, z)):
				best = maxf(best, float(r[1]))
		return best


## The shared HUD with a record of everything the rescue line puts up and takes down, in order.
class RescueHud extends Fakes.Hud:
	var record: Array[String] = []

	func show_card(title: String, text: String, btn: PackedStringArray, a: Color, bottom := false, te := "", be := "", s := false) -> void:
		super.show_card(title, text, btn, a, bottom, te, be, s)
		record.append("card %s | %s | %s | %s | %s | %s" % [title, text, ",".join(btn), a.to_html(), te, be])

	func hide_card() -> void:
		super.hide_card()
		record.append("card down")

	func show_status(t: String, c: String, d: String, h: String, p: float, a: Color, b := "", i := {}, he := "") -> void:
		super.show_status(t, c, d, h, p, a, b, i, he)
		record.append("status %s | %s | %s | %s | %.3f | %s | %s" % [t, c, d, h, p, a.to_html(), he])

	func hide_status() -> void:
		super.hide_status()
		record.append("status down")

	func toast(a: String, b := "", _priority := 2) -> void:
		super.toast(a, b, _priority)
		record.append("toast %s | %s" % [a, b])

	func show_pill(pl: String, en := "", who := "call") -> void:
		super.show_pill(pl, en, who)
		record.append("pill %s | %s | %s" % [pl, en, who])

	func hide_pill() -> void:
		super.hide_pill()
		record.append("pill down")


const PLAYER := Vector3.ZERO
const DT := 0.1

var problems: Array[String] = []
var facts := 0
var hud: RescueHud
var dialogue: Fakes.Dialogue
var wallet: Fakes.Wallet
var map: RescueMap
var world: Node3D
var m: Node
var accepted := 0
## Every session's record (the HUD's calls, the lines said, the pay), for the digest the old and new
## scripts must share.
var trace: Array[String] = []


func _initialize() -> void:
	_run()


func _expect(ok: bool, what: String) -> void:
	facts += 1
	if not ok:
		problems.append(what)


## A square outline of `side` metres from its corner (x, z), as centrum.json's flat [x, z, ...].
func _box(x: float, z: float, side: float) -> Array:
	return [x, z, x + side, z, x + side, z + side, x, z + side, x, z]


func _data() -> Dictionary:
	return {
		"roads": [
			{"name": "Marszałkowska", "k": "primary", "p": [0.0, -800.0, 0.0, 800.0]},
			{"name": "Plac Zbawiciela", "k": "secondary", "p": [400.0, 200.0, 460.0, 200.0]},
			{"name": "Rondo ONZ", "k": "primary", "p": [-300.0, -300.0, -300.0, -360.0]},
			{"name": "Nowy Świat", "k": "secondary", "p": [700.0, -100.0, 700.0, 300.0]},
			{"name": "Nowy Świat", "k": "secondary", "p": [700.0, 500.0, 700.0, 520.0]},
			# Under the Pałac's roof in its middle: the spot moves along it to open sky.
			{"name": "Wspólna", "k": "tertiary", "p": [320.0, -500.0, 320.0, -300.0]},
			{"name": "", "k": "residential", "p": [100.0, 100.0, 200.0, 100.0]},
			{"name": "Dojazd", "k": "service", "p": [-100.0, -100.0, -100.0, -200.0]},
		],
		"landmarks": [
			{"name": "Pałac Testowy", "p": _box(300.0, -400.0, 40.0)},
			{"name": "Pałac Testowy", "p": _box(-900.0, -900.0, 40.0)},
			{"name": "Puro Hotel Testowy", "p": _box(-500.0, 300.0, 32.0)},
			{"name": "Kamienica Niska", "p": _box(600.0, 600.0, 24.0)},
			{"name": "Zamek Ujazdowski", "p": _box(450.0, 1600.0, 40.0)},
			{"name": "Wąska Wieża", "p": _box(-300.0, 900.0, 8.0)},
		],
		"pois": [
			{"k": "hospital", "name": "Szpital Testowy", "x": 800.0, "z": 0.0, "door": [810.0, 0.0]},
			{"k": "hospital", "name": "Szpital Dziecięcy", "x": -700.0, "z": -200.0, "door": [-700.0, -190.0]},
			{"k": "beach", "name": "Poniatówka", "x": 1200.0, "z": 400.0},
			{"k": "beach", "name": "", "x": 1300.0, "z": -200.0},
			{"k": "shore", "name": "", "x": 1100.0, "z": 900.0},
			{"k": "sandbar", "name": "", "x": 1500.0, "z": 0.0},
			{"k": "park", "name": "Park Testowy", "x": -600.0, "z": 500.0},
			{"k": "square", "name": "Plac Testowy", "x": -200.0, "z": 700.0},
			{"k": "kebab", "name": "Kebab u Testera", "x": 50.0, "z": 50.0},
			# Under the Pałac's roof: the spot moves out to open sky.
			{"k": "park", "name": "Park pod Dachem", "x": 310.0, "z": -390.0},
		],
	}


func _roofs() -> Array:
	return [[Rect2(300.0, -400.0, 40.0, 40.0), 60.0], [Rect2(-900.0, -900.0, 40.0, 40.0), 30.0],
			[Rect2(-500.0, 300.0, 32.0, 32.0), 30.0], [Rect2(600.0, 600.0, 24.0, 24.0), 10.0],
			[Rect2(450.0, 1600.0, 40.0, 40.0), 25.0], [Rect2(-300.0, 900.0, 8.0, 8.0), 40.0]]


## A fresh rescue line on a fresh HUD, dialogue and wallet (the first part builds the one the
## rest share; `fresh` starts again for a part that needs a session of its own).
func _fresh() -> void:
	if m != null:
		_keep_trace()
		m.queue_free()
		world.queue_free()
	accepted = 0
	hud = RescueHud.new()
	root.add_child(hud)
	dialogue = Fakes.Dialogue.new()
	root.add_child(dialogue)
	wallet = Fakes.Wallet.new()
	root.add_child(wallet)
	world = Node3D.new()
	root.add_child(world)
	m = Missions.new()
	root.add_child(m)
	await m.setup(map, _data(), world, hud)
	m.wallet = wallet
	m.dialogue = dialogue
	m.vehicle_anchor = func() -> Vector3: return Vector3(1, 2, 3)
	m.player = PLAYER
	m.accepted.connect(func() -> void: accepted += 1)


## Adds the session's record to `trace`: the HUD's calls in order, then each line said (key,
## speaker) and each payment.
func _keep_trace() -> void:
	trace.append("--- session")
	trace.append_array(hud.record)
	for i in dialogue.said.size():
		trace.append("said %s | %s" % [dialogue.said[i], dialogue.speakers[i]])
	for pay: Array in wallet.payments:
		trace.append("paid %s" % str(pay))


func _ticks(seconds: float, pos := PLAYER, speed := 0.0, flying := false) -> void:
	var n := roundi(seconds / DT)
	for i in n:
		m.tick(DT, pos, speed, flying)


## Stands still at `at` until the hold is done (HOLD_TIME and one tick more), by car or in the air.
func _hold_at(at: Vector3, flying := false) -> void:
	_ticks(Missions.HOLD_TIME + 0.2, at, 0.0, flying)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clock(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%d:%02d" % [s / 60, s % 60]


func _pickup() -> Node3D:
	return world.get_child(0) as Node3D


func _dropoff() -> Node3D:
	return world.get_child(1) as Node3D


func _run() -> void:
	await process_frame
	map = RescueMap.new()
	map.roofs = _roofs()
	root.add_child(map)
	await _fresh()
	_setup_facts()
	_countdown()
	_ring_facts()
	_offer_facts()
	_car_run()
	await _fresh()
	_heli_run()
	await _fresh()
	_ends()
	await _fresh()
	_calls()
	await _fresh()
	_escort()
	await _fresh()
	_keys()
	_keep_trace()
	var digest := "\n".join(trace).sha256_text().left(12)
	if OS.get_cmdline_user_args().has("--trace"):
		for line in trace:
			print("  trace: " + line)
	if problems.is_empty():
		print("check_rescue_play: OK (%d facts; the record of every session %d entries, %s)" % [facts, trace.size(), digest])
		quit(0)
	else:
		print("check_rescue_play: PROBLEMS")
		for p in problems:
			print("  problem: " + p)
		quit(1)


# --- A. what setup finds --------------------------------------------------------------------------

func _setup_facts() -> void:
	_expect(world.get_child_count() == 2, "A setup puts two beacons in the world (the pickup, the drop-off): %d" % world.get_child_count())
	_expect(not _pickup().visible and not _dropoff().visible, "A the beacons start out of sight")
	_expect(int(m.state) == Missions.State.IDLE, "A the line starts IDLE before the game's quiet start: %d" % int(m.state))
	_expect(m.can_request() == false, "A no request before the quiet start (IDLE)")
	_expect(m.peacock_open(), "A the peacock sits on Zamek Ujazdowski's roof (the first of the peacock roofs mapped)")
	_expect(not m.call_needs_heli(), "A no call, none that needs the helicopter")
	_expect(not m.has_target(), "A no target before a call")


# --- B. the countdown ------------------------------------------------------------------------------

func _countdown() -> void:
	m.quiet_start(5.0)
	_expect(int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), 5.0), "B quiet_start(5) closes and counts 5 s: %d %.1f" % [int(m.state), m.call_in()])
	_expect(m.can_request(), "B a request may be made while counting down")
	_expect(hud.pill == "", "B nothing on the pill while counting down")
	m.paused = true
	_ticks(10.0)
	_expect(is_equal_approx(m.call_in(), 5.0) and hud.pill == "", "B paused: the countdown stands at 5 s: %.1f" % m.call_in())
	_expect(not m.can_request(), "B paused: no request")
	m.paused = false
	m.calls_off = true
	_ticks(10.0)
	_expect(is_equal_approx(m.call_in(), 5.0), "B Spacer's calls_off: the countdown stands: %.1f" % m.call_in())
	_expect(not m.can_request(), "B calls_off: no request")
	m.calls_off = false
	m.held = true
	_ticks(10.0)
	_expect(is_equal_approx(m.call_in(), 5.0), "B the guide's hold: the countdown stands: %.1f" % m.call_in())
	_expect(not m.can_request(), "B held: no request")
	m.held = false
	_ticks(2.0)
	_expect(absf(m.call_in() - 3.0) < 0.05, "B free: 2 s off the countdown: %.2f" % m.call_in())
	hud.calls_ok = false
	_ticks(4.0)
	_expect(is_equal_approx(m.call_in(), 0.0) and int(m.state) == Missions.State.CLOSED and hud.pill == "",
			"B the HUD's gate shut: the call waits at zero, no ring: %.2f %d" % [m.call_in(), int(m.state)])
	_expect(m.ring_in(30.0) and is_equal_approx(m.call_in(), 30.0), "B ring_in(30) from CLOSED sets the countdown: %.1f" % m.call_in())
	m.ring_in(0.3)
	hud.calls_ok = true


# --- C. the ring ---------------------------------------------------------------------------------

func _ring_facts() -> void:
	var toasts := hud.toasts.size()
	_ticks(0.5)
	_expect(int(m.state) == Missions.State.RINGING, "C the call rings once the countdown passes zero and the gate is open: %d" % int(m.state))
	_expect(hud.pill_word == "WEZWANIE" and hud.pill_en == "rescue call" and hud.pill == "call",
			"C the pill: WEZWANIE / rescue call, as the call's: %s %s %s" % [hud.pill_word, hud.pill_en, hud.pill])
	_expect(hud.toasts.size() == toasts + 1 and hud.toasts[-1] == "Wezwanie ratunkowe!"
			and hud.toasts_en[-1] == "A rescue call came in: tap the button at the top.", "C the toast, without a pad: %s" % str(hud.toasts.slice(toasts)))
	_expect(not m.ring_in(10.0), "C ring_in refused while ringing")
	_expect(m.can_request(), "C a request may be made while ringing")
	_ticks(120.0)
	_expect(int(m.state) == Missions.State.RINGING and hud.pill_word == "WEZWANIE", "C the pill waits with no time limit (2 min)")
	_expect(hud.card == "", "C no card while ringing")


# --- D. the call card ------------------------------------------------------------------------------

func _offer_facts() -> void:
	hud.pill_pressed.emit()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 1, "D the pill's tap offers call 1: %d %d" % [int(m.state), m.number])
	_expect(hud.pill == "" and hud.pills_hidden > 0, "D the pill goes with the card")
	_expect(hud.card.begins_with("WEZWANIE 1 · RATUNEK NA ULICY"), "D call 1 is a street rescue: %s" % hud.card)
	_expect(hud.card_en == "Call 1 · street rescue", "D its English title: %s" % hud.card_en)
	_expect(hud.button_words == PackedStringArray(["ACCEPT", "SKIP", "LATER"]), "D ACCEPT / SKIP / LATER: %s" % str(hud.button_words))
	_expect(hud.accent == Missions.PICKUP_COLOUR, "D the card in the pickup's amber")
	_expect(hud.body.contains("Ranny rowerzysta:") and hud.body.contains("Szpital: Szpital Testowy"),
			"D the body: the cyclist and the nearest adults' hospital: %s" % hud.body)
	_expect(hud.body_en.begins_with("A cyclist is hurt: the car or the helicopter will do. About ") and hud.body_en.contains("Get them to the hospital in"),
			"D the English body: %s" % hud.body_en)
	_expect(not m.has_target() and not _pickup().visible, "D no target, no beacon on the card")
	var first := hud.body
	hud.press(1)
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2 and hud.card.begins_with("WEZWANIE 2 · RATUNEK NA DACHU"),
			"D SKIP: call 2 at once, a roof: %s" % hud.card)
	_expect(hud.body.contains("Paw uciekł z Łazienek") and hud.body.contains("Zamek Ujazdowski"),
			"D call 2 is the peacock (a roof call within its reach while it waits): %s" % hud.body)
	hud.press(2)
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "" and is_equal_approx(m.call_in(), Missions.NEXT_CALL),
			"D LATER: closed, the next call in 90 s: %d %.1f" % [int(m.state), m.call_in()])
	m.paused = true
	m.offer(3)
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "", "D no offer while paused")
	m.paused = false
	m.offer(1)
	_expect(hud.body == first, "D the same call for the same number from the same place: %s" % hud.body)


# --- E. under way by car ---------------------------------------------------------------------------

func _car_run() -> void:
	var toasts := hud.toasts.size()
	var said := dialogue.said.size()
	hud.press(0)
	_expect(int(m.state) == Missions.State.PICKUP and m.has_target() and accepted == 1, "E ACCEPT: the pickup, a target, `accepted` once: %d %d" % [int(m.state), accepted])
	_expect(hud.card == "" and hud.toasts[-1] == "Jedziemy! Autem albo helikopterem." and hud.toasts_en[-1] == "Go! Car or helicopter.",
			"E the card goes, the toast: %s" % str(hud.toasts.slice(toasts)))
	var at: Vector3 = m.target_position()
	var streets := {"Plac Zbawiciela": Vector3(430, 0, 200), "Rondo ONZ": Vector3(-300, 0, -330), "Nowy Świat": Vector3(700, 0, 100),
			"Wspólna": Vector3(320, 0, -406)}
	var street := ""
	for s: String in streets:
		if _flat(streets[s], at) < 0.5:
			street = s
	_expect(street != "", "E the person waits on one of the four named streets 150 m to 1.1 km off, at its open middle: %s" % at)
	_expect(_pickup().visible and _flat(_pickup().position, at) < 0.01, "E the pickup's beacon stands at the person: %s" % _pickup().position)
	_expect(m.target_colour() == Missions.PICKUP_COLOUR and m.stop_spot() == at and not m.needs_heli(),
			"E a car's pickup: amber, the stop assist's spot is the person, no helicopter needed")
	var hosp := Vector3(810, 0, 0)
	var limit := ceilf((35.0 + (_flat(PLAYER, at) + _flat(at, hosp)) / 9.5) / 5.0) * 5.0
	m.tick(DT, PLAYER, 0.0, false)
	_expect(hud.status_title == "ODBIÓR · " + street, "E the status line: ODBIÓR · the street: %s" % hud.status_title)
	_expect(hud.count == _clock(limit - DT), "E the clock: the fair time %s less a tick: %s" % [_clock(limit), hud.count])
	_expect(hud.distance == "%d m" % roundi(_flat(PLAYER, at)), "E the metres to the person: %s" % hud.distance)
	_expect(hud.status == "Jedź do żółtego światła" and hud.hint_en == "Head for the yellow beacon", "E far off: head for the yellow beacon: %s" % hud.status)
	_expect(hud.tint == Missions.PICKUP_COLOUR, "E the line in amber")
	var near := at + Vector3(20, 0, 0)
	m.tick(DT, near, 0.0, false)
	_expect(hud.status == "Stań w kręgu" and hud.hint_en == "Stop inside the ring", "E within 40 m, outside the ring: stop inside it: %s" % hud.status)
	m.tick(DT, at + Vector3(5, 0, 0), Missions.CAR_STOPPED + 1.0, false)
	_expect(hud.status == "Stań, żeby ich zabrać" and hud.hint_en == "Stop to pick them up", "E in the ring too fast: stop: %s" % hud.status)
	m.tick(DT, at + Vector3(5, 0, 0), 0.0, false)
	_expect(hud.status == "Nie ruszaj się… zabieramy" and absf(hud.progress - DT / Missions.HOLD_TIME) < 0.01, "E stopped in the ring: hold still, the bar fills: %s %.3f" % [hud.status, hud.progress])
	m.tick(DT, at + Vector3(5, 0, 0), Missions.CAR_STOPPED + 1.0, false)
	_expect(is_equal_approx(hud.progress, 0.0), "E moving again starts the hold over: %.3f" % hud.progress)
	m.tick(DT, at + Vector3(0, 3.0, 0), 0.0, false)
	_expect(hud.status != "Nie ruszaj się… zabieramy", "E 3 m above the person (a bridge) is no pickup: %s" % hud.status)
	_hold_at(at)
	_expect(int(m.state) == Missions.State.DROPOFF, "E held still 1.5 s: picked up: %d" % int(m.state))
	_expect(hud.toasts[-1] == "Zabrani! Teraz: Szpital Testowy" and hud.toasts_en[-1] == "Picked up! Now to Szpital Testowy", "E the toast names the hospital: %s" % hud.toasts[-1])
	_expect(not _pickup().visible and _dropoff().visible and _flat(_dropoff().position, hosp) < 0.01, "E the pickup's beacon goes, the drop-off's stands at the hospital's open door")
	_expect(dialogue.said.size() == said + 1 and dialogue.said[-1] == "rescue_person:street", "E the person's line, a street one: %s" % str(dialogue.said.slice(said)))
	_expect(dialogue.speakers[-1] in Missions.NAMES and dialogue.anchors[-1] is Callable, "E said by a grown-up's name at the vehicle: %s" % dialogue.speakers[-1])
	_expect(m.target_position() == hosp and m.stop_spot() == hosp and m.target_colour() == Missions.DROPOFF_COLOUR, "E the target is the hospital now, in green")
	m.tick(DT, at, 0.0, false)
	_expect(hud.status_title == "DO SZPITALA · Szpital Testowy" and hud.status == "Pacjent na pokładzie: do zielonego światła",
			"E the status line to the hospital: %s / %s" % [hud.status_title, hud.status])
	_expect(hud.tint == Missions.DROPOFF_COLOUR, "E the line in green")
	m.tick(DT, hosp + Vector3(3, 0, 0), Missions.CAR_STOPPED + 2.0, false)
	_expect(hud.status == "Stań, żeby ich przekazać" and hud.hint_en == "Stop to hand them over", "E at the door too fast: stop to hand over: %s" % hud.status)
	_hold_at(hosp)
	_expect(int(m.state) == Missions.State.RESULT, "E held still at the door: rescued: %d" % int(m.state))
	var route := _flat(at, hosp)
	# The clock ran from ACCEPT for 40 ticks: six single ones, the pickup's hold of 17, two more, and
	# the door's hold, done on its 15th (1.5 s).
	var left := limit - DT * (6 + 17 + 2 + 15)
	var score := 500 + int(left) * 10 + int(route / 4.0)
	var pay := roundi(score * 0.08)
	_expect(m.total_score == score, "E the score: 500, 10 a second left, a point per 4 m of the trip: %d (%d)" % [m.total_score, score])
	_expect(wallet.payments.size() == 1 and wallet.payments[0] == [pay, 40, "rescue"], "E the pay: 8 %% of the score, 40 respect, a rescue: %s (%d)" % [str(wallet.payments), pay])
	_expect(hud.card == "URATOWANI" and hud.button_words == PackedStringArray(["NEXT CALL", "FREE ROAM"]) and hud.card_en == "Rescued",
			"E the card: URATOWANI, NEXT CALL / FREE ROAM: %s %s" % [hud.card, str(hud.button_words)])
	_expect(hud.body == "Cali i zdrowi: Szpital Testowy.\nCzas %s z %s · punkty +%d (razem %d) · +%d zł" % [_clock(limit - left), _clock(limit), score, score, pay],
			"E its body: the time, the score, the pay: %s" % hud.body)
	_expect(hud.accent == Missions.DROPOFF_COLOUR and hud.status_title == "", "E the card green, the status line down")
	_expect(dialogue.said[-1] == "rescue_done:" and dialogue.speakers[-1] == "Ratownik" and dialogue.anchors[-1] == _dropoff(),
			"E the crew's line at the hospital: %s %s" % [dialogue.said[-1], dialogue.speakers[-1]])
	_expect(_dropoff().visible and _pickup().visible and _flat(_pickup().position, hosp + Vector3(1.6, 0, 0.8)) < 0.01,
			"E the patient stands with the crew beside the door")
	_expect(not m.has_target(), "E no target on the result card")
	hud.press(1)
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "" and is_equal_approx(m.call_in(), Missions.NEXT_CALL) and not _pickup().visible,
			"E FREE ROAM: closed, the next call in 90 s, the beacons go: %d %.1f" % [int(m.state), m.call_in()])


# --- F. by helicopter --------------------------------------------------------------------------------

func _heli_run() -> void:
	m.quiet_start(1.0)
	m.request_peacock()
	_expect(int(m.state) == Missions.State.OFFER and hud.card.begins_with("WEZWANIE 1 · RATUNEK NA DACHU") and hud.body.contains("Paw uciekł"),
			"F the HELI list's peacock: its roof call on the card at once: %s" % hud.card)
	_expect(m.call_needs_heli(), "F a call on the card that only the helicopter reaches")
	hud.press(0)
	_expect(hud.toasts[-1] == "Jedziemy! Tylko helikopterem." and hud.toasts_en[-1] == "Go! Take the helicopter.", "F the toast: the helicopter only: %s" % hud.toasts[-1])
	var at: Vector3 = m.target_position()
	_expect(Rect2(450.0, 1600.0, 40.0, 40.0).has_point(Vector2(at.x, at.z)) and is_equal_approx(at.y, 25.0), "F the peacock on Zamek Ujazdowski's roof, 25 m up: %s" % at)
	_expect(m.needs_heli() and m.stop_spot() == Vector3.INF and m.target_colour() == Lines.HELI_COLOUR, "F needs the helicopter, no stop spot, the HELI violet")
	m.tick(DT, PLAYER, 0.0, false)
	_expect(hud.status == "Tam dotrze tylko helikopter: HELI (H)" and hud.hint_en == "Only the helicopter gets there: press HELI (H)",
			"F by car: only the helicopter gets there: %s" % hud.status)
	_expect(hud.status_title == "ODBIÓR · paw na dachu: Zamek Ujazdowski", "F the status line: %s" % hud.status_title)
	m.tick(DT, at + Vector3(0, 10, 0), 0.0, true)
	_expect(hud.status == "Niżej: do 4 m nad nimi (▼ / F)", "F 10 m over them: go down: %s" % hud.status)
	m.tick(DT, at + Vector3(12, 2, 0), 0.0, true)
	_expect(hud.status == "Leć nad krąg" and hud.hint_en == "Move over the ring", "F low, 12 m off: move over the ring: %s" % hud.status)
	m.tick(DT, at + Vector3(3, -2, 0), 0.0, true)
	_expect(hud.status == "" and is_equal_approx(hud.progress, 0.0), "F 2 m under the roof's top, 3 m off: no pickup, no hint: %s" % hud.status)
	_hold_at(at + Vector3(3, 2, 0), true)
	_expect(int(m.state) == Missions.State.DROPOFF and dialogue.said[-1] == "rescue_person:peacock" and dialogue.speakers[-1] == "Pan Paw",
			"F hovering 2 m over them 1.5 s: aboard; Pan Paw's own line: %s %s" % [dialogue.said[-1], dialogue.speakers[-1]])
	var hosp: Vector3 = m.target_position()
	_expect(_flat(hosp, Vector3(810, 0, 0)) < 0.01, "F the peacock goes to the adults' hospital (it is no child)")
	_hold_at(hosp)
	_expect(int(m.state) == Missions.State.RESULT and not m.peacock_open() and dialogue.said[-1] == "rescue_done:peacock",
			"F rescued: the peacock is done for the session, the crew's peacock line: %s" % dialogue.said[-1])
	hud.press(0)
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2 and hud.card.begins_with("WEZWANIE 2 · RATUNEK NA DACHU") and not hud.body.contains("Paw"),
			"F NEXT CALL: call 2, a roof again, no peacock now: %s / %s" % [hud.card, hud.body])
	_expect(hud.body.contains("Pałac Testowy") or hud.body.contains("Hotel Piure") or hud.body.contains("Zamek Ujazdowski"),
			"F a roof rescue on one of the three roofs 20 m up or more: %s" % hud.body)
	_expect(not hud.body.contains("Puro"), "F the Puro roof shows as the parody Hotel Piure")
	_expect(not hud.body.contains("Kamienica Niska") and not hud.body.contains("Wąska Wieża"), "F no rescue on a roof under 20 m or with no flat spot")


# --- G. the end without a rescue ---------------------------------------------------------------------

func _ends() -> void:
	m.quiet_start(1.0)
	m.offer(1)
	hud.press(0)
	var at: Vector3 = m.target_position()
	var limit := ceilf((35.0 + (_flat(PLAYER, at) + _flat(at, Vector3(810, 0, 0))) / 9.5) / 5.0) * 5.0
	_ticks(limit - 1.0)
	_expect(int(m.state) == Missions.State.PICKUP, "G a second before the clock runs out the call is on")
	_ticks(1.5)
	_expect(int(m.state) == Missions.State.RESULT and hud.card == "ZA PÓŹNO" and hud.card_en == "Too late", "G out of time: ZA PÓŹNO: %s" % hud.card)
	_expect(hud.body == "Czas minął. Przejęła inna załoga. Punkty razem: 0." and hud.body_en == "Out of time. Another crew took over. Score total 0.",
			"G its words: %s / %s" % [hud.body, hud.body_en])
	_expect(hud.button_words == PackedStringArray(["TRY AGAIN", "NEXT CALL", "FREE ROAM"]) and hud.accent == Missions.FAIL_COLOUR, "G TRY AGAIN / NEXT CALL / FREE ROAM, in red")
	_expect(not _pickup().visible and not _dropoff().visible and wallet.payments.is_empty(), "G no beacons, no pay")
	hud.press(0)
	_expect(int(m.state) == Missions.State.PICKUP and m.target_position() == at and accepted == 2, "G TRY AGAIN: the same call, accepted again")
	m.tick(DT, PLAYER, 0.0, false)
	_expect(hud.count == _clock(limit - DT), "G timed from here: the full time again: %s" % hud.count)
	hud.abort_pressed.emit()
	_expect(int(m.state) == Missions.State.RESULT and hud.card == "ZA PÓŹNO" and hud.body.begins_with("Akcja odwołana.") and hud.body_en.begins_with("You called the rescue off."),
			"G the ✕: called off: %s" % hud.body)
	hud.press(1)
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2, "G NEXT CALL: call 2 on the card")
	hud.press(2)
	_expect(int(m.state) == Missions.State.CLOSED, "G LATER")
	hud.abort_pressed.emit()
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "", "G the ✕ with no call does nothing")
	m.offer(3)
	hud.press(0)
	hud.abort_pressed.emit()
	hud.press(2)
	_expect(int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), Missions.NEXT_CALL), "G FREE ROAM after a failure: closed, 90 s")


# --- H. the calls ----------------------------------------------------------------------------------

func _calls() -> void:
	m.quiet_start(1.0)
	var titles := []
	for n in range(1, 9):
		m.offer(n)
		titles.append(hud.card.get_slice(" · ", 1))
	_expect(titles == ["RATUNEK NA ULICY", "RATUNEK NA DACHU", "RATUNEK NAD WISŁĄ", "RATUNEK W PARKU",
			"RATUNEK NA ULICY", "RATUNEK NA DACHU", "RATUNEK NAD WISŁĄ", "RATUNEK W PARKU"], "H the kinds go street, roof, river, park: %s" % str(titles))
	m.offer(3)
	hud.press(0)
	var river: Vector3 = m.target_position()
	_expect(_flat(river, Vector3(1200, 0, 400)) < 0.5 or _flat(river, Vector3(1300, 0, -200)) < 0.5 or _flat(river, Vector3(1100, 0, 900)) < 0.5,
			"H a river call with nothing in 1.1 km: one of the three nearest (the beaches and the shore, not the sandbar): %s" % river)
	hud.abort_pressed.emit()
	hud.press(2)
	m.offer(4)
	var child := hud.body.contains("Dziecko spadło")
	hud.press(0)
	var park: Vector3 = m.target_position()
	_hold_at(park)
	var hosp: Vector3 = m.target_position()
	if child:
		_expect(_flat(hosp, Vector3(-700, 0, -190)) < 0.01 and dialogue.said[-1] == "rescue_person:child" and dialogue.speakers[-1] in Missions.KIDS,
				"H a child goes to the children's hospital, a child's name and line: %s %s" % [dialogue.said[-1], dialogue.speakers[-1]])
	else:
		_expect(_flat(hosp, Vector3(810, 0, 0)) < 0.01 and dialogue.said[-1] == "rescue_person:square", "H a fainted tourist goes to the adults' hospital: %s" % dialogue.said[-1])
	hud.abort_pressed.emit()
	hud.press(2)
	# The line split (G12): flying, a street call becomes a roof call; driving, a roof call a park call.
	m.line_split = true
	m.tick(DT, PLAYER, 0.0, true)
	m.offer(5)
	_expect(hud.card.contains("RATUNEK NA DACHU"), "H split, flying: call 5 (a street) is a roof call: %s" % hud.card)
	m.tick(DT, PLAYER, 0.0, false)
	m.offer(6)
	_expect(hud.card.contains("RATUNEK W PARKU"), "H split, driving: call 6 (a roof) is a park call: %s" % hud.card)
	m.offer(7)
	_expect(hud.card.contains("RATUNEK NAD WISŁĄ") and not hud.body.contains("łasze"), "H split, driving: a river call off the sandbar: %s" % hud.body)
	m.tick(DT, PLAYER, 0.0, true)
	m.offer(7)
	_expect(hud.body.contains("łasze"), "H split, flying: the river call is the sandbar, the helicopter's: %s" % hud.body)
	m.line_split = false
	hud.press(2)
	m.tick(DT, PLAYER, 0.0, false)
	m.request_call(true)
	_expect(int(m.state) == Missions.State.OFFER and m.call_needs_heli(), "H the HELI list's rescue call: one only the helicopter reaches, on the card at once: %s" % hud.body)
	hud.press(2)
	m.paused = true
	m.request_call(true)
	_expect(int(m.state) == Missions.State.CLOSED, "H no request while paused")
	m.paused = false


# --- I. the police escort -------------------------------------------------------------------------------

func _escort() -> void:
	m.quiet_start(1.0)
	m.add_time(10.0)
	m.offer(1)
	hud.press(0)
	m.tick(DT, PLAYER, 0.0, false)
	var before := hud.count
	m.add_time(10.0)
	m.tick(DT, PLAYER, 0.0, false)
	_expect(hud.count != before and m.has_target(), "I add_time: the escort's seconds on the clock: %s then %s" % [before, hud.count])
	m.board()
	_expect(int(m.state) == Missions.State.DROPOFF and dialogue.said[-1] == "rescue_person:street", "I board: the person is aboard at once (--escort)")
	m.board()
	_expect(int(m.state) == Missions.State.DROPOFF, "I board again does nothing")
	hud.abort_pressed.emit()
	hud.press(2)
	m.offer(2)
	hud.press(0)
	m.board()
	_expect(int(m.state) == Missions.State.PICKUP, "I board does nothing for a helicopter's pickup")


# --- J. the keys ---------------------------------------------------------------------------------------

func _keys() -> void:
	m.quiet_start(1.0)
	m.primary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 1, "J M while counting down: the next call's card")
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2, "J K on a card: SKIP")
	m.primary()
	_expect(int(m.state) == Missions.State.PICKUP, "J M on a card: ACCEPT")
	m.secondary()
	m.primary()
	_expect(int(m.state) == Missions.State.PICKUP, "J the keys do nothing under way")
	hud.abort_pressed.emit()
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 3, "J K on a failure's card: NEXT CALL")
	m.paused = true
	m.primary()
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 3, "J the keys do nothing while paused")
	m.paused = false
	hud.press(2)
	_ticks(Missions.NEXT_CALL + 0.5)
	_expect(int(m.state) == Missions.State.RINGING, "J 90 s after LATER the next call rings")
	m.primary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 4, "J M while ringing: the call's card")
	hud.pad_mode = true
	hud.press(2)
	m.ring_in(0.05)
	_ticks(0.2)
	_expect(hud.toasts[-1].begins_with("Wezwanie ratunkowe! ") and hud.toasts[-1].ends_with(": odbierz."), "J with a pad the toast names its button: %s" % hud.toasts[-1])
