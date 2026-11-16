extends SceneTree
## The map marker registry (map_markers.gd, tech-debt TD-13, docs/architecture/map-markers.md
## section 5), on its own and with the real hud.gd and full_map.gd (no map, no game). Checks that:
## - the rule table holds today's behaviour: quest focus hides the street jobs, the "?" marks, the
##   garage and the questline badges on both maps; flying hides the questline badges; the "?" marks
##   never show on the full map; the target, the main line and the police show everywhere; the
##   rivals' layer shows nowhere yet;
## - put, put_all, remove and clear: one owner's write never touches another's marks (jobs.gd's
##   places and roundup_job.gd's pins both used to write the one list `set_minimap_pois`, the last
##   writer wiping the other's); put_all keeps the order it was given; a layer's arrays are cached
##   until the next write;
## - the minimap paints what the registry holds and the rule table allows: a job place, a garage and
##   a "?" each add triangles to the overlay's one batch in free drive, none in quest focus; a
##   questline badge adds them in free drive, none in focus and none in the air; the main line's
##   star shows in focus too; a mark of the final's start (RIVAL, kept, not drawn) adds none;
## - each mark keeps its group and extra (the questline's name, line and "small"), and the game's
##   own builders give them: the questlines' starts (story_quests.gd `map_marks`) and the main
##   line's star (main_line.gd `map_marks`, id MAIN_STAR);
## - the full map opened from the HUD reads the same registry (its job places and garage come from
##   it, not from a copy made on open), and its questline labels and tap lines come from the marks.
##   godot --headless --path game --script res://tools/check_map_markers.gd

const MapMarkers := preload("res://scripts/map_markers.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Hud := preload("res://scripts/hud.gd")
const StoryQuests := preload("res://scripts/story_quests.gd")
const MainLine := preload("res://scripts/main_line.gd")

const L := MapMarkers.Layer
const MINI := MapMarkers.View.MINIMAP
const FULL := MapMarkers.View.FULL_MAP
const FREE := MapMarkers.Context.FREE
const QUEST := MapMarkers.Context.QUEST
const AIR := MapMarkers.Context.AIR

var _problems := 0
## The HUD part ran to its end (a script error in hud.gd or full_map.gd stops it half way: not OK).
var _hud_done := false


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run()


func _run() -> void:
	_rules()
	_registry()
	await _hud()
	_expect(_hud_done, "the HUD part ran to its end (a script error in hud.gd or full_map.gd?)")
	if _problems == 0:
		print("check_map_markers: OK")
		quit(0)
	else:
		print("check_map_markers: %d problems" % _problems)
		quit(1)


## Today's behaviour, written out the way hud.gd and full_map.gd decided it before the registry
## (quest_focus tests in each drawing loop, main.gd's `focus or flying` for the questlines): every
## layer, both maps, FREE, QUEST, AIR.
func _rules() -> void:
	var want := {
		L.TARGET: [true, true, true, true, true, true],
		L.MAIN: [true, true, true, true, true, true],
		L.STORY: [true, false, false, true, false, false],
		L.JOB: [true, false, true, true, false, true],
		L.PLACE: [true, false, true, false, false, false],
		L.SERVICE: [true, false, true, true, false, true],
		L.INFO: [true, true, true, true, true, true],
		L.RIVAL: [false, false, false, false, false, false],
		L.UNKNOWN: [false, false, false, true, false, true],  # 2026-11-16: the "?" of a First step not done: full map only
	}
	_expect(MapMarkers.RULES.size() == L.size(), "a rule row for every layer (%d of %d)" % [MapMarkers.RULES.size(), L.size()])
	for layer: int in want:
		var row: Array = want[layer]
		var got := [MapMarkers.shows(layer, MINI, FREE), MapMarkers.shows(layer, MINI, QUEST), MapMarkers.shows(layer, MINI, AIR),
				MapMarkers.shows(layer, FULL, FREE), MapMarkers.shows(layer, FULL, QUEST), MapMarkers.shows(layer, FULL, AIR)]
		_expect(got == row, "layer %s: %s (want %s)" % [L.keys()[layer], got, row])
	_expect(MapMarkers.context_of(true) == QUEST and MapMarkers.context_of(false) == FREE, "context_of")
	_expect(MapMarkers.context_of(false, true) == AIR and MapMarkers.context_of(true, true) == QUEST, "context_of: flying, focus wins")


func _registry() -> void:
	var m := MapMarkers.new()
	# Two owners on one layer (the bug the setters had).
	m.put_all("jobs", [{"layer": L.JOB, "at": Vector2(1, 1), "colour": Color.RED, "shape": MapIcons.POI_KEBAB},
			{"layer": L.JOB, "at": Vector2(2, 2), "colour": Color.GREEN, "shape": MapIcons.POI_STATION}])
	m.put_all("roundup", [{"layer": L.JOB, "at": Vector2(3, 3), "colour": Color.BLUE, "shape": MapIcons.POI_SCOOTER}])
	var job: Dictionary = m.marks_of(L.JOB)
	_expect(job["at"] == PackedVector2Array([Vector2(1, 1), Vector2(2, 2), Vector2(3, 3)]), "two owners: both lists, in order (%s)" % job["at"])
	_expect(job["shape"] == PackedInt32Array([MapIcons.POI_KEBAB, MapIcons.POI_STATION, MapIcons.POI_SCOOTER]), "the shapes kept")
	_expect(job["colour"] == PackedColorArray([Color.RED, Color.GREEN, Color.BLUE]), "the colours kept")
	_expect(m.marks_of(L.JOB) == job and is_same(m.marks_of(L.JOB), job), "a layer's arrays are cached until a write")
	m.clear("roundup")
	_expect(m.marks_of(L.JOB)["at"] == PackedVector2Array([Vector2(1, 1), Vector2(2, 2)]), "clear(roundup) leaves the job places")
	m.put_all("jobs", [{"layer": L.JOB, "at": Vector2(5, 5)}])
	_expect(m.marks_of(L.JOB)["at"] == PackedVector2Array([Vector2(5, 5)]), "put_all replaces that owner's marks")
	_expect(m.marks_of(L.JOB)["shape"] == PackedInt32Array([MapIcons.POI_SQUARE]), "no shape given: the square")
	_expect(m.writes("jobs") == 2 and m.writes("roundup") == 2, "writes counted per owner (%d, %d)" % [m.writes("jobs"), m.writes("roundup")])
	# One mark by id.
	m.put("garage:workshop", L.SERVICE, Vector2(9, 9), Color.CYAN)
	_expect(m.has("garage:workshop") and m.where("garage:workshop") == Vector2(9, 9), "put and where")
	_expect(m.owned("garage").size() == 1 and m.owned("garage")[0]["layer"] == L.SERVICE, "owned(garage)")
	m.put("garage:workshop", L.SERVICE, Vector2(8, 8), Color.CYAN)
	_expect(m.marks_of(L.SERVICE)["at"] == PackedVector2Array([Vector2(8, 8)]), "put again moves it, no second mark")
	m.remove("garage:workshop")
	_expect(not m.has("garage:workshop") and m.where("garage:workshop") == Vector2.INF and m.marks_of(L.SERVICE)["at"].is_empty(), "remove")
	m.remove("garage:never")
	_expect(m.marks_of(L.JOB)["at"].size() == 1, "removing a mark that isn't there changes nothing")
	# The active target (main.gd `_put_target`) is put every frame: only a change is a write, and a
	# put drops only its own layer's view.
	var w0 := m.version
	m.remove(MapMarkers.ACTIVE_TARGET)
	_expect(m.version == w0, "removing a mark that isn't there is not a write")
	var job_view := m.marks_of(L.JOB)
	m.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(3, 4), Color.RED, 0, "target")
	_expect(m.version == w0 + 1 and m.where(MapMarkers.ACTIVE_TARGET) == Vector2(3, 4) and m.owned("target").size() == 1, "the active target is one TARGET mark")
	_expect(is_same(m.marks_of(L.JOB), job_view), "a put keeps the other layers' views (nothing rebuilt per frame)")
	var tv := m.marks_of(L.TARGET)
	m.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(3, 4), Color.RED, 0, "target")
	_expect(m.version == w0 + 1 and is_same(m.marks_of(L.TARGET), tv), "the same put again is not a write")
	m.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(3, 5), Color.RED, 0, "target")
	_expect(m.version == w0 + 2 and m.marks_of(L.TARGET)["at"] == PackedVector2Array([Vector2(3, 5)]), "a moved target is a write (a rival's pin follows them)")
	m.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(3, 5), Color.BLUE, 0, "target")
	_expect(m.marks_of(L.TARGET)["colour"] == PackedColorArray([Color.BLUE]), "a new colour is a write")
	m.put("target:moved", L.TARGET, Vector2(1, 1), Color.RED)
	m.put("target:moved", L.SERVICE, Vector2(1, 1), Color.RED)
	_expect(not m.marks_of(L.TARGET)["at"].has(Vector2(1, 1)) and m.marks_of(L.SERVICE)["at"].has(Vector2(1, 1)), "a mark that changes layer leaves the old layer's view")
	m.remove("target:moved")
	m.remove(MapMarkers.ACTIVE_TARGET)
	_expect(m.marks_of(L.TARGET)["at"].is_empty() and m.version == w0 + 7, "removing the target is a write, and it is gone")
	m.set_target(Vector2(6, 6), Color.RED)
	_expect(m.where(MapMarkers.ACTIVE_TARGET) == Vector2(6, 6) and m.marks_of(L.TARGET)["group"] == PackedStringArray(["target"]), "set_target puts the one TARGET mark")
	m.set_target(Vector2.INF, Color.RED)
	_expect(not m.has(MapMarkers.ACTIVE_TARGET) and m.target() == Vector2.INF, "set_target(INF): no target")
	_expect(MapMarkers.shows(L.TARGET, MINI, QUEST) and MapMarkers.shows(L.TARGET, MINI, AIR) and MapMarkers.shows(L.TARGET, FULL, QUEST),
			"the active target shows on both maps in every context")
	# The rule table on the read.
	_expect(m.shown(L.JOB, MINI, QUEST)["at"].is_empty() and m.shown(L.JOB, MINI, FREE)["at"].size() == 1, "shown() follows the rules")
	var v := m.version
	m.put_all("notebook", [])
	_expect(m.version == v + 1, "every write moves the version")
	# Groups and extras (the one map list: a row per group).
	m.put_all("jobs", [{"layer": L.JOB, "at": Vector2(1, 1), "group": "kebab"}, {"layer": L.JOB, "at": Vector2(2, 2), "group": "sloik"}])
	m.put("garage:workshop", L.SERVICE, Vector2(9, 9), Color.CYAN, 0, "garage")
	_expect(m.marks_of(L.JOB)["group"] == PackedStringArray(["kebab", "sloik"]), "groups kept in order (%s)" % m.marks_of(L.JOB)["group"])
	_expect(m.owned("garage")[0]["group"] == "garage", "put's group")
	m.put_all("unknown", [{"layer": L.UNKNOWN, "at": Vector2(4, 4), "group": "unknown"}])
	_expect(m.count_group(["unknown"]) == 1 and m.count_group(["unknown"], FULL, FREE) == 1 and m.count_group(["unknown"], FULL, QUEST) == 0
			and m.count_group(["unknown"], MINI, FREE) == 0 and m.count_group(["kebab", "sloik"]) == 2,
			"count_group: all, or only what the rule table shows (the full map's filter counts)")
	m.clear("unknown")
	_expect(m.shown(L.RIVAL, MINI, FREE)["at"].is_empty() and is_same(m.shown(L.RIVAL, MINI, FREE), m.shown(L.STORY, FULL, QUEST)),
			"a hidden layer reads one shared empty view (nothing made per frame)")
	# The game's own builders.
	var defs := [{"id": "rave", "pl": "Tajny rejw", "en": "Secret rave", "at": Vector2(5, 6), "colour": Color.PURPLE,
			"blurb": ["Bas pod mostem", "Bass under the bridge"], "small": true},
			{"id": "closed", "pl": "Zamknięte", "en": "Closed", "at": Vector2.INF}]
	m.put_all("stories", StoryQuests.map_marks(defs))
	var st: Dictionary = m.marks_of(L.STORY)
	var ex: Dictionary = (st["extra"] as Array)[0] if not (st["extra"] as Array).is_empty() else {}
	_expect(st["at"] == PackedVector2Array([Vector2(5, 6)]) and m.has("stories:rave"), "story_quests.gd map_marks: one start per open questline, id stories:<id>")
	_expect(st["group"] == PackedStringArray(["story"]) and bool(ex.get("small", false)) and str(ex.get("name", "")) in ["Tajny rejw", "Secret rave"]
			and str(ex.get("blurb", "")) in ["Bas pod mostem", "Bass under the bridge"], "the start's group, name, line and small (%s)" % ex)
	m.put_all("main", MainLine.map_marks(Vector2(7, 8)))
	_expect(m.where(MapMarkers.MAIN_STAR) == Vector2(7, 8) and m.marks_of(L.MAIN)["colour"][0] == MainLine.COLOUR, "main_line.gd map_marks: the star at MAIN_STAR")
	m.put_all("main", MainLine.map_marks(Vector2.INF))
	_expect(not m.has(MapMarkers.MAIN_STAR), "a step with no place: no star")


func _hud() -> void:
	await process_frame
	var vp := SubViewport.new()
	vp.size = Vector2i(2532, 1170)
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	await process_frame
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	await process_frame
	await process_frame
	var markers: MapMarkers = hud.markers
	var base := await _tris(hud)
	var cases := [
		["a job place", func() -> void: markers.put_all("jobs", [{"layer": L.JOB, "at": Vector2(60, 0), "colour": Color.ORANGE, "shape": MapIcons.POI_KEBAB}]),
				func() -> void: markers.clear("jobs")],
		["the garage", func() -> void: markers.put("garage:workshop", L.SERVICE, Vector2(0, 80), Color("#5aa0ff")),
				func() -> void: markers.remove("garage:workshop")],
		["a \"?\"", func() -> void: markers.put_all("notebook", [{"layer": L.PLACE, "at": Vector2(-40, 30)}]),
				func() -> void: markers.clear("notebook")],
	]
	for c: Array in cases:
		(c[1] as Callable).call()
		hud.quest_focus = false
		var free := await _tris(hud)
		hud.quest_focus = true
		var focus := await _tris(hud)
		hud.quest_focus = false
		_expect(free > base, "minimap, free drive: %s adds triangles (%d over %d)" % [c[0], free, base])
		var focus_base := await _tris_focus_base(hud)
		_expect(focus == focus_base, "minimap, quest focus: %s hidden (%d)" % [c[0], focus])
		print("  %s: %d triangles free, %d in focus (base %d, focus base %d)" % [c[0], free, focus, base, focus_base])
		(c[2] as Callable).call()
		var after := await _tris(hud)
		_expect(after == base, "minimap: %s gone after its owner took it away" % c[0])
	# A questline's start: shown in free drive, hidden in focus and in the air.
	markers.put_all("stories", [{"layer": L.STORY, "at": Vector2(30, -30), "colour": Color.PURPLE, "group": "story",
			"extra": {"name": "Secret rave", "blurb": "Bass", "small": false}}])
	var st_free := await _tris(hud)
	hud.flying = true
	var st_air := await _tris(hud)
	markers.clear("stories")
	var air_base := await _tris(hud)
	hud.flying = false
	markers.put_all("stories", [{"layer": L.STORY, "at": Vector2(30, -30), "colour": Color.PURPLE, "group": "story"}])
	hud.quest_focus = true
	var st_focus := await _tris(hud)
	hud.quest_focus = false
	var focus_base2 := await _tris_focus_base(hud)
	_expect(st_free > base and st_air == air_base and st_focus == focus_base2,
			"minimap: the questline badge in free drive (%d over %d), not in the air (%d, %d), not in focus (%d, %d)" % [st_free, base, st_air, air_base, st_focus, focus_base2])
	markers.clear("stories")
	# The main line's star: shown in free drive and in focus (dimmed).
	markers.put_all("main", MainLine.map_marks(Vector2(-60, 10)))
	var star_free := await _tris(hud)
	hud.quest_focus = true
	var star_focus := await _tris(hud)
	hud.quest_focus = false
	_expect(star_free > base and star_focus > focus_base2, "minimap: the main star in free drive (%d) and in focus (%d over %d)" % [star_free, star_focus, focus_base2])
	markers.clear("main")
	# The active target: drawn in free drive, in focus and in the air; gone with its mark.
	markers.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(50, -20), Color.ORANGE, 0, "target")
	var tg_free := await _tris(hud)
	hud.quest_focus = true
	var tg_focus := await _tris(hud)
	hud.quest_focus = false
	hud.flying = true
	var tg_air := await _tris(hud)
	markers.remove(MapMarkers.ACTIVE_TARGET)
	var tg_air_base := await _tris(hud)
	hud.flying = false
	var tg_gone := await _tris(hud)
	_expect(tg_free > base and tg_focus > focus_base2 and tg_air > tg_air_base and tg_gone == base,
			"minimap: the active target in free drive (%d over %d), in focus (%d over %d), in the air (%d over %d), gone with its mark (%d)"
			% [tg_free, base, tg_focus, focus_base2, tg_air, tg_air_base, tg_gone])
	# Far away it waits on the rim (pinned, not dropped).
	markers.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(5000, 0), Color.ORANGE, 0, "target")
	var tg_far := await _tris(hud)
	markers.remove(MapMarkers.ACTIVE_TARGET)
	_expect(tg_far == tg_free, "minimap: a far target waits on the rim (%d, as near %d)" % [tg_far, tg_free])
	markers.put("rivals:final", L.RIVAL, Vector2(10, 10), Color.GOLD, 0, "final")
	var with_final := await _tris(hud)
	_expect(with_final == base and base > 0, "the final's start mark is kept, not drawn (the main line's star stands there)")
	markers.remove("rivals:final")
	# The full map reads the same registry.
	markers.put_all("jobs", [{"layer": L.JOB, "at": Vector2(60, 0), "colour": Color.ORANGE, "shape": MapIcons.POI_KEBAB}])
	markers.put("garage:workshop", L.SERVICE, Vector2(0, 80), Color("#5aa0ff"))
	hud.open_full_map(Vector2(10.0, 20.0), 0.5, PackedVector2Array())
	await process_frame
	var fm: Control = hud.full_map
	_expect(fm != null and is_same(fm.get("markers"), markers), "the full map reads the HUD's registry")
	markers.put_all("jobs", [{"layer": L.JOB, "at": Vector2(70, 0), "colour": Color.ORANGE}])
	_expect(fm != null and (fm.get("markers") as MapMarkers).marks_of(L.JOB)["at"] == PackedVector2Array([Vector2(70, 0)]),
			"a write while the map is open is what it draws next (no copy)")
	# Its questline starts: the labels' names and the tap's line come from the marks; none in focus.
	markers.put_all("stories", [{"layer": L.STORY, "at": Vector2(30, -30), "colour": Color.PURPLE, "group": "story",
			"extra": {"name": "Secret rave", "blurb": "Bass", "small": false}}])
	if fm != null:
		var sv: Dictionary = fm.call("_stories")
		_expect((sv["at"] as PackedVector2Array).size() == 1 and str((sv["extra"][0] as Dictionary)["name"]) == "Secret rave", "the full map's questline label")
		fm.set("focus", true)
		_expect((fm.call("_stories")["at"] as PackedVector2Array).is_empty(), "the full map in focus: no starts")
		fm.set("focus", false)
		fm.set("flying", true)
		_expect((fm.call("_stories")["at"] as PackedVector2Array).is_empty(), "the full map in the air: no starts")
		fm.set("flying", false)
		markers.put_all("main", MainLine.map_marks(Vector2(-60, 10)))
		_expect(fm.call("_main_at") == Vector2(-60, 10), "the full map's star from the registry")
		# The active target's pin and dotted line come from the registry's TARGET mark.
		markers.clear("main")
		var fm_base := await _tris_full(hud, fm)
		markers.put(MapMarkers.ACTIVE_TARGET, L.TARGET, Vector2(40, 30), Color.ORANGE, 0, "target")
		var fm_target := await _tris_full(hud, fm)
		# Step 4: with a road route on the HUD that ends at the target, the dots follow it (a detour
		# north is longer than the straight line, so more dots); one that ends elsewhere is not used.
		hud.set_minimap_route(PackedVector2Array([Vector2(10, 20), Vector2(10, -120), Vector2(40, -120), Vector2(40, 30)]), Color.ORANGE, "target")
		var fm_road := await _tris_full(hud, fm)
		hud.set_minimap_route(PackedVector2Array([Vector2(10, 20), Vector2(-300, 20)]), Color.ORANGE, "jobs")
		var fm_elsewhere := await _tris_full(hud, fm)
		hud.clear_minimap_route("jobs")
		_expect(fm_road > fm_target and fm_elsewhere == fm_target,
				"the full map's dots follow a road route that ends at the target (%d over %d straight), not one that ends elsewhere (%d)" % [fm_road, fm_target, fm_elsewhere])
		markers.remove(MapMarkers.ACTIVE_TARGET)
		var fm_gone := await _tris_full(hud, fm)
		_expect(fm_base >= 0 and fm_target > fm_base and fm_gone == fm_base,
				"the full map's active pin from the registry (%d over %d, %d after)" % [fm_target, fm_base, fm_gone])
	hud.set_quest_focus(true)
	_expect(fm == null or bool(fm.get("focus")), "focus while the map is open reaches it")
	hud.set_quest_focus(false)
	if fm != null:
		fm.call("close")
	vp.queue_free()
	await process_frame
	_hud_done = true


## The overlay's triangle count for one paint of the minimap now (read in the overlay's own draw,
## right after hud.gd's painter, which is connected first).
func _tris(hud: CanvasLayer) -> int:
	var o: Control = hud.get("_mini_overlay")
	var got := [-1]
	var read := func() -> void: got[0] = (hud.get("_tri_pts") as PackedVector2Array).size()
	o.draw.connect(read)
	o.queue_redraw()
	await process_frame
	await process_frame
	o.draw.disconnect(read)
	return got[0]


## The full map's triangle count for one paint (its overlay draws in the HUD's batch).
func _tris_full(hud: CanvasLayer, fm: Control) -> int:
	var o: Control = fm.get("_overlay")
	var got := [-1]
	var read := func() -> void: got[0] = (hud.get("_tri_pts") as PackedVector2Array).size()
	o.draw.connect(read)
	o.queue_redraw()
	await process_frame
	await process_frame
	o.draw.disconnect(read)
	return got[0]


## The count in quest focus with no marks at all (the main star dims in focus, so focus has its
## own base).
func _tris_focus_base(hud: CanvasLayer) -> int:
	var keep := (hud.markers as MapMarkers)
	hud.markers = MapMarkers.new()
	hud.quest_focus = true
	var n := await _tris(hud)
	hud.quest_focus = false
	hud.markers = keep
	return n
