extends SceneTree
## The city objects plan, step 4 (docs/design/drivable-city-build.md item 5; docs/design/
## drivable-city.md rule R2, "solid looks solid"): every collider face of the city held against
## what is drawn there. The runtime builder (map_builder.gd build_sector) keeps each `_solid` call
## with its site's hint (`note_solids`: [class, faces, drawn]), and the check builds a second,
## check-only physics body of the sector's drawing: every mesh's triangles (the tiles round the
## sector too, `note_reach`, so a drawing over the border is whole) and every MultiMesh
## instance's box, on a layer of its own. Then, over the faces whose centre lies in the sector
## (each face in one sector, as the colliders are cut):
##   K  every class is one solidity.gd knows;
##   L  a hard class (answer H) whose site says its drawing is under R2_LOW m (`h`): PT-47's kind,
##      a 0.2 m kerb that kept a 1.9 m wall's collider;
##   B  the plan test: along each collider's foot every STEP m, something drawn at least R2_LOW m
##      over the surface (and under the car's roof, BAND) within R2_OUT m in plan; a stretch
##      with nothing is "bare" (the collider stands more than R2_OUT m outside its drawing, or
##      on nothing). A collider with more than BARE_MAX m of it fails. Sites that stand on their
##      drawing's own outline (`same`: buildings, LoD2, barriers, platforms) are taken at their
##      word unless --all (which tests them too: the hints' proof);
##   N  invisible on purpose (`none`) only for a reason this check knows: the pocket walls, the
##      PT-40 lead-ins, the PT-18 rail joins; everything else invisible fails B;
##   P  the pocket-wall audit (map_builder.gd _bridge_pockets): both ends within POCKET_END m of
##      a drawn face or a block's wall ("at"; up to POCKET_NEAR, "<1m", leaves a gap no car enters
##      and passes too), and the gap a slit under POCKET_SLIT m, a notch, or a fairing before a step;
##      the PT-17 bays (up to 30 m wide, 2.5 m deep) on the allow-list by rule. A pocket with an
##      end on open ground is the bug the census asked about.
## ALLOW holds the allowed findings, each with its reason, by rule (a decision), never by place;
## the overhangs (O) are counted only.
##
## Prints the counts per class and kind and `check_colliders: OK (...)` (exit 0), or the findings
## and exit 1. Default: the SECTORS (check_solids.gd's six and four more), about 1.5 min; --all
## every sector and the `same` sites too (~11 min in the cloud).
##   godot --headless --path game --script res://tools/check_colliders.gd [-- --all --sectors=i,j;i,j
##       --verbose --review=DIR]
## --review=DIR writes pockets.tsv (every pocket wall: sector, x, z, kind, length, ends' gaps,
## verdict) and findings.tsv (every finding, allowed or not) there.

const MapBuilder := preload("res://scripts/map_builder.gd")
const Solidity := preload("res://scripts/solidity.gd")

## check_solids.gd's six (the stadium's grounds, Marszałkowska and the spawn, Poniatowski's
## viaduct and the river) and four more: the Old Town (-2,-3), Powiśle and Tamka (0,-1),
## Centralna's cutting and the tram stops on Aleje (-3,0), Praga by Most Śląsko-Dąbrowski (0,-2).
const SECTORS: Array[Vector2i] = [Vector2i(3, -1), Vector2i(2, -1), Vector2i(-2, 0), Vector2i(-2, 1),
		Vector2i(0, 0), Vector2i(1, -1), Vector2i(-2, -3), Vector2i(0, -1), Vector2i(-3, 0), Vector2i(0, -2)]
## A drawing under this is no drawing for a hard class (m; PT-47's planter kerbs drew 0.2 m).
const R2_LOW := 0.3
## R2: no collider more than this outside its drawing in plan (m).
const R2_OUT := 0.5
## The plan test's spacing along a collider's foot (m).
const STEP := 1.0
## A collider fails B with more bare foot than this (m): one or two samples (a slope's corner
## under a parked car, a drape's last cell at a run's end) are the sampling's own grain; they
## are counted in the table (bare), not failed.
const BARE_MAX := 2.0
## What counts as drawn at a sample: something from R2_LOW over the surface up to this (m): the
## car's body, not a deck or a roof overhead.
const BAND_TOP := 1.6
## A bare sample with a drawing from BAND_TOP up to this over it within R2_OUT stands under an
## overhang (an arcade, a building lifted on posts, a gallery): counted on its own (O).
const OVER_TOP := 8.0
## The pocket audit: an end within this of a drawn face (m), a slit under this (m: the car's width).
const POCKET_END := 0.3
## A pocket's end this near a face leaves a gap under half the car's width: no car gets in.
const POCKET_NEAR := 1.0
const POCKET_SLIT := 1.9
## A fairing's longest (map_builder.gd: STEP_TAPER * STEP_MAX = 3.6 m back along the wall, to a
## corner up to 1.5 m ahead and 0.6 m out: 5.1 m) and a notch's widest mouth (POCKET_MOUTH).
const POCKET_FAIRING := 5.2
const POCKET_NOTCH := 4.5
## The check's drawing body: on this layer only (the city's colliders are on 1); the buildings'
## colliders for the pocket audit on WALL_LAYER.
const DRAW_LAYER := 1 << 19
const WALL_LAYER := 1 << 20
const SOLID_LAYER := 1 << 21
## The reach test (`_reachable`).
const REACH_SIDE := 0.4
const REACH_RAYS := 12
const REACH_FAR := 150.0
## The classes a pocket wall may end on (a block's walls: map_builder.gd _bridge_pockets bridges
## their outlines, a landmark's mapped ring among them).
const BLOCK_CLASSES := [&"building", &"lod2", &"small_building", &"landmark"]
## The findings allowed, all by rule (a decision, not a place): [finding kind, class or pocket
## kind, the longest such finding allowed (m; 0: any), reason].
const ALLOW := [
	["P", "bay", 0.0, "PT-17 (2026-11-03): a bay up to 30 m wide and 2.5 m deep in a block's front, closed at its mouth so a car sliding along it is not thrown between the piers; wider than the car on purpose"],
	["N", "taper", 0.0, "PT-40 (2026-11-07): the collider-only lead-in at a Poniatowski approach wall's open end, behind the tower's own collider, so a car glances back onto the road"],
	["N", "join", 0.0, "PT-18: the shallow V behind a gap under 1.5 m between two drawn guard rails' ends on a deck (a gap narrower than the car: R2's own exception)"],
	["N", "water", 0.0, "a natural bank's edge (map_builder.gd _build_shore): the car stops at the foam; the water is what stops it (R1), and the river is the drawing"],
	["N", "deck_gap", 0.0, "a 3D-mapped bridge's joined side (map_builder.gd _build_decks): drawn as a 0.22 m kerb on the piece's edge, solid over the drop into the gap to the next piece; a structure edge (R1)"],
	["L", "platform", 0.0, "PT-1 (2026-11-07): a platform's sides stand 1.5 m over its top so a car off the tracks slides along instead of climbing onto the shelter; the slab is drawn level at its outline's lowest ground (OSM has no heights), so on a slope its high end sinks and the side stands over the ground there: the tram-island Open Question (step 4: 0 contacts in set A)"],
	["B", "landmark", 30.0, "a landmark's collider is its mapped outline (the street blocks' `raw`, a model's footprint); where the model is set back from it (an arcade, a recessed ground floor, a gate, a court's mouth) the ring closes the recess like a PT-17 bay, up to a bay's 30 m; fitting the rings to the models is an Open Question"],
]

var problems: Array[String] = []
var verbose := false
var test_all := false
var review := ""
var keys: Array[Vector2i] = []
var runtime: Node3D
var _i := -1
var _phase := 0
var _built: Node3D
var _drawing: StaticBody3D
var _space: PhysicsDirectSpaceState3D
var _q := PhysicsShapeQueryParameters3D.new()
var _cyl := CylinderShape3D.new()
var _ray := PhysicsRayQueryParameters3D.new()
var _t0 := 0
## Per class: [notes, faces, samples, bare samples, failing notes, samples under an overhang,
## bare samples no car reaches].
var per := {}
## Findings: [kind, class, x, z, metres or length, detail, allowed reason or ""].
var findings: Array = []
var pocket_rows := PackedStringArray()
var pockets := {}
var low_hard := {}
var skipped_same := 0
var _ready_points: Array[Vector3] = []
## The ground under each collider vertex of the sector, as its build read it.
var _g_at := {}
## --probe=X,Z: that point's sector only, and every collider within PROBE_R of it printed with its
## samples (what is drawn round each, by height band and radius).
var probe := Vector2(INF, INF)
const PROBE_R := 3.0


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
		elif a == "--all":
			test_all = true
		elif a.begins_with("--sectors="):
			only = a.trim_prefix("--sectors=")
		elif a.begins_with("--review="):
			review = a.trim_prefix("--review=")
		elif a.begins_with("--probe="):
			var xz := a.trim_prefix("--probe=").split(",")
			probe = Vector2(float(xz[0]), float(xz[1]))
			only = "%d,%d" % [floori(probe.x / MapBuilder.SECTOR), floori(probe.y / MapBuilder.SECTOR)]
	_t0 = Time.get_ticks_msec()
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	if only != "":
		for pair in only.split(";"):
			var ij := pair.split(",")
			keys.append(Vector2i(int(ij[0]), int(ij[1])))
	elif test_all:
		for k: Array in index["sectors"]["keys"]:
			keys.append(Vector2i(int(k[0]), int(k[1])))
	else:
		keys = SECTORS.duplicate()
	runtime = MapBuilder.new()
	runtime.name = "City"
	root.add_child(runtime)
	runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	runtime.note_solids = true
	runtime.note_reach = 1
	_q.shape = _cyl
	_q.collision_mask = DRAW_LAYER
	_q.collide_with_areas = false
	_ray.collision_mask = SOLID_LAYER
	_ray.hit_back_faces = true
	pocket_rows.append("sector\tx\tz\tkind\tlength\tend_a\tend_b\tverdict")


func _physics_process(_delta: float) -> bool:
	if _phase == 0:
		_i += 1
		if _i >= keys.size():
			_finish()
			return true
		var t := Time.get_ticks_msec()
		runtime.solid_notes.clear()
		_built = runtime.build_sector(keys[_i])
		_drawing = _draw_body(_built)
		_wall_body(_drawing, runtime.solid_notes)
		root.add_child(_drawing)
		if verbose:
			print("  %s built in %d ms" % [keys[_i], Time.get_ticks_msec() - t])
		_phase = 1
		return false
	if _phase < 3:
		_phase += 1
		return false
	_space = _drawing.get_world_3d().direct_space_state
	# The drawing body must answer before the sector is judged: its own triangles, hit where they
	# are (a physics frame or more after a big body went in).
	var missed := 0
	for c: Vector3 in _ready_points:
		_cyl.radius = 0.05
		_cyl.height = 0.1
		_q.transform = Transform3D(Basis(), c)
		if _space.intersect_shape(_q, 1).is_empty():
			missed += 1
	if missed > 0 and _phase < 60:
		_phase += 1
		return false
	if missed > 0:
		problems.append("%s: the check's drawing body missed %d of its own %d test points" % [keys[_i], missed, _ready_points.size()])
	if verbose and _phase > 3:
		print("  %s: the drawing answered after %d frames" % [keys[_i], _phase - 1])
	var t2 := Time.get_ticks_msec()
	_check_sector(keys[_i])
	if verbose:
		print("  %s checked in %d ms" % [keys[_i], Time.get_ticks_msec() - t2])
	root.remove_child(_drawing)
	_drawing.free()
	_built.free()
	runtime.solid_notes.clear()
	_phase = 0
	return false


## The sector's drawing as one check-only body: each mesh's triangles, each MultiMesh instance's box.
func _draw_body(sector: Node3D) -> StaticBody3D:
	_ready_points.clear()
	var body := StaticBody3D.new()
	body.name = "R2Drawing"
	body.collision_layer = DRAW_LAYER
	body.collision_mask = 0
	for n in sector.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		# The lamps' night halos are light, not a thing.
		if not g.visible or g.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY \
				or str(sector.get_path_to(g)).contains("LampHalos"):
			continue
		var xf := _local(g, sector)
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var faces := (g as MeshInstance3D).mesh.get_faces()
			if faces.is_empty():
				continue
			if xf != Transform3D.IDENTITY:
				faces = xf * faces
			var stride := maxi(1, faces.size() / 3 / 40) * 3
			for i in range(0, faces.size() - 2, stride):
				_ready_points.append((faces[i] + faces[i + 1] + faces[i + 2]) / 3.0)
			var shape := ConcavePolygonShape3D.new()
			shape.backface_collision = true
			shape.set_faces(faces)
			var cs := CollisionShape3D.new()
			cs.shape = shape
			body.add_child(cs)
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
			var mm := (g as MultiMeshInstance3D).multimesh
			if mm.mesh == null:
				continue
			var box := mm.mesh.get_aabb()
			if box.size.y < R2_LOW:
				continue
			var shape := BoxShape3D.new()
			shape.size = box.size.max(Vector3(0.02, 0.02, 0.02))
			# map_builder.gd notes the instances (`r2_spots`): a headless run keeps no MultiMesh data.
			var spots: Array = g.get_meta(&"r2_spots", [])
			if spots.is_empty():
				for k in mm.instance_count:
					spots.append(mm.get_instance_transform(k))
			for t: Transform3D in spots:
				var cs := CollisionShape3D.new()
				cs.shape = shape
				cs.transform = xf * t * Transform3D(Basis(), box.get_center())
				body.add_child(cs)
	return body


## The block classes' collider faces as shapes of the drawing body on WALL_LAYER, for the pocket
## audit: a pocket that ends on a building's collider ring closes a gap between colliders even
## where the ring stands off its drawing (that is the ring's own B finding).
## And every collider face on SOLID_LAYER, for the reach test (`_reachable`).
func _wall_body(body: StaticBody3D, notes: Array) -> void:
	var faces := PackedVector3Array()
	var every := PackedVector3Array()
	for note: Array in notes:
		if StringName(note[0]) in BLOCK_CLASSES:
			faces.append_array(note[1])
		every.append_array(note[1])
	for pair: Array in [[faces, WALL_LAYER], [every, SOLID_LAYER]]:
		if (pair[0] as PackedVector3Array).is_empty():
			continue
		var walls := StaticBody3D.new()
		walls.collision_layer = pair[1]
		walls.collision_mask = 0
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(pair[0])
		var cs := CollisionShape3D.new()
		cs.shape = shape
		walls.add_child(cs)
		body.add_child(walls)


## Whether a car can reach a collider at p (its plan normal n) from either side: a side is shut
## when every one of REACH_RAYS level rays from REACH_SIDE m out, at car height, meets a collider
## within REACH_FAR m (inside a building's ring, a closed court). A collider no car can reach is
## no driving matter: its bare samples are counted apart (inside).
func _reachable(p: Vector2, n: Vector2, ref: float) -> bool:
	for side: float in [1.0, -1.0]:
		var q := p + n * side * REACH_SIDE
		var from := Vector3(q.x, ref + 1.0, q.y)
		var shut := true
		for k in REACH_RAYS:
			var d := Vector2.from_angle(TAU * k / REACH_RAYS)
			_ray.from = from
			_ray.to = from + Vector3(d.x, 0.0, d.y) * REACH_FAR
			if _space.intersect_ray(_ray).is_empty():
				shut = false
				break
		if not shut:
			return true
	return false


## `n`'s transform relative to `top` (the sector root, not in the tree).
func _local(n: Node3D, top: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != top:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


func _check_sector(key: Vector2i) -> void:
	var rect := Rect2(Vector2(key) * MapBuilder.SECTOR, Vector2(MapBuilder.SECTOR, MapBuilder.SECTOR))
	# The ground under every collider vertex as the build read it (map_builder.gd notes it).
	_g_at.clear()
	for note: Array in runtime.solid_notes:
		var vs: PackedVector3Array = note[1]
		var gs: PackedFloat32Array = note[3]
		for i in vs.size():
			_g_at[Vector2i(roundi(vs[i].x * 20.0), roundi(vs[i].z * 20.0))] = gs[i]
	for note: Array in runtime.solid_notes:
		var cls := StringName(note[0])
		var all: PackedVector3Array = note[1]
		var drawn: Dictionary = note[2]
		var faces := PackedVector3Array()
		for i in range(0, all.size() - 2, 3):
			var c := (all[i] + all[i + 1] + all[i + 2]) / 3.0
			if rect.has_point(Vector2(c.x, c.z)):
				faces.append_array([all[i], all[i + 1], all[i + 2]])
		if faces.is_empty():
			continue
		if probe.x < INF:
			_probe(cls, faces, drawn)
		if not per.has(cls):
			per[cls] = [0, 0, 0, 0, 0, 0, 0]
		var row: Array = per[cls]
		row[0] += 1
		row[1] += faces.size() / 3
		var at := _plan_mid(faces)
		# K: the class.
		if not Solidity.is_known(cls):
			_find("K", cls, at, 0.0, "class not in solidity.gd")
			continue
		var hard := Solidity.answer(cls) == "H"
		# N, P: invisible on purpose.
		if drawn.has("none"):
			var why := str(drawn["none"])
			if why == "pocket":
				_pocket(key, faces, str(drawn.get("kind", "")))
			elif why in ["taper", "join", "water", "deck_gap"]:
				_find("N", StringName(why), at, _plan_length(faces), str(cls))
			else:
				_find("N", cls, at, _plan_length(faces), "invisible for an unknown reason: %s" % why)
			continue
		# L: the site's own drawn height, where the collider stands out of the surface.
		if drawn.has("h") and hard:
			var h := float(drawn["h"])
			var proud := _proud(faces)
			if h < R2_LOW and proud > R2_LOW:
				_find("L", cls, at, _plan_length(faces), "drawn %.2f m, the collider %.2f m over the surface" % [h, proud])
			elif h < 0.8 and proud > R2_LOW:
				low_hard[cls] = int(low_hard.get(cls, 0)) + 1
		if drawn.get("same", false) and not test_all:
			skipped_same += 1
			continue
		# B: the plan test.
		var bare := 0
		var under := 0
		var samples := 0
		var worst := Vector2.ZERO
		var gap := 0.0
		for seg in _foot(faces, cls == &"lod2"):
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var y0: float = seg[2]
			var length := a.distance_to(b)
			var n := maxi(1, ceili(length / STEP))
			for k in n:
				var p := a.lerp(b, (k + 0.5) / n)
				var ref := _surface(lerpf(seg[3], seg[4], (k + 0.5) / n), y0)
				samples += 1
				if not _drawn_at(p, ref, R2_OUT):
					if _drawn_at(p, ref, R2_OUT, BAND_TOP, OVER_TOP):
						under += 1
						continue
					if not _reachable(p, (b - a).orthogonal().normalized(), ref):
						row[6] += 1
						continue
					bare += 1
					var g := _gap(p, ref)
					if g >= gap:
						gap = g
						worst = p
		row[2] += samples
		row[3] += bare
		row[5] += under
		if float(under) * STEP > BARE_MAX:
			_find("O", cls, at, float(under) * STEP, "under an overhang%s" % ((", site " + str(drawn["site"])) if drawn.has("site") else ""))
		if float(bare) * STEP > BARE_MAX:
			row[4] += 1
			_find("B", cls, worst, float(bare) * STEP, "%d of %d samples bare, the drawing %s%s" % [bare, samples, _gap_text(gap),
					(", site " + str(drawn["site"])) if drawn.has("site") else ""])


func _probe(cls: StringName, faces: PackedVector3Array, drawn: Dictionary) -> void:
	var near := false
	for seg in _foot(faces):
		near = near or Geometry2D.get_closest_point_to_segment(probe, seg[0], seg[1]).distance_to(probe) < PROBE_R
	if not near:
		return
	print("  PROBE %s %s, %d faces" % [cls, drawn, faces.size() / 3])
	for seg in _foot(faces):
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var n := maxi(1, ceili(a.distance_to(b) / STEP))
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n)
			if p.distance_to(probe) > PROBE_R:
				continue
			var ref := _surface(lerpf(seg[3], seg[4], (k + 0.5) / n), seg[2])
			var row := PackedStringArray()
			for r: float in [0.3, 0.5, 1.0, 2.0, 4.0]:
				row.append("r%.1f %s%s" % [r, "car" if _drawn_at(p, ref, r) else "-", "+over" if _drawn_at(p, ref, r, BAND_TOP, OVER_TOP) else ""])
			print("    (%.1f, %.1f) foot %.2f surface %.2f: %s" % [p.x, p.y, seg[2], ref, ", ".join(row)])


## The pocket audit for one pocket wall (its two triangles: a quad from a to b).
func _pocket(key: Vector2i, faces: PackedVector3Array, kind: String) -> void:
	var seg: Array = _foot(faces)[0]
	var a: Vector2 = seg[0]
	var b: Vector2 = seg[1]
	var length := a.distance_to(b)
	var gaps: Array[float] = []
	for e in 2:
		var p: Vector2 = seg[e]
		var ref: float = seg[3 + e]
		var at_face := _drawn_at(p, ref, POCKET_END) or _drawn_at(p, ref, POCKET_END, BAND_TOP, OVER_TOP)
		if not at_face:
			_q.collision_mask = WALL_LAYER
			at_face = _drawn_at(p, ref, POCKET_END)
			_q.collision_mask = DRAW_LAYER
		if not at_face and not _drawn_at(p, ref, POCKET_NEAR):
			_q.collision_mask = WALL_LAYER
			var near := _drawn_at(p, ref, POCKET_NEAR)
			_q.collision_mask = DRAW_LAYER
			gaps.append(POCKET_END if near else 9.9)
		else:
			gaps.append(0.0 if at_face else POCKET_END)
	var verdict := ""
	var ends_ok := gaps[0] < POCKET_NEAR and gaps[1] < POCKET_NEAR
	if not ends_ok:
		verdict = "open_end"
	elif kind == "slit":
		verdict = "slit" if _inside_gap(a, b, seg[3], seg[4]) else "wide_slit"
	elif kind == "notch":
		verdict = "notch" if length <= POCKET_NOTCH + 0.01 else "wide_notch"
	elif kind == "fairing":
		verdict = "fairing" if length <= POCKET_FAIRING else "long_fairing"
	elif kind == "bay":
		verdict = "bay"
	else:
		verdict = "unknown_kind"
	pockets[verdict] = int(pockets.get(verdict, 0)) + 1
	var mid := (a + b) * 0.5
	pocket_rows.append("%d,%d\t%.1f\t%.1f\t%s\t%.2f\t%s\t%s\t%s" % [key.x, key.y, mid.x, mid.y, kind, length,
			_gap_word(gaps[0]), _gap_word(gaps[1]), verdict])
	if verdict in ["slit", "notch", "fairing"]:
		return
	_find("P", StringName(verdict if verdict != "bay" else "bay"), mid, length, "%s, %.2f m, ends %s / %s" % [kind, length,
			_gap_word(gaps[0]), _gap_word(gaps[1])])


## A slit's wall lies in a gap under POCKET_SLIT: every metre of it within half that of a drawing.
func _inside_gap(a: Vector2, b: Vector2, ga: float, gb: float) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / STEP))
	for k in range(1, n):
		var p := a.lerp(b, float(k) / n)
		if not _drawn_at(p, lerpf(ga, gb, float(k) / n), POCKET_SLIT * 0.5):
			return false
	return true


static func _gap_word(g: float) -> String:
	return "at" if g == 0.0 else ("<1m" if g < 1.0 else "open")


## How far the nearest drawing is from a bare sample: under 1, 2 or 4 m (the value), else 99.
func _gap(p: Vector2, ref: float) -> float:
	for r: float in [1.0, 2.0, 4.0]:
		if _drawn_at(p, ref, r):
			return r
	return 99.0


static func _gap_text(g: float) -> String:
	return "nowhere within 4 m" if g > 4.0 else "within %.0f m" % g


## How far the collider stands out of the surface at its foot (m, the most along it).
func _proud(faces: PackedVector3Array) -> float:
	var most := -INF
	for i in range(0, faces.size() - 2, 3):
		var top := maxf(faces[i].y, maxf(faces[i + 1].y, faces[i + 2].y))
		var y0 := minf(faces[i].y, minf(faces[i + 1].y, faces[i + 2].y))
		for v in [faces[i], faces[i + 1], faces[i + 2]]:
			most = maxf(most, top - _surface(_ground(Vector2(v.x, v.z)), y0))
	return most


## Whether something drawn at least R2_LOW over `ref` (and under ref + BAND_TOP) lies within `r`
## of p in plan.
func _drawn_at(p: Vector2, ref: float, r: float, lo := R2_LOW, hi := BAND_TOP) -> bool:
	_cyl.radius = r
	_cyl.height = hi - lo
	_q.transform = Transform3D(Basis(), Vector3(p.x, ref + (lo + hi) * 0.5, p.y))
	return not _space.intersect_shape(_q, 1).is_empty()


## The surface a car stands on by a collider's foot `y0` (its lowest point there), `g` the ground
## there: the ground when it is near the foot (a collider is sunk 0.2-1 m into it), else the
## foot's own level (on a deck, in a tunnel).
static func _surface(g: float, y0: float) -> float:
	if g >= y0 - 0.1 and g <= y0 + 1.2:
		return g
	return y0 + 0.3


## The ground at a collider vertex as the build read it (`_g_at`), else as the map reads it now.
func _ground(p: Vector2) -> float:
	var g: Variant = _g_at.get(Vector2i(roundi(p.x * 20.0), roundi(p.y * 20.0)))
	return float(g) if g != null else float(runtime.terrain_height(p.x, p.y))


## A collider's foot in plan: per triangle, its plan's longest stretch [a, b, lowest y, the ground
## at a, at b]; the two
## halves of a wall quad give one stretch (kept once).
func _foot(faces: PackedVector3Array, high_skip := false) -> Array:
	var out: Array = []
	var seen := {}
	for i in range(0, faces.size() - 2, 3):
		var v: Array[Vector3] = [faces[i], faces[i + 1], faces[i + 2]]
		var best := -1.0
		var a := Vector2.ZERO
		var b := Vector2.ZERO
		for j in 3:
			var p := Vector2(v[j].x, v[j].z)
			var q := Vector2(v[(j + 1) % 3].x, v[(j + 1) % 3].z)
			if p.distance_to(q) > best:
				best = p.distance_to(q)
				a = p
				b = q
		var y0 := minf(v[0].y, minf(v[1].y, v[2].y))
		var ga := _ground(a)
		var gb := _ground(b)
		if high_skip and y0 > (ga + gb) * 0.5 + BAND_TOP + 0.5:
			continue  # an LoD2 wall's upper triangle: over any car on the ground
		var key := "%d,%d,%d,%d" % [roundi(minf(a.x, b.x) * 20), roundi(minf(a.y, b.y) * 20), roundi(maxf(a.x, b.x) * 20), roundi(maxf(a.y, b.y) * 20)]
		if seen.has(key):
			continue
		seen[key] = true
		out.append([a, b, y0, ga, gb])
	return out


func _plan_mid(faces: PackedVector3Array) -> Vector2:
	var c := Vector3.ZERO
	for v in faces:
		c += v
	c /= faces.size()
	return Vector2(c.x, c.z)


func _plan_length(faces: PackedVector3Array) -> float:
	var total := 0.0
	for seg: Array in _foot(faces):
		total += (seg[0] as Vector2).distance_to(seg[1])
	return total


func _find(kind: String, what: StringName, at: Vector2, metres: float, detail: String) -> void:
	var why := "counted only: a stretch under an overhang is drawn over the car, not beside it" if kind == "O" else ""
	for a: Array in ALLOW:
		if a[0] == kind and StringName(a[1]) == what and (float(a[2]) == 0.0 or metres <= float(a[2])):
			why = a[3]
			break
	findings.append([kind, what, at.x, at.y, metres, detail, why])


func _finish() -> void:
	var by_kind := {}
	var allowed := {}
	var open: Array = []
	for f: Array in findings:
		var k := "%s %s" % [f[0], f[1]]
		if f[6] == "":
			by_kind[k] = int(by_kind.get(k, 0)) + 1
			open.append(f)
		else:
			allowed[k] = int(allowed.get(k, 0)) + 1
	var names := per.keys()
	names.sort()
	var faces := 0
	var notes := 0
	for cls in names:
		var r: Array = per[cls]
		notes += int(r[0])
		faces += int(r[1])
		print("  %-14s %6d colliders %7d faces, plan test %7d samples, %5d bare, %4d failing, %5d under an overhang, %5d bare out of reach" % [cls, r[0], r[1], r[2], r[3], r[4], r[5], r[6]])
	var pk := pockets.keys()
	pk.sort()
	var pl := PackedStringArray()
	for k in pk:
		pl.append("%s %d" % [k, pockets[k]])
	print("  pockets: " + ", ".join(pl))
	print("  hard and drawn 0.3-0.8 m (R2 wants 0.8 m; later steps): %s" % [low_hard])
	print("  'same' sites taken at their word: %d%s" % [skipped_same, "" if test_all else " (--all tests them)"])
	for k in allowed:
		print("  allowed %s: %d" % [k, allowed[k]])
	if not review.is_empty():
		DirAccess.make_dir_recursive_absolute(review)
		var f := FileAccess.open(review.path_join("pockets.tsv"), FileAccess.WRITE)
		f.store_string("\n".join(pocket_rows) + "\n")
		f.close()
		var g := FileAccess.open(review.path_join("findings.tsv"), FileAccess.WRITE)
		g.store_line("kind\tclass\tx\tz\tm\tdetail\tallowed")
		for fd: Array in findings:
			g.store_line("%s\t%s\t%.1f\t%.1f\t%.1f\t%s\t%s" % [fd[0], fd[1], fd[2], fd[3], fd[4], fd[5], fd[6]])
		g.close()
		print("  review files in %s" % review)
	open.sort_custom(func(x: Array, y: Array) -> bool: return float(x[4]) > float(y[4]))
	for f: Array in open.slice(0, 40 if verbose else 15):
		print("  FINDING %s %s at --at=%.0f,%.0f: %.1f m, %s" % [f[0], f[1], f[2], f[3], f[4], f[5]])
	runtime.free()
	for p in problems:
		print("  PROBLEM " + p)
	if open.is_empty() and problems.is_empty():
		print("check_colliders: OK (%d sectors, %d colliders, %d faces in %d classes; %d findings allowed by rule; %d ms)" % [
				keys.size(), notes, faces, names.size(), findings.size(), Time.get_ticks_msec() - _t0])
		quit(0)
	else:
		print("check_colliders: %d findings (%s), %d problems" % [open.size(), by_kind, problems.size()])
		quit(1)
