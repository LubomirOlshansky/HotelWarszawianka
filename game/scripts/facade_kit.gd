extends RefCounted
## The facade kit: what every landmark, building front and street block in landmarks.gd is
## built from. Three layers, lowest first:
##   1. the emitting core: material codes (M_*, S_*), one triangle / quad / wall / prism into the
##      city's building surface, the roof grid and the picking grid;
##   2. the local frame (`_o`, `_a`, `_b`, `_w`, `_lbox`, `_rect` ...): a front's own u (along),
##      v (out) and y;
##   3. the shared facade parts (`kit_*`) and the palette (`PAL_*`): docs/design/facade-kit.md.
## landmarks.gd extends this script, so a site calls all of it without a prefix.

# --- material codes ---

## Material codes for building.gdshader (UV2.x); the fraction is a parameter.
const M_MONUMENT := 2.0   # stone, tall windows between piers, pilasters (the Palace)
const M_STONE := 3.0      # plain stone: pinnacles, plinths, columns
const M_GOLD := 4.0       # the Palace's spire
const M_DIAL := 5.0       # clock dials: lit at night
const M_WEAVE := 6.0      # Stadion Narodowy's red-and-white skin
const M_GLASS_ROOF := 7.0 # Złote Tarasy's wave
const M_PAVILION := 8.0   # glass lit from inside: + 0 warm (the Rotunda), + 0.5 cool (Varso's crown)
const M_ATTIC := 9.0      # a parapet cut into merlons; fraction = its height / 10 m
const M_LAMP := 10.0      # glows at night
const M_MEMBRANE := 11.0  # the stadium's roof membrane
const M_GLASS := 12.0     # curtain wall with mullions (Varso)
const M_SKIN := 13.0      # a tower's own skin; fraction = style / 16 (S_*, building.gdshader skin())
const M_GOTHIC := 14.0    # brick Gothic: buttresses and pointed lancets (the Cathedral, the Barbican)
const M_PANE := 15.0      # one real pane of a modelled block: fraction = its number; lit by chance at night

## The skins (building.gdshader S_*): Złota 44's white banded cladding, Warsaw Spire's diamonds,
## silver floor bands, vertical fins, a white grid, balcony slabs, dark glass, gold glass,
## and an open frame (its panes cut away).
const S_SAIL := 0
# 1 is free (the diamond grid, no building used it; building.gdshader skin()): the next new skin takes it.
const S_BANDS := 2
const S_FINS := 3
const S_GRID := 4
const S_RIBBON := 5
const S_DARK := 6
const S_GOLD := 7
const S_FRAME := 8
const S_TILE := 9   # Novotel's white tiled shaft (the Rondo photos, 2026-10-31)
const S_EASTWALL := 10  # the Eastern Wall stores: pale glass in a light silver grid, 3 m by 2.7 m
const S_PUNCHED := 11   # a re-clad point block: light horizontal cladding, punched windows in bands
const S_MIRROR := 13    # the Blue Skyscraper's blue reflective float glass
const S_SLAB := 12      # a 1960s slab's long face: plaster and loggia bands
const S_ESTATE := 14    # Osiedle Za Żelazną Bramą: large-panel bays, ribbon windows, coloured loggia stacks
const S_KEYS := 15      # Piano House: white plaster, dark window strips in a keyboard's 2-and-3 rhythm

const CLOCKWISE_FRONT := true
const M_STEEL := M_GOLD + 0.5


# --- state ---

var map  # map_builder.gd: terrain, roof grid, wall faces
var st  # the city's building surface (chunked_surface.gd)
# Emitter state.
var _mode := M_STONE
var _no_roof := false  # true: triangles go into the mesh but not the roof grid (glass the cassette must not pick)
var _g := 0.0          # the landmark's ground height
var _id := 0           # landmark id for the picking grid (0: none)
var _pick := PackedByteArray()  # 16-bit landmark ids, two bytes a cell (257 sites by 2026-11-08)
## Walls already drawn by the current site, to cut a later coplanar wall back to what shows
## (z-fighting fix, 2026-10-31): [ax, az, bx, bz, y0, y1, nx, nz] per wall.
var _walls: Array[PackedFloat32Array] = []
## Flat tops already drawn by the current site: [height, outline] (same fix, see _cap).
var _caps: Array = []
## The current site's courts while it builds (`_cap` leaves them open).
var _holes: Array[PackedVector2Array] = []
# A landmark's own plan axes (its local u, v in world metres).
var _o := Vector2.ZERO
var _a := Vector2.RIGHT
var _b := Vector2.DOWN


# --- emitting ---

## One triangle into the city mesh, the roof grid and the picking grid. `top` is the
## wall top above the ground (UV2.y), uv the shader's wall coordinates (x < 0 on tops).
func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color, ua: Vector2, ub: Vector2, uc: Vector2,
		top: float, roof := true) -> void:
	if ((b - a).cross(c - a).dot(n) > 0.0) == CLOCKWISE_FRONT:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	var uv2 := Vector2(_mode, top)
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(ua)
	st.set_uv2(uv2)
	st.add_vertex(a)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_uv(uc)
	st.add_vertex(c)
	if roof and not _no_roof:
		map._roof_triangle(a, b, c, absf(n.y) >= 0.3)
	if _id > 0:
		_mark_pick(a, b, c)


func _mark_pick(a: Vector3, b: Vector3, c: Vector3) -> void:
	var cell: float = map.ROOF_CELL
	var i0 := floori((minf(a.x, minf(b.x, c.x)) - map._roof_x0) / cell)
	var i1 := floori((maxf(a.x, maxf(b.x, c.x)) - map._roof_x0) / cell)
	var j0 := floori((minf(a.z, minf(b.z, c.z)) - map._roof_z0) / cell)
	var j1 := floori((maxf(a.z, maxf(b.z, c.z)) - map._roof_z0) / cell)
	if (i1 - i0 + 1) * (j1 - j0 + 1) > 400:
		return  # a long thin piece (a cable): not worth the cells
	for j in range(maxi(j0, 0), mini(j1, map._roof_nz - 1) + 1):
		for i in range(maxi(i0, 0), mini(i1, map._roof_nx - 1) + 1):
			_pick.encode_u16((j * map._roof_nx + i) * 2, _id)


## A quad a-b-c-d (in order round its edge).
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color,
		ua := Vector2(-1, -1), ub := Vector2(-1, -1), uc := Vector2(-1, -1), ud := Vector2(-1, -1), top := -1.0) -> void:
	_tri(a, b, c, n, col, ua, ub, uc, top)
	_tri(a, c, d, n, col, ua, uc, ud, top)


## A vertical wall along a→b (plan) from y0 to y1 (absolute), facing `out`. `run` is the
## distance along the facade already covered (keeps the window rhythm continuous).
func _wall(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, col: Color, run := 0.0) -> void:
	var length := a.distance_to(b)
	if length < 0.02 or y1 <= y0:
		return
	var n := Vector3(out.x, 0.0, out.y).normalized()
	# Cut away what an earlier wall of this site already covers in the same plane, facing the
	# same way: two coplanar faces z-fight (flicker) on the phone. Pieces are (t0, t1, y0, y1)
	# in metres along a→b and absolute height.
	var d := (b - a) / length
	var pieces: Array[Vector4] = [Vector4(0.0, length, y0, y1)]
	for w in _walls:
		if w[6] * n.x + w[7] * n.z < 0.9995:
			continue
		var wa := Vector2(w[0], w[1])
		var wb := Vector2(w[2], w[3])
		if absf((wa - a).dot(Vector2(-d.y, d.x))) > 0.03 or absf((wb - a).dot(Vector2(-d.y, d.x))) > 0.03:
			continue
		var e0 := (wa - a).dot(d)
		var e1 := (wb - a).dot(d)
		var t_lo := minf(e0, e1)
		var t_hi := maxf(e0, e1)
		var next: Array[Vector4] = []
		for pc in pieces:
			if t_hi <= pc.x + 0.01 or t_lo >= pc.y - 0.01 or w[5] <= pc.z + 0.01 or w[4] >= pc.w - 0.01:
				next.append(pc)
				continue
			if t_lo > pc.x + 0.01:
				next.append(Vector4(pc.x, t_lo, pc.z, pc.w))
			if t_hi < pc.y - 0.01:
				next.append(Vector4(t_hi, pc.y, pc.z, pc.w))
			var m0 := maxf(pc.x, t_lo)
			var m1 := minf(pc.y, t_hi)
			if w[4] > pc.z + 0.01:
				next.append(Vector4(m0, m1, pc.z, w[4]))
			if w[5] < pc.w - 0.01:
				next.append(Vector4(m0, m1, w[5], pc.w))
		pieces = next
	_walls.append(PackedFloat32Array([a.x, a.y, b.x, b.y, y0, y1, n.x, n.z]))
	for pc in pieces:
		var pa := a + d * pc.x
		var pb := a + d * pc.y
		var h0 := pc.z - _g
		var h1 := pc.w - _g
		var r0 := run + pc.x
		var r1 := run + pc.y
		_quad(Vector3(pa.x, pc.z, pa.y), Vector3(pb.x, pc.z, pb.y), Vector3(pb.x, pc.w, pb.y), Vector3(pa.x, pc.w, pa.y), n, col,
				Vector2(r0, h0), Vector2(r1, h0), Vector2(r1, h1), Vector2(r0, h1), h1)


## The outward normal of edge a→b of a polygon (plan).
func _out(poly: PackedVector2Array, a: Vector2, b: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var n := Vector2(e.y, -e.x)
	return -n if Geometry2D.is_polygon_clockwise(poly) else n


## `_tri` with a normal per corner (the glb's smooth parts); `fn` the face normal for winding.
func _tri_smooth(p: Array[Vector3], n: Array[Vector3], fn: Vector3, col: Color, u: Array[Vector2], top: float) -> void:
	var a := p[0]
	var b := p[1]
	var c := p[2]
	var na := n[0]
	var nb := n[1]
	var nc := n[2]
	var ua := u[0]
	var ub := u[1]
	var uc := u[2]
	if ((b - a).cross(c - a).dot(fn) > 0.0) == CLOCKWISE_FRONT:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
		var tu := ub
		ub = uc
		uc = tu
	st.set_color(col)
	st.set_uv2(Vector2(_mode, top))
	st.set_normal(na)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_normal(nb)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_normal(nc)
	st.set_uv(uc)
	st.add_vertex(c)
	if not _no_roof:
		map._roof_triangle(a, b, c, absf(fn.y) >= 0.3)
	if _id > 0:
		_mark_pick(a, b, c)


## A flat top over a polygon.
func _cap(poly: PackedVector2Array, y: float, col: Color) -> void:
	# Two flat tops at the same height that overlap z-fight: the later one keeps only what the
	# earlier ones leave bare.
	var pieces: Array[PackedVector2Array] = [poly]
	for c in _caps:
		if absf(float(c[0]) - y) > 0.03:
			continue
		var next: Array[PackedVector2Array] = []
		for pc in pieces:
			var cut := Geometry2D.clip_polygons(pc, c[1])
			for q in cut:
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		pieces = next
	_caps.append([y, poly])
	if not _holes.is_empty():
		var open: Array[PackedVector2Array] = []
		for pc in pieces:
			open.append_array(_minus_holes(pc))
		pieces = open
	for pc in pieces:
		# Mapped outlines that double back on themselves triangulate into overlapping
		# triangles; Clipper's union untangles them (a hole comes back clockwise: skipped).
		for q in Geometry2D.merge_polygons(pc, PackedVector2Array()):
			if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
				_cap_piece(q, y, col)


func _cap_piece(poly: PackedVector2Array, y: float, col: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(poly)
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		if absf((b - a).cross(c - a)) < 0.001:
			continue  # a sliver with a repeated corner: no area, nothing to draw
		_tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, col,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## Courtyards (F, 2026-11-03): `poly` less the current site's courts (`_holes`), in pieces
## that hold no hole (a piece left round a whole court is cut in two by a north-south line
## through a point inside that court, then each half again). Counter-clockwise pieces only.
func _minus_holes(poly: PackedVector2Array, depth := 0) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = [poly]
	for h in _holes:
		var next: Array[PackedVector2Array] = []
		for p in parts:
			for q in Geometry2D.clip_polygons(p, h):
				next.append(q)
		parts = next
	var out: Array[PackedVector2Array] = []
	var enclosed := -1
	for q in parts:
		if q.size() < 3:
			continue
		if Geometry2D.is_polygon_clockwise(q):
			enclosed = 0  # a court left whole inside a piece
		else:
			out.append(q)
	if enclosed < 0 or depth > 6:
		return out
	# Split the piece at a point inside a court it holds whole, and take the courts from each half.
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var cut := INF
	for h in _holes:
		var idx := Geometry2D.triangulate_polygon(h)
		if idx.size() < 3:
			continue
		var inner := (h[idx[0]] + h[idx[1]] + h[idx[2]]) / 3.0
		if inner.x > lo.x and inner.x < hi.x and Geometry2D.is_point_in_polygon(inner, poly):
			cut = inner.x
			break
	if cut == INF:
		return out
	var result: Array[PackedVector2Array] = []
	for half in [PackedVector2Array([Vector2(lo.x - 1.0, lo.y - 1.0), Vector2(cut, lo.y - 1.0), Vector2(cut, hi.y + 1.0), Vector2(lo.x - 1.0, hi.y + 1.0)]),
			PackedVector2Array([Vector2(cut, lo.y - 1.0), Vector2(hi.x + 1.0, lo.y - 1.0), Vector2(hi.x + 1.0, hi.y + 1.0), Vector2(cut, hi.y + 1.0)])]:
		for piece in Geometry2D.intersect_polygons(poly, half):
			if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
				result.append_array(_minus_holes(piece, depth + 1))
	return result


## A flat top over a polygon with holes: cut into vertical slabs through every hole,
## so no piece holds a hole, then each piece is filled on its own.
func _cap_holes(outer: PackedVector2Array, holes: Array, y: float, col: Color) -> void:
	if holes.is_empty():
		_cap(outer, y, col)
		return
	var lo := outer[0]
	var hi := outer[0]
	for q in outer:
		lo = lo.min(q)
		hi = hi.max(q)
	var cuts: Array[float] = [lo.x - 1.0]
	for h: PackedVector2Array in holes:
		cuts.append(_centre(h).x)
	cuts.append(hi.x + 1.0)
	cuts.sort()
	for k in cuts.size() - 1:
		var slab := PackedVector2Array([Vector2(cuts[k], lo.y - 1.0), Vector2(cuts[k + 1], lo.y - 1.0),
				Vector2(cuts[k + 1], hi.y + 1.0), Vector2(cuts[k], hi.y + 1.0)])
		for piece in Geometry2D.intersect_polygons(outer, slab):
			var parts: Array = [piece]
			for h: PackedVector2Array in holes:
				var next: Array = []
				for p: PackedVector2Array in parts:
					next.append_array(Geometry2D.clip_polygons(p, h))
				parts = next
			for p: PackedVector2Array in parts:
				if p.size() >= 3:
					_cap(p, y, col)


# --- local frame ---

## A rectangle in a landmark's local plan (centre, half sizes, turned by `turn`).
func _rect(cu: float, cv: float, hu: float, hv: float) -> PackedVector2Array:
	return PackedVector2Array([_w(cu - hu, cv - hv), _w(cu + hu, cv - hv), _w(cu + hu, cv + hv), _w(cu - hu, cv + hv)])


func _w(u: float, v: float) -> Vector2:
	return _o + _a * u + _b * v


func _wl(p: Vector2) -> Vector2:
	return _o + _a * p.x + _b * p.y


func _local(p: Vector2) -> Vector2:
	var d := p - _o
	return Vector2(d.dot(_a), d.dot(_b))


## A box in the local plan: walls and a top.
func _lbox(cu: float, cv: float, hu: float, hv: float, y0: float, y1: float, col: Color, mode := M_STONE, top_col := Color(0, 0, 0, 0)) -> void:
	_prism(_rect(cu, cv, hu, hv), y0, y1, col, top_col if top_col.a > 0.0 else col.darkened(0.1), mode, M_STONE)


## A local rectangle (u0, v0, width, depth) as a world ring.
func _lrect(r: Rect2, grow := 0.0) -> PackedVector2Array:
	return _rect(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5, r.size.x * 0.5 + grow, r.size.y * 0.5 + grow)


func _lpoly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(_w(q[0], q[1]))
	return out


# --- solids ---

## Walls round a polygon from y0 to y1, then (if roof_col.a > 0) its flat top.
func _prism(poly: PackedVector2Array, y0: float, y1: float, wall: Color, roof: Color, wall_mode := -1.0, roof_mode := -1.0) -> void:
	if poly.size() < 3:
		return
	var keep := _mode
	if wall_mode >= 0.0:
		_mode = wall_mode
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		_wall(a, b, y0, y1, _out(poly, a, b), wall, run)
		run += a.distance_to(b)
	_mode = roof_mode if roof_mode >= 0.0 else keep
	if roof.a > 0.0:
		_cap(poly, y1, roof)
	_mode = keep


## Sides from ring0 (at y0) to ring1 (at y1), same number of corners, then a top.
func _frustum(ring0: PackedVector2Array, y0: float, ring1: PackedVector2Array, y1: float, col: Color, top_col := Color(0, 0, 0, 0)) -> void:
	var n := ring0.size()
	var c0 := _centre(ring0)
	for i in n:
		var a0 := ring0[i]
		var b0 := ring0[(i + 1) % n]
		var a1 := ring1[i]
		var b1 := ring1[(i + 1) % n]
		var p0 := Vector3(a0.x, y0, a0.y)
		var p1 := Vector3(b0.x, y0, b0.y)
		var p2 := Vector3(b1.x, y1, b1.y)
		var p3 := Vector3(a1.x, y1, a1.y)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		var mid := (a0 + b0) * 0.5 - c0
		if Vector2(nrm.x, nrm.z).dot(mid) < 0.0:
			nrm = -nrm
		var h0 := y0 - _g
		var h1 := y1 - _g
		var l := a0.distance_to(b0)
		_quad(p0, p1, p2, p3, nrm, col, Vector2(0, h0), Vector2(l, h0), Vector2(l, h1), Vector2(0, h1), h1)
	if top_col.a > 0.0:
		_cap(ring1, y1, top_col)


## A pyramid over a ring, to an apex above its centre.
func _pyramid(ring: PackedVector2Array, y0: float, apex_y: float, col: Color) -> void:
	var c := _centre(ring)
	var apex := Vector3(c.x, apex_y, c.y)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var pa := Vector3(a.x, y0, a.y)
		var pb := Vector3(b.x, y0, b.y)
		var nrm := (pb - pa).cross(apex - pa).normalized()
		if Vector2(nrm.x, nrm.z).dot((a + b) * 0.5 - c) < 0.0:
			nrm = -nrm
		_tri(pa, pb, apex, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A crenellated parapet (zero thickness, seen from both sides) round a ring.
func _attic(ring: PackedVector2Array, y: float, height: float, col: Color, closed := true) -> void:
	var keep := _mode
	_mode = M_ATTIC + clampf(height / 10.0, 0.0, 0.99)
	var run := 0.0
	var n := ring.size()
	for i in (n if closed else n - 1):
		var a := ring[i]
		var b := ring[(i + 1) % n]
		_wall(a, b, y, y + height, _out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## A pinnacle: a square shaft with a pointed cap, on a local spot.
func _pinnacle(cu: float, cv: float, w: float, y: float, h: float, col: Color) -> void:
	var r := w * 0.5
	_prism(_rect(cu, cv, r, r), y, y + h * 0.62, col, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	_pyramid(_rect(cu, cv, r * 1.15, r * 1.15), y + h * 0.62, y + h, col.lightened(0.08))


## A ring of `n` points round `c`.
func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		out.append(c + Vector2.from_angle(TAU * (k + 0.5) / n) * r)
	return out


## An axis-aligned square round `c`, half-width `r`.
func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r)])


## A column on a local spot: a square plinth, an octagonal shaft and a square capital (Tuscan).
func _column(cu: float, cv: float, r: float, y0: float, y1: float, col: Color) -> void:
	var none := Color(0, 0, 0, 0)
	var base := minf(0.45, (y1 - y0) * 0.05)
	_prism(_rect(cu, cv, r * 1.35, r * 1.35), y0, y0 + base, col.darkened(0.04), col.darkened(0.08), M_STONE, M_STONE)
	_prism(_circle(_w(cu, cv), r, 8), y0 + base, y1 - base, col, none, M_STONE)
	_prism(_rect(cu, cv, r * 1.4, r * 1.4), y1 - base, y1, col.lightened(0.05), none, M_STONE)


## A gable in the local frame: the pediment's triangle on the plane u = uf (facing away from
## ub), from v = cv - hv to cv + hv, base y, apex y + h, and its two roof slopes back to u = ub,
## closed there by a second triangle when `back` (none when it ends inside a wall).
func _gable(uf: float, ub: float, cv: float, hv: float, y: float, h: float, face: Color, roof: Color, back := true) -> void:
	var keep := _mode
	_mode = M_STONE
	var s := signf(uf - ub)
	var at := func(u: float, v: float, yy: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, yy, p.y)
	var front := Vector3(_a.x * s, 0.0, _a.y * s)
	var top := y + h - _g
	var y0 := y - _g
	var l: Vector3 = at.call(uf, cv - hv, y)
	var rr: Vector3 = at.call(uf, cv + hv, y)
	var apex: Vector3 = at.call(uf, cv, y + h)
	var lb: Vector3 = at.call(ub, cv - hv, y)
	var rb: Vector3 = at.call(ub, cv + hv, y)
	var apex_b: Vector3 = at.call(ub, cv, y + h)
	_tri(l, rr, apex, front, face, Vector2(0, y0), Vector2(hv * 2.0, y0), Vector2(hv, top), top)
	if back:
		_tri(lb, rb, apex_b, -front, face, Vector2(0, y0), Vector2(hv * 2.0, y0), Vector2(hv, top), top)
	for side: float in [-1.0, 1.0]:
		var e: Vector3 = l if side < 0.0 else rr
		var eb: Vector3 = lb if side < 0.0 else rb
		var n := (Vector3(_b.x, 0.0, _b.y) * side * h + Vector3.UP * hv).normalized()
		_quad(e, eb, apex_b, apex, n, roof)
	_mode = keep


## A flat round (n-sided) disc at c facing n: an oculus, a clock face.
func _disc(c: Vector3, n: Vector3, r: float, sides: int, col: Color) -> void:
	var side := Vector3.UP.cross(n).normalized()
	var top := c.y + r - _g
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var p0 := c + (side * cos(a0) + Vector3.UP * sin(a0)) * r
		var p1 := c + (side * cos(a1) + Vector3.UP * sin(a1)) * r
		_tri(c, p0, p1, n, col, Vector2(r, c.y - _g), Vector2(r + cos(a0) * r, p0.y - _g),
				Vector2(r + cos(a1) * r, p1.y - _g), top)


## A hipped roof over a local rectangle: from the eaves at y up `rise` to a ridge along the
## longer side.
func _hip(cu: float, cv: float, hu: float, hv: float, y: float, rise: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var short := minf(hu, hv) - 0.15
	_frustum(_rect(cu, cv, hu, hv), y, _rect(cu, cv, hu - short, hv - short), y + rise, col, col.darkened(0.06))
	_mode = keep


## A round-headed panel on a wall: a rectangle up to the spring line and a four-segment half
## disc above it. `at` is the foot centre in plan, `along` the wall's direction, `out` its
## outward normal, `proud` how far it stands off the wall (against z-fighting).
func _arch_panel(at: Vector2, along: Vector2, out: Vector2, hw: float, y0: float, spring: float, col: Color,
		proud: float, mode: float) -> void:
	var keep := _mode
	_mode = mode
	var p := at + out * proud
	_wall(p - along * hw, p + along * hw, y0, spring, out, col)
	var n := Vector3(out.x, 0.0, out.y)
	var t := Vector3(along.x, 0.0, along.y)
	var c := Vector3(p.x, spring, p.y)
	var top := spring + hw - _g
	var prev := c + t * hw
	for k in range(1, 5):
		var ang := PI * k / 4.0
		var q := c + (t * cos(ang) + Vector3.UP * sin(ang)) * hw
		var a0 := PI * (k - 1) / 4.0
		_tri(c, prev, q, n, col, Vector2(hw, spring - _g),
				Vector2(hw + cos(a0) * hw, spring - _g + sin(a0) * hw),
				Vector2(hw + cos(ang) * hw, spring - _g + sin(ang) * hw), top)
		prev = q
	_mode = keep


## The upper half of a round (n-sided) disc at c facing n: an arch's head over a flat opening.
func _arch_cap(c: Vector3, n: Vector3, r: float, sides: int, col: Color) -> void:
	var side := Vector3.UP.cross(n).normalized()
	var top := c.y + r - _g
	for k in sides:
		var a0 := PI * k / sides
		var a1 := PI * (k + 1) / sides
		var p0 := c + (side * cos(a0) + Vector3.UP * sin(a0)) * r
		var p1 := c + (side * cos(a1) + Vector3.UP * sin(a1)) * r
		_tri(c, p0, p1, n, col, Vector2(r, c.y - _g), Vector2(r + cos(a0) * r, p0.y - _g),
				Vector2(r + cos(a1) * r, p1.y - _g), top)


## A pane's material: its own number from where it stands, so night lights each window whole.
func _lit(u: float, y: float) -> float:
	return M_PANE + 0.01 + 0.98 * fposmod(sin(u * 12.9898 + y * 78.233 + _o.x) * 437.585, 1.0)


## A pane's lit-by-chance material from a place on the wall (a pane is lit whole at night).
func _pane_at(a: float, b: float) -> float:
	return M_PANE + 0.01 + 0.98 * fposmod(sin(a * 12.9898 + b * 78.233 + _o.x) * 437.585, 1.0)


## Evenly spaced centres between a and b, n of them (bay middles).
func _spread(a: float, b: float, n: int) -> Array:
	var out := []
	for k in n:
		out.append(a + (b - a) * (k + 0.5) / n)
	return out


## A thin parapet (zero thickness, both sides drawn) round a ring, from y up `height`.
func _parapet(ring: PackedVector2Array, y: float, height: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		_wall(a, b, y, y + height, _out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## Tall window bays along a ring's walls: a pane `w` wide every `step` metres (the walls'
## piers between them), from h0 to h1 over the ground, 0.07 m proud of the wall, in the
## curtain-wall glass (M_GLASS: a transom every 4 m, some lit at night); none where a bay's
## foot falls in `skip` (a block standing in front of that wall).
func _bays(ring: PackedVector2Array, h0: float, h1: float, step: float, w: float, col: Color,
		skip := PackedVector2Array()) -> void:
	var keep := _mode
	_mode = M_GLASS
	var along := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		along += length
		var n := floori((length - 1.5) / step)
		if n < 1:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var t0 := (length - n * step) * 0.5 + step * 0.5
		for k in n:
			var p := a + e * (t0 + k * step) + out * 0.07
			if skip.size() >= 3 and Geometry2D.is_point_in_polygon(p, skip):
				continue
			# UV.x centred on a pane of the shader's 1.5 m grid (so its mullions frame the bay), at
			# the bay's distance round the ring (so each bay draws its own lit rooms at night).
			var pane := floorf((along + t0 + k * step) / 1.5) * 1.5
			_wall(p - e * w * 0.5, p + e * w * 0.5, _g + h0, _g + h1, out, col, pane + 0.75 - w * 0.5)
	_mode = keep


## A square beam from a to b, `w` wide (masts, cables). Cables stay out of the roof grid.
func _beam(a: Vector3, b: Vector3, w: float, col: Color, solid := true, mode := M_STONE) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z)
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	x = x.normalized() * w * 0.5
	var y := z.cross(x).normalized() * w * 0.5
	var keep := _mode
	_mode = mode
	var corners := [x + y, -x + y, -x - y, x - y]
	for k in 4:
		var c0: Vector3 = corners[k]
		var c1: Vector3 = corners[(k + 1) % 4]
		var nrm := (c0 + c1).normalized()
		var p0 := a + c0
		var p1 := a + c1
		var p2 := b + c1
		var p3 := b + c0
		_tri(p0, p1, p2, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, solid)
		_tri(p0, p2, p3, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, solid)
	_mode = keep


## The underside of a box at y over its whole outline, facing down (an overhang's soffit; the part
## over the inner floor is its ceiling, never seen).
func _soffit(outer: PackedVector2Array, y: float, col: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(outer)
	for i in range(0, idx.size() - 2, 3):
		var p0 := outer[idx[i]]
		var p1 := outer[idx[i + 1]]
		var p2 := outer[idx[i + 2]]
		_tri(Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), Vector3.DOWN, col,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)


## Vertical mullions every `step` m round `poly` between y0 and y1, `proud` m out from it.
func _mullions(poly: PackedVector2Array, y0: float, y1: float, step: float, proud: float, col: Color) -> void:
	_mode = M_STONE
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		if len < 1.0:
			continue
		var o := _out(poly, a, b)
		var d := (b - a) / len
		var n := maxi(1, roundi(len / step))
		for k in range(1, n):
			var c := a + d * len * k / n + o * proud
			var p0 := c - d * 0.07
			var p1 := c + d * 0.07
			_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y),
					Vector3(o.x, 0.0, o.y), col)


## A thin band round a ring, `proud` metres out of it, from y0 to y1 (walls only).
func _band(ring: PackedVector2Array, proud: float, y0: float, y1: float, col: Color, mode := M_STONE) -> void:
	var r := _largest(Geometry2D.offset_polygon(ring, proud, Geometry2D.JOIN_MITER))
	if r.size() >= 3:
		_prism(r, y0, y1, col, Color(0, 0, 0, 0), mode)


## A flat strip between two matched rings at y, facing up (or down).
func _strip(inner: PackedVector2Array, outer: PackedVector2Array, y: float, col: Color, down := false) -> void:
	var n := Vector3.DOWN if down else Vector3.UP
	for i in inner.size():
		var j := (i + 1) % inner.size()
		_quad(Vector3(inner[i].x, y, inner[i].y), Vector3(inner[j].x, y, inner[j].y), Vector3(outer[j].x, y, outer[j].y),
				Vector3(outer[i].x, y, outer[i].y), n, col)


func _centre(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q in poly:
		c += q
	return c / maxf(poly.size(), 1)


func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## The biggest of some polygons (an offset ring can break into pieces).
func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var size := 0.0
	for p: PackedVector2Array in polys:
		if absf(_area(p)) > size:
			size = absf(_area(p))
			best = p
	return best


# --- palette ---

## The 33 named colours of docs/design/facade-kit.md section 4: the most typical of the colours
## landmarks.gd already used for each role. A landmark takes a name the next time it is reworked.
const PAL_WHITE_STONE := Color("#ebe8df")  # white plaster, pale stone, columns, trim
const PAL_CREAM_STONE := Color("#e2d8c4")  # cream plaster and stone
const PAL_SANDSTONE := Color("#d9c3a0")  # sandstone, warm plaster
const PAL_OCHRE := Color("#d8b67a")  # ochre plaster, yellow brick
const PAL_GREY_STONE := Color("#a8a49c")  # grey stone and render
const PAL_PALE_CONCRETE := Color("#d4d0c6")  # copings, pale concrete, paving stone
const PAL_WARM_GRANITE := Color("#b9b2a2")  # plinths and bases
const PAL_GREY_GRANITE := Color("#8e8a82")  # granite, grey bases
const PAL_DARK_GRANITE := Color("#4a4744")  # dark plinths, polished stone
const PAL_RED_BRICK := Color("#a1503a")  # red brick
const PAL_DARK_BRICK := Color("#8a3a28")  # dark and burnt brick
const PAL_BROWN_RENDER := Color("#7a4a3d")  # brown render and piers
const PAL_ROOF_GREY := Color("#6d7470")  # zinc and sheet roofs
const PAL_ROOF_PALE := Color("#9a9c9c")  # lead, pale sheet, flat roofs
const PAL_ROOF_DARK := Color("#4d5256")  # slate, tar, dark zinc
const PAL_ROOF_TILE := Color("#a8503c")  # red tile
const PAL_ROOF_GRAVEL := Color("#b9b7b1")  # gravel and pale membrane
const PAL_PATINA_COPPER := Color("#6f9a8a")  # green copper
const PAL_NEW_COPPER := Color("#b26a3a")  # brown copper
const PAL_IRON := Color("#2a2c2f")  # wrought iron, dark frames
const PAL_DARK_STEEL := Color("#4a4e52")  # steel, dark metal
const PAL_ALUMINIUM := Color("#c3c7ca")  # aluminium, pale rails and frames
const PAL_BRONZE := Color("#4f4a40")  # bronze statues, doors
const PAL_GOLD := Color("#c9a24c")  # gilding
const PAL_GLASS_DARK := Color("#323a40")  # windows of old houses
const PAL_GLASS_NAVY := Color("#3e4d5a")  # office glass, dark
const PAL_GLASS_STEEL := Color("#5d717c")  # office glass, mid
const PAL_GLASS_PALE := Color("#8fa9b6")  # pale curtain wall
const PAL_GLASS_BLUE := Color("#4a74a6")  # blue glass
const PAL_DARK_DOOR := Color("#34393d")  # painted doors and gates
const PAL_OAK := Color("#5e432f")  # wooden doors
const PAL_TIMBER := Color("#a37a52")  # decks, planks, pale wood
const PAL_SIGNAL_RED := Color("#c8322e")  # red paint


# --- facade parts ---

## Window styles of `kit_window`: what surrounds the pane (docs/design/facade-kit.md section 3).
enum Win { PLAIN, SILL, SILL_HEAD, FRAMED, HOODED, PEDIMENT, ARCHED }
## Balcony kinds of `kit_balcony`: iron rail and bars, solid stone balustrade, parapet wall.
enum Balcony { IRON, STONE, PARAPET }
## What stands on a cornice (`kit_attic`): a plain parapet or a balustrade with piers.
enum Attic { WALL, BALUSTRADE }
## Column orders of `kit_column`, `kit_colonnade`, `kit_portico`.
enum Order { TUSCAN, CORINTHIAN }

## Where the current front's wall surface is in v (`kit_face`); every kit part stands on it.
var _face := 0.0


## Starts a front: u runs from `from` to `to` (plan, metres), v points out to the left of that
## direction, `_face` back to 0. Returns the front's width.
func kit_front(from: Vector2, to: Vector2) -> float:
	_o = from
	_a = (to - from).normalized()
	_b = Vector2(-_a.y, _a.x)
	_face = 0.0
	return from.distance_to(to)


## Says where the wall's surface is in v (metres out of the frame's line); parts stand on it.
func kit_face(v: float) -> void:
	_face = v


## A box between two u, two v (local metres) and two heights (absolute).
func _kbox(u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, col: Color,
		mode := M_STONE) -> void:
	_lbox((u0 + u1) * 0.5, (v0 + v1) * 0.5, (u1 - u0) * 0.5, (v1 - v0) * 0.5, y0, y1, col, mode)


## A ring `d` metres out of `ring` (mitred corners), vertex for vertex, so a strip can join them.
func _ring_out(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := ring.size()
	var out := PackedVector2Array()
	for i in n:
		var p := ring[i]
		var n1 := _out(ring, ring[(i + n - 1) % n], p)
		var n2 := _out(ring, p, ring[(i + 1) % n])
		out.append(p + (n1 + n2) * (d / maxf(1.0 + n1.dot(n2), 0.2)))
	return out


## A slab round `ring` from y0 to y1, `proud` metres out of it: its outer walls and a top strip
## from the ring to the outer edge (the inside is the building's own).
func _ring_slab(ring: PackedVector2Array, y0: float, y1: float, proud: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var outer := _ring_out(ring, proud)
	_prism(outer, y0, y1, col, Color(0, 0, 0, 0), M_STONE)
	_strip(ring, outer, y1, col.darkened(0.1))
	_mode = keep


## The wall slab of a front from u0 to u1, y0 to y1 (absolute), 0.4 m thick, its front on the face.
func kit_wall(u0: float, u1: float, y0: float, y1: float, col: Color) -> void:
	_kbox(u0, u1, _face - 0.4, _face, y0, y1, col)


## Rustication: a groove line (3 cm proud, 9 cm tall, in `col` darkened) every `step` metres of
## height between y0 and y1 (absolute), from u0 to u1.
func kit_bands(u0: float, u1: float, y0: float, y1: float, step: float, col: Color) -> void:
	if step < 0.2:
		return
	var line := col.darkened(0.14)
	var y := y0 + step
	while y + 0.09 < y1:
		_kbox(u0, u1, _face - 0.03, _face + 0.03, y, y + 0.09, line)
		y += step


## A string course or sill band from u0 to u1: a box `proud` metres out of the face, `h` tall,
## its foot at y (absolute).
func kit_ledge(u0: float, u1: float, y: float, h: float, col: Color, proud := 0.08) -> void:
	_kbox(u0, u1, _face - 0.04, _face + proud, y, y + h, col)


## The main cornice from u0 to u1: a frieze band 0.14 m proud and 0.4 m tall under y (absolute),
## and the slab `proud` out of the face and `h` tall on it, running 0.5 m past each end.
func kit_cornice(u0: float, u1: float, y: float, col: Color, h := 0.5, proud := 1.0) -> void:
	_kbox(u0, u1, _face - 0.14, _face + 0.14, y - 0.4, y, col)
	_kbox(u0 - 0.5, u1 + 0.5, _face - 0.17, _face + proud, y, y + h, col)


## `kit_ledge` round a whole plan ring (a free-standing block), foot at y (absolute).
func kit_ledge_ring(ring: PackedVector2Array, y: float, h: float, col: Color, proud := 0.08) -> void:
	_ring_slab(ring, y, y + h, proud, col)


## `kit_cornice` round a whole plan ring: a frieze ring 0.14 m proud under y, the slab ring
## `proud` out and `h` tall on it. The ring's inside is left to the building's own roof.
func kit_cornice_ring(ring: PackedVector2Array, y: float, col: Color, h := 0.5, proud := 1.0) -> void:
	_prism(_ring_out(ring, 0.14), y - 0.4, y, col, Color(0, 0, 0, 0), M_STONE)
	_ring_slab(ring, y, y + h, proud, col)


## What stands on the cornice from u0 to u1, foot at y (absolute), `h` tall: `WALL` a plain
## parapet with a coping; `BALUSTRADE` a plinth, a shaded baluster field, a rail and a pier
## about every 3 m (two at the ends).
func kit_attic(u0: float, u1: float, y: float, col: Color, h := 1.0, kind := Attic.BALUSTRADE) -> void:
	var vc := _face - 0.02
	if kind == Attic.WALL:
		_kbox(u0, u1, vc - 0.14, vc + 0.14, y, y + h - 0.2, col)
		_kbox(u0, u1, vc - 0.18, vc + 0.18, y + h - 0.2, y + h, col.lightened(0.05))
		return
	_kbox(u0, u1, vc - 0.18, vc + 0.18, y, y + 0.2, col)
	_kbox(u0, u1, vc - 0.1, vc + 0.1, y + 0.2, y + h - 0.2, col.darkened(0.12))
	_kbox(u0, u1, vc - 0.16, vc + 0.16, y + h - 0.2, y + h, col)
	var n := maxi(1, roundi((u1 - u0) / 3.0))
	for k in n + 1:
		var c := u0 + 0.2 + (u1 - u0 - 0.4) * float(k) / float(n)
		_kbox(c - 0.2, c + 0.2, vc - 0.2, vc + 0.2, y, y + h + 0.1, col)


## A flat pilaster at u, from y0 to y1 (absolute), `w` wide and `proud` out of the face, with a
## base and a capital block each a little wider and prouder.
func kit_pilaster(u: float, y0: float, y1: float, col: Color, w := 0.6, proud := 0.12) -> void:
	var hw := w * 0.5
	_kbox(u - hw, u + hw, _face - 0.04, _face + proud, y0, y1 - 0.3, col)
	_kbox(u - hw - 0.06, u + hw + 0.06, _face - 0.04, _face + proud + 0.04, y0, y0 + 0.3, col)
	_kbox(u - hw - 0.06, u + hw + 0.06, _face - 0.04, _face + proud + 0.04, y1 - 0.3, y1, col.lightened(0.05))


## A free column at u, v (local metres), from y0 to y1 (absolute), shaft radius `r`: `TUSCAN` a
## square plinth, an 8-sided shaft and a square capital; `CORINTHIAN` a 6-sided shaft with a
## flared capital under a square abacus.
func kit_column(u: float, v: float, y0: float, y1: float, col: Color, r := 0.4, order := Order.TUSCAN) -> void:
	if order == Order.TUSCAN:
		_column(u, v, r, y0, y1, col)
		return
	var keep := _mode
	_mode = M_STONE
	var h := y1 - y0
	var base := minf(0.45, h * 0.05)
	var cap := minf(0.9, h * 0.12)
	var c := _w(u, v)
	_prism(_rect(u, v, r * 1.35, r * 1.35), y0, y0 + base, col.darkened(0.04), col.darkened(0.08), M_STONE, M_STONE)
	_prism(_circle(c, r, 6), y0 + base, y1 - cap, col, Color(0, 0, 0, 0), M_STONE)
	_frustum(_circle(c, r, 6), y1 - cap, _circle(c, r * 1.5, 6), y1 - cap * 0.3, col.lightened(0.03))
	_lbox(u, v, r * 1.55, r * 1.55, y1 - cap * 0.3, y1, col.lightened(0.05))
	_mode = keep


## `n` columns evenly from u0 to u1 (the first on u0, the last on u1), `v` out of the frame's
## line, from y0 to y1 (absolute), shaft radius `r`. Returns their u.
func kit_colonnade(u0: float, u1: float, n: int, v: float, y0: float, y1: float, col: Color, r := 0.4,
		order := Order.TUSCAN) -> Array[float]:
	var out: Array[float] = []
	for k in n:
		var u := (u0 + u1) * 0.5 if n == 1 else u0 + (u1 - u0) * float(k) / float(n - 1)
		kit_column(u, v, y0, y1, col, r, order)
		out.append(u)
	return out


## One window at u: sill at y (absolute), the pane `h` tall and 2 * `hw` wide in `glass` (lit by
## chance at night), `style` (`Win`) the surround in `trim`. Proportions are the kit's:
## pane 5 cm proud; sill hw + 0.28 half wide, 0.30 deep, 0.16 tall under the pane; head hw + 0.20
## half wide, 0.17 tall just over it; jambs 0.2 square at hw + 0.08; a hood hw + 0.28 half
## wide to 0.30 over the pane; a two-step pediment on the head; an arched head of glass and trim.
func kit_window(u: float, y: float, h: float, style: Win, trim: Color, glass := PAL_GLASS_DARK, hw := 0.7) -> void:
	var f := _face
	var top := y + h
	_lbox(u, f + 0.02, hw, 0.03, y, top, glass, _lit(u, y))
	if style == Win.PLAIN:
		return
	if style == Win.FRAMED or style == Win.HOODED:
		for s: float in [-1.0, 1.0]:
			_lbox(u + s * (hw + 0.08), f + 0.02, 0.1, 0.1, y - 0.1, top + 0.1, trim)
	_lbox(u, f + 0.0575, hw + 0.28, 0.15, y - 0.20, y - 0.06, trim)  # the sill
	if style == Win.SILL:
		return
	if style == Win.HOODED:
		_lbox(u, f + 0.08, hw + 0.28, 0.18, top + 0.05, top + 0.30, trim)
		return
	_lbox(u, f + 0.0675, hw + 0.20, 0.1125, top + 0.05, top + 0.22, trim)  # the head
	if style == Win.PEDIMENT:
		_lbox(u, f + 0.08, hw + 0.12, 0.12, top + 0.22, top + 0.34, trim)
		_lbox(u, f + 0.08, hw - 0.23, 0.12, top + 0.34, top + 0.50, trim)
	elif style == Win.ARCHED:
		_lbox(u, f + 0.02, hw * 0.67, 0.03, top, top + 0.30, glass)
		_lbox(u, f + 0.08, hw * 0.86, 0.12, top + 0.24, top + 0.50, trim)


## A window in every bay (bay centres evenly between u0 and u1) on every sill height in `sills`
## (absolute); `h` a float or an array with one per sill; `skip` holds `Vector2i(bay, floor)` to
## leave out. Returns the bay centres.
func kit_window_grid(u0: float, u1: float, bays: int, sills: Array, h: Variant, style: Win, trim: Color,
		glass: Color, hw: float, skip: Array = []) -> Array[float]:
	var centres: Array[float] = []
	for c: float in _spread(u0, u1, bays):
		centres.append(c)
	for i in sills.size():
		var height := float(h[i]) if h is Array else float(h)
		for k in bays:
			if skip.has(Vector2i(k, i)):
				continue
			kit_window(centres[k], float(sills[i]), height, style, trim, glass, hw)
	return centres


## Flat lit panes with no surround, one quad each, `proud` metres out of the face: a pane `w`
## wide and `h` tall at every u in `cols` (centres) and every sill height in `rows` (absolute).
func kit_panes(cols: Array, rows: Array, w: float, h: float, glass: Color, proud := 0.05) -> void:
	var keep := _mode
	for r in rows:
		var y := float(r)
		for c in cols:
			var u := float(c)
			_mode = _lit(u, y)
			_wall(_w(u - w * 0.5, _face + proud), _w(u + w * 0.5, _face + proud), y, y + h, _b, glass)
	_mode = keep


## A ground-floor opening at u, 2 * `hw` wide: dark glass from y0 to y1 (absolute) and a lintel
## band in `trim` over it.
func kit_shop_bay(u: float, y0: float, y1: float, hw: float, trim: Color, glass: Color) -> void:
	_kbox(u - hw, u + hw, _face - 0.01, _face + 0.05, y0, y1, glass)
	_kbox(u - hw - 0.12, u + hw + 0.12, _face - 0.03, _face + 0.15, y1, y1 + 0.2, trim)


## A door leaf at u, foot at y (absolute), `h` tall and 2 * `hw` wide in `leaf`, in a surround of
## `trim`: a flat head, or when `arched` a round head with a keystone (`h` then counts the arch).
func kit_door(u: float, y: float, h: float, hw: float, trim: Color, leaf: Color, arched := false) -> void:
	var f := _face
	if not arched:
		_kbox(u - hw, u + hw, f - 0.01, f + 0.05, y, y + h, leaf)
		_kbox(u - hw - 0.2, u + hw + 0.2, f - 0.06, f + 0.14, y + h, y + h + 0.25, trim)
		return
	var spring := y + h - hw
	var at := _w(u, f)
	_arch_panel(at, _a, _b, hw + 0.15, y, spring, trim, 0.03, M_STONE)
	_arch_panel(at, _a, _b, hw, y, spring, leaf, 0.07, M_STONE)
	_kbox(u - 0.18, u + 0.18, f - 0.02, f + 0.12, y + h + 0.02, y + h + 0.32, trim)


## A balcony at u on the storey whose sill is at y (absolute), 2 * `hw` wide and `depth` out of
## the face: `IRON` a slab 0.20 thick, a top rail 0.85 to 0.92 over it on the front and both
## sides, a bar every 0.42 m or closer; `STONE` a slab 0.28 thick, a solid balustrade 1.0 high
## and 0.14 thick on the front and both sides, two brackets under it; `PARAPET` a slab and a
## solid front wall 0.86 high with a coping, no sides. `rail` is the railing, balustrade or wall.
func kit_balcony(u: float, y: float, hw: float, kind: Balcony, rail: Color, slab: Color, depth := 1.0) -> void:
	var v0 := _face + 0.01
	var vf := v0 + depth
	match kind:
		Balcony.IRON:
			var vm := v0 + depth * 0.5
			_lbox(u, vm, hw, depth * 0.5, y - 0.26, y - 0.06, slab)
			_lbox(u, v0 + depth - 0.05, hw, 0.03, y + 0.85, y + 0.92, rail)
			var n := maxi(1, ceili(2.0 * hw / 0.42))
			for j in n + 1:
				_lbox(u - hw + 2.0 * hw * float(j) / float(n), v0 + depth - 0.05, 0.03, 0.03, y - 0.06, y + 0.85, rail)
			for s: float in [-1.0, 1.0]:
				_lbox(u + s * hw, vm, 0.025, depth * 0.5 - 0.02, y + 0.85, y + 0.92, rail)
		Balcony.STONE:
			_kbox(u - hw, u + hw, v0, vf, y - 0.34, y - 0.06, slab)
			_kbox(u - hw, u + hw, vf - 0.14, vf, y - 0.06, y + 0.94, rail)
			for s: float in [-1.0, 1.0]:
				var c := u + s * (hw - 0.07)
				_kbox(c - 0.07, c + 0.07, v0, vf - 0.14, y - 0.06, y + 0.94, rail)
				var b := u + s * (hw - 0.3)
				_kbox(b - 0.12, b + 0.12, v0, v0 + depth * 0.6, y - 0.74, y - 0.34, slab)
		_:
			_kbox(u - hw, u + hw, v0, vf, y - 0.28, y - 0.06, slab)
			_kbox(u - hw, u + hw, vf - 0.14, vf, y - 0.06, y + 0.80, rail)
			_kbox(u - hw, u + hw, vf - 0.18, vf, y + 0.80, y + 0.92, slab)


## A triangular gable over u +- hw standing `depth` out of the face, its base at y (absolute) and
## apex `h` over it; its two roof slopes in `roof` run back into the wall. A darker triangle of
## `relief` on the face of it when `relief` is opaque.
func kit_pediment(u: float, hw: float, y: float, h: float, col: Color, roof: Color, depth := 0.45,
		relief := Color(0, 0, 0, 0)) -> void:
	var keep := _mode
	_mode = M_STONE
	var vf := _face + depth
	var at := func(uu: float, vv: float, yy: float) -> Vector3:
		var p := _w(uu, vv)
		return Vector3(p.x, yy, p.y)
	var out := Vector3(_b.x, 0.0, _b.y)
	var along := Vector3(_a.x, 0.0, _a.y)
	var y0 := y - _g
	var top := y + h - _g
	var l: Vector3 = at.call(u - hw, vf, y)
	var r: Vector3 = at.call(u + hw, vf, y)
	var apex: Vector3 = at.call(u, vf, y + h)
	var lb: Vector3 = at.call(u - hw, _face, y)
	var rb: Vector3 = at.call(u + hw, _face, y)
	var apex_b: Vector3 = at.call(u, _face, y + h)
	_tri(l, r, apex, out, col, Vector2(0, y0), Vector2(hw * 2.0, y0), Vector2(hw, top), top)
	if relief.a > 0.0:
		var li: Vector3 = at.call(u - hw * 0.7, vf + 0.03, y + h * 0.12)
		var ri: Vector3 = at.call(u + hw * 0.7, vf + 0.03, y + h * 0.12)
		var ai: Vector3 = at.call(u, vf + 0.03, y + h * 0.72)
		_tri(li, ri, ai, out, relief, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	var nl := (-along * h + Vector3.UP * hw).normalized()
	var nr := (along * h + Vector3.UP * hw).normalized()
	_quad(l, lb, apex_b, apex, nl, roof)
	_quad(r, rb, apex_b, apex, nr, roof)
	_mode = keep


## A portico at u (half width `hw`): steps from y0 (absolute, the ground), `n` columns of `order`
## `depth` out of the face standing on the top step up to y1, an entablature on them back to the
## wall and a pediment a quarter of its width tall in `roof`. Column radius follows the height.
func kit_portico(u: float, hw: float, y0: float, y1: float, n: int, col: Color, roof: Color, depth := 3.0,
		steps := 3, order := Order.TUSCAN) -> void:
	var f := _face
	var rise := 0.2
	for k in steps:
		var run := 0.4 * float(steps - 1 - k)
		_kbox(u - hw - 0.45 - run, u + hw + 0.45 + run, f - 0.04, f + depth + 0.3 + run,
				y0 + k * rise, y0 + (k + 1) * rise, col.darkened(0.03))
	var top := y0 + steps * rise
	var r := clampf((y1 - top) / 12.0, 0.25, 0.7)
	var edge := r * 1.6
	kit_colonnade(u - hw + edge, u + hw - edge, n, f + depth - edge, top, y1, col, r, order)
	_kbox(u - hw, u + hw, f - 0.04, f + depth, y1, y1 + 0.5, col)
	_kbox(u - hw - 0.25, u + hw + 0.25, f - 0.04, f + depth + 0.25, y1 + 0.5, y1 + 0.75, col)
	kit_pediment(u, hw + 0.25, y1 + 0.75, (hw + 0.25) * 0.5, col, roof, depth + 0.25)


## A roof lantern at u, v (local metres) standing on y (absolute): a `sides`-sided drum `h` * 0.7
## tall and `r` in radius with a lit pane in each face, a ledge, a pointed cap in `roof` and a
## finial. The drum and ledge are `wall`, the panes `glass`.
func kit_lantern(u: float, v: float, y: float, h: float, r: float, wall: Color, roof: Color,
		glass := PAL_GLASS_DARK, sides := 8) -> void:
	var keep := _mode
	_mode = M_STONE
	var c := _w(u, v)
	var drum := _circle(c, r, sides)
	var y_top := y + h * 0.7
	_prism(drum, y, y_top, wall, Color(0, 0, 0, 0), M_STONE)
	for i in sides:
		var a := drum[i]
		var b := drum[(i + 1) % sides]
		var out := _out(drum, a, b)
		var mid := (a + b) * 0.5 + out * 0.04
		var half := (b - a) * 0.3
		_mode = _lit(float(i) * 1.7 + u, y)
		_wall(mid - half, mid + half, y + h * 0.12, y + h * 0.58, out, glass)
	_mode = M_STONE
	var ledge := wall.lightened(0.05)
	_prism(_circle(c, r * 1.18, sides), y_top, y_top + h * 0.06, ledge, ledge.darkened(0.1), M_STONE, M_STONE)
	_pyramid(_circle(c, r * 1.25, sides), y_top + h * 0.06, y + h * 0.94, roof)
	var pin := roof.lightened(0.1)
	_prism(_circle(c, 0.07, 4), y + h * 0.94 - 0.1, y + h, pin, pin, M_STONE, M_STONE)
	_mode = keep


# --- the sampler ---

## One street front and one free-standing pavilion that use every kit part and style once
## (docs/design/facade-kit.md section 6): the test of `check_mesh_quality.gd` and the picture of
## the kit (`--solo=kit_sampler`). Stands at a fixed spot in the city's west.
func kit_sampler() -> void:
	var x0 := -1180.0
	var z0 := 330.0
	_g = map.terrain_height(x0, z0)
	_mode = M_STONE
	var g := _g
	var glass := PAL_GLASS_DARK
	# --- the street front: 30 m, seven bays, a banded ground floor under four storeys ---
	var wide := kit_front(Vector2(x0, z0), Vector2(x0 + 30.0, z0))
	var top := g + 19.4
	var bays := 7
	var bay := wide / bays
	_lbox(wide * 0.5, -6.4, wide * 0.5, 6.0, g, top, PAL_SANDSTONE, M_STONE, PAL_ROOF_GREY)
	kit_wall(0.0, wide, g - 0.3, g + 5.0, PAL_GREY_STONE)
	kit_wall(0.0, wide, g + 5.0, top, PAL_CREAM_STONE)
	# Ground floor: shop bays, the door in the middle bay; the grooves only on the piers between.
	var spans: Array[Vector2] = []
	var centres := _spread(0.0, wide, bays)
	for k in bays:
		var c: float = centres[k]
		if k == 3:
			kit_door(c, g, 3.6, 0.95, PAL_WHITE_STONE, PAL_OAK, true)
			spans.append(Vector2(c - 1.2, c + 1.2))
		else:
			kit_shop_bay(c, g + 0.5, g + 3.7, 1.5, PAL_WHITE_STONE, glass)
			spans.append(Vector2(c - 1.65, c + 1.65))
	var at := 0.0
	for s in spans:
		if s.x - at > 0.5:
			kit_bands(at + 0.1, s.x - 0.1, g, g + 4.7, 1.15, PAL_GREY_STONE)
		at = s.y
	if wide - at > 0.5:
		kit_bands(at + 0.1, wide - 0.1, g, g + 4.7, 1.15, PAL_GREY_STONE)
	kit_ledge(0.0, wide, g + 4.9, 0.35, PAL_WHITE_STONE)
	# Four storeys, a different window style on each; the top one mixes the plain styles.
	kit_window_grid(0.0, wide, bays, [g + 5.7], 2.4, Win.PEDIMENT, PAL_WHITE_STONE, glass, 0.7)
	kit_window_grid(0.0, wide, bays, [g + 9.7], 2.4, Win.HOODED, PAL_WHITE_STONE, glass, 0.7)
	kit_window_grid(0.0, wide, bays, [g + 13.2], 2.2, Win.FRAMED, PAL_WHITE_STONE, glass, 0.7)
	kit_ledge(0.0, wide, g + 15.8, 0.25, PAL_WHITE_STONE)
	kit_window_grid(0.0, wide, bays, [g + 16.5], 1.9, Win.ARCHED, PAL_WHITE_STONE, glass, 0.7,
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(5, 0), Vector2i(6, 0)])
	kit_window(centres[0], g + 16.5, 1.9, Win.PLAIN, PAL_WHITE_STONE, glass, 0.7)
	kit_window(centres[1], g + 16.5, 1.9, Win.SILL, PAL_WHITE_STONE, glass, 0.7)
	kit_window(centres[5], g + 16.5, 1.9, Win.SILL_HEAD, PAL_WHITE_STONE, glass, 0.7)
	kit_window(centres[6], g + 16.5, 1.9, Win.PLAIN, PAL_WHITE_STONE, glass, 0.7)
	# One balcony of each kind.
	kit_balcony(centres[1], g + 5.7, 1.2, Balcony.IRON, PAL_IRON, PAL_WHITE_STONE)
	kit_balcony(centres[5], g + 9.7, 1.2, Balcony.STONE, PAL_WHITE_STONE, PAL_PALE_CONCRETE, 1.1)
	kit_balcony(centres[2], g + 13.2, 1.2, Balcony.PARAPET, PAL_WARM_GRANITE, PAL_PALE_CONCRETE, 0.9)
	# Pilasters at the corners and either side of the door bay, the cornice and the attic.
	for pu: float in [0.35, wide - 0.35, wide * 0.5 - bay * 0.5, wide * 0.5 + bay * 0.5]:
		kit_pilaster(pu, g + 5.25, g + 18.95, PAL_WHITE_STONE)
	kit_cornice(0.0, wide, top, PAL_WHITE_STONE)
	kit_attic(0.0, wide, top + 0.5, PAL_WHITE_STONE, 1.0, Attic.BALUSTRADE)
	# --- the pavilion: 10 by 8 m, a portico on its front, 8 m east of the front ---
	var pw := kit_front(Vector2(x0 + 38.0, z0), Vector2(x0 + 48.0, z0))
	var ring := _rect(pw * 0.5, -4.0, pw * 0.5, 4.0)
	var wall_top := g + 8.0
	_prism(ring, g, wall_top, PAL_CREAM_STONE, PAL_ROOF_GREY, M_STONE, M_STONE)
	kit_ledge_ring(ring, g, 0.5, PAL_WARM_GRANITE, 0.12)
	kit_ledge_ring(ring, g + 4.7, 0.2, PAL_WHITE_STONE, 0.08)
	kit_cornice_ring(ring, g + 7.5, PAL_WHITE_STONE, 0.5, 0.7)
	kit_portico(pw * 0.5, 3.2, g, g + 4.5, 4, PAL_WHITE_STONE, PAL_ROOF_GREY, 3.0, 3, Order.TUSCAN)
	kit_door(pw * 0.5, g + 0.6, 3.4, 1.1, PAL_WHITE_STONE, PAL_OAK, true)
	kit_face(-8.0)  # the back wall: a plain parapet on the cornice
	kit_attic(0.0, pw, wall_top, PAL_WHITE_STONE, 0.9, Attic.WALL)
	kit_face(0.0)
	# The lantern on a roof slab.
	_lbox(pw * 0.5, -4.0, 2.4, 2.4, wall_top, wall_top + 0.4, PAL_ROOF_PALE)
	kit_lantern(pw * 0.5, -4.0, wall_top + 0.4, 2.4, 1.3, PAL_WHITE_STONE, PAL_PATINA_COPPER, glass, 8)
	# The west side: flat lit panes.
	kit_front(Vector2(x0 + 38.0, z0 - 8.0), Vector2(x0 + 38.0, z0))
	kit_panes([1.5, 3.2, 4.8, 6.5], [g + 1.2, g + 5.1], 1.0, 1.6, glass)
	# The east side: a Corinthian colonnade under a beam.
	kit_front(Vector2(x0 + 48.0, z0), Vector2(x0 + 48.0, z0 - 8.0))
	kit_colonnade(1.2, 6.8, 4, 1.4, g, g + 4.4, PAL_WHITE_STONE, 0.3, Order.CORINTHIAN)
	kit_ledge(0.4, 7.6, g + 4.4, 0.45, PAL_WHITE_STONE, 2.0)
