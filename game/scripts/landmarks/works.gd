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
	# Torwar: the hall's outline and the entrance block with the portico in front of it (the map's
	# own outlines there are dropped; the street block draws the mass, _build_torwar the rest).
	var torwar := _landmark("Torwar")
	if torwar.size() >= 3:
		_add_site("torwar", [torwar, PackedVector2Array([_tw_w(-22.0, -30.0), _tw_w(22.0, -30.0), _tw_w(22.0, 12.0),
				_tw_w(-22.0, 12.0)])])
		if sites[-1]["key"] == "torwar":
			sites[-1]["ring"] = torwar
	# Dom Chłopa: its outline (the street block blk_2250406 draws the mass, _build_dom_chlopa the
	# wavy roof edge and the signs)
	var dch := _landmark("Dom Chłopa")
	if dch.size() >= 3:
		_add_site("dom_chlopa", [dch])
		if sites[-1]["key"] == "dom_chlopa":
			sites[-1]["ring"] = dch
	# Żyletkowiec (Marszałkowska 82): its outline (the street block blk_30241286 draws the mass,
	# _build_zyletkowiec the fins, the piers and the roof lid)
	var zyl := _landmark("Żyletkowiec")
	if zyl.size() >= 3:
		_add_site("zyletkowiec", [zyl])
		if sites[-1]["key"] == "zyletkowiec":
			sites[-1]["ring"] = zyl
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
	# The frontispiece between the pylons, its rusticated foot, and the gable over it: its edges
	# climb in small steps from the pylons to the cartouche, the highest point of the front.
	_lbox(0.0, 0.1, 4.5, 0.2, g - 0.5, g + 9.9, KOS_STONE, M_STONE, KOS_STONE)
	_lbox(0.0, 0.2, 4.5, 0.2, g - 0.5, g + 1.8, KOS_BASE, M_STONE, KOS_BASE)
	var hu := 3.9
	var y := 9.9
	while hu > 1.4:
		_lbox(0.0, 0.1, hu, 0.2, g + y, g + y + 0.45, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(0.0, 0.18, hu + 0.12, 0.2, g + y + 0.33, g + y + 0.45, KOS_STONE.lightened(0.05), M_STONE, KOS_STONE)
		hu -= 0.6
		y += 0.45
	_lbox(0.0, 0.25, 0.9, 0.25, g + 11.4, g + 13.0, KOS_STONE.lightened(0.06), M_STONE, KOS_STONE)
	_lbox(0.0, 0.25, 1.3, 0.3, g + 11.4, g + 11.9, KOS_STONE.lightened(0.03), M_STONE, KOS_STONE)
	# The pylons, lower than the cartouche: stone, a rusticated foot, a tall red brick panel up the
	# face, a rounded cap (two steps).
	for side: float in [-1.0, 1.0]:
		var pu := side * 5.45
		_lbox(pu, 0.15, 0.95, 0.35, g - 0.5, g + 10.8, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(pu, 0.2, 1.05, 0.42, g - 0.5, g + 3.0, KOS_BASE, M_STONE, KOS_BASE)
		_lbox(pu, 0.53, 0.65, 0.05, g + 5.4, g + 10.4, KOS_RED, M_STONE, KOS_RED)
		_lbox(pu, 0.2, 1.05, 0.42, g + 10.8, g + 11.2, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(pu, 0.2, 0.7, 0.35, g + 11.2, g + 11.6, KOS_STONE.lightened(0.04), M_STONE, KOS_STONE)
	# The big arch: a stone ring, the green-framed glass, two stone mullions, two green transoms.
	var at := _w(0.0, 0.3)
	_arch_panel(at, _a, _b, 4.5, g + 5.4, g + 6.4, KOS_STONE.lightened(0.04), 0.04, M_STONE)
	_arch_panel(at, _a, _b, 4.0, g + 5.6, g + 6.4, KOS_GLASS, 0.14, M_GLASS)
	for mu: float in [-1.35, 1.35]:
		_lbox(mu, 0.53, 0.16, 0.05, g + 5.6, g + 10.1, KOS_STONE, M_STONE, KOS_STONE)
	for ty: float in [7.4, 8.9]:
		var tw := sqrt(maxf(4.0 * 4.0 - pow(maxf(ty - 6.4, 0.0), 2.0), 0.0)) - 0.1
		_lbox(0.0, 0.52, tw, 0.03, g + ty, g + ty + 0.12, KOS_GREEN, M_STONE, KOS_GREEN)
	# The balcony under the arch: a stone ledge and the green railing.
	_lbox(0.0, 0.5, 4.5, 0.2, g + 5.0, g + 5.6, KOS_STONE.darkened(0.04), M_STONE, KOS_STONE)
	_lbox(0.0, 0.66, 4.0, 0.03, g + 5.6, g + 6.3, KOS_GREEN, M_STONE, KOS_GREEN)
	# The ground floor: the door in a stone surround, a shop window either side, a lintel over them.
	_arch_panel(at, _a, _b, 0.95, g + 0.0, g + 2.9, KOS_DOOR, 0.12, M_STONE)
	for side: float in [-1.0, 1.0]:
		_lbox(side * 1.5, 0.45, 0.3, 0.15, g - 0.5, g + 5.0, KOS_STONE, M_STONE, KOS_STONE)
		_lbox(side * 2.95, 0.4, 1.05, 0.03, g + 0.3, g + 4.2, KOS_GLASS, M_GLASS, KOS_GLASS)
		_lbox(side * 2.95, 0.43, 1.1, 0.03, g + 4.2, g + 4.35, KOS_GREEN, M_STONE, KOS_GREEN)
	_lbox(0.0, 0.42, 4.5, 0.15, g + 4.35, g + 5.0, KOS_STONE, M_STONE, KOS_STONE)
	_collide(_rect(0.0, 0.3, 6.4, 0.4))


## The forecourt (F's photos 2026-11-15, from above and from the street): a dark steel canopy on
## thin black posts runs round all four sides of the paved yard, along the street and in front of
## the brick wings and the hall; two strings of festoon bulbs cross the yard from canopy to canopy,
## lit at night (the night photo); KOSZYKI in blue neon over the hall's door.
const KOS_YARD := [21.8, 59.3, 4.9, 21.6]   ## u0, u1, v0, v1 of the paved yard
const KOS_CANOPY := Color("#3b4044")
const KOS_POST := Color("#1f2326")


func _koszyki_terrace(g: float) -> void:
	_mode = M_STONE
	var u0: float = KOS_YARD[0]
	var u1: float = KOS_YARD[1]
	var v0: float = KOS_YARD[2]
	var v1: float = KOS_YARD[3]
	var d := 2.6   # the canopy's depth
	var y0 := g + 3.4
	var y1 := g + 3.65
	# The four strips: [u0, u1, v0, v1]; the street's runs in front of the yard's mouth.
	var strips := [[u0, u1, v0 - 3.6, v0 - 1.0], [u0, u0 + d, v0 - 1.0, v1], [u1 - d, u1, v0 - 1.0, v1],
			[u0 + d, u1 - d, v1 - d, v1]]
	for st: Array in strips:
		var a0: float = st[0]
		var a1: float = st[1]
		var b0: float = st[2]
		var b1: float = st[3]
		_prism(PackedVector2Array([_kos_w(a0, b0), _kos_w(a1, b0), _kos_w(a1, b1), _kos_w(a0, b1)]), y0, y1,
				KOS_CANOPY, KOS_CANOPY, M_STONE, M_STONE)
		# One row of posts down the strip's middle, about every 4.6 m.
		var along_u := (a1 - a0) > (b1 - b0)
		var length := (a1 - a0) if along_u else (b1 - b0)
		var n := maxi(2, roundi(length / 4.6) + 1)
		for k in n:
			var t := 0.4 + (length - 0.8) * float(k) / float(n - 1)
			var pu := (a0 + t) if along_u else (a0 + a1) * 0.5
			var pv := (b0 + b1) * 0.5 if along_u else (b0 + t)
			_prism(_circle(_kos_w(pu, pv), 0.08, 4), g, y0, KOS_POST, KOS_POST, M_STONE, M_STONE)
	# The festoons: a wire from the west canopy's edge to the east one's, sagging through the bulbs.
	var w0 := u0 + d
	var w1 := u1 - d
	for v: float in [9.5, 15.5]:
		var pts: Array[Vector3] = []
		var u := w0
		while u < w1 - 0.5:
			var q := _kos_w(u, v)
			pts.append(Vector3(q.x, y0 - 0.02 - 0.4 * sin(PI * (u - w0) / (w1 - w0)), q.y))
			u += 2.4
		var e := _kos_w(w1, v)
		pts.append(Vector3(e.x, y0 - 0.02, e.y))
		var side := Vector2(-KOS_A.y, KOS_A.x) * 0.03
		for i in range(pts.size() - 1):
			var a := Vector2(pts[i].x, pts[i].z)
			var c := Vector2(pts[i + 1].x, pts[i + 1].z)
			var wy := (pts[i].y + pts[i + 1].y) * 0.5
			_prism(PackedVector2Array([a - side, c - side, c + side, a + side]), wy - 0.03, wy + 0.03,
					KOS_POST, KOS_POST, M_STONE, M_STONE)
			if i > 0:
				_prism(_circle(a, 0.13, 4), pts[i].y - 0.13, pts[i].y + 0.13, KOS_BULB, KOS_BULB, M_LAMP, M_LAMP)
	var at := _kos_w(40.3, 21.0)
	var out := -Vector2(-KOS_A.y, KOS_A.x)
	signs.append(["KOSZYKI", Vector3(at.x, g + 6.0, at.y), Vector3(out.x, 0.0, out.y),
			7.5 / Neon.length_of("KOSZYKI"), Color(0.35, 0.7, 1.0)])


## Torwar (Łazienkowska 6a, 2026-11-15, spec docs/landmarks/specs/torwar.md; photos: F's T45 set
## in the shared store, Mapillary and Panoramax frames round the hall in refs/torwar/street, never
## shipped). The hall's mass is its street block (blk_25844922: the cream hall, the brick annexes,
## the white entrance block with its glass front, measured); this site dresses it with what the
## photos show and the block lacks: on Łazienkowska the white portico (twelve slender columns, the
## deep entablature with TORWAR on it and the curved parapet over the middle), and round the hall
## the white pilasters, the lattice panels in the upper windows and the cornice. Every part is in
## the entrance's frame: u along the front (east +), v out to the street (south +), v 0 on the
## block's glass; heights over the block's own ground (the lowest under the hall), so they meet
## the block's (the forecourt stands about 2 m higher: the columns start on it).
const TW_O := Vector2(1240.45, 1341.81)
const TW_A := Vector2(0.99774, 0.06733)
const TW_FRONT := [-21.6, 21.6, 1.8, 4.6]   ## the entablature's u0, u1, v0, v1
const TW_COLS := 12                          ## the portico's columns, 3.3 m apart (T45-01)
const TW_WHITE := Color("#eeede6")
const TW_COLUMN := Color("#e8e7e0")
const TW_LETTER := Color("#6f757b")
const TW_PILASTER := Color("#f0ece0")
const TW_LATTICE := Color("#d8d6cc")
const TW_LATTICE_IN := Color("#8f948f")
## The hall's long walls (the block's, measured): u of the wall at v -128.7 and at v -46 per side,
## the windows' centres (ten a side, 9.2 m apart, 5.5 m wide, 6.5 to 11.5 m) and the north gable.
const TW_EAST := [39.5, 40.05]
const TW_WEST := [-39.3, -39.6]
const TW_NORTH_V := -133.0


func _tw_w(u: float, v: float) -> Vector2:
	return TW_O + TW_A * u + Vector2(-TW_A.y, TW_A.x) * v


func _build_torwar(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_b = Vector2(-TW_A.y, TW_A.x)
	_a = TW_A
	_o = TW_O
	_mode = M_STONE
	_torwar_portico(g)
	for side: float in [-1.0, 1.0]:
		_torwar_side(g, side)
	_torwar_north(g)
	# The entrance block and the portico stop the car (the map's own outlines there are dropped).
	_collide(_urect(TW_FRONT[0], TW_FRONT[1], -29.5, 4.0))


## The portico (T45-01, straight on): a deep white entablature over the whole front, its top at
## the block's own top band; TORWAR in grey letters across its face (lit white at night); the
## curved parapet rising over its middle; twelve round white columns from the forecourt.
func _torwar_portico(g: float) -> void:
	var u0: float = TW_FRONT[0]
	var u1: float = TW_FRONT[1]
	var v0: float = TW_FRONT[2]
	var vf: float = TW_FRONT[3]
	var y0 := g + 13.3
	var top := g + 15.9
	_ubox(u0, u1, v0, vf, y0, top, TW_WHITE, M_STONE, TW_WHITE.darkened(0.06))
	_soffit(_urect(u0, u1, v0, vf), y0, TW_WHITE.darkened(0.18))
	# The columns, from the forecourt (about 2 m over the block's ground) to the entablature.
	var gf: float = map.terrain_height(_w(0.0, 3.4).x, _w(0.0, 3.4).y)
	var pitch := 3.3
	for k in TW_COLS:
		var cu := (float(k) - (TW_COLS - 1) * 0.5) * pitch
		_prism(_circle(_w(cu, 3.4), 0.36, 8), gf - 0.4, y0 + 0.05, TW_COLUMN, TW_COLUMN, M_STONE, M_STONE)
	# The curved parapet over the middle, flush with the entablature's face and as deep as it:
	# a low crown 2.5 m over the top. It is as wide as the block's own arc behind it (22 m, to
	# 18.2 m, with the block's dark letters on it), which it must hide; T45-01 shows it a little
	# narrower (not built: two arcs read as a fault).
	var aw := 12.2
	var n := 24
	var prof: Array[Vector2] = []
	for k in n + 1:
		var u := -aw + 2.0 * aw * float(k) / float(n)
		var t := absf(u) / aw
		prof.append(Vector2(u, top + 2.5 * pow(maxf(1.0 - t * t, 0.0), 0.6)))
	var vb := v0 - 0.08
	for face: float in [vf, vb]:
		var nrm := Vector3(_b.x, 0.0, _b.y) * (1.0 if face == vf else -1.0)
		var base := _w(0.0, face)
		for k in n:
			var p0 := _w(prof[k].x, face)
			var p1 := _w(prof[k + 1].x, face)
			_tri(Vector3(base.x, top, base.y), Vector3(p0.x, prof[k].y, p0.y), Vector3(p1.x, prof[k + 1].y, p1.y),
					nrm, TW_WHITE, Vector2(aw, top - g), Vector2(prof[k].x + aw, prof[k].y - g),
					Vector2(prof[k + 1].x + aw, prof[k + 1].y - g), top + 2.5 - g)
	for k in n:
		var d := prof[k + 1] - prof[k]
		var up := Vector2(-d.y, d.x).normalized()
		var nrm := Vector3(_a.x * up.x, up.y, _a.y * up.x)
		var a0 := _w(prof[k].x, vf)
		var a1 := _w(prof[k + 1].x, vf)
		var b0 := _w(prof[k].x, vb)
		var b1 := _w(prof[k + 1].x, vb)
		_quad(Vector3(a0.x, prof[k].y, a0.y), Vector3(a1.x, prof[k + 1].y, a1.y), Vector3(b1.x, prof[k + 1].y, b1.y),
				Vector3(b0.x, prof[k].y, b0.y), nrm, TW_WHITE.darkened(0.04))
	# TORWAR: pixel letters on the entablature's face (wider than tall, as on the hall), each
	# row's runs one face; grey by day, lit at night (M_LAMP).
	var word := "TORWAR"
	var pu := 0.26
	var py := 0.17
	var us := -PixelFont.width(word) * pu * 0.5
	var y_top := g + 15.2
	var rows := {}
	PixelFont.each_pixel(word, 0, func(x: int, row: int) -> void:
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(x))
	_mode = M_LAMP
	for row: int in rows:
		var xs: Array = rows[row]
		xs.sort()
		var s0: int = xs[0]
		var prev: int = xs[0]
		for idx in range(1, xs.size() + 1):
			var x: int = xs[idx] if idx < xs.size() else -999
			if x == prev + 1:
				prev = x
				continue
			var y := y_top - float(row - PixelFont.BODY + 1) * py
			_buw_face(_w(us + s0 * pu, vf + 0.06), _w(us + (prev + 1) * pu, vf + 0.06), y - py, y, _b, TW_LETTER)
			s0 = x
			prev = x
	_mode = M_STONE


## One long side of the hall (`side` -1 west, +1 east), over the block's cream wall: a white
## pilaster between each pair of its ten upper windows and at both corners, a grey lattice panel
## in the middle of each window (the glass shows either side of it), a white cornice along the
## eaves (the street photos from the east car park and from Trasa Łazienkowska).
func _torwar_side(g: float, side: float) -> void:
	var ends: Array = TW_EAST if side > 0.0 else TW_WEST
	var wall := func(v: float) -> float:
		return lerpf(ends[0], ends[1], (v + 128.7) / 82.7)
	var out := _a * side
	var vs: Array[float] = [-38.2, -132.3]
	for k in 9:
		vs.append(-47.75 - 9.2 * float(k))
	for v: float in vs:
		_lbox(wall.call(v) + side * 0.15, v, 0.3, 0.7, g - 0.5, g + 12.6, TW_PILASTER, M_STONE, TW_PILASTER)
	for k in 10:
		var v := -43.2 - 9.2 * float(k)
		var u: float = wall.call(v)
		_lbox(u + side * 0.05, v, 0.12, 1.6, g + 6.7, g + 11.3, TW_LATTICE, M_STONE, TW_LATTICE)
		_buw_face(_w(u + side * 0.2, v - 1.35 * side), _w(u + side * 0.2, v + 1.35 * side), g + 7.0, g + 11.0, out, TW_LATTICE_IN)
	var mid: float = (wall.call(-37.5) + wall.call(TW_NORTH_V)) * 0.5
	_lbox(mid + side * 0.2, (-37.5 + TW_NORTH_V) * 0.5 - 0.3, 0.75, (-37.5 - TW_NORTH_V) * 0.5 + 0.3, g + 12.5,
			g + 13.4, TW_PILASTER, M_STONE, TW_PILASTER.darkened(0.05))


## The north gable on Trasa Łazienkowska (the Panoramax frames from the viaduct): eleven white
## pilasters, a lattice panel in each bay, the cornice across.
func _torwar_north(g: float) -> void:
	var v := TW_NORTH_V
	for k in 11:
		_lbox(-39.2 + 7.84 * float(k), v - 0.15, 0.7, 0.3, g - 0.5, g + 12.6, TW_PILASTER, M_STONE, TW_PILASTER)
	for k in 10:
		var u := -35.28 + 7.84 * float(k)
		_lbox(u, v - 0.05, 1.5, 0.12, g + 6.7, g + 11.3, TW_LATTICE, M_STONE, TW_LATTICE)
		_buw_face(_w(u + 1.25, v - 0.2), _w(u - 1.25, v - 0.2), g + 7.0, g + 11.0, -_b, TW_LATTICE_IN)
	_lbox(0.0, v - 0.2, 40.6, 0.55, g + 12.5, g + 13.4, TW_PILASTER, M_STONE, TW_PILASTER.darkened(0.05))


## NBP's regional branch (Oddział Okręgowy, Plac Powstańców Warszawy 4; 2026-11-16, spec
## docs/landmarks/specs/nbp.md; photos: F's T13 set and refs/nbp_oddzial/street). A long, low
## block whose 133 m front on the square is dark brown-grey metal panels in three bands, each
## leaning out over the one below and the top one curving out over the square. Under them the
## glass ground floor stands back on a terrace up a wide flight of granite steps, with a white
## wall bearing the eagle and NBP left of the doors and a narrow glazed stair slot right of
## them; the rest of the front stands on a rough stone plinth wall with wooden planters. The
## whole building is ours (SKINS `model`, it replaces LoD2's beige block); the frame's u runs
## south along the front from its north-west corner, v out over the square.
const NBP_O := Vector2(-703.2, -225.0)
const NBP_A := Vector2(0.32948, 0.94416)
const NBP_LEN := 133.24
## the mass, LoD2's footprint (GUGiK) simplified; the last edge is the front. The roof is 14 m
## over the square (LoD2 24-28 m, the square at 11.3 m)
const NBP_RING := [Vector2(-703.2, -225.0), Vector2(-675.5, -234.3), Vector2(-671.1, -223.9), Vector2(-644.5, -151.7),
		Vector2(-633.5, -115.6), Vector2(-630.9, -109.4), Vector2(-659.3, -99.2)]
const NBP_TOP := 14.0
const NBP_PANEL := Color("#4d4446")
const NBP_JOINT := Color("#625a5c")
const NBP_SHADOW := Color("#2f2a2b")
const NBP_ROOF := Color("#6f7173")
const NBP_STONE := Color("#b9b2a5")    # the rough plinth wall
const NBP_GRANITE := Color("#a9a7a1")  # the steps and the terrace
const NBP_GLASS := Color("#5d6f78")
const NBP_FRAME := Color("#c9cbc8")
const NBP_WHITE := Color("#eeeeea")
const NBP_LETTER := Color("#8a8d90")
const NBP_WOOD := Color("#b08a5e")
const NBP_GREEN := Color("#6f8f4a")
## along the front (u): the terrace, the steps up to it, the white wall, the stair slot
const NBP_TERRACE := Vector2(26.0, 84.0)
const NBP_STEPS := Vector2(30.0, 80.0)
const NBP_PLAQUE := Vector2(40.0, 50.0)
const NBP_SLOT := Vector2(57.0, 60.5)
## the front's profile over the ground floor, (height over the square, v): three bands, each
## leaning out with a lip over the next, the top one curving out to the roof's edge
const NBP_PROFILE := [Vector2(5.6, 0.2), Vector2(8.5, 0.6), Vector2(8.5, 0.35), Vector2(11.3, 0.95), Vector2(11.3, 0.7),
		Vector2(12.6, 1.15), Vector2(13.5, 1.6), Vector2(14.0, 1.75), Vector2(14.0, 0.0)]
## the eagle on the white wall, rows from the top
const NBP_EAGLE := ["...X.X...", "X..XXX..X", "XX.XXX.XX", "XXXXXXXXX", ".XXXXXXX.", "...XXX...", "..XX.XX..", ".X.....X."]


func _build_nbp(_site: Dictionary) -> void:
	_o = NBP_O
	_a = NBP_A
	_b = Vector2(-NBP_A.y, NBP_A.x)
	var ring := PackedVector2Array(NBP_RING)
	var lo := _ground_under(ring) - 0.6
	# the square's level in front of the steps
	var gf := 0.0
	for k in 6:
		var p := _w(30.0 + 10.0 * k, 5.0)
		gf += map.terrain_height(p.x, p.y)
	gf /= 6.0
	_g = gf
	_mode = M_STONE
	var top := gf + NBP_TOP
	# --- the mass: dark panels round the back and the ends (seams where the front's bands
	# meet), the flat roof, two plant rooms at the ends
	var n := ring.size()
	for k in n - 1:
		var p: Vector2 = ring[k]
		var q: Vector2 = ring[k + 1]
		var out := _out(ring, p, q)
		_wall(p, q, lo, top, out, NBP_PANEL)
		for h: float in [5.6, 8.5, 11.3]:
			_buw_face(p + out * 0.03, q + out * 0.03, gf + h - 0.14, gf + h, out, NBP_SHADOW)
	_cap(ring, top, NBP_ROOF)
	_ubox(2.0, 11.0, -22.0, -6.0, top, top + 2.2, NBP_ROOF.lightened(0.15))
	_ubox(121.0, 130.0, -22.0, -6.0, top, top + 2.2, NBP_ROOF.lightened(0.15))
	_nbp_front(gf, lo)
	_collide(ring)
	_collide(_urect(0.0, NBP_LEN, -1.0, 0.5))
	_collide(_urect(NBP_TERRACE.x, NBP_TERRACE.y, -1.0, 3.9))


## The front on the square: the bands either side of the stair slot, the slot, the glass ground
## floor on its terrace with the white wall, the steps, and the plinth wall with its planters.
func _nbp_front(gf: float, lo: float) -> void:
	var a3 := Vector3(_a.x, 0.0, _a.y)
	var deck := gf + 1.8
	var t0 := NBP_TERRACE.x
	var t1 := NBP_TERRACE.y
	_nbp_bands(0.0, NBP_SLOT.x, gf)
	_nbp_bands(NBP_SLOT.y, NBP_LEN, gf)
	# the bands' ends, the slot's cheeks back to its glass
	_nbp_cheek(0.0, -a3, 0.0, gf)
	_nbp_cheek(NBP_LEN, a3, 0.0, gf)
	_nbp_cheek(NBP_SLOT.x, a3, -1.0, gf)
	_nbp_cheek(NBP_SLOT.y, -a3, -1.0, gf)
	# --- the stair slot: glass from the ground floor's top to the roof, light frames
	_mode = M_GLASS
	_buw_face(_w(NBP_SLOT.x, -1.0), _w(NBP_SLOT.y, -1.0), gf + 5.6, gf + NBP_TOP, _b, NBP_GLASS)
	_mode = M_STONE
	for k in 2:
		var u := NBP_SLOT.x + (NBP_SLOT.y - NBP_SLOT.x) * float(k + 1) / 3.0
		_buw_face(_w(u - 0.05, -0.97), _w(u + 0.05, -0.97), gf + 5.6, gf + NBP_TOP, _b, NBP_FRAME)
	for h: float in [8.4, 11.2]:
		_buw_face(_w(NBP_SLOT.x, -0.96), _w(NBP_SLOT.y, -0.96), gf + h - 0.08, gf + h + 0.08, _b, NBP_FRAME)
	# --- the terrace: granite to the glass, the glass ground floor in light frames, the bands'
	# dark soffit over it and dark ends
	_ubox(t0, t1, -2.6, 0.0, lo, deck, NBP_GRANITE)
	_mode = M_GLASS
	_buw_face(_w(t0, -2.6), _w(NBP_PLAQUE.x, -2.6), deck, gf + 5.6, _b, NBP_GLASS)
	_buw_face(_w(NBP_PLAQUE.y, -2.6), _w(t1, -2.6), deck, gf + 5.6, _b, NBP_GLASS)
	_mode = M_STONE
	var u := t0 + 1.6
	while u < t1 - 0.5:
		if u < NBP_PLAQUE.x - 0.1 or u > NBP_PLAQUE.y + 0.1:
			_buw_face(_w(u - 0.05, -2.57), _w(u + 0.05, -2.57), deck, gf + 5.6, _b, NBP_FRAME)
		u += 1.6
	_buw_face(_w(t0, -2.57), _w(t1, -2.57), gf + 4.9, gf + 5.0, _b, NBP_FRAME)
	_soffit(_urect(t0, t1, -2.6, 0.2), gf + 5.6, NBP_SHADOW)
	# (the strip over the plinth's end only above the stone, which closes it below: no overlap)
	_buw_face(_w(t0, -2.6), _w(t0, 0.0), deck, gf + 5.6, _a, NBP_PANEL)
	_buw_face(_w(t0, 0.0), _w(t0, 0.2), gf + 3.0, gf + 5.6, _a, NBP_PANEL)
	_buw_face(_w(t1, 0.0), _w(t1, -2.6), deck, gf + 5.6, -_a, NBP_PANEL)
	_buw_face(_w(t1, 0.2), _w(t1, 0.0), gf + 3.0, gf + 5.6, -_a, NBP_PANEL)
	# the white wall left of the doors: the eagle and NBP in grey
	_ubox(NBP_PLAQUE.x, NBP_PLAQUE.y, -2.6, -2.3, deck, gf + 5.6, NBP_WHITE)
	var rows := {}
	for r in NBP_EAGLE.size():
		var line: String = NBP_EAGLE[r]
		var xs: Array = []
		for x in line.length():
			if line[x] == "X":
				xs.append(x)
		rows[r] = xs
	_nbp_pixels(rows, NBP_PLAQUE.x + 0.9, 0.18, 0.17, gf + 4.75, -2.27, NBP_LETTER)
	rows = {}
	PixelFont.each_pixel("NBP", 0, func(x: int, row: int) -> void:
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(x))
	var lrows := {}
	for row: int in rows:
		lrows[row - PixelFont.BODY] = rows[row]
	_nbp_pixels(lrows, NBP_PLAQUE.x + 3.2, 0.3, 0.19, gf + 4.65, -2.27, NBP_LETTER)
	# --- the steps: nine granite steps from the square up to the terrace, solid blocks at the
	# flight's ends, three handrails
	for k in 9:
		_ubox(NBP_STEPS.x, NBP_STEPS.y, 0.42 * float(k), 0.42 * float(k + 1), lo, deck - 0.2 * float(k),
				NBP_GRANITE, M_STONE, NBP_GRANITE.lightened(0.04 if k % 2 == 0 else 0.0))
	_ubox(t0, NBP_STEPS.x, 0.0, 3.9, lo, deck + 0.9, NBP_GRANITE.darkened(0.06))
	_ubox(NBP_STEPS.y, t1, 0.0, 3.9, lo, deck + 0.9, NBP_GRANITE.darkened(0.06))
	for ur: float in [42.0, 55.0, 68.0]:
		for side: float in [-1.0, 1.0]:
			var p0 := _w(ur + side * 0.03, 0.2)
			var p1 := _w(ur + side * 0.03, 3.7)
			_quad(Vector3(p0.x, deck + 0.75, p0.y), Vector3(p1.x, gf + 0.95, p1.y), Vector3(p1.x, gf + 1.05, p1.y),
					Vector3(p0.x, deck + 0.85, p0.y), a3 * side, NBP_FRAME)
	# --- the plinth: rough stone either side of the terrace, the panels' dark foot above it,
	# wooden planters with small trees along the south stretch
	for span: Vector2 in [Vector2(0.0, t0), Vector2(t1, NBP_LEN)]:
		_ubox(span.x, span.y, 0.0, 0.5, lo, gf + 3.0, NBP_STONE, M_STONE, NBP_STONE.darkened(0.08))
		_wall(_w(span.x, 0.2), _w(span.y, 0.2), gf + 3.0, gf + 5.6, _b, NBP_PANEL)
	for k in 6:
		var up := 92.0 + 7.0 * float(k)
		var c := _w(up, 1.5)
		var gp: float = map.terrain_height(c.x, c.y)
		_ubox(up - 0.6, up + 0.6, 0.9, 2.1, gp - 0.2, gp + 0.9, NBP_WOOD, M_STONE, NBP_WOOD.darkened(0.25))
		_prism(_circle(c, 0.75, 6), gp + 1.2, gp + 2.6, NBP_GREEN, NBP_GREEN.lightened(0.12), M_STONE, M_STONE)


## One stretch of the panel bands (NBP_PROFILE) from u0 to u1, each band a shade lighter than the
## one below (they catch more sky, T13-01), with a lighter seam every ~4 m.
func _nbp_bands(u0: float, u1: float, gf: float) -> void:
	for k in NBP_PROFILE.size() - 1:
		var p: Vector2 = NBP_PROFILE[k]
		var q: Vector2 = NBP_PROFILE[k + 1]
		var nl := Vector2(q.x - p.x, -(q.y - p.y)).normalized()  # the face's normal: (out, up)
		var n := Vector3(_b.x * nl.x, nl.y, _b.y * nl.x)
		var a0 := _w(u0, p.y)
		var a1 := _w(u1, p.y)
		var b0 := _w(u0, q.y)
		var b1 := _w(u1, q.y)
		var tall := q.x - p.x
		_quad(Vector3(a0.x, gf + p.x, a0.y), Vector3(a1.x, gf + p.x, a1.y), Vector3(b1.x, gf + q.x, b1.y),
				Vector3(b0.x, gf + q.x, b0.y), n, NBP_PANEL.lightened(0.012 * (p.x - 5.6)) if tall > 0.01 else NBP_JOINT)
		if tall < 1.0:
			continue
		var m := maxi(1, roundi((u1 - u0) / 4.2))
		for j in range(1, m):
			var u := u0 + (u1 - u0) * float(j) / float(m)
			var c0 := _w(u - 0.05, p.y + 0.03 * nl.x)
			var c1 := _w(u + 0.05, p.y + 0.03 * nl.x)
			var d0 := _w(u - 0.05, q.y + 0.03 * nl.x)
			var d1 := _w(u + 0.05, q.y + 0.03 * nl.x)
			var h0 := gf + p.x + 0.03 * nl.y
			var h1 := gf + q.x + 0.03 * nl.y
			_quad(Vector3(c0.x, h0, c0.y), Vector3(c1.x, h0, c1.y), Vector3(d1.x, h1, d1.y), Vector3(d0.x, h1, d0.y), n, NBP_JOINT)


## The bands' side at u, facing n (plan direction as a Vector3), from v `back` out to the profile.
func _nbp_cheek(u: float, n: Vector3, back: float, gf: float) -> void:
	for k in NBP_PROFILE.size() - 1:
		var p: Vector2 = NBP_PROFILE[k]
		var q: Vector2 = NBP_PROFILE[k + 1]
		if q.x - p.x < 0.01:
			continue
		var a0 := _w(u, back)
		var a1 := _w(u, p.y)
		var b1 := _w(u, q.y)
		_quad(Vector3(a0.x, gf + p.x, a0.y), Vector3(a1.x, gf + p.x, a1.y), Vector3(b1.x, gf + q.x, b1.y),
				Vector3(a0.x, gf + q.x, a0.y), n, NBP_PANEL)


## Pixel runs (rows: row index -> sorted or unsorted pixel columns) on a face at v, from u0, the
## top row's top at y_top: one face per run of neighbouring pixels.
func _nbp_pixels(rows: Dictionary, u0: float, pu: float, py: float, y_top: float, v: float, col: Color) -> void:
	for row: int in rows:
		var xs: Array = (rows[row] as Array).duplicate()
		if xs.is_empty():
			continue
		xs.sort()
		var s0: int = xs[0]
		var prev: int = xs[0]
		for idx in range(1, xs.size() + 1):
			var x: int = xs[idx] if idx < xs.size() else -999
			if x == prev + 1:
				prev = x
				continue
			var y := y_top - float(row) * py
			_buw_face(_w(u0 + s0 * pu, v), _w(u0 + (prev + 1) * pu, v), y - py, y, _b, col)
			s0 = x
			prev = x


## Dom Chłopa (Plac Powstańców Warszawy 2, 1958-61, today a hotel; 2026-11-16, spec
## docs/landmarks/specs/dom_chlopa.md; photos: F's T14 set and refs/dom_chlopa/street). The
## cream block round its courtyard is the street block that already stood on the outline
## (blk_2250406, its walls, windows, dark glass ground floor and coping). This site adds what makes
## it Dom Chłopa from the square: the wavy roof edge, a row of shallow arcs along every street
## front, and the signs (as parodies): GROMADKA in green on the roof over the north end of the
## front, a tall dark HOTEL sign at the north-west corner, KASYNO TRAF over the ground floor.
## The frame's u runs south along the front on the square from its north-west corner, v out.
const DCH_O := Vector2(-664.3, -39.7)
const DCH_A := Vector2(0.3211, 0.9476)
const DCH_LEN := 76.3
const DCH_TOP := 18.4      # the block's coping, over its ground
const DCH_WAVE := 6.2      # one arc of the roof edge, about two window bays
const DCH_RISE := 1.3      # how far each arc rises over the coping
const DCH_CREAM := Color("#e6e1cb")
const DCH_GREEN := Color("#3fbf4a")
const DCH_SIGN := Color("#2c3133")
const DCH_WHITE := Color("#f2f2ee")


func _build_dom_chlopa(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	# --- the wavy roof edge along every street front long enough for one arc
	# (a piece under 4 m, the outline's small kinks, is a flat band; each edge's underside sits a
	# few cm off its neighbours', so two never lie in one plane at a corner)
	var n := ring.size()
	var drop: Array[float] = []
	for k in n:
		drop.append(0.05 * float(k % 3))
	if n > 2 and is_equal_approx(drop[n - 1], drop[0]):
		drop[n - 1] = 0.125
	for k in n:
		var p := ring[k]
		var q := ring[(k + 1) % n]
		if p.distance_to(q) < 0.3:
			continue
		_dch_waves(p, q, _out(ring, p, q), g + DCH_TOP, drop[k])
	# --- the signs, in the front's frame
	_o = DCH_O
	_a = DCH_A
	_b = Vector2(-DCH_A.y, DCH_A.x)
	var top := g + DCH_TOP
	# GROMADKA over the north end: green letters on two dark posts, lit at night
	var word := "GROMADKA"
	var pu := 0.42
	var py := 0.36
	var u0 := 17.0 - PixelFont.width(word) * pu * 0.5
	# (the posts are beams from the sign back over the roof edge, resting on it)
	_ubox(u0 + 2.0, u0 + 2.3, -2.2, -0.2, top - 0.2, top + 0.6, DCH_SIGN)
	_ubox(u0 + PixelFont.width(word) * pu - 2.3, u0 + PixelFont.width(word) * pu - 2.0, -2.2, -0.2, top - 0.2, top + 0.6, DCH_SIGN)
	_mode = M_LAMP
	_dch_word(word, u0, pu, py, top + 0.6 + 7.0 * py, -1.9, DCH_GREEN)
	# HOTEL down the north-west corner: a tall dark pier from the ground to the roof edge, the
	# letters stacked high on it, green; a dark fascia from it over the ground floor carries the
	# casino's name
	_mode = M_STONE
	_ubox(1.0, 2.6, 0.0, 0.5, g - 0.3, top, DCH_SIGN)
	_ubox(2.6, 33.0, 0.0, 0.1, g + 4.8, g + 6.6, DCH_SIGN)
	_mode = M_LAMP
	var letters := "HOTEL"
	for i in letters.length():
		var ch := letters[i]
		var cw := PixelFont.width(ch) * 0.2
		_dch_word(ch, 1.8 - cw * 0.5, 0.2, 0.2, g + 17.0 - float(i) * 1.9, 0.53, DCH_GREEN)
	# KASYNO TRAF over the ground floor's north stretch, white
	_dch_word("KASYNO TRAF", 21.0, 0.17, 0.15, g + 6.4, 0.13, DCH_WHITE)
	_mode = M_STONE


## One street front's roof edge from a to b: shallow arcs over the coping at y, a cream band
## 0.3 m proud of the wall line with its shaded underside (the photos' dark line under the
## waves), its back and its top, each arc in five straight pieces.
func _dch_waves(a: Vector2, b: Vector2, out: Vector2, y: float, drop: float) -> void:
	var l := a.distance_to(b)
	var d := (b - a) / l
	var m := maxi(1, roundi(l / DCH_WAVE))
	var segs := 5 if l >= 4.0 else 1
	var rise := DCH_RISE if l >= 4.0 else 0.0
	var n_out := Vector3(out.x, 0.0, out.y)
	var fo := out * 0.3
	var bo := -out * 0.25
	for w in m:
		for s in segs:
			var t0 := float(s) / float(segs)
			var t1 := float(s + 1) / float(segs)
			var c0 := a + d * l * (float(w) + t0) / float(m)
			var c1 := a + d * l * (float(w) + t1) / float(m)
			var flat := 0.0 if l >= 4.0 else drop  # a flat piece's top, off its neighbours' too
			var h0 := y + rise * sin(PI * t0) + flat
			var h1 := y + rise * sin(PI * t1) + flat
			var y0 := y - 0.3 - drop
			var f0 := c0 + fo
			var f1 := c1 + fo
			var k0 := c0 + bo
			var k1 := c1 + bo
			_quad(Vector3(f0.x, y0, f0.y), Vector3(f1.x, y0, f1.y), Vector3(f1.x, h1 + 0.2, f1.y), Vector3(f0.x, h0 + 0.2, f0.y),
					n_out, DCH_CREAM)
			_quad(Vector3(k1.x, y0, k1.y), Vector3(k0.x, y0, k0.y), Vector3(k0.x, h0 + 0.2, k0.y), Vector3(k1.x, h1 + 0.2, k1.y),
					-n_out, DCH_CREAM.darkened(0.06))
			_quad(Vector3(c0.x, y0, c0.y), Vector3(c1.x, y0, c1.y), Vector3(f1.x, y0, f1.y), Vector3(f0.x, y0, f0.y),
					Vector3.DOWN, DCH_CREAM.darkened(0.35))
			var e := Vector3(c1.x - c0.x, h1 - h0, c1.y - c0.y)
			var up := e.cross(n_out).normalized()
			if up.y < 0.0:
				up = -up
			_quad(Vector3(f0.x, h0 + 0.2, f0.y), Vector3(f1.x, h1 + 0.2, f1.y), Vector3(k1.x, h1 + 0.2, k1.y), Vector3(k0.x, h0 + 0.2, k0.y),
					up, DCH_CREAM.lightened(0.05))


## A word in pixel faces on the plane v, from u0, its top at y_top; one face per run of pixels.
func _dch_word(word: String, u0: float, pu: float, py: float, y_top: float, v: float, col: Color) -> void:
	var rows := {}
	PixelFont.each_pixel(word, 0, func(x: int, row: int) -> void:
		if not rows.has(row - PixelFont.BODY):
			rows[row - PixelFont.BODY] = []
		(rows[row - PixelFont.BODY] as Array).append(x))
	_nbp_pixels(rows, u0, pu, py, y_top, v, col)


## Żyletkowiec (Marszałkowska 82, 1952; OSM way 30241286; 2026-11-16, spec
## docs/landmarks/specs/zyletkowiec.md; photos: F's T15 set). The U-shaped block round its
## courtyard, open to the north, is the street block that already stood on the outline
## (blk_30241286: its walls, windows, thin pilasters, the dark glass ground floor and the coping).
## This site adds what makes it the "razor blade" building: a deep white fin over each of the
## block's pilasters on every street front, from the first floor to the roof; a granite-grey pier
## under each fin through the ground floor (the photos' arcade); and the
## dark roof lid that overhangs every front, its thin edge, its pale underside and its shallow
## slope up to a flat top.
## The fins sit exactly over the block's pilasters, measured from the block (edge index of the
## outline, the first pilaster's centre along the edge, the pitch, the count); the street fronts
## only, not the courtyard.
const ZYL_FINS := [[0, 2.310, 2.3170, 24], [1, 2.050, 2.3036, 34], [3, 2.380, 2.4350, 3],
		[9, 2.450, 2.4025, 3], [10, 2.470, 2.4050, 2], [11, 2.070, 2.2959, 34]]
const ZYL_TOP := 26.1        # the block's coping, over its ground
const ZYL_GF := 3.7          # the top of the block's ground floor
const ZYL_EAVE := 1.6        # how far the lid overhangs the wall line
const ZYL_FIN := Color("#f2f2ee")
const ZYL_PIER := Color("#9a9c9b")
const ZYL_EDGE := Color("#4a4f53")
const ZYL_SLOPE := Color("#6f7478")
const ZYL_ROOF := Color("#7c8185")
const ZYL_SOFFIT := Color("#d6d6d1")


func _build_zyletkowiec(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	var n := ring.size()
	# --- the fins and the piers under them, in each street front's own frame (u along the
	# edge, v out of the wall line)
	for f: Array in ZYL_FINS:
		var k: int = f[0]
		if k >= n:
			continue
		var p := ring[k]
		var q := ring[(k + 1) % n]
		_o = p
		_a = (q - p).normalized()
		_b = _out(ring, p, q)
		for i: int in f[3]:
			var c: float = float(f[1]) + float(f[2]) * float(i)
			# the pier, granite grey, up to the ground floor's top
			_ubox(c - 0.25, c + 0.25, -0.1, 1.0, g - 0.3, g + ZYL_GF, ZYL_PIER)
			# the fin, up into the lid
			_ubox(c - 0.18, c + 0.18, -0.1, 0.95, g + ZYL_GF, g + ZYL_TOP, ZYL_FIN)
	# --- the lid: a thin dark edge round the overhang, a pale underside, a shallow slope up to
	# a flat top
	var eave := _inset_ring(ring, -ZYL_EAVE)
	var crest := _inset_ring(ring, 1.5)
	var y0 := g + ZYL_TOP - 0.2
	var y1 := g + ZYL_TOP + 0.2
	var y2 := g + ZYL_TOP + 0.8
	for k in n:
		var a := eave[k]
		var b := eave[(k + 1) % n]
		var out := _out(eave, a, b)
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y),
				Vector3(out.x, 0.0, out.y), ZYL_EDGE)
		var ca := crest[k]
		var cb := crest[(k + 1) % n]
		var p0 := Vector3(a.x, y1, a.y)
		var p1 := Vector3(b.x, y1, b.y)
		var p3 := Vector3(ca.x, y2, ca.y)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		_quad(p0, p1, Vector3(cb.x, y2, cb.y), p3, nrm, ZYL_SLOPE)
	var idx := Geometry2D.triangulate_polygon(eave)
	for t in range(0, idx.size(), 3):
		var a := eave[idx[t]]
		var b := eave[idx[t + 1]]
		var c := eave[idx[t + 2]]
		_tri(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(c.x, y0, c.y), Vector3.DOWN, ZYL_SOFFIT,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_cap(crest, y2, ZYL_ROOF)


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
