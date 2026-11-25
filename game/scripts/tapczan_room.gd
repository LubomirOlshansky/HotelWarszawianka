extends Node3D
## Inside THE TAPCZAN (F's ask 2026-11-24, docs/design/tapczan-pub.md): a cutaway room in the
## city's isometric look, like Smoła's (club.gd): the walls on two sides, a dark void round it,
## the camera off the car (main.gd `_update_camera` asks `view`), the HUD aside, the car waiting
## at the kerb (tapczan.gd does both).
##
## The room (ROOM m, far off the map at PLACE), from the real pub's photos (refs/tapczan-interior,
## gitignored): the CURVED bar on the back wall with its copper-and-wood top over a front of rubble
## stone piers and dark slate panels, two long chrome tap pipes on it (arched ends, a coloured handle
## per tap, glowing amber glasses on top), the row of amber glass lamps and the lit bottle shelves on
## the brick behind, the black soffit over the bar following its curve with the numbered chalk tap
## list, black leather stools on wooden legs; exposed red brick with the round porthole; the grey
## concrete wall with BREW ENJOY EMPTY REPEAT (the first letters spell BEER, lit white); the steel
## mezzanine over the right end with its cable railing and the arched way out under it; the black
## ceiling's edge with the silver ducts; dark slate tiles; square wooden tables with wooden chairs,
## the regulars on them (one MultiMesh); the beer pong table at the front right with tonight's
## rivals. The craft-beer memes hang as chalkboards (data/tapczan.json "memes"; a tap reads one).
##
## The panel: WYPIJ PIWKO (the TAP LIST: six beers on tap, each with its style, ABV, glass and
## price; the price goes on the bill and out of the wallet, the barman answers the pick and the
## first sip has its line; a stronger beer makes the drive after it more tipsy (tapczan.gd), short
## of money is a refusal), ZAGRAJ (the rival card, then beer pong, beer_pong.gd), WYJDŹ. The bill
## of the visit and the wallet stand under the title.
##
## Cost: two draw calls (the room's mesh with every board's chalk in it, the people), the city out
## of view; under 30k triangles (pixel text merged into runs), built once on the first visit. No
## lights of its own: the glows are the actor shader's lit parts. The pong view is 2D on top.

const Models := preload("res://scripts/models.gd")
const UiKit := preload("res://scripts/ui_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const BeerPong := preload("res://scripts/beer_pong.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const DATA := "res://data/tapczan.json"
## Where the room stands: far past the map's edge, away from the club (9000, 9000) and the lounge.
const PLACE := Vector3(9000.0, 0.0, -9000.0)
const ROOM := Vector2(16.0, 11.0)
const WALL_H := 5.0
const VIEW := 16.0
const YAW := 45.0
const TAP_R := 1.4
## The rivals in the order of the card's buttons (data "rivals").
const RIVALS := ["sommelier", "office", "first"]
## How many glasses the bar pours in one visit before it says enough.
const MAX_PINTS := 4
## A beer's strength in "drinks" for the tipsy spell: ABV / this (a 5 % pint is one drink).
const ABV_DRINK := 5.0
## The barman's answer, then the first sip's line this many seconds later.
const SIP_S := 2.4
const AMBER := UiKit.HEAT
## The bar's curve: the circle's centre (room-local x, z), the front's radius, the half angle.
const BAR_C := Vector2(-3.0, -10.5)
const BAR_R := 7.6
const BAR_A := 0.62
## The square tables (room-local x, z); four chairs each.
const TABLES := [Vector2(-5.0, 0.9), Vector2(-2.3, 0.9), Vector2(0.4, 0.9), Vector2(-5.0, 3.7), Vector2(-2.3, 3.7), Vector2(0.6, 4.0)]
## Who sits where among the regulars to tap: [table, chair] (chairs: 0 -x, 1 +x, 2 -z, 3 +z).
const TAGGED := {"beard": [0, 1], "students": [1, 2], "tourists": [4, 1], "couple": [3, 3]}
## The mezzanine over the right end of the back wall: x from, x to, its depth from the wall, floor y.
const MEZZ := [1.8, 8.0, 2.9, 2.9]
## The pong table (room-local), along x.
const PONG := Vector3(4.8, 0.0, 3.2)

signal left
## A glass was poured (tapczan.gd: the drive after it): its strength in drinks (0 for the zero).
signal drank(drinks: float)
## A pong game ended: won, the stake paid, the drinks it cost.
signal pong_over(won: bool, stake: int, drinks: int)

var hud: CanvasLayer
var wallet: Node
## The sound (sfx.gd, from tapczan.gd): the pour and the clink here, the ball in the pong view. Null in checks.
var sfx: Node
var cam: Camera3D
var log_on := false
## A test run: the pong plays itself, the rival is the first on the card.
var auto_play := false
## A test run's rival (--tapczan=pong:ID; "" for the first on the card).
var auto_rival := ""
## --nohud: the room without its panel (shots).
var panel_off := false

var inside := false
## The view's aim: up and towards the back so the tall walls and the mezzanine fit over the panel.
var centre := PLACE + Vector3(-0.6, 2.4, -0.8)
var view_size := VIEW
var yaw := YAW
var pints := 0
## The visit's bill (zł): every glass's price.
var bill := 0
## [name [pl, en], data key, room-local position]: people to tap ("r:" rivals) and boards ("m:").
var people: Array = []

static var _data: Dictionary = {}

var _built := false
var _room: MeshInstance3D
var _crowd: MultiMeshInstance3D
var _ui: CanvasLayer
var _title: Label
var _bill: Label
var _talk: PanelContainer
var _who: Label
var _line: Label
var _buttons: HBoxContainer
var _drink_btn: Button
var _play_btn: Button
var _out_btn: Button
var _pick: PanelContainer
var _taps: PanelContainer
var _pong: Control
var _rng := RandomNumberGenerator.new()
## The regulars' seats: (x, yaw, z), room-local.
var _seat: Array[Vector3] = []
var _clock := 0.0
var _anim_t := 0.0
var _sip_gen := 0


## The words (data/tapczan.json), read once.
static func data() -> Dictionary:
	if _data.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data


## One UI pair [pl, en] by key ("ui" group).
static func pair(key: String) -> Array:
	return (data().get("ui", {}) as Dictionary).get(key, [key, key])


## One UI line in the player's language, `args` formatted in.
static func say(key: String, args: Array = []) -> String:
	var p := pair(key)
	var s := Lang.pick(str(p[0]), str(p[1]))
	return s % args if not args.is_empty() else s


static func rival(id: String) -> Dictionary:
	return (data().get("rivals", {}) as Dictionary).get(id, {})


## The beers on tap (data "taps"), in the list's order.
static func taps() -> Array:
	return data().get("taps", [])


static func tap(id: String) -> Dictionary:
	for t: Dictionary in taps():
		if str(t.get("id", "")) == id:
			return t
	return {}


## A beer's strength for the tipsy spell (drinks).
static func strength(t: Dictionary) -> float:
	return float(t.get("abv", 0.0)) / ABV_DRINK


## "6,5%" in Polish, "6.5%" in English; "0,4 l" / "0.4 l".
static func num(v: float, pl: bool) -> String:
	var s := ("%.1f" % v)
	return s.replace(".", ",") if pl else s


## One tap's button: name · price, then style · ABV · glass.
static func tap_label(t: Dictionary, pl: bool) -> String:
	var nm: Array = t.get("name", ["", ""])
	var st: Array = t.get("style", ["", ""])
	var p := pair("tap_btn")
	return str(p[0 if pl else 1]) % [str(nm[0 if pl else 1]), int(t.get("price", 0)),
		str(st[0 if pl else 1]), num(float(t.get("abv", 0.0)), pl) + "%", num(int(t.get("ml", 0)) / 1000.0, pl) + " l"]


# --- the room -------------------------------------------------------------------------------

## A box turned `turn` rad about the vertical (its local +z towards (sin, 0, cos)), centred at `c`.
static func _rbox(st: SurfaceTool, c: Vector3, size: Vector3, turn: float, colour: Color, part := Models.FIXED) -> void:
	var b := Basis(Vector3.UP, turn)
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var f := n * h[axis]
			var q := [b * (f - u - v), b * (f + u - v), b * (f + u + v), b * (f - u + v)]
			var wn := b * n
			if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(wn) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(wn)
				st.set_uv(Vector2(part, 0.0))
				st.add_vertex(c + q[k])


## A point on the bar's circle at radius `r`, angle `a` (0: straight out from the back wall), height y.
static func _arc(r: float, a: float, y := 0.0) -> Vector3:
	return Vector3(BAR_C.x + sin(a) * r, y, BAR_C.y + cos(a) * r)


## Pixel-font text as merged runs (one quad per run of lit pixels in a row, not one per pixel):
## the cell's top left at `origin`, along `right` and `down` (unit), `px` m a pixel, facing the
## reader (pixel_font.gd add_quads' rule).
static func _text(st: SurfaceTool, text: String, origin: Vector3, right: Vector3, down: Vector3, px: float, colour: Color, part := Models.LIT_SIGN) -> void:
	var rows := {}
	PixelFont.each_pixel(text, 0, func(x: int, row: int) -> void:
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(x))
	var n := down.cross(right).normalized()
	for row: int in rows:
		var xs: Array = rows[row]
		xs.sort()
		var i := 0
		while i < xs.size():
			var j := i
			while j + 1 < xs.size() and int(xs[j + 1]) == int(xs[j]) + 1:
				j += 1
			var a := origin + right * (int(xs[i]) * px) + down * (row * px) + n * 0.012
			var w := right * ((int(xs[j]) - int(xs[i]) + 1) * px)
			var q := [a, a + w, a + w + down * px, a + down * px]
			if ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(n)
				st.set_uv(Vector2(part, 0.0))
				st.add_vertex(q[k])
			i = j + 1


## Lines of text centred on `mid` (the block's middle), along `right`, lines going down.
static func _lines(st: SurfaceTool, lines: Array, mid: Vector3, right: Vector3, px: float, colour: Color) -> void:
	var down := Vector3.DOWN
	var tall := (lines.size() * PixelFont.LINE - (PixelFont.LINE - PixelFont.ROWS)) * px
	for i in lines.size():
		var t := str(lines[i])
		var w := PixelFont.width(t) * px
		var o := mid - right * (w * 0.5) + Vector3.UP * (tall * 0.5) + down * (i * PixelFont.LINE * px)
		_text(st, t, o, right, down, px, colour)


## The meme boards (data "memes" but the wall's words): [id, centre, facing turn, width, height].
static func meme_boards() -> Array:
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	return [
		["drugie", Vector3(3.6, 1.95, -hz + 0.06), 0.0, 1.7, 1.0],
		["cena", Vector3(-hx + 0.06, 1.9, -1.0), PI * 0.5, 1.5, 0.95],
		["chmiel", Vector3(-hx + 0.06, 2.15, -3.0), PI * 0.5, 1.1, 1.0],
		["metne", Vector3(-1.0, 2.05, -hz + 0.06), 0.0, 1.5, 0.95],
		["jasne", Vector3(5.6, 1.95, -hz + 0.06), 0.0, 1.7, 1.0],
	]


## The room's static mesh (room-local: the floor's middle at the origin, the back wall at -Z, the
## left wall at -X, open towards the camera at +X and +Z).
static func room_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var brick := Color("#8a432e")
	var brick_d := Color("#6a3324")
	var brick_l := Color("#a8583a")
	var mortar := Color("#9a6a54")
	var black := Color("#161618")
	var steel := Color("#26272a")
	var chrome := Color("#d0d4d8")
	var amber := Color("#f4b44c")
	var warm := Color("#ffd08a")
	var chalk := Color("#e2ded2")
	var board := Color("#22272a")
	var wood := Color("#b07a44")
	var wood_d := Color("#6e4a2a")
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	# The void and the floor: big dark slate tiles (photo 1).
	Models.box(st, Vector3(0, -0.6, 0), Vector3(400, 1.0, 400), Color("#050304"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(ROOM.x, 0.2, ROOM.y), Color("#3a3f44"), Models.FIXED)
	for i in 13:
		Models.box(st, Vector3(-hx + 1.2 + i * 1.2, 0.005, 0), Vector3(0.025, 0.01, ROOM.y), Color("#2a2e32"), Models.FIXED)
	for i in 18:
		Models.box(st, Vector3(0, 0.005, -hz + 0.6 + i * 0.6), Vector3(ROOM.x, 0.01, 0.025), Color("#2a2e32"), Models.FIXED)
	# The walls: the back wall red brick, the left wall brick to z 0.4, then the grey concrete panel.
	var split := 0.4
	Models.box(st, Vector3(0, WALL_H * 0.5, -hz - 0.2), Vector3(ROOM.x + 0.8, WALL_H, 0.4), brick, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.2, WALL_H * 0.5, (-hz + split) * 0.5), Vector3(0.4, WALL_H, split + hz), brick, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.2, WALL_H * 0.5, (split + hz) * 0.5), Vector3(0.4, WALL_H, hz - split), Color("#8e8d88"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.03, WALL_H * 0.5, split), Vector3(0.08, WALL_H, 0.12), black, Models.FIXED)
	for row in 17:
		var y := 0.25 + row * 0.27
		Models.box(st, Vector3(0, y, -hz + 0.005), Vector3(ROOM.x, 0.025, 0.01), mortar, Models.FIXED)
		Models.box(st, Vector3(-hx + 0.005, y, (-hz + split) * 0.5), Vector3(0.01, 0.025, split + hz), mortar, Models.FIXED)
		for k in 4:
			var bx := rng.randf_range(-hx + 0.3, hx - 0.3)
			Models.box(st, Vector3(bx, y + 0.135, -hz + 0.01), Vector3(0.25, 0.24, 0.01), brick_d if k % 2 else brick_l, Models.FIXED)
			var bz := rng.randf_range(-hz + 0.3, split - 0.3)
			Models.box(st, Vector3(-hx + 0.01, y + 0.135, bz), Vector3(0.01, 0.24, 0.25), brick_d if k % 2 else brick_l, Models.FIXED)
	# The black ceiling's edge along both walls and the silver ducts under it (the cutaway's top).
	Models.box(st, Vector3(0, WALL_H - 0.1, -hz + 0.6), Vector3(ROOM.x, 0.2, 1.2), black, Models.FIXED)
	Models.box(st, Vector3(-hx + 0.6, WALL_H - 0.1, 0), Vector3(1.2, 0.2, ROOM.y), black, Models.FIXED)
	Models.box(st, Vector3(0, WALL_H - 0.5, -hz + 0.55), Vector3(ROOM.x, 0.45, 0.45), Color("#9ea4a8"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.55, WALL_H - 0.5, 0), Vector3(0.45, 0.45, ROOM.y), Color("#9ea4a8"), Models.FIXED)
	for i in 15:
		Models.box(st, Vector3(-hx + 1.0 + i * 1.0, WALL_H - 0.5, -hz + 0.55), Vector3(0.04, 0.47, 0.47), Color("#6e7478"), Models.FIXED)
	for i in 10:
		Models.box(st, Vector3(-hx + 0.55, WALL_H - 0.5, -hz + 1.0 + i * 1.0), Vector3(0.47, 0.47, 0.04), Color("#6e7478"), Models.FIXED)
	# Behind the bar on the brick: the lit bottle shelves, and over them the row of glowing amber
	# beer-glass lamps on a ledge (photo 1, left).
	var bottles := [Color("#3a6a3a"), Color("#c9b48a"), Color("#6a3a1e"), Color("#e8e4d8"), Color("#2a4a6a")]
	for k in 2:
		Models.box(st, Vector3(-3.4, 1.45 + k * 0.45, -hz + 0.18), Vector3(8.0, 0.04, 0.3), Color("#cfe6ea"), Models.LIT_WINDOW)
		for j in 24:
			Models.box(st, Vector3(-7.1 + j * 0.32, 1.62 + k * 0.45, -hz + 0.18), Vector3(0.08, 0.3, 0.08), bottles[(j + k) % 5], Models.FIXED)
	Models.box(st, Vector3(-3.4, 2.55, -hz + 0.12), Vector3(8.2, 0.05, 0.22), steel, Models.FIXED)
	for j in 18:
		Models.box(st, Vector3(-7.2 + j * 0.45, 2.69, -hz + 0.14), Vector3(0.2, 0.22, 0.16), amber, Models.LIT_SIGN)
	# The curved bar: per segment a dark slate panel between rubble stone piers, a course of stones
	# under the top, the copper-edged wooden top, the steel back counter, the chrome footrest.
	var segs := 14
	var da := 2.0 * BAR_A / segs
	var chord := BAR_R * da
	var stones := [Color("#a4a6a2"), Color("#8c8e8a"), Color("#b8b9b4"), Color("#7c7e7a")]
	for s in segs:
		var a := -BAR_A + (s + 0.5) * da
		_rbox(st, _arc(BAR_R - 0.35, a, 0.5), Vector3(chord + 0.02, 1.0, 0.7), a, Color("#2c3034"))
		_rbox(st, _arc(BAR_R - 0.33, a, 1.12), Vector3(chord * 1.04, 0.07, 1.0), a, Color("#a65a2e"))
		_rbox(st, _arc(BAR_R + 0.17, a, 1.105), Vector3(chord * 1.04, 0.05, 0.03), a, Color("#d08a4a"))
		_rbox(st, _arc(BAR_R - 1.0, a, 0.95), Vector3(chord + 0.02, 0.1, 0.4), a, steel)
		_rbox(st, _arc(BAR_R + 0.28, a, 0.22), Vector3(chord + 0.02, 0.05, 0.05), a, chrome)
		for k in 2:
			_rbox(st, _arc(BAR_R + 0.02, a + (k - 0.5) * da * 0.5, 0.97), Vector3(chord * 0.48, 0.17, 0.08), a, stones[(s + k) % 4])
	for s in segs + 1:
		var a := -BAR_A + s * da
		for k in 4:
			var w := 0.26 + 0.06 * float((s + k) % 3)
			_rbox(st, _arc(BAR_R + 0.03, a + 0.006 * float(k % 2 * 2 - 1), 0.12 + k * 0.21), Vector3(w, 0.19, 0.1), a, stones[(s + k * 3) % 4])
	# The tap towers: two long chrome pipes along the bar with arched ends, a black spout and a
	# coloured handle per tap (the TAP LIST's colours, data "taps"), glowing amber glasses on top.
	var handles: Array = []
	for t: Dictionary in taps():
		handles.append(Color(str(t.get("handle", "#202020"))))
	if handles.is_empty():
		handles.append(Color("#202020"))
	var r_tap := BAR_R - 0.55
	var hcount := 0
	for span: Array in [[-0.5, -0.08], [0.08, 0.5]]:
		var a0 := float(span[0])
		var a1 := float(span[1])
		var n := 6
		var d := (a1 - a0) / n
		for k in n:
			var a := a0 + (k + 0.5) * d
			_rbox(st, _arc(r_tap, a, 1.78), Vector3(r_tap * d + 0.04, 0.1, 0.1), a, chrome)
			_rbox(st, _arc(r_tap, a, 1.93), Vector3(0.15, 0.2, 0.15), a, amber, Models.LIT_SIGN)
			_rbox(st, _arc(r_tap + 0.06, a, 1.66), Vector3(0.04, 0.14, 0.04), a, black)
			_rbox(st, _arc(r_tap + 0.06, a, 1.92), Vector3(0.05, 0.22, 0.05), a, handles[hcount % handles.size()])
			hcount += 1
		for e in [a0, a1]:
			var out := -1.0 if e == a0 else 1.0
			_rbox(st, _arc(r_tap, e + out * 0.012, 1.74), Vector3(0.12, 0.12, 0.1), e, chrome)
			_rbox(st, _arc(r_tap, e + out * 0.02, 1.43), Vector3(0.1, 0.6, 0.1), e, chrome)
	# A black column through the bar to the soffit (photo 4), cage lamps under the soffit.
	_rbox(st, _arc(BAR_R - 1.4, 0.0, 1.55), Vector3(0.26, 3.1, 0.26), 0.0, black)
	# The black soffit over the bar following its curve, the numbered chalk tap list on its face:
	# five boards, two taps each (the six on tap and four more); the numbers and prices in chalk.
	for s in segs:
		var a := -BAR_A + (s + 0.5) * da
		_rbox(st, _arc(BAR_R - 1.2, a, 3.55), Vector3((BAR_R - 1.2) * da + 0.06, 0.9, 1.4), a, black)
		_rbox(st, _arc(BAR_R - 0.6, a, 3.04), Vector3(0.16, 0.1, 0.16), a, warm, Models.LIT_SIGN)
	var list: Array = []
	for t: Dictionary in taps():
		list.append([int(t.get("no", 0)), str((t.get("name", ["", ""]) as Array)[0]).split(" ")[0].replace(",", ""), int(t.get("price", 0))])
	list.append_array([[2, "PILS", 18], [5, "PSZENKA", 19], [10, "PORTER", 22], [14, "GOSE", 24]])
	list.sort_custom(func(x: Array, y: Array) -> bool: return int(x[0]) < int(y[0]))
	var r_b := BAR_R - 0.48
	for b in 5:
		var a := -0.5 + b * 0.25
		var right := Vector3(cos(a), 0, -sin(a))
		var c := _arc(r_b, a, 3.55)
		_rbox(st, c, Vector3(1.75, 0.76, 0.03), a, board)
		for k in 2:
			var i := b * 2 + k
			if i >= list.size():
				continue
			var e: Array = list[i]
			var line := "%d %s %d" % [int(e[0]), str(e[1]), int(e[2])]
			var px := minf(0.028, 1.6 / maxf(1.0, PixelFont.width(line)))
			var w := PixelFont.width(line) * px
			var o := c + Vector3(0, 0.33 - k * 0.36, 0) - right * (w * 0.5) + Vector3(sin(a), 0, cos(a)) * 0.016
			_text(st, line, o, right, Vector3.DOWN, px, chalk)
	# The stools along the bar: black leather seats on wooden legs with a footring (photo 1).
	var n_st := 10
	for k in n_st:
		var a := -BAR_A + 0.08 + k * (2.0 * BAR_A - 0.16) / (n_st - 1)
		var c := _arc(BAR_R + 0.6, a)
		_rbox(st, c + Vector3(0, 0.78, 0), Vector3(0.42, 0.1, 0.42), a, black)
		for lx in [-0.15, 0.15]:
			for lz in [-0.15, 0.15]:
				var off := Basis(Vector3.UP, a) * Vector3(lx, 0, lz)
				_rbox(st, c + off + Vector3(0, 0.37, 0), Vector3(0.045, 0.74, 0.045), a, wood)
		_rbox(st, c + Vector3(0, 0.3, 0), Vector3(0.36, 0.03, 0.36), a, wood_d)
	# The porthole high on the left wall's brick (the round iron window), a meme or two below.
	for k in 16:
		var a := TAU * k / 16.0
		Models.box(st, Vector3(-hx + 0.04, 3.6 + sin(a) * 0.5, -1.2 + cos(a) * 0.5), Vector3(0.06, 0.17, 0.17), Color("#2b2c2e"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.02, 3.6, -1.2), Vector3(0.03, 0.72, 0.72), Color("#9fb8c8"), Models.LIT_WINDOW)
	Models.box(st, Vector3(-hx + 0.05, 3.6, -1.2), Vector3(0.03, 0.74, 0.05), Color("#2b2c2e"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.05, 3.6, -1.2), Vector3(0.03, 0.05, 0.74), Color("#2b2c2e"), Models.FIXED)
	# BREW ENJOY EMPTY REPEAT on the concrete (photo 2): black letters, the first of each line white
	# (they spell BEER downwards).
	# Read from the room (+x), the words run towards -z from near the open front.
	var wpx := 0.085
	var wtop := 3.5
	var wz := hz - 0.5
	var along := Vector3(0, 0, -1)
	for i in 4:
		var word := str(["BREW", "ENJOY", "EMPTY", "REPEAT"][i])
		var o := Vector3(-hx + 0.01, wtop - i * PixelFont.LINE * wpx + PixelFont.BODY * wpx, wz)
		var head := word.substr(0, 1)
		_text(st, head, o, along, Vector3.DOWN, wpx, Color("#f2f0ea"), Models.FIXED)
		var shift := (PixelFont.char_width(head) + PixelFont.GAP) * wpx
		_text(st, word.substr(1), o + along * shift, along, Vector3.DOWN, wpx, Color("#141414"), Models.FIXED)
	# The meme chalkboards (data "memes"): a wooden frame, the board, the chalk.
	var memes := {}
	for m: Dictionary in data().get("memes", []):
		memes[str(m.get("id", ""))] = m
	for mb: Array in meme_boards():
		var m: Dictionary = memes.get(str(mb[0]), {})
		if m.is_empty():
			continue
		var c: Vector3 = mb[1]
		var turn := float(mb[2])
		var w := float(mb[3])
		var h := float(mb[4])
		_rbox(st, c, Vector3(w + 0.1, h + 0.1, 0.04), turn, wood_d)
		var nrm := Vector3(sin(turn), 0, cos(turn))
		_rbox(st, c + nrm * 0.02, Vector3(w, h, 0.03), turn, board)
		var lines: Array = m.get("world", [])
		var widest := 1
		for l: String in lines:
			widest = maxi(widest, PixelFont.width(l))
		var px := minf((w - 0.16) / widest, (h - 0.14) / (lines.size() * PixelFont.LINE))
		_lines(st, lines, c + nrm * 0.035, Vector3(cos(turn), 0, -sin(turn)), px, chalk)
	# The mezzanine over the right end of the back wall: the steel deck on posts, its fascia, the
	# railing of thin steel cables between black posts (photo 1), two regulars up there (people).
	var mx0 := float(MEZZ[0])
	var mx1 := float(MEZZ[1])
	var md := float(MEZZ[2])
	var my := float(MEZZ[3])
	var mz := -hz + md
	Models.box(st, Vector3((mx0 + mx1) * 0.5, my - 0.12, -hz + md * 0.5), Vector3(mx1 - mx0, 0.24, md), steel, Models.FIXED)
	Models.box(st, Vector3((mx0 + mx1) * 0.5, my - 0.2, mz), Vector3(mx1 - mx0, 0.4, 0.08), black, Models.FIXED)
	Models.box(st, Vector3(mx0, my - 0.2, -hz + md * 0.5), Vector3(0.08, 0.4, md), black, Models.FIXED)
	for px_ in [mx0 + 0.05, (mx0 + mx1) * 0.5, mx1 - 0.3]:
		Models.box(st, Vector3(px_, (my - 0.4) * 0.5, mz - 0.05), Vector3(0.14, my - 0.4, 0.14), black, Models.FIXED)
	var posts := int((mx1 - mx0) / 1.0)
	for k in posts + 1:
		Models.box(st, Vector3(mx0 + k * (mx1 - mx0) / posts, my + 0.5, mz), Vector3(0.05, 1.0, 0.05), black, Models.FIXED)
	for k in 3:
		Models.box(st, Vector3(mx0, my + 0.5, -hz + 0.2 + k * (md - 0.2) / 2.0), Vector3(0.05, 1.0, 0.05), black, Models.FIXED)
	Models.box(st, Vector3((mx0 + mx1) * 0.5, my + 1.0, mz), Vector3(mx1 - mx0, 0.05, 0.06), black, Models.FIXED)
	Models.box(st, Vector3(mx0, my + 1.0, -hz + md * 0.5), Vector3(0.06, 0.05, md), black, Models.FIXED)
	for k in 5:
		var cy := my + 0.15 + k * 0.17
		Models.box(st, Vector3((mx0 + mx1) * 0.5, cy, mz), Vector3(mx1 - mx0, 0.012, 0.012), Color("#b8bcc0"), Models.FIXED)
		Models.box(st, Vector3(mx0, cy, -hz + md * 0.5), Vector3(0.012, 0.012, md), Color("#b8bcc0"), Models.FIXED)
	# Under it: a high shelf along the brick with tall stools, and the arched way out with its
	# coloured glass and the green WYJŚCIE sign (photo 1, right).
	Models.box(st, Vector3(3.3, 1.05, -hz + 0.2), Vector3(2.8, 0.06, 0.4), wood, Models.FIXED)
	for k in 4:
		var c := Vector3(2.3 + k * 0.7, 0, -hz + 0.7)
		Models.box(st, c + Vector3(0, 0.75, 0), Vector3(0.36, 0.09, 0.36), black, Models.FIXED)
		Models.box(st, c + Vector3(0, 0.36, 0), Vector3(0.05, 0.72, 0.05), wood, Models.FIXED)
		Models.box(st, c + Vector3(0, 0.3, 0), Vector3(0.3, 0.03, 0.3), wood_d, Models.FIXED)
	var door_x := 7.0
	Models.box(st, Vector3(door_x, 1.05, -hz + 0.03), Vector3(1.2, 2.1, 0.06), Color("#2e2118"), Models.FIXED)
	for k in 5:
		var a := PI * (k + 0.5) / 5.0
		Models.box(st, Vector3(door_x + cos(a) * 0.45, 2.1 + sin(a) * 0.35, -hz + 0.03), Vector3(0.3, 0.3, 0.06), Color("#2e2118"), Models.FIXED)
	Models.box(st, Vector3(door_x, 1.55, -hz + 0.07), Vector3(0.5, 0.8, 0.02), Color("#c87a8a"), Models.LIT_WINDOW)
	Models.box(st, Vector3(door_x, 1.55, -hz + 0.08), Vector3(0.04, 0.8, 0.02), Color("#2b2c2e"), Models.FIXED)
	Models.box(st, Vector3(door_x, 2.62, -hz + 0.07), Vector3(1.0, 0.22, 0.04), Color("#3aff7a"), Models.LIT_SIGN)
	# The square tables (photo 2), four wooden chairs with dark seats each, pints and coasters.
	var coasters := [Color("#f2f0ea"), Color("#d8366a"), Color("#4f9a3a"), Color("#f2c14a")]
	for ti in TABLES.size():
		var t: Vector2 = TABLES[ti]
		var c := Vector3(t.x, 0, t.y)
		Models.box(st, c + Vector3(0, 0.76, 0), Vector3(0.9, 0.05, 0.9), wood, Models.FIXED)
		Models.box(st, c + Vector3(0, 0.37, 0), Vector3(0.1, 0.74, 0.1), black, Models.FIXED)
		Models.box(st, c + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), black, Models.FIXED)
		for k in 4:
			var ch := chair(ti, k)
			var cp := Vector3(ch.x, 0, ch.z)
			var back := Basis(Vector3.UP, ch.y) * Vector3(0, 0, 0.2)
			_rbox(st, cp + Vector3(0, 0.46, 0), Vector3(0.42, 0.05, 0.42), ch.y, Color("#1e1e22"))
			_rbox(st, cp + back + Vector3(0, 0.72, 0), Vector3(0.42, 0.4, 0.04), ch.y, Color("#1e1e22"))
			for lx in [-0.17, 0.17]:
				for lz in [-0.17, 0.17]:
					var off := Basis(Vector3.UP, ch.y) * Vector3(lx, 0, lz)
					_rbox(st, cp + off + Vector3(0, 0.22, 0), Vector3(0.04, 0.44, 0.04), ch.y, wood)
			var on := c + (cp - c) * 0.42
			Models.box(st, on + Vector3(0, 0.79, 0), Vector3(0.1, 0.008, 0.1), coasters[(ti + k) % 4], Models.FIXED)
			if (ti + k) % 3 != 0:
				Models.box(st, on + Vector3(0, 0.87, 0), Vector3(0.08, 0.16, 0.08), Color("#e8a83a") if k % 2 else Color("#2a1408"), Models.LIT_WINDOW if k % 2 else Models.FIXED)
		Models.box(st, c + Vector3(0, 0.83, 0), Vector3(0.06, 0.09, 0.06), warm, Models.LIT_SIGN)
		# A pendant lamp over each table.
		Models.box(st, c + Vector3(0, 3.7, 0), Vector3(0.015, 2.2, 0.015), black, Models.FIXED)
		Models.box(st, c + Vector3(0, 2.62, 0), Vector3(0.26, 0.12, 0.26), Color("#6a4a2a"), Models.FIXED)
		Models.box(st, c + Vector3(0, 2.53, 0), Vector3(0.24, 0.08, 0.24), warm, Models.LIT_SIGN)
	# The beer pong table: black top, white edge lines, a red triangle of cups at each end.
	var pt := PONG
	Models.box(st, pt + Vector3(0, 0.74, 0), Vector3(2.44, 0.05, 0.61), black, Models.FIXED)
	Models.box(st, pt + Vector3(0, 0.767, 0.29), Vector3(2.44, 0.006, 0.02), Color.WHITE, Models.FIXED)
	Models.box(st, pt + Vector3(0, 0.767, -0.29), Vector3(2.44, 0.006, 0.02), Color.WHITE, Models.FIXED)
	Models.box(st, pt + Vector3(0, 0.767, 0), Vector3(0.02, 0.006, 0.61), Color.WHITE, Models.FIXED)
	for s in [-1.0, 1.0]:
		for lz in [-0.25, 0.25]:
			Models.box(st, pt + Vector3(s * 1.1, 0.36, lz), Vector3(0.05, 0.72, 0.05), Color("#5a5a60"), Models.FIXED)
		var dz := 0.096 * 0.866
		for r in 3:
			for i in r + 1:
				var cx: float = s * (1.0 - r * dz)
				var cz := (i - r * 0.5) * 0.096
				Models.box(st, pt + Vector3(cx, 0.83, cz), Vector3(0.08, 0.12, 0.08), Color("#d4282e"), Models.FIXED)
				Models.box(st, pt + Vector3(cx, 0.892, cz), Vector3(0.082, 0.01, 0.082), Color("#f2f2ea"), Models.FIXED)
	return st.commit()


## Chair `k` of table `ti`: (x, yaw facing the table, z), room-local (0: -x side, 1: +x, 2: -z, 3: +z).
static func chair(ti: int, k: int) -> Vector3:
	var t: Vector2 = TABLES[ti]
	match k:
		0:
			return Vector3(t.x - 0.68, -PI * 0.5, t.y)
		1:
			return Vector3(t.x + 0.68, PI * 0.5, t.y)
		2:
			return Vector3(t.x, PI, t.y - 0.68)
		_:
			return Vector3(t.x, 0.0, t.y + 0.68)


func _build(world: Node3D) -> void:
	_built = true
	_rng.randomize()
	_room = MeshInstance3D.new()
	_room.name = "TapczanRoom"
	_room.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_room.mesh = room_mesh()
	_room.material_override = Models.material()
	_room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_room.position = PLACE
	world.add_child(_room)
	# The regulars on the chairs (lowered: their legs under the table), the ones to tap always there;
	# standing: the barman behind the bar, tonight's three rivals by the pong table, two up on the
	# mezzanine.
	var dmat := Models.material().duplicate() as ShaderMaterial
	dmat.set_shader_parameter("walk", 0.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = Models.person_mesh()
	var frng := RandomNumberGenerator.new()
	frng.seed = 4040
	var clothes := [Color("#3a5a7a"), Color("#7a3a3a"), Color("#2a2a2e"), Color("#c9a45a"), Color("#4a6a3a"), Color("#d8d2c4"), Color("#5a3a6a")]
	var tagged := {}
	for key: String in TAGGED:
		tagged[Vector2i(int(TAGGED[key][0]), int(TAGGED[key][1]))] = key
	var seat_of := {}
	for ti in TABLES.size():
		for k in 4:
			var tag: String = tagged.get(Vector2i(ti, k), "")
			if tag == "" and frng.randf() < 0.3:
				continue
			# The seated face the table (the chair's yaw: the person mesh looks down -z).
			var ch := chair(ti, k)
			_seat.append(Vector3(ch.x, ch.y, ch.z))
			if tag != "":
				seat_of[tag] = Vector3(ch.x, 0, ch.z)
	var hz := ROOM.y * 0.5
	var ppl: Dictionary = data().get("people", {})
	people = [[ppl["barman"]["name"], "barman", _arc(BAR_R - 1.0, -0.12) + Vector3(0, 0, -0.2)]]
	for key: String in ["beard", "students", "tourists", "couple"]:
		people.append([ppl[key]["name"], key, seat_of.get(key, Vector3.ZERO) - Vector3(0, 0.4, 0)])
	people.append([rival("sommelier").get("name", ["", ""]), "r:sommelier", PONG + Vector3(1.7, 0, -0.3)])
	people.append([rival("office").get("name", ["", ""]), "r:office", PONG + Vector3(1.7, 0, 0.5)])
	people.append([rival("first").get("name", ["", ""]), "r:first", PONG + Vector3(0.9, 0, 0.9)])
	for mb: Array in meme_boards():
		people.append([pair("board"), "m:" + str(mb[0]), (mb[1] as Vector3) - Vector3(0, 1.1, 0)])
	people.append([pair("board"), "m:wall", Vector3(-ROOM.x * 0.5 + 0.2, 1.6, 3.4)])
	# The standing: [position, yaw, colour].
	var stand: Array = [
		[people[0][2], PI, Color("#1a1a1e")],
		[people[5][2], PI * 0.5, Color("#5a1a2a")],
		[people[6][2], PI * 0.5, Color("#e8e8ee")],
		[people[7][2], PI * 0.5, Color("#c86aa8")],
		[Vector3(3.2, float(MEZZ[3]), -hz + 1.6), 0.4, Color("#3a6a8a")],
		[Vector3(3.8, float(MEZZ[3]), -hz + 1.4), -0.9, Color("#c9a45a")],
	]
	mm.instance_count = _seat.size() + stand.size()
	InstanceBuffers.whiten(mm)
	for i in _seat.size():
		mm.set_instance_custom_data(i, Color(clothes[frng.randi() % clothes.size()], 0.25))
	for i in stand.size():
		mm.set_instance_custom_data(_seat.size() + i, Color(stand[i][2], 0.25))
		mm.set_instance_transform(_seat.size() + i, Transform3D(Basis(Vector3.UP, float(stand[i][1])), stand[i][0]))
	_crowd = MultiMeshInstance3D.new()
	_crowd.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_crowd.multimesh = mm
	_crowd.material_override = dmat
	_crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_crowd.position = PLACE
	world.add_child(_crowd)
	_pose_crowd()
	_build_ui()


## The regulars at 6 Hz: a small lean and a lift of the glass now and then (one buffer write).
func _pose_crowd() -> void:
	var mm := _crowd.multimesh
	for i in _seat.size():
		var s := _seat[i]
		var nod := 0.04 * sin(_clock * 1.3 + i * 1.7)
		var lean := Basis(Vector3.UP, s.y) * Basis(Vector3.RIGHT, nod)
		mm.set_instance_transform(i, Transform3D(lean, Vector3(s.x, -0.36, s.z)))


func _build_ui() -> void:
	var pt: float = hud.pt if hud != null and "pt" in hud else 1.0
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiKit.card(pt, 10.0))
	top.position = Vector2(16, 16) * pt
	_ui.add_child(top)
	var tv := VBoxContainer.new()
	top.add_child(tv)
	_title = Label.new()
	UiKit.style_label(_title, "title", pt)
	tv.add_child(_title)
	_bill = Label.new()
	_bill.name = "Bill"
	UiKit.style_label(_bill, "sub", pt)
	_bill.add_theme_color_override("font_color", AMBER)
	tv.add_child(_bill)
	_talk = PanelContainer.new()
	_talk.add_theme_stylebox_override("panel", UiKit.card(pt, 10.0))
	_talk.custom_minimum_size = Vector2(360, 0) * pt
	_ui.add_child(_talk)
	var v := VBoxContainer.new()
	_talk.add_child(v)
	_who = Label.new()
	UiKit.style_label(_who, "sub", pt)
	_who.add_theme_color_override("font_color", AMBER)
	v.add_child(_who)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.x = 340 * pt
	UiKit.style_label(_line, "body", pt)
	v.add_child(_line)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", int(10 * pt))
	_ui.add_child(_buttons)
	_drink_btn = _button(_buttons, "drink", pt, true)
	_drink_btn.pressed.connect(drink)
	_play_btn = _button(_buttons, "play", pt, true)
	_play_btn.pressed.connect(_show_pick)
	_out_btn = _button(_buttons, "leave", pt, false)
	_out_btn.pressed.connect(leave)
	# The rival card: who to play, the stake on each button.
	_pick = PanelContainer.new()
	_pick.add_theme_stylebox_override("panel", UiKit.card(pt, 14.0))
	_ui.add_child(_pick)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", int(8 * pt))
	_pick.add_child(pv)
	var head := Label.new()
	UiKit.style_label(head, "title", pt)
	head.text = say("pick")
	head.name = "Head"
	pv.add_child(head)
	for id: String in RIVALS:
		var r := rival(id)
		var b := Button.new()
		var nm: Array = r.get("name", [id, id])
		b.text = say("stake_btn", [Lang.pick(str(nm[0]), str(nm[1])), int(r.get("stake", 0))])
		b.name = "R_" + id
		UiKit.style_button(b, UiKit.Kind.PRIMARY, pt)
		b.custom_minimum_size = Vector2(320, 48) * pt
		b.pressed.connect(play.bind(id))
		pv.add_child(b)
	var no := Button.new()
	no.text = say("back")
	UiKit.style_button(no, UiKit.Kind.SECONDARY, pt)
	no.custom_minimum_size = Vector2(320, 44) * pt
	no.pressed.connect(func() -> void: _pick.visible = false)
	pv.add_child(no)
	_pick.visible = false
	# The TAP LIST: the six on tap in two columns, name and price, style, ABV and glass.
	_taps = PanelContainer.new()
	_taps.name = "Taps"
	_taps.add_theme_stylebox_override("panel", UiKit.card(pt, 14.0))
	_ui.add_child(_taps)
	var tl := VBoxContainer.new()
	tl.add_theme_constant_override("separation", int(8 * pt))
	_taps.add_child(tl)
	var th := Label.new()
	UiKit.style_label(th, "title", pt)
	th.text = say("taps_head")
	tl.add_child(th)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(8 * pt))
	grid.add_theme_constant_override("v_separation", int(8 * pt))
	tl.add_child(grid)
	var pl := Lang.pick("pl", "en") == "pl"
	for t: Dictionary in taps():
		var b := Button.new()
		b.name = "T_" + str(t.get("id", ""))
		b.text = tap_label(t, pl)
		UiKit.style_button(b, UiKit.Kind.PRIMARY, pt, UiKit.T_LABEL)
		b.custom_minimum_size = Vector2(270, 54) * pt
		b.pressed.connect(order.bind(str(t.get("id", ""))))
		grid.add_child(b)
	var tno := Button.new()
	tno.text = say("back")
	UiKit.style_button(tno, UiKit.Kind.SECONDARY, pt)
	tno.custom_minimum_size = Vector2(250, 44) * pt
	tno.pressed.connect(func() -> void: _taps.visible = false)
	tl.add_child(tno)
	_taps.visible = false
	_layout()
	get_viewport().size_changed.connect(_layout)


func _button(parent: Node, key: String, pt: float, primary: bool) -> Button:
	var b := Button.new()
	b.text = say(key)
	UiKit.style_button(b, UiKit.Kind.PRIMARY if primary else UiKit.Kind.SECONDARY, pt)
	b.custom_minimum_size = Vector2(120, 52) * pt
	parent.add_child(b)
	return b


func _layout() -> void:
	if _ui == null:
		return
	var pt: float = hud.pt if hud != null and "pt" in hud else 1.0
	var vp := get_viewport().get_visible_rect().size
	_buttons.reset_size()
	_buttons.position = vp - _buttons.size - Vector2(16, 16) * pt
	# The line sits over the buttons (a long line widens it to the screen's width otherwise).
	_talk.size = Vector2(360 * pt, 0)
	_talk.reset_size()
	_talk.position = Vector2(16 * pt, _buttons.position.y - _talk.size.y - 10 * pt)
	_pick.reset_size()
	_pick.position = (vp - _pick.size) * 0.5
	_taps.reset_size()
	# Long names (English) or a big Mac window: the list shrinks to fit the screen, never runs off.
	var k := minf(1.0, minf(vp.x * 0.94 / maxf(_taps.size.x, 1.0), vp.y * 0.94 / maxf(_taps.size.y, 1.0)))
	_taps.scale = Vector2(k, k)
	_taps.position = (vp - _taps.size * k) * 0.5


# --- going in and out -----------------------------------------------------------------------

## In: the room built (once) under `world`, the panel up, the barman's hello.
func enter(world: Node3D) -> void:
	if not _built:
		_build(world)
	inside = true
	pints = 0
	bill = 0
	_title.text = say("title")
	_update_bill()
	_show(true)
	_say(people[0])
	_log("room in")
	if auto_play:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if inside:
				order("lager")
				play(auto_rival if auto_rival in RIVALS else RIVALS[0]))


func leave() -> void:
	if not inside:
		return
	if _pong != null and _pong.visible:
		return
	inside = false
	_show(false)
	_log("out (pints %d)" % pints)
	left.emit()


func _show(on: bool) -> void:
	_room.visible = on
	_crowd.visible = on
	_ui.visible = on and not panel_off
	_talk.visible = on and _line.text != ""
	_pick.visible = false
	_taps.visible = false
	_buttons.visible = on


## WYPIJ PIWKO: the TAP LIST (or the barman's "enough" once the visit had MAX_PINTS).
func drink() -> void:
	if not inside:
		return
	if pints >= MAX_PINTS:
		_say_text(people[0][0], pair("full"))
		return
	_pick.visible = false
	_taps.visible = true
	_layout()


## One beer from the list: its price out of the wallet and onto the bill, the barman's answer to
## the pick, the first sip's line SIP_S s later, and the drive after it as tipsy as the beer is
## strong. Short of money: a refusal, nothing poured. False when nothing was poured.
func order(id: String) -> bool:
	_taps.visible = false
	if not inside:
		return false
	var t := tap(id)
	if t.is_empty():
		return false
	if pints >= MAX_PINTS:
		_say_text(people[0][0], pair("full"))
		return false
	var price := int(t.get("price", 0))
	if wallet != null and not wallet.spend(price):
		var no: Array = data().get("refusals", [pair("broke")])
		_say_text(people[0][0], no[_rng.randi() % no.size()])
		_log("broke for %s (%d zl)" % [id, price])
		return false
	pints += 1
	bill += price
	_update_bill()
	_sound("beer_pour")
	var picks: Array = t.get("pick", [])
	if not picks.is_empty():
		_say_text(people[0][0], picks[_rng.randi() % picks.size()])
	var sips: Array = t.get("sip", [])
	_sip_gen += 1
	var gen := _sip_gen
	if not sips.is_empty() and is_inside_tree():
		var line: Array = sips[_rng.randi() % sips.size()]
		get_tree().create_timer(SIP_S).timeout.connect(func() -> void:
			if inside and gen == _sip_gen:
				_sound("glass_clink")
				_say_text(pair("sip"), line))
	_log("pour %s: %d zl, bill %d, wallet %d, strength %.2f" % [id, price, bill,
			int(wallet.get("zl")) if wallet != null else -1, strength(t)])
	drank.emit(strength(t))
	return true


## The bill line under the title: the visit's bill and what is left in the wallet.
func _update_bill() -> void:
	if _bill == null:
		return
	var zl := int(wallet.get("zl")) if wallet != null else 0
	_bill.text = say("bill", [bill, zl])


func _show_pick() -> void:
	_taps.visible = false
	_pick.visible = true
	_layout()


## The rival of the last pong game ("" before one).
func last_rival() -> String:
	return _pong.rival_id if _pong != null else ""


## ZAGRAJ against rival `id`: the pong view over the room.
func play(id: String) -> void:
	_pick.visible = false
	if _pong == null:
		_pong = BeerPong.new()
		_pong.name = "BeerPong"
		_pong.log_on = log_on
		var layer := CanvasLayer.new()
		layer.layer = 21
		add_child(layer)
		layer.add_child(_pong)
		_pong.finished.connect(_on_pong_finished)
		_pong.closed.connect(func() -> void:
			_buttons.visible = inside
			_talk.visible = inside and _line.text != "")
	_pong.auto_play = auto_play
	_pong.sound = _sound
	_pong.cue = func(n: String) -> void:
		if hud != null and hud.has_method("cue"):
			hud.cue(n)
		_log("cue " + n)
	_pong.pt =hud.pt if hud != null and "pt" in hud else 1.0
	_buttons.visible = false
	_talk.visible = false
	_pong.start(id, rival(id))
	_log("pong vs %s" % id)


func _on_pong_finished(won: bool, stake: int, drinks: int) -> void:
	var r: Dictionary = rival(_pong.rival_id)
	var lines: Array = r.get("win" if not won else "lose", [])
	if not lines.is_empty():
		_say_text(r.get("name", ["", ""]), lines[_rng.randi() % lines.size()])
	_log("pong over: %s, %d zl, %d drinks" % ["won" if won else "lost", stake, drinks])
	pong_over.emit(won, stake, drinks)
	_update_bill()
	if auto_play:
		get_tree().create_timer(2.5).timeout.connect(leave)


# --- the frame and taps ------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside:
		return
	_clock += dt
	_anim_t -= dt
	if _anim_t <= 0.0:
		_anim_t = 1.0 / 6.0
		_pose_crowd()


func _unhandled_input(event: InputEvent) -> void:
	if not inside or cam == null or (_pong != null and _pong.visible):
		return
	var at := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		leave()
		return
	if at == Vector2.INF:
		return
	var who := pick(at)
	if who >= 0:
		_say(people[who])
		get_viewport().set_input_as_handled()


## The person under screen point `at`: the nearest within TAP_R m of the ray at chest height, or -1.
func pick(at: Vector2) -> int:
	var vp := cam.get_viewport()
	var p := at * Vector2(vp.get_visible_rect().size) / get_viewport().get_visible_rect().size
	var from := cam.project_ray_origin(p)
	var dir := cam.project_ray_normal(p)
	var best := -1
	var best_d := TAP_R
	for i in people.size():
		var c: Vector3 = PLACE + (people[i][2] as Vector3) + Vector3(0, 1.1, 0)
		var d := (from + dir * (c - from).dot(dir)).distance_to(c)
		if d < best_d:
			best_d = d
			best = i
	return best


## A person's line: a regular's from "people", a rival's hello.
func _say(person: Array) -> void:
	var key := str(person[1])
	var lines: Array = []
	if key.begins_with("r:"):
		lines = rival(key.trim_prefix("r:")).get("hello", [])
	elif key.begins_with("m:"):
		for m: Dictionary in data().get("memes", []):
			if "m:" + str(m.get("id", "")) == key:
				lines = [m.get("say", ["", ""])]
	else:
		lines = (data().get("people", {}) as Dictionary).get(key, {}).get("lines", [])
	if lines.is_empty():
		return
	_say_text(person[0], lines[_rng.randi() % lines.size()])


func _say_text(name_pair: Array, line: Array) -> void:
	_who.text = Lang.pick(str(name_pair[0]), str(name_pair[1]))
	_line.text = Lang.pick(str(line[0]), str(line[1]))
	_talk.visible = inside and (_pong == null or not _pong.visible)
	_update_bill()
	_layout()


## One of the pub's one-shots (sfx.gd SHOTS): silent in the checks (no sfx), logged with --tapczan-log.
func _sound(n: String) -> void:
	if sfx != null:
		sfx.play(n)
	_log("sound " + n)


func _log(text: String) -> void:
	if log_on:
		print("tapczan: " + text)
