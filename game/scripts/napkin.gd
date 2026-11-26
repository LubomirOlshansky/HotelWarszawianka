extends Node
## The napkin, LISTA "zanim powiesz, że jesteś stąd" (F 2026-11-26; docs/design/story-structure.md,
## "The napkin"): Kebabulo's list of 14 places where Warsaw lives (not tourist sights: a beer on
## Plac Zbawiciela, a coffee rave, matcha, vinyl, pyzy, the steps at sunset, Karowa's hairpin...).
## Lines in data/napkin.json; each is ticked once, by being there at its hour.
##
## Thin on purpose: no trigger code of its own. A line is one or more egg-shaped dicts
## ({trigger, at}) run through egg_book.gd's static `step` (stop, pass; its `conditions`: hours,
## look), so the napkin and the eggs agree on what "stopped at a place at night" means. Its
## conditions are looser than the eggs on the same places (e02, e06, e14, e26): not duplicates.
##
## Opens after story chapter 1 (story_arc.gd `is_done("tajny")`: Kebabulo hands it over). Phase 1
## ticks the lines with `phase` 1 (wide hours); phase 2 lines wait for the buy and off-hours cards.
## A tick: wallet.gd `napkin` (line id -> the real date, yyyymmdd), +5 respect, a "LISTA n/14" note,
## the blip, and `ticked(id)` (play_stats.gd "discover", kind "napkin"). Checked at 2 Hz over at
## most ~20 points; nothing per frame but the timer.

signal ticked(id: String)

const EggBook := preload("res://scripts/egg_book.gd")
const StoryArc := preload("res://scripts/story_arc.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Lang := preload("res://scripts/lang.gd")
const Access := preload("res://scripts/access.gd")
const PATH := "res://data/napkin.json"
const CHECK_EVERY := 0.5
## The lines with a phase up to this one tick now.
const PHASE_NOW := 1
## Paper: the note's colour.
const COLOUR := Color("#f3e2b8")

## napkin.json's lines plus `n` (from 1) and `spots` (Array of egg-shaped dicts: {trigger, at}).
var lines: Array[Dictionary] = []
var by_id := {}
var respect := 5
var wallet: Node
var hud: CanvasLayer
## main.gd `_egg_state` (pos, kmh, flying, hour, look, sun, away...).
var probe: Callable
var blip: Callable
var spent_usec := 0
## A spot's memory between checks ("id#k" -> egg_book.gd's mem).
var _mem := {}
var _t := 0.0


## Reads napkin.json (no map). False if it is missing or broken.
func load_lines() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary:
		push_error("napkin: %s does not parse" % PATH)
		return false
	respect = int(d.get("respect", 5))
	lines.clear()
	by_id.clear()
	for l: Dictionary in d.get("lines", []):
		var line := l.duplicate(true)
		line["n"] = lines.size() + 1
		line["spots"] = []
		by_id[str(l["id"])] = lines.size()
		lines.append(line)
	return true


## Puts each line's points on the map: `places` (notebook.gd: id -> Vector2), `origin` (the map's
## [lat0, lon0]). A line with no point found never ticks (and says so).
func setup(places: Dictionary, origin: Array) -> void:
	if lines.is_empty() and not load_lines():
		return
	var none := PackedStringArray()
	for line in lines:
		var pts := points(line, places, origin)
		var spots: Array = []
		for p in pts:
			spots.append({"trigger": line["trigger"], "at": p})
		line["spots"] = spots
		if spots.is_empty():
			none.append(str(line["id"]))
	print("napkin: %d lines (%d now), %d with no place%s" % [lines.size(), live_count(), none.size(),
			(": " + ", ".join(none)) if not none.is_empty() else ""])


## A line's points: its notebook places, its [lat, lon] points and its map points.
static func points(line: Dictionary, places: Dictionary, origin: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for id: Variant in line.get("places", []):
		var at: Variant = places.get(str(id), Vector2.INF)
		if at is Vector2 and at != Vector2.INF:
			out.append(at)
	for ll: Variant in line.get("latlon", []):
		out.append(Notebook.project(origin, float(ll[0]), float(ll[1])))
	for xz: Variant in line.get("xz", []):
		out.append(Vector2(float(xz[0]), float(xz[1])))
	return out


## Kebabulo has handed the napkin over: story chapter 1 is done.
func is_open() -> bool:
	return wallet != null and StoryArc.is_done("tajny", wallet.intro, wallet.jobs)


static func is_live(line: Dictionary) -> bool:
	return int(line.get("phase", 1)) <= PHASE_NOW


func live_count() -> int:
	return lines.filter(func(l: Dictionary) -> bool: return is_live(l)).size()


func is_done(id: String) -> bool:
	return wallet != null and wallet.napkin.has(id)


func done_count() -> int:
	var n := 0
	for line in lines:
		n += int(is_done(str(line["id"])))
	return n


func _process(dt: float) -> void:
	if lines.is_empty() or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	var step_s := _t
	_t = 0.0
	if not is_open():
		return
	var t0 := Time.get_ticks_usec()
	tick(probe.call(), step_s)
	spent_usec += Time.get_ticks_usec() - t0


## One check on `s` (the probe's state), `dt` seconds after the last: ticks every line met.
func tick(s: Dictionary, dt: float) -> void:
	if bool(s.get("away", false)):
		return
	for line in lines:
		var id := str(line["id"])
		if not is_live(line) or is_done(id):
			continue
		if met(line, s, _mem, dt):
			record(id)


## Line `line` met in state `s`: any of its spots fires egg_book.gd's `step` (`mem`: "id#k" ->
## that spot's memory).
static func met(line: Dictionary, s: Dictionary, mem: Dictionary, dt: float) -> bool:
	var spots: Array = line.get("spots", [])
	for k in spots.size():
		var key := "%s#%d" % [line["id"], k]
		if not mem.has(key):
			mem[key] = {}
		if EggBook.step(spots[k], s, mem[key], dt):
			return true
	return false


## Line `id` ticked for the first time: the save, the respect, the note, the blip. False if it
## was ticked already (or isn't a line).
func record(id: String, date := 0) -> bool:
	if wallet == null or not by_id.has(id) or is_done(id):
		return false
	var line := lines[by_id[id]]
	wallet.napkin[id] = date if date > 0 else EggBook.today()
	if respect > 0:
		wallet.pay(0, respect)  # pay() saves
	else:
		wallet.save()
	var title: Array = line["title"]
	var note: Array = line.get("note", ["", ""])
	print("napkin: ticked %s %s (%d/%d): +%d respect" % [id, title[0], done_count(), lines.size(), respect])
	if hud != null:
		hud.show_note(Lang.pick("LISTA %d/%d", "THE LIST %d/%d") % [done_count(), lines.size()],
				"%s\n%s · %s" % [Lang.pick(title[0], title[1]), Lang.pick(note[0], note[1]),
				Lang.pick("+%d szacunku", "+%d respect") % respect], COLOUR)
	if blip.is_valid():
		blip.call()
	Access.buzz(30, 0.4)
	ticked.emit(id)
	return true
