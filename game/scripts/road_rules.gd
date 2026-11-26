extends RefCounted
## Road life's rules (road_life.gd; F 2026-11-23, docs/design/road-life.md): what the ambulance on
## a call does to respect, and when a driver behind honks at a green. Pure and static, so
## game/tools/check_road_life.gd tests every case without a scene.
##
## F chose (2026-11-23, the plan's card "−10, але чесно"): hitting the ambulance costs HIT_LOSS
## respect, but only when the player is at fault (`at_fault`: their own car went into it, not the
## ambulance into a car standing or driving ahead), never below the respect of the ladder rung the
## player has already reached (`respect_floor`: an open race stays open), and never a police chase
## (police.gd leaves the "ambulance" role's bumps alone). Driving on in its way for BLOCK_TIME s
## while the road has room to pull aside costs BLOCK_LOSS; letting it through (it passes) gives
## THANKS_GAIN, once per ambulance.

const Ladder := preload("res://scripts/ladder.gd")

const HIT_LOSS := 10
const BLOCK_LOSS := 3
const THANKS_GAIN := 3
## A bump counts from this much speed lost (m/s; police.gd BUMP, car.gd's own floor).
const BUMP := 2.0
## The player's car is "in the ambulance's way": ahead of it by 0..WAY_AHEAD m, within WAY_SIDE m
## of its line (its lane), going its way (headings within WAY_COS).
const WAY_AHEAD := 40.0
const WAY_SIDE := 1.7
const WAY_COS := 0.6
## Blocking: in its way this long (s), moving at least BLOCK_MOVING m/s (a car standing at a red or
## in a queue has nowhere to go), on a road with 2+ lanes its way (room to pull aside).
const BLOCK_TIME := 4.0
const BLOCK_MOVING := 4.2
## Passed: the ambulance's front is this far past the player's car (m).
const PASSED := 3.0
## The honk at a green: the player's car stands (under STILL m/s) within GREEN_NEAR m of the stop
## line, the light has been green GREEN_WAIT s, a car stands behind within BEHIND_NEAR m.
const STILL := 0.5
const GREEN_NEAR := 14.0
const GREEN_WAIT := 2.5
const BEHIND_NEAR := 12.0


## The lowest respect a loss may leave: the threshold of the highest ladder rung (the final
## included) that `respect` reaches now, 0 below the first.
static func respect_floor(respect: int) -> int:
	var low := 0
	for i in Ladder.RUNGS.size():
		var t := Ladder.threshold(i)
		if t <= respect:
			low = maxi(low, t)
	if Ladder.FINAL_RESPECT <= respect:
		low = maxi(low, Ladder.FINAL_RESPECT)
	return low


## What a loss of `loss` takes from `respect` (never below the floor, never negative).
static func loss_from(respect: int, loss: int) -> int:
	return clampi(respect - respect_floor(respect), 0, maxi(loss, 0))


## Where the player's car is from the ambulance (at `amb`, heading `amb_fwd`, a unit vector on the
## ground): [metres ahead along its heading, metres to the side of its line].
static func relative(amb: Vector2, amb_fwd: Vector2, player: Vector2) -> Vector2:
	var rel := player - amb
	return Vector2(rel.dot(amb_fwd), absf(rel.cross(amb_fwd)))


## The player's car (its heading `player_fwd`) is in the ambulance's way.
static func in_way(rel: Vector2, amb_fwd: Vector2, player_fwd: Vector2) -> bool:
	return rel.x > 0.0 and rel.x < WAY_AHEAD and rel.y < WAY_SIDE and amb_fwd.dot(player_fwd) > WAY_COS


## A bump into the ambulance is the player's fault: they lost at least BUMP m/s on it while
## moving (`player_v`, m/s along their heading), and it was not the ambulance coming up behind
## them faster than they went (`rel`: the player's car from the ambulance, `relative`; `amb_v` its
## speed).
static func at_fault(lost: float, player_v: float, rel: Vector2, amb_v: float) -> bool:
	if lost < BUMP or absf(player_v) < 1.0:
		return false
	if rel.x > 0.0 and rel.y < WAY_SIDE and amb_v > player_v:
		return false  # it ran into the back of the player's car
	return true


## The player gave way as it passed: they moved out of the lane they were in when it came up
## behind (`lane_then`, `lane_now`: the lane graph's lane index; -1 off the road), or let it by
## slowly (under GAVE_WAY_V m/s). An ambulance that only went round a car driving on gets no thanks.
const GAVE_WAY_V := 4.0


static func gave_way(lane_then: int, lane_now: int, player_v: float) -> bool:
	return lane_now != lane_then or absf(player_v) < GAVE_WAY_V


## Blocking for long enough to count (`way_t`: seconds in its way so far).
static func blocking(way_t: float, player_v: float, lanes_its_way: int) -> bool:
	return way_t >= BLOCK_TIME and player_v >= BLOCK_MOVING and lanes_its_way >= 2


## A driver behind honks: the player's car has stood `still_t` s and the light ahead has been green
## `green_t` s, within GREEN_NEAR m of the line, with a car standing behind within BEHIND_NEAR m.
static func honk_at_green(green_t: float, to_line: float, behind: float) -> bool:
	return green_t >= GREEN_WAIT and to_line >= 0.0 and to_line <= GREEN_NEAR and behind <= BEHIND_NEAR
