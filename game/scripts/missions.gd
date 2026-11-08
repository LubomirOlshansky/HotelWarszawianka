extends Node
## Rescue missions. A call comes in for a person at a real place on the map: the
## roof of a named building, a named street, a park or square, a Vistula beach or
## sandbar. The player gets there, holds still next to them for a moment, then
## brings them to a real hospital before the clock runs out. Every place comes
## from the baked map data (landmarks, roads and pois in centrum.json). The person
## says a line when picked up, the crew another at the hospital (dialogue.gd), and
## a rescue pays złoty and respect (wallet.gd). Loop 2e: no card at the start: a call comes in
## during play (FIRST_CALL seconds in, then NEXT_CALL after each one ends or is put off) and
## waits as the HUD's context button, WEZWANIE, until the player opens it.

## Loop 3g-2 (police.md 8.1): a call was accepted (police.gd ends a chase).
signal accepted

const Gamepad := preload("res://scripts/gamepad.gd")  # the pad's A in the call toast (2026-11-03)
const Access := preload("res://scripts/access.gd")
const Haptics := preload("res://scripts/haptics.gd")
const Beacon := preload("res://scripts/beacon.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

const StopAssist := preload("res://scripts/stop_assist.gd")
const HOLD_TIME := 1.5
const CAR_REACH := StopAssist.RING          # stop this close to the person...
const CAR_STOPPED := StopAssist.STOP_SPEED  # ...going no faster than this (m/s)
const HELI_REACH := 8.0      # hover or land this close...
const HELI_LOW := 4.0        # ...with the skids no higher above the person than this
const MIN_ROOF := 20.0       # a roof rescue is at least this high above the street
## A rescue roof named after a real chain shows our parody instead (found 2026-11-01): lower-case
## fragment of the OSM name, then the name the player reads. The landmark keeps its OSM name as the key.
const ROOF_PARODIES := {"puro": "Hotel Piure", "caffè nero": "Green Caffè Nerwo", "caffe nero": "Green Caffè Nerwo"}
const ROOF_LOW := 6.0        # cassettes.gd: a roof for a cassette is at least this high
const OPEN_RADIUS := 4.5     # street spots need this much open sky for the helicopter
## Map north: rescue spots keep this far inside the map's outline (map_builder.gd `in_map`; it was
## the bounding box shrunk by as much, which let a spot fall in the corner left outside).
const EDGE_PAD := 40.0
const PICKUP_COLOUR := Color("#ffc23a")
const DROPOFF_COLOUR := Color("#56d68a")
## Colour-safe (access.gd): the drop-off turns blue, so pickup and drop-off differ in more than
## green against amber.
const DROPOFF_SAFE := Color("#4aa3ff")
const FAIL_COLOUR := Color("#e2574c")

enum Kind { STREET, ROOF, RIVER, PARK }
## Mission n is of kind ORDER[(n - 1) % 4], so --mission=2 is always a roof.
const ORDER := [Kind.STREET, Kind.ROOF, Kind.RIVER, Kind.PARK]
const TITLES := ["STREET RESCUE", "ROOF RESCUE", "RIVER RESCUE", "PARK RESCUE"]
## Loop 2e: the cards, the status and the toasts in Polish, the English under it.
const TITLES_PL := ["RATUNEK NA ULICY", "RATUNEK NA DACHU", "RATUNEK NAD WISŁĄ", "RATUNEK W PARKU"]
## DEMO 6.3: the Łazienki peacock. Łazienki itself lies just south of the demo map; its peacocks
## wander north over Agrykola and Ujazdów, so one ends up on a roof by Park Ujazdowski: the first of
## these buildings with a roof the helicopter can land on (else the nearest roof rescue within
## PEACOCK_NEAR of PEACOCK_ANCHOR, map metres). A roof call within PEACOCK_REACH of the player
## offers the peacock first, once per session.
const PEACOCK_ROOFS := ["Zamek Ujazdowski", "Główna Biblioteka Lekarska im. Stanisława Konopki",
		"Instytut Teatralny im. Z. Raszewskiego", "Laboratorium"]
const PEACOCK_ANCHOR := Vector2(450.0, 1620.0)
const PEACOCK_NEAR := 700.0
const PEACOCK_REACH := 2600.0
const PEACOCK_NAME := "Pan Paw"
enum State { IDLE, OFFER, CLOSED, PICKUP, DROPOFF, RESULT, RINGING }
## Loop 2e: seconds of play before the first call comes in, and between calls (first guesses;
## docs/DEMO.md 6.2 puts the first rescue at 4:00 in the scripted first ten minutes).
const FIRST_CALL := 60.0
const NEXT_CALL := 90.0

var map: Node3D
var hud: CanvasLayer
var state := State.IDLE
var number := 0
var total_score := 0
## Where the player is, kept by tick(); new calls come from places near it.
var player := Vector3.ZERO
## A street race or a side job is on: no calls until it ends (one activity at a time).
var paused := false
## Set by the game: the wallet, everybody's lines, and where the vehicle's cabin is.
var wallet: Node
var dialogue: Node
var vehicle_anchor: Callable
## Who needs rescuing: first names only.
const NAMES := ["Ania", "Kuba", "Ola", "Tomek", "Zosia", "Bartek", "Magda", "Piotrek", "Ewa", "Marek"]
const KIDS := ["Staś", "Zuzia", "Antek", "Hania"]

## Kind -> places: {kind, name, short, text, pos, heli, child}.
var _places := {}
## Landmark name -> its outlines (PackedVector2Array each), for `roof_spot`.
var _outlines := {}
## The peacock's call (a ROOF place with "peacock": true), {} if no roof near Ujazdów fits; and
## whether this session has rescued it.
var _peacock: Dictionary = {}
var _peacock_done := false
var _hospitals: Array[Dictionary] = []
var _mission: Dictionary = {}
var _success := false
var _time_left := 0.0
var _limit := 0.0
var _hold := 0.0
var _road_points := PackedVector2Array()
var _road_names := PackedStringArray()
var _pickup: Node3D
var _dropoff: Node3D
## Loop 2e: seconds until the next call comes in (counted only while nothing else runs).
var _call_in := -1.0
## Loop MW-6: Spacer (spacer.gd): no call comes in by itself, and a rescue runs without its clock.
var calls_off := false
## Loop 3h slice 4: the guided first 10 minutes (first10.gd) hold the first call until its beat
## (about 4:00, after the first race): the countdown stands still while this is on.
var held := false
## G12: the calls that come in by themselves follow the vehicle (flying: heli-only places;
## driving: places the car reaches). Off for --mission and the checks, which ask for a kind.
var line_split := false
var _flying := false
## G12 part 2: the next call is a helicopter's (the HELI list's "rescue call" request), once.
var _want_heli := false
## G12c: the next call is the peacock's (the HELI list's "Pan Paw" request), once.
var _want_peacock := false


func setup(map_node: Node3D, data: Dictionary, world: Node3D, hud_layer: CanvasLayer) -> void:
	map = map_node
	hud = hud_layer
	for k in ORDER:
		_places[k] = []
	var t0 := Time.get_ticks_msec()
	_collect_road_names(data["roads"])
	await LoadYield.tick("missions roads")
	_find_roofs(data.get("landmarks", []))
	await LoadYield.tick("missions roofs")
	_find_peacock()
	await LoadYield.tick("missions peacock")
	_find_streets(data["roads"])
	await LoadYield.tick("missions streets")
	_find_pois(data.get("pois", []))
	await LoadYield.tick("missions pois")
	print("missions: %d roofs (peacock %s), %d streets, %d riverside, %d parks, %d hospitals in %d ms" % [
			_places[Kind.ROOF].size(), str(_peacock.get("short", "none")), _places[Kind.STREET].size(), _places[Kind.RIVER].size(),
			_places[Kind.PARK].size(), _hospitals.size(), Time.get_ticks_msec() - t0])
	# Sweep 2: the haptic engine is built now, while the city loads, not at the first call.
	var t1 := Time.get_ticks_usec()
	if warm_haptics():
		print("haptics: engine built and starting in %.1f ms (sweep 2)" % ((Time.get_ticks_usec() - t1) / 1000.0))
	await LoadYield.tick("missions haptics")

	_pickup = Beacon.new()
	world.add_child(_pickup)
	_pickup.setup(PICKUP_COLOUR, Color("#e8762e"))
	_pickup.pattern = Beacon.Pattern.DASHED  # colour-safe: someone waiting (beacon.gd)
	_dropoff = Beacon.new()
	world.add_child(_dropoff)
	# The plain green: the beacon tints it blue itself under colour-safe, also when the
	# setting changes mid-call (it was fixed at load before).
	_dropoff.setup(DROPOFF_COLOUR, Color("#f2efe8"))
	_dropoff.waving = false
	hud.card_pressed.connect(_on_card)
	hud.pill_pressed.connect(func(): offer(number + 1))
	hud.abort_pressed.connect(func():
		if has_target():
			_finish(false, ["Akcja odwołana.", "You called the rescue off."]))


# --- the flow -------------------------------------------------------------------

## Shows the call card for mission n.
func offer(n: int) -> void:
	if _hospitals.is_empty() or paused:
		return
	number = n
	_mission = _make(n)
	state = State.OFFER
	_pickup.visible = false
	_dropoff.visible = false
	hud.hide_status()
	hud.hide_pill()
	var limit := _limit_for(_mission)
	var where := _where(_mission["pos"])
	hud.show_card("WEZWANIE %d · %s" % [n, TITLES_PL[_mission["kind"]]],
			"%s\nOd ciebie: %s · Szpital: %s · czas %s" % [_mission["text_pl"], where[0], _mission["hospital"]["name"], _clock(limit)],
			PackedStringArray(["ACCEPT", "SKIP", "LATER"]), PICKUP_COLOUR, false,
			"Call %d · %s" % [n, TITLES[_mission["kind"]].to_lower()],
			"%s About %s of you. Get them to the hospital in %s." % [_mission["gloss"], where[1], _clock(limit)])


const COMPASS_PL := ["na północ", "na północny wschód", "na wschód", "na południowy wschód", "na południe", "na południowy zachód", "na zachód", "na północny zachód"]
const COMPASS_EN := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]


## Where `at` lies from the player: [Polish, English] such as "ok. 420 m na północ" / "420 m north"
## (map +x is east, -z is north). The card said only the street, so nobody knew which way to go.
func _where(at: Vector3) -> Array:
	var d := Vector2(at.x - player.x, at.z - player.z)
	var metres := int(round(d.length() / 10.0)) * 10
	var i := int(round(fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0) / 45.0)) % 8
	return ["ok. %d m %s" % [metres, COMPASS_PL[i]], "%d m %s" % [metres, COMPASS_EN[i]]]


## Offers mission n and accepts it at once (the --mission flag).
func start(n: int) -> void:
	offer(n)
	print("rescue call %d: %s" % [n, _mission.get("short", "?")])
	accept()


func accept() -> void:
	if _mission.is_empty():
		return
	state = State.PICKUP
	_limit = _limit_for(_mission)
	_time_left = _limit
	_hold = 0.0
	hud.hide_card()
	_dropoff.visible = false
	_pickup.waving = true
	_pickup.recolour(target_colour())
	_pickup.place(_mission["pos"], HELI_REACH if _mission["heli"] else CAR_REACH)
	hud.toast("Jedziemy! " + ("Tylko helikopterem." if _mission["heli"] else "Autem albo helikopterem."),
			"Go! " + ("Take the helicopter." if _mission["heli"] else "Car or helicopter."))
	accepted.emit()


## Loop 3g-2 (police.md 8.1): seconds added to the rescue clock (the police escort's +10 s).
func add_time(seconds: float) -> void:
	if has_target():
		_time_left += seconds
		print("rescue clock +%.0f s (%s left)" % [seconds, _clock(_time_left)])


## Loop 3g-2, --escort: the person is aboard at once (a pickup's call goes straight to the drop-off).
func board() -> void:
	if state == State.PICKUP and not _mission["heli"]:
		_picked_up()


## Hides the card; the next call comes in NEXT_CALL seconds later (loop 2e: it was a RESCUE
## CALLS button waiting on screen).
func close() -> void:
	state = State.CLOSED
	_call_in = NEXT_CALL
	_pickup.visible = false
	_dropoff.visible = false
	hud.hide_card()
	hud.hide_status()
	hud.hide_pill()


## Loop 2e: the game starts with nothing on screen; the first call comes in `first` seconds
## later (FIRST_CALL by default, --call-in=S).
func quiet_start(first := -1.0) -> void:
	close()
	_call_in = first if first >= 0.0 else FIRST_CALL


## Loop 3h slice 4: the next call comes in `seconds` from now (first10.gd's rescue beat), unless
## one is on or ringing already. Returns true when the countdown was set.
func ring_in(seconds: float) -> bool:
	if state != State.CLOSED and state != State.IDLE:
		return false
	state = State.CLOSED
	_call_in = seconds
	return true


## G12 part 2: a rescue call may be asked for now (the HELI list's request): no call on, ringing
## or counting down past the guide's hold, and calls not switched off.
func can_request() -> bool:
	return (state == State.CLOSED or state == State.RINGING) and not calls_off and not held and not paused \
			and not _hospitals.is_empty()


## G12 part 2: the HELI list's request: a call only the helicopter reaches (a roof or a sandbar,
## Lines.kind_for / prefer as if flying) on the card now, ACCEPT / SKIP / LATER as any call.
func request_call(heli := true) -> void:
	if not can_request():
		return
	_want_heli = heli
	offer(number + 1)
	_want_heli = false


## G12c: the peacock is still on its roof this session (the HELI list offers its call).
func peacock_open() -> bool:
	return not _peacock.is_empty() and not _peacock_done


## G12c: the HELI list's peacock request: Pan Paw's roof call on the card now, from anywhere on the
## map (not only within PEACOCK_REACH), ACCEPT / SKIP / LATER as any call.
func request_peacock() -> void:
	if not can_request() or not peacock_open():
		return
	_want_peacock = true
	offer(number + 1)
	_want_peacock = false


## Loop 3h slice 4: the call on the card or under way can only be reached by the helicopter
## (first10.gd unlocks it then, even before the first rescue is done).
func call_needs_heli() -> bool:
	return (state == State.OFFER or state == State.PICKUP) and bool(_mission.get("heli", false))


## Loop 3h slice 4: the seconds until the next call (-1: none counting).
func call_in() -> float:
	return _call_in


# --- sweep 2: the first call's hitch --------------------------------------------------------
## The first rescue call's hitch (61 ms on the iPhone 11, 100-117 ms on the Pro Max) is its
## buzz, as far as the Mac can tell: there the call costs 0.3 ms of script, compiles no
## pipeline and its frame is an ordinary one, and the buzz is the only part that does
## anything different on the phone. On iOS the first Input.vibrate_handheld builds Core
## Haptics' engine (CHHapticEngine init, a synchronous handshake with the system's haptic
## server) and starts it inside that frame; the engine shuts itself down when idle, so a
## later buzz starts it again. The engine is built at load instead (behind the loading
## screen) and started without waiting (startWithCompletionHandler), and started again
## HAPTICS_LEAD seconds before each call rings. Every other buzz (bumps, jobs, races) finds
## the engine built too.
const HAPTICS_LEAD := 2.0


## Builds the haptic engine if it isn't yet and starts it without waiting (haptics.gd warm();
## the engine's singleton exists on iPhone builds only; elsewhere this does nothing). True when it ran.
static func warm_haptics() -> bool:
	return Haptics.warm()
# --- end sweep 2 ---------------------------------------------------------------------------


## Loop 2e: a call came in: the context button (WEZWANIE · rescue call) waits until pressed.
func _ring() -> void:
	if _hospitals.is_empty():
		return
	state = State.RINGING
	hud.show_pill("WEZWANIE", "rescue call")
	if hud.pad_mode:
		hud.toast(Gamepad.fmt("Wezwanie ratunkowe! {a}: odbierz."), Gamepad.fmt("A rescue call came in: {a} to answer."))
	else:
		hud.toast("Wezwanie ratunkowe!", "A rescue call came in: tap the button at the top.")
	# Sweep 2: the buzz is timed so the phone's log shows the call's hitch is gone (it was
	# the haptic engine starting inside this frame: warm_haptics()).
	var t0 := Time.get_ticks_usec()
	Access.buzz(40, 0.5)
	print("rescue call ringing (buzz %.1f ms)" % ((Time.get_ticks_usec() - t0) / 1000.0))


## Keyboard: M answers the card's first button (or opens the next call).
func primary() -> void:
	if paused:
		return
	match state:
		State.OFFER, State.RESULT:
			_on_card(0)
		State.CLOSED, State.RINGING:
			offer(number + 1)


## Keyboard: N skips a call, or moves on to the next call from a result.
func secondary() -> void:
	if paused:
		return
	match state:
		State.OFFER:
			_on_card(1)
		State.RESULT:
			_on_card(0 if _success else 1)


## Card buttons: an offer is ACCEPT / SKIP / LATER, a success NEXT CALL / FREE ROAM,
## a failure TRY AGAIN / NEXT CALL / FREE ROAM.
func _on_card(index: int) -> void:
	if state == State.RESULT and _success:
		index += 1  # no TRY AGAIN button
	if state == State.OFFER:
		if index == 0:
			accept()
		elif index == 1:
			offer(number + 1)
		else:
			close()
	elif state == State.RESULT:
		if index == 0:
			accept()  # the same call again, timed from here
		elif index == 1:
			offer(number + 1)
		else:
			close()


func has_target() -> bool:
	return state == State.PICKUP or state == State.DROPOFF


func target_position() -> Vector3:
	return _mission["pos"] if state == State.PICKUP else _mission["hospital"]["pos"]


## Where the car should stop now (stop_assist.gd; Vector3.INF: nowhere, e.g. a helicopter-only
## pickup).
func stop_spot() -> Vector3:
	if not has_target() or (state == State.PICKUP and _mission["heli"]):
		return Vector3.INF
	return target_position()


func _dropoff_colour() -> Color:
	return DROPOFF_SAFE if Access.color_safe else DROPOFF_COLOUR


func target_colour() -> Color:
	if state == State.PICKUP:
		return Lines.HELI_COLOUR if bool(_mission.get("heli", false)) else PICKUP_COLOUR
	return _dropoff_colour()


## True while the person still waits somewhere only the helicopter reaches.
func needs_heli() -> bool:
	return state == State.PICKUP and _mission["heli"]


## Runs the clock and checks for pick-up and hand-over. `pos` is the vehicle
## (the bottom of the skids for the helicopter), `speed` its speed in m/s.
func tick(dt: float, pos: Vector3, speed: float, flying: bool) -> void:
	player = pos
	_flying = flying
	if state == State.CLOSED and not paused and _call_in >= 0.0 and not calls_off and not held:
		# Sweep 2: start the haptic engine a moment before the call (it stops itself when idle).
		if _call_in >= HAPTICS_LEAD and _call_in - dt < HAPTICS_LEAD:
			warm_haptics()
		_call_in -= dt
		if _call_in < 0.0:
			_ring()
	if not has_target():
		return
	if not calls_off:
		_time_left -= dt
	if _time_left <= 0.0:
		_finish(false, ["Czas minął. Przejęła inna załoga.", "Out of time. Another crew took over."])
		return
	var target := target_position()
	var d := Vector2(pos.x - target.x, pos.z - target.z).length()
	var dy := pos.y - target.y
	var picking := state == State.PICKUP
	var ok := false
	var hint := ["", ""]
	if picking and _mission["heli"] and not flying:
		hint = ["Tam dotrze tylko helikopter: HELI (H)", "Only the helicopter gets there: press HELI (H)"]
	elif d > 40.0:
		hint = ["Jedź do żółtego światła", "Head for the yellow beacon"] if picking \
				else ["Pacjent na pokładzie: do zielonego światła", "Patient on board: head for the green beacon"]
	elif flying:
		ok = d <= HELI_REACH and dy < HELI_LOW and dy > -1.0
		if dy >= HELI_LOW:
			hint = ["Niżej: do 4 m nad nimi (▼ / F)", "Go down: within 4 m of them (▼ / F)"]
		elif d > HELI_REACH:
			hint = ["Leć nad krąg", "Move over the ring"]
	else:
		ok = d <= CAR_REACH and speed < CAR_STOPPED and absf(dy) < 2.5
		if d > CAR_REACH:
			hint = ["Stań w kręgu", "Stop inside the ring"]
		elif speed >= CAR_STOPPED:
			hint = ["Stań, żeby ich zabrać", "Stop to pick them up"] if picking else ["Stań, żeby ich przekazać", "Stop to hand them over"]
	if ok:
		_hold += dt
		hint = ["Nie ruszaj się… zabieramy", "Hold still… picking up"] if picking else ["Nie ruszaj się… przekazujemy", "Hold still… handing over"]
	else:
		_hold = 0.0
	if _hold >= HOLD_TIME:
		_hold = 0.0
		if picking:
			_picked_up()
		else:
			_finish(true, [])
		return
	var where: String = _mission["short_pl"] if picking else _mission["hospital"]["name"]
	hud.show_status(("ODBIÓR · " if picking else "DO SZPITALA · ") + where, _clock(_time_left), "%d m" % roundi(d),
			hint[0], _hold / HOLD_TIME, target_colour(), "", {}, hint[1])


func _picked_up() -> void:
	state = State.DROPOFF
	_pickup.visible = false
	var h: Dictionary = _mission["hospital"]
	_dropoff.place(h["pos"], CAR_REACH)
	hud.toast("Zabrani! Teraz: " + h["name"], "Picked up! Now to " + h["name"])
	Access.buzz(60, 0.6)
	if dialogue != null and vehicle_anchor.is_valid():
		dialogue.say(vehicle_anchor, _mission["who"], "rescue_person", _tag(), 4.5, PICKUP_COLOUR, 0.0)


## Which rescue lines fit this call: "roof", "street", "river", "child" or "square".
func _tag() -> String:
	match int(_mission["kind"]):
		Kind.ROOF:
			return "peacock" if _mission.get("peacock", false) else "roof"
		Kind.RIVER:
			return "river"
		Kind.PARK:
			return "child" if _mission["child"] else "square"
	return "street"


## `why`: [Polish, English] (a failure's reason).
func _finish(success: bool, why: Array) -> void:
	_success = success
	state = State.RESULT
	print("rescue %s: %s, %s left" % ["done" if success else "failed", _mission["short"], _clock(_time_left)])
	hud.hide_status()
	if success:
		var route := _flat(_mission["pos"], _mission["hospital"]["pos"])
		if _mission.get("peacock", false):
			_peacock_done = true
		var score := 500 + int(_time_left) * 10 + int(route / 4.0)
		total_score += score
		var pay := roundi(score * 0.08)
		if wallet != null:
			wallet.pay(pay, 40, "rescue")
		# The patient stands with the hospital crew; the light goes out.
		var at: Vector3 = _mission["hospital"]["pos"]
		_dropoff.place(at, CAR_REACH + 2.0, false, true)
		_pickup.waving = false
		_pickup.place(at + Vector3(1.6, 0, 0.8), HELI_REACH, false, true)
		hud.show_card("URATOWANI", "Cali i zdrowi: %s.\nCzas %s z %s · punkty +%d (razem %d) · +%d zł" % [
				_mission["hospital"]["name"], _clock(_limit - _time_left), _clock(_limit), score, total_score, pay],
				PackedStringArray(["NEXT CALL", "FREE ROAM"]), _dropoff_colour(), false, "Rescued",
				"Safe and sound at the hospital: time, score and pay above.")
		Access.buzz(120, 0.8)
		if dialogue != null:
			dialogue.say(_dropoff, "Ratownik", "rescue_done", "peacock" if _mission.get("peacock", false) else "", 5.0, _dropoff_colour(), 3.6)
	else:
		_pickup.visible = false
		_dropoff.visible = false
		hud.show_card("ZA PÓŹNO", "%s Punkty razem: %d." % [why[0], total_score],
				PackedStringArray(["TRY AGAIN", "NEXT CALL", "FREE ROAM"]), FAIL_COLOUR, false, "Too late",
				"%s Score total %d." % [why[1], total_score])


## The call for mission n: a place of its kind a short trip from the player
## (a seeded pick, so the same start gives the same call), and a hospital.
func _make(n: int) -> Dictionary:
	var kind: int = ORDER[(n - 1) % ORDER.size()]
	var fly := _flying or _want_heli
	if line_split or _want_heli:
		kind = Lines.kind_for(kind, fly)
	if (_want_peacock and peacock_open()) or (kind == Kind.ROOF and peacock_open() \
			and _flat(player, _peacock["pos"]) <= PEACOCK_REACH):
		var pm: Dictionary = _peacock.duplicate()
		pm["hospital"] = _hospital_for(_peacock)
		pm["who"] = PEACOCK_NAME
		return pm
	var list: Array = _places[kind]
	if list.is_empty():
		list = _places[Kind.STREET]
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + 17
	if line_split or _want_heli:
		list = Lines.prefer(list, fly)
	var by_distance := list.duplicate()
	by_distance.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _flat(player, a["pos"]) < _flat(player, b["pos"]))
	var near := by_distance.filter(func(p: Dictionary) -> bool: return _flat(player, p["pos"]) >= 150.0 and _flat(player, p["pos"]) <= 1100.0)
	if near.size() < 3:
		# Nothing much in reach (the river from the west end): one of the three nearest.
		near = by_distance.filter(func(p: Dictionary) -> bool: return _flat(player, p["pos"]) >= 60.0).slice(0, 3)
	if near.is_empty():
		near = by_distance
	var place: Dictionary = near[rng.randi() % near.size()]
	var m := place.duplicate()
	m["hospital"] = _hospital_for(place)
	m["who"] = KIDS[rng.randi() % KIDS.size()] if place["child"] else NAMES[rng.randi() % NAMES.size()]
	return m


## The nearest hospital; the children's hospital takes only children.
func _hospital_for(place: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for h in _hospitals:
		if h["children"] and not place["child"]:
			continue
		if best.is_empty() or _flat(place["pos"], h["pos"]) < _flat(place["pos"], best["pos"]):
			best = h
	return best if not best.is_empty() else _hospitals[0]


## A fair time: the straight-line trip at a city pace, the climb to a roof, and slack.
func _limit_for(m: Dictionary) -> float:
	var route := _flat(player, m["pos"]) + _flat(m["pos"], m["hospital"]["pos"])
	var pos: Vector3 = m["pos"]
	var climb := maxf(0.0, pos.y - map.ground_height(pos.x, pos.z)) / 5.0
	var t := 35.0 + route / (17.0 if m["heli"] else 9.5) + climb
	return ceilf(t / 5.0) * 5.0


# --- finding places -------------------------------------------------------------

## The name a roof is shown under: the parody when the OSM name holds a real chain.
static func roof_shown(name: String) -> String:
	var low := name.to_lower()
	for frag: String in ROOF_PARODIES:
		if low.contains(frag):
			return ROOF_PARODIES[frag]
	return name


func _find_roofs(landmarks: Array) -> void:
	var best := {}
	for l in landmarks:
		var name: String = l["name"]
		var poly := _pts(l["p"])
		if not _outlines.has(name):
			_outlines[name] = []
		(_outlines[name] as Array).append(poly)
		var spot := _flat_roof(poly)
		if spot == Vector3.INF or (best.has(name) and (best[name]["pos"] as Vector3).y >= spot.y):
			continue
		var up := roundi(spot.y - map.ground_height(spot.x, spot.z))
		var shown := roof_shown(name)
		best[name] = {"kind": Kind.ROOF, "name": name, "short": "roof of " + shown, "pos": spot, "heli": true, "child": false,
				"short_pl": "dach: " + shown, "gloss": "Someone is stuck on a roof %d m up: helicopter only." % up,
				"text": "Someone is stranded on the roof of %s, %d m up. Only the helicopter can reach them." % [shown, up],
				"text_pl": "Ktoś utknął na dachu: %s, %d m nad ulicą. Dotrze tylko helikopter." % [shown, up]}
	_places[Kind.ROOF].append_array(best.values())


## DEMO 6.3: the peacock's roof (see PEACOCK_ROOFS); {} when none fits.
func _find_peacock() -> void:
	var roof := ""
	var spot := Vector3.INF
	for name in PEACOCK_ROOFS:
		spot = roof_spot(name)
		if spot != Vector3.INF:
			roof = name
			break
	if spot == Vector3.INF:
		var best := PEACOCK_NEAR
		for p: Dictionary in _places[Kind.ROOF]:
			var d := Vector2(p["pos"].x, p["pos"].z).distance_to(PEACOCK_ANCHOR)
			if d < best:
				best = d
				roof = p["name"]
				spot = p["pos"]
	if spot == Vector3.INF:
		return
	var up := roundi(spot.y - map.ground_height(spot.x, spot.z))
	roof = roof_shown(roof)
	_peacock = {"kind": Kind.ROOF, "name": PEACOCK_NAME, "short": "peacock on " + roof, "pos": spot, "heli": true,
			"child": false, "peacock": true, "short_pl": "paw na dachu: " + roof,
			"gloss": "A peacock escaped from Łazienki and sits on a roof %d m up: helicopter only." % up,
			"text": "A peacock has escaped from Łazienki and is strutting on the roof of %s, %d m up. Only the helicopter can reach it." % [roof, up],
			"text_pl": "Paw uciekł z Łazienek i paraduje po dachu: %s, %d m nad ulicą. Dotrze tylko helikopter." % [roof, up]}


## The first-10 polish (cassettes.gd): the roof spot of the landmark `name`: the rescue's own pick
## (its highest flat spot), else the highest flat spot at least ROOF_LOW m up (a roof too low for a
## rescue, like the University Library's garden roof); Vector3.INF if it has none.
func roof_spot(name: String) -> Vector3:
	for p: Dictionary in _places.get(Kind.ROOF, []):
		if p["name"] == name:
			return p["pos"]
	var best := Vector3.INF
	for poly: PackedVector2Array in _outlines.get(name, []):
		var spot := _flat_roof(poly, ROOF_LOW)
		if spot != Vector3.INF and (best == Vector3.INF or spot.y > best.y):
			best = spot
	return best


## The highest spot on a building's roof that is flat enough to land on (the
## cells around it within a metre of it), or Vector3.INF.
func _flat_roof(poly: PackedVector2Array, min_up := MIN_ROOF) -> Vector3:
	if poly.size() < 3:
		return Vector3.INF
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var cell := MapBuilder.ROOF_CELL
	var best := Vector3.INF
	var best_h := -INF
	var z := lo.y + cell * 0.5
	while z < hi.y:
		var x := lo.x + cell * 0.5
		while x < hi.x:
			var p := Vector2(x, z)
			var h: float = map.roof_height(x, z)
			if h > best_h and map.in_map(p, -EDGE_PAD) and Geometry2D.is_point_in_polygon(p, poly) \
					and h - map.ground_height(x, z) >= min_up and _is_flat(x, z, h, cell):
				best_h = h
				best = Vector3(x, h, z)
			x += cell
		z += cell
	return best


func _is_flat(x: float, z: float, h: float, cell: float) -> bool:
	for j in range(-1, 2):
		for i in range(-1, 2):
			if absf(map.roof_height(x + i * cell, z + j * cell) - h) > 1.0:
				return false
	return true


## One spot per named street: the open point nearest the middle of its longest piece.
func _find_streets(roads: Array) -> void:
	var best := {}
	for r in roads:
		var name: String = r["name"]
		if name == "" or r["k"] == "service":
			continue
		var poly := _pts(r["p"])
		var length := 0.0
		for i in poly.size() - 1:
			length += poly[i].distance_to(poly[i + 1])
		if best.has(name) and float(best[name][0]) >= length:
			continue
		var s := 0.0
		while s <= length * 0.5:
			var spot := Vector3.INF
			for along in [length * 0.5 + s, length * 0.5 - s]:
				var p := _point_along(poly, along)
				if _is_open(p.x, p.y):
					spot = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
					break
			if spot != Vector3.INF:
				best[name] = [length, spot]
				break
			s += 6.0
	for name in best:
		var at := "at" if name.begins_with("Plac") or name.begins_with("Rondo") else "on"
		_places[Kind.STREET].append({"kind": Kind.STREET, "name": name, "short": name, "pos": best[name][1],
				"heli": false, "child": false, "short_pl": name, "gloss": "A cyclist is hurt: the car or the helicopter will do.",
				"text": "A cyclist is hurt %s %s. The car or the helicopter will do." % [at, name],
				"text_pl": "Ranny rowerzysta: %s. Wystarczy auto albo helikopter." % name})


func _find_pois(pois: Array) -> void:
	for p in pois:
		var kind: String = p["k"]
		# The side jobs' and easter eggs' places (kebab stands, addresses...) are not calls.
		if not kind in ["hospital", "beach", "shore", "sandbar", "park", "square"]:
			continue
		var name: String = p["name"]
		var x := float(p["x"])
		var z := float(p["z"])
		if kind == "hospital":
			var door: Array = p["door"]
			var spot := _open_near(float(door[0]), float(door[1]), 40.0)
			if spot != Vector3.INF:
				_hospitals.append({"name": name, "pos": spot, "children": name.to_lower().contains("dzieci")})
			continue
		var spot := _open_near(x, z, 24.0)
		if spot == Vector3.INF:
			continue
		var place := {"name": name, "pos": spot, "heli": false, "child": false}
		match kind:
			"beach":
				place["kind"] = Kind.RIVER
				if name != "":
					place["short"] = name + " beach"
					place["short_pl"] = "plaża " + name
					place["gloss"] = "A swimmer is in trouble on a Vistula beach."
					place["text"] = "A swimmer is in trouble at %s, the beach on the Vistula." % name
					place["text_pl"] = "Pływak w tarapatach: plaża %s nad Wisłą." % name
				else:
					place["short"] = "Vistula beach"
					place["short_pl"] = "plaża nad Wisłą"
					place["gloss"] = "A swimmer is in trouble on a Vistula beach."
					place["text"] = "A swimmer is in trouble on a Vistula beach near %s." % _nearest_road(x, z)
					place["text_pl"] = "Pływak w tarapatach na plaży nad Wisłą (okolice: %s)." % _nearest_road(x, z)
			"shore":
				place["kind"] = Kind.RIVER
				place["short"] = "Vistula shore"
				place["short_pl"] = "brzeg Wisły"
				place["gloss"] = "Someone slipped on the Vistula shore: car or helicopter."
				place["text"] = "Someone slipped on the Vistula shore near %s. The car or the helicopter will do." % _nearest_road(x, z)
				place["text_pl"] = "Ktoś poślizgnął się na brzegu Wisły (okolice: %s). Wystarczy auto albo helikopter." % _nearest_road(x, z)
			"sandbar":
				place["kind"] = Kind.RIVER
				place["heli"] = true
				place["short"] = "Vistula sandbar"
				place["short_pl"] = "łacha na Wiśle"
				place["gloss"] = "Someone is stranded on a Vistula sandbar: helicopter only."
				place["text"] = "Someone is stranded on a sandbar in the Vistula near %s. Only the helicopter can reach them." % _nearest_road(x, z)
				place["text_pl"] = "Ktoś utknął na łasze na Wiśle (okolice: %s). Dotrze tylko helikopter." % _nearest_road(x, z)
			"park":
				place["kind"] = Kind.PARK
				place["child"] = true
				place["short"] = name
				place["short_pl"] = name
				place["text"] = "A child fell off a climbing frame in %s." % name
				place["text_pl"] = "Dziecko spadło z drabinek: %s." % name
				place["gloss"] = "A child fell off a climbing frame."
			"square":
				place["kind"] = Kind.PARK
				place["short"] = name
				place["short_pl"] = name
				place["text"] = "A tourist fainted at %s." % name
				place["text_pl"] = "Turystka zemdlała: %s." % name
				place["gloss"] = "A tourist fainted."
			_:
				continue
		_places[place["kind"]].append(place)


## Open sky: no building within OPEN_RADIUS, so the helicopter can come down too.
func _is_open(x: float, z: float) -> bool:
	return map.in_map(Vector2(x, z), -EDGE_PAD) and map.top_height(x, z, OPEN_RADIUS) <= map.ground_height(x, z) + 1.5


## The point itself if it's open, else the nearest open point within `reach` metres.
func _open_near(x: float, z: float, reach: float) -> Vector3:
	var r := 0.0
	while r <= reach:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * k / steps
			var px := x + cos(a) * r
			var pz := z + sin(a) * r
			if _is_open(px, pz):
				return Vector3(px, map.ground_height(px, pz), pz)
		r += 4.0
	return Vector3.INF


func _collect_road_names(roads: Array) -> void:
	for r in roads:
		if r["name"] == "" or r["k"] == "service":
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 1, 2):
			_road_points.append(Vector2(flat[i], flat[i + 1]))
			_road_names.append(r["name"])


func _nearest_road(x: float, z: float) -> String:
	var best := INF
	var name := "the river"
	var p := Vector2(x, z)
	for i in _road_points.size():
		var d := p.distance_squared_to(_road_points[i])
		if d < best:
			best = d
			name = _road_names[i]
	return name


# --- helpers --------------------------------------------------------------------

func _point_along(poly: PackedVector2Array, s: float) -> Vector2:
	for i in poly.size() - 1:
		var seg := poly[i].distance_to(poly[i + 1])
		if s <= seg and seg > 0.0:
			return poly[i].lerp(poly[i + 1], s / seg)
		s -= seg
	return poly[poly.size() - 1]


func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clock(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%d:%02d" % [s / 60, s % 60]
