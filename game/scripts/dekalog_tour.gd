extends Node
## "Dekalog na kółkach" · Decalogue on wheels (docs/design/dekalog-tour.md; F's ask 2026-11-07: a
## visitor comes to Warsaw and wants to be driven round the places where Kieślowski filmed, ending on
## the Muranów estate where most of the Dekalog and "A Short Film About Love" were shot).
##
## Claire, a film student from Lyon writing her thesis on the Dekalog, phones (16:00-23:30, once the
## player has driven a while, then every CALL_COOL s): ODBIERZ, then JADĘ puts a beacon on Aleje
## Jerozolimskie by Warszawa Centralna, where her train comes in. Then six frames of the series in
## the real places (mapadekalogu.pl), south to north: the Noakowskiego 12 courtyard (VIII), Plac
## Trzech Krzyży (III), the University gate (VIII), the taxi rank at the Europejski (V), the café at
## Krakowskie Przedmieście 27 (VI), and the estate on Inflancka by Dzika 6 (I, IV, VI), across the
## street from the Inflancka pools. At each stop a KADR card says, in our own words, what was shot
## there; the last one asks her question (two answers), then the pay.
##
## On the way: each leg asks for one UJĘCIE, an optional bonus in the series' spirit: a quiet leg (no
## hit at all), a rush (arrive within RUSH s, Christmas Eve), a long take (15 s at 5-40 km/h), a
## static shot (5 s standing still) and the W-Z tunnel (drive under Plac Zamkowy, Dekalog III).
## Hits cost her patience (PAY_HIT each, at most HITS_MAX). Between them, every BANTER s, a line about
## Kieślowski (data/dialogue.json `dekalog_claire`; our own words, no quotes from the films).
##
## Pay *guess*: PAY_BASE - PAY_HIT a hit + PAY_SHOT a shot, RESPECT; the ✕ drops it.
## Cost: nothing per frame while idle but a timer; during the tour one beacon and a status line.

const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

## The Trois Couleurs blue (the cinema tour has the red, the boat race the river blue).
const COLOUR := Color("#3f6fd8")
const DARK := Color("#1d2440")
const NAME := "Dekalog na kółkach"
const NAME_EN := "Decalogue on wheels"
const SPEAKER := "Claire"
const GROUP := "dekalog_claire"

## The call: 16:00-23:30, after FIRST_CALL s of play, then every CALL_COOL s; the card's life.
const HOURS := [16.0, 23.5]
const FIRST_CALL := 600.0
const CALL_COOL := 1800.0
const CARD_LIFE := 12.0
## The whole tour gives up after this long (s) without finishing.
const PLAY_LIMIT := 2700.0
const ARRIVE := StopAssist.RING
const ARRIVE_KMH := StopAssist.STOP_SPEED * 3.6
const HOLD := 1.0
const BUMP_FREE := 3.0       # m/s: a softer touch costs nothing
const BUMP_WAIT := 1.2       # s between two counted hits
const HITS_MAX := 6
## Banter: a line every BANTER s (a range) while driving with her.
const BANTER := Vector2(17.0, 26.0)
## The rush leg: arrive within this many seconds of setting off.
const RUSH := 150.0
## The W-Z tunnel under Plac Zamkowy (centrum.json tunnels, piece 9: Aleja „Solidarności”): its
## two portals; the car counts as inside within TUNNEL_W m of the line between them, TUNNEL_DEEP m
## below the street, away from the portals' ramps.
const TUNNEL := [Vector2(-681.5, -1406.1), Vector2(-874.9, -1382.9)]
const TUNNEL_W := 9.0
const TUNNEL_DEEP := 3.0
## Pay *guess*.
const PAY_BASE := 260
const PAY_HIT := 15
const PAY_SHOT := 25
const RESPECT := 70
const RESPECT_HIT := 6

## The pickup and the six frames: where the car stops (on the carriageway), the place, the street,
## the episode, the card (title, what was shot there and her remark; Polish and English) and the
## shot asked for on the leg that leads there ("" for none).
const PICKUP := {"at": Vector2(-1393.7, 637.8), "name": "Warszawa Centralna"}
const STOPS := [
	{"id": "noakowskiego", "at": Vector2(-918.2, 1426.8), "name": "Noakowskiego 12", "episode": "VIII",
		"shot": "quiet",
		"title": "DEKALOG VIII · NOAKOWSKIEGO 12", "title_en": "DECALOGUE VIII · 12 NOAKOWSKIEGO",
		"body": "Brama, podwórko i kapliczka z Matką Boską, którą mieszkańcy postawili w czasie wojny. Tu w filmie wraca kobieta, której w 1943 roku nie wpuszczono do mieszkania.\nClaire: „Ta sama kapliczka! On niczego nie budował. On tylko patrzył.”",
		"body_en": "A gate, a courtyard and a wayside shrine to the Virgin the tenants put up in the war. In the film a woman comes back here, the girl turned away from a flat in 1943.\nClaire: \"The same shrine! He built nothing. He just looked.\""},
	{"id": "trzech_krzyzy", "at": Vector2(-135.5, 546.1), "name": "Plac Trzech Krzyży", "episode": "III",
		"shot": "rush",
		"title": "DEKALOG III · PLAC TRZECH KRZYŻY", "title_en": "DECALOGUE III · THREE CROSSES SQUARE",
		"body": "Wigilia, noc, biały fiat i czerwony maluch pod kościołem św. Aleksandra. Kamera patrzy z góry, zza kapitelu kolumny, na trójkąt placu.\nClaire: „Trójkątny plac, trójkąt miłosny. Przypadkowych kadrów tu nie ma.”",
		"body_en": "Christmas Eve, night, a white Fiat and a red Maluch outside St Alexander's. The camera looks down from behind a column's capital at the square's triangle.\nClaire: \"A triangular square, a love triangle. No frame here is an accident.\""},
	{"id": "uniwersytet", "at": Vector2(-487.2, -641.9), "name": "Uniwersytet", "episode": "VIII",
		"shot": "long",
		"title": "DEKALOG VIII · UNIWERSYTET", "title_en": "DECALOGUE VIII · THE UNIVERSITY",
		"body": "Brama uniwersytetu. W filmie profesorka etyki prowadzi tu zajęcia, a studenci opowiadają jej historie znane z innych odcinków.\nClaire: „Film, w którym ludzie omawiają inny film. Mój promotor zemdlałby z zachwytu.”",
		"body_en": "The university gate. In the film an ethics professor teaches here, and her students tell her stories from other episodes.\nClaire: \"A film where people discuss another film. My supervisor would faint with joy.\""},
	{"id": "europejski", "at": Vector2(-589.0, -894.6), "name": "Postój przy Europejskim", "episode": "V",
		"shot": "static",
		"title": "DEKALOG V · POSTÓJ TAKSÓWEK", "title_en": "DECALOGUE V · THE TAXI RANK",
		"body": "Postój przy Hotelu Europejskim. Tu chłopak wsiada do taksówki i zaczyna się najcięższy odcinek cyklu, ten, który stał się głosem przeciw karze śmierci.\nClaire długo milczy. „Jedźmy. Tylko nie szybko.”",
		"body_en": "The rank by the Hotel Europejski. Here a young man gets into a taxi and the series' hardest episode begins, the one that became a voice against the death penalty.\nClaire is quiet for a long moment. \"Let's go. Just not fast.\""},
	{"id": "kawiarnia", "at": Vector2(-667.7, -1107.1), "name": "Krakowskie Przedmieście 27", "episode": "VI",
		"shot": "",
		"title": "DEKALOG VI · KAWIARNIA", "title_en": "DECALOGUE VI · THE CAFÉ",
		"body": "Krakowskie Przedmieście 27. Tu chłopak z poczty wreszcie zaprasza sąsiadkę z bloku naprzeciwko. Lody, dwie filiżanki i za dużo odwagi naraz.\nClaire: „Najbardziej romantyczna randka w historii kina. I najbardziej niezręczna.”",
		"body_en": "27 Krakowskie Przedmieście. Here the boy from the post office finally asks out the woman from the block opposite. Ice cream, two cups and too much courage at once.\nClaire: \"The most romantic date in film history. And the most awkward.\""},
	{"id": "osiedle", "at": Vector2(-2393.2, -2301.6), "name": "Osiedle na Inflanckiej", "episode": "I · IV · VI",
		"shot": "tunnel",
		"title": "DEKALOG · OSIEDLE NA INFLANCKIEJ", "title_en": "DECALOGUE · THE INFLANCKA ESTATE",
		"body": "Wielka płyta: Dzika 6 i Inflancka 15, okno w okno. W filmie mieszkają tu bohaterowie wszystkich dziesięciu odcinków, a chłopak z poczty patrzy przez lunetę w okno naprzeciwko.\nClaire zadziera głowę: „Które to okno? Wszystkie są takie same. I o to chodziło.”\nClaire: „A ty? Patrzyłbyś przez lunetę czy zapukał?”",
		"body_en": "Large-panel blocks: Dzika 6 and Inflancka 15, window facing window. In the film the people of all ten episodes live here, and the boy from the post office watches the window opposite through a telescope.\nClaire looks up: \"Which window? They're all the same. That was the point.\"\nClaire: \"And you? Would you watch through a telescope or knock?\""},
]
## The shots she asks for: the status line's hint and how much of it is needed.
const SHOTS := {
	"quiet": ["Ujęcie: cisza, ani jednej stłuczki", "Shot: silence, not a single bump", 1.0],
	"rush": ["Ujęcie: wigilijny pośpiech, zdąż w 150 s", "Shot: the Christmas Eve rush, make it in 150 s", RUSH],
	"long": ["Ujęcie: długie, 15 s przy 5-40 km/h", "Shot: a long take, 15 s at 5-40 km/h", 15.0],
	"static": ["Ujęcie: statyczne, stój 5 s", "Shot: a static one, stand still 5 s", 5.0],
	"tunnel": ["Ujęcie: przejedź tunelem Trasy W-Z", "Shot: drive through the W-Z tunnel", 1.0],
}
## The last card's two answers and her reply to each.
const ANSWERS := [
	["ZAPUKAŁBYM|I'D KNOCK", "Claire: „Odważnie. Ale wtedy nie byłoby filmu, tylko herbata.”",
			"Claire: \"Brave. But then there'd be no film, just tea.\""],
	["PATRZĘ NA DROGĘ|EYES ON THE ROAD", "Claire: „Mądrze. Kierowca, który patrzy w okna, kończy w innym odcinku.”",
			"Claire: \"Wise. A driver who looks into windows ends up in another episode.\""],
]

enum State { IDLE, RING, OFFER, TO_PICKUP, LEG, FRAME, ASK, DONE }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var map: Node3D
var car: Node3D
var log_on := false
var autopilot := false
## Nothing else on, on the ground (main.gd).
var free_now: Callable = func() -> bool: return true
## [position, speed km/h, flying, forward speed m/s].
var vehicle: Callable
var clock: Callable = func() -> float: return 12.0
## Testing aids: calls at any hour.
var force_hours := false

var state := State.IDLE
## The next stop's index into STOPS while on a leg or at a frame.
var stop := 0
var hits := 0
var shots_done: Array[String] = []
var answer := -1
var _t := 0.0
var _session := 0.0
var _tour_t := 0.0
var _leg_t := 0.0
var _leg_hit := false
var _next_call := FIRST_CALL
var _hold := 0.0
var _bump_wait := 0.0
var _banter := 20.0
var _shot_t := 0.0
var _beacon: Node3D
var _rng := RandomNumberGenerator.new()
var _result: Dictionary = {}


func setup(world: Node3D) -> void:
	_rng.randomize()
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, DARK)
	_beacon.visible = false
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func() -> void:
		if state in [State.TO_PICKUP, State.LEG]:
			_quit(true))
	if car != null and car.has_signal("bumped"):
		car.bumped.connect(on_bump)


func busy() -> bool:
	return state != State.IDLE and state != State.RING


func has_target() -> bool:
	return state == State.TO_PICKUP or state == State.LEG


func target_position() -> Vector3:
	var at: Vector2 = PICKUP["at"] if state == State.TO_PICKUP else STOPS[stop]["at"]
	return Vector3(at.x, _ground(at), at.y)


func target_colour() -> Color:
	return COLOUR


## The stop assist's spot (main.gd `_stop_assist`): the ring the car glides into.
func stop_spot() -> Vector3:
	return target_position()


func last_result() -> Dictionary:
	return _result


func _ground(at: Vector2) -> float:
	return map.ground_height(at.x, at.y) if map != null else 0.0


func _process(dt: float) -> void:
	_t += dt
	_session += dt
	_bump_wait = maxf(0.0, _bump_wait - dt)
	match state:
		State.IDLE:
			_idle_tick()
		State.RING, State.OFFER:
			if _t > CARD_LIFE:
				hud.hide_card()
				_reset(CALL_COOL * 0.5)
			elif autopilot and _t > 1.5:
				_on_card(0)
		State.TO_PICKUP, State.LEG:
			_tour_t += dt
			_drive_tick(dt)
		State.FRAME, State.ASK, State.DONE:
			if autopilot and _t > 2.5:
				_on_card(0)


func _idle_tick() -> void:
	if _session < _next_call or int(_session * 2.0) == int((_session - get_process_delta_time()) * 2.0):
		return
	if vehicle.is_valid() and bool(vehicle.call()[2]):
		return
	var h: float = clock.call()
	if not force_hours and (h < HOURS[0] or h >= HOURS[1]):
		return
	if not free_now.call():
		return
	ring()


# --- the call --------------------------------------------------------------------------------------

## Claire met in person at Centralna (story_quests.gd: she walks up, the player said WCHODZĘ):
## no call, the tour starts with her already at the car. False unless idle.
func meet() -> bool:
	if state != State.IDLE:
		return false
	_log("met Claire at Centralna")
	start()
	return true


## Idle: not ringing, not touring (a questline may start now).
func idle() -> bool:
	return state == State.IDLE


## Claire phones.
func ring() -> bool:
	if state != State.IDLE:
		return false
	state = State.RING
	_t = 0.0
	hud.show_side_card("📞 +33 · CLAIRE DZWONI", "Nieznany numer z Francji. W tle zapowiedź pociągu i coś o „Kieślowskim” z francuskim akcentem.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "+33 · Claire is calling",
			"An unknown French number. A train announcement behind her and something about \"Kieślowski\" in a French accent.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call ringing")
	return true


func _offer() -> void:
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("CLAIRE: „PROWADZI PAN? ŚWIETNIE!”",
			"„Bonjour! Claire, studentka filmu z Lyonu. Piszę pracę o „Dekalogu” i mam jeden dzień w Warszawie. Chcę zobaczyć miejsca, gdzie kręcił Kieślowski, aż do osiedla na Inflanckiej. Jestem na Centralnej.”",
			PackedStringArray(["JADĘ|ON MY WAY", "NIE DZIŚ|NOT TODAY"]), COLOUR, "Claire: \"You drive? Perfect!\"",
			"\"Bonjour! Claire, a film student from Lyon. I'm writing about the Dekalog and I have one day in Warsaw. I want to see where Kieślowski filmed, all the way to the estate on Inflancka. I'm at Centralna.\"")


func _on_card(i: int) -> void:
	match state:
		State.RING:
			hud.hide_card()
			if i == 0:
				_offer()
			else:
				_reset(CALL_COOL)
		State.OFFER:
			hud.hide_card()
			if i == 0:
				start()
			else:
				_reset(CALL_COOL)
		State.FRAME:
			hud.hide_card()
			stop += 1
			_leg()
		State.ASK:
			hud.hide_card()
			_finale(clampi(i, 0, ANSWERS.size() - 1))
		State.DONE:
			hud.hide_card()
			_reset(CALL_COOL)


## The tour starts: to Centralna for Claire (or straight on when the car is there).
func start() -> void:
	state = State.TO_PICKUP
	_t = 0.0
	_tour_t = 0.0
	_hold = 0.0
	stop = 0
	hits = 0
	answer = -1
	shots_done.clear()
	_result = {}
	var at: Vector2 = PICKUP["at"]
	_beacon.visible = true
	_beacon.place(Vector3(at.x, _ground(at), at.y), ARRIVE - 0.5, true, true)
	hud.toast("Po Claire na Dworzec Centralny", "Pick Claire up at Warszawa Centralna")
	_log("to the pickup")


# --- driving -----------------------------------------------------------------------------------------

func _drive_tick(dt: float) -> void:
	if _tour_t > PLAY_LIMIT:
		_quit(false)
		return
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var kmh: float = v[1]
	var flying: bool = v[2]
	var at: Vector2 = PICKUP["at"] if state == State.TO_PICKUP else STOPS[stop]["at"]
	var d := Vector2(p.x, p.z).distance_to(at)
	if state == State.LEG:
		_leg_t += dt
		_shot_tick(dt, p, kmh)
		_banter_tick(dt)
	_status(d)
	if not flying and d < ARRIVE and kmh < ARRIVE_KMH:
		_hold += dt
		if _hold >= HOLD:
			_hold = 0.0
			if state == State.TO_PICKUP:
				_picked_up()
			else:
				_arrive()
	else:
		_hold = 0.0


func _picked_up() -> void:
	state = State.LEG
	stop = 0
	_banter = 6.0
	_begin_leg()
	dialogue.say(car, SPEAKER, GROUP, "hello", 4.5, COLOUR, 2.4, true)
	hud.toast("Claire wsiada z plecakiem i zeszytem pełnym kadrów", "Claire gets in with a rucksack and a notebook full of frames")
	_aim()
	_log("picked up")


## On to the next stop (or the end after the last).
func _leg() -> void:
	if stop >= STOPS.size():
		_reset(CALL_COOL)
		return
	state = State.LEG
	_t = 0.0
	_banter = 8.0
	_begin_leg()
	_aim()


func _begin_leg() -> void:
	_leg_t = 0.0
	_leg_hit = false
	_shot_t = 0.0


func _aim() -> void:
	var at: Vector2 = STOPS[stop]["at"]
	_beacon.visible = true
	_beacon.place(Vector3(at.x, _ground(at), at.y), ARRIVE - 0.5, true, false)
	var shot: String = STOPS[stop]["shot"]
	if shot != "" and not shots_done.has(shot):
		hud.toast(String(SHOTS[shot][0]), String(SHOTS[shot][1]))


func _status(d: float) -> void:
	var hint := "Claire czeka na peronie: %s" % PICKUP["name"]
	var hint_en := "Claire waits on the platform: %s" % PICKUP["name"]
	var progress := 0.0
	if state == State.LEG:
		var s: Dictionary = STOPS[stop]
		var shot: String = s["shot"]
		var where := "Dekalog %s · %s" % [s["episode"], s["name"]]
		if shot == "":
			hint = where
			hint_en = "Decalogue %s · %s" % [s["episode"], s["name"]]
		elif shots_done.has(shot):
			hint = "%s · Ujęcie jest!" % where
			hint_en = "Decalogue %s · %s · Got the shot!" % [s["episode"], s["name"]]
		else:
			hint = "%s · %s" % [where, SHOTS[shot][0]]
			hint_en = "Decalogue %s · %s · %s" % [s["episode"], s["name"], SHOTS[shot][1]]
			match shot:
				"long", "static":
					progress = clampf(_shot_t / float(SHOTS[shot][2]), 0.0, 1.0)
				"rush":
					progress = clampf(1.0 - _leg_t / RUSH, 0.0, 1.0)
	hud.show_status(NAME, "%d/%d" % [mini(stop + (1 if state == State.LEG else 0), STOPS.size()), STOPS.size()], "%d m" % roundi(d),
			hint, progress, COLOUR, "", {}, hint_en)


## The leg's shot. "quiet" and "rush" are judged on arrival (_arrive); the others fill while driving.
func _shot_tick(dt: float, p: Vector3, kmh: float) -> void:
	var shot: String = STOPS[stop]["shot"]
	if shot == "" or shots_done.has(shot):
		return
	match shot:
		"long":
			_shot_t = _shot_t + dt if kmh >= 5.0 and kmh <= 40.0 else 0.0
		"static":
			_shot_t = _shot_t + dt if kmh < 2.0 else 0.0
		"tunnel":
			if in_tunnel(p):
				_shot_t = 1.0
	if shot in ["long", "static", "tunnel"] and _shot_t >= float(SHOTS[shot][2]):
		_got(shot)


## Inside the W-Z tunnel: near the line between its portals, away from the ramps, below the street.
func in_tunnel(p: Vector3) -> bool:
	var a: Vector2 = TUNNEL[0]
	var b: Vector2 = TUNNEL[1]
	var q := Vector2(p.x, p.z)
	var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	if t < 0.2 or t > 0.8:
		return false
	if q.distance_to(a.lerp(b, t)) > TUNNEL_W:
		return false
	return p.y < _ground(q) - TUNNEL_DEEP or map == null


func _got(shot: String) -> void:
	shots_done.append(shot)
	_shot_t = float(SHOTS[shot][2])
	hud.toast("UJĘCIE! Claire notuje (+%d zł na końcu)" % PAY_SHOT, "SHOT! Claire takes notes (+%d zł at the end)" % PAY_SHOT)
	dialogue.say(car, SPEAKER, GROUP, "shot_" + shot, 4.0, COLOUR, 2.4, true)
	Access.buzz(40, 0.4)
	_banter = maxf(_banter, 8.0)
	_log("shot %s done" % shot)


func _banter_tick(dt: float) -> void:
	_banter -= dt
	if _banter > 0.0:
		return
	_banter = _rng.randf_range(BANTER.x, BANTER.y)
	dialogue.say(car, SPEAKER, GROUP, "", 5.0, COLOUR, 2.4)


## A hit on the way: her patience (main.gd wires car.bumped here).
func on_bump(_collider: Object, speed: float) -> void:
	if state != State.LEG or speed < BUMP_FREE or _bump_wait > 0.0:
		return
	_bump_wait = BUMP_WAIT
	_leg_hit = true
	if STOPS[stop]["shot"] == "long":
		_shot_t = 0.0
	if hits >= HITS_MAX:
		return
	hits += 1
	Access.buzz(90, 0.9)
	dialogue.say(car, SPEAKER, GROUP, "bump", 3.5, COLOUR, 2.4, true)
	hud.toast("Stłuczka! Claire zapisuje to jako „scenę niepokoju moralnego” (−%d zł)" % PAY_HIT,
			"A bump! Claire notes it down as \"a scene of moral anxiety\" (−%d zł)" % PAY_HIT)
	_banter = maxf(_banter, 6.0)
	_log("bump: %d hits" % hits)


# --- the frames --------------------------------------------------------------------------------------

func _arrive() -> void:
	var s: Dictionary = STOPS[stop]
	var shot: String = s["shot"]
	if not shots_done.has(shot):
		if shot == "quiet" and not _leg_hit:
			_got(shot)
		elif shot == "rush" and _leg_t <= RUSH:
			_got(shot)
	state = State.FRAME
	_t = 0.0
	_beacon.visible = false
	hud.hide_status()
	_log("frame at %s" % s["id"])
	if stop == STOPS.size() - 1:
		state = State.ASK
		hud.show_card(String(s["title"]), String(s["body"]),
				PackedStringArray([ANSWERS[0][0], ANSWERS[1][0]]), COLOUR, false, String(s["title_en"]), String(s["body_en"]))
		return
	hud.show_card(String(s["title"]), String(s["body"]), PackedStringArray(["JEDZIEMY DALEJ|DRIVE ON"]), COLOUR, false,
			String(s["title_en"]), String(s["body_en"]))


## Her question answered: the reply, the pay, tomorrow's plan.
func _finale(i: int) -> void:
	state = State.DONE
	_t = 0.0
	answer = i
	var s: Dictionary = STOPS[stop]
	var pay := maxi(0, PAY_BASE - PAY_HIT * hits) + PAY_SHOT * shots_done.size()
	var respect := maxi(0, RESPECT - RESPECT_HIT * hits)
	if wallet != null:
		wallet.pay(pay, respect, "dekalog_tour")
	var plan := "Jutro rano basen na Inflanckiej, po drugiej stronie ulicy, a potem znicz na Powązkach."
	var plan_en := "Tomorrow morning the Inflancka pool across the street, then a candle at Powązki."
	hud.show_card(String(s["title"]), "%s\n%s\n+%d zł  +%d szacunu · ujęcia %d/%d" % [ANSWERS[i][1], plan, pay, respect, shots_done.size(), SHOTS.size()],
			PackedStringArray(["MERCI!|MERCI!"]), COLOUR, false, String(s["title_en"]),
			"%s\n%s\n+%d zł  +%d respect · shots %d/%d" % [ANSWERS[i][2], plan_en, pay, respect, shots_done.size(), SHOTS.size()])
	_result = {"pay": pay, "respect": respect, "hits": hits, "shots": shots_done.size(), "answer": i, "time": _tour_t}
	_log("done: %d zł, %d respect, %d hits, %d shots, answer %d, %.0f s" % [pay, respect, hits, shots_done.size(), i, _tour_t])


func _quit(by_player: bool) -> void:
	hud.hide_status()
	hud.hide_card()
	_beacon.visible = false
	if by_player:
		hud.toast("Claire wysiada: „Dokończę tramwajem. Tramwaje też grały u Kieślowskiego.”",
				"Claire gets out: \"I'll finish by tram. Trams were in Kieślowski's films too.\"")
	_reset(CALL_COOL)
	_log("quit")


func _reset(cool: float) -> void:
	state = State.IDLE
	_t = 0.0
	_beacon.visible = false
	_next_call = _session + cool


func _log(msg: String) -> void:
	if log_on:
		print("dekalog: " + msg)
