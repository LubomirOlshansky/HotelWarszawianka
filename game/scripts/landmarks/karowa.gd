extends "res://scripts/landmarks/kladka.gd"
## Karowa's serpentine (F, 2026-11-20; spec docs/landmarks/specs/wiadukt_markiewicza.md). One link of
## landmarks.gd's base chain (TD-10): it may use this file, common.gd and the facade kit, never
## another area.
##
## Wiadukt Markiewicza (1902-1904, Stefan Szyller, engineer Karol Sommer; sculpture Jan Woydyga):
## the curved viaduct that carries Karowa over itself on its way down the escarpment. Measured on
## the orthophoto and the map: every part of it is concentric round MK_C. The deck is a ring from
## MK_IN (the face over the pit inside the loop) to MK_OUT (the outer face over the lower road),
## from bearing MK_A0 to MK_A1 (degrees of atan2(z, x) round MK_C), and the two one-way passages
## under it are radial, at MK_ARCH, each MK_ARCH_HW either side of its line: a narrow pier between
## the arches on the inner face, a wide one on the outer face, as the old drawings give (3.76 m and
## 14.98 m). Built here, in the city's building surface (+0 draw calls): the cream sandstone faces
## with a granite plinth, pilasters at the arches, an impost band, the grey spandrels and the cream
## archivolt with its keystone, a frieze and the cornice; the barrel vaults through; the deck's
## paving and kerbs between the map's ribbons; the balustrade on both faces with its double-pitched
## rail; eight obelisk lamp posts with their lanterns (lit at night); Woydyga's Syrena on the inner
## face over the central pier, facing the pit, and the allegorical group (Warsaw with her mural
## crown and the book, Labour with the cogwheel, the Vistula's medallion and the torch over them)
## in the middle of the outer balustrade.
##
## map_builder.gd and city_barriers.gd leave the ring to this model (`mk_covers`): the bake's deck
## slab and parapets, the tunnel portals, the tunnel side walls, the deck's railings and lamps; the
## guard lines along the roadway keep their colliders and are drawn as kerbs here. The colliders
## of the faces, the passages' sides and the balustrades are filed here.
##
## And by the loop, the memorial to Krzysztof "Szaya" Szaykowski (died 2018), the voice of the
## Barbórka rally's Kryterium Asów on Karowa: a granite stone with a plaque (site `szaja`; where it
## stands and how it looks waits for F's photo, docs/QUESTIONS.md).

const MK_C := Vector2(-336.0, -939.0)
const MK_IN := 29.5
const MK_OUT := 50.4
const MK_A0 := 12.0
const MK_A1 := 92.0
const MK_ARCH: Array[float] = [37.9, 68.3]
const MK_ARCH_HW := 5.95
## The deck's walk height: MK_DECK.y at bearing MK_DECK.x, rising MK_DECK.z a degree westwards
## (the map's road piece, -3.43 at 16.2 to -2.46 at 88.6).
const MK_DECK := Vector3(16.2, -3.43, 0.0134)
## The lower road at each passage's two mouths [inner, outer] (the map's tunnel pieces).
const MK_FLOOR := [Vector2(-7.81, -8.53), Vector2(-7.75, -8.05)]
## The arches: spring over the road, crown under the deck's walk.
const MK_SPRING := 1.1
const MK_CROWN := 0.85
## The roadway's kerbs on the deck (the map's guard lines, the road ribbon's edges).
const MK_KERB := Vector2(36.95, 42.85)
## The obelisk lamp posts: [face (-1 inner, 1 outer), bearing].
const MK_OBELISKS := [[-1, 13.5], [-1, 24.0], [-1, 82.0], [-1, 90.5], [1, 19.0], [1, 44.0], [1, 62.0], [1, 86.0]]
## The bearing of the central pier (the Syrena inside, the group outside).
const MK_MID := 53.1
## Build steps (degrees): the faces and bands, and inside an arch.
const MK_STEP := 2.0
const MK_ARCH_STEP := 0.9

const MK_STONE := PAL_SANDSTONE
const MK_TRIM := PAL_CREAM_STONE
const MK_SPANDREL := Color("#b9b2a3")  # the grey render of the spandrels (F's photo 2)
const MK_PLINTH := PAL_WARM_GRANITE
const MK_VAULT := Color("#cfc4ad")
const MK_PAVING := Color("#b5afa4")
const MK_SETTS := Color("#8f8a83")
const MK_FIGURE := Color("#d6cab0")  # the sandstone figures, paler than the walls
const MK_GLASS := Color("#ffd9a0")

## The memorial to "Szaya": its spot (the loop's island, facing the viaduct) and facing.
const SZ_AT := Vector2(-321.5, -945.5)
const SZ_FACE := Vector2(0.45, 0.89)


# --- the plan, shared with map_builder.gd and city_barriers.gd ---------------------------------

## Whether plan point p lies on the viaduct's ring (grown by `grow` metres all round): the bake's
## own structures there are left to this model.
static func mk_covers(p: Vector2, grow := 0.0) -> bool:
	var d := p - MK_C
	var r := d.length()
	if r < MK_IN - 1.0 - grow or r > MK_OUT + 1.0 + grow:
		return false
	var a := rad_to_deg(atan2(d.y, d.x))
	var pad := rad_to_deg((1.0 + grow) / r)
	return a >= MK_A0 - pad and a <= MK_A1 + pad


## Whether every point of a flat [x, z, x, z ...] line lies on the ring.
static func mk_covers_line(flat: Array, grow := 0.0) -> bool:
	if flat.size() < 2:
		return false
	for i in range(0, flat.size() - 1, 2):
		if not mk_covers(Vector2(float(flat[i]), float(flat[i + 1])), grow):
			return false
	return true


static func _mk_p(r: float, a: float) -> Vector2:
	return MK_C + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * r


## The deck's walk height at bearing a.
static func _mk_y(a: float) -> float:
	return MK_DECK.y + (clampf(a, MK_A0 - 2.0, MK_A1 + 2.0) - MK_DECK.x) * MK_DECK.z


## The lower road's height by a face at bearing a (inner face: the pit; outer: the lower road).
static func _mk_floor(a: float, outer: bool) -> float:
	var f0: Vector2 = MK_FLOOR[0]
	var f1: Vector2 = MK_FLOOR[1]
	var t := clampf((a - MK_ARCH[0]) / (MK_ARCH[1] - MK_ARCH[0]), -0.3, 1.3)
	return lerpf(f0.y, f1.y, t) if outer else lerpf(f0.x, f1.x, t)


## The arch's soffit height at lateral offset x from its line, between spring and crown (a
## segment of a circle: the arches are wide and low).
static func _mk_arch_y(x: float, spring: float, crown: float) -> float:
	var rise := maxf(crown - spring, 0.3)
	var rs := (rise * rise + MK_ARCH_HW * MK_ARCH_HW) / (2.0 * rise)
	var ax := minf(absf(x), MK_ARCH_HW)
	return crown - rs + sqrt(maxf(rs * rs - ax * ax, 0.0))


## Which arch (index) the face at radius r crosses at bearing a, and the lateral offset there;
## [-1, 0] outside both.
static func _mk_in_arch(r: float, a: float) -> Array:
	for k in MK_ARCH.size():
		var x := r * sin(deg_to_rad(a - MK_ARCH[k]))
		if absf(x) < MK_ARCH_HW - 0.001 and absf(a - MK_ARCH[k]) < 30.0:
			return [k, x]
	return [-1, 0.0]


func _find_markiewicz() -> void:
	var inner := PackedVector2Array()
	var outer := PackedVector2Array()
	var a := MK_A0 - 1.0
	while a <= MK_A1 + 1.01:
		inner.append(_mk_p(MK_IN - 1.0, a))
		outer.append(_mk_p(MK_OUT + 1.6, a))
		a += 4.0
	outer.reverse()
	inner.append_array(outer)
	_add_site("wiadukt_markiewicza", [inner])


func _find_szaja() -> void:
	_add_site("szaja", [_square(SZ_AT, 1.4)])


# --- the viaduct ----------------------------------------------------------------------------

func _build_markiewicz(_site: Dictionary) -> void:
	_g = _mk_y(MK_MID)
	_mode = M_STONE
	for outer in [false, true]:
		_mk_face(outer)
	for k in MK_ARCH.size():
		_mk_vault(k)
	_mk_deck()
	for outer in [false, true]:
		_mk_balustrade(outer)
	for o: Array in MK_OBELISKS:
		_mk_obelisk(int(o[0]) > 0, float(o[1]))
	_mk_syrena()
	_mk_group()
	_mode = M_STONE


## The face's stations (degrees): every MK_STEP, finer inside the arches, and each arch's edges.
func _mk_stations(r: float) -> Array[float]:
	var ss: Array[float] = []
	var a := MK_A0
	while a < MK_A1:
		ss.append(a)
		a += MK_STEP
	ss.append(MK_A1)
	for phi: float in MK_ARCH:
		var half := rad_to_deg(asin(MK_ARCH_HW / r))
		var b := phi - half
		while b < phi + half:
			ss.append(b)
			b += MK_ARCH_STEP
		ss.append(phi + half)
	ss.sort()
	var out: Array[float] = []
	for v in ss:
		if out.is_empty() or v - out[-1] > 0.05:
			out.append(v)
	return out


## The radius a face stands at, the way out of it (plan, unit) at bearing a.
func _mk_out(outer: bool, a: float) -> Vector2:
	var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
	return d if outer else -d


## A band along a face at radius r (out of it `proud` metres, facing out) from bearing a0 to a1,
## from deck height + y0 to deck height + y1 (or absolute heights when `deck` is false): its front,
## its top and its underside.
func _mk_band(r: float, outer: bool, a0: float, a1: float, y0: float, y1: float, proud: float, col: Color, deck := true) -> void:
	var sgn := 1.0 if outer else -1.0
	var n := ceili((a1 - a0) / MK_STEP)
	for i in n:
		var b0 := a0 + (a1 - a0) * i / n
		var b1 := a0 + (a1 - a0) * (i + 1) / n
		var p0 := _mk_p(r + sgn * proud, b0)
		var p1 := _mk_p(r + sgn * proud, b1)
		var q0 := _mk_p(r, b0)
		var q1 := _mk_p(r, b1)
		var lo0 := y0 + (_mk_y(b0) if deck else 0.0)
		var lo1 := y0 + (_mk_y(b1) if deck else 0.0)
		var hi0 := y1 + (_mk_y(b0) if deck else 0.0)
		var hi1 := y1 + (_mk_y(b1) if deck else 0.0)
		var o := _mk_out(outer, (b0 + b1) * 0.5)
		_quad(Vector3(p0.x, lo0, p0.y), Vector3(p1.x, lo1, p1.y), Vector3(p1.x, hi1, p1.y), Vector3(p0.x, hi0, p0.y),
				Vector3(o.x, 0.0, o.y), col)
		_quad(Vector3(q0.x, hi0, q0.y), Vector3(q1.x, hi1, q1.y), Vector3(p1.x, hi1, p1.y), Vector3(p0.x, hi0, p0.y),
				Vector3.UP, col.lightened(0.04))
		_quad(Vector3(q0.x, lo0, q0.y), Vector3(q1.x, lo1, q1.y), Vector3(p1.x, lo1, p1.y), Vector3(p0.x, lo0, p0.y),
				Vector3.DOWN, col.darkened(0.2))


## Sets the local frame at the face point (r, a): u along the face (westwards), v out of it.
func _mk_frame(r: float, a: float, outer: bool) -> void:
	_o = _mk_p(r, a)
	var o := _mk_out(outer, a)
	_b = o
	_a = Vector2(-o.y, o.x)


## One face of the ring: the wall from its foot (or an arch's soffit) to the deck, the plinth, the
## impost band, the pilasters, the archivolts and keystones, the frieze and the cornice, and its
## colliders at the lower level.
func _mk_face(outer: bool) -> void:
	var r := MK_OUT if outer else MK_IN
	var ss := _mk_stations(r)
	var feet: Array[float] = []
	for a in ss:
		var o := _mk_out(outer, a)
		var p := _mk_p(r, a) + o * 1.2
		feet.append(minf(map.terrain_height(p.x, p.y), _mk_floor(a, outer)) - 0.4)
	for i in ss.size() - 1:
		var a0 := ss[i]
		var a1 := ss[i + 1]
		var am := (a0 + a1) * 0.5
		var hit: Array = _mk_in_arch(r, am)
		var k := int(hit[0])
		var p0 := _mk_p(r, a0)
		var p1 := _mk_p(r, a1)
		var o := _mk_out(outer, am)
		var n := Vector3(o.x, 0.0, o.y)
		var y0 := feet[i]
		var y1 := feet[i + 1]
		var col := MK_STONE
		if k >= 0:
			var fl := _mk_floor(MK_ARCH[k], outer)
			var crown := _mk_y(MK_ARCH[k]) - MK_CROWN
			y0 = _mk_arch_y(r * sin(deg_to_rad(a0 - MK_ARCH[k])), fl + MK_SPRING, crown)
			y1 = _mk_arch_y(r * sin(deg_to_rad(a1 - MK_ARCH[k])), fl + MK_SPRING, crown)
			col = MK_SPANDREL
		_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y1, p1.y), Vector3(p1.x, _mk_y(a1), p1.y), Vector3(p0.x, _mk_y(a0), p0.y), n, col)
		if k < 0:
			# The lower level can't drive into the ring (a metre under the deck at most).
			map._solid(&"struct_wall", PackedVector3Array([Vector3(p0.x, feet[i] - 0.6, p0.y), Vector3(p1.x, feet[i + 1] - 0.6, p1.y),
					Vector3(p1.x, _mk_y(a1) - 1.0, p1.y), Vector3(p0.x, feet[i] - 0.6, p0.y),
					Vector3(p1.x, _mk_y(a1) - 1.0, p1.y), Vector3(p0.x, _mk_y(a0) - 1.0, p0.y)]), _r2)
	# The bands, run by run between the arches (the plinth and the impost stop at each opening).
	var runs: Array = []
	var start := MK_A0
	for phi: float in MK_ARCH:
		var half := rad_to_deg(asin(MK_ARCH_HW / r))
		runs.append([start, phi - half])
		start = phi + half
	runs.append([start, MK_A1])
	for run: Array in runs:
		var b0 := float(run[0])
		var b1 := float(run[1])
		var fl := _mk_floor((b0 + b1) * 0.5, outer)
		_mk_band(r, outer, b0, b1, minf(fl, -8.6) - 0.4, fl + 0.9, 0.14, MK_PLINTH, false)
		_mk_band(r, outer, b0, b1, fl + MK_SPRING - 0.3, fl + MK_SPRING, 0.1, MK_TRIM, false)
	_mk_band(r, outer, MK_A0, MK_A1, -0.85, -0.5, 0.1, MK_TRIM)
	_mk_band(r, outer, MK_A0, MK_A1, -0.5, -0.06, 0.32, MK_TRIM)
	# The pilasters: either side of each arch and at the face's ends.
	var at: Array[float] = [MK_A0 + rad_to_deg(0.45 / r), MK_A1 - rad_to_deg(0.45 / r)]
	for phi: float in MK_ARCH:
		var w := rad_to_deg(asin((MK_ARCH_HW + 0.5) / r))
		at.append(phi - w)
		at.append(phi + w)
	for a in at:
		var fl := _mk_floor(a, outer)
		_mk_frame(r, a, outer)
		_lbox(0.0, 0.08, 0.42, 0.1, fl + 0.9, _mk_y(a) - 0.85, MK_TRIM)
		_lbox(0.0, 0.12, 0.5, 0.14, _mk_y(a) - 1.15, _mk_y(a) - 0.85, MK_TRIM.lightened(0.04))
	# The archivolts: a cream ring round each opening, its keystone at the crown; on the inner
	# face's narrow pier a cartouche, on the outer face's wide one a sunk panel with it.
	for k in MK_ARCH.size():
		_mk_archivolt(k, r, outer)
	_mk_frame(r, MK_MID, outer)
	var mid_y := (_mk_floor(MK_MID, outer) + _mk_y(MK_MID)) * 0.5 + 0.3
	if outer:
		_lbox(0.0, 0.03, 4.2, 0.04, _mk_floor(MK_MID, outer) + 1.6, _mk_y(MK_MID) - 1.3, MK_SPANDREL.darkened(0.04))
	_lbox(0.0, 0.1, 0.8, 0.1, mid_y - 0.95, mid_y + 0.95, MK_TRIM)
	_disc(Vector3(_o.x + _b.x * 0.22, mid_y, _o.y + _b.y * 0.22), Vector3(_b.x, 0.0, _b.y), 0.62, 10, MK_FIGURE)


## The cream ring round arch k on the face at r and its keystone, 0.14 m proud (in front of the frieze).
func _mk_archivolt(k: int, r: float, outer: bool) -> void:
	var phi: float = MK_ARCH[k]
	var fl := _mk_floor(phi, outer)
	var spring := fl + MK_SPRING
	var crown := _mk_y(phi) - MK_CROWN
	var sgn := 1.0 if outer else -1.0
	var steps := 10
	var prev_in := Vector3.ZERO
	var prev_out := Vector3.ZERO
	for s in steps + 1:
		var x := -MK_ARCH_HW + 2.0 * MK_ARCH_HW * s / steps
		var y := _mk_arch_y(x, spring, crown)
		# The ring's outer edge 0.55 m out along the arc's normal (in the face's x, y).
		var rise := maxf(crown - spring, 0.3)
		var rs := (rise * rise + MK_ARCH_HW * MK_ARCH_HW) / (2.0 * rise)
		var cy := crown - rs
		var nrm := Vector2(x, y - cy).normalized()
		var xo := x + nrm.x * 0.55
		var yo := y + nrm.y * 0.55
		var pa := _mk_p(r + sgn * 0.14, phi + rad_to_deg(asin(clampf(x / r, -1.0, 1.0))))
		var pb := _mk_p(r + sgn * 0.14, phi + rad_to_deg(asin(clampf(xo / r, -1.0, 1.0))))
		var cur_in := Vector3(pa.x, y, pa.y)
		var cur_out := Vector3(pb.x, yo, pb.y)
		if s > 0:
			var o := _mk_out(outer, phi + rad_to_deg(asin(x / r)))
			_quad(prev_in, cur_in, cur_out, prev_out, Vector3(o.x, 0.0, o.y), MK_TRIM)
			# The ring's soffit edge, so it doesn't read as paper from below.
			var qa := _mk_p(r, phi + rad_to_deg(asin(clampf(x / r, -1.0, 1.0))))
			var xp := -MK_ARCH_HW + 2.0 * MK_ARCH_HW * (s - 1) / steps
			var qb := _mk_p(r, phi + rad_to_deg(asin(clampf(xp / r, -1.0, 1.0))))
			_quad(prev_in, cur_in, Vector3(qa.x, y, qa.y), Vector3(qb.x, prev_in.y, qb.y), Vector3.DOWN, MK_TRIM.darkened(0.12))
		prev_in = cur_in
		prev_out = cur_out
	_mk_frame(r, phi, outer)
	_lbox(0.0, 0.12, 0.38, 0.12, crown - 0.15, crown + 0.75, MK_TRIM.lightened(0.05))


## The barrel vault through the ring over passage k: the soffit in strips from the inner mouth to
## the outer one, the side walls under its springs, the walks either side of the road, and the
## colliders of its sides.
func _mk_vault(k: int) -> void:
	var phi: float = MK_ARCH[k]
	var ur := Vector2(cos(deg_to_rad(phi)), sin(deg_to_rad(phi)))
	var ut := Vector2(-ur.y, ur.x)
	var fi := _mk_floor(phi, false)
	var fo := _mk_floor(phi, true)
	var crown := _mk_y(phi) - MK_CROWN
	var at := func(x: float, outer: bool) -> Vector2:
		var r := MK_OUT if outer else MK_IN
		return MK_C + ur * sqrt(maxf(r * r - x * x, 0.0)) + ut * x
	var steps := 10
	for s in steps:
		var x0 := -MK_ARCH_HW + 2.0 * MK_ARCH_HW * s / steps
		var x1 := -MK_ARCH_HW + 2.0 * MK_ARCH_HW * (s + 1) / steps
		var a0: Vector2 = at.call(x0, false)
		var b0: Vector2 = at.call(x0, true)
		var a1: Vector2 = at.call(x1, false)
		var b1: Vector2 = at.call(x1, true)
		var ya0 := _mk_arch_y(x0, fi + MK_SPRING, crown)
		var yb0 := _mk_arch_y(x0, fo + MK_SPRING, crown)
		var ya1 := _mk_arch_y(x1, fi + MK_SPRING, crown)
		var yb1 := _mk_arch_y(x1, fo + MK_SPRING, crown)
		var xm := (x0 + x1) * 0.5
		var nrm := (-ut * signf(xm) * absf(xm) / MK_ARCH_HW)
		var n := Vector3(nrm.x, -1.0, nrm.y).normalized()
		_quad(Vector3(a0.x, ya0, a0.y), Vector3(b0.x, yb0, b0.y), Vector3(b1.x, yb1, b1.y), Vector3(a1.x, ya1, a1.y), n,
				MK_VAULT.darkened(0.06 if s % 2 == 0 else 0.0))
	for side: float in [-1.0, 1.0]:
		var x := side * MK_ARCH_HW
		var a: Vector2 = at.call(x, false)
		var b: Vector2 = at.call(x, true)
		var inward := Vector3(-ut.x * side, 0.0, -ut.y * side)
		_quad(Vector3(a.x, fi - 0.4, a.y), Vector3(b.x, fo - 0.4, b.y), Vector3(b.x, fo + MK_SPRING, b.y),
				Vector3(a.x, fi + MK_SPRING, a.y), inward, MK_VAULT.darkened(0.1))
		map._solid(&"struct_wall", PackedVector3Array([Vector3(a.x, fi - 1.0, a.y), Vector3(b.x, fo - 1.0, b.y),
				Vector3(b.x, crown - 0.2, b.y), Vector3(a.x, fi - 1.0, a.y), Vector3(b.x, crown - 0.2, b.y),
				Vector3(a.x, crown - 0.2, a.y)]), _r2)
		# The walk along the side, a kerb's height over the road, from 2.6 m off the line to the wall.
		var c: Vector2 = at.call(side * 2.6, false)
		var d: Vector2 = at.call(side * 2.6, true)
		_quad(Vector3(c.x, fi + 0.12, c.y), Vector3(d.x, fo + 0.12, d.y), Vector3(b.x, fo + 0.12, b.y),
				Vector3(a.x, fi + 0.12, a.y), Vector3.UP, MK_PAVING.darkened(0.05))
		_quad(Vector3(c.x, fi - 0.3, c.y), Vector3(d.x, fo - 0.3, d.y), Vector3(d.x, fo + 0.12, d.y),
				Vector3(c.x, fi + 0.12, c.y), -inward, MK_PLINTH)


## The deck between the map's ribbons: the walks' paving out to the balustrades, the setts by the
## kerbs, and the kerb stones along the roadway (where the map's guard lines keep the cars).
func _mk_deck() -> void:
	var bands := [[MK_IN, MK_KERB.x - 0.25, MK_PAVING], [MK_KERB.x - 0.25, MK_KERB.x, MK_TRIM],
			[MK_KERB.y, MK_KERB.y + 0.25, MK_TRIM], [MK_KERB.y + 0.25, MK_OUT, MK_PAVING]]
	var n := ceili((MK_A1 - MK_A0) / MK_STEP)
	for i in n:
		var a0 := MK_A0 + (MK_A1 - MK_A0) * i / n
		var a1 := MK_A0 + (MK_A1 - MK_A0) * (i + 1) / n
		for b: Array in bands:
			var r0 := float(b[0])
			var r1 := float(b[1])
			var lift := 0.06 if r1 - r0 < 0.3 else -0.05
			var p00 := _mk_p(r0, a0)
			var p01 := _mk_p(r0, a1)
			var p10 := _mk_p(r1, a0)
			var p11 := _mk_p(r1, a1)
			_quad(Vector3(p00.x, _mk_y(a0) + lift, p00.y), Vector3(p01.x, _mk_y(a1) + lift, p01.y),
					Vector3(p11.x, _mk_y(a1) + lift, p11.y), Vector3(p10.x, _mk_y(a0) + lift, p10.y), Vector3.UP, b[2])
		# The kerbs' faces to the roadway.
		for side: int in [0, 1]:
			var r := MK_KERB.x if side == 0 else MK_KERB.y
			var o := -1.0 if side == 0 else 1.0
			var q0 := _mk_p(r, a0)
			var q1 := _mk_p(r, a1)
			var d := _mk_out(true, (a0 + a1) * 0.5) * -o
			_quad(Vector3(q0.x, _mk_y(a0) - 0.05, q0.y), Vector3(q1.x, _mk_y(a1) - 0.05, q1.y),
					Vector3(q1.x, _mk_y(a1) + 0.06, q1.y), Vector3(q0.x, _mk_y(a0) + 0.06, q0.y), Vector3(d.x, 0.0, d.y), MK_TRIM.darkened(0.08))


## The balustrade on a face: a plinth, the pierced panels (a darker field), the rail with its two
## slopes, and a die every 2.4 m (left out where a lamp post or a statue's pedestal stands); its
## collider over the drop.
func _mk_balustrade(outer: bool) -> void:
	var sgn := 1.0 if outer else -1.0
	var r := (MK_OUT if outer else MK_IN) - sgn * 0.3
	var n := ceili((MK_A1 - MK_A0) / MK_STEP)
	for i in n:
		var a0 := MK_A0 + (MK_A1 - MK_A0) * i / n
		var a1 := MK_A0 + (MK_A1 - MK_A0) * (i + 1) / n
		_mk_ringbox(r, 0.22, a0, a1, 0.0, 0.2, MK_TRIM)
		_mk_ringbox(r, 0.09, a0, a1, 0.2, 0.86, MK_TRIM.darkened(0.2))
		_mk_ringbox(r, 0.2, a0, a1, 0.86, 1.0, MK_TRIM)
		# The rail's two slopes up to its ridge.
		for s: float in [-1.0, 1.0]:
			var e0 := _mk_p(r + s * 0.2, a0)
			var e1 := _mk_p(r + s * 0.2, a1)
			var m0 := _mk_p(r, a0)
			var m1 := _mk_p(r, a1)
			var o := _mk_out(true, (a0 + a1) * 0.5) * s
			_quad(Vector3(e0.x, _mk_y(a0) + 1.0, e0.y), Vector3(e1.x, _mk_y(a1) + 1.0, e1.y), Vector3(m1.x, _mk_y(a1) + 1.08, m1.y),
					Vector3(m0.x, _mk_y(a0) + 1.08, m0.y), Vector3(o.x, 1.4, o.y).normalized(), MK_TRIM.lightened(0.05))
		var g0 := _mk_p(r, a0)
		var g1 := _mk_p(r, a1)
		map._solid(&"guard_deck", PackedVector3Array([Vector3(g0.x, _mk_y(a0) - 0.2, g0.y), Vector3(g1.x, _mk_y(a1) - 0.2, g1.y),
				Vector3(g1.x, _mk_y(a1) + 1.6, g1.y), Vector3(g0.x, _mk_y(a0) - 0.2, g0.y), Vector3(g1.x, _mk_y(a1) + 1.6, g1.y),
				Vector3(g0.x, _mk_y(a0) + 1.6, g0.y)]), _r2)
	var face := 1 if outer else -1
	var step := rad_to_deg(2.4 / r)
	var a := MK_A0 + step * 0.5
	while a < MK_A1:
		var clear := absf(a - MK_MID) > rad_to_deg((3.0 if outer else 1.2) / r)
		for o: Array in MK_OBELISKS:
			if int(o[0]) == face and absf(a - float(o[1])) < rad_to_deg(1.0 / r):
				clear = false
		if clear:
			_mk_frame(r, a, outer)
			_lbox(0.0, 0.0, 0.25, 0.25, _mk_y(a), _mk_y(a) + 1.12, MK_TRIM)
		a += step


## An annular box on the ring: centre radius r, half width hw (across), from bearing a0 to a1,
## from deck height + y0 to + y1: its two sides and its top.
func _mk_ringbox(r: float, hw: float, a0: float, a1: float, y0: float, y1: float, col: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var p0 := _mk_p(r + s * hw, a0)
		var p1 := _mk_p(r + s * hw, a1)
		var o := _mk_out(true, (a0 + a1) * 0.5) * s
		_quad(Vector3(p0.x, _mk_y(a0) + y0, p0.y), Vector3(p1.x, _mk_y(a1) + y0, p1.y), Vector3(p1.x, _mk_y(a1) + y1, p1.y),
				Vector3(p0.x, _mk_y(a0) + y1, p0.y), Vector3(o.x, 0.0, o.y), col)
	var i0 := _mk_p(r - hw, a0)
	var i1 := _mk_p(r - hw, a1)
	var o0 := _mk_p(r + hw, a0)
	var o1 := _mk_p(r + hw, a1)
	_quad(Vector3(i0.x, _mk_y(a0) + y1, i0.y), Vector3(i1.x, _mk_y(a1) + y1, i1.y), Vector3(o1.x, _mk_y(a1) + y1, o1.y),
			Vector3(o0.x, _mk_y(a0) + y1, o0.y), Vector3.UP, col.lightened(0.04))


## An obelisk lamp post on the balustrade of a face at bearing a: the pedestal with its cap, the
## tapering shaft, its cap and finial, the iron arms with a lantern either side along the
## balustrade and one on top (the glass lights at night).
func _mk_obelisk(outer: bool, a: float) -> void:
	var sgn := 1.0 if outer else -1.0
	var r := (MK_OUT if outer else MK_IN) - sgn * 0.3
	var y := _mk_y(a)
	_mk_frame(r, a, outer)
	_lbox(0.0, 0.0, 0.5, 0.5, y - 0.05, y + 1.25, MK_TRIM)
	_lbox(0.0, 0.0, 0.58, 0.58, y + 1.25, y + 1.4, MK_TRIM.lightened(0.05))
	var c := _w(0.0, 0.0)
	_frustum(_square(c, 0.36), y + 1.4, _square(c, 0.22), y + 4.4, MK_TRIM)
	_lbox(0.0, 0.0, 0.3, 0.3, y + 4.4, y + 4.55, MK_TRIM.lightened(0.05))
	_pyramid(_square(c, 0.2), y + 4.55, y + 4.85, MK_TRIM)
	var keep := _mode
	for s: float in [-1.0, 1.0]:
		var arm := _w(s * 0.85, 0.0)
		_beam(Vector3(c.x, y + 3.9, c.y), Vector3(arm.x, y + 4.05, arm.y), 0.07, PAL_IRON, false)
		_lbox(s * 0.85, 0.0, 0.05, 0.05, y + 3.55, y + 4.05, PAL_IRON)
		_mode = M_LAMP
		_lbox(s * 0.85, 0.0, 0.15, 0.15, y + 3.15, y + 3.55, MK_GLASS)
		_mode = keep
		_lbox(s * 0.85, 0.0, 0.18, 0.18, y + 3.55, y + 3.62, PAL_IRON)
	_lbox(0.0, 0.0, 0.05, 0.05, y + 4.85, y + 5.0, PAL_IRON)
	_mode = M_LAMP
	_lbox(0.0, 0.0, 0.16, 0.16, y + 5.0, y + 5.42, MK_GLASS)
	_mode = keep
	_pyramid(_square(c, 0.2), y + 5.42, y + 5.65, PAL_IRON)


## Woydyga's Syrena over the central pier on the inner face, facing the pit (north-west): the
## pedestal breaking the balustrade, the scaly tail coiled under her, the draped body, the shield
## on her left arm, the right arm raised over her head with the sword, the hair down her back.
func _mk_syrena() -> void:
	var r := MK_IN + 0.3
	var y := _mk_y(MK_MID)
	_mk_frame(r, MK_MID, false)
	_lbox(0.0, 0.1, 0.85, 0.7, y - 0.05, y + 1.35, MK_TRIM)
	_lbox(0.0, 0.1, 0.95, 0.8, y + 1.35, y + 1.5, MK_TRIM.lightened(0.05))
	var f := MK_FIGURE
	var b := y + 1.5
	var c := _w(0.0, 0.15)
	_frustum(_circle(c, 0.5, 8), b, _circle(_w(0.0, 0.1), 0.34, 8), b + 0.55, f.darkened(0.05))
	_beam(Vector3(_w(0.3, -0.2).x, b + 0.15, _w(0.3, -0.2).y), Vector3(_w(0.62, -0.35).x, b + 0.75, _w(0.62, -0.35).y), 0.2, f.darkened(0.05))
	_frustum(_circle(_w(0.0, 0.1), 0.32, 8), b + 0.55, _circle(_w(0.0, 0.08), 0.21, 8), b + 1.45, f)
	_frustum(_circle(_w(0.0, 0.08), 0.21, 8), b + 1.45, _circle(_w(0.0, 0.08), 0.16, 8), b + 1.6, f)
	_prism(_circle(_w(0.0, 0.1), 0.12, 8), b + 1.6, b + 1.9, f, f)
	_lbox(0.0, -0.08, 0.12, 0.06, b + 1.15, b + 1.8, f.darkened(0.08))
	var sh := _w(0.22, 0.08)
	var hand := _w(0.05, 0.02)
	_beam(Vector3(sh.x, b + 1.42, sh.y), Vector3(hand.x, b + 2.1, hand.y), 0.1, f)
	var tip := _w(-0.35, -0.1)
	_beam(Vector3(hand.x, b + 2.1, hand.y), Vector3(tip.x, b + 2.75, tip.y), 0.05, f.lightened(0.04))
	var sc := _w(-0.36, 0.22)
	_disc(Vector3(sc.x, b + 1.05, sc.y), Vector3(_b.x * 0.8 - _a.x * 0.6, 0.0, _b.y * 0.8 - _a.y * 0.6).normalized(), 0.36, 10, f.darkened(0.03))
	_disc(Vector3(sc.x, b + 1.05, sc.y), -Vector3(_b.x * 0.8 - _a.x * 0.6, 0.0, _b.y * 0.8 - _a.y * 0.6).normalized(), 0.36, 10, f.darkened(0.08))


## The allegorical group in the middle of the outer balustrade, carved both ways: a pedestal
## standing out of the face, the stele with the Vistula's medallion each side, the torch over it in
## its oak leaves, Warsaw seated with her mural crown and the book, Labour with the cogwheel.
func _mk_group() -> void:
	var r := MK_OUT - 0.3
	var y := _mk_y(MK_MID)
	_mk_frame(r, MK_MID, true)
	_lbox(0.0, 0.15, 2.7, 0.75, y - 0.05, y + 1.1, MK_TRIM)
	_lbox(0.0, 0.15, 2.8, 0.85, y + 1.1, y + 1.25, MK_TRIM.lightened(0.05))
	var f := MK_FIGURE
	var b := y + 1.25
	_lbox(0.0, 0.15, 0.55, 0.3, b - 0.05, b + 1.6, f)
	_disc(Vector3(_w(0.0, 0.5).x, b + 1.0, _w(0.0, 0.5).y), Vector3(_b.x, 0.0, _b.y), 0.38, 10, f.darkened(0.06))
	_disc(Vector3(_w(0.0, -0.2).x, b + 1.0, _w(0.0, -0.2).y), Vector3(-_b.x, 0.0, -_b.y), 0.38, 10, f.darkened(0.06))
	var tc := _w(0.0, 0.15)
	_frustum(_circle(tc, 0.32, 8), b + 1.6, _circle(tc, 0.2, 8), b + 1.85, f.darkened(0.04))
	_prism(_circle(tc, 0.1, 6), b + 1.85, b + 2.45, f, f)
	_pyramid(_circle(tc, 0.2, 6), b + 2.45, b + 2.95, f.lightened(0.05))
	for s: float in [-1.0, 1.0]:
		var c := _w(s * 1.45, 0.15)
		# Seated: the lap and the legs down the front of the plinth, the body, the head.
		_lbox(s * 1.45, 0.25, 0.42, 0.5, b, b + 0.55, f.darkened(0.04))
		_frustum(_circle(c, 0.36, 8), b + 0.55, _circle(c, 0.24, 8), b + 1.35, f)
		_prism(_circle(_w(s * 1.45, 0.2), 0.14, 8), b + 1.35, b + 1.65, f, f)
		if s < 0.0:
			# Warsaw: the mural crown and the book on her knee.
			_prism(_circle(_w(s * 1.45, 0.2), 0.16, 8), b + 1.65, b + 1.78, f.darkened(0.06), f.darkened(0.1))
			_lbox(s * 1.2, 0.55, 0.2, 0.14, b + 0.55, b + 0.7, f.darkened(0.12))
		else:
			# Labour: the cogwheel stood at his side.
			var g := _w(s * 2.15, 0.15)
			_disc(Vector3(g.x, b + 0.55, g.y), Vector3(_b.x, 0.0, _b.y), 0.45, 12, f.darkened(0.1))
			_disc(Vector3(g.x, b + 0.55, g.y), -Vector3(_b.x, 0.0, _b.y), 0.45, 12, f.darkened(0.14))


# --- the memorial ------------------------------------------------------------------------------

## Krzysztof "Szaya" Szaykowski's memorial: a rough granite stone on a low step, a dark bronze
## plaque on its face towards the viaduct (the default until F's photo: docs/QUESTIONS.md).
func _build_szaja(_site: Dictionary) -> void:
	_g = map.terrain_height(SZ_AT.x, SZ_AT.y)
	_mode = M_STONE
	_o = SZ_AT
	_b = SZ_FACE.normalized()
	_a = Vector2(-_b.y, _b.x)
	_lbox(0.0, 0.0, 0.95, 0.75, _g - 0.3, _g + 0.15, PAL_GREY_GRANITE.lightened(0.1))
	var foot := PackedVector2Array([_w(-0.6, -0.4), _w(0.1, -0.5), _w(0.62, -0.25), _w(0.55, 0.35), _w(-0.15, 0.42), _w(-0.62, 0.2)])
	var top := PackedVector2Array([_w(-0.45, -0.3), _w(0.05, -0.38), _w(0.4, -0.18), _w(0.38, 0.22), _w(-0.1, 0.3), _w(-0.42, 0.12)])
	_frustum(foot, _g + 0.15, top, _g + 1.35, PAL_GREY_GRANITE, PAL_GREY_GRANITE.darkened(0.06))
	_lbox(0.0, 0.36, 0.3, 0.02, _g + 0.75, _g + 1.1, PAL_BRONZE)
	_collide(_square(SZ_AT, 0.9))
