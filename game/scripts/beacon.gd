extends Node3D
## A mission marker: a ring on the ground showing where to stop, a tall column of
## light that reads from across the map, and a tiny person (waving for help, or
## standing and waiting at the hospital).
##
## Colour-safe (access.gd, Settings → DOSTĘP) gives the marker a second cue besides its hue: the
## colour passes through `Access.tint` (a success green turns blue), and the ring's shape says what
## the marker is, so a race ring and a rescue ring no longer differ by colour alone:
##   SOLID    the place to stop (drop-off, hospital, a job's door): a full ring, as always.
##   DASHED   someone waiting to be picked up (a rescue call): 16 dashes with the ground between.
##   CHEQUER  a race's finish or checkpoint: blocks about 1.2 m long in the marker's colour and
##            white, like a finish line.
## With colour-safe off every ring is solid. The beacon notices the setting changing on its own
## (no restart), and rebuilds only its ring (a few dozen quads), never per frame.

const Access := preload("res://scripts/access.gd")

const COLUMN_HEIGHT := 170.0
const RING_WIDTH := 0.6
const DASHES := 16
const CHEQUER_BLOCK := 1.2
const CHEQUER_WHITE := Color("#f4f1ea")

enum Pattern { SOLID, DASHED, CHEQUER }

## The beta trailer (trailer.gd, F 2026-11-10): every marker kept out of the picture, the quest
## starts' columns of light included.
static var hide_all := false

var waving := true
## The ring's shape under colour-safe (see above); set it before or after `setup`.
var pattern := Pattern.SOLID:
	set(v):
		pattern = v
		if _ring != null:
			_refresh()
var _ring: MeshInstance3D
var _ring_radius := 0.0
var _ring_mat: StandardMaterial3D
var _column: MeshInstance3D
var _column_mat: StandardMaterial3D
var _person: Node3D
var _arm: Node3D
var _colour := Color.WHITE
var _shown := Color.WHITE  # _colour as the player sees it (Access.tint)
var _safe := false  # Access.color_safe the ring was last built for
var _t := 0.0


## Builds the parts once; `shirt` colours the person.
func setup(colour: Color, shirt: Color) -> void:
	_colour = colour
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# The ring carries its colour in its vertices (the chequer's white blocks), so the
	# material stays white.
	_ring_mat.vertex_color_use_as_albedo = true
	_ring_mat.vertex_color_is_srgb = true  # the same shade albedo_color gave it before
	_ring = MeshInstance3D.new()
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	_column_mat = StandardMaterial3D.new()
	_column_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_column_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_column_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_column_mat.vertex_color_use_as_albedo = true
	_column_mat.albedo_color = colour
	# After the post-process quad, which repaints the screen from a copy taken
	# before the transparent pass (see heli.gd).
	_column_mat.render_priority = 1
	_column = MeshInstance3D.new()
	_column.mesh = _column_mesh()
	_column.material_override = _column_mat
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_column)

	_person = _make_person(shirt)
	add_child(_person)
	visible = false
	_refresh()


## Changes the ring and column colour (one beacon serves both side jobs).
func recolour(colour: Color) -> void:
	if colour == _colour:
		return
	_colour = colour
	_refresh()


## The colour the player sees now (after colour-safe's tint).
func shown_colour() -> Color:
	return _shown


## The ring's mesh now (checks read its vertex colours and size).
func ring_mesh() -> ArrayMesh:
	return _ring.mesh


## Re-reads colour-safe and the colour, and rebuilds the ring if it is placed.
func _refresh() -> void:
	_safe = Access.color_safe
	_shown = Access.tint(_colour)
	_column_mat.albedo_color = _shown
	if _ring_radius > 0.0:
		_ring.mesh = _ring_mesh(_ring_radius)


## Shows the marker at a spot; `radius` is the ring the vehicle has to stop in.
func place(at: Vector3, radius: float, column := true, person := true) -> void:
	global_position = at
	if radius != _ring_radius or _safe != Access.color_safe:
		_ring_radius = radius
		_refresh()
	_ring.visible = column
	_column.visible = column
	_person.visible = person
	visible = not hide_all


func _process(dt: float) -> void:
	if hide_all:
		visible = false
	if not visible:
		return
	if _safe != Access.color_safe:
		_refresh()  # the player switched colour-safe in Settings
	_t += dt
	_column_mat.albedo_color = Color(_shown, 0.7 + 0.3 * sin(_t * 4.0))
	if waving:
		_arm.rotation.z = -0.25 + 0.55 * sin(_t * 9.0)
	else:
		_arm.rotation.z = -2.95  # hanging down at the side


## A flat ring RING_WIDTH wide, lifted a little so the ground layers don't cover it, in
## `pattern`'s shape when colour-safe is on (a full ring otherwise).
func _ring_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape := pattern if _safe else Pattern.SOLID
	var n := 32
	if shape == Pattern.DASHED:
		n = DASHES * 2
	elif shape == Pattern.CHEQUER:
		n = clampi(roundi(TAU * radius / CHEQUER_BLOCK / 2.0) * 2, 12, 96)  # even: blocks pair up
	var inner := radius - RING_WIDTH
	var y := Vector3(0, 0.4, 0)
	for i in n:
		if shape == Pattern.DASHED and i % 2 == 1:
			continue  # the gap between two dashes
		var c := CHEQUER_WHITE if shape == Pattern.CHEQUER and i % 2 == 1 else _shown
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		st.set_color(c)
		# Clockwise seen from above (Godot's front faces).
		for v in [o0 * radius, o1 * radius, o0 * inner, o1 * radius, o1 * inner, o0 * inner]:
			st.add_vertex(v + y)
	return st.commit()


## A six-sided column of light, fading out towards the top.
func _column_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 1.1
	for i in 6:
		var a := Vector3(cos(TAU * i / 6.0) * r, 0.0, sin(TAU * i / 6.0) * r)
		var b := Vector3(cos(TAU * (i + 1) / 6.0) * r, 0.0, sin(TAU * (i + 1) / 6.0) * r)
		var up := Vector3(0, COLUMN_HEIGHT, 0)
		var low := Color(1, 1, 1, 0.75)
		var high := Color(1, 1, 1, 0.0)
		for v in [[a, low], [b, low], [b + up, high], [a, low], [b + up, high], [a + up, high]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
	return st.commit()


## A person about 2.5 m tall (a little over life size so it reads at pixel scale),
## with one arm on a shoulder pivot for waving.
func _make_person(shirt: Color) -> Node3D:
	var root := Node3D.new()
	var skin := Color("#e7b98f")
	var trousers := Color("#2d3442")
	for x in [-0.12, 0.12]:
		_box(root, Vector3(0.18, 0.95, 0.24), Vector3(x, 0.48, 0), trousers)
	_box(root, Vector3(0.5, 0.7, 0.3), Vector3(0, 1.3, 0), shirt)
	_box(root, Vector3(0.3, 0.32, 0.3), Vector3(0, 1.84, 0), skin)
	_box(root, Vector3(0.13, 0.66, 0.14), Vector3(-0.32, 1.28, 0), shirt)
	_arm = Node3D.new()
	_arm.position = Vector3(0.3, 1.58, 0)
	root.add_child(_arm)
	_box(_arm, Vector3(0.13, 0.66, 0.14), Vector3(0.0, 0.3, 0), shirt)
	_box(_arm, Vector3(0.13, 0.13, 0.14), Vector3(0.0, 0.66, 0), skin)
	root.scale = Vector3.ONE * 1.35
	return root


func _box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
