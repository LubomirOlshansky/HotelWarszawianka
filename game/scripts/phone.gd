extends RefCounted
## The phone's owner (F 2026-11-26, "the phone with jobs"; F 2026-11-27, the compact phone): the phone
## button opens phone_hub.gd with phone_rules.gd's `model` of the game's facts. QUESTS opens the big
## QUESTS screen (`full_map.open_screen`); ŁUBER and GŁODNO search inside the phone, then offer:
## ŁUBER the next passenger (`rides.peek`, TAKE = `rides.take_peeked`), GŁODNO the nearest kebab
## place from the side jobs (main.gd `_quest_entries`; TAKE pins it, the map arrow). The game pauses
## under the card (PauseReasons.PHONE). It reads the game through `m` (main.gd) when it is used, so it
## can be built before the systems it asks.
## Add-ons: Beehave and Dialogue Manager not used (a menu, no behaviour and no conversation).

const Rules := preload("res://scripts/phone_rules.gd")
const Lines := preload("res://scripts/quest_lines.gd")
const PauseReasons := preload("res://scripts/pause_reasons.gd")

var m: Node
var hud: CanvasLayer
## The food offer on screen (phone_rules.gd `food_offer`), taken by TAKE.
var _food := {}


func _init(main: Node) -> void:
	m = main


## Connects the HUD's chip and the card's presses.
func wire(h: CanvasLayer) -> void:
	hud = h
	hud.phone_pressed.connect(open)
	var hub: Control = hud.phone_hub
	hub.closed.connect(_closed)
	hub.app_pressed.connect(_app)
	hub.home_pressed.connect(_home)
	hub.searched.connect(_searched)
	hub.offer_taken.connect(_taken)
	hub.offer_skipped.connect(_skipped)


## The facts phone_rules.gd `model` draws from.
func facts() -> Dictionary:
	var wallet: Variant = m.get("wallet")
	var jobs_done := 0
	if wallet != null:
		for k: Variant in wallet.jobs:
			jobs_done += int(wallet.jobs[k])
	var rides: Variant = m.get("rides")
	return {"can_ride": rides != null and rides.can_request() and not bool(m.get("flying")),
			"busy": busy(), "jobs_done": jobs_done}


## Something is on that a start from the phone would cut across (the map's hold refuses for the
## same reasons: main.gd `_teleport_refusal`).
func busy() -> bool:
	var stories: Variant = m.get("stories")
	return not (m.call("_teleport_refusal") as Array).is_empty() or hud.call_showing() \
			or (stories != null and stories.talking())


func open() -> void:
	if not bool(m.get("_started")) or m.get("title") != null or hud.settings_open() or hud.full_map_open() or hud.phone_open():
		return
	if bool(m.get("_phone_bench")):
		m.call("_end_phone_bench", false)
	print("phone: open (paused)")
	m.call("_blip_sound")
	(m.get("_pause") as PauseReasons).hold(PauseReasons.PHONE)
	hud.open_phone(Rules.model(facts()))


## Esc closes the phone when it is up (true), else nothing (false).
func close_if_open() -> bool:
	if hud == null or not hud.phone_open():
		return false
	hud.phone_hub.close()
	return true


func _closed() -> void:
	var pause := m.get("_pause") as PauseReasons
	pause.release(PauseReasons.PHONE)
	var rides: Variant = m.get("rides")
	if rides != null:
		rides.peeked = {}  # a passenger looked at and not taken is gone
	_food = {}
	print("phone: closed%s" % pause.still())


func _home() -> void:
	hud.phone_hub.show_home(Rules.model(facts()))


func _app_def(key: String) -> Array:
	for a: Array in Rules.APPS:
		if str(a[0]) == key:
			return a
	return []


## An app tile: the offering apps search, QUESTS opens the big screen, COTAM is not built.
func _app(key: String) -> void:
	print("phone: app %s" % key)
	match Rules.kind(key):
		"offer":
			var def := _app_def(key)
			hud.phone_hub.show_search(key, Rules.words("app_" + key), def[1])
		"screen":
			hud.phone_hub.close()
			m.call("_open_full_map")
			if hud.full_map_open():
				hud.full_map.open_screen("stories")


## The search is over: the offer, or nothing.
func _searched(key: String) -> void:
	var hub: Control = hud.phone_hub
	var def := _app_def(key)
	var title := Rules.words("app_" + key)
	var colour: Color = def[1]
	var offer := {}
	_food = {}
	match key:
		"luber":
			var rides: Variant = m.get("rides")
			var r: Dictionary = rides.peek() if rides != null else {}
			if not r.is_empty():
				offer = {"who": r["who"], "title": r["title"], "body": r["body"]}
		"glodno":
			if not busy():
				var car: Variant = m.get("car")
				var from := Vector2(car.global_position.x, car.global_position.z) if car != null else Vector2.ZERO
				var entries: Array = m.call("_quest_entries")
				var far := [Lines.far_text(from, _nearest_food(entries, from), true), Lines.far_text(from, _nearest_food(entries, from), false)]
				_food = Rules.food_offer(entries, from, far)
				offer = _food
	if offer.is_empty():
		hub.show_none(key, title, colour)
	else:
		hub.show_offer(key, title, offer, colour)


func _nearest_food(entries: Array, from: Vector2) -> Vector2:
	var best := Vector2.INF
	for e: Dictionary in entries:
		if Rules.FOOD_GROUPS.has(str(e.get("group", ""))) and e["at"] != Vector2.INF:
			if best == Vector2.INF or from.distance_to(e["at"]) < from.distance_to(best):
				best = e["at"]
	return best if best != Vector2.INF else from


## TAKE: the ride starts, or the food place is pinned on the map; the phone closes.
func _taken(key: String) -> void:
	print("phone: took %s" % key)
	hud.phone_hub.close()
	match key:
		"luber":
			var rides: Variant = m.get("rides")
			if rides == null or not rides.take_peeked():
				hud.toast(Rules.words("busy")[0], Rules.words("busy")[1])
		"glodno":
			if not _food.is_empty() and not busy():
				m.set("quest_pin", _food["entry"])
			else:
				hud.toast(Rules.words("busy")[0], Rules.words("busy")[1])


## SKIP: the next one is looked for.
func _skipped(key: String) -> void:
	print("phone: skipped %s" % key)
	_app(key)
