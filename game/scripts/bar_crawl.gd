extends Node3D
## Bar crawl (F's ask 2026-11-04, docs/design/bar-crawl.md): drive a company through three bars
## before they close.
##
## **The call.** At night (20:00-04:00 on the game clock), with nothing else on, a group rings
## (GROUPS in data/bar_crawl.json: a hen party, a stag night, students after exams, a team after
## launch day): ODBIERZ / ODRZUĆ, then the route and its clock, JEDZIEMY! / NIE DZIŚ. The group
## waits at a kerb 250-600 m away (the dashed amber ring).
##
## **The crawl.** Once they are in, the clock runs: the sum of each leg's allowance (`leg_time`) and
## the stays. Three bars in a row (ROUTES: the existing parody fascias on Nowogrodzka, Mazowiecka,
## Wilcza, under the Powiśle viaduct, on the boulevard, the Party House and Praga), each a stop
## ring at the kerb nearest its door. At the first two the group goes in for a round (STAY s) and
## you wait at the kerb: the stay counts down only within WAIT_R of the ring (drive off and the mood
## drops while they stand on the pavement). The third bar is the night's end: they stay there.
## The mood (0-100, starts at MOOD_START): a knock (the car's `bumped`) or a hard stop lowers it,
## smooth driving lifts it. Out of time: "ostatnie zamówienia", the crawl ends where it is and they
## pay for the bars they got to. ✕ gives up (they walk).
##
## **Pay** (`pay_for`): per bar reached, plus a tip by mood and an on-time bonus when all three
## were made. The calls (missions.gd) are paused while it runs; no ride card meanwhile (main.gd).
##
## Cost: a 0.25 s timer, two beacons; no per-frame work, no new meshes but the beacons.
##
## Flags (main.gd): --crawl-call (the group rings a second in, any hour), --crawl-route=ID,
## --crawl-group=ID, --crawl=0 (none of it), --crawl-log.

const Beacon := preload("res://scripts/beacon.gd")
const Access := preload("res://scripts/access.gd")
const Notebook := preload("res://scripts/notebook.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Rave := preload("res://scripts/rave.gd")
const Storefronts := preload("res://scripts/storefronts.gd")

const DATA_PATH := "res://data/bar_crawl.json"
const COLOUR := Color("#ff8a3d")        ## the crawl's colour: last-orders orange
const PICK_COLOUR := Color("#ffc23a")   ## the group waiting (the rides' amber)
const BUBBLE := Color("#ffb070")

## The routes: id, the name on the card [pl, en], three stops. A stop is a storefront sign id
## (its [lat, lon] from Storefronts' tables, or the viaduct's game coordinates) or `ll` for a
## place without a sign table; `name` is what the HUD shows.
const ROUTES := [
	{"id": "klasyczna", "name": ["Klasyczna", "The Classic"], "stops": [
		{"sign": "nowo_kwarta", "name": "KWARTA"},
		{"sign": "maz_tygrys", "name": "TYGRYS JAZZ"},
		{"sign": "wil_muza", "name": "MUZA NA BIS"}]},
	{"id": "nad_woda", "name": ["Nad wodą", "By the River"], "stops": [
		{"sign": "maz_szkic", "name": "SZKIC NOCĄ"},
		{"sign": "via_qbar", "name": "Q-BAR POD WIADUKTEM"},
		{"ll": [52.2412, 21.0318], "name": "CUDAK NA BULWARZE"}]},
	{"id": "odwazni", "name": ["Dla odważnych", "For the Brave"], "stops": [
		{"sign": "wil_goraczka", "name": "GORĄCZKA PIĄTKOWA"},
		{"sign": "bar_newtwice", "name": "NEWTWICE"},
		{"sign": "maz_enklawka", "name": "ENKLAWKA"}]},
	{"id": "praga", "name": ["Na drugą stronę", "Over the River"], "stops": [
		{"sign": "nowo_schron", "name": "SCHRON PIWNY"},
		{"sign": "praga_swiat", "name": "ŚWIAT PO PRASKU"},
		{"sign": "praga_kufel", "name": "POD KUFLEM ZA ROGIEM"}]},
]

## The call's window (wraps past midnight) and the free-play seconds before the first and the
## next call.
const HOURS := Vector2(20.0, 4.0)
const FIRST_CALL := Vector2(240.0, 420.0)
const NEXT_CALL := Vector2(1200.0, 1800.0)
const RING_LIFE := 25.0
## The pickup: a kerb this far from the player.
const PICK_FROM := 250.0
const PICK_TO := 600.0
## Stopping: within R m of the ring, under STOP_KMH, for HOLD s.
const PICK_R := 7.0
const BAR_R := 9.0
const STOP_KMH := 9.0
const HOLD := 0.8
## The stay inside a bar (s), counted while the car is within WAIT_R m of the ring.
const STAY := 15.0
const WAIT_R := 30.0
## The clock per leg: the straight distance x DETOUR at LEG_SPEED m/s, plus LEG_SLACK s.
const DETOUR := 1.6
const LEG_SPEED := 10.0
const LEG_SLACK := 20.0
## Mood: the start, a knock (over BUMP_SPEED m/s; once per BUMP_GAP s), a hard stop (a drop of
## BRAKE_KMH km/h in one 0.25 s tick from over 20 km/h), smooth driving (+CALM per CALM_EVERY s over
## 15 km/h), waiting away from the bar (per s).
const MOOD_START := 70.0
const BUMP_SPEED := 2.0
const BUMP_GAP := 1.0
const BUMP_MOOD := 7.0
const BRAKE_KMH := 9.0
const BRAKE_MOOD := 3.0
const CALM := 1.0
const CALM_EVERY := 8.0
const AWAY_MOOD := 1.5
const LATE_AT := 45.0
## The group talks every TALK_GAP s in the car (the leg's line first).
const TALK_GAP := Vector2(12.0, 18.0)
## Pay: per bar, the tip at full mood, the on-time bonus; respect per bar and for a happy finish.
const PER_BAR := 35
const TIP := 60
const ON_TIME := 40
const RESPECT_BAR := 10
const RESPECT_HAPPY := 20
const RESULT_LIFE := 14.0
const TICK := 0.25

enum State { IDLE, RING, OFFER, PICKUP, DRIVE, WAIT, RESULT }

var hud: CanvasLayer
var bubbles: Control
var wallet: Node
var missions: Node
var map: Node3D
var graph: LaneGraph
## [position, km/h, flying] of the player's vehicle.
var vehicle: Callable
## {hour, weekday} (time_of_day.gd local_clock).
var clock: Callable
## True when nothing else is on (main.gd).
var free_now: Callable
var origin := [52.234, 21.024]
var log_on := false
## The call's timer runs (off in test runs but for the flags).
var auto := true
## --autopilot: the car slides to the targets (main.gd `_autopilot`).
var autopilot := false
## --crawl-route / --crawl-group: the next crawl's.
var force_route := ""
var force_group := ""

var state := State.IDLE
var call_in := 0.0
## The routes found on this map: ROUTES' entries with stops: [{name, at: kerb}] (all three found).
var routes: Array[Dictionary] = []
var groups: Array = []
## The crawl now: the route and group (indices), the pickup kerb, the bar reached next (0..2).
var route := -1
var group := -1
var pickup := {}
var bar := 0
var mood := MOOD_START
var time_left := 0.0
var stay_left := 0.0
var crawls := 0
var last_pay := {}
var spent_usec := 0

var _rng := RandomNumberGenerator.new()
var _tick := 0.0
var _ring_t := 0.0
var _hold_t := 0.0
var _talk_t := 0.0
var _said_leg := -1
var _said_late := false
var _bump_t := 0.0
var _calm_t := 0.0
var _last_kmh := 0.0
var _result_t := 0.0
var _calls_were := false
var _pick: Node3D
var _mark: Node3D


func setup(world: Node3D, seed_value := -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	call_in = _rng.randf_range(FIRST_CALL.x, FIRST_CALL.y)
	groups = load_groups()
	if graph != null:
		routes = find_routes(graph, map, origin)
	_pick = Beacon.new()
	world.add_child(_pick)
	_pick.setup(PICK_COLOUR, Color("#2a2320"))
	_pick.pattern = Beacon.Pattern.DASHED
	_pick.visible = false
	_mark = Beacon.new()
	world.add_child(_mark)
	_mark.setup(COLOUR, Color("#2a2320"))
	_mark.waving = false
	_mark.visible = false
	if hud != null:
		hud.card_pressed.connect(_on_card)
		hud.abort_pressed.connect(func() -> void:
			if busy():
				_give_up())
	var names := PackedStringArray()
	for r in routes:
		names.append(String(r["id"]))
	_log("%d routes (%s), %d groups; first call in %.0f s" % [routes.size(), ", ".join(names), groups.size(), call_in])


# --- the rules (static: check_bar_crawl.gd runs them) -----------------------------------------

## The groups' table (data/bar_crawl.json), [] when missing.
static func load_groups() -> Array:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return []
	var d: Variant = JSON.parse_string(f.get_as_text())
	return (d as Dictionary).get("groups", []) if d is Dictionary else []


## The call may come at this hour.
static func call_hours(hour: float) -> bool:
	return Rave.in_hours(hour, HOURS)


## A stop's point on the map (game x, z): its sign's [lat, lon] (or the viaduct's game point), or
## its own `ll`; Vector2.INF when unknown.
static func stop_point(stop: Dictionary, org: Array) -> Vector2:
	if stop.has("ll"):
		return Notebook.project(org, float(stop["ll"][0]), float(stop["ll"][1]))
	var id: String = stop.get("sign", "")
	if Storefronts.VIADUKT.has(id):
		return Storefronts.VIADUKT[id][0]
	for table: Dictionary in [Storefronts.NOWOGRODZKA, Storefronts.MAZOWIECKA, Storefronts.WILCZA,
			Storefronts.PRAGA, Storefronts.HYPE]:
		if table.has(id):
			var ll: Array = table[id]
			return Notebook.project(org, float(ll[0]), float(ll[1]))
	return Vector2.INF


## The routes on this map: each ROUTES entry with every stop's kerb (the nearest ground road
## within 120 m); a route missing a stop is left out.
static func find_routes(g: LaneGraph, m: Node3D, org: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in ROUTES:
		var stops: Array = []
		for s: Dictionary in r["stops"]:
			var p := stop_point(s, org)
			if p == Vector2.INF:
				break
			var kerb := Rave.kerb_near(g, p, 120.0)
			if kerb.is_empty():
				break
			stops.append({"name": s["name"], "at": kerb})
		if stops.size() == (r["stops"] as Array).size():
			var e := r.duplicate(true)
			e["stops"] = stops
			out.append(e)
	return out


## The clock for one leg of `metres` straight (s).
static func leg_time(metres: float) -> float:
	return metres * DETOUR / LEG_SPEED + LEG_SLACK


## The whole crawl's clock: the legs from the pickup through the bars, and the stays at all but
## the last bar.
static func budget(points: Array) -> float:
	var t := 0.0
	for i in range(1, points.size()):
		t += leg_time((points[i - 1] as Vector2).distance_to(points[i]))
	return t + STAY * maxi(points.size() - 2, 0)


## [zł, respect] for `done` of `total` bars at `mood`, and whether all were made in time.
static func pay_for(done: int, total: int, m: float, on_time: bool) -> Array:
	var all := done >= total
	var zl := PER_BAR * done
	var respect := RESPECT_BAR * done
	if all:
		zl += roundi(TIP * clampf(m, 0.0, 100.0) / 100.0)
		if on_time:
			zl += ON_TIME
		if m >= 70.0:
			respect += RESPECT_HAPPY
	return [zl, respect]


## The mood's word on the status: [pl, en].
static func mood_word(m: float) -> Array:
	if m >= 80.0:
		return ["szampański", "sparkling"]
	if m >= 55.0:
		return ["wesoły", "cheerful"]
	if m >= 30.0:
		return ["tak sobie", "so-so"]
	return ["ponury", "gloomy"]


## m:ss
static func clock_text(s: float) -> String:
	var t := maxi(ceili(s), 0)
	return "%d:%02d" % [t / 60, t % 60]


# --- the quest --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0:
		return
	var t0 := Time.get_ticks_usec()
	_tick += dt
	if _tick >= TICK:
		step(_tick)
		_tick = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func step(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var at: Vector3 = v[0]
	var kmh: float = v[1]
	_bump_t = maxf(_bump_t - dt, 0.0)
	match state:
		State.IDLE:
			if auto and _free() and _hours_now():
				call_in -= dt
				if call_in <= 0.0 and not ring():
					call_in = 20.0
		State.RING, State.OFFER:
			_ring_t += dt
			if autopilot and _ring_t > 2.0:
				_on_card(0)  # --autopilot answers and accepts (the test run)
			elif _ring_t > RING_LIFE:
				hud.hide_card()
				hud.toast("Nieodebrane połączenie: %s" % _group_name()[0], "Missed call: %s" % _group_name()[1])
				_reset()
		State.PICKUP:
			var p: Vector3 = pickup["at"]
			_status_to(at, p, "Zatrzymaj się przy grupie", "Stop by the group", PICK_COLOUR, false)
			if _arrived(dt, at, kmh, p, PICK_R):
				_board()
		State.DRIVE, State.WAIT:
			time_left -= dt
			_drive_mood(dt, kmh)
			if time_left <= 0.0:
				_end(false)
				return
			if time_left < LATE_AT and not _said_late:
				_said_late = true
				_say(_group().get("late", []))
			if state == State.DRIVE:
				_drive(dt, at, kmh)
			else:
				_wait(dt, at)
		State.RESULT:
			_result_t += dt
			if _result_t > RESULT_LIFE:
				hud.hide_card()
				_finish()
	_last_kmh = kmh


func _free() -> bool:
	return free_now.is_valid() and bool(free_now.call()) and not routes.is_empty() and not groups.is_empty()


func _hours_now() -> bool:
	var c: Dictionary = clock.call() if clock.is_valid() else {"hour": 22.0}
	return call_hours(float(c["hour"]))


func busy() -> bool:
	return state in [State.PICKUP, State.DRIVE, State.WAIT]


func has_target() -> bool:
	return state in [State.PICKUP, State.DRIVE, State.WAIT]


func target_position() -> Vector3:
	match state:
		State.PICKUP:
			return pickup["at"]
		State.DRIVE, State.WAIT:
			return _stop()["at"]["at"]
	return Vector3.ZERO


func target_colour() -> Color:
	return PICK_COLOUR if state == State.PICKUP else COLOUR


## The group rings (--crawl-call too). False with no routes or groups, or while busy.
func ring() -> bool:
	if routes.is_empty() or groups.is_empty() or state != State.IDLE:
		return false
	group = _rng.randi() % groups.size()
	route = _rng.randi() % routes.size()
	for i in groups.size():
		if String(groups[i].get("id", "")) == force_group:
			group = i
	for i in routes.size():
		if String(routes[i]["id"]) == force_route:
			route = i
	state = State.RING
	_ring_t = 0.0
	var n := _group_name()
	hud.show_side_card("📞 " + String(n[0]), "Grupa na wieczór po mieście. Mówią wszyscy naraz.",
			PackedStringArray(["ODBIERZ|ANSWER", "ODRZUĆ|DECLINE"]), COLOUR, "📞 " + String(n[1]),
			"A group out on the town tonight. All talking at once.")
	hud.ticker_out()
	Access.buzz(60, 0.6)
	_log("call: %s, route %s" % [_group().get("id", ""), routes[route]["id"]])
	return true


## The offer: the route, its bars and the clock; the pickup kerb.
func _offer() -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var from := Vector2((v[0] as Vector3).x, (v[0] as Vector3).z)
	pickup = Rave.kerb_ring(graph, from, PICK_FROM, PICK_TO, Vector2.ZERO, _rng)
	if pickup.is_empty():
		pickup = Rave.kerb_ring(graph, from, 120.0, PICK_TO * 1.5, Vector2.ZERO, _rng)
	if pickup.is_empty():
		hud.hide_card()
		_reset()
		return
	state = State.OFFER
	_ring_t = 0.0
	var r: Dictionary = routes[route]
	var stops: Array = r["stops"]
	var bars := PackedStringArray()
	for s: Dictionary in stops:
		bars.append(String(s["name"]))
	var c: Array = _group().get("call", ["", ""])
	var body_pl := String(c[0]).replace("{route}", "„%s”" % r["name"][0]).replace("{bars}", str(stops.size()))
	var body_en := String(c[1]).replace("{route}", "\"%s\"" % r["name"][1]).replace("{bars}", str(stops.size()))
	var t := clock_text(budget(_points()))
	body_pl += " %s. Czas: %s." % [" → ".join(bars), t]
	body_en += " %s. Time: %s." % [" → ".join(bars), t]
	var n := _group_name()
	hud.show_side_card(String(n[0]), body_pl, PackedStringArray(["JEDZIEMY!|LET'S GO", "NIE DZIŚ|NOT TONIGHT"]),
			COLOUR, String(n[1]), body_en)
	_log("offer: pickup at %d,%d, clock %s" % [roundi(pickup["at"].x), roundi(pickup["at"].z), t])


func _on_card(i: int) -> void:
	match state:
		State.RING:
			if i == 0:
				_offer()
			else:
				hud.hide_card()
				hud.toast("Odrzucono. Pojadą tramwajem. Głośno.", "Declined. They'll take the tram. Loudly.")
				_reset()
		State.OFFER:
			hud.hide_card()
			if i == 0:
				accept()
			else:
				hud.toast("„Trudno! Zamówimy kogoś z aplikacji. On na pewno nie zna barów.”", "\"Fine! We'll get someone off the app. He won't know the bars.\"")
				_reset()
		State.RESULT:
			hud.hide_card()
			_finish()


## JEDZIEMY!: the group waiting at the kerb (the dashed ring).
func accept() -> void:
	if pickup.is_empty():
		return
	_calls_were = missions.paused if missions != null else false
	if missions != null:
		missions.paused = true
	var side: Vector3 = pickup["side"]
	_pick.place(Vector3(side.x, pickup["at"].y, side.z), PICK_R, true, true)
	_pick.visible = true
	state = State.PICKUP
	_hold_t = 0.0
	hud.toast("Jedź po grupę", "Go and pick up the group")
	_log("accepted")


## In the car: the clock starts.
func _board() -> void:
	_pick.visible = false
	bar = 0
	mood = MOOD_START
	time_left = budget(_points())
	_said_leg = -1
	_said_late = false
	_talk_t = 3.0
	_calm_t = 0.0
	_say(_group().get("board", []))
	_to_bar()
	_log("boarded: clock %s" % clock_text(time_left))


## The ring at the next bar.
func _to_bar() -> void:
	var k: Dictionary = _stop()["at"]
	var side: Vector3 = k["side"]
	_mark.place(Vector3(side.x, k["at"].y, side.z), BAR_R, true, false)
	_mark.visible = true
	state = State.DRIVE
	_hold_t = 0.0


func _drive(dt: float, at: Vector3, kmh: float) -> void:
	_talk(dt)
	var to: Vector3 = _stop()["at"]["at"]
	var bar_name := String(_stop()["name"])
	_status_to(at, to, "Stań pod %s" % bar_name, "Pull up outside %s" % bar_name, COLOUR, true)
	if _arrived(dt, at, kmh, to, BAR_R):
		_log("bar %d (%s) at %s left, mood %.0f" % [bar + 1, _stop()["name"], clock_text(time_left), mood])
		if bar >= (routes[route]["stops"] as Array).size() - 1:
			_end(true)
			return
		state = State.WAIT
		stay_left = STAY
		_say_pick("in")


## Waiting at the kerb: the stay counts down near the bar, the mood drops away from it.
func _wait(dt: float, at: Vector3) -> void:
	var to: Vector3 = _stop()["at"]["at"]
	var d := Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z))
	var near := d <= WAIT_R
	if near:
		stay_left -= dt
	else:
		mood = maxf(mood - AWAY_MOOD * dt, 0.0)
	var hint := ["Czekaj przy krawężniku: są w %s" % _stop()["name"], "Wait at the kerb: they're in %s" % _stop()["name"]] if near \
			else ["Wracaj pod bar! Zaraz wyjdą", "Back to the bar! They're coming out"]
	hud.show_status(_title(), clock_text(time_left), clock_text(stay_left),
			hint[0], 1.0 - stay_left / STAY, COLOUR, "", {}, hint[1])
	if stay_left <= 0.0:
		bar += 1
		_say_pick("out")
		_talk_t = 6.0
		_to_bar()


## Mood from the driving: hard stops and smooth cruising (the knocks come from `bumped`).
func _drive_mood(dt: float, kmh: float) -> void:
	if _last_kmh > 20.0 and _last_kmh - kmh > BRAKE_KMH:
		mood = maxf(mood - BRAKE_MOOD, 0.0)
	if kmh > 15.0:
		_calm_t += dt
		if _calm_t >= CALM_EVERY:
			_calm_t = 0.0
			mood = minf(mood + CALM, 100.0)


## The car hit something (car.gd `bumped`, main.gd wires it).
func on_bump(speed: float) -> void:
	if not busy() or state == State.PICKUP or speed < BUMP_SPEED or _bump_t > 0.0:
		return
	_bump_t = BUMP_GAP
	mood = maxf(mood - BUMP_MOOD, 0.0)
	_say_pick("bump")


## The crawl ends: `made` true at the last bar, false when the clock ran out.
func _end(made: bool) -> void:
	var total := (routes[route]["stops"] as Array).size()
	var done := total if made else bar
	var p := pay_for(done, total, mood, made)
	last_pay = {"zl": p[0], "respect": p[1], "done": done, "total": total, "mood": roundi(mood), "on_time": made}
	if wallet != null and p[0] > 0:
		wallet.pay(p[0], p[1], "crawl")
	_mark.visible = false
	hud.hide_status()
	state = State.RESULT
	_result_t = 0.0
	crawls += 1
	var q: Array = _group().get("end_good" if made else "end_late", ["", ""])
	var mw := mood_word(mood)
	var pl := "%s %d z %d barów, nastrój: %s. Za kurs %d zł, +%d szacunku." % [q[0], done, total, mw[0], p[0], p[1]]
	var en := "%s %d of %d bars, mood: %s. %d zł for the ride, +%d respect." % [q[1], done, total, mw[1], p[0], p[1]]
	var title := ["RAJD PO BARACH", "BAR CRAWL"] if made else ["OSTATNIE ZAMÓWIENIA", "LAST ORDERS"]
	hud.show_card(title[0], pl, PackedStringArray(["OK"]), COLOUR, false, title[1], en)
	_log("end: %s, %d/%d bars, mood %.0f, +%d zł +%d respect" % ["made it" if made else "out of time", done, total, mood, p[0], p[1]])


func _give_up() -> void:
	hud.hide_status()
	hud.toast("Grupa idzie dalej pieszo. Śpiewając.", "The group walks on. Singing.")
	_log("gave up")
	_finish()


## Back to free play: the calls back on, the next call later.
func _finish() -> void:
	_pick.visible = false
	_mark.visible = false
	hud.hide_status()
	if missions != null and state != State.IDLE:
		missions.paused = _calls_were
	_reset()


func _reset() -> void:
	state = State.IDLE
	pickup = {}
	route = -1
	group = -1
	bar = 0
	_hold_t = 0.0
	call_in = _rng.randf_range(NEXT_CALL.x, NEXT_CALL.y)
	_log("next call in %.0f s" % call_in)


## Testing aid (--autopilot): the car slides to the target like the mission autopilot. True
## while it drives.
func drive_player(car: CharacterBody3D, dt: float) -> bool:
	if not autopilot or not has_target():
		return false
	var t := target_position()
	var to := Vector3(t.x - car.global_position.x, 0.0, t.z - car.global_position.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	if d > 0.5:
		car.global_position += to / d * minf(d, 22.0 * dt)
		car.rotation.y = atan2(-to.x, -to.z)
	return true


# --- helpers ----------------------------------------------------------------------------------

func _group() -> Dictionary:
	return groups[group] if group >= 0 and group < groups.size() else {}


func _group_name() -> Array:
	return _group().get("name", ["GRUPA", "THE GROUP"])


func _stop() -> Dictionary:
	return (routes[route]["stops"] as Array)[bar]


## The pickup and the bars as game points (x, z), for the clock.
func _points() -> Array:
	var out: Array = [Vector2(pickup["at"].x, pickup["at"].z)]
	for s: Dictionary in routes[route]["stops"]:
		out.append(Vector2(s["at"]["at"].x, s["at"]["at"].z))
	return out


func _title() -> String:
	var r: Dictionary = routes[route]
	return "%s · %d/%d" % [String(r["name"][0]).to_upper(), bar + 1, (r["stops"] as Array).size()]


func _status_to(at: Vector3, to: Vector3, hint: String, hint_en: String, colour: Color, crawl: bool) -> void:
	var m := roundi(Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)))
	var title := _title() if crawl else String(_group_name()[0])
	var mw := mood_word(mood)
	var h := hint
	var h_en := hint_en
	if crawl:
		h = "%s · nastrój: %s" % [hint, mw[0]]
		h_en = "%s · mood: %s" % [hint_en, mw[1]]
	hud.show_status(title, clock_text(time_left) if crawl else "", "%d m" % m, h, _hold_t / HOLD, colour, "", {}, h_en)


func _arrived(dt: float, at: Vector3, kmh: float, to: Vector3, r: float) -> bool:
	if Vector2(at.x, at.z).distance_to(Vector2(to.x, to.z)) <= r and kmh < STOP_KMH:
		_hold_t += dt
	else:
		_hold_t = 0.0
	if _hold_t >= HOLD:
		_hold_t = 0.0
		return true
	return false


## The leg's own line once per leg, then the odd repeat from the leg lines.
func _talk(dt: float) -> void:
	_talk_t -= dt
	if _talk_t > 0.0:
		return
	_talk_t = _rng.randf_range(TALK_GAP.x, TALK_GAP.y)
	var ride: Array = _group().get("ride", [])
	if ride.is_empty():
		return
	var leg := bar
	if _said_leg != leg and leg < ride.size():
		if _say(ride[leg]):
			_said_leg = leg


func _say_pick(tag: String) -> void:
	var lines: Array = _group().get(tag, [])
	if not lines.is_empty():
		_say(lines[_rng.randi() % lines.size()])


## A line over the car (the group is in it), through the chatter budget.
func _say(l: Array) -> bool:
	if bubbles == null or l.size() < 2:
		return false
	var anchor := func() -> Vector3:
		var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
		return v[0]
	var ok: bool = bubbles.say(anchor, String(_group().get("speaker", "")), String(l[0]), String(l[1]), 4.2, BUBBLE, 2.2)
	if ok:
		_log("says: %s" % l[1])
	return ok


func _log(text: String) -> void:
	if log_on:
		print("crawl: " + text)
