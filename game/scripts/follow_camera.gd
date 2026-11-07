extends RefCounted
## Camera loop: the follow camera's laws, shared by the game (main.gd) and the replay test
## (tools/check_steering.gd), so the test measures the camera the player sees. main.gd keeps the
## camera's yaw (cam_yaw) and centre (cam_focus); this keeps what moves them smoothly: the turn
## rate, the look-ahead, the dead zone and the speed zoom.
##
## - Turning: the camera turns towards the vehicle's heading at a rate set by the error (a gain
##   per second), the rate itself easing in and out (critically damped: no overshoot), never
##   faster than MAX_TURN (Nesky's comfort limit, docs/DEMO.md 1.1). Classic turns with the car;
##   Point and the helicopter hold still while the finger (or a key) is down and HOLD_DELAY after
##   it lifts, then come round, easing in over RETURN_EASE: a held direction must not turn with the
##   view (loop 2a's steering fix, tools/check_steering.gd). A standing car's camera holds still
##   (the hovering helicopter's comes round); heading wiggles under YAW_DEAD don't turn it.
## - Look-ahead: the view's centre leads the car along the way it goes (Classic: along the
##   camera's forward, which keeps the car still on screen while the camera turns) by LEAD_TIME
##   of its speed (LEAD_TIME_FAST more at top speed), at most LEAD_MAX of the view, turning and
##   growing smoothly (LEAD_TAU) and never faster than LEAD_RATE of the view a second (the car
##   drifts across the screen at most that fast when the way it goes turns); braking, it shrinks
##   by at most LEAD_KEEP of the car's own speed, so the view never slides back past the car: it
##   glides to rest ahead of it, and stays there while the car stands (it moves again when the
##   car does).
## - Dead zone: the centre follows a window DEAD_ZONE of the view wide (on screen), so wiggles
##   inside it don't move the view (FOCUS_RATE then smooths it, as in loop 2a).
## - Speed zoom: the view widens by SPEED_ZOOM at top speed, out at ZOOM_OUT_RATE and back in
##   more slowly (ZOOM_IN_RATE), so braking doesn't snap the view in; the zoom's own changes (−,
##   +, a pinch) follow at ZOOM_OUT_RATE both ways. The shadow's sphere doesn't change with the
##   speed zoom (main.gd _camera_far).
## Before the camera loop the turn was a first-order lerp (up to 108°/s in Classic, 135°/s from
## the helicopter 0.6 s after a release), the lead shrank with the speed (the view slid 8 m back
## after a hard stop from 90 km/h) and the speed zoom came back in at once.

## The default view height in metres while driving (was 110 before loop 2a): the car is
## ~58 px long side-on on an iPhone's 1170 lines; still ~3 s of road ahead at 90 km/h.
const DEFAULT_SIZE := 80.0
## The follow-camera loop (2026-10-30): the player's zoom, view heights in metres (pinch, the
## mouse wheel, − and +; saved in Settings), from close to wide; DEFAULT_SIZE is the fourth.
## 40 m (F, 2026-11-07: "+ a little bit closer"): the car ~115 px long on 1170 lines.
const VIEWS: Array[float] = [40.0, 50.0, 65.0, 80.0, 100.0, 125.0]
## The camera's angle over the ground in degrees (main.gd camera_pitch is minus this), Settings →
## Obraz "Kąt kamery" (F, 2026-11-07). 30 is the game's look and the default; steeper ones show
## less of the street ahead (ground depth = view height / sin angle) and more of the roofs.
const PITCHES: Array[float] = [30.0, 40.0, 50.0]
const DEFAULT_PITCH := 30.0
## A pinch takes a step each time the fingers' span changes by this ratio.
const PINCH_STEP := 1.2
## The view widens by this share at top speed.
const SPEED_ZOOM := 0.25
## The fastest the camera ever turns, degrees a second.
const MAX_TURN := 64.0
## Classic: the turn rate per degree of error (1/s), at FULL_SPEED and over (loop 2a's 2.2).
const TURN_GAIN := 2.2
## Point and the helicopter, after a release: the turn rate per degree of error (1/s).
const RETURN_GAIN := 1.1
## Point and the helicopter: hold still this long after the finger lifts, then ease in over
## RETURN_EASE.
const HOLD_DELAY := 0.6
const RETURN_EASE := 0.8
## The speed (m/s) from which the camera turns in full: Classic at 8 m/s, Point down to a crawl
## (3 m/s: off the gas the car soon slows down). The helicopter turns in full even hovering (it
## stops within a second of a release, and hovers facing the way it flew): FULL_SPEED_HELI 0.
const FULL_SPEED := 8.0
const FULL_SPEED_POINT := 3.0
const FULL_SPEED_HELI := 0.0
## Heading wiggles under this (degrees) don't turn the camera.
const YAW_DEAD := 1.0
## The look-ahead: LEAD_TIME s of the speed, LEAD_TIME_FAST s more at top speed, at most LEAD_MAX
## of the view height, eased over LEAD_TAU s; braking it gives back at most LEAD_KEEP of the car's
## speed.
const LEAD_TIME := 0.4
const LEAD_TIME_FAST := 0.25
const LEAD_MAX := 0.2
const LEAD_TAU := 0.7
const LEAD_RATE := 0.035
const LEAD_KEEP := 0.5
## The dead zone's radius, a share of the view height (0.4 m at 80 m: ~7 px of 1320 lines).
const DEAD_ZONE := 0.005
## How quickly the view's centre follows the dead zone's window (1/s, loop 2a's).
const FOCUS_RATE := 6.0
## The speed zoom's rates (1/s): out as the car speeds up, in as it slows.
const ZOOM_OUT_RATE := 2.5
const ZOOM_IN_RATE := 0.8

## The camera's turn rate now, degrees a second.
var turn := 0.0
## The look-ahead now (metres, on the ground).
var lead := Vector3.ZERO
var _window := Vector3.INF
var _base := -1.0
var _extra := 0.0


## The follow camera's next yaw (degrees, main.gd's cam_yaw) for a vehicle with `heading`
## (degrees, its rotation.y) going `speed` m/s. `waits` (Point, the helicopter): it holds still
## while `held` and HOLD_DELAY after `since_release`, then comes round; otherwise (Classic) it turns
## with the vehicle, at `gain` (Classic's TURN_GAIN; Point's RETURN_GAIN since the follow-camera
## loop). `full`: the speed from which it turns in full (0: at any speed).
func follow_yaw(yaw: float, heading: float, speed: float, waits: bool, held: bool, since_release: float,
		full: float, dt: float, gain := TURN_GAIN) -> float:
	var share := 1.0 if full <= 0.0 else clampf(speed / full, 0.0, 1.0)
	if waits:
		if held or since_release < HOLD_DELAY:
			turn = 0.0
			return yaw
		var ease := smoothstep(HOLD_DELAY, HOLD_DELAY + RETURN_EASE, since_release)
		return turn_towards(yaw, heading, RETURN_GAIN, ease * share, dt)
	return turn_towards(yaw, heading, gain, share, dt)


## One step of the turn towards `heading`: the rate `gain` × error (less YAW_DEAD), times `share`
## (0..1), at most MAX_TURN; the turn rate eases towards it over 1 / (4 gain) s, which makes the
## whole turn critically damped (no overshoot; with share < 1, slower and still none).
func turn_towards(yaw: float, heading: float, gain: float, share: float, dt: float) -> float:
	var err := wrapf(heading - yaw, -180.0, 180.0)
	err = signf(err) * maxf(absf(err) - YAW_DEAD, 0.0)
	var want := clampf(gain * err, -MAX_TURN, MAX_TURN) * share
	turn += (want - turn) * (1.0 - exp(-4.0 * gain * dt))
	return yaw + turn * dt


## A camera that doesn't follow (Fixed, the rotate buttons): it isn't turning by itself.
func stop_turning() -> void:
	turn = 0.0


## The look-ahead for a car going `vel` (m/s) with a top speed of `top`, for a view `size` m tall.
## With `forward` (the camera's forward on the ground: Classic, where the camera turns with the
## car) it lies along the camera's forward, so the car keeps its place on screen while the camera
## turns (along the car's way, it would sweep the car round the screen's middle as the camera
## lags behind the car in a turn); otherwise (Point, Fixed, the helicopter: any way across the
## screen) along the way the car goes.
func lead_step(vel: Vector3, top: float, size: float, dt: float, forward := Vector3.ZERO) -> Vector3:
	var v := Vector3(vel.x, 0.0, vel.z)
	var speed := v.length()
	var most := size * LEAD_MAX
	if speed < 0.05:
		if forward != Vector3.ZERO:
			lead = forward * clampf(lead.dot(forward), -most, most)
		lead = lead.limit_length(most)
		return lead
	var t := LEAD_TIME + LEAD_TIME_FAST * clampf(speed / top, 0.0, 1.0)
	var want := (v * t).limit_length(most)
	var dir := v / speed
	if forward != Vector3.ZERO:
		# One length along the camera's forward (behind when reversing).
		var now := lead.dot(forward)
		var goal := want.dot(forward)
		var step := clampf((goal - now) * (1.0 - exp(-dt / LEAD_TAU)), -LEAD_RATE * size * dt, LEAD_RATE * size * dt)
		var keep_back := LEAD_KEEP * speed * dt * absf(dir.dot(forward))
		if signf(now) == signf(dir.dot(forward)) and absf(now + step) < absf(now) - keep_back:
			step = signf(now) * (absf(now) - keep_back) - now
		lead = forward * clampf(now + step, -most, most)
		return lead
	var step := (want - lead) * (1.0 - exp(-dt / LEAD_TAU))
	var next := lead + step.limit_length(LEAD_RATE * size * dt)
	# Braking: along the way the car goes, give back at most LEAD_KEEP of its speed.
	var floor_along := lead.dot(dir) - LEAD_KEEP * speed * dt
	var along := next.dot(dir)
	if along < floor_along:
		next += dir * (floor_along - along)
	lead = next.limit_length(most)
	return lead


## A placed or towed car: no look-ahead.
func reset_lead() -> void:
	lead = Vector3.ZERO


## The view's next centre: `focus` (main.gd's cam_focus) follows a window DEAD_ZONE × `size`
## wide on screen (the camera's `basis`) that `target` (the vehicle plus its lead) drags along.
func focus_step(focus: Vector3, target: Vector3, basis: Basis, size: float, rate: float, dt: float) -> Vector3:
	if _window == Vector3.INF:
		_window = focus
	var off := target - _window
	var r := off.dot(basis.x)
	var u := off.dot(basis.y)
	var d := sqrt(r * r + u * u)
	var radius := DEAD_ZONE * size
	if d > radius:
		_window += (basis.x * r + basis.y * u) * ((d - radius) / d)
	# Along the view (into the screen) nothing shows: no dead zone.
	_window += basis.z * off.dot(basis.z)
	return focus.lerp(_window, 1.0 - exp(-rate * dt))


## The view's next height: `size` towards `base` (the zoom: at ZOOM_OUT_RATE both ways) plus
## `extra` (the speed zoom, in metres: out at ZOOM_OUT_RATE, in at ZOOM_IN_RATE).
## The follow-camera loop: the zoom step `steps` away from `size` (+1 wider, -1 closer), from the
## VIEWS step nearest to `size`; it stays at either end.
static func view_step(size: float, steps: int) -> float:
	var k := 0
	for i in VIEWS.size():
		if absf(VIEWS[i] - size) < absf(VIEWS[k] - size):
			k = i
	return VIEWS[clampi(k + steps, 0, VIEWS.size() - 1)]


func zoom_step(size: float, base: float, extra: float, dt: float) -> float:
	if _base < 0.0:
		_base = size
		_extra = 0.0
	_base = lerpf(_base, base, 1.0 - exp(-ZOOM_OUT_RATE * dt))
	_extra = lerpf(_extra, extra, 1.0 - exp(-(ZOOM_OUT_RATE if extra > _extra else ZOOM_IN_RATE) * dt))
	return _base + _extra
