extends Node
## Loop MW-4 (docs/design/vision.md 3.4): "Na czasie" · On trend, the trend courier's side job.
## Passing an open Wiralek slot (within 60 m, its shop open, the trend on days 1-7) with nothing
## else on brings a request card like Podwózka's: an office worker at Rondo Daszyńskiego wants
## today's trend before it's over. Accept, stop 2 s by the queue ("odbiór na aplikację": the
## queue lets the courier through), then deliver to a real address door within 300 m of the
## roundabout in 6 minutes. Pay 25 zł + 8 zł a km by road, +15 respect, a 10 zł tip *guess*; on
## the trend's day 6 or 7 the customer says "to już niemodne" and tips nothing (the joke). Late:
## half the pay, no tip, no respect *guess*. One activity at a time, like every job (jobs.gd,
## rides.gd and this script see each other's `busy`).
##
## Trend follow-up: **"Limitka" · the limited drop** (docs/design/trends-2025-26.md). On Fridays
## 16:00-18:30 PISTACJA DO KOŃCA sells a limited run (crowds.gd `pistacja_drop`). A car within 60 m
## of its door gets the request: a friend wants a box, 5 minutes before it melts. Stand in the
## queue's ring 5 s ("stoisz w kolejce"); if the drop ends first it is "wyprzedane" and the job
## drops. Deliver to a door 500-1800 m away in 5 minutes. Pay 40 zł + 10 zł a km, +12 respect, a
## 15 zł tip *guess*; late: half, no tip, no respect.##
## **"Mlask" · Mrożulo's review** (docs/design/gaulle-and-food-hype.md G5): Mrożulo, the food
## reviewer on wheels (a parody type, never the real man), parks his cream van at one of four
## spots by the weekday (ML_SPOTS), 11:00-21:00. Stop by it: he wants a bite of a new place (the
## nearest open Wiralek slot on its days 1-3, else KUKŁA's nearest door). Stop 2 s there ("na
## wynos dla Mrożula"), bring it back while it's warm (5 min), get his review on a card in his
## grade, the MLASK, then take his sticker to the place in 4 min: 40 zł + 10 zł a km (both legs),
## +15 respect, a 15 zł tip *guess*, and the "Mrożulo effect": that place's queue stands at its
## longest for the rest of the game day (crowds.gd `mrozulo`). A cold delivery: three MLASKI,
## half the pay, no tip, no respect, the queue grows anyway (any review is a review).
##
## **"Dżemini" · Mrożulo's call** (F, 2026-11-06; docs/design/gaulle-and-food-hype.md G5b): once
## per save, after DZ_FIRST s of play in his van's hours, Mrożulo phones: a new kebab, DŻEMINI
## KEBAB on Świętokrzyska, whose meat an AI agent carves (a parody of the AI assistant). Stop 2 s by
## its queue, bring the kebab to his van while it's warm (5 min). He bites: "Wjeżdżam w to." Then a
## TYGRAM (the messenger parody) message from him, and for good: the MLASK sticker on DŻEMINI's wall
## and the city's longest line at its door (crowds.gd `dzemini_mlask`, the `viral` "dzemini" jokes),
## kept in the save (`keep` DZ_KEEP). Skipped, he rings again DZ_COOL s later. 60 zł + 10 zł a km,
## +25 respect, a 20 zł tip *guess*; cold: half, no tip, no respect, the sticker all the same.

const Beacon := preload("res://scripts/beacon.gd")
const Models := preload("res://scripts/models.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Missions := preload("res://scripts/missions.gd")
const CityLife := preload("res://scripts/city_life.gd")
const Crowds := preload("res://scripts/crowds.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const CoffeeRun := preload("res://scripts/coffee_run.gd")
const Access := preload("res://scripts/access.gd")

## Wiralek's pink (not the kebab's orange, not the passengers' teal).
const COLOUR := Color("#ff7ac8")
const FAIL_COLOUR := Color("#e2574c")
const OFFER_R := 60.0
const OFFER_LIFE := 10.0
## A slot offers again after this long (s).
const SLOT_COOL := 240.0
const PICKUP := StopAssist.RING
const PICKUP_SPEED := StopAssist.STOP_SPEED
const PICKUP_HOLD := 1.5
const ARRIVE := StopAssist.RING
const ARRIVE_SPEED := StopAssist.STOP_SPEED
const LIMIT := 360.0
const BASE := 25
const PER_KM := 8
const TIP := 10
const RESPECT := 15
const DROP_BASE := 40
const DROP_PER_KM := 10
const DROP_TIP := 15
const DROP_RESPECT := 12
const DROP_HOLD := 5.0
const DROP_LIMIT := 300.0
const DROP_FROM := 500.0
const DROP_TO := 1800.0
const DROP_COLOUR := Color("#8fc46a")
const DROP_FRIENDS := ["Zuzia", "Bartek", "Magda", "Kuba", "Iga", "Olek"]
## "Czwarty" (docs/design/padel.md): PADELNIA's fourth player. Fetch a player from a door 400-1500 m
## away and bring them to the court's door in 7 minutes. 45 zł + 8 zł a km (there and back), +14
## respect, a 15 zł tip *guess*; late: half, no tip, no respect.
const CZ_BASE := 45
const CZ_PER_KM := 8
const CZ_TIP := 15
const CZ_RESPECT := 14
const CZ_LIMIT := 420.0
const CZ_FROM := 400.0
const CZ_TO := 1500.0
const CZ_MIN_QUEUE := 10
const CZ_COLOUR := Color("#2fd0e0")
## "Czwarty" at WTS DESKA (landmarks.gd DESKI, docs/design/padel.md): a friend phones from the court
## by the Vistula: the fourth player broke a leg at pole dance, come at once (drive or fly) and play.
## Once the player has driven a while, 8:00-22:00, then every DESKI_COOL s of play. No pickup: the
## beacon is the club's gate; a helicopter within DESKI_FLY_R m of it counts.
const DESKI_GATE := Vector2(1475.0, 985.0)
const DESKI_HOURS := [8.0, 22.0]
const DESKI_FIRST := 150.0
const DESKI_COOL := 1200.0
const DESKI_LIMIT := 480.0
const DESKI_FLY_R := 28.0
## No call within this many metres of the gate.
const DESKI_NEAR := 250.0
const DESKI_CALLERS := ["Kuba", "Zuzia", "Bartek", "Iga", "Olek", "Magda"]
const DESKI_INJURED := ["Marta", "Ola", "Michał od Excela", "Prezes z Mokotowa"]
## The DESKA call's opening (as Szymek's boat race and Ziomek's rave): the phone rings first, with
## who it is, ODBIERZ / ODRZUĆ, and only an answered call says what it wants. A short bio per caller.
const DESKI_BIOS := {
	"Kuba": ["Kumpel z liceum. Od marca „zaczyna padla od poniedziałku”. Ma już trzy rakiety.", "Your mate from school. Since March he has been \"starting padel on Monday\". He has three rackets already."],
	"Zuzia": ["Koleżanka z pracy. Bluzę klubową kupiła, zanim zagrała pierwszy mecz.", "A friend from work. She bought the club hoodie before her first game."],
	"Bartek": ["Kumpel z osiedla. Rezerwuje korty o 6:00 rano, bo tylko wtedy są wolne.", "Your mate from the estate. He books courts at 6 a.m., the only free slot."],
	"Iga": ["Znajoma z kursu salsy. Teraz mówi tylko o vibora i bandeja.", "A friend from salsa class. Now all she talks about is the vibora and the bandeja."],
	"Olek": ["Kuzyn. Grał w tenisa, więc myśli, że w padla też umie. Nie umie.", "Your cousin. He played tennis, so he thinks he can play padel. He can't."],
	"Magda": ["Sąsiadka z góry. Prowadzi grupę „Padel Powiśle” na 412 osób.", "The neighbour upstairs. She runs the \"Padel Powiśle\" group, 412 members."],
}
## The match at DESKA (an answered call that arrived on time): DESKI_POINTS points, one card each,
## three shots (LOB, ZE ŚCIANY, SMECZ). Each rally: [situation pl, en], the best shot's index, the
## line when it wins [pl, en], when it loses [pl, en]. Every point won: MATCH_ZL zł, MATCH_RESPECT.
const DESKI_POINTS := 3
const MATCH_ZL := 6
const MATCH_RESPECT := 2
const SHOTS := [["LOB", "Lob"], ["ZE ŚCIANY", "OFF THE GLASS"], ["SMECZ", "SMASH"]]
const RALLIES := [
	[["Piłka odbija się od tylnej szyby i wraca wysoko na środek kortu.", "The ball comes off the back glass and floats high over the middle."], 2,
		["Smecz! Piłka wylatuje za kort. Kibice z kawiarni klaszczą.", "Smash! The ball flies off the court. The café crowd claps."],
		["Lob z takiej piłki? Rywale dziękują i kończą punkt.", "A lob off that ball? The other pair says thanks and finishes it."]],
	[["Rywale stoją przy siatce. Prezes z Mokotowa macha rakietą jak packą na muchy.", "The other pair is up at the net. Prezes z Mokotowa swats like it's a fly."], 0,
		["Lob nad Prezesem! Odwraca się, piłka już leży za nim.", "A lob over Prezes! By the time he turns, it's down behind him."],
		["Prosto w Prezesa. Odbija, nawet nie wiedząc jak.", "Straight at Prezes. He gets it back without knowing how."]],
	[["Szybka piłka w róg, prosto w szybę za tobą.", "A fast ball into the corner, straight at the glass behind you."], 1,
		["Czekasz, piłka wraca od szyby, kontra po linii. Ściana jest częścią gry!", "You wait, it comes off the glass, a counter down the line. The wall is part of the game!"],
		["Bierzesz ją z powietrza i trafiasz w siatkę. Ściana by ci pomogła.", "You take it on the volley and hit the net. The wall would have helped."]],
	[["Krótka, niska piłka tuż za siatką. Trener Dominik krzyczy: „Nie biegaj, ustaw się!”", "A short, low ball just over the net. Trener Dominik shouts: \"Don't run, get in place!\""], 0,
		["Podbijasz lobem wysoko. Rywale cofają się do szyby i gubią rytm.", "You lift it high. The other pair backs off to the glass and loses the rhythm."],
		["Smecz z kolan? Piłka ląduje w siatce, Dominik łapie się za głowę.", "A smash from your knees? Into the net, and Dominik holds his head."]],
	[["Lob rywali leci nad tobą i spada za linią, przy samej szybie.", "Their lob sails over you and drops behind the line, right by the glass."], 1,
		["Odwracasz się, piłka odbija od szyby, odgrywasz spokojnie. Pani Basia z recepcji kiwa głową.", "You turn, it comes off the glass, you play it back calmly. Pani Basia from reception nods."],
		["Gonisz piłkę jak w tenisie i wpadasz na szybę. To nie tenis.", "You chase it like tennis and run into the glass. It isn't tennis."]],
]
## The score line per points won (0..3): [pl, en].
const MATCH_SCORES := [["2:6, 1:6", "2-6, 1-6"], ["4:6, 6:7", "4-6, 6-7"], ["6:4, 4:6, 10:8 w tie-breaku", "6-4, 4-6, 10-8 in the tie-break"], ["6:2, 6:3", "6-2, 6-3"]]
## Landing the helicopter by the court counts (DESKI_FLY_R) and earns the reception's remark and
## FLY_RESPECT more.
const FLY_RESPECT := 5
## A point not played within this long (s) is lost (the ball went by).
const POINT_LIFE := 25.0
const CZ_PLAYERS := ["Prezes z Mokotowa", "Pani Basia", "Trener Dominik", "kuzyn Kuby", "Ola z recepcji", "Michał od Excela"]
## "Mlask" (G5): the van's spots (places.json ids) by weekday, its hours, the offer's reach, the
## legs' limits, the pay *guess*.
const ML_SPOTS := ["plac_zbawiciela", "hala_koszyki", "kebab_palma", "plac_trzech_krzyzy"]
const ML_HOURS := [11.0, 21.0]
const ML_OFFER_R := 30.0
const ML_COOL := 300.0
const ML_WARM := 300.0
const ML_STICKER := 240.0
const ML_BASE := 40
const ML_PER_KM := 10
const ML_TIP := 15
const ML_RESPECT := 15
const ML_COLOUR := Color("#ffbf5f")
const ML_GRADES := [7.5, 8.0, 8.5, 9.0, 9.5]
const ML_COLD_GRADE := 3.0
## "Dżemini" (G5b): the shop (crowds.gd / storefronts.gd id), the save key, the first call after this
## much play (s), again this long after a skip, the pay *guess*, the TYGRAM card's blue, the sticker.
const DZ_SITE := "dzemini_kebab"
const DZ_KEEP := "dzemini_mlask"
const DZ_FIRST := 300.0
const DZ_COOL := 900.0
const DZ_BASE := 60
const DZ_PER_KM := 10
const DZ_TIP := 20
const DZ_RESPECT := 25
const TYGRAM_COLOUR := Color("#3aa0e8")
const STICKER_YELLOW := Color("#ffd23f")
const STICKER_PX := 0.04
const PixelFont := preload("res://scripts/pixel_font.gd")
const VAN_CREAM := Color("#efe6cf")
const VAN_PINK := Color("#d9467f")
const VAN_DARK := Color("#26262b")
## The fans by the van (while it is out): their shirts, a bubble every FAN_GAP seconds when the
## car is within FAN_TALK_R m (the `viral` "mrozulo" lines).
const FAN_SHIRTS := ["#e57aa0", "#2f6fb5", "#e0b23a", "#f2efe8", "#7a4fa8"]
const FAN_GAP := [14.0, 26.0]
const FAN_TALK_R := 22.0
## The egg "In Mrożulo's shot" (eggs.json easter_mlask): the car stopped (under 1 m/s) within
## EGG_R m of the van for EGG_SECS seconds while he is out and filming.
const EGG_ID := "easter_mlask"
const EGG_R := 9.0
const EGG_SECS := 3.0
const DEST_ID := "rondo_daszynskiego"
const DEST_R := 300.0
const RESULT_LIFE := 10.0
const CUSTOMERS := ["Ania z HR", "Tomek z IT", "Kasia z marketingu", "Paweł z finansów", "Ola z działu prawnego", "Michał ze sprzedaży"]

enum State { IDLE, OFFER, PICKUP, DELIVER, RESULT }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var missions: Node
var rivals: Node
var jobs: Node
var rides: Node
var graph: LaneGraph
var map: Node3D
var car: CharacterBody3D
## city_life.gd: the slots' state and doors.
var life: Node3D
## crowds.gd (the PISTACJA site and its drop); may be null.
var crowds: Node
var state := State.IDLE
## Set by the game each frame (no offers from the helicopter, the title screen or the bench).
var flying := false
var away := false
## Spacer: no request comes by itself.
var quiet := false
## The first-10 guide (first10.gd `_hold_offers`): a beat is due, no offer until it has fired.
var guide_hold := false
var autopilot := false
## --trend-job=4: the drop never ends (the test run).
var force_drop := false
## --trend-log: `trend job:` lines.
var log_on := false
var last_usec := 0
## The order: {slot, word, day, kerb, ring (pickup), door ring, road, customer, name}.
var order := {}
## The jobs done (the check, the log).
var done := 0

var _dest := Vector2.INF
var _cool := {}
var _t := 0.0
var _clock := 0.0
var _hold := 0.0
var _beacon: Node3D
var _rng := RandomNumberGenerator.new()
var _session := 0.0
var _world: Node3D
## Set by the game each frame: where the player is (the car, or the helicopter in the air).
var player_pos := Vector3.ZERO
## When the DESKA call may ring next (_session seconds).
var _deski_at := DESKI_FIRST
## The coffee run (coffee_run.gd, order kind "kawa"): when Zuzia calls next (s of play), the car
## left at the ROWERILO dock while the player rides, the world it stands in, the joke's clock.
var _kawa_at := CoffeeRun.FIRST
## Session time before which Zuzia doesn't walk up again (set when a run ends: no fresh offer the
## moment you hand the bike back at the dock).
var _kawa_rest := 0.0
var _parked: Node3D
var _line_t := 0.0
## The call comes only within this many metres of the dock (a coffee run, not a road trip).
const KAWA_CALL_R := 1800.0
## "Mlask": the places' points (setup), the van {spot, at: Vector3, ring: Vector3, yaw} or {}, its node.
var _places := {}
var van := {}
var _van_node: MeshInstance3D
var _van_day := -1
## The fans' node (a child of the van), their bubble timer, the egg's stop timer and its callback
## (main.gd: egg_book.fire).
var _fans: MeshInstance3D
var _fan_t := 8.0
var _egg_t := 0.0
var egg: Callable
## "Dżemini": storefronts.gd (the shop's wall, for the sticker; may be null), whether the job is done
## (the save), when the call may ring next (_session s), the sticker's node once placed.
var storefronts: Node
var dz_done := false
var _dz_at := DZ_FIRST
var _sticker: MeshInstance3D


## The pay for a delivery `road_m` metres by road on the trend's day `day`: {zl, base, tip,
## respect, out (day 6-7: "niemodne")}.
static func pay(road_m: float, day: int, on_time: bool) -> Dictionary:
	var base := BASE + roundi(PER_KM * road_m / 1000.0)
	var out := day >= 6
	var tip := TIP if on_time and not out else 0
	var zl := (base if on_time else roundi(base * 0.5)) + tip
	return {"zl": zl, "base": base, "tip": tip, "respect": RESPECT if on_time else 0, "out": out}


## The limited drop's pay for a delivery `road_m` metres by road: {zl, base, tip, respect}.
static func drop_pay(road_m: float, on_time: bool) -> Dictionary:
	var base := DROP_BASE + roundi(DROP_PER_KM * road_m / 1000.0)
	var tip := DROP_TIP if on_time else 0
	return {"zl": (base if on_time else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": DROP_RESPECT if on_time else 0}


## The "Czwarty" pay for `road_m` metres by road (one way): {zl, base, tip, respect}.
static func cz_pay(road_m: float, on_time: bool) -> Dictionary:
	var base := CZ_BASE + roundi(CZ_PER_KM * 2.0 * road_m / 1000.0)
	var tip := CZ_TIP if on_time else 0
	return {"zl": (base if on_time else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": CZ_RESPECT if on_time else 0}


## An open slot offers the job: its shop open, the trend on days 1-7 (state: slot_state's).
static func offers(st: Dictionary, hour: float) -> bool:
	return int(st.get("day", 8)) < CityLife.CYCLE and hour >= float(CityLife.SHOP_HOURS[0]) and hour < float(CityLife.SHOP_HOURS[1])


func setup(nodes: Dictionary, places: Dictionary, world: Node3D) -> void:
	hud = nodes["hud"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	missions = nodes["missions"]
	rivals = nodes.get("rivals")
	jobs = nodes["jobs"]
	rides = nodes.get("rides")
	graph = nodes["graph"]
	map = nodes["map"]
	car = nodes["car"]
	life = nodes["life"]
	crowds = nodes.get("crowds")
	storefronts = nodes.get("storefronts")
	dz_done = wallet != null and bool(wallet.keep.get(DZ_KEEP, false))
	if dz_done and crowds != null and crowds.has_method("dzemini_mlask"):
		crowds.dzemini_mlask()
	_world = world
	_rng.randomize()
	_dest = places.get(DEST_ID, Vector2.INF)
	_places = places
	_world = world
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#2f6fb5"))
	_van_node = MeshInstance3D.new()
	_van_node.mesh = van_mesh()
	_van_node.material_override = Models.material()
	_van_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_van_node.visible = false
	world.add_child(_van_node)
	_fans = MeshInstance3D.new()
	_fans.mesh = fans_mesh()
	_fans.material_override = Models.material()
	_fans.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_van_node.add_child(_fans)
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func() -> void:
		if state == State.PICKUP or state == State.DELIVER:
			_fail(["Anulowane", "Cancelled"]))


func busy() -> bool:
	return state != State.IDLE and state != State.OFFER


func has_target() -> bool:
	return state == State.PICKUP or state == State.DELIVER


func target_position() -> Vector3:
	return order["ring"] if state == State.PICKUP else order["door_ring"]


## Where the car should stop now (stop_assist.gd): the queue, then the door.
func stop_spot() -> Vector3:
	return target_position() if has_target() else Vector3.INF


func target_colour() -> Color:
	return CoffeeRun.COLOUR if _is_kawa() else COLOUR


func primary() -> bool:
	if state == State.OFFER or state == State.RESULT:
		_on_card(0)
		return true
	return false


func secondary() -> bool:
	if state == State.OFFER:
		_on_card(1)
		return true
	return false


func _free() -> bool:
	if flying or away or quiet or guide_hold or car.in_water or missions.has_target():
		return false
	if not (missions.state == Missions.State.CLOSED or missions.state == Missions.State.RINGING):
		return false
	if jobs != null and jobs.own_busy():
		return false
	if rides != null and rides.state != 0:
		return false
	return rivals == null or not rivals.busy()


func _process(dt: float) -> void:
	if life == null or graph == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	if not away:
		_session += dt
	if dz_done and _sticker == null and int(_t * 2.0) != int((_t - dt) * 2.0):
		_place_sticker()
	match state:
		State.IDLE:
			if int(_session * 2.0) != int((_session - dt) * 2.0):
				_look()
		State.OFFER:
			if flying or away or (jobs != null and jobs.own_busy()) or (rides != null and rides.busy()):
				_withdraw()
			elif autopilot and _t > 2.0:
				_on_card(0)
			elif _t > OFFER_LIFE:
				_withdraw()
		State.PICKUP:
			_pickup_tick(dt)
		State.DELIVER:
			_deliver_tick(dt)
		State.RESULT:
			if str(order.get("stage", "")) == "match":
				if autopilot and _t > 2.0:
					_match_answer(int(RALLIES[int(order["rallies"][int(order["point"])])][1]))
				elif _t > POINT_LIFE:
					_match_answer(-1)
			elif _is_ml() and str(order.get("stage", "")) == "review":
				if autopilot and _t > 2.0:
					_start_sticker()
			elif _is_dz() and str(order.get("stage", "")) == "review":
				if (autopilot and _t > 2.0) or _t > RESULT_LIFE:
					_dz_tygram()
			elif _t > RESULT_LIFE:
				_release()
	last_usec = Time.get_ticks_usec() - t0


## Twice a second: an open slot within 60 m offers the job.
func _look() -> void:
	if not _free() or life.slots_now.is_empty() or _dest == Vector2.INF:
		return
	var p := Vector2(car.global_position.x, car.global_position.z)
	var hour: float = life.hour_now()
	_van_tick(hour, life.weekday_now())
	if not van.is_empty() and _van_node.visible and p.distance_to(Vector2(van["ring"].x, van["ring"].z)) <= ML_OFFER_R \
			and _session >= float(_cool.get(-3, 0.0)):
		_cool[-3] = _session + ML_COOL
		if offer_mlask():
			return
	if not dz_done and van_out(hour) and _session >= _dz_at:
		_dz_at = _session + DZ_COOL
		if offer_dzemini():
			return
	if crowds != null and Crowds.pistacja_drop(hour, life.weekday_now()) and crowds.by_id.has(Crowds.PISTACJA_ID):
		var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]
		if p.distance_to(site["door"]) <= OFFER_R and _session >= float(_cool.get(-1, 0.0)):
			_cool[-1] = _session + SLOT_COOL
			if offer_drop():
				return
	if hour >= CoffeeRun.HOURS[0] and hour < CoffeeRun.HOURS[1] and _session >= _kawa_at \
			and p.distance_to(CoffeeRun.DOCK) <= KAWA_CALL_R:
		_kawa_at = _session + CoffeeRun.COOL
		if offer_kawa_call():
			return
	if hour >= DESKI_HOURS[0] and hour < DESKI_HOURS[1] and _session >= _deski_at:
		_deski_at = _session + DESKI_COOL
		if offer_deski_call():
			return
	if crowds != null and crowds.by_id.has(Crowds.PADEL_ID) and int(Crowds.padel_queue(hour, life.weekday_now())[0]) >= CZ_MIN_QUEUE:
		var psite: Dictionary = crowds.sites[crowds.by_id[Crowds.PADEL_ID]]
		if p.distance_to(psite["door"]) <= OFFER_R and _session >= float(_cool.get(-2, 0.0)):
			_cool[-2] = _session + SLOT_COOL
			if offer_czwarty():
				return
	for i in life.slot_doors.size():
		var door: Vector2 = life.slot_doors[i]
		if door == Vector2.INF or p.distance_to(door) > OFFER_R or _session < float(_cool.get(i, 0.0)):
			continue
		if offers(life.slots_now[i], hour):
			_cool[i] = _session + SLOT_COOL
			offer(i)
			return


## G12c: the places for the full map's ZADANIA AUTO list while nothing is on: the open Wiralek
## slots ("Na czasie", only those not cooling down, so driving there brings the request), Mrożulo's
## van while it is out (Mlask) and PISTACJA's door during its Friday drop (Limitka). Each:
## {group, at (map x, z), colour, name [pl, en]}, as jobs.gd `offer_places`.
func offer_places() -> Array:
	var out: Array = []
	if state != State.IDLE or life == null or _dest == Vector2.INF:
		return out
	var hour: float = life.hour_now()
	for i in life.slot_doors.size():
		var door: Vector2 = life.slot_doors[i]
		if door == Vector2.INF or i >= life.slots_now.size() or _session < float(_cool.get(i, 0.0)):
			continue
		var st: Dictionary = life.slots_now[i]
		if offers(st, hour):
			out.append({"group": "trend", "at": door, "colour": COLOUR,
					"name": ["Na czasie · %s" % st["word"], "On trend · %s" % st["word"]]})
	if not van.is_empty() and van_out(hour) and _session >= float(_cool.get(-3, 0.0)):
		out.append({"group": "mlask", "at": Vector2(van["ring"].x, van["ring"].z), "colour": ML_COLOUR,
				"name": ["Mlask · van Mrożula", "Smack · Mrożulo's van"]})
	if crowds != null and Crowds.pistacja_drop(hour, life.weekday_now()) and crowds.by_id.has(Crowds.PISTACJA_ID) \
			and _session >= float(_cool.get(-1, 0.0)):
		var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]
		out.append({"group": "drop", "at": site["door"], "colour": DROP_COLOUR,
				"name": ["Limitka · PISTACJA DO KOŃCA", "Limited drop · PISTACJA DO KOŃCA"]})
	return out


## The request at slot `i` (--trend-job too). False if no door fits.
func offer(i: int) -> bool:
	var door: Vector2 = life.slot_doors[i]
	var st: Dictionary = life.slots_now[i]
	var k: Dictionary = jobs._kerb(door, door - life.slot_out[i] * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 7919 + i * 31 + int(st["cycle"]) * 3
	var dest := _dest
	var to: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, 0.0, 9000.0, rng,
			func(a: Dictionary) -> bool: return (a["door"] as Vector2).distance_to(dest) <= DEST_R)
	if to.is_empty():
		if log_on:
			print("trend job: no door by Rondo Daszyńskiego reached from slot %d" % (i + 1))
		return false
	order = {"slot": i, "word": str(st["word"]), "day": int(st["day"]), "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y),
			"door_ring": to["ring"], "road": float(to["road"]), "name": str(to["name"]),
			"customer": CUSTOMERS[rng.randi() % CUSTOMERS.size()]}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("NA CZASIE · %s" % order["word"], "Biuro z Ronda Daszyńskiego chce trend, zanim minie. Dowóz w 6 min.",
			PackedStringArray(["ACCEPT", "SKIP"]), COLOUR, "On trend · %s" % st["word"],
			"Rondo Daszyńskiego wants it before it's over. 6 min to deliver.")
	hud.ticker_out()
	if log_on:
		print("trend job: offer at slot %d (day %d, %s) for %s, %s, %.0f m by road" % [i + 1, order["day"], order["word"],
				order["customer"], order["name"], order["road"]])
	return true


## The limited drop's request at PISTACJA (--trend-job=4 too). False if no kerb or door fits.
func offer_drop() -> bool:
	if crowds == null or not crowds.by_id.has(Crowds.PISTACJA_ID):
		return false
	var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]
	var door: Vector2 = site["door"]
	var out: Vector2 = site["out"]
	var k: Dictionary = jobs._kerb(door, door - out * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 6007 + 17
	var to: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, DROP_FROM, DROP_TO, rng, func(_a: Dictionary) -> bool: return true)
	if to.is_empty():
		if log_on:
			print("trend job: no door %.0f-%.0f m from PISTACJA" % [DROP_FROM, DROP_TO])
		return false
	order = {"kind": "drop", "slot": -1, "word": "PISTACJA", "day": 0, "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y),
			"door_ring": to["ring"], "road": float(to["road"]), "name": str(to["name"]),
			"customer": DROP_FRIENDS[rng.randi() % DROP_FRIENDS.size()]}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("LIMITKA · PISTACJA", "Dropu jest tylko do 18:30. Znajomy chce pudełko, zanim się roztopi. Dowóz w 5 min.",
			PackedStringArray(["ACCEPT", "SKIP"]), DROP_COLOUR, "Limited drop · PISTACJA",
			"A friend wants a box before it melts. The drop ends at 18:30. 5 min to deliver.")
	hud.ticker_out()
	if log_on:
		print("trend job: drop offer at PISTACJA for %s, %s, %.0f m by road" % [order["customer"], order["name"], order["road"]])
	return true


## The "Czwarty" request at PADELNIA (--trend-job=5 too): the pickup is the player's door, the
## delivery the court's kerb. False if no kerb or door fits.
func offer_czwarty() -> bool:
	if crowds == null or not crowds.by_id.has(Crowds.PADEL_ID):
		return false
	var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PADEL_ID]]
	var door: Vector2 = site["door"]
	var out: Vector2 = site["out"]
	var venue := "PADELNIA"
	var k: Dictionary = jobs._kerb(door, door - out * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 4001 + 29
	var from: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, CZ_FROM, CZ_TO, rng, func(_a: Dictionary) -> bool: return true)
	if from.is_empty():
		if log_on:
			print("trend job: no door %.0f-%.0f m from %s" % [CZ_FROM, CZ_TO, venue])
		return false
	order = {"kind": "czwarty", "slot": -1, "word": "PADEL", "day": 0, "ring": from["ring"],
			"door_ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y),
			"road": float(from["road"]), "name": venue, "customer": CZ_PLAYERS[rng.randi() % CZ_PLAYERS.size()], "from": str(from["name"])}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("CZWARTY · " + venue.to_upper(), "Grają we trzech. Zabierz %s spod %s i dowieź na kort w 7 min." % [order["customer"], order["from"]],
			PackedStringArray(["ACCEPT", "SKIP"]), CZ_COLOUR, "Fourth player · " + venue,
			"Three players are waiting. Fetch %s from %s and bring them to the court in 7 min." % [order["customer"], order["from"]])
	hud.ticker_out()
	if log_on:
		print("trend job: czwarty offer at %s: %s from %s, %.0f m by road" % [venue, order["customer"], order["from"], order["road"]])
	return true


## The DESKA call (--trend-job=7 too): a friend phones, the club is short of a fourth. It rings
## first (the caller and a bio, ODBIERZ / ODRZUĆ, as Szymek's boat race and Ziomek's rave); an
## answered call says what it wants (_deski_offer). Accepting sets the gate as the target at once
## (no pickup). False in the air or with a job on.
func offer_deski_call(force := false) -> bool:
	if not force and not _free():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 7001 + 53 + roundi(_session)
	var who: String = DESKI_CALLERS[rng.randi() % DESKI_CALLERS.size()]
	var hurt: String = DESKI_INJURED[rng.randi() % DESKI_INJURED.size()]
	var gy: float = map.terrain_height(DESKI_GATE.x, DESKI_GATE.y)
	var dist := Vector2(player_pos.x, player_pos.z).distance_to(DESKI_GATE)
	# Not when the player is already by the court ("come over, 8 minutes" from 13 m: Mac run
	# 2026-11-07); the next call waits the full DESKI_COOL either way (the flag's call too).
	if not force and dist < DESKI_NEAR:
		return false
	_deski_at = maxf(_deski_at, _session + DESKI_COOL)
	order = {"kind": "czwarty", "call": true, "stage": "ring", "slot": -1, "word": "PADEL", "day": 0, "ring": Vector3(DESKI_GATE.x, gy, DESKI_GATE.y),
			"door_ring": Vector3(DESKI_GATE.x, gy, DESKI_GATE.y), "road": dist * 1.3,
			"name": "WTS DESKA", "customer": who, "from": "", "hurt": hurt, "seed": rng.randi()}
	state = State.OFFER
	_t = 0.0
	var bio: Array = DESKI_BIOS.get(who, ["Znajomy z padla.", "A friend from padel."])
	hud.show_side_card("📞 %s DZWONI" % who.to_upper(), bio[0],
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), CZ_COLOUR, "%s is calling" % who, bio[1])
	hud.ticker_out()
	Access.buzz(60, 0.6)
	if log_on:
		print("trend job: DESKA call ringing from %s, %.0f m away" % [who, dist])
	return true


## The answered DESKA call: what the friend wants.
func _deski_offer() -> void:
	order["stage"] = "offer"
	_t = 0.0
	var who: String = order["customer"]
	var hurt: String = order["hurt"]
	hud.show_side_card("%s: „BRAKUJE CZWARTEGO!”" % who.to_upper(),
			"„Halo? Gramy na Desce w padla, a %s ma nogę w gipsie po pole dance i wypadło z gry! Dojedź albo doleć na kort przy Zaruskiego, 8 minut. Kort opłacony do pełnej godziny!”" % hurt,
			PackedStringArray(["JADĘ!|ON MY WAY", "NIE DZIŚ|NOT TODAY"]), CZ_COLOUR, "%s: \"We need a fourth!\"" % who,
			"\"Hello? We're playing padel at DESKA, but %s has a leg in plaster after pole dance and dropped out! Drive or fly to the court on Zaruskiego, 8 minutes. The court is paid till the hour!\"" % hurt)
	if log_on:
		print("trend job: DESKA call answered: %s broke a leg" % hurt)


# --- "Mlask": Mrożulo's review (G5) ----------------------------------------------------------

## The van's mesh: a cream box van, a pink band, dark windows, the big lens on the roof, in the
## models' one material (~150 plus the lettering). Local frame: +Z forward, origin on the ground.
static func van_mesh() -> ArrayMesh:
	var st := Models._begin()
	Models.box(st, Vector3(0, 1.25, 0), Vector3(2.0, 1.9, 5.2), VAN_CREAM)
	Models.box(st, Vector3(0, 0.95, 0), Vector3(2.04, 0.28, 5.24), VAN_PINK)
	Models.box(st, Vector3(0, 1.75, 2.35), Vector3(1.86, 0.6, 0.56), VAN_DARK)
	Models.box(st, Vector3(1.01, 1.7, 0.6), Vector3(0.04, 0.55, 1.6), VAN_DARK)
	Models.box(st, Vector3(-1.01, 1.7, 0.6), Vector3(0.04, 0.55, 1.6), VAN_DARK)
	for z: float in [-1.7, 1.7]:
		for x: float in [-0.95, 0.95]:
			Models.box(st, Vector3(x, 0.32, z), Vector3(0.3, 0.64, 0.64), VAN_DARK)
	Models.box(st, Vector3(0, 2.3, -0.4), Vector3(0.5, 0.2, 0.5), VAN_DARK)
	Models.box(st, Vector3(0, 2.62, -0.4), Vector3(0.62, 0.44, 0.9), VAN_DARK)
	Models.box(st, Vector3(0, 2.62, 0.12), Vector3(0.5, 0.36, 0.16), VAN_PINK)
	var mesh := st.commit()
	var tx := _van_lettering("MROŻULO TV", -0.2, 0.58)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tx.surface_get_arrays(0))
	return mesh


## `text` in the pixel font (5 cm pixels, flat dark quads, a row's lit run is one quad) on both
## flanks of the van, centred at (zc, yc), below the pink band: a second surface of the van mesh.
static func _van_lettering(text: String, zc: float, yc: float) -> ArrayMesh:
	var s := Models.Shape.new()
	var f := Models.fin(VAN_DARK)
	var px := 0.05
	var wide := PixelFont.width(text) * px
	var runs := {}  # row -> sorted columns
	PixelFont.each_pixel(text, 0, func(col: int, row: int) -> void:
		if not runs.has(row):
			runs[row] = []
		runs[row].append(col))
	for sgn: float in [-1.0, 1.0]:
		# Seen from +x the text runs towards -z, from -x towards +z.
		var x := sgn * 1.03
		var start := zc + sgn * wide * 0.5
		var top := yc + 3.5 * px + PixelFont.BODY * px
		for row: int in runs:
			var cols: Array = runs[row]
			cols.sort()
			var i := 0
			while i < cols.size():
				var j := i
				while j + 1 < cols.size() and int(cols[j + 1]) == int(cols[j]) + 1:
					j += 1
				var za := start - sgn * int(cols[i]) * px
				var zb := start - sgn * (int(cols[j]) + 1) * px
				var yt := top - row * px
				s.side_rect(x, sgn, yt - px, yt, minf(za, zb), maxf(za, zb), f)
				i = j + 1
	return s.mesh()


## Five fans standing behind the van along the kerb, one holding a phone up: a single mesh in the
## van's local frame (a child of it, so it parks and hides with it).
static func fans_mesh() -> ArrayMesh:
	var st := Models._begin()
	var spots := [Vector3(-0.7, 0, -3.4), Vector3(0.5, 0, -3.7), Vector3(-0.1, 0, -4.5), Vector3(1.0, 0, -4.6), Vector3(-1.1, 0, -4.9)]
	for i in spots.size():
		var o: Vector3 = spots[i]
		var shirt := Color(FAN_SHIRTS[i % FAN_SHIRTS.size()])
		for side in [-1.0, 1.0]:
			Models.box(st, o + Vector3(0.11 * side, 0.43, 0), Vector3(0.17, 0.86, 0.22), VAN_DARK)
		Models.box(st, o + Vector3(0, 1.15, 0), Vector3(0.46, 0.62, 0.28), shirt)
		for side in [-1.0, 1.0]:
			Models.box(st, o + Vector3(0.29 * side, 1.12, 0), Vector3(0.12, 0.56, 0.16), shirt)
		Models.box(st, o + Vector3(0, 1.58, 0), Vector3(0.26, 0.26, 0.26), Color("#e2b48c"))
		Models.box(st, o + Vector3(0, 1.72, 0.02), Vector3(0.28, 0.08, 0.3), Color("#4a3426"))
	# The phone, raised towards the van: the third fan's arm up, a dark slab with a lit face.
	Models.box(st, spots[2] + Vector3(0.2, 1.62, 0.28), Vector3(0.1, 0.18, 0.04), VAN_DARK)
	return st.commit()


## Is the van out at `hour`? Its spot on `weekday` (1 Monday .. 7 Sunday).
static func van_out(hour: float) -> bool:
	return hour >= float(ML_HOURS[0]) and hour < float(ML_HOURS[1])


static func van_spot(weekday: int) -> String:
	return ML_SPOTS[posmod(weekday, ML_SPOTS.size())]


## The grade's words: [Polish, English] ("7,5 MLASKA", "8 MLASKÓW", "3 MLASKI"; "7.5 SMACKS").
static func grade_words(g: float) -> Array:
	var whole := is_equal_approx(g, roundf(g))
	var num_pl := ("%d" % int(g)) if whole else ("%d,%d" % [int(g), int(roundf(g * 10.0)) % 10])
	var num_en := ("%d" % int(g)) if whole else ("%.1f" % g)
	var word := "MLASKA"
	if whole:
		var n := int(g)
		word = "MLASK" if n == 1 else ("MLASKI" if n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14) else "MLASKÓW")
	return ["%s %s" % [num_pl, word], "%s SMACK%s" % [num_en, "" if num_en == "1" else "S"]]


## The pay for `road_m` metres by road (the bring leg; the sticker goes back the same way).
static func ml_pay(road_m: float, warm: bool, on_time: bool) -> Dictionary:
	var base := ML_BASE + roundi(ML_PER_KM * 2.0 * road_m / 1000.0)
	var good := warm and on_time
	var tip := ML_TIP if good else 0
	return {"zl": (base if good else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": ML_RESPECT if good else 0}


## Puts the van at today's spot while it is out (twice a second, from _look).
func _van_tick(hour: float, weekday: int) -> void:
	var out := van_out(hour)
	if weekday != _van_day:
		_van_day = weekday
		van = _park_van(van_spot(weekday))
	var show := (out or (_is_dz() and busy())) and not van.is_empty()
	if _van_node != null and _van_node.visible != show:
		_van_node.visible = show
	if show:
		_fans_tick(hour)
	else:
		_egg_t = 0.0


## Twice a second while the van is out: the fans' chatter when the car is near, and the egg (the
## car parked by the van while he films). `hour` is the game hour.
func _fans_tick(_hour: float) -> void:
	var at: Vector3 = van["at"]
	var d := Vector2(car.global_position.x - at.x, car.global_position.z - at.z).length()
	if d <= FAN_TALK_R and dialogue != null:
		_fan_t -= 0.5
		if _fan_t <= 0.0:
			_fan_t = _rng.randf_range(FAN_GAP[0], FAN_GAP[1])
			var back := Vector3(at.x, at.y, at.z) + (_van_node.global_transform.basis * Vector3(0, 0, -4.0))
			dialogue.say_ambient(func() -> Vector3: return back, "", "viral", "mrozulo", 4.0, ML_COLOUR, 2.2, true)
	if d <= EGG_R and not flying and car.velocity.length() < 1.0:
		_egg_t += 0.5
		if _egg_t >= EGG_SECS and egg.is_valid():
			_egg_t = -1000.0
			egg.call(EGG_ID)
	elif _egg_t > 0.0:
		_egg_t = 0.0


## The van by the kerb nearest the place `spot` (or at the point `near`): {spot, at, ring, yaw}.
func _park_van(spot: String, near := Vector2.INF) -> Dictionary:
	var p: Vector2 = near if near != Vector2.INF else _places.get(spot, Vector2.INF)
	if p == Vector2.INF:
		if log_on:
			print("trend job: Mrożulo's van: no place %s" % spot)
		return {}
	var hit: Array = graph.snap(p, 80.0)
	if hit.is_empty():
		if log_on:
			print("trend job: Mrożulo's van: no road within 80 m of %s" % spot)
		return {}
	var road: Vector2 = graph.point_at(hit[0], hit[2])
	var toward := road if road.distance_to(p) > 1.0 else p + Vector2(4.0, 0.0)
	var k: Dictionary = jobs._kerb(road + (p - road).normalized() * 0.5 if road.distance_to(p) > 1.0 else p, toward, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		if log_on:
			print("trend job: Mrożulo's van: no kerb by %s" % spot)
		return {}
	var side: Vector2 = k["side"]
	var c: Vector2 = k["centre"]
	var ring2 := c + side * 2.0
	var at2 := c + side * 4.4
	var y: float = graph.surface(k["edge"], ring2)
	var yaw := atan2(side.y, -side.x)
	var v := {"spot": spot, "ring": Vector3(ring2.x, y, ring2.y), "at": Vector3(at2.x, map.ground_height(at2.x, at2.y), at2.y), "yaw": yaw}
	if _van_node != null:
		_van_node.global_transform = Transform3D(Basis(Vector3.UP, yaw), v["at"])
	if log_on:
		print("trend job: Mrożulo's van at %s (%.0f, %.0f)" % [spot, at2.x, at2.y])
	return v


## The new place he wants: the nearest open Wiralek slot on its days 1-3, else KUKŁA's nearest
## door: {name, ring: Vector3, edge, s, slot (index or -1), site (crowds id or "")} or {}.
func _new_place(from: Vector2, hour: float) -> Dictionary:
	var best := {}
	var bd := INF
	for i in life.slot_doors.size():
		var door: Vector2 = life.slot_doors[i]
		var st: Dictionary = life.slots_now[i]
		if door == Vector2.INF or int(st.get("day", 8)) > 3 or not offers(st, hour):
			continue
		var d := door.distance_to(from)
		if d < bd:
			var k: Dictionary = jobs._kerb(door, door - life.slot_out[i] * 4.0, 3.5, [1.4, 2.2, 3.0])
			if not k.is_empty():
				bd = d
				var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
				best = {"name": str(st["word"]), "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "edge": k["edge"],
						"s": k["s"], "slot": i, "site": CityLife.SLOTS[i]}
	if not best.is_empty() or crowds == null:
		return best
	for id: String in Crowds.KUKLA:
		if not crowds.by_id.has(id):
			continue
		var site: Dictionary = crowds.sites[crowds.by_id[id]]
		if not site.has("door"):
			continue
		var door: Vector2 = site["door"]
		var d := door.distance_to(from)
		if d < bd:
			var k: Dictionary = jobs._kerb(door, door - (site["out"] as Vector2) * 4.0, 3.5, [1.4, 2.2, 3.0])
			if not k.is_empty():
				bd = d
				var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
				best = {"name": "KUKŁA", "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "edge": k["edge"],
						"s": k["s"], "slot": -1, "site": id}
	return best


## Mrożulo's request by his van (--trend-job=6 too, which first parks the van by the car).
func offer_mlask(force_here := false) -> bool:
	if force_here:
		var p := Vector2(car.global_position.x, car.global_position.z)
		van = _park_van("here", p + Vector2(0.0, -12.0))
		_van_day = life.weekday_now() if life != null else -1
		if _van_node != null:
			_van_node.visible = not van.is_empty()
	if van.is_empty():
		return false
	var vr: Vector3 = van["ring"]
	var place := _new_place(Vector2(vr.x, vr.z), life.hour_now())
	if place.is_empty():
		if log_on:
			print("trend job: Mrożulo found no new place open")
		return false
	var road := Vector2(vr.x, vr.z).distance_to(Vector2(place["ring"].x, place["ring"].z)) * 1.3
	order = {"kind": "mlask", "stage": "fetch", "slot": int(place["slot"]), "word": str(place["name"]), "day": 0,
			"ring": place["ring"], "door_ring": vr, "road": road, "name": "Mrożulo", "customer": "Mrożulo",
			"site": str(place["site"]), "place_ring": place["ring"], "warm": true}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("MLASK · MROŻULO", "Siema, tu Mrożulo! %s, nowe miejsce. Weź mi coś, tylko ma być ciepłe." % order["word"],
			PackedStringArray(["ACCEPT", "SKIP"]), ML_COLOUR, "Smack · Mrożulo",
			"Hi, Mrożulo here! %s, a new place. Grab me something, and keep it warm." % order["word"])
	hud.ticker_out()
	if log_on:
		print("trend job: Mrożulo's offer: %s, %.0f m" % [order["word"], road])
	return true


func _is_ml() -> bool:
	return str(order.get("kind", "")) == "mlask"


## At the van: the review card; the sticker leg starts when it is closed.
func _arrive_ml_review() -> void:
	var warm := _clock <= ML_WARM
	order["warm"] = warm
	order["bring_s"] = _clock
	var g: float = ML_GRADES[_rng.randi() % ML_GRADES.size()] if warm else ML_COLD_GRADE
	order["grade"] = g
	var gw := grade_words(g)
	var l: Array = dialogue.line("mrozulo_review", "warm" if warm else "cold", true) if dialogue != null else []
	var line := [str(l[0]), str(l[1])] if not l.is_empty() else ["Je się. Mlaska się.", "One eats. One smacks."]
	order["stage"] = "review"
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	hud.show_side_card("RECENZJA · %s" % gw[0], "„%s”\nZawieź naklejkę do %s w 4 min." % [line[0], order["word"]],
			PackedStringArray(["NAKLEJKA"]), ML_COLOUR, "Review · %s" % gw[1], "\"%s\"\nTake the sticker to %s in 4 min." % [line[1], order["word"]])
	print("trend job: Mrożulo reviewed %s after %.0f s (%s): %s" % [order["word"], _clock, "warm" if warm else "cold", gw[0]])


## The sticker leg: back to the place.
func _start_sticker() -> void:
	order["stage"] = "sticker"
	order["door_ring"] = order["place_ring"]
	state = State.DELIVER
	_clock = 0.0
	_t = 0.0
	hud.hide_card()
	_beacon.waving = true
	_beacon.place(order["door_ring"], ARRIVE - 0.5)
	hud.toast("Naklejka MLASK: do %s" % order["word"], "The MLASK sticker: to %s" % order["word"])


func _arrive_ml_sticker() -> void:
	var on_time := _clock <= ML_STICKER
	var r := ml_pay(float(order["road"]), bool(order["warm"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	if crowds != null and crowds.has_method("mrozulo_boost") and str(order["site"]) != "":
		crowds.mrozulo_boost(str(order["site"]))
	var l: Array = dialogue.line("mrozulo_owner", "", false) if dialogue != null else []
	var line := [str(l[0]), str(l[1])] if not l.is_empty() else ["Mrożulo nas polecił? Otwieram drugą kasę.", "Mrożulo recommends us? Opening a second till."]
	var gw := grade_words(float(order["grade"]))
	var head := "MLASK · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n%s · +%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["word"], gw[0], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n%s · +%d zł (tip %d zł), +%d respect" % [line[1], gw[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	order["stage"] = "done"
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card(head, body, PackedStringArray(["OK"]), ML_COLOUR, "Smack · +%d zł" % int(r["zl"]), body_en)
	print("trend job: the MLASK sticker at %s in %.0f s (%s, %s): +%d zł (base %d, tip %d), +%d respect, the queue grows" % [
			order["word"], _clock, "warm" if bool(order["warm"]) else "cold", "on time" if on_time else "late", int(r["zl"]),
			int(r["base"]), int(r["tip"]), int(r["respect"])])


# --- "Dżemini": Mrożulo's call (G5b) ----------------------------------------------------------

func _is_dz() -> bool:
	return str(order.get("kind", "")) == "dzemini"


## The "Dżemini" pay for `road_m` metres by road (the shop to the van): {zl, base, tip, respect}.
static func dz_pay(road_m: float, warm: bool) -> Dictionary:
	var base := DZ_BASE + roundi(DZ_PER_KM * road_m / 1000.0)
	var tip := DZ_TIP if warm else 0
	return {"zl": (base if warm else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": DZ_RESPECT if warm else 0}


## Mrożulo's call (--trend-job=8 too, with `force`): pickup by DŻEMINI's queue, delivery to his van
## at today's spot. False with a job on (unless forced), or no shop, kerb or van spot.
func offer_dzemini(force := false) -> bool:
	if not force and not _free():
		return false
	if crowds == null or not crowds.by_id.has(DZ_SITE):
		return false
	var site: Dictionary = crowds.sites[crowds.by_id[DZ_SITE]]
	if not site.has("door") or not site.has("out"):
		return false
	var door: Vector2 = site["door"]
	var k: Dictionary = jobs._kerb(door, door - (site["out"] as Vector2) * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	if van.is_empty() and life != null:
		# Today's spot, else the next of his spots that has a kerb.
		_van_day = life.weekday_now()
		for k2 in ML_SPOTS.size():
			van = _park_van(van_spot(_van_day + k2))
			if not van.is_empty():
				break
	if van.is_empty():
		if log_on:
			print("trend job: Dżemini: no van spot")
		return false
	if _van_node != null:
		_van_node.visible = true
	var vr: Vector3 = van["ring"]
	var road := kerb.distance_to(Vector2(vr.x, vr.z)) * 1.3
	order = {"kind": "dzemini", "stage": "fetch", "slot": -1, "word": "DŻEMINI", "day": 0,
			"ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "door_ring": vr, "road": road,
			"name": "Mrożulo", "customer": "Mrożulo", "site": DZ_SITE}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("📞 MROŻULO DZWONI",
			"„Siema, tu Mrożulo! Na Świętokrzyskiej otworzyli DŻEMINI KEBAB, mięso kroi agent AI. Kup mi jednego i przywieź do vana, póki ciepły!”",
			PackedStringArray(["JADĘ", "NIE TERAZ"]), ML_COLOUR, "Mrożulo is calling",
			"\"Hi, Mrożulo here! DŻEMINI KEBAB just opened on Świętokrzyska, an AI agent carves the meat. Get me one and bring it to my van while it's warm!\"")
	hud.ticker_out()
	if log_on:
		print("trend job: Dżemini call from Mrożulo: the van at %s, %.0f m by road" % [van["spot"], road])
	return true


## At the van: he bites ("Wjeżdżam w to."), the pay, and for good the MLASK on DŻEMINI (the save,
## the queue, the sticker). The TYGRAM message follows when the card closes.
func _arrive_dz() -> void:
	var warm := _clock <= ML_WARM
	var r := dz_pay(float(order["road"]), warm)
	dz_done = true
	wallet.keep[DZ_KEEP] = true
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	if crowds != null and crowds.has_method("dzemini_mlask"):
		crowds.dzemini_mlask()
	_place_sticker()
	var line := ["*mlask* … Wjeżdżam w to.", "*smack* … I'm going in."] if warm \
			else ["Letni, ale… *mlask* … wjeżdżam w to.", "Lukewarm, but… *smack* … I'm going in."]
	order["stage"] = "review"
	order["warm"] = warm
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card("MROŻULO · +%d zł" % int(r["zl"]),
			"„%s”\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], int(r["zl"]), int(r["tip"]), int(r["respect"])],
			PackedStringArray(["OK"]), ML_COLOUR, "Mrożulo · +%d zł" % int(r["zl"]),
			"\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])])
	print("trend job: Dżemini kebab to Mrożulo in %.0f s (%s): +%d zł (base %d, tip %d), +%d respect, MLASK on DŻEMINI for good" % [
			_clock, "warm" if warm else "cold", int(r["zl"]), int(r["base"]), int(r["tip"]), int(r["respect"])])


## The TYGRAM message from Mrożulo (the messenger parody's blue card), then the job ends.
func _dz_tygram() -> void:
	order["stage"] = "tygram"
	_t = 0.0
	hud.show_side_card("TYGRAM · MROŻULO",
			"„DŻEMINI: MLASK! Naklejka już wisi na szybie. Jutro kolejka do Marszałkowskiej. Dzięki, kierowco!”",
			PackedStringArray(["OK"]), TYGRAM_COLOUR, "TYGRAM · Mrożulo",
			"\"DŻEMINI: SMACK! The sticker's on the window. Tomorrow the queue reaches Marszałkowska. Thanks, driver!\"")
	print("trend job: TYGRAM from Mrożulo: DŻEMINI gets the MLASK")


## The MLASK sticker on DŻEMINI's wall beside its sign, once the shop's sector has placed it.
func _place_sticker() -> void:
	if _sticker != null or _world == null or storefronts == null or not storefronts.has_method("venue_wall"):
		return
	var w: Dictionary = storefronts.venue_wall(DZ_SITE)
	if w.is_empty():
		return
	var n: Vector3 = w["n"]
	var t: Vector3 = w["t"]
	_sticker = MeshInstance3D.new()
	_sticker.name = "DzeminiSticker"
	_sticker.mesh = sticker_mesh()
	_sticker.material_override = Models.material()
	_sticker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sticker.visibility_range_end = 260.0
	_world.add_child(_sticker)
	var at: Vector3 = (w["p"] as Vector3) + Vector3.UP * maxf(float(w["up"]) - 0.9, 1.5) + t * 1.8 + n * 0.16
	_sticker.global_transform = Transform3D(Basis(t, Vector3.UP, n), at)
	if log_on:
		print("trend job: the MLASK sticker on DŻEMINI at %.1f, %.1f" % [at.x, at.z])


## The sticker: a yellow decal with a pink edge and "MLASK" in dark pixel letters (~200 triangles).
## Local frame: x along the wall, y up, +z out of it.
static func sticker_mesh() -> ArrayMesh:
	var st := Models._begin()
	var tw := PixelFont.width("MLASK") * STICKER_PX
	var w := tw + 0.24
	var h := PixelFont.ROWS * STICKER_PX + 0.12
	Models.box(st, Vector3(0, 0, 0.005), Vector3(w + 0.08, h + 0.08, 0.01), VAN_PINK)
	Models.box(st, Vector3(0, 0, 0.012), Vector3(w, h, 0.014), STICKER_YELLOW)
	PixelFont.add_quads(st, "MLASK", Vector3(-tw * 0.5, PixelFont.ROWS * STICKER_PX * 0.5, 0.02), Vector3.RIGHT, Vector3.DOWN,
			STICKER_PX, VAN_DARK, Models.FIXED)
	return st.commit()


func _is_cz() -> bool:
	return str(order.get("kind", "")) == "czwarty"


func _is_drop() -> bool:
	return str(order.get("kind", "")) == "drop"


func _withdraw() -> void:
	hud.hide_card()
	state = State.IDLE
	_t = 0.0


func _on_card(index: int) -> void:
	match state:
		State.OFFER:
			if index == 0 and str(order.get("stage", "")) == "ring":
				_deski_offer()
			elif index == 0:
				_accept()
			else:
				if log_on and bool(order.get("call", false)):
					print("trend job: DESKA call declined (%s)" % order.get("stage", ""))
				_withdraw()
		State.RESULT:
			if str(order.get("stage", "")) == "match":
				_match_answer(index)
			elif _is_ml() and str(order.get("stage", "")) == "review":
				_start_sticker()
			elif _is_dz() and str(order.get("stage", "")) == "review":
				_dz_tygram()
			else:
				_release()


func _accept() -> void:
	if _is_kawa():
		_accept_kawa()
		return
	if bool(order.get("call", false)):
		_accept_call()
		return
	state = State.PICKUP
	_t = 0.0
	_hold = 0.0
	hud.hide_card()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()
	_beacon.recolour(ML_COLOUR if _is_ml() or _is_dz() else (DROP_COLOUR if _is_drop() else (CZ_COLOUR if _is_cz() else COLOUR)))
	_beacon.waving = false
	_beacon.place(order["ring"], PICKUP - 0.5, true, false)
	if _is_ml():
		hud.toast("Mlask: na wynos dla Mrożula", "Smack: a takeaway for Mrożulo")
	elif _is_dz():
		hud.toast("Dżemini: kebab dla Mrożula, Świętokrzyska", "Dżemini: a kebab for Mrożulo, on Świętokrzyska")
	elif _is_drop():
		hud.toast("Limitka: stań w kolejce po pudełko", "Limited drop: join the queue for a box")
	elif _is_cz():
		hud.toast("Czwarty: jedź po gracza", "Fourth player: go and fetch them")
	else:
		hud.toast("Na czasie: odbiór przy kolejce", "On trend: pick up by the queue")
	if log_on:
		print("trend job: accepted")


func _accept_call() -> void:
	state = State.DELIVER
	_clock = 0.0
	_t = 0.0
	hud.hide_card()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()
	_beacon.recolour(CZ_COLOUR)
	_beacon.waving = true
	_beacon.place(order["door_ring"], ARRIVE - 0.5)
	hud.toast("Czwarty: na kort Deski, jedź albo leć", "Fourth player: to the DESKA court, drive or fly")
	if log_on:
		print("trend job: DESKA call accepted")


func _pickup_tick(dt: float) -> void:
	var d := _flat(car.global_position, order["ring"])
	var drop := _is_drop()
	if drop and not force_drop and crowds != null and life != null and not Crowds.pistacja_drop(life.hour_now(), life.weekday_now()):
		_fail(["Wyprzedane! Drop się skończył.", "Sold out! The drop is over."])
		return
	var hold_for := DROP_HOLD if drop else PICKUP_HOLD
	if d < PICKUP and car.vel.length() < PICKUP_SPEED and not flying:
		_hold += dt
		if _hold >= hold_for:
			state = State.DELIVER
			_clock = 0.0
			_t = 0.0
			_beacon.waving = true
			_beacon.place(order["door_ring"], ARRIVE - 0.5)
			if _is_ml():
				hud.toast("Kolejka przepuszcza: to dla Mrożula! Wieź, póki ciepłe", "The queue lets you through: it's for Mrożulo! Bring it warm")
			elif _is_dz():
				hud.toast("Agent: „Na pewno kebab? Mogę też napisać o nim wiersz.”", "The agent: \"Sure about the kebab? I can also write a poem about it.\"")
			elif _is_cz():
				hud.toast("Jest! Na kort, grają bez ciebie", "Got them! To the court, they're starting without you")
			elif drop:
				hud.toast("Ostatnie pudełko! Zanim się roztopi", "The last box! Before it melts")
			else:
				hud.toast("Odbiór na aplikację: kolejka przepuszcza kuriera", "App pickup: the queue lets the courier through")
			if log_on:
				print("trend job: picked up at slot %d, %.0f m by road to go" % [int(order["slot"]) + 1, order["road"]])
			return
	else:
		_hold = 0.0
	if drop:
		hud.show_status("LIMITKA · KOLEJKA", "", "%d m" % roundi(d), "Stań w kolejce", _hold / hold_for, DROP_COLOUR, "", {},
				"Wait in the queue")
		return
	if _is_dz():
		hud.show_status("DŻEMINI · ODBIÓR", "", "%d m" % roundi(d), "Stań przy kolejce", _hold / PICKUP_HOLD, ML_COLOUR, "", {},
				"Stop by the queue")
		return
	if _is_ml():
		hud.show_status("MLASK · %s" % order["word"], "", "%d m" % roundi(d), "Stań przy kolejce", _hold / PICKUP_HOLD, ML_COLOUR, "", {},
				"Stop by the queue")
		return
	if _is_cz():
		hud.show_status("CZWARTY · ODBIÓR", "", "%d m" % roundi(d), "Stań pod drzwiami gracza", _hold / PICKUP_HOLD, CZ_COLOUR, "", {},
				"Stop at the player's door")
		return
	hud.show_status("NA CZASIE · ODBIÓR", "", "%d m" % roundi(d), "Stań przy kolejce", _hold / PICKUP_HOLD, COLOUR, "", {},
			"Stop by the queue")


func _deliver_tick(dt: float) -> void:
	if _is_kawa():
		_kawa_tick(dt)
		return
	_clock += dt
	var is_call := bool(order.get("call", false))
	var d := _flat(player_pos if is_call else car.global_position, order["door_ring"])
	if is_call and flying and d < DESKI_FLY_R:
		_arrive()
		return
	if d < ARRIVE and car.vel.length() < ARRIVE_SPEED and not flying:
		_arrive()
		return
	if _is_ml() or _is_dz():
		_ml_status(d)
		return
	var drop := _is_drop()
	var cz := _is_cz()
	var limit := DROP_LIMIT if drop else ((DESKI_LIMIT if is_call else CZ_LIMIT) if cz else LIMIT)
	var tint := DROP_COLOUR if drop else (CZ_COLOUR if cz else COLOUR)
	var left := limit - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := (["Jedź lub leć do turkusowego światła", "Drive or fly to the teal beacon"] if is_call else ["Jedź do turkusowego światła", "Head for the teal beacon"] if cz else ["Jedź do zielonego światła", "Head for the green beacon"] if drop else ["Jedź do różowego światła", "Head for the pink beacon"]) if d > 40.0 else ["Stań pod drzwiami", "Stop at the door"]
	if left <= 0.0:
		hint = ["Spóźnione, ale dowieź", "Late, but deliver it"]
	hud.show_status(("CZWARTY → %s" if cz else "LIMITKA → %s" if drop else "NA CZASIE → %s") % order["name"], clock, "%d m" % roundi(d), hint[0],
			clampf(_clock / limit, 0.0, 1.0), tint if left > 0.0 else FAIL_COLOUR, "", {}, hint[1])


func _ml_status(d: float) -> void:
	var sticker := str(order.get("stage", "")) == "sticker"
	var limit := ML_STICKER if sticker else ML_WARM
	var left := limit - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := ["Stań przy drzwiach", "Stop at the door"] if sticker else ["Do vana Mrożula, póki ciepłe", "To Mrożulo's van while it's warm"]
	if left <= 0.0:
		hint = ["Spóźnione, ale dowieź", "Late, but deliver it"] if sticker else ["Stygnie… jedź dalej", "It's going cold… keep going"]
	hud.show_status(("MLASK → %s" % order["word"]) if sticker else ("DŻEMINI → MROŻULO" if _is_dz() else "MLASK → MROŻULO"), clock, "%d m" % roundi(d), hint[0],
			clampf(_clock / limit, 0.0, 1.0), ML_COLOUR if left > 0.0 else FAIL_COLOUR, "", {}, hint[1])


func _arrive() -> void:
	if _is_dz():
		_arrive_dz()
		return
	if _is_ml():
		if str(order.get("stage", "")) == "sticker":
			_arrive_ml_sticker()
		else:
			_arrive_ml_review()
		return
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	if _is_drop():
		_arrive_drop()
		return
	if _is_cz():
		_arrive_cz()
		return
	var on_time := _clock <= LIMIT
	var r := pay(float(order["road"]), int(order["day"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["", ""]
	if bool(r["out"]):
		var l: Array = dialogue.line("viral", "late", true) if dialogue != null else []
		if not l.is_empty():
			line = [str(l[0]), str(l[1])]
	elif not on_time:
		line = ["Spóźnione. Trend poszedł dalej beze mnie.", "Late. The trend moved on without me."]
	else:
		line = ["Jeszcze ciepłe i jeszcze modne. Dziękuję!", "Still warm and still trendy. Thank you!"]
	var head := "NA CZASIE · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	hud.show_side_card(head, body, PackedStringArray(["OK"]), COLOUR, "On trend · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered %s to %s in %.0f s (%s, trend day %d): +%d zł (base %d, tip %d), +%d respect%s" % [order["word"],
			order["name"], _clock, "on time" if on_time else "late", int(order["day"]), int(r["zl"]), int(r["base"]), int(r["tip"]),
			int(r["respect"]), ", \"to już niemodne\"" if bool(r["out"]) else ""])


func _arrive_cz() -> void:
	var call := bool(order.get("call", false))
	var on_time := _clock <= (DESKI_LIMIT if call else CZ_LIMIT)
	if call:
		order["flew"] = flying
		if on_time:
			_start_match()
			return
	var r := cz_pay(float(order["road"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["Jesteśmy w czterech! Ściana nas nie zje.", "Four of us! The wall won't eat us."]
	if not on_time:
		line = ["Zagraliśmy w trzech. Piłka i tak wróciła.", "We played three-a-side. The ball came back anyway."]
		if call:
			line = ["Zagraliśmy w trzech, ale piłka i tak wróciła. Dzięki, że dojechałeś.", "We played three-a-side, the ball came back anyway. Thanks for coming."]
	var head := "CZWARTY · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	state = State.RESULT
	_t = 0.0
	hud.show_side_card(head, body, PackedStringArray(["OK"]), CZ_COLOUR, "Fourth player · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered %s (Czwarty) to %s in %.0f s (%s): +%d zł (base %d, tip %d), +%d respect" % [order["customer"], order["name"], _clock,
			"on time" if on_time else "late", int(r["zl"]), int(r["base"]), int(r["tip"]), int(r["respect"])])


## The DESKA call's rallies for `seed`: DESKI_POINTS distinct indices into RALLIES.
static func match_rallies(seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool: Array = range(RALLIES.size())
	var out: Array = []
	while out.size() < DESKI_POINTS:
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out


## The match's pay on top of the call's (cz_pay on time): {zl, respect} for `won` points, landing
## by helicopter (`flew`) adds FLY_RESPECT.
static func match_pay(won: int, flew: bool) -> Dictionary:
	return {"zl": MATCH_ZL * won, "respect": MATCH_RESPECT * won + (FLY_RESPECT if flew else 0)}


## On time at DESKA: the match, one card per point, the three shots in a row on the centred card
## (the car stands still). Beside the car the card never showed on a 16:9 screen: three shots in a
## row were wider than the room there, stacked they were taller than the screen (Mac Autopilot,
## 2026-11-07).
func _start_match() -> void:
	state = State.RESULT
	order["stage"] = "match"
	order["rallies"] = match_rallies(int(order.get("seed", done)))
	order["point"] = 0
	order["won"] = 0
	order["said"] = ""
	_ask_point()
	if log_on:
		print("trend job: DESKA match starts (%s)" % ("landed by helicopter" if bool(order["flew"]) else "by car"))


func _ask_point() -> void:
	_t = 0.0
	var i: int = order["point"]
	var rally: Array = RALLIES[int(order["rallies"][i])]
	var buttons := PackedStringArray()
	for shot: Array in SHOTS:
		buttons.append("%s|%s" % [shot[0], shot[1]])
	var said: String = order["said"]
	var said_en: String = order.get("said_en", "")
	var lead := ""
	var lead_en := ""
	if i == 0:
		lead = "Pani Basia z recepcji: „Parking dla helikopterów jest od strony Wisły.” " if bool(order["flew"]) else "%s podaje ci rakietę. " % order["customer"]
		lead_en = "Pani Basia from reception: \"The helicopter parking is on the river side.\" " if bool(order["flew"]) else "%s hands you a racket. " % order["customer"]
	elif said != "":
		lead = said + " "
		lead_en = said_en + " "
	hud.show_card("PADEL · PUNKT %d/%d · %d:%d" % [i + 1, DESKI_POINTS, int(order["won"]), i - int(order["won"])],
			lead + str(rally[0][0]), buttons, CZ_COLOUR, false, "Padel · point %d/%d · %d-%d" % [i + 1, DESKI_POINTS, int(order["won"]), i - int(order["won"])],
			lead_en + str(rally[0][1]))


func _match_answer(index: int) -> void:
	var rally: Array = RALLIES[int(order["rallies"][int(order["point"])])]
	var won := index == int(rally[1])
	if won:
		order["won"] = int(order["won"]) + 1
	order["said"] = str(rally[2][0] if won else rally[3][0])
	order["said_en"] = str(rally[2][1] if won else rally[3][1])
	if index < 0:
		order["said"] = "Piłka przeleciała obok. Rywale nawet nie czekali."
		order["said_en"] = "The ball went by. The other pair didn't wait."
	if log_on:
		print("trend job: DESKA point %d: %s, %s" % [int(order["point"]) + 1, SHOTS[index][1] if index >= 0 else "none", "won" if won else "lost"])
	order["point"] = int(order["point"]) + 1
	if int(order["point"]) < DESKI_POINTS:
		_ask_point()
		return
	_end_match()


## The match's end: the call's pay (on time) and the match's, the score on a card.
func _end_match() -> void:
	order["stage"] = "done"
	var won: int = order["won"]
	var flew := bool(order["flew"])
	var r := cz_pay(float(order["road"]), true)
	var m := match_pay(won, flew)
	var zl := int(r["zl"]) + int(m["zl"])
	var respect := int(r["respect"]) + int(m["respect"])
	wallet.pay(zl, respect, "trend")
	done += 1
	var score: Array = MATCH_SCORES[won]
	var line: Array = [["Przegraliśmy, ale zdjęcie na story wyszło świetnie.", "We lost, but the story photo came out great."],
			["Przegraliśmy po walce. %s z gipsem mówi, że to przez kort." % order["hurt"], "We lost after a fight. %s in plaster says it was the court." % order["hurt"]],
			["Wygrane w tie-breaku! %s stuka gipsem w ławkę." % order["hurt"], "Won in the tie-break! %s bangs the cast on the bench." % order["hurt"]],
			["Wygrane! Bluza klubowa twoja. Od poniedziałku grasz z nami na stałe.", "We won! The club hoodie is yours. From Monday you're our regular fourth."]][won]
	_t = 0.0
	hud.show_card("PADEL · %s · +%d zł" % [score[0], zl],
			"%s\n„%s” · %s\n+%d zł (napiwek %d zł, punkty %d zł), +%d szacunku" % [order["said"], line[0], order["customer"], zl, int(r["tip"]), int(m["zl"]), respect],
			PackedStringArray(["OK"]), CZ_COLOUR, false, "Padel · %s · +%d zł" % [score[1], zl],
			"%s\n\"%s\"\n+%d zł (tip %d zł, points %d zł), +%d respect" % [order["said_en"], line[1], zl, int(r["tip"]), int(m["zl"]), respect])
	print("trend job: DESKA match %d/%d (%s), %s: +%d zł (base %d, tip %d, points %d), +%d respect" % [won, DESKI_POINTS, score[1],
			"landed by helicopter" if flew else "by car", zl, int(r["base"]), int(r["tip"]), int(m["zl"]), respect])


func _arrive_drop() -> void:
	var on_time := _clock <= DROP_LIMIT
	var r := drop_pay(float(order["road"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["Jeszcze zimne i jeszcze pistacjowe. Zdjęcie zrobione, dziękuję!", "Still cold and still pistachio. Photo taken, thank you!"]
	if not on_time:
		line = ["Roztopiło się. Wrzucę jako „vibe”.", "It melted. I'll post it as a \"vibe\"."]
	var head := "LIMITKA · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card(head, body, PackedStringArray(["OK"]), DROP_COLOUR, "Limited drop · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered the PISTACJA drop to %s in %.0f s (%s): +%d zł (base %d, tip %d), +%d respect" % [order["name"], _clock,
			"on time" if on_time else "late", int(r["zl"]), int(r["base"]), int(r["tip"]), int(r["respect"])])


func _fail(words: Array) -> void:
	hud.toast(str(words[0]), str(words[1]))
	if log_on:
		print("trend job: %s" % words[1])
	_release()


func _release() -> void:
	_kawa_car_back()
	state = State.IDLE
	_t = 0.0
	_beacon.visible = false
	hud.hide_card()
	hud.hide_status()
	missions.paused = false
	missions.close()
	order = {}


# --- "Kawowy rajd": the coffee run on a ROWERILO bike (coffee_run.gd) ---------------------------

func _is_kawa() -> bool:
	return str(order.get("kind", "")) == "kawa"


## Zuzia calls: the coffee run's card (stage "dock": first to the ROWERILO dock by car).
func offer_kawa_call(force := false) -> bool:
	if not force and not _free():
		return false
	for i in CoffeeRun.STOPS.size():
		if CoffeeRun.stop_at(i, _places) == Vector2.INF:
			if log_on:
				print("trend job: coffee run: stop %d has no position" % i)
			return false
	var dock := _ring_at(CoffeeRun.DOCK)
	order = {"kind": "kawa", "call": true, "slot": -1, "word": "KAWA", "day": 0, "stage": "dock", "i": 0,
			"ring": dock, "door_ring": dock, "name": "ROWERILO", "customer": CoffeeRun.CALLER, "paid": 0, "road": 0.0,
			"prev": "hatch"}
	state = State.OFFER
	_t = 0.0
	var txt := CoffeeRun.call_text()
	hud.show_side_card(str(txt[0]), str(txt[1]), PackedStringArray(["JADĘ", "NIE TERAZ"]), CoffeeRun.COLOUR,
			"%s is calling" % CoffeeRun.CALLER, str(txt[2]))
	hud.ticker_out()
	if log_on:
		print("trend job: coffee run call from %s, dock %.0f m away" % [CoffeeRun.CALLER,
				Vector2(player_pos.x, player_pos.z).distance_to(CoffeeRun.DOCK)])
	return true


## The quest map's hooks (main.gd `_build_stories`, story_quests.gd). Zuzia phones from the list:
## never over another job.
func kawa_ring() -> bool:
	return state == State.IDLE and offer_kawa_call(true)


## Zuzia met in person at the ROWERILO dock (she walks up, the player said WCHODZĘ): no call card,
## straight to the run (the car is already at the dock, so the bike comes next). False unless idle.
func kawa_meet() -> bool:
	if state != State.IDLE or not offer_kawa_call(true):
		return false
	_accept_kawa()
	return true


## True while the coffee run runs (quest focus).
func kawa_busy() -> bool:
	return _is_kawa() and busy()


## Idle: no job, no call, and not just after a run (the coffee run may start now).
func kawa_idle() -> bool:
	return state == State.IDLE and _session >= _kawa_rest


# --- Padel at DESKA on the quest map (story_quests.gd, docs/design/quest-map.md) ---------------

## The questline's start spot: the club's gate on Zaruskiego.
const PADEL_NAME := ["Czwarty do padla", "Fourth for padel"]
const PADEL_HELLO := ["„Jesteś! Jedno z nas ma nogę w gipsie po pole dance, a kort opłacony do pełnej. Bierz rakietę, gramy do trzech punktów?”",
		"\"You're here! One of us has a leg in plaster after pole dance and the court is paid till the hour. Grab a racket, three points?\""]
## The questline's colour on the maps: the padel ball's yellow-green (the call's teal is too near
## the boat race's blue there).
const PADEL_COLOUR := Color("#c6e83a")
const PADEL_CLOSED := ["„Korty już zamknięte. Pani Basia z recepcji poszła do domu. Wpadnij od ósmej”",
		"\"The courts are closed. Pani Basia from reception has gone home. Come by from eight\""]


## The quest map's call (the list's start): the DESKA call rings now. False unless idle.
func padel_ring() -> bool:
	return state == State.IDLE and offer_deski_call(true)


## Met in person at the gate (the friend walks up, the player said yes): no call, no drive,
## straight to the match. False unless idle.
func padel_meet() -> bool:
	if state != State.IDLE or not offer_deski_call(true):
		return false
	hud.hide_card()
	missions.close()
	missions.paused = true
	_clock = 0.0
	order["stage"] = "offer"
	order["flew"] = flying
	if log_on:
		print("trend job: DESKA met in person at the gate")
	_start_match()
	return true


## True while the DESKA call runs (quest focus): the drive or the match.
func padel_busy() -> bool:
	return busy() and _is_cz() and bool(order.get("call", false))


## Idle: no job and no call (the padel questline may start now).
func padel_idle() -> bool:
	return state == State.IDLE


func _ring_at(at: Vector2) -> Vector3:
	return Vector3(at.x, map.terrain_height(at.x, at.y), at.y)


func _accept_kawa() -> void:
	state = State.DELIVER
	_clock = 0.0
	_t = 0.0
	_hold = 0.0
	hud.hide_card()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()
	_beacon.recolour(CoffeeRun.COLOUR)
	_beacon.waving = true
	_beacon.place(order["door_ring"], ARRIVE - 0.5)
	hud.toast("Kawowy rajd: jedź do stacji ROWERILO przy Elektrowni", "Coffee run: drive to the ROWERILO dock by Elektrownia")
	if log_on:
		print("trend job: coffee run accepted")


## The run: the dock (by car, no clock), the four cafés (on the bike, the clock on), the dock again.
func _kawa_tick(dt: float) -> void:
	var stage := str(order.get("stage", ""))
	var biking := stage == "stop" or stage == "return"
	if biking and flying:
		_fail(["Rower nie lata. Rajd przerwany.", "Bikes don't fly. The run is off."])
		return
	if stage == "stop":
		_clock += dt
		_line_t += dt
	var d := _flat(car.global_position, order["door_ring"])
	var still: bool = d < ARRIVE and car.vel.length() < ARRIVE_SPEED and not flying
	if still:
		_hold += dt
	else:
		_hold = 0.0
	var need := CoffeeRun.STAMP_HOLD if stage == "stop" else 0.5
	if still and _hold >= need:
		_hold = 0.0
		match stage:
			"dock":
				_kawa_take_bike()
			"stop":
				_kawa_stamp()
			"return":
				_kawa_finish()
		return
	_kawa_status(d)


func _kawa_status(d: float) -> void:
	var stage := str(order.get("stage", ""))
	if stage == "dock":
		var hint := ["Jedź do brązowego światła: stacja ROWERILO", "Head for the brown beacon: the ROWERILO dock"] if d > 40.0 \
				else ["Stań przy stacji, weź rower", "Stop by the dock, take a bike"]
		hud.show_status("KAWOWY RAJD → ROWERILO", "", "%d m" % roundi(d), hint[0], 0.0, CoffeeRun.COLOUR, "", {}, hint[1])
		return
	if stage == "return":
		hud.show_status("KAWOWY RAJD → ROWERILO", "", "%d m" % roundi(d), "Odstaw rower, auto czeka", 0.0, CoffeeRun.COLOUR, "", {},
				"Return the bike, the car's waiting")
		return
	var i := int(order["i"])
	var left := CoffeeRun.COFFEE_LIMIT - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var line: Array = CoffeeRun.RIDE_LINES[int(_line_t / CoffeeRun.LINE_EVERY) % CoffeeRun.RIDE_LINES.size()]
	if d <= 40.0:
		line = ["Stań przy drzwiach po pieczątkę", "Stop at the door for the stamp"]
	elif left <= 0.0:
		line = ["Zuzia: „Moja kawa stygnie!”", "Zuzia: \"My coffee's going cold!\""]
	hud.show_status("KAWA %s → %s" % [CoffeeRun.stamps(i), CoffeeRun.STOPS[i]["name"]], clock, "%d m" % roundi(d), str(line[0]),
			clampf(_clock / CoffeeRun.COFFEE_LIMIT, 0.0, 1.0), CoffeeRun.COLOUR if left > 0.0 else FAIL_COLOUR, "", {}, str(line[1]))


## At the dock: the car stays (a still copy), the player rides on (car.gd model "bike").
func _kawa_take_bike() -> void:
	order["prev"] = car.model
	if _parked != null:
		_parked.queue_free()
	_parked = car.parked_copy()
	_world.add_child(_parked)
	_parked.global_transform = car.global_transform
	car.set_model("bike")
	car.reset_motion()
	_kawa_next(0)
	_clock = 0.0
	_line_t = 0.0
	hud.toast("Rower z ROWERILO! Zuzia czeka w KROPCE.", "A ROWERILO bike! Zuzia's waiting at KROPKA.")
	if log_on:
		print("trend job: coffee run: on the bike at the dock")


func _kawa_next(i: int) -> void:
	order["stage"] = "stop"
	order["i"] = i
	order["name"] = CoffeeRun.STOPS[i]["name"]
	order["door_ring"] = _ring_at(CoffeeRun.stop_at(i, _places))
	_beacon.waving = true
	_beacon.place(order["door_ring"], ARRIVE - 0.5)


## A stamp: pay the coffee (or Zuzia does), then the next café or, after the fourth, back to the dock.
func _kawa_stamp() -> void:
	var i := int(order["i"])
	var st: Dictionary = CoffeeRun.STOPS[i]
	var price := int(st["price"])
	var own: bool = wallet.spend(price)
	if own:
		order["paid"] = int(order["paid"]) + price
	var drink: Array = st["drink"]
	var line: Array = st["line"]
	hud.toast("Pieczątka %s! %s, %s: %s. %s" % [CoffeeRun.stamps(i + 1), st["name"], drink[0],
			("-%d zł" % price) if own else "na koszt Zuzi", line[0]],
			"Stamp %s! %s, %s: %s. %s" % [CoffeeRun.stamps(i + 1), st["name"], drink[1],
			("-%d zł" % price) if own else "Zuzia's treat", line[1]])
	if log_on:
		print("trend job: coffee run: stamp %d at %s after %.0f s (%s)" % [i + 1, st["name"], _clock, "paid %d zł" % price if own else "Zuzia paid"])
	if i + 1 < CoffeeRun.STOPS.size():
		_kawa_next(i + 1)
		return
	order["on_time"] = _clock <= CoffeeRun.COFFEE_LIMIT
	order["time"] = _clock
	order["stage"] = "return"
	order["name"] = "ROWERILO"
	order["door_ring"] = _ring_at(CoffeeRun.DOCK)
	_beacon.place(order["door_ring"], ARRIVE - 0.5)


## Back at the dock: the car again, Zuzia's BLIK and the card.
func _kawa_finish() -> void:
	_kawa_car_back()
	var on_time := bool(order.get("on_time", false))
	var r := CoffeeRun.pay(int(order["paid"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	var line := ["Pełny paszport! Dziesiąta kawa gratis… w dni robocze 6:00-6:05.", "Full passport! Tenth coffee free… weekdays 6:00-6:05."]
	if not on_time:
		line = ["Twoja kawa wystygła, to ją wypiłam. Oddaję połowę.", "Your coffee went cold, so I drank it. Here's half back."]
	var head := "KAWOWY RAJD · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\nPASZPORT KAWOWY %s w %d:%02d\n+%d zł BLIKiem (zwrot %d zł), +%d szacunku" % [line[0], CoffeeRun.CALLER,
			CoffeeRun.stamps(CoffeeRun.STOPS.size()), int(order["time"]) / 60, int(order["time"]) % 60, int(r["zl"]), int(r["back"]), int(r["respect"])]
	var body_en := "\"%s\"\nCOFFEE PASSPORT in %d:%02d\n+%d zł by BLIK (%d zł back), +%d respect" % [line[1], int(order["time"]) / 60,
			int(order["time"]) % 60, int(r["zl"]), int(r["back"]), int(r["respect"])]
	hud.show_side_card(head, body, PackedStringArray(["OK"]), CoffeeRun.COLOUR, "Coffee run · +%d zł" % int(r["zl"]), body_en)
	print("trend job: coffee run done in %.0f s (%s): paid %d zł for coffee, +%d zł back, +%d respect" % [float(order["time"]),
			"on time" if on_time else "late", int(order["paid"]), int(r["zl"]), int(r["respect"])])


## Off the bike and into the car (the run ended, failed or was cancelled); the still copy goes.
func _kawa_car_back() -> void:
	if _is_kawa():
		_kawa_rest = _session + CoffeeRun.REST
	if car != null and car.model == "bike":
		car.set_model(str(order.get("prev", "hatch")))
	if _parked != null:
		_parked.queue_free()
		_parked = null


## --autopilot: the car slides straight to the pickup, then the door (as the missions' autopilot).
func drive_player() -> bool:
	if not autopilot or not has_target():
		return false
	var to3: Vector3 = target_position() - car.global_position
	var to := Vector3(to3.x, 0.0, to3.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	var dt := get_process_delta_time()
	if d > 1.0:
		var step := minf(d - 0.5, 22.0 * dt)
		car.global_position += to / d * step
		car.global_position.y = map.ground_height(car.global_position.x, car.global_position.z) + 0.05
		car.rotation.y = atan2(-to.x, -to.z)
	return true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
