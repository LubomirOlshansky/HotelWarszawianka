extends "res://scripts/landmarks/plac.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, the brick works: Norblin,
## Browary Warszawskie, Hala Koszyki, Elektrownia Powiśle. Moved as it was from the one big file.
## landmarks.gd is the class the game makes; every file of game/scripts/landmarks/ is one link of
## its base chain (facade_kit.gd, common.gd, then the areas in the order of landmarks.gd's `extends`
## chain), so code here may use this file, common.gd and the facade kit, never another area: a
## helper two areas need goes to common.gd.


# --- The brick works: Norblin, Browary Warszawskie, Hala Koszyki, Elektrownia Powiśle -------------

## F's ask (2026-11-01): the four old-industry-turned-hangout sites of the west and south as
## models (specs docs/landmarks/specs/norblin.md, browary.md, koszyki.md, elektrownia.md), each on
## its mapped outline: brick walls on a plinth with round-headed windows in rows and a cornice, and
## what makes each one itself. Norblin: glazed storeys over the restored halls and a chimney in the
## court; the Browary: the brewhouse (Warzelnia) and the villa in brick, the office blocks clad in
## warm grey with window bays, the brewery chimney; Koszyki: the market hall with its glass
## lantern; the power station: two big storeys of arches and two chimneys. No photos in the
## cloud: the Mac look check (BACKLOG) settles brick shade, storeys and the chimneys.
const WORKS_BRICK := Color("#9b4d39")
const WORKS_DARK := Color("#7d3b2c")
const WORKS_TRIM := Color("#d3c7ab")
const WORKS_PLINTH := Color("#6f6a63")
const WORKS_ROOF := Color("#5d6366")
const WORKS_GLASS := Color("#2f3a40")
const WORKS_TOP := Color("#9db4be")
const WORKS_MODERN := Color("#b3a894")
## Fabryka Norblina, rebuilt from the Mac's photo report (docs/landmarks/photo-reports/norblin.md,
## GUGiK ortho, 2026-11-02): the factory is the block between Łucka, Żelazna and Prosta that OSM
## maps as the office buildings "Plater" (east) and "Galwan" (west); the first pass stood on
## "Modsen" north of Łucka, the wrong block. Both outlines come with their courts carved out
## (tools/planted_trees.py COURTS). Their OSM height (50 m) is the glazed storeys' top.
const NORBLIN_BLOCKS := ["Plater", "Galwan"]
const NORBLIN_PT := Vector2(-2262.0, 190.0)
const NORBLIN_H := 50.0
const NORBLIN_SEDUM := Color("#7c8f55")   # the report's green sedum roofs (Browary's too)
const NORBLIN_EDGE := Color("#5e7444")    # the planted edge round them
const NORBLIN_PLANT := Color("#8b9094")   # roof plant rooms
## The garden terraces upstairs on the north-west block (report: x -2290..-2275, z 140..160 and
## x -2315..-2300, z 135..150; each pulled onto the roof when the outline lies a few metres off).
const NORBLIN_TERRACES := [Vector2(-2283.0, 150.0), Vector2(-2307.0, 146.0)]
## F's photos and look check (2026-11-03): the blocks' base is a tall copper (rust-orange)
## metal-clad wall, lit warm at night on the lane's side; over it dark office storeys with fine
## vertical fins, the top two set back with terraces; between the two blocks the covered passage
## under a glass roof (the ortho's glazed strip; its exact extent is still to verify); no chimney.
const NORBLIN_BASE := 12.0
const NORBLIN_COPPER := Color("#a2552f")
const NORBLIN_DARK := Color("#38424a")    # the office storeys' glass
const NORBLIN_FIN := Color("#7c766c")     # their fine grey-bronze fins
const NORBLIN_WHITE := Color("#ece9e2")   # the old works' white plaster
const NORBLIN_ZINC := Color("#4d5256")    # their dark grey standing-seam roofs
## The covered passage's centre line between Galwan and Plater, and its half width (the gap
## between the two outlines inside it is roofed).
const NORBLIN_PASSAGE := [Vector2(-2292.0, 136.0), Vector2(-2263.0, 199.0), 9.0]
## Where the old works stand (their centres): the white workshops between the blocks and Prosta.
const NORBLIN_OLD := Rect2(-2290.0, 185.0, 125.0, 50.0)
const NORBLIN_HALL := "Verit"
const NORBLIN_HALL_AT := Vector2(-2244.0, 242.0)
const BROWARY_NAMES := ["Warzelnia", "Laboratorium", "Biura przy Bramie", "Biura przy Warzelni", "Biura przy Willi", "Willa Schielego"]


func _find_works() -> void:
	var blocks: Array = []
	var nor_zone: Array = []
	for n: String in NORBLIN_BLOCKS:
		var q := _landmark_near(n, NORBLIN_PT, 200.0)
		if q.size() >= 3:
			# OSM traces every pilaster (Galwan has 130 corners): the walls go on the outline
			# simplified to 1.2 m (the court notches' corners stay).
			var simple := _simplify(q, 1.2)
			blocks.append(simple if simple.size() >= 3 else q)
			# The court notch can take the outline's centre out of it: the hull keeps the
			# plain block replaced (landmark pitfalls, Piano House).
			nor_zone.append(q)
			nor_zone.append(Geometry2D.convex_hull(q))
	# The old works round the open lane (F's photos, 2026-11-03): the white one- and two-storey
	# workshops and houses between the blocks and Prosta, and the long low glazed hall on Prosta
	# ("Verit" in OSM), all generic boxes before.
	var olds: Array = []
	for bld in data["buildings"]:
		if float(bld["mh"]) > 0.5 or float(bld["h"]) > 8.0:
			continue
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		var hall: bool = bld.get("name", "") == NORBLIN_HALL and c.distance_to(NORBLIN_HALL_AT) < 10.0
		if hall or (NORBLIN_OLD.has_point(c) and bld.get("name", "") == ""):
			olds.append([_simplify(q, 0.4), hall])
			nor_zone.append(q)
	if not blocks.is_empty():
		_add_site("norblin", nor_zone)
		if sites[-1]["key"] == "norblin":
			sites[-1]["blocks"] = blocks
			sites[-1]["olds"] = olds
	var rings: Array = []
	var roles: Array = []
	for n: String in BROWARY_NAMES:
		var q := _landmark_near(n, Vector2(-2500.0, -100.0), 200.0)
		if q.size() >= 3:
			rings.append(q)
			roles.append(n)
	if not rings.is_empty():
		_add_site("browary", rings)
		if sites[-1]["key"] == "browary":
			sites[-1]["roles"] = roles
	var kosz := _landmark("Hala Koszyki")
	if kosz.size() >= 3:
		_add_site("koszyki", [kosz])
		if sites[-1]["key"] == "koszyki":
			sites[-1]["ring"] = kosz
	var rdyn := _landmark("Rotunda na Dynasach")
	if rdyn.size() >= 3:
		_add_site("rotunda_dynasy", [rdyn])
		if sites[-1]["key"] == "rotunda_dynasy":
			sites[-1]["ring"] = rdyn
	var elek := _landmark("Elektrownia Powiśle")
	if elek.size() >= 3:
		# The whole complex (2026-11-13): the T, the passage block, the office and the old wing.
		_add_site("elektrownia", [elek, _pts(ELEK_ATRIUM), _pts(ELEK_OFFICE), _pts(ELEK_WING)])
		if sites[-1]["key"] == "elektrownia":
			sites[-1]["ring"] = elek


## Brick walls round a ring from the ground to `h`: a plinth, a cornice, and round-headed windows
## in `rows` ([foot, spring, half width] above the ground) every `pitch` m along each wall longer
## than two bays (the windows are the walls' own panels, a few cm proud).
func _works_walls(ring: PackedVector2Array, h: float, brick: Color, rows: Array, pitch: float, glass := WORKS_GLASS) -> void:
	var g := _g
	var base := _grown(ring, 0.2)
	if base.size() >= 3:
		_prism(base, g - 0.6, g + 1.0, WORKS_PLINTH, WORKS_PLINTH, M_STONE, M_STONE)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var n := floori((length - 1.0) / pitch)
		if n < 2:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var t0 := (length - n * pitch) * 0.5 + pitch * 0.5
		for k in n:
			var at := a + e * (t0 + k * pitch)
			for r: Array in rows:
				_arch_win(at, e, out, float(r[2]), g + float(r[0]), g + float(r[1]), glass)
	var top := _grown(ring, 0.25)
	if top.size() >= 3:
		# The cornice's cap is the whole roof (one flat top, no second at the same height).
		_prism(ring, g - 0.6, g + h, brick, Color(0, 0, 0, 0), M_STONE, M_STONE)
		_prism(top, g + h - 0.9, g + h, WORKS_TRIM, WORKS_ROOF, M_STONE, M_STONE)
	else:
		_prism(ring, g - 0.6, g + h, brick, WORKS_ROOF, M_STONE, M_STONE)


## Glazed storeys on a ring: inset 1.8 m, curtain glass in `storeys` of 3.6 m from y, a flat roof.
func _works_top(ring: PackedVector2Array, y: float, storeys: int, roof := WORKS_ROOF) -> void:
	var inner := _grown(ring, -1.8)
	if inner.size() < 3:
		return
	var h := storeys * 3.6
	_mode = M_GLASS
	_prism(inner, y, y + h, WORKS_TOP, roof, M_GLASS, M_STONE)
	_parapet(inner, y + h, 0.7, WORKS_TRIM)
	_mode = M_STONE


## A brick chimney: a tapering ten-sided stack on a plinth, two pale bands and a cap near the top.
func _works_chimney(c: Vector2, h: float, r0: float, brick: Color) -> void:
	var g := _g
	var r1 := r0 * 0.62
	_mode = M_STONE
	_prism(_circle(c, r0 * 1.5, 10), g - 0.6, g + 1.4, WORKS_PLINTH, WORKS_PLINTH, M_STONE, M_STONE)
	_frustum(_circle(c, r0, 10), g + 1.4, _circle(c, r1, 10), g + h, brick)
	for band: float in [3.6, 6.4]:
		var y0 := g + h - band
		var t0 := (y0 - g - 1.4) / (h - 1.4)
		var t1 := (y0 + 1.0 - g - 1.4) / (h - 1.4)
		_frustum(_circle(c, lerpf(r0, r1, t0) + 0.06, 10), y0, _circle(c, lerpf(r0, r1, t1) + 0.06, 10), y0 + 1.0, WORKS_TRIM)
	_prism(_circle(c, r1 + 0.35, 10), g + h - 1.2, g + h, WORKS_TRIM.darkened(0.1), WORKS_ROOF, M_STONE, M_STONE)
	_collide(_circle(c, r0, 8))


## The ring's vertex farthest from `from`.
func _farthest(ring: PackedVector2Array, from: Vector2) -> Vector2:
	var best := ring[0]
	for q in ring:
		if q.distance_to(from) > best.distance_to(from):
			best = q
	return best


## The long axis of a ring: [the origin (its low corner), the unit direction along the longest edge,
## the unit across, the length, the width], for a lantern or ridge.
func _long_axis(ring: PackedVector2Array) -> Array:
	var a := Vector2.RIGHT
	var best := 0.0
	for i in ring.size():
		var d := ring[(i + 1) % ring.size()] - ring[i]
		if d.length() > best:
			best = d.length()
			a = d.normalized()
	var b := Vector2(-a.y, a.x)
	var u0 := INF
	var u1 := -INF
	var v0 := INF
	var v1 := -INF
	for q in ring:
		u0 = minf(u0, q.dot(a))
		u1 = maxf(u1, q.dot(a))
		v0 = minf(v0, q.dot(b))
		v1 = maxf(v1, q.dot(b))
	return [a * u0 + b * v0, a, b, u1 - u0, v1 - v0]


func _build_norblin(site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	var rings: Array = site["blocks"]
	for ring: PackedVector2Array in rings:
		_g = _ground_under(ring)
		var g := _g
		# The copper base: its panels' joints every 3 m, lit warm at night on the faces that look
		# onto the lane and Prosta (south), plain copper elsewhere; its top a dark ledge.
		var run := 0.0
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			var o := _out(ring, a, b)
			_mode = M_LAMP if o.y > 0.55 else M_STONE
			_wall(a, b, g - 0.6, g + NORBLIN_BASE, o, NORBLIN_COPPER, run)
			run += a.distance_to(b)
		_mullions(ring, g + 0.3, g + NORBLIN_BASE, 3.0, 0.04, NORBLIN_COPPER.darkened(0.2))
		_mode = M_STONE
		_cap(ring, g + NORBLIN_BASE, NORBLIN_ZINC)
		# The office storeys over it: dark glass behind fine fins, the top two set back further
		# behind a terrace with planters.
		var storeys := maxi(3, roundi((NORBLIN_H - NORBLIN_BASE) / 3.6))
		var inner := _grown(ring, -1.8)
		if inner.size() < 3:
			_collide(ring)
			continue
		var y1 := g + NORBLIN_BASE + (storeys - 2) * 3.6
		_prism(inner, g + NORBLIN_BASE, y1, NORBLIN_DARK, VARSO_DECK.darkened(0.25), M_GLASS, M_STONE)
		_mullions(inner, g + NORBLIN_BASE, y1, 1.2, 0.22, NORBLIN_FIN)
		_parapet(inner, y1, 1.0, NORBLIN_FIN.darkened(0.1))
		var top := _grown(ring, -5.0)
		var roof_y := y1
		if top.size() >= 3:
			roof_y = y1 + 7.2
			_prism(top, y1, roof_y, NORBLIN_DARK.lightened(0.06), none, M_GLASS)
			_mullions(top, y1, roof_y, 1.2, 0.18, NORBLIN_FIN)
			_norblin_planters(inner, y1)
		_mode = M_STONE
		_cap(top if top.size() >= 3 else inner, roof_y, NORBLIN_EDGE)
		_norblin_roof(inner, roof_y)
		_collide(ring)
	_norblin_passage(rings)
	for old: Array in site.get("olds", []):
		_norblin_old(old[0], old[1])
	_mode = M_STONE
	# No chimney: neither the ortho nor F's photos show one over the works.


## Planters with small trees on the set-back terrace: one in each long edge's middle of `ring`
## (the storeys' outline), 1.6 m in.
func _norblin_planters(ring: PackedVector2Array, y: float) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var l := a.distance_to(b)
		if l < 12.0:
			continue
		var o := _out(ring, a, b)
		var d := (b - a) / l
		for f: float in ([0.3, 0.7] if l > 30.0 else [0.5]):
			var p := a + d * l * f - o * 1.6
			_prism(PackedVector2Array([p - d * 2.0 - o * 0.5, p + d * 2.0 - o * 0.5, p + d * 2.0 + o * 0.5, p - d * 2.0 + o * 0.5]),
					y, y + 0.7, NORBLIN_PLANT, NORBLIN_EDGE, M_STONE, M_STONE)
			_varso_tree(p, y + 0.7, 2.6, 0.9)


## The covered passage between the two blocks: the gap between their outlines along
## NORBLIN_PASSAGE, under a flat glass roof at the base's top on light steel ribs.
func _norblin_passage(rings: Array) -> void:
	var a: Vector2 = NORBLIN_PASSAGE[0]
	var b: Vector2 = NORBLIN_PASSAGE[1]
	var hw: float = NORBLIN_PASSAGE[2]
	var d := (b - a).normalized()
	var o := Vector2(-d.y, d.x) * hw
	var pieces: Array = [PackedVector2Array([a - o, b - o, b + o, a + o])]
	for r: PackedVector2Array in rings:
		var grown := _grown(r, 0.15)
		var next: Array = []
		for pc: PackedVector2Array in pieces:
			for q: PackedVector2Array in Geometry2D.clip_polygons(pc, grown if grown.size() >= 3 else r):
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		pieces = next
	var gap := _largest(pieces)
	if gap.size() < 3 or absf(_area(gap)) < 120.0:
		return
	_g = _ground_under(gap)
	var y := _g + NORBLIN_BASE - 0.1
	_mode = M_GLASS_ROOF
	_cap(gap, y, WORKS_TOP)
	_soffit(gap, y - 0.02, WORKS_TOP.darkened(0.2))
	_mode = M_STONE
	var len := a.distance_to(b)
	for k in range(1, int(len / 4.5)):
		var c := a + d * 4.5 * k
		var p0 := c - o * 1.2
		var p1 := c + o * 1.2
		for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([p0, p1]), gap):
			if piece.size() == 2:
				_beam(Vector3(piece[0].x, y + 0.15, piece[0].y), Vector3(piece[1].x, y + 0.15, piece[1].y), 0.18, NORBLIN_FIN)


## One of the old works: a white workshop or house (two rows of windows when tall enough, a
## dark grey standing-seam hipped roof), or the long low glazed hall on Prosta (glass walls lit
## warm at night under a dark low hip).
func _norblin_old(ring: PackedVector2Array, hall: bool) -> void:
	if ring.size() < 3:
		return
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var ax := _long_axis(ring)
	var width: float = ax[4]
	var eave := 4.0 if hall else (6.4 if width > 12.0 else 4.6)
	var rise := clampf(width * 0.22, 1.6, 3.4)
	if hall:
		_prism(ring, g - 0.4, g + 0.5, WORKS_PLINTH, none, M_STONE)
		_prism(ring, g + 0.5, g + eave, WORKS_TOP.darkened(0.25), none, M_PAVILION)
		_mullions(ring, g + 0.5, g + eave, 2.0, 0.05, NORBLIN_ZINC)
	else:
		_prism(ring, g - 0.4, g + 0.5, WORKS_PLINTH.lightened(0.15), none, M_STONE)
		_bays(ring, 1.1, 2.9, 3.2, 1.3, WORKS_GLASS)
		if eave > 6.0:
			_bays(ring, 3.9, 5.6, 3.2, 1.2, WORKS_GLASS)
		_prism(ring, g + 0.5, g + eave, NORBLIN_WHITE, none, M_STONE)
	# The roof: a 0.4 m eave, slopes up to a ridge set in by most of the half width, its flat top.
	var eaves := _inset_ring(ring, -0.4)
	var ridge := _inset_ring(ring, minf(width * 0.42, 4.0))
	_mode = M_STONE
	_prism(eaves, g + eave - 0.25, g + eave, NORBLIN_ZINC.darkened(0.15), none, M_STONE)
	_soffit(eaves, g + eave - 0.25, NORBLIN_WHITE.darkened(0.2))
	_slope(ring, eaves, g + eave, ridge, g + eave + rise, NORBLIN_ZINC)
	_cap(ridge, g + eave + rise, NORBLIN_ZINC.lightened(0.06))
	_collide(ring)


## A green roof on the glazed storeys of `ring` (top at y): the sedum field a step up inside a
## 1.4 m planted edge, two grey plant rooms, and the garden terraces upstairs where a terrace spot
## (NORBLIN_TERRACES) is near: planters with small trees.
func _norblin_roof(ring: PackedVector2Array, y: float) -> void:
	var inner := _grown(ring, -3.2)
	if inner.size() < 3:
		return
	_mode = M_STONE
	_prism(inner, y, y + 0.12, NORBLIN_EDGE, NORBLIN_SEDUM, M_STONE, M_STONE)
	# Plant rooms on the long axis, a third in from each end.
	var ax := _long_axis(inner)
	var o: Vector2 = ax[0]
	var a: Vector2 = ax[1]
	var b: Vector2 = ax[2]
	for f: float in [0.3, 0.62]:
		var c := o + a * float(ax[3]) * f + b * float(ax[4]) * 0.5
		if Geometry2D.is_point_in_polygon(c, inner):
			var box := PackedVector2Array([c - a * 3.0 - b * 2.0, c + a * 3.0 - b * 2.0, c + a * 3.0 + b * 2.0, c - a * 3.0 + b * 2.0])
			_prism(box, y + 0.12, y + 2.8, NORBLIN_PLANT, NORBLIN_PLANT.darkened(0.1), M_STONE, M_STONE)
	var keep := _no_roof
	_no_roof = true
	for t: Vector2 in NORBLIN_TERRACES:
		var at := t
		if not Geometry2D.is_point_in_polygon(at, inner):
			var best := INF
			for i in inner.size():
				var cp := Geometry2D.get_closest_point_to_segment(t, inner[i], inner[(i + 1) % inner.size()])
				if cp.distance_to(t) < best:
					best = cp.distance_to(t)
					at = cp + (_centre(inner) - cp).normalized() * 2.5
			if best > 9.0:
				continue
		# A timber deck with four planters round it, a small tree in each.
		_prism(_square(at, 3.4), y + 0.12, y + 0.22, VARSO_DECK, VARSO_DECK, M_STONE, M_STONE)
		for k in 4:
			var p := at + Vector2.from_angle(TAU * k / 4.0 + 0.6) * 3.0
			_prism(_square(p, 0.6), y + 0.12, y + 0.75, NORBLIN_PLANT, NORBLIN_EDGE, M_STONE, M_STONE)
			_varso_tree(p, y + 0.75, 2.8 + 0.3 * (k % 2), 0.95)
	_no_roof = keep


func _build_browary(site: Dictionary) -> void:
	var zone: Array[PackedVector2Array] = site["zone"]
	var roles: Array = site["roles"]
	for k in zone.size():
		var ring := zone[k]
		var role: String = roles[k]
		_g = _ground_under(ring)
		var g := _g
		var h := 12.0
		match role:
			"Warzelnia":
				# The brewhouse: tall brick, narrow lancet-like windows in two rows, the brewery chimney by it.
				_works_walls(ring, 14.0, WORKS_DARK, [[1.2, 5.4, 0.9], [7.0, 11.4, 0.9]], 3.4)
				_works_chimney(_farthest(ring, _centre(ring)) + (_centre(ring) - _farthest(ring, _centre(ring))).normalized() * 3.0,
						46.0, 1.7, WORKS_DARK)
			"Willa Schielego":
				_works_walls(ring, 8.0, WORKS_BRICK.lightened(0.08), [[1.2, 3.4, 0.7]], 3.4)
			"Laboratorium":
				_works_walls(ring, 8.0, WORKS_BRICK, [[1.2, 3.8, 0.8]], 3.6)
			_:
				# The office blocks between the old walls: warm grey, brick-coloured base, glass bays.
				h = 22.0 if role == "Biura przy Warzelni" else 30.0
				_prism(_grown(ring, 0.2), g - 0.6, g + 3.0, WORKS_BRICK, WORKS_BRICK, M_STONE, M_STONE)
				# The photo report: almost every Browary block has a green sedum roof with
				# planted edges (the planted edge is the roof, the sedum field a step up).
				_prism(ring, g - 0.6, g + h, WORKS_MODERN, NORBLIN_EDGE, M_STONE, M_STONE)
				_parapet(ring, g + h, 0.8, WORKS_TRIM)
				_bays(ring, 3.4, h - 1.2, 3.0, 1.9, WORKS_GLASS)
				var sedum := _grown(ring, -1.6)
				if sedum.size() >= 3:
					_prism(sedum, g + h, g + h + 0.12, NORBLIN_EDGE, NORBLIN_SEDUM, M_STONE, M_STONE)
					if role == "Biura przy Warzelni":
						_browary_roof_garden(sedum, g + h + 0.12)
		_collide(ring)
	_browary_garden()


## Browary Warszawskie's Central Garden (photo report browary.md, the GUGiK ortho, 2026-11-02):
## the S-shaped gravel path from the south gate to the north slab and the two clearings with white
## café tables, chairs and dark-blue parasols. The same numbers as tools/planted_trees.py
## BROWARY_PATH and BROWARY_CLEARINGS, which keep the garden's 22 trees off them.
const BROWARY_PATH := [Vector2(-2459.0, -84.0), Vector2(-2456.4, -87.3), Vector2(-2454.7, -90.6),
		Vector2(-2454.3, -93.6), Vector2(-2455.5, -96.4), Vector2(-2458.1, -99.0), Vector2(-2461.5, -101.5),
		Vector2(-2464.9, -104.0), Vector2(-2467.5, -106.6), Vector2(-2468.7, -109.4), Vector2(-2468.3, -112.4),
		Vector2(-2466.6, -115.7), Vector2(-2464.0, -119.0)]
const BROWARY_CLEARINGS := [Vector2(-2459.4, -93.2), Vector2(-2463.6, -109.8)]
const BROWARY_GRAVEL := Color("#cbbd9e")
const BROWARY_PAVING := Color("#e2ded4")   # the clearings' pale stone (look check: tell them from the path)
const BROWARY_EDGE := Color("#3d3f41")     # dark steel edging round the path and the clearings
const BROWARY_CLEARING_R := 4.2
const BROWARY_WHITE := Color("#e9e6df")
const BROWARY_BLUE := Color("#24385a")
## The roof garden on the north slab (report: x -2470..-2410, z -150..-130): a gravel walk down
## its length and two small garden houses.
const BROWARY_ROOF_WALK := [Vector2(-2472.0, -133.0), Vector2(-2412.0, -148.0)]
const BROWARY_ROOF_HOUSES := [Vector2(-2460.0, -138.5), Vector2(-2424.0, -147.0)]


func _browary_garden() -> void:
	var g := map.terrain_height(-2460.0, -100.0) as float
	var none := Color(0, 0, 0, 0)
	# F's look check (2026-11-03): the path and the clearings read apart. The clearings are
	# paved in pale stone inside a dark steel edge and laid first; the main path is gravel
	# between two dark edging strips, 1.5 m each side of its line (clipped by the clearings).
	_mode = M_STONE
	_no_roof = true
	for c: Vector2 in BROWARY_CLEARINGS:
		_cap(_circle(c, BROWARY_CLEARING_R + 0.25, 14), g + 0.13, BROWARY_EDGE)
		_cap(_circle(c, BROWARY_CLEARING_R, 14), g + 0.18, BROWARY_PAVING)
	var edges: Array[PackedVector2Array] = []
	var pieces: Array[PackedVector2Array] = []
	for i in BROWARY_PATH.size() - 1:
		var a: Vector2 = BROWARY_PATH[i]
		var b: Vector2 = BROWARY_PATH[i + 1]
		var t := (b - a).normalized() * 0.6
		var n := Vector2(-t.y, t.x) / 0.6
		pieces.append(PackedVector2Array([a - t - n * 1.5, b + t - n * 1.5, b + t + n * 1.5, a - t + n * 1.5]))
		edges.append(PackedVector2Array([a - t - n * 1.75, b + t - n * 1.75, b + t + n * 1.75, a - t + n * 1.75]))
	for pc in edges:
		_cap(pc, g + 0.04, BROWARY_EDGE)  # _cap clips each piece by the ones before it (within 3 cm)
	for pc in pieces:
		_cap(pc, g + 0.08, BROWARY_GRAVEL)
	# Two white tables in each clearing, two chairs each, a dark-blue parasol over the pair.
	for c: Vector2 in BROWARY_CLEARINGS:
		for side: float in [-1.0, 1.0]:
			var p := c + Vector2(side * 1.4, 0.0)
			_prism(_circle(p, 0.45, 6), g + 0.06, g + 0.75, BROWARY_WHITE, BROWARY_WHITE, M_STONE, M_STONE)
			for q: Vector2 in [p + Vector2(0.0, -0.85), p + Vector2(0.0, 0.85)]:
				_prism(_square(q, 0.22), g + 0.06, g + 0.48, BROWARY_WHITE.darkened(0.08), BROWARY_WHITE, M_STONE, M_STONE)
		_prism(_circle(c, 0.05, 4), g + 0.06, g + 2.4, Color("#c9cdd0"), none, M_STONE)
		_mode = M_STONE
		_pyramid(_circle(c, 2.2, 8), g + 2.4, g + 3.0, BROWARY_BLUE)
	_no_roof = false


func _browary_roof_garden(roof: PackedVector2Array, y: float) -> void:
	var a: Vector2 = BROWARY_ROOF_WALK[0]
	var b: Vector2 = BROWARY_ROOF_WALK[1]
	var o := (b - a).normalized().orthogonal() * 0.8
	for q: PackedVector2Array in Geometry2D.intersect_polygons(PackedVector2Array([a - o, b - o, b + o, a + o]), roof):
		if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
			_prism(q, y, y + 0.06, BROWARY_GRAVEL, BROWARY_GRAVEL, M_STONE, M_STONE)
	for c: Vector2 in BROWARY_ROOF_HOUSES:
		if Geometry2D.is_point_in_polygon(c, roof):
			_prism(_square(c, 1.5), y, y + 2.6, WORKS_MODERN, WORKS_ROOF, M_STONE, M_STONE)


## Hala Koszyki from photos (2026-11-15, spec koszyki.md; F's T18 set in refs/_f/warsaw-needed-photos/top-50,
## Mapillary frames along Koszykowa in refs/koszyki_west and refs/koszyki_east; reference only, never
## shipped). The hall's mass is its street block (game/data/street_blocks/459521303.bin, site
## blk_459521303: the buff brick ranges, the two long pitched halls, the forecourt); this site dresses
## it and draws no walls of its own (the 2026-11-01 model drew a second hall over the block). In the street's frame (KOS_O the outline's north-west corner on Koszykowa, u east
## along the street, v south into the block) the two 1909 pavilions stand at the street ends of the
## two long halls, u 3.5..16.3 and 66..78: a cream stone front between two pylons with red brick
## panels, the big three-light arch in green steel over a balcony, a door and two shop windows
## under it, a stepped gable with a cartouche. Between them the forecourt is the summer terrace
## under festoon lights, KOSZYKI in blue neon over the hall's door at its back.
const KOS_O := Vector2(-922.5, 1260.4)
const KOS_A := Vector2(0.99629, 0.08604)
## The pavilions: [u of the middle, v of the block's stone front] (measured off the block).
const KOS_PAVILIONS := [Vector2(9.88, -1.15), Vector2(71.97, -0.89)]
const KOS_STONE := Color("#ddd2b6")
const KOS_BASE := Color("#c2b597")       ## the rusticated foot
const KOS_RED := Color("#b5643f")        ## the pylons' red brick panels
const KOS_GREEN := Color("#2e6b4a")      ## the green steel frames and railings
const KOS_GLASS := Color("#24332e")
const KOS_DOOR := Color("#2a3532")
const KOS_BULB := Color("#ffe2a8")


func _kos_w(u: float, v: float) -> Vector2:
	return KOS_O + KOS_A * u + Vector2(-KOS_A.y, KOS_A.x) * v


func _build_koszyki(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	for p: Vector2 in KOS_PAVILIONS:
		_koszyki_pavilion(g, p.x, p.y)
	_koszyki_terrace(g)
	_collide(ring)


## One 1909 pavilion's street front (the photos: T18 front-2, Mapillary 1369000433495769), on the
## block's own pavilion just in front of it: the frame's v is out to the street, u across (the
## front is symmetric, so its sense does not matter). Every part stands at least 0.06 m off the
## one behind it.
func _koszyki_pavilion(g: float, cu: float, vf: float) -> void:
	var out := -Vector2(-KOS_A.y, KOS_A.x)
	_b = out
	_a = Vector2(out.y, -out.x)
	_o = _kos_w(cu, vf)
	_mode = M_STONE
	# The frontispiece between the pylons, its rusticated foot and the stepped gable.
	_lbox(0.0, 0.1, 4.2, 0.2, g - 0.5, g + 10.4, KOS_STONE, M_STONE, KOS_STONE)
	_lbox(0.0, 0.2, 4.2, 0.2, g - 0.5, g + 0.6, KOS_BASE, M_STONE, KOS_BASE)
	_lbox(0.0, 0.25, 4.35, 0.2, g + 10.2, g + 10.55, KOS_STONE.darkened(0.05), M_STONE, KOS_STONE)
	var steps := [[3.4, 10.55, 11.1], [2.5, 11.1, 11.65], [1.6, 11.65, 12.2]]
	for st: Array in steps:
		_lbox(0.0, 0.1, float(st[0]), 0.2, g + float(st[1]), g + float(st[2]), KOS_STONE, M_STONE, KOS_STONE)
	_lbox(0.0, 0.25, 0.9, 0.25, g + 11.2, g + 12.9, KOS_STONE.lightened(0.06), M_STONE, KOS_STONE)
	# The pylons: stone, a rusticated foot, a red brick panel up the face, a cap and a finial.
	for side: float in [-1.0, 1.0]:
		var pu := side * 5.3
		_lbox(pu, 0.15, 1.1, 0.35, g - 0.5, g + 13.2, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(pu, 0.2, 1.2, 0.42, g - 0.5, g + 3.4, KOS_BASE, M_STONE, KOS_BASE)
		_lbox(pu, 0.53, 0.75, 0.05, g + 6.0, g + 11.0, KOS_RED, M_STONE, KOS_RED)
		_lbox(pu, 0.2, 1.2, 0.45, g + 13.2, g + 13.6, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(pu, 0.2, 0.6, 0.3, g + 13.6, g + 14.2, KOS_STONE, M_STONE, KOS_STONE)
	# The big arch: a stone ring, the green-framed glass, two stone mullions, two green transoms.
	var at := _w(0.0, 0.3)
	_arch_panel(at, _a, _b, 4.4, g + 4.6, g + 5.4, KOS_STONE.lightened(0.04), 0.06, M_STONE)
	_arch_panel(at, _a, _b, 3.9, g + 4.8, g + 5.4, KOS_GLASS, 0.12, M_GLASS)
	for mu: float in [-1.3, 1.3]:
		_lbox(mu, 0.47, 0.16, 0.05, g + 4.8, g + 9.0, KOS_STONE, M_STONE, KOS_STONE)
	for ty: float in [6.4, 7.8]:
		var hw := sqrt(maxf(3.9 * 3.9 - pow(maxf(ty - 5.4, 0.0), 2.0), 0.0)) - 0.1
		_lbox(0.0, 0.46, hw, 0.03, g + ty, g + ty + 0.12, KOS_GREEN, M_STONE, KOS_GREEN)
	# The balcony under the arch: a stone ledge and the green railing.
	_lbox(0.0, 0.5, 4.2, 0.2, g + 4.2, g + 4.8, KOS_STONE.darkened(0.04), M_STONE, KOS_STONE)
	_lbox(0.0, 0.66, 3.9, 0.03, g + 4.8, g + 5.6, KOS_GREEN, M_STONE, KOS_GREEN)
	# The ground floor: the arched door in a stone surround, a shop window either side.
	_arch_panel(at, _a, _b, 1.0, g + 0.0, g + 2.6, KOS_DOOR, 0.12, M_STONE)
	for side: float in [-1.0, 1.0]:
		_lbox(side * 1.45, 0.45, 0.25, 0.15, g - 0.5, g + 4.2, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(side * 2.9, 0.4, 1.0, 0.03, g + 0.5, g + 3.6, KOS_GLASS, M_GLASS, KOS_GLASS)
		_lbox(side * 2.9, 0.43, 1.05, 0.03, g + 3.6, g + 3.75, KOS_GREEN, M_STONE, KOS_GREEN)
	_collide(_rect(0.0, 0.3, 6.4, 0.4))


## The forecourt's summer terrace: two strings of festoon bulbs on poles across it, lit at night
## (the night photo); KOSZYKI in blue neon over the hall's door.
func _koszyki_terrace(g: float) -> void:
	_mode = M_STONE
	for v: float in [7.5, 15.0]:
		for end: float in [22.6, 58.3]:
			var p := _kos_w(end, v)
			_prism(_circle(p, 0.08, 4), g, g + 4.3, KOS_DOOR, KOS_DOOR, M_STONE, M_STONE)
		# The wire, pole to pole through every bulb, and the bulbs hanging on it.
		var pts: Array[Vector3] = []
		var u := 22.6
		while u < 58.3:
			var q := _kos_w(u, v)
			pts.append(Vector3(q.x, g + 3.9 - 0.35 * sin(PI * (u - 22.6) / 35.7), q.y))
			u += 2.4
		var e := _kos_w(58.3, v)
		pts.append(Vector3(e.x, g + 3.9, e.y))
		var side := Vector2(-KOS_A.y, KOS_A.x) * 0.03
		for i in range(pts.size() - 1):
			var a := Vector2(pts[i].x, pts[i].z)
			var c := Vector2(pts[i + 1].x, pts[i + 1].z)
			var y := (pts[i].y + pts[i + 1].y) * 0.5
			_prism(PackedVector2Array([a - side, c - side, c + side, a + side]), y - 0.03, y + 0.03,
					KOS_DOOR, KOS_DOOR, M_STONE, M_STONE)
			if i > 0:
				_prism(_circle(a, 0.13, 4), pts[i].y - 0.13, pts[i].y + 0.13, KOS_BULB, KOS_BULB, M_LAMP, M_LAMP)
	var at := _kos_w(40.3, 21.0)
	var out := -Vector2(-KOS_A.y, KOS_A.x)
	signs.append(["KOSZYKI", Vector3(at.x, g + 6.0, at.y), Vector3(out.x, 0.0, out.y),
			7.5 / Neon.length_of("KOSZYKI"), Color(0.35, 0.7, 1.0)])


## Elektrownia Powiśle, the whole complex (2026-11-13, F: "like in real life, with the fronts", and
## "alive: people, summer bars, small squares"; spec docs/landmarks/specs/elektrownia.md, photos:
## 34 Mapillary frames round the block, refs/elektrownia-*/, never shipped). Every part is placed
## in the turbine hall's frame (u along the hall from the Dobra gable, -40.8, to the cross wing at
## 22.3; v across it, + towards Zajęcza):
## - the turbine hall over the stem: orange brick, zinc gable roof with a glazed ridge, its Dobra
##   gable a glass-and-steel front (big steel-grid windows, the shop glass, an X-braced frieze),
##   festoon bulbs along the gable and the south eave, the glass lift tower with the blue box;
## - the brick halls round the T (the mapped outline): tall round-arched windows in cream
##   surrounds in two rows between brick pilasters, a cream string course and cornice; the arches
##   on the yards and passages are shop windows, lit warm at night; the cross wing under a zinc
##   gable with a long glass lantern;
## - the four aluminium stacks, lit blue at night (the real ones are);
## - the glass-roofed passage south of the hall (the mapped block between the hall and the new
##   office), its plaza front with steel-grid windows and an X-braced frieze;
## - the new office on Zajęcza 2B: a dark glass block on a black-columned arcade of lit shops,
##   brick fins up its plaza face;
## - the low old wing on Wybrzeże Kościuszkowskie 43C: brick, arched windows in pale render
##   surrounds, a taller pavilion at its Leszczyńska end;
## - the life (elektrownia_garden_plan, the same for crowds.gd's sitters): the beer tables under
##   festoons in the passage between the cross wing and the old wing, the summer bar with its
##   umbrellas and deck chairs on the yard by Leszczyńska, café tables on the setts plaza by
##   Dobra, the painted sphere on the lawn; shop and bar names are parodies (warsaw-tone).
const ELEK_C := Vector2(245.0, -740.0)
const ELEK_AXIS := Vector2(0.7885, -0.615)
const ELEK_U0 := -40.8   ## the Dobra gable
const ELEK_U1 := 22.3    ## the hall's east end, where the cross wing starts
const ELEK_HV := 15.4
const ELEK_EAVE := 16.0
const ELEK_RISE := 9.0
const ELEK_WALL := 13.0  ## the brick halls round the T
const ELEK_PITCH := 5.5
const ELEK_BRICK := Color("#a35e42")
const ELEK_TRIM := Color("#d9d0bd")
const ELEK_STEEL := Color("#26292c")
const ELEK_ZINC := Color("#737a7f")
const ELEK_ALU := Color("#c3c7ca")
const ELEK_BLUE := Color("#2f8fd4")
const ELEK_LIFT := Color("#86aebd")
const ELEK_SHOP := Color("#e9b77a")      ## shop glass: warm, lit at night (M_PAVILION)
const ELEK_DARK_GLASS := Color("#2f3a44")
const ELEK_ROOF_GLASS := Color("#9ab9c6")
const ELEK_OFFICE_GLASS := Color("#3e4d5a")
const ELEK_FIN := Color("#9c5238")
const ELEK_RENDER := Color("#d6d3ca")    ## the old wing's pale window surrounds
const ELEK_SETT := [Color("#9b8f88"), Color("#b39a92"), Color("#c9c4bc"), Color("#7f7a77"), Color("#a7807a")]
## The stacks: [u, v] in the hall's frame (two by the front gable, two further back).
const ELEK_STACKS := [Vector2(-27.0, -12.0), Vector2(-27.0, 12.0), Vector2(6.0, -11.0), Vector2(14.0, 11.0)]
const ELEK_STACK_TOP := 33.0
## The mapped blocks the site takes over besides its own outline (OpenStreetMap, game metres):
## the glass-roofed passage between the hall and the office, the office (Zajęcza 2B) and the old
## wing on the embankment (Wybrzeże Kościuszkowskie 43C).
const ELEK_ATRIUM := [292.1, -706.5, 286.9, -713.0, 281.2, -720.1, 275.9, -726.8, 269.4, -721.7, 257.0, -712.1,
		252.9, -718.0, 251.8, -719.6, 250.2, -721.7, 252.1, -723.2, 260.8, -730.0, 264.6, -733.0, 269.5, -736.8,
		271.1, -738.0, 273.4, -739.8, 276.4, -736.0, 277.0, -735.3, 279.4, -732.3, 283.0, -727.6, 286.3, -723.4,
		290.0, -718.8, 293.7, -714.3, 299.5, -706.8, 302.8, -703.5, 301.7, -702.4, 302.5, -701.2, 301.4, -700.3,
		300.2, -699.3, 299.2, -700.5, 297.7, -699.4]
const ELEK_OFFICE := [249.2, -705.7, 257.0, -712.1, 269.4, -721.7, 275.9, -726.8, 281.2, -720.1, 286.9, -713.0,
		292.1, -706.5, 297.7, -699.4, 314.7, -678.5, 312.9, -675.9, 306.2, -665.8]
const ELEK_WING := [283.4, -796.2, 310.4, -762.0, 304.7, -757.2, 276.5, -792.0, 282.7, -797.0]
const ELEK_OFFICE_TOP := 18.9
const ELEK_ATRIUM_TOP := 11.5
## The beer tables in the passage (u, v of the table's middle; the table runs along v), the
## yard's umbrella tables and deck chairs (u, v), the plaza's café tables (u, v).
const ELEK_BEER := [Vector2(54.6, -17.0), Vector2(54.6, -10.5), Vector2(54.6, -4.0), Vector2(54.6, 3.0),
		Vector2(54.6, 10.0), Vector2(54.6, 17.0)]
const ELEK_YARD_UMB := [Vector2(-12.0, -25.5), Vector2(-4.5, -25.0), Vector2(3.0, -25.0), Vector2(10.5, -25.5),
		Vector2(-14.0, -33.0), Vector2(11.0, -33.0)]
const ELEK_LEZAK := [Vector2(-34.0, -40.5), Vector2(-31.6, -40.5), Vector2(-29.2, -40.5), Vector2(-26.8, -40.5),
		Vector2(-24.4, -40.5), Vector2(-22.0, -40.5)]
const ELEK_PLAZA_UMB := [Vector2(-35.5, 22.0), Vector2(-29.0, 22.0), Vector2(-22.5, 22.0), Vector2(-16.0, 22.0)]
const ELEK_BAR := Vector2(-1.5, -33.5)
const ELEK_SPHERE := Vector2(53.0, -31.0)


## The plan of the complex's tables and chairs (the model draws them, crowds.gd sits people on
## the seats): seats [p, sitter's yaw], two a side at each beer table, two at each umbrella, one
## in each deck chair; "centre" the passage's middle.
static func elektrownia_garden_plan() -> Dictionary:
	var a := ELEK_AXIS
	var b := Vector2(-a.y, a.x)
	var at := func(u: float, v: float) -> Vector2: return ELEK_C + a * u + b * v
	var seats: Array = []
	for t: Vector2 in ELEK_BEER:
		for side: float in [-1.0, 1.0]:
			for dv: float in [-0.55, 0.55]:
				var d := a * side
				seats.append([at.call(t.x + side * 0.78, t.y + dv), atan2(d.x, d.y)])
	for t: Vector2 in ELEK_YARD_UMB + ELEK_PLAZA_UMB:
		for side: float in [-1.0, 1.0]:
			var d := b * side
			seats.append([(at.call(t.x, t.y) as Vector2) + d * 0.8, atan2(d.x, d.y)])
	for c: Vector2 in ELEK_LEZAK:
		seats.append([at.call(c.x, c.y), atan2(-b.x, -b.y)])
	return {"seats": seats, "centre": at.call(40.0, -10.0)}


func _build_elektrownia(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_elek_frame()
	var others: Array[PackedVector2Array] = [_pts(ELEK_ATRIUM), _pts(ELEK_OFFICE), _pts(ELEK_WING)]
	# The turbine hall and the lift first: their faces own the planes the brick ring shares.
	_elek_hall(g)
	_elek_lift(g)
	_elek_walls(ring, g, others)
	_elek_cross_roof(g)
	_elek_stacks(g)
	_elek_atrium(others[0], g)
	_elek_office(others[1], g)
	_elek_wing(others[2], g)
	_elek_signs(g)
	_elek_life(g)
	_elek_frame()
	_collide(ring)
	for q: PackedVector2Array in others:
		_collide(q)


func _elek_frame() -> void:
	_o = ELEK_C
	_a = ELEK_AXIS
	_b = Vector2(-_a.y, _a.x)


## The turbine hall: the brick body to the eaves, the zinc gable roof with its glazed ridge, the
## Dobra gable's glass-and-steel front (F's corner photo at night) and the festoons.
func _elek_hall(g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var hc := (ELEK_U0 + ELEK_U1) * 0.5
	var hu := (ELEK_U1 - ELEK_U0) * 0.5
	var hv := ELEK_HV
	var eave := g + ELEK_EAVE
	# The front's glass and steel before the brick (the brick's wall in that plane is cut round it).
	var out := -_a
	var front := ELEK_U0 - 0.06
	for side: float in [-1.0, 1.0]:
		# the shop glass on the ground (lit), the big steel-grid windows over it
		_elek_pane(front, side * 8.6, 4.6, 0.4, 4.4, ELEK_SHOP, M_PAVILION)
		_elek_pane(front, side * 8.6, 4.6, 6.2, 13.4, ELEK_DARK_GLASS, M_GLASS)
		_elek_grid(front, side * 8.6, 4.6, 6.2, 13.4, 1.15, 1.2)
	_prism(_rect(hc, 0.0, hu, hv), g - 0.6, eave, ELEK_BRICK, none, M_STONE, M_STONE)
	_gable(ELEK_U0, ELEK_U1, 0.0, hv, eave, ELEK_RISE, ELEK_BRICK, ELEK_ZINC)
	# the gable's stepped shoulders and the glazed ridge
	for side: float in [-1.0, 1.0]:
		_prism(_rect(ELEK_U0 + 0.4, side * (hv - 2.0), 0.5, 2.0), eave, eave + 1.6, ELEK_BRICK, ELEK_STEEL, M_STONE, M_STONE)
	_mode = M_PAVILION + 0.5
	_prism(_rect(hc + 2.0, 0.0, hu - 6.0, 1.5), eave + ELEK_RISE - 1.0, eave + ELEK_RISE + 0.9, ELEK_ROOF_GLASS, ELEK_ROOF_GLASS.lightened(0.15),
			M_PAVILION + 0.5, M_PAVILION + 0.5)
	_mode = M_STONE
	# the front's frieze: black steel braces in X under the eaves, a steel band over the shops
	# (each brace and band at its own depth: crossing faces in one plane would flicker)
	var f := func(v: float, y: float, d: float) -> Vector3:
		var q := _w(front - d, v)
		return Vector3(q.x, g + y, q.y)
	var x := -hv + 0.6
	while x < hv - 3.0:
		_beam(f.call(x, 13.9, 0.1), f.call(x + 3.6, 15.7, 0.1), 0.22, ELEK_STEEL)
		_beam(f.call(x, 15.7, 0.18), f.call(x + 3.6, 13.9, 0.18), 0.22, ELEK_STEEL)
		x += 3.6
	_beam(f.call(-hv + 0.3, 13.8, 0.3), f.call(hv - 0.3, 13.8, 0.3), 0.3, ELEK_STEEL)
	_beam(f.call(-hv + 0.3, 4.9, 0.3), f.call(hv - 0.3, 4.9, 0.3), 0.45, ELEK_STEEL)
	# the glass canopy over the doors right of the lift
	_lbox(ELEK_U0 - 1.6, 6.0, 1.6, 3.4, g + 4.4, g + 4.65, ELEK_ROOF_GLASS, M_GLASS, ELEK_ROOF_GLASS.lightened(0.2))
	# Festoons (the night photo): up both slopes of the gable and along the south eave.
	var at := func(u: float, v: float, y: float) -> Vector3:
		var q := _w(u, v)
		return Vector3(q.x, y, q.y)
	_elek_festoon(at.call(ELEK_U0 - 0.25, -hv, eave + 0.1), at.call(ELEK_U0 - 0.25, 0.0, eave + ELEK_RISE + 0.1), 0.05, 9)
	_elek_festoon(at.call(ELEK_U0 - 0.25, 0.0, eave + ELEK_RISE + 0.1), at.call(ELEK_U0 - 0.25, hv, eave + 0.1), 0.05, 9)
	_elek_festoon(at.call(ELEK_U0, hv + 0.25, eave + 0.05), at.call(ELEK_U1 - 1.0, hv + 0.25, eave + 0.05), 0.05, 26)


## A flat pane on the hall's Dobra front (u, facing -u) at v, half-width hw, between y0 and y1.
func _elek_pane(u: float, v: float, hw: float, y0: float, y1: float, col: Color, mode: float) -> void:
	var keep := _mode
	_mode = mode
	var p0 := _w(u, v - hw)
	var p1 := _w(u, v + hw)
	_quad(Vector3(p1.x, _g + y0, p1.y), Vector3(p0.x, _g + y0, p0.y), Vector3(p0.x, _g + y1, p0.y), Vector3(p1.x, _g + y1, p1.y),
			Vector3(-_a.x, 0.0, -_a.y), col, Vector2(0, y0), Vector2(hw * 2.0, y0), Vector2(hw * 2.0, y1), Vector2(0, y1), y1)
	_mode = keep


## The steel grid of a big window on the Dobra front: bars every `du` across and `dy` up.
func _elek_grid(u: float, v: float, hw: float, y0: float, y1: float, dv: float, dy: float) -> void:
	var n := Vector3(-_a.x, 0.0, -_a.y)
	var uu := u - 0.05
	var s := -hw
	while s <= hw + 0.01:
		var p0 := _w(uu, v + s - 0.06)
		var p1 := _w(uu, v + s + 0.06)
		_quad(Vector3(p1.x, _g + y0, p1.y), Vector3(p0.x, _g + y0, p0.y), Vector3(p0.x, _g + y1, p0.y), Vector3(p1.x, _g + y1, p1.y), n, ELEK_STEEL)
		s += dv
	var y := y0
	while y <= y1 + 0.01:
		# 4 cm proud of the uprights: crossing bars in one plane would flicker
		var p0 := _w(uu - 0.04, v - hw)
		var p1 := _w(uu - 0.04, v + hw)
		_quad(Vector3(p1.x, _g + y - 0.06, p1.y), Vector3(p0.x, _g + y - 0.06, p0.y), Vector3(p0.x, _g + y + 0.06, p0.y),
				Vector3(p1.x, _g + y + 0.06, p1.y), n, ELEK_STEEL)
		y += dy


## The glass lift tower in the gable's porch, the blue corrugated box on top and the blue bay.
func _elek_lift(g: float) -> void:
	var none := Color(0, 0, 0, 0)
	# a hair wider than the mapped porch, so its glass stands in front of the porch's brick
	var lc := -42.45
	var lv := 0.3
	_mode = M_GLASS
	_prism(_rect(lc, lv, 1.65, 1.5), g - 0.6, g + 27.0, ELEK_LIFT, none, M_GLASS, M_STONE)
	_mode = M_STONE
	for cu: float in [lc - 1.6, lc + 1.6]:
		for cv: float in [lv - 1.4, lv + 1.4]:
			var q := _w(cu, cv)
			_beam(Vector3(q.x, g, q.y), Vector3(q.x, g + 27.0, q.y), 0.22, ELEK_STEEL)
	_prism(_rect(lc - 0.4, lv - 3.3, 1.8, 2.0), g + 6.0, g + 9.2, ELEK_BLUE, ELEK_BLUE.darkened(0.15), M_STONE, M_STONE)
	_prism(_rect(lc, lv, 2.1, 1.9), g + 27.0, g + 31.0, ELEK_BLUE, ELEK_BLUE.darkened(0.2), M_STONE, M_STONE)
	_collide(_rect(lc, lv, 1.6, 1.4))


## The brick halls round the T: on every face two rows of round-arched windows between
## pilasters, the ground row lit as shop windows where the face looks onto a yard, a passage or
## the plaza (not where it backs onto the passage block or the office), a cream string course and
## cornice, a flat zinc roof.
func _elek_walls(ring: PackedVector2Array, g: float, others: Array[PackedVector2Array]) -> void:
	var h := ELEK_WALL
	var none := Color(0, 0, 0, 0)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		var n := floori((length - 1.0) / ELEK_PITCH)
		if n < 1:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var mid := (a + b) * 0.5 + out * 2.5
		var hidden := false
		for q: PackedVector2Array in others:
			if Geometry2D.is_point_in_polygon(mid, q):
				hidden = true
		if hidden or _elek_in_hall(mid - out * 3.0):
			continue
		var t0 := (length - n * ELEK_PITCH) * 0.5 + ELEK_PITCH * 0.5
		for k in n:
			var at := a + e * (t0 + k * ELEK_PITCH)
			_arch_panel(at, e, out, 1.95, g + 0.25, g + 3.6, ELEK_TRIM, 0.04, M_STONE)
			_arch_panel(at, e, out, 1.65, g + 0.4, g + 3.6, ELEK_SHOP, 0.08, M_PAVILION)
			_arch_panel(at, e, out, 1.7, g + 6.2, g + 9.6, ELEK_TRIM, 0.04, M_STONE)
			_arch_panel(at, e, out, 1.4, g + 6.4, g + 9.6, ELEK_DARK_GLASS, 0.08, M_GLASS)
		for k in n + 1:
			var p := a + e * (t0 + (k - 0.5) * ELEK_PITCH)
			var pil := PackedVector2Array([p - e * 0.35, p + e * 0.35, p + e * 0.35 + out * 0.22, p - e * 0.35 + out * 0.22])
			_prism(pil, g + 0.6, g + h - 0.9, ELEK_BRICK.darkened(0.06), none, M_STONE, M_STONE)
	var base := _grown(ring, 0.2)
	if base.size() >= 3:
		_prism(base, g - 0.6, g + 0.6, WORKS_PLINTH, none, M_STONE, M_STONE)
	_prism(ring, g - 0.6, g + h, ELEK_BRICK, none, M_STONE, M_STONE)
	var course := _grown(ring, 0.12)
	if course.size() >= 3:
		_prism(course, g + 5.0, g + 5.45, ELEK_TRIM, none, M_STONE, M_STONE)
	var top := _grown(ring, 0.3)
	if top.size() >= 3:
		_prism(top, g + h - 0.9, g + h, ELEK_TRIM, ELEK_ZINC.darkened(0.1), M_STONE, M_STONE)
	else:
		_prism(ring, g + h - 0.1, g + h, ELEK_TRIM, ELEK_ZINC.darkened(0.1), M_STONE, M_STONE)


func _elek_in_hall(p: Vector2) -> bool:
	var l := _local(p)
	return l.x > ELEK_U0 + 0.5 and l.x < ELEK_U1 - 0.5 and absf(l.y) < ELEK_HV - 0.5


## The cross wing's roof: a zinc gable along it over the flat brick top, a glass lantern on its ridge.
func _elek_cross_roof(g: float) -> void:
	var keep_o := _o
	var keep_a := _a
	var keep_b := _b
	_o = keep_o + keep_a * 33.0 + keep_b * 13.5
	_a = keep_b
	_b = -keep_a
	var y := g + ELEK_WALL
	_gable(-51.0, 51.0, 0.0, 10.4, y, 4.6, ELEK_BRICK, ELEK_ZINC)
	_mode = M_PAVILION + 0.5
	_prism(_rect(0.0, 0.0, 47.0, 1.5), y + 3.6, y + 5.3, ELEK_ROOF_GLASS, ELEK_ROOF_GLASS.lightened(0.15), M_PAVILION + 0.5, M_PAVILION + 0.5)
	_mode = M_STONE
	_o = keep_o
	_a = keep_a
	_b = keep_b


## The four stacks: aluminium tubes out of the hall roof with flared tops, lit blue at night (the
## tube's M_LAMP + 0.5: its own colour by day, blue neon at night).
func _elek_stacks(g: float) -> void:
	var none := Color(0, 0, 0, 0)
	for st: Vector2 in ELEK_STACKS:
		var c := _w(st.x, st.y)
		_prism(_circle(c, 1.3, 12), g + 12.0, g + ELEK_STACK_TOP - 3.0, ELEK_ALU, none, M_LAMP + 0.5, M_STONE)
		_mode = M_LAMP + 0.5
		_frustum(_circle(c, 1.3, 12), g + ELEK_STACK_TOP - 3.0, _circle(c, 2.0, 12), g + ELEK_STACK_TOP, ELEK_ALU.lightened(0.08), ELEK_STEEL)
		_mode = M_STONE
		_prism(_circle(c, 1.42, 12), g + ELEK_STACK_TOP - 6.0, g + ELEK_STACK_TOP - 5.4, ELEK_ALU.darkened(0.2), none, M_STONE, M_STONE)


## The passage block between the hall and the office: brick to 11.5 m under a glass roof on steel
## ribs (lit from inside at night); its plaza front with the shop glass, a big steel-grid window and
## an X-braced frieze; glass doors at its Zajęcza end.
func _elek_atrium(q: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var top := g + ELEK_ATRIUM_TOP
	# The plaza front (u = -7.3, facing -u): before the brick.
	for side: float in [-1.0, 1.0]:
		_elek_pane(-7.5, 23.5 + side * 2.9, 2.5, 0.4, 4.2, ELEK_SHOP, M_PAVILION)
	_elek_pane(-7.5, 23.5, 5.4, 5.4, 9.6, ELEK_DARK_GLASS, M_GLASS)
	_elek_grid(-7.5, 23.5, 5.4, 5.4, 9.6, 1.35, 1.4)
	var f := func(v: float, y: float) -> Vector3:
		var p := _w(-7.62, v)
		return Vector3(p.x, g + y, p.y)
	var v := 18.2
	while v < 28.6:
		_beam(f.call(v, 9.9), f.call(v + 2.6, 11.2), 0.18, ELEK_STEEL)
		_beam(f.call(v, 11.2) - Vector3(_a.x, 0.0, _a.y) * 0.08, f.call(v + 2.6, 9.9) - Vector3(_a.x, 0.0, _a.y) * 0.08, 0.18, ELEK_STEEL)
		v += 2.6
	_lbox(-8.6, 23.5, 1.1, 5.6, g + 4.3, g + 4.6, ELEK_STEEL, M_STONE, ELEK_STEEL.lightened(0.1))
	# the Zajęcza end's glass doors
	var d0 := _w(16.8, 66.05)
	var d1 := _w(21.4, 66.05)
	_mode = M_PAVILION
	_quad(Vector3(d0.x, g + 0.2, d0.y), Vector3(d1.x, g + 0.2, d1.y), Vector3(d1.x, g + 4.0, d1.y), Vector3(d0.x, g + 4.0, d0.y),
			Vector3(_b.x, 0.0, _b.y), ELEK_SHOP)
	_mode = M_STONE
	_prism(q, g - 0.6, top, ELEK_BRICK, none, M_STONE, M_STONE)
	_parapet(q, top, 0.7, ELEK_TRIM)
	var glass := _grown(q, -0.6)
	if glass.size() >= 3:
		_mode = M_PAVILION + 0.5
		_cap(glass, top + 0.35, ELEK_ROOF_GLASS)
		_mode = M_STONE
	# steel ribs across both arms, every 3 m
	for arm: Array in [[-6.6, 21.8, 18.2, 29.0, true], [16.9, 22.1, 30.0, 65.5, false]]:
		var across_u: bool = arm[4]
		var s: float = arm[0] if across_u else arm[2]
		var e_: float = arm[1] if across_u else arm[3]
		while s <= e_:
			var p0 := _w(s, arm[2]) if across_u else _w(arm[0], s)
			var p1 := _w(s, arm[3]) if across_u else _w(arm[1], s)
			_beam(Vector3(p0.x, top + 0.45, p0.y), Vector3(p1.x, top + 0.45, p1.y), 0.16, ELEK_STEEL)
			s += 3.0


## The new office on Zajęcza 2B: a black-columned arcade of lit shops under four storeys of dark
## glass, brick fins up the plaza face and the Zajęcza end (the night photo), a flat roof.
func _elek_office(q: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var low := g + 4.6
	var top := g + ELEK_OFFICE_TOP
	var inner := _grown(q, -1.4)
	if inner.size() >= 3:
		_prism(inner, g - 0.6, low, ELEK_SHOP, none, M_PAVILION, M_STONE)
	# the arcade's soffit (seen from the plaza) and the columns along the open faces
	for i in q.size():
		var a := q[i]
		var b := q[(i + 1) % q.size()]
		var length := a.distance_to(b)
		if length < 5.0 or _elek_backed(a, b, q):
			continue
		var e := (b - a) / length
		var out := _out(q, a, b)
		var n := maxi(1, roundi(length / 6.0))
		for k in range(0, n + 1):
			var p := a + e * (length * k / n) - out * 0.45
			_prism(_square(p, 0.38), g - 0.3, low, ELEK_STEEL, none, M_STONE, M_STONE)
		if length > 9.0:
			var m := maxi(2, roundi(length / 2.8))
			for k in range(1, m):
				var p := a + e * (length * k / m) + out * 0.25
				var fin := PackedVector2Array([p - e * 0.18, p + e * 0.18, p + e * 0.18 + out * 0.55, p - e * 0.18 + out * 0.55])
				_prism(fin, low + 0.3, top - 0.5, ELEK_FIN, ELEK_FIN.darkened(0.1), M_STONE, M_STONE)
	_mode = M_GLASS
	_prism(q, low, top, ELEK_OFFICE_GLASS, none, M_GLASS, M_STONE)
	_mode = M_STONE
	_prism(q, low - 0.4, low, ELEK_STEEL, none, M_STONE, M_STONE)
	_parapet(q, top, 0.8, ELEK_STEEL)
	_cap(q, top, Color("#6a6d70"))
	var c := _centre(q)
	_prism(_square(c + _b * 6.0, 2.2), top, top + 1.8, Color("#8b8e91"), Color("#9a9da0"), M_STONE, M_STONE)


## Whether the edge a→b of `q` stands against a neighbour (the passage block or the halls).
func _elek_backed(a: Vector2, b: Vector2, q: PackedVector2Array) -> bool:
	var mid := (a + b) * 0.5 + _out(q, a, b) * 1.5
	var l := _local(mid)
	if Geometry2D.is_point_in_polygon(mid, _pts(ELEK_ATRIUM)):
		return true
	return l.x > 16.0 and l.x < 45.0 and l.y > 17.0 and l.y < 66.0


## The low old wing on the embankment: brick under a pale cornice, arched windows in pale render
## surrounds on both long faces, a taller pavilion at the Leszczyńska end.
func _elek_wing(q: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var h := 6.8
	for i in q.size():
		var a := q[i]
		var b := q[(i + 1) % q.size()]
		var length := a.distance_to(b)
		if length < 20.0:
			continue
		var e := (b - a) / length
		var out := _out(q, a, b)
		var n := floori((length - 10.0) / 3.6)
		for k in n:
			var at := a + e * (9.5 + (k + 0.5) * 3.6)
			_arch_panel(at, e, out, 1.2, g + 1.0, g + 4.1, ELEK_RENDER, 0.05, M_STONE)
			_arch_panel(at, e, out, 0.85, g + 1.3, g + 4.1, ELEK_DARK_GLASS, 0.09, M_GLASS)
	_prism(q, g - 0.6, g + h, ELEK_BRICK, none, M_STONE, M_STONE)
	var top := _grown(q, 0.25)
	if top.size() >= 3:
		_prism(top, g + h - 0.7, g + h, ELEK_RENDER, ELEK_ZINC, M_STONE, M_STONE)
	# the pavilion: the wing's north end, two storeys, arched windows on its three free faces
	var pav := _lpoly([[56.9, -21.7], [65.0, -21.7], [65.0, -12.5], [57.1, -12.5]])
	_prism(pav, g + h - 0.1, g + 9.8, ELEK_BRICK, none, M_STONE, M_STONE)
	var pt := _grown(pav, 0.3)
	if pt.size() >= 3:
		_prism(pt, g + 9.1, g + 9.8, ELEK_RENDER, ELEK_ZINC.darkened(0.1), M_STONE, M_STONE)
	for fc: Array in [[61.0, -21.85, _a, -_b], [56.75, -17.1, _b, -_a], [65.15, -17.1, _b, _a]]:
		var c: Vector2 = _w(fc[0], fc[1])
		for s: float in [-1.6, 1.6]:
			_arch_panel(c + (fc[2] as Vector2) * s, fc[2], fc[3], 0.8, g + 7.0, g + 8.4, ELEK_RENDER, 0.05, M_STONE)
			_arch_panel(c + (fc[2] as Vector2) * s, fc[2], fc[3], 0.55, g + 7.2, g + 8.4, ELEK_DARK_GLASS, 0.09, M_GLASS)


## The names (parodies, warsaw-tone): ELEKTROWNIA on the Dobra gable, the food hall and the
## brewery on the yard, the shops on the plaza, the bars on the passage, the office's shops.
func _elek_signs(g: float) -> void:
	var white := Color(1.0, 0.97, 0.9)
	_usign("ELEKTROWNIA", ELEK_U0 - 0.3, 0.0, g + 16.6, -_a, 14.0, 2.0, white)
	# on the yard (north face of the hall wall, v = -17.1)
	_usign("HALA TURBIN", -26.0, -17.4, g + 4.3, -_b, 10.0, 0.9, Color(1.0, 0.8, 0.35))
	_usign("BROWAR KOMIN", 8.5, -17.4, g + 4.3, -_b, 10.0, 0.9, Color(0.95, 0.65, 0.3))
	# on the plaza (south face, v = 17.6)
	var plaza := [["ROSOMAK", -35.0, Color(0.95, 0.25, 0.3)], ["KAWA 220V", -27.0, white], ["AMPERIK", -19.0, Color(1.0, 0.55, 0.2)],
			["FAZA", -11.0, Color(1.0, 0.85, 0.5)]]
	for s: Array in plaza:
		_usign(str(s[0]), float(s[1]), 17.95, g + 4.3, _b, 6.0, 0.8, s[2])
	# on the passage (the cross wing's east face, u = 50)
	_usign("BEZPIECZNIK", 50.35, 2.0, g + 4.3, _a, 9.0, 0.8, Color(0.35, 0.8, 1.0))
	_usign("PIEROGARNIA", 50.35, 13.0, g + 4.3, _a, 9.0, 0.8, Color(1.0, 0.75, 0.3))
	_usign("ZARAZA", 44.15, -11.0, g + 4.3, _a, 6.0, 0.8, white)
	# the office's shops on its plaza face and the passage's café
	var oo := _elek_office_out()
	_usign("SPOŻYWCZAK", -12.6, 49.9, g + 4.75, oo, 9.0, 1.0, Color(0.4, 0.95, 0.5))
	_usign("WATOWNIA", -6.5, 69.8, g + ELEK_OFFICE_TOP - 2.4, oo, 12.0, 1.6, Color(1.0, 0.3, 0.25))


## The office's plaza face (its long side to Dobra) outwards, in the plan.
func _elek_office_out() -> Vector2:
	return (_a * -0.955 + _b * 0.293).normalized()


## A festoon of warm bulbs from p to q, sagging `sag` (relative to its length) in the middle: a
## thin wire seen from above and a small lit bulb (two crossed cards, M_LAMP) at every joint. The
## same look as the barges' festoons for a third of their triangles.
func _elek_festoon(p: Vector3, q: Vector3, sag: float, n: int) -> void:
	var keep := _mode
	var drop := sag * p.distance_to(q)
	var prev := p
	var side := Vector3.UP.cross(q - p).normalized() * 0.025
	for k in range(1, n + 1):
		var t := float(k) / n
		var at := p.lerp(q, t) - Vector3.UP * drop * 4.0 * t * (1.0 - t)
		_mode = M_STONE
		_quad(prev - side, at - side, at + side, prev + side, Vector3.UP, BARGE_POST)
		if k < n:
			_mode = M_LAMP
			var col := BARGE_BULB if k % 2 == 0 else BARGE_BULB_2
			var s := side.normalized() * 0.15
			var f := (q - p).normalized() * 0.15
			for d: Vector3 in [s, f]:
				var nn := d.cross(Vector3.UP).normalized()
				_quad(at - d + Vector3.DOWN * 0.32, at + d + Vector3.DOWN * 0.32, at + d, at - d, nn, col)
				_quad(at + d + Vector3.DOWN * 0.32, at - d + Vector3.DOWN * 0.32, at - d, at + d, -nn, col)
		prev = at
	_mode = keep


func _elek_xyz(u: float, v: float, h: float) -> Vector3:
	var q := _w(u, v)
	return Vector3(q.x, float(map.terrain_height(q.x, q.y)) + h, q.y)


## The face of the cross wing towards the passage at v (u of its east wall).
static func _elek_cross_face(v: float) -> float:
	return 50.0 if v > -3.3 and v < 18.7 else 43.9


## The life of the complex: the passage's granite with beer tables under zigzag festoons, the
## yard's summer bar (ZWARCIE) with umbrellas, deck chairs and festoons to posts, the setts plaza
## by Dobra with café umbrellas and benches, the painted sphere on the lawn (the photos).
func _elek_life(g: float) -> void:
	_elek_frame()
	_no_roof = true
	_mode = M_STONE
	var none := Color(0, 0, 0, 0)
	# The passage's pale granite and the plaza's setts.
	var passage := _lpoly([[44.2, -22.0], [56.6, -21.6], [56.9, 23.0], [50.3, 23.0], [50.3, -3.3], [44.2, -3.3]])
	var pg := _mean_ground(passage)
	_cap(passage, pg + 0.1, Color("#c4c1ba"))
	var plaza := _lpoly([[-40.5, 18.3], [-8.0, 18.3], [-8.0, 29.2], [-18.4, 29.8], [-16.2, 36.0], [-40.5, 36.0]])
	var zg := _mean_ground(plaza)
	_cap(plaza, zg + 0.1, Color("#8f8580"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1904
	var u := -40.0
	while u < -8.6:
		var v := 18.9
		while v < 35.4:
			if rng.randf() < 0.42 and Geometry2D.is_point_in_polygon(_w(u + 0.45, v + 0.45), plaza):
				var col: Color = ELEK_SETT[rng.randi() % ELEK_SETT.size()]
				var sq := _rect(u + 0.45, v + 0.45, 0.42, 0.42)
				_quad(Vector3(sq[0].x, zg + 0.13, sq[0].y), Vector3(sq[3].x, zg + 0.13, sq[3].y), Vector3(sq[2].x, zg + 0.13, sq[2].y),
						Vector3(sq[1].x, zg + 0.13, sq[1].y), Vector3.UP, col)
			v += 1.0
		u += 1.0
	# The passage: beer tables (along v) and festoons zigzagging from wall to wall.
	for t: Vector2 in ELEK_BEER:
		var y := pg + 0.1
		_lbox(t.x, t.y, 0.38, 1.15, y + 0.68, y + 0.76, Color("#b98a5a"), M_STONE, Color("#c99a68"))
		_lbox(t.x, t.y, 0.06, 0.85, y, y + 0.68, Color("#3b3d40"))
		for side: float in [-1.0, 1.0]:
			_lbox(t.x + side * 0.78, t.y, 0.16, 1.15, y + 0.4, y + 0.46, Color("#a87c50"), M_STONE, Color("#b98a5a"))
			_lbox(t.x + side * 0.78, t.y, 0.05, 0.8, y, y + 0.4, Color("#3b3d40"))
	var v := -20.0
	var flip := false
	while v < 21.0:
		var cu := _elek_cross_face(v) + 0.15
		var a := _elek_xyz(cu, v, 6.6)
		var b := _elek_xyz(56.7, v + 2.7, 6.2)
		if flip:
			a = _elek_xyz(cu, v + 2.7, 6.6)
			b = _elek_xyz(56.7, v, 6.2)
		_elek_festoon(a, b, 0.06, 7)
		flip = not flip
		v += 5.4
	# The yard by Leszczyńska: the summer bar, umbrella tables, deck chairs, festoons to posts.
	var bc := ELEK_BAR
	var by: float = map.terrain_height(_w(bc.x, bc.y).x, _w(bc.x, bc.y).y)
	_lbox(bc.x, bc.y, 3.0, 1.2, by - 0.2, by + 2.6, Color("#b8412f"), M_STONE, Color("#8f3324"))
	_lbox(bc.x, bc.y + 1.55, 2.6, 0.3, by, by + 1.1, Color("#6b4a2e"), M_STONE, Color("#c99a68"))
	var fa := _elek_xyz(bc.x - 3.0, bc.y + 1.2, 2.55)
	var fb := _elek_xyz(bc.x + 3.0, bc.y + 1.2, 2.55)
	var fc := _elek_xyz(bc.x + 3.0, bc.y + 2.7, 2.15)
	var fd := _elek_xyz(bc.x - 3.0, bc.y + 2.7, 2.15)
	_two_sided(fa, fb, fc, fd, Color("#e8dcc0"))
	_lbox(bc.x, bc.y, 2.6, 0.06, by + 2.6, by + 3.6, Color("#2b2c2f"), M_STONE, Color("#2b2c2f"))
	_usign("ZWARCIE", bc.x, bc.y + 0.1, by + 2.75, _b, 4.6, 0.8, Color(1.0, 0.85, 0.3))
	_usign("ZWARCIE", bc.x, bc.y - 0.1, by + 2.75, -_b, 4.6, 0.8, Color(1.0, 0.85, 0.3))
	var umb := [Color("#efe7d6"), Color("#c8553d"), Color("#efe7d6"), Color("#2f6f5e")]
	var i := 0
	for t: Vector2 in ELEK_YARD_UMB + ELEK_PLAZA_UMB:
		var p := _w(t.x, t.y)
		_barge_umbrella(t.x, t.y, map.terrain_height(p.x, p.y), 1.5, umb[i % umb.size()])
		for side: float in [-1.0, 1.0]:
			var s := _w(t.x, t.y + side * 0.8)
			_lbox(t.x, t.y + side * 0.8, 0.2, 0.2, map.terrain_height(s.x, s.y), map.terrain_height(s.x, s.y) + 0.45,
					Color("#3b3d40"), M_STONE, Color("#55585c"))
		i += 1
	var stripes := [Color("#2f8fd4"), Color("#e9e4d8"), Color("#d9542f")]
	i = 0
	for c: Vector2 in ELEK_LEZAK:
		var p := _w(c.x, c.y)
		_bulwar_lezak(c.x, c.y, map.terrain_height(p.x, p.y), stripes[i % stripes.size()], -1.0)
		i += 1
	var posts: Array[Vector3] = []
	for pu: float in [-30.0, -19.0, -8.0, 3.0, 14.0]:
		var foot := _elek_xyz(pu, -38.5, 0.0)
		var top := foot + Vector3.UP * 4.3
		_beam(foot + Vector3.DOWN * 0.3, top, 0.12, BARGE_POST)
		posts.append(top)
		_elek_festoon(_elek_xyz(pu, -17.5, 7.4), top, 0.05, 8)
	for k in posts.size() - 1:
		_elek_festoon(posts[k], posts[k + 1], 0.04, 6)
	# The plaza: two festoons from the hall to posts, two long benches.
	for pu: float in [-32.0, -21.0]:
		var foot := _elek_xyz(pu, 31.5, 0.0)
		var top := foot + Vector3.UP * 4.3
		_beam(foot + Vector3.DOWN * 0.3, top, 0.12, BARGE_POST)
		_elek_festoon(_elek_xyz(pu, 17.9, 7.4), top, 0.05, 7)
	for bu: float in [-36.0, -26.0]:
		var p := _w(bu, 33.5)
		var y: float = map.terrain_height(p.x, p.y)
		_lbox(bu, 33.5, 2.4, 0.35, y - 0.1, y + 0.42, Color("#9c9a95"), M_STONE, Color("#a87c50"))
	# The painted sphere on the lawn by the yard (a white ball with red and blue bands).
	var sp := _w(ELEK_SPHERE.x, ELEK_SPHERE.y)
	var sy: float = map.terrain_height(sp.x, sp.y)
	_prism(_circle(sp, 0.5, 8), sy - 0.1, sy + 0.55, Color("#8e8c88"), Color("#9b9994"), M_STONE, M_STONE)
	var r := 1.3
	var cy: float = sy + 0.55 + r
	var prev := _circle(sp, 0.25, 10)
	var prev_y: float = sy + 0.55 + 0.03
	for k in range(1, 7):
		var ang := -PI * 0.5 + PI * k / 6.0
		var ring := _circle(sp, maxf(cos(ang) * r, 0.05), 10)
		var y: float = cy + sin(ang) * r
		var col := Color("#f0ede6")
		if k == 3:
			col = Color("#c8323a")
		elif k == 4:
			col = Color("#2f6fb4")
		_frustum(prev, prev_y, ring, y, col, Color("#f0ede6") if k == 6 else none)
		prev = ring
		prev_y = y
	_no_roof = false
	_mode = M_STONE


## Rotunda Dynasy (F's photo set 2026-11-09, Mac powisle/X-Dynasy): the round block of flats on
## the old panorama's site at Dynasy 22, its mapped round outline: a two-storey brick base with dark
## shop glass, six storeys of glass behind white concrete frames (a slab and a band of fins each
## floor), the top two set back with terraces, a flat roof.
const RDYN_BRICK := Color("#9a5a44")
const RDYN_WHITE := Color("#e6e5e0")
const RDYN_GLASS := Color("#7f98a2")
const RDYN_BASE := 7.0
const RDYN_FLOOR := 3.2


func _build_rotunda_dynasy(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_prism(ring, g - 0.6, g + RDYN_BASE, RDYN_BRICK, none, M_STONE, M_STONE)
	var y := g + RDYN_BASE
	for k in 6:
		var inset := 0.6 if k < 4 else 2.6
		var slab := _largest(Geometry2D.offset_polygon(ring, 0.3 - (inset - 0.6), Geometry2D.JOIN_MITER))
		var glass := _largest(Geometry2D.offset_polygon(ring, -inset, Geometry2D.JOIN_MITER))
		if slab.size() < 3 or glass.size() < 3:
			break
		_prism(slab, y, y + 0.35, RDYN_WHITE, RDYN_WHITE, M_STONE, M_STONE)
		_mode = M_GLASS
		_prism(glass, y + 0.35, y + RDYN_FLOOR, RDYN_GLASS, none, M_GLASS, M_STONE)
		_mode = M_STONE
		y += RDYN_FLOOR
	var top := _largest(Geometry2D.offset_polygon(ring, -2.3, Geometry2D.JOIN_MITER))
	if top.size() >= 3:
		_prism(top, y, y + 0.5, RDYN_WHITE, RDYN_WHITE.darkened(0.15), M_STONE, M_STONE)
	_collide(ring)
