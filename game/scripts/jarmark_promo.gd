extends "res://scripts/place.gd"
## Jarmark Warszawski dressed for the promo video (F, 2026-11-21: "nicer cinematic lighting, details,
## close-ups", "do not consider performance, maybe we would not put everything in the game"). Built
## only with --promo-dress=jarmark (places.gd `promo` rows), never in a player's game.
##
## What the drone reels (refs/jarmark-2026/instagram/videos2: Df-JvEJoNJv, Df9-olHig27) show that the
## game's market (landmarks/jarmark.gd) has too little of, and the art director's critique of the
## first pass (2026-11-21), in one mesh with its own shader (shaders/jarmark_promo.gdshader):
##  - bulbs as camera-facing discs never smaller than ~1.3 pixels (a 5 cm bulb is under a pixel at a
##    promo view), HDR so the glow pass blooms them into the reels' chains of dots;
##  - one amber bulb line on every chalet's roof edges (front eave and rakes; the roofs dark: F's
##    drone photos, 2026-11-21, "warm lines on a dark ground"), warm-white counters (#ffc98a, not
##    fast-food yellow), striped awnings on a third;
##  - the aisles: a chain of 7 m poles every 12 m down each aisle's middle with a white globe crown,
##    strings from the crown to both rows' front eaves, scalloped swags crown to crown, and the
##    paving lit warm in three hard bands in a pool under each crown only, dark between;
##  - the car park's bay lines covered;
##  - the tower carousel's LED mast cyan above and violet-magenta below, cycling, a blue LED ring
##    round its base;
##  - the big tree dark fir under an LED net cycling blue-white to violet;
##  - Metro Centrum's glass pavilion glowing warm, its two glass tubes in the market white-green;
##  - the kurant's tiered pagoda by the tubes, fans of strings from its crown, the carousel's and
##    the tree's tops to the ground (lighting-decision.md);
##  - gold wire reindeer and tall warm light cones by the tree.
## The kit (landmarks/jarmark.gd) places it all in the market's own frame, so it sits on the model.

const Kit := preload("res://scripts/landmarks/jarmark.gd")
const Centre := preload("res://scripts/landmarks/centre.gd")
const SHADER := "res://shaders/jarmark_promo.gdshader"
const Tiers := preload("res://scripts/tiers.gd")

## Material codes (UV2.x) the shader reads. Meshes: a softly lit surface, the tower's cycling LED
## sleeve (UV2.y its height 0-1), a cool glow, gold wire, the lit paving (UV.x across the band -1..1),
## a warm-white counter, plain. Bulbs (camera-facing discs, UV the corner, UV2.y the radius): a
## fixed-colour bulb, a tree bulb that cycles (its colour's red channel picks its phase).
const SOFT := 21.0
const CYCLE := 22.0
const COOL := 23.0
const GOLD := 24.0
const FLOOR := 26.0
const COUNTER := 27.0
const PLAIN := 0.0
const BULB := 30.0
const TREE_BULB := 31.0
const PAGODA_BULB := 32.0

const WARM := Color(1.0, 0.78, 0.48)
const WHITE_BULB := Color(1.0, 0.92, 0.78)
const GLOBE := Color(1.0, 0.97, 0.9)
const STRIPE_RED := Color("#c8202a")
const STRIPE_WHITE := Color("#f4efe6")
const COUNTER_WARM := Color("#ffc98a")
const ASPHALT := Color("#56585c")

var kit
var mesh_instance: MeshInstance3D
var bulbs := 0
var _st: SurfaceTool


func build() -> void:
	kit = Kit.new()
	kit.map = map
	kit._no_roof = true
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	kit.st = _st
	var huts: Array = Kit._jm_huts()
	for h: Array in huts:
		_hut_lights(h[0], h[1], h[2], h[3], h[4])
	_bay_lines()
	_aisles()
	_mast()
	_tree_net()
	_pavilion_glow()
	_tube_glow()
	_pagoda()
	_ride_fans()
	_figures()
	kit._jm_frame()
	var mesh := _st.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "JarmarkPromo"
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The bulbs grow in the vertex shader (a pixel floor): a margin round the mesh's own box.
	var box := mesh.get_aabb().grow(3.0)
	mesh_instance.custom_aabb = box
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	# The floor in the video's pixels: --ss=N draws N image pixels a video pixel.
	mat.set_shader_parameter("px_floor", 1.3 * Tiers.capture_scale)
	mesh_instance.material_override = mat
	part(mesh_instance)
	count = bulbs
	print("jarmark promo: %d bulbs, %d triangles" % [bulbs, mesh_triangles(mesh)])


## A bulb: a camera-facing disc at `p` (world), radius r (the shader keeps it ~1.3 px at least).
## Four vertices at the centre, UV the corner, UV2 (code, r).
func _bulb(p: Vector3, r: float, col: Color, code := BULB) -> void:
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for tri: Array in [[0, 1, 2], [0, 2, 3]]:
		for i: int in tri:
			_st.set_color(col)
			_st.set_normal(Vector3.UP)
			_st.set_uv(corners[i])
			_st.set_uv2(Vector2(code, r))
			_st.add_vertex(p)
	bulbs += 1


## Bulbs every `step` m from a to b (world), sagging `sag` m in the middle, on a thin dark wire.
func _bulb_line(a: Vector3, b: Vector3, step: float, r: float, col: Color, sag := 0.0, wire := true) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / step))
	var prev := a
	for k in n + 1:
		var t := float(k) / n
		var p := a.lerp(b, t) - Vector3.UP * sag * 4.0 * t * (1.0 - t)
		_bulb(p, r, col)
		if wire and k > 0:
			kit._beam(prev, p, 0.02, Color("#1a1a1c"), false, PLAIN)
		prev = p


func _q(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, code: float, ua := Vector2(-1, -1), ub := Vector2(-1, -1),
		uc := Vector2(-1, -1), ud := Vector2(-1, -1)) -> void:
	kit._mode = code
	var n := (b - a).cross(d - a).normalized()
	kit._quad(a, b, c, d, n, col, ua, ub, uc, ud, -1.0)


## The hut's frame after kit._jm_at: a local (u, v, y) point in the world.
func _hp(lu: float, lv: float, ly: float) -> Vector3:
	var w: Vector2 = kit._w(lu, lv)
	return Vector3(w.x, ly, w.y)


static func hut_size(kind: int) -> Array:
	match kind:
		Kit.Hut.FOOD:
			return [1.3, 1.0, 2.2, 0.75]
		Kit.Hut.BIG:
			return [2.6, 1.5, 2.6, 1.25]
	return [1.6, 1.15, 2.3, 0.95]


## One chalet's lights, in the hut's own frame as jarmark.gd `_jm_hut` builds it.
func _hut_lights(u: float, v: float, quarter: int, kind: int, n: int) -> void:
	var g: float = kit._jm_at(u, v, quarter)
	var s := hut_size(kind)
	var hu: float = s[0]
	var hv: float = s[1]
	var eave: float = s[2]
	var rise: float = s[3]
	var ou := hu + 0.17
	var ov := hv + 0.42
	var y := g + eave + 0.04
	var ridge := g + eave + rise + 0.06
	# One amber line on the roof's edges, the roof itself dark (F's drone photos, 2026-11-21: warm
	# lines on a dark ground): the front eave and the two front rakes.
	var col := WARM
	_bulb_line(_hp(-ou, -ov, y), _hp(ou, -ov, y), 0.25, 0.05, col, 0.0, false)
	for su: float in [-ou, ou]:
		_bulb_line(_hp(su, -ov, y), _hp(su, 0.0, ridge), 0.25, 0.045, col, 0.0, false)
	# The counter's glow, warm white, over the model's yellow (just in front of it).
	_q(_hp(-hu + 0.22, -hv - 0.05, g + 1.05), _hp(hu - 0.22, -hv - 0.05, g + 1.05),
			_hp(hu - 0.22, -hv - 0.05, g + eave - 0.3), _hp(-hu + 0.22, -hv - 0.05, g + eave - 0.3), COUNTER_WARM, COUNTER)
	# A striped awning over every third counter, sloping out from under the eave, scalloped.
	if kind != Kit.Hut.FOOD and n % 3 == 1:
		var strips := 9
		var w := 2.0 * (hu - 0.1) / strips
		for k in strips:
			var u0 := -hu + 0.1 + float(k) * w
			var c := STRIPE_RED if k % 2 == 0 else STRIPE_WHITE
			var a0 := _hp(u0, -hv - 0.06, g + eave - 0.22)
			var a1 := _hp(u0 + w, -hv - 0.06, g + eave - 0.22)
			var b1 := _hp(u0 + w, -hv - 0.95, g + eave - 0.62)
			var b0 := _hp(u0, -hv - 0.95, g + eave - 0.62)
			_q(a0, a1, b1, b0, c, SOFT)
			var mid := (b0 + b1) * 0.5 - Vector3.UP * 0.12
			kit._mode = SOFT
			kit._tri(b0, b1, mid, (b1 - b0).cross(Vector3.UP).normalized(), c, Vector2(-1, -1), Vector2(-1, -1),
					Vector2(-1, -1), -1.0, false)
	kit._jm_frame()


## The car park's white bay lines (jarmark.gd `_jm_drape`), covered in asphalt: inside the market
## the reels show none.
func _bay_lines() -> void:
	kit._jm_frame()
	var paved: Array = Kit.JM_PAVED[0]
	for vl: float in Kit.JM_BAYS:
		var uu: float = paved[0] + 2.0
		while uu < float(paved[1]) - 2.0:
			if not Kit.jm_clear(uu, vl, 2.5):
				uu += 2.6
				continue
			var g: float = kit._jm_ground(uu, vl) + Kit.JM_LIFT + 0.07
			_q(_hp(uu - 0.15, vl - 2.5, g), _hp(uu + 0.15, vl - 2.5, g), _hp(uu + 0.15, vl + 2.5, g), _hp(uu - 0.15, vl + 2.5, g),
					ASPHALT, PLAIN)
			uu += 2.6


## The aisles (jarmark.gd JM_STRINGS: [u0, u1, v_a, v_b, step]): down each aisle's middle a pole every
## 12 m, 7 m tall, a crown of white globes on top; from each crown 8 strings down to each row's
## front eave (2.6 m), scalloped swags crown to crown; under them the paving lit warm in three bands.
func _aisles() -> void:
	for s: Array in Kit.JM_STRINGS:
		kit._jm_frame()
		var u0: float = s[0]
		var u1: float = s[1]
		var va: float = s[2]
		var vb: float = s[3]
		var vm := (va + vb) * 0.5
		var half := absf(vb - va) * 0.5
		var n := maxi(1, roundi((u1 - u0) / 12.0))
		var prev := Vector3.INF
		for k in n + 1:
			var u := lerpf(u0 + 3.0, u1 - 3.0, float(k) / n)
			kit._jm_frame()
			var at: Vector2 = kit._w(u, vm)
			var g: float = map.terrain_height(at.x, at.y) + Kit.JM_LIFT
			var top := Vector3(at.x, g + 7.0, at.y)
			kit._beam(Vector3(at.x, g, at.y), top, 0.12, Color("#1c1d20"), false, PLAIN)
			# A warm pool under the crown only; between the pools the paving stays dark.
			# Pools no wider than half the gap to the next crown, so neighbours never overlap.
			var pr := minf(4.0, (u1 - u0 - 6.0) / float(n) * 0.5 - 0.05)
			_floor_band(maxf(u - pr, u0), minf(u + pr, u1), vm, half)
			for j in 5:
				var t := TAU * float(j) / 5.0
				_bulb(top + Vector3(cos(t) * 0.42, 0.15, sin(t) * 0.42), 0.26, GLOBE)
			_bulb(top + Vector3.UP * 0.55, 0.3, GLOBE)
			for side: float in [-1.0, 1.0]:
				for j in 8:
					var du := lerpf(-5.6, 5.6, float(j) / 7.0)
					var e: Vector2 = kit._w(u + du, vm + side * (half - 0.3))
					var low := Vector3(e.x, g + 2.6, e.y)
					_bulb_line(top - Vector3.UP * 0.2, low, 0.38, 0.05, WARM if j % 3 != 1 else WHITE_BULB, 0.3)
			if prev != Vector3.INF:
				_bulb_line(prev - Vector3.UP * 0.3, top - Vector3.UP * 0.3, 0.38, 0.05, WARM, 1.6)
			prev = top


## The paving under a crown of strings lit warm: three hard bands out from the aisle's middle line
## (the art bible's lamp pools), 3 cm over the asphalt, in 4 m pieces draped on the ground; only
## under each crown (F's drone photos: pools, not a carpet).
func _floor_band(u0: float, u1: float, vm: float, half: float) -> void:
	kit._jm_frame()
	var w := minf(half + 0.6, 3.6)
	var u := u0
	while u < u1 - 0.01:
		var ue := minf(u + 4.0, u1)
		var g0: float = kit._jm_ground(u, vm) + Kit.JM_LIFT + 0.04
		var g1: float = kit._jm_ground(ue, vm) + Kit.JM_LIFT + 0.04
		_q(_hp(u, vm - w, g0), _hp(ue, vm - w, g1), _hp(ue, vm + w, g1), _hp(u, vm + w, g0), Color("#6a4c30"), FLOOR,
				Vector2(-1, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, 0))
		u = ue


## The tower carousel's mast as an LED sleeve over the static rainbow one (radius 0.72): rings every
## 0.6 m that the shader colours one colour at a time; a blue LED ring round the base (top.png).
func _mast() -> void:
	kit._jm_frame()
	var c: Vector2 = kit._w(Kit.JM_TOWER.x, Kit.JM_TOWER.y)
	var g: float = map.terrain_height(c.x, c.y)
	var y := g + 2.2
	while y < g + 38.0:
		var ring: PackedVector2Array = kit._circle(c, 0.76, 10)
		kit._mode = CYCLE
		for k in ring.size():
			var a := ring[k]
			var b := ring[(k + 1) % ring.size()]
			var nr := Vector3(a.x + b.x - 2.0 * c.x, 0.0, a.y + b.y - 2.0 * c.y).normalized()
			kit._quad(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(b.x, y + 0.6, b.y), Vector3(a.x, y + 0.6, a.y),
					nr, Color.WHITE, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), (y - g) / 38.0)
		y += 0.6
	# The blue ring round the base, 5 m out, 0.5 m up.
	var ring2: PackedVector2Array = kit._circle(c, 5.2, 48)
	for k in ring2.size():
		var a := ring2[k]
		_bulb(Vector3(a.x, g + 0.5, a.y), 0.12, Color(0.16, 0.36, 1.0))
	for k in 16:
		var t := TAU * float(k) / 16.0
		_bulb(Vector3(c.x + cos(t) * 1.75, g + 39.4, c.y + sin(t) * 1.75), 0.12, GLOBE)
	# The big outline star beside it (top.png: left of the tower), cool white.
	_outline_star(Vector2(Kit.JM_TOWER.x + 9.0, Kit.JM_TOWER.y - 6.0), 2.2, 4.0)


## A five-pointed star outline of bulbs, radius r, its centre `up` m over the ground at local (u, v),
## facing -v.
func _outline_star(at: Vector2, r: float, up: float) -> void:
	kit._jm_frame()
	var g: float = kit._jm_ground(at.x, at.y) + up
	var pts: Array[Vector3] = []
	for k in 10:
		var t := PI * 0.5 + TAU * float(k) / 10.0
		var rr := r if k % 2 == 0 else r * 0.42
		pts.append(_hp(at.x + cos(t) * rr, at.y, g + sin(t) * rr))
	for k in 10:
		_bulb_line(pts[k], pts[(k + 1) % 10], 0.2, 0.06, Color(0.92, 0.95, 1.0), 0.0, false)
	kit._jm_pole(at.x, at.y, up - r * 0.42)


## The big tree's LED net as the reels show it: the model's glowing cone covered in dark fir (the net
## carries the colour), bulbs over every tier (jarmark.gd `_jm_tree`: 8 tiers 1.75 m apart, each a
## cone from r0 = 4.7 - 0.53 k to a third of it 2.5 m up), more on the silhouette, white sparkles.
func _tree_net() -> void:
	kit._jm_frame()
	var c: Vector2 = kit._w(Kit.JM_TREE.x, Kit.JM_TREE.y)
	var g0: float = map.terrain_height(c.x, c.y) + 0.35
	var rng := RandomNumberGenerator.new()
	rng.seed = 135
	for k in 8:
		var y0 := g0 + 0.5 + k * 1.75
		var r0 := 4.7 - 0.53 * k
		kit._mode = PLAIN
		kit._frustum(kit._circle(c, r0 + 0.07, 16), y0 - 0.02, kit._circle(c, r0 * 0.32 + 0.07, 16), y0 + 2.52, Color("#0f2a18"))
		var n := int(170.0 * r0 / 4.7) + 40
		for j in n:
			var f := rng.randf_range(0.0, 0.9)
			var t := rng.randf() * TAU
			var r := lerpf(r0, r0 * 0.32, f) + 0.12
			var p := Vector3(c.x + cos(t) * r, y0 + f * 2.5, c.y + sin(t) * r)
			if rng.randf() < 0.1:
				_bulb(p, 0.06, Color(1.0, 0.95, 0.9))
			else:
				# The red channel carries the bulb's phase in the cycle (a ripple down the tree).
				_bulb(p, 0.07, Color(fposmod(float(k) * 0.07 + rng.randf() * 0.05, 1.0), 0.0, 0.0), TREE_BULB)


## A glow skin over a half-barrel of glass in `tint` (its emission is tint x 1.15), between dark
## ribs every `rib` m.
func _barrel_glow(c: Vector2, up: Vector2, length: float, radius: float, base: float,
		tint := Color(0.9, 0.95, 1.0), rib := 1.5) -> void:
	var side := Vector2(-up.y, up.x)
	var segs := 10
	var h := length * 0.5
	for i in segs:
		var a0 := PI * float(i) / segs
		var a1 := PI * float(i + 1) / segs
		var o0 := side * cos(a0) * radius
		var o1 := side * cos(a1) * radius
		var p00 := c + o0 - up * h
		var p01 := c + o0 + up * h
		var p10 := c + o1 - up * h
		var p11 := c + o1 + up * h
		_q(Vector3(p00.x, base + sin(a0) * radius, p00.y), Vector3(p01.x, base + sin(a0) * radius, p01.y),
				Vector3(p11.x, base + sin(a1) * radius, p11.y), Vector3(p10.x, base + sin(a1) * radius, p10.y), tint, COOL)
	var s := -h
	while s <= h + 0.01:
		for i in segs:
			var a0 := PI * float(i) / segs
			var a1 := PI * float(i + 1) / segs
			var q0 := c + up * s + side * cos(a0) * (radius + 0.04)
			var q1 := c + up * s + side * cos(a1) * (radius + 0.04)
			kit._beam(Vector3(q0.x, base + sin(a0) * (radius + 0.04), q0.y), Vector3(q1.x, base + sin(a1) * (radius + 0.04), q1.y),
					0.09, Color("#20283a"), false, PLAIN)
		s += rib


## Metro Centrum's glass pavilion lit from inside (Df9-olHig27): F 2026-11-21 found the white
## lantern too bright, so it is smoky glass with a soft warm-white light and a rib each metre.
func _pavilion_glow() -> void:
	var q: Array = Centre.METRO_PAVILION
	var mouth: Vector2 = (q[0] + q[1]) * 0.5
	var far: Vector2 = (q[2] + q[3]) * 0.5
	var length := mouth.distance_to(far)
	var hw: float = (q[0] as Vector2).distance_to(q[1]) * 0.5
	var c := (mouth + far) * 0.5
	_barrel_glow(c, (mouth - far) / length, length - 0.2, hw - 0.05, map.terrain_height(c.x, c.y) + 1.1,
			Color(0.34, 0.33, 0.3), 1.0)


## Metro Centrum's two glass tubes in the market (centre.gd METRO_TUBES, built as `_glass_barrel`: the
## long side q0-q1, the vault half the width less 15 cm, 1 m up): a soft white-green glow, one of the
## few cool accents (F's drone photos; the drone frame's lit "greenhouse" by the tree is the north one).
func _tube_glow() -> void:
	for q: Array in Centre.METRO_TUBES:
		var q0: Vector2 = q[0]
		var q1: Vector2 = q[1]
		var length := q0.distance_to(q1)
		var c: Vector2 = (q0 + q1 + (q[2] as Vector2) + (q[3] as Vector2)) * 0.25
		var r := q1.distance_to(q[2]) * 0.5 - 0.2
		_barrel_glow(c, (q1 - q0) / length, length - 0.2, r, map.terrain_height(c.x, c.y) + 1.0, Color(0.5, 0.66, 0.56))


## The tiered "pagoda", the kurant (the organiser's day reel DfxopUFN7Fs 0:10, the drone's metro.png
## at night, the official map's kurant by the metro tubes) over the model's red hexagonal bar, its
## stand-in (jarmark.gd `_jm_hexbar` at JM_KURANT), until the kit's kurant replaces both: a glass hexagonal kiosk
## lit warm, a red patterned drum, three white tiers with green bands, a red upturned crown on a
## stem, about 12.6 m; at night every tier's edge in LED bulbs turning green and red.
func _pagoda() -> void:
	kit._jm_frame()
	var c: Vector2 = kit._w(Kit.JM_KURANT.x, Kit.JM_KURANT.y)
	var g: float = map.terrain_height(c.x, c.y) + Kit.JM_LIFT
	var white := Color("#eeeae2")
	var red := Color("#b3242c")
	var green := Color("#2f7a44")
	# The glass kiosk (warm inside), its white roof band.
	kit._prism(kit._circle(c, 3.6, 6), g, g + 3.1, COUNTER_WARM, white, COUNTER, PLAIN)
	kit._prism(kit._circle(c, 3.95, 6), g + 3.1, g + 3.5, white, white, PLAIN, PLAIN)
	# The red drum with its gold pattern lit softly.
	kit._prism(kit._circle(c, 2.75, 6), g + 3.5, g + 5.4, red, red, SOFT, PLAIN)
	# Three white tiers, green bands between.
	var tiers := [[2.65, 5.4, 7.0], [2.3, 7.0, 8.5], [1.95, 8.5, 9.9]]
	for t: Array in tiers:
		kit._prism(kit._circle(c, t[0], 6), g + float(t[1]), g + float(t[2]) - 0.3, white, white, SOFT, PLAIN)
		kit._prism(kit._circle(c, float(t[0]) + 0.05, 6), g + float(t[2]) - 0.3, g + float(t[2]), green, green, PLAIN, PLAIN)
	kit._prism(kit._circle(c, 0.45, 6), g + 9.9, g + 11.0, white, white, PLAIN, PLAIN)
	kit._mode = PLAIN
	kit._frustum(kit._circle(c, 0.9, 4), g + 11.0, kit._circle(c, 2.0, 4), g + 12.6, red, red)
	# The LED edges: the kiosk's roof, the drum's top, each tier's top and bottom, the crown's rim.
	var edges := [[3.98, 3.5], [3.98, 3.1], [2.8, 5.4], [2.7, 7.0], [2.35, 8.5], [2.0, 9.9], [2.7, 5.45], [2.35, 7.05], [2.0, 8.55]]
	var ph := 0.0
	for e: Array in edges:
		var ring: PackedVector2Array = kit._circle(c, e[0], 6)
		for k in 6:
			var a := Vector3(ring[k].x, g + float(e[1]), ring[k].y)
			var b := Vector3(ring[(k + 1) % 6].x, g + float(e[1]), ring[(k + 1) % 6].y)
			var n := maxi(2, ceili(a.distance_to(b) / 0.22))
			for j in n:
				_bulb(a.lerp(b, float(j) / n), 0.06, Color(ph, 0.0, 0.0), PAGODA_BULB)
		ph = fposmod(ph + 0.11, 1.0)
	var crown: PackedVector2Array = kit._circle(c, 2.02, 4)
	for k in 4:
		var a := Vector3(crown[k].x, g + 12.6, crown[k].y)
		var b := Vector3(crown[(k + 1) % 4].x, g + 12.6, crown[(k + 1) % 4].y)
		_bulb_line(a, b, 0.22, 0.06, WARM, 0.0, false)
	_bulb(Vector3(c.x, g + 13.2, c.y), 0.35, Color(1.0, 0.82, 0.4))
	# The maypole (drone-wide-palace.png, pyramid-real.png): strings of warm bulbs from under the
	# crown down to 2.4 m poles 12 m round, where they stand clear of the chalets and the tubes.
	for k in 18:
		var t := TAU * float(k) / 18.0
		var at: Vector2 = Kit.JM_KURANT + Vector2(cos(t), sin(t)) * 12.0
		if at.y < -8.5 or not Kit.jm_clear(at.x, at.y, 0.4) or (absf(at.x - 225.5) < 4.0 and at.y > 15.5):
			continue
		var w: Vector2 = kit._w(at.x, at.y)
		var gw: float = map.terrain_height(w.x, w.y) + Kit.JM_LIFT
		kit._beam(Vector3(w.x, gw, w.y), Vector3(w.x, gw + 2.4, w.y), 0.07, Color("#1c1d20"), false, PLAIN)
		_bulb_line(Vector3(c.x, g + 10.8, c.y), Vector3(w.x, gw + 2.4, w.y), 0.35, 0.05, WARM if k % 2 == 0 else WHITE_BULB, 0.5)


## The fans of warm strings from the tall rides' tops to poles round them (lighting-decision.md: the
## carousel, the kurant (in `_pagoda`), the tree): [centre, top over the ground, radius, strings].
func _ride_fans() -> void:
	for f: Array in [[Kit.JM_CAROUSEL, 7.4, 13.0, 14], [Kit.JM_TREE, 12.5, 13.5, 16]]:
		var at0: Vector2 = f[0]
		kit._jm_frame()
		var c: Vector2 = kit._w(at0.x, at0.y)
		var top := Vector3(c.x, map.terrain_height(c.x, c.y) + float(f[1]), c.y)
		for k in int(f[3]):
			var t := TAU * (float(k) + 0.5) / float(f[3])
			var at: Vector2 = at0 + Vector2(cos(t), sin(t)) * float(f[2])
			# Clear of the chalets, inside the market's fence, off the Palace's forecourt road.
			if at.y < -8.5 or at.y > 133.0 or not Kit.jm_clear(at.x, at.y, 0.4) or not _clear_of_huts(at):
				continue
			var w: Vector2 = kit._w(at.x, at.y)
			var gw: float = map.terrain_height(w.x, w.y) + Kit.JM_LIFT
			kit._beam(Vector3(w.x, gw, w.y), Vector3(w.x, gw + 2.6, w.y), 0.07, Color("#1c1d20"), false, PLAIN)
			_bulb_line(top, Vector3(w.x, gw + 2.6, w.y), 0.35, 0.05, WARM if k % 3 != 1 else WHITE_BULB, 0.6)


## Gold wire reindeer by the tree and the entrance (the reel's frames 6-7), and tall warm light
## cones round the tree's plaza.
func _figures() -> void:
	var deer := [[0.0, 0.9], [0.2, 1.3], [1.4, 1.35], [1.7, 1.6], [1.9, 2.3], [2.1, 2.2], [1.9, 1.55], [1.6, 1.0],
			[1.5, 0.0], [1.35, 0.95], [0.4, 0.95], [0.3, 0.0], [0.15, 0.9], [0.0, 0.9]]
	var antler := [[1.9, 2.3], [1.8, 2.8], [2.0, 2.6], [2.2, 3.0], [2.1, 2.2]]
	for spot: Array in [[185.0, -2.0, 1.0], [208.0, 2.5, -1.0], [152.0, -2.0, 1.0], [88.0, 10.0, 1.0]]:
		kit._jm_frame()
		var g: float = kit._jm_ground(spot[0], spot[1]) + Kit.JM_LIFT
		for shape: Array in [deer, antler]:
			for k in shape.size() - 1:
				var a: Array = shape[k]
				var b: Array = shape[k + 1]
				var pa: Vector2 = kit._w(spot[0] + float(a[0]) * float(spot[2]) * 1.4, spot[1])
				var pb: Vector2 = kit._w(spot[0] + float(b[0]) * float(spot[2]) * 1.4, spot[1])
				var wa := Vector3(pa.x, g + float(a[1]) * 1.4, pa.y)
				var wb := Vector3(pb.x, g + float(b[1]) * 1.4, pb.y)
				kit._beam(wa, wb, 0.05, Color(1.0, 0.78, 0.35), false, GOLD)
				_bulb_line(wa, wb, 0.2, 0.05, Color(1.0, 0.82, 0.42), 0.0, false)
	for k in 8:
		var t := TAU * (float(k) + 0.25) / 8.0
		var at: Vector2 = Kit.JM_TREE + Vector2(cos(t), sin(t)) * 12.5
		if not _clear_of_huts(at):
			continue
		kit._jm_frame()
		var c: Vector2 = kit._w(at.x, at.y)
		var g: float = map.terrain_height(c.x, c.y) + Kit.JM_LIFT
		for j in 50:
			var f := float(j) / 50.0
			var a := f * TAU * 5.0
			var r := 0.75 * (1.0 - f)
			_bulb(Vector3(c.x + cos(a) * r, g + f * 3.2, c.y + sin(a) * r), 0.05, WARM)
		_bulb(Vector3(c.x, g + 3.35, c.y), 0.16, Color(1.0, 0.82, 0.4))


## Is a spot of the market's plan clear of every chalet by a metre?
func _clear_of_huts(at: Vector2) -> bool:
	for h: Array in Kit.JM_HUT_LIST:
		if absf(at.x - float(h[0])) < 3.2 and absf(at.y - float(h[1])) < 2.8:
			return false
	return true
