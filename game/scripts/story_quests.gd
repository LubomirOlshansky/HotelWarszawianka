extends Node
## Wątki: the big interactive questlines and where they start (F's ask 2026-11-07,
## docs/design/quest-map.md). The game has three tiers of things to do, and the map shows them
## three ways (the research behind it: Witcher 3, GTA V, RDR2, Cyberpunk 2077, Ghost of Tsushima):
##   1. the main line (main_line.gd): the gold star in a glowing halo, always on;
##   2. the questlines here (the boat race, the secret rave, later the coffee run, the night meet,
##      padel, the cinema tour...): a round badge with a white "!" in the questline's own colour, on
##      the minimap and the full map, with a lit column and the friend waving at the start spot;
##   3. the light street jobs (kebab, słoiki, Leżak...): their small icons, one per stand.
## While anything runs (a race, a job, a ride, a rescue, a questline) the map goes quiet: the
## street jobs, the garage, the "?" places and the other questlines' badges hide, and only what
## the player is doing (and, dimmed, the main star) stays (main.gd `_story_tick` -> hud.quest_focus).
##
## A questline starts three ways:
##   - its friend phones, as before (each quest's own timer; unchanged);
##   - the player drives to the start spot and slows down: the friend walks up and talks in person
##     (a card with the friend's name and no phone: "Siema! Ścigamy się?"), WCHODZĘ / NIE TERAZ;
##     outside the quest's hours the friend says when to come back instead;
##   - the beta list: the full map's WĄTKI tab lists every questline; a tap starts it now
##     (the friend phones at once, any hour).
##
## A questline joins with `add` (additive: a new quest thread adds one call in main.gd, nothing
## else here changes). Its def:
##   id: String, pl / en: its name, who: [pl, en] the friend, hello: [pl, en] the friend's words in
##   person, closed: [pl, en] the words outside its hours, at: Vector2 the start spot (map x, z;
##   INF: no fixed start, menu and calls only), colour: Color, hours: Vector2 (from, to; may wrap
##   past midnight; Vector2(-1, -1): any time), days: Array of weekdays (1 Monday .. 7 Sunday;
##   [] any day; a night past midnight counts as the day before, as rave.gd's night_day),
##   call: Callable() -> bool (phone now), meet: Callable() -> bool (start in person, here),
##   busy: Callable() -> bool (under way), idle: Callable() -> bool (can start now: not ringing,
##   not cooling down after a card).
##
## Cost: a 0.25 s timer; one shared start beacon (ring, column, waving friend: about 10 draw calls)
## shown only within BEACON_R of the nearest start, never during a quest.

const Beacon := preload("res://scripts/beacon.gd")
const Lines := preload("res://scripts/quest_lines.gd")

## Within this many metres of a start (and slower than GREET_KMH) the friend walks up.
const GREET_R := 30.0
const GREET_KMH := 22.0
## The friend greets again only after the car has been this far away.
const REARM_R := 80.0
## The start beacon stands within this many metres of the nearest start.
const BEACON_R := 320.0
## The minimap pins a questline's badge to its rim up to this far (the garage's reach).
const MINI_REACH := 1500.0
## The in-person card's life (s), then it goes as if NIE TERAZ.
const CARD_LIFE := 15.0
const TICK := 0.25
## The default accent (the full map's WĄTKI tab, quest_lines.gd).
const COLOUR := Lines.STORY_COLOUR

var hud: CanvasLayer
## () -> [position: Vector3, km/h, flying: bool]
var vehicle: Callable
## () -> bool: nothing else on and no card up (main.gd `_boat_free`).
var free_now: Callable = func() -> bool: return true
## () -> [hour: float, weekday: int]
var clock: Callable = func() -> Array: return [12.0, 3]
## (x, z) -> float: the ground's height (map.gd ground_height).
var ground: Callable
var log_on := false
## --story-meet: WCHODZĘ is pressed a second after the friend walks up (test runs, autopilot).
var auto_yes := false

var defs: Array[Dictionary] = []
## The def whose friend is talking now (in person), -1 none; the card's age.
var greeting := -1
var _greet_t := 0.0
## Per def id: true once greeted, until the car is REARM_R away.
var _greeted := {}
var _tick := 0.0
var _beacon: Node3D
var _beacon_at := -1
## Set by main.gd: a quest is under way (focus: the starts hide).
var focus := false


func setup(world: Node3D) -> void:
	_beacon = Beacon.new()
	_beacon.name = "StoryStart"
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#26232c"))
	_beacon.visible = false
	if hud != null:
		hud.card_pressed.connect(_on_card)


## Joins a questline (see the header for the def's keys). Returns its index.
func add(def: Dictionary) -> int:
	var d := {"at": Vector2.INF, "hours": Vector2(-1, -1), "days": [], "closed": ["", ""],
			"hello": ["", ""], "who": ["", ""], "colour": COLOUR}
	d.merge(def, true)
	defs.append(d)
	return defs.size() - 1


func find(id: String) -> int:
	for i in defs.size():
		if str(defs[i]["id"]) == id:
			return i
	return -1


# --- the rules (static: check_story_quests.gd runs them) ---------------------------------------

## Within hours (from, to) that may wrap past midnight; Vector2(-1, -1) is any time.
static func hours_ok(hours: Vector2, hour: float) -> bool:
	if hours.x < 0.0:
		return true
	if hours.x < hours.y:
		return hour >= hours.x and hour < hours.y
	return hour >= hours.x or hour < hours.y


## Open at this hour and weekday (1 Monday .. 7 Sunday): the hours, and the day the night belongs
## to (before noon a wrapped window counts as the day before).
static func open_at(def: Dictionary, hour: float, weekday: int) -> bool:
	var h: Vector2 = def.get("hours", Vector2(-1, -1))
	if not hours_ok(h, hour):
		return false
	var days: Array = def.get("days", [])
	if days.is_empty():
		return true
	var day := weekday
	if h.x > h.y and hour < 12.0:
		day = (weekday + 5) % 7 + 1
	return day in days


## "7:00-22:00" / "czw.-sob. 22:00-6:00": when a questline is open, for its row and closed card.
static func when_text(def: Dictionary, polish: bool) -> String:
	var h: Vector2 = def.get("hours", Vector2(-1, -1))
	if h.x < 0.0:
		return ""
	var t := "%d:00-%d:00" % [int(h.x), int(h.y)]
	var days: Array = def.get("days", [])
	if days.is_empty():
		return t
	var pl := ["pon.", "wt.", "śr.", "czw.", "pt.", "sob.", "niedz."]
	var en := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	var names: Array = pl if polish else en
	return "%s-%s %s" % [names[int(days[0]) - 1], names[int(days[-1]) - 1], t]


## The index of the start nearest `at` within `reach` metres (-1 none), skipping `skip` ids.
static func nearest(list: Array, at: Vector2, reach: float, skip := {}) -> int:
	var best := -1
	var best_d := reach
	for i in list.size():
		var p: Vector2 = list[i].get("at", Vector2.INF)
		if p == Vector2.INF or skip.has(str(list[i]["id"])):
			continue
		var d := at.distance_to(p)
		if d <= best_d:
			best = i
			best_d = d
	return best


## The friend walks up: close enough, slow enough, on the ground.
static func greet_ready(at: Vector2, start: Vector2, kmh: float, flying: bool) -> bool:
	return not flying and start != Vector2.INF and at.distance_to(start) <= GREET_R and kmh <= GREET_KMH


## The map's badges now: [points, colours] of the starts; none in focus (a quest under way).
static func marks(list: Array, in_focus: bool) -> Array:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	if not in_focus:
		for d: Dictionary in list:
			var p: Vector2 = d.get("at", Vector2.INF)
			if p != Vector2.INF:
				pts.append(p)
				cols.append(d.get("colour", COLOUR))
	return [pts, cols]


## The WĄTKI tab's entries (quest_lines.gd): one per questline, action "story", its name (the row
## adds the distance; "open": false dims a questline closed at this hour).
static func entries(list: Array, hour: float, weekday: int) -> Array:
	var out: Array = []
	for d: Dictionary in list:
		var e := Lines.entry("story_" + str(d["id"]), "story", Lines.Line.STORY, "▶ " + str(d["pl"]), "▶ " + str(d["en"]),
				d.get("at", Vector2.INF), d.get("colour", COLOUR), "story")
		e["story"] = str(d["id"])
		e["open"] = open_at(d, hour, weekday)
		out.append(e)
	return out


# --- the game -----------------------------------------------------------------------------------

func _now() -> Array:
	return clock.call() if clock.is_valid() else [12.0, 3]


func _process(dt: float) -> void:
	_tick += dt
	if greeting >= 0:
		_greet_t += dt
		if _greet_t > CARD_LIFE:
			_log("%s: the friend walked off" % defs[greeting]["id"])
			hud.hide_card()
			greeting = -1
	if _tick < TICK:
		return
	_tick = 0.0
	step()


## The slow part: the beacon at the nearest start, the friend walking up.
func step() -> void:
	if not vehicle.is_valid() or defs.is_empty():
		return
	var v: Array = vehicle.call()
	var p: Vector3 = v[0]
	var at := Vector2(p.x, p.z)
	var flying := bool(v[2])
	for id: String in _greeted.keys():
		var k := find(id)
		if k < 0 or at.distance_to(defs[k]["at"]) > REARM_R:
			_greeted.erase(id)
	var any_busy := focus
	for d: Dictionary in defs:
		var b: Callable = d.get("busy", Callable())
		if b.is_valid() and bool(b.call()):
			any_busy = true
	var near := -1 if any_busy or flying else nearest(defs, at, BEACON_R)
	if near != _beacon_at:
		_beacon_at = near
		if near >= 0:
			var s: Vector2 = defs[near]["at"]
			var y: float = ground.call(s.x, s.y) if ground.is_valid() else p.y
			_beacon.recolour(defs[near]["colour"])
			_beacon.place(Vector3(s.x, y, s.y), GREET_R * 0.5)
		else:
			_beacon.visible = false
	if greeting >= 0 or near < 0 or _greeted.has(str(defs[near]["id"])):
		return
	if not greet_ready(at, defs[near]["at"], float(v[1]), flying) or not bool(free_now.call()):
		return
	var idle: Callable = defs[near].get("idle", Callable())
	if idle.is_valid() and not bool(idle.call()):
		return
	_greet(near)


## The friend walks up and talks (no phone): the questline's offer, or when to come back.
func _greet(i: int) -> void:
	var d := defs[i]
	_greeted[str(d["id"])] = true
	greeting = i
	_greet_t = 0.0
	var c := _now()
	var who: Array = d["who"]
	var title_pl := "👋 %s" % str(who[0]).to_upper()
	var title_en := "%s, in person" % who[1]
	if open_at(d, float(c[0]), int(c[1])):
		var hello: Array = d["hello"]
		hud.show_side_card(title_pl, str(hello[0]), PackedStringArray(["WCHODZĘ!|I'M IN!", "NIE TERAZ|NOT NOW"]),
				d["colour"], title_en, str(hello[1]))
		_log("%s: %s walks up (open)" % [d["id"], who[1]])
		if auto_yes:
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if greeting == i:
					hud.card_pressed.emit(0))
	else:
		var closed: Array = d["closed"]
		var pl := "%s (%s)" % [closed[0], when_text(d, true)]
		var en := "%s (%s)" % [closed[1], when_text(d, false)]
		hud.show_side_card(title_pl, pl, PackedStringArray(["OK|OK"]), d["colour"], title_en, en)
		_log("%s: %s walks up (closed now)" % [d["id"], who[1]])


func _on_card(index: int) -> void:
	if greeting < 0:
		return
	var d := defs[greeting]
	var c := _now()
	var open := open_at(d, float(c[0]), int(c[1]))
	greeting = -1
	hud.hide_card()
	if open and index == 0:
		var meet: Callable = d.get("meet", Callable())
		var ok := meet.is_valid() and bool(meet.call())
		_log("%s: started in person (%s)" % [d["id"], "ok" if ok else "refused"])
	else:
		_log("%s: not now" % d["id"])


## The beta list's start: the friend phones now (any hour). False when it can't (busy, no call).
func start(id: String) -> bool:
	var i := find(id)
	if i < 0:
		return false
	var call: Callable = defs[i].get("call", Callable())
	var ok := call.is_valid() and bool(call.call())
	_log("%s: started from the list (%s)" % [id, "ok" if ok else "refused"])
	return ok


## True while the friend talks in person (the card is ours).
func talking() -> bool:
	return greeting >= 0


func _log(s: String) -> void:
	if log_on:
		print("stories: " + s)
