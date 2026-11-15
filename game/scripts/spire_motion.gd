extends "res://scripts/place.gd"
## The Warsaw Spire's moving parts and lights (F, 2026-11-06 and 2026-11-14, from his photos): the
## LED band that runs round the top of the glass with the GeoBent advert and KOCHAM WARSZAWĘ, the
## night lines of light on the slab edges, the fins, the rim and the drum, and the jets of the plaza's fountains (the big
## pool, its two small pools and the pebble channel beside Spire B). The tower, the wings, the pools'
## granite rims, the channel and the trees are static (landmarks.gd `_spire*`); this node adds what
## moves, on both city paths (it isn't in the sector scenes), like tarasy_screen.gd.
## Two meshes, two draw calls: the lights (shaders/spire_ticker.gdshader: the text is one small
## texture scrolled in the shader, the lines lit by `lights_on`, no per-frame script work) and every jet together
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
## The tower's rings (metres over its ground): the shaft is lofted straight from one to the next
## (landmarks.gd `_spire`), so whatever lies on the glass between two of them (`on_glass`) follows
## that loft and not the curve `k_at`. 148, 158 and 165.5 carry the LED band's rows.
const RINGS := [10.0, 25.0, 45.0, 65.0, 85.0, 103.0, 120.0, 135.0, 148.0, 158.0, 165.5, 171.1, 176.0, 180.0]
## The LED band (F, 2026-11-14, his night photos: the real tower writes KOCHAM WARSZAWĘ in letters
## three floors tall across the top of the glass, in blue or violet): a running sign behind the
## glass, 148 to 165.5 m, LEDs 1.2 m apart, so the letters stand 8.4 m tall and read from the street.
## Unlit LEDs are not drawn: the glass shows between the letters, as on the real tower.
const TICK_Y0 := 148.0
const TICK_Y1 := 165.5
const TICK_OUT := 0.3         # off the glass
const TICK_PX := 1.2          # metres per LED (the font's rows: 10 to a line)
const TICK_SPEED := 9.0       # metres a second, right to left as one reads it
## The advert (F, 2026-11-14: "a running GeoBent ad with its logo"; F asked for the real firm by
## name, the one exception to the parody-brands rule, noted in the PR), then the tower's own
## KOCHAM WARSZAWĘ. Polish on the sign; English glosses for the data's readers. Each part is
## [text, colour, gloss]; "@logo" and "@heart" are drawn from LOGO and HEART.
const GEO_BLUE := Color(0.43, 0.45, 1.0)      # the logo's navy (#272878), bright enough to read as LEDs
const GEO_ORANGE := Color(1.0, 0.5, 0.24)     # the logo's orange (#e36f3e)
const LED_WHITE := Color(0.92, 0.95, 1.0)
const LED_VIOLET := Color(0.78, 0.42, 1.0)    # the violet KOCHAM WARSZAWĘ (F's photo IMG_7978)
const LED_CYAN := Color(0.45, 0.85, 1.0)      # the blue one (IMG_7977, 7979)
const ADS := [
	["@logo", GEO_ORANGE, "the GeoBent mark"],
	["GEOBENT", GEO_BLUE, "GeoBent"],
	["·", GEO_ORANGE, ""],
	["NIEZAWODNY PARTNER:", LED_WHITE, "a reliable partner:"],
	["BENTONIT", GEO_ORANGE, "bentonite"],
	["DLA BUDOWNICTWA, ODLEWNI I ROLNICTWA", LED_WHITE, "for construction, foundries and farming"],
	["·", GEO_ORANGE, ""],
	["GEOBENT.PL", GEO_BLUE, "geobent.pl"],
	["@logo", GEO_ORANGE, ""],
	["   ", LED_WHITE, ""],
	["@heart", Color(1.0, 0.25, 0.35), ""],
	["KOCHAM WARSZAWĘ", LED_VIOLET, "I love Warsaw (the tower's own sign)"],
	["@heart", Color(1.0, 0.25, 0.35), ""],
	["   ", LED_WHITE, ""],
	["@logo", GEO_ORANGE, ""],
	["GEOBENT", LED_CYAN, ""],
	["·", GEO_ORANGE, ""],
	["KOCHAM WARSZAWĘ", LED_CYAN, ""],
	["·", GEO_ORANGE, ""],
]
## The GeoBent mark in LEDs (F's screenshot of geobent.pl): a flat open diamond, orange on its
## upper left and navy on its right and its front, over an orange chevron and a navy one, the
## three layers of a stack. o orange, n navy; rows from the cell's top (the font's 10).
const LOGO := [
	".....oon.....",
	"...oo...nn...",
	".oo.......nn.",
	"nn.........nn",
	"..nn.....nn..",
	"o...nnnnn...o",
	".ooo.....ooo.",
	"n...ooooo...n",
	".nnn.....nnn.",
	"....nnnnn....",
]
const HEART := [
	"..........",
	"..........",
	".##...##..",
	"####.####.",
	"#########.",
	"#########.",
	".#######..",
	"..#####...",
	"...###....",
	"....#.....",
]
## The night lights on the glass (the night photos IMG_7975 to 7979): a cyan line of LEDs along
## every slab edge, brighter the higher it is; the lit edge up each fin; a pink-red line round the
## roof's rim and a violet one round the drum. One mesh with the LED band, one material: the line
## parts (vertex alpha LINE) light only at night and are not drawn by day.
const FLOOR := 3.8
const LINE_FROM := 25.0
const LINE_W := 0.35
const LINE_GLASS := Color(0.08, 0.42, 1.0)
const LINE_MULLION := Color(0.05, 0.25, 0.85)
const MULLION_EVERY := 5.0   # metres round the ring between the vertical lines
const LINE_FIN := Color(0.3, 0.85, 1.0)
const LINE_RIM := Color(1.0, 0.25, 0.45)
const LINE_DRUM := Color(0.55, 0.35, 1.0)
const MODE_LED := 0.0
const MODE_LINE := 0.5
## The fins (landmarks.gd `_spire_fins`): a glass blade standing out of each narrow end from
## FIN_FROM to past the crown, FIN_OUT deep.
const FIN_FROM := 19.0
const FIN_OUT := 1.6
const FIN_TOP := 196.0

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


## The point at height h on the lofted glass (straight between the two RINGS round h, as
## landmarks.gd builds it), `out` metres proud of it, for each point of the plan.
static func on_glass(base: PackedVector2Array, h: float, out := 0.0) -> PackedVector2Array:
	var h0: float = RINGS[0]
	var h1: float = RINGS[RINGS.size() - 1]
	for k in RINGS.size() - 1:
		if h >= RINGS[k] and h <= RINGS[k + 1]:
			h0 = RINGS[k]
			h1 = RINGS[k + 1]
			break
	var t := clampf((h - h0) / maxf(h1 - h0, 0.001), 0.0, 1.0)
	var c := centre(base)
	var k0 := k_at(minf(h0, ROOF))
	var k1 := k_at(minf(h1, ROOF))
	var r := PackedVector2Array()
	for q in base:
		var d := q - c
		r.append(c + d * lerpf(k0, k1, t) + d.normalized() * out)
	return r


## The tower's long axis, pointing to its north end (the entrance).
static func axis_of(base: PackedVector2Array) -> Vector2:
	var c := centre(base)
	var axis := Vector2.ZERO
	for q in base:
		if (q - c).length() > axis.length():
			axis = q - c
	axis = axis.normalized()
	return -axis if axis.y > 0.0 else axis


## The front edge of the fin at the narrow end along `d` (axis or -axis), at height h: FIN_OUT out
## from the glass; over the roof it stands straight up from the roof's edge.
static func fin_edge(base: PackedVector2Array, d: Vector2, h: float) -> Vector2:
	var c := centre(base)
	var best := 0
	for i in base.size():
		if (base[i] - c).dot(d) > (base[best] - c).dot(d):
			best = i
	var p: Vector2 = on_glass(base, minf(h, ROOF))[best]
	return p + d * FIN_OUT


## The tower's mapped outline. The runtime city keeps the whole map in `data`; the prebuilt city
## keeps none (its `data` is empty, the landmarks live in the index: `index_data`, outlines packed),
## so both are read, or the lights mesh came out empty on the phone's path (found 2026-11-15).
func _outline() -> PackedVector2Array:
	if map == null:
		return PackedVector2Array()
	var lists: Array = [(map.data as Dictionary).get("landmarks", [])]
	if "index_data" in map:
		lists.append((map.index_data as Dictionary).get("landmarks", []))
	for list: Array in lists:
		for l in list:
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


## The lights: the LED band and the night lines, one mesh and one material (spire_lights.gdshader).
## Vertex colour: rgb the line's light, alpha the mode (MODE_LED, MODE_LINE). LED band UV in metres
## (x round, y up the band); a line's UV.y its brightness.
func _build_ticker(base: PackedVector2Array, g: float) -> void:
	var c := centre(base)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The band: rows at the rings inside it, so it lies flat on the lofted glass.
	var rows: Array[float] = [TICK_Y0]
	for h: float in RINGS:
		if h > TICK_Y0 and h < TICK_Y1:
			rows.append(h)
	rows.append(TICK_Y1)
	var walk := _reading_order(base, c)
	var mid := on_glass(base, rows[rows.size() / 2], TICK_OUT)
	var s := 0.0
	var cum: Array[float] = []
	for k in walk.size() + 1:
		cum.append(s)
		var i: int = walk[k % walk.size()]
		var j: int = walk[(k + 1) % walk.size()]
		s += mid[i].distance_to(mid[j])
	var length: float = cum[walk.size()]
	for r in rows.size() - 1:
		var lo := on_glass(base, rows[r], TICK_OUT)
		var hi := on_glass(base, rows[r + 1], TICK_OUT)
		for k in walk.size():
			var i: int = walk[k]
			var j: int = walk[(k + 1) % walk.size()]
			_face(st, c, [Vector3(lo[i].x, g + rows[r], lo[i].y), Vector3(lo[j].x, g + rows[r], lo[j].y),
					Vector3(hi[j].x, g + rows[r + 1], hi[j].y), Vector3(hi[i].x, g + rows[r + 1], hi[i].y)],
					[Vector2(cum[k], rows[r] - TICK_Y0), Vector2(cum[k + 1], rows[r] - TICK_Y0),
					Vector2(cum[k + 1], rows[r + 1] - TICK_Y0), Vector2(cum[k], rows[r + 1] - TICK_Y0)],
					Color(0, 0, 0, MODE_LED))
	tick_length = length
	# The slab edges, from LINE_FROM to under the band and from over it to the rim.
	var h := LINE_FROM
	while h < ROOF - 2.0:
		if h + LINE_W < TICK_Y0 - 0.5 or h > TICK_Y1 + 0.5:
			var bright := lerpf(0.25, 1.0, clampf((h - LINE_FROM) / (ROOF - LINE_FROM), 0.0, 1.0))
			_ring_line(st, base, c, g, h, h + LINE_W, LINE_GLASS, bright)
		h += FLOOR
	_ring_line(st, base, c, g, ROOF - 1.0, ROOF - 0.3, LINE_RIM, 1.2)
	# The vertical lines: the mullions picked out in blue, every MULLION_EVERY metres round,
	# fading out towards the foot (the night photos: the whole glass reads blue).
	_mullions(st, base, c, g)
	# The drum's band (the drum stands at 0.74 of the roof's plan, 180 to 187 m).
	var top := ring(base, ROOF)
	var drum := PackedVector2Array()
	for q in top:
		drum.append(c + (q - c) * 0.74 + (q - c).normalized() * 0.12)
	_loop_line(st, drum, c, g + ROOF + 5.6, g + ROOF + 6.6, LINE_DRUM, 1.0)
	# The fins' lit edges.
	var axis := axis_of(base)
	for d: Vector2 in [axis, -axis]:
		var side := Vector2(-d.y, d.x) * 0.3
		var hs: Array[float] = [FIN_FROM]
		for r: float in RINGS:
			if r > FIN_FROM:
				hs.append(r)
		hs.append(FIN_TOP)
		for k in hs.size() - 1:
			var p0 := fin_edge(base, d, hs[k]) + d * 0.05
			var p1 := fin_edge(base, d, hs[k + 1]) + d * 0.05
			_face(st, c, [Vector3(p0.x - side.x, g + hs[k], p0.y - side.y), Vector3(p0.x + side.x, g + hs[k], p0.y + side.y),
					Vector3(p1.x + side.x, g + hs[k + 1], p1.y + side.y), Vector3(p1.x - side.x, g + hs[k + 1], p1.y - side.y)],
					[Vector2(0, 1.3), Vector2(0, 1.3), Vector2(0, 1.3), Vector2(0, 1.3)], Color(LINE_FIN, MODE_LINE), d)
	ticker = MeshInstance3D.new()
	ticker.name = "SpireTicker"
	ticker.mesh = st.commit()
	ticker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tex := _ads_texture()
	# Stretch the LEDs a little sideways so the text's length is a whole number of laps: the band's
	# start and end meet without a seam.
	var laps := maxf(1.0, roundf(tex.get_width() * TICK_PX / maxf(length, 1.0)))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/spire_ticker.gdshader")
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mat.set_shader_parameter("px_m", Vector2(length * laps / tex.get_width(), TICK_PX))
	mat.set_shader_parameter("band", TICK_Y1 - TICK_Y0)
	mat.set_shader_parameter("speed", TICK_SPEED)
	ticker.material_override = mat
	part(ticker)
	print("spire ticker: %.1f m round, %d LEDs of text, %d laps, %d triangles of lights" % [length, tex.get_width(), int(laps), ticker.mesh.surface_get_array_len(0) / 3])


## The order to walk the plan in so that, seen from outside, the band runs to the reader's right.
func _reading_order(base: PackedVector2Array, c: Vector2) -> Array[int]:
	var out: Array[int] = []
	for i in base.size():
		out.append(i)
	var e0 := base[1] - base[0]
	var o0 := (base[0] + base[1]) * 0.5 - c
	var right := Vector3(-o0.x, 0.0, -o0.y).cross(Vector3.UP)
	if e0.x * right.x + e0.y * right.z < 0.0:
		out.reverse()
	return out


## One quad facing out from the tower's axis (or along `out` when given), its corners a, b, c, d
## (b along the ring from a, c over b), UVs per corner, the vertex colour.
func _face(st: SurfaceTool, c: Vector2, v: Array, uv: Array, col: Color, out := Vector2.ZERO) -> void:
	var a: Vector3 = v[0]
	var b: Vector3 = v[1]
	var cc: Vector3 = v[2]
	var mid := (a + b) * 0.5
	var o := out if out != Vector2.ZERO else (Vector2(mid.x, mid.z) - c)
	# the face's own normal (the plan's segments are not square to the axis at the narrow ends),
	# turned to face out
	var nrm := (b - a).cross((v[3] as Vector3) - a).normalized()
	if nrm.dot(Vector3(o.x, 0.0, o.y)) < 0.0:
		nrm = -nrm
	var order := [0, 2, 1, 0, 3, 2] if (b - a).cross(cc - a).dot(nrm) > 0.0 else [0, 1, 2, 0, 2, 3]
	for k: int in order:
		st.set_color(col)
		st.set_normal(nrm)
		st.set_uv(uv[k])
		st.add_vertex(v[k])


## A line of light round the glass from h0 to h1 (inside one loft step).
func _ring_line(st: SurfaceTool, base: PackedVector2Array, c: Vector2, g: float, h0: float, h1: float, col: Color, bright: float) -> void:
	var lo := on_glass(base, h0, 0.2)
	var hi := on_glass(base, h1, 0.2)
	for i in lo.size():
		var j := (i + 1) % lo.size()
		_face(st, c, [Vector3(lo[i].x, g + h0, lo[i].y), Vector3(lo[j].x, g + h0, lo[j].y),
				Vector3(hi[j].x, g + h1, hi[j].y), Vector3(hi[i].x, g + h1, hi[i].y)],
				[Vector2(0, bright), Vector2(0, bright), Vector2(0, bright), Vector2(0, bright)], Color(col, MODE_LINE))


## The blue mullions: 0.3 m strips up the glass from LINE_FROM to the roof, skipping the LED band,
## every MULLION_EVERY metres round (measured on the roof's ring, so they spread with the flare).
func _mullions(st: SurfaceTool, base: PackedVector2Array, c: Vector2, g: float) -> void:
	var top := on_glass(base, ROOF)
	var n := base.size()
	var cum: Array[float] = [0.0]
	for i in n:
		cum.append(cum[-1] + top[i].distance_to(top[(i + 1) % n]))
	var count := int(cum[n] / MULLION_EVERY)
	var hs: Array[float] = []
	for r: float in RINGS:
		if r >= LINE_FROM:
			hs.append(r)
	for m in count:
		var at := cum[n] * (m + 0.5) / count
		var i := 0
		while cum[i + 1] < at:
			i += 1
		var t := (at - cum[i]) / maxf(cum[i + 1] - cum[i], 0.001)
		var j := (i + 1) % n
		for k in hs.size() - 1:
			var h0 := hs[k]
			var h1 := hs[k + 1]
			if h1 > TICK_Y0 and h0 < TICK_Y1:
				continue
			var r0 := on_glass(base, h0, 0.12)
			var r1 := on_glass(base, h1, 0.12)
			var p0 := r0[i].lerp(r0[j], t)
			var p1 := r1[i].lerp(r1[j], t)
			var e0 := (r0[j] - r0[i]).normalized() * 0.15
			var e1 := (r1[j] - r1[i]).normalized() * 0.15
			var b0 := lerpf(0.15, 0.8, clampf((h0 - LINE_FROM) / (ROOF - LINE_FROM), 0.0, 1.0))
			var b1 := lerpf(0.15, 0.8, clampf((h1 - LINE_FROM) / (ROOF - LINE_FROM), 0.0, 1.0))
			_face(st, c, [Vector3(p0.x - e0.x, g + h0, p0.y - e0.y), Vector3(p0.x + e0.x, g + h0, p0.y + e0.y),
					Vector3(p1.x + e1.x, g + h1, p1.y + e1.y), Vector3(p1.x - e1.x, g + h1, p1.y - e1.y)],
					[Vector2(0, b0), Vector2(0, b0), Vector2(0, b1), Vector2(0, b1)], Color(LINE_MULLION, MODE_LINE))


## A line of light round a vertical wall `loop`, from y0 to y1.
func _loop_line(st: SurfaceTool, loop: PackedVector2Array, c: Vector2, y0: float, y1: float, col: Color, bright: float) -> void:
	for i in loop.size():
		var j := (i + 1) % loop.size()
		_face(st, c, [Vector3(loop[i].x, y0, loop[i].y), Vector3(loop[j].x, y0, loop[j].y),
				Vector3(loop[j].x, y1, loop[j].y), Vector3(loop[i].x, y1, loop[i].y)],
				[Vector2(0, bright), Vector2(0, bright), Vector2(0, bright), Vector2(0, bright)], Color(col, MODE_LINE))


## The advert on one line of LEDs (ADS), the logo and hearts drawn from their bitmaps.
func _ads_texture() -> ImageTexture:
	var gap := 4
	var wide := 0
	for p: Array in ADS:
		wide += _part_width(p[0]) + gap
	var img := Image.create_empty(wide, Pixel.ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	var x := 0
	for p: Array in ADS:
		var text: String = p[0]
		if text == "@logo" or text == "@heart":
			var bits: Array = LOGO if text == "@logo" else HEART
			for row in bits.size():
				var line: String = bits[row]
				for k in line.length():
					var ch := line[k]
					if ch == "o":
						img.set_pixel(x + k, row, GEO_ORANGE)
					elif ch == "n":
						img.set_pixel(x + k, row, GEO_BLUE)
					elif ch == "#":
						img.set_pixel(x + k, row, p[1])
		else:
			Pixel.draw(img, text, x, 0, p[1])
		x += _part_width(text) + gap
	return ImageTexture.create_from_image(img)


func _part_width(text: String) -> int:
	if text == "@logo":
		return (LOGO[0] as String).length()
	if text == "@heart":
		return (HEART[0] as String).length()
	if text.strip_edges() == "":
		return Pixel.SPACE * text.length()
	return Pixel.width(text)


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
	part(jet_mesh)


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
