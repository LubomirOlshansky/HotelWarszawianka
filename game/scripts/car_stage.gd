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

const Models := preload("res://scripts/models.gd")
const UiKit := preload("res://scripts/ui_kit.gd")

## One turn of the turntable (s) and how fast a let-go drag settles back to it (1/s).
const SPIN_TIME := 8.0
const SETTLE := 2.2
## Radians a drag of one point turns the car.
const DRAG_TURN := 0.012
## The back wall's words by mode (the stencil on the roller door).
const MODE_WORDS := {"garage": "WARSZTAT · TWARDA 24h", "lot": "KOMIS U MIRKA", "mine": "MOJE AUTO"}
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
var _body_mat: StandardMaterial3D


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
	visibility_changed.connect(func() -> void:
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED)


## The workshop, the lot or MOJE AUTO (MODE_WORDS): the stencil on the back wall.
func set_mode(m: String) -> void:
	mode = m if MODE_WORDS.has(m) else "garage"
	if _words != null:
		_words.text = str(MODE_WORDS[mode])


## The car on the turntable: its body kind (models.gd player_meshes: "player", "player_tt") and paint.
func set_car(kind: String, paint: Color, stripe: Color) -> void:
	if kind == _kind and paint == _paint and stripe == _stripe and _car_root != null and _car_root.get_child_count() > 0:
		return
	_kind = kind
	_paint = paint
	_stripe = stripe
	_set_car_meshes()


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
	var meshes := Models.player_meshes(Models.fin(_paint, Models.HERO, 1.0), Models.fin(_stripe, Models.HERO, 0.3), _kind)
	if _body_mat == null:
		_body_mat = StandardMaterial3D.new()
		_body_mat.vertex_color_use_as_albedo = true
		_body_mat.roughness = 0.3
		_body_mat.metallic = 0.1
		_body_mat.metallic_specular = 0.7
	var mats: Array[Material] = [_body_mat, _glow_mat(Color("#fff6d8"), 1.6), _glow_mat(Color("#ff3a2a"), 1.3)]
	for i in 3:
		_mesh(_car_root, meshes[i], mats[i], Vector3.ZERO)
	_mesh(_mirror_root, meshes[0], _body_mat, Vector3.ZERO)  # the body only: lit lamps glare through the floor
	_car_root.rotation.y = _yaw
	_mirror_root.rotation.y = _yaw
