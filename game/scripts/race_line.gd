extends RefCounted
## The racing line (the racer AI rebuild, step 4a, 2026-11-12; docs/design/race-ai.md): the way a
## racer drives a run of streets, as points on the ground with the metres driven and the lane
## graph's own metres at each.
##
## The town's cars keep to the lane's line and the junction's curve (lane_graph.gd): a lane that
## steps sideways across a junction, a kink of the street's line and a tight curve are all driven as
## they are, at any speed. A racer's line stays in its lane (what is left of it beside a car,
## `free_side`) and inside the junction, and makes the best of that room:
##   - a sideways step between two lanes straight on is spread over both streets (each lane's line
##     moved towards the other at the mouth, down a ramp no steeper than RAMP_STEEP);
##   - every bend left is rounded by the widest arc that stays in the room of each point it passes
##     (`_bend`), and bends of one hand close together (the two halves of a turn, the pieces a big
##     junction is cut into, a street's bend drawn as short pieces) become one arc where that is
##     wider (`_join`);
##   - a U-turn, a hairpin and a shortcut are driven as the lane graph (or the cut) has them.
## The line is built a stretch at a time: from the middle of one long street (`split`) through the
## junction, or the run of short pieces a big junction is cut into, to the middle of the next. A
## stretch depends on nothing outside it, so it is built once and kept (`stretch`), and a racer's
## way is stretches end to end (`path`): building the way further ahead never moves the line under
## the car.
##
## A place on the line is known by its logical metres (x): the lane graph's own, a street's
## stations and a junction curve's length. So the traffic's rail (traffic.gd: `s`, `cu`, lanes,
## gaps, lights) stays as it is, and only the place on the ground is read from the line.
##
## The speed for every metre (`speeds`): no RUN metres of the line ask for more sideways pull than
## the racer's grip (the turn within WINDOW metres, the race bench's own measure of an honest car),
## and the racer brakes for each such place in time, at its own braking.

const LaneGraph := preload("res://scripts/lane_graph.gd")

## A car's width (m) and the gap it keeps to its lane's edge: what is left of the lane each side
## is free for the line, SIDE_MAX at most.
const CAR_W := 1.8
const SIDE_GAP := 0.15
const SIDE_MAX := 1.0
## A street with this many usable metres or more is cut in two at its `split`; a shorter one lies
## whole inside a stretch.
const LONG := 14.0
## A piece shorter than this between two junctions is part of the junction: the junction's room.
const INSIDE := 6.0
## Inside a junction the line may pass this much further in than the lane graph's curve (on top of
## the lanes' free side), and no further out than this: where no lane of the junction's streets
## lies on that side. Where one does, no further out than the lanes' free side.
const JUNCTION_IN := 0.3
const JUNCTION_OUT := 2.0
## A junction turning less than this (rad) is straight on: its two lanes' lines are joined by a
## chord, and moved sideways at the mouths where they do not line up.
const STRAIGHT_ON := 0.2
## A sideways move of the lane's line: its ramp is this steep (m a metre) where the street is long
## enough, never steeper than RAMP_STEEP, RAMP_LEAST m long at least, and it ends RAMP_KEEP m
## short of the stretch's end.
const RAMP_SLOPE := 0.05
const RAMP_STEEP := 0.08
const RAMP_LEAST := 4.0
const RAMP_KEEP := 2.0
## Up to this turn (rad) a racer continues in the lane ahead of its own (`lane_on`; past it the
## lane graph's rule for a turn, lane_graph.gd next_lane).
const LANE_TURN := 0.6
## A step smaller than this (m) is left as it is; a lane's line is moved by this share of its
## free side at most (the rest is room for the arc where the ramp meets the junction).
const STEP_LEAST := 0.1
const MOVE_SHARE := 0.75
## A point of the lane's line nearer than this (m) to the straight between its neighbours is left out.
const FLAT := 0.12
## An arc is no wider than this (m); one tighter than RADIUS_LEAST is left a corner.
const RADIUS_MOST := 400.0
const RADIUS_LEAST := 0.25
## Bends are joined into one arc up to this turn (rad). The one arc is held to the lane's line
## every BULGE_STEP m of the way between the bends it takes the place of.
const JOIN_TURN := 2.2
const BULGE_STEP := 2.0
## A junction whose way through the short pieces inside it strays less than this (m) from the
## straight between its mouths is a chord too.
const CHORD_STRAY := 0.5
## A junction whose way swings this much (rad) past the headings it comes in and goes out at, or
## winds round the other way (a loop, a pirouette between two carriageways), is driven as the lane
## graph has it.
const LOOP := 0.8
## So is one whose arc comes out tighter than this share of the radius the town's cars drive it at.
const POOR := 0.8
## A lane's line that crosses itself within this many metres is a fold (`_unfold`).
const UNFOLD := 12.0
## Two ways through a junction are compared by the seconds a car of this grip (m/s²) and this top
## speed (m/s) takes at the caps alone.
const COST_GRIP := 8.0
const COST_TOP := 25.0
## The racer's corners, kept here for traffic.gd too (its RACE_HAIRPIN, UTURN_SPEED,
## RACE_TURN_RADIUS, CUT_TOP and RACE_TURN_MIN are these: it preloads this script): a turn past
## HAIRPIN rad is driven as a U-turn, at UTURN_SPEED (m/s), as the arc of TURN_RADIUS (m) a car
## can turn; a shortcut at CUT_TOP (m/s) at most; SPEED_LEAST (m/s) is the slowest a racer takes
## any bend.
const HAIRPIN := 2.4
const TURN_RADIUS := 5.0
const UTURN_SPEED := 3.5
const CUT_TOP := 16.0
const SPEED_LEAST := 6.0
## Points of the line: ARC_STEP m and ARC_ANGLE rad apart at most on an arc, LINE_STEP m on a straight.
const ARC_STEP := 1.0
const ARC_ANGLE := 0.08
const LINE_STEP := 4.0
## The honest car: the turn (rad) within any WINDOW m of the line counts as made in RUN m (the
## race bench measures the turn over 8 m driven; the longer window covers the points' spacing).
const WINDOW := 9.0
const RUN := 8.0

## What a junction of a stretch is driven as.
enum { CORNER, CHORD, RIGID }

var graph: LaneGraph
## Stretches built, by their key (`_key`).
var _stretches := {}
## Per edge: the station its line is cut at (-1: not found yet).
var _splits := PackedFloat32Array()
## How many stretches were built (not found in the cache), the microseconds that took and the
## most one took.
var built := 0
var built_usec := 0
var built_most := 0


## A stretch of the line: the way through a run of streets (`edges`, each in its lane of `lanes`)
## from station `from` of the first to station `to` of the last.
class Stretch:
	extends RefCounted
	var edges := PackedInt32Array()
	var lanes := PackedInt32Array()
	var from := 0.0
	var to := 0.0
	## Its points on the ground, the metres driven to each (those on the ground, but through a
	## U-turn, where a car drives the longer arc it can turn), the logical metres at each (0 at
	## `from`) and a speed no racer passes there (INF: none).
	var pt := PackedVector2Array()
	var gm := PackedFloat32Array()
	var xl := PackedFloat32Array()
	var fix := PackedFloat32Array()
	## Per street of it: logical metres = xs + station on it, and xc + metres into the junction
	## curve after it.
	var xs := PackedFloat32Array()
	var xc := PackedFloat32Array()
	## Its logical length.
	var span := 0.0
	## Its junctions (each from one street to the next that does not lie inside it): the index of
	## the first curve, what it is driven as, and the radius the lane graph's cars drive it at.
	var j_first := PackedInt32Array()
	var j_kind := PackedByteArray()
	var j_radius := PackedFloat32Array()
	## While it is built: the junctions (by first curve) whose arc came out too tight, the steps
	## back of its line, and whether it is the lane graph's way as it is.
	var poor := PackedInt32Array()
	var backs := 0
	var tight := 0
	var plain := false
	var cost := 0.0
	## For the checks: its arcs ([radius, turn, the radius its room asked for at least] flat), and
	## how many of its junctions were taken as a corner, a chord, or as the lane graph has them.
	var arcs := PackedFloat32Array()
	var kinds := PackedInt32Array([0, 0, 0])


## A racer's way: stretches end to end. `v` is filled by `speeds` for one racer.
class Path:
	extends RefCounted
	var edges := PackedInt32Array()
	var lanes := PackedInt32Array()
	var xs := PackedFloat32Array()
	var xc := PackedFloat32Array()
	var pt := PackedVector2Array()
	var gm := PackedFloat32Array()
	var xl := PackedFloat32Array()
	var fix := PackedFloat32Array()
	## The turn (rad) within WINDOW m of each point, before or after it.
	var turn := PackedFloat32Array()
	## The line's right-hand side at each point (between the pieces that meet there), and per
	## piece how much longer (+) or shorter (-) a metre of it is one metre to its right.
	var nr := PackedVector2Array()
	var bend := PackedFloat32Array()
	## The racer's speed at each point (m/s), for the grip it was built with.
	var v := PackedFloat32Array()
	## Per stretch: its first point, its first street (an index into `edges`) and the station on
	## that street it starts at.
	var part_i := PackedInt32Array()
	var part_q := PackedInt32Array()
	var part_from := PackedFloat32Array()

	## The index of the point at or before logical metres x, searched from `hint`.
	func seek(x: float, hint: int) -> int:
		var last := xl.size() - 2
		var i := clampi(hint, 0, last)
		while i < last and xl[i + 1] <= x:
			i += 1
		while i > 0 and xl[i] > x:
			i -= 1
		return i

	## The place on the ground at logical metres x; i from seek().
	func point(x: float, i: int) -> Vector2:
		var d := xl[i + 1] - xl[i]
		return pt[i].lerp(pt[i + 1], clampf((x - xl[i]) / d, 0.0, 1.0) if d > 0.0001 else 0.0)

	## The line's direction there.
	func direction(i: int) -> Vector2:
		return (pt[i + 1] - pt[i]).normalized()

	## The line's right-hand side at logical metres x; i from seek(). It turns evenly along a
	## piece, so a car held beside the line moves without a step where the line bends.
	func side(x: float, i: int) -> Vector2:
		var d := xl[i + 1] - xl[i]
		return nr[i].lerp(nr[i + 1], clampf((x - xl[i]) / d, 0.0, 1.0) if d > 0.0001 else 0.0)

	## The metres a car makes `off` m to the right of the line for each metre of piece i: fewer
	## inside a bend, more outside it.
	func beside(i: int, off: float) -> float:
		return 1.0 + bend[i] * off

	## The racer's speed there (m/s). Between two points the square of the speed runs straight,
	## as it does under steady braking.
	func speed(x: float, i: int) -> float:
		var d := xl[i + 1] - xl[i]
		var t := clampf((x - xl[i]) / d, 0.0, 1.0) if d > 0.0001 else 0.0
		return sqrt(lerpf(v[i] * v[i], v[i + 1] * v[i + 1], t))

	## The logical metres made by driving `step` m on from x; i from seek().
	func advance(x: float, i: int, step: float) -> float:
		var done := 0.0
		var last := xl.size() - 2
		while step > 0.0:
			var dx := xl[i + 1] - xl[i]
			var dg := gm[i + 1] - gm[i]
			if dg < 0.0001 or dx < 0.0001:
				done += step
				break
			var rate := dx / dg
			var room := xl[i + 1] - (x + done)
			if step * rate <= room or i >= last:
				done += step * rate
				break
			if room > 0.0:
				done += room
				step -= room / rate
			i += 1
		return done

	## The stretch the logical metres x lie in (an index into `part_i`).
	func part(x: float) -> int:
		var k := part_i.size() - 1
		while k > 0 and xl[part_i[k]] > x:
			k -= 1
		return k


## The points a stretch is built from: the lanes' lines and the junctions' curves, in order.
class Raw:
	extends RefCounted
	var p := PackedVector2Array()
	## The logical metres at each.
	var x := PackedFloat32Array()
	## The room for the line to its left and its right (m).
	var left := PackedFloat32Array()
	var right := PackedFloat32Array()
	## 1: inside a junction: `left` is its room towards the inside of a bend, and `out_l` / `out_r`
	## its room towards the outside of one, where that is on its left / its right.
	var inside := PackedByteArray()
	var out_l := PackedFloat32Array()
	var out_r := PackedFloat32Array()
	## 1: the line passes through it as it is (the ends of the stretch, a U-turn's curve).
	var rigid := PackedByteArray()
	## 1: kept by `_simplify` whatever its place.
	var keep := PackedByteArray()
	## From it to the next: the metres driven for each on the ground, and a speed no racer passes.
	var pace := PackedFloat32Array()
	var fix := PackedFloat32Array()
	## The junction it lies inside (an index into the stretch's j_first), -1 on a street.
	var junction := PackedInt32Array()

	func add(at: Vector2, logical: float, room_left: float, room_right: float, in_junction: bool, as_it_is: bool,
			kept: bool, driven: float, cap: float, of_junction: int, out_left := 0.0, out_right := 0.0) -> void:
		var n := p.size()
		if n > 0 and p[n - 1].distance_squared_to(at) < 0.0025:
			# The same place twice (a lane's end and its curve's start): one point, the stricter of the two.
			if as_it_is:
				rigid[n - 1] = 1
				keep[n - 1] = 1
			if kept:
				keep[n - 1] = 1
			pace[n - 1] = driven
			fix[n - 1] = cap
			return
		junction.append(of_junction)
		p.append(at)
		x.append(logical)
		left.append(maxf(room_left, 0.0))
		right.append(maxf(room_right, 0.0))
		inside.append(1 if in_junction else 0)
		out_l.append(out_left)
		out_r.append(out_right)
		rigid.append(1 if as_it_is else 0)
		keep.append(1 if kept or as_it_is else 0)
		pace.append(driven)
		fix.append(cap)


## One arc of the line and the points of the simplified line it takes the place of.
class Bend:
	extends RefCounted
	## The first and the last of those points (indices into the simplified line).
	var a := 0
	var b := 0
	## Where its legs meet, their directions, the turn (rad, + to the right) and its tan and
	## 1 / cos of half the turn.
	var at := Vector2.ZERO
	var d_in := Vector2.ZERO
	var d_out := Vector2.ZERO
	var theta := 0.0
	var tn := 0.0
	var sec := 0.0
	## Metres from point a on to `at`, and from `at` on to point b.
	var ta := 0.0
	var tb := 0.0
	## The legs' lengths beyond a and b (to the next point of the simplified line).
	var leg_in := 0.0
	var leg_out := 0.0
	## The widest radius its room allows and the tightest it needs (m).
	var most := 0.0
	var least := 0.0
	var r := 0.0
	var ok := false
	## The two bends it was joined from (null: a bend of the line itself).
	var first: Bend
	var second: Bend

	func reach() -> float:
		return r * tn

	## The widest it can be by itself: its room, and its legs as far as the next point of the line.
	func alone() -> float:
		return minf(most, minf(ta + leg_in, tb + leg_out) / tn)


func _init(lane_graph: LaneGraph) -> void:
	graph = lane_graph


static func right(d: Vector2) -> Vector2:
	return Vector2(-d.y, d.x)


## What is left of edge e's lane on each side of a car in its middle (m).
func free_side(e: int) -> float:
	return clampf((graph.e_lw[e] - CAR_W) * 0.5 - SIDE_GAP, 0.0, SIDE_MAX)


func is_long(e: int) -> bool:
	return graph.e_s1[e] - graph.e_s0[e] >= LONG


## The station edge e's line is cut at: the middle of the longest straight piece of its middle
## (so the line there is the lane's own, straight, and no arc is cut in two).
func split(e: int) -> float:
	if _splits.is_empty():
		_splits.resize(graph.e_a.size())
		_splits.fill(-1.0)
	var at := _splits[e]
	if at >= 0.0:
		return at
	var s0 := graph.e_s0[e]
	var s1 := graph.e_s1[e]
	var u := s1 - s0
	var lo := s0 + u * 0.3
	var hi := s0 + u * 0.7
	var i0 := graph.e_first[e]
	var count := graph.e_count[e]
	at = (s0 + s1) * 0.5
	var longest := -1.0
	var prev := s0
	for q in range(1, count):
		var st := s1 if q == count - 1 else clampf(graph.cum[i0 + q], s0, s1)
		if st <= prev + 0.001:
			continue
		if st > lo and prev < hi and st - prev > longest:
			longest = st - prev
			at = clampf((prev + st) * 0.5, s0 + u * 0.25, s0 + u * 0.75)
		prev = st
	_splits[e] = at
	return at


## The lane of edge f a racer continues in from lane k of edge e. At a turn the lane graph's rule
## (the rightmost lane out of a right turn, the leftmost out of a left). Straight on, the lane
## that lies ahead of its own: where a street gains or loses a lane the graph's rule keeps the
## lane's number, which can be the lane beside.
func lane_on(e: int, k: int, f: int) -> int:
	var g := graph
	var n := g.e_lanes[f]
	if n == 1:
		return 0
	var d0 := g.direction(e, g.e_s1[e])
	var d3 := g.direction(f, g.e_s0[f])
	if absf(d0.angle_to(d3)) > LANE_TURN:
		return g.next_lane(e, k, f)
	var p0 := g.point_at(e, g.e_s1[e], g.lane_offset(e, k))
	var bis := (d0 + d3).normalized()
	var p3 := g.point_at(f, g.e_s0[f], 0.0)
	var across := g.point_at(f, g.e_s0[f], 1.0) - p3
	# Lane j of f lies bis.cross(p3 + across * offset(j) - p0) to the side of the way straight on.
	var side := bis.cross(p3 - p0)
	var per := bis.cross(across)
	var best := 0
	var least := INF
	for j in n:
		var step := absf(side + per * g.lane_offset(f, j))
		if step < least:
			least = step
			best = j
	return best


## The lanes a racer takes along `edges` from lane `lane` of the first.
func lanes_of(edges: PackedInt32Array, lane: int) -> PackedInt32Array:
	var out := PackedInt32Array([lane])
	for i in range(1, edges.size()):
		out.append(lane_on(edges[i - 1], out[i - 1], edges[i]))
	return out


func _key(edges: PackedInt32Array, lanes: PackedInt32Array, from: float, to: float, cuts: Array) -> PackedInt32Array:
	var key := PackedInt32Array()
	key.append_array(edges)
	key.append(-1)
	key.append_array(lanes)
	key.append(roundi(from * 50.0))
	key.append(roundi(to * 50.0))
	for i in cuts.size():
		if cuts[i] != null:
			key.append(-2 - i)
	return key


## The stretch along `edges` (each in its lane of `lanes`) from station `from` of the first to
## station `to` of the last; `cuts` holds, for a junction that is a shortcut, its curve (the
## junction after edges[i] at cuts[i]; null or missing: the lane graph's). Built once and kept.
func stretch(edges: PackedInt32Array, lanes: PackedInt32Array, from: float, to: float, cuts: Array = []) -> Stretch:
	var key := _key(edges, lanes, from, to, cuts)
	var found: Stretch = _stretches.get(key)
	if found != null:
		return found
	var t0 := Time.get_ticks_usec()
	found = _build(edges, lanes, from, to, cuts)
	built += 1
	var took := Time.get_ticks_usec() - t0
	built_usec += took
	built_most = maxi(built_most, took)
	_stretches[key] = found
	return found


## Forgets the stretches kept (a race is over; the next one may drive other streets).
func clear() -> void:
	_stretches.clear()


## How many stretches are kept.
func kept() -> int:
	return _stretches.size()


## A racer's way along `edges` (each in its lane of `lanes`) from station `from` of the first to
## station `to` of the last: cut into stretches at the split of every long street of it.
func path(edges: PackedInt32Array, lanes: PackedInt32Array, from: float, to: float, cuts: Array = []) -> Path:
	var out := Path.new()
	var n := edges.size()
	out.edges = edges
	out.lanes = lanes
	out.xs.resize(n)
	out.xc.resize(n)
	var first := 0
	var at := from
	var x0 := 0.0
	for i in n:
		var e := edges[i]
		var last := i == n - 1
		var cut := -1.0
		if is_long(e):
			var sp := split(e)
			if (i > first or sp > at + 1.0) and (not last or sp < to - 1.0):
				cut = sp
		if cut >= 0.0:
			x0 = _append(out, stretch(edges.slice(first, i + 1), lanes.slice(first, i + 1), at, cut, cuts.slice(first, i)), first, at, x0)
			first = i
			at = cut
		if last:
			x0 = _append(out, stretch(edges.slice(first, n), lanes.slice(first, n), at, to, cuts.slice(first, n - 1)), first, at, x0)
	out.turn = turns(out.pt, out.gm)
	sides(out)
	return out


## Sets stretch st at the end of path p (its first street is p's `first`); the logical metres at
## its end.
func _append(p: Path, st: Stretch, first: int, from: float, x0: float) -> float:
	var base := p.pt.size()
	var skip := 0
	var g0 := 0.0
	if base > 0:
		# The stretch before ends where this one begins: one point.
		skip = 1
		g0 = p.gm[base - 1]
		p.fix[base - 1] = minf(p.fix[base - 1], st.fix[0])
	p.part_i.append(maxi(base - 1, 0))
	p.part_q.append(first)
	p.part_from.append(from)
	for k in range(skip, st.pt.size()):
		p.pt.append(st.pt[k])
		p.gm.append(g0 + st.gm[k])
		p.xl.append(x0 + st.xl[k])
		p.fix.append(st.fix[k])
	for j in st.edges.size():
		p.xs[first + j] = x0 + st.xs[j]
		if j < st.edges.size() - 1:
			p.xc[first + j] = x0 + st.xc[j]
	return x0 + st.span


## The turn (rad) within WINDOW driven metres of each point of a line, before or after it: the
## widest spread of the line's headings there, so a quick flick left and right counts too.
static func turns(pt: PackedVector2Array, gm: PackedFloat32Array) -> PackedFloat32Array:
	var n := pt.size()
	var out := PackedFloat32Array()
	out.resize(n)
	if n < 3:
		return out
	var m := n - 1
	var hd := PackedFloat32Array()
	hd.resize(m)
	var prev := 0.0
	for i in m:
		var a := (pt[i + 1] - pt[i]).angle()
		prev = a if i == 0 else prev + angle_difference(prev, a)
		hd[i] = prev
	# After the point: from the piece that ends at it to the one WINDOW m on.
	var j := 0
	for i in n:
		var lo := maxi(i - 1, 0)
		j = maxi(j, lo)
		while j < m - 1 and gm[j + 1] < gm[i] + WINDOW:
			j += 1
		var mn := hd[lo]
		var mx := mn
		for s in range(lo + 1, j + 1):
			mn = minf(mn, hd[s])
			mx = maxf(mx, hd[s])
		out[i] = mx - mn
	# Before it: from the piece WINDOW m back to the one that starts at it.
	var k := 0
	for i in n:
		var hi := mini(i, m - 1)
		while k < hi and gm[k + 1] <= gm[i] - WINDOW:
			k += 1
		var mn := hd[hi]
		var mx := mn
		for s in range(k, hi):
			mn = minf(mn, hd[s])
			mx = maxf(mx, hd[s])
		out[i] = maxf(out[i], mx - mn)
	return out


## Fills p.nr and p.bend: the right-hand side of path p at each point, and how a metre beside
## each piece compares with the piece's own (Path.side, Path.beside).
static func sides(p: Path) -> void:
	var n := p.pt.size()
	p.nr.resize(n)
	p.bend.resize(maxi(n - 1, 0))
	if n < 2:
		return
	# Each piece's direction; one without length takes its neighbour's.
	var dir := PackedVector2Array()
	dir.resize(n - 1)
	var known := Vector2.ZERO
	for i in n - 1:
		var t := p.pt[i + 1] - p.pt[i]
		if t.length_squared() > 0.000001:
			known = t.normalized()
		dir[i] = known
	for i in range(n - 2, -1, -1):
		if dir[i] == Vector2.ZERO:
			dir[i] = known
		known = dir[i]
	for i in n:
		var a := dir[maxi(i - 1, 0)]
		var b := dir[mini(i, n - 2)]
		var m := a + b
		p.nr[i] = right(m.normalized() if m.length_squared() > 0.0001 else b)
	for i in n - 1:
		var t := p.pt[i + 1] - p.pt[i]
		var l2 := t.length_squared()
		p.bend[i] = (p.nr[i + 1] - p.nr[i]).dot(t) / l2 if l2 > 0.000001 else 0.0


## The fastest a car of grip `lat` (m/s²) takes a place of the line that turns `turn` rad within
## its window.
static func cap(lat: float, turn: float) -> float:
	return maxf(sqrt(lat * RUN / maxf(turn, 0.0001)), SPEED_LEAST)


## Fills p.v: the speed for every point of path p for a racer of grip `lat` that brakes at `brake`
## (m/s²). No point is passed faster than its turn allows (`cap`) or its `fix`, and each is braked
## for in time. Between logical metres `fast_from` and `fast_to` the racer misjudges: `fast` times
## its speed (a mistake, traffic.gd MISTAKE_FAST), though never past what a car of grip `grip` holds.
func speeds(p: Path, lat: float, brake: float, fast_from := INF, fast_to := -INF, fast := 1.0, grip := 0.0) -> void:
	var n := p.pt.size()
	p.v.resize(n)
	if n == 0:
		return
	for i in n:
		var c := cap(lat, p.turn[i])
		if fast != 1.0 and p.xl[i] >= fast_from and p.xl[i] <= fast_to:
			c = minf(c * fast, maxf(cap(grip, p.turn[i]) * 0.97, c))
		p.v[i] = minf(c, p.fix[i])
	for i in range(n - 2, -1, -1):
		var next := p.v[i + 1]
		p.v[i] = minf(p.v[i], sqrt(next * next + 2.0 * brake * (p.gm[i + 1] - p.gm[i])))


# --- building a stretch ---------------------------------------------------------------------------

## A stretch, built: first with every junction as wide as its room allows. A junction whose arc
## comes out tighter than the lane graph's own curve is tried as the lane graph has it too, and the
## quicker of the two kept; and should the line still step back on itself, the whole stretch is
## taken as the lane graph has it (never worse than the town's cars).
func _build(edges: PackedInt32Array, lanes: PackedInt32Array, from: float, to: float, cuts: Array) -> Stretch:
	var forced := PackedByteArray()
	forced.resize(maxi(edges.size() - 1, 0))
	var st := _try(edges, lanes, from, to, cuts, forced, false)
	for first in st.poor:
		var other := forced.duplicate()
		other[first] = 1
		var alt := _try(edges, lanes, from, to, cuts, other, false)
		if alt.tight < st.tight or (alt.tight == st.tight and alt.cost < st.cost - 0.005):
			alt.poor = st.poor
			st = alt
			forced = other
	if st.backs > 0:
		var plain := _try(edges, lanes, from, to, cuts, forced, true)
		if plain.backs <= st.backs:
			st = plain
	return st


func _try(edges: PackedInt32Array, lanes: PackedInt32Array, from: float, to: float, cuts: Array, forced: PackedByteArray,
		plain: bool) -> Stretch:
	var st := Stretch.new()
	st.edges = edges
	st.lanes = lanes
	st.from = from
	st.to = to
	st.xs.resize(edges.size())
	st.xc.resize(edges.size())
	st.plain = plain
	var raw := _points(st, cuts, forced, plain)
	var line := _simplify(raw)
	var bends := _bends(raw, line)
	st.poor = _poor(st, raw, line, bends)
	_emit(st, raw, line, bends)
	st.xl = _logical(raw, st.pt)
	# What it costs: the seconds a car of middling grip would take along it at its caps alone.
	var turn := turns(st.pt, st.gm)
	for i in range(1, st.pt.size()):
		st.cost += (st.gm[i] - st.gm[i - 1]) / minf(minf(cap(COST_GRIP, maxf(turn[i], turn[i - 1])), COST_TOP), st.fix[i])
	return st


## The junctions of stretch st (their first curve's index) whose arc came out tighter than
## POOR of the radius the lane graph's own curve is driven at, or tighter than its room asks (it
## would leave the lane); and st.tight, how many arcs of the stretch are that tight.
func _poor(st: Stretch, raw: Raw, line: PackedInt32Array, bends: Array[Bend]) -> PackedInt32Array:
	var count := st.j_first.size()
	var tight := PackedFloat32Array()
	tight.resize(count)
	tight.fill(INF)
	var off := PackedByteArray()
	off.resize(count)
	for bd in bends:
		var wide := bd.r >= bd.least - 0.01
		if not wide:
			st.tight += 1
		for q in range(line[bd.a], line[bd.b] + 1):
			var jn := raw.junction[q]
			if jn >= 0:
				tight[jn] = minf(tight[jn], bd.r)
				if not wide:
					off[jn] = 1
	var out := PackedInt32Array()
	for jn in count:
		if st.j_kind[jn] == CORNER and (tight[jn] < POOR * st.j_radius[jn] or off[jn] == 1):
			out.append(st.j_first[jn])
	return out


## The points stretch st is built from (and its xs, xc, span and junctions): each street's lane
## line, moved sideways down its ramps, and each junction's way. `forced` marks the junctions (by
## their first curve) taken as the lane graph has them; `plain`: everything is.
func _points(st: Stretch, cuts: Array, forced: PackedByteArray, plain: bool) -> Raw:
	var g := graph
	var edges := st.edges
	var lanes := st.lanes
	var n := edges.size()
	# Each street's stretch of it, whether it lies inside a junction, the curves between them and
	# the logical metres.
	var a := PackedFloat32Array()
	var z := PackedFloat32Array()
	var inner := PackedByteArray()
	var curve: Array[PackedVector2Array] = []
	var length := PackedFloat32Array()
	var x := 0.0
	for i in n:
		var e := edges[i]
		a.append(st.from if i == 0 else g.e_s0[e])
		z.append(maxf(st.to if i == n - 1 else g.e_s1[e], a[i] + 0.05))
		inner.append(1 if i > 0 and i < n - 1 and z[i] - a[i] < INSIDE else 0)
		st.xs[i] = x - a[i]
		x += z[i] - a[i]
		if i == n - 1:
			break
		var cut: Variant = cuts[i] if i < cuts.size() else null
		var c: PackedVector2Array = cut if cut != null else g.connector(e, lanes[i], edges[i + 1], lanes[i + 1])
		curve.append(c)
		length.append(LaneGraph.bezier_length(c))
		st.xc[i] = x
		x += length[i]
	st.span = x
	# Each curve as the lane graph's cars drive it: the metres driven for each on the ground (a
	# tight one is driven as the arc a car can turn) and the speed no racer passes on it.
	var pace := PackedFloat32Array()
	var fix := PackedFloat32Array()
	var hard := PackedByteArray()
	for i in n - 1:
		var turn := absf(g.direction(edges[i], g.e_s1[edges[i]]).angle_to(g.direction(edges[i + 1], g.e_s0[edges[i + 1]])))
		var is_cut := i < cuts.size() and cuts[i] != null
		var back := edges[i + 1] == g.e_reverse[edges[i]] or turn > HAIRPIN
		pace.append(1.0 if is_cut else maxf(length[i], TURN_RADIUS * turn) / length[i])
		fix.append(CUT_TOP if is_cut else (UTURN_SPEED if back else INF))
		hard.append(1 if is_cut or back else 0)
	# The junctions, each from one street to the next that is not inside it: what it is driven as,
	# and the sideways move at its two mouths.
	var move_out := PackedFloat32Array()
	var move_in := PackedFloat32Array()
	move_out.resize(n)
	move_in.resize(n)
	var j_last := PackedInt32Array()
	var i := 0
	while i < n - 1:
		var j := i + 1
		while j < n - 1 and inner[j] == 1:
			j += 1
		var e := edges[i]
		var f := edges[j]
		var p0 := curve[i][0]
		var p3 := curve[j - 1][3]
		var d0 := g.direction(e, g.e_s1[e])
		var d3 := g.direction(f, g.e_s0[f])
		var theta := d0.angle_to(d3)
		var is_hard := plain or forced[i] == 1 or absf(theta) > HAIRPIN
		for q in range(i, j):
			if hard[q] == 1:
				is_hard = true
		var kind := RIGID
		var driven := 0.0
		for q in range(i, j):
			driven += length[q] * pace[q] + (z[q + 1] - a[q + 1] if q + 1 < j else 0.0)
		if not is_hard:
			var way := _way(st, curve, a, z, i, j)
			# How far its way strays from the straight between its mouths, and how much it turns in all.
			var chord := p3 - p0
			var l2 := chord.length_squared()
			var stray := 0.0
			for q in way:
				var t := clampf((q - p0).dot(chord) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
				stray = maxf(stray, q.distance_to(p0 + chord * t))
			# Its heading along the way, from the way in: where it ends up and how far it swings.
			var swing := 0.0
			var lo := 0.0
			var hi := 0.0
			var heading := d0
			var prev := p0
			for q in way.size() + 2:
				var next := way[q] if q < way.size() else (p3 if q == way.size() else p3 + d3)
				if next.distance_squared_to(prev) < 0.0001:
					continue
				var dir := (next - prev).normalized()
				swing += heading.angle_to(dir)
				lo = minf(lo, swing)
				hi = maxf(hi, swing)
				heading = dir
				prev = next
			if absf(theta) < STRAIGHT_ON and (j == i + 1 or stray < CHORD_STRAY):
				kind = CHORD
			elif absf(swing - theta) < 1.0 and hi <= maxf(theta, 0.0) + LOOP and lo >= minf(theta, 0.0) - LOOP:
				kind = CORNER
		if kind == CHORD:
			var bis := (d0 + d3).normalized()
			var step := bis.cross(p3 - p0)
			if absf(step) > STEP_LEAST:
				var room_e := minf(free_side(e) * MOVE_SHARE, RAMP_STEEP * _ramp_room(i, n, a, z))
				var room_f := minf(free_side(f) * MOVE_SHARE, RAMP_STEEP * _ramp_room(j, n, a, z))
				var half := absf(step) * 0.5
				var by_e := minf(room_e, half)
				var by_f := minf(room_f, half)
				var rest := absf(step) - by_e - by_f
				var more := minf(room_e - by_e, rest)
				by_e += more
				by_f += minf(room_f - by_f, rest - more)
				move_out[i] = signf(step) * by_e
				move_in[j] = -signf(step) * by_f
		st.j_first.append(i)
		st.j_kind.append(kind)
		st.j_radius.append(maxf(driven, TURN_RADIUS * absf(theta)) / maxf(absf(theta), 0.05))
		st.kinds[kind] += 1
		j_last.append(j)
		i = j
	# The points: each street's lane line, each junction's way.
	var raw := Raw.new()
	var jn := 0
	i = 0
	while i < n:
		var e := edges[i]
		var off := g.lane_offset(e, lanes[i])
		var h := free_side(e)
		var before := jn - 1
		var room := _ramp_room(i, n, a, z)
		var l_in := clampf(absf(move_in[i]) / RAMP_SLOPE, RAMP_LEAST, maxf(room, RAMP_LEAST))
		var l_out := clampf(absf(move_out[i]) / RAMP_SLOPE, RAMP_LEAST, maxf(room, RAMP_LEAST))
		var stations := PackedFloat32Array([a[i]])
		var i0 := g.e_first[e]
		for q in range(1, g.e_count[e] - 1):
			var at := g.cum[i0 + q]
			if at > a[i] + 0.05 and at < z[i] - 0.05:
				stations.append(at)
		stations.append(z[i])
		# Kept whatever their place: where a ramp ends, and a metre in from each end of the stretch
		# (so the line leaves and reaches the end along the lane's own line).
		var marks := PackedFloat32Array()
		if move_in[i] != 0.0:
			marks.append(a[i] + l_in)
		if move_out[i] != 0.0:
			marks.append(z[i] - l_out)
		if i == 0:
			marks.append(a[i] + 1.0)
		if i == n - 1:
			marks.append(z[i] - 1.0)
		for at in marks:
			if at > a[i] + 0.3 and at < z[i] - 0.3:
				stations.append(at)
		stations.sort()
		var lp := PackedVector2Array()
		var lx := PackedFloat32Array()
		var ll := PackedFloat32Array()
		var lk := PackedByteArray()
		for q in stations.size():
			var s := stations[q]
			if q > 0 and s - stations[q - 1] < 0.05:
				continue
			var lat := 0.0
			if move_in[i] != 0.0:
				lat += move_in[i] * maxf(0.0, 1.0 - (s - a[i]) / l_in)
			if move_out[i] != 0.0:
				lat += move_out[i] * maxf(0.0, 1.0 - (z[i] - s) / l_out)
			lp.append(g.point_at(e, s, off + lat))
			lx.append(st.xs[i] + s)
			ll.append(lat)
			lk.append(1 if marks.has(s) else 0)
		if not plain:
			_unfold(lp, lx, ll, lk)
		var rigid_in := i == 0 or st.j_kind[before] == RIGID
		var rigid_out := i == n - 1 or st.j_kind[jn] == RIGID
		for q in lp.size():
			var first := q == 0
			var last := q == lp.size() - 1
			# The ends of the stretch and the mouths of a junction driven as it is: passed as they are.
			var as_it_is := plain or (first and rigid_in) or (last and rigid_out)
			var driven := pace[i] if last and i < n - 1 and st.j_kind[jn] == RIGID else 1.0
			var capped := INF
			if last and i < n - 1 and st.j_kind[jn] == RIGID:
				capped = fix[i]
			elif first and i > 0 and st.j_kind[before] == RIGID:
				capped = fix[i - 1]
			raw.add(lp[q], lx[q], h + ll[q], h - ll[q], false, as_it_is, lk[q] == 1, driven, capped, -1)
		if i == n - 1:
			break
		# The junction after it, to street j.
		var j := j_last[jn]
		var beside := minf(h, free_side(edges[j]))
		var room_j := beside + JUNCTION_IN
		# Outside the lane graph's curve the junction is the line's only where no lane of its streets
		# lies on that side: a car may be in that one, beside it (lines over other lanes: step 4b).
		var out_l := JUNCTION_OUT
		var out_r := JUNCTION_OUT
		for q in range(i, j + 1):
			if lanes[q] > 0:
				out_l = beside
			if lanes[q] < g.e_lanes[edges[q]] - 1:
				out_r = beside
		for q in range(i, j):
			var c := curve[q]
			var at := st.xc[q]
			if st.j_kind[jn] == RIGID:
				var m := maxi(ceili(length[q] / ARC_STEP), 8)
				for k in range(1, m):
					raw.add(LaneGraph.bezier(c, float(k) / m), at + length[q] * k / m, 0.0, 0.0, true, true, true, pace[q], fix[q], jn)
			elif st.j_kind[jn] == CORNER:
				for k in range(1, 4):
					raw.add(LaneGraph.bezier(c, k * 0.25), at + length[q] * k * 0.25, room_j, room_j, true, false, false, 1.0, INF, jn, out_l, out_r)
			if q + 1 == j or st.j_kind[jn] == CHORD:
				continue
			# The short piece after this curve, inside the junction.
			var mid := edges[q + 1]
			var mid_off := g.lane_offset(mid, lanes[q + 1])
			var m0 := g.e_first[mid]
			var mids := PackedFloat32Array([a[q + 1]])
			for k in range(1, g.e_count[mid] - 1):
				var s := g.cum[m0 + k]
				if s > a[q + 1] + 0.05 and s < z[q + 1] - 0.05:
					mids.append(s)
			mids.append(z[q + 1])
			for k in mids.size():
				var s := mids[k]
				var last := k == mids.size() - 1
				if st.j_kind[jn] == RIGID:
					raw.add(g.point_at(mid, s, mid_off), st.xs[q + 1] + s, 0.0, 0.0, true, true, true,
							pace[q + 1] if last else 1.0, fix[q + 1] if last else (fix[q] if k == 0 else INF), jn)
				else:
					raw.add(g.point_at(mid, s, mid_off), st.xs[q + 1] + s, room_j, room_j, true, false, false, 1.0, INF, jn, out_l, out_r)
		jn += 1
		i = j
	return raw


## The lane graph's way through the junction from street i to street j of stretch st, between
## its two mouths: the curves, and the short pieces between them.
func _way(st: Stretch, curve: Array[PackedVector2Array], a: PackedFloat32Array, z: PackedFloat32Array, i: int, j: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in range(i, j):
		for k in range(1, 8):
			out.append(LaneGraph.bezier(curve[q], k / 8.0))
		if q + 1 == j:
			break
		var e := st.edges[q + 1]
		var off := graph.lane_offset(e, st.lanes[q + 1])
		out.append(graph.point_at(e, a[q + 1], off))
		var i0 := graph.e_first[e]
		for k in range(1, graph.e_count[e] - 1):
			var s := graph.cum[i0 + k]
			if s > a[q + 1] + 0.05 and s < z[q + 1] - 0.05:
				out.append(graph.point_at(e, s, off))
		out.append(graph.point_at(e, z[q + 1], off))
	return out


## Takes the loops out of a lane's line (points p, their logical metres x, sideways moves l and
## keep marks k): where a sharp bend of the street folds its inner lane back over itself, the line
## runs straight to where it crosses itself.
static func _unfold(p: PackedVector2Array, x: PackedFloat32Array, l: PackedFloat32Array, k: PackedByteArray) -> void:
	var i := 0
	while i < p.size() - 3:
		var hit := -1
		var at := Vector2.ZERO
		for j in range(i + 2, p.size() - 1):
			if x[j] - x[i + 1] > UNFOLD:
				break
			var cross: Variant = Geometry2D.segment_intersects_segment(p[i], p[i + 1], p[j], p[j + 1])
			if cross != null:
				hit = j
				at = cross
		if hit < 0:
			i += 1
			continue
		var along := p[i].distance_to(at) / maxf(p[i].distance_to(p[i + 1]), 0.001)
		var at_x := lerpf(x[i], x[i + 1], clampf(along, 0.0, 1.0))
		var at_l := l[i + 1]
		for q in range(hit, i, -1):
			p.remove_at(q)
			x.remove_at(q)
			l.remove_at(q)
			k.remove_at(q)
		p.insert(i + 1, at)
		x.insert(i + 1, at_x)
		l.insert(i + 1, at_l)
		k.insert(i + 1, 0)


## The metres of street i of a stretch a ramp may take: all but RAMP_KEEP m of the first and the
## last street, half of one between two junctions.
func _ramp_room(i: int, n: int, a: PackedFloat32Array, z: PackedFloat32Array) -> float:
	var span := z[i] - a[i]
	if i == 0 or i == n - 1:
		return maxf(span - RAMP_KEEP - (RAMP_KEEP if n == 1 else 0.0), 0.0)
	return span * 0.5


## The points of `raw` the simplified line keeps (indices): its ends, the points passed as they
## are, and every point further than FLAT from the straight between the kept ones around it.
func _simplify(raw: Raw) -> PackedInt32Array:
	var n := raw.p.size()
	var kept := PackedByteArray()
	kept.resize(n)
	kept[0] = 1
	kept[n - 1] = 1
	var stack := PackedInt32Array()
	var from := 0
	for i in range(1, n):
		if raw.keep[i] == 0 and i < n - 1:
			continue
		kept[i] = 1
		if i > from + 1:
			stack.append(from)
			stack.append(i)
		from = i
	while not stack.is_empty():
		var b := stack[stack.size() - 1]
		var a := stack[stack.size() - 2]
		stack.resize(stack.size() - 2)
		var pa := raw.p[a]
		var ab := raw.p[b] - pa
		var l2 := ab.length_squared()
		var far := -1
		var most := FLAT * FLAT
		for i in range(a + 1, b):
			var t := clampf((raw.p[i] - pa).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
			var d2 := raw.p[i].distance_squared_to(pa + ab * t)
			if d2 > most:
				most = d2
				far = i
		if far < 0:
			continue
		kept[far] = 1
		if far > a + 1:
			stack.append(a)
			stack.append(far)
		if b > far + 1:
			stack.append(far)
			stack.append(b)
	var line := PackedInt32Array()
	for i in n:
		if kept[i] == 1:
			line.append(i)
	return line


## The arc that takes the place of points a to b of the simplified line `line` (a == b: of one
## bend), with the radii its room allows and needs: the line may pass no further inside any point
## it leaves out than that point's room on that side, and no further outside.
func _bend(raw: Raw, line: PackedInt32Array, a: int, b: int) -> Bend:
	var out := Bend.new()
	out.a = a
	out.b = b
	var pa := raw.p[line[a]]
	var pb := raw.p[line[b]]
	var before := raw.p[line[a - 1]]
	var after := raw.p[line[b + 1]]
	out.leg_in = pa.distance_to(before)
	out.leg_out = after.distance_to(pb)
	if out.leg_in < 0.01 or out.leg_out < 0.01:
		return out
	out.d_in = (pa - before) / out.leg_in
	out.d_out = (after - pb) / out.leg_out
	out.theta = out.d_in.angle_to(out.d_out)
	var turn := absf(out.theta)
	if turn < 0.0005 or turn > JOIN_TURN + 0.6:
		return out
	if a == b:
		out.at = pa
	else:
		if turn > JOIN_TURN:
			return out
		var den := out.d_in.cross(out.d_out)
		if absf(den) < 0.01:
			return out
		var w := pb - pa
		out.ta = w.cross(out.d_out) / den
		out.tb = out.d_in.cross(w) / den
		if out.ta < -0.01 or out.tb < -0.01:
			return out  # its legs do not meet ahead: no one corner
		out.at = pa + out.d_in * out.ta
	var half := turn * 0.5
	out.tn = tan(half)
	out.sec = 1.0 / cos(half)
	var sgn := signf(out.theta)
	var bis := (out.d_out - out.d_in).normalized()
	var n_in := right(out.d_in) * sgn
	var n_out := right(out.d_out) * sgn
	var tn2 := out.tn * out.tn
	out.most = RADIUS_MOST
	out.least = 0.0
	for q in range(line[a - 1] + 1, line[b + 1]):
		var room_in: float
		var room_out: float
		if raw.inside[q] == 1:
			room_in = raw.left[q]
			room_out = raw.out_l[q] if sgn > 0.0 else raw.out_r[q]
		elif sgn > 0.0:
			room_in = raw.right[q]
			room_out = raw.left[q]
		else:
			room_in = raw.left[q]
			room_out = raw.right[q]
		var w := raw.p[q] - out.at
		var wb := w.dot(bis)
		var w2 := w.length_squared()
		# No further inside it than its room: the arc that passes room_in inside the point.
		var bb := out.sec * wb + room_in
		var disc := bb * bb - tn2 * (w2 - room_in * room_in)
		out.most = minf(out.most, (bb + sqrt(maxf(disc, 0.0))) / tn2)
		# No further outside it, nor outside the way on from it to the next point (the arc bulges
		# furthest from the middle of a straight piece it passes): beside a leg a place lies as far
		# inside the line as it lies from the leg; past its room only an arc that comes in to it
		# will do.
		var parts := 1
		if a != b and q >= line[a] and q < line[b]:
			parts = maxi(ceili(raw.p[q].distance_to(raw.p[q + 1]) / BULGE_STEP), 1)
		for k in parts:
			if k > 0:
				w = raw.p[q].lerp(raw.p[q + 1], float(k) / parts) - out.at
				wb = w.dot(bis)
				w2 = w.length_squared()
			var beside := w.dot(n_in) if -w.dot(out.d_in) >= w.dot(out.d_out) else w.dot(n_out)
			if beside > room_out:
				bb = out.sec * wb - room_out
				disc = bb * bb - tn2 * (w2 - room_out * room_out)
				out.least = maxf(out.least, (bb + sqrt(maxf(disc, 0.0))) / tn2)
	out.ok = out.most >= out.least
	return out


## The arcs of the simplified line: one for each bend, then bends of one hand whose arcs would
## not both fit between them joined into one arc while that arc is the wider (`_join`), then each
## arc's radius: as wide as its room and its legs allow, a leg between two arcs shared.
func _bends(raw: Raw, line: PackedInt32Array) -> Array[Bend]:
	var bends: Array[Bend] = []
	for i in range(1, line.size() - 1):
		if raw.rigid[line[i]] == 1:
			continue
		var bd := _bend(raw, line, i, i)
		if bd.ok:
			bends.append(bd)
	while true:
		var best := -1
		var best_gain := 0.0
		var best_bend: Bend = null
		for k in bends.size() - 1:
			var joined := _join(raw, line, bends[k], bends[k + 1])
			if joined == null:
				continue
			if joined.r > best_gain:
				best_gain = joined.r
				best = k
				best_bend = joined
		if best < 0:
			break
		best_bend.first = bends[best]
		best_bend.second = bends[best + 1]
		bends[best] = best_bend
		bends.remove_at(best + 1)
	# The radii. A joined arc that cannot be as wide as its room asks (its neighbours need the legs)
	# would leave the lane: it is taken apart again.
	while true:
		_radii(bends)
		var apart := -1
		for k in bends.size():
			if bends[k].first != null and bends[k].r < bends[k].least - 0.01:
				apart = k
				break
		if apart < 0:
			break
		var joined := bends[apart]
		bends[apart] = joined.first
		bends.insert(apart + 1, joined.second)
	return bends


## The radius of each arc of `bends`: as wide as its room and its legs allow alone, then a leg
## between two shared, then what one left of a leg to the other; and an arc that came out tighter
## than its room asks takes what it needs of the legs from its neighbours.
func _radii(bends: Array[Bend]) -> void:
	var count := bends.size()
	for bd in bends:
		bd.r = bd.alone()
	for k in count - 1:
		var g := bends[k]
		var h := bends[k + 1]
		if g.b + 1 != h.a:
			continue
		var both := _share(g, h, g.r, h.r)
		g.r = both.x
		h.r = both.y
	for pass_no in 2:
		for k in count:
			var bd := bends[k]
			var room_in := bd.ta + bd.leg_in
			var room_out := bd.tb + bd.leg_out
			if k > 0 and bends[k - 1].b + 1 == bd.a:
				room_in += bends[k - 1].tb - bends[k - 1].reach()
			if k < count - 1 and bd.b + 1 == bends[k + 1].a:
				room_out += bends[k + 1].ta - bends[k + 1].reach()
			bd.r = maxf(bd.r, minf(bd.most, minf(room_in, room_out) / bd.tn))
	for k in count:
		var bd := bends[k]
		if bd.r >= bd.least - 0.001 or bd.least > bd.most:
			continue
		var before: Bend = bends[k - 1] if k > 0 and bends[k - 1].b + 1 == bd.a else null
		var after: Bend = bends[k + 1] if k < count - 1 and bd.b + 1 == bends[k + 1].a else null
		var need := bd.least * bd.tn
		var room_in := bd.ta + bd.leg_in + (before.tb - before.least * before.tn if before != null else 0.0)
		var room_out := bd.tb + bd.leg_out + (after.ta - after.least * after.tn if after != null else 0.0)
		if need > room_in or need > room_out:
			continue
		bd.r = bd.least
		if before != null:
			before.r = minf(before.r, maxf(before.tb + before.leg_out + bd.ta - need, 0.0) / before.tn)
		if after != null:
			after.r = minf(after.r, maxf(bd.tb + bd.leg_out + after.ta - need, 0.0) / after.tn)


## The radii of two arcs next to each other (g before h) that would be `rg` and `rh` alone, with
## the leg between them shared: the one that needs less than half keeps its own.
func _share(g: Bend, h: Bend, rg: float, rh: float) -> Vector2:
	var between := g.tb + g.leg_out + h.ta
	if rg * g.tn + rh * h.tn <= between:
		return Vector2(rg, rh)
	var even := between / (g.tn + h.tn)
	if rg <= even:
		return Vector2(rg, minf(rh, (between - rg * g.tn) / h.tn))
	if rh <= even:
		return Vector2(minf(rg, (between - rh * h.tn) / g.tn), rh)
	return Vector2(even, even)


## Bends g and h (next to each other, g first) as one arc, or null: they turn the same way, their
## own arcs do not both fit on the leg between them, the one arc stays in its room, and it is
## wider than the tighter of the two would be. Its `r` holds the gain (m of radius).
func _join(raw: Raw, line: PackedInt32Array, g: Bend, h: Bend) -> Bend:
	if g.b + 1 != h.a or signf(g.theta) != signf(h.theta):
		return null
	var rg := minf(g.most, (g.ta + g.leg_in) / g.tn)
	var rh := minf(h.most, (h.tb + h.leg_out) / h.tn)
	if rg * g.tn + rh * h.tn <= g.tb + g.leg_out + h.ta:
		return null
	var apart := _share(g, h, rg, rh)
	var one := _bend(raw, line, g.a, h.b)
	if not one.ok:
		return null
	var r := one.alone()
	if r < one.least or r <= minf(apart.x, apart.y):
		return null
	one.r = r - minf(apart.x, apart.y)
	return one


## The points of stretch st: the simplified line with each bend's arc in its place.
func _emit(st: Stretch, raw: Raw, line: PackedInt32Array, bends: Array[Bend]) -> void:
	st.pt.append(raw.p[line[0]])
	st.gm.append(0.0)
	st.fix.append(INF)
	var i := 1
	var k := 0
	while i < line.size():
		if k < bends.size() and bends[k].a == i:
			var bd := bends[k]
			k += 1
			st.arcs.append(bd.r)
			st.arcs.append(bd.theta)
			st.arcs.append(bd.least)
			if bd.r >= RADIUS_LEAST:
				var t := bd.reach()
				var centre := bd.at + (bd.d_out - bd.d_in).normalized() * (bd.r * bd.sec)
				var start := bd.at - bd.d_in * t
				_line_to(st, start, 1.0, INF)
				var steps := maxi(maxi(ceili(bd.r * absf(bd.theta) / ARC_STEP), ceili(absf(bd.theta) / ARC_ANGLE)), 2)
				var radial := (start - centre) / bd.r
				# (An arc tighter than a car turns is driven as the arc it can turn, like the lane graph's curves.)
				var pace := maxf(TURN_RADIUS / bd.r, 1.0)
				for q in range(1, steps + 1):
					_point(st, centre + radial.rotated(bd.theta * q / steps) * bd.r, pace, INF)
			else:
				for q in range(bd.a, bd.b + 1):
					_line_to(st, raw.p[line[q]], 1.0, INF)
			i = bd.b + 1
		else:
			var before := line[i - 1]
			_line_to(st, raw.p[line[i]], raw.pace[before], raw.fix[before] if raw.rigid[before] == 1 and raw.rigid[line[i]] == 1 else INF)
			i += 1


## A straight of stretch st from its last point to `to`, a point every LINE_STEP m.
func _line_to(st: Stretch, to: Vector2, pace: float, fix: float) -> void:
	var from := st.pt[st.pt.size() - 1]
	var steps := maxi(ceili(from.distance_to(to) / LINE_STEP), 1)
	for q in range(1, steps + 1):
		_point(st, from.lerp(to, float(q) / steps), pace, fix)


func _point(st: Stretch, at: Vector2, pace: float, fix: float) -> void:
	var n := st.pt.size()
	var step := st.pt[n - 1].distance_to(at)
	if fix < INF:
		st.fix[n - 1] = minf(st.fix[n - 1], fix)
	if step < 0.02:
		return
	if n >= 2 and fix == INF and (at - st.pt[n - 1]).dot(st.pt[n - 1] - st.pt[n - 2]) < 0.0:
		st.backs += 1
	st.pt.append(at)
	st.gm.append(st.gm[n - 1] + step * pace)
	st.fix.append(fix)


## The logical metres at each point of a stretch's line `pt`: every point of `raw` keeps its own
## where the line passes it (the nearest place of the line, found going forward only), and
## between two such places they run evenly.
func _logical(raw: Raw, pt: PackedVector2Array) -> PackedFloat32Array:
	var n := pt.size()
	var ground := PackedFloat32Array()
	ground.resize(n)
	for i in range(1, n):
		ground[i] = ground[i - 1] + pt[i].distance_to(pt[i - 1])
	var at_g := PackedFloat32Array([0.0])
	var at_x := PackedFloat32Array([raw.x[0]])
	var seg := 0
	var last := raw.p.size() - 1
	for k in range(1, last):
		var q := raw.p[k]
		var reach := q.distance_to(raw.p[k - 1]) + 6.0
		var from: float = at_g[at_g.size() - 1]
		var best := INF
		var best_g := from
		var best_seg := seg
		var j := seg
		while j < n - 1 and ground[j] - from <= reach:
			var pa := pt[j]
			var ab := pt[j + 1] - pa
			var l2 := ab.length_squared()
			var t := clampf((q - pa).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
			var d2 := q.distance_squared_to(pa + ab * t)
			var gg := ground[j] + t * sqrt(l2)
			if d2 < best - 0.000001 and gg >= from:
				best = d2
				best_g = gg
				best_seg = j
			j += 1
		seg = best_seg
		if best_g - from >= 0.25 and ground[n - 1] - best_g >= 0.25 and raw.x[k] - at_x[at_x.size() - 1] > 0.01:
			at_g.append(best_g)
			at_x.append(raw.x[k])
	at_g.append(ground[n - 1])
	at_x.append(raw.x[last])
	var out := PackedFloat32Array()
	out.resize(n)
	var m := 0
	for i in n:
		while m < at_g.size() - 2 and ground[i] > at_g[m + 1]:
			m += 1
		var span := at_g[m + 1] - at_g[m]
		out[i] = lerpf(at_x[m], at_x[m + 1], clampf((ground[i] - at_g[m]) / span, 0.0, 1.0) if span > 0.0001 else 1.0)
	return out
