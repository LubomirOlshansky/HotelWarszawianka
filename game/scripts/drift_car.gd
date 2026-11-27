extends "res://scripts/car.gd"
## The stadium's car for Bokiem na Narodowym (the grey box, critique-drift.md section 4): car.gd's look,
## lamps and body, posed from the drift model instead of driven. One thumb needs no move_and_slide:
## the position is the line's at s, the yaw the course plus the slip (drift_model.gd). No colliders,
## no wall rule; car.gd is not edited (check_drift M11: its source names no drift script).
##
## `_step` writes what the city's readers of a car read: the transform, `vel`, `forward_speed` (for
## sfx.gd's engine: the wheel speed, change 5: `v + 10 m/s × gas × min(1, |β| / 45°)`, so the revs climb
## with depth, cut at LIMIT_HZ past LIMIT_DEG: the limiter's stutter in the engine loop), `slip` (the
## tyres' squeal and skids.gd: v × sin|β|), `throttle` and `brakes_on` (never). The body rolls a little
## with the slip, for the look.

const DriftModel := preload("res://scripts/drift_model.gd")

## Change 5: the wheel speed's lead at full gas and 45° (m/s); the limiter past LIMIT_DEG, at LIMIT_HZ.
const WHEEL_LEAD := 10.0
const LIMIT_DEG := 55.0
const LIMIT_HZ := 8.0

## Set by the stadium (drift_stadium.gd) before each physics frame: the model's state and the line.
var state: DriftModel.State
var line: RefCounted
## The floor's height (the stadium's PLACE.y).
var floor_y := 0.0
## Where the line's (0, 0) is in the world.
var origin := Vector3.ZERO
var _limit_t := 0.0


func _ready() -> void:
	super()
	collision_layer = 0
	collision_mask = 0
	lights = 0.0


func _step(dt: float) -> void:
	if state == null or line == null:
		return
	var p: Vector2 = line.at(state.s)
	var course: float = line.yaw_at(state.s)
	var b := deg_to_rad(state.beta)
	global_transform = Transform3D(Basis(Vector3.UP, course + b), origin + Vector3(p.x, floor_y, p.y))
	var d: Vector2 = line.dir(course)
	vel = Vector3(d.x, 0.0, d.y) * state.v
	var ab := absf(state.beta) if state.mode != DriftModel.Mode.SPIN else 60.0
	var wheel := state.v + WHEEL_LEAD * state.gas * minf(1.0, ab / 45.0)
	_limit_t += dt
	if ab > LIMIT_DEG and state.gas > 0.5 and fmod(_limit_t * LIMIT_HZ, 1.0) < 0.35:
		wheel *= 0.82  # the limiter cuts in
	forward_speed = wheel
	slip = state.v * sin(deg_to_rad(minf(ab, 90.0)))
	throttle = state.gas
	brakes_on = false
	steer_now = 0.0
	var roll := clampf(-state.beta / 60.0 * 0.07, -0.07, 0.07)
	_body.rotation.z = lerpf(_body.rotation.z, roll, 1.0 - exp(-10.0 * dt))
	_body.rotation.x = lerpf(_body.rotation.x, -0.02 * state.gas, 1.0 - exp(-8.0 * dt))
