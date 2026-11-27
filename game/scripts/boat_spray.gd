extends MultiMeshInstance3D
## The Szprotka's spray (the arcade pass, 2026-11-26): one pool of DROPS droplets shared by every
## boat of the race (boat_race.gd `_spray_tick`): a fast hull throws a few a second off its bow,
## a burning nitro three times as many, a landing or a crate a burst. Small boxes in one MultiMesh
## with the actors' material (splash.gd's pattern: no new shader, no transparency, no shadow), one
## buffer upload a frame while a drop lives; hidden (no draw call, no script) the rest of the time.
## The node sits on the player's boat each frame (`follow`) and the drops are written relative to
## it, so its AABB stays small and the culling honest.

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const DROPS := 48
const LIFE := 0.5
const GRAVITY := 15.0
const SPRAY := Color("#f4fbff")
const SPRAY_BLUE := Color("#bfe0f2")
const REACH := 60.0

## Per drop: where it left (world), its velocity, its age (>= LIFE: dead) and size.
var _start := PackedVector3Array()
var _vel := PackedVector3Array()
var _age := PackedFloat32Array()
var _size := PackedFloat32Array()
var _buf := PackedFloat32Array()
var _next := 0
var _alive := 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(st, Vector3.ZERO, Vector3.ONE, Color.WHITE, Models.FIXED)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = st.commit()
	mm.instance_count = DROPS
	mm.custom_aabb = AABB(Vector3(-REACH, -2.0, -REACH), Vector3(REACH * 2.0, 14.0, REACH * 2.0))
	multimesh = mm
	material_override = Models.material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_start.resize(DROPS)
	_vel.resize(DROPS)
	_age.resize(DROPS)
	_age.fill(LIFE)
	_size.resize(DROPS)
	_buf.resize(DROPS * 16)
	_rng.seed = 2611
	visible = false


## One droplet from `at` (world) at `vel`, white or blue-white; the oldest goes when the pool is full.
func emit(at: Vector3, vel: Vector3) -> void:
	var i := _next
	_next = (_next + 1) % DROPS
	if _age[i] >= LIFE:
		_alive += 1
	_start[i] = at
	_vel[i] = vel
	_age[i] = 0.0
	_size[i] = _rng.randf_range(0.18, 0.34)
	var tint := SPRAY if _rng.randf() < 0.7 else SPRAY_BLUE
	var b := i * 16
	_buf[b + 12] = tint.r
	_buf[b + 13] = tint.g
	_buf[b + 14] = tint.b
	_buf[b + 15] = 0.0
	visible = true


## `n` droplets thrown up and out round `at` (a landing, a crate).
func burst(at: Vector3, n: int, strength := 1.0) -> void:
	for k in n:
		var a := _rng.randf() * TAU
		var out := Vector3(cos(a), 0.0, sin(a))
		emit(at + out * _rng.randf_range(0.3, 1.4), (out * _rng.randf_range(2.0, 5.0) + Vector3.UP * _rng.randf_range(4.0, 8.0)) * strength)


## A random number in [a, b] from the pool's own dice (the race's stay on its stream).
func rand(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


## Every drop gone at once (the race hidden).
func clear() -> void:
	_age.fill(LIFE)
	_alive = 0
	visible = false


func live() -> int:
	return _alive


## One frame: age the drops and write them relative to `centre` (the player's boat).
func step(dt: float, centre: Vector3) -> void:
	if _alive <= 0:
		visible = false
		return
	position = centre  # the race is a plain Node: local is the world
	_alive = 0
	for i in DROPS:
		var age := _age[i]
		var s := 0.0
		var p := Vector3.ZERO
		if age < LIFE:
			age += dt
			_age[i] = age
			if age < LIFE:
				_alive += 1
				p = _start[i] + _vel[i] * age + Vector3.DOWN * (0.5 * GRAVITY * age * age) - centre
				s = _size[i] * (1.0 - 0.5 * age / LIFE)
				if p.y + centre.y < _start[i].y - 0.6 or absf(p.x) > REACH or absf(p.z) > REACH:
					s = 0.0
		var b := i * 16
		_buf[b] = s
		_buf[b + 1] = 0.0
		_buf[b + 2] = 0.0
		_buf[b + 3] = p.x
		_buf[b + 4] = 0.0
		_buf[b + 5] = s
		_buf[b + 6] = 0.0
		_buf[b + 7] = p.y
		_buf[b + 8] = 0.0
		_buf[b + 9] = 0.0
		_buf[b + 10] = s
		_buf[b + 11] = p.z
	visible = _alive > 0
	if visible and is_inside_tree():
		InstanceBuffers.send(multimesh.get_rid(), _buf)
