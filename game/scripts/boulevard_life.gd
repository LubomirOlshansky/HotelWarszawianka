extends RefCounted
## Schodki nad Wisłą, Phase B (F, 2026-11-19): the life round the Vistula steps by Kopernik. Pure
## rules and closed-form poses, no node and no state: city_life.gd asks for the poses at each step
## and writes them into the pedestrians' guest slots (people), the dog MultiMesh (the police dog)
## and the scooters' MultiMesh (scooters and rollerbladers), so the draw calls are +0 for people
## and dog and +1 for the scooters' small mesh (the bike family's shape slots are all used).
##
## The frame is the steps' own (the same C, A and N as the Phase A plan): `u` along the river,
## `v` towards the water (the steps' band is u -95 .. +104, v -6 top .. +9 foot). A pose is a pure
## function of the clock `t`, so nothing drifts, a check can walk it, and an off-screen figure
## costs nothing. Not Beehave: one fixed loop per figure (beehave-trees: fewer than four
## behaviours, and a loop is not a choice).
##
## What there is:
##  - the patrol (upper promenade, v -10): two Policja officers, one with a dog, 18:00-02:00 (a
##    second pair on Friday and Saturday); by day (10:00-18:00) a Straż Miejska pair instead (dark
##    uniform, lime hi-vis shirt). 1.1-1.3 m/s end to end and back; at the top of the steps they
##    stop 5-10 s and look down at the crowd.
##  - the riders: scooters and rollerbladers along the upper promenade, 6:00-22:00.
##  - the walkers: couples, a jogger and a few singles on the upper and lower promenade in the
##    evening; a family by day.

## The steps' frame (Phase A plan): the centre, `A` along the river, `N` towards the water.
const C := Vector2(445.0, -862.0)
const A := Vector2(0.665, 0.747)
const N := Vector2(0.747, -0.665)
## The view this near C (m) brings the life up (the steps' band is 200 m long).
const NEAR_R := 170.0

## The paved upper promenade's middle line, (u, v) points read off centrum.json's footway ribbons and
## the plaza (the strip runs slanted to the steps' frame: v -15.8 at the west end, -5.3 by the steps'
## top, then onto the plaza at u 80), kept >= 1.5 m off the lamps, benches, bins and trunks there. The
## patrol, the walkers and the riders all follow it (a lane is an offset in v from it).
const ROUTE: Array[Vector2] = [Vector2(-135.0, -17.0), Vector2(-110.0, -15.8), Vector2(-80.0, -13.8), Vector2(-50.0, -12.0),
		Vector2(-30.0, -10.6), Vector2(-10.0, -8.6), Vector2(10.0, -7.8), Vector2(20.0, -6.6), Vector2(30.0, -5.3),
		Vector2(60.0, -5.5), Vector2(72.0, -5.6), Vector2(80.0, -5.4), Vector2(88.0, -12.6), Vector2(140.0, -12.6)]
## The lower quay's path (the footway at v 7-12 by the water, u -5 .. 89).
const LOWER: Array[Vector2] = [Vector2(-5.0, 7.0), Vector2(3.0, 8.0), Vector2(17.0, 9.0), Vector2(35.0, 10.0), Vector2(47.0, 10.0),
		Vector2(60.0, 11.0), Vector2(75.0, 12.0), Vector2(89.0, 12.0)]
## The patrol: from PATROL_U.x to .y along the river at PATROL_V, PATROL_SPEED m/s, with the pauses at
## the tops of the steps: [u, seconds].
const PATROL_U := Vector2(-110.0, 120.0)
const PATROL_SPEED := 1.2
const PATROL_STOPS: Array[Vector2] = [Vector2(-62.0, 7.0), Vector2(-8.0, 24.0), Vector2(52.0, 6.0), Vector2(96.0, 8.0)]
## The mandat (F, 2026-11-19): at the stop whose pause is FINE_PAUSE s the first Policja officer
## walks FINE_WALK m down towards the seated group (towards the water, to the steps' top edge), stands
## writing a ticket for FINE_WRITE s, and walks back; the stop comes round twice a cycle (about
## every 3.7 min). Only Policja fines, and only the first pair.
const FINE_PAUSE := 24.0
const FINE_WALK := 4.5
const FINE_WRITE := 10.0
## Policja 18:00-02:00 (wraps midnight), Straż Miejska by day; a second Policja pair on these
## weekdays (1 Monday .. 7 Sunday: Friday, Saturday and the small hours after them).
const NIGHT_HOURS := [18.0, 26.0]
const DAY_HOURS := [10.0, 18.0]
const BUSY_DAYS := [5, 6]
## The uniforms: Policja navy, Straż Miejska a dark uniform under a lime hi-vis shirt; the trousers'
## palette index (actor.gdshader TROUSERS: 0 navy, 1 black).
const POLICE_SHIRT := Color("#243a73")
const GUARD_SHIRT := Color("#c8e04a")
const POLICE_TR := 0.1
const GUARD_TR := 0.35
## The officer's dog: a long-bodied dog on a lead beside the second officer, a police-dog brown.
const DOG_COAT := Color("#5b4636")
const DOG_SCALE := 1.6

## The riders (scooter 0, rollerblader 1): [kind, lane (m off the route), speed m/s, phase 0..1, shirt].
## They ride the promenade between RIDE_U.x and .y, there and back (the ends lie off the steps' view);
## RIDE_HOURS is the cyclists' day.
const RIDE_U := Vector2(-118.0, 125.0)
const RIDE_HOURS := [6.0, 22.0]
const RIDERS := [
	[0, -0.8, 5.6, 0.05, "#2f6fb5"], [0, 0.6, 4.8, 0.33, "#d8432f"], [0, -1.0, 6.2, 0.61, "#3b8f5a"],
	[0, 0.9, 5.2, 0.84, "#e0b23a"], [1, -0.3, 3.6, 0.2, "#7a4fa8"], [1, 0.4, 3.2, 0.7, "#e57aa0"],
]

## The walkers: [kind, hours key, lane (m off the route; the lower quay's path when `lower`), u0, u1,
## speed, phase, shirt, shirt2, lower]. Kind: "couple", "single", "jogger" and "family" (two adults and
## a child). Hours: "eve" 18:00-24:00, "day" 10:00-18:00, "all" 6:00-24:00. A figure walks u0 to u1
## and back.
const EVE_HOURS := [18.0, 24.0]
const WALK_DAY := [10.0, 18.0]
const WALK_ALL := [6.0, 24.0]
const WALKERS := [
	["couple", "eve", 0.5, -105.0, 118.0, 1.0, 0.1, "#e57aa0", "#2b2c2f", false],
	["couple", "eve", -0.4, -95.0, 110.0, 0.9, 0.45, "#5aa9c9", "#9c2f3a", false],
	["couple", "eve", 0.0, -2.0, 88.0, 0.85, 0.3, "#f2efe8", "#3b8f5a", true],
	["couple", "eve", 0.6, -100.0, 118.0, 1.05, 0.72, "#7a4fa8", "#e0b23a", false],
	["single", "eve", 0.1, -100.0, 118.0, 1.3, 0.55, "#d8432f", "", false],
	["single", "eve", 0.3, -2.0, 88.0, 1.1, 0.9, "#2f6fb5", "", true],
	["jogger", "eve", -0.2, -2.0, 88.0, 2.9, 0.0, "#fff3a6", "", true],
	["family", "day", 0.0, -100.0, 118.0, 0.8, 0.25, "#3b8f5a", "#e0b23a", false],
	["couple", "day", 0.4, -100.0, 118.0, 0.95, 0.6, "#2f6fb5", "#d8432f", false],
	["couple", "day", 0.0, -2.0, 88.0, 0.9, 0.15, "#e0b23a", "#7a4fa8", true],
	["jogger", "all", -0.4, -100.0, 118.0, 2.7, 0.4, "#b8f0d8", "", false],
]
## Who queues at the food (bulwar_food.gd, on the plaza at the promenade's east end): [hours key, u, v,
## shirt, trousers]; they stand still facing the hatches (towards -N). Two at the ice-cream cart by day
## and in the evening, three more at the truck then.
const STANDERS := [
	["day", 103.2, -17.4, "#2f6fb5", 0.35], ["day", 104.7, -17.4, "#e57aa0", 0.1],
	["eve", 103.2, -17.4, "#d8432f", 0.1], ["eve", 104.7, -17.4, "#f2efe8", 0.35],
	["eve", 90.8, -16.6, "#3b8f5a", 0.1], ["eve", 92.2, -16.6, "#7a4fa8", 0.35], ["eve", 93.6, -16.6, "#e0b23a", 0.1],
]
## Added to the trousers' value, a figure stands still (actor.gdshader: no leg swing from 2.0 up).
const STILL := 2.0
## A child walks at this scale and the pair's side offsets are in m.
const CHILD_SCALE := 0.62
const PAIR_GAP := 0.42

## Bubble: the patrol's line, once per LINE_GAP s, when a view within LINE_R m of an officer.
const LINE_GAP := 45.0
const LINE_R := 38.0


# --- the rules --------------------------------------------------------------------------------

## Inside the [from, to) window (hours; `to` may be past 24: the small hours after midnight)?
static func in_window(w: Array, hour: float) -> bool:
	var h := hour
	if float(w[1]) > 24.0 and h < float(w[1]) - 24.0:
		h += 24.0
	return h >= float(w[0]) and h < float(w[1])


## Who patrols at `hour` on `weekday`: "policja" (18:00-02:00), "straz" (10:00-18:00) or "".
static func patrol_kind(hour: float) -> String:
	if in_window(NIGHT_HOURS, hour):
		return "policja"
	if in_window(DAY_HOURS, hour):
		return "straz"
	return ""


## How many patrol pairs: two on a Friday or Saturday evening (and the small hours after), else one.
## Straż Miejska is always one pair.
static func patrol_pairs(hour: float, weekday: int) -> int:
	if patrol_kind(hour) != "policja":
		return 1 if patrol_kind(hour) == "straz" else 0
	# The small hours belong to the evening before.
	var day := weekday if hour >= 6.0 else ((weekday + 5) % 7) + 1
	return 2 if day in BUSY_DAYS else 1


## Is any of the street life up at `hour` (the view this near gets the bit)?
static func active(hour: float) -> bool:
	return hour >= 6.0 or hour < 2.0


## The frame's v of a polyline (ROUTE or LOWER) at `u` (flat beyond its ends).
static func line_v(line: Array[Vector2], u: float) -> float:
	if u <= line[0].x:
		return line[0].y
	for i in range(1, line.size()):
		if u <= line[i].x:
			return lerpf(line[i - 1].y, line[i].y, (u - line[i - 1].x) / (line[i].x - line[i - 1].x))
	return line[line.size() - 1].y


## The map position at `u` on the upper promenade's middle line, `off` m towards the water.
static func on_route(u: float, off := 0.0) -> Vector2:
	return at(u, line_v(ROUTE, u) + off)


## The way a figure walking along `line` at `u` faces, going towards +u (`dir` 1) or -u (-1).
static func line_dir(line: Array[Vector2], u: float, dir: float) -> Vector2:
	var a := at(u, line_v(line, u))
	var b := at(u + dir, line_v(line, u + dir))
	return (b - a).normalized()


## Map position of the frame's (u, v).
static func at(u: float, v: float) -> Vector2:
	return C + A * u + N * v


static func yaw_of(dir: Vector2) -> float:
	return atan2(-dir.x, -dir.y)


# --- the patrol -------------------------------------------------------------------------------

## The stops of one leg as distances from the leg's start: the out leg's (low u first), or the
## return leg's (mirrored), ascending.
static func _leg_stops(back: bool) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var length := PATROL_U.y - PATROL_U.x
	for s in PATROL_STOPS:
		var d := s.x - PATROL_U.x
		out.append(Vector2(length - d if back else d, s.y))
	if back:
		out.reverse()
	return out


## The time of one leg: the walk and the pauses.
static func leg_time() -> float:
	var total := (PATROL_U.y - PATROL_U.x) / PATROL_SPEED
	for s in PATROL_STOPS:
		total += s.y
	return total


## The patrol's whole there-and-back cycle (s).
static func cycle_time() -> float:
	return 2.0 * leg_time()


## Where along its leg (m from its start) the patrol is `x` s into the leg, and whether it is paused.
static func _walk_leg(x: float, back: bool) -> Array:
	var pos := 0.0
	var rest := x
	for s in _leg_stops(back):
		var to_stop := (s.x - pos) / PATROL_SPEED
		if rest < to_stop:
			return [pos + rest * PATROL_SPEED, false, 0.0, 0.0]
		rest -= to_stop
		pos = s.x
		if rest < s.y:
			return [pos, true, rest, s.y]
		rest -= s.y
	return [minf(pos + rest * PATROL_SPEED, PATROL_U.y - PATROL_U.x), false, 0.0, 0.0]


## The patrol pair's pose at clock `t` (s), offset by `phase` (0..1 of the cycle): {"u": along the
## river, "dir": 1 (towards +u) or -1, "paused": looking down at the steps, "face": the facing
## (a map direction)}.
static func patrol_pose(t: float, phase: float) -> Dictionary:
	var cycle := cycle_time()
	var x := fposmod(t + phase * cycle, cycle)
	var lt := leg_time()
	var back := x >= lt
	var r := _walk_leg(x - lt if back else x, back)
	var d: float = r[0]
	var u := PATROL_U.y - d if back else PATROL_U.x + d
	var dir := -1.0 if back else 1.0
	var paused: bool = r[1]
	# The fine stop: `fine_t` seconds into it (-1 elsewhere) and which passing it is (for one line each).
	var fine_t := -1.0
	if paused and is_equal_approx(float(r[3]), FINE_PAUSE):
		fine_t = r[2]
	var passing := int(floor((t + phase * cycle) / cycle)) * 2 + (1 if back else 0)
	return {"u": u, "dir": dir, "paused": paused, "face": N if paused else A * dir, "fine_t": fine_t, "passing": passing}


## How far (m towards the water) the fining officer is `fine_t` s into the fine stop, and whether he is
## writing (standing at the group): out FINE_WALK m at the patrol's pace, FINE_WRITE s, and back.
static func fine_offset(fine_t: float) -> float:
	if fine_t < 0.0:
		return 0.0
	var walk := FINE_WALK / PATROL_SPEED
	if fine_t < walk:
		return fine_t * PATROL_SPEED
	if fine_t < walk + FINE_WRITE:
		return FINE_WALK
	return maxf(0.0, FINE_WALK - (fine_t - walk - FINE_WRITE) * PATROL_SPEED)


## Is the officer walking (out or back) at `fine_t`?
static func fine_moving(fine_t: float) -> bool:
	var walk := FINE_WALK / PATROL_SPEED
	return fine_t >= 0.0 and (fine_t < walk or (fine_t >= walk + FINE_WRITE and fine_t < 2.0 * walk + FINE_WRITE))


## Is the officer writing the ticket at `fine_t` (a line is due)?
static func fine_writing(fine_t: float) -> bool:
	var walk := FINE_WALK / PATROL_SPEED
	return fine_t >= walk and fine_t < walk + FINE_WRITE


## The patrol's figures at clock `t`: one entry per figure, [position (map x, z), yaw, shirt, trousers,
## scale], and the dog as the last entry of the list in "dog": [position, yaw]. `pairs` the pairs on
## duty, `kind` "policja" or "straz".
static func patrol_figures(t: float, kind: String, pairs: int) -> Dictionary:
	var figs: Array = []
	var dog := []
	var shirt := POLICE_SHIRT if kind == "policja" else GUARD_SHIRT
	var tr := POLICE_TR if kind == "policja" else GUARD_TR
	for p in pairs:
		var pose := patrol_pose(t, 0.0 if p == 0 else 0.5)
		var u: float = pose["u"]
		var dir: float = pose["dir"]
		var face: Vector2 = N if bool(pose["paused"]) else line_dir(ROUTE, u, dir)
		var side := Vector2(-face.y, face.x)
		var centre := on_route(u, -1.2 * p)
		var yaw := yaw_of(face)
		var out := Vector2.ZERO
		var ft: float = pose["fine_t"]
		var fining := p == 0 and kind == "policja" and ft >= 0.0
		if fining:
			out = N * fine_offset(ft)
		# Still (no leg swing) while paused, but the fining officer's walk out and back swings.
		var still := STILL if bool(pose["paused"]) else 0.0
		var still1 := 0.0 if fining and fine_moving(ft) else still
		figs.append([centre + side * PAIR_GAP + out, yaw, shirt, tr + still1, Vector3.ONE])
		figs.append([centre - side * PAIR_GAP, yaw, shirt, tr + still, Vector3.ONE])
		if p == 0 and kind == "policja":
			# The dog on its lead, ahead and a little out from the second officer (it trots ahead
			# along the way, or sits at his boot when he stands).
			var ahead := A * dir * (0.0 if bool(pose["paused"]) else 1.3)
			dog = [centre - side * (PAIR_GAP + 0.8) + ahead, yaw]
	return {"figs": figs, "dog": dog}


## The nearest officer's position to `p` among `figs` (the patrol figures): INF when none.
static func nearest(figs: Array, p: Vector2) -> Vector2:
	var best := Vector2.INF
	var bd := INF
	for f: Array in figs:
		var q: Vector2 = f[0]
		var d := q.distance_squared_to(p)
		if d < bd:
			bd = d
			best = q
	return best


# --- the walkers ------------------------------------------------------------------------------

## A back-and-forth triangle wave: 0 at x = 0, 1 at x = 0.5, 0 at 1 (the walk's fraction of its lane).
static func tri(x: float) -> float:
	var f := fposmod(x, 1.0)
	return f * 2.0 if f < 0.5 else 2.0 - f * 2.0


## A walker's hours window by its key.
static func walker_hours(key: String) -> Array:
	return EVE_HOURS if key == "eve" else (WALK_DAY if key == "day" else WALK_ALL)


## The walkers' figures (and the queues') at clock `t` and `hour`: [position (map x, z), yaw, shirt, trousers, scale].
static func walker_figures(t: float, hour: float) -> Array:
	var out: Array = []
	for i in WALKERS.size():
		var w: Array = WALKERS[i]
		if not in_window(walker_hours(str(w[1])), hour):
			continue
		var length := float(w[4]) - float(w[3])
		var f := float(w[6]) + t * float(w[5]) / (2.0 * length)
		var u := float(w[3]) + tri(f) * length
		var dir := 1.0 if fposmod(f, 1.0) < 0.5 else -1.0
		var line: Array[Vector2] = LOWER if bool(w[9]) else ROUTE
		var face := line_dir(line, u, dir)
		var side := Vector2(-face.y, face.x)
		var centre := at(u, line_v(line, u) + float(w[2]))
		var yaw := yaw_of(face)
		var c1 := Color(str(w[7]))
		var c2 := Color(str(w[8])) if str(w[8]) != "" else c1
		match str(w[0]):
			"couple":
				out.append([centre + side * PAIR_GAP, yaw, c1, 0.1 + 0.25 * (i % 3), Vector3.ONE])
				out.append([centre - side * PAIR_GAP, yaw, c2, 0.1 + 0.25 * ((i + 1) % 3), Vector3.ONE])
			"family":
				out.append([centre + side * 0.55, yaw, c1, 0.35, Vector3.ONE])
				out.append([centre - side * 0.55, yaw, c2, 0.1, Vector3.ONE])
				out.append([centre + side * 0.0 + face * 0.3, yaw, Color("#e57aa0"), 0.1, Vector3.ONE * CHILD_SCALE])
			_:
				out.append([centre, yaw, c1, 0.35, Vector3.ONE])
	for q: Array in STANDERS:
		if in_window(walker_hours(str(q[0])), hour):
			out.append([at(float(q[1]), float(q[2])), yaw_of(-N), Color(str(q[3])), float(q[4]) + STILL, Vector3.ONE])
	return out


# --- the riders -------------------------------------------------------------------------------

## The riders' instances at clock `t` and `hour`: [position (map x, z), yaw, kind, shirt].
static func rider_figures(t: float, hour: float) -> Array:
	var out: Array = []
	if not in_window(RIDE_HOURS, hour):
		return out
	var length := RIDE_U.y - RIDE_U.x
	for r: Array in RIDERS:
		var f := float(r[3]) + t * float(r[2]) / (2.0 * length)
		var u := RIDE_U.x + tri(f) * length
		var dir := 1.0 if fposmod(f, 1.0) < 0.5 else -1.0
		out.append([on_route(u, float(r[1])), yaw_of(line_dir(ROUTE, u, dir)), int(r[0]), Color(str(r[4]))])
	return out
