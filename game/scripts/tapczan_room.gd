extends Node3D
## Inside THE TAPCZAN (F's ask 2026-11-24, docs/design/tapczan-pub.md): a cutaway room in the
## city's isometric look, like Smoła's (club.gd): the walls on two sides, a dark void round it,
## the camera off the car (main.gd `_update_camera` asks `view`), the HUD aside, the car waiting
## at the kerb (tapczan.gd does both).
##
## The room (ROOM m, far off the map at PLACE): old brick walls, the bar along the back wall with
## two chrome tap towers with their glowing amber glasses, the black soffit with fifteen numbered
## chalk boards, a porthole window in the brick (from refs/tapczan-interior), warm pendant lamps over five long
## wooden tables with benches, the regulars sitting at them (one MultiMesh), the beer pong table at
## the front right with tonight's rivals standing by it, a window bay with the street's glow, the lit
## WYJŚCIE door. People to tap say a line (data/tapczan.json "people").
##
## The panel: WYPIJ PIWKO (a pint at the bar: its price, then tapczan.gd makes the drive after it
## tipsy), ZAGRAJ (the rival card: three rivals, each with a stake; then beer pong, beer_pong.gd),
## WYJDŹ (back to the car).
##
## Cost: three draw calls (the room's mesh, the people, the pong table's cups in the room mesh), the
## city out of view; about 9k triangles, built once on the first visit. The pong view is 2D on top.

const Models := preload("res://scripts/models.gd")
const UiKit := preload("res://scripts/ui_kit.gd")
const Lang := preload("res://scripts/lang.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const BeerPong := preload("res://scripts/beer_pong.gd")

const DATA := "res://data/tapczan.json"
## Where the room stands: far past the map's edge, away from the club (9000, 9000) and the lounge.
const PLACE := Vector3(9000.0, 0.0, -9000.0)
const ROOM := Vector2(16.0, 11.0)
const WALL_H := 4.2
const VIEW := 15.0
const YAW := 45.0
const TAP_R := 1.4
## The rivals in the order of the card's buttons (data "rivals").
const RIVALS := ["sommelier", "office", "first"]
## A pint's price (zł) and how many the bar pours before it says enough.
const PINT := 16
const MAX_PINTS := 4
const AMBER := UiKit.HEAT
## The tables: centre (room-local x, z) and length along x; the benches either side.
const TABLES := [[-4.6, -1.4, 3.6], [-4.6, 2.2, 3.6], [0.6, -1.4, 3.2], [0.6, 2.2, 3.2], [-1.8, 4.6, 3.0]]
## The pong table (room-local), along x.
const PONG := Vector3(4.8, 0.0, 3.2)

signal left
## A pint was poured (tapczan.gd: the drive after it).
signal drank
## A pong game ended: won, the stake paid, the drinks it cost.
signal pong_over(won: bool, stake: int, drinks: int)

var hud: CanvasLayer
var wallet: Node
var cam: Camera3D
var log_on := false
## A test run: the pong plays itself, the rival is the first on the card.
var auto_play := false

var inside := false
var centre := PLACE + Vector3(0, 1.0, 0)
var view_size := VIEW
var yaw := YAW
var pints := 0
## [name [pl, en], data key, room-local position].
var people: Array = []

static var _data: Dictionary = {}

var _built := false
var _room: MeshInstance3D
var _crowd: MultiMeshInstance3D
var _ui: CanvasLayer
var _title: Label
var _talk: PanelContainer
var _who: Label
var _line: Label
var _buttons: HBoxContainer
var _drink_btn: Button
var _play_btn: Button
var _out_btn: Button
var _pick: PanelContainer
var _pong: Control
var _rng := RandomNumberGenerator.new()
var _seat: Array[Vector3] = []
var _clock := 0.0
var _anim_t := 0.0


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


# --- the room -------------------------------------------------------------------------------

## The room's static mesh (room-local: the floor's middle at the origin, the back wall at -Z, the
## left wall at -X, open towards the camera at +X and +Z).
static func room_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var brick := Color("#7a3e2c")
	var brick_d := Color("#5e2e22")
	var mortar := Color("#8c5a48")
	var oak := Color("#a0703f")
	var oak_d := Color("#4a3222")
	var black := Color("#18181a")
	var warm := Color("#ffd08a")
	# The void, the floor: dark slate tiles (F's interior photos, refs/tapczan-interior).
	Models.box(st, Vector3(0, -0.6, 0), Vector3(400, 1.0, 400), Color("#050304"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(ROOM.x, 0.2, ROOM.y), Color("#33373b"), Models.FIXED)
	for i in 16:
		Models.box(st, Vector3(-hx + 1.0 + i * 1.0, 0.005, 0), Vector3(0.03, 0.01, ROOM.y), Color("#26292c"), Models.FIXED)
	for i in 10:
		Models.box(st, Vector3(0, 0.005, -hz + 1.0 + i * 1.0), Vector3(ROOM.x, 0.01, 0.03), Color("#26292c"), Models.FIXED)
	# The brick walls: courses in two reds, the mortar lines between.
	Models.box(st, Vector3(0, WALL_H * 0.5, -hz - 0.2), Vector3(ROOM.x + 0.8, WALL_H, 0.4), brick, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.2, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, ROOM.y), brick, Models.FIXED)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for row in 14:
		var y := 0.3 + row * 0.28
		Models.box(st, Vector3(0, y, -hz + 0.005), Vector3(ROOM.x, 0.025, 0.01), mortar, Models.FIXED)
		Models.box(st, Vector3(-hx + 0.005, y, 0), Vector3(0.01, 0.025, ROOM.y), mortar, Models.FIXED)
		for k in 6:
			var bx := rng.randf_range(-hx + 0.4, hx - 0.4)
			Models.box(st, Vector3(bx, y + 0.14, -hz + 0.01), Vector3(0.24, 0.24, 0.01), brick_d, Models.FIXED)
			var bz := rng.randf_range(-hz + 0.4, hz - 0.4)
			Models.box(st, Vector3(-hx + 0.01, y + 0.14, bz), Vector3(0.01, 0.24, 0.24), brick_d, Models.FIXED)
	# The bar along the back wall (the photos): a wooden top on a front of grey brick, a footrest,
	# two chrome T-towers with the glowing amber glasses on top (the pub's own look), the bottles on
	# lit shelves against the brick, a black column, and over it all the black soffit with fifteen
	# numbered chalk boards (the taps' list).
	var grey := Color("#7d7f80")
	var chrome := Color("#c8ccd0")
	var glass := Color("#f2b04a")
	Models.box(st, Vector3(-1.0, 0.55, -hz + 1.7), Vector3(9.0, 1.1, 0.7), Color("#55585a"), Models.FIXED)
	for row in 4:
		for k in 15:
			var bx := -5.3 + k * 0.6 + (0.3 if row % 2 else 0.0)
			if bx < 3.4:
				Models.box(st, Vector3(bx, 0.16 + row * 0.26, -hz + 2.06), Vector3(0.5, 0.2, 0.02), grey if (k + row) % 3 else grey.darkened(0.2), Models.FIXED)
	Models.box(st, Vector3(-1.0, 1.13, -hz + 1.75), Vector3(9.2, 0.07, 0.95), Color("#a0683a"), Models.FIXED)
	Models.box(st, Vector3(-1.0, 0.18, -hz + 2.25), Vector3(9.0, 0.05, 0.05), chrome, Models.FIXED)
	for tx: float in [-3.2, 1.2]:
		for side in [-1.0, 1.0]:
			Models.box(st, Vector3(tx + side * 1.1, 1.45, -hz + 1.6), Vector3(0.09, 0.6, 0.09), chrome, Models.FIXED)
		Models.box(st, Vector3(tx, 1.78, -hz + 1.6), Vector3(2.3, 0.1, 0.1), chrome, Models.FIXED)
		for k in 8:
			var gx := tx - 0.98 + k * 0.28
			Models.box(st, Vector3(gx, 1.93, -hz + 1.6), Vector3(0.16, 0.2, 0.16), glass, Models.LIT_SIGN)
			Models.box(st, Vector3(gx, 1.66, -hz + 1.72), Vector3(0.04, 0.14, 0.04), Color("#1a1a1c"), Models.FIXED)
	var bottles := [Color("#3a6a3a"), Color("#c9b48a"), Color("#6a3a1e"), Color("#e8e4d8"), Color("#2a4a6a")]
	for k in 2:
		Models.box(st, Vector3(-1.0, 1.6 + k * 0.5, -hz + 0.2), Vector3(8.0, 0.04, 0.3), Color("#cfe6ea"), Models.LIT_WINDOW)
		for j in 26:
			Models.box(st, Vector3(-4.8 + j * 0.3, 1.78 + k * 0.5, -hz + 0.2), Vector3(0.08, 0.3, 0.08), bottles[(j + k) % 5], Models.FIXED)
	Models.box(st, Vector3(-1.0, 1.4, -hz + 1.3), Vector3(0.24, 2.8, 0.24), black, Models.FIXED)
	Models.box(st, Vector3(-1.0, 3.3, -hz + 1.0), Vector3(9.4, 1.2, 2.0), Color("#1c1c1e"), Models.FIXED)
	for col in 3:
		for row in 5:
			var c := Vector3(-3.9 + col * 2.9, 3.78 - row * 0.22, -hz + 2.02)
			Models.box(st, c, Vector3(2.6, 0.19, 0.02), Color("#2a2e30"), Models.FIXED)
			Models.box(st, c + Vector3(-1.15, 0.0, 0.012), Vector3(0.1, 0.12, 0.01), Color("#e8e4d8"), Models.LIT_SIGN)
			Models.box(st, c + Vector3(-0.2 + 0.1 * (row % 2), 0.0, 0.012), Vector3(1.3 - 0.2 * ((row + col) % 3), 0.04, 0.01), Color("#e8e4d8"), Models.LIT_SIGN)
			Models.box(st, c + Vector3(1.0, 0.0, 0.012), Vector3(0.3, 0.05, 0.01), Color("#e8e4d8"), Models.LIT_SIGN)
	# The porthole in the left wall (the round iron window over the side door) and the stools at the bar.
	for k in 16:
		var a := TAU * k / 16.0
		Models.box(st, Vector3(-hx + 0.03, 3.0 + sin(a) * 0.5, 2.6 + cos(a) * 0.5), Vector3(0.05, 0.16, 0.16), Color("#2b2c2e"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.02, 3.0, 2.6), Vector3(0.03, 0.7, 0.7), Color("#9fb8c8"), Models.LIT_WINDOW)
	Models.box(st, Vector3(-hx + 0.04, 3.0, 2.6), Vector3(0.03, 0.72, 0.05), Color("#2b2c2e"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.04, 3.0, 2.6), Vector3(0.03, 0.05, 0.72), Color("#2b2c2e"), Models.FIXED)
	for k in 9:
		var sx := -4.8 + k * 0.95
		Models.box(st, Vector3(sx, 0.38, -hz + 2.75), Vector3(0.06, 0.76, 0.06), Color("#a0683a"), Models.FIXED)
		Models.box(st, Vector3(sx, 0.78, -hz + 2.75), Vector3(0.38, 0.08, 0.38), black, Models.FIXED)
		Models.box(st, Vector3(sx, 0.3, -hz + 2.75), Vector3(0.3, 0.03, 0.03), Color("#a0683a"), Models.FIXED)
	# The bottle-cap sign over the bar's right end (the street sign's gold ring).
	Models.box(st, Vector3(4.6, 2.6, -hz + 0.05), Vector3(1.4, 1.4, 0.06), black, Models.FIXED)
	for k in 16:
		var a := TAU * k / 16.0
		Models.box(st, Vector3(4.6 + cos(a) * 0.55, 2.6 + sin(a) * 0.55, -hz + 0.1), Vector3(0.14, 0.14, 0.03), Color(1.0, 0.8, 0.42), Models.LIT_SIGN)
	# The tables and benches, a candle on each.
	for t: Array in TABLES:
		var c := Vector3(float(t[0]), 0, float(t[1]))
		var ln := float(t[2])
		Models.box(st, c + Vector3(0, 0.76, 0), Vector3(ln, 0.06, 0.9), oak, Models.FIXED)
		for s in [-1.0, 1.0]:
			Models.box(st, c + Vector3(s * (ln * 0.5 - 0.25), 0.37, 0), Vector3(0.1, 0.74, 0.7), oak_d, Models.FIXED)
			Models.box(st, c + Vector3(0, 0.45, s * 0.75), Vector3(ln, 0.06, 0.32), oak, Models.FIXED)
			Models.box(st, c + Vector3(0, 0.22, s * 0.75), Vector3(ln - 0.3, 0.44, 0.06), oak_d, Models.FIXED)
		Models.box(st, c + Vector3(0, 0.84, 0), Vector3(0.07, 0.1, 0.07), warm, Models.LIT_SIGN)
		# Pints on the table.
		for k in 4:
			Models.box(st, c + Vector3(-ln * 0.35 + k * ln * 0.23, 0.87, 0.22 * (1 if k % 2 else -1)), Vector3(0.08, 0.16, 0.08), Color("#e8a83a"), Models.LIT_WINDOW)
	# The pendant lamps over the tables and the bar (warm, lit), their cords.
	for t: Array in TABLES:
		for s in [-0.25, 0.25]:
			var p := Vector3(float(t[0]) + s * float(t[2]), 0, float(t[1]))
			Models.box(st, p + Vector3(0, 3.3, 0), Vector3(0.015, 1.8, 0.015), black, Models.FIXED)
			Models.box(st, p + Vector3(0, 2.3, 0), Vector3(0.34, 0.2, 0.34), black, Models.FIXED)
			Models.box(st, p + Vector3(0, 2.17, 0), Vector3(0.22, 0.06, 0.22), warm, Models.LIT_SIGN)
	for i in 5:
		var p := Vector3(-4.6 + i * 1.8, 0, -hz + 1.6)
		Models.box(st, p + Vector3(0, 2.75, 0), Vector3(0.12, 0.14, 0.12), warm, Models.LIT_SIGN)
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
	# A neon "PONG" strip on the left wall's front for the corner, and the window bay at the front.
	Models.box(st, Vector3(-hx + 0.05, 2.7, hz - 1.2), Vector3(0.04, 0.9, 1.4), Color("#203040"), Models.LIT_WINDOW)
	Models.box(st, Vector3(-hx + 0.05, 1.3, hz - 1.2), Vector3(0.04, 1.6, 1.4), Color("#203040"), Models.LIT_WINDOW)
	# The way out: a door in the left wall, its green sign.
	Models.box(st, Vector3(-hx + 0.03, 1.1, hz - 3.4), Vector3(0.06, 2.2, 1.1), Color("#3a2a1e"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.07, 2.45, hz - 3.4), Vector3(0.04, 0.26, 1.0), Color("#3aff7a"), Models.LIT_SIGN)
	# Barrels in the back right corner, hops on the beams.
	for k in 3:
		var b := Vector3(hx - 0.8 - (k % 2) * 0.9, 0.45 + (k / 2) * 0.9, -hz + 0.8)
		Models.box(st, b, Vector3(0.8, 0.9, 0.8), Color("#7a5232"), Models.FIXED)
		Models.box(st, b + Vector3(0, 0.25, 0), Vector3(0.84, 0.06, 0.84), Color("#3a3a3e"), Models.FIXED)
		Models.box(st, b - Vector3(0, 0.25, 0), Vector3(0.84, 0.06, 0.84), Color("#3a3a3e"), Models.FIXED)
	# Hop garlands along the two walls' top (none across the room: they would hide the tables).
	for j in 18:
		Models.box(st, Vector3(-hx + 0.6 + j * 0.85, WALL_H - 0.35 - 0.12 * (j % 2), -hz + 0.25), Vector3(0.2, 0.26, 0.16), Color("#6f9a3a"), Models.FIXED)
	for j in 12:
		Models.box(st, Vector3(-hx + 0.25, WALL_H - 0.35 - 0.12 * (j % 2), -hz + 0.6 + j * 0.85), Vector3(0.16, 0.26, 0.2), Color("#6f9a3a"), Models.FIXED)
	return st.commit()


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
	# The regulars, sitting on the benches (lowered: their legs under the table), and the people to
	# tap standing: the barman, tonight's three rivals by the pong table.
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
	for t: Array in TABLES:
		var ln := float(t[2])
		for s in [-1.0, 1.0]:
			var n := int(ln / 0.9)
			for k in n:
				if frng.randf() < 0.25:
					continue
				_seat.append(Vector3(float(t[0]) - ln * 0.5 + 0.45 + k * 0.9, PI if s < 0.0 else 0.0, float(t[1]) + s * 0.75))
	var hz := ROOM.y * 0.5
	people = [
		[(data()["people"]["barman"]["name"]), "barman", Vector3(-1.0, 0, -hz + 0.9), Color("#1a1a1e")],
		[(data()["people"]["beard"]["name"]), "beard", Vector3(-4.6, 0, -1.4 - 0.75), Color("#6a4a2a")],
		[(data()["people"]["students"]["name"]), "students", Vector3(0.6, 0, -1.4 + 0.75), Color("#3a6aa8")],
		[(data()["people"]["tourists"]["name"]), "tourists", Vector3(0.6, 0, 2.2 + 0.75), Color("#d88a3a")],
		[(data()["people"]["couple"]["name"]), "couple", Vector3(-1.8, 0, 4.6 - 0.75), Color("#b43a6a")],
		[rival("sommelier").get("name", ["", ""]), "r:sommelier", PONG + Vector3(1.7, 0, -0.3), Color("#5a1a2a")],
		[rival("office").get("name", ["", ""]), "r:office", PONG + Vector3(1.7, 0, 0.5), Color("#e8e8ee")],
		[rival("first").get("name", ["", ""]), "r:first", PONG + Vector3(0.9, 0, 0.9), Color("#c86aa8")],
	]
	mm.instance_count = _seat.size() + people.size()
	InstanceBuffers.whiten(mm)
	for i in _seat.size():
		mm.set_instance_custom_data(i, Color(clothes[frng.randi() % clothes.size()], 0.25))
	for i in people.size():
		mm.set_instance_custom_data(_seat.size() + i, Color(people[i][3], 0.25))
		var face := 0.0 if i == 0 else PI * 0.5
		mm.set_instance_transform(_seat.size() + i, Transform3D(Basis(Vector3.UP, face), people[i][2]))
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
		mm.set_instance_transform(i, Transform3D(lean, Vector3(s.x, -0.42, s.z)))


func _build_ui() -> void:
	var pt: float = hud.pt if hud != null and "pt" in hud else 1.0
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiKit.card(pt, 10.0))
	top.position = Vector2(16, 16) * pt
	_ui.add_child(top)
	_title = Label.new()
	UiKit.style_label(_title, "title", pt)
	top.add_child(_title)
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
	_talk.reset_size()
	_talk.position = Vector2(16 * pt, vp.y - _talk.size.y - 16 * pt)
	_pick.reset_size()
	_pick.position = (vp - _pick.size) * 0.5


# --- going in and out -----------------------------------------------------------------------

## In: the room built (once) under `world`, the panel up, the barman's hello.
func enter(world: Node3D) -> void:
	if not _built:
		_build(world)
	inside = true
	pints = 0
	_title.text = say("title")
	_show(true)
	_say(people[0])
	_log("room in")
	if auto_play:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if inside:
				drink()
				play(RIVALS[0]))


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
	_ui.visible = on
	_talk.visible = on and _line.text != ""
	_pick.visible = false
	_buttons.visible = on


## WYPIJ PIWKO: a pint at the bar (PINT zł; the bar stops at MAX_PINTS).
func drink() -> void:
	if not inside:
		return
	if pints >= MAX_PINTS:
		_say_text(people[0][0], pair("full"))
		return
	# Short of a pint's price: the first of the visit is on the house, then no tabs.
	var paid: bool = wallet == null or wallet.spend(PINT)
	if not paid and pints > 0:
		_say_text(people[0][0], pair("broke"))
		return
	pints += 1
	var p := pair("price")
	if paid:
		_say_text(people[0][0], [str(p[0]) % PINT, str(p[1]) % PINT])
	else:
		_say_text(people[0][0], pair("free"))
	_log("pint %d" % pints)
	drank.emit()


func _show_pick() -> void:
	_pick.visible = true
	_layout()


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
	_pong.pt = hud.pt if hud != null and "pt" in hud else 1.0
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
	else:
		lines = (data().get("people", {}) as Dictionary).get(key, {}).get("lines", [])
	if lines.is_empty():
		return
	_say_text(person[0], lines[_rng.randi() % lines.size()])


func _say_text(name_pair: Array, line: Array) -> void:
	_who.text = Lang.pick(str(name_pair[0]), str(name_pair[1]))
	_line.text = Lang.pick(str(line[0]), str(line[1]))
	_talk.visible = inside and (_pong == null or not _pong.visible)
	_layout()


func _log(text: String) -> void:
	if log_on:
		print("tapczan: " + text)
