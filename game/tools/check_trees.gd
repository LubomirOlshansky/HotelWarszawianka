extends SceneTree
## Trees thread (F, 2026-11-15, Fable's review F13): the trees' kinds, their table and the season
## rule, without building the city (the quick group: only the committed centrum.json).
##
## 1. Every TreeKind has a TREE_LOOK row (two colours, fall start and length in 0-1, the share
##    kept in 0-1), there are at most 16 (the shader's table is 16 wide), and foliage.gdshader's
##    silhouette arrays hold one entry per broadleaf kind (TreeKind.SPRUCE of them).
## 2. Nothing seasonal goes into the instance data: a tree's custom data and colour are the same
##    whatever `season` the builder has, so the prebuilt sectors follow the game's date
##    (`tree_season`, a shader global in project.godot).
## 3. The guessed kinds over the map's scanned trees: every broadleaf kind in the pool shows up,
##    poplars at most 4 % and birches at most 8 % (Fable: shape rules over-claimed; the scan's
##    radius turned out to follow the height, so the guess is by place), and the
##    same tree gets the same kind twice (the runtime and prebuilt paths build from one function).
##
## Prints the kinds' shares and `check_trees: OK`; else the problems and exit 1.
##   godot --headless --path game --script res://tools/check_trees.gd

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"
const POPLAR_MAX := 0.04
const BIRCH_MAX := 0.08


func _initialize() -> void:
	var problems: Array[String] = []
	var map: Node3D = MapBuilder.new()
	var kinds: Dictionary = MapBuilder.TreeKind
	# 1. The table.
	if kinds.size() > 16:
		problems.append("%d tree kinds, the shader's table holds 16" % kinds.size())
	for name: String in kinds:
		var kind: int = kinds[name]
		if not MapBuilder.TREE_LOOK.has(kind):
			problems.append("TreeKind.%s has no TREE_LOOK row" % name)
			continue
		var row: Array = MapBuilder.TREE_LOOK[kind]
		if row.size() != 5 or Color.from_string(String(row[0]), Color(0, 0, 0, 0)).a == 0.0 \
				or Color.from_string(String(row[1]), Color(0, 0, 0, 0)).a == 0.0:
			problems.append("TreeKind.%s: TREE_LOOK row %s" % [name, row])
			continue
		for k in [2, 3, 4]:
			if float(row[k]) < 0.0 or float(row[k]) > 1.0:
				problems.append("TreeKind.%s: TREE_LOOK value %s outside 0-1" % [name, row[k]])
	var shader := FileAccess.get_file_as_string("res://shaders/foliage.gdshader")
	for arr in ["S_LOW", "S_HIGH", "S_TAPER", "S_WIDE", "S_DROOP", "S_LUMPY"]:
		var want := "const float %s[%d]" % [arr, MapBuilder.TreeKind.SPRUCE]
		if not shader.contains(want):
			problems.append("foliage.gdshader has no `%s` (one per broadleaf kind)" % want)
	if not ProjectSettings.has_setting("shader_globals/tree_season"):
		problems.append("project.godot has no shader global tree_season")
	# 2. No season in the instance data.
	for i in 50:
		var h := fposmod(i * 0.6180339, 1.0)
		map.season = "autumn"
		var a := [map._tree_custom(i % 11, h), map._tree_colour(h)]
		map.season = "summer"
		var b := [map._tree_custom(i % 11, h), map._tree_colour(h)]
		if a != b:
			problems.append("a tree's instance data changes with the season: %s / %s" % [a, b])
			break
	# 3. The guessed kinds on the map's trees.
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	var real: Array = (data as Dictionary).get("trees3d", []) if data is Dictionary else []
	if real.is_empty():
		problems.append("no trees3d in " + MAP_PATH)
	var count := {}
	var broad := 0
	for i in range(0, real.size() - 5, 6):
		var x := float(real[i])
		var z := float(real[i + 1])
		var top := float(real[i + 2])
		var base := minf(float(real[i + 4]), top - 1.5)
		var needle := int(real[i + 5]) == 1
		var kind: int = map._tree_kind(x, z, top, float(real[i + 3]), base, needle)
		if kind != map._tree_kind(x, z, top, float(real[i + 3]), base, needle):
			problems.append("the kind at %.1f, %.1f is not the same twice" % [x, z])
		count[kind] = int(count.get(kind, 0)) + 1
		if kind < MapBuilder.TreeKind.SPRUCE:
			broad += 1
	var shares: Array[String] = []
	for name: String in kinds:
		var n: int = count.get(kinds[name], 0)
		shares.append("%s %d" % [name.to_lower(), n])
	print("check_trees: %d trees: %s" % [real.size() / 6, ", ".join(shares)])
	for row: Array in MapBuilder.TREE_POOL:
		if int(count.get(int(row[0]), 0)) == 0:
			problems.append("no tree of pool kind %d on the map" % int(row[0]))
	if broad > 0:
		var poplar := float(count.get(MapBuilder.TreeKind.POPLAR, 0)) / broad
		var birch := float(count.get(MapBuilder.TreeKind.BIRCH, 0)) / broad
		if poplar > POPLAR_MAX:
			problems.append("poplars are %.1f %% of the broadleaf trees (at most %.0f %%)" % [poplar * 100.0, POPLAR_MAX * 100.0])
		if birch > BIRCH_MAX:
			problems.append("birches are %.1f %% of the broadleaf trees (at most %.0f %%)" % [birch * 100.0, BIRCH_MAX * 100.0])
	map.free()
	for p in problems:
		print("check_trees: PROBLEM " + p)
	if problems.is_empty():
		print("check_trees: OK")
	quit(0 if problems.is_empty() else 1)
