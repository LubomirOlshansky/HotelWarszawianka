extends Node3D
## Trains on the city's railway (T1 of docs/design/railway.md): suburban units, the city line and
## long-distance trains on the baked rail tracks (OpenStreetMap `rails`, drawn by map_builder as
## ballast and rails). The tracks have no direction, so every piece is used both ways; pieces
## join where their ends meet and the line runs on smoothly. A train comes in where the railway
## enters the map (its edge, or one of the cross-city tunnel's mouths: the tunnel itself is not in
## the map), runs through at city speed, stops at the platforms it serves (Ochota, Powiśle,
## Stadion; the long-distance trains run through), and slides out under the next edge or into the
## next tunnel mouth; a while later another comes in somewhere. Only one train holds a stretch of
## track at a time, so trains never meet head on. Each car is an AnimatableBody3D (the player's car
## bounces off them, as off the trams); cars far from the view are hidden.

const Models := preload("res://scripts/models.gd")
const RailYard := preload("res://scripts/rail_yard.gd")
const StationLines := preload("res://scripts/station_lines.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

## Cars are CAR m long with GAP m between them.
const CAR := 20.0
const GAP := 0.8
const CRUISE := 16.0          # 58 km/h: the cross-city line's speed through the centre
const ACCEL := 0.7
const DECEL := 0.9
const DWELL := 18.0
const HEIGHT_STEP := 8.0
## How many trains at most at once, and the wait (s) before a train that left comes back in.
const COUNT := 5
const RESPAWN := Vector2(8.0, 30.0)
## Track pieces join where their ends lie within LINK m and the line turns by under MAX_TURN rad.
const LINK := 0.8
const MAX_TURN := 0.55
## An end of the track this near the map's bounds is a way in and out; so is one near a tunnel
## mouth (the cross-city tunnel west of Ochota's cutting and under Powiśle's upper pavilion).
const EDGE := 45.0
const PORTALS := [Vector2(-1964.0, 812.0), Vector2(176.0, 80.0)]
const PORTAL_R := 40.0
## The cross-city tunnel under Plac Zawiszy: the 10 m terrain grid has the cutting's floor (7.5 m)
## up to its mouth, then the street (14.2 m) over the tunnel, but OSM keeps the tracks on to
## (-1923, 798), so beds, rails, wires and trains ran over the road. Rails are cut by this polygon
## (`trim_rails`); the mouth stands where the cutting ends (PORTALS[0]).
const TUNNEL_ZAWISZY := [Vector2(-2018.0, 850.0), Vector2(-1992.0, 834.0), Vector2(-1966.0, 825.0),
		Vector2(-1962.0, 806.0), Vector2(-1962.0, 760.0), Vector2(-1890.0, 760.0), Vector2(-1890.0, 860.0)]
## A platform within this distance of a track (its centre from the track's line) is a stop.
const PLATFORM_NEAR := 9.0
## A train this close to the end of its piece holds the next one.
const COMMIT := 80.0
## A train that has waited this long for its way to clear, out of sight, gives up and leaves.
const GIVE_UP := 45.0

## The kinds, all our own liveries (parody names in docs/design/railway.md section 4; the names on
## the sides are left for a later pass).
const KINDS := [
	{"name": "KOLEJE MAZOWE", "cars": 4, "body": "#f1f0ea", "band": "#2f8a45", "door": "#f0c22c", "roof": "#9a9d9f", "stops": true, "share": 0.5, "shape": "unit"},
	{"name": "SKiM", "cars": 3, "body": "#d3262c", "band": "#3a3d42", "door": "#f0c22c", "roof": "#8a8d90", "stops": true, "share": 0.3, "shape": "unit"},
	{"name": "INTERSZYBKO", "cars": 6, "body": "#d9dcdf", "band": "#1f3e78", "door": "#4a5058", "roof": "#6f7377", "stops": false, "share": 0.2, "shape": "ic", "loco": "#2f4f86"},
]


class Train:
	var kind := 0
	var n_cars := 4
	var active := false
	var wait := 0.0           # inactive: seconds until it comes in; active: seconds stuck
	## Directed pieces it is on, oldest first; the last one holds the head.
	var trail := PackedInt32Array()
	var s := 0.0
	var v := 0.0
	var next := -1
	var dwell := 0.0
	var served := -1
	var cars: Array[AnimatableBody3D] = []
	var pos := Vector3.ZERO
	var dir := Vector2.UP
	var rear := Vector2.ZERO
	var exits := 0
	var stops_made := 0
	var rumble := 0.0         # seconds to its next wheel rumble (sounds)


var map: Node3D
var player_pos := Vector3.ZERO
var player_on_road := true
var trains: Array[Train] = []
## The view centre and reach (main.gd sets them from the traffic's view each frame).
var view_at := Vector2.ZERO
var view_reach := 700.0
## How long the last update took, for --bench.
var last_usec := 0
## For check_trains.gd: the stops made, [platform index, kind] per stop, and the most trains that
## ever held one physical track piece at once.
var stop_log: Array[Vector2i] = []
var most_on_a_piece := 0
## Railway audit (F, 2026-11-07): the trains were silent. sfx.gd (main.gd sets it): the wheels'
## rumble and rail-joint beats while a train runs near the player (a steel drone over it on a
## bridge), its horn as it comes out of a tunnel mouth or in at the map's edge, and the platform
## gong as it pulls in at a stop. All original (tools/make_sfx.py). `heard` counts what played.
var sfx: Node
var heard := {}
var _snd_rng := RandomNumberGenerator.new()   # its own, so sound never changes the trains' run
const EARSHOT := 80.0
const RUMBLE_GAP := 2.2
const HORN_REACH := 85.0

# Directed pieces: 2 i runs along rail i as mapped, 2 i + 1 against it.
var _pts: Array[PackedVector2Array] = []
var _cum: Array[PackedFloat32Array] = []
var _len := PackedFloat32Array()
var _deck := PackedInt32Array()
var _succ: Array[PackedInt32Array] = []
var _pred: Array[PackedInt32Array] = []
var _sink := PackedByteArray()
var _sources := PackedInt32Array()
## Per directed piece, flat [s, platform index] of its stops, by s.
var _halts: Array[PackedFloat32Array] = []
## 1 where a directed piece has a stop on it or within TO_HALT pieces on (_straightest).
var _to_halt := PackedByteArray()
## 1 where a directed piece ends at buffers past a stop: a terminus (_link, _turn_back).
var _term := PackedByteArray()
## Turns made at a terminus (check_trains reads them).
var turns := 0
const TO_HALT := 3
var _heights: Array[PackedFloat32Array] = []
var _platforms: Array[Vector2] = []
var _bounds := Rect2()
var _rng := RandomNumberGenerator.new()


## The rails with the stretch under Plac Zawiszy (TUNNEL_ZAWISZY) cut away: each polyline that
## touches it comes back as its pieces outside. Others are returned as they are.
## Stacja Muzeum (the railway museum at Warszawa Główna, 2026-11-07): its four sidings (found by
## their ends at the museum's hall and its platform) hold the locomotives on show, so east of
## MUSEUM_X no train runs on them, and they get no wires and no signals. The tracks stay drawn.
const MUSEUM_ENDS := [Vector2(-2531.6, 870.1), Vector2(-2529.9, 874.5), Vector2(-2638.9, 933.1), Vector2(-2636.8, 936.9)]
const MUSEUM_X := -2895.0


## The rails trains run on (trim_rails without the museum's sidings east of MUSEUM_X).
static func service_rails(rails: Array) -> Array:
	var out: Array = []
	for r in trim_rails(rails):
		var f: Array = r["p"]
		var n := f.size()
		var museum := false
		for e: Vector2 in MUSEUM_ENDS:
			museum = museum or Vector2(f[0], f[1]).distance_to(e) < 0.5 or Vector2(f[n - 2], f[n - 1]).distance_to(e) < 0.5
		if not museum:
			out.append(r)
			continue
		var pts := PackedVector2Array()
		for i in range(0, n - 1, 2):
			pts.append(Vector2(f[i], f[i + 1]))
		var west := PackedVector2Array([Vector2(MUSEUM_X, -1e5), Vector2(MUSEUM_X, 1e5), Vector2(-1e5, 1e5), Vector2(-1e5, -1e5)])
		for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(pts, west):
			if piece.size() < 2 or piece[0].distance_to(piece[piece.size() - 1]) < 0.5:
				continue
			var np: Dictionary = r.duplicate()
			var g: Array = []
			for q in piece:
				g.append(q.x)
				g.append(q.y)
			np["p"] = g
			out.append(np)
	return out


static func trim_rails(rails: Array) -> Array:
	var poly := PackedVector2Array(TUNNEL_ZAWISZY)
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	var out: Array = []
	for r in rails:
		var flat: Array = r["p"]
		var pts := PackedVector2Array()
		var touches := false
		for i in range(0, flat.size() - 1, 2):
			var q := Vector2(flat[i], flat[i + 1])
			pts.append(q)
			touches = touches or box.has_point(q)
		if not touches:
			out.append(r)
			continue
		for piece: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(pts, poly):
			if piece.size() < 2 or piece[0].distance_to(piece[piece.size() - 1]) < 0.5:
				continue
			var np: Dictionary = r.duplicate()
			var f: Array = []
			for q in piece:
				f.append(q.x)
				f.append(q.y)
			np["p"] = f
			out.append(np)
	return out


func setup(map_node: Node3D, data: Dictionary) -> void:
	map = map_node
	_rng.seed = 1955
	var b: Array = data.get("bounds", [-1e6, -1e6, 1e6, 1e6])
	_bounds = Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	var lines: Array[PackedVector2Array] = []
	var decks := PackedInt32Array()
	for r in service_rails(data.get("rails", [])):
		var flat: Array = r["p"]
		var p := PackedVector2Array()
		for i in range(0, flat.size() - 1, 2):
			var q := Vector2(flat[i], flat[i + 1])
			if p.is_empty() or q.distance_to(p[p.size() - 1]) > 0.01:
				p.append(q)
		if p.size() < 2:
			continue
		lines.append(p)
		decks.append(int(r.get("dk", -1)))
	# A track that branches off another starts at one of the other's middle points (OSM ties a
	# switch so): the other is cut there, so the branch joins it end to end (_link). Warszawa
	# Główna's platform tracks were never reached without this.
	var ends := {}
	for p in lines:
		for q: Vector2 in [p[0], p[p.size() - 1]]:
			var key := _cell(q)
			var list: PackedVector2Array = ends.get(key, PackedVector2Array())
			list.append(q)
			ends[key] = list
	for li in lines.size():
		var p := lines[li]
		var cut := 0
		for i in range(1, p.size() - 1):
			if not _touches(ends, p[i]):
				continue
			if i - cut >= 1:
				_add_both(p.slice(cut, i + 1), decks[li])
			cut = i
		_add_both(p.slice(cut), decks[li])
	for plat in data.get("platforms", []):
		var flat: Array = plat["p"]
		var c := Vector2.ZERO
		for k in range(0, flat.size() - 1, 2):
			c += Vector2(flat[k], flat[k + 1])
		_platforms.append(c / (flat.size() / 2.0))
	# The island platforms OSM draws only as footways (Warszawa Główna): their middles.
	var yard := RailYard.new()
	yard.setup(data.get("paths", []), trim_rails(data.get("rails", [])), data.get("platforms", []))
	# Each island's two edges at its middle: a mark beside each of its tracks (the footway it
	# was found from often runs off its centre, past PLATFORM_NEAR from the far track).
	for pl: Dictionary in yard.platforms:
		var pp: PackedVector2Array = pl["p"]
		var m := pp.size() / 2
		var nm := RailYard._normal(pp, m)
		_platforms.append(pp[m] + nm * (pl["l"] as PackedFloat32Array)[m])
		_platforms.append(pp[m] - nm * (pl["r"] as PackedFloat32Array)[m])
	for ring: PackedVector2Array in yard.rings:
		var c := Vector2.ZERO
		for q in ring:
			c += q
		_platforms.append(c / ring.size())
	_find_halts()
	_link()
	_mark_to_halt()
	if map != null:
		_make_pax(data, yard)
	_make_trains()


func _add_both(p: PackedVector2Array, deck: int) -> void:
	if p.size() < 2:
		return
	var back := p.duplicate()
	back.reverse()
	for way: PackedVector2Array in [p, back]:
		_add_piece(way, deck)


func _touches(ends: Dictionary, q: Vector2) -> bool:
	var c := _cell(q)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for e: Vector2 in ends.get(c + Vector2i(dx, dz), PackedVector2Array()):
				if e.distance_to(q) < LINK:
					return true
	return false


func _add_piece(p: PackedVector2Array, deck: int) -> void:
	var c := PackedFloat32Array()
	var run := 0.0
	for i in p.size():
		if i > 0:
			run += p[i].distance_to(p[i - 1])
		c.append(run)
	_pts.append(p)
	_cum.append(c)
	_len.append(run)
	_deck.append(deck)
	_succ.append(PackedInt32Array())
	_pred.append(PackedInt32Array())
	_halts.append(PackedFloat32Array())
	_heights.append(PackedFloat32Array())


## Joins the pieces, finds the ways in and out, and drops every turn that leads only into a
## siding (a train must always reach a way out).
func _link() -> void:
	var n := _pts.size()
	var starts := {}
	for j in n:
		var key := _cell(_pts[j][0])
		if not starts.has(key):
			starts[key] = PackedInt32Array()
		starts[key].append(j)
	for i in n:
		var end := _pts[i][_pts[i].size() - 1]
		var out := _dir(i, _len[i])
		var cell := _cell(end)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for j: int in starts.get(cell + Vector2i(dx, dz), PackedInt32Array()):
					if j == (i ^ 1) or _pts[j][0].distance_to(end) > LINK:
						continue
					if absf(out.angle_to(_dir(j, 0.0))) < MAX_TURN:
						_succ[i].append(j)
	_sink.resize(n)
	for i in n:
		_sink[i] = 1 if _succ[i].is_empty() and _is_way_out(_pts[i][_pts[i].size() - 1]) else 0
	# Which pieces lead to a way out (repeat until nothing changes). A track ending at buffers
	# with a stop on it (Warszawa Główna's platform tracks) is a terminus: the train turns back
	# there (_turn_back), so it leads out where its way back does.
	var good := _sink.duplicate()
	_term.resize(n)
	_term.fill(0)
	for round_ in 2:
		var changed := true
		while changed:
			changed = false
			for i in n:
				if good[i] == 0:
					for j in _succ[i]:
						if good[j] == 1:
							good[i] = 1
							changed = true
							break
		for i in n:
			if good[i] == 0 and _succ[i].is_empty() and _sink[i] == 0 and not _halts[i].is_empty() and good[i ^ 1] == 1:
				good[i] = 1
				_term[i] = 1
	for i in n:
		var keep := PackedInt32Array()
		for j in _succ[i]:
			if good[j] == 1:
				keep.append(j)
		_succ[i] = keep
		for j in keep:
			_pred[j].append(i)
	for i in n:
		if good[i] == 1 and _pred[i].is_empty() and _is_way_out(_pts[i][0]) and _route_length(i) > 300.0:
			_sources.append(i)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))


func _is_way_out(p: Vector2) -> bool:
	if p.x < _bounds.position.x + EDGE or p.y < _bounds.position.y + EDGE or p.x > _bounds.end.x - EDGE or p.y > _bounds.end.y - EDGE:
		return true
	for q: Vector2 in PORTALS:
		if p.distance_to(q) < PORTAL_R:
			return true
	return false


## How far a train coming in on piece i runs (always the straightest way) before it leaves.
func _route_length(i: int) -> float:
	var total := 0.0
	var seen := {}
	while i >= 0 and not seen.has(i) and total < 5000.0:
		seen[i] = true
		total += _len[i]
		i = _straightest(i, false)
	return total


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


## The rails' height (on their bridge deck, or the ground), sampled once per piece.
func _height(i: int, s: float) -> float:
	if map == null:
		return 0.0
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


## A platform beside a track is a stop on it, both ways; the train's middle stops at the
## platform's middle (the head is placed half a train on, for each kind, in _move).
func _find_halts() -> void:
	for k in _platforms.size():
		for i in _pts.size():
			if _len[i] < 30.0:
				continue
			var near := _project(i, _platforms[k])
			if near.y < PLATFORM_NEAR and near.x > 1.0 and near.x < _len[i] - 1.0:
				_halts[i].append_array(PackedFloat32Array([near.x, k]))
	for i in _halts.size():
		var rows := []
		for k in range(0, _halts[i].size(), 2):
			rows.append(Vector2(_halts[i][k], _halts[i][k + 1]))
		rows.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var out := PackedFloat32Array()
		for r: Vector2 in rows:
			out.append_array(PackedFloat32Array([r.x, r.y]))
		_halts[i] = out


func _mark_to_halt() -> void:
	_to_halt.resize(_pts.size())
	_to_halt.fill(0)
	for i in _pts.size():
		var front := PackedInt32Array([i])
		for depth in TO_HALT + 1:
			var nxt := PackedInt32Array()
			for j in front:
				if not _halts[j].is_empty():
					_to_halt[i] = 1
				nxt.append_array(_succ[j])
			if _to_halt[i] == 1:
				break
			front = nxt


func _make_trains() -> void:
	if _sources.is_empty():
		return
	var meshes := []
	for kind: Dictionary in KINDS:
		var front := car_mesh(kind, 0)
		if kind.has("loco"):
			var loco: Dictionary = kind.duplicate()
			loco["body"] = kind["loco"]
			loco["band"] = "#d9dcdf"
			front = car_mesh(loco, 2)
		# The rear: a unit's other cab, or a train's last coach, with red tail lamps (railway audit,
		# 2026-11-07: both ends showed white lamps).
		var rear := car_mesh(kind, 1, true) if kind.has("loco") else car_mesh(kind, 0, true)
		meshes.append([front, car_mesh(kind, 1), rear])
	var most := 0
	for kind: Dictionary in KINDS:
		most = maxi(most, int(kind["cars"]))
	for n in COUNT:
		var t := Train.new()
		t.kind = _pick_kind()
		for k in most:
			var body := AnimatableBody3D.new()
			body.sync_to_physics = false
			body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			var mi := MeshInstance3D.new()
			mi.material_override = Models.material()
			body.add_child(mi)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.9, 4.2, CAR)
			shape.shape = box
			shape.position.y = 2.2
			body.add_child(shape)
			body.visible = false
			body.collision_layer = 0
			add_child(body)
			t.cars.append(body)
		_dress(t, meshes)
		# Spread the first arrivals out: a couple on the map at once, the rest a little later.
		t.wait = n * 6.0
		trains.append(t)
	for n in mini(2, trains.size()):
		_enter(trains[n], meshes)
	set_meta("meshes", meshes)


func _pick_kind() -> int:
	var r := _rng.randf()
	for k in KINDS.size():
		r -= float(KINDS[k]["share"])
		if r <= 0.0:
			return k
	return 0


## Gives train t its kind's car meshes (a cab at each end, the cars between plain).
func _dress(t: Train, meshes: Array) -> void:
	t.n_cars = int(KINDS[t.kind]["cars"])
	for k in t.cars.size():
		var mi := t.cars[k].get_child(0) as MeshInstance3D
		# A unit has a cab at each end; a long-distance train its locomotive at the front.
		var loco: bool = (KINDS[t.kind] as Dictionary).has("loco")
		var last := k == t.n_cars - 1 and k > 0
		mi.mesh = meshes[t.kind][2 if last else (0 if k == 0 else 1)]
		mi.rotation.y = PI if k == t.n_cars - 1 and k > 0 and not loco else 0.0


## Brings train t in on a way in whose first stretch is free; false if none is.
func _enter(t: Train, meshes: Array) -> bool:
	var order := Array(_sources)
	order.shuffle()
	for i: int in order:
		if _held(i, t):
			continue
		t.kind = _pick_kind()
		_dress(t, meshes)
		t.trail = PackedInt32Array([i])
		t.s = 0.0
		t.v = CRUISE * 0.8
		t.next = _straightest(i, true, bool(KINDS[t.kind]["stops"]))
		t.served = -1
		t.dwell = 0.0
		t.wait = 0.0
		t.active = true
		t.rumble = 0.5
		# Out of a tunnel mouth or in from the edge near the player: the horn.
		var from := _pts[i][0]
		if map != null and from.distance_to(Vector2(player_pos.x, player_pos.z)) < HORN_REACH:
			_play("train_horn", Vector3(from.x, player_pos.y + 2.0, from.y))
		return true
	return false


## Whether any other active train holds the physical track under directed piece i.
func _held(i: int, by: Train) -> bool:
	var phys := i >> 1
	for o in trains:
		if o == by or not o.active:
			continue
		for j in o.trail:
			if j >> 1 == phys:
				return true
		# Its next piece too once it is close to it (committed): two trains a long way off
		# would otherwise each hold the stretch between them for the other.
		if o.next >= 0 and o.next >> 1 == phys and not o.trail.is_empty() and _len[_head(o)] - o.s < COMMIT:
			return true
	return false


## The next piece after i: the straightest way on (a little variety where two are nearly as
## straight), or -1 at a way out.
func _straightest(i: int, vary: bool, stops := false) -> int:
	var options := _succ[i]
	if options.is_empty():
		return -1
	# A stopping train takes the way to a platform where one branches off (Warszawa Główna's
	# islands lie on the yard's side tracks) most times.
	if stops and options.size() > 1 and _rng.randf() < 0.75:
		var to_halt := PackedInt32Array()
		for j in options:
			if _to_halt[j] == 1:
				to_halt.append(j)
		if not to_halt.is_empty() and to_halt.size() < options.size():
			options = to_halt
	var out := _dir(i, _len[i])
	var best := -1
	var best_turn := INF
	for j in options:
		var turn := absf(out.angle_to(_dir(j, 0.0)))
		if vary:
			turn += _rng.randf() * 0.06
		if turn < best_turn:
			best_turn = turn
			best = j
	return best


## --train=X,Z: an idle train onto the track nearest p, its middle there, rolling on.
func place_near(p: Vector2, kind := -1) -> bool:
	var best := -1
	var best_s := 0.0
	var best_d := INF
	for i in _pts.size():
		if _len[i] < 60.0 or _succ[i].is_empty() and _sink[i] == 0 and _term[i] == 0:
			continue
		var near := _project(i, p)
		if near.y < best_d:
			best_d = near.y
			best = i
			best_s = near.x
	if best < 0:
		return false
	for t in trains:
		if t.active:
			continue
		if kind >= 0 and kind < KINDS.size():
			t.kind = kind
			_dress(t, get_meta("meshes", []))
		var s := clampf(best_s + length_of(t) * 0.5, 1.0, _len[best] - 1.0)
		t.trail = PackedInt32Array([best])
		var back := s
		while back < length_of(t) + 5.0 and not _pred[t.trail[0]].is_empty():
			var prev := _pred[t.trail[0]][0]
			t.trail.insert(0, prev)
			back += _len[prev]
		t.s = s
		t.v = CRUISE * 0.5
		t.next = _straightest(best, true, bool(KINDS[t.kind]["stops"]))
		t.served = -1
		t.active = true
		return true
	return false


func length_of(t: Train) -> float:
	return t.n_cars * CAR + (t.n_cars - 1) * GAP


func _process(dt: float) -> void:
	step(dt)


## One update (check_trains.gd calls it directly, with no map and no view).
func step(dt: float) -> void:
	if dt <= 0.0 or trains.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	var meshes: Array = get_meta("meshes", [])
	for t in trains:
		if not t.active:
			t.wait -= dt
			if t.wait <= 0.0 and not _enter(t, meshes):
				t.wait = 3.0
			continue
		var head := _head(t)
		t.dir = _dir(head, clampf(t.s, 0.0, _len[head]))
		t.rear = _back_point(t, length_of(t))
	for t in trains:
		if t.active:
			_move(t, dt)
	# Bookkeeping for the check: the most trains on one physical piece.
	var count := {}
	for t in trains:
		if not t.active:
			continue
		var mine := {}
		for j in t.trail:
			mine[j >> 1] = true
		for k in mine:
			count[k] = count.get(k, 0) + 1
			most_on_a_piece = maxi(most_on_a_piece, count[k])
	for t in trains:
		if not t.active:
			continue
		var head := _back_point(t, 0.0)
		if map == null:
			t.pos = Vector3(head.x, 0.0, head.y)
		elif head.distance_to(view_at) < view_reach + length_of(t):
			_pose(t)
		else:
			t.pos = Vector3(head.x, t.pos.y, head.y)
			_hide(t)
	if _pax_mm != null:
		_step_pax(dt)
	if sfx != null:
		_sounds(dt)
	last_usec = Time.get_ticks_usec() - t0


## People getting off and on at a stop (F, 2026-11-06): when a train in view comes to rest at a
## platform, a few step out of each door onto the platform and walk off along it, and a few who
## waited walk up to the doors and in. Their own MultiMesh of the pedestrians' figure (+1 draw
## call, hidden while nobody is about).
const PAX := 64
const PAX_SPEED := 1.35
const PAX_SHIRTS := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#2b2c2f", "#c96b2c", "#5aa9c9", "#9c2f3a"]
## How far from the track's centre a door's step lies (the car's half width and the gap).
const DOOR_OUT := 1.75
## The platform's top over the rails' bed (OSM 0.9 m, Warszawa Główna's 0.76 m).
const PAX_UP := 0.8

var _pax_mm: MultiMesh
var _pax_mi: MultiMeshInstance3D
var _pax_buf := PackedFloat32Array()
## Per person: from, to (x, y, z), the delay before they set off, how far along (m), alive.
var _pax_from := PackedVector3Array()
var _pax_to := PackedVector3Array()
var _pax_delay := PackedFloat32Array()
var _pax_s := PackedFloat32Array()
var _pax_alive := PackedByteArray()
var _pax_count := 0
## Boardings and alightings so far (check_trains reads them).
var pax_moved := 0

## People waiting at every station (F, 2026-11-06: "people at all the stations"): when a stop's
## platform comes into view a few walk in along it and stand facing the track, up to WAITERS at
## each stop mark; when a train stops there they walk to its nearest door and get in. They live
## in the same MultiMesh as the boarders (no new draw call); the leg swing is off while they
## stand (actor.gdshader: INSTANCE_CUSTOM.a over STAND_A).
const WAITERS := 6
## How near the view's centre a stop must be for people to gather on its platform.
const WAIT_RANGE := 260.0
## How far either way from the stop's middle they stand (a train is 60 to 120 m long).
const WAIT_SPREAD := 32.0
## The free places kept for those getting off a train.
const WAIT_SPARE := 18
## Custom data's alpha past this: the figure stands still (its trousers stay fract(alpha)).
const STAND_A := 2.0
## How near a stop's track a platform line (station_lines.gd) must pass to be its platform.
const WAIT_LINE_NEAR := 14.0
## Each stop once: Vector3(piece, s of the train's middle there, platform mark), and its platform
## line and the sample nearest it (Vector2i(line, sample)).
var _stops: Array[Vector3] = []
var _stop_line: Array[Vector2i] = []
var _lines: Array = []
## Per person: the platform mark they wait at (-1: not waiting), and where they look when they
## stand (towards the track).
var _pax_wait := PackedInt32Array()
var _pax_face := PackedVector2Array()
var _wait_tick := 0.0
var waiting := 0


func _make_pax(data: Dictionary, yard: RailYard) -> void:
	_pax_mm = MultiMesh.new()
	_pax_mm.transform_format = MultiMesh.TRANSFORM_3D
	_pax_mm.use_custom_data = true
	InstanceBuffers.prepare(_pax_mm)
	_pax_mm.mesh = Models.person_mesh()
	_pax_mm.instance_count = PAX
	_pax_mm.custom_aabb = AABB(Vector3(-6000, -300, -6000), Vector3(12000, 900, 12000))
	_pax_buf.resize(PAX * 16)
	_pax_buf.fill(0.0)
	_pax_from.resize(PAX)
	_pax_to.resize(PAX)
	_pax_delay.resize(PAX)
	_pax_s.resize(PAX)
	_pax_alive.resize(PAX)
	_pax_alive.fill(0)
	_pax_wait.resize(PAX)
	_pax_wait.fill(-1)
	_pax_face.resize(PAX)
	_lines = StationLines.lines(data.get("platforms", []), StationLines.tracks(trim_rails(data.get("rails", []))), yard,
			map.terrain_height)
	var seen := {}
	for i in _halts.size():
		for k in range(0, _halts[i].size(), 2):
			var mark := int(_halts[i][k + 1])
			if seen.has(mark):
				continue
			# The platform line beside this stop: its sample nearest the train's middle there.
			var at := _point(i, _halts[i][k])
			var best := Vector2i(-1, -1)
			var near := WAIT_LINE_NEAR
			for li in _lines.size():
				var pts: PackedVector2Array = _lines[li][0]
				for j in pts.size():
					var dd := pts[j].distance_to(at)
					if dd < near:
						near = dd
						best = Vector2i(li, j)
			if best.x < 0:
				continue
			seen[mark] = true
			_stops.append(Vector3(i, _halts[i][k], mark))
			_stop_line.append(best)
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.16)
	_pax_mi = MultiMeshInstance3D.new()
	_pax_mi.multimesh = _pax_mm
	_pax_mi.material_override = mat
	_pax_mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_pax_mi.visible = false
	add_child(_pax_mi)


## Train t has come to rest at platform k: people off and on at each door on its side.
func _board(t: Train, k: int) -> void:
	if _pax_mm == null or not _in_sight(t):
		return
	var head := _back_point(t, 0.0)
	var side := signf(t.dir.cross(_platforms[k] - head))
	if side == 0.0:
		side = 1.0
	var nm := Vector2(-t.dir.y, t.dir.x) * side
	var steps := PackedVector3Array()
	for c in t.n_cars:
		for door: float in [0.25, 0.75]:
			var back := c * (CAR + GAP) + CAR * door
			var at := _back_point(t, back)
			var step := at + nm * DOOR_OUT
			steps.append(Vector3(step.x, _back_height(t, back) + PAX_UP, step.y))
	# Those waiting on this platform walk to the nearest door and get in.
	var boarded := 0
	for n in PAX:
		if _pax_alive[n] == 0 or _pax_wait[n] != k:
			continue
		var here := _pax_to[n]
		var best := steps[0]
		for q in steps:
			if Vector2(q.x - here.x, q.z - here.z).length() < Vector2(best.x - here.x, best.z - here.z).length():
				best = q
		if Vector2(best.x - here.x, best.z - here.z).length() > 45.0:
			continue  # past the train's end: they wait for the next one
		_pax_wait[n] = -1
		_pax_from[n] = here
		_pax_to[n] = best - Vector3(nm.x, 0.0, nm.y) * 0.9
		_pax_delay[n] = _rng.randf_range(0.5, 4.0)
		_pax_s[n] = 0.0
		_pax_buf[n * 16 + 15] = fposmod(_pax_buf[n * 16 + 15], 1.0)
		waiting -= 1
		boarded += 1
		pax_moved += 1
	# Which way along the platform its middle lies, so people walk towards it, not off its end.
	var mid := _platforms[k]
	for q in steps:
		var step := Vector2(q.x, q.z)
		var y := q.y
		var toward := signf((mid - step).dot(t.dir))
		for n in _rng.randi_range(0, 2):
			var off := step + nm * _rng.randf_range(1.5, 3.2) + t.dir * toward * _rng.randf_range(3.0, 12.0)
			_pax_spawn(Vector3(step.x, y, step.y), Vector3(off.x, y, off.y), _rng.randf_range(0.3, 2.5))
		if boarded > 0:
			continue
		for n in _rng.randi_range(0, 2):
			var from := step + nm * _rng.randf_range(1.5, 3.5) + t.dir * _rng.randf_range(-5.0, 5.0)
			_pax_spawn(Vector3(from.x, y, from.y), Vector3(step.x, y, step.y) - Vector3(nm.x, 0.0, nm.y) * 0.9,
					_rng.randf_range(4.0, 10.0))


## A free place for one more person walking from `from` to `to` after `delay` s: its index, or -1.
func _pax_spawn(from: Vector3, to: Vector3, delay: float) -> int:
	for n in PAX:
		if _pax_alive[n] == 1:
			continue
		_pax_from[n] = from
		_pax_to[n] = to
		_pax_delay[n] = delay
		_pax_s[n] = 0.0
		_pax_alive[n] = 1
		_pax_wait[n] = -1
		_pax_count += 1
		pax_moved += 1
		var shirt := Color(PAX_SHIRTS[_rng.randi() % PAX_SHIRTS.size()])
		var b := n * 16
		_pax_buf[b + 12] = shirt.r
		_pax_buf[b + 13] = shirt.g
		_pax_buf[b + 14] = shirt.b
		_pax_buf[b + 15] = _rng.randf()
		return n
	return -1


## Tops up the people waiting on the platforms near the view, and lets go of those far from it.
func _gather() -> void:
	var free := PAX - _pax_count
	var count := {}
	for n in PAX:
		if _pax_alive[n] == 0 or _pax_wait[n] < 0:
			continue
		var at := Vector2(_pax_to[n].x, _pax_to[n].z)
		if at.distance_to(view_at) > WAIT_RANGE * 1.4:
			_pax_alive[n] = 0
			_pax_wait[n] = -1
			_pax_count -= 1
			waiting -= 1
			for k in 16:
				_pax_buf[n * 16 + k] = 0.0
			continue
		count[_pax_wait[n]] = int(count.get(_pax_wait[n], 0)) + 1
	for si in _stops.size():
		if free <= WAIT_SPARE:
			return
		var stop := _stops[si]
		var i := int(stop.x)
		var mark := int(stop.z)
		var mid := _point(i, stop.y)
		if mid.distance_to(view_at) > WAIT_RANGE:
			continue
		# Each stop its own crowd size (3 to WAITERS), the same every time it comes into view.
		if int(count.get(mark, 0)) >= 3 + (mark * 7) % (WAITERS - 2):
			continue
		var line: Array = _lines[_stop_line[si].x]
		var pts: PackedVector2Array = line[0]
		var tops: PackedFloat32Array = line[1]
		var halves: PackedFloat32Array = line[2]
		var spread := int(WAIT_SPREAD / StationLines.STEP)
		var j := clampi(_stop_line[si].y + _rng.randi_range(-spread, spread), 0, pts.size() - 1)
		var j2 := clampi(j + _rng.randi_range(-8, 8), 0, pts.size() - 1)
		var d := (pts[mini(j + 1, pts.size() - 1)] - pts[maxi(j - 1, 0)]).normalized()
		var nm := Vector2(-d.y, d.x)
		# Towards the stop's own track: they stand on its side of the platform and look at it.
		var side := signf((_point(i, stop.y) - pts[_stop_line[si].y]).dot(nm))
		if side == 0.0:
			side = 1.0
		var across := side * _rng.randf_range(0.0, maxf(halves[j] - 1.2, 0.0))
		var stand := pts[j] + nm * across
		var start := pts[j2] + nm * across
		var y := tops[j]
		var n := _pax_spawn(Vector3(start.x, y, start.y), Vector3(stand.x, y, stand.y), _rng.randf_range(0.0, 3.0))
		if n < 0:
			return
		pax_moved -= 1  # not a boarding (yet)
		_pax_wait[n] = mark
		_pax_face[n] = nm * side
		waiting += 1
		free -= 1


func _step_pax(dt: float) -> void:
	_wait_tick -= dt
	if _wait_tick <= 0.0:
		_wait_tick = 1.0
		_gather()
	if _pax_count == 0:
		if _pax_mi.visible:
			_pax_mi.visible = false
		return
	_pax_mi.visible = true
	for n in PAX:
		var b := n * 16
		if _pax_alive[n] == 0:
			_pax_buf[b + 5] = 0.0  # a collapsed instance draws nothing
			continue
		var from := _pax_from[n]
		var to := _pax_to[n]
		var run := Vector2(to.x - from.x, to.z - from.z)
		var length := run.length()
		if _pax_delay[n] > 0.0:
			_pax_delay[n] -= dt
		else:
			_pax_s[n] += PAX_SPEED * dt
		if _pax_s[n] >= length:
			if _pax_wait[n] >= 0:
				# Arrived where they wait: stand still, facing the track.
				_pax_s[n] = length
				run = _pax_face[n]
				_pax_buf[b + 15] = STAND_A + fposmod(_pax_buf[b + 15], 1.0)
			else:
				_pax_alive[n] = 0
				_pax_count -= 1
				_pax_buf[b + 5] = 0.0
				for k in 12:
					_pax_buf[b + k] = 0.0
				continue
		var q := from.lerp(to, minf(_pax_s[n] / maxf(length, 0.01), 1.0))
		var yaw := atan2(-run.x, -run.y) if run.length() > 0.01 else 0.0
		var c := cos(yaw)
		var sn := sin(yaw)
		_pax_buf[b] = c
		_pax_buf[b + 1] = 0.0
		_pax_buf[b + 2] = sn
		_pax_buf[b + 3] = q.x
		_pax_buf[b + 4] = 0.0
		_pax_buf[b + 5] = 1.0
		_pax_buf[b + 6] = 0.0
		_pax_buf[b + 7] = q.y
		_pax_buf[b + 8] = -sn
		_pax_buf[b + 9] = 0.0
		_pax_buf[b + 10] = c
		_pax_buf[b + 11] = q.z
	InstanceBuffers.send(_pax_mm.get_rid(), _pax_buf)


func _head(t: Train) -> int:
	return t.trail[t.trail.size() - 1]


func _move(t: Train, dt: float) -> void:
	var head := _head(t)
	var gap := INF
	var half := length_of(t) * 0.5
	# The next stop on this piece or the next one.
	if bool(KINDS[t.kind]["stops"]):
		for pass_ in 2:
			var piece := head if pass_ == 0 else t.next
			if piece < 0 or gap < INF:
				break
			var offset := 0.0 if pass_ == 0 else _len[head] - t.s
			var halts := _halts[piece]
			for k in range(0, halts.size(), 2):
				var at := halts[k] + half
				var ahead := at - (t.s if pass_ == 0 else 0.0) + offset
				if ahead < -0.5 or int(halts[k + 1]) == t.served:
					continue
				gap = ahead
				if ahead < 0.8 and t.v < 0.3:
					if t.dwell == 0.0 and map != null:
						_board(t, int(halts[k + 1]))
						if Vector2(t.pos.x, t.pos.z).distance_to(Vector2(player_pos.x, player_pos.z)) < EARSHOT:
							_play("station_gong", t.pos + Vector3.UP * 3.0)
					t.dwell += dt
					if t.dwell > DWELL:
						t.served = int(halts[k + 1])
						t.dwell = 0.0
						t.stops_made += 1
						stop_log.append(Vector2i(t.served, t.kind))
						if pass_ == 0 and _term[head] == 1:
							_turn_back(t)
							return
				break
	# Buffers ahead: never past them.
	if _term[head] == 1:
		gap = minf(gap, _len[head] - t.s - 1.0)
	# The way on: wait at the end of this piece while another train holds the next one.
	if t.next >= 0 and _held(t.next, t):
		gap = minf(gap, _len[head] - t.s - 2.0)
		if t.v < 0.2:
			t.wait += dt
			if t.wait > GIVE_UP and not _in_sight(t):
				_leave(t)
				return
	else:
		t.wait = 0.0
	# The player's car on the rails ahead.
	if player_on_road and map != null:
		var here := Vector2(t.pos.x, t.pos.z)
		var rel := Vector2(player_pos.x, player_pos.z) - here
		var along := rel.dot(t.dir)
		if along > 0.0 and along < 70.0 and absf(rel.cross(t.dir)) < 2.8 and absf(player_pos.y - t.pos.y) < 3.0:
			gap = minf(gap, along - 6.0)
	var want := CRUISE
	if gap < INF:
		want = minf(want, sqrt(maxf(gap - 0.3, 0.0) * 2.0 * DECEL))
	if t.v < want:
		t.v = minf(want, t.v + ACCEL * dt)
	else:
		t.v = maxf(want, t.v - DECEL * 3.0 * dt)
	t.s += t.v * dt
	if t.s >= _len[head]:
		if t.next >= 0 and not _held(t.next, t):
			t.s -= _len[head]
			t.trail.append(t.next)
			t.next = _straightest(t.next, true, bool(KINDS[t.kind]["stops"]))
			var behind := 0.0
			for k in t.trail.size() - 1:
				behind += _len[t.trail[k]]
			while t.trail.size() > 2 and behind - _len[t.trail[0]] > length_of(t) + 5.0:
				behind -= _len[t.trail[0]]
				t.trail.remove_at(0)
		elif t.next < 0 and t.s > _len[head] + length_of(t) + 2.0:
			_leave(t)
		elif t.next >= 0:
			t.s = _len[head]
			t.v = 0.0


## At a terminus, after its stop: the train's tail becomes its head, and it runs back out the
## way it came (the units have a cab at each end; the long-distance kind never stops).
func _turn_back(t: Train) -> void:
	var k := t.trail.size() - 1
	var s := t.s - length_of(t)
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[t.trail[k]]
	var back := PackedInt32Array()
	for j in range(t.trail.size() - 1, k - 1, -1):
		back.append(t.trail[j] ^ 1)
	t.trail = back
	t.s = _len[back[back.size() - 1]] - maxf(s, 0.0)
	t.v = 0.0
	t.next = _straightest(back[back.size() - 1], true, true)
	turns += 1
	# The cars in the new order: the old last car leads.
	for c in t.n_cars / 2:
		var a := t.cars[c]
		t.cars[c] = t.cars[t.n_cars - 1 - c]
		t.cars[t.n_cars - 1 - c] = a
	# The new front cab shows white lamps, the new last car red ones.
	_dress(t, get_meta("meshes"))


## The wheels: every RUMBLE_GAP s (sooner when fast) a train running within EARSHOT of the
## player rumbles from its car nearest the player; on a bridge deck the steel drone instead.
func _sounds(dt: float) -> void:
	var ear := Vector2(player_pos.x, player_pos.z)
	for t in trains:
		if not t.active or t.v < 4.0:
			continue
		t.rumble -= dt * (t.v / CRUISE)
		if t.rumble > 0.0:
			continue
		t.rumble = RUMBLE_GAP * _snd_rng.randf_range(0.85, 1.15)
		# The point of the train nearest the ear.
		var head := Vector2(t.pos.x, t.pos.z)
		var ab := t.rear - head
		var u := clampf((ear - head).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
		var at := head + ab * u
		if at.distance_to(ear) > EARSHOT:
			continue
		var on_deck := _deck[_head(t)] >= 0
		_play("train_bridge" if on_deck else "train_rumble", Vector3(at.x, t.pos.y + 1.0, at.y),
				lerpf(-6.0, 0.0, t.v / CRUISE))


func _play(n: String, at: Vector3, gain_db := 0.0) -> void:
	heard[n] = int(heard.get(n, 0)) + 1
	if sfx != null:
		sfx.play_at(n, at, gain_db)


## Off the map or into the tunnel: gone, and back in a while somewhere.
func _leave(t: Train) -> void:
	t.active = false
	t.exits += 1
	t.trail = PackedInt32Array()
	t.next = -1
	t.wait = _rng.randf_range(RESPAWN.x, RESPAWN.y)
	_hide(t)


func _hide(t: Train) -> void:
	for body in t.cars:
		body.visible = false
		body.collision_layer = 0


func _in_sight(t: Train) -> bool:
	if map == null:
		return false
	for back in [0.0, length_of(t) * 0.5, length_of(t)]:
		if _back_point(t, back).distance_to(view_at) < view_reach:
			return true
	return false


## The point `back` m behind the head along the trail.
func _back_point(t: Train, back: float) -> Vector2:
	var k := t.trail.size() - 1
	var s := t.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[t.trail[k]]
	return _point(t.trail[k], s)


func _back_height(t: Train, back: float) -> float:
	var k := t.trail.size() - 1
	var s := t.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[t.trail[k]]
	return _height(t.trail[k], clampf(s, 0.0, _len[t.trail[k]]))


## Places the cars along the rails; parts past a way out (or before a way in) are cut off, so a
## train slides out under the map's edge or into the tunnel's mouth.
func _pose(t: Train) -> void:
	var head := _head(t)
	var lo := t.s - _len[head] if t.next < 0 else -INF
	var hi := INF
	if _pred[t.trail[0]].is_empty():
		hi = t.s
		for k in t.trail.size() - 1:
			hi += _len[t.trail[k]]
	for k in t.cars.size():
		var body := t.cars[k]
		var f := k * (CAR + GAP)
		var b0 := maxf(f, lo)
		var b1 := minf(f + CAR, hi)
		if k >= t.n_cars or b1 - b0 < 0.3:
			body.visible = false
			body.collision_layer = 0
			continue
		var front := _back_point(t, b0)
		var rear := _back_point(t, b1)
		var y := (_back_height(t, b0) + _back_height(t, b1)) * 0.5
		var mid := (front + rear) * 0.5
		var d := front - rear
		body.visible = true
		body.global_transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.y)), Vector3(mid.x, y + 0.15, mid.y))
		(body.get_child(0) as Node3D).scale.z = (b1 - b0) / CAR
		var near := Vector2(mid.x - player_pos.x, mid.y - player_pos.z).length_squared() < 90.0 * 90.0
		body.collision_layer = 1 if near and player_on_road else 0
		if k == 0:
			t.pos = Vector3(front.x, y, front.y)


## One car of a kind (front at -Z), built from the vehicles' shapes (models.gd Shape), F
## 2026-11-06 (a photo of a red suburban unit at a platform): `role` 0 a cab car, 1 a car between, 2 a
## locomotive. The suburban kinds ("shape" unit) are low-floor units: a sloped nose with a big
## black windscreen running up into the roof, wide windows in a dark band, two sliding doors a
## side in the door colour, a grey skirt, air-conditioning boxes on the roof and the pantograph
## over the cab car. The long-distance kind ("shape" ic) is a locomotive with a blunt sloped cab
## at each end (grilles down its sides, two pantographs) and coaches with a dark window band
## over a navy stripe and a door near each end. `tail`: the train's last car, its lamps at the far
## end red (a cab's nose lamps; on a coach, two at its +Z end).
static func car_mesh(kind: Dictionary, role: int, tail := false) -> ArrayMesh:
	var s := Models.Shape.new()
	var body := Models.fin(Color(kind["body"]))
	var band := Models.fin(Color(kind["band"]))
	var door := Models.fin(Color(kind["door"]))
	var roof := Models.fin(Color(kind["roof"]))
	var dark := Models.fin(Color("#232528"))
	var skirt := Models.fin(Color("#55595e"))
	var glass := Models.fin(Models.GLASS)
	var lit := Models.fin(Models.GLASS, Models.LIT_WINDOW)
	var lamp := Models.fin(Models.TAIL, Models.TAIL_LAMP) if tail else Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP)
	var unit := String(kind.get("shape", "unit")) == "unit"
	var hl := CAR * 0.5
	var W := 1.45
	var top := 4.0 if unit else 4.05
	var floor_y := 1.0
	# The noses: a cab at -Z (cab car, locomotive) and at +Z (the locomotive's other end).
	var ends: Array[float] = []
	if role == 0 or role == 2:
		ends.append(-1.0)
	if role == 2:
		ends.append(1.0)
	var nose := 3.0 if unit else 1.8
	var z0 := -hl + (nose if ends.has(-1.0) else 0.0)
	var z1 := hl - (nose if ends.has(1.0) else 0.0)
	# The body between the noses.
	var house := PackedVector2Array([Vector2(z0, floor_y), Vector2(z0, top), Vector2(z1, top), Vector2(z1, floor_y)])
	var hw := PackedFloat32Array([W, W, W, W])
	s.loft(house, hw, [null if ends.has(-1.0) else dark, roof, null if ends.has(1.0) else dark, null], body)
	for e: float in ends:
		# Side view from the body's join out to the bumper and back up over the windscreen.
		var zj := z0 if e < 0.0 else z1
		var zf := -hl if e < 0.0 else hl
		var sl := (zf - zj)  # signed nose length, outwards
		var prof := PackedVector2Array()
		var half := PackedFloat32Array()
		if unit:
			prof = PackedVector2Array([Vector2(zj, floor_y), Vector2(zj + sl * 0.93, floor_y), Vector2(zf, 1.75),
					Vector2(zj + sl * 0.72, 2.75), Vector2(zj + sl * 0.22, top), Vector2(zj, top)])
			half = PackedFloat32Array([W, W - 0.08, W - 0.18, W - 0.22, W - 0.08, W])
		else:
			prof = PackedVector2Array([Vector2(zj, floor_y), Vector2(zf, floor_y), Vector2(zf, 2.55),
					Vector2(zj + sl * 0.45, 3.75), Vector2(zj + sl * 0.15, top), Vector2(zj, top)])
			half = PackedFloat32Array([W, W - 0.05, W - 0.1, W - 0.12, W - 0.05, W])
		# (loft takes each face's outside from the outline's middle: either end's order works.)
		var skin := [null, body, body, glass, roof, null] if unit else [null, body, glass, body, roof, null]
		s.loft(prof, half, skin, body)
		# Lamps low on the nose, a dark coupler under it, the skirt's front.
		for x: float in [-0.9, 0.9]:
			s.box(Vector3(x, 1.45, zf + e * 0.03), Vector3(0.36, 0.18, 0.08), lamp)
		s.box(Vector3(0.0, 0.85, zf + e * 0.15), Vector3(0.5, 0.3, 0.5), dark)
		if unit:
			# The black mask round the windscreen down the nose's sides.
			for sgn: float in [-1.0, 1.0]:
				s.side_rect(sgn * (W + 0.012), sgn, 2.55, 3.55, minf(zj, zj + sl * 0.5), maxf(zj, zj + sl * 0.5), glass)
		else:
			# The cab's side windows.
			for sgn: float in [-1.0, 1.0]:
				s.side_rect(sgn * (W - 0.05 + 0.012), sgn, 2.6, 3.4, minf(zj, zj + sl * 0.6), maxf(zj, zj + sl * 0.6), glass)
	# Sides: windows, doors, the stripe.
	for sgn: float in [-1.0, 1.0]:
		var x := sgn * (W + 0.012)
		var doors: Array[float] = []
		if role == 2:
			# The locomotive: grilles along the machine room, a stripe.
			for g in 4:
				var gz := lerpf(z0 + 1.6, z1 - 1.6, (g + 0.5) / 4.0)
				s.side_rect(x, sgn, 2.3, 3.4, gz - 1.2, gz + 1.2, dark)
			s.side_rect(x, sgn, 1.25, 1.65, z0, z1, band)
			continue
		if unit:
			doors = [lerpf(z0, z1, 0.22), lerpf(z0, z1, 0.78)]
		else:
			doors = [z0 + 1.6, z1 - 1.6]
		s.side_rect(x, sgn, 1.2, 1.45, z0, z1, band)
		var y0 := 2.15 if unit else 2.3
		var y1 := 3.45 if unit else 3.3
		var stops: Array[float] = [z0 + 0.3]
		for d: float in doors:
			stops.append(d - 0.85)
			stops.append(d + 0.85)
		stops.append(z1 - 0.3)
		for k in range(0, stops.size(), 2):
			var a := stops[k]
			var b := stops[k + 1]
			if b - a < 0.8:
				continue
			# A dark band behind the panes, the panes in it with thin pillars.
			s.side_rect(x, sgn, y0 - 0.1, y1 + 0.1, a, b, dark)
			var panes := maxi(1, roundi((b - a) / 2.3))
			for q in panes:
				var pa := lerpf(a, b, float(q) / panes) + 0.08
				var pb := lerpf(a, b, float(q + 1) / panes) - 0.08
				s.side_rect(x + sgn * 0.006, sgn, y0, y1, pa, pb, lit)
		for d: float in doors:
			s.side_rect(x + sgn * 0.004, sgn, floor_y + 0.15, 3.35, d - 0.7, d + 0.7, door)
			s.side_rect(x + sgn * 0.01, sgn, 2.0, 3.15, d - 0.6, d - 0.06, glass)
			s.side_rect(x + sgn * 0.01, sgn, 2.0, 3.15, d + 0.06, d + 0.6, glass)
	if tail and role == 1:
		# The last coach's tail lamps, low on its end wall.
		for x: float in [-0.9, 0.9]:
			s.box(Vector3(x, 1.45, hl + 0.03), Vector3(0.3, 0.3, 0.08), lamp)
	# Under the floor: the skirt and two bogies.
	s.box(Vector3(0.0, 0.75, 0.0), Vector3(2.0 * W - 0.1, 0.5, CAR - 0.6), skirt)
	for z: float in [-hl + 3.0, hl - 3.0]:
		s.box(Vector3(0.0, 0.5, z), Vector3(2.4, 0.6, 2.8), dark)
	# The roof: air-conditioning boxes, the pantograph (over the cab, or two on a locomotive).
	if role != 2:
		for z: float in ([-hl * 0.45, hl * 0.45] if role == 1 else [hl * 0.35]):
			s.box(Vector3(0.0, top + 0.18, z), Vector3(1.8, 0.36, 3.2), roof)
	var pans: Array[float] = []
	if role == 0:
		pans = [-hl + nose + 2.4]
	elif role == 2:
		pans = [-hl * 0.45, hl * 0.45]
	for z: float in pans:
		s.box(Vector3(0.0, top + 0.12, z), Vector3(1.6, 0.12, 0.5), dark)
		s.box(Vector3(0.0, top + 0.45, z + 0.6), Vector3(0.1, 0.6, 1.4), dark)
		s.box(Vector3(0.0, top + 0.78, z + 1.2), Vector3(1.4, 0.06, 0.15), dark)
	return s.mesh()
