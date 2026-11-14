extends RefCounted
## The city objects plan, step 6 (docs/design/drivable-city-build.md "Item 2. Collision answer v2"):
## the car's answer to a contact, as numbers. Pure and static: no node, no state. `car.gd` applies
## it (`_wall_answer`) and `traffic.gd` asks it how hard a hit car is shoved; nothing here knows the
## map, an object or a node.
##
## Four presets (`--collide=`, main.gd; the default stays V1 until F's phone A/B):
##   v1    today's answer, written down: the car keeps what slides along the wall (the projection),
##         less the scrape; a glancing nose turns along it at Car.WALL_TURN; the first frame pushes
##         back WALL_PUSH of the speed lost (at most 1.2 m/s); traffic keeps Car.CAR_KEEP of what
##         went into it. car.gd runs its own block for v1 (untouched); this table only describes it
##         (check_collide_rules.gd drives the real car and compares).
##   soft, mid, firm  the v2 answer: the speed is turned along the wall, keeping `keep_along` of it
##         (a graze, GRAZE_DEG, keeps 97 / 90 / 80 %; F: "97 % is too arcade, start from the middle"),
##         `bounce` of it off the wall, the nose turning toward the new way at `yaw_rate`; head-on
##         (over HEADON_DEG and HEADON_SPEED) the nose is kicked `kick_deg` toward the freer side once
##         per contact episode. Traffic keeps a share by how it was hit (`car_keep`).
## Classes (`solidity.gd`) reach `answer` so step 7 can add Smash; today every hard class answers
## the same, and anything not hard is not in the car's collider at all.

const V1 := &"v1"
const SOFT := &"soft"
const MID := &"mid"
const FIRM := &"firm"
## The presets in order, softest last but v1 first (the parse order of `--collide=`).
const PRESETS: Array[StringName] = [V1, SOFT, MID, FIRM]
## car.gd's Handling enum (CRUISE, SPORT, GROUNDED); check_collide_rules.gd holds them equal.
const CRUISE := 0
const SPORT := 1
const GROUNDED := 2

## v1: car.gd's own numbers (check_collide_rules.gd compares them with car.gd's consts).
const V1_SCRAPE := 1.2
const V1_SCRAPE_PRESS := 3.0
const V1_SCRAPE_MIN := 0.15
const V1_WALL_TURN := 3.0
const V1_WALL_PUSH := 0.12
const V1_PUSH_MOST := 1.2
const V1_CAR_KEEP := 0.5
const V1_GHOST_PUSH := 1.5

## v2: the speed kept along the wall by the angle going in (deg from the wall: 0 parallel, 90
## head-on), linear between the points; GRAZE_DEG is "a graze". Never rising with the angle.
const GRAZE_DEG := 10.0
const KEEP_AT: Array[float] = [0.0, GRAZE_DEG, 45.0, 75.0, 90.0]
const KEEP := {
	SOFT: [1.0, 0.97, 0.88, 0.72, 0.64],
	MID: [1.0, 0.90, 0.76, 0.58, 0.52],
	FIRM: [1.0, 0.80, 0.62, 0.46, 0.43],
}
## The share of the speed sent back off the wall, at a head-on hit (× sin of the angle), and the
## most it may be (m/s): a little push out of the wall so the next frame is not pressed into it.
const BOUNCE := {SOFT: 0.06, MID: 0.08, FIRM: 0.10}
const BOUNCE_MOST := 1.5
## The nose turns toward the new way at this rate (rad/s): 3.5 in Cruise, a little quicker in
## Sport, slower in Grounded (the body's inertia). The spec's 6 with a 35-50 deg kick swung the nose
## 55-75 deg in half a second, which Autopilot's tester read as a snap (Mac, 2026-11-14).
const YAW_RATE := {CRUISE: 3.5, SPORT: 4.0, GROUNDED: 3.0}
## Head-on: over HEADON_DEG from the wall and HEADON_SPEED m/s, a kick of KICK_MIN deg at
## HEADON_DEG rising to KICK_MAX straight on, once per contact episode.
const HEADON_DEG := 75.0
const HEADON_SPEED := 4.0
const KICK_MIN := 15.0
const KICK_MAX := 25.0
## While the contact lasts (the nose still turning off the wall) the car keeps at least the speed
## the hit gave it, less this scrape (1/s): v1's lightest scrape.
const SLIDE_SCRAPE := V1_SCRAPE * V1_SCRAPE_MIN
## The corner pivot: the contact's normal turning more than PIVOT_DEG within two frames at a front
## corner (within PIVOT_REACH m of it): keep PIVOT_KEEP and turn about the contact.
const PIVOT_DEG := 40.0
const PIVOT_REACH := 0.6
const PIVOT_KEEP := 0.8

## Traffic (a body that gives way): the share of the speed going into it that is kept, by how it
## was hit: a side swipe (the angle to its side under SWIPE_DEG), a rear-end (our way within
## INLINE_DEG of its axis) or a T-bone (across it, over CROSS_DEG); between them linear.
const SWIPE_DEG := 30.0
const INLINE_DEG := 30.0
const CROSS_DEG := 60.0
const KEEP_REAR := 0.75
const KEEP_SIDE := 0.85
const KEEP_TBONE := 0.4
## traffic.gd `_shove`: the share of the player's speed across the hit car's lane that slides it
## sideways: v1's 0.4 in line, up to SHOVE_TBONE square across (a T-boned car is knocked out of
## its lane).
const V1_SHOVE_SIDE := 0.4
const SHOVE_TBONE := 0.8
## G17's ghosting after this long held against traffic in Cruise (s; v1 and the other profiles keep
## V1_GHOST_PUSH).
const GHOST_PUSH_CRUISE := 0.8


## The preset named by `word` (`--collide=`), or V1 for anything else.
static func parse(word: String) -> StringName:
	var w := StringName(word.strip_edges().to_lower())
	return w if w in PRESETS else V1


## True for the v2 presets (car.gd and traffic.gd then use this table).
static func is_v2(preset: StringName) -> bool:
	return preset != V1 and preset in PRESETS


## The answer to a contact with something fixed: `speed` m/s going in, `angle_deg` from the wall
## (0 parallel, 90 head-on), `cls` the solid class (solidity.gd; every hard class the same today).
## {keep_along: share of the speed kept along the wall, bounce: share sent back off it, yaw_rate:
## rad/s the nose turns toward the new way, kick_deg: the head-on kick (0: none), scrape: 1/s while
## the contact lasts}. For V1 the numbers describe car.gd's own block on its first contact frame at
## 60 Hz (keep_along without the frame's scrape, which is `scrape`).
static func answer(preset: StringName, profile: int, speed: float, angle_deg: float, cls: StringName = &"") -> Dictionary:
	var a := clampf(angle_deg, 0.0, 90.0)
	var into := sin(deg_to_rad(a))
	if not is_v2(preset):
		# car.gd: slid = vel less what goes into the wall (cos), × exp(-scrape × dt); the first frame
		# pushes back lost × WALL_PUSH (lost = speed × sin), at most V1_PUSH_MOST.
		var push := minf(speed * into * V1_WALL_PUSH, V1_PUSH_MOST) if speed * into > 1.0 else 0.0
		return {"keep_along": cos(deg_to_rad(a)), "bounce": push / speed if speed > 0.001 else 0.0,
				"yaw_rate": V1_WALL_TURN if into > 0.05 and into < 0.9 else 0.0, "kick_deg": 0.0,
				"scrape": V1_SCRAPE * clampf(speed * into / V1_SCRAPE_PRESS, V1_SCRAPE_MIN, 1.0)}
	var keep := keep_along(preset, a, cls)
	var b := minf(float(BOUNCE[preset]) * into, BOUNCE_MOST / maxf(speed, 0.001))
	# Never more speed out than in.
	b = minf(b, sqrt(maxf(1.0 - keep * keep, 0.0)))
	var kick := 0.0
	if a > HEADON_DEG and speed > HEADON_SPEED:
		kick = lerpf(KICK_MIN, KICK_MAX, (a - HEADON_DEG) / (90.0 - HEADON_DEG))
	return {"keep_along": keep, "bounce": b, "yaw_rate": float(YAW_RATE.get(profile, YAW_RATE[CRUISE])),
			"kick_deg": kick, "scrape": SLIDE_SCRAPE}


## The share of the speed a v2 preset keeps along a wall met at `angle_deg` (linear in KEEP_AT).
## `_cls` is the hook for step 7 (Smash); every hard class answers the same today.
static func keep_along(preset: StringName, angle_deg: float, _cls: StringName = &"") -> float:
	if not is_v2(preset):
		return cos(deg_to_rad(clampf(angle_deg, 0.0, 90.0)))
	var pts: Array = KEEP[preset]
	var a := clampf(angle_deg, 0.0, 90.0)
	for i in range(1, KEEP_AT.size()):
		if a <= KEEP_AT[i]:
			return lerpf(float(pts[i - 1]), float(pts[i]), (a - KEEP_AT[i - 1]) / (KEEP_AT[i] - KEEP_AT[i - 1]))
	return float(pts[pts.size() - 1])


## Traffic: the share of the speed going into a car that gives way which is kept. `angle_deg` is
## the angle to its side (0 a swipe along it, 90 square into it), `cross_deg` the angle between our
## way and its axis (0 in line: a rear-end, 90 across: a T-bone).
static func car_keep(preset: StringName, angle_deg: float, cross_deg: float) -> float:
	if not is_v2(preset):
		return V1_CAR_KEEP
	var a := clampf(angle_deg, 0.0, 90.0)
	var c := clampf(cross_deg, 0.0, 90.0)
	# Hit square on: a rear-end in line, a T-bone across, linear between.
	var square := lerpf(KEEP_REAR, KEEP_TBONE, clampf((c - INLINE_DEG) / (CROSS_DEG - INLINE_DEG), 0.0, 1.0))
	# A shallow angle to its side is a swipe whatever the axis.
	return lerpf(KEEP_SIDE, square, clampf(a / SWIPE_DEG, 0.0, 1.0))


## traffic.gd `_shove`: the share of the player's speed across the hit car's lane that slides it,
## by `cross_deg` (the player's way against the car's axis: 0 in line, 90 a T-bone).
static func shove_side(preset: StringName, cross_deg: float) -> float:
	if not is_v2(preset):
		return V1_SHOVE_SIDE
	return lerpf(V1_SHOVE_SIDE, SHOVE_TBONE, clampf((cross_deg - INLINE_DEG) / (90.0 - INLINE_DEG), 0.0, 1.0))


## G17: how long the car is held against traffic before it ghosts through (s).
static func ghost_push_time(preset: StringName, profile: int) -> float:
	return GHOST_PUSH_CRUISE if is_v2(preset) and profile == CRUISE else V1_GHOST_PUSH


## The angle (deg, 0..90) between a way `dir` and an axis `axis` (either way along it), on the ground.
static func cross_angle(dir: Vector3, axis: Vector3) -> float:
	var d := Vector2(dir.x, dir.z)
	var x := Vector2(axis.x, axis.z)
	if d.length() < 0.001 or x.length() < 0.001:
		return 0.0
	return rad_to_deg(acos(clampf(absf(d.normalized().dot(x.normalized())), 0.0, 1.0)))
