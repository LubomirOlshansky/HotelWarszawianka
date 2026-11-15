extends SceneTree
## The map marker registry (map_markers.gd, tech-debt TD-13, docs/architecture/map-markers.md
## section 5), on its own and with the real hud.gd and full_map.gd (no map, no game). Checks that:
## - the rule table holds today's behaviour: quest focus hides the street jobs, the "?" marks, the
##   garage and the questline badges on both maps; the "?" marks never show on the full map; the
##   target, the main line and the police show everywhere;
## - put, put_all, remove and clear: one owner's write never touches another's marks (jobs.gd's
##   places and roundup_job.gd's pins both used to write the one list `set_minimap_pois`, the last
##   writer wiping the other's); put_all keeps the order it was given; a layer's arrays are cached
##   until the next write;
## - the minimap paints what the registry holds and the rule table allows: a job place, a garage and
##   a "?" each add triangles to the overlay's one batch in free drive, none in quest focus; a mark
##   of the final's start (MAIN, kept, not drawn) adds none;
## - the full map opened from the HUD reads the same registry (its job places and garage come from
##   it, not from a copy made on open).
##   godot --headless --path game --script res://tools/check_map_markers.gd

const MapMarkers := preload("res://scripts/map_markers.gd")
const MapIcons := preload("res://scripts/map_icons.gd")
const Hud := preload("res://scripts/hud.gd")

const L := MapMarkers.Layer
const MINI := MapMarkers.View.MINIMAP
const FULL := MapMarkers.View.FULL_MAP
const FREE := MapMarkers.Context.FREE
const QUEST := MapMarkers.Context.QUEST

var _problems := 0


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
	if _problems == 0:
		print("check_map_markers: OK")
		quit(0)
	else:
		print("check_map_markers: %d problems" % _problems)
		quit(1)


## Today's behaviour, written out the way hud.gd and full_map.gd decided it before the registry
## (quest_focus tests in each drawing loop): every layer, both maps, both contexts.
func _rules() -> void:
	var want := {
		L.TARGET: [true, true, true, true],
		L.MAIN: [true, true, true, true],
		L.STORY: [true, false, true, false],
		L.JOB: [true, false, true, false],
		L.PLACE: [true, false, false, false],
		L.SERVICE: [true, false, true, false],
		L.INFO: [true, true, true, true],
	}
	_expect(MapMarkers.RULES.size() == L.size(), "a rule row for every layer (%d of %d)" % [MapMarkers.RULES.size(), L.size()])
	for layer: int in want:
		var row: Array = want[layer]
		var got := [MapMarkers.shows(layer, MINI, FREE), MapMarkers.shows(layer, MINI, QUEST),
				MapMarkers.shows(layer, FULL, FREE), MapMarkers.shows(layer, FULL, QUEST)]
		_expect(got == row, "layer %s: %s (want %s)" % [L.keys()[layer], got, row])
	_expect(MapMarkers.context_of(true) == QUEST and MapMarkers.context_of(false) == FREE, "context_of")


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
	# The rule table on the read.
	_expect(m.shown(L.JOB, MINI, QUEST)["at"].is_empty() and m.shown(L.JOB, MINI, FREE)["at"].size() == 1, "shown() follows the rules")
	var v := m.version
	m.put_all("notebook", [])
	_expect(m.version == v + 1, "every write moves the version")


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
	markers.put("rivals:final", L.MAIN, Vector2(10, 10), Color.GOLD)
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
	if fm != null:
		fm.call("close")
	vp.queue_free()
	await process_frame


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
