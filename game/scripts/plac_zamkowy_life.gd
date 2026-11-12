extends Node3D
## Plac Zamkowy's people and pigeons, for the beta trailer's Old Town take (F, 2026-11-10; the
## static half, the column's plaza with its steps and the cafe gardens, is landmarks.gd
## `_build_zamkowy`): a crowd of tourists on the square, standing in groups (a guide and a
## ring round her, photographers facing the column) with a few strolling, and a flock of
## pigeons pecking on the setts that burst into the air when a car comes close or a helicopter
## flies low over them, circle, and land again once it has gone: the same flock as Plac Defilad's
## (eggs.gd `_pigeons`), written here per flock so the second one needs no copy of eggs.gd's
## state. Cost: 3 MultiMeshes (the standing tourists, the strollers, the two pigeon meshes: 4
## draws) only while the player is within ACTIVE_R of the square, none otherwise.
##
## Beehave / Dialogue Manager: not used, because nobody here decides anything (a ping-pong walk
## between two points and a three-state flock); no lines are spoken.

const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Landmarks := preload("res://scripts/landmarks.gd")

## The square's middle, and how far from it the player must be for any of this to run.
const CENTRE := Vector2(-713.0, -1484.0)
const ACTIVE_R := 190.0
## Where tourists may stand: the square between the north houses, the wall and the castle.
const BOX := Rect2(-741.0, -1528.0, 56.0, 96.0)
const STANDING := 72
const STROLLING := 16
const PIGEONS := 24
const FLOCK_AT := Vector2(-716.0, -1494.0)
const FLOCK_R := 5.0
const SHIRTS := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#2b2c2f",
		"#c96b2c", "#5aa9c9", "#f2d13a", "#e8e4dc"]

## The flock sounds its wings through sfx.gd (main.gd connects this like eggs.flushed).
signal flushed(at: Vector3)

var map: Node3D
## Set by the game each frame: the vehicle, its velocity, whether it flies.
var player := Vector3.ZERO
var player_vel := Vector3.ZERO
var flying := false
## How long the last update took, for --bench.
var last_usec := 0

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _high := 0.0
var _awake := false

var _stand_mm: MultiMesh
var _stroll_mm: MultiMesh
var _stroll_a := PackedVector2Array()
var _stroll_b := PackedVector2Array()
var _stroll_u := PackedFloat32Array()
var _stroll_speed := PackedFloat32Array()
var _blocked: Array[Vector2] = []

enum Flock { GROUND, AIR, LANDING }
var _flock := Flock.GROUND
var _flock_t := 0.0
var _centre := Vector3.ZERO
var _home := PackedVector3Array()
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _yaw := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _ground_mm: MultiMesh
var _air_mm: MultiMesh


func setup(m: Node3D) -> void:
	map = m
	_rng.seed = 1644
	_high = (Landmarks.zamkowy_span(map) as Vector2).y
	# The cafe sets are no place to stand.
	var u := Landmarks.ZAMKOWY_SETS
	for k in range(0, u.size(), 3):
		_blocked.append(Vector2(u[k], u[k + 1]))
	_build_tourists()
	_build_pigeons()
	_wake(false)


## Open paving at p: no building or wall within `clear` metres, no cafe set within 1.6 m, and not
## by the column's own steps.
func _open(p: Vector2, clear: float) -> bool:
	var ground: float = map.ground_height(p.x, p.y)
	if map.top_height(p.x, p.y, clear) > ground + 0.5:
		return false
	if p.distance_to(Landmarks.ZYGMUNT) < 5.0:
		return false
	for b in _blocked:
		if p.distance_to(b) < 1.6:
			return false
	return true


func _floor(p: Vector2) -> Vector3:
	return Vector3(p.x, Landmarks.zamkowy_floor(map, p, _high), p.y)


func _person_mm(count: int, material: ShaderMaterial) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = Models.person_mesh()
	mm.instance_count = count
	InstanceBuffers.whiten(mm)
	mm.custom_aabb = AABB(Vector3(BOX.position.x, -2.0, BOX.position.y), Vector3(BOX.size.x, 8.0, BOX.size.y))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = material
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mm


func _shirt() -> Color:
	return Color(SHIRTS[_rng.randi() % SHIRTS.size()])


# --- the tourists ------------------------------------------------------------------------

func _build_tourists() -> void:
	_stand_mm = _person_mm(STANDING, Models.material())
	var walk_mat := Models.material().duplicate() as ShaderMaterial
	walk_mat.set_shader_parameter("walk", 0.16)
	_stroll_mm = _person_mm(STROLLING, walk_mat)
	# Standing: groups round a middle (a tour guide and her ring, friends photographing each
	# other) and a few couples and loners looking at the column.
	var placed := 0
	var tries := 0
	while placed < STANDING and tries < 600:
		tries += 1
		var g := BOX.position + Vector2(_rng.randf() * BOX.size.x, _rng.randf() * BOX.size.y)
		if not _open(g, 2.5):
			continue
		var size := mini(_rng.randi_range(2, 6), STANDING - placed)
		var at_column := g.distance_to(Landmarks.ZYGMUNT) < 22.0
		for k in size:
			var b := TAU * k / size + _rng.randf_range(-0.3, 0.3)
			var p := g + Vector2.from_angle(b) * (0.7 + 0.16 * size)
			if not _open(p, 0.8):
				p = g
			# Facing the group's middle, or the column when close to it.
			var face := (Landmarks.ZYGMUNT - p) if at_column and k % 2 == 0 else (g - p)
			var yaw := atan2(face.x, face.y) if face.length() > 0.1 else _rng.randf() * TAU
			var f := _floor(p)
			_stand_mm.set_instance_transform(placed, Transform3D(Basis(Vector3.UP, yaw), f))
			var shirt := _shirt()
			_stand_mm.set_instance_custom_data(placed, Color(shirt.r, shirt.g, shirt.b, 2.0 + _rng.randf() * 0.99))
			placed += 1
			if placed >= STANDING:
				break
	for i in range(placed, STANDING):
		_stand_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), _floor(CENTRE)))
	# Strolling: back and forth between two open spots on the square.
	for i in STROLLING:
		var a := Vector2.INF
		var b := Vector2.INF
		for t in 80:
			var p := BOX.position + Vector2(_rng.randf() * BOX.size.x, _rng.randf() * BOX.size.y)
			if _open(p, 1.2):
				if a == Vector2.INF:
					a = p
				elif p.distance_to(a) > 14.0 and p.distance_to(a) < 40.0 and _clear_line(a, p):
					b = p
					break
		if b == Vector2.INF:
			b = a
			a = CENTRE
		_stroll_a.append(a)
		_stroll_b.append(b)
		_stroll_u.append(_rng.randf())
		_stroll_speed.append(_rng.randf_range(0.8, 1.3))
		var shirt := _shirt()
		_stroll_mm.set_instance_custom_data(i, Color(shirt.r, shirt.g, shirt.b, _rng.randf() * 0.99))
	_strollers(0.0)


## True when the straight line from a to b stays on open paving (a stroller does not walk into
## a wall or a cafe table).
func _clear_line(a: Vector2, b: Vector2) -> bool:
	var n := ceili(a.distance_to(b) / 2.0)
	for k in range(1, n):
		if not _open(a.lerp(b, float(k) / n), 0.8):
			return false
	return true


func _strollers(dt: float) -> void:
	for i in STROLLING:
		var a := _stroll_a[i]
		var b := _stroll_b[i]
		var len := maxf(a.distance_to(b), 1.0)
		var u := _stroll_u[i] + dt * _stroll_speed[i] / len
		_stroll_u[i] = fposmod(u, 2.0)
		var s := _stroll_u[i]
		var forward := s < 1.0
		var f := s if forward else 2.0 - s
		var p := a.lerp(b, f)
		var dir := (b - a) if forward else (a - b)
		var yaw := atan2(dir.x, dir.y)
		_stroll_mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), _floor(p)))


# --- the pigeons -------------------------------------------------------------------------

func _build_pigeons() -> void:
	_centre = _floor(FLOCK_AT)
	for i in PIGEONS:
		var p := FLOCK_AT
		for t in 12:
			var a := _rng.randf() * TAU
			var q := FLOCK_AT + Vector2.from_angle(a) * sqrt(_rng.randf()) * FLOCK_R
			if _open(q, 0.5):
				p = q
				break
		var at := _floor(p)
		_home.append(at)
		_pos.append(at)
		_vel.append(Vector3.ZERO)
		_yaw.append(_rng.randf() * TAU)
		_phase.append(_rng.randf() * TAU)
	_ground_mm = _pigeon_mm(Props.pigeon(false))
	_air_mm = _pigeon_mm(Props.pigeon(true))
	_write_pigeons()


func _pigeon_mm(mesh: ArrayMesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = PIGEONS
	InstanceBuffers.whiten(mm)
	mm.custom_aabb = AABB(_centre - Vector3(80, 10, 80), Vector3(160, 80, 160))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = Models.material()
	mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mi)
	return mm


func _pigeons(dt: float) -> void:
	var flat := Vector2(player.x - _centre.x, player.z - _centre.z).length()
	var low := player.y - _centre.y < 35.0
	var scare := (flat < 13.0 and (player_vel.length() > 1.0 or flying)) or (flying and flat < 30.0 and low)
	_flock_t += dt
	match _flock:
		Flock.GROUND:
			if scare:
				_flock = Flock.AIR
				_flock_t = 0.0
				for i in PIGEONS:
					var away := Vector3(_pos[i].x - player.x, 0.0, _pos[i].z - player.z).normalized()
					if away == Vector3.ZERO:
						away = Vector3.FORWARD
					away = away.rotated(Vector3.UP, _rng.randf_range(-0.8, 0.8))
					_vel[i] = away * _rng.randf_range(3.0, 6.0) + Vector3.UP * _rng.randf_range(4.0, 7.0)
				flushed.emit(_centre)
		Flock.AIR:
			# Up to the rooftops, a wide lazy circle, and back once it is quiet.
			if _flock_t > 9.0 and flat > 28.0 and not scare:
				_flock = Flock.LANDING
				_flock_t = 0.0
		Flock.LANDING:
			if scare:
				_flock = Flock.AIR
				_flock_t = 0.0
				flushed.emit(_centre)
	for i in PIGEONS:
		var p := _pos[i]
		if _flock == Flock.GROUND:
			# Peck about: a step now and then, turning.
			if _rng.randf() < dt * 0.4:
				_yaw[i] += _rng.randf_range(-1.2, 1.2)
			var step := Vector3(-sin(_yaw[i]), 0.0, -cos(_yaw[i])) * 0.25 * dt * float(sin(_t * 2.0 + _phase[i]) > 0.3)
			var q := p + step
			if Vector2(q.x - _home[i].x, q.z - _home[i].z).length() < 1.8:
				p = q
			else:
				_yaw[i] += PI * dt
		elif _flock == Flock.AIR:
			var climb := clampf(16.0 + float(i % 5) * 2.0 - (p.y - _centre.y), -2.0, 4.0)
			var orbit := Vector3(-(p.z - _centre.z), 0.0, p.x - _centre.x).normalized() * 6.0
			var pull := Vector3(_centre.x - p.x, 0.0, _centre.z - p.z) * 0.06
			var want := orbit + pull + Vector3(0, climb, 0)
			_vel[i] = _vel[i].lerp(want, 1.0 - exp(-1.2 * dt))
			p += _vel[i] * dt
			_yaw[i] = atan2(-_vel[i].x, -_vel[i].z)
		else:
			var to := _home[i] - p
			var d := to.length()
			if d < 0.15:
				p = _home[i]
			else:
				_vel[i] = _vel[i].lerp(to / d * minf(7.0, d * 1.2 + 0.5), 1.0 - exp(-2.0 * dt))
				p += _vel[i] * dt
				_yaw[i] = atan2(-_vel[i].x, -_vel[i].z) if Vector2(_vel[i].x, _vel[i].z).length() > 0.3 else _yaw[i]
		_pos[i] = p
	if _flock == Flock.LANDING:
		var done := true
		for i in PIGEONS:
			if _pos[i].distance_to(_home[i]) > 0.15:
				done = false
				break
		if done:
			_flock = Flock.GROUND
	_write_pigeons()


func _write_pigeons() -> void:
	for i in PIGEONS:
		var p := _pos[i]
		var up: float = p.y - map.ground_height(p.x, p.z) if _flock != Flock.GROUND else 0.0
		var on_ground := up < 0.3
		var b := Basis(Vector3.UP, _yaw[i])
		var hidden := Transform3D(Basis.from_scale(Vector3.ZERO), p)
		if on_ground:
			# Pecking: the body tips forward every second or so.
			var peck := maxf(0.0, sin(_t * 5.0 + _phase[i] * 3.0)) * 0.5
			_ground_mm.set_instance_transform(i, Transform3D(b * Basis(Vector3.RIGHT, -peck), p))
			_air_mm.set_instance_transform(i, hidden)
		else:
			var flap := 0.45 + 0.55 * absf(sin(_t * 16.0 + _phase[i]))
			_air_mm.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3(flap, 1.0, 1.0)), p))
			_ground_mm.set_instance_transform(i, hidden)


# --- the frame ---------------------------------------------------------------------------

## Draws and runs only while the player is near; a flock in the air lands before it sleeps.
func _wake(on: bool) -> void:
	_awake = on
	visible = on
	set_process(on)


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_t += dt
	_strollers(dt)
	_pigeons(dt)
	last_usec = Time.get_ticks_usec() - t0


## Called by the game each frame (main.gd) with the player's place: sleeps the square when far.
func tick(pos: Vector3, vel: Vector3, fly: bool) -> void:
	player = pos
	player_vel = vel
	flying = fly
	var near := Vector2(pos.x - CENTRE.x, pos.z - CENTRE.y).length() < ACTIVE_R
	if near != _awake:
		_wake(near)
