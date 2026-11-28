extends "res://scripts/landmarks/river.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Muranów: POLIN, the monuments,
## Kino Muranów, the Dekalog estate, the Inflancka pools, Pokorna 2. Moved as it was from the one
## big file. landmarks.gd is the class the game makes; every file of game/scripts/landmarks/ is one
## link of its base chain (facade_kit.gd, common.gd, then the areas in the order of landmarks.gd's
## `extends` chain), so code here may use this file, common.gd and the facade kit, never another
## area: a helper two areas need goes to common.gd.


# --- Pałac Mostowskich ----------------------------------------------------------------------

## Southeast front, with positive u along the facade and positive v into the forecourt.
const MOSTOWSKI_O := Vector2(-1720.3, -1304.3)
const MOSTOWSKI_U := Vector2(0.853, -0.522)
const MOSTOWSKI_OUTER := [[0.0, 0.0], [51.1, 0.0], [52.0, -116.2], [0.3, -124.2]]
## Inner eaves from GUGiK. The rear court flares out in front of the skewed rear range.
const MOSTOWSKI_COURTS := [
	[[14.9, -12.6], [37.7, -12.6], [37.8, -37.7], [14.7, -37.3]],
	[[17.0, -47.3], [35.6, -47.7], [35.8, -60.8], [16.9, -60.7]],
	[[15.1, -71.5], [37.2, -71.9], [37.9, -94.5], [42.8, -94.7], [43.1, -99.2],
			[9.9, -104.2], [9.5, -97.3], [14.7, -97.3]],
]
## Ridge points opposite the eaves. The cross ranges share ridge edges between adjacent courts.
const MOSTOWSKI_RIDGE := [[7.4, -6.5], [44.6, -6.5], [44.6, -108.0], [7.4, -115.0]]
const MOSTOWSKI_COURT_RIDGES := [
	[[7.4, -6.5], [44.6, -6.5], [44.6, -42.5], [7.4, -42.5]],
	[[7.4, -42.5], [44.6, -42.5], [44.6, -66.2], [7.4, -66.2]],
	[[7.4, -66.2], [44.6, -66.2], [44.6, -92.0], [44.6, -96.0], [44.6, -108.0],
			[7.4, -115.0], [7.4, -102.0], [7.4, -95.0]],
]
const MOSTOWSKI_EAVE := 13.35
const MOSTOWSKI_RISE := 3.85
const MOSTOWSKI_SHOULDER := 17.75
const MOSTOWSKI_BREAKS := Vector2(13.1, 37.9)
const MOSTOWSKI_FACE := 3.7
## Cream plaster and blue-grey roofing from the daylight views of the two long wings.
const MOSTOWSKI_WALL := Color("#eee3c9")
const MOSTOWSKI_ROOF := Color("#9a9ba2")


## Replace the mapped palace as one mesh, retaining the open courts in the roof and collision.
func _build_mostowski(site: Dictionary) -> void:
	kit_front(MOSTOWSKI_O, MOSTOWSKI_O + MOSTOWSKI_U)
	var entrance := _w(25.6, 6.0)
	_g = map.terrain_height(entrance.x, entrance.y)
	_mode = M_STONE
	var outline: PackedVector2Array = site["zone"][0]
	var foot := _ground_under(outline) - 0.6
	var outer := _lpoly(MOSTOWSKI_OUTER)
	var courts: Array[PackedVector2Array] = []
	for plan: Array in MOSTOWSKI_COURTS:
		courts.append(_lpoly(plan))
	_mostowski_roofs(outer, courts)
	_mostowski_chimneys()
	_mostowski_shell(outer, courts, foot)
	_mostowski_portico(foot)
	_collide(outline)
	for court: PackedVector2Array in courts:
		_collide(court)


## Build the outer and court walls as separate loops so the stonework leaves each court open.
func _mostowski_shell(outer: PackedVector2Array, courts: Array[PackedVector2Array], foot: float) -> void:
	var trim := PAL_CREAM_STONE
	var eave := _g + MOSTOWSKI_EAVE
	kit_ledge_ring(outer, foot, _g + 0.42 - foot, PAL_WARM_GRANITE, 0.09)
	kit_ledge_ring(outer, _g + 4.8, 0.22, trim, 0.15)
	kit_cornice_ring(outer, eave - 0.35, trim, 0.35, 0.47)
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		var width := kit_front(a, b)
		if i == 0:
			_mostowski_elevations(0.0, MOSTOWSKI_BREAKS.x, 3, true)
			_mostowski_elevations(MOSTOWSKI_BREAKS.y, width, 3, true)
			for span: Vector2 in [Vector2(0.1, MOSTOWSKI_BREAKS.x), Vector2(MOSTOWSKI_BREAKS.y, width - 0.1)]:
				kit_bands(span.x, span.y, _g + 0.48, _g + 4.7, 0.64, MOSTOWSKI_WALL)
		elif i == 2:
			# The skewed rear face has seven close-set bays between two groups of four.
			_mostowski_elevations(0.0, 16.5, 4, true)
			_mostowski_elevations(16.5, 35.2, 7, true, false, true)
			_mostowski_elevations(35.2, width, 4, true)
		else:
			_mostowski_elevations(0.0, width, roundi(width / 4.0), false)
		_wall(a, b, foot, eave, _b, MOSTOWSKI_WALL)
	for court: PackedVector2Array in courts:
		for i in court.size():
			var a := court[(i + 1) % court.size()]
			var b := court[i]
			var width := kit_front(a, b)
			if width > 3.5:
				kit_ledge(0.23, width - 0.23, _g + 4.8, 0.18, trim, 0.14)
				kit_cornice(0.9, width - 0.9, eave - 0.35, trim, 0.35, 0.34)
				var door := i == 2 or (i == 0 and court.size() == 4) or i == 4
				_mostowski_elevations(0.0, width, roundi(width / 3.65), false, true, door)
			_wall(a, b, foot, eave, _b, MOSTOWSKI_WALL)


## Lay out the same three storeys on each elevation, with simpler surrounds inside the courts.
func _mostowski_elevations(u0: float, u1: float, bays: int, formal: bool, court := false,
		door := false) -> void:
	var trim := PAL_WHITE_STONE
	var glass := PAL_GLASS_DARK
	var sash := PAL_CREAM_STONE
	for k in bays:
		var u := lerpf(u0, u1, (float(k) + 0.5) / bays)
		if door and k == bays / 2:
			kit_door(u, _g - 0.25, 4.45, 1.28, trim, PAL_DARK_DOOR, true)
		elif court:
			kit_panes([u], [_g + 1.06], 1.38, 2.56, glass)
		else:
			kit_window(u, _g + 1.06, 2.56, Win.PLAIN, trim, glass, 0.73, sash)
		var middle := Win.PLAIN if court else (Win.SILL_HEAD if formal else Win.SILL)
		kit_window(u, _g + 6.04, 2.90, middle, trim, glass, 0.73, sash)
		if court:
			kit_panes([u], [_g + 10.43], 1.38, 1.8, glass)
		else:
			kit_window(u, _g + 10.43, 1.8, Win.SILL if formal else Win.PLAIN, trim, glass, 0.68, sash)


## The portico stands on the three-arched podium. The flared kit capitals approximate the Ionic order.
func _mostowski_portico(foot: float) -> void:
	kit_front(MOSTOWSKI_O, MOSTOWSKI_O + MOSTOWSKI_U)
	var trim := PAL_WHITE_STONE
	var g := _g
	var u0 := MOSTOWSKI_BREAKS.x
	var u1 := MOSTOWSKI_BREAKS.y
	var mid := 25.65
	var half := 6.7
	var face := MOSTOWSKI_FACE
	var podium := 6.0
	kit_face(face)
	_mostowski_elevations(u0 + 0.2, mid - half - 0.2, 1, true)
	_mostowski_elevations(mid + half + 0.2, u1 - 0.2, 1, true)
	for u: float in [21.5, 25.65, 29.8]:
		kit_window(u, g + 6.04, 3.1, Win.SILL_HEAD, trim, PAL_GLASS_DARK, 0.76, PAL_CREAM_STONE)
		kit_window(u, g + 11.2, 1.95, Win.SILL, trim, PAL_GLASS_DARK, 0.72, PAL_CREAM_STONE)
	kit_ledge(u0, u1, g + 4.8, 0.23, trim, 0.2)
	kit_cornice(u0 + 0.5, u1 - 0.5, g + 17.40, trim, 0.35, 0.36)
	kit_bands(u0 + 0.1, u1 - 0.1, g + 0.48, g + 4.7, 0.64, MOSTOWSKI_WALL)
	kit_ledge(mid - half, mid + half, g + 16.20, 0.92, trim, 2.46)
	kit_cornice(mid - half + 0.16, mid + half - 0.16, g + 17.15, trim, 0.48, 2.62)
	kit_pediment(mid, 7.04, g + 17.63, 1.96, trim, MOSTOWSKI_ROOF, 2.61, PAL_CREAM_STONE)
	kit_colonnade(19.9, 31.4, 4, 5.1, g + 4.88, g + 16.20, trim, 0.56, Order.CORINTHIAN)
	kit_face(podium)
	kit_ledge(mid - half, mid + half, g + 4.61, 0.27, trim, 0.22)
	kit_bands(mid - half, mid + half, g + 0.48, g + 4.5, 0.64, MOSTOWSKI_WALL)
	kit_face(podium + 0.04)  # clear the rustication with the arch surrounds
	for u: float in [21.5, 25.65, 29.8]:
		kit_door(u, g - 0.25, 4.45, 1.26 if u == mid else 0.96, trim, PAL_OAK, true)
	_ubox(19.0, 32.4, face - 0.1, podium, foot, g + 4.81, PAL_SANDSTONE)
	_prism(_urect(u0, u1, -5.8, face), foot, g + MOSTOWSKI_SHOULDER,
			MOSTOWSKI_WALL, Color.TRANSPARENT, M_STONE)
	_hip(mid - 0.15, -1.05, 12.4, 4.75, g + MOSTOWSKI_SHOULDER, 1.15, MOSTOWSKI_ROOF)


## Join outer hips and court slopes along the same ridges without spanning the courtyards.
func _mostowski_roofs(outer: PackedVector2Array, courts: Array[PackedVector2Array]) -> void:
	var eave := _g + MOSTOWSKI_EAVE
	var top := eave + MOSTOWSKI_RISE
	var eaves: Array[PackedVector2Array] = [_ring_out(outer, 0.20)]
	eaves.append_array(courts)
	var ridges: Array[PackedVector2Array] = [_lpoly(MOSTOWSKI_RIDGE)]
	for plan: Array in MOSTOWSKI_COURT_RIDGES:
		ridges.append(_lpoly(plan))
	for k in eaves.size():
		var lower := eaves[k]
		var upper := ridges[k]
		for i in lower.size():
			var j := (i + 1) % lower.size()
			var corners := PackedVector2Array([lower[i], lower[j], upper[j], upper[i]])
			# The rear court's shoulders make concave slopes in plan. Triangulate there
			# with the same eave and ridge corners as the neighbouring slopes.
			var plan := PackedVector2Array()
			var points: Array[Vector3] = []
			for m in corners.size():
				var p := corners[m]
				plan.append(p - MOSTOWSKI_O)
				points.append(Vector3(p.x, eave if m < 2 else top, p.y))
			var triangles := Geometry2D.triangulate_polygon(plan)
			var uv := Vector2(-1.0, -1.0)
			for m in range(0, triangles.size(), 3):
				var a := points[triangles[m]]
				var b := points[triangles[m + 1]]
				var c := points[triangles[m + 2]]
				var n := (b - a).cross(c - a).normalized()
				_tri(a, b, c, n if n.y > 0.0 else -n, MOSTOWSKI_ROOF, uv, uv, uv, -1.0)


## Pale chimney stacks and caps break the silhouette of the long roofs in the aerial views.
func _mostowski_chimneys() -> void:
	var top := _g + MOSTOWSKI_EAVE + MOSTOWSKI_RISE
	for v: float in [-19.0, -32.0, -55.0, -78.0, -90.0]:
		for u: float in [7.4, 44.6]:
			_lbox(u, v, 0.56, 0.84, top - 0.74, top + 0.8, PAL_CREAM_STONE)
			_lbox(u, v, 0.64, 0.92, top + 0.8, top + 0.98, PAL_PALE_CONCRETE)
	for p: Vector2 in [Vector2(19.2, -111.7), Vector2(34.3, -109.9), Vector2(25.6, -66.2), Vector2(14.8, -42.5)]:
		_lbox(p.x, p.y, 0.96, 0.56, top - 0.75, top + 1.04, PAL_CREAM_STONE)
		_lbox(p.x, p.y, 1.04, 0.64, top + 1.04, top + 1.25, PAL_PALE_CONCRETE)


# --- Pokorna 2: the residential tower by Muranów ---------------------------------------------

## F (2026-11-01): "Pokorna 2 looks strange, not as an apartment". OpenStreetMap has it as one
## 57 m `apartments` outline (12 corners, a stepped 1970s block off Pokorna) and the plain
## extrusion read as an office. Spec docs/landmarks/specs/pokorna2.md: the long faces take the
## loggia skin S_SLAB (a window in every 3.6 m bay) plus a real balcony slab and railing on
## every floor; the short faces stay plain; lift house and water tank on the flat roof. Unnamed.
const POKORNA2_AT := Vector2(-2123.0, -2217.0)
const POKORNA2_FLOOR := 2.85          # the S_SLAB shader's floor height
const POKORNA2_PLASTER := Color("#d6c3ad")
const POKORNA2_END := Color("#bda98f")
const POKORNA2_SLAB := Color("#e8e2d6")
const POKORNA2_RAIL := Color("#6f8f95")


func _find_pokorna2() -> void:
	var q := _outline_at(POKORNA2_AT)
	if q.size() < 3:
		return
	_add_site("pokorna2", [_largest(Geometry2D.offset_polygon(q, 3.0, Geometry2D.JOIN_MITER))])
	sites[-1]["outline"] = q


func _build_pokorna2(site: Dictionary) -> void:
	var poly := _simplify(site["outline"], 0.6)
	if poly.size() < 3:
		return
	_g = _ground_under(poly)
	var g := _g
	var floors := 20
	var top := g + POKORNA2_FLOOR * floors
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var long_face := a.distance_to(b) >= 8.0
		_mode = M_SKIN + float(S_SLAB) / 16.0 if long_face else M_STONE
		_wall(a, b, g - 0.4, top, _out(poly, a, b), POKORNA2_PLASTER if long_face else POKORNA2_END)
	_mode = M_STONE
	_cap(poly, top, Color("#8c8a84"))
	# A balcony slab with a railing on every floor above the first, along each long face, held
	# 0.8 m short of the corners so neighbouring faces' balconies never cross.
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		if len < 8.0:
			continue
		var d := (b - a) / len
		var o := _out(poly, a, b)
		var a2 := a + d * 0.8
		var b2 := b - d * 0.8
		var slab := PackedVector2Array([a2, b2, b2 + o * 1.0, a2 + o * 1.0])
		if Geometry2D.is_polygon_clockwise(slab) != Geometry2D.is_polygon_clockwise(poly):
			slab.reverse()
		for n in range(1, floors):
			var y := g + POKORNA2_FLOOR * n
			_prism(slab, y, y + 0.15, POKORNA2_SLAB, POKORNA2_SLAB, M_STONE, M_STONE)
			_wall(a2 + o * 1.0, b2 + o * 1.0, y + 0.15, y + 0.95, o, POKORNA2_RAIL)
	# The roof: a lift house on the longest face's middle and a water tank beside it.
	var best := 0
	var longest := 0.0
	for i in poly.size():
		var el := poly[i].distance_to(poly[(i + 1) % poly.size()])
		if el > longest:
			longest = el
			best = i
	var e0 := poly[best]
	var e1 := poly[(best + 1) % poly.size()]
	var dd := (e1 - e0).normalized()
	var oo := _out(poly, e0, e1)
	var mid := (e0 + e1) * 0.5 - oo * 3.0
	_prism(PackedVector2Array([mid - dd * 3.0 - oo * 2.0, mid + dd * 3.0 - oo * 2.0, mid + dd * 3.0 + oo * 2.0, mid - dd * 3.0 + oo * 2.0]),
			top, top + 3.2, POKORNA2_PLASTER.darkened(0.06), Color("#7d7b75"), M_STONE, M_STONE)
	var tank := mid + dd * 7.0
	_prism(_square(tank, 1.6), top, top + 2.4, Color("#9aa3a8"), Color("#7d8388"), M_STONE, M_STONE)
	_collide(poly)
	_mode = M_STONE


# --- Kino Muranów: the cinema under the arcaded block on Andersa ---------------------------

## F's four photos (2026-11-07, thread "Add arthouse cinema tour quest"; spec
## docs/landmarks/specs/kino_muranow.md, v2 whole-building rebuild 2026-11-27): the full Generała
## Andersa 3-7 socialist-realist complex as one site: both four-storey residential blocks (OSM 2014
## and 2904), the raised arch block between them with its passage through to the courtyard, the full
## arcaded podium along the square with the cinema front in the middle (red MURANÓW, white KINO,
## doors, poster boards under lamps), the paved terrace with its white balustrade and two pillars,
## the round putti fountain on the square, and the café garden with festoons and paper lanterns.
## In the frame: u along the front (towards Nowolipki, south-east), v out to the square.
const KM_AT := Vector2(-1661.5, -1209.8)          # the OSM cinema point (inside the podium, 2018)
const KM_NORTH_AT := Vector2(-1698.0, -1224.0)    # inside the north residential block (OSM 2014)
const KM_SOUTH_AT := Vector2(-1671.0, -1173.0)    # inside the south residential block (OSM 2904)
const KM_O := Vector2(-1653.5, -1212.1)           # the front's middle (the doors)
const KM_U := Vector2(0.481, 0.876)               # along the front
const KM_V := Vector2(0.876, -0.481)              # out to the square
const KM_FRONT := 15.0                            # the straight front's half length
const KM_DEEP := 14.0                             # how deep the straightened block reaches back
const KM_H := 4.8                                 # the pavilion's top over the square
const KM_PLINTH := 0.9
const KM_RAIL := 1.05                             # the balustrade over the terrace
const KM_ARCH_U := -0.62                          # the arch bridge centerline between OSM 2014 & 2904
const KM_ARCH_V := -27.3                          # the blocks' front line behind the terrace
const KM_ARCH_HALF := 5.2                         # arch block half width (10.4 m wide)
const KM_ARCH_BACK_V := -37.0                     # arch block back face (framed by back risalits)
const KM_SLOT_N := -6.95                          # north block inner edge (recessed balcony slot)
const KM_SLOT_S := 5.92                           # south block inner edge (recessed balcony slot)
const KM_BLOCK_STOREY := 3.2                      # four storeys over the terrace
const KM_BLOCK_CORNICE := 13.4                    # crowning cornice foot over the terrace
const KM_BLOCK_PARAPET := 14.8                    # parapet top over the terrace (cornice 0.5 + parapet 0.9)
const KM_ROOF_RISE := 1.8                         # low hipped roof rise
const KM_FOUNT := Vector2(-0.3, 19.2)             # the fountain's middle (u, v): OSM's basin ring
const KM_FOUNT_R := 5.0                           # the basin
const KM_STEP := 0.15                             # the round platform's steps (photo 4): rise,
const KM_TREAD := 0.4                             # tread,
const KM_STEPS := 3                               # count; the platform runs 1.6 m round the basin
const KM_PLAT_R := KM_FOUNT_R + 1.6
## The bench row by the metro parapet (map_builder BENCH_ROWS sets OSM's benches in it): its
## middle and direction in game x/z; the site paves a strip under it (the street photo).
const KM_BENCH_MID := Vector2(-1623.8, -1213.9)
const KM_BENCH_DIR := Vector2(-0.49, 0.872)
const KM_WALL := Color("#e7dcb6")
const KM_CORNICE := Color("#efe7cc")
const KM_GREY := Color("#8c8b86")
const KM_TERRACE := Color("#bdb7aa")
const KM_BALUSTER := Color("#ece8dc")
const KM_STEP_STONE := Color("#c9c3b6")
const KM_STONE := Color("#d2c5a3")                # the arch block's stone, a shade under the walls
const KM_BLOCK_WALL := Color("#b5a993")           # warm grey-beige render of the 1950s blocks (spec v2)
const KM_BLOCK_BASE := Color("#9a9284")           # plinth and back rusticated base band
const KM_BLOCK_TRIM := Color("#d6ccb8")           # pale surrounds, sill bands, and crowning cornice
const KM_BLOCK_ROOF := Color("#8a8e92")           # grey sheet low hipped roof (3D Tiles h135)
const KM_IRON := Color("#2c2e30")                 # iron balconies (spec v2)
const KM_ARCADE := Color("#2a2d30")               # podium wings' dark arcade openings (3D Tiles h270)
const KM_RED := Color(0.86, 0.13, 0.1)            # the letters (lit at night)
const KM_WHITE := Color(0.96, 0.95, 0.9)
const KM_GLASS := Color("#2e3539")
const KM_FRAME := Color("#2a2a2a")
const KM_PATINA := Color("#6f9a84")               # the fountain's green bronze
const KM_WATER := Color("#58798a")
## The poster boards (u from, u to) and each one's two parody posters' colours (no real films).
const KM_POSTERS := [[-8.6, -3.1, [Color("#c8582a"), Color("#2f3f6a")]], [3.1, 8.6, [Color("#e9e4d6"), Color("#3f7a4a")]]]
## The café garden's tables (u, v) by the left posters, and the festoon posts (u, v).
const KM_TABLES := [Vector2(-10.6, 2.6), Vector2(-7.8, 4.2), Vector2(-5.2, 2.8), Vector2(-9.2, 6.0), Vector2(-12.6, 5.0)]
const KM_POSTS := [Vector2(-12.0, 8.2), Vector2(-4.0, 8.6), Vector2(4.5, 8.4), Vector2(11.5, 7.8)]
const KM_TABLE_TOP := Color("#d9d2c4")
const KM_CHAIR := Color("#3a3d40")


func _find_kino_muranow() -> void:
	var q := _outline_at(KM_AT)
	if q.size() < 3:
		return
	var front := PackedVector2Array([_km(-KM_FRONT, 0.0), _km(KM_FRONT, 0.0), _km(KM_FRONT, -KM_DEEP), _km(-KM_FRONT, -KM_DEEP)])
	# Simplified again: the OSM corners left a hand's breadth off the straight front make slivers.
	var body := _simplify(_largest(Geometry2D.merge_polygons(_simplify(q, 0.6), front)), 0.4)
	if body.size() < 3:
		return
	var north := _outline_at(KM_NORTH_AT)
	var south := _outline_at(KM_SOUTH_AT)
	# A re-bake that moves the OSM outlines would leave the blocks out without a word: say so.
	if north.size() < 3 or south.size() < 3:
		push_error("kino_muranow: a residential block outline is missing at KM_NORTH_AT/KM_SOUTH_AT (north %d, south %d corners): re-measure them" % [north.size(), south.size()])
	var zone: Array = [_largest(Geometry2D.offset_polygon(body, 0.5, Geometry2D.JOIN_MITER))]
	if north.size() >= 3:
		zone.append(_largest(Geometry2D.offset_polygon(north, 1.0, Geometry2D.JOIN_MITER)))
	if south.size() >= 3:
		zone.append(_largest(Geometry2D.offset_polygon(south, 1.0, Geometry2D.JOIN_MITER)))
	var fc := _km(KM_FOUNT.x, KM_FOUNT.y)
	_add_site("kino_muranow", zone)
	if sites.is_empty() or sites[-1]["key"] != "kino_muranow":
		return
	sites[-1]["body"] = body
	sites[-1]["north"] = north
	sites[-1]["south"] = south
	tree_free.append([fc, KM_PLAT_R + KM_TREAD * (KM_STEPS - 1) + 1.0])


## A point in the cinema's frame.
static func _km(u: float, v: float) -> Vector2:
	return KM_O + KM_U * u + KM_V * v


## World point into the cinema's (u, v) frame.
static func _km_uv(p: Vector2) -> Vector2:
	var d := p - KM_O
	return Vector2(d.dot(KM_U), d.dot(KM_V))


## Restores the site's local frame (u along the front, v out to the square) for _lbox/_hip calls.
func _km_frame() -> void:
	_o = KM_O
	_a = KM_U
	_b = KM_V
	kit_face(0.0)


## Starts a kit_front along edge a->b oriented so _b matches the outward normal `out`.
func _km_front_edge(a: Vector2, b: Vector2, out: Vector2) -> float:
	var dir := (b - a).normalized()
	if Vector2(-dir.y, dir.x).dot(out) < 0.0:
		return kit_front(b, a)
	return kit_front(a, b)


func _build_kino_muranow(site: Dictionary) -> void:
	var body: PackedVector2Array = site["body"]
	var north: PackedVector2Array = site.get("north", PackedVector2Array())
	var south: PackedVector2Array = site.get("south", PackedVector2Array())
	var g := float(map.terrain_height(_km(0.0, 3.0).x, _km(0.0, 3.0).y))
	_g = g
	var top := g + KM_H
	# The podium: a grey plinth, the cream walls, a cornice slab whose top is the terrace.
	_prism(body, g - 0.6, g + KM_PLINTH, KM_GREY, Color(0, 0, 0, 0), M_STONE)
	_prism(body, g + KM_PLINTH, top - 0.35, KM_WALL, Color(0, 0, 0, 0), M_STONE)
	var lip := _largest(Geometry2D.offset_polygon(body, 0.22, Geometry2D.JOIN_MITER))
	_prism(lip, top - 0.35, top, KM_CORNICE, KM_TERRACE, M_STONE, M_STONE)
	# The balustrade along every edge that faces the square (white, a darker coping on top).
	for i in body.size():
		var a := body[i]
		var b := body[(i + 1) % body.size()]
		var o := _out(body, a, b)
		if o.dot(KM_V) < 0.3 or a.distance_to(b) < 1.0:
			continue
		var d := (b - a).normalized()
		var mid := (a + b) * 0.5 + o * 0.05
		_pow_box(mid, d, a.distance_to(b) * 0.5 + 0.1, 0.13, top, top + KM_RAIL - 0.12, KM_BALUSTER, KM_BALUSTER)
		_pow_box(mid, d, a.distance_to(b) * 0.5 + 0.15, 0.2, top + KM_RAIL - 0.12, top + KM_RAIL, KM_CORNICE.darkened(0.06), KM_CORNICE)
	_km_arcade(body, g, top)
	_km_front(g, top)
	_km_terrace(top)
	_km_blocks(north, south, top)
	_km_arch_block(top)
	_km_fountain()
	_km_garden(g, top)
	_collide(body)
	if north.size() >= 3:
		_collide(north)
	if south.size() >= 3:
		_collide(south)
	_collide(_circle(_km(KM_FOUNT.x, KM_FOUNT.y), KM_PLAT_R + KM_TREAD * (KM_STEPS - 1), 16))
	_mode = M_STONE


## The front: the doors' glass bay, the poster boards with their lamps, the red MURANÓW and the
## two white KINO words, all a hand's breadth proud of the wall.
func _km_front(g: float, top: float) -> void:
	var n3 := Vector3(KM_V.x, 0.0, KM_V.y)
	var f := 0.06
	# The doors: a warm-lit glass bay (M_PAVILION) with dark frames.
	var keep := _mode
	_mode = M_PAVILION
	var d0 := _km(-2.4, f)
	var d1 := _km(2.4, f)
	_quad(Vector3(d0.x, g, d0.y), Vector3(d1.x, g, d1.y), Vector3(d1.x, g + 3.0, d1.y), Vector3(d0.x, g + 3.0, d0.y), n3, KM_GLASS,
			Vector2(0, 0), Vector2(4.8, 0), Vector2(4.8, 3.0), Vector2(0, 3.0), 3.0)
	_mode = M_STONE
	for u: float in [-2.4, -1.2, 0.0, 1.2, 2.4]:
		var p := _km(u, f + 0.1)
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + 3.05, p.y), 0.09, KM_FRAME)
	var h0 := _km(-2.45, f + 0.1)
	var h1 := _km(2.45, f + 0.1)
	for y: float in [3.05, 2.2]:
		_beam(Vector3(h0.x, g + y, h0.y), Vector3(h1.x, g + y, h1.y), 0.09, KM_FRAME)
	# The poster boards: a dark frame, two posters each, a little lamp over each poster.
	for board: Array in KM_POSTERS:
		var u0: float = board[0]
		var u1: float = board[1]
		var a := _km(u0, f)
		var b := _km(u1, f)
		_quad(Vector3(a.x, g + 0.95, a.y), Vector3(b.x, g + 0.95, b.y), Vector3(b.x, g + 3.45, b.y), Vector3(a.x, g + 3.45, a.y), n3, KM_FRAME)
		var cols: Array = board[2]
		for k in 2:
			var pu0 := lerpf(u0, u1, k * 0.5) + 0.12
			var pu1 := lerpf(u0, u1, (k + 1) * 0.5) - 0.12
			var p0 := _km(pu0, f + 0.05)
			var p1 := _km(pu1, f + 0.05)
			var col: Color = cols[k]
			_quad(Vector3(p0.x, g + 1.07, p0.y), Vector3(p1.x, g + 1.07, p1.y), Vector3(p1.x, g + 3.33, p1.y), Vector3(p0.x, g + 3.33, p0.y), n3, col)
			# A title band and a face-sized block on each (shapes only, no real film).
			var t0 := _km(pu0 + 0.2, f + 0.1)
			var t1 := _km(pu1 - 0.2, f + 0.1)
			_quad(Vector3(t0.x, g + 1.35, t0.y), Vector3(t1.x, g + 1.35, t1.y), Vector3(t1.x, g + 1.65, t1.y), Vector3(t0.x, g + 1.65, t0.y), n3,
					KM_WHITE if col.get_luminance() < 0.5 else KM_FRAME)
			var c := (pu0 + pu1) * 0.5
			var m0 := _km(c - 0.55, f + 0.1)
			var m1 := _km(c + 0.55, f + 0.1)
			_quad(Vector3(m0.x, g + 2.0, m0.y), Vector3(m1.x, g + 2.0, m1.y), Vector3(m1.x, g + 3.05, m1.y), Vector3(m0.x, g + 3.05, m0.y), n3,
					col.lightened(0.35) if col.get_luminance() < 0.5 else col.darkened(0.45))
			var lamp := _km(c, f + 0.35)
			_mode = M_LAMP
			_pow_box(lamp, KM_U, 0.14, 0.1, g + 3.62, g + 3.75, BARGE_BULB, BARGE_BULB, M_LAMP)
			_mode = M_STONE
			var arm := _km(c, f)
			_beam(Vector3(arm.x, g + 3.7, arm.y), Vector3(lamp.x, g + 3.7, lamp.y), 0.04, KM_FRAME, false)
	# The words: red MURANÓW over the doors, white KINO at each end (photo 2: KINO, MURANÓW, KINO).
	_km_word("MURANÓW", -0.6, g + 3.75, 0.95, 0.28, KM_RED, f)
	_km_word("KINO", -11.6, g + 3.95, 0.6, 0.15, KM_WHITE, f)
	_km_word("KINO", 11.3, g + 3.95, 0.6, 0.15, KM_WHITE, f)
	_mode = keep


## A word in solid pixel blocks on the front, centred on u, its bottom at y, `h` tall; `sx` is a
## pixel column's width (the real letters are wide). M_LAMP: its colour by day, lit at night.
func _km_word(text: String, u: float, y: float, h: float, sx: float, col: Color, f: float) -> void:
	var sy := h / 7.0
	var width := 0.0
	for ch in text:
		width += (_pow_glyph_w(ch) + 1) * sx
	width -= sx
	var at := u - width * 0.5
	var keep := _mode
	_mode = M_LAMP
	for ch in text:
		var lit := {}
		for q: Vector2i in _pow_glyph(ch):
			lit[q] = true
		# Horizontal runs, one block each.
		for q: Vector2i in lit:
			if lit.has(q - Vector2i(1, 0)):
				continue
			var e := q
			while lit.has(e + Vector2i(1, 0)):
				e += Vector2i(1, 0)
			var row := PixelFont.BODY + 6 - q.y   # 0 at the body's bottom row, accents above
			var u0 := at + q.x * sx
			var u1 := at + (e.x + 1) * sx
			# The reader faces -v: their left-to-right runs along -u, so the word is mirrored about u.
			var p := _km(2.0 * u - (u0 + u1) * 0.5, f + 0.12)
			_pow_box(p, KM_U, (u1 - u0) * 0.5, 0.1, y + row * sy, y + (row + 1) * sy, col, col.lightened(0.15), M_LAMP)
		at += (_pow_glyph_w(ch) + 1) * sx
	_mode = keep


## The terrace on the roof: the two pillars with dark ball finials before the arch.
func _km_terrace(top: float) -> void:
	for side: float in [-1.0, 1.0]:
		var p := _km(KM_ARCH_U + side * 5.6, -19.5)
		_pow_box(p, KM_U, 0.48, 0.48, top, top + 0.6, KM_BALUSTER.darkened(0.04), KM_BALUSTER)
		_pow_box(p, KM_U, 0.3, 0.3, top + 0.6, top + 4.6, KM_BALUSTER, KM_BALUSTER)
		_pow_box(p, KM_U, 0.42, 0.42, top + 4.6, top + 4.9, KM_CORNICE, KM_CORNICE)
		_pow_box(p, KM_U, 0.12, 0.12, top + 4.9, top + 5.05, KM_GREY.darkened(0.3), KM_GREY.darkened(0.3))
		# The ball: an octagonal drum with pointed caps.
		var ball := _circle(p, 0.3, 8)
		_prism(ball, top + 5.17, top + 5.45, KM_GREY.darkened(0.35), Color(0, 0, 0, 0), M_STONE)
		_pyramid(ball, top + 5.45, top + 5.62, KM_GREY.darkened(0.3))
		var under := _circle(p, 0.3, 8)
		under.reverse()
		_pyramid(under, top + 5.17, top + 5.05, KM_GREY.darkened(0.4))


## The podium's north and south wings carry a row of round-headed dark arcade openings along their
## square faces (3D Tiles h270, h315): 2.4 m wide, 3.6 m high, every 3.4 m, in a pale stone trim.
func _km_arcade(body: PackedVector2Array, g: float, top: float) -> void:
	var step := 3.4
	var hw := 1.2
	var y0 := g - 0.1
	var spring := minf(g + 2.6, top - 1.85)
	for i in body.size():
		var a := body[i]
		var b := body[(i + 1) % body.size()]
		var length := a.distance_to(b)
		var out := _out(body, a, b)
		if out.dot(KM_V) < 0.7 or length < 20.0:
			continue
		var mid_u := _km_uv((a + b) * 0.5).x
		if absf(mid_u) < 25.0:
			continue  # the central cinema pavilion front stays as v1
		var along := (b - a) / length
		var n := floori((length - 1.6) / step)
		if n < 1:
			continue
		var start := (length - float(n - 1) * step) * 0.5
		for k in n:
			var at := a + along * (start + float(k) * step)
			_arch_panel(at, along, out, hw + 0.16, y0, spring, KM_CORNICE, 0.03, M_STONE)
			_arch_panel(at, along, out, hw, y0, spring, KM_ARCADE, 0.08, M_STONE)


## Both four-storey socialist-realist residential blocks (OSM 2014 north, 2904 south) over the
## terrace: shells, crowning cornice and parapet, front/back/gable kit windows, iron balconies,
## low hipped grey sheet roofs with skylights and chimneys.
func _km_blocks(north: PackedVector2Array, south: PackedVector2Array, top: float) -> void:
	for entry: Array in [[north, true], [south, false]]:
		var raw: PackedVector2Array = entry[0]
		var is_north: bool = entry[1]
		if raw.size() < 3:
			continue
		var ring := _km_block_ring(raw)
		if ring.size() < 3:
			continue
		_km_block_mass(ring, top)
		_km_block_front(ring, top, is_north)
		_km_block_back_ends(ring, top)
		_km_block_roof(ring, top)


## Trims the central arch bridge and narrow recessed slots out of an OSM block outline, and
## smooths minor gable-end kinks (under 1.8 m) so each wing has a clean ring for `kit_cornice_ring`.
func _km_block_ring(raw: PackedVector2Array) -> PackedVector2Array:
	var cut := PackedVector2Array([
		_km(KM_SLOT_N, -46.0),
		_km(KM_SLOT_S, -46.0),
		_km(KM_SLOT_S, -20.0),
		_km(KM_SLOT_N, -20.0),
	])
	var piece := _largest(Geometry2D.clip_polygons(raw, cut))
	if piece.size() < 3:
		return PackedVector2Array()
	var cleaned := _simplify(piece, 0.7)
	# Collapse the shallow 1.6 m OSM kink on the far north gable end so it stays a flat gable wall.
	# Re-bake risk: the u/v window below is measured from today's OSM 2014 outline; re-check it
	# (turntable, the north gable) whenever centrum.json is re-baked.
	var out := PackedVector2Array()
	var n := cleaned.size()
	for i in n:
		var uv := _km_uv(cleaned[i])
		if uv.x < -77.3 and uv.y > -35.0 and uv.y < -28.0:
			continue
		out.append(cleaned[i])
	return _simplify(out, 0.7) if out.size() >= 3 else cleaned


## The block's masonry shell: plinth on the terrace front, full-depth rusticated base to terrain on
## the back and ends, warm grey-beige render, crowning cornice ring, 0.9 m parapet and roof deck.
func _km_block_mass(ring: PackedVector2Array, top: float) -> void:
	var eave := top + KM_BLOCK_CORNICE
	var parapet := top + KM_BLOCK_PARAPET
	_mode = M_STONE
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		if out.dot(KM_V) > 0.5:
			_wall(a, b, top - 0.3, top + 0.5, out, KM_BLOCK_BASE)
			_wall(a, b, top + 0.5, eave, out, KM_BLOCK_WALL)
		else:
			var mid := (a + b) * 0.5
			var foot := minf(top - 0.3, minf(float(map.terrain_height(a.x, a.y)),
					minf(float(map.terrain_height(b.x, b.y)), float(map.terrain_height(mid.x, mid.y)))) - 0.8)
			_wall(a, b, foot, top + 0.9, out, KM_BLOCK_BASE)
			_wall(a, b, top + 0.9, eave, out, KM_BLOCK_WALL)
	kit_cornice_ring(ring, eave, KM_BLOCK_TRIM, 0.5, 0.6)
	_prism(ring, eave + 0.5, parapet, KM_BLOCK_WALL, Color(0, 0, 0, 0), M_STONE)
	_cap(ring, top + 14.4, KM_BLOCK_ROOF.darkened(0.08))


## Square-facing long facade of one block: 14 paired window bays across 4 storeys, pale sill bands,
## `kit_window` surrounds with white sash crosses on floors 2-3, lit `kit_panes` on floors 1 and 4,
## and 2.4 m iron balconies on floors 2-4 mirrored symmetrically about the central arch block.
func _km_block_front(ring: PackedVector2Array, top: float, is_north: bool) -> void:
	var best_i := -1
	var best_len := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var out := _out(ring, a, b)
		var length := a.distance_to(b)
		if out.dot(KM_V) > 0.7 and length > best_len:
			best_len = length
			best_i = i
	if best_i < 0 or best_len < 30.0:
		return
	var a := ring[best_i]
	var b := ring[(best_i + 1) % ring.size()]
	var w := _km_front_edge(a, b, _out(ring, a, b))
	# Seven pairs of windows (14 bays) match the paired socialist-realist rhythm in h225/h270.
	var margin := 2.4
	var pairs := 7
	var pair_step := (w - 2.0 * margin) / float(pairs)
	var bays: Array[float] = []
	for p in pairs:
		var c := margin + (float(p) + 0.5) * pair_step
		bays.append(c - 1.55)
		bays.append(c + 1.55)
	var sills: Array[float] = []
	for fl in 4:
		var sy := top + 1.2 + float(fl) * KM_BLOCK_STOREY
		sills.append(sy)
		kit_ledge(0.2, w - 0.2, sy - 0.34, 0.12, KM_BLOCK_TRIM, 0.08)
	kit_panes(bays, [sills[0], sills[3]], 1.4, 1.7, PAL_GLASS_DARK)
	for fl in [1, 2]:
		for bu in bays:
			kit_window(bu, sills[fl], 1.7, Win.SILL, KM_BLOCK_TRIM, PAL_GLASS_DARK, 0.7, PAL_WHITE_STONE)
	# Small iron balconies (2.4 m wide) on floors 2-4, mirrored symmetrically across the arch.
	var balc_bays: Array = [3, 7, 11] if is_north else [2, 6, 10]
	for idx: int in balc_bays:
		var bu := bays[idx]
		for fl in [1, 2, 3]:
			kit_balcony(bu, sills[fl] - 0.04, 1.2, Balcony.IRON, KM_IRON, KM_BLOCK_TRIM, 0.9)


## Courtyard-facing back edges (rusticated base groove, sill bands, lit `kit_panes`) and the far
## gable end wall (one vertical column of `kit_window` SILL on all four floors).
func _km_block_back_ends(ring: PackedVector2Array, top: float) -> void:
	var sills: Array[float] = []
	for fl in 4:
		sills.append(top + 1.2 + float(fl) * KM_BLOCK_STOREY)
	var best_end := -1
	var best_end_len := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 4.0:
			continue
		var out := _out(ring, a, b)
		if out.dot(-KM_V) > 0.7:
			var w := _km_front_edge(a, b, out)
			if length > 15.0:
				kit_bands(0.2, w - 0.2, top, top + 0.9, 0.46, KM_BLOCK_BASE)
			for sy in sills:
				kit_ledge(0.2, w - 0.2, sy - 0.22, 0.12, KM_BLOCK_TRIM, 0.08)
			var n := maxi(1, roundi((w - 1.4) / 4.2))
			kit_panes(_spread(0.7, w - 0.7, n), sills, 1.4, 1.7, PAL_GLASS_DARK)
		elif absf(out.dot(KM_U)) > 0.7 and absf(_km_uv((a + b) * 0.5).x) > 40.0 and length > best_end_len:
			best_end_len = length
			best_end = i
	if best_end >= 0:
		var ea := ring[best_end]
		var eb := ring[(best_end + 1) % ring.size()]
		var w := _km_front_edge(ea, eb, _out(ring, ea, eb))
		for sy in sills:
			kit_window(w * 0.5, sy, 1.7, Win.SILL, KM_BLOCK_TRIM, PAL_GLASS_DARK, 0.7)


## Low hipped grey sheet roof tucked inside the parapet, with skylight boxes and chimney stacks
## spaced every ~9 m along the ridge (3D Tiles h135).
func _km_block_roof(ring: PackedVector2Array, top: float) -> void:
	var u0 := INF
	var u1 := -INF
	var v0 := INF
	var v1 := -INF
	for p in ring:
		var uv := _km_uv(p)
		u0 = minf(u0, uv.x)
		u1 = maxf(u1, uv.x)
		v0 = minf(v0, uv.y)
		v1 = maxf(v1, uv.y)
	var v_back := maxf(v0 + 0.45, -37.8)
	var v_front := v1 - 0.45
	var cu := (u0 + u1) * 0.5
	var cv := (v_back + v_front) * 0.5
	var hu := (u1 - u0) * 0.5 - 0.45
	var hv := (v_front - v_back) * 0.5
	if hu < 2.0 or hv < 2.0:
		return
	var eave := top + 14.4
	var ridge := eave + KM_ROOF_RISE
	_km_frame()
	_hip(cu, cv, hu, hv, eave, KM_ROOF_RISE, KM_BLOCK_ROOF)
	var span := (u1 - u0) - 10.0
	var count := maxi(2, roundi(span / 9.0) + 1)
	for k in count:
		var u := (u0 + 5.0) + span * float(k) / float(maxi(count - 1, 1))
		if k % 2 == 0:
			_lbox(u, cv, 1.4, 1.0, ridge - 0.25, ridge + 0.55, KM_BLOCK_ROOF.lightened(0.08), M_STONE, PAL_GLASS_STEEL)
		else:
			_lbox(u, cv, 0.85, 0.55, ridge - 0.25, ridge + 1.1, KM_BLOCK_WALL.darkened(0.08), M_STONE, KM_IRON)


## The central arch block connecting the two residential wings (10.4 m wide at KM_ARCH_U, 1.1 m
## proud of the block front, full depth through to the back with the same round arch on both faces),
## rising 1.6 m over the blocks' parapet with its own cornice, plain attic, narrow upper windows,
## dark through-passage, and the two recessed flanking balcony slots on all four floors.
func _km_arch_block(top: float) -> void:
	_km_frame()
	var v_front := KM_ARCH_V + 1.1
	var v_back := KM_ARCH_BACK_V
	var v_mid := (v_front + v_back) * 0.5
	var hv := (v_front - v_back) * 0.5
	var half := KM_ARCH_HALF
	var r := 2.6
	var spring := top + 6.2
	var eave := top + 14.7
	var crown := top + KM_BLOCK_PARAPET + 1.6
	var back_pt := _km(KM_ARCH_U, v_back)
	var foot := minf(top - 0.3, float(map.terrain_height(back_pt.x, back_pt.y)) - 0.8)
	# Two full-depth piers and the solid upper span over the arch, plus the raised attic mass.
	for side: float in [-1.0, 1.0]:
		var pu := KM_ARCH_U + side * (r + (half - r) * 0.5)
		_lbox(pu, v_mid, (half - r) * 0.5, hv, foot, eave, KM_STONE, M_STONE, KM_STONE.darkened(0.1))
	_lbox(KM_ARCH_U, v_mid, r, hv, spring + r, eave, KM_STONE, M_STONE, KM_STONE.darkened(0.1))
	_lbox(KM_ARCH_U, v_mid, half, hv, eave, crown, KM_STONE, M_STONE, KM_BLOCK_ROOF)
	# Round arch curve in six steps a side spanning the full depth (front arch, back arch and vault).
	var steps := 6
	for k in steps:
		var a0 := PI * 0.5 * float(k) / float(steps)
		var a1 := PI * 0.5 * float(k + 1) / float(steps)
		var w := r * cos(a1)
		var y0 := spring + r * sin(a0)
		var y1 := spring + r * sin(a1)
		for side: float in [-1.0, 1.0]:
			var cu := KM_ARCH_U + side * (w + (r - w) * 0.5)
			_lbox(cu, v_mid, (r - w) * 0.5, hv, y0, y1, KM_STONE, M_STONE, KM_STONE)
	# Deep shadow walls and paved floor through the passage so both arch faces read cleanly.
	_mode = M_STONE
	_lbox(KM_ARCH_U, v_mid, r - 0.04, hv - 0.04, foot, top - 0.04, KM_TERRACE.darkened(0.18), M_STONE, KM_TERRACE.darkened(0.14))
	_wall(_km(KM_ARCH_U - r + 0.05, v_mid + 0.2), _km(KM_ARCH_U + r - 0.05, v_mid + 0.2), top - 0.04, spring + r - 0.05, KM_V, Color("#2a2926"))
	_wall(_km(KM_ARCH_U + r - 0.05, v_mid - 0.2), _km(KM_ARCH_U - r + 0.05, v_mid - 0.2), top - 0.04, spring + r - 0.05, -KM_V, Color("#2a2926"))
	# Cornice, arch band, attic coping, and two narrow windows on floors 3-4 on both faces.
	var faces: Array = [
		[_km(KM_ARCH_U + half, v_front), _km(KM_ARCH_U - half, v_front), KM_V, true],
		[_km(KM_ARCH_U - half, v_back), _km(KM_ARCH_U + half, v_back), -KM_V, false],
	]
	for fc: Array in faces:
		var fw := _km_front_edge(fc[0], fc[1], fc[2])
		var is_front: bool = fc[3]
		kit_ledge(0.0, fw, spring + r + 0.6, 0.22, KM_CORNICE, 0.14)
		kit_cornice(0.0, fw, eave, KM_CORNICE, 0.42, 0.45)
		kit_ledge(0.0, fw, crown - 0.16, 0.16, KM_CORNICE, 0.12)
		# Floor 3 narrow windows on the piers beside the arch; floor 4 narrow windows over the arch.
		if is_front:
			for off: float in [-3.9, 3.9]:
				kit_window(fw * 0.5 + off, top + 7.6, 1.6, Win.SILL, KM_CORNICE, PAL_GLASS_DARK, 0.42)
			for off: float in [-1.8, 1.8]:
				kit_window(fw * 0.5 + off, top + 10.6, 1.6, Win.SILL, KM_CORNICE, PAL_GLASS_DARK, 0.45)
		else:
			kit_panes([fw * 0.5 - 3.9, fw * 0.5 + 3.9], [top + 7.6], 0.84, 1.6, PAL_GLASS_DARK)
			kit_panes([fw * 0.5 - 1.8, fw * 0.5 + 1.8], [top + 10.6], 0.9, 1.6, PAL_GLASS_DARK)
	# Two narrow recessed balcony slots flanking the arch (all four floors, photos 2 and 4).
	# Held 0.35 m under the blocks' parapet so their flat roof never shares a plane with the coping.
	var slot_v_front := -31.6
	var slot_v_back := -36.5
	var slot_spans: Array = [[KM_SLOT_N, KM_ARCH_U - half], [KM_ARCH_U + half, KM_SLOT_S]]
	for sp: Array in slot_spans:
		var su0: float = sp[0]
		var su1: float = sp[1]
		var sw := su1 - su0
		if sw < 0.6:
			continue
		_km_frame()
		_lbox((su0 + su1) * 0.5, (slot_v_front + slot_v_back) * 0.5, sw * 0.5 - 0.02,
				(slot_v_front - slot_v_back) * 0.5, foot, top + KM_BLOCK_PARAPET - 0.35, KM_BLOCK_WALL, M_STONE, KM_BLOCK_ROOF)
		var fw := _km_front_edge(_km(su1, slot_v_front), _km(su0, slot_v_front), KM_V)
		for fl in 4:
			var sy := top + 1.2 + float(fl) * KM_BLOCK_STOREY
			kit_panes([fw * 0.5], [sy], minf(0.95, fw - 0.2), 1.7, PAL_GLASS_DARK)
			kit_balcony(fw * 0.5, sy - 0.04, fw * 0.46, Balcony.IRON, KM_IRON, KM_BLOCK_TRIM, 1.0)


## The fountain on the square: a round platform up three steps (photo 4; OSM's ring `wall` is
## the basin, map_builder SITE_WALLS leaves it to this site), a round stone basin with water, a
## square green-bronze pedestal, four putti round a column, and the wide upper bowl (photo 1).
func _km_fountain() -> void:
	var c := _km(KM_FOUNT.x, KM_FOUNT.y)
	var g0 := float(map.terrain_height(c.x, c.y))
	# The steps, on the half towards the cinema only (photo 4; the street photo from Andersa has the
	# basin's paving ring level with the benches): outermost first, a riser from below the ground
	# and a tread ring inside it. Round the other half the platform ends in one low stone kerb.
	var unit := _circle(Vector2.ZERO, 1.0, 24)
	var stepped: Array[bool] = []
	for k in 24:
		stepped.append(((unit[k] + unit[(k + 1) % 24]) * 0.5).dot(-KM_V) > 0.0)
	for s in KM_STEPS:
		var ro := KM_PLAT_R + KM_TREAD * (KM_STEPS - 1 - s)
		var ri := ro - KM_TREAD if s < KM_STEPS - 1 else KM_FOUNT_R - 0.05
		var y1 := g0 + KM_STEP * (s + 1)
		var shade := KM_STEP_STONE.darkened(0.04 * (KM_STEPS - 1 - s))
		for k in 24:
			var top := s == KM_STEPS - 1
			if not stepped[k] and not top:
				continue
			var y0 := g0 - 0.25 if s == 0 or not stepped[k] else g0 + KM_STEP * s
			var a := c + unit[k] * ro
			var b := c + unit[(k + 1) % 24] * ro
			var o := ((a + b) * 0.5 - c).normalized()
			_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), Vector3(o.x, 0.0, o.y), shade.darkened(0.12))
			var ia := c + unit[k] * ri
			var ib := c + unit[(k + 1) % 24] * ri
			_quad(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(ib.x, y1, ib.y), Vector3(ia.x, y1, ia.y), Vector3.UP, shade)
			# Where the flight ends, the side of this step's band.
			if not top:
				for side in 2:
					var j := k + side
					if stepped[(k + 2 * side - 1 + 24) % 24]:
						continue
					var e := unit[j % 24]
					var t := Vector2(-e.y, e.x) * (1.0 if side == 1 else -1.0)
					var p0 := c + e * (ro - KM_TREAD)
					var p1 := c + e * ro
					_quad(Vector3(p0.x, g0 - 0.25, p0.y), Vector3(p1.x, g0 - 0.25, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y), Vector3(t.x, 0.0, t.y), shade.darkened(0.08))
	# The paved strip under the bench row, its front towards the fountain.
	var bd := KM_BENCH_DIR.normalized()
	var bf := Vector2(-bd.y, bd.x)
	if bf.dot(c - KM_BENCH_MID) < 0.0:
		bf = -bf
	var gb := float(map.terrain_height(KM_BENCH_MID.x, KM_BENCH_MID.y))
	var m := KM_BENCH_MID
	var strip := PackedVector2Array([m - bd * 5.4 - bf * 1.0, m + bd * 5.4 - bf * 1.0, m + bd * 5.4 + bf * 1.7, m - bd * 5.4 + bf * 1.7])
	_prism(strip, gb - 0.2, gb + 0.03, KM_STEP_STONE.darkened(0.15), KM_STEP_STONE.darkened(0.05), M_STONE, M_STONE)
	var g := g0 + KM_STEP * KM_STEPS
	var outer := _circle(c, KM_FOUNT_R, 20)
	var inner := _circle(c, KM_FOUNT_R - 0.4, 20)
	# The rim as 20 short wall pieces, inside and out, and its top.
	for k in 20:
		var a := outer[k]
		var b := outer[(k + 1) % 20]
		var ia := inner[k]
		var ib := inner[(k + 1) % 20]
		var o := ((a + b) * 0.5 - c).normalized()
		var n := Vector3(o.x, 0.0, o.y)
		_quad(Vector3(a.x, g - 0.02, a.y), Vector3(b.x, g - 0.02, b.y), Vector3(b.x, g + 0.55, b.y), Vector3(a.x, g + 0.55, a.y), n, KM_BALUSTER.darkened(0.08))
		_quad(Vector3(ia.x, g + 0.2, ia.y), Vector3(ib.x, g + 0.2, ib.y), Vector3(ib.x, g + 0.55, ib.y), Vector3(ia.x, g + 0.55, ia.y), -n, KM_BALUSTER.darkened(0.2))
		_quad(Vector3(a.x, g + 0.55, a.y), Vector3(b.x, g + 0.55, b.y), Vector3(ib.x, g + 0.55, ib.y), Vector3(ia.x, g + 0.55, ia.y), Vector3.UP, KM_BALUSTER)
	_cap(inner, g + 0.2, KM_WATER)
	# The pedestal (scrolled corners as a wider foot and a cornice), the putti, the column, the bowl.
	_pow_box(c, KM_U, 0.95, 0.95, g + 0.15, g + 0.5, KM_PATINA.darkened(0.1), KM_PATINA)
	_pow_box(c, KM_U, 0.75, 0.75, g + 0.5, g + 1.55, KM_PATINA, KM_PATINA)
	_pow_box(c, KM_U, 0.9, 0.9, g + 1.55, g + 1.75, KM_PATINA.lightened(0.08), KM_PATINA.lightened(0.08))
	for k in 4:
		var d := Vector2.from_angle(KM_U.angle() + PI * 0.25 + PI * 0.5 * k)
		var p := c + d * 0.48
		_pow_box(p, d, 0.17, 0.2, g + 1.75, g + 2.55, KM_PATINA.lightened(0.04), KM_PATINA)
		_pow_box(p + d * 0.02, d, 0.13, 0.13, g + 2.55, g + 2.85, KM_PATINA.lightened(0.1), KM_PATINA.lightened(0.1))
	var col := _circle(c, 0.26, 8)
	_prism(col, g + 1.75, g + 3.75, KM_PATINA, Color(0, 0, 0, 0), M_STONE)
	# The bowl: a flared frustum from the column out to its rim, a flat top of water.
	var lo := _circle(c, 0.4, 16)
	var hi := _circle(c, 1.75, 16)
	for k in 16:
		var a := lo[k]
		var b := lo[(k + 1) % 16]
		var ha := hi[k]
		var hb := hi[(k + 1) % 16]
		var o := ((ha + hb) * 0.5 - c).normalized()
		var n := (Vector3(o.x, 0.0, o.y) * 0.4 + Vector3.DOWN * 0.9).normalized()
		_quad(Vector3(a.x, g + 3.6, a.y), Vector3(b.x, g + 3.6, b.y), Vector3(hb.x, g + 4.1, hb.y), Vector3(ha.x, g + 4.1, ha.y), n, KM_PATINA.darkened(0.08))
		_quad(Vector3(ha.x, g + 4.1, ha.y), Vector3(hb.x, g + 4.1, hb.y), Vector3(hb.x, g + 4.3, hb.y), Vector3(ha.x, g + 4.3, ha.y), Vector3(o.x, 0.0, o.y), KM_PATINA)
	_cap(hi, g + 4.3, KM_PATINA.lightened(0.12))


## The café garden by the doors and its lights: small tables with folding chairs, festoons of warm
## bulbs from the front's top out to four posts and along the front, paper lanterns under them.
func _km_garden(g: float, top: float) -> void:
	for t: Vector2 in KM_TABLES:
		var p := _km(t.x, t.y)
		var y := float(map.terrain_height(p.x, p.y))
		_pow_box(p, KM_U, 0.36, 0.36, y + 0.71, y + 0.75, KM_TABLE_TOP.darkened(0.1), KM_TABLE_TOP)
		_beam(Vector3(p.x, y, p.y), Vector3(p.x, y + 0.72, p.y), 0.07, KM_CHAIR, false)
		for side: float in [-1.0, 1.0]:
			var s := p + KM_U * (side * 0.62)
			var to := -KM_U * side
			_pow_box(s, to, 0.2, 0.2, y + 0.42, y + 0.46, KM_CHAIR, KM_CHAIR)
			_pow_box(s - to * 0.2, to, 0.025, 0.2, y + 0.46, y + 0.86, KM_CHAIR, KM_CHAIR)
			_beam(Vector3(s.x, y, s.y), Vector3(s.x, y + 0.43, s.y), 0.05, KM_CHAIR, false)
	var hook_y := top - 0.75
	var hooks: Array[Vector3] = []
	for u: float in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		var h := _km(u, 0.3)
		hooks.append(Vector3(h.x, hook_y, h.y))
	for i in hooks.size() - 1:
		_pow_festoon(hooks[i], hooks[i + 1], 0.35, 6)
	for k in KM_POSTS.size():
		var pp: Vector2 = KM_POSTS[k]
		var foot := _km(pp.x, pp.y)
		var y := float(map.terrain_height(foot.x, foot.y))
		_beam(Vector3(foot.x, y - 0.3, foot.y), Vector3(foot.x, y + 3.6, foot.y), 0.1, KM_FRAME)
		var from: Vector3 = hooks[mini(k + 1, hooks.size() - 1)]
		_pow_festoon(from, Vector3(foot.x, y + 3.55, foot.y), 0.6, 7)
		if k + 1 < KM_POSTS.size():
			var nxt: Vector2 = KM_POSTS[k + 1]
			var nf := _km(nxt.x, nxt.y)
			var ny := float(map.terrain_height(nf.x, nf.y))
			_pow_festoon(Vector3(foot.x, y + 3.55, foot.y), Vector3(nf.x, ny + 3.55, nf.y), 0.5, 7)
	# The paper lanterns: bigger warm-white globes hung under the front's festoon.
	var keep := _mode
	_mode = M_LAMP
	for u: float in [-12.5, -9.0, -5.5, 5.5, 9.0, 12.5]:
		var p := _km(u, 1.4)
		var ring := _circle(p, 0.24, 6)
		_prism(ring, hook_y - 0.95, hook_y - 0.55, Color(1.0, 0.93, 0.78), Color(1.0, 0.93, 0.78), M_LAMP, M_LAMP)
		_beam(Vector3(p.x, hook_y - 0.55, p.y), Vector3(p.x, hook_y - 0.3, p.y), 0.02, KM_FRAME, false)
	_mode = keep


# --- POLIN and the Ghetto Heroes Monument (Muranów, 2026-11-02) ----------------------------------

## Muzeum Historii Żydów Polskich POLIN (Lahdelma & Mahlamäki, 2013; spec
## docs/landmarks/specs/polin.md), from the Mac's reference set refs/polin/ (25 Commons photos,
## the GUGiK ortho, REPORT.md) and the LoD2 roof: an 18 m box of grey-green glass fins with one
## curved cut through it: the canyon, a tall wedge 15 m wide at the foot and 3.5 m at the top on
## the east front, the glazed slot across the roof with its south lip lifted, and the big glazed
## "lens" on the west front. Frame: u along the east front from the north corner southwards,
## +v into the building; origin the canyon's centre on the front.
const POLIN_O := Vector2(-2067.3, -1704.1)
const POLIN_U := Vector2(0.508, 0.861)
const POLIN_H := 18.0                     # photos and the ortho's shadows; LoD2 26.0 over ground 8.0
const POLIN_DEPTH := 9.0                  # where the canyon's glass stands, from the front
## The canyon's sides at the foot and at the roof (u at v = 0, 3, 6, 9): the north wall curves
## and flares into the plaza, the south side is a straight plane leaning back.
const POLIN_N_FOOT := [-7.5, -4.8, -3.2, -2.5]
const POLIN_N_TOP := [-1.6, -1.5, -1.4, -1.2]
const POLIN_S_FOOT := [7.5, 5.8, 4.2, 2.5]
const POLIN_S_TOP := [1.9, 1.7, 1.4, 1.2]
## The glazed slot across the roof (the ortho), on to ~7.5 m inside the west front.
const POLIN_SLOT := [Vector2(-2075.0, -1699.5), Vector2(-2089.0, -1698.7), Vector2(-2100.0, -1692.0),
		Vector2(-2111.0, -1684.4), Vector2(-2122.0, -1674.5)]
const POLIN_SLOT_HW := 1.1
const POLIN_LIP_UP := 2.5                 # the slot's south lip over the roof (LoD2 2.3, shadow 3-3.5)
const POLIN_LIP_W := 11.0
const POLIN_LENS := Vector2(-2132.0, -1680.0)
const POLIN_LENS_HW := 18.5
const POLIN_LENS_TOP := 13.5
const POLIN_FINS := Color("#8a9ba0")      # grey-green glass fins (mid; lit #adb3ad, shade #566466)
const POLIN_CANYON := Color("#a39378")    # warm sand cast concrete
const POLIN_FLOOR := Color("#d6cfbf")     # pale travertine in the canyon's mouth
const POLIN_ROOF := Color("#bcbcb6")
const POLIN_TEAL := Color("#4f8584")      # the glass band crowning the roof edge
const POLIN_PLINTH := Color("#a9a7a0")    # board-marked concrete under the west and north fronts
const POLIN_DOOR := Color("#4a3f33")      # deep-set bronze-dark glazing, warm at night
const POLIN_LENS_GLASS := Color("#6f8590")
const POLIN_DARK := Color("#2b2f33")


func _find_polin() -> void:
	var q := _landmark("Muzeum Historii Żydów Polskich Polin")
	if q.size() >= 3:
		_add_site("polin", [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == "polin":
			sites[-1]["ring"] = _simplify(q, 0.6)
	_o = GETTO_O
	_a = GETTO_A
	_b = GETTO_B
	_add_site("getto", [_rect(0.0, 0.0, 15.0, 8.0)])


## The canyon's side point k (0..3) at the foot or the roof, in the plan.
func _polin_side(north: bool, top: bool, k: int) -> Vector2:
	var us: Array = (POLIN_N_TOP if top else POLIN_N_FOOT) if north else (POLIN_S_TOP if top else POLIN_S_FOOT)
	return _w(float(us[k]), POLIN_DEPTH * k / 3.0)


func _polin_frame() -> void:
	_o = POLIN_O
	_a = POLIN_U
	_b = Vector2(-0.861, 0.508)   # into the building (west-south-west)


func _build_polin(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var top := g + POLIN_H
	_polin_frame()
	# The cut in plan: the canyon's foot from 3 m outside the front to its glass, then the slot.
	var cut := PackedVector2Array([_w(-7.5, -3.0)])
	for k in 4:
		cut.append(_polin_side(true, false, k))
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(1, POLIN_SLOT.size()):
		var p: Vector2 = POLIN_SLOT[i]
		var prev: Vector2 = POLIN_SLOT[i - 1]
		var n := (p - prev).normalized()
		var side := Vector2(-n.y, n.x)
		if side.dot(Vector2(0.483, 0.876)) < 0.0:
			side = -side   # towards the lip (south-east)
		if i == 1:
			left.append(prev - side * POLIN_SLOT_HW)
			right.append(prev + side * POLIN_SLOT_HW)
		left.append(p - side * POLIN_SLOT_HW)
		right.append(p + side * POLIN_SLOT_HW)
	var slot := left.duplicate()
	for i in range(right.size() - 1, -1, -1):
		slot.append(right[i])
	var notch := cut.duplicate()
	for k in range(3, -1, -1):
		notch.append(_polin_side(false, false, k))
	notch.append(_w(7.5, -3.0))
	var hole := Geometry2D.merge_polygons(notch, slot)
	var both: PackedVector2Array = _largest(hole)
	var on_cut := func(p: Vector2) -> bool:
		for i in both.size():
			if Geometry2D.get_closest_point_to_segment(p, both[i], both[(i + 1) % both.size()]).distance_to(p) < 0.05:
				return true
		return false
	var west := Vector2(-0.861, 0.508)
	var north := Vector2(-0.478, -0.878)
	for piece in Geometry2D.clip_polygons(ring, both):
		if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
			continue
		var run := 0.0
		for i in piece.size():
			var a := piece[i]
			var b := piece[(i + 1) % piece.size()]
			var out := _out(piece, a, b)
			var mid := (a + b) * 0.5
			if on_cut.call(mid):
				# the slot's walls show only down to its glass; the canyon's are drawn sloping below
				if Geometry2D.is_point_in_polygon(mid, _grown(slot, 0.05)) and not Geometry2D.is_point_in_polygon(mid, _grown(notch, -0.05)):
					_mode = M_STONE
					_wall(a, b, top - 1.0, top, out, POLIN_ROOF.darkened(0.1))
			else:
				var foot := g - 0.4
				if out.dot(west) > 0.7 or out.dot(north) > 0.7:
					_mode = M_STONE
					_wall(a, b, g - 0.4, g + 1.5, out, POLIN_PLINTH, run)
					foot = g + 1.5
				_mode = M_SKIN + S_FINS / 16.0
				_wall(a, b, foot, top, out, POLIN_FINS, run)
			run += a.distance_to(b)
		_mode = M_STONE
		_cap(piece, top, POLIN_ROOF)
	_parapet(ring, top, 1.2, POLIN_TEAL)
	_polin_canyon(g, top)
	# the slot's glass, sunk a metre
	_mode = M_PAVILION
	var sunk := Geometry2D.clip_polygons(slot, notch)
	for q in sunk:
		if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
			_cap(q, top - 1.0, POLIN_LENS_GLASS)
	_polin_lip(g, top)
	_polin_lens(ring, g)
	_polin_roof_kit(top)
	_collide(ring)


## The canyon: its two leaning walls from the foot line to the roof line, the strips of roof over
## them, the end faces on the front, the deep-set glass and the pale floor in its mouth.
func _polin_canyon(g: float, top: float) -> void:
	_polin_frame()
	for north: bool in [true, false]:
		for k in 3:
			var f0 := _polin_side(north, false, k)
			var f1 := _polin_side(north, false, k + 1)
			var t0 := _polin_side(north, true, k)
			var t1 := _polin_side(north, true, k + 1)
			var a := Vector3(f0.x, g - 0.4, f0.y)
			var b := Vector3(f1.x, g - 0.4, f1.y)
			var c := Vector3(t1.x, top, t1.y)
			var d := Vector3(t0.x, top, t0.y)
			var nrm := (b - a).cross(d - a).normalized()
			var gap := _w(0.0, POLIN_DEPTH * (k + 0.5) / 3.0)
			if Vector2(nrm.x, nrm.z).dot(gap - (f0 + f1) * 0.5) < 0.0:
				nrm = -nrm
			_mode = M_STONE
			_quad(a, b, c, d, nrm, POLIN_CANYON if k % 2 == 0 else POLIN_CANYON.darkened(0.04))
			# the roof over the overhang
			_quad(Vector3(f0.x, top, f0.y), Vector3(f1.x, top, f1.y), c, d, Vector3.UP, POLIN_ROOF)
		# the wall's end on the front: the triangle the lean leaves, in fins
		var ff := _polin_side(north, false, 0)
		var tf := _polin_side(north, true, 0)
		var out := -_b
		_mode = M_SKIN + S_FINS / 16.0
		_tri(Vector3(ff.x, g - 0.4, ff.y), Vector3(tf.x, top, tf.y), Vector3(ff.x, top, ff.y), Vector3(out.x, 0.0, out.y),
				POLIN_FINS, Vector2(0, -0.4), Vector2(ff.distance_to(tf), POLIN_H), Vector2(0, POLIN_H), POLIN_H)
	# the deep-set glazing across the canyon at its depth, and the end faces either side of it
	var nf := _polin_side(true, false, 3)
	var sf := _polin_side(false, false, 3)
	var nt := _polin_side(true, true, 3)
	var stt := _polin_side(false, true, 3)
	var face := Vector3(-_b.x, 0.0, -_b.y)
	_mode = M_PAVILION
	_quad(Vector3(nf.x, g - 0.2, nf.y), Vector3(sf.x, g - 0.2, sf.y), Vector3(stt.x, top - 1.0, stt.y), Vector3(nt.x, top - 1.0, nt.y),
			face, POLIN_DOOR)
	# the floor of the mouth, from 3 m in front of the front to the glass
	_mode = M_STONE
	var floor_ring := PackedVector2Array([_w(-7.5, -3.0), _w(-7.5, 0.0)])
	for k in range(1, 4):
		floor_ring.append(_polin_side(true, false, k))
	for k in range(3, 0, -1):
		floor_ring.append(_polin_side(false, false, k))
	floor_ring.append(_w(7.5, 0.0))
	floor_ring.append(_w(7.5, -3.0))
	_cap(floor_ring, g + 0.04, POLIN_FLOOR)


## The slot's south lip: a ribbed grey wedge on the roof, POLIN_LIP_UP over it at the slot,
## falling back to the roof over POLIN_LIP_W, its face over the slot in the same grey.
func _polin_lip(g: float, top: float) -> void:
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for i in range(1, POLIN_SLOT.size()):
		var p: Vector2 = POLIN_SLOT[i]
		var prev: Vector2 = POLIN_SLOT[i - 1]
		var n := (p - prev).normalized()
		var side := Vector2(-n.y, n.x)
		if side.dot(Vector2(0.483, 0.876)) < 0.0:
			side = -side
		var w := POLIN_LIP_W * (0.55 if i == POLIN_SLOT.size() - 1 else 1.0)
		if i == 1:
			var q0 := prev + side * POLIN_SLOT_HW
			inner.append(Vector3(q0.x, top + POLIN_LIP_UP, q0.y))
			var o0 := q0 + side * w
			outer.append(Vector3(o0.x, top, o0.y))
		var q := p + side * POLIN_SLOT_HW
		inner.append(Vector3(q.x, top + POLIN_LIP_UP, q.y))
		var o := q + side * w
		outer.append(Vector3(o.x, top, o.y))
	var n := inner.size()
	for i in n - 1:
		var a := inner[i]
		var b := inner[i + 1]
		var c := outer[i + 1]
		var d := outer[i]
		var nrm := (b - a).cross(d - a).normalized()
		if nrm.y < 0.0:
			nrm = -nrm
		_mode = M_STONE
		_quad(a, b, c, d, nrm, POLIN_ROOF.darkened(0.05))
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var e := (b2 - a2).normalized()
		var face := Vector2(-e.y, e.x)
		if face.dot(Vector2(d.x, d.z) - a2) > 0.0:
			face = -face
		_wall(a2, b2, top, top + POLIN_LIP_UP, face, POLIN_ROOF.darkened(0.15))
	for k: int in [0, n - 1]:
		var t := inner[k]
		var foot := Vector3(t.x, top, t.z)
		var far := outer[k]
		var other := inner[1] if k == 0 else inner[n - 2]
		var nrm := (far - foot).cross(t - foot).normalized()
		if nrm.dot(t - other) < 0.0:
			nrm = -nrm
		_tri(foot, far, t, nrm, POLIN_ROOF.darkened(0.12), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## The west front's lens: where the cut comes out, a glazed eye about 37 m wide from near the
## ground to 13.5 m, 10 cm proud of the fins, with a thin dark curved lip; warm-lit at night.
func _polin_lens(ring: PackedVector2Array, g: float) -> void:
	var best := INF
	var at := Vector2.ZERO
	var dir := Vector2.ZERO
	var out := Vector2.ZERO
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var c := Geometry2D.get_closest_point_to_segment(POLIN_LENS, a, b)
		if c.distance_to(POLIN_LENS) < best and a.distance_to(b) > 10.0:
			best = c.distance_to(POLIN_LENS)
			at = c
			dir = (b - a).normalized()
			out = _out(ring, a, b)
	var nrm := Vector3(out.x, 0.0, out.y)
	var seg := 14
	var curve := func(t: float) -> float:
		return POLIN_LENS_TOP * sqrt(maxf(0.0, 1.0 - t * t))
	for k in seg:
		var t0 := (-1.0 + 2.0 * k / seg) * 0.985
		var t1 := (-1.0 + 2.0 * (k + 1) / seg) * 0.985
		var p0 := at + dir * t0 * POLIN_LENS_HW + out * 0.1
		var p1 := at + dir * t1 * POLIN_LENS_HW + out * 0.1
		var y0: float = g + 0.6
		var h0: float = curve.call(t0)
		var h1: float = curve.call(t1)
		_mode = M_PAVILION
		_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y0 + h1 - 0.35, p1.y),
				Vector3(p0.x, y0 + h0 - 0.35, p0.y), nrm, POLIN_LENS_GLASS)
		# the dark lip along the curve
		var q0 := p0 + out * 0.05
		var q1 := p1 + out * 0.05
		_mode = M_STONE
		_quad(Vector3(q0.x, y0 + h0 - 0.4, q0.y), Vector3(q1.x, y0 + h1 - 0.4, q1.y),
				Vector3(q1.x, y0 + h1, q1.y), Vector3(q0.x, y0 + h0, q0.y), nrm, POLIN_DARK)


## What stands on the roof (the ortho): the plant room with six round fans, the lift and plant
## box, two groups of blue skylights.
func _polin_roof_kit(top: float) -> void:
	_polin_frame()
	_o = Vector2(-2105.0, -1728.5)
	_lbox(0.0, 0.0, 6.5, 3.5, top, top + 2.6, Color("#9c9e9a"), M_STONE, Color("#8f918d"))
	for k in 6:
		_prism(_circle(_w(-5.0 + 2.0 * k, 0.0), 0.8, 8), top + 2.6, top + 2.9, Color("#6d706e"), Color("#3f4241"), M_STONE, M_STONE)
	_o = Vector2(-2096.0, -1702.0)
	_lbox(0.0, 0.0, 3.6, 3.6, top, top + 3.0, Color("#a3a5a1"), M_STONE, Color("#959793"))
	for c: Vector2 in [Vector2(-2111.5, -1715.0), Vector2(-2103.5, -1709.5)]:
		_o = c
		_lbox(0.0, 0.0, 2.2, 1.4, top, top + 0.5, Color("#3f4448"), M_STONE, Color("#4a6f96"))


## Pomnik Bohaterów Getta (Natan Rapaport, 1948), from refs/polin/ (photos d00-d12, the ortho):
## on a 30 x 16 m paved platform in the plaza before the canyon, a wall of dark grey-green
## labradorite 9.5 m wide, 3 m deep and 11 m tall, leaning in a little, on a black plinth; the
## fighters' bronze in a tall recess in a granite frame on its west face (towards the museum)
## over five low black steps and a flower bed; the deportation relief in stone on the back;
## menorahs on polished granite blocks at the ends of the steps and one with a flame at the
## wall's foot. Frame: u along the platform's long axis, +v west-south-west to the museum.
const GETTO_O := Vector2(-2031.0, -1741.0)
const GETTO_A := Vector2(0.457, 0.889)
const GETTO_B := Vector2(-0.889, 0.457)
const GETTO_WALL_V := -0.5
const GETTO_PAVE := Color("#a8a8a2")
const GETTO_BORDER := Color("#7c7d79")
const GETTO_BLACK := Color("#25272a")
const GETTO_STONE := Color("#5a5e5d")      # labradorite, between lit #85868b and shade #4d5154
const GETTO_FRAME := Color("#a8a8a2")
const GETTO_BRONZE := Color("#3a3a36")
const GETTO_RELIEF := Color("#8f8a80")


func _build_getto(_site: Dictionary) -> void:
	_o = GETTO_O
	_a = GETTO_A
	_b = GETTO_B
	_g = _ground_under(_rect(0.0, 0.0, 15.0, 8.0))
	var g := _g
	# the platform: a darker border round lighter slabs
	_lbox(0.0, 0.0, 15.0, 8.0, g - 0.4, g + 0.12, GETTO_BORDER, M_STONE, GETTO_BORDER)
	_mode = M_STONE
	_cap(_rect(0.0, 0.0, 13.8, 6.8), g + 0.14, GETTO_PAVE)
	var base := g + 0.14
	var front := GETTO_WALL_V + 1.5
	# five low black steps on the west, then the flower bed along the lowest
	for k in 5:
		var reach := 4.6 - 0.9 * k
		_lbox(0.0, front + reach * 0.5, 7.5, reach * 0.5, base, base + 0.16 * (k + 1), GETTO_BLACK, M_STONE, GETTO_BLACK.lightened(0.04))
	_lbox(0.0, front + 5.0, 7.5, 0.4, base, base + 0.25, Color("#3f6a33"), M_STONE, Color("#58803f"))
	var step_top := base + 0.8
	# the plinth and the wall, leaning in a little
	_lbox(0.0, GETTO_WALL_V, 5.0, 1.75, base, step_top + 0.5, GETTO_BLACK, M_STONE, GETTO_BLACK)
	var y0 := step_top + 0.5
	_mode = M_STONE
	_frustum(_rect(0.0, GETTO_WALL_V, 4.75, 1.5), y0, _rect(0.0, GETTO_WALL_V, 4.5, 1.3), step_top + 11.0, GETTO_STONE, GETTO_STONE.darkened(0.05))
	# the fighters: a granite frame round a tall bronze recess with the figures standing out
	_lbox(0.0, front + 0.06, 1.9, 0.12, y0 + 0.9, y0 + 8.4, GETTO_FRAME, M_STONE, GETTO_FRAME)
	_lbox(0.0, front + 0.2, 1.5, 0.06, y0 + 1.2, y0 + 8.1, GETTO_BRONZE, M_STONE, GETTO_BRONZE)
	var figures := [[-1.1, 5.2], [-0.55, 6.4], [0.0, 6.8], [0.55, 6.0], [1.1, 4.8]]
	for f: Array in figures:
		_lbox(float(f[0]), front + 0.38, 0.22, 0.12, y0 + 1.3, y0 + 1.3 + float(f[1]), GETTO_BRONZE.lightened(0.08), M_STONE, GETTO_BRONZE)
	# the deportation relief on the back: stone bas-relief in a rough frame
	var back := GETTO_WALL_V - 1.5
	_lbox(0.0, back - 0.08, 3.2, 0.12, y0 + 2.6, y0 + 6.6, GETTO_FRAME, M_STONE, GETTO_FRAME)
	_lbox(0.0, back - 0.24, 3.0, 0.06, y0 + 2.8, y0 + 6.4, GETTO_RELIEF, M_STONE, GETTO_RELIEF)
	# menorahs: two on polished blocks at the steps' ends, one with a flame at the wall's foot
	for u: float in [-6.25, 6.25]:
		_lbox(u, front + 4.6, 0.75, 0.75, base, base + 1.0, GETTO_BLACK, M_STONE, GETTO_BLACK.lightened(0.06))
		_menorah(_w(u, front + 4.6), base + 1.0, 1.0)
	_menorah(_w(0.0, front + 1.6), step_top, 0.7)
	var fl := _w(0.0, front + 1.6)
	_prism(_square(fl, 0.12), step_top + 1.35, step_top + 1.6, Color("#ffb347"), Color("#ffd27a"), M_LAMP, M_LAMP)
	_collide(_rect(0.0, front - 1.0, 8.0, 4.8))


## A seven-branched bronze candlestick standing at p on y, `s` its scale (1 = 2 m tall), the arms
## across the frame's u.
func _menorah(p: Vector2, y: float, s: float) -> void:
	var foot := Vector3(p.x, y, p.y)
	var up := Vector3.UP * s
	var side := Vector3(_a.x, 0.0, _a.y) * s
	_beam(foot, foot + up * 1.9, 0.12 * s, GETTO_BRONZE)
	_beam(foot - side * 0.3, foot + side * 0.3, 0.14 * s, GETTO_BRONZE)
	for k in 3:
		var r := 0.28 * (k + 1)
		var low := 0.95 - 0.22 * k
		for sd: float in [-1.0, 1.0]:
			var elbow := foot + up * low + side * sd * r
			_beam(foot + up * low, elbow, 0.08 * s, GETTO_BRONZE)
			_beam(elbow, foot + up * 1.9 + side * sd * r, 0.08 * s, GETTO_BRONZE)


# --- The monuments pass, part 2 (photo builds, 2026-11-02) ---------------------------------------

## Seven monuments built from the Mac's photo reports (docs/landmarks/photo-reports/: Commons
## photos and the GUGiK ortho read in game coordinates). Until now each stood as a generic OSM
## piece (tools/bake_monuments.py); they are in its SKIP list now. Each has its own frame
## (_o, _a forward / the way it faces, _b = its right) and a small zone that drops the mapped
## specks under it (Słowacki's OSM parts).
const NIKE := Vector2(-1010.0, -1317.0)
const NIKE_A := Vector2(0.7071, -0.7071)        # she lunges north-east, toward Trasa W-Z
const NIKE_GRANITE := Color("#c8c0b0")
const NIKE_BRONZE := Color("#2e302c")
const SLOWACKI := Vector2(-1480.0, -978.0)
const SLOWACKI_A := Vector2(1.0, 0.0)           # east, out to Plac Bankowy, his back to the palace
const SLOWACKI_STONE := Color("#4a4a4c")
const SLOWACKI_BRONZE := Color("#33342f")
const STARZYNSKI := Vector2(-1499.0, -1101.0)
const STARZYNSKI_A := Vector2(0.7071, 0.7071)   # south-east, the Blue Tower behind him
const STARZYNSKI_BRONZE := Color("#3d3a33")
const MALY := Vector2(-981.0, -1689.0)
const MALY_A := Vector2(0.924, 0.383)           # away from the city wall (NNE-SSW) to Podwale
const MALY_BRICK := Color("#b5573c")
const MALY_BRONZE := Color("#4a4c48")
const KILINSKI := Vector2(-896.0, -1573.0)
const KILINSKI_A := Vector2(-0.7071, 0.7071)    # south-west, along Podwale
const KILINSKI_GRANITE := Color("#2d2d2f")
const KILINSKI_BRONZE := Color("#35362f")
const UMSCHLAG := Vector2(-2382.0, -2020.0)
const UMSCHLAG_A := Vector2(0.870, -0.493)      # along Stawki; +v (its right) is the street side
const UMSCHLAG_MARBLE := Color("#dadad6")
const UMSCHLAG_BLACK := Color("#26282a")
const WSCHOD := Vector2(-1718.0, -2183.0)
const WSCHOD_A := Vector2(0.991, -0.131)        # along Muranowska's median, east: the way the wagon faces
const WSCHOD_STONE := Color("#8e8478")
const WSCHOD_BRONZE := Color("#3e3f33")
const MON_GREEN := Color("#4d6b3a")
const MON_LANTERN := Color("#ffd9a0")


func _mon_frame(c: Vector2, a: Vector2) -> void:
	_o = c
	_a = a.normalized()
	_b = Vector2(-_a.y, _a.x)


## A point of the frame at height y.
func _mon_p(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


func _find_monuments() -> void:
	_mon_frame(NIKE, NIKE_A)
	_add_site("nike", [_rect(0.0, 0.0, 3.2, 3.2)])
	_mon_frame(SLOWACKI, SLOWACKI_A)
	_add_site("slowacki", [_rect(0.0, 0.0, 6.2, 5.2)])
	_mon_frame(STARZYNSKI, STARZYNSKI_A)
	_add_site("starzynski", [_rect(-0.5, 0.0, 2.4, 2.8)])
	_mon_frame(MALY, MALY_A)
	_add_site("maly_powstaniec", [_rect(-1.0, 0.0, 2.2, 2.2)])
	_mon_frame(KILINSKI, KILINSKI_A)
	_add_site("kilinski", [_rect(0.0, 0.0, 2.3, 2.3)])
	_mon_frame(UMSCHLAG, UMSCHLAG_A)
	_add_site("umschlagplatz", [_rect(0.0, 0.0, 8.2, 5.2)])
	_mon_frame(WSCHOD, WSCHOD_A)
	_add_site("pomnik_wschod", [_rect(0.9, 0.0, 23.9, 4.6)])


## A standing bronze figure `h` tall from y in the current frame (u forward, +v his right), the
## same build as de Gaulle's: with `stride` > 0 the legs walk (that much step at 3.3 m), else a
## cloak falls to the feet (`flare` widens its hem). `lh`/`rh` are the hands (u, v, height) at
## the 3.3 m scale; `cap` a fur cap's height (0: bare head). Returns the right hand's point.
func _mon_figure(y: float, h: float, col: Color, stride: float, lh: Vector3, rh: Vector3, flare := 1.0, cap := 0.0) -> Vector3:
	var k := h / 3.3
	var none := Color(0, 0, 0, 0)
	var hem := y
	if stride > 0.0:
		hem = y + 1.0 * k
		for side: float in [1.0, -1.0]:
			var hip := _w(0.0, 0.14 * side * k)
			var foot := _w(stride * 0.5 * side * k, 0.15 * side * k)
			_beam(Vector3(hip.x, y + 1.62 * k, hip.y), Vector3(foot.x, y + 0.08 * k, foot.y), 0.24 * k, col)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.34 * k * flare, 0.33 * k * flare), hem, _rect(0.0, 0.0, 0.23 * k, 0.27 * k), y + 1.75 * k, col)
	_prism(_rect(0.0, 0.0, 0.2 * k, 0.27 * k), y + 1.75 * k, y + 2.5 * k, col, none, M_STONE)
	_frustum(_rect(0.0, 0.0, 0.2 * k, 0.29 * k), y + 2.5 * k, _rect(0.0, 0.0, 0.14 * k, 0.18 * k), y + 2.66 * k, col, col)
	for arm: Array in [[-1.0, lh], [1.0, rh]]:
		var hand: Vector3 = arm[1]
		_beam(_mon_p(0.0, 0.31 * float(arm[0]) * k, y + 2.55 * k), _mon_p(hand.x * k, hand.y * k, y + hand.z * k), 0.13 * k, col)
	_prism(_rect(0.0, 0.0, 0.06 * k, 0.06 * k), y + 2.62 * k, y + 2.72 * k, col, none, M_STONE)
	_prism(_rect(0.02 * k, 0.0, 0.11 * k, 0.1 * k), y + 2.72 * k, y + 2.98 * k, col, col if cap <= 0.0 else none, M_STONE, M_STONE)
	if cap > 0.0:
		_frustum(_circle(_w(0.0, 0.0), 0.13 * k, 8), y + 2.98 * k, _circle(_w(0.0, 0.0), 0.15 * k, 8), y + (2.98 + cap) * k, col.darkened(0.1), col.darkened(0.15))
	return _mon_p(rh.x * k, rh.y * k, y + rh.z * k)


## A flat quad from its four corners, the normal from its own geometry (bronze cloaks, plates).
func _mon_sheet(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var n := (b - a).cross(d - a).normalized()
	_quad(a, b, c, d, n, col)


## A vertical half disc standing on y across the frame's u (centre cu, cv), radius r, depth d.
func _mon_halfdisc(cu: float, cv: float, y: float, r: float, d: float, col: Color) -> void:
	var n := 10
	var nb := Vector3(_b.x, 0.0, _b.y)
	for i in n:
		var t0 := PI * i / n
		var t1 := PI * (i + 1) / n
		for side: float in [-1.0, 1.0]:
			var v := cv + side * d * 0.5
			_tri(_mon_p(cu, v, y), _mon_p(cu + r * cos(t0), v, y + r * sin(t0)), _mon_p(cu + r * cos(t1), v, y + r * sin(t1)),
					nb * side, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		var tm := (t0 + t1) * 0.5
		var out := Vector3(_a.x * cos(tm), sin(tm), _a.y * cos(tm)).normalized()
		_quad(_mon_p(cu + r * cos(t0), cv - d * 0.5, y + r * sin(t0)), _mon_p(cu + r * cos(t1), cv - d * 0.5, y + r * sin(t1)),
				_mon_p(cu + r * cos(t1), cv + d * 0.5, y + r * sin(t1)), _mon_p(cu + r * cos(t0), cv + d * 0.5, y + r * sin(t0)), out, col)


## Pomnik Bohaterów Warszawy, the Warsaw Nike (Marian Konieczny, 1964), from refs/nike/: a
## light granite pylon 3 m square at the foot, tapering, 9 m tall, "BOHATEROM WARSZAWY
## 1939-1945" low on its south-east face (the open side of the path loop); on it the dark
## bronze Nike, about 5 m, lunging north-east, the left arm up, the sword swung up and back in
## the right, her cloak flying. Shrub beds round the foot, open to the path on the south-east.
func _build_nike(_site: Dictionary) -> void:
	_mon_frame(NIKE, NIKE_A)
	_g = _ground_under(_rect(0.0, 0.0, 2.2, 2.2))
	var g := _g
	_lbox(0.0, 0.0, 3.2, 3.2, g - 0.3, g + 0.1, Color("#a9a49a"), M_STONE, Color("#b4afa5"))
	_lbox(0.0, 0.0, 2.1, 2.1, g + 0.1, g + 0.55, NIKE_GRANITE.darkened(0.06), M_STONE, NIKE_GRANITE)
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 1.5, 1.5), g + 0.55, _rect(0.0, 0.0, 1.2, 1.2), g + 9.0, NIKE_GRANITE, NIKE_GRANITE.lightened(0.04))
	_lbox(0.0, 1.47, 1.0, 0.05, g + 1.3, g + 2.1, Color("#3a3834"))
	for bed: Array in [[-4.3, 0.0, 0.6, 2.6], [0.0, -4.3, 2.6, 0.6], [4.3, 0.0, 0.6, 2.6]]:
		_lbox(float(bed[0]), float(bed[1]), float(bed[2]), float(bed[3]), g - 0.2, g + 0.7, MON_GREEN, M_STONE, MON_GREEN.lightened(0.1))
	var y := g + 9.0
	var bz := NIKE_BRONZE
	_lbox(0.0, 0.0, 0.9, 0.7, y, y + 0.3, bz)
	y += 0.3
	# legs: the back one stretched, the front one bent at the knee
	_beam(_mon_p(-0.15, 0.1, y + 2.2), _mon_p(-1.1, 0.2, y + 0.1), 0.38, bz)
	_beam(_mon_p(0.15, -0.1, y + 2.2), _mon_p(0.8, -0.15, y + 1.3), 0.38, bz)
	_beam(_mon_p(0.8, -0.15, y + 1.3), _mon_p(0.85, -0.2, y + 0.1), 0.36, bz)
	# the skirt and the body, leaning into the lunge
	_frustum(_rect(0.2, 0.0, 0.7, 0.5), y + 1.2, _rect(0.3, 0.0, 0.4, 0.4), y + 2.4, bz)
	_frustum(_rect(0.3, 0.0, 0.4, 0.4), y + 2.4, _rect(0.6, 0.0, 0.32, 0.45), y + 3.6, bz, bz)
	_beam(_mon_p(0.62, 0.0, y + 3.5), _mon_p(0.8, 0.0, y + 4.1), 0.38, bz)
	# the left arm up and forward, the right with the sword up and back
	_beam(_mon_p(0.6, -0.42, y + 3.45), _mon_p(1.6, -0.6, y + 4.7), 0.18, bz)
	_beam(_mon_p(0.6, 0.42, y + 3.45), _mon_p(-0.1, 0.7, y + 4.6), 0.18, bz)
	_beam(_mon_p(-0.1, 0.7, y + 4.6), _mon_p(-1.3, 0.8, y + 5.4), 0.1, bz.lightened(0.12))
	_beam(_mon_p(-0.05, 0.45, y + 4.55), _mon_p(-0.15, 0.95, y + 4.65), 0.08, bz)
	# the cloak flying back from her shoulders
	_mon_sheet(_mon_p(0.45, -0.45, y + 3.5), _mon_p(0.45, 0.45, y + 3.5), _mon_p(-1.4, 0.7, y + 2.6), _mon_p(-1.4, -0.9, y + 2.9), bz.darkened(0.05))
	_collide(_rect(0.0, 0.0, 2.1, 2.1))


## Pomnik Juliusza Słowackiego on Plac Bankowy, from refs/slowacki/: a broad two-step dark
## granite platform (12 x 10 m), a dark granite pillar 1.8 m square and 6 m tall with the name
## cut in its face, the poet on it in a long cloak, head down, 4.5 m of dark bronze, looking
## east over the square with Corazzi's arcaded palace behind; two-lantern lamps on the
## platform's corners. The OSM parts under it (the platform and the pillar as boxes) go.
func _build_slowacki(_site: Dictionary) -> void:
	_mon_frame(SLOWACKI, SLOWACKI_A)
	_g = _ground_under(_rect(0.0, 0.0, 6.0, 5.0))
	var g := _g
	var st := SLOWACKI_STONE
	_lbox(0.0, 0.0, 6.0, 5.0, g - 0.3, g + 0.2, st.darkened(0.06), M_STONE, st.lightened(0.08))
	_lbox(0.0, 0.0, 5.2, 4.2, g + 0.2, g + 0.45, st.darkened(0.04), M_STONE, st.lightened(0.05))
	_lbox(0.0, 0.0, 1.15, 1.15, g + 0.45, g + 1.0, Color("#2e2e30"))
	_lbox(0.0, 0.0, 0.9, 0.9, g + 1.0, g + 6.2, Color("#353537"))
	_lbox(0.0, 0.0, 1.05, 1.05, g + 6.2, g + 6.45, Color("#2e2e30"), M_STONE, Color("#3a3a3c"))
	_lbox(0.93, 0.0, 0.03, 0.55, g + 4.9, g + 5.25, Color("#9a968c"))
	_mon_figure(g + 6.45, 4.4, SLOWACKI_BRONZE, 0.0, Vector3(0.25, -0.15, 1.95), Vector3(0.25, 0.12, 2.05), 1.3)
	for corner: Vector2 in [Vector2(5.0, 4.0), Vector2(5.0, -4.0), Vector2(-5.0, 4.0), Vector2(-5.0, -4.0)]:
		var top := g + 4.2
		_beam(_mon_p(corner.x, corner.y, g + 0.45), _mon_p(corner.x, corner.y, top + 0.1), 0.14, Color("#2a2a2a"))
		_beam(_mon_p(corner.x - 0.5, corner.y, top), _mon_p(corner.x + 0.5, corner.y, top), 0.08, Color("#2a2a2a"))
		for du: float in [-0.45, 0.45]:
			_prism(_square(_w(corner.x + du, corner.y), 0.15), top + 0.04, top + 0.5, MON_LANTERN, MON_LANTERN, M_LAMP, M_LAMP)
	_collide(_rect(0.0, 0.0, 6.0, 5.0))


## Pomnik Stefana Starzyńskiego on Plac Bankowy, from refs/starzynski/: the mayor of 1939
## sinking into a huge faceted bronze armchair of folded plates, only his head and shoulders
## and his hands on its edge above it, on a low rough granite block with STARZYŃSKI cut in it;
## at the foot of the Blue Tower, facing south-east over the square.
func _build_starzynski(_site: Dictionary) -> void:
	_mon_frame(STARZYNSKI, STARZYNSKI_A)
	_g = _ground_under(_rect(0.0, 0.0, 1.25, 2.0))
	var g := _g
	var bz := STARZYNSKI_BRONZE
	_lbox(0.0, 0.0, 1.25, 2.0, g - 0.2, g + 1.2, Color("#8b8984"), M_STONE, Color("#9a9893"))
	_lbox(1.27, 0.0, 0.03, 1.5, g + 0.45, g + 0.85, Color("#4a4844"))
	_lbox(-2.3, 0.0, 0.45, 2.6, g - 0.2, g + 0.6, MON_GREEN, M_STONE, MON_GREEN.lightened(0.1))
	_mode = M_STONE
	# the chair: a mass leaning back, and its folded plates standing up behind like broken slabs
	_frustum(_rect(-0.1, 0.0, 1.05, 1.9), g + 1.2, _rect(-0.55, 0.0, 0.45, 1.6), g + 3.6, bz, bz.lightened(0.06))
	var plates := [[-1.35, 4.0, 0.05], [-0.5, 4.3, -0.04], [0.5, 4.15, 0.04], [1.35, 3.8, -0.05]]
	for p: Array in plates:
		var v := float(p[0])
		_frustum(_rect(-0.55, v, 0.3, 0.42), g + 2.0, _rect(-0.95, v * (1.1 + float(p[2])), 0.12, 0.3), g + float(p[1]), bz.lightened(0.04), bz)
	# the mayor: shoulders and head above the chair's front, his hands on its edge
	_lbox(0.3, 0.0, 0.25, 0.48, g + 2.6, g + 3.05, bz.darkened(0.04))
	_lbox(0.35, 0.0, 0.13, 0.12, g + 3.05, g + 3.4, bz.darkened(0.04))
	for side: float in [-1.0, 1.0]:
		_lbox(0.85, 0.55 * side, 0.12, 0.09, g + 2.2, g + 2.36, bz.lightened(0.05))
	_collide(_rect(0.0, 0.0, 1.3, 2.05))


## Pomnik Małego Powstańca on Podwale (Jerzy Jarnuszkiewicz, 1983), from refs/maly_powstaniec/:
## a 1.4 m bronze boy in a far-too-big helmet with a white and red band, a submachine gun on
## its strap, on a narrow dark stone post; behind him against the inner face of the city wall
## a semicircular brick terrace with cobbles, a low brick wall, a black railing on its back
## edge, a bronze plaque, red and white flowers and grave candles.
func _build_maly_powstaniec(_site: Dictionary) -> void:
	_mon_frame(MALY, MALY_A)
	_g = _ground_under(_rect(-1.0, 0.0, 2.0, 2.0))
	var g := _g
	# the terrace floor: a half disc behind the post, opening forward
	var floor := PackedVector2Array()
	var arc: Array[Vector2] = []
	for i in 9:
		var t := PI * 0.5 + PI * i / 8.0
		arc.append(Vector2(-1.0 + 2.1 * cos(t), 2.1 * sin(t)))
	for q: Vector2 in arc:
		floor.append(_w(q.x, q.y))
	floor.append(_w(0.9, -2.1))
	floor.append(_w(0.9, 2.1))
	_prism(floor, g - 0.2, g + 0.08, MALY_BRICK.darkened(0.1), Color("#8d8a84"), M_STONE, M_STONE)
	# the low brick wall round the arc, the railing along its back
	for i in 8:
		var a0: Vector2 = arc[i]
		var a1: Vector2 = arc[i + 1]
		var c0 := Vector2(-1.0, 0.0)
		var seg := PackedVector2Array([_w(a0.x, a0.y), _w(a1.x, a1.y), _wl(c0 + (a1 - c0) * 0.85), _wl(c0 + (a0 - c0) * 0.85)])
		_prism(seg, g + 0.08, g + 0.65, MALY_BRICK, MALY_BRICK.lightened(0.08), M_STONE, M_STONE)
	for i in range(2, 7):
		var a0: Vector2 = arc[i]
		var a1: Vector2 = arc[i + 1]
		_beam(Vector3(_wl(a0).x, g + 0.65, _wl(a0).y), Vector3(_wl(a0).x, g + 1.5, _wl(a0).y), 0.05, Color("#1f1f20"))
		_beam(Vector3(_wl(a0).x, g + 1.45, _wl(a0).y), Vector3(_wl(a1).x, g + 1.45, _wl(a1).y), 0.05, Color("#1f1f20"))
	_beam(Vector3(_wl(arc[7]).x, g + 0.65, _wl(arc[7]).y), Vector3(_wl(arc[7]).x, g + 1.5, _wl(arc[7]).y), 0.05, Color("#1f1f20"))
	_lbox(-2.9, 0.0, 0.04, 0.45, g + 0.6, g + 1.25, Color("#6b5a3e"))
	# flowers (red and white) and candles on the terrace
	var beds := [[-2.3, -1.0, Color("#c0392b")], [-2.5, 0.0, Color("#eeeeea")], [-2.3, 1.0, Color("#c0392b")]]
	for b: Array in beds:
		_lbox(float(b[0]), float(b[1]), 0.3, 0.32, g + 0.08, g + 0.36, b[2], M_STONE, b[2])
	for cv: float in [-0.6, -0.3, 0.3, 0.6]:
		_prism(_square(_w(-0.2, cv), 0.06), g + 0.08, g + 0.26, Color("#d9442f"), Color("#ffb347"), M_LAMP, M_LAMP)
	# the post and the boy on it
	_lbox(0.6, 0.0, 0.25, 0.25, g + 0.08, g + 1.38, Color("#3b3b3c"))
	_o = _w(0.6, 0.0)
	var y := g + 1.38
	var h := 1.45
	var k := h / 3.3
	_mon_figure(y, h, MALY_BRONZE, 0.3, Vector3(0.35, -0.1, 1.95), Vector3(0.3, 0.2, 1.75), 1.15)
	# the helmet, far too big, with its white and red band
	var head := _w(0.02 * k, 0.0)
	_mode = M_STONE
	_frustum(_circle(head, 0.2, 8), y + 2.86 * k, _circle(head, 0.1, 8), y + 3.3 * k, MALY_BRONZE.darkened(0.05), MALY_BRONZE.darkened(0.05))
	_prism(_circle(head, 0.205, 8), y + 2.86 * k, y + 2.92 * k, Color("#eeeeea"), Color(0, 0, 0, 0), M_STONE)
	_prism(_circle(head, 0.205, 8), y + 2.92 * k, y + 2.98 * k, Color("#c0392b"), Color(0, 0, 0, 0), M_STONE)
	_beam(_mon_p(0.42 * k, 0.28 * k, y + 1.55 * k), _mon_p(0.48 * k, -0.25 * k, y + 2.1 * k), 0.06, Color("#2a2a2a"))
	_o = MALY
	_collide(_rect(-1.0, 0.0, 2.2, 2.2))


## Pomnik Jana Kilińskiego on Podwale (Stanisław Jackowski, 1936; here since 1959), from
## refs/kilinski/: a polished dark granite pedestal 2 m square and 4.5 m tall with a bronze
## plaque, on two steps; on it the shoemaker of the 1794 Rising striding south-west along
## Podwale in his long kontusz and fur cap, the sabre raised high in his right hand, the left
## at his belt.
func _build_kilinski(_site: Dictionary) -> void:
	_mon_frame(KILINSKI, KILINSKI_A)
	_g = _ground_under(_rect(0.0, 0.0, 2.2, 2.2))
	var g := _g
	var gr := KILINSKI_GRANITE
	_lbox(0.0, 0.0, 2.2, 2.2, g - 0.3, g + 0.3, Color("#6f6e6b"), M_STONE, Color("#7d7c79"))
	_lbox(0.0, 0.0, 1.75, 1.75, g + 0.3, g + 0.6, Color("#5f5e5b"), M_STONE, Color("#6d6c69"))
	_lbox(0.0, 0.0, 1.15, 1.15, g + 0.6, g + 1.0, gr, M_STONE, gr.lightened(0.06))
	_lbox(0.0, 0.0, 1.0, 1.0, g + 1.0, g + 4.1, gr.lightened(0.03))
	_lbox(0.0, 0.0, 1.15, 1.15, g + 4.1, g + 4.5, gr, M_STONE, gr.lightened(0.06))
	_lbox(1.03, 0.0, 0.03, 0.5, g + 2.2, g + 3.0, Color("#5d5440"))
	var bz := KILINSKI_BRONZE
	var hand := _mon_figure(g + 4.5, 3.5, bz, 0.9, Vector3(0.05, -0.38, 1.6), Vector3(0.1, 0.45, 3.55), 1.15, 0.24)
	var k := 3.5 / 3.3
	var tip := hand + Vector3(_a.x, 0.0, _a.y) * 0.3 * k + Vector3.UP * 1.0 * k
	_beam(hand, tip, 0.06 * k, bz.lightened(0.15))
	_collide(_rect(0.0, 0.0, 2.2, 2.2))


## Pomnik Umschlagplatz (Hanna Szmalenberg and Władysław Klamerus, 1988), from
## refs/umschlagplatz/: an open-topped enclosure of white-grey marble slabs, 16 m along Stawki,
## 10 m deep and 4 m high; in the middle of the street side a tall narrow gate under a black
## stone semicircle; a black band round the outside at two thirds of the height with the name
## cut in it; the names on the walls inside. A quiet place: no props, no gags.
func _build_umschlagplatz(_site: Dictionary) -> void:
	_mon_frame(UMSCHLAG, UMSCHLAG_A)
	_g = _ground_under(_rect(0.0, 0.0, 8.0, 5.0))
	var g := _g
	var m := UMSCHLAG_MARBLE
	var bk := UMSCHLAG_BLACK
	var top := g + 4.0
	_mode = M_STONE
	_cap(_rect(0.0, 0.0, 7.6, 4.6), g + 0.06, Color("#bdbdb8"))
	_lbox(0.0, -4.8, 8.0, 0.2, g - 0.3, top, m, M_STONE, m.lightened(0.04))
	for s: float in [-1.0, 1.0]:
		_lbox(7.8 * s, 0.0, 0.2, 4.6, g - 0.3, top, m, M_STONE, m.lightened(0.04))
		_lbox(4.7 * s, 4.8, 3.3, 0.2, g - 0.3, top, m, M_STONE, m.lightened(0.04))
		_lbox(1.1 * s, 4.8, 0.3, 0.3, g - 0.3, g + 4.6, m.darkened(0.03), M_STONE, m)
		# the black band outside, at two thirds of the height
		_lbox(8.03 * s, 0.0, 0.03, 5.0, g + 2.6, g + 3.1, bk)
		_lbox(4.7 * s, 5.03, 3.3, 0.03, g + 2.6, g + 3.1, bk)
		# the names: a slightly darker field on the side walls inside
		_lbox(7.57 * s, 0.0, 0.03, 3.8, g + 0.8, g + 3.4, m.darkened(0.08))
	_lbox(0.0, -5.03, 8.06, 0.03, g + 2.6, g + 3.1, bk)
	_lbox(0.0, -4.57, 6.5, 0.03, g + 0.8, g + 3.4, m.darkened(0.08))
	# the gate: a lintel over the narrow opening, the black semicircle on it
	_lbox(0.0, 4.8, 0.8, 0.3, g + 3.9, g + 4.6, bk)
	_mon_halfdisc(0.0, 4.8, g + 4.6, 1.4, 0.4, bk)
	_collide(_rect(0.0, 0.0, 8.1, 5.1))


## Pomnik Poległym i Pomordowanym na Wschodzie (Maksymilian Biskupski, 1995), from
## refs/pomnik_wschod/: in Muranowska's wide median a bronze railway flatcar piled with crosses
## (Latin and Orthodox, a matzevah and a Muslim tombstone among them), up to 6 m over the
## street, at the east end of a track of 41 bronze sleepers with the places' names, laid on a
## low mound of rounded field stones 37 m long. Respectful, like Umschlagplatz.
func _build_pomnik_wschod(_site: Dictionary) -> void:
	_mon_frame(WSCHOD, WSCHOD_A)
	_g = _ground_under(_rect(0.0, 0.0, 22.0, 2.0))
	var g := _g
	var bz := WSCHOD_BRONZE
	_lbox(0.9, 0.0, 23.9, 4.6, g - 0.3, g + 0.05, Color("#77746f"), M_STONE, Color("#827f79"))
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 22.2, 2.0), g + 0.05, _rect(0.0, 0.0, 22.0, 1.5), g + 0.45, WSCHOD_STONE, WSCHOD_STONE.lightened(0.05))
	# the 41 named sleepers west of the wagon, and the plain ones under it
	for i in 48:
		var u := -21.6 + 0.9 * i
		_lbox(u, 0.0, 0.13, 1.3, g + 0.45, g + 0.6, bz.lightened(0.04 * (i % 3)), M_STONE, bz.lightened(0.08))
	for s: float in [-1.0, 1.0]:
		_lbox(0.0, 0.72 * s, 21.9, 0.04, g + 0.6, g + 0.72, bz.lightened(0.12))
	# the flatcar on its two bogies at the track's east end
	for u: float in [16.4, 20.6]:
		_lbox(u, 0.0, 0.9, 0.85, g + 0.72, g + 1.1, bz.darkened(0.15))
	_lbox(18.5, 0.0, 3.5, 1.25, g + 1.1, g + 1.4, bz.darkened(0.08), M_STONE, bz)
	# the crosses, packed and leaning a little; every fourth Orthodox
	var rng := RandomNumberGenerator.new()
	rng.seed = 1795
	var deck := g + 1.4
	for i in 24:
		var cu := rng.randf_range(15.4, 21.6)
		var cv := rng.randf_range(-0.95, 0.95)
		var hh := rng.randf_range(2.2, 4.6)
		var lean := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
		var foot := _mon_p(cu, cv, deck)
		var head := foot + Vector3.UP * hh + lean
		var col := bz.lightened(rng.randf_range(0.0, 0.12))
		_beam(foot, head, 0.14, col)
		var arm := 0.28 * hh
		var at := foot.lerp(head, 0.74)
		var across := Vector3(_b.x, 0.0, _b.y) * arm * 0.5 if i % 2 == 0 else Vector3(_a.x, 0.0, _a.y) * arm * 0.5
		_beam(at - across, at + across, 0.12, col)
		if i % 4 == 1:
			var top := foot.lerp(head, 0.88)
			_beam(top - across * 0.5, top + across * 0.5, 0.1, col)
			var low := foot.lerp(head, 0.4)
			_beam(low - across * 0.5 - Vector3.UP * 0.12, low + across * 0.5 + Vector3.UP * 0.12, 0.1, col)
	# the matzevah (a round-topped slab) and the Muslim tombstone (a pointed one)
	_lbox(16.0, -0.6, 0.08, 0.35, deck, deck + 1.2, bz.lightened(0.1))
	_frustum(_rect(16.0, -0.6, 0.08, 0.35), deck + 1.2, _rect(16.0, -0.6, 0.08, 0.18), deck + 1.42, bz.lightened(0.1), bz.lightened(0.1))
	_lbox(21.2, 0.55, 0.08, 0.25, deck, deck + 1.0, bz.lightened(0.06))
	_pyramid(_rect(21.2, 0.55, 0.08, 0.25), deck + 1.0, deck + 1.4, bz.lightened(0.06))
	# the cobbled apron round it (4.6 m each side, 2 m past the buffers): the kerb a car meets
	_collide(_rect(0.9, 0.0, 23.9, 4.6))


# --- The Dekalog estate and the Inflancka pools (F's photos, 2026-11-07) -------------------------

## The large-panel estate between Inflancka, Dzika and Stawki where Kieślowski shot most of the
## Dekalog (mapadekalogu.pl: Dzika 6, episodes I, IV, VI), from F's photo set
## (~/Documents/warsaw-kieslowski-photos, rows K01-K08: Dzika 6 from the south 2026, two 1970s
## fronts, GUGiK ortho and the city's 2018 oblique flights; spec docs/landmarks/specs/dekalog_estate.md).
## Six 14-storey slabs, each a chain of staggered segments: pale cream plaster with punched windows,
## narrow ochre stair strips where one segment steps back from the next, blank gable ends, and
## at both ends of every segment's long face a stack of white concrete balconies, one per floor.
## Dark flat roofs with lift houses. OpenStreetMap draws them with every balcony notch; the model
## simplifies the outline to the segments (DE_SIMPLIFY) and builds the balconies itself.
## Interior points of the six OSM outlines: Dzika 6, Inflancka 15, Inflancka 19, Inflancka 11,
## Dzika 19/23, Stawki 6.
const DE_AT := [Vector2(-2522.3, -2182.1), Vector2(-2427.1, -2241.4), Vector2(-2522.9, -2328.4),
		Vector2(-2343.4, -2208.7), Vector2(-2647.1, -2153.7), Vector2(-2248.0, -2192.1)]

const DE_SIMPLIFY := 1.8
const DE_FLOORS := 14
const DE_FLOOR := 2.95                 # the S_PUNCHED shader's floor height
const DE_ATTIC := 0.9
const DE_FACE := 9.0                   # a long face at least this long carries balconies
const DE_BAL_W := 3.2                  # a balcony stack's width along the face
const DE_BAL_D := 1.25                 # how far it stands out
const DE_BAL_IN := 0.5                 # held in from the face's ends
const DE_PLASTER := Color("#ece3c8")   # the 2026 photo: pale cream
const DE_GABLE := Color("#e2d7b8")
const DE_STAIR := Color("#d9b874")     # the ochre stair strips between segments
const DE_SLAB := Color("#f2f0ea")      # the balconies' white concrete
const DE_PARAPET := Color("#e9e7df")
const DE_ROOF := Color("#55585c")
const DE_LIFT := Color("#d8cfb4")


func _find_dekalog_estate() -> void:
	var zones: Array[PackedVector2Array] = []
	var outlines: Array[PackedVector2Array] = []
	for at: Vector2 in DE_AT:
		var q := _outline_at(at)
		if q.size() >= 3:
			zones.append(_largest(Geometry2D.offset_polygon(q, 2.5, Geometry2D.JOIN_MITER)))
			outlines.append(q)
	_add_site("dekalog_estate", zones)
	if not sites.is_empty() and sites[-1]["key"] == "dekalog_estate":
		sites[-1]["outlines"] = outlines


func _build_dekalog_estate(site: Dictionary) -> void:
	for raw: PackedVector2Array in site["outlines"]:
		var poly := _simplify(raw, DE_SIMPLIFY)
		if poly.size() < 3:
			continue
		_dekalog_slab(poly)
	_mode = M_STONE


## One staggered slab: walls by face kind, the roof, lift houses, the balcony stacks, the ring.
func _dekalog_slab(poly: PackedVector2Array) -> void:
	_g = _ground_under(poly)
	var g := _g
	var top := g + DE_FLOOR * DE_FLOORS + DE_ATTIC
	# The long axis: the direction the longest run of parallel edges adds up along.
	var axis := Vector2.ZERO
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() > axis.length():
			axis = e
	axis = axis.normalized()
	var run := 0.0
	var faces: Array = []
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var len := a.distance_to(b)
		var o := _out(poly, a, b)
		var end_on := absf(o.dot(axis)) > 0.7
		if end_on and len < DE_FACE:
			_mode = M_STONE
			_wall(a, b, g - 0.4, top + 0.6, o, DE_STAIR, run)
		elif end_on:
			_mode = M_STONE
			_wall(a, b, g - 0.4, top, o, DE_GABLE, run)
		else:
			_mode = M_SKIN + float(S_PUNCHED) / 16.0
			_wall(a, b, g - 0.4, top, o, DE_PLASTER, run)
			if len >= DE_FACE:
				faces.append([a, b, o])
		run += len
	_mode = M_STONE
	_cap(poly, top, DE_ROOF)
	# Lift houses over each segment's middle: one every ~22 m along the axis.
	var c0 := _centre(poly)
	var span := 0.0
	for q in poly:
		span = maxf(span, absf((q - c0).dot(axis)))
	var across := Vector2(-axis.y, axis.x)
	var n := maxi(1, roundi(span * 2.0 / 22.0))
	for k in n:
		var p := c0 + axis * span * (-1.0 + (2.0 * k + 1.0) / n) * 0.85
		if not Geometry2D.is_point_in_polygon(p, poly):
			continue
		_prism(PackedVector2Array([p - axis * 2.4 - across * 1.8, p + axis * 2.4 - across * 1.8, p + axis * 2.4 + across * 1.8,
				p - axis * 2.4 + across * 1.8]), top, top + 2.8, DE_LIFT, DE_ROOF, M_STONE, M_STONE)
	# The balcony stacks: at both ends of each long face, floors 1 to 13.
	for f: Array in faces:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var o: Vector2 = f[2]
		var d := (b - a).normalized()
		for end: Array in [[a + d * DE_BAL_IN, a + d * (DE_BAL_IN + DE_BAL_W)], [b - d * (DE_BAL_IN + DE_BAL_W), b - d * DE_BAL_IN]]:
			_dekalog_stack(end[0], end[1], o, g, top)
	_collide(poly)


## A stack of balconies on the face between p and q, standing out along o: a slab and a solid
## parapet front with short sides on every floor above the ground floor.
func _dekalog_stack(p: Vector2, q: Vector2, o: Vector2, g: float, top: float) -> void:
	var p2 := p + o * DE_BAL_D
	var q2 := q + o * DE_BAL_D
	var d := (q - p).normalized()
	_mode = M_STONE
	for n in range(1, DE_FLOORS):
		var y := g + DE_FLOOR * n
		if y + 1.1 > top:
			break
		var slab := PackedVector2Array([p, q, q2, p2])
		if Geometry2D.is_polygon_clockwise(slab):
			slab.reverse()
		_prism(slab, y - 0.18, y, DE_SLAB, DE_SLAB, M_STONE, M_STONE)
		_wall(p2, q2, y, y + 1.05, o, DE_PARAPET)
		_wall(p, p2, y, y + 1.05, -d, DE_PARAPET)
		_wall(q2, q, y, y + 1.05, d, DE_PARAPET)


## Ośrodek Sportowy Inflancka 8, across Inflancka from the estate (F, 2026-11-07: "the centre of
## Muranów where the pools are"), from F's row K09: the GUGiK ortho (georeferenced, 0.15 m a
## pixel, it matches OSM's lap pool to under a metre), the 2018 oblique and five 2022 summer
## photos. The white air dome over the indoor pool (OSM's 14 m `building` outline), the yellow
## deck with three round leisure pools (a pale one, one with a red-brown painted floor, a deep
## blue one), the 25 m lap pool with its lanes on a sand-yellow deck, the slide tower with a red
## chute and a green spiral, and a beach volleyball court.
const IP_DOME_AT := Vector2(-2336.0, -2370.0)
const IP_DOME_H := 11.0
const IP_DOME_WALL := 1.1
const IP_DECK_H := 0.35                # the decks stand this far over the ground
const IP_LEISURE := [Vector2(-2325.9, -2413.8), Vector2(-2304.5, -2427.4), Vector2(-2289.8, -2400.6), Vector2(-2311.3, -2389.3)]
## The round pools: centre, radius, water colour.
const IP_ROUND := [[Vector2(-2310.3, -2415.2), 4.2, Color("#8fd0e2")], [Vector2(-2309.2, -2405.0), 6.4, Color("#b4806c")],
		[Vector2(-2299.3, -2406.1), 6.2, Color("#2f5e98")]]
const IP_LAP := [Vector2(-2294.6, -2381.9), Vector2(-2271.4, -2393.5), Vector2(-2265.5, -2381.8), Vector2(-2288.7, -2370.2)]
const IP_SPIRAL := Vector2(-2255.8, -2385.8)
const IP_CHUTE_END := Vector2(-2258.0, -2377.6)
const IP_SAND := Vector2(-2220.5, -2374.5)
const IP_DOME := Color("#eef0ec")
const IP_DOME_BASE := Color("#c9c7c0")
const IP_DECK := Color("#e1c35c")
const IP_LAP_DECK := Color("#d9b85a")
const IP_RIM := Color("#e8eeee")
const IP_RING := Color("#3d8fb5")
const IP_WATER := Color("#41c3e6")
const IP_LANE := Color("#1d5fa8")
const IP_RED := Color("#d8343a")
const IP_GREEN := Color("#3fa66a")
const IP_STEEL := Color("#9aa1a6")
const IP_SANDC := Color("#dccb9d")


func _find_inflancka_pools() -> void:
	var dome := _outline_at(IP_DOME_AT)
	var zone: Array = []
	if dome.size() >= 3:
		zone.append(_largest(Geometry2D.offset_polygon(dome, 1.5, Geometry2D.JOIN_MITER)))
	zone.append(PackedVector2Array(IP_LEISURE))
	zone.append(_ip_lap_deck())
	zone.append(_ip_circle(IP_SAND, 10.5, 8))
	_add_site("inflancka_pools", zone)
	if sites.is_empty() or sites[-1]["key"] != "inflancka_pools":
		return
	sites[-1]["dome"] = dome
	for plan: PackedVector2Array in [PackedVector2Array(IP_LEISURE), _ip_lap_deck()]:
		var grown := _largest(Geometry2D.offset_polygon(plan, 1.5, Geometry2D.JOIN_MITER))
		tree_free.append([grown, 0.0, _box_of([grown])])
	tree_free.append([IP_SPIRAL, 5.0])
	tree_free.append([IP_SAND, 10.0])


## The lap pool's deck: the pool grown 3.5 m, and 6 m more on the slide's end.
func _ip_lap_deck() -> PackedVector2Array:
	var p := PackedVector2Array(IP_LAP)
	var u := (p[1] - p[0]).normalized()       # along the pool, towards the slide
	var v := (p[3] - p[0]).normalized()
	var m := 3.5
	return PackedVector2Array([p[0] - u * m - v * m, p[1] + u * (m + 6.0) - v * m, p[2] + u * (m + 6.0) + v * m, p[3] - u * m + v * m])


static func _ip_circle(c: Vector2, r: float, sides := 28) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in sides:
		var t := TAU * k / sides
		out.append(c + Vector2(cos(t), sin(t)) * r)
	return out


func _build_inflancka_pools(site: Dictionary) -> void:
	var leisure := PackedVector2Array(IP_LEISURE)
	_g = _ground_under(leisure)
	var g := _g
	_mode = M_STONE
	# The decks are low slabs (IP_DECK_H) so the park's pitch and grass under them never show
	# through; on the leisure deck the three round pools: a blue ring, then the water.
	var top := g + IP_DECK_H
	_prism(leisure, g - 0.3, top, IP_DECK.darkened(0.15), IP_DECK, M_STONE, M_STONE)
	for r: Array in IP_ROUND:
		_cap(_ip_circle(r[0], float(r[1]) + 0.35), top + 0.03, IP_RING)
	for r: Array in IP_ROUND:
		_cap(_ip_circle(r[0], float(r[1])), top + 0.06, r[2])
	# The lap pool: the deck, a white rim, the water and five lane lines.
	var lap := PackedVector2Array(IP_LAP)
	_prism(_ip_lap_deck(), g - 0.3, top, IP_LAP_DECK.darkened(0.15), IP_LAP_DECK, M_STONE, M_STONE)
	var rim := Geometry2D.offset_polygon(lap, 0.45, Geometry2D.JOIN_MITER)
	if not rim.is_empty():
		_cap(rim[0], top + 0.03, IP_RIM)
	_cap(lap, top + 0.06, IP_WATER)
	var u := lap[1] - lap[0]
	var v := lap[3] - lap[0]
	for k in range(1, 6):
		var s := float(k) / 6.0
		var a := lap[0] + v * s + u.normalized() * 1.5
		var b := lap[1] + v * s - u.normalized() * 1.5
		var w := v.normalized() * 0.12
		_cap(PackedVector2Array([a - w, b - w, b + w, a + w]), top + 0.08, IP_LANE)
	# The beach volleyball court (turned with the lap pool), a low sand bed; the playground's
	# sand circle is OpenStreetMap's own.
	var cu := u.normalized()
	var cv := v.normalized()
	var court := PackedVector2Array([IP_SAND - cu * 9.0 - cv * 4.5, IP_SAND + cu * 9.0 - cv * 4.5, IP_SAND + cu * 9.0 + cv * 4.5,
			IP_SAND - cu * 9.0 + cv * 4.5])
	if Geometry2D.is_polygon_clockwise(court):
		court.reverse()
	_prism(court, g - 0.3, g + 0.2, IP_SANDC.darkened(0.2), IP_SANDC, M_STONE, M_STONE)
	for sgn: float in [-1.0, 1.0]:
		var post := IP_SAND + cv * 4.8 * sgn
		_beam(Vector3(post.x, g, post.y), Vector3(post.x, g + 2.5, post.y), 0.1, IP_STEEL)
	var n0 := IP_SAND - cv * 4.8
	var n1 := IP_SAND + cv * 4.8
	_beam(Vector3(n0.x, g + 2.35, n0.y), Vector3(n1.x, g + 2.35, n1.y), 0.06, Color("#f4f4f0"), false)
	_ip_slide(g)
	_ip_dome(site.get("dome", PackedVector2Array()))


## The slide tower: four posts and a deck at 6.5 m, the red chute down to the end of the strip
## by the lap pool and the green spiral wound round the tower down to the splash basin.
func _ip_slide(g: float) -> void:
	var c := IP_SPIRAL
	var h := 6.5
	for k in 4:
		var p := c + Vector2(cos(TAU * k / 4.0 + 0.4), sin(TAU * k / 4.0 + 0.4)) * 1.3
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + h + 1.0, p.y), 0.2, IP_STEEL)
	_prism(_ip_circle(c, 1.6, 8), g + h - 0.15, g + h, IP_STEEL, IP_STEEL.darkened(0.1), M_STONE, M_STONE)
	# The red straight chute.
	var top := c + (IP_CHUTE_END - c).normalized() * 1.6
	_beam(Vector3(top.x, g + h, top.y), Vector3(IP_CHUTE_END.x, g + 0.6, IP_CHUTE_END.y), 1.0, IP_RED)
	# The green spiral: 1.5 turns at 3.3 m, from the deck down to 1 m.
	var steps := 18
	var prev := Vector3.INF
	for k in steps + 1:
		var t := float(k) / steps
		var ang := 0.4 + t * TAU * 1.5
		var p := c + Vector2(cos(ang), sin(ang)) * 3.3
		var y := g + lerpf(h, 1.0, t)
		var here := Vector3(p.x, y, p.y)
		if prev != Vector3.INF:
			_beam(prev, here, 0.9, IP_GREEN)
		prev = here
	_cap(_ip_circle(c + Vector2(cos(0.4 + TAU * 1.5), sin(0.4 + TAU * 1.5)) * 5.0, 1.6, 12), g + IP_DECK_H + 0.06, IP_WATER)
	_collide(_ip_circle(c, 1.6, 8))


## The air dome over the indoor pool: a concrete kerb round OSM's outline, then a cushion over
## the outline's turned rectangle, rising IP_DOME_H with rounded shoulders (a superellipse).
func _ip_dome(outline: PackedVector2Array) -> void:
	var poly := _simplify(outline, 1.0)
	if poly.size() < 3:
		return
	_g = _ground_under(poly)
	var g := _g
	var axis := Vector2.ZERO
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() > axis.length():
			axis = e
	axis = axis.normalized()
	var across := Vector2(-axis.y, axis.x)
	var c := _centre(poly)
	var hu := 0.0
	var hv := 0.0
	for q in poly:
		hu = maxf(hu, absf((q - c).dot(axis)))
		hv = maxf(hv, absf((q - c).dot(across)))
	hu -= 0.4
	hv -= 0.4
	var ring := PackedVector2Array([c - axis * hu - across * hv, c + axis * hu - across * hv, c + axis * hu + across * hv,
			c - axis * hu + across * hv])
	_prism(ring, g - 0.3, g + IP_DOME_WALL, IP_DOME_BASE, Color(0, 0, 0, 0), M_STONE)
	var nu := 16
	var nv := 11
	var base := g + IP_DOME_WALL
	var pts: Array = []
	for i in nu + 1:
		var row: Array = []
		var s := -1.0 + 2.0 * i / nu
		for j in nv + 1:
			var t := -1.0 + 2.0 * j / nv
			var hgt := IP_DOME_H * pow(maxf(0.0, 1.0 - pow(absf(s), 4.0)), 0.25) * pow(maxf(0.0, 1.0 - pow(absf(t), 3.0)), 0.33)
			var p := c + axis * hu * s + across * hv * t
			row.append(Vector3(p.x, base + hgt, p.y))
		pts.append(row)
	for i in nu:
		for j in nv:
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i + 1][j]
			var d: Vector3 = pts[i + 1][j + 1]
			var e: Vector3 = pts[i][j + 1]
			var nrm := (d - a).cross(b - e).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			# A faint quilting: every other cell a shade darker.
			var col := IP_DOME if (i + j) % 2 == 0 else IP_DOME.darkened(0.04)
			_quad(a, b, d, e, nrm, col)
	_collide(ring)
