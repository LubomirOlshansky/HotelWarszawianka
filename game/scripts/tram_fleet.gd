extends RefCounted
## The city's tram fleet (F, 2026-11-06, "new and old", from F's six photos): beside today's
## yellow five-section tram (models.gd tram_mesh, kind CLASSIC) the trams on the tracks now come in
## three more looks, our own shapes with no maker's or operator's name:
##
## - **SMILE** ("Uśmiech", the newest): a bidirectional low-floor tram, three bodies of trams.gd
##   CAR m (about 33 m in all, like the real ones) read as five sections (two dark joints painted
##   on the middle body). A yellow body under a red roof with a thin yellow line between them, big
##   dark windows and all-glass doors on both sides, and the face: a black glass mask wrapping the
##   rounded nose, its windscreen with the lit destination line on top, a yellow chin with a black
##   smile line and lamps at its corners, two camera arms in place of mirrors. The rear body is
##   the same cab turned round, with tail lamps.
## - **PAIR** (the old boxy high-floor pair, "akwarium" for its big windows): two coupled single-ended cars of PAIR_CAR
##   m (27 m in all), yellow over a red skirt, tall windows with a top light, four folding doors on
##   the right only, the round red "t" on the sides, a flat face with a three-piece windscreen,
##   the dark route box with its lit line, round lamps, a yellow box on the roof and a diamond
##   pantograph on each car.
## - **PAIR_NEW** (the same pair rebuilt): one big framed windscreen with the route number in its
##   corner, a raised yellow hood over the cab, a black lower nose and square lamps.
##
## Every car is one surface on the one actor material, like the other trams (models.gd): a PAIR
## draws two car meshes where a SMILE or CLASSIC draws three (-1 draw call in view, never more).

const Models := preload("res://scripts/models.gd")
const OldTram := preload("res://scripts/old_tram.gd")

enum Kind { CLASSIC, SMILE, PAIR, PAIR_NEW }

## The old pair's car length (m) and its coupler gap.
const PAIR_CAR := 13.5
const PAIR_JOINT := 0.9

const YELLOW := Color("#f2bf1a")
const RED := Color("#c8262b")
const MASK := Color("#141619")
const DOOR_FRAME := Color("#2a2d33")
const ROOF_GREY := Color("#8d8a84")
const ROUTE := Color("#d9e24f")
const DEST := Color("#f0c674")
## The newest tram's face: its chin's top and how far back the top of its nose leans.
const CHIN := 1.0
const RAKE := 0.45

static var _made := {}


## The meshes of kind `kind`, front car first (made once; the same objects every call).
static func meshes(kind: Kind) -> Array:
	if not _made.has(kind):
		match kind:
			Kind.SMILE:
				_made[kind] = [smile_mesh(0), smile_mesh(1), smile_mesh(2)]
			Kind.PAIR:
				_made[kind] = [pair_mesh(false, true), pair_mesh(false, false)]
			Kind.PAIR_NEW:
				_made[kind] = [pair_mesh(true, true), pair_mesh(true, false)]
			_:
				_made[kind] = [Models.tram_mesh(true), Models.tram_mesh(false), Models.tram_mesh(true, true)]
	return _made[kind]


## The parody name of a kind, for the logs and the checks.
static func label(kind: Kind) -> String:
	return ["ŻÓŁTY", "UŚMIECH", "AKWARIUM", "AKWARIUM NOWE"][kind]


# --- the newest tram ----------------------------------------------------------------------------

## One body of the newest tram, CAR (10.5) m by 2.4 m, its front at -Z. `part` 0 is the front cab
## (head lamps), 1 the middle body (the pantograph, two painted joints), 2 the rear cab (the trams
## turn it round; tail lamps).
static func smile_mesh(part: int) -> ArrayMesh:
	var s := Models.Shape.new()
	var cab := part != 1
	var yellow := Models.fin(YELLOW)
	var red := Models.fin(RED)
	var mask := Models.fin(MASK)
	var dark := Models.fin(Color("#1c1c1e"))
	var glass := Models.fin(Models.GLASS, Models.LIT_WINDOW)
	var W := 1.2
	var hl := 5.25
	var rf := 1.05 if cab else 0.12
	var rb := 0.12
	var n := 8
	var ol := OldTram._outline(W, hl, rf, rb, n)
	OldTram._band(s, OldTram._inset(ol, 0.07), ol, 0.28, 0.42, dark)
	# A cab's face leans back above its chin (CHIN m up): the top of the nose is RAKE m further back.
	var top := ol
	if cab:
		top = ol.duplicate()
		for i in range(1, n + 2):
			top[i].y += RAKE
	OldTram._band(s, ol, ol, 0.42, CHIN, yellow)
	OldTram._band(s, ol, top, CHIN, 3.0, yellow)
	OldTram._band(s, top, top, 3.0, 3.06, yellow)
	var r1 := OldTram._inset(top, 0.12)
	var r2 := OldTram._inset(top, 0.34)
	OldTram._band(s, top, r1, 3.06, 3.3, red)
	OldTram._band(s, r1, r2, 3.3, 3.38, red)
	OldTram._cap(s, r2, 3.38, red)
	# Sides: all-glass doors on both (bidirectional) and big windows between, thin yellow pillars.
	var z0 := -hl + rf + 0.12
	var z1 := hl - rb - 0.15
	var doors: Array = [-hl + rf + 0.95, 2.35] if cab else [-3.45, 3.45]
	var joints: Array = [] if cab else [-1.75, 1.75]
	if part == 2:
		doors = [-hl + rf + 0.95, 2.35]
	for sgn: float in [-1.0, 1.0]:
		var x := sgn * (W + 0.012)
		var cuts: Array = []
		for dz: float in doors:
			cuts.append(Vector3(dz - 0.68, dz + 0.68, 0.0))
			s.side_rect(x, sgn, 0.4, 2.9, dz - 0.66, dz + 0.66, Models.fin(DOOR_FRAME))
			for half: float in [-1.0, 1.0]:
				var zc := dz + half * 0.31
				s.side_rect(x + sgn * 0.006, sgn, 0.55, 2.8, zc - 0.27, zc + 0.27, glass)
		for jz: float in joints:
			cuts.append(Vector3(jz - 0.16, jz + 0.16, 1.0))
			s.side_rect(x + sgn * 0.004, sgn, 0.3, 3.3, jz - 0.13, jz + 0.13, dark)
		cuts.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)
		var from := z0
		for c: Vector3 in cuts:
			_windows(s, x, sgn, from, c.x, 1.08, 2.82, 1.45, glass)
			from = c.y
		_windows(s, x, sgn, from, z1, 1.08, 2.82, 1.45, glass)
	if cab:
		_smile_face(s, ol, top, n, part == 2, mask)
		# The camera arms where mirrors were, at the nose's shoulders.
		for sgn: float in [-1.0, 1.0]:
			s.box(Vector3(sgn * 1.27, 2.86, -hl + rf + 0.1), Vector3(0.16, 0.05, 0.05), mask)
			s.box(Vector3(sgn * 1.36, 2.72, -hl + rf + 0.1), Vector3(0.07, 0.3, 0.12), mask)
		# The air-conditioning box on the roof.
		s.box(Vector3(0.0, 3.52, 1.0), Vector3(1.5, 0.3, 2.6), Models.fin(Color("#9b9890")))
	else:
		# The roof's dark joint lines and the single-arm pantograph on its base.
		for jz: float in joints:
			s.box(Vector3(0.0, 3.36, jz), Vector3(2.0, 0.06, 0.26), dark)
		s.box(Vector3(0.0, 3.46, 0.0), Vector3(1.3, 0.16, 1.6), Models.fin(Color("#9b9890")))
		OldTram._strut(s, Vector3(0.0, 3.56, 0.6), Vector3(0.0, 4.05, -0.45), 0.07, dark)
		OldTram._strut(s, Vector3(0.0, 4.05, -0.45), Vector3(0.0, 4.5, 0.25), 0.05, dark)
		s.box(Vector3(0.0, 4.52, 0.25), Vector3(1.4, 0.05, 0.12), dark)
	# Gangway bellows at the joint ends (the next body is JOINT m back).
	s.box(Vector3(0.0, 1.75, hl + 0.17), Vector3(2.0, 2.8, 0.34), dark)
	if not cab:
		s.box(Vector3(0.0, 1.75, -hl - 0.17), Vector3(2.0, 2.8, 0.34), dark)
	# The bogies under the skirt.
	for z: float in ([-1.6] if cab else [0.0]):
		s.box(Vector3(0.0, 0.2, z), Vector3(2.0, 0.34, 2.0), dark)
	return s.mesh()


## The newest tram's face on the front curve of `ol` (n pieces; `top` the curve at the roof, the
## face leaning back above CHIN): the black glass mask wrapping the nose, the windscreen, the lit
## destination line, the yellow chin's smile rising to the mask at the corners, and its lamps.
static func _smile_face(s: Models.Shape, ol: PackedVector2Array, top: PackedVector2Array, n: int, rear: bool, mask: Array) -> void:
	var half := n * 0.5
	for k in n:
		var a := ol[1 + k]
		var b := ol[2 + k]
		var ta := top[1 + k]
		var tb := top[2 + k]
		var d := (k + 0.5 - half) / half
		var outer := k == 0 or k == n - 1
		if outer:
			_lift_pane(s, a, b, 0.86, CHIN, mask, 0.0, 0.0)
		_rake_pane(s, a, b, ta, tb, CHIN if outer else 1.08, 3.02, mask, 0.0, 0.0)
		if not outer:
			_rake_pane(s, a, b, ta, tb, 1.16, 2.95, Models.fin(Color("#26323f"), Models.LIT_WINDOW), 0.0, 0.03)
			if k >= 2 and k <= n - 3:
				_rake_pane(s, a, b, ta, tb, 2.72, 2.9, Models.fin(DEST, Models.LIT_SIGN), 0.02, 0.05)
		# The smile: a black line across the chin, rising to the mask at the corners.
		var y := 0.6 + 0.3 * d * d
		_lift_pane(s, a, b, y - 0.04, y + 0.04, mask, 0.0, 0.02)
		if k == 1 or k == n - 2:
			var lamp := Models.fin(Models.TAIL, Models.TAIL_LAMP) if rear else Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP)
			_lift_pane(s, a, b, 0.76, 0.9, lamp, 0.15, 0.03)


## A pane on the leaning face from wall piece a -> b (at CHIN) to ta -> tb (at the roof, 3.0 m),
## from y0 to y1, `margin` in from each end, `lift` m off the face.
static func _rake_pane(s: Models.Shape, a: Vector2, b: Vector2, ta: Vector2, tb: Vector2, y0: float, y1: float, f: Array, margin: float, lift: float) -> void:
	var at := func(p: Vector2, tp: Vector2, y: float) -> Vector3:
		var q := p.lerp(tp, clampf((y - CHIN) / (3.0 - CHIN), 0.0, 1.0))
		return Vector3(q.x, y, q.y)
	var nrm := OldTram._normal(a, b)
	var o := Vector3(nrm.x, 0.0, nrm.y) * (0.014 + lift)
	var a0: Vector3 = at.call(a.lerp(b, margin), ta.lerp(tb, margin), y0) + o
	var b0: Vector3 = at.call(b.lerp(a, margin), tb.lerp(ta, margin), y0) + o
	var b1: Vector3 = at.call(b.lerp(a, margin), tb.lerp(ta, margin), y1) + o
	var a1: Vector3 = at.call(a.lerp(b, margin), ta.lerp(tb, margin), y1) + o
	s.quad(a0, b0, b1, a1, f, Vector3(nrm.x, 0.3, nrm.y))


## A pane on the wall piece a -> b like OldTram._seg_pane, `lift` m off the wall (layered panes).
static func _lift_pane(s: Models.Shape, a: Vector2, b: Vector2, y0: float, y1: float, f: Array, margin: float, lift: float) -> void:
	var nrm := OldTram._normal(a, b)
	var o := nrm * (0.014 + lift)
	var p := a.lerp(b, margin) + o
	var q := b.lerp(a, margin) + o
	s.quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y), Vector3(p.x, y1, p.y), f, Vector3(nrm.x, 0, nrm.y))


## Windows along a side from z a to b (y0..y1), split into panes about `step` m long.
static func _windows(s: Models.Shape, x: float, sgn: float, a: float, b: float, y0: float, y1: float, step: float, glass: Array) -> void:
	if b - a < 0.4:
		return
	var k := maxi(1, roundi((b - a) / step))
	var w := (b - a) / k
	for i in k:
		s.side_rect(x, sgn, y0, y1, a + i * w + 0.05, a + (i + 1) * w - 0.05, glass)


# --- the old pair -------------------------------------------------------------------------------

## One car of the old high-floor pair, PAIR_CAR m by 2.4 m, its front at -Z. `rebuilt`: the newer
## face (one framed windscreen, a hood, a black nose, square lamps). `lead`: the front car (lit
## head lamps); the second car, coupled behind it, shows the lit tail lamps.
static func pair_mesh(rebuilt: bool, lead: bool) -> ArrayMesh:
	var s := Models.Shape.new()
	var yellow := Models.fin(YELLOW)
	var red := Models.fin(RED)
	var dark := Models.fin(Color("#1c1c1e"))
	var frame := Models.fin(Color("#2b2c2f"))
	var roof := Models.fin(ROOF_GREY)
	var glass := Models.fin(Models.GLASS, Models.LIT_WINDOW)
	var W := 1.2
	var hl := PAIR_CAR * 0.5
	var n := 6
	var rf := 0.34 if not rebuilt else 0.5
	var rb := 0.3
	var ol := OldTram._outline(W, hl, rf, rb, n)
	OldTram._band(s, OldTram._inset(ol, 0.08), ol, 0.32, 0.5, dark)
	OldTram._band(s, ol, ol, 0.5, 0.98, red)
	OldTram._band(s, ol, ol, 0.98, 3.0, yellow)
	var r1 := OldTram._inset(ol, 0.1)
	var r2 := OldTram._inset(ol, 0.3)
	OldTram._band(s, ol, r1, 3.0, 3.12, roof)
	OldTram._band(s, r1, r2, 3.12, 3.18, roof)
	OldTram._cap(s, r2, 3.18, roof)
	# Sides: four folding doors on the right (+X) only, tall windows with a top light, the "t".
	var doors := [-hl + rf + 0.8, -1.7, 1.9, hl - rb - 0.85]
	var z0 := -hl + rf + 0.1
	var z1 := hl - rb - 0.1
	for sgn: float in [-1.0, 1.0]:
		var x := sgn * (W + 0.012)
		var from := z0
		if sgn > 0.0:
			for dz: float in doors:
				_pair_windows(s, x, sgn, from, dz - 0.66, frame, yellow, glass)
				from = dz + 0.66
				s.side_rect(x, sgn, 0.5, 2.72, dz - 0.64, dz + 0.64, frame)
				for leaf: float in [-0.31, 0.31]:
					var zc := dz + leaf
					s.side_rect(x + sgn * 0.006, sgn, 0.54, 2.68, zc - 0.28, zc + 0.28, yellow)
					s.side_rect(x + sgn * 0.012, sgn, 1.6, 2.58, zc - 0.21, zc + 0.21, glass)
					s.side_rect(x + sgn * 0.012, sgn, 0.72, 1.32, zc - 0.21, zc + 0.21, glass)
		_pair_windows(s, x, sgn, from, z1, frame, yellow, glass)
		_t_logo(s, x + sgn * 0.01, sgn, 0.0 if sgn > 0.0 else -0.4, 1.28, 0.27, red)
	# The face (front curve) and the back.
	for k in n:
		var a := ol[1 + k]
		var b := ol[2 + k]
		var ba := ol[n + 2 + k]
		var bb := ol[(n + 3 + k) % ol.size()]
		var outer := k == 0 or k == n - 1
		if not outer:
			OldTram._seg_pane(s, ba, bb, 1.56, 2.62, glass, 0.06)
			if k == 1 or k == n - 2:
				var tail := Models.fin(Models.TAIL, Models.TAIL_LAMP) if not lead else Models.fin(Models.TAIL)
				OldTram._seg_pane(s, ba, bb, 1.08, 1.22, tail, 0.3)
		if rebuilt:
			# One big framed windscreen, the route number in its corner, a black nose.
			OldTram._seg_pane(s, a, b, 1.36 if not outer else 1.5, 2.78, frame, 0.0)
			if not outer:
				_lift_pane(s, a, b, 1.42, 2.72, glass, 0.02, 0.02)
			if k == 1:
				_lift_pane(s, a, b, 2.42, 2.7, Models.fin(Color("#f4f1e6"), Models.LIT_SIGN), 0.15, 0.04)
			OldTram._seg_pane(s, a, b, 0.5, 0.96, dark, 0.0)
		else:
			# The three-piece windscreen, the dark route box with its lit line over it.
			OldTram._seg_pane(s, a, b, 1.5, 2.66, frame, 0.0)
			if not outer:
				_lift_pane(s, a, b, 1.55, 2.6, glass, 0.08, 0.02)
				_lift_pane(s, a, b, 2.72, 2.96, dark, 0.0, 0.02)
				_lift_pane(s, a, b, 2.77, 2.91, Models.fin(ROUTE, Models.LIT_SIGN), 0.05, 0.035)
		if k == 1 or k == n - 2:
			var head := Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP) if lead else Models.fin(Models.HEADLIGHT)
			_lift_pane(s, a, b, 1.1 if rebuilt else 1.12, 1.24 if rebuilt else 1.3, head, 0.3, 0.03)
	# The bumper (and the rebuilt car's sloped black skirt), the coupler at the back.
	if rebuilt:
		s.box(Vector3(0.0, 0.46, -hl - 0.06), Vector3(2.3, 0.3, 0.36), dark)
		s.box(Vector3(0.0, 3.3, -hl + 1.35), Vector3(2.2, 0.3, 2.5), yellow)
		s.box(Vector3(0.0, 3.3, -hl + 1.35), Vector3(1.6, 0.31, 0.3), dark)
	else:
		s.box(Vector3(0.0, 0.62, -hl - 0.08), Vector3(2.1, 0.16, 0.16), dark)
		s.box(Vector3(0.0, 3.3, -hl + 0.9), Vector3(1.3, 0.26, 1.1), yellow)
	s.box(Vector3(0.0, 0.62, hl + 0.2), Vector3(0.3, 0.18, 0.42), dark)
	# The diamond pantograph on each car, two roof vents, the bogies.
	var zp := -hl + 3.6
	s.box(Vector3(0.0, 3.24, zp), Vector3(1.2, 0.08, 1.1), dark)
	for xs: float in [-0.3, 0.3]:
		var p0 := Vector3(xs, 3.26, zp)
		var pf := Vector3(xs, 3.62, zp - 0.45)
		var pt := Vector3(xs, 3.98, zp)
		var pr := Vector3(xs, 3.62, zp + 0.45)
		for pair: Array in [[p0, pf], [pf, pt], [pt, pr], [pr, p0]]:
			OldTram._strut(s, pair[0], pair[1], 0.05, dark)
	s.box(Vector3(0.0, 4.01, zp), Vector3(1.3, 0.05, 0.1), dark)
	for z: float in [0.6, hl - 1.6]:
		s.box(Vector3(0.0, 3.24, z), Vector3(0.6, 0.12, 0.7), roof)
	for z: float in [-hl + 3.4, hl - 3.4]:
		s.box(Vector3(0.0, 0.24, z), Vector3(2.0, 0.4, 2.2), dark)
	return s.mesh()


## The old pair's windows along a side from z a to b: a dark frame round each, a yellow bar
## under its top light.
static func _pair_windows(s: Models.Shape, x: float, sgn: float, a: float, b: float, frame: Array, yellow: Array, glass: Array) -> void:
	if b - a < 0.5:
		return
	var k := maxi(1, roundi((b - a) / 1.25))
	var w := (b - a) / k
	for i in k:
		var p := a + i * w + 0.07
		var q := a + (i + 1) * w - 0.07
		s.side_rect(x, sgn, 1.5, 2.68, p, q, frame)
		s.side_rect(x + sgn * 0.006, sgn, 1.56, 2.62, p + 0.05, q - 0.05, glass)
		s.side_rect(x + sgn * 0.012, sgn, 2.28, 2.33, p + 0.05, q - 0.05, frame)


## The round red "t" on a side (x, facing sgn) at (zc, yc), radius r: a ring of twelve pieces,
## the letter's stem, bar and foot (to the viewer's right: -Z on the right side, +Z on the left).
static func _t_logo(s: Models.Shape, x: float, sgn: float, zc: float, yc: float, r: float, red: Array) -> void:
	var m := 12
	var t := r * 0.2
	for i in m:
		var a0 := TAU * i / m
		var a1 := TAU * (i + 1) / m
		var o0 := Vector3(x, yc + sin(a0) * r, zc + cos(a0) * r)
		var o1 := Vector3(x, yc + sin(a1) * r, zc + cos(a1) * r)
		var i0 := Vector3(x, yc + sin(a0) * (r - t), zc + cos(a0) * (r - t))
		var i1 := Vector3(x, yc + sin(a1) * (r - t), zc + cos(a1) * (r - t))
		s.quad(o0, o1, i1, i0, red, Vector3(sgn, 0, 0))
	s.side_rect(x, sgn, yc - r * 0.62, yc + r * 0.6, zc - r * 0.1, zc + r * 0.1, red)
	s.side_rect(x, sgn, yc + r * 0.1, yc + r * 0.28, zc - r * 0.42, zc + r * 0.42, red)
	var f0 := zc - sgn * r * 0.1
	var f1 := zc - sgn * r * 0.38
	s.side_rect(x, sgn, yc - r * 0.62, yc - r * 0.44, minf(f0, f1), maxf(f0, f1), red)
