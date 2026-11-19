extends SceneTree
## The place scripts and their owner (pipeline review item 7, 2026-11-13): builds `Places.TABLE`
## through places.gd itself on the mesh check's flat stub map (tools/mesh_probe.gd, from the
## committed map/centrum.json only, so it runs in CI) and fails when
##   - a row has no `tris` budget, a place builds more triangles than its budget, or builds nothing;
##   - a place adds more draw items of its own (`Place.part` meshes) than its row's `own`, or makes
##     a MeshInstance3D without `pour` or `part`;
##   - the poured dressing ends as more than one mesh per (sector, shadow setting), or the merge
##     loses or adds a triangle;
##   - a script in game/scripts extends place.gd and has no row, or a row's script does not;
##   - main.gd names a table script (a hand hook came back);
##   - `--solo=KEY` builds a place that does not name the site;
##   - a mesh defect of the mesh check's kinds (ZFIGHT, DEGENERATE, BADNORMAL, FLOAT) is found
##     beyond the KNOWN ratchet below (per place and kind; below it the check says so: lower it).
##   - a place builds other triangles or parts on the phone's map (Fakes.PhoneMap: only the prebuilt
##     city's index, as the iPhone has it) than on the whole map: it reads something the phone's city
##     does not keep, as the Spire's lights and Tamka's bollards did until 2026-11-15 (PHONE_SHORT
##     names a known gap with its reason);
## Prints a line per place, then `check_place_scripts: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_place_scripts.gd

const Places := preload("res://scripts/places.gd")
const MeshProbe := preload("res://tools/mesh_probe.gd")
const Fakes := preload("res://tools/fakes.gd")
const PLACE_BASE := "extends \"res://scripts/place.gd\""
## The defect pass cuts a mesh of more than TILE_AT triangles into TILE m tiles (see _tiles).
const TILE := 48.0
const TILE_AT := 4000
## Known defects per place and kind (counts on the flat stub map, mesh by mesh): the defects that
## exist today are a ratchet. The check fails when a count goes ABOVE it and says so when it went
## below. Measured 2026-11-13.
const KNOWN := {
	"first_scene": {"zfight": 837, "float": 15},
	"skwer_zlota": {"zfight": 168},
	"centralny_ramp": {"zfight": 68, "float": 133},
	"patelnia": {"zfight": 317, "float": 634},
	"plac_pieciu_rogow": {"zfight": 470, "degenerate": 24, "float": 5},
	"tarasy_screen": {"float": 1},
	"spire_motion": {"float": 271},  # 2026-11-15: the night lines and LED band lie on the tower's glass (landmarks.gd), not on this mesh
	"street_details": {"zfight": 7163, "float": 7},
	"ratusz_hub": {"zfight": 271, "degenerate": 8, "float": 382},
	"park_details": {"zfight": 2357, "float": 3602},
	"tamka": {"zfight": 364, "float": 20},
	"towarowa22_life": {"zfight": 1206, "float": 1510},  # 2026-11-16: props.gd's cafe sets, benches and people (shared pieces: boxes that meet and stand on their feet) on the flat stub
	"bulwar_food": {"zfight": 12},  # 2026-11-19: the food truck's hidden chassis and floor boxes overlap (under the body, not visible)
	"light_garden": {"float": 3},  # the dandelion clocks' bulb tips on their spikes (2026-11-15; 7 before the flower rebuild)
	"trasa_wz": {"zfight": 249, "float": 128},  # 2026-11-15: the walls, rails and stairs keep set heights (walls and steps are sector-only data) and the kiosk front hangs on the map's kiosk, so on the flat stub the pilaster feet meet and the rails and the front stand off the ground
}

## Places allowed to differ on the phone's map: the triangles they build there less those on the whole map,
## and why. Any other difference fails, and so does this one when the count changes.
const PHONE_SHORT := {
	# One street name plate more at Zajęcza and Dynasy: plate_spots keeps a plate clear of the houses, and
	# the houses (`buildings`) are sector-only, so both streamed cities place it against no house (BACKLOG).
	"tamka": [192, "the plates' house test has no houses on the streamed cities"],
}

var problems: Array[String] = []
var notes: Array[String] = []


## Stands in for places.gd while the defect pass builds each place alone: keeps the poured meshes.
class Collector extends Node:
	var meshes: Array[Mesh] = []

	func take(mesh: ArrayMesh, _shadows: bool) -> void:
		meshes.append(mesh)


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_place_scripts: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var ctx := {"data": data, "dialogue": null, "clock": Callable(), "focus": Callable(),
			"vehicle": Callable(), "logs": {}}
	_table_and_scripts()
	_main_has_no_hooks()
	var map := Fakes.BuilderMap.new()
	map.data = data
	var places := Places.new()
	places.name = "Places"
	_build_and_count(places, map, ctx)
	_phone(data, places.facts)
	_solo(map, ctx)
	_defects(map, ctx, MeshProbe.new(data))
	map.free()
	places.free()
	for n in notes:
		print("  note: " + n)
	if problems.is_empty():
		print("check_place_scripts: OK (%d places)" % Places.TABLE.size())
		quit(0)
	else:
		print("check_place_scripts: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


## Every row has a budget and a script that extends place.gd; every script that extends place.gd
## has a row.
func _table_and_scripts() -> void:
	var rows := {}
	for row: Dictionary in Places.TABLE:
		var key := str(row.get("key", ""))
		rows[str(row.get("script", ""))] = key
		if int(row.get("tris", 0)) <= 0:
			problems.append("%s: no tris budget in Places.TABLE" % key)
		if not row.has("own"):
			problems.append("%s: no own count in Places.TABLE" % key)
		if not FileAccess.file_exists(str(row.get("script", ""))):
			problems.append("%s: script %s not found" % [key, row.get("script", "")])
		elif not FileAccess.get_file_as_string(str(row["script"])).contains(PLACE_BASE):
			problems.append("%s: %s does not extend place.gd" % [key, row["script"]])
	var dir := DirAccess.open("res://scripts")
	for f in dir.get_files():
		if not f.ends_with(".gd") or f == "place.gd":
			continue
		var path := "res://scripts/" + f
		if FileAccess.get_file_as_string(path).contains(PLACE_BASE) and not rows.has(path):
			problems.append("%s extends place.gd and has no row in Places.TABLE" % path)


## main.gd wires no place by hand: none of the table's scripts is named there.
func _main_has_no_hooks() -> void:
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	for row: Dictionary in Places.TABLE:
		if main.contains(str(row["script"])):
			problems.append("main.gd names %s: a hand hook came back (put it in Places.TABLE)" % row["script"])


## Builds the whole table through places.gd and judges the triangles, the own parts and the merge.
func _build_and_count(places: Node3D, map: Node3D, ctx: Dictionary) -> void:
	places.build(map, ctx, "")
	var poured := 0
	var total := 0
	for row: Dictionary in Places.TABLE:
		var key := str(row["key"])
		if not places.facts.has(key):
			problems.append("%s: a row but nothing built" % key)
			continue
		var f: Dictionary = places.facts[key]
		var tris := int(f["tris"])
		total += tris
		print("check_place_scripts: %-18s %6d tris (budget %d)  own %d (max %d)  %.0f ms" % [
				key, tris, int(row.get("tris", 0)), int(f["own"]), int(row.get("own", 0)), float(f["ms"])])
		if tris == 0:
			problems.append("%s: builds nothing" % key)
		if tris > int(row.get("tris", 0)):
			problems.append("%s: %d triangles (budget %d)" % [key, tris, int(row.get("tris", 0))])
		if int(f["own"]) > int(row.get("own", 0)):
			problems.append("%s: %d own draw items (own %d)" % [key, f["own"], int(row.get("own", 0))])
		var node := places.get_node_or_null(str(row["node"]))
		if node == null:
			problems.append("%s: no node %s under Places" % [key, row["node"]])
			continue
		poured += int(node.get("poured"))
		var meshes := _mesh_nodes(node)
		if meshes != int(f["own"]):
			problems.append("%s: %d MeshInstance3D under the place but %d from Place.part (use pour or part)" % [
					key, meshes, int(f["own"])])
	# One mesh per (sector, shadows), and the merge keeps every triangle.
	var seen := {}
	var merged := 0
	for mi: MeshInstance3D in places.sector_meshes:
		var key := mi.name
		if seen.has(key):
			problems.append("poured dressing in two meshes for %s" % key)
		seen[key] = true
		merged += _tris(mi.mesh)
	for child in places.get_children():
		if child is MeshInstance3D and not places.sector_meshes.has(child):
			problems.append("Places holds a mesh that is not a sector mesh: %s" % child.name)
	if merged != poured:
		problems.append("the merge kept %d triangles of %d poured" % [merged, poured])
	if places.sector_meshes.is_empty():
		problems.append("no sector mesh built")
	print("check_place_scripts: %d places, %d triangles, %d sector meshes (%d poured triangles)" % [
			Places.TABLE.size(), total, places.sector_meshes.size(), poured])


## The table again on the phone's map (Fakes.PhoneMap: `data` and ctx's "data" are the prebuilt index): every
## place builds what it builds on the whole map, or it reads a key the phone's city does not keep.
func _phone(whole: Dictionary, facts: Dictionary) -> void:
	var phone := Fakes.phone_map(whole)
	if phone.problem != "":
		problems.append("the phone's map: " + phone.problem)
	var ctx := {"data": phone.index_data, "dialogue": null, "clock": Callable(), "focus": Callable(),
			"vehicle": Callable(), "logs": {}}
	var places := Places.new()
	places.build(phone, ctx, "")
	var short := 0
	for row: Dictionary in Places.TABLE:
		var key := str(row["key"])
		var a: Dictionary = facts.get(key, {})
		var b: Dictionary = places.facts.get(key, {})
		var lost := int(a.get("tris", 0)) - int(b.get("tris", 0))
		var parts := int(a.get("own", 0)) - int(b.get("own", 0))
		var known: Array = PHONE_SHORT.get(key, [0, ""])
		if lost == 0 and parts == 0 and int(known[0]) == 0:
			continue
		short += 1
		if parts == 0 and -lost == int(known[0]):
			notes.append("%s: %+d triangles on the phone's map (known: %s)" % [key, -lost, known[1]])
		else:
			problems.append("%s: %d triangles, %d own parts on the phone's map against %d, %d on the whole map: it reads map data the prebuilt city does not keep (sector-only lists such as lamps or steps, or bake_city's BUILDER_ONLY)" % [
					key, int(b.get("tris", 0)), int(b.get("own", 0)), int(a.get("tris", 0)), int(a.get("own", 0))])
	for k: String in PHONE_SHORT:
		if not facts.has(k):
			problems.append("PHONE_SHORT names %s, which is no place in the table" % k)
	print("check_place_scripts: the phone's map (the prebuilt index only, %d keys): %d of %d places differ" % [
			phone.index_data.size(), short, Places.TABLE.size()])
	places.free()
	phone.free()


## With a solo site set only the rows that name it are built.
func _solo(map: Node3D, ctx: Dictionary) -> void:
	var places := Places.new()
	places.build(map, ctx, "spire")
	var want: Array[String] = []
	for row: Dictionary in Places.TABLE:
		if (row.get("solo", []) as Array).has("spire"):
			want.append(str(row["key"]))
	var got: Array[String] = []
	for k: String in places.facts:
		got.append(k)
	if got != want:
		problems.append("--solo=spire built %s, the table says %s" % [str(got), str(want)])
	var none := Places.new()
	none.build(map, ctx, "palace")
	if not none.facts.is_empty():
		problems.append("--solo=palace built %s: only rows that name the site may be built" % str(none.facts.keys()))
	places.free()
	none.free()


## Each place alone, poured meshes kept: the mesh check's defects against the ratchet, mesh by mesh.
func _defects(map: Node3D, ctx: Dictionary, probe: MeshProbe) -> void:
	for row: Dictionary in Places.TABLE:
		var key := str(row["key"])
		var place := (load(str(row["script"])) as GDScript).new() as Node3D
		var col := Collector.new()
		place.set("map", map)
		place.set("ctx", ctx)
		place.set("hub", col)
		place.call("build")
		# Mesh by mesh (a place pours one mesh per cell of its own, a mover is one mesh): the defects
		# are local, and the examination grows with the square of a mesh's triangles.
		var meshes: Array[Mesh] = []
		meshes.append_array(col.meshes)
		for mi in _mesh_instances(place):
			meshes.append(mi.mesh)
		var t0 := Time.get_ticks_msec()
		var f := {"tris": 0, "zfight": 0, "degenerate": 0, "badnormal": 0, "float": 0,
				"at_zfight": [], "at_degenerate": [], "at_badnormal": [], "at_float": []}
		for m in meshes:
			var whole := MeshProbe.Recorder.new()
			whole.add_mesh(m)
			for rec in _tiles(whole):
				var one := probe.examine(key, rec)
				for k: String in ["tris", "zfight", "degenerate", "badnormal", "float"]:
					f[k] += one[k]
				for k: String in ["at_zfight", "at_degenerate", "at_badnormal", "at_float"]:
					(f[k] as Array).append_array(one[k])
		var took := Time.get_ticks_msec() - t0
		var known: Dictionary = KNOWN.get(key, {})
		print("check_place_scripts: %-18s %6d tris  zfight %d  degenerate %d  badnormal %d  float %d  (%d ms)" % [
				key, f["tris"], f["zfight"], f["degenerate"], f["badnormal"], f["float"], took])
		for kind: String in ["zfight", "degenerate", "badnormal", "float"]:
			var allowed := int(known.get(kind, 0))
			if f[kind] > allowed:
				problems.append("%s: %d %s (known %d)%s" % [key, f[kind], kind, allowed, _where(f, kind)])
			elif f[kind] < allowed:
				notes.append("%s: %s is down to %d (KNOWN says %d): lower it" % [key, kind, f[kind], allowed])
		col.free()
		place.free()


## A big mesh cut into TILE m squares by each triangle's centre (the examination grows with the
## square of the triangles it compares; a defect is between neighbours, and a pair split by a tile
## edge is not seen). A mesh of TILE_AT triangles or fewer is one piece.
func _tiles(rec: MeshProbe.Recorder) -> Array[MeshProbe.Recorder]:
	var out: Array[MeshProbe.Recorder] = []
	var n := rec.pos.size() / 3
	if n <= TILE_AT:
		out.append(rec)
		return out
	var by := {}
	for t in n:
		var c := (rec.pos[t * 3] + rec.pos[t * 3 + 1] + rec.pos[t * 3 + 2]) / 3.0
		var k := Vector2i(floori(c.x / TILE), floori(c.z / TILE))
		if not by.has(k):
			by[k] = MeshProbe.Recorder.new()
		var r: MeshProbe.Recorder = by[k]
		for i in 3:
			r.pos.append(rec.pos[t * 3 + i])
			r.norms.append(rec.norms[t * 3 + i])
			r.codes.append(rec.codes[t * 3 + i])
	for k: Vector2i in by:
		out.append(by[k])
	return out


func _where(f: Dictionary, kind: String) -> String:
	var at: Array = f["at_" + kind]
	if at.is_empty():
		return ""
	var parts: Array[String] = []
	for v: Vector3 in at.slice(0, 3):
		parts.append("(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z])
	return " e.g. at " + ", ".join(parts)


## MeshInstance3D nodes under a node (itself included).
func _mesh_instances(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_mesh_instances(c))
	return out


func _mesh_nodes(n: Node) -> int:
	return _mesh_instances(n).size()


func _tris(mesh: Mesh) -> int:
	return preload("res://scripts/place.gd").mesh_triangles(mesh)
