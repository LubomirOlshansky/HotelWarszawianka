extends SceneTree
## W2 of the walls look (docs/design/walls-true-to-life.md 6.1-6.3; city-objects-plan.md 5.2, step
## 9a): the palette's `looks` rows and the typed drawing (city_barriers.gd `_typed`,
## `rail_lite_along`), behind the key `barrier_look`.
##   1 the palette's `barrier_look` is classic: testers' builds stay as main draws them (the pull
##     request that changes the default changes this line too);
##   2 every `ty` on a fence, wall or hedge line of map/centrum.json has a `looks` row; every row
##     has the keys its `draw` needs (rail: h, colour, post {every, w}, rails; slab: h, thick,
##     colour; every drawn row a family); every `post.every` is 2 or 4 (a multiple of the 2 m
##     panel soft_things.gd remembers; a `keep` row's posts are its classic look's: stadium_fence's
##     1.5 m); every colour parses; `alt` shares add up to at most 1;
##   3 on a flat synthetic map, one line per draw kind built by build_barriers under typed: `rail`
##     makes 4 x posts + 2 x rails x segments triangles (its foot, where the row has one, wall_along's
##     10 a segment) and the same collider faces as railing_along at that height; `slab` makes what
##     wall_along makes at the row's thickness and the line's height; `none` makes nothing; `keep`,
##     an unknown type and a line a rule gave its look (`st`) make what classic makes;
##     W7 (walls doc 6.5): every heavy or low `slab` row with a foot, cap, bays or piers is drawn by the
##     heavy kit (city_barriers.gd wall_kit), the same under typed and panels: more triangles than
##     wall_along's slab, nothing under its sink, over its top but its piers, posts and rails, or
##     further from the line than its cap, posts and piers reach; every other bay a step darker; a
##     stone wall over water gets its top rail; and the very collider faces wall_along files at the
##     row's thickness and the line's height, in the same order;
##   4 the same line built twice gets the same `alt` colour, and the colour follows its stable id;
##   5 the whole map's lines built under typed on the flat map: none drawn classic for want of a
##     row (`unknown`) and none in barrier_default; the count of lines per draw kind is printed;
##   6 W4 (walls doc 6.4): under panels, on the flat synthetic map, a line of each panel draw kind
##     (a rail row, one with a foot, a slab row; hard and soft) makes no triangles in the city mesh
##     and the very collider faces and soft list typed makes; its panel pieces are cut at every 2 m
##     of the line's run and at its corners, each with its panel index (soft_things.gd's), its
##     row, its run and its seed, the soft line's first instance and count in its tile's meta;
##     under classic and typed no piece is made; the whole city's build (no sector) makes its
##     `Panels_i_j` node with the pieces and the panel material; W5: the same for a line of every
##     light row (bars_pier's `in_mesh` posts: rail_lite_along's 4 triangles a post in the city mesh,
##     nothing else; W7: its plinth and piers, `_pier_fence_kit`'s triangles, and on a soft line a
##     diamond collider of class wall per pier, none on a hard line or with the soft switch off); a row not marked panel (deck_railing) stays typed; the stadium's railing (#808)
##     is classic under typed and, under panels, pieces of its row at its types row's height with
##     the classic railing's colliders and no triangle in the city mesh;
##   7 W4: the whole map under panels on the flat map: the collider faces per class are typed's,
##     face for face (the cars meet the same fences), every line of a panel row is drawn as
##     panels and none of another; the pieces are printed; W5: the light-family lines still drawn
##     in the city mesh are named by type (`mesh_light`), and none is of a type outside MESH_LIGHT;
##   9 W8 (walls doc 6.6 row 9, tools/barrier_gates.py): a 20 m fence with a gap (`g`) and gate ends
##     (`ge`: a post at its start, a post and an open leaf at its end), a soft and a hard one, under
##     typed and panels on the flat map: no triangle, collider face, soft segment or panel piece inside
##     the gap; the pieces after it keep their panel index (metres / 2 along the whole line) and run;
##     the soft list's panels are the whole line's; a gate post at each of the gap's edges and at each
##     gated end, inside the line, CityBarriers.GATE_RISE m over the line, and nothing else over it; the
##     leaf on its side of the line, off the line's own segment, not past the line's far end; a wall's
##     gap the same; under classic the gates change nothing (triangles and faces as the line without them);
##   10 W9 (walls doc 6.8, game/scripts/wall_marks.gd): every character of game/data/wall_marks.json is in
##     the pixel font and its lines fit (a slogan at most 15 characters, a banner line 11); the atlas holds
##     every cell inside the image, none over another; on a 600 m precast wall under typed marks stand off
##     the wall's face by their lift, under its top and over the ground, the same on a second build, none
##     under classic; none across a gap; on a hoarding a banner per face; and on the whole map no line has
##     more slogans than its length in 150 m windows (at least one) or two closer than 150 m, and the
##     slogans are at most the marked walls' length over 150 m;
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
const WallMarks := preload("res://scripts/wall_marks.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const PANEL_RHYTHMS := [2.0, 4.0]
## 9 (W8): how far a piece's own end shape (rail_lite's last post, a wall's end) may reach into a gap.
const END_IN := 0.1
## 7 (W5): the light types whose lines may still be drawn in the city mesh under panels: the tram's
## railing (`draw: keep`: the placed tram_railing, a hard rail by the tracks). Every other light line
## is panels (bars_pier's posts stand in the mesh as part of its panel line, W7's piers).
const MESH_LIGHT := ["rail_tram"]
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
	_gates(map)
	var marks_out := _marks(map)
	if data is Dictionary:
		counts = _whole(map, data)
		counts["marks"] = _whole_marks(map, data)
		counts["marks synthetic"] = marks_out
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
			if not float(post.get("every", 0.0)) in PANEL_RHYTHMS and draw != "keep":
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
	# W9: the synthetic cases count the line's own triangles; the marks have case 10.
	map.barriers.marks_on = false
	map.barriers.build_barriers(st)
	map.barriers.marks_on = true
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
	_kit(map)
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


## 3 (W7): the heavy kit, a line of every kit row on the flat map (a corner, so it mitres; 19 m, so
## the rhythm repeats): see the header.
func _kit(map: Node3D) -> void:
	var p := [3000.0, 3000.0, 3012.0, 3000.0, 3012.0, 3007.0]
	var pts := PackedVector2Array([Vector2(3000, 3000), Vector2(3012, 3000), Vector2(3012, 3007)])
	var b: RefCounted = map.barriers
	var kits := 0
	for id: StringName in Solidity.looks():
		var row := Solidity.look_row(id)
		if str(row.get("draw", "")) != "slab" or not CityBarriers.kit_row(row):
			continue
		kits += 1
		var h := float(row["h"])
		var hw := float(row["thick"]) * 0.5
		for hz: String in ["", "water"]:
			var l := _line("wall", p, {"ty": str(id)} if hz == "" else {"ty": str(id), "hz": hz})
			var look: Dictionary = b._typed(l, true)
			var colour: Color = look["colour"]
			var typed := _build(map, [l], &"typed")
			var st := Chunked.new()
			Solidity.set_barrier_look(&"typed")
			map.data = {"lines": [l]}
			map._solids = {}
			b.marks_on = false
			b.build_barriers(st)
			b.marks_on = true
			var panels := _build(map, [l], &"panels")
			map._solids = {}
			var slab := Chunked.new()
			b.wall_along(slab, pts, float(row["thick"]), h, colour, true, &"wall")
			if typed[1] != map._solids:
				problems.append("3 kit %s: collider faces %s, wall_along files %d" % [id, typed[2],
						(map._solids.get(&"wall", PackedVector3Array()) as PackedVector3Array).size() / 3])
			if panels[0] != typed[0] or panels[1] != typed[1]:
				problems.append("3 kit %s: panels %d triangles %s, typed %d %s" % [id, panels[0], panels[2], typed[0], typed[2]])
			if int(typed[0]) <= slab.vertex_count / 3:
				problems.append("3 kit %s: %d triangles, the plain slab %d" % [id, typed[0], slab.vertex_count / 3])
			var pier: Dictionary = row.get("pier", {})
			var bay: Dictionary = row.get("bay", {})
			var cap: Dictionary = row.get("cap", {})
			var rail: Dictionary = row.get("top_rail", {})
			var railed := hz != "" and hz in (rail.get("hz", []) as Array)
			var top := h + (CityBarriers.KIT_PIER_RISE if not pier.is_empty() else (CityBarriers.KIT_POST_RISE if bay.has("post_w") else 0.0))
			if railed:
				top = maxf(top, h + float(rail["h"]))
			var reach := maxf(hw + float(cap.get("over", 0.0)), hw + float(bay.get("proud", CityBarriers.KIT_PROUD)))
			reach = maxf(reach, float(pier.get("w", 0.0)) * 0.71) * 1.415
			var lo := INF
			var hi := -INF
			var far := 0.0
			var colours: Array[Color] = []
			for mesh: ArrayMesh in st.meshes():
				for si in mesh.get_surface_count():
					var arrays := mesh.surface_get_arrays(si)
					for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
						lo = minf(lo, v.y)
						hi = maxf(hi, v.y)
						far = maxf(far, CityBarriers._dist_to_line(Vector2(v.x, v.z), pts))
					for c: Color in arrays[Mesh.ARRAY_COLOR]:
						if not _has_colour(colours, c):
							colours.append(c)
			if lo < -CityBarriers.KIT_SINK - 1e-3 or hi > top + 1e-3 or far > reach + 1e-3:
				problems.append("3 kit %s%s: drawn from %.2f to %.2f m, %.2f m off the line; want %.2f to %.2f, %.2f" % [id,
						" (hz %s)" % hz if hz != "" else "", lo, hi, far, -CityBarriers.KIT_SINK, top, reach])
			if railed and absf(hi - (h + float(rail["h"]))) > 1e-3:
				problems.append("3 kit %s over %s: no top rail (the top at %.2f m)" % [id, hz, hi])
			var step := float(bay.get("step", 0.0))
			if step > 0.0 and not (_has_colour(colours, colour.darkened(0.08)) and _has_colour(colours, colour.darkened(step).darkened(0.08))):
				problems.append("3 kit %s: the bays are not a step %.2f apart (%d colours)" % [id, step, colours.size()])
	if kits < 9:
		problems.append("3 kit: %d rows drawn by the heavy kit, want the nine heavy and low slab rows" % kits)
	map._solids = {}


## Whether `list` holds `c` to within the 8 bits a vertex colour keeps.
static func _has_colour(list: Array[Color], c: Color) -> bool:
	for x in list:
		if absf(x.r - c.r) < 0.006 and absf(x.g - c.g) < 0.006 and absf(x.b - c.b) < 0.006:
			return true
	return false


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
	# 9 (W8): the map's gates as drawn (the lines with a typed look): printed.
	counts["gates"] = (map.barriers.gate_counts as Dictionary).duplicate()
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
	for case: Array in [["fence", "fence_plain", 1.3], ["fence", "bars_black", -1.0], ["hedge", "hedge_low", 0.7],
			["fence", "green_fence", -1.0], ["fence", "low_lawn", -1.0], ["fence", "ball_net", -1.0], ["fence", "wood", -1.0],
			["wall", "wood", -1.0], ["fence", "hoarding", -1.0], ["hedge", "hedge_tall", -1.0], ["fence", "chain_posts", -1.0],
			["fence", "post_row", -1.0], ["fence", "bars_pier", -1.0]]:
		# (A wall is never soft: soft_things breaks fences and hedges.)
		for sc: String in (["H"] if case[0] == "wall" else ["H", "S"]):
			var extra := {"ty": case[1], "sc": sc}
			if float(case[2]) > 0.0:
				extra["hs"] = case[2]
			var l := _line(str(case[0]), p, extra)
			var typed := _build(map, [l], &"typed")
			var typed_soft: Dictionary = b.soft_data()
			var typed_diamonds: int = b.kit_diamonds
			if not (b.panel_tiles as Dictionary).is_empty():
				problems.append("6 %s: typed made panel pieces" % case[1])
			var classic := _build(map, [l], &"classic")
			if not (b.panel_tiles as Dictionary).is_empty():
				problems.append("6 %s: classic made panel pieces" % case[1])
			var panels := _build(map, [l], &"panels")
			var what := "%s %s (%s)" % [case[0], case[1], sc]
			var lrow := Solidity.look_row(StringName(str(case[1])))
			var mesh_tris := 0
			if lrow.has("pier"):
				# W7: the plinth and piers in the city mesh; a pier diamond each on a soft line only.
				var pe := float(lrow["pier"]["every"])
				var marks := floori(8.2 / pe) + 1 + (1 if fmod(8.2, pe) > 0.05 else 0)
				var kst := Chunked.new()
				b._soft_line = {}
				b._pier_fence_kit(kst, PackedVector2Array([Vector2(3000, 3000), Vector2(3005, 3000), Vector2(3005, 3003.2)]),
						lrow, float(lrow["h"]))
				map._solids = {}
				mesh_tris = kst.vertex_count / 3
				var want_d := marks if sc == "S" else 0
				var walls := (typed[1] as Dictionary).get(&"wall", PackedVector3Array()) as PackedVector3Array
				if typed_diamonds != want_d or walls.size() != want_d * 24:
					problems.append("6 %s (%s): %d pier diamonds, %d wall faces; want %d and %d" % [case[1], sc, typed_diamonds,
							walls.size() / 3, want_d, want_d * 8])
			elif bool((lrow.get("post", {}) as Dictionary).get("in_mesh", false)):
				var pe := float(lrow["post"]["every"])
				mesh_tris = 4 * (floori(8.2 / pe) + 1 + (1 if fmod(8.2, pe) > 0.05 else 0))
			if int(panels[0]) != mesh_tris:
				problems.append("6 %s: %d triangles in the city mesh under panels, want %d" % [what, panels[0], mesh_tris])
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
	# W7: a soft pier-and-iron line with the soft switch off: hard, and no pier diamond.
	CityBarriers.soft_off = true
	var hard := _build(map, [_line("fence", p, {"ty": "bars_pier", "sc": "S"})], &"typed")
	CityBarriers.soft_off = false
	if int(b.kit_diamonds) != 0 or (hard[1] as Dictionary).has(&"wall"):
		problems.append("6 bars_pier: %d pier diamonds with the soft switch off" % b.kit_diamonds)
	# A row not marked panel (deck_railing, heavy) stays typed under panels.
	var deck := _line("fence", p, {"ty": "deck_railing"})
	var lt := _build(map, [deck], &"typed")
	var lp := _build(map, [deck], &"panels")
	if lt[0] != lp[0] or lt[1] != lp[1] or not (b.panel_tiles as Dictionary).is_empty() or int(lt[0]) == 0:
		problems.append("6 deck_railing: typed %d triangles, panels %d (and %d tiles of pieces)" % [lt[0], lp[0], (b.panel_tiles as Dictionary).size()])
	_stadium(map)
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


## 9 (W8): the gates on a flat synthetic line: see the header.
func _gates(map: Node3D) -> void:
	map._in_sector = true
	map._sector_rect = Rect2(2560.0, 2560.0, 512.0, 512.0)
	map._sector = Vector2i(5, 5)
	var b: RefCounted = map.barriers
	var p := [3000.0, 3000.0, 3012.0, 3000.0, 3020.0, 3000.0]
	var g0 := 7.0
	var g1 := 9.4
	var gates := {"g": [[g0, g1 - g0, 0]], "ge": [1, 2]}
	for case: Array in [["fence", "fence_plain", "S"], ["fence", "bars_black", "H"], ["hedge", "hedge_low", "S"], ["wall", "wall_precast", "H"]]:
		var what := "%s %s (%s)" % case
		var bare := _line(str(case[0]), p, {"ty": case[1], "sc": case[2]})
		var gated := bare.duplicate(true)
		gated.merge(gates, true)
		# Classic ignores the gates.
		var cb := _build(map, [bare], &"classic")
		var cg := _build(map, [gated], &"classic")
		if cb[0] != cg[0] or cb[1] != cg[1]:
			problems.append("9 %s: classic draws the gates (%d triangles %s, %d %s without)" % [what, cg[0], cg[2], cb[0], cb[2]])
		var row := Solidity.look_row(StringName(str(case[1])))
		var h := float(row["h"])
		for look: StringName in [&"typed", &"panels"]:
			Solidity.set_barrier_look(look)
			map.data = {"lines": [gated]}
			map._solids = {}
			var st := Chunked.new()
			b.build_barriers(st)
			Solidity.set_barrier_look(&"typed")
			var tag := "%s %s" % [what, look]
			var eps := 1e-3
			var post_w := maxf(CityBarriers.GATE_POST_W, float(row.get("thick", 0.0)) + CityBarriers.GATE_POST_PROUD) if case[0] == "wall" \
					else CityBarriers.GATE_POST_W
			# Triangles: none inside the gap (a piece's own end shape, a post's or a wall end's half width,
			# may reach END_IN m into it, as at any line's end); over the line's height only the posts,
			# wholly inside the line at the gap's edges and the gated ends, GATE_RISE over it.
			var tops := {0.0: -INF, g0: -INF, g1: -INF, 20.0: -INF}
			var in_gap := 0
			var odd := 0
			for mesh: ArrayMesh in st.meshes():
				for si in mesh.get_surface_count():
					var verts: PackedVector3Array = mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
					for v: Vector3 in verts:
						var s := v.x - 3000.0
						if s > g0 + END_IN and s < g1 - END_IN:
							in_gap += 1
						if s < -END_IN or s > 20.0 + END_IN:
							odd += 1
						if v.y > h + 0.2 + eps:
							var near := false
							for edge: float in tops:
								var inner := edge + (post_w if edge == g1 or edge == 0.0 else -post_w)
								if s >= minf(edge, inner) - eps and s <= maxf(edge, inner) + eps:
									tops[edge] = maxf(float(tops[edge]), v.y)
									near = true
							if not near:
								odd += 1
			if in_gap > 0 or odd > 0:
				problems.append("9 %s: %d vertices in the gap, %d over the line's height off a post or past its ends" % [tag, in_gap, odd])
			for edge: float in tops:
				if absf(float(tops[edge]) - (h + CityBarriers.GATE_RISE)) > eps:
					problems.append("9 %s: the post at %.1f m stands %.2f m, want %.2f" % [tag, edge, tops[edge], h + CityBarriers.GATE_RISE])
			# Collider faces and soft segments: none inside the gap.
			for cls: StringName in map._solids:
				var faces: PackedVector3Array = map._solids[cls]
				for v: Vector3 in faces:
					if v.x - 3000.0 > g0 + END_IN and v.x - 3000.0 < g1 - END_IN:
						problems.append("9 %s: a %s collider vertex in the gap at %.2f m" % [tag, cls, v.x - 3000.0])
						break
			var soft: Dictionary = b.soft_data()
			if case[2] == "S" and case[0] != "wall":
				if soft.is_empty():
					problems.append("9 %s: the line is not soft (the case tests nothing)" % tag)
				else:
					var segs: PackedFloat64Array = soft["segs"]
					for k in range(0, segs.size(), CityBarriers.SOFT_STRIDE):
						var ax := segs[k + 1] - 3000.0
						var bx := segs[k + 3] - 3000.0
						if maxf(ax, bx) > g0 + END_IN and minf(ax, bx) < g1 - END_IN:
							problems.append("9 %s: a soft segment %.2f..%.2f m in the gap" % [tag, ax, bx])
						if absf(segs[k + 9] - ax) > eps:
							problems.append("9 %s: the soft segment at %.2f m says it starts %.2f m along the line" % [tag, ax, segs[k + 9]])
					if (soft["panels"] as PackedInt32Array) != PackedInt32Array([10]):
						problems.append("9 %s: the soft line's panels %s, want the whole line's [10]" % [tag, soft["panels"]])
			# Panels: no piece in the gap; each piece's panel index metres / 2 along the whole line.
			if look == &"panels" and bool(row.get("panel", false)):
				var tiles: Dictionary = b.panel_tiles
				if not tiles.has(Vector2i(5, 5)):
					problems.append("9 %s: no panel pieces" % tag)
				else:
					var t = tiles[Vector2i(5, 5)]
					for k in (t.buf.size() / CityBarriers.PANEL_FLOATS):
						var o: int = k * CityBarriers.PANEL_FLOATS
						var x0: float = t.buf[o + 3] - 3000.0
						var x1: float = x0 + t.buf[o]
						var run: float = t.buf[o + 13]
						if x1 > g0 + END_IN and x0 < g1 - END_IN:
							problems.append("9 %s: a panel piece %.2f..%.2f m in the gap" % [tag, x0, x1])
						if absf(run - x0) > eps or int(t.panel[k]) != floori(x0 / CityBarriers.PANEL + 1e-6):
							problems.append("9 %s: the piece at %.2f m has run %.2f, panel %d" % [tag, x0, run, t.panel[k]])
			# The leaf: at the end gate (2: the left side, +z for a line running +x), off the line, inside it.
			var leaf := 0
			var left := 0
			for mesh: ArrayMesh in st.meshes():
				for si in mesh.get_surface_count():
					var arrays := mesh.surface_get_arrays(si)
					var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
					for vi in verts.size():
						if cols[vi].is_equal_approx(CityBarriers.GATE_LEAF):
							leaf += 1
							left += 1 if verts[vi].z > 3000.0 + float(row.get("thick", 0.0)) * 0.5 else 0
							if verts[vi].x < 3020.0 - CityBarriers.GATE_LEAF_LEN - post_w - eps:
								problems.append("9 %s: the leaf reaches %.2f m along the line" % [tag, verts[vi].x - 3000.0])
								break
			if leaf == 0 or left != leaf:
				problems.append("9 %s: %d leaf vertices, %d on its side" % [tag, leaf, left])
	map._in_sector = false
	map._sector = Vector2i.ZERO


## 6 (W5): the stadium's railing (#808): a line of it 250 m from the stadium's centre, in its tile.
func _stadium(map: Node3D) -> void:
	var c := CityBarriers.STADIUM_CENTRE + Vector2(250.0, 0.0)
	var key := Vector2i(floori(c.x / 512.0), floori(c.y / 512.0))
	map._in_sector = true
	map._sector = key
	map._sector_rect = Rect2(key.x * 512.0, key.y * 512.0, 512.0, 512.0)
	var p := [c.x, c.y, c.x + 5.0, c.y, c.x + 5.0, c.y + 3.2]
	var b: RefCounted = map.barriers
	for sc: String in ["H", "S"]:
		var l := _line("fence", p, {"ty": "stadium_fence", "sc": sc})
		if not CityBarriers.stadium_fence_line(l):
			problems.append("6 stadium: the test line is not the stadium's railing")
			break
		var classic := _build(map, [l], &"classic")
		var classic_soft: Dictionary = b.soft_data()
		var typed := _build(map, [l], &"typed")
		if typed[0] != classic[0] or typed[1] != classic[1] or not (b.panel_tiles as Dictionary).is_empty():
			problems.append("6 stadium (%s): typed %d triangles %s, classic %d %s" % [sc, typed[0], typed[2], classic[0], classic[2]])
		var panels := _build(map, [l], &"panels")
		if int(panels[0]) != 0 or panels[1] != classic[1] or var_to_str(b.soft_data()) != var_to_str(classic_soft):
			problems.append("6 stadium (%s): panels %d triangles, faces %s (classic %s), the soft list %s" % [sc, panels[0], panels[2],
					classic[2], "the same" if var_to_str(b.soft_data()) == var_to_str(classic_soft) else "differs"])
		var t = (b.panel_tiles as Dictionary).get(key)
		var h := float(Solidity.type_row(&"stadium_fence")["height"])
		if t == null or (t.buf as PackedFloat32Array).size() / CityBarriers.PANEL_FLOATS != 6 \
				or int(t.buf[12]) != PanelRule.row_of(&"stadium_fence") or not is_equal_approx(t.buf[5], h + PanelRule.SINK):
			problems.append("6 stadium (%s): pieces %s, want 6 of row %d at %.2f m" % [sc, "none" if t == null else str(
					(t.buf as PackedFloat32Array).size() / CityBarriers.PANEL_FLOATS), PanelRule.row_of(&"stadium_fence"), h])
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
			"city mesh triangles": st.vertex_count / 3, "light lines in the city mesh": (b.mesh_light as Dictionary).duplicate()}
	for ty: String in b.mesh_light:
		if not ty in MESH_LIGHT:
			problems.append("7 %d lines of light type %s drawn in the city mesh under panels" % [b.mesh_light[ty], ty])
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
	var quads := 0
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
		quads += int(a["slogan quads"])
	runtime.free()
	Solidity.set_barrier_look(&"classic")
	if problems.is_empty():
		print("check_barrier_look: OK (paths: %d sectors in the baked look %s, %d city mesh vertices, %d panel pieces, %d slogan and banner quads, the same on both)" % [
				keys.size(), look, verts, pieces, quads])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_barrier_look: %d problems" % problems.size())
		quit(1)


## 8: a sector's mesh vertices (every MeshInstance3D's surfaces), its Panels' pieces and (W9) its
## Slogans' quads.
func _sector_counts(sector: Node) -> Dictionary:
	var verts := 0
	var pieces := 0
	var nodes := 0
	var quads := 0
	for n in sector.find_children("*", "", true, false):
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var m := (n as MeshInstance3D).mesh
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				if arr[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					if str(n.name).begins_with("Slogans"):
						quads += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 6
		elif n is MultiMeshInstance3D and str(n.name).begins_with("Panels"):
			nodes += 1
			pieces += (n as MultiMeshInstance3D).multimesh.instance_count
	return {"vertices": verts, "panel pieces": pieces, "panel nodes": nodes, "slogan quads": quads}


## 10 (W9): the words, the atlas and one wall's marks on the flat map.
func _marks(map: Node3D) -> Dictionary:
	var WM := WallMarks
	var texts: Dictionary = WM.texts()
	var out := {}
	for kind: String in ["slogans", "banners"]:
		for t: Dictionary in texts.get(kind, []):
			var lines: Array = [str(t["pl"])] if kind == "slogans" else t["lines"]
			for ln: Variant in lines:
				for ch in str(ln):
					if ch != " " and PixelFont.char_width(ch) == 0:
						problems.append("10 %s %s: '%s' is not in the pixel font" % [kind, t["id"], ch])
				var cap := 15 if kind == "slogans" else 11
				if str(ln).length() > cap:
					problems.append("10 %s %s: %d characters (at most %d)" % [kind, t["id"], str(ln).length(), cap])
	var at: Dictionary = WM.atlas()
	var img: Image = at["image"]
	var rects: Array[Rect2i] = []
	for kind: String in ["slogans", "banners"]:
		for key: String in at[kind]:
			var r: Rect2i = at[kind][key]
			if r.position.x < 0 or r.position.y < 0 or r.end.x > img.get_width() or r.end.y > img.get_height():
				problems.append("10 atlas cell %s outside the image" % key)
			for o: Rect2i in rects:
				if o.intersects(r):
					problems.append("10 atlas cell %s overlaps another" % key)
			rects.append(r)
	out["atlas"] = "%dx%d, %d cells" % [img.get_width(), img.get_height(), rects.size()]
	# One 600 m precast wall (a slogan or two, patches, stains) under typed, built twice, and under classic.
	var wall := _line("wall", [4000.0, 4000.0, 4600.0, 4000.0], {"ty": "wall_precast", "g": [[100.0, 4.0, 0]]})
	var b: RefCounted = map.barriers
	Solidity.set_barrier_look(&"typed")
	map.data = {"lines": [wall]}
	map._in_sector = false
	var plain := Chunked.new()
	b.marks_on = false
	map._solids = {}
	b.build_barriers(plain)
	b.marks_on = true
	var first := Chunked.new()
	map._solids = {}
	b.build_barriers(first)
	var counts: Dictionary = (b.mark_counts as Dictionary).duplicate()
	var tiles: int = (b.mark_tiles as Dictionary).size()
	var log1: Array = (b.slogan_log as Array).duplicate(true)
	var second := Chunked.new()
	map._solids = {}
	b.build_barriers(second)
	if first.vertex_count != second.vertex_count or var_to_str(log1) != var_to_str(b.slogan_log):
		problems.append("10 the same wall built twice differs (%d and %d vertices)" % [first.vertex_count, second.vertex_count])
	if first.vertex_count <= plain.vertex_count or int(counts.get("graffiti", 0)) + int(counts.get("stain", 0)) == 0:
		problems.append("10 a 600 m precast wall got no marks (%d vertices with, %d without; %s)" % [first.vertex_count, plain.vertex_count, counts])
	var row := Solidity.look_row(&"wall_precast")
	var hw := float(row["thick"]) * 0.5
	var near := INF
	var far := 0.0
	var top := -INF
	var low := INF
	# What the marks added stays on the face's side: between lift and the longest reach, above ground.
	var extra_verts: Array[Vector3] = []
	var seen := {}
	for mesh: ArrayMesh in plain.meshes():
		for si in mesh.get_surface_count():
			for v: Vector3 in mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				seen[v] = true
	for mesh: ArrayMesh in first.meshes():
		for si in mesh.get_surface_count():
			for v: Vector3 in mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				if not seen.has(v):
					extra_verts.append(v)
	var in_gap := 0
	for v: Vector3 in extra_verts:
		if v.x > 4100.0 and v.x < 4104.0:
			in_gap += 1
		var off := absf(v.z - 4000.0)
		near = minf(near, off)
		far = maxf(far, off)
		top = maxf(top, v.y)
		low = minf(low, v.y)
	if in_gap > 0:
		problems.append("10 %d mark vertices stand in the gap of the precast wall" % in_gap)
	if not extra_verts.is_empty():
		if near < hw + 0.01 or far > hw + 0.1 or low < 0.0 or top > float(row["h"]) + 0.05:
			problems.append("10 precast marks reach %.3f to %.3f m off the line (face at %.3f), from %.2f to %.2f m up (wall %.2f)" % [
					near, far, hw, low, top, float(row["h"])])
	out["precast wall"] = {"vertices": first.vertex_count - plain.vertex_count, "counts": counts, "poster tiles": tiles}
	# Classic: nothing.
	Solidity.set_barrier_look(&"classic")
	var classic := Chunked.new()
	map._solids = {}
	b.build_barriers(classic)
	if not (b.mark_counts as Dictionary).is_empty() or not (b.mark_tiles as Dictionary).is_empty():
		problems.append("10 classic made marks: %s" % b.mark_counts)
	# A hoarding: a banner on each face.
	var hoard := _line("fence", [4000.0, 4100.0, 4008.0, 4100.0], {"ty": "hoarding", "sc": "S"})
	for look: StringName in [&"typed", &"panels"]:
		Solidity.set_barrier_look(look)
		map.data = {"lines": [hoard]}
		map._solids = {}
		b.build_barriers(Chunked.new())
		if int(b.mark_counts.get("banner", 0)) != 2:
			problems.append("10 a 8 m hoarding under %s got %s banners, want 2" % [look, b.mark_counts.get("banner", 0)])
	Solidity.set_barrier_look(&"typed")
	map.data = {}
	map._solids = {}
	return out


## 10: the whole map's marks on the flat map under typed and panels (the same), and the slogans' rule.
func _whole_marks(map: Node3D, data: Dictionary) -> Dictionary:
	var out := {}
	var b: RefCounted = map.barriers
	var first := {}
	for look: StringName in [&"typed", &"panels"]:
		Solidity.set_barrier_look(look)
		map.data = data
		map._solids = {}
		b.build_barriers(Chunked.new())
		var counts: Dictionary = (b.mark_counts as Dictionary).duplicate()
		var quads := 0
		for k: Vector2i in b.mark_tiles:
			quads += b.mark_tiles[k].quads
		counts["poster quads"] = quads
		counts["poster tiles"] = (b.mark_tiles as Dictionary).size()
		if look == &"typed":
			first = counts
			var per_line := {}
			var totals := {}
			for e: Array in b.slogan_log:
				per_line[e[0]] = (per_line.get(e[0], []) as Array) + [float(e[1])]
				totals[e[0]] = float(e[2])
			var wall_m := 0.0
			for l: Dictionary in data.get("lines", []):
				if str(l.get("ty", "")) in (Solidity.marks_table().get("slogan", {}).get("share", {}) as Dictionary):
					var pts: PackedVector2Array = map._pts(l["p"])
					for i in pts.size() - 1:
						wall_m += pts[i].distance_to(pts[i + 1])
			for id: String in per_line:
				var ss: Array = per_line[id]
				ss.sort()
				if ss.size() > maxi(1, ceili(float(totals[id]) / 150.0)):
					problems.append("10 line %s has %d slogans in %.0f m" % [id, ss.size(), totals[id]])
				for i in range(1, ss.size()):
					if float(ss[i]) - float(ss[i - 1]) < 150.0 - 0.001:
						problems.append("10 line %s: two slogans %.0f m apart" % [id, float(ss[i]) - float(ss[i - 1])])
			if float(b.slogan_log.size()) > wall_m / 150.0:
				problems.append("10 %d slogans on %.0f m of slogan walls (one per 150 m at most)" % [b.slogan_log.size(), wall_m])
			out["slogan walls m"] = roundi(wall_m)
		elif var_to_str(counts) != var_to_str(first):
			problems.append("10 marks under panels %s, under typed %s" % [counts, first])
	out["counts"] = first
	map.data = {}
	map._solids = {}
	return out
