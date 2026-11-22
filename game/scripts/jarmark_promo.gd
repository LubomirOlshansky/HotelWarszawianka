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
##
## F's look check 1 (2026-11-21, night, Ultra): the real market's object kit (landmarks/jarmark_kit.gd)
## replaces the game's old stand-ins here: the tree carousel, the kurant, the tower ride, the Venetian
## carousel and the teacups stand in this mesh (their turning parts in jarmark_rides.gd), and the old
## ones (jarmark.gd `_jm_tree`, `_jm_hexbar`, `_jm_tower`, `_jm_carousel`, `_jm_teacups`) are carved
## out of the city's sector meshes as each sector comes in (`_carve_mesh`, both city paths), with half
## the LED fir figures and the solid glowing LED cones (now cones of bulbs). The city's M_LAMP and the
## lamp pools are turned down on its shared materials for the promo only (`_tune_material`).

const Kit := preload("res://scripts/landmarks/jarmark.gd")
const Centre := preload("res://scripts/landmarks/centre.gd")
const SHADER := "res://shaders/jarmark_promo.gdshader"
const Tiers := preload("res://scripts/tiers.gd")
const JK := preload("res://scripts/landmarks/jarmark_kit.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
## The kit objects' yaw: the market's u axis (Kit.JM_AXIS.angle()), fronts to -v as a quarter-0 hut.
const KIT_YAW := 1.2190949
## The promo's GRZANIEC booth: right in front of the kurant (towards the metro and gate 2), facing -u;
## it takes the place of the market's own booth there (JM_ANCHORS "grzaniec-kurant", carved).
const GRZANIEC_AT := Vector2(237.0, 7.2)
## The city's M_LAMP gain in the promo (building.gdshader `lamp_gain`, 2.4 in the game): the hut bulbs,
## strings and LED figures read as bulbs and lines, not blobs (grade D: soft highlights, matte).
const CITY_LAMP_GAIN := 1.2
## The huts' bulbs: warm white (F, look check 1).
const HUT_WARM := Color("#ffd9a0")

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
## The old pieces carved out of the sector meshes: [world centre, radius, lowest, highest] (heights
## over the terrain under the triangle); a triangle goes when all its corners are inside the circle
## and its middle between the heights. `_carve_cells` bins them by 8 m cell.
var _carves: Array = []
var _carve_cells := {}
var _carve_box := AABB()
var _carved_tris := 0


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
	_kit_objects()
	_mast()
	_pavilion_glow()
	_tube_glow()
	_kurant_strings()
	_ride_fans()
	_figures()
	_led_cones()
	_sign_bulbs()
	_carve_list()
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
	_start_carving()
	print("jarmark promo: %d bulbs, %d triangles; %d old triangles carved so far" % [bulbs, mesh_triangles(mesh), _carved_tris])


## The view's zoom each frame (F 2026-11-21, the hut-aisle close-up "glows far too much"): the glow is
## screen-space, so close up the same bulbs fill far more pixels and haze white. Full glow on a wide
## drone shot (a view 110 m tall or more), about 40 % of its intensity under 60 m, and the city's M_LAMP
## down with it; the bulbs' own emission falls in jarmark_promo.gdshader by the same rule.
func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var view_m := cam.size if cam.projection == Camera3D.PROJECTION_ORTHOGONAL else 80.0
	var wide := smoothstep(60.0, 110.0, view_m)
	var share := lerpf(0.82, 1.0, wide)  # was 0.4: too dark (F 2026-11-22)
	# Far drone shots with the Palace (F 2026-11-22, pack 2): thousands of tiny bulbs haze the frame, so
	# the glow eases to 80 % on views 180 to 400 m tall: visible, not bright.
	share *= lerpf(1.0, 0.8, smoothstep(180.0, 400.0, view_m))
	if absf(share - TimeOfDay.promo_glow_share) < 0.005:
		return
	TimeOfDay.promo_glow_share = share
	if TimeOfDay.promo_env != null and TimeOfDay.promo_glow_base > 0.0:
		TimeOfDay.promo_env.glow_intensity = TimeOfDay.promo_glow_base * share
	if "building_material" in map and map.get("building_material") is ShaderMaterial:
		(map.get("building_material") as ShaderMaterial).set_shader_parameter("lamp_gain", CITY_LAMP_GAIN * lerpf(0.8, 1.0, wide))


## The ground a kit object stands on at market point (u, v): the terrain, plus the asphalt's lift on
## the car park; the tree carousel on the old tree's platform (35 cm, left standing when it is carved).
static func kit_ground(m: Node3D, uv: Vector2, what := "") -> float:
	var p := Kit._jm_world(uv.x, uv.y)
	var g: float = m.terrain_height(p.x, p.y)
	return g + (0.35 if what == "tree" else Kit.jarmark_lift(p))


## The kit's still parts of the rides and the kurant (their turning parts: jarmark_rides.gd), and the
## GRZANIEC booth right in front of the kurant, its counter to the main approach (the metro and gate 2).
func _kit_objects() -> void:
	var at := func(uv: Vector2) -> Vector2: return Kit._jm_world(uv.x, uv.y)
	JK.tree_ride_static(kit, at.call(Kit.JM_TREE), KIT_YAW, kit_ground(map, Kit.JM_TREE, "tree"))
	JK.kurant(kit, at.call(Kit.JM_KURANT), KIT_YAW, kit_ground(map, Kit.JM_KURANT), false)
	JK.tower_static(kit, at.call(Kit.JM_TOWER), KIT_YAW, kit_ground(map, Kit.JM_TOWER))
	JK.venetian_static(kit, at.call(Kit.JM_CAROUSEL), KIT_YAW, kit_ground(map, Kit.JM_CAROUSEL))
	JK.teacups_static(kit, at.call(Kit.JM_TEACUPS), KIT_YAW, kit_ground(map, Kit.JM_TEACUPS))
	# 6.4 m out from the kurant's axis (its skirt roof is 4.8 m): the booth's back to the kurant.
	var gz := GRZANIEC_AT
	JK.grzaniec_booth(kit, at.call(gz), KIT_YAW + PI * 1.5, kit_ground(map, gz))
	kit._no_roof = true
	kit._jm_frame()


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
	var col := HUT_WARM
	_bulb_line(_hp(-ou, -ov, y), _hp(ou, -ov, y), 0.25, 0.05, col, 0.0, false)
	for su: float in [-ou, ou]:
		_bulb_line(_hp(su, -ov, y), _hp(su, 0.0, ridge), 0.25, 0.045, col, 0.0, false)
	# The light roofs (jarmark.gd: every fourth white hut) dark too: a charcoal skin 3 cm over both planes.
	if kind == Kit.Hut.WHITE and n % 4 == 1:
		for sv: float in [-1.0, 1.0]:
			_q(_hp(-ou, sv * ov, y - 0.01), _hp(ou, sv * ov, y - 0.01), _hp(ou, 0.0, ridge - 0.03), _hp(-ou, 0.0, ridge - 0.03),
					Kit.JM_ROOF, PLAIN)
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
				# Look check 1: the aisles read nearly white; six strings a side (were eight), a bulb every
				# 55 cm (were 38): about 40 % fewer, and each dimmer (the shader's bulb_gain).
				for j in 6:
					var du := lerpf(-5.6, 5.6, float(j) / 5.0)
					var e: Vector2 = kit._w(u + du, vm + side * (half - 0.3))
					var low := Vector3(e.x, g + 2.6, e.y)
					_bulb_line(top - Vector3.UP * 0.2, low, 0.55, 0.05, HUT_WARM if j % 3 != 1 else WHITE_BULB, 0.3)
			if prev != Vector3.INF:
				_bulb_line(prev - Vector3.UP * 0.3, top - Vector3.UP * 0.3, 0.55, 0.05, HUT_WARM, 1.6)
			prev = top


## The paving under a crown of strings lit warm: three hard bands out from the aisle's middle line
## (the art bible's lamp pools), 3 cm over the asphalt, in 4 m pieces draped on the ground; only
## under each crown (F's drone photos: pools, not a carpet).
func _floor_band(u0: float, u1: float, vm: float, half: float) -> void:
	kit._jm_frame()
	var w := minf(half + 0.6, 3.6)
	var u := u0
	# UV.y along the pool (-1..1), so the shader fades its ends too (no hard edges).
	var along := func(x: float) -> float: return lerpf(-1.0, 1.0, (x - u0) / maxf(u1 - u0, 0.01))
	while u < u1 - 0.01:
		var ue := minf(u + 4.0, u1)
		var g0: float = kit._jm_ground(u, vm) + Kit.JM_LIFT + 0.04
		var g1: float = kit._jm_ground(ue, vm) + Kit.JM_LIFT + 0.04
		var t0: float = along.call(u)
		var t1: float = along.call(ue)
		_q(_hp(u, vm - w, g0), _hp(ue, vm - w, g1), _hp(ue, vm + w, g1), _hp(u, vm + w, g0), Color("#6a4c30"), FLOOR,
				Vector2(-1, t0), Vector2(-1, t1), Vector2(1, t1), Vector2(1, t0))
		u = ue


## The tower carousel's mast as an LED sleeve over the static rainbow one (radius 0.72): rings every
## 0.6 m that the shader colours one colour at a time; a blue LED ring round the base (top.png).
func _mast() -> void:
	kit._jm_frame()
	var c: Vector2 = kit._w(Kit.JM_TOWER.x, Kit.JM_TOWER.y)
	var g: float = map.terrain_height(c.x, c.y)
	var y := g + 2.2
	var top := g + JK.TOWER_H
	while y < top - 0.01:
		var ring: PackedVector2Array = kit._circle(c, 0.8, 10)
		kit._mode = CYCLE
		for k in ring.size():
			var a := ring[k]
			var b := ring[(k + 1) % ring.size()]
			var nr := Vector3(a.x + b.x - 2.0 * c.x, 0.0, a.y + b.y - 2.0 * c.y).normalized()
			kit._quad(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(b.x, y + 0.6, b.y), Vector3(a.x, y + 0.6, a.y),
					nr, Color.WHITE, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), (y - g) / JK.TOWER_H)
		y += 0.6
	# The blue ring round the kit's platform (r 6.5, 0.8 m), on its skirt.
	var ring2: PackedVector2Array = kit._circle(c, 6.6, 56)
	for k in ring2.size():
		var a := ring2[k]
		_bulb(Vector3(a.x, g + 0.45, a.y), 0.12, Color(0.16, 0.36, 1.0))
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
			Color(0.55, 0.53, 0.47), 1.0)  # was 0.34: a little brighter (F 2026-11-22)


## Metro Centrum's two glass tubes in the market (centre.gd METRO_TUBES, built as `_glass_barrel`: the
## long side q0-q1, the vault half the width less 15 cm, 1 m up): a soft white-green glow, one of the
## few cool accents (F's drone photos; the drone frame's lit "greenhouse" by the tree is the north one).
func _tube_glow() -> void:
	for q: Array in Centre.METRO_TUBES:
		var q0: Vector2 = q[0]
		var q1: Vector2 = q[1]
		var length := q0.distance_to(q1)
		var c: Vector2 = (q0 + q1 + (q[2] as Vector2) + (q[3] as Vector2)) * 0.25
		var r := q1.distance_to(q[2]) * 0.5 + 0.06  # just outside the glass shell (was -0.2: the shell hid the glow, look check 2)
		_barrel_glow(c, (q1 - q0) / length, length + 0.1, r, map.terrain_height(c.x, c.y) + 1.0, Color(0.78, 0.94, 0.84))  # brighter white-green (F 2026-11-22: light the metro entrances as in the reels)


## The kurant's maypole (drone-wide-palace.png, pyramid-real.png; the kit's kurant stands in
## `_kit_objects`, its crown turns in jarmark_rides.gd): strings of warm bulbs from under the crown
## (13.3 m) down to 2.4 m poles 12 m round, where they stand clear of the chalets and the tubes.
func _kurant_strings() -> void:
	kit._jm_frame()
	var c: Vector2 = kit._w(Kit.JM_KURANT.x, Kit.JM_KURANT.y)
	var g: float = kit_ground(map, Kit.JM_KURANT)
	for k in 18:
		var t := TAU * float(k) / 18.0
		var at: Vector2 = Kit.JM_KURANT + Vector2(cos(t), sin(t)) * 12.0
		if at.y < -8.5 or not Kit.jm_clear(at.x, at.y, 0.4) or (absf(at.x - 225.5) < 4.0 and at.y > 15.5) \
				or at.distance_to(GRZANIEC_AT) < 4.0:
			continue
		var w: Vector2 = kit._w(at.x, at.y)
		var gw: float = map.terrain_height(w.x, w.y) + Kit.JM_LIFT
		kit._beam(Vector3(w.x, gw, w.y), Vector3(w.x, gw + 2.4, w.y), 0.07, Color("#1c1d20"), false, PLAIN)
		var d := (w - c).normalized()
		_bulb_line(Vector3(c.x + d.x * 1.3, g + 13.3, c.y + d.y * 1.3), Vector3(w.x, gw + 2.4, w.y), 0.45, 0.05,
				HUT_WARM if k % 2 == 0 else WHITE_BULB, 0.5)


## The fans of warm strings from the tall rides' tops to poles round them (lighting-decision.md: the
## carousel, the kurant (in `_pagoda`), the tree): [centre, top over the ground, radius, strings].
func _ride_fans() -> void:
	# The tops: the kit carousel's spire (6.6 m), under the kit tree's star (11 m on its 35 cm floor).
	for f: Array in [[Kit.JM_CAROUSEL, 6.6, 13.0, 14], [Kit.JM_TREE, 11.35, 13.5, 16]]:
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


## The light-up LED trees (jarmark.gd `_jm_ledtree`: three solid glowing cones, white blobs close up in
## look check 1) as cones of cool white bulbs: a spiral and a ring on each tier's rim (the old cones are
## carved, `_carve_list`). [u, v, height].
const LED_CONES := [[150.5, -6.5, 3.4], [168.5, -7.0, 3.4], [236.5, -7.0, 3.4], [261.0, 22.0, 3.4], [261.0, 37.0, 3.4],
		[261.0, 81.0, 3.4], [155.0, 12.0, 3.4], [155.0, 21.0, 3.4], [92.0, 40.0, 3.4], [86.0, 13.0, 3.4], [97.0, 13.0, 3.4],
		[196.6, 85.0, 3.8], [214.6, 85.0, 3.8], [186.7, 87.5, 2.6], [198.3, 87.5, 2.6]]


func _led_cones() -> void:
	var cool := Color(0.85, 0.9, 1.0)
	for t: Array in LED_CONES:
		var c := Kit._jm_world(float(t[0]), float(t[1]))
		var g: float = map.terrain_height(c.x, c.y) + 0.8
		var h: float = t[2]
		var r := h * 0.3
		for k in 3:
			var y0 := g + h * 0.3 * float(k)
			var r0 := r * (1.0 - 0.28 * float(k))
			var n := 12 - 3 * k
			for j in n:
				var a := TAU * float(j) / float(n) + 0.4 * float(k)
				_bulb(Vector3(c.x + cos(a) * r0, y0 + 0.05, c.y + sin(a) * r0), 0.05, cool)
			for j in 14:
				var f := float(j) / 14.0
				var a := f * TAU * 1.5 + float(k)
				var rr := lerpf(r0, r0 * 0.25, f)
				_bulb(Vector3(c.x + cos(a) * rr, y0 + f * h * 0.42, c.y + sin(a) * rr), 0.045, cool)
		_bulb(Vector3(c.x, g + h * 1.02, c.y), 0.1, Color(1.0, 0.9, 0.62))


## The WESOŁYCH ŚWIĄT sign by the south gate (JM_ANCHORS "wesolych-swiat-south"; look check 1: dark
## from behind and its 5 cm bulbs under a pixel): its letters again as the promo's bulbs (never under
## ~1.3 px), on both faces, each reading the right way round.
func _sign_bulbs() -> void:
	var r := Kit.jm_anchor("wesolych-swiat-south")
	var at := Vector2(r.x, r.y)
	var g: float = map.terrain_height(at.x, at.y)
	var gold := Color(1.0, 0.9, 0.66)
	for back in [false, true]:
		var yaw: float = r.z + (PI if back else 0.0)
		var lv := -0.2 if back else -0.09
		_bulb_word(at, yaw, g, "WESOŁYCH", lv, 3.5, 1.0, gold)
		_bulb_word(at, yaw, g, "ŚWIĄT", lv, 1.0, 1.75, gold)


## One word in bulbs as jarmark_kit.gd `bulb_word` lays it (the pixel font, a bulb a pixel), centred
## on the frame (origin `at`, yaw as the kit's), at local v `lv`, its body's bottom y over g, h tall.
func _bulb_word(at: Vector2, yaw: float, g: float, text: String, lv: float, y: float, h: float, col: Color) -> void:
	var u := Vector2.from_angle(yaw)
	var v := Vector2(-u.y, u.x)
	var sx := h / 7.0
	var width := 0.0
	for ch in text:
		width += (int(kit._pow_glyph_w(ch)) + 1) * sx
	width -= sx
	var x := width * 0.5
	for ch in text:
		if ch != " ":
			for q: Vector2i in kit._pow_glyph(ch):
				var row := 2 + 6 - q.y
				var p := at + u * (x - float(q.x) * sx) + v * lv
				_bulb(Vector3(p.x, g + y + float(row) * sx, p.y), sx * 0.32, col)
		x -= (int(kit._pow_glyph_w(ch)) + 1) * sx


## What goes from the city's sectors (the triangles of jarmark.gd's old pieces): the old tree above its
## platform, the old kurant stand-in, tower, carousel and teacups, the GRZANIEC booth the promo's own
## replaces, half the LED fir figures (look check 1: too many; the standing "b" of each pair and every
## other hanging one) and the solid LED cones.
func _carve_list() -> void:
	var add := func(uv: Vector2, rad: float, lo: float, hi: float) -> void:
		_carves.append([Kit._jm_world(uv.x, uv.y), rad, lo, hi])
	add.call(Kit.JM_TREE, 7.6, 0.42, 30.0)
	add.call(Kit.JM_KURANT, 3.6, 0.3, 12.0)
	add.call(Kit.JM_TOWER, 5.1, 0.15, 45.0)
	add.call(Kit.JM_CAROUSEL, 6.1, 0.1, 12.0)
	add.call(Kit.JM_TEACUPS, 6.1, 0.1, 6.0)
	var gk: Array = Kit.JM_ANCHORS["grzaniec-kurant"]
	add.call(Vector2(gk[1], gk[2]), 3.4, 0.31, 4.0)
	for name: String in Kit.JM_ANCHORS:
		var e: Array = Kit.JM_ANCHORS[name]
		if e[4] != 0 or not str(e[0]).begins_with("led_figure"):
			continue
		var hung := str(e[0]) == "led_figure_hung"
		var drop := name.ends_with("b") if not hung else int(name.get_slice("-", 3)) % 2 == 0
		if drop:
			add.call(Vector2(e[1], e[2]), 1.36, 4.9 if hung else 0.3, 9.5 if hung else 4.5)
	for t: Array in LED_CONES:
		add.call(Vector2(t[0], t[1]), 1.2, 0.85, 0.8 + float(t[2]) * 1.1 + 0.3)
	for i in _carves.size():
		var c: Array = _carves[i]
		var at: Vector2 = c[0]
		var rad: float = c[1]
		var box := AABB(Vector3(at.x - rad, -1000.0, at.y - rad), Vector3(rad * 2.0, 3000.0, rad * 2.0))
		_carve_box = box if i == 0 else _carve_box.merge(box)
		for cx in range(floori((at.x - rad) / 8.0), floori((at.x + rad) / 8.0) + 1):
			for cz in range(floori((at.y - rad) / 8.0), floori((at.y + rad) / 8.0) + 1):
				var k := Vector2i(cx, cz)
				if not _carve_cells.has(k):
					_carve_cells[k] = []
				(_carve_cells[k] as Array).append(i)


## Carves the sectors already in and every one that comes in later (the streamer's sector_ready), and
## turns the city's shared materials down for the promo. Nothing to do on a check's stub map.
func _start_carving() -> void:
	if "building_material" in map:
		_tune_material(map.get("building_material"))
	if "flat_material" in map:
		_tune_material(map.get("flat_material"))
	for n in map.find_children("*", "MeshInstance3D", true, false):
		_carve_node(n as MeshInstance3D)
	# main.gd's SectorStreamer: on an ancestor (main.gd holds `streamer`; the places hang under its world).
	var n := get_parent()
	while n != null:
		var streamer: Variant = n.get("streamer") if "streamer" in n else null
		if streamer is Object and (streamer as Object).has_signal("sector_ready"):
			(streamer as Object).connect("sector_ready", _on_sector_ready)
			print("jarmark promo: carving each sector as it comes in")
			if bool((streamer as Object).get("prebuilt")):
				_check_stamp()
			break
		n = n.get_parent()


## The Mac's capture test at 70e7a1a (2026-11-21): the huts of the field were missing, only this
## dressing's counters, awnings and bulbs stood on the car park's bay lines: the prebuilt sectors had
## no market (baked from another jarmark.gd). Say so loudly: the fix is a re-bake (tools/bake_sectors.py,
## then bake_city.gd with a renderer), or a --runtime promo.
func _check_stamp() -> void:
	const STAMP := "res://map/sectors/city.stamp"
	if not FileAccess.file_exists(STAMP):
		return
	var stamp: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAMP))
	if not stamp is Dictionary:
		return
	var inputs: Dictionary = (stamp as Dictionary).get("inputs", {})
	for f in ["scripts/landmarks/jarmark.gd", "scripts/landmarks/jarmark_kit.gd"]:
		if FileAccess.get_sha256("res://" + f) != str(inputs.get(f, "")):
			push_warning("jarmark promo: the prebuilt sectors were baked from another %s: the market in them is stale (missing huts or old pieces). Re-bake (python3 -I tools/bake_sectors.py, then bake_city.gd with a renderer) or run the promo with --runtime." % f)


func _on_sector_ready(root: Node3D) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		_carve_node(n as MeshInstance3D)


## The promo's lower M_LAMP on the building shader and the soft lamp pools on the ground shader (both
## uniforms default to the game's look).
func _tune_material(m: Variant) -> void:
	var sm := m as ShaderMaterial
	if sm == null or sm.shader == null or sm.has_meta("jm_tuned"):
		return
	sm.set_meta("jm_tuned", true)
	var path := sm.shader.resource_path
	if path.contains("building"):
		sm.set_shader_parameter("lamp_gain", CITY_LAMP_GAIN)
	elif path.contains("ground"):
		sm.set_shader_parameter("pool_soft", 1.0)


func _carve_node(mi: MeshInstance3D) -> void:
	if mi == null:
		return
	_tune_material(mi.material_override)
	var src := mi.mesh as ArrayMesh
	if src == null or mi.has_meta("jm_carved"):
		return
	if mi.material_override == null:
		for s in src.get_surface_count():
			_tune_material(src.surface_get_material(s))
	# The streamer's first sector_ready comes before the sector is in the tree (no world transform yet):
	# its second, once every node is in, carves it.
	if not mi.is_inside_tree():
		return
	var xf := mi.global_transform
	if not (xf * src.get_aabb()).intersects(_carve_box):
		return
	mi.set_meta("jm_carved", true)
	var out := ArrayMesh.new()
	var cut := 0
	var custom := 0
	for sh: int in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT,
			Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
		custom |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << sh
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var flags := src.surface_get_format(s) & custom
		if src.surface_get_primitive_type(s) == Mesh.PRIMITIVE_TRIANGLES:
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx := PackedInt32Array()
			if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
				idx = arr[Mesh.ARRAY_INDEX]
			else:
				idx.resize(verts.size())
				for i in verts.size():
					idx[i] = i
			var keep := PackedInt32Array()
			keep.resize(idx.size())
			var nk := 0
			for t in range(0, idx.size() - 2, 3):
				var a := xf * verts[idx[t]]
				var b := xf * verts[idx[t + 1]]
				var c := xf * verts[idx[t + 2]]
				if _carved(a, b, c):
					cut += 1
					continue
				keep[nk] = idx[t]
				keep[nk + 1] = idx[t + 1]
				keep[nk + 2] = idx[t + 2]
				nk += 3
			keep.resize(nk)
			if nk == 0:
				continue
			arr[Mesh.ARRAY_INDEX] = keep
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), arr, [], {}, flags)
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(s))
	if cut == 0:
		return
	mi.mesh = out
	_carved_tris += cut
	if is_inside_tree() and Engine.get_process_frames() > 0:
		print("jarmark promo: %d old triangles carved from %s" % [cut, mi.name])


## Is the triangle a, b, c (world) one of an old piece's: all three corners inside a carve's circle,
## its middle between the carve's heights over the terrain there?
func _carved(a: Vector3, b: Vector3, c: Vector3) -> bool:
	var m := (a + b + c) / 3.0
	if not _carve_box.has_point(m):
		return false
	var cell: Variant = _carve_cells.get(Vector2i(floori(m.x / 8.0), floori(m.z / 8.0)))
	if cell == null:
		return false
	for i: int in cell:
		var k: Array = _carves[i]
		var at: Vector2 = k[0]
		var r2: float = float(k[1]) * float(k[1])
		if Vector2(a.x, a.z).distance_squared_to(at) > r2 or Vector2(b.x, b.z).distance_squared_to(at) > r2 \
				or Vector2(c.x, c.z).distance_squared_to(at) > r2:
			continue
		var h := m.y - float(map.terrain_height(m.x, m.z))
		if h >= float(k[2]) and h <= float(k[3]):
			return true
	return false
