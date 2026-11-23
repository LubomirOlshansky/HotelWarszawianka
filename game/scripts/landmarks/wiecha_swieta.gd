extends "res://scripts/landmarks/jarmark.gd"
## Pasaż Wiecha's Christmas lights, 2026 (F, 2026-11-22: "model Pasaż Wiecha, improve what is there,
## add people, fly over it with a drone", from F's six night photos and an Instagram carousel of the
## opening night). One link of landmarks.gd's base chain (TD-10): it uses this file, common.gd and
## the facade kit, never another area (the pasaż's frame and lamp masts are read from
## first_scene.gd, which owns them). Refs (never shipped): /mnt/project-files/refs/pasaz-wiecha-2026/.
## Spec docs/landmarks/specs/wiecha_swieta.md.
##
## The frame is the first scene's (first_scene.gd FRAME_*): u = s, metres north along Marszałkowska,
## v = t, metres east of it; the stores' backs stand at v 61-62, the pavilions' fronts at v 72-77.
## What the photos show, south (Aleje Jerozolimskie) to north (Złota):
##  - a pair of shooting stars on every white Y mast: an eight-petalled white LED star with a gold
##    heart, its tail of white strands and warm bulbs falling towards the pole;
##  - by Wars: the big neon fir of crossed fins (yellow tube outside, red inside, pale film between),
##    an orange wire bauble and a gold open bauble the children stand in, a bench, flat yellow
##    zig-zag firs on the glass, a heart and a candy cane in neon further south;
##  - the purple and gold bauble benches, one by Zodiak's square, one on the square at Chmielna;
##  - the WARSIK SAWKA JUNIOREK photo frame (the stores' own sign, parodied as everywhere in the
##    game): white words on a starry navy panel, a purple glitter foot, a rainbow neon border;
##  - the gingerbread-man tunnel: five neon outlines one behind another (blue, green, cream,
##    yellow, red), each smaller, on two grated rails, by the cafés of Złota 11;
##  - the blue tinsel photo frame by Słoik's (here SŁOICZEK's) terrace;
##  - white LED curtains on the stores' back glass.
## Everything is the city's building surface (+0 draw calls); every light is M_LAMP (its colour by
## day, glowing at night). `wiecha_plan` gives crowds.gd its standing people (photo-takers by the
## decorations); wiecha_life.gd walks the strollers up and down the pasaż.

const FirstScene := preload("res://scripts/first_scene.gd")

const WX_LED := Color(0.86, 0.93, 1.0)
const WX_LED_DIM := Color(0.42, 0.52, 0.72)
const WX_WARM := Color(1.0, 0.8, 0.45)
const WX_GOLD := Color(1.0, 0.76, 0.3)
const WX_PURPLE := Color(0.56, 0.2, 1.0)
const WX_NAVY := Color(0.05, 0.07, 0.26)
const WX_METAL := Color("#2f3340")
const WX_BRONZE := Color("#5e4a2c")
const WX_ORANGE := Color(1.0, 0.42, 0.08)
## The gingerbread tunnel's tubes, front (south) to back.
const WX_GINGER := [Color(0.14, 0.3, 1.0), Color(0.18, 0.95, 0.3), Color(1.0, 0.95, 0.62), Color(1.0, 0.78, 0.12),
		Color(1.0, 0.16, 0.1)]
const WX_RAINBOW := [Color(1.0, 0.15, 0.2), Color(1.0, 0.55, 0.1), Color(1.0, 0.9, 0.2), Color(0.2, 0.95, 0.35),
		Color(0.2, 0.6, 1.0), Color(0.7, 0.25, 1.0)]

## Where things stand, (u, v) in the frame. From the photos against the OSM shops (Boardriders on
## Wars' back, the cafés of Złota 11, Słoik, Kiseki) and the masts' own places.
const WX_FRAME_AT := Vector2(-83.0, 65.4)       # the photo frame, just south of the mast at -80
const WX_GINGER_AT := Vector2(-27.5, 68.6)      # the tunnel, opposite WEGE FUD and AUREOLA
const WX_TINSEL_AT := Vector2(13.6, 66.9)       # the blue frame, north of the mast at 10
const WX_TREE_AT := Vector2(-127.0, 68.4)       # the neon fir by Wars
const WX_BENCH_AT := Vector2(-121.4, 66.6)
const WX_ORANGE_AT := Vector2(-112.4, 64.9)
const WX_HALF_AT := Vector2(-118.2, 63.9)
## The purple and gold bauble benches: [u, v, which way the opening looks (radians from +u)].
const WX_BAUBLES := [[-97.0, 75.6, -2.2], [-69.6, 83.2, -2.6]]
## The LED curtains on the stores' back glass: [u0, u1, v of the glass].
const WX_CURTAINS := [[-38.0, -31.0, 62.0], [1.0, 9.0, 62.0], [73.0, 80.0, 62.0], [-104.5, -99.5, 61.0]]
## The flat neon firs on Wars' glass: [u, v].
const WX_FLAT_FIRS := [[-109.2, 61.0], [-134.0, 61.0]]
## The neon shapes further south on the stores' side: [kind, u, v].
const WX_SHAPES := [["heart", -141.0, 64.4], ["cane", -151.0, 64.6], ["ball", -162.0, 65.6]]
## The parody words on fronts the pavilions' kit does not own (the tower's base by Chmielna, the
## strip in front of Scena Relax, the cinema on Chmielna): [word, u, v, y over the ground, w, colour].
const WX_SIGNS := [["PO CZESKU", -86.0, 77.8, 3.6, 3.4, Color(1.0, 0.82, 0.3)],
		["KAWIARNIA RELAKS", 108.0, 71.8, 3.4, 4.6, Color(1.0, 0.3, 0.45)],
		["WŁOSKI ZASTÓJ", 92.0, 71.8, 3.4, 4.4, Color(0.3, 1.0, 0.5)],
		["KOSMOSIK", 118.5, 72.6, 3.4, 2.8, Color(0.4, 0.7, 1.0)]]


func _wx_frame() -> void:
	_o = FirstScene.FRAME_O
	_a = FirstScene.FRAME_S.normalized()
	_b = Vector2(-_a.y, _a.x)


func _wx_g(u: float, v: float) -> float:
	var p := _w(u, v)
	return map.ground_height(p.x, p.y)


func _wx_p(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


## The frame's axes as 3D directions.
func _wx_U() -> Vector3:
	return Vector3(_a.x, 0.0, _a.y)


func _wx_V() -> Vector3:
	return Vector3(_b.x, 0.0, _b.y)


## Every mast of the pasaż (first_scene.gd PASAZ_MASTS), (u, v).
static func _wx_masts() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for m: Array in FirstScene.PASAZ_MASTS:
		out.append(Vector2(float(m[0]), float(m[1])))
	return out


static func _wx_world(u: float, v: float) -> Vector2:
	var a := FirstScene.FRAME_S.normalized()
	return FirstScene.FRAME_O + a * u + Vector2(-a.y, a.x) * v


func _find_wiecha_swieta() -> void:
	_wx_frame()
	var zones: Array = []
	for c: Vector2 in [WX_FRAME_AT, WX_GINGER_AT, WX_TINSEL_AT, WX_TREE_AT, WX_ORANGE_AT, WX_HALF_AT]:
		zones.append(_rect(c.x, c.y, 1.8, 1.8))
	for b: Array in WX_BAUBLES:
		zones.append(_rect(b[0], b[1], 2.0, 2.0))
	_add_site("wiecha_swieta", zones)


func _build_wiecha_swieta(_site: Dictionary) -> void:
	_wx_frame()
	_mode = M_STONE
	for m in _wx_masts():
		for side: float in [-1.0, 1.0]:
			_wx_comet(m, side)
	_wx_photo_frame(WX_FRAME_AT)
	_wx_gingerbread(WX_GINGER_AT)
	_wx_tinsel(WX_TINSEL_AT)
	_wx_neon_fir(WX_TREE_AT)
	_wx_bench(WX_BENCH_AT)
	_wx_wire_ball(WX_ORANGE_AT)
	_wx_bauble(WX_HALF_AT, 1.05, -2.0, 0.0, WX_GOLD, WX_GOLD.darkened(0.25), false)
	for b: Array in WX_BAUBLES:
		_wx_bauble(Vector2(b[0], b[1]), 1.75, float(b[2]), 0.42, WX_PURPLE, WX_GOLD, true)
	for c: Array in WX_CURTAINS:
		_wx_curtain(c[0], c[1], c[2])
	for f: Array in WX_FLAT_FIRS:
		_wx_flat_fir(f[0], f[1])
	for s: Array in WX_SHAPES:
		_wx_shape(str(s[0]), s[1], s[2])
	for s: Array in WX_SIGNS:
		_wx_frame()
		var g := _wx_g(s[1], s[2])
		_usign(str(s[0]), s[1], s[2], g + float(s[3]), -_b, float(s[4]), 0.5, s[5])
	_wx_frame()
	_mode = M_STONE


# --- small kit ---------------------------------------------------------------------------------

## A lit tube along points (world), `w` thick, out of the roof grid.
func _wx_tube(pts: Array, w: float, col: Color, mode := M_LAMP) -> void:
	_no_roof = true
	for k in range(1, pts.size()):
		_beam(pts[k - 1], pts[k], w, col, false, mode)
	_no_roof = false


## A flat polygon (world points round its edge, convex or a fan from its first point), seen from both
## faces, `n` its normal.
func _wx_flat(pts: Array, n: Vector3, col: Color, mode := M_LAMP) -> void:
	var keep := _mode
	_mode = mode
	var off := n * 0.012
	for k in range(1, pts.size() - 1):
		var a: Vector3 = pts[0]
		var b: Vector3 = pts[k]
		var c: Vector3 = pts[k + 1]
		_tri(a + off, b + off, c + off, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
		_tri(a - off, c - off, b - off, -n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep


## A small lit bulb (a box `s` across) at a world point.
func _wx_bulb(at: Vector3, s: float, col: Color) -> void:
	var h := s * 0.5
	_no_roof = true
	_prism(PackedVector2Array([Vector2(at.x - h, at.z - h), Vector2(at.x + h, at.z - h), Vector2(at.x + h, at.z + h),
			Vector2(at.x - h, at.z + h)]), at.y - h, at.y + h, col, col, M_LAMP, M_LAMP)
	_no_roof = false


## Catmull-Rom through 2D points, `sub` pieces a span (the ends kept).
static func _wx_smooth(pts: Array, sub: int) -> Array:
	var out: Array = []
	var n := pts.size()
	for i in n - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, n - 1)]
		for k in sub:
			var t := float(k) / sub
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[n - 1])
	return out


## Pixel words on an upright plane: centred on `c` (its letters' foot at c.y), running along
## `right`, `h` tall, facing right × up. One face; call again turned round for the back.
func _wx_word(text: String, c: Vector3, right: Vector3, h: float, col: Color, mode := M_LAMP) -> void:
	var sx := h / 7.0
	var width := 0.0
	for ch in text:
		width += (_pow_glyph_w(ch) + 1) * sx
	width -= sx
	var n := right.cross(Vector3.UP).normalized()
	var keep := _mode
	_mode = mode
	var at := -width * 0.5
	for ch in text:
		if ch == " ":
			at += (_pow_glyph_w(ch) + 1) * sx
			continue
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		for q: Vector2i in lit:
			if lit.has(q - Vector2i(1, 0)):
				continue
			var e := q
			while lit.has(e + Vector2i(1, 0)):
				e += Vector2i(1, 0)
			var row := PixelFont.BODY + 6 - q.y
			var x0 := at + q.x * sx
			var x1 := at + (e.x + 1) * sx
			var y0 := c.y + row * sx
			var y1 := y0 + sx
			var p0 := c + right * x0 + n * 0.02
			var p1 := c + right * x1 + n * 0.02
			_quad(Vector3(p0.x, y0, p0.z), Vector3(p1.x, y0, p1.z), Vector3(p1.x, y1, p1.z), Vector3(p0.x, y1, p0.z), n, col)
		at += (_pow_glyph_w(ch) + 1) * sx
	_mode = keep


# --- the shooting stars on the masts -----------------------------------------------------------

## One shooting star hung on a mast at (u, v), `side` -1 or +1 across the pasaż: the head 1.55 m out
## from the pole at 5.4 m, eight petals of white LED (a dimmer heart in each, so it reads as the
## photos' outlined petals), a gold heart ringed with warm bulbs, six white strands of tail falling
## and curling in towards the pole down to 2.6 m, two of them strung with warm bulbs.
func _wx_comet(m: Vector2, side: float) -> void:
	_wx_frame()
	var g := _wx_g(m.x, m.y)
	var across := _wx_V() * side
	var nrm := _wx_U()
	var head := _wx_p(m.x, m.y, g + 5.4) + across * 1.55
	var to2 := func(x: float, y: float) -> Vector3:
		return head + across * x + Vector3.UP * y
	# The bracket to the pole.
	_no_roof = true
	_beam(_wx_p(m.x, m.y, g + 5.9), to2.call(-0.15, 0.4), 0.05, Color("#d8d8d4"), false)
	_beam(_wx_p(m.x, m.y, g + 3.6), to2.call(-0.55, -1.8), 0.04, Color("#d8d8d4"), false)
	# The power cable down the pole's face (the mast's own hatch and plate are on the other faces).
	var cable := _wx_p(m.x, m.y, 0.0) + across * 0.235
	_beam(Vector3(cable.x, g, cable.z), Vector3(cable.x, g + 5.9, cable.z), 0.03, Color("#d0d0cc"), false)
	_no_roof = false
	for k in 8:
		var t := PI * 0.5 + TAU * float(k) / 8.0 + 0.2
		var d := Vector2(cos(t), sin(t))
		var e := Vector2(-d.y, d.x)
		var r1 := 1.05 if k % 2 == 0 else 0.82
		# Neighbouring petals overlap at the hub, so every other one sits 5 cm forward (no flicker).
		var lift := nrm * (0.0 if k % 2 == 0 else 0.05)
		var kite := func(s: float) -> Array:
			return [to2.call(d.x * 0.24, d.y * 0.24), to2.call(d.x * 0.6 * s + e.x * 0.2 * s, d.y * 0.6 * s + e.y * 0.2 * s),
					to2.call(d.x * r1 * s, d.y * r1 * s), to2.call(d.x * 0.6 * s - e.x * 0.2 * s, d.y * 0.6 * s - e.y * 0.2 * s)]
		var outer: Array = kite.call(1.0)
		for q in outer.size():
			outer[q] = outer[q] + lift
		_wx_flat(outer, nrm, WX_LED)
		var inner: Array = kite.call(0.82)
		for q in inner.size():
			inner[q] = inner[q] + lift + nrm * 0.025
		_wx_flat(inner, nrm, WX_LED_DIM)
	var disc: Array = []
	for k in 10:
		var t := TAU * float(k) / 10.0
		disc.append(to2.call(cos(t) * 0.27, sin(t) * 0.27) + nrm * 0.12)
	_wx_flat(disc, nrm, WX_GOLD)
	for k in 8:
		var t := TAU * (float(k) + 0.5) / 8.0
		_wx_bulb(to2.call(cos(t) * 0.36, sin(t) * 0.36) + nrm * 0.14, 0.1, WX_WARM)
	# The tail: quadratic curves from under the head, down and in towards the pole, just behind the
	# petals, every other strand 4 cm further back.
	for j in 6:
		var f := float(j) - 2.5
		var back := nrm * (-0.075 if j % 2 == 0 else -0.115)
		var p0 := Vector2(0.06 * f, -0.3)
		var p1 := Vector2(0.45 + 0.1 * f, -1.35)
		var p2 := Vector2(-0.55 + 0.2 * f, -2.8 + 0.12 * absf(f))
		var pts: Array = []
		for k in 6:
			var t := float(k) / 5.0
			var q := p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t
			pts.append(to2.call(q.x, q.y) + back)
		_wx_tube(pts, 0.06, WX_LED)
		if j == 1 or j == 4:
			for k in range(1, 6):
				var t := (float(k) - 0.5) / 5.0
				var q := p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t
				_wx_bulb(to2.call(q.x, q.y) + back, 0.11, WX_WARM)


# --- the WARSIK SAWKA JUNIOREK photo frame -----------------------------------------------------

## The photo frame (F's photo 8429 and the Instagram frame): a 3.4 m wide, 4.1 m tall board across the
## pasaż on two bronze feet, a starry navy panel with the three stores' names in white LED, a purple
## glitter band at its foot, WESOŁYCH ŚWIĄT in red and green on its top edge and a wobbly rainbow
## neon border; both faces dressed.
func _wx_photo_frame(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var hw := 1.7
	for s: float in [-1.0, 1.0]:
		_ubox(at.x - 0.45, at.x + 0.45, at.y + s * hw - 0.35, at.y + s * hw + 0.35, g, g + 0.32, WX_BRONZE)
		_ubox(at.x - 0.04, at.x + 0.04, at.y + s * (hw + 0.1) - 0.04, at.y + s * (hw + 0.1) + 0.04, g + 0.32, g + 4.1, WX_METAL)
	# The board: navy panel, purple foot band (both lit, so the glitter shows at night).
	_ubox(at.x - 0.05, at.x + 0.05, at.y - hw, at.y + hw, g + 0.55, g + 1.35, WX_PURPLE.darkened(0.15), M_LAMP)
	_ubox(at.x - 0.05, at.x + 0.05, at.y - hw, at.y + hw, g + 1.35, g + 4.0, WX_NAVY, M_LAMP)
	# The greeting's own strip on top, so its two faces' words hide each other from above.
	_ubox(at.x - 0.05, at.x + 0.05, at.y - 1.55, at.y + 1.55, g + 4.1, g + 4.45, WX_NAVY, M_LAMP)
	var rng := RandomNumberGenerator.new()
	rng.seed = 829
	var U := _wx_U()
	var V := _wx_V()
	for face: float in [-1.0, 1.0]:
		var n := U * face
		var right := V * -face
		var c := _wx_p(at.x, at.y, 0.0) + n * 0.08
		_wx_word("WARSIK", Vector3(c.x, g + 3.1, c.z), right, 0.44, WX_LED)
		_wx_word("SAWKA", Vector3(c.x, g + 2.5, c.z), right, 0.44, WX_LED)
		_wx_word("JUNIOREK", Vector3(c.x, g + 1.9, c.z), right, 0.42, WX_LED)
		_wx_word("WESOŁYCH", Vector3(c.x, g + 4.15, c.z) - right * 0.75, right, 0.22, Color(1.0, 0.2, 0.25))
		_wx_word("ŚWIĄT", Vector3(c.x, g + 4.15, c.z) + right * 0.85, right, 0.22, Color(0.2, 1.0, 0.35))
		# The stars on the navy and the glitter in the purple.
		for k in 22:
			var p := c + n * 0.01 + right * rng.randf_range(-1.55, 1.55)
			var y := rng.randf_range(1.42, 1.85) if k < 8 else rng.randf_range(1.42, 3.9)
			_wx_bulb(Vector3(p.x, g + y, p.z), 0.05, WX_LED)
		for k in 16:
			var p := c + n * 0.01 + right * rng.randf_range(-1.6, 1.6)
			_wx_bulb(Vector3(p.x, g + rng.randf_range(0.6, 1.3), p.z), 0.06, Color(0.85, 0.5, 1.0))
	# The rainbow border: a tube round the board's edge, wobbling in and out as the photos' scrolls.
	var ring: Array = []
	var corners := [Vector2(-hw, 0.55), Vector2(hw, 0.55), Vector2(hw, 4.05), Vector2(-hw, 4.05)]
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		for j in 8:
			var t := float(j) / 8.0
			var q := a.lerp(b, t)
			var wob := 0.09 * sin(t * TAU * 2.0 + k)
			var inward := (Vector2.ZERO - q).normalized() * wob
			ring.append(q + inward)
	ring.append(ring[0])
	for k in range(1, ring.size()):
		var q0: Vector2 = ring[k - 1]
		var q1: Vector2 = ring[k]
		var col: Color = WX_RAINBOW[(k / 3) % WX_RAINBOW.size()]
		_wx_tube([_wx_p(at.x, at.y + q0.x, g + q0.y), _wx_p(at.x, at.y + q1.x, g + q1.y)], 0.16, col)
	_collide(_rect(at.x, at.y, 0.45, hw + 0.35))


# --- the gingerbread tunnel ----------------------------------------------------------------------

## The outline's right half, top of the head to the foot's inner curl (metres, from the photos' blue
## layer: 5 m tall, 4.3 m across the hands). The left half is its mirror.
const WX_GINGER_HALF := [Vector2(0.0, 4.98), Vector2(0.55, 4.88), Vector2(0.92, 4.6), Vector2(0.99, 4.3),
		Vector2(0.9, 3.85), Vector2(0.86, 3.66), Vector2(1.15, 3.62), Vector2(1.6, 3.6), Vector2(2.0, 3.48),
		Vector2(2.13, 3.22), Vector2(1.95, 2.95), Vector2(1.55, 2.86), Vector2(1.25, 2.72), Vector2(1.33, 2.35),
		Vector2(1.45, 2.0), Vector2(1.6, 1.4), Vector2(1.74, 0.8), Vector2(1.8, 0.35), Vector2(1.62, 0.08),
		Vector2(1.3, 0.04), Vector2(1.05, 0.15), Vector2(0.95, 0.42)]
const WX_GINGER_SCALE := [1.1, 1.0, 0.9, 0.81, 0.73]


## The gingerbread man you walk through (F's photo 8425, the Instagram frames): five neon outlines
## 0.7 m apart along the pasaż, blue in front (south) shrinking to red at the back, each a coloured
## tube on a dark channel, standing on two grated rails.
func _wx_gingerbread(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var curve: Array = []
	for k in range(WX_GINGER_HALF.size() - 1, 0, -1):
		var q: Vector2 = WX_GINGER_HALF[k]
		curve.append(Vector2(-q.x, q.y))
	for q: Vector2 in WX_GINGER_HALF:
		curve.append(q)
	var smooth := _wx_smooth(curve, 2)
	var V := _wx_V()
	var U := _wx_U()
	for layer in WX_GINGER_SCALE.size():
		var s: float = WX_GINGER_SCALE[layer]
		var u := at.x - 1.4 + 0.7 * layer
		var tube: Array = []
		var chan: Array = []
		for q: Vector2 in smooth:
			var p := _wx_p(u, at.y, g + 0.2 + q.y * s) + V * (q.x * s)
			tube.append(p)
			chan.append(p + U * 0.1 - Vector3.UP * 0.02)
		_wx_tube(chan, 0.1, Color("#2a3040"), M_STONE)
		_wx_tube(tube, 0.13, WX_GINGER[layer])
	for side: float in [-1.0, 1.0]:
		var v0 := at.y + side * 0.75
		var v1 := at.y + side * 1.65
		_ubox(at.x - 1.9, at.x + 1.9, minf(v0, v1), maxf(v0, v1), g, g + 0.15, Color("#3e4658"), M_STONE, Color("#6a7488"))
		_collide(_urect(at.x - 1.9, at.x + 1.9, minf(v0, v1), maxf(v0, v1)))


# --- the blue tinsel frame ----------------------------------------------------------------------

## The blue photo frame by the cafés (F's photo 8433): a 2.6 m by 3 m board across the pasaż on gold
## feet, a deep blue tinsel field in a silvery lavender border, warm bulbs round it.
func _wx_tinsel(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var hw := 1.3
	for s: float in [-1.0, 1.0]:
		_ubox(at.x - 0.4, at.x + 0.4, at.y + s * hw - 0.3, at.y + s * hw + 0.3, g, g + 0.22, WX_GOLD.darkened(0.35))
	_ubox(at.x - 0.12, at.x + 0.12, at.y - hw, at.y + hw, g + 0.3, g + 3.3, Color(0.5, 0.47, 0.7), M_LAMP)
	_ubox(at.x - 0.14, at.x + 0.14, at.y - hw + 0.45, at.y + hw - 0.45, g + 0.75, g + 2.85, Color(0.06, 0.16, 0.75), M_LAMP)
	var rim := [Vector2(-hw, 0.3), Vector2(hw, 0.3), Vector2(hw, 3.3), Vector2(-hw, 3.3)]
	for k in 4:
		var a: Vector2 = rim[k]
		var b: Vector2 = rim[(k + 1) % 4]
		var n := ceili(a.distance_to(b) / 0.35)
		for j in n:
			var q := a.lerp(b, float(j) / n)
			for face: float in [-1.0, 1.0]:
				_wx_bulb(_wx_p(at.x + face * 0.15, at.y + q.x, g + q.y), 0.08, WX_WARM)
	_collide(_rect(at.x, at.y, 0.4, hw + 0.3))


# --- the neon fir, the baubles, the bench --------------------------------------------------------

## A neon fir's half profile, (r out from the axis, y): the zig-zag edge from the tip down.
const WX_FIR := [Vector2(0.0, 5.6), Vector2(0.95, 4.2), Vector2(0.55, 4.2), Vector2(1.45, 2.7), Vector2(0.95, 2.7),
		Vector2(2.0, 0.95), Vector2(1.3, 0.95), Vector2(1.3, 0.3), Vector2(0.0, 0.3)]
## The red tube's line, 11 to 17 cm inside the yellow edge all round (so the two never touch).
const WX_FIR_IN := [Vector2(0.1, 5.25), Vector2(0.72, 4.34), Vector2(0.32, 4.34), Vector2(1.18, 2.86),
		Vector2(0.68, 2.86), Vector2(1.72, 1.09), Vector2(1.16, 1.09), Vector2(1.16, 0.44)]


## The big neon fir by Wars (F's photos 8434 and 8435, the Instagram frames): four crossed fins, each
## edged in a yellow tube with a red one just inside, a pale film between (dim teal and pink) and a
## dark round base ringed in red.
func _wx_neon_fir(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var c := _w(at.x, at.y)
	_prism(_circle(c, 2.15, 16), g, g + 0.14, Color("#3a2a2a"), Color("#6a2a26"), M_STONE, M_STONE)
	var base := _circle(c, 2.0, 16)
	var ring: Array = []
	for q in base:
		ring.append(Vector3(q.x, g + 0.18, q.y))
	ring.append(ring[0])
	_wx_tube(ring, 0.06, Color(1.0, 0.25, 0.15))
	for k in 8:
		var t := TAU * float(k) / 8.0 + 0.3
		var out := Vector3(cos(t), 0.0, sin(t))
		var nrm := Vector3(-out.z, 0.0, out.x)
		var edge: Array = []
		var inner: Array = []
		for q: Vector2 in WX_FIR:
			edge.append(Vector3(c.x, g + q.y, c.y) + out * q.x)
		# The tubes start 10 cm off the axis (opposite fins share a plane).
		for q: Vector2 in WX_FIR_IN:
			inner.append(Vector3(c.x, g + q.y, c.y) + out * q.x)
		var tip := Vector3(c.x, g + 5.5, c.y) + out * 0.1
		_wx_tube([tip] + edge.slice(1, edge.size() - 1), 0.08, Color(1.0, 0.78, 0.12))
		_wx_tube(inner, 0.07, Color(1.0, 0.3, 0.12))
		var film := Color(0.14, 0.32, 0.3) if k % 2 == 0 else Color(0.34, 0.16, 0.26)
		_wx_flat([edge[0], edge[1], edge[2], edge[8]], nrm, film)
		_wx_flat([edge[2], edge[3], edge[4], edge[8]], nrm, film)
		_wx_flat([edge[4], edge[5], edge[6], edge[7], edge[8]], nrm, film)
	_collide(_circle(c, 2.1, 8))


## A park bench of dark slats on two black frames, its long side along `along` (radians from +u).
func _wx_bench(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	_ubox(at.x - 1.2, at.x + 1.2, at.y - 0.25, at.y + 0.25, g + 0.42, g + 0.5, Color("#5a4632"))
	for s: float in [-0.95, 0.95]:
		_ubox(at.x + s - 0.04, at.x + s + 0.04, at.y - 0.25, at.y + 0.25, g, g + 0.42, Color("#1e1f22"))


## The orange wire bauble (photo 8434): a 2.1 m ball of orange light on a round foot, darker ribs,
## its cap and hanging loop on top.
func _wx_wire_ball(at: Vector2) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var c := _w(at.x, at.y)
	_prism(_circle(c, 0.75, 12), g, g + 0.08, WX_ORANGE.darkened(0.3), WX_ORANGE.darkened(0.2), M_STONE, M_STONE)
	_prism(_circle(c, 0.12, 6), g + 0.08, g + 0.45, WX_ORANGE.darkened(0.3), Color(0, 0, 0, 0), M_STONE)
	var r := 1.0
	var cy := g + 0.45 + r
	var keep := _mode
	_mode = M_LAMP
	for k in 6:
		var a0 := PI * float(k) / 6.0
		var a1 := PI * float(k + 1) / 6.0
		var y0 := cy - r * cos(a0)
		var y1 := cy - r * cos(a1)
		var r0 := maxf(r * sin(a0), 0.02)
		var r1 := maxf(r * sin(a1), 0.02)
		_frustum(_circle(c, r0, 10), y0, _circle(c, r1, 10), y1, WX_ORANGE if k % 2 == 0 else WX_ORANGE.lightened(0.1))
	_mode = keep
	for k in 6:
		var t := TAU * float(k) / 6.0
		var pts: Array = []
		for j in 9:
			var a := PI * float(j) / 8.0
			pts.append(Vector3(c.x, cy - r * 1.02 * cos(a), c.y) + Vector3(cos(t), 0.0, sin(t)) * r * 1.02 * sin(a))
		_wx_tube(pts, 0.05, Color(1.0, 0.7, 0.35))
	_prism(_circle(c, 0.2, 8), cy + r - 0.05, cy + r + 0.22, WX_ORANGE.darkened(0.2), WX_ORANGE, M_LAMP, M_LAMP)
	var loop: Array = []
	for k in 9:
		var t := PI * float(k) / 8.0
		loop.append(_wx_p(at.x + cos(t) * 0.2, at.y, cy + r + 0.22 + sin(t) * 0.25))
	_wx_tube(loop, 0.05, WX_ORANGE)
	_collide(_circle(c, 0.8, 8))


## A bauble opened on one side (the purple and gold benches of photos 8429 and 8432; with `seat`
## false the small gold one children stand in, photo 8434): the back part of a ball of radius r in
## swirled stripes of `col_a` and `col_b`, a gold rim round the opening, the opening looking `look`
## (radians from +u) and tipped `tilt` up; on a dark grated platform, a bench inside.
func _wx_bauble(at: Vector2, r: float, look: float, tilt: float, col_a: Color, col_b: Color, seat: bool) -> void:
	_wx_frame()
	var g := _wx_g(at.x, at.y)
	var U := _wx_U()
	var V := _wx_V()
	var flat := (U * cos(look) + V * sin(look)).normalized()
	var fwd := (flat * cos(tilt) + Vector3.UP * sin(tilt)).normalized()
	var e1 := fwd.cross(Vector3.UP).normalized()
	var e2 := e1.cross(fwd).normalized()
	var base := _wx_p(at.x, at.y, g)
	var c := base + Vector3.UP * (r * 0.86 + 0.18)
	if seat:
		var plan := Vector2(flat.x, flat.z)
		_pow_box(Vector2(base.x, base.z) + plan * 0.2, plan, r * 0.95, r * 0.8, g, g + 0.16, WX_BRONZE.darkened(0.2), WX_BRONZE)
	var cut := PI * (0.6 if seat else 0.55)
	var rings := 6
	var segs := 16
	var keep := _mode
	_mode = M_LAMP
	var pt := func(th: float, ph: float) -> Vector3:
		return c + (-fwd * cos(th) + (e1 * cos(ph) + e2 * sin(ph)) * sin(th)) * r
	for i in rings:
		var th0 := cut * float(i) / rings
		var th1 := cut * float(i + 1) / rings
		for j in segs:
			var ph0 := TAU * float(j) / segs
			var ph1 := TAU * float(j + 1) / segs
			var stripe := posmod(j + i, 4) < 2
			var col := col_a if stripe else col_b
			var p00: Vector3 = pt.call(th0, ph0)
			var p01: Vector3 = pt.call(th0, ph1)
			var p11: Vector3 = pt.call(th1, ph1)
			var p10: Vector3 = pt.call(th1, ph0)
			var n := (p00 + p11) * 0.5 - c
			n = n.normalized()
			if i > 0:  # the pole's ring is a fan: its first triangle would have no area
				_tri(p00, p01, p11, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
				_tri(p00, p11, p01, -n, col.darkened(0.15), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
			_tri(p00, p11, p10, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
			_tri(p00, p10, p11, -n, col.darkened(0.15), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep
	# The rim: a dark band and a warm tube of bulbs on it.
	var rim: Array = []
	var dark: Array = []
	for j in segs + 1:
		var ph := TAU * float(j) / segs
		rim.append(pt.call(cut, ph) + fwd * 0.16)
		dark.append(pt.call(cut, ph) - fwd * 0.02)
	_wx_tube(dark, 0.2, Color("#2c2418"), M_STONE)
	_wx_tube(rim, 0.08, WX_WARM)
	if seat:
		var sc := c - fwd * (r * 0.25) - Vector3.UP * (r * 0.42)
		var sp := Vector2(sc.x, sc.z)
		var side := Vector2(e1.x, e1.z)
		_pow_box(sp, side.normalized(), r * 0.55, 0.22, sc.y - 0.04, sc.y + 0.04, WX_GOLD.darkened(0.3), WX_GOLD)
		var back := sc - flat * 0.25 + Vector3.UP * 0.25
		_wx_tube([back + e1 * r * 0.55, back - e1 * r * 0.55], 0.05, WX_GOLD.darkened(0.2), M_STONE)
		_collide(_circle(Vector2(base.x, base.z), r * 0.95, 8))
	else:
		_prism(_circle(Vector2(base.x, base.z), 0.7, 10), g, g + 0.1, col_b, col_a.darkened(0.2), M_STONE, M_STONE)


## A curtain of white LED strands on the stores' back glass from u0 to u1 (v the glass), 0.4 to 4.6 m
## up (photos 8433 and 8425): a faint glow behind, a strand every 0.22 m.
func _wx_curtain(u0: float, u1: float, v: float) -> void:
	_wx_frame()
	var g := _wx_g((u0 + u1) * 0.5, v)
	var n := _wx_V()
	var keep := _mode
	_mode = M_LAMP
	var a := _wx_p(u0, v + 0.12, 0.0)
	var b := _wx_p(u1, v + 0.12, 0.0)
	_quad(Vector3(a.x, g + 0.1, a.z), Vector3(b.x, g + 0.1, b.z), Vector3(b.x, g + 4.6, b.z), Vector3(a.x, g + 4.6, a.z), n,
			Color(0.36, 0.42, 0.55))
	var k := 0
	var u := u0 + 0.11
	while u < u1:
		var p := _wx_p(u, v + 0.18, 0.0)
		var e := _wx_U() * 0.025
		var top := 4.6 - 0.25 * absf(sin(float(k) * 1.7))
		_quad(Vector3(p.x - e.x, g + 0.45, p.z - e.z), Vector3(p.x + e.x, g + 0.45, p.z + e.z),
				Vector3(p.x + e.x, g + top, p.z + e.z), Vector3(p.x - e.x, g + top, p.z - e.z), n, WX_LED)
		u += 0.22
		k += 1
	_mode = keep


## A flat zig-zag fir of yellow neon on the glass at (u, v), 4.4 m tall, facing the pasaż.
func _wx_flat_fir(u: float, v: float) -> void:
	_wx_frame()
	var g := _wx_g(u, v)
	var pts: Array = []
	for k in range(WX_FIR.size() - 2, -1, -1):
		var q: Vector2 = WX_FIR[k]
		pts.append(_wx_p(u - q.x * 0.82, v + 0.2, g + q.y * 0.8 - 0.12))
	for k in range(1, WX_FIR.size() - 1):
		var q: Vector2 = WX_FIR[k]
		pts.append(_wx_p(u + q.x * 0.82, v + 0.2, g + q.y * 0.8 - 0.12))
	_wx_tube(pts, 0.08, Color(1.0, 0.85, 0.15))


## The neon shapes on posts further south (photo 8435's background): a pink heart, a green and
## yellow candy cane, a purple bauble ring; each 2.4 m tall, seen from both ends of the pasaż.
func _wx_shape(kind: String, u: float, v: float) -> void:
	_wx_frame()
	var g := _wx_g(u, v)
	_ubox(u - 0.05, u + 0.05, v - 0.05, v + 0.05, g, g + 0.6, WX_METAL)
	_ubox(u - 0.3, u + 0.3, v - 0.3, v + 0.3, g, g + 0.1, WX_METAL)
	var pts: Array = []
	match kind:
		"heart":
			for k in 25:
				var t := TAU * float(k) / 24.0
				var x := 16.0 * pow(sin(t), 3)
				var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				pts.append(_wx_p(u, v + x * 0.06, g + 1.5 + y * 0.06))
			_wx_tube(pts, 0.09, Color(1.0, 0.25, 0.65))
		"cane":
			var cane: Array = []
			for k in 6:
				cane.append(Vector2(0.0, 0.6 + 0.3 * k))
			for k in range(1, 8):
				var t := PI * float(k) / 7.0
				cane.append(Vector2(0.45 - 0.45 * cos(t), 2.1 + 0.45 * sin(t)))
			for k in range(1, cane.size()):
				var q0: Vector2 = cane[k - 1]
				var q1: Vector2 = cane[k]
				var col := Color(0.3, 1.0, 0.3) if k % 2 == 0 else Color(1.0, 0.9, 0.2)
				_wx_tube([_wx_p(u, v + q0.x, g + q0.y), _wx_p(u, v + q1.x, g + q1.y)], 0.12, col)
		_:
			for k in 21:
				var t := TAU * float(k) / 20.0
				pts.append(_wx_p(u, v + cos(t) * 0.9, g + 1.55 + sin(t) * 0.9))
			_wx_tube(pts, 0.09, Color(0.75, 0.3, 1.0))
			_wx_tube([_wx_p(u, v - 0.2, g + 2.45), _wx_p(u, v + 0.2, g + 2.45), _wx_p(u, v + 0.2, g + 2.7),
					_wx_p(u, v - 0.2, g + 2.7), _wx_p(u, v - 0.2, g + 2.45)], 0.07, WX_GOLD)


# --- people -------------------------------------------------------------------------------------

## Where the pasaż's standing people are (crowds.gd, kind `wiecha`): [plan point, the way they face].
## A few at each decoration taking a photo or posing in it, a pair at each café front, someone on
## each bauble bench; scattered, never a crowd (F: "not overdone"). Deterministic, so both city
## paths and every run agree.
static func wiecha_plan() -> Array:
	var out: Array = []
	var a := FirstScene.FRAME_S.normalized()
	var b := Vector2(-a.y, a.x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2212
	# [u, v, how many, how far they stand, the side they stand on (radians from +u)].
	var spots := [[WX_FRAME_AT.x, WX_FRAME_AT.y, 3, 2.6, 0.0], [WX_FRAME_AT.x, WX_FRAME_AT.y, 2, 2.4, PI],
			[WX_GINGER_AT.x, WX_GINGER_AT.y, 3, 3.4, PI], [WX_GINGER_AT.x, WX_GINGER_AT.y, 2, 3.2, 0.0],
			[WX_TINSEL_AT.x, WX_TINSEL_AT.y, 2, 2.3, PI], [WX_TREE_AT.x, WX_TREE_AT.y, 3, 3.3, 0.4],
			[WX_ORANGE_AT.x, WX_ORANGE_AT.y, 2, 1.8, 1.4], [WX_HALF_AT.x, WX_HALF_AT.y, 2, 1.6, 1.6],
			[WX_BAUBLES[0][0], WX_BAUBLES[0][1], 3, 3.0, WX_BAUBLES[0][2]],
			[WX_BAUBLES[1][0], WX_BAUBLES[1][1], 2, 2.9, WX_BAUBLES[1][2]]]
	for s: Array in spots:
		var c := _wx_world(s[0], s[1])
		for k in int(s[2]):
			var t := float(s[4]) + rng.randf_range(-0.6, 0.6)
			var d := a * cos(t) + b * sin(t)
			var p := c + d * (float(s[3]) + rng.randf_range(0.0, 1.2))
			out.append([p, -d.rotated(rng.randf_range(-0.3, 0.3))])
	# The café fronts of Złota 11 and the terraces: in twos, talking or reading the menu.
	for u: float in [-31.0, -21.0, -12.0, -1.0, 8.0, 20.0, 92.0, 110.0, -50.0, -140.0]:
		var v := 75.6 if u > -40.0 and u < 40.0 else (71.0 if u > 80.0 else (88.0 if u > -60.0 else 72.5))
		var p := _wx_world(u + rng.randf_range(-1.0, 1.0), v - rng.randf_range(0.4, 1.2))
		var t := rng.randf() * TAU
		var d := Vector2(cos(t), sin(t))
		out.append([p, d])
		if rng.randf() < 0.7:
			out.append([p + d * 0.8, -d])
	return out
