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
##     row (`unknown`) and none in barrier_default; the count of lines per draw kind is printed.
## Prints `check_barrier_look: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_barrier_look.gd

const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const Chunked := preload("res://scripts/chunked_surface.gd")
const PANEL_RHYTHMS := [2.0, 4.0]


## A flat world: the wall builder's terrain is 0 everywhere.
class FlatMap extends "res://scripts/map_builder.gd":
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0


var problems: Array[String] = []


func _initialize() -> void:
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
	if data is Dictionary:
		counts = _whole(map, data)
	map.free()
	if problems.is_empty():
		print("check_barrier_look: OK (%d look rows, %d types on the map; the whole map typed on a flat map: %s)" % [
				Solidity.looks().size(), types.size(), counts])
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
