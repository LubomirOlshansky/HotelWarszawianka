extends "res://scripts/landmarks/wola.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the railway: Warszawa
## Centralna, Ochota, Powiśle, Stadion, Wschodnia, Śródmieście and the WKD stops. Moved as it was
## from the one big file. landmarks.gd is the class the game makes; every file of
## game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd, then the areas
## in the order of landmarks.gd's `extends` chain), so code here may use this file, common.gd and
## the facade kit, never another area: a helper two areas need goes to common.gd.
## Warszawa Centralna (spec docs/landmarks/specs/centralna.md, 2026-10-31): OpenStreetMap maps
## the station in 3D, and the model is built from those parts: the glass hall (71 x 51 m, its
## mapped storey under it drawn as the hall's own ground floor), the lower side wings with
## their roof boxes, the entrance vestibules, the 28 pillars (two rows, 10 m apart) and the
## roof in two mapped tiers: the shell zone over the pillars (140 x 57 m, 15 to 16.5 m) and
## the flat slab over it, overhanging both long sides to 140 x 86 m (16.5 to 18 m).
const CENTRALNA := Vector2(-1420.0, 572.5)
const CENTRALNA_TURN := -19.4
func _find_centralna() -> void:
	var a := Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	var b := Vector2(-a.y, a.x)
	var zone := PackedVector2Array()
	for q in [[-73.0, -45.5], [73.0, -45.5], [73.0, 46.5], [-73.0, 46.5]]:
		zone.append(CENTRALNA + a * float(q[0]) + b * float(q[1]))
	_add_site("centralna", [zone])
	if sites.is_empty() or sites[-1]["key"] != "centralna":
		return
	var site: Dictionary = sites[-1]
	var pillars: Array[Vector2] = []
	var hall: Array[PackedVector2Array] = []
	var wings: Array[Dictionary] = []
	var boxes: Array[Dictionary] = []
	var small: Array[PackedVector2Array] = []
	for bld in _parts_in(zone, func(b2: Dictionary) -> bool: return float(b2["h"]) > float(b2["mh"])):
		var q := _pts(bld["p"])
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		var lo := q[0]
		var hi := q[0]
		for v in q:
			lo = lo.min(v)
			hi = hi.max(v)
		var area := absf(_area(q))
		if absf(h - 15.0) < 0.5 and mh < 0.5 and (hi - lo).length() < 3.0:
			pillars.append(_centre(q))
		elif mh >= 14.9:
			site["slab" if mh >= 16.4 else "shells"] = q  # the roof's two tiers
		elif mh >= 11.0:
			boxes.append(bld)  # the boxes on the wings' roofs
		elif h >= 14.5 and area > 1000.0:
			hall.append(q)
		elif h >= 11.0 and area > 300.0:
			wings.append(bld)
		elif h <= 3.5 and area < 500.0:
			small.append(q)  # the vestibules (the 87-point storey under the hall is the hall's)
	# The vestibules and pillars that stand clear of the hall and the wings (the rest are inside).
	var vest: Array[PackedVector2Array] = []
	for q in small:
		if not _in_any(_centre(q), hall, wings):
			vest.append(q)
	var free: Array[Vector2] = []
	for p in pillars:
		if not _in_any(p, hall, wings):
			free.append(p)
	site["pillars"] = free
	site["hall"] = hall
	site["wings"] = wings
	site["boxes"] = boxes
	site["vest"] = vest


func _in_any(p: Vector2, hall: Array[PackedVector2Array], wings: Array[Dictionary]) -> bool:
	for q in hall:
		if Geometry2D.is_point_in_polygon(p, q):
			return true
	for w in wings:
		if Geometry2D.is_point_in_polygon(p, _pts(w["p"])):
			return true
	return false


# --- Warszawa Centralna -----------------------------------------------------------------------

## Colours (spec centralna.md section 5).
const CEN_GLASS := Color("#7f9fb2")     # the hall's curtain wall, lit cool white at night
const CEN_WING := Color("#8d9aa2")      # the wings' glass in a light concrete grid
const CEN_STONE := Color("#bcbaab")     # mapped: the wings and their roof boxes
const CEN_DECK := Color("#9c9a90")      # the wings' and boxes' roofs
const CEN_DOOR := Color("#3f4c55")      # the vestibules' dark glass
const CEN_FASCIA := Color("#e4e2dc")    # mapped white: the slab's edge and the shells' fascia
const CEN_ROOF := Color("#638898")      # mapped roof colour
const CEN_SOFFIT := Color("#9a968c")    # the shells' underside: the ceiling, lit at night
const CEN_PILLAR := Color("#bdb8ad")
## The shells' grid (local metres): the pillars stand on every other node along u (10 m apart
## from -65.4) on the rows v -20.5 and 21.2; the ends are the shell tier's mapped edges.
const CEN_SHELL_U0 := -65.4
const CEN_SHELL_V := [-28.0, -20.5, -13.55, -6.6, 0.35, 7.3, 14.25, 21.2, 28.9]
const CEN_SHELL_ENDS := Vector2(-68.5, 68.7)
const CEN_LOW := 12.0    # the underside at the pillar rows: the pillars' heads (photo 1)
const CEN_APEX := 14.2   # the arch's crown between the rows, over the hall
const CEN_EDGE := 16.0   # the underside at the slab's long edges: the wing tips, 2 m thick
const CEN_HIGH := 16.5   # the hall's glass goes up into the roof to here
const CEN_TOP := 18.0
const CEN_STEPS := 6     # profile pieces per half bay
const CEN_END := Color("#b9b7b0")  # the shells' end faces, grey under the white fascia

## The station hall's glass box under the flat overhanging slab, and under the slab the roof's
## shells: falling from the long edges to the pillar rows like wings and arching over the hall
## between them, the winged shape that shows at both ends. At night the hall glows cool white
## floor by floor, the shells' underside is lit, and lamps line the slab's edge.
func _build_centralna(site: Dictionary) -> void:
	_o = CENTRALNA
	_a = Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(0.0, 0.0, 70.0, 43.0))
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The glass hall, from the ground (the mapped storey under it is its ground floor) to the
	# slab: the shells meet its walls.
	for q: PackedVector2Array in site.get("hall", []):
		_prism(q, _ground_under(q) - 0.4, g + CEN_HIGH, CEN_GLASS, none, M_PAVILION + 0.5)
		_collide(q)
	# The lower wings either side, from the ground, and the boxes on their roofs.
	for w: Dictionary in site.get("wings", []):
		var q := _pts(w["p"])
		_prism(q, _ground_under(q) - 0.4, g + float(w["h"]), CEN_WING, CEN_DECK, M_SKIN + float(S_GRID) / 16.0, M_STONE)
		_collide(q)
	for bx: Dictionary in site.get("boxes", []):
		_prism(_pts(bx["p"]), g + float(bx["mh"]), g + float(bx["h"]), CEN_STONE, CEN_DECK, M_STONE, M_STONE)
	for q: PackedVector2Array in site.get("vest", []):
		_prism(q, _ground_under(q) - 0.4, g + 3.3, CEN_DOOR, CEN_DOOR.darkened(0.2), M_GLASS, M_STONE)
		_collide(q)
	# The pillars that stand clear of the hall and the wings (the ends), solid for the car too.
	for p: Vector2 in site.get("pillars", []):
		var l := _local(p)
		_lbox(l.x, l.y, 0.55, 0.55, g - 0.4, g + CEN_LOW + 0.3, CEN_PILLAR, M_STONE)
		_collide(_rect(l.x, l.y, 0.55, 0.55))
	# The slab: straight white edges down to the wing tips, the mapped roof colour on top in a
	# faint checker of panels over the shells' bays (every panel cut to the slab's outline; the
	# end ones reach past it).
	var slab: PackedVector2Array = site.get("slab", _rect(0.0, 0.0, 70.0, 43.0))
	_centralna_shells(g, slab)
	_prism(slab, g + CEN_EDGE, g + CEN_TOP, CEN_FASCIA, none, M_STONE)
	_mode = M_STONE
	var vb := [-44.0]
	vb.append_array(CEN_SHELL_V.slice(0, 9, 2))
	vb.append(45.0)
	for j in vb.size() - 1:
		for i in 14:
			var u0 := -80.0 if i == 0 else CEN_SHELL_U0 - 5.0 + i * 10.0
			var u1 := 80.0 if i == 13 else CEN_SHELL_U0 + 5.0 + i * 10.0
			var cell := PackedVector2Array([_w(u0, vb[j]), _w(u1, vb[j]), _w(u1, vb[j + 1]), _w(u0, vb[j + 1])])
			for piece in Geometry2D.intersect_polygons(cell, slab):
				if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
					_cap(piece, g + CEN_TOP, CEN_ROOF.darkened(0.03) if (i + j) % 2 == 1 else CEN_ROOF)
	# The dusk loop (2026-10-31): small warm-white lamps along the slab's edge, every ~5 m,
	# 0.6 m under its top, 0.08 m proud of it (0.8 m: smaller ones were under a pixel from
	# the driving camera).
	_mode = M_LAMP
	var lamp := Color(1.0, 0.93, 0.78)
	for k in slab.size():
		var ea := slab[k]
		var eb := slab[(k + 1) % slab.size()]
		var eo := _out(slab, ea, eb)
		var along := (eb - ea).normalized()
		var count := roundi(ea.distance_to(eb) / 5.0)
		for n in count:
			var t := (float(n) + 0.5) / float(count)
			var p := ea.lerp(eb, t) + eo * 0.08
			var y := g + CEN_TOP - 0.6
			var l := along * 0.4
			_quad(Vector3(p.x - l.x, y - 0.4, p.y - l.y), Vector3(p.x + l.x, y - 0.4, p.y + l.y),
					Vector3(p.x + l.x, y + 0.4, p.y + l.y), Vector3(p.x - l.x, y + 0.4, p.y - l.y),
					Vector3(eo.x, 0.0, eo.y), lamp)
	_mode = M_STONE


## The roof's underside (photo check on the Mac, 2026-11-01, refs/centralna 1-3): seen from
## either end the shells are the station's face, a wide winged shape under the straight top.
## Across the roof (v) the underside falls from the slab's long edges (CEN_EDGE) to the pillar
## rows (CEN_LOW), curving like a wing, and rises between the rows in a shallow arch over the
## hall (CEN_APEX); along u it runs straight to the slab's (bowed) ends, where a grey end face
## fills from the curve up to the fascia. Lit at night, like the ceiling it is.
func _centralna_shells(g: float, slab: PackedVector2Array) -> void:
	var lo_v := INF
	var hi_v := -INF
	for p in slab:
		var l := _local(p)
		lo_v = minf(lo_v, l.y)
		hi_v = maxf(hi_v, l.y)
	var row0: float = CEN_SHELL_V[1]
	var row1: float = CEN_SHELL_V[7]
	var mid := (row0 + row1) * 0.5
	# The profile (v, height over the ground), wing tip to wing tip, CEN_STEPS pieces a bay.
	var prof: Array[Vector2] = []
	for k in CEN_STEPS + 1:
		var t := float(k) / CEN_STEPS
		prof.append(Vector2(lerpf(lo_v, row0, t), CEN_LOW + (CEN_EDGE - CEN_LOW) * pow(1.0 - t, 0.8)))
	for k in range(1, 2 * CEN_STEPS + 1):
		var t := float(k) / (2 * CEN_STEPS)
		var v := lerpf(row0, row1, t)
		var x := (v - mid) / (row1 - mid)
		prof.append(Vector2(v, CEN_LOW + (CEN_APEX - CEN_LOW) * (1.0 - x * x)))
	for k in range(1, CEN_STEPS + 1):
		var t := float(k) / CEN_STEPS
		prof.append(Vector2(lerpf(row1, hi_v, t), CEN_LOW + (CEN_EDGE - CEN_LOW) * pow(t, 0.8)))
	# The tips sit a hair inside the slab's long edges, where the end lines still cross it.
	prof[0].x += 0.05
	prof[-1].x -= 0.05
	var ends: Array[Vector2] = []
	for q in prof:
		ends.append(_tier_ends(slab, q.x))
	_mode = M_LAMP
	for k in prof.size() - 1:
		var p0 := _w(ends[k].x, prof[k].x)
		var p1 := _w(ends[k].y, prof[k].x)
		var p2 := _w(ends[k + 1].y, prof[k + 1].x)
		var p3 := _w(ends[k + 1].x, prof[k + 1].x)
		var y0 := g + prof[k].y
		var y1 := g + prof[k + 1].y
		var a0 := Vector3(p0.x, y0, p0.y)
		var a1 := Vector3(p1.x, y0, p1.y)
		var a2 := Vector3(p2.x, y1, p2.y)
		var a3 := Vector3(p3.x, y1, p3.y)
		var n := (a1 - a0).cross(a3 - a0).normalized()
		if n.y > 0.0:
			n = -n
		_quad(a0, a1, a2, a3, n, CEN_SOFFIT)
	# The end faces: from the curve up to the fascia's foot, at both ends.
	_mode = M_STONE
	for side in 2:
		var out := -_a if side == 0 else _a
		for k in prof.size() - 1:
			var e0 := _w(ends[k][side], prof[k].x)
			var e1 := _w(ends[k + 1][side], prof[k + 1].x)
			var top := g + CEN_EDGE
			var b0 := Vector3(e0.x, g + prof[k].y, e0.y)
			var b1 := Vector3(e1.x, g + prof[k + 1].y, e1.y)
			# The ends bow out: each piece faces square to its own run, outwards.
			var run := Vector2(e1.x - e0.x, e1.y - e0.y)
			var face := Vector2(run.y, -run.x).normalized()
			if face.dot(out) < 0.0:
				face = -face
			var n := Vector3(face.x, 0.0, face.y)
			var none := Vector2(-1, -1)
			if prof[k].y > CEN_EDGE - 0.01:  # a wing tip: a triangle
				_tri(b0, b1, Vector3(e1.x, top, e1.y), n, CEN_END, none, none, none, -1.0)
			elif prof[k + 1].y > CEN_EDGE - 0.01:
				_tri(b0, b1, Vector3(e0.x, top, e0.y), n, CEN_END, none, none, none, -1.0)
			else:
				_quad(b0, b1, Vector3(e1.x, top, e1.y), Vector3(e0.x, top, e0.y), n, CEN_END)


## Where the line v (the shell tier's local plan) crosses the tier's outline: its west and
## east ends (CEN_SHELL_ENDS when the outline is missing or the line misses it).
func _tier_ends(tier: PackedVector2Array, v: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for k in tier.size():
		var a := _local(tier[k])
		var b := _local(tier[(k + 1) % tier.size()])
		if (a.y - v) * (b.y - v) > 0.0 or is_equal_approx(a.y, b.y):
			continue
		var u := lerpf(a.x, b.x, (v - a.y) / (b.y - a.y))
		lo = minf(lo, u)
		hi = maxf(hi, u)
	return Vector2(lo, hi) if hi > lo else CEN_SHELL_ENDS


# --- Warszawa Ochota (S1 of docs/design/railway.md, 2026-11-01) --------------------------------

## The cross-city line's station by Plac Zawiszy (Arseniusz Romanowicz and Piotr Szymaniak,
## 1962-63; on the monuments register). A square glazed ticket hall, 17.25 m a side, on a deck
## at street level that reaches out over the railway cutting, under a thin concrete hyperbolic
## paraboloid: two opposite corners rise to 8.34 m, the other two sit low on hinged supports, one
## high corner on a sliding bearing; the shell's underside is a black-and-white striped mosaic,
## and a mosaic band runs along the glass by the floor. Stairs fold down to the island platform;
## a small kiosk (once a newsagent's) by the entrance. The hall's walls are glass up to the
## shell (a hyperbolic paraboloid's edges are straight, so each wall is a trapezoid). Built from
## the OSM outline and published descriptions (no photo in the cloud): spec
## docs/landmarks/specs/ochota.md; the Mac photo check sets the stripes, the supports and the
## stairs.
const OCH_OSM := "Warszawa Ochota"
const OCH_HIGH := 10.6         # the shell's two high corners over the deck (they shoot up)
const OCH_SAG := 1.1           # the saddle's middle sags this far under the straight rulings' surface
const OCH_LOW := 3.0           # its two low corners
const OCH_OVER := 1.4          # the shell's overhang past the hall
const OCH_SHELL := 0.16        # the shell's edge thickness
const OCH_GRID := 14           # rulings each way (the stripes underneath)
const OCH_DECK := 1.1          # the deck slab's depth
const OCH_STREET := 15.0       # the deck reaches this far (u) past the hall's street side
const OCH_WHITE := Color("#e9e7e1")
const OCH_BLACK := Color("#2b2c2e")
const OCH_CONCRETE := Color("#b9b4aa")
const OCH_GLASS := Color("#6a7c86")
const OCH_FRAME := Color("#3a3f44")
const OCH_NEON := Color(0.2, 0.55, 1.0)

var _och_v := 1.0              # 1 or -1: which diagonal is high (the one whose far corner shows the stripes to the camera)


func _find_ochota() -> void:
	var q := _landmark(OCH_OSM)
	if q.size() < 3:
		return
	# The zone reaches over the stairs (along the tracks) and the deck to the street.
	var f := _och_frame(_simplify(q, 0.4))
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	var zone := PackedVector2Array([_w(-hu - 3.0, -hv - 14.0), _w(hu + OCH_STREET, -hv - 14.0),
			_w(hu + OCH_STREET, hv + 3.0), _w(-hu - 3.0, hv + 3.0)])
	_add_site("ochota", [zone])
	if not sites.is_empty() and sites[-1]["key"] == "ochota":
		sites[-1]["frame"] = f


## The hall's frame from its outline: [centre, u axis (across the tracks), v axis, half u,
## half v]. u runs along the outline's longest edge; +u is the side with the higher ground (the
## street the deck reaches; the cutting is on the other side).
func _och_frame(poly: PackedVector2Array) -> Array:
	var best := 0.0
	var a := Vector2.RIGHT
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() > best:
			best = e.length()
			a = e.normalized()
	var b := Vector2(-a.y, a.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		var l := Vector2(p.dot(a), p.dot(b))
		lo = Vector2(minf(lo.x, l.x), minf(lo.y, l.y))
		hi = Vector2(maxf(hi.x, l.x), maxf(hi.y, l.y))
	var c := a * (lo.x + hi.x) * 0.5 + b * (lo.y + hi.y) * 0.5
	var hu := (hi.x - lo.x) * 0.5
	if map.terrain_height(c.x - a.x * (hu + 25.0), c.y - a.y * (hu + 25.0)) > map.terrain_height(c.x + a.x * (hu + 25.0), c.y + a.y * (hu + 25.0)):
		a = -a
		b = -b
	return [c, a, b, hu, (hi.y - lo.y) * 0.5]


## The shell's height over the deck at local (u, v): a bilinear patch over the square of half
## size h, high at (-h, -h) and (h, h), low at the other two corners.
func _och_shell(u: float, v: float, h: float) -> float:
	var s := (u + h) / (2.0 * h)
	var t := (v * _och_v + h) / (2.0 * h)
	var diag := (1.0 - s) * (1.0 - t) + s * t
	var a := u / h
	var b := v / h
	return OCH_LOW + (OCH_HIGH - OCH_LOW) * diag - OCH_SAG * (1.0 - a * a) * (1.0 - b * b)


func _build_ochota(site: Dictionary) -> void:
	var f: Array = site["frame"]
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	# The deck's level: the street on both rims of the cutting (the highest ground across).
	var g := -INF
	var low := INF
	for k in range(-10, 11):
		var p := _w(k * 5.0, 0.0)
		g = maxf(g, map.terrain_height(p.x, p.y))
		low = minf(low, map.terrain_height(p.x, p.y))
	_g = g
	var none := Color(0, 0, 0, 0)
	var h := maxf(hu, hv) + OCH_OVER
	# The high diagonal: the one with the corner farthest from the game's camera, so the saddle
	# rises away from it and its whole striped top reads from the game's view.
	var far := INF
	_och_v = 1.0
	for c: Vector2 in [Vector2(-h, -h), Vector2(h, h), Vector2(-h, h), Vector2(h, -h)]:
		var d := (_w(c.x, c.y) - _o).dot(BEHIND_FACE)
		if d < far:
			far = d
			_och_v = 1.0 if c.x * c.y > 0.0 else -1.0
	# The deck: a slab from the street over the cutting, its edge beam, two piers in the cutting.
	_mode = M_STONE
	var deck := _rect((hu + OCH_STREET - h - 0.6) * 0.5, 0.0, (hu + OCH_STREET + h + 0.6) * 0.5, hv + 0.8)
	_prism(deck, g - OCH_DECK, g, OCH_CONCRETE.darkened(0.08), OCH_CONCRETE.lightened(0.05), M_STONE, M_STONE)
	_soffit(deck, g - OCH_DECK, OCH_CONCRETE.darkened(0.3))
	for pu in [-hu + 1.5, hu - 1.5]:
		_prism(_rect(pu, 0.0, 0.5, hv - 1.0), low - 1.0, g - OCH_DECK, OCH_CONCRETE.darkened(0.15), none, M_STONE)
	# The hall: glass walls up to the shell, a black-and-white mosaic band by the floor.
	var corners := [Vector2(-hu, -hv), Vector2(hu, -hv), Vector2(hu, hv), Vector2(-hu, hv)]
	var hall := PackedVector2Array()
	for c: Vector2 in corners:
		hall.append(_w(c.x, c.y))
	var keep := _mode
	_mode = M_PAVILION
	for i in 4:
		var c0: Vector2 = corners[i]
		var c1: Vector2 = corners[(i + 1) % 4]
		var a := hall[i]
		var b := hall[(i + 1) % 4]
		var o := _out(hall, a, b)
		var n := Vector3(o.x, 0.0, o.y)
		var t0 := g + _och_shell(c0.x, c0.y, h) - OCH_SHELL
		var t1 := g + _och_shell(c1.x, c1.y, h) - OCH_SHELL
		var y0 := g + 0.6
		var len := a.distance_to(b)
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, t1, b.y), Vector3(a.x, t0, a.y), n, OCH_GLASS,
				Vector2(0.0, 0.6), Vector2(len, 0.6), Vector2(len, t1 - g), Vector2(0.0, t0 - g), maxf(t0, t1) - g)
	_mode = M_STONE
	# Mullions every ~1.7 m, from the band to the shell.
	for i in 4:
		var c0: Vector2 = corners[i]
		var c1: Vector2 = corners[(i + 1) % 4]
		var a := hall[i]
		var b := hall[(i + 1) % 4]
		var o := _out(hall, a, b) * 0.06
		var n := maxi(1, roundi(a.distance_to(b) / 1.7))
		for k in range(0, n):
			var t := float(k) / n
			var cl: Vector2 = c0.lerp(c1, t)
			var p := a.lerp(b, t) + o
			var d := (b - a).normalized() * 0.06
			var top := g + _och_shell(cl.x, cl.y, h) - OCH_SHELL
			_quad(Vector3(p.x - d.x, g + 0.6, p.y - d.y), Vector3(p.x + d.x, g + 0.6, p.y + d.y),
					Vector3(p.x + d.x, top, p.y + d.y), Vector3(p.x - d.x, top, p.y - d.y), Vector3(o.x, 0.0, o.y).normalized(), OCH_FRAME)
		# The mosaic band: black and white tiles 0.6 m wide.
		var m := maxi(1, roundi(a.distance_to(b) / 0.6))
		for k in m:
			var p0 := a.lerp(b, float(k) / m) + o * 0.5
			var p1 := a.lerp(b, float(k + 1) / m) + o * 0.5
			_quad(Vector3(p0.x, g, p0.y), Vector3(p1.x, g, p1.y), Vector3(p1.x, g + 0.6, p1.y), Vector3(p0.x, g + 0.6, p0.y),
					Vector3(o.x, 0.0, o.y).normalized(), OCH_WHITE if k % 2 == 0 else OCH_BLACK)
	_mode = keep
	_och_roof(g, h)
	_och_supports(g, h)
	_och_stairs(g, hu, hv, low)
	# The kiosk by the entrance on the street side.
	_prism(_rect(hu + 4.0, hv - 2.5, 1.3, 1.0), g, g + 2.5, Color("#d7d2c4"), OCH_FRAME, M_PAVILION, M_STONE)
	# The blue WARSZAWA OCHOTA letters on their steel frame by the entrance, over the street.
	var fs := 1.0 if _a.dot(BEHIND_FACE) >= 0.0 else -1.0
	var out := _a * fs
	var along := Vector2(-out.y, out.x)  # leftwards as read (Neon.place: right = (out.z, -out.x))
	var base := _w(hu + 7.5, -hv + 1.0)
	var top_y := g + 4.2
	var k := 0.42
	var half := (Neon.length_of("WARSZAWA") + Neon.length_of("OCHOTA")) * k * 0.5 + 0.6
	for sgn in [-1.0, 1.0]:
		var p := base + along * half * float(sgn)
		_prism(_square(p, 0.09), g - 0.2, top_y, OCH_FRAME, OCH_FRAME, M_STONE, M_STONE)
	var b0 := base - along * half
	var b1 := base + along * half
	_beam(Vector3(b0.x, top_y, b0.y), Vector3(b1.x, top_y, b1.y), 0.16, OCH_FRAME)
	for word: Array in [["WARSZAWA", 1.0], ["OCHOTA", -1.0]]:
		var w: String = word[0]
		var at := base + along * (float(word[1]) * (Neon.length_of(w) * k * 0.5 + 0.25))
		signs.append([w, Vector3(at.x, top_y + 0.08, at.y), Vector3(out.x, 0.0, out.y), k, OCH_NEON])
	_collide_span(hall, low - 1.0, g + 4.0)


## The shell: a ruled grid of OCH_GRID x OCH_GRID quads, white on top, the mosaic's black and
## white stripes underneath (one stripe per ruling), the thin edge round it.
func _och_roof(g: float, h: float) -> void:
	_mode = M_STONE
	var n := OCH_GRID
	var step := 2.0 * h / n
	for j in n:
		for i in n:
			var u0 := -h + i * step
			var u1 := u0 + step
			var v0 := -h + j * step
			var v1 := v0 + step
			var p00 := _w(u0, v0)
			var p10 := _w(u1, v0)
			var p11 := _w(u1, v1)
			var p01 := _w(u0, v1)
			var y00 := g + _och_shell(u0, v0, h)
			var y10 := g + _och_shell(u1, v0, h)
			var y11 := g + _och_shell(u1, v1, h)
			var y01 := g + _och_shell(u0, v1, h)
			var top: Array[Vector3] = [Vector3(p00.x, y00, p00.y), Vector3(p10.x, y10, p10.y), Vector3(p11.x, y11, p11.y), Vector3(p01.x, y01, p01.y)]
			var nt := (top[1] - top[0]).cross(top[3] - top[0]).normalized()
			if nt.y < 0.0:
				nt = -nt
			# The stripes show on top too, faintly: the game's camera never sees the underside.
			_quad(top[0], top[1], top[2], top[3], nt, OCH_WHITE if i % 2 == 0 else OCH_WHITE.darkened(0.16))
			var dn := Vector3(0.0, -OCH_SHELL, 0.0)
			var stripe := OCH_BLACK if i % 2 == 0 else OCH_WHITE.darkened(0.06)
			var keep := _no_roof
			_no_roof = true
			_quad(top[0] + dn, top[1] + dn, top[2] + dn, top[3] + dn, -nt, stripe)
			_no_roof = keep
	# The edge, following the shell along each side.
	var cs := [Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]
	var ring := PackedVector2Array()
	for c: Vector2 in cs:
		ring.append(_w(c.x, c.y))
	for i in 4:
		var c0: Vector2 = cs[i]
		var c1: Vector2 = cs[(i + 1) % 4]
		var o := _out(ring, ring[i], ring[(i + 1) % 4])
		for k in n:
			var e0: Vector2 = c0.lerp(c1, float(k) / n)
			var e1: Vector2 = c0.lerp(c1, float(k + 1) / n)
			var a := _w(e0.x, e0.y)
			var b := _w(e1.x, e1.y)
			var t0 := g + _och_shell(e0.x, e0.y, h)
			var t1 := g + _och_shell(e1.x, e1.y, h)
			_quad(Vector3(a.x, t0 - OCH_SHELL, a.y), Vector3(b.x, t1 - OCH_SHELL, b.y), Vector3(b.x, t1, b.y), Vector3(a.x, t0, a.y),
					Vector3(o.x, 0.0, o.y), OCH_WHITE.darkened(0.05))


## The two low corners on hinged concrete supports (raked struts down to the deck), and one high
## corner on its sliding bearing: a slim column. The other high corner is free.
func _och_supports(g: float, h: float) -> void:
	for c: Vector2 in [Vector2(h, -h * _och_v), Vector2(-h, h * _och_v)]:
		var top := _w(c.x, c.y)
		var foot := _w(c.x * 0.86, c.y * 0.86)
		var y := g + _och_shell(c.x, c.y, h) - OCH_SHELL
		_beam(Vector3(foot.x, g, foot.y), Vector3(top.x, y, top.y), 0.55, OCH_CONCRETE)
		_prism(_rect(c.x * 0.86, c.y * 0.86, 0.6, 0.6), g, g + 0.35, OCH_CONCRETE.darkened(0.1), OCH_CONCRETE, M_STONE, M_STONE)
	var hc := _w(h - 0.5, (h - 0.5) * _och_v)
	_beam(Vector3(hc.x, g, hc.y), Vector3(hc.x, g + _och_shell(h - 0.5, (h - 0.5) * _och_v, h) - OCH_SHELL - 0.3, hc.y), 0.32, OCH_FRAME)


## The stairs from the hall down to the island platform in the cutting, along the tracks (-v)
## from the hall's cutting side: a flight of steps between two concrete parapets.
func _och_stairs(g: float, hu: float, hv: float, low: float) -> void:
	var cu := -hu + 3.2
	var half := 1.6
	var floor_y := low + 0.9   # the platform's top (bake_osm: railway platforms 0.9 m)
	var drop := g - floor_y
	if drop < 1.0:
		return
	var steps := clampi(roundi(drop / 0.17), 6, 40)
	var run := 0.3
	var none := Color(0, 0, 0, 0)
	for k in steps:
		var v0 := -hv - k * run
		var y := g - (k + 1) * drop / steps
		_prism(_rect(cu, v0 - run * 0.5, half, run * 0.5), y - 0.2, y + drop / steps, OCH_CONCRETE.lightened(0.04), OCH_CONCRETE.lightened(0.1), M_STONE, M_STONE)
	var len := steps * run
	for side in [-1.0, 1.0]:
		var su: float = cu + side * (half + 0.12)
		var p0 := _w(su, -hv)
		var p1 := _w(su, -hv - len)
		_beam(Vector3(p0.x, g + 0.5, p0.y), Vector3(p1.x, floor_y + 0.5, p1.y), 0.24, OCH_CONCRETE.darkened(0.12))


# --- Warszawa Powiśle (S2 of docs/design/railway.md, 2026-11-01) -------------------------------

## The cross-city line's station on the embankment between the tunnel's east mouth and the
## bridge (Romanowicz and Szymaniak, designed 1954-55, opened 1963). The upper pavilion, the
## ticket hall on the Aleje level at the edge of the escarpment over the tunnel's mouth: a roof
## stretched between two concrete arches, sagging between them into its own gutter ("a kite
## floating in the air"), glass under it. The lower pavilion at the platforms' east end by
## Kruczkowskiego: a glass drum under an inverted dome, a shallow saucer with its rim up (the
## "UFO"), since 2013 the café-club "Warszawa Powiśle" with the station's name in neon on the
## rim. The two side platforms between them under canopies on X-shaped steel supports. Built from
## the OSM outlines and published descriptions (no photo in the cloud): spec
## docs/landmarks/specs/powisle.md; the Mac photo check sets the arches, the saucer and the
## canopies' length.
const POW_OSM := "Dworzec PKP Powiśle"
# F (2026-11-13, a Street View still and Mapillary 2025-2026): the upper pavilion's roof is a
# hyperbolic paraboloid with straight edges, two opposite corners up and two down, so along the
# Aleje its long front rises in a straight line from low by the gate tower (east) to high at the
# far (west) end. It was a kite with both ends turned up. LoD2 2454 has its top 6.0-7.4 m.
const POW_MID := 5.2           # the roof over the hall's floor at its middle
const POW_TWIST := 1.8         # how far its corners rise over and dip under that (3.4 m to 7.0 m)
const POW_FASCIA := Color("#6e3a2c")   # the edge band's red-brown (F's still)
var _pow_twist := 1.0          # +1 or -1: which pair of the roof's corners stands up (_pow_upper)
const POW_INSET := 1.6         # the glass hall's set-back under the roof's edges
const POW_GRID := 10
const POW_LOW_C := Vector2(400.8, -6.3)   # the round pavilion's centre (its OSM roof outline)
const POW_LOW_R := 14.6        # the saucer's radius (the Mac photo check: it overhangs the drum about twice)
const POW_DRUM_R := 7.8        # the glass drum's radius
const POW_DRUM_H := 3.4
const POW_RIM := 4.5           # the saucer's rim over the floor
const POW_DISH := 0.8          # how far its middle dips under the rim
const POW_SIDES := 28
const POW_CANOPY := 72.0       # each platform's canopy length (middle of the platform)
const POW_BAY := 7.2           # supports' spacing
const POW_WHITE := Color("#e6e4dd")
const POW_GREY := Color("#8d9095")

const POW_GLASS := Color("#5d717c")
const POW_GRANITE := Color("#9b9c97")
## The tunnel's mouth under the upper pavilion (F's platform photo, 2026-11-13): a grey station
## block over two dark mouths, one per pair of tracks, a pier with a stair up from the platform
## between them. The frame: the line where Trains.TUNNEL_POWISLE cuts the rails (origin, +lat
## along it to the south, +out away from the tunnel); the tracks cross it at lat -6.9, -3.1,
## 5.8 and 9.3, the platform between the pairs at lat 0-3.
const POW_MOUTH_O := Vector2(178.52, 76.91)
const POW_MOUTH_LAT := Vector2(0.328, 0.945)
const POW_MOUTH_SPAN := Vector2(-10.6, 13.0)   # the headwall's ends (map_builder _build_rail_portals)
const POW_MOUTH_PIER := Vector2(-1.2, 3.6)     # the pier between the two mouths
const POW_MOUTH_H := 6.4                       # map_builder RAIL_MOUTH
const POW_CLAD := Color("#a3a49f")
const POW_SIGN := Color("#24489a")
const POW_NEON := Color(1.0, 0.82, 0.2)   # the round pavilion's yellow tube letters
const POW_BLUE := Color(0.2, 0.5, 1.0)     # the upper pavilion's letters over the doors
# The round pavilion from F's photos (2026-11-06): the saucer's knife edge, the letter boxes on
# the rim, the festoons, the terrace and the jazz stage (powisle_jazz_plan).
const POW_EDGE := 0.35         # the rim's white edge
const POW_RIBS := 16           # the top's radial seams (F's archive photo), their width, colour
const POW_RIB_W := 0.22
const POW_RIB := Color("#c9c6bd")
const POW_DRAIN_R := 0.75      # the round drain in the dish's middle
const POW_LETTER_W := 1.05     # one letter box: width, depth, height, the gap between two
const POW_LETTER_D := 0.32
const POW_LETTER_H := 1.75
const POW_LETTER_GAP := 0.18
const POW_SPACE_W := 1.0       # between WARSZAWA and POWIŚLE
const POW_RAIL_H := 0.35       # the steel rail the boxes stand on, over the rim's top
const POW_BOX := Color("#22302f")          # the boxes: dark teal-black (the photos)
const POW_TUBE := Color(1.0, 0.84, 0.3)    # the tubes by day; lit at night (M_LAMP)
const POW_POSTS := [-22.0, 0.0, 22.0]    # the festoons' posts over the deck chairs (degrees)
const POW_POST_R := 22.4
const POW_STAGE_DEG := -5.0    # the stage's direction from the saucer's middle (degrees from +x to +z): east, the open
                               # paving towards Kruczkowskiego the game's camera sees past the saucer (south of it the viaduct hides the ground)
const POW_STAGE_R := 13.0      # its middle from the saucer's (under the canopy's edge: the camera sees the band)
const POW_STAGE_HU := 1.5      # half its depth (out) and width (across)
const POW_STAGE_HV := 3.6
const POW_STAGE_H := 0.6
const POW_CROWD_R := 18.2      # the standing audience: out to here, in a fan this wide (degrees)
const POW_CROWD_SPAN := 46.0
const POW_CROWD_MAX := 48
const POW_CHAIR_R := 19.4      # the deck chairs' first arc behind the standing audience, between these directions
const POW_CHAIR_DEG := Vector2(-20.0, 14.0)
## The café tables: direction (degrees), distance from the saucer's middle, chairs round it.
const POW_TABLES := [[-36.0, 18.0, 4], [-48.0, 17.2, 3], [-60.0, 18.6, 4], [-42.0, 21.4, 2], [-54.0, 21.0, 3], [-68.0, 21.6, 2]]
const POW_SLING := Color("#e8682a")        # the deck chairs' orange canvas, a white band across it
const POW_SLING_BAND := Color("#f1ece2")
const POW_TABLE_TOP := Color("#d9d2c4")
const POW_RED := Color("#c8312b")          # the café tables' frames
const POW_CHAIR := Color("#eeeeea")        # white folding chairs
const POW_RISER := Color("#1d1d20")
const POW_DECK := Color("#3a312b")
const POW_VALANCE := Color("#e9dfc8")
const POW_JAZZ := Color(1.0, 0.45, 0.85)   # the JAZZ neon on the valance
const POW_TRUSS := Color("#9da1a6")
const POW_PIANO := Color("#17171a")
const POW_KEYS := Color("#f2f0ea")
const POW_BASS := Color("#7a3e1d")
const POW_BRASS := Color("#c9a44a")


func _find_powisle() -> void:
	var q := _landmark(POW_OSM)
	if q.size() < 3:
		return
	var ring := PackedVector2Array()
	for k in POW_SIDES:
		ring.append(POW_LOW_C + Vector2.from_angle(TAU * k / POW_SIDES) * (POW_LOW_R + 1.0))
	_add_site("powisle", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER)), ring])
	tree_free.append([POW_LOW_C, POW_LOW_R + 1.0])
	if sites.is_empty() or sites[-1]["key"] != "powisle":
		return
	sites[-1]["frame"] = _och_frame(_simplify(q, 0.4))
	# The two side platforms between the pavilions (their outlines, longest first).
	var plats: Array = []
	var mid := (_centre(q) + POW_LOW_C) * 0.5
	for pl in data.get("platforms", []):
		var p := _pts(pl["p"])
		if p.size() >= 3 and _centre(p).distance_to(mid) < 140.0:
			plats.append(_och_frame(_simplify(p, 0.3)))
	sites[-1]["platforms"] = plats


## The roof's height over the floor at local (u, v): a hyperbolic paraboloid, its edges straight,
## the corner that stands south-east low (_pow_twist sets which way the frame runs).
func _pow_roof(u: float, v: float, hu: float, hv: float) -> float:
	var s := clampf(u / hu, -1.0, 1.0)
	var t := clampf(v / hv, -1.0, 1.0)
	return POW_MID + POW_TWIST * _pow_twist * s * t


func _build_powisle(site: Dictionary) -> void:
	_pow_upper(site["frame"])
	_pow_portal()
	_pow_lower()
	for f: Array in site.get("platforms", []):
		_pow_canopy(f)


## The station block over the tunnel's mouth, the pier between its two mouths and the stair from
## the platform into the pier (POW_MOUTH_*). Drawn in front of map_builder's headwall (its face
## on the cut line), after _pow_upper (_g is the pavilion's floor).
func _pow_portal() -> void:
	_o = POW_MOUTH_O
	_a = POW_MOUTH_LAT
	_b = Vector2(_a.y, -_a.x)   # out of the tunnel, east
	var rail: float = map.terrain_height(_w(-5.0, 4.0).x, _w(-5.0, 4.0).y)
	var top: float = maxf(_g + 0.6, rail + POW_MOUTH_H + 3.0)
	var lo := POW_MOUTH_SPAN.x
	var hi := POW_MOUTH_SPAN.y
	var mid := (lo + hi) * 0.5
	var half := (hi - lo) * 0.5
	var band: float = rail + POW_MOUTH_H
	# The block over the mouths: cladding, a dark ribbon of windows, a cornice.
	_lbox(mid, 0.6, half, 0.6, band, top, POW_CLAD, M_STONE, POW_GREY)
	var win: float = band + (top - band) * 0.35
	var n := maxi(4, roundi((hi - lo) / 2.2))
	for k in n:
		var u := lo + 0.6 + (hi - lo - 1.2) * (k + 0.5) / n
		_lbox(u, 1.22, (hi - lo - 1.2) / n * 0.5 - 0.12, 0.03, win, win + 1.3, POW_DARK, M_STONE)
	_lbox(mid, 0.7, half + 0.1, 0.7, top - 0.3, top, POW_GREY.lightened(0.15), M_STONE)
	_lbox(mid, 0.65, half + 0.05, 0.65, band - 0.35, band, POW_GREY, M_STONE)
	# The blue station boards under the block, one over each mouth.
	for u: float in [(lo + POW_MOUTH_PIER.x) * 0.5, (POW_MOUTH_PIER.y + hi) * 0.5]:
		_lbox(u, 1.25, 1.4, 0.05, band - 0.7, band, POW_SIGN, M_STONE)
		_lbox(u, 1.31, 1.2, 0.02, band - 0.55, band - 0.2, POW_WHITE, M_STONE)
	# The pier between the mouths, its doorway at the stair's head.
	var pm := (POW_MOUTH_PIER.x + POW_MOUTH_PIER.y) * 0.5
	var ph := (POW_MOUTH_PIER.y - POW_MOUTH_PIER.x) * 0.5
	_lbox(pm, 0.6, ph, 0.6, rail - 0.3, band, POW_CLAD.darkened(0.05), M_STONE)
	var deck: float = rail + 0.9          # the platform's top
	var head: float = rail + 3.6          # the stair's head, the doorway's sill
	_lbox(pm, 1.22, 1.0, 0.03, head, head + 2.4, POW_DARK, M_STONE)
	# The stair down the platform to the pier.
	var steps := 9
	var run := 0.75
	for k in steps:
		var y: float = deck + (head - deck) * (k + 1) / steps
		var o := 1.2 + (steps - 1 - k) * run
		_lbox(pm, o + run * 0.5, 1.0, run * 0.5, deck, y, POW_GRANITE.darkened(0.08 if k % 2 == 0 else 0.0), M_STONE)


func _pow_upper(f: Array) -> void:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	# The south-east corner (largest x + z) stands low: the front by the gate tower.
	var se := Vector2.ZERO
	var most := -INF
	for c: Vector2 in [Vector2(hu, hv), Vector2(-hu, hv), Vector2(hu, -hv), Vector2(-hu, -hv)]:
		var w := _w(c.x, c.y)
		if w.x + w.y > most:
			most = w.x + w.y
			se = c
	_pow_twist = -signf(se.x * se.y)
	# The floor: the Aleje level (the highest ground under the outline).
	var g := -INF
	for k in range(-2, 3):
		for m in range(-2, 3):
			var p := _w(hu * k * 0.5, hv * m * 0.5)
			g = maxf(g, map.terrain_height(p.x, p.y))
	_g = g
	var none := Color(0, 0, 0, 0)
	# The base down to the ground on the escarpment's falling side: grey granite (F's street photo,
	# 2026-11-13: the glass hall stands on a granite plinth; the glazed base read as the tracks
	# running into a glass wall).
	_lbox(0.0, 0.0, hu, hv, g - 6.0, g, POW_GRANITE, M_STONE, POW_GREY.lightened(0.2))
	# The glass hall, set back under the roof; its tops follow the roof's underside.
	var iu := hu - POW_INSET
	var iv := hv - POW_INSET
	var corners := [Vector2(-iu, -iv), Vector2(iu, -iv), Vector2(iu, iv), Vector2(-iu, iv)]
	var hall := PackedVector2Array()
	for c: Vector2 in corners:
		hall.append(_w(c.x, c.y))
	for i in 4:
		var c0: Vector2 = corners[i]
		var c1: Vector2 = corners[(i + 1) % 4]
		var a := hall[i]
		var b := hall[(i + 1) % 4]
		var o := _out(hall, a, b)
		var nrm := Vector3(o.x, 0.0, o.y)
		var n := maxi(2, roundi(a.distance_to(b) / 1.8))
		for k in n:
			var l0: Vector2 = c0.lerp(c1, float(k) / n)
			var l1: Vector2 = c0.lerp(c1, float(k + 1) / n)
			var p0 := a.lerp(b, float(k) / n)
			var p1 := a.lerp(b, float(k + 1) / n)
			var t0 := g + _pow_roof(l0.x, l0.y, hu, hv) - 0.2
			var t1 := g + _pow_roof(l1.x, l1.y, hu, hv) - 0.2
			_mode = M_PAVILION
			_quad(Vector3(p0.x, g, p0.y), Vector3(p1.x, g, p1.y), Vector3(p1.x, t1, p1.y), Vector3(p0.x, t0, p0.y), nrm, POW_GLASS,
					Vector2(0.0, 0.0), Vector2(1.8, 0.0), Vector2(1.8, t1 - g), Vector2(0.0, t0 - g), maxf(t0, t1) - g)
			_mode = M_STONE
			var d := (p1 - p0).normalized() * 0.07
			var q := p0 + o * 0.1
			_quad(Vector3(q.x - d.x, g, q.y - d.y), Vector3(q.x + d.x, g, q.y + d.y), Vector3(q.x + d.x, t0, q.y + d.y),
					Vector3(q.x - d.x, t0, q.y - d.y), nrm, POW_DARK)
	# The roof: a grid between the arches, white on top, grey under.
	var n := POW_GRID
	for j in n:
		for i in n:
			var u0 := -hu + 2.0 * hu * i / n
			var u1 := -hu + 2.0 * hu * (i + 1) / n
			var v0 := -hv + 2.0 * hv * j / n
			var v1 := -hv + 2.0 * hv * (j + 1) / n
			var pts := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
			var top: Array[Vector3] = []
			for l: Vector2 in pts:
				var w := _w(l.x, l.y)
				top.append(Vector3(w.x, g + _pow_roof(l.x, l.y, hu, hv), w.y))
			var nt := (top[1] - top[0]).cross(top[3] - top[0]).normalized()
			if nt.y < 0.0:
				nt = -nt
			_quad(top[0], top[1], top[2], top[3], nt, POW_WHITE)
			var dn := Vector3(0.0, -0.18, 0.0)
			var keep := _no_roof
			_no_roof = true
			_quad(top[0] + dn, top[1] + dn, top[2] + dn, top[3] + dn, -nt, POW_GREY.lightened(0.15))
			_no_roof = keep
	# The dark fascia along the roof's long sides, following its sag, swept as one piece each.
	for side in [-1.0, 1.0]:
		var v: float = side * (hv + 0.05)
		var line: Array[Vector3] = []
		for k in range(0, 13):
			var u := -hu + 2.0 * hu * k / 12.0
			var w := _w(u, v)
			line.append(Vector3(w.x, g + _pow_roof(u, v, hu, hv) - 0.1, w.y))
		_pow_rib(line, Vector3(_b.x, 0.0, _b.y), 0.2, POW_FASCIA)
	# The blue WARSZAWA POWIŚLE letters over the doors, on the glass side the game's camera sees.
	var best := -2.0
	var face := Vector2.ZERO
	var reach := 0.0
	for d: Array in [[_a, iu], [-_a, iu], [_b, iv], [-_b, iv]]:
		var dir: Vector2 = d[0]
		if dir.dot(BEHIND_FACE) > best:
			best = dir.dot(BEHIND_FACE)
			face = dir
			reach = d[1]
	var along := Vector2(-face.y, face.x)
	var k := 0.36
	for word: Array in [["WARSZAWA", 1.0], ["POWIŚLE", -1.0]]:
		var w: String = word[0]
		var at := _o + face * reach + along * (float(word[1]) * (Neon.length_of(w) * k * 0.5 + 0.3))
		signs.append([w, Vector3(at.x, g + 2.7, at.y), Vector3(face.x, 0.0, face.y), k, POW_BLUE])
	_collide_span(hall, g - 6.0, g + 4.0)


## A rib swept along `line`: square section 2r, `side` the horizontal axis across it.
func _pow_rib(line: Array[Vector3], side: Vector3, r: float, col: Color) -> void:
	_mode = M_STONE
	var ring: Array = []
	for k in line.size():
		var t := (line[mini(k + 1, line.size() - 1)] - line[maxi(k - 1, 0)]).normalized()
		var up := side.cross(t).normalized()
		if up.y < 0.0:
			up = -up
		ring.append([line[k] + up * r + side * r, line[k] + up * r - side * r, line[k] - up * r - side * r, line[k] - up * r + side * r])
	for k in line.size() - 1:
		var a: Array = ring[k]
		var b: Array = ring[k + 1]
		for f in 4:
			var p0: Vector3 = a[f]
			var p1: Vector3 = a[(f + 1) % 4]
			var q1: Vector3 = b[(f + 1) % 4]
			var q0: Vector3 = b[f]
			var mid := (p0 + p1 + q0 + q1) * 0.25 - (line[k] + line[k + 1]) * 0.5
			_quad(p0, p1, q1, q0, mid.normalized(), col)


## The round pavilion from F's photos (2026-11-06): the café-club under the "UFO". A glass
## drum under a wide white saucer with a thin rim, its middle dipping, its underside rising from
## the drum to the rim; WARSZAWA POWIŚLE on top of the rim's front arc in separate dark letter
## boxes on a steel rail, each with yellow tube letters on stand-offs (yellow by day, lit at
## night, a neon glow over each); a festoon of warm bulbs all round the rim's edge and three more
## out to posts over the deck chairs; the terrace: orange deck chairs (a parody brewery's, its
## name too small to read), red café tables with white folding chairs, and the jazz stage under
## the canopy's edge (the plan: powisle_jazz_plan, shared with crowds.gd's band and audience).
func _pow_lower() -> void:
	var c := POW_LOW_C
	var g := powisle_floor(map)
	_g = g
	var none := Color(0, 0, 0, 0)
	var drum := PackedVector2Array()
	var rim := PackedVector2Array()
	for k in POW_SIDES:
		drum.append(c + Vector2.from_angle(TAU * k / POW_SIDES) * POW_DRUM_R)
		rim.append(c + Vector2.from_angle(TAU * k / POW_SIDES) * POW_LOW_R)
	_prism(drum, g - 0.5, g + POW_DRUM_H, POW_GLASS.lightened(0.1), none, M_PAVILION)
	_mullions(drum, g, g + POW_DRUM_H, 1.6, 0.05, POW_DARK)
	# The dark transom band round the drum's top (the photos: a black frame under the saucer).
	_prism(_pow_ring(c, POW_DRUM_R + 0.06), g + POW_DRUM_H - 0.45, g + POW_DRUM_H, POW_DARK, none, M_STONE)
	# The saucer's top: a shallow dish from the middle (low) up to the rim.
	var rings := [0.0, 0.45, 0.8, 1.0]
	var top_y := g + POW_RIM
	_mode = M_STONE
	for r in range(rings.size() - 1):
		for k in POW_SIDES:
			var a0 := Vector2.from_angle(TAU * k / POW_SIDES)
			var a1 := Vector2.from_angle(TAU * (k + 1) / POW_SIDES)
			var r0: float = rings[r]
			var r1: float = rings[r + 1]
			var y0 := top_y - POW_DISH * (1.0 - r0 * r0)
			var y1 := top_y - POW_DISH * (1.0 - r1 * r1)
			var p00 := c + a0 * r0 * POW_LOW_R
			var p01 := c + a1 * r0 * POW_LOW_R
			var p10 := c + a0 * r1 * POW_LOW_R
			var p11 := c + a1 * r1 * POW_LOW_R
			var q: Array[Vector3] = [Vector3(p00.x, y0, p00.y), Vector3(p10.x, y1, p10.y), Vector3(p11.x, y1, p11.y), Vector3(p01.x, y0, p01.y)]
			var nt := (q[1] - q[0]).cross(q[3] - q[0])
			if nt.length_squared() < 1e-6:
				nt = (q[2] - q[0]).cross(q[1] - q[0])
			nt = nt.normalized()
			if nt.y < 0.0:
				nt = -nt
			if r0 == 0.0:
				_tri(q[0], q[1], q[2], nt, POW_WHITE.darkened(0.04), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			else:
				_quad(q[0], q[1], q[2], q[3], nt, POW_WHITE.darkened(0.04))
	# The top's ribs (F's archive photo, 2026-11-06): radial seams from the round drain in the
	# middle out to the rim, raised a little over the dish, following its rings; the drain dark.
	var dish := func(t: float) -> float:
		var tt := clampf(t, 0.0, 1.0)
		var ys := [0.0, 0.45, 0.8, 1.0]
		for j in 3:
			var a: float = ys[j]
			var b: float = ys[j + 1]
			if tt <= b:
				var ya := top_y - POW_DISH * (1.0 - a * a)
				var yb := top_y - POW_DISH * (1.0 - b * b)
				return lerpf(ya, yb, (tt - a) / (b - a))
		return top_y
	var stops := [POW_DRAIN_R / POW_LOW_R, 0.45, 0.8, 0.985]
	for k in POW_RIBS:
		var d := Vector2.from_angle(TAU * (k + 0.5) / POW_RIBS)
		var e := Vector2(-d.y, d.x) * POW_RIB_W * 0.5
		for j in stops.size() - 1:
			var t0: float = stops[j]
			var t1: float = stops[j + 1]
			var p0 := c + d * t0 * POW_LOW_R
			var p1 := c + d * t1 * POW_LOW_R
			var y0: float = dish.call(t0) + 0.04
			var y1: float = dish.call(t1) + 0.04
			var q0 := Vector3(p0.x - e.x, y0, p0.y - e.y)
			var q1 := Vector3(p1.x - e.x, y1, p1.y - e.y)
			var q2 := Vector3(p1.x + e.x, y1, p1.y + e.y)
			var q3 := Vector3(p0.x + e.x, y0, p0.y + e.y)
			var nr := (q1 - q0).cross(q3 - q0).normalized()
			if nr.y < 0.0:
				nr = -nr
			_quad(q0, q1, q2, q3, nr, POW_RIB)
	var drain := PackedVector2Array()
	for k in 12:
		drain.append(c + Vector2.from_angle(TAU * k / 12.0) * POW_DRAIN_R)
	var dy: float = dish.call(0.0) + 0.03
	for k in 12:
		var a := drain[k]
		var b := drain[(k + 1) % 12]
		_tri(Vector3(c.x, dy, c.y), Vector3(a.x, dy, a.y), Vector3(b.x, dy, b.y), Vector3.UP, POW_GREY.darkened(0.25),
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The rim: a thin white edge (the photos: a knife edge, about a third of a metre).
	_prism(rim, top_y - POW_EDGE, top_y, POW_WHITE, none, M_STONE)
	# The underside: from the drum's top curving up to the rim's lower edge, in three bands.
	var keep := _no_roof
	_no_roof = true
	var under := [[POW_DRUM_R, g + POW_DRUM_H]]
	for t: float in [0.35, 0.7, 1.0]:
		under.append([lerpf(POW_DRUM_R, POW_LOW_R, t), g + POW_DRUM_H + (top_y - POW_EDGE - g - POW_DRUM_H) * (1.0 - (1.0 - t) * (1.0 - t))])
	for j in under.size() - 1:
		var ra: float = under[j][0]
		var ya: float = under[j][1]
		var rb: float = under[j + 1][0]
		var yb: float = under[j + 1][1]
		for k in POW_SIDES:
			var d0 := Vector2.from_angle(TAU * k / POW_SIDES)
			var d1 := Vector2.from_angle(TAU * (k + 1) / POW_SIDES)
			var a := c + d0 * rb
			var b := c + d1 * rb
			var a2 := c + d0 * ra
			var b2 := c + d1 * ra
			var mid := (d0 + d1).normalized()
			var nrm := Vector3(mid.x * (yb - ya), -(rb - ra), mid.y * (yb - ya)).normalized()
			_quad(Vector3(a.x, yb, a.y), Vector3(b.x, yb, b.y), Vector3(b2.x, ya, b2.y), Vector3(a2.x, ya, a2.y), nrm,
					POW_GREY.lightened(0.25 + 0.1 * j))
	# The letters on the rim, the bulbs round its edge and out over the terrace, the terrace, the stage.
	_pow_letters(top_y)
	_pow_bulbs(top_y - POW_EDGE)
	var plan := powisle_jazz_plan()
	_pow_terrace(plan, g)
	_pow_stage(plan, g)
	_no_roof = keep
	_collide(drum)
	_collide(plan["stage"])


## The round pavilion's floor: the lowest ground under its drum (the landmark and the crowds
## stand on it alike).
static func powisle_floor(m: Object) -> float:
	if m == null or not m.has_method("terrain_height"):
		return 0.0
	var g := INF
	for k in 8:
		var p := POW_LOW_C + Vector2.from_angle(TAU * k / 8.0) * POW_DRUM_R
		g = minf(g, float(m.call("terrain_height", p.x, p.y)))
	return g


func _pow_ring(c: Vector2, r: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for k in POW_SIDES:
		ring.append(c + Vector2.from_angle(TAU * k / POW_SIDES) * r)
	return ring


## WARSZAWA POWIŚLE on the rim's front arc (the side the game's camera sees): one dark box a
## letter on a steel rail, facing out from the saucer's middle, the letter's strokes in yellow
## tubes (M_LAMP: yellow by day, lit at night) a hand's breadth in front of the box, and one
## neon glyph over each for the glow at night.
func _pow_letters(top_y: float) -> void:
	var c := POW_LOW_C
	var o := BEHIND_FACE.normalized()
	var text := "WARSZAWA POWIŚLE"
	var r := POW_LOW_R - 0.75
	var step := POW_LETTER_W + POW_LETTER_GAP
	var total := 0.0
	for ch in text:
		total += POW_SPACE_W if ch == " " else step
	total -= POW_LETTER_GAP
	# Arc length -> angle; the first letter at the reader's left (+along, see Neon.place).
	var s := total * 0.5
	var base := o.angle()
	var rail: Array[Vector3] = []
	for ch in text:
		if ch == " ":
			s -= POW_SPACE_W
			continue
		var phi := base + (s - POW_LETTER_W * 0.5) / r
		s -= step
		var d := Vector2.from_angle(phi)
		var p := c + d * r
		var y0 := top_y + POW_RAIL_H
		_pow_box(p, d, POW_LETTER_D * 0.5, POW_LETTER_W * 0.5, y0, y0 + POW_LETTER_H, POW_BOX, POW_BOX.lightened(0.08))
		# Its two legs down to the rim.
		var e := Vector2(-d.y, d.x)
		for side: float in [-1.0, 1.0]:
			var f := p + e * (side * POW_LETTER_W * 0.32)
			_beam(Vector3(f.x, top_y - 0.05, f.y), Vector3(f.x, y0 + 0.02, f.y), 0.07, POW_DARK, false)
		rail.append(Vector3(p.x, top_y + POW_RAIL_H * 0.5, p.y))
		# The strokes: the glyph's horizontal and vertical runs as tubes, odd pixels as dots.
		var px := (POW_LETTER_H - 0.4) / 9.0
		var right := Vector2(d.y, -d.x)  # the reader's right, facing the box
		var gw := _pow_glyph_w(ch)
		var face := p + d * (POW_LETTER_D * 0.5 + 0.1)
		var bottom := y0 + 0.2 + px * 0.5   # the body's lowest row's centre (row BODY + 6)
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		var at := func(x: float, row: float) -> Vector3:
			var w := face + right * ((x - (gw - 1) * 0.5) * px)
			return Vector3(w.x, bottom + (PixelFont.BODY + 6 - row) * px, w.y)
		var nrm := Vector3(d.x, 0.0, d.y)
		var t := px * 0.32
		var used := {}
		_mode = M_LAMP
		for q: Vector2i in lit:
			# Horizontal runs from their left end.
			if not lit.has(q - Vector2i(1, 0)) and lit.has(q + Vector2i(1, 0)):
				var e2 := q
				while lit.has(e2 + Vector2i(1, 0)):
					e2 += Vector2i(1, 0)
				_pow_tube(at.call(float(q.x), float(q.y)), at.call(float(e2.x), float(e2.y)), right, t, nrm)
				for x in range(q.x, e2.x + 1):
					used[Vector2i(x, q.y)] = true
			# Vertical runs from their top.
			if not lit.has(q - Vector2i(0, 1)) and lit.has(q + Vector2i(0, 1)):
				var e3 := q
				while lit.has(e3 + Vector2i(0, 1)):
					e3 += Vector2i(0, 1)
				_pow_tube(at.call(float(q.x), float(q.y)), at.call(float(e3.x), float(e3.y)), right, t, nrm)
				for y in range(q.y, e3.y + 1):
					used[Vector2i(q.x, y)] = true
		for q: Vector2i in lit:
			if not used.has(q):
				_pow_tube(at.call(float(q.x), float(q.y)), at.call(float(q.x), float(q.y)), right, t, nrm)
		_mode = M_STONE
		# The night's glow over the box: the neon glyph of the same font, its body on the strokes.
		var k := px / Neon.PIXEL
		var w0 := face - d * 0.12
		signs.append([ch, Vector3(w0.x, bottom - px * 0.5 - Neon.PAD * Neon.PIXEL * k, w0.y), Vector3(d.x, 0.0, d.y), k, POW_NEON])
	# The rail the boxes stand on, along the arc.
	for i in rail.size() - 1:
		_beam(rail[i], rail[i + 1], 0.12, POW_DARK, false)


## One tube between two stroke ends (a dot when they meet): a flat strip on the letter's face,
## `t` its half width.
func _pow_tube(a: Vector3, b: Vector3, right: Vector2, t: float, nrm: Vector3) -> void:
	var r3 := Vector3(right.x, 0.0, right.y)
	var up := Vector3.UP
	if absf(a.y - b.y) > 1e-4:
		var lo := a if a.y < b.y else b
		var hi := b if a.y < b.y else a
		_quad(lo - up * t - r3 * t, lo - up * t + r3 * t, hi + up * t + r3 * t, hi + up * t - r3 * t, nrm, POW_TUBE)
	else:
		var l := a if (a - b).dot(r3) < 0.0 else b
		var r := b if (a - b).dot(r3) < 0.0 else a
		_quad(l - r3 * t - up * t, r + r3 * t - up * t, r + r3 * t + up * t, l - r3 * t + up * t, nrm, POW_TUBE)


## Warm bulbs on a wire round the rim's lower edge (sagging between hooks), and three festoons
## from the rim out to posts over the deck chairs (F's night photo).
func _pow_bulbs(edge_y: float) -> void:
	var c := POW_LOW_C
	var hooks := 30
	for k in hooks:
		var a := c + Vector2.from_angle(TAU * k / hooks) * (POW_LOW_R + 0.05)
		var b := c + Vector2.from_angle(TAU * (k + 1) / hooks) * (POW_LOW_R + 0.05)
		_pow_festoon(Vector3(a.x, edge_y - 0.02, a.y), Vector3(b.x, edge_y - 0.02, b.y), 0.22, 3)
	for deg: float in POW_POSTS:
		var d := Vector2.from_angle(deg_to_rad(deg))
		var foot := c + d * POW_POST_R
		var y: float = map.terrain_height(foot.x, foot.y)
		_beam(Vector3(foot.x, y - 0.3, foot.y), Vector3(foot.x, y + 3.4, foot.y), 0.1, POW_DARK)
		var from := c + d * (POW_LOW_R + 0.05)
		_pow_festoon(Vector3(from.x, edge_y - 0.02, from.y), Vector3(foot.x, y + 3.35, foot.y), 0.5, 6)


## The jazz evenings' plan (F, 2026-11-06), the same for the model (the stage, the deck chairs,
## the tables) and crowds.gd (the band on the stage, the audience in front, sitters in the deck
## chairs and at the tables). Angles round the saucer's middle in the map's plan (degrees from
## +x towards +z): the stage under the canopy's edge towards Kruczkowskiego, the standing
## audience out in front of it, the deck chairs facing it on the camera's side, the café tables
## to the south-west. Stage local: u out from the saucer's middle, v across.
static func powisle_jazz_plan() -> Dictionary:
	var c := POW_LOW_C
	var sd := Vector2.from_angle(deg_to_rad(POW_STAGE_DEG))
	var sv := Vector2(-sd.y, sd.x)
	var sc := c + sd * POW_STAGE_R
	var stage := PackedVector2Array([sc - sd * POW_STAGE_HU - sv * POW_STAGE_HV, sc + sd * POW_STAGE_HU - sv * POW_STAGE_HV,
			sc + sd * POW_STAGE_HU + sv * POW_STAGE_HV, sc - sd * POW_STAGE_HU + sv * POW_STAGE_HV])
	var face_out := atan2(-sd.x, -sd.y)   # a figure's yaw facing out from the stage (crowds.gd)
	# The band: bass, piano (sitting at the upright, its back to the saucer), drums (sitting), vibraphone.
	var band: Array = []
	# [u, v, sits, faces in]: the pianist faces the upright behind him, the others the audience.
	for b: Array in [[0.7, -2.2, 0, false], [0.0, -0.4, 1, true], [-0.1, 2.3, 1, false], [0.7, 1.0, 0, false]]:
		band.append([sc + sd * float(b[0]) + sv * float(b[1]), face_out + (PI if bool(b[3]) else 0.0), int(b[2])])
	var front := c + sd * (POW_STAGE_R + POW_STAGE_HU)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1963
	var standing: Array = []
	var rr := POW_STAGE_R + POW_STAGE_HU + 1.4
	while rr < POW_CROWD_R:
		var span := deg_to_rad(POW_CROWD_SPAN) * (0.55 + 0.45 * (rr - POW_STAGE_R) / (POW_CROWD_R - POW_STAGE_R))
		var n := maxi(3, int(span * rr / 0.85))
		for i in n:
			var a := deg_to_rad(POW_STAGE_DEG) + (float(i) / maxf(n - 1, 1) - 0.5) * span + rng.randf_range(-0.03, 0.03)
			var p := c + Vector2.from_angle(a) * (rr + rng.randf_range(-0.25, 0.25))
			var to := front - p
			standing.append([p, atan2(-to.x, -to.y) + rng.randf_range(-0.35, 0.35)])
		rr += 1.0
	standing.resize(mini(standing.size(), POW_CROWD_MAX))
	# The deck chairs, in two arcs facing the stage.
	var chairs: Array = []
	for arc: Array in [[POW_CHAIR_R, 6], [POW_CHAIR_R + 2.2, 7]]:
		var n: int = arc[1]
		for i in n:
			var a := deg_to_rad(lerpf(POW_CHAIR_DEG.x, POW_CHAIR_DEG.y, (float(i) + 0.5 * (n % 2)) / float(n)))
			var p := c + Vector2.from_angle(a) * float(arc[0])
			var to := (front - p).normalized()
			chairs.append([p, to])
	# The café tables, each with two to four folding chairs round it.
	var tables: Array = []
	var seats: Array = []
	for t: Array in POW_TABLES:
		var p := c + Vector2.from_angle(deg_to_rad(float(t[0]))) * float(t[1])
		var spin := rng.randf_range(0.0, PI * 0.5)
		tables.append([p, spin])
		for k in int(t[2]):
			var a := spin + TAU * k / float(t[2])
			var q := p + Vector2.from_angle(a) * 0.62
			var to := p - q
			seats.append([q, atan2(-to.x, -to.y), to.normalized()])
	return {"stage": stage, "centre": sc, "out": sd, "across": sv, "band": band, "standing": standing,
			"chairs": chairs, "tables": tables, "seats": seats}


## The terrace: deck chairs (orange slings with a white band, dark frames) and café tables (red
## frames, pale tops) with white folding chairs.
func _pow_terrace(plan: Dictionary, g: float) -> void:
	for ch: Array in plan["chairs"]:
		var p: Vector2 = ch[0]
		var d: Vector2 = ch[1]   # towards the stage: the sitter faces it
		var e := Vector2(-d.y, d.x)
		var y: float = map.terrain_height(p.x, p.y)
		var front := 0.45
		var back := -0.45
		# The sling: from the front bar (low) up to the back's top, in two pieces (orange, a white band).
		var lo := [p + d * front, 0.32]
		var mid := [p + d * 0.0, 0.48]
		var hi := [p + d * back, 0.95]
		var pieces := [[lo, mid, POW_SLING], [mid, [p + d * (back + 0.2), 0.78], POW_SLING_BAND], [[p + d * (back + 0.2), 0.78], hi, POW_SLING]]
		for pc: Array in pieces:
			var a: Vector2 = pc[0][0]
			var b: Vector2 = pc[1][0]
			var ya: float = y + float(pc[0][1])
			var yb: float = y + float(pc[1][1])
			var hw := 0.27
			var q0 := Vector3(a.x - e.x * hw, ya, a.y - e.y * hw)
			var q1 := Vector3(a.x + e.x * hw, ya, a.y + e.y * hw)
			var q2 := Vector3(b.x + e.x * hw, yb, b.y + e.y * hw)
			var q3 := Vector3(b.x - e.x * hw, yb, b.y - e.y * hw)
			var nrm := (q1 - q0).cross(q3 - q0).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			_quad(q0, q1, q2, q3, nrm, pc[2])
			_quad(q0, q1, q2, q3, -nrm, Color(pc[2]).darkened(0.2))
		# The frame: two side rails from the front foot up to the back, two back legs, the front bar.
		for side: float in [-1.0, 1.0]:
			var s := e * (side * 0.3)
			var ff := p + d * (front + 0.1) + s
			var bt := p + d * back + s
			var bf := p + d * (back + 0.15) + s
			_beam(Vector3(ff.x, y, ff.y), Vector3(bt.x, y + 1.0, bt.y), 0.05, POW_DARK, false)
			_beam(Vector3(bf.x, y + 0.5, bf.y), Vector3(bf.x - d.x * 0.35, y, bf.y - d.y * 0.35), 0.05, POW_DARK, false)
		var fl := p + d * front - e * 0.3
		var fr := p + d * front + e * 0.3
		_beam(Vector3(fl.x, y + 0.32, fl.y), Vector3(fr.x, y + 0.32, fr.y), 0.05, POW_DARK, false)
	for t: Array in plan["tables"]:
		var p: Vector2 = t[0]
		var d := Vector2.from_angle(float(t[1]))
		var y: float = map.terrain_height(p.x, p.y)
		_pow_box(p, d, 0.42, 0.42, y + 0.71, y + 0.75, POW_TABLE_TOP.darkened(0.1), POW_TABLE_TOP)
		_pow_box(p, d, 0.38, 0.38, y + 0.62, y + 0.71, POW_RED, Color(0, 0, 0, 0))
		var e := Vector2(-d.y, d.x)
		for corner: Vector2 in [d + e, d - e, -d + e, -d - e]:
			var f := p + corner * 0.34
			_beam(Vector3(f.x, y, f.y), Vector3(f.x, y + 0.63, f.y), 0.05, POW_RED, false)
	for st: Array in plan["seats"]:
		var p: Vector2 = st[0]
		var to: Vector2 = st[2]   # towards the table
		var y: float = map.terrain_height(p.x, p.y)
		var back := p - to * 0.2
		_pow_box(p, to, 0.2, 0.2, y + 0.42, y + 0.46, POW_CHAIR, POW_CHAIR)
		_pow_box(back, to, 0.025, 0.2, y + 0.46, y + 0.88, POW_CHAIR, POW_CHAIR)
		var e := Vector2(-to.y, to.x)
		for side: float in [-1.0, 1.0]:
			var a := p + to * 0.18 + e * (side * 0.17)
			var b := p - to * 0.2 + e * (side * 0.17)
			_beam(Vector3(a.x, y, a.y), Vector3(b.x, y + 0.88, b.y), 0.035, POW_CHAIR.darkened(0.25), false)


## The jazz stage under the canopy's edge: a low black riser with a cream valance and a JAZZ neon,
## a truss over its back with warm and blue lamps, two black speakers at its front corners, and
## the band's instruments (an upright piano, a double bass on its stand, a drum kit, a
## vibraphone).
func _pow_stage(plan: Dictionary, g: float) -> void:
	var sc: Vector2 = plan["centre"]
	var sd: Vector2 = plan["out"]
	var sv: Vector2 = plan["across"]
	var top := g + POW_STAGE_H
	_prism(plan["stage"], g - 0.3, top, POW_RISER, POW_DECK, M_STONE, M_STONE)
	# The valance on the stage's front: cream cloth, the JAZZ neon on it.
	var fc := sc + sd * (POW_STAGE_HU + 0.02)
	var n3 := Vector3(sd.x, 0.0, sd.y)
	var vl := fc - sv * (POW_STAGE_HV - 0.3)
	var vr := fc + sv * (POW_STAGE_HV - 0.3)
	_quad(Vector3(vl.x, g + 0.08, vl.y), Vector3(vr.x, g + 0.08, vr.y), Vector3(vr.x, top - 0.06, vr.y), Vector3(vl.x, top - 0.06, vl.y), n3, POW_VALANCE)
	var word := "JAZZ"
	var jw := fc + sd * 0.05
	var jk := 0.42 / (Neon.GLYPH_H * Neon.PIXEL)
	signs.append([word, Vector3(jw.x, g + 0.12 - Neon.PAD * Neon.PIXEL * jk, jw.y), n3, jk, POW_JAZZ])
	# The truss over the stage's back: two posts, a beam, the lamps hung under it.
	var back := sc - sd * (POW_STAGE_HU - 0.25)
	var tr_y := top + 2.75
	for s: float in [-1.0, 1.0]:
		var f := back + sv * (s * (POW_STAGE_HV - 0.2))
		_beam(Vector3(f.x, top, f.y), Vector3(f.x, tr_y + 0.2, f.y), 0.22, POW_TRUSS)
	var t0 := back - sv * (POW_STAGE_HV - 0.2)
	var t1 := back + sv * (POW_STAGE_HV - 0.2)
	_beam(Vector3(t0.x, tr_y, t0.y), Vector3(t1.x, tr_y, t1.y), 0.22, POW_TRUSS)
	for i in 6:
		var l := t0.lerp(t1, (i + 0.5) / 6.0) + sd * 0.15
		var warm := i % 2 == 0
		var col := Color(1.0, 0.62, 0.25) if warm else POW_GREY.darkened(0.2)
		var keep := _mode
		_prism(_box_poly(Rect2(l.x - 0.12, l.y - 0.12, 0.24, 0.24)), tr_y - 0.45, tr_y - 0.12, col, POW_DARK,
				M_LAMP if warm else M_LAMP + 0.5, M_STONE)
		_mode = keep
	# The speakers at the front corners, on the ground beside the riser.
	for s: float in [-1.0, 1.0]:
		var p := sc + sd * (POW_STAGE_HU - 0.3) + sv * (s * (POW_STAGE_HV + 0.45))
		_pow_box(p, sd, 0.3, 0.3, g, g + 1.5, POW_RISER, POW_DARK)
		_pow_box(p + sd * 0.31, sd, 0.01, 0.2, g + 0.9, g + 1.3, POW_DARK.darkened(0.3), Color(0, 0, 0, 0))
	# The upright piano behind the pianist (band slot 1), its back to the saucer.
	var band: Array = plan["band"]
	var pp: Vector2 = band[1][0]
	_pow_box(pp - sd * 0.6, sd, 0.32, 0.75, top, top + 1.25, POW_PIANO, POW_PIANO.lightened(0.1))
	_pow_box(pp - sd * 0.25, sd, 0.1, 0.72, top + 0.7, top + 0.78, POW_KEYS, POW_KEYS)
	# The double bass beside the bassist (slot 0): a tall brown body on its spike, the neck up.
	var bp: Vector2 = band[0][0] + sv * 0.45 + sd * 0.1
	_pow_box(bp, sd, 0.12, 0.3, top + 0.15, top + 1.15, POW_BASS, POW_BASS.darkened(0.1))
	_beam(Vector3(bp.x, top + 1.1, bp.y), Vector3(bp.x, top + 1.85, bp.y), 0.07, POW_DARK, false)
	# The drum kit round the drummer (slot 2): the bass drum, a snare, two cymbals on stands.
	var dp: Vector2 = band[2][0]
	var bd := dp + sd * 0.7
	_g = top
	_disc(Vector3(bd.x, top + 0.3, bd.y) + n3 * 0.22, n3, 0.29, 10, POW_VALANCE)
	_pow_box(bd, sd, 0.2, 0.3, top, top + 0.6, POW_RED.darkened(0.3), POW_RED.darkened(0.3))
	_g = g
	var sn := dp + sd * 0.4 - sv * 0.4
	_pow_box(sn, sd, 0.18, 0.18, top + 0.5, top + 0.68, Color("#d9d6cf"), Color("#ecebe6"))
	for cy: Vector2 in [dp + sd * 0.5 + sv * 0.6, dp + sd * 0.3 - sv * 0.75]:
		_beam(Vector3(cy.x, top, cy.y), Vector3(cy.x, top + 1.1, cy.y), 0.04, POW_DARK, false)
		_pow_box(cy, sd, 0.25, 0.25, top + 1.1, top + 1.13, POW_BRASS, POW_BRASS)
	# The vibraphone in front of slot 3: a frame on legs, its gold bars on top.
	var vp: Vector2 = band[3][0] + sd * 0.55
	_pow_box(vp, sd, 0.3, 0.7, top + 0.78, top + 0.86, POW_BRASS, POW_BRASS.lightened(0.1))
	for s: float in [-1.0, 1.0]:
		var lg := vp + sv * (s * 0.6)
		_beam(Vector3(lg.x, top, lg.y), Vector3(lg.x, top + 0.78, lg.y), 0.05, POW_DARK, false)
	# Mic stands at the bass and the vibraphone.
	for m: Vector2 in [band[0][0] + sd * 0.45, band[3][0] + sd * 0.3 - sv * 0.7]:
		_beam(Vector3(m.x, top, m.y), Vector3(m.x, top + 1.45, m.y), 0.03, POW_DARK, false)


## One platform's canopy: a thin slab on X-shaped steel supports along its middle.
func _pow_canopy(f: Array) -> void:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	if hu < 20.0 or hv > 8.0:
		return
	var len := minf(POW_CANOPY, hu * 2.0 - 10.0)
	var floor_y: float = map.terrain_height(_o.x, _o.y) + 0.9
	var top := floor_y + 3.6
	var half := minf(hv + 0.6, 2.4)
	_prism(_rect(0.0, 0.0, len * 0.5, half), top, top + 0.22, POW_WHITE.darkened(0.06), POW_GREY.darkened(0.1), M_STONE, M_STONE)
	_soffit(_rect(0.0, 0.0, len * 0.5, half), top, POW_GREY)
	var n := maxi(2, roundi(len / POW_BAY))
	for k in n + 1:
		var u := -len * 0.5 + len * k / n
		var w := 0.9
		for s in [-1.0, 1.0]:
			var p0 := _w(u, -s * w)
			var p1 := _w(u, s * w)
			# The foot goes down into the platform's slab (it stands on the map's platform).
			_beam(Vector3(p0.x, floor_y - 1.0, p0.y), Vector3(p1.x, top, p1.y), 0.16, POW_DARK)


# Romanowicz and Szymaniak's stop of 1955-58 by the old stadium, renovated for Euro 2012: a low
# white ticket hall at street level south of the platforms, its platform-side end a curved white
# "sail", the passage under the tracks, and two long side platforms whose canopies have glazed
# wind walls over a red-and-white mosaic (the National Stadium's colours) and a perforated metal
# roof. Built from the hall's OSM outline and the two platforms' outlines; shapes from texts.


# --- Warszawa Stadion (the railway S3a, docs/landmarks/specs/stadion_pkp.md) ---------------

const STP_OSM := "Dworzec PKP Warszawa Stadion"
const STP_SAIL := Rect2(1385.5, -1322.5, 12.6, 4.2)   # where the hall's curved end lies (its OSM arc)
const STP_HALL_H := 3.9        # the glass walls' top over the plinth's foot
const STP_ROOF := 0.5          # the roof slab
const STP_EAVE := 0.8          # its overhang
const STP_SAIL_H := 8.2        # the sail's tips over the ground (over the roof's raised end)
const STP_RISE := 1.5          # how far the roof sweeps up towards the sail
var _stp_axis := Vector2.UP    # the hall's axis towards the sail (set by _stp_roof)
var _stp_lo := 0.0
var _stp_hi := 1.0
var _stp_g := 0.0
const STP_SAIL_DIP := 1.1      # how far its middle dips under the tips
const STP_SAIL_LEAN := 1.4     # how far its top leans out towards the platforms
const STP_CANOPY := 96.0       # each canopy's length from the platform's hall end
const STP_CANOPY_H := 3.8      # the canopy roof over the platform
const STP_PANEL := 2.0         # the mosaic's panels
const STP_WHITE := Color("#ecebe6")
const STP_GLASS := Color("#56707e")
const STP_RED := Color("#c4252b")
const STP_METAL := Color("#b3b7bb")
const STP_DARK := Color("#2d3034")
const STP_NEON := Color(1.0, 0.18, 0.22)


func _find_stadion_pkp() -> void:
	var q := _landmark(STP_OSM)
	if q.size() < 3:
		return
	_add_site("stadion_pkp", [_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER))])
	if sites.is_empty() or sites[-1]["key"] != "stadion_pkp":
		return
	sites[-1]["hall"] = q
	# The two side platforms north of the hall (their frames, nearest end first).
	var c := _centre(q)
	var plats: Array = []
	for pl in data.get("platforms", []):
		var p := _pts(pl["p"])
		if p.size() < 3:
			continue
		var f := _och_frame(_simplify(p, 0.3))
		var hu: float = f[3]
		var near := minf((f[0] + f[1] * hu).distance_to(c), (f[0] - f[1] * hu).distance_to(c))
		if near < 60.0 and hu > 40.0:
			plats.append(f)
	sites[-1]["platforms"] = plats


func _build_stadion_pkp(site: Dictionary) -> void:
	var q: PackedVector2Array = site["hall"]
	var c := _centre(q)
	var g := INF
	for p in q:
		g = minf(g, map.terrain_height(p.x, p.y))
	_g = g
	var none := Color(0, 0, 0, 0)
	var hall := _simplify(q, 0.15)
	if Geometry2D.is_polygon_clockwise(hall):
		hall.reverse()
	# The plinth, the glass walls with their mullions, the white roof slab on its overhang.
	_prism(hall, g - 0.6, g + 0.5, STP_WHITE.darkened(0.2), none, M_STONE)
	var keep := _mode
	_prism(hall, g + 0.5, g + STP_HALL_H, STP_GLASS, none, M_PAVILION)
	_mode = keep
	_mullions(hall, g + 0.5, g + STP_HALL_H, 1.8, 0.05, STP_DARK)
	var roof := _largest(Geometry2D.offset_polygon(hall, STP_EAVE, Geometry2D.JOIN_MITER))
	_stp_roof(hall, roof, g)
	_stp_sail(q, g)
	# STADION in red neon standing on the roof's low end, facing the game's camera.
	var o := BEHIND_FACE.normalized()
	var k := 0.68
	var at := c + o * 4.0
	signs.append(["STADION", Vector3(at.x, _stp_roof_y(at) + 0.05, at.y), Vector3(o.x, 0.0, o.y), k, STP_NEON])
	_collide(hall)
	var plats: Array = site.get("platforms", [])
	var pair_mid := Vector2.ZERO
	for f: Array in plats:
		pair_mid += (f[0] as Vector2) / plats.size()
	for f: Array in plats:
		_stp_canopy(f, c, pair_mid)


## The hall's roof (Mac photo check 2026-11-01: the flat slab read as a plain white box): one
## white slab that sweeps up towards the sail's end, STP_RISE over its length (a parabola), so the
## hall and the sail read as one form lifting towards the platforms. The glass rises with it as a
## clerestory; the slab in 2 m cells clipped to the eaves' outline, a fascia round its edge and a
## grey soffit under it.
func _stp_roof(hall: PackedVector2Array, roof: PackedVector2Array, g: float) -> void:
	var c := _centre(hall)
	var sail := STP_SAIL.get_center()
	_stp_axis = (sail - c).normalized()
	_stp_lo = INF
	_stp_hi = -INF
	for p in roof:
		_stp_lo = minf(_stp_lo, p.dot(_stp_axis))
		_stp_hi = maxf(_stp_hi, p.dot(_stp_axis))
	_stp_g = g
	var side := Vector2(-_stp_axis.y, _stp_axis.x)
	var s_lo := INF
	var s_hi := -INF
	for p in roof:
		s_lo = minf(s_lo, p.dot(side))
		s_hi = maxf(s_hi, p.dot(side))
	var nu := maxi(2, ceili((_stp_hi - _stp_lo) / 3.0))
	var nv := maxi(1, ceili((s_hi - s_lo) / 7.0))
	var top_col := STP_WHITE
	var under := STP_WHITE.darkened(0.25)
	_mode = M_STONE
	for i in nu:
		for j in nv:
			var u0 := lerpf(_stp_lo, _stp_hi, float(i) / nu)
			var u1 := lerpf(_stp_lo, _stp_hi, float(i + 1) / nu)
			var v0 := lerpf(s_lo, s_hi, float(j) / nv)
			var v1 := lerpf(s_lo, s_hi, float(j + 1) / nv)
			var cell := PackedVector2Array([_stp_axis * u0 + side * v0, _stp_axis * u1 + side * v0,
					_stp_axis * u1 + side * v1, _stp_axis * u0 + side * v1])
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(cell, roof):
				var idx := Geometry2D.triangulate_polygon(piece)
				for t in range(0, idx.size() - 2, 3):
					var tri: Array[Vector3] = []
					for m in 3:
						var p := piece[idx[t + m]]
						tri.append(Vector3(p.x, _stp_roof_y(p), p.y))
					var nrm := (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
					if nrm.y < 0.0:
						nrm = -nrm
					# Faint seams: every other cell a shade greyer, as the slab's panels read.
					var col := top_col if (i + j) % 2 == 0 else top_col.darkened(0.025)
					_tri(tri[0], tri[1], tri[2], nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
					var d := Vector3.DOWN * STP_ROOF
					_tri(tri[0] + d, tri[1] + d, tri[2] + d, -nrm, under, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	# The fascia round the slab's edge and the clerestory glass from the walls' top up to it.
	for ring in [[roof, STP_ROOF, STP_WHITE.darkened(0.08), M_STONE], [hall, -1.0, STP_GLASS, M_PAVILION]]:
		var poly: PackedVector2Array = ring[0]
		_mode = ring[3]
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var e := b - a
			var n := maxi(1, ceili(e.length() / 3.0))
			var out := Vector2(e.y, -e.x).normalized()
			if out.dot((a + b) * 0.5 - c) < 0.0:
				out = -out
			for k in n:
				var p0 := a + e * (float(k) / n)
				var p1 := a + e * (float(k + 1) / n)
				var y0 := _stp_roof_y(p0)
				var y1 := _stp_roof_y(p1)
				var lo0: float = y0 - float(ring[1]) if float(ring[1]) > 0.0 else g + STP_HALL_H
				var lo1: float = y1 - float(ring[1]) if float(ring[1]) > 0.0 else g + STP_HALL_H
				var top0: float = y0 if float(ring[1]) > 0.0 else y0 - STP_ROOF
				var top1: float = y1 if float(ring[1]) > 0.0 else y1 - STP_ROOF
				if top0 - lo0 < 0.02 and top1 - lo1 < 0.02:
					continue
				_quad(Vector3(p0.x, lo0, p0.y), Vector3(p1.x, lo1, p1.y), Vector3(p1.x, top1, p1.y),
						Vector3(p0.x, top0, p0.y), Vector3(out.x, 0.0, out.y), ring[2])
	_mode = M_STONE


## The roof's top over a point: STP_HALL_H + STP_ROOF at its far end, STP_RISE more at the sail's.
func _stp_roof_y(p: Vector2) -> float:
	var t := clampf((p.dot(_stp_axis) - _stp_lo) / maxf(_stp_hi - _stp_lo, 0.1), 0.0, 1.0)
	return _stp_g + STP_HALL_H + STP_ROOF + STP_RISE * t * t


## The sail: a curved white wall along the hall's concave end, its tips high, its middle lower,
## its top leaning out over the forecourt towards the platforms; both faces and the top edge.
func _stp_sail(q: PackedVector2Array, g: float) -> void:
	var arc := PackedVector2Array()
	for p in q:
		if STP_SAIL.has_point(p):
			arc.append(p)
	if arc.size() < 3:
		return
	arc = _simplify(arc, 0.12) if arc.size() > 8 else arc
	var a0 := arc[0]
	var a1 := arc[arc.size() - 1]
	var chord := a1 - a0
	var out := Vector2(-chord.y, chord.x).normalized()
	var mid := (a0 + a1) * 0.5
	if (_centre(q) - mid).dot(out) > 0.0:
		out = -out
	var n := arc.size()
	var top := PackedVector3Array()
	var foot := PackedVector3Array()
	for i in n:
		var t := float(i) / (n - 1)
		var e := (2.0 * t - 1.0) * (2.0 * t - 1.0)
		var h := STP_SAIL_H - STP_SAIL_DIP * (1.0 - e)
		var lean := out * STP_SAIL_LEAN * (0.6 + 0.4 * (1.0 - e))
		foot.append(Vector3(arc[i].x, g - 0.3, arc[i].y))
		top.append(Vector3(arc[i].x + lean.x, g + h, arc[i].y + lean.y))
	var d := Vector3(out.x, 0.0, out.y) * 0.22
	_mode = M_STONE
	for i in n - 1:
		var nrm := (top[i + 1] - foot[i]).cross(foot[i + 1] - foot[i]).normalized()
		if Vector2(nrm.x, nrm.z).dot(out) < 0.0:
			nrm = -nrm
		_quad(foot[i], foot[i + 1], top[i + 1], top[i], nrm, STP_WHITE)
		_quad(foot[i] - d, foot[i + 1] - d, top[i + 1] - d, top[i] - d, -nrm, STP_WHITE.darkened(0.12))
		_quad(top[i], top[i + 1], top[i + 1] - d, top[i] - d, Vector3.UP, STP_WHITE.lightened(0.05))


## One platform's canopy from its hall end: posts along the outer edge, the wind wall there (the
## red-and-white mosaic below, glass above), the perforated metal roof over the whole width, and
## the stair head down to the passage under the tracks at the hall end.
func _stp_canopy(f: Array, hall_c: Vector2, pair_mid: Vector2) -> void:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	if hv > 9.0:
		return
	# u runs from the hall end (-hu) along the platform; v = +1 is the outer side.
	if (_o + _a * hu).distance_to(hall_c) < (_o - _a * hu).distance_to(hall_c):
		_a = -_a
		_b = -_b
	# The outer side: away from the tracks between the two side platforms (the side facing the
	# pair's middle is the inner one).
	var other := -1.0 if (_w(0.0, 1.0) - _o).dot(pair_mid - _o) > 0.0 else 1.0
	var len := minf(STP_CANOPY, hu * 2.0 - 4.0)
	var u0 := -hu + 1.0
	var u1 := u0 + len
	var floor_y: float = map.terrain_height(_o.x, _o.y) + 0.9
	var top := floor_y + STP_CANOPY_H
	var none := Color(0, 0, 0, 0)
	var half := hv + 0.3
	var slab := PackedVector2Array([_w(u0, -half), _w(u1, -half), _w(u1, half), _w(u0, half)])
	_prism(slab, top, top + 0.25, STP_METAL.darkened(0.1), STP_METAL, M_STONE, M_STONE)
	_soffit(slab, top, STP_METAL.darkened(0.35))
	var v := other * (hv - 0.35)
	var n := maxi(2, roundi(len / 8.0))
	for k in n + 1:
		var u := u0 + 0.4 + (len - 0.8) * k / n
		_prism(_rect(u, v, 0.14, 0.14), floor_y - 1.0, top, STP_DARK, none, M_STONE)
	# The wind wall just inside the posts: the mosaic panels (two rows, chequered) facing the
	# tracks and out, glass from 2.4 m up to the roof.
	var vin := v - other * 0.2
	var nin := Vector3(_b.x, 0.0, _b.y) * -other
	var m := maxi(1, roundi(len / STP_PANEL))
	var e0 := _w(u0, vin)
	var e1 := _w(u1, vin)
	for face in 2:
		var vv := vin + (other * 0.12 if face == 1 else 0.0)
		var nf := nin if face == 0 else -nin
		for row in 2:
			var y0 := floor_y + 1.2 * row - (1.0 if row == 0 else 0.0)
			var y1 := floor_y + 1.2 * (row + 1)
			for k in m:
				var p0 := _w(u0 + len * k / m, vv)
				var p1 := _w(u0 + len * (k + 1) / m, vv)
				var col := STP_RED if (k + row) % 2 == 0 else STP_WHITE
				_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y), nf, col)
	_mode = M_STONE
	for s in [1.0, -1.0]:
		var nn: Vector3 = nin * float(s)
		_quad(Vector3(e0.x, floor_y + 2.4, e0.y), Vector3(e1.x, floor_y + 2.4, e1.y), Vector3(e1.x, top, e1.y), Vector3(e0.x, top, e0.y), nn, STP_GLASS.lightened(0.1))
	# The stair head at the hall end: a white box with a dark opening facing along the platform.
	var sh := _rect(u0 + 4.5, -other * 0.6, 3.5, 1.6)
	_prism(sh, floor_y - 1.0, floor_y + 2.6, STP_WHITE, STP_WHITE.darkened(0.05), M_STONE, M_STONE)
	var d0 := _w(u0 + 8.08, -other * 0.6 - 1.2)
	var d1 := _w(u0 + 8.08, -other * 0.6 + 1.2)
	var na := Vector3(_a.x, 0.0, _a.y)
	_quad(Vector3(d0.x, floor_y - 1.0, d0.y), Vector3(d1.x, floor_y - 1.0, d1.y), Vector3(d1.x, floor_y + 2.2, d1.y), Vector3(d0.x, floor_y + 2.2, d0.y), na, STP_DARK)
	_collide(sh)


# The main hall north of the tracks (1969, refitted for Euro 2012), from the Mac photo report
# docs/landmarks/photo-reports/wschodnia.md: a long glazed hall under a flat roof whose edge is a
# folded (zig-zag) concrete fascia, carried round the overhang on V-shaped steel struts, white-grey
# on the Kijowska front, pale green on the track side; WARSZAWA WSCHODNIA in white letters on the
# fascia. South-east of it the island platforms under long rust-brown roofs on a row of columns.
# Neither the hall nor its roofs were drawn before (no LoD2 model, OSM's outline is not a
# building): the corner was an empty forecourt by a bare yard. The hall's outline is OSM's; the
# heights are estimates from the photos (no LoD2 here).


# --- Warszawa Wschodnia (the railway S3e, docs/landmarks/specs/wschodnia.md) -----------------

const WSC_OSM := "Warszawa Wschodnia"
const WSC_UNDER := 9.8         # the roof's underside (the glass's top) over the plinth's foot
const WSC_TOP := 10.4          # the roof's top
# F's look check (2026-11-03): keep 10.4 m as the working roof edge, and make the folded eave and
# the repeated V supports more prominent: deeper, wider pleats that stand further out, thicker
# struts spread wider, one every 6 m.
const WSC_FOLD_DEEP := 2.3     # how far the folded fascia's points hang under the top
const WSC_FOLD := 3.6          # one pleat's width along the edge
const WSC_FOLD_OUT := 0.9      # how far each deep point stands out from the roof's edge
const WSC_EAVE := 3.2          # the overhang round the hall
const WSC_STRUT_STEP := 6.0    # one V every so many metres along a long front
const WSC_STRUT_W := 0.42      # a strut leg's thickness
const WSC_STRUT_SPREAD := 2.4  # how far each leg's head leans out along the front
const WSC_CANOPY_X := Vector2(1860.0, 2120.0)  # the platform roofs' run (the ortho)
## The two short suburban platforms east of the hall are roofed only part way (the ortho's
## rust roofs from about x 2020 to the frame's edge; F's look check: endpoints still to verify).
const WSC_SUBURBAN_X := Vector2(2020.0, 2160.0)
const WSC_EDGE_Z := -2043.0    # the map's cut on this side: no roof past it
const WSC_CANOPY_H := 4.4      # the platform roofs' top over the platform
const WSC_CANOPY_STEP := 6.0
const WSC_GLASS := Color("#5f7a88")
const WSC_FRAME := Color("#4a4f55")
const WSC_FASCIA := Color("#3b3e43")    # the dark roof edge the letters stand on
const WSC_ROOF := Color("#8f9296")
const WSC_SOFFIT := Color("#c9c7c0")
const WSC_GRANITE := Color("#8d8b86")
const WSC_STRUT_N := Color("#d9dcdc")   # white-grey (the Kijowska front, photo 1)
const WSC_STRUT_S := Color("#9cc38e")   # pale green (the track side, photo 4)
const WSC_RUST := Color("#8e5a44")      # the platform roofs (the ortho)
const WSC_POST := Color("#55524f")
const WSC_SIGN := Color(0.95, 0.96, 1.0)


func _find_wschodnia() -> void:
	var q := _landmark(WSC_OSM)
	if q.size() < 3:
		return
	var hall := _simplify(q, 0.6)
	if Geometry2D.is_polygon_clockwise(hall):
		hall.reverse()
	_add_site("wschodnia", [_largest(Geometry2D.offset_polygon(hall, WSC_EAVE + 0.8, Geometry2D.JOIN_MITER))])
	if sites.is_empty() or sites[-1]["key"] != "wschodnia":
		return
	sites[-1]["hall"] = hall
	# The long island platforms beside it, and the two short suburban ones further east, roofed
	# part way (F's look check, 2026-11-03).
	var near := Rect2(1650.0, -2070.0, 560.0, 300.0)
	var plats: Array = []
	for pl in data.get("platforms", []):
		if float(pl["h"]) < 0.5:
			continue
		var p := _pts(pl["p"])
		if p.size() < 4 or not near.intersects(_box_of([p])):
			continue
		var f := _och_frame(_simplify(p, 0.3))
		if float(f[3]) > 150.0:
			plats.append([p, f, WSC_CANOPY_X])
		elif float(f[3]) > 80.0 and _centre(p).x > WSC_SUBURBAN_X.x - 60.0:
			plats.append([p, f, WSC_SUBURBAN_X])
	sites[-1]["platforms"] = plats


func _build_wschodnia(site: Dictionary) -> void:
	var hall: PackedVector2Array = site["hall"]
	var g := _ground_under(hall)
	_g = g
	var none := Color(0, 0, 0, 0)
	var under := g + WSC_UNDER
	var top := g + WSC_TOP
	# The granite plinth, the glass walls lit from inside at night, their mullions and the
	# mezzanine's band.
	_prism(hall, g - 0.6, g + 0.4, WSC_GRANITE, none, M_STONE)
	var keep := _mode
	_prism(hall, g + 0.4, under, WSC_GLASS, none, M_PAVILION + 0.5)
	_mode = keep
	_mullions(hall, g + 0.4, under, 2.4, 0.05, WSC_FRAME)
	for i in hall.size():
		var a := hall[i]
		var b := hall[(i + 1) % hall.size()]
		if a.distance_to(b) < 1.0:
			continue
		var o := _out(hall, a, b) * 0.07
		_quad(Vector3(a.x + o.x, g + 4.4, a.y + o.y), Vector3(b.x + o.x, g + 4.4, b.y + o.y),
				Vector3(b.x + o.x, g + 4.75, b.y + o.y), Vector3(a.x + o.x, g + 4.75, a.y + o.y),
				Vector3(o.x, 0.0, o.y).normalized(), WSC_FRAME)
	# The roof: its top, the soffit under the overhang, the folded fascia round its edge.
	var roof := _simplify(_largest(Geometry2D.offset_polygon(hall, WSC_EAVE, Geometry2D.JOIN_MITER)), 0.8)
	if Geometry2D.is_polygon_clockwise(roof):
		roof.reverse()
	_mode = M_STONE
	_cap(roof, top, WSC_ROOF)
	_soffit(roof, under, WSC_SOFFIT)
	_wsc_fascia(roof, under, top)
	_wsc_roof_kit(hall, top)
	# The V struts round the overhang, and the letters on the track side's long front.
	var best := 0.0
	var front := Vector4.ZERO
	for i in hall.size():
		var a := hall[i]
		var b := hall[(i + 1) % hall.size()]
		var len := a.distance_to(b)
		var o := _out(hall, a, b)
		if len < 14.0:
			continue
		var col := WSC_STRUT_S if o.y > 0.0 else WSC_STRUT_N
		var d := (b - a) / len
		var n := maxi(1, floori(len / WSC_STRUT_STEP))
		for k in n:
			var c := a + d * len * (k + 0.5) / n + o * (WSC_EAVE - 0.9)
			# Each leg from its own foot (two legs from one point would share a face plane there).
			for s in [-1.0, 1.0]:
				var f0: Vector2 = c + d * 0.3 * float(s)
				var t: Vector2 = c + d * WSC_STRUT_SPREAD * float(s)
				_beam(Vector3(f0.x, g - 0.2, f0.y), Vector3(t.x, under + 0.05, t.y), WSC_STRUT_W, col)
			_prism(PackedVector2Array([c - d * 0.5 - o * 0.45, c + d * 0.5 - o * 0.45, c + d * 0.5 + o * 0.45,
					c - d * 0.5 + o * 0.45]), g - 0.3, g + 0.45, WSC_GRANITE, WSC_GRANITE.lightened(0.05), M_STONE, M_STONE)
		# The sign goes on the longest front facing the camera's side (south).
		if o.dot(BEHIND_FACE) > 0.3 and len > best:
			best = len
			front = Vector4(a.x, a.y, b.x, b.y)
	if best > 0.0:
		var a := Vector2(front.x, front.y)
		var b := Vector2(front.z, front.w)
		var o := _out(hall, a, b)
		var d := (b - a).normalized()
		var mid := (a + b) * 0.5 + o * (WSC_EAVE + 0.05)
		var k := 0.55
		var gap := 0.6
		var la: float = Neon.length_of("WARSZAWA") * k
		var lb: float = Neon.length_of("WSCHODNIA") * k
		var left := -(la + gap + lb) * 0.5
		# Text reads left to right from outside: +right is (out.z, -out.x) in plan.
		var right := Vector2(o.y, -o.x)
		if right.dot(d) < 0.0:
			d = -d
		# A flat board over the pleats for the letters (the real ones stand on a plain band).
		var y := top - 1.4
		var half := (la + gap + lb) * 0.5 + 1.0
		var bo := mid + o * (WSC_FOLD_OUT + 0.08 - 0.05)
		_prism(PackedVector2Array([bo - right * half, bo + right * half, bo + right * half + o * 0.12,
				bo - right * half + o * 0.12]), top - WSC_FOLD_DEEP - 0.1, top + 0.05, WSC_FASCIA.darkened(0.15), WSC_FASCIA, M_STONE, M_STONE)
		mid = bo + o * 0.12
		var pa := mid + right * (left + la * 0.5)
		var pb := mid + right * (left + la + gap + lb * 0.5)
		signs.append(["WARSZAWA", Vector3(pa.x, y, pa.y), Vector3(o.x, 0.0, o.y), k, WSC_SIGN])
		signs.append(["WSCHODNIA", Vector3(pb.x, y, pb.y), Vector3(o.x, 0.0, o.y), k, WSC_SIGN])
	_collide(hall)
	for pf: Array in site.get("platforms", []):
		_wsc_canopy(pf[0], pf[1], pf[2])


## The folded fascia: round the roof's edge a vertical plate whose foot zig-zags, its deep points
## standing WSC_FOLD_OUT out, so the edge reads as concrete pleats (photo 1); both faces, and the
## roof's top carried out over the pleats.
func _wsc_fascia(roof: PackedVector2Array, under: float, top: float) -> void:
	_mode = M_STONE
	for i in roof.size():
		var a := roof[i]
		var b := roof[(i + 1) % roof.size()]
		var len := a.distance_to(b)
		if len < 0.3:
			continue
		var d := (b - a) / len
		var o := _out(roof, a, b)
		var n := maxi(2, roundi(len / WSC_FOLD))
		if n % 2 == 1:
			n += 1  # both corners shallow, so neighbouring edges meet
		var pts: Array[Vector2] = []
		var bots: Array[float] = []
		var base: Array[Vector2] = []
		for k in n + 1:
			var p := a + d * len * k / n
			var deep := k % 2 == 1
			base.append(p)
			pts.append(p + o * (WSC_FOLD_OUT if deep else 0.0))
			bots.append(top - (WSC_FOLD_DEEP if deep else (top - under)))
		for k in n:
			var p0: Vector2 = pts[k]
			var p1: Vector2 = pts[k + 1]
			var v0 := Vector3(p0.x, bots[k], p0.y)
			var v1 := Vector3(p1.x, bots[k + 1], p1.y)
			var t0 := Vector3(p0.x, top, p0.y)
			var t1 := Vector3(p1.x, top, p1.y)
			var e := p1 - p0
			var nrm := Vector2(e.y, -e.x).normalized()
			if nrm.dot(o) < 0.0:
				nrm = -nrm
			var n3 := Vector3(nrm.x, 0.0, nrm.y)
			# Alternate pleats a shade apart, as the folds catch the light.
			var col := WSC_FASCIA if k % 2 == 0 else WSC_FASCIA.lightened(0.22)
			_quad(v0, v1, t1, t0, n3, col)
			_quad(v0, v1, t1, t0, -n3, WSC_SOFFIT.darkened(0.15))
			# The top over the pleat, out from the roof's edge.
			var b0: Vector2 = base[k]
			var b1: Vector2 = base[k + 1]
			if p0.distance_to(b0) > 0.01:
				_tri(Vector3(b0.x, top, b0.y), Vector3(b1.x, top, b1.y), t0, Vector3.UP, WSC_ROOF,
						Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			if p1.distance_to(b1) > 0.01:
				_tri(Vector3(b0.x, top, b0.y), Vector3(b1.x, top, b1.y), t1, Vector3.UP, WSC_ROOF,
						Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The roof's kit: three glazed ridge lights along the hall (the lattice roof's glazed strips
## seen from inside, photos 2-3) and a few plant boxes.
func _wsc_roof_kit(hall: PackedVector2Array, top: float) -> void:
	var f := _och_frame(hall)
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	var none := Color(0, 0, 0, 0)
	var inner := _largest(Geometry2D.offset_polygon(hall, -3.0))
	if inner.size() < 3:
		inner = hall
	for v in [-0.35, 0.0, 0.35]:
		var strip := _rect(0.0, hv * float(v), hu - 8.0, 1.1)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(strip, inner):
			if absf(_area(piece)) < 12.0:
				continue
			var keep := _mode
			_prism(piece, top, top + 0.7, WSC_GLASS.lightened(0.15), WSC_GLASS.lightened(0.3), M_PAVILION + 0.5, M_STONE)
			_mode = keep
	for u in [-0.55, -0.15, 0.3, 0.6]:
		var c := _w(hu * float(u), hv * 0.62)
		if Geometry2D.is_point_in_polygon(c, hall):
			_prism(_rect(hu * float(u), hv * 0.62, 1.8, 1.2), top, top + 1.4, Color("#a9acaf"), Color("#b8babc"), M_STONE, M_STONE)


## One island platform's roof over its run inside `run_x` (WSC_CANOPY_X, WSC_SUBURBAN_X): a rust-brown slab following the
## platform's edges (cross-sections every WSC_CANOPY_STEP m), on a row of columns down its middle,
## a lamp strip under it.
func _wsc_canopy(p: PackedVector2Array, f: Array, run_x: Vector2) -> void:
	_o = f[0]
	_a = f[1]
	_b = f[2]
	var hu: float = f[3]
	var hv: float = f[4]
	var floor_y: float = map.terrain_height(_o.x, _o.y) + 0.9
	var top := floor_y + WSC_CANOPY_H
	var low := top - 0.35
	# The cross-sections: the platform's v extent at each step (none where it is too narrow or
	# outside the roofs' run).
	var secs: Array = []
	var u := -hu + 2.0
	while u <= hu - 2.0:
		var strip := _rect(u, 0.0, 0.4, hv + 6.0)
		var lo := INF
		var hi := -INF
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(strip, p):
			for q in piece:
				var l := _local(q)
				lo = minf(lo, l.y)
				hi = maxf(hi, l.y)
		var mid := _w(u, (lo + hi) * 0.5)
		if hi - lo > 3.5 and hi - lo < 16.0 and mid.x >= run_x.x and mid.x <= run_x.y and mid.y > WSC_EDGE_Z:
			secs.append(Vector3(u, lo + 0.35, hi - 0.35))
		else:
			secs.append(Vector3.INF)
		u += WSC_CANOPY_STEP
	var under := WSC_RUST.lightened(0.35)
	var edge := WSC_RUST.darkened(0.2)
	var n_post := 0
	_mode = M_STONE
	for k in secs.size() - 1:
		if not _wsc_on(secs, k) or not _wsc_on(secs, k + 1):
			continue
		var s0: Vector3 = secs[k]
		var s1: Vector3 = secs[k + 1]
		var a0 := _w(s0.x, s0.y)
		var a1 := _w(s1.x, s1.y)
		var b0 := _w(s0.x, s0.z)
		var b1 := _w(s1.x, s1.z)
		# The top: two shallow slopes from a ridge down the middle, so the roof catches the light.
		var r0 := _w(s0.x, (s0.y + s0.z) * 0.5)
		var r1 := _w(s1.x, (s1.y + s1.z) * 0.5)
		var ry := top + 0.25
		for side in [[a0, a1, WSC_RUST], [b0, b1, WSC_RUST.darkened(0.12)]]:
			var e0: Vector2 = side[0]
			var e1: Vector2 = side[1]
			var q0 := Vector3(e0.x, top, e0.y)
			var q1 := Vector3(e1.x, top, e1.y)
			var q2 := Vector3(r1.x, ry, r1.y)
			var q3 := Vector3(r0.x, ry, r0.y)
			var nrm := (q1 - q0).cross(q3 - q0).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			_quad(q0, q1, q2, q3, nrm, side[2])
		_quad(Vector3(a0.x, low, a0.y), Vector3(a1.x, low, a1.y), Vector3(b1.x, low, b1.y), Vector3(b0.x, low, b0.y), Vector3.DOWN, under)
		var nb := Vector3(_b.x, 0.0, _b.y)
		_quad(Vector3(a0.x, low, a0.y), Vector3(a1.x, low, a1.y), Vector3(a1.x, top, a1.y), Vector3(a0.x, top, a0.y), -nb, edge)
		_quad(Vector3(b0.x, low, b0.y), Vector3(b1.x, low, b1.y), Vector3(b1.x, top, b1.y), Vector3(b0.x, top, b0.y), nb, edge)
		# The run's ends.
		var na := Vector3(_a.x, 0.0, _a.y)
		if not _wsc_on(secs, k - 1):
			_quad(Vector3(a0.x, low, a0.y), Vector3(b0.x, low, b0.y), Vector3(b0.x, top, b0.y), Vector3(a0.x, top, a0.y), -na, edge)
		if not _wsc_on(secs, k + 2):
			_quad(Vector3(a1.x, low, a1.y), Vector3(b1.x, low, b1.y), Vector3(b1.x, top, b1.y), Vector3(a1.x, top, a1.y), na, edge)
		# The lamp strip down the middle (glows at night) and a column every other step.
		var m0 := (s0.y + s0.z) * 0.5
		var m1 := (s1.y + s1.z) * 0.5
		var keep := _mode
		_mode = M_LAMP
		var l0 := _w(s0.x + 0.5, m0 - 0.15)
		var l1 := _w(s1.x - 0.5, m1 - 0.15)
		var l2 := _w(s1.x - 0.5, m1 + 0.15)
		var l3 := _w(s0.x + 0.5, m0 + 0.15)
		var ly := low - 0.03
		_quad(Vector3(l0.x, ly, l0.y), Vector3(l1.x, ly, l1.y), Vector3(l2.x, ly, l2.y), Vector3(l3.x, ly, l3.y), Vector3.DOWN, Color(1.0, 0.93, 0.78))
		_mode = keep
		if n_post % 2 == 0:
			_prism(_rect(s0.x + WSC_CANOPY_STEP * 0.5, (m0 + m1) * 0.5, 0.2, 0.2), floor_y - 0.3, low, WSC_POST, Color(0, 0, 0, 0), M_STONE)
		n_post += 1


## Whether cross-section k of a platform roof exists (inside the list and under the roof's run).
func _wsc_on(secs: Array, k: int) -> bool:
	return k >= 0 and k < secs.size() and (secs[k] as Vector3).is_finite()


# OpenStreetMap maps the bar barges moored along the Vistula boulevards as buildings of kind
# "boat" (and the houseboats in the harbour on the right bank as "houseboat"), with no height:
# the builder drew them as 14 m office blocks standing in the water. Here each becomes a moored
# barge on its outline's oriented box: a steel hull with raked ends and an antifouling band, a
# timber deck behind a low bulwark, a glazed deckhouse with a sun terrace on its roof, bars,
# umbrellas over tables, festoons of warm bulbs on posts, a flag, and a gangway to the bank. The
# signed ones carry parody names in neon (no real venue's name on a sign or a card).


# --- Warszawa Śródmieście (the railway S3b, docs/landmarks/specs/srodmiescie.md) --------------

const SRD_OSM := "PKP Warszawa Śródmieście"
const SRD_GLASS_H := 4.4       # the glass hall over the ground
const SRD_TOP := 6.9           # the fascia's top (the OSM height is 7 m)
const SRD_OVER := 0.7          # the fascia's overhang past the glass
const SRD_STONE := Color("#dcd8cd")
const SRD_PLINTH := Color("#4a4b4d")
const SRD_GLASS := Color("#4f6a78")
const SRD_DARK := Color("#2a2c2f")
const SRD_NEON := Color(0.25, 0.75, 1.0)


func _find_srodmiescie() -> void:
	var halls: Array = []
	for l in data.get("landmarks", []):
		if l["name"] == SRD_OSM:
			var q := _pts(l["p"])
			if q.size() >= 3:
				halls.append(_simplify(q, 0.3))
	if halls.is_empty():
		return
	var zones: Array = []
	for q: PackedVector2Array in halls:
		zones.append(_largest(Geometry2D.offset_polygon(q, 1.5, Geometry2D.JOIN_MITER)))
	_add_site("srodmiescie", zones)
	if not sites.is_empty() and sites[-1]["key"] == "srodmiescie":
		sites[-1]["halls"] = halls


func _build_srodmiescie(site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	for q: PackedVector2Array in site["halls"]:
		var hall := q.duplicate()
		if Geometry2D.is_polygon_clockwise(hall):
			hall.reverse()
		var g := INF
		for p in hall:
			g = minf(g, map.terrain_height(p.x, p.y))
		_g = g
		_prism(hall, g - 0.6, g + 0.4, SRD_PLINTH, none, M_STONE)
		var keep := _mode
		_prism(hall, g + 0.4, g + SRD_GLASS_H, SRD_GLASS, none, M_PAVILION)
		_mode = keep
		_mullions(hall, g + 0.4, g + SRD_GLASS_H, 1.6, 0.05, SRD_DARK)
		var top := _largest(Geometry2D.offset_polygon(hall, SRD_OVER, Geometry2D.JOIN_MITER))
		_prism(top, g + SRD_GLASS_H, g + SRD_TOP, SRD_STONE, SRD_STONE.darkened(0.1), M_STONE, M_STONE)
		_soffit(top, g + SRD_GLASS_H, SRD_STONE.darkened(0.3))
		# The name on the middle of the long side the game's camera sees.
		var f := _och_frame(hall)
		var side: Vector2 = f[2]
		if side.dot(BEHIND_FACE) < 0.0:
			side = -side
		var at: Vector2 = f[0] + side * (float(f[4]) + SRD_OVER)
		signs.append(["ŚRÓDMIEŚCIE", Vector3(at.x, g + SRD_GLASS_H + 0.55, at.y), Vector3(side.x, 0.0, side.y), 0.5, SRD_NEON])
		_collide(hall)

## The WKD commuter line's two stops on the map, built from F's Mac photo gather (Commons photos
## and the GUGiK orthophoto, 2026-11-02). Śródmieście WKD, the terminus in an open cutting by the
## Aleje: above ground only two free-standing concrete "propellers", two long tapering wings on
## one raked wedge pier and a slim post, over the stairs down; a white parapet box round each
## stair, the name board on the west one. Ochota WKD, in the cross-city cutting by Plac Zawiszy:
## a heavy concrete slab on V-shaped legs over the island platform (OpenStreetMap maps the slab
## as a 5 m "retail" box, which the site replaces), blue benches, a stair up at the west end.
## The board shows the place name, and the logo is two plain arrows: no operator's brand.


# --- The WKD stations (the railway S3c-e, docs/landmarks/photo-reports/wkd_*.md) -------------

## The propellers' pier spots and which side the cutting lies on (+1: the frame's +v, south).
const WKD_SRD := [[Vector2(-1722.0, 728.0), 1.0], [Vector2(-1632.0, 711.0), -1.0]]
const WKD_SRD_A := Vector2(0.945, -0.327)  # along the cutting (its rails), east-north-east
const WKD_WING := 9.6           # the hub to a wing's tip
const WKD_WING_S := [0.0, 0.2, 0.4, 0.6, 0.75, 0.88, 0.96, 1.0]   # sections along a wing (of WKD_WING)
const WKD_WING_HW := [2.0, 1.75, 1.5, 1.25, 1.05, 0.85, 0.6, 0.25]  # their half widths: a rounded tip
const WKD_SLAB_Y := 4.0         # the slab's top over the walk at the hub; the tips rise 0.45 m
const WKD_CONCRETE := Color("#a39a8d")
const WKD_UNDER := Color("#7e766b")
const WKD_EDGE := Color("#b9b1a4")
const WKD_PARAPET := Color("#e6e4df")
const WKD_STAIR := Color("#3c3d3f")
const WKD_BOARD := Color("#3a3c40")
const WKD_RED := Color("#d22a2f")
const WKD_BLUE := Color("#2a4f9e")
const WKD_SIGN := Color(0.92, 0.95, 1.0)
## Ochota WKD: the slab's frame along the platform (OSM's island platform between the two tracks).
const WKD_OCH_O := Vector2(-2355.1, 951.2)
const WKD_OCH_A := Vector2(0.9455, -0.3253)
const WKD_OCH_HU := 24.5        # the slab's half length
const WKD_OCH_HV := 3.3         # its half width (the platform is 5.4 m wide)
const WKD_OCH_CLEAR := 3.5      # the platform's top to the slab's underside
const WKD_OCH_SLAB := 0.65
const WKD_OCH_GREY := Color("#9e9a92")
const WKD_OCH_TOP := Color("#857866")   # brown on the orthophoto
const WKD_OCH_EDGE := Color("#8b4a3a")  # the platform's red-brown edge strip
const WKD_OCH_BENCH := Color("#2f5e9e")


func _find_wkd() -> void:
	var zones: Array = []
	for p: Array in WKD_SRD:
		_wkd_srd_frame(p)
		zones.append(_rect(0.0, 0.0, WKD_WING + 0.6, 3.2))
	_add_site("wkd_srodmiescie", zones)
	_wkd_och_frame()
	# The zone holds the mapped slab's middle (the 5 m box over the platform) and the stair.
	_add_site("wkd_ochota", [_rect(-2.0, 0.0, WKD_OCH_HU + 10.0, WKD_OCH_HV + 0.5)])


## A propeller's frame: the pier spot, u along the cutting, +v towards the cutting.
func _wkd_srd_frame(p: Array) -> void:
	_o = p[0]
	_a = WKD_SRD_A
	_b = Vector2(-_a.y, _a.x) * float(p[1])


func _wkd_och_frame() -> void:
	_o = WKD_OCH_O
	_a = WKD_OCH_A
	_b = Vector2(-_a.y, _a.x)


func _build_wkd_srodmiescie(_site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	for k in WKD_SRD.size():
		var p: Array = WKD_SRD[k]
		_wkd_srd_frame(p)
		var g := -INF
		for q in [_w(-2.0, -2.5), _w(2.0, -2.5), _w(0.0, 0.0)]:
			g = maxf(g, map.terrain_height(q.x, q.y))
		_g = g
		var top := g + WKD_SLAB_Y
		# The parapet box round the stair: white, waist high, open at the east end where the
		# stair starts; the dark well inside with its steps.
		var hu := 3.6
		var hv := 1.7
		_lbox(-hu, 0.0, 0.12, hv, g - 0.5, g + 1.05, WKD_PARAPET, M_STONE, WKD_PARAPET)
		_lbox(0.0, -hv, hu, 0.12, g - 0.5, g + 1.05, WKD_PARAPET, M_STONE, WKD_PARAPET)
		_lbox(0.0, hv, hu, 0.12, g - 0.5, g + 1.05, WKD_PARAPET, M_STONE, WKD_PARAPET)
		_mode = M_STONE
		_cap(_rect(0.0, 0.0, hu - 0.12, hv - 0.12), g + 0.04, WKD_STAIR)
		for s in 6:
			var u := hu - 0.9 - s * 1.05
			_cap(_rect(u, 0.0, 0.08, hv - 0.2), g + 0.06, WKD_STAIR.lightened(0.25))
		_collide(_rect(0.0, 0.0, hu + 0.12, hv + 0.12))
		# The raked wedge pier on the far side from the cutting, wider at the top, and the slim
		# post under the other wing.
		var foot := _rect(-1.5, -2.5, 0.3, 0.3)
		var head := _rect(-1.0, -2.5, 0.95, 0.3)
		_mode = M_STONE
		_frustum(foot, g - 0.5, head, top - 0.4, WKD_CONCRETE.darkened(0.06))
		_prism(_circle(_w(6.2, -0.6 + 0.5 * 6.2 / WKD_WING), 0.13, 6), g - 0.5, top - 0.3, WKD_EDGE, none, M_STONE)
		_collide(_rect(-1.25, -2.5, 0.6, 0.35))
		_wkd_wings(top)
		# The logo on the pier's walk side: a white octagon, a red arrow over a blue one.
		_wkd_logo(_w(-1.25, -2.5) - _b * 0.33, g + 2.5, -_b, 0.5)
		# The west one carries the name board, on its slab on the side the camera sees.
		if k == 0:
			var face := _b if _b.dot(BEHIND_FACE) > 0.0 else -_b
			var sv := 0.3 * signf(face.dot(_b))
			var word := "ŚRÓDMIEŚCIE"
			_lbox(-4.3, sv, 3.6, 0.08, top - 0.05, top + 0.75, WKD_BOARD, M_STONE, WKD_BOARD)
			var at := _w(-4.3, sv) + face * 0.1
			var size := minf(0.32, 6.6 / Neon.length_of(word))
			signs.append([word, Vector3(at.x, top + 0.12, at.y), Vector3(face.x, 0.0, face.y), size, WKD_SIGN])


## The two wings as one slab: tapering to rounded tips, the tips raised, thin at the edge and
## thicker at the hub; the wings set off the axis in opposite ways (a propeller in plan).
func _wkd_wings(top: float) -> void:
	var secs: Array = []   # [u, v centre, half width, top y, bottom y]
	var n: int = WKD_WING_S.size()
	for i in range(n - 1, -1, -1):
		secs.append(_wkd_sec(-1.0, i, top))
	for i in range(1, n):
		secs.append(_wkd_sec(1.0, i, top))
	var keep := _mode
	_mode = M_STONE
	var corner := func(s: Array, side: float, up: bool) -> Vector3:
		var q := _w(float(s[0]), float(s[1]) + float(s[2]) * side)
		return Vector3(q.x, float(s[3]) if up else float(s[4]), q.y)
	for i in secs.size() - 1:
		var s0: Array = secs[i]
		var s1: Array = secs[i + 1]
		var l0: Vector3 = corner.call(s0, -1.0, true)
		var r0: Vector3 = corner.call(s0, 1.0, true)
		var l1: Vector3 = corner.call(s1, -1.0, true)
		var r1: Vector3 = corner.call(s1, 1.0, true)
		var lb0: Vector3 = corner.call(s0, -1.0, false)
		var rb0: Vector3 = corner.call(s0, 1.0, false)
		var lb1: Vector3 = corner.call(s1, -1.0, false)
		var rb1: Vector3 = corner.call(s1, 1.0, false)
		_wkd_face(l0, r0, r1, l1, Vector3.UP, WKD_CONCRETE)
		_wkd_face(lb0, rb0, rb1, lb1, Vector3.DOWN, WKD_UNDER)
		var mid := (l0 + r0 + l1 + r1) * 0.25
		_wkd_face(l0, l1, lb1, lb0, l0 - mid, WKD_EDGE)
		_wkd_face(r0, r1, rb1, rb0, r0 - mid, WKD_EDGE)
	for e in [0, secs.size() - 1]:
		var s: Array = secs[e]
		var out := _a * signf(float(s[0]))
		_wkd_face(corner.call(s, -1.0, true), corner.call(s, 1.0, true), corner.call(s, 1.0, false),
				corner.call(s, -1.0, false), Vector3(out.x, 0.0, out.y), WKD_EDGE)
	_mode = keep


## A wing's section i on the side `dir` (-1 west, +1 east).
func _wkd_sec(dir: float, i: int, top: float) -> Array:
	var s: float = WKD_WING_S[i]
	var y := top + 0.45 * s * s
	return [dir * s * WKD_WING, -0.6 + 0.5 * s * dir, float(WKD_WING_HW[i]), y, y - lerpf(0.55, 0.2, s)]


## A quad whose normal is its own geometry's, turned to the side `toward` points to.
func _wkd_face(a: Vector3, b: Vector3, c: Vector3, d: Vector3, toward: Vector3, col: Color) -> void:
	var n := (c - a).cross(d - b)
	if n.length() < 1e-6:
		return
	n = n.normalized()
	if n.dot(toward) < 0.0:
		n = -n
	_quad(a, b, c, d, n, col)


## The logo plate: a white octagon of radius r facing `out` with its middle at (c, y), a red arrow
## pointing one way over a blue one pointing back.
func _wkd_logo(c: Vector2, y: float, out: Vector2, r: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var n := Vector3(out.x, 0.0, out.y).normalized()
	var side := Vector3(-n.z, 0.0, n.x)
	var o := Vector3(c.x, y, c.y) + n * 0.03
	var at := func(x: float, h: float, lift: float) -> Vector3:
		return o + side * x + Vector3.UP * h + n * lift
	var ring: Array[Vector3] = []
	for k in 8:
		var t := TAU * (k + 0.5) / 8.0
		ring.append(at.call(cos(t) * r, sin(t) * r, 0.0))
	for k in range(1, 7):
		_tri(ring[0], ring[k], ring[k + 1], n, Color.WHITE, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	for arrow: Array in [[1.0, 0.28, WKD_RED], [-1.0, -0.28, WKD_BLUE]]:
		var d: float = arrow[0]
		var h: float = float(arrow[1]) * r
		var col: Color = arrow[2]
		var w := 0.09 * r
		_quad(at.call(-0.55 * r * d, h - w, 0.02), at.call(0.15 * r * d, h - w, 0.02),
				at.call(0.15 * r * d, h + w, 0.02), at.call(-0.55 * r * d, h + w, 0.02), n, col)
		_tri(at.call(0.15 * r * d, h - 0.22 * r, 0.02), at.call(0.6 * r * d, h, 0.02), at.call(0.15 * r * d, h + 0.22 * r, 0.02),
				n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = keep


func _build_wkd_ochota(_site: Dictionary) -> void:
	_wkd_och_frame()
	# The platform's top as map_builder draws it (its lowest corner + 0.9 + 0.1).
	var ground := INF
	for a in data.get("platforms", []):
		var q := _pts(a["p"])
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(_o, q):
			for p in q:
				ground = minf(ground, map.terrain_height(p.x, p.y))
	if ground == INF:
		ground = _ground_under(_rect(0.0, 0.0, 20.0, 2.0))
	_g = ground
	var pt := ground + 1.0
	var under := pt + WKD_OCH_CLEAR
	var top := under + WKD_OCH_SLAB
	var none := Color(0, 0, 0, 0)
	# The slab: rough grey edges, brown on top, darker underneath.
	var slab := _rect(0.0, 0.0, WKD_OCH_HU, WKD_OCH_HV)
	_prism(slab, under, top, WKD_OCH_GREY, WKD_OCH_TOP, M_STONE, M_STONE)
	_soffit(slab, under, WKD_OCH_GREY.darkened(0.3))
	# The V legs along the platform's middle every 8 m: two raked legs meeting at the floor
	# (their feet down in the platform, so they stand on its ground).
	var u := -20.0
	while u <= 20.5:
		for d: float in [-1.0, 1.0]:
			_mode = M_STONE
			_frustum(_rect(u + d * 0.12, 0.0, 0.14, 0.2), ground, _rect(u + d * 0.78, 0.0, 0.17, 0.22), under,
					WKD_OCH_GREY.lightened(0.05))
		u += 8.0
	# The red-brown edge strips down both sides of the platform, blue benches between the legs.
	_mode = M_STONE
	for v: float in [-2.35, 2.35]:
		_cap(_rect(0.0, v, 25.0, 0.2), pt + 0.03, WKD_OCH_EDGE)
	for b: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		_lbox(b, 0.0, 0.9, 0.22, ground, pt + 0.45, WKD_OCH_BENCH, M_STONE, WKD_OCH_BENCH.lightened(0.1))
	# The blue timetable board on two posts.
	_lbox(4.0, 0.0, 0.6, 0.05, pt + 1.0, pt + 2.1, WKD_OCH_BENCH, M_STONE, WKD_OCH_BENCH)
	for s: float in [-0.5, 0.5]:
		_lbox(4.0 + s, 0.0, 0.04, 0.04, ground, pt + 1.0, WKD_BOARD, M_STONE, none)
	# The stair up from the platform's west end to Al. Jerozolimskie and Towarowa: a flight of
	# 0.17 m steps between two low walls, rising west to the street.
	var street: float = map.terrain_height(_w(-36.0, 3.0).x, _w(-36.0, 3.0).y)
	var rise := maxf(street - pt, 1.0)
	var steps := clampi(ceili(rise / 0.17), 6, 40)
	var tread := 0.3
	var u0 := -WKD_OCH_HU - 1.5
	for s in steps:
		var y1 := pt + rise * float(s + 1) / steps
		var ua := u0 - s * tread
		var ring := PackedVector2Array([_w(ua, -1.2), _w(ua - tread, -1.2), _w(ua - tread, 1.2), _w(ua, 1.2)])
		_prism(ring, ground, y1, WKD_OCH_GREY.darkened(0.15), WKD_OCH_GREY.lightened(0.1), M_STONE, M_STONE)
	var u1 := u0 - steps * tread
	for v: float in [-1.35, 1.35]:
		var wall := PackedVector2Array([_w(u0, v - 0.15), _w(u1, v - 0.15), _w(u1, v + 0.15), _w(u0, v + 0.15)])
		_prism(wall, ground, pt + rise + 1.0, WKD_OCH_GREY, WKD_OCH_GREY.lightened(0.08), M_STONE, M_STONE)
	# A totem with the logo at the stair head.
	_lbox(u1 - 0.6, 1.9, 0.12, 0.12, ground, pt + rise + 2.6, WKD_BOARD, M_STONE, WKD_BOARD)
	var face := _b if _b.dot(BEHIND_FACE) > 0.0 else -_b
	_wkd_logo(_w(u1 - 0.6, 1.9) + face * 0.12, pt + rise + 2.1, face, 0.45)
