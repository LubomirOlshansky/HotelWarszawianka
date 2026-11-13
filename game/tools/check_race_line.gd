extends SceneTree
## The racing line (race_line.gd; docs/design/race-ai.md 5.2), checked over the whole committed
## map without a race:
## - no rival's grip, at its hardest effort or on a mistake, is over the player's own car's;
## - every run of streets from the cut of one long street to the cut of the next, in each lane
##   (the stretches the game builds), gives a line that stays in its lane: no further beside the
##   lane's own line than the lane's free side and OFF_LANE m, no further off a junction's curve
##   than the junction's room, its logical metres rising, with no more steps back on itself than
##   the lane graph's own tiny curves give it (BACKS, counted on purpose) and no more arcs tighter
##   than their room asks (TIGHT);
## - a racer's way of several stretches (race_line.gd `path`) joins without a step or a kink, its
##   right-hand side (`side`) has length one, and a metre beside it is shorter inside a bend and
##   longer outside (`beside`): what keeps a car that passes beside its line from stuttering;
## - the speeds a racer gets (`speeds`) pass no point faster than its turn allows and are braked
##   for in time, a racer of less grip is nowhere the faster, and a mistake's stretch is faster
##   but held by the car's own grip;
## - driving the way on by `advance` comes to its end in its driven metres.
##   godot --headless --path game --script res://tools/check_race_line.gd
## Prints "race_line: OK (...)" or the problems (exit 1).

const RaceBench := preload("res://tools/race_bench.gd")
const RaceLine := preload("res://scripts/race_line.gd")
const Traffic := preload("res://scripts/traffic.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Ladder := preload("res://scripts/ladder.gd")

## The slack beside a lane's free side (m): the lane's line is a row of points, the racing line
## an arc past them.
const OFF_LANE := 0.35
## Counted on purpose (2026-11-12): the steps back the lane graph's own curves give the line
## where a junction is a knot of 1 m streets (Łazienkowska at Solec, Wybrzeże Szczecińskie), and
## the arcs that came out tighter than their room asks. A change that adds to either says why.
const BACKS := 11
const TIGHT := 1
## The longest run of streets followed from one long street to the next.
const CHAIN := 8
## A way of several stretches for the path checks: how many long streets it runs.
const WAY := 7
## The racers the speeds are checked for: grip and brakes (m/s²).
const SLOW := Vector2(9.5, 4.0)
const FAST := Vector2(16.5, 13.0)

var _bench: RaceBench
var _graph: LaneGraph
var _line: RaceLine
var _problems := 0
var _notes := PackedStringArray()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_bench = RaceBench.new()
	if not _bench.open(root):
		# A clone without the map data: no streets to draw a line on (as check_race_bench.gd).
		print("race_line: OK (skipped: %s)" % _bench.error)
		quit(0)
		return
	_graph = _bench.graph
	_line = RaceLine.new(_graph)
	_constants()
	_map()
	_way()
	_bench.close()
	if _problems == 0:
		print("race_line: OK (%s)" % " · ".join(_notes))
		quit(0)
	else:
		print("race_line: %d problem(s)" % _problems)
		quit(1)


## The honest car: a racer at its line's speed pulls no more sideways than a car of the player's
## grip holds, at its hardest effort (traffic.gd GRIP_EFFORT_MOST) and on a mistake
## (RACE_GRIP_MOST) too.
func _constants() -> void:
	_expect(Traffic.RACE_GRIP_MOST <= RaceBench.PLAYER_GRIP, "a mistake is held by the player's car's grip at most (%.1f, %.1f m/s²)" % [Traffic.RACE_GRIP_MOST, RaceBench.PLAYER_GRIP])
	var hardest := float(Ladder.FIRST_RACER["lat"])
	for rung in range(-1, Ladder.FINAL + 1):
		hardest = maxf(hardest, float(Ladder.racer(rung)["lat"]))
	hardest *= Traffic.GRIP_EFFORT_MOST
	_expect(hardest <= RaceBench.PLAYER_GRIP, "no racer's grip at its hardest effort is over the player's car's (%.2f, %.1f m/s²)" % [hardest, RaceBench.PLAYER_GRIP])
	_notes.append("the hardest racer's grip %.1f m/s² of the car's %.0f" % [hardest, RaceBench.PLAYER_GRIP])


## The runs of streets from long street e on: through short ones to the next long one.
func _chains(e: int) -> Array:
	var out: Array = []
	var stack: Array = [PackedInt32Array([e])]
	while not stack.is_empty():
		var chain: PackedInt32Array = stack.pop_back()
		var at := chain[chain.size() - 1]
		if _graph.e_shut[at] < INF:
			continue
		for f in _graph.node_out[_graph.e_b[at]]:
			var next := chain.duplicate()
			next.append(f)
			if _line.is_long(f) or next.size() > CHAIN:
				out.append(next)
			elif not chain.has(f):
				stack.append(next)
	return out


## How far the line of stretch st leaves the lane graph's way: {lane: the most metres beside a
## lane's line beyond the lane's free side, junction: the most off a junction's curve, back: steps
## back on itself, flat: points whose logical metres do not rise}.
func _measure(st: RaceLine.Stretch) -> Dictionary:
	var g := _graph
	var edges := st.edges
	var n := edges.size()
	# The lane graph's way: its points, their logical metres and the room there (-1: a junction).
	var rp := PackedVector2Array()
	var rx := PackedFloat32Array()
	var rh := PackedFloat32Array()
	for i in n:
		var e := edges[i]
		var a := st.from if i == 0 else g.e_s0[e]
		var z := st.to if i == n - 1 else g.e_s1[e]
		var off := g.lane_offset(e, st.lanes[i])
		var h := _line.free_side(e)
		var inner := i > 0 and i < n - 1 and z - a < RaceLine.INSIDE
		var stations := PackedFloat32Array([a])
		for k in range(1, g.e_count[e] - 1):
			var sv := g.cum[g.e_first[e] + k]
			if sv > a + 0.01 and sv < z - 0.01:
				stations.append(sv)
		stations.append(z)
		for s in stations:
			rp.append(g.point_at(e, s, off))
			rx.append(st.xs[i] + s)
			rh.append(-1.0 if inner else h)
		if i < n - 1:
			var c := g.connector(e, st.lanes[i], edges[i + 1], st.lanes[i + 1])
			var cl := LaneGraph.bezier_length(c)
			for k in range(1, 12):
				rp.append(LaneGraph.bezier(c, k / 12.0))
				rx.append(st.xc[i] + cl * k / 12.0)
				rh.append(-1.0)
	var out := {"lane": 0.0, "junction": 0.0, "back": 0, "flat": 0}
	var j := 0
	for i in st.pt.size():
		if i > 0 and st.xl[i] < st.xl[i - 1]:
			out["flat"] += 1
		if i >= 2 and st.fix[i] == INF and absf((st.pt[i - 1] - st.pt[i - 2]).angle_to(st.pt[i] - st.pt[i - 1])) > RaceLine.HAIRPIN:
			out["back"] += 1
		var x := st.xl[i]
		while j < rx.size() - 2 and rx[j + 1] < x - 10.0:
			j += 1
		var best := INF
		var best_h := 0.0
		var k := j
		while k < rx.size() - 1 and rx[k] <= x + 10.0:
			var pa := rp[k]
			var ab := rp[k + 1] - pa
			var l2 := ab.length_squared()
			var t := clampf((st.pt[i] - pa).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
			var d := st.pt[i].distance_to(pa + ab * t)
			if d < best:
				best = d
				best_h = rh[k] if t < 0.5 else rh[k + 1]
			k += 1
		if best == INF:
			continue
		if best_h < 0.0:
			out["junction"] = maxf(out["junction"], best)
		else:
			out["lane"] = maxf(out["lane"], best - best_h)
	return out


## Every stretch the game can build between two long streets, in every lane.
func _map() -> void:
	var g := _graph
	var count := 0
	var off_lane := 0
	var worst_lane := 0.0
	var worst_junction := 0.0
	var backs := 0
	var flats := 0
	var tight := 0
	var arcs := 0
	var plain := 0
	var shown := 0
	for e in g.e_a.size():
		if g.e_cf[e] != 0 or not _line.is_long(e) or g.node_scc[g.e_b[e]] == 0 or g.node_scc[g.e_a[e]] == 0:
			continue
		for chain: PackedInt32Array in _chains(e):
			var end := chain[chain.size() - 1]
			if not _line.is_long(end):
				continue
			for lane in g.e_lanes[e]:
				var st := _line.stretch(chain, _line.lanes_of(chain, lane), _line.split(e), _line.split(end))
				count += 1
				if st.plain:
					plain += 1
				var m := _measure(st)
				backs += int(m["back"])
				flats += int(m["flat"])
				worst_lane = maxf(worst_lane, float(m["lane"]))
				worst_junction = maxf(worst_junction, float(m["junction"]))
				for w in range(0, st.arcs.size(), 3):
					arcs += 1
					if st.arcs[w + 2] > st.arcs[w] + 0.01:
						tight += 1
				if float(m["lane"]) > OFF_LANE or float(m["junction"]) > RaceLine.JUNCTION_OUT + 0.1 or int(m["flat"]) > 0:
					off_lane += 1
					if shown < 8:
						shown += 1
						var names := PackedStringArray()
						for f in chain:
							names.append("%s e%d" % [g.e_name[f], f])
						print("  a line off its way: %.2f m beside its lane's room, %.2f m off a junction's curve, %d points not rising, from lane %d: %s" % [
								m["lane"], m["junction"], m["flat"], lane, " > ".join(names)])
	_expect(count > 5000, "the map gives stretches to check (%d)" % count)
	_expect(off_lane == 0, "every line stays in its lane and its junctions' room, its metres rising (%d of %d do not; the worst %.2f m beside a lane's room, %.2f m off a junction's curve, %d points not rising)" % [
			off_lane, count, worst_lane, worst_junction, flats])
	_expect(backs <= BACKS, "no more steps back than the lane graph's own curves give (%d, known %d)" % [backs, BACKS])
	_expect(tight <= TIGHT, "no more arcs tighter than their room asks (%d of %d, known %d)" % [tight, arcs, TIGHT])
	_notes.append("%d stretches in every lane: %.2f m beside a lane's room at most, %.2f m off a junction's curve, %d steps back, %d arcs (%d tight), %d as the lane graph has them" % [
			count, worst_lane, worst_junction, backs, arcs, tight, plain])
	_notes.append("built in %.2f ms each, %.1f ms the slowest" % [_line.built_usec / 1000.0 / maxf(_line.built, 1), _line.built_most / 1000.0])


## A racer's way of several stretches: from the first long street WAY long streets on, always
## the first run of streets the map offers.
func _way() -> void:
	var g := _graph
	var edges := PackedInt32Array()
	for e in g.e_a.size():
		if g.e_cf[e] != 0 or not _line.is_long(e) or g.node_scc[g.e_b[e]] == 0 or g.node_scc[g.e_a[e]] == 0:
			continue
		edges = PackedInt32Array([e])
		var at := e
		for hop in WAY:
			var next := PackedInt32Array()
			for chain: PackedInt32Array in _chains(at):
				var end := chain[chain.size() - 1]
				if _line.is_long(end) and not edges.has(end):
					next = chain
					break
			if next.is_empty():
				break
			edges.append_array(next.slice(1))
			at = next[next.size() - 1]
		if edges.size() >= WAY:
			break
	_expect(edges.size() >= WAY, "the map gives a way of several long streets (%d streets)" % edges.size())
	if edges.size() < WAY:
		return
	var last := edges[edges.size() - 1]
	var p := _line.path(edges, _line.lanes_of(edges, 0), g.e_s0[edges[0]] + 1.0, g.e_s1[last] - 1.0)
	var n := p.pt.size()
	_expect(p.part_i.size() >= 3 and n > 20, "the way is cut into stretches (%d, %d points)" % [p.part_i.size(), n])
	# The joins: one point each, the line straight through it; the metres rise along the way.
	var kink := 0.0
	for k in range(1, p.part_i.size()):
		var i := p.part_i[k]
		if i > 0 and i < n - 1:
			kink = maxf(kink, absf((p.pt[i] - p.pt[i - 1]).angle_to(p.pt[i + 1] - p.pt[i])))
	_expect(kink < 0.05, "the stretches join without a kink (%.3f rad at the worst join)" % kink)
	var falls := 0
	var side_off := 0.0
	for i in range(1, n):
		if p.xl[i] < p.xl[i - 1] or p.gm[i] < p.gm[i - 1]:
			falls += 1
	for i in n:
		side_off = maxf(side_off, absf(p.nr[i].length() - 1.0))
	_expect(falls == 0, "the way's metres rise from point to point (%d fall)" % falls)
	_expect(side_off < 0.001, "the line's right-hand side has length one at every point (off by %.4f)" % side_off)
	# Beside the line: inside its sharpest bend a metre is shorter, outside it longer, and a car
	# held a lane's width beside it moves without a step from piece to piece.
	var sharp := 0
	for i in n - 1:
		if absf(p.bend[i]) > absf(p.bend[sharp]):
			sharp = i
	var inside := 1.0 if p.bend[sharp] < 0.0 else -1.0
	_expect(p.beside(sharp, inside) < 1.0 and p.beside(sharp, -inside) > 1.0, "a metre beside the sharpest bend is shorter inside it and longer outside (%.2f, %.2f)" % [
			p.beside(sharp, inside), p.beside(sharp, -inside)])
	var step := 0.0
	for i in range(1, n - 1):
		var x := p.xl[i]
		var before := p.point(x, i - 1) + p.side(x, i - 1) * 3.0
		var after := p.point(x, i) + p.side(x, i) * 3.0
		step = maxf(step, before.distance_to(after))
	_expect(step < 0.001, "a car 3 m beside the line has no step where two pieces meet (%.4f m)" % step)
	# The speeds: never past a point's turn, braked for in time, the racer of less grip nowhere
	# the faster, a mistake faster but within the car's grip.
	_line.speeds(p, SLOW.x, SLOW.y)
	var slow := p.v.duplicate()
	_line.speeds(p, FAST.x, FAST.y)
	var fast := p.v.duplicate()
	var over := 0
	var late := 0
	var order := 0
	for i in n:
		if slow[i] > RaceLine.cap(SLOW.x, p.turn[i]) + 0.001 or fast[i] > RaceLine.cap(FAST.x, p.turn[i]) + 0.001 or fast[i] > p.fix[i] + 0.001:
			over += 1
		if slow[i] > fast[i] + 0.001:
			order += 1
		if i < n - 1:
			var room := p.gm[i + 1] - p.gm[i]
			if slow[i] > sqrt(slow[i + 1] * slow[i + 1] + 2.0 * SLOW.y * room) + 0.001 \
					or fast[i] > sqrt(fast[i + 1] * fast[i + 1] + 2.0 * FAST.y * room) + 0.001:
				late += 1
	_expect(over == 0, "no point is passed faster than its turn allows (%d are)" % over)
	_expect(late == 0, "every bend is braked for in time (%d points are not)" % late)
	_expect(order == 0, "the racer of less grip is nowhere the faster (%d points)" % order)
	var from := p.xl[sharp] - Traffic.LINE_FAST
	var to := p.xl[sharp] + Traffic.LINE_FAST
	_line.speeds(p, SLOW.x, SLOW.y, from, to, Traffic.MISTAKE_FAST, Traffic.RACE_GRIP_MOST)
	var quicker := 0
	var held := 0
	for i in n:
		if p.xl[i] >= from and p.xl[i] <= to:
			if p.v[i] > slow[i] + 0.001:
				quicker += 1
			if p.v[i] > RaceLine.cap(Traffic.RACE_GRIP_MOST, p.turn[i]) + 0.001:
				held += 1
	_expect(quicker > 0 and held == 0, "a mistake is faster round its bend, within the car's grip (%d points faster, %d past the grip)" % [quicker, held])
	# Driving it: the driven metres of the whole way bring `advance` to its end.
	var x_end := p.advance(p.xl[0], 0, p.gm[n - 1] - p.gm[0])
	_expect(absf(p.xl[0] + x_end - p.xl[n - 1]) < 0.01, "driving its driven metres comes to its end (%.2f m of %.2f)" % [p.xl[0] + x_end, p.xl[n - 1]])
	var least_slow := INF
	var least_fast := INF
	for i in n:
		least_slow = minf(least_slow, slow[i])
		least_fast = minf(least_fast, fast[i])
	_notes.append("a way of %d streets in %d stretches joins within %.3f rad, its sharpest bend of %.0f m radius; its slowest place at %.0f km/h for a grip of %.1f m/s², %.0f for %.1f" % [
			edges.size(), p.part_i.size(), kink, 1.0 / maxf(absf(p.bend[sharp]), 0.001), least_slow * 3.6, SLOW.x, least_fast * 3.6, FAST.x])
