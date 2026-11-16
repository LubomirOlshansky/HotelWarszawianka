extends RefCounted
## First hour step 6 (docs/design/onboarding-hints.md; the first-hour spec, section 6, accepted by
## F on 2026-11-15): short hints in play that show only when the player needs them. George Fan's
## rules: eight words at most, the game never pauses, a hint shows only to a player who has not
## done the thing, once (the ring's twice), and never in a race, a chase or a scripted moment (the
## message director's CHASE and FOCUS contexts), nor while a card is up.
##
## | id | the hint | shows when | goes when |
## | stop | "Slow down and stop in the ring" over the car | in a job's ring faster than STOP_FAST, the first STOP_TIMES times | the car stands |
## | reverse | "Hold BRAKE to reverse" round the brake | trying to drive in one spot for STALL_HINT s (car.gd `stalled`), before the tow offer at Car.STALL_TIME | the car moves |
## | minimap | "Tap the map: all of Warsaw" round the minimap | free driving after the first pay or MINIMAP_DRIVE_S s of it, the full map never opened; twice at most | the map opens |
## | heli | "Roof? Take the helicopter" round HELI | a rescue only the helicopter reaches, by car | the take-off |
## | climb | "Hold: up and down" round the up pad | the first flight, until the up or down pad (or key) is used | climbing or sinking |
## | land | "Land by the person" over the helicopter | flying within LAND_NEAR m of a roof rescue's person | the pick-up |
##
## The full map's coach marks (map_list, map_hold, map_pin; `decide_map`, `map_tick`) are the same
## rules inside the map: one at a time, once, each gone when the player does the thing (scrolls the
## list, holds a spot, taps a place); full_map.gd draws them (the game is paused under the map, so
## hud.gd's spotlight is not used) and its "?" button plays them again.
##
## The words are game/data/tips.json `hints`; what was shown is the save's [intro] section, under
## "hint_<id>" (wallet.gd). main.gd hands `tick` the facts five times a second (`_hints_frame`);
## the spotlight is hud.gd's (`spotlight`). `decide` is pure: game/tools/check_hints.gd drives it.

const Lang := preload("res://scripts/lang.gd")
const Messages := preload("res://scripts/messages.gd")
const FILE := "res://data/tips.json"
const IDS := ["stop", "reverse", "minimap", "heli", "climb", "land"]
## Things done that a hint or a loading tip asks about, kept beside the hints: the full map opened
## once, a flight once (`tick` notes them from `map_open` and `flying`).
const DID := ["map", "flown"]
## The full map's coach marks, in the order they show (save keys "hint_map_list" and so on).
const MAP_IDS := ["map_list", "map_hold", "map_pin"]
## Driving this long (s) in free driving also brings the minimap hint, pay or not (a player who
## has not been paid yet has still not found the map).
const MINIMAP_DRIVE_S := 60.0
## A map coach mark gives way to the next after this long (s) if the thing was not done.
const COACH_LIFE := 9.0
## Where each hint's ring goes (hud.gd `spotlight`).
const TARGETS := {"stop": "car", "reverse": "brake", "minimap": "minimap", "heli": "heli", "climb": "climb", "land": "car"}
## How many times each shows at most.
const TIMES := {"stop": 2, "minimap": 2}
## Faster than this (m/s, ~16 km/h) in a job's ring: "stop in the ring".
const STOP_FAST := 4.5
## Trying to drive in one spot this long (s): "hold BRAKE to reverse" (the tow offer comes at 8).
const STALL_HINT := 3.0
## A roof rescue's person this near (m, flat) while flying: "land by the person".
const LAND_NEAR := 120.0
## At least this long (s) between two hints that are not urgent (the minimap's).
const GAP := 20.0
## How long a hint stays up at most (s).
const LIFE := 7.0
const KEY := "hint_"

## Shown so far: id -> times (the save's [intro] "hint_<id>").
var seen := {}
## DID's things done so far (the save's [intro] "hint_map", "hint_flown").
var did := {}
## True when `seen` or `did` changed since the last `save_to` (main.gd saves the wallet then).
var dirty := false
## The hint up now ("" none) and how long it has been up.
var current := ""
var up_for := 0.0
## Every hint shown this run, in order (the log, check_hints).
var shown_log: Array[String] = []
## Off for this run (the bench, the probe, the demo, --no-hints), and a hint to put up at once
## (--hint=ID, for a shot of the spotlight): `use_flags`.
var off := false
var force := ""
var _since := GAP
## Seconds of free driving so far this run (`tick` adds the dt of a tick with the fact "driving").
var _drive := 0.0
## The map coach mark up now ("" none), how long it has been up, and the ones a replay (the map's
## "?") has shown so far.
var coach := ""
var coach_for := 0.0
var _replayed := {}
var _was_fast := false
var _words := {}


func _init() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if d is Dictionary:
		_words = (d as Dictionary).get("hints", {})


## The run's flags (dev_flags.gd): off on the bench, the probe and the demo and with --no-hints;
## --hint=ID; --map-coach (the map's coach marks as if never seen).
func use_flags(flags: Object) -> void:
	off = bool(flags.bench) or bool(flags.probe) or bool(flags.demo) or bool(flags.no_hints)
	force = str(flags.hint_flag)
	if bool(flags.map_coach):
		for id: String in MAP_IDS:
			seen.erase(id)


## The words of hint `id` in the game's language.
func words(id: String) -> String:
	var w: Dictionary = _words.get(id, {})
	return Lang.pick(str(w.get("pl", "")), str(w.get("en", "")))


## Reads what was shown from the save's [intro] section.
func load_from(intro: Dictionary) -> void:
	seen.clear()
	did.clear()
	for id: String in IDS + MAP_IDS:
		if intro.has(KEY + id):
			seen[id] = int(intro[KEY + id])
	for id: String in DID:
		if intro.has(KEY + id):
			did[id] = 1


## Writes it back (wallet.gd saves the section).
func save_to(intro: Dictionary) -> void:
	for id: String in seen:
		intro[KEY + id] = int(seen[id])
	for id: String in did:
		intro[KEY + id] = 1
	dirty = false


## Hint `id`'s words in the game's language without an instance (the map's coach marks).
static func words_of(id: String) -> String:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	var w: Dictionary = ((d as Dictionary).get("hints", {}) as Dictionary).get(id, {}) if d is Dictionary else {}
	return Lang.pick(str(w.get("pl", "")), str(w.get("en", "")))


func _left(id: String) -> bool:
	return int(seen.get(id, 0)) < int(TIMES.get(id, 1))


## The hint to show now ("" none), from the facts (`tick` lists them). Pure but for the ring's
## edge (a hint for each time the car comes into a ring too fast, not for each tick in it).
func decide(f: Dictionary) -> String:
	var ctx := int(f.get("context", Messages.FREE))
	var fast := bool(f.get("in_ring", false)) and float(f.get("speed", 0.0)) > STOP_FAST and not bool(f.get("flying", false))
	var edge := fast and not _was_fast
	_was_fast = fast
	if ctx == Messages.CHASE or ctx == Messages.FOCUS or bool(f.get("card", false)) or current != "":
		return ""
	if edge and _left("stop"):
		return "stop"
	var flying := bool(f.get("flying", false))
	if not flying and float(f.get("stalled", 0.0)) >= STALL_HINT and _left("reverse"):
		return "reverse"
	if not flying and bool(f.get("heli_call", false)) and bool(f.get("heli_shown", false)) and _left("heli"):
		return "heli"
	if flying and not bool(f.get("climbed", false)) and _left("climb"):
		return "climb"
	if flying and bool(f.get("land_near", false)) and _left("land"):
		return "land"
	var asked := bool(f.get("earned", false)) or float(f.get("drive_s", 0.0)) >= MINIMAP_DRIVE_S
	if ctx == Messages.FREE and _since >= GAP and asked and not did.has("map") and _left("minimap"):
		return "minimap"
	return ""


## The hint up now is done with (the player did the thing, or a chase began).
func done_now(f: Dictionary) -> bool:
	var ctx := int(f.get("context", Messages.FREE))
	if ctx == Messages.CHASE or ctx == Messages.FOCUS or up_for >= LIFE:
		return true
	var flying := bool(f.get("flying", false))
	match current:
		"stop":
			return float(f.get("speed", 0.0)) < 1.0 or not bool(f.get("in_ring", false))
		"reverse":
			return float(f.get("stalled", 0.0)) < 0.5 or flying
		"minimap":
			return did.has("map")
		"heli":
			return flying or not bool(f.get("heli_call", false))
		"climb":
			return bool(f.get("climbed", false)) or not flying
		"land":
			return not bool(f.get("land_near", false)) or not flying
	return true


## Five times a second (main.gd): takes a hint down when it is done, puts up the next one.
## `f`: context (messages.gd), card (a card is up), flying, speed (m/s), in_ring (in a job's ring),
## stalled (car.gd), heli_call (a rescue only the helicopter reaches), heli_shown (the HELI chip),
## climbed (this flight), land_near, earned (any pay so far), map_open (the full map is open),
## driving (the car is moving in free driving: `tick` sums it into drive_s, which a check may give).
## Returns the id it put up ("" none); `hud` may be null (a check).
func tick(dt: float, f: Dictionary, hud: Object) -> String:
	_since += dt
	if bool(f.get("driving", false)) and int(f.get("context", Messages.FREE)) == Messages.FREE and not bool(f.get("flying", false)):
		_drive += dt
	if not f.has("drive_s"):
		f["drive_s"] = _drive
	for pair: Array in [["map", "map_open"], ["flown", "flying"]]:
		if bool(f.get(pair[1], false)) and not did.has(pair[0]):
			did[pair[0]] = 1
			dirty = true
	if current != "":
		up_for += dt
		if done_now(f):
			current = ""
			if hud != null:
				hud.spotlight_off()
	var id := decide(f)
	if id == "":
		return ""
	current = id
	up_for = 0.0
	_since = 0.0
	seen[id] = int(seen.get(id, 0)) + 1
	dirty = true
	shown_log.append(id)
	if hud != null:
		hud.spotlight(TARGETS[id], words(id), LIFE)
	print("hints: %s (%d)" % [id, int(seen[id])])
	return id


## The map coach mark to show now ("" none), from the facts the map gives: scrollable (the list
## is longer than its scroll), has_place (a place row to tap), cards (the ≡ cards are up: no coach
## mark then), replay (the "?" was tapped: every mark again, once each, whether seen or not).
## Pure but for `_replayed`. One at a time, in MAP_IDS' order.
func decide_map(f: Dictionary) -> String:
	if coach != "" or bool(f.get("cards", false)):
		return ""
	var replay := bool(f.get("replay", false))
	for id: String in MAP_IDS:
		var avail := not _replayed.has(id) if replay else int(seen.get(id, 0)) < 1
		if not avail:
			continue
		if id == "map_list" and not bool(f.get("scrollable", false)):
			continue
		if id == "map_pin" and not bool(f.get("has_place", false)):
			continue
		return id
	return ""


## The map coach mark up now is done: the player did its thing (did_scroll, did_hold, did_pin
## in the facts), it has been up COACH_LIFE s, or the ≡ cards came up.
func map_done(f: Dictionary) -> bool:
	if coach_for >= COACH_LIFE or bool(f.get("cards", false)):
		return true
	match coach:
		"map_list":
			return bool(f.get("did_scroll", false))
		"map_hold":
			return bool(f.get("did_hold", false))
		"map_pin":
			return bool(f.get("did_pin", false))
	return true


## Every frame the map is open (full_map.gd): takes a coach mark down when done, puts the next
## up, counts it shown (a replay does not touch the save). Returns the id up now ("" none).
func map_tick(dt: float, f: Dictionary) -> String:
	if coach != "":
		coach_for += dt
		if map_done(f):
			coach = ""
	var id := decide_map(f)
	if id != "":
		coach = id
		coach_for = 0.0
		if bool(f.get("replay", false)):
			_replayed[id] = 1
		else:
			seen[id] = int(seen.get(id, 0)) + 1
			dirty = true
		shown_log.append(id)
		print("hints: %s (%d)" % [id, int(seen.get(id, 0))])
	return coach


## The map closed or a replay ended: no coach mark up, the replay's memory cleared.
func map_reset() -> void:
	coach = ""
	coach_for = 0.0
	_replayed.clear()


## The tags of the loading tips this save has done (tips.json `tag`; the title puts those tips
## last). From the save: the jobs done, the ladder, the [intro] hints.
static func done_tags(wallet: Object) -> PackedStringArray:
	var out := PackedStringArray()
	if wallet == null:
		return out
	var intro: Dictionary = wallet.get("intro") if wallet.get("intro") is Dictionary else {}
	if wallet.has_method("jobs_done") and int(wallet.jobs_done()) > 0:
		out.append("delivered")
	var ladder: Variant = wallet.get("ladder")
	if ladder is Dictionary and not (ladder as Dictionary).is_empty():
		out.append("raced")
	if intro.has(KEY + "map"):
		out.append("map")
	if intro.has(KEY + "flown"):
		out.append("flown")
	return out
