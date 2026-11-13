extends RefCounted
## Loop 2a: the driving controls, shared by the game (main.gd) and the replay test
## (tools/check_steering.gd), so the test drives exactly what the player drives.
##
## Three schemes (Settings → Controls, `--controls=`):
## - POINT (the default until 2026-11-04): point where you want to go. The stick points in screen space. Since
##   the follow-camera loop (FOLLOW_HELD) the camera turns with the car while the finger is down
##   too; a held direction keeps the world direction it meant when it was set (the screen as it
##   was then), and pointing somewhere new (REAIM° or more from it) means the screen as it is now.
##   Before, the camera held still while the finger was down and eased round behind the car 0.6 s
##   after it lifted (follow_camera.gd): the view only swung round once you let go. Gas comes
##   from how far the stick is pushed (full from three quarters out). Pointing well behind
##   brakes, then turns (car.gd).
## - CLASSIC (the default since 2026-11-04, F's call; settings.gd DEFAULT_CONTROLS): steer + pedals. The stick's left / right steers (car-relative), GAS and
##   BRAKE / REVERSE are buttons on the right; the camera turns with the car.
## - FIXED: point where you want to go with the camera never turning (the v0.4 scheme).
## Keys follow the scheme: in POINT and FIXED, W A S D / arrows point in screen directions
## (like the helicopter); in CLASSIC, A / D steer, W is the gas and S the brake. Space
## brakes in every scheme.
##
## Before loop 2a the stick pointed in screen space while the follow camera kept turning
## towards the car's heading, so the world direction a held stick meant kept rotating
## with the car: holding the stick to one side made the car circle (check_steering.gd
## --legacy: 3.8 full circles in 10 s with the stick held right).

enum { POINT, CLASSIC, FIXED }
const NAMES := ["Point", "Classic", "Fixed"]
const KEYS := ["point", "classic", "fixed"]

## The stick, as a share of its radius: the dead zone, and where the gas is full (POINT).
const DEAD := 0.15
const FULL := 0.75
## CLASSIC: the left / right dead zone.
const STEER_DEAD := 0.08
## The follow-camera loop (2026-10-30, the user's call from the phone): POINT's camera turns with
## the car while the finger is down (false: loop 2a's camera, which waited for the finger to lift).
const FOLLOW_HELD := true
## POINT with FOLLOW_HELD: a held direction is read against the camera's yaw when it was set, so
## the camera coming round doesn't turn it (which made a held stick circle the car, loop 2a);
## moving the finger this many degrees or more sets it again, against the screen as it is now.
const REAIM := 20.0

var scheme := CLASSIC
## True while the stick's finger is down or a direction key is held (POINT: the camera waits).
var held := false
## Seconds since `held` last was true (the camera loop's follow_camera.gd reads it).
var since_release := 99.0
## POINT with FOLLOW_HELD: the held direction (screen) and the camera's yaw when it was set.
var _set_aim := Vector2.ZERO
var _set_yaw := 0.0
## CLASSIC, F 2026-11-13: the HUD's fixed arrow buttons (hud.gd `arrows`: +1 left, -1 right, 0
## none), set by the game before `drive`. An arrow is all or nothing, so the steering it gives
## ramps: ARROW_START of full lock at once (a tap is a small correction), full lock after
## ARROW_RAMP s held. The car's own limits (car.gd max_turn) make full lock gentler at speed.
const ARROW_START := 0.35
const ARROW_RAMP := 0.3
var arrows := 0
var _arrow_dir := 0
var _arrow_t := 0.0


## Sets the car's controls from the stick (screen space, -1..1, y down; `stick_on` while its
## finger is down), the keys {left, right, up, down, brake}, the on-screen GAS and BRAKE
## pedals, and the camera's yaw in degrees (main.gd's cam_yaw).
func drive(car: Node, stick: Vector2, stick_on: bool, keys: Dictionary, gas: bool, brake: bool, cam_yaw: float,
		dt: float) -> void:
	var left: bool = keys.get("left", false)
	var right: bool = keys.get("right", false)
	var up: bool = keys.get("up", false)
	var down: bool = keys.get("down", false)
	var brake_key: bool = keys.get("brake", false)
	if scheme == CLASSIC:
		var s := float(left) - float(right)
		if arrows != 0:
			if arrows != _arrow_dir:
				_arrow_dir = arrows
				_arrow_t = 0.0
			_arrow_t += dt
			var u := clampf(_arrow_t / ARROW_RAMP, 0.0, 1.0)
			s = float(arrows) * (ARROW_START + (1.0 - ARROW_START) * u * u * (3.0 - 2.0 * u))
		else:
			_arrow_dir = 0
			_arrow_t = 0.0
		if stick_on and absf(stick.x) > STEER_DEAD:
			var u := clampf((absf(stick.x) - STEER_DEAD) / (1.0 - STEER_DEAD), 0.0, 1.0)
			# A gentle curve: fine corrections near the middle, full lock at the edge.
			s = -signf(stick.x) * u * (0.4 + 0.6 * u)
		car.target_dir = Vector3.ZERO
		car.steer = s
		car.throttle = 1.0 if gas or up else 0.0
		car.braking = brake or down or brake_key
		held = false
	else:
		var aim := Vector2.ZERO
		var amount := 0.0
		var length := stick.length()
		if stick_on and length > DEAD:
			aim = stick / length
			amount = clampf((length - DEAD) / (FULL - DEAD), 0.0, 1.0)
		else:
			var k := Vector2(float(right) - float(left), float(down) - float(up))
			if k != Vector2.ZERO:
				aim = k.normalized()
				amount = 1.0
		var yaw := cam_yaw
		if scheme == POINT and FOLLOW_HELD:
			if aim == Vector2.ZERO:
				_set_aim = Vector2.ZERO
			else:
				if _set_aim == Vector2.ZERO or absf(rad_to_deg(aim.angle_to(_set_aim))) >= REAIM:
					_set_aim = aim
					_set_yaw = cam_yaw
				yaw = _set_yaw
		car.target_dir = screen_to_world(aim, yaw) if aim != Vector2.ZERO else Vector3.ZERO
		car.throttle = amount
		car.steer = 0.0
		car.braking = brake or brake_key
		held = stick_on or aim != Vector2.ZERO
	since_release = 0.0 if held else since_release + dt


## Nothing held (the title screen, the helicopter, an autopilot): the camera may follow.
func release() -> void:
	held = false
	arrows = 0
	_arrow_dir = 0
	_arrow_t = 0.0
	_set_aim = Vector2.ZERO


## Whether the follow camera waits for the finger to lift before it comes round (follow_camera.gd
## follow_yaw's `waits`): FIXED never turns, POINT waits only without FOLLOW_HELD, CLASSIC never.
func camera_waits() -> bool:
	return scheme == FIXED or (scheme == POINT and not FOLLOW_HELD)


## A screen direction (x right, y down) as a world direction on the ground for a camera
## turned `yaw` degrees (main.gd's camera: pitch about x, then yaw about y).
static func screen_to_world(s: Vector2, yaw: float) -> Vector3:
	var y := deg_to_rad(yaw)
	var right := Vector3(cos(y), 0.0, -sin(y))
	var ahead := Vector3(-sin(y), 0.0, -cos(y))
	return right * s.x + ahead * -s.y


static func parse(v: String) -> int:
	var k := KEYS.find(v.to_lower())
	return k if k >= 0 else clampi(int(v), 0, NAMES.size() - 1)
