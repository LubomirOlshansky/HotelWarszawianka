extends SceneTree
## W2 of the walls look (docs/design/walls-true-to-life.md 6.1-6.3; city-objects-plan.md 5.2, step
## 9a): the palette's `looks` rows and the typed drawing (city_barriers.gd `_typed`,
## `rail_lite_along`), behind the key `barrier_look`.
##   1 the palette's `barrier_look` is classic: testers' builds stay as main draws them (the pull
##     request that changes the default changes this line too);
##   2 every `ty` on a fence, wall or hedge line of map/centrum.json has a `looks` row; every row
##     has the keys its `draw` needs (rail: h, colour, post {every, w}, rails; slab: h, thick,
##     colour; every drawn row a family); every `post.every` is 2 or 4 (a multiple of the 2 m
##     panel soft_things.gd remembers); every colour parses; `alt` shares add up to at most 1;
##   3 on a flat synthetic map, one line per draw kind built by build_barriers under typed: `rail`
##     makes 4 x posts + 2 x rails x segments triangles (its foot, where the row has one, wall_along's
##     10 a segment) and the same collider faces as railing_along at that height; `slab` makes what
##     wall_along makes at the row's thickness and the line's height; `none` makes nothing; `keep`,
##     an unknown type and a line a rule gave its look (`st`) make what classic makes;
##   4 the same line built twice gets the same `alt` colour, and the colour follows its stable id;
##   5 the whole map's lines built under typed on the flat map: none drawn classic for want of a
##     row (`unknown`) and none in barrier_default; the count of lines per draw kind is printed;
##   6 W4 (walls doc 6.4): under panels, on the flat synthetic map, a line of each panel draw kind
##     (a rail row, one with a foot, a slab row; hard and soft) makes no triangles in the city mesh
##     and the very collider faces and soft list typed makes; its panel pieces are cut at every 2 m
##     of the line's run and at its corners, each with its panel index (soft_things.gd's), its
##     row, its run and its seed, the soft line's first instance and count in its tile's meta;
##     under classic and typed no piece is made; the whole city's build (no sector) makes its
##     `Panels_i_j` node with the pieces and the panel material;
##   7 W4: the whole map under panels on the flat map: the collider faces per class are typed's,
##     face for face (the cars meet the same fences), every line of a panel row is drawn as
##     panels and none of another; the pieces are printed;
##   8 with `--paths` (verify step `barrierpaths`, the prebuilt city needed): in each of the
##     sectors (check_colliders.gd's ten; `--all` every sector) the runtime build in the look the
##     prebuilt city was baked in (map/sectors/city.stamp) has the prebuilt sector's city mesh
##     vertices and its `Panels` pieces (walls doc 9: the two city paths agree).
## Prints `check_barrier_look: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_barrier_look.gd [-- --paths [--all]]

const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const Chunked := preload("res://scripts/chunked_surface.gd")
const PanelRule := preload("res://scripts/panel_rule.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const PANEL_RHYTHMS := [2.0, 4.0]
## 8: check_colliders.gd's ten sectors (the stadium's grounds, Marszałkowska and the spawn,
## Poniatowski's viaduct and the river, the Old Town, Powiśle, Centralna's cutting, Praga).
const PATH_SECTORS: Array[Vector2i] = [Vector2i(3, -1), Vector2i(2, -1), Vector2i(-2, 0), Vector2i(-2, 1),
		Vector2i(0, 0), Vector2i(1, -1), Vector2i(-2, -3), Vector2i(0, -1), Vector2i(-3, 0), Vector2i(0, -2)]


## A flat world: the wall builder's terrain is 0 everywhere.
class FlatMap extends "res://scripts/map_builder.gd":
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []


func _initialize() -> void:
	if "--paths" in OS.get_cmdline_user_args():
		_paths("--all" in OS.get_cmdline_user_args())
		return
	var palette: Variant = JSON.parse_string(FileAccess.get_file_as_string(Solidity.PALETTE))
	# 1: the key.
	if not palette is Dictionary or str((palette as Dictionary).get("barrier_look", "")) != "classic":
		problems.append("1 the palette's barrier_look is %s, not classic" % (palette as Dictionary).get("barrier_look", "missing") if palette is Dictionary else "1 no palette")
	# 2: the rows.
	_rows()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var types := {}
	if data is Dictionary:
		for l: Dictionary in (data as Dictionary).get("lines", []):
			if str(l["k"]) in ["fence", "wall", "hedge"]:
				var ty := str(l.get("ty", ""))
				types[ty] = int(types.get(ty, 0)) + 1
	else:
		problems.append("2 no map data (res://map/centrum.json)")
	for ty: String in types:
		if Solidity.look_row(StringName(ty)).is_empty():
			problems.append("2 type %s (%d lines) has no looks row" % [ty if ty != "" else "(none)", types[ty]])
	# 3, 4: the synthetic map; 5: the whole map's lines.
	Solidity.set_barrier_look(&"typed")
	var map := FlatMap.new()
	_kinds(map)
	_alt(map)
	var counts := {}
	var panels := {}
	_panels(map)
	if data is Dictionary:
		counts = _whole(map, data)
		panels = _whole_panels(map, data)
	map.free()
	Solidity.set_barrier_look(&"classic")
	if problems.is_empty():
		print("check_barrier_look: OK (%d look rows, %d types on the map; the whole map typed on a flat map: %s; under panels: %s)" % [
				Solidity.looks().size(), types.size(), counts, panels])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_barrier_look: %d problems" % problems.size())
		quit(1)


## 2: every row's keys by its draw, the posts' rhythm, the colours, the alt shares.
func _rows() -> void:
	if Solidity.looks().is_empty():
		problems.append("2 the palette has no looks rows")
	for id in Solidity.looks():
		var row := Solidity.look_row(id)
		var draw := str(row["draw"])
		if not draw in ["rail", "slab", "keep", "none"]:
			problems.append("2 %s: unknown draw %s" % [id, draw])
			continue
		if not row.has("family"):
			problems.append("2 %s: no family" % id)
		var needs: Array = {"rail": ["h", "colour", "post", "rails"], "slab": ["h", "thick", "colour"]}.get(draw, [])
		for key: String in needs:
			if not row.has(key):
				problems.append("2 %s (%s): no %s" % [id, draw, key])
		if row.has("post"):
			var post: Dictionary = row["post"]
			if not float(post.get("every", 0.0)) in PANEL_RHYTHMS:
				problems.append("2 %s: post.every %s is not 2 or 4" % [id, post.get("every")])
			if draw == "rail" and not float(post.get("w", 0.0)) > 0.0:
				problems.append("2 %s: no post width" % id)
		if row.has("h_range") and float(row["h_range"][0]) > float(row["h_range"][1]):
			problems.append("2 %s: h_range %s" % [id, row["h_range"]])
		var share := 0.0
		for a: Array in row.get("alt", []):
			share += float(a[1])
		if share > 1.0:
			problems.append("2 %s: the alt shares add up to %.2f" % [id, share])
		_colours(str(id), row)


## Every string in `v` that begins with "#" must be a colour.
func _colours(where: String, v: Variant) -> void:
	if v is Dictionary:
		for k: Variant in v:
			_colours(where + "." + str(k), v[k])
	elif v is Array:
		for x: Variant in v:
			_colours(where, x)
	elif v is String and (v as String).begins_with("#") and not Color.html_is_valid(v):
		problems.append("2 %s: %s is not a colour" % [where, v])


## A barrier line of kind `k` along flat points `p` with the extra keys of `extra`.
func _line(k: String, p: Array, extra := {}) -> Dictionary:
	var l := {"k": k, "p": p, "sc": "H"}
	l.merge(extra, true)
	return l


## build_barriers over `lines` on the flat map in `look`: [triangles, {class: faces}, the barriers].
func _build(map: Node3D, lines: Array, look: StringName) -> Array:
	Solidity.set_barrier_look(look)
	map.data = {"lines": lines}
	map._solids = {}
	var st := Chunked.new()
	map.barriers.build_barriers(st)
	var faces := {}
	for cls: StringName in map._solids:
		faces[cls] = (map._solids[cls] as PackedVector3Array).size() / 3
	Solidity.set_barrier_look(&"typed")
	return [st.vertex_count / 3, map._solids.duplicate(true), faces]


## 3: one line per draw kind.
func _kinds(map: Node3D) -> void:
	# Far from every place rule (the Palace, the tribune, the gardens): a plain spot, built as a
	# sector there (so the pocket hedges at Most Poniatowskiego, drawn by every whole build, stay out).
	map._in_sector = true
	map._sector_rect = Rect2(2800.0, 2800.0, 512.0, 512.0)
	var p := [3000.0, 3000.0, 3005.0, 3000.0, 3005.0, 3003.2]
	var pts := PackedVector2Array([Vector2(3000, 3000), Vector2(3005, 3000), Vector2(3005, 3003.2)])
	var segs := 2
	var length := 8.2
	# rail, no foot (fence_plain: posts every 2 m, two rails).
	var row := Solidity.look_row(&"fence_plain")
	var h := 1.3
	var got := _build(map, [_line("fence", p, {"ty": "fence_plain", "hs": h})], &"typed")
	var every := float(row["post"]["every"])
	var posts := floori(length / every) + 1 + (1 if fmod(length, every) > 0.05 else 0)
	var want := 4 * posts + 2 * int(row["rails"]) * segs
	if int(got[0]) != want:
		problems.append("3 rail: %d triangles, want 4 x %d posts + 2 x %d rails x %d segments = %d" % [got[0], posts, row["rails"], segs, want])
	map._solids = {}
	map.barriers.railing_along(Chunked.new(), pts, h, 0.0, Color.BLACK, Color.BLACK, true, &"fence")
	if (got[1] as Dictionary).get(&"fence", PackedVector3Array()) != map._solids.get(&"fence", PackedVector3Array()):
		problems.append("3 rail: its collider faces are not railing_along's at %.2f m (%s against %d)" % [h, got[2],
				(map._solids.get(&"fence", PackedVector3Array()) as PackedVector3Array).size() / 3])
	# rail with a foot (bars_black): the foot is wall_along's 10 triangles a segment.
	var bars := Solidity.look_row(&"bars_black")
	got = _build(map, [_line("fence", p, {"ty": "bars_black"})], &"typed")
	var bevery := float(bars["post"]["every"])
	var bposts := floori(length / bevery) + 1 + (1 if fmod(length, bevery) > 0.05 else 0)
	want = 4 * bposts + 2 * int(bars["rails"]) * segs + 10 * segs
	if int(got[0]) != want:
		problems.append("3 rail with a foot: %d triangles, want %d" % [got[0], want])
	# slab (hedge_low at its hs): wall_along at the row's thickness.
	var hedge := Solidity.look_row(&"hedge_low")
	got = _build(map, [_line("hedge", p, {"ty": "hedge_low", "hs": 0.7})], &"typed")
	map._solids = {}
	var st := Chunked.new()
	map.barriers.wall_along(st, pts, float(hedge["thick"]), 0.7, Color(str(hedge["colour"])), true, &"hedge")
	if int(got[0]) != st.vertex_count / 3 or (got[1] as Dictionary).get(&"hedge") != map._solids.get(&"hedge"):
		problems.append("3 slab: %d triangles %s, wall_along makes %d" % [got[0], got[2], st.vertex_count / 3])
	# none: nothing.
	got = _build(map, [_line("fence", p, {"ty": "removed"})], &"typed")
	if int(got[0]) != 0 or not (got[1] as Dictionary).is_empty():
		problems.append("3 none: %d triangles, faces %s" % [got[0], got[2]])
	# keep, an unknown type and a placed `st`: what classic makes.
	for extra: Dictionary in [{"ty": "rail_tram"}, {"ty": "no_such_type"}, {"ty": "fence_plain", "st": "tram_railing"}]:
		var typed := _build(map, [_line("fence", p, extra)], &"typed")
		var classic := _build(map, [_line("fence", p, extra)], &"classic")
		if typed[0] != classic[0] or typed[1] != classic[1]:
			problems.append("3 %s: typed makes %d triangles %s, classic %d %s" % [extra, typed[0], typed[2], classic[0], classic[2]])
	map._in_sector = false


## 4: the alt colour is the line's, every time, and follows its id.
func _alt(map: Node3D) -> void:
	var b: RefCounted = map.barriers
	var seen := {}
	for i in 40:
		var l := _line("fence", [100.0 + i * 10.0, 50.0, 104.0 + i * 10.0, 50.0], {"ty": "mesh_panel"})
		var a: Dictionary = b._typed(l, true)
		var again: Dictionary = b._typed(l.duplicate(true), true)
		if a.get("colour") != again.get("colour"):
			problems.append("4 the same line got %s and %s" % [a.get("colour"), again.get("colour")])
		seen[a.get("colour")] = true
	if seen.size() < 2:
		problems.append("4 forty mesh_panel lines got one colour (the alt share is 0.4): %s" % seen.keys())


## 5: the whole map's lines under typed, on the flat map: the lines per draw kind.
func _whole(map: Node3D, data: Dictionary) -> Dictionary:
	Solidity.set_barrier_look(&"typed")
	map.data = data
	map._solids = {}
	map.barriers.build_barriers(Chunked.new())
	var counts := {}
	for k: StringName in map.barriers.look_counts:
		counts[str(k)] = map.barriers.look_counts[k]
	if int(counts.get("unknown", 0)) > 0:
		problems.append("5 %d lines drawn classic for want of a looks row" % counts["unknown"])
	if int(map.barriers.default_lines) > 0:
		problems.append("5 %d lines drawn in barrier_default" % map.barriers.default_lines)
	map._solids = {}
	map.data = {}
	return counts


## 6: the panel draw kinds on the flat synthetic map, in a sector far from every place rule.
func _panels(map: Node3D) -> void:
	map._in_sector = true
	map._sector_rect = Rect2(2560.0, 2560.0, 512.0, 512.0)
	map._sector = Vector2i(5, 5)
	var p := [3000.0, 3000.0, 3005.0, 3000.0, 3005.0, 3003.2]
	# Runs 0..5 and 5..8.2: pieces 0-2, 2-4, 4-5 | 5-6, 6-8, 8-8.2, panels 0, 1, 2, 2, 3, 4.
	var want_runs: Array[float] = [0.0, 2.0, 4.0, 5.0, 6.0, 8.0]
	var want_panels: Array[int] = [0, 1, 2, 2, 3, 4]
	var b: RefCounted = map.barriers
	for case: Array in [["fence", "fence_plain", 1.3], ["fence", "bars_black", -1.0], ["hedge", "hedge_low", 0.7]]:
		for sc: String in ["H", "S"]:
			var extra := {"ty": case[1], "sc": sc}
			if float(case[2]) > 0.0:
				extra["hs"] = case[2]
			var l := _line(str(case[0]), p, extra)
			var typed := _build(map, [l], &"typed")
			var typed_soft: Dictionary = b.soft_data()
			if not (b.panel_tiles as Dictionary).is_empty():
				problems.append("6 %s: typed made panel pieces" % case[1])
			var classic := _build(map, [l], &"classic")
			if not (b.panel_tiles as Dictionary).is_empty():
				problems.append("6 %s: classic made panel pieces" % case[1])
			var panels := _build(map, [l], &"panels")
			var what := "%s (%s)" % [case[1], sc]
			if int(panels[0]) != 0:
				problems.append("6 %s: %d triangles in the city mesh under panels" % [what, panels[0]])
			if panels[1] != typed[1]:
				problems.append("6 %s: collider faces %s under panels, %s typed" % [what, panels[2], typed[2]])
			if var_to_str(b.soft_data()) != var_to_str(typed_soft):
				problems.append("6 %s: the soft list differs from typed's" % what)
			if int(classic[0]) == 0:
				problems.append("6 %s: classic drew nothing" % what)
			var tiles: Dictionary = b.panel_tiles
			if tiles.size() != 1 or not tiles.has(Vector2i(5, 5)):
				problems.append("6 %s: pieces in tiles %s, want (5, 5)" % [what, tiles.keys()])
				continue
			var t = tiles[Vector2i(5, 5)]
			var n: int = t.buf.size() / CityBarriers.PANEL_FLOATS
			if n != want_runs.size() or int(b.panel_pieces) != n:
				problems.append("6 %s: %d pieces (%d counted), want %d" % [what, n, b.panel_pieces, want_runs.size()])
				continue
			var row := PanelRule.row_of(StringName(str(case[1])))
			var seed := PanelRule.seed(CityBarriers.barrier_id(str(case[0]), p))
			for k in n:
				var o: int = k * CityBarriers.PANEL_FLOATS
				if int(t.buf[o + 12]) != row or absf(t.buf[o + 13] - want_runs[k]) > 1e-4 or t.buf[o + 14] != 0.0 \
						or absf(t.buf[o + 15] - seed) > 1e-6 or int(t.panel[k]) != want_panels[k]:
					problems.append("6 %s: piece %d is row %d, run %.2f, state %.0f, seed %.4f, panel %d; want %d, %.2f, 0, %.4f, %d" % [
							what, k, t.buf[o + 12], t.buf[o + 13], t.buf[o + 14], t.buf[o + 15], t.panel[k], row, want_runs[k],
							seed, want_panels[k]])
					break
			# The first piece: 2 m along +x, from SINK under the ground to the line's height, upright.
			var h := float(Solidity.look_row(StringName(str(case[1])))["h"]) if float(case[2]) <= 0.0 else float(case[2])
			var first := Vector3(t.buf[0], t.buf[4], t.buf[8])
			var up := Vector3(t.buf[1], t.buf[5], t.buf[9])
			if not first.is_equal_approx(Vector3(2, 0, 0)) or not up.is_equal_approx(Vector3(0, h + PanelRule.SINK, 0)) \
					or not is_equal_approx(t.buf[7], -PanelRule.SINK):
				problems.append("6 %s: the first piece's axes %s, %s and foot %.2f" % [what, first, up, t.buf[7]])
			var soft := sc == "S"
			var meta: Dictionary = t.meta()
			var ids: PackedStringArray = meta["ids"]
			if soft and (ids.size() != 1 or ids[0] != CityBarriers.barrier_id(str(case[0]), p) or meta["first"] != PackedInt32Array([0]) \
					or meta["count"] != PackedInt32Array([n])):
				problems.append("6 %s: the soft line's meta %s" % [what, meta])
			if not soft and not ids.is_empty():
				problems.append("6 %s: a hard line in the soft meta %s" % [what, ids])
			if soft and typed_soft.is_empty():
				problems.append("6 %s: the line is not soft (the case tests nothing)" % what)
	# A row not marked panel (low_lawn) stays typed under panels.
	var lawn := _line("fence", p, {"ty": "low_lawn"})
	var lt := _build(map, [lawn], &"typed")
	var lp := _build(map, [lawn], &"panels")
	if lt[0] != lp[0] or lt[1] != lp[1] or not (b.panel_tiles as Dictionary).is_empty():
		problems.append("6 low_lawn: typed %d triangles, panels %d (and %d tiles of pieces)" % [lt[0], lp[0], (b.panel_tiles as Dictionary).size()])
	# The node as the whole city's build makes it (map_builder.gd `build` makes the shared things
	# later, at the trees, so `_build_panels` makes them itself): Panels_5_5, the pieces, the material.
	map._in_sector = false
	_build(map, [_line("fence", p, {"ty": "bars_black", "sc": "H"})], &"panels")
	map._out = map
	map._build_panels()
	var node := map.get_node_or_null("Panels_5_5") as MultiMeshInstance3D
	if node == null or node.multimesh.instance_count != want_runs.size() or node.material_override != map.panel_material \
			or map.panel_material == null:
		problems.append("6 the whole city's Panels_5_5: %s" % ("missing" if node == null else "%d pieces, material %s" % [
				node.multimesh.instance_count, node.material_override]))
	if node != null:
		map.remove_child(node)
		node.free()
	map._out = null
	map._in_sector = false
	map._sector = Vector2i.ZERO


## 7: the whole map under panels on the flat map: typed's faces, every panel row's line as panels.
func _whole_panels(map: Node3D, data: Dictionary) -> Dictionary:
	Solidity.set_barrier_look(&"typed")
	map.data = data
	map._solids = {}
	map.barriers.build_barriers(Chunked.new())
	var typed_faces: Dictionary = map._solids.duplicate(true)
	var typed_counts: Dictionary = (map.barriers.look_counts as Dictionary).duplicate()
	Solidity.set_barrier_look(&"panels")
	map._solids = {}
	var st := Chunked.new()
	map.barriers.build_barriers(st)
	var b: RefCounted = map.barriers
	for cls: StringName in typed_faces:
		if map._solids.get(cls) != typed_faces[cls]:
			problems.append("7 class %s: %d faces under panels, %d typed" % [cls,
					(map._solids.get(cls, PackedVector3Array()) as PackedVector3Array).size() / 3, (typed_faces[cls] as PackedVector3Array).size() / 3])
	for cls: StringName in map._solids:
		if not typed_faces.has(cls):
			problems.append("7 class %s under panels only" % cls)
	var lines := int(b.look_counts.get(&"panel", 0))
	var want := 0
	for l: Dictionary in data.get("lines", []):
		if PanelRule.is_panel(StringName(str(l.get("ty", "")))):
			want += 1
	if lines == 0 or lines > want:
		problems.append("7 %d lines drawn as panels, %d lines of panel rows on the map" % [lines, want])
	var counted := 0
	for key: Vector2i in b.panel_tiles:
		counted += (b.panel_tiles[key].buf as PackedFloat32Array).size() / CityBarriers.PANEL_FLOATS
	if counted != int(b.panel_pieces):
		problems.append("7 the tiles hold %d pieces, %d counted" % [counted, b.panel_pieces])
	var out := {"panel lines": lines, "of": want, "pieces": counted, "tiles": (b.panel_tiles as Dictionary).size(),
			"city mesh triangles": st.vertex_count / 3}
	if int(typed_counts.get(&"rail", 0)) + int(typed_counts.get(&"slab", 0)) != int(b.look_counts.get(&"rail", 0)) + int(b.look_counts.get(&"slab", 0)):
		problems.append("7 the typed lines' counts differ: %s typed, %s panels" % [typed_counts, b.look_counts])
	map._solids = {}
	map.data = {}
	return out


## 8: the two city paths against each other, in the look the prebuilt city was baked in.
func _paths(every: bool) -> void:
	var stamp: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/sectors/city.stamp")) \
			if FileAccess.file_exists("res://map/sectors/city.stamp") else null
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json")) \
			if FileAccess.file_exists("res://map/index.json") else null
	if not stamp is Dictionary or not index is Dictionary:
		print("  PROBLEM 8 no prebuilt city (map/sectors/city.stamp, map/index.json): run tools/setup_map.sh")
		print("check_barrier_look: 1 problems")
		quit(1)
		return
	var look := StringName(str((stamp as Dictionary).get("barrier_look", "classic")))
	Solidity.set_barrier_look(look)
	var runtime: Node3D = MapBuilder.new()
	root.add_child(runtime)
	runtime.setup_streamed(index, ShaderMaterial.new(), ShaderMaterial.new())
	var keys: Array[Vector2i] = []
	if every:
		for k: Array in (index as Dictionary)["sectors"]["keys"]:
			keys.append(Vector2i(int(k[0]), int(k[1])))
	else:
		keys = PATH_SECTORS
	var pieces := 0
	var verts := 0
	for key in keys:
		var built: Node3D = runtime.build_sector(key)
		var a := _sector_counts(built)
		built.free()
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if not ResourceLoader.exists(path):
			problems.append("8 %s: no prebuilt sector %s" % [key, path])
			continue
		var inst := (ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
		var b := _sector_counts(inst)
		inst.free()
		if a != b:
			problems.append("8 %s (%s): runtime %s, prebuilt %s" % [key, look, a, b])
		pieces += int(a["panel pieces"])
		verts += int(a["vertices"])
	runtime.free()
	Solidity.set_barrier_look(&"classic")
	if problems.is_empty():
		print("check_barrier_look: OK (paths: %d sectors in the baked look %s, %d city mesh vertices, %d panel pieces, the same on both)" % [
				keys.size(), look, verts, pieces])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_barrier_look: %d problems" % problems.size())
		quit(1)


## 8: a sector's mesh vertices (every MeshInstance3D's surfaces) and its Panels' pieces.
func _sector_counts(sector: Node) -> Dictionary:
	var verts := 0
	var pieces := 0
	var nodes := 0
	for n in sector.find_children("*", "", true, false):
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var m := (n as MeshInstance3D).mesh
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				if arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		elif n is MultiMeshInstance3D and str(n.name).begins_with("Panels"):
			nodes += 1
			pieces += (n as MultiMeshInstance3D).multimesh.instance_count
	return {"vertices": verts, "panel pieces": pieces, "panel nodes": nodes}
