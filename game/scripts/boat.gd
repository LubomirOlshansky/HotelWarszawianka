extends Node3D
## The boat race's boats (docs/design/boat-race.md, F's ask 2026-11-06): the player's runabout, the
## rivals' boats and jet ski. An arcade planing model on the water plane, the same for the player
## and the rivals (they get no physics of their own, only better or worse inputs):
##
## - Thrust along the heading, fading to nothing at the top speed; a brake that turns into reverse.
## - The hull's grip across the heading is low at rest and grows as the boat gets up on the plane
##   (`plane`), so a turn at speed slides out a little first and then bites (Wave Race's feel).
## - The rudder needs water flowing past it: no turn at rest, the most at mid speed, a bit less flat
##   out. In the air almost none.
## - The Vistula's current carries everything downstream at `flow` (set by the race, about 1 m/s).
## - The water's height (`wave`, the race's chop plus every boat's and the barge's wake rings) lifts
##   and tilts the hull; a crest met fast throws the boat up (`air`), it lands with a splash and
##   loses a bit of speed if it came down hard.
## - The banks (map_builder.gd `shore_distance`, a distance field) and solid things (`solid`, the
##   race's test against the bridge piers, the barges, the marina) push the boat out and take the
##   speed into the wall away.
##
## Inputs, set each frame by the game (drive_controls.gd writes the same four fields as for the
## car) or by the race's rival driver: `throttle` 0..1, `braking`, `steer` -1..1 (right +), or a
## `target_dir` (Point / Fixed schemes: the boat turns towards it).
##
## Frame: +Z forward (the mesh, `yaw` from +Z towards +X), origin at the waterline.

enum Kind { RUNABOUT, TUB, JETSKI, SKUTER, ELECTRIC, OFFSHORE }

## Per kind: top speed (m/s), pull at rest (m/s²), turn (rad/s), grip across at rest and on the
## plane (1/s), the speed where it planes (m/s), mass (bumps), radius (m), length (m), the wake's
## height at top speed (m). *guess*, tuned by check_boat_race.gd and feel.
const SPECS := {
	Kind.RUNABOUT: {"top": 21.0, "pull": 6.5, "turn": 1.55, "grip0": 1.1, "grip1": 3.2, "plane": 9.0,
			"mass": 1.0, "r": 2.1, "len": 5.4, "wake": 0.32},
	Kind.TUB: {"top": 19.3, "pull": 4.6, "turn": 1.25, "grip0": 2.0, "grip1": 4.2, "plane": 8.0,
			"mass": 1.8, "r": 2.6, "len": 6.4, "wake": 0.42},
	Kind.JETSKI: {"top": 22.6, "pull": 8.0, "turn": 2.1, "grip0": 0.9, "grip1": 2.6, "plane": 7.0,
			"mass": 0.55, "r": 1.4, "len": 3.2, "wake": 0.2},
	# The free-ride fleet at the start pontoon (F 2026-11-07, his three photos), each with its own
	# feel through the optional keys below:
	# - SKUTER "Rekin X", a 3.4 m black-and-red jet ski: light, twitchy, slides; jet steering
	#   (it turns only with thrust: let go of the gas and it runs straight), leans hard, jumps
	#   off the smallest wake, lands soft.
	# - ELECTRIC "Srebrna Strzała", a 7.5 m silver electric runabout: full torque to the top
	#   (falloff power 5: no fade until the very end), stays flat and grippy, a gentle turn.
	# - OFFSHORE "Czarna Pantera", a 13 m black offshore boat on five outboards: heavy and slow off
	#   the line until it planes, then the fastest thing on the river; a wide slow turn, a big
	#   wake, it hardly notices other wakes and keeps its speed on a hard landing.
	Kind.SKUTER: {"top": 20.0, "pull": 9.5, "turn": 2.5, "grip0": 0.7, "grip1": 2.2, "plane": 6.0,
			"mass": 0.6, "r": 1.4, "len": 3.4, "wake": 0.22, "jet": true, "roll": 1.8, "launch": 1.6,
			"land_keep": 0.95, "bleed": 0.03},
	Kind.ELECTRIC: {"top": 17.5, "pull": 7.5, "turn": 1.45, "grip0": 1.8, "grip1": 4.2, "plane": 7.5,
			"mass": 1.3, "r": 2.2, "len": 7.5, "wake": 0.3, "falloff": 5.0, "roll": 0.6, "bow": 0.4,
			"launch": 3.0},
	Kind.OFFSHORE: {"top": 27.0, "pull": 3.0, "pull_plane": 2.4, "turn": 0.95, "grip0": 1.4, "grip1": 3.0,
			"plane": 11.0, "mass": 3.2, "r": 3.0, "len": 13.0, "wake": 0.75, "roll": 0.7, "bow": 1.8,
			"launch": 4.2, "land_keep": 0.97, "bleed": 0.09, "feel": 0.45},
}
const DRAG := 0.06           # water drag on top of the thrust curve (1/s)
const REVERSE := 4.0         # m/s back
const BRAKE := 9.0           # m/s² while going forward and braking
const GRAVITY := 15.0        # arcade: a hop lasts a moment, not a second
const LAUNCH := 2.4          # m/s up the face of a wave that throws the boat in the air
const HARD_LANDING := 4.0    # m/s down: a landing harder than this costs speed
const BOW_UP := 0.07         # rad: the bow up while it climbs onto the plane
const ROLL := 0.22           # rad of lean per rad/s of turn
const PUSH := 0.35           # share of the speed into a wall that bounces back
## A boat nosed into a bank at full throttle barely moves, so its rudder has no flow: for
## CONTACT_HOLD s after a touch, with the throttle on, the rudder keeps this much bite (the
## prop wash over it), so the player can turn off the bank instead of having to reverse.
const CONTACT_BITE := 0.55
const CONTACT_HOLD := 0.8
## A boat still pinned on a bank or the pontoon after PIN_TIME s of throttle (a long hull whose
## rudder can't swing it off) gets pushed back off the contact at PIN_PUSH m/s, so the player is
## never left grinding there (Autopilot, 2026-11-07: Czarna Pantera sat 12 s at 0.4 km/h).
const PIN_TIME := 1.2
const PIN_PUSH := 3.0

## The kind's spec, and the boost the race grants (rhythm, gold rings): top speed × `boost`.
var kind := Kind.RUNABOUT
var spec: Dictionary = SPECS[Kind.RUNABOUT]
var boost := 1.0

## Inputs.
var throttle := 0.0
var braking := false
var steer := 0.0
var target_dir := Vector3.ZERO

## State on the water: position (x, z), heading, velocity (x, z, over the ground), turn rate,
## height of the hull over the water's rest level and its vertical speed.
var pos := Vector2.ZERO
var yaw := 0.0
var vel := Vector2.ZERO
var yaw_rate := 0.0
var y := 0.0
var vy := 0.0
var air := false
var pitch := 0.0
var roll := 0.0
## 0..1, how far up on the plane.
var planing := 0.0
## Set by the race: the water's rest level, the current, and the world tests.
var water_y := 0.0
var flow := Vector2.ZERO
## (x, z) -> extra water height (the chop and the wakes), m.
var wave: Callable = func(_x: float, _z: float) -> float: return 0.0
## (x, z) -> metres into the water (0 on land): map_builder.gd `shore_distance`.
var shore: Callable = func(_x: float, _z: float) -> float: return 99.0
## (centre: Vector3, radius) -> push-out Vector2 (ZERO when clear): the race's physics test.
var solid: Callable = Callable()

## Events of the last step, for the race (sound, haptics, lines): a bump's strength (m/s into
## the wall or boat), a landing's strength.
var bumped := 0.0
var _contact := 0.0
var _contact_n := Vector2.ZERO
var _pinned := 0.0
var landed := 0.0
## The race's boats on the same water (for the boat-to-boat bumps).
var others: Array = []

var _body: Node3D
var _mesh: MeshInstance3D


func setup(k: int, mesh: ArrayMesh, material: Material) -> void:
	kind = k
	spec = SPECS[k]
	_body = Node3D.new()
	add_child(_body)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = material
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_mesh)


## Swap the hull's mesh (a free-ride boat: parked empty, or with the player at the wheel).
func set_mesh(mesh: ArrayMesh) -> void:
	_mesh.mesh = mesh


func place(at: Vector2, heading: float) -> void:
	pos = at
	yaw = heading
	vel = Vector2.ZERO
	yaw_rate = 0.0
	_contact = 0.0
	_pinned = 0.0
	y = 0.0
	vy = 0.0
	air = false
	planing = 0.0
	boost = 1.0
	throttle = 0.0
	steer = 0.0
	braking = false
	target_dir = Vector3.ZERO
	_sync()


func forward() -> Vector2:
	return Vector2(sin(yaw), cos(yaw))


func speed() -> float:
	return vel.length()


func forward_speed() -> float:
	return (vel - flow).dot(forward())


func radius() -> float:
	return float(spec["r"])


func top() -> float:
	return float(spec["top"]) * boost


## One step of the boat's motion (the race calls it for every boat, in order).
func step(dt: float) -> void:
	bumped = 0.0
	landed = 0.0
	var f := forward()
	var right := Vector2(f.y, -f.x)
	# Over the water (the current takes the boat along; the hull works against the water).
	var rel := vel - flow
	var vf := rel.dot(f)
	var vr := rel.dot(right)
	var top_v := top()
	var on_water := not air
	# Thrust and braking.
	var thr := clampf(throttle, 0.0, 1.0)
	if target_dir != Vector3.ZERO:
		var want := Vector2(target_dir.x, target_dir.z)
		thr = clampf(want.length() / 0.75, 0.0, 1.0)
		var err := wrapf(atan2(want.x, want.y) - yaw, -PI, PI)
		steer = clampf(err * 1.8, -1.0, 1.0)
		if absf(err) > 2.2 and vf > 3.0:
			thr = 0.0
	if on_water:
		if braking:
			if vf > 0.5:
				vf -= BRAKE * dt
			else:
				vf = maxf(vf - float(spec["pull"]) * 0.5 * dt, -REVERSE)
		elif thr > 0.0 and vf < top_v:
			var share := clampf(vf / top_v, 0.0, 1.0)
			# The thrust curve: falloff 2 for a propeller (fades towards the top), higher for an
			# electric motor (full torque almost to the top); pull_plane: a heavy hull pulls
			# weakly until it is up on the plane.
			var pull := float(spec["pull"]) * lerpf(1.0, float(spec.get("pull_plane", 1.0)), planing)
			vf += pull * thr * (1.0 - pow(share, float(spec.get("falloff", 2.0)))) * dt
		vf -= vf * DRAG * dt
		if vf > top_v:
			vf = lerpf(vf, top_v, 1.0 - exp(-1.5 * dt))
	# Grip across: low at rest, high on the plane, almost none in the air.
	planing = smoothstep(float(spec["plane"]) * 0.45, float(spec["plane"]), absf(vf))
	var grip := lerpf(float(spec["grip0"]), float(spec["grip1"]), planing) if on_water else 0.25
	vr *= exp(-grip * dt)
	# A hard turn on the plane bleeds speed (the hull digs in).
	if on_water:
		vf -= absf(yaw_rate) * absf(vf) * float(spec.get("bleed", 0.06)) * dt
	rel = f * vf + right * vr
	# The rudder.
	var authority := clampf(absf(vf) / 5.0, 0.0, 1.0) * (1.0 - 0.3 * clampf((absf(vf) - 12.0) / 10.0, 0.0, 1.0))
	_contact = maxf(0.0, _contact - dt)
	if _contact > 0.0 and throttle > 0.1 and on_water:
		authority = maxf(authority, CONTACT_BITE)
		_pinned = _pinned + dt if absf(vf) < 1.0 else 0.0
		if _pinned > PIN_TIME:
			rel += _contact_n * PIN_PUSH
			_pinned = 0.0
	else:
		_pinned = 0.0
	if bool(spec.get("jet", false)) and on_water:
		# Jet steering: the nozzle turns the thrust, so no gas means (almost) no turn, and gas
		# turns it even from a standstill.
		authority = maxf(authority, thr * 0.7) * lerpf(0.2, 1.0, thr)
	if not on_water:
		authority *= 0.25
	var want_rate := float(spec["turn"]) * clampf(steer, -1.0, 1.0) * authority * (1.0 if vf >= -0.5 else -1.0)
	yaw_rate = lerpf(yaw_rate, want_rate, 1.0 - exp(-6.0 * dt))
	yaw = wrapf(yaw + yaw_rate * dt, -PI, PI)
	vel = rel + flow
	pos += vel * dt
	_banks()
	_solids()
	_boats()
	_vertical(dt, vf)
	_sync()


## The water's height under (x, z) over its rest level.
func _water(x: float, z: float) -> float:
	return float(wave.call(x, z)) * float(spec.get("feel", 1.0))


func _vertical(dt: float, vf: float) -> void:
	var f := forward()
	var half := float(spec["len"]) * 0.4
	var hb := _water(pos.x + f.x * half, pos.y + f.y * half)
	var hs := _water(pos.x - f.x * half, pos.y - f.y * half)
	var hc := (hb + hs) * 0.5
	var slope := (hb - hs) / (2.0 * half)
	if air:
		vy -= GRAVITY * dt
		y += vy * dt
		pitch = lerpf(pitch, clampf(vy * 0.03, -0.25, 0.2), 1.0 - exp(-3.0 * dt))
		if y <= hc:
			landed = maxf(0.0, -vy)
			if landed > HARD_LANDING:
				vel = flow + (vel - flow) * float(spec.get("land_keep", 0.86))
			air = false
			y = hc
			vy = 0.0
	else:
		# Up the face of a crest, fast: the boat leaves it.
		var climb := slope * vf
		if climb > float(spec.get("launch", LAUNCH)) and vf > 6.0:
			air = true
			vy = climb * 0.85
			y = hc + 0.05
		else:
			var y0 := y
			y = lerpf(y, hc, 1.0 - exp(-12.0 * dt))
			vy = (y - y0) / maxf(dt, 0.0001)
		pitch = lerpf(pitch, -atan(slope) - BOW_UP * float(spec.get("bow", 1.0)) * planing * (1.0 - planing * 0.5), 1.0 - exp(-8.0 * dt))
	var lean := float(spec.get("roll", 1.0))
	roll = lerpf(roll, clampf(yaw_rate * ROLL * lean * (0.3 + planing), -0.35 * lean, 0.35 * lean), 1.0 - exp(-6.0 * dt))


## The banks: out along the shore field's slope, the speed into the bank taken away.
func _banks() -> void:
	var r := radius() + 0.6
	var d: float = shore.call(pos.x, pos.y)
	if d >= r:
		return
	var e := 1.5
	var g := Vector2(float(shore.call(pos.x + e, pos.y)) - float(shore.call(pos.x - e, pos.y)),
			float(shore.call(pos.x, pos.y + e)) - float(shore.call(pos.x, pos.y - e)))
	if g.length_squared() < 0.0001:
		return
	var n := g.normalized()
	pos += n * (r - d)
	_hit(n)


func _solids() -> void:
	if not solid.is_valid():
		return
	var push: Vector2 = solid.call(Vector3(pos.x, water_y + 1.0, pos.y), radius())
	if push == Vector2.ZERO:
		return
	pos += push
	_hit(push.normalized())


func _boats() -> void:
	for o: Node3D in others:
		if o == self or not o.visible:
			continue
		var d: Vector2 = pos - o.pos
		var reach: float = radius() + o.radius()
		var l := d.length()
		if l >= reach or l < 0.001:
			continue
		var n := d / l
		var m: float = o.spec["mass"]
		var share: float = m / (m + float(spec["mass"]))
		pos += n * (reach - l) * share
		var into: float = (vel - o.vel).dot(n)
		if into < 0.0:
			vel -= n * into * share * (1.0 + PUSH)
			bumped = maxf(bumped, -into)


func _hit(n: Vector2) -> void:
	_contact = CONTACT_HOLD
	_contact_n = n
	var into := vel.dot(n)
	if into < 0.0:
		vel -= n * into * (1.0 + PUSH)
		vel *= 0.92
		bumped = maxf(bumped, -into)


func _sync() -> void:
	position = Vector3(pos.x, water_y + y, pos.y)
	rotation = Vector3(0.0, yaw, 0.0)
	if _body != null:
		_body.rotation = Vector3(pitch, 0.0, roll)


# --- models -------------------------------------------------------------------------------------
# Original designs, flat-shaded in the models' one material (Models.FIXED parts, the nav lights
# glow at night as lamps). +Z forward, the waterline at y = 0.

const Models := preload("res://scripts/models.gd")
const WHITE := Color("#f1f1ec")
const GLASS := Color("#2c3a48")
const DARK := Color("#24262b")
const SKIN := Color("#d8a27c")
const SEAT := Color("#3a3d44")
## The hull's part and glow while a mesh is built: Models.HERO lit from within at night by UV.y
## (actor.gdshader), so the boats read on the dark river; the fittings stay FIXED.
static var _part := Models.FIXED
static var _glow := 0.0


## A lofted hull: stations along z ([z, half beam, keel depth, sheer height]), its sides in `hull`,
## the deck in `deck`, a darker band at the waterline.
static func _hull(st: SurfaceTool, stations: Array, hull: Color, deck: Color, band: Color) -> void:
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b: Array = stations[i + 1]
		for s: float in [-1.0, 1.0]:
			var a_top := Vector3(s * a[1], a[3], a[0])
			var b_top := Vector3(s * b[1], b[3], b[0])
			var a_wl := Vector3(s * a[1] * 0.92, 0.12, a[0])
			var b_wl := Vector3(s * b[1] * 0.92, 0.12, b[0])
			var a_k := Vector3(0.0, -a[2], a[0])
			var b_k := Vector3(0.0, -b[2], b[0])
			_quad(st, a_wl, b_wl, b_top, a_top, hull, s)
			_quad(st, a_k, b_k, b_wl, a_wl, band, s)
			# deck
			_quad(st, Vector3(0, a[3] + 0.02, a[0]), Vector3(0, b[3] + 0.02, b[0]), b_top + Vector3(0, 0.02, 0), a_top + Vector3(0, 0.02, 0), deck, -s)
	# the transom
	var t: Array = stations[0]
	for s: float in [-1.0, 1.0]:
		_tri(st, Vector3(0, -t[2], t[0]), Vector3(s * t[1] * 0.92, 0.12, t[0]), Vector3(s * t[1], t[3], t[0]), band)
		_tri(st, Vector3(0, -t[2], t[0]), Vector3(s * t[1], t[3], t[0]), Vector3(0, t[3], t[0]), hull)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, colour: Color, side: float) -> void:
	if side > 0.0:
		_tri(st, a, b, c, colour)
		_tri(st, a, c, d, colour)
	else:
		_tri(st, a, c, b, colour)
		_tri(st, a, d, c, colour)


## A triangle seen from both sides (the hulls are open shells).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, colour: Color) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-8:
		return
	n = n.normalized()
	for v: Vector3 in [a, b, c]:
		st.set_color(colour)
		st.set_normal(n)
		st.set_uv(Vector2(_part, _glow))
		st.add_vertex(v)
	for v: Vector3 in [a, c, b]:
		st.set_color(colour)
		st.set_normal(-n)
		st.set_uv(Vector2(_part, _glow))
		st.add_vertex(v)


## A seated driver: torso, head, arms forward, in `shirt`.
static func _driver(st: SurfaceTool, at: Vector3, shirt: Color, hair: Color) -> void:
	Models.box(st, at + Vector3(0, 0.35, 0), Vector3(0.46, 0.6, 0.3), shirt)
	Models.box(st, at + Vector3(0, 0.8, 0.02), Vector3(0.26, 0.28, 0.26), SKIN)
	Models.box(st, at + Vector3(0, 0.95, -0.02), Vector3(0.28, 0.1, 0.28), hair)
	Models.box(st, at + Vector3(0.24, 0.42, 0.25), Vector3(0.1, 0.12, 0.45), shirt)
	Models.box(st, at + Vector3(-0.24, 0.42, 0.25), Vector3(0.1, 0.12, 0.45), shirt)


## Red to port, green to starboard, white at the stern: lamps that glow when the city's lights are on.
static func _nav(st: SurfaceTool, x: float, y0: float, z: float, stern_z: float, stern_y: float) -> void:
	Models.box(st, Vector3(-x, y0, z), Vector3(0.1, 0.1, 0.16), Color("#d8262a"), Models.TAIL_LAMP)
	Models.box(st, Vector3(x, y0, z), Vector3(0.1, 0.1, 0.16), Color("#2fd06a"), Models.HEAD_LAMP)
	Models.box(st, Vector3(0, stern_y, stern_z), Vector3(0.1, 0.12, 0.1), Color("#fff3c4"), Models.HEAD_LAMP)


## The runabout (the player's "Szprotka" and Szymek's): 5.4 m, a deep-V bow, a low windscreen, two
## seats, an outboard on the transom, a stripe in `paint` along the sheer.
static func runabout_mesh(paint: Color, deck: Color, shirt: Color, hair: Color, glow := 0.3) -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = glow
	var stations := [[-2.5, 0.95, 0.35, 0.62], [-1.2, 1.05, 0.42, 0.66], [0.3, 1.02, 0.48, 0.72],
			[1.5, 0.78, 0.45, 0.8], [2.4, 0.38, 0.3, 0.86], [2.9, 0.04, 0.12, 0.9]]
	_hull(st, stations, WHITE, deck, paint.darkened(0.45))
	# the stripe along the sheer
	for s: float in [-1.0, 1.0]:
		for i in stations.size() - 1:
			var a: Array = stations[i]
			var b: Array = stations[i + 1]
			_quad(st, Vector3(s * a[1] * 1.005, a[3] - 0.22, a[0]), Vector3(s * b[1] * 1.005, b[3] - 0.22, b[0]),
					Vector3(s * b[1] * 1.005, b[3] - 0.06, b[0]), Vector3(s * a[1] * 1.005, a[3] - 0.06, a[0]), paint, s)
	# windscreen and dash
	Models.box(st, Vector3(0, 0.82, 0.75), Vector3(1.5, 0.16, 0.6), deck.darkened(0.2))
	_quad(st, Vector3(-0.75, 0.9, 0.5), Vector3(0.75, 0.9, 0.5), Vector3(0.6, 1.25, 0.3), Vector3(-0.6, 1.25, 0.3), GLASS, 1.0)
	# seats and the driver
	Models.box(st, Vector3(0.4, 0.55, -0.3), Vector3(0.6, 0.35, 0.6), SEAT)
	Models.box(st, Vector3(-0.4, 0.55, -0.3), Vector3(0.6, 0.35, 0.6), SEAT)
	Models.box(st, Vector3(0, 0.55, -1.5), Vector3(1.6, 0.3, 0.6), SEAT)
	_driver(st, Vector3(0.4, 0.55, -0.25), shirt, hair)
	# the outboard
	Models.box(st, Vector3(0, 0.75, -2.75), Vector3(0.5, 0.65, 0.5), DARK)
	Models.box(st, Vector3(0, 0.2, -2.8), Vector3(0.18, 0.7, 0.22), DARK)
	Models.box(st, Vector3(0, 1.0, -2.75), Vector3(0.52, 0.1, 0.52), paint)
	_nav(st, 0.75, 0.85, 1.6, -2.4, 1.15)
	return st.commit()


## Pan Zdzisiek's "Złota Rybka": a 6.4 m cream cabin cruiser from another decade, a varnished
## wooden deck, a small cabin with round portholes, a fishing rod on the stern and a flag.
static func tub_mesh() -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = 0.3
	var cream := Color("#e9dfc4")
	var wood := Color("#9a6a3c")
	var stations := [[-3.0, 1.2, 0.5, 0.72], [-1.5, 1.32, 0.6, 0.76], [0.5, 1.3, 0.62, 0.82],
			[2.0, 1.0, 0.55, 0.92], [3.0, 0.5, 0.35, 1.0], [3.4, 0.06, 0.15, 1.04]]
	_hull(st, stations, cream, wood, Color("#2f5a46"))
	# the cabin
	Models.box(st, Vector3(0, 1.2, 0.9), Vector3(1.9, 0.85, 2.0), cream)
	Models.box(st, Vector3(0, 1.66, 0.9), Vector3(2.0, 0.08, 2.1), Color("#c7b48a"))
	for s: float in [-1.0, 1.0]:
		for z: float in [0.4, 1.0, 1.6]:
			Models.box(st, Vector3(s * 0.96, 1.3, z), Vector3(0.04, 0.22, 0.22), GLASS)
	Models.box(st, Vector3(0, 1.32, 1.92), Vector3(1.4, 0.36, 0.04), GLASS)
	# Pan Zdzisiek at the wheel, cap and all, and the rod
	_driver(st, Vector3(0.3, 0.75, -0.6), Color("#4f6a3a"), Color("#8a8f94"))
	Models.box(st, Vector3(0.3, 1.78, -0.6), Vector3(0.34, 0.06, 0.4), Color("#c7c2b0"))
	Models.box(st, Vector3(-0.6, 1.6, -2.4), Vector3(0.04, 2.2, 0.04), DARK)
	Models.box(st, Vector3(0, 0.95, -3.05), Vector3(0.35, 0.5, 0.35), DARK)
	# the flag on the stern staff: white over red
	Models.box(st, Vector3(0.0, 1.5, -2.9), Vector3(0.04, 1.0, 0.04), DARK)
	Models.box(st, Vector3(0.0, 1.88, -3.15), Vector3(0.03, 0.15, 0.45), WHITE)
	Models.box(st, Vector3(0.0, 1.73, -3.15), Vector3(0.03, 0.15, 0.45), Color("#c8202c"))
	_nav(st, 1.0, 1.0, 2.0, -2.9, 1.25)
	return st.commit()


## Kamil's jet ski: 3.2 m, lime and black, the rider standing up.
static func jetski_mesh() -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = 0.3
	var lime := Color("#a6d63a")
	var stations := [[-1.5, 0.52, 0.2, 0.5], [-0.4, 0.58, 0.25, 0.55], [0.8, 0.45, 0.25, 0.6], [1.7, 0.05, 0.1, 0.62]]
	_hull(st, stations, lime, DARK, DARK)
	Models.box(st, Vector3(0, 0.75, 0.2), Vector3(0.5, 0.35, 1.2), DARK)
	Models.box(st, Vector3(0, 0.95, 0.9), Vector3(0.7, 0.08, 0.1), DARK)
	# the rider, standing, leaning in
	Models.box(st, Vector3(0, 1.15, 0.0), Vector3(0.4, 0.7, 0.28), Color("#1b1c20"))
	Models.box(st, Vector3(0, 1.6, 0.1), Vector3(0.36, 0.36, 0.36), Color("#e8492a"))
	Models.box(st, Vector3(0, 1.62, 0.29), Vector3(0.3, 0.12, 0.02), GLASS)
	Models.box(st, Vector3(0.22, 1.2, 0.5), Vector3(0.1, 0.1, 0.6), Color("#1b1c20"))
	Models.box(st, Vector3(-0.22, 1.2, 0.5), Vector3(0.1, 0.1, 0.6), Color("#1b1c20"))
	_nav(st, 0.4, 0.66, 0.9, -1.45, 0.62)
	return st.commit()


## The free-ride jet ski "Rekin X" (F's photo 1: black, red graphics, a black-and-red saddle): 3.4 m,
## a stepped deck, the handlebar pod, a rider seated astride. `rider` false: parked.
static func skuter_mesh(rider: bool) -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = 0.35
	var black := Color("#17181c")
	var red := Color("#d8322c")
	var stations := [[-1.6, 0.6, 0.22, 0.48], [-0.5, 0.62, 0.28, 0.52], [0.7, 0.52, 0.28, 0.6], [1.5, 0.3, 0.2, 0.64], [1.85, 0.03, 0.08, 0.62]]
	_hull(st, stations, black, Color("#26282e"), Color("#0e0f12"))
	# the red flash along each side
	for s: float in [-1.0, 1.0]:
		_quad(st, Vector3(s * 0.63, 0.24, -1.2), Vector3(s * 0.6, 0.3, 0.9), Vector3(s * 0.56, 0.42, 1.1), Vector3(s * 0.64, 0.38, -0.7), red, s)
		_quad(st, Vector3(s * 0.62, 0.42, -1.5), Vector3(s * 0.63, 0.46, -0.6), Vector3(s * 0.63, 0.5, -0.6), Vector3(s * 0.62, 0.5, -1.5), Color("#c9ccd1"), s)
	# the hood and the handlebar pod, the saddle in black with red panels, the footwells
	Models.box(st, Vector3(0, 0.72, 0.85), Vector3(0.78, 0.3, 1.0), black)
	Models.box(st, Vector3(0, 0.9, 0.85), Vector3(0.5, 0.06, 0.6), red)
	Models.box(st, Vector3(0, 0.98, 0.35), Vector3(0.24, 0.3, 0.24), black)
	Models.box(st, Vector3(0, 1.12, 0.32), Vector3(0.8, 0.06, 0.08), Color("#3a3d44"))
	Models.box(st, Vector3(0, 0.74, -0.45), Vector3(0.46, 0.22, 1.25), black)
	Models.box(st, Vector3(0, 0.86, -0.45), Vector3(0.3, 0.04, 1.1), red)
	Models.box(st, Vector3(0, 0.6, -1.45), Vector3(0.9, 0.12, 0.35), Color("#26282e"))
	if rider:
		Models.box(st, Vector3(0, 1.15, -0.25), Vector3(0.42, 0.62, 0.3), Color("#ff8a1a"))
		Models.box(st, Vector3(0, 1.62, -0.15), Vector3(0.3, 0.3, 0.3), Color("#1b1c20"))
		Models.box(st, Vector3(0, 1.63, 0.0), Vector3(0.26, 0.1, 0.02), GLASS)
		Models.box(st, Vector3(0.24, 1.2, 0.05), Vector3(0.1, 0.1, 0.55), Color("#ff8a1a"))
		Models.box(st, Vector3(-0.24, 1.2, 0.05), Vector3(0.1, 0.1, 0.55), Color("#ff8a1a"))
		for s: float in [-1.0, 1.0]:
			Models.box(st, Vector3(s * 0.28, 0.82, -0.35), Vector3(0.14, 0.3, 0.5), Color("#2a3550"))
	_nav(st, 0.45, 0.7, 1.0, -1.55, 0.62)
	return st.commit()


## The free-ride electric runabout "Srebrna Strzała" (F's photo 2: silver, yellow seats, no engine
## noise): 7.5 m, a long silver hull with a rounded tumblehome stern, a flush foredeck, a low dark
## screen, two yellow buckets and a yellow bench, a grilled hatch over the motor aft, a dark
## line along the sheer. `driver` false: parked, a grey cover over the cockpit.
static func electric_mesh(driver: bool) -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = 0.35
	var silver := Color("#c3c7cc")
	var yellow := Color("#f2c230")
	var stations := [[-3.6, 1.1, 0.35, 0.82], [-2.8, 1.28, 0.45, 0.86], [-0.8, 1.3, 0.52, 0.9],
			[1.3, 1.12, 0.5, 0.94], [2.8, 0.62, 0.36, 0.98], [3.9, 0.06, 0.12, 1.0]]
	_hull(st, stations, silver, silver.lightened(0.12), Color("#5d6268"))
	for s: float in [-1.0, 1.0]:
		for i in stations.size() - 1:
			var a: Array = stations[i]
			var b: Array = stations[i + 1]
			_quad(st, Vector3(s * a[1] * 1.005, a[3] - 0.2, a[0]), Vector3(s * b[1] * 1.005, b[3] - 0.2, b[0]),
					Vector3(s * b[1] * 1.005, b[3] - 0.16, b[0]), Vector3(s * a[1] * 1.005, a[3] - 0.16, a[0]), Color("#2b2e33"), s)
	# the cockpit well (dark), the low wrap-around screen
	Models.box(st, Vector3(0, 0.86, -0.3), Vector3(2.0, 0.06, 2.6), Color("#2b2e33"))
	for s: float in [-1.0, 1.0]:
		_quad(st, Vector3(0, 1.0, 1.15), Vector3(s * 1.05, 1.0, 0.9), Vector3(s * 0.95, 1.3, 0.75), Vector3(0, 1.3, 0.98), GLASS, s)
	# the yellow seats: two buckets and the bench behind
	Models.box(st, Vector3(0.48, 1.0, 0.25), Vector3(0.62, 0.32, 0.6), yellow)
	Models.box(st, Vector3(-0.48, 1.0, 0.25), Vector3(0.62, 0.32, 0.6), yellow)
	Models.box(st, Vector3(0.48, 1.25, -0.02), Vector3(0.6, 0.45, 0.14), Color("#2b2e33"))
	Models.box(st, Vector3(-0.48, 1.25, -0.02), Vector3(0.6, 0.45, 0.14), Color("#2b2e33"))
	Models.box(st, Vector3(0, 0.98, -1.2), Vector3(1.9, 0.28, 0.6), yellow)
	# the motor hatch aft with its dark grille, a thin bright name plate on the transom
	Models.box(st, Vector3(0, 0.98, -2.6), Vector3(1.6, 0.12, 1.6), silver.lightened(0.08))
	Models.box(st, Vector3(0, 1.05, -2.5), Vector3(0.9, 0.04, 0.8), Color("#3a3d44"))
	Models.box(st, Vector3(0, 0.6, -3.62), Vector3(0.7, 0.06, 0.02), Color("#2b2e33"))
	if driver:
		_driver(st, Vector3(0.48, 1.0, 0.3), Color("#ff8a1a"), Color("#3a2a1c"))
	else:
		Models.box(st, Vector3(0, 1.12, -0.5), Vector3(2.1, 0.05, 2.2), Color("#8e949b"))
	_nav(st, 1.05, 1.0, 2.0, -3.5, 1.2)
	return st.commit()


## The free-ride offshore boat "Czarna Pantera" (F's photo 3: gloss black, red upholstery, a hardtop,
## five outboards): 13 m, a sharp black hull with a silver rub line and three portholes a side, a
## red bow lounge, a black hardtop on pillars over the helm, red buckets and an aft lounge, five
## black outboards on the transom. `driver` false: parked.
static func offshore_mesh(driver: bool) -> ArrayMesh:
	var st := Models._begin()
	_part = Models.HERO
	_glow = 0.3
	var black := Color("#141519")
	var red := Color("#c92a2a")
	var stations := [[-6.2, 1.55, 0.55, 1.15], [-4.0, 1.7, 0.75, 1.2], [-1.0, 1.72, 0.85, 1.28],
			[2.0, 1.55, 0.85, 1.36], [4.5, 0.95, 0.65, 1.44], [6.6, 0.08, 0.2, 1.5]]
	_hull(st, stations, black, Color("#2a2c31"), Color("#0b0c0e"))
	for s: float in [-1.0, 1.0]:
		for i in stations.size() - 1:
			var a: Array = stations[i]
			var b: Array = stations[i + 1]
			_quad(st, Vector3(s * a[1] * 1.005, a[3] - 0.1, a[0]), Vector3(s * b[1] * 1.005, b[3] - 0.1, b[0]),
					Vector3(s * b[1] * 1.005, b[3] - 0.05, b[0]), Vector3(s * a[1] * 1.005, a[3] - 0.05, a[0]), Color("#c9ccd1"), s)
		for z: float in [-2.6, -1.9, -1.2]:
			Models.box(st, Vector3(s * 1.74, 0.75, z), Vector3(0.03, 0.18, 0.3), Color("#5a6470"))
	# the red bow lounge round a teak sole
	Models.box(st, Vector3(0, 1.3, 4.0), Vector3(1.2, 0.06, 1.6), Color("#b08a60"))
	Models.box(st, Vector3(0.75, 1.42, 3.9), Vector3(0.4, 0.28, 2.2), red)
	Models.box(st, Vector3(-0.75, 1.42, 3.9), Vector3(0.4, 0.28, 2.2), red)
	Models.box(st, Vector3(0, 1.42, 2.6), Vector3(1.9, 0.28, 0.9), red)
	# the console and the screen, the hardtop on four pillars
	Models.box(st, Vector3(0, 1.55, 1.1), Vector3(2.3, 0.6, 0.9), black)
	for s: float in [-1.0, 1.0]:
		_quad(st, Vector3(s * 0.05, 1.85, 1.45), Vector3(s * 1.15, 1.85, 1.35), Vector3(s * 1.1, 2.4, 0.95), Vector3(s * 0.05, 2.4, 1.05), GLASS, s)
		for z: float in [0.9, -1.4]:
			Models.box(st, Vector3(s * 1.15, 2.2, z), Vector3(0.1, 1.5, 0.1), black)
	Models.box(st, Vector3(0, 2.98, -0.25), Vector3(2.6, 0.12, 3.0), black)
	Models.box(st, Vector3(0, 3.1, -0.25), Vector3(1.4, 0.06, 1.6), Color("#2a2c31"))
	# the red buckets under the top, the aft lounge, the engine bay hatch
	for x: float in [-0.75, 0.0, 0.75]:
		Models.box(st, Vector3(x, 1.5, 0.0), Vector3(0.6, 0.5, 0.6), red)
	Models.box(st, Vector3(0, 1.45, -2.4), Vector3(2.9, 0.4, 1.2), red)
	Models.box(st, Vector3(0, 1.3, -4.4), Vector3(2.8, 0.1, 2.6), Color("#2a2c31"))
	# five outboards
	for k in 5:
		var x := -1.2 + 0.6 * k
		Models.box(st, Vector3(x, 1.25, -6.45), Vector3(0.48, 0.9, 0.62), black)
		Models.box(st, Vector3(x, 1.72, -6.45), Vector3(0.5, 0.06, 0.64), Color("#3a3d44"))
		Models.box(st, Vector3(x, 0.35, -6.5), Vector3(0.16, 1.0, 0.24), black)
	if driver:
		_driver(st, Vector3(0.0, 1.5, 0.05), Color("#ff8a1a"), Color("#3a2a1c"))
	_nav(st, 1.5, 1.5, 4.8, -6.0, 3.15)
	return st.commit()
