extends Node3D
## The University guards' cart (F's ask and photo 8074, 2026-11-15; docs/landmarks/specs/uw_kampus.md
## section 11): "Straż Uniwersytecka 001", a small white boxy electric cart with black pillars, a
## black roof frame and a light bar, driving round the main campus behind the gate on
## Krakowskie Przedmieście.
##
## - **The way** (`LOOP`): the campus's service road ring round the middle lawn (OSM, the
##   2026-11-15 map), copied here so both city paths have it: east along the Old Library's front to
##   Pałac Kazimierzowski, back past the Auditorium Maximum, a stop of PAUSE s at the guards' kiosk
##   (`PAUSE_AT`) every lap. It runs at SPEED (12 km/h), slower round the bends.
## - **The car**: it waits while the player's car (or the helicopter on the ground) stands in its way
##   (`blocked`: within GAP m ahead, inside its lane), and the guard says something after WAIT s;
##   a car racing past within NEAR m at over FAST km/h gets a line too. Lines in dialogue.json's
##   `uw_guard` (Polish with English), tags "blocked" and "fast".
## - **The cost**: one AnimatableBody3D with one mesh (the actor material, +1 draw call in view) and
##   a box collider; it moves only while the view is within ACTIVE m of the campus, otherwise it is
##   hidden and stands still. A tick every frame while active (one transform), the checks at TICK.
## Not a traffic Driver (city-ai.md section 7, 2): the ring is service roads with no lights and no
## other traffic, and the traffic's lanes would send it out onto Krakowskie.

const Models := preload("res://scripts/models.gd")

## The ring (x, z pairs), counter-clockwise from the guards' kiosk: the OSM service roads round
## the lawn (the one-way pieces as OSM draws them).
const LOOP := [-397.1, -679.8, -397.5, -674.8, -396.3, -671.1, -394.4, -667.7, -392.1, -664.7, -385.0, -660.7,
		-371.1, -658.1, -342.0, -670.0, -325.6, -677.2, -277.2, -698.6, -268.5, -702.6, -282.6, -733.7,
		-288.9, -747.3, -345.3, -720.9, -380.0, -704.9, -388.6, -696.5]
## Where it stops each lap (beside the kiosk, photo 8074) and for how long (s).
const PAUSE_AT := Vector2(-393.5, -687.5)
const PAUSE := 25.0
const SPEED := 3.4
## Its box (width, height, length) and the light bar's height.
const SIZE := Vector3(1.45, 1.95, 2.7)
## The player in its way: within GAP m ahead of its nose and LANE m of its line.
const GAP := 6.0
const LANE := 2.2
## A line after WAIT s blocked; a car past within NEAR m at over FAST km/h; one line per QUIET s.
const WAIT := 2.5
const NEAR := 10.0
const FAST := 35.0
const QUIET := 18.0
## The view farther than ACTIVE m from the ring's middle: hidden and still.
const ACTIVE := 260.0
const CENTRE := Vector2(-335.0, -702.0)
const TICK := 0.2
const BUBBLE := Color("#dfe7f2")

const WHITE := Color("#f2f2ee")
const BLACK := Color("#1d1e21")
const BADGE := Color("#2c4a8a")

## The world's map (heights), the dialogue (lines), the view's centre, the vehicle:
## [position, km/h, flying] (main.gd).
var map: Node
var dialogue: Node
var focus: Callable
var vehicle: Callable
## --campus-log: `campus cart:` lines.
var log_on := false
## Microseconds spent, for --bench.
var spent_usec := 0
## Where it is: metres along the ring, the pause left, the time it has been blocked.
var s := 0.0
var pause_left := 0.0
var blocked_for := 0.0
var lines_said := 0
var laps := 0

var body: AnimatableBody3D
var _shape: CollisionShape3D
var _pts := PackedVector2Array()
var _cum := PackedFloat32Array()
var _len := 0.0
var _pause_s := 0.0
var _passed_pause := false
var _t := 0.0
var _quiet := 0.0
var _blocked := false


func setup() -> void:
	_pts = ring()
	_cum = cumulative(_pts)
	_len = _cum[_cum.size() - 1]
	_pause_s = nearest_s(_pts, _cum, PAUSE_AT)
	s = _pause_s + 1.0
	body = AnimatableBody3D.new()
	body.name = "CampusCart"
	body.sync_to_physics = false
	body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mi := MeshInstance3D.new()
	mi.mesh = cart_mesh()
	mi.material_override = Models.material()
	body.add_child(mi)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE
	_shape.shape = box
	_shape.position.y = SIZE.y * 0.5
	body.add_child(_shape)
	add_child(body)
	_place()


# --- the rules (static: check_campus.gd runs them) ---------------------------------------------

## The ring as points, closed (the last point joins the first).
static func ring() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, LOOP.size() - 1, 2):
		out.append(Vector2(LOOP[i], LOOP[i + 1]))
	out.append(out[0])
	return out


static func cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var cum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
	return cum


## The point `at` metres along the ring (wrapped) and the heading there.
static func point_at(pts: PackedVector2Array, cum: PackedFloat32Array, at: float) -> Array:
	var total := cum[cum.size() - 1]
	var d := fposmod(at, total)
	var k := 0
	while k < cum.size() - 2 and cum[k + 1] < d:
		k += 1
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var dir := (pts[k + 1] - pts[k]) / seg
	return [pts[k] + dir * (d - cum[k]), dir]


## Metres along the ring of the point nearest `p`.
static func nearest_s(pts: PackedVector2Array, cum: PackedFloat32Array, p: Vector2) -> float:
	var best := INF
	var at := 0.0
	for k in pts.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, pts[k], pts[k + 1])
		if q.distance_to(p) < best:
			best = q.distance_to(p)
			at = cum[k] + q.distance_to(pts[k])
	return at


## Is something at `p` in the cart's way (the cart at `at` heading `dir`)?
static func blocked(at: Vector2, dir: Vector2, p: Vector2) -> bool:
	var rel := p - at
	var ahead := rel.dot(dir)
	return ahead > SIZE.z * 0.3 and ahead < SIZE.z * 0.5 + GAP and absf(rel.dot(Vector2(-dir.y, dir.x))) < LANE


## Its speed round a bend: SPEED on the straight, down to half where the ring turns sharply
## within 6 m ahead.
static func speed_at(pts: PackedVector2Array, cum: PackedFloat32Array, at: float) -> float:
	var a: Array = point_at(pts, cum, at)
	var b: Array = point_at(pts, cum, at + 6.0)
	var turn := absf((a[1] as Vector2).angle_to(b[1]))
	return SPEED * clampf(1.0 - turn / PI, 0.5, 1.0)


# --- the tick ----------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if body == null:
		return
	var t0 := Time.get_ticks_usec()
	var f3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var on := Vector2(f3.x, f3.z).distance_to(CENTRE) < ACTIVE
	if body.visible != on:
		body.visible = on
		_shape.disabled = not on
	if not on:
		return
	_t += dt
	_quiet -= dt
	if _t >= TICK:
		_check(_t)
		_t = 0.0
	if pause_left > 0.0:
		pause_left -= dt
	elif not _blocked:
		var before := s
		s += speed_at(_pts, _cum, s) * dt
		# The kiosk's stop, once a lap.
		if fposmod(before - _pause_s, _len) > fposmod(s - _pause_s, _len):
			pause_left = PAUSE
			laps += 1
			if log_on:
				print("campus cart: lap %d, a stop at the kiosk" % laps)
		s = fposmod(s, _len)
		_place()
	spent_usec += Time.get_ticks_usec() - t0


func _place() -> void:
	var p: Array = point_at(_pts, _cum, s)
	var at: Vector2 = p[0]
	var dir: Vector2 = p[1]
	var y: float = map.ground_height(at.x, at.y) if map != null else 0.0
	# Its front is at -Z: -Z points along `dir`.
	var yaw := atan2(-dir.x, -dir.y)
	body.global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, y, at.y))


## The player in its way, the guard's lines (5 Hz).
func _check(step: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var c3: Vector3 = v[0]
	var car := Vector2(c3.x, c3.z)
	var p: Array = point_at(_pts, _cum, s)
	var at: Vector2 = p[0]
	var low: bool = not bool(v[2]) or c3.y - (map.ground_height(car.x, car.y) if map != null else 0.0) < 1.5
	_blocked = low and blocked(at, p[1], car)
	blocked_for = blocked_for + step if _blocked else 0.0
	if _quiet > 0.0:
		return
	if blocked_for >= WAIT:
		_say("blocked")
	elif not bool(v[2]) and float(v[1]) > FAST and car.distance_to(at) < NEAR:
		_say("fast")


func _say(tag: String) -> void:
	_quiet = QUIET
	if dialogue == null:
		return
	var b := body
	var anchor := func() -> Vector3: return b.global_position + Vector3.UP * SIZE.y if is_instance_valid(b) else Vector3.INF
	var l: Array = dialogue.say_ambient(anchor, "Straż Uniwersytecka", "uw_guard", tag, 4.0, BUBBLE, 2.2, true)
	if not l.is_empty():
		lines_said += 1
		if log_on:
			print("campus cart: line %s: %s" % [tag, l[0]])


## The `campus cart:` summary line (--campus-log).
func summary() -> String:
	var p: Array = point_at(_pts, _cum, s)
	return "campus cart: at %.0f, %.0f, %.0f m along the %.0f m ring, %d laps, %d lines" % [
			(p[0] as Vector2).x, (p[0] as Vector2).y, s, _len, laps, lines_said]


# --- the look ----------------------------------------------------------------------------------

## The cart from photo 8074: white body on black wheels, black pillars and roof frame, glass all
## round, a black bumper, two head lamps, the light bar on the roof (its amber half lit), the
## badge and "001" on the doors. Front at -Z. One surface on the actor material.
static func cart_mesh() -> ArrayMesh:
	var sh := Models.Shape.new()
	var white := Models.fin(WHITE)
	var black := Models.fin(BLACK)
	var glass := Models.fin(Models.GLASS)
	var hw := SIZE.x * 0.5
	var hl := SIZE.z * 0.5
	# The tub: white lower body over a black sill, a black bumper at each end.
	sh.box(Vector3(0.0, 0.32, 0.0), Vector3(SIZE.x - 0.08, 0.16, SIZE.z - 0.1), black)
	sh.box(Vector3(0.0, 0.72, 0.0), Vector3(SIZE.x, 0.64, SIZE.z), white)
	sh.box(Vector3(0.0, 0.42, -hl - 0.04), Vector3(SIZE.x - 0.1, 0.22, 0.12), black)
	sh.box(Vector3(0.0, 0.42, hl + 0.04), Vector3(SIZE.x - 0.1, 0.22, 0.12), black)
	# The cab: glass sides and screens between black pillars, the black roof frame on top.
	sh.box(Vector3(0.0, 1.42, 0.05), Vector3(SIZE.x - 0.06, 0.76, SIZE.z - 0.5), glass)
	for z: float in [-hl + 0.28, -0.1, hl - 0.2]:
		for sx: float in [-1.0, 1.0]:
			sh.box(Vector3(sx * (hw - 0.05), 1.42, z), Vector3(0.09, 0.78, 0.09), black)
	sh.box(Vector3(0.0, 1.83, 0.05), Vector3(SIZE.x, 0.07, SIZE.z - 0.42), black)
	# White door panels under the glass on each side, the badge and the number on them.
	for sx: float in [-1.0, 1.0]:
		sh.box(Vector3(sx * (hw + 0.005), 1.12, -0.35), Vector3(0.01, 0.16, 0.9), white)
		sh.box(Vector3(sx * (hw + 0.012), 0.82, -0.35), Vector3(0.012, 0.16, 0.13), Models.fin(BADGE))
		sh.box(Vector3(sx * (hw + 0.012), 0.82, 0.25), Vector3(0.012, 0.07, 0.3), black)
	# Head lamps, the tail lamps, the light bar (amber and white).
	for sx: float in [-1.0, 1.0]:
		sh.box(Vector3(sx * (hw - 0.22), 0.86, -hl - 0.01), Vector3(0.22, 0.12, 0.03), Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP))
		sh.box(Vector3(sx * (hw - 0.18), 0.86, hl + 0.01), Vector3(0.14, 0.12, 0.03), Models.fin(Models.TAIL, Models.TAIL_LAMP))
	sh.box(Vector3(0.0, 1.9, -0.35), Vector3(0.9, 0.08, 0.2), black)
	sh.box(Vector3(-0.25, 1.98, -0.35), Vector3(0.36, 0.1, 0.17), Models.fin(Color("#ffb21e"), Models.LIT_SIGN))
	sh.box(Vector3(0.25, 1.98, -0.35), Vector3(0.36, 0.1, 0.17), Models.fin(Color("#f3f3ef"), Models.FIXED))
	# Four small wheels.
	for sx: float in [-1.0, 1.0]:
		for z: float in [-hl + 0.45, hl - 0.45]:
			sh.wheel(Vector3(sx * (hw - 0.12), 0.27, z), 0.27, 0.2, 8, sx, Models.fin(Models.TYRE), Models.fin(Models.HUB))
	return sh.mesh()
