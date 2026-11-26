extends RefCounted
## The pen of the full-screen 2D scenes drawn in code (palm_tasting_ui.gd first): cel-shaded shapes
## on the scene's 216-unit grid, drawn into a SubViewport whose canvas_transform scales the grid.
##   - pixel mode (`hard`, F 2026-11-26 19:33 "it should be the pixel style ... but with more
##     pixels", the isometric pixel-city reference): the viewport is the screen divided by a whole
##     number (~360-400 lines, almost twice the old 216), nearest-filtered, no antialiasing on
##     lines or words, so every edge is a hard stair of pixels; pixel_art.gdshader then adds the
##     one-pixel ink outlines and the ordered dither;
##   - smooth mode: the same shapes at screen resolution, linear-filtered (the stream's overlay).
##
## The light: one warm key from screen-left and a little above (golden hour, the sun low behind the
## Party House). `ball` and `limb` draw a form in its shade tone, the same form shifted and shrunk
## toward the light in its base tone, a highlight blob, and a thin rim on the lit edge: three tones
## and a rim, which is the whole "fake 3D".
##
## Text: the device's own bold sans (SystemFont), drawn at the target's pixel size; in pixel mode
## the same face without antialiasing.
##
## Cost: draw_colored_polygon / draw_polygon / draw_polyline calls only; a ball is ~4 polygons, a
## limb ~3, a figure ~100. Nothing allocated per frame but the point arrays.

## The key light's direction on screen (toward the light): left and a little up.
const LIGHT := Vector2(-0.86, -0.5)
## Shadows lean this way (away from the light), stretched on the ground.
const SHADOW := Color("#3a2a55")
const RIM := Color("#ffe2a8")
const OUTLINE := Color("#2a1f3d")

var ci: CanvasItem
## Device pixels per grid unit (for crisp text).
var k := 1.0
## Added to every point (parallax, the handheld sway, the shake).
var o := Vector2.ZERO
## Pixel mode: no antialiasing on lines, the hard-edged face for words.
var hard := false

static var _font: Font
static var _hard_font: Font


func _init(item: CanvasItem = null) -> void:
	ci = item


## The device's bold sans, one for every scene.
static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["SF Pro Rounded", "SF Pro Display", ".SF NS Rounded", "Helvetica Neue",
				"Roboto", "Noto Sans", "DejaVu Sans", "sans-serif"])
		f.font_weight = 800
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font = f
	return _font


## The same face with no antialiasing: words in the pixel layer are pixels too.
static func hard_font() -> Font:
	if _hard_font == null:
		var f := font().duplicate() as SystemFont
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NORMAL
		_hard_font = f
	return _hard_font


func _face() -> Font:
	return hard_font() if hard else font()


## A string's width in grid units at `size` units.
static func text_w(s: String, size: float) -> float:
	var px := maxi(4, roundi(size * 8.0))
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / 8.0


# --- shapes -------------------------------------------------------------------------------------

func _off(pts: PackedVector2Array) -> PackedVector2Array:
	if o == Vector2.ZERO:
		return pts
	var q := PackedVector2Array()
	q.resize(pts.size())
	for i in pts.size():
		q[i] = pts[i] + o
	return q


func poly(pts: PackedVector2Array, c: Color) -> void:
	if pts.size() >= 3 and c.a > 0.003:
		ci.draw_colored_polygon(_off(pts), c)


## A polygon with a colour per point (gradients).
func poly_cols(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.size() >= 3:
		ci.draw_polygon(_off(pts), cols)


func line(pts: PackedVector2Array, w: float, c: Color) -> void:
	if pts.size() >= 2 and c.a > 0.003:
		ci.draw_polyline(_off(pts), c, w, not hard)


func seg(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	line(PackedVector2Array([a, b]), w, c)


func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	if c.a > 0.003:
		ci.draw_rect(Rect2(Vector2(x, y) + o, Vector2(w, h)), c)


## A rect from `top` to `bot` colour.
func rect_v(x: float, y: float, w: float, h: float, top: Color, bot: Color) -> void:
	poly_cols(PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]),
			PackedColorArray([top, top, bot, bot]))


## A rect from `l` to `r` colour.
func rect_h(x: float, y: float, w: float, h: float, l: Color, r: Color) -> void:
	poly_cols(PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]),
			PackedColorArray([l, r, r, l]))


static func ell_pts(c: Vector2, r: Vector2, rot := 0.0, n := 24, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full := absf(a1 - a0) >= TAU - 0.001
	var steps := n if full else n + 1
	var cr := cos(rot)
	var sr := sin(rot)
	for i in steps:
		var a := a0 + (a1 - a0) * float(i) / float(n)
		var p := Vector2(cos(a) * r.x, sin(a) * r.y)
		pts.append(c + Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr))
	return pts


func ell(c: Vector2, r: Vector2, col: Color, rot := 0.0, n := 24) -> void:
	poly(ell_pts(c, r, rot, n), col)


## A soft round blob: `col` in the middle fading to nothing at the edge (shadows, glows, blush).
func blob(c: Vector2, r: Vector2, col: Color, n := 18) -> void:
	if col.a <= 0.003:
		return
	var edge := Color(col, 0.0)
	var ring := ell_pts(c, r, 0.0, n)
	var mid := ell_pts(c, r * 0.45, 0.0, n)
	for i in n:
		var j := (i + 1) % n
		poly_cols(PackedVector2Array([mid[i], ring[i], ring[j], mid[j]]), PackedColorArray([col, edge, edge, col]))
	poly(mid, col)


## The rounded rect's outline points (radius `rad`).
static func rr_pts(x: float, y: float, w: float, h: float, rad: float, n := 5) -> PackedVector2Array:
	var r := minf(rad, minf(w, h) * 0.5)
	var pts := PackedVector2Array()
	var cs := [Vector2(x + w - r, y + r), Vector2(x + w - r, y + h - r), Vector2(x + r, y + h - r), Vector2(x + r, y + r)]
	for q in 4:
		var a0 := -PI * 0.5 + q * PI * 0.5
		for i in n + 1:
			var a := a0 + PI * 0.5 * float(i) / float(n)
			pts.append((cs[q] as Vector2) + Vector2(cos(a), sin(a)) * r)
	return pts


func rrect(x: float, y: float, w: float, h: float, rad: float, c: Color) -> void:
	poly(rr_pts(x, y, w, h, rad), c)


## A rounded rect from `top` to `bot` colour.
func rrect_v(x: float, y: float, w: float, h: float, rad: float, top: Color, bot: Color) -> void:
	var pts := rr_pts(x, y, w, h, rad)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bot, clampf((p.y - y) / maxf(h, 0.01), 0.0, 1.0)))
	poly_cols(pts, cols)


func rrect_line(x: float, y: float, w: float, h: float, rad: float, lw: float, c: Color) -> void:
	var pts := rr_pts(x, y, w, h, rad)
	pts.append(pts[0])
	line(pts, lw, c)


## A star's points (`n` spikes, outer `r0`, inner `r1`, radii as Vector2 for an oval).
static func star_pts(c: Vector2, r0: Vector2, r1: Vector2, n: int, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + PI * float(i) / float(n)
		var r := r0 if i % 2 == 0 else r1
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


# --- forms (the fake 3D) -------------------------------------------------------------------------

## A shaded oval: the shade tone, the base tone shifted toward the light, a highlight, the rim.
func ball(c: Vector2, r: Vector2, base: Color, shade: Color, light: Color, rot := 0.0, rim := 0.6) -> void:
	ell(c, r, shade, rot)
	ell(c + LIGHT * r * 0.16, r * 0.84, base, rot)
	blob(c + LIGHT * r * 0.42, r * 0.36, Color(light, 0.7), 12)
	if rim > 0.0:
		line(ell_pts(c, r * 0.97, rot, 10, PI * 0.78, PI * 1.32), maxf(0.35, minf(r.x, r.y) * 0.08), Color(RIM, rim))


## A tapered capsule's points from `a` (radius `ra`) to `b` (radius `rb`).
static func capsule_pts(a: Vector2, b: Vector2, ra: float, rb: float, n := 8) -> PackedVector2Array:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return ell_pts(a, Vector2(ra, ra), 0.0, n * 2)
	var ang := d.angle()
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := ang + PI * 0.5 + PI * float(i) / float(n)
		pts.append(a + Vector2(cos(t), sin(t)) * ra)
	for i in n + 1:
		var t := ang - PI * 0.5 + PI * float(i) / float(n)
		pts.append(b + Vector2(cos(t), sin(t)) * rb)
	return pts


## A shaded limb (an arm, a leg): shade, the base toward the light, the rim on the lit side.
func limb(a: Vector2, b: Vector2, ra: float, rb: float, base: Color, shade: Color, rim := 0.5) -> void:
	poly(capsule_pts(a, b, ra, rb), shade)
	var d := (b - a).normalized()
	var side := Vector2(-d.y, d.x)
	if side.dot(LIGHT) < 0.0:
		side = -side
	poly(capsule_pts(a + side * ra * 0.22, b + side * rb * 0.22, ra * 0.72, rb * 0.72), base)
	if rim > 0.0:
		seg(a + side * ra * 0.86, b + side * rb * 0.86, maxf(0.3, minf(ra, rb) * 0.22), Color(RIM, rim))


## Any outline as a form: shade, then the base squeezed toward the lit side (anchor on its left).
func form(pts: PackedVector2Array, base: Color, shade: Color, squeeze := 0.8) -> void:
	poly(pts, shade)
	var lo := INF
	var hi := -INF
	var top := INF
	for p in pts:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
		top = minf(top, p.y)
	var q := PackedVector2Array()
	for p in pts:
		q.append(Vector2(lo + (p.x - lo) * squeeze, top + (p.y - top) * 0.985))
	poly(q, base)


## The dark accent line on the shaded side (right and bottom only, no black outline).
func edge(pts: PackedVector2Array, w := 0.5, a := 0.55) -> void:
	line(pts, w, Color(OUTLINE, a))


## The ground under something: a contact blob and the long golden-hour shadow to the right.
func ground(c: Vector2, w: float, len := 3.2, a := 0.42) -> void:
	blob(c + Vector2(w * len * 0.5, 0.6), Vector2(w * len * 0.62, w * 0.14), Color(SHADOW, a * 0.7), 14)
	blob(c, Vector2(w * 0.62, w * 0.12), Color(SHADOW, a), 14)


# --- text ---------------------------------------------------------------------------------------

## `s` at (x, y) (the top of the line), `size` units high; `align` -1 left, 0 centre, 1 right.
func text(s: String, x: float, y: float, size: float, c: Color, align := -1, shadow := 0.0, rot := 0.0) -> void:
	if s == "" or c.a <= 0.003:
		return
	var f := _face()
	var px := maxi(4, roundi(size * k))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / k
	var x0 := x - (w * 0.5 if align == 0 else (w if align > 0 else 0.0))
	var asc := f.get_ascent(px) / k
	var at := Vector2(x0, y) + o
	if rot != 0.0:
		var pivot := Vector2(x, y + size * 0.5) + o
		at = pivot + (at - pivot).rotated(rot)
	ci.draw_set_transform(at, rot, Vector2(1.0 / k, 1.0 / k))
	if shadow > 0.0:
		ci.draw_string(f, Vector2(shadow * k, asc * k + shadow * k), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(0, 0, 0, 0.45 * c.a))
	ci.draw_string(f, Vector2(0, asc * k), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)
	ci.draw_set_transform(Vector2.ZERO)


## `s` with a thick outline (the MLASK word, the grade).
func text_outlined(s: String, x: float, y: float, size: float, c: Color, ol: Color, ow: float, align := 0, rot := 0.0) -> void:
	if s == "":
		return
	var f := _face()
	var px := maxi(4, roundi(size * k))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / k
	var x0 := x - (w * 0.5 if align == 0 else (w if align > 0 else 0.0))
	var asc := f.get_ascent(px) / k
	var at := Vector2(x0, y) + o
	if rot != 0.0:
		var pivot := Vector2(x, y + size * 0.5) + o
		at = pivot + (at - pivot).rotated(rot)
	ci.draw_set_transform(at, rot, Vector2(1.0 / k, 1.0 / k))
	ci.draw_string_outline(f, Vector2(0, asc * k), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(1, roundi(ow * k)), ol)
	ci.draw_string(f, Vector2(0, asc * k), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)
	ci.draw_set_transform(Vector2.ZERO)


## Words wrapped to `w` units at `size`.
static func wrap(s: String, w: float, size: float) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in s.split(" ", false):
		var t := word if cur == "" else cur + " " + word
		if cur != "" and text_w(t, size) > w:
			out.append(cur)
			cur = word
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out


# --- easing -------------------------------------------------------------------------------------

static func ease_out(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return 1.0 - (1.0 - u) * (1.0 - u) * (1.0 - u)


static func ease_in_out(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


## The pop: 0 to `over` (1.15) and back to 1 over `t` 0..1 (squash and stretch for the burst, cards).
static func pop(t: float, over := 1.15) -> float:
	var u := clampf(t, 0.0, 1.0)
	if u < 0.6:
		return ease_out(u / 0.6) * over
	return lerpf(over, 1.0, ease_in_out((u - 0.6) / 0.4))
