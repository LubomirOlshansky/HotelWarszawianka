extends RefCounted
## The game's time owner (F 2026-11-19: "a centralized system that understands time and which
## activity is on at what time"). One table of every activity's hours, read from data/pacing.json,
## and the three answers everything else asks: is it open now (`open_now`, `open_ids`), may its
## friend call now (`may_call`), and the clock's jump to its hour (`jump`, `jump_into`).
##
## Game time (time_of_day.gd `local_clock`): a new game starts at 14:00 on this week's Friday and
## the game clock runs at 30x (time.speed: a game day in 48 real minutes, the sun by the date). At
## real speed, before it, the night friends (the shisha night, the bar crawl, the racing club,
## Mati's raves) never called in a normal session. With `time.by_day` on, they call at any hour, and the run they offer jumps the
## clock to its opening hour when the player says yes ("You wait until 21:00"), as the quest
## map's starts already did (story_quests.gd `skip_to`). Their call cards say so (activity.gd
## `_night_line`).
##
## The map's clock (full_map.gd) reads `label` and `open_ids`, and its picker sets the look the
## settings' Time of day sets. Static and pure but `jump` (it sets the TimeOfDay node):
## game/tools/check_game_time.gd tests it.

const Pacer := preload("res://scripts/pacer.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")

## Every activity with opening hours: its id -> [pacing.json source, key]. The first word of each
## id's name ([Polish, English]) is what the map's clock lists as open.
const SOURCES := {
	"boat": ["boat", "hours"], "kino": ["kino", "hours"], "dekalog": ["dekalog", "hours"],
	"shisha": ["shisha", "hours"], "crawl": ["crawl", "hours"], "meet": ["meet", "hours"],
	"rave": ["rave", "tease_hours"], "kawa": ["trend", "kawa_hours"], "deski": ["trend", "deski_hours"],
	"mlask": ["trend", "ml_hours"],
}
const NAMES := {
	"boat": ["Łódki", "Boat race"], "kino": ["Kino", "Cinema tour"], "dekalog": ["Dekalog", "Dekalog tour"],
	"shisha": ["Shisha", "Shisha night"], "crawl": ["Bary", "Bar crawl"], "meet": ["Nocne wyścigi", "Night racing"],
	"rave": ["Rave", "Rave"], "kawa": ["Kawa", "Coffee run"], "deski": ["Padel", "Padel"],
	"mlask": ["Mlask", "Mlask"],
}
## The night activities whose friend calls by day when `by_day` is on (a yes jumps the clock).
const NIGHT := ["shisha", "crawl", "meet", "rave"]
const DAYS := [["PN", "Mon"], ["WT", "Tue"], ["ŚR", "Wed"], ["CZW", "Thu"], ["PT", "Fri"], ["SOB", "Sat"], ["ND", "Sun"]]

## 1: the night friends call at any hour and a yes jumps the clock; 0: only in their hours.
static var BY_DAY: float = Pacer.num("time", "by_day")


## F 2026-11-26 (story-structure, "The clock"): the clock goes at time.hold_speed (real time) while
## any of these runs: a questline of story_quests.gd's `defs` (its `busy`), or `extra` (the Tajny
## klient chapter). Jobs, rides, rival races and rescues are not questlines, so the day still moves
## while the player grinds. main.gd's story tick sets time_of_day.gd `held` from this.
static func held_for(defs: Array, extra := false) -> bool:
	if extra:
		return true
	for d: Variant in defs:
		if d is Dictionary:
			var b: Callable = (d as Dictionary).get("busy", Callable())
			if b.is_valid() and bool(b.call()):
				return true
	return false


## Within hours [from, to) that may wrap past midnight.
static func in_hours(hour: float, h: Vector2) -> bool:
	return (hour >= h.x and hour < h.y) if h.x < h.y else (hour >= h.x or hour < h.y)


## An activity's hours (Vector2(0, 24) for an id the table lacks: always open).
static func hours(id: String) -> Vector2:
	if not SOURCES.has(id):
		return Vector2(0.0, 24.0)
	var s: Array = SOURCES[id]
	return Pacer.span(str(s[0]), str(s[1]))


static func open_now(id: String, hour: float) -> bool:
	return in_hours(hour, hours(id))


## The ids open at `hour`, in the table's order.
static func open_ids(hour: float) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in SOURCES:
		if open_now(id, hour):
			out.append(id)
	return out


## A friend whose run keeps hours `h` may call at `hour`: in them, or any time for a night activity
## with `by_day` on (`night`).
static func may_call(h: Vector2, hour: float, night := true) -> bool:
	return in_hours(hour, h) or (night and BY_DAY > 0.0)


## The fixed look whose light fits `hour` (time_of_day.gd `look_at`): the jump to a night hour
## turns the city dark too.
static func look_for(hour: float) -> String:
	return TimeOfDay.look_at(hour)


## The clock jumps to `hour` (0-24; time_of_day.gd `set_hour`: on the game clock it moves forward
## and the light follows the sun, else the look that fits) and one toast says so. False without a
## clock.
static func jump(tod: Node, hud: Node, hour: float) -> bool:
	if tod == null:
		return false
	tod.set_hour(hour)
	var hm := "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]
	if hud != null:
		hud.toast("Czekacie do %s." % hm, "You wait until %s." % hm)
	return true


## Promo Mode's -15 / +15 (promo_mode.gd): the clock moves by `minutes`, either way, with no
## toast (the promo readout shows the time). False without a clock.
static func nudge(tod: Node, minutes: float) -> bool:
	if tod == null:
		return false
	tod.shift_clock(minutes)
	return true


## A run that keeps hours `h` starts: outside them the clock jumps to their opening (a few minutes
## in, so the hour is inside). True when it jumped.
static func jump_into(tod: Node, hud: Node, h: Vector2) -> bool:
	if tod == null or h.x < 0.0 or in_hours(float(tod.local_clock()["hour"]), h):
		return false
	return jump(tod, hud, fmod(h.x + 0.05, 24.0))


## "PT 14:05", "Fri 14:05" for a clock {hour, weekday} (time_of_day.gd local_clock).
static func label(c: Dictionary) -> Array:
	var h: float = float(c.get("hour", 12.0))
	var d: Array = DAYS[clampi(int(c.get("weekday", 5)) - 1, 0, 6)]
	var hm := "%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)]
	return ["%s %s" % [d[0], hm], "%s %s" % [d[1], hm]]
