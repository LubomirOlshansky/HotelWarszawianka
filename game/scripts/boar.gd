class_name Boar
extends RefCounted
## The wild boar (dzik), Warsaw's most famous suburban resident, as an Around Warsaw toy character
## (F, 2026-11-26: "a stylish dzik in my game's style, recognisable, with real wings, funny"): the
## chudiki's chunky voxel look (big head, clean flat colours, crisp blocks) with the boar's tells
## exaggerated so it reads at phone size: a wedge head with a pink nose disc, big white tusks, a
## punk mohawk mane, pointy black ears, a dark chocolate coat. Reusable for the "become a boar"
## quest; the feathered wings are promo only.
## A rig of rigid parts, each one vertex-coloured ArrayMesh in one shared material: body, head, two
## ears, four legs, tail (+ two two-piece wings) = 9 to 13 draw calls.
## 1.35 m snout to rump, 0.95 m to the mane's top; facing local +z, feet on y = 0.
##
## Boar.build(wings) -> rig Dictionary {root, body, head, ears[2], legs[4], tail, wings[0 or 2]}
## Boar.pose_fly(rig, t) and Boar.pose_trot(rig, t, speed) pose it; the caller moves rig.root.

# Mid-value colours (Fable's critique, 2026-11-26: a near-black coat silhouettes against the sky).
const COAT := Color("#5a3d2a")
const COAT_DARK := Color("#47301f")
const BELLY := Color("#4a3223")
const MANE := Color("#2e1f17")
const MANE_TIP := Color("#c9a26b")
const FACE := Color("#8a6a52")
const CHEEK := Color("#b49a80")
const SNOUT := Color("#a3846a")
const NOSE := Color("#b98580")
const NOSTRIL := Color("#3a1f1c")
const BLUSH := Color("#f08c8c")
const EAR := Color("#2e1f17")
const EAR_IN := Color("#9a6656")
const LEG := Color("#4a3223")
const HOOF := Color("#2a1c16")
const TUSK := Color("#ffffff")
const EYE := Color("#141014")
const BROW := Color("#2e1f17")
const FEATHER := Color("#fffaf0")
const FEATHER_SHADE := Color("#d9e2f2")
const FEATHER_TIP := Color("#eef0f6")
## The striped piglets (warchlaki): light brown with cream stripes.
const PIG_COAT := Color("#a7774f")
const PIG_STRIPE := Color("#ecd3a6")

## Wing looks (promo only).
enum Wings { NONE, FEATHERS }

static var _mat: ShaderMaterial


## One material for every part: the vertex colour as albedo plus a quarter of it as emission, so
## the shadow side never goes black against a bright sky.
static func material() -> Material:
	if _mat == null:
		_mat = ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = """shader_type spatial;
render_mode cull_disabled;
void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 0.25;
	ROUGHNESS = 0.85;
	SPECULAR = 0.3;
}"""
		_mat.shader = sh
	return _mat


# --- mesh helpers ---------------------------------------------------------------------------------

## A box from centre c and size s, turned by basis b, into the surface tool.
static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color, b := Basis()) -> void:
	_taper(st, c, Vector2(s.x, s.y), Vector2(s.x, s.y), s.z, col, b)


## A frustum along z: back face (z-) sized `back`, front face (z+) sized `front`, `len` long,
## centred on c and turned by b. The tapered blocks give the boar its wedge head and high shoulders.
static func _taper(st: SurfaceTool, c: Vector3, back: Vector2, front: Vector2, len: float, col: Color,
		b := Basis(), front_dy := 0.0) -> void:
	var h := len * 0.5
	var p := [
		Vector3(-back.x, -back.y, 0) * 0.5 + Vector3(0, 0, -h), Vector3(back.x, -back.y, 0) * 0.5 + Vector3(0, 0, -h),
		Vector3(back.x, back.y, 0) * 0.5 + Vector3(0, 0, -h), Vector3(-back.x, back.y, 0) * 0.5 + Vector3(0, 0, -h),
		Vector3(-front.x, -front.y, 0) * 0.5 + Vector3(0, front_dy, h), Vector3(front.x, -front.y, 0) * 0.5 + Vector3(0, front_dy, h),
		Vector3(front.x, front.y, 0) * 0.5 + Vector3(0, front_dy, h), Vector3(-front.x, front.y, 0) * 0.5 + Vector3(0, front_dy, h),
	]
	for i in 8:
		p[i] = c + b * (p[i] as Vector3)
	# Faces as corner index quads, wound counter-clockwise seen from outside.
	var faces := [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [0, 4, 7, 3], [1, 2, 6, 5]]
	for f in 6:
		var q: Array = faces[f]
		# Tops a touch lighter, undersides darker (the low-poly look's free AO).
		var n := ((p[q[1]] as Vector3) - (p[q[0]] as Vector3)).cross((p[q[2]] as Vector3) - (p[q[0]] as Vector3)).normalized()
		var mid := ((p[q[0]] as Vector3) + (p[q[2]] as Vector3)) * 0.5
		if n.dot(mid - c) < 0.0:
			n = -n
		var cc := col * (0.9 + 0.16 * n.y)
		cc.a = 1.0
		st.set_color(cc)
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n)
			st.add_vertex(p[q[k]])


## A frustum with its long edges bevelled (two overlapping frustums, one narrower and taller): an
## octagon in section, so the body reads round, not as a crate.
static func _round(st: SurfaceTool, c: Vector3, back: Vector2, front: Vector2, len: float, col: Color,
		b := Basis(), front_dy := 0.0, bevel := 0.22) -> void:
	_taper(st, c, Vector2(back.x, back.y * (1.0 - bevel * 1.6)), Vector2(front.x, front.y * (1.0 - bevel * 1.6)), len, col, b, front_dy)
	_taper(st, c, Vector2(back.x * (1.0 - bevel * 1.6), back.y), Vector2(front.x * (1.0 - bevel * 1.6), front.y), len, col, b, front_dy)


static func _part(parent: Node3D, at: Vector3, draw: Callable, name := "") -> Node3D:
	var j := Node3D.new()
	j.name = name
	j.position = at
	parent.add_child(j)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	draw.call(st)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material()
	j.add_child(mi)
	return j


## A row of bristle tufts along a line (the mane, the fuzz round the ears): small blocks of
## alternating height, tipped lighter, leaning back like brushed hair.
static func _bristles(st: SurfaceTool, from: Vector3, to: Vector3, n: int, w: float, h: float, col: Color, tip: Color, lean := -0.45) -> void:
	for i in n:
		var f := float(i) / float(maxi(n - 1, 1))
		var c := from.lerp(to, f)
		var hh := h * (0.7 + 0.3 * float((i * 7) % 3) / 2.0)
		var b := Basis(Vector3.RIGHT, lean)
		_box(st, c + b * Vector3(0, hh * 0.5, 0), Vector3(w, hh, w * 0.8), col, b)
		_box(st, c + b * Vector3(0, hh + 0.012, 0), Vector3(w * 0.7, 0.03, w * 0.6), tip, b)




# --- the rig ---------------------------------------------------------------------------------------

## piglet: a warchlak, the striped baby (build it as is and scale the root ~0.45): light coat with
## cream stripes, no tusks, a small crest.
static func build(wings := Wings.NONE, piglet := false) -> Dictionary:
	var coat := PIG_COAT if piglet else COAT
	var coat_dark := PIG_COAT.darkened(0.15) if piglet else COAT_DARK
	var root := Node3D.new()
	root.name = "Warchlak" if piglet else "Boar"
	var body := _part(root, Vector3.ZERO, func(st: SurfaceTool) -> void:
		# The wedge: a deep high shoulder hump tapering to a small low rump (the boar's tell; a pig is
		# a level barrel).
		_taper(st, Vector3(0, 0.52, -0.16), Vector2(0.46, 0.4), Vector2(0.6, 0.58), 0.5, coat)
		_box(st, Vector3(0, 0.6, 0.2), Vector3(0.64, 0.66, 0.26), coat)
		_taper(st, Vector3(0, 0.9, 0.12), Vector2(0.4, 0.06), Vector2(0.54, 0.2), 0.42, coat)  # the hump
		_box(st, Vector3(0, 0.34, 0.04), Vector3(0.48, 0.1, 0.56), BELLY if not piglet else coat_dark)
		if piglet:
			# Cream stripes along the flanks and back.
			for k in 3:
				var y := 0.5 + 0.13 * float(k)
				for s in [-1.0, 1.0]:
					_box(st, Vector3((0.285 + 0.02 * float(k)) * s, y, -0.02), Vector3(0.03, 0.05, 0.72), PIG_STRIPE)
			_box(st, Vector3(0, 0.95, 0.0), Vector3(0.06, 0.03, 0.6), PIG_STRIPE)
		# The mohawk: dark chunky blocks from the nape down the back, tallest at the hump, blond tips.
		var crest := [[0.34, 0.2], [0.22, 0.24], [0.1, 0.22], [-0.03, 0.17], [-0.16, 0.13], [-0.29, 0.09]]
		var n := 3 if piglet else crest.size()
		for i in n:
			var z: float = crest[i][0]
			var h: float = crest[i][1] * (0.6 if piglet else 1.35)
			var top := 0.98 - maxf(0.0, 0.1 - z) * 0.55
			_box(st, Vector3(0, top + h * 0.5, z), Vector3(0.12, h, 0.12), MANE, Basis(Vector3.RIGHT, -0.3))
			_box(st, Vector3(0, top + h - 0.005, z - 0.03), Vector3(0.1, 0.06, 0.1), MANE_TIP, Basis(Vector3.RIGHT, -0.3))
	, "body")
	var head := _part(body, Vector3(0, 0.64, 0.33), func(st: SurfaceTool) -> void:
		# The big wedge head: tall at the brow, sloping to a long straight snout and its flat pink disc.
		_taper(st, Vector3(0, 0.06, 0.18), Vector2(0.58, 0.56), Vector2(0.5, 0.42), 0.36, coat, Basis(), -0.05)
		_box(st, Vector3(0, 0.02, 0.37), Vector3(0.46, 0.36, 0.03), FACE if not piglet else coat.lightened(0.15))
		_taper(st, Vector3(0, -0.1, 0.56), Vector2(0.34, 0.28), Vector2(0.28, 0.24), 0.36, SNOUT if not piglet else coat.lightened(0.2))
		_box(st, Vector3(0, -0.1, 0.745), Vector3(0.22, 0.18, 0.03), NOSE)
		_box(st, Vector3(0.05, -0.1, 0.762), Vector3(0.05, 0.07, 0.01), NOSTRIL)
		_box(st, Vector3(-0.05, -0.1, 0.762), Vector3(0.05, 0.07, 0.01), NOSTRIL)
		for s in [-1.0, 1.0]:
			# Eyes on the face like the chudiki's: a white 2x2 with a dark pupil, a heavy brow, a blush.
			_box(st, Vector3(0.12 * s, 0.1, 0.39), Vector3(0.1, 0.1, 0.02), Color.WHITE)
			_box(st, Vector3(0.105 * s, 0.09, 0.402), Vector3(0.06, 0.07, 0.01), EYE)
			_box(st, Vector3(0.13 * s, 0.185, 0.395), Vector3(0.14, 0.04, 0.04), BROW, Basis(Vector3.BACK, 0.2 * s))
			_box(st, Vector3(0.2 * s, -0.04, 0.39), Vector3(0.08, 0.05, 0.01), BLUSH)
			if not piglet:
				# Cheek beard, then the tusks: big cream hooks out of the snout's sides, curving up.
				_box(st, Vector3(0.24 * s, -0.16, 0.36), Vector3(0.12, 0.16, 0.12), CHEEK)
				_box(st, Vector3(0.18 * s, -0.2, 0.66), Vector3(0.1, 0.1, 0.14), TUSK)
				_box(st, Vector3(0.21 * s, -0.06, 0.7), Vector3(0.1, 0.24, 0.1), TUSK, Basis(Vector3.BACK, -0.3 * s))
				_box(st, Vector3(0.27 * s, 0.07, 0.69), Vector3(0.075, 0.1, 0.075), TUSK, Basis(Vector3.BACK, -0.65 * s))
		_box(st, Vector3(0, -0.235, 0.66), Vector3(0.16, 0.025, 0.12), NOSTRIL)  # the grin
	, "head")
	var ears: Array[Node3D] = []
	for s in [-1.0, 1.0]:
		var ear := _part(head, Vector3(0.2 * s, 0.3, 0.1), func(st: SurfaceTool) -> void:
			var b := Basis(Vector3.BACK, -0.3 * s)
			_box(st, b * Vector3(0, 0.06, 0), Vector3(0.14, 0.13, 0.06), EAR, b)
			_box(st, b * Vector3(0, 0.16, 0), Vector3(0.09, 0.09, 0.05), EAR, b)
			_box(st, b * Vector3(0, 0.08, 0.032), Vector3(0.07, 0.09, 0.01), EAR_IN, b)
		, "ear")
		ears.append(ear)
	var legs: Array[Node3D] = []
	for i in 4:
		var front := i < 2
		var s := -1.0 if i % 2 == 0 else 1.0
		var leg := _part(body, Vector3(0.18 * s, 0.32, 0.2 if front else -0.3), func(st: SurfaceTool) -> void:
			_box(st, Vector3(0, -0.11, 0), Vector3(0.15, 0.22, 0.16), LEG if not piglet else coat_dark)
			_box(st, Vector3(0, -0.26, 0.01), Vector3(0.16, 0.08, 0.18), HOOF)
		, "leg")
		legs.append(leg)
	var tail := _part(body, Vector3(0, 0.64, -0.42), func(st: SurfaceTool) -> void:
		# Straight with a tuft, never a pig's curl.
		_box(st, Vector3(0, -0.11, -0.02), Vector3(0.045, 0.22, 0.045), coat_dark, Basis(Vector3.RIGHT, -0.2))
		_box(st, Vector3(0, -0.24, -0.05), Vector3(0.08, 0.09, 0.07), MANE)
	, "tail")
	var rig := {"root": root, "body": body, "head": head, "ears": ears, "legs": legs, "tail": tail,
		"wings": [] as Array[Node3D], "outer": [] as Array[Node3D], "wing_kind": wings}
	if wings != Wings.NONE:
		for s in [-1.0, 1.0]:
			var w := Node3D.new()
			w.name = "wing"
			w.position = Vector3(0.26 * s, 0.95, 0.16)
			body.add_child(w)
			var outer := _feather_wing(w, s)
			(rig["wings"] as Array[Node3D]).append(w)
			(rig["outer"] as Array[Node3D]).append(outer)
	return rig


# --- wings (promo only) ------------------------------------------------------------------------

## A big white feathered wing (comically big: 1.25 m out from the shoulder), in two pieces so the
## outer half lags the beat: the inner arm with rounded coverts and secondaries, the outer hand
## with long primaries fanning back like fingers. Returns the outer joint.
static func _feather_wing(w: Node3D, s: float) -> Node3D:
	var inner := _part(w, Vector3.ZERO, func(st: SurfaceTool) -> void:
		_box(st, Vector3(0.28 * s, 0.03, 0.02), Vector3(0.58, 0.09, 0.16), FEATHER)  # the arm
		for k in 5:
			var x := (0.07 + 0.11 * float(k)) * s
			_box(st, Vector3(x, 0.0, -0.13), Vector3(0.12, 0.05, 0.2), FEATHER if k % 2 == 0 else FEATHER_TIP)  # coverts
			var l := 0.36 + 0.03 * float(k)
			_box(st, Vector3(x, -0.03, -0.06 - l * 0.5), Vector3(0.11, 0.035, l), FEATHER_SHADE if k % 2 == 0 else FEATHER)
	, "wing_in")
	var outer := _part(w, Vector3(0.56 * s, 0.0, 0.0), func(st: SurfaceTool) -> void:
		_box(st, Vector3(0.16 * s, 0.02, 0.02), Vector3(0.34, 0.07, 0.13), FEATHER)
		for k in 5:
			var x := (0.04 + 0.1 * float(k)) * s
			var l := 0.42 + 0.06 * float(k)
			var b := Basis(Vector3.UP, (0.06 * float(k) - 0.05) * -s)
			_box(st, Vector3(x, -0.02, -0.02 - l * 0.5) + b * Vector3.ZERO, Vector3(0.1, 0.035, l), FEATHER if k % 2 == 0 else FEATHER_SHADE, b)
		# The tip primaries, longest, reaching out and back.
		_box(st, Vector3(0.6 * s, -0.02, -0.18), Vector3(0.36, 0.035, 0.11), FEATHER, Basis(Vector3.UP, 0.5 * s))
		_box(st, Vector3(0.62 * s, -0.025, -0.34), Vector3(0.34, 0.035, 0.11), FEATHER_TIP, Basis(Vector3.UP, 0.75 * s))
	, "wing_out")
	return outer


# --- poses -----------------------------------------------------------------------------------------

## Flying: big wing beats with the outer feathers lagging, legs paddling as if swimming in the air
## (the funny part), ears streaming back and flopping on each beat, the tail spinning, the body
## bobbing against the beat.
static func pose_fly(r: Dictionary, t: float, flap_hz := 3.0) -> void:
	var beat := TAU * flap_hz * t
	# Wings in stepped poses (8 a beat), like a toy's animation, not a smooth swing.
	var step := TAU * floorf(flap_hz * t * 8.0) / 8.0
	var body: Node3D = r["body"]
	body.position.y = -0.08 * sin(beat + 0.4)
	body.rotation.x = 0.06 * sin(beat + 1.0) - 0.05
	var wings: Array = r["wings"]
	var outer: Array = r["outer"]
	for i in wings.size():
		var s := -1.0 if i == 0 else 1.0
		(wings[i] as Node3D).rotation = Vector3(0.0, 0.0, s * (0.15 + 0.75 * sin(step)))
		(outer[i] as Node3D).rotation = Vector3(0.0, 0.0, s * (0.05 + 0.45 * sin(step - 0.9)))
	var legs: Array = r["legs"]
	for i in legs.size():
		var front := i < 2
		var ph := TAU * 2.0 * flap_hz * t + (0.0 if (i == 0 or i == 3) else PI)
		(legs[i] as Node3D).rotation = Vector3((0.5 if front else -0.45) + 0.6 * sin(ph), 0, 0)
	var ears: Array = r["ears"]
	for i in ears.size():
		var s := -1.0 if i == 0 else 1.0
		(ears[i] as Node3D).rotation = Vector3(-0.55 + 0.25 * sin(beat - 1.3), 0, s * 0.2 * sin(beat - 1.0))
	(r["head"] as Node3D).rotation = Vector3(0.06 * sin(beat), 0.12 * sin(t * 0.9), 0.05 * sin(t * 1.3))
	(r["tail"] as Node3D).rotation = Vector3(-1.0 + 0.2 * sin(t * 11.0), 0, 0.6 * sin(t * 17.0))


## Trotting on the ground at `speed` m/s (for the quest): diagonal legs together, the head nodding,
## the tail swishing. At speed 0 it stands and sniffs.
static func pose_trot(r: Dictionary, t: float, speed: float) -> void:
	var gait := clampf(speed / 3.0, 0.0, 1.0)
	var ph := TAU * t * (1.2 + speed * 0.5)
	var legs: Array = r["legs"]
	for i in legs.size():
		var o := 0.0 if (i == 0 or i == 3) else PI
		(legs[i] as Node3D).rotation = Vector3(0.5 * gait * sin(ph + o), 0, 0)
	var body: Node3D = r["body"]
	body.position.y = 0.025 * gait * absf(sin(ph))
	body.rotation.x = 0.0
	var sniff := (1.0 - gait) * 0.08 * sin(t * 7.0)
	(r["head"] as Node3D).rotation = Vector3(0.06 + 0.05 * gait * sin(ph * 2.0) + sniff, 0.15 * (1.0 - gait) * sin(t * 0.7), 0)
	var ears: Array = r["ears"]
	for i in ears.size():
		(ears[i] as Node3D).rotation = Vector3(-0.1 + 0.08 * gait * sin(ph * 2.0 - 0.6), 0, 0)
	(r["tail"] as Node3D).rotation = Vector3(-0.2, 0, 0.6 * sin(t * 6.0))
