extends Node3D
## Inside Senatorek (the shisha lounge quest, shisha.gd; docs/design/shisha-lounge.md): after the
## lift, a cutaway room in the city's isometric look, like the club (club.gd), from F's 13 photos
## of the lounge at Emilii Plater 53: "quiet money", a calm, warm, dark-stone room.
##
## The room (ROOM m, off the map at PLACE): the back wall is the window wall with the Palace of
## Culture lit in the panes and the city's lights below it; the left wall is rough rock behind
## vertical steel bars, the gold SENATOREK letters on them. Curved rust-velvet banquettes round
## black tables, grey armchairs on brass legs, olive trees in black planters, the travertine bar
## with the flavour jars and the coal station, black beams with track spots, the lit door to the
## TERRACE. The terrace (TERRACE, in the same mesh, out of the room's view): travertine floor,
## teak armchairs with cream cushions, the tower's glass wall behind, a glass balustrade, the
## Palace's tower beyond it over a field of city lights, bulb garlands.
##
## The evening, in steps: the waiter's order (Ivan a pale beer, Bogdan green tea), then the
## mini-game "Miks u Mistrza" with Mistrz Dymek: two jars of six on a sweet/cool chart (Ivan's and
## Bogdan's pins; the mix is the midpoint, hearts 0-3 each by distance, the car's strength vote
## tips them; strong gets the master's two hoses), the coal (tap in the band, narrower when
## stronger), the first draw (hold, release in the band: a smoke ring). The score 0-9 sets the
## master's verdict and the pay. Then PALIĆ (the smoke scene: the bowl's trickle, exhales, rings,
## haze), TARAS (the same on the terrace) or WYJDŹ. Every guest can be tapped (data/shisha.json
## "taps").
##
## Cost: four draw calls (the room and terrace mesh, the people, the smoke, the warm light cones);
## the city is out of view. Built once, on the first visit.

const Models := preload("res://scripts/models.gd")
const Rave := preload("res://scripts/rave.gd")
const Club := preload("res://scripts/club.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Lang := preload("res://scripts/lang.gd")
const Shisha := preload("res://scripts/shisha.gd")

## Where it stands: far past the map's edge, away from the club (9000, 9000).
const PLACE := Vector3(-9000.0, 0.0, 9000.0)
## The room's floor, x across, y deep (m), the ceiling's height.
const ROOM := Vector2(18.0, 12.0)
const WALL_H := 4.2
## The terrace's middle (room-local) and its size.
const TERRACE := Vector3(70.0, 0.0, 0.0)
const TER := Vector2(16.0, 11.0)
const VIEW := 15.5
const TER_VIEW := 17.0
const YAW := 45.0
## Our table (room-local) and on the terrace.
const OURS := Vector3(-1.2, 0.0, 0.6)
const OURS_TER := TERRACE + Vector3(-1.0, 0.0, 0.8)
const TEAL := Color("#2fb8a0")
const GOLD := Color("#e2bf7a")
const TAP_R := 1.4
## The room's own warm light at night (`warm`).
const INNER_GLOW := 0.5

## The mini-game: the friends' pins on the sweet/cool chart.
const IVAN_PIN := Vector2(3.5, 1.5)
const BOGDAN_PIN := Vector2(1.5, 4.0)
## Hearts by the mix's distance from a pin: under [0] 3, under [1] 2, under [2] 1.
const HEART_D := [1.5, 2.3, 3.2]
## The coal's glow rises 0..1 every COAL_CYCLE s; the band's middle and half-width (strength 1).
const COAL_CYCLE := 2.4
const COAL_MID := 0.72
const COAL_HALF := 0.15
## The first draw: hold, the cloud grows DRAW_RATE per second, let go inside the band.
const DRAW_RATE := 0.5
const DRAW_BAND := Vector2(0.62, 0.86)
## Lines in the panel, one every LINE_S s.
const LINE_S := 3.0
## The smoke scene's length before the car.
const SMOKE_S := 24.0
## A step waits this long for a tap, then takes the miss.
const STEP_LIFE := 14.0
## The auto player waits this long on each step (the panel in the shots).
const AUTO_WAIT := 5.0
## Smoke puffs in the pool.
const PUFFS := 180
const JAR_COLOURS := {"arbuz": Color("#e8506a"), "jablko": Color("#9fd04a"), "guma": Color("#ff8ac8"),
		"ogorek": Color("#7ad6a0"), "mgla": Color("#b8c8e0"), "zupa": Color("#d8442a")}

## The jars' names on the buttons (the full names in the hint once picked).
const JAR_SHORT := {"arbuz": ["ARBUZ", "MELON"], "jablko": ["JABŁKO", "APPLE"], "guma": ["GUMA", "GUM"],
		"ogorek": ["OGÓREK", "CUCUMBER"], "mgla": ["MGŁA", "MIST"], "zupa": ["ZUPA", "SOUP"]}

enum Step { NONE, ORDER, JARS, COAL, DRAW, RESULT, SMOKE }

## How it ended ("smoke", "terrace", "leave") and the score 0..9.
signal done(how: String, score: int)

var hud: CanvasLayer
var cam: Camera3D
var log_on := false
## Plays itself (the check, --shisha-lounge shots): the best jars, clean timing, PALIĆ.
var auto_play := false
## What the auto player picks at the end: "smoke" or "terrace".
var auto_how := "smoke"

var inside := false
var centre := PLACE + OURS + Vector3(0, 1.2, 0)
var view_size := VIEW
var yaw := YAW
var area := "sala"
var step_now := Step.NONE
## The votes from the car {flavour, strength, name}.
var votes := {}
var strength := 3
var picked: Array[String] = []
var hearts_now := Vector2i.ZERO
var coal_pts := 0
var ringed := false
var score := 0
var how := ""
## The people one can tap: [name, local position].
var people: Array = []

var _data := {}
var _jars: Array = []
var _built := false
var _room: MeshInstance3D
var _people: MultiMeshInstance3D
var _smoke: MultiMeshInstance3D
var _lights: MultiMeshInstance3D
var _seats: Array = []          ## [local position, yaw, colour] per person instance
var _clock := 0.0
var _step_t := 0.0
var _lines: Array = []
var _line_t := 0.0
var _speaker := ""
var _holding := false
var _cloud := 0.0
var _rng := RandomNumberGenerator.new()
var _emit_t := 0.0
var _exhale_t := 0.0
var _ring_t := 0.0
var _turn := 0
# The puffs: position, velocity, age, life, size from-to, alpha.
var _pp := PackedVector3Array()
var _pv := PackedVector3Array()
var _page := PackedFloat32Array()
var _plife := PackedFloat32Array()
var _psize := PackedVector2Array()
var _palpha := PackedFloat32Array()
var _pnext := 0
var _ui: CanvasLayer
var _title: Label
var _talk: PanelContainer
var _who: Label
var _line: Label
var _game: PanelContainer
var _game_title: Label
var _game_hint: Label
var _chart: Control
var _bar: Control
var _jar_box: GridContainer
var _jar_btns: Dictionary = {}
var _act: Button
var _buttons: HBoxContainer
var _smoke_btn: Button
var _terrace_btn: Button
var _out_btn: Button


# --- the rules (static: check_shisha.gd runs them) --------------------------------------------

## The bowl's mix: the midpoint of the jars' (sweet, cool).
static func mix_point(a: Dictionary, b: Dictionary) -> Vector2:
	return (Vector2(float(a["sweet"]), float(a["cool"])) + Vector2(float(b["sweet"]), float(b["cool"]))) * 0.5


static func hearts_at(pin: Vector2, mix: Vector2) -> int:
	var d := pin.distance_to(mix)
	for i in HEART_D.size():
		if d < float(HEART_D[i]):
			return 3 - i
	return 0


## Ivan's and Bogdan's hearts for two jars and the strength: strong (4-5) pleases Bogdan (Ivan
## gets the master's second hose through ice), light (1-2) pleases Ivan and bores Bogdan; the
## tomato soup is a legend (Bogdan 3, Ivan 0).
static func friends_hearts(a: Dictionary, b: Dictionary, s: int) -> Vector2i:
	if String(a["id"]) == "zupa" or String(b["id"]) == "zupa":
		return Vector2i(0, 3)
	var m := mix_point(a, b)
	var iv := hearts_at(IVAN_PIN, m)
	var bo := hearts_at(BOGDAN_PIN, m)
	if s >= 4:
		bo += 1
	elif s <= 2:
		iv += 1
		bo -= 1
	return Vector2i(clampi(iv, 0, 3), clampi(bo, 0, 3))


## The coal's band [from, to] on the glow 0..1: narrower the stronger.
static func coal_band(s: int) -> Vector2:
	var half := COAL_HALF - 0.02 * float(clampi(s, 1, 5) - 1)
	return Vector2(COAL_MID - half, COAL_MID + half)


## The coal's points and its scene for a tap at `glow`.
static func coal_result(glow: float, s: int) -> Array:
	var band := coal_band(s)
	if glow < band.x:
		return [0, "coal_early"]
	if glow > band.y:
		return [0, "coal_late"]
	return [2, "coal_good"]


static func draw_ok(cloud: float) -> bool:
	return cloud >= DRAW_BAND.x and cloud <= DRAW_BAND.y


## The evening's score 0..9: the hearts, the coal (0 or 2), the ring (0 or 1).
static func total(h: Vector2i, coal: int, ring: bool) -> int:
	return clampi(h.x + h.y + coal + (1 if ring else 0), 0, 9)


static func result_scene(s: int) -> String:
	return "result_high" if s >= 7 else ("result_mid" if s >= 4 else "result_low")


## The best pair of jars for a strength (the auto player and the check): [id, id].
static func best_jars(jars: Array, s: int) -> Array:
	var best: Array = []
	var top := -1
	for i in jars.size():
		for j in range(i + 1, jars.size()):
			var h := friends_hearts(jars[i], jars[j], s)
			if h.x + h.y > top:
				top = h.x + h.y
				best = [String(jars[i]["id"]), String(jars[j]["id"])]
	return best


## The jar the car's flavour vote puts in the bowl first.
static func first_jar(flavour: String) -> String:
	return {"ivan": "arbuz", "bogdan": "ogorek"}.get(flavour, "jablko")


# --- the room and the terrace (one mesh) ----------------------------------------------------

static func room_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 5353
	# The void round both, the floor: dark smoked oak in long boards.
	Models.box(st, Vector3(30, -0.6, 0), Vector3(400, 1.0, 400), Color("#020203"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(ROOM.x, 0.2, ROOM.y), Color("#2b2421"), Models.FIXED)
	for i in 24:
		Models.box(st, Vector3(-hx + 0.375 + i * 0.75, 0.005, 0), Vector3(0.02, 0.01, ROOM.y), Color("#221c1a"), Models.FIXED)
	_window_wall(st, hx, hz, rng)
	_rock_wall(st, hx, hz, rng)
	# The ceiling is cut away; its track spots hang over the tables on thin black rods.
	for p: Vector3 in [OURS, Vector3(-5.0, 0, -3.9), Vector3(0.6, 0, -3.9), Vector3(5.4, 0, -3.9)]:
		Models.box(st, p + Vector3(0, WALL_H + 0.2, 0), Vector3(0.03, 1.0, 0.03), Color("#141416"), Models.FIXED)
		Models.box(st, p + Vector3(0, WALL_H - 0.38, 0), Vector3(0.2, 0.26, 0.2), Color("#1d1d20"), Models.FIXED)
		Models.box(st, p + Vector3(0, WALL_H - 0.52, 0), Vector3(0.14, 0.03, 0.14), Color("#ffe2a8"), Models.LIT_SIGN)
	# The bar along the rock wall at the front: travertine, a brass foot rail, the jars and coals.
	var bx := -hx + 1.5
	Models.box(st, Vector3(bx, 0.55, 3.0), Vector3(0.9, 1.1, 4.8), Color("#cfc5b4"), Models.FIXED)
	Models.box(st, Vector3(bx, 1.13, 3.0), Vector3(1.05, 0.06, 5.0), Color("#e2d9c8"), Models.FIXED)
	Models.box(st, Vector3(bx + 0.5, 0.18, 3.0), Vector3(0.04, 0.04, 4.8), Color("#b8954a"), Models.FIXED)
	for i in 5:
		Models.box(st, Vector3(bx + 0.02, 0.6, 1.0 + i * 1.0), Vector3(0.92, 1.0, 0.02), Color("#b9af9f"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.45, 1.6, 3.0), Vector3(0.3, 0.05, 4.4), Color("#3a3226"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.45, 2.2, 3.0), Vector3(0.3, 0.05, 4.4), Color("#3a3226"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.33, 1.9, 3.0), Vector3(0.04, 0.62, 4.4), Color("#ffcf8a"), Models.LIT_SIGN)
	var jar_c: Array = JAR_COLOURS.values()
	for row in 2:
		for i in 12:
			var c: Color = jar_c[(i + row * 3) % jar_c.size()]
			Models.box(st, Vector3(-hx + 0.47, 1.76 + row * 0.6, 1.0 + i * 0.36), Vector3(0.16, 0.22, 0.16), c.darkened(0.25), Models.FIXED)
			Models.box(st, Vector3(-hx + 0.47, 1.9 + row * 0.6, 1.0 + i * 0.36), Vector3(0.17, 0.04, 0.17), Color("#d8d4cc"), Models.FIXED)
	# The coal station on the counter's end: a steel box, coals glowing in it.
	Models.box(st, Vector3(bx, 1.26, 5.0), Vector3(0.6, 0.2, 0.6), Color("#3a3b3f"), Models.FIXED)
	for i in 6:
		Models.box(st, Vector3(bx - 0.18 + (i % 3) * 0.18, 1.38, 4.9 + (i / 3) * 0.2), Vector3(0.12, 0.06, 0.12), Color("#ff6a2a"), Models.LIT_SIGN)
	# Three bar stools.
	for i in 3:
		var p := Vector3(bx + 1.0, 0, 2.0 + i * 1.1)
		Models.box(st, p + Vector3(0, 0.38, 0), Vector3(0.05, 0.76, 0.05), Color("#b8954a"), Models.FIXED)
		Models.box(st, p + Vector3(0, 0.8, 0), Vector3(0.42, 0.08, 0.42), Color("#7a3a26"), Models.FIXED)
	# The booths along the windows, ours in the middle, armchairs at the front right.
	for b: Vector3 in [Vector3(-5.0, 0, -3.9), Vector3(0.6, 0, -3.9), Vector3(5.4, 0, -3.9)]:
		_banquette(st, b, 1.3, 180.0, 0.0)
		_table(st, b, 0.55)
		_hookah(st, b + Vector3(0.1, 0.62, 0.0), rng)
	_banquette(st, OURS, 1.55, 240.0, 45.0)
	_table(st, OURS, 0.65)
	_hookah(st, OURS + Vector3(0, 0.62, 0), rng)
	for g: Vector3 in [Vector3(4.6, 0, 1.4), Vector3(5.6, 0, 4.4), Vector3(1.6, 0, 4.4)]:
		_table(st, g, 0.45)
		_hookah(st, g + Vector3(0, 0.62, 0), rng)
		for k in 3:
			var a := TAU * k / 3.0 + 0.4
			_armchair(st, g + Vector3(cos(a), 0, sin(a)) * 1.05, -a - PI * 0.5)
	# Olive trees in black planters.
	for p: Vector3 in [Vector3(-hx + 0.9, 0, -hz + 0.9), Vector3(-2.2, 0, -hz + 0.8), Vector3(3.0, 0, -hz + 0.8),
			Vector3(hx - 0.9, 0, -0.6), Vector3(-3.6, 0, 3.6), Vector3(-hx + 0.9, 0, 0.0)]:
		_olive(st, p, rng)
	# The terrace door at the window wall's right end, lit warm, its sign.
	Models.box(st, Vector3(hx - 1.3, 1.25, -hz + 0.06), Vector3(1.4, 2.5, 0.06), Color("#ffd89a"), Models.LIT_SIGN)
	Models.box(st, Vector3(hx - 1.3, 2.62, -hz + 0.09), Vector3(1.0, 0.14, 0.03), TEAL, Models.LIT_SIGN)
	_terrace(st, rng)
	return warm(st.commit(), INNER_GLOW)


## The room's warm light at night: every plain part (FIXED) turned into a "hero" part lit from
## within by `k` (actor.gdshader part 8), so the lounge reads warm and dim, not the city's blue.
static func warm(mesh: ArrayMesh, k: float) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var col: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	for i in uv.size():
		if absf(uv[i].x - Models.FIXED) < 0.01 and col[i].get_luminance() > 0.02:
			uv[i] = Vector2(Models.HERO, k)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## The window wall (back, -Z): black steel mullions, dusk-blue panes, the Palace of Culture lit in
## the middle panes, the city's lights below it, a dark sill.
static func _window_wall(st: SurfaceTool, hx: float, hz: float, rng: RandomNumberGenerator) -> void:
	var z := -hz - 0.1
	Models.box(st, Vector3(0, 0.25, z + 0.05), Vector3(ROOM.x, 0.5, 0.3), Color("#1a1a1d"), Models.FIXED)
	Models.box(st, Vector3(0, WALL_H * 0.5 + 0.25, z - 0.05), Vector3(ROOM.x, WALL_H - 0.5, 0.1), Color("#1b2434"), Models.FIXED)
	# The sky's glow low over the city, a band lighter than the top.
	Models.box(st, Vector3(0, 1.15, z + 0.01), Vector3(ROOM.x, 0.9, 0.02), Color("#2c3550"), Models.FIXED)
	# The city's lights through the glass.
	for i in 150:
		var x := rng.randf_range(-hx + 0.2, hx - 2.2)
		var y := rng.randf_range(0.6, 1.5) if rng.randf() < 0.8 else rng.randf_range(1.5, 2.2)
		var warm := rng.randf() < 0.65
		Models.box(st, Vector3(x, y, z + 0.03), Vector3(0.05, 0.05, 0.02), Color("#ffd58a") if warm else Color("#dfe8ff"), Models.LIT_WINDOW)
	# The Palace (left of the middle): stepped tower, side towers, lit window rows, the spire.
	var px := -0.4
	var stone := Color("#4a4c5a")
	var tiers := [[2.6, 0.5, 1.35], [1.6, 1.35, 2.15], [1.1, 2.15, 2.75], [0.7, 2.75, 3.15], [0.42, 3.15, 3.45]]
	for t: Array in tiers:
		Models.box(st, Vector3(px, (t[1] + t[2]) * 0.5, z + 0.04), Vector3(t[0], t[2] - t[1], 0.03), stone, Models.FIXED)
	for side in [-1.0, 1.0]:
		Models.box(st, Vector3(px + side * 2.0, 1.05, z + 0.04), Vector3(0.6, 1.1, 0.03), stone, Models.FIXED)
		Models.box(st, Vector3(px + side * 2.0, 1.75, z + 0.04), Vector3(0.12, 0.3, 0.03), stone, Models.FIXED)
	Models.box(st, Vector3(px, 3.7, z + 0.04), Vector3(0.05, 0.5, 0.03), Color("#c9b98a"), Models.LIT_SIGN)
	Models.box(st, Vector3(px, 2.95, z + 0.06), Vector3(0.16, 0.16, 0.02), Color("#f2e3b0"), Models.LIT_SIGN)
	for t: Array in tiers.slice(0, 3):
		var w: float = t[0]
		var rows := int((t[2] - t[1]) / 0.16)
		for r in rows:
			for c in int(w / 0.18):
				if rng.randf() < 0.55:
					Models.box(st, Vector3(px - w * 0.5 + 0.1 + c * 0.18, t[1] + 0.08 + r * 0.16, z + 0.06), Vector3(0.06, 0.07, 0.02), Color("#ffe0a0"), Models.LIT_WINDOW)
	# A violet-lit top (the Palace's event lights).
	Models.box(st, Vector3(px, 3.3, z + 0.07), Vector3(0.44, 0.06, 0.02), Color("#b06cff"), Models.LIT_SIGN)
	# The mullions, a transom, the head.
	for i in 13:
		Models.box(st, Vector3(-hx + i * 1.5, WALL_H * 0.5, z + 0.08), Vector3(0.08, WALL_H, 0.12), Color("#121214"), Models.FIXED)
	Models.box(st, Vector3(0, 2.9, z + 0.08), Vector3(ROOM.x, 0.06, 0.1), Color("#121214"), Models.FIXED)
	Models.box(st, Vector3(0, WALL_H - 0.1, z + 0.08), Vector3(ROOM.x, 0.2, 0.14), Color("#121214"), Models.FIXED)


## The rock wall (left, -X): rough stone blocks, vertical steel bars over its back half, the gold
## SENATOREK letters fixed to the bars, lit from below.
static func _rock_wall(st: SurfaceTool, hx: float, hz: float, rng: RandomNumberGenerator) -> void:
	var x := -hx - 0.2
	Models.box(st, Vector3(x, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, ROOM.y + 0.2), Color("#3d3a37"), Models.FIXED)
	var greys := [Color("#5b5752"), Color("#6a655e"), Color("#4a4642"), Color("#77706a"), Color("#544f4a")]
	var y := 0.0
	while y < WALL_H:
		var h := rng.randf_range(0.25, 0.55)
		var z := -hz
		while z < hz:
			var w := rng.randf_range(0.35, 0.9)
			var d := rng.randf_range(0.04, 0.22)
			Models.box(st, Vector3(x + 0.2 + d * 0.5, y + h * 0.5, z + w * 0.5), Vector3(d, h - 0.03, w - 0.03), greys[rng.randi() % greys.size()], Models.FIXED)
			z += w
		y += h
	# The bars and their frame over the back half.
	var bars_x := -hx + 0.42
	for i in 22:
		Models.box(st, Vector3(bars_x, WALL_H * 0.5, -hz + 0.4 + i * 0.25), Vector3(0.04, WALL_H, 0.04), Color("#2a2a2e"), Models.FIXED)
	for yy: float in [0.35, WALL_H - 0.3]:
		Models.box(st, Vector3(bars_x, yy, -hz + 3.0), Vector3(0.06, 0.06, 5.6), Color("#2a2a2e"), Models.FIXED)
	var word := "SENATOREK"
	var px := 0.095
	var w := PixelFont.width(word) * px
	var mid := -hz + 3.0
	PixelFont.add_quads(st, word, Vector3(bars_x + 0.05, 2.75, mid + w * 0.5), Vector3(0, 0, -1), Vector3(0, -1, 0), px, GOLD, Models.LIT_SIGN)
	Models.box(st, Vector3(bars_x + 0.1, 0.05, mid), Vector3(0.12, 0.06, 5.4), Color("#ffcf8a"), Models.LIT_SIGN)


## A curved banquette of rust velvet round `c`, radius r, `arc` degrees opening to `face` (0 = +Z).
static func _banquette(st: SurfaceTool, c: Vector3, r: float, arc: float, face: float) -> void:
	var n := int(arc / 20.0) + 1
	var open := deg_to_rad(90.0 - face)     # the opening's direction as an angle on (cos, sin)
	var velvet := [Color("#8a3a24"), Color("#94422a")]
	for i in n:
		var a := open + PI + deg_to_rad(-arc * 0.5 + arc * i / float(n - 1))
		var dir := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a - PI * 0.5)
		var seg := TAU * r * 20.0 / 360.0 + 0.08
		Club._leaf(st, c + dir * r + Vector3(0, 0.22, 0), b, Vector3(seg, 0.44, 0.62), Color("#2a1e1a"))
		Club._leaf(st, c + dir * r + Vector3(0, 0.5, 0), b, Vector3(seg, 0.14, 0.6), velvet[i % 2])
		Club._leaf(st, c + dir * (r + 0.36) + Vector3(0, 0.82, 0), b, Vector3(seg * 1.2, 0.68, 0.2), velvet[(i + 1) % 2])


## A black table, round-ish (two crossed boxes), on a pedestal.
static func _table(st: SurfaceTool, c: Vector3, r: float) -> void:
	Models.box(st, c + Vector3(0, 0.28, 0), Vector3(0.18, 0.56, 0.18), Color("#141416"), Models.FIXED)
	Models.box(st, c + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), Color("#141416"), Models.FIXED)
	Club._leaf(st, c + Vector3(0, 0.58, 0), Basis.IDENTITY, Vector3(r * 2.0, 0.05, r * 1.4), Color("#18181b"))
	Club._leaf(st, c + Vector3(0, 0.58, 0), Basis.IDENTITY, Vector3(r * 1.4, 0.05, r * 2.0), Color("#18181b"))


## A grey armchair on brass legs, its back away from `yaw`'s +Z.
static func _armchair(st: SurfaceTool, c: Vector3, yaw_a: float) -> void:
	var b := Basis(Vector3.UP, yaw_a)
	for k: Vector2 in [Vector2(-0.26, -0.26), Vector2(0.26, -0.26), Vector2(-0.26, 0.26), Vector2(0.26, 0.26)]:
		Club._leaf(st, c + b * Vector3(k.x, 0.12, k.y), b, Vector3(0.04, 0.24, 0.04), Color("#b8954a"))
	Club._leaf(st, c + b * Vector3(0, 0.34, 0), b, Vector3(0.7, 0.2, 0.66), Color("#8c8c8e"))
	Club._leaf(st, c + b * Vector3(0, 0.66, -0.28), b, Vector3(0.7, 0.5, 0.14), Color("#7e7e82"))
	for s in [-1.0, 1.0]:
		Club._leaf(st, c + b * Vector3(0.32 * s, 0.52, 0), b, Vector3(0.1, 0.18, 0.6), Color("#7e7e82"))


## A shisha on a table: a smoked-glass base, the stem in brass, the tray, the bowl, the coals,
## the hose in a loop to the table's edge.
static func _hookah(st: SurfaceTool, at: Vector3, rng: RandomNumberGenerator) -> void:
	var glass: Color = [Color("#2f6a78"), Color("#6a2f5a"), Color("#3a5a2f"), Color("#4a4a6a")][rng.randi() % 4]
	Models.box(st, at + Vector3(0, 0.16, 0), Vector3(0.3, 0.32, 0.3), glass, Models.FIXED)
	Models.box(st, at + Vector3(0, 0.34, 0), Vector3(0.18, 0.06, 0.18), glass, Models.FIXED)
	Models.box(st, at + Vector3(0, 0.62, 0), Vector3(0.05, 0.5, 0.05), Color("#b8954a"), Models.FIXED)
	Models.box(st, at + Vector3(0, 0.82, 0), Vector3(0.3, 0.02, 0.3), Color("#c9ccd1"), Models.FIXED)
	Models.box(st, at + Vector3(0, 0.9, 0), Vector3(0.14, 0.12, 0.14), Color("#7a4a32"), Models.FIXED)
	Models.box(st, at + Vector3(0, 0.98, 0), Vector3(0.12, 0.04, 0.12), Color("#ff6a2a"), Models.LIT_SIGN)
	var a := rng.randf() * TAU
	var dir := Vector3(cos(a), 0, sin(a))
	for k in 4:
		var t := (k + 0.5) / 4.0
		var p := at + Vector3(0, 0.5, 0) + dir * (0.12 + t * 0.4) + Vector3(0, -sin(t * PI) * 0.25, 0)
		Club._leaf(st, p, Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, (0.5 - t) * 1.2), Vector3(0.14, 0.03, 0.03), Color("#1d1d20"))


## An olive tree in a black planter: a twisted trunk, a loose crown of small grey-green leaves.
static func _olive(st: SurfaceTool, at: Vector3, rng: RandomNumberGenerator) -> void:
	Models.box(st, at + Vector3(0, 0.35, 0), Vector3(0.8, 0.7, 0.8), Color("#141416"), Models.FIXED)
	Models.box(st, at + Vector3(0, 0.71, 0), Vector3(0.7, 0.02, 0.7), Color("#3a2e24"), Models.FIXED)
	var top := at + Vector3(0, 0.7, 0)
	for k in 4:
		var lean := Vector3(rng.randf_range(-0.12, 0.12), 0.45, rng.randf_range(-0.12, 0.12))
		Club._leaf(st, top + lean * 0.5, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, lean.x), Vector3(0.14, 0.5, 0.14), Color("#6b5a48"))
		top += lean
	var greens := [Color("#7d8a5a"), Color("#8f9b6a"), Color("#6b7a4c"), Color("#a3ad80")]
	for i in 70:
		var o := Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.3, 0.7), rng.randf_range(-0.8, 0.8))
		if o.length() > 0.95:
			continue
		Club._leaf(st, top + o, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.8, 0.8)), Vector3(0.22, 0.03, 0.08), greens[i % 4])


## The terrace (TERRACE, room-local): travertine, the tower's glass wall at the back with the
## lounge's door, a glass balustrade on the left with the Palace's tower beyond it over the city's
## lights, teak armchairs with cream cushions round travertine tables, olive trees, bulb garlands.
static func _terrace(st: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var o := TERRACE
	var hx := TER.x * 0.5
	var hz := TER.y * 0.5
	Models.box(st, o + Vector3(0, -0.1, 0), Vector3(TER.x, 0.2, TER.y), Color("#d6cdbd"), Models.FIXED)
	for i in 11:
		Models.box(st, o + Vector3(-hx + 1.0 + i * 1.4, 0.005, 0), Vector3(0.02, 0.01, TER.y), Color("#c4bba9"), Models.FIXED)
	for i in 8:
		Models.box(st, o + Vector3(0, 0.005, -hz + 0.7 + i * 1.4), Vector3(TER.x, 0.01, 0.02), Color("#c4bba9"), Models.FIXED)
	# The tower's curtain wall: tall glass, silver mullions, the door back in, warm lit.
	Models.box(st, o + Vector3(0, 5.0, -hz - 0.15), Vector3(TER.x, 10.0, 0.3), Color("#26364a"), Models.FIXED)
	for i in 12:
		Models.box(st, o + Vector3(-hx + i * 1.45, 5.0, -hz + 0.02), Vector3(0.08, 10.0, 0.1), Color("#9aa3ad"), Models.FIXED)
	for yy: float in [3.4, 6.8, 10.0]:
		Models.box(st, o + Vector3(0, yy, -hz + 0.02), Vector3(TER.x, 0.12, 0.12), Color("#9aa3ad"), Models.FIXED)
	for i in 20:
		var x := rng.randf_range(-hx + 0.6, hx - 0.6)
		var y := rng.randf_range(3.9, 9.6)
		Models.box(st, o + Vector3(x, y, -hz + 0.01), Vector3(0.9, 0.5, 0.02), Color("#ffe3a8"), Models.LIT_WINDOW)
	Models.box(st, o + Vector3(-2.0, 1.3, -hz + 0.05), Vector3(1.6, 2.6, 0.04), Color("#ffd89a"), Models.LIT_SIGN)
	PixelFont.add_quads(st, "SENATOREK", o + Vector3(-2.0 - PixelFont.width("SENATOREK") * 0.035 * 0.5, 3.1, -hz + 0.08), Vector3(1, 0, 0), Vector3(0, -1, 0), 0.035, GOLD, Models.LIT_SIGN)
	# The balustrade: glass on the left, posts and a rail at the front.
	Models.box(st, o + Vector3(-hx + 0.05, 0.6, 0), Vector3(0.05, 1.1, TER.y), Color("#9cc4c8"), Models.FIXED)
	Models.box(st, o + Vector3(-hx + 0.05, 1.17, 0), Vector3(0.08, 0.05, TER.y), Color("#c9ccd1"), Models.FIXED)
	for i in 9:
		Models.box(st, o + Vector3(-hx + 1.0 + i * 1.8, 0.55, hz - 0.05), Vector3(0.05, 1.1, 0.05), Color("#c9ccd1"), Models.FIXED)
	Models.box(st, o + Vector3(0, 1.12, hz - 0.05), Vector3(TER.x, 0.05, 0.06), Color("#c9ccd1"), Models.FIXED)
	# The Palace's tower beyond, over the city's lights (the void below is the dark city).
	# A model at half size, so the whole tower and its spire stand in the view.
	var ks := 0.42
	var pal := o + Vector3(-hx - 4.5, -0.5, 3.0)
	var sand := Color("#cdbd9c")
	var tiers := [[9.0, 0.0, 5.0], [6.0, 5.0, 9.5], [4.2, 9.5, 12.6], [2.8, 12.6, 14.8], [1.6, 14.8, 16.4]]
	for t: Array in tiers:
		Models.box(st, pal + Vector3(0, (t[1] + t[2]) * 0.5, 0) * ks, Vector3(t[0], t[2] - t[1], t[0]) * ks, sand, Models.FIXED)
		Models.box(st, pal + Vector3(0, t[2] - 0.15, 0) * ks, Vector3(t[0] + 0.3, 0.3, t[0] + 0.3) * ks, sand.darkened(0.15), Models.FIXED)
	for side in [-1.0, 1.0]:
		Models.box(st, pal + Vector3(side * 6.5, 3.0, 0) * ks, Vector3(2.2, 6.0, 2.2) * ks, sand, Models.FIXED)
	Models.box(st, pal + Vector3(0, 18.6, 0) * ks, Vector3(0.24, 4.4, 0.24) * ks, Color("#d8c89a"), Models.FIXED)
	Models.box(st, pal + Vector3(0, 13.7, 1.42) * ks, Vector3(1.0, 1.0, 0.06) * ks, Color("#f2e3b0"), Models.LIT_SIGN)
	Models.box(st, pal + Vector3(1.42, 13.7, 0) * ks, Vector3(0.06, 1.0, 1.0) * ks, Color("#f2e3b0"), Models.LIT_SIGN)
	for t: Array in tiers.slice(0, 3):
		var w: float = t[0]
		for r in int((t[2] - t[1]) / 0.8):
			for c in int(w / 0.7):
				Models.box(st, pal + Vector3(-w * 0.5 + 0.35 + c * 0.7, t[1] + 0.4 + r * 0.8, w * 0.5 + 0.02) * ks, Vector3(0.24, 0.36, 0.03) * ks, Color("#ffe0a0"), Models.LIT_WINDOW)
				Models.box(st, pal + Vector3(w * 0.5 + 0.02, t[1] + 0.4 + r * 0.8, -w * 0.5 + 0.35 + c * 0.7) * ks, Vector3(0.03, 0.36, 0.24) * ks, Color("#ffe0a0"), Models.LIT_WINDOW)
	for i in 260:
		var p := o + Vector3(rng.randf_range(-hx - 30.0, -hx - 1.5), -0.08, rng.randf_range(-hz - 20.0, hz + 12.0))
		Models.box(st, p, Vector3(0.12, 0.04, 0.12), Color("#ffd58a") if rng.randf() < 0.7 else Color("#dfe8ff"), Models.LIT_WINDOW)
	# Tables with teak armchairs and cream cushions; ours, three more.
	for t: Vector3 in [OURS_TER, o + Vector3(4.2, 0, -2.4), o + Vector3(4.6, 0, 3.0), o + Vector3(-4.8, 0, 3.0)]:
		Models.box(st, t + Vector3(0, 0.3, 0), Vector3(0.24, 0.6, 0.24), Color("#bfb4a2"), Models.FIXED)
		Models.box(st, t + Vector3(0, 0.62, 0), Vector3(1.1, 0.06, 1.1), Color("#ddd3c2"), Models.FIXED)
		_hookah(st, t + Vector3(0, 0.65, 0), rng)
		for k in 4:
			var a := TAU * k / 4.0 + 0.3
			var b := Basis(Vector3.UP, -a - PI * 0.5)
			var c := t + Vector3(cos(a), 0, sin(a)) * 1.0
			Club._leaf(st, c + Vector3(0, 0.2, 0), b, Vector3(0.66, 0.4, 0.62), Color("#8a5a32"))
			Club._leaf(st, c + Vector3(0, 0.45, 0), b, Vector3(0.6, 0.1, 0.56), Color("#efe6d2"))
			Club._leaf(st, c + Vector3(cos(a), 0, sin(a)) * 0.28 + Vector3(0, 0.7, 0), b, Vector3(0.66, 0.5, 0.08), Color("#8a5a32"))
	for p: Vector3 in [o + Vector3(-hx + 0.9, 0, -hz + 0.9), o + Vector3(hx - 0.9, 0, -hz + 0.9), o + Vector3(hx - 0.9, 0, 1.0)]:
		_olive(st, p, rng)
	# The garlands: posts at the front corners, bulbs swinging low to the curtain wall.
	for pole: Vector3 in [o + Vector3(-hx + 0.4, 0, hz - 0.4), o + Vector3(hx - 0.4, 0, hz - 0.4)]:
		Models.box(st, pole + Vector3(0, 1.7, 0), Vector3(0.08, 3.4, 0.08), Color("#2a2a30"), Models.FIXED)
	for g: Array in [[o + Vector3(-hx + 0.4, 3.3, hz - 0.4), o + Vector3(-hx + 3.0, 3.6, -hz)], [o + Vector3(-hx + 0.4, 3.3, hz - 0.4), o + Vector3(hx - 0.4, 3.3, hz - 0.4)],
			[o + Vector3(hx - 0.4, 3.3, hz - 0.4), o + Vector3(hx - 4.0, 3.6, -hz)], [o + Vector3(-hx + 0.4, 3.3, hz - 0.4), o + Vector3(2.0, 3.6, -hz)]]:
		var a: Vector3 = g[0]
		var b: Vector3 = g[1]
		var n := int(a.distance_to(b) / 0.6)
		for i in n + 1:
			var t := float(i) / n
			Models.box(st, a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.6, 0), Vector3(0.1, 0.12, 0.1), Color("#fff1c4") if i % 3 else Color("#ffd27a"), Models.LIT_SIGN)


## The warm light cones (local frame): spots down onto the tables in the room, softer bulbs'
## glow on the terrace.
static func light_pose(on_terrace: bool, t: float) -> Array:
	var out: Array = []
	var flick := 0.92 + 0.08 * sin(t * 1.7)
	if on_terrace:
		for p: Vector3 in [OURS_TER, TERRACE + Vector3(4.2, 0, -2.4), TERRACE + Vector3(4.6, 0, 3.0), TERRACE + Vector3(-4.8, 0, 3.0)]:
			out.append([Rave._aim(p + Vector3(0, 3.2, 0), Vector3.DOWN, 1.6, 3.1), Color("#ffcf8a") * 0.22 * flick])
	else:
		for p: Vector3 in [OURS, Vector3(-5.0, 0, -3.9), Vector3(0.6, 0, -3.9), Vector3(5.4, 0, -3.9)]:
			out.append([Rave._aim(p + Vector3(0, WALL_H - 0.5, 0), Vector3.DOWN, 1.4, WALL_H - 0.6), Color("#ffcf8a") * 0.26 * flick])
	while out.size() < 6:
		out.append([Rave._aim(Vector3(-5.8, WALL_H - 0.5, 3.0), Vector3.DOWN, 1.0, WALL_H - 0.6), Color("#ffcf8a") * (0.0 if on_terrace else 0.2)])
	return out


# --- building it ------------------------------------------------------------------------------

func _build(world: Node3D) -> void:
	_built = true
	_rng.randomize()
	_data = Shisha.load_data()
	_jars = _data.get("jars", [])
	_room = MeshInstance3D.new()
	_room.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_room.name = "LoungeRoom"
	_room.mesh = room_mesh()
	_room.material_override = Models.material()
	_room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_room.position = PLACE
	world.add_child(_room)
	_build_people(world)
	_build_smoke(world)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader")
	mat.render_priority = 1
	mat.set_shader_parameter("lift", 0.0)
	mat.set_shader_parameter("strength", 1.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Rave.cone_mesh()
	mm.instance_count = 6
	_lights = MultiMeshInstance3D.new()
	_lights.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_lights.multimesh = mm
	_lights.material_override = mat
	_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lights.position = PLACE
	world.add_child(_lights)
	_build_ui()
	_show(false)


## The people (one MultiMesh, room-local): our three on the banquette, Mistrz Dymek standing at
## our table, the waiter, the barman, guests at the booths, the armchairs and on the terrace.
func _build_people(world: Node3D) -> void:
	var dmat := Models.material().duplicate() as ShaderMaterial
	dmat.set_shader_parameter("walk", 0.0)
	_seats.clear()
	people.clear()
	var ring := func(c: Vector3, r: float, a_deg: float) -> Array:
		var a := deg_to_rad(a_deg)
		var p := c + Vector3(cos(a), -0.42, sin(a)) * r
		p.y = -0.42
		return [p, atan2(-cos(a), -sin(a))]
	# Ours: Ivan (navy hoodie), Bogdan (tennis white), you (teal); the opening faces the camera.
	var named := [["Ivan", 165.0, Color("#2f3e6a")], ["Bogdan", 225.0, Color("#f2f2ee")], ["Ty", 285.0, TEAL]]
	for row: Array in named:
		var s: Array = ring.call(OURS, 1.25, row[1])
		_seats.append([s[0], s[1], row[2]])
		people.append([row[0], s[0]])
	_seats.append([OURS + Vector3(1.75, 0, -0.35), atan2(-1.0, 0.2), Color("#3a2a22")])
	people.append(["Mistrz", OURS + Vector3(1.75, 0, -0.35)])
	_seats.append([Vector3(-6.2, 0, 1.6), PI * 0.5, Color("#e8e2d6")])
	people.append(["Kelner", Vector3(-6.2, 0, 1.6)])
	_seats.append([Vector3(-ROOM.x * 0.5 + 0.75, 0, 3.6), PI * 0.5, Color("#2a2a2e")])
	people.append(["Barman", Vector3(-ROOM.x * 0.5 + 0.75, 0, 3.6)])
	var clothes := [Color("#1a1a1e"), Color("#5a4636"), Color("#e8e2d6"), Color("#3a4a5a"), Color("#7a2a3a"), Color("#2e2e34"), Color("#c8b89a")]
	var k := 0
	for b: Vector3 in [Vector3(-5.0, 0, -3.9), Vector3(0.6, 0, -3.9), Vector3(5.4, 0, -3.9)]:
		for a: float in [210.0, 270.0, 330.0]:
			var s: Array = ring.call(b, 1.15, a)
			_seats.append([s[0], s[1], clothes[k % clothes.size()]])
			if k % 3 == 1:
				people.append(["Goście", s[0]])
			k += 1
	for g: Vector3 in [Vector3(4.6, 0, 1.4), Vector3(5.6, 0, 4.4)]:
		for j in 2:
			var a := TAU * j / 3.0 + 0.4
			var p := g + Vector3(cos(a), 0, sin(a)) * 1.0
			_seats.append([Vector3(p.x, -0.38, p.z), atan2(-cos(a), -sin(a)), clothes[k % clothes.size()]])
			k += 1
	people.append(["Goście", _seats[_seats.size() - 1][0]])
	for t: Vector3 in [TERRACE + Vector3(4.2, 0, -2.4), TERRACE + Vector3(4.6, 0, 3.0), TERRACE + Vector3(-4.8, 0, 3.0)]:
		for j in 2:
			var a := TAU * j / 4.0 + 0.3
			var p := t + Vector3(cos(a), 0, sin(a)) * 0.95
			_seats.append([Vector3(p.x, -0.38, p.z), atan2(-cos(a), -sin(a)), clothes[k % clothes.size()]])
			k += 1
	people.append(["Oliwka", Vector3(-3.6, 0, 3.6)])
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_custom_data = true
	InstanceBuffers.prepare(dm)
	dm.mesh = Models.person_mesh()
	dm.instance_count = _seats.size()
	InstanceBuffers.whiten(dm)
	for i in _seats.size():
		dm.set_instance_custom_data(i, Color(_seats[i][2], 0.25))
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, _seats[i][1]), _seats[i][0]))
	_people = MultiMeshInstance3D.new()
	_people.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_people.multimesh = dm
	_people.material_override = dmat
	_people.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_people.position = PLACE
	world.add_child(_people)


## The smoke: a pool of soft puffs (one MultiMesh, unshaded, see-through, coloured per puff).
func _build_smoke(world: Node3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 0.8
	sphere.radial_segments = 8
	sphere.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.render_priority = 2
	sphere.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = PUFFS
	_smoke = MultiMeshInstance3D.new()
	_smoke.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_smoke.multimesh = mm
	_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke.position = PLACE
	world.add_child(_smoke)
	_pp.resize(PUFFS)
	_pv.resize(PUFFS)
	_page.resize(PUFFS)
	_plife.resize(PUFFS)
	_psize.resize(PUFFS)
	_palpha.resize(PUFFS)
	for i in PUFFS:
		_page[i] = 1.0
		_plife[i] = 1.0
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001), Vector3(0, -50, 0)))
		mm.set_instance_color(i, Color(1, 1, 1, 0))


# --- the panel --------------------------------------------------------------------------------

func _build_ui() -> void:
	var pt: float = hud.pt if hud != null else 1.0
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", Club._box(Color(0.04, 0.035, 0.03, 0.85), GOLD))
	top.position = Vector2(16, 16) * pt
	_ui.add_child(top)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", int(16 * pt))
	_title.add_theme_color_override("font_color", GOLD)
	top.add_child(_title)
	_talk = PanelContainer.new()
	_talk.add_theme_stylebox_override("panel", Club._box(Color(0.04, 0.035, 0.03, 0.9), TEAL))
	_talk.custom_minimum_size = Vector2(360, 0) * pt
	_ui.add_child(_talk)
	var v := VBoxContainer.new()
	_talk.add_child(v)
	_who = Label.new()
	_who.add_theme_font_size_override("font_size", int(13 * pt))
	_who.add_theme_color_override("font_color", TEAL)
	v.add_child(_who)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.x = 340 * pt
	_line.add_theme_font_size_override("font_size", int(14 * pt))
	v.add_child(_line)
	# The mini-game panel, top right.
	_game = PanelContainer.new()
	_game.add_theme_stylebox_override("panel", Club._box(Color(0.04, 0.035, 0.03, 0.9), GOLD))
	_ui.add_child(_game)
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", int(6 * pt))
	_game.add_child(g)
	_game_title = Label.new()
	_game_title.add_theme_font_size_override("font_size", int(14 * pt))
	_game_title.add_theme_color_override("font_color", GOLD)
	g.add_child(_game_title)
	_game_hint = Label.new()
	_game_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_game_hint.custom_minimum_size.x = 250 * pt
	_game_hint.add_theme_font_size_override("font_size", int(11 * pt))
	_game_hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.76))
	g.add_child(_game_hint)
	_chart = Control.new()
	_chart.custom_minimum_size = Vector2(250, 112) * pt
	_chart.draw.connect(_draw_chart)
	g.add_child(_chart)
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(250, 30) * pt
	_bar.draw.connect(_draw_bar)
	g.add_child(_bar)
	_jar_box = GridContainer.new()
	_jar_box.columns = 3
	_jar_box.add_theme_constant_override("h_separation", int(6 * pt))
	_jar_box.add_theme_constant_override("v_separation", int(6 * pt))
	g.add_child(_jar_box)
	for jar: Dictionary in _jars:
		var id := String(jar["id"])
		var short: Array = JAR_SHORT.get(id, [jar["pl"], jar["en"]])
		var b := _button(_jar_box, String(short[0]), String(short[1]), JAR_COLOURS.get(id, GOLD), pt, Vector2.ZERO)
		b.pressed.connect(func() -> void: _on_jar(id))
		_jar_btns[id] = b
	_act = _button(g, "TERAZ!", "NOW!", TEAL, pt, Vector2(250, 52))
	_act.pressed.connect(_on_act)
	_act.button_down.connect(func() -> void:
		if step_now == Step.DRAW:
			_holding = true)
	_act.button_up.connect(func() -> void:
		if step_now == Step.DRAW and _holding:
			_holding = false
			_end_draw())
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", int(10 * pt))
	_ui.add_child(_buttons)
	_smoke_btn = _button(_buttons, "PALIĆ", "SMOKE", TEAL, pt, Vector2(96, 52))
	_smoke_btn.pressed.connect(func() -> void: _start_smoke("smoke"))
	_terrace_btn = _button(_buttons, "TARAS", "TERRACE", GOLD, pt, Vector2(96, 52))
	_terrace_btn.pressed.connect(func() -> void: _start_smoke("terrace"))
	_out_btn = _button(_buttons, "WYJDŹ", "LEAVE", Color("#e0e0e0"), pt, Vector2(96, 52))
	_out_btn.pressed.connect(leave)
	_layout()


func _button(parent: Node, pl: String, en: String, accent: Color, pt: float, size: Vector2) -> Button:
	var b: Button
	if hud != null and hud.has_method("_chip"):
		b = hud._chip(parent, pl, en, accent)
	else:
		b = Button.new()
		b.text = Lang.pick(pl, en)
		parent.add_child(b)
	if size != Vector2.ZERO:
		b.custom_minimum_size = size * pt
	return b


## New words on a button (the hud's chip keeps its own labels), its width kept.
func _chip_text(b: Button, pl: String, en: String) -> void:
	var w := b.custom_minimum_size
	if hud != null and hud.has_method("_set_chip"):
		hud._set_chip(b, pl, en)
	else:
		b.text = Lang.pick(pl, en)
	b.custom_minimum_size = w


func _layout() -> void:
	var pt: float = hud.pt if hud != null else 1.0
	var vp := get_viewport().get_visible_rect().size
	_buttons.reset_size()
	var room := clampf(vp.x - _buttons.size.x - 48 * pt, 220 * pt, 360 * pt)
	_talk.custom_minimum_size.x = room
	_line.custom_minimum_size.x = room - 20 * pt
	_talk.size.x = room
	_talk.reset_size()
	_talk.position = Vector2(16 * pt, vp.y - _talk.size.y - 16 * pt)
	_game.reset_size()
	_game.position = Vector2(vp.x - _game.size.x - 16 * pt, 16 * pt)
	_buttons.reset_size()
	_buttons.position = vp - _buttons.size - Vector2(16, 16) * pt


## The chart: sweet → across, cool ↑ up; the friends' pins, the jars, the mix and the hearts.
func _draw_chart() -> void:
	var sz := _chart.size
	var font := ThemeDB.fallback_font
	var fs := maxi(10, int(sz.y / 13.0))
	var pad := Vector2(26, 10)
	var area := Rect2(pad, sz - pad - Vector2(10, 26))
	var to := func(p: Vector2) -> Vector2:
		return area.position + Vector2(p.x / 5.0 * area.size.x, (1.0 - p.y / 5.0) * area.size.y)
	_chart.draw_rect(area, Color(1, 1, 1, 0.05))
	_chart.draw_line(area.position + Vector2(0, area.size.y), area.end, Color(1, 1, 1, 0.5), 2.0)
	_chart.draw_line(area.position, area.position + Vector2(0, area.size.y), Color(1, 1, 1, 0.5), 2.0)
	_chart.draw_string(font, Vector2(area.position.x, sz.y - 6), Lang.pick("SŁODKIE →", "SWEET →"), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.7))
	_chart.draw_string(font, Vector2(area.end.x - 70, area.end.y - 6), Lang.pick("↑ CHŁÓD", "↑ COOL"), HORIZONTAL_ALIGNMENT_RIGHT, 64, fs, Color(1, 1, 1, 0.7))
	for pin: Array in [[IVAN_PIN, "IVAN", Color("#7aa0ff")], [BOGDAN_PIN, "BOGDAN", Color("#f2f2ee")]]:
		var c: Vector2 = to.call(pin[0])
		_chart.draw_circle(c, 11.0, Color(pin[2], 0.18))
		_chart.draw_circle(c, 5.0, pin[2])
		_chart.draw_string(font, c + Vector2(7, -4), String(pin[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, pin[2])
	for jar: Dictionary in _jars:
		var c: Vector2 = to.call(Vector2(float(jar["sweet"]), float(jar["cool"])))
		var col: Color = JAR_COLOURS.get(String(jar["id"]), GOLD)
		_chart.draw_circle(c, 4.0, col)
		if String(jar["id"]) in picked:
			_chart.draw_arc(c, 8.0, 0.0, TAU, 20, GOLD, 2.0)
	if picked.size() == 2:
		var m: Vector2 = to.call(mix_point(_jar(picked[0]), _jar(picked[1])))
		_chart.draw_circle(m, 6.0, GOLD)
		_chart.draw_string(font, m + Vector2(8, 12), "MIX", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GOLD)
	var hs := "Ivan %s   Bogdan %s" % [_hearts_text(hearts_now.x), _hearts_text(hearts_now.y)]
	if picked.size() == 2:
		_chart.draw_string(font, Vector2(area.position.x + 6, area.position.y + fs + 2), hs, HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 12, fs, GOLD)


static func _hearts_text(n: int) -> String:
	return "%d/3" % n


## The bar: the coal's glow or the draw's cloud, its band in green.
func _draw_bar() -> void:
	var sz := _bar.size
	var r := Rect2(Vector2(4, 6), sz - Vector2(8, 12))
	_bar.draw_rect(r, Color(1, 1, 1, 0.08))
	var band := coal_band(strength) if step_now == Step.COAL else DRAW_BAND
	var v := _glow() if step_now == Step.COAL else _cloud
	var col := Color("#ff6a2a").lerp(Color("#ffd27a"), v) if step_now == Step.COAL else Color(0.92, 0.94, 1.0, 0.8)
	_bar.draw_rect(Rect2(r.position, Vector2(clampf(v, 0, 1) * r.size.x, r.size.y)), col)
	var zone := Rect2(r.position + Vector2(band.x * r.size.x, 0), Vector2((band.y - band.x) * r.size.x, r.size.y))
	_bar.draw_rect(zone, Color(0.3, 0.95, 0.45, 0.3))
	_bar.draw_rect(zone, Color(0.3, 0.95, 0.45), false, 3.0)
	_bar.draw_rect(r, Color(1, 1, 1, 0.4), false, 2.0)


# --- in and out -------------------------------------------------------------------------------

## In from the lift with the car's votes: the room built (once) in `world`, the waiter's order.
func enter(world: Node3D, v: Dictionary) -> void:
	if not _built:
		_build(world)
	votes = v
	strength = int(v.get("strength", 3))
	picked = []
	hearts_now = Vector2i.ZERO
	coal_pts = 0
	ringed = false
	score = 0
	how = ""
	inside = true
	_clock = 0.0
	_go("sala")
	_title.text = Lang.pick("SENATOREK · Emilii Plater 53", "SENATOREK · Emilii Plater 53")
	_set_step(Step.ORDER)
	_lines.clear()
	_queue("order")
	_log("in: votes %s" % v)


func _go(where: String) -> void:
	area = where
	var ter := where == "taras"
	centre = PLACE + (OURS_TER if ter else OURS) + Vector3(1.0, 1.2, -1.0)
	view_size = TER_VIEW if ter else VIEW
	_show(true)
	if ter:
		for i in 4:
			var a := deg_to_rad([200.0, 250.0, 300.0, 40.0][i])
			var p := OURS_TER + Vector3(cos(a), 0, sin(a)) * 1.0
			p.y = -0.38 if i < 3 else 0.0
			_seats[i][0] = p
			_seats[i][1] = atan2(-cos(a), -sin(a))
		people[0][1] = _seats[0][0]
		people[1][1] = _seats[1][0]
		people[2][1] = _seats[2][0]
		people[3][1] = _seats[3][0]
	_pose_people()


## WYJDŹ: before the smoke it is "leave"; during it, the evening as chosen.
func leave() -> void:
	if not inside:
		return
	_finish("leave" if how == "" else how)


func _finish(h: String) -> void:
	inside = false
	how = h
	_show(false)
	_set_step(Step.NONE)
	_log("out: %s, score %d" % [h, score])
	done.emit(h, score if h != "leave" else 0)


func _show(on: bool) -> void:
	_room.visible = on
	_people.visible = on
	_smoke.visible = on
	_lights.visible = on
	_ui.visible = on


func _set_step(s: Step) -> void:
	step_now = s
	_step_t = 0.0
	var game_on := s in [Step.JARS, Step.COAL, Step.DRAW, Step.RESULT]
	_game.visible = game_on
	_chart.visible = s in [Step.JARS, Step.RESULT]
	_bar.visible = s in [Step.COAL, Step.DRAW]
	_jar_box.visible = s == Step.JARS
	_act.visible = s in [Step.COAL, Step.DRAW]
	_smoke_btn.visible = s == Step.RESULT
	_terrace_btn.visible = s == Step.RESULT
	match s:
		Step.JARS:
			_game_title.text = Lang.pick("MIKS U MISTRZA · 1/3 SŁOIKI", "THE MASTER'S MIX · 1/3 JARS")
			_game_hint.text = Lang.pick("Wybierz dwa słoiki. Miks to środek między nimi. Ivan lubi słodko, Bogdan chłodno.",
					"Pick two jars. The mix is halfway between them. Ivan likes sweet, Bogdan likes cool.")
		Step.COAL:
			_game_title.text = Lang.pick("MIKS U MISTRZA · 2/3 WĘGIEL", "THE MASTER'S MIX · 2/3 COAL")
			_game_hint.text = Lang.pick("Stuknij, gdy żar jest w zielonym. Im mocniej, tym węższe pole.",
					"Tap when the glow is in the green. The stronger, the narrower.")
			_chip_text(_act, "TERAZ!", "NOW!")
		Step.DRAW:
			_game_title.text = Lang.pick("MIKS U MISTRZA · 3/3 PIERWSZY BUCH", "THE MASTER'S MIX · 3/3 FIRST DRAW")
			_game_hint.text = Lang.pick("Trzymaj, puść w zielonym: kółko z dymu.", "Hold, let go in the green: a smoke ring.")
			_chip_text(_act, "TRZYMAJ · PUŚĆ", "HOLD · LET GO")
			_cloud = 0.0
		Step.RESULT:
			_game_title.text = Lang.pick("WYNIK · %d/9" % score, "SCORE · %d/9" % score)
			_game_hint.text = Lang.pick("Fajka „%s”. Palimy w sali, na tarasie, czy do auta?" % _pipe(0),
					"The pipe \"%s\". Smoke inside, on the terrace, or back to the car?" % _pipe(1))
	if _ui != null:
		_layout()


func _pipe(i: int) -> String:
	var p: Array = votes.get("name", ["Forhend", "Forehand"])
	return String(p[i])


# --- the frame --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside or dt <= 0.0:
		return
	_clock += dt
	_step_t += dt
	_lines_tick(dt)
	_smoke_tick(dt)
	_pose_lights()
	_pose_people()
	match step_now:
		Step.ORDER:
			if _lines.is_empty() and _line_t <= 0.0:
				_start_jars()
		Step.JARS:
			if auto_play and _step_t > AUTO_WAIT and _lines.is_empty():
				var best := best_jars(_jars, strength)
				picked = []
				for id: String in best:
					_on_jar(id)
			elif _step_t > STEP_LIFE * 2.0 and picked.size() < 2:
				var best := best_jars(_jars, 3)
				for id: String in best:
					if picked.size() < 2 and not id in picked:
						_on_jar(id)
		Step.COAL:
			_bar.queue_redraw()
			var band := coal_band(strength)
			if auto_play and _lines.is_empty() and _step_t > AUTO_WAIT and absf(_glow() - (band.x + band.y) * 0.5) < 0.02:
				_on_act()
			elif _step_t > STEP_LIFE:
				_coal_tap(1.0)
		Step.DRAW:
			var go := auto_play and _lines.is_empty() and _step_t > AUTO_WAIT
			if _holding or (go and _cloud < (DRAW_BAND.x + DRAW_BAND.y) * 0.5):
				_cloud += DRAW_RATE * dt
				_bar.queue_redraw()
				if _cloud > 1.05:
					_holding = false
					_end_draw()
			elif go:
				_end_draw()
			elif _step_t > STEP_LIFE:
				_end_draw()
		Step.RESULT:
			if auto_play and _step_t > AUTO_WAIT and _lines.is_empty():
				_start_smoke(auto_how)
			elif _step_t > STEP_LIFE * 2.0:
				_start_smoke("smoke")
		Step.SMOKE:
			if _step_t > SMOKE_S and _lines.is_empty():
				_finish(how)


func _glow() -> float:
	return fmod(_step_t / COAL_CYCLE, 1.0)


# --- the mini-game ----------------------------------------------------------------------------

func _jar(id: String) -> Dictionary:
	for j: Dictionary in _jars:
		if String(j["id"]) == id:
			return j
	return {"id": id, "sweet": 0.0, "cool": 0.0}


func _start_jars() -> void:
	_set_step(Step.JARS)
	picked = [first_jar(String(votes.get("flavour", "master")))]
	_queue("jars")
	_refresh_jars()


func _on_jar(id: String) -> void:
	if step_now != Step.JARS:
		return
	if id in picked:
		picked.erase(id)
	elif picked.size() < 2:
		picked.append(id)
	_refresh_jars()
	if picked.size() == 2:
		var a := _jar(picked[0])
		var b := _jar(picked[1])
		_game_hint.text = Lang.pick("Miks: %s + %s" % [a.get("pl", ""), b.get("pl", "")], "Mix: %s + %s" % [a.get("en", ""), b.get("en", "")])
		hearts_now = friends_hearts(a, b, strength)
		_chart.queue_redraw()
		if "zupa" in picked:
			_queue("soup")
		elif strength >= 4:
			_queue("two_hoses")
		_log("jars %s: hearts %s" % [picked, hearts_now])
		get_tree().create_timer(1.6 if not auto_play else 0.6).timeout.connect(func() -> void:
			if step_now == Step.JARS and picked.size() == 2:
				_set_step(Step.COAL)
				_queue("coal"))


func _refresh_jars() -> void:
	for id: String in _jar_btns:
		(_jar_btns[id] as Button).modulate = Color(1, 1, 1, 1) if id in picked or picked.size() < 2 else Color(1, 1, 1, 0.45)
	_chart.queue_redraw()


func _on_act() -> void:
	if step_now == Step.COAL:
		_coal_tap(_glow())


func _coal_tap(glow: float) -> void:
	var r := coal_result(glow, strength)
	coal_pts = int(r[0])
	_queue(String(r[1]))
	_log("coal at %.2f: %s" % [glow, r[1]])
	_set_step(Step.DRAW)


func _end_draw() -> void:
	if step_now != Step.DRAW:
		return
	ringed = draw_ok(_cloud)
	_queue("draw_good" if ringed else "draw_bad")
	if ringed:
		_puff_ring(_seat_head(2), Vector3(1, 0.1, 1).normalized())
	else:
		_exhale(_seat_head(0), 8)
	score = total(hearts_now, coal_pts, ringed)
	_queue(result_scene(score))
	_log("draw %.2f ring %s: score %d" % [_cloud, ringed, score])
	_set_step(Step.RESULT)
	_chart.queue_redraw()


## PALIĆ / TARAS: the long smoke (lines from "smoke" or "terrace", rings, haze), then the car.
func _start_smoke(where: String) -> void:
	if step_now != Step.RESULT:
		return
	how = where
	if where == "terrace":
		_go("taras")
		_title.text = Lang.pick("SENATOREK · taras", "SENATOREK · terrace")
	_set_step(Step.SMOKE)
	_queue("terrace" if where == "terrace" else "smoke")
	_queue("ring")
	_log("smoke: %s" % where)


# --- lines ------------------------------------------------------------------------------------

func _queue(id: String) -> void:
	var scenes: Dictionary = _data.get("scenes", {})
	_lines.append_array(scenes.get(id, []))


func _lines_tick(dt: float) -> void:
	_line_t -= dt
	if _line_t > 0.0:
		return
	if _lines.is_empty():
		if _line_t < -LINE_S:
			_talk.visible = false
			_speaker = ""
		return
	var row: Array = _lines.pop_front()
	_line_t = LINE_S * (0.6 if auto_play else 1.0)
	_say(String(row[0]), String(row[1]), String(row[2]))


func _say(who: String, pl: String, en: String) -> void:
	_speaker = who
	_who.text = who if who != "Ty" else Lang.pick("Ty", "You")
	_line.text = Lang.pick(pl, en)
	_talk.visible = true
	_layout()
	if who in ["Ivan", "Bogdan", "Ty"] and step_now == Step.SMOKE:
		_exhale(_seat_head(["Ivan", "Bogdan", "Ty"].find(who)), 5)


# --- the smoke and the people -------------------------------------------------------------------

func _smoke_tick(dt: float) -> void:
	var smoking := step_now in [Step.DRAW, Step.RESULT, Step.SMOKE]
	_emit_t -= dt
	if _emit_t <= 0.0:
		_emit_t = 0.35
		# A thin trickle from every bowl in view; ours thicker while we smoke.
		var bowls: Array = [OURS_TER] if area == "taras" else [OURS, Vector3(-5.0, 0, -3.9), Vector3(0.6, 0, -3.9), Vector3(5.4, 0, -3.9), Vector3(4.6, 0, 1.4)]
		if area == "taras":
			bowls.append_array([TERRACE + Vector3(4.2, 0, -2.4), TERRACE + Vector3(4.6, 0, 3.0)])
		var b: Vector3 = bowls[_rng.randi() % bowls.size()]
		_spawn(b + Vector3(0, 1.62, 0), Vector3(_rng.randf_range(-0.05, 0.05), 0.3, _rng.randf_range(-0.05, 0.05)), 3.2, Vector2(0.06, 0.42), 0.22)
		# A thin haze under the ceiling (the room only).
		if area == "sala" and _rng.randf() < 0.25:
			var h := Vector3(_rng.randf_range(-7, 7), WALL_H - 0.4, _rng.randf_range(-5, 3))
			_spawn(h, Vector3(_rng.randf_range(-0.1, 0.1), 0.0, _rng.randf_range(-0.1, 0.1)), 8.0, Vector2(0.5, 1.1), 0.035)
	if step_now == Step.SMOKE:
		_exhale_t -= dt
		if _exhale_t <= 0.0:
			_exhale_t = _rng.randf_range(1.4, 2.4)
			_turn = (_turn + 1) % 3
			_exhale(_seat_head(_turn), 6)
		_ring_t -= dt
		if _ring_t <= 0.0:
			_ring_t = _rng.randf_range(4.0, 6.0)
			_puff_ring(_seat_head(1), Vector3(1, 0.15, 1).normalized())
	elif smoking and _rng.randf() < dt * 0.3:
		_exhale(_seat_head(_rng.randi() % 3), 4)
	var mm := _smoke.multimesh
	for i in PUFFS:
		if _page[i] >= _plife[i]:
			continue
		_page[i] += dt
		var t := _page[i] / _plife[i]
		_pp[i] += _pv[i] * dt
		_pv[i] *= 1.0 - 0.6 * dt
		_pv[i].y += 0.05 * dt
		var s := lerpf(_psize[i].x, _psize[i].y, sqrt(t))
		var a := _palpha[i] * minf(1.0, t * 6.0) * (1.0 - t)
		if t >= 1.0:
			s = 0.001
			a = 0.0
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), _pp[i]))
		mm.set_instance_color(i, Color(0.96, 0.95, 0.93, a))


func _spawn(at: Vector3, vel: Vector3, life: float, size: Vector2, alpha: float) -> void:
	var i := _pnext
	_pnext = (_pnext + 1) % PUFFS
	_pp[i] = at
	_pv[i] = vel
	_page[i] = 0.0
	_plife[i] = life
	_psize[i] = size
	_palpha[i] = alpha


## An exhale: n puffs out of a mouth, forward and up, widening.
func _exhale(head: Vector3, n: int) -> void:
	var dir := (centre - PLACE - head) * Vector3(1, 0, 1)
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(1, 0, 1).normalized()
	for k in n:
		var v := dir.rotated(Vector3.UP, _rng.randf_range(-0.5, 0.5)) * _rng.randf_range(0.6, 1.2) + Vector3(0, _rng.randf_range(0.15, 0.4), 0)
		_spawn(head, v, _rng.randf_range(1.8, 2.8), Vector2(0.08, _rng.randf_range(0.35, 0.6)), 0.34)


## A smoke ring: twelve puffs in a circle moving out together, the ring widening as it goes.
func _puff_ring(head: Vector3, dir: Vector3) -> void:
	var side := dir.cross(Vector3.UP).normalized()
	for k in 12:
		var a := TAU * k / 12.0
		var off := (side * cos(a) + Vector3.UP * sin(a)) * 0.08
		_spawn(head + off, dir * 0.9 + off * 3.0, 2.6, Vector2(0.07, 0.2), 0.5)


## The head of person i (room-local).
func _seat_head(i: int) -> Vector3:
	return (_seats[i][0] as Vector3) + Vector3(0, 1.6, 0)


func _pose_people() -> void:
	var dm := _people.multimesh
	for i in mini(6, _seats.size()):
		var p: Vector3 = _seats[i][0]
		var y: float = _seats[i][1]
		var talking := i < people.size() and String(people[i][0]) == _speaker and _speaker != ""
		var bob := 0.03 * absf(sin(_clock * 7.0)) if talking else 0.0
		if i == 4:
			# The waiter goes between the bar and our table.
			var t := 0.5 - 0.5 * cos(_clock * 0.25)
			p = Vector3(-6.2, 0, 1.6).lerp(OURS + Vector3(-1.6, 0, 1.4), t) if area == "sala" else Vector3(-6.2, 0, 1.6)
			y = atan2(OURS.x - -6.2, OURS.z - 1.6) if sin(_clock * 0.25) > 0.0 else atan2(-6.2 - OURS.x, 1.6 - OURS.z)
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, y + (sin(_clock * 0.7 + i) * 0.08 if i < 3 else 0.0)), p + Vector3(0, bob, 0)))


func _pose_lights() -> void:
	var mm := _lights.multimesh
	var pose := light_pose(area == "taras", _clock)
	for i in mini(pose.size(), mm.instance_count):
		mm.set_instance_transform(i, pose[i][0])
		mm.set_instance_color(i, pose[i][1])


# --- taps -------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not inside or cam == null:
		return
	var at := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			leave()
		elif event.keycode == KEY_SPACE:
			_on_act()
		return
	if at == Vector2.INF:
		return
	var who := pick(at)
	if who >= 0:
		tap(String(people[who][0]))
		get_viewport().set_input_as_handled()


## The person under screen point `at`: the nearest within TAP_R m of the ray at chest height.
func pick(at: Vector2) -> int:
	var vp := cam.get_viewport()
	var scale := Vector2(vp.get_visible_rect().size) / get_viewport().get_visible_rect().size
	var p := at * scale
	var from := cam.project_ray_origin(p)
	var dir := cam.project_ray_normal(p)
	var best := -1
	var best_d := TAP_R
	for i in people.size():
		var c: Vector3 = PLACE + (people[i][1] as Vector3) + Vector3(0, 1.0, 0)
		var d := (from + dir * (c - from).dot(dir)).distance_to(c)
		if d < best_d:
			best_d = d
			best = i
	return best


## A tap on someone: one of their lines (data/shisha.json "taps"; you and Ivan/Bogdan too).
func tap(name: String) -> void:
	var taps: Dictionary = _data.get("taps", {})
	var key := name
	if key == "Ty":
		key = "Ivan"
	var rows: Array = taps.get(key, [])
	if rows.is_empty():
		return
	var row: Array = rows[_rng.randi() % rows.size()]
	_say(name if name != "Ty" else key, String(row[0]), String(row[1]))
	_line_t = LINE_S


func _log(text: String) -> void:
	if log_on:
		print("lounge: " + text)
