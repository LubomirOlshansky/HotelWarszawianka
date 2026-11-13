extends Node3D
## The owner of the place scripts (pipeline review item 7, 2026-11-13; docs/design/building-pipeline-review.md
## way B, weak place W7). Every place (first scene, the Patelnia, Tamka ...) is a script that
## extends place.gd plus one row of TABLE; main.gd calls `build` once and wires nothing by hand.
##
## What it does that the hand wiring did not:
##  - a place's static dressing (`Place.pour`) is merged here into ONE MeshInstance3D per map
##    sector and shadow setting (`places_<cx>_<cz>`), in the actors' material, so dressing costs
##    one draw call per sector however many places stand in it (before: one per place and, for
##    street_details, park_details and Tamka, one per 256 m cell of their own);
##  - every row has a triangle budget and a count of the draw items of its own it may add
##    (`own`: a mesh with its own material, a mover), which check_places.gd holds it to.
##
## No distance visibility range (decisions.md, "Places: merged per sector, no range"): the camera is
## orthographic and sits 500 m back at every play zoom, so a range in metres from the camera cannot
## tell near from far on screen, and the frustum already culls what is off screen.
## One node, named "Places", child of the world, built once at load (an awaitable setup step).

const MapBuilderRef := preload("res://scripts/map_builder.gd")
const Models := preload("res://scripts/models.gd")
const Place := preload("res://scripts/place.gd")

## The merge cell: a map sector (512 m). Both city paths use the same cells, so the merged
## meshes are the same on the runtime build and the prebuilt sectors.
const CELL := MapBuilderRef.SECTOR

## One row per place, in the order the places were built by hand (Tamka last):
##   key    short id (the log line, the check's facts)
##   script the place script (extends place.gd), loaded here at build time
##   node   the node's name under "Places"
##   tris   the triangle budget of everything the place makes, poured and own (measured on
##          check_places' flat stub map and on the real city, plus about 20 %: raise on purpose only)
##   own    how many draw items of its own (`Place.part` meshes) the place may add
##   solo   optional: the `--solo=` site keys the place is still built for (every other place is
##          skipped while a solo site is set)
const TABLE: Array[Dictionary] = [
	{"key": "first_scene", "script": "res://scripts/first_scene.gd", "node": "FirstScene", "tris": 19800, "own": 0},
	{"key": "skwer_zlota", "script": "res://scripts/skwer_zlota.gd", "node": "SkwerZlota", "tris": 5300, "own": 0},
	{"key": "centralny_ramp", "script": "res://scripts/centralny_ramp.gd", "node": "CentralnyRamp", "tris": 5900, "own": 0},
	{"key": "patelnia", "script": "res://scripts/patelnia.gd", "node": "Patelnia", "tris": 19300, "own": 0},
	{"key": "plac_pieciu_rogow", "script": "res://scripts/plac_pieciu_rogow.gd", "node": "PlacPieciuRogow", "tris": 10200, "own": 0},
	{"key": "tarasy_screen", "script": "res://scripts/tarasy_screen.gd", "node": "TarasyScreen", "tris": 6, "own": 1},
	{"key": "spire_motion", "script": "res://scripts/spire_motion.gd", "node": "SpireMotion", "tris": 720, "own": 2,
			"solo": ["spire"]},
	{"key": "street_details", "script": "res://scripts/street_details.gd", "node": "StreetDetails", "tris": 96200, "own": 0},
	{"key": "ratusz_hub", "script": "res://scripts/ratusz_hub.gd", "node": "RatuszHub", "tris": 14000, "own": 0},
	{"key": "park_details", "script": "res://scripts/park_details.gd", "node": "ParkDetails", "tris": 142000, "own": 0},
	{"key": "tamka", "script": "res://scripts/tamka.gd", "node": "Tamka", "tris": 138300, "own": 1},
]

## Per place key: {"tris": triangles (poured and own), "own": draw items of its own, "ms": build ms}.
var facts := {}
## The merged sector meshes, after `build`.
var sector_meshes: Array[MeshInstance3D] = []
## The poured meshes waiting for the merge: [mesh, shadows].
var _poured: Array = []
## Triangles of the merged meshes (what the merge kept), for the log line and the check.
var merged_tris := 0


## Builds every place of TABLE (all of them, or with `solo_site` set only the rows that name it),
## then merges the poured dressing. `ctx` is what main.gd hands every place (place.gd).
func build(map: Node3D, ctx: Dictionary, solo_site := "") -> void:
	var t_all := Time.get_ticks_usec()
	var built := 0
	var tris_all := 0
	var own_all := 0
	for row: Dictionary in TABLE:
		if solo_site != "" and not (row.get("solo", []) as Array).has(solo_site):
			continue
		var t0 := Time.get_ticks_usec()
		var place := (load(row["script"]) as GDScript).new() as Node3D
		place.name = row["node"]
		place.set("map", map)
		place.set("ctx", ctx)
		place.set("hub", self)
		add_child(place)
		place.call("build")
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		var tris := int(place.call("total_triangles"))
		var own := int(place.get("own_parts"))
		facts[row["key"]] = {"tris": tris, "own": own, "ms": ms}
		tris_all += tris
		own_all += own
		built += 1
		print("places: %s %d triangles, %d own parts, %.1f ms" % [row["key"], tris, own, ms])
		await LoadYield.tick("place %s" % row["key"])
	_merge()
	print("places: %d places, %d triangles, %d sector meshes, %d own parts, built in %.0f ms" % [
			built, tris_all, sector_meshes.size(), own_all, float(Time.get_ticks_usec() - t_all) / 1000.0])


## Takes a poured mesh (Place.pour): kept until `_merge` puts every one into its sector's mesh.
func take(mesh: ArrayMesh, shadows: bool) -> void:
	_poured.append([mesh, shadows])


## One MeshInstance3D per (sector, shadows): the poured meshes' arrays concatenated as they are
## (positions, normals, colours and both UV sets are copied value for value, so the actors'
## material reads exactly what it read before). The cell is the sector of the mesh's AABB centre.
func _merge() -> void:
	var groups := {}  # "cx_cz_shadows" -> {"cx", "cz", "shadows", "meshes"}
	for rec: Array in _poured:
		var mesh := rec[0] as ArrayMesh
		var c := mesh.get_aabb().get_center()
		var cx := floori(c.x / CELL)
		var cz := floori(c.z / CELL)
		var gk := "%d_%d_%d" % [cx, cz, 1 if rec[1] else 0]
		if not groups.has(gk):
			groups[gk] = {"cx": cx, "cz": cz, "shadows": rec[1], "meshes": []}
		(groups[gk]["meshes"] as Array).append(mesh)
	_poured.clear()
	var list: Array = groups.values()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["cx"] != b["cx"]:
			return a["cx"] < b["cx"]
		if a["cz"] != b["cz"]:
			return a["cz"] < b["cz"]
		return a["shadows"] and not b["shadows"])
	for g: Dictionary in list:
		var merged := _concat(g["meshes"] as Array)
		var mi := MeshInstance3D.new()
		mi.name = "places_%d_%d%s" % [g["cx"], g["cz"], "" if g["shadows"] else "_ns"]
		mi.mesh = merged
		mi.material_override = Models.material()
		if not g["shadows"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		sector_meshes.append(mi)
		merged_tris += Place.mesh_triangles(merged)


## One mesh from several: every surface's arrays appended in order. An attribute some meshes have
## and others lack is filled with the engine's default for the ones without (white, zero, up).
func _concat(meshes: Array) -> ArrayMesh:
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	var has_n := false
	var has_c := false
	var has_u := false
	var has_u2 := false
	var has_i := false
	var surfaces: Array = []
	for mesh: ArrayMesh in meshes:
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			surfaces.append(a)
			has_n = has_n or a[Mesh.ARRAY_NORMAL] != null
			has_c = has_c or a[Mesh.ARRAY_COLOR] != null
			has_u = has_u or a[Mesh.ARRAY_TEX_UV] != null
			has_u2 = has_u2 or a[Mesh.ARRAY_TEX_UV2] != null
			has_i = has_i or a[Mesh.ARRAY_INDEX] != null
	for a: Array in surfaces:
		var p: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var n := p.size()
		var base := pos.size()
		pos.append_array(p)
		if has_n:
			nor.append_array(a[Mesh.ARRAY_NORMAL] if a[Mesh.ARRAY_NORMAL] != null else _fill3(n, Vector3.UP))
		if has_c:
			col.append_array(a[Mesh.ARRAY_COLOR] if a[Mesh.ARRAY_COLOR] != null else _fillc(n))
		if has_u:
			uv.append_array(a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else _fill2(n))
		if has_u2:
			uv2.append_array(a[Mesh.ARRAY_TEX_UV2] if a[Mesh.ARRAY_TEX_UV2] != null else _fill2(n))
		if has_i:
			if a[Mesh.ARRAY_INDEX] != null:
				for i: int in (a[Mesh.ARRAY_INDEX] as PackedInt32Array):
					idx.append(i + base)
			else:
				for i in n:
					idx.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pos
	if has_n:
		arrays[Mesh.ARRAY_NORMAL] = nor
	if has_c:
		arrays[Mesh.ARRAY_COLOR] = col
	if has_u:
		arrays[Mesh.ARRAY_TEX_UV] = uv
	if has_u2:
		arrays[Mesh.ARRAY_TEX_UV2] = uv2
	if has_i:
		arrays[Mesh.ARRAY_INDEX] = idx
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


func _fill3(n: int, v: Vector3) -> PackedVector3Array:
	var a := PackedVector3Array()
	a.resize(n)
	a.fill(v)
	return a


func _fill2(n: int) -> PackedVector2Array:
	var a := PackedVector2Array()
	a.resize(n)
	return a


func _fillc(n: int) -> PackedColorArray:
	var a := PackedColorArray()
	a.resize(n)
	a.fill(Color.WHITE)
	return a
