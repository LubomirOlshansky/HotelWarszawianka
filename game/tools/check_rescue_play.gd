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
##   K. the edges in exact numbers: the countdown's arguments and its zero, the haptic engine's start two
##      seconds before a ring, the door of the hospital by car and by helicopter (13 and 40 m, 6 m/s, 2.5 m up;
##      8 m, 4 m up, 1 m down), the hold in quarter seconds, a broken-off hold, the clock at exactly zero;
##   L. the words of every kind in both languages (a street, a roof under its parody name, a named and an
##      unnamed beach, the shore, a sandbar, a park, a square), the status line's place, the person's line
##      and the failure card on the way;
##   M. which place, which hospital, which roof: calls 1 to 8 from two starts, the 150 m and 1,100 m edges of
##      a call's reach and the three nearest, the street person's open spot (6 m steps, 4.5 m of open sky, 1.5 m
##      of height, 40 m from the map's edge, bent, doubled and shut-in roads), roofs (20 m up, the highest of two
##      outlines, flat to a metre, three corners), the peacock (its four roofs in order, the nearest roof
##      within 700 m of its anchor, 2,600 m of reach), the hospital (the nearest, the first of two as near,
##      the first when only children's are left), the open spot of a door (40 m) and of a beach (24 m), the
##      nearest road's name, and every name a person can have;
##   N. the rest: `start`, the beacons going with a call put away, the HELI list's requests asked once, `tick`
##      keeping the player, `ring_in` from IDLE, K on a success, Spacer's rescue without a clock, the fair
##      time to the second (by car and by helicopter with its climb), the eight compass words, colour-safe;
##   O. the record of every session: each card, status line, toast and pill in order, each with both beacons
##      (where, shown, waving, ring pattern, colours, ring radius, the person's clothes) and the haptics' last
##      buzz; then each line said (how, where) and each payment, hashed into the OK line, so two scripts that
##      play the same print the same line (`-- --trace` prints the record itself, one line each).
## Words that no player can read (a place's English `text`, its `short`, the log lines) are not checked: the
## deliberate-break run lists them, each with its reason (the M0 report).
## Prints "check_rescue_play: OK (N facts; ...)" or one "  problem: ..." line per failed fact under
## "check_rescue_play: PROBLEMS" (exit 1).
##   godot --headless --path game --script res://tools/check_rescue_play.gd [-- --trace]

const Missions := preload("res://scripts/missions.gd")
const Fakes := preload("res://tools/fakes.gd")
const Haptics := preload("res://scripts/haptics.gd")
const Access := preload("res://scripts/access.gd")

## The colours the rescue line shows, as literals: the pickup's amber, the drop-off's green (blue under
## colour-safe), the failure's red, the helicopter-only violet.
const AMBER := Color("#ffc23a")
const GREEN := Color("#56d68a")
const BLUE := Color("#4aa3ff")
const RED := Color("#e2574c")
const VIOLET := Color("#b48cff")
## Who needs rescuing: the grown-ups' and the children's first names, as the game words them.
const NAMES: Array[String] = ["Ania", "Kuba", "Ola", "Tomek", "Zosia", "Bartek", "Magda", "Piotrek", "Ewa", "Marek"]
const KIDS: Array[String] = ["Staś", "Zuzia", "Antek", "Hania"]

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


## The HUD's message director (hud-messages.md): counts the rescue calls that rang through it.
class RescueMessages extends RefCounted:
	var calls := 0

	func call_rang() -> void:
		calls += 1


## The shared HUD with a record of everything the rescue line puts up and takes down, in order, each
## entry with the two beacons as they stand then (`snap`).
class RescueHud extends Fakes.Hud:
	var record: Array[String] = []
	## The world the two beacons stand in (child 0 the pickup's, child 1 the drop-off's).
	var world: Node3D
	## The message director the rescue line tells when a call rings (`hud.get("messages")`).
	var messages := RescueMessages.new()

	func show_card(title: String, text: String, btn: PackedStringArray, a: Color, bottom := false, te := "", be := "", s := false) -> void:
		super.show_card(title, text, btn, a, bottom, te, be, s)
		record.append("card %s | %s | %s | %s | %s | %s | %s" % [title, text, ",".join(btn), a.to_html(), te, be, snap()])

	func hide_card() -> void:
		super.hide_card()
		record.append("card down | " + snap())

	func show_status(t: String, c: String, d: String, h: String, p: float, a: Color, b := "", i := {}, he := "") -> void:
		super.show_status(t, c, d, h, p, a, b, i, he)
		record.append("status %s | %s | %s | %s | %.3f | %s | %s | %s" % [t, c, d, h, p, a.to_html(), he, snap()])

	func hide_status() -> void:
		super.hide_status()
		record.append("status down | " + snap())

	func toast(a: String, b := "", _priority := 2) -> void:
		super.toast(a, b, _priority)
		record.append("toast %s | %s | %s" % [a, b, snap()])

	func show_pill(pl: String, en := "", who := "call") -> void:
		super.show_pill(pl, en, who)
		record.append("pill %s | %s | %s | rings %d" % [pl, en, who, messages.calls])

	func hide_pill() -> void:
		super.hide_pill()
		record.append("pill down")

	## Both beacons: where they stand, whether they show, how (waving, ring pattern, colour as set and as
	## seen, the ring's radius, the ring, the column and the person), the colours of the person's clothes; then
	## the haptics' count and last buzz. The haptics' clock rules are wound back after every look, so the
	## record does not depend on how fast the check runs (a buzz close behind another is not dropped).
	func snap() -> String:
		var out := PackedStringArray()
		if world != null and world.get_child_count() >= 2:
			for i in 2:
				var b := world.get_child(i) as Node3D
				var clothes := PackedStringArray()
				var person := b.get("_person") as Node3D
				var arm := b.get("_arm") as Node3D
				for part: Node in person.get_children() + arm.get_children():
					if part is MeshInstance3D:
						clothes.append((((part as MeshInstance3D).mesh as BoxMesh).material as StandardMaterial3D).albedo_color.to_html())
				out.append("%s %.2f,%.2f,%.2f w%s p%d c%s s%s r%.2f ring%s col%s per%s [%s]" % [
						"B%d" % i, b.global_position.x, b.global_position.y, b.global_position.z, str(b.visible).left(1) + str(b.get("waving")).left(1),
						int(b.get("pattern")), (b.get("_colour") as Color).to_html(), b.call("shown_colour").to_html(), float(b.get("_ring_radius")),
						str((b.get("_ring") as Node3D).visible).left(1), str((b.get("_column") as Node3D).visible).left(1),
						str((b.get("_person") as Node3D).visible).left(1), ",".join(clothes)])
		out.append("buzz %d %d %.2f" % [Haptics.count, Haptics.last_ms, Haptics.last_amp])
		Haptics._last_usec = -Haptics.GAP_USEC
		Haptics._last_end_usec = 0
		return " | ".join(out)


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
## The status line's title on the first tick of the last call `_take_aboard` took (the pickup's, before it was aboard).
var title_seen := ""
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
## rest share; `fresh` starts again for a part that needs a session of its own). `data` and `roofs`
## are the city it finds its places in: the rig's own when empty.
func _fresh(data := {}, roofs := []) -> void:
	if m != null:
		_keep_trace()
		m.queue_free()
		world.queue_free()
	accepted = 0
	map.roofs = roofs if not roofs.is_empty() else _roofs()
	hud = RescueHud.new()
	root.add_child(hud)
	dialogue = Fakes.Dialogue.new()
	root.add_child(dialogue)
	wallet = Fakes.Wallet.new()
	root.add_child(wallet)
	world = Node3D.new()
	root.add_child(world)
	hud.world = world
	m = Missions.new()
	root.add_child(m)
	await m.setup(map, data if not data.is_empty() else _data(), world, hud)
	m.wallet = wallet
	m.dialogue = dialogue
	m.vehicle_anchor = func() -> Vector3: return Vector3(1, 2, 3)
	m.player = PLAYER
	m.accepted.connect(func() -> void: accepted += 1)


## Adds the session's record to `trace`: the HUD's calls in order, then each line said (key, speaker, how
## it was said, where) and each payment, then the two beacons as the session left them.
func _keep_trace() -> void:
	trace.append("--- session")
	trace.append_array(hud.record)
	for i in dialogue.said.size():
		var h: Array = dialogue.hows[i]
		var anchor: Variant = dialogue.anchors[i]
		var where := "other"
		if anchor is Callable:
			where = "vehicle %s" % str((anchor as Callable).call())
		elif anchor == world.get_child(1):
			where = "drop-off"
		trace.append("said %s | %s | %s %s %s %s | %s" % [dialogue.said[i], dialogue.speakers[i], str(h[0]), (h[1] as Color).to_html(), str(h[2]), str(h[3]), where])
	for pay: Array in wallet.payments:
		trace.append("paid %s" % str(pay))
	trace.append("end " + hud.snap())


func _ticks(seconds: float, pos := PLAYER, speed := 0.0, flying := false) -> void:
	var n := roundi(seconds / DT)
	for i in n:
		m.tick(DT, pos, speed, flying)


## Stands still at `at` until the hold is done (1.5 s and two ticks more), by car or in the air.
func _hold_at(at: Vector3, flying := false) -> void:
	_ticks(1.5 + 0.2, at, 0.0, flying)


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
	await _fresh()
	_edges()
	await _words()
	await _fresh()
	await _places()
	await _fresh()
	await _rest()
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
	_expect(is_equal_approx(m.call_in(), -1.0), "A before the quiet start no countdown runs: %.2f" % m.call_in())


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
	_expect(hud.messages.calls == 1, "C the HUD's message director was told of the one call: %d" % hud.messages.calls)
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
	_expect(hud.accent == AMBER, "D the card in the pickup's amber")
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
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "" and is_equal_approx(m.call_in(), 90.0),
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
	_expect(m.target_colour() == AMBER and m.stop_spot() == at and not m.needs_heli(),
			"E a car's pickup: amber, the stop assist's spot is the person, no helicopter needed")
	var hosp := Vector3(810, 0, 0)
	var limit := ceilf((35.0 + (_flat(PLAYER, at) + _flat(at, hosp)) / 9.5) / 5.0) * 5.0
	m.tick(DT, PLAYER, 0.0, false)
	_expect(hud.status_title == "ODBIÓR · " + street, "E the status line: ODBIÓR · the street: %s" % hud.status_title)
	_expect(hud.count == _clock(limit - DT), "E the clock: the fair time %s less a tick: %s" % [_clock(limit), hud.count])
	_expect(hud.distance == "%d m" % roundi(_flat(PLAYER, at)), "E the metres to the person: %s" % hud.distance)
	_expect(hud.status == "Jedź do żółtego światła" and hud.hint_en == "Head for the yellow beacon", "E far off: head for the yellow beacon: %s" % hud.status)
	_expect(hud.tint == AMBER, "E the line in amber")
	var near := at + Vector3(20, 0, 0)
	m.tick(DT, near, 0.0, false)
	_expect(hud.status == "Stań w kręgu" and hud.hint_en == "Stop inside the ring", "E within 40 m, outside the ring: stop inside it: %s" % hud.status)
	m.tick(DT, at + Vector3(5, 0, 0), 7.0, false)
	_expect(hud.status == "Stań, żeby ich zabrać" and hud.hint_en == "Stop to pick them up", "E in the ring too fast: stop: %s" % hud.status)
	m.tick(DT, at + Vector3(5, 0, 0), 0.0, false)
	_expect(hud.status == "Nie ruszaj się… zabieramy" and absf(hud.progress - DT / 1.5) < 0.01, "E stopped in the ring: hold still, the bar fills: %s %.3f" % [hud.status, hud.progress])
	m.tick(DT, at + Vector3(5, 0, 0), 7.0, false)
	_expect(is_equal_approx(hud.progress, 0.0), "E moving again starts the hold over: %.3f" % hud.progress)
	m.tick(DT, at + Vector3(0, 3.0, 0), 0.0, false)
	_expect(hud.status != "Nie ruszaj się… zabieramy", "E 3 m above the person (a bridge) is no pickup: %s" % hud.status)
	_hold_at(at)
	_expect(int(m.state) == Missions.State.DROPOFF, "E held still 1.5 s: picked up: %d" % int(m.state))
	_expect(hud.toasts[-1] == "Zabrani! Teraz: Szpital Testowy" and hud.toasts_en[-1] == "Picked up! Now to Szpital Testowy", "E the toast names the hospital: %s" % hud.toasts[-1])
	_expect(not _pickup().visible and _dropoff().visible and _flat(_dropoff().position, hosp) < 0.01, "E the pickup's beacon goes, the drop-off's stands at the hospital's open door")
	_expect(dialogue.said.size() == said + 1 and dialogue.said[-1] == "rescue_person:street", "E the person's line, a street one: %s" % str(dialogue.said.slice(said)))
	_expect(dialogue.speakers[-1] in NAMES and dialogue.anchors[-1] is Callable, "E said by a grown-up's name at the vehicle: %s" % dialogue.speakers[-1])
	_expect(m.target_position() == hosp and m.stop_spot() == hosp and m.target_colour() == GREEN, "E the target is the hospital now, in green")
	m.tick(DT, at, 0.0, false)
	_expect(hud.status_title == "DO SZPITALA · Szpital Testowy" and hud.status == "Pacjent na pokładzie: do zielonego światła",
			"E the status line to the hospital: %s / %s" % [hud.status_title, hud.status])
	_expect(hud.tint == GREEN, "E the line in green")
	m.tick(DT, hosp + Vector3(3, 0, 0), 8.0, false)
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
	_expect(hud.body_en == "Safe and sound at the hospital: time, score and pay above.", "E its English body: %s" % hud.body_en)
	_expect(hud.accent == GREEN and hud.status_title == "", "E the card green, the status line down")
	_expect(dialogue.said[-1] == "rescue_done:" and dialogue.speakers[-1] == "Ratownik" and dialogue.anchors[-1] == _dropoff(),
			"E the crew's line at the hospital: %s %s" % [dialogue.said[-1], dialogue.speakers[-1]])
	_expect(_dropoff().visible and _pickup().visible and _flat(_pickup().position, hosp + Vector3(1.6, 0, 0.8)) < 0.01,
			"E the patient stands with the crew beside the door")
	_expect(not m.has_target(), "E no target on the result card")
	hud.press(1)
	_expect(int(m.state) == Missions.State.CLOSED and hud.card == "" and is_equal_approx(m.call_in(), 90.0) and not _pickup().visible,
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
	_expect(m.needs_heli() and m.stop_spot() == Vector3.INF and m.target_colour() == VIOLET, "F needs the helicopter, no stop spot, the HELI violet")
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
	_expect(hud.button_words == PackedStringArray(["TRY AGAIN", "NEXT CALL", "FREE ROAM"]) and hud.accent == RED, "G TRY AGAIN / NEXT CALL / FREE ROAM, in red")
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
	_expect(int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), 90.0), "G FREE ROAM after a failure: closed, 90 s")


# --- H. the calls ----------------------------------------------------------------------------------

func _calls() -> void:
	m.quiet_start(1.0)
	var titles := []
	var titles_en := []
	for n in range(1, 9):
		m.offer(n)
		titles.append(hud.card.get_slice(" · ", 1))
		titles_en.append(hud.card_en)
	_expect(titles_en == ["Call 1 · street rescue", "Call 2 · roof rescue", "Call 3 · river rescue", "Call 4 · park rescue",
			"Call 5 · street rescue", "Call 6 · roof rescue", "Call 7 · river rescue", "Call 8 · park rescue"], "H the English titles: %s" % str(titles_en))
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
		_expect(_flat(hosp, Vector3(-700, 0, -190)) < 0.01 and dialogue.said[-1] == "rescue_person:child" and dialogue.speakers[-1] in KIDS,
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

## The M key as main.gd presses it for the line (`_primary`): the card's first button, or with no
## card up the next call. The line on the kit answers the director (`primary`) and gives the rest to
## `call_now`; before the kit its `primary` did both.
func _key_m() -> void:
	if m.has_method("call_now"):
		if not bool(m.call("primary")):
			m.call("call_now")
	else:
		m.call("primary")


func _keys() -> void:
	m.quiet_start(1.0)
	_key_m()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 1, "J M while counting down: the next call's card")
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2, "J K on a card: SKIP")
	_key_m()
	_expect(int(m.state) == Missions.State.PICKUP, "J M on a card: ACCEPT")
	m.secondary()
	_key_m()
	_expect(int(m.state) == Missions.State.PICKUP, "J the keys do nothing under way")
	hud.abort_pressed.emit()
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 3, "J K on a failure's card: NEXT CALL")
	m.paused = true
	_key_m()
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 3, "J the keys do nothing while paused")
	m.paused = false
	hud.press(2)
	_ticks(90.5)
	_expect(int(m.state) == Missions.State.RINGING, "J 90 s after LATER the next call rings")
	_key_m()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 4, "J M while ringing: the call's card")
	hud.pad_mode = true
	hud.press(2)
	m.ring_in(0.05)
	_ticks(0.2)
	_expect(hud.toasts[-1].begins_with("Wezwanie ratunkowe! ") and hud.toasts[-1].ends_with(": odbierz."), "J with a pad the toast names its button: %s" % hud.toasts[-1])


# --- the labs' helpers -----------------------------------------------------------------------------------

## No roof anywhere: one flat patch at the map's far corner (a lab with no roofs of its own).
const NO_ROOFS := [[Rect2(1990.0, 1990.0, 1.0, 1.0), 0.0]]
## The hospital's door in the rig, and what the status line says at the hold.
const DOOR := Vector3(810, 0, 0)
const HOLD_DROP := "Nie ruszaj się… przekazujemy"
const HOLD_PICK := "Nie ruszaj się… zabieramy"


## A small city for a lab: `roads`, `landmarks` and `pois` and, unless `hospital` is off, the rig's one hospital
## (door at 810, 0).
func _city(roads := [], landmarks := [], pois := [], hospital := true) -> Dictionary:
	var all := pois.duplicate()
	if hospital:
		all.append({"k": "hospital", "name": "Szpital Testowy", "x": 800.0, "z": 0.0, "door": [810.0, 0.0]})
	return {"roads": roads, "landmarks": landmarks, "pois": all}


## A named road running along z at `x` from `z0` to `z1`.
func _vroad(name: String, x: float, z0: float, z1: float, kind := "primary") -> Dictionary:
	return {"name": name, "k": kind, "p": [x, z0, x, z1]}


## A landmark with a square outline from its corner (x, z).
func _lm(name: String, x: float, z: float, side: float) -> Dictionary:
	return {"name": name, "p": _box(x, z, side)}


## A roof over the same square, `up` metres high.
func _roof(x: float, z: float, side: float, up: float) -> Array:
	return [Rect2(x, z, side, side), up]


## A session of its own on `city` and `roofs`, the player at `at`, ready for `offer`.
func _lab(city: Dictionary, roofs: Array, at := PLAYER) -> void:
	await _fresh(city, roofs)
	m.tick(DT, at, 0.0, false)


## The call on the card, accepted and picked up: by car `board`, by helicopter hovering 2 m over the person.
## Returns where the person waited.
func _take_aboard() -> Vector3:
	hud.press(0)
	var at: Vector3 = m.target_position()
	m.tick(DT, PLAYER, 0.0, false)
	title_seen = hud.status_title
	if m.needs_heli():
		_hold_at(at + Vector3(0, 2, 0), true)
	else:
		m.board()
	return at


## The roof spot of landmark `name` as the rescue line's places hold it (missions.gd's own on the script
## before M0, rescue_places.gd's `places` after): INF when it has none.
func _roof_spot(name: String) -> Vector3:
	if "places" in m:
		return m.places.roof_spot(name)
	return m.roof_spot(name)


## Whether two places are the same to 5 cm (a lerp along a road leaves the last digits of a float).
func _same(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) < 0.05


## One tick of 0.1 s at `pos` right after one far away (which ends any hold), then what the status line says.
func _edge(pos: Vector3, speed: float, flying: bool, hint: String, hold: bool, what: String) -> void:
	m.tick(DT, Vector3(9000, 0, 9000), 0.0, flying)
	m.tick(DT, pos, speed, flying)
	_expect(hud.status == hint and (hud.progress > 0.0) == hold, "K %s: %s (%.3f)" % [what, hud.status, hud.progress])


## The fair time of a trip in whole seconds as the game says it: 35 s, the trip at `pace` m/s, the climb at 5 m/s,
## rounded up to 5 s.
func _fair(trip: float, pace: float, climb := 0.0) -> float:
	return ceilf((35.0 + trip / pace + climb / 5.0) / 5.0) * 5.0


# --- K. the edges, in exact numbers ---------------------------------------------------------------------

func _edges() -> void:
	# The countdown's arguments.
	m.quiet_start()
	_expect(is_equal_approx(m.call_in(), 60.0), "K quiet_start() with no argument counts 60 s: %.2f" % m.call_in())
	m.quiet_start(0.0)
	_expect(is_equal_approx(m.call_in(), 0.0) and int(m.state) == Missions.State.CLOSED, "K quiet_start(0) counts 0 s: %.2f" % m.call_in())
	m.quiet_start(0.25)
	m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), 0.0), "K a countdown that lands on zero has not rung yet: %d %.2f" % [int(m.state), m.call_in()])
	m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.RINGING, "K and rings on the next tick: %d" % int(m.state))
	m.quiet_start(1.0)
	hud.calls_ok = false
	m.tick(0.25, PLAYER, 0.0, false)
	m.quiet_start(0.0)
	m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), 0.0), "K the HUD's gate shut: the call waits at zero: %d %.2f" % [int(m.state), m.call_in()])
	hud.calls_ok = true
	m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.RINGING, "K the gate opens: the call waiting at zero rings on the next tick: %d" % int(m.state))
	# The haptic engine is started two seconds before the call rings, on the tick that crosses them.
	m.quiet_start(3.0)
	var warms := ""
	for i in 8:
		Haptics._warm_in = 0.0
		m.tick(0.25, PLAYER, 0.0, false)
		warms += "w" if Haptics._warm_in > 0.0 else "."
	_expect(warms == "....w...", "K the haptic engine starts on the one tick that crosses 2 s before the ring: %s" % warms)

	# At the hospital's door: a car, then the helicopter.
	m.quiet_start(1.0)
	m.tick(DT, PLAYER, 0.0, false)
	m.offer(1)
	hud.press(0)
	var person: Vector3 = m.target_position()
	m.board()
	_expect(int(m.state) == Missions.State.DROPOFF and m.target_position() == DOOR, "K call 1 is aboard for the hospital's door at 810, 0: %s" % m.target_position())
	_edge(DOOR + Vector3(13, 0, 0), 0.0, false, HOLD_DROP, true, "car 13 m off, stopped, holds")
	_edge(DOOR + Vector3(13.5, 0, 0), 0.0, false, "Stań w kręgu", false, "car 13.5 m off: stop inside the ring")
	_edge(DOOR + Vector3(40, 0, 0), 0.0, false, "Stań w kręgu", false, "car 40 m off: stop inside the ring")
	_edge(DOOR + Vector3(40.5, 0, 0), 0.0, false, "Pacjent na pokładzie: do zielonego światła", false, "car 40.5 m off: head for the green beacon")
	_edge(DOOR, 5.9, false, HOLD_DROP, true, "car at 5.9 m/s holds")
	_edge(DOOR, 6.0, false, "Stań, żeby ich przekazać", false, "car at 6.0 m/s: stop to hand them over")
	_edge(DOOR + Vector3(0, 2.4, 0), 0.0, false, HOLD_DROP, true, "car 2.4 m above holds")
	_edge(DOOR + Vector3(0, -2.4, 0), 0.0, false, HOLD_DROP, true, "car 2.4 m below holds")
	_edge(DOOR + Vector3(0, 2.5, 0), 0.0, false, "", false, "car 2.5 m above: no hold, no hint")
	_edge(DOOR + Vector3(13, 2.5, 0), 0.0, false, "", false, "car at 13 m and 2.5 m above: no hold, no hint")
	_edge(DOOR + Vector3(8, 3.9, 0), 0.0, true, HOLD_DROP, true, "helicopter 8 m off, 3.9 m up, holds")
	_edge(DOOR + Vector3(8.5, 3.9, 0), 0.0, true, "Leć nad krąg", false, "helicopter 8.5 m off: move over the ring")
	_edge(DOOR + Vector3(8, 4.0, 0), 0.0, true, "Niżej: do 4 m nad nimi (▼ / F)", false, "helicopter 4.0 m up: go down")
	_edge(DOOR + Vector3(0, -1.0, 0), 0.0, true, "", false, "helicopter 1.0 m below: no hold, no hint")
	_edge(DOOR + Vector3(0, -0.9, 0), 0.0, true, HOLD_DROP, true, "helicopter 0.9 m below holds")
	_edge(DOOR + Vector3(8, -1.0, 0), 0.0, true, "", false, "helicopter 8 m off and 1.0 m below: no hold, no hint")
	_edge(DOOR + Vector3(8, 0.0, 0), 0.0, true, HOLD_DROP, true, "helicopter 8 m off at the door's height holds")

	# The hold in quarter seconds (exact in binary): five ticks are not enough, the sixth is, at the person and at the door.
	m.tick(DT, PLAYER, 0.0, false)
	m.offer(1)
	hud.press(0)
	for i in 5:
		m.tick(0.25, person, 0.0, false)
	_expect(int(m.state) == Missions.State.PICKUP and absf(hud.progress - 1.25 / 1.5) < 0.001, "K five quarter-seconds at the person: still on the way, the bar at 1.25 of 1.5: %.3f" % hud.progress)
	m.tick(0.25, person, 0.0, false)
	_expect(int(m.state) == Missions.State.DROPOFF, "K the sixth picks them up: %d" % int(m.state))
	m.tick(0.25, DOOR, 0.0, false)
	_expect(int(m.state) == Missions.State.DROPOFF and absf(hud.progress - 0.25 / 1.5) < 0.001, "K at the door right after the pickup the hold starts from nothing: %.3f" % hud.progress)
	for i in 4:
		m.tick(0.25, DOOR, 0.0, false)
	_expect(int(m.state) == Missions.State.DROPOFF and absf(hud.progress - 1.25 / 1.5) < 0.001, "K five quarter-seconds at the door: still there, the bar at 1.25 of 1.5: %.3f" % hud.progress)
	m.tick(0.25, DOOR, 0.0, false)
	_expect(int(m.state) == Missions.State.RESULT and m.total_score > 0, "K the sixth hands them over: %d" % int(m.state))

	# A hold broken off, then TRY AGAIN: the new hold starts from nothing.
	m.tick(DT, PLAYER, 0.0, false)
	m.offer(1)
	hud.press(0)
	for i in 5:
		m.tick(0.1, person, 0.0, false)
	hud.abort_pressed.emit()
	hud.press(0)
	m.tick(0.1, person, 0.0, false)
	_expect(int(m.state) == Missions.State.PICKUP and absf(hud.progress - 0.1 / 1.5) < 0.001, "K TRY AGAIN after a broken-off hold: the bar starts over: %.3f" % hud.progress)

	# The clock runs out exactly on the tick that takes the last quarter second.
	m.tick(DT, PLAYER, 0.0, false)
	m.offer(1)
	hud.press(0)
	var limit := _fair(_flat(PLAYER, person) + _flat(person, DOOR), 9.5)
	var quarters := roundi(limit * 4.0)
	for i in quarters - 1:
		m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.PICKUP, "K a quarter second before the clock reaches zero the call is on: %d" % int(m.state))
	m.tick(0.25, PLAYER, 0.0, false)
	_expect(int(m.state) == Missions.State.RESULT and hud.card == "ZA PÓŹNO", "K the clock at exactly zero: out of time: %d %s" % [int(m.state), hud.card])


# --- L. the words of every kind ------------------------------------------------------------------------

## A lab with `city`, call `n` on the card: its titles, its Polish and English words (`pl` the place's own Polish
## text, `gloss` its English), then accepted and picked up: the status line's place (`short_pl`) and the person's
## line (`tag`). `where` and `where_en` are the distance and direction from the player at the origin.
func _word_lab(city: Dictionary, roofs: Array, n: int, pl: String, gloss: String, short_pl: String, tag: String,
		where: String, where_en: String, limit: String) -> void:
	await _lab(city, roofs)
	m.offer(n)
	var kinds_pl := ["RATUNEK NA ULICY", "RATUNEK NA DACHU", "RATUNEK NAD WISŁĄ", "RATUNEK W PARKU"]
	var kinds_en := ["street rescue", "roof rescue", "river rescue", "park rescue"]
	var k := (n - 1) % 4
	_expect(hud.card == "WEZWANIE %d · %s" % [n, kinds_pl[k]] and hud.card_en == "Call %d · %s" % [n, kinds_en[k]], "L %s: the card's titles: %s / %s" % [tag, hud.card, hud.card_en])
	_expect(hud.body == "%s\nOd ciebie: %s · Szpital: Szpital Testowy · czas %s" % [pl, where, limit], "L %s: the Polish body: %s" % [tag, hud.body])
	_expect(hud.body_en == "%s About %s of you. Get them to the hospital in %s." % [gloss, where_en, limit], "L %s: the English body: %s" % [tag, hud.body_en])
	_take_aboard()
	_expect(title_seen == "ODBIÓR · " + short_pl, "L %s: the status line names the place: %s" % [tag, title_seen])
	_expect(int(m.state) == Missions.State.DROPOFF and dialogue.said[-1] == "rescue_person:" + tag, "L %s: the person's line: %s" % [tag, dialogue.said[-1]])
	var kid := tag == "child"
	_expect((dialogue.speakers[-1] in KIDS) == kid and (dialogue.speakers[-1] in NAMES) != kid, "L %s: said by a %s's name: %s" % [tag, "child" if kid else "grown-up", dialogue.speakers[-1]])
	hud.abort_pressed.emit()
	_expect(int(m.state) == Missions.State.RESULT and hud.card == "ZA PÓŹNO" and hud.body.begins_with("Akcja odwołana."), "L %s: called off on the way to the hospital: the failure card: %s" % [tag, hud.card])


func _words() -> void:
	var river := _vroad("Aleja Nadwiślańska", 300.0, -50.0, 50.0)
	await _word_lab(_city([_vroad("Aleja Testowa", 300.0, -50.0, 50.0)]), NO_ROOFS, 1,
			"Ranny rowerzysta: Aleja Testowa. Wystarczy auto albo helikopter.", "A cyclist is hurt: the car or the helicopter will do.",
			"Aleja Testowa", "street", "ok. 300 m na wschód", "300 m east", "2:05")
	var roof_city := func(name: String) -> Dictionary: return _city([], [_lm(name, -600.0, 300.0, 32.0)])
	var roof_roof := [_roof(-600.0, 300.0, 32.0, 30.0)]
	# A roof named after a real chain shows the parody: Puro, and Caffè Nero spelt both ways.
	for row: Array in [["Puro Hotel Testowy", "Hotel Piure"], ["Caffè Nero Testowe", "Green Caffè Nerwo"], ["Caffe Nero Testowe", "Green Caffè Nerwo"],
			["Pałac Testowy", "Pałac Testowy"]]:
		await _word_lab(roof_city.call(row[0]), roof_roof, 2,
				"Ktoś utknął na dachu: %s, 30 m nad ulicą. Dotrze tylko helikopter." % row[1], "Someone is stuck on a roof 30 m up: helicopter only.",
				"dach: " + row[1], "roof", "ok. 670 m na południowy zachód", "670 m south-west", "2:45")
	var at_400 := "ok. 400 m na wschód"
	var limit_car := _clock(_fair(810.0, 9.5))
	await _word_lab(_city([], [], [{"k": "beach", "name": "Poniatówka", "x": 400.0, "z": 0.0}]), NO_ROOFS, 3,
			"Pływak w tarapatach: plaża Poniatówka nad Wisłą.", "A swimmer is in trouble on a Vistula beach.",
			"plaża Poniatówka", "river", at_400, "400 m east", limit_car)
	await _word_lab(_city([river], [], [{"k": "beach", "name": "", "x": 400.0, "z": 0.0}]), NO_ROOFS, 3,
			"Pływak w tarapatach na plaży nad Wisłą (okolice: Aleja Nadwiślańska).", "A swimmer is in trouble on a Vistula beach.",
			"plaża nad Wisłą", "river", at_400, "400 m east", limit_car)
	await _word_lab(_city([], [], [{"k": "beach", "name": "", "x": 400.0, "z": 0.0}]), NO_ROOFS, 3,
			"Pływak w tarapatach na plaży nad Wisłą (okolice: the river).", "A swimmer is in trouble on a Vistula beach.",
			"plaża nad Wisłą", "river", at_400, "400 m east", limit_car)
	await _word_lab(_city([river], [], [{"k": "shore", "name": "", "x": 400.0, "z": 0.0}]), NO_ROOFS, 3,
			"Ktoś poślizgnął się na brzegu Wisły (okolice: Aleja Nadwiślańska). Wystarczy auto albo helikopter.",
			"Someone slipped on the Vistula shore: car or helicopter.", "brzeg Wisły", "river", at_400, "400 m east", limit_car)
	await _word_lab(_city([river], [], [{"k": "sandbar", "name": "", "x": 400.0, "z": 0.0}]), NO_ROOFS, 3,
			"Ktoś utknął na łasze na Wiśle (okolice: Aleja Nadwiślańska). Dotrze tylko helikopter.",
			"Someone is stranded on a Vistula sandbar: helicopter only.", "łacha na Wiśle", "river", at_400, "400 m east", _clock(_fair(810.0, 17.0)))
	await _word_lab(_city([], [], [{"k": "park", "name": "Park Testowy", "x": 400.0, "z": 0.0}]), NO_ROOFS, 4,
			"Dziecko spadło z drabinek: Park Testowy.", "A child fell off a climbing frame.", "Park Testowy", "child", at_400, "400 m east", limit_car)
	await _word_lab(_city([], [], [{"k": "square", "name": "Plac Testowy", "x": 400.0, "z": 0.0}]), NO_ROOFS, 4,
			"Turystka zemdlała: Plac Testowy.", "A tourist fainted.", "Plac Testowy", "square", at_400, "400 m east", limit_car)


# --- M. which place, which hospital, which roof -----------------------------------------------------------

## What call `n` is from `at` in the rig: the place on the status line, where its person waits, where the
## hospital's door is, and who it is.
func _call_row(n: int, at: Vector3) -> String:
	m.tick(DT, at, 0.0, false)
	m.offer(n)
	var where := _take_aboard()
	return "%d %s @ %.1f,%.1f > %s | %s" % [n, title_seen.trim_prefix("ODBIÓR · "), where.x, where.z, str(m.target_position()), dialogue.speakers[-1]]


## The streets the street calls 1, 5, 9 ... (`count` of them) name, from the player where he stands, in order.
func _street_calls(count: int) -> String:
	var names := PackedStringArray()
	for i in count:
		m.offer(1 + 4 * i)
		names.append(hud.body.get_slice(". Wystarczy", 0).trim_prefix("Ranny rowerzysta: "))
	return " ".join(names)


## A lab of vertical roads, one per x in `xs` (z from -10 to 10, so each one's person stands at its x on the z axis),
## named "S" and the x.
func _spread(xs: Array) -> Dictionary:
	var roads := []
	for x: float in xs:
		roads.append(_vroad("S%d" % roundi(x), x, -10.0, 10.0))
	return _city(roads)


## Where the person of street call 1 stands in a lab of `roads` over `roofs`.
func _street_spot(roads: Array, roofs: Array) -> Vector3:
	await _lab(_city(roads), roofs)
	m.offer(1)
	hud.press(0)
	return m.target_position()


## A hospital for a lab: its name and its door.
func _hospital(name: String, x: float, z: float) -> Dictionary:
	return {"k": "hospital", "name": name, "x": x, "z": z, "door": [x, z]}


func _places() -> void:
	m.quiet_start(1.0)
	var from_origin := ["1 Rondo ONZ @ -300.0,-330.0 > (810.0, 0.0, 0.0) | Tomek", "2 paw na dachu: Zamek Ujazdowski @ 456.0,1606.0 > (810.0, 0.0, 0.0) | Pan Paw",
			"3 plaża nad Wisłą @ 1300.0,-200.0 > (810.0, 0.0, 0.0) | Magda", "4 Park Testowy @ -600.0,500.0 > (-700.0, 0.0, -190.0) | Staś",
			"5 Nowy Świat @ 700.0,100.0 > (810.0, 0.0, 0.0) | Ania", "6 paw na dachu: Zamek Ujazdowski @ 456.0,1606.0 > (810.0, 0.0, 0.0) | Pan Paw",
			"7 plaża nad Wisłą @ 1300.0,-200.0 > (810.0, 0.0, 0.0) | Bartek", "8 Park pod Dachem @ 294.0,-390.0 > (810.0, 0.0, 0.0) | Hania"]
	var from_west := ["1 Marszałkowska @ 0.0,0.0 > (810.0, 0.0, 0.0) | Tomek", "2 paw na dachu: Zamek Ujazdowski @ 456.0,1606.0 > (810.0, 0.0, 0.0) | Pan Paw",
			"3 brzeg Wisły @ 1100.0,900.0 > (810.0, 0.0, 0.0) | Magda", "4 Park pod Dachem @ 294.0,-390.0 > (810.0, 0.0, 0.0) | Staś",
			"5 Wspólna @ 320.0,-406.0 > (810.0, 0.0, 0.0) | Ania", "6 paw na dachu: Zamek Ujazdowski @ 456.0,1606.0 > (810.0, 0.0, 0.0) | Pan Paw",
			"7 brzeg Wisły @ 1100.0,900.0 > (810.0, 0.0, 0.0) | Bartek", "8 Park Testowy @ -600.0,500.0 > (-700.0, 0.0, -190.0) | Hania"]
	for row: Array in [[PLAYER, from_origin], [Vector3(-400, 0, 300), from_west]]:
		var got := []
		for n in range(1, 9):
			got.append(_call_row(n, row[0]))
		_expect(got == row[1], "M calls 1 to 8 from %s: the place, the person's spot, the hospital's door, who:\n    %s" % [str(row[0]), "\n    ".join(got)])
	# The calls to the street never take a service road or one with no name.
	var streets := {}
	for n in range(1, 60, 4):
		m.offer(n)
		streets[hud.body.get_slice(". Wystarczy", 0).trim_prefix("Ranny rowerzysta: ")] = true
	var street_names := streets.keys()
	street_names.sort()
	_expect(street_names == ["Nowy Świat", "Plac Zbawiciela", "Rondo ONZ", "Wspólna"], "M the street calls name four streets, no service road or unnamed one: %s" % str(street_names))
	# The peacock keeps its call within 2,600 m of the player, and not beyond.
	var zamek := _roof_spot("Zamek Ujazdowski")
	_expect(zamek == Vector3(456, 25, 1606), "M the Zamek's roof spot: %s" % str(zamek))
	m.tick(DT, zamek + Vector3(2600, 0, 0), 0.0, false)
	m.offer(2)
	_expect(hud.body.begins_with("Paw uciekł z Łazienek i paraduje po dachu: Zamek Ujazdowski, 25 m nad ulicą. Dotrze tylko helikopter.\nOd ciebie: ok. 2600 m na zachód"),
			"M a roof call 2,600 m off still offers the peacock: %s" % hud.body)
	_expect(hud.body_en.begins_with("A peacock escaped from Łazienki and sits on a roof 25 m up: helicopter only. About 2600 m west of you."), "M and its English: %s" % hud.body_en)
	m.tick(DT, zamek + Vector3(2600.5, 0, 0), 0.0, false)
	m.offer(2)
	_expect(not hud.body.contains("Paw"), "M 2,600.5 m off it does not: %s" % hud.body)
	m.tick(DT, zamek + Vector3(-2599, 0, 0), 0.0, false)
	m.offer(2)
	_expect(hud.body.contains("Paw"), "M 2,599 m off it does: %s" % hud.body)

	# The 150 m and 1,100 m edges of a call's reach (and the three nearest when fewer than three are in it).
	await _lab(_spread([59.0, 60.0, 70.0, 149.0, 150.0, 160.0, 190.0, 1000.0, 1100.0, 1200.0, 1400.0]), NO_ROOFS)
	var band := _street_calls(16)
	_expect(band == "S150 S190 S160 S150 S1100 S1100 S1000 S1000 S1000 S150 S1100 S150 S1000 S1100 S1100 S1000", "M streets 150 to 1,100 m off, the street calls 1, 5, 9 ...: %s" % band)
	await _lab(_spread([59.0, 60.0, 70.0, 200.0, 1300.0]), NO_ROOFS)
	band = _street_calls(16)
	_expect(band == "S200 S60 S60 S200 S200 S70 S200 S200 S70 S200 S70 S70 S200 S70 S200 S70", "M one street in reach: it and the next two from 60 m on: %s" % band)
	await _lab(_spread([59.0, 100.0, 160.0, 400.0, 1000.0]), NO_ROOFS)
	band = _street_calls(16)
	_expect(band == "S1000 S160 S160 S1000 S1000 S400 S1000 S1000 S400 S1000 S400 S400 S1000 S400 S1000 S400", "M exactly three streets in reach: those three: %s" % band)
	await _lab(_spread([10.0]), NO_ROOFS)
	band = _street_calls(2)
	_expect(band == "S10 S10", "M the one street 10 m off is still the call: %s" % band)
	await _lab(_city([_vroad("E", 200.0, -10.0, 10.0), _vroad("W", -200.0, -10.0, 10.0), _vroad("N", 0.0, -210.0, -190.0), _vroad("S", 0.0, 190.0, 210.0), _vroad("F", 500.0, -10.0, 10.0)]), NO_ROOFS)
	band = _street_calls(16)
	_expect(band == "E N W E F F S S S E F E S F F S", "M four streets as far as each other: %s" % band)

	# Where a street's person stands: the open middle, 6 m out either way, clear of a roof by 4.5 m and 1.5 m of height.
	var a_road := [_vroad("A", 300.0, -100.0, 100.0)]
	var spot := await _street_spot(a_road, NO_ROOFS)
	_expect(_same(spot, Vector3(300, 0, 0)), "M a street's person at its open middle: %s" % spot)
	spot = await _street_spot(a_road, [[Rect2(304.4, -50.0, 20.0, 100.0), 10.0]])
	_expect(_same(spot, Vector3(300, 0, 60)), "M a roof 4.4 m from the middle: the person moves on to open sky: %s" % spot)
	spot = await _street_spot(a_road, [[Rect2(304.6, -50.0, 20.0, 100.0), 10.0]])
	_expect(_same(spot, Vector3(300, 0, 0)), "M a roof 4.6 m from the middle: the person stays: %s" % spot)
	spot = await _street_spot(a_road, [[Rect2(304.0, -50.0, 20.0, 100.0), 1.5]])
	_expect(_same(spot, Vector3(300, 0, 0)), "M a roof 1.5 m high is no roof: %s" % spot)
	spot = await _street_spot(a_road, [[Rect2(304.0, -50.0, 20.0, 100.0), 1.7]])
	_expect(_same(spot, Vector3(300, 0, 60)), "M a roof 1.7 m high is: %s" % spot)
	spot = await _street_spot([_vroad("A", 300.0, 0.0, 200.0)], [[Rect2(298.0, 90.0, 4.0, 7.0), 10.0]])
	_expect(_same(spot, Vector3(300, 0, 106)), "M the middle shut: 6 m on, the way the road runs: %s" % spot)
	spot = await _street_spot([_vroad("A", 300.0, 0.0, 200.0)], [[Rect2(298.0, 103.0, 4.0, 7.0), 10.0]])
	_expect(_same(spot, Vector3(300, 0, 94)), "M the middle and 6 m on shut: 6 m back: %s" % spot)
	spot = await _street_spot([_vroad("A", 300.0, -50.0, 50.0), _vroad("A", -300.0, -50.0, 50.0)], NO_ROOFS)
	_expect(_same(spot, Vector3(300, 0, 0)), "M a name on two pieces of one length: the first: %s" % spot)
	spot = await _street_spot([_vroad("A", 300.0, -50.0, 50.0), _vroad("A", -300.0, -60.0, 60.0)], NO_ROOFS)
	_expect(_same(spot, Vector3(-300, 0, 0)), "M a name on two pieces: the longer: %s" % spot)
	spot = await _street_spot([{"name": "A", "k": "primary", "p": [500.0, 0.0, 540.0, 0.0, 540.0, 0.4, 580.0, 0.4]}], NO_ROOFS)
	_expect(absf(spot.x - 540.0) < 0.05 and absf(spot.z - 0.2) < 0.05, "M the middle of a bent road, on its 0.4 m piece: %s" % spot)
	spot = await _street_spot([_vroad("Dojazd", 300.0, -50.0, 50.0, "service"), _vroad("", 400.0, -50.0, 50.0, "residential"), _vroad("B", 500.0, -50.0, 50.0)], NO_ROOFS)
	_expect(_same(spot, Vector3(500, 0, 0)), "M no call on a service road or a road with no name: %s" % spot)
	# The map's edge: a street 35 m inside it is left out, one 45 m inside is kept.
	for row: Array in [["35", 1965.0, "B B B B B B B B B B B B B B B B B B B B B B B B"], ["45", 1955.0, "B A B B B A A A B B B A A A B A B A B A B A A B"]]:
		await _lab(_city([_vroad("A", row[1], -10.0, 10.0), _vroad("B", 300.0, -10.0, 10.0), _vroad("C", -1965.0, -10.0, 10.0)]), NO_ROOFS)
		band = _street_calls(24)
		_expect(band == row[2], "M a street %s m inside the map's edge (another 35 m inside on the far side is out): %s" % [row[0], band])

	# Short, doubled and shut-in roads: the road's ends count, a doubled first point is skipped, a shut road is no call.
	await _lab(_city([_vroad("Zablokowana", 300.0, -10.0, 10.0), _vroad("Krótka", 600.0, -6.0, 6.0),
			{"name": "Zdublowana", "k": "primary", "p": [900.0, -6.0, 900.0, -6.0, 900.0, 6.0]}, _vroad("Wolna", 1200.0, -10.0, 10.0)]),
			[[Rect2(290.0, -5.5, 20.0, 11.0), 10.0], [Rect2(599.0, -0.5, 2.0, 1.0), 10.0], [Rect2(899.0, 0.0, 2.0, 3.0), 10.0]])
	var odd := {}
	for n in range(1, 100, 4):
		m.offer(n)
		odd[hud.body.get_slice(". Wystarczy", 0).trim_prefix("Ranny rowerzysta: ")] = true
	var odd_names := odd.keys()
	odd_names.sort()
	_expect(odd_names == ["Krótka", "Wolna", "Zdublowana"], "M a road shut in along its whole length is no call; a short one and one with a doubled first point are: %s" % str(odd_names))

	# Roofs: 20 m up is the least; the highest flat spot of a name; flat to a metre in the 3 x 3 cells; 3 corners are an outline.
	var lms := [_lm("Dach 21", -1500.0, 100.0, 20.0), _lm("Dach 20", -1500.0, 300.0, 20.0), _lm("Dach 19", -1500.0, 500.0, 20.0),
			_lm("Dach 7", -1500.0, 700.0, 20.0), _lm("Dach 5", -1500.0, 900.0, 20.0),
			_lm("Dwa Dachy", -1200.0, 100.0, 20.0), _lm("Dwa Dachy", -1200.0, 300.0, 20.0),
			_lm("Dwa Równe", -1200.0, 500.0, 20.0), _lm("Dwa Równe", -1200.0, 700.0, 20.0),
			_lm("Garb 1.0", -1000.0, 100.0, 28.0), _lm("Garb 1.2", -1000.0, 300.0, 28.0), _lm("Trzy", -1000.0, 500.0, 12.0),
			{"name": "Trójkąt", "p": [-1000.0, 700.0, -960.0, 700.0, -1000.0, 740.0]},
			{"name": "Odwrócony", "p": [-780.0, 120.0, -800.0, 120.0, -800.0, 100.0, -780.0, 100.0, -780.0, 120.0]},
			_lm("Niskie Dwa", -700.0, 100.0, 20.0), _lm("Niskie Dwa", -700.0, 300.0, 20.0),
			_lm("Niskie Równe", -700.0, 500.0, 20.0), _lm("Niskie Równe", -700.0, 700.0, 20.0),
			_lm("Granica X", 1000.0, 100.0, 10.0), _lm("Granica Z", 1000.0, 300.0, 10.0)]
	var rfs := [_roof(-1500.0, 100.0, 20.0, 21.0), _roof(-1500.0, 300.0, 20.0, 20.0), _roof(-1500.0, 500.0, 20.0, 19.0),
			_roof(-1500.0, 700.0, 20.0, 7.0), _roof(-1500.0, 900.0, 20.0, 5.0),
			_roof(-1200.0, 100.0, 20.0, 24.0), _roof(-1200.0, 300.0, 20.0, 28.0),
			_roof(-1200.0, 500.0, 20.0, 30.0), _roof(-1200.0, 700.0, 20.0, 30.0),
			_roof(-1000.0, 100.0, 28.0, 30.0), [Rect2(-988.0, 112.0, 4.0, 4.0), 31.0],
			_roof(-1000.0, 300.0, 28.0, 30.0), [Rect2(-988.0, 312.0, 4.0, 4.0), 31.2],
			_roof(-1000.0, 500.0, 12.0, 30.0), _roof(-1000.0, 700.0, 40.0, 30.0), _roof(-800.0, 100.0, 20.0, 30.0),
			_roof(-700.0, 100.0, 20.0, 10.0), _roof(-700.0, 300.0, 20.0, 12.0), _roof(-700.0, 500.0, 20.0, 10.0), _roof(-700.0, 700.0, 20.0, 10.0),
			[Rect2(990.0, 90.0, 40.0, 40.0), 30.0], [Rect2(1008.0, 104.0, 4.0, 4.0), 30.8],
			[Rect2(990.0, 290.0, 40.0, 40.0), 30.0], [Rect2(1004.0, 308.0, 4.0, 4.0), 30.8]]
	await _lab(_city([], lms), rfs, Vector3(-1300, 0, 900))
	var want := {"Dach 21": Vector3(-1494, 21, 106), "Dach 20": Vector3(-1494, 20, 306), "Dach 19": Vector3(-1494, 19, 506), "Dach 7": Vector3(-1494, 7, 706),
			"Dach 5": Vector3.INF, "Dwa Dachy": Vector3(-1194, 28, 306), "Dwa Równe": Vector3(-1194, 30, 506), "Garb 1.0": Vector3(-986, 31, 114),
			"Garb 1.2": Vector3(-994, 30, 306), "Trzy": Vector3(-994, 30, 506), "Trójkąt": Vector3(-994, 30, 706), "Odwrócony": Vector3(-794, 30, 106),
			"Niskie Dwa": Vector3(-694, 12, 306), "Niskie Równe": Vector3(-694, 10, 506),
			"Granica X": Vector3(1002, 30, 102), "Granica Z": Vector3(1002, 30, 302), "Nieznany": Vector3.INF}
	for name: String in want:
		_expect(_roof_spot(name) == want[name], "M the roof spot of %s: %s (%s)" % [name, str(_roof_spot(name)), str(want[name])])
	var seen := {}
	for i in 40:
		m.offer(2 + 4 * i)
		seen[hud.body.get_slice(", ", 0).trim_prefix("Ktoś utknął na dachu: ")] = true
	var seen_names := seen.keys()
	seen_names.sort()
	_expect(seen_names == ["Dach 20", "Dach 21", "Dwa Dachy", "Dwa Równe", "Garb 1.0", "Garb 1.2", "Odwrócony", "Trzy", "Trójkąt"],
			"M the roofs the roof calls name: 20 and 21 m up, not 19, 7 or 5: %s" % str(seen_names))

	# The peacock: on the first of its four roofs the map has, else on the nearest roof within 700 m of its anchor.
	for name: String in ["Zamek Ujazdowski", "Główna Biblioteka Lekarska im. Stanisława Konopki", "Instytut Teatralny im. Z. Raszewskiego", "Laboratorium"]:
		await _lab(_city([], [_lm(name, -1500.0, -1500.0, 20.0), _lm("Dach Wabik", 500.0, 1700.0, 20.0)]), [_roof(-1500.0, -1500.0, 20.0, 30.0), _roof(500.0, 1700.0, 20.0, 30.0)])
		m.quiet_start(1.0)
		m.request_peacock()
		_expect(hud.body.begins_with("Paw uciekł z Łazienek i paraduje po dachu: %s, 30 m nad ulicą." % name), "M the peacock on %s, far off, with a roof by its anchor: %s" % [name, hud.body])
		hud.press(0)
		_expect(_same(m.target_position(), Vector3(-1494, 30, -1494)), "M and its spot: %s" % str(m.target_position()))
	var ring_lms := []
	var ring_roofs := []
	for r: Array in [["Dach Pierwszy", 1044.0, 1614.0], ["Dach Blisko", 444.0, 1314.0], ["Dach Trzeci", -56.0, 1614.0], ["Puro Dach Zachodni", 344.0, 1614.0],
			["Dach Wschodni", 694.0, 1614.0], ["Dach Południowy", 444.0, 1894.0]]:
		ring_lms.append(_lm(r[0], r[1], r[2], 20.0))
		ring_roofs.append(_roof(r[1], r[2], 20.0, 30.0))
	await _lab(_city([], ring_lms), ring_roofs)
	m.quiet_start(1.0)
	m.request_peacock()
	_expect(m.peacock_open() and hud.body.begins_with("Paw uciekł z Łazienek i paraduje po dachu: Hotel Piure, 30 m nad ulicą."), "M none of the four roofs: the nearest roof to the anchor, under its parody name: %s" % hud.body)
	hud.press(0)
	_expect(_same(m.target_position(), Vector3(350, 30, 1620)), "M and its spot: %s" % str(m.target_position()))
	for row: Array in [["750 m", 1194.0, false], ["700 m", 1144.0, false], ["699 m", 1143.0, true]]:
		await _lab(_city([], [_lm("Dach Daleki", row[1], 1614.0, 20.0)]), [_roof(row[1], 1614.0, 20.0, 30.0)])
		_expect(m.peacock_open() == row[2], "M the only roof %s from the peacock's anchor: it %s: %s" % [row[0], "sits there" if row[2] else "is too far", str(m.peacock_open())])

	# Which hospital: the nearest (the first of two as near), the first when only children's hospitals are left.
	var one_street := [_vroad("A", 0.0, -10.0, 10.0)]
	for row: Array in [["tie", [_hospital("Szpital Pierwszy", 300.0, 0.0), _hospital("Szpital Drugi", -300.0, 0.0)], "Szpital Pierwszy"],
			["children only", [_hospital("Szpital Dziecięcy Jeden", 300.0, 0.0), _hospital("Szpital Dziecięcy Dwa", -100.0, 0.0)], "Szpital Dziecięcy Jeden"]]:
		await _lab(_city(one_street, [], row[1], false), NO_ROOFS)
		m.offer(1)
		_expect(hud.body.contains("Szpital: %s ·" % row[2]), "M hospitals %s: %s" % [row[0], hud.body])
		hud.press(0)
		m.board()
		_expect(_same(m.target_position(), Vector3(300, 0, 0)), "M and its door: %s" % str(m.target_position()))
	# A door's open spot: within 40 m (a hospital with none is left out), 12 directions, 4 m steps.
	var door_roads := [_vroad("A", 300.0, -50.0, 50.0)]
	await _lab(_city(door_roads), [[Rect2(774.5, -35.5, 71.0, 71.0), 10.0]])
	spot = await _door_spot()
	_expect(_same(spot, Vector3(850, 0, 0)), "M a door shut in by a roof: the open spot 40 m off: %s" % str(spot))
	await _lab(_city(door_roads), [[Rect2(773.5, -36.5, 73.0, 73.0), 10.0]])
	m.offer(1)
	_expect(hud.card == "" and not m.can_request(), "M a door with no open spot within 40 m: that hospital is left out, and with it every call: %s" % hud.card)
	await _lab(_city(door_roads), [[Rect2(807.0, -3.0, 6.0, 6.0), 10.0], [Rect2(814.0, -2.0, 10.0, 4.0), 10.0]])
	spot = await _door_spot()
	_expect(_same(spot, Vector3(810, 0, 8)), "M a door shut in at 4 m and to the east: the open spot 8 m north... south of it, the first direction in twelfths: %s" % str(spot))
	# A beach's: within 24 m, else it is no call.
	var beach := [{"k": "beach", "name": "Poniatówka", "x": 400.0, "z": 0.0}]
	await _lab(_city(door_roads, [], beach), [[Rect2(380.5, -19.5, 39.0, 39.0), 10.0]])
	m.offer(3)
	_expect(hud.body.begins_with("Pływak w tarapatach: plaża Poniatówka"), "M a beach with open sky 24 m off is a call: %s" % hud.body)
	hud.press(0)
	_expect(_same(m.target_position(), Vector3(424, 0, 0)), "M its person: %s" % str(m.target_position()))
	await _lab(_city(door_roads, [], beach), [[Rect2(377.5, -22.5, 45.0, 45.0), 10.0]])
	m.offer(3)
	_expect(hud.body.begins_with("Ranny rowerzysta: A."), "M a beach with none within 24 m is no call (the street takes its place): %s" % hud.body)
	# The nearest road's name for a beach with none of its own: by the road's points, last ones too, the first of two as near,
	# no service roads, no unnamed ones.
	for row: Array in [["last vertex", [{"name": "Aleja Druga", "k": "primary", "p": [200.0, 300.0, 250.0, 300.0]}, {"name": "Aleja Trzecia", "k": "primary", "p": [300.0, 300.0, 360.0, 300.0]},
					{"name": "Aleja Zmyłka", "k": "primary", "p": [900.0, 258.0, 300.0, 900.0]}], 258.0, 300.0, "Aleja Druga"],
			["tie", [{"name": "Aleja A", "k": "primary", "p": [30.0, 40.0, 31.0, 41.0]}, {"name": "Aleja B", "k": "primary", "p": [-30.0, -40.0, -31.0, -41.0]}], 0.0, 0.0, "Aleja A"],
			["service and unnamed", [{"name": "Dojazd", "k": "service", "p": [3.0, 0.0, 4.0, 1.0]}, {"name": "", "k": "residential", "p": [2.0, 0.0, 5.0, 1.0]}, {"name": "Aleja Dalsza", "k": "primary", "p": [50.0, 0.0, 60.0, 0.0]}], 0.0, 0.0, "Aleja Dalsza"]]:
		await _lab(_city(row[1], [], [{"k": "beach", "name": "", "x": row[2], "z": row[3]}]), NO_ROOFS, Vector3(0, 0, 500))
		m.offer(3)
		_expect(hud.body.begins_with("Pływak w tarapatach na plaży nad Wisłą (okolice: %s)." % row[4]), "M the nearest road, %s: %s" % [row[0], hud.body])
	# The bent road's point along it, the 0.2 m kink and a road with a doubled first point.
	await _fresh()
	await _names()


## The person of street call 1 in the lab as it stands, once picked up the hospital's door: where the call's drop-off is.
func _door_spot() -> Vector3:
	m.offer(1)
	hud.press(0)
	m.board()
	return m.target_position()


## Every name a person can have turns up, grown-ups' and children's, and no other.
func _names() -> void:
	m.quiet_start(1.0)
	var seen := {}
	for n in range(1, 161):
		m.offer(n)
		_take_aboard()
		seen[dialogue.speakers[-1]] = true
	var heard := seen.keys()
	heard.sort()
	var all: Array = NAMES.duplicate()
	all.append_array(KIDS)
	all.append("Pan Paw")
	all.sort()
	_expect(heard == all, "M the names of the first 160 calls, grown-ups', children's and Pan Paw: %s" % str(heard))


# --- N. the rest -------------------------------------------------------------------------------------------

func _rest() -> void:
	# `start(n)`: the call's card skipped, the pickup on at once.
	m.start(1)
	_expect(int(m.state) == Missions.State.PICKUP and m.number == 1 and m.has_target() and accepted == 1 and hud.card == "",
			"N start(1): no card, the pickup on at once, accepted once: %d %d %d [%s]" % [int(m.state), m.number, accepted, hud.card])
	_expect(hud.toasts[-1] == "Jedziemy! Autem albo helikopterem.", "N start(1)'s toast: %s" % hud.toasts[-1])
	# A call under way is put away by the next card: the beacons go with it (the pickup's, then the drop-off's).
	m.offer(2)
	_expect(not _pickup().visible and not _dropoff().visible and int(m.state) == Missions.State.OFFER, "N a new card while a pickup is on: the pickup's beacon goes")
	m.offer(1)
	hud.press(0)
	m.board()
	_expect(_dropoff().visible, "N aboard: the drop-off's beacon stands")
	m.offer(3)
	_expect(not _pickup().visible and not _dropoff().visible, "N a new card while aboard: the drop-off's beacon goes")
	m.offer(1)
	hud.press(0)
	m.board()
	m.quiet_start(1.0)
	_expect(not _pickup().visible and not _dropoff().visible and hud.card == "", "N the quiet start while aboard: both beacons go")
	m.offer(1)
	hud.press(0)
	m.board()
	hud.abort_pressed.emit()
	_expect(not _pickup().visible and not _dropoff().visible and hud.card == "ZA PÓŹNO", "N called off while aboard: both beacons go, the failure card")
	hud.press(0)
	m.board()
	m.accept()
	_expect(int(m.state) == Missions.State.PICKUP and not _dropoff().visible and _pickup().visible, "N accepting again while aboard: back to the pickup, the drop-off's beacon goes")
	# The helicopter's request and the peacock's are asked once.
	m.quiet_start(1.0)
	m.request_call(true)
	_expect(m.call_needs_heli(), "N the HELI list's call needs the helicopter")
	hud.press(2)
	m.offer(1)
	_expect(hud.card.begins_with("WEZWANIE 1 · RATUNEK NA ULICY") and not m.call_needs_heli(), "N after it and LATER, call 1 is an ordinary street call again: %s" % hud.card)
	hud.press(2)
	m.tick(DT, Vector3(-2000, 0, -1900), 0.0, false)
	m.request_peacock()
	_expect(hud.body.contains("Paw uciekł"), "N the peacock's request: %s" % hud.body)
	hud.press(2)
	m.offer(2)
	_expect(hud.card.begins_with("WEZWANIE 2 · RATUNEK NA DACHU") and not hud.body.contains("Paw"), "N after it and LATER, a roof call from far off is no peacock: %s" % hud.body)
	# `tick` keeps where the player is: the next call measures from there.
	m.tick(DT, Vector3(500, 0, 0), 0.0, false)
	m.offer(5)
	_expect(hud.body.contains("Wspólna.") and hud.body.contains("Od ciebie: ok. 440 m na północny zachód") and hud.body_en.contains("About 440 m north-west of you"), "N after a tick at 500, 0 the call measures from there: %s" % hud.body)
	# The eight directions and the rounding to 10 m, with the player at each side of one street's person at 500, 500.
	await _lab(_city([_vroad("Aleja Kompasowa", 500.0, 450.0, 550.0)]), NO_ROOFS)
	for row: Array in [[Vector3(500, 0, 800), "ok. 300 m na północ", "300 m north"], [Vector3(300, 0, 700), "ok. 280 m na północny wschód", "280 m north-east"],
			[Vector3(250, 0, 500), "ok. 250 m na wschód", "250 m east"], [Vector3(350, 0, 350), "ok. 210 m na południowy wschód", "210 m south-east"],
			[Vector3(500, 0, 150), "ok. 350 m na południe", "350 m south"], [Vector3(700, 0, 300), "ok. 280 m na południowy zachód", "280 m south-west"],
			[Vector3(755, 0, 500), "ok. 260 m na zachód", "260 m west"], [Vector3(620, 0, 620), "ok. 170 m na północny zachód", "170 m north-west"],
			[Vector3(510, 0, 800), "ok. 300 m na północ", "300 m north"]]:
		m.tick(DT, row[0], 0.0, false)
		m.offer(1)
		_expect(hud.body.contains("Od ciebie: %s ·" % row[1]) and hud.body_en.contains("About %s of you." % row[2]), "N from %s the person is %s / %s: %s" % [str(row[0]), row[1], row[2], hud.body])
	# `ring_in` takes a line that has not started (IDLE) and closes it.
	await _fresh()
	_expect(m.ring_in(30.0) and int(m.state) == Missions.State.CLOSED and is_equal_approx(m.call_in(), 30.0), "N ring_in(30) on a line that has not started: closed, 30 s: %d %.1f" % [int(m.state), m.call_in()])
	# K after a rescue: NEXT CALL.
	await _fresh()
	m.quiet_start(1.0)
	m.offer(1)
	hud.press(0)
	m.board()
	_hold_at(DOOR)
	_expect(int(m.state) == Missions.State.RESULT and hud.card == "URATOWANI", "N a rescue done: %d" % int(m.state))
	m.secondary()
	_expect(int(m.state) == Missions.State.OFFER and m.number == 2, "N K on the success card: NEXT CALL: %d %d" % [int(m.state), m.number])
	# Spacer: no clock; the result card counts the time as 0:00 of the fair time.
	await _fresh()
	m.quiet_start(1.0)
	m.calls_off = true
	m.offer(1)
	hud.press(0)
	m.tick(DT, PLAYER, 0.0, false)
	var fair := _clock(_fair(_flat(PLAYER, m.target_position()) + _flat(m.target_position(), DOOR), 9.5))
	_expect(hud.count == fair, "N Spacer's rescue: the clock stands at the fair time: %s (%s)" % [hud.count, fair])
	m.board()
	_hold_at(DOOR)
	_expect(hud.body.contains("Czas 0:00 z %s ·" % fair), "N Spacer's rescue: 0:00 of the fair time on the card: %s" % hud.body)
	# The fair time, to the second.
	await _lab(_city([_vroad("A", 400.0, -50.0, 50.0)]), NO_ROOFS, Vector3(335, 0, 0))
	m.offer(1)
	_expect(hud.body.contains("czas 1:25") and hud.body_en.contains("in 1:25."), "N 475 m by car: 35 s and 50 s, exactly 1:25 with nothing to spare: %s" % hud.body)
	hud.press(0)
	m.tick(DT, Vector3(335, 0, 0), 0.0, false)
	_expect(hud.count == "1:25", "N its clock a tick on: %s" % hud.count)
	await _lab(_city([], [_lm("Wieża", 294.0, -6.0, 20.0)]), [_roof(294.0, -6.0, 20.0, 30.0)], Vector3(300, 0, 0))
	m.offer(2)
	_expect(hud.body.contains("czas 1:15") and hud.body_en.contains("in 1:15."), "N a roof 30 m up, 510 m to the door: 35 s, 30 s by helicopter, 6 s of climb, 1:15: %s" % hud.body)
	hud.press(0)
	m.tick(DT, Vector3(300, 0, 0), 0.0, false)
	_expect(hud.count == "1:15", "N its clock a tick on: %s" % hud.count)
	# Colour-safe: the drop-off turns blue, the pickup stays amber.
	await _fresh()
	Access.color_safe = true
	m.quiet_start(1.0)
	m.offer(1)
	hud.press(0)
	_expect(m.target_colour() == AMBER, "N colour-safe: the pickup stays amber")
	m.board()
	_expect(m.target_colour() == BLUE, "N colour-safe: the drop-off is blue: %s" % m.target_colour().to_html())
	m.tick(DT, DOOR, 0.0, false)
	_expect(hud.tint == BLUE, "N colour-safe: the status line blue: %s" % hud.tint.to_html())
	_hold_at(DOOR)
	_expect(hud.accent == BLUE and hud.card == "URATOWANI", "N colour-safe: the success card blue: %s" % hud.accent.to_html())
	Access.color_safe = false
