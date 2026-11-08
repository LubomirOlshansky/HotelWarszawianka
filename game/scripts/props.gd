extends RefCounted
## Box-built models for the side jobs and the easter eggs (v0.65), all drawn with
## the actors' material (models.gd, actor.gdshader): a kebab stand with a pixel
## KEBAB board that glows at night, the palm on Rondo de Gaulle'a with a neon ring,
## pigeons (on the ground and in the air), roadwork barriers, a REMONT sign, the
## Mermaid with her sword and shield, a billboard frame, and people standing about.
## Fronts face -Z, like the vehicles.

const Models := preload("res://scripts/models.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const FIXED := Models.FIXED
const PAINT := Models.PAINT
const TROUSERS := Models.TROUSERS
const HEAD_LAMP := Models.HEAD_LAMP
const LIT_WINDOW := Models.LIT_WINDOW
const LIT_SIGN := Models.LIT_SIGN
const BLINK := Models.BLINK
## Loop couriers: the waiting courier's shape in pedzik_rider's morph family (INSTANCE_CUSTOM.a).
const PEDZIK_STANDING := 1.0


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func box(st: SurfaceTool, centre: Vector3, size: Vector3, colour: Color, part := FIXED) -> void:
	Models.box(st, centre, size, colour, part)


## A box turned by `basis` (unit axes) about its centre.
static func obox(st: SurfaceTool, centre: Vector3, basis: Basis, size: Vector3, colour: Color, part := FIXED) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n: Vector3 = basis[axis] * sgn
			var u: Vector3 = basis[(axis + 1) % 3] * h[(axis + 1) % 3]
			var v: Vector3 = basis[(axis + 2) % 3] * h[(axis + 2) % 3]
			var c: Vector3 = centre + n * h[axis]
			var q := [c - u - v, c + u - v, c + u + v, c - u + v]
			if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(n)
				st.set_uv(Vector2(part, 0.0))
				st.add_vertex(q[k])


## A box from a to b (its long axis), `w` wide and `t` thick; `side` sets which
## way its width lies.
static func beam(st: SurfaceTool, a: Vector3, b: Vector3, w: float, t: float, colour: Color, side := Vector3.UP, part := FIXED) -> void:
	var along := b - a
	var z := along.normalized()
	var x := side.cross(z).normalized()
	if x.length_squared() < 0.01:
		x = Vector3.RIGHT
	var y := z.cross(x).normalized()
	obox(st, (a + b) * 0.5, Basis(x, y, z), Vector3(w, t, along.length()), colour, part)


# --- the kebab stand ----------------------------------------------------------------

## A kiosk about 3 m wide: cream walls with a red band, a lit serving hatch with a
## striped awning, and a dark board on the roof with KEBAB in pixel letters (front
## and back), framed by a neon tube. A tall table stands in front.
static func kebab_stand() -> ArrayMesh:
	var st := _begin()
	var cream := Color("#efe4cc")
	var red := Color("#c8282a")
	var dark := Color("#2b2730")
	box(st, Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 2.0), cream)
	box(st, Vector3(0, 0.18, 0), Vector3(3.04, 0.36, 2.04), red)
	box(st, Vector3(0, 2.32, 0), Vector3(3.08, 0.2, 2.08), red)
	box(st, Vector3(0, 2.48, 0), Vector3(3.2, 0.12, 2.2), Color("#5d5a57"))
	# The hatch: warm light from inside at night, a counter under it.
	box(st, Vector3(0, 1.45, -1.0), Vector3(2.1, 0.9, 0.06), Color("#f3cf8a"), LIT_WINDOW)
	box(st, Vector3(-0.55, 1.4, -1.02), Vector3(0.22, 0.75, 0.04), Color("#8a4a24"))  # the spit inside
	box(st, Vector3(0, 0.98, -1.18), Vector3(2.5, 0.08, 0.38), Color("#9aa0a6"))
	# Awning: red and white stripes.
	for k in 8:
		var x := -1.4 + k * 0.4
		box(st, Vector3(x, 2.08, -1.42), Vector3(0.4, 0.07, 0.9), red if k % 2 == 0 else Color("#f7f2e8"))
	box(st, Vector3(0, 1.98, -1.86), Vector3(3.2, 0.16, 0.04), red)
	# Roof board on two posts, KEBAB on both faces, a pink neon frame.
	for x in [-1.1, 1.1]:
		box(st, Vector3(x, 2.85, 0), Vector3(0.1, 0.6, 0.1), dark)
	var w := 5.2
	var h := 1.55
	var y0 := 3.15
	box(st, Vector3(0, y0 + h * 0.5, 0), Vector3(w, h, 0.2), dark)
	var pink := Color("#ff4fb8")
	for z in [-0.12, 0.12]:
		box(st, Vector3(0, y0 + 0.04, z), Vector3(w, 0.07, 0.03), pink, LIT_SIGN)
		box(st, Vector3(0, y0 + h - 0.04, z), Vector3(w, 0.07, 0.03), pink, LIT_SIGN)
		for x in [-w * 0.5 + 0.04, w * 0.5 - 0.04]:
			box(st, Vector3(x, y0 + h * 0.5, z), Vector3(0.07, h, 0.03), pink, LIT_SIGN)
	var px := 0.15
	var word := "KEBAB"
	var tw := PixelFont.width(word) * px
	var top := y0 + h * 0.5 + (PixelFont.BODY + 3.5) * px
	var gold := Color("#ffd23f")
	# Seen from the front (-Z) the text runs towards -X; from the back, towards +X.
	PixelFont.add_quads(st, word, Vector3(tw * 0.5, top, -0.11), Vector3.LEFT, Vector3.DOWN, px, gold, LIT_SIGN)
	PixelFont.add_quads(st, word, Vector3(-tw * 0.5, top, 0.11), Vector3.RIGHT, Vector3.DOWN, px, gold, LIT_SIGN)
	# A tall table out front.
	box(st, Vector3(1.0, 0.55, -2.5), Vector3(0.1, 1.1, 0.1), Color("#5d5a57"))
	box(st, Vector3(1.0, 1.12, -2.5), Vector3(0.7, 0.06, 0.7), Color("#d9d4c8"))
	box(st, Vector3(1.0, 0.03, -2.5), Vector3(0.5, 0.06, 0.5), Color("#5d5a57"))
	return st.commit()


# --- the palm -------------------------------------------------------------------------

## The palm on Rondo de Gaulle'a: a ringed, gently curving trunk about 13 m tall on
## a round-ish plinth, a crown of drooping fronds, a few coconuts, and a pink neon
## ring and four uplights round the plinth that glow at night.
static func palm() -> ArrayMesh:
	var st := _begin()
	var stone := Color("#bdb6aa")
	box(st, Vector3(0, 0.3, 0), Vector3(2.4, 0.6, 1.2), stone)
	box(st, Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 2.4), stone)
	box(st, Vector3(0, 0.3, 0), Vector3(2.0, 0.6, 2.0), stone)
	var pink := Color("#ff4fd8")
	box(st, Vector3(0, 0.66, 0), Vector3(2.5, 0.07, 0.07), pink, LIT_SIGN)
	box(st, Vector3(0, 0.66, 0), Vector3(0.07, 0.07, 2.5), pink, LIT_SIGN)
	for c in [Vector3(1.05, 0.66, 1.05), Vector3(-1.05, 0.66, 1.05), Vector3(1.05, 0.66, -1.05), Vector3(-1.05, 0.66, -1.05)]:
		box(st, c, Vector3(0.18, 0.12, 0.18), Color("#fff3c4"), HEAD_LAMP)
	# Trunk: rings alternating two browns, leaning a little and widening at the foot.
	var segs := 16
	var top := Vector3.ZERO
	for i in segs:
		var t := float(i) / segs
		var lean := Vector3(0.9 * t * t, 0, -0.35 * t * t)
		var y := 0.6 + i * 0.78
		var wd := lerpf(0.78, 0.5, t)
		box(st, Vector3(0, y + 0.39, 0) + lean, Vector3(wd, 0.8, wd), Color("#8b6c4a") if i % 2 == 0 else Color("#a2825b"))
		top = Vector3(0, y + 0.8, 0) + lean
	box(st, top + Vector3(0, 0.15, 0), Vector3(0.7, 0.4, 0.7), Color("#6f8a3a"))
	# Coconuts.
	for a in [0.3, 2.4, 4.4]:
		box(st, top + Vector3(cos(a) * 0.38, -0.25, sin(a) * 0.38), Vector3(0.3, 0.3, 0.3), Color("#6b4a2b"))
	# Fronds: chains of leaf boxes rising, then drooping, around the crown.
	var greens := [Color("#3f8f3a"), Color("#4f9e3f"), Color("#5aa845"), Color("#3b7f36")]
	var n := 9
	for k in n:
		var a := TAU * k / n + 0.2
		var dir := Vector3(cos(a), 0, sin(a))
		var p := top + Vector3(0, 0.2, 0)
		var pitch := 0.75 - 0.15 * (k % 2)
		for j in 6:
			var length := 1.0
			var step := (dir * cos(pitch) + Vector3.UP * sin(pitch)) * length
			var q := p + step
			beam(st, p, q, 0.85 - j * 0.1, 0.1, greens[(k + j) % greens.size()])
			p = q
			pitch -= 0.38
	return st.commit()


# --- pigeons -----------------------------------------------------------------------------

## A pigeon about 0.7 m long (bigger than life, so it reads): grey body, a green
## and violet neck, dark wing bars. `flying` spreads the wings.
static func pigeon(flying: bool) -> ArrayMesh:
	var st := _begin()
	var grey := Color("#9097a1")
	var dark := Color("#5f656e")
	box(st, Vector3(0, 0.32, 0.02), Vector3(0.34, 0.3, 0.56), grey)
	box(st, Vector3(0, 0.5, -0.24), Vector3(0.26, 0.22, 0.2), Color("#6e5a8f"))
	box(st, Vector3(0, 0.6, -0.32), Vector3(0.22, 0.22, 0.24), Color("#7b828c"))
	box(st, Vector3(0, 0.57, -0.47), Vector3(0.07, 0.06, 0.1), Color("#e8c9a8"))
	box(st, Vector3(0, 0.3, 0.38), Vector3(0.26, 0.08, 0.26), dark)
	if flying:
		for s in [-1.0, 1.0]:
			box(st, Vector3(s * 0.42, 0.42, 0.02), Vector3(0.55, 0.05, 0.36), grey)
			box(st, Vector3(s * 0.62, 0.42, 0.1), Vector3(0.2, 0.06, 0.24), dark)
	else:
		for s in [-1.0, 1.0]:
			box(st, Vector3(s * 0.18, 0.36, 0.08), Vector3(0.04, 0.18, 0.4), dark)
		for s in [-0.07, 0.07]:
			box(st, Vector3(s, 0.08, -0.02), Vector3(0.04, 0.16, 0.04), Color("#d77a7a"))
	return st.commit()


# --- roadworks -------------------------------------------------------------------------

## A roadwork barrier 2 m long and 1.2 m tall, chunky enough to read at the default zoom
## (loop 1; the old 1.6 m one with 22 cm boards was a few stray pixels): a deep top board
## and a lower rail in red and white blocks, grey legs on dark feet, and an amber lamp on
## top that blinks at dusk and at night.
static func barrier() -> ArrayMesh:
	var st := _begin()
	var red := Color("#d8262b")
	var white := Color("#f6f3ec")
	for k in 5:
		box(st, Vector3(-0.8 + k * 0.4, 0.95, 0), Vector3(0.4, 0.46, 0.14), red if k % 2 == 0 else white)
		box(st, Vector3(-0.8 + k * 0.4, 0.39, 0), Vector3(0.4, 0.22, 0.12), white if k % 2 == 0 else red)
	for x in [-0.93, 0.93]:
		box(st, Vector3(x, 0.6, 0), Vector3(0.1, 1.2, 0.1), Color("#c9ccd0"))
		box(st, Vector3(x, 0.05, 0), Vector3(0.2, 0.1, 0.85), Color("#2f3034"))
	box(st, Vector3(-0.78, 1.24, 0), Vector3(0.08, 0.1, 0.08), Color("#2f3034"))
	box(st, Vector3(-0.78, 1.4, 0), Vector3(0.28, 0.24, 0.2), Color("#ffb21e"), BLINK)
	return st.commit()


## A traffic cone, 0.75 m: orange with a white band (loop 1: bigger, stepped like a cone).
static func cone() -> ArrayMesh:
	var st := _begin()
	var orange := Color("#ff6a13")
	box(st, Vector3(0, 0.03, 0), Vector3(0.6, 0.06, 0.6), Color("#2b2c2f"))
	box(st, Vector3(0, 0.18, 0), Vector3(0.44, 0.24, 0.44), orange)
	box(st, Vector3(0, 0.38, 0), Vector3(0.34, 0.16, 0.34), Color("#f6f3ec"))
	box(st, Vector3(0, 0.53, 0), Vector3(0.25, 0.14, 0.25), orange)
	box(st, Vector3(0, 0.67, 0), Vector3(0.15, 0.14, 0.15), orange)
	return st.commit()


## The dig the barriers fence off: a dark trench and a heap of sand.
static func dig(length: float, width: float) -> ArrayMesh:
	var st := _begin()
	box(st, Vector3(0, 0.04, 0), Vector3(width, 0.08, length), Color("#4a3a2c"))
	box(st, Vector3(0, 0.09, length * 0.25), Vector3(width * 0.6, 0.06, length * 0.3), Color("#2f251c"))
	box(st, Vector3(width * 0.15, 0.25, -length * 0.3), Vector3(width * 0.5, 0.5, 1.6), Color("#d8b77a"))
	box(st, Vector3(width * 0.15, 0.55, -length * 0.3), Vector3(width * 0.3, 0.2, 0.9), Color("#cfa96a"))
	return st.commit()


## A yellow roadworks sign on two posts with `word` in black pixel letters on both
## faces.
static func work_sign(word: String) -> ArrayMesh:
	var st := _begin()
	var px := 0.09
	var tw := PixelFont.width(word) * px
	var w := tw + 0.5
	var h := 1.1
	var y0 := 1.3
	for x in [-w * 0.5 + 0.2, w * 0.5 - 0.2]:
		box(st, Vector3(x, (y0 + 0.1) * 0.5, 0), Vector3(0.08, y0 + 0.1, 0.08), Color("#8c9096"))
	box(st, Vector3(0, y0 + h * 0.5, 0), Vector3(w, h, 0.06), Color("#f2c12e"))
	box(st, Vector3(0, y0 + h * 0.5, 0), Vector3(w + 0.12, h + 0.12, 0.04), Color("#1d1b19"))
	var top := y0 + h * 0.5 + (PixelFont.BODY + 3.5) * px
	var ink := Color("#1d1b19")
	PixelFont.add_quads(st, word, Vector3(tw * 0.5, top, -0.035), Vector3.LEFT, Vector3.DOWN, px, ink, FIXED)
	PixelFont.add_quads(st, word, Vector3(-tw * 0.5, top, 0.035), Vector3.RIGHT, Vector3.DOWN, px, ink, FIXED)
	box(st, Vector3(-w * 0.5 + 0.2, y0 + h + 0.12, 0), Vector3(0.16, 0.16, 0.12), Color("#ffb21e"), LIT_SIGN)
	return st.commit()


# --- the Mermaid -------------------------------------------------------------------------

## A small Mermaid (no particular statue): a stone plinth, a curled fish tail, her
## sword raised in the right hand and a round shield on the left arm, all in green
## patinated bronze. About 5 m tall with the plinth, so she reads from the street.
static func mermaid() -> ArrayMesh:
	var st := _begin()
	var stone := Color("#c3bcae")
	var bronze := Color("#4f8a76")
	var shade := Color("#3c6d5d")
	var deep := Color("#2c5246")
	box(st, Vector3(0, 0.15, 0), Vector3(2.2, 0.3, 2.2), Color("#a9a294"))
	box(st, Vector3(0, 0.95, 0), Vector3(1.6, 1.3, 1.6), stone)
	box(st, Vector3(0, 1.66, 0), Vector3(1.8, 0.14, 1.8), Color("#a9a294"))
	var base := 1.73
	# Tail: a coil on the plinth, rising into the hips, the fin flicked up behind.
	box(st, Vector3(0, base + 0.15, 0.1), Vector3(1.1, 0.3, 0.9), shade)
	box(st, Vector3(0.25, base + 0.42, 0.25), Vector3(0.6, 0.3, 0.6), bronze)
	box(st, Vector3(0.05, base + 0.75, 0.05), Vector3(0.5, 0.4, 0.45), bronze)
	beam(st, Vector3(-0.35, base + 0.2, 0.35), Vector3(-0.75, base + 0.8, 0.75), 0.35, 0.22, shade)
	beam(st, Vector3(-0.75, base + 0.8, 0.75), Vector3(-1.0, base + 1.25, 0.75), 0.6, 0.08, deep)
	beam(st, Vector3(-0.75, base + 0.8, 0.75), Vector3(-0.6, base + 1.3, 1.0), 0.6, 0.08, deep)
	# Torso, head and hair.
	box(st, Vector3(0, base + 1.25, 0), Vector3(0.52, 0.65, 0.34), bronze)
	box(st, Vector3(0, base + 1.66, 0), Vector3(0.3, 0.18, 0.26), shade)
	box(st, Vector3(0, base + 1.9, -0.02), Vector3(0.32, 0.34, 0.3), bronze)
	box(st, Vector3(0, base + 2.0, 0.14), Vector3(0.36, 0.32, 0.18), deep)
	# Right arm up, the sword above her head.
	beam(st, Vector3(0.3, base + 1.5, 0), Vector3(0.5, base + 2.2, -0.05), 0.15, 0.15, bronze)
	box(st, Vector3(0.52, base + 2.28, -0.05), Vector3(0.36, 0.08, 0.12), deep)
	beam(st, Vector3(0.52, base + 2.3, -0.05), Vector3(0.62, base + 3.55, -0.1), 0.14, 0.05, Color("#6fa592"))
	# Left arm forward with the round shield.
	beam(st, Vector3(-0.3, base + 1.5, 0), Vector3(-0.45, base + 1.2, -0.3), 0.15, 0.15, bronze)
	var shield := Vector3(-0.5, base + 1.25, -0.42)
	box(st, shield, Vector3(0.8, 0.56, 0.08), shade)
	box(st, shield, Vector3(0.56, 0.8, 0.08), shade)
	box(st, shield + Vector3(0, 0, -0.05), Vector3(0.2, 0.2, 0.06), Color("#6fa592"))
	return st.commit()


# --- people and things ---------------------------------------------------------------------

## A person standing, 1.75 m tall, in their own colours (no instance paint), so it
## can be a plain MeshInstance3D. `bags` gives them two shopping bags of jars.
static func person(shirt: Color, trousers: Color, bags := false) -> ArrayMesh:
	var st := _begin()
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.11 * side, 0.43, 0), Vector3(0.17, 0.86, 0.22), trousers)
	box(st, Vector3(0, 1.15, 0), Vector3(0.46, 0.62, 0.28), shirt)
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.29 * side, 1.12, 0), Vector3(0.12, 0.56, 0.16), shirt)
	box(st, Vector3(0, 1.58, 0), Vector3(0.26, 0.26, 0.26), Color("#e2b48c"))
	box(st, Vector3(0, 1.72, 0.02), Vector3(0.28, 0.08, 0.3), Color("#4a3426"))
	if bags:
		for side in [-1.0, 1.0]:
			box(st, Vector3(0.48 * side, 0.55, 0), Vector3(0.34, 0.42, 0.24), Color("#e9e4d8"))
			for k in 2:
				box(st, Vector3(0.48 * side + (k - 0.5) * 0.14, 0.82, 0), Vector3(0.11, 0.14, 0.11), Color("#d9a441"))
				box(st, Vector3(0.48 * side + (k - 0.5) * 0.14, 0.9, 0), Vector3(0.12, 0.03, 0.12), Color("#c8282a"))
	return st.commit()


## A billboard's frame: two posts and a dark border round a board w × h metres whose
## bottom edge is `y0` up; the poster itself is a separate quad (poster.gdshader).
static func billboard_frame(w: float, h: float, y0: float) -> ArrayMesh:
	var st := _begin()
	var steel := Color("#4a4d52")
	for x in [-w * 0.3, w * 0.3]:
		box(st, Vector3(x, (y0 + 0.2) * 0.5, 0.12), Vector3(0.3, y0 + 0.2, 0.3), steel)
	box(st, Vector3(0, y0 + h * 0.5, 0.1), Vector3(w + 0.3, h + 0.3, 0.16), Color("#5b5f66"))
	# The back: steel panels with a few ribs.
	for k in 4:
		box(st, Vector3(0, y0 + h * (k + 0.5) / 4.0, 0.19), Vector3(w + 0.1, 0.06, 0.04), Color("#43464b"))
	# Lamps along the top that light the poster at night.
	for k in 3:
		box(st, Vector3((k - 1) * w * 0.33, y0 + h + 0.25, -0.35), Vector3(0.4, 0.12, 0.3), Color("#fff3c4"), HEAD_LAMP)
		box(st, Vector3((k - 1) * w * 0.33, y0 + h + 0.2, -0.12), Vector3(0.06, 0.06, 0.5), steel)
	return st.commit()


## A flat quad w × h facing -Z with UV 0..1 (u right, v down), for a poster texture.
static func poster_quad(w: float, h: float, y0: float) -> ArrayMesh:
	var st := _begin()
	var corners := [Vector3(w * 0.5, y0 + h, 0), Vector3(-w * 0.5, y0 + h, 0), Vector3(-w * 0.5, y0, 0), Vector3(w * 0.5, y0, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.FORWARD)
		st.set_uv(uvs[k])
		st.set_color(Color.WHITE)
		st.add_vertex(corners[k])
	return st.commit()


## A soft glow sprite `size` metres across in `colour` (alpha = brightness), for the
## glow material (glow.gdshader, billboard + radial): a halo round a sign at night.
static func halo(size: float, colour: Color) -> ArrayMesh:
	var st := _begin()
	var h := size * 0.5
	var corners := [Vector3(-h, h, 0), Vector3(h, h, 0), Vector3(h, -h, 0), Vector3(-h, -h, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(colour)
		st.set_uv(uvs[k])
		st.add_vertex(corners[k])
	return st.commit()


## The glow material for halos and light cones (night only, after the post pass).
static func glow_material(billboard: bool, lift := 1.5) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/glow.gdshader")
	m.set_shader_parameter("billboard", billboard)
	m.set_shader_parameter("radial", billboard)
	m.set_shader_parameter("lift", lift)
	m.render_priority = 1
	return m


# --- loop MW-2: storefronts and parodies (docs/design/parodies.md 2, 4, 5, 6.1; vision.md 3.5) --

## One triangle facing `n` (Godot's front faces are clockwise: swapped when needed).
static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, colour: Color, part := FIXED) -> void:
	var q := [a, b, c]
	if (b - a).cross(c - a).dot(n) > 0.0:
		q = [a, c, b]
	for v in q:
		st.set_color(colour)
		st.set_normal(n)
		st.set_uv(Vector2(part, 0.0))
		st.add_vertex(v)


## A Frogs shop front (parodies.md 2.1), on a wall: x along the wall (to the reader's right), y
## up, z out of the wall (the wall's plane z = 0, the pavement y = 0). The frog-green fascia
## 5.0 × 0.9 m, 0.25 m deep at 3.2-4.1 m with FROGS in cream at a 0.12 m letter pixel (3.48 ×
## 0.84 m), the lily-pad blade sign (a 0.9 m octagon disc with a notch, "24" on both faces) on
## a bracket at 3.65 m, the 4.4 × 2.4 m window (LIT_WINDOW), a 1.0 m door with a dark frame and
## the floor strip. No frog figure: the lily pad is the mark (Open Question 3). ~430 triangles.
static func frogs_shop() -> ArrayMesh:
	var st := _begin()
	var green := Color("#4fae3b")
	var pad := Color("#2f6b2a")
	var cream := Color("#fbf7ee")
	var dark := Color("#1f3a22")
	var glass := Color("#cfe8c6")
	# The fascia and its text.
	box(st, Vector3(0, 3.65, 0.125), Vector3(5.0, 0.9, 0.25), green, LIT_SIGN)
	var px := 0.12
	var w := PixelFont.width("FROGS") * px
	var top := 3.65 + (PixelFont.BODY + 3.5) * px
	PixelFont.add_quads(st, "FROGS", Vector3(-w * 0.5, top, 0.252), Vector3.RIGHT, Vector3.DOWN, px, cream, LIT_SIGN)
	# The window, the door and the frame round them.
	box(st, Vector3(-0.55, 1.5, 0.03), Vector3(3.3, 2.4, 0.06), glass, LIT_WINDOW)
	box(st, Vector3(1.75, 1.2, 0.035), Vector3(0.9, 2.2, 0.07), glass, LIT_WINDOW)
	box(st, Vector3(1.75, 2.36, 0.06), Vector3(1.1, 0.12, 0.12), dark)
	for x in [-2.45, 1.2, 2.3, 2.45]:
		box(st, Vector3(x, 1.6, 0.06), Vector3(0.1, 3.2 if absf(x) > 2.4 else 2.4, 0.12), dark)
	box(st, Vector3(0, 2.97, 0.05), Vector3(5.0, 0.14, 0.1), dark)
	box(st, Vector3(0, 0.06, 0.1), Vector3(5.0, 0.12, 0.2), dark)
	# The blade sign: a bracket out from the fascia, the disc across it (faces ±x), "24" on both.
	var c := Vector3(2.2, 3.65, 0.85)
	box(st, Vector3(2.2, 4.06, 0.55), Vector3(0.05, 0.05, 0.6), Color("#3a3b3f"))
	var r := 0.45
	var half := 0.06
	var pts: Array[Vector3] = []
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		pts.append(Vector3(0.0, sin(a) * r, cos(a) * r))
	for side in [-1.0, 1.0]:
		var n := Vector3(side, 0, 0)
		for k in 8:
			if k == 1:
				continue  # the notch: a lily pad, not a coin
			tri(st, c + n * half, c + pts[k] + n * half, c + pts[(k + 1) % 8] + n * half, n, pad, LIT_SIGN)
	for k in 8:
		if k == 1:
			continue
		var a: Vector3 = c + pts[k]
		var b: Vector3 = c + pts[(k + 1) % 8]
		var n := ((a + b) * 0.5 - c).normalized()
		tri(st, a + Vector3(-half, 0, 0), b + Vector3(-half, 0, 0), b + Vector3(half, 0, 0), n, pad)
		tri(st, a + Vector3(-half, 0, 0), b + Vector3(half, 0, 0), a + Vector3(half, 0, 0), n, pad)
	var dpx := 0.06
	var dw := PixelFont.width("24") * dpx
	var dtop := c.y + (PixelFont.BODY + 3.5) * dpx
	# A reader on the +x side (looking -x) has -z on the right; on the -x side, +z.
	PixelFont.add_quads(st, "24", Vector3(c.x + half + 0.002, dtop, c.z + dw * 0.5), Vector3.FORWARD, Vector3.DOWN, dpx, cream, LIT_SIGN)
	PixelFont.add_quads(st, "24", Vector3(c.x - half - 0.002, dtop, c.z - dw * 0.5), Vector3.BACK, Vector3.DOWN, dpx, cream, LIT_SIGN)
	return st.commit()


## A Leżak (parodies.md 5.1): a dumped e-scooter, ≤ 120 triangles, standing, its length along
## z: the violet deck 1.1 × 0.06 × 0.18 m, the dark stem 0.95 m and handlebar, two small
## wheels, a white front lamp. Lying on its side is the same mesh turned 90° about z.
static func lezak() -> ArrayMesh:
	var st := _begin()
	var violet := Color("#8e44d9")
	var dark := Color("#3a3b3f")
	box(st, Vector3(0, 0.12, 0), Vector3(0.18, 0.06, 1.1), violet)
	box(st, Vector3(0, 0.6, -0.5), Vector3(0.06, 0.95, 0.06), dark)
	box(st, Vector3(0, 1.06, -0.5), Vector3(0.5, 0.04, 0.05), dark)
	for z in [-0.48, 0.5]:
		box(st, Vector3(0, 0.1, z), Vector3(0.05, 0.2, 0.2), Models.TYRE)
	box(st, Vector3(0, 0.9, -0.54), Vector3(0.06, 0.05, 0.03), Color("#fbf7ee"), HEAD_LAMP)
	return st.commit()


## A Leżak parking zone (parodies.md 5.2): a painted white rectangle 3 × 1.5 m on the pavement
## (an outline 0.1 m wide, 2 cm up), centred on the origin, long along x.
static func add_scooter_zone(st: SurfaceTool, xf: Transform3D) -> void:
	var white := Color("#f2efe6")
	for b: Array in [[Vector3(0, 0.02, -0.7), Vector3(3.0, 0.02, 0.1)], [Vector3(0, 0.02, 0.7), Vector3(3.0, 0.02, 0.1)],
			[Vector3(-1.45, 0.02, 0), Vector3(0.1, 0.02, 1.5)], [Vector3(1.45, 0.02, 0), Vector3(0.1, 0.02, 1.5)]]:
		_xbox(st, xf, b[0], b[1], white)


## Loop jobs-2 (vision.md 3.9 T17, egg E40): the old card payphone at Plac Konstytucji, into the
## sector's street-prop mesh at `xf`: a grey post, the phone's box with a dark screen, a black
## handset on its hook and a cream card slot, under a small hood (no operator's colours or mark).
## The phone faces -z. 10 boxes, 120 triangles; 1.95 m tall; no shadow (the street-prop mesh).
static func add_payphone(st: SurfaceTool, xf: Transform3D) -> void:
	var steel := Color("#6b7079")
	var shell := Color("#aeb4bb")
	var dark := Color("#1d1f24")
	var hood := Color("#4d6178")
	_xbox(st, xf, Vector3(0, 0.03, 0), Vector3(0.3, 0.06, 0.3), steel)
	_xbox(st, xf, Vector3(0, 0.6, 0.02), Vector3(0.1, 1.2, 0.1), steel)
	_xbox(st, xf, Vector3(0, 1.42, 0), Vector3(0.38, 0.52, 0.2), shell)
	_xbox(st, xf, Vector3(0, 1.58, -0.105), Vector3(0.2, 0.09, 0.02), dark)
	_xbox(st, xf, Vector3(0.06, 1.42, -0.105), Vector3(0.1, 0.12, 0.02), Color("#3a3d44"))
	_xbox(st, xf, Vector3(0.06, 1.33, -0.112), Vector3(0.08, 0.012, 0.012), Color("#fbf7ee"))
	_xbox(st, xf, Vector3(-0.15, 1.44, -0.12), Vector3(0.06, 0.32, 0.06), dark)
	_xbox(st, xf, Vector3(-0.15, 1.3, -0.15), Vector3(0.05, 0.03, 0.07), dark)
	_xbox(st, xf, Vector3(0, 1.88, -0.04), Vector3(0.56, 0.05, 0.42), hood)
	_xbox(st, xf, Vector3(0, 1.82, 0.14), Vector3(0.56, 0.12, 0.05), hood)


## Loop jobs-2 (vision.md 3.7, egg E34): a 1960s armchair carried upside down on a man's head (his
## head's top at 1.75 m): the teal cushion on top, the back hanging down behind him (+z: he faces
## -z), the wooden arms, and four splayed legs in the air. 10 boxes, 120 triangles.
static func carried_armchair() -> ArrayMesh:
	var st := _begin()
	var teal := Color("#3f7f7a")
	var wood := Color("#8a5a34")
	box(st, Vector3(0, 1.84, 0.02), Vector3(0.66, 0.12, 0.6), teal)
	box(st, Vector3(0, 1.58, 0.33), Vector3(0.62, 0.5, 0.09), teal)
	for x in [-0.36, 0.36]:
		box(st, Vector3(x, 1.74, 0.02), Vector3(0.07, 0.1, 0.56), wood)
	for x in [-0.27, 0.27]:
		for z in [-0.22, 0.26]:
			beam(st, Vector3(x, 1.9, z), Vector3(x * 1.25, 2.16, z * 1.25), 0.045, 0.045, wood)
	return st.commit()


## A box through a transform (for the combined street-prop mesh of a sector).
static func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color, part := FIXED) -> void:
	obox(st, xf * centre, xf.basis.orthonormalized(), size, colour, part)


## A metro entrance (vision.md 3.5, M1 and M2 at the real stairs) into the sector's street-prop
## mesh at `xf` (open front at -z; the stairs go down towards +z, as the bake's `yaw` says). `form`
## is the bake's `f`: "canopy" (a barrel-vaulted glass canopy on steel ribs with a lit red fascia
## and a handrail down the middle), "steps" (an open stairwell behind a granite balustrade) or
## "footway" (a passage mouth between two stepped concrete retaining walls) or "tube" (Metro
## Centrum's blue half-barrel canopy). Every form has the
## step treads painted down the dark opening, a red M post (a pixel-font M in a red square, our
## own shape, not the operator's mark; lit at night) and, when `lift`, a glass lift shaft beside it.
## Stays in the sector's one mesh: no extra draw call. 320-620 triangles.
static func add_metro_entrance(st: SurfaceTool, xf: Transform3D, form := "canopy", lift := false) -> void:
	var steel := Color("#5b5f66")
	var rail := Color("#b9bec4")
	var glass := Color("#a8cde6")
	var granite := Color("#8d8b86")
	var concrete := Color("#9a978f")
	# The opening, its treads (light at the top, darker down) and the handrail posts.
	_xbox(st, xf, Vector3(0, 0.02, 0), Vector3(2.2, 0.03, 4.0), Color("#1d1f24"))
	for i in 9:
		var k := float(i) / 8.0
		var tone := Color("#7b7e84").lerp(Color("#2a2c31"), k)
		_xbox(st, xf, Vector3(0, 0.04, -1.8 + i * 0.42), Vector3(2.2, 0.02, 0.2), tone)
	for z in [-1.7, 0.0, 1.7]:
		_xbox(st, xf, Vector3(0, 0.5, z), Vector3(0.05, 1.0, 0.05), rail)
	_xbox(st, xf, Vector3(0, 0.98, 0), Vector3(0.06, 0.05, 3.7), rail)
	match form:
		"steps":
			# A balustrade of granite on three sides, a cap on its top.
			for x in [-1.2, 1.2]:
				_xbox(st, xf, Vector3(x, 0.45, 0.0), Vector3(0.22, 0.9, 4.2), granite)
				_xbox(st, xf, Vector3(x, 0.93, 0.0), Vector3(0.32, 0.06, 4.3), steel)
			_xbox(st, xf, Vector3(0, 0.45, 2.0), Vector3(2.66, 0.9, 0.22), granite)
			_xbox(st, xf, Vector3(0, 0.93, 2.0), Vector3(2.76, 0.06, 0.32), steel)
		"tube":
			# Metro Centrum's 1990s "tube" (F, 2026-11-02): a half barrel of milky polycarbonate on
			# blue steel arches over the stairs, from 1.0 m, closed at the deep end (+z), a blue
			# rim at the mouth. Rondo Dmowskiego's underpass stairs wear the same (landmarks.gd).
			var blue := Color("#2457a8")
			var skin := Color("#d6e4ee")
			for x in [-1.25, 1.25]:
				_xbox(st, xf, Vector3(x, 0.5, 0.0), Vector3(0.22, 1.0, 4.2), granite)
			var arc: Array[Vector3] = []
			for i in 8:
				var a := PI * float(i) / 7.0
				arc.append(Vector3(1.4 * cos(a), 1.0 + 1.4 * sin(a), 0.0))
			# The closed deep end: three stacked panes roughly filling the half circle.
			for pane: Vector3 in [Vector3(2.7, 1.0, 1.6), Vector3(2.3, 1.6, 2.05), Vector3(1.4, 2.05, 2.36)]:
				_xbox(st, xf, Vector3(0, (pane.y + pane.z) * 0.5, 2.12), Vector3(pane.x, pane.z - pane.y, 0.04), skin, LIT_WINDOW)
			for i in 7:
				_xbeam(st, xf, arc[i], arc[i + 1], 4.3, 0.03, skin, LIT_WINDOW)
				for z in [-2.1, -0.7, 0.7, 2.1]:
					var w := 0.18 if z < -2.0 else 0.1
					_xbeam(st, xf, arc[i] * 1.02 + Vector3(0, 0, z), arc[i + 1] * 1.02 + Vector3(0, 0, z), w, 0.1, blue)
		"footway":
			# Two retaining walls climbing from the mouth into the ground, handrails along them.
			for x in [-1.2, 1.2]:
				for j in 4:
					var hgt := 0.35 + j * 0.3
					_xbox(st, xf, Vector3(x, hgt * 0.5, -1.5 + j * 1.0), Vector3(0.24, hgt, 1.0), concrete)
				_xbox(st, xf, Vector3(x * 0.9, 1.0, -0.1), Vector3(0.05, 0.05, 3.7), rail)
			_xbox(st, xf, Vector3(0, 0.6, 2.05), Vector3(2.66, 1.2, 0.2), concrete)
		"crystal", "crystal_aqua", "crystal_clear":
			_metro_crystal(st, xf, form)
		"box":
			_metro_box(st, xf)
		"tent":
			_metro_tent(st, xf)
		"wings":
			_metro_wings(st, xf)
		"pavilion", "stone", "stone_steps":
			_metro_ratusz(st, xf, form)
			return
		_:
			# The canopy: steel sill and posts, glass sides and back, a vaulted glass roof on three
			# ribs (seven points on an ellipse 1.35 m out and 0.7 m up from the 2.2 m springing).
			for x in [-1.3, 1.3]:
				_xbox(st, xf, Vector3(x, 0.15, 0.0), Vector3(0.12, 0.3, 4.2), steel)
				_xbox(st, xf, Vector3(x, 1.25, 0.0), Vector3(0.05, 1.9, 4.1), glass, LIT_WINDOW)
				for z in [-2.05, 0.0, 2.05]:
					_xbox(st, xf, Vector3(x, 1.2, z), Vector3(0.1, 2.0, 0.1), steel)
			_xbox(st, xf, Vector3(0, 1.25, 2.1), Vector3(2.6, 1.9, 0.05), glass, LIT_WINDOW)
			_xbox(st, xf, Vector3(0, 0.15, 2.05), Vector3(2.6, 0.3, 0.12), steel)
			var pts: Array[Vector3] = []
			for i in 7:
				var a := PI * float(i) / 6.0
				pts.append(Vector3(1.35 * cos(a), 2.2 + 0.7 * sin(a), 0.0))
			for i in 6:
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[i + 1]
				_xbeam(st, xf, a, b, 4.3, 0.04, glass, LIT_WINDOW)
				for z in [-2.1, 0.0, 2.1]:
					_xbeam(st, xf, a + Vector3(0, 0, z), b + Vector3(0, 0, z), 0.1, 0.1, steel)
			# The fascia over the open front: red, lit, with the M on it.
			_xbox(st, xf, Vector3(0, 2.62, -2.15), Vector3(2.8, 0.55, 0.14), Color("#c8171f"), LIT_SIGN)
			_metro_m(st, xf, Vector3(0, 2.62, -2.15), 0.06, [-1.0])
	# The M post at the front right: a 3.4 m pole, a 0.9 m red square, the M on both faces.
	var post := Vector3(1.7, 0, -2.4)
	_xbox(st, xf, post + Vector3(0, 1.7, 0), Vector3(0.1, 3.4, 0.1), steel)
	_xbox(st, xf, post + Vector3(0, 3.3, 0), Vector3(0.9, 0.9, 0.08), Color("#c8171f"), LIT_SIGN)
	_metro_m(st, xf, post + Vector3(0, 3.3, 0), 0.095, [-1.0, 1.0], 0.08)
	if lift:
		if form == "wings":
			glass = Color("#b0202c")  # Rondo Daszyńskiego's lifts wear the same red glass
		# The lift: a steel frame round a lit glass shaft, a dark door on the open side (-z).
		var c := Vector3(-2.3, 0, -0.6)
		_xbox(st, xf, c + Vector3(0, 1.3, 0), Vector3(1.3, 2.5, 1.3), glass, LIT_WINDOW)
		for x in [-0.7, 0.7]:
			for z in [-0.7, 0.7]:
				_xbox(st, xf, c + Vector3(x, 1.35, z), Vector3(0.1, 2.7, 0.1), steel)
		_xbox(st, xf, c + Vector3(0, 2.72, 0), Vector3(1.5, 0.12, 1.5), steel)
		_xbox(st, xf, c + Vector3(0, 0.95, -0.67), Vector3(0.9, 1.9, 0.04), Color("#3a3e45"))


## Metro Ratusz-Arsenał's entrances (F's photos, 2026-11-07), local frame as add_metro_entrance's
## (open front -z, the stairs down towards +z; the treads and the handrail are already drawn):
##  - "pavilion": the glass escalator pavilion by the tram stop: a 9.6 m glass box on a pale stone
##    base, steel mullions every 1.2 m, a flat white roof with a thin overhang, the glazing lit at
##    night, the escalator's dark band and rails down the middle, stone cheek walls at the open
##    mouth, three white globe lamps on posts along its side and the roundel on a pole;
##  - "stone": an M1 entrance: a tall block of pale travertine on the right of the stairs, low stone
##    parapets with a steel rail, and a white cantilevered canopy over the mouth with the yellow
##    roundel on its front;
##  - "stone_steps": an open stairwell between stone walls with a steel rail on top, a stone pylon at
##    the front corner carrying a station plan and the roundel on its pole.
## These forms carry no red M post (the roundel is their sign). Stays in the sector's one mesh.
## 250-700 triangles.
static func _metro_ratusz(st: SurfaceTool, xf: Transform3D, form: String) -> void:
	var stone := Color("#bfb39c")
	var stone_dark := Color("#a49884")
	var steel := Color("#8e949a")
	var white := Color("#ecebe6")
	var glass := Color("#a9c6d4")
	match form:
		"pavilion":
			# The base: stone walls along both sides of the stairs, a step of stone at the mouth.
			for x: float in [-1.75, 1.75]:
				_xbox(st, xf, Vector3(x, 0.45, 2.2), Vector3(0.35, 0.9, 9.6), stone)
			_xbox(st, xf, Vector3(0, 0.45, 6.95), Vector3(3.85, 0.9, 0.3), stone)
			for x: float in [-1.2, 1.2]:
				_xbox(st, xf, Vector3(x, 0.5, -2.75), Vector3(0.5, 1.0, 0.5), stone_dark)
			# The glass box on the base: both sides and the back, lit at night, mullions every 1.2 m.
			for x: float in [-1.75, 1.75]:
				_xbox(st, xf, Vector3(x, 2.05, 2.2), Vector3(0.04, 2.3, 9.4), glass, LIT_WINDOW)
				for k in 9:
					_xbox(st, xf, Vector3(x * 1.01, 2.05, -2.6 + k * 1.2), Vector3(0.07, 2.3, 0.07), steel)
				_xbox(st, xf, Vector3(x * 1.01, 1.4, 2.2), Vector3(0.06, 0.06, 9.6), steel)
			_xbox(st, xf, Vector3(0, 2.05, 6.95), Vector3(3.5, 2.3, 0.04), glass, LIT_WINDOW)
			# The front's frame and the flat white roof over everything.
			_xbox(st, xf, Vector3(0, 3.05, -2.6), Vector3(3.6, 0.3, 0.1), steel)
			_xbox(st, xf, Vector3(0, 3.35, 2.2), Vector3(4.0, 0.22, 10.2), white)
			_xbox(st, xf, Vector3(0, 3.22, 2.2), Vector3(3.7, 0.06, 9.9), Color("#d8dadc"), LIT_WINDOW)
			# The escalator: a dark band and two rails down the middle, under the treads' handrail.
			_xbox(st, xf, Vector3(0.55, 0.05, 1.0), Vector3(0.9, 0.04, 6.0), Color("#26282c"))
			for x: float in [0.1, 1.0]:
				_xbox(st, xf, Vector3(x, 0.95, 1.0), Vector3(0.08, 0.08, 6.0), Color("#1d1e21"))
			# The globe lamps along the open side (+x), the roundel's pole at the mouth.
			for z: float in [-1.5, 2.2, 5.9]:
				_xbox(st, xf, Vector3(2.6, 1.75, z), Vector3(0.12, 3.5, 0.12), steel)
				_xbox(st, xf, Vector3(2.6, 3.7, z), Vector3(0.4, 0.4, 0.4), Color("#f6f3e8"), LIT_SIGN)
			_xbox(st, xf, Vector3(-2.4, 1.7, -2.9), Vector3(0.1, 3.4, 0.1), steel)
			_metro_roundel(st, xf, Vector3(-2.4, 3.3, -2.9), 0.42, [-1.0, 1.0])
		"stone":
			# The travertine block on the right, the parapets, the white canopy with the roundel.
			_xbox(st, xf, Vector3(1.9, 1.6, 0.4), Vector3(1.4, 3.2, 3.6), stone)
			for k in 5:
				_xbox(st, xf, Vector3(1.9, 0.5 + k * 0.6, 0.4), Vector3(1.42, 0.03, 3.62), stone_dark)
			_xbox(st, xf, Vector3(-1.2, 0.5, 0.2), Vector3(0.3, 1.0, 4.4), stone)
			_xbox(st, xf, Vector3(0, 0.5, 2.25), Vector3(2.7, 1.0, 0.3), stone)
			_xbox(st, xf, Vector3(-1.2, 1.05, 0.2), Vector3(0.36, 0.06, 4.4), stone_dark)
			_xbox(st, xf, Vector3(-1.2, 1.25, 0.2), Vector3(0.05, 0.05, 4.2), steel)
			_xbox(st, xf, Vector3(0.0, 2.85, -1.0), Vector3(3.4, 0.45, 2.6), white)
			_xbox(st, xf, Vector3(0.0, 2.6, -1.0), Vector3(3.2, 0.04, 2.4), Color("#f2f0e6"), LIT_WINDOW)
			_metro_roundel(st, xf, Vector3(0.2, 2.85, -2.34), 0.3, [-1.0])
		_:
			# The stairwell's stone walls on three sides, a rail on top.
			for x: float in [-1.25, 1.25]:
				_xbox(st, xf, Vector3(x, 0.55, 0.0), Vector3(0.32, 1.1, 4.3), stone)
				_xbox(st, xf, Vector3(x, 1.12, 0.0), Vector3(0.36, 0.05, 4.3), stone_dark)
				_xbox(st, xf, Vector3(x * 0.92, 1.0, 0.0), Vector3(0.05, 0.05, 4.1), steel)
			_xbox(st, xf, Vector3(0, 0.55, 2.1), Vector3(2.82, 1.1, 0.32), stone)
			# The pylon at the front corner with the plan, the roundel on its pole.
			_xbox(st, xf, Vector3(1.55, 1.1, -2.3), Vector3(0.7, 2.2, 0.45), stone)
			_xbox(st, xf, Vector3(1.55, 1.3, -2.53), Vector3(0.5, 0.8, 0.02), Color("#e8e4d6"), LIT_WINDOW)
			_xbox(st, xf, Vector3(1.55, 3.0, -2.3), Vector3(0.1, 1.6, 0.1), steel)
			_metro_roundel(st, xf, Vector3(1.55, 3.5, -2.3), 0.4, [-1.0, 1.0])


## Metro Świętokrzyska's M2 entrances (F's photo, Feb 2026): a steel-and-glass triangle "tent"
## over the stairs, tall at the open mouth (an A-frame gable 5.4 m high) and falling to 2.8 m at
## the deep end; light grey tube rafters, a ridge, two purlins and cross braces a side, glazed
## slopes with a fine mesh (lit at night), a white name band across the mouth with the M1 blue
## and M2 red squares, and the yellow roundel with the red M high on the gable. Local frame as
## add_metro_entrance's (open front -z). ~300 triangles.
static func _metro_tent(st: SurfaceTool, xf: Transform3D) -> void:
	var tube := Color("#d3d7da")
	var glass := Color("#b9c9cf")
	var concrete := Color("#a4a19a")
	var half := 1.75
	var z0 := -2.35
	var z1 := 2.35
	var front := Vector3(0, 5.4, z0)
	var back := Vector3(0, 2.8, z1)
	var basis := xf.basis.orthonormalized()
	# The low concrete upstands the slopes stand on.
	for x in [-half, half]:
		_xbox(st, xf, Vector3(x, 0.3, 0.0), Vector3(0.3, 0.6, z1 - z0 + 0.2), concrete)
	_xbox(st, xf, Vector3(0, 0.3, z1), Vector3(2 * half + 0.3, 0.6, 0.3), concrete)
	# The glazed slopes, both faces (the camera sees in through the mouth), and the back gable.
	for x: float in [-half, half]:
		var a := xf * Vector3(x, 0.6, z0)
		var b := xf * Vector3(x, 0.6, z1)
		var c := xf * back
		var d := xf * front
		var n := basis * Vector3(signf(x) * 0.88, 0.47, 0.0)
		for s: float in [1.0, -1.0]:
			tri(st, a, b, c, n * s, glass, LIT_WINDOW)
			tri(st, a, c, d, n * s, glass, LIT_WINDOW)
	for s: float in [1.0, -1.0]:
		tri(st, xf * Vector3(-half, 0.6, z1), xf * Vector3(half, 0.6, z1), xf * back, basis * Vector3(0, 0, s), glass, LIT_WINDOW)
	# The frame: the mouth's and the back's A, the ridge, the sills, two purlins and an X a side.
	for z: float in [z0, z1]:
		var top := front if z == z0 else back
		for x in [-half, half]:
			_xbeam(st, xf, Vector3(x, 0.6, z), top, 0.16, 0.16, tube)
	_xbeam(st, xf, front, back, 0.16, 0.16, tube)
	for x: float in [-half, half]:
		_xbeam(st, xf, Vector3(x, 0.62, z0), Vector3(x, 0.62, z1), 0.12, 0.12, tube)
		for k: float in [0.36, 0.68]:
			var p0 := Vector3(x, 0.6, z0).lerp(front, k)
			var p1 := Vector3(x, 0.6, z1).lerp(back, k)
			_xbeam(st, xf, p0, p1, 0.07, 0.07, tube)
		_xbeam(st, xf, Vector3(x, 0.6, z0), Vector3(x, 0.6, z1).lerp(back, 0.85), 0.06, 0.06, tube)
		_xbeam(st, xf, Vector3(x, 0.6, z1), Vector3(x, 0.6, z0).lerp(front, 0.85), 0.06, 0.06, tube)
	# The tie across the mouth and the name band hung from it (white, lit; M1 blue, M2 red).
	_xbeam(st, xf, Vector3(-half * 0.62, 2.35, z0), Vector3(half * 0.62, 2.35, z0), 0.12, 0.12, tube)
	_xbox(st, xf, Vector3(0, 2.05, z0 - 0.02), Vector3(2.3, 0.42, 0.08), Color("#f2f6f8"), LIT_SIGN)
	_xbox(st, xf, Vector3(-0.85, 2.05, z0 - 0.07), Vector3(0.24, 0.24, 0.03), Color("#2a6fc4"), LIT_SIGN)
	_xbox(st, xf, Vector3(-0.55, 2.05, z0 - 0.07), Vector3(0.24, 0.24, 0.03), Color("#d3202a"), LIT_SIGN)
	_xbox(st, xf, Vector3(0.35, 2.05, z0 - 0.07), Vector3(1.1, 0.08, 0.03), Color("#2a5ea8"), LIT_SIGN)
	# The roundel high on the gable: a yellow octagon (0.95 m) with the red M.
	_metro_roundel(st, xf, Vector3(0, 4.25, z0 - 0.12), 0.48, [-1.0])


## The station roundel: a yellow octagon of radius `r` (0.08 m thick) centred at `rc` in the
## entrance's frame, facing ±z, the red pixel M on the faces `sides` (-1 the -z face, 1 the +z).
## Lit at night. ~60 triangles a face.
static func _metro_roundel(st: SurfaceTool, xf: Transform3D, rc: Vector3, r: float, sides: Array) -> void:
	var basis := xf.basis.orthonormalized()
	var ring := 8
	for i in ring:
		var a0 := TAU * (i + 0.5) / ring
		var a1 := TAU * (i + 1.5) / ring
		for s: float in [-1.0, 1.0]:
			tri(st, xf * (rc + Vector3(0, 0, 0.04 * s)), xf * (rc + Vector3(r * cos(a0), r * sin(a0), 0.04 * s)),
					xf * (rc + Vector3(r * cos(a1), r * sin(a1), 0.04 * s)), basis * Vector3(0, 0, s), Color("#f6c813"), LIT_SIGN)
	_metro_m(st, xf, rc, 0.07 * r / 0.48, sides, 0.08, Color("#d3202a"))


## Metro Rondo Daszyński's M2 entrances (F's photos, 2026-11-06): two wings of red glass on a
## steel frame folding up from a keel over the escalators, so the mouth reads as a wide M: the
## outer tips stand 5.6 m high and lean out past the opening, the keel runs from 2.6 m at the mouth
## down into the ground behind it; tube edges and two ribs a wing, both faces glazed (lit at
## night), dark red side walls to the opening, and the yellow roundel with the red M on the keel's
## front. Local frame as add_metro_entrance's (open front -z). ~250 triangles.
static func _metro_wings(st: SurfaceTool, xf: Transform3D) -> void:
	var red := Color("#d02634")
	var tube := Color("#9a9ea3")
	var wall := Color("#5a1d22")
	var basis := xf.basis.orthonormalized()
	var z0 := -2.3
	var z1 := 2.3
	# The opening's low side walls (the escalators' balustrades): dark red panels.
	for x in [-1.25, 1.25]:
		_xbox(st, xf, Vector3(x, 0.5, 0.0), Vector3(0.22, 1.0, z1 - z0), wall)
	var keel0 := Vector3(0, 2.6, z0)
	var keel1 := Vector3(0, 0.4, z1 + 0.6)
	for side: float in [-1.0, 1.0]:
		var tip := Vector3(side * 3.3, 5.6, z0 - 0.5)
		var foot := Vector3(side * 2.4, 0.5, z1)
		var n := basis * Vector3(side * 0.6, -0.8, 0.0).normalized()
		for s: float in [1.0, -1.0]:
			tri(st, xf * keel0, xf * tip, xf * foot, n * s, red, LIT_SIGN)
			tri(st, xf * keel0, xf * foot, xf * keel1, n * s, red, LIT_SIGN)
		_xbeam(st, xf, keel0, tip, 0.14, 0.14, tube)
		_xbeam(st, xf, tip, foot, 0.12, 0.12, tube)
		_xbeam(st, xf, foot, keel1, 0.12, 0.12, tube)
		for k: float in [0.35, 0.7]:
			_xbeam(st, xf, keel0.lerp(keel1, k), tip.lerp(foot, k), 0.08, 0.08, tube)
		# a strut from the side wall up to the wing
		_xbeam(st, xf, Vector3(side * 1.25, 1.0, z0 + 0.6), keel0.lerp(tip, 0.55), 0.1, 0.1, tube)
	_xbeam(st, xf, keel0, keel1, 0.22, 0.3, Color("#3a3d42"))
	# The roundel on the keel's front: a yellow octagon (0.9 m) with the red M.
	var rc := keel0 + Vector3(0, 0.6, -0.2)
	for i in 8:
		var a0 := TAU * (i + 0.5) / 8
		var a1 := TAU * (i + 1.5) / 8
		for s: float in [-1.0, 1.0]:
			tri(st, xf * (rc + Vector3(0, 0, 0.04 * s)), xf * (rc + Vector3(0.45 * cos(a0), 0.45 * sin(a0), 0.04 * s)),
					xf * (rc + Vector3(0.45 * cos(a1), 0.45 * sin(a1), 0.04 * s)), basis * Vector3(0, 0, s), Color("#f6c813"), LIT_SIGN)
	_metro_m(st, xf, rc, 0.065, [-1.0], 0.08, Color("#d3202a"))


## One glass pane (a quad, both faces) between four points of an entrance's local frame.
static func _xpane(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, colour: Color, part := FIXED) -> void:
	var wa := xf * a
	var wb := xf * b
	var wc := xf * c
	var wd := xf * d
	var n := (wb - wa).cross(wc - wa).normalized()
	for s: float in [1.0, -1.0]:
		tri(st, wa, wb, wc, n * s, colour, part)
		tri(st, wa, wc, wd, n * s, colour, part)


## The "crystal" metro pavilions of Stadion Narodowy, Centrum Nauki Kopernik and Dworzec Gdanski
## (street photos, Mapillary CC BY-SA, 2026-11-07): one big leaning glass prism over the escalators,
## its front lip low over the mouth and the roof climbing to a 4.3 m ridge before a steep back pane
## drops to the ground, glazed sides, a lattice of diagonal tubes on the roof, and low concrete
## ramp walls each side. `form` picks the glass: "crystal" Stadion Narodowy's teal, "crystal_aqua"
## Kopernik's pale aqua-green, "crystal_clear" Gdanski's clear glass in a dark steel frame.
## Local frame as add_metro_entrance's (open front -z). ~120 triangles.
static func _metro_crystal(st: SurfaceTool, xf: Transform3D, form: String) -> void:
	var glass := Color("#46b3a3")
	var frame := Color("#cfd6d8")
	if form == "crystal_aqua":
		glass = Color("#9fd2d0")
		frame = Color("#e4e8ea")
	elif form == "crystal_clear":
		glass = Color("#bdd6df")
		frame = Color("#3d4247")
	var concrete := Color("#8f8d88")
	var hw := 1.9
	var z0 := -2.3
	var z1 := 2.3
	var zt := 1.0
	var fl := Vector3(-hw, 1.7, z0)
	var fr := Vector3(hw, 1.7, z0)
	var tl := Vector3(-hw, 4.3, zt)
	var tr := Vector3(hw, 4.3, zt)
	var bl := Vector3(-hw, 0.5, z1)
	var br := Vector3(hw, 0.5, z1)
	# The concrete ramp walls beside the opening and the plinth behind the back pane.
	for x in [-hw - 0.15, hw + 0.15]:
		_xbox(st, xf, Vector3(x, 0.25, 0.0), Vector3(0.3, 0.5, z1 - z0 + 0.4), concrete)
	_xbox(st, xf, Vector3(0, 0.25, z1 + 0.15), Vector3(2 * hw + 0.6, 0.5, 0.3), concrete)
	# The panes: the roof, the back, and a side each (a trapezoid from the lip to the ridge to the plinth).
	_xpane(st, xf, fl, fr, tr, tl, glass, LIT_WINDOW)
	_xpane(st, xf, tl, tr, br, bl, glass, LIT_WINDOW)
	for side: float in [-1.0, 1.0]:
		var a := Vector3(side * hw, 0.5, z0)
		var f := Vector3(side * hw, 1.7, z0)
		var t := Vector3(side * hw, 4.3, zt)
		var b := Vector3(side * hw, 0.5, z1)
		_xpane(st, xf, a, f, t, b, glass, LIT_WINDOW)
	# The tubes: the lip, the ridge, the edges, and an X over the roof and over each side.
	_xbeam(st, xf, fl, fr, 0.12, 0.12, frame)
	_xbeam(st, xf, tl, tr, 0.14, 0.14, frame)
	_xbeam(st, xf, bl, br, 0.1, 0.1, frame)
	for side: float in [-1.0, 1.0]:
		var f := Vector3(side * hw, 1.7, z0)
		var t := Vector3(side * hw, 4.3, zt)
		var b := Vector3(side * hw, 0.5, z1)
		var a := Vector3(side * hw, 0.5, z0)
		_xbeam(st, xf, f, t, 0.12, 0.12, frame)
		_xbeam(st, xf, t, b, 0.12, 0.12, frame)
		_xbeam(st, xf, a, f, 0.12, 0.12, frame)
		_xbeam(st, xf, a, t, 0.07, 0.07, frame)
		_xbeam(st, xf, f, b, 0.07, 0.07, frame)
	_xbeam(st, xf, fl, tr, 0.07, 0.07, frame)
	_xbeam(st, xf, fr, tl, 0.07, 0.07, frame)
	_xbeam(st, xf, tl, br, 0.07, 0.07, frame)
	_xbeam(st, xf, tr, bl, 0.07, 0.07, frame)


## Metro Nowy Swiat-Uniwersytet's entrances (street photos, Mapillary CC BY-SA, 2026-11-07): a
## plain glass box on the pavement, violet-blue glass between slim steel mullions under a flat
## roof with a deep fascia, open at the front over the stairs. 2.7 m high. Local frame as
## add_metro_entrance's (open front -z). ~80 triangles.
static func _metro_box(st: SurfaceTool, xf: Transform3D) -> void:
	var glass := Color("#4b4a96")
	var steel := Color("#34363c")
	var hw := 1.6
	var z0 := -2.2
	var z1 := 2.2
	var h := 2.7
	# The side panes and the back pane, both faces, with a mullion every 1.1 m.
	for side: float in [-1.0, 1.0]:
		_xpane(st, xf, Vector3(side * hw, 0.3, z0), Vector3(side * hw, h, z0), Vector3(side * hw, h, z1), Vector3(side * hw, 0.3, z1), glass, LIT_WINDOW)
		for z in [z0, -1.1, 0.0, 1.1, z1]:
			_xbox(st, xf, Vector3(side * hw, h * 0.5 + 0.15, z), Vector3(0.08, h - 0.3, 0.08), steel)
		_xbox(st, xf, Vector3(side * hw, 0.15, 0.0), Vector3(0.14, 0.3, z1 - z0), steel)
	_xpane(st, xf, Vector3(-hw, 0.3, z1), Vector3(-hw, h, z1), Vector3(hw, h, z1), Vector3(hw, 0.3, z1), glass, LIT_WINDOW)
	_xbox(st, xf, Vector3(0, 0.15, z1), Vector3(2 * hw, 0.3, 0.14), steel)
	# The flat roof slab with its fascia, a lit band over the open mouth.
	_xbox(st, xf, Vector3(0, h + 0.08, 0.0), Vector3(2 * hw + 0.3, 0.16, z1 - z0 + 0.3), steel)
	_xbox(st, xf, Vector3(0, h - 0.18, z0 - 0.1), Vector3(2 * hw + 0.3, 0.36, 0.1), Color("#e9ecef"), LIT_SIGN)
	_metro_m(st, xf, Vector3(0, h - 0.18, z0 - 0.16), 0.032, [-1.0], 0.04, Color("#d3202a"))


## A beam between two points of an entrance's local frame, `w` wide along its z, through `xf`.
static func _xbeam(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, w: float, t: float, colour: Color, part := FIXED) -> void:
	beam(st, xf * a, xf * b, w, t, colour, xf.basis * Vector3.UP, part)


## The cream pixel M facing -z (sides -1) and/or +z (1) on a plate centred at `c` (local frame).
## `thick` is the plate's thickness (the M stands 5 mm off each face).
static func _metro_m(st: SurfaceTool, xf: Transform3D, c: Vector3, px: float, sides: Array, thick := 0.14, ink := Color("#fbf7ee")) -> void:
	var cream := ink
	var w := PixelFont.width("M") * px
	var top := (PixelFont.BODY + 3.5) * px
	var basis := xf.basis.orthonormalized()
	for side: float in sides:
		# side -1 faces -z (its reader looks +z, -x on the right); side 1 the back.
		var right := basis * Vector3(side, 0, 0)
		var origin := xf * (c + Vector3(-side * w * 0.5, top, side * (thick * 0.5 + 0.005)))
		PixelFont.add_quads(st, "M", origin, right, Vector3.DOWN, px, cream, LIT_SIGN)


## A Pędzik rider (parodies.md 4.1), ≤ 300 triangles, facing -z: a dark bike (boxes), the rider
## in a white helmet, a magenta jacket and dark trousers, and the 0.45 m cube backpack in magenta
## with a cream band round its middle and our own mark (a wheel with three speed lines) on the
## sides in vertex-coloured pixels. No sun shadow (small_casters' rule: its own MultiMesh).
## Loop couriers: a two-shape family (actor.gdshader's morph, INSTANCE_CUSTOM.a): shape 0 riding,
## shape 1 (`PEDZIK_STANDING`) the courier waiting at a kebab stand, standing on the bike's right
## (+x) with his legs straight and his arms down, the bike parked beside him. A MeshInstance3D (the
## courier race's rider) draws shape 0.
static func pedzik_rider() -> ArrayMesh:
	return Models.family([_pedzik_pose(false), _pedzik_pose(true)])


## One of pedzik_rider's shapes: the same parts in the same order (the family's rule), riding or
## standing beside the bike.
static func _pedzik_pose(standing: bool) -> Models.Shape:
	var sh := Models.Shape.new()
	var dark := Models.fin(Color("#3a3b3f"))
	var magenta := Models.fin(Color("#c23a7e"))
	var cream := Models.fin(Color("#fbf7ee"))
	var legs := Models.fin(Color("#2d3442"))
	for z in [-0.52, 0.52]:
		sh.box(Vector3(0, 0.33, z), Vector3(0.05, 0.64, 0.64), Models.fin(Models.TYRE))
	sh.box(Vector3(0, 0.62, 0), Vector3(0.05, 0.06, 0.98), dark)
	sh.box(Vector3(0, 1.0, -0.46), Vector3(0.5, 0.04, 0.04), dark)
	sh.box(Vector3(0, 0.88, 0.25), Vector3(0.12, 0.05, 0.2), dark)
	# The rider: on the saddle, or a step to the bike's right, standing.
	if standing:
		sh.xform = Transform3D(Basis.IDENTITY, Vector3(0.62, 0.0, 0.12))
	for x in [-0.1, 0.1]:
		if standing:
			sh.box(Vector3(x, 0.47, 0.0), Vector3(0.14, 0.94, 0.16), legs, true)
		else:
			sh.box(Vector3(x, 0.62, 0.0), Vector3(0.14, 0.56, 0.16), legs, true)
	sh.box(Vector3(0, 1.22, 0.1), Vector3(0.42, 0.55, 0.26), magenta)
	if standing:
		sh.box(Vector3(0, 1.12, 0.08), Vector3(0.52, 0.44, 0.12), magenta, true)
	else:
		sh.box(Vector3(0, 1.1, -0.2), Vector3(0.52, 0.1, 0.42), magenta, true)
	sh.box(Vector3(0, 1.62, 0.02), Vector3(0.24, 0.24, 0.24), Models.fin(Color("#e2b48c")))
	sh.box(Vector3(0, 1.76, 0.03), Vector3(0.28, 0.1, 0.3), Models.fin(Color("#f4f4f0")), true)
	# The backpack and its band.
	sh.box(Vector3(0, 1.38, 0.45), Vector3(0.45, 0.45, 0.45), magenta, true)
	sh.box(Vector3(0, 1.38, 0.45), Vector3(0.47, 0.08, 0.47), cream, true)
	# The mark on both sides: a wheel (a ring of 8 pixels) and three speed lines, one-sided quads.
	var mark := [Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(3, 1), Vector2(0, 2), Vector2(3, 2), Vector2(1, 3), Vector2(2, 3)]
	var px := 0.035
	for side in [-1.0, 1.0]:
		var n := Vector3(side, 0, 0)
		for m: Vector2 in mark:
			_shape_face(sh, Vector3(0.227 * side, 1.56 - m.y * px, 0.5 - m.x * px), Vector3(0, 0, px * 0.5), Vector3(0, px * 0.5, 0), n, cream)
		for k in 3:
			_shape_face(sh, Vector3(0.227 * side, 1.56 - k * px * 1.4, 0.61), Vector3(0, 0, px), Vector3(0, px * 0.3, 0), n, cream)
	return sh


## A one-sided quad on a Shape, facing `n` (`u`, `v` its half sides).
static func _shape_face(sh: Models.Shape, c: Vector3, u: Vector3, v: Vector3, n: Vector3, f: Array) -> void:
	sh.quad(c - u - v, c + u - v, c + u + v, c - u + v, f, n)


## A kebab stand with its name on a smaller board under KEBAB (parodies.md 6.1: U ZDZICHA at
## Hala Mirowska, NA CIENKIM on Plac Zbawiciela), facing -z like kebab_stand().
static func named_kebab_stand(name: String) -> ArrayMesh:
	var st := _begin()
	var base := kebab_stand()
	st.append_from(base, 0, Transform3D.IDENTITY)
	var px := 0.045
	var w := PixelFont.width(name) * px
	var bw := w + 0.3
	var y := 2.85
	box(st, Vector3(0, y, 0), Vector3(bw, 0.56, 0.14), Color("#2b2730"))
	var gold := Color("#ffd23f")
	var top := y + (PixelFont.BODY + 3.5) * px
	PixelFont.add_quads(st, name, Vector3(w * 0.5, top, -0.075), Vector3.LEFT, Vector3.DOWN, px, gold, LIT_SIGN)
	PixelFont.add_quads(st, name, Vector3(-w * 0.5, top, 0.075), Vector3.RIGHT, Vector3.DOWN, px, gold, LIT_SIGN)
	return st.commit()


# --- the first scene's street (first-scene.md items 4 and 5) -------------------------------------

## A newspaper kiosk, 2.6 m wide and 1.9 m deep, its front (the hatch) towards -z: a green steel
## box on a dark plinth, a wide hatch lit at night with a rack of magazines under it, a flat roof
## overhanging all round, and PRASA (press) in cream pixel letters on the front fascia. ~240 tris.
static func add_kiosk(st: SurfaceTool, xf: Transform3D) -> void:
	var green := Color("#2f6b4f")
	var cream := Color("#efe6cf")
	var dark := Color("#2b2730")
	_xbox(st, xf, Vector3(0, 0.1, 0), Vector3(2.6, 0.2, 1.9), dark)
	_xbox(st, xf, Vector3(0, 1.2, 0), Vector3(2.5, 2.0, 1.8), green)
	_xbox(st, xf, Vector3(0, 1.45, -0.91), Vector3(1.9, 0.75, 0.04), Color("#f3cf8a"), LIT_WINDOW)
	_xbox(st, xf, Vector3(0, 1.04, -1.02), Vector3(2.1, 0.06, 0.26), cream)
	# The rack: rows of magazine covers in the hatch's lower half and on the side.
	var covers := [Color("#e07a5f"), Color("#81b29a"), Color("#f2cc8f"), Color("#9db4d8"), Color("#e8a6b8"), Color("#f4f1de")]
	for k in 6:
		_xbox(st, xf, Vector3(-0.85 + k * 0.34, 0.68, -0.93), Vector3(0.26, 0.34, 0.03), covers[k])
		_xbox(st, xf, Vector3(1.27, 0.95 + (k % 3) * 0.36, -0.55 + floorf(k / 3.0) * 0.5), Vector3(0.03, 0.3, 0.4), covers[(k + 2) % 6])
	_xbox(st, xf, Vector3(0, 2.28, 0), Vector3(2.9, 0.16, 2.2), cream)
	_xbox(st, xf, Vector3(0, 2.02, -0.92), Vector3(2.5, 0.36, 0.04), cream)
	var px := 0.06
	var word := "PRASA"
	var tw := PixelFont.width(word) * px
	var top := 2.02 + (PixelFont.BODY + 3.5) * px
	PixelFont.add_quads(st, word, xf * Vector3(tw * 0.5, top, -0.95), xf.basis.orthonormalized() * Vector3.LEFT,
			Vector3.DOWN, px, Color("#1f4a36"), LIT_SIGN)


## A round concrete planter (Warsaw's street bowls), 1.2 m across and 0.6 m tall, full of
## flowers of one colour among green leaves. ~110 tris.
static func add_planter(st: SurfaceTool, xf: Transform3D, flower: Color) -> void:
	var stone := Color("#b9b5ac")
	var turn := Basis(Vector3.UP, PI / 4.0)
	_xbox(st, xf, Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 0.62), stone)
	_xbox(st, xf, Vector3(0, 0.3, 0), Vector3(0.62, 0.6, 1.2), stone)
	obox(st, xf * Vector3(0, 0.3, 0), (xf.basis * turn).orthonormalized(), Vector3(1.05, 0.6, 1.05), stone)
	_xbox(st, xf, Vector3(0, 0.66, 0), Vector3(0.95, 0.14, 0.95), Color("#4f7a3a"))
	for p: Vector3 in [Vector3(-0.25, 0, -0.2), Vector3(0.22, 0, -0.25), Vector3(0.0, 0, 0.05), Vector3(-0.22, 0, 0.27), Vector3(0.27, 0, 0.22)]:
		_xbox(st, xf, p + Vector3(0, 0.82, 0), Vector3(0.2, 0.16, 0.2), flower)


## A café table for two under a square parasol, 2.6 m across: a round-ish table, two chairs,
## the pole and a two-tier canopy in `canopy` with a cream valance. ~150 tris.
static func add_cafe_set(st: SurfaceTool, xf: Transform3D, canopy: Color) -> void:
	var metal := Color("#3a3b3f")
	var top := Color("#e9e4d8")
	_xbox(st, xf, Vector3(0, 0.37, 0), Vector3(0.08, 0.74, 0.08), metal)
	_xbox(st, xf, Vector3(0, 0.75, 0), Vector3(0.7, 0.04, 0.7), top)
	for z: float in [-0.6, 0.6]:
		_xbox(st, xf, Vector3(0, 0.23, z), Vector3(0.42, 0.46, 0.4), Color("#8a5a34"))
		_xbox(st, xf, Vector3(0, 0.62, z + signf(z) * 0.18), Vector3(0.42, 0.42, 0.05), Color("#8a5a34"))
	_xbox(st, xf, Vector3(0, 1.3, 0), Vector3(0.06, 2.6, 0.06), metal)
	_xbox(st, xf, Vector3(0, 2.35, 0), Vector3(2.6, 0.08, 2.6), canopy)
	_xbox(st, xf, Vector3(0, 2.47, 0), Vector3(1.5, 0.16, 1.5), canopy.lightened(0.08))
	for k in 4:
		var side := Basis(Vector3.UP, k * PI / 2.0)
		obox(st, xf * (side * Vector3(0, 2.24, 1.29)), (xf.basis * side).orthonormalized(), Vector3(2.6, 0.16, 0.03), Color("#f4efe2"))


## A patio heater (a café garden's gas "mushroom", Nowy Świat pass 2): a round base, a 2.1 m steel
## pole, a reflector hood and the warm burner ring under it. ~50 tris.
static func add_patio_heater(st: SurfaceTool, xf: Transform3D) -> void:
	var steel := Color("#8e949a")
	_xbox(st, xf, Vector3(0, 0.03, 0), Vector3(0.46, 0.06, 0.46), Color("#3a3b3f"))
	_xbox(st, xf, Vector3(0, 1.06, 0), Vector3(0.07, 2.0, 0.07), steel)
	_xbox(st, xf, Vector3(0, 2.02, 0), Vector3(0.22, 0.14, 0.22), Color("#ff9a3c"))
	_xbox(st, xf, Vector3(0, 2.14, 0), Vector3(0.78, 0.05, 0.78), steel)
	_xbox(st, xf, Vector3(0, 2.2, 0), Vector3(0.44, 0.07, 0.44), steel.lightened(0.1))


## A flower stall (a kwiaciarnia's table on the pavement), 2.2 m wide: a green trestle with rows
## of buckets of flowers stepping up to the back, a striped awning on four posts, KWIATY on a
## board over the front. ~330 tris.
static func add_flower_stall(st: SurfaceTool, xf: Transform3D) -> void:
	var green := Color("#3e6b4a")
	var cream := Color("#f4efe2")
	var bucket := Color("#5d6b74")
	_xbox(st, xf, Vector3(0, 0.4, 0), Vector3(2.2, 0.8, 1.2), green)
	var blooms := [Color("#e63946"), Color("#f4a261"), Color("#ffd23f"), Color("#e8a6b8"), Color("#f4f1de"), Color("#9b5de5")]
	for row in 3:
		for k in 5:
			var p := Vector3(-0.84 + k * 0.42, 0.8 + row * 0.18, -0.4 + row * 0.38)
			_xbox(st, xf, p + Vector3(0, 0.12, 0), Vector3(0.3, 0.24, 0.3), bucket)
			_xbox(st, xf, p + Vector3(0, 0.34, 0), Vector3(0.36, 0.22, 0.34), blooms[(k + row * 2) % blooms.size()])
	for x: float in [-1.15, 1.15]:
		for z: float in [-0.7, 0.7]:
			_xbox(st, xf, Vector3(x, 1.1, z), Vector3(0.06, 2.2, 0.06), Color("#3a3b3f"))
	for k in 6:
		_xbox(st, xf, Vector3(-1.0 + k * 0.4, 2.2 + (0.05 if k % 2 == 0 else 0.0), -0.05), Vector3(0.4, 0.06, 1.7),
				Color("#c8282a") if k % 2 == 0 else cream)
	_xbox(st, xf, Vector3(0, 2.45, -0.88), Vector3(1.7, 0.4, 0.05), cream)
	var px := 0.07
	var word := "KWIATY"
	var tw := PixelFont.width(word) * px
	var top := 2.45 + (PixelFont.BODY + 3.5) * px
	PixelFont.add_quads(st, word, xf * Vector3(tw * 0.5, top, -0.92), xf.basis.orthonormalized() * Vector3.LEFT,
			Vector3.DOWN, px, Color("#c8282a"), LIT_SIGN)


## An advertising column (a litfaza): a green foot, an eight-sided drum of posters in `poster`
## with a pale band, and a dark green cap with a finial; 1.2 m across, 3.3 m tall. ~110 tris.
static func add_ad_column(st: SurfaceTool, xf: Transform3D, poster: Color) -> void:
	var green := Color("#28503c")
	var turn := (xf.basis * Basis(Vector3.UP, PI / 8.0)).orthonormalized()
	var turn2 := (xf.basis * Basis(Vector3.UP, -PI / 8.0)).orthonormalized()
	obox(st, xf * Vector3(0, 0.25, 0), turn, Vector3(1.3, 0.5, 1.3), green)
	obox(st, xf * Vector3(0, 1.55, 0), turn, Vector3(1.15, 2.1, 1.15), poster)
	obox(st, xf * Vector3(0, 1.55, 0), turn2, Vector3(1.15, 2.1, 1.15), poster.lightened(0.15))
	obox(st, xf * Vector3(0, 2.2, 0), turn, Vector3(1.18, 0.3, 1.18), Color("#f4f1de"))
	obox(st, xf * Vector3(0, 2.75, 0), turn2, Vector3(1.4, 0.2, 1.4), green)
	obox(st, xf * Vector3(0, 2.95, 0), turn, Vector3(1.0, 0.25, 1.0), green)
	_xbox(st, xf, Vector3(0, 3.25, 0), Vector3(0.12, 0.35, 0.12), Color("#c9a44a"))


## Pasaż Wiecha's lamp mast (the Mac photo report dt_pawilony, 2026-11-02): a single white pole
## that splits at 6 m into two flat arms climbing out along ±z, each ending in a long flat lamp
## blade (lit underneath at night), about 10 m tall. ~90 triangles.
static func add_y_mast(st: SurfaceTool, xf: Transform3D) -> void:
	# F's look check (2026-11-03): the white Y masts come first on the pasaż, so they stand as
	# in the photo: a stout pole to 7.4 m, two thick arms out to 11 m, long wide lamp blades.
	var white := Color("#f2f2ee")
	_xbox(st, xf, Vector3(0, 0.2, 0), Vector3(0.6, 0.4, 0.6), Color("#5d6166"))
	_xbox(st, xf, Vector3(0, 3.7, 0), Vector3(0.36, 7.4, 0.36), white)
	for side: float in [-1.0, 1.0]:
		_xbeam(st, xf, Vector3(0, 7.1, 0), Vector3(0, 11.0, side * 1.8), 0.24, 0.18, white)
		var tilt := Basis(Vector3.RIGHT, -side * 0.12)
		var c := xf * Vector3(0, 11.1, side * 2.7)
		obox(st, c, (xf.basis * tilt).orthonormalized(), Vector3(0.5, 0.14, 2.2), white)
		obox(st, c + xf.basis * Vector3(0, -0.08, 0), (xf.basis * tilt).orthonormalized(), Vector3(0.36, 0.03, 2.0),
				Color("#fff4dc"), LIT_SIGN)


## A row of `n` street bollards (a dark steel post 0.9 m tall with a pale band, 1.5 m apart along
## x), the row centred on `xf`. ~25 triangles a post. (Street details, docs/design/street-details.md.)
static func add_bollards(st: SurfaceTool, xf: Transform3D, n := 4) -> void:
	for k in n:
		var x := (k - (n - 1) * 0.5) * 1.5
		_xbox(st, xf, Vector3(x, 0.45, 0), Vector3(0.16, 0.9, 0.16), Color("#2b2f36"))
		_xbox(st, xf, Vector3(x, 0.78, 0), Vector3(0.18, 0.08, 0.18), Color("#e8e3d4"))


## The start area as real Warsaw (R7, docs/design/start-area-real.md): Warsaw's street name plate
## (the city information system's: a navy plate, the name in white, a red strip along the foot for
## the district) on a grey pole at a crossing. `along` is the street the plate runs along (its faces
## look at -z and +z), `across` the side street's, a plate lower down turned a quarter. Both faces
## carry the name, so the camera reads one of them either way. ~400 triangles with the letters.
static func add_street_plates(st: SurfaceTool, xf: Transform3D, along: String, across: String) -> void:
	_xbox(st, xf, Vector3(0, 1.6, 0), Vector3(0.08, 3.2, 0.08), Color("#8d939a"))
	_street_plate(st, xf, Vector3(0, 3.0, 0), along)
	if across != "":
		var turned := Transform3D(xf.basis * Basis(Vector3.UP, PI * 0.5), xf.origin)
		_street_plate(st, turned, Vector3(0, 2.55, 0), across)


## One plate at `centre` (local to `xf`), its faces looking at -z and +z.
static func _street_plate(st: SurfaceTool, xf: Transform3D, centre: Vector3, name: String) -> void:
	var px := 0.03
	var w := PixelFont.width(name) * px + 0.16
	_xbox(st, xf, centre, Vector3(w, 0.36, 0.04), Color("#1d2f5c"))
	_xbox(st, xf, centre + Vector3(0, -0.15, 0), Vector3(w + 0.005, 0.07, 0.045), Color("#c8282a"))
	var b := xf.basis.orthonormalized()
	var top := centre.y + 0.15
	for side in [-1.0, 1.0]:
		# A reader on the `side` face: their right is -X on the -z face and +X on the +z one.
		var right: Vector3 = b * Vector3(side, 0, 0)
		var at: Vector3 = xf * Vector3(centre.x + side * -0.5 * (w - 0.16), top, centre.z + side * 0.025)
		PixelFont.add_quads(st, name, at, right, Vector3.DOWN, px, Color("#f2f2ee"), FIXED)


## Krajobraz K2 (ul. Chmielna, 2026-11-02): a memorial stone, a rough grey granite boulder about
## 1.2 m wide and 0.95 m tall (two offset blocks and a cap), a dark bronze plaque on its -z face.
## Ali's stone by Pasaż Wiecha (August Agbola Browne, 2019). ~60 triangles.
static func add_memorial_stone(st: SurfaceTool, xf: Transform3D) -> void:
	var granite := Color("#8e8b86")
	_xbox(st, xf, Vector3(0, 0.38, 0), Vector3(1.2, 0.76, 0.8), granite)
	_xbox(st, xf, Vector3(0.12, 0.7, 0.05), Vector3(0.86, 0.5, 0.66), granite.lightened(0.08))
	_xbox(st, xf, Vector3(-0.05, 0.9, 0.08), Vector3(0.5, 0.12, 0.42), granite.darkened(0.06))
	_xbox(st, xf, Vector3(0.02, 0.56, -0.41), Vector3(0.56, 0.36, 0.03), Color("#5a4630"))
	_xbox(st, xf, Vector3(0.02, 0.56, -0.425), Vector3(0.46, 0.04, 0.01), Color("#b08d57"))


## R7: a city bike dock (a parody of the city's hire bikes): a row of `n` docked bikes, mint
## mudguards on grey frames, in grey stands, and a terminal post at the -x end with the word
## ROWERY (bikes) on its head. The bikes lean along x, the riders' side at -z. ~110 triangles a bike.
static func add_bike_dock(st: SurfaceTool, xf: Transform3D, n := 6) -> void:
	var grey := Color("#7c838b")
	var mint := Color("#3fbfa0")
	var tyre := Color("#24272b")
	for k in n:
		var z := (k - (n - 1) * 0.5) * 0.85
		_xbox(st, xf, Vector3(0.75, 0.4, z), Vector3(0.1, 0.8, 0.12), grey)
		_xbox(st, xf, Vector3(-0.45, 0.33, z), Vector3(0.66, 0.66, 0.05), tyre)
		_xbox(st, xf, Vector3(0.45, 0.33, z), Vector3(0.66, 0.66, 0.05), tyre)
		_xbox(st, xf, Vector3(-0.45, 0.33, z), Vector3(0.5, 0.5, 0.06), Color("#cfd3d6"))
		_xbox(st, xf, Vector3(0.45, 0.33, z), Vector3(0.5, 0.5, 0.06), Color("#cfd3d6"))
		_xbox(st, xf, Vector3(0.0, 0.6, z), Vector3(0.9, 0.08, 0.07), grey)
		_xbox(st, xf, Vector3(-0.45, 0.68, z), Vector3(0.55, 0.06, 0.12), mint)
		_xbox(st, xf, Vector3(0.45, 0.68, z), Vector3(0.5, 0.06, 0.12), mint)
		_xbox(st, xf, Vector3(-0.2, 0.92, z), Vector3(0.2, 0.06, 0.14), tyre)
		_xbox(st, xf, Vector3(0.55, 1.0, z), Vector3(0.06, 0.06, 0.5), grey)
		_xbox(st, xf, Vector3(0.7, 0.9, z), Vector3(0.3, 0.22, 0.26), mint)
	var end := -(n - 1) * 0.5 * 0.85 - 0.9
	_xbox(st, xf, Vector3(0.4, 0.9, end), Vector3(0.4, 1.8, 0.3), Color("#2b2f36"))
	_xbox(st, xf, Vector3(0.4, 1.35, end), Vector3(0.42, 0.3, 0.2), Color("#9fe0c8"), LIT_WINDOW)
	_xbox(st, xf, Vector3(0.4, 1.86, end), Vector3(0.5, 0.22, 0.85), mint)
	var px := 0.022
	var word := "ROWERY"
	var tw := PixelFont.width(word) * px
	var b := xf.basis.orthonormalized()
	PixelFont.add_quads(st, word, xf * Vector3(0.66, 1.86 + 0.11, end + tw * 0.5), b * Vector3.FORWARD, Vector3.DOWN, px,
			Color("#f2f2ee"), LIT_SIGN)


## R7: Warsaw's glass tram shelter, as the map's shared shelter (map_builder.gd) but into a
## street-prop mesh: a graphite roof with a red edge, a glass back and end, red posts, a bench
## and a poster box. The tracks are on its -z side. ~250 triangles.
static func add_tram_shelter(st: SurfaceTool, xf: Transform3D) -> void:
	var glass := Color("#b8d3df")
	var graphite := Color("#33363b")
	var red := Color("#c8282a")
	_xbox(st, xf, Vector3(0, 2.5, 0.08), Vector3(4.3, 0.12, 1.95), graphite)
	_xbox(st, xf, Vector3(0, 2.57, 0.08), Vector3(4.0, 0.03, 1.7), Color("#a7c2cf"))
	_xbox(st, xf, Vector3(0, 2.38, -0.86), Vector3(4.3, 0.3, 0.06), red)
	_xbox(st, xf, Vector3(0, 1.3, 0.75), Vector3(3.85, 2.05, 0.04), glass)
	_xbox(st, xf, Vector3(-1.95, 1.3, 0.17), Vector3(0.04, 2.05, 1.15), glass)
	for x in [-1.95, 0.0, 1.95]:
		_xbox(st, xf, Vector3(x, 1.25, 0.78), Vector3(0.09, 2.5, 0.09), red)
	_xbox(st, xf, Vector3(1.95, 1.2, 0.12), Vector3(0.2, 1.95, 1.3), graphite)
	for sx in [-0.11, 0.11]:
		_xbox(st, xf, Vector3(1.95 + sx, 1.45, 0.12), Vector3(0.02, 1.1, 1.12), Color("#f0c94a"), LIT_WINDOW)
	_xbox(st, xf, Vector3(-0.2, 0.46, 0.5), Vector3(2.2, 0.06, 0.38), Color("#5c6168"))
	for x in [-1.1, 0.7]:
		_xbox(st, xf, Vector3(x, 0.22, 0.5), Vector3(0.06, 0.44, 0.3), graphite)


## A stop post (a tram or bus stop's pole): a 2.6 m grey pole, a round yellow-green plate facing the
## street and a timetable box under it. ~70 triangles.
static func add_stop_post(st: SurfaceTool, xf: Transform3D) -> void:
	_xbox(st, xf, Vector3(0, 1.3, 0), Vector3(0.08, 2.6, 0.08), Color("#5d6168"))
	_xbox(st, xf, Vector3(0, 2.5, -0.06), Vector3(0.5, 0.5, 0.04), Color("#c9d94a"))
	_xbox(st, xf, Vector3(0, 2.5, -0.09), Vector3(0.3, 0.3, 0.03), Color("#2b2f36"))
	_xbox(st, xf, Vector3(0, 1.75, -0.08), Vector3(0.4, 0.55, 0.05), Color("#eeeadc"))


## A tram-stop bench (ławka): a 1.8 m slatted seat and back on two graphite feet, the back to
## +z (away from the street), like the stop kits. ~60 triangles.
static func add_stop_bench(st: SurfaceTool, xf: Transform3D) -> void:
	var wood := Color("#8a6a45")
	var graphite := Color("#33363b")
	_xbox(st, xf, Vector3(0, 0.46, 0.0), Vector3(1.8, 0.06, 0.42), wood)
	_xbox(st, xf, Vector3(0, 0.78, 0.22), Vector3(1.8, 0.34, 0.05), wood)
	for x in [-0.78, 0.78]:
		_xbox(st, xf, Vector3(x, 0.22, 0.0), Vector3(0.07, 0.44, 0.4), graphite)
		_xbox(st, xf, Vector3(x, 0.6, 0.22), Vector3(0.07, 0.6, 0.07), graphite)


## A ticket machine (BILETY, tickets): a 1.7 m grey-and-yellow box with a lit screen and the word in
## pixel letters on its head. ~120 triangles.
static func add_ticket_machine(st: SurfaceTool, xf: Transform3D) -> void:
	_xbox(st, xf, Vector3(0, 0.85, 0), Vector3(0.6, 1.7, 0.45), Color("#6d7076"))
	_xbox(st, xf, Vector3(0, 1.25, -0.23), Vector3(0.4, 0.3, 0.03), Color("#9fe0c8"), LIT_WINDOW)
	_xbox(st, xf, Vector3(0, 0.85, -0.23), Vector3(0.4, 0.12, 0.03), Color("#e6c23a"))
	_xbox(st, xf, Vector3(0, 1.62, -0.23), Vector3(0.52, 0.16, 0.03), Color("#e6c23a"))
	var px := 0.025
	var word := "BILETY"
	var tw := PixelFont.width(word) * px
	PixelFont.add_quads(st, word, xf * Vector3(tw * 0.5, 1.62 + (PixelFont.BODY + 3.5) * px * 0.5, -0.26),
			xf.basis.orthonormalized() * Vector3.LEFT, Vector3.DOWN, px, Color("#2b2f36"), LIT_SIGN)


## An ice-cream cart (LODY, ice cream): a white box on two wheels with a striped awning on two
## posts and the word on a board; 1.6 m wide. ~200 triangles.
static func add_ice_cream_cart(st: SurfaceTool, xf: Transform3D, awning: Color) -> void:
	var cream := Color("#f4efe2")
	_xbox(st, xf, Vector3(0, 0.75, 0), Vector3(1.6, 0.9, 1.0), cream)
	_xbox(st, xf, Vector3(0, 1.22, -0.05), Vector3(1.5, 0.06, 0.9), Color("#9db4d8"))
	for x: float in [-0.85, 0.85]:
		_xbox(st, xf, Vector3(x, 0.3, 0.1), Vector3(0.08, 0.6, 0.6), Color("#2b2f36"))
		_xbox(st, xf, Vector3(x * 0.55, 1.65, -0.45), Vector3(0.05, 1.0, 0.05), Color("#3a3b3f"))
	for k in 5:
		_xbox(st, xf, Vector3(-0.8 + k * 0.4, 2.2 + (0.04 if k % 2 == 0 else 0.0), -0.1), Vector3(0.4, 0.05, 1.4), awning if k % 2 == 0 else cream)
	_xbox(st, xf, Vector3(0, 0.95, -0.52), Vector3(1.0, 0.3, 0.03), awning.lightened(0.2))
	var px := 0.06
	var word := "LODY"
	var tw := PixelFont.width(word) * px
	PixelFont.add_quads(st, word, xf * Vector3(tw * 0.5, 0.95 + (PixelFont.BODY + 3.5) * px * 0.5, -0.55),
			xf.basis.orthonormalized() * Vector3.LEFT, Vector3.DOWN, px, Color("#2b2f36"), LIT_SIGN)


## A flat dark quad 2 cm over the paving, `half` (x, z) metres each way: the contact shadow of a
## tall prop whose mesh casts no sun shadow (street_details.gd draws it under kiosks, stalls,
## cafés, carts and columns). 2 triangles.
static func add_contact_pad(st: SurfaceTool, xf: Transform3D, half: Vector2) -> void:
	_xbox(st, xf, Vector3(0, 0.02, 0), Vector3(half.x * 2.0, 0.02, half.y * 2.0), Color("#6f6b68"))


## Skwer Linearny na Złotej (2026-11-02): a free-standing pale stone block on the lawn (people sit
## on them), `size` metres: the block, a slightly smaller top course set off it, chamfered by a
## turned middle course so it reads as cut stone, not a crate. 36 triangles.
static func add_stone_block(st: SurfaceTool, xf: Transform3D, size: Vector3, stone: Color) -> void:
	_xbox(st, xf, Vector3(0, size.y * 0.4, 0), Vector3(size.x, size.y * 0.8, size.z), stone)
	_xbox(st, xf, Vector3(0, size.y * 0.9, 0), Vector3(size.x * 0.88, size.y * 0.2, size.z * 0.88), stone.lightened(0.06))
	var turn := Basis(Vector3.UP, 0.12)
	obox(st, xf * Vector3(0.04, size.y * 0.5, 0), (xf.basis * turn).orthonormalized(),
			Vector3(size.x * 0.96, size.y * 0.7, size.z * 1.02), stone.darkened(0.04))


## A long park bench (Złota's square): `length` m of larch slats on three grey concrete feet, a low
## back on the +z side. ~60 triangles.
static func add_long_bench(st: SurfaceTool, xf: Transform3D, length: float) -> void:
	var concrete := Color("#a9a69e")
	var wood := Color("#a8743f")
	var feet := maxi(2, ceili(length / 2.2) + 1)
	for k in feet:
		var x := (k / float(feet - 1) - 0.5) * (length - 0.4)
		_xbox(st, xf, Vector3(x, 0.2, 0), Vector3(0.22, 0.4, 0.55), concrete)
	_xbox(st, xf, Vector3(0, 0.44, 0), Vector3(length, 0.08, 0.6), wood)
	_xbox(st, xf, Vector3(0, 0.72, 0.27), Vector3(length, 0.34, 0.06), wood.darkened(0.08))


## The rock fountain's water: a thin pale jet and the foam round its foot. 24 triangles.
static func add_spout(st: SurfaceTool, xf: Transform3D) -> void:
	var water := Color("#dfeef4")
	_xbox(st, xf, Vector3(0, 0.55, 0), Vector3(0.12, 1.1, 0.12), water)
	_xbox(st, xf, Vector3(0, 0.25, 0), Vector3(0.5, 0.5, 0.5), water.darkened(0.05))


## A slim park lamp (Złota's square): a 4.6 m graphite pole and a flat round head that glows warm
## white when the city's lights are on (LIT_SIGN). No light pool of its own (lights.bin is baked).
## 36 triangles.
static func add_park_lamp(st: SurfaceTool, xf: Transform3D) -> void:
	var pole := Color("#33373c")
	_xbox(st, xf, Vector3(0, 0.15, 0), Vector3(0.3, 0.3, 0.3), pole)
	_xbox(st, xf, Vector3(0, 2.35, 0), Vector3(0.1, 4.4, 0.1), pole)
	_xbox(st, xf, Vector3(0, 4.62, 0), Vector3(0.62, 0.14, 0.62), pole)
	_xbox(st, xf, Vector3(0, 4.52, 0), Vector3(0.5, 0.06, 0.5), Color("#fff1d0"), LIT_SIGN)
