extends Node3D
## Warsaw trams on the baked tracks (Marszałkowska, Jerozolimskie, Świętokrzyska,
## Most Poniatowskiego): three-car articulated trams in yellow and red that follow
## the rails, stop about ten seconds at the platforms, wait at red lights (the same
## lights as the cars running alongside), keep apart, and brake for the player's
## car on the track. Track pieces are OpenStreetMap ways drawn in the direction of
## travel; a tram that runs off the map slides out under its edge and comes back in
## where another track enters.
## The fleet (2026-11-06, tram_fleet.gd): the eight trams come in four looks (FLEET), today's
## yellow tram, the newest one with the smiling face and the old boxy pair in its first and
## rebuilt face; a pair is two longer cars (its third body hidden), so it draws one car fewer.

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Models := preload("res://scripts/models.gd")
const Fleet := preload("res://scripts/tram_fleet.gd")

const COUNT := 8
const CAR := 10.5
const JOINT := 0.7
const LENGTH := 3.0 * CAR + 2.0 * JOINT
const CRUISE := 11.0
const ACCEL := 1.1
const DECEL := 1.6
const DWELL := 10.0
const HEIGHT_STEP := 8.0
## The traffic loop (2026-10-30): a tram stops for a traffic car whose box reaches into its
## swept width (half its 2.4 m body + CLEAR m), not only for a car centred on the rails (a car
## standing across the track with its nose or tail on the rails was driven into), and stops
## STOP_SHORT m before the first point of the rails that comes that close.
const HALF_WIDTH := 1.2
const CLEAR := 0.4
const STOP_SHORT := 1.5
## The rails ahead are followed in AHEAD_STEP m steps to AHEAD_REACH m (round the curve, not on
## the head's straight line: a car waiting inside a curve was missed); SWEEP m more for the
## straight car bodies cutting inside a curve.
const AHEAD_STEP := 2.0
const AHEAD_REACH := 30.0
const SWEEP := 0.5
## A car running alongside counts from ON_RAILS m off the tram's side (a lane beside the rails is
## not in the way; a car on them, or a junction curve slanting across, is).
const ON_RAILS := 0.3
## Each tram's look, by its index (tram 0 is the first scene's tram passing the car: the newest;
## tram 1 coming down Marszałkowska towards it: the old pair). About the city's mix: the newest
## and today's yellow ones most, two old pairs.
const FLEET: Array[int] = [Fleet.Kind.SMILE, Fleet.Kind.PAIR, Fleet.Kind.CLASSIC, Fleet.Kind.SMILE,
		Fleet.Kind.PAIR_NEW, Fleet.Kind.CLASSIC, Fleet.Kind.SMILE, Fleet.Kind.CLASSIC]


class Tram:
	## Pieces it is on, oldest first; the last one holds the head.
	var trail := PackedInt32Array()
	var s := 0.0
	var v := 0.0
	var next := -1
	var dwell := 0.0
	var served := -1
	var bell_wait := 0.0
	var cars: Array[AnimatableBody3D] = []
	var pos := Vector3.ZERO
	## This frame's heading and points along its body, for the other trams' checks.
	var dir := Vector2.UP
	var mid := Vector2.ZERO
	var rear := Vector2.ZERO
	## The vintage-tram loop (old_tram.gd): this tram runs as the old two-car set (its cars
	## beyond `n_cars` hidden, its cruise `cruise`), and rings the old bell.
	var vintage := false
	var n_cars := 3
	var cruise := CRUISE
	## Its look (tram_fleet.gd Kind), its cars' length and the gap between them.
	var kind := 0
	var car_len := CAR
	var joint := JOINT
	## The head-lamp cones (on the first car) and the red glow behind the last car.
	var cones: MeshInstance3D
	var tail: MeshInstance3D


## v0.9: the bell, as a tram leaves a stop or brakes for the player's car on its track.
signal bell(at: Vector3)
## The vintage-tram loop: the old tram's bell instead (its own two-tone hand bell).
signal old_bell(at: Vector3)

var graph: LaneGraph
var map: Node3D
## The traffic (traffic.gd): a tram stops for a car already crossing its track.
var traffic: Node3D
var player_pos := Vector3.ZERO
var player_on_road := true
var trams: Array[Tram] = []
## How long the last update took, for --bench.
var last_usec := 0
## The vintage-tram loop: the last update's view centre and reach (a tram farther than this is
## not posed: out of sight).
var view_at := Vector2.ZERO
var view_reach := 600.0

var _pts: Array[PackedVector2Array] = []
var _cum: Array[PackedFloat32Array] = []
var _len := PackedFloat32Array()
var _succ: Array[PackedInt32Array] = []
var _pred: Array[PackedInt32Array] = []
## Per piece, flat [s, kind (0 platform, 1 light), controller, group, id, ...].
var _halts: Array[PackedFloat32Array] = []
var _heights: Array[PackedFloat32Array] = []
## The bridge deck each track piece lies on (-1: the ground), from the bake.
var _deck := PackedInt32Array()
var _rng := RandomNumberGenerator.new()
## The traffic loop: the rails ahead of the tram being moved, every AHEAD_STEP m (kept, not
## reallocated each frame).
var _ahead := PackedVector2Array()


func setup(lane_graph: LaneGraph, map_node: Node3D, data: Dictionary) -> void:
	graph = lane_graph
	map = map_node
	_rng.seed = 1908
	for t in data.get("trams", []):
		var flat: Array = t["p"]
		var p := PackedVector2Array()
		var c := PackedFloat32Array()
		var run := 0.0
		for i in range(0, flat.size() - 1, 2):
			var q := Vector2(flat[i], flat[i + 1])
			if not p.is_empty():
				run += q.distance_to(p[p.size() - 1])
			p.append(q)
			c.append(run)
		_pts.append(p)
		_cum.append(c)
		_len.append(run)
		_deck.append(int(t.get("dk", -1)))
		_succ.append(PackedInt32Array())
		_pred.append(PackedInt32Array())
		_halts.append(PackedFloat32Array())
		_heights.append(PackedFloat32Array())
	for i in _pts.size():
		var end := _pts[i][_pts[i].size() - 1]
		var out := _dir(i, _len[i])
		for j in _pts.size():
			if j != i and _pts[j][0].distance_to(end) < 0.6 and absf(out.angle_to(_dir(j, 0.0))) < 1.2:
				_succ[i].append(j)
				_pred[j].append(i)
	_find_halts(data)
	# Night: headlight cones ahead of the first car, a red glow behind the last.
	var cones := Models.headlight_pools(CAR * 0.5 + 0.2, 0.75, 16.0, false)
	var taken := PackedVector2Array()
	for n in COUNT:
		var tram := Tram.new()
		tram.kind = FLEET[n % FLEET.size()]
		for k in 3:
			var body := AnimatableBody3D.new()
			body.sync_to_physics = false
			body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			var mi := MeshInstance3D.new()
			mi.material_override = Models.material()
			body.add_child(mi)
			if k != 1:
				var glow := MeshInstance3D.new()
				glow.mesh = cones if k == 0 else _tail_glow()
				glow.material_override = Models.glow_material()
				glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				glow.visible = false
				glow.add_to_group("night_lights")
				body.add_child(glow)
				if k == 0:
					tram.cones = glow
				else:
					tram.tail = glow
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.4, 3.4, CAR)
			shape.shape = box
			shape.position.y = 1.8
			body.add_child(shape)
			add_child(body)
			tram.cars.append(body)
		_dress(tram, _kind_look(tram.kind))
		_place_new(tram, taken)
		trams.append(tram)


## A red glow on the rails behind the last car (its back is at +Z).
func _tail_glow() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(0.0, 0.15, CAR * 0.5 + 1.2)
	var n := 12
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		for v in [[c, 0.3], [c + Vector3(cos(a0) * 2.0, 0.0, sin(a0) * 1.6), 0.0], [c + Vector3(cos(a1) * 2.0, 0.0, sin(a1) * 1.6), 0.0]]:
			st.set_color(Color(1.0, 0.08, 0.05, v[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	return st.commit()


func _dir(i: int, s: float) -> Vector2:
	var p := _pts[i]
	var k := _seek(i, s)
	return (p[k + 1] - p[k]).normalized()


func _seek(i: int, s: float) -> int:
	var c := _cum[i]
	var k := 0
	while k < c.size() - 2 and c[k + 1] < s:
		k += 1
	return k


## A point s along piece i; beyond either end it carries on in a straight line.
func _point(i: int, s: float) -> Vector2:
	var p := _pts[i]
	if s <= 0.0:
		return p[0] + _dir(i, 0.0) * s
	if s >= _len[i]:
		return p[p.size() - 1] + _dir(i, _len[i]) * (s - _len[i])
	var k := _seek(i, s)
	var c := _cum[i]
	var seg := c[k + 1] - c[k]
	return p[k].lerp(p[k + 1], (s - c[k]) / seg if seg > 0.0001 else 0.0)


## Rail height (on its bridge deck, like the rails the city draws), sampled
## once per piece the first time a tram uses it.
func _height(i: int, s: float) -> float:
	var h := _heights[i]
	if h.is_empty():
		var n := ceili(_len[i] / HEIGHT_STEP) + 2
		h.resize(n)
		for k in n:
			var q := _point(i, minf(k * HEIGHT_STEP, _len[i]))
			h[k] = map.deck_height(_deck[i], q.x, q.y)
		_heights[i] = h
	var f := clampf(s / HEIGHT_STEP, 0.0, h.size() - 1.0001)
	return lerpf(h[int(f)], h[int(f) + 1], f - int(f))


## Platforms within a few metres of a track become stops; a car stop line on a road
## running alongside (same direction, within 14 m) becomes the tram's stop line too.
func _find_halts(data: Dictionary) -> void:
	var halt_id := 0
	for plat in data.get("platforms", []):
		var flat: Array = plat["p"]
		var centre := Vector2.ZERO
		for k in range(0, flat.size() - 1, 2):
			centre += Vector2(flat[k], flat[k + 1])
		centre /= flat.size() / 2.0
		for i in _pts.size():
			var near := _project(i, centre)
			if near.y < 7.5 and _len[i] > 20.0:
				var at := clampf(near.x + LENGTH * 0.5, minf(LENGTH, _len[i] - 1.0), _len[i] - 1.0)
				# Platforms on both sides of a stop are one stop (else the tram would
				# stop at each in turn, forever).
				var same := false
				for k in range(0, _halts[i].size(), 5):
					same = same or absf(_halts[i][k] - at) < 20.0
				if not same:
					_halts[i].append_array(PackedFloat32Array([at, 0.0, -1.0, 0.0, halt_id]))
					halt_id += 1
	for e in graph.e_a.size():
		var stops := graph.e_stops[e]
		for k in range(0, stops.size(), 3):
			var p := graph.point_at(e, stops[k])
			var d := graph.direction(e, stops[k])
			for i in _pts.size():
				var near := _project(i, p)
				if near.y < 14.0 and _dir(i, near.x).dot(d) > 0.85 and near.x > 1.0 and near.x < _len[i] - 0.5:
					_halts[i].append_array(PackedFloat32Array([near.x, 1.0, stops[k + 1], stops[k + 2], halt_id]))
					halt_id += 1
	for i in _halts.size():
		_halts[i] = _sorted(_halts[i])


## (s along piece i of the point nearest p, distance to it).
func _project(i: int, p: Vector2) -> Vector2:
	var best := Vector2(0.0, INF)
	var pts := _pts[i]
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.0001:
			continue
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best.y:
			best = Vector2(_cum[i][k] + t * sqrt(l2), d)
	return best


static func _sorted(flat: PackedFloat32Array) -> PackedFloat32Array:
	var rows := []
	for k in range(0, flat.size(), 5):
		rows.append(flat.slice(k, k + 5))
	rows.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	var out := PackedFloat32Array()
	for r in rows:
		out.append_array(r)
	return out


## A spot on a long piece away from the other trams, with a trail of pieces behind.
func _place_new(tram: Tram, taken: PackedVector2Array) -> void:
	for attempt in 60:
		var i := _rng.randi() % _pts.size()
		if _len[i] < 60.0:
			continue
		var s := _rng.randf_range(LENGTH, _len[i] - 5.0)
		var p := _point(i, s)
		var free := true
		for q in taken:
			if q.distance_to(p) < 150.0:
				free = false
		if not free and attempt < 50:
			continue
		taken.append(p)
		tram.trail = PackedInt32Array([i])
		var back := s
		while back < LENGTH + 5.0 and not _pred[tram.trail[0]].is_empty():
			var prev := _pred[tram.trail[0]][0]
			tram.trail.insert(0, prev)
			back += _len[prev]
		tram.s = s
		tram.v = CRUISE * 0.7
		tram.next = _pick_next(i)
		return


func _pick_next(i: int) -> int:
	var options := _succ[i]
	return options[_rng.randi() % options.size()] if not options.is_empty() else -1


func _head(tram: Tram) -> int:
	return tram.trail[tram.trail.size() - 1]


func _process(dt: float) -> void:
	if dt <= 0.0 or _pts.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	for tram in trams:
		var head := _head(tram)
		var length := length_of(tram)
		tram.dir = _dir(head, clampf(tram.s, 0.0, _len[head]))
		tram.mid = _back_point(tram, length * 0.5)
		tram.rear = _back_point(tram, length)
	for tram in trams:
		_move(tram, dt)
	_greet_step(dt)
	# Only trams that could be seen get their cars placed (moving physics bodies
	# costs more than the rest); the others just keep track of their head.
	var centre := Vector2(player_pos.x, player_pos.z)
	var reach := 600.0
	if traffic != null:
		centre = traffic.view_centre
		reach = maxf(traffic.view_half.x, traffic.view_half.y) * 1.5 + 120.0
	view_at = centre
	view_reach = reach
	for tram in trams:
		var head := _back_point(tram, 0.0)
		if head.distance_to(centre) < reach:
			_pose(tram)
		else:
			tram.pos = Vector3(head.x, tram.pos.y, head.y)
			for body in tram.cars:
				body.collision_layer = 0
	last_usec = Time.get_ticks_usec() - t0


func _move(tram: Tram, dt: float) -> void:
	var head := _head(tram)
	var gap := INF
	# Stops and lights on this piece and the next.
	for pass_ in 2:
		var piece := head if pass_ == 0 else tram.next
		if piece < 0 or gap < INF:
			break
		var offset := 0.0 if pass_ == 0 else _len[head] - tram.s
		var halts := _halts[piece]
		for k in range(0, halts.size(), 5):
			var ahead := halts[k] - (tram.s if pass_ == 0 else 0.0) + offset
			if ahead < -0.3:
				continue
			if halts[k + 1] == 0.0:
				if int(halts[k + 4]) == tram.served:
					continue
			elif graph.light(int(halts[k + 2]), int(halts[k + 3])) == LaneGraph.GREEN:
				continue
			gap = ahead
			if halts[k + 1] == 0.0 and ahead < 0.6 and tram.v < 0.3:
				tram.dwell += dt
				if tram.dwell > DWELL:
					tram.served = int(halts[k + 4])
					tram.dwell = 0.0
					_ring(tram)
			break
	# Other trams ahead and the player's car on the track.
	var fwd := tram.dir
	var here := Vector2(tram.pos.x, tram.pos.z)
	for other in trams:
		# Only trams going our way: one coming the other way on a crossover would
		# otherwise stop both for good.
		if other == tram or other.dir.dot(fwd) < 0.3:
			continue
		for q in [other.rear, other.mid]:
			var rel: Vector2 = q - here
			var along := rel.dot(fwd)
			if along > 0.0 and along < 60.0 and absf(rel.cross(fwd)) < 2.0:
				gap = minf(gap, along - 3.0)
	if traffic != null and not traffic.junction_cars.is_empty():
		_ahead.clear()
		var a := 0.0
		while a <= AHEAD_REACH:
			_ahead.append(_ahead_point(tram, head, a))
			a += AHEAD_STEP
		var reach := HALF_WIDTH + CLEAR + SWEEP
		for d in traffic.junction_cars:
			var at := Vector2(d.pos.x, d.pos.z)
			if at.distance_squared_to(here) > (AHEAD_REACH + 8.0) * (AHEAD_REACH + 8.0):
				continue
			var df := Vector2(-sin(d.yaw), -cos(d.yaw))
			var dr := Vector2(-df.y, df.x)
			for k in _ahead.size():
				var q := _ahead[k] - at
				# The rails' distance from the car's box.
				var out := Vector2(maxf(absf(q.dot(dr)) - d.size.x * 0.5, 0.0), maxf(absf(q.dot(df)) - d.length * 0.5, 0.0))
				if out.length_squared() >= reach * reach:
					continue
				# A car alongside the rails (queueing next to them, or on a curve that runs with
				# them) stops us only if its box is on them; one crossing them, inside the swept width.
				var way := _ahead[mini(k + 1, _ahead.size() - 1)] - _ahead[maxi(k - 1, 0)]
				if absf(df.dot(way.normalized())) >= 0.75 and out.length() >= HALF_WIDTH + ON_RAILS:
					continue
				gap = minf(gap, k * AHEAD_STEP - STOP_SHORT)
				break
	if player_on_road:
		var rel := Vector2(player_pos.x, player_pos.z) - here
		var along := rel.dot(fwd)
		if along > 0.0 and along < 40.0 and absf(rel.cross(fwd)) < 2.6:
			gap = minf(gap, along - 4.0)
			if tram.bell_wait <= 0.0 and along < 30.0 and tram.v > 2.0:
				tram.bell_wait = 8.0
				_ring(tram)
	tram.bell_wait -= dt
	var want := tram.cruise
	if gap < INF:
		want = minf(want, sqrt(maxf(gap - 0.3, 0.0) * 2.0 * DECEL))
	if tram.v < want:
		tram.v = minf(want, tram.v + ACCEL * dt)
	else:
		tram.v = maxf(want, tram.v - DECEL * 2.5 * dt)
	tram.s += tram.v * dt
	if tram.s >= _len[head]:
		if tram.next >= 0:
			tram.s -= _len[head]
			tram.trail.append(tram.next)
			tram.next = _pick_next(tram.next)
			# Keep just enough of the trail for the cars behind the head.
			var behind := 0.0
			for k in tram.trail.size() - 1:
				behind += _len[tram.trail[k]]
			while tram.trail.size() > 2 and behind - _len[tram.trail[0]] > LENGTH + 5.0:
				behind -= _len[tram.trail[0]]
				tram.trail.remove_at(0)
		elif tram.s > _len[head] + LENGTH + 2.0:
			_reenter(tram)


## Off the map: come back in on a track that enters it (a piece with nothing before it).
func _reenter(tram: Tram) -> void:
	var entries := []
	for i in _pts.size():
		if _pred[i].is_empty() and _len[i] > 5.0:
			entries.append(i)
	if entries.is_empty():
		return
	var i: int = entries[_rng.randi() % entries.size()]
	for other in trams:
		if other != tram and other.pos.distance_to(Vector3(_pts[i][0].x, other.pos.y, _pts[i][0].y)) < LENGTH + 15.0:
			return  # wait out there until the way in is clear
	tram.trail = PackedInt32Array([i])
	tram.s = 0.0
	tram.v = CRUISE * 0.8
	tram.next = _pick_next(i)
	tram.served = -1


## The point `back` metres behind the head along the trail.
func _back_point(tram: Tram, back: float) -> Vector2:
	var k := tram.trail.size() - 1
	var s := tram.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[tram.trail[k]]
	return _point(tram.trail[k], s)


## The traffic loop: a point `ahead` m along the rails in front of the tram's head, on to the next
## piece (or straight on past the end of the last).
func _ahead_point(tram: Tram, head: int, ahead: float) -> Vector2:
	var s := tram.s + ahead
	if s > _len[head] and tram.next >= 0:
		return _point(tram.next, s - _len[head])
	return _point(head, s)


func _back_height(tram: Tram, back: float) -> float:
	var k := tram.trail.size() - 1
	var s := tram.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[tram.trail[k]]
	return _height(tram.trail[k], s)


## Places the three cars along the rails. Parts past the map's edge (an exit with no
## track after it, or an entry with none before) are cut off, so trams slide in and
## out under the edge of the diorama.
func _pose(tram: Tram) -> void:
	var head := _head(tram)
	var lo := tram.s - _len[head] if tram.next < 0 else -INF
	var hi := INF
	if _pred[tram.trail[0]].is_empty():
		hi = tram.s
		for k in tram.trail.size() - 1:
			hi += _len[tram.trail[k]]
	tram.pos = Vector3.ZERO
	for k in 3:
		var body := tram.cars[k]
		var f := k * (tram.car_len + tram.joint)
		var b0 := maxf(f, lo)
		var b1 := minf(f + tram.car_len, hi)
		if b1 - b0 < 0.3 or k >= tram.n_cars:
			body.visible = false
			body.collision_layer = 0
			continue
		var front := _back_point(tram, b0)
		var rear := _back_point(tram, b1)
		var y := (_back_height(tram, b0) + _back_height(tram, b1)) * 0.5
		var mid := (front + rear) * 0.5
		var d := front - rear
		body.visible = true
		body.global_transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.y)), Vector3(mid.x, y + 0.1, mid.y))
		# Shorten the model (not the body: physics bodies don't like scaling).
		(body.get_child(0) as Node3D).scale.z = (b1 - b0) / tram.car_len
		var near := Vector2(mid.x - player_pos.x, mid.y - player_pos.z).length_squared() < 80.0 * 80.0
		body.collision_layer = 1 if near and player_on_road else 0
		if k == 0:
			tram.pos = Vector3(front.x, y, front.y)


# --- the vintage-tram loop (old_tram.gd) ------------------------------------------------------

## First scene item 7 (docs/design/first-scene.md, 2026-11-02): the first seconds of play ring a
## tram bell. Each tram in `list` rings once as its middle passes within GREET_R m of the player's
## car (moving, not braking for it: that rings anyway), the first of them only, for `seconds`.
const GREET_R := 14.0
var _greet: Array[Tram] = []
var _greet_t := 0.0
## How many greeting bells rang (the check reads it).
var greeted := 0


func greet(list: Array[Tram], seconds: float) -> void:
	_greet = list
	_greet_t = seconds


func _greet_step(dt: float) -> void:
	if _greet_t <= 0.0:
		return
	_greet_t -= dt
	var me := Vector2(player_pos.x, player_pos.z)
	for tram in _greet:
		if tram.v > 2.0 and tram.mid.distance_to(me) < GREET_R:
			_ring(tram)
			greeted += 1
			_greet_t = 0.0
			return


## The bell as a tram leaves a stop or brakes for the car: the old tram's own (old_bell).
func _ring(tram: Tram) -> void:
	if tram.vintage:
		old_bell.emit(tram.pos)
	else:
		bell.emit(tram.pos)


## A tram's length, head to tail (3 cars, or the old set's 2).
static func length_of(tram: Tram) -> float:
	return tram.n_cars * tram.car_len + (tram.n_cars - 1) * tram.joint


## Turns tram `tram` into the old two-car set (`meshes`: [motor car, trailer], cruising at
## `cruise` m/s) or back to its own look (on false). Its car meshes are swapped on its own
## MeshInstance3Ds (the same material): the old set draws two cars, never more than its own look.
func set_vintage(tram: Tram, on: bool, meshes: Array = [], cruise := CRUISE) -> void:
	if on == tram.vintage:
		return
	tram.vintage = on
	if on:
		_dress(tram, {"meshes": meshes, "turn": [false, false, false], "car": CAR, "joint": JOINT})
	else:
		_dress(tram, _kind_look(tram.kind))
	tram.cruise = cruise if on else CRUISE
	if on and tram.v > tram.cruise:
		tram.v = tram.cruise


## The look of fleet kind `kind` (tram_fleet.gd): its car meshes front first, which of them are
## turned round (a rear cab), the cars' length and the gap between them.
static func _kind_look(kind: int) -> Dictionary:
	var pair := kind == Fleet.Kind.PAIR or kind == Fleet.Kind.PAIR_NEW
	return {"meshes": Fleet.meshes(kind), "turn": [false, false, not pair],
			"car": Fleet.PAIR_CAR if pair else CAR, "joint": Fleet.PAIR_JOINT if pair else JOINT}


## Puts look `look` (_kind_look) on tram `tram`: the meshes on its cars (those past its last car
## hidden), the cars' collision boxes to their length, the lamp cones at the first car's nose and
## the red glow behind its last car.
func _dress(tram: Tram, look: Dictionary) -> void:
	var meshes: Array = look["meshes"]
	tram.n_cars = meshes.size()
	tram.car_len = look["car"]
	tram.joint = look["joint"]
	for k in 3:
		var body := tram.cars[k]
		var mi := body.get_child(0) as MeshInstance3D
		if k < tram.n_cars:
			mi.mesh = meshes[k]
			mi.rotation.y = PI if look["turn"][k] else 0.0
			for c in body.get_children():
				if c is CollisionShape3D:
					((c as CollisionShape3D).shape as BoxShape3D).size.z = tram.car_len
		else:
			body.visible = false
			body.collision_layer = 0
	var last := tram.cars[tram.n_cars - 1]
	if tram.tail.get_parent() != last:
		tram.tail.reparent(last, false)
	var grow := (tram.car_len - CAR) * 0.5
	tram.tail.position = Vector3(0.0, 0.0, grow)
	tram.cones.position = Vector3(0.0, 0.0, -grow)


## Whether any of tram `tram` is within the last update's reach of the view (posed: it may be
## seen). A tram swapped while out of it is never seen changing.
func in_sight(tram: Tram) -> bool:
	for p in [_back_point(tram, 0.0), _back_point(tram, length_of(tram) * 0.5), _back_point(tram, length_of(tram))]:
		if (p as Vector2).distance_to(view_at) < view_reach:
			return true
	return false


## The trams out of sight now, nearest the point `p` first.
func out_of_sight(p: Vector2) -> Array[Tram]:
	var out: Array[Tram] = []
	for tram in trams:
		if not in_sight(tram):
			out.append(tram)
	out.sort_custom(func(a: Tram, b: Tram) -> bool:
		return _back_point(a, 0.0).distance_squared_to(p) < _back_point(b, 0.0).distance_squared_to(p))
	return out


## Puts tram `tram` on the track nearest `p`, its head `ahead` m along the rails from the point
## nearest p (--old-tram), standing still; false if no track piece is long enough. The other
## trams keep their places (one that is in the way is left for the trams' own spacing). With a
## `way` (a unit direction), only a track running that way (the first scene: one tram each way
## up Marszałkowska), and the tram rolls off at `speed` m/s.
func place_near(tram: Tram, p: Vector2, ahead := 30.0, way := Vector2.ZERO, speed := 0.0) -> bool:
	var best := -1
	var best_s := 0.0
	var best_d := INF
	for i in _pts.size():
		if _len[i] < 40.0:
			continue
		var near := _project(i, p)
		if way != Vector2.ZERO and _dir(i, near.x).dot(way) < 0.8:
			continue
		if near.y < best_d:
			best_d = near.y
			best = i
			best_s = near.x
	if best < 0:
		return false
	var s := clampf(best_s + ahead, minf(length_of(tram), _len[best] - 1.0), _len[best] - 1.0)
	tram.trail = PackedInt32Array([best])
	var back := s
	while back < LENGTH + 5.0 and not _pred[tram.trail[0]].is_empty():
		var prev := _pred[tram.trail[0]][0]
		tram.trail.insert(0, prev)
		back += _len[prev]
	tram.s = s
	tram.v = speed
	tram.dwell = 0.0
	tram.served = -1
	tram.next = _pick_next(best)
	var head := _back_point(tram, 0.0)
	tram.pos = Vector3(head.x, tram.pos.y, head.y)
	tram.dir = _dir(best, s)
	tram.mid = _back_point(tram, length_of(tram) * 0.5)
	tram.rear = _back_point(tram, length_of(tram))
	return true


## A point `back` m behind tram `tram`'s head along its rails (old_tram.gd: its body, for the
## follow).
func body_point(tram: Tram, back: float) -> Vector2:
	return _back_point(tram, back)
