extends "res://scripts/landmarks/praga.gd"
## Kładka Magdaleny Abakanowicz, the footbridge from Karowa to Port Praski (F, 2026-11-20; spec
## docs/landmarks/specs/kladka.md). One link of landmarks.gd's base chain (TD-10): it may use this
## file, common.gd and the facade kit, never another area.
##
## The map (tools/kladka.py, a stamp-guarded post-pass) lays the bridge out and hands over what is
## built here in `data["kladka"]`: the centre line from the Powiśle end to the Praga end with the
## deck's walk height every few metres, the south ramp down to the boulevard, the two bays at the
## bends, the seven supports and the Warsaw meridian. map_builder.gd draws nothing of its deck
## pieces (`kl`), so everything seen of the bridge is here, in the city's building surface (+0 draw
## calls): the light grey concrete walk; at the bends the stepped wooden seats facing across the
## deck and the boardwalk with its long benches; the railings of rust posts and grey steel mesh
## under a steel handrail with the warm LED strip on its inner side; the deck's rust-painted edge
## (it glows warm at night, the dusk photo's lit underside) on a rust box girder; the white
## concrete supports flaring under the girder, the two in the main current in their rings of timber
## piles; the red meridian line across the walk.
##
## Colliders: the railings over the drop (`guard_deck`), the seat blocks and benches (`prop`) and
## the supports (`pier`). The walk itself is the deck pieces' ground (map_builder `ground_height`).

const KL_DECK := Color("#bdb8af")
const KL_DECK_EDGE := Color("#a9a49b")
const KL_RUST := Color("#8c4c2f")
const KL_RUST_DARK := Color("#6f3c26")
const KL_MESH := Color("#5f6264")
const KL_RAIL := Color("#c9ccce")
const KL_LED := Color("#f3d29a")
const KL_GLOW := Color("#3e3427")
const KL_SEAT := Color("#7b5132")
const KL_SEAT_TOP := Color("#8e6140")
const KL_WALK := Color("#b27b47")
const KL_BENCH := Color("#6d4a2f")
const KL_PIER := Color("#e7e4dd")
const KL_PILE := Color("#4c3d2e")
const KL_RED := Color("#c3352b")
## The deck's build step along the line (m), and the railing posts' spacing.
const KL_STEP := 6.0
const KL_POST := 3.2
## The railing: its height over the walk, the mesh's bottom and top, the handrail's width.
const KL_RAIL_H := 1.15
const KL_MESH_Y := Vector2(0.1, 1.0)
const KL_RAIL_W := 0.12
## The slab's edge (the rust fascia) and the box girder under it: [half width at its top, at its
## bottom]. The girder's depth is the map's `girder` (to the supports' heads).
const KL_FASCIA := 0.55
const KL_BOX := Vector2(2.5, 1.5)
## A seat row's rise and the seats' back wall over the top row (height, thickness).
const KL_ROW := 0.42
const KL_BACK := Vector2(0.75, 0.35)
## Seats are built where the bay is at least this much wider than the deck.
const KL_SEAT_MIN := 1.2
## The supports: the column's half size (across, along), how far its head flares out, how tall the
## flare is. The rings of timber piles: their half size round the column, pile spacing, top over the
## water. Which supports stand in a ring (index into the map's list).
const KL_COL := Vector2(1.7, 1.1)
const KL_FLARE := Vector2(0.6, 0.25)
const KL_FLARE_H := 1.8
const KL_RING := Vector2(4.2, 3.0)
const KL_PILE_GAP := 1.1
const KL_PILE_UP := 1.3
const KL_RINGED := [1, 2]

var _kl_line := PackedVector3Array()
var _kl_cum := PackedFloat32Array()


func _find_kladka() -> void:
	var st: Dictionary = data.get("kladka", {})
	if int(st.get("v", 0)) < 1:
		return
	var line := _kl_triples(st["line"])
	if line.size() < 2:
		return
	var half := float(st["half"])
	var wide := half
	for b: Array in st["bays"]:
		wide = maxf(wide, half + float(b[3]))
	# The zone: the deck's strip grown to its widest bay, in one polygon down each side.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in line.size():
		var p := Vector2(line[i].x, line[i].z)
		var a := Vector2(line[maxi(i - 1, 0)].x, line[maxi(i - 1, 0)].z)
		var b := Vector2(line[mini(i + 1, line.size() - 1)].x, line[mini(i + 1, line.size() - 1)].z)
		var d := (b - a).normalized()
		var r := Vector2(-d.y, d.x)
		left.append(p - r * (wide + 0.5))
		right.append(p + r * (wide + 0.5))
	right.reverse()
	left.append_array(right)
	_add_site("kladka", [left])


static func _kl_triples(flat: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(0, flat.size() - 2, 3):
		out.append(Vector3(float(flat[i]), float(flat[i + 2]), float(flat[i + 1])))
	return out


## Position (walk height in y) and unit direction along the line at s.
static func _kl_at(line: PackedVector3Array, cum: PackedFloat32Array, s: float) -> Array:
	s = clampf(s, 0.0, cum[cum.size() - 1])
	var k := 0
	while k < line.size() - 2 and cum[k + 1] < s:
		k += 1
	var t := (s - cum[k]) / maxf(cum[k + 1] - cum[k], 0.001)
	var p := line[k].lerp(line[k + 1], t)
	# The direction over 6 m round s, so a bend's two sides share one normal at its vertex.
	var a := _kl_pos(line, cum, maxf(s - 3.0, 0.0))
	var b := _kl_pos(line, cum, minf(s + 3.0, cum[cum.size() - 1]))
	var d := Vector2(b.x - a.x, b.z - a.z).normalized()
	return [p, d]


static func _kl_pos(line: PackedVector3Array, cum: PackedFloat32Array, s: float) -> Vector3:
	var k := 0
	while k < line.size() - 2 and cum[k + 1] < s:
		k += 1
	return line[k].lerp(line[k + 1], clampf((s - cum[k]) / maxf(cum[k + 1] - cum[k], 0.001), 0.0, 1.0))


static func _kl_cumulate(line: PackedVector3Array) -> PackedFloat32Array:
	var cum := PackedFloat32Array([0.0])
	for i in range(1, line.size()):
		cum.append(cum[i - 1] + Vector2(line[i].x - line[i - 1].x, line[i].z - line[i - 1].z).length())
	return cum


## How much wider than the deck the bay on `side` is at s (0 outside the bays): a lens, full between
## its tapers, smoothly in and out over `taper` m.
static func _kl_extra(bays: Array, taper: float, s: float, side: int) -> float:
	var e := 0.0
	for b: Array in bays:
		if int(b[2]) != side:
			continue
		var s0 := float(b[0])
		var s1 := float(b[1])
		if s <= s0 or s >= s1:
			continue
		var f := minf(clampf((s - s0) / taper, 0.0, 1.0), clampf((s1 - s) / taper, 0.0, 1.0))
		e = maxf(e, float(b[3]) * f * f * (3.0 - 2.0 * f))
	return e


## The seat rows of the bay on `side` at s (0: none, or a boardwalk).
static func _kl_rows(bays: Array, s: float, side: int) -> int:
	for b: Array in bays:
		if int(b[2]) == side and s > float(b[0]) and s < float(b[1]):
			return int(b[4])
	return 0


func _build_kladka(_site: Dictionary) -> void:
	var st: Dictionary = data.get("kladka", {})
	var line := _kl_triples(st["line"])
	var cum := _kl_cumulate(line)
	var ramp := _kl_triples(st.get("ramp", []))
	var half := float(st["half"])
	var bays: Array = st["bays"]
	var taper := float(st["taper"])
	var girder := float(st["girder"])
	var meridian := float(st.get("meridian", -1.0))
	var total := cum[cum.size() - 1]
	_no_roof = true
	_mode = M_STONE
	_g = line[0].y
	# The build's stations: every KL_STEP m, plus each bay's ends and full width, and the meridian
	# line's two edges (its strip of the walk is painted red).
	var ss: Array[float] = []
	var s := 0.0
	while s < total:
		ss.append(s)
		s += KL_STEP
	ss.append(total)
	for b: Array in bays:
		for v in [float(b[0]), float(b[0]) + taper, float(b[1]) - taper, float(b[1])]:
			ss.append(v)
	if meridian > 0.0:
		ss.append(meridian - 0.25)
		ss.append(meridian + 0.25)
	ss.sort()
	var stations: Array[float] = []
	for v in ss:
		if stations.is_empty() or v - stations[-1] > 0.2:
			stations.append(v)
	# The main deck, from the Powiśle end to the Praga end.
	_kl_deck(line, cum, stations, half, bays, taper, girder, meridian, ramp, float(st.get("ramp_half", 2.4)), false)
	# The south ramp, down to the boulevard, where it is not on the main deck.
	if ramp.size() >= 2:
		var ramp_cum := _kl_cumulate(ramp)
		var rs: Array[float] = []
		s = 0.0
		while s < ramp_cum[ramp_cum.size() - 1]:
			rs.append(s)
			s += KL_STEP
		rs.append(ramp_cum[ramp_cum.size() - 1])
		_kl_deck(ramp, ramp_cum, rs, float(st.get("ramp_half", 2.4)), [], taper, girder * 0.7, -1.0, line, half, true)
	# The supports.
	var piers: Array = st["piers"]
	for i in piers.size():
		var at: Array = _kl_at(line, cum, float(piers[i]))
		_kl_support(at[0], at[1], girder, KL_RINGED.has(i))
	_no_roof = false


## Whether p lies on the other deck's walk (its corridor between its ends), so this deck's railing,
## slab and girder stop there (the fork where the south ramp meets the deck).
func _kl_on_other(p: Vector2, other: PackedVector3Array, other_half: float) -> bool:
	for k in other.size() - 1:
		var a := Vector2(other[k].x, other[k].z)
		var b := Vector2(other[k + 1].x, other[k + 1].z)
		var ab := b - a
		var u := (p - a).dot(ab) / maxf(ab.length_squared(), 0.000001)
		if u < 0.0 or u > 1.0:
			continue
		if p.distance_to(a + ab * u) < other_half - 0.05:
			return true
	return false


func _kl_deck(line: PackedVector3Array, cum: PackedFloat32Array, stations: Array[float], half: float, bays: Array,
		taper: float, girder: float, meridian: float, other: PackedVector3Array, other_half: float, yields: bool) -> void:
	var has_other := other.size() >= 2
	# Per station: the walk's centre, its right, the two edges (bays included).
	var cs: Array[Vector3] = []
	var rs: Array[Vector2] = []
	var el: Array[float] = []
	var er: Array[float] = []
	for s in stations:
		var at: Array = _kl_at(line, cum, s)
		var d: Vector2 = at[1]
		cs.append(at[0])
		rs.append(Vector2(-d.y, d.x))
		el.append(half + _kl_extra(bays, taper, s, -1))
		er.append(half + _kl_extra(bays, taper, s, 1))
	for i in stations.size() - 1:
		var c0 := cs[i]
		var c1 := cs[i + 1]
		var r0 := rs[i]
		var r1 := rs[i + 1]
		var mid := (Vector2(c0.x, c0.z) + Vector2(c1.x, c1.z)) * 0.5
		var smid := (stations[i] + stations[i + 1]) * 0.5
		# Where the ramp runs on the deck's walk (the fork), the deck draws it.
		if yields and _kl_on_other(mid, other, other_half):
			continue
		var red := meridian > 0.0 and absf(smid - meridian) < 0.3
		# The walk in three strips: the deck (concrete), and each bay (the boardwalk's timber or the
		# concrete under the seats).
		var a_in := _kl_pt(c0, r0, -half)
		var b_in := _kl_pt(c1, r1, -half)
		var a_out := _kl_pt(c0, r0, half)
		var b_out := _kl_pt(c1, r1, half)
		# The walk goes into the roof grid (the heli lands on it, a tap finds the bridge); the rest
		# (girder, railings, supports) stays out of it.
		_no_roof = false
		_quad(a_in, b_in, b_out, a_out, Vector3.UP, KL_RED if red else KL_DECK)
		_no_roof = true
		for side: int in [-1, 1]:
			var e0 := el[i] if side < 0 else er[i]
			var e1 := el[i + 1] if side < 0 else er[i + 1]
			var p0 := _kl_pt(c0, r0, side * half)
			var p1 := _kl_pt(c1, r1, side * half)
			var q0 := _kl_pt(c0, r0, side * e0)
			var q1 := _kl_pt(c1, r1, side * e1)
			if e0 > half + 0.05 or e1 > half + 0.05:
				var rows := _kl_rows(bays, smid, side)
				# A bay's first and last strip start at no width: 6 cm there, so no triangle is a sliver.
				_quad(p0, p1, _kl_pt(c1, r1, side * maxf(e1, half + 0.06)), _kl_pt(c0, r0, side * maxf(e0, half + 0.06)),
						Vector3.UP, KL_WALK if rows == 0 else KL_DECK)
				if rows > 0 and minf(e0, e1) - half >= KL_SEAT_MIN:
					_kl_seats(c0, c1, r0, r1, side, half, e0, e1, rows)
				elif rows == 0 and minf(e0, e1) - half >= 2.4:
					_kl_bench(c0, c1, r0, r1, side, half + 0.45)
			# The slab's rust edge (lit warm at night) and the girder's side under it.
			var n := Vector3(r0.x + r1.x, 0.0, r0.y + r1.y).normalized() * side
			_mode = M_MEMBRANE + 0.5
			_quad(q0, q1, q1 - Vector3(0, KL_FASCIA, 0), q0 - Vector3(0, KL_FASCIA, 0), n, KL_RUST)
			_mode = M_STONE
			var g0 := _kl_pt(c0, r0, side * KL_BOX.x) - Vector3(0, KL_FASCIA, 0)
			var g1 := _kl_pt(c1, r1, side * KL_BOX.x) - Vector3(0, KL_FASCIA, 0)
			var h0 := _kl_pt(c0, r0, side * KL_BOX.y) - Vector3(0, girder, 0)
			var h1 := _kl_pt(c1, r1, side * KL_BOX.y) - Vector3(0, girder, 0)
			var gn := (n + Vector3(0, -0.45, 0)).normalized()
			_quad(g0, g1, h1, h0, gn, KL_RUST_DARK)
			# The soffit from the slab's edge in to the girder's top (seen from a low camera).
			_quad(q0 - Vector3(0, KL_FASCIA, 0), q1 - Vector3(0, KL_FASCIA, 0), g1, g0, Vector3.DOWN, KL_RUST_DARK)
			# The railing on the edge, where it is not the seats' back wall, and its collider.
			var seated := _kl_rows(bays, smid, side) > 0 and minf(e0, e1) - half >= KL_SEAT_MIN
			var ra := _kl_pt(c0, r0, side * (e0 - 0.08))
			var rb := _kl_pt(c1, r1, side * (e1 - 0.08))
			if has_other and (_kl_on_other(Vector2(ra.x, ra.z), other, other_half) or _kl_on_other(Vector2(rb.x, rb.z), other, other_half)):
				continue
			if not seated:
				_kl_railing(ra, rb, n)
			if maxf(ra.y - map.terrain_height(ra.x, ra.z), rb.y - map.terrain_height(rb.x, rb.z)) > 1.0:
				map._solid(&"guard_deck", PackedVector3Array([ra - Vector3(0, 0.2, 0), rb - Vector3(0, 0.2, 0), rb + Vector3(0, 1.6, 0),
						ra - Vector3(0, 0.2, 0), rb + Vector3(0, 1.6, 0), ra + Vector3(0, 1.6, 0)]), _r2)
	# The posts along both edges, every KL_POST m.
	var sp := stations[0] + KL_POST * 0.5
	while sp < stations[-1]:
		var at: Array = _kl_at(line, cum, sp)
		var c: Vector3 = at[0]
		var d: Vector2 = at[1]
		var r := Vector2(-d.y, d.x)
		for side: int in [-1, 1]:
			var e := half + _kl_extra(bays, taper, sp, side)
			if _kl_rows(bays, sp, side) > 0 and e - half >= KL_SEAT_MIN:
				continue
			var p := _kl_pt(c, r, side * (e - 0.08))
			if has_other and _kl_on_other(Vector2(p.x, p.z), other, other_half):
				continue
			_kl_post(p, d, r * side)
		sp += KL_POST


func _kl_pt(c: Vector3, r: Vector2, t: float) -> Vector3:
	return Vector3(c.x + r.x * t, c.y, c.z + r.y * t)


## One railing panel from a to b (on the walk at the edge): the grey mesh (both faces), the steel
## handrail on top and the LED strip under it on the walk's side (M_LAMP: warm at night).
func _kl_railing(a: Vector3, b: Vector3, out: Vector3) -> void:
	var up := Vector3.UP
	_quad(a + up * KL_MESH_Y.x, b + up * KL_MESH_Y.x, b + up * KL_MESH_Y.y, a + up * KL_MESH_Y.y, out, KL_MESH)
	_quad(a + up * KL_MESH_Y.x, b + up * KL_MESH_Y.x, b + up * KL_MESH_Y.y, a + up * KL_MESH_Y.y, -out, KL_MESH.darkened(0.1))
	var w := out * KL_RAIL_W * 0.5
	var top := up * KL_RAIL_H
	_quad(a + top - w, b + top - w, b + top + w, a + top + w, up, KL_RAIL)
	_quad(a + top - w - up * 0.1, b + top - w - up * 0.1, b + top - w, a + top - w, -out, KL_RAIL.darkened(0.12))
	_quad(a + top + w - up * 0.1, b + top + w - up * 0.1, b + top + w, a + top + w, out, KL_RAIL.darkened(0.2))
	_mode = M_LAMP
	_quad(a + top - w - up * 0.1, b + top - w - up * 0.1, b + top + w - up * 0.1, a + top + w - up * 0.1, Vector3.DOWN, KL_LED)
	# The warm light's line along the walk at the railing's foot (dark by day, a glow at night).
	var g := -out * 0.3
	_quad(a + up * 0.04, b + up * 0.04, b + g + up * 0.04, a + g + up * 0.04, up, KL_GLOW)
	_mode = M_STONE


## A rust post: its outer, inner and one side face.
func _kl_post(p: Vector3, d: Vector2, out: Vector2) -> void:
	var along := Vector3(d.x, 0.0, d.y) * 0.05
	var o := Vector3(out.x, 0.0, out.y) * 0.065
	var h := Vector3(0, KL_RAIL_H - 0.06, 0)
	_quad(p + o - along, p + o + along, p + o + along + h, p + o - along + h, o.normalized(), KL_RUST)
	_quad(p - o - along, p - o + along, p - o + along + h, p - o - along + h, -o.normalized(), KL_RUST)
	_quad(p - o + along, p + o + along, p + o + along + h, p - o + along + h, along.normalized(), KL_RUST_DARK)


## The stepped wooden seats of a bay between two stations: `rows` steps rising from the deck's edge
## out to the back wall on the bay's outer edge, the sitters facing across the deck. Solid (`prop`).
func _kl_seats(c0: Vector3, c1: Vector3, r0: Vector2, r1: Vector2, side: int, half: float, e0: float, e1: float, rows: int) -> void:
	var n := Vector3(r0.x + r1.x, 0.0, r0.y + r1.y).normalized() * side
	var start := half + 0.3
	var back0 := e0 - KL_BACK.y
	var back1 := e1 - KL_BACK.y
	for k in rows:
		var t0a := lerpf(start, back0, float(k) / rows)
		var t0b := lerpf(start, back1, float(k) / rows)
		var t1a := lerpf(start, back0, float(k + 1) / rows)
		var t1b := lerpf(start, back1, float(k + 1) / rows)
		var y := KL_ROW * (k + 1)
		var fa := _kl_pt(c0, r0, side * t0a)
		var fb := _kl_pt(c1, r1, side * t0b)
		var ba := _kl_pt(c0, r0, side * t1a)
		var bb := _kl_pt(c1, r1, side * t1b)
		# The riser facing the deck, then the seat's top.
		_quad(fa + Vector3(0, y - KL_ROW, 0), fb + Vector3(0, y - KL_ROW, 0), fb + Vector3(0, y, 0), fa + Vector3(0, y, 0), -n, KL_SEAT)
		_quad(fa + Vector3(0, y, 0), fb + Vector3(0, y, 0), bb + Vector3(0, y, 0), ba + Vector3(0, y, 0), Vector3.UP, KL_SEAT_TOP)
	# The back wall on the outer edge: its inner face, rust top, outer face.
	var top := KL_ROW * rows + KL_BACK.x
	var ia := _kl_pt(c0, r0, side * back0)
	var ib := _kl_pt(c1, r1, side * back1)
	var oa := _kl_pt(c0, r0, side * e0)
	var ob := _kl_pt(c1, r1, side * e1)
	var yr := Vector3(0, KL_ROW * rows, 0)
	var yt := Vector3(0, top, 0)
	_quad(ia + yr, ib + yr, ib + yt, ia + yt, -n, KL_SEAT)
	_quad(ia + yt, ib + yt, ob + yt, oa + yt, Vector3.UP, KL_RUST)
	_quad(oa, ob, ob + yt, oa + yt, n, KL_SEAT.darkened(0.15))
	# Solid: the first riser's line (the car meets the steps' face) up to the back wall's top.
	var sa := _kl_pt(c0, r0, side * start)
	var sb := _kl_pt(c1, r1, side * start)
	map._solid(&"prop", PackedVector3Array([sa - Vector3(0, 0.2, 0), sb - Vector3(0, 0.2, 0), sb + yt,
			sa - Vector3(0, 0.2, 0), sb + yt, sa + yt]), _r2)


## A long low timber bench on a boardwalk, along the deck between two stations (with a gap at each
## end, so a run of them reads as separate benches). Solid (`prop`).
func _kl_bench(c0: Vector3, c1: Vector3, r0: Vector2, r1: Vector2, side: int, t: float) -> void:
	var a := _kl_pt(c0, r0, side * t).lerp(_kl_pt(c1, r1, side * t), 0.12)
	var b := _kl_pt(c0, r0, side * t).lerp(_kl_pt(c1, r1, side * t), 0.88)
	var d := Vector2(b.x - a.x, b.z - a.z).normalized()
	var o := Vector3(-d.y, 0.0, d.x) * 0.3 * side
	var y := Vector3(0, 0.45, 0)
	_quad(a - o + y, b - o + y, b + o + y, a + o + y, Vector3.UP, KL_SEAT_TOP)
	_quad(a - o, b - o, b - o + y, a - o + y, -o.normalized(), KL_BENCH)
	_quad(a + o, b + o, b + o + y, a + o + y, o.normalized(), KL_BENCH)
	var along := Vector3(d.x, 0.0, d.y)
	_quad(a - o, a + o, a + o + y, a - o + y, -along, KL_BENCH.darkened(0.1))
	_quad(b - o, b + o, b + o + y, b - o + y, along, KL_BENCH.darkened(0.1))
	map._solid(&"prop", PackedVector3Array([a - o, b - o, b - o + y * 2.0, a - o, b - o + y * 2.0, a - o + y * 2.0]), _r2)


## A white concrete support under the girder at `c` (the walk's centre over it): an elongated
## octagon column from the river bed or the floodplain flaring out under the girder; in the main
## current a ring of timber piles round it with lights on some tops (the dusk photo).
func _kl_support(c: Vector3, d: Vector2, girder: float, ringed: bool) -> void:
	var r := Vector2(-d.y, d.x)
	var p := Vector2(c.x, c.z)
	var ground: float = map.terrain_height(p.x, p.y)
	var top := c.y - girder
	if top - ground < 1.0:
		return
	var foot := ground - 1.0
	var col := _kl_oct(p, r, d, KL_COL.x, KL_COL.y, 0.45)
	var head := _kl_oct(p, r, d, KL_COL.x + KL_FLARE.x, KL_COL.y + KL_FLARE.y, 0.6)
	var neck := minf(top - KL_FLARE_H, top - 0.5)
	_prism(col, foot, neck, KL_PIER, Color(0, 0, 0, 0))
	_frustum(col, neck, head, top, KL_PIER.darkened(0.04), KL_PIER)
	# Two black floodlights on the column's sides, aimed up at the girder.
	for side: float in [-1.0, 1.0]:
		var q := p + r * side * (KL_COL.x + 0.15)
		_lbox_at(q, 0.18, neck - 0.6, neck - 0.25, Color("#24262a"))
	_collide_span(head, foot, top)
	if not ringed:
		return
	# The ring of timber piles in the water, round the column (a fender), every third one lit.
	var water: float = ground
	var corners: Array[Vector2] = [p - r * KL_RING.x - d * KL_RING.y, p + r * KL_RING.x - d * KL_RING.y,
			p + r * KL_RING.x + d * KL_RING.y, p - r * KL_RING.x + d * KL_RING.y]
	var count := 0
	for k in 4:
		var a := corners[k]
		var b := corners[(k + 1) % 4]
		var n := maxi(1, int(a.distance_to(b) / KL_PILE_GAP))
		for j in n:
			var q := a.lerp(b, float(j) / n)
			var lit := count % 3 == 0
			_prism(_circle(q, 0.2, 5), water - 0.5, water + KL_PILE_UP, KL_PILE, KL_PILE)
			if lit:
				_prism(_circle(q, 0.21, 5), water + KL_PILE_UP, water + KL_PILE_UP + 0.12, KL_LED, KL_LED, M_LAMP, M_LAMP)
			count += 1
	var ring := PackedVector2Array(corners)
	_collide_span(ring, water - 0.5, water + KL_PILE_UP)


## An elongated octagon round p: `hr` across (along r), `hd` along (along d), corners cut by `cut`.
func _kl_oct(p: Vector2, r: Vector2, d: Vector2, hr: float, hd: float, cut: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in [Vector2(hr, hd - cut), Vector2(hr - cut, hd), Vector2(-hr + cut, hd), Vector2(-hr, hd - cut),
			Vector2(-hr, -hd + cut), Vector2(-hr + cut, -hd), Vector2(hr - cut, -hd), Vector2(hr, -hd + cut)]:
		out.append(p + r * q.x + d * q.y)
	return out


## The people who stay on the bridge (F, 2026-11-20: "people sit there like on the steps"), for
## crowds.gd's `kladka` site: pure, from the map's stamp alone (no node), so a check can read it.
## "seats": [point, yaw, height, group] on the seat rows of the seated bays, in groups of 2-6 facing
## across the deck; on the boardwalks' benches facing the river. "standing": [point, yaw, height] at
## the railing over the water in ones to threes facing out, and a pair on the meridian line (the
## selfie). Yaw as the crowd's: a figure faces (-sin yaw, -cos yaw).
static func kladka_plan(st: Dictionary) -> Dictionary:
	var out := {"seats": [], "standing": [], "centre": Vector2.ZERO}
	if int(st.get("v", 0)) < 1:
		return out
	var line := _kl_triples(st["line"])
	if line.size() < 2:
		return out
	var cum := _kl_cumulate(line)
	var half := float(st["half"])
	var bays: Array = st["bays"]
	var taper := float(st["taper"])
	var total := cum[cum.size() - 1]
	var mid: Array = _kl_at(line, cum, total * 0.5)
	out["centre"] = Vector2((mid[0] as Vector3).x, (mid[0] as Vector3).z)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var seats: Array = []
	var gid := 0
	for b: Array in bays:
		var side := int(b[2])
		var rows := int(b[4])
		var s := float(b[0]) + taper * 0.4
		while s < float(b[1]) - taper * 0.4:
			var e := _kl_extra(bays, taper, s, side)
			var size: int = [2, 2, 3, 3, 4, 5, 6][rng.randi() % 7]
			if rng.randf() < 0.3 or e < (KL_SEAT_MIN if rows > 0 else 2.4):
				s += rng.randf_range(2.0, 5.0)
				continue
			var k := rng.randi() % maxi(rows, 1)
			for i in size:
				var at: Array = _kl_at(line, cum, s + i * 0.62)
				var c: Vector3 = at[0]
				var d: Vector2 = at[1]
				var r := Vector2(-d.y, d.x) * side
				var p: Vector2
				var face: Vector2
				var y := c.y
				if rows > 0:
					var e2 := _kl_extra(bays, taper, s + i * 0.62, side)
					var t := lerpf(half + 0.3, half + e2 - KL_BACK.y, (k + 0.6) / rows)
					p = Vector2(c.x, c.z) + r * t
					face = -r
					y += KL_ROW * (k + 1)
				else:
					p = Vector2(c.x, c.z) + r * (half + 0.45)
					face = r
					y += 0.45
				var f := face.rotated(rng.randf_range(-0.35, 0.35))
				seats.append([p, atan2(-f.x, -f.y), y, gid])
			gid += 1
			s += size * 0.62 + rng.randf_range(1.5, 4.0)
	out["seats"] = seats
	# At the railing over the river, off the bays: ones to threes looking out (more on the
	# downstream side, the Old Town's view), and the meridian pair.
	var standing: Array = []
	var s := 40.0
	while s < minf(300.0, total - 20.0):
		var side := 1 if rng.randf() < 0.4 else -1
		if _kl_extra(bays, taper, s, side) > 0.05 or _kl_extra(bays, taper, s, -side) > 0.05:
			s += 6.0
			continue
		var n := rng.randi_range(1, 3)
		for i in n:
			var at: Array = _kl_at(line, cum, s + i * 0.65)
			var c: Vector3 = at[0]
			var d: Vector2 = at[1]
			var r := Vector2(-d.y, d.x) * side
			var p := Vector2(c.x, c.z) + r * (half - 0.45)
			var f := r.rotated(rng.randf_range(-0.3, 0.3))
			standing.append([p, atan2(-f.x, -f.y), c.y])
		s += rng.randf_range(9.0, 22.0)
	var mer := float(st.get("meridian", -1.0))
	if mer > 0.0:
		var at: Array = _kl_at(line, cum, mer)
		var c: Vector3 = at[0]
		var d: Vector2 = at[1]
		var r := Vector2(-d.y, d.x)
		for side: float in [-0.5, 0.5]:
			var p := Vector2(c.x, c.z) + r * side
			var f := -r * signf(side)  # the two face each other across the line
			standing.append([p, atan2(-f.x, -f.y), c.y])
	out["standing"] = standing
	return out
