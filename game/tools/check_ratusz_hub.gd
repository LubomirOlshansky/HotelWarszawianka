extends SceneTree
## The Ratusz Arsenał interchange (ratusz_hub.gd, F's photos 2026-11-07) against the committed map:
## the three hub platforms are found with the tracks on their front side, each gets its arched
## canopy (arches, benches, two boards), the whole hub is one surface inside its triangle budget,
## Gruba Kaśka stands between the two Solidarności platforms, Andersa's stop 03 has none, the tower
## and its railings keep clear of the tracks, the generic shelters on the hub platforms
## are dropped and no others, the station's entrances take the Ratusz forms and each form builds,
## and the trams carry passengers. No renderer, no derived map files (CI too).
##   godot --headless --path game --script res://tools/check_ratusz_hub.gd

const RatuszHub := preload("res://scripts/ratusz_hub.gd")
const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const Storefronts := preload("res://scripts/storefronts.gd")

const MAP := "res://map/centrum.json"
## The hub's one mesh, at most (the canopies, the tower, the railings).
const MAX_TRIS := 16000
## One entrance form, at most.
const MAX_FORM_TRIS := 1200
## The tower's wall to the nearest track's centre line, at least (a tram is 2.4 m wide).
const TOWER_CLEAR := 1.7
## Stop 03 on Andersa: no canopy there (F, 2026-11-07).
const ANDERSA_03 := Vector2(-1586.5, -1202.7)
## A tram car's passengers, at most (6 triangles each).
const MAX_PASSENGER_TRIS := 400

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _tris(mesh: ArrayMesh) -> int:
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	return mesh.surface_get_array_len(0) / 3


func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP))
	var plats := RatuszHub.hub_platforms(data)
	_expect(plats.size() == RatuszHub.PLATFORMS.size(), "%d hub platforms found, want %d" % [plats.size(), RatuszHub.PLATFORMS.size()])
	var tracks := RatuszHub._track_segments(data, RatuszHub.PLATFORMS[0], 220.0)
	for p: Dictionary in plats:
		var span := RatuszHub.canopy_span(p)
		_expect(float(span[1]) - float(span[0]) >= 20.0, "canopy at %s only %.1f m long" % [p["c"], float(span[1]) - float(span[0])])
		_expect(float(span[2]) >= 3.0, "canopy at %s only %.1f m deep" % [p["c"], span[2]])
		# The front (v1) edge's middle is nearer a track than the back (v0) edge's.
		var c: Vector2 = p["c"]
		var n: Vector2 = p["n"]
		var front := c + n * float(p["v1"])
		var back := c + n * float(p["v0"])
		var df := INF
		var db := INF
		for sg: Array in tracks:
			df = minf(df, Geometry2D.get_closest_point_to_segment(front, sg[0], sg[1]).distance_to(front))
			db = minf(db, Geometry2D.get_closest_point_to_segment(back, sg[0], sg[1]).distance_to(back))
		_expect(df < db, "platform at %s: its canopy opens away from the tracks (front %.1f m, back %.1f m)" % [c, df, db])
	# The hub with no map (flat ground).
	var hub := RatuszHub.new()
	hub.build(data)
	_expect(hub.canopies == plats.size(), "%d canopies built" % hub.canopies)
	_expect(hub.arches >= 40, "only %d arches" % hub.arches)
	_expect(hub.boards == 2 * hub.canopies, "%d boards" % hub.boards)
	_expect(hub.benches >= 2 * hub.canopies, "%d benches" % hub.benches)
	_expect(hub.triangles > 0 and hub.triangles <= MAX_TRIS, "%d triangles (budget %d)" % [hub.triangles, MAX_TRIS])
	var meshes := 0
	for ch in hub.get_children():
		if ch is MeshInstance3D:
			meshes += 1
	_expect(meshes == 1, "%d meshes (one draw call wanted)" % meshes)
	hub.free()
	# The tower and its railings against the tracks.
	var near := RatuszHub._track_segments(data, RatuszHub.TOWER, 40.0)
	var clear := INF
	for sg: Array in near:
		clear = minf(clear, Geometry2D.get_closest_point_to_segment(RatuszHub.TOWER, sg[0], sg[1]).distance_to(RatuszHub.TOWER))
	_expect(clear - RatuszHub.TOWER_R - 0.22 >= TOWER_CLEAR, "the tower stands %.2f m from a track" % (clear - RatuszHub.TOWER_R - 0.22))
	for p: Dictionary in plats:
		_expect(not Geometry2D.is_point_in_polygon(RatuszHub.TOWER, p["poly"]), "the tower stands on a platform")
		_expect((p["c"] as Vector2).distance_to(ANDERSA_03) > 30.0, "stop 03 on Andersa got a canopy (it has ordinary shelters)")
	# Gruba Kaśka stands between the two platforms: on the far side of each from the other's view.
	if plats.size() == 2:
		var c0: Vector2 = plats[0]["c"]
		var c1: Vector2 = plats[1]["c"]
		var t := Geometry2D.get_closest_point_to_segment_uncapped(RatuszHub.TOWER, c0, c1)
		var k := (t - c0).dot(c1 - c0) / (c1 - c0).length_squared()
		_expect(k > 0.1 and k < 0.9, "the tower is not between the two Solidarności platforms (%.2f)" % k)
	# The shelters: the hub's dropped, the rest kept.
	var shelters: Array = data.get("shelters", [])
	var dropped := 0
	for i in range(0, shelters.size() - 2, 3):
		if RatuszHub.covers(float(shelters[i]), float(shelters[i + 1]), plats):
			dropped += 1
			var at := Vector2(float(shelters[i]), float(shelters[i + 1]))
			_expect(at.distance_to(RatuszHub.PLATFORMS[0]) < 140.0, "a shelter at %s dropped far from the hub" % at)
	_expect(dropped >= 2 and dropped <= 8, "%d shelters dropped on the hub platforms" % dropped)
	# The entrances: the station's take the Ratusz forms, each form builds within its budget.
	var forms := {}
	for p: Dictionary in data.get("pois", []):
		if str(p.get("k", "")) == "subway_entrance" and str(p.get("st", "")) == RatuszHub.STATION:
			forms[Storefronts.metro_form(str(p["st"]), str(p.get("f", "canopy")))] = true
	for f: String in ["pavilion", "stone", "stone_steps"]:
		_expect(forms.has(f), "no %s entrance at the station" % f)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Props.add_metro_entrance(st, Transform3D.IDENTITY, f, false)
		var t := _tris(st.commit())
		_expect(t > 100 and t <= MAX_FORM_TRIS, "form %s: %d triangles" % [f, t])
	_expect(Storefronts.metro_form("Centrum", "canopy") == "tube", "Centrum lost its tubes")
	# The trams' passengers.
	var s := Models.Shape.new()
	var face := [Vector3(1.2, 1.1, -5.0), Vector3(1.2, 1.1, 5.0), Vector3(1.15, 3.2, 5.0), Vector3(1.15, 3.2, -5.0), Vector3(1, 0, 0)]
	Models.passengers(s, face, 0.1, 0.9, 0.27, 0.78, 3)
	var pt := _tris(s.mesh())
	_expect(pt > 0 and pt <= MAX_PASSENGER_TRIS, "%d passenger triangles on a 8 m band" % pt)
	print("ratusz_hub: %d platforms, %d entrance forms, %d passenger triangles a band" % [plats.size(), forms.size(), pt])
	if _problems > 0:
		print("ratusz_hub: FAIL (%d)" % _problems)
		quit(1)
	else:
		print("ratusz_hub: OK")
		quit(0)
