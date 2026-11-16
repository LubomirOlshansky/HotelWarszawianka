extends RefCounted
## The map marker registry (tech-debt TD-13, docs/architecture/map-markers.md section 5): every
## mark the minimap and the full map draw is declared here once, by the script that owns it, and
## both maps only read it. Before it each layer had its own HUD setter that replaced a whole list,
## and two owners of one list (jobs.gd's places and roundup_job.gd's pins) overwrote each other.
##
## A mark is `put` under an id "owner:key" with its layer, place (map x, z), colour and shape
## (MapIcons.POI_*); `put_all(owner, marks)` replaces everything one owner has in one call, which is
## what a script that rebuilds its list (the job places, the "?" marks) wants. `remove` and
## `clear(owner)` take marks away. A write never touches another owner's marks.
##
## Each mark may carry a `group` (the kind of thing it is: "kebab", "sloik", "lezak", "garage",
## "story"...; the onboarding plan's one map list shows one row per group) and, for the questline
## badges, `extra` ({"name", "blurb", "small"}: the label, the tap's line, a smaller "!").
##
## The rule table (RULES) says which layer each map shows in each context: FREE (driving round the
## city), QUEST (quest focus: something runs, main.gd `_quest_running`, hud.gd `quest_focus`) and
## AIR (flying, nothing running; quest focus wins over AIR). It holds today's behaviour; a new
## situation (a chase, an event day) is a column here, not edits in five scripts. Reach (how far from the car a layer's marks show on the
## minimap) and the full map's zoom rule stay with the drawing.
##
## Which layers the maps read from here so far (one layer per pull request, map-markers.md
## section 5 "Order of work"): JOB (street jobs' places, the round-up's pins), PLACE (the
## notebook's "?" marks), SERVICE (the garage), STORY (the questlines' starts, main.gd
## `_story_tick`), MAIN (the main line's star, MAIN_STAR, main.gd `_main_line_tick`), TARGET (the
## active target's pin, ACTIVE_TARGET, main.gd `_put_target`) and RIVAL (the final's start,
## rivals.gd; kept, not drawn: the main line's star stands there; the rivals' own marks join it for
## the one map list). The edge arrow on the driving screen stays hud.gd `set_target`: it is a point
## on the screen (the camera's business), fed from the same branch of `_show_target` as the mark.
##
## Pure state, no nodes: game/tools/check_map_markers.gd drives it (verify step `markers`).

## The layers, loudest first.
enum Layer {TARGET, MAIN, STORY, JOB, PLACE, SERVICE, INFO, RIVAL, UNKNOWN}
## The maps that read the registry.
enum View {MINIMAP, FULL_MAP}
## What the player is doing now (the activity director's context comes later, TD-1).
enum Context {FREE, QUEST, AIR}

## The main line's star (main.gd `_main_line_tick`): one MAIN mark under this id.
const MAIN_STAR := "main:star"
## The active target (main.gd `_put_target`, from `_show_target`'s chain): one TARGET mark under
## this id, the quest taken's pin on both maps; none while the main line's star stands for it.
const ACTIVE_TARGET := "target:active"

## Per layer: [minimap FREE, QUEST, AIR, full map FREE, QUEST, AIR]. Today's behaviour: quest
## focus hides the street jobs, the "?" marks, the garage and the questline badges on both maps;
## flying hides the questline badges (the job places hide themselves in the air, jobs.gd); the "?"
## marks are off the full map always (F 2026-11-08); the active target, the main line (its star
## dims in focus, the drawing's business) and the police show everywhere; the rivals' layer is
## kept for the one map list and drawn nowhere yet. UNKNOWN (2026-11-16, map_track.gd): the "?" of a
## First step not done whose place is not shown otherwise, group "unknown": on the full map only,
## in free driving and in the air (a tap tells a line and offers TRACK), never on the minimap.
const RULES := {
	Layer.TARGET: [true, true, true, true, true, true],
	Layer.MAIN: [true, true, true, true, true, true],
	Layer.STORY: [true, false, false, true, false, false],
	Layer.JOB: [true, false, true, true, false, true],
	Layer.PLACE: [true, false, true, false, false, false],
	Layer.SERVICE: [true, false, true, true, false, true],
	Layer.INFO: [true, true, true, true, true, true],
	Layer.RIVAL: [false, false, false, false, false, false],
	Layer.UNKNOWN: [false, false, false, true, false, true],
}

## id -> {"layer", "at", "colour", "shape", "group", "extra", "owner"}, in the order they were first put (the order
## the maps draw them in).
var _marks := {}
## Per layer, its marks as packed arrays for the drawing (rebuilt on the first read after a write).
var _views := {}
## How many writes each owner made (put_all, put, remove, clear), and in all: a check reads them,
## and a reader that caches can compare `version`.
var _writes := {}
var version := 0


## Whether `view` shows `layer` in `context` (the rule table).
static func shows(layer: int, view: int, context: int) -> bool:
	var row: Array = RULES.get(layer, [])
	var i := (0 if view == View.MINIMAP else 3) + context
	return i < row.size() and bool(row[i])


## The context for quest focus on or off (hud.gd's `quest_focus`) and flying (quest focus wins).
static func context_of(focus: bool, flying := false) -> int:
	return Context.QUEST if focus else (Context.AIR if flying else Context.FREE)


## One mark: `id` is "owner:key" (the owner is what comes before the first colon). A put that
## changes nothing is not a write (the active target is put every frame, main.gd `_put_target`), and
## a put drops only its layer's view (and the old one's, when the mark changed layer).
func put(id: String, layer: int, at: Vector2, colour: Color, shape := 0, group := "") -> void:
	var old: Dictionary = _marks.get(id, {})
	if not old.is_empty() and int(old["layer"]) == layer and old["at"] == at and old["colour"] == colour \
			and int(old["shape"]) == shape and str(old["group"]) == group and (old["extra"] as Dictionary).is_empty():
		return
	_marks[id] = {"layer": layer, "at": at, "colour": colour, "shape": shape, "group": group, "extra": {},
			"owner": _owner_of(id)}
	if not old.is_empty():
		_views.erase(int(old["layer"]))
	_views.erase(layer)
	_count(_owner_of(id))


## Everything `owner` shows, in one call: its old marks go, these come in this order. Each entry is
## {"layer", "at", "colour", "shape", "group", "extra" (each optional), "key" (optional; else its
## index)}.
func put_all(owner: String, marks: Array) -> void:
	_drop(owner)
	for i in marks.size():
		var m: Dictionary = marks[i]
		var id := "%s:%s" % [owner, str(m.get("key", i))]
		_marks[id] = {"layer": int(m["layer"]), "at": m["at"], "colour": m.get("colour", Color.WHITE),
				"shape": int(m.get("shape", 0)), "group": str(m.get("group", "")), "extra": m.get("extra", {}),
				"owner": owner}
	_changed(owner)


## The active target (main.gd `_put_target`, every frame): its one TARGET mark at `xz`, or none
## (`xz` INF).
func set_target(xz: Vector2, colour: Color) -> void:
	if xz == Vector2.INF:
		remove(ACTIVE_TARGET)
	else:
		put(ACTIVE_TARGET, Layer.TARGET, xz, colour, 0, "target")


## Where the active target is (INF: none).
func target() -> Vector2:
	return where(ACTIVE_TARGET)


## The active target's colour (white: none).
func target_colour() -> Color:
	return (_marks[ACTIVE_TARGET]["colour"] as Color) if _marks.has(ACTIVE_TARGET) else Color.WHITE


## Takes mark `id` away; removing a mark that isn't there is not a write.
func remove(id: String) -> void:
	if not _marks.has(id):
		return
	_views.erase(int(_marks[id]["layer"]))
	_marks.erase(id)
	_count(_owner_of(id))


## Takes all of `owner`'s marks away.
func clear(owner: String) -> void:
	_drop(owner)
	_changed(owner)


## Where mark `id` is (INF when it isn't there).
func where(id: String) -> Vector2:
	return (_marks[id]["at"] as Vector2) if _marks.has(id) else Vector2.INF


func has(id: String) -> bool:
	return _marks.has(id)


## How many marks (any owner) are in one of `groups`: all of them, or (`view` given) only those the
## rule table shows in `context` (the full map's filter counts, full_map.gd).
func count_group(groups: Array, view := -1, context := 0) -> int:
	var n := 0
	for id: String in _marks:
		var m: Dictionary = _marks[id]
		if (m["group"] as String) in groups and (view < 0 or shows(int(m["layer"]), view, context)):
			n += 1
	return n


## `owner`'s marks in order, each {"id", "layer", "at", "colour", "shape", "group", "extra"}.
func owned(owner: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in _marks:
		var m: Dictionary = _marks[id]
		if m["owner"] == owner:
			out.append({"id": id, "layer": m["layer"], "at": m["at"], "colour": m["colour"], "shape": m["shape"],
					"group": m["group"], "extra": m["extra"]})
	return out


## How many writes `owner` made so far.
func writes(owner: String) -> int:
	return int(_writes.get(owner, 0))


## One layer's marks for the drawing: {"at": PackedVector2Array, "colour": PackedColorArray,
## "shape": PackedInt32Array, "group": PackedStringArray, "extra": Array}, parallel, in the order
## put. Cached until the next write, so the
## minimap reads it every frame for nothing.
func marks_of(l: int) -> Dictionary:
	if _views.has(l):
		return _views[l]
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var shapes := PackedInt32Array()
	var groups := PackedStringArray()
	var extras: Array = []
	for id: String in _marks:
		var m: Dictionary = _marks[id]
		if int(m["layer"]) == l:
			pts.append(m["at"])
			cols.append(m["colour"])
			shapes.append(m["shape"])
			groups.append(m["group"])
			extras.append(m["extra"])
	var v := {"at": pts, "colour": cols, "shape": shapes, "group": groups, "extra": extras}
	_views[l] = v
	return v


## The marks of `l` that `view` shows in `context` (empty when the rule table hides the layer: one
## shared empty view, nothing made per frame; never write into it).
func shown(l: int, view: int, context: int) -> Dictionary:
	if shows(l, view, context):
		return marks_of(l)
	return _none


var _none := {"at": PackedVector2Array(), "colour": PackedColorArray(), "shape": PackedInt32Array(),
		"group": PackedStringArray(), "extra": []}


func _drop(owner: String) -> void:
	var gone: Array[String] = []
	for id: String in _marks:
		if _marks[id]["owner"] == owner:
			gone.append(id)
	for id in gone:
		_marks.erase(id)


func _changed(owner: String) -> void:
	_views.clear()
	_count(owner)


func _count(owner: String) -> void:
	_writes[owner] = writes(owner) + 1
	version += 1


static func _owner_of(id: String) -> String:
	var c := id.find(":")
	return id if c < 0 else id.substr(0, c)
