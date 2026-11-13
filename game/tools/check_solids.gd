extends SceneTree
## The city objects plan, step 1 (docs/design/city-objects-plan.md; build plan item 0): every
## collider face of the city knows its class (scripts/solidity.gd, data/object_palette.json).
##   S1 in each of SECTORS, the faces per class are the same on the runtime path (map_builder.gd
##      build_sector) and the prebuilt path (map/sectors/s_<i>_<j>.scn), and their total is TOTAL;
##   S2 every StaticBody3D in those sectors is a class's body: named Solid_<class>, with
##      meta "solid" = a class solidity.gd knows, and nothing but its own class's shapes;
##   S3 the map's own bodies (the edge walls, Edges; the roadworks' Barriers) carry `edge`, on
##      both paths (index.json built, index.res loaded);
##   S4 the dressing scripts' bodies (street_details.gd, park_details.gd with monuments.gd's,
##      tamka.gd, plac_pieciu_rogow.gd, skwer_zlota.gd, ratusz_hub.gd) carry a known class.
## TOTAL moves only with the map (a re-bake, a collider added or taken out on purpose): record the
## new number here with the reason (`--record` prints it).
## Prints `solids: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_solids.gd [-- --verbose --record]

const MapBuilder := preload("res://scripts/map_builder.gd")
const Solidity := preload("res://scripts/solidity.gd")
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
const StreetDetails := preload("res://scripts/street_details.gd")
const ParkDetails := preload("res://scripts/park_details.gd")
const Tamka := preload("res://scripts/tamka.gd")
const PlacPieciuRogow := preload("res://scripts/plac_pieciu_rogow.gd")
const SkwerZlota := preload("res://scripts/skwer_zlota.gd")
const RatuszHub := preload("res://scripts/ratusz_hub.gd")

## The sectors compared: Stadion Narodowy's grounds (3,-1 and 2,-1: fences, hedges, walls, the
## stands), Marszałkowska and the spawn (-2,0 and -2,1: buildings, LoD2, parked cars, shelters),
## Most Poniatowskiego's viaduct and the river (0,0 and 1,-1: piers, decks, guard rails, the shore).
const SECTORS: Array[Vector2i] = [Vector2i(3, -1), Vector2i(2, -1), Vector2i(-2, 0), Vector2i(-2, 1),
		Vector2i(0, 0), Vector2i(1, -1)]
## The faces of SECTORS together (2026-11-13, step 1: the colliders as main 2638826 had them, the
## same face set per sector before and after the split by class).
const TOTAL := 53147

var problems: Array[String] = []
var verbose := false
var record := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--verbose":
			verbose = true
		elif a == "--record":
			record = true
	var t0 := Time.get_ticks_msec()
	if Solidity.classes().is_empty():
		problems.append("S2 solidity.gd has no classes (%s)" % Solidity.PALETTE)
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var runtime: Node3D = MapBuilder.new()
	runtime.name = "City"
	root.add_child(runtime)
	runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var prebuilt: Node3D = null
	if ResourceLoader.exists("res://map/index.res"):
		prebuilt = (load("res://map/index.res") as PackedScene).instantiate()
	else:
		problems.append("S1 no prebuilt city (map/index.res): run tools/setup_map.sh")
	# S1, S2: the sectors on both paths.
	var total := 0
	var classes_seen := {}
	for key in SECTORS:
		var built: Node3D = runtime.build_sector(key)
		var a := _faces(built, "runtime %s" % key)
		built.free()
		var b := {}
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if prebuilt != null and ResourceLoader.exists(path):
			var inst := (load(path) as PackedScene).instantiate()
			b = _faces(inst, "prebuilt %s" % key)
			inst.free()
		elif prebuilt != null:
			problems.append("S1 %s: no prebuilt sector %s" % [key, path])
		for cls: StringName in a:
			total += int(a[cls])
			classes_seen[cls] = int(classes_seen.get(cls, 0)) + int(a[cls])
		if prebuilt != null and a != b:
			problems.append("S1 %s: faces per class differ: runtime %s, prebuilt %s" % [key, a, b])
		if verbose:
			print("  %s: %s" % [key, a])
	if total != TOTAL:
		problems.append("S1 the sectors' faces: %d, recorded %d (a re-bake or a collider change: record it in TOTAL)" % [total, TOTAL])
	# S3: the map's own bodies.
	_edges(runtime, "runtime")
	if prebuilt != null:
		root.add_child(prebuilt)
		EdgeRoadworks.rebuild(prebuilt)
		_edges(prebuilt, "prebuilt")
	# S4: the dressing scripts (built at runtime on both paths, from the map's heights).
	var dressing := 0
	for maker: Callable in [
			func() -> Node3D: return _dress(StreetDetails.new(), runtime),
			func() -> Node3D: return _dress(ParkDetails.new(), runtime),
			func() -> Node3D: return _dress(Tamka.new(), runtime),
			func() -> Node3D: return _dress(PlacPieciuRogow.new(), runtime),
			func() -> Node3D: return _dress(SkwerZlota.new(), runtime),
			func() -> Node3D: return _dress(RatuszHub.new(), runtime, index)]:
		var node: Node3D = maker.call()
		dressing += _check_bodies(node, "dressing %s" % node.name, false)
		node.free()
	if record:
		print("solids: --record: TOTAL := %d" % total)
	var names := classes_seen.keys()
	names.sort()
	var per := PackedStringArray()
	for cls in names:
		per.append("%s %d" % [cls, classes_seen[cls]])
	if problems.is_empty():
		print("solids: OK (%d sectors, %d faces in %d classes, the same on both paths; %d dressing bodies classed; %d ms)" % [
				SECTORS.size(), total, names.size(), dressing, Time.get_ticks_msec() - t0])
		if verbose:
			print("  " + ", ".join(per))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("solids: %d problems" % problems.size())
		quit(1)


## A sector root's collider faces by class ({class: faces}), its bodies checked (S2).
func _faces(sector: Node, where: String) -> Dictionary:
	var out := {}
	_check_bodies(sector, where, true)
	for n in sector.find_children("*", "StaticBody3D", true, false):
		if n is AnimatableBody3D:
			continue
		var cls := StringName(str(n.get_meta("solid", "")))
		for cs in n.find_children("*", "CollisionShape3D", true, false):
			var shape := (cs as CollisionShape3D).shape
			var count := 0
			if shape is ConcavePolygonShape3D:
				count = (shape as ConcavePolygonShape3D).get_faces().size() / 3
			elif shape != null:
				count = 1
			out[cls] = int(out.get(cls, 0)) + count
	return out


## Every StaticBody3D under `node` carries a known class (S2, S3, S4); in a sector, named after
## it. The number of bodies looked at.
func _check_bodies(node: Node, where: String, sector: bool) -> int:
	var n := 0
	for b in node.find_children("*", "StaticBody3D", true, false):
		if b is AnimatableBody3D:
			continue
		n += 1
		if not b.has_meta("solid"):
			problems.append("S2 %s: body %s has no \"solid\" meta" % [where, node.get_path_to(b)])
			continue
		var cls := StringName(str(b.get_meta("solid")))
		if not Solidity.is_known(cls):
			problems.append("S2 %s: body %s's class %s is not in solidity.gd" % [where, node.get_path_to(b), cls])
		if sector and str(b.name) != "Solid_" + str(cls):
			problems.append("S2 %s: body %s carries class %s" % [where, b.name, cls])
	return n


## The edge walls (Edges) and the roadworks' barriers carry `edge` (S3).
func _edges(map: Node3D, where: String) -> void:
	for path in ["Edges", "EdgeRoadworks/Barriers"]:
		var b := map.get_node_or_null(path)
		if b == null:
			problems.append("S3 %s: no %s on the map" % [where, path])
		elif StringName(str(b.get_meta("solid", ""))) != &"edge":
			problems.append("S3 %s: %s carries %s, not edge" % [where, path, b.get_meta("solid", "nothing")])


func _dress(node: Node3D, map: Node3D, data := {}) -> Node3D:
	node.set("map", map)
	node.name = (node.get_script() as Script).resource_path.get_file().get_basename()
	root.add_child(node)
	if node.has_method("build") and data.is_empty():
		node.call("build")
	else:
		node.call("build", data)
	return node
