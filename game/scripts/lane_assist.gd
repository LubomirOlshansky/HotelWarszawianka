extends RefCounted
## Beta values (2026-11-04), GAMEPLAY_PLAN 1.5 item 1: the lane assist, "Asysta pasa". With the
## steering near the middle the car eases towards the direction of the lane it drives in, so a long
## avenue or a gentle curve (Wisłostrada, Trasa Łazienkowska, the bridges) holds without constant
## small thumb movements on the strip. It never fights a deliberate turn: its pull fades to nothing
## as the steering moves past NEAR_CENTRE, and it lets go past MAX_ERR off the lane (a turn into
## another street, a lane change at a big angle).
##
## Classic only (the strip and the pedals; Point already aims where the finger points), behind
## Settings → Jazda → Asysta pasa (settings.gd `lane_assist`, on by default since 2026-11-13).
## main.gd finds the lane's direction (`lane_heading`, 10 times a second) and car.gd adds the pull
## (`yaw_pull`) to the steering. tools/check_lane_assist.gd measures it.

const LaneGraph := preload("res://scripts/lane_graph.gd")

## The pull (1/s): the yaw rate asked for per radian of heading error (GAMEPLAY_PLAN's k ≈ 1.5).
const GAIN := 1.5
## Only below this heading error to the lane (rad): past it the player is turning off.
const MAX_ERR := deg_to_rad(20.0)
## The steering share under which the assist works, fading to 0 at this share.
const NEAR_CENTRE := 0.15
## On from this speed (m/s, ~15 km/h), fully on from FULL_SPEED (~22 km/h).
const MIN_SPEED := 4.2
const FULL_SPEED := 6.0
## The lane must be this close to the car (m): on the carriageway, not on a parallel street.
const REACH := 3.5
## How far apart the car's heading and the lane's may be to count as "driving in it" (rad).
const ALIGN := deg_to_rad(35.0)
## The aim is a point on the lane this many seconds ahead (pure pursuit), between AHEAD_MIN and
## AHEAD_MAX m: it holds the car to the lane's middle and round a curve. A pull to the lane's own
## direction alone left a steady error on a curve (1.8° at 50 km/h on 300 m: 4.3 m wide in 10 s).
const AHEAD_TIME := 0.9
const AHEAD_MIN := 8.0
const AHEAD_MAX := 30.0


## The yaw rate (rad/s, + turns left like car.gd's yaw) the assist adds: `err` the signed angle from
## the car's heading to the lane's (rad), `steer` the player's steering (-1..1), `speed` (m/s).
static func yaw_pull(err: float, steer: float, speed: float) -> float:
	if absf(err) > MAX_ERR or speed < MIN_SPEED:
		return 0.0
	var w := clampf(1.0 - absf(steer) / NEAR_CENTRE, 0.0, 1.0)
	var fade := clampf((speed - MIN_SPEED) / (FULL_SPEED - MIN_SPEED), 0.0, 1.0)
	return GAIN * err * w * fade


## The way (map x, z; unit) to steer for to keep to the lane the car at `at` heading `fwd` (unit)
## at `speed` m/s drives in: towards the lane's middle ahead(); or Vector2.ZERO: no lane within
## REACH whose direction is within ALIGN of the car's (a plaza, a junction box, crossing the road,
## going the wrong way down a one-way street).
static func lane_heading(graph: LaneGraph, at: Vector2, fwd: Vector2, speed := 14.0) -> Vector2:
	if graph == null:
		return Vector2.ZERO
	var hit := graph.snap(at, REACH, fwd)
	if hit.is_empty():
		return Vector2.ZERO
	var e: int = hit[0]
	var s: float = hit[2]
	var dir := graph.direction(e, s)
	if dir.length() < 0.5 or absf(fwd.angle_to(dir)) > ALIGN:
		return Vector2.ZERO
	var reach := ahead(speed)
	var aim := graph.point_at(e, minf(s + reach, graph.e_s1[e]), graph.lane_offset(e, int(hit[1])))
	return pursuit(at, aim, dir)


## How far ahead the aim is at `speed` m/s.
static func ahead(speed: float) -> float:
	return clampf(speed * AHEAD_TIME, AHEAD_MIN, AHEAD_MAX)


## The way from `at` to `aim`, or the lane's own direction `dir` when the aim is too close (the
## lane's end right ahead, at a junction) or behind.
static func pursuit(at: Vector2, aim: Vector2, dir: Vector2) -> Vector2:
	var to := aim - at
	if to.length() < AHEAD_MIN * 0.5 or to.dot(dir) <= 0.0:
		return dir.normalized()
	return to.normalized()
