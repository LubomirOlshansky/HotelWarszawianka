extends RefCounted
## Jarmark Warszawski 2026: the real market's objects, from the organiser's own map renders
## (/mnt/project-files/jarmark-2026-model/objects/object-spec.md, F's promo video, 2026-11-21), a
## class of static builders. Each takes `b`, the mesh builder (a landmarks/jarmark.gd instance with
## `map` and `st` set: the same object landmarks.gd and jarmark_rides.gd already make), a world
## origin `at` (x, z) and a `yaw` (radians, the local u axis turned from world +x towards +z), and
## adds its triangles to `b.st` with the city's building material codes (M_STONE plain, M_LAMP lit
## at night, M_LAMP + 0.5 lit blue at night). Nothing here is a new mesh system: every triangle
## goes through the facade kit's `_tri` / `_beam` (facade_kit.gd), so +0 draw calls and no node.
## `g` is the ground height under the origin (NAN: read from `b.map.terrain_height`). Heights are
## metres over that ground.
##
## Moving parts follow jarmark.gd's `_jm_*_spin` pattern: a separate `*_spin` function builds what
## turns about the origin (`at`), for jarmark_rides.gd's batches (the shader turns each batch about
## its ride's axis, which must be `at`):
##   tower_spin           -> ride TOWER (turns and runs down the mast TOWER_DROP, as now)
##   tree_ride_spin       -> ride TREE_RIDE (turns the fir and its gondolas)
##   venetian_spin(-1)    -> ride CAROUSEL (the canopy and crest); venetian_spin(0..11) -> HORSE + k/12
##   teacups_spin         -> ride TEACUPS (the cups)
## Everything else is static. No brand name or logo anywhere: parody or plain.
## Helper copies: `string` is jarmark.gd `_jm_string` (bulbs on a sagging wire), `rider` calls
## jarmark.gd `_jm_rider`; the colours the spec gives are the constants below.

const M_STONE := 3.0
const M_LAMP := 10.0
const M_LAMP_BLUE := 10.5
const NOUV := Vector2(-1, -1)
const CLEAR := Color(0, 0, 0, 0)
## jarmark.gd TOWER_TOP: the carrier's height when built (the shader drops it TOWER_DROP = 18.9).
const TOWER_TOP := 26.0

const WHITE := Color("#f2f0ea")
const SNOW := Color("#f4f6fa")
const WIRE := Color("#2b2c2f")
const BULB := Color(1.0, 0.84, 0.55)
const LED := Color(0.9, 0.94, 1.0)
const GOLD := Color("#e3b34a")
const RED := Color("#c8342a")
const FIR := Color("#2e5a2e")
const WOOD := Color("#7a4a20")
## The market's multicolour bulbs: red, yellow, green, white (the official huts).
const RAINBOW := [Color("#e8333a"), Color("#f08a24"), Color("#f2d230"), Color("#4cc35a"), Color("#2fa8e0"),
		Color("#3a5be0"), Color("#9a4ad8")]
const MULTI := [Color("#e03a2a"), Color("#f2c230"), Color("#4cb050"), Color("#f4efe6")]


## Local frame of one object: origin `o`, unit axes u and v in the plan, ground height g. Every
## shape below is a method of it, so a builder function reads in the object's own metres.
class Ctx extends RefCounted:
	var b
	var o := Vector2.ZERO
	var u := Vector2.RIGHT
	var v := Vector2.DOWN
	var g := 0.0

	func _init(builder, at: Vector2, yaw: float, ground := NAN) -> void:
		b = builder
		o = at
		u = Vector2.from_angle(yaw)
		v = Vector2(-u.y, u.x)
		g = ground
		if is_nan(g):
			g = float(b.map.terrain_height(at.x, at.y))
		b._g = g

	## World plan point of local (lu, lv).
	func w(lu: float, lv: float) -> Vector2:
		return o + u * lu + v * lv

	## World position of local (lu, lv) at height y over the ground.
	func p(lu: float, lv: float, y: float) -> Vector3:
		var q := o + u * lu + v * lv
		return Vector3(q.x, g + y, q.y)

	## World plan direction of a local angle.
	func dir(ang: float) -> Vector2:
		return u * cos(ang) + v * sin(ang)

	func noroof(on: bool) -> void:
		b._no_roof = on

	## One triangle (any winding; `n` the outward normal, else from the corners).
	func tri(a: Vector3, c: Vector3, d: Vector3, col: Color, mode: float, n := Vector3.ZERO) -> void:
		var nn := n
		if n == Vector3.ZERO:
			nn = (c - a).cross(d - a)
		if (c - a).cross(d - a).length_squared() < 1e-9:
			return
		b._mode = mode
		b._tri(a, c, d, nn.normalized(), col, NOUV, NOUV, NOUV, -1.0)

	func quad(a: Vector3, c: Vector3, d: Vector3, e: Vector3, col: Color, mode: float, n := Vector3.ZERO, both := false) -> void:
		var nn := n
		if n == Vector3.ZERO:
			nn = (d - a).cross(e - c)
		tri(a, c, d, col, mode, nn)
		tri(a, d, e, col, mode, nn)
		if both:
			tri(a, d, c, col, mode, -nn)
			tri(a, e, d, col, mode, -nn)

	## A box turned by local angle `ang` about its centre (lu, lv): half sizes hu along, hv across.
	func pbox(lu: float, lv: float, ang: float, hu: float, hv: float, y0: float, y1: float, col: Color,
			top := CLEAR, mode := M_STONE, bottom := false) -> void:
		var e := dir(ang)
		var f := Vector2(-e.y, e.x)
		var c := w(lu, lv)
		var pts: Array[Vector2] = [c - e * hu - f * hv, c + e * hu - f * hv, c + e * hu + f * hv, c - e * hu + f * hv]
		for i in 4:
			var a := pts[i]
			var d := pts[(i + 1) % 4]
			var nrm := Vector2(d.y - a.y, a.x - d.x).normalized()
			quad(Vector3(a.x, g + y0, a.y), Vector3(d.x, g + y0, d.y), Vector3(d.x, g + y1, d.y), Vector3(a.x, g + y1, a.y),
					col, mode, Vector3(nrm.x, 0.0, nrm.y))
		var tc := top if top.a > 0.0 else col
		quad(Vector3(pts[0].x, g + y1, pts[0].y), Vector3(pts[1].x, g + y1, pts[1].y), Vector3(pts[2].x, g + y1, pts[2].y),
				Vector3(pts[3].x, g + y1, pts[3].y), tc, mode, Vector3.UP)
		if bottom:
			quad(Vector3(pts[0].x, g + y0, pts[0].y), Vector3(pts[1].x, g + y0, pts[1].y), Vector3(pts[2].x, g + y0, pts[2].y),
					Vector3(pts[3].x, g + y0, pts[3].y), tc.darkened(0.3), mode, Vector3.DOWN)

	## A box between local u0..u1, v0..v1.
	func box(u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, col: Color, top := CLEAR,
			mode := M_STONE, bottom := false) -> void:
		pbox((u0 + u1) * 0.5, (v0 + v1) * 0.5, 0.0, (u1 - u0) * 0.5, (v1 - v0) * 0.5, y0, y1, col, top, mode, bottom)

	## The world ring of an n-gon round local (lu, lv).
	func ring(lu: float, lv: float, r: float, n: int, rot := 0.0) -> PackedVector2Array:
		var out := PackedVector2Array()
		var c := w(lu, lv)
		for k in n:
			out.append(c + dir(rot + TAU * float(k) / float(n)) * r)
		return out

	## A flat n-gon fan at height y, facing up (or down).
	func disc(lu: float, lv: float, r: float, n: int, y: float, col: Color, mode := M_STONE, up := true, rot := 0.0) -> void:
		var rg := ring(lu, lv, r, n, rot)
		var c := p(lu, lv, y)
		for k in n:
			var a := rg[k]
			var d := rg[(k + 1) % n]
			tri(c, Vector3(a.x, c.y, a.y), Vector3(d.x, c.y, d.y), col, mode, Vector3.UP if up else Vector3.DOWN)

	## Walls of an n-gon from y0 to y1 and (top.a > 0) its flat top.
	func prism(lu: float, lv: float, r: float, n: int, y0: float, y1: float, col: Color, top := CLEAR, mode := M_STONE,
			top_mode := -1.0, rot := 0.0) -> void:
		frustum(lu, lv, r, y0, r, y1, n, col, top, mode, top_mode, rot)

	## Sides from radius r0 at y0 to r1 at y1 (r1 or r0 may be 0: a cone), then a flat top.
	func frustum(lu: float, lv: float, r0: float, y0: float, r1: float, y1: float, n: int, col: Color, top := CLEAR,
			mode := M_STONE, top_mode := -1.0, rot := 0.0, alt := CLEAR) -> void:
		var c := w(lu, lv)
		var ra := ring(lu, lv, r0, n, rot)
		var rb := ring(lu, lv, r1, n, rot)
		for k in n:
			var j := (k + 1) % n
			var p0 := Vector3(ra[k].x, g + y0, ra[k].y)
			var p1 := Vector3(ra[j].x, g + y0, ra[j].y)
			var p2 := Vector3(rb[j].x, g + y1, rb[j].y)
			var p3 := Vector3(rb[k].x, g + y1, rb[k].y)
			var nrm := (p2 - p0).cross(p3 - p1)
			var mid := (ra[k] + ra[j] + rb[k] + rb[j]) * 0.25 - c
			if Vector2(nrm.x, nrm.z).dot(mid) < 0.0:
				nrm = -nrm
			var cc := col
			if alt.a > 0.0 and k % 2 == 1:
				cc = alt
			quad(p0, p1, p2, p3, cc, mode, nrm)
		if top.a > 0.0 and r1 > 0.01:
			disc(lu, lv, r1, n, y1, top, mode if top_mode < 0.0 else top_mode, true, rot)

	## A ball of radius r about (lu, lv, cy): `rings` bands of an n-gon, one colour.
	func sphere(lu: float, lv: float, cy: float, r: float, n: int, rings: int, col: Color, mode := M_STONE) -> void:
		for i in rings:
			var a0 := -PI * 0.5 + PI * float(i) / float(rings)
			var a1 := -PI * 0.5 + PI * float(i + 1) / float(rings)
			frustum(lu, lv, maxf(r * cos(a0), 0.0), cy + r * sin(a0), maxf(r * cos(a1), 0.0), cy + r * sin(a1), n, col, CLEAR, mode)

	## A beam between two world points.
	func beam(a: Vector3, c: Vector3, wd: float, col: Color, mode := M_STONE) -> void:
		b._beam(a, c, wd, col, false, mode)

	## A beam between two local points (lu, lv, y).
	func lbeam(a: Vector3, c: Vector3, wd: float, col: Color, mode := M_STONE) -> void:
		b._beam(p(a.x, a.y, a.z), p(c.x, c.y, c.z), wd, col, false, mode)

	## A tiny lit diamond (8 triangles): a bulb of half-size s at a world point.
	func bulb(q: Vector3, s: float, col: Color, mode := M_LAMP) -> void:
		var pts: Array[Vector3] = [q + Vector3(s, 0, 0), q + Vector3(-s, 0, 0), q + Vector3(0, s * 1.2, 0),
				q + Vector3(0, -s * 1.2, 0), q + Vector3(0, 0, s), q + Vector3(0, 0, -s)]
		for top in [2, 3]:
			for pair in [[0, 4], [4, 1], [1, 5], [5, 0]]:
				var a: Vector3 = pts[top]
				var d: Vector3 = pts[pair[0]]
				var e: Vector3 = pts[pair[1]]
				tri(a, d, e, col, mode, ((d + e + a) / 3.0 - q))

	func lbulb(lu: float, lv: float, y: float, s: float, col: Color, mode := M_LAMP) -> void:
		bulb(p(lu, lv, y), s, col, mode)

	## A ring of bulbs round (lu, lv) at radius r, height y, colours cycling through `cols`.
	func bulb_ring(lu: float, lv: float, r: float, y: float, n: int, s: float, cols: Array, mode := M_LAMP, rot := 0.0) -> void:
		var rg := ring(lu, lv, r, n, rot)
		for k in n:
			bulb(Vector3(rg[k].x, g + y, rg[k].y), s, cols[k % cols.size()], mode)

	## A flat polygon panel standing on the plan at local (lu, lv), facing local angle `out`; `pts`
	## are (along the face's tangent, height over the ground), a convex outline; seen from both sides
	## when `both`.
	func panel(lu: float, lv: float, out: float, pts: Array, col: Color, mode := M_LAMP, both := false, lift := 0.0) -> void:
		var f := dir(out)
		var t := Vector2(-f.y, f.x)
		var base := w(lu, lv) + f * lift
		var vs: Array[Vector3] = []
		for q in pts:
			var qq: Vector2 = q
			var pl := base + t * qq.x
			vs.append(Vector3(pl.x, g + qq.y, pl.y))
		var n3 := Vector3(f.x, 0.0, f.y)
		for k in range(1, vs.size() - 1):
			tri(vs[0], vs[k], vs[k + 1], col, mode, n3)
			if both:
				tri(vs[0], vs[k + 1], vs[k], col, mode, -n3)

	## A rectangle panel of width wd, y0..y1.
	func rect_panel(lu: float, lv: float, out: float, wd: float, y0: float, y1: float, col: Color, mode := M_LAMP,
			both := false, lift := 0.0) -> void:
		var h := wd * 0.5
		panel(lu, lv, out, [Vector2(-h, y0), Vector2(h, y0), Vector2(h, y1), Vector2(-h, y1)], col, mode, both, lift)

	## A round-topped (arched) opening panel.
	func arch_panel(lu: float, lv: float, out: float, wd: float, y0: float, y1: float, col: Color, mode := M_LAMP, lift := 0.0) -> void:
		var h := wd * 0.5
		var ys := y1 - h
		var pts: Array = [Vector2(-h, y0), Vector2(h, y0), Vector2(h, ys)]
		for k in range(1, 4):
			var a := PI * float(k) / 4.0
			pts.append(Vector2(h * cos(a), ys + h * sin(a)))
		pts.append(Vector2(-h, ys))
		panel(lu, lv, out, pts, col, mode, false, lift)

	## A round plate (n-gon) standing on a face: a medallion, a lamp disc.
	func round_panel(lu: float, lv: float, out: float, r: float, yc: float, n: int, col: Color, mode := M_LAMP, lift := 0.0) -> void:
		var pts: Array = []
		for k in n:
			var a := TAU * float(k) / float(n)
			pts.append(Vector2(r * cos(a), yc + r * sin(a)))
		panel(lu, lv, out, pts, col, mode, false, lift)

	## A flat disc tilted to face `normal`, `thick` thick, lit on both faces (the tower's top disc).
	func tilted_disc(centre: Vector3, normal: Vector3, r: float, thick: float, n: int, col: Color, rim: Color, mode := M_LAMP) -> void:
		var nn := normal.normalized()
		var t1 := nn.cross(Vector3.UP)
		if t1.length_squared() < 0.001:
			t1 = Vector3.RIGHT
		t1 = t1.normalized()
		var t2 := nn.cross(t1).normalized()
		var h := nn * thick * 0.5
		var pts: Array[Vector3] = []
		for k in n:
			var a := TAU * float(k) / float(n)
			pts.append(centre + (t1 * cos(a) + t2 * sin(a)) * r)
		for k in n:
			var j := (k + 1) % n
			tri(centre + h, pts[k] + h, pts[j] + h, col, mode, nn)
			tri(centre - h, pts[j] - h, pts[k] - h, rim, M_STONE, -nn)
			quad(pts[k] - h, pts[j] - h, pts[j] + h, pts[k] + h, rim, M_STONE, (pts[k] + pts[j]) * 0.5 - centre)

	## A flat slab from a to c: `w0` wide at a, `w1` at c, `th` thick; `side` the way its width lies.
	func slab(a: Vector3, c: Vector3, w0: float, w1: float, th: float, col: Color, mode := M_STONE) -> void:
		var d := (c - a).normalized()
		var s := d.cross(Vector3.UP)
		if s.length_squared() < 0.001:
			s = Vector3.RIGHT
		s = s.normalized()
		var nn := s.cross(d).normalized()
		var hv := nn * th * 0.5
		var a0 := a - s * w0 * 0.5
		var a1 := a + s * w0 * 0.5
		var c0 := c - s * w1 * 0.5
		var c1 := c + s * w1 * 0.5
		quad(a0 + hv, a1 + hv, c1 + hv, c0 + hv, col, mode, nn)
		quad(a0 - hv, c0 - hv, c1 - hv, a1 - hv, col, mode, -nn)
		quad(a0 - hv, a0 + hv, c0 + hv, c0 - hv, col, mode, -s)
		quad(a1 - hv, c1 - hv, c1 + hv, a1 + hv, col, mode, s)
		quad(a0 - hv, a1 - hv, a1 + hv, a0 + hv, col, mode, -d)
		quad(c0 - hv, c0 + hv, c1 + hv, c1 - hv, col, mode, d)

	## A string of bulbs from a to c (world), sagging: `_jm_string` of jarmark.gd, in this frame.
	func string(a: Vector3, c: Vector3, sag: float, col := BULB) -> void:
		var prev := a
		for k in range(1, 5):
			var t := float(k) / 4.0
			var at := a.lerp(c, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
			beam(prev, at, 0.03, WIRE)
			prev = at
		var n := maxi(3, ceili(a.distance_to(c) / 1.25))
		for k in range(1, n):
			var t := float(k) / float(n)
			bulb(a.lerp(c, t) - Vector3.UP * (sag * 4.0 * t * (1.0 - t) + 0.15), 0.1, col)

	## jarmark.gd's rider on a seat at local (lu, lv), facing local angle `ang`, y over the ground.
	func rider(lu: float, lv: float, ang: float, y: float, n: int, s := 1.0) -> void:
		if b.has_method("_jm_rider"):
			b._jm_rider(w(lu, lv), dir(ang), g + y, n, s)

	## jarmark.gd's `_jm_word` (pixel blocks on a -v face) in this frame: y over the ground, h tall.
	func word(text: String, lu: float, lv: float, y: float, h: float, col: Color, mode := M_LAMP) -> void:
		var keep: Array = [b._o, b._a, b._b]
		b._o = o
		b._a = u
		b._b = v
		b._jm_word(text, lu, lv, g + y, h, col, mode)
		b._o = keep[0]
		b._a = keep[1]
		b._b = keep[2]

	## A gable roof along u (ridge at v = 0, height y + rise), overhanging by ou and ov, its two slopes
	## and the two end triangles. Roof faces and rakes are one-sided up; seen from both sides.
	func gable(hu: float, hv: float, y: float, rise: float, wall: Color, roof: Color, roof_back := CLEAR, ou := 0.15, ov := 0.4) -> void:
		var rb := roof_back if roof_back.a > 0.0 else roof.darkened(0.25)
		var xu := hu + ou
		var xv := hv + ov
		var top := y + rise
		var fa := p(-xu, -xv, y)
		var fb := p(xu, -xv, y)
		var fc := p(xu, 0.0, top)
		var fd := p(-xu, 0.0, top)
		quad(fa, fb, fc, fd, roof, M_STONE, Vector3.ZERO, true)
		quad(p(xu, xv, y), p(-xu, xv, y), p(-xu, 0.0, top), p(xu, 0.0, top), rb, M_STONE, Vector3.ZERO, true)
		for sd: float in [-1.0, 1.0]:
			var tn := Vector3(u.x * sd, 0.0, u.y * sd)
			tri(p(sd * xu, -xv, y), p(sd * xu, xv, y), p(sd * xu, 0.0, top), wall, M_STONE, tn)
			tri(p(sd * xu, -xv, y), p(sd * xu, 0.0, top), p(sd * xu, xv, y), wall, M_STONE, -tn)

	## A hip roof over a rectangle hu x hv at height y, rising `rise` to a ridge half `rh` long.
	func hip(hu: float, hv: float, y: float, rise: float, rh: float, col: Color, col2 := CLEAR) -> void:
		var c2 := col2 if col2.a > 0.0 else col.darkened(0.15)
		var r0 := p(-rh, 0.0, y + rise)
		var r1 := p(rh, 0.0, y + rise)
		quad(p(-hu, -hv, y), p(hu, -hv, y), r1, r0, col, M_STONE, Vector3.ZERO, true)
		quad(p(hu, hv, y), p(-hu, hv, y), r0, r1, col, M_STONE, Vector3.ZERO, true)
		tri(p(hu, -hv, y), p(hu, hv, y), r1, c2, M_STONE, Vector3.ZERO)
		tri(p(-hu, hv, y), p(-hu, -hv, y), r0, c2, M_STONE, Vector3.ZERO)

	## A fir: a trunk and three tiers of needles, optional white bulbs and snow on the tier edges.
	func fir(lu: float, lv: float, h: float, lit := true, snow := false, col := FIR) -> void:
		c_trunk(lu, lv, h)
		for k in 3:
			var y0 := h * (0.18 + 0.27 * float(k))
			var r0 := h * 0.34 * (1.0 - 0.25 * float(k))
			frustum(lu, lv, r0, y0, r0 * 0.2, y0 + h * 0.42, 8, col, CLEAR, M_STONE, -1.0, 0.3 * float(k))
			if lit:
				bulb_ring(lu, lv, r0 * 0.9, y0 + 0.04, 6, h * 0.022, [LED, BULB], M_LAMP, 0.4 * float(k))
			if snow:
				disc(lu, lv, r0 * 0.5, 8, y0 + h * 0.2, SNOW, M_STONE)
		if lit:
			bulb(p(lu, lv, h + 0.05), h * 0.04, Color("#ffe9a0"))

	func c_trunk(lu: float, lv: float, h: float) -> void:
		prism(lu, lv, h * 0.04 + 0.05, 5, 0.0, h * 0.25, WOOD.darkened(0.2))

	## A canopy grid y = f(u, v): quads over u0..u1, v0..v1 in nu x nv cells, facing up.
	func surface(u0: float, u1: float, v0: float, v1: float, nu: int, nv: int, f: Callable, col: Color, col2 := CLEAR) -> void:
		for i in nu:
			for j in nv:
				var ua := lerpf(u0, u1, float(i) / nu)
				var ub := lerpf(u0, u1, float(i + 1) / nu)
				var va := lerpf(v0, v1, float(j) / nv)
				var vb := lerpf(v0, v1, float(j + 1) / nv)
				var a := p(ua, va, f.call(ua, va))
				var bb := p(ub, va, f.call(ub, va))
				var cc := p(ub, vb, f.call(ub, vb))
				var d := p(ua, vb, f.call(ua, vb))
				var nn := (cc - a).cross(d - bb)
				if nn.y < 0.0:
					nn = -nn
				var cl := col2 if (col2.a > 0.0 and i % 2 == 1) else col
				quad(a, bb, cc, d, cl, M_STONE, nn, true)

	## A cylinder lying on its side: axis along local angle `ang`, radius r, half length `half`, centre
	## (lu, lv) at height yc; round sides in `col`, both end discs in `cap`.
	func drum(lu: float, lv: float, ang: float, r: float, half: float, yc: float, n: int, col: Color, cap: Color, mode := M_STONE) -> void:
		var e := dir(ang)
		var f := Vector2(-e.y, e.x)
		var cc := p(lu, lv, yc)
		var e3 := Vector3(e.x, 0.0, e.y)
		var ring_pts: Array[Vector3] = []
		for k in n:
			var a := TAU * float(k) / float(n)
			ring_pts.append(Vector3(f.x * cos(a), sin(a), f.y * cos(a)) * r)
		for k in n:
			var j := (k + 1) % n
			var nn := (ring_pts[k] + ring_pts[j]).normalized()
			quad(cc - e3 * half + ring_pts[k], cc - e3 * half + ring_pts[j], cc + e3 * half + ring_pts[j], cc + e3 * half + ring_pts[k], col, mode, nn)
			tri(cc + e3 * half, cc + e3 * half + ring_pts[k], cc + e3 * half + ring_pts[j], cap, mode, e3)
			tri(cc - e3 * half, cc - e3 * half + ring_pts[j], cc - e3 * half + ring_pts[k], cap, mode, -e3)

	## A polyline in the u-y plane at local v = lv: pts are (u, y); beams of width `wd`, optionally closed.
	func poly(pts: Array, lv: float, wd: float, col: Color, closed := false, mode := M_LAMP) -> void:
		var n := pts.size()
		for i in (n if closed else n - 1):
			var a: Vector2 = pts[i]
			var d: Vector2 = pts[(i + 1) % n]
			lbeam(Vector3(a.x, lv, a.y), Vector3(d.x, lv, d.y), wd, col, mode)

	## Bulbs every `step` m along a polyline in the u-y plane.
	func poly_bulbs(pts: Array, lv: float, step: float, sz: float, col: Color) -> void:
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var d: Vector2 = pts[i + 1]
			var cnt := maxi(1, int(round(a.distance_to(d) / step)))
			for k in cnt:
				var q := a.lerp(d, float(k) / float(cnt))
				lbulb(q.x, lv, q.y, sz, col)

	## A snowman at local (lu, lv), `k` the scale (1 = 2.5 m): white lit balls, black hat, orange nose.
	func snowman_at(lu: float, lv: float, k: float) -> void:
		var white := Color("#d8dee8")
		sphere(lu, lv, 0.6 * k, 0.6 * k, 12, 6, white, M_LAMP)
		sphere(lu, lv, 1.5 * k, 0.45 * k, 10, 5, white, M_LAMP)
		sphere(lu, lv, 2.15 * k, 0.32 * k, 10, 5, white, M_LAMP)
		prism(lu, lv, 0.34 * k, 10, 2.38 * k, 2.42 * k, WIRE, WIRE)
		prism(lu, lv, 0.2 * k, 10, 2.42 * k, 2.75 * k, WIRE, WIRE)
		prism(lu, lv, 0.4 * k, 10, 1.9 * k, 2.0 * k, Color("#c01c28"))
		lbeam(Vector3(lu, lv - 0.3 * k, 2.15 * k), Vector3(lu, lv - 0.7 * k, 2.1 * k), 0.07 * k, Color("#e87a24"))
		lbeam(Vector3(lu - 0.4 * k, lv, 1.6 * k), Vector3(lu - 0.95 * k, lv, 1.95 * k), 0.05 * k, WOOD)
		lbeam(Vector3(lu + 0.4 * k, lv, 1.6 * k), Vector3(lu + 0.95 * k, lv, 1.95 * k), 0.05 * k, WOOD)

	func done() -> void:
		b._no_roof = false
		b._mode = M_STONE


# ---------------------------------------------------------------------------------------------
# 1. The viewing tower ride (karuzela widokowa)
# ---------------------------------------------------------------------------------------------

const TOWER_NAVY := Color("#1e3a8a")
const TOWER_GREY := Color("#8a8a90")
const TOWER_MAST := Color("#2a3a9a")
const TOWER_PINK := Color("#f07070")
const TOWER_HUB := Color("#d9962e")
## The mast: 30 m (the coordinator's second reading of the sprites: 26-30 m; the spec leaves it open, the wheel hub at TOWER_TOP 26).
const TOWER_H := 30.0
## --pov-swing (main.gd POV_CHAIR): the empty chair the eye rides, and the other chains' softer white.
const POV_CHAIR := 3
const POV_METAL := Color(0.55, 0.57, 0.62)
const POV_JACKETS := [Color("#f2efe8"), Color("#ffd23a"), Color("#ff5a5a"), Color("#7fd0ff"), Color("#c9f06a"), Color("#ffa0c8")]
const POV_HATS := [Color("#d8262b"), Color("#f4f2ee"), Color("#2a4fd0"), Color("#1d1d22")]
const CHAIRS := [Color("#f2c230"), Color("#e03a2a"), Color("#5a8cff"), Color("#4cb050")]


## The tower ride's still parts: the 13 m grey platform with its navy skirt, white rail and
## stair, the blue-violet mast (30 m) with eight white LED lines and a ring of blue dots round its
## foot, and the pink-red disc on top, tilted up to the drone. `tilt` is the local angle the disc
## faces (default -v).
static func tower_static(b, at: Vector2, yaw := 0.0, g := NAN, tilt := -PI * 0.5) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.prism(0, 0, 6.5, 16, 0.0, 0.8, TOWER_NAVY, TOWER_GREY, M_STONE, M_STONE)
	# The white rail round the platform, with a gap for the stair at local -v.
	c.noroof(true)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := TAU * float(k + 1) / 16.0
		if k == 12:
			continue
		var p0 := Vector3(cos(a), sin(a), 0.0) * 6.3
		var p1 := Vector3(cos(d), sin(d), 0.0) * 6.3
		c.lbeam(Vector3(p0.x, p0.y, 0.8), Vector3(p0.x, p0.y, 1.7), 0.08, WHITE)
		c.lbeam(Vector3(p0.x, p0.y, 1.7), Vector3(p1.x, p1.y, 1.7), 0.07, WHITE)
	c.noroof(false)
	# The stair: three steps out at local -v.
	for s in 3:
		c.box(-1.0, 1.0, -6.5 - 0.6 * (s + 1), -6.5 + 0.2, 0.0, 0.8 - 0.25 * (s + 1) * 0.8, TOWER_GREY.darkened(0.1))
	# The mast's collar with its ring of blue dots, then the mast.
	c.frustum(0, 0, 2.3, 0.8, 1.0, 2.2, 16, TOWER_NAVY, CLEAR)
	c.bulb_ring(0, 0, 2.0, 1.05, 16, 0.12, [Color(0.3, 0.5, 1.0)], M_LAMP, 0.1)
	c.bulb_ring(0, 0, 1.7, 1.55, 12, 0.1, [Color(0.5, 0.65, 1.0)], M_LAMP, 0.2)
	# The mast: a lit blue tube, four bright blue vertical LED lines, and a few pink-magenta segments.
	c.prism(0, 0, 0.7, 8, 2.2, TOWER_H, TOWER_MAST, CLEAR, M_LAMP)
	for seg in [[7.0, 8.6], [14.0, 15.4], [21.0, 22.6], [27.0, 28.2]]:
		c.prism(0, 0, 0.73, 8, seg[0], seg[1], Color("#e0309a"), CLEAR, M_LAMP)
	c.noroof(true)
	var mr := c.ring(0, 0, 0.76, 8, 0.0)
	for k in [0, 2, 4, 6]:
		c.beam(Vector3(mr[k].x, c.g + 2.2, mr[k].y), Vector3(mr[k].x, c.g + TOWER_H, mr[k].y), 0.1, Color("#6a96ff"), M_LAMP)
	c.noroof(false)
	# The disc on top: a stem, then a pink-red lamp disc tilted towards the camera.
	c.prism(0, 0, 0.45, 8, TOWER_H, TOWER_H + 1.1, TOWER_MAST.darkened(0.2))
	var face := c.dir(tilt)
	var nrm := Vector3(face.x * 0.62, 0.78, face.y * 0.62)
	c.tilted_disc(c.p(0, 0, TOWER_H + 1.9), nrm, 1.45, 0.3, 14, TOWER_PINK, TOWER_PINK.darkened(0.35))
	c.done()


## The tower ride's turning carrier (built at TOWER_TOP; the shader runs it round and down the
## mast): the orange sphere hub (r 1.8), twenty lit spokes to a flat white wheel (r 6, plus an
## inner ring), and twenty chairs hanging on chains swung out to r 8.3, a rider in three of four.
## `flyer` (promo only, --promo-flyer: F's phone video 2026-11-22, the swing against the Palace): the
## spokes slant up to the rim like an umbrella and the rim is 5 m and the chairs fly out 32 degrees on 6.5 m chains, as the
## real ride at full speed, the chains and chairs lit white as in the video at night.
static func tower_spin(b, at: Vector2, yaw := 0.0, g := NAN, riders := true, rest := TOWER_TOP, flyer := false) -> void:
	var pov := false
	for a: String in OS.get_cmdline_user_args():
		pov = pov or a.begins_with("--pov-swing")
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	var yc := rest  # keep TOWER_TOP unless the shader's TOWER_DROP changes with it
	# flyer (F's video): a pink-white hub with bigger white dots, steady instead of flickering red specks.
	c.sphere(0, 0, yc, 1.8, 12, 6, Color("#f2c9d8") if flyer else TOWER_HUB, M_LAMP)
	# About thirty red LED dots over the hub (a golden-angle spread).
	for q in 30:
		var phi := acos(1.0 - 2.0 * (float(q) + 0.5) / 30.0)
		var th := float(q) * 2.39996
		c.lbulb(sin(phi) * cos(th) * 1.86, sin(phi) * sin(th) * 1.86, yc + cos(phi) * 1.86, 0.22 if flyer else 0.12, LED if flyer else Color("#ff2a2a"))
	var n := 20
	var rim_prev := Vector3.ZERO
	var first := Vector3.ZERO
	for j in n:
		var t := TAU * (float(j) + 0.5) / float(n)
		var d := Vector2(cos(t), sin(t))
		var hub := Vector3(d.x * 1.7, d.y * 1.7, yc + 0.35)
		var rim_z := yc + 2.2 if flyer else yc - 0.25
		var rr := 5.0 if flyer else 6.0
		var tip := Vector3(d.x * rr, d.y * rr, rim_z)
		# --pov-swing (F 2026-11-23: "better it doesn't glow"): from the chairs the carrier is matte metal.
		c.lbeam(Vector3(hub.x, hub.y, hub.z), Vector3(tip.x, tip.y, tip.z), 0.17, POV_METAL if pov else WHITE, M_STONE if pov else M_LAMP)
		var inner := Vector3(d.x * 3.7, d.y * 3.7, yc + 0.05)
		if j > 0:
			c.lbeam(Vector3(rim_prev.x, rim_prev.y, rim_prev.z), Vector3(tip.x, tip.y, tip.z), 0.14, POV_METAL if pov else WHITE, M_STONE if pov else M_LAMP)
		else:
			first = tip
		rim_prev = tip
		c.lbulb(d.x * rr, d.y * rr, rim_z + 0.15, 0.2, LED)
		c.lbulb(inner.x, inner.y, yc + 0.1, 0.14, LED)
		# The chair on two chains, swung out.
		var seat := Vector2(d.x, d.y) * (rr + 6.5 * sin(deg_to_rad(32.0)) if flyer else 8.3)
		var tang := Vector2(-d.y, d.x)
		var sy := rim_z - 6.5 * cos(deg_to_rad(32.0)) - 0.62 if flyer else yc - 6.3
		for sd: float in [-1.0, 1.0]:
			# --pov-swing rides chair 3: its own chains stay dark and thin (lit, right by the eye, they
			# burned out a quarter of the frame), the others' a softer white (F 2026-11-23).
			var own := pov and j == POV_CHAIR
			c.lbeam(Vector3(d.x * rr + tang.x * sd * 0.25, d.y * rr + tang.y * sd * 0.25, rim_z),
					Vector3(seat.x + tang.x * sd * 0.27, seat.y + tang.y * sd * 0.27, sy + 0.62),
					0.035 if own else (0.05 if pov else (0.09 if flyer else 0.04)),
					WIRE if (own or not flyer) else (POV_METAL if pov else LED), M_STONE if (own or not flyer or pov) else M_LAMP)
		var col: Color = CHAIRS[j % 4]
		var ang := t + PI * 0.5
		# POV (F 2026-11-23: "why do their legs hang sideways, not forward"): the real chairs face the way
		# they fly, along the rim (tang), not out from the mast.
		var face := d
		if pov:
			ang = t
			face = tang
		c.pbox(seat.x, seat.y, ang, 0.32, 0.27, sy, sy + 0.12, Color("#2a2d36"))
		var back := seat - face * 0.25
		if pov and j == POV_CHAIR:
			c.pbox(back.x, back.y, ang, 0.32, 0.04, sy, sy + 0.62, Color("#2a2d36"))
		else:
			# POV: the chairs in their own colours, matte, so a rider reads against them (no glow).
			c.pbox(back.x, back.y, ang, 0.32, 0.04, sy, sy + 0.62, col if pov else (LED if flyer else col), CLEAR, M_STONE if pov else M_LAMP)
		if flyer and not pov:
			# The real chairs carry a white lamp each at night (F's video): a dot at the chain's foot.
			c.lbulb(seat.x, seat.y, sy + 0.7, 0.22, LED)
		if riders and j % 4 != 3:
			# The POV take sees the riders from 3 m (F: "make the person clearer, so it reads as a swing"):
			# a size up, and legs hanging over the seat's front in jeans.
			# F (2026-11-23): the riders as in take k, a size up in the POV.
			c.rider(seat.x - face.x * 0.05, seat.y - face.y * 0.05, ang, sy + 0.12, j, 1.3 if pov else 1.0)
			if pov:
				for sd: float in [-1.0, 1.0]:
					var side := Vector2(-face.y, face.x)
					var lp := seat + face * 0.3 + side * sd * 0.09
					c.pbox(lp.x, lp.y, ang, 0.06, 0.07, sy - 0.42, sy + 0.12, Color("#7f98bd"))
					c.pbox(lp.x + face.x * 0.05, lp.y + face.y * 0.05, ang, 0.07, 0.11, sy - 0.5, sy - 0.42, Color("#151518"))
	# Close the rim.
	c.lbeam(Vector3(rim_prev.x, rim_prev.y, rim_prev.z), Vector3(first.x, first.y, first.z), 0.14, POV_METAL if pov else WHITE, M_STONE if pov else M_LAMP)
	# The second, smaller LED ring.
	for j in n:
		var a := TAU * (float(j) + 0.5) / float(n)
		var d := TAU * (float(j) + 1.5) / float(n)
		c.lbeam(Vector3(cos(a) * 3.7, sin(a) * 3.7, yc + 0.05), Vector3(cos(d) * 3.7, sin(d) * 3.7, yc + 0.05), 0.07, WHITE, M_LAMP)
	c.done()


# ---------------------------------------------------------------------------------------------
# 2. The Christmas-tree carousel (karuzela choinka): one object, the market's big tree
# ---------------------------------------------------------------------------------------------

const TREE_FLOOR := Color("#5a8a30")
const TREE_H := 11.0
const BAUBLE := [Color("#d6252c"), Color("#e8b030"), Color("#d6252c"), Color("#f4efe6")]


## The tree carousel's still parts: a green floor disc (r 4.6, 24 sides) with snow patches and a
## slatted wooden fence 0.6 m high round it, a gap at local -v for the entrance.
static func tree_ride_static(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.prism(0, 0, 4.6, 24, 0.0, 0.35, WOOD.darkened(0.1), TREE_FLOOR, M_STONE, M_STONE)
	# Snow patches: low white blobs lying on the floor.
	var patches := [[-1.2, 2.4, 0.9], [2.6, 1.0, 0.7], [-3.0, -0.8, 0.8], [0.8, -2.8, 1.0], [3.0, -2.1, 0.6], [-2.1, -2.6, 0.55]]
	for pt in patches:
		c.disc(pt[0], pt[1], pt[2], 7, 0.37, SNOW, M_STONE, true, pt[0])
	# The fence: slats between posts, two rails.
	c.noroof(true)
	var slats := 40
	for k in slats:
		var a := TAU * float(k) / float(slats)
		if absf(wrapf(a - PI * 1.5, -PI, PI)) < 0.2:
			continue
		var x := cos(a) * 4.45
		var y := sin(a) * 4.45
		c.pbox(x, y, a + PI * 0.5, 0.07, 0.025, 0.35, 0.95, WOOD, WOOD.lightened(0.1))
	for h: float in [0.5, 0.78]:
		for k in 24:
			var a := TAU * float(k) / 24.0
			var d := TAU * float(k + 1) / 24.0
			if absf(wrapf(a - PI * 1.5, -PI, PI)) < 0.2:
				continue
			c.lbeam(Vector3(cos(a) * 4.5, sin(a) * 4.5, h), Vector3(cos(d) * 4.5, sin(d) * 4.5, h), 0.06, WOOD.darkened(0.15))
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		c.pbox(cos(a) * 4.5, sin(a) * 4.5, a, 0.09, 0.09, 0.35, 1.05, WOOD.darkened(0.2), WOOD)
	c.bulb_ring(0, 0, 4.5, 1.12, 24, 0.07, [LED, BULB], M_LAMP)
	c.noroof(false)
	# A big gold drum prop by the fence (on its side, as in F's photo).
	c.drum(2.9, 3.3, 0.9, 0.9, 0.5, 1.25, 14, Color("#d8a830"), Color("#efe2a8"))
	c.done()


## The tree carousel's turning part (F's photos): the 11 m fir of wide flat sheet-metal fronds (green,
## seven whorls of nine, drooping 35 degrees, ragged) each with a thin white snow strip on top
## and tiny purple-white LED dots, up to 16 glossy red and gold baubles (2.4 m low to 0.8 m high); lit violet-blue at night hanging
## off them, a gold star, and eight yellow-gold drum gondolas round the base.
static func tree_ride_spin(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	c.prism(0, 0, 0.32, 8, 0.35, TREE_H, WOOD.darkened(0.25))
	var whorls := 7
	var droop := deg_to_rad(35.0)
	# At night the tree stays green under its own floodlights (F on site, 2026-11-22: green sheet
	# fronds, white snow, cold white and pale blue LED dots); the fronds are a dim M_LAMP green (the
	# colour is the strength).
	var frond := Color("#17704a")
	var led_cols := [Color("#e8f0ff"), Color("#8fb0ff")]
	var placed: Array = []  # [x, y, z, r] of the baubles so far: no two overlap
	var per_whorl := [3, 2, 2, 2, 2, 3, 2]
	for k in whorls:
		var t := float(k) / float(whorls - 1)
		var y := lerpf(4.3, 10.0, t)
		var len0 := lerpf(4.2, 0.9, t)
		c.frustum(0, 0, len0 * cos(droop) * 0.55, y - len0 * sin(droop) * 0.5, 0.15, y + 0.9, 10, frond.darkened(0.5), CLEAR, M_LAMP)
		var count := 9
		for j in count:
			var h := float((j * 7 + k * 13) % 10) / 10.0
			var len := len0 * (0.82 + 0.3 * h)
			var a := TAU * float(j) / float(count) + 0.62 * float(k) + 0.12 * (h - 0.5)  # the boughs spiral up the trunk
			var dp := droop + deg_to_rad(8.0) * (h - 0.5)
			var d := Vector2(cos(a), sin(a))
			var run := len * cos(dp)
			var root := Vector3(d.x * 0.25, d.y * 0.25, y + 0.1)
			var tip := Vector3(d.x * run, d.y * run, y - len * sin(dp))
			var wd := 0.45 + 0.75 * clampf(len / 4.2, 0.0, 1.0)
			c.slab(c.p(root.x, root.y, root.z), c.p(tip.x, tip.y, tip.z), wd, wd * 0.3, 0.1, frond if (j + k) % 2 == 0 else frond.lightened(0.12), M_LAMP)
			# A thinner snow strip along the upper edge (about a third of the frond's width).
			var s0 := root.lerp(tip, 0.15)
			var s1 := root.lerp(tip, 0.95)
			c.slab(c.p(s0.x, s0.y, s0.z + 0.085), c.p(s1.x, s1.y, s1.z + 0.085), wd * 0.33, wd * 0.18, 0.08, Color("#f2f5f8"))
			# Dense violet-blue LED dots on both halves of the frond (nine each).
			for q_i in 9:
				var f := 0.22 + 0.085 * float(q_i)
				var q := root.lerp(tip, f)
				var side := Vector2(-d.y, d.x) * wd * 0.3 * (1.0 if q_i % 2 == 0 else -1.0)
				c.lbulb(q.x + side.x, q.y + side.y, q.z + 0.1, 0.06, led_cols[(q_i + j) % 2])
			# A big glossy bauble, 1.5 m wide low down to 0.8 m near the top, clear of the others and the floor.
			var m: int = per_whorl[k]
			if (j * m) % count < m and placed.size() < 16:
				var br := lerpf(1.2, 0.4, t)  # the lowest up to 2.4 m wide
				var q := root.lerp(tip, 0.5 if k == 0 else 0.7)
				var cz := q.z - 0.2 - br
				var ok := cz > 0.35 + br + 0.15
				for pl in placed:
					if Vector3(pl[0], pl[1], pl[2]).distance_to(Vector3(q.x, q.y, cz)) < float(pl[3]) + br + 0.15:
						ok = false
				if ok:
					placed.append([q.x, q.y, cz, br])
					var bcol: Color = Color("#d6252c") if (placed.size() % 3 != 0) else Color("#e0b030")
					c.lbeam(Vector3(q.x, q.y, q.z), Vector3(q.x, q.y, cz + br), 0.04, WIRE)
					c.sphere(q.x, q.y, cz, br, 10, 5, bcol, M_STONE)
	# The crown: a small cone and the gold star (two crossed).
	c.frustum(0, 0, 0.55, 10.0, 0.0, 11.5, 8, frond)
	b._mode = M_LAMP
	b._jm_star(c.p(0, 0, 12.2), 1.25, Vector3(c.u.x, 0.0, c.u.y), Color("#e8b030"))
	b._jm_star(c.p(0, 0, 12.2), 1.25, Vector3(c.v.x, 0.0, c.v.y), Color("#e8b030"))
	# The star's outline in warm bulbs, in both planes.
	for pl in 2:
		var prev := Vector2.ZERO
		for q in 11:
			var ang := PI * 0.5 + TAU * float(q) / 10.0
			var rr := 1.35 if q % 2 == 0 else 0.58
			var pt := Vector2(cos(ang), sin(ang)) * rr
			var lu := pt.x if pl == 0 else 0.0
			var lv := pt.x if pl == 1 else 0.0
			c.lbulb(lu, lv, 12.2 + pt.y, 0.13, Color("#ffd878"))
			if q > 0:
				var mid := (pt + prev) * 0.5
				c.lbulb(mid.x if pl == 0 else 0.0, mid.x if pl == 1 else 0.0, 12.2 + mid.y, 0.1, Color("#ffd878"))
			prev = pt
	# The gondolas are the tree's big toys (F 2026-11-22, on site: "people inside the toys"): six
	# glossy baubles 2 m wide, gold and red, open all round at chest height (a white cage band) so the
	# two riders show, hung off the lowest boughs; three ride low by the floor, three up in the boughs.
	for j in 6:
		var a := TAU * float(j) / 6.0 + TAU / 12.0
		var d := Vector2(cos(a), sin(a))
		var low := j % 2 == 0
		var rr := 3.75 if low else 3.3
		var gx := d.x * rr
		var gy := d.y * rr
		var cz := 1.45 if low else 4.0
		var col: Color = Color("#e0b030") if j % 3 != 1 else Color("#d6252c")
		var hang := cz + 1.0
		c.lbeam(Vector3(gx, gy, hang + (1.2 if low else 0.6)), Vector3(gx, gy, hang), 0.06, WIRE)
		# The bowl (the bauble's lower half) and its cap (the upper third), a gap between.
		c.frustum(gx, gy, 0.35, cz - 0.98, 0.78, cz - 0.6, 12, col, col)
		c.frustum(gx, gy, 0.78, cz - 0.6, 1.0, cz - 0.05, 12, col, WHITE)
		c.frustum(gx, gy, 0.98, cz + 0.45, 0.72, cz + 0.8, 12, col, col)
		c.frustum(gx, gy, 0.72, cz + 0.8, 0.2, cz + 1.0, 12, col, col)
		c.disc(gx, gy, 0.96, 12, cz + 0.44, WHITE, M_STONE)
		# The white cage band: four bars joining bowl and cap.
		for q in 4:
			var qa := a + PI * 0.25 + TAU * float(q) / 4.0
			c.lbeam(Vector3(gx + cos(qa) * 0.97, gy + sin(qa) * 0.97, cz - 0.05), Vector3(gx + cos(qa) * 0.97, gy + sin(qa) * 0.97, cz + 0.45), 0.06, WHITE)
		c.bulb_ring(gx, gy, 1.0, cz - 0.05, 10, 0.06, [BULB], M_LAMP)
		var s := Vector2(-d.y, d.x) * 0.3
		c.rider(gx + s.x, gy + s.y, a, cz - 0.55, j * 2 + 2, 0.65)
		c.rider(gx - s.x, gy - s.y, a, cz - 0.55, j * 2 + 3, 0.65)
	c.done()


# ---------------------------------------------------------------------------------------------
# 3. The kurant (the tiered octagonal bar)
# ---------------------------------------------------------------------------------------------

const KURANT_CREAM := Color("#e8d8c0")
const KURANT_GREEN := Color("#3e8f65")
const KURANT_GREEN_D := Color("#1c4f3a")
const KURANT_CAP := Color("#d8c8b0")
const KURANT_WARM := Color("#ffc98a")
const KURANT_BULB := Color(1.0, 0.86, 0.6)


## The kurant (F's photos): a white octagonal bar (r 3.6, 2.4 m) with a red front panel under a lit
## hatch (three gold bars, no words), a wide low dark-grey skirt roof (r 4.8 at 2.6 m to r 2.4 at
## 3.3 m), and four stepped octagonal tiers (r 2.5 / 2.2 / 1.9 / 1.6, 2.4 m each: 5 m across at the
## foot, to 12.9 m): white planked walls with a dark-grey post at every corner; dark-grey louvred
## shutters on the lowest; red printed panels (a snowflake and a balloon) on the second and fourth; a
## thick fir garland (0.35 m) with red and gold baubles and warm bulbs round every tier edge; a dark
## collar to 13.4 m. The red six-sided turning crown on top (to 15.4 m) is `kurant_spin`. `strings`:
## twelve bulb strings fan from the top to poles `fan` m round.
static func kurant(b, at: Vector2, yaw := 0.0, g := NAN, strings := true, fan := 13.0) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var rot := PI / 8.0  # a flat face towards local +u
	var post := Color("#3a3d42")
	var red := Color("#b8282a")
	c.prism(0, 0, 3.6, 8, 0.0, 2.4, WHITE, Color("#4a4c50"), M_STONE, M_STONE, rot)
	var apo := 3.6 * cos(PI / 8.0)
	for k in 8:
		var out := rot + TAU * (float(k) + 0.5) / 8.0
		var ox := cos(out)
		var oy := sin(out)
		if k % 2 == 0:
			c.rect_panel(ox * (apo + 0.03), oy * (apo + 0.03), out, 1.9, 1.05, 2.1, KURANT_WARM, M_LAMP)
			c.pbox(ox * (apo + 0.22), oy * (apo + 0.22), out + PI * 0.5, 1.05, 0.2, 0.95, 1.05, WOOD)
			c.rect_panel(ox * (apo + 0.03), oy * (apo + 0.03), out, 1.9, 0.12, 0.92, red, M_STONE)
			for q in 3:
				c.rect_panel(ox * (apo + 0.05), oy * (apo + 0.05), out, 1.3 - 0.25 * float(q), 0.3 + 0.2 * float(q), 0.36 + 0.2 * float(q), GOLD, M_STONE)
		var cc := rot + TAU * float(k) / 8.0
		c.pbox(cos(cc) * 3.62, sin(cc) * 3.62, cc, 0.07, 0.07, 0.0, 2.4, post)
	var roof := Color("#3c3e44")
	c.disc(0, 0, 4.8, 8, 2.6, roof.darkened(0.5), M_STONE, false, rot)
	c.frustum(0, 0, 4.8, 2.6, 2.4, 3.3, 8, roof, CLEAR, M_STONE, -1.0, rot, roof.darkened(0.25))
	c.noroof(true)
	var outer := c.ring(0, 0, 4.8, 8, rot)
	for k in 8:
		var j := (k + 1) % 8
		c.beam(Vector3(outer[k].x, c.g + 2.6, outer[k].y), Vector3(outer[j].x, c.g + 2.6, outer[j].y), 0.1, Color("#8a8c92"))
		c.bulb(Vector3(outer[k].x, c.g + 2.45, outer[k].y), 0.11, KURANT_BULB)
		var mid := (outer[k] + outer[j]) * 0.5
		c.bulb(Vector3(mid.x, c.g + 2.45, mid.y), 0.11, KURANT_BULB)
	c.noroof(false)
	var radii := [2.5, 2.2, 1.9, 1.6]
	var y := 3.3
	for t in 4:
		var r: float = radii[t]
		var ap := r * cos(PI / 8.0)
		c.prism(0, 0, r, 8, y, y + 2.4, WHITE, CLEAR, M_STONE, -1.0, rot)
		for k in 8:
			var cc := rot + TAU * float(k) / 8.0
			c.pbox(cos(cc) * (r + 0.02), sin(cc) * (r + 0.02), cc, 0.07, 0.07, y, y + 2.4, post)
			var out := rot + TAU * (float(k) + 0.5) / 8.0
			var ox := cos(out) * (ap + 0.03)
			var oy := sin(out) * (ap + 0.03)
			var ox2 := cos(out) * (ap + 0.045)
			var oy2 := sin(out) * (ap + 0.045)
			if t == 0:
				c.rect_panel(ox, oy, out, r * 0.62, y + 0.45, y + 1.85, Color("#3a3c42"), M_STONE)
				for q in 6:
					c.rect_panel(ox2, oy2, out, r * 0.6, y + 0.58 + 0.2 * float(q), y + 0.63 + 0.2 * float(q), Color("#5a5d64"), M_STONE)
			elif t % 2 == 1:
				c.rect_panel(ox, oy, out, r * 0.72, y + 0.2, y + 2.2, red, M_STONE)
				c.panel(ox2, oy2, out, _star_pts(0.6, y + 1.5), Color("#e4a0a0"), M_STONE)
				c.round_panel(ox2, oy2, out, 0.22, y + 0.7, 8, Color("#e8c070"), M_STONE)
		# At night the tiers glow soft green (F's photos): lit green strips under the garland and above
		# the foot of every tier, and a green panel on the plain white tiers.
		var green := Color("#2fa860")
		for k in 8:
			var out := rot + TAU * (float(k) + 0.5) / 8.0
			var gx := cos(out) * (ap + 0.05)
			var gy := sin(out) * (ap + 0.05)
			c.rect_panel(gx, gy, out, r * 0.7, y + 2.0, y + 2.28, green, M_LAMP)
			c.rect_panel(gx, gy, out, r * 0.7, y + 0.06, y + 0.3, green, M_LAMP)
			if t == 2:
				c.rect_panel(gx, gy, out, r * 0.6, y + 0.5, y + 1.8, green.darkened(0.35), M_LAMP)
		# The garland round the tier's top edge: 0.35 m of fir, red and gold baubles, warm bulbs.
		c.noroof(true)
		var gr := c.ring(0, 0, r + 0.12, 8, rot)
		for k in 8:
			var j := (k + 1) % 8
			c.beam(Vector3(gr[k].x, c.g + y + 2.4, gr[k].y), Vector3(gr[j].x, c.g + y + 2.4, gr[j].y), 0.35, FIR)
		for k in 16:
			var a := TAU * (float(k) + 0.5) / 16.0
			var bc := Color("#d6252c") if k % 2 == 0 else Color("#e0b030")
			c.sphere(cos(a) * (r + 0.28), sin(a) * (r + 0.28), y + 2.42, 0.15, 6, 3, bc)
			c.lbulb(cos(a + 0.2) * (r + 0.3), sin(a + 0.2) * (r + 0.3), y + 2.48, 0.06, KURANT_BULB)
		c.noroof(false)
		y += 2.4
	# The dark collar under the crown.
	c.prism(0, 0, 1.3, 6, y, y + 0.5, post, Color("#2a2c30"))
	if strings:
		var top := c.p(0, 0, y + 2.5)
		for k in 12:
			var a := TAU * (float(k) + 0.5) / 12.0
			var pw := c.w(cos(a) * fan, sin(a) * fan)
			var pg: float = float(b.map.terrain_height(pw.x, pw.y))
			c.beam(Vector3(pw.x, pg, pw.y), Vector3(pw.x, pg + 4.0, pw.y), 0.09, WIRE)
			c.noroof(true)
			c.string(top, Vector3(pw.x, pg + 4.0, pw.y), 0.9)
			c.noroof(false)
	c.done()


## The kurant's turning crown (F's photos): a six-sided box wider at the top (r 1.2 at 13.4 m to r 2.2
## at 15.4 m), red faces with white edges and a lighter white snowflake on each. Turn it slowly
## about `at` (the rides shader: about one revolution in 12-20 s, a new ride number).
static func kurant_spin(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var y0 := 13.4
	var y1 := 15.4
	var red := Color("#b8282a")
	c.frustum(0, 0, 1.2, y0, 2.2, y1, 6, red.darkened(0.25), red.darkened(0.4), M_LAMP)  # lit red at night
	var a := c.ring(0, 0, 1.2, 6, 0.0)
	var t := c.ring(0, 0, 2.2, 6, 0.0)
	c.noroof(true)
	for k in 6:
		var j := (k + 1) % 6
		var pa := Vector3(a[k].x, c.g + y0, a[k].y)
		var pb := Vector3(a[j].x, c.g + y0, a[j].y)
		var pc := Vector3(t[j].x, c.g + y1, t[j].y)
		var pd := Vector3(t[k].x, c.g + y1, t[k].y)
		c.beam(pa, pd, 0.1, WHITE)
		c.beam(pd, pc, 0.1, WHITE)
		# A snowflake on the face, lying in its plane, lifted out a little.
		var cen := (pa + pb + pc + pd) * 0.25
		var tx := (pb - pa).normalized()
		var sy := ((pd + pc) * 0.5 - (pa + pb) * 0.5).normalized()
		var nn := tx.cross(sy)
		if Vector2(nn.x, nn.z).dot(Vector2(cen.x - c.o.x, cen.z - c.o.y)) < 0.0:
			nn = -nn
		var pts: Array[Vector3] = []
		for q in 12:
			var ang := TAU * float(q) / 12.0
			var rr := 0.7 if q % 2 == 0 else 0.28
			pts.append(cen + nn * 0.03 + tx * cos(ang) * rr + sy * sin(ang) * rr)
		for q in 12:
			c.tri(cen + nn * 0.03, pts[q], pts[(q + 1) % 12], Color("#f4f0e8"), M_STONE, nn)
	c.noroof(false)
	c.done()


# ---------------------------------------------------------------------------------------------
# 4. The Venetian carousel (karuzela wenecka)
# ---------------------------------------------------------------------------------------------

const VEN_FLOOR := Color("#d8b58a")
const VEN_DRUM := Color("#5f3825")
const VEN_ORANGE := Color("#e08a3a")
const VEN_PURPLE := Color("#6a2a6a")
const VEN_BROWN := Color("#5a2a1e")
const VEN_SHIELD := Color("#d0702a")
const VEN_INSET := Color("#c03a2a")
const VEN_MEDALS := [Color("#3aa0d8"), Color("#e8c030"), Color("#d6407a"), Color("#4cb050"), Color("#8a5ad0")]
const VEN_Y_EAVE := 3.3
const VEN_R := 4.25


## The Venetian carousel's still parts: the tan floor disc (r 5) with a stair at local -v, the dark
## wood drum (r 4.25) with a frieze of sixteen painted lit medallions, gold bands, multicolour
## bulbs on its top edge, and the centre column.
static func venetian_static(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.prism(0, 0, 5.0, 16, 0.0, 0.4, VEN_DRUM.lightened(0.1), VEN_FLOOR, M_STONE, M_STONE)
	for s in 3:
		c.box(-1.1, 1.1, -5.0 - 0.45 * (s + 1), -4.9, 0.0, 0.4 - 0.13 * (s + 1), VEN_FLOOR.darkened(0.1))
	c.prism(0, 0, VEN_R, 16, 0.4, 1.9, VEN_DRUM, VEN_DRUM.lightened(0.1))
	c.prism(0, 0, VEN_R + 0.05, 16, 0.4, 0.6, GOLD.darkened(0.2))
	c.prism(0, 0, VEN_R + 0.05, 16, 1.75, 1.9, GOLD.darkened(0.2))
	# The medallion frieze: a lit round plate on every other face of the 32-sided look (16 plates).
	var ap := VEN_R * cos(PI / 16.0) + 0.04
	for k in 16:
		var out := TAU * (float(k) + 0.5) / 16.0
		c.round_panel(cos(out) * ap, sin(out) * ap, out, 0.3, 1.18, 8, VEN_MEDALS[k % 5], M_LAMP)
		c.round_panel(cos(out) * (ap + 0.01), sin(out) * (ap + 0.01), out, 0.4, 1.18, 8, GOLD.darkened(0.25), M_STONE)
	c.noroof(true)
	c.bulb_ring(0, 0, VEN_R + 0.15, 1.98, 32, 0.09, MULTI, M_LAMP)
	c.bulb_ring(0, 0, VEN_R + 0.15, 0.45, 32, 0.07, MULTI, M_LAMP, 0.05)
	c.noroof(false)
	c.prism(0, 0, 0.9, 12, 0.4, VEN_Y_EAVE + 1.6, Color("#c99a48"), CLEAR, M_LAMP)
	c.done()


## The Venetian carousel's turning canopy (`part` -1): eight gold-and-dark posts, the striped cone
## (orange, purple and brown in 24 sectors, eave r 4.4 at 3.3 m up to the apex at 6 m), sixteen
## orange scalloped shields with red insets round the eave, two rings of multicolour bulbs (the
## eave and 60 % up) and a spire finial. `part` 0..11: one horse on its pole (a rider on seven).
static func venetian_spin(b, at: Vector2, part: int, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	if part < 0:
		for k in 8:
			var a := TAU * float(k) / 8.0
			c.lbeam(Vector3(cos(a) * 4.0, sin(a) * 4.0, 1.9), Vector3(cos(a) * 4.0, sin(a) * 4.0, VEN_Y_EAVE), 0.16, GOLD)
		var apex := 6.0
		var sectors := 24
		var cols := [VEN_ORANGE, VEN_PURPLE, VEN_BROWN]
		var eave := c.ring(0, 0, 4.45, sectors, 0.0)
		var apex_p := c.p(0, 0, apex)
		for k in sectors:
			var j := (k + 1) % sectors
			var pa := Vector3(eave[k].x, c.g + VEN_Y_EAVE, eave[k].y)
			var pb := Vector3(eave[j].x, c.g + VEN_Y_EAVE, eave[j].y)
			var nrm := (pb - pa).cross(apex_p - pa)
			if Vector2(nrm.x, nrm.z).dot((eave[k] + eave[j]) * 0.5 - c.o) < 0.0:
				nrm = -nrm
			c.tri(pa, pb, apex_p, cols[k % 3], M_STONE, nrm)
		# The underside, dark.
		c.disc(0, 0, 4.45, sectors, VEN_Y_EAVE - 0.02, VEN_BROWN.darkened(0.5), M_STONE, false)
		# A thin ring beam at the eave and the scalloped shields on it.
		for k in 16:
			var a := TAU * float(k) / 16.0
			var d := TAU * float(k + 1) / 16.0
			c.lbeam(Vector3(cos(a) * 4.45, sin(a) * 4.45, VEN_Y_EAVE), Vector3(cos(d) * 4.45, sin(d) * 4.45, VEN_Y_EAVE), 0.14, GOLD)
		for k in 16:
			var out := TAU * (float(k) + 0.5) / 16.0
			var px := cos(out) * 4.42
			var py := sin(out) * 4.42
			var y0 := VEN_Y_EAVE + 0.05
			var sh: Array = [Vector2(-0.42, y0), Vector2(0.42, y0), Vector2(0.45, y0 + 0.5), Vector2(0.22, y0 + 0.8),
					Vector2(0.0, y0 + 0.88), Vector2(-0.22, y0 + 0.8), Vector2(-0.45, y0 + 0.5)]
			c.panel(px, py, out, sh, VEN_SHIELD, M_STONE, true)
			c.panel(px, py, out, [Vector2(-0.2, y0 + 0.18), Vector2(0.2, y0 + 0.18), Vector2(0.2, y0 + 0.55), Vector2(0.0, y0 + 0.68),
					Vector2(-0.2, y0 + 0.55)], VEN_INSET, M_LAMP, false, 0.02)
			c.panel(px, py, out, [Vector2(-0.2, y0 + 0.18), Vector2(0.2, y0 + 0.18), Vector2(0.2, y0 + 0.55), Vector2(0.0, y0 + 0.68),
					Vector2(-0.2, y0 + 0.55)], VEN_INSET, M_LAMP, false, -0.02)
		# Bulb rings: at the eave, and 60 % of the way up the slope.
		c.bulb_ring(0, 0, 4.5, VEN_Y_EAVE - 0.05, 32, 0.1, MULTI, M_LAMP)
		var rr := 4.45 * 0.4
		c.bulb_ring(0, 0, rr + 0.2, VEN_Y_EAVE + (apex - VEN_Y_EAVE) * 0.6 + 0.12, 24, 0.1, MULTI, M_LAMP)
		# Spire.
		c.frustum(0, 0, 0.3, apex, 0.08, apex + 0.7, 8, GOLD, GOLD)
		c.sphere(0, 0, apex + 0.85, 0.2, 8, 3, BULB, M_LAMP)
		c.done()
		return
	var k := part
	var t := TAU * float(k) / 12.0
	var r := 3.3 if k % 2 == 0 else 2.3
	var d := Vector2(-sin(t), cos(t))
	var px := cos(t) * r
	var py := sin(t) * r
	var hy := 1.25 + 0.3 * float(k % 3)
	var coat: Color = [WHITE, Color("#e8d9b8"), Color("#8a4a2a"), Color("#b8b8c0")][k % 4]
	c.lbeam(Vector3(px, py, 0.4), Vector3(px, py, VEN_Y_EAVE - 0.1), 0.06, GOLD)
	var ang := t + PI * 0.5
	# Body, neck, head, four legs, a coloured blanket.
	c.lbeam(Vector3(px - d.x * 0.55, py - d.y * 0.55, hy), Vector3(px + d.x * 0.5, py + d.y * 0.5, hy), 0.4, coat)
	c.lbeam(Vector3(px + d.x * 0.5, py + d.y * 0.5, hy + 0.05), Vector3(px + d.x * 0.75, py + d.y * 0.75, hy + 0.6), 0.2, coat)
	c.lbeam(Vector3(px + d.x * 0.72, py + d.y * 0.72, hy + 0.6), Vector3(px + d.x * 0.98, py + d.y * 0.98, hy + 0.45), 0.15, coat)
	for lx: float in [-0.45, 0.4]:
		for ly: float in [-0.12, 0.12]:
			var f := Vector2(cos(t), sin(t))
			var q := Vector2(px, py) + d * lx + f * ly
			c.lbeam(Vector3(q.x, q.y, hy - 0.1), Vector3(q.x, q.y, hy - 0.7), 0.08, coat.darkened(0.15))
	var blanket: Color = [RED, Color("#3a6fc0"), GOLD][k % 3]
	c.pbox(px, py, ang, 0.28, 0.23, hy + 0.2, hy + 0.3, blanket, CLEAR, M_LAMP)
	if k in [0, 1, 3, 4, 6, 8, 10]:
		c.rider(px, py, ang, hy + 0.3, k)
	c.done()


# ---------------------------------------------------------------------------------------------
# 5. The teacups (filizanki)
# ---------------------------------------------------------------------------------------------

const CUP_NAVY := Color("#1e2a5a")
const CUP_BLUE := Color("#2e4fa0")
const CUP_R := 4.5
const CUP_N := 7


## The teacups' still parts: a navy floor (r 4.5) with ~30 white star dots and a red trim band, a
## white picket fence (56 pickets, two rails, a gap at local -v), the blue teapot (2.5 m: belly,
## lid, spout, handle) in the middle, and a white ticket booth outside the fence.
static func teacups_static(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.prism(0, 0, CUP_R, 24, 0.0, 0.35, RED, CUP_NAVY, M_STONE, M_STONE)
	c.prism(0, 0, CUP_R + 0.03, 24, 0.2, 0.3, Color("#f4efe6"), CLEAR, M_LAMP)
	# Star dots: a golden-angle spread over the floor, outside the cups' track and the pot.
	c.noroof(true)
	for k in 34:
		var a := float(k) * 2.39996
		var rr := 1.6 + 2.7 * sqrt((float(k) + 0.5) / 34.0)
		c.bulb(c.p(cos(a) * rr, sin(a) * rr, 0.4), 0.09, Color(0.95, 0.96, 1.0))
	# The picket fence.
	for k in 56:
		var a := TAU * float(k) / 56.0
		if absf(wrapf(a - PI * 1.5, -PI, PI)) < 0.22:
			continue
		c.pbox(cos(a) * 4.7, sin(a) * 4.7, a + PI * 0.5, 0.06, 0.02, 0.35, 1.25, WHITE, WHITE, M_STONE)
	for h: float in [0.6, 1.05]:
		for k in 28:
			var a := TAU * float(k) / 28.0
			var d := TAU * float(k + 1) / 28.0
			if absf(wrapf(a - PI * 1.5, -PI, PI)) < 0.2:
				continue
			c.lbeam(Vector3(cos(a) * 4.72, sin(a) * 4.72, h), Vector3(cos(d) * 4.72, sin(d) * 4.72, h), 0.06, WHITE)
	c.noroof(false)
	# The teapot, blue, with a lid, a spout and a handle, white dots on its belly.
	c.frustum(0, 0, 0.9, 0.35, 1.15, 0.75, 14, CUP_BLUE)
	c.sphere(0, 0, 1.45, 1.1, 14, 6, CUP_BLUE)
	c.frustum(0, 0, 0.7, 2.4, 0.45, 2.7, 14, CUP_BLUE, CUP_BLUE.lightened(0.1))
	c.sphere(0, 0, 2.85, 0.18, 8, 3, WHITE)
	var pb := CUP_BLUE.lightened(0.12)
	c.lbeam(Vector3(0.9, 0.0, 0.95), Vector3(1.7, 0.0, 1.7), 0.4, pb)
	c.lbeam(Vector3(1.7, 0.0, 1.7), Vector3(2.35, 0.0, 2.55), 0.28, pb)
	c.lbeam(Vector3(2.35, 0.0, 2.55), Vector3(2.55, 0.0, 2.75), 0.2, WHITE)
	c.lbeam(Vector3(-1.0, 0.0, 2.1), Vector3(-1.85, 0.0, 2.1), 0.3, pb)
	c.lbeam(Vector3(-1.85, 0.0, 2.1), Vector3(-1.85, 0.0, 1.2), 0.3, pb)
	c.lbeam(Vector3(-1.85, 0.0, 1.2), Vector3(-1.0, 0.0, 0.95), 0.3, pb)
	for k in 9:
		var a := TAU * float(k) / 9.0 + 0.3
		var q := Vector2(cos(a), sin(a))
		c.round_panel(q.x * 1.06, q.y * 1.06, a, 0.09, 1.2 + 0.3 * float(k % 3), 5, Color("#f4efe6"), M_STONE)
	# The ticket booth: a white cube, a dark window with a lit counter.
	var bx := 4.0
	var by := 4.1
	c.pbox(bx, by, PI * 0.25, 0.75, 0.75, 0.0, 2.3, WHITE, Color("#c9c9c4"))
	var bo := PI * 0.25 + PI * 0.5
	var bf := c.dir(bo)
	c.rect_panel(bx + bf.x * 0.76, by + bf.y * 0.76, bo, 0.9, 1.2, 1.9, Color("#ffc98a"), M_LAMP)
	c.done()


## The teacups' turning part: seven blue cups (white inside, white dots, a handle) on white
## saucers going round the pot at r 2.9, two riders in each.
static func teacups_spin(b, at: Vector2, yaw := 0.0, g := NAN, riders := true) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	for k in CUP_N:
		var t := TAU * float(k) / float(CUP_N)
		var px := cos(t) * 2.95
		var py := sin(t) * 2.95
		c.prism(px, py, 0.9, 12, 0.35, 0.45, WHITE, Color("#dcdcd6"))
		# The cup: blue outside, a blue rim, white only inside; white dots on the blue.
		c.frustum(px, py, 0.6, 0.45, 0.82, 1.35, 12, CUP_BLUE, CUP_BLUE.lightened(0.05))
		c.disc(px, py, 0.66, 12, 1.37, WHITE, M_STONE)
		for q in 9:
			var a := t + 0.35 + TAU * float(q) / 9.0
			c.round_panel(px + cos(a) * 0.78, py + sin(a) * 0.78, a, 0.1, 0.75 + 0.3 * float(q % 2), 5, WHITE, M_STONE, 0.02)
		var f := Vector2(cos(t + PI * 0.5), sin(t + PI * 0.5))
		c.lbeam(Vector3(px + f.x * 0.78, py + f.y * 0.78, 1.2), Vector3(px + f.x * 1.15, py + f.y * 1.15, 1.0), 0.14, CUP_BLUE.lightened(0.1))
		c.lbeam(Vector3(px + f.x * 1.15, py + f.y * 1.15, 1.0), Vector3(px + f.x * 0.8, py + f.y * 0.8, 0.6), 0.14, CUP_BLUE.lightened(0.1))
		if riders:
			var d := Vector2(cos(t + 0.7 * float(k)), sin(t + 0.7 * float(k)))
			c.rider(px + d.x * 0.35, py + d.y * 0.35, t + 0.7 * float(k) + PI * 0.5, 0.7, k * 2)
			c.rider(px - d.x * 0.35, py - d.y * 0.35, t + 0.7 * float(k) + PI * 0.5, 0.7, k * 2 + 1)
	c.done()


# ---------------------------------------------------------------------------------------------
# 6. The castle stage (P1-K): a stone castle front with four crenellated towers
# ---------------------------------------------------------------------------------------------

const CASTLE_STONE := Color("#b8a891")  # the spec's #B5ADA0, warmed
const CASTLE_MERLON := Color("#cfc8bc")  # stone, as the walls (F on site, 2026-11-22)
const CASTLE_WARM := Color("#ff5a32")  # the windows glow red-orange behind candle chandeliers
const CASTLE_BLUE := Color("#2a58b0")
const CASTLE_FLAG := Color("#1f2b5c")  # navy swallowtail flags, plain


## The castle stage (the official P1-K, a plain castle: no brand mark): 7.5 x 7 m, grey stone, four
## towers 1.8 m square and 7 m tall with stone merlons, a 5 m wall between them, arched red-lit
## windows, a blue shield with a plain gold diamond on the front wall, navy flags on the towers,
## fir garlands, and in front (local -v) a wooden counter with blue panels under a lean-to orange
## roof and a small fir at each corner.
static func castle_stage(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var tx := 2.85
	var tz := 2.6
	c.box(-3.75, 3.75, -3.5, 3.5, 0.0, 0.2, CASTLE_STONE.darkened(0.2))
	# The walls between the towers (back, both sides, the front wall in the middle).
	c.box(-3.75, 3.75, 2.2, 3.0, 0.2, 5.0, CASTLE_STONE)
	c.box(-3.75, -3.0, -3.0, 2.2, 0.2, 5.0, CASTLE_STONE)
	c.box(3.0, 3.75, -3.0, 2.2, 0.2, 5.0, CASTLE_STONE)
	c.box(-2.0, 2.0, -3.3, -2.3, 0.2, 5.0, CASTLE_STONE.lightened(0.04))
	c.box(-2.0, 2.0, -2.3, 2.2, 0.2, 2.6, CASTLE_STONE.darkened(0.15))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var cu := sx * tx
			var cv := sz * tz
			c.box(cu - 0.9, cu + 0.9, cv - 0.9, cv + 0.9, 0.2, 7.0, CASTLE_STONE.lightened(0.03), CASTLE_STONE.darkened(0.2))
			# The tower's merlons: a ring of small boxes round its top.
			for k in 12:
				var a := TAU * float(k) / 12.0
				var mu := cu + clampf(cos(a) * 1.4, -0.82, 0.82)
				var mv := cv + clampf(sin(a) * 1.4, -0.82, 0.82)
				c.pbox(mu, mv, 0.0, 0.2, 0.2, 7.0, 7.4, CASTLE_STONE, CASTLE_MERLON)
			# A pole and a red pennant.
			c.lbeam(Vector3(cu, cv, 7.0), Vector3(cu, cv, 9.0), 0.06, WIRE)
			c.panel(cu, cv, 0.0, [Vector2(0, 8.9), Vector2(0, 8.3), Vector2(1.1, 8.6)], CASTLE_FLAG, M_STONE, true, 0.0)
			c.panel(cu, cv, PI * 0.5, [Vector2(0, 8.9), Vector2(0, 8.3), Vector2(1.1, 8.6)], CASTLE_FLAG, M_STONE, true, 0.0)
			# The tower's arched window, on the faces that look out.
			c.arch_panel(cu, cv + sz * 0.93, sz * PI * 0.5, 0.75, 3.3, 5.3, CASTLE_WARM, M_LAMP)
			c.arch_panel(cu, cv + sz * 0.93, sz * PI * 0.5, 0.45, 5.6, 6.6, CASTLE_WARM, M_LAMP)
			c.arch_panel(cu + sx * 0.93, cv, 0.0 if sx > 0.0 else PI, 0.75, 3.3, 5.3, CASTLE_WARM, M_LAMP)
	# Merlons along the walls.
	for k in 12:
		var mu := -2.3 + 0.42 * float(k)
		c.pbox(mu, 2.6, 0.0, 0.17, 0.17, 5.0, 5.4, CASTLE_STONE, CASTLE_MERLON)
	for k in 5:
		var mu := -1.7 + 0.85 * float(k)
		c.pbox(mu, -2.8, 0.0, 0.2, 0.2, 5.0, 5.4, CASTLE_STONE, CASTLE_MERLON)
	for sx: float in [-3.4, 3.4]:
		for k in 4:
			c.pbox(sx, -1.6 + 1.1 * float(k), 0.0, 0.2, 0.2, 5.0, 5.4, CASTLE_STONE, CASTLE_MERLON)
	# The front wall: two windows and the blue shield with a plain gold diamond.
	c.arch_panel(-1.35, -3.33, -PI * 0.5, 0.6, 2.9, 4.2, CASTLE_WARM, M_LAMP)
	c.arch_panel(1.35, -3.33, -PI * 0.5, 0.6, 2.9, 4.2, CASTLE_WARM, M_LAMP)
	c.panel(0.0, -3.33, -PI * 0.5, [Vector2(-0.7, 3.1), Vector2(0.7, 3.1), Vector2(0.7, 4.2), Vector2(0.0, 4.9), Vector2(-0.7, 4.2)], CASTLE_BLUE, M_LAMP)
	c.panel(0.0, -3.34, -PI * 0.5, [Vector2(0, 3.5), Vector2(0.3, 4.0), Vector2(0, 4.5), Vector2(-0.3, 4.0)], Color("#f2c230"), M_LAMP)
	# Fir garlands along the wall tops (front, both sides, back) with bulbs and red bows.
	c.noroof(true)
	for gl in [[-2.0, -3.4, 2.0, -3.4], [-3.85, -3.0, -3.85, 2.2], [3.85, -3.0, 3.85, 2.2], [-3.75, 2.9, 3.75, 2.9]]:
		c.lbeam(Vector3(gl[0], gl[1], 4.9), Vector3(gl[2], gl[3], 4.9), 0.28, FIR)
		var steps := 10
		for k in steps + 1:
			var gp := Vector2(lerpf(gl[0], gl[2], float(k) / steps), lerpf(gl[1], gl[3], float(k) / steps))
			c.lbulb(gp.x, gp.y, 4.82, 0.07, MULTI[k % 4])
			if k % 3 == 0:
				c.box(gp.x - 0.1, gp.x + 0.1, gp.y - 0.1, gp.y + 0.1, 4.7, 4.95, Color("#d0222c"))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			c.lbeam(Vector3(sx * tx - 0.95, sz * tz - 0.95, 3.0), Vector3(sx * tx + 0.95, sz * tz - 0.95, 3.0), 0.2, FIR)
	c.noroof(false)
	# The counter and its big lean-to roof in front: the full width, sloping down to the front.
	c.box(-3.5, 3.5, -5.0, -3.7, 0.0, 1.05, WOOD, Color("#d9b27a"))
	for k in 5:
		c.rect_panel(-2.8 + 1.4 * float(k), -5.01, -PI * 0.5, 1.1, 0.2, 0.9, CASTLE_BLUE, M_STONE)
	for sx: float in [-3.6, 3.6]:
		c.pbox(sx, -5.3, 0.0, 0.09, 0.09, 0.0, 2.2, WOOD.darkened(0.2))
	var orange := Color("#d8741a")
	c.surface(-3.9, 3.9, -5.7, -3.3, 8, 4, func(_u: float, v: float) -> float: return 3.1 + (v + 3.3) * 0.5, orange, orange.darkened(0.12))
	c.box(-3.9, 3.9, -5.78, -5.66, 1.85, 2.2, orange.darkened(0.3))
	c.noroof(true)
	for k in 16:
		c.lbulb(-3.75 + 0.5 * float(k), -5.8, 1.8, 0.07, MULTI[k % 4])
	c.noroof(false)
	# Small firs at the corners.
	for sx: float in [-1.0, 1.0]:
		c.fir(sx * 4.3, -4.9, 2.4)
	c.done()


# ---------------------------------------------------------------------------------------------
# 7. The food zone (strefa gastronomiczna)
# ---------------------------------------------------------------------------------------------

const FOOD_RED := Color("#c1422c")


## The food zone, 14 x 10 m: a red booth (6 x 2.5 x 3 m) along the back (local +v) whose front has three
## lit square panels with a white tree outline each, five white square umbrellas (3 x 3 m, at 2.6 m)
## over round tables, fourteen firs with red planter boxes round the edge, and poles at the corners
## and middles with bulb strings between them.
static func food_zone(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-3.0, 3.0, 3.2, 5.0, 0.0, 3.0, FOOD_RED, FOOD_RED.darkened(0.25))
	c.box(-3.2, 3.2, 2.9, 3.2, 0.0, 1.0, FOOD_RED.darkened(0.15), WHITE)
	c.box(-3.2, 3.2, 2.9, 5.2, 3.0, 3.15, FOOD_RED.darkened(0.3))
	for k in 3:
		var cu := -2.0 + 2.0 * float(k)
		c.rect_panel(cu, 3.18, -PI * 0.5, 1.5, 1.2, 2.7, FOOD_RED.lightened(0.15), M_LAMP)
		# The tree icon: three nested white triangles (lit) and a trunk.
		for t in 3:
			var y0 := 1.45 + 0.35 * float(t)
			var hw := 0.52 - 0.1 * float(t)
			c.panel(cu, 3.17, -PI * 0.5, [Vector2(-hw, y0), Vector2(hw, y0), Vector2(0.0, y0 + 0.62)], WHITE, M_LAMP)
		c.rect_panel(cu, 3.17, -PI * 0.5, 0.12, 1.3, 1.45, WHITE, M_LAMP)
	# Umbrellas over tables.
	var spots := [[-4.6, -1.0], [0.0, -1.6], [4.6, -1.0], [-2.3, -3.8], [2.3, -3.8]]
	for sp in spots:
		var x: float = sp[0]
		var z: float = sp[1]
		c.noroof(true)
		c.lbeam(Vector3(x, z, 0.0), Vector3(x, z, 2.6), 0.06, WIRE)
		c.noroof(false)
		c.prism(x, z, 0.45, 8, 0.7, 0.75, WOOD, Color("#d9b27a"))
		c.prism(x, z, 0.06, 4, 0.0, 0.7, WIRE)
		c.frustum(x, z, 2.1, 2.5, 0.0, 2.95, 4, WHITE, CLEAR, M_STONE, -1.0, PI * 0.25)
		for k in 4:
			var a := PI * 0.25 + TAU * float(k) / 4.0
			c.pbox(x + cos(a) * 0.95, z + sin(a) * 0.95, a, 0.2, 0.2, 0.0, 0.45, WIRE, WOOD)
	# Firs in red planters round the edge.
	var firs := [[-6.5, 4.5], [-6.5, 1.5], [-6.5, -1.5], [-6.5, -4.5], [-3.5, -4.9], [0.0, -4.9], [3.5, -4.9], [6.5, -4.5],
			[6.5, -1.5], [6.5, 1.5], [6.5, 4.5], [-4.0, 4.9], [4.0, 4.9], [-3.4, 4.9]]
	for f in firs:
		c.box(f[0] - 0.4, f[0] + 0.4, f[1] - 0.4, f[1] + 0.4, 0.0, 0.5, FOOD_RED)
		c.fir(f[0], f[1], 2.8, true, false)
	# Poles with bulb strings round the perimeter.
	var poles: Array[Vector2] = []
	for pt in [[-7.0, -5.0], [0.0, -5.0], [7.0, -5.0], [7.0, 0.0], [7.0, 5.0], [0.0, 5.2], [-7.0, 5.0], [-7.0, 0.0]]:
		poles.append(Vector2(pt[0], pt[1]))
	c.noroof(true)
	for i in poles.size():
		var q := poles[i]
		var q2 := poles[(i + 1) % poles.size()]
		c.lbeam(Vector3(q.x, q.y, 0.0), Vector3(q.x, q.y, 3.6), 0.08, WIRE)
		c.string(c.p(q.x, q.y, 3.6), c.p(q2.x, q2.y, 3.6), 0.35)
	c.noroof(false)
	c.done()


# ---------------------------------------------------------------------------------------------
# 8. The wine and bar containers, kiosks K1 and K2
# ---------------------------------------------------------------------------------------------

const CONT_WINE := Color("#e07a45")
const CONT_BAR := Color("#56666e")
const CONT_K2 := Color("#a9763a")
const CONT_K1 := Color("#a85f07")
enum Cont { WINE, BAR, K2 }


## A 20 ft shipping-container stall (6 x 2.4 x 2.6 m): `kind` Cont.WINE orange, Cont.BAR blue-grey,
## Cont.K2 timber-brown. Vertical corrugation every 0.3 m on both long sides and the roof ribs, a
## long hatch on the front (local -v) lit warm inside with an open awning flap above and a counter flap
## below, a multicolour bulb string round the roof edge.
static func container(b, at: Vector2, yaw := 0.0, g := NAN, kind := Cont.WINE) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var col := [CONT_WINE, CONT_BAR, CONT_K2][kind] as Color
	var dark := col.darkened(0.3)
	c.box(-3.0, 3.0, -1.2, 1.2, 0.0, 2.6, col, col.darkened(0.12))
	for k in 20:
		var cu := -2.85 + 0.3 * float(k)
		if absf(cu) < 2.15:
			c.pbox(cu, 1.2, 0.0, 0.035, 0.03, 0.15, 2.45, dark)
		else:
			c.pbox(cu, -1.2, 0.0, 0.035, 0.03, 0.15, 2.45, dark)
		if k % 2 == 0:
			c.pbox(cu, 0.0, 0.0, 0.035, 1.15, 2.6, 2.63, dark)
	for sd: float in [-1.0, 1.0]:
		c.pbox(sd * 2.99, 0.0, 0.0, 0.02, 1.2, 0.05, 2.55, dark.darkened(0.2))
	# The hatch: a dark frame, the warm lit inside, the awning flap up and the counter flap down.
	c.rect_panel(0.0, -1.2, -PI * 0.5, 4.3, 0.95, 2.25, Color("#1c1c20"), M_STONE, false, 0.012)
	c.rect_panel(0.0, -1.2, -PI * 0.5, 4.0, 1.05, 2.15, Color("#ffc98a"), M_LAMP, false, 0.03)
	c.quad(c.p(-2.1, -1.22, 2.25), c.p(2.1, -1.22, 2.25), c.p(2.1, -1.95, 2.55), c.p(-2.1, -1.95, 2.55), col.lightened(0.1), M_STONE, Vector3.ZERO, true)
	c.box(-2.1, 2.1, -1.8, -1.2, 0.95, 1.02, WOOD.lightened(0.1))
	# The bulbs round the roof edge.
	c.noroof(true)
	var n := 0
	for k in 13:
		for sd: float in [-1.0, 1.0]:
			c.lbulb(-3.0 + 0.5 * float(k), sd * 1.2, 2.66, 0.07, MULTI[n % 4])
			n += 1
	for k in 4:
		for sd: float in [-1.0, 1.0]:
			c.lbulb(sd * 3.0, -0.9 + 0.6 * float(k), 2.66, 0.07, MULTI[n % 4])
			n += 1
	c.noroof(false)
	c.done()


## Kiosk K1: an orange gable hut (#A85F07) on an open white frame, 5 x 3.5 m, its front (local -v)
## open with a lit counter and white flaps folded out.
static func kiosk_k1(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-2.5, 2.5, -1.75, 1.75, 0.0, 0.18, Color("#d4d0ca"))
	for sx: float in [-2.3, 2.3]:
		for sz: float in [-1.55, 1.55]:
			c.pbox(sx, sz, 0.0, 0.08, 0.08, 0.18, 2.4, WHITE)
	c.box(-2.3, 2.3, 1.45, 1.65, 0.18, 2.4, Color("#d4d0ca"))
	c.rect_panel(0.0, -1.3, -PI * 0.5, 3.6, 1.1, 2.2, Color("#ffc98a"), M_LAMP)
	c.box(-2.0, 2.0, -1.7, -1.3, 0.95, 1.05, WOOD)
	c.gable(2.3, 1.5, 2.4, 1.0, WHITE, CONT_K1, CONT_K1.darkened(0.3), 0.2, 0.3)
	c.quad(c.p(-2.2, -1.5, 2.3), c.p(2.2, -1.5, 2.3), c.p(2.2, -2.2, 2.65), c.p(-2.2, -2.2, 2.65), Color("#d4d0ca"), M_STONE, Vector3.ZERO, true)
	c.quad(c.p(-2.5, -1.7, 1.0), c.p(-3.2, -2.3, 1.0), c.p(-3.2, -2.3, 2.1), c.p(-2.5, -1.7, 2.1), Color("#d4d0ca"), M_STONE, Vector3.ZERO, true)
	c.quad(c.p(2.5, -1.7, 1.0), c.p(3.2, -2.3, 1.0), c.p(3.2, -2.3, 2.1), c.p(2.5, -1.7, 2.1), Color("#d4d0ca"), M_STONE, Vector3.ZERO, true)
	c.noroof(true)
	for k in 11:
		c.lbulb(-2.5 + 0.5 * float(k), -1.8, 2.35, 0.07, MULTI[k % 4])
	c.noroof(false)
	c.done()


# ---------------------------------------------------------------------------------------------
# 9. The Fun House (plac zabaw)
# ---------------------------------------------------------------------------------------------

const FUN_MAGENTA := Color("#ff1a8c")
const FUN_CYAN := Color("#33d9ff")
const FUN_SKY := Color("#7cc8f0")


## Santa's Workshop (the official map's plac zabaw; F's photos on site, 2026-11-22): a two-deck
## walk-through funhouse trailer 16 x 6 m by the Palace's north-east wing. The lower deck is a navy
## body with rainbow arrow panels and a striped ramp in; the upper deck an open gallery behind a
## white rail under striped arches; over it a sign band, "SANTA'S" in red neon and "WORKSHOP" in white
## bulbs, and five square LED boards on poles with rainbow Christmas-bulb pictures. A palm with a
## climbing Santa at the -u end, the HOLIDAY ride (a trailer, a Santa on a surfboard over a gift-box
## base) beside it, the blue ticket booth, small firs in front, floodlights washing it green and
## magenta. Front is local -v.
static func fun_house(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var navy := Color("#1b2350")
	c.box(-9.0, 9.0, -5.2, 3.4, 0.0, 0.12, Color("#3a3c44"))
	# The lower deck: a navy body, a dark skirt, rainbow arrow panels and lit doors.
	c.box(-8.0, 8.0, -3.0, 3.0, 0.12, 2.8, navy, Color("#2a2e3a"))
	c.box(-8.02, 8.02, -3.02, 3.02, 0.12, 0.55, Color("#15151c"))
	for k in 8:
		var cu := -7.0 + 2.0 * float(k)
		var col: Color = RAINBOW[k % RAINBOW.size()]
		c.panel(cu, -3.04, -PI * 0.5, [Vector2(-0.7, 0.9), Vector2(0.2, 0.9), Vector2(0.2, 0.65), Vector2(0.75, 1.5),
				Vector2(0.2, 2.35), Vector2(0.2, 2.1), Vector2(-0.7, 2.1)], col, M_LAMP)
	for cu: float in [-3.0, 3.0]:
		c.rect_panel(cu, -3.05, -PI * 0.5, 1.3, 0.55, 2.5, Color("#ffd6f2"), M_LAMP)
	# The upper deck: a floor, a back wall with windows, the white rail and striped arches.
	c.box(-8.0, 8.0, -3.0, 3.0, 2.8, 2.95, Color("#c9ccd6"))
	c.box(-8.0, 8.0, 1.6, 3.0, 2.95, 5.3, Color("#e6e3ea"), Color("#9a9aa2"))
	for k in 7:
		var cu := -6.0 + 2.0 * float(k)
		c.arch_panel(cu, 1.58, -PI * 0.5, 1.2, 3.3, 4.8, FUN_CYAN if k % 2 == 0 else FUN_MAGENTA, M_LAMP)
	c.noroof(true)
	for k in 33:
		var cu := -8.0 + 0.5 * float(k)
		c.pbox(cu, -2.95, 0.0, 0.03, 0.03, 2.95, 4.0, WHITE)
	c.lbeam(Vector3(-8.0, -2.95, 4.0), Vector3(8.0, -2.95, 4.0), 0.08, WHITE)
	c.lbeam(Vector3(-8.0, -2.95, 3.45), Vector3(8.0, -2.95, 3.45), 0.05, WHITE)
	# The striped arches over the gallery (red and white), on posts at the front edge.
	for k in 5:
		var cu := -6.4 + 3.2 * float(k)
		for q in 8:
			var a0 := PI * float(q) / 8.0
			var a1 := PI * float(q + 1) / 8.0
			c.lbeam(Vector3(cu + cos(a0) * 1.5, -2.95, 4.0 + sin(a0) * 1.3), Vector3(cu + cos(a1) * 1.5, -2.95, 4.0 + sin(a1) * 1.3),
					0.16, RED if q % 2 == 0 else WHITE)
		# A punching bag hanging in each arch.
		c.lbeam(Vector3(cu, -2.6, 5.2), Vector3(cu, -2.6, 4.4), 0.03, WIRE)
		c.prism(cu, -2.6, 0.22, 8, 3.6, 4.4, RED if k % 2 == 0 else Color("#2a6fd0"))
	c.noroof(false)
	# The roof and the sign band over it.
	c.box(-8.1, 8.1, -0.5, 3.1, 5.3, 5.5, Color("#2a2e3a"))
	c.box(-7.6, 7.6, -0.4, -0.2, 5.5, 7.6, Color("#14141c"))
	c.noroof(true)
	bulb_word(c, "WORKSHOP", -3.1, -0.5, 5.9, 1.1, Color(1.0, 0.95, 0.8), 0.07)
	c.box(1.4, 7.4, -0.43, -0.4, 5.65, 7.45, Color("#5a0d1a"))
	c.word("SANTA'S", 4.4, -0.5, 6.05, 1.0, Color("#ff2a3a"), M_LAMP)
	# A string of chaser bulbs along the sign band's top and the roof edge.
	for k in 39:
		var cu := -7.6 + 0.4 * float(k)
		c.lbulb(cu, -0.5, 7.65, 0.09, MULTI[k % 4])
		c.lbulb(cu, -3.1, 5.45, 0.08, MULTI[(k + 2) % 4])
	# Five LED boards on poles: dark squares with a ring of rainbow Christmas bulbs and a big bulb in the middle.
	for k in 5:
		var cu := -7.4 + 3.7 * float(k)
		var y0 := 7.8 + 0.4 * float(k % 2)
		c.lbeam(Vector3(cu, -0.3, 5.5), Vector3(cu, -0.3, y0), 0.08, WIRE)
		c.box(cu - 0.8, cu + 0.8, -0.42, -0.3, y0, y0 + 1.6, Color("#101018"))
		for q in 9:
			var qa := TAU * float(q) / 9.0
			c.lbulb(cu + cos(qa) * 0.55, -0.46, y0 + 0.8 + sin(qa) * 0.55, 0.12, RAINBOW[(q + k) % RAINBOW.size()])
		c.lbulb(cu, -0.46, y0 + 0.8, 0.22, RAINBOW[(k * 2) % RAINBOW.size()])
	c.noroof(false)
	# The striped ramp up to the upper deck at the +u end, and the exit slide at the -u end.
	for s_i in 6:
		c.box(8.0, 9.4, -2.8 + 0.8 * float(s_i), -2.0 + 0.8 * float(s_i), 0.12, 0.12 + 0.47 * float(s_i + 1),
				RED if s_i % 2 == 0 else WHITE)
	c.slab(c.p(-8.0, -1.5, 2.9), c.p(-10.2, -1.5, 0.3), 1.1, 1.1, 0.15, Color("#ffd23a"))
	# The palm with Santa climbing it (-u end, in front).
	c.lbeam(Vector3(-8.6, -4.2, 0.12), Vector3(-8.3, -4.2, 7.5), 0.3, Color("#8a6a3a"))
	for k in 8:
		var a := TAU * float(k) / 8.0
		c.slab(c.p(-8.3, -4.2, 7.5), c.p(-8.3 + cos(a) * 2.2, -4.2 + sin(a) * 2.2, 6.6), 0.6, 0.15, 0.05, Color("#3a9a4a"))
	c.box(-8.75, -8.15, -4.65, -4.35, 4.6, 5.5, RED)
	c.sphere(-8.45, -4.55, 5.75, 0.25, 8, 4, Color("#f2d6c0"))
	c.frustum(-8.45, -4.55, 0.24, 5.9, 0.0, 6.4, 8, RED)
	# Small firs in front, floodlights in the corners.
	for k in 6:
		c.fir(-6.0 + 2.4 * float(k), -4.4, 1.6 + 0.3 * float(k % 2))
	for fl in [[-8.8, -5.0, Color(0.2, 1.0, 0.35)], [8.8, -5.0, Color(1.0, 0.2, 0.7)], [0.0, -5.1, Color(0.3, 0.45, 1.0)]]:
		c.box(fl[0] - 0.25, fl[0] + 0.25, fl[1] - 0.15, fl[1] + 0.15, 0.12, 0.5, Color("#202024"))
		c.rect_panel(fl[0], fl[1] + 0.16, PI * 0.5, 0.4, 0.2, 0.45, fl[2], M_LAMP)
	c.done()
	holiday_ride(b, c.w(13.5, -1.0), yaw, g)
	ticket_booth_fireworks(b, c.w(11.2, -4.6), yaw, g)


## The HOLIDAY ride beside the Workshop: a low trailer (6 x 3 m) painted as a stack of gift boxes, a
## big Santa on a surfboard over it (the board tilted up, his arms out), the plain word HOLIDAY in
## white bulbs on a red board, LED arrow strips along the sides. Front is local -v.
static func holiday_ride(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-3.0, 3.0, -1.5, 1.5, 0.0, 1.4, Color("#2a6fd0"), Color("#3a3c44"))
	for k in 3:
		var cu := -2.0 + 2.0 * float(k)
		var col: Color = [RED, Color("#33b04a"), Color("#e8b030")][k]
		c.box(cu - 0.9, cu + 0.9, -1.55, -1.5, 0.2, 1.3, col)
		c.box(cu - 0.1, cu + 0.1, -1.58, -1.55, 0.2, 1.3, WHITE)
	c.noroof(true)
	for k in 15:
		c.lbulb(-2.8 + 0.4 * float(k), -1.6, 1.45, 0.08, Color(0.2, 1.0, 0.4) if k % 2 == 0 else Color(1.0, 0.9, 0.3))
	c.noroof(false)
	# The surfboard on a post, tilted, and Santa on it.
	c.lbeam(Vector3(0.0, 0.0, 1.4), Vector3(0.0, 0.0, 3.2), 0.25, Color("#9a9aa2"))
	c.slab(c.p(-2.2, 0.0, 3.0), c.p(2.4, 0.0, 3.8), 1.0, 0.9, 0.18, Color("#ffd23a"))
	c.prism(0.2, 0.0, 0.55, 10, 3.5, 4.7, RED)
	c.box(-0.25, 0.65, -0.3, 0.3, 3.4, 3.9, Color("#1a1a20"))
	c.sphere(0.2, 0.0, 5.05, 0.38, 10, 5, Color("#f2d6c0"))
	c.sphere(0.2, -0.15, 4.85, 0.32, 8, 4, WHITE)
	c.frustum(0.2, 0.0, 0.38, 5.25, 0.0, 5.95, 8, RED)
	c.sphere(0.0, 0.0, 6.0, 0.12, 6, 3, WHITE)
	c.lbeam(Vector3(0.2, 0.0, 4.5), Vector3(-1.2, 0.0, 5.2), 0.18, RED)
	c.lbeam(Vector3(0.2, 0.0, 4.5), Vector3(1.6, 0.0, 5.1), 0.18, RED)
	# The HOLIDAY board.
	c.box(-2.2, 2.2, 1.3, 1.45, 1.4, 2.6, RED.darkened(0.2))
	c.noroof(true)
	bulb_word(c, "HOLIDAY", 0.0, 1.25, 1.65, 0.75, Color(1.0, 0.95, 0.8), 0.06)
	c.noroof(false)
	c.done()


## The small ticket booth: a 2 x 2 m blue box with firework bursts painted on its sides (lit panels at
## night), a counter window and a row of green LED dots along its roof edge. Front is local -v.
static func ticket_booth_fireworks(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-1.0, 1.0, -1.0, 1.0, 0.0, 2.5, Color("#2a5ab8"), Color("#2a2e3a"))
	c.rect_panel(0.0, -1.02, -PI * 0.5, 1.1, 1.0, 1.9, Color("#ffd8a0"), M_LAMP)
	for side: float in [-1.0, 1.0]:
		for q in 7:
			var a := PI * 0.15 + PI * 0.7 * float(q) / 6.0
			var o := side * 1.02
			c.panel(o, 0.0, 0.0 if side > 0.0 else PI, [Vector2(0.0, 0.8), Vector2(cos(a) * 0.75 - 0.05, 0.8 + sin(a) * 0.75),
					Vector2(cos(a) * 0.75 + 0.05, 0.8 + sin(a) * 0.75)], RAINBOW[q % RAINBOW.size()], M_LAMP)
	c.noroof(true)
	for k in 10:
		c.lbulb(-0.9 + 0.2 * float(k), -1.05, 2.45, 0.06, Color(0.2, 1.0, 0.4))
	c.noroof(false)
	c.done()


# ---------------------------------------------------------------------------------------------
# 10. Red game stalls, Santa's chair, maze, gingerbread tent, P2-L, the stand, small items
# ---------------------------------------------------------------------------------------------

const GAME_RED := Color("#d31d09")


## A basketball stall (2 in the market), 7 x 6 m: a red wavy canopy on four posts, a red counter in
## front (local -v) with a lit strip, and a back wall (local +v) with three orange hoops.
static func basketball(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-3.5, 3.5, -3.0, 3.0, 0.0, 0.1, Color("#5a1810"))
	for sx: float in [-3.4, 3.4]:
		for sz: float in [-2.9, 2.9]:
			c.pbox(sx, sz, 0.0, 0.1, 0.1, 0.1, 3.4, GAME_RED)
	c.surface(-3.6, 3.6, -3.2, 3.2, 14, 6, func(u: float, v: float) -> float: return 3.35 + 0.28 * sin(u * 1.7) - 0.5 * pow(v / 3.2, 2.0), GAME_RED, GAME_RED.darkened(0.2))
	c.box(-3.4, 3.4, 2.7, 3.0, 0.1, 3.2, GAME_RED.darkened(0.15))
	c.box(-3.4, 3.4, -2.9, -2.3, 0.1, 1.05, GAME_RED, WHITE)
	c.rect_panel(0.0, -2.91, -PI * 0.5, 6.4, 0.3, 0.9, Color("#ffc98a"), M_LAMP)
	c.noroof(true)
	for k in 3:
		var cu := -2.0 + 2.0 * float(k)
		for j in 8:
			var a := TAU * float(j) / 8.0
			var d := TAU * float(j + 1) / 8.0
			c.lbeam(Vector3(cu + cos(a) * 0.35, 2.6, 1.9 + sin(a) * 0.35), Vector3(cu + cos(d) * 0.35, 2.6, 1.9 + sin(d) * 0.35), 0.05, Color("#f08a24"))
	for k in 15:
		c.lbulb(-3.5 + 0.5 * float(k), -3.2, 3.0 + 0.28 * sin((-3.5 + 0.5 * float(k)) * 1.7) - 0.5 * 1.0, 0.07, MULTI[k % 4])
	c.noroof(false)
	c.done()


## A carnival stall (4): a 4 x 3 x 2.5 m red-orange box (#D54B23) with a cream top frame of open
## slats and a green oval sign (#71BF25, plain, no words) on the front (local -v).
static func carnival(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var red := Color("#d54b23")
	c.box(-2.0, 2.0, -1.5, 1.5, 0.0, 2.0, red, red.darkened(0.3))
	var cream := Color("#f0e6cf")
	c.box(-2.05, 2.05, -1.55, -1.35, 2.0, 2.5, cream)
	c.box(-2.05, 2.05, 1.35, 1.55, 2.0, 2.5, cream)
	c.box(-2.05, -1.85, -1.35, 1.35, 2.0, 2.5, cream)
	c.box(1.85, 2.05, -1.35, 1.35, 2.0, 2.5, cream)
	for k in 9:
		c.box(-1.7 + 0.425 * float(k) - 0.07, -1.7 + 0.425 * float(k) + 0.07, -1.35, 1.35, 2.0, 2.4, red.lightened(0.05))
	var pts: Array = []
	for k in 16:
		var a := TAU * float(k) / 16.0
		pts.append(Vector2(cos(a) * 1.35, 1.0 + sin(a) * 0.45))
	c.panel(0.0, -1.52, -PI * 0.5, pts, Color("#71bf25"), M_LAMP)
	c.done()


## Claw machines (automaty pluszaki), 6.5 x 5 m: a red frame shelter with a curved clear roof (five arcs
## and rails) over five red cabinets 1 x 1 x 1.9 m with lit glass fronts (local -v).
static func claw_machines(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-3.25, 3.25, -2.5, 2.5, 0.0, 0.06, Color("#6a6a70"))
	for sx: float in [-3.2, 3.2]:
		for sz: float in [-2.4, 2.4]:
			c.pbox(sx, sz, 0.0, 0.06, 0.06, 0.0, 2.5, GAME_RED)
	c.noroof(true)
	for k in 5:
		var cu := -3.2 + 1.6 * float(k)
		var prev := Vector3(cu, -2.4, 2.5)
		for j in range(1, 9):
			var t := float(j) / 8.0
			var q := Vector3(cu, lerpf(-2.4, 2.4, t), 2.5 + 0.7 * sin(PI * t))
			c.lbeam(prev, q, 0.07, GAME_RED)
			prev = q
	for rz: float in [-1.2, 0.0, 1.2]:
		c.lbeam(Vector3(-3.2, rz, 2.5 + 0.7 * cos(rz / 2.4 * PI * 0.5)), Vector3(3.2, rz, 2.5 + 0.7 * cos(rz / 2.4 * PI * 0.5)), 0.06, GAME_RED)
	c.noroof(false)
	for k in 5:
		var cu := -2.4 + 1.2 * float(k)
		c.box(cu - 0.5, cu + 0.5, 1.0, 2.0, 0.06, 1.9, GAME_RED)
		c.rect_panel(cu, 0.99, -PI * 0.5, 0.8, 0.9, 1.7, Color("#bfe8ff"), M_LAMP)
		c.round_panel(cu, 0.98, -PI * 0.5, 0.2, 1.25, 8, Color("#e8506a"), M_STONE)
	c.done()


## Santa's chair (the radio sponsor's stand, no logo): a red floor 6 x 6 m, a big plain red ring arch
## (4 m, two beam rings) standing at the back (local +v), a white throne, two white trees, a snowman
## and two tall red feather flags.
static func santa_chair(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var red := Color("#d03030")
	c.box(-3.0, 3.0, -3.0, 3.0, 0.0, 0.12, red)
	c.noroof(true)
	for ring_v: float in [1.55, 1.9]:
		for k in 16:
			var a := TAU * float(k) / 16.0
			var d := TAU * float(k + 1) / 16.0
			c.lbeam(Vector3(cos(a) * 1.9, ring_v, 2.3 + sin(a) * 1.9), Vector3(cos(d) * 1.9, ring_v, 2.3 + sin(d) * 1.9), 0.3, red.darkened(0.1))
	c.noroof(false)
	c.box(-0.7, 0.7, -0.5, 0.5, 0.12, 0.55, WHITE)
	c.box(-0.7, 0.7, 0.3, 0.5, 0.55, 1.7, WHITE)
	c.box(-0.78, -0.58, -0.5, 0.5, 0.55, 1.0, WHITE)
	c.box(0.58, 0.78, -0.5, 0.5, 0.55, 1.0, WHITE)
	c.fir(-2.2, 0.0, 2.8, true, true, SNOW)
	c.fir(2.1, 0.5, 2.5, true, true, SNOW)
	c.sphere(-1.9, -1.9, 0.45, 0.45, 8, 4, SNOW)
	c.sphere(-1.9, -1.9, 1.15, 0.33, 8, 4, SNOW)
	c.sphere(-1.9, -1.9, 1.65, 0.24, 8, 3, SNOW)
	c.prism(-1.9, -1.9, 0.2, 6, 1.85, 2.15, Color("#2a58b0"), Color("#2a58b0"))
	for sx: float in [-2.7, 2.7]:
		c.lbeam(Vector3(sx, -2.6, 0.12), Vector3(sx, -2.6, 4.6), 0.07, WIRE)
		c.panel(sx, -2.6, 0.0, [Vector2(0, 1.2), Vector2(0.55, 2.2), Vector2(0.45, 4.3), Vector2(0, 4.6)], Color("#d02424"), M_STONE, true)
	c.done()


## The Christmas maze (labirynt), 9 x 7 m: white walls 1.2 m high in a ring (a gap at local -v) with
## five inner white blocks, a fir garland with red bows along the top, two small firs and a leafy tree.
static func maze(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var wall := Color("#ececf0")
	var t := 0.25
	c.box(-4.5, 4.5, 3.5 - t, 3.5, 0.0, 1.2, wall)
	c.box(-4.5, -4.5 + t, -3.5, 3.5, 0.0, 1.2, wall)
	c.box(4.5 - t, 4.5, -3.5, 3.5, 0.0, 1.2, wall)
	c.box(-4.5, -1.0, -3.5, -3.5 + t, 0.0, 1.2, wall)
	c.box(1.0, 4.5, -3.5, -3.5 + t, 0.0, 1.2, wall)
	for blk in [[-2.8, 1.8, 0.9, 0.7], [-0.3, 1.8, 0.9, 0.7], [2.2, 1.8, 0.9, 0.7], [-2.8, -1.0, 0.9, 0.7], [-0.4, -0.6, 0.9, 0.9]]:
		c.box(blk[0] - blk[2], blk[0] + blk[2], blk[1] - blk[3], blk[1] + blk[3], 0.0, 1.2, wall)
	c.noroof(true)
	c.lbeam(Vector3(-4.5, 3.4, 1.3), Vector3(4.5, 3.4, 1.3), 0.2, FIR)
	c.lbeam(Vector3(-4.4, -3.5, 1.3), Vector3(-4.4, 3.4, 1.3), 0.2, FIR)
	c.lbeam(Vector3(4.4, -3.5, 1.3), Vector3(4.4, 3.4, 1.3), 0.2, FIR)
	for k in 8:
		c.box(-4.2 + 1.2 * float(k), -3.95 + 1.2 * float(k), 3.2, 3.6, 1.2, 1.5, Color("#d0222c"))
	c.noroof(false)
	c.fir(-5.0, -2.5, 2.2)
	c.fir(-5.0, -3.4, 1.8)
	c.prism(3.2, -2.2, 0.15, 5, 0.0, 2.2, WOOD.darkened(0.2))
	c.sphere(3.2, -2.2, 3.0, 1.3, 8, 5, Color("#4a9a3a"))
	c.done()


## The gingerbread tent (5.5 x 6.5 x 3 m): orange gingerbread-print walls (#D8803A) with cream star
## and gingerbread icons, a white hip roof.
static func gingerbread_tent(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var ginger := Color("#d8803a")
	c.box(-2.75, 2.75, -3.25, 3.25, 0.0, 2.2, ginger, WHITE)
	c.hip(2.9, 3.4, 2.2, 1.0, 0.9, WHITE, Color("#d8d8dc"))
	for k in 3:
		var cu := -1.7 + 1.7 * float(k)
		c.panel(cu, -3.26, -PI * 0.5, _star_pts(0.4, 1.1), Color("#f0e0b0"), M_STONE)
		c.panel(cu, -3.26, -PI * 0.5, [Vector2(-0.2, 0.3), Vector2(0.2, 0.3), Vector2(0.25, 0.7), Vector2(0.0, 0.95), Vector2(-0.25, 0.7)], Color("#8a4a1a"), M_STONE)
	for k in 3:
		var cv := -2.0 + 2.0 * float(k)
		c.panel(2.76, cv, 0.0, _star_pts(0.4, 1.1), Color("#f0e0b0"), M_STONE)
		c.panel(-2.76, cv, PI, _star_pts(0.4, 1.1), Color("#f0e0b0"), M_STONE)
	c.rect_panel(0.0, -3.27, -PI * 0.5, 1.6, 0.0, 1.9, Color("#ffd9a0"), M_LAMP)
	c.done()


static func _star_pts(r: float, yc: float) -> Array:
	var out: Array = []
	for k in 8:
		var a := PI * 0.5 + TAU * float(k) / 8.0
		var rr := r if k % 2 == 0 else r * 0.45
		out.append(Vector2(cos(a) * rr, yc + sin(a) * rr))
	return out


## Pavilion P2-L (5 x 4 m): a grey low gable on a white frame, three big lit windows, a fir garland
## on the eave and a blue flag on a pole at the front-left corner.
static func pavilion_p2l(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-2.5, 2.5, -2.0, 2.0, 0.0, 0.12, Color("#c9c9c4"))
	for sx: float in [-2.4, 2.4]:
		for sz: float in [-1.9, 1.9]:
			c.pbox(sx, sz, 0.0, 0.07, 0.07, 0.12, 2.5, WHITE)
	c.box(-2.4, 2.4, 1.85, 1.95, 0.12, 2.5, Color("#ececf0"))
	for k in 3:
		c.rect_panel(-1.6 + 1.6 * float(k), -1.0, -PI * 0.5, 1.2, 0.7, 2.2, Color("#ffd9a0"), M_LAMP)
	c.gable(2.4, 1.9, 2.5, 0.7, WHITE, Color("#9a9ca2"), Color("#7a7c82"), 0.2, 0.3)
	c.noroof(true)
	c.lbeam(Vector3(-2.6, -2.3, 2.45), Vector3(2.6, -2.3, 2.45), 0.22, FIR)
	c.noroof(false)
	c.lbeam(Vector3(-2.9, -2.2, 0.0), Vector3(-2.9, -2.2, 3.8), 0.06, WIRE)
	c.panel(-2.9, -2.2, -PI * 0.5, [Vector2(0, 3.7), Vector2(0, 2.6), Vector2(1.0, 3.2)], Color("#2a58b0"), M_STONE, true)
	c.done()


## The stand (trybuna), 17 x 9 m: a flat grey deck 0.8 m up, three low steps along the back (local +v) and
## two lit firs on the front corners.
static func stand(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var conc := Color("#9a9a98")
	c.box(-8.5, 8.5, -4.5, 4.5, 0.0, 0.8, conc, conc.lightened(0.08))
	for s in 3:
		c.box(-8.5, 8.5, 4.5 - 0.5 * float(s + 1), 4.5, 0.8, 0.8 + 0.2 * float(s + 1), conc.darkened(0.04 * float(s)), conc.lightened(0.05))
	c.fir(-7.6, -3.6, 3.0, true, true)
	c.fir(7.6, -3.6, 3.0, true, true)
	c.done()


## A photo booth: 1.5 x 1.2 x 2.3 m, white with a grey top and a lit pink graphic panel on the front
## (local -v); `phone` makes the pink phone booth, `kind` 0 white / 1 phone / 2 cash machine (blue and orange).
static func booth(b, at: Vector2, yaw := 0.0, g := NAN, kind := 0) -> void:
	var c := Ctx.new(b, at, yaw, g)
	if kind == 2:
		c.box(-0.4, 0.4, -0.35, 0.35, 0.0, 1.9, Color("#2a58b0"), Color("#1e3a8a"))
		c.box(-0.4, 0.4, -0.35, 0.35, 0.0, 0.7, Color("#e8a030"))
		c.rect_panel(0.0, -0.36, -PI * 0.5, 0.5, 1.2, 1.6, Color("#bfe8ff"), M_LAMP)
		c.done()
		return
	var body := WHITE if kind == 0 else Color("#f06a9a")
	c.box(-0.75, 0.75, -0.6, 0.6, 0.0, 2.3, body, Color("#8a8a90"))
	c.rect_panel(0.0, -0.61, -PI * 0.5, 1.0, 0.9, 2.0, Color("#ff7ab0") if kind == 0 else Color("#ffd0e4"), M_LAMP)
	c.rect_panel(0.0, -0.62, -PI * 0.5, 0.5, 0.5, 0.8, Color("#ffe9a0"), M_LAMP)
	c.done()


## A service cabin: `size` the half sizes (u, v), 2.5 m high, front local -v. `kind`: Cabin.WC (a pink
## and a blue sign, two doors), STAFF (a green band), MEDICAL (a lit green cross), SECURITY (a dark
## blue band), OFFICE (a row of lit windows), INFO (a small open kiosk: lit counter, awning).
enum Cabin { WC, STAFF, MEDICAL, SECURITY, OFFICE, INFO }


static func cabin(b, at: Vector2, yaw := 0.0, g := NAN, size := Vector2(1.5, 1.2), kind := Cabin.WC) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var hu := size.x
	var hv := size.y
	var fy := -hv - 0.01
	if kind == Cabin.INFO:
		c.box(-hu, hu, -hv, hv, 0.0, 2.5, Color("#ececf0"), Color("#9a9a9e"))
		c.rect_panel(0.0, fy, -PI * 0.5, hu * 1.5, 1.0, 2.0, Color("#ffd9a0"), M_LAMP)
		c.box(-hu, hu, -hv - 0.5, -hv, 0.95, 1.05, WOOD)
		c.quad(c.p(-hu - 0.1, -hv, 2.4), c.p(hu + 0.1, -hv, 2.4), c.p(hu + 0.1, -hv - 0.8, 2.65), c.p(-hu - 0.1, -hv - 0.8, 2.65), Color("#2a58b0"), M_STONE, Vector3.ZERO, true)
		c.round_panel(hu * 0.7, fy - 0.002, -PI * 0.5, 0.18, 2.1, 8, Color("#2a58b0"), M_LAMP)
		c.done()
		return
	c.box(-hu, hu, -hv, hv, 0.0, 2.5, Color("#ececf0"), Color("#c9c9c4"))
	match kind:
		Cabin.WC:
			c.rect_panel(-hu * 0.5, fy, -PI * 0.5, 0.8, 0.0, 2.0, Color("#6a6a72"), M_STONE)
			c.rect_panel(hu * 0.5, fy, -PI * 0.5, 0.8, 0.0, 2.0, Color("#6a6a72"), M_STONE)
			c.rect_panel(-hu * 0.5, fy - 0.002, -PI * 0.5, 0.4, 2.05, 2.4, Color("#f06a9a"), M_LAMP)
			c.rect_panel(hu * 0.5, fy - 0.002, -PI * 0.5, 0.4, 2.05, 2.4, Color("#4a8ae0"), M_LAMP)
		Cabin.STAFF:
			c.rect_panel(-hu * 0.5, fy, -PI * 0.5, 0.8, 0.0, 2.0, Color("#6a6a72"), M_STONE)
			c.rect_panel(0.0, fy - 0.002, -PI * 0.5, hu * 2.0, 2.1, 2.4, Color("#3a9a5a"), M_STONE)
		Cabin.MEDICAL:
			c.rect_panel(-hu * 0.5, fy, -PI * 0.5, 0.8, 0.0, 2.0, Color("#6a6a72"), M_STONE)
			c.rect_panel(hu * 0.5, fy - 0.002, -PI * 0.5, 0.2, 1.1, 2.0, Color("#3acf6a"), M_LAMP)
			c.rect_panel(hu * 0.5, fy - 0.002, -PI * 0.5, 0.8, 1.4, 1.7, Color("#3acf6a"), M_LAMP)
		Cabin.SECURITY:
			c.rect_panel(-hu * 0.5, fy, -PI * 0.5, 0.8, 0.0, 2.0, Color("#6a6a72"), M_STONE)
			c.rect_panel(0.0, fy - 0.002, -PI * 0.5, hu * 2.0, 2.1, 2.4, Color("#26407a"), M_STONE)
			c.rect_panel(hu * 0.5, fy - 0.002, -PI * 0.5, 0.7, 1.0, 1.7, Color("#ffd9a0"), M_LAMP)
		Cabin.OFFICE:
			for k in 3:
				c.rect_panel(-hu * 0.6 + hu * 0.6 * float(k), fy - 0.002, -PI * 0.5, 0.6, 1.1, 1.9, Color("#ffd9a0"), M_LAMP)
	c.done()


## A cash machine (blue and orange), a wrapper of `booth` kind 2.
static func cash_machine(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	booth(b, at, yaw, g, 2)


## A photo booth (white, pink graphic), a wrapper of `booth` kind 0.
static func photo_booth(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	booth(b, at, yaw, g, 0)


## Bins: `kind` 0 a street bin (0.5 x 0.5 x 1 m, dark green with a lid and a lit band), 1 the waste
## container group (a 5 x 3.5 m grey paving with four 1.3 m containers: grey, yellow, black, green,
## sloped lids). The group's front is local -v.
static func bins(b, at: Vector2, yaw := 0.0, g := NAN, kind := 0) -> void:
	var c := Ctx.new(b, at, yaw, g)
	if kind == 0:
		c.box(-0.25, 0.25, -0.25, 0.25, 0.0, 0.95, Color("#2f5a3c"), Color("#25452e"))
		c.box(-0.28, 0.28, -0.28, 0.28, 0.95, 1.05, Color("#26282e"))
		c.rect_panel(0.0, -0.26, -PI * 0.5, 0.3, 0.55, 0.75, Color("#ffd9a0"), M_LAMP)
	else:
		c.box(-2.5, 2.5, -1.75, 1.75, 0.0, 0.06, Color("#9a9a98"))
		var cols := [Color("#8a8d92"), Color("#e8c030"), Color("#2a2c30"), Color("#3a8a4a")]
		for k in 4:
			var cu := -1.8 + 1.2 * float(k)
			c.box(cu - 0.55, cu + 0.55, 0.0, 1.0, 0.06, 1.1, cols[k])
			c.surface(cu - 0.58, cu + 0.58, -0.05, 1.05, 1, 1, func(_u: float, v: float) -> float: return 1.1 + 0.18 * (1.0 - v), cols[k].darkened(0.2))
	c.done()


## The mural wall: white, 6 x 0.2 x 2.5 m, on a stone-paved strip.
static func mural_wall(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-3.5, 3.5, -1.8, 1.0, 0.0, 0.05, Color("#8a8884"))
	c.box(-3.0, 3.0, -0.1, 0.1, 0.05, 2.5, WHITE, Color("#c9c9c4"))
	c.done()


## A green entrance board (WEJŚCIE, about 2 x 1.5 m, #1E6B2E) on two posts: a white arch and the
## word in white pixel blocks on its front (local -v).
static func entrance_board(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var green := Color("#1e6b2e")
	for sx: float in [-0.8, 0.8]:
		c.pbox(sx, 0.0, 0.0, 0.05, 0.05, 0.0, 1.8, WIRE)
	c.box(-1.0, 1.0, -0.06, 0.06, 1.0, 2.5, green, green.darkened(0.2))
	c.noroof(true)
	# The arch logo: a semicircle and two legs (the reader's -v face: local u runs the other way).
	var prev := Vector3.ZERO
	for k in 9:
		var a := PI * float(k) / 8.0
		var q := Vector3(cos(a) * 0.3, -0.08, 2.1 + sin(a) * 0.3)
		if k > 0:
			c.lbeam(prev, q, 0.07, WHITE, M_LAMP)
		prev = q
	c.lbeam(Vector3(0.3, -0.08, 1.8), Vector3(0.3, -0.08, 2.1), 0.07, WHITE, M_LAMP)
	c.lbeam(Vector3(-0.3, -0.08, 1.8), Vector3(-0.3, -0.08, 2.1), 0.07, WHITE, M_LAMP)
	c.noroof(false)
	c.word("WEJŚCIE", 0.0, -0.075, 1.15, 0.38, WHITE, M_LAMP)
	c.done()


# ---------------------------------------------------------------------------------------------
# 11. The hut upgrade
# ---------------------------------------------------------------------------------------------

## F's choice (2026-11-21): the real photos' dark roofs are the default; orange is the other option.
const HUT_ROOF_DARK := Color("#323438")
const HUT_ROOF_ORANGE := Color("#af5f05")
const HUT_FLAP := Color("#d4d0ca")
## The real reels: the eave and rake bulbs are warm white (the official map's multicolour is illustration).
const HUT_BULB_WARM := Color("#ffd9a0")


## What the official huts have that jarmark.gd's `_jm_hut` doesn't, laid on a chalet of half sizes
## hu x hv (default the white 3.2 x 2.3 m one, eave 2.3 m, roof rise 0.95), front local -v: the
## upper shutter propped up as an awning (hu*2 x 0.6 m, 20 degrees up from the eave), the lower one
## down as a counter (flat at 1.0 m, 0.5 m), two side flaps (0.6 x 1.2 m at 45 degrees), three plank
## grooves on each side and the back wall, warm-white bulbs (#FFD9A0; `multicolour` brings back the map's red, yellow, green, white) along both
## eaves and up the rakes, a thick fir garland with warm bulbs up both front rakes, red velvet drapes under the eave and a red bow at the apex, and (`snow`) a white patch on the roof. Costs about 320 triangles.
static func hut_extras(b, at: Vector2, yaw := 0.0, g := NAN, hu := 1.6, hv := 1.15, eave := 2.3, rise := 0.95,
		snow := false, grooves := true, bulbs := true, seed := 0, multicolour := false) -> void:
	var cols: Array = MULTI if multicolour else [HUT_BULB_WARM]
	var c := Ctx.new(b, at, yaw, g)
	# The upper flap, up as an awning, and the lower flap, down as a counter.
	var a20 := deg_to_rad(20.0)
	c.quad(c.p(-hu, -hv - 0.04, eave - 0.3), c.p(hu, -hv - 0.04, eave - 0.3), c.p(hu, -hv - 0.04 - 0.6 * cos(a20), eave - 0.3 + 0.6 * sin(a20)),
			c.p(-hu, -hv - 0.04 - 0.6 * cos(a20), eave - 0.3 + 0.6 * sin(a20)), HUT_FLAP, M_STONE, Vector3.ZERO, true)
	c.quad(c.p(-hu, -hv - 0.04, 1.0), c.p(hu, -hv - 0.04, 1.0), c.p(hu, -hv - 0.54, 1.0), c.p(-hu, -hv - 0.54, 1.0), HUT_FLAP.darkened(0.08), M_STONE, Vector3.UP, true)
	# The side flaps, hinged at the front corners, folded out at 45 degrees.
	for sd: float in [-1.0, 1.0]:
		var hx := sd * hu
		var ex := sd * (hu + 0.6 * cos(PI * 0.25))
		var ez := -hv - 0.04 - 0.6 * sin(PI * 0.25)
		c.quad(c.p(hx, -hv - 0.04, 1.0), c.p(ex, ez, 1.0), c.p(ex, ez, 2.2), c.p(hx, -hv - 0.04, 2.2), HUT_FLAP, M_STONE, Vector3.ZERO, true)
	# A thick fir garland up both rakes of the front slope, warm bulbs on it.
	c.noroof(true)
	for sd: float in [-1.0, 1.0]:
		var gx := sd * (hu + 0.17)
		c.lbeam(Vector3(gx, -(hv + 0.4), eave + 0.02), Vector3(gx, 0.0, eave + rise + 0.03), 0.2, FIR)
		for k in 7:
			var t := float(k) / 6.0
			c.lbulb(gx - sd * 0.03, -(hv + 0.4) * (1.0 - t), eave + rise * t + 0.15, 0.06, Color("#ffcf80"))
	# Red velvet drapes under the eave (four swags) and a red bow at the apex.
	var dw := hu * 0.5
	for k in 4:
		var cu := -hu + dw * (float(k) + 0.5)
		c.panel(cu, -(hv + 0.28), -PI * 0.5, [Vector2(-dw * 0.5, eave - 0.02), Vector2(dw * 0.5, eave - 0.02), Vector2(dw * 0.32, eave - 0.3),
				Vector2(0.0, eave - 0.42), Vector2(-dw * 0.32, eave - 0.3)], Color("#a01822"), M_STONE, true)
	var bow := Color("#c01c28")
	var bz := eave + rise + 0.1
	c.pbox(0.0, -0.05, 0.0, 0.1, 0.07, bz - 0.07, bz + 0.1, bow.darkened(0.15))
	c.pbox(-0.28, -0.05, 0.5, 0.22, 0.07, bz - 0.04, bz + 0.1, bow)
	c.pbox(0.28, -0.05, -0.5, 0.22, 0.07, bz - 0.04, bz + 0.1, bow)
	c.quad(c.p(-0.1, -0.1, bz - 0.05), c.p(-0.02, -0.1, bz - 0.05), c.p(-0.05, -0.4, bz - 0.42), c.p(-0.17, -0.4, bz - 0.42), bow, M_STONE, Vector3.ZERO, true)
	c.quad(c.p(0.02, -0.1, bz - 0.05), c.p(0.1, -0.1, bz - 0.05), c.p(0.17, -0.4, bz - 0.42), c.p(0.05, -0.4, bz - 0.42), bow, M_STONE, Vector3.ZERO, true)
	c.noroof(false)
	if grooves:
		var groove := Color("#8a8680")
		for k in 3:
			var cv := -hv * 0.5 + hv * 0.5 * float(k)
			c.pbox(hu + 0.012, cv, PI * 0.5, 0.02, 0.012, 0.15, eave - 0.2, groove)
			c.pbox(-hu - 0.012, cv, PI * 0.5, 0.02, 0.012, 0.15, eave - 0.2, groove)
			var cu := -hu * 0.5 + hu * 0.5 * float(k)
			c.pbox(cu, hv + 0.012, 0.0, 0.02, 0.012, 0.15, eave - 0.2, groove)
	if bulbs:
		c.noroof(true)
		var n := seed
		for k in range(0, int(hu * 2.0 / 0.5) + 1):
			var cu := -hu - 0.1 + 0.5 * float(k)
			for ev: float in [-hv - 0.42, hv + 0.42]:
				c.lbulb(cu, ev, eave - 0.1, 0.055, cols[n % cols.size()])
				n += 1
		for sd: float in [-1.0, 1.0]:
			for k in 4:
				var t := float(k + 1) / 5.0
				for sl: float in [-1.0, 1.0]:
					c.lbulb(sd * (hu + 0.15), sl * (hv + 0.4) * (1.0 - t), eave + rise * t - 0.02, 0.055, cols[n % cols.size()])
					n += 1
		c.noroof(false)
	if snow:
		# An irregular off-white patch on the front slope: about a quarter of it.
		var pts: Array[Vector3] = []
		for q in [[-0.55, 0.22], [-0.1, 0.1], [0.35, 0.2], [0.62, 0.12], [0.75, 0.45], [0.4, 0.58], [0.05, 0.4], [-0.3, 0.66], [-0.62, 0.5]]:
			var su: float = (q[0] as float) * hu
			var st: float = q[1]
			pts.append(c.p(su, -(hv + 0.4) * (1.0 - st), eave + rise * st) + Vector3(0.0, 0.03, 0.0))
		var cen := Vector3.ZERO
		for q in pts:
			cen += q
		cen /= float(pts.size())
		for k in pts.size():
			c.tri(cen, pts[k], pts[(k + 1) % pts.size()], Color("#eef2f6"), M_STONE, Vector3.UP)
	c.done()


## A full chalet with the upgrade (for sites that don't use `_jm_hut`): white box 3.2 x 2.3 m, a lit
## counter opening, a gable roof along the front in `roof` (default dark `HUT_ROOF_DARK`; pass
## `HUT_ROOF_ORANGE` for the official orange) and everything `hut_extras` adds.
static func hut(b, at: Vector2, yaw := 0.0, g := NAN, roof := HUT_ROOF_DARK, snow := false, seed := 0, multicolour := false) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var hu := 1.6
	var hv := 1.15
	var eave := 2.3
	var rise := 0.95
	c.box(-hu, hu, -hv, hv, 0.0, eave, JM_WHITE_KIT, Color(0, 0, 0, 0))
	c.rect_panel(0.0, -hv - 0.02, -PI * 0.5, 2.6, 1.05, eave - 0.3, Color("#cf8d4c"), M_LAMP)
	c.box(-hu, hu, -hv - 0.4, -hv, 0.93, 1.03, Color("#6b4a2e"))
	c.gable(hu, hv, eave, rise, JM_WHITE_KIT, roof, roof.darkened(0.2), 0.15, 0.4)
	c.done()
	hut_extras(b, at, yaw, c.g, hu, hv, eave, rise, snow, true, true, seed, multicolour)


const JM_WHITE_KIT := Color("#f2f0ea")


# ---------------------------------------------------------------------------------------------
# 12. The greeting sign and the LED figures
# ---------------------------------------------------------------------------------------------

const SIGN_GOLD := Color("#ffe6a8")


## A word in bulb dots (the pixel font's glyphs, one lit bulb per pixel) on the -v face, centred on
## local u = `cu`, its body's bottom at height y, `h` tall. Left to right runs along -u (the reader
## faces +v), as `_jm_word`.
static func bulb_word(c: Ctx, text: String, cu: float, lv: float, y: float, h: float, col: Color, size: float) -> void:
	var sx := h / 7.0
	var width := 0.0
	for ch in text:
		width += (int(c.b._pow_glyph_w(ch)) + 1) * sx
	width -= sx
	var at := cu + width * 0.5
	for ch in text:
		if ch != " ":
			for q: Vector2i in c.b._pow_glyph(ch):
				var row := 2 + 6 - q.y  # PixelFont.BODY + 6 - y: the body's bottom row is 0
				c.lbulb(at - float(q.x) * sx, lv, y + float(row) * sx, size, col)
		at -= (int(c.b._pow_glyph_w(ch)) + 1) * sx


## The greeting sign: about 8 m wide on a low dark base, a dark board with "WESOŁYCH" small and
## "ŚWIĄT" big in gold-white bulb dots (the pixel font; capitals, as the market's other sign), small
## blue stars and white snowflakes above. Reads from local -v.
static func wesolych_swiat_sign(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	c.box(-4.3, 4.3, -0.4, 0.5, 0.0, 0.45, Color("#26282e"), Color("#3a3c44"))
	c.box(-4.0, 4.0, 0.0, 0.12, 0.45, 5.2, Color("#171a26"))
	for sx: float in [-4.05, 4.05]:
		c.pbox(sx, 0.05, 0.0, 0.09, 0.09, 0.45, 5.4, Color("#2a2c32"))
	bulb_word(c, "WESOŁYCH", 0.0, -0.06, 3.5, 1.0, SIGN_GOLD, 0.05)
	bulb_word(c, "ŚWIĄT", 0.0, -0.06, 1.0, 1.75, SIGN_GOLD, 0.085)
	for k in 7:
		var cu := -3.6 + 1.2 * float(k)
		var cy := 5.95 + 0.25 * sin(PI * float(k) / 6.0)
		if k % 2 == 0:
			b._mode = M_LAMP
			b._jm_star(c.p(cu, -0.06, cy), 0.42, Vector3(c.u.x, 0.0, c.u.y), Color("#5a8cff"))
		else:
			for arm in 3:
				var a := PI * float(arm) / 3.0
				c.lbeam(Vector3(cu + cos(a) * 0.4, -0.06, cy + sin(a) * 0.4), Vector3(cu - cos(a) * 0.4, -0.06, cy - sin(a) * 0.4), 0.05, WHITE, M_LAMP)
			c.lbulb(cu, -0.06, cy, 0.07, WHITE)
	c.noroof(false)
	c.done()


## An LED figure, lit white: `kind` 0 a fir outline 4 m tall on a pole (two crossed planes, three
## tiers of bulbs), `kind` 1 a pair of angel wings 2.5 m tall on a short stand (six feathers a
## side, facing local -v).
static func led_figure(b, at: Vector2, yaw := 0.0, g := NAN, kind := 0) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	var led := Color(0.9, 0.94, 1.0)
	if kind == 0:
		c.lbeam(Vector3(0, 0, 0), Vector3(0, 0, 1.4), 0.1, WIRE)
		for plane in 2:
			var tiers := [[1.0, 2.5, 1.25], [1.9, 3.3, 0.95], [2.8, 4.0, 0.62]]
			for tr in tiers:
				var y0: float = tr[0]
				var y1: float = tr[1]
				var hw: float = tr[2]
				var pts := [Vector3(-hw, 0, y0), Vector3(hw, 0, y0), Vector3(0, 0, y1)]
				for i in 3:
					var p0: Vector3 = pts[i]
					var p1: Vector3 = pts[(i + 1) % 3]
					if plane == 1:
						p0 = Vector3(p0.y, p0.x, p0.z)
						p1 = Vector3(p1.y, p1.x, p1.z)
					c.lbeam(p0, p1, 0.07, led, M_LAMP)
					c.lbulb(p0.x, p0.y, p0.z, 0.09, WHITE)
		c.lbulb(0, 0, 4.1, 0.14, Color("#ffe9a0"))
	else:
		c.lbeam(Vector3(0, 0, 0), Vector3(0, 0, 0.7), 0.1, WIRE)
		for sx: float in [-1.0, 1.0]:
			var base := Vector3(sx * 0.3, 0.0, 0.9)
			for i in 6:
				var ang := deg_to_rad(lerpf(14.0, 82.0, float(i) / 5.0))
				var len := 1.7 - 0.1 * float(i)
				var d := Vector3(sx * sin(ang), 0.0, cos(ang))
				var perp := Vector3(cos(ang) * sx, 0.0, -sin(ang)).normalized() * 0.16
				var tip := base + d * len
				var mid := base + d * len * 0.55
				c.lbeam(base, mid + perp, 0.06, led, M_LAMP)
				c.lbeam(mid + perp, tip, 0.06, led, M_LAMP)
				c.lbeam(base, mid - perp, 0.06, led, M_LAMP)
				c.lbeam(mid - perp, tip, 0.06, led, M_LAMP)
				c.lbulb(tip.x, tip.y, tip.z, 0.1, WHITE)
	c.noroof(false)
	c.done()


# ---------------------------------------------------------------------------------------------
# 13. Small details of the official map (round 6)
# ---------------------------------------------------------------------------------------------

## The market's warm white (the lighting decision, 2026-11-21: about 85 % of the light).
const WARM := Color("#ffd9a0")


## A white LED arch, 4 m wide and 4 m high, two concentric outlines (r 2.0 and 1.75) of bulbs and
## lamp lines, legs to the ground; several in a row (every 3 m along u) make the tunnel. Plane: u-y.
static func light_arch(b, at: Vector2, yaw := 0.0, g := NAN, col := WARM) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	for r: float in [2.0, 1.75]:
		var pts: Array = [Vector2(-r, 0.0)]
		for k in range(0, 17):
			var a := PI - PI * float(k) / 16.0
			pts.append(Vector2(cos(a) * r, 2.0 + sin(a) * (r + 0.0)))
		pts.append(Vector2(r, 0.0))
		c.poly(pts, 0.0, 0.05, col)
		c.poly_bulbs(pts, 0.0, 0.32, 0.06, WHITE)
	c.noroof(false)
	c.done()


## A giant lit bauble (about 2 m) on a low plinth, with a gold cap and a hook: `color` red (default) or
## gold. No yaw (it is round).
static func ornament_ball(b, at: Vector2, g := NAN, color := Color("#d6252c")) -> void:
	var c := Ctx.new(b, at, 0.0, g)
	c.prism(0, 0, 0.7, 12, 0.0, 0.3, Color("#2a2c30"), Color("#3a3c44"))
	c.sphere(0, 0, 1.4, 1.0, 14, 8, color.darkened(0.3), M_LAMP)
	c.prism(0, 0, 0.3, 10, 2.35, 2.62, GOLD, GOLD.lightened(0.1))
	c.noroof(true)
	var prev := Vector3(0.12, 0.0, 2.62)
	for k in range(1, 9):
		var a := PI * float(k) / 8.0
		var q := Vector3(0.12 * cos(a), 0.0, 2.62 + 0.3 * sin(a))
		c.lbeam(prev, q, 0.05, GOLD)
		prev = q
	c.noroof(false)
	c.done()


## A gold wire reindeer, about 2 m (antlers to 2.1 m), outlined in lamp lines in the u-y plane,
## facing local +u: oval body, neck, head, two-pronged antlers, four legs, a tail.
static func reindeer(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	var gold := Color("#e8b030")
	var body: Array = []
	for k in 13:
		var a := TAU * float(k) / 12.0
		body.append(Vector2(cos(a) * 0.7, 1.0 + sin(a) * 0.33))
	c.poly(body, 0.0, 0.04, gold)
	c.poly([Vector2(0.55, 1.2), Vector2(0.78, 1.6), Vector2(0.92, 1.66)], 0.0, 0.04, gold)
	c.poly([Vector2(0.55, 1.05), Vector2(0.72, 1.45), Vector2(0.88, 1.5)], 0.0, 0.04, gold)
	var head: Array = []
	for k in 9:
		var a := TAU * float(k) / 8.0
		head.append(Vector2(1.0 + cos(a) * 0.17, 1.72 + sin(a) * 0.12))
	c.poly(head, 0.0, 0.04, gold)
	c.poly([Vector2(1.14, 1.68), Vector2(1.32, 1.6)], 0.0, 0.04, gold)
	c.poly([Vector2(0.95, 1.82), Vector2(0.9, 2.1), Vector2(0.78, 2.2)], 0.0, 0.04, gold)
	c.poly([Vector2(0.9, 2.0), Vector2(1.05, 2.1)], 0.0, 0.04, gold)
	c.poly([Vector2(1.02, 1.82), Vector2(1.08, 2.1), Vector2(1.2, 2.2)], 0.0, 0.04, gold)
	c.poly([Vector2(1.08, 2.0), Vector2(0.95, 2.1)], 0.0, 0.04, gold)
	for lx: float in [0.45, 0.28, -0.4, -0.55]:
		c.poly([Vector2(lx, 0.72), Vector2(lx + 0.03, 0.35), Vector2(lx, 0.0)], 0.0, 0.04, gold)
	c.poly([Vector2(-0.68, 1.1), Vector2(-0.9, 1.25)], 0.0, 0.04, gold)
	c.poly_bulbs(body, 0.0, 0.45, 0.05, WARM)
	c.lbulb(1.1, 0.0, 1.74, 0.07, Color("#ff4a3a"))
	c.noroof(false)
	c.done()


## A big lit gift box (`size` m a side, `color`) with a gold ribbon on both axes and a bow on top.
static func gift_box(b, at: Vector2, yaw := 0.0, g := NAN, size := 1.6, color := Color("#c01c28")) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var h := size * 0.5
	c.box(-h, h, -h, h, 0.0, size, color.darkened(0.3), color.darkened(0.2), M_LAMP)
	var rb := 0.12 * size
	c.box(-rb, rb, -h - 0.02, h + 0.02, 0.0, size + 0.02, GOLD, GOLD, M_LAMP)
	c.box(-h - 0.02, h + 0.02, -rb, rb, 0.0, size + 0.02, GOLD, GOLD, M_LAMP)
	c.pbox(-0.3 * size, 0.0, 0.4, 0.25 * size, 0.08 * size, size, size + 0.22 * size, GOLD, CLEAR, M_LAMP)
	c.pbox(0.3 * size, 0.0, -0.4, 0.25 * size, 0.08 * size, size, size + 0.22 * size, GOLD, CLEAR, M_LAMP)
	c.box(-0.08 * size, 0.08 * size, -0.08 * size, 0.08 * size, size, size + 0.16 * size, GOLD.darkened(0.1), CLEAR, M_LAMP)
	c.done()


## A dome tent, 8 m across (r 4, 3.2 m high), blue-white lit (M_LAMP), eight white ribs
## and a base ring. No yaw.
static func blue_dome(b, at: Vector2, g := NAN) -> void:
	var c := Ctx.new(b, at, 0.0, g)
	var skin := Color("#3c5088")
	var rings := 6
	for i in rings:
		var a0 := (PI * 0.5) * float(i) / float(rings)
		var a1 := (PI * 0.5) * float(i + 1) / float(rings)
		c.frustum(0, 0, 4.0 * cos(a0), 4.0 * sin(a0) * 0.8, maxf(4.0 * cos(a1), 0.0), 4.0 * sin(a1) * 0.8, 16, skin.darkened(0.15 * float(i) / float(rings)), CLEAR, M_LAMP)
	c.noroof(true)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var prev := Vector3(cos(a) * 4.05, sin(a) * 4.05, 0.0)
		for i in range(1, rings + 1):
			var e := (PI * 0.5) * float(i) / float(rings)
			var q := Vector3(cos(a) * 4.05 * cos(e), sin(a) * 4.05 * cos(e), 4.05 * sin(e) * 0.8)
			c.lbeam(prev, q, 0.1, Color("#f2f6ff"), M_LAMP)
			prev = q
	c.prism(0, 0, 4.05, 16, 0.0, 0.2, Color("#d8e2f4"), CLEAR, M_LAMP)
	c.noroof(false)
	c.done()


## The beer garden, 14 x 10 m: dark decking, a grey fence (posts every 1.5 m, two rails) with warm bulbs
## on top and a gap at local -v, six wooden tables with two benches each, and a bare tree in the back
## corner.
static func beer_garden(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var grey := Color("#7a7d82")
	c.box(-7.0, 7.0, -5.0, 5.0, 0.0, 0.1, Color("#4a3a2c"))
	c.noroof(true)
	var corners: Array = [Vector2(-7, -5), Vector2(7, -5), Vector2(7, 5), Vector2(-7, 5)]
	for i in 4:
		var a: Vector2 = corners[i]
		var d: Vector2 = corners[(i + 1) % 4]
		var cnt := int(a.distance_to(d) / 1.5)
		for k in cnt + 1:
			var q := a.lerp(d, float(k) / float(cnt))
			if i == 0 and absf(q.x) < 1.6:
				continue
			c.pbox(q.x, q.y, 0.0, 0.06, 0.06, 0.1, 1.3, grey)
			c.lbulb(q.x, q.y, 1.38, 0.07, WARM)
		for h: float in [0.55, 1.05]:
			if i == 0:
				c.lbeam(Vector3(-7, -5, h), Vector3(-1.6, -5, h), 0.05, grey, M_STONE)
				c.lbeam(Vector3(1.6, -5, h), Vector3(7, -5, h), 0.05, grey, M_STONE)
			else:
				c.lbeam(Vector3(a.x, a.y, h), Vector3(d.x, d.y, h), 0.05, grey, M_STONE)
	c.noroof(false)
	for ix in 3:
		for iz in 2:
			var tx := -4.0 + 4.0 * float(ix)
			var tz := -1.8 + 3.2 * float(iz)
			c.box(tx - 1.0, tx + 1.0, tz - 0.4, tz + 0.4, 0.7, 0.78, WOOD.lightened(0.15))
			for sx: float in [-0.8, 0.8]:
				c.pbox(tx + sx, tz, 0.0, 0.05, 0.3, 0.1, 0.7, WOOD.darkened(0.2))
			for sz: float in [-0.75, 0.75]:
				c.box(tx - 1.0, tx + 1.0, tz + sz - 0.18, tz + sz + 0.18, 0.4, 0.46, WOOD)
	# A bare tree: trunk and two levels of branches.
	c.noroof(true)
	c.lbeam(Vector3(5.5, 3.8, 0.1), Vector3(5.5, 3.8, 3.2), 0.28, Color("#4a3a2c"), M_STONE)
	for k in 5:
		var a := TAU * float(k) / 5.0
		var tip := Vector3(5.5 + cos(a) * 1.4, 3.8 + sin(a) * 1.4, 4.6)
		c.lbeam(Vector3(5.5, 3.8, 2.6), tip, 0.12, Color("#4a3a2c"), M_STONE)
		c.lbeam(tip, Vector3(5.5 + cos(a) * 1.9, 3.8 + sin(a) * 1.9, 5.2), 0.07, Color("#4a3a2c"), M_STONE)
	c.noroof(false)
	c.done()


## The Santa sleigh scene, 8 x 6 m: a red base, a red sleigh (runners curling up at the front, a body
## with a curved back and a white seat, gold trim), two white lit trees and a lit snowman.
static func sleigh_scene(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var red := Color("#c03030")
	c.box(-4.0, 4.0, -3.0, 3.0, 0.0, 0.15, red)
	for sd: float in [-0.7, 0.7]:
		c.poly([Vector2(-1.5, 0.35), Vector2(0.9, 0.35), Vector2(1.6, 0.55), Vector2(1.9, 1.0)], sd, 0.12, GOLD.darkened(0.15), false, M_STONE)
	c.box(-1.4, 1.3, -0.8, 0.8, 0.45, 0.9, red.darkened(0.1), red)
	c.box(-1.4, -1.1, -0.8, 0.8, 0.9, 1.9, red)
	c.box(-1.1, 1.0, -0.6, 0.6, 0.9, 1.0, Color("#f2f0ea"))
	c.box(-1.42, 1.32, -0.82, 0.82, 0.78, 0.86, GOLD, CLEAR, M_LAMP)
	c.fir(-3.0, 1.8, 4.6, true, true, SNOW)
	c.fir(2.8, 2.2, 3.4, true, true, SNOW)
	c.snowman_at(3.0, -1.8, 1.0)
	c.done()


## A white vaulted tent (the three white tents, the big hall 20 x 12 m): `length` along u, `width`
## across (default 0.6 x length), vault height 0.4 x width up to 5 m. White glow inside (M_LAMP),
## blue ribs every 2.5 m, the two ends closed with white arches.
static func white_tent(b, at: Vector2, yaw := 0.0, g := NAN, length := 10.0, width := -1.0) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var w := width if width > 0.0 else length * 0.6
	var hw := w * 0.5
	var h := minf(w * 0.4, 5.0)
	var hl := length * 0.5
	var segs := 14
	var skin := Color("#566274")
	var rib := Color("#2a3a7a")
	var ribs := maxi(2, int(length / 2.5))
	var arc := func(i: int) -> Vector2:
		var a := PI * float(i) / float(segs)
		return Vector2(-cos(a) * hw, 0.3 + sin(a) * h)
	for i in segs:
		var p0: Vector2 = arc.call(i)
		var p1: Vector2 = arc.call(i + 1)
		c.quad(c.p(-hl, p0.x, p0.y), c.p(hl, p0.x, p0.y), c.p(hl, p1.x, p1.y), c.p(-hl, p1.x, p1.y), skin, M_LAMP, Vector3.ZERO, true)
		for sd: float in [-1.0, 1.0]:
			c.tri(c.p(sd * hl, 0.0, 0.3), c.p(sd * hl, p0.x, p0.y), c.p(sd * hl, p1.x, p1.y), skin.lightened(0.08), M_LAMP, Vector3(c.u.x * sd, 0.0, c.u.y * sd))
	c.noroof(true)
	for k in ribs + 1:
		var ru := -hl + length * float(k) / float(ribs)
		var pts: Array = []
		for i in segs + 1:
			var q: Vector2 = arc.call(i)
			pts.append(q)
		for i in segs:
			var q0: Vector2 = pts[i]
			var q1: Vector2 = pts[i + 1]
			c.lbeam(Vector3(ru, q0.x, q0.y + 0.03), Vector3(ru, q1.x, q1.y + 0.03), 0.14, rib, M_STONE)
	c.lbeam(Vector3(-hl, -hw, 0.3), Vector3(hl, -hw, 0.3), 0.14, rib, M_STONE)
	c.lbeam(Vector3(-hl, hw, 0.3), Vector3(hl, hw, 0.3), 0.14, rib, M_STONE)
	c.noroof(false)
	c.done()


## A blue-roofed arcade pavilion, 16 x 6 m, front local -v: white square piers every 2 m with eight warm
## arched openings and a bar counter, a pitched blue roof (eave 3.6 m, ridge 5.2 m) and a small white
## tower at the +u end with a red pyramid cap (to 6.6 m).
static func blue_pavilion(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.box(-8.0, 8.0, -3.0, 3.0, 0.0, 0.2, Color("#9a9a98"))
	c.box(-8.0, 8.0, 2.6, 3.0, 0.2, 3.6, Color("#e8e8ec"))
	for k in 9:
		c.box(-8.0 + 2.0 * float(k) - 0.2, -8.0 + 2.0 * float(k) + 0.2, -3.0, -2.6, 0.2, 3.6, WHITE)
	for k in 8:
		var cu := -7.0 + 2.0 * float(k)
		c.arch_panel(cu, 2.58, -PI * 0.5, 1.4, 0.3, 3.0, WARM, M_LAMP)
	c.box(-7.5, 7.5, -2.0, -1.5, 0.2, 1.05, WOOD, Color("#d9b27a"))
	c.gable(8.0, 3.0, 3.6, 1.6, WHITE, Color("#2a58b0"), Color("#1e4088"), 0.4, 0.6)
	c.noroof(true)
	for k in 17:
		c.lbulb(-8.0 + 1.0 * float(k), -3.55, 3.5, 0.07, WARM)
	c.noroof(false)
	c.box(5.6, 7.4, -0.9, 0.9, 3.6, 5.6, WHITE)
	c.frustum(6.5, 0.0, 1.45, 5.6, 0.0, 7.0, 4, Color("#c03030"), CLEAR, M_STONE, -1.0, PI * 0.25)
	c.arch_panel(6.5, -0.92, -PI * 0.5, 0.6, 4.0, 5.2, WARM, M_LAMP)
	c.done()


## The Palace's corner tree: a tall (8 m) lit tree of five tiers of white-blue LED (M_LAMP) with warm
## bulbs on the tier edges and a red lit bauble on top. No yaw.
static func palace_corner_tree(b, at: Vector2, g := NAN) -> void:
	var c := Ctx.new(b, at, 0.0, g)
	c.prism(0, 0, 0.25, 6, 0.0, 1.0, WOOD.darkened(0.2))
	for k in 5:
		var y0 := 0.8 + 1.35 * float(k)
		var r0 := 2.3 - 0.4 * float(k)
		c.frustum(0, 0, r0, y0, r0 * 0.2, y0 + 1.9, 10, Color("#8fa4d8"), CLEAR, M_LAMP_BLUE)
		c.noroof(true)
		c.bulb_ring(0, 0, r0 * 0.95, y0 + 0.05, 12, 0.08, [WARM], M_LAMP, 0.2 * float(k))
		c.noroof(false)
	c.sphere(0, 0, 8.15, 0.45, 10, 5, Color("#8a1a20"), M_LAMP)
	c.done()


## The red GRZANIEC container booth (the generic word only): 6 x 2.5 x 2.8 m, red (#B8282A), a wide
## lit open counter (4.8 m), the word in gold bulb letters across the lower front, and a fir garland
## with red and gold baubles and warm bulbs round the roof edge. Front local -v.
static func grzaniec_booth(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var red := Color("#b8282a")
	c.box(-3.0, 3.0, -1.25, 1.25, 0.0, 2.8, red, red.darkened(0.3))
	for k in 20:
		c.pbox(-2.85 + 0.3 * float(k), -1.26, 0.0, 0.03, 0.02, 0.1, 2.7, red.darkened(0.25))
	c.rect_panel(0.0, -1.27, -PI * 0.5, 4.8, 1.0, 2.35, Color("#2a1a14"), M_STONE)
	c.rect_panel(0.0, -1.28, -PI * 0.5, 4.6, 1.1, 2.3, WARM, M_LAMP)
	c.box(-2.5, 2.5, -1.9, -1.27, 0.95, 1.05, WOOD)
	c.noroof(true)
	bulb_word(c, "GRZANIEC", 0.0, -1.3, 0.2, 0.62, Color("#ffd070"), 0.04)
	var corners: Array = [Vector2(-3.05, -1.3), Vector2(3.05, -1.3), Vector2(3.05, 1.3), Vector2(-3.05, 1.3)]
	for i in 4:
		var a: Vector2 = corners[i]
		var d: Vector2 = corners[(i + 1) % 4]
		c.lbeam(Vector3(a.x, a.y, 2.85), Vector3(d.x, d.y, 2.85), 0.3, FIR)
		var cnt := int(a.distance_to(d) / 0.5)
		for k in cnt:
			var q := a.lerp(d, float(k) / float(cnt))
			var bc := Color("#d6252c") if k % 2 == 0 else Color("#e0b030")
			c.sphere(q.x, q.y, 3.0, 0.13, 6, 3, bc)
			c.lbulb(q.x + 0.12, q.y, 2.98, 0.05, WARM)
	c.noroof(false)
	c.done()


## A blue-white LED walk-through arch shaped like a tall tiered Christmas tree (6 m high, 4 m wide),
## two parallel outlines 0.5 m apart tied at the corners, a heart-shaped opening (about 2 m) at the
## bottom, blue lines with white bulb tips and a small gold star on top.
static func led_tree_arch(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.noroof(true)
	var blue := Color("#6a8cff")
	var left: Array = [Vector2(-2.0, 0.0), Vector2(-0.95, 2.2), Vector2(-1.45, 2.2), Vector2(-0.65, 3.9), Vector2(-1.05, 3.9), Vector2(-0.3, 5.4), Vector2(0.0, 6.0)]
	var outline: Array = left.duplicate()
	for i in range(left.size() - 2, -1, -1):
		var q: Vector2 = left[i]
		outline.append(Vector2(-q.x, q.y))
	var heart: Array = []
	for k in 17:
		var t := TAU * float(k) / 16.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		heart.append(Vector2(x, y) * 0.062 + Vector2(0.0, 1.35))
	for lv: float in [-0.25, 0.25]:
		c.poly(outline, lv, 0.07, blue)
		c.poly(heart, lv, 0.06, Color("#cfe0ff"))
		c.poly([Vector2(-1.05, 2.2), Vector2(1.05, 2.2)], lv, 0.05, blue)
		c.poly([Vector2(-0.75, 3.9), Vector2(0.75, 3.9)], lv, 0.05, blue)
		for q in outline:
			var qq: Vector2 = q
			c.lbulb(qq.x, lv, qq.y, 0.1, WHITE)
		c.poly_bulbs(outline, lv, 0.5, 0.05, Color("#9ab8ff"))
	for q in outline:
		var qq: Vector2 = q
		c.lbeam(Vector3(qq.x, -0.25, qq.y), Vector3(qq.x, 0.25, qq.y), 0.05, blue)
	b._mode = M_LAMP
	b._jm_star(c.p(0, 0, 6.5), 0.45, Vector3(c.u.x, 0.0, c.u.y), Color("#e8b030"))
	c.noroof(false)
	c.done()


## A snowman (`size` m tall, default 2.5): three white lit balls, a black hat, an orange nose, a red
## scarf and two stick arms. No front: it looks towards local -v.
static func snowman(b, at: Vector2, yaw := 0.0, g := NAN, size := 2.5) -> void:
	var c := Ctx.new(b, at, yaw, g)
	c.snowman_at(0.0, 0.0, size / 2.5)
	c.done()


## A yellow bench (the yellow seats round the tree): 1.9 m long, seat facing local -v, backrest at +v.
static func yellow_bench(b, at: Vector2, yaw := 0.0, g := NAN) -> void:
	var c := Ctx.new(b, at, yaw, g)
	var y := Color("#e9b62c")
	c.box(-0.95, 0.95, -0.25, 0.25, 0.4, 0.5, y, y.lightened(0.1))
	c.box(-0.95, 0.95, 0.2, 0.27, 0.5, 0.95, y)
	for sx: float in [-0.8, 0.8]:
		c.box(sx - 0.06, sx + 0.06, -0.2, 0.2, 0.0, 0.4, Color("#9a7a2a"))
	c.done()
