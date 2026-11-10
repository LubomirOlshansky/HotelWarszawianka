extends Node3D
## The Warsaw Spire's moving parts (F, 2026-11-06, from his photos): the LED ticker that runs round
## the crown with the phone brand's parody adverts, and the jets of the plaza's fountains (the big
## pool, its two small pools and the pebble channel beside Spire B). The tower, the wings, the pools'
## granite rims, the channel and the trees are static (landmarks.gd `_spire*`); this node adds what
## moves, on both city paths (it isn't in the sector scenes), like tarasy_screen.gd.
## Two meshes, two draw calls: the ticker (shaders/spire_ticker.gdshader: the text is one small
## texture scrolled in the shader, no per-frame script work) and every jet together
## (shaders/spire_jets.gdshader: each jet bobs in the vertex shader).
## The tower's plan and its flare are here too (`plan`, `k_at`), so landmarks.gd lofts the tower and
## this node wraps the ticker round the same rings.

const Pixel := preload("res://scripts/pixel_font.gd")

const TOWER := "Warsaw Spire"
## The tower's shape (F's photos IMG_7349 to 7352, 2026-11-06: "concave, not convex"): a vase. A
## little narrower from the lobby to a waist about 45 m up, then the sides curve in as they flare out
## ever faster to the widest plan (the mapped outline) at the roof, 180 m. `k` scales the plan about
## its centre.
const K_FOOT := 0.80
const K_WAIST := 0.72
const H_WAIST := 45.0
const FLARE := 1.8         # the flare's exponent: over 1 makes the sides concave
const K_TOP := 1.0
const H_WIDE := 180.0
const ROOF := 180.0
## The ticker: a band of LEDs round the crown, under the roof's rim (where the real tower carries its
## brand), metres above the ground.
const TICK_Y0 := 165.5
const TICK_Y1 := 171.1
const TICK_OUT := 0.25        # off the glass
const TICK_PX := 0.5          # metres per LED (the font's rows: 10 to a line)
const TICK_SPEED := 7.0       # metres a second, right to left as one reads it
## The adverts (Polish on the sign; English glosses for the data's readers). SAMSONG is the game's
## parody of the phone brand; the models and slogans are invented.
const ADS := [
	["SAMSONG GALAKTYKA Z26", "SAMSONG GALAKTYKA Z26"],
	["SKŁADA SIĘ SZYBCIEJ NIŻ TWÓJ BUDŻET", "it folds faster than your budget"],
	["BATERIA WYTRZYMA KOREK NA TOWAROWEJ", "the battery outlasts a Towarowa jam"],
	["APARAT 200 MPX: WIDAĆ KONIEC REMONTU", "200 MP camera: you can see the end of the roadworks"],
	["RATY 0% DO 2050 ROKU", "0% instalments until 2050"],
]
const TICK_BRAND := Color(0.35, 0.8, 1.0)
const TICK_TEXT := Color(1.0, 1.0, 1.0)
const TICK_DOT := Color(1.0, 0.62, 0.15)

## The plaza's water (OpenStreetMap: the big pool with its fountain basin, two small pools; the pebble
## channel along Spire B's west face from F's photo IMG_7330). World x east, z south.
const FOUNTAIN := Vector2(-2694.7, 149.6)
const POOLS := [Vector2(-2690.0, 164.0), Vector2(-2699.0, 136.2)]
const CHANNEL := [Vector2(-2685.6, 181.0), Vector2(-2686.3, 189.0), Vector2(-2686.6, 197.0),
		Vector2(-2686.5, 204.0), Vector2(-2686.0, 210.0), Vector2(-2685.2, 215.5)]
const CHANNEL_W := 2.6
## The jets: [x, z, height, radius]: a ring of eight round the basin and its tall middle one, a pair
## in each small pool, bubblers down the channel.
static func jets() -> Array:
	var out: Array = [[FOUNTAIN.x, FOUNTAIN.y, 3.4, 0.16]]
	for k in 8:
		var p := FOUNTAIN + Vector2.from_angle(TAU * (k + 0.5) / 8.0) * 4.2
		out.append([p.x, p.y, 1.7, 0.1])
	for c: Vector2 in POOLS:
		out.append([c.x - 1.2, c.y, 0.9, 0.08])
		out.append([c.x + 1.2, c.y, 0.9, 0.08])
	var line := channel_line()
	for i in range(1, line.size() - 1, 3):
		var p: Vector2 = line[i]
		out.append([p.x, p.y, 0.45, 0.07])
	return out


## The channel's centre line, smoothed into short steps (Catmull-Rom through CHANNEL).
static func channel_line() -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := CHANNEL.size()
	for i in n - 1:
		var p0: Vector2 = CHANNEL[maxi(i - 1, 0)]
		var p1: Vector2 = CHANNEL[i]
		var p2: Vector2 = CHANNEL[i + 1]
		var p3: Vector2 = CHANNEL[mini(i + 2, n - 1)]
		for s in 4:
			var t := s / 4.0
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	out.append(CHANNEL[n - 1])
	return out


var map: Node3D
var ticker: MeshInstance3D
var jet_mesh: MeshInstance3D
var tick_length := 0.0


## The plan's share of the mapped (widest) outline at height h.
static func k_at(h: float) -> float:
	if h <= H_WAIST:
		var t := clampf(h / H_WAIST, 0.0, 1.0)
		return lerpf(K_FOOT, K_WAIST, 0.5 - 0.5 * cos(PI * t))
	var u := clampf((h - H_WAIST) / (ROOF - H_WAIST), 0.0, 1.0)
	return K_WAIST + (K_TOP - K_WAIST) * pow(u, FLARE)


## The mapped outline with its doubled points dropped (OpenStreetMap draws the entrance's notch in
## points a few centimetres apart).
static func plan(outline: PackedVector2Array) -> PackedVector2Array:
	var base := PackedVector2Array()
	for q in outline:
		if base.is_empty() or (q.distance_to(base[-1]) > 1.2 and q.distance_to(base[0]) > 1.2):
			base.append(q)
	return base


static func centre(base: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q in base:
		c += q
	return c / maxf(base.size(), 1)


## The ring at height h (metres over the tower's ground), `out` metres proud of the glass.
static func ring(base: PackedVector2Array, h: float, out := 0.0) -> PackedVector2Array:
	var c := centre(base)
	var k := k_at(h)
	var r := PackedVector2Array()
	for q in base:
		var d := q - c
		r.append(c + d * k + d.normalized() * out)
	return r


func _outline() -> PackedVector2Array:
	if map == null:
		return PackedVector2Array()
	for l in (map.data as Dictionary).get("landmarks", []):
		if l["name"] == TOWER:
			var p: Array = l["p"]
			var out := PackedVector2Array()
			for i in range(0, p.size() - 1, 2):
				out.append(Vector2(float(p[i]), float(p[i + 1])))
			return out
	return PackedVector2Array()


func _ground(poly: PackedVector2Array) -> float:
	var g := INF
	for q in poly:
		g = minf(g, map.terrain_height(q.x, q.y))
	return g if g < INF else 0.0


func build() -> void:
	var base := plan(_outline())
	if base.size() >= 3:
		_build_ticker(base, _ground(base))
	_build_jets()


## The ticker: the ring at TICK_Y0..TICK_Y1 as one strip, UV in metres (x round, y up).
func _build_ticker(base: PackedVector2Array, g: float) -> void:
	var r0 := ring(base, TICK_Y0, TICK_OUT)
	var r1 := ring(base, TICK_Y1, TICK_OUT)
	var c := centre(base)
	# Walk the ring so that, seen from outside, it runs to the reader's right (forward x up).
	var e0 := r0[1] - r0[0]
	var o0 := (r0[0] + r0[1]) * 0.5 - c
	var right := Vector3(-o0.x, 0.0, -o0.y).cross(Vector3.UP)
	if e0.x * right.x + e0.y * right.z < 0.0:
		r0.reverse()
		r1.reverse()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := r0.size()
	var s := 0.0
	for i in n:
		var j := (i + 1) % n
		var s1 := s + r0[i].distance_to(r0[j])
		var e := (r0[j] - r0[i]).normalized()
		var o := Vector2(e.y, -e.x)
		if o.dot((r0[i] + r0[j]) * 0.5 - c) < 0.0:
			o = -o
		# Walked so the text reads left to right from outside: a, b along the ring, then up.
		var v := [
			[Vector3(r0[i].x, g + TICK_Y0, r0[i].y), Vector2(s, 0.0)],
			[Vector3(r0[j].x, g + TICK_Y0, r0[j].y), Vector2(s1, 0.0)],
			[Vector3(r1[j].x, g + TICK_Y1, r1[j].y), Vector2(s1, TICK_Y1 - TICK_Y0)],
			[Vector3(r1[i].x, g + TICK_Y1, r1[i].y), Vector2(s, TICK_Y1 - TICK_Y0)]]
		var nrm := Vector3(o.x, 0.0, o.y)
		# Front faces wind clockwise seen from outside.
		var a: Vector3 = v[0][0]
		var b: Vector3 = v[1][0]
		var cc: Vector3 = v[2][0]
		var order := [0, 2, 1, 0, 3, 2] if (b - a).cross(cc - a).dot(nrm) > 0.0 else [0, 1, 2, 0, 2, 3]
		for k in order:
			st.set_normal(nrm)
			st.set_uv(v[k][1])
			st.add_vertex(v[k][0])
		s = s1
	tick_length = s
	ticker = MeshInstance3D.new()
	ticker.name = "SpireTicker"
	ticker.mesh = st.commit()
	ticker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tex := _ads_texture()
	# Stretch the LEDs a little sideways so the text's length is a whole number of laps: the strip's
	# start and end meet without a seam.
	var laps := maxf(1.0, roundf(tex.get_width() * TICK_PX / maxf(s, 1.0)))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/spire_ticker.gdshader")
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mat.set_shader_parameter("px_m", Vector2(s * laps / tex.get_width(), TICK_PX))
	mat.set_shader_parameter("band", TICK_Y1 - TICK_Y0)
	mat.set_shader_parameter("speed", TICK_SPEED)
	ticker.material_override = mat
	add_child(ticker)
	print("spire ticker: %.1f m round, %d LEDs of text, %d laps" % [s, tex.get_width(), int(laps)])


## Every advert on one line, brand in blue, slogans in white, an amber dot between.
func _ads_texture() -> ImageTexture:
	var parts: Array = []
	for ad: Array in ADS:
		parts.append([ad[0], TICK_BRAND if String(ad[0]).begins_with("SAMSONG") else TICK_TEXT])
		parts.append(["·", TICK_DOT])
	var gap := 6
	var wide := 0
	for p: Array in parts:
		wide += Pixel.width(p[0]) + gap
	var img := Image.create_empty(wide, Pixel.ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	var x := 0
	for p: Array in parts:
		Pixel.draw(img, p[0], x, 0, p[1])
		x += Pixel.width(p[0]) + gap
	return ImageTexture.create_from_image(img)


## The jets: each a slim six-sided cone of water with a wider splash ring at its foot. UV2.x is the
## jet's foot height (world y), UV2.y its phase, for the shader's bob.
func _build_jets() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k := 0
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for j: Array in jets():
		var p := Vector2(float(j[0]), float(j[1]))
		var y: float = (map.terrain_height(p.x, p.y) if map != null else 0.0) + 0.3
		var h := float(j[2])
		var r := float(j[3])
		var phase := float(k) * 1.37
		k += 1
		_cone(st, p, y, y + h, r * 1.6, r * 0.45, y, phase)
		_cone(st, p, y, y + h * 0.18, r * 4.0, r * 2.2, y, phase + 0.6)
		lo = lo.min(Vector3(p.x - 1.0, y, p.y - 1.0))
		hi = hi.max(Vector3(p.x + 1.0, y + h * 1.3, p.y + 1.0))
	jet_mesh = MeshInstance3D.new()
	jet_mesh.name = "SpireJets"
	jet_mesh.mesh = st.commit()
	jet_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	jet_mesh.custom_aabb = AABB(lo, hi - lo)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/spire_jets.gdshader")
	jet_mesh.material_override = mat
	add_child(jet_mesh)


func _cone(st: SurfaceTool, p: Vector2, y0: float, y1: float, r0: float, r1: float, foot: float, phase: float) -> void:
	var sides := 6
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		var q := [Vector3(p.x + d0.x * r0, y0, p.y + d0.y * r0), Vector3(p.x + d1.x * r0, y0, p.y + d1.y * r0),
				Vector3(p.x + d1.x * r1, y1, p.y + d1.y * r1), Vector3(p.x + d0.x * r1, y1, p.y + d0.y * r1)]
		var mid := (d0 + d1).normalized()
		var nrm := Vector3(mid.x, 0.35, mid.y).normalized()
		for v in [0, 2, 1, 0, 3, 2]:
			st.set_normal(nrm)
			st.set_uv(Vector2(float(i) / sides, (q[v] as Vector3).y - y0))
			st.set_uv2(Vector2(foot, phase))
			st.add_vertex(q[v])
