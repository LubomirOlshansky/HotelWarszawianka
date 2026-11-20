extends RefCounted
## W4 of the walls look (docs/design/walls-true-to-life.md 3 and 6.4): the panels' numbers in one
## pure place, so the shader (game/shaders/panel.gdshader), the builder (city_barriers.gd
## `panel_along`, map_builder.gd `_build_panels`) and the check (game/tools/check_panel_rule.gd)
## read the same rule.
##
## - The pixel rule (walls doc 3): posts and rails solid and never thinner than a pixel; bars at
##   the row's spacing doubled until they stand at least BAR_GAP_PX image pixels apart, each one
##   pixel wide, fixed to the fence (placed by the metres along the line, so they do not crawl as
##   the car moves); a tint fill (`bars` 0) a stipple on cells of the pixel size rounded up to a
##   power of two times CELL. panel.gdshader writes the same formulas; check_panel_rule holds both
##   to the gate (2.5 px apart, 1 px wide, at 5, 10, 17 and 26 cm a pixel) and to each other.
## - The rows texture: the palette's `looks` rows (solidity.gd), ROW_TEXELS texels a row, one row
##   a look in the palette's order (a line's row index is its type's place there), made once by
##   map_builder.gd `_make_shared` with the panel material (the prebuilt city keeps it under
##   map/shared/, as the trees' look texture).
## - W5 (walls doc 6.4): the tops. `sag` lowers the top edge (the top rail and the fill under it)
##   by up to SAG between posts, 4 t (1 - t) of the way from one post to the next; `leafy` cuts the
##   leaves' top edge by a value noise of the line's seed, at most LEAFY under the top, on cells of
##   LEAF_CELL along the line, and darkens the lowest LEAFY_FOOT. A closed row (`open` at most
##   CLOSED: wood, hoarding, the hedges) has no holes: its bars are board joints, a shade darker.
##   A row with a `leaf` colour (green_fence) has leaves on 1 - open of its fill's cells.

const Solidity := preload("res://scripts/solidity.gd")

## Bars never closer than this many image pixels (walls doc 3: "five bars instead of sixteen").
const BAR_GAP_PX := 2.5
## A bar, a rail or a post is never thinner than one image pixel.
const MIN_PX := 1.0
## The tint fill's finest cell (m): the pixel size rounded up to a power of two times this.
const CELL := 0.08
## A rail's height (m), the second rail's bottom over the foot's top: rail_lite_along's own
## (city_barriers.gd LITE_RAIL, LITE_LOW_RAIL), so a panel's rails sit where the typed ones do.
const RAIL := 0.06
const LOW_RAIL := 0.35
## How far a panel's box reaches under its foot (m): wall_along's slabs go 0.3 m into the ground,
## so a panel on a dip does not float.
const SINK := 0.3
## The panels' box: 10 triangles (four sides and the top), one panel piece a unit of it.
const BOX_TRIANGLES := 10

## The rows texture: texels a row and rows at most (64 x 8 RGBA floats, 8 KB).
const ROW_TEXELS := 8
const MAX_ROWS := 64
## `top` codes in texel 6 (W5 draws sag and leafy).
const TOPS := {"flat": 0.0, "sag": 1.0, "leafy": 2.0}
## W5: a sagging top's drop midway between two posts (m; walls doc 6.4: "up to 8 cm").
const SAG := 0.08
## W5: a leafy top: the deepest cut under the top (m), the noise's cell along the line (m), and the
## darkened band over the foot (m; walls doc 6.4: "the lowest 0.2 m") with its shade.
const LEAFY := 0.15
const LEAF_CELL := 0.3
const LEAFY_FOOT := 0.2
const LEAFY_SHADE := 0.75
## W5: a row this open or less is closed (walls doc 10: wood 0.08, hoarding 0): no holes, its bars
## drawn as joints JOINT_SHADE darker.
const CLOSED := 0.1
const JOINT_SHADE := 0.72


## The spacing of the bars drawn (m) for a row's `spacing` at `px` metres an image pixel: the
## spacing doubled until the bars stand BAR_GAP_PX pixels apart, never under the row's own.
## (The shader writes it spacing * exp2(max(ceil(log2(BAR_GAP_PX * px / spacing)), 0)).)
static func bar_spacing(spacing: float, px: float) -> float:
	if spacing <= 0.0:
		return 0.0
	return spacing * _doubling(BAR_GAP_PX * px / spacing)


## A drawn bar's width (m): one image pixel.
static func bar_width(px: float) -> float:
	return MIN_PX * px


## A band of the panel (a post's width, a rail's height) as drawn: its own size, or one image
## pixel when that is more.
static func band(size: float, px: float) -> float:
	return maxf(size, MIN_PX * px)


## The tint fill's cell (m) at `px` metres a pixel: CELL times the smallest power of two that
## keeps the cell at least a pixel.
static func cell(px: float) -> float:
	return CELL * _doubling(px / CELL)


## The smallest power of two (1 at least) that is `ratio` or more.
static func _doubling(ratio: float) -> float:
	var k := 1.0
	while k < ratio and k < 1e6:
		k *= 2.0
	return k


## A line's colour seed (0..1) from its stable id: the very pick city_barriers.gd `_typed` makes
## for the alt colour (posmod(hash(id), 1000)), half a step up, so "seed < share" in the shader
## picks what "pick < share x 1000" picks there.
static func seed(stable_id: String) -> float:
	return (float(posmod(hash(stable_id), 1000)) + 0.5) / 1000.0


## A barrier type's row in the rows texture (its place among the palette's looks), -1 for none.
static func row_of(ty: StringName) -> int:
	return Solidity.looks().find(ty)


## Whether type `ty`'s look row is drawn as panels under barrier_look panels (the palette's
## `panel` key: the six rows of W4).
static func is_panel(ty: StringName) -> bool:
	return bool(Solidity.look_row(ty).get("panel", false))


## The rows texture's image: per look row, in the palette's order, ROW_TEXELS texels (RGBA, the
## colours sRGB as the palette writes them; panel.gdshader converts them):
##   0 colour, open        1 alt colour, its share     2 the second alt, the two shares together
##   3 foot colour, foot h 4 post every, post width, rails, bar spacing
##   5 post colour, ribs   6 top (TOPS), thick, h, panel (1)   7 leaf colour, has leaves (1)
## (W5: a row whose posts are `in_mesh` gets post width 0: the city mesh stands them.)
static func rows_image() -> Image:
	var img := Image.create_empty(ROW_TEXELS, MAX_ROWS, false, Image.FORMAT_RGBAF)
	var ids := Solidity.looks()
	if ids.size() > MAX_ROWS:
		push_error("panel_rule: %d look rows, the rows texture holds %d" % [ids.size(), MAX_ROWS])
	for r in mini(ids.size(), MAX_ROWS):
		var t := row_texels(Solidity.look_row(ids[r]))
		for k in ROW_TEXELS:
			img.set_pixel(k, r, t[k])
	return img


## One look row's ROW_TEXELS texels (see rows_image).
static func row_texels(row: Dictionary) -> Array[Color]:
	var colour := _colour(row.get("colour", "#808080"))
	var alt: Array = row.get("alt", [])
	var a1 := colour
	var s1 := 0.0
	var a2 := colour
	var s2 := 0.0
	if alt.size() > 0:
		a1 = _colour((alt[0] as Array)[0])
		s1 = float((alt[0] as Array)[1])
	if alt.size() > 1:
		a2 = _colour((alt[1] as Array)[0])
		s2 = s1 + float((alt[1] as Array)[1])
	var foot: Dictionary = row.get("foot", {})
	var foot_col := _colour(foot["colour"]) if foot.has("colour") else colour.darkened(float(foot.get("darken", 0.0)))
	var post: Dictionary = row.get("post", {})
	var post_col := _colour(post["colour"]) if post.has("colour") else colour
	var post_w := 0.0 if bool(post.get("in_mesh", false)) else float(post.get("w", 0.0))
	var leaf := _colour(row["leaf"]) if row.has("leaf") else colour
	var out: Array[Color] = [
		Color(colour.r, colour.g, colour.b, float(row.get("open", 0.0))),
		Color(a1.r, a1.g, a1.b, s1),
		Color(a2.r, a2.g, a2.b, s2),
		Color(foot_col.r, foot_col.g, foot_col.b, float(foot.get("h", 0.0))),
		Color(float(post.get("every", 0.0)), post_w, float(row.get("rails", 0)), float(row.get("bars", 0.0))),
		Color(post_col.r, post_col.g, post_col.b, float(row.get("ribs", 0.0))),
		Color(float(TOPS.get(str(row.get("top", "flat")), 0.0)), float(row.get("thick", 0.05)), float(row.get("h", 1.0)),
				1.0 if bool(row.get("panel", false)) else 0.0),
		Color(leaf.r, leaf.g, leaf.b, 1.0 if row.has("leaf") else 0.0),
	]
	return out


static func _colour(v: Variant) -> Color:
	var s := str(v)
	return Color(s) if Color.html_is_valid(s) else Color(0.5, 0.5, 0.5)


## The rows texture (an ImageTexture of rows_image).
static func rows_texture() -> ImageTexture:
	return ImageTexture.create_from_image(rows_image())


## What the shader draws at a point of a panel, in GDScript for the check: `u` metres along the
## line, `v` metres up from the foot, `h` the panel's height, `px` metres an image pixel, the
## row's texels `t` (row_texels) and the line's `seed`. {"solid": bool, "what": "foot", "post",
## "rail", "bar", "joint", "leaf", "fill" or ""}. The shader's fragment() is this, in step / mix form.
## W5: the tops (`sag_drop`, `leaf_edge`), a closed row's joints, a leafy row's leaves.
static func sample(t: Array[Color], u: float, v: float, h: float, px: float, seed_v: float) -> Dictionary:
	var foot_h := t[3].a
	var every := t[4].r
	var pw := t[4].g
	var rails := t[4].b
	var bars := t[4].a
	var ribs := t[5].a
	var open := t[0].a
	var top := t[6].r
	var closed := open <= CLOSED
	var leaves := t[7].a > 0.5
	# The top line: sagging between posts, else the panel's height; a leafy row's leaves stop at
	# its noisy edge (a hedge is all leaves).
	var line := h - (sag_drop(u, every) if absf(top - 1.0) < 0.5 else 0.0)
	var edge := leaf_edge(u, h, seed_v) if top > 1.5 else h
	if v <= foot_h:
		return {"solid": true, "what": "foot"}
	if every > 0.0 and pw > 0.0:
		var d := absf(fposmod(u / every + 0.5, 1.0) - 0.5) * every
		if d <= band(pw, px) * 0.5:
			return {"solid": true, "what": "post"}
	var rail := band(RAIL, px)
	if rails >= 0.5 and v >= line - rail and v <= line:
		return {"solid": true, "what": "rail"}
	if rails >= 1.5 and absf(v - (foot_h + LOW_RAIL + RAIL * 0.5)) <= rail * 0.5:
		return {"solid": true, "what": "rail"}
	if v > line or (closed and not leaves and top > 1.5 and v > edge):
		return {"solid": false, "what": ""}
	var c := cell(px)
	var stipple := _hash12(Vector2(floorf(u / c), floorf(v / c)) + Vector2(seed_v * 17.0, 0.0)) < 1.0 - open
	if leaves and stipple and v <= edge:
		return {"solid": true, "what": "leaf"}
	if bars > 0.0:
		var s := bar_spacing(bars, px)
		if absf(fposmod(u / s + 0.5, 1.0) - 0.5) * s <= bar_width(px) * 0.5:
			return {"solid": true, "what": "joint" if closed else "bar"}
		return {"solid": closed, "what": "fill" if closed else ""}
	if ribs > 0.0 and absf(fposmod(v / ribs + 0.5, 1.0) - 0.5) * ribs <= band(0.0, px) * 0.5:
		return {"solid": true, "what": "rail"}
	var keep := closed or (stipple and not leaves)
	return {"solid": keep, "what": "fill" if keep else ""}


## W5: a sagging top's drop (m) at `u` m along the line, posts every `every` m: SAG x 4 t (1 - t),
## t the share of the way from the last post (0 at a post, SAG midway). No posts: no sag.
static func sag_drop(u: float, every: float) -> float:
	if every <= 0.0:
		return 0.0
	var f := fposmod(u / every, 1.0)
	return SAG * 4.0 * f * (1.0 - f)


## W5: a leafy top's edge (m over the foot) at `u` m along the line for the line's seed: the
## height less LEAFY times a value noise (two hashes of LEAF_CELL cells, smoothstepped between).
static func leaf_edge(u: float, h: float, seed_v: float) -> float:
	var x := u / LEAF_CELL
	var i := floorf(x)
	var f := x - i
	var s := f * f * (3.0 - 2.0 * f)
	var n := lerpf(_hash12(Vector2(i, seed_v * 31.0)), _hash12(Vector2(i + 1.0, seed_v * 31.0)), s)
	return h - LEAFY * n


## common.gdshaderinc's hash12, the same arithmetic (the check's stipple share).
static func _hash12(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d := p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)
