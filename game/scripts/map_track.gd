extends RefCounted
## The full map's track and "?" marks (F's ask 2026-11-16, after the Witcher 3's map and
## GTA; docs/architecture/map-markers.md "Track and ?"). Pure state and rules, no nodes:
## full_map.gd draws and taps, main.gd feeds it, game/tools/check_hud.gd and check_map_track.gd
## drive it.
##
## TRACK. The tracked thing is the quest pin (main.gd `quest_pin`, full_map.gd `quest_pick`): SHOW
## ON MAP on the QUESTS screen, ROUTE on a questline's dot or TRACK on a "?" pins it, STOP TRACKING
## lets it go. What is new is only that the pin is kept across sessions (this instance: the save's
## [intro] section, one key "track_<id>", no wallet version change) and that the full map shows it
## gold on the map and on the NEXT line.
## The pin is the registry's TARGET mark whenever no activity has a target of its own
## (main.gd `_show_target` -> `_put_target`), and so the road route (target_route.gd) follows it.
##
## FILTERS (2026-11-16) went with the legend on 2026-11-17 (F: "make the map minimalistic"; the
## QUESTS screen, quest_book.gd, lists what the map no longer does).
##
## "?" MARKS. A First step not done whose map point nothing else shows: `unknown_marks` gives its
## UNKNOWN-layer mark (group "unknown", owner OWNER), a tap on it tells the step's teaser line
## (dialogue.json first_steps `unknown_<id>`) and offers TRACK. Only the steps that have a fixed
## place (PLACED): the others (a ride, a race, the police) have none.

const Lines := preload("res://scripts/quest_lines.gd")
const FirstSteps := preload("res://scripts/first_steps.gd")
const MapMarkers := preload("res://scripts/map_markers.gd")

## The save's [intro] key prefix: "track_<sanitised id>" (the value is 1).
const KEY := "track_"
## The registry owner and group of the "?" marks.
const OWNER := "unknown"
const GROUP := "unknown"
## The First steps that have a fixed place, and the line (vehicle) that reaches it.
const PLACED := ["garage", "heli"]
## The "?" mark's colour (the map's gold).
const COLOUR := Color("#f0b429")
## A saved id that never resolves is let go after this many tries (main.gd `_story_tick`, 4 a second).
const TRIES := 40

## The tracked id the save holds, waiting for the world to offer it again ("" none); `tried` counts.
var pending := ""
var tried := 0
## The id tracked now ("" none), and whether it changed since the last `save_to`.
var tracked := ""
var dirty := false


## A saved key's tail for `id`: letters, digits, "_" and "-" only (ConfigFile keys).
static func clean(id: String) -> String:
	var out := ""
	for ch in id:
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "_" or ch == "-" else "_"
	return out


## A pin can be kept: a place with a fixed id (a rival's pin moves and a request has no place).
static func keepable(pin: Dictionary) -> bool:
	return not pin.is_empty() and str(pin.get("id", "")) != "" and pin.get("at", Vector2.INF) != Vector2.INF \
			and not (str(pin.get("group", "")) in Lines.MOVING) and str(pin.get("action", "")) == ""


## The save's tracked id from `intro` ("" none): the first "track_" key; `pending` waits for it.
func load_from(intro: Dictionary) -> void:
	pending = ""
	for key: String in intro:
		if key.begins_with(KEY):
			pending = key.trim_prefix(KEY)
			break
	tracked = pending
	tried = 0
	dirty = false


## The pin changed (main.gd's `quest_pin` setter): a place that can be kept is tracked, anything
## else lets the track go. True when the saved key changed.
func pin(p: Dictionary) -> bool:
	pending = ""
	var now := clean(str(p.get("id", ""))) if keepable(p) else ""
	if now == tracked:
		return false
	tracked = now
	dirty = true
	return true


## Writes the tracked id into `intro` (one key at most); wallet.gd saves the section.
func save_to(intro: Dictionary) -> void:
	for key: String in intro.keys():
		if key.begins_with(KEY):
			intro.erase(key)
	if tracked != "":
		intro[KEY + tracked] = 1
	dirty = false


## One try at the saved id: the entry among `lists` (each an Array of quest entries) whose cleaned
## id it is, or {} (the world has not offered it yet or any more). It lets go after TRIES tries.
func resolve(lists: Array) -> Dictionary:
	if pending == "":
		return {}
	tried += 1
	for list: Array in lists:
		for e: Dictionary in list:
			if keepable(e) and clean(str(e["id"])) == pending:
				pending = ""
				return e
	if tried >= TRIES:
		pending = ""
	return {}


## The "?" marks as the registry takes them (`put_all(OWNER, ...)`): for each step of PLACED not
## ticked in `intro` whose place is in `places` (step -> map point) and not already `shown`
## (step -> true when a mark of its own is on the map: the garage's diamond).
static func unknown_marks(intro: Dictionary, places: Dictionary, shown: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in PLACED:
		var at: Vector2 = places.get(id, Vector2.INF)
		if intro.has(FirstSteps.KEY + id) or at == Vector2.INF or bool(shown.get(id, false)):
			continue
		out.append({"layer": MapMarkers.Layer.UNKNOWN, "at": at, "colour": COLOUR, "group": GROUP, "key": id,
				"extra": {"step": id}})
	return out


## The pin a tap on step `id`'s "?" offers: its place, the step's name, the vehicle's line.
static func entry_of(id: String, at: Vector2) -> Dictionary:
	var name: Array = FirstSteps.name_of(id)
	return Lines.entry("unknown_" + id, GROUP, Lines.Line.HELI if id == "heli" else Lines.Line.CAR, str(name[0]), str(name[1]), at, COLOUR)


## The teaser line of step `id` ([pl, en]; dialogue.json first_steps `unknown_<id>`).
static func teaser(id: String) -> Array:
	return FirstSteps.words("unknown_" + id)
