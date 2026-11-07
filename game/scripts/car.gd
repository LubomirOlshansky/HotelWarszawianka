extends CharacterBody3D
## Arcade car: forward speed from throttle and brake, steering that needs a little
## speed, and lateral grip that lets the tail slide when braking hard.
## It can flash its headlights (the street-race challenge). When the city's
## lights are on (`lights`, set by the game), its head and tail lamps glow, a
## spotlight lights the road and the walls ahead, and soft cones lie on the road.
##
## Loop 2a (the feel on a phone, measured by tools/check_steering.gd): the most it turns
## depends on speed (sharp when slow, calm when fast: full-lock radius ~2.5 m at 20 km/h,
## ~8.5 m at 50, ~23 m at 90; it was 2.3 / 6.4 / 11.5 m, a 4 g swerve at speed); it pivots
## a little from a standstill with the gas on; the steering is smoothed over 0.08 s;
## point-to-steer (target_dir) turns at a rate set by the heading error with a touch of
## yaw damping, so it settles on the direction without overshooting, and pointing well
## behind at speed brakes first and then turns; a big turn holds the speed (off the gas)
## until it is done; pointing into a wall it is touching, it follows the wall instead. The gas sets a target speed (a light push cruises slowly). Walls: the car keeps what slides along them (was 8 % lost every
## frame of contact), a glancing hit turns it along the wall, a head-on one pushes it back a
## little, and if it is pinned (touching something fixed, getting nowhere, with the gas or
## brake on) for 1.5 s it is turned out of the wall; pinned again soon after, `stuck` asks
## the game to put it on a free spot. Queued against a traffic car is not pinned (until the
## driving-feel loop's CAR_PUSH_TIME, below).
##
## The driving-feel loop (2026-10-30, "the car sticks to everything"): a front corner that
## clips something small (a post, a bench, a parked or traffic car's corner) slips the car
## sideways past it with most of its speed (`_corner_slip`) instead of stopping it dead; held
## against a car or tram for CAR_PUSH_TIME with the gas on, it steers round it like a wall (and
## is turned out after UNSTICK_TIME, never sent to a free spot for it); a kerb takes 3 % of the
## speed (was 8 %) once per KERB_GAP however many kerb lines it crosses (an island is two), and
## the raised ground drags at 0.25/s (was 0.6).
##
## Loop 10a: in the water (the river, a pond: `water_at`, the map's test) it splashes once
## (`splashed`), takes no gas or steering, slows hard and settles a little, bobbing, until the
## game tows it out (`leave_water`).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Access := preload("res://scripts/access.gd")
const Haptics := preload("res://scripts/haptics.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Models := preload("res://scripts/models.gd")
const LaneAssist := preload("res://scripts/lane_assist.gd")

## Hit something hard enough to notice, at `speed` m/s closing speed (traffic stops
## the car it was hit by; the słoiki run breaks jars).
signal bumped(collider: Object, speed: float)
## A hit worth a sound (v0.9, sfx.gd): fired where the haptics are, once per knock.
signal impact(collider: Object, speed: float)
## v1.0 juice: sliding along something fixed at `speed` m/s, at most SCRAPE_EVERY s apart
## (crash_fx.gd throws a few sparks from `at`, the contact, out along `normal`).
signal scraped(at: Vector3, normal: Vector3, speed: float)
## v1.0 juice: where the last `impact` touched and the contact's normal (crash_fx.gd's sparks).
var hit_point := Vector3.ZERO
var hit_normal := Vector3.BACK
const SCRAPE_EVERY := 0.07
var _scrape_wait := 0.0
## Loop 2a: pinned twice within a few seconds; the game moves the car to a free spot.
signal stuck
## G13b: the nitro just lit (sfx whoosh, a buzz in main.gd).
signal nitro_started
## G17 (2026-11-02): jammed among traffic cars for JAM_TIME s (never fixed walls); the game tows it.
signal jammed
## Loop 10a: rolled into the water, at `speed` m/s (once; the game splashes and tows it out).
signal splashed(speed: float)

@export var max_speed := 30.0        # m/s, about 108 km/h
## Loop 3d-1: the most the gas asks for here (main.gd sets it in a pedestrian zone: 20 km/h).
var zone_cap := INF
@export var accel := 15.0
@export var brake_decel := 30.0
@export var reverse_speed := 7.0
@export var grip := 16.0
@export var drift_grip := 5.0
## Steering (loop 2a): the most the car turns (rad/s) is turn_cap when slow and
## turn_pull / speed + turn_floor at speed (turn_pull is the sideways pull, m/s²).
@export var turn_cap := 1.8
@export var turn_pull := 10.0
@export var turn_floor := 0.3
## Turning from a standstill with the gas fully on (rad/s); it needs ~2 m/s for full lock.
@export var pivot := 1.4
## Steering input smoothing (s).
@export var steer_time := 0.14
## How much of the gas the car answers with at once (0..1): the rest builds with the gas held,
## so a light touch pulls away gently (Cruise 0.25, Sport 0.35).
@export var onset := 0.25
## G4 (F, 2026-11-01): "very drifty and sensitive, this is a city, not a racer". Two handling
## profiles of the same car (settings.gd `handling`, Settings → Jazda): CRUISE (the default) holds
## the road (stronger grip, a lower steering limit at speed, slower steering, a softer gas) and
## SPORT is the loop 2a feel. `set_handling` writes the numbers; check_handling.gd measures both.
enum Handling { CRUISE, SPORT }
const PROFILES := {
	Handling.CRUISE: {"grip": 16.0, "drift_grip": 5.0, "turn_cap": 1.8, "turn_pull": 10.0, "turn_floor": 0.3,
			"pivot": 1.4, "steer_time": 0.14, "onset": 0.25},
	Handling.SPORT: {"grip": 9.0, "drift_grip": 1.6, "turn_cap": 2.3, "turn_pull": 18.0, "turn_floor": 0.35,
			"pivot": 1.5, "steer_time": 0.08, "onset": 0.35},
}
var handling := Handling.CRUISE
## F (2026-11-01): "adjustments of the car's reactions, like the sensitivity of the driving" (Settings
## → Jazda, settings.gd `sensitivity` 0..1, 0.5 the profile as is). A multiplier on how hard the
## wheel turns the car and how fast it answers: SENS_MIN at the slider's left end, SENS_MAX at its right.
const SENS_MIN := 0.6
const SENS_MAX := 1.4
var steer_gain := 1.0
## G13 (the upgrade shop, garage.gd / upgrades.gd): the model on the road ("hatch", or "tt", the
## "Ołdi TT" parody), the tuning multipliers (engine: top speed and pull, tyres: grip) and nitro.
## All 1.0 / off by default, so a car nobody has tuned drives exactly as before.
var model := "hatch"
## The coffee run (coffee_run.gd): the player swaps the car for a ROWERILO bike at a dock. On the
## bike (model "bike") the top speed is BIKE_TOP whatever the engine, the pull BIKE_PULL of the
## car's and NITRO never lights; the collision box stays the car's (the same stuck and kerb rules).
const BIKE_TOP := 8.5
const BIKE_PULL := 0.55
var top_mult := 1.0
var accel_mult := 1.0
var grip_mult := 1.0
## NITRO ("Kebab Boost"): bought at the garage. Held, it opens the gas fully and lifts the top speed by
## NITRO_TOP and the pull by NITRO_ACCEL for NITRO_SECONDS of a full tank; the tank refills in
## NITRO_REFILL s once released, and one that ran dry waits for the button to be let go.
const NITRO_TOP := 1.3
const NITRO_ACCEL := 2.2
const NITRO_SECONDS := 3.5
const NITRO_REFILL := 20.0
const NITRO_MIN := 0.25
var nitro_owned := false
## The button (hud.gd's, Shift, or LB / RB on a pad) is held.
var nitro_hold := false
var nitro_on := false
var nitro_charge := 1.0
var _nitro_dry := false
## Point-to-steer: heading error (rad) to yaw rate (rad/s), and the yaw damping.
@export var point_gain := 6.0
@export var yaw_damping := 0.4
## Pointing more than this far off the nose at more than BRAKE_TURN_SPEED: brake first.
const BRAKE_TURN_ANGLE := deg_to_rad(110.0)
const BRAKE_TURN_SPEED := 5.0
## Pointing more than this far off the nose: hold the speed (above a crawl) until it has turned.
const TURN_HOLD_ANGLE := deg_to_rad(30.0)
const TURN_CRAWL := 6.0
## Walls: scraping friction (1/s), how fast a glancing hit turns the car along the wall
## (rad/s), the push back off a head-on hit (share of the speed lost, at most 1.2 m/s),
## and how long it may sit pinned before it is turned out (s).
const SCRAPE := 1.2
## PT-1 (2026-11-02): the scrape scales with how hard the car presses into the wall: full at
## SCRAPE_PRESS m/s into it, down to SCRAPE_MIN of it running parallel along a fence (it lost
## 30 → 17 m/s in 0.8 s brushing Marszałkowska's tram-stop fence, 1.2/s of the whole speed).
const SCRAPE_PRESS := 3.0
const SCRAPE_MIN := 0.15
const WALL_TURN := 3.0
const WALL_PUSH := 0.12
const UNSTICK_TIME := 1.5
## The driving-feel loop: corner slip. A touch this near a front corner (m in from the side)
## sidesteps the car past the thing it clipped at up to SLIP_RATE m/s, keeping SLIP_KEEP of
## its speed; the bump it reports is SLIP_HIT of a full one (traffic, jars, ride stars).
const SLIP_REACH := 0.6
const SLIP_RATE := 7.0
const SLIP_KEEP := 0.96
const SLIP_HIT := 0.35
## Pushing into a car or a tram (not fixed) this long with the gas on and going nowhere: steer
## round it as round a wall.
const CAR_PUSH_TIME := 0.35
## Classic against a wall: the strip leaning more than this picks the side the car slides off to.
const CLASSIC_WALL_LEAN := 0.2
## G17 ("stuck with another cars"): held against a traffic car or tram this long with the gas on
## and going nowhere, the car ghosts through it for GHOST_TIME s (a collision exception, never
## for walls); still among cars within JAM_RADIUS m of where it began after JAM_TIME s, `jammed`.
const GHOST_PUSH_TIME := 1.5
const GHOST_TIME := 3.0
const JAM_TIME := 8.0
const JAM_RADIUS := 4.0
## The stuck offer (G14's "later", 2026-11-03): trying to drive (gas, brake or the stick) for
## STALL_TIME s in all and still within STALL_RADIUS m of where it began, whatever holds it (a
## wall nothing pins it against, a gap inside a building, a ledge): `stalled` reaches STALL_TIME
## and the game offers the tow on the context button. Time off the controls neither counts nor
## resets it; leaving the spot does. Parked, held by the stop assist or in the water: never.
## PT-24 (2026-11-06): the spot was 4 m, so backing off a wall to take another run at it (5-8 m
## back) started the count again every try; 10 m holds a ram-and-reverse in one spot, and a car
## that drives on still leaves it in a couple of seconds.
const STALL_TIME := 8.0
const STALL_RADIUS := 10.0
## The driving-feel loop (the ram test): the share of the speed going into a car or a tram that
## is kept for the next frame (it was none: a rear-ended car stopped the player dead).
const CAR_KEEP := 0.5
## Loop 10a: in the water it loses speed at this rate (1/s: from 91 km/h it stops within
## ~6 m) and settles this far (m) into it.
const WATER_DRAG := 4.0
const SINK := 0.45
## Loop 3b-2: kerbs you feel. Hopping a kerb keeps KERB_JOLT of the speed and bounces the body
## KERB_BOUNCE m; rolling over an island or a grass median loses KERB_DRAG of the speed per
## second (map_builder.kerb_feel says where; drive_height lifts the car onto them).
const KERB_JOLT := 0.97
const KERB_BOUNCE := 0.07
const KERB_DRAG := 0.25
## The driving-feel loop: kerbs crossed within this long of the last jolt (s) are felt as one.
const KERB_GAP := 0.5
## The look loop (2026-10-28): how strongly the paint and the roof and bonnet stripes light
## from within at night (actor.gdshader's hero part; share of their own colour), so the
## car reads at least 30 luma over the road under it (it was 20-50 darker).
const HERO_PAINT := 1.4
const HERO_STRIPE := 0.3

## Inputs, set every frame by the game. steer > 0 turns left. throttle 0..1 is the
## share of top speed to drive at (1: flat out).
var throttle := 0.0
var steer := 0.0
var braking := false
## Loop 2b: the game has parked the car (the title screen, the player flying): it holds
## still on the brake (a held brake at a standstill would reverse it into whatever is
## behind) and never counts as pinned. A player holding BRAKE to reverse is not parked.
var parked := false
## Quest stop assist (2026-10-31, stop_assist.gd): stopping exactly in a small ring with a finger
## was the hardest part of every pickup and drop-off. The game sets assist_at to the ring of the
## quest on now (Vector3.INF: none) and assist_reach to its radius; the car then caps its own
## speed so it glides in and stops inside the ring, and holds still there for up to
## StopAssist.HOLD s while the quest's hold runs. Holding BRAKE at a standstill (reverse) lets
## go at once; either way it does not grab again until the car has left the ring.
var assist_at := Vector3.INF
var assist_reach := 0.0
## True while the assist slows or holds the car this step (the HUD's hint reads it).
var assisting := false
var _assist_held := 0.0
var _assist_spent := false
## Point-to-steer: when not zero, the car turns towards this world direction.
var target_dir := Vector3.ZERO
## Beta values (2026-11-04): the lane assist ("Asysta pasa", lane_assist.gd), on from Settings →
## Jazda (off by default), and the direction of the lane the car drives in (main.gd sets it 10 times
## a second; ZERO: none). Classic only: with a target_dir (Point, Fixed) it does nothing.
var lane_assist := false
var lane_dir := Vector3.ZERO
## The assist's yaw rate this step (rad/s), for the checks.
var lane_pull := 0.0
## What the car does this step (loop 2a): the brakes are on (the button, or pointing well
## behind at speed: skids and the tyres' squeal read this), the smoothed steering, and
## the yaw rate (rad/s, + is left).
var brakes_on := false
var steer_now := 0.0
var yaw_rate := 0.0
## How many times it has been turned out of a wall (check_steering.gd counts them).
var unsticks := 0
## Loop 10a: whether a car at (x, z, height) is in the water (the game sets map.in_water). A
## car with its collision off (the testing autopilots glide through walls) or parked never
## splashes.
var water_at: Callable = func(_x: float, _z: float, _y: float) -> bool: return false
## Loop 3b-2: what the ground does to the car on its way from one spot to the next (the game sets
## map.kerb_feel): x the raise under the new spot (an island, a median), y 1 if it crossed a kerb.
var kerb_feel: Callable = func(_from: Vector2, _to: Vector2, _y: float) -> Vector2: return Vector2.ZERO
var _last_xz := Vector2.INF
var _bounce := 0.0
## Loop 10a: in the water, waiting for the tow; how long it has been in.
var in_water := false
var _sink := 0.0

## Height of the road surface under a point for a car at height y; set by the game
## (terrain and bridge decks: a deck overhead is not the road).
var ground_height: Callable = func(_x: float, _z: float, _y: float) -> float: return 0.0
var vel := Vector3.ZERO
var forward_speed := 0.0
## Times the car's state left the numbers (NaN or infinity) and was put back (loop 3h slice 4).
var nan_recoveries := 0
## check_finite.gd's poisoned cars: count the recoveries without the warning (it expects them).
var nan_quiet := false
var _good_xform := Transform3D.IDENTITY
var _good_seen := false
## The state as the last physics step began (the NaN report says what went in).
var _pre_step: Array = []
## Sideways speed in m/s; high when the tail slides (skid marks, the tyres' squeal).
var slip := 0.0
## 0..1, how wet the road is (weather.gd): a little less grip and braking in the rain.
var wet := 0.0
var _bump_cooldown := 0.0
var _sound_cooldown := 0.0
var _turn_side := 0.0
var _contact := 0.0
## Phase 0.2: trying to drive this frame (gas, brake or the stick), for struggling().
var _trying := false
## Seconds left of the last touch of something fixed (a wall, a kiosk, a parked car), not a
## moving car or tram: only those can pin the car (a queue at a red light is not "stuck").
var _fixed_contact := 0.0
var _wall_normal := Vector3.ZERO
## The walls touched since the car was last pinned somewhere new (a corner's two walls).
var _wall_normals := PackedVector3Array()
## Which way along a wall it follows when pointed straight into it (+1 / -1; 0: not chosen).
var _wall_side := 0.0
## The driving-feel loop: how long it has pushed into a car or tram going nowhere (s).
var _car_push := 0.0
## G17: the traffic cars and trams the car ghosts through (body -> seconds left), and how long it
## has been among cars near `_jam_at` (s).
var _ghosted := {}
var _jam := 0.0
var _car_hold := 0.0
var _hold_at := Vector2.ZERO
var _jam_at := Vector2.ZERO
## The stuck offer: seconds spent trying near `_stall_at` (main.gd reads it).
var stalled := 0.0
var _stall_at := Vector2.INF
## The driving-feel loop: seconds since the last kerb jolt.
var _kerb_wait := KERB_GAP
var _pinned := 0.0
var _pin_at := Vector2.ZERO
var _last_unstick := -100.0
var _clock := 0.0
var _body: Node3D
var _headlights: Array[StandardMaterial3D] = []
var _tails: Array[StandardMaterial3D] = []
var _beams: Node3D
## G13b: the nitro's flame behind the tail, shown while it burns.
var _flame: Node3D
var _night_beams: MeshInstance3D
var _spot: SpotLight3D
var _flash := 0.0
## The garage loop: the body's paint and stripes and their night glow (garage.gd PAINTS; the
## factory red by default), and the body's MeshInstance3D, whose mesh `set_paint` makes again.
var paint := Color("#d8432f")
var stripe := Color("#f4efe4")
var paint_glow := HERO_PAINT
var stripe_glow := HERO_STRIPE
var _body_mesh: MeshInstance3D
## 0..1, how far the city's lights are on (time_of_day.gd); the game sets it every frame.
var lights := 0.0:
	set(value):
		var changed := (value > 0.001) != (lights > 0.001)
		lights = value
		if changed and is_node_ready():
			_apply_lights()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 4.0)
	shape.shape = box
	shape.position.y = 0.8
	add_child(shape)
	_body = _make_body()
	add_child(_body)
	_beams = _make_beams()
	_body.add_child(_beams)
	_flame = _make_flame()
	_body.add_child(_flame)
	_night_beams = MeshInstance3D.new()
	# The look loop: the player's cone a little stronger and longer than traffic's.
	_night_beams.mesh = Models.headlight_pools(2.05, 0.58, 17.0, true, 0.52)
	_night_beams.material_override = Models.glow_material()
	_night_beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_night_beams)
	# One real light, the player's own: it catches walls, cars and trees ahead.
	_spot = SpotLight3D.new()
	_spot.light_color = Color("#ffe6b8")
	_spot.light_energy = 3.0
	_spot.spot_range = 34.0
	_spot.spot_angle = 34.0
	_spot.spot_attenuation = 0.8
	_spot.shadow_enabled = false
	_spot.position = Vector3(0, 1.0, -2.2)
	_spot.rotation.x = deg_to_rad(-14.0)
	_body.add_child(_spot)
	_apply_lights()


## Lamps, cones and the spotlight follow the city's lights.
func _apply_lights() -> void:
	var night := lights > 0.001
	# Emission stays enabled and only its energy changes, so no shader variant has
	# to compile when the lamps come on.
	for m in _headlights:
		m.emission_energy_multiplier = 4.0 if night or _beams.visible else 0.0
	for m in _tails:
		m.emission_energy_multiplier = 3.0 if night else 0.0
	_night_beams.visible = night and model != "bike"
	_spot.visible = night


## Two quick flashes of the headlights.
func flash_lights() -> void:
	_flash = 0.55


func _process(dt: float) -> void:
	# G13b: the nitro's flame flickers while it burns (one small unshaded mesh, hidden otherwise).
	if nitro_on != _flame.visible:
		_flame.visible = nitro_on
	if nitro_on:
		_flame.scale = Vector3(1.0, 1.0, 0.8 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.045)) + 0.2 * randf())
	if _flash <= 0.0 and not _beams.visible:
		return
	_flash -= dt
	var on := _flash > 0.0 and (_flash > 0.38 or _flash < 0.2)
	_beams.visible = on
	for m in _headlights:
		m.emission_energy_multiplier = 4.0 if on or lights > 0.001 else 0.0


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_pre_step = [global_transform, vel, target_dir, steer, steer_now, yaw_rate, throttle, braking, parked, collision_mask, in_water]
	_clean_inputs()
	_step(dt)
	_keep_finite()
	spent_usec += Time.get_ticks_usec() - t0


## The NaN car (2026-11-02): the stick, the steering and the pedals come from many writers (the
## controls, the police's test drivers, the autopilots, the guide). One that is not a number would
## turn the car by NaN (`signed_angle_to`, then `rotate_y`) and poison its rotation for good, so it
## is dropped here, before the step, and counted with the other recoveries (check_finite.gd).
func _clean_inputs() -> void:
	var dirty := false
	if not target_dir.is_finite():
		target_dir = Vector3.ZERO
		dirty = true
	if not is_finite(steer):
		steer = 0.0
		dirty = true
	if not is_finite(throttle):
		throttle = 0.0
		dirty = true
	if not is_finite(steer_now) or not is_finite(yaw_rate):
		steer_now = 0.0
		yaw_rate = 0.0
		dirty = true
	if dirty:
		nan_recoveries += 1
		if not nan_quiet:
			push_warning("car: an input was not a number (target_dir, steer, throttle or the steering state), dropped (recovery %d); the step began with %s"
					% [nan_recoveries, _pre_step])


## A safety net (loop 3h slice 4): once in ~10 headless first-10 replays the car's position went
## NaN at a rescue pickup (not seen again in 55 replays since, nor found by check_finite.gd's sweep
## of the map's heights, lanes and the car's step; BACKLOG "From loop 3h slice 4"), and a NaN car
## poisons everything that measures from it (every Syrenka "found", the police lookups). If the
## position, rotation or velocity is not a number after a step, the car goes back to its last good
## transform, stopped, and the event is logged once per occurrence.
func _keep_finite() -> void:
	var x := global_transform
	if x.origin.is_finite() and x.basis.x.is_finite() and x.basis.z.is_finite() and vel.is_finite() \
			and is_finite(forward_speed):
		_good_xform = x
		_good_seen = true
		return
	nan_recoveries += 1
	if not nan_quiet:
		push_warning("car: state not a number (pos %s, vel %s, basis z %s, fwd speed %s), put back at %s (recovery %d); the step began with %s"
				% [x.origin, vel, x.basis.z, forward_speed, _good_xform.origin, nan_recoveries, _pre_step])
	vel = Vector3.ZERO
	velocity = Vector3.ZERO
	forward_speed = 0.0
	steer_now = 0.0
	yaw_rate = 0.0
	if not _body.rotation.is_finite():
		_body.rotation = Vector3.ZERO
	if _good_seen:
		global_transform = _good_xform
	reset_physics_interpolation()


## The quest stop assist's speed cap for this step (INF: free): ahead of the ring, the speed from
## which StopAssist.DECEL still stops the car at the ring's centre; inside it, 0 for up to
## StopAssist.HOLD s at a standstill. Only when the car heads into the ring (the centre in front,
## the line of travel through the ring), so driving past or away is never touched.
func _assist_cap(speed: float, fwd: Vector3, dt: float) -> float:
	assisting = false
	if assist_at == Vector3.INF or parked or in_water or assist_reach <= 0.0 or not Access.stop_assist:
		_assist_spent = false
		_assist_held = 0.0
		return INF
	var p := global_position
	var rel := Vector2(assist_at.x - p.x, assist_at.z - p.z)
	var d := rel.length()
	if d > assist_reach + StopAssist.LEAVE:
		_assist_spent = false
		_assist_held = 0.0
	# Reversing out (BRAKE held at a crawl) or a tight spot across a level: the player decides.
	if _assist_spent or (braking and speed < 0.5) or absf(assist_at.y - p.y) > 3.0:
		if d <= assist_reach + StopAssist.LEAVE and (braking and speed < 0.5):
			_assist_spent = true
		return INF
	if d < assist_reach - StopAssist.INSIDE:
		if absf(speed) < 0.3:
			_assist_held += dt
			if _assist_held >= StopAssist.HOLD:
				_assist_spent = true
				return INF
		assisting = true
		return 0.0
	if speed < 0.5 or d > StopAssist.LOOK:
		return INF
	var f2 := Vector2(fwd.x, fwd.z).normalized()
	var along := rel.dot(f2)
	if along <= 0.0 or absf(rel.cross(f2)) > assist_reach - StopAssist.INSIDE:
		return INF
	var cap := sqrt(2.0 * StopAssist.DECEL * maxf(along - 1.0, 0.0))
	assisting = speed > cap
	return cap


func _step(dt: float) -> void:
	_clock += dt
	if in_water:
		_float(dt)
		return
	var fwd := _forward()
	var speed := vel.dot(fwd)
	var gas := clampf(throttle, 0.0, 1.0)
	# The speed the gas asks for (a share of top speed); a big point-to-steer turn caps it.
	_nitro_tick(dt)
	if nitro_on:
		gas = 1.0
	var top := minf(top_speed(), zone_cap) * gas
	var brake_now := braking
	var turn := max_turn(absf(speed), gas)
	# Moving backwards the car turns the other way for the same steering.
	var backwards := -1.0 if speed < -0.3 else 1.0

	var s := steer
	if target_dir != Vector3.ZERO:
		var want := target_dir
		# Reversing (the brake held at a standstill or going back): the tail goes where you point.
		if braking and speed < 0.5:
			want = -want
		# Touching a wall and pointing into it: follow the wall the way the stick leans
		# (straight into it: the way the nose leans) instead of pushing against it. A car or
		# tram only once the car has pushed into it for CAR_PUSH_TIME (a touch in a queue
		# doesn't send it round; holding the gas against one does).
		if _contact > 0.0 and (_fixed_contact > 0.0 or _car_push > CAR_PUSH_TIME) and _wall_normal != Vector3.ZERO:
			var into_wall := want.dot(_wall_normal)
			if into_wall < -0.05:
				var along := want - _wall_normal * into_wall
				if along.length() < 0.25:
					# Picked once per touch: nose-on, the choice would flip every frame.
					var t := _wall_normal.cross(Vector3.UP)
					if _wall_side == 0.0:
						_wall_side = 1.0 if t.dot(fwd * backwards) >= 0.0 else -1.0
					along = t * _wall_side
				want = along.normalized()
		var err := fwd.signed_angle_to(want, Vector3.UP)
		# Pointing straight back: keep turning the way it started, never flip-flop at ±180°.
		if absf(err) > 2.8 and _turn_side != 0.0 and signf(err) != _turn_side:
			err = _turn_side * (TAU - absf(err))
		if absf(err) > 0.2:
			_turn_side = signf(err)
		# A yaw rate from the error, damped by the rate it already turns at: it settles
		# on the direction without swinging past it.
		var rate := err * point_gain - yaw_rate * yaw_damping
		s = clampf(rate / maxf(turn, 0.05), -1.0, 1.0) * backwards
		if not braking:
			var off := absf(err)
			if off > BRAKE_TURN_ANGLE and speed > BRAKE_TURN_SPEED:
				# Well behind at speed: brake first (the tail may slide round), then turn.
				brake_now = true
				gas = 0.0
			elif off > TURN_HOLD_ANGLE and gas > 0.0:
				# A big turn: no faster than now (off the gas), so the turn stays tight;
				# from a crawl it still pulls away briskly.
				top = minf(top, maxf(speed, TURN_CRAWL))
	else:
		_turn_side = 0.0
		var w := _classic_wall_steer(fwd, speed, gas)
		if w != 0.0:
			# Collision rework v2, step 1: the player's own steering wins when it turns harder
			# the same way (or away from the wall); otherwise the wall's line does.
			s = signf(w) * maxf(absf(w), absf(s)) if signf(s) == signf(w) else w
			# Turning off the wall from a crawl: hold the speed until it has turned, as Point does.
			top = minf(top, maxf(speed, TURN_CRAWL))
	steer_now = lerpf(steer_now, clampf(s, -1.0, 1.0), 1.0 - exp(-dt / (steer_time / steer_gain)))
	var yaw := steer_now * max_turn(absf(speed), maxf(gas, throttle)) * backwards
	lane_pull = _lane_pull(fwd, speed)
	if lane_pull != 0.0:
		var most := max_turn(absf(speed), maxf(gas, throttle))
		yaw = clampf(yaw + lane_pull, -most, most)
	rotate_y(yaw * dt)
	yaw_rate = yaw

	fwd = _forward()
	speed = vel.dot(fwd)
	var lateral := vel - fwd * speed
	slip = lateral.length()

	if brake_now:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, brake_decel * (1.0 - 0.15 * wet) * dt)
		elif parked:
			speed = move_toward(speed, 0.0, brake_decel * dt)
		else:
			speed = move_toward(speed, -reverse_speed, accel * 0.6 * dt)
	elif gas > 0.0:
		# The gas sets a speed to drive at; a light push accelerates gently.
		if speed < top:
			speed = minf(top, speed + accel * (BIKE_PULL if model == "bike" else accel_mult) * (NITRO_ACCEL if nitro_on else 1.0) * (onset + (1.0 - onset) * gas) * dt * (1.0 - 0.6 * clampf(speed / top_speed(), 0.0, 1.0)))
		else:
			speed = move_toward(speed, top, 4.0 * dt)
	else:
		speed = move_toward(speed, 0.0, 5.0 * dt)
	speed = minf(speed, BIKE_TOP if model == "bike" else max_speed * top_mult * NITRO_TOP)
	var cap := _assist_cap(speed, fwd, dt)
	if speed > cap:
		speed = move_toward(speed, cap, brake_decel * dt)
		brake_now = true
	brakes_on = brake_now

	# Wet roads: the tail lets go a little sooner and slides a little longer.
	var g := (drift_grip if brake_now and speed > 10.0 else grip) * (1.0 - 0.22 * wet)
	lateral *= exp(-g * dt)
	vel = fwd * speed + lateral

	velocity = vel
	move_and_slide()
	var hits := get_slide_collision_count()
	var slipped := hits > 0 and _corner_slip(speed, dt)
	if hits > 0:
		var lost := (vel - velocity).length()
		# Also the closing speed along the contact normal: moving bodies (traffic) push
		# the car out rather than stop it, so the speed lost alone misses those hits.
		var hit := get_slide_collision(0)
		lost = maxf(lost, -vel.dot(hit.get_normal()))
		if slipped:
			# A clipped corner is a knock, felt once (it slips past over a few frames).
			lost = lost * SLIP_HIT if _contact <= 0.0 else 0.0
		if lost > 2.0:
			bumped.emit(hit.get_collider(), lost)
		_bump_cooldown -= dt
		_sound_cooldown -= dt
		if lost > 2.5 and _sound_cooldown <= 0.0:
			hit_point = hit.get_position()
			hit_normal = hit.get_normal()
			impact.emit(hit.get_collider(), lost)
			_sound_cooldown = 0.35
		if lost > 4.0 and _bump_cooldown <= 0.0:
			# A short buzz on the phone for a real hit, not for scraping along a wall.
			Haptics.knock(lost)
			_bump_cooldown = 0.35
		var n := Vector3.ZERO
		var slid := vel
		var fixed := false
		var press := 0.0
		for k in hits:
			# (An AnimatableBody3D, traffic's and the trams' bodies, is a StaticBody3D too: not fixed.)
			var other := get_slide_collision(k).get_collider()
			if other is StaticBody3D and not other is AnimatableBody3D:
				_fixed_contact = 0.25
				fixed = true
			var nk := get_slide_collision(k).get_normal()
			nk.y = 0.0
			n += nk
			# move_and_slide (floating) slides the motion but leaves the velocity pointing into
			# the wall: take the part going into each contact out of it.
			if nk.length() > 0.01:
				nk = nk.normalized()
				var known := false
				for w in _wall_normals:
					known = known or w.dot(nk) > 0.9
				if not known and _wall_normals.size() < 6:
					_wall_normals.append(nk)
				press = maxf(press, -vel.dot(nk))
				var into_k := slid.dot(nk)
				if into_k < 0.0:
					slid -= nk * into_k
		var first := _contact <= 0.0
		if n.length() > 0.01:
			n = n.normalized()
			_wall_normal = n
		# Against a car or a tram (nothing fixed), trying to go on and getting nowhere.
		if not fixed and not parked and (gas > 0.1 or target_dir != Vector3.ZERO) and absf(speed) < 2.0:
			_car_push += dt
		elif fixed:
			_car_push = 0.0
		# G17: held among traffic cars (touching only them, under 1.5 m from where it began),
		# however much it jiggles between them: the speed alone flips above and below 2 m/s.
		var here_xz := Vector2(global_position.x, global_position.z)
		if not fixed and not parked and (gas > 0.1 or target_dir != Vector3.ZERO):
			if _car_hold <= 0.0 or here_xz.distance_to(_hold_at) > 1.5:
				_hold_at = here_xz
				_car_hold = dt
			else:
				_car_hold += dt
		else:
			_car_hold = 0.0
		if _car_hold > GHOST_PUSH_TIME:
			# G17: held against traffic this long: pass through those cars for a moment.
			for k in hits:
				var body := get_slide_collision(k).get_collider() as PhysicsBody3D
				if body != null:
					if not _ghosted.has(body):
						add_collision_exception_with(body)
					_ghosted[body] = GHOST_TIME
			_car_hold = 0.0
		# v1.0 juice: sparks while sliding along something fixed at speed.
		_scrape_wait -= dt
		if fixed and not slipped and _scrape_wait <= 0.0 and slid.length() > 6.0:
			_scrape_wait = SCRAPE_EVERY
			scraped.emit(hit.get_position(), hit.get_normal(), slid.length())
		# What slides along the wall is kept, less a little scrape (loop 2a; it lost 8 % a frame),
		# lighter the less it presses in (PT-1: brushing a fence along the kerb).
		vel = slid * exp(-SCRAPE * clampf(press / SCRAPE_PRESS, SCRAPE_MIN, 1.0) * dt)
		if not fixed and not slipped:
			# A car or a tram gives way (traffic is shoved): keep CAR_KEEP of what went into it,
			# not a dead stop; something that doesn't move takes the rest on the next frames.
			vel += (fwd * speed + lateral - slid) * CAR_KEEP
		if slipped:
			# Slipping past a clipped corner: it keeps its speed (the next frames carry it past).
			vel = fwd * speed * (SLIP_KEEP if first else 1.0) + lateral
			n = Vector3.ZERO
			_wall_normal = Vector3.ZERO
		if n != Vector3.ZERO:
			var f := _forward()
			var into := -f.dot(n)
			var along := f - n * f.dot(n)
			if into > 0.05 and into < 0.9 and along.length() > 0.05 and speed > 0.0:
				# A glancing hit: turn the nose along the wall so it slides on.
				var a := f.signed_angle_to(along.normalized(), Vector3.UP)
				rotate_y(clampf(a, -WALL_TURN * dt, WALL_TURN * dt))
			if first and lost > 1.0:
				# A small push back off the wall (out of corners too).
				vel += n * minf(lost * WALL_PUSH, 1.2)
		_contact = 0.25
	else:
		vel = velocity
		_bump_cooldown = 0.0
		_sound_cooldown = 0.0
		_contact -= dt
		if _contact <= 0.0:
			_wall_side = 0.0
			_car_push = 0.0
			_car_hold = 0.0
	vel.y = 0.0
	global_position.y = ground_height.call(global_position.x, global_position.z, global_position.y)
	_feel_kerbs(dt)
	forward_speed = vel.dot(_forward())
	_fixed_contact -= dt
	if not parked and collision_mask != 0 and water_at.call(global_position.x, global_position.z, global_position.y):
		in_water = true
		_sink = 0.0
		_pinned = 0.0
		splashed.emit(vel.length())
		return

	# Pinned: touching something fixed with the gas or the brake on, and getting nowhere (under
	# a metre from where it was pinned, however much it jiggles between a wall and a car).
	# Nosing into the car ahead in a queue doesn't count: traffic moves on by itself. A car
	# the game has parked (loop 2b) is never "trying".
	var trying := not parked and (gas > 0.1 or brake_now or target_dir != Vector3.ZERO)
	_trying = trying
	var here := Vector2(global_position.x, global_position.z)
	if _contact > 0.0 and (_fixed_contact > 0.0 or _car_push > CAR_PUSH_TIME) and trying:
		if _pinned <= 0.0 or here.distance_to(_pin_at) > 1.0:
			_pin_at = here
			_pinned = dt
			_wall_normals.clear()
			if _wall_normal != Vector3.ZERO:
				_wall_normals.append(_wall_normal)
		else:
			_pinned += dt
		if _pinned >= UNSTICK_TIME:
			_unstick()
	else:
		_pinned = 0.0
		if _contact <= 0.0:
			_wall_normals.clear()

	# G17: the ghosting runs out; among cars for JAM_TIME s near one spot: ask the game for a tow.
	for body: PhysicsBody3D in _ghosted.keys():
		_ghosted[body] -= dt
		if _ghosted[body] <= 0.0 or not is_instance_valid(body):
			_ghosted.erase(body)
			if is_instance_valid(body):
				remove_collision_exception_with(body)
	if trying and (_car_hold > 0.0 or _car_push > 0.0 or not _ghosted.is_empty()) and _fixed_contact <= 0.0:
		if _jam <= 0.0 or here.distance_to(_jam_at) > JAM_RADIUS:
			_jam_at = here
			_jam = dt
		else:
			_jam += dt
			if _jam >= JAM_TIME:
				_jam = 0.0
				jammed.emit()
	else:
		_jam = 0.0

	# The stuck offer: the time spent trying near one spot (a car that drives off starts again).
	if _stall_at == Vector2.INF or here.distance_to(_stall_at) > STALL_RADIUS:
		_stall_at = here
		stalled = 0.0
	if trying and not assisting and collision_mask != 0:
		stalled += dt

	# Lean into turns and squat under braking, just for the look.
	var lean := clampf(lateral.dot(global_transform.basis.x) * 0.012, -0.08, 0.08)
	_body.rotation.z = lerpf(_body.rotation.z, lean, 1.0 - exp(-10.0 * dt))
	var pitch := 0.03 if brake_now and speed > 1.0 else (-0.02 if gas > 0.0 else 0.0)
	_body.rotation.x = lerpf(_body.rotation.x, pitch, 1.0 - exp(-8.0 * dt))


## Loop 3b-2: a kerb hopped takes a little speed and bounces the body; an island or a median
## under the car drags like rough ground. Not for a car with its collision off (the testing
## autopilots) or parked.
func _feel_kerbs(dt: float) -> void:
	var here := Vector2(global_position.x, global_position.z)
	_kerb_wait += dt
	# (A jump of more than 5 m is a tow or a landing, not a drive.)
	if collision_mask != 0 and not parked and _last_xz != Vector2.INF and here != _last_xz and here.distance_to(_last_xz) < 5.0:
		var feel: Vector2 = kerb_feel.call(_last_xz, here, global_position.y)
		if feel.y > 0.0 and vel.length() > 1.5 and _kerb_wait >= KERB_GAP:
			vel *= KERB_JOLT
			_bounce = KERB_BOUNCE
			_kerb_wait = 0.0
		if feel.x > 0.0:
			vel *= exp(-KERB_DRAG * dt)
	_last_xz = here
	if _bounce > 0.0 or _body.position.y != 0.0:
		_bounce = maxf(_bounce - dt * 0.6, 0.0)
		_body.position.y = _bounce


## Loop 10a: in the water: no engine, no grip, no steering; it glides to a stop, settles
## SINK metres nose first and bobs.
func _float(dt: float) -> void:
	vel *= exp(-WATER_DRAG * dt)
	vel.y = 0.0
	velocity = vel
	move_and_slide()
	vel = Vector3(velocity.x, 0.0, velocity.z)
	global_position.y = ground_height.call(global_position.x, global_position.z, global_position.y)
	forward_speed = vel.dot(_forward())
	slip = 0.0
	brakes_on = false
	steer_now = 0.0
	yaw_rate = 0.0
	_sink += dt
	var settle := SINK * (1.0 - exp(-5.0 * _sink))
	_body.position.y = -settle + sin(_sink * 7.0) * 0.04 * minf(_sink * 2.0, 1.0)
	_body.rotation.x = lerpf(_body.rotation.x, -0.09, 1.0 - exp(-6.0 * dt))
	_body.rotation.z = lerpf(_body.rotation.z, sin(_sink * 4.5) * 0.03, 1.0 - exp(-6.0 * dt))


## Loop 10a: the tow has put the car back on dry land (the game moves it first).
func leave_water() -> void:
	in_water = false
	_sink = 0.0
	reset_motion()


## The stuck offer starts again from here (a tow has just moved the car, maybe only a few metres).
func reset_stall() -> void:
	stalled = 0.0
	_stall_at = Vector2.INF


## Stopped, with nothing of the last contact kept (no pin, no wall, no bounce): a car the game
## has just moved (the water's tow, the pause card's unstuck button, 2026-11-01).
func reset_motion() -> void:
	_body.position.y = 0.0
	_bounce = 0.0
	_last_xz = Vector2.INF
	_body.rotation = Vector3.ZERO
	vel = Vector3.ZERO
	velocity = Vector3.ZERO
	forward_speed = 0.0
	steer_now = 0.0
	_pinned = 0.0
	_contact = 0.0
	_fixed_contact = 0.0
	_wall_normals.clear()
	_car_push = 0.0
	_car_hold = 0.0
	_jam = 0.0
	reset_stall()
	for body: PhysicsBody3D in _ghosted.keys():
		if is_instance_valid(body):
			remove_collision_exception_with(body)
	_ghosted.clear()


## F: the steering sensitivity slider (0..1, 0.5 = 1.0) sets `steer_gain`.
func set_sensitivity(level: float) -> void:
	steer_gain = lerpf(SENS_MIN, SENS_MAX, clampf(level, 0.0, 1.0))


## G4: switch the handling profile (see PROFILES); anything else goes with the numbers it sets.
func set_handling(h: int) -> void:
	handling = (h if h in PROFILES else Handling.CRUISE) as Handling
	var p: Dictionary = PROFILES[handling]
	for k: String in p:
		set(k, p[k])
	grip *= grip_mult
	drift_grip *= grip_mult


## G13: the car's top speed now (m/s): the model's and the engine's, with nitro on top.
func top_speed() -> float:
	if model == "bike":
		return BIKE_TOP
	return max_speed * top_mult * (NITRO_TOP if nitro_on else 1.0)


## G13: the shop's tuning (upgrades.gd `stats`): multipliers on top speed, pull and grip. Grip goes
## on the handling profile's numbers (Cruise or Sport still decides how the car steers).
func set_tuning(top: float, pull: float, grip_x: float) -> void:
	top_mult = top
	accel_mult = pull
	grip_mult = grip_x
	set_handling(handling)


## G13: the model on the road: the three body meshes are made again once (a swap, no new node).
func set_model(id: String) -> void:
	model = id if id == "tt" or id == "bike" else "hatch"
	if _night_beams != null:
		_apply_lights()
	if _body != null and _body.get_child_count() >= 3:
		var m := Models.player_meshes(Models.fin(paint, Models.HERO, paint_glow),
				Models.fin(stripe, Models.HERO, stripe_glow), _kind())
		(_body.get_child(0) as MeshInstance3D).mesh = m[0]
		(_body.get_child(1) as MeshInstance3D).mesh = m[1]
		(_body.get_child(2) as MeshInstance3D).mesh = m[2]


func _kind() -> String:
	return "player_tt" if model == "tt" else ("player_bike" if model == "bike" else "player")


## The coffee run: a still copy of the car's three body meshes (the paint, lamps unlit), left at the
## ROWERILO dock while the player rides; the caller adds it to the world and frees it later.
func parked_copy() -> Node3D:
	var root := Node3D.new()
	for i in mini(3, _body.get_child_count()):
		var src := _body.get_child(i) as MeshInstance3D
		if src == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.material_override = src.material_override if i == 0 else Models.material()
		mi.cast_shadow = src.cast_shadow
		root.add_child(mi)
	root.global_transform = global_transform if is_inside_tree() else transform
	return root


## NITRO's tank: drains while it burns, refills when it does not (see NITRO_*).
func _nitro_tick(dt: float) -> void:
	if not nitro_hold:
		_nitro_dry = false
	var want := model != "bike" and nitro_owned and nitro_hold and not _nitro_dry and not parked and not in_water \
			and nitro_charge > 0.0 and (nitro_on or nitro_charge >= NITRO_MIN)
	if want:
		if not nitro_on:
			nitro_started.emit()
		nitro_on = true
		nitro_charge = maxf(0.0, nitro_charge - dt / NITRO_SECONDS)
		if nitro_charge <= 0.0:
			_nitro_dry = true
	else:
		nitro_on = false
		nitro_charge = minf(1.0, nitro_charge + dt / NITRO_REFILL)


## The most the car turns (rad/s) at `v` m/s: turn_cap when slow, turn_pull / v + turn_floor
## at speed; under 2 m/s it fades out, except for a little pivot with the gas on.
## The lane assist's yaw rate (lane_assist.gd yaw_pull): Classic, going forward, not braking, not
## touching anything (the wall follow and the slips have the steering then), on a lane.
func _lane_pull(fwd: Vector3, speed: float) -> float:
	if not lane_assist or lane_dir == Vector3.ZERO or target_dir != Vector3.ZERO or braking or parked \
			or speed < 0.0 or _contact > 0.0:
		return 0.0
	return LaneAssist.yaw_pull(fwd.signed_angle_to(lane_dir, Vector3.UP), steer, speed)


func max_turn(v: float, gas := 0.0) -> float:
	var w := minf(turn_cap, turn_pull / maxf(v, 0.1) + turn_floor)
	var roll := clampf(v / 2.0, 0.0, 1.0)
	return maxf(w * roll, pivot * gas * (1.0 - roll)) * steer_gain


## Classic (steer strip + GAS/BRAKE, the default since 2026-11-04): touching a wall with the
## gas on and the nose into it, the steering that turns the car along the wall, so a head-on
## hit slides off instead of stopping dead ("walls redirect, never stop", docs/design/
## road-objects.md section 7 item 1). Point does the same through its aim (`_step`). The side
## follows the strip once it leans past CLASSIC_WALL_LEAN, else the way the nose leans (picked
## once per touch: nose-on it would flip every frame). 0.0 when not against a wall. A car or
## tram only after CAR_PUSH_TIME of pushing, as in Point; reversing is left to the player.
func _classic_wall_steer(fwd: Vector3, speed: float, gas: float) -> float:
	if parked or braking or gas <= 0.1 or speed < -0.3 or _contact <= 0.0 or _wall_normal == Vector3.ZERO:
		return 0.0
	if _fixed_contact <= 0.0 and _car_push <= CAR_PUSH_TIME:
		return 0.0
	if fwd.dot(_wall_normal) >= -0.05:
		return 0.0
	var t := _wall_normal.cross(Vector3.UP)
	if absf(steer) > CLASSIC_WALL_LEAN:
		# The side the strip turns to: a positive steer turns towards a positive signed angle.
		_wall_side = 1.0 if signf(fwd.signed_angle_to(t, Vector3.UP)) == signf(steer) else -1.0
	elif _wall_side == 0.0:
		_wall_side = 1.0 if t.dot(fwd) >= 0.0 else -1.0
	var err := fwd.signed_angle_to(t * _wall_side, Vector3.UP)
	var rate := err * point_gain - yaw_rate * yaw_damping
	var w := clampf(rate / maxf(max_turn(absf(speed), gas), 0.05), -1.0, 1.0)
	return w if absf(w) > 0.001 else 0.0


## Pinned against a wall: turn the car out of it (towards where the player wants to go,
## or along the wall), step it 0.5 m off and send it off at walking pace. Pinned again
## within 5 s, ask the game for a free spot (`stuck`).
## Phase 0.2 (the chatter budget, chatter.gd): the car is struggling: pinned, pressing into
## something at walking pace, held against traffic, or trying near one spot for half of
## STALL_TIME. The city keeps quiet then (no shouts, no dog walkers, no crowds).
func struggling() -> bool:
	if parked:
		return false
	return _pinned > 0.0 or _car_hold > 0.0 or stalled >= STALL_TIME * 0.5 \
			or (_contact > 0.0 and _trying and absf(forward_speed) < STRUGGLE_SPEED)


## Phase 0.2: slower than this (m/s, ~11 km/h) while touching something and trying counts as struggling.
const STRUGGLE_SPEED := 3.0


func _unstick() -> void:
	_pinned = 0.0
	unsticks += 1
	# Out of everything touched while pinned (both walls of a corner).
	var n := Vector3.ZERO
	for w in _wall_normals:
		n += w
	n = n.normalized() if n.length() > 0.1 else (_wall_normal if _wall_normal != Vector3.ZERO else -_forward())
	# The way it moves: forwards, or backwards while reversing (the tail goes where you point).
	var reverse := braking and forward_speed < 0.5
	var moving := _forward() * (-1.0 if reverse else 1.0)
	var want := target_dir if target_dir != Vector3.ZERO else moving
	var t := n.cross(Vector3.UP).normalized()
	var best := n
	var best_score := -INF
	for c: Vector3 in [n, (n + t).normalized(), (n - t).normalized(), t, -t]:
		# Only ways out: none may lead into a wall it is touching (in a corner, along one
		# wall is into the other).
		var blocked := false
		for w in _wall_normals:
			if c.dot(w) < -0.1:
				blocked = true
		if blocked:
			continue
		# Only headings the car fits in there (a 4 m car turned across a 3 m gap sits half in the
		# walls, and driving on from that pose pushed it out through one: check_stuck_offer's pen).
		if not _fits(n * 0.5, -c if reverse else c):
			continue
		var score := c.dot(want) + 0.1 * c.dot(moving)
		if score > best_score:
			best_score = score
			best = c
	global_position += n * 0.5
	var face := -best if reverse else best
	if best_score == -INF:
		# No way out it fits: keep the heading and ease off the wall.
		face = _forward()
		best = n * 0.5
	rotation.y = atan2(-face.x, -face.z)
	vel = best * 3.0
	forward_speed = vel.dot(_forward())
	steer_now = 0.0
	print("car: pinned %.1f s, turned out of the wall at %.0f, %.0f (heading %03.0f°)" % [UNSTICK_TIME,
			global_position.x, global_position.z, fposmod(rad_to_deg(atan2(face.x, -face.z)), 360.0)])
	# Turned out from between cars (nothing fixed): never sent to a free spot for it.
	if _fixed_contact <= 0.0:
		return
	if _clock - _last_unstick < 5.0:
		stuck.emit()
	_last_unstick = _clock


## Would the car, moved by `step` and facing `face`, sit clear of what it collides with (under
## 0.15 m into it)? For the unstick's choice of heading.
func _fits(step: Vector3, face: Vector3) -> bool:
	var xf := Transform3D(Basis(Vector3.UP, atan2(-face.x, -face.z)), global_position + step)
	var hit := KinematicCollision3D.new()
	return not test_move(xf, Vector3.ZERO, hit, 0.001, true) or hit.get_depth() <= 0.15


## The driving-feel loop: every touch this step is at one front corner (Godot reports the car's
## own corner) and the way on is open within SLIP_REACH to the other side (`test_move` from the
## side-stepped spot, the smallest step that clears): step the car sideways that way (at most
## SLIP_RATE m/s) and say so; the caller keeps its speed. A touch along the flank, both corners
## at once, a face met at an angle (the glancing hit turns along it) or no way past don't slip.
func _corner_slip(speed: float, dt: float) -> bool:
	if speed < 1.0 or parked:
		return false
	var f := _forward()
	var right := f.cross(Vector3.UP)
	var half := Vector2(0.9, 2.0)  # the collision box's half width and half length
	var side := 0.0
	for k in get_slide_collision_count():
		var hit := get_slide_collision(k)
		var rel := hit.get_position() - global_position
		var lat := rel.dot(right)
		var n := hit.get_normal()
		# Met nose on (within ~37°): a wall met at an angle is the glancing hit's to turn along.
		if rel.dot(f) < half.y - 0.8 or absf(lat) < half.x - SLIP_REACH or Vector2(n.x, n.z).normalized().dot(Vector2(f.x, f.z)) > -0.8:
			return false
		var s := -signf(lat)
		if side != 0.0 and s != side:
			return false
		side = s
	if side == 0.0:
		return false
	var away := right * side
	for need: float in [0.15, 0.3, 0.45, SLIP_REACH]:
		if not test_move(global_transform.translated(away * need), f * 0.6):
			move_and_collide(away * minf(need, SLIP_RATE * dt))
			return true
	return false


func _forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()


func _make_body() -> Node3D:
	# A small retro hatchback with twin racing stripes. The front is -Z. Loop 2b: one mesh
	# with vertex colours (one draw call; it was 14 boxes, 14 materials) and each lamp pair
	# one more (their glow). The look loop (2026-10-28): the body is drawn with the actors'
	# material (actor.gdshader, no new shader) as its hero part: at night the paint and the
	# stripes light from within (HERO_PAINT, HERO_STRIPE), so the car is never darker than
	# the road; the stripes are a game pixel wider (0.18 -> 0.3 m) and the tail lamps wrap
	# over the rear deck, so the camera above sees them. Loop 2c (car models): the shape
	# comes from models.gd (player_meshes(): a lofted body with a sloped bonnet and
	# windscreen, a glasshouse narrower at the roof, side windows with pillars, eight-sided
	# wheels in dark arches with light hub caps, black bumpers, a roof spoiler, round head
	# lamps), the stripes running over the nose, bonnet, roof and tailgate; still 3 meshes.
	# The garage loop: the paint and the stripes are the car's (`set_paint`).
	var root := Node3D.new()
	var meshes := Models.player_meshes(Models.fin(paint, Models.HERO, paint_glow),
			Models.fin(stripe, Models.HERO, stripe_glow), _kind())
	_part(root, meshes[0], Models.material(), true)
	_body_mesh = root.get_child(0) as MeshInstance3D
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color("#fff3c4")
	lamp.roughness = 0.8
	lamp.emission_enabled = true
	lamp.emission = Color("#fff8dc")
	lamp.emission_energy_multiplier = 0.0
	_headlights.append(lamp)
	_part(root, meshes[1], lamp, false)
	var tail := StandardMaterial3D.new()
	tail.albedo_color = Color("#b3241f")
	tail.roughness = 0.8
	tail.emission_enabled = true
	tail.emission = Color("#ff2a1c")
	tail.emission_energy_multiplier = 0.0
	_tails.append(tail)
	_part(root, meshes[2], tail, false)
	return root


## The garage loop: a new paint job. The body's one mesh is made again once with the new vertex
## colours (the same shared material, so no new draw call or shader); the lamps stay.
func set_paint(body: Color, stripes: Color, body_glow := HERO_PAINT, stripes_glow := HERO_STRIPE) -> void:
	paint = body
	stripe = stripes
	paint_glow = body_glow
	stripe_glow = stripes_glow
	if _body_mesh != null:
		_body_mesh.mesh = Models.player_meshes(Models.fin(paint, Models.HERO, paint_glow),
				Models.fin(stripe, Models.HERO, stripe_glow), _kind())[0]


## G13b: two flames out of the tail, orange fading to a transparent blue-white tip, drawn like the
## beams (unshaded, see-through). The car's tail is +Z; the flames are 3 m long at scale 1.
func _make_flame() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := [Vector3(-0.24, 0.0, 0.0), Vector3(0.0, 0.22, 0.0), Vector3(0.24, 0.0, 0.0), Vector3(0.0, -0.22, 0.0)]
	for x in [-0.45, 0.45]:
		var base := Vector3(x, 0.42, 2.0)
		var tip := base + Vector3(0.0, 0.05, 3.0)
		for k in 4:
			st.set_color(Color(1.0, 0.62, 0.15, 0.95))
			st.add_vertex(base + ring[k])
			st.set_color(Color(1.0, 0.62, 0.15, 0.95))
			st.add_vertex(base + ring[(k + 1) % 4])
			st.set_color(Color(0.55, 0.8, 1.0, 0.0))
			st.add_vertex(tip)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.render_priority = 1
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	root.visible = false
	return root


## Light thrown on the road ahead while flashing: two pale fans, drawn after the
## post-process pass (see heli.gd) like every see-through surface.
func _make_beams() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-0.58, 0.58]:
		var tip := Vector3(x, 0.12, -2.1)
		st.set_color(Color(1, 0.97, 0.8, 0.75))
		st.add_vertex(tip)
		st.set_color(Color(1, 0.97, 0.8, 0.0))
		st.add_vertex(Vector3(x + 1.3, 0.12, -9.5))
		st.set_color(Color(1, 0.97, 0.8, 0.0))
		st.add_vertex(Vector3(x - 1.3, 0.12, -9.5))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.render_priority = 1
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	root.visible = false
	return root


## One part of the body: a mesh with its material (loop 2b: the body casts the sun's shadow,
## the lamps don't).
func _part(parent: Node3D, mesh: ArrayMesh, mat: Material, shadows: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
