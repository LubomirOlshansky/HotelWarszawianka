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
	# The Arka's cut (F's photos, 2026-11-21): OSM's slivers of "building" along its cheek walls, the
	# headwall's strip and the flights' outlines stood as boxes in the cut; the site draws them.
	var arka_zone := PackedVector2Array([Vector2(1636.6, -728.1), Vector2(1665.1, -679.9), Vector2(1638.9, -664.4), Vector2(1610.3, -712.5)])
	_add_site("stadium", [zone, arka_zone])
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
## F's night photos (2026-11-21): the spikes' tip lamps and the rim's line of light (pale by day).
const STADIUM_TIP := Color(0.96, 0.97, 1.0)
const STADIUM_RIM_LIGHT := Color(0.84, 0.87, 0.92)
const STADIUM_LAMP := Color("#fff1cf")
## The stairs' light lines (pale sand by day, warm at night), on the mapped stairs within STAIR_REACH m of the centre.
const STADIUM_STAIR := Color("#e0701a")
const STAIR_REACH := 270.0
## The stairs' light lines: one per step (F's drone photo, 2026-11-21).
const STAIR_STEP := 0.6
## F (2026-11-21): the flights read as dark slabs with thin stripes from the heli's 485 m view.
## Each line is now over half the step, so a flight reads as a glowing ladder.
const STAIR_LINE := 0.36
## The handrail light: its height over the treads and its bright warm white (F's night photo).
const STAIR_RAIL := 0.95
const STADIUM_RAIL := Color("#f2822a")
## The lines ride over the stone treads (map_builder rounds the ground up to whole risers of
## 0.16 m): at ground level they were hidden under the treads in checkered bits.
const STAIR_LIFT := 0.19
## F's drone photo (2026-11-21): the broad flights up the embankment at the ends of the
## avenues have a lit portal in their middle, a passage into the bank under the promenade.
const PORTAL_STAIR_W := 20.0
const PORTAL_W := 9.0
## Only a long flight has one (the short wide ones are landings at the promenade).
const PORTAL_MIN_RUN := 10.0
const PORTAL_CONCRETE := Color("#b9b6ae")
const PORTAL_GLOW := Color("#ffd89a")
## The Arka (F's photos, 2026-11-21): the road tunnel under the stadium's east plaza, between its
## two stair blocks (OSM service road 2156). The mouth's centre, the way out (east), the front
## wall's half width and top, the opening's half width and the springing of its arch.
const ARKA_AT := Vector2(1650.0, -703.5)
const ARKA_OUT := Vector2(0.86, -0.51)
const ARKA_HALF := 9.0
const ARKA_TOP := 10.5
const ARKA_OPEN := 5.0
const ARKA_RIM := 0.9
const ARKA_DEPTH := 1.5
## Where the headwall stands: this far back along the cut from ARKA_AT (the terrain rises there).
const ARKA_BACK := 25.5
const ARKA_SPRING := 4.0
const ARKA_RISE := 3.5
const ARKA_GRANITE := Color("#6e655a")
const ARKA_WHITE := Color("#e9e6df")
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
		# F's photos (2026-11-21): the white masts stand clear in front of the skin all the way up,
		# so the basket leans a little less than the masts (it was 0.25 / 0.62: they hid in it).
		mid.append(vi + (vo - vi) * 0.13)
		top.append(vi + (vo - vi) * 0.52)
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
	# F's night photos (2026-11-21): lamp posts round the promenade's outer edge, one every
	# other mast, and lines of warm light across the mapped stairs down the embankment.
	for k in range(0, n, 2):
		var lp: Vector2 = c + ((inner[k] as Vector2) - c) * (PROM_TO - 0.008)
		_prism(_circle(lp, 0.12, 4), deck[k], deck[k] + 4.6, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
		_prism(_circle(lp, 0.32, 4), deck[k] + 4.6, deck[k] + 5.0, STADIUM_LAMP, STADIUM_LAMP, M_LAMP, M_LAMP)
	# F's drone photo: a warm line of light along the promenade's outer edge, at the facade's foot.
	_mode = M_LAMP
	for k in n:
		var k1 := (k + 1) % n
		var ea: Vector2 = c + ((inner[k] as Vector2) - c) * PROM_TO
		var eb: Vector2 = c + ((inner[k1] as Vector2) - c) * PROM_TO
		var ia: Vector2 = c + ((inner[k] as Vector2) - c) * (PROM_TO - 0.006)
		var ib: Vector2 = c + ((inner[k1] as Vector2) - c) * (PROM_TO - 0.006)
		_quad(Vector3(ia.x, deck[k] + 0.05, ia.y), Vector3(ib.x, deck[k1] + 0.05, ib.y),
				Vector3(eb.x, deck[k1] + 0.05, eb.y), Vector3(ea.x, deck[k] + 0.05, ea.y), Vector3.UP, STADIUM_STAIR)
	for st: Dictionary in data.get("steps", []):
		var sp: Array = st["p"]
		var w := float(st.get("w", 0.0))
		if sp.size() < 4 or w < 7.0:
			continue
		var s0 := Vector2(float(sp[0]), float(sp[1]))
		var s1 := Vector2(float(sp[sp.size() - 2]), float(sp[sp.size() - 1]))
		if (s0 + s1).distance_to(c * 2.0) > STAIR_REACH * 2.0:
			continue
		var run_len := s0.distance_to(s1)
		var e := (s1 - s0) / maxf(run_len, 0.01)
		var side := Vector2(-e.y, e.x)
		var half := side * w * 0.47
		# F's drone photo (2026-11-21): every step's nosing glows, so a flight reads as a
		# block of gold lines from the air; a lit strip runs down both of its edges.
		var t := 0.3
		while t < run_len - 0.2:
			var m0 := s0 + e * t
			var m1 := m0 + e * 0.2
			var y0: float = _stair_top(m0, side * w * 0.5) + STAIR_LIFT
			var y1: float = _stair_top(m1, side * w * 0.5) + STAIR_LIFT
			if w >= PORTAL_STAIR_W and run_len >= PORTAL_MIN_RUN:
				# The portal's block covers the flight's middle: a line on each side of it.
				var gap := side * PORTAL_W * 0.5 + side * 0.6
				for sg in [-1.0, 1.0]:
					var g0: Vector2 = gap * sg
					var g1: Vector2 = half * sg
					_quad(Vector3(m0.x + g0.x, y0, m0.y + g0.y), Vector3(m0.x + g1.x, y0, m0.y + g1.y),
							Vector3(m1.x + g1.x, y1, m1.y + g1.y), Vector3(m1.x + g0.x, y1, m1.y + g0.y), Vector3.UP, STADIUM_STAIR)
			else:
				_quad(Vector3(m0.x - half.x, y0, m0.y - half.y), Vector3(m0.x + half.x, y0, m0.y + half.y),
						Vector3(m1.x + half.x, y1, m1.y + half.y), Vector3(m1.x - half.x, y1, m1.y - half.y), Vector3.UP, STADIUM_STAIR)
			t += STAIR_STEP
		for sgn in [-1.0, 1.0]:
			var o0: Vector2 = side * (w * 0.5 - 0.15) * sgn
			var o1: Vector2 = side * (w * 0.5 - 0.5) * sgn
			var k := 0.0
			while k < run_len - 0.01:
				var k2 := minf(k + 3.0, run_len)
				var q0 := s0 + e * k
				var q1 := s0 + e * k2
				var h0: float = _stair_top(q0, side * w * 0.5) + STAIR_LIFT
				var h1: float = _stair_top(q1, side * w * 0.5) + STAIR_LIFT
				# F (2026-11-21): the handrails glow along the whole flight, at hand height, so each
				# flight reads from the air as a bright diagonal.
				# A lit ribbon on the rail's inner face ties it to the tread (its foot lies on the ground), so the rail does not float.
				_quad(Vector3(q0.x + o0.x, h0 + STAIR_RAIL, q0.y + o0.y), Vector3(q0.x + o1.x, h0 + STAIR_RAIL, q0.y + o1.y),
						Vector3(q1.x + o1.x, h1 + STAIR_RAIL, q1.y + o1.y), Vector3(q1.x + o0.x, h1 + STAIR_RAIL, q1.y + o0.y), Vector3.UP, STADIUM_RAIL)
				_quad(Vector3(q0.x + o1.x, h0, q0.y + o1.y), Vector3(q1.x + o1.x, h1, q1.y + o1.y),
						Vector3(q1.x + o1.x, h1 + STAIR_RAIL, q1.y + o1.y), Vector3(q0.x + o1.x, h0 + STAIR_RAIL, q0.y + o1.y),
						Vector3(-side.x * sgn, 0.0, -side.y * sgn), STADIUM_RAIL)
				k = k2
		if w >= PORTAL_STAIR_W and run_len >= PORTAL_MIN_RUN:
			_stadium_portal(s0, s1, w)
			_mode = M_LAMP
	_mode = M_STONE
	_stadium_arka()

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
		# F's night photos (2026-11-21): a line of light along the rim's foot, its own grey by day.
		var e0 := edge[k] + (edge[k] - c).normalized() * 0.05
		var e1 := edge[k1] + (edge[k1] - c).normalized() * 0.05
		_mode = M_LAMP
		_quad(Vector3(e0.x, roof_y - 1.6, e0.y), Vector3(e1.x, roof_y - 1.6, e1.y),
				Vector3(e1.x, roof_y - 1.0, e1.y), Vector3(e0.x, roof_y - 1.0, e0.y), on, STADIUM_RIM_LIGHT)
		_mode = M_STONE
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
		# F's night photos (2026-11-21): a white lamp on every spike's tip.
		var tip := b + (b - a).normalized() * 0.4
		_prism(_circle(Vector2(tip.x, tip.z), 0.6, 4), tip.y - 0.2, tip.y + 0.9, STADIUM_TIP, STADIUM_TIP, M_LAMP, M_LAMP)
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


# --- Port Praski (F, 2026-11-20; spec docs/landmarks/specs/port_praski.md) -----------------------

## Port Praski, the Praga bank's river port: dug from 1919, never finished, closed in 1980 and a
## fenced wasteland for forty years; since 2016 a housing quarter in a "Praga tenement" style.
## Each new block (APA, ADS: 7-8 storeys, 24-27 m) has its fronts cut into tenement-wide
## sections, each in its own material: dark red clinker, grey-brown brick, cream limestone,
## copper-framed loggias, sandstone (refs/port-praski: 90 Mapillary photos 2025-26, Bryła's view
## of Sierakowskiego 1-3 over the basin). OpenStreetMap maps them as plain outlines, newer than
## GUGiK's 2018 survey (no LoD2), so the site rebuilds every one of them, found by the vertex
## mean of its outline: [mean, look]. Looks: "row" the tenement sections, "latarnia" the brown
## tower with stacked timber loggias on Okrzei, "works" Krowia 6 (the restored red-brick works
## with its glass storey, the brick-and-glass tower behind it), "minter" the Minter tenement on
## Okrzei (1860-63, Korczak's school, a hotel from 2026: HOTEL AHOJ), "garden" the courtyard deck.
const PP_BLOCKS := [
	[Vector2(380.9, -1582.1), "latarnia"],  # Latarnia, Okrzei / Wybrzeże Szczecińskie (2016)
	[Vector2(417.7, -1611.9), "row"],       # Port, Okrzei 2 (2016)
	[Vector2(485.7, -1598.5), "row"],       # Port II, the basin side (2016-21)
	[Vector2(518.3, -1630.3), "row"],       # Port II on Krowia
	[Vector2(546.4, -1661.1), "works"],     # Krowia 6
	[Vector2(519.8, -1683.6), "row"],       # Krowia / Okrzei
	[Vector2(580.2, -1681.9), "row"],       # Sierakowskiego 4
	[Vector2(607.6, -1616.0), "row"],       # Sierakowskiego 5, round its garden court
	[Vector2(642.4, -1583.0), "row"],       # Sierakowskiego 1-3 on the quay (2024)
	[Vector2(665.9, -1692.7), "row"],       # Sierakowskiego 2, round its garden deck
	[Vector2(636.3, -1740.2), "row"],       # Sierakowskiego / Okrzei
	[Vector2(453.3, -1646.6), "minter"],    # the Minter tenement, Okrzei
	[Vector2(681.9, -1682.0), "garden"],    # Sierakowskiego 2's courtyard deck (over its garage)
]
## The basin's own buildings, the same way: the lock's control tower (red brick, a glass room
## on top) and its two pump houses at the lock's heads, and the long white sheds on the south
## pier (the rowing and rescue station's, photo 1668958797675054).
const PP_BASIN := [
	[Vector2(500.1, -1504.1), "tower"],
	[Vector2(504.5, -1483.0), "pump"],
	[Vector2(544.4, -1492.7), "pump"],
	[Vector2(552.5, -1449.4), "pier"],
	[Vector2(577.2, -1428.4), "pier"],
	[Vector2(592.2, -1412.5), "pier"],
	[Vector2(627.5, -1407.3), "pier"],
]
## How near an outline's vertex mean must lie to a listed one (metres).
const PP_FIND := 2.0
## The tenement sections: [wall, facade seed (building.gdshader facade(): storey 3.0-3.2 m, the
## window rhythm), trim (the joints, ledges and slabs)]. Read off the photos: Port II's clinker
## and limestone, Sierakowskiego 1-3's cream stone, red brick and copper loggias.
const PP_LOOKS := [
	[Color("#8a4434"), 0.18, Color("#6b3328")],   # 0 dark red clinker, wide French windows
	[Color("#857565"), 0.43, Color("#695c50")],   # 1 grey-brown brick
	[Color("#d9d0c0"), 0.31, Color("#bcb2a1")],   # 2 cream limestone, stone ledges
	[Color("#5c3f33"), 0.73, Color("#a0663f")],   # 3 copper loggias: a dark wall behind copper frames
	[Color("#a8553d"), 0.86, Color("#85412f")],   # 4 red brick
	[Color("#c9b79a"), 0.985, Color("#ab9a7f")],  # 5 sandstone
]
const PP_SECTION := 11.5        # a tenement section's width along a front (metres, about)
const PP_ROOF := Color("#a9a8a2")
const PP_GREEN_ROOF := Color("#7f9658")
const PP_GLASS := Color("#9fb6c0")    # the balconies' glass fronts
const PP_SLAB := Color("#cfcac0")     # their slabs
const PP_BRICK := Color("#a34f39")    # Krowia 6 and the lock's red brick
const PP_BRICK_TRIM := Color("#c2735b")
const PP_MINTER := Color("#d8c39a")   # the Minter tenement's warm plaster
const PP_TIMBER := Color("#8a5a3a")   # Latarnia's loggia frames


func _pp_mean(q: PackedVector2Array) -> Vector2:
	var s := Vector2.ZERO
	for p in q:
		s += p
	return s / maxf(q.size(), 1)


func _find_port_praski() -> void:
	var parts: Array = []
	var zone: Array[PackedVector2Array] = []
	var basin: Array = []
	var bzone: Array[PackedVector2Array] = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var m := _pp_mean(q)
		if m.x < 360.0 or m.x > 700.0 or m.y < -1760.0 or m.y > -1395.0:
			continue
		for spec: Array in PP_BLOCKS:
			if m.distance_to(spec[0]) < PP_FIND:
				parts.append([q, float(bld["h"]), str(spec[1])])
				zone.append(q)
				# A bent outline's centre can lie outside it (the plain block would stay and
				# z-fight the model): its hull joins the zone (Sierakowskiego 2's hull holds
				# the courtyard deck, which is ours too).
				var hull := Geometry2D.convex_hull(q)
				if hull.size() >= 4:
					zone.append(hull)
		for spec: Array in PP_BASIN:
			if m.distance_to(spec[0]) < PP_FIND:
				basin.append([q, float(bld["h"]), str(spec[1])])
				bzone.append(q)
	if not parts.is_empty():
		_add_site("port_praski", zone)
		if not sites.is_empty() and sites[-1]["key"] == "port_praski":
			sites[-1]["parts"] = parts
	# The basin's site reaches the quay, the hoarding and the lock as well as its buildings.
	var reach: Array[PackedVector2Array] = []
	reach.append(_box_poly(Rect2(488.0, -1640.0, 545.0, 245.0)))
	_add_site("pp_basin", bzone if not bzone.is_empty() else reach)
	if not sites.is_empty() and sites[-1]["key"] == "pp_basin":
		sites[-1]["parts"] = basin
		sites[-1]["box"] = _box_of(reach + bzone)


# --- the new blocks ---

func _build_port_praski(site: Dictionary) -> void:
	_pp_rings.clear()
	for p: Array in site["parts"]:
		_pp_rings.append(p[0])
	for p: Array in site["parts"]:
		var raw: PackedVector2Array = p[0]
		_pp_self = raw
		var ring := _simplify(raw, 0.25)
		if ring.size() < 3 or absf(_area(ring)) < 20.0:
			continue
		if Geometry2D.is_polygon_clockwise(ring):
			ring.reverse()
		var g := _ground_under(ring)
		_g = g
		var look: String = p[2]
		match look:
			"latarnia":
				_pp_row(ring, g, float(p[1]), [3])
			"works":
				_pp_works(ring, g, float(p[1]))
			"minter":
				_pp_minter(ring, g)
			"garden":
				_pp_garden(ring, g)
				continue
			_:
				_pp_row(ring, g, float(p[1]), [])
		_collide(raw)
		pocket_rings.append(raw)
	_mode = M_STONE


## Every part's outline while Port Praski builds, and the one building now: a wall that stands
## against a neighbour (OSM's shared party walls) is inside the block and is left out, or the two
## back-to-back walls flicker.
var _pp_rings: Array[PackedVector2Array] = []
var _pp_self := PackedVector2Array()


func _pp_party_wall(p: Vector2) -> bool:
	for r in _pp_rings:
		if r != _pp_self and Geometry2D.is_point_in_polygon(p, r):
			return true
	return false


## A seeded 0..1 for a section (the same every run and every sector).
func _pp_rand(p: Vector2, salt: int) -> float:
	return _bazar_rand(p * 0.37, salt + 101)


## A box standing on a front: from p0 to p1 along it, d0 to d1 metres out (`o` the outward
## normal), y0 to y1; its sides and top (its foot never shows).
func _pp_band(p0: Vector2, p1: Vector2, o: Vector2, d0: float, d1: float, y0: float, y1: float, col: Color) -> void:
	var poly := PackedVector2Array([p0 + o * d0, p1 + o * d0, p1 + o * d1, p0 + o * d1])
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	_prism(poly, y0, y1, col, col.lightened(0.04), M_STONE, M_STONE)


## A block in tenement sections (the "row" look): every front cut into sections about
## PP_SECTION wide, each its own look (PP_LOOKS, seeded by its place; `only` limits the looks),
## its own window rhythm (the facade shader's seed, shops on the ground floor), its own parapet
## height (the row's broken skyline), joints between the sections, stone ledges on the limestone,
## copper or timber frames round the loggias, glass balconies on some brick sections.
func _pp_row(ring: PackedVector2Array, g: float, h: float, only: Array) -> void:
	var top := g + h
	var run := 0.0
	var last := -1
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var o := _out(ring, a, b)
		var t := (b - a) / length
		var n := maxi(1, roundi(length / PP_SECTION))
		for k in n:
			var s0 := a + t * (length * k / n)
			var s1 := a + t * (length * (k + 1) / n)
			var mid := (s0 + s1) * 0.5
			var pick := int(_pp_rand(mid, 1) * 6.0) % 6
			if not only.is_empty():
				pick = int(only[0])
			elif pick == last:
				pick = (pick + 1 + int(_pp_rand(mid, 2) * 4.0)) % 6
			last = pick
			var look: Array = PP_LOOKS[pick]
			var wall: Color = look[0]
			var trim: Color = look[2]
			if not only.is_empty():
				trim = PP_TIMBER
			var seed: float = look[1]
			var seg := s0.distance_to(s1)
			if _pp_party_wall(mid + o * 0.4):
				continue
			_mode = seed
			_wall(s0, s1, g - 0.3, top, o, wall, run + length * k / n)
			_mode = M_STONE
			if seg < 4.0:
				continue
			# The broken skyline: a section's parapet 0, 0.9 or 1.8 m over the roof.
			var lift: float = [0.0, 0.0, 0.9, 1.8][int(_pp_rand(mid, 3) * 4.0) % 4] if only.is_empty() else 0.0
			if lift > 0.0:
				_pp_band(s0, s1, o, -0.35, 0.0, top, top + lift, wall)
			# The joint before each section (a pier in the next one's trim, a little proud).
			if k > 0 or i > 0:
				_pp_band(s0 - t * 0.22, s0 + t * 0.22, o, 0.0, 0.16, g + 3.2, top + lift, trim)
			var fh := 3.0 + 0.7 * fposmod(seed * 7.13, 1.0)
			var floors := floori(h / fh)
			match pick:
				2:
					# limestone: a ledge every second storey and a cornice
					var j := 2
					while j < floors:
						_pp_band(s0, s1, o, 0.0, 0.14, g + j * fh - 0.12, g + j * fh + 0.06, trim)
						j += 2
					_pp_band(s0, s1, o, 0.0, 0.3, top + lift - 0.45, top + lift, trim)
				3:
					# loggias: frames at every floor slab and at both ends of the section
					for j in range(1, floors + 1):
						_pp_band(s0 + t * 0.2, s1 - t * 0.2, o, 0.0, 0.75, g + j * fh - 0.28, g + j * fh, trim)
					for e: Vector2 in [s0 + t * 0.2, s1 - t * 0.45]:
						_pp_band(e, e + t * 0.25, o, 0.0, 0.75, g + fh, top + lift, trim)
				_:
					if (pick == 0 or pick == 1 or pick == 4) and _pp_rand(mid, 4) < 0.55 and seg >= 7.0:
						# glass balconies (kit PARAPET in glass) in every third window bay
						var sp := 2.2 + 1.4 * fposmod(seed * 3.71, 1.0)
						var run0 := run + length * k / n
						var flip := Vector2(-t.y, t.x).dot(o) < 0.0
						if flip:
							kit_front(s1, s0)
						else:
							kit_front(s0, s1)
						var bay := ceili(run0 / sp - 0.5)
						while true:
							var u := (bay + 0.5) * sp - run0
							bay += 1
							if u > seg - 1.2:
								break
							if u < 1.2 or bay % 3 != 0:
								continue
							for j in range(1, floors):
								kit_balcony(seg - u if flip else u, g + j * fh + 0.26, 0.95, Balcony.PARAPET, PP_GLASS, PP_SLAB, 1.2)
		run += length
	_mode = M_STONE
	_cap(ring, top, PP_ROOF)
	# A big roof: a planted patch and a plant room (the photos' green roofs, rooftop masts).
	if absf(_area(ring)) > 700.0:
		var c := _centre(ring)
		if Geometry2D.is_point_in_polygon(c, ring) and _dist_to_ring(c, ring) > 6.0:
			_prism(_square(c, 2.2), top, top + 2.4, Color("#8f8e89"), Color("#7d7c77"), M_STONE, M_STONE)
			var d := Vector2(4.5, 0.0) if _dist_to_ring(c + Vector2(4.5, 0.0), ring) > 4.0 else Vector2(0.0, 4.5)
			if _dist_to_ring(c + d, ring) > 4.0:
				_prism(_square(c + d, 2.6), top, top + 0.35, PP_ROOF.darkened(0.1), PP_GREEN_ROOF, M_STONE, M_STONE)




## Krowia 6: the restored red-brick works (three tall storeys, arched windows, a glass and white
## storey on top) along the street fronts that face the corner of Krowia (photos 1572343553967513,
## 1227635669243797), and behind it the tower (brick and glass, terraces) up to the outline's height.
func _pp_works(ring: PackedVector2Array, g: float, h: float) -> void:
	var corner := Vector2(552.6, -1623.0)   # where the photos were taken from
	var towards := (corner - _centre(ring)).normalized()
	var strips: Array[PackedVector2Array] = []
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var o := _out(ring, a, b)
		if a.distance_to(b) >= 8.0 and o.dot(towards) > 0.35:
			var s := PackedVector2Array([a + o * 0.5, b + o * 0.5, b - o * 13.0, a - o * 13.0])
			if Geometry2D.is_polygon_clockwise(s):
				s.reverse()
			strips.append(s)
	# The strips of two facing edges overlap at their corner: one outline for them all first, so
	# no two old pieces stand in each other (coplanar walls and tops flicker).
	var merged: Array[PackedVector2Array] = []
	for s in strips:
		var cur := s
		var rest: Array[PackedVector2Array] = []
		for m in merged:
			var u := Geometry2D.merge_polygons(cur, m)
			var outer: Array[PackedVector2Array] = []
			for q in u:
				if not Geometry2D.is_polygon_clockwise(q):
					outer.append(q)
			if outer.size() == 1:
				cur = outer[0]
			else:
				rest.append(m)
		rest.append(cur)
		merged = rest
	var old: Array[PackedVector2Array] = []
	for s in merged:
		for r in Geometry2D.intersect_polygons(ring, s):
			if r.size() >= 3 and not Geometry2D.is_polygon_clockwise(r) and absf(_area(r)) > 40.0:
				old.append(r)
	var tower: Array[PackedVector2Array] = [ring]
	for r in old:
		var next: Array[PackedVector2Array] = []
		for piece in tower:
			for q in Geometry2D.clip_polygons(piece, _grown(r, 0.06)):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		tower = next
	for piece in tower:
		if absf(_area(piece)) < 30.0:
			continue
		_pp_row(_simplify(piece, 0.2), g, h, [1])
	var y1 := g + 13.8
	for r in old:
		var piece := _simplify(r, 0.2)
		_prism(piece, g - 0.3, y1, PP_BRICK, Color(0, 0, 0, 0), M_STONE)
		for i in piece.size():
			var a := piece[i]
			var b := piece[(i + 1) % piece.size()]
			var length := a.distance_to(b)
			if length < 5.0 or _dist_to_ring((a + b) * 0.5, ring) > 0.4:
				continue
			kit_front(a, b)
			if _out(piece, a, b).dot(_b) < 0.0:
				kit_front(b, a)
			var bays := maxi(1, floori(length / 3.1))
			kit_window_grid(0.9, length - 0.9, bays, [g + 0.9, g + 5.4, g + 9.6], [3.0, 2.9, 2.7], Win.ARCHED,
					PP_BRICK_TRIM, PAL_GLASS_DARK, 0.62)
			kit_ledge(0.0, length, g + 4.6, 0.22, PP_BRICK_TRIM)
		_ring_slab(piece, y1 - 0.5, y1, 0.35, PP_BRICK_TRIM)
		# the glass storey set back on it, white-framed
		var top := _largest(Geometry2D.offset_polygon(piece, -1.4, Geometry2D.JOIN_MITER))
		if top.size() >= 3:
			_prism(top, y1, y1 + 3.2, PP_GLASS.darkened(0.15), Color(0, 0, 0, 0), M_PAVILION + 0.5)
			_ring_slab(top, y1 + 3.2, y1 + 3.6, 0.3, Color("#eceae4"))
			_cap(top, y1 + 3.6, Color("#e4e2dc"))


## The Minter tenement (Okrzei, 1860-63, the Praga gymnasium where Korczak sat his finals; the
## AC hotel from 2026, here HOTEL AHOJ): four tall storeys in warm plaster, the typed tenement
## facade (rusticated shop floor, tall windows, a heavy cornice), a hotel sign on the Okrzei front.
func _pp_minter(ring: PackedVector2Array, g: float) -> void:
	var h := 18.2
	_prism(ring, g - 0.3, g + h, PP_MINTER, Color(0, 0, 0, 0), HouseTypes.encode(1, 0.6))
	kit_cornice_ring(ring, g + h - 0.2, PP_MINTER.lightened(0.06), 0.45, 0.6)
	_mode = M_STONE
	_cap(ring, g + h + 0.25, PAL_ROOF_GREY)
	var okrzei := Vector2(459.5, -1671.8)
	var i := _edge_facing(ring, (okrzei - _centre(ring)).normalized(), 10.0)
	if i >= 0:
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var w := kit_front(a, b)
		if _out(ring, a, b).dot(_b) < 0.0:
			w = kit_front(b, a)
		_usign("HOTEL AHOJ", w * 0.5, 0.25, g + h - 2.6, _b, minf(w * 0.6, 12.0), 1.4, Color("#f2e6c8"))


## Sierakowskiego 2's courtyard deck over its garage: a planted podium with paths and three trees.
func _pp_garden(ring: PackedVector2Array, g: float) -> void:
	_prism(ring, g - 0.3, g + 1.1, Color("#8f8a80"), PP_GREEN_ROOF, M_STONE, M_STONE)
	var c := _centre(ring)
	for k in 3:
		var p := c + Vector2.from_angle(TAU * k / 3.0 + 0.4) * 9.0
		if Geometry2D.is_point_in_polygon(p, ring) and _dist_to_ring(p, ring) > 2.5:
			_varso_tree(p, g + 1.1, 5.5, 2.2)
	_collide(ring)


# --- the basin: the open quay, the railing, the lock, the pier, the Doki hoarding ---

## The north quay's water edge from the lock to the basin's end, 0.6 m inland (read off the
## water map, x every 20 m): the railing runs along it.
const PP_QUAY := [Vector2(550.0, -1527.4), Vector2(560.0, -1530.4), Vector2(580.0, -1535.4), Vector2(600.0, -1540.4),
		Vector2(620.0, -1536.6), Vector2(640.0, -1539.4), Vector2(660.0, -1542.4), Vector2(676.0, -1546.0),
		Vector2(684.0, -1551.4), Vector2(700.0, -1551.4), Vector2(720.0, -1552.4), Vector2(740.0, -1551.4),
		Vector2(760.0, -1549.4), Vector2(780.0, -1546.4), Vector2(800.0, -1542.4), Vector2(820.0, -1538.4),
		Vector2(860.0, -1528.4), Vector2(900.0, -1519.4), Vector2(940.0, -1510.4), Vector2(980.0, -1501.4),
		Vector2(1020.0, -1491.4), Vector2(1060.0, -1482.4)]
## The open stretch of the new boulevard (October 2024, in front of Sierakowskiego 1-3): between
## the quay street's kerb and the water.
const PP_WALK := [Vector2(620.0, -1554.0), Vector2(637.0, -1553.2), Vector2(655.0, -1555.0), Vector2(677.0, -1559.0),
		Vector2(686.0, -1561.0), Vector2(686.5, -1551.6), Vector2(676.0, -1546.4), Vector2(660.0, -1542.8),
		Vector2(640.0, -1539.8), Vector2(620.0, -1537.0)]
## Its red-brick herringbone square at the east end (photo 1030459645977956).
const PP_HERRING := [Vector2(664.0, -1556.6), Vector2(685.5, -1560.6), Vector2(686.0, -1552.0), Vector2(668.0, -1545.0)]
## The timber seating steps down to the water (from, to along the quay).
const PP_SEAT_STEPS := [Vector2(631.0, -1538.2), Vector2(653.0, -1541.0)]
## The lock in the basin's mouth (2017-20): its chamber's axis from the west head to the east
## head, and the chamber's half width (the water map's channel, 8-10 m).
const PP_LOCK_A := Vector2(492.0, -1494.0)
const PP_LOCK_B := Vector2(548.0, -1506.0)
const PP_LOCK_HALF := 5.2
## The Doki building site's hoarding, black and blue "signal flags" with PORT PRASKI (photos
## 1006907995018108, 1030459645977956, 1499668478205423): round the quay's green west of the open
## stretch, and from the quay street's end east along the whole north quay. Kept off every road.
const PP_FENCE_W := [Vector2(560.0, -1606.0), Vector2(586.0, -1586.0), Vector2(616.0, -1556.0), Vector2(619.0, -1545.0)]
const PP_FENCE_E := [Vector2(690.0, -1626.0), Vector2(689.0, -1566.0), Vector2(700.0, -1556.0), Vector2(720.0, -1557.0),
		Vector2(740.0, -1556.0), Vector2(760.0, -1554.0), Vector2(780.0, -1551.0), Vector2(800.0, -1547.0),
		Vector2(820.0, -1543.0), Vector2(860.0, -1533.0), Vector2(900.0, -1524.0), Vector2(940.0, -1515.0),
		Vector2(980.0, -1506.0), Vector2(1020.0, -1496.0)]
const PP_FENCE_COLS := [Color("#151a22"), Color("#1f6fd0"), Color("#5ab7ea"), Color("#0e3b75"), Color("#151a22"), Color("#2a86d8")]
const PP_RAIL := Color("#24272a")
const PP_PAVE := Color("#b9b6ae")
const PP_HERRING_COL := Color("#8d6a5c")
const PP_CONCRETE := Color("#dcdad3")


func _build_pp_basin(site: Dictionary) -> void:
	# The pier's sheds stand wall to wall (OSM splits one long shed): one outline for those that
	# touch, so no party wall, slab or roof is drawn twice.
	var parts: Array = []
	var sheds: Array[PackedVector2Array] = []
	for p: Array in site["parts"]:
		if str(p[2]) == "tower" or str(p[2]) == "pump":
			parts.append(p)
			continue
		var cur: PackedVector2Array = _grown(p[0], 0.05)
		var rest: Array[PackedVector2Array] = []
		for m in sheds:
			var outer: Array[PackedVector2Array] = []
			for q in Geometry2D.merge_polygons(cur, m):
				if not Geometry2D.is_polygon_clockwise(q):
					outer.append(q)
			if outer.size() == 1:
				cur = outer[0]
			else:
				rest.append(m)
		rest.append(cur)
		sheds = rest
	for m in sheds:
		parts.append([m, 7.4, "shed"])
	for p: Array in parts:
		var raw: PackedVector2Array = p[0]
		var ring := _simplify(raw, 0.2)
		if ring.size() < 3:
			continue
		if Geometry2D.is_polygon_clockwise(ring):
			ring.reverse()
		var g := _ground_under(ring)
		_g = g
		match str(p[2]):
			"tower":
				# red brick to 7.5 m, the glass control room, a white roof slab over it
				_prism(ring, g - 0.3, g + 7.5, PP_BRICK, Color(0, 0, 0, 0), M_STONE)
				_ring_slab(ring, g + 7.2, g + 7.6, 0.25, PP_CONCRETE)
				_prism(ring, g + 7.6, g + 10.4, PP_GLASS.darkened(0.2), Color(0, 0, 0, 0), M_PAVILION + 0.5)
				_ring_slab(ring, g + 10.4, g + 10.9, 0.45, PP_CONCRETE)
				_cap(ring, g + 10.9, PP_CONCRETE.darkened(0.05))
			"pump":
				_prism(ring, g - 0.3, g + 4.4, PP_BRICK, PAL_ROOF_GREY, M_STONE, M_STONE)
				_ring_slab(ring, g + 4.1, g + 4.5, 0.2, PP_CONCRETE)
			_:
				# the pier's sheds: white render, two blue window bands, a flat roof
				_prism(ring, g - 0.3, g + 7.4, Color("#e8e6df"), Color(0, 0, 0, 0), M_STONE)
				_ring_slab(ring, g + 1.0, g + 2.5, 0.05, Color("#3d6b97"))
				_ring_slab(ring, g + 4.3, g + 6.1, 0.05, Color("#3d6b97"))
				_ring_slab(ring, g + 7.1, g + 7.6, 0.2, PP_CONCRETE)
				_cap(ring, g + 7.6, PAL_ROOF_PALE)
		_collide(raw)
		pocket_rings.append(raw)
	_pp_walk()
	_pp_railing()
	_pp_lock()
	_pp_fence(PackedVector2Array(PP_FENCE_W))
	_pp_fence(PackedVector2Array(PP_FENCE_E))
	_mode = M_STONE


## A flat paving laid on the terrain (each corner 6 cm over its own ground): no wall, no roof grid.
func _pp_drape(poly: PackedVector2Array, col: Color, lift := 0.06) -> void:
	var ids := Geometry2D.triangulate_polygon(poly)
	var keep := _no_roof
	_no_roof = true
	_mode = M_STONE
	for k in range(0, ids.size(), 3):
		var q: Array[Vector3] = []
		for m in 3:
			var p := poly[ids[k + m]]
			q.append(Vector3(p.x, map.terrain_height(p.x, p.y) + lift, p.y))
		_tri(q[0], q[1], q[2], Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_no_roof = keep


## The open boulevard: grey block paving, the herringbone square, lamps with a hooked arm, wooden
## benches facing the water, and the timber steps people sit on, down to the water.
func _pp_walk() -> void:
	var walk := PackedVector2Array(PP_WALK)
	if Geometry2D.is_polygon_clockwise(walk):
		walk.reverse()
	_pp_drape(walk, PP_PAVE)
	var sq := PackedVector2Array(PP_HERRING)
	if Geometry2D.is_polygon_clockwise(sq):
		sq.reverse()
	_pp_drape(sq, PP_HERRING_COL, 0.09)
	# lamps along the land side, benches along the water side
	var lamps := [Vector2(624.0, -1551.0), Vector2(642.0, -1551.4), Vector2(660.0, -1554.0), Vector2(678.0, -1557.0)]
	for p: Vector2 in lamps:
		var y: float = map.terrain_height(p.x, p.y)
		_prism(_square(p, 0.09), y, y + 6.0, Color("#8e9396"), Color(0, 0, 0, 0), M_STONE)
		_pp_band(p, p + Vector2(0.0, 1.6), Vector2(1.0, 0.0), -0.05, 0.05, y + 5.8, y + 6.0, Color("#8e9396"))
		_prism(_square(p + Vector2(0.0, 1.5), 0.22), y + 5.55, y + 5.85, Color("#fff1c8"), Color("#8e9396"), M_LAMP, M_STONE)
	for k in 4:
		var p := Vector2(624.0 + k * 13.5, 0.0)
		p.y = -1541.5 - (p.x - 620.0) * 0.13
		if p.x > 629.0 and p.x < 655.0:
			continue  # the steps are there
		var y: float = map.terrain_height(p.x, p.y)
		var t := Vector2(1.0, 0.13).normalized()
		var o := Vector2(t.y, -t.x)   # the back away from the water
		_pp_band(p - t * 1.0, p + t * 1.0, -o, -0.25, 0.25, y + 0.42, y + 0.5, PAL_TIMBER)
		_pp_band(p - t * 1.0, p + t * 1.0, -o, -0.3, -0.24, y + 0.5, y + 0.95, PAL_TIMBER)
		for e: Vector2 in [p - t * 0.85, p + t * 0.75]:
			_pp_band(e, e + t * 0.1, -o, -0.25, 0.25, y, y + 0.42, PP_RAIL)
	# the seating steps: three timber tiers down from the quay towards the water, 0.45 m each
	var a: Vector2 = PP_SEAT_STEPS[0]
	var b: Vector2 = PP_SEAT_STEPS[1]
	var tt := (b - a).normalized()
	var water := Vector2(tt.y, -tt.x)
	if water.y < 0.0:
		water = -water   # the water lies south of the quay (+z)
	var g := minf(map.terrain_height(a.x, a.y), map.terrain_height(b.x, b.y))
	var wl: float = map.terrain_height((a.x + b.x) * 0.5 + water.x * 6.0, (a.y + b.y) * 0.5 + water.y * 6.0)
	for k in 4:
		var y := g - 0.45 * k
		if y < wl + 0.3:
			break
		_pp_band(a, b, water, -0.6 + k * 0.9, 0.3 + k * 0.9, minf(wl, y - 1.0), y, PAL_TIMBER if k % 2 == 0 else PAL_TIMBER.darkened(0.12))


## The black railing along the quay: a top rail and a post every 3 m (none at the steps).
func _pp_railing() -> void:
	for i in PP_QUAY.size() - 1:
		var a: Vector2 = PP_QUAY[i]
		var b: Vector2 = PP_QUAY[i + 1]
		var length := a.distance_to(b)
		var t := (b - a) / length
		var o := Vector2(t.y, -t.x)
		var n := maxi(1, roundi(length / 3.0))
		for k in n:
			var p0 := a + t * (length * k / n)
			var p1 := a + t * (length * (k + 1) / n)
			var m := (p0 + p1) * 0.5
			if m.x > PP_SEAT_STEPS[0].x - 0.5 and m.x < PP_SEAT_STEPS[1].x + 0.5:
				continue
			var y0: float = map.terrain_height(p0.x, p0.y)
			var y1: float = map.terrain_height(p1.x, p1.y)
			var y := minf(y0, y1)
			_pp_band(p0, p1, o, -0.03, 0.03, y + 1.0, y + 1.08, PP_RAIL)
			_pp_band(p0, p0 + t * 0.06, o, -0.03, 0.03, y0 - 0.1, y0 + 1.0, PP_RAIL)
			_pp_band(p0, p1, o, -0.015, 0.015, y + 0.12, y + 0.18, PP_RAIL)


## The lock: white concrete walls along both sides of the chamber, its two heads' striped gates
## (yellow and black, under the deck's level) and a pontoon with the rescue boats inside it.
func _pp_lock() -> void:
	var t := (PP_LOCK_B - PP_LOCK_A).normalized()
	var o := Vector2(-t.y, t.x)
	var c := (PP_LOCK_A + PP_LOCK_B) * 0.5
	var wl: float = map.terrain_height(c.x, c.y)
	for s: float in [-1.0, 1.0]:
		var e0 := PP_LOCK_A + o * s * PP_LOCK_HALF
		var e1 := PP_LOCK_B + o * s * PP_LOCK_HALF
		var gy := maxf(map.terrain_height(e0.x + o.x * s * 3.0, e0.y + o.y * s * 3.0), map.terrain_height(e1.x + o.x * s * 3.0, e1.y + o.y * s * 3.0))
		_pp_band(e0, e1, o * s, 0.0, 1.4, wl - 0.5, gy + 0.35, PP_CONCRETE)
	for u: float in [3.0, PP_LOCK_A.distance_to(PP_LOCK_B) - 3.0]:
		var p := PP_LOCK_A + t * u
		var gy: float = map.terrain_height(p.x + o.x * (PP_LOCK_HALF + 3.0), p.y + o.y * (PP_LOCK_HALF + 3.0))
		var n := 6
		for k in n:
			var v0 := -PP_LOCK_HALF + 2.0 * PP_LOCK_HALF * k / n
			var v1 := -PP_LOCK_HALF + 2.0 * PP_LOCK_HALF * (k + 1) / n
			_pp_band(p + o * v0 - t * 0.6, p + o * v1 - t * 0.6, t, 0.0, 1.2, wl - 0.3, gy - 0.4,
					Color("#e8c22c") if k % 2 == 0 else Color("#1d1d1f"))
		# the walkway over the gate
		_pp_band(p - o * (PP_LOCK_HALF + 1.4) - t * 0.9, p + o * (PP_LOCK_HALF + 1.4) - t * 0.9, t, 0.0, 1.8, gy - 0.4, gy - 0.1, PP_CONCRETE)
	# the pontoon by the north quay just inside the basin, two small boats on it
	var pa := Vector2(556.0, -1524.0)
	var pt := Vector2(0.95, 0.31).normalized()
	var po := Vector2(pt.y, -pt.x)
	var pw: float = map.terrain_height(pa.x + 4.0, pa.y + 4.0)
	_pp_band(pa, pa + pt * 18.0, po, -1.2, 1.2, pw - 0.2, pw + 0.45, Color("#9a9c9a"))
	for k in 2:
		var bc := pa + pt * (5.0 + k * 8.0) - po * 2.9
		var hull := PackedVector2Array([bc - pt * 2.8 - po * 1.0, bc + pt * 2.0 - po * 1.0, bc + pt * 3.1, bc + pt * 2.0 + po * 1.0, bc - pt * 2.8 + po * 1.0])
		if Geometry2D.is_polygon_clockwise(hull):
			hull.reverse()
		var paint := Color("#d9372e") if k == 0 else Color("#2b5fa8")
		_prism(hull, pw - 0.3, pw + 0.55, paint, Color("#efefea"), M_STONE, M_STONE)
		_prism(_square(bc - pt * 0.6, 0.75), pw + 0.55, pw + 1.6, Color("#f2f2ee"), paint, M_STONE, M_STONE)


## A hoarding along a polyline: 2.5 m panels in the black and blues of the signal flags, a
## lighter diamond on some, a post at each corner, and PORT PRASKI in white on the longest runs.
func _pp_fence(line: PackedVector2Array) -> void:
	var k := 0
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var length := a.distance_to(b)
		var t := (b - a) / length
		var o := Vector2(t.y, -t.x)
		var n := maxi(1, roundi(length / 2.5))
		for j in n:
			var p0 := a + t * (length * j / n)
			var p1 := a + t * (length * (j + 1) / n)
			var y := minf(map.terrain_height(p0.x, p0.y), map.terrain_height(p1.x, p1.y))
			var col: Color = PP_FENCE_COLS[int(_pp_rand(p0, 7) * PP_FENCE_COLS.size()) % PP_FENCE_COLS.size()]
			_pp_band(p0, p1, o, -0.04, 0.04, y - 0.1, y + 3.0, col)
			if _pp_rand(p0, 8) < 0.35:
				# a motif: a pale diamond (two triangles) on both faces
				var m := (p0 + p1) * 0.5
				var lit := Color("#c9e6f7") if col.v < 0.3 else Color("#101318")
				for s: float in [-1.0, 1.0]:
					var f := m + o * s * 0.075
					var nn := Vector3(o.x * s, 0.0, o.y * s)
					var l := f - t * 0.7
					var r := f + t * 0.7
					_quad(Vector3(l.x, y + 1.25, l.y), Vector3(f.x, y + 0.55, f.y), Vector3(r.x, y + 1.25, r.y), Vector3(f.x, y + 1.95, f.y), nn, lit)
			k += 1
		_pp_band(a - t * 0.06, a + t * 0.06, o, -0.08, 0.08, map.terrain_height(a.x, a.y) - 0.1, map.terrain_height(a.x, a.y) + 3.2, PP_RAIL)
		var ring := PackedVector2Array([a - o * 0.08, b - o * 0.08, b + o * 0.08, a + o * 0.08])
		_collide(ring)
		# the words on the long runs, both faces (the water's side reads a joke)
		if length > 35.0:
			var w := kit_front(a, b)
			var y: float = map.terrain_height((a.x + b.x) * 0.5, (a.y + b.y) * 0.5)
			_usign("PORT PRASKI", w * 0.3, 0.12, y + 0.8, _b, 11.0, 1.5, Color("#f4f6f8"))
			_usign("STATKI WKRÓTCE", w * 0.7, -0.12, y + 0.8, -_b, 14.0, 1.5, Color("#f4f6f8"))


# --- Pomnik Kościuszkowców (F 2026-11-20: "it's there", with the skaters round it) ---------------

## The monument's plinth outline on the plaza (OSM's plaza keeps it as a notch) and the soldier's
## facing: west, to the left bank, the way the division tried to cross in September 1944.
const KOSC_PLINTH := [Vector2(474.0, -1551.0), Vector2(461.0, -1548.0), Vector2(460.0, -1554.0), Vector2(472.0, -1557.0)]
const KOSC_AT := Vector2(466.7, -1552.5)
const KOSC_A := Vector2(-0.974, 0.225)
const KOSC_BRONZE := Color("#55604f")   # the green-grey patina of the bridge photos
const KOSC_GRANITE := Color("#77736d")
const KOSC_PAVING := Color("#b9b4aa")
## The skaters' granite ledges on the plaza, west of the monument: [u, v, half length, half width].
const KOSC_LEDGES := [[11.0, -7.5, 5.0, 0.45], [11.0, 7.5, 5.0, 0.45], [24.0, 0.0, 3.5, 0.45]]


func _find_kosciuszkowcy() -> void:
	_add_site("kosciuszkowcy", [PackedVector2Array(KOSC_PLINTH)])


## Pomnik Kościuszkowców (Andrzej Kasten and Bogusław Chyliński, 1985), from the Mapillary
## photos from the bridge ramp (refs/kosciuszkowcy): a 12 m bronze soldier on a dark granite
## plinth, 16 m in all, striding west to the river, his left arm flung up and out with the hand
## open (Warsaw calls it "Pięć piw proszę", five beers please), the PPSh at his right hip, the
## hood over his helmet and a cape that sweeps back and to his right like a sail down to the
## plinth. Round it the granite plaza, the skaters' ledges.
func _build_kosciuszkowcy(_site: Dictionary) -> void:
	_mon_frame(KOSC_AT, KOSC_A)
	var g := _ground_under(PackedVector2Array(KOSC_PLINTH))
	_g = g
	# the plinth: a step all round, then the dark granite block, a little narrower at its top
	_lbox(0.0, 0.0, 7.4, 3.9, g - 0.3, g + 0.35, KOSC_PAVING.darkened(0.08), M_STONE, KOSC_PAVING)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 6.4, 3.0), g + 0.35, _rect(0.0, 0.0, 6.04, 2.73), g + 3.8, KOSC_GRANITE, KOSC_GRANITE.lightened(0.05))
	_lbox(0.0, 0.0, 6.15, 2.85, g + 3.7, g + 4.0, KOSC_GRANITE.darkened(0.12), M_STONE, KOSC_GRANITE.lightened(0.05))
	var y := g + 4.0
	var bz := KOSC_BRONZE
	var k := 12.0 / 3.3
	# the legs: the left one forward and bent, the right one stretched back
	_beam(_mon_p(0.1 * k, -0.15 * k, y + 1.55 * k), _mon_p(0.75 * k, -0.2 * k, y + 0.85 * k), 0.27 * k, bz)
	_beam(_mon_p(0.75 * k, -0.2 * k, y + 0.85 * k), _mon_p(0.85 * k, -0.22 * k, y + 0.05 * k), 0.25 * k, bz)
	_beam(_mon_p(-0.05 * k, 0.15 * k, y + 1.55 * k), _mon_p(-0.75 * k, 0.2 * k, y + 0.05 * k), 0.26 * k, bz)
	_lbox(0.9 * k, -0.22 * k, 0.2 * k, 0.1 * k, y, y + 0.12 * k, bz)
	_lbox(-0.72 * k, 0.2 * k, 0.2 * k, 0.1 * k, y, y + 0.12 * k, bz)
	# the body, leaning into the stride; the hooded head with the helmet's brim
	_frustum(_rect(0.1 * k, 0.0, 0.26 * k, 0.33 * k), y + 1.45 * k, _rect(0.32 * k, 0.0, 0.22 * k, 0.36 * k), y + 2.55 * k, bz, bz)
	_beam(_mon_p(0.36 * k, 0.0, y + 2.5 * k), _mon_p(0.42 * k, 0.0, y + 2.68 * k), 0.15 * k, bz)
	_frustum(_rect(0.44 * k, 0.0, 0.17 * k, 0.16 * k), y + 2.66 * k, _rect(0.4 * k, 0.0, 0.1 * k, 0.1 * k), y + 3.05 * k, bz.darkened(0.06), bz)
	_lbox(0.5 * k, 0.0, 0.2 * k, 0.19 * k, y + 2.8 * k, y + 2.84 * k, bz.darkened(0.1))
	# the left arm flung up and out, the open hand: five fingers (five beers)
	var shoulder := _mon_p(0.36 * k, -0.34 * k, y + 2.45 * k)
	var wrist := _mon_p(1.15 * k, -1.05 * k, y + 3.45 * k)
	_beam(shoulder, wrist, 0.13 * k, bz)
	for f in 5:
		var spread := -0.5 + 0.25 * f
		var tip := _mon_p((1.15 + 0.22 * cos(spread)) * k, (-1.05 - 0.22 * sin(spread + 0.8)) * k, y + (3.45 + 0.2 + 0.05 * f) * k)
		_beam(wrist, tip, 0.035 * k, bz)
	# the right arm down to the hip and the PPSh: the barrel forward, the drum under it
	var rs := _mon_p(0.3 * k, 0.36 * k, y + 2.4 * k)
	var rh := _mon_p(0.42 * k, 0.42 * k, y + 1.7 * k)
	_beam(rs, rh, 0.12 * k, bz)
	_beam(_mon_p(0.1 * k, 0.42 * k, y + 1.62 * k), _mon_p(1.05 * k, 0.4 * k, y + 1.82 * k), 0.07 * k, bz.darkened(0.12))
	_mode = M_STONE
	_frustum(_circle(_w(0.55 * k, 0.42 * k), 0.13 * k, 8), y + 1.45 * k, _circle(_w(0.55 * k, 0.42 * k), 0.13 * k, 8), y + 1.62 * k, bz.darkened(0.12), bz.darkened(0.12))
	# the cape: from the hood and both shoulders back and out to his right, a sail down to the plinth
	var cb := bz.darkened(0.08)
	var hood := _mon_p(0.25 * k, 0.0, y + 3.0 * k)
	var sl := _mon_p(0.2 * k, -0.4 * k, y + 2.5 * k)
	var sr := _mon_p(0.2 * k, 0.4 * k, y + 2.5 * k)
	var far_top := _mon_p(-1.1 * k, 1.25 * k, y + 2.75 * k)
	var far_low := _mon_p(-1.35 * k, 1.55 * k, y + 0.35 * k)
	var back_low := _mon_p(-1.0 * k, -0.3 * k, y + 0.25 * k)
	var mid := _mon_p(-1.25 * k, 0.55 * k, y + 1.4 * k)
	# the cape's bulk: a second, darker fold behind the sail, so it reads as a heavy wedge from the
	# side too and not as one sheet (the bridge photos: a trapezoid as wide as the man is tall)
	var fold_top := _mon_p(-1.45 * k, 1.0 * k, y + 2.35 * k)
	var fold_low := _mon_p(-1.6 * k, 1.2 * k, y + 0.3 * k)
	var nape := _mon_p(-0.4 * k, 0.5 * k, y + 2.4 * k)
	var crest := _mon_p(-0.45 * k, 0.6 * k, y + 2.95 * k)
	# each quad as two triangles with their own normals (the cloth's quads are not flat)
	var cloth := [[hood, sr, far_top, crest, cb], [sr, far_top, far_low, mid, cb],
			[hood, crest, mid, sl, cb.lightened(0.04)], [crest, far_top, mid, mid, cb.lightened(0.04)],
			[sl, mid, far_low, back_low, cb.lightened(0.02)],
			[sl, back_low, _mon_p(0.0, -0.35 * k, y + 1.3 * k), _mon_p(0.1 * k, -0.4 * k, y + 2.2 * k), cb],
			[sr, far_top, fold_top, nape, cb.darkened(0.1)], [far_top, far_low, fold_low, fold_top, cb.darkened(0.14)],
			[nape, fold_top, fold_low, back_low, cb.darkened(0.1)]]
	for q: Array in cloth:
		var pa: Vector3 = q[0]
		var pb: Vector3 = q[1]
		var pc: Vector3 = q[2]
		var pd: Vector3 = q[3]
		_tri(pa, pb, pc, (pb - pa).cross(pc - pa).normalized(), q[4], Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		if pd != pc:
			_tri(pa, pc, pd, (pc - pa).cross(pd - pa).normalized(), q[4], Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# the skaters' ledges: low granite blocks on the plaza in front of him
	for l: Array in KOSC_LEDGES:
		var lu: float = l[0]
		var lv: float = l[1]
		var lg: float = map.terrain_height(_w(lu, lv).x, _w(lu, lv).y)
		_lbox(lu, lv, float(l[2]), float(l[3]), lg - 0.2, lg + 0.45, KOSC_GRANITE.lightened(0.12), M_STONE, KOSC_GRANITE.lightened(0.2))
		_collide(_rect(lu, lv, float(l[2]), float(l[3])))
	_collide(_rect(0.0, 0.0, 6.4, 3.0))
	_mode = M_STONE


## The portal in a broad flight (s0 its foot, s1 its head, w wide): a concrete block over the
## flight's middle from the foot to the head, its front a warm lit opening into the bank.
func _stadium_portal(s0: Vector2, s1: Vector2, w: float) -> void:
	var run_len := s0.distance_to(s1)
	if run_len < PORTAL_MIN_RUN:
		return
	if map.ground_height(s1.x, s1.y) < map.ground_height(s0.x, s0.y):
		var sw := s0
		s0 = s1
		s1 = sw
	var e := (s1 - s0) / run_len
	var side := Vector2(-e.y, e.x) * PORTAL_W * 0.5
	var foot: float = map.ground_height(s0.x, s0.y)
	var head: float = maxf(map.ground_height(s1.x, s1.y), foot + 3.6)
	var poly := PackedVector2Array([s0 - side - e * 0.4, s0 + side - e * 0.4, s1 + side, s1 - side])
	_prism(poly, foot - 0.4, head + 0.25, PORTAL_CONCRETE, PORTAL_CONCRETE.darkened(0.08), M_STONE, M_STONE)
	# The opening on the block's front, inset from its edges, glowing warm at night (dark glass by day it reads as a doorway).
	var f := s0 - e * 0.46
	var o := side * 0.78
	var top := foot + minf(head - foot - 0.7, 4.2)
	_mode = M_LAMP
	_quad(Vector3(f.x - o.x, foot, f.y - o.y), Vector3(f.x + o.x, foot, f.y + o.y),
			Vector3(f.x + o.x, top, f.y + o.y), Vector3(f.x - o.x, top, f.y - o.y), Vector3(-e.x, 0.0, -e.y), PORTAL_GLOW)
	# A lit line under the block's head beam, as in the photo.
	_quad(Vector3(f.x - side.x, top + 0.35, f.y - side.y), Vector3(f.x + side.x, top + 0.35, f.y + side.y),
			Vector3(f.x + side.x, top + 0.5, f.y + side.y), Vector3(f.x - side.x, top + 0.5, f.y - side.y), Vector3(-e.x, 0.0, -e.y), PORTAL_GLOW)
	_mode = M_STONE


## The Arka (F's photos, 2026-11-21): the stadium's east pedestrian entrance, a granite headwall at the
## foot of the embankment, at the end of the sunken service road (OSM 2156) that runs down the cut,
## with a tall white-rimmed arch and lit glass doors, the stair flights running up on both sides.
## The wall closes the cut: its top is level with the terrace the flights climb to.
func _stadium_arka() -> void:
	var e := ARKA_OUT.normalized()
	var side := Vector2(-e.y, e.x)
	var a := ARKA_AT - e * ARKA_BACK
	var g: float = map.ground_height(a.x + e.x * 2.0, a.y + e.y * 2.0)
	var n3 := Vector3(e.x, 0.0, e.y)
	# The slab behind the doorway's recess (1.3 m deep, so the lit glass shows through the arch),
	# and a cap over the recess.
	var front := a - e * 1.3
	var back := a - e * (1.3 + ARKA_DEPTH)
	_prism(PackedVector2Array([front - side * ARKA_HALF, front + side * ARKA_HALF, back + side * ARKA_HALF, back - side * ARKA_HALF]),
			g - 3.0, g + ARKA_TOP, ARKA_GRANITE, PORTAL_CONCRETE, M_STONE, M_STONE)
	var cap0 := a + e * 0.05
	_quad(Vector3(cap0.x - side.x * ARKA_HALF, g + ARKA_TOP, cap0.y - side.y * ARKA_HALF), Vector3(cap0.x + side.x * ARKA_HALF, g + ARKA_TOP, cap0.y + side.y * ARKA_HALF),
			Vector3(front.x + side.x * ARKA_HALF, g + ARKA_TOP, front.y + side.y * ARKA_HALF), Vector3(front.x - side.x * ARKA_HALF, g + ARKA_TOP, front.y - side.y * ARKA_HALF), Vector3.UP, PORTAL_CONCRETE)
	# The arch: points along an ellipse from one springing to the other (across, up).
	var segs := 14
	var arch: Array[Vector2] = []
	for i in segs + 1:
		var ang := PI * float(i) / float(segs)
		arch.append(Vector2(-cos(ang) * ARKA_OPEN, ARKA_SPRING + sin(ang) * ARKA_RISE))
	var f := a + e * 0.05
	var at := func(u: float, v: float, d: float) -> Vector3:
		var q: Vector2 = f + side * u - e * d
		return Vector3(q.x, g + v, q.y)
	# The rim's outer edge: the arch pushed out by ARKA_RIM (from its centre).
	var rim := func(p: Vector2) -> Vector2:
		var c := Vector2(0.0, ARKA_SPRING)
		return c + (p - c) * ((p - c).length() + ARKA_RIM) / maxf((p - c).length(), 0.01)
	# The headwall's face round the rim: the piers, then the spandrel above each arch segment.
	var out_arch: Array[Vector2] = []
	for q: Vector2 in arch:
		out_arch.append(rim.call(q))
	_quad(at.call(-ARKA_HALF, -0.3, 0.0), at.call(out_arch[0].x, -0.3, 0.0), at.call(out_arch[0].x, ARKA_TOP, 0.0),
			at.call(-ARKA_HALF, ARKA_TOP, 0.0), n3, ARKA_GRANITE)
	_quad(at.call(out_arch[segs].x, -0.3, 0.0), at.call(ARKA_HALF, -0.3, 0.0), at.call(ARKA_HALF, ARKA_TOP, 0.0),
			at.call(out_arch[segs].x, ARKA_TOP, 0.0), n3, ARKA_GRANITE)
	for i in segs:
		var o0: Vector2 = out_arch[i]
		var o1: Vector2 = out_arch[i + 1]
		_quad(at.call(o0.x, o0.y, 0.0), at.call(o1.x, o1.y, 0.0), at.call(o1.x, ARKA_TOP, 0.0), at.call(o0.x, ARKA_TOP, 0.0), n3, ARKA_GRANITE)
	# The white rim, proud of the wall, with its legs down to the ground; it glows at night so it reads
	# from the wide frame.
	_mode = M_LAMP
	for i in segs:
		var i0: Vector2 = arch[i]
		var i1: Vector2 = arch[i + 1]
		_quad(at.call(i0.x, i0.y, -0.2), at.call(i1.x, i1.y, -0.2), at.call(out_arch[i + 1].x, out_arch[i + 1].y, -0.2),
				at.call(out_arch[i].x, out_arch[i].y, -0.2), n3, ARKA_WHITE)
	for sg in [-1.0, 1.0]:
		var u0: float = sg * ARKA_OPEN
		var u1: float = sg * (ARKA_OPEN + ARKA_RIM)
		_quad(at.call(minf(u0, u1), 0.0, -0.2), at.call(maxf(u0, u1), 0.0, -0.2), at.call(maxf(u0, u1), ARKA_SPRING, -0.2),
				at.call(minf(u0, u1), ARKA_SPRING, -0.2), n3, ARKA_WHITE)
	# The doors: a lit glass front set back under the arch, warm at night.
	_mode = M_LAMP
	_quad(at.call(-ARKA_OPEN, 0.0, 1.2), at.call(ARKA_OPEN, 0.0, 1.2), at.call(ARKA_OPEN, ARKA_SPRING, 1.2),
			at.call(-ARKA_OPEN, ARKA_SPRING, 1.2), n3, PORTAL_GLOW)
	for i in segs:
		var j0: Vector2 = arch[i]
		var j1: Vector2 = arch[i + 1]
		# Two triangles, the one that would have zero area at a springing left out.
		if i < segs - 1:
			_tri(at.call(j0.x, ARKA_SPRING, 1.2), at.call(j1.x, ARKA_SPRING, 1.2), at.call(j1.x, j1.y, 1.2), n3, PORTAL_GLOW,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		if i > 0:
			_tri(at.call(j0.x, ARKA_SPRING, 1.2), at.call(j1.x, j1.y, 1.2), at.call(j0.x, j0.y, 1.2), n3, PORTAL_GLOW,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# F (2026-11-21): the road to the Arka. A dark asphalt road, 8 m
	# wide, straight, as F's aerial photo shows: it runs down the middle of the cut square into the doorway.
	_mode = M_STONE
	var road_len := ARKA_BACK - 1.3  # to the cut's mouth: the plaza's own road goes on from there
	var rd0 := 0.0
	while rd0 < road_len:
		var rd1 := minf(rd0 + 1.5, road_len)
		var rp := []
		for rt: float in [rd0, rd1]:
			var k := rt / road_len
			var off := 0.0
			var c0 := a + e * (1.3 + rt) + side * off
			rp.append(c0)
		var r0: Vector2 = rp[0]
		var r1: Vector2 = rp[1]
		var ry0: float = map.ground_height(r0.x, r0.y) + 0.07
		var ry1: float = map.ground_height(r1.x, r1.y) + 0.07
		_quad(Vector3(r0.x - side.x * 5.0, ry0, r0.y - side.y * 5.0), Vector3(r0.x + side.x * 5.0, ry0, r0.y + side.y * 5.0),
				Vector3(r1.x + side.x * 5.0, ry1, r1.y + side.y * 5.0), Vector3(r1.x - side.x * 5.0, ry1, r1.y - side.y * 5.0), Vector3.UP, Color("#2a2c31"))
		rd0 = rd1
	# The cut's cheek walls and their granite parapets (map_builder SUNKEN `arka_cut`: its floor is level).
	_no_roof = true
	for sk: Dictionary in map._sunk:
		if str(sk.get("site", "")) == "stadium":
			_sunk_edges(sk)
	_no_roof = false
	_mode = M_STONE
	# Lamp posts at the top corners of the two flights that frame the entrance (F's night photo).
	for sg in [-1.0, 1.0]:
		var lq: Vector2 = a - e * 6.0 + side * (ARKA_HALF + 7.0) * sg
		var ly: float = map.ground_height(lq.x, lq.y)
		_prism(_circle(lq, 0.12, 4), ly, ly + 4.6, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
		_prism(_circle(lq, 0.32, 4), ly + 4.6, ly + 5.0, STADIUM_LAMP, STADIUM_LAMP, M_LAMP, M_LAMP)
	_mode = M_STONE


## The ground's highest point across a flight at p (centre and both edges, `half` the half-width):
## the city's stone flight (map_builder._stair_flight) lays its treads at or over that, so a lit
## line at the centre's ground sank under every other tread (F, 2026-11-21: "the lighting on the
## stairs is a little broken").
func _stair_top(p: Vector2, half: Vector2) -> float:
	return maxf(map.ground_height(p.x, p.y), maxf(map.ground_height(p.x + half.x, p.y + half.y),
			map.ground_height(p.x - half.x, p.y - half.y)))


# --- Teatr Powszechny (docs/landmarks/specs/powszechny.md) --------------------------------------

const PWS_ORIGIN := Vector2(1636.1, -1474.2)
const PWS_WEST_NORTH := Vector2(1636.5, -1464.5)
const PWS_WEST_SOUTH := Vector2(1636.1, -1402.5)
const PWS_OFFICE_TOP := 10.9
const PWS_STAGE_TOP := 11.5
const PWS_ANNEX_TOP := 12.2
const PWS_TOWER_TOP := 18.6
const PWS_FOYER := Vector2(27.0, 53.0)
const PWS_RECESS := -0.9
const PWS_FOYER_HEAD := 8.9
## Cool grey roof membrane, lifted from the dark palette value to match the aerial views in game light.
const PWS_ROOF := Color("#b9babc")


## Build the full SKINS replacement around the open court, then use the mapped ring for collision.
func _build_powszechny(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["zone"][0]
	var ring := _simplify(outline, 0.25)
	_g = map.terrain_height(1636.3, -1431.0)
	_mode = M_STONE
	_o = PWS_ORIGIN
	_a = Vector2.RIGHT
	_b = Vector2.DOWN
	var court := _urect(22.6, 34.8, 41.6, 63.6)
	var annex := _lpoly([[20.4, 0.0], [22.5, 0.2], [36.5, 1.3], [36.5, 10.0], [20.4, 10.0]])
	_powszechny_roofs(ring, court, annex)
	_powszechny_tower()
	_powszechny_plant()
	_powszechny_court(court)
	_powszechny_offices(annex)
	kit_front(PWS_WEST_NORTH, PWS_WEST_SOUTH)
	_powszechny_sign()
	_powszechny_foyer()
	_powszechny_mass(ring)
	_collide(outline)


## Close the stepped envelope and leave the west lobby open back to its recessed glazing.
func _powszechny_mass(ring: PackedVector2Array) -> void:
	var foot := _g - 1.8
	var top := _g + PWS_OFFICE_TOP
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if a == PWS_WEST_SOUTH and b == PWS_WEST_NORTH:
			continue
		_wall(a, b, foot, top, _out(ring, a, b), PAL_WHITE_STONE)
	var span := PWS_WEST_NORTH.distance_to(PWS_WEST_SOUTH)
	var head := _g + PWS_FOYER_HEAD
	var cream := PAL_SANDSTONE.lightened(0.28)
	_wall(_w(0.0, 0.0), _w(PWS_FOYER.x, 0.0), foot, _g + 2.55, _b, PAL_WHITE_STONE)
	_wall(_w(0.0, 0.0), _w(PWS_FOYER.x, 0.0), _g + 2.55, top, _b, cream)
	_wall(_w(PWS_FOYER.x, 0.0), _w(PWS_FOYER.y, 0.0), head, top, _b, PAL_WHITE_STONE)
	_wall(_w(PWS_FOYER.y, 0.0), _w(span, 0.0), foot, top, _b, PAL_WHITE_STONE)
	_wall(_w(PWS_FOYER.x, PWS_RECESS), _w(PWS_FOYER.y, PWS_RECESS), foot, head, _b, PAL_DARK_STEEL)
	_wall(_w(PWS_FOYER.x, 0.0), _w(PWS_FOYER.x, PWS_RECESS), foot, head, _a, PAL_PALE_CONCRETE)
	_wall(_w(PWS_FOYER.y, PWS_RECESS), _w(PWS_FOYER.y, 0.0), foot, head, -_a, PAL_PALE_CONCRETE)
	var soffit := _urect(PWS_FOYER.x, PWS_FOYER.y, PWS_RECESS, 0.0)
	_quad(Vector3(soffit[0].x, head, soffit[0].y), Vector3(soffit[1].x, head, soffit[1].y),
			Vector3(soffit[2].x, head, soffit[2].y), Vector3(soffit[3].x, head, soffit[3].y),
			Vector3.DOWN, PAL_DARK_STEEL)


## Run tight rows of square office lights along the east and south, with service doors at grade.
func _powszechny_offices(annex: PackedVector2Array) -> void:
	var upper := [_g + 4.8, _g + 8.0]
	var length := kit_front(Vector2(1678.0, -1402.1), Vector2(1678.7, -1469.5))
	kit_window_grid(1.2, length - 1.6, 34, upper, 1.12, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.54)
	kit_window_grid(1.0, 10.0, 5, [_g + 1.4], 0.9, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.51)
	kit_door(14.0, _g - 0.45, 2.8, 1.45, PAL_GREY_STONE, PAL_DARK_DOOR)
	kit_door(56.0, _g - 0.25, 2.95, 1.6, PAL_GREY_STONE, PAL_DARK_DOOR)
	_ubox(17.0, 51.0, -0.06, 0.055, _g - 1.3, _g + 3.6, PAL_BROWN_RENDER.lightened(0.2))
	kit_face(0.055)
	kit_window_grid(18.0, 50.0, 15, [_g + 1.4], 0.85, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.48)
	kit_face(0.0)
	for h: float in [4.58, 7.79]:
		kit_ledge(0.25, length - 0.3, _g + h, 0.14, PAL_PALE_CONCRETE, 0.12)
	length = kit_front(PWS_WEST_SOUTH, Vector2(1678.0, -1402.1))
	kit_window_grid(7.0, length - 4.1, 19, upper, 1.12, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.54)
	kit_window_grid(13.4, length - 4.1, 15, [_g + 1.4], 0.9, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.48)
	kit_window_grid(4.7, 6.6, 1, [_g + 1.4, _g + 4.8, _g + 8.0],
			1.12, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.51)
	kit_door(9.9, _g - 0.2, 2.9, 2.7, PAL_GREY_STONE, PAL_GLASS_STEEL)
	for h: float in [4.58, 7.79]:
		kit_ledge(6.8, length - 0.3, _g + h, 0.14, PAL_PALE_CONCRETE, 0.12)
	length = kit_front(annex[2], annex[1])
	kit_window_grid(2.2, length - 1.1, 4, [_g + 7.3], 1.1, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.44)
	kit_door(length * 0.54, _g - 0.3, 2.5, 1.25, PAL_GREY_STONE, PAL_DARK_DOOR)
	kit_front(Vector2(1656.4, -1472.6), Vector2(1640.8, -1472.9))
	kit_door(5.25, _g - 0.48, 7.75, 3.25, PAL_GREY_STONE, PAL_DARK_STEEL)


## Glaze the recessed public foyer and give the secondary doors on the cream wall a smaller hood.
func _powszechny_foyer() -> void:
	_ubox(PWS_FOYER.x, PWS_FOYER.y, PWS_RECESS - 0.05, 0.95, _g - 1.4, _g + 0.12,
			PAL_GREY_GRANITE, M_STONE, PAL_PALE_CONCRETE)
	kit_face(PWS_RECESS)
	var screen_start := PWS_FOYER.x + 0.35
	var screen_end := PWS_FOYER.y - 0.35
	kit_window_grid(screen_start, screen_end, 13, [_g + 3.35], 5.05, Win.PLAIN,
			PAL_ALUMINIUM, PAL_GLASS_NAVY, 0.89)
	for u: float in _spread(screen_start, screen_end, 13):
		if u >= 33.0 and u <= 47.0:
			kit_door(u, _g + 0.12, 2.68, 0.78, PAL_DARK_STEEL, PAL_GLASS_STEEL)
		else:
			kit_window(u, _g + 0.28, 2.52, Win.PLAIN, PAL_ALUMINIUM, PAL_GLASS_NAVY, 0.89)
	for h: float in [3.11, 4.32, 5.46, 6.6, 7.74, 8.55]:
		kit_ledge(PWS_FOYER.x, PWS_FOYER.y, _g + h, 0.085, PAL_DARK_STEEL.lightened(0.18), 0.145)
	kit_face(0.0)
	kit_door(9.5, _g - 0.2, 2.45, 1.03, PAL_DARK_STEEL, PAL_GLASS_STEEL)
	kit_window_grid(13.0, 25.9, 7, [_g + 1.15], 0.9, Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.49)
	for u: float in [4.45, 9.0, 13.5, 18.0, 22.5]:
		_wall(_w(u, 0.04), _w(u + 0.065, 0.04), _g + 3.2, _g + 9.04, _b, PAL_SANDSTONE.lightened(0.16))
	kit_window_grid(54.5, 61.0, 3, [_g + 1.4, _g + 4.8, _g + 8.0], 1.08,
			Win.PLAIN, PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.52)
	kit_ledge(5.0, 12.9, _g + 2.88, 0.3, PAL_DARK_STEEL, 1.45)


## Put pale mesh letters on the street's dark fascia, using the same font as other site signs.
func _powszechny_sign() -> void:
	_ubox(4.2, 53.2, -0.16, 0.22, _g + 9.04, _g + 11.27, PAL_DARK_STEEL)
	var word := "TEATR POWSZECHNY"
	var pixel_width := 0.41
	var pixel_height := 0.24
	var start := 28.7 - PixelFont.width(word) * pixel_width * 0.5
	PixelFont.each_pixel(word, 0, func(x: int, row: int) -> void:
		var u := start + x * pixel_width
		var y := _g + 11.02 - (row - PixelFont.BODY) * pixel_height
		_wall(_w(u, 0.26), _w(u + pixel_width, 0.26), y - pixel_height, y, _b, PAL_WHITE_STONE))


## Finish the four inward-facing walls of the light court down to its paved floor.
func _powszechny_court(court: PackedVector2Array) -> void:
	_prism(court, _g - 1.6, _g - 0.4, PAL_GREY_STONE, PAL_GREY_GRANITE, M_STONE, M_STONE)
	for i in court.size():
		var length := kit_front(court[i], court[(i + 1) % court.size()])
		var sills := [_g + 1.2, _g + 4.8, _g + 8.0]
		if i == 3:
			sills = [_g + 1.2, _g + 4.0]
			kit_window_grid(0.65, length - 0.65, 10, [_g + 6.3], 2.4, Win.PLAIN,
					PAL_ALUMINIUM, PAL_GLASS_NAVY, 0.94)
		kit_window_grid(0.8, length - 0.8, roundi(length / 1.92), sills, 1.05, Win.PLAIN,
				PAL_PALE_CONCRETE, PAL_GLASS_DARK, 0.5)
		kit_ledge(0.16, length - 0.16, _g + PWS_OFFICE_TOP - 0.13, 0.24, PAL_PALE_CONCRETE, 0.12)
		_wall(_w(0.0, 0.0), _w(length, 0.0), _g - 1.8, _g + PWS_OFFICE_TOP, _b, PAL_WHITE_STONE)


## Keep the roof open where the court cuts it and lift the auditorium, foyer and north annex.
func _powszechny_roofs(ring: PackedVector2Array, court: PackedVector2Array, annex: PackedVector2Array) -> void:
	var roof := _g + PWS_OFFICE_TOP
	_cap_holes(ring, [court], roof, PWS_ROOF)
	kit_ledge_ring(ring, roof - 0.13, 0.22, PAL_PALE_CONCRETE, 0.12)
	_prism(annex, roof - 0.22, _g + PWS_ANNEX_TOP, PAL_WHITE_STONE, PWS_ROOF, M_STONE, M_STONE)
	_ubox(4.5, 20.0, 10.5, 31.5, roof - 0.2, _g + 12.5, PAL_WHITE_STONE, M_STONE, PWS_ROOF.lightened(0.06))
	_ubox(6.3, 20.3, 34.5, 61.5, roof - 0.2, _g + 11.8, PAL_PALE_CONCRETE, M_STONE, PWS_ROOF)
	kit_ledge_ring(_urect(4.5, 20.0, 10.5, 31.5), _g + 12.37, 0.21, PAL_PALE_CONCRETE, 0.12)
	kit_ledge_ring(_urect(6.3, 20.3, 34.5, 61.5), _g + 11.68, 0.2, PAL_PALE_CONCRETE, 0.12)


## Raise the white fly tower over its lower stage block and give the blank head a shallow coping.
func _powszechny_tower() -> void:
	_ubox(20.1, 35.3, 23.8, 41.5, _g + PWS_OFFICE_TOP - 0.2, _g + PWS_STAGE_TOP,
			PAL_WHITE_STONE, M_STONE, PWS_ROOF)
	var tower := _urect(20.3, 35.0, 24.2, 34.4)
	_prism(tower, _g + PWS_STAGE_TOP - 0.18, _g + PWS_TOWER_TOP - 0.08,
			PAL_WHITE_STONE, PWS_ROOF, M_STONE, M_STONE)
	kit_ledge_ring(tower, _g + PWS_TOWER_TOP - 0.25, 0.25, PAL_PALE_CONCRETE, 0.18)
	for v: float in [26.1, 28.3, 31.9]:
		_ubox(20.23, 20.35, v, v + 0.16, _g + PWS_STAGE_TOP, _g + PWS_TOWER_TOP - 0.31, PAL_PALE_CONCRETE)


## Group the larger vents and duct runs by roof so each machine sits on the roof it serves.
func _powszechny_plant() -> void:
	var roof := _g + PWS_OFFICE_TOP
	var duct := PAL_ALUMINIUM.darkened(0.12)
	var housing := PAL_PALE_CONCRETE.darkened(0.09)
	# Twin housings behind the auditorium and the three feeds running towards the tower.
	_ubox(4.7, 19.2, 31.9, 33.7, roof, roof + 1.75, housing, M_STONE, duct)
	_ubox(4.7, 15.6, 34.0, 35.1, roof, roof + 1.52, duct)
	for u: float in [22.3, 29.1, 36.4]:
		_ubox(u, u + 1.45, 14.5, 22.0, roof, roof + 0.86, duct)
		_ubox(u - 0.2, u + 1.65, 13.6, 16.9, roof, roof + 1.53, housing)
	_ubox(22.3, 37.85, 22.0, 23.5, roof, roof + 1.04, duct)
	_ubox(24.5, 34.1, 23.35, 24.38, roof, roof + 1.18, duct)
	# The return duct follows the east and south roof edges around the open court.
	_ubox(37.1, 38.35, 49.4, 68.8, roof, roof + 0.92, duct)
	_ubox(12.1, 38.1, 67.65, 69.15, roof, roof + 1.16, duct)
	_ubox(11.25, 12.6, 64.2, 69.0, roof, roof + 0.82, duct)
	_ubox(23.4, 24.8, 64.0, 68.4, roof, roof + 0.77, housing)
	for v: float in [11.3, 29.6, 38.7, 46.2, 55.4, 61.0]:
		_ubox(39.0, 40.3, v, v + 1.3, roof, roof + 0.58, housing)
	# Local exhausts above the north annex, stage roof and west foyer.
	_ubox(26.8, 34.6, 6.2, 7.5, _g + PWS_ANNEX_TOP, _g + PWS_ANNEX_TOP + 0.52, duct)
	_ubox(33.8, 35.4, 3.7, 7.3, _g + PWS_ANNEX_TOP, _g + PWS_ANNEX_TOP + 0.83, housing)
	for u: float in [22.8, 27.1, 32.4]:
		_ubox(u, u + 1.0, 36.5, 37.8, _g + PWS_STAGE_TOP, _g + PWS_STAGE_TOP + 0.7, housing)
	_ubox(25.2, 34.84, 34.25, 35.35, _g + PWS_STAGE_TOP, _g + PWS_STAGE_TOP + 1.78, duct)
	for at: Vector2 in [Vector2(11.0, 44.0), Vector2(15.5, 50.1), Vector2(10.5, 57.3)]:
		_lbox(at.x, at.y, 0.45, 0.56, _g + 11.8, _g + 12.22, PAL_ROOF_PALE)
	_ubox(16.8, 19.3, 55.6, 56.5, _g + 11.8, _g + 12.36, duct)
	_ubox(18.4, 19.3, 56.4, 60.0, _g + 11.8, _g + 12.43, duct)
	_ubox(27.8, 30.2, 25.4, 31.2, _g + PWS_TOWER_TOP - 0.08, _g + PWS_TOWER_TOP + 0.73, housing)


# --- Centrum Praha (docs/landmarks/specs/centrum_praha.md) --------------------------------------

## Sandstone tones, piers, zinc mansard, glazing and roof membrane measured from refs/centrum_praha/.
const CP_NAME := "Centrum Praha"
const CP_STONE := Color("#d4c8b0")       # main pale sandstone
const CP_STONE_HI := Color("#d9ceb7")    # lighter sandstone fins and relief plaques
const CP_SHADOW := Color("#bfb39c")      # recessed sandstone shadow panels and carved features
const CP_PIER := Color("#6d6a66")        # dark grey ground-floor stone piers
const CP_SHOP_BACK := Color("#3a4246")   # recessed dark backing behind ground-floor glazing
const CP_SHOP_GLASS := Color("#5d6f74")  # ground-floor shopfront glass (M_PAVILION at night)
const CP_GLASS := Color("#4a5a63")       # upper window storey and mansard glazing
const CP_ZINC := Color("#6e7378")        # sloped grey zinc mansard and ridge cap
const CP_ROOF := Color("#5f6266")        # flat dark roof membrane inside the mansard
const CP_H_GROUND := 4.5
const CP_H_FRIEZE := 6.0
const CP_H_FRAMES := 12.0
const CP_H_WINDOWS := 14.8
const CP_H_TOP := 17.5
const CP_BAY := 6.5


## Finds Centrum Praha's OSM outline by name and registers a 0.5 m outward zone so the map's plain
## prism is replaced by the detailed sandstone block.
func _find_centrum_praha() -> void:
	var raw := _landmark(CP_NAME)
	if raw.size() < 3:
		push_error("centrum_praha: landmark outline '%s' is missing from centrum.json" % CP_NAME)
		return
	var zone := _largest(Geometry2D.offset_polygon(raw, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = raw
	_add_site("centrum_praha", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "centrum_praha":
		sites[-1]["raw"] = raw


## Starts a kit_front along edge a->b oriented so _b matches the outward normal `out`.
func _cp_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Builds Centrum Praha: glazed ground floor between dark stone piers, carved-faces sandstone
## frieze, deep two-storey stone frames over vertical fin panels, recessed square-window storey,
## cornice ring, sloped zinc mansard with tilted pale-framed windows, flat roof and collision.
func _build_centrum_praha(site: Dictionary) -> void:
	var raw: PackedVector2Array = site.get("raw", PackedVector2Array())
	if raw.size() < 3:
		return
	var ring := _simplify(raw, 0.5)
	if ring.size() < 3:
		ring = raw
	var g := _ground_under(raw)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# Stacked body tiers: dark ground backing, frieze backing, recessed sandstone shadow panel,
	# and upper window storey wall. No vertical overlap so no wall planes z-fight.
	_prism(ring, g - 0.5, g + CP_H_GROUND, CP_SHOP_BACK, none, M_STONE)
	_prism(ring, g + CP_H_GROUND, g + CP_H_FRIEZE, CP_SHADOW, none, M_STONE)
	_prism(ring, g + CP_H_FRIEZE, g + CP_H_FRAMES, CP_SHADOW.darkened(0.12), none, M_STONE)
	_prism(ring, g + CP_H_FRAMES, g + CP_H_WINDOWS, CP_STONE, none, M_STONE)
	# Continuous sandstone frieze band wrapping all four corners cleanly (slightly darker recessed
	# ground so the carved lighter-stone portrait plaques read crisply from the isometric camera).
	kit_ledge_ring(ring, g + CP_H_GROUND, CP_H_FRIEZE - CP_H_GROUND, CP_SHADOW, 0.14)
	# Corner piers aligned to the block's primary edges so ground and upper frames turn cleanly.
	_cp_corners(ring, g)
	# Per-face facade dressing: shop bays, carved face reliefs, deep bay frames, fins, and windows.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		if a.distance_to(b) >= 4.0:
			_cp_dress_face(a, b, out, g)
	# Main stone cornice right under the zinc mansard (top flush at g + 14.8 m).
	kit_cornice_ring(ring, g + CP_H_WINDOWS - 0.30, CP_STONE, 0.30, 0.36)
	# Sloped grey zinc mansard leaning 1.2 m inward with tilted windows, plus flat roof & plant.
	var top_ring := _inset_ring(ring, 1.2)
	_cp_mansard(ring, top_ring, g)
	_cp_roof(ring, top_ring, g)
	_collide(raw)
	_mode = M_STONE


## Places ground-floor dark piers and upper sandstone corner piers aligned to `ring`'s first edge.
func _cp_corners(ring: PackedVector2Array, g: float) -> void:
	var ua := (ring[1] - ring[0]).normalized()
	var vb := Vector2(-ua.y, ua.x)
	var r := 0.52
	for p in ring:
		var sq := PackedVector2Array([
			p - ua * r - vb * r,
			p + ua * r - vb * r,
			p + ua * r + vb * r,
			p - ua * r + vb * r,
		])
		_prism(sq, g - 0.5, g + CP_H_GROUND - 0.03, CP_PIER, CP_PIER.darkened(0.08), M_STONE, M_STONE)
		_prism(sq, g + CP_H_FRIEZE + 0.03, g + CP_H_WINDOWS - 0.32, CP_STONE, CP_STONE.darkened(0.06), M_STONE, M_STONE)


## Dresses one straight face of Centrum Praha with ground shopfronts, carved portrait reliefs in
## the frieze, deep two-storey sandstone frames with vertical fins, and the square-window storey.
func _cp_dress_face(a: Vector2, b: Vector2, out: Vector2, g: float) -> void:
	var w := _cp_front_edge(a, b, out)
	var margin := 0.65
	var usable := w - 2.0 * margin
	if usable < 3.0:
		return
	var bays := maxi(1, roundi(usable / CP_BAY))
	var step := usable / float(bays)
	var keep := _mode
	# Horizontal frame sill (6.0 m) and mid beam (11.75 m) spanning between corner piers.
	kit_ledge(margin - 0.08, w - margin + 0.08, g + CP_H_FRIEZE + 0.04, 0.34, CP_STONE, 0.36)
	kit_ledge(margin - 0.08, w - margin + 0.08, g + CP_H_FRAMES - 0.25, 0.36, CP_STONE, 0.36)
	# Intermediate bay piers: dark ground piers, deep framed pilasters, and upper window piers.
	for k in range(1, bays):
		var pu := margin + float(k) * step
		_kbox(pu - 0.45, pu + 0.45, -0.04, 0.26, g - 0.5, g + CP_H_GROUND - 0.03, CP_PIER)
		kit_pilaster(pu, g + CP_H_FRIEZE + 0.40, g + CP_H_FRAMES - 0.28, CP_STONE, 0.70, 0.40)
		_kbox(pu - 0.35, pu + 0.35, -0.04, 0.40, g + CP_H_FRAMES + 0.14, g + CP_H_WINDOWS - 0.34, CP_STONE)
	# Per-bay openings, carved face relief, recessed sandstone fins, and paired square windows.
	var shop_hw := clampf((step - 1.15) * 0.5, 1.2, 2.7)
	var bay_clear := step - 0.85
	var win_hw := clampf((bay_clear - 0.65) * 0.25, 0.55, 1.15)
	for k in bays:
		var u0 := margin + float(k) * step
		var u1 := u0 + step
		var bc := (u0 + u1) * 0.5
		# Ground floor: glazed shopfront via kit_shop_bay + M_PAVILION night-glowing glass pane.
		kit_shop_bay(bc, g, g + CP_H_GROUND - 0.35, shop_hw, CP_PIER.lightened(0.08), CP_SHOP_GLASS)
		_mode = M_PAVILION
		_wall(_w(bc - shop_hw + 0.05, 0.08), _w(bc + shop_hw - 0.05, 0.08), g + 0.05, g + CP_H_GROUND - 0.38, _b, CP_SHOP_GLASS)
		_mode = M_STONE
		# Sculpted frieze: one carved portrait relief plaque per bay.
		_cp_relief(bc, g + CP_H_GROUND, 0.14)
		# Framed storeys (6.38-11.72 m): central projecting rib + vertical sandstone fin strips.
		var fin_y0 := g + CP_H_FRIEZE + 0.40
		var fin_y1 := g + CP_H_FRAMES - 0.28
		_kbox(bc - 0.18, bc + 0.18, -0.02, 0.24, fin_y0, fin_y1, CP_STONE_HI)
		var inner_lo := u0 + 0.48
		var inner_hi := u1 - 0.48
		var half_w := (bc - 0.24) - inner_lo
		if half_w > 0.7:
			for side_start: float in [inner_lo, bc + 0.24]:
				for s in 3:
					var fu := side_start + half_w * (float(s) + 0.5) / 3.0
					_wall(_w(fu - 0.12, 0.06), _w(fu + 0.12, 0.06), fin_y0 + 0.04, fin_y1 - 0.04, _b, CP_STONE_HI)
		# Window storey (12.12-14.48 m): two square windows per bay in thin stone surrounds.
		kit_window_grid(u0 + 0.45, u1 - 0.45, 2, [g + CP_H_FRAMES + 0.28], 1.85, Win.PLAIN, CP_STONE, CP_GLASS, win_hw)
		_wall(_w(bc - 0.10, 0.08), _w(bc + 0.10, 0.08), g + CP_H_FRAMES + 0.20, g + CP_H_WINDOWS - 0.42, _b, CP_STONE)
	_mode = keep


## Places one carved Praga portrait relief in the frieze at `u`: a bold sandstone portrait plaque
## standing proud of the frieze band, with a projecting 3D nose ridge and high-contrast shaded eye
## sockets and mouth relief sized to read clearly from the isometric camera.
func _cp_relief(u: float, frieze_y0: float, face_v: float) -> void:
	var cy := frieze_y0 + 0.75
	_kbox(u - 0.80, u + 0.80, face_v - 0.02, face_v + 0.16, cy - 0.56, cy + 0.56, CP_STONE_HI)
	var v_plaque := face_v + 0.16
	# Projecting nose ridge box in shaded sandstone.
	_kbox(u - 0.10, u + 0.10, v_plaque - 0.02, v_plaque + 0.10, cy - 0.16, cy + 0.18, CP_SHADOW.darkened(0.08))
	# Two recessed-tone eye sockets and a mouth shadow bar standing 3 cm proud of the plaque.
	var eye_col := CP_SHADOW.darkened(0.28)
	var v_feat := v_plaque + 0.03
	for s: float in [-1.0, 1.0]:
		_wall(_w(u + s * 0.28 - 0.12, v_feat), _w(u + s * 0.28 + 0.12, v_feat), cy + 0.14, cy + 0.30, _b, eye_col)
	_wall(_w(u - 0.20, v_feat), _w(u + 0.20, v_feat), cy - 0.36, cy - 0.24, _b, eye_col)


## Builds the sloped grey zinc mansard from g + 14.8 m to g + 17.5 m (leaning 1.2 m in) and sets
## two large tilted pale-framed windows per bay parallel to each sloped face.
func _cp_mansard(ring: PackedVector2Array, top_ring: PackedVector2Array, g: float) -> void:
	var y0 := g + CP_H_WINDOWS
	var y1 := g + CP_H_TOP
	_mode = M_STONE
	_slope(ring, ring, y0, top_ring, y1, CP_ZINC)
	var n := ring.size()
	for i in n:
		var j := (i + 1) % n
		var a0 := ring[i]
		var b0 := ring[j]
		var a1 := top_ring[i]
		var b1 := top_ring[j]
		var ln := a0.distance_to(b0)
		if ln < 4.0:
			continue
		var p0 := Vector3(a0.x, y0, a0.y)
		var p1 := Vector3(b0.x, y0, b0.y)
		var p3 := Vector3(a1.x, y1, a1.y)
		var out := _out(ring, a0, b0)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		if Vector2(nrm.x, nrm.z).dot(out) < 0.0:
			nrm = -nrm
		var margin := 0.85
		var usable := ln - 2.0 * margin
		var bays := maxi(1, roundi(usable / CP_BAY))
		var step := usable / float(bays)
		var win_w := minf(step * 0.38, 2.35)
		for k in bays:
			var bay_lo := margin + float(k) * step
			for w_idx in 2:
				var cu := bay_lo + step * (0.27 if w_idx == 0 else 0.73)
				var t0 := clampf((cu - win_w * 0.5) / ln, 0.03, 0.97)
				var t1 := clampf((cu + win_w * 0.5) / ln, 0.03, 0.97)
				# Pale stone frame quad (5 cm proud) and tilted dark glass pane (10 cm proud).
				_cp_slope_quad(a0, b0, a1, b1, y0, y1, t0, t1, 0.08, 0.92, nrm, 0.05, CP_STONE_HI)
				var inset_t := 0.16 / ln
				_cp_slope_quad(a0, b0, a1, b1, y0, y1, t0 + inset_t, t1 - inset_t, 0.16, 0.84, nrm, 0.10, CP_GLASS)


## Emits one quad on the sloped mansard face parameterized by horizontal t0..t1 and slope s0..s1.
func _cp_slope_quad(a0: Vector2, b0: Vector2, a1: Vector2, b1: Vector2, y0: float, y1: float,
		t0: float, t1: float, s0: float, s1: float, nrm: Vector3, proud: float, col: Color) -> void:
	var pt := func(t: float, s: float) -> Vector3:
		var bot := a0.lerp(b0, t)
		var top := a1.lerp(b1, t)
		var p2 := bot.lerp(top, s)
		return Vector3(p2.x, lerpf(y0, y1, s), p2.y) + nrm * proud
	_quad(pt.call(t0, s0), pt.call(t1, s0), pt.call(t1, s1), pt.call(t0, s1), nrm, col)


## Builds Centrum Praha's flat dark membrane roof at 17.5 m, a 0.5 m zinc ridge cap closing cleanly
## on both faces, and two low 2 x 4 m rooftop plant boxes.
func _cp_roof(ring: PackedVector2Array, top_ring: PackedVector2Array, g: float) -> void:
	var roof_y := g + CP_H_TOP
	_mode = M_STONE
	_cap(top_ring, roof_y, CP_ROOF)
	# 0.5 m zinc ridge cap round the mansard crest, with inner faces closed down to the membrane.
	kit_ledge_ring(top_ring, roof_y, 0.5, CP_ZINC.lightened(0.06), 0.12)
	for i in top_ring.size():
		var a := top_ring[i]
		var b := top_ring[(i + 1) % top_ring.size()]
		_wall(b, a, roof_y, roof_y + 0.5, -_out(top_ring, a, b), CP_ZINC.darkened(0.1))
	# Two low 2 x 4 m rooftop plant boxes aligned to the block's main axes.
	_o = _centre(top_ring)
	_a = (ring[1] - ring[0]).normalized()
	_b = Vector2(-_a.y, _a.x)
	_lbox(-7.5, -4.0, 2.0, 1.0, roof_y, roof_y + 1.25, CP_ZINC.lightened(0.12), M_STONE, CP_ROOF.lightened(0.08))
	_lbox(6.5, 5.5, 2.0, 1.0, roof_y, roof_y + 1.15, CP_ZINC.lightened(0.12), M_STONE, CP_ROOF.lightened(0.08))


# --- Pasaż Handlowy Targowa 33A (docs/landmarks/specs/targowa33a.md) ----------------------------

## Point well inside the 7.6 m trade podium and colours from refs/targowa33a/ and the spec.
const TG_NAME := "Pasaż Handlowy \"Targowa 33A\""
const TG_PODIUM_AT := Vector2(1090.0, -1780.0)
const TG_PODIUM_H := 7.6
const TG_BLOCK_H := 24.1
const TG_RENDER := Color("#d9d4c8")       # pale render walls
const TG_PLINTH := Color("#4b4d50")       # dark grey plinth
const TG_FRAME := Color("#3e4246")        # dark shopfront frames
const TG_SIGN_BAND := Color("#ecebe6")    # white sign band fascia
const TG_ROOF := Color("#8a8c8e")         # flat grey roof membrane
const TG_PARAPET := Color("#b9b8b3")      # light grey parapet & coping
const TG_SHOP_GLASS := Color("#50636b")   # ground-floor shop glass (M_PAVILION at night)
const TG_UPPER_GLASS := Color("#4a5a63")  # upper ribbon windows
const TG_SKY_GLASS := Color("#6f8590")    # skylight strip glazing
const TG_VENT := Color("#a8aaac")         # rooftop vent boxes
const TG_H_PLINTH := 0.4
const TG_H_GROUND := 3.6
const TG_H_ROOF := 7.0
const TG_H_TOP := 7.6
## Generic Polish shop words already present in neon_signs.gd (no real brands).
const TG_WORDS := ["APTEKA", "KEBAB 24H", "KANTOR", "PIEKARNIA", "KWIATY", "SPOŻYWCZAK", "PIZZA", "BAR"]
const TG_WORD_COLS := [Color("#2fd168"), Color("#ff6a2a"), Color("#ffb81f"), Color("#ffd27a"),
		Color("#ff527a"), Color("#3fb4ff"), Color("#ff4a3a"), Color("#ff8a2b")]


## Finds Targowa 33A's 7.6 m commercial podium building (cross-checked with the landmark outline)
## and every 24.1 m residential block that stands on or overlaps its 0.5 m zone, passing those
## blocks as `keep` so the flats stay drawn while the podium is rebuilt inside the block.
func _find_targowa33a() -> void:
	var lm := _landmark(TG_NAME)
	var podium := PackedVector2Array()
	for bld: Dictionary in data.get("buildings", []):
		if absf(float(bld["h"]) - TG_PODIUM_H) > 0.3:
			continue
		var q := _pts(bld["p"])
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(TG_PODIUM_AT, q):
			podium = q
			break
	if podium.size() < 3 and lm.size() >= 3:
		podium = lm
	if podium.size() < 3:
		push_error("targowa33a: 7.6 m trade podium outline holding %s (and landmark '%s') is missing from centrum.json" % [TG_PODIUM_AT, TG_NAME])
		return
	if lm.size() >= 3 and _centre(podium).distance_to(_centre(lm)) > 5.0:
		push_error("targowa33a: 7.6 m building centre %s disagrees with landmark '%s' centre %s" % [_centre(podium), TG_NAME, _centre(lm)])
	var zone := _largest(Geometry2D.offset_polygon(podium, 0.5, Geometry2D.JOIN_MITER))
	if zone.size() < 3:
		zone = podium
	var zbox := _box_of([zone])
	var keep_blocks: Array[PackedVector2Array] = []
	for bld: Dictionary in data.get("buildings", []):
		if absf(float(bld["h"]) - TG_BLOCK_H) > 0.3:
			continue
		var q := _pts(bld["p"])
		if q.size() < 3 or not zbox.intersects(_box_of([q])):
			continue
		if not Geometry2D.intersect_polygons(zone, q).is_empty():
			keep_blocks.append(q)
	_add_site("targowa33a", [zone], keep_blocks)
	if not sites.is_empty() and sites[-1]["key"] == "targowa33a":
		sites[-1]["podium"] = podium
		sites[-1]["keep_blocks"] = keep_blocks


## Starts a kit_front along edge a->b oriented so _b matches the outward normal `out`.
func _tg_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


## Merges consecutive collinear edges of `poly` (within ~3 deg) without moving any real sawtooth
## corner, so long straight arms get clean continuous bay spacing.
func _tg_merge_collinear(poly: PackedVector2Array) -> PackedVector2Array:
	var cur := poly
	var changed := true
	while changed and cur.size() > 3:
		changed = false
		var next := PackedVector2Array()
		var n := cur.size()
		for i in n:
			var prev := cur[(i + n - 1) % n]
			var p := cur[i]
			var nxt := cur[(i + 1) % n]
			var d0 := p - prev
			var d1 := nxt - p
			if d0.length() < 0.05 or d1.length() < 0.05:
				changed = true
				continue
			if d0.normalized().dot(d1.normalized()) > 0.9985:
				changed = true
				continue
			next.append(p)
		cur = next
	return cur if cur.size() >= 3 else poly


## Clips `podium` against every kept 24.1 m residential block so nothing is built inside them.
func _tg_clip_blocks(podium: PackedVector2Array, keep_blocks: Array) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = [podium]
	for kb: PackedVector2Array in keep_blocks:
		var next: Array[PackedVector2Array] = []
		for p in parts:
			for q: PackedVector2Array in Geometry2D.clip_polygons(p, kb):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and absf(_area(q)) > 2.0:
					next.append(q)
		parts = next
	return parts


## Returns true if edge a->b (with outward normal `out`) abuts or faces straight into a kept block.
func _tg_touches_keep(a: Vector2, b: Vector2, out: Vector2, keep_blocks: Array) -> bool:
	var mid := (a + b) * 0.5
	var probe := mid + out * 0.45
	for kb: PackedVector2Array in keep_blocks:
		if Geometry2D.is_point_in_polygon(probe, kb) or _dist_to_ring(mid, kb) < 0.35:
			return true
	return false


## Builds Pasaż Handlowy Targowa 33A: clipped two-storey podium body over dark plinth, exposed
## edges dressed with shop bays, glowing sign band with generic words, upper ribbon windows, inset
## roof parapet with coping, and the flat grey roof with two pitched skylight strips and vent boxes.
func _build_targowa33a(site: Dictionary) -> void:
	var podium: PackedVector2Array = site.get("podium", PackedVector2Array())
	if podium.size() < 3:
		return
	var keep_blocks: Array = site.get("keep_blocks", [])
	var clipped := _tg_clip_blocks(podium, keep_blocks)
	if clipped.is_empty():
		return
	var g := _ground_under(podium)
	_g = g
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	var roof_y := g + TG_H_ROOF
	var top_y := g + TG_H_TOP
	var word_idx := 0
	var inner_roofs: Array[PackedVector2Array] = []
	for raw_piece in clipped:
		var piece := _tg_merge_collinear(raw_piece)
		# Podium shell: dark plinth (0-0.4 m), pale render body (0.4-7.0 m), outer parapet (7.0-7.6 m).
		_prism(piece, g - 0.5, g + TG_H_PLINTH, TG_PLINTH, none, M_STONE)
		_prism(piece, g + TG_H_PLINTH, roof_y, TG_RENDER, none, M_STONE)
		_prism(piece, roof_y, top_y, TG_PARAPET, none, M_STONE)
		# Inset roof membrane (0.35 m inside outline so parapet never pokes into kept 24.1 m flats).
		var inners: Array[PackedVector2Array] = []
		for q: PackedVector2Array in Geometry2D.offset_polygon(piece, -0.35, Geometry2D.JOIN_MITER):
			if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q) and absf(_area(q)) > 2.0:
				inners.append(q)
				inner_roofs.append(q)
		if inners.is_empty():
			_cap(piece, roof_y, TG_ROOF)
		else:
			for iq in inners:
				_cap(iq, roof_y, TG_ROOF)
				for i in iq.size():
					var ia := iq[i]
					var ib := iq[(i + 1) % iq.size()]
					_wall(ib, ia, roof_y, top_y, -_out(iq, ia, ib), TG_PARAPET.darkened(0.08))
			_cap_holes(piece, inners, top_y, TG_PARAPET.lightened(0.05))
		# Dress every exposed edge longer than 3 m with shop bays, sign band, ribbon windows, coping.
		for i in piece.size():
			var a := piece[i]
			var b := piece[(i + 1) % piece.size()]
			var ln := a.distance_to(b)
			if ln <= 3.0:
				continue
			var out := _out(piece, a, b)
			if _tg_touches_keep(a, b, out, keep_blocks):
				continue
			word_idx = _tg_dress_edge(a, b, out, g, word_idx)
		_collide(raw_piece)
	# Rooftop skylights and vents clipped strictly inside the inner roof polygons.
	if not inner_roofs.is_empty():
		_tg_roof_features(inner_roofs, roof_y)
	_mode = M_STONE


## Dresses one exposed edge (> 3 m) of Targowa 33A with ground-floor shop bays, white sign band
## and generic glowing shop words, upper ribbon windows, and parapet coping trim.
func _tg_dress_edge(a: Vector2, b: Vector2, out: Vector2, g: float, word_idx: int) -> int:
	var w := _tg_front_edge(a, b, out)
	var m := 0.35
	var usable := w - 2.0 * m
	if usable < 2.2:
		return word_idx
	var keep := _mode
	# White sign band (3.0-3.6 m) and light grey parapet trim (7.42-7.62 m) via kit_ledge.
	kit_ledge(m * 0.5, w - m * 0.5, g + 3.0, 0.60, TG_SIGN_BAND, 0.12)
	kit_ledge(m * 0.5, w - m * 0.5, g + TG_H_TOP - 0.16, 0.18, TG_PARAPET.lightened(0.06), 0.08)
	# Ground-floor shop bays every 4-5 m with glowing M_PAVILION glass and periodic shop signs.
	var shops := maxi(1, roundi(usable / 4.5))
	var step := usable / float(shops)
	var shop_hw := clampf((step - 0.65) * 0.5, 0.85, 2.0)
	for k in shops:
		var cu := m + (float(k) + 0.5) * step
		kit_shop_bay(cu, g + TG_H_PLINTH, g + 2.80, shop_hw, TG_FRAME, TG_SHOP_GLASS)
		_mode = M_PAVILION
		_wall(_w(cu - shop_hw + 0.04, 0.08), _w(cu + shop_hw - 0.04, 0.08), g + TG_H_PLINTH + 0.04, g + 2.76, _b, TG_SHOP_GLASS)
		_mode = M_STONE
		if k % 2 == 0 and step >= 3.2:
			var word: String = TG_WORDS[word_idx % TG_WORDS.size()]
			var col: Color = TG_WORD_COLS[word_idx % TG_WORD_COLS.size()]
			var sw := minf(step * 0.72, 3.0)
			# Coloured daytime fascia nameplate on the white sign band behind the night-lit neon word.
			_mode = M_STONE
			_wall(_w(cu - sw * 0.5, 0.15), _w(cu + sw * 0.5, 0.15), g + 3.09, g + 3.51, _b, col.darkened(0.28))
			_usign(word, cu, 0.19, g + 3.08, _b, sw, 0.46, col)
			word_idx += 1
	# Upper floor (3.6-7.0 m): continuous sill ledge and ribbon windows via kit_window_grid.
	kit_ledge(m, w - m, g + 4.48, 0.14, TG_PARAPET, 0.08)
	var upper_n := maxi(1, roundi(usable / 3.2))
	var upper_step := usable / float(upper_n)
	var win_hw := clampf((upper_step - 0.42) * 0.5, 0.65, 1.35)
	kit_window_grid(m, w - m, upper_n, [g + 4.65], 1.55, Win.PLAIN, TG_PARAPET, TG_UPPER_GLASS, win_hw)
	_mode = keep
	return word_idx


## Returns true if all corners and the centre of `poly` lie inside one of `roof_polys`.
func _tg_inside_roof(poly: PackedVector2Array, roof_polys: Array[PackedVector2Array]) -> bool:
	var c := _centre(poly)
	for rp in roof_polys:
		if not Geometry2D.is_point_in_polygon(c, rp):
			continue
		var ok := true
		for p in poly:
			if not Geometry2D.is_point_in_polygon(p, rp):
				ok = false
				break
		if ok:
			return true
	return false


## Populates Targowa 33A's flat grey roof (7.0 m) with two bold pitched skylight strips along its
## two longest arms, three pale-walled square rooftop shafts, and eight low vent boxes (matching
## the 3D Tiles top view).
func _tg_roof_features(roof_polys: Array[PackedVector2Array], roof_y: float) -> void:
	# Align local frame to the podium's NE (u) and SE (v) building axes.
	_o = Vector2(1089.3, -1778.8)
	_a = Vector2(0.6632, -0.7485).normalized()
	_b = Vector2(-_a.y, _a.x)
	_mode = M_STONE
	# Two bold glazed skylight strips (3.2 m wide) along the NW arm (along u) and SE arm (along v).
	_tg_skylight_strip(-17.0, 13.0, -20.0, true, 6, roof_polys, roof_y)
	_tg_skylight_strip(7.0, 33.0, -2.0, false, 5, roof_polys, roof_y)
	# Three pale-walled square stairwell/lightwell shafts visible between the skylights in 3D Tiles.
	var shafts := [[7.5, -10.5], [9.5, 5.5], [4.5, 19.0]]
	for sh: Array in shafts:
		var su := float(sh[0])
		var sv := float(sh[1])
		var outer := _rect(su, sv, 1.8, 1.8)
		if _tg_inside_roof(outer, roof_polys):
			_prism(outer, roof_y, roof_y + 1.25, TG_SIGN_BAND.darkened(0.08), TG_PARAPET.lightened(0.06), M_STONE, M_STONE)
			var cap_in := _rect(su, sv, 1.25, 1.25)
			_cap(cap_in, roof_y + 1.29, TG_FRAME)
	# Eight rooftop vent boxes (1.0 x 1.5 m, 0.8 m tall) in pale grey with darker tops for contrast.
	var vents := [
		[12.0, 26.0, 0.75, 0.55, 0.85],
		[12.0, -26.0, 0.75, 0.55, 0.85],
		[14.0, -14.0, 0.55, 0.75, 0.85],
		[-18.0, -26.0, 0.75, 0.55, 0.85],
		[-16.0, 26.0, 0.55, 0.75, 0.85],
		[-8.0, -28.0, 0.75, 0.55, 0.85],
		[11.0, 15.0, 0.55, 0.75, 0.85],
		[-11.0, 16.0, 0.75, 0.55, 0.85],
	]
	for v: Array in vents:
		var poly := _rect(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
		if _tg_inside_roof(poly, roof_polys):
			_prism(poly, roof_y, roof_y + float(v[4]), TG_PARAPET.lightened(0.08), TG_PLINTH.lightened(0.14), M_STONE, M_STONE)


## Builds one segmented pitched-glass skylight strip (3.2 m wide) on the podium roof, emitting only
## segments whose footprint lies completely inside `roof_polys`.
func _tg_skylight_strip(s0: float, s1: float, fixed: float, along_u: bool, segs: int,
		roof_polys: Array[PackedVector2Array], roof_y: float) -> void:
	var step := (s1 - s0) / float(segs)
	var hw := 1.6
	for k in segs:
		var mid := s0 + (float(k) + 0.5) * step
		var hl := step * 0.46
		var cu := mid if along_u else fixed
		var cv := fixed if along_u else mid
		var hu := hl if along_u else hw
		var hv := hw if along_u else hl
		var base := _rect(cu, cv, hu, hv)
		if not _tg_inside_roof(base, roof_polys):
			continue
		_prism(base, roof_y, roof_y + 0.35, TG_PARAPET.lightened(0.05), Color(0, 0, 0, 0), M_STONE)
		_pyramid(base, roof_y + 0.35, roof_y + 1.55, TG_SKY_GLASS)
