extends RefCounted
## Two quest lines (G12, 2026-11-02): CAR (kebab, Łuber, couriers, races) and HELI (rescues only
## the helicopter reaches). F asked that flying shows helicopter quests and driving car quests, each
## with its own marker colour. The main line stays one path and is not touched here.
## A rescue the car can also reach (street, park, shore) is not heli-only: it stays on offer in
## both vehicles and keeps its amber pickup; only heli-only calls take the HELI colour.

## STORY (2026-11-07, story_quests.gd): the full map's WĄTKI tab, the big questlines; a beta
## list where a tap starts one now.
enum Line { CAR, HELI, STORY }

## The WĄTKI tab's and the questlines' default accent (story_quests.gd): a warm pink that neither
## the main gold, the car amber nor the heli violet use.
const STORY_COLOUR := Color("#ff5e8a")
## The marker colour of heli-only quests (a violet that neither the amber pickup, the teal ride
## nor the blue/green drop-offs use, colour-safe mode included).
const HELI_COLOUR := Color("#b48cff")


## The line of a rescue call (`heli` is the mission's flag).
static func of_mission(m: Dictionary) -> int:
	return Line.HELI if bool(m.get("heli", false)) else Line.CAR


## True when a quest of `line` shows its marker and arrow for a player who is `flying`: car quests
## stay out of the helicopter's way; heli quests are always shown once taken, so a driver who
## accepted one is still told where to go (and to press HELI).
static func shows(line: int, flying: bool) -> bool:
	return line == Line.HELI or not flying


## Which places a new rescue call may pick from, for a player who is `flying`: flying prefers the
## heli-only places, driving the ones the car reaches. Returns `list` itself when the preferred
## half is empty, so a call is never lost.
static func prefer(list: Array, flying: bool) -> Array:
	var keep := list.filter(func(p: Dictionary) -> bool: return bool(p.get("heli", false)) == flying)
	return keep if not keep.is_empty() else list


## The rescue kind a new call takes for a player who is `flying` (kinds as rescue_places.gd `Kind`:
## 0 street, 1 roof, 2 river, 3 park): flying turns the street and park calls into roof calls
## (the helicopter's own), driving turns roof calls into park calls.
static func kind_for(kind: int, flying: bool) -> int:
	if flying and (kind == 0 or kind == 3):
		return 1
	if not flying and kind == 1:
		return 3
	return kind


# --- G12 part 2: the quest lists (full_map.gd's ZADANIA card) ---------------------------------
## F asked for car quests and heli quests "each with its own list". The full map carries a card with
## two tabs, AUTO and HELI, each listing what can be started now: places (a kebab stand, a station,
## a cassette on a roof) nearest first with their distance and compass direction, and requests (a
## Łuber ride, a helicopter rescue call) that start at once. A tapped place becomes the quest pin
## (main.gd `quest_pin`): the arrow and the minimap dot point at it until the vehicle is there.

## The rows a tab shows at most (44 pt each, the card must fit under the map's buttons on a 375 pt
## tall phone).
const MAX_ROWS := 4
## The WĄTKI tab lists every questline (about ten later), in a scroll of MAX_ROWS rows' height.
const STORY_ROWS := 12
## Of each group only the nearest are listed (one kebab stand, not all nine), these groups more.
const GROUP_KEEP := {"cassette": 3}
## The quest pin counts as reached within this many metres (ground plane).
const PIN_REACH := 25.0
const COMPASS_PL := ["płn.", "płn.-wsch.", "wsch.", "płd.-wsch.", "płd.", "płd.-zach.", "zach.", "płn.-zach."]
const COMPASS_EN := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


## G12c: the action of the row for the quest under way (a race, a job, a ride, a rescue): it leads
## its tab and, tapped, only centres the map on its target (the arrow already points there).
const NOW := "now"
## G12c: groups that move (a rival cruising in traffic): main.gd moves the pin with them.
const MOVING := ["rival"]


## A quest for the list: `id` unique, `group` (kebab, sloik, cassette...), its line, its name
## [pl, en], its place (map x, z; Vector2.INF for a request) and colour, and `action` for a request
## ("ride", "call", "peacock"; NOW for the quest under way; "" for a place to drive or fly to).
static func entry(id: String, group: String, line: int, pl: String, en: String, at: Vector2, colour: Color,
		action := "") -> Dictionary:
	return {"id": id, "group": group, "line": line, "pl": pl, "en": en, "at": at, "colour": colour, "action": action}


## The compass point (0 north .. 7 north-west) of `to` seen from `from` (map +x east, -z north).
static func compass(from: Vector2, to: Vector2) -> int:
	var d := to - from
	return int(round(fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0) / 45.0)) % 8


## "420 m płn." / "1,2 km NE": a row's distance (10 m steps under a kilometre).
static func far_text(from: Vector2, to: Vector2, polish: bool) -> String:
	var m := from.distance_to(to)
	var i := compass(from, to)
	var dist := "%d m" % (int(round(m / 10.0)) * 10) if m < 995.0 else "%.1f km" % (m / 1000.0)
	if polish:
		dist = dist.replace(".", ",")
	return "%s %s" % [dist, COMPASS_PL[i] if polish else COMPASS_EN[i]]


## The rows of `line`'s tab for a player at `from`: the requests first, then the places nearest
## first, each group cut to its nearest (GROUP_KEEP), at most `most`. Each row is its entry plus
## `far` [pl, en] ("" for a request).
static func rows(entries: Array, line: int, from: Vector2, most := MAX_ROWS) -> Array:
	var asks: Array = []
	var places: Array = []
	if line == Line.STORY:
		return _story_rows(entries, from, most)
	for e: Dictionary in entries:
		if int(e["line"]) != line:
			continue
		var r := e.duplicate()
		if str(e["action"]) == NOW:
			# G12c: the quest under way leads the tab, with its distance when it has a place.
			var has_at: bool = e["at"] != Vector2.INF
			r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)] if has_at else ["", ""]
			r["d"] = -2.0
			asks.push_front(r)
		elif str(e["action"]) != "" or e["at"] == Vector2.INF:
			r["far"] = ["", ""]
			r["d"] = -1.0
			asks.append(r)
		else:
			r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)]
			r["d"] = from.distance_to(e["at"])
			places.append(r)
	places.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	var taken := {}
	var out: Array = asks.duplicate()
	for r: Dictionary in places:
		var g := str(r["group"])
		var n: int = taken.get(g, 0)
		if n >= int(GROUP_KEEP.get(g, 1)):
			continue
		taken[g] = n + 1
		out.append(r)
	return out.slice(0, most)


## The WĄTKI tab's rows: every questline, the open ones first, each set nearest first (one with no
## start spot last), with its distance; at most `most` (STORY_ROWS when the caller passes MAX_ROWS).
static func _story_rows(entries: Array, from: Vector2, most: int) -> Array:
	var out: Array = []
	for e: Dictionary in entries:
		if int(e["line"]) != Line.STORY:
			continue
		var r := e.duplicate()
		var has_at: bool = e["at"] != Vector2.INF
		r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)] if has_at else ["", ""]
		r["d"] = (from.distance_to(e["at"]) if has_at else 1e9) + (0.0 if bool(e.get("open", true)) else 1e10)
		out.append(r)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	return out.slice(0, maxi(most, STORY_ROWS) if most == MAX_ROWS else most)


## True when the vehicle at `at` has reached the quest pin `pin` (an entry; {} never).
static func pin_reached(pin: Dictionary, at: Vector2) -> bool:
	if pin.is_empty() or pin.get("at", Vector2.INF) == Vector2.INF:
		return false
	return at.distance_to(pin["at"]) <= PIN_REACH


## G12b: the pad's pick after a D-pad step `dir` (+1 down, -1 up) from row `sel` (-1: none yet) on
## a tab of `count` rows: the first step picks the first (down) or last (up) row, then it wraps
## round; -1 on an empty tab.
static func pad_move(sel: int, count: int, dir: int) -> int:
	if count <= 0:
		return -1
	if sel < 0 or sel >= count:
		return 0 if dir >= 0 else count - 1
	return posmod(sel + dir, count)


# --- First hour, step 4: one map list ---------------------------------------------------------
## The spec "First hour for the beta" (section 3) and the critique's point 7 (F's yes, 2026-11-15):
## the full map's three tabs (AUTO, HELI, WĄTKI) become one scrolling list with sections, grouped by
## what the player wants to know. A new player sees three sections (First steps with only the
## nearest few steps, Around town, Rivals as one row that opens to their names); Friends opens after the third First
## step, Collection after the first find. While something runs only Now shows (as the tab did).
## full_map.gd draws `sections`; the rivals' chips and the collection's line come with it.

## The sections, in the order the list shows them.
const SECTIONS := ["now", "steps", "town", "rivals", "friends", "collection"]
const SECTION_TITLES := {
	"now": ["TERAZ", "NOW"],
	"steps": ["PIERWSZE KROKI", "FIRST STEPS"],
	"rivals": ["RYWALE", "RIVALS"],
	"town": ["W MIEŚCIE", "AROUND TOWN"],
	"friends": ["ZNAJOMI", "FRIENDS"],
	"collection": ["KOLEKCJA", "COLLECTION"],
}
## The First steps left that the list shows (the critique: two or three, not seven).
const STEPS_SHOWN := 3
## Around town's rows at most: one per kind of job, nearest first.
const TOWN_ROWS := 6
## Friends' rows at most (the questlines, open ones nearest first).
const FRIENDS_ROWS := 6
## A step row's action when tapped calls a rival out (full_map.gd `rival_called`), and the night
## button's (main.gd switches the night on for the final).
const RIVAL_CALL := "rival_call"
const NIGHT := "night"
## The groups that belong to the Rivals section, not Around town.
const RIVAL_GROUPS := ["rival", "final"]


## The list's sections for a player at `from`. `entries` as `rows` takes them (main.gd
## `_quest_entries`); `line` is the vehicle's own (its places come first in Around town); `steps`
## the First steps left, each {"id", "pl", "en", "entry"} with `entry` the place or request that
## does it ({} for none: a step done by a button, as the helicopter); `friends` opens the Friends
## section. Returns [{"key", "rows"}], only the sections with rows (Rivals and Collection are drawn
## from their own data by full_map.gd; their keys come with no rows). Each row is an entry with
## `far` [pl, en]; a step row also has `step` (its id) and `label` (true: not tappable).
static func sections(entries: Array, line: int, from: Vector2, steps: Array, friends: bool) -> Array:
	var out: Array = []
	for e: Dictionary in entries:
		if str(e["action"]) == NOW:
			return [{"key": "now", "rows": rows(entries, int(e["line"]), from, 1)}]
	var step_rows := _step_rows(steps, from)
	if not step_rows.is_empty():
		out.append({"key": "steps", "rows": step_rows})
	var finals: Array = []
	for e: Dictionary in entries:
		if str(e["group"]) == "final":
			var r := e.duplicate()
			r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)] if e["at"] != Vector2.INF else ["", ""]
			finals.append(r)
	var town := _town_rows(entries, line, from, step_rows.map(func(r: Dictionary) -> String: return str(r["group"])))
	if not town.is_empty():
		out.append({"key": "town", "rows": town})
	out.append({"key": "rivals", "rows": finals})
	if friends:
		var f := _story_rows(entries, from, FRIENDS_ROWS)
		if not f.is_empty():
			out.append({"key": "friends", "rows": f})
	out.append({"key": "collection", "rows": []})
	return out


## Around town: the requests of both lines first (a ride, a rescue call), then the vehicle's own
## line's places nearest first, then the other line's, one per kind (GROUP_KEEP), no rivals; a kind
## First steps already shows (`shown` groups) is not listed twice.
static func _town_rows(entries: Array, line: int, from: Vector2, shown: Array = []) -> Array:
	var asks: Array = []
	var own: Array = []
	var other: Array = []
	for e: Dictionary in entries:
		var l := int(e["line"])
		if l == Line.STORY or str(e["group"]) in RIVAL_GROUPS or str(e["group"]) in shown:
			continue
		var r := e.duplicate()
		if str(e["action"]) != "" or e["at"] == Vector2.INF:
			r["far"] = ["", ""]
			asks.append(r)
			continue
		r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)]
		r["d"] = from.distance_to(e["at"])
		(own if l == line else other).append(r)
	var near := func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"])
	own.sort_custom(near)
	other.sort_custom(near)
	var out: Array = asks.duplicate()
	var taken := {}
	for r: Dictionary in own + other:
		var g := str(r["group"])
		var n: int = taken.get(g, 0)
		if n >= int(GROUP_KEEP.get(g, 1)):
			continue
		taken[g] = n + 1
		out.append(r)
	return out.slice(0, TOWN_ROWS)


## The First steps left as rows: the ones with a place nearest first, then the requests (a ride, a
## rescue call, a rival called out), then the ones a button does (labels); STEPS_SHOWN at most.
static func _step_rows(steps: Array, from: Vector2) -> Array:
	var placed: Array = []
	var asks: Array = []
	var labels: Array = []
	for s: Dictionary in steps:
		var e: Dictionary = s.get("entry", {})
		var r := {}
		if e.is_empty():
			r = entry("step_" + str(s["id"]), "step", Line.CAR, str(s["pl"]), str(s["en"]), Vector2.INF, Color("#ffd23f"))
			r["label"] = true
			r["far"] = ["", ""]
			labels.append(r)
		else:
			r = e.duplicate()
			r["pl"] = str(s["pl"])
			r["en"] = str(s["en"])
			r["label"] = false
			if str(e["action"]) == "" and e["at"] != Vector2.INF:
				r["far"] = [far_text(from, e["at"], true), far_text(from, e["at"], false)]
				r["d"] = from.distance_to(e["at"])
				placed.append(r)
			else:
				r["far"] = ["", ""]
				asks.append(r)
		r["step"] = str(s["id"])
	placed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	return (placed + asks + labels).slice(0, STEPS_SHOWN)
