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
##   godot --headless --path game --script res://tools/check_solids.gd [-- --verbose --record --barriers=typed]

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
## 2026-11-14: +36 faces, the pocket hedge at Most Poniatowskiego (city_barriers.gd POCKET_HEDGES, PT-54).
## 2026-11-14, step 7: -6925 faces (53183 → 46258), the S fences and hedges have no collider now
## (soft_things.gd breaks them; their segments are the sector's `soft` list, check_soft_things);
## with them hard again (`--no-soft`: CityBarriers.soft_off, SoftThings.harden) the faces are main's.
## 2026-11-14, step 7 review: +320 faces (46258 → 46578), S lines kept hard again: inside or within
## 10 m of a landmark site's ring (city_barriers.gd LANDMARK_GUARD) and road_objects.json hard_lines.
## 2026-11-15, step 8a: unchanged: the parked cars' colliders are still filed (`Solid_parked`, main's
## faces); soft_things.gd turns that body off when the soft things are on (check_soft_things M2-M4).
## 2026-11-15, Narodowy grounds: +8 faces (46578 → 46586), the gates' four piers as hard boxes; the perimeter fence keeps its smash class (soft lines file no faces here).
## 2026-11-15, step 8b: -84 faces (46586 → 46502, measured after merging the Narodowy grounds
## and the phone's place data, #818),
## tools/parked_thin.py took 11 parked cars out of these sectors (8 faces a car, filed by face
## centre, so a car on a sector's border counts in part).
## 2026-11-15, Plac Defilad (#848): +260 faces (46502 → 46762), the TR site's wider plot, the
## market moved into sector (-2, 0) (a box per hut, the van, the tree) and the candelabras' pedestals.
## 2026-11-17, the obelisk's semicircle (#914, tools/defilad_obelisk.py): -8 faces (46762 → 46754), its
## garage door and the ramp's walls taken off; TOTAL_TYPED 46573 → 46565 the same way (each its own `--record`).
## 2026-11-19, Metro Centrum's glass pavilion (#933): -44 faces (46754 → 46710), the pavilion's ring replaces its
## box, and the two little boxes and the two plain fences beside it go; TOTAL_TYPED 46565 → 46533 the same way.
## 2026-11-19, Hotel Metropol (#942): -74 faces (46710 → 46636), the street block blk_28759009 (#495) on the
## hotel's outline is no longer built (a second model over METROPOLKA); the hotel's own site keeps its walls.
## TOTAL_TYPED 46533 → 46459 the same way (each its own `--record` on a fresh bake after merging #933).
## 2026-11-21, Teatr Ateneum as the whole L-block and Lipowa 1A (#988): -49 faces (46636 → 46587), the 47 m
## strip and the block's old masses under the theatre give way to its own ring; TOTAL_TYPED 46459 → 46406 the same way.
## 2026-11-21, Jarmark Warszawski 2026 (#980): +1127 faces (46636 → 47763), the finished market's chalets, stands,
## rides' bases and the tree platform on Plac Defilad and Plac Centralny (the car park's parked cars cleared under
## it); TOTAL_TYPED 46459 → 47586 the same way (each its own `--record` on a fresh bake of the branch).
## Merged (main 1d3a3ff with #988, then #980): both measured again with their own `--record` on a fresh bake
## of the merge: TOTAL 47714 (46636 - 49 + 1127), TOTAL_TYPED 47533 (46459 - 53 + 1127).
## 2026-11-22, Jarmark from the official map and Santa's Workshop (#1006): +3 faces in (-2, 0) (47714 → 47717),
## the market's kit landmarks (the CI's fresh bake has both paths equal; TOTAL_TYPED not measured again here).
## 2026-11-22 (#1008, Pasaż Wiecha at Christmas): +96 faces (47717 → 47813), the decorations' colliders
## (the photo frames, the gingerbread tunnel's rails, the neon fir, the wire bauble, the bauble benches)
## in sector -2,0, `--record` on a fresh bake of the branch after merging main, both paths equal;
## TOTAL_TYPED not measured again here.
## 2026-11-23 (Jarmark parked cars, F's Play 14 report): -53 faces in (-2, 0) (47813 → 47760), the parked
## cars on Plac Centralny cleared under the market's rides and chalets (jarmark.gd JM_PARK_FREE).
## 2026-11-26 (#1099, Rondo Dmowskiego): +194 faces (47760 → 47954), the twelve sunken stairwells' edge
## colliders (site `rondo_wells`), the lifts and the square's beds, less the old tubes and wall lines on
## the rings; measured on a fresh bake of the branch after merging main.
## 2026-11-26 (Ufficio Primo, #1096): -10 faces (47954 → 47944 after #1099), the street block blk_25911097's
## colliders out under the new site (its ring's own walls in their place), `--record` on a fresh bake
## of the branch after merging main; TOTAL_TYPED not measured again here.
## 2026-11-26 (double models, check_sites DRESSES_BLOCK): Marszałkowska 99's street block
## (blk_338542425) no longer drawn under its landmark in (-2, 1): -46 faces, 47944 → 47898, `--record` on
## a fresh bake of the branch after merging main.
## 2026-11-27 (house types, parked cars by zone #1111): -17 faces (47898 → 47881), the parked cars
## the Ściana Wschodnia and Śródmieście Północne zones thin out in (-2, 0) and (-2, 1)
## (HouseTypes.keeps_parked); measured on the runtime path before the merge (47760 → 47743).
## 2026-11-27 (#1107, the metro wells): +66 faces (47881 → 47947), the other stations' 37 sunken wells'
## edge and mouth colliders (sites `mw_*`), less the wall lines on their rings; `--record` on a fresh bake
## of the branch after merging main; TOTAL_TYPED not measured again here.
const TOTAL := 47947
## W2 of the walls look (2026-11-15): the same sectors built with `--barriers=typed` (the palette's key
## stays classic, so verify runs TOTAL): -147 faces, the typed fences' rails collide with one face
## per segment as railing_along's do (a slab has two), the `removed` fragments are not drawn. The
## soft lines are the same. Moves with TOTAL (a re-bake): `--record --barriers=typed` prints it.
## 2026-11-15, Plac Defilad (#848): 46355 → 46573 with the same sites (measured with `--record
## --barriers=typed` on a fresh bake after merging main 85090c58).
## W3 of the walls look (2026-11-15, tools/object_types.py v2): both measured again on the retyped map
## (each with its own `--record` run, never one from the other): TOTAL 46762 and TOTAL_TYPED 46573
## (after merging main with Plac Defilad #848), unchanged by W3: the stadium's retyped lines keep their look and class (soft, no faces), and the other
## fixes change no face in these sectors (the planter edges by the Palace of Culture in (-2, 0) keep
## a placed style).
## W8 of the walls look (2026-11-20, tools/barrier_gates.py): measured again with its own `--record
## --barriers=typed` on the gated map: 46459, unchanged (of the 16 gaps in these six sectors 13 cut
## soft fences, which file no faces; the walls' 3 sit on OSM's gate node, a vertex, so the segments on
## each side are shorter but as many; the gate posts file none). TOTAL (classic) ignores the gates.
## 2026-11-26 (double models): 47717 with the same block gone (-46), measured with its own
## `--record --barriers=typed` on a fresh bake after merging main (Rondo #1099, Ufficio #1096).
const TOTAL_TYPED := 47717

var problems: Array[String] = []
var verbose := false
var record := false


func _initialize() -> void:
	# W2 of the walls look: --barriers=classic|typed builds the city in that look (the palette's by default).
	Solidity.barrier_look_from(OS.get_cmdline_user_args())
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
	var want := TOTAL_TYPED if Solidity.barrier_look() != &"classic" else TOTAL
	var name := "TOTAL_TYPED" if Solidity.barrier_look() != &"classic" else "TOTAL"
	if total != want:
		problems.append("S1 the sectors' faces: %d, recorded %d (a re-bake or a collider change: record it in %s)" % [total, want, name])
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
		print("solids: --record: %s := %d" % ["TOTAL_TYPED" if Solidity.barrier_look() != &"classic" else "TOTAL", total])
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
	# A place script (place.gd) takes what main.gd hands it from `ctx`; the map's data for ratusz_hub.
	if not data.is_empty():
		node.set("ctx", {"data": data})
	node.name = (node.get_script() as Script).resource_path.get_file().get_basename()
	root.add_child(node)
	node.call("build")
	return node
