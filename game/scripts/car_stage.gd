extends SubViewportContainer
## G1 (docs/design/garage-and-cars.md 0b, F 2026-11-23: "MOJE AUTO with that street-racing
## underground vibe, the garage and the tuning, stylish"): the car on a turntable in a night box,
## the 3D half of the car screen (garage_card.gd puts it left of its panel). Its own small world
## (SubViewport `own_world_3d`), so nothing of the city is drawn while it is open:
##  - a dark concrete floor with a wet sheen: the car drawn once more upside down under a floor
##    that lets 30 % of it through (the cheap mirror, no reflection probe);
##  - the back wall: a roller door with a stencil (MODE_WORDS: the workshop, the lot, MOJE AUTO),
##    a pink neon tube over it and a cyan one along the floor, each with an additive halo quad (no
##    glow pass: the Mobile renderer's glow stays off), a tyre stack and a work lamp at the sides;
##  - one warm key light (no shadows: a soft blob under the car) and the two tubes' colour lights.
## The car turns once in SPIN_TIME s; a drag turns it, and a release lets it run on and settle back
## to the slow turn; `focus` turns a side towards the camera (the engine: the nose, the tyres: a
## wheel, the nitro: the tail). About a dozen draw calls; the viewport renders only while shown
## (`render_target_update_mode`), and the game is paused under the screen.
## F 2026-11-24 ("inside it must look good, neon; you can buy, say, a spoiler; and next to it a
## Porsche 911, by all means"): the night box became Mirek's tuning bay (`_build_bay`):
##  - the car turns on a round diamond-plate pad with a hazard-striped rim (one generated texture);
##  - on the wall, two crossed neon wrenches and TUNING in cyan, two white strip lights (F, same day:
##    nothing else behind the car; the Porsza 911 stands outside the workshop, mirek.gd);
##  - the looks shown on the car (`set_car` wing and neon): the GT wing in the body's mesh, the
##    underglow an additive pad and a cyan light under it.
## About six more draw calls than G1's box, all inside the stage's own world.

const Models := preload("res://scripts/models.gd")
const UiKit := preload("res://scripts/ui_kit.gd")

## One turn of the turntable (s) and how fast a let-go drag settles back to it (1/s).
const SPIN_TIME := 8.0
const SETTLE := 2.2
## Radians a drag of one point turns the car.
const DRAG_TURN := 0.012
## The back wall's words by mode (the stencil on the roller door).
const MODE_WORDS := {"garage": "WARSZTAT · GRZYBOWSKA 24h", "lot": "KOMIS U MIRKA", "mine": "MOJE AUTO"}
## The camera: distance (m), height (m), the point it looks at, the field of view.
const CAM_DIST := 10.5
const CAM_HIGH := 2.6
const CAM_AT := Vector3(0.0, 0.7, 0.0)
const CAM_FOV := 34.0
## How long a `focus` holds the side before the slow turn takes over again (s).
const FOCUS_HOLD := 3.5
## The yaw (rad) that shows each part's side to the camera.
const FOCUS_YAW := {"engine": 0.35, "tyres": -1.2, "nitro": PI - 0.35}

var mode := "garage"
## The share of the screen's width the panel covers on the right (garage_card.gd): the camera slides
## so the car sits in the middle of what is left.
var panel_share := 0.0
var _cam: Camera3D
var _vp: SubViewport
var _car_root: Node3D
var _mirror_root: Node3D
var _yaw := 0.6
var _spin := TAU / SPIN_TIME
var _drag := false
var _hold := 0.0
var _target := NAN
var _words: Label3D
var _paint := Color("#d8432f")
var _stripe := Color("#f4efe4")
var _kind := "player"
var _wing := false
var _neon := false
var _body_mat: StandardMaterial3D
## The underglow under the stage car (a pad and its light), shown with `set_car` neon.
var _glow_pad: MeshInstance3D
var _glow_light: OmniLight3D
## The turning pad (it turns with the car).
var _pad: MeshInstance3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stretch = true
	stretch_shrink = 1
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_build_room()
	_set_car_meshes()
	visibility_changed.connect(_update_mode)


## The stage draws only while the card shows it AND the game is paused under it (audit, #1023):
## a card left visible over a running city would cost a second 3D frame.
func _update_mode() -> void:
	var on := is_visible_in_tree() and is_inside_tree() and get_tree().paused
	var want := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if _vp.render_target_update_mode != want:
		_vp.render_target_update_mode = want


## The workshop, the lot or MOJE AUTO (MODE_WORDS): the stencil on the back wall.
func set_mode(m: String) -> void:
	mode = m if MODE_WORDS.has(m) else "garage"
	if _words != null:
		_words.text = str(MODE_WORDS[mode])


## The car on the turntable: its body kind (models.gd player_meshes: "player", "player_tt"), paint,
## and the looks (upgrades.gd LOOKS: the GT wing, the underglow), owned or tried on.
func set_car(kind: String, paint: Color, stripe: Color, wing := false, neon := false) -> void:
	_neon = neon
	if _glow_pad != null:
		_glow_pad.visible = neon
		_glow_light.visible = neon
	if kind == _kind and paint == _paint and stripe == _stripe and wing == _wing and _car_root != null and _car_root.get_child_count() > 0:
		return
	_kind = kind
	_paint = paint
	_stripe = stripe
	_wing = wing
	_set_car_meshes()


## For the checks: the looks the stage car wears now [wing, neon].
func looks() -> Array[bool]:
	return [_wing, _neon]


## Turn the side that shows `part` (FOCUS_YAW) towards the camera, then the slow turn goes on.
func focus(part: String) -> void:
	if not FOCUS_YAW.has(part):
		return
	_target = float(FOCUS_YAW[part])
	_hold = FOCUS_HOLD


## The car's yaw now (rad), for the checks.
func yaw() -> float:
	return _yaw


func _process(dt: float) -> void:
	_update_mode()
	if not is_visible_in_tree() or _car_root == null:
		return
	if _drag:
		pass
	elif not is_nan(_target):
		var d := wrapf(_target - _yaw, -PI, PI)
		_yaw += d * minf(1.0, dt * 4.0)
		if absf(d) < 0.01:
			_hold -= dt
			if _hold <= 0.0:
				_target = NAN
				_spin = 0.0
	else:
		_spin = lerpf(_spin, TAU / SPIN_TIME, minf(1.0, dt * SETTLE))
		_yaw += _spin * dt
	_yaw = wrapf(_yaw, -PI, PI)
	if _cam != null and size.y > 0.0:
		var high := 2.0 * CAM_DIST * tan(deg_to_rad(CAM_FOV * 0.5))
		_cam.h_offset = panel_share * 0.5 * high * size.x / size.y
	_car_root.rotation.y = _yaw
	_mirror_root.rotation.y = _yaw
	if _pad != null:
		_pad.rotation.y = _yaw


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var down: bool = event.pressed
		_drag = down
		if down:
			_target = NAN
			_spin = 0.0
		accept_event()
	elif (event is InputEventScreenDrag or (event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask != 0)) and _drag:
		var rel: Vector2 = event.relative
		var pt := maxf(1.0, get_viewport_rect().size.y / 390.0)
		var turn := rel.x / pt * DRAG_TURN
		_yaw += turn
		var dt := maxf(get_process_delta_time(), 1.0 / 120.0)
		_spin = clampf(turn / dt, -6.0, 6.0)
		accept_event()


func _build_room() -> void:
	var world := Node3D.new()
	_vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#07060c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#3a3150")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var cam := Camera3D.new()
	_cam = cam
	cam.fov = CAM_FOV
	world.add_child(cam)
	cam.position = Vector3(CAM_DIST * 0.82, CAM_HIGH, CAM_DIST * 0.57)
	cam.look_at_from_position(cam.position, CAM_AT, Vector3.UP)
	cam.current = true
	# The key light: warm, from the camera's left and above; no shadows (the blob does it).
	var key := DirectionalLight3D.new()
	key.light_color = Color("#ffe2c2")
	key.light_energy = 1.1
	key.shadow_enabled = false
	world.add_child(key)
	key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(28.0), 0.0)
	# The tubes' colour on the car's flanks and roof.
	for l: Array in [[UiKit.NEON_PINK, Vector3(-1.5, 3.2, -3.0), 0.9], [UiKit.NEON_CYAN, Vector3(2.4, 0.4, -2.6), 0.6]]:
		var o := OmniLight3D.new()
		o.light_color = l[0]
		o.light_energy = l[2]
		o.omni_range = 7.5
		o.shadow_enabled = false
		o.position = l[1]
		world.add_child(o)
	# The mirror under the floor: the car again, upside down.
	_mirror_root = Node3D.new()
	_mirror_root.scale = Vector3(1.0, -1.0, 1.0)
	world.add_child(_mirror_root)
	# The floor: dark wet concrete that lets the mirror through.
	var floor_m := StandardMaterial3D.new()
	floor_m.albedo_color = Color(0.05, 0.045, 0.065, 0.92)
	floor_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_m.roughness = 0.18
	floor_m.metallic_specular = 0.8
	_mesh(world, _plane(Vector2(26.0, 26.0)), floor_m, Vector3(0.0, 0.0, 0.0))
	# A soft dark blob under the car (the shadow the key light does not cast).
	var blob := StandardMaterial3D.new()
	blob.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blob.albedo_texture = _radial(Color(0, 0, 0, 0.85), Color(0, 0, 0, 0))
	_mesh(world, _plane(Vector2(3.6, 5.6)), blob, Vector3(0.0, 0.012, 0.0))
	# The back wall: a roller door of ribs and its frame, the stencil, the tubes and their halos.
	var wall_m := StandardMaterial3D.new()
	wall_m.albedo_color = Color("#1b1824")
	wall_m.roughness = 0.9
	var wall := Node3D.new()
	# Square to the camera, behind the car, filling the frame.
	wall.rotation.y = atan2(0.82, 0.57)
	wall.position = -Vector3(0.82, 0.0, 0.57) * 5.0
	world.add_child(wall)
	var door := BoxMesh.new()
	door.size = Vector3(20.0, 7.0, 0.2)
	_mesh(wall, door, wall_m, Vector3(0.0, 3.5, 0.0))
	var rib_m := StandardMaterial3D.new()
	rib_m.albedo_color = Color("#2a2636")
	rib_m.roughness = 0.7
	var ribs := SurfaceTool.new()
	ribs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rib := BoxMesh.new()
	rib.size = Vector3(9.0, 0.06, 0.05)
	for i in 18:
		ribs.append_from(rib, 0, Transform3D(Basis(), Vector3(0.0, 0.35 + i * 0.25, 0.12)))
	_mesh(wall, ribs.commit(), rib_m, Vector3.ZERO)
	_words = Label3D.new()
	_words.text = str(MODE_WORDS[mode])
	_words.font_size = 96
	_words.pixel_size = 0.0042
	_words.modulate = Color(0.95, 0.92, 0.85, 0.42)
	_words.outline_size = 0
	_words.shaded = false
	_words.position = Vector3(0.0, 3.6, 0.14)
	wall.add_child(_words)
	_tube(wall, UiKit.NEON_PINK, Vector3(0.0, 5.0, 0.18), 10.0)
	_tube(wall, UiKit.NEON_CYAN, Vector3(0.0, 0.08, 0.3), 14.0, 0.7)
	# A tyre stack on the right and a work lamp on the left: dark shapes against the glow.
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("#0d0c12")
	dark.roughness = 0.85
	var tyres := SurfaceTool.new()
	tyres.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tyre := CylinderMesh.new()
	tyre.top_radius = 0.34
	tyre.bottom_radius = 0.34
	tyre.height = 0.24
	tyre.radial_segments = 12
	for i in 4:
		tyres.append_from(tyre, 0, Transform3D(Basis(Vector3.UP, i * 0.4), Vector3(0.0, 0.12 + i * 0.25, 0.0)))
	_mesh(wall, tyres.commit(), dark, Vector3(5.2, 0.0, 1.0))
	var lamp := SurfaceTool.new()
	lamp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pole := BoxMesh.new()
	pole.size = Vector3(0.06, 1.9, 0.06)
	lamp.append_from(pole, 0, Transform3D(Basis(), Vector3(0.0, 0.95, 0.0)))
	var legs := BoxMesh.new()
	legs.size = Vector3(0.7, 0.05, 0.7)
	lamp.append_from(legs, 0, Transform3D(Basis(Vector3.UP, 0.78), Vector3(0.0, 0.03, 0.0)))
	_mesh(wall, lamp.commit(), dark, Vector3(-5.0, 0.0, 1.6))
	var lamp_head := BoxMesh.new()
	lamp_head.size = Vector3(0.36, 0.26, 0.12)
	_mesh(wall, lamp_head, _glow_mat(Color("#e8b860"), 1.0), Vector3(-5.0, 1.95, 1.6))
	_build_bay(world, wall)
	# The car (and its mirror) go on the turntable; `_set_car_meshes` fills them.
	_car_root = Node3D.new()
	world.add_child(_car_root)


## A neon tube (an unshaded bright strip) with its halo (a soft additive quad behind it).
func _tube(parent: Node3D, colour: Color, at: Vector3, length: float, halo_up := 0.0) -> void:
	var tube := BoxMesh.new()
	tube.size = Vector3(length, 0.07, 0.07)
	_mesh(parent, tube, _glow_mat(colour.lightened(0.35), 1.0), at)
	var halo := StandardMaterial3D.new()
	halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo.albedo_texture = _radial(Color(colour, 0.75 if halo_up == 0.0 else 0.4), Color(colour, 0.0))
	halo.cull_mode = BaseMaterial3D.CULL_DISABLED
	var q := QuadMesh.new()
	q.size = Vector2(length * 1.25, 1.5)
	_mesh(parent, q, halo, at + Vector3(0.0, halo_up, -0.02))


func _glow_mat(colour: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = colour * energy if energy > 1.0 else colour
	return m


func _plane(size: Vector2) -> PlaneMesh:
	var p := PlaneMesh.new()
	p.size = size
	return p


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A small radial gradient (`inner` in the middle to `outer` at the edge), for the halos and the blob.
func _radial(inner: Color, outer: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	return t


## The car's three meshes (models.gd player_meshes) on the turntable and in the mirror, the body in
## a glossy showroom material that takes the vertex colours (the paint and the stripes), the head
## lamps lit.
func _set_car_meshes() -> void:
	if _car_root == null:
		return
	for root: Node3D in [_car_root, _mirror_root]:
		for c in root.get_children():
			c.free()
	var meshes := Models.player_meshes(Models.fin(_paint, Models.HERO, 1.0), Models.fin(_stripe, Models.HERO, 0.3), _kind, _wing)
	var mats: Array[Material] = [_gloss(), _glow_mat(Color("#fff6d8"), 1.6), _glow_mat(Color("#ff3a2a"), 1.3)]
	for i in 3:
		_mesh(_car_root, meshes[i], mats[i], Vector3.ZERO)
	if _kind == "player_tt":
		# The active spoiler shown up, as it is at speed.
		_mesh(_car_root, Models.tt_spoiler(Models.fin(_paint, Models.HERO, 1.0)), _gloss(), Vector3(0.0, Models.SPOILER_LIFT, 0.0))
	_mesh(_mirror_root, meshes[0], _gloss(), Vector3.ZERO)  # the body only: lit lamps glare through the floor
	_car_root.rotation.y = _yaw
	_mirror_root.rotation.y = _yaw


## The glossy showroom material that takes the vertex colours (the cars on the stage).
func _gloss() -> StandardMaterial3D:
	if _body_mat == null:
		_body_mat = StandardMaterial3D.new()
		_body_mat.vertex_color_use_as_albedo = true
		_body_mat.roughness = 0.3
		_body_mat.metallic = 0.1
		_body_mat.metallic_specular = 0.7
	return _body_mat


# --- Mirek's tuning bay (F 2026-11-24) ----------------------------------------------------------

## The pad's radius (m) and its hazard rim's share of it.
const PAD_R := 2.9
const PAD_RIM := 0.12


## Everything the bay adds round the car; `wall` is the back wall's frame (x to the camera's right,
## z towards it, the car 5 m out from it).
func _build_bay(world: Node3D, wall: Node3D) -> void:
	# The pad: diamond plate in a hazard rim, a little see-through so the wet floor still shines.
	var pad_m := StandardMaterial3D.new()
	pad_m.albedo_texture = _pad_texture()
	pad_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	pad_m.alpha_scissor_threshold = 0.5
	pad_m.roughness = 0.35
	pad_m.metallic = 0.55
	pad_m.metallic_specular = 0.7
	_pad = _mesh(world, _plane(Vector2(PAD_R * 2.0, PAD_R * 2.0)), pad_m, Vector3(0.0, 0.02, 0.0))
	# The underglow (shown with `set_car` neon): a soft additive pad and a cyan light under the car.
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_texture = _radial(Color(UiKit.NEON_CYAN, 0.95), Color(UiKit.NEON_CYAN, 0.0))
	_glow_pad = _mesh(world, _plane(Vector2(3.4, 5.6)), glow, Vector3(0.0, 0.035, 0.0))
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = UiKit.NEON_CYAN
	_glow_light.light_energy = 1.6
	_glow_light.omni_range = 3.2
	_glow_light.shadow_enabled = false
	_glow_light.position = Vector3(0.0, 0.25, 0.0)
	world.add_child(_glow_light)
	_glow_pad.visible = _neon
	_glow_light.visible = _neon
	# Two crossed neon wrenches over TUNING, left of the stencil, with a halo behind.
	var wrench := SurfaceTool.new()
	wrench.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sgn: float in [-1.0, 1.0]:
		_wrench(wrench, Transform3D(Basis(Vector3.BACK, sgn * 0.75), Vector3.ZERO))
	_mesh(wall, wrench.commit(), _glow_mat(UiKit.NEON_CYAN.lightened(0.35), 1.0), Vector3(-4.9, 3.95, 0.2))
	var halo := StandardMaterial3D.new()
	halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo.albedo_texture = _radial(Color(UiKit.NEON_CYAN, 0.55), Color(UiKit.NEON_CYAN, 0.0))
	var hq := QuadMesh.new()
	hq.size = Vector2(4.2, 3.8)
	_mesh(wall, hq, halo, Vector3(-4.9, 3.5, 0.16))
	var word := Label3D.new()
	word.text = "TUNING"
	word.font_size = 120
	word.pixel_size = 0.005
	word.modulate = UiKit.NEON_CYAN.lightened(0.3)
	word.outline_modulate = Color(UiKit.NEON_CYAN, 0.5)
	word.outline_size = 18
	word.shaded = false
	word.position = Vector3(-4.9, 2.55, 0.22)
	wall.add_child(word)
	# Two white strip lights down the wall.
	var strips := SurfaceTool.new()
	strips.begin(Mesh.PRIMITIVE_TRIANGLES)
	var strip := BoxMesh.new()
	strip.size = Vector3(0.09, 4.6, 0.09)
	for x: float in [-6.9, 3.6]:
		strips.append_from(strip, 0, Transform3D(Basis(), Vector3(x, 3.0, 0.2)))
	_mesh(wall, strips.commit(), _glow_mat(Color("#f4f1ff"), 1.0), Vector3.ZERO)


## One wrench along x (2.4 m), its open jaws at both ends, into `st` at `xf`.
func _wrench(st: SurfaceTool, xf: Transform3D) -> void:
	var bar := BoxMesh.new()
	bar.size = Vector3(1.7, 0.13, 0.06)
	st.append_from(bar, 0, xf)
	var seg := BoxMesh.new()
	seg.size = Vector3(0.2, 0.09, 0.06)
	for end: float in [-1.0, 1.0]:
		var c := Vector3(end * 1.06, 0.0, 0.0)
		# A C of seven segments round the jaw, open away from the handle.
		for k in 7:
			var a := (end * -1.0 + 1.0) * PI * 0.5 + deg_to_rad(-150.0 + k * 50.0)
			var p := c + Vector3(cos(a), sin(a), 0.0) * 0.24
			st.append_from(seg, 0, xf * Transform3D(Basis(Vector3.BACK, a + PI * 0.5), p))


## The pad's texture: diamond plate inside, the hazard rim, clear outside the circle.
func _pad_texture() -> ImageTexture:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var plate := Color("#4c5058")
	var bead := Color("#8a8f99")
	var yellow := Color("#ffc21a")
	var black := Color("#141417")
	var half := n * 0.5
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half)
			var r := d.length() / half
			if r > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			if r > 1.0 - PAD_RIM:
				var stripe := int(floor((d.angle() / TAU * 48.0) + r * 3.0)) % 2 == 0
				img.set_pixel(x, y, yellow if stripe else black)
				continue
			# Diamond plate: short raised beads in a herringbone, two directions on a 16 px grid.
			var cell := Vector2(fposmod(x, 16.0) - 8.0, fposmod(y, 16.0) - 8.0)
			var flip := (int(x / 16.0) + int(y / 16.0)) % 2 == 0
			var a := cell.rotated(0.785 if flip else -0.785)
			var on := absf(a.x) < 5.0 and absf(a.y) < 1.3
			img.set_pixel(x, y, bead if on else plate)
	return ImageTexture.create_from_image(img)
