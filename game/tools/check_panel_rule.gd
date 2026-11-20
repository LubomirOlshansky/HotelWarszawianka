extends SceneTree
## W4 of the walls look (docs/design/walls-true-to-life.md 3, 6.4 and 10): the panels' pixel rule
## (game/scripts/panel_rule.gd) and the shader that draws it (game/shaders/panel.gdshader).
##   1 at 5, 10, 17 and 26 cm an image pixel, for every row drawn as panels: bars never closer than
##     2.5 pixels and never thinner than one, and the spacing the least doubling of the row's own
##     that keeps them so (no sparser than it must be); posts, rails and ribs never under a pixel;
##     the tint fill's cell at least a pixel, a power of two times 8 cm;
##   2 the same rule as the shader samples it (panel_rule.gd `sample`) along one row of pixels
##     across a 4 m stretch of each panel row at mid-height: every bar a run of at least one
##     pixel, two bars' middles never under 2.5 pixels apart, every post drawn;
##   3 panel.gdshader carries panel_rule.gd's numbers (BAR_GAP_PX, MIN_PX, CELL, RAIL, LOW_RAIL,
##     SINK; W5: GRAZE, the floors' cap at a grazing view) and the two formulas (the bar spacing and the cell, exp2 of a ceiled log2), and holds
##     its one discard behind `holes` and the car's hole;
##   4 the rows texture: 8 texels by 64 rows, one row per look in the palette's order, every
##     `panel` row flagged, the colours the palette's; the rows the walls doc's W4 names (six) are
##     the palette's `panel` rows;
##   5 a line's seed picks the alt colour city_barriers.gd `_typed` picks, for 400 ids of every
##     row with an alt;
##   6 W5 (walls doc 6.4): the tops and closed rows as `sample` draws them, 4 m of each panel row in
##     a grid of 2 cm: a `sag` row's top rail midway between two posts SAG lower than at a post, its
##     fill never over the sagging line; a `leafy` row's leaves never over the top nor under it by
##     more than LEAFY, and the edge not flat (a noise); a closed row (wood, hoarding, the hedges)
##     solid everywhere under its top line (no hole), a closed row's bars drawn as joints; a row with
##     `in_mesh` posts draws none in its panels; the shader carries SAG, LEAFY, LEAF_CELL,
##     LEAFY_FOOT, CLOSED and JOINT_SHADE as panel_rule.gd has them.
## Prints `check_panel_rule: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_panel_rule.gd

const PanelRule := preload("res://scripts/panel_rule.gd")
const Solidity := preload("res://scripts/solidity.gd")
const CityBarriers := preload("res://scripts/city_barriers.gd")
const SHADER := "res://shaders/panel.gdshader"
## The gate's pixel sizes (m): the closest zoom's finest, the default's two ends, the widest's.
const PIXELS: Array[float] = [0.05, 0.10, 0.17, 0.26]
## The walls doc's W4 rows (section 10): 173 km of light fences and low hedges; W5's, the rest of the
## light rows (rail_tram stays the tram's railing, `draw: keep`).
## The gate (walls doc 10), not panel_rule.gd's own numbers: bars at least this many pixels apart
## and this many wide.
const GATE_GAP := 2.5
const GATE_WIDTH := 1.0
const W4_ROWS: Array[StringName] = [&"fence_plain", &"bars_black", &"mesh_panel", &"chain_link", &"rail_street", &"hedge_low"]
const W5_ROWS: Array[StringName] = [&"green_fence", &"low_lawn", &"ball_net", &"wood", &"hoarding", &"hedge_tall",
		&"chain_posts", &"post_row", &"stadium_fence", &"bars_pier"]

var problems: Array[String] = []


func _initialize() -> void:
	var rows: Array[StringName] = []
	for id in Solidity.looks():
		if PanelRule.is_panel(id):
			rows.append(id)
	var bars_checked := 0
	for id in rows:
		bars_checked += _rule(id)
		_sampled(id)
	_shader()
	_texture(rows)
	_seeds()
	_tops(rows)
	if problems.is_empty():
		print("check_panel_rule: OK (%d panel rows, %d with bars, at %s m a pixel)" % [rows.size(), bars_checked, PIXELS])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_panel_rule: %d problems" % problems.size())
		quit(1)


## 1: the rule's numbers for one row; 1 when the row has bars.
func _rule(id: StringName) -> int:
	var row := Solidity.look_row(id)
	var bars := float(row.get("bars", 0.0))
	var post: Dictionary = row.get("post", {})
	for px in PIXELS:
		if bars > 0.0:
			var s := PanelRule.bar_spacing(bars, px)
			if s / px < GATE_GAP - 1e-6:
				problems.append("1 %s at %.2f m a pixel: bars %.3f m apart, %.2f px" % [id, px, s, s / px])
			if s > bars + 1e-6 and (s * 0.5) / px >= PanelRule.BAR_GAP_PX and (s * 0.5) / px >= GATE_GAP:
				problems.append("1 %s at %.2f m a pixel: bars %.3f m apart, half of it would do" % [id, px, s])
			if s < bars - 1e-6:
				problems.append("1 %s at %.2f m a pixel: bars %.3f m apart, under the row's %.3f" % [id, px, s, bars])
			if PanelRule.bar_width(px) / px < GATE_WIDTH - 1e-6:
				problems.append("1 %s at %.2f m a pixel: a bar %.3f m wide, under a pixel" % [id, px, PanelRule.bar_width(px)])
		if post.has("w") and PanelRule.band(float(post["w"]), px) < px - 1e-6:
			problems.append("1 %s at %.2f m a pixel: a post under a pixel" % [id, px])
		if PanelRule.band(PanelRule.RAIL, px) < px - 1e-6:
			problems.append("1 %s at %.2f m a pixel: a rail under a pixel" % [id, px])
		var c := PanelRule.cell(px)
		var k := c / PanelRule.CELL
		if c < px - 1e-6 or absf(k - pow(2.0, roundf(log(k) / log(2.0)))) > 1e-6 or (k > 1.5 and c * 0.5 >= px):
			problems.append("1 %s at %.2f m a pixel: a fill cell of %.3f m" % [id, px, c])
	return 1 if bars > 0.0 else 0


## 2: one row of pixels across a 4 m stretch at mid-height, sampled at the pixels' middles.
func _sampled(id: StringName) -> void:
	var row := Solidity.look_row(id)
	var t := PanelRule.row_texels(row)
	var h := float(row["h"])
	var foot := float((row.get("foot", {}) as Dictionary).get("h", 0.0))
	var v := foot + (h - foot) * 0.6
	var every := float((row.get("post", {}) as Dictionary).get("every", 0.0))
	var bars := float(row.get("bars", 0.0))
	for px in PIXELS:
		var n := ceili(4.0 / px)
		var runs: Array[Vector2] = []  # [first pixel, last pixel] of each bar
		var posts := 0
		var in_post := false
		for i in n:
			var u := 1.0 + (i + 0.5) * px  # away from the line's start
			var s := PanelRule.sample(t, u, v, h, px, 0.37)
			var what := str(s["what"])
			if what == "bar" or what == "joint":
				if not runs.is_empty() and int(runs[runs.size() - 1].y) == i - 1:
					runs[runs.size() - 1].y = i
				else:
					runs.append(Vector2(i, i))
			if what == "post" and not in_post:
				posts += 1
			in_post = what == "post"
		if bars > 0.0:
			# (W5: a leafy row's leaves cover its bars where they grow.)
			if runs.is_empty() and not row.has("leaf"):
				problems.append("2 %s at %.2f m a pixel: no bar drawn in 4 m" % [id, px])
			for k in range(1, runs.size()):
				var gap := (runs[k].x + runs[k].y) * 0.5 - (runs[k - 1].x + runs[k - 1].y) * 0.5
				if gap < GATE_GAP - 0.5 - 1e-6:
					problems.append("2 %s at %.2f m a pixel: two bars %.1f px apart" % [id, px, gap])
					break
		if every > 0.0 and t[4].g > 0.0:
			var want := floori(4.0 / every)
			if posts < want:
				problems.append("2 %s at %.2f m a pixel: %d posts in 4 m, want %d" % [id, px, posts, want])


## 3: the shader's numbers and formulas.
func _shader() -> void:
	var code := FileAccess.get_file_as_string(SHADER)
	if code == "":
		problems.append("3 no %s" % SHADER)
		return
	for pair: Array in [["BAR_GAP_PX", PanelRule.BAR_GAP_PX], ["MIN_PX", PanelRule.MIN_PX], ["CELL", PanelRule.CELL],
			["RAIL", PanelRule.RAIL], ["LOW_RAIL", PanelRule.LOW_RAIL], ["SINK", PanelRule.SINK],
			["GRAZE", PanelRule.GRAZE]]:
		var m := RegEx.create_from_string("const float %s = ([0-9.]+);" % pair[0]).search(code)
		if m == null or absf(float(m.get_string(1)) - float(pair[1])) > 1e-6:
			problems.append("3 %s: %s is not panel_rule.gd's %s" % [SHADER, pair[0], pair[1]])
	if code.count("exp2(max(ceil(log2(") != 2:
		problems.append("3 %s: the bar spacing and the fill cell are not both exp2(max(ceil(log2(...)), 0))" % SHADER)
	if code.count("discard;") != 1 or code.count("if (") != 1:
		problems.append("3 %s: one `if` and one discard, %d and %d" % [SHADER, code.count("if ("), code.count("discard;")])
	if not code.contains("render_mode cull_disabled, specular_disabled;"):
		problems.append("3 %s: not cull_disabled and diffuse only" % SHADER)


## 4: the rows texture.
func _texture(rows: Array[StringName]) -> void:
	var img := PanelRule.rows_image()
	if img.get_width() != PanelRule.ROW_TEXELS or img.get_height() != PanelRule.MAX_ROWS:
		problems.append("4 the rows texture is %dx%d" % [img.get_width(), img.get_height()])
		return
	var ids := Solidity.looks()
	if ids.size() > PanelRule.MAX_ROWS:
		problems.append("4 %d look rows, the texture holds %d" % [ids.size(), PanelRule.MAX_ROWS])
	for r in mini(ids.size(), PanelRule.MAX_ROWS):
		var row := Solidity.look_row(ids[r])
		if PanelRule.row_of(ids[r]) != r:
			problems.append("4 %s: row %d, row_of says %d" % [ids[r], r, PanelRule.row_of(ids[r])])
		var flagged := img.get_pixel(6, r).a > 0.5
		if flagged != PanelRule.is_panel(ids[r]):
			problems.append("4 %s: the texture's panel flag is %s" % [ids[r], flagged])
		if row.has("colour"):
			var want := Color(str(row["colour"]))
			var got := img.get_pixel(0, r)
			if absf(got.r - want.r) + absf(got.g - want.g) + absf(got.b - want.b) > 1e-4:
				problems.append("4 %s: colour %s in the texture, %s in the palette" % [ids[r], got, want])
	var want: Array[StringName] = []
	for id in Solidity.looks():
		if id in W4_ROWS or id in W5_ROWS:
			want.append(id)
	if rows != want:
		problems.append("4 the palette's panel rows are %s, the walls doc's W4 and W5 rows %s" % [rows, want])
	for id in Solidity.looks():
		var row := Solidity.look_row(id)
		if str(row.get("family", "")) == "light" and not PanelRule.is_panel(id) and id != &"rail_tram":
			problems.append("4 light row %s is not a panel row" % id)


## 5: the seed's alt against _typed's pick.
func _seeds() -> void:
	for id in Solidity.looks():
		var row := Solidity.look_row(id)
		var alt: Array = row.get("alt", [])
		if alt.is_empty():
			continue
		var t := PanelRule.row_texels(row)
		for i in 400:
			var sid := "barrier:fence:%d:%d" % [i * 2, 100 - i * 4]
			var pick := posmod(hash(sid), 1000)
			var upto := 0.0
			var want := Color(str(row["colour"]))
			for a: Array in alt:
				upto += float(a[1]) * 1000.0
				if pick < upto:
					want = Color(str(a[0]))
					break
			var s := PanelRule.seed(sid)
			var got: Color = t[0]
			if s < t[2].a:
				got = t[2]
			if s < t[1].a:
				got = t[1]
			if absf(got.r - want.r) + absf(got.g - want.g) + absf(got.b - want.b) > 1e-4:
				problems.append("5 %s, id %s: the seed picks %s, _typed %s" % [id, sid, got.to_html(false), want.to_html(false)])
				break


## 6: the tops, the closed rows, the leaves, the posts left to the mesh; the shader's numbers.
func _tops(rows: Array[StringName]) -> void:
	var px := 0.02
	for id in rows:
		var row := Solidity.look_row(id)
		var t := PanelRule.row_texels(row)
		var h := float(row["h"])
		var every := t[4].r
		var top := str(row.get("top", "flat"))
		var closed := float(row.get("open", 0.0)) <= PanelRule.CLOSED
		var leaves := row.has("leaf")
		var holes := 0
		var joints := 0
		var over := 0
		var edges := {}
		var n := ceili(4.0 / px)
		for i in n:
			var u := 1.0 + (i + 0.5) * px
			var line := h - (PanelRule.sag_drop(u, every) if top == "sag" else 0.0)
			var edge := PanelRule.leaf_edge(u, h, 0.37) if top == "leafy" else h
			if top == "leafy":
				edges[snappedf(edge, 0.01)] = true
				if edge > h + 1e-6 or edge < h - PanelRule.LEAFY - 1e-6:
					problems.append("6 %s: the leafy edge at %.2f m stands at %.3f of %.2f" % [id, u, edge, h])
					break
			for j in ceili(h / px):
				var v := (j + 0.5) * px
				var smp := PanelRule.sample(t, u, v, h, 0.02, 0.37)
				var what := str(smp["what"])
				if what == "joint":
					joints += 1
				if closed and not bool(smp["solid"]) and v < minf(line, edge) - px:
					holes += 1
				if bool(smp["solid"]) and v > line + 1e-6 and what != "post" and what != "foot":
					over += 1
				if what == "leaf" and v > edge + 1e-6:
					over += 1
		if holes > 0:
			problems.append("6 %s: a closed row with %d holes under its top" % [id, holes])
		if over > 0:
			problems.append("6 %s: %d pixels drawn over the top line or the leaves' edge" % [id, over])
		if closed and float(row.get("bars", 0.0)) > 0.0 and joints == 0:
			problems.append("6 %s: a closed row's bars drew no joint" % id)
		if top == "leafy" and edges.size() < 4:
			problems.append("6 %s: the leafy edge takes %d heights in 4 m (flat)" % [id, edges.size()])
		if top == "sag" and every > 0.0:
			var mid := PanelRule.sag_drop(every * 0.5, every)
			var at := PanelRule.sag_drop(every * 3.0, every)
			if absf(mid - PanelRule.SAG) > 1e-6 or absf(at) > 1e-6:
				problems.append("6 %s: the sag %.3f m midway, %.3f at a post" % [id, mid, at])
		var in_mesh := bool((row.get("post", {}) as Dictionary).get("in_mesh", false))
		if in_mesh and t[4].g != 0.0:
			problems.append("6 %s: its posts are the mesh's, the panel draws them %.2f wide" % [id, t[4].g])
		if leaves and t[7].a < 0.5:
			problems.append("6 %s: its leaves are not in the texture" % id)
	var code := FileAccess.get_file_as_string(SHADER)
	for pair: Array in [["SAG", PanelRule.SAG], ["LEAFY", PanelRule.LEAFY], ["LEAF_CELL", PanelRule.LEAF_CELL],
			["LEAFY_FOOT", PanelRule.LEAFY_FOOT], ["LEAFY_SHADE", PanelRule.LEAFY_SHADE], ["CLOSED", PanelRule.CLOSED],
			["JOINT_SHADE", PanelRule.JOINT_SHADE], ["PANEL", CityBarriers.PANEL]]:
		var m := RegEx.create_from_string("const float %s = ([0-9.]+);" % pair[0]).search(code)
		if m == null or absf(float(m.get_string(1)) - float(pair[1])) > 1e-6:
			problems.append("6 %s: %s is not %s" % [SHADER, pair[0], pair[1]])
