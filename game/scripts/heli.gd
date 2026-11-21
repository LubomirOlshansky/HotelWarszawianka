extends Node3D
## Arcade rescue helicopter: flies towards where the stick points, holds a height
## above the ground, banks into turns, and treats buildings as solid by reading
## the city's roof-height grid (no physics queries).
##
## The position is the bottom of the skids: resting on a surface keeps the cabin
## about 1.5 m above it, and the skids never go below the ground, a bridge deck
## or a roof. When the city's lights are on (`lights`, set by the game) a red
## beacon and a white strobe blink, and a searchlight throws a pool on the ground.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

## Emitted when a landing asked for with `landing = true` touches down.
signal landed

const MAX_SPEED := 35.0      # m/s, about 126 km/h
const CRUISE := 45.0         # default height above the ground, metres
const MAX_HEIGHT := 360.0    # above the ground; Varso's spire tops out at 310 m
## The height cap (GAMEPLAY_PLAN 3.1, 2026-11-03): over most of the city the helicopter tops out
## at OPEN_CEILING, so the view stays on the city instead of the map's edge and the sky past it;
## near a tall building it may climb to that roof plus ROOF_CLEAR (Varso's spire: MAX_HEIGHT).
## The roofs are read CEILING_REACH m round the helicopter (`tallest_near`) every CEILING_EVERY s.
const OPEN_CEILING := 220.0
const ROOF_CLEAR := 60.0
const CEILING_REACH := 140.0
const CEILING_EVERY := 0.25
const CLIMB_RATE := 12.0     # m/s the wanted height moves while climb is held
const RADIUS := 3.0          # footprint tested against roofs (the fuselage, not the blade tips)
const STEP := 0.6            # a ledge this low is flown up onto instead of blocking
const PAD := 12.0            # metres kept from the map's edge
## See-through parts draw after the post-process quad: it repaints the screen from
## a copy taken before the transparent pass, which would wipe them out.
const AFTER_POST := 1

## Inputs, set every frame by the game: a world direction whose length (0..1)
## is the share of top speed, and -1..1 to sink or climb.
var input_dir := Vector3.ZERO
var climb := 0.0
## Fly straight down to whatever is below and emit `landed`.
var landing := false
## A car hangs under it on the sling (ev_tow.gd, 0..1): top speed LOAD_SLOW and the easing
## LOAD_EASE lower, so the load swings less and the machine feels its weight.
var sling := 0.0
const LOAD_SLOW := 0.25
const LOAD_EASE := 0.5

## The world, set by the game: ground or bridge deck under a point, and the top of
## anything (ground, deck, roof) within a radius of a point.
var ground_height: Callable = func(_x: float, _z: float) -> float: return 0.0
var top_height: Callable = func(_x: float, _z: float, _r: float) -> float: return 0.0
## The tallest roof in the square of a reach round a point (map_builder.gd `tallest_near`).
var tallest_near: Callable = func(_x: float, _z: float, _r: float) -> float: return 0.0
var bounds := Rect2(-1000, -1000, 2000, 2000)
## Map north (the L-shaped map, 2026-10-31): the corners of `bounds` that are not map, each grown
## by the 12 m pad (map_builder.gd `in_map(p, -PAD)` is false inside them); the game sets them
## (`set_map`). The clamp slides along their sides, so the helicopter can't fly over the empty
## north-east corner.
var keep_out: Array[Rect2] = []

## Horizontal velocity.
var vel := Vector3.ZERO
var vy := 0.0
## The height above the ground the helicopter holds; climb moves it.
var alt_target := CRUISE
## Skids above whatever is under the helicopter, and that surface's height.
var height_above := 0.0
var surface := 0.0
## Skids above the ground (not a roof): the camera frames by this, so it doesn't jump at a roof's edge.
var above_ground := 0.0
## The highest the helicopter may hold here (above the ground): see OPEN_CEILING.
var ceiling := MAX_HEIGHT
var _ceiling_wait := 0.0
## True on a frame where a building stopped the helicopter.
var blocked := false

## 0..1, how far the city's lights are on; the game sets it every frame.
var lights := 0.0
## A promo shot's helicopter (main.gd --promo-heli) flies itself towards this point (x, z) at
## auto_share of top speed and hovers there; INF: steered by the game's input as usual.
var auto_to := Vector2.INF
var auto_share := 0.6
var _beacon: StandardMaterial3D
var _strobe: StandardMaterial3D
var _search: MeshInstance3D
var _search_beam: MeshInstance3D
var _blink := 0.0
var _body: Node3D
var _rotor: Node3D
var _tail_rotor: Node3D
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _acc := Vector3.ZERO
var _spin := 0.0


func _ready() -> void:
	_body = _make_body()
	add_child(_body)
	_shadow = _make_shadow()
	add_child(_shadow)
	_make_lights()


## Puts the helicopter somewhere new without sliding there.
func place(at: Vector3, yaw: float, height_above_ground: float) -> void:
	global_position = at
	rotation.y = yaw
	vel = Vector3.ZERO
	vy = 0.0
	_acc = Vector3.ZERO
	landing = false
	alt_target = height_above_ground
	_ceiling_wait = 0.0
	_spin = 0.6
	reset_physics_interpolation()
	_shadow.reset_physics_interpolation()


func speed() -> float:
	return Vector2(vel.x, vel.z).length()


## 0..1, how fast the rotor turns (it spins up after take-off): the rotor sound's pitch.
func rotor_speed() -> float:
	return _spin


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _step(dt: float) -> void:
	var p := global_position
	if auto_to != Vector2.INF:
		var to := auto_to - Vector2(p.x, p.z)
		input_dir = Vector3(to.x, 0.0, to.y).normalized() * auto_share if to.length() > 8.0 else Vector3.ZERO
	var before := vel
	# A heavy machine, not a cursor: ease towards the wanted velocity.
	var want := Vector3.ZERO if landing else input_dir.limit_length(1.0) * MAX_SPEED * (1.0 - LOAD_SLOW * sling)
	vel = vel.lerp(want, 1.0 - exp(-1.3 * (1.0 - LOAD_EASE * sling) * dt))

	# Move sideways, but never into anything taller than the skids; slide along it instead.
	var nx := p.x + vel.x * dt
	var nz := p.z + vel.z * dt
	blocked = false
	if _solid(nx, nz, p.y):
		blocked = true
		if not _solid(nx, p.z, p.y):
			nz = p.z
			vel.z = 0.0
		elif not _solid(p.x, nz, p.y):
			nx = p.x
			vel.x = 0.0
		else:
			nx = p.x
			nz = p.z
			vel = Vector3.ZERO
	# Vector2 is single precision: a moved axis is one the clamp changed by more than its rounding.
	var kept := clamp_to_map(Vector2(p.x, p.z), Vector2(nx, nz))
	if absf(kept.x - nx) > 1e-3:
		vel.x = 0.0
		nx = kept.x
	if absf(kept.y - nz) > 1e-3:
		vel.z = 0.0
		nz = kept.y

	# Height: the wanted height follows the ground, but never sinks below what we are
	# over, so lifting off a tall roof answers the stick at once.
	var ground: float = ground_height.call(nx, nz)
	surface = top_height.call(nx, nz, RADIUS)
	_ceiling_wait -= dt
	if _ceiling_wait <= 0.0:
		_ceiling_wait = CEILING_EVERY
		ceiling = ceiling_at(nx, nz, ground)
	alt_target = clampf(alt_target + climb * CLIMB_RATE * dt, surface - ground, maxf(ceiling, surface - ground))
	var target_y := surface if landing else ground + alt_target
	var want_vy := clampf((target_y - p.y) * 1.5, -11.0, 13.0)
	vy = lerpf(vy, want_vy, 1.0 - exp(-3.0 * dt))
	var y := p.y + vy * dt
	if y < surface:
		y = surface
		vy = maxf(vy, 0.0)
	global_position = Vector3(nx, y, nz)
	height_above = y - surface
	above_ground = y - ground
	if landing and height_above < 0.05 and speed() < 1.0:
		landing = false
		alt_target = surface - ground
		landed.emit()

	_turn_and_tilt(dt, before)
	_spin = move_toward(_spin, 1.0, 0.5 * dt)
	_rotor.rotate_y(27.0 * _spin * dt)
	_tail_rotor.rotate_x(40.0 * _spin * dt)
	_update_shadow(nx, nz)
	_update_lights(dt, nx, nz)


## Map north: the bounds and the parts outside, as `map` (map_builder.gd) has them.
func set_map(map: Node3D) -> void:
	bounds = map.bounds
	keep_out.clear()
	for o: Rect2 in map.outside:
		keep_out.append(map._outside_grown(o, -PAD))


## Map north: where a move from `from` (on the map) to `to` ends, kept PAD m inside the map's
## outline: clamped to the bounds, then out of each part left outside along the side it crossed
## last (the one its sweep enters latest), so it slides along that side; at the inner corner
## it stops on whichever side it meets and slides on, never flicking between the two. A point
## already inside a part (a teleport) goes out by the nearest inner side.
func clamp_to_map(from: Vector2, to: Vector2) -> Vector2:
	var inside := bounds.grow(-PAD)
	var n := to.clamp(inside.position, inside.end)
	for g in keep_out:
		if not (n.x > g.position.x and n.x < g.end.x and n.y > g.position.y and n.y < g.end.y):
			continue
		# Each axis: the side `from` stands beyond (none if it stands within the part's span).
		var side_x := NAN
		if from.x <= g.position.x:
			side_x = g.position.x
		elif from.x >= g.end.x:
			side_x = g.end.x
		var side_z := NAN
		if from.y <= g.position.y:
			side_z = g.position.y
		elif from.y >= g.end.y:
			side_z = g.end.y
		if is_nan(side_x) and is_nan(side_z):
			# Out by the nearest of its sides inside the map (not one on the bounds).
			var best := INF
			var out := n
			var sides: Array[Vector2] = []
			if g.position.x > inside.position.x + 0.01:
				sides.append(Vector2(g.position.x, n.y))
			if g.end.x < inside.end.x - 0.01:
				sides.append(Vector2(g.end.x, n.y))
			if g.position.y > inside.position.y + 0.01:
				sides.append(Vector2(n.x, g.position.y))
			if g.end.y < inside.end.y - 0.01:
				sides.append(Vector2(n.x, g.end.y))
			for c in sides:
				if c.distance_to(n) < best:
					best = c.distance_to(n)
					out = c
			n = out
		elif is_nan(side_z):
			n.x = side_x
		elif is_nan(side_x):
			n.y = side_z
		else:
			# Both: the side whose line the move crosses later is the one it meets.
			var tx := (side_x - from.x) / (n.x - from.x) if n.x != from.x else -INF
			var tz := (side_z - from.y) / (n.y - from.y) if n.y != from.y else -INF
			if tx >= tz:
				n.x = side_x
			else:
				n.y = side_z
	return n


## The height cap at (x, z) over the ground `ground`: OPEN_CEILING, or the tallest roof within
## CEILING_REACH plus ROOF_CLEAR, never over MAX_HEIGHT.
func ceiling_at(x: float, z: float, ground: float) -> float:
	var top: float = tallest_near.call(x, z, CEILING_REACH)
	return clampf(top - ground + ROOF_CLEAR, OPEN_CEILING, MAX_HEIGHT)


## True when the top of anything near (x, z) stands above the skids at height y.
func _solid(x: float, z: float, y: float) -> bool:
	return float(top_height.call(x, z, RADIUS)) > y + STEP


func _turn_and_tilt(dt: float, before: Vector3) -> void:
	var resting := height_above < 0.1 and speed() < 1.0
	# Face the way we fly; when hovering, turn towards the stick.
	var face := Vector2(vel.x, vel.z)
	if face.length() < 4.0:
		face = Vector2(input_dir.x, input_dir.z)
	if face.length() > 0.05 and not resting:
		rotation.y = lerp_angle(rotation.y, atan2(-face.x, -face.y), 1.0 - exp(-2.2 * dt))
	# Bank into the turn and dip the nose when speeding up, from the smoothed acceleration.
	_acc = _acc.lerp((vel - before) / maxf(dt, 0.001), 1.0 - exp(-6.0 * dt))
	var fwd := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	var right := Vector3(cos(rotation.y), 0.0, -sin(rotation.y))
	var roll := clampf(-_acc.dot(right) * 0.045, -0.42, 0.42)
	var pitch := clampf(-vel.dot(fwd) / MAX_SPEED * 0.16 - _acc.dot(fwd) * 0.025, -0.35, 0.22)
	if resting:
		roll = 0.0
		pitch = 0.0
	_body.rotation.z = lerpf(_body.rotation.z, roll, 1.0 - exp(-5.0 * dt))
	_body.rotation.x = lerpf(_body.rotation.x, pitch, 1.0 - exp(-5.0 * dt))


## The blob shadow lies on whatever is right below: wider and fainter the higher we fly.
func _update_shadow(x: float, z: float) -> void:
	var under: float = top_height.call(x, z, 0.0)
	var h := clampf((global_position.y - under) / 150.0, 0.0, 1.0)
	var grow := 1.0 + 0.8 * h
	_shadow.global_transform = Transform3D(Basis(Vector3.UP, rotation.y).scaled(Vector3(2.6 * grow, 1.0, 5.6 * grow)),
			Vector3(x, under + 0.45, z))
	_shadow_mat.albedo_color.a = lerpf(0.6, 0.36, h)


## Beacon (red, on the fin), strobe (white, under the belly) and the searchlight:
## a pool on whatever is below, a little ahead, and a faint beam down to it.
func _make_lights() -> void:
	_beacon = _glow_box(Vector3(0.22, 0.16, 0.22), Vector3(0, 2.26, 6.75), Color("#ff2a1c"))
	_strobe = _glow_box(Vector3(0.2, 0.08, 0.2), Vector3(0, -0.82, 0.6), Color("#f4f6ff"))
	var glow := load("res://scripts/models.gd").glow_material() as ShaderMaterial
	_search = MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 20
	for i in n:
		for v in [[Vector3.ZERO, 0.55], [Vector3(cos(TAU * i / n), 0, sin(TAU * i / n)), 0.0],
				[Vector3(cos(TAU * (i + 1) / n), 0, sin(TAU * (i + 1) / n)), 0.0]]:
			st.set_color(Color(1.0, 0.95, 0.82, v[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	_search.mesh = st.commit()
	_search.material_override = glow.duplicate()
	_search.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_search.top_level = true
	_search.visible = false
	add_child(_search)
	# The beam: a cone from the apex (origin) down to a unit circle at y = -1.
	_search_beam = MeshInstance3D.new()
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		for v in [[Vector3.ZERO, 0.16], [Vector3(cos(TAU * i / n), -1, sin(TAU * i / n)), 0.03],
				[Vector3(cos(TAU * (i + 1) / n), -1, sin(TAU * (i + 1) / n)), 0.03]]:
			st.set_color(Color(1.0, 0.95, 0.85, v[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	_search_beam.mesh = st.commit()
	var beam_mat := glow.duplicate() as ShaderMaterial
	beam_mat.set_shader_parameter("lift", 0.0)
	_search_beam.material_override = beam_mat
	_search_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_search_beam.top_level = true
	_search_beam.visible = false
	add_child(_search_beam)


func _glow_box(size: Vector3, pos: Vector3, colour: Color) -> StandardMaterial3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour.darkened(0.5)
	mat.emission_enabled = true
	mat.emission = colour
	mat.emission_energy_multiplier = 0.0
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	_body.add_child(mi)
	return mat


## Blinks the beacon and strobe and lays the searchlight on the ground at night.
func _update_lights(dt: float, x: float, z: float) -> void:
	var night := lights > 0.001
	_search.visible = night
	_search_beam.visible = night
	if not night:
		_beacon.emission_energy_multiplier = 0.0
		_strobe.emission_energy_multiplier = 0.0
		return
	_blink = fmod(_blink + dt, 1.2)
	_beacon.emission_energy_multiplier = 5.0 if _blink < 0.5 else 0.0
	_strobe.emission_energy_multiplier = 8.0 if fmod(_blink, 0.6) < 0.06 else 0.0
	var ahead := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	var px := x + ahead.x * 7.0
	var pz := z + ahead.z * 7.0
	var under: float = top_height.call(px, pz, 0.0)
	var drop := maxf(global_position.y + 0.6 - under, 0.5)
	var r := clampf(3.0 + drop * 0.12, 3.0, 14.0)
	_search.global_transform = Transform3D(Basis.from_scale(Vector3(r, 1.0, r * 1.15)), Vector3(px, under + 0.4, pz))
	# Fades with height: high up, the beam spreads thin.
	var strength := clampf(1.4 - drop / 120.0, 0.35, 1.2)
	(_search.material_override as ShaderMaterial).set_shader_parameter("strength", strength)
	var apex := global_position + Vector3(0, 0.9, 0) + ahead * 1.6
	var foot := Vector3(px, under + 0.4, pz)
	var down := foot - apex
	var side := down.cross(Vector3.UP if absf(down.normalized().y) < 0.99 else Vector3.RIGHT).normalized() * r * 0.8
	var front := side.cross(down).normalized() * r * 0.8
	_search_beam.global_transform = Transform3D(Basis(side, -down, front), apex)


func _make_shadow() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for i in n:
		# Clockwise seen from above (Godot's front faces), so the disc faces up.
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(cos(TAU * i / n), 0.0, sin(TAU * i / n)))
		st.add_vertex(Vector3(cos(TAU * (i + 1) / n), 0.0, sin(TAU * (i + 1) / n)))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	_shadow_mat = StandardMaterial3D.new()
	_shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shadow_mat.albedo_color = Color(0.05, 0.05, 0.08, 0.6)
	_shadow_mat.render_priority = AFTER_POST
	mi.material_override = _shadow_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Placed in world space, so it doesn't lean with the helicopter.
	mi.top_level = true
	return mi


func _make_body() -> Node3D:
	# A red-and-white rescue helicopter from boxes, readable at pixel scale. No
	# markings. The front is -Z; the pivot sits in the cabin so it tilts naturally.
	var root := Node3D.new()
	root.position.y = 1.6
	var o := Vector3(0, -1.6, 0)
	var red := Color("#c8322b")
	var white := Color("#f2efe8")
	var glass := Color("#2f3f52")
	var dark := Color("#2a2b2e")
	var metal := Color("#5c5f64")
	_box(root, Vector3(1.9, 1.5, 3.6), o + Vector3(0, 1.6, -0.2), red)           # cabin
	_box(root, Vector3(1.94, 0.45, 3.4), o + Vector3(0, 1.05, -0.2), white)      # white belly
	_box(root, Vector3(1.6, 1.15, 1.2), o + Vector3(0, 1.45, -2.4), red)         # nose
	_box(root, Vector3(1.64, 0.36, 1.2), o + Vector3(0, 1.04, -2.4), white)
	_box(root, Vector3(1.56, 0.75, 1.0), o + Vector3(0, 2.0, -2.05), glass)      # windscreen
	_box(root, Vector3(1.96, 0.55, 1.4), o + Vector3(0, 1.95, -0.85), glass)     # side windows
	_box(root, Vector3(1.25, 0.6, 2.4), o + Vector3(0, 2.6, 0.3), white)         # engine cowling
	_box(root, Vector3(0.22, 0.5, 0.22), o + Vector3(0, 3.1, -0.2), dark)        # mast
	_box(root, Vector3(0.55, 0.55, 4.8), o + Vector3(0, 2.15, 3.9), red)         # tail boom
	_box(root, Vector3(0.58, 0.14, 4.6), o + Vector3(0, 1.93, 3.9), white)       # boom stripe
	_box(root, Vector3(0.14, 1.7, 1.0), o + Vector3(0, 2.9, 6.7), red)           # fin
	_box(root, Vector3(0.16, 0.35, 1.02), o + Vector3(0, 3.6, 6.75), white)      # fin tip
	_box(root, Vector3(2.2, 0.1, 0.55), o + Vector3(0, 2.2, 5.9), white)         # stabiliser
	for x in [-1.15, 1.15]:
		_box(root, Vector3(0.14, 0.12, 4.4), o + Vector3(x, 0.06, -0.2), metal)  # skids
		_box(root, Vector3(0.14, 0.14, 0.3), o + Vector3(x, 0.18, -2.45), metal) # skid tips
		for z in [-1.2, 0.9]:
			_box(root, Vector3(0.1, 0.75, 0.1), o + Vector3(x, 0.45, z), metal)  # struts
	for z in [-1.2, 0.9]:
		_box(root, Vector3(2.4, 0.1, 0.12), o + Vector3(0, 0.82, z), metal)      # cross tubes

	_rotor = Node3D.new()
	_rotor.position = o + Vector3(0, 3.4, -0.2)
	root.add_child(_rotor)
	_box(_rotor, Vector3(0.45, 0.2, 0.45), Vector3.ZERO, dark)
	for k in 4:
		var arm := Node3D.new()
		arm.rotation.y = k * PI * 0.5
		_rotor.add_child(arm)
		_box(arm, Vector3(0.32, 0.05, 4.9), Vector3(0, 0, 2.65), dark)
	# A faint disc where the blades sweep, so the rotor reads as spinning fast.
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 5.1
	cyl.bottom_radius = 5.1
	cyl.height = 0.02
	cyl.radial_segments = 24
	cyl.rings = 1
	var blur := StandardMaterial3D.new()
	blur.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blur.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blur.albedo_color = Color(0.16, 0.17, 0.19, 0.16)
	blur.render_priority = AFTER_POST
	cyl.material = blur
	disc.mesh = cyl
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position = o + Vector3(0, 3.42, -0.2)
	root.add_child(disc)

	_tail_rotor = Node3D.new()
	_tail_rotor.position = o + Vector3(0.2, 2.95, 6.95)
	root.add_child(_tail_rotor)
	for k in 2:
		var arm := Node3D.new()
		arm.rotation.x = k * PI * 0.5
		_tail_rotor.add_child(arm)
		_box(arm, Vector3(0.05, 1.5, 0.16), Vector3.ZERO, dark)
	return root


func _box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.8
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
