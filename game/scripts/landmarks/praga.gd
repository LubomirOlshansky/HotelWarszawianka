extends "res://scripts/landmarks/ujazdow.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Praga: Stadion Narodowy and
## Bazar Różyckiego. Moved as it was from the one big file. landmarks.gd is the class the game
## makes; every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd,
## common.gd, then the areas in the order of landmarks.gd's `extends` chain), so code here may use
## this file, common.gd and the facade kit, never another area: a helper two areas need goes to
## common.gd.
## Stadion Narodowy's grass embankment (2026-11-01): the old Stadion Dziesięciolecia's earth
## bank below the promenade, bare ground in the map, in one band per gap between two masts
## (`_find_embankment`). map_builder's _build_areas lays them as grass under every mapped area,
## so the plazas, lawns, steps, paths and roads on the bank stay on top.
var embankment: Array[PackedVector2Array] = []


## Stadion Narodowy: 72 pairs of masts are mapped round it (columns from the ground to
## 50 m, spikes 44-60 m a few metres further out); they give its outline at every angle.
func _find_stadium() -> void:
	var inner: Array[Vector2] = []
	var outer: Array[Vector2] = []
	var area := Rect2(1250, -820, 450, 450)
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		if not area.has_point(c):
			continue
		var lo := q[0]
		var hi := q[0]
		for v in q:
			lo = lo.min(v)
			hi = hi.max(v)
		if (hi - lo).length() > 2.5:
			continue
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		if absf(h - 50.0) < 0.5 and mh < 0.5:
			inner.append(c)
		elif absf(h - 60.0) < 0.5 and absf(mh - 44.0) < 0.5:
			outer.append(c)
	if inner.size() < 24 or inner.size() != outer.size():
		return
	var centre := Vector2.ZERO
	for v in inner:
		centre += v
	centre /= inner.size()
	var by_angle := func(a: Vector2, b: Vector2) -> bool: return (a - centre).angle() < (b - centre).angle()
	inner.sort_custom(by_angle)
	outer.sort_custom(by_angle)
	var zone := PackedVector2Array()
	for v in outer:
		zone.append(centre + (v - centre) * 1.08)
	_add_site("stadium", [zone])
	sites[-1]["inner"] = inner
	sites[-1]["outer"] = outer
	sites[-1]["centre"] = centre
	_find_embankment(inner, centre)


## How far out the grass embankment starts, in inner-mast radii: under the mapped plaza and
## the lawns round the stadium (the plaza's outer edge is at 1.2 to 1.35), so the band shows
## only where they end and the bank falls to the streets.
const BANK_FROM := 1.15
## How far out the bank may reach, in inner-mast radii.
const BANK_TO := 1.75
## A ray whose ground falls less than this (metres) has no bank (a road ramp, a bridge).
const BANK_DROP := 2.0


## The embankment's bands. Along each mast's ray from the centre, in 2 m steps from BANK_FROM:
## the bank's slope starts where the ground falls at least 15 % over the next 4 m once it is
## 2.5 m under the start (under the plaza's terrace, so its inner slope with the lawns and
## stairs does not count), and its foot is where it flattens to under 9 % (the street, the
## car parks, the river walk start there). A band per gap between two masts, from BANK_FROM
## out to the feet (a 3-ray median, so a stair or a ramp in the terrain makes no notch).
func _find_embankment(inner: Array[Vector2], c: Vector2) -> void:
	var n := inner.size()
	var reach := PackedFloat32Array()
	reach.resize(n)
	for k in n:
		var d := inner[k] - c
		var r := d.length()
		var dir := d / r
		var start: float = map.terrain_height(c.x + dir.x * r * BANK_FROM, c.y + dir.y * r * BANK_FROM)
		var steep := false
		var foot := r * BANK_TO
		var t := r * BANK_FROM
		while t <= r * BANK_TO:
			var h0: float = map.terrain_height(c.x + dir.x * t, c.y + dir.y * t)
			var drop: float = h0 - map.terrain_height(c.x + dir.x * (t + 4.0), c.y + dir.y * (t + 4.0))
			if not steep:
				steep = h0 < start - 2.5 and drop >= 0.6
			elif drop < 0.35:
				foot = t
				break
			t += 2.0
		var fell: float = start - map.terrain_height(c.x + dir.x * foot, c.y + dir.y * foot)
		reach[k] = foot if steep and fell >= BANK_DROP else r * BANK_FROM
	embankment.clear()
	for k in n:
		var k1 := (k + 1) % n
		var ra := _median3(reach[(k + n - 1) % n], reach[k], reach[k1])
		var rb := _median3(reach[k], reach[k1], reach[(k + 2) % n])
		var da := (inner[k] - c).normalized()
		var db := (inner[k1] - c).normalized()
		var ia := (inner[k] - c).length() * BANK_FROM
		var ib := (inner[k1] - c).length() * BANK_FROM
		if ra - ia < 1.0 and rb - ib < 1.0:
			continue
		embankment.append(PackedVector2Array([c + da * ia, c + db * ib, c + db * maxf(rb, ib + 0.5), c + da * maxf(ra, ia + 0.5)]))


static func _median3(a: float, b: float, c: float) -> float:
	return maxf(minf(a, b), minf(maxf(a, b), c))


# --- Stadion Narodowy -------------------------------------------------------------------------

## The bowl in the old stadium's embankment (spec docs/landmarks/specs/stadium.md): a woven
## skin leaning out like a basket from the embankment's crest to the roof's edge, red below
## and white above like the flag, 72 masts leaning with it and spiking above the roof, a
## raised white rim and a membrane roof ringing the open middle, two tiers of red seats round
## a striped pitch, and the needle with the folded roof hanging over the centre on its cables.
## The outline at every angle comes from the mapped masts; heights from the mapped parts
## (roof rim 44-46.2 m, mast tips 60 m, upper tier 19-38.5 m, hub 37-43 m, folded roof
## 55-63 m, needle 30-100 m, over the street round it).
## The promenade's inner and outer edges, in inner-mast radii (the concourse glass is at 0.935).
const PROM_FROM := 0.955
const PROM_TO := 1.04


func _build_stadium(site: Dictionary) -> void:
	var inner: Array = site["inner"]
	var outer: Array = site["outer"]
	var c: Vector2 = site["centre"]
	var n := inner.size()
	var street := INF
	for v in outer:
		var q: Vector2 = c + ((v as Vector2) - c) * 1.25
		street = minf(street, map.terrain_height(q.x, q.y))
	_g = street
	var pitch: float = map.terrain_height(c.x, c.y)
	var roof_y := street + 44.0
	var rim_y := street + 46.2
	var skin_top := street + 41.0
	# The pitch's long axis: the masts' principal axis (the outline is an oval round it).
	var sxx := 0.0
	var sxy := 0.0
	var syy := 0.0
	for v in inner:
		var dd := (v as Vector2) - c
		sxx += dd.x * dd.x
		sxy += dd.x * dd.y
		syy += dd.y * dd.y
	var axis := Vector2.from_angle(0.5 * atan2(2.0 * sxy, sxx - syy))
	var across := Vector2(-axis.y, axis.x)
	var dirs: Array[Vector2] = []
	for v in inner:
		dirs.append(((v as Vector2) - c).normalized())
	# A rounded rectangle round the pitch (half-sizes along and across the axis), sampled at
	# the masts' angles so every ring of the bowl meets the next one quad by quad.
	var oblong := func(half_a: float, half_b: float, power: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for d: Vector2 in dirs:
			var x := absf(d.dot(axis)) / half_a
			var y := absf(d.dot(across)) / half_b
			ring.append(c + d * pow(pow(x, power) + pow(y, power), -1.0 / power))
		return ring
	var scaled := func(s: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for v in inner:
			ring.append(c + ((v as Vector2) - c) * s)
		return ring
	# Rings at every mast angle.
	var base := PackedVector2Array()   # the skin's foot, on the crest
	var mid := PackedVector2Array()    # the basket's belly
	var top := PackedVector2Array()    # the skin's top, under the roof edge
	var edge := PackedVector2Array()   # the roof's outer edge
	var inset := PackedVector2Array()  # the rim's inner foot, where the membrane starts
	var foot := PackedFloat32Array()
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var d := vi - c
		base.append(c + d * 0.965)
		mid.append(vi + (vo - vi) * 0.25)
		top.append(vi + (vo - vi) * 0.62)
		edge.append(vo + (vo - c).normalized() * 1.5)
		inset.append(vo - (vo - c).normalized() * 1.5)
		foot.append(map.terrain_height(vi.x, vi.y) - 1.0)
	var hole: PackedVector2Array = oblong.call(70.0, 54.0, 4.0)
	# The concourse: a dark glass curtain wall set back behind the masts' feet, from the
	# crest to 7.5 m (the Mac photo check, 2026-11-01); the skin starts over it.
	_mode = M_GLASS
	var glass := PackedVector2Array()
	for k in n:
		glass.append(c + ((inner[k] as Vector2) - c) * 0.935)
	var grun := 0.0
	for k in n:
		var k1 := (k + 1) % n
		var gl := glass[k].distance_to(glass[k1])
		var go := (glass[k] + glass[k1]) * 0.5 - c
		var y0 := minf(foot[k], foot[k1]) - 0.5
		var y1 := maxf(foot[k], foot[k1]) + 7.5
		_quad(Vector3(glass[k].x, y0, glass[k].y), Vector3(glass[k1].x, y0, glass[k1].y),
				Vector3(glass[k1].x, y1, glass[k1].y), Vector3(glass[k].x, y1, glass[k].y),
				Vector3(go.x, 0.0, go.y).normalized(), Color("#2b3440"),
				Vector2(grun, y0 - street), Vector2(grun + gl, y0 - street), Vector2(grun + gl, y1 - street),
				Vector2(grun, y1 - street), y1 - street)
		grun += gl
	for k in n:
		foot[k] += 7.0
	# The skin: two bands, its panels continuous all the way round (the shader turns them
	# from red to silver with the height).
	_mode = M_WEAVE
	var run := 0.0
	for k in n:
		var k1 := (k + 1) % n
		var len0 := base[k].distance_to(base[k1])
		var out := (base[k] + base[k1]) * 0.5 - c
		var nrm := Vector3(out.x, 0.0, out.y).normalized()
		var ym := lerpf(foot[k], skin_top, 0.45)
		var ym1 := lerpf(foot[k1], skin_top, 0.45)
		var p0 := Vector3(base[k].x, foot[k], base[k].y)
		var p1 := Vector3(base[k1].x, foot[k1], base[k1].y)
		var m0 := Vector3(mid[k].x, ym, mid[k].y)
		var m1 := Vector3(mid[k1].x, ym1, mid[k1].y)
		var t0 := Vector3(top[k].x, skin_top, top[k].y)
		var t1 := Vector3(top[k1].x, skin_top, top[k1].y)
		_quad(p0, p1, m1, m0, nrm, Color.WHITE, Vector2(run, foot[k] - street), Vector2(run + len0, foot[k1] - street),
				Vector2(run + len0, ym1 - street), Vector2(run, ym - street), skin_top - street)
		_quad(m0, m1, t1, t0, (nrm + Vector3(0, -0.25, 0)).normalized(), Color.WHITE, Vector2(run, ym - street),
				Vector2(run + len0, ym1 - street), Vector2(run + len0, skin_top - street), Vector2(run, skin_top - street), skin_top - street)
		run += len0
	_collide(base)
	# The promenade at the masts' feet on the old embankment's crest, from the concourse's
	# glass out to the mapped plaza (its lawns and stairs down the bank start there), in two
	# greys every three masts, a kerb down to the ground on its outer edge. Each corner sits
	# over the highest ground round it (the crest is a ridge between the 10 m grid's points).
	_mode = M_STONE
	var deck := PackedFloat32Array()
	for k in n:
		var hi := -INF
		for j in [-1, 0, 1]:
			var dj: Vector2 = (inner[(k + j + n) % n] as Vector2) - c
			var dk: Vector2 = (inner[k] as Vector2) - c
			var ray: Vector2 = (dk + dj) * 0.5 if j != 0 else dk
			for s in [PROM_FROM, 0.98, 1.0, 1.02, PROM_TO]:
				hi = maxf(hi, map.terrain_height(c.x + ray.x * s, c.y + ray.y * s))
		deck.append(hi + 0.2)
	for k in n:
		var k1 := (k + 1) % n
		var a0: Vector2 = c + ((inner[k] as Vector2) - c) * PROM_FROM
		var b0: Vector2 = c + ((inner[k1] as Vector2) - c) * PROM_FROM
		var a1: Vector2 = c + ((inner[k] as Vector2) - c) * PROM_TO
		var b1: Vector2 = c + ((inner[k1] as Vector2) - c) * PROM_TO
		var tone := Color("#cbc6ba") if (k / 3) % 2 == 0 else Color("#c3beb2")
		_quad(Vector3(a0.x, deck[k], a0.y), Vector3(b0.x, deck[k1], b0.y), Vector3(b1.x, deck[k1], b1.y),
				Vector3(a1.x, deck[k], a1.y), Vector3.UP, tone)
		var ka := minf(map.terrain_height(a1.x, a1.y), deck[k]) - 0.3
		var kb := minf(map.terrain_height(b1.x, b1.y), deck[k1]) - 0.3
		var ko := (a1 + b1) * 0.5 - c
		_quad(Vector3(a1.x, ka, a1.y), Vector3(b1.x, kb, b1.y), Vector3(b1.x, deck[k1], b1.y), Vector3(a1.x, deck[k], a1.y),
				Vector3(ko.x, 0.0, ko.y).normalized(), Color("#a9a59b"))
	# The roof: the raised rim (its outer face over the skin, its inner face sloping to the
	# membrane), its soffit back to the skin's top, then the membrane down to the open middle
	# in panels.
	for k in n:
		var k1 := (k + 1) % n
		var o := (edge[k] + edge[k1]) * 0.5 - c
		var on := Vector3(o.x, 0, o.y).normalized()
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(edge[k1].x, rim_y, edge[k1].y), Vector3(edge[k].x, rim_y, edge[k].y), on, Color("#dcdee2"))
		_quad(Vector3(edge[k].x, rim_y, edge[k].y), Vector3(edge[k1].x, rim_y, edge[k1].y),
				Vector3(inset[k1].x, roof_y, inset[k1].y), Vector3(inset[k].x, roof_y, inset[k].y),
				(Vector3.UP * 1.5 - on * 2.2).normalized(), Color("#c9ccd1"))
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(top[k1].x, skin_top, top[k1].y), Vector3(top[k].x, skin_top, top[k].y), Vector3.DOWN, Color("#9da1a8"))
	_mode = M_MEMBRANE
	var hole_y := roof_y - 3.5
	for k in n:
		var k1 := (k + 1) % n
		var p0 := Vector3(inset[k].x, roof_y, inset[k].y)
		var p1 := Vector3(inset[k1].x, roof_y, inset[k1].y)
		var p2 := Vector3(hole[k1].x, hole_y, hole[k1].y)
		var p3 := Vector3(hole[k].x, hole_y, hole[k].y)
		# The last 7 m before the opening are grey-blue polycarbonate (the Mac photo check).
		var g0 := p3 + (p0 - p3) * (7.0 / p0.distance_to(p3))
		var g1 := p2 + (p1 - p2) * (7.0 / p1.distance_to(p2))
		var nr := (p1 - p0).cross(p3 - p0).normalized()
		if nr.y < 0.0:
			nr = -nr
		_quad(p0, p1, g1, g0, nr, Color("#f4f4f1") if k % 2 == 0 else Color("#eaebe8"))
		_quad(g0, g1, p2, p3, nr, Color("#8f9aa3") if k % 2 == 0 else Color("#98a2aa"))
	# The bowl, from the pitch out: advertising boards, the lower tier of red seats, a grey
	# gangway, the dark glass of the boxes, then the upper tier up under the roof. Every
	# sixth wedge is a lighter aisle.
	_mode = M_STONE
	var seat := Color("#c42a31")
	var bowl := [
		[oblong.call(61.0, 42.0, 8.0), pitch + 0.4, Color("#2d3138")],
		[oblong.call(61.0, 42.0, 8.0), pitch + 1.4, seat],
		[oblong.call(78.0, 59.0, 6.0), pitch + 13.0, Color("#8e8a88")],
		[oblong.call(81.0, 62.0, 6.0), pitch + 13.0, Color("#3d4652")],
		[oblong.call(81.0, 62.0, 6.0), pitch + 19.0, seat],
		[scaled.call(0.86), street + 38.5, Color()]]
	for t in range(1, bowl.size()):
		var r0: PackedVector2Array = bowl[t - 1][0]
		var y0: float = bowl[t - 1][1]
		var col: Color = bowl[t - 1][2]
		var r1: PackedVector2Array = bowl[t][0]
		var y1: float = bowl[t][1]
		for k in n:
			var k1 := (k + 1) % n
			var p0 := Vector3(r0[k].x, y0, r0[k].y)
			var p1 := Vector3(r0[k1].x, y0, r0[k1].y)
			var p2 := Vector3(r1[k1].x, y1, r1[k1].y)
			var p3 := Vector3(r1[k].x, y1, r1[k].y)
			var nr := (p1 - p0).cross(p3 - p0).normalized()
			if absf(nr.y) < 0.2:
				# A wall (the boards, the boxes): faces the pitch.
				var mid2 := (r0[k] + r0[k1]) * 0.5 - c
				if Vector2(nr.x, nr.z).dot(mid2) > 0.0:
					nr = -nr
			elif nr.y < 0.0:
				nr = -nr
			var aisle := k % 6 == 0 and col == seat
			_quad(p0, p1, p2, p3, nr, col.lightened(0.25) if aisle else col)
	# The pitch: grass out to the boards, mown in stripes across it, and its white lines.
	var rim0: PackedVector2Array = bowl[0][0]
	_cap(rim0, pitch + 0.4, Color("#4f8a3a"))
	var flat := func(a: Vector2, b: Vector2, w: float, y: float, col: Color) -> void:
		var s := (b - a).normalized().orthogonal() * w * 0.5
		_quad(Vector3(a.x - s.x, y, a.y - s.y), Vector3(b.x - s.x, y, b.y - s.y), Vector3(b.x + s.x, y, b.y + s.y),
				Vector3(a.x + s.x, y, a.y + s.y), Vector3.UP, col)
	var at := func(x: float, y: float) -> Vector2: return c + axis * x + across * y
	for b in 12:
		if b % 2 == 0:
			var x0 := -52.5 + b * 8.75
			flat.call(at.call(x0, 0.0), at.call(x0 + 8.75, 0.0), 68.0, pitch + 0.43, Color("#5a9643"))
	# Lines at three heights 3 cm apart, so lines that cross never share a plane.
	var line := Color("#f2f2ee")
	var y_long := pitch + 0.47
	var y_short := pitch + 0.50
	var y_box := pitch + 0.53
	for side: float in [-1.0, 1.0]:
		flat.call(at.call(-52.5, side * 34.0), at.call(52.5, side * 34.0), 0.6, y_long, line)
		flat.call(at.call(side * 52.5, -34.3), at.call(side * 52.5, 34.3), 0.6, y_short, line)
		# The penalty area: 16.5 m deep, 40.3 m wide; its front at the third height.
		flat.call(at.call(side * 52.2, -20.15), at.call(side * 36.0, -20.15), 0.6, y_long, line)
		flat.call(at.call(side * 52.2, 20.15), at.call(side * 36.0, 20.15), 0.6, y_long, line)
		flat.call(at.call(side * 36.0, -20.45), at.call(side * 36.0, 20.45), 0.6, y_box, line)
	flat.call(at.call(0.0, -34.3), at.call(0.0, 34.3), 0.6, y_short, line)
	for k in 16:
		var a0: float = TAU * k / 16.0
		var a1: float = TAU * (k + 1) / 16.0
		# Neighbouring arcs overlap at their joints: every other one 3 cm higher.
		flat.call(at.call(cos(a0) * 9.15, sin(a0) * 9.15), at.call(cos(a1) * 9.15, sin(a1) * 9.15), 0.6,
				y_box + (k % 2) * 0.03, line)
	# The masts: from the foot of the skin, leaning out with it, spiking over the roof.
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var a := Vector3(vi.x, foot[k], vi.y)
		var b := Vector3(vo.x, street + 60.0, vo.y)
		_beam(a, b, 0.55, Color("#e4e6ea"))
		# The spike over the rim, thicker: the stadium's silhouette from the street.
		var s0 := a.lerp(b, (rim_y - 1.0 - a.y) / (b.y - a.y))
		_beam(s0, b + (b - a).normalized() * 0.4, 1.0, Color("#f2f3f5"))
	# The needle (mapped 30-100 m): a white spindle through a dark hub ring where the cables
	# meet (37-43 m, 15.6 m across), the folded roof stored in a white drum above it (55-63 m,
	# 21 m across), and a red light on its tip; a cable from the hub to every third mast's
	# angle on the roof's inner edge.
	var steel := Color("#f1f1ee")
	var ring10 := func(radius: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for k in 10:
			ring.append(c + Vector2.from_angle(TAU * k / 10.0) * radius)
		return ring
	_frustum(ring10.call(0.6), street + 30.0, ring10.call(1.0), street + 37.0, steel)
	_prism(ring10.call(7.8), street + 37.0, street + 43.0, Color("#2c2d31"), Color("#3a3b40"), M_STONE, M_STONE)
	_frustum(ring10.call(1.0), street + 43.0, ring10.call(1.2), street + 51.5, steel)
	_frustum(ring10.call(1.2), street + 51.5, ring10.call(10.5), street + 55.0, steel)
	_frustum(ring10.call(10.5), street + 55.0, ring10.call(10.5), street + 61.0, Color("#e6e7e4"))
	_frustum(ring10.call(10.5), street + 61.0, ring10.call(1.6), street + 63.5, steel, steel)
	_frustum(ring10.call(1.0), street + 63.5, ring10.call(0.3), street + 99.0, steel)
	_prism(ring10.call(0.45), street + 99.0, street + 100.5, Color("#ff3b30"), Color("#ff6a5c"), M_LAMP, M_LAMP)
	var hub := Vector3(c.x, street + 40.0, c.y)
	var keep_id := _id
	_id = 0
	for k in range(0, n, 3):
		var h: Vector2 = hole[k]
		# A few cm of height apart at the hub, so neighbours' flat tops don't z-fight there.
		var lift := Vector3(0.0, (k / 3 % 5) * 0.03, 0.0)
		_beam(hub + lift, Vector3(h.x, hole_y, h.y), 0.18, Color("#c8cbd0"), false)
	_id = keep_id


# --- Praga: St Florian's cathedral and Bazar Różyckiego (2026-11-02, photo reports) ----------

## Bazar Różyckiego (Targowa, since 1882): Warsaw's oldest market. From the Mac's photo report
## (docs/landmarks/photo-reports/bazar_rozyckiego.md: one 2023 photo and the orthophoto): the old
## stalls, a dense patchwork of low tin- and tarp-roofed sheds with awnings and crates, face the
## 2023 rebuild's grid of dark green box kiosks with flat white-edged roofs across narrow lanes.
## OpenStreetMap maps the stalls as 26 retail outlines 4.3 m tall; the 16 regular 5.7 x 9.7 and
## 5.8 x 11.7 m boxes are the new kiosks, the rest the old stall rows (cut into stalls 2.6-4.2 m
## wide, seeded by position). Spec docs/landmarks/specs/bazar.md.
const BAZAR_BOX := Rect2(1025.0, -2032.0, 110.0, 70.0)
const BAZAR_KIOSK := Color("#2f6b55")
const BAZAR_KIOSK_ROOF := Color("#3b7a62")
const BAZAR_FASCIA := Color("#e9ece6")
const BAZAR_SHUTTER := Color("#9a9c98")
const BAZAR_GLASS := Color(1.0, 0.84, 0.58)
const BAZAR_DOOR := Color("#23262a")
const BAZAR_PLINTH := Color("#5a5854")
## The old stalls' walls (faded paint, sheet metal) and roofs (tin, blue tarp, rust, grey felt).
const BAZAR_WALLS := ["#b9b2a2", "#8f9a9e", "#c7b98f", "#7f8f7a", "#a46d52", "#d6d0c2", "#6f7d8c"]
const BAZAR_ROOFS := ["#7d8084", "#3f6fa8", "#8a5638", "#5e5d59", "#9a9a94", "#4f7fb0", "#6e4a36"]
## Awnings (striped canvas reads as one colour from above) and the crates' wood.
const BAZAR_AWNINGS := ["#c0392b", "#2e6da4", "#e0b33a", "#3f8f5a", "#e7e2d6"]
const BAZAR_CRATE := Color("#a7814f")


func _find_bazar() -> void:
	var stalls: Array = []
	var kiosks: Array = []
	for bld in data["buildings"]:
		if bld.get("kind", "") != "retail" or float(bld["h"]) > 5.0:
			continue
		var q := _pts(bld["p"])
		if q.size() < 3 or not BAZAR_BOX.has_point(_centre(q)):
			continue
		if _bazar_kiosk(q):
			kiosks.append(q)
		else:
			stalls.append(q)
	if stalls.is_empty() and kiosks.is_empty():
		return
	_add_site("bazar", stalls + kiosks)
	if not sites.is_empty() and sites[-1]["key"] == "bazar":
		sites[-1]["stalls"] = stalls
		sites[-1]["kiosks"] = kiosks


## A new kiosk: a four-cornered box of 45-75 m^2 with right angles.
func _bazar_kiosk(q: PackedVector2Array) -> bool:
	if q.size() != 4:
		return false
	var area := absf(_area(q))
	if area < 45.0 or area > 75.0:
		return false
	for i in 4:
		var e0 := (q[(i + 1) % 4] - q[i]).normalized()
		var e1 := (q[(i + 2) % 4] - q[(i + 1) % 4]).normalized()
		if absf(e0.dot(e1)) > 0.08:
			return false
	return true


## A seeded 0..1 from a stall's position and a salt (the same every run and every sector).
func _bazar_rand(p: Vector2, salt: int) -> float:
	var x := sin(p.x * 12.9898 + p.y * 78.233 + float(salt) * 37.719) * 43758.5453
	return x - floorf(x)


func _build_bazar(site: Dictionary) -> void:
	for q: PackedVector2Array in site["kiosks"]:
		_bazar_kiosk_box(q)
	for q: PackedVector2Array in site["stalls"]:
		_bazar_row(q)


## The frame of a ring: u along its longest edge, from the ring's centre.
func _bazar_frame(q: PackedVector2Array) -> Rect2:
	var longest := 0.0
	for i in q.size():
		var e := q[(i + 1) % q.size()] - q[i]
		if e.length() > longest:
			longest = e.length()
			_a = e.normalized()
	_b = Vector2(-_a.y, _a.x)
	_o = _centre(q)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in q:
		lo = lo.min(_local(p))
		hi = hi.max(_local(p))
	return Rect2(lo, hi - lo)


## A 2023 kiosk: a dark green box under a flat roof with a white edge that overhangs a little,
## three shop units along each long side (whatever its length), a lit window or a grey roller
## shutter each.
func _bazar_kiosk_box(q: PackedVector2Array) -> void:
	var r := _bazar_frame(q)
	var g := _ground_under(q)
	_g = g
	var none := Color(0, 0, 0, 0)
	var top := g + 3.1
	var plan := _rect(r.get_center().x, r.get_center().y, r.size.x * 0.5, r.size.y * 0.5)
	_prism(plan, g - 0.3, g + 0.15, BAZAR_PLINTH, none, M_STONE)
	_prism(plan, g + 0.15, top, BAZAR_KIOSK, none, M_STONE)
	var roof := _rect(r.get_center().x, r.get_center().y, r.size.x * 0.5 + 0.35, r.size.y * 0.5 + 0.35)
	_prism(roof, top, top + 0.3, BAZAR_FASCIA, BAZAR_KIOSK_ROOF, M_STONE, M_STONE)
	# Three units a side (F's look check, 2026-11-03: the working count; the photo shows paired
	# rows but hides their ends).
	var units := 3
	var uw := r.size.x / units
	for sv: float in [-1.0, 1.0]:
		var v := r.get_center().y + sv * (r.size.y * 0.5 + 0.04)
		for k in units:
			var u0 := r.position.x + uw * k + 0.25
			var u1 := r.position.x + uw * (k + 1) - 0.25
			var lit := _bazar_rand(_w(u0, v), 3) < 0.6
			_mode = M_PAVILION if lit else M_STONE
			_wall(_w(u0, v), _w(u1, v), g + 0.35, g + 2.5, _b * sv, BAZAR_GLASS if lit else BAZAR_SHUTTER)
	_mode = M_STONE
	_collide(plan)


## An old stall row: the outline cut into stalls 2.6-4.2 m wide along its length, each clipped to
## the outline, its own height, faded wall and patched roof; on a whole (rectangular) stall an
## awning over one long side and a stack of crates before it.
func _bazar_row(q: PackedVector2Array) -> void:
	var r := _bazar_frame(q)
	var u := r.position.x
	while u < r.end.x - 0.5:
		var w := lerpf(2.6, 4.2, _bazar_rand(_w(u, 0.0), 1))
		var u1 := minf(u + w, r.end.x)
		if r.end.x - u1 < 1.8:
			u1 = r.end.x
		var cell := _rect((u + u1) * 0.5, r.get_center().y, (u1 - u) * 0.5, r.size.y * 0.5 + 0.5)
		var pieces := Geometry2D.intersect_polygons(cell, q)
		var spot := _w(u, r.position.y)
		if not pieces.is_empty():
			var piece := _largest(pieces)
			if piece.size() >= 3 and absf(_area(piece)) > 2.0:
				var g := _ground_under(piece)
				_g = g
				var top := g + lerpf(2.5, 3.3, _bazar_rand(spot, 2))
				var wall := Color(BAZAR_WALLS[int(_bazar_rand(spot, 3) * BAZAR_WALLS.size()) % BAZAR_WALLS.size()])
				var roof := Color(BAZAR_ROOFS[int(_bazar_rand(spot, 4) * BAZAR_ROOFS.size()) % BAZAR_ROOFS.size()])
				_prism(piece, g - 0.2, top, wall, roof, M_STONE, M_STONE)
				# The old roofs are patched (F's look check: keep them apart from the kiosks' clean
				# green tops): a sheet or a tarp of another colour over part of most stalls.
				if _bazar_rand(spot, 10) < 0.7:
					var pu := lerpf(u + 0.3, u1 - 0.3, _bazar_rand(spot, 11))
					var pv := r.get_center().y + (r.size.y * 0.5) * (_bazar_rand(spot, 12) - 0.5)
					var patch := _rect(pu, pv, maxf((u1 - u) * 0.28, 0.6), maxf(r.size.y * 0.22, 0.8))
					var pc := Color(BAZAR_ROOFS[int(_bazar_rand(spot, 13) * BAZAR_ROOFS.size()) % BAZAR_ROOFS.size()])
					if pc.is_equal_approx(roof):
						pc = roof.lightened(0.25)
					for pq: PackedVector2Array in Geometry2D.intersect_polygons(patch, piece):
						if pq.size() >= 3 and not Geometry2D.is_polygon_clockwise(pq):
							_cap(pq, top + 0.04, pc)
				var whole := absf(_area(piece)) > 0.9 * (u1 - u) * r.size.y
				if whole and r.size.y < 14.0:
					var sv := -1.0 if _bazar_rand(spot, 5) < 0.5 else 1.0
					var edge := r.get_center().y + sv * r.size.y * 0.5
					var col := Color(BAZAR_AWNINGS[int(_bazar_rand(spot, 6) * BAZAR_AWNINGS.size()) % BAZAR_AWNINGS.size()])
					var a0 := _w(u + 0.15, edge)
					var a1 := _w(u1 - 0.15, edge)
					var b0 := _w(u + 0.15, edge + sv * 1.3)
					var b1 := _w(u1 - 0.15, edge + sv * 1.3)
					var hi := top - 0.35
					var lo := top - 0.9
					var n := (Vector3(_b.x, 0.0, _b.y) * sv * 0.55 + Vector3.UP * 1.3).normalized()
					_quad(Vector3(a0.x, hi, a0.y), Vector3(a1.x, hi, a1.y), Vector3(b1.x, lo, b1.y), Vector3(b0.x, lo, b0.y), n, col)
					# the shop front under it: a dark opening, or a closed shutter
					var open := _bazar_rand(spot, 7) < 0.7
					_wall(_w(u + 0.4, edge + sv * 0.03), _w(u1 - 0.4, edge + sv * 0.03), g + 0.3, lo - 0.1, _b * sv,
							BAZAR_DOOR if open else BAZAR_SHUTTER)
					if open and _bazar_rand(spot, 8) < 0.6:
						var cu := lerpf(u + 0.7, u1 - 0.7, _bazar_rand(spot, 9))
						_lbox(cu, edge + sv * 0.75, 0.35, 0.28, g, g + 0.55, BAZAR_CRATE, M_STONE, BAZAR_CRATE.lightened(0.1))
				_collide(piece)
		u = u1
