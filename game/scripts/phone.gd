extends RefCounted
## The phone's owner (F 2026-11-26, "the phone with jobs"): the TELEFON chip opens phone_hub.gd with
## phone_rules.gd's `model` of the game's facts; an app press goes to its owner (the ride to
## rides.gd, the side jobs and the questlines to the QUESTS screen, a featured quest to
## story_quests.gd `start`). The game pauses under the card (PauseReasons.PHONE). It reads the
## game through `m` (main.gd) when it is used, so it can be built before the systems it asks.
## Add-ons: Beehave and Dialogue Manager not used (a menu, no behaviour and no conversation).

const Rules := preload("res://scripts/phone_rules.gd")
const QuestBook := preload("res://scripts/quest_book.gd")
const PauseReasons := preload("res://scripts/pause_reasons.gd")

var m: Node
var hud: CanvasLayer


func _init(main: Node) -> void:
	m = main


## Connects the HUD's chip and the card's presses.
func wire(h: CanvasLayer) -> void:
	hud = h
	hud.phone_pressed.connect(open)
	hud.phone_hub.closed.connect(_closed)
	hud.phone_hub.app_pressed.connect(_app)
	hud.phone_hub.featured_pressed.connect(_featured)


## The facts phone_rules.gd `model` draws from.
func facts() -> Dictionary:
	var ids: Array = []
	var done: Array = []
	var stories: Variant = m.get("stories")
	var wallet: Variant = m.get("wallet")
	if stories != null:
		for d: Dictionary in stories.defs:
			ids.append(str(d["id"]))
			if wallet != null and QuestBook.is_done(wallet.intro, str(d["id"])):
				done.append(str(d["id"]))
	var jobs_done := 0
	if wallet != null:
		for k: Variant in wallet.jobs:
			jobs_done += int(wallet.jobs[k])
	var rides: Variant = m.get("rides")
	return {"can_ride": rides != null and rides.can_request() and not bool(m.get("flying")),
			"busy": busy(), "stories": ids, "done": done, "jobs_done": jobs_done}


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
	print("phone: closed%s" % pause.still())


## The ride app asks for a ride; jobs and quests open the QUESTS screen on their tab.
func _app(key: String) -> void:
	hud.phone_hub.close()
	print("phone: app %s" % key)
	var rides: Variant = m.get("rides")
	match key:
		"luber":
			if rides != null and rides.can_request():
				rides.request()
			else:
				hud.toast(Rules.words("no_ride")[0], Rules.words("no_ride")[1])
		"jobs", "quests":
			m.call("_open_full_map")
			if hud.full_map_open():
				hud.full_map.open_screen("jobs" if key == "jobs" else "stories")


## A featured quest's START: its friend phones now, at any hour (story_quests.gd `start`).
func _featured(id: String) -> void:
	hud.phone_hub.close()
	print("phone: featured %s" % id)
	var stories: Variant = m.get("stories")
	if busy() or stories == null or not stories.start(id):
		hud.toast(Rules.words("busy")[0], Rules.words("busy")[1])
