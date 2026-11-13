extends Node3D
## The Patelnia at Metro Centrum dressed as a lively entrance (F, 2026-11-13, twelve photos: the
## square from the Palace's side, the aerials from the Palace's terrace and straight down, the
## barrels' mouths, the Pasaż Handlowy front, the murals over the years). The landmark site
## `sunken` (landmarks.gd) sinks the square, walls it and puts Metro Centrum's two glass barrels
## on it; this adds what makes the place read as the busy front door it is:
##  - each barrel's mouth: the blue steel arch with posts, the blue "CENTRUM" band across it with
##    the yellow roundel and red M, the big roundel over it, the yellow door frames folded back and
##    a red ticket machine beside it;
##  - the Pasaż Handlowy (the shopping passage under the square) on the box between the barrels: a
##    lit glass front under a blue fascia, the white sign box "PASAŻ HANDLOWY" with its tenants'
##    tiles, a poster beside it, the pharmacy's green cross (APTEKA 24H), ticket machines and a cash
##    machine; the two courts beside it with lit shopfronts at the back under a blue gateway, a
##    PRASA kiosk and a flower stall;
##  - two big billboards on the pavilions' roof facing the square (parody ads only);
##  - murals on the retaining walls, our own pictures in the themes the real walls have carried:
##    a Warsaw skyline in a blue wave ("DO ZOBACZENIA") by the Kokota stairs, yellow pop faces
##    with blue and orange swooshes, three readers' portraits with speech bubbles, an orange ribbon
##    on white;
##  - the green slope over the south wall: shrubs (some in pink blossom) leaning over the coping and
##    globe lamps along the walk, more globes beside the Kokota stair, handrails down both stairs;
##  - the square's life: a busker with his listeners, a breakdancer in a ring of people, a painter
##    on a ladder at the skyline mural, an easel painter, a gold living statue, a market umbrella and
##    a green tent, advertising columns.
## Built at runtime on both city paths (it isn't in the sector scenes), as centralny_ramp.gd: one
## mesh in the actors' material (models.gd), one draw call in view, no building-shader cost; the
## globes and signs use the material's own night glow (LIT_SIGN / LIT_WINDOW), no lights. Nothing
## here is solid (the square's walls are the site's): drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const MapBuilderStatic := preload("res://scripts/map_builder.gd")

const BLUE := Color("#1f4fa0")
const BLUE_DARK := Color("#183c7a")
const YELLOW := Color("#f6c813")
const RED := Color("#d3202a")
const WHITE := Color("#f4f2ec")
const INK := Color("#1d1d24")
const GLASS_LIT := Color("#e6dcc4")
const DARK := Color("#23272d")
const STEEL := Color("#8d9298")
const GREEN := Color("#21a148")
const SKIN := Color("#e2b48c")
## The line of fronts between the barrels: barrel 1's mouth corner, the box's front (OSM outline
## 5588), barrel 2's mouth corner; `FRONT_OUT` is the square's side (south-south-east).
const BOX_FRONT := [Vector2(-905.6, 398.2), Vector2(-913.0, 401.7)]
const FRONT_OUT := Vector2(0.429, 0.903)
## The courts either side of the box (open to the square): their mouths and the pavilions' face at
## their back (OSM outline 5582), each from the reader's left to right.
const COURTS := [
	[Vector2(-897.8, 395.5), Vector2(-905.6, 398.2), Vector2(-904.6, 381.5), Vector2(-911.8, 385.0)],
	[Vector2(-913.0, 401.7), Vector2(-919.9, 406.0), Vector2(-919.4, 388.6), Vector2(-926.5, 392.0)],
]
## The roof billboards: on the pavilions' two posts (OSM 8058 and 8059, 4-7.5 m), facing the square.
const BILLBOARDS := [Vector2(-909.9, 375.2), Vector2(-928.6, 384.1)]
const BOARD := Vector2(9.0, 3.2)
## The murals: [first ring point, last ring point (wrapping), theme] on the Patelnia's ring
## (map_builder.gd SUNKEN "patelnia").
const MURALS := [
	[24, 29, "skyline"], [29, 0, "pop"], [0, 4, "readers"], [4, 7, "ribbon"],
]
const MURAL_PX := 0.1
const MURAL_ROWS := 32
## Globe lamps: this far out past the south wall, this far apart.
const LAMP_OUT := 4.6
const LAMP_STEP := 7.5

var map: Node3D
var count := 0
var tris := 0
var _rng := RandomNumberGenerator.new()
## The Patelnia's rings as built (map_builder.gd sunk_entry), by key: the runtime city keeps them in
## map._sunk, the prebuilt one doesn't, so they are rebuilt here from SUNKEN.
var _sk := {}
var _ring := PackedVector2Array()
var _mq := 0


## Builds the mesh; `map` gives the ground (terrain_height: the square's floor inside the ring) and
## the sunken rings (map_builder.gd SUNKEN).
func build() -> void:
	for e: Dictionary in MapBuilderStatic.SUNKEN:
		var key := str(e["key"])
		if not key.begins_with("patelnia"):
			continue
		var at: Vector2 = e.get("at", e["a"])
		_sk[key] = MapBuilderStatic.sunk_entry(e, map._grid_height(at.x, at.y), float(map._terrain.get("step", 10.0)))
	if not _sk.has("patelnia"):
		return
	# SUNKEN's own order (the ring as built may be turned round): MURALS count in it.
	var ring := PackedVector2Array(MapBuilderStatic.SUNKEN[0]["ring"])
	_ring = ring
	_rng.seed = 873
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q: Array in Landmarks.PATELNIA_BARRELS:
		_barrel_mouth(st, q)
	_pasaz_front(st)
	for c: Array in COURTS:
		_court(st, c)
	for i in BILLBOARDS.size():
		_billboard(st, BILLBOARDS[i], i)
	for m: Array in MURALS:
		_mural(st, ring, int(m[0]), int(m[1]), str(m[2]))
	_slope(st, ring)
	_stairs(st)
	_square_life(st, ring)
	var mesh := st.commit()
	tris = mesh.surface_get_array_len(0) / 3
	var mi := MeshInstance3D.new()
	print("patelnia: %d pieces, %d triangles (murals %d quads)" % [count, tris, _mq])
	mi.name = "PatelniaDressing"
	mi.mesh = mesh
	mi.material_override = Models.material()
	add_child(mi)


# --- Helpers ---------------------------------------------------------------------------------

func _v(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


## The square's floor (a stair's level on a stair), or the ground outside.
func _floor(p: Vector2) -> float:
	for sk: Dictionary in _sk.values():
		if Geometry2D.is_point_in_polygon(p, sk["ring"]):
			return MapBuilderStatic.sunk_level(sk, p)
	return map.ground_height(p.x, p.y)


## A basis whose -z looks along `f` (plan x, z): a face built on local -z faces f.
static func _facing(f: Vector2) -> Basis:
	return Basis(Vector3.UP, atan2(-f.x, -f.y))


func _box(st: SurfaceTool, c: Vector3, f: Vector2, size: Vector3, col: Color, part := Models.FIXED) -> void:
	Props.obox(st, c, _facing(f), size, col, part)
	count += 1


## A box from a to b (its long axis), `w` across (along `across`) and `t` the third way.
func _seg(st: SurfaceTool, a: Vector3, b: Vector3, across: Vector3, w: float, t: float, col: Color, part := Models.FIXED) -> void:
	var z := (b - a).normalized()
	var x := (across - z * across.dot(z)).normalized()
	var y := z.cross(x)
	Props.obox(st, (a + b) * 0.5, Basis(x, y, z), Vector3(w, t, a.distance_to(b)), col, part)


## A flat quad facing `n` (either winding).
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color, part := Models.FIXED) -> void:
	var q := [a, b, c, d]
	if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
		q = [a, d, c, b]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(Vector2(part, 0.0))
		st.add_vertex(q[k])


## A flat disc of `sides` facing `n` (plan normal), centre `c`.
func _disc(st: SurfaceTool, c: Vector3, n: Vector3, r: float, col: Color, sides := 12, part := Models.FIXED) -> void:
	var right := Vector3.UP.cross(n).normalized()
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		Props.tri(st, c, c + (right * cos(a0) + Vector3.UP * sin(a0)) * r, c + (right * cos(a1) + Vector3.UP * sin(a1)) * r, n, col, part)


## Text centred on `c`, on a face looking along `n` (plan), `px` metres a pixel.
func _text(st: SurfaceTool, text: String, c: Vector3, n: Vector3, px: float, col: Color, part := Models.LIT_SIGN) -> void:
	var right := Vector3.UP.cross(n).normalized()
	var w := PixelFont.width(text) * px
	var origin := c - right * w * 0.5 + Vector3.UP * (PixelFont.BODY + 3.5) * px + n * 0.01
	# The lit pixels merged into runs along each row, and equal runs down the rows (PixelFont's
	# add_quads draws one quad a pixel: four times the triangles on a sign).
	var lit := {}
	PixelFont.each_pixel(text, 0, func(x: int, row: int) -> void:
		lit[Vector2i(x, row)] = true)
	var runs := {}   # Vector3i(x0, x1, row) of each row's runs
	for row in PixelFont.ROWS:
		var x := 0
		var wpx := PixelFont.width(text)
		while x < wpx:
			if not lit.has(Vector2i(x, row)):
				x += 1
				continue
			var e := x + 1
			while lit.has(Vector2i(e, row)):
				e += 1
			runs[Vector3i(x, e, row)] = true
			x = e
	for key: Vector3i in runs.keys():
		if runs.has(Vector3i(key.x, key.y, key.z - 1)):
			continue  # drawn from the run above
		var r1 := key.z + 1
		while runs.has(Vector3i(key.x, key.y, r1)):
			r1 += 1
		var a := origin + right * (key.x * px) + Vector3.DOWN * (key.z * px)
		var b := origin + right * (key.y * px) + Vector3.DOWN * (key.z * px)
		_quad(st, a, b, b + Vector3.DOWN * ((r1 - key.z) * px), a + Vector3.DOWN * ((r1 - key.z) * px), n, col, part)


## The yellow roundel with the red M, facing `n`.
func _roundel(st: SurfaceTool, c: Vector3, n: Vector3, r: float) -> void:
	_disc(st, c, n, r + 0.04, RED, 14, Models.LIT_SIGN)
	_disc(st, c + n * 0.015, n, r, YELLOW, 14, Models.LIT_SIGN)
	_text(st, "M", c + n * 0.03 + Vector3.DOWN * r * 0.05, n, r * 0.27, RED)


## A person (props.gd's) standing at `at`, looking along `f`.
func _person(st: SurfaceTool, at: Vector3, f: Vector2, shirt: Color, trousers := Color("#2d3442")) -> void:
	st.append_from(Props.person(shirt, trousers), 0, Transform3D(_facing(f), at))
	count += 1


const SHIRTS := ["#c8282a", "#2a62d1", "#f2c12e", "#f4f2ec", "#3a7d44", "#7a52b8", "#e8762a", "#2b2730", "#e8a6b8",
	"#4fb3c9", "#8a5a3c"]


func _shirt() -> Color:
	return Color(SHIRTS[_rng.randi() % SHIRTS.size()])


# --- The barrels' mouths --------------------------------------------------------------------

## Barrel `q` (landmarks.gd PATELNIA_BARRELS: q0-q1 the long side, q1-q2 the mouth): the blue arch
## round its mouth on two posts, the CENTRUM band across it, the big roundel over the band, the
## yellow door frames folded back against the sides and a red ticket machine outside.
func _barrel_mouth(st: SurfaceTool, q: Array) -> void:
	var q0: Vector2 = q[0]
	var q1: Vector2 = q[1]
	var q2: Vector2 = q[2]
	var q3: Vector2 = q[3]
	var length := q0.distance_to(q1)
	var up := (q1 - q0) / length
	var c := (q0 + q1 + q2 + q3) * 0.25
	var side := Vector2(-up.y, up.x)
	var r := q1.distance_to(q2) * 0.5 - 0.15
	var g := _floor(c)
	var y0 := g + 1.0
	var m := c + up * (length * 0.5 + 0.2)
	var out := Vector3(up.x, 0.0, up.y)
	var at := func(x: float, y: float) -> Vector3:
		return Vector3(m.x + side.x * x, y0 + y, m.y + side.y * x)
	# The arch and its posts.
	var big := r + 0.16
	var segs := 12
	for k in segs:
		var a0 := PI * k / segs
		var a1 := PI * (k + 1) / segs
		_seg(st, at.call(cos(a0) * big, sin(a0) * big), at.call(cos(a1) * big, sin(a1) * big), out, 0.34, 0.26, BLUE)
	for sx: float in [-1.0, 1.0]:
		_seg(st, at.call(sx * big, -1.0), at.call(sx * big, 0.02), out, 0.34, 0.3, BLUE)
	# The band: blue, across the mouth at 2.4-3.0 m, "CENTRUM" in white beside a small roundel.
	var bh := 1.7
	var half_w := sqrt(maxf(big * big - (bh + 0.3) * (bh + 0.3), 1.0))
	var bc: Vector3 = at.call(0.0, bh)
	_seg(st, bc - Vector3(side.x, 0, side.y) * half_w, bc + Vector3(side.x, 0, side.y) * half_w, out, 0.14, 0.62, BLUE)
	var face := bc + out * 0.08
	_roundel(st, face - Vector3.UP.cross(out).normalized() * 1.55, out, 0.24)
	_text(st, "CENTRUM", face + Vector3.UP.cross(out).normalized() * 0.25, out, 0.065, WHITE)
	# Under the band each side: a narrow strip "KIERUNEK" signs are too small to read; a white
	# rule instead, and the big roundel up in the crown.
	_seg(st, bc + Vector3.DOWN * 0.36 - Vector3(side.x, 0, side.y) * (half_w - 0.1),
			bc + Vector3.DOWN * 0.36 + Vector3(side.x, 0, side.y) * (half_w - 0.1), out, 0.1, 0.06, WHITE, Models.LIT_SIGN)
	_roundel(st, at.call(0.0, bh + 1.25) + out * 0.05, out, 0.5)
	# The doors: yellow frames folded back against both sides (open by day).
	for sx: float in [-1.0, 1.0]:
		for k in 2:
			var x := sx * (r - 0.35 - 0.12 * k)
			var p0: Vector3 = at.call(x, -0.98) - out * (0.25 + 1.1 * k)
			var p1: Vector3 = p0 - out * 1.0
			var yt := 2.1
			_seg(st, p0, p0 + Vector3.UP * yt, out, 0.07, 0.07, YELLOW)
			_seg(st, p1, p1 + Vector3.UP * yt, out, 0.07, 0.07, YELLOW)
			_seg(st, p0 + Vector3.UP * yt, p1 + Vector3.UP * yt, Vector3(side.x, 0, side.y), 0.07, 0.07, YELLOW)
			_seg(st, p0 + Vector3.UP * 0.05, p1 + Vector3.UP * 0.05, Vector3(side.x, 0, side.y), 0.07, 0.07, YELLOW)
	# The red ticket machine outside, by the arch's right foot (as a reader at the mouth sees it).
	var tm := m + up * 0.7 - side * (big + 0.7)
	_ticket_machine(st, _v(tm, _floor(tm)), up)


## A red ticket machine (the photos' red ones) looking along `f`: "BILETY" over a lit screen.
func _ticket_machine(st: SurfaceTool, at: Vector3, f: Vector2) -> void:
	var n := Vector3(f.x, 0.0, f.y)
	_box(st, at + Vector3.UP * 0.85, f, Vector3(0.62, 1.7, 0.45), RED)
	_box(st, at + Vector3.UP * 1.2 + n * 0.23, f, Vector3(0.42, 0.34, 0.03), Color("#9fe0c8"), Models.LIT_WINDOW)
	_box(st, at + Vector3.UP * 0.8 + n * 0.23, f, Vector3(0.36, 0.14, 0.03), INK)
	_box(st, at + Vector3.UP * 1.78, f, Vector3(0.66, 0.16, 0.5), WHITE)
	_text(st, "BILETY", at + Vector3.UP * 1.56 + n * 0.25, n, 0.022, WHITE)


# --- The Pasaż Handlowy ------------------------------------------------------------------------

## The box between the barrels: a lit glass front with blue mullions under a blue fascia ("APTEKA
## 24H" at its right end), the white sign box "PASAŻ HANDLOWY" with the tenants' tiles over its
## left half, a poster over its right, the green cross on a bracket, the machines along the front.
func _pasaz_front(st: SurfaceTool) -> void:
	var a: Vector2 = BOX_FRONT[0]
	var b: Vector2 = BOX_FRONT[1]
	var w := a.distance_to(b)
	var d := (b - a) / w
	var n := Vector3(FRONT_OUT.x, 0.0, FRONT_OUT.y)
	var g := _floor((a + b) * 0.5)
	var at := func(u: float, y: float, o := 0.0) -> Vector3:
		var p := a + d * u + FRONT_OUT * o
		return Vector3(p.x, g + y, p.y)
	# The glass front 0-2.6 m, lit inside, blue mullions every ~1.2 m, a dark door left of centre.
	_quad(st, at.call(0.0, 0.0, 0.04), at.call(w, 0.0, 0.04), at.call(w, 2.6, 0.04), at.call(0.0, 2.6, 0.04), n, GLASS_LIT, Models.LIT_WINDOW)
	_quad(st, at.call(2.3, 0.0, 0.06), at.call(4.1, 0.0, 0.06), at.call(4.1, 2.3, 0.06), at.call(2.3, 2.3, 0.06), n, DARK)
	var nm := ceili(w / 1.2)
	for k in nm + 1:
		var u := w * k / nm
		_seg(st, at.call(u, 0.0, 0.1), at.call(u, 2.6, 0.1), n, 0.12, 0.1, BLUE)
	_seg(st, at.call(0.0, 0.05, 0.1), at.call(w, 0.05, 0.1), Vector3.UP, 0.1, 0.12, BLUE_DARK)
	# The fascia 2.6-3.0 m: blue, the pharmacy's name at the right end.
	_seg(st, at.call(-0.1, 2.8, 0.12), at.call(w + 0.1, 2.8, 0.12), Vector3.UP, 0.42, 0.2, BLUE)
	_text(st, "APTEKA 24H", at.call(w - 1.6, 2.8, 0.23), n, 0.045, WHITE)
	_text(st, "WEJŚCIE", at.call(3.2, 2.8, 0.23), n, 0.04, YELLOW)
	# The sign box over the left half: white, a blue rim, "PASAŻ HANDLOWY" in red, tiles under it.
	var sw := w * 0.56
	var sc: Vector3 = at.call(sw * 0.5, 3.85, 0.1)
	_box(st, sc, FRONT_OUT, Vector3(sw + 0.12, 1.75, 0.5), BLUE)
	_box(st, sc + n * 0.2, FRONT_OUT, Vector3(sw - 0.1, 1.55, 0.14), WHITE, Models.LIT_SIGN)
	var title := "PASAŻ HANDLOWY"
	var px := minf(0.075, (sw - 0.4) / PixelFont.width(title))
	_text(st, title, sc + n * 0.29 + Vector3.UP * 0.42, n, px, RED)
	var tiles := [["KIOSK", Color("#2a62d1")], ["FOTO", Color("#e8762a")], ["KLUCZE", Color("#3a7d44")],
			["OPTYK", Color("#7a52b8")], ["KANTOR", Color("#c8282a")], ["TELEFONY", Color("#1d1d24")]]
	var tw := (sw - 0.4) / 3.0
	for k in tiles.size():
		var tc: Vector3 = sc + n * 0.29 + Vector3.UP * (-0.1 - 0.42 * (k / 3)) + Vector3.UP.cross(n).normalized() * (-(sw - 0.4) * 0.5 + tw * (k % 3 + 0.5))
		_box(st, tc, FRONT_OUT, Vector3(tw - 0.08, 0.34, 0.02), tiles[k][1], Models.LIT_SIGN)
		_text(st, tiles[k][0], tc + n * 0.02, n, minf(0.035, (tw - 0.2) / PixelFont.width(tiles[k][0])), WHITE)
	# The poster over the right half (a parody ad): the milk bar under the square.
	var pw := w - sw - 0.25
	var pc: Vector3 = at.call(sw + 0.25 + pw * 0.5, 3.85, 0.1)
	_box(st, pc, FRONT_OUT, Vector3(pw + 0.12, 1.75, 0.4), INK)
	_box(st, pc + n * 0.16, FRONT_OUT, Vector3(pw - 0.1, 1.55, 0.14), Color("#f2c12e"), Models.LIT_SIGN)
	_disc(st, pc + n * 0.24 + Vector3.UP.cross(n).normalized() * (pw * 0.5 - 0.6) + Vector3.DOWN * 0.2, n, 0.42, WHITE, 12, Models.LIT_SIGN)
	_disc(st, pc + n * 0.25 + Vector3.UP.cross(n).normalized() * (pw * 0.5 - 0.6) + Vector3.DOWN * 0.2, n, 0.3, Color("#c98b3a"), 12, Models.LIT_SIGN)
	_text(st, "BAR MLECZNY", pc + n * 0.24 + Vector3.UP * 0.45 - Vector3.UP.cross(n).normalized() * 0.35, n, 0.045, INK)
	_text(st, "POD PATELNIĄ", pc + n * 0.24 + Vector3.UP * 0.05 - Vector3.UP.cross(n).normalized() * 0.35, n, 0.04, RED)
	_text(st, "ŻUREK 9 ZŁ", pc + n * 0.24 + Vector3.DOWN * 0.45 - Vector3.UP.cross(n).normalized() * 0.35, n, 0.04, INK)
	# The pharmacy's green cross on a bracket off the right corner, lit.
	var cc: Vector3 = at.call(w - 0.2, 3.3, 0.9)
	_seg(st, at.call(w - 0.2, 3.3, 0.1), cc, Vector3.UP, 0.08, 0.08, STEEL)
	var dn := Vector3(d.x, 0.0, d.y)
	for nn: Vector3 in [dn, -dn]:
		_box(st, cc, Vector2(nn.x, nn.z), Vector3(0.75, 0.25, 0.1), GREEN, Models.LIT_SIGN)
		_box(st, cc, Vector2(nn.x, nn.z), Vector3(0.25, 0.75, 0.1), GREEN, Models.LIT_SIGN)
	# Along the front: two ticket machines and a cash machine.
	for k in 2:
		_ticket_machine(st, at.call(0.6 + 0.8 * k, 0.0, 0.6), FRONT_OUT)
	var atm: Vector3 = at.call(w - 0.8, 0.0, 0.55)
	_box(st, atm + Vector3.UP * 0.9, FRONT_OUT, Vector3(0.8, 1.8, 0.5), Color("#c9ccd1"))
	_box(st, atm + Vector3.UP * 1.25 + n * 0.25, FRONT_OUT, Vector3(0.4, 0.3, 0.03), Color("#9fc6e8"), Models.LIT_WINDOW)
	_box(st, atm + Vector3.UP * 1.72 + n * 0.25, FRONT_OUT, Vector3(0.7, 0.14, 0.03), Color("#2a62d1"), Models.LIT_SIGN)
	_text(st, "BANKOMAT", atm + Vector3.UP * 1.72 + n * 0.27, n, 0.016, WHITE)


## A court beside the box: lit shopfronts across its back, a blue gateway over its mouth with a
## white "PASAŻ" board; a kiosk in the first, a flower stall in the second.
func _court(st: SurfaceTool, c: Array) -> void:
	var m0: Vector2 = c[0]
	var m1: Vector2 = c[1]
	var k0: Vector2 = c[2]
	var k1: Vector2 = c[3]
	var n := Vector3(FRONT_OUT.x, 0.0, FRONT_OUT.y)
	var g := _floor((m0 + m1) * 0.5)
	# The back: three shops, glass to 2.6 m under a blue fascia with a pale name board each.
	var bw := k0.distance_to(k1)
	var bd := (k1 - k0) / bw
	var names := ["KANTOR", "TELEFONY", "SKLEP", "OPTYK", "OBUWIE", "LOMBARD"]
	var first := 0 if m0.x > -910.0 else 3
	for s in 3:
		var u0 := bw * s / 3.0 + 0.1
		var u1 := bw * (s + 1) / 3.0 - 0.1
		var p0 := k0 + bd * u0 + FRONT_OUT * 0.05
		var p1 := k0 + bd * u1 + FRONT_OUT * 0.05
		_quad(st, _v(p0, g), _v(p1, g), _v(p1, g + 2.6), _v(p0, g + 2.6), n, GLASS_LIT.darkened(0.06 * s), Models.LIT_WINDOW)
		_seg(st, _v(p0 + FRONT_OUT * 0.05, g + 2.85), _v(p1 + FRONT_OUT * 0.05, g + 2.85), Vector3.UP, 0.5, 0.12, BLUE)
		var mid := (p0 + p1) * 0.5 + FRONT_OUT * 0.13
		_box(st, _v(mid, g + 2.85), FRONT_OUT, Vector3(u1 - u0 - 0.5, 0.36, 0.03), WHITE, Models.LIT_SIGN)
		_text(st, names[first + s], _v(mid + FRONT_OUT * 0.03, g + 2.85), n, 0.035, BLUE_DARK)
		_seg(st, _v(p0 + FRONT_OUT * 0.05, g), _v(p0 + FRONT_OUT * 0.05, g + 2.6), n, 0.1, 0.08, BLUE)
	# The gateway: two blue posts and a beam at 3.6 m, a white board on it.
	var w := m0.distance_to(m1)
	var d := (m1 - m0) / w
	for p: Vector2 in [m0 + d * 0.35, m1 - d * 0.35]:
		_seg(st, _v(p, g), _v(p, g + 3.8), n, 0.24, 0.24, BLUE)
	_seg(st, _v(m0 + d * 0.2, g + 3.7), _v(m1 - d * 0.2, g + 3.7), Vector3.UP, 0.3, 0.26, BLUE)
	var bc := (m0 + m1) * 0.5 + FRONT_OUT * 0.16
	_box(st, _v(bc, g + 3.7), FRONT_OUT, Vector3(w * 0.6, 0.42, 0.04), WHITE, Models.LIT_SIGN)
	_text(st, "PASAŻ HANDLOWY", _v(bc + FRONT_OUT * 0.03, g + 3.7), n, 0.038, RED)
	# A kiosk or a flower stall inside, against the court's side, facing across.
	var inside := (m0 + m1) * 0.5 - FRONT_OUT * 6.5
	var face := d if m0.x > -910.0 else -d
	var xf := Transform3D(_facing(face), _v(inside - face * 2.2, _floor(inside)))
	if m0.x > -910.0:
		Props.add_kiosk(st, xf)
	else:
		Props.add_flower_stall(st, xf)
	count += 1


## A billboard on the pavilions' roof at post `p`, facing the square: a dark frame on two legs, the
## poster (a parody ad), lit at night.
func _billboard(st: SurfaceTool, p: Vector2, which: int) -> void:
	var n := Vector3(FRONT_OUT.x, 0.0, FRONT_OUT.y)
	var right := Vector3.UP.cross(n).normalized()
	var base := _floor(p) + 7.5
	var c := _v(p, base + BOARD.y * 0.5 + 0.2)
	for sx: float in [-1.0, 1.0]:
		_seg(st, c + right * sx * BOARD.x * 0.3 + Vector3.DOWN * (BOARD.y * 0.5 + 3.7), c + right * sx * BOARD.x * 0.3, n, 0.22, 0.22, Color("#3a3d42"))
	_box(st, c, FRONT_OUT, Vector3(BOARD.x + 0.3, BOARD.y + 0.3, 0.3), Color("#2a2d33"))
	var f := c + n * 0.16
	if which == 0:
		# The night radio: KEBAB FM 87,3 (the game's own station) on deep purple, sound waves.
		_box(st, f, FRONT_OUT, Vector3(BOARD.x, BOARD.y, 0.04), Color("#3b1f5e"), Models.LIT_SIGN)
		_text(st, "KEBAB FM 87,3", f + n * 0.03 + Vector3.UP * 0.65 - right * 0.6, n, 0.1, YELLOW)
		_text(st, "GRAMY CAŁĄ NOC", f + n * 0.03 + Vector3.DOWN * 0.55 - right * 0.6, n, 0.075, WHITE)
		for k in 3:
			var rr := 0.35 + 0.3 * k
			var wc := f + n * 0.03 + right * (BOARD.x * 0.5 - 1.1)
			for s in 5:
				var a0 := -0.9 + 1.8 * s / 5.0
				var a1 := -0.9 + 1.8 * (s + 1) / 5.0
				_seg(st, wc + (right * cos(a0) + Vector3.UP * sin(a0)) * rr, wc + (right * cos(a1) + Vector3.UP * sin(a1)) * rr, n, 0.1, 0.02,
						Color("#ff5fa2"), Models.LIT_SIGN)
		_disc(st, f + n * 0.04 + right * (BOARD.x * 0.5 - 1.25), n, 0.18, Color("#ff5fa2"), 8, Models.LIT_SIGN)
	else:
		# The optician's sale: "PRZEJRZYJ NA OCZY" on red, a pair of yellow glasses.
		_box(st, f, FRONT_OUT, Vector3(BOARD.x, BOARD.y, 0.04), Color("#c8282a"), Models.LIT_SIGN)
		_text(st, "OPTYK SOKOLE OKO", f + n * 0.03 + Vector3.UP * 0.75 + right * 0.9, n, 0.075, WHITE)
		_text(st, "-50%", f + n * 0.03 + Vector3.DOWN * 0.5 + right * 0.9, n, 0.16, YELLOW)
		_text(st, "NA OPRAWKI", f + n * 0.03 + Vector3.DOWN * 1.2 + right * 0.9, n, 0.05, WHITE)
		var gc := f + n * 0.04 - right * (BOARD.x * 0.5 - 1.6)
		for sx: float in [-1.0, 1.0]:
			_disc(st, gc + right * sx * 0.55, n, 0.48, INK, 12, Models.LIT_SIGN)
			_disc(st, gc + right * sx * 0.55 + n * 0.01, n, 0.36, YELLOW, 12, Models.LIT_SIGN)
		_seg(st, gc - right * 0.12 + n * 0.01, gc + right * 0.12 + n * 0.01, Vector3.UP, 0.08, 0.02, INK)


# --- Murals --------------------------------------------------------------------------------

## The mural from ring point i0 to i1 (wrapping): a picture drawn into an image MURAL_ROWS tall,
## sized to the wall (at most MURAL_PX a pixel) from 0.15 m over the floor, laid on the retaining face 5 cm proud of it, its
## rows cut where the wall's top (the street's height) runs lower; one quad per same-coloured
## rectangle (rows of equal runs merged).
func _mural(st: SurfaceTool, ring: PackedVector2Array, i0: int, i1: int, theme: String) -> void:
	var pts := PackedVector2Array()
	var i := i0
	while true:
		pts.append(ring[i])
		if i == i1:
			break
		i = (i + 1) % ring.size()
	# Inward normals; the reader faces the wall from the square: run the line to their right.
	var mid := (pts[0] + pts[1]) * 0.5
	var d0 := (pts[1] - pts[0]).normalized()
	var nin := Vector2(-d0.y, d0.x)
	if not Geometry2D.is_point_in_polygon(mid + nin * 0.2, ring):
		nin = -nin
	var right := Vector3.UP.cross(Vector3(nin.x, 0.0, nin.y))
	if Vector2(right.x, right.z).dot(d0) < 0.0:
		pts.reverse()
	var cum := PackedFloat32Array([0.0])
	for k in range(1, pts.size()):
		cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
	var total: float = cum[cum.size() - 1]
	var base := float(_sk["patelnia"]["hb"]) + 0.15
	# Each piece's normal and the wall's top there (the street's height a little way out); the
	# picture's pixel is sized so its MURAL_ROWS fit under the lowest top of the wall's dropping
	# pieces (at most MURAL_PX).
	var normals: Array[Vector2] = []
	var tops := PackedFloat32Array()
	var lowest := INF
	for s in pts.size() - 1:
		var a := pts[s]
		var b := pts[s + 1]
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		if not Geometry2D.is_point_in_polygon((a + b) * 0.5 + n * 0.2, ring):
			n = -n
		normals.append(n)
		var top := INF
		for p: Vector2 in [a, b, (a + b) * 0.5]:
			var u: float = map._grid_height(p.x, p.y)
			for o: float in [0.8, 1.8, 3.0]:
				u = maxf(u, map._grid_height(p.x - n.x * o, p.y - n.y * o))
			top = minf(top, u)
		tops.append(top)
		if top - base > 1.2 and a.distance_to(b) > 1.0:
			lowest = minf(lowest, top)
	if lowest == INF:
		return
	var px := clampf((lowest - 0.1 - base) / MURAL_ROWS, 0.04, MURAL_PX)
	var cols := maxi(8, int(total / px))
	var img := Image.create(cols, MURAL_ROWS, false, Image.FORMAT_RGBA8)
	match theme:
		"skyline":
			_paint_skyline(img)
		"pop":
			_paint_pop(img)
		"readers":
			_paint_readers(img)
		_:
			_paint_ribbon(img)
	for s in pts.size() - 1:
		var a := pts[s]
		var b := pts[s + 1]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var d := (b - a) / length
		var n: Vector2 = normals[s]
		var rows_vis := clampi(int((tops[s] - 0.1 - base) / px), 0, MURAL_ROWS)
		if rows_vis < 4:
			continue
		var j0 := int(ceil(cum[s] / px - 0.5))
		var j1 := mini(cols, int(ceil(cum[s + 1] / px - 0.5)))
		var place := func(u: float, row: int) -> Vector3:
			var w := a + d * clampf(u - cum[s], 0.0, length) + n * 0.05
			return Vector3(w.x, base + (MURAL_ROWS - row) * px, w.y)
		_greedy(st, img, j0, j1, MURAL_ROWS - rows_vis, px, place, Vector3(n.x, 0.0, n.y))


## Merges an image's columns [j0, j1) and rows [r0, end) into same-coloured rectangles, each one
## quad placed by `place(u metres, row)`.
func _greedy(st: SurfaceTool, img: Image, j0: int, j1: int, r0: int, px: float, place: Callable, nrm: Vector3) -> void:
	var open := {}   # Vector3i(x0, x1, rgba) -> first row
	for r in range(r0, img.get_height() + 1):
		var runs := {}
		if r < img.get_height():
			var x := j0
			while x < j1:
				var col := img.get_pixel(x, r)
				var e := x + 1
				while e < j1 and img.get_pixel(e, r) == col:
					e += 1
				if col.a > 0.5:
					runs[Vector3i(x, e, col.to_rgba32())] = true
				x = e
		for key: Vector3i in open.keys():
			if not runs.has(key):
				var top: int = open[key]
				var u0 := key.x * px
				var u1 := key.y * px
				_quad(st, place.call(u0, r), place.call(u1, r), place.call(u1, top), place.call(u0, top), nrm,
						Color.hex(key.z))
				_mq += 1
				open.erase(key)
		for key: Vector3i in runs.keys():
			if not open.has(key):
				open[key] = r


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	img.fill_rect(Rect2i(Vector2i(clampi(x0, 0, w), clampi(y0, 0, h)), Vector2i(clampi(x1, 0, w) - clampi(x0, 0, w),
			clampi(y1, 0, h) - clampi(y0, 0, h))), col)


func _circle(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
					img.set_pixel(x, y, col)


## A band of thickness `t` rows whose top follows y(x).
func _band(img: Image, y_of: Callable, t: float, col: Color) -> void:
	for x in img.get_width():
		var y: float = y_of.call(float(x))
		_rect(img, x, roundi(y), x + 1, roundi(y + t), col)


## Text into the image, `s` image pixels a font pixel, the cell's top left at (x, y).
func _ink(img: Image, text: String, x: int, y: int, s: int, col: Color) -> void:
	PixelFont.each_pixel(text, 0, func(px: int, row: int) -> void:
		_rect(img, x + px * s, y + row * s, x + (px + 1) * s, y + (row + 1) * s, col))


## A Warsaw skyline in a blue wave on cream, a red sun behind the Palace, birds, "DO ZOBACZENIA".
func _paint_skyline(img: Image) -> void:
	var w := img.get_width()
	var navy := Color("#1d2b53")
	img.fill(Color("#f4f1e8"))
	var px := int(w * 0.3)
	_circle(img, px + 9, 13, 8.5, Color("#e2483d"))
	# The Palace: stepped, its spire.
	_rect(img, px - 13, 21, px + 13, 32, navy)
	_rect(img, px - 9, 14, px + 9, 21, navy)
	_rect(img, px - 6, 9, px + 6, 14, navy)
	_rect(img, px - 3, 5, px + 3, 9, navy)
	_rect(img, px - 1, 1, px + 1, 5, navy)
	# Towers either side, a sail, a row of tenements, a mast.
	_rect(img, int(w * 0.1), 10, int(w * 0.1) + 8, 32, navy)
	_rect(img, int(w * 0.1) + 3, 6, int(w * 0.1) + 5, 10, navy)
	for y in range(8, 32):
		var x0 := int(w * 0.52) - (y - 8) / 4
		_rect(img, x0, y, int(w * 0.52) + 6, y + 1, navy)
	_rect(img, int(w * 0.64), 12, int(w * 0.64) + 10, 32, navy)
	_rect(img, int(w * 0.64) + 4, 7, int(w * 0.64) + 5, 12, navy)
	for k in 6:
		var x := int(w * 0.74) + k * 7
		_rect(img, x, 20 + (k % 2) * 2, x + 6, 32, navy)
	_rect(img, int(w * 0.92), 9, int(w * 0.92) + 7, 32, navy)
	for k in 9:
		var bx := 8 + (k * 37) % maxi(w - 16, 1)
		var by := 2 + (k * 5) % 8
		_rect(img, bx, by, bx + 2, by + 1, navy)
		_rect(img, bx + 2, by + 1, bx + 3, by + 2, navy)
		_rect(img, bx + 3, by, bx + 5, by + 1, navy)
	# The wave and the words in it.
	_band(img, func(x: float) -> float: return 17.0 + 2.2 * sin(x / 9.0), 20.0, Color("#2f6fbf"))
	_band(img, func(x: float) -> float: return 30.0, 2.0, Color("#e2483d"))
	var text := "DO ZOBACZENIA"
	_ink(img, text, int(w * 0.38), 13, 2, Color("#f4f1e8"))


## Yellow pop: blue and orange swooshes, cartoon faces with big open mouths, "PATELNIA".
func _paint_pop(img: Image) -> void:
	var w := img.get_width()
	img.fill(Color("#f5c518"))
	_band(img, func(x: float) -> float: return 6.0 + 5.0 * sin(x / 14.0), 3.0, Color("#2a62d1"))
	_band(img, func(x: float) -> float: return 24.0 + 4.0 * sin(x / 11.0 + 1.0), 3.0, Color("#e8562a"))
	var faces := [Color("#f08a24"), Color("#ffffff"), Color("#f08fb8"), Color("#5bbf4a")]
	var k := 0
	var x := 22
	while x < w - 14:
		if absf(x - w * 0.5) < 34.0:
			x += 30
			continue
		var cy := 15.0 + (3.0 if k % 2 == 0 else -1.0)
		_circle(img, x, cy, 11.0, INK)
		_circle(img, x, cy, 10.0, faces[k % faces.size()])
		for ex: float in [-4.0, 4.0]:
			_circle(img, x + ex, cy - 4.0, 3.2, INK)
			_circle(img, x + ex, cy - 4.0, 2.4, Color.WHITE)
			_circle(img, x + ex + (1.0 if k % 2 == 0 else -1.0), cy - 3.5, 1.1, INK)
		_circle(img, x, cy + 4.0, 5.0, INK)
		_circle(img, x, cy + 4.0, 4.2, Color("#c42b3a"))
		_rect(img, x - 4, int(cy) - 1, x + 5, int(cy) + 3, faces[k % faces.size()])
		_rect(img, x - 3, int(cy) + 2, x + 4, int(cy) + 3, Color.WHITE)
		k += 1
		x += 46 + (k % 3) * 6
	var text := "PATELNIA"
	var tw := PixelFont.width(text) * 2
	_ink(img, text, w / 2 - tw / 2 + 1, 9, 2, INK)
	_ink(img, text, w / 2 - tw / 2, 8, 2, Color.WHITE)


## Readers on navy: three busts (yellow, pink, cyan) with glasses and a book, speech bubbles, stars.
func _paint_readers(img: Image) -> void:
	var w := img.get_width()
	img.fill(Color("#1f2340"))
	for k in 40:
		var sx := (k * 53 + 11) % w
		var sy := (k * 7 + 3) % 30
		_rect(img, sx, sy, sx + 1, sy + 1, [Color("#f2c12e"), Color("#f08fb8"), Color("#2fb3c9")][k % 3])
	var tones := [Color("#f2c12e"), Color("#f08fb8"), Color("#2fb3c9")]
	var lines := ["POEZJA!", "CZYTAJ", "DOBROĆ"]
	for k in 3:
		var cx := int(w * (0.17 + 0.33 * k))
		var tone: Color = tones[k]
		var dark := tone.darkened(0.45)
		# Shoulders, neck, head, hair, glasses.
		for y in range(22, 32):
			var half := 8 + (y - 22)
			_rect(img, cx - half, y, cx + half, y + 1, tone.darkened(0.15))
		_rect(img, cx - 2, 19, cx + 3, 23, tone)
		_circle(img, cx + 0.5, 14.0, 6.5, tone)
		_circle(img, cx + 0.5, 10.5, 6.0, Color("#f4f2ec") if k != 1 else dark)
		_rect(img, cx - 6, 13, cx + 7, 22, Color(0, 0, 0, 0))
		_circle(img, cx + 0.5, 15.0, 6.0, tone)
		for ex: int in [-3, 3]:
			_rect(img, cx + ex - 2, 13, cx + ex + 3, 16, dark)
			_rect(img, cx + ex - 1, 14, cx + ex + 2, 15, tone.lightened(0.4))
		_rect(img, cx - 1, 18, cx + 2, 19, dark)
		# A book held up in front (white pages, a dark spine).
		_rect(img, cx - 6, 25, cx + 7, 31, Color("#f4f2ec"))
		_rect(img, cx, 25, cx + 1, 31, dark)
		# The bubble, up and right.
		var text: String = lines[k]
		var bw := PixelFont.width(text) + 4
		var bx := cx + 9
		_rect(img, bx, 1, bx + bw, 11, Color("#f4f2ec"))
		_rect(img, bx - 1, 2, bx, 10, Color("#f4f2ec"))
		_rect(img, bx + bw, 2, bx + bw + 1, 10, Color("#f4f2ec"))
		_rect(img, bx, 11, bx + 3, 13, Color("#f4f2ec"))
		_ink(img, text, bx + 2, 1, 1, INK)
	# Clear the stray transparent rows left by the hair cut (fill with the ground).
	for y in img.get_height():
		for x in w:
			if img.get_pixel(x, y).a < 0.5:
				img.set_pixel(x, y, Color("#1f2340"))


## An orange ribbon on white with loops at its crests.
func _paint_ribbon(img: Image) -> void:
	var w := img.get_width()
	img.fill(Color("#f2efe8"))
	var orange := Color("#e8662a")
	_band(img, func(x: float) -> float: return 13.0 + 7.0 * sin(x / 18.0), 5.0, orange)
	var x := 18.0 * PI * 0.5 * 3.0
	while x < w - 8:
		var cy := 13.0 + 7.0 * sin(x / 18.0)
		_circle(img, x, cy - 3.0, 6.5, orange)
		_circle(img, x, cy - 3.0, 4.0, Color("#f2efe8"))
		x += 18.0 * TAU * 1.5
	_band(img, func(x2: float) -> float: return 30.0, 2.0, Color("#1d2b53"))


# --- The slope, the lamps, the stairs ---------------------------------------------------------

## The green slope over the south wall (ring points 24-34, 0): shrubs leaning over the coping (some
## in pink blossom) and globe lamps along the walk behind them; more globes beside the Kokota stair.
func _slope(st: SurfaceTool, ring: PackedVector2Array) -> void:
	var run := 0.0
	var next_lamp := 3.0
	for i in range(24, 35):
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var d := (b - a) / length
		var out := Vector2(-d.y, d.x)
		if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.2, ring):
			out = -out
		var s := 0.4
		while s < length:
			var p := a + d * s + out * (1.0 + _rng.randf() * 1.6)
			_shrub(st, p, 0.7 + _rng.randf() * 0.6, _rng.randf() < 0.3)
			s += 1.3 + _rng.randf() * 0.9
		while next_lamp < run + length:
			var p := a + d * (next_lamp - run) + out * LAMP_OUT
			_globe_lamp(st, _v(p, map.ground_height(p.x, p.y)))
			next_lamp += LAMP_STEP
		run += length
	if _sk.has("patelnia_kokota"):
		var sk: Dictionary = _sk["patelnia_kokota"]
		var top: Vector2 = sk["a"]
		var foot: Vector2 = sk["b"]
		var along := (top - foot).normalized()
		var across := Vector2(-along.y, along.x)
		for t: float in [1.0, 6.0, 11.0]:
			for sx: float in [-1.0, 1.0]:
				var p := foot + along * t + across * sx * 3.4
				_globe_lamp(st, _v(p, map.ground_height(p.x, p.y)))


## A shrub: three green blocks round a middle, `big` metres, pink blossom on top for some.
func _shrub(st: SurfaceTool, p: Vector2, big: float, blossom: bool) -> void:
	var g: float = map.ground_height(p.x, p.y)
	var greens := [Color("#3f6b2f"), Color("#4f7d36"), Color("#365e29")]
	var f := Vector2.from_angle(_rng.randf() * TAU)
	_box(st, _v(p, g + big * 0.45), f, Vector3(big * 1.3, big * 0.9, big * 1.1), greens[_rng.randi() % 3])
	_box(st, _v(p + f * big * 0.4, g + big * 0.7), f.orthogonal(), Vector3(big * 0.8, big * 0.6, big * 0.9), greens[_rng.randi() % 3])
	if blossom:
		_box(st, _v(p - f * big * 0.2, g + big * 0.95), f, Vector3(big * 0.9, big * 0.3, big * 0.8), Color("#e8a6c8"))


## A globe lamp: a dark pole 3.6 m with a white ball (lit at night).
func _globe_lamp(st: SurfaceTool, at: Vector3) -> void:
	_box(st, at + Vector3.UP * 0.2, Vector2(0, -1), Vector3(0.24, 0.4, 0.24), Color("#2b2f35"))
	_box(st, at + Vector3.UP * 1.8, Vector2(0, -1), Vector3(0.1, 3.6, 0.1), Color("#2b2f35"))
	var c := at + Vector3.UP * 3.85
	_box(st, c, Vector2(0, -1), Vector3(0.42, 0.42, 0.42), WHITE, Models.LIT_SIGN)
	_box(st, c, Vector2(0.7071, -0.7071), Vector3(0.36, 0.48, 0.36), WHITE, Models.LIT_SIGN)
	_box(st, c, Vector2(0, -1), Vector3(0.48, 0.32, 0.48), WHITE, Models.LIT_SIGN)


## Handrails down the Kokota stair and the north-east stair: a steel rail down the middle on posts.
func _stairs(st: SurfaceTool) -> void:
	for key: String in ["patelnia_kokota", "patelnia_ne"]:
		if not _sk.has(key):
			continue
		var sk: Dictionary = _sk[key]
		var top: Vector2 = sk["a"]
		var foot: Vector2 = sk["b"]
		var length := top.distance_to(foot)
		var along := (foot - top) / length
		var n := maxi(2, ceili(length / 2.5))
		var prev := Vector3.INF
		for k in n + 1:
			var p := top + along * (0.4 + (length - 0.8) * k / n)
			var y: float = MapBuilderStatic.sunk_level(sk, p)
			var head := _v(p, y + 0.95)
			_seg(st, _v(p, y), head, Vector3(along.x, 0, along.y), 0.06, 0.06, Color("#5b7fa6"))
			if prev != Vector3.INF:
				_seg(st, prev, head, Vector3.UP, 0.07, 0.07, Color("#5b7fa6"))
			prev = head


# --- The square's life ------------------------------------------------------------------------

## The performers and the stalls (positions from the aerials: the open middle, clear of the barrels'
## mouths and the stairs' feet).
func _square_life(st: SurfaceTool, ring: PackedVector2Array) -> void:
	# The busker by the pop mural, his listeners in a half ring.
	var bk := Vector2(-899.0, 419.5)
	var bg := _floor(bk)
	_person(st, _v(bk, bg), Vector2(0, -1), Color("#2b2730"), Color("#3b4f7a"))
	var gb := Basis(Vector3.UP, 0.5)
	Props.obox(st, _v(bk, bg) + Vector3(0.05, 1.0, -0.2), gb, Vector3(0.42, 0.5, 0.12), Color("#a8642e"))
	Props.obox(st, _v(bk, bg) + Vector3(-0.42, 1.28, -0.2), gb * Basis(Vector3.BACK, 0.9), Vector3(0.07, 0.7, 0.05), Color("#3a2a20"))
	_box(st, _v(bk + Vector2(0.9, 0.1), bg + 0.3), Vector2(0, -1), Vector3(0.45, 0.6, 0.35), INK)
	_box(st, _v(bk + Vector2(0.9, -0.08), bg + 0.33), Vector2(0, -1), Vector3(0.32, 0.32, 0.2), Color("#4a4f57"))
	_box(st, _v(bk + Vector2(-0.3, -1.0), bg + 0.06), Vector2(1, 0), Vector3(1.0, 0.12, 0.38), Color("#2b2730"))
	_box(st, _v(bk + Vector2(-0.3, -1.0), bg + 0.1), Vector2(1, 0), Vector3(0.9, 0.04, 0.3), Color("#b8323a"))
	for k in 6:
		var ang := PI * (1.2 + 0.6 * k / 5.0)
		var p := bk + Vector2(cos(ang), sin(ang)) * (2.8 + 0.3 * (k % 2))
		_person(st, _v(p, _floor(p)), (bk - p).normalized(), _shirt())
	# The breakdancer in a handstand on cardboard, a boombox, a ring of watchers (open to the south).
	var bd := Vector2(-910.5, 414.0)
	var dg := _floor(bd)
	_box(st, _v(bd, dg + 0.02), Vector2(0, -1), Vector3(2.4, 0.03, 2.4), Color("#b88a55"))
	_box(st, _v(bd + Vector2(1.6, 1.0), dg + 0.2), Vector2(-0.6, -0.8), Vector3(0.6, 0.36, 0.22), Color("#2b2f35"))
	for sx: float in [-1.0, 1.0]:
		_disc(st, _v(bd + Vector2(1.6, 1.0), dg + 0.2) + Vector3(-0.6, 0, -0.8) * 0.12 + Vector3(0.8, 0, -0.6) * sx * 0.16, Vector3(-0.6, 0, -0.8),
				0.09, STEEL, 8)
	var hb := Basis(Vector3.UP, 0.7)
	var hc := _v(bd, dg)
	for sx: float in [-1.0, 1.0]:
		Props.obox(st, hc + hb * Vector3(0.2 * sx, 0.3, 0), hb, Vector3(0.12, 0.6, 0.14), Color("#e8762a"))
	Props.obox(st, hc + hb * Vector3(0, 0.95, 0), hb, Vector3(0.44, 0.62, 0.28), Color("#e8762a"))
	Props.obox(st, hc + hb * Vector3(0, 0.5, -0.04), hb, Vector3(0.25, 0.25, 0.25), SKIN)
	Props.obox(st, hc + hb * Vector3(0, 0.4, -0.04), hb, Vector3(0.28, 0.08, 0.3), Color("#c8282a"))
	for sx: float in [-1.0, 1.0]:
		var lb := hb * Basis(Vector3.BACK, 0.45 * sx)
		Props.obox(st, hc + hb * Vector3(0.22 * sx, 1.65, 0), lb, Vector3(0.16, 0.85, 0.2), Color("#2d3442"))
		Props.obox(st, hc + hb * Vector3(0.42 * sx, 2.06, 0), lb, Vector3(0.18, 0.12, 0.28), WHITE)
	count += 1
	for k in 10:
		var ang := PI * (0.85 + 1.3 * k / 9.0) + PI
		var p := bd + Vector2(cos(ang), sin(ang)) * (3.0 + 0.35 * (k % 2))
		_person(st, _v(p, _floor(p)), (bd - p).normalized(), _shirt())
	# The painter on a ladder at the skyline mural, spray cans at the foot.
	var wa: Vector2 = ring[27]
	var wb: Vector2 = ring[28]
	var wd := (wb - wa).normalized()
	var win := Vector2(-wd.y, wd.x)
	if not Geometry2D.is_point_in_polygon((wa + wb) * 0.5 + win * 0.2, ring):
		win = -win
	var lp := (wa + wb) * 0.5 + win * 0.75
	var lg := _floor(lp)
	for sx: float in [-1.0, 1.0]:
		var foot_a := lp + wd * sx * 0.25 + win * 0.45
		var foot_b := lp + wd * sx * 0.25 - win * 0.45
		_seg(st, _v(foot_a, lg), _v(lp + wd * sx * 0.22, lg + 1.6), Vector3(wd.x, 0, wd.y), 0.05, 0.05, STEEL)
		_seg(st, _v(foot_b, lg), _v(lp + wd * sx * 0.22, lg + 1.6), Vector3(wd.x, 0, wd.y), 0.05, 0.05, STEEL)
	_box(st, _v(lp + win * 0.15, lg + 0.75), wd.orthogonal(), Vector3(0.55, 0.05, 0.25), STEEL)
	_person(st, _v(lp + win * 0.15, lg + 0.78), -win, Color("#f4f2ec"), Color("#4a6fa5"))
	_seg(st, _v(lp + win * 0.1 + wd * 0.3, lg + 0.78 + 1.35), _v(lp - win * 0.25 + wd * 0.35, lg + 0.78 + 1.9),
			Vector3.UP, 0.12, 0.12, Color("#f4f2ec"))
	_box(st, _v(lp - win * 0.3 + wd * 0.36, lg + 0.78 + 1.98), -win, Vector3(0.07, 0.18, 0.07), RED)
	for k in 5:
		var cp := lp + wd * (0.8 + 0.18 * k) + win * (0.2 + 0.12 * (k % 2))
		_box(st, _v(cp, lg + 0.1), Vector2(0, -1), Vector3(0.08, 0.2, 0.08), [RED, Color("#2a62d1"), YELLOW, Color("#5bbf4a"), WHITE][k])
	# The easel painter by the east wall, two watching.
	var ep := Vector2(-893.5, 413.0)
	var eg := _floor(ep)
	var ef := Vector2(-0.8, 0.6)
	var eb := _facing(ef)
	var ec := _v(ep - ef * 1.0, eg)
	for k in 3:
		var leg := eb * Vector3([-0.3, 0.3, 0.0][k], 0, [0.0, 0.0, 0.4][k])
		_seg(st, ec + leg, ec + Vector3.UP * 1.6, Vector3.UP.cross(eb * Vector3.FORWARD), 0.04, 0.04, Color("#8a5a3c"))
	Props.obox(st, ec + Vector3.UP * 1.15 + eb * Vector3(0, 0, 0.04), eb, Vector3(0.8, 0.62, 0.04), WHITE)
	var swatch := [Color("#2f6fbf"), Color("#e2483d"), Color("#f2c12e"), Color("#5bbf4a"), Color("#1d2b53"), Color("#e8a6c8")]
	for k in 6:
		Props.obox(st, ec + Vector3.UP * (1.0 + 0.24 * (k / 3)) + eb * Vector3(-0.24 + 0.24 * (k % 3), 0, 0.07), eb,
				Vector3(0.2, 0.2, 0.02), swatch[k])
	count += 1
	_person(st, _v(ep, eg), -ef, Color("#3a7d44"), Color("#2d3442"))
	for k in 2:
		var p := ep + ef.orthogonal() * (1.2 + 0.7 * k) + ef * 0.6
		_person(st, _v(p, _floor(p)), (ec_flat(ec) - p).normalized(), _shirt())
	# The gold living statue on its box.
	var ls := Vector2(-926.5, 418.6)
	var lsg := _floor(ls)
	var gold := Color("#c9a227")
	var sf := Vector2(0.35, -0.94)
	_box(st, _v(ls, lsg + 0.3), sf, Vector3(0.8, 0.6, 0.8), Color("#e4dfd2"))
	var sb := _facing(sf)
	var s0 := _v(ls, lsg + 0.6)
	for sx: float in [-1.0, 1.0]:
		Props.obox(st, s0 + sb * Vector3(0.11 * sx, 0.43, 0), sb, Vector3(0.17, 0.86, 0.22), gold)
	Props.obox(st, s0 + sb * Vector3(0, 1.15, 0), sb, Vector3(0.46, 0.62, 0.28), gold)
	Props.obox(st, s0 + sb * Vector3(-0.29, 1.12, 0), sb, Vector3(0.12, 0.56, 0.16), gold)
	Props.obox(st, s0 + sb * Vector3(0.36, 1.62, 0), sb * Basis(Vector3.BACK, 0.4), Vector3(0.12, 0.6, 0.16), gold)
	Props.obox(st, s0 + sb * Vector3(0, 1.58, 0), sb, Vector3(0.26, 0.26, 0.26), gold.lightened(0.1))
	Props.obox(st, s0 + sb * Vector3(0, 1.78, 0), sb, Vector3(0.4, 0.04, 0.4), gold.darkened(0.2))
	Props.obox(st, s0 + sb * Vector3(0, 1.9, 0), sb, Vector3(0.24, 0.22, 0.24), gold.darkened(0.2))
	_box(st, _v(ls + sf * 0.8, lsg + 0.08), sf, Vector3(0.3, 0.16, 0.3), Color("#2b2730"))
	count += 1
	# Stalls: a big four-colour market umbrella over a table, a green tent with a trestle table.
	var um := Vector2(-931.0, 413.5)
	var ug := _floor(um)
	_box(st, _v(um, ug + 0.4), Vector2(0, 1), Vector3(1.6, 0.8, 0.8), Color("#f4f2ec"))
	_box(st, _v(um, ug + 0.84), Vector2(0, 1), Vector3(1.5, 0.08, 0.7), Color("#c98b3a"))
	_seg(st, _v(um, ug), _v(um, ug + 2.5), Vector3.RIGHT, 0.05, 0.05, Color("#3a3b3f"))
	var ucol := [Color("#f2c12e"), Color("#c8282a"), Color("#21a148"), Color("#2a62d1")]
	for k in 8:
		var a0 := TAU * k / 8.0
		var a1 := TAU * (k + 1) / 8.0
		var tip := _v(um, ug + 2.7)
		var e0 := _v(um + Vector2(cos(a0), sin(a0)) * 1.7, ug + 2.15)
		var e1 := _v(um + Vector2(cos(a1), sin(a1)) * 1.7, ug + 2.15)
		var nn := (e1 - tip).cross(e0 - tip).normalized()
		if nn.y < 0.0:
			nn = -nn
		Props.tri(st, tip, e0, e1, nn, ucol[k / 2])
		Props.tri(st, tip, e1, e0, -nn, ucol[k / 2].darkened(0.3))
	count += 1
	var tn := Vector2(-932.0, 419.0)
	var tg := _floor(tn)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_seg(st, _v(tn + Vector2(sx * 1.3, sz * 1.3), tg), _v(tn + Vector2(sx * 1.3, sz * 1.3), tg + 2.1), Vector3.RIGHT, 0.05, 0.05,
					Color("#d8dbe0"))
	var apex := _v(tn, tg + 2.9)
	var cs := [Vector2(-1.4, -1.4), Vector2(1.4, -1.4), Vector2(1.4, 1.4), Vector2(-1.4, 1.4)]
	for k in 4:
		var e0 := _v(tn + cs[k], tg + 2.1)
		var e1 := _v(tn + cs[(k + 1) % 4], tg + 2.1)
		var nn := (e1 - apex).cross(e0 - apex).normalized()
		if nn.y < 0.0:
			nn = -nn
		Props.tri(st, apex, e0, e1, nn, Color("#2f8a4f"))
		Props.tri(st, apex, e1, e0, -nn, Color("#1f5e36"))
		_quad(st, e0, e1, e1 + Vector3.DOWN * 0.25, e0 + Vector3.DOWN * 0.25, Vector3(cs[k].x + cs[(k + 1) % 4].x, 0, cs[k].y + cs[(k + 1) % 4].y).normalized(),
				Color("#2f8a4f"))
	_box(st, _v(tn, tg + 0.75), Vector2(0, -1), Vector3(2.0, 0.06, 0.8), Color("#f4f2ec"))
	for k in 6:
		_box(st, _v(tn + Vector2(-0.8 + 0.32 * k, 0.0), tg + 0.84), Vector2(0, -1), Vector3(0.24, 0.12, 0.3), ucol[k % 4].lightened(0.2))
	count += 1
	# The advertising columns: one by the busker, one at the east wall.
	Props.add_ad_column(st, Transform3D(Basis.IDENTITY, _v(Vector2(-917.0, 421.4), _floor(Vector2(-917.0, 421.4)))), Color("#c8282a"))
	Props.add_ad_column(st, Transform3D(Basis.IDENTITY, _v(Vector2(-889.6, 408.0), _floor(Vector2(-889.6, 408.0)))), Color("#f2c12e"))
	count += 2


static func ec_flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
