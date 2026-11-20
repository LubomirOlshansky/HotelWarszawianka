extends "res://scripts/landmarks/kladka.gd"
## Powiśle, second part (F, 2026-11-20): Teatr Ateneum and Lipowa 1A. One link of landmarks.gd's
## base chain (TD-10): it may use this file, common.gd and the facade kit, never another area.
##
## Teatr Ateneum (Jaracza 2; spec docs/landmarks/specs/ateneum.md, F's four photos X-Ateneum): the
## theatre's grey house between Jaracza and the embankment, a flat block of the 20.8 m the map
## gives it with one free front, the one on Jaracza. The portico, the arched band and the big
## ATENEUM letters are tamka.gd's (`_ateneum`, 2026-11-09); here is the house they stand on:
## warm grey plaster over a pale blue-grey plinth, a tall ground floor with a framed window each
## side of the portico, a round window each side over it, three upper floors of framed windows
## on five axes, a pale cornice and a parapet, a stage house behind on the roof.
##
## Lipowa 1A (F's screenshot and the Lipowa photos, spec docs/landmarks/specs/lipowa1a.md): the
## seven-storey house across Lipowa from the University Library's glass vault and the law faculty:
## three floors of white plaster with small windows, four floors of dark glass behind balcony slabs
## between teal fins, a teal rim, and a planted roof terrace with plant boxes and a glass pavilion.

# --- Teatr Ateneum -----------------------------------------------------------------------

## The block's footprint (F's aerial and photos, 2026-11-21): the long Wybrzeże wing and the Jaracza
## wing joined by the rounded corner at the junction. The map has them as a 47.2 m "hotel" strip
## (wrong: the whole block is about 23 m) and a 20.8 m house; both are replaced by this ring. The
## corner is an arc from ATE_C0 (end of the Wybrzeże face) to ATE_C1 (start of the Jaracza face)
## bulging ATE_SAG metres out.
const ATE_AT := Vector2(581.0, -382.0)
const ATE_C0 := Vector2(598.1, -403.3)
const ATE_C1 := Vector2(592.1, -386.2)
const ATE_SAG := 3.0
const ATE_ARC := 5
const ATE_CORNICE := 19.9
const ATE_TOP := 23.0
const ATE_PINK := Color("#d9b8a4")
const ATE_TAUPE := Color("#b5a58b")
const ATE_WHITE := Color("#e6e2d6")
const ATE_RED := Color("#b3503f")
const ATE_STONE := Color("#78736d")
const ATE_ROOF := Color("#6e7072")
const ATE_PLINTH := Color("#8d8a84")
## The wall colour the far skyline sees (landmarks.gd).
const ATE_WALL := ATE_PINK


func _ate_ring() -> PackedVector2Array:
	var r := PackedVector2Array([Vector2(555.2, -456.5), Vector2(559.7, -451.0), Vector2(579.2, -426.8),
			Vector2(593.8, -408.7), ATE_C0])
	var m := (ATE_C0 + ATE_C1) * 0.5
	var d := (ATE_C1 - ATE_C0).normalized()
	var out := Vector2(-d.y, d.x)
	if out.dot(Vector2(1.0, 0.0)) < 0.0:
		out = -out
	var chord := ATE_C0.distance_to(ATE_C1)
	var rad := (chord * chord * 0.25 + ATE_SAG * ATE_SAG) / (2.0 * ATE_SAG)
	var c := m - out * (rad - ATE_SAG)
	var a0 := (ATE_C0 - c).angle()
	var delta := wrapf((ATE_C1 - c).angle() - a0, -PI, PI)
	for k in range(1, ATE_ARC):
		r.append(c + Vector2.from_angle(a0 + delta * float(k) / ATE_ARC) * rad)
	r.append_array(PackedVector2Array([ATE_C1, Vector2(579.9, -370.5), Vector2(571.2, -377.5),
			Vector2(581.9, -394.1), Vector2(584.4, -397.3), Vector2(587.0, -400.6), Vector2(585.8, -402.1),
			Vector2(571.1, -420.6), Vector2(556.3, -438.8), Vector2(551.8, -444.5), Vector2(548.7, -448.2)]))
	return r


func _find_ateneum() -> void:
	var ring := _ate_ring()
	_add_site("ateneum", [_largest(Geometry2D.offset_polygon(ring, 0.5, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "ateneum":
		sites[-1]["ring"] = ring
		sites[-1]["raw"] = ring


## Frames the edge a-b so that u runs along it and +v points out of the building.
func _ate_frame(ring: PackedVector2Array, a: Vector2, b: Vector2) -> float:
	var out := _out(ring, a, b)
	var left := Vector2(-(b - a).y, (b - a).x).normalized()
	if left.dot(out) > 0.0:
		return kit_front(a, b)
	return kit_front(b, a)


func _build_ateneum(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	_prism(ring, g - 1.5, g + ATE_CORNICE, ATE_PINK, ATE_ROOF, M_STONE, M_STONE)
	# the set-back attic: a red band under a white one, a roof deck inside
	for q: PackedVector2Array in Geometry2D.offset_polygon(ring, -1.6, Geometry2D.JOIN_MITER):
		if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
			_prism(q, g + ATE_CORNICE, g + ATE_TOP - 0.7, ATE_RED, ATE_ROOF, M_STONE, M_STONE)
			_prism(q, g + ATE_TOP - 0.7, g + ATE_TOP, ATE_WHITE, ATE_ROOF, M_STONE, M_STONE)
	var n := ring.size()
	var arc_from := 4
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var length := a.distance_to(b)
		if length < 4.0:
			continue
		var on_arc := i >= arc_from and i < arc_from + ATE_ARC
		var front := _out(ring, a, b).dot(Vector2(0.789, 0.614)) > 0.9 and length > 15.0
		var outer := _out(ring, a, b).dot(Vector2(0.78, -0.63)) > 0.9
		if not (on_arc or outer or front or i == n - 1):
			continue
		var w := _ate_frame(ring, a, b)
		kit_face(0.0)
		kit_cornice(0.0, w, g + ATE_CORNICE, ATE_WHITE, 0.5, 0.9)
		kit_ledge(0.0, w, g - 0.2, 1.3, ATE_PLINTH, 0.1)
		if on_arc:
			_ate_arc_bay(w, i - arc_from)
		else:
			_ate_flat_face(w, front)
	# the rooftop: a stage house over the Jaracza wing, plant, a lift head
	var keep := _mode
	_o = Vector2.ZERO
	_a = Vector2(1.0, 0.0)
	_b = Vector2(0.0, 1.0)
	_lbox(576.5, -392.0, 5.0, 4.0, g + ATE_TOP, g + ATE_TOP + 2.6, ATE_TAUPE.darkened(0.1), M_STONE, ATE_ROOF)
	_lbox(584.0, -384.0, 1.4, 1.2, g + ATE_TOP, g + ATE_TOP + 1.4, PAL_GREY_STONE, M_STONE, ATE_ROOF)
	_lbox(577.0, -420.0, 1.5, 1.2, g + ATE_TOP, g + ATE_TOP + 1.2, PAL_ALUMINIUM, M_STONE, ATE_ROOF)
	_lbox(565.0, -435.0, 1.3, 1.0, g + ATE_TOP, g + ATE_TOP + 1.0, PAL_GREY_STONE, M_STONE, ATE_ROOF)
	_mode = keep
	_ate_sign(ring)
	_collide_raw(site)


## A straight face: a taupe ground floor with framed windows, four floors of windows in pink walls,
## white pilaster strips at the ends and every 13 m; on the front (Jaracza) the middle is taupe with
## tall arched windows over the porch (which is tamka.gd's) and a round window each side of it.
func _ate_flat_face(w: float, front: bool) -> void:
	var g := _g
	kit_wall(0.0, w, g, g + 5.4, ATE_TAUPE.darkened(0.04))
	kit_ledge(0.0, w, g + 5.4, 0.3, ATE_WHITE, 0.22)
	var pil := maxi(1, roundi(w / 13.0))
	for k in pil + 1:
		kit_pilaster(0.0 + 0.7 + (w - 1.4) * float(k) / pil, g + 5.7, g + ATE_CORNICE - 0.5, ATE_WHITE, 1.1, 0.14)
	var bays := maxi(1, floori(w / 3.3))
	var cx := _spread(0.0, w, bays)
	for u: float in cx:
		var mid := front and absf(u - w * 0.5) < 5.0
		if mid:
			continue
		kit_window(u, g + 1.5, 2.3, Win.FRAMED, ATE_WHITE, PAL_GLASS_DARK, 0.65)
		for sill: float in [g + 6.7, g + 10.0, g + 13.3, g + 16.6]:
			if front and sill < g + 7.0 and absf(absf(u - w * 0.5) - 7.6) < 1.9:
				continue  # the round window stands there
			kit_window(u, sill, 1.9, Win.SILL, ATE_WHITE, PAL_GLASS_DARK, 0.6)
	if front:
		# over the porch: a taupe panel between white double pilasters, three tall arched windows
		var pw := 5.2
		kit_wall(w * 0.5 - pw, w * 0.5 + pw, g + 5.7, g + ATE_CORNICE, ATE_TAUPE)
		for s: float in [-1.0, 1.0]:
			kit_pilaster(w * 0.5 + s * (pw + 0.6), g + 5.7, g + ATE_CORNICE - 0.5, ATE_WHITE, 1.1, 0.16)
			kit_pilaster(w * 0.5 + s * (pw - 0.4), g + 5.7, g + ATE_CORNICE - 0.5, ATE_WHITE, 0.6, 0.12)
		for k in 3:
			kit_window(w * 0.5 + (k - 1) * 3.2, g + 9.6, 6.4, Win.ARCHED, ATE_WHITE, PAL_GLASS_DARK, 0.85)
		for s: float in [-1.0, 1.0]:
			var u := w * 0.5 + s * 7.6
			_ate_oculus(u, g + 7.6)


## One bay of the rounded corner: a cream round column in front of a dark arched opening, then a
## balcony rail on the first floor, tall arched windows over the middle three bays.
func _ate_arc_bay(w: float, k: int) -> void:
	var g := _g
	kit_wall(0.0, w, g, g + 5.4, ATE_STONE)
	kit_window(w * 0.5, g + 0.9, 3.6, Win.ARCHED, ATE_WHITE, PAL_GLASS_DARK, 0.95)
	kit_column(0.0, 0.9, g, g + 5.2, ATE_WHITE, 0.5, Order.CORINTHIAN)
	if k == ATE_ARC - 1:
		kit_column(w, 0.9, g, g + 5.2, ATE_WHITE, 0.5, Order.CORINTHIAN)
	kit_ledge(0.0, w, g + 5.2, 0.5, ATE_WHITE, 0.55)
	kit_balcony(w * 0.5, g + 6.0, w * 0.5 - 0.1, Balcony.IRON, PAL_IRON, ATE_WHITE, 0.8)
	kit_pilaster(0.0, g + 5.8, g + ATE_CORNICE - 0.5, ATE_WHITE, 0.9, 0.14)
	if k >= 1 and k <= 3:
		kit_window(w * 0.5, g + 8.4, 5.8, Win.ARCHED, ATE_WHITE, PAL_GLASS_DARK, 0.85)
		kit_balcony(w * 0.5, g + 8.4, 0.9, Balcony.IRON, PAL_IRON, ATE_WHITE, 0.6)
		kit_window(w * 0.5, g + 15.0, 1.9, Win.SILL, ATE_WHITE, PAL_GLASS_DARK, 0.6)
	else:
		for sill: float in [g + 6.7, g + 10.0, g + 13.3, g + 16.6]:
			kit_window(w * 0.5, sill, 1.9, Win.SILL, ATE_WHITE, PAL_GLASS_DARK, 0.6)


## A round window on the front at u, its centre y (absolute): a pale surround and a lit pane.
func _ate_oculus(u: float, y: float) -> void:
	var c := _w(u, 0.0)
	var n := Vector3(_b.x, 0.0, _b.y)
	var keep := _mode
	_mode = M_STONE
	_disc(Vector3(c.x + _b.x * 0.04, y, c.y + _b.y * 0.04), n, 1.15, 14, ATE_WHITE)
	_mode = _lit(u, y)
	_disc(Vector3(c.x + _b.x * 0.09, y, c.y + _b.y * 0.09), n, 0.88, 14, PAL_GLASS_DARK)
	_mode = keep


## The tall ATENEUM sign on the Jaracza wing's far end (photos 1, 4): seven lit letter boxes in
## the theatre's colours, one over the other.
func _ate_sign(ring: PackedVector2Array) -> void:
	var g := _g
	var a := Vector2(579.9, -370.5)
	var b := Vector2(592.1, -386.2)
	var out := Vector2(0.789, 0.614)
	var e := (a - b).normalized()
	var at := a + e * 0.6 + out * 0.12
	_o = at
	_a = e
	_b = out
	var cols: Array[Color] = [Color("#d23a35"), Color("#3fa34a"), Color("#e8e4da"), Color("#2f8fd8"), Color("#d23a35"), Color("#3fa34a"), Color("#e8e4da")]
	var keep := _mode
	_lbox(0.0, 0.0, 0.5, 0.15, g + 8.4, g + 19.4, ATE_WHITE, M_STONE)
	for k in 7:
		var y := g + 8.6 + 1.5 * k
		_mode = M_LAMP
		_lbox(0.0, 0.25, 0.5, 0.2, y, y + 1.3, cols[k], M_LAMP)
	_mode = keep


# --- Lipowa 1A ---------------------------------------------------------------------------

## Lipowa 1a (F, 2026-11-20: "the house with the green front", his aerial and two street photos
## of 2023): a white classical base of four storeys (arched ground-floor windows, a cornice), and
## four storeys over it clad in patina-green copper sheet: on Lipowa deep loggias between copper
## piers with concrete slabs and glass rails, the end towards Dobra solid copper with a few small
## windows, a roof terrace with a rail and a small glass room. OSM says 10.9 m; the photos ~25 m.
const L1A_AT := Vector2(114.8, -891.5)       # the address point inside its outline
const L1A_LIPOWA := Vector2(-0.45, -0.89)    # the Lipowa front's outward normal
const L1A_END := Vector2(0.89, -0.45)        # the end towards Dobra
const L1A_BASE := 12.6
const L1A_TOP := 24.8
const L1A_STOREY := 3.05
const L1A_WHITE := Color("#e4e1d8")
const L1A_CORNICE := Color("#f0eee8")
const L1A_COPPER := [Color("#5c9f8e"), Color("#55988a"), Color("#63a693"), Color("#519285"), Color("#68aa98")]
const L1A_LOGGIA := Color("#2c3a3c")
const L1A_SLAB := Color("#bfbcb3")
const L1A_RAIL := Color("#a9c6c8")
const L1A_ROOF := Color("#6e7270")


func _find_lipowa1a() -> void:
	var q := _tallest_at(L1A_AT)
	if q.size() < 4:
		return
	_add_site("lipowa1a", [_largest(Geometry2D.offset_polygon(q, 0.4, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "lipowa1a":
		sites[-1]["ring"] = _simplify(q, 0.6)
		sites[-1]["raw"] = q



## loggias on Lipowa, the solid copper end, the roof terrace. Its own outline, its own ground.
func _build_lipowa1a(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["raw"]
	if outline.size() < 3:
		return
	var ring := _simplify(outline, 0.6)
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	_g = _ground_under(outline)
	var g := _g
	var base := g + L1A_BASE
	var top := g + L1A_TOP
	_mode = M_STONE
	var n := ring.size()
	var run := 0.0
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var out := _out(ring, a, b)
		var length := a.distance_to(b)
		if length < 0.3:
			run += length
			continue
		var e := (b - a) / length
		# the white base and its plinth, the cornice under the copper
		_wall(a, b, g - 0.4, base, out, L1A_WHITE, run)
		_buw_face(a + out * 0.06, b + out * 0.06, g - 0.4, g + 0.8, out, L1A_WHITE.darkened(0.12))
		_buw_face(a + out * 0.2, b + out * 0.2, base - 0.45, base, out, L1A_CORNICE)
		_quad(Vector3(a.x, base - 0.45, a.y) + Vector3(out.x, 0, out.y) * 0.2,
				Vector3(b.x, base - 0.45, b.y) + Vector3(out.x, 0, out.y) * 0.2,
				Vector3(b.x, base - 0.45, b.y), Vector3(a.x, base - 0.45, a.y), Vector3.DOWN, L1A_CORNICE.darkened(0.2))
		# the ground floor's arched windows on the street fronts: dark panes with a white arch
		if out.dot(L1A_LIPOWA) > 0.7 or out.dot(L1A_END) > 0.7:
			var bays := maxi(1, floori(length / 3.2))
			for k in bays:
				var m := a + e * (length * (float(k) + 0.5) / float(bays)) + out * 0.04
				_buw_face(m - e * 0.55, m + e * 0.55, g + 1.0, g + 2.7, out, L1A_LOGGIA)
				_disc(Vector3(m.x, g + 2.7, m.y) + Vector3(out.x, 0, out.y) * 0.03, Vector3(out.x, 0.0, out.y), 0.55, 8, L1A_LOGGIA)
		# the base's three upper storeys: tall windows in white surrounds, a bay every ~2.6 m
		if length > 2.0:
			var wins := maxi(1, floori(length / 2.6))
			for k in wins:
				var m := a + e * (length * (float(k) + 0.5) / float(wins)) + out * 0.04
				for fl in 3:
					var wy := g + 3.9 + 3.0 * float(fl)
					_buw_face(m - e * 0.5, m + e * 0.5, wy, wy + 1.6, out, L1A_LOGGIA.lightened(0.08))
		# the copper storeys
		if out.dot(L1A_LIPOWA) > 0.7 and length > 3.0:
			_l1a_loggias(a, b, out, base, top, run)
		else:
			_l1a_copper(a, b, out, base, top, out.dot(L1A_END) > 0.7)
		run += length
	# the roof, its copper coping, the terrace's rail and the small glass room
	_cap(ring, top, L1A_ROOF)
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		if a.distance_to(b) < 0.3:
			continue
		var out := _out(ring, a, b)
		_buw_face(a, b, top, top + 0.5, out, L1A_COPPER[1])
		_buw_face(b - out * 0.25, a - out * 0.25, top, top + 0.5, -out, L1A_COPPER[3])
		_buw_face(a - out * 0.6, b - out * 0.6, top, top + 1.1, out, L1A_RAIL)
	var c := _centre(outline)
	var room := _circle(c + L1A_END * 3.0, 2.2, 4)
	_prism(room, top, top + 2.6, L1A_LOGGIA, L1A_ROOF, M_STONE, M_STONE)
	_collide_raw(site)


## A copper face from `y0` to `y1`: panels of slightly different patina (2.4 m wide, a storey
## high), small dark windows on the end towards Dobra (photo: a few, off the grid).
func _l1a_copper(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, end: bool) -> void:
	var length := a.distance_to(b)
	var e := (b - a) / length
	var cols := maxi(1, roundi(length / 2.4))
	var rows := maxi(1, roundi((y1 - y0) / L1A_STOREY))
	for r in rows:
		var ya := y0 + (y1 - y0) * float(r) / float(rows)
		var yb := y0 + (y1 - y0) * float(r + 1) / float(rows)
		for k in cols:
			var p0 := a + e * (length * float(k) / float(cols))
			var p1 := a + e * (length * float(k + 1) / float(cols))
			var h := _buw_hash(roundf(p0.x * 2.0) + float(r) * 7.0, roundf(p0.y * 2.0))
			_buw_face(p0, p1, ya, yb, out, L1A_COPPER[int(h * 97.0) % L1A_COPPER.size()])
	if end and length > 6.0:
		# [where along, width, storey]: one window per storey, so none overlaps another
		for w: Vector3 in [Vector3(0.3, 1.8, 3.0), Vector3(0.62, 0.9, 2.0), Vector3(0.8, 0.5, 1.0), Vector3(0.45, 0.9, 0.0)]:
			var m := a + e * (length * w.x) + out * 0.03
			var wy := y0 + L1A_STOREY * (w.z + 0.5)
			_buw_face(m - e * w.y * 0.5, m + e * w.y * 0.5, wy - 0.6, wy + 0.6, out, L1A_LOGGIA)


## The Lipowa front's copper storeys: copper piers every ~4.5 m, between them loggias 1.6 m deep
## (dark glass at the back, a concrete slab at each floor, a glass rail), copper over the top floor.
func _l1a_loggias(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, run: float) -> void:
	var length := a.distance_to(b)
	var e := (b - a) / length
	var o3 := Vector3(out.x, 0.0, out.y)
	var bays := maxi(1, roundi(length / 4.5))
	var pier := 0.7
	var deep := 1.6
	var yt := y1 - 0.9
	var rows := maxi(1, roundi((yt - y0) / L1A_STOREY))
	for k in bays:
		var t0 := length * float(k) / float(bays)
		var t1 := length * float(k + 1) / float(bays)
		# the pier: its front and two cheeks
		var pa := a + e * t0
		var pb := a + e * minf(t0 + pier, t1)
		var col: Color = L1A_COPPER[k % L1A_COPPER.size()]
		_buw_face(pa, pb, y0, y1, out, col)
		_buw_face(pb - out * deep, pb, y0, yt, e, col.darkened(0.15))
		var qa := a + e * t1
		if k == bays - 1:
			_buw_face(qa - e * pier, qa, y0, y1, out, col)
			qa -= e * pier
		_buw_face(qa, qa - out * deep, y0, yt, -e, col.darkened(0.15))
		# the back wall of glass, the top band of copper over the loggia
		var la := pb
		var lb := qa
		_buw_face(la - out * deep, lb - out * deep, y0, yt, out, L1A_LOGGIA)
		_buw_face(la, lb, yt, y1, out, L1A_COPPER[(k + 2) % L1A_COPPER.size()])
		for r in rows:
			var ys := y0 + (yt - y0) * float(r) / float(rows)
			# the slab: its edge and its top, a glass rail on it
			if r > 0:  # the lowest slab's edge would lie on the base's wall: the cornice covers it
				_buw_face(la, lb, ys - 0.25, ys, out, L1A_SLAB)
			_quad(Vector3(la.x, ys, la.y) - o3 * deep, Vector3(lb.x, ys, lb.y) - o3 * deep,
					Vector3(lb.x, ys, lb.y), Vector3(la.x, ys, la.y), Vector3.UP, L1A_SLAB.darkened(0.1))
			_buw_face(la - out * 0.05, lb - out * 0.05, ys, ys + 1.0, out, L1A_RAIL)
		# under the top band: the soffit
		_quad(Vector3(la.x, yt, la.y), Vector3(lb.x, yt, lb.y), Vector3(lb.x, yt, lb.y) - o3 * deep,
				Vector3(la.x, yt, la.y) - o3 * deep, Vector3.DOWN, L1A_SLAB.darkened(0.25))


