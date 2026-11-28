extends "res://scripts/landmarks/skyline.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Plac Defilad round the Palace:
## the Palace, Złote Tarasy, the Rotunda, the Patelnia and the sunken places, Rondo Dmowskiego, the
## Eastern Wall's stores and the blocks behind them, MSN, TR's site, Plac Centralny, the pavilions
## by the Palace. Moved as it was from the one big file. landmarks.gd is the class the game makes;
## every file of game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd,
## then the areas in the order of landmarks.gd's `extends` chain), so code here may use this file,
## common.gd and the facade kit, never another area: a helper two areas need goes to common.gd.
const SANDSTONE := Color("#d8c49c")   # the Palace (bake_gugik.py LANDMARKS)
const SANDSTONE_LIGHT := Color("#e6d6b2")
const PATINA := Color("#9fbcae")

const SPIRE_GOLD := Color("#d4a640")    # the Palace's spire (Mac photo check 2026-11-01)
const SPIRE_BRONZE := Color("#5a4630")  # the dark bronze lantern at the spire's foot
const HALL_METAL := Color("#8d9398")    # the Congress Hall's flat stepped metal roof

const COURT_GLASS := Color("#3b4650")
const COURT_STEP := 3.6    # m between the court walls' window bays
const COURT_FLOOR := 3.6   # m per storey


# --- the Palace of Culture and Science ------------------------------------------------------

## The Palace's own axes run with the Śródmieście grid: u towards Marszałkowska (the
## main front, ENE), v towards Al. Jerozolimskie (SSE). Its tiers come from the
## OpenStreetMap building parts (base 18 m, tower to 67, shaft to 139, clock tier to 168,
## lantern to 188, crown to 204, the gilded spire to 237 m); the plan below is those
## parts' outlines in the Palace's frame (metres from the clock tier's centre).
const P_WINGS := [
	# u0, v0, u1, v1, top: the four corner pavilions and the east entrance block (the parts
	# of 22.5 m; spec docs/landmarks/specs/palace.md).
	[-79.5, 68.7, -53.0, 119.7, 22.5], [-81.0, -120.9, -53.7, -70.5, 22.5],
	[53.9, -121.0, 80.4, -69.8, 22.5], [55.5, 68.3, 82.1, 119.4, 22.5],
	[28.0, -10.6, 46.4, 12.1, 22.5],
]
## The north and south blocks (30 m) that join the tower to the annexes: their mapped
## outlines, from the tower's faces out to the annexes' ends.
const P_BLOCKS := [
	[[-7.7, 64.6], [-12.4, 64.6], [-12.4, 60.3], [-17.7, 60.3], [-17.8, 44.5], [-13.5, 44.5], [-13.4, 34.1],
			[-13.5, 21.4], [-10.3, 21.4], [-10.3, 20.0], [10.5, 20.1], [10.5, 21.6], [14.0, 21.6], [14.1, 34.1],
			[14.0, 45.4], [17.2, 45.4], [17.3, 60.1], [12.2, 60.1], [12.3, 64.6], [7.7, 64.7]],
	[[-12.2, -63.9], [-12.3, -68.2], [11.1, -68.0], [11.1, -63.7], [16.5, -63.7], [16.5, -49.9], [14.2, -49.9],
			[14.2, -21.8], [9.8, -21.7], [9.8, -20.2], [-10.6, -20.2], [-10.6, -21.8], [-15.0, -21.8], [-15.1, -50.2],
			[-17.6, -50.2], [-17.6, -63.9]],
]
## The tower's first tier (18-67 m): the shaft's plan with a corner tower on each corner.
const P_TIER := [[-21.7, 10.8], [-20.4, 10.7], [-20.5, -10.3], [-22.3, -10.3], [-22.3, -17.6], [-32.6, -17.7],
		[-32.5, -35.4], [-15.1, -35.4], [-15.0, -21.8], [-10.6, -21.8], [-10.6, -20.2], [9.8, -20.2], [9.8, -21.7],
		[14.2, -21.8], [14.2, -35.8], [31.8, -35.7], [31.8, -17.7], [20.9, -17.7], [21.0, -9.3], [19.7, -9.3],
		[19.8, 10.8], [21.2, 10.7], [21.2, 16.6], [31.8, 16.6], [31.8, 34.2], [14.1, 34.1], [14.0, 21.6],
		[10.5, 21.6], [10.5, 20.1], [-10.3, 20.0], [-10.3, 21.4], [-13.4, 21.4], [-13.4, 34.1], [-31.6, 34.1],
		[-31.6, 16.6], [-21.6, 16.7]]
## The corner towers of the first tier: u0, v0, u1, v1.
const P_CORNERS := [[-32.6, -35.4, -15.0, -17.7], [14.2, -35.8, 31.8, -17.7], [14.1, 16.6, 31.8, 34.2],
		[-31.6, 16.6, -13.4, 34.1]]
## The shaft (67-139 m): heavy corner piers, each face's middle bay set back 1.3-1.8 m.
const P_SHAFT := [[-21.6, 16.7], [-21.7, 10.8], [-20.4, 10.7], [-20.5, -10.3], [-22.3, -10.3], [-22.3, -21.9],
		[-10.6, -21.8], [-10.6, -20.2], [9.8, -20.2], [9.8, -21.7], [21.0, -21.7], [21.0, -9.3], [19.7, -9.3],
		[19.8, 10.8], [21.2, 10.7], [21.2, 21.6], [10.5, 21.6], [10.5, 20.1], [-10.3, 20.0], [-10.3, 21.4],
		[-21.7, 21.3]]
## The shaft's set-back middle bays, one per face: centre u, centre v, normal u, normal v,
## half width along the face.
const P_BAYS := [[19.75, 0.75, 1.0, 0.0, 10.0], [-20.45, 0.2, -1.0, 0.0, 10.4], [0.1, 20.05, 0.0, 1.0, 10.4],
		[-0.4, -20.2, 0.0, -1.0, 10.2]]
## The gates into the south courtyard (F, 2026-11-08: "the road goes into the building"): OSM maps
## the two driveways off the service road by the Congress Hall through the south-west block as
## `tunnel=building_passage` (ways 365218395 and 960211301), which the bake never draws, so the
## roads ended at a bare wall. Each gate: the wall's plane u, the centre v, the width and the
## height of the opening (the passages' outer ends; the courtyard behind is private, so closed).
const P_GATES := [[-82.4, 48.2, 4.2, 4.4], [-82.4, 55.7, 4.2, 4.4]]
const P_GATE_DARK := Color("#2f2c28")
const P_GATE_STEEL := Color("#5e6662")
## The courtyards (the relation's inner rings).
const P_COURTS := [
	[[-68.4, 40.7], [-67.6, 40.7], [-67.6, 36.1], [-48.8, 36.2], [-48.8, 32.8], [-34.4, 32.9], [-34.4, 65.1],
			[-48.2, 65.1], [-48.2, 63.9], [-68.4, 63.9]],
	[[-69.2, -41.8], [-69.2, -64.4], [-49.4, -64.3], [-49.4, -65.4], [-34.8, -65.4], [-34.7, -33.5],
			[-49.1, -33.5], [-49.1, -37.4], [-67.9, -37.4], [-67.9, -41.8]],
]
## The Congress Hall (west end): its mapped outline, the block and the auditorium's
## half-round end towards Emilii Plater.
const P_HALL := [[-93.6, 24.6], [-97.3, 23.1], [-101.6, 20.3], [-104.4, 18.0], [-107.7, 14.2], [-110.0, 10.0],
		[-111.8, 5.7], [-112.7, 1.3], [-112.6, -2.6], [-111.9, -6.8], [-110.5, -10.8], [-108.8, -14.4],
		[-106.6, -17.3], [-104.2, -20.2], [-101.2, -22.4], [-97.2, -24.6], [-93.3, -26.0], [-89.0, -26.8],
		[-80.5, -26.7], [-80.5, -34.2], [-65.8, -34.1], [-65.7, -22.4], [-63.3, -22.5], [-63.3, -20.0],
		[-55.3, -20.0], [-55.3, 18.8], [-62.4, 18.8], [-62.4, 20.9], [-65.1, 20.9], [-65.0, 33.4], [-80.3, 33.3],
		[-80.3, 25.3], [-89.3, 25.3]]


func _palace_frame() -> void:
	# The clock tier (139-168 m) is a square: its centre and edges give the frame.
	var outline := _landmark("Pałac Kultury i Nauki")
	var box := _box_of([outline])
	for bld in data["buildings"]:
		if absf(float(bld["h"]) - 168.0) < 0.5 and absf(float(bld["mh"]) - 139.0) < 0.5:
			var sq := _pts(bld["p"])
			if sq.size() >= 4 and box.has_point(_centre(sq)):
				_o = _centre(sq)
				# The edge closest to the grid's east-west direction is the u axis.
				for i in sq.size():
					var e := sq[(i + 1) % sq.size()] - sq[i]
					if e.length() > 5.0 and absf(e.normalized().x) > 0.7:
						_a = e.normalized() * signf(e.x)
						_b = Vector2(-_a.y, _a.x)
						return
	# Fallback: measured from the 2026 data.
	_o = Vector2(-1214.25, 247.3)
	_a = Vector2(0.9403, -0.3404)
	_b = Vector2(0.3404, 0.9403)


## Whether plan point p lies on a ring's outline (within 0.4 m): an edge there is shared.
func _on_ring(p: Vector2, ring: PackedVector2Array) -> bool:
	for i in ring.size():
		var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
		if q.distance_to(p) < 0.4:
			return true
	return false


func _build_palace(site: Dictionary) -> void:
	_palace_frame()
	var outer: PackedVector2Array = site["zone"][0]
	_g = _ground_under(outer)
	var g := _g
	if palace_source() != "code" and _palace_glb(outer, g):
		return
	var stone := SANDSTONE
	var light := SANDSTONE_LIGHT
	var roof := Color("#8f877a")
	var courts: Array = []
	for c in P_COURTS:
		courts.append(_lpoly(c))

	# The base: four storeys round the courtyards, a crenellated attic on top.
	_mode = M_MONUMENT
	var run := 0.0
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		_wall(a, b, g - 0.4, g + 18.0, _out(outer, a, b), stone, run)
		run += a.distance_to(b)
	for ring: PackedVector2Array in courts:
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			_wall(a, b, g + 4.0, g + 18.0, -_out(ring, a, b), stone.darkened(0.08))
		_mode = M_STONE
		_cap(ring, g + 4.0, Color("#a39c90"))
		_mode = M_MONUMENT
	_mode = M_STONE
	_cap_holes(outer, courts, g + 18.0, roof)
	_attic(outer, g + 18.0, 1.6, light)
	_collide(outer)

	# Wings: the corner pavilions and the entrance block.
	for w in P_WINGS:
		var poly := _lpoly([[w[0], w[1]], [w[2], w[1]], [w[2], w[3]], [w[0], w[3]]])
		_prism(poly, g + 17.0, g + w[4], stone, roof, M_MONUMENT, M_STONE)
		_attic(poly, g + w[4], 1.4, light)
		# Small pinnacles on the pavilions' corners.
		for k in 4:
			var cu: float = w[0] if k % 2 == 0 else w[2]
			var cv: float = w[1] if k < 2 else w[3]
			_pinnacle(cu, cv, 1.4, g + w[4], 4.2, light)

	# The tower: its first tier (to 67 m) and the shaft (to 139 m) on their mapped plans.
	var tier := _lpoly(P_TIER)
	var shaft := _lpoly(P_SHAFT)

	# The north and south blocks (30 m) between the tower and the annexes; no wall where they
	# meet the tower (it would hide inside it).
	for blk in P_BLOCKS:
		var poly := _lpoly(blk)
		_mode = M_MONUMENT
		var run2 := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if not _on_ring((a + b) * 0.5, tier):
				_wall(a, b, g + 17.0, g + 30.0, _out(poly, a, b), stone, run2)
			run2 += a.distance_to(b)
		_mode = M_STONE
		for piece in Geometry2D.clip_polygons(poly, tier):
			if not Geometry2D.is_polygon_clockwise(piece):
				_cap(piece, g + 30.0, roof)
		# The parapet only round the outer end (the open part beside the tower stays bare).
		var outer_end := PackedVector2Array()
		for q in blk:
			if absf(float(q[1])) > 40.0:
				outer_end.append(_w(q[0], q[1]))
		_attic(outer_end, g + 30.0, 1.4, light, false)
		var far: float = 60.2 if float(blk[0][1]) > 0.0 else -63.8
		var near: float = 45.0 if float(blk[0][1]) > 0.0 else -50.0
		for cu in [-17.6, 17.2]:
			_pinnacle(cu, far, 1.6, g + 30.0, 5.0, light)
			_pinnacle(cu, near, 1.6, g + 30.0, 5.0, light)

	# The Congress Hall: its mapped block with the half-round end under a flat grey metal roof
	# in concentric steps (Mac photo check 2026-11-01): the roof at the wall top, a raised
	# drum about 48 m across over the auditorium, its flat top with a small vent cap.
	var hall := _lpoly(P_HALL)
	_prism(hall, g + 17.0, g + 22.5, stone, HALL_METAL, M_MONUMENT, M_STONE)
	_attic(hall, g + 22.5, 1.2, light)
	var drum := PackedVector2Array()
	for k in 16:
		var t := TAU * k / 16.0
		drum.append(_w(-86.0 + cos(t) * 24.0, -0.75 + sin(t) * 23.5))
	_prism(drum, g + 22.5, g + 26.0, HALL_METAL.darkened(0.12), HALL_METAL.lightened(0.06), M_STONE, M_STONE)
	_lbox(-86.0, -0.75, 2.0, 2.0, g + 26.0, g + 27.0, HALL_METAL.darkened(0.2), M_STONE)

	# The gates of the two building passages into the south courtyard.
	for gt in P_GATES:
		_palace_gate(float(gt[0]), float(gt[1]), float(gt[2]), float(gt[3]), g, light)

	# The east portico (Mac photo check 2026-11-01: about 25 m wide): six columns before the
	# entrance, an entablature on them.
	for k in 6:
		var cv := -12.0 + k * 4.8
		_lbox(53.4, cv, 0.65, 0.65, g, g + 13.5, light, M_STONE)
	_lbox(53.4, 0.0, 1.5, 12.8, g + 13.5, g + 15.6, stone, M_STONE, light)
	_palace_name(54.95, g)

	# Tier one: walls to 67 m, a roof only on the corner towers (the shaft stands on the rest).
	_mode = M_MONUMENT
	var run1 := 0.0
	for i in tier.size():
		var a := tier[i]
		var b := tier[(i + 1) % tier.size()]
		_wall(a, b, g + 17.0, g + 67.0, _out(tier, a, b), stone, run1)
		run1 += a.distance_to(b)
	_mode = M_STONE
	for piece in Geometry2D.clip_polygons(tier, shaft):
		if not Geometry2D.is_polygon_clockwise(piece) and absf(_area(piece)) > 4.0:
			_cap(piece, g + 67.0, roof)
	for cr in P_CORNERS:
		var cu: float = (cr[0] + cr[2]) * 0.5
		var cv: float = (cr[1] + cr[3]) * 0.5
		var hu: float = (cr[2] - cr[0]) * 0.5
		var hv: float = (cr[3] - cr[1]) * 0.5
		var corner := _rect(cu, cv, hu, hv)
		_attic(corner, g + 67.0, 2.2, light)
		for q in 4:
			var pu: float = cu + (-hu + 1.3 if q % 2 == 0 else hu - 1.3)
			var pv: float = cv + (-hv + 1.3 if q < 2 else hv - 1.3)
			if not Geometry2D.is_point_in_polygon(_w(pu, pv), shaft):
				_pinnacle(pu, pv, 1.8, g + 67.0, 7.0, light)
		# A small stepped crown on each corner tower.
		_prism(_rect(cu, cv, 4.5, 4.5), g + 67.0, g + 73.0, light, roof, M_STONE, M_STONE)
		_pinnacle(cu, cv, 2.2, g + 73.0, 9.0, light)

	# The shaft: heavy corner piers and a set-back middle bay on each face, ribbed in stone.
	_prism(shaft, g + 67.0, g + 139.0, stone, roof, M_MONUMENT, M_STONE)
	for bay in P_BAYS:
		var nu: float = bay[2]
		var nv: float = bay[3]
		for k in 5:
			var t: float = -bay[4] + bay[4] * 0.2 + k * bay[4] * 0.4
			var ru: float = bay[0] + nu * 0.45 + absf(nv) * t
			var rv: float = bay[1] + nv * 0.45 + absf(nu) * t
			_lbox(ru, rv, 0.45 if nu != 0.0 else 0.5, 0.45 if nv != 0.0 else 0.5, g + 67.0, g + 121.5, light, M_STONE)
			_lbox(ru, rv, 0.45 if nu != 0.0 else 0.5, 0.45 if nv != 0.0 else 0.5, g + 123.0, g + 136.0, light, M_STONE)
	# A thin cornice band about five storeys under the top (Mac photo check 2026-11-01: the
	# shaft keeps one width up to its top cornice; no step at the 114 m terrace).
	var band: PackedVector2Array = Geometry2D.offset_polygon(shaft, 0.6, Geometry2D.JOIN_MITER)[0]
	_prism(band, g + 121.5, g + 123.0, light, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	_cap_holes(band, [shaft], g + 123.0, light)
	# The 30th-floor observation terrace (F, 2026-11-01): a 1.9 m ledge round the shaft at 114 m
	# (the real gallery runs inside the walls; the ledge is the walkway the visitors need, crowds.gd
	# DECKS `pkin_terrace`, 22.4 m from the centre) with a stone balustrade 1.1 m high.
	for su: float in [-1.0, 1.0]:
		_lbox(su * 21.5, 0.0, 1.9, 23.4, g + 113.5, g + 114.0, light, M_STONE, light.darkened(0.12))
		_lbox(0.0, su * 21.5, 23.4, 1.9, g + 113.5, g + 114.0, light, M_STONE, light.darkened(0.12))
		_lbox(su * 23.25, 0.0, 0.15, 23.4, g + 114.0, g + 115.1, light, M_STONE, light)
		_lbox(0.0, su * 23.25, 23.4, 0.15, g + 114.0, g + 115.1, light, M_STONE, light)
	# The shaft's top: an attic, big pinnacles on the corner piers, smaller ones between.
	_attic(shaft, g + 139.0, 3.0, light)
	for k in 4:
		var su := -1.0 if k % 2 == 0 else 1.0
		var sv := -1.0 if k < 2 else 1.0
		_pinnacle(su * 18.8, sv * 18.8, 3.4, g + 139.0, 14.0, light)
	for sd in [-1.0, 1.0]:
		_pinnacle(sd * 18.0, 0.0, 2.0, g + 139.0, 8.0, light)
		_pinnacle(0.0, sd * 18.0, 2.0, g + 139.0, 8.0, light)
	# A stepped plinth for the clock tier.
	_prism(_rect(0.0, 0.0, 12.5, 12.5), g + 139.0, g + 143.0, stone, roof, M_STONE, M_STONE)
	_attic(_rect(0.0, 0.0, 12.5, 12.5), g + 143.0, 1.6, light)

	# The clock tier (139-168 m): a dial on every face, an attic and pinnacles on top.
	var clock := _rect(0.0, 0.0, 8.5, 8.5)
	_prism(clock, g + 143.0, g + 168.0, stone, roof, M_MONUMENT, M_STONE)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		_dial(_w(nu * 8.62, nv * 8.62), g + 156.0, Vector2(_a * nu + _b * nv), 3.15)
	_attic(clock, g + 168.0, 2.0, light)
	for k in 4:
		_pinnacle(-7.4 if k % 2 == 0 else 7.4, -7.4 if k < 2 else 7.4, 1.8, g + 168.0, 9.0, light)

	# The lantern (168-188 m): tall dark arches between stone piers.
	var lantern := _rect(0.0, 0.0, 6.3, 6.3)
	_prism(lantern, g + 168.0, g + 188.0, stone, Color(0, 0, 0, 0), M_STONE)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		var n2: Vector2 = _a * nu + _b * nv
		var side := Vector2(-n2.y, n2.x)
		for k in 3:
			var c := _w(nu * 6.36, nv * 6.36) + side * (-3.6 + k * 3.6)
			_mode = M_STONE
			_quad(Vector3(c.x - side.x * 0.8, g + 171.0, c.y - side.y * 0.8), Vector3(c.x + side.x * 0.8, g + 171.0, c.y + side.y * 0.8),
					Vector3(c.x + side.x * 0.8, g + 185.0, c.y + side.y * 0.8), Vector3(c.x - side.x * 0.8, g + 185.0, c.y - side.y * 0.8),
					Vector3(n2.x, 0, n2.y), Color("#3a3640"))
	_attic(lantern, g + 188.0, 1.4, light)

	# The crown: a patina pyramid, then the gilded spire to 237 m.
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 6.0, 6.0), g + 188.0, _rect(0.0, 0.0, 2.4, 2.4), g + 203.0, PATINA)
	# The spire's foot: a dark bronze lantern (Mac photo check 2026-11-01), then the gold spire.
	_prism(_rect(0.0, 0.0, 1.8, 1.8), g + 200.5, g + 208.0, SPIRE_BRONZE, SPIRE_BRONZE, M_STONE, M_STONE)
	_mode = M_GOLD
	_frustum(_rect(0.0, 0.0, 1.6, 1.6), g + 208.0, _rect(0.0, 0.0, 0.9, 0.9), g + 222.0, SPIRE_GOLD)
	_frustum(_rect(0.0, 0.0, 0.9, 0.9), g + 222.0, _rect(0.0, 0.0, 0.15, 0.15), g + 237.0, SPIRE_GOLD)
	# Two rings on the spire.
	_prism(_rect(0.0, 0.0, 1.3, 1.3), g + 214.0, g + 215.0, SPIRE_GOLD, SPIRE_GOLD, M_GOLD, M_GOLD)
	_prism(_rect(0.0, 0.0, 1.0, 1.0), g + 225.0, g + 225.8, SPIRE_GOLD, SPIRE_GOLD, M_GOLD, M_GOLD)
	_palace_venues(g)


## Where the Palace comes from. Since 2026-11-26 (F's flying-boar reel, close-ups round the Palace) the
## default is "blender" (LOD 0): the glb that tools/blender/pkin.py exports ("blender1" is LOD 1).
## "code" is `_build_palace` below, the fallback when the glb is missing. Set by
## main.gd's `--palace=`; the sector bake (tools/bake_city.gd) reads AW_PALACE instead.
static var palace_flag := ""


static func palace_source() -> String:
	if palace_flag != "":
		return palace_flag
	var env := OS.get_environment("AW_PALACE")
	return env if env != "" else "blender"


## The Palace from the Blender model: every triangle of the glb into the city mesh with the
## material code and colour its material name carries (`M<code>_<rrggbb>`), the wall UVs from
## UV, the wall's top from UV2.y, and the glb's own normals (round columns and the drum shade
## smooth). The clocks, the gates, the collision and the venues stay in code. False if the
## file is missing (the code model is built instead).
func _palace_glb(outer: PackedVector2Array, g: float) -> bool:
	var path := "res://models/pkin/pkin_lod%d.glb" % (1 if palace_source() == "blender1" else 0)
	if not ResourceLoader.exists(path):
		push_warning("palace: %s missing, building the code model" % path)
		return false
	var scene: Node = (load(path) as PackedScene).instantiate()
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	for node: Node in meshes:
		var mesh := (node as MeshInstance3D).mesh
		for si in mesh.get_surface_count():
			var mat := mesh.surface_get_material(si)
			var parts := (mat.resource_name if mat else "M3_d8c49c").trim_prefix("M").split("_")
			var mode := float(parts[0])
			var col := Color("#" + parts[1])
			var arr := mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				idx = PackedInt32Array(range(vs.size()))
			_mode = mode
			for t in range(0, idx.size(), 3):
				var p: Array[Vector3] = []
				var n: Array[Vector3] = []
				var u: Array[Vector2] = []
				for k in 3:
					var i := idx[t + k]
					var q := vs[i]
					var w := _w(q.x, q.z)
					p.append(Vector3(w.x, g + q.y, w.y))
					var nq := ns[i]
					var nw := _a * nq.x + _b * nq.z
					n.append(Vector3(nw.x, nq.y, nw.y).normalized())
					# glTF flips V (v' = 1 - v): turn the metres above the ground back.
					u.append(Vector2(-1.0, -1.0) if uv[i].x < 0.0 else Vector2(uv[i].x, 1.0 - uv[i].y))
				var top := 1.0 - uv2[idx[t]].y
				# The projector's terrace height (tools/blender/pkin.py lamp_level) into the vertex
				# alpha, 0.75 + metres / 1024: building.gdshader's floodlight() fades the light up
				# from it. Alpha 1 (every other model) keeps the shader's own falloff.
				col.a = 0.75 + clampf(uv2[idx[t]].x, 0.0, 250.0) / 1024.0
				var fn := (p[1] - p[0]).cross(p[2] - p[0])
				if fn.length_squared() < 1e-10:
					continue
				fn = fn.normalized()
				# The glb's winding is outward: keep the face normal on the side the corners face.
				if fn.dot(n[0] + n[1] + n[2]) < 0.0:
					fn = -fn
				_tri_smooth(p, n, fn, col, u, top)
	scene.free()
	_mode = M_STONE
	# What stays in code: the car's collision, the clocks, the courtyard gates, the venues.
	_collide(outer)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		# The clocks sit over the arcade on the 12.6 m tier (the photos), not under it.
		_dial(_w(nu * 6.42, nv * 6.42), g + 178.0, Vector2(_a * nu + _b * nv), 3.6)
	for gate in P_GATES:
		_palace_gate(float(gate[0]), float(gate[1]), float(gate[2]), float(gate[3]), g, SANDSTONE_LIGHT)
	_palace_name(54.05, g)
	_palace_venues(g)
	return true


## A gate in the Palace's base on the west-facing wall at plane u (the wall faces -u): a dark
## opening of width w and height h at v, under a sandstone surround standing 0.3 m out, closed
## by a steel gate of vertical bars. Opaque boxes only (M_STONE, no new material).
func _palace_gate(u: float, v: float, w: float, h: float, g: float, light: Color) -> void:
	var hw := w * 0.5
	# the opening: dark, just in front of the wall so it does not fight the facade
	var a := _w(u - 0.05, v - hw)
	var b := _w(u - 0.05, v + hw)
	_mode = M_STONE
	_wall(a, b, g - 0.4, g + h, -_a, P_GATE_DARK)
	# the surround: two jambs and a lintel with a keystone
	_lbox(u - 0.15, v - hw - 0.35, 0.15, 0.35, g - 0.4, g + h, light, M_STONE)
	_lbox(u - 0.15, v + hw + 0.35, 0.15, 0.35, g - 0.4, g + h, light, M_STONE)
	_lbox(u - 0.18, v, 0.18, hw + 0.7, g + h, g + h + 0.8, light, M_STONE)
	_lbox(u - 0.24, v, 0.24, 0.45, g + h - 0.3, g + h + 0.95, light, M_STONE)
	# the steel gate: a top and a bottom rail, bars about every 0.3 m
	_lbox(u - 0.12, v, 0.04, hw, g + 0.15, g + 0.3, P_GATE_STEEL, M_STONE)
	_lbox(u - 0.12, v, 0.04, hw, g + h - 0.45, g + h - 0.3, P_GATE_STEEL, M_STONE)
	var n := int(w / 0.3)
	for k in n + 1:
		var bv := v - hw + 0.15 + (w - 0.3) * float(k) / float(n)
		_lbox(u - 0.12, bv, 0.03, 0.03, g, g + h - 0.3, P_GATE_STEEL, M_STONE)


# --- The Palace's venues (F, 2026-11-07: "add the entertainment the Palace has, Bar Studio and the others")

## The Palace's frame as _palace_frame's fallback measures it, for the static plans crowds.gd
## reads (the model and the crowd must agree without a built map).
const PKIN_O := Vector2(-1214.25, 247.3)
const PKIN_A := Vector2(0.9403, -0.3404)
const PKIN_B := Vector2(0.3404, 0.9403)
## The venues' lit names on the faces the camera sees (+v, BEHIND_FACE), over their real doors
## (OSM's amenity points, docs/inventory/osm_candidates.json): [lines, u, v (the face), y0, y1
## over the ground, most width, tube]. Kinoteka over the south block's door, the bar Kulturalna
## beside it, Teatr Dramatyczny on the south-east pavilion's end, Muzeum Techniki on the
## south-west one's, Sala Kongresowa on the hall's south front over the base's roof and the
## 30th-floor terrace's name under its ledge (Teatr Studio's name is cut in its portico, below). Real names: they are public stages and museums (place names).
const PKIN_SIGNS := [
	[["KINOTEKA"], 0.0, 69.25, 7.0, 10.0, 12.5, Color(1.0, 0.72, 0.25)],
	[["KULTURALNA"], 14.7, 60.25, 3.6, 5.0, 4.6, Color(1.0, 0.45, 0.35)],
	[["TEATR", "DRAMATYCZNY"], 68.2, 132.45, 15.5, 21.0, 12.5, Color(1.0, 0.9, 0.7)],
	[["MUZEUM", "TECHNIKI"], -66.0, 132.55, 15.5, 21.0, 11.5, Color(0.75, 0.9, 1.0)],
	[["SALA", "KONGRESOWA"], -72.6, 33.45, 18.4, 22.3, 14.0, Color(1.0, 0.86, 0.55)],
	[["TARAS", "30 PIĘTRO"], 0.0, 21.75, 103.5, 110.5, 18.0, Color(1.0, 0.86, 0.55)],
]
## Teatr Studio's portico and Bar Studio (F's photos 2026-11-07: the portico by day and at dusk,
## the bar in the colonnade, the forecourt's corten planters). The portico fills the recess in
## the north-east wing's east front (u 84.2 back wall, the bays' fronts at u 89.3, v -110.9 to
## -79.1): six columns on a platform with four steps down to the square, the entablature with
## TEATR STUDIO cut in it, THE FUTURE SHOULD ALWAYS BE BETTER in neon on the band over it,
## pale-blue poster banners in the middle bays and orange ones in the outer two, warm lights
## strung between the columns, the bar's glazed doors lit at the back. Bar Studio's tables
## stand in the colonnade and under pale-blue umbrellas on the square at the steps' foot, with
## potted palms between them and the lit BAR letters on the north cheek of the steps.
const PKIN_PORT_U := Vector2(84.2, 89.3)
const PKIN_PORT_V := Vector2(-110.9, -79.1)
const PKIN_COL_U := 87.9
const PKIN_COL_R := 0.8
const PKIN_PLATFORM := 0.9
const PKIN_STEP_DEEP := 0.5
const PKIN_UMBRELLA := Color("#9db3bd")
const PKIN_BANNERS := [Color("#d0613a"), Color("#b9cfd6"), Color("#a7bfcb"), Color("#b9cfd6"), Color("#d0613a")]
## The umbrella tables on the square: [u, v] in two rows at the steps' foot.
const PKIN_UMBRELLAS := [[94.6, -106.0], [94.6, -100.0], [94.6, -94.0], [94.6, -88.0], [94.6, -82.0],
		[99.6, -103.0], [99.6, -97.0], [99.6, -91.0], [99.6, -85.0]]
const PKIN_PALMS := [[92.3, -103.0], [92.3, -97.0], [92.3, -91.0], [92.3, -85.0], [92.3, -109.0], [92.3, -80.5]]
## Plac Nowego Sąsiedztwa's corten planters (Teatr Studio's square, 2024): [u, v, kind] on the
## forecourt beyond the tables; kind 0 a round-crowned tree, 1 a spiral topiary. Wooden bench
## tops on their west and south sides.
const PKIN_PLANTERS := [[107.0, -107.0, 0], [107.0, -93.0, 1], [107.0, -79.0, 0], [115.0, -100.0, 0],
		[115.0, -86.0, 0], [123.0, -107.0, 1], [123.0, -79.0, 0]]
const PKIN_CORTEN := Color("#8b4a26")
const PKIN_WOOD := Color("#b98552")
## "Zieleń nad betonem" (Teatr Studio, 2022): the 40 m² bed cut into the slab, a ginkgo in the
## middle among sage, verbena, cranesbill, coneflowers and white anemones. [u0, v0, u1, v1].
const PKIN_BED := [112.0, -71.0, 120.0, -66.0]


## The columns' v, evenly across the recess.
static func pkin_columns() -> Array:
	var out: Array = []
	for i in 6:
		out.append(lerpf(PKIN_PORT_V.x + 2.6, PKIN_PORT_V.y - 2.6, i / 5.0))
	return out


## Bar Studio's plan (model and crowds.gd): umbrella tables [p, yaw] (yaw for _umbrella, its
## square on the Palace's grid) and seats [p, sitter's yaw], two per table facing it.
static func pkin_studio_plan() -> Dictionary:
	var tables: Array = []
	var seats: Array = []
	var yaw := atan2(PKIN_A.x, PKIN_A.y)
	var mid := Vector2.ZERO
	for t: Array in PKIN_UMBRELLAS:
		var p := PKIN_O + PKIN_A * float(t[0]) + PKIN_B * float(t[1])
		tables.append([p, yaw])
		seats.append([p + PKIN_B * 0.8, atan2(PKIN_B.x, PKIN_B.y)])
		seats.append([p - PKIN_B * 0.8, atan2(-PKIN_B.x, -PKIN_B.y)])
		mid += p
	return {"tables": tables, "seats": seats, "centre": mid / float(PKIN_UMBRELLAS.size())}


## Where the evening audiences gather (crowds.gd THEATRES reads it): before the doors of Teatr
## Dramatyczny, Teatr Studio (on the square past Bar Studio's tables), the Kinoteka and Sala
## Kongresowa, 2-4 m out of their faces.
static func pkin_theatre_doors() -> Dictionary:
	return {
		"theatre_dramatyczny": PKIN_O + PKIN_A * 68.0 + PKIN_B * 136.0,
		"theatre_studio": PKIN_O + PKIN_A * 103.5 + PKIN_B * -95.0,
		"theatre_kinoteka": PKIN_O + PKIN_A * 0.0 + PKIN_B * 73.0,
		"theatre_kongresowa": PKIN_O + PKIN_A * -72.0 + PKIN_B * 37.0,
	}


## PAŁAC KULTURY I NAUKI in red neon on the main portico's entablature (F's photos, 2026-11-13:
## red tubes over the columns on Marszałkowska, lit at night), on its +u face at u.
func _palace_name(u: float, g: float) -> void:
	_pkin_row(["PAŁAC", "KULTURY", "I", "NAUKI"], u, 0.0, g + 13.75, 1.7, 1.4, Color(1.0, 0.16, 0.12))


func _palace_venues(g: float) -> void:
	for s: Array in PKIN_SIGNS:
		var at := _w(float(s[1]), float(s[2]))
		_dtc_words(s[0], at, _b, g + float(s[3]), g + float(s[4]), float(s[5]), 4.0, s[6])
	_pkin_portico(g)
	_pkin_bar()
	_pkin_square()


func _pkin_portico(g: float) -> void:
	var u0 := PKIN_PORT_U.x
	var u1 := PKIN_PORT_U.y
	var v0 := PKIN_PORT_V.x
	var v1 := PKIN_PORT_V.y
	var vc := (v0 + v1) * 0.5
	var hv := (v1 - v0) * 0.5
	var front := _w(u1, vc)
	var gp: float = map.terrain_height(front.x, front.y)
	var top := gp + PKIN_PLATFORM
	_mode = M_STONE
	# The platform and the four steps down to the square.
	_prism(_rect((u0 + u1) * 0.5, vc, (u1 - u0) * 0.5, hv), gp - 0.3, top, SANDSTONE.darkened(0.05), SANDSTONE_LIGHT, M_STONE, M_STONE)
	for k in 4:
		var su := u1 + PKIN_STEP_DEEP * (k + 0.5)
		var sy := top - PKIN_PLATFORM * (k + 1) / 5.0
		_prism(_rect(su, vc, PKIN_STEP_DEEP * 0.5, hv), gp - 0.3, sy, SANDSTONE.darkened(0.08), SANDSTONE_LIGHT.darkened(0.03), M_STONE, M_STONE)
	# The cheeks at the steps' ends (BAR stands on the north one).
	var cheek_u := u1 + PKIN_STEP_DEEP * 2.0
	for cv: float in [v0 - 1.0, v1 + 1.0]:
		_prism(_rect(cheek_u, cv, PKIN_STEP_DEEP * 2.0 + 0.1, 1.0), gp - 0.3, top + 0.2, SANDSTONE.darkened(0.06), SANDSTONE_LIGHT, M_STONE, M_STONE)
	_collide(_rect((u0 + u1 + PKIN_STEP_DEEP * 4.0) * 0.5, vc, (u1 - u0 + PKIN_STEP_DEEP * 4.0) * 0.5, hv + 2.0))
	# The bar's doors at the back of the colonnade: a tall lit door on the axis, two lower beside it.
	_mode = M_PAVILION
	for d: Array in [[vc, 2.0, 5.2], [vc - 6.6, 1.5, 4.2], [vc + 6.6, 1.5, 4.2]]:
		_wall(_w(u0 + 0.05, float(d[0]) - float(d[1])), _w(u0 + 0.05, float(d[0]) + float(d[1])), top, top + float(d[2]), _a, Color("#c9a35f"))
	_mode = M_STONE
	# The columns, and the entablature over them to the base's top.
	var cols := pkin_columns()
	for cv: float in cols:
		_column(PKIN_COL_U, cv, PKIN_COL_R, top, g + 11.8, SANDSTONE_LIGHT)
	_prism(_rect((u0 + u1) * 0.5, vc, (u1 - u0) * 0.5, hv), g + 11.8, g + 18.0, SANDSTONE_LIGHT, SANDSTONE.darkened(0.12), M_STONE, M_STONE)
	_prism(_rect((u0 + u1 + 0.6) * 0.5, vc, (u1 - u0 + 0.6) * 0.5, hv), g + 14.6, g + 15.0, SANDSTONE_LIGHT.lightened(0.05), SANDSTONE_LIGHT, M_STONE, M_STONE)
	# The banners between the columns, a little behind their faces.
	for i in 5:
		var a: float = cols[i] + PKIN_COL_R + 0.3
		var b: float = cols[i + 1] - PKIN_COL_R - 0.3
		var w := (b - a) if i in [1, 2, 3] else 1.2
		var mv := (a + b) * 0.5
		var p0 := _w(PKIN_COL_U - 0.1, mv - w * 0.5)
		var p1 := _w(PKIN_COL_U - 0.1, mv + w * 0.5)
		var y0 := top + (2.6 if i in [1, 2, 3] else 3.2)
		var y1 := top + 8.6
		_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y), Vector3(_a.x, 0, _a.y), PKIN_BANNERS[i])
	# Warm lights strung between the columns' fronts.
	for i in 5:
		var a := _w(PKIN_COL_U + PKIN_COL_R, cols[i])
		var b := _w(PKIN_COL_U + PKIN_COL_R, cols[i + 1])
		_pow_festoon(Vector3(a.x, top + 2.6, a.y), Vector3(b.x, top + 2.6, b.y), 0.35, 6)
	# The lettering: TEATR STUDIO cut in the entablature, lit warm white at night; the neon line
	# on the band over the cornice, in its four pieces left to right (towards -v).
	var face := u1 + 0.05
	_pkin_row(["TEATR", "STUDIO"], face, vc, g + 12.6, 1.5, 2.5, Color(1.0, 0.95, 0.85))
	_pkin_row(["THE FUTURE", "SHOULD", "ALWAYS BE", "BETTER"], face, vc, g + 15.6, 0.95, 0.6, Color(0.8, 0.95, 1.0))


## A row of lit words on a +u face at u, centred on v = vc, bottom y, letters `tall` metres high,
## `gap` between them; read left to right as someone facing the face sees it (towards -v).
func _pkin_row(words: Array, u: float, vc: float, y: float, tall: float, gap: float, ink: Color) -> void:
	var k := tall / (Neon.ROW_H * Neon.PIXEL)
	var total := -gap
	for wd: String in words:
		total += Neon.length_of(wd) * k + gap
	var v := vc + total * 0.5
	for wd: String in words:
		var wl := Neon.length_of(wd) * k
		var at := _w(u, v - wl * 0.5)
		signs.append([wd, Vector3(at.x, y, at.y), Vector3(_a.x, 0.0, _a.y), k, ink])
		v -= wl + gap


## Bar Studio: bistro tables in the colonnade, the umbrella tables and palms on the square, the
## lit BAR letters on the steps' north cheek.
func _pkin_bar() -> void:
	var front := _w(PKIN_PORT_U.y, (PKIN_PORT_V.x + PKIN_PORT_V.y) * 0.5)
	var gp: float = map.terrain_height(front.x, front.y)
	var top := gp + PKIN_PLATFORM
	var cols := pkin_columns()
	_mode = M_STONE
	for i in 5:
		var mv: float = (cols[i] + cols[i + 1]) * 0.5
		for tu: float in [85.6, 87.4]:
			_lbox(tu, mv, 0.04, 0.04, top, top + 0.74, POW_DARK, M_STONE)
			_lbox(tu, mv, 0.36, 0.36, top + 0.72, top + 0.76, RYNEK_TABLE, M_STONE)
			for s: float in [-0.75, 0.75]:
				_lbox(tu, mv + s, 0.2, 0.2, top, top + 0.45, POW_DARK, M_STONE)
	# BAR on the north cheek, facing the square.
	var cheek := _w(PKIN_PORT_U.y + PKIN_STEP_DEEP * 2.0, PKIN_PORT_V.x - 1.0)
	_dtc_words(["BAR"], cheek + _a * (PKIN_STEP_DEEP * 2.0 + 0.15), _a, top + 0.25, top + 1.5, 2.6, 1.2, Color(1.0, 0.93, 0.78))
	# The palms in tubs.
	for pl: Array in PKIN_PALMS:
		var p := _w(float(pl[0]), float(pl[1]))
		var y: float = map.terrain_height(p.x, p.y)
		_prism(_square(p, 0.38), y, y + 0.65, Color("#3b3d40"), Color("#4a3a2c"), M_STONE, M_STONE)
		var crown := Vector3(p.x, y + 2.7, p.y)
		_beam(Vector3(p.x, y + 0.6, p.y), crown, 0.16, Color("#7a6248"))
		for f in 7:
			var t := TAU * f / 7.0 + float(pl[1]) * 0.37
			var tip := crown + Vector3(cos(t) * 1.3, -0.55, sin(t) * 1.3)
			_beam(crown, tip, 0.34, Color("#4f7a3a").lightened(0.06 * (f % 3)))
	# The umbrella tables (_umbrella moves the frame: put the Palace's back after).
	var plan := pkin_studio_plan()
	for t: Array in plan["tables"]:
		var p: Vector2 = t[0]
		_umbrella(p, float(t[1]), map.terrain_height(p.x, p.y), PKIN_UMBRELLA)
	_palace_frame()


## The forecourt's furniture: Plac Nowego Sąsiedztwa's corten planters with bench tops and their
## trees, the ginkgo's flower bed.
func _pkin_square() -> void:
	_mode = M_STONE
	for pl: Array in PKIN_PLANTERS:
		var cu := float(pl[0])
		var cv := float(pl[1])
		var c := _w(cu, cv)
		var y: float = map.terrain_height(c.x, c.y)
		_lbox(cu, cv, 1.2, 1.2, y - 0.2, y + 0.9, PKIN_CORTEN, M_STONE, Color("#4a3a2c"))
		_lbox(cu - 1.5, cv, 0.3, 1.2, y - 0.2, y + 0.46, PKIN_WOOD, M_STONE)
		_lbox(cu, cv + 1.5, 1.5, 0.3, y - 0.2, y + 0.46, PKIN_WOOD, M_STONE)
		_collide(_rect(cu - 0.15, cv + 0.15, 1.5, 1.5))
		if int(pl[2]) == 1:
			# A spiral topiary: stacked collars narrowing to the top.
			for k in 6:
				var r := 0.75 - 0.1 * k
				_frustum(_circle(c, r * 0.6, 6), y + 0.9 + 0.42 * k, _circle(c, r, 6), y + 1.1 + 0.42 * k, Color("#4e7a36"))
				_frustum(_circle(c, r, 6), y + 1.1 + 0.42 * k, _circle(c, r * 0.6, 6), y + 1.32 + 0.42 * k, Color("#5d8c40"))
		else:
			_prism(_square(c, 0.09), y + 0.9, y + 3.0, Color("#5a4636"), Color(0, 0, 0, 0), M_STONE)
			_frustum(_circle(c, 0.5, 7), y + 2.7, _circle(c, 1.35, 7), y + 3.4, Color("#55853a"))
			_frustum(_circle(c, 1.35, 7), y + 3.4, _circle(c, 0.45, 7), y + 4.3, Color("#62943f"), Color("#6ea047"))
	# The flower bed: a granite kerb, dark soil, clumps in purple, blue, red and white, the ginkgo.
	var b: Array = PKIN_BED
	var bc := _w((b[0] + b[2]) * 0.5, (b[1] + b[3]) * 0.5)
	var by: float = map.terrain_height(bc.x, bc.y)
	_lbox((b[0] + b[2]) * 0.5, (b[1] + b[3]) * 0.5, (b[2] - b[0]) * 0.5, (b[3] - b[1]) * 0.5, by - 0.2, by + 0.22, Color("#a8a49c"), M_STONE, Color("#3d3128"))
	var tones := [Color("#7a5aa6"), Color("#5a6fb0"), Color("#b0403a"), Color("#e8e6e0"), Color("#4e7a3a"), Color("#8a62b0")]
	var n := 0
	var u := float(b[0]) + 0.8
	while u < float(b[2]) - 0.5:
		var v := float(b[1]) + 0.7
		while v < float(b[3]) - 0.4:
			var q := _w(u + 0.3 * sin(v * 3.1), v)
			var r := 0.45 + 0.12 * ((n * 7) % 3)
			_frustum(_circle(q, r, 6), by + 0.22, _circle(q, r * 0.5, 6), by + 0.75 + 0.1 * (n % 3), tones[n % tones.size()])
			n += 1
			v += 1.3
		u += 1.5
	_prism(_square(bc, 0.12), by + 0.22, by + 2.2, Color("#5a4636"), Color(0, 0, 0, 0), M_STONE)
	_frustum(_circle(bc, 0.9, 7), by + 1.8, _circle(bc, 0.2, 7), by + 5.4, Color("#9bbb4a"))
	_collide(_rect((b[0] + b[2]) * 0.5, (b[1] + b[3]) * 0.5, (b[2] - b[0]) * 0.5, (b[3] - b[1]) * 0.5))


# --- Złote Tarasy -----------------------------------------------------------------------------

## Złote Tarasy (Jerde Partnership, 2007), rebuilt 2026-10-31 to its spec
## docs/landmarks/specs/tarasy.md from the complex's OpenStreetMap parts: the glass wave over
## the mall, the mall's terraced sandstone podium under it, the Lumen office crescent wrapping
## it on Złota and Jana Pawła II, the Skylight tower on Emilii Plater with its lit glass crown,
## the round glass drum on the station side. Every part keeps its mapped outline and heights;
## what the part is decides its look (TARASY_*).
const TARASY_SAND := Color("#d9c7a0")      # the podium's sandstone walls
const TARASY_SHOP := Color("#c8b27e")      # the podium's golden shop glass (S_GRID)
const TARASY_TERRACE := Color("#8a9a72")   # the planted terraces (mapped #6EBE9F)
const TARASY_DECK := Color("#a49d90")      # the podium's plain roofs
const TARASY_LUMEN := Color("#7ea3c0")     # Lumen's blue glass between white ribbons (F's photos 2026-11-11)
const TARASY_LUMEN_ROOF := Color("#8e9497")
const TARASY_SKY := Color("#a3afb4")       # Skylight's light silver-grey cladding (Mac photos), a dark-teal window dash per floor
const TARASY_SKY_ROOF := Color("#a7b3b8")
const TARASY_CROWN := Color("#b9d2dc")     # Skylight's glass crown, lit cool white at night
const TARASY_DRUM := Color("#c9b98f")      # the drum: golden glass lit warm
const TARASY_BLOCK := Color("#3b3e4b")     # the screen block over the entrance: dark graphite
const TARASY_RED := Color("#c0624c")       # the red entrance boxes on Jana Pawła II (mapped tomato)
const TARASY_RIM := Color("#8ea6bd")       # the wave's glass walls: the terraces' shopfronts (blue-grey glass)
const TARASY_WAVE := Color("#4a74a6")      # F 2026-11-11: blue glass (was #d4b066 gold, #8fb6c6 ice before)
const TARASY_DRUM_GLASS := Color("#7f9fb4")  # the drum's banded glass (F's photos, 2026-11-11)
## How far Skylight's crown leans in (fraction of the way to the centre) and how high it is.
const TARASY_CROWN_IN := 0.18
const TARASY_CROWN_H := 8.0


func _tarasy_dome(b: Dictionary) -> bool:
	return str(b["c"]).to_lower() == "#336699" and float(b["h"]) >= 20.0


## The mapped plate over the entrance (17 to 27 m, 19 points, Skylight's colour): the screen's block.
func _tarasy_screen_block(b: Dictionary) -> bool:
	return str(b.get("name", "")) == "" and str(b["c"]).to_lower() == "#bac1c7" and is_equal_approx(float(b["mh"]), 17.0) \
			and is_equal_approx(float(b["h"]), 27.0) and (b["p"] as Array).size() == 38


func _build_tarasy(site: Dictionary) -> void:
	# The street's level round the complex (the median under its outline, about 14.5 m), not its
	# lowest point: that is a dip by the car park ramp 3 m lower, which sank every mapped height
	# (the podium read 13.6 m, the café's sign hung at knee height; F's photos, 2026-11-11).
	_g = _median_ground(site["zone"][0])
	var g := _g
	var none := Color(0, 0, 0, 0)
	var podium: Array = []
	var t26 := {"lumen": [], "plate": PackedVector2Array(), "hall": PackedVector2Array(), "teal": PackedVector2Array(),
			"lift": PackedVector2Array()}
	for b: Dictionary in site.get("parts", []):
		if _tarasy_dome(b):
			continue
		var poly := _pts(b["p"])
		if poly.size() < 3:
			continue
		var h := float(b["h"])
		var mh := float(b["mh"])
		var y0 := _ground_under(poly) - 0.4 if mh < 0.5 else g + mh
		var y1 := g + h
		var nm := str(b.get("name", ""))
		var col := str(b["c"]).to_lower()
		if _tarasy_screen_block(b):
			# The grey box over the podium (F's photos 2026-11-11, refs/skylight 06): Skylight's
			# cladding from 17 to the mapped 27 m, a planted roof, the mall's gold name on its south
			# face. The 3D screen is not on it: it wraps Skylight's south-east corner (tarasy_screen.gd).
			_prism(poly, y0, y1, SKY_CLAD, TARASY_TERRACE, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
		elif nm == "Lumen":
			_tarasy_lumen(poly, y0, y1)
			(t26["lumen"] as Array).append(poly)
		elif nm == "Skylight":
			_tarasy_skylight(poly, y0, g)
		elif col == "#336699":
			# The glass floor under the wave's low south sweep: the wave carried down to the plaza.
			_prism(poly, y0, y1, TARASY_RIM, TARASY_WAVE, M_PAVILION, M_GLASS_ROOF)
		elif h >= 29.5 and h - mh < 1.0:
			_prism(poly, y0, y1, TARASY_SAND, TARASY_SAND.darkened(0.08), M_STONE, M_STONE)  # the drum's rim
		elif h >= 29.5 and mh < 0.5 and poly.size() >= 16:
			# The drum (F's photos: round blue-grey glass, warm from inside at night).
			_prism(poly, y0, y1, TARASY_DRUM_GLASS, TARASY_DECK, M_PAVILION, M_STONE)
			_t26_drum_crown(g)
		elif col == "#669999" and is_equal_approx(mh, 14.0):
			_t26_south_band(poly, y0, y1, g)
			podium.append([poly, y0, y1])
		elif col == "#dddddd" and is_equal_approx(mh, 35.0):
			_t26_egg(g)
		elif col == "tomato":
			_prism(poly, y0, y1, TARASY_RED, TARASY_RED.darkened(0.15), M_STONE, M_STONE)
		elif col == "#6ebe9f" and mh >= 34.5:
			_t26_teal_box(poly, y0, y1)
			t26["teal"] = poly
			podium.append([poly, y0, y1])
		elif col == "#6ebe9f" and mh < 0.5 and poly.size() == 23:
			_t26_wing(poly, y0, y1)
			podium.append([poly, y0, y1])
		elif col == "#6ebe9f":
			_tarasy_podium(poly, y0, y1, g, TARASY_TERRACE, true)
			podium.append([poly, y0, y1])
		else:
			var roof := TARASY_DECK
			if col == "#bac1c7" and is_equal_approx(mh, 14.0) and is_equal_approx(h, 35.0):
				roof = T26_ROOF   # the hall's roof: dark membrane
				t26["hall"] = poly
			elif col == "#bac1c7" and is_equal_approx(mh, 35.0) and is_equal_approx(h, 36.0):
				roof = T26_ROOF
				t26["plate"] = poly
			elif col == "#bac1c7" and is_equal_approx(mh, 14.0) and is_equal_approx(h, 28.0):
				t26["lift"] = poly
			_tarasy_podium(poly, y0, y1, g, roof, false)
			podium.append([poly, y0, y1])
		if mh < 0.5:
			_collide(poly)
	_tarasy_ledges(podium, g)
	_tarasy_shops(g)
	_tarasy_wave(site)
	_tarasy_signs(g)
	_tarasy_guitar(g)
	_tarasy_cafe(g)
	_t26_extras(g, podium, t26)
	_mode = M_STONE


## The mall's podium, part by part (F's photos, 2026-11-11: "redesign all the complex"): a glazed
## shop floor at the street (dark glass, the shops lit warm at night), sandstone above it, and the
## planted terraces fenced with a glass balustrade. The ledges that make it read as stacked terraces
## run round the podium's whole outline (_tarasy_ledges), not part by part.
const TARASY_SHOPFRONT := Color("#5f7178")   # the shop floor's glass
const TARASY_SHOP_H := 4.6                   # its height (the canopy's line)
const TARASY_STONE := Color("#dccaa2")       # the sandstone over it
const TARASY_LEDGE := Color("#ece0c4")       # the ledges' pale top
const TARASY_CANOPY := Color("#4d4f55")      # the canopy over the shops
const TARASY_RAIL := Color("#bcd3dd")        # the terraces' glass balustrade


## The podium: glass shops at street level, then the stone terraces with their window bands (re-clad
## cladding skin: pale bands with punched windows, so the mass is lit at night, not a dark block).
func _tarasy_podium(poly: PackedVector2Array, y0: float, y1: float, g: float, roof: Color, planted: bool) -> void:
	var none := Color(0, 0, 0, 0)
	var shop_top := _mean_ground(poly) + TARASY_SHOP_H
	if y0 < shop_top - 0.5 and y1 > shop_top + 0.5:
		_prism(poly, y0, shop_top, TARASY_SHOPFRONT, none, M_PAVILION, M_STONE)
		_prism(poly, shop_top, y1, TARASY_STONE, roof, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
	else:
		_prism(poly, y0, y1, TARASY_STONE, roof, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
	if planted:
		_prism(poly, y1, y1 + 1.1, TARASY_RAIL, none, M_PAVILION + 0.5, M_STONE)


## The ledges round the podium (F's photos: the terraces stack in pale stone bands, the shops under
## a dark canopy whose front is a strip of light at night): at each level, the outline of every
## podium part that spans it, merged, gets a slab pushed out from its walls (top and front, the
## camera never sees under). TARASY_LEDGES: height over the ground, depth, thickness; the first is
## the canopy.
const TARASY_LEDGES := [[TARASY_SHOP_H, 1.5, 0.45], [9.8, 0.6, 0.3], [15.9, 0.7, 0.35]]


func _tarasy_ledges(podium: Array, g: float) -> void:
	for i in TARASY_LEDGES.size():
		var lv: Array = TARASY_LEDGES[i]
		# The canopy and the middle ledge stand on the street (the site's ground `g` is its lowest
		# point, in a dip by the car park ramp); the cornice keeps with the mapped tops (g + h).
		var y := g + float(lv[0])
		var outline: Array = []
		for part: Array in podium:
			var py := y if i == TARASY_LEDGES.size() - 1 else _mean_ground(part[0]) + float(lv[0])
			if float(part[1]) < py - 0.3 and float(part[2]) > py + 0.3:
				outline = _merge_into(outline, part[0])
		for ring: PackedVector2Array in outline:
			if i < TARASY_LEDGES.size() - 1:
				y = _mean_ground(ring) + float(lv[0])
			if i == 0:
				_tarasy_ledge(ring, y, float(lv[1]), float(lv[2]), TARASY_CANOPY, Color("#f6e7c2"), M_LAMP)
			else:
				_tarasy_ledge(ring, y, float(lv[1]), float(lv[2]), TARASY_LEDGE, TARASY_STONE.darkened(0.1), M_STONE)


## The median ground height under a plan outline's corners.
func _median_ground(poly: PackedVector2Array) -> float:
	var hs: Array[float] = []
	for q in poly:
		hs.append(map.terrain_height(q.x, q.y))
	if hs.is_empty():
		return 0.0
	hs.sort()
	return hs[hs.size() / 2]


## A list of plan polygons with one more merged in: outlines only (holes dropped).
func _merge_into(list: Array, poly: PackedVector2Array) -> Array:
	var cur := poly
	var keep: Array = []
	for q: PackedVector2Array in list:
		var m := Geometry2D.merge_polygons(cur, q)
		var outer: Array = []
		for r: PackedVector2Array in m:
			if not Geometry2D.is_polygon_clockwise(r):
				outer.append(r)
		if outer.size() == 1:
			cur = outer[0]
		else:
			keep.append(q)
	keep.append(cur)
	return keep


## A slab round a plan outline at height y: `w` out from the walls, `t` thick; its top in `top`,
## its front in `front` drawn with `front_mode`.
func _tarasy_ledge(ring_in: PackedVector2Array, y: float, w: float, t: float, top: Color, front: Color, front_mode: float) -> void:
	# Drop the outline's short steps and straight-through points first: a slab wider than an edge
	# folds over itself at a mitre.
	var ring := PackedVector2Array()
	for q in ring_in:
		if ring.is_empty() or ring[ring.size() - 1].distance_to(q) >= maxf(2.0, w * 1.6):
			ring.append(q)
	while ring.size() > 3 and ring[0].distance_to(ring[ring.size() - 1]) < maxf(2.0, w * 1.6):
		ring.remove_at(ring.size() - 1)
	var k0 := 0
	while k0 < ring.size() and ring.size() > 3:
		var a0 := ring[(k0 + ring.size() - 1) % ring.size()]
		var b0 := ring[(k0 + 1) % ring.size()]
		if absf((ring[k0] - a0).normalized().cross((b0 - ring[k0]).normalized())) < 0.07 \
				and (ring[k0] - a0).dot(b0 - ring[k0]) > 0.0:
			ring.remove_at(k0)
		else:
			k0 += 1
	var n := ring.size()
	if n < 3:
		return
	var area := 0.0
	for k in n:
		area += ring[k].x * ring[(k + 1) % n].y - ring[(k + 1) % n].x * ring[k].y
	var sgn := 1.0 if area > 0.0 else -1.0
	var outs: Array[Vector2] = []
	for k in n:
		var dp := (ring[k] - ring[(k + n - 1) % n]).normalized()
		var dn := (ring[(k + 1) % n] - ring[k]).normalized()
		var np := Vector2(dp.y, -dp.x) * sgn
		var nn := Vector2(dn.y, -dn.x) * sgn
		var m := (np + nn).normalized()
		outs.append(ring[k] + m * w / maxf(m.dot(nn), 0.5))
	var keep := _mode
	for k in n:
		var a := ring[k]
		var b := ring[(k + 1) % n]
		if a.distance_to(b) < 0.3:
			continue
		var oa: Vector2 = outs[k]
		var ob: Vector2 = outs[(k + 1) % n]
		var d := (b - a).normalized()
		var nrm := Vector3(d.y, 0.0, -d.x) * sgn
		_mode = M_STONE
		_quad(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(ob.x, y, ob.y), Vector3(oa.x, y, oa.y), Vector3.UP, top)
		_mode = front_mode
		_quad(Vector3(oa.x, y, oa.y), Vector3(ob.x, y, ob.y), Vector3(ob.x, y - t, ob.y), Vector3(oa.x, y - t, oa.y), nrm, front)
	_mode = keep


## Lumen (F's photos, 2026-11-11): the curved office wings over the podium in blue glass between
## white ribbons, the top floor set back behind a white parapet, a plant screen on the roof.
func _tarasy_lumen(poly: PackedVector2Array, y0: float, y1: float) -> void:
	var none := Color(0, 0, 0, 0)
	var ribbon := M_SKIN + float(S_RIBBON) / 16.0
	var top := y1 - 3.6
	_prism(poly, y0, top, TARASY_LUMEN, TARASY_LUMEN_ROOF, ribbon, M_STONE)
	_prism(poly, top, top + 1.0, Color("#eef1f2"), none, M_STONE, M_STONE)
	var inset := _largest(Geometry2D.offset_polygon(poly, -2.2, Geometry2D.JOIN_MITER))
	if inset.size() >= 3:
		_prism(inset, top, y1, TARASY_LUMEN.darkened(0.12), TARASY_LUMEN_ROOF, ribbon, M_STONE)
		var plant := _largest(Geometry2D.offset_polygon(inset, -6.0, Geometry2D.JOIN_MITER))
		if plant.size() >= 3:
			_prism(plant, y1, y1 + 2.2, Color("#a9adb0"), Color("#8e9497"), M_STONE, M_STONE)


## The shops' parody signs and the lit advert boards on the podium (F's photos, 2026-11-11):
## the fashion corner on Emilii Plater by the guitar (the plague for the Spanish chain, dotted
## letters and an extra M for the Swedish one), the cinema's pink name on the station side, and a
## big red sale board over the entrance on Złota. Words in neon_signs.gd LANDMARK_WORDS. TARASY_BOARDS: centre, facing, width, height
## (bottom over the ground), colour; lit at night.
const TARASY_BOARDS := [
	[Vector2(-1363.6, 444.6), Vector2(0.94, -0.34), 8.0, 3.0, 5.9, Color("#1d1d1f")],
	[Vector2(-1360.7, 452.4), Vector2(0.94, -0.34), 5.0, 2.4, 5.6, Color("#c8102e")],
	[Vector2(-1467.0, 521.8), Vector2(0.33, 0.95), 11.0, 2.6, 5.8, Color("#c2185b")],
	[Vector2(-1449.8, 347.8), Vector2(-0.33, -0.94), 13.0, 2.8, 5.8, Color("#d32f2f")],
]


func _tarasy_shops(g: float) -> void:
	_mode = M_LAMP
	for bd: Array in TARASY_BOARDS:
		var c: Vector2 = bd[0]
		var n: Vector2 = (bd[1] as Vector2).normalized()
		var side := Vector2(-n.y, n.x)
		var w := float(bd[2]) * 0.5
		var y0: float = map.terrain_height(c.x, c.y) + float(bd[4])
		var y1: float = y0 + float(bd[3])
		var o := c + n * 0.25
		var a := o - side * w
		var b := o + side * w
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), Vector3(n.x, 0, n.y), bd[5])
	_mode = M_STONE
	for sg: Array in [["ZARAZA", Vector2(-1363.6, 444.6), Vector2(0.94, -0.34), 6.4, 0.9],
			["H·M·M", Vector2(-1360.7, 452.4), Vector2(0.94, -0.34), 5.9, 0.75],
			["MULTIKINKO", Vector2(-1467.0, 521.8), Vector2(0.33, 0.95), 6.1, 0.8],
			["WYPRZEDAŻ", Vector2(-1449.8, 347.8), Vector2(-0.33, -0.94), 6.1, 0.95]]:
		var at: Vector2 = sg[1]
		var nn: Vector2 = sg[2]
		signs.append([sg[0], Vector3(at.x, map.terrain_height(at.x, at.y) + float(sg[3]), at.y), Vector3(nn.x, 0.0, nn.y), sg[4], Color(1, 1, 1)])


## The mall's name in gold on the grey box over the podium (a parody, as Arkadia's ARKADKA: the
## big word and the small one over its right end, as on the real box), facing the station.
const TARASY_GOLD := Color(1.0, 0.78, 0.35)


func _tarasy_signs(g: float) -> void:
	var face := Vector3(0.22, 0.0, 0.975)
	signs.append(["ZŁOTE", Vector3(-1384.0, g + 19.2, 447.9), face, 1.2, TARASY_GOLD])
	signs.append(["TARASKI", Vector3(-1381.5, g + 22.6, 448.5), face, 0.7, TARASY_GOLD])


# --- Złote Tarasy, update 2026-11-26 (spec docs/landmarks/specs/tarasy.md "3D Tiles + Street View pass") ---
## Only additions and re-skins of the parts the spec names; every part id t26_* is a function below.
const T26_ROOF := Color("#6b625a")        # the hall's dark brown-grey membrane (t26_roofs)
const T26_TEAL_FASCIA := Color("#8cc0b2")
const T26_TEAL_ROOF := Color("#82b8aa")
const T26_WHITE := Color("#ebe8df")       # PAL_WHITE_STONE
## The egg, 1.4x the first reading in plan (review): centre nudged north to stay on the hall roof.
const T26_EGG_C := Vector2(-1509.5, 515.0)
const T26_EGG_R := Vector2(7.7, 10.0)
const T26_BRICK_FRAME := TARASY_STONE


## t26_teal_box: the mapped #6EBE9F box on the hall (35-40 m): plain verdigris metal walls, a fascia
## ring and a 13-facet low hip. The glass rail round the top stays (F's rule: nothing existing goes).
func _t26_teal_box(poly: PackedVector2Array, y0: float, y1: float) -> void:
	var none := Color(0, 0, 0, 0)
	y1 += 2.5   # review: the walls stand 7.5 m clear of the brown hall roof, not 5
	_prism(poly, y0, y1, PAL_PATINA_COPPER, T26_TEAL_ROOF, M_STONE, M_STONE)
	_prism(poly, y1, y1 + 1.1, TARASY_RAIL, none, M_PAVILION + 0.5, M_STONE)
	kit_ledge_ring(poly, y1 - 0.6, 0.6, T26_TEAL_FASCIA, 0.15)
	_mode = M_STONE
	_pyramid(poly, y1, y1 + 1.8, T26_TEAL_ROOF)


## One facet of a ring band, shaded `dark` darker (the drum ring's 20 panels).
func _t26_facet(a0: Vector2, b0: Vector2, y0: float, a1: Vector2, b1: Vector2, y1: float, col: Color) -> void:
	var p0 := Vector3(a0.x, y0, a0.y)
	var p1 := Vector3(b0.x, y0, b0.y)
	var p2 := Vector3(b1.x, y1, b1.y)
	var p3 := Vector3(a1.x, y1, a1.y)
	var nrm := (p1 - p0).cross(p3 - p0).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	_quad(p0, p1, p2, p3, nrm, col)


## t26_drum_crown: a white ring of 20 panels, a blue glass oculus with 16 white ribs and a hub,
## on top of the drum's own deck and rim.
func _t26_drum_crown(g: float) -> void:
	var c := Vector2(-1459.0, 476.0)
	var r0 := _circle(c, 12.9, 20)
	var r1 := _circle(c, 7.2, 20)
	_mode = M_STONE
	for i in 20:
		var col := T26_WHITE if i % 2 == 0 else T26_WHITE.darkened(0.06)
		_t26_facet(r0[i], r0[(i + 1) % 20], g + 30.0, r1[i], r1[(i + 1) % 20], g + 31.4, col)
	var oc := _circle(c, 7.2, 16)
	_mode = M_GLASS_ROOF
	_pyramid(oc, g + 31.4, g + 32.4, TARASY_WAVE)
	for k in 16:
		_beam(Vector3(oc[k].x, g + 31.55, oc[k].y), Vector3(c.x, g + 32.55, c.y), 0.35, T26_WHITE)
	_prism(_circle(c, 1.0, 10), g + 32.4, g + 32.55, T26_WHITE, T26_WHITE, M_STONE, M_STONE)


func _t26_ellipse(c: Vector2, rx: float, rz: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := TAU * (k + 0.5) / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * rz))
	return out


## t26_egg: the white half-ellipsoid on the hall's roof, 11 x 16 x 6 m, five bands and an apex.
func _t26_egg(g: float) -> void:
	var c := T26_EGG_C
	var fr := [0.0, 0.35, 0.62, 0.82, 0.95]
	_mode = M_STONE
	var base := Color("#eceeed")
	var prev := _t26_ellipse(c, T26_EGG_R.x, T26_EGG_R.y, 20)
	var prev_y: float = g + 35.0
	for i in range(1, 5):
		var t: float = fr[i]
		var ring := _t26_ellipse(c, T26_EGG_R.x * sqrt(1.0 - t * t), T26_EGG_R.y * sqrt(1.0 - t * t), 20)
		var y: float = g + 35.0 + 6.0 * t
		_frustum(prev, prev_y, ring, y, base.darkened(0.03 * float(5 - i)))
		prev = ring
		prev_y = y
	_pyramid(prev, prev_y, g + 41.0, base)


## t26_south_band: the station-side strip re-skinned as ribbon glass, on a white soffit and a rounded
## fascia (the canopy, ledges and boards of the podium stay: this part is still in `podium`).
func _t26_south_band(poly: PackedVector2Array, y0: float, y1: float, g: float) -> void:
	_prism(poly, y0, y1, TARASY_DRUM_GLASS, T26_ROOF, M_SKIN + float(S_RIBBON) / 16.0, M_STONE)
	_mode = M_STONE
	_soffit(poly, y0, Color("#e6e8e6"))
	kit_ledge_ring(poly, y0 - 0.97, 1.0, Color("#e9ebea"), 0.3)   # 3 cm over the mall roof it stands on: no coplanar top
	# t26_p_boards: two lit blue parking boards, each with a white P.
	for bd: Array in [[Vector2(-1507.5, 529.3), Vector2(-0.27, 0.96)], [Vector2(-1488.5, 531.6), Vector2(0.20, 0.98)]]:
		var c: Vector2 = bd[0]
		var n: Vector2 = (bd[1] as Vector2).normalized()
		var side := Vector2(-n.y, n.x)
		var a := c - side * 3.5
		var b := c + side * 3.5
		_mode = M_LAMP
		_quad(Vector3(a.x, g + 22.0, a.y), Vector3(b.x, g + 22.0, b.y), Vector3(b.x, g + 28.0, b.y), Vector3(a.x, g + 28.0, a.y),
				Vector3(n.x, 0.0, n.y), Color("#2f5d9e"))
		var sp := c + n * 0.12
		signs.append(["P", Vector3(sp.x, g + 22.75, sp.y), Vector3(n.x, 0.0, n.y), 3.2, Color(1, 1, 1)])
	_mode = M_STONE


## t26_wing: teal glass over the shop floor, the roof rolling over the cornice to a flat teal cap.
## The glass rail stays (F's rule), so the wall runs to the mapped top and the roll starts there.
func _t26_wing(poly: PackedVector2Array, y0: float, y1: float) -> void:
	var none := Color(0, 0, 0, 0)
	var shop_top := _mean_ground(poly) + TARASY_SHOP_H
	_prism(poly, y0, shop_top, TARASY_SHOPFRONT, none, M_PAVILION, M_STONE)
	_prism(poly, shop_top, y1, PAL_PATINA_COPPER, none, M_PAVILION, M_STONE)
	_prism(poly, y1, y1 + 1.1, TARASY_RAIL, none, M_PAVILION + 0.5, M_STONE)
	_mode = M_STONE
	# the roll runs on the outline without its tiny steps (a mitred inset folds over them)
	var ring := PackedVector2Array()
	for q in poly:
		if ring.is_empty() or ring[ring.size() - 1].distance_to(q) >= 2.0:
			ring.append(q)
	while ring.size() > 3 and ring[0].distance_to(ring[ring.size() - 1]) < 2.0:
		ring.remove_at(ring.size() - 1)
	var r1 := _t26_inset(ring, 1.0)
	var r2 := _t26_inset(ring, 2.0)
	# starts 0.3 m over the mapped top (behind the rail): the small teal entrance parts' caps lie at 17 m
	_frustum(ring, y1 + 0.3, r1, y1 + 0.65, Color("#7aaea0"))
	_frustum(r1, y1 + 0.65, r2, y1 + 1.0, T26_TEAL_ROOF, T26_TEAL_ROOF)


## A ring `d` m inside `ring`, vertex for vertex, the mitre capped so a sharp corner doesn't fold over.
func _t26_inset(ring: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := ring.size()
	var out := PackedVector2Array()
	for i in n:
		var n1 := _out(ring, ring[(i + n - 1) % n], ring[i])
		var n2 := _out(ring, ring[i], ring[(i + 1) % n])
		out.append(ring[i] - (n1 + n2) * (d / maxf(1.0 + n1.dot(n2), 1.0)))
	return out


## A rectangle centred on c, `l` along t and `w` across n.
func _t26_rect(c: Vector2, t: Vector2, n: Vector2, l: float, w: float) -> PackedVector2Array:
	return PackedVector2Array([c - t * l * 0.5 - n * w * 0.5, c + t * l * 0.5 - n * w * 0.5,
			c + t * l * 0.5 + n * w * 0.5, c - t * l * 0.5 + n * w * 0.5])


## The point and tangent at distance s along a polyline.
func _t26_along(chain: PackedVector2Array, s: float) -> Array:
	var run := 0.0
	for i in chain.size() - 1:
		var l := chain[i].distance_to(chain[i + 1])
		if l < 0.01:
			continue
		if s <= run + l or i == chain.size() - 2:
			var t := (chain[i + 1] - chain[i]) / l
			return [chain[i] + t * (s - run), t]
		run += l
	return [chain[0], Vector2.RIGHT]


func _t26_len(chain: PackedVector2Array) -> float:
	var l := 0.0
	for i in chain.size() - 1:
		l += chain[i].distance_to(chain[i + 1])
	return l


## A roof box on the clipped footprint `fp` (clipped to `inset`); false when it loses over half its area.
func _t26_box(fp: PackedVector2Array, inset: PackedVector2Array, y0: float, h: float, wall: Color, top: Color) -> bool:
	var clip := _largest(Geometry2D.intersect_polygons(fp, inset))
	if clip.size() < 3 or absf(_area(clip)) < absf(_area(fp)) * 0.5:
		return false
	_prism(clip, y0, y0 + h, wall, top, M_STONE, M_STONE)
	return true


## t26_lumen_plant: the plant units, lift overrun, small boxes, shed and tilted panels on Lumen's two roofs.
func _t26_lumen_plant(g: float, lumens: Array) -> void:
	var y := g + 55.0
	for poly: PackedVector2Array in lumens:
		var inset := _largest(Geometry2D.offset_polygon(poly, -2.2, Geometry2D.JOIN_MITER))
		if inset.size() < 3:
			continue
		if poly.size() == 36:
			# West arc: the outer (west) wall runs from index 0 (south) to 17 (north end).
			var chain := PackedVector2Array()
			for i in range(17, -1, -1):
				chain.append(poly[i])
			var total := _t26_len(chain)
			for k in 8:
				var at := _t26_along(chain, 6.0 + k * 8.0 + 3.25)
				var t: Vector2 = at[1]
				var n := Vector2(-t.y, t.x)
				if not Geometry2D.is_point_in_polygon(at[0] + n * 2.0, poly):
					n = -n
				_t26_box(_t26_rect(at[0] + n * 5.0, t, n, 6.5, 4.5), inset, y, 2.0, PAL_ALUMINIUM, PAL_ROOF_PALE)
			# the lift overrun at the north end, where the arcs meet
			var c0 := (poly[17] + poly[18]) * 0.5
			var t0 := (chain[1] - chain[0]).normalized()
			var n0 := Vector2(-t0.y, t0.x)
			_t26_box(_t26_rect(c0 + t0 * 3.5, t0, n0, 7.0, 9.0), inset, y, 3.5, PAL_PALE_CONCRETE, PAL_PALE_CONCRETE.lightened(0.05))
			# two small boxes at the south end
			for k in 2:
				var at := _t26_along(chain, total - 5.0 - 7.0 * k)
				var t: Vector2 = at[1]
				var n := Vector2(-t.y, t.x)
				if not Geometry2D.is_point_in_polygon(at[0] + n * 2.0, poly):
					n = -n
				_t26_box(_t26_rect(at[0] + n * 5.0, t, n, 3.0, 3.0), inset, y, 1.5, PAL_ALUMINIUM, PAL_ALUMINIUM.lightened(0.05))
		elif poly.size() == 25:
			# North arc: a long plant shed, then six tilted dark panels to the east.
			_t26_box(_t26_rect(Vector2(-1449.0, 364.0), Vector2(1, 0), Vector2(0, 1), 26.0, 10.0), inset, y, 3.0,
					PAL_ROOF_GRAVEL, PAL_ALUMINIUM)
			var chain := PackedVector2Array()
			for i in 12:
				chain.append(poly[i])
			var s0 := 0.0
			var run := 0.0
			for i in 11:
				if chain[i].x < -1434.0:
					s0 = run + chain[i].distance_to(chain[i + 1])
				run += chain[i].distance_to(chain[i + 1])
			for k in 6:
				var at := _t26_along(chain, s0 + 2.0 + 5.0 * k)
				var t: Vector2 = at[1]
				var n := Vector2(-t.y, t.x)
				if not Geometry2D.is_point_in_polygon(at[0] + n * 2.0, poly):
					n = -n
				var cc: Vector2 = at[0] + n * 9.0
				if not Geometry2D.is_point_in_polygon(cc, inset):
					continue
				# the panel's high edge faces south (+z): its low edge sits 0.4 m on the roof, the high 0.9 m
				var south := Vector2(0, 1) if n.y >= 0.0 else Vector2(0, -1)
				south = (south - t * south.dot(t)).normalized()
				var lo := cc - south
				var hi := cc + south
				var a0 := lo - t * 2.0
				var a1 := lo + t * 2.0
				var b0 := hi + t * 2.0
				var b1 := hi - t * 2.0
				_mode = M_STONE
				var nm := Vector3(-south.x * 0.26, 0.97, -south.y * 0.26)
				_quad(Vector3(a0.x, y + 0.4, a0.y), Vector3(a1.x, y + 0.4, a1.y), Vector3(b0.x, y + 0.92, b0.y),
						Vector3(b1.x, y + 0.92, b1.y), nm, PAL_GLASS_NAVY)
	_mode = M_STONE


## t26_brick: a recessed red-brick panel in a stone frame on one wall, centred c, facing n.
func _t26_brick_panel(c: Vector2, n: Vector2, width: float, y0: float, y1: float, off: float) -> void:
	var side := Vector2(-n.y, n.x)
	var fr := 0.4
	var nrm := Vector3(n.x, 0.0, n.y)
	var o := c + n * off
	var fcol := T26_BRICK_FRAME.darkened(0.15)
	_mode = M_STONE
	var hw := width * 0.5
	var l0 := o - side * hw
	var l1 := o + side * hw
	var iin0 := o - side * (hw - fr)
	var iin1 := o + side * (hw - fr)
	_quad(Vector3(iin0.x, y0 + fr, iin0.y), Vector3(iin1.x, y0 + fr, iin1.y), Vector3(iin1.x, y1 - fr, iin1.y),
			Vector3(iin0.x, y1 - fr, iin0.y), nrm, PLAZA_BRICK)
	_quad(Vector3(l0.x, y0, l0.y), Vector3(l1.x, y0, l1.y), Vector3(l1.x, y0 + fr, l1.y), Vector3(l0.x, y0 + fr, l0.y), nrm, fcol)
	_quad(Vector3(l0.x, y1 - fr, l0.y), Vector3(l1.x, y1 - fr, l1.y), Vector3(l1.x, y1, l1.y), Vector3(l0.x, y1, l0.y), nrm, fcol)
	_quad(Vector3(l0.x, y0 + fr, l0.y), Vector3(iin0.x, y0 + fr, iin0.y), Vector3(iin0.x, y1 - fr, iin0.y),
			Vector3(l0.x, y1 - fr, l0.y), nrm, fcol)
	_quad(Vector3(iin1.x, y0 + fr, iin1.y), Vector3(l1.x, y0 + fr, l1.y), Vector3(l1.x, y1 - fr, l1.y),
			Vector3(iin1.x, y1 - fr, iin1.y), nrm, fcol)


## The extras of the 2026-11-26 pass that need the whole site: vents, Lumen's plant, the brick panels,
## the cinema's name, the lift box's grid.
func _t26_extras(g: float, podium: Array, t26: Dictionary) -> void:
	# t26_vents
	var teal: PackedVector2Array = t26["teal"]
	var plate: PackedVector2Array = t26["plate"]
	var egg_c := T26_EGG_C
	for p: Vector2 in [Vector2(-1485.9, 502.3), Vector2(-1474.0, 509.8), Vector2(-1459.8, 506.0), Vector2(-1493.4, 516.5),
			Vector2(-1465.8, 521.7), Vector2(-1484.4, 526.9), Vector2(-1478.4, 481.4), Vector2(-1475.5, 485.1),
			Vector2(-1468.7, 488.9), Vector2(-1483.0, 486.0)]:
		if teal.size() >= 3 and Geometry2D.is_point_in_polygon(p, teal):
			continue
		var d := p - egg_c
		if pow(d.x / T26_EGG_R.x, 2.0) + pow(d.y / T26_EGG_R.y, 2.0) < 1.0:
			continue
		var on_plate := plate.size() >= 3 and Geometry2D.is_point_in_polygon(p, plate)
		var yb := g + (36.0 if on_plate else 35.0)
		_prism(_square(p, 0.6), yb, yb + 0.9, PAL_DARK_STEEL, PAL_DARK_STEEL.lightened(0.06), M_STONE, M_STONE)
	_t26_lumen_plant(g, t26["lumen"])
	# t26_brick: Złota entrance (the first podium wall south of (-1470, 330)) ...
	var best_z := INF
	var best_n := Vector2(0, -1)
	for part: Array in podium:
		var poly: PackedVector2Array = part[0]
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if absf(b.x - a.x) < 1.0 or minf(a.x, b.x) > -1470.0 or maxf(a.x, b.x) < -1470.0:
				continue
			var z := a.y + (b.y - a.y) * (-1470.0 - a.x) / (b.x - a.x)
			var out := _out(poly, a, b)
			if out.y < -0.7 and z >= 330.0 and z < best_z:
				best_z = z
				best_n = out
	if best_z < INF:
		var cz := Vector2(-1470.0, best_z)
		_t26_brick_panel(cz, best_n, 12.0, g + 5.0, g + 13.5, 0.1)
		var sp := cz + best_n * 0.35
		signs.append(["ZŁOTE", Vector3(sp.x, g + 10.0, sp.y), Vector3(best_n.x, 0.0, best_n.y), 1.0, TARASY_GOLD])
		signs.append(["TARASKI", Vector3(sp.x, g + 8.2, sp.y), Vector3(best_n.x, 0.0, best_n.y), 0.6, TARASY_GOLD])
	# ... and the Emilii Plater entrance, behind the ZARAZA and H·M·M boards.
	_t26_brick_panel(Vector2(-1362.0, 448.5), Vector2(0.94, -0.34).normalized(), 14.0, g + 4.8, g + 15.0, 0.12)
	# t26_cinema_sign: the hall's west face, snapped to the nearest wall of the hall (the spec's point is 4 m inside it).
	var hall: PackedVector2Array = t26["hall"]
	if hall.size() >= 3:
		var want := Vector2(-1535.0, 497.0)
		var bq := want
		var bn := Vector2(-0.94, 0.33)
		var bd := INF
		for i in hall.size():
			var a := hall[i]
			var b := hall[(i + 1) % hall.size()]
			var q := Geometry2D.get_closest_point_to_segment(want, a, b)
			if q.distance_to(want) < bd:
				bd = q.distance_to(want)
				bq = q
				bn = _out(hall, a, b)
		var sp2 := bq + bn * 0.3
		signs.append(["MULTIKINKO", Vector3(sp2.x, g + 27.0, sp2.y), Vector3(bn.x, 0.0, bn.y), 1.6, Color("#e0457b")])
	# t26_grid: three beams each way on the lift box's roof.
	var lift: PackedVector2Array = t26["lift"]
	if lift.size() >= 3:
		var x0 := INF
		var x1 := -INF
		var z0 := INF
		var z1 := -INF
		for q in lift:
			x0 = minf(x0, q.x)
			x1 = maxf(x1, q.x)
			z0 = minf(z0, q.y)
			z1 = maxf(z1, q.y)
		for f in [0.25, 0.5, 0.75]:
			var zz: float = lerpf(z0, z1, f)
			_beam(Vector3(x0, g + 28.6, zz), Vector3(x1, g + 28.6, zz), 0.4, PAL_ALUMINIUM)
			var xx: float = lerpf(x0, x1, f)
			_beam(Vector3(xx, g + 29.0, z0), Vector3(xx, g + 29.0, z1), 0.4, PAL_ALUMINIUM)   # laid across the east-west ones, not through them
	_mode = M_STONE


## The guitar sign by the café on the podium's south-east corner (F, 2026-11-11, his photos and the
## orthophoto: it stands on the pavement at about (-1349, 457.5), on a black pole with a menu box,
## facing the crossing): a big electric guitar, the red body and the cream rim in neon, a pale wood
## neck, the café's parody badge on the body (HARD BLOK CAFE: a hard rock of the prefab blocks; its
## colours are not the real one's). One flat slab per part, lit at night (M_LAMP).
const GUITAR_AT := Vector2(-1349.0, 457.5)
const GUITAR_FACE := Vector2(0.42, 0.91)
const GUITAR_SCALE := 0.9
const GUITAR_RED := Color("#b8321f")
const GUITAR_RIM := Color("#f1d9a6")
const GUITAR_WOOD := Color("#d9a253")
const GUITAR_BADGE := Color("#f4ecd8")
## The body's outline (metres before GUITAR_SCALE, y up from its bottom, x to the viewer's right):
## a double cutaway, the right horn the taller.
const GUITAR_BODY := [Vector2(0.0, 0.0), Vector2(1.2, 0.12), Vector2(2.1, 0.6), Vector2(2.5, 1.5), Vector2(2.3, 2.4),
		Vector2(2.05, 2.9), Vector2(2.25, 3.7), Vector2(2.35, 4.6), Vector2(2.0, 5.05), Vector2(1.5, 4.6),
		Vector2(1.0, 4.0), Vector2(0.45, 3.85), Vector2(-0.45, 3.85), Vector2(-1.0, 4.0), Vector2(-1.6, 4.4),
		Vector2(-2.05, 4.25), Vector2(-2.2, 3.5), Vector2(-2.0, 2.85), Vector2(-2.4, 2.0), Vector2(-2.5, 1.2),
		Vector2(-2.0, 0.5), Vector2(-1.1, 0.06)]
const GUITAR_HEAD := [Vector2(-0.4, 0.0), Vector2(0.4, 0.0), Vector2(0.75, 0.5), Vector2(0.85, 1.6),
		Vector2(0.55, 1.95), Vector2(-0.15, 1.8), Vector2(-0.5, 1.2)]


func _tarasy_guitar(g: float) -> void:
	var c := GUITAR_AT
	var base: float = map.terrain_height(c.x, c.y)
	var f := GUITAR_FACE.normalized()
	var right := Vector3(f.y, 0.0, -f.x)
	var n := Vector3(f.x, 0.0, f.y)
	var o := Vector3(c.x, base, c.y)
	var sc := GUITAR_SCALE
	_mode = M_STONE
	# The foot: a black box with the menu's lit panel on its face, the pole up to the body.
	_prism(_square(c, 0.75), base - 0.3, base + 2.6, Color("#202224"), Color("#2a2c2e"), M_STONE, M_STONE)
	var menu := o + n * 0.77 + Vector3.UP * 0.5
	_mode = M_LAMP
	_quad(menu - right * 0.5, menu + right * 0.5, menu + right * 0.5 + Vector3.UP * 1.7, menu - right * 0.5 + Vector3.UP * 1.7,
			n, Color("#f3efe4"))
	_mode = M_STONE
	_prism(_circle(c, 0.32, 8), base + 2.6, base + 5.4, Color("#2a2c2e"), Color("#2a2c2e"), M_STONE, M_STONE)
	var body_y := base + 5.0
	var body := PackedVector2Array()
	for q: Vector2 in GUITAR_BODY:
		body.append(q * sc)
	_upright_slab(body, o + Vector3.UP * (body_y - base), right, n, 0.9, GUITAR_RED, GUITAR_RIM, M_LAMP, M_LAMP)
	# The pickguard, a pale scratch plate, and the badge: a cream disc the words sit on.
	var guard := PackedVector2Array([Vector2(-0.5, 3.75), Vector2(0.5, 3.75), Vector2(1.3, 3.2), Vector2(1.6, 2.2),
			Vector2(1.0, 1.6), Vector2(-0.9, 1.9), Vector2(-1.5, 2.7), Vector2(-1.2, 3.5)])
	for i in guard.size():
		guard[i] *= sc
	_upright_slab(guard, o + Vector3.UP * (body_y - base) + n * 0.47, right, n, 0.04, Color("#e9e2d2"), Color("#e9e2d2"), M_STONE, M_STONE)
	var badge := _circle(Vector2(0.0, 1.7) * sc, 1.45 * sc, 18)
	_upright_slab(badge, o + Vector3.UP * (body_y - base) + n * 0.5, right, n, 0.04, GUITAR_BADGE, GUITAR_BADGE, M_LAMP, M_LAMP)
	# The neck from the body's notch to the head, frets as dark bands; the headstock tilted.
	var neck := PackedVector2Array([Vector2(-0.42, 3.6), Vector2(0.42, 3.6), Vector2(0.36, 11.2), Vector2(-0.36, 11.2)])
	for i in neck.size():
		neck[i] *= sc
	_upright_slab(neck, o + Vector3.UP * (body_y - base), right, n, 0.5, GUITAR_WOOD, GUITAR_RIM, M_LAMP, M_LAMP)
	var head := PackedVector2Array()
	for q: Vector2 in GUITAR_HEAD:
		head.append((q + Vector2(0.0, 11.2)) * sc)
	_upright_slab(head, o + Vector3.UP * (body_y - base), right, n, 0.45, GUITAR_RIM, GUITAR_WOOD, M_LAMP, M_LAMP)
	_mode = M_STONE
	for k in 7:
		var y := (4.4 + k * 0.95) * sc
		var a := o + Vector3.UP * (body_y - base + y) + n * 0.27
		_quad(a - right * 0.36 * sc, a + right * 0.36 * sc, a + right * 0.36 * sc + Vector3.UP * 0.07, a - right * 0.36 * sc + Vector3.UP * 0.07,
				n, Color("#6b4a2a"))
	var word_at := o + Vector3.UP * (body_y - base + 1.95 * sc) + n * 0.55
	signs.append(["HARD BLOK", word_at, n, 0.22, Color(0.85, 0.12, 0.1)])
	signs.append(["CAFE", word_at - Vector3.UP * 0.75, n, 0.2, Color(0.85, 0.12, 0.1)])
	_collide(_square(c, 0.8))


## A flat upright slab: plan-free outline `poly` (x along `right`, y up) at `o`, `thick` deep about
## the plane through o facing `n`; front and back faces in `face`, the edge round it in `side`.
func _upright_slab(poly: PackedVector2Array, o: Vector3, right: Vector3, n: Vector3, thick: float, face: Color,
		side: Color, face_mode: float, side_mode: float) -> void:
	var at := func(q: Vector2, d: float) -> Vector3:
		return o + right * q.x + Vector3.UP * q.y + n * d
	var idx := Geometry2D.triangulate_polygon(poly)
	_mode = face_mode
	for t in range(0, idx.size() - 2, 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		_tri(at.call(a, thick * 0.5), at.call(b, thick * 0.5), at.call(c, thick * 0.5), n, face,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
		_tri(at.call(a, -thick * 0.5), at.call(c, -thick * 0.5), at.call(b, -thick * 0.5), -n, face.darkened(0.2),
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
	_mode = side_mode
	var ccw := not Geometry2D.is_polygon_clockwise(poly)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var e := (b - a).normalized()
		var out2 := Vector2(e.y, -e.x) if ccw else Vector2(-e.y, e.x)
		var out := (right * out2.x + Vector3.UP * out2.y).normalized()
		_quad(at.call(a, -thick * 0.5), at.call(b, -thick * 0.5), at.call(b, thick * 0.5), at.call(a, thick * 0.5), out, side)


## The guitar's café on the podium's south-east corner (the orthophoto: its tables under white
## umbrellas along the podium's south face): its parody name over the door, and the umbrellas.
func _tarasy_cafe(g: float) -> void:
	var face := Vector3(0.12, 0.0, 0.99)
	signs.append(["HARD BLOK", Vector3(-1365.0, g + 4.6, 457.9), face, 0.35, Color(0.95, 0.2, 0.15)])
	for c: Vector2 in [Vector2(-1371.5, 460.6), Vector2(-1367.0, 461.0), Vector2(-1362.5, 460.8), Vector2(-1358.2, 460.2)]:
		_umbrella(c, 0.13, map.terrain_height(c.x, c.y), Color("#f3f0e8"))


## Złote Tarasy's sunken plaza (site `tarasy_plaza`, the SUNKEN rings did the walls, shops and
## treads): white café umbrellas by the shops on its west half (F's photos 5de57b27, 71bbdf44).
const PLAZA_UMBRELLAS := [Vector2(-1421.0, 481.5), Vector2(-1416.0, 477.5), Vector2(-1411.5, 482.5),
		Vector2(-1416.5, 486.5), Vector2(-1406.0, 479.0), Vector2(-1402.0, 485.0), Vector2(-1424.5, 485.0)]


func _tarasy_plaza_dress() -> void:
	for c: Vector2 in PLAZA_UMBRELLAS:
		_umbrella(c, 0.3, map.terrain_height(c.x, c.y), Color("#f1eee6"))


## Skylight rebuilt from photos (refs/skylight/REPORT.md, 2026-11-05): a light silver-grey shaft
## with a dark-teal window dash per floor (S_PUNCHED), on piers with a glass canopy, a stepped
## four-floor glazed belt at 20-33 m, a roof that is high on the convex south wall and scooped
## down on the west half round an oval glass cap, plant on the east half, and no advert panels: the 3D
## screen is on the block over the entrance (tarasy_screen.gd). No lit crown: the real top has none.
const SKY_CLAD := Color("#b8bdc1")
const SKY_ROOF := Color("#8e9497")
const SKY_GLASS := Color("#4f7f92")


func _tarasy_skylight(poly: PackedVector2Array, y0: float, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var c := _centre(poly)
	var clad := M_SKIN + float(S_PUNCHED) / 16.0
	var belt := M_SKIN + float(S_RIBBON) / 16.0
	# Foot: dark lobby glass between the piers, a canopy slab at 5 m.
	var foot := _largest(Geometry2D.offset_polygon(poly, -1.0, Geometry2D.JOIN_MITER))
	if foot.size() < 3:
		foot = poly
	_prism(foot, y0, g + 5.0, SKY_GLASS.darkened(0.25), none, M_PAVILION, M_STONE)
	_prism(poly, g + 5.0, g + 5.5, Color("#c9ccce"), SKY_ROOF, M_STONE, M_STONE)
	# Lower body: cladding with the narrow gold stair slits' rhythm left to the skin.
	_prism(poly, g + 5.5, g + 20.0, SKY_CLAD, none, clad, M_SKIN)
	# The glazed belt, each edge stepped out a little.
	var out := PackedVector2Array()
	for q in poly:
		out.append(c + (q - c) * 1.012)
	_prism(out, g + 20.0, g + 33.0, SKY_GLASS, none, belt, M_SKIN)
	# The shaft to the notch line, then two roof heights.
	_prism(poly, g + 33.0, g + 100.0, SKY_CLAD, none, clad, M_SKIN)
	var split_x := c.x - 4.0
	var east := Geometry2D.intersect_polygons(poly, PackedVector2Array([
		Vector2(split_x, c.y - 60.0), Vector2(c.x + 80.0, c.y - 60.0),
		Vector2(c.x + 80.0, c.y + 60.0), Vector2(split_x, c.y + 60.0)]))
	for e: PackedVector2Array in east:
		_prism(e, g + 100.0, g + 105.0, SKY_CLAD, SKY_ROOF, clad, M_STONE)
	# West half: roof at 100 m, a lower parapet, and the oval glass cap in the notch.
	var west := Geometry2D.intersect_polygons(poly, PackedVector2Array([
		Vector2(c.x - 80.0, c.y - 60.0), Vector2(split_x, c.y - 60.0),
		Vector2(split_x, c.y + 60.0), Vector2(c.x - 80.0, c.y + 60.0)]))
	for w: PackedVector2Array in west:
		_prism(w, g + 100.0, g + 100.4, SKY_ROOF, SKY_ROOF, M_STONE, M_STONE)
	var cap_c := Vector2(-1396.0, 418.0)
	var cap := PackedVector2Array()
	var cap_top := PackedVector2Array()
	for k in 20:
		var d := Vector2.from_angle(TAU * (k + 0.5) / 20.0)
		cap.append(cap_c + Vector2(d.x * 6.0, d.y * 3.5))
		cap_top.append(cap_c + Vector2(d.x * 4.2, d.y * 2.4))
	_mode = M_PAVILION + 0.5
	_frustum(cap, g + 100.4, cap_top, g + 103.4, Color("#9fc4d2"), Color("#b9d2dc"))
	# Roof plant on the east half behind the high wall.
	_prism(_square(c + Vector2(7.0, -3.0), 4.5), g + 105.0, g + 107.5, Color("#aeb3b6"), SKY_ROOF, M_STONE, M_STONE)
	_prism(_square(c + Vector2(13.0, -1.0), 3.0), g + 105.0, g + 106.6, Color("#a2a7aa"), SKY_ROOF, M_STONE, M_STONE)
	_mode = M_STONE


## The glass wave, rebuilt from F's photos (2026-11-11: "it's actually a blue shape, glass"): one
## surface over the mapped domes like fabric draped over balls of different sizes, each dome a
## cap at its own height (TARASY_DOME_H: highest by Skylight, lowest where it sweeps down to the
## plaza on the station side), blended so the valleys between them stay soft but deep; laid on
## the ground's slope. Built from real triangular panes (TARASY_PANE in plan, an equilateral
## lattice): each triangle carries its corners' barycentric coordinates (building.gdshader
## glass_roof, M_GLASS_ROOF + 0.5 draws the steel frame on its edges) and its own shade of blue,
## so the roof sparkles pane by pane. Glass walls round its rim where it stands clear of the
## ground: the terraces' shopfronts, lit warm floor by floor at night.
const TARASY_PANE := 3.2
## Each mapped dome's height (by its centre, within 4 m), from the photos from the
## plaza, the Palace and Varso; the mapped 35 / 22 m are all alike.
const TARASY_DOME_H := {Vector2(-1430, 420): 36.0, Vector2(-1440, 395): 31.0, Vector2(-1470, 395): 34.0,
		Vector2(-1465, 420): 32.0, Vector2(-1495, 410): 30.0, Vector2(-1495, 440): 27.0,
		Vector2(-1435, 440): 25.0, Vector2(-1460, 450): 21.0}
const TARASY_GLASS := Color("#4a74a6")      # the wave's blue glass (F's photos: blue, a little sky)
const TARASY_GLASS_SKY := Color("#a9c8e4")  # a pane catching the sky


func _tarasy_wave(site: Dictionary) -> void:
	var domes: Array = []
	for b in site.get("domes", []):
		var poly := _pts(b["p"])
		var c := _centre(poly)
		var r := 0.0
		for q in poly:
			r += q.distance_to(c)
		var h := float(b["h"])
		for key: Vector2 in TARASY_DOME_H:
			if key.distance_to(c) < 4.0:
				h = TARASY_DOME_H[key]
		domes.append([c, r / poly.size() + 1.0, h])
	if domes.is_empty():
		return
	var lo := Vector2(INF, INF)
	var hi := -lo
	for d in domes:
		lo = lo.min(d[0] - Vector2.ONE * d[1])
		hi = hi.max(d[0] + Vector2.ONE * d[1])
	var step := TARASY_PANE
	var row := step * sqrt(3.0) * 0.5
	var nx := ceili((hi.x - lo.x) / step) + 1
	var nz := ceili((hi.y - lo.y) / row)
	# Every lattice corner: inside the domes (or moved onto the nearest rim) and its height.
	var corner := PackedVector3Array()
	var inside := PackedByteArray()
	for j in nz + 1:
		for i in nx + 1:
			var p := lo + Vector2(i * step + (step * 0.5 if j % 2 == 1 else 0.0), j * row)
			var best := INF
			var rim := p
			var any := false
			for d in domes:
				var dist := p.distance_to(d[0])
				if dist <= d[1]:
					any = true
				if dist - d[1] < best:
					best = dist - d[1]
					rim = d[0] + (p - d[0]).normalized() * d[1] * 0.999
			if not any:
				p = rim
			corner.append(Vector3(p.x, _wave(p, domes), p.y))
			inside.append(1 if any else 0)
	_mode = M_GLASS_ROOF + 0.5
	var ua := Vector2(-2.0, -2.0)
	var ub := Vector2(-3.0, -2.0)
	var uc := Vector2(-2.0, -3.0)
	for j in nz:
		for i in nx:
			var k00 := j * (nx + 1) + i
			var k10 := k00 + 1
			var k01 := k00 + nx + 1
			var k11 := k01 + 1
			# Rows alternate their half-pane offset: an even row's panes lean the other way.
			var tris := [[k00, k10, k01], [k10, k11, k01]] if j % 2 == 0 else [[k00, k11, k01], [k00, k10, k11]]
			for tri: Array in tris:
				if inside[tri[0]] + inside[tri[1]] + inside[tri[2]] == 0:
					continue
				var a := corner[tri[0]]
				var b := corner[tri[1]]
				var c := corner[tri[2]]
				if (b - a).cross(c - a).length() < 0.05:
					continue
				var n := (b - a).cross(c - a).normalized()
				if n.y < 0.0:
					n = -n
				# Each pane its own blue; one in twelve catches the sky.
				var h := fposmod(sin((a.x + b.x + c.x) * 12.9898 + (a.z + b.z + c.z) * 78.233) * 43758.5453, 1.0)
				var pane := TARASY_GLASS_SKY if h > 0.92 else TARASY_GLASS.lightened(h * 0.16).darkened(0.08)
				_tri(a, b, c, n, pane, ua, ub, uc, -1.0)
	# The rim: glass walls where the wave stands clear of the ground.
	_mode = M_PAVILION
	for d in domes:
		var seg := 40
		for k in seg:
			var a: Vector2 = d[0] + Vector2.from_angle(TAU * k / seg) * d[1]
			var b: Vector2 = d[0] + Vector2.from_angle(TAU * (k + 1) / seg) * d[1]
			var m := (a + b) * 0.5
			var covered := false
			for e in domes:
				if e != d and m.distance_to(e[0]) < e[1] - 0.3:
					covered = true
					break
			if covered:
				continue
			var ya := _wave(a, domes)
			var yb := _wave(b, domes)
			var ga: float = map.terrain_height(a.x, a.y) - 0.3
			var gb: float = map.terrain_height(b.x, b.y) - 0.3
			if ya - ga < 0.6 and yb - gb < 0.6:
				continue
			var n: Vector2 = (m - (d[0] as Vector2)).normalized()
			_quad(Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y),
					Vector3(n.x, 0, n.y), TARASY_RIM, Vector2(0, ga - _g), Vector2(a.distance_to(b), gb - _g),
					Vector2(a.distance_to(b), yb - _g), Vector2(0, ya - _g), maxf(ya, yb) - _g)
			map._solid(&"landmark", [Vector3(a.x, ga - 1.0, a.y), Vector3(b.x, gb - 1.0, b.y), Vector3(b.x, gb + 5.0, b.y),
					Vector3(a.x, ga - 1.0, a.y), Vector3(b.x, gb + 5.0, b.y), Vector3(a.x, ga + 5.0, a.y)], _r2)


## The wave's height at a point: each dome a cap with steep, bulging sides (its rim a seventh of
## its height), the caps blended where they overlap (a soft maximum: the valleys between them
## stay round, not creased); on the ground's slope.
func _wave(p: Vector2, domes: Array) -> float:
	var k := 1.4
	var sum := 0.0
	var any := false
	for d in domes:
		var t: float = p.distance_to(d[0]) / d[1]
		if t <= 1.0:
			var v: float = d[2] * (0.14 + 0.86 * pow(maxf(1.0 - t * t, 0.0), 0.62))
			sum += exp(v / k)
			any = true
	var h := k * log(sum) if any else 0.0
	return map.terrain_height(p.x, p.y) + h


# --- the Rotunda ------------------------------------------------------------------------------

## Rebuilt from photos (2026-11-08, spec docs/landmarks/specs/rotunda.md): F's set
## (pkin-surroundings/photos/E3-rotunda: the street front, the crown close up, the overhang, the
## view from Varso, a night front), the Commons views from the Palace and Varso and fresh Mapillary
## (2026-05). A green-teal glass drum in 40 tall bays between slim silver mullions, two thin
## transoms; the glass rises into a ring of points under a thin white zigzag edge, the end of a
## folded-plate roof whose 40 radial folds slope DOWN from the rim into a raised oculus (a funnel:
## from the street nothing shows over the edge); a flat white canopy over the south door, a smaller
## one on the plaza (north-west), and the bank's parody name either side of the south door.
const ROT_GLASS := Color("#5e7f7a")    # #4d6f6b in shade, #6f8f8a lit
const ROT_SILVER := Color("#c3c8cc")
const ROT_WHITE := Color("#eef1f3")   # the mullions, transoms and the oculus kerb (F's photos, 2026-11-11)
const ROT_OCULUS_GLASS := Color("#2c5d8a")  # the oculus: dark blue glass (the drone views)
const ROT_FOLD_LIGHT := Color("#d4d8db")
const ROT_FOLD_DARK := Color("#b0b6bb")
const ROT_TOOTH := Color("#e8ebed")   # the zigzag edge, white-silver
const ROT_BAYS := 40        # bays and folds alike: a point over every mullion (the photos)
const ROT_EAVE := 10.8      # the glass's valleys (mid-bay), over the ground
const ROT_RIDGE := 12.3     # the glass's points, over every mullion
const ROT_EDGE := 0.6       # how far the roof's edge stands out from the glass
const ROT_OCULUS := 5.4     # the oculus's radius (10.8 m across)
const ROT_SOUTH := Vector2(0, 1)
const ROT_PLAZA := Vector2(-0.7071, -0.7071)


func _build_rotunda(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	var c := _centre(poly)
	var r := 0.0
	for q in poly:
		r += q.distance_to(c)
	r /= poly.size()
	_g = _ground_under(poly)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The drum: one bay of the 40 centred on the south door, a mullion at every corner.
	var step := TAU / ROT_BAYS
	var a0 := ROT_SOUTH.angle() + 0.5 * step
	var drum := PackedVector2Array()
	for k in ROT_BAYS:
		drum.append(c + Vector2.from_angle(a0 + k * step) * r)
	_prism(drum, g - 0.4, g + 0.3, Color("#55585c"), none, M_STONE)
	_prism(drum, g + 0.3, g + ROT_EAVE, ROT_GLASS, none, M_PAVILION + 0.75)
	# The glass rises into a point over every mullion: two glass triangles per bay over the eave.
	_mode = M_PAVILION + 0.75
	var nn := Vector2(-1, -1)
	for k in ROT_BAYS:
		var p0 := drum[k]
		var p1 := drum[(k + 1) % ROT_BAYS]
		var mid := c + Vector2.from_angle(a0 + (k + 0.5) * step) * r
		var o := Vector2.from_angle(a0 + (k + 0.5) * step)
		var n := Vector3(o.x, 0, o.y)
		_tri(Vector3(p0.x, g + ROT_EAVE, p0.y), Vector3(mid.x, g + ROT_EAVE, mid.y), Vector3(p0.x, g + ROT_RIDGE, p0.y), n, ROT_GLASS, nn, nn, nn, -1.0)
		_tri(Vector3(mid.x, g + ROT_EAVE, mid.y), Vector3(p1.x, g + ROT_EAVE, p1.y), Vector3(p1.x, g + ROT_RIDGE, p1.y), n, ROT_GLASS, nn, nn, nn, -1.0)
	_mode = M_STONE
	for p in drum:
		_rot_fin(c, p, g + 0.3, g + ROT_RIDGE, 0.06, 0.14, ROT_WHITE)
	# Two thin silver transoms round the drum (the street photos: the panes in three rows).
	for y: float in [3.4, 7.1]:
		for k in ROT_BAYS:
			var q0 := c + Vector2.from_angle(a0 + k * step) * (r + 0.06)
			var q1 := c + Vector2.from_angle(a0 + (k + 1) * step) * (r + 0.06)
			var o := Vector2.from_angle(a0 + (k + 0.5) * step)
			_quad(Vector3(q0.x, g + y, q0.y), Vector3(q1.x, g + y, q1.y), Vector3(q1.x, g + y + 0.2, q1.y),
					Vector3(q0.x, g + y + 0.2, q0.y), Vector3(o.x, 0, o.y), ROT_WHITE)
	_rot_crown(c, r, g, a0)
	_rot_plaza(c, r)
	# The entrances: glazed doors under a flat white canopy, a transom over the doors.
	_rot_door(c, r, g, ROT_SOUTH, 3, 8.0, 2.0, 3.8)
	_rot_door(c, r, g, ROT_PLAZA, 2, 5.0, 1.5, 3.6)
	# The bank's name (a parody), white on the glass either side of the south door.
	for s: float in [-1.0, 1.0]:
		var d := ROT_SOUTH.rotated(s * 0.56)
		var at := c + d * (r + 0.1)
		signs.append(["BANK POLSKA", Vector3(at.x, g + 5.2, at.y), Vector3(d.x, 0.0, d.y), 0.4, Color(0.95, 0.97, 1.0)])
	_collide(drum)


## A mullion standing proud of the glass at plan point p: its face and two sides.
func _rot_fin(c: Vector2, p: Vector2, y0: float, y1: float, half: float, depth: float, col: Color) -> void:
	var o := (p - c).normalized()
	var t := Vector2(-o.y, o.x)
	var a := p - t * half
	var b := p + t * half
	var a2 := a + o * depth
	var b2 := b + o * depth
	var n := Vector3(o.x, 0, o.y)
	var tn := Vector3(t.x, 0, t.y)
	_quad(Vector3(a2.x, y0, a2.y), Vector3(b2.x, y0, b2.y), Vector3(b2.x, y1, b2.y), Vector3(a2.x, y1, a2.y), n, col)
	_quad(Vector3(b.x, y0, b.y), Vector3(b2.x, y0, b2.y), Vector3(b2.x, y1, b2.y), Vector3(b.x, y1, b.y), tn, col.darkened(0.08))
	_quad(Vector3(a.x, y0, a.y), Vector3(a2.x, y0, a2.y), Vector3(a2.x, y1, a2.y), Vector3(a.x, y1, a.y), -tn, col.darkened(0.08))


## The folded-plate roof (the photos from Varso and the Palace): 40 folds, a ridge over every
## mullion and a valley over every bay's middle, sloping DOWN from the rim into the oculus (a
## shallow funnel; the folds flatten towards the middle); the thin white zigzag edge round the rim
## (the glass's points under it); the oculus's raised kerb and glazed top in a 4 x 4 grid.
func _rot_crown(c: Vector2, r: float, g: float, a0: float) -> void:
	var edge := r + ROT_EDGE
	var fold := TAU / ROT_BAYS
	var rim_hi := g + ROT_RIDGE + 0.25   # a ridge at the rim, over the glass's point
	var rim_lo := g + ROT_EAVE + 0.25    # a valley at the rim
	var top := g + 11.9    # a ridge at the oculus
	var low := g + 11.5    # a valley at the oculus
	_mode = M_STONE
	for k in ROT_BAYS:
		var ar := a0 + k * fold
		var av := ar + 0.5 * fold
		var ar2 := ar + fold
		var re := c + Vector2.from_angle(ar) * edge
		var ve := c + Vector2.from_angle(av) * edge
		var re2 := c + Vector2.from_angle(ar2) * edge
		var ri := c + Vector2.from_angle(ar) * ROT_OCULUS
		var vi := c + Vector2.from_angle(av) * ROT_OCULUS
		var ri2 := c + Vector2.from_angle(ar2) * ROT_OCULUS
		var p_re := Vector3(re.x, rim_hi, re.y)
		var p_ve := Vector3(ve.x, rim_lo, ve.y)
		var p_re2 := Vector3(re2.x, rim_hi, re2.y)
		var p_ri := Vector3(ri.x, top, ri.y)
		var p_vi := Vector3(vi.x, low, vi.y)
		var p_ri2 := Vector3(ri2.x, top, ri2.y)
		for f: Array in [[p_re, p_ve, p_vi, p_ri, ROT_FOLD_LIGHT], [p_ve, p_re2, p_ri2, p_vi, ROT_FOLD_DARK]]:
			_rot_up_tri(f[0], f[1], f[2], f[4])
			_rot_up_tri(f[0], f[2], f[3], f[4])
		# The zigzag edge: a white band 0.4 m deep following the folds' ends round the rim.
		var o := Vector3(cos(av), 0, sin(av))
		for e: Array in [[p_re, p_ve], [p_ve, p_re2]]:
			var e0: Vector3 = e[0]
			var e1: Vector3 = e[1]
			_quad(e0 + Vector3.DOWN * 0.4, e1 + Vector3.DOWN * 0.4, e1, e0, o, ROT_TOOTH)
			# its underside, back to the glass (seen from below the overhang)
			var b0 := c + (Vector2(e0.x, e0.z) - c).normalized() * r
			var b1 := c + (Vector2(e1.x, e1.z) - c).normalized() * r
			_quad(Vector3(b0.x, e0.y - 0.4, b0.y), Vector3(b1.x, e1.y - 0.4, b1.y), e1 + Vector3.DOWN * 0.4,
					e0 + Vector3.DOWN * 0.4, Vector3.DOWN, Color("#b9bec2"))
	# The oculus: a metal kerb 1.1 m over the folds, a glazed top in a 4 x 4 grid.
	var ring := _circle(c, ROT_OCULUS, 24)
	_prism(ring, low - 0.1, top + 0.7, ROT_WHITE, Color(0, 0, 0, 0), M_STONE)
	# the kerb's flat white rim round the glass (the drone views: a wide white ring)
	_rot_ring(c, ROT_OCULUS - 0.9, ROT_OCULUS, top + 0.7, ROT_WHITE.darkened(0.03))
	var glass_y := top + 0.7
	_mode = M_GLASS_ROOF
	_cap(_circle(c, ROT_OCULUS - 0.9, 24), glass_y - 0.06, ROT_OCULUS_GLASS)  # set 6 cm into the rim
	_mode = M_STONE
	var oi := ROT_OCULUS - 0.9
	for i in range(1, 4):
		var off := -oi + i * oi * 0.5
		var span := sqrt(oi * oi - off * off) - 0.1
		for d: Vector2 in [Vector2(1, 0), Vector2(0, 1)]:
			var across := Vector2(-d.y, d.x)
			var m := c + across * off
			_prism(PackedVector2Array([m - d * span - across * 0.12, m + d * span - across * 0.12,
					m + d * span + across * 0.12, m - d * span + across * 0.12]),
					glass_y, glass_y + 0.18 + (0.02 if d.x > 0.5 else 0.0), ROT_SILVER, ROT_SILVER, M_STONE, M_STONE)


## A flat ring at y between radii r0 and r1 round c, facing up (the oculus kerb's rim).
func _rot_ring(c: Vector2, r0: float, r1: float, y: float, col: Color) -> void:
	var n := 24
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var i0 := c + Vector2.from_angle(a0) * r0
		var i1 := c + Vector2.from_angle(a1) * r0
		var o0 := c + Vector2.from_angle(a0) * r1
		var o1 := c + Vector2.from_angle(a1) * r1
		_quad(Vector3(i0.x, y, i0.y), Vector3(o0.x, y, o0.y), Vector3(o1.x, y, o1.y), Vector3(i1.x, y, i1.y), Vector3.UP, col)


## The plaza round the Rotunda (F's drone photos and the GUGiK ortho, 2026-11-11): light granite
## crossed by a grid of dark stone bands every 4.8 m, square to Widok Towers (the bands run 65
## degrees off east); the bands stop at the drum, the stair down to the underpass and its planters.
## A row of black bollards along the plaza's south edge by Aleje Jerozolimskie (the street photos).
const ROT_PLAZA_POLY := [Vector2(-835.0, 369.0), Vector2(-812.0, 360.0), Vector2(-784.0, 356.0), Vector2(-761.0, 405.0),
		Vector2(-769.0, 411.0), Vector2(-801.0, 411.5), Vector2(-821.0, 401.0), Vector2(-837.0, 383.0)]
const ROT_PLAZA_BAND := Color("#55585b")
const ROT_PLAZA_STEP := 4.8
const ROT_BOLLARDS := [Vector2(-804.0, 410.6), Vector2(-768.0, 410.2)]


func _rot_plaza(c: Vector2, r: float) -> void:
	var plaza := PackedVector2Array(ROT_PLAZA_POLY)
	var holes: Array[PackedVector2Array] = [_circle(c, r + 0.9, 40)]
	for sk: Dictionary in map._sunk:
		if sk["key"] == "rotunda_stair":
			var grown := Geometry2D.offset_polygon(sk["ring"], 3.4, Geometry2D.JOIN_MITER)
			if not grown.is_empty():
				holes.append(grown[0])
	var u := Vector2.from_angle(deg_to_rad(65.0))
	var v := Vector2(-u.y, u.x)
	_mode = M_STONE
	for dir: Vector2 in [u, v]:
		var across := Vector2(-dir.y, dir.x)
		for k in range(-14, 15):
			var m := c + across * (k * ROT_PLAZA_STEP + 2.4)
			var lines := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([m - dir * 80.0, m + dir * 80.0]), plaza)
			for hole in holes:
				var left: Array[PackedVector2Array] = []
				for ln: PackedVector2Array in lines:
					left.append_array(Geometry2D.clip_polyline_with_polygon(ln, hole))
				lines = left
			var seen := {}
			for ln: PackedVector2Array in lines:
				var key := "%.1f,%.1f" % [(ln[0] + ln[ln.size() - 1]).x, (ln[0] + ln[ln.size() - 1]).y]
				if seen.has(key):
					continue  # the clip can hand back one piece twice
				seen[key] = true
				# The second direction 3 cm over the first: no z-fight where the bands cross.
				_rot_band(ln[0], ln[ln.size() - 1], 0.45, 0.06 if dir == u else 0.09)
	# The bollards: black posts every 1.8 m.
	var a: Vector2 = ROT_BOLLARDS[0]
	var b: Vector2 = ROT_BOLLARDS[1]
	var n := int(a.distance_to(b) / 1.8)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var gy: float = map.terrain_height(p.x, p.y)
		var post := _circle(p, 0.11, 6)
		_prism(post, gy - 0.1, gy + 0.9, Color("#2a2d30"), Color("#3a3e42"), M_STONE, M_STONE)
		_collide(post)


## A dark paving band from a to b, `w` wide, laid `lift` m over the ground in pieces up to 2.5 m.
func _rot_band(a: Vector2, b: Vector2, w: float, lift: float) -> void:
	var length := a.distance_to(b)
	if length < 0.3:
		return
	var d := (b - a) / length
	var side := Vector2(-d.y, d.x) * (w * 0.5)
	var n := maxi(1, ceili(length / 2.5))
	for k in n:
		var p0 := a + d * (length * k / n)
		var p1 := a + d * (length * (k + 1) / n)
		var h0: float = map.terrain_height(p0.x, p0.y) + lift
		var h1: float = map.terrain_height(p1.x, p1.y) + lift
		_quad(Vector3((p0 - side).x, h0, (p0 - side).y), Vector3((p1 - side).x, h1, (p1 - side).y),
				Vector3((p1 + side).x, h1, (p1 + side).y), Vector3((p0 + side).x, h0, (p0 + side).y), Vector3.UP, ROT_PLAZA_BAND)


## A roof triangle with its normal pointing up (a fold's facet).
func _rot_up_tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	_tri(a, b, c, n, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## An entrance facing `d`: `bays` dark glass doors (centred on d) to 3.2 m, a silver transom
## over them, and a flat canopy `wide` by `deep` at `at` m.
func _rot_door(c: Vector2, r: float, g: float, d: Vector2, bays: int, wide: float, deep: float, at: float) -> void:
	var step := TAU / ROT_BAYS
	var mid := d.angle()
	var first := mid - 0.5 * bays * step
	_mode = M_STONE
	for k in bays:
		var p0 := c + Vector2.from_angle(first + k * step) * (r + 0.1)
		var p1 := c + Vector2.from_angle(first + (k + 1) * step) * (r + 0.1)
		var o := Vector2.from_angle(first + (k + 0.5) * step)
		var n := Vector3(o.x, 0, o.y)
		_quad(Vector3(p0.x, g + 0.3, p0.y), Vector3(p1.x, g + 0.3, p1.y), Vector3(p1.x, g + 3.2, p1.y), Vector3(p0.x, g + 3.2, p0.y),
				n, Color("#2e3a39"))
		var q0 := c + Vector2.from_angle(first + k * step) * (r + 0.22)
		var q1 := c + Vector2.from_angle(first + (k + 1) * step) * (r + 0.22)
		_quad(Vector3(q0.x, g + 3.2, q0.y), Vector3(q1.x, g + 3.2, q1.y), Vector3(q1.x, g + 3.5, q1.y), Vector3(q0.x, g + 3.5, q0.y),
				n, ROT_SILVER)
	var t := Vector2(-d.y, d.x)
	var near := c + d * (r - 0.4)
	var far := c + d * (r + deep)
	_prism(PackedVector2Array([near - t * wide * 0.5, near + t * wide * 0.5, far + t * wide * 0.5, far - t * wide * 0.5]),
			g + at, g + at + 0.3, Color("#eef0f1"), Color("#e2e5e7"), M_STONE, M_STONE)


# --- Rondo Dmowskiego (F's photos and the city's traffic plan, 2026-11-02) ---------------------

## The roundabout where Marszałkowska crosses Al. Jerozolimskie, over the underpass to Metro
## Centrum (spec docs/landmarks/specs/rondo-dmowskiego.md). The map has the ring, the tram cross through
## the middle, the four lawns between the tracks and twelve walled stairwells; this site dresses
## them like the real place (F's aerials, 2026-11-02):
##  - the island: light granite paving with three wide mid-grey concentric bands round the tram
##    cross, in each quarter a long bent bed of dark planting with a red and a yellow ribbon of
##    flowers and a short inner bed of clipped shrubs, both chevrons with rounded ends in a low
##    granite kerb (F's aerial and Fable's critique, 2026-11-26); no trees (tree_free);
##  - the underpass stairs: open stairwells since the 2020s renovation (F's street views,
##    2026-11-25): a granite coping, a dark steel balustrade, a red M post at the mouth, a glass
##    lift and a planted bed by four of them (the 1990s blue tubes are gone);
##  - (the Patelnia's murals are patelnia.gd's since 2026-11-13).
## The PRASA kiosk, the ice-cream cart and the east tram stop's shelter are street details
## (tools/bake_street_details.py RONDO). The zone is two 0.2 m squares at the corners of it all
## (RONDO_BOX), so nothing mapped is dropped and every sector the pieces reach builds them.
const RONDO_C := Vector2(-836.36, 461.05)
const RONDO_U := Vector2(0.33738, 0.94137)    # along Marszałkowska, south
const RONDO_V := Vector2(0.94258, -0.33399)   # along Al. Jerozolimskie, east
const RONDO_TRACK := 4.0                      # half the tram cross's width (ballast 3 m and a kerb strip)
const RONDO_PAVING := Color("#c8c4ba")
const RONDO_BAND := Color("#a39f96")
const RONDO_KERB := Color("#b4b0a8")
const RONDO_SHRUB := Color("#4a6a3a")
const RONDO_HEDGE := Color("#3b5a40")
const RONDO_RED := Color("#b23a2e")
const RONDO_YELLOW := Color("#d6b23a")
const METRO_RED := Color("#c8171f")
## The stairwells (centrum.json `steps` with their walled outlines, `lines` k wall): centre x, z, the
## way up (to the open mouth), length and width of the walled well.
const RONDO_WELLS := [
	[-780.2, 473.9, 0.821, -0.570, 8.8, 4.6], [-850.1, 514.7, 0.357, 0.934, 9.3, 5.6],
	[-794.8, 418.0, 0.999, -0.046, 8.7, 6.0], [-789.5, 490.9, 0.038, 0.999, 8.6, 5.6],
	[-815.5, 412.9, -0.618, -0.786, 9.1, 6.3], [-862.0, 415.4, -0.011, -1.000, 9.6, 4.3],
	[-793.6, 438.3, 0.991, -0.130, 8.7, 5.9], [-876.5, 484.6, -1.000, 0.012, 9.1, 3.9],
	[-810.9, 499.4, 0.110, 0.994, 8.6, 4.0], [-884.4, 405.2, -0.204, -0.979, 8.7, 5.4],
	[-881.5, 429.3, -0.083, 0.997, 9.6, 5.8], [-864.4, 503.9, -0.996, -0.091, 8.9, 5.7],
]


## The zone's two 0.2 m squares: the north-west and south-east corners of everything the site
## builds (the mural's far end, the south-east stairs), so its box covers it all.
const RONDO_BOX := [Vector2(-937.0, 370.0), Vector2(-770.0, 575.0)]
func _find_rondo() -> void:
	var zone: Array = []
	for a: Vector2 in RONDO_BOX:
		zone.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("rondo", zone)
	tree_free.append([RONDO_C, 27.5])
	# The square by the Empik pavilion has its own young trees (_build_square): the laser scan's
	# old crowns over the car park go.
	tree_free.append([Vector2(-866.0, 528.0), 24.0])


func _build_rondo(_site: Dictionary) -> void:
	_no_roof = true
	_rondo_island()
	_rondo_arms()
	var carriage := _rondo_carriage()
	for i in RONDO_WELLS.size():
		_rondo_well(i, carriage)
	_build_square()
	_no_roof = false


## The island's edge at angle `ang` in a quarter: 25.2 m at the tracks,
## 26.8 m on the diagonals (just over the mapped lawns' outline, 24.8-26.6 m).
func _rondo_r(ang: float) -> float:
	var s := sin(2.0 * ang)
	return 25.2 + 1.6 * s * s


## A point of quarter (sv, su) in the island's frame (v east, u south) at (v, u) >= 0.
func _rondo_p(q: Vector2, v: float, u: float) -> Vector2:
	return RONDO_C + RONDO_V * (v * q.x) + RONDO_U * (u * q.y)


## A polygon of quarter `q` from local (v, u) points, counter-clockwise in the plan.
func _rondo_poly(q: Vector2, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(_rondo_p(q, p.x, p.y))
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	return out


## The quarter between the tracks out to the edge, as local points (v, u).
func _rondo_quarter_local(r_scale := 1.0, inset := 0.0) -> Array:
	var pts: Array = [Vector2(RONDO_TRACK + inset, RONDO_TRACK + inset)]
	for k in 13:
		var ang := PI * 0.5 * float(k) / 12.0
		var r := _rondo_r(ang) * r_scale - inset
		var p := Vector2(cos(ang), sin(ang)) * r
		pts.append(Vector2(maxf(p.x, RONDO_TRACK + inset), maxf(p.y, RONDO_TRACK + inset)))
	return pts


func _rondo_island() -> void:
	_id = 0
	_g = map.terrain_height(RONDO_C.x, RONDO_C.y)
	var g := _g
	_mode = M_STONE
	var quarters := [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for qi in 4:
		var q: Vector2 = quarters[qi]
		# Light granite paving over the mapped lawn, then three wide mid-grey concentric bands
		# (F's aerial, Fable's critique 2026-11-26), clipped to the quarter.
		var quarter := _rondo_poly(q, _rondo_quarter_local())
		_cap(quarter, g + 0.18, RONDO_PAVING)
		for band: Vector2 in [Vector2(6.0, 8.4), Vector2(12.6, 14.2), Vector2(21.2, 23.4)]:
			var ring_out := PackedVector2Array()
			var ring_in := PackedVector2Array()
			for k in 13:
				var ang := PI * 0.5 * float(k) / 12.0
				ring_out.append(_rondo_p(q, cos(ang) * band.y, sin(ang) * band.y))
				ring_in.append(_rondo_p(q, cos(ang) * band.x, sin(ang) * band.x))
			ring_in.reverse()
			var strip := ring_out + ring_in
			if Geometry2D.is_polygon_clockwise(strip):
				strip.reverse()
			for piece in Geometry2D.intersect_polygons(strip, quarter):
				if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
					_cap(piece, g + 0.21, RONDO_BAND)
		# The long bent bed: dark planting in a low granite kerb, bulging out on the diagonal (a
		# chevron with rounded ends), with a red and a yellow ribbon of flowers along it.
		var bed := _rondo_poly(q, _rondo_bent(17.3, 5.2, 1.4, 0.30, 1.27))
		_prism(bed, g, g + 0.32, RONDO_KERB.darkened(0.08), RONDO_KERB, M_STONE, M_STONE)
		for p in Geometry2D.offset_polygon(bed, -0.35, Geometry2D.JOIN_ROUND):
			if p.size() >= 3 and not Geometry2D.is_polygon_clockwise(p):
				_prism(p, g + 0.32, g + 0.5, RONDO_SHRUB.darkened(0.2), RONDO_SHRUB, M_STONE, M_STONE)
		var red := _rondo_poly(q, _rondo_bent(18.4, 1.4, 1.4, 0.36, 1.21))
		_prism(red, g + 0.5, g + 0.56, RONDO_RED.darkened(0.2), RONDO_RED, M_STONE, M_STONE)
		var yellow := _rondo_poly(q, _rondo_bent(16.1, 1.2, 1.4, 0.40, 1.17))
		_prism(yellow, g + 0.5, g + 0.56, RONDO_YELLOW.darkened(0.2), RONDO_YELLOW, M_STONE, M_STONE)
		# The short inner bed: clipped dark shrubs in the same kerb.
		var small := _rondo_poly(q, _rondo_bent(10.4, 3.4, 0.9, 0.46, 1.11))
		_prism(small, g, g + 0.32, RONDO_KERB.darkened(0.08), RONDO_KERB, M_STONE, M_STONE)
		for p in Geometry2D.offset_polygon(small, -0.3, Geometry2D.JOIN_ROUND):
			if p.size() >= 3 and not Geometry2D.is_polygon_clockwise(p):
				_prism(p, g + 0.32, g + 0.78, RONDO_HEDGE.darkened(0.15), RONDO_HEDGE, M_STONE, M_STONE)


## A bent bed over a quarter as local (v, u) points: its middle line at radius `rc` plus `bulge` on
## the diagonal (sin 2a), from angle a0 to a1, `wide` m across, the ends rounded (the width eases
## to nothing over the last eighth).
func _rondo_bent(rc: float, wide: float, bulge: float, a0: float, a1: float) -> Array:
	var outer: Array = []
	var inner: Array = []
	var n := 18
	for k in n + 1:
		var t := float(k) / float(n)
		var a := lerpf(a0, a1, t)
		var r := rc + bulge * sin(2.0 * a)
		var e := clampf(minf(t, 1.0 - t) / 0.125, 0.0, 1.0)
		var hw := wide * 0.5 * sqrt(1.0 - (1.0 - e) * (1.0 - e))
		outer.append(Vector2(cos(a), sin(a)) * (r + hw))
		inner.append(Vector2(cos(a), sin(a)) * (r - hw))
	inner.reverse()
	var out: Array = []
	for p: Vector2 in outer + inner:
		if out.is_empty() or (out[out.size() - 1] as Vector2).distance_to(p) > 0.05:
			out.append(p)
	return out


## The rondo's arm islands (the mapped lawns between the carriageways and the tracks on the four
## arms, by their middles): real ones are dark planted beds in a granite kerb with a serpentine
## ribbon of flowers (F's satellite views, 2026-11-25; not plain lawn), yellow or red by arm.
const RONDO_ARM_BEDS := [
	[Vector2(-845.9, 407.8), 0], [Vector2(-907.2, 476.2), 1], [Vector2(-787.3, 454.6), 1], [Vector2(-822.8, 521.6), 0],
]
## Within this many metres of the rondo's middle, a mapped lawn wedge a stairwell stands in is
## paved over (the real wells stand in granite paving; F's street views).
const RONDO_PAVED_REACH := 80.0
func _rondo_arms() -> void:
	_mode = M_STONE
	var wells: Array[PackedVector2Array] = []
	for w: Array in RONDO_WELLS:
		var c := Vector2(float(w[0]), float(w[1]))
		var up := Vector2(float(w[2]), float(w[3]))
		var side := Vector2(-up.y, up.x)
		var hl := float(w[4]) * 0.5 + 0.4
		var hw := float(w[5]) * 0.5 + 0.4
		var ring := PackedVector2Array([c - up * hl - side * hw, c + up * hl - side * hw, c + up * hl + side * hw, c - up * hl + side * hw])
		if Geometry2D.is_polygon_clockwise(ring):
			ring.reverse()
		wells.append(ring)
	for ar in data.get("areas", []):
		var k: String = ar.get("k", "")
		if k != "park" and k != "grass":
			continue
		var q := _pts(ar["p"])
		if q.size() < 3:
			continue
		var mid := _centre(q)
		if mid.distance_to(RONDO_C) > RONDO_PAVED_REACH or mid.distance_to(RONDO_C) < 28.0:
			continue
		if Geometry2D.is_polygon_clockwise(q):
			q.reverse()
		var bed := -1
		for b: Array in RONDO_ARM_BEDS:
			if (b[0] as Vector2).distance_to(mid) < 3.0:
				bed = int(b[1])
		if bed >= 0:
			_rondo_arm_bed(q, bed)
			continue
		var holes: Array = []
		for wr in wells:
			if not Geometry2D.intersect_polygons(wr, q).is_empty():
				holes.append(wr)
		if holes.is_empty():
			continue
		var pieces: Array = [q]
		for h: PackedVector2Array in holes:
			var next: Array = []
			for pc: PackedVector2Array in pieces:
				next.append_array(Geometry2D.clip_polygons(pc, h))
			pieces = next
		for pc: PackedVector2Array in pieces:
			if pc.size() >= 3 and not Geometry2D.is_polygon_clockwise(pc):
				_drape_cap(pc, 0.12, RONDO_PAVING)


## One arm bed over the mapped island `q`: a granite kerb 0.3 m high, dark planting 0.4 m in, and a
## serpentine ribbon of flowers (1.3 m wide, yellow or red) winding along the island's long axis.
func _rondo_arm_bed(q: PackedVector2Array, tint: int) -> void:
	_drape_prism(q, 0.3, RONDO_KERB.darkened(0.08), RONDO_KERB)
	var inner := Geometry2D.offset_polygon(q, -0.45, Geometry2D.JOIN_MITER)
	# The long axis: the island's longest edge.
	var along := Vector2.RIGHT
	var best := 0.0
	for i in q.size():
		var e := q[(i + 1) % q.size()] - q[i]
		if e.length() > best:
			best = e.length()
			along = e.normalized()
	var across := Vector2(-along.y, along.x)
	var mid := _centre(q)
	var lo := INF
	var hi := -INF
	var wlo := INF
	var whi := -INF
	for p in q:
		lo = minf(lo, (p - mid).dot(along))
		hi = maxf(hi, (p - mid).dot(along))
		wlo = minf(wlo, (p - mid).dot(across))
		whi = maxf(whi, (p - mid).dot(across))
	var amp := clampf((whi - wlo) * 0.22, 0.6, 3.0)
	var off := (whi + wlo) * 0.5
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := maxi(8, int((hi - lo) / 1.5))
	for k in n + 1:
		var s := lerpf(lo, hi, float(k) / float(n))
		var c := mid + along * s + across * (off + amp * sin(s / 4.5))
		left.append(c + across * 0.65)
		right.append(c - across * 0.65)
	right.reverse()
	var ribbon := left + right
	if Geometry2D.is_polygon_clockwise(ribbon):
		ribbon.reverse()
	for p in inner:
		if p.size() < 3 or Geometry2D.is_polygon_clockwise(p):
			continue
		_drape_prism(p, 0.48, RONDO_SHRUB.darkened(0.1), RONDO_SHRUB)
		for piece in Geometry2D.intersect_polygons(ribbon, p):
			if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
				_drape_cap(piece, 0.53, RONDO_YELLOW if tint == 0 else RONDO_RED)


## A flat top over `poly` draped on the terrain `lift` m over it: cut into DRAPE_CELL m cells,
## each piece triangulated with its corners at the ground's height there (a square or a long
## island falls 0.5-1 m across, so one flat cap would sink at one end and float at the other).
const DRAPE_CELL := 3.0
func _drape_cap(poly: PackedVector2Array, lift: float, col: Color) -> void:
	var box := _box_of([poly])
	var x := floorf(box.position.x / DRAPE_CELL) * DRAPE_CELL
	while x < box.end.x:
		var z := floorf(box.position.y / DRAPE_CELL) * DRAPE_CELL
		while z < box.end.y:
			var cell := PackedVector2Array([Vector2(x, z), Vector2(x + DRAPE_CELL, z), Vector2(x + DRAPE_CELL, z + DRAPE_CELL), Vector2(x, z + DRAPE_CELL)])
			for piece in Geometry2D.intersect_polygons(poly, cell):
				if piece.size() < 3 or Geometry2D.is_polygon_clockwise(piece):
					continue
				var idx := Geometry2D.triangulate_polygon(piece)
				for i in range(0, idx.size(), 3):
					var a := piece[idx[i]]
					var b := piece[idx[i + 1]]
					var c := piece[idx[i + 2]]
					if absf((b - a).cross(c - a)) < 0.001:
						continue
					_tri(_dv(a, lift), _dv(b, lift), _dv(c, lift), Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
			z += DRAPE_CELL
		x += DRAPE_CELL


## A point on the terrain `lift` m up.
func _dv(p: Vector2, lift: float) -> Vector3:
	return Vector3(p.x, map.terrain_height(p.x, p.y) + lift, p.y)


## A low draped slab: walls round `poly` from 0.3 m under the terrain to `lift` over it, the top
## draped (`_drape_cap`). A kerb, a bed, a paved island on sloping ground.
func _drape_prism(poly: PackedVector2Array, lift: float, wall: Color, top: Color) -> void:
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	_drape_walls(poly, lift, wall)
	_drape_cap(poly, lift, top)


## The walls round `poly` from 0.3 m under the terrain to `lift` over it.
func _drape_walls(poly: PackedVector2Array, lift: float, wall: Color) -> void:
	if Geometry2D.is_polygon_clockwise(poly):
		poly = poly.duplicate()
		poly.reverse()
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var o := _out(poly, a, b)
		_quad(_dv(a, -0.3), _dv(b, -0.3), _dv(b, lift), _dv(a, lift), Vector3(o.x, 0.0, o.y), wall)


# --- The square by the Empik pavilion ("Zielona metamorfoza", F 2026-11-25) --------------------

## The city's plan for the car park between the Cepelia pavilion (the game's EMPIRYK) and Hotel
## Metropol (the game's METROPOLKA), from its "Tak będzie" renders (F's pictures, 2026-11-25; the
## city page itself was not reachable from the cloud): one square of light grey slabs; the big
## rounded lawn island with trees at the pavilion's north end (the mapped lawn there); two rows of
## rectangular tree beds between the pavilion and the slab block; café tables by the block's shops;
## an advertising column; the two underpass stairs kept open. Built with the rondo's site (its
## box covers it). Local frame: along Marszałkowska (south), across it (east), from the Metropol
## front's north end.
const SQ_O := Vector2(-886.0, 511.0)
const SQ_PAVE := Color("#c8c4ba")
const SQ_LAWN := Color("#5c8a44")
const SQ_EDGE := Color("#b4b0a8")
const SQ_LEAF := [Color("#6f8a3a"), Color("#7d8f45"), Color("#5f7a3a")]
## The square's outline (world x, z): the Metropol front, the ring road's pavement edge, the
## pavilion's north end and west side.
const SQ_RING := [
	Vector2(-892.5, 507.5), Vector2(-860.5, 503.5), Vector2(-851.5, 509.0), Vector2(-843.5, 519.0),
	Vector2(-838.5, 528.0), Vector2(-836.0, 538.5), Vector2(-857.5, 540.5), Vector2(-861.5, 553.0),
	Vector2(-878.0, 553.0),
]
## The tree beds in the local frame: [along from, along to, across from, across to, trees].
const SQ_BEDS := [
	[17.0, 26.0, 6.5, 9.5, 2], [29.0, 38.0, 6.5, 9.5, 2],
	[5.0, 13.0, 12.0, 15.0, 2], [16.0, 24.0, 12.5, 15.5, 2], [27.0, 34.0, 13.0, 16.0, 1],
]
func _build_square() -> void:
	var ring := PackedVector2Array(SQ_RING)
	if Geometry2D.is_polygon_clockwise(ring):
		ring.reverse()
	# The passage up the Metropol front to the pavilion's south end (the mapped `construction`
	# outline there is self-touching and does not merge cleanly, so a clean strip in the passage's
	# frame: from the front, 0.3 m off, across to the pavilion; the plinth cut below trims it).
	var strip := PackedVector2Array()
	for uv: Vector2 in [Vector2(-3.0, 0.3), Vector2(40.0, 0.3), Vector2(40.0, 21.0), Vector2(-3.0, 21.0)]:
		strip.append(PS_O + PS_U * uv.x + PS_V * uv.y)
	if Geometry2D.is_polygon_clockwise(strip):
		strip.reverse()
	var outer: Array = []
	for m: PackedVector2Array in Geometry2D.merge_polygons(ring, strip):
		if not Geometry2D.is_polygon_clockwise(m):
			outer.append(m)
	if not outer.is_empty():
		ring = _largest(outer)
	# Less the pavilion's plinth, which splits it: the square and the passage up the Metropol
	# front, and the strip south of the pavilion (every piece is kept).
	var rings: Array = [ring]
	var cep := _landmark(CEP_OSM)
	if cep.size() >= 3:
		var plinth := _largest(Geometry2D.offset_polygon(cep, 2.2, Geometry2D.JOIN_MITER))
		rings.clear()
		for p: PackedVector2Array in Geometry2D.clip_polygons(ring, plinth):
			if not Geometry2D.is_polygon_clockwise(p) and absf(_area(p)) > 12.0:
				rings.append(p)
	_mode = M_STONE
	_o = SQ_O
	_a = RONDO_U
	_b = RONDO_V
	# Holes: the two stairwells and the big lawn island (built on its own below).
	var holes: Array = []
	for i in [1, 11]:
		var w: Array = RONDO_WELLS[i]
		var c := Vector2(float(w[0]), float(w[1]))
		var up := Vector2(float(w[2]), float(w[3]))
		var sd := Vector2(-up.y, up.x)
		var hl := float(w[4]) * 0.5 + 0.4
		var hw := float(w[5]) * 0.5 + 0.4
		holes.append(PackedVector2Array([c - up * hl - sd * hw, c - up * hl + sd * hw, c + up * hl + sd * hw, c + up * hl - sd * hw]))
	var island := PackedVector2Array()
	for ar in data.get("areas", []):
		if str(ar.get("k", "")) != "grass":
			continue
		var q := _pts(ar["p"])
		if q.size() >= 3 and _centre(q).distance_to(Vector2(-856.8, 530.6)) < 3.0:
			island = q
	var pieces: Array = rings
	for h in holes + ([island] if island.size() >= 3 else []):
		var hp: PackedVector2Array = h
		if Geometry2D.is_polygon_clockwise(hp):
			hp.reverse()
		var next: Array = []
		for p: PackedVector2Array in pieces:
			next.append_array(Geometry2D.clip_polygons(p, hp))
		pieces = next
	for p: PackedVector2Array in pieces:
		if p.size() >= 3 and not Geometry2D.is_polygon_clockwise(p):
			_drape_cap(p, 0.18, SQ_PAVE)  # over the old service lane's asphalt
	# Its kerb on the outer edge only (a hole's clip leaves a bridge edge inside a piece, whose two
	# walls would overlap; the holes' own edges are the beds' and the wells' walls).
	for r: PackedVector2Array in rings:
		_drape_walls(r, 0.18, SQ_EDGE.darkened(0.1))
	# The big lawn island: a granite edge, the lawn, five trees and two shrub clumps.
	if island.size() >= 3:
		var isl := Geometry2D.offset_polygon(island, 1.0, Geometry2D.JOIN_ROUND)
		for p in isl:
			if p.size() >= 3 and not Geometry2D.is_polygon_clockwise(p):
				_drape_prism(p, 0.35, SQ_EDGE.darkened(0.08), SQ_EDGE)
				for l in Geometry2D.offset_polygon(p, -0.4, Geometry2D.JOIN_ROUND):
					if l.size() >= 3 and not Geometry2D.is_polygon_clockwise(l):
						_drape_cap(l, 0.4, SQ_LAWN)
		var ic := _centre(island)
		for k in 5:
			var t := Vector2.from_angle(float(k) * TAU / 5.0 + 0.4) * (3.4 if k % 2 == 0 else 5.0)
			_sq_tree(ic + t, k)
		for k in 2:
			var s := ic + Vector2.from_angle(float(k) * PI + 1.3) * 2.0
			_frustum(_circle(s, 1.3, 6), map.terrain_height(s.x, s.y) + 0.35, _circle(s, 0.7, 6), map.terrain_height(s.x, s.y) + 1.3, RONDO_SHRUB)
	# The rows of tree beds between the pavilion and the block.
	for b: Array in SQ_BEDS:
		var bed := _urect(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
		# 0.31 / 0.37: the first bed's corner runs under the lawn island's edge (0.35 / 0.4).
		_drape_prism(bed, 0.31, SQ_EDGE.darkened(0.08), SQ_EDGE)
		_drape_cap(_urect(float(b[0]) + 0.3, float(b[1]) - 0.3, float(b[2]) + 0.3, float(b[3]) - 0.3), 0.37, SQ_LAWN)
		var n := int(b[4])
		for k in n:
			var u := lerpf(float(b[0]), float(b[1]), (float(k) + 0.5) / float(n))
			_sq_tree(_w(u, (float(b[2]) + float(b[3])) * 0.5), k + int(b[0]))
	# The café terrace by the block's shops: tables under cream umbrellas.
	var cafe: Array[Vector2] = []
	for k in 4:
		cafe.append(_w(5.0 + 2.6 * float(k), 3.0))
	for p in cafe:
		_umbrella(p, 0.0, map.terrain_height(p.x, p.y) + 0.18, Color("#efe6cf"))  # (moves the frame)
	# The advertising column by the corner (a 1.2 m drum, 2.8 m, a dark cap).
	var col := Vector2(-841.0, 531.0)
	var cg: float = map.terrain_height(col.x, col.y)
	_prism(_circle(col, 0.6, 10), cg, cg + 2.6, Color("#e9e2cf"), Color(0, 0, 0, 0), M_STONE)
	_prism(_circle(col, 0.7, 10), cg + 2.6, cg + 2.85, Color("#3a4a3f"), Color("#3a4a3f"), M_STONE, M_STONE)
	_build_passage()


## The passage between the Empik pavilion and Hotel Metropol (F, 2026-11-26: "model this street
## between the Empik and the building"): the old service lane, now in the square's paving (the
## construction outline the square covers runs up it), with a row of three planted beds down its
## middle, two trees each, a timber seat on each bed's west kerb, and three lamps on the pavilion
## side. Local frame: from the Metropol front's south-east corner, along the front (u, south) and
## across to the pavilion (v, about 20 m).
const PS_O := Vector2(-877.1, 552.7)
const PS_U := Vector2(0.354, 0.935)
const PS_V := Vector2(0.935, -0.354)
const PS_WOOD := Color("#8a6a48")
func _build_passage() -> void:
	_o = PS_O
	_a = PS_U
	_b = PS_V
	_mode = M_STONE
	for k in 3:
		var u0 := 5.0 + 9.5 * float(k)
		var u1 := u0 + 6.5
		var bed := _urect(u0, u1, 7.5, 10.5)
		_drape_prism(bed, 0.4, SQ_EDGE.darkened(0.08), SQ_EDGE)
		_drape_cap(_urect(u0 + 0.3, u1 - 0.3, 7.8, 10.2), 0.45, SQ_LAWN)
		for t in 2:
			_sq_tree(_w(lerpf(u0, u1, 0.27 + 0.46 * float(t)), 9.0), 31 + 2 * k + t)
		# A timber seat on the bed's kerb (Metropol side), 0.48 m.
		var sc := _w((u0 + u1) * 0.5, 7.25)
		var sg: float = map.terrain_height(sc.x, sc.y)
		_lbox((u0 + u1) * 0.5, 7.25, 2.4, 0.3, sg + 0.1, sg + 0.48, PS_WOOD.darkened(0.15), M_STONE, PS_WOOD)
	# Three lamps on the pavilion side: a 5 m grey mast, a flat head over the passage.
	for k in 3:
		var u := 7.0 + 12.0 * float(k)
		var p := _w(u, 15.5)
		var g: float = map.terrain_height(p.x, p.y)
		_beam(Vector3(p.x, g, p.y), Vector3(p.x, g + 5.0, p.y), 0.07, Color("#7c8186"), false)
		_mode = M_LAMP
		_lbox(u, 14.9, 0.22, 0.7, g + 4.9, g + 5.08, Color("#5b5f66"), M_LAMP, Color("#5b5f66"))
		_mode = M_STONE


## One of the square's young trees at `p` (seed `k` picks the height and the olive shade): a
## trunk and a two-tier crown, 5-6.5 m, crown at most 2 m across (simple for performance).
func _sq_tree(p: Vector2, k: int) -> void:
	var g: float = map.terrain_height(p.x, p.y) + 0.4
	var h := 5.0 + 1.5 * fmod(absf(float(k) * 0.618), 1.0)
	_prism(_square(p, 0.12), g, g + h * 0.42, Color("#5a4632"), Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	var leaf: Color = SQ_LEAF[absi(k) % SQ_LEAF.size()]
	_frustum(_circle(p, 0.6, 6), g + h * 0.32, _circle(p, 1.9, 6), g + h * 0.62, leaf.darkened(0.12))
	_frustum(_circle(p, 1.9, 6), g + h * 0.62, _circle(p, 0.7, 6), g + h, leaf, leaf.lightened(0.08))


## One of the underpass's open stairwells, `w` a RONDO_WELLS row (F, 2026-11-26: the first pass's
## slabs read as big fences round small stairs). The real ones since the 2020s renovation (F's
## street views, 2026-11-25): an open well in the paving, a coping on its edge and a dark steel
## railing on it, the stair going 3.5 m down to the passage. The well itself is map_builder.gd's
## SUNKEN `rondo_w<i>` (the drop, treads, coping, railing, collision: site `rondo_wells`); the
## mapped walls on its ring are left out (typed `balustrade_rail` too, streets.json place
## "rondo-dmowskiego-wells", for any piece off the ring). The site adds only what the map has not:
## a red M post at the mouth, and on three wells a glass lift on the long side, wherever that side
## is clear of the carriageway and the other wells (F's photos: beside the stair, not over it).
const WELL_COPING := Color("#b1aea6")
const WELL_STEEL := Color("#2a2e33")
const WELL_GLASS := Color("#b8d2db")
const WELL_GRASS := Color("#7a8a46")
## The wells (RONDO_WELLS index) with a lift (a guess from F's two street views, docs/QUESTIONS.md
## 2026-11-26). Not well 9: Widok's rebuilt kerb (road design area `widok`) runs past both its long
## sides closer than the map's `carriage` outlines say, and a lift there stood on the road.
const RONDO_LIFTS := [0, 1, 5]
func _rondo_well(i: int, carriage: Array) -> void:
	var w: Array = RONDO_WELLS[i]
	var c := Vector2(float(w[0]), float(w[1]))
	var up := Vector2(float(w[2]), float(w[3]))
	var side := Vector2(-up.y, up.x)
	var half := float(w[4]) * 0.5
	var hw := float(w[5]) * 0.5
	_g = map.terrain_height(c.x, c.y)
	var g := _g
	_mode = M_STONE
	# The M post at the mouth's right: a 3.2 m pole, a red square with a white M on both faces.
	var foot := c + up * (half + 0.9) + side * (hw + 0.6)
	_beam(Vector3(foot.x, g, foot.y), Vector3(foot.x, g + 2.72, foot.y), 0.08, Color("#5b5f66"), false)
	_o = foot
	_a = side
	_b = up
	_mode = M_LAMP
	_lbox(0.0, 0.0, 0.42, 0.05, g + 2.7, g + 3.54, METRO_RED, M_LAMP, METRO_RED)
	for face: float in [-1.0, 1.0]:
		_rondo_m(foot, side, up * face, g + 3.12)
	_mode = M_STONE
	if i in RONDO_LIFTS:
		_rondo_lift(c, up, half, hw, carriage)


## The glass lift beside a well: a 1.8 m cabin of pale glass in a dark frame, 2.9 m, a dark roof,
## and a low bed of grasses at its foot; on whichever long side is clear (no carriageway within
## 2.6 m, no other well), else none.
func _rondo_lift(c: Vector2, up: Vector2, half: float, hw: float, carriage: Array) -> void:
	var side := Vector2(-up.y, up.x)
	for sx: float in [1.0, -1.0]:
		var at := c - up * (half * 0.35) + side * sx * (hw + 2.2)
		var clear := true
		for poly: PackedVector2Array in carriage:
			if Geometry2D.is_point_in_polygon(at, poly):
				clear = false
				break
			for k in 8:
				if Geometry2D.is_point_in_polygon(at + Vector2.from_angle(TAU * k / 8.0) * 2.6, poly):
					clear = false
					break
			if not clear:
				break
		for w: Array in RONDO_WELLS:
			if Vector2(float(w[0]), float(w[1])).distance_to(at) < 5.0 and Vector2(float(w[0]), float(w[1])) != c:
				clear = false
		# The roads' own ribbons too (the carriage outlines miss some kerb lanes): half the width
		# and 2.4 m from the centre line.
		for r: Array in _rondo_roads:
			var rp: PackedVector2Array = r[0]
			for k in rp.size() - 1:
				var q := Geometry2D.get_closest_point_to_segment(at, rp[k], rp[k + 1])
				if q.distance_to(at) < float(r[1]) * 0.5 + 2.4:
					clear = false
					break
			if not clear:
				break
		if not clear:
			continue
		var g: float = map.terrain_height(at.x, at.y)
		_o = at
		_a = up
		_b = side
		_lbox(0.0, 0.0, 0.9, 0.9, g, g + 2.9, WELL_GLASS, M_STONE, WELL_GLASS)
		_lbox(0.0, 0.0, 0.98, 0.98, g + 2.9, g + 3.1, WELL_STEEL, M_STONE, WELL_STEEL.lightened(0.1))
		for cu: float in [-0.92, 0.92]:
			for cv: float in [-0.92, 0.92]:
				_lbox(cu, cv, 0.05, 0.05, g, g + 2.9, WELL_STEEL, M_STONE, WELL_STEEL)
		_lbox(-2.0, 0.0, 0.9, 0.8, g - 0.1, g + 0.32, WELL_COPING.darkened(0.08), M_STONE, WELL_GRASS)
		_collide(_rect(0.0, 0.0, 1.0, 1.0))
		return


## The roads near the rondo, [points, width] (for the lifts' clearance; _rondo_carriage fills it).
var _rondo_roads: Array = []
## The carriageway outlines within 110 m of the rondo (for the lifts' clearance).
func _rondo_carriage() -> Array:
	var out: Array = []
	_rondo_roads.clear()
	for rd in data.get("roads", []):
		if str(rd.get("k", "")) in ["foot", "footway", "path", "steps", "pedestrian", "cycleway"]:
			continue
		var rp := _pts(rd["p"])
		if rp.size() < 2:
			continue
		for q in rp:
			if q.distance_to(RONDO_C) < 140.0:
				_rondo_roads.append([rp, float(rd.get("w", 6.0))])
				break
	for cw in data.get("carriage", []):
		var q := _pts(cw["p"])
		if q.size() < 3:
			continue
		for p in q:
			if p.distance_to(RONDO_C) < 140.0:
				out.append(q)
				break
	return out


## A white M (five strokes) on the red square at `c`, facing `n` (plan), its middle at `y`.
func _rondo_m(c: Vector2, along: Vector2, n: Vector2, y: float) -> void:
	var white := Color("#fbf7ee")
	var nrm := Vector3(n.x, 0.0, n.y)
	var strokes := [[-0.24, -0.24, -0.24, 0.24], [0.24, -0.24, 0.24, 0.24], [-0.24, 0.24, 0.0, 0.02], [0.24, 0.24, 0.0, 0.02]]
	_mode = M_LAMP
	for i in strokes.size():
		var s: Array = strokes[i]
		# The uprights 3.5 cm off the plate, the diagonals 3 cm further (no shared planes).
		var p := c + n * (0.085 if i < 2 else 0.115)
		var a := p + along * float(s[0])
		var b := p + along * float(s[2])
		var ya := y + float(s[1])
		var yb := y + float(s[3])
		var d3 := Vector3(b.x - a.x, yb - ya, b.y - a.y).normalized()
		var off := d3.cross(nrm).normalized() * 0.045
		var pa := Vector3(a.x, ya, a.y)
		var pb := Vector3(b.x, yb, b.y)
		_quad(pa - off, pb - off, pb + off, pa + off, nrm, white)


# --- Sunken places: the Patelnia and the Rotunda's stair (F's aerial, 2026-11-05) -------------

## map_builder.gd SUNKEN lowers the ground of each ring (terrain_height and the drawn ground); this
## site builds what makes the drop read (spec docs/landmarks/specs/patelnia.md):
##  - on every ring edge that drops: a concrete retaining face from the floor to just over the
##    street, its coping, a band of paving over the street side (the drawn ground's sunken band
##    lies under it), a dark steel railing and the car's collision (the stair tops stay open);
##  - a stair's treads across its ring (risers ~0.16 m) from the street down to the floor;
##  - the Patelnia: Metro Centrum's two glass barrel vaults over the stairs down to the station
##    (F's aerial: smoky ribbed glass, open to the square, closed against the pavilions; the
##    OpenStreetMap outlines are their plans), dark wells inside;
##  - the Rotunda: the lower floor's glazed doorway at the foot of the stair.
## Zone: the barrels' outlines (their boxes go) and two 0.2 m squares at the corners of it all.
const SUNK_CONCRETE := Color("#bfb9ad")
const SUNK_COPING := Color("#cdc7bb")
const SUNK_RAIL := Color("#3b4046")
## M2's exits (Rondo ONZ, Rondo Daszyńskiego, Nowy Świat-Uniwersytet, Centrum Nauki Kopernik;
## Street View 2015-2021, Google 3D Tiles 2026-11-26): dark polished granite walls, frameless glass.
const M2_GRANITE := Color("#33373b")
const M2_GLASS := Color("#9db5b9")
const M2_STEEL := Color("#b9bec2")
const SUNK_TREAD := Color("#c4beb1")
const SUNK_PLANTER := Color("#5f8a3f")
## The Rotunda's stair (F's photos, 2026-11-11): its side walls are living green walls, tall grasses
## in the planters on top, small warm LED lights in the risers along the walking side.
const ROT_GREEN_WALL := [Color("#4a6b37"), Color("#3d5c30"), Color("#56783d")]
const ROT_GRASS := [Color("#7a9444"), Color("#5f7d3a"), Color("#8ea256")]
const ROT_STEP_LED := Color(1.0, 0.86, 0.58)
## The barrels (`buildings` outlines, 4.5 m): the long side's ends, then the mouth's far corner.
const PATELNIA_BARRELS := [
	[Vector2(-897.4, 378.1), Vector2(-890.6, 392.1), Vector2(-897.8, 395.5), Vector2(-904.6, 381.5)],
	[Vector2(-926.5, 392.0), Vector2(-919.9, 406.0), Vector2(-927.1, 409.4), Vector2(-933.8, 395.4)],
]
const BARREL_SKIN := Color("#a9b9c2")
const BARREL_RIB := Color("#2d5aa0")   # blue steel (F's photos, 2026-11-13)
const BARREL_WELL := Color("#2a2e33")
const BARREL_TILE := Color("#c9a69b")
const BARREL_COPING := Color("#d9cfc6")
const SUNK_BOX := [Vector2(-955.0, 360.0), Vector2(-805.0, 432.0)]
const UNDERPASS_BOX := [Vector2(-1315.0, 546.0), Vector2(-1211.0, 625.0)]
const DEFILAD_BOX := [Vector2(-1010.0, 220.0), Vector2(-986.0, 260.0)]
const POWSTANCOW_RAMP_BOX := [Vector2(-729.0, -189.0), Vector2(-711.0, -155.0)]
const TARASY_PLAZA_BOX := [Vector2(-1436.0, 456.0), Vector2(-1352.0, 499.0)]
## Rondo Dmowskiego's twelve stairwells (SUNKEN `rondo_w0`..`rondo_w11`, site `rondo_wells`).
const RONDO_WELLS_BOX := [Vector2(-890.0, 400.0), Vector2(-772.0, 521.0)]
## The stations whose open wells are SUNKEN entries of their own site (Metro Centrum's north exits
## on Marszałkowska, Rondo ONZ, Rondo Daszyńskiego, Ratusz Arsenał, Nowy Świat-Uniwersytet,
## Politechnika, Centrum Nauki Kopernik): each site's box round its wells.
const METRO_WELLS_BOXES := {
	"mw_cen": [Vector2(-968.3, 165.2), Vector2(-909.2, 219.1)],
	"mw_onz": [Vector2(-1829.3, 25.4), Vector2(-1681.3, 177.7)],
	"mw_dasz": [Vector2(-2894.8, 409.1), Vector2(-2748.0, 489.7)],
	"mw_ratusz": [Vector2(-1597.8, -1258.1), Vector2(-1499.8, -1115.0)],
	"mw_nsu": [Vector2(-551.9, -310.7), Vector2(-498.8, -274.4)],
	"mw_poli": [Vector2(-601.1, 1576.3), Vector2(-550.9, 1629.8)],
	"mw_cnk": [Vector2(427.7, -649.6), Vector2(486.0, -614.0)],
}
## Politechnika's two mapped escalators under their glass barrels (3D Tiles 2026-11-26: the
## Patelnia's kind, grey glass on steel ribs, beside each north well): q0-q1 the long side, q1-q2
## the mouth.
const POLI_BARRELS := [
	[Vector2(-593.0, 1589.0), Vector2(-592.4, 1579.1), Vector2(-590.0, 1579.1), Vector2(-590.6, 1589.0)],
	[Vector2(-554.2, 1593.8), Vector2(-553.4, 1583.8), Vector2(-551.2, 1583.8), Vector2(-552.0, 1593.8)],
]
## Złote Tarasy's plaza (F's photos 2026-11-11): the curved wall under the upper terrace is red-brown
## brick over a band of lit shopfronts (the electronics store, the restaurants); white café umbrellas
## on the square.
const PLAZA_BRICK := Color("#9c5a46")
const PLAZA_SHOP := Color("#b9b39a")
const PLAZA_SHOP_H := 4.4
## Metro Centrum's barrels beside the Palace (the outlines' corners: the deep end's far corner, the
## mouth end's near corner, the mouth's far corner, the deep end's near corner).
const METRO_TUBES := [
	[Vector2(-937.1, 306.2), Vector2(-927.5, 302.2), Vector2(-925.9, 305.8), Vector2(-935.6, 309.8)],
	[Vector2(-962.7, 316.7), Vector2(-972.4, 320.7), Vector2(-970.8, 324.4), Vector2(-961.2, 320.3)],
]
## Metro Centrum's big glass pavilion by the Palace's park (ref 5, OSM `transportation` outline 3223,
## 5 m): the outline's four corners, the mouth's two first (north, facing Plac Defilad's lawn), then
## the closed end's two. Built from F's Street View and aerial (2026-11-19): a barrel vault of smoky
## glass on dark blue steel ribs over a 1.1 m beige tiled base, a fan-glazed closed end.
const METRO_PAVILION := [Vector2(-963.4, 218.1), Vector2(-971.1, 220.7), Vector2(-965.6, 236.8), Vector2(-957.9, 234.2)]
## The two little boxes south of it (OSM `service` 3222 and `transportation` 3402, a vent and a
## kiosk) that F asked to remove (2026-11-19, with its fence: city_barriers SITE_WALLS): dropped with the site.
const PAV_NEIGHBOURS := [
	[Vector2(-947.9, 258.4), Vector2(-946.7, 261.4), Vector2(-951.6, 263.3), Vector2(-952.8, 260.4)],
	[Vector2(-962.7, 252.5), Vector2(-961.5, 252.0), Vector2(-960.4, 251.5), Vector2(-959.2, 254.4), Vector2(-961.5, 255.3)],
]
const PAV_TILE := Color("#c7b08f")
const PAV_COPING := Color("#ddd2bf")
const PAV_GLASS := Color("#6f8799")
const PAV_BASE_H := 1.1
## The Plac Defilad car park ramp's walls: pink wall tile (Street View, Aug 2025) under a pale
## granite coping, the ramp's surface a dark ribbed slab.
const RAMP_TILE := Color("#c9a69b")
const RAMP_COPING := Color("#d8cdc4")
const RAMP_ROAD := Color("#43464b")
const RAMP_RIB := Color("#5f6368")
## The underpass's entrances (street photos, Mapillary 2020-2026, refs/epl_*): a granite parapet
## round the wells in the lawn and the forecourt, steel canopies over the pavement flights
## (Śródmieście's green ones on the south side, a dark one on the north).
const PARAPET_FACE := Color("#8e8a83")
const PARAPET_TOP := Color("#a8a49c")
const CANOPY_GREEN := Color("#2e5a45")
const CANOPY_DARK := Color("#2b3035")
const CANOPY_GLASS := Color("#8fa9a6")
const PASSAGE_DARK := Color("#24272b")
const POSTERS := [Color("#d94f3d"), Color("#3f6fb0"), Color("#e8c547"), Color("#f2efe8")]


func _find_sunken() -> void:
	if map._sunk.is_empty():
		return
	var zone: Array = []
	for b: Array in PATELNIA_BARRELS:
		zone.append(PackedVector2Array(b))
	for a: Vector2 in SUNK_BOX:
		zone.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("sunken", zone)
	# The Emilii Plater underpass's entrances: their own site (another sector), tiny squares at
	# its box's corners (nothing mapped is replaced: the walls are map_builder's to leave out).
	var under: Array = []
	for a: Vector2 in UNDERPASS_BOX:
		under.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("underpass", under)
	# The Plac Defilad car park's ramp (SUNKEN `defilad_ramp`): its own site, tiny squares at the
	# corners of its box (the mapped walls are map_builder's to leave out).
	var ramp: Array = []
	for a: Vector2 in DEFILAD_BOX:
		ramp.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("defilad_ramp", ramp)
	# Plac Powstańców Warszawy's car park ramp (SUNKEN `powstancow_ramp`), the same way.
	var pramp: Array = []
	for a: Vector2 in POWSTANCOW_RAMP_BOX:
		pramp.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("powstancow_ramp", pramp)
	# Złote Tarasy's sunken plaza and its great stair (SUNKEN `tarasy_plaza`, `tarasy_stair`): their
	# own site, tiny squares at the corners of its box (the railings and walls OSM maps on the rings
	# are map_builder's to leave out).
	var plaza: Array = []
	for a: Vector2 in TARASY_PLAZA_BOX:
		plaza.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("tarasy_plaza", plaza)
	# Rondo Dmowskiego's stairwells (SUNKEN `rondo_w*`): their own site, the same way (the mapped
	# walls on the rings are map_builder's to leave out).
	var wells: Array = []
	for a: Vector2 in RONDO_WELLS_BOX:
		wells.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
	_add_site("rondo_wells", wells)
	# The other metro stations' open wells (SUNKEN `mw_*`): a site per station, tiny squares at the
	# corners of its box (the mapped walls on the rings are map_builder's to leave out).
	for key: String in METRO_WELLS_BOXES:
		var mw: Array = []
		for a: Vector2 in METRO_WELLS_BOXES[key]:
			mw.append(PackedVector2Array([a, a + Vector2(0.2, 0), a + Vector2(0.2, 0.2), a + Vector2(0, 0.2)]))
		# Each well's ring grown 0.6 m: an OSM part centred in it goes (Rondo ONZ's canopy roofs,
		# drawn here now).
		for sk: Dictionary in map._sunk:
			if str(sk.get("site", "")) == key:
				var g := Geometry2D.offset_polygon(sk["ring"], 0.6, Geometry2D.JOIN_MITER)
				if not g.is_empty():
					mw.append(g[0])
		if key == "mw_poli":
			for b: Array in POLI_BARRELS:
				mw.append(PackedVector2Array(b))
		_add_site(key, mw)
	# Metro Centrum's other two glass barrels (OSM `transportation` outlines 3224 and 3401 by the
	# Palace's park, refs 10 and 4): the mapped outlines are the plans, the boxes go.
	var tubes: Array = []
	for b: Array in METRO_TUBES:
		tubes.append(PackedVector2Array(b))
	_add_site("metro_tubes", tubes)
	# The big pavilion beside them (ref 5): its outline is the plan, the grey box goes.
	var pav_zone: Array = [PackedVector2Array(METRO_PAVILION)]
	for n: Array in PAV_NEIGHBOURS:
		pav_zone.append(PackedVector2Array(n))
	_add_site("metro_pavilion", pav_zone)


var _sunk_done: Array[PackedVector2Array] = []


func _build_sunken(site: Dictionary) -> void:
	_no_roof = true
	_sunk_done.clear()
	var key: String = site["key"]
	for sk: Dictionary in map._sunk:
		if str(sk.get("site", "sunken")) != key:
			continue
		_sunk_edges(sk)
		if str(sk.get("style", "")) == "ramp":
			_sunk_ramp(sk)
		elif (sk["a"] as Vector2).distance_to(sk["b"]) > 0.1:
			_sunk_treads(sk)
		if not (sk.get("walk", PackedVector2Array()) as PackedVector2Array).is_empty():
			_sunk_mouth(sk)
		if str(sk["key"]).begins_with("mw_"):
			_mw_handrails(sk)
		if str(sk.get("style", "")) == "canopy_glass":
			_sunk_glass_canopy(sk)
		elif str(sk.get("style", "")).begins_with("canopy"):
			_sunk_canopy(sk)
	if key == "tarasy_plaza":
		_tarasy_plaza_dress()
	if key == "mw_poli":
		for b: Array in POLI_BARRELS:
			_glass_barrel(b)
	if key == "sunken":
		for b: Array in PATELNIA_BARRELS:
			_glass_barrel(b)
		for sk: Dictionary in map._sunk:
			if sk["key"] == "rotunda_stair":
				_sunk_doorway(sk)
				_rot_stair_dress(sk)
	_no_roof = false


## The street's height beside a ring's edge point p (outward `out`): the grid's highest over the
## next 3 m out (the 10 m grid blurs the drop: right at the edge it lies metres low).
func _sunk_upper(p: Vector2, out: Vector2) -> float:
	var u: float = map._grid_height(p.x, p.y)
	for d: float in [0.8, 1.8, 3.0]:
		var q := p + out * d
		u = maxf(u, map._grid_height(q.x, q.y))
	return u


## Each edge of ring `sk` in pieces up to 2 m: where the street side stands over the floor, a
## retaining face, coping, paving band, railing and collision; an edge another ring continues
## (a stair's foot on the square) or a stair's top (no drop) stays open.
func _sunk_edges(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var band := 1.42 * 2.0 * 10.0 / float(sk["sub"]) + 0.2
	var planted: bool = sk["key"] == "rotunda_stair"
	# The edge's top over the street: the coping (a railing on it), a granite parapet, or the
	# low parapet a canopy's frame stands on.
	var style := str(sk.get("style", "rail"))
	var rise := 0.12
	var face_col := SUNK_CONCRETE
	var top_col := SUNK_COPING.lightened(0.05)
	if style == "parapet":
		rise = 1.1
		face_col = PARAPET_FACE
		top_col = PARAPET_TOP
	elif style.begins_with("canopy"):
		rise = 0.9
		face_col = PARAPET_FACE
		top_col = PARAPET_TOP
	elif style == "ramp":
		rise = 0.45
		face_col = RAMP_TILE
		top_col = RAMP_COPING
		# a ramp's own walls (SUNKEN `tile`, `rise`: Plac Powstańców' bare concrete, a metre up)
		if (sk.get("tile", Color(0, 0, 0, 0)) as Color).a > 0.0:
			face_col = sk["tile"]
			top_col = (sk["tile"] as Color).lightened(0.06)
		if float(sk.get("rise", -1.0)) > 0.0:
			rise = float(sk["rise"])
	elif style == "shops":
		face_col = PLAZA_BRICK
	elif style == "glass" or style == "canopy_glass":
		# M2's exits (Street View 2015-2021): a low dark granite upstand, dark granite inside, a
		# frameless glass balustrade on it (or the coloured glass canopy, `_sunk_glass_canopy`).
		rise = 0.3
		face_col = M2_GRANITE
		top_col = M2_GRANITE.lightened(0.1)
	# A well's own inner walls (SUNKEN `tile`: Metro Centrum's pink marble, Politechnika's rough
	# stone); the parapet's street side stays `face_col`.
	var inner_col := face_col
	if style != "ramp" and (sk.get("tile", Color(0, 0, 0, 0)) as Color).a > 0.0:
		inner_col = sk["tile"]
	var run := 0.0
	# A stair's band lies over the square's where they meet: 0.1 m higher (no flicker).
	var band_lift := 0.0 if (sk["a"] as Vector2).distance_to(sk["b"]) < 0.1 else 0.1
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var d := (b - a) / length
		var out := Vector2(d.y, -d.x)
		if Geometry2D.is_point_in_polygon((a + b) * 0.5 + out * 0.1, ring):
			out = -out
		# Open where the ground past the edge is another ring's at this floor.
		var mid := (a + b) * 0.5
		var past: float = map.sunk_floor(mid.x + out.x * 0.8, mid.y + out.y * 0.8)
		if past < INF and absf(past - map.sunk_level(sk, mid)) < 0.8:
			continue
		var n := maxi(1, ceili(length / 2.0))
		for k in n:
			var p0 := a + d * (length * k / n)
			var p1 := a + d * (length * (k + 1) / n)
			var f0: float = map.sunk_level(sk, p0)
			var f1: float = map.sunk_level(sk, p1)
			# `rim`: the street's height where the 10 m grid's pit dips under it (the car park ramp).
			var u0 := maxf(_sunk_upper(p0, out), float(sk.get("rim", -INF)))
			var u1 := maxf(_sunk_upper(p1, out), float(sk.get("rim", -INF)))
			if u0 - f0 < 0.35 and u1 - f1 < 0.35:
				# A stair's top: level with the street, open to walkers; a metro well's mouth keeps
				# the car out (an unseen 1.2 m wall on it: no car fits down a station's stair).
				if str(sk["key"]).begins_with("mw_"):
					map._solid(&"landmark", [Vector3(p0.x, u0 - 0.5, p0.y), Vector3(p1.x, u1 - 0.5, p1.y), Vector3(p1.x, u1 + 1.2, p1.y),
							Vector3(p0.x, u0 - 0.5, p0.y), Vector3(p1.x, u1 + 1.2, p1.y), Vector3(p0.x, u0 + 1.2, p0.y)], _r2)
				continue
			var t0 := u0 + rise
			var t1 := u1 + rise
			var nin := Vector3(-out.x, 0.0, -out.y)
			var nout := Vector3(out.x, 0.0, out.y)
			var q0 := p0 + out * 0.3
			var q1 := p1 + out * 0.3
			# The retaining face (the square's side), the coping on top and its street face; by the
			# Rotunda a living green wall, patchy in three greens.
			_mode = M_STONE
			var fc := inner_col
			if planted:
				fc = ROT_GREEN_WALL[(i * 3 + k) % ROT_GREEN_WALL.size()]
			_quad(Vector3(p0.x, f0 - 0.3, p0.y), Vector3(p1.x, f1 - 0.3, p1.y), Vector3(p1.x, t1, p1.y), Vector3(p0.x, t0, p0.y),
					nin, fc)
			# The plaza's shops: a band of glass fronts along the foot of every wall but the one to
			# the station (south), lit warm bay by bay at night, a little proud of the brick.
			if style == "shops" and out.y < 0.5 and minf(t0 - f0, t1 - f1) > PLAZA_SHOP_H + 0.5:
				var s0 := p0 - out * 0.06
				var s1 := p1 - out * 0.06
				var w := p0.distance_to(p1)
				_mode = M_PAVILION
				_quad(Vector3(s0.x, f0, s0.y), Vector3(s1.x, f1, s1.y), Vector3(s1.x, f1 + PLAZA_SHOP_H, s1.y),
						Vector3(s0.x, f0 + PLAZA_SHOP_H, s0.y), nin, PLAZA_SHOP, Vector2(run, 0.0), Vector2(run + w, 0.0),
						Vector2(run + w, PLAZA_SHOP_H), Vector2(run, PLAZA_SHOP_H), PLAZA_SHOP_H)
				run += w
				_mode = M_STONE
			var along := func(v: Vector2) -> float:
				return lerpf(t0, t1, clampf((v - p0).dot(d) / maxf(p0.distance_to(p1), 0.01), 0.0, 1.0))
			_sunk_top(PackedVector2Array([p0, p1, q1, q0]), along, top_col)
			var g0: float = map._grid_height(q0.x, q0.y)
			var g1: float = map._grid_height(q1.x, q1.y)
			_quad(Vector3(q0.x, minf(t0, g0 + 0.05), q0.y), Vector3(q1.x, minf(t1, g1 + 0.05), q1.y),
					Vector3(q1.x, t1, q1.y), Vector3(q0.x, t0, q0.y), nout, face_col.darkened(0.05))
			# The band over the street side's sunken ground: paving (planting by the Rotunda).
			var on_grid := func(v: Vector2) -> float:
				return map._grid_height(v.x, v.y) + 0.05 + band_lift
			# By the Rotunda the first 1.3 m are the planters' planting, the rest paving.
			var split := 1.3 if planted else 0.3
			if planted:
				_sunk_top(PackedVector2Array([q0, q1, p1 + out * split, p0 + out * split]), on_grid, SUNK_PLANTER)
			_sunk_top(PackedVector2Array([p0 + out * split, p1 + out * split, p1 + out * band, p0 + out * band]), on_grid, SUNK_COPING)
			# The railing: a post every piece and a top rail at 1.05 m, thin two-sided bands.
			var w0 := p0 + out * 0.12
			var w1 := p1 + out * 0.12
			if style == "rail" or style == "shops":
				_sunk_band(w0, w1, t0 + 0.99, t1 + 0.99, 0.07, nout)
				_sunk_band(w0 + d * 0.02, w0 + d * 0.08, t0, t0, 0.99, nout)
			elif style == "glass":
				_sunk_glass(w0, w1, t0, t1, nout)
			# The car: from the floor to well over the railing (or the parapet), on the edge.
			var over := 1.6 if style in ["rail", "shops", "glass", "canopy_glass"] else 0.6
			map._solid(&"landmark", [Vector3(p0.x, f0 - 0.5, p0.y), Vector3(p1.x, f1 - 0.5, p1.y), Vector3(p1.x, t1 + over, p1.y),
					Vector3(p0.x, f0 - 0.5, p0.y), Vector3(p1.x, t1 + over, p1.y), Vector3(p0.x, t0 + over, p0.y)], _r2)


## A metro well's handrails (Street View: steel rails down both sides of every flight, one down the
## middle of a wide one): from a post at the mouth, 0.95 m over the treads to the stair's foot.
## The posts at the mouth are what the car meets there (`_sunk_edges` keeps it out).
func _mw_handrails(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var a: Vector2 = sk["a"]
	var b: Vector2 = sk["b"]
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var d := (b - a) / length
	var side := Vector2(-d.y, d.x)
	# The mouth's width across the ring at its top (a little in from the mouth).
	var lo := INF
	var hi := -INF
	var probe := a + d * 0.3
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		var hit: Variant = Geometry2D.line_intersects_line(probe, side, p, q - p)
		if hit == null:
			continue
		var h: Vector2 = hit
		if (h - p).dot(q - p) < -0.01 or (h - q).dot(p - q) < -0.01:
			continue
		var t := (h - probe).dot(side)
		lo = minf(lo, t)
		hi = maxf(hi, t)
	if not is_finite(lo) or hi - lo < 1.0:
		return
	var offs: Array[float] = [lo + 0.25, hi - 0.25]
	if hi - lo > 3.0:
		offs.append((lo + hi) * 0.5)
	var ha := float(sk["ha"])
	var hb := float(sk["hb"])
	# M2's brushed steel; Ratusz Arsenał's green (Street View 2019); M1's dark steel elsewhere.
	var col := M2_STEEL if str(sk["style"]) in ["glass", "canopy_glass"] else SUNK_RAIL
	if str(sk["key"]).begins_with("mw_ra_"):
		col = Color("#2f5d45")
	for o: float in offs:
		var t0 := a + side * o
		var t1 := b + side * o
		_beam(Vector3(t0.x, ha, t0.y), Vector3(t0.x, ha + 1.0, t0.y), 0.07, col, false)
		_beam(Vector3(t0.x, ha + 1.0, t0.y), Vector3(t1.x, hb + 0.95, t1.y), 0.05, col, false)


## A frameless glass balustrade on a well's upstand from w0 to w1 (tops t0, t1): one pane 0.85 m
## tall, a slim steel cap on it, both faces.
func _sunk_glass(w0: Vector2, w1: Vector2, t0: float, t1: float, n: Vector3) -> void:
	_mode = M_STONE
	var a := Vector3(w0.x, t0, w0.y)
	var b := Vector3(w1.x, t1, w1.y)
	var up := Vector3(0.0, 0.85, 0.0)
	_quad(a, b, b + up, a + up, n, M2_GLASS)
	_quad(b, a, a + up, b + up, -n, M2_GLASS)
	_quad(a + up, b + up, b + up + Vector3(0.0, 0.05, 0.0), a + up + Vector3(0.0, 0.05, 0.0), n, M2_STEEL)
	_quad(b + up, a + up, a + up + Vector3(0.0, 0.05, 0.0), b + up + Vector3(0.0, 0.05, 0.0), -n, M2_STEEL)


## M2's coloured glass canopy over a well (SUNKEN style "canopy_glass", `roof` its glass: Rondo
## Daszyński's red, Nowy Świat-Uniwersytet's violet; Google 3D Tiles 2026-11-26): a long low wedge,
## 2.6 m over the street at the mouth sinking to 1.2 m at the far end, glass sides on the granite
## upstand along every edge that drops, the tinted roof over the whole ring, dark frame edges.
## The mouth (the stair's top, level with the street) stays open.
func _sunk_glass_canopy(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var a: Vector2 = sk["a"]
	var d: Vector2 = ((sk["b"] as Vector2) - a).normalized()
	var u0 := INF
	var u1 := -INF
	for q in ring:
		u0 = minf(u0, (q - a).dot(d))
		u1 = maxf(u1, (q - a).dot(d))
	var street: float = map._grid_height(a.x, a.y)
	var roof_y := func(p: Vector2) -> float:
		var t := clampf(((p - a).dot(d) - u0) / maxf(u1 - u0, 0.1), 0.0, 1.0)
		return street + lerpf(2.6, 1.2, t)
	var col: Color = sk.get("roof", Color("#8e2b33"))
	_mode = M_STONE
	# The roof: the ring's triangles at the wedge's height, both faces (the camera looks down on it).
	var idx := Geometry2D.triangulate_polygon(ring)
	for t in range(0, idx.size() - 2, 3):
		var p := [ring[idx[t]], ring[idx[t + 1]], ring[idx[t + 2]]]
		var v: Array[Vector3] = []
		for q: Vector2 in p:
			v.append(Vector3(q.x, float(roof_y.call(q)), q.y))
		_tri(v[0], v[1], v[2], Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		_tri(v[0], v[2], v[1], Vector3.DOWN, col.darkened(0.25), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The sides: glass from the upstand to the roof on every edge but the mouth; a frame along the
	# roof's edges and a post at each corner.
	for i in ring.size():
		var p0 := ring[i]
		var p1 := ring[(i + 1) % ring.size()]
		var r0: float = roof_y.call(p0)
		var r1: float = roof_y.call(p1)
		_beam(Vector3(p0.x, r0, p0.y), Vector3(p1.x, r1, p1.y), 0.09, M2_GRANITE, false)
		_beam(Vector3(p0.x, map._grid_height(p0.x, p0.y), p0.y), Vector3(p0.x, r0, p0.y), 0.08, M2_GRANITE, false)
		var mid := (p0 + p1) * 0.5
		if absf((mid - a).dot(d) - u0) < 0.3:
			continue  # the mouth
		var dd := (p1 - p0).normalized()
		var out := Vector2(dd.y, -dd.x)
		if Geometry2D.is_point_in_polygon(mid + out * 0.1, ring):
			out = -out
		var g0: float = map._grid_height(p0.x, p0.y) + 0.3
		var g1: float = map._grid_height(p1.x, p1.y) + 0.3
		var n3 := Vector3(out.x, 0.0, out.y)
		var q0 := p0 + out * 0.1
		var q1 := p1 + out * 0.1
		_quad(Vector3(q0.x, g0, q0.y), Vector3(q1.x, g1, q1.y), Vector3(q1.x, r1, q1.y), Vector3(q0.x, r0, q0.y), n3, col.lerp(M2_GLASS, 0.45))
		_quad(Vector3(q1.x, g1, q1.y), Vector3(q0.x, g0, q0.y), Vector3(q0.x, r0, q0.y), Vector3(q1.x, r1, q1.y), -n3, col.lerp(M2_GLASS, 0.45).darkened(0.2))


## The car park ramp's surface between its walls (ring edges 5-0 and 1-2 are the sides): a dark slab
## with a rib across every 1.4 m (Street View: the herringbone grooves), from the top to the hood,
## each strip following the floor's slope, 3 cm over it.
func _sunk_ramp(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var w_top: Vector2 = ring[0]
	var e_top: Vector2 = ring[1]
	var e_foot: Vector2 = ring[2]
	var w_foot: Vector2 = ring[5]
	var n := 22
	var floor_at := func(v: Vector2) -> float:
		return map.sunk_level(sk, v) + 0.03
	_mode = M_STONE
	# the ramp's own surface (SUNKEN `floor`: Plac Powstańców' grey setts), else the dark ribbed slab
	var road := RAMP_ROAD
	var rib := RAMP_RIB
	if (sk.get("floor", Color(0, 0, 0, 0)) as Color).a > 0.0:
		road = sk["floor"]
		rib = (sk["floor"] as Color).darkened(0.07)
	for k in n:
		var t0 := float(k) / n
		var t1 := float(k + 1) / n
		var q := PackedVector2Array([w_top.lerp(w_foot, t0), e_top.lerp(e_foot, t0), e_top.lerp(e_foot, t1), w_top.lerp(w_foot, t1)])
		_sunk_top(q, floor_at, road if k % 2 == 0 else rib)


## Metro Centrum's big pavilion by the Palace's park (METRO_PAVILION).
func _build_metro_pavilion() -> void:
	_no_roof = true
	_glass_pavilion(METRO_PAVILION)
	_no_roof = false


## Metro Centrum's two barrels by the Palace's park (METRO_TUBES), as the Patelnia's.
func _build_metro_tubes() -> void:
	_no_roof = true
	for b: Array in METRO_TUBES:
		_glass_barrel(b)
	_no_roof = false


## Metro Centrum's big glass pavilion (METRO_PAVILION): a 1.1 m beige tiled base round a half-barrel
## vault of smoky glass on dark blue steel ribs (every ~1.5 m) with horizontal glazing bars, the
## closed south end glazed in a fan of radial bars, the north mouth open between two stubs of
## base wall over a stair going down (the M post is storefronts' prop, form "post"). Car
## collision on the outline.
func _glass_pavilion(q: Array) -> void:
	var p0: Vector2 = q[0]
	var p1: Vector2 = q[1]
	var p2: Vector2 = q[2]
	var p3: Vector2 = q[3]
	var mouth := (p0 + p1) * 0.5
	var far := (p2 + p3) * 0.5
	var length := mouth.distance_to(far)
	var up := (mouth - far) / length
	var side := Vector2(-up.y, up.x)
	var width := p0.distance_to(p1)
	var c := (mouth + far) * 0.5
	var half := length * 0.5
	var hw := width * 0.5
	var r := hw - 0.15
	var g: float = map.terrain_height(c.x, c.y)
	var y0 := g + PAV_BASE_H
	_o = c
	_a = up
	_b = side
	_collide(PackedVector2Array(q))
	# The tiled base: both long walls, the closed end, the mouth's two stubs (a 3.6 m gap between),
	# a coping over each.
	var gap := 1.8
	_mode = M_STONE
	for sv: float in [-1.0, 1.0]:
		_lbox(0.0, (hw - 0.2) * sv, half, 0.2, g - 0.05, y0, PAV_TILE, M_STONE, PAV_COPING)
		_lbox(half - 0.2, (gap + hw) * 0.5 * sv, 0.2, (hw - gap) * 0.5, g - 0.05, y0 - 0.03, PAV_TILE, M_STONE, PAV_COPING)
	_lbox(-half + 0.2, 0.0, 0.2, hw - 0.4, g - 0.05, y0 - 0.03, PAV_TILE, M_STONE, PAV_COPING)
	# The vault: half a barrel, 12 panes round, smoky glass, a pale sheen band along the crown.
	var segs := 12
	var arc: Array[Vector2] = []
	for k in segs + 1:
		var ang := PI * float(k) / float(segs)
		arc.append(Vector2(cos(ang) * r, sin(ang) * r))
	var at := func(s: float, p: Vector2) -> Vector3:
		var w := c + up * s + side * p.x
		return Vector3(w.x, y0 + p.y, w.y)
	_mode = M_PAVILION + 0.5
	for k in segs:
		var pa: Vector2 = arc[k]
		var pb: Vector2 = arc[k + 1]
		var n3: Vector3 = ((at.call(0.0, (pa + pb) * 0.5) as Vector3) - Vector3(c.x, y0, c.y)).normalized()
		var tone := PAV_GLASS.lightened(0.10) if k % 4 == 1 else PAV_GLASS
		_quad(at.call(-half, pa), at.call(half, pa), at.call(half, pb), at.call(-half, pb), n3, tone)
	# The closed south end: glass in a fan from the foot of the end wall, radial bars and a ring.
	var back := Vector3(-up.x, 0.0, -up.y)
	var hub: Vector3 = at.call(-half, Vector2.ZERO)
	for k in segs:
		_tri(hub, at.call(-half, arc[k]), at.call(-half, arc[k + 1]), back, PAV_GLASS.darkened(0.12),
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# Ribs every ~1.5 m, the mouth's arch heavier.
	var n_rib := maxi(4, roundi(length / 1.5) + 1)
	for i in n_rib:
		var s := -half + length * float(i) / float(n_rib - 1)
		_barrel_rib(at, s, 0.22 if i == n_rib - 1 or i == 0 else 0.12, arc, r)
	# Horizontal glazing bars along the vault at every second vertex, on the glass.
	_mode = M_STONE
	var k_out := 1.015
	for k in range(2, segs - 1, 2):
		var pk: Vector2 = arc[k]
		var tang := Vector2(-pk.y, pk.x).normalized() * 0.05
		var nrm3: Vector3 = ((at.call(0.0, pk) as Vector3) - Vector3(c.x, y0, c.y)).normalized()
		_quad(at.call(-half, pk * k_out - tang), at.call(half, pk * k_out - tang), at.call(half, pk * k_out + tang),
				at.call(-half, pk * k_out + tang), nrm3, BARREL_RIB)
	# The fan's radial bars on the end glass (in the end plane, 0.1 m proud), and a ring half way up.
	for k in range(1, segs):
		var pk: Vector2 = arc[k]
		var perp := Vector2(-pk.y, pk.x).normalized() * 0.05
		_quad(at.call(-half - 0.04, pk * 0.12 + perp), at.call(-half - 0.04, pk + perp), at.call(-half - 0.04, pk - perp),
				at.call(-half - 0.04, pk * 0.12 - perp), back, BARREL_RIB)
	for k in segs:
		var pa: Vector2 = arc[k] * 0.55
		var pb: Vector2 = arc[k + 1] * 0.55
		var pa2: Vector2 = pa * 1.08
		var pb2: Vector2 = pb * 1.08
		_quad(at.call(-half - 0.04, pa), at.call(-half - 0.04, pb), at.call(-half - 0.04, pb2), at.call(-half - 0.04, pa2), back, BARREL_RIB)
	# Inside the mouth: the dark well and its first lighter steps going down.
	var w0 := c + up * (half - 0.6) - side * gap
	var w1 := c + up * (half - 0.6) + side * gap
	var w2 := c - up * (half - 0.6) + side * gap
	var w3 := c - up * (half - 0.6) - side * gap
	_quad(Vector3(w0.x, g + 0.03, w0.y), Vector3(w1.x, g + 0.03, w1.y), Vector3(w2.x, g + 0.03, w2.y), Vector3(w3.x, g + 0.03, w3.y),
			Vector3.UP, BARREL_WELL)
	for k in 4:
		var s := half - 0.5 - 0.45 * k
		var e0 := c + up * s - side * (gap - 0.1)
		var e1 := c + up * s + side * (gap - 0.1)
		var e2 := c + up * (s - 0.2) + side * (gap - 0.1)
		var e3 := c + up * (s - 0.2) - side * (gap - 0.1)
		_quad(Vector3(e0.x, g + 0.07, e0.y), Vector3(e1.x, g + 0.07, e1.y), Vector3(e2.x, g + 0.07, e2.y), Vector3(e3.x, g + 0.07, e3.y),
				Vector3.UP, SUNK_TREAD.darkened(0.2 + 0.12 * k))


## A flat top over plan polygon `poly`, less what this build already covered (neighbouring edges'
## coping and bands overlap at the corners and would flicker), each corner at `height`(corner).
func _sunk_top(poly: PackedVector2Array, height: Callable, col: Color) -> void:
	var parts: Array[PackedVector2Array] = [poly]
	for done: PackedVector2Array in _sunk_done:
		var left: Array[PackedVector2Array] = []
		for part in parts:
			for q in Geometry2D.clip_polygons(part, done):
				if not Geometry2D.is_polygon_clockwise(q) or q.size() < 3:
					left.append(q)
		parts = left
	_sunk_done.append(poly)
	_mode = M_STONE
	for part in parts:
		var idx := Geometry2D.triangulate_polygon(part)
		for t in range(0, idx.size() - 2, 3):
			var a := part[idx[t]]
			var b := part[idx[t + 1]]
			var c := part[idx[t + 2]]
			var pa := Vector3(a.x, float(height.call(a)), a.y)
			var pb := Vector3(b.x, float(height.call(b)), b.y)
			var pc := Vector3(c.x, float(height.call(c)), c.y)
			if (pb - pa).cross(pc - pa).length() < 0.001:
				continue  # a clipped sliver
			_tri(pa, pb, pc, Vector3.UP, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A thin vertical band from a to b (plan), bottom y0/y1 at each end, `h` tall, both faces dark steel.
func _sunk_band(a: Vector2, b: Vector2, y0: float, y1: float, h: float, n: Vector3) -> void:
	_mode = M_STONE
	var pa := Vector3(a.x, y0, a.y)
	var pb := Vector3(b.x, y1, b.y)
	var up := Vector3(0.0, h, 0.0)
	_quad(pa, pb, pb + up, pa + up, n, SUNK_RAIL)
	_quad(pb, pa, pa + up, pb + up, -n, SUNK_RAIL)


## A stair's treads across its ring from its top `a` (the street's height) to its foot `b`
## (the floor): risers ~0.16 m, each tread level with the higher end of its strip so the sunken
## ground's slope stays under them; a darker nosing on each.
func _sunk_treads(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var a: Vector2 = sk["a"]
	var b: Vector2 = sk["b"]
	var length := a.distance_to(b)
	var d := (b - a) / length
	var side := Vector2(-d.y, d.x)
	var ha := float(sk["ha"])
	var hb := float(sk["hb"])
	var n := maxi(3, roundi((ha - hb) / 0.16))
	for k in n:
		var s0 := length * k / n
		var s1 := length * (k + 1) / n
		var strip := PackedVector2Array([a + d * s0 - side * 40.0, a + d * s1 - side * 40.0, a + d * s1 + side * 40.0,
				a + d * s0 + side * 40.0])
		var top := lerpf(ha, hb, float(k) / n)
		for poly in Geometry2D.intersect_polygons(strip, ring):
			if Geometry2D.is_polygon_clockwise(poly):
				continue  # a hole: none in a convex strip
			_prism(poly, top - 0.4, top, SUNK_TREAD.darkened(0.12), SUNK_TREAD.darkened(0.04 if k % 2 == 0 else 0.0), M_STONE, M_STONE)


## One of Metro Centrum's glass barrels on the Patelnia over a stair down to the station: plan
## `q` (q0-q1 the long side, q1-q2 the mouth), a half barrel springing from 0.45 m (crown at
## the outline's 4.5 m), smoky ribbed glass, closed at the far end, open at the mouth, a dark
## well inside and a concrete sill along each side.
func _glass_barrel(q: Array) -> void:
	var q0: Vector2 = q[0]
	var q1: Vector2 = q[1]
	var q2: Vector2 = q[2]
	var q3: Vector2 = q[3]
	var length := q0.distance_to(q1)
	var up := (q1 - q0) / length
	var c := (q0 + q1 + q2 + q3) * 0.25
	var side := Vector2(-up.y, up.x)
	var width := q1.distance_to(q2)
	var r := width * 0.5 - 0.15
	var g: float = map.terrain_height(c.x, c.y)
	var y0 := g + 1.0
	var half := length * 0.5
	var segs := 9
	var arc: Array[Vector2] = []
	for k in segs + 1:
		var ang := PI * float(k) / float(segs)
		arc.append(Vector2(cos(ang) * r, sin(ang) * r))
	var at := func(s: float, p: Vector2) -> Vector3:
		var w := c + up * s + side * p.x
		return Vector3(w.x, y0 + p.y, w.y)
	_mode = M_PAVILION + 0.5
	for k in segs:
		var p0: Vector2 = arc[k]
		var p1: Vector2 = arc[k + 1]
		var n3: Vector3 = ((at.call(0.0, (p0 + p1) * 0.5) as Vector3) - Vector3(c.x, y0, c.y)).normalized()
		_quad(at.call(-half, p0), at.call(half, p0), at.call(half, p1), at.call(-half, p1), n3, BARREL_SKIN)
	var back := Vector3(-up.x, 0.0, -up.y)
	var hub: Vector3 = at.call(-half, Vector2.ZERO)
	for k in segs:
		_tri(hub, at.call(-half, arc[k]), at.call(-half, arc[k + 1]), back, BARREL_SKIN.darkened(0.08),
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# Ribs every ~1.3 m (the mouth's a little heavier), steel.
	var n_rib := maxi(4, roundi(length / 1.3) + 1)
	for i in n_rib:
		var s := -half + length * float(i) / float(n_rib - 1)
		_barrel_rib(at, s, 0.22 if i == n_rib - 1 else 0.12, arc, r)
	# Sills along both sides, the dark well between them (the stair going down under the pavilions).
	_o = c
	_a = up
	_b = side
	# The low walls under the glass: pink wall tile under a pale coping (Street View, Jul 2024).
	for sx: float in [-1.0, 1.0]:
		_lbox(0.0, (r + 0.05) * sx, half, 0.14, g, y0 + 0.02, BARREL_TILE, M_STONE, BARREL_COPING)
	_mode = M_STONE
	var w0 := c + up * (half - 0.6) - side * (r - 0.2)
	var w1 := c + up * (half - 0.6) + side * (r - 0.2)
	var w2 := c - up * (half - 0.2) + side * (r - 0.2)
	var w3 := c - up * (half - 0.2) - side * (r - 0.2)
	_quad(Vector3(w0.x, g + 0.03, w0.y), Vector3(w1.x, g + 0.03, w1.y), Vector3(w2.x, g + 0.03, w2.y), Vector3(w3.x, g + 0.03, w3.y),
			Vector3.UP, BARREL_WELL)
	# The well's first steps at the mouth, lighter, so it reads as a stair going down.
	for k in 3:
		var s := half - 0.6 - 0.45 * k
		var e0 := c + up * s - side * (r - 0.25)
		var e1 := c + up * s + side * (r - 0.25)
		var e2 := c + up * (s - 0.18) + side * (r - 0.25)
		var e3 := c + up * (s - 0.18) - side * (r - 0.25)
		_quad(Vector3(e0.x, g + 0.07, e0.y), Vector3(e1.x, g + 0.07, e1.y), Vector3(e2.x, g + 0.07, e2.y), Vector3(e3.x, g + 0.07, e3.y),
				Vector3.UP, SUNK_TREAD.darkened(0.25 + 0.15 * k))
	# The escalator beside the stair (the photos: a steel escalator on the left): grey treads in
	# bands down the left half and a steel balustrade on each side of it, sloping down into the well.
	var e_in := -(r - 0.25)
	var e_out := -0.35
	var e_len := minf(half * 2.0 - 1.4, 5.0)
	for k in int(e_len / 0.3):
		var s0 := half - 0.6 - 1.5 - 0.3 * k
		if s0 - 0.2 < -half + 0.3:
			break
		var t0 := c + up * s0
		var t1 := c + up * (s0 - 0.2)
		_quad(Vector3(t0.x + side.x * e_in, g + 0.06, t0.y + side.y * e_in), Vector3(t0.x + side.x * e_out, g + 0.06, t0.y + side.y * e_out),
				Vector3(t1.x + side.x * e_out, g + 0.06, t1.y + side.y * e_out), Vector3(t1.x + side.x * e_in, g + 0.06, t1.y + side.y * e_in),
				Vector3.UP, Color("#8d9298") if k % 2 == 0 else Color("#5c6168"))
	for ex: float in [e_in, e_out]:
		var a0 := c + up * (half - 0.6) + side * ex
		var a1 := c + up * (half - 0.6 - e_len) + side * ex
		var nrm := Vector3(side.x, 0.0, side.y)
		var lo0 := Vector3(a0.x, g + 0.05, a0.y)
		var lo1 := Vector3(a1.x, g + 0.05, a1.y)
		var hi0 := Vector3(a0.x, g + 0.95, a0.y)
		_tri(lo0, lo1, hi0, nrm, Color("#3a3d42"), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		_tri(lo1, lo0, hi0, -nrm, Color("#3a3d42"), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A barrel's steel rib at `s` along it, `w` wide: an annular band 0.1 m proud of the glass.
func _barrel_rib(at: Callable, s: float, w: float, arc: Array[Vector2], r: float) -> void:
	_mode = M_STONE
	var k_in := (r + 0.01) / r
	var k_out := (r + 0.11) / r
	var axis := ((at.call(s + 0.1, Vector2.ZERO) as Vector3) - (at.call(s - 0.1, Vector2.ZERO) as Vector3)).normalized()
	for k in arc.size() - 1:
		var pa: Vector2 = arc[k]
		var pb: Vector2 = arc[k + 1]
		var hub: Vector3 = at.call(s, Vector2.ZERO)
		var n_out: Vector3 = ((at.call(s, (pa + pb) * 0.5) as Vector3) - hub).normalized()
		var fa_o: Vector3 = at.call(s - w * 0.5, pa * k_out)
		var fb_o: Vector3 = at.call(s - w * 0.5, pb * k_out)
		var ba_o: Vector3 = at.call(s + w * 0.5, pa * k_out)
		var bb_o: Vector3 = at.call(s + w * 0.5, pb * k_out)
		# The face towards the mouth and the outer band (the far face is never seen past the glass).
		_quad(at.call(s + w * 0.5, pa * k_in), at.call(s + w * 0.5, pb * k_in), bb_o, ba_o, axis, BARREL_RIB)
		_quad(fa_o, fb_o, bb_o, ba_o, n_out, BARREL_RIB.lightened(0.08))


## The Rotunda's stair as a place to sit (F, 2026-11-11, his photos): tall grasses along the
## planters on its rims, and a warm LED light in every riser by the walking side (the west wall),
## lit at night. The people sitting on the steps are crowds.gd's (site `rotunda_steps`).
func _rot_stair_dress(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	var a: Vector2 = sk["a"]
	var b: Vector2 = sk["b"]
	var length := a.distance_to(b)
	var d := (b - a) / length
	var side := Vector2(-d.y, d.x)
	var ha := float(sk["ha"])
	var hb := float(sk["hb"])
	var n := maxi(3, roundi((ha - hb) / 0.16))
	_mode = M_LAMP
	for k in range(1, n):
		var s0 := length * k / n
		var strip := PackedVector2Array([a + d * (s0 - 0.05) - side * 40.0, a + d * (s0 + 0.05) - side * 40.0,
				a + d * (s0 + 0.05) + side * 40.0, a + d * (s0 - 0.05) + side * 40.0])
		var lo := INF
		for poly in Geometry2D.intersect_polygons(strip, ring):
			for q in poly:
				lo = minf(lo, (q - a).dot(side))
		if lo == INF:
			continue
		var top := lerpf(ha, hb, float(k) / n)
		var c0 := a + d * (s0 + 0.012) + side * (lo + 0.3)
		var c1 := c0 + side * 0.32
		_quad(Vector3(c0.x, top + 0.03, c0.y), Vector3(c1.x, top + 0.03, c1.y), Vector3(c1.x, top + 0.08, c1.y),
				Vector3(c0.x, top + 0.08, c0.y), Vector3(d.x, 0.0, d.y), ROT_STEP_LED)
	# The grasses: a crossed pair of blades every 1.2 m along the planted rims, 0.65 m out.
	_mode = M_STONE
	var nn := Vector2(-1, -1)
	var t := 0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		var l := p.distance_to(q)
		if l < 0.5:
			continue
		var e := (q - p) / l
		var out := Vector2(e.y, -e.x)
		if Geometry2D.is_point_in_polygon((p + q) * 0.5 + out * 0.1, ring):
			out = -out
		for j in int(l / 1.2):
			var m := p + e * (0.6 + 1.2 * j) + out * 0.65
			var f: float = map.sunk_level(sk, m - out * 0.65)
			var gy: float = _sunk_upper(m, out)
			if gy - f < 0.35:
				continue  # the stair's open top
			var col: Color = ROT_GRASS[t % ROT_GRASS.size()]
			var h := 0.7 + 0.25 * float((t * 7) % 3)
			t += 1
			for w: Vector2 in [e * 0.45, out * 0.45]:
				var w3 := Vector3(w.x, 0.0, w.y)
				var base := Vector3(m.x, gy + 0.05, m.y)
				var nrm := Vector3(-w.y, 0.0, w.x).normalized()
				_tri(base - w3, base + w3, base + Vector3(0.0, h, 0.0), nrm, col, nn, nn, nn, -1.0)
				_tri(base + w3, base - w3, base + Vector3(0.0, h, 0.0), -nrm, col.darkened(0.1), nn, nn, nn, -1.0)


## The Rotunda's stair for crowds.gd: [[seat point, yaw, tread], ...] on its treads, a row on
## every second tread across the steps east of the walking side (1.9 m along the west wall stays
## free), people facing down the stair to the plaza; `n` the tread count `_sunk_treads` lays
## (tread k's top is lerp(ha, hb, k / n)) and the stair's key, so the sitters take those heights.
static func rotunda_steps_plan(e: Dictionary) -> Dictionary:
	if e.is_empty():
		return {"seats": [], "centre": Vector2.ZERO, "stair": "", "n": 1}
	var ring := PackedVector2Array(e["ring"])
	var a: Vector2 = e["a"]
	var b: Vector2 = e["b"]
	var length := a.distance_to(b)
	var d := (b - a) / length
	var side := Vector2(-d.y, d.x)
	var yaw := atan2(-d.x, -d.y)
	var n := maxi(3, roundi(float(e.get("drop", 3.6)) / 0.16))
	var tread := length / n
	var seats: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1966
	for k in range(2, n - 1, 2):
		var s := (k + 0.55) * tread
		var lo := INF
		var hi := -INF
		var strip := PackedVector2Array([a + d * (s - 0.1) - side * 40.0, a + d * (s + 0.1) - side * 40.0,
				a + d * (s + 0.1) + side * 40.0, a + d * (s - 0.1) + side * 40.0])
		for poly in Geometry2D.intersect_polygons(strip, ring):
			for q in poly:
				lo = minf(lo, (q - a).dot(side))
				hi = maxf(hi, (q - a).dot(side))
		var x := lo + 1.9 + rng.randf_range(0.0, 0.4)
		while x < hi - 0.45:
			var p := a + d * s + side * (x + rng.randf_range(-0.1, 0.1))
			seats.append([p, yaw + rng.randf_range(-0.35, 0.35), k])
			x += rng.randf_range(0.7, 1.1)
	return {"seats": seats, "centre": (a + b) * 0.5, "stair": str(e["key"]), "n": n}


## The Rotunda's lower floor at the foot of its stair: a glazed doorway across the landing 2.5 m
## past the last step, dark glass in a steel frame under a concrete lintel up to the street.
func _sunk_doorway(sk: Dictionary) -> void:
	var a: Vector2 = sk["a"]
	var b: Vector2 = sk["b"]
	var d := (b - a).normalized()
	var side := Vector2(-d.y, d.x)
	var at := b + d * 2.5
	var hits := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([at - side * 20.0, at + side * 20.0]), sk["ring"])
	if hits.is_empty() or (hits[0] as PackedVector2Array).size() < 2:
		return
	var seg: PackedVector2Array = hits[0]
	var p0 := seg[0]
	var p1 := seg[seg.size() - 1]
	var f := float(sk["hb"])
	var u := _sunk_upper(at, d)
	var n := Vector3(-d.x, 0.0, -d.y)
	_mode = M_GLASS_ROOF
	_quad(Vector3(p0.x, f, p0.y), Vector3(p1.x, f, p1.y), Vector3(p1.x, f + 2.4, p1.y), Vector3(p0.x, f + 2.4, p0.y), n, Color("#33424d"))
	_mode = M_STONE
	_quad(Vector3(p0.x, f + 2.4, p0.y), Vector3(p1.x, f + 2.4, p1.y), Vector3(p1.x, u + 0.12, p1.y), Vector3(p0.x, u + 0.12, p0.y), n, SUNK_CONCRETE)
	var mid := (p0 + p1) * 0.5
	for p: Vector2 in [p0.lerp(p1, 0.04), mid, p1.lerp(p0, 0.04)]:
		_beam(Vector3(p.x, f, p.y) - Vector3(d.x, 0.0, d.y) * 0.05, Vector3(p.x, f + 2.4, p.y) - Vector3(d.x, 0.0, d.y) * 0.05, 0.08, SUNK_RAIL, false)


## Where a sunken entry's `walk` leaves its ring (the passage's mouth under the street): a dark
## opening 2.2 m wide and 2.3 m tall on that edge, just inside the retaining face, so the walkers
## going in pass behind the face and under the street (pedestrians.gd hides them there).
func _sunk_mouth(sk: Dictionary) -> void:
	var walk: PackedVector2Array = sk["walk"]
	if walk.size() < 2:
		return
	var ring: PackedVector2Array = sk["ring"]
	var w0 := walk[walk.size() - 2]
	var w1 := walk[walk.size() - 1]
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(w0, w1, a, b)
		if hit == null:
			continue
		var at: Vector2 = hit
		var d := (b - a).normalized()
		var inward := (w0 - w1).normalized()
		var f := float(map.sunk_level(sk, at))
		var p0 := at - d * 1.1 + inward * 0.03
		var p1 := at + d * 1.1 + inward * 0.03
		var n := Vector3(inward.x, 0.0, inward.y)
		_mode = M_STONE
		_quad(Vector3(p0.x, f - 0.3, p0.y), Vector3(p1.x, f - 0.3, p1.y), Vector3(p1.x, f + 2.3, p1.y), Vector3(p0.x, f + 2.3, p0.y),
				n, PASSAGE_DARK)
		# A lighter lintel band over the opening.
		_quad(Vector3(p0.x, f + 2.3, p0.y), Vector3(p1.x, f + 2.3, p1.y), Vector3(p1.x, f + 2.55, p1.y), Vector3(p0.x, f + 2.55, p0.y),
				n, PARAPET_TOP)
		return


## A steel canopy over a pavement flight (its ring): posts along both long sides every ~2.6 m on
## the parapet, a beam along each side and across every bay at 2.8 m over the street, glass in
## the lower bays only where posters hang (the green Śródmieście canopies carry ads), the roof
## left open between the beams (the glass there would hide the stair and its people from the
## game's camera: the frame reads as the canopy).
func _sunk_canopy(sk: Dictionary) -> void:
	var ring: PackedVector2Array = sk["ring"]
	if ring.size() != 4:
		return
	var col := CANOPY_GREEN if str(sk["style"]) == "canopy_green" else CANOPY_DARK
	# The long sides: ring[0]-ring[1] and ring[3]-ring[2] (the top end ring[3]-ring[0]).
	var sides := [[ring[0], ring[1]], [ring[3], ring[2]]]
	var length := ring[0].distance_to(ring[1])
	var n := maxi(2, roundi(length / 2.6))
	var top: float = map._grid_height(ring[0].x, ring[0].y)
	for sd: Array in sides:
		var a: Vector2 = sd[0]
		var b: Vector2 = sd[1]
		var d := (b - a) / length
		var y := top + 2.8
		for k in n + 1:
			var p := a + d * (length * k / n)
			var g: float = map._grid_height(p.x, p.y)
			_beam(Vector3(p.x, g + 0.9, p.y), Vector3(p.x, y, p.y), 0.1, col, false)
		_beam(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), 0.14, col, false)
	for k in n + 1:
		var t := float(k) / n
		var p := ring[0].lerp(ring[1], t)
		var q := ring[3].lerp(ring[2], t)
		_beam(Vector3(p.x, top + 2.8, p.y), Vector3(q.x, top + 2.8, q.y), 0.08, col, false)
	# Posters behind glass in the two middle bays of both long sides (green canopies only).
	if str(sk["style"]) != "canopy_green":
		return
	var c := 0
	for sd: Array in sides:
		var a: Vector2 = sd[0]
		var b: Vector2 = sd[1]
		var d := (b - a) / length
		var out := Vector2(d.y, -d.x)
		var mid := (ring[0] + ring[1] + ring[2] + ring[3]) * 0.25
		if out.dot(a - mid) < 0.0:
			out = -out
		for k: int in [n / 2 - 1, n / 2]:
			if k < 0 or k >= n:
				continue
			var p0 := a + d * (length * k / n + 0.25) + out * 0.02
			var p1 := a + d * (length * (k + 1) / n - 0.25) + out * 0.02
			var g: float = map._grid_height(p0.x, p0.y)
			var nn := Vector3(out.x, 0.0, out.y)
			_mode = M_STONE
			_quad(Vector3(p0.x, g + 0.9, p0.y), Vector3(p1.x, g + 0.9, p1.y), Vector3(p1.x, g + 2.6, p1.y), Vector3(p0.x, g + 2.6, p0.y),
					nn, POSTERS[c % POSTERS.size()])
			_quad(Vector3(p1.x, g + 0.9, p1.y), Vector3(p0.x, g + 0.9, p0.y), Vector3(p0.x, g + 2.6, p0.y), Vector3(p1.x, g + 2.6, p1.y),
					-nn, CANOPY_GLASS)
			c += 1


# --- Muzeum Sztuki Nowoczesnej ------------------------------------------------------------

## The Museum of Modern Art (Thomas Phifer, 2024), first scene item 1, built to its spec
## docs/landmarks/specs/msn.md (v2, 2026-11-26, from Street View 2024/2026 and photos of the
## finished building): two stacked white boxes, the upper one overhanging the lower by 0.4 m over
## a shadowed seam that is glazed only in a few long ribbon runs, the lower box floating on a
## glazed ground floor behind deep white piers, a few large deliberate windows set into the white
## (the deep city-room cut-out on Marszałkowska, the wide window and the tall entrance cut towards
## the Palace), a glass grid over the flat roof. Its plan frame: u along the long side (north end,
## Świętokrzyska, at u < 0), +v towards the Palace, -v Marszałkowska.
const MSN := Vector2(-1022.4, 100.15)
const MSN_AXIS := Vector2(0.3445, 0.9388)
const MSN_HU := 51.85          # the upper box's half length and half width (the outline)
const MSN_HV := 19.9
const MSN_LOWER_IN := 0.4      # the lower box sits this far in under the upper one
const MSN_SEAM_IN := 0.8       # and the seam between them this far
const MSN_CORE := Vector2(45.8, 13.95)  # the glazed ground floor's half plan
const MSN_BASE := 3.5          # the soffit (photos: the ground floor is 3-3.5 m, people for scale)
const MSN_SEAM := Vector2(12.5, 13.6)  # the lower box's top and the upper box's bottom (F's dusk photo, 2026-11-26)
const MSN_H := 26.0
## The fins' centres (u) on the Marszałkowska face (v -17.4) and the Plac Defilad face (v +17.35).
const MSN_FINS_EAST := [-50.4, -39.4, -26.4, -18.4, -10.4, 0.4, 7.4, 15.3, 26.4, 33.8, 40.8, 50.4]
const MSN_FINS_WEST := [-50.4, -39.5, -32.5, -26.5, -18.5, -10.6, 0.4, 7.3, 15.2, 26.2, 33.7, 40.7, 50.3]
## The ends' fins, turned along u: [u, v].
const MSN_FINS_END := [[-49.4, 3.95], [-49.4, -8.5], [49.4, 6.3], [49.4, -8.55]]
## The roof (ortho.jpg, checked 2026-11-01 and 2026-11-26): one gridded glass field inside a white
## edge MSN_SKY_EDGE wide, two small square light wells [u, v, half side], the fans' housing.
const MSN_SKY_EDGE := 2.2
const MSN_WELLS := [Vector3(5.0, 4.9, 4.0), Vector3(31.5, -0.6, 3.5)]
const MSN_FANS := [-12.5, 1.8, 1.5, 3.0, 1.2]  # u, v, half sizes, height
## The openings, spec section 3: [face, along0, along1, y0, y1, depth, part]. face: "-v"
## Marszałkowska, "+v" Plac Defilad, "+u" the south end, "-u" the north end; part "up" for the
## upper box's wall, "low" for the lower box's (0.4 m further in). along is u on the long faces,
## v on the ends. Every window is set into the wall (deep reveals: the building's look).
const MSN_OPENINGS := [
	["-v", -4.2, 9.8, 15.7, 20.9, 3.0, "up"],      # loggia: the city room on Marszałkowska
	["-v", -33.4, -30.3, 15.5, 19.5, 0.4, "up"],   # win_mn
	["-v", -7.7, -0.3, 6.8, 9.7, 0.4, "low"],      # low_mc
	["-v", 16.0, 23.4, 6.8, 9.7, 0.4, "low"],      # low_ms
	["-v", -32.4, -30.3, 6.8, 9.0, 0.4, "low"],    # low_mn
	["+v", -9.0, 9.0, 15.2, 20.8, 0.4, "up"],      # w1: the wide window towards the Palace
	["+v", 14.0, 23.0, 3.5, 10.5, 3.0, "low"],     # entry: the tall entrance cut
	["+v", -9.0, 3.0, 6.8, 9.7, 0.4, "low"],       # low_pc
	["+v", -27.0, -24.5, 7.3, 9.5, 0.4, "low"],    # low_pn
	["+u", -7.5, -1.5, 15.3, 20.5, 0.4, "up"],     # win_s
	["+u", -3.3, -1.5, 6.3, 10.4, 0.4, "low"],     # low_s
	["-u", -15.0, -9.0, 15.6, 22.0, 0.4, "up"],    # w4 (F's night photo)
	["-u", -14.0, -11.5, 6.8, 9.3, 0.4, "low"],    # w5 (F's night photo)
]
## The ribbon windows in the seam: [face, u0, u1] (spec rib_*), 14.1 to 14.9 m.
const MSN_RIBBONS := [["-v", 18.0, 51.0], ["-v", -45.5, -0.5], ["+v", -43.0, -31.0], ["+v", 20.0, 49.0]]
## The south end's east part stands proud and higher (3.jpg, 4.jpg): u0, u1, v0, v1, top.
const MSN_PANEL := [51.85, 52.25, -19.9, -7.9, 27.4]
## The roofline steps (3.jpg, 4.jpg; F's dusk photo shows the Marszałkowska edge flat): the south part of the box stands
## about a metre higher, as upstands on the roof edge [u0, u1, v0, v1] up to MSN_STEP.
const MSN_STEP := 27.1
const MSN_UPSTANDS := [[8.0, 51.85, 19.5, 19.9], [51.45, 51.85, -7.9, 19.5]]
## The north-west corner block (OSM: u -64.3..-53.8, v 16.5..27, 26 m on an 8 m base).
const MSN_CORNER_U := -64.3
const MSN_CORNER_V := Vector2(16.5, 27.0)
## The night look (F's night photos, 2026-11-26): the white walls are floodlit (a lit wall,
## M_MEMBRANE + 0.5), the gallery roof stays dark with a few panels faintly lit (building.gdshader
## glass_roof, param 0.75), the light wells glow dimly; the windows and ribbons glow warm.
const MSN_LIT := M_MEMBRANE + 0.5
const MSN_ROOF_GLASS := M_GLASS_ROOF + 0.75
const MSN_WELL_GLASS := M_MEMBRANE
const MSN_WHITE := Color("#ebe9e3")
const MSN_SEAM_WHITE := Color("#c9c8c2")
const MSN_ROOF := Color("#d9d8d2")
const MSN_LOBBY := Color("#a9c3cd")
const MSN_RIBBON := Color("#526872")
const MSN_WINDOW := Color("#8fa9b6")
const MSN_SKY_GLASS := Color("#cfd8dc")
const MSN_SKYLIGHT := Color("#7d97a2")  # the two light wells: darker glazing (ortho.jpg)
const MSN_FAN := Color("#9a9d9e")
func _find_msn() -> void:
	var outline := _landmark("Muzeum Sztuki Nowoczesnej")
	if outline.size() < 3:
		return
	# Grown a metre so the fins and the mapped parts on the edge go with it.
	var grown := Geometry2D.offset_polygon(outline, 1.0, Geometry2D.JOIN_MITER)
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var corner := _rect((MSN_CORNER_U - MSN_HU) * 0.5, (MSN_CORNER_V.x + MSN_CORNER_V.y) * 0.5,
			(MSN_HU + MSN_CORNER_U) * -0.5 + 1.0, (MSN_CORNER_V.y - MSN_CORNER_V.x) * 0.5 + 1.0)
	_add_site("msn", [grown[0] if not grown.is_empty() else outline, corner])


func _build_msn(_site: Dictionary) -> void:
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var box := _rect(0.0, 0.0, MSN_HU, MSN_HV)
	_g = _ground_under(box)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The openings first, so the box walls drawn after them are cut round them.
	for o: Array in MSN_OPENINGS:
		var inset := MSN_LOWER_IN if o[6] == "low" else 0.0
		_msn_recess(o[0], inset, o[1], o[2], g + o[3], g + o[4], o[5])
	_mode = M_PAVILION
	for r: Array in MSN_RIBBONS:
		var s := -1.0 if r[0] == "-v" else 1.0
		var hv := MSN_HV - MSN_SEAM_IN
		_wall(_w(r[1], s * hv), _w(r[2], s * hv), g + MSN_SEAM.x + 0.1, g + MSN_SEAM.y - 0.1, _b * s, MSN_RIBBON)
	# corner: the full-height block standing out at the north-west corner (OSM's part at
	# (-1062, 54), closed up to the box), solid to the ground, a glazed top a metre under the roof.
	var corner := PackedVector2Array([_w(MSN_CORNER_U, MSN_CORNER_V.x), _w(-MSN_HU, MSN_CORNER_V.x),
			_w(-MSN_HU, MSN_CORNER_V.y), _w(MSN_CORNER_U, MSN_CORNER_V.y)])
	_prism(corner, g - 0.4, g + MSN_H - 1.0, MSN_WHITE, MSN_SKY_GLASS, MSN_LIT, M_GLASS_ROOF)
	# core: the glazed lobby, lit warm at night.
	_prism(_rect(0.0, 0.0, MSN_CORE.x, MSN_CORE.y), g - 0.4, g + MSN_BASE, MSN_LOBBY, none, M_PAVILION)
	# fins
	for u: float in MSN_FINS_EAST:
		_prism(_rect(u, -17.4, 0.5, 1.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, MSN_LIT)
	for u: float in MSN_FINS_WEST:
		_prism(_rect(u, 17.35, 0.5, 1.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, MSN_LIT)
	for f: Array in MSN_FINS_END:
		_prism(_rect(f[0], f[1], 1.5, 0.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, MSN_LIT)
	_mode = MSN_LIT
	var lu := MSN_HU - MSN_LOWER_IN
	var lv := MSN_HV - MSN_LOWER_IN
	var su := MSN_HU - MSN_SEAM_IN
	var sv := MSN_HV - MSN_SEAM_IN
	# soffit
	_msn_ring(lu, lv, MSN_CORE.x, MSN_CORE.y, g + MSN_BASE, Vector3.DOWN, MSN_WHITE.darkened(0.12))
	_mode = M_STONE
	# lower
	_prism(_rect(0.0, 0.0, lu, lv), g + MSN_BASE, g + MSN_SEAM.x, MSN_WHITE, none, MSN_LIT)
	# ledge, seam, under: the lower box's top, the shadowed band, the upper box's overhang.
	_msn_ring(lu, lv, su, sv, g + MSN_SEAM.x, Vector3.UP, MSN_WHITE)
	_prism(_rect(0.0, 0.0, su, sv), g + MSN_SEAM.x, g + MSN_SEAM.y, MSN_SEAM_WHITE, none, M_STONE)
	_msn_ring(MSN_HU, MSN_HV, su, sv, g + MSN_SEAM.y, Vector3.DOWN, MSN_WHITE.darkened(0.15))
	# upper
	_prism(box, g + MSN_SEAM.y, g + MSN_H, MSN_WHITE, none, MSN_LIT)
	# panel: the south end's proud, higher east part.
	_prism(_lpoly([[MSN_PANEL[0], MSN_PANEL[2]], [MSN_PANEL[1], MSN_PANEL[2]], [MSN_PANEL[1], MSN_PANEL[3]],
			[MSN_PANEL[0], MSN_PANEL[3]]]), g + MSN_SEAM.y, g + MSN_PANEL[4], MSN_WHITE, MSN_ROOF, MSN_LIT, M_STONE)
	# sky: the glass field over the top galleries, lit from inside at night, round the wells;
	# drawn first so the stone roof after it keeps only the white edge.
	var wells: Array = []
	for w: Vector3 in MSN_WELLS:
		wells.append(_rect(w.x, w.y, w.z, w.z))
	_mode = MSN_ROOF_GLASS
	_cap_holes(_rect(0.0, 0.0, MSN_HU - MSN_SKY_EDGE, MSN_HV - MSN_SKY_EDGE), wells, g + MSN_H, MSN_SKY_GLASS)
	_mode = M_STONE
	_cap_holes(box, wells, g + MSN_H, MSN_ROOF)
	# wells: the two light wells, glazed flush with the roof, darker than the grid round them.
	_mode = MSN_WELL_GLASS
	for well: PackedVector2Array in wells:
		_cap(well, g + MSN_H, MSN_SKYLIGHT)
	_mode = M_STONE
	# upstands: the roofline's step up over the south part.
	for r: Array in MSN_UPSTANDS:
		_prism(_lpoly([[r[0], r[2]], [r[1], r[2]], [r[1], r[3]], [r[0], r[3]]]), g + MSN_H, g + MSN_STEP, MSN_WHITE, MSN_ROOF,
				MSN_LIT, M_STONE)
	# fans: the plant's housing on the roof.
	_prism(_rect(MSN_FANS[0], MSN_FANS[1], MSN_FANS[2], MSN_FANS[3]), g + MSN_H, g + MSN_H + MSN_FANS[4], MSN_FAN,
			MSN_FAN.darkened(0.2), M_STONE, M_STONE)
	_collide(box)


## One window or cut set `depth` into a face of the museum (spec section 3): the opening goes into
## _walls undrawn, so the box's wall drawn after it is cut round it; then the glass at the back
## (lit warm at night), the two reveals, the sill and the head. `inset` is how far the face itself
## sits in from the outline (the lower box: 0.4 m). On the long faces s0..s1 run along u, on the
## ends along v.
func _msn_recess(face: String, inset: float, s0: float, s1: float, y0: float, y1: float, depth: float) -> void:
	var sg := -1.0 if face.begins_with("-") else 1.0
	var on_u := face.ends_with("u")
	var plane := sg * ((MSN_HU if on_u else MSN_HV) - inset)
	var n := (_a if on_u else _b) * sg
	var along := _b if on_u else _a
	var at := func(s: float, d: float) -> Vector2:
		return _w(plane - sg * d, s) if on_u else _w(s, plane - sg * d)
	var o0: Vector2 = at.call(s0, 0.0)
	var o1: Vector2 = at.call(s1, 0.0)
	var i0: Vector2 = at.call(s0, depth)
	var i1: Vector2 = at.call(s1, depth)
	_walls.append(PackedFloat32Array([o0.x, o0.y, o1.x, o1.y, y0, y1, n.x, n.y]))
	_mode = M_PAVILION
	_wall(i0, i1, y0, y1, n, MSN_WINDOW)
	_mode = M_STONE
	_wall(o0, i0, y0, y1, along, MSN_WHITE.darkened(0.1))
	_wall(i1, o1, y0, y1, -along, MSN_WHITE.darkened(0.18))
	_quad(Vector3(o0.x, y0, o0.y), Vector3(o1.x, y0, o1.y), Vector3(i1.x, y0, i1.y), Vector3(i0.x, y0, i0.y), Vector3.UP, MSN_WHITE)
	_quad(Vector3(o0.x, y1, o0.y), Vector3(o1.x, y1, o1.y), Vector3(i1.x, y1, i1.y), Vector3(i0.x, y1, i0.y), Vector3.DOWN,
			MSN_WHITE.darkened(0.25))


## A flat ring in the museum's frame between the half plans (hu, hv) and (iu, iv) at y, facing
## `n` (up for a ledge, down for a soffit): four quads.
func _msn_ring(hu: float, hv: float, iu: float, iv: float, y: float, n: Vector3, col: Color) -> void:
	for r: Array in [[-hu, -hv, -iu, hv], [iu, -hv, hu, hv], [-iu, -hv, iu, -iv], [-iu, iv, iu, hv]]:
		var p0 := _w(r[0], r[1])
		var p1 := _w(r[2], r[1])
		var p2 := _w(r[2], r[3])
		var p3 := _w(r[0], r[3])
		_quad(Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), Vector3(p3.x, y, p3.y), n, col)


# --- Domy Towarowe Centrum (the Eastern Wall) ----------------------------------------------

## First scene item 3 (spec docs/landmarks/specs/dtc.md, 2026-10-31): the three glass department
## stores on Marszałkowska's east side, right of the car at the start (Junior beside it, Sawa and
## Wars behind), built from their OpenStreetMap parts: the recessed glazed shop floor (mh 0,
## 5.5 m, its mapped piers), the cantilevered curtain-wall box over it (5.5 to 17.5 m, the
## landmark's outline), an aluminium fascia at the slab and a cornice at the roof, a set-back top
## storey, and each store's name on the roof as a lit parody sign facing the street.
const DTC := [{"osm": "Junior", "sign": "JUNIOREK"}, {"osm": "Sawa", "sign": "SAWKA"}, {"osm": "Wars", "sign": "WARSIK"}]
const DTC_BASE := 5.5        # the shop floor's top (OSM part h 5.5)
const DTC_FASCIA := 0.8      # the slab edge over the shop windows
const DTC_BODY := 17.5       # the curtain wall's top (OSM part h 17.5)
const DTC_CORNICE := 0.9   # the light band along the roof edge (F's aerials and street photos)
const DTC_TOP := 3.0         # the top storey (OSM parts 17.5 to 20.5)
const DTC_TOP_IN := 1.6      # and how far it stands back from the long sides (F's photos 2026-11-15: the crown nearly sits on the cornice)
const DTC_TOP_END := 3.0     # and from the ends (F's photos 2026-11-15: the louvres run almost to the corner)
const DTC_TOP_ROUND := 3.5   # the crown's rounded corners (the corner by the Half Price banner)
const DTC_RECESS := 4.5      # the shop floor's set-back under the cantilever (photos: 4-5 m)
## Down Marszałkowska (south-south-east) from the stores: the game's camera looks up the street,
## so the stores' south ends face it.
const DTC_SOUTH := Vector2(0.349, 0.937)
const DTC_SHOP := Color("#6e7f84")      # the dark shop windows deep under the cantilever, lit warm at night
const DTC_GLASS := Color("#a6bdb4")     # the curtain wall: frosted pale green-grey panels (F's photos 2026-11-15)
const DTC_ALU := Color("#c9cdcf")       # fascia, cornice, soffit: light aluminium
const DTC_TOP_WALL := Color("#8a6d4a")  # the crown: vertical bronze louvres (F's photos 2026-11-15)
const DTC_ROOF := Color("#4f5559")      # the main roof
const DTC_TOP_ROOF := Color("#5d6468")  # the top storey's roof
const DTC_SOFFIT := Color("#eceeea")    # the arcade's white slatted ceiling (F's photo of the pasaż)
const DTC_SKY := Color("#cfd8dc")       # the roof lights, lit at night
const DTC_SIGN := Color(1.0, 0.86, 0.55)
## The stores' shops and ads (printed banners on the curtain walls, lit shop fronts under the
## cantilever, the furniture outside) come from data/eastern_wall_shops.json, as the stores are
## now (2026-11: UNIKAT where Zara was, LUKA's bakery, the four-floor TAK MAKS, the two-storey
## FROGS XXL on H&M's corner): these shops change often, so they are swapped there, not here.
const DTC_SHOPS_FILE := "res://data/eastern_wall_shops.json"
## The street face (Marszałkowska), the back, the far end: the faces the file names.
const DTC_EAST := Vector2(0.937, -0.349)


## The file's stores (osm name -> {banners, fronts, props}); empty when it is missing.
static func dtc_shops() -> Dictionary:
	var f := FileAccess.get_file_as_string(DTC_SHOPS_FILE)
	var json: Variant = JSON.parse_string(f) if f != "" else null
	if json is Dictionary and (json as Dictionary).get("stores") is Dictionary:
		return json["stores"]
	return {}


static func _dtc_dir(face: String) -> Vector2:
	match face:
		"south":
			return DTC_SOUTH
		"north":
			return -DTC_SOUTH
		"east":
			return DTC_EAST
	return -DTC_EAST


func _find_dtc() -> void:
	var zone: Array[PackedVector2Array] = []
	for d: Dictionary in DTC:
		var outline := _landmark(d["osm"])
		if outline.size() < 3:
			continue
		var grown := Geometry2D.offset_polygon(outline, 1.0, Geometry2D.JOIN_MITER)
		zone.append(grown[0] if not grown.is_empty() else outline)
	_add_site("dtc", zone)


func _build_dtc(_site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	var skin := M_SKIN + float(S_EASTWALL) / 16.0
	var shops := dtc_shops()
	for d: Dictionary in DTC:
		var outline := _landmark(d["osm"])
		if outline.size() < 3:
			continue
		_g = _ground_under(outline)
		var g := _g
		# shop: the dark glazed ground floor, its mapped outline (the piers are its jogs) kept at
		# least DTC_RECESS in from the edge (the photo check: 4-5 m under the cantilever).
		var mapped := PackedVector2Array()
		for part in _parts_in(outline, func(b: Dictionary) -> bool: return float(b["mh"]) < 0.5 and float(b["h"]) < DTC_BASE + 1.0):
			var q := _pts(part["p"])
			if _area(q) > _area(mapped):
				mapped = q
		var drawn := Geometry2D.offset_polygon(outline, -DTC_RECESS, Geometry2D.JOIN_MITER)
		var shop: PackedVector2Array = drawn[0] if not drawn.is_empty() else outline
		if _area(mapped) > _area(outline) * 0.5:
			var both := _largest(Geometry2D.intersect_polygons(mapped, shop))
			if _area(both) > _area(shop) * 0.6:
				shop = both
		_prism(shop, g - 0.4, g + DTC_BASE, DTC_SHOP, none, M_PAVILION)
		# body: the fascia over the shops, the curtain wall, the cornice and the roof.
		_prism(outline, g + DTC_BASE, g + DTC_BASE + DTC_FASCIA, DTC_ALU, none, M_STONE)
		_prism(outline, g + DTC_BASE + DTC_FASCIA, g + DTC_BODY - DTC_CORNICE, DTC_GLASS, none, skin)
		_prism(outline, g + DTC_BODY - DTC_CORNICE, g + DTC_BODY, DTC_ALU, DTC_ROOF, M_STONE, M_STONE)
		# soffit: the cantilever's light aluminium underside round the shop floor.
		_mode = M_STONE
		_soffit(outline, g + DTC_BASE, DTC_SOFFIT)
		_dtc_ceiling(outline, shop, g)
		# top: the set-back top storey, 3 m in on the long sides and DTC_TOP_END at the ends.
		var top := _dtc_top(outline)
		if top.size() >= 3:
			var y := g + DTC_BODY + DTC_TOP
			_prism(top, g + DTC_BODY, y, DTC_TOP_WALL, DTC_TOP_ROOF, M_STONE, M_STONE)   # solid bronze: the S_FINS skin is silver-white
			_dtc_roof(top, y, d["osm"] == "Junior")
		var store: Dictionary = shops.get(str(d["osm"]), {})
		_dtc_banners(outline, top, g, store.get("banners", []))
		_dtc_fronts(outline, shop, g, store.get("fronts", []))
		_dtc_props(outline, g, store.get("props", []))
		_dtc_green(outline, g, store.get("roof_green", []))
		_dtc_sign(outline, str(d["sign"]), g + DTC_BODY)
		if d["osm"] == "Junior":
			_dtc_cube(outline, g)
			_dtc_corner_box(outline, g + DTC_BODY)
		_collide(shop)
	_mode = M_STONE
	_dtc_relax()


func _dtc_relax() -> void:
	pass  # the word is on the banner now (_build_scena_relax)


## The top storey's plan: the outline drawn in 3 m, then cut back to DTC_TOP_END from each end
## (along the street).
func _dtc_top(outline: PackedVector2Array) -> PackedVector2Array:
	var inset := Geometry2D.offset_polygon(outline, -DTC_TOP_IN, Geometry2D.JOIN_MITER)
	if inset.is_empty():
		return PackedVector2Array()
	var lo := INF
	var hi := -INF
	var c := _centre(outline)
	for q in outline:
		var s := (q - c).dot(DTC_SOUTH)
		lo = minf(lo, s)
		hi = maxf(hi, s)
	var across := Vector2(-DTC_SOUTH.y, DTC_SOUTH.x)
	var a := lo + DTC_TOP_END
	var b := hi - DTC_TOP_END
	var band := PackedVector2Array([c + DTC_SOUTH * a - across * 60.0, c + DTC_SOUTH * b - across * 60.0,
			c + DTC_SOUTH * b + across * 60.0, c + DTC_SOUTH * a + across * 60.0])
	var crown := _largest(Geometry2D.intersect_polygons(inset[0], band))
	# Rounded corners: draw it in and out again with round joins.
	var in_ := Geometry2D.offset_polygon(crown, -DTC_TOP_ROUND, Geometry2D.JOIN_MITER)
	if not in_.is_empty():
		var out_ := Geometry2D.offset_polygon(in_[0], DTC_TOP_ROUND, Geometry2D.JOIN_ROUND)
		if not out_.is_empty() and _area(out_[0]) > _area(crown) * 0.85:
			return out_[0]
	return crown


## The arcade's ceiling (F's photo of the pasaż): a row of small recessed lights down the middle of
## the white soffit, between the cantilever's edge and the shop glass, and a few dark dome cameras.
## Flat quads and tiny prisms only (about 2 tris a light).
func _dtc_ceiling(outline: PackedVector2Array, shop: PackedVector2Array, g: float) -> void:
	var y := g + DTC_BASE - 0.07
	var col := Color("#6c7074")
	var c := _centre(outline)
	var across := Vector2(-DTC_SOUTH.y, DTC_SOUTH.x)
	var lo := INF
	var hi := -INF
	for q in outline:
		var sv := (q - c).dot(DTC_SOUTH)
		lo = minf(lo, sv)
		hi = maxf(hi, sv)
	# The street-side row: a ray in from the street face finds the edge and the glass.
	var n := 0
	var sv := lo + 5.0
	while sv < hi - 4.0:
		var from := c + DTC_SOUTH * sv + DTC_EAST * -60.0
		var edge := _dtc_ray(outline, from, DTC_EAST, 120.0)
		var glass := _dtc_ray(shop, from, DTC_EAST, 120.0)
		if not edge.is_empty() and not glass.is_empty():
			var e: Vector2 = edge[0]
			var gl: Vector2 = glass[0]
			if e.distance_to(gl) > 2.0 and e.distance_to(gl) < 8.0:
				var p := e.lerp(gl, 0.5)
				var h := 0.16
				_mode = M_LAMP
				_quad(Vector3(p.x - h, y, p.y - h), Vector3(p.x + h, y, p.y - h), Vector3(p.x + h, y, p.y + h), Vector3(p.x - h, y, p.y + h), Vector3.DOWN, Color("#fff4d6"))
				if n % 5 == 2:
					_mode = M_STONE
					_prism(_square(e.lerp(gl, 0.3), 0.2), y - 0.35, y + 0.02, col, col, M_STONE, M_STONE)
				n += 1
		sv += 6.0
	_mode = M_STONE


## Junior's cube (F's photo of the arcade's end): a hanging silver box, its faces to the street and
## down the arcade carrying the green bullseye and JUNIOR in green, under the slab at the south end
## of the store's street face.
func _dtc_cube(outline: PackedVector2Array, g: float) -> void:
	var spot := _dtc_spot(outline, "west", 0.97, 0.0)
	if spot.is_empty():
		return
	var o: Vector2 = spot[2]
	var d: Vector2 = spot[1]
	var m: Vector2 = (spot[0] as Vector2) + o * 0.8 - d * 2.2   # hangs a little in from the corner
	var h := 1.5
	var y0 := g + DTC_BASE - 3.1
	var y1 := g + DTC_BASE - 0.05
	var steel := Color("#aeb4b6")
	_mode = M_STONE
	_prism(PackedVector2Array([m - d * h - o * h, m + d * h - o * h, m + d * h + o * h, m - d * h + o * h]), y0, y1, steel, steel.darkened(0.1), M_STONE, M_STONE)
	var rings := [Color("#2f7a37"), Color("#4f9a45"), Color("#8cc063"), Color("#e6e27a")]
	for face: Array in [[o, d], [d, -o]]:
		var n: Vector2 = face[0]
		var t: Vector2 = face[1]
		var cc := m + n * (h + 0.03)
		var cy := (y0 + y1) * 0.5 - 0.25
		for i in rings.size():
			var r := 1.15 - 0.27 * i
			var nn := n * (0.06 * i)
			var a := cc + nn - t * r
			var b := cc + nn + t * r
			_quad(Vector3(a.x, cy - r, a.y), Vector3(b.x, cy - r, b.y), Vector3(b.x, cy + r, b.y), Vector3(a.x, cy + r, a.y), Vector3(n.x, 0, n.y), rings[i])
	_dtc_words(["JUNIOR"], m + o * (h + 0.06), o, y1 - 0.45, y1 - 0.05, 2.8, 0.4, Color("#2f7a37"))


## The white box on the roof at the corner (F's photos: a rooftop sign box with the city's logo and
## a lit word), parody: a plain white box with CITY in blue, facing the street.
func _dtc_corner_box(outline: PackedVector2Array, y: float) -> void:
	var spot := _dtc_spot(outline, "west", 0.97, 8.0)
	if spot.is_empty():
		return
	var o: Vector2 = spot[2]
	var d: Vector2 = spot[1]
	var m: Vector2 = (spot[0] as Vector2) - o * 2.4 - d * 5.0
	var w := 4.2
	_prism(PackedVector2Array([m - d * w - o * 1.2, m + d * w - o * 1.2, m + d * w + o * 1.2, m - d * w + o * 1.2]), y, y + 5.8,
			Color("#e9ebe9"), Color("#cfd4d6"), M_STONE, M_STONE)
	signs.append(["CITY", Vector3(m.x + o.x * 1.25, y + 2.2, m.y + o.y * 1.25), Vector3(o.x, 0.0, o.y), 0.7 * 2.0 * w / Neon.length_of("CITY"), Color(0.2, 0.5, 0.9)])


## The top storey's roof (the photo check): small square skylights in pairs and 2 x 2
## clusters every 12 m down the middle, a few curved half-cylinder vents, and fewer, larger
## plant boxes at the north end. Junior's roof is stepped: a lighter raised strip over its east
## half, a light-blue glazed skylight block and more plant.
func _dtc_roof(top: PackedVector2Array, y: float, junior: bool) -> void:
	var c := _centre(top)
	var across := Vector2(-DTC_SOUTH.y, DTC_SOUTH.x)
	var lo := INF
	var hi := -INF
	for q in top:
		var s := (q - c).dot(DTC_SOUTH)
		lo = minf(lo, s)
		hi = maxf(hi, s)
	var mid_off := 0.0
	if junior:
		# The raised strip over the east half (the side away from the street).
		var strip := _largest(Geometry2D.intersect_polygons(top, PackedVector2Array([
				c + DTC_SOUTH * (lo - 1.0) + across * 0.5, c + DTC_SOUTH * (hi + 1.0) + across * 0.5,
				c + DTC_SOUTH * (hi + 1.0) - across * 40.0, c + DTC_SOUTH * (lo - 1.0) - across * 40.0])))
		if strip.size() >= 3:
			_prism(strip, y, y + 1.2, DTC_TOP_WALL.darkened(0.08), Color("#848b8f"), M_STONE, M_STONE)
		mid_off = 4.0   # the skylights move onto the lower west half
		# The glazed skylight block, on the strip near the south end.
		var gb := c + DTC_SOUTH * (hi - 14.0) - across * 4.5
		var block := PackedVector2Array([gb - DTC_SOUTH * 5.0 - across * 2.6, gb + DTC_SOUTH * 5.0 - across * 2.6,
				gb + DTC_SOUTH * 5.0 + across * 2.6, gb - DTC_SOUTH * 5.0 + across * 2.6])
		_prism(block, y + 1.2, y + 2.6, Color("#a9c6d6"), Color("#b4d2e0"), M_PAVILION + 0.5, M_GLASS_ROOF)
	var line := c + across * mid_off
	var n := 0
	var s := lo + 6.0
	while s < hi - 5.0:
		var p := line + DTC_SOUTH * s
		if n % 4 == 2:
			# A curved vent, its axis along the store.
			_dtc_vent(p, y)
		else:
			var cluster := n % 2 == 0
			for i in (4 if cluster else 2):
				var off := Vector2(-1.5 if i % 2 == 0 else 1.5, -1.5 if i < 2 else 1.5)
				if not cluster:
					off.y = 0.0
				var q := p + across * off.x + DTC_SOUTH * off.y
				_prism(_rot_square(q, 1.1), y, y + 0.45, DTC_ALU, DTC_SKY, M_STONE, M_GLASS_ROOF)
		s += 12.0
		n += 1
	# The plant: a few large boxes at the north end (more on Junior).
	var boxes := 3 if junior else 2
	for i in boxes:
		var q := line + DTC_SOUTH * (lo + 3.5) + across * (-4.0 + i * 4.0) + (DTC_SOUTH * 6.0 if i == 2 else Vector2.ZERO)
		if Geometry2D.is_point_in_polygon(q, top):
			_prism(_rot_square(q, 1.7), y, y + 1.9, Color("#a3aaac"), Color("#8d9497"), M_STONE, M_STONE)


## A square of half side h with its sides along and across the stores.
func _rot_square(c: Vector2, h: float) -> PackedVector2Array:
	var a := Vector2(-DTC_SOUTH.y, DTC_SOUTH.x)
	return PackedVector2Array([c - DTC_SOUTH * h - a * h, c + DTC_SOUTH * h - a * h, c + DTC_SOUTH * h + a * h, c - DTC_SOUTH * h + a * h])


## A curved half-cylinder vent on the roof, 2 m across and 4 m long along the store.
func _dtc_vent(p: Vector2, y: float) -> void:
	var a := Vector2(-DTC_SOUTH.y, DTC_SOUTH.x)
	var seg := 6
	var col := Color("#b4babd")
	_mode = M_STONE
	var e0 := p - DTC_SOUTH * 2.0
	var e1 := p + DTC_SOUTH * 2.0
	for k in seg:
		var t0 := PI * k / seg
		var t1 := PI * (k + 1) / seg
		var o0 := a * cos(t0)
		var o1 := a * cos(t1)
		var h0 := sin(t0)
		var h1 := sin(t1)
		var nm := (t0 + t1) * 0.5
		var n := Vector3(a.x * cos(nm), sin(nm), a.y * cos(nm))
		_quad(Vector3((e0 + o0).x, y + h0, (e0 + o0).y), Vector3((e1 + o0).x, y + h0, (e1 + o0).y),
				Vector3((e1 + o1).x, y + h1, (e1 + o1).y), Vector3((e0 + o1).x, y + h1, (e0 + o1).y), n, col)
		for e: Vector2 in [e0, e1]:
			var out := -DTC_SOUTH if e == e0 else DTC_SOUTH
			var nn := Vector2(-1, -1)
			_tri(Vector3(e.x, y, e.y), Vector3((e + o0).x, y + h0, (e + o0).y), Vector3((e + o1).x, y + h1, (e + o1).y),
					Vector3(out.x, 0, out.y), col.darkened(0.1), nn, nn, nn, -1.0)


## Where a sign `w` m wide goes on the face of `poly` that looks along the file's `face` ("west" is
## the street), `at` 0..1 from its left end to its right as read from outside: a ray in from
## outside finds the wall there (the outlines jog, so the wall is found, not assumed).
## [point on the wall, along the wall (to the reader's right), the wall's outward normal, the
## face's length], or [] when the ray meets no wall facing that way.
func _dtc_spot(poly: PackedVector2Array, face: String, at: float, w: float) -> Array:
	var want := _dtc_dir(face)
	var right := Vector2(want.y, -want.x)
	var lo := INF
	var hi := -INF
	var top := -INF
	for q in poly:
		lo = minf(lo, q.dot(right))
		hi = maxf(hi, q.dot(right))
		top = maxf(top, q.dot(want))
	var r := (lo + hi) * 0.5
	if hi - lo > w + 0.6:
		r = lerpf(lo + w * 0.5 + 0.3, hi - w * 0.5 - 0.3, clampf(at, 0.0, 1.0))
	var hit := _dtc_ray(poly, right * r + want * (top + 1.0), -want, 80.0)
	if hit.is_empty() or (hit[1] as Vector2).dot(want) < 0.8:
		return []
	var o: Vector2 = hit[1]
	return [hit[0], Vector2(o.y, -o.x), o, hi - lo]


## The first edge of `poly` a ray from `from` along `dir` meets within `far` m: [the point, that
## edge's outward normal], or [].
func _dtc_ray(poly: PackedVector2Array, from: Vector2, dir: Vector2, far: float) -> Array:
	var best := INF
	var out := []
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(from, from + dir * far, a, b)
		if hit != null and from.distance_to(hit as Vector2) < best:
			best = from.distance_to(hit as Vector2)
			out = [hit as Vector2, _out(poly, a, b)]
	return out


## Lines of lit letters (the neon atlas) centred at `at` on a face with outward normal `o`, between
## y0 and y1, at most `w` m wide and `cap` m a row.
func _dtc_words(lines: Array, at: Vector2, o: Vector2, y0: float, y1: float, w: float, cap: float, ink: Color) -> void:
	if lines.is_empty():
		return
	var row := Neon.ROW_H * Neon.PIXEL
	var k := minf(cap, 0.85 * (y1 - y0) / lines.size()) / row
	for l: String in lines:
		k = minf(k, 0.8 * w / Neon.length_of(l))
	var step := row * k
	var y := (y0 + y1) * 0.5 - 0.5 * step * lines.size()
	for i in range(lines.size() - 1, -1, -1):
		signs.append([str(lines[i]), Vector3(at.x, y, at.y), Vector3(o.x, 0.0, o.y), k, ink])
		y += step


## The printed ad banners (the Mac photo check; what they say: data/eastern_wall_shops.json): big
## posters the curtain wall's height (or the top storey's), 0.2 m proud of the glass, each a colour
## with its words lit on it.
func _dtc_banners(outline: PackedVector2Array, top: PackedVector2Array, g: float, list: Array) -> void:
	for spec: Dictionary in list:
		var on_top := bool(spec.get("top", false))
		var poly := top if on_top else outline
		if poly.size() < 3:
			continue
		var w := float(spec.get("w", 10.0))
		var spot := _dtc_spot(poly, str(spec.get("face", "south")), float(spec.get("at", 0.5)), w)
		if spot.is_empty() or float(spot[3]) < (5.0 if on_top else 12.0):
			continue
		var m: Vector2 = spot[0]
		var dir: Vector2 = spot[1]
		var o: Vector2 = spot[2]
		w = minf(w, float(spot[3]) * 0.85)
		var y0 := g + (DTC_BODY + 0.4 if on_top else DTC_BASE + DTC_FASCIA + 0.4)
		var y1 := g + (DTC_BODY + DTC_TOP - 0.3 if on_top else DTC_BODY - DTC_CORNICE - 0.4)
		if spec.has("y0"):
			y0 = g + float(spec["y0"])
		if spec.has("y1"):
			y1 = g + float(spec["y1"])
		var q0 := m - dir * w * 0.5 + o * 0.2
		var q1 := m + dir * w * 0.5 + o * 0.2
		var p0 := m - dir * w * 0.5
		var p1 := m + dir * w * 0.5
		var col := Color(str(spec.get("bg", "#c8322e")))
		_mode = M_STONE
		_quad(Vector3(q0.x, y0, q0.y), Vector3(q1.x, y0, q1.y), Vector3(q1.x, y1, q1.y), Vector3(q0.x, y1, q0.y), Vector3(o.x, 0, o.y), col)
		_quad(Vector3(q0.x, y1, q0.y), Vector3(q1.x, y1, q1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y), Vector3.UP, col.darkened(0.2))
		_dtc_words(spec.get("lines", []), m + o * 0.25, o, y0, y1, w, 2.4, Color(str(spec.get("ink", "#ffffff"))))


## The shop fronts on the recessed glazed floor (data/eastern_wall_shops.json `fronts`): the
## shop's glass tinted its own colour (lit from inside at night) and a lit fascia band over it with
## the name; a two-storey shop (FROGS XXL) also glows through the curtain wall's first floor.
func _dtc_fronts(outline: PackedVector2Array, shop: PackedVector2Array, g: float, list: Array) -> void:
	for spec: Dictionary in list:
		var w := float(spec.get("w", 8.0))
		var spot := _dtc_spot(outline, str(spec.get("face", "west")), float(spec.get("at", 0.5)), w)
		if spot.is_empty():
			continue
		var m: Vector2 = spot[0]
		w = minf(w, float(spot[3]) * 0.9)
		# The shop's glass: its wall straight in from the curtain wall (under the cantilever).
		var hit := _dtc_ray(shop, m + (spot[2] as Vector2) * 0.5, -(spot[2] as Vector2), 12.0)
		if hit.is_empty():
			continue
		var wall: Vector2 = hit[0]
		var o: Vector2 = hit[1]
		var dir := Vector2(o.y, -o.x)
		var p0 := wall - dir * w * 0.5 + o * 0.06
		var p1 := wall + dir * w * 0.5 + o * 0.06
		var n := Vector3(o.x, 0, o.y)
		if spec.has("glass"):
			_mode = M_PAVILION
			_quad(Vector3(p0.x, g + 0.25, p0.y), Vector3(p1.x, g + 0.25, p1.y), Vector3(p1.x, g + 3.7, p1.y), Vector3(p0.x, g + 3.7, p0.y), n, Color(str(spec["glass"])))
		# The name: a lit board hung from the cantilever's edge (the slab's fascia), where the
		# street and the game's high camera both see it; the shop's glass behind stays tinted.
		var band := Color(str(spec.get("band", "#2b2f36")))
		var co: Vector2 = spot[2]
		var cd: Vector2 = spot[1]
		var b0 := m - cd * w * 0.5 + co * 0.3
		var b1 := m + cd * w * 0.5 + co * 0.3
		var t0 := m - cd * w * 0.5
		var t1 := m + cd * w * 0.5
		var by0 := g + DTC_BASE - 1.4
		var by1 := g + DTC_BASE + DTC_FASCIA - 0.05
		_mode = M_LAMP
		_quad(Vector3(b0.x, by0, b0.y), Vector3(b1.x, by0, b1.y), Vector3(b1.x, by1, b1.y), Vector3(b0.x, by1, b0.y), Vector3(co.x, 0, co.y), band)
		_mode = M_STONE
		_quad(Vector3(b0.x, by1, b0.y), Vector3(b1.x, by1, b1.y), Vector3(t1.x, by1, t1.y), Vector3(t0.x, by1, t0.y), Vector3.UP, band.darkened(0.3))
		_quad(Vector3(b0.x, by0, b0.y), Vector3(b1.x, by0, b1.y), Vector3(t1.x, by0, t1.y), Vector3(t0.x, by0, t0.y), Vector3.DOWN, band.darkened(0.4))
		_dtc_words(spec.get("lines", []), m + co * 0.35, co, by0 + 0.05, by1 - 0.05, w, 1.6, Color(str(spec.get("ink", "#ffffff"))))
		if spec.has("portal"):
			# A coloured portal round the doors (the discount store's red frame): two posts at the
			# board's ends down to the pavement, at the cantilever's edge.
			var pc := Color(str(spec["portal"]))
			for e: Vector2 in [b0, b1]:
				var pp := e - co * 0.15
				_prism(PackedVector2Array([pp - cd * 0.25 - co * 0.15, pp + cd * 0.25 - co * 0.15, pp + cd * 0.25 + co * 0.15, pp - cd * 0.25 + co * 0.15]),
						g, by0, pc, pc, M_LAMP, M_STONE)
		if bool(spec.get("two_storey", false)) and spec.has("glass"):
			# The first floor behind the curtain wall: the shop's colour glowing through the glass.
			var c0 := m - cd * w * 0.5 + co * 0.08
			var c1 := m + cd * w * 0.5 + co * 0.08
			var y0 := g + DTC_BASE + DTC_FASCIA + 0.1
			_mode = M_PAVILION
			_quad(Vector3(c0.x, y0, c0.y), Vector3(c1.x, y0, c1.y), Vector3(c1.x, y0 + 4.0, c1.y), Vector3(c0.x, y0 + 4.0, c0.y), Vector3(co.x, 0, co.y), Color(str(spec["glass"])).darkened(0.15))
	_mode = M_STONE


## The green roof strips (`roof_green`, F's aerial photos): sedum along a long side of the main
## roof, between the cornice and the set-back top storey, kept off the ends.
func _dtc_green(outline: PackedVector2Array, g: float, list: Array) -> void:
	for spec: Dictionary in list:
		var want := _dtc_dir(str(spec.get("face", "west")))
		var right := Vector2(want.y, -want.x)
		var lo := INF
		var hi := -INF
		var top := -INF
		for q in outline:
			lo = minf(lo, q.dot(right))
			hi = maxf(hi, q.dot(right))
			top = maxf(top, q.dot(want))
		var w := float(spec.get("w", 2.0))
		var s0 := top - 0.9 - w
		var s1 := top - 0.9
		var r0 := lo + DTC_TOP_END * 0.5
		var r1 := hi - DTC_TOP_END * 0.5
		var band := PackedVector2Array([right * r0 + want * s0, right * r1 + want * s0, right * r1 + want * s1, right * r0 + want * s1])
		var inset := Geometry2D.offset_polygon(outline, -0.9, Geometry2D.JOIN_MITER)
		if inset.is_empty():
			continue
		var strip := _largest(Geometry2D.intersect_polygons(inset[0], band))
		if strip.size() >= 3:
			_prism(strip, g + DTC_BODY, g + DTC_BODY + 0.3, Color("#7d8a66"), Color(str(spec.get("colour", "#6f8f4a"))), M_STONE, M_STONE)


## The furniture outside a shop (`props`): FROGS XXL's cream parasols and green seats on the corner.
func _dtc_props(outline: PackedVector2Array, g: float, list: Array) -> void:
	_mode = M_STONE
	for spec: Dictionary in list:
		var spot := _dtc_spot(outline, str(spec.get("face", "west")), float(spec.get("at", 0.5)), 0.0)
		if spot.is_empty():
			continue
		var p: Vector2 = spot[0] + (spot[2] as Vector2) * float(spec.get("out", 2.0))
		var col := Color(str(spec.get("colour", "#3fae3b")))
		match str(spec.get("kind", "seat")):
			"parasol":
				_prism(_square(p, 0.05), g, g + 2.5, Color("#3a3d40"), Color("#3a3d40"), M_STONE, M_STONE)
				var h := 1.6
				var tip := Vector3(p.x, g + 3.0, p.y)
				var c := [p + Vector2(-h, -h), p + Vector2(h, -h), p + Vector2(h, h), p + Vector2(-h, h)]
				for i in 4:
					var u: Vector2 = c[i]
					var v: Vector2 = c[(i + 1) % 4]
					var mid := (u + v) * 0.5 - p
					var nn := Vector3(mid.x, h * 1.6, mid.y).normalized()
					_tri(Vector3(u.x, g + 2.4, u.y), Vector3(v.x, g + 2.4, v.y), tip, nn, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
					_tri(Vector3(u.x, g + 2.4, u.y), Vector3(v.x, g + 2.4, v.y), tip, Vector3.DOWN, col.darkened(0.25), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)
			_:
				var ring := PackedVector2Array()
				for i in 6:
					ring.append(p + Vector2(cos(TAU * i / 6.0), sin(TAU * i / 6.0)) * 0.7)
				_prism(ring, g, g + 0.45, col, col.lightened(0.1), M_STONE, M_STONE)


## The store's name on the roof over its south end (the face the game's camera sees from the
## street): a lit parody sign on a frame, the word over 75 % of the end (letters 3.2 m at most),
## standing on the cornice.
func _dtc_sign(outline: PackedVector2Array, word: String, y: float) -> void:
	var best := -1
	var best_score := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var score := _out(outline, a, b).dot(DTC_SOUTH) * minf(a.distance_to(b), 12.0)
		if score > best_score:
			best_score = score
			best = i
	if best < 0:
		return
	var a := outline[best]
	var b := outline[(best + 1) % outline.size()]
	var o := _out(outline, a, b)
	var mid := (a + b) * 0.5 - o * 1.0
	var k := minf(0.75 * a.distance_to(b) / Neon.length_of(word), 3.2 / (Neon.ROW_H * Neon.PIXEL))
	var tall := Neon.ROW_H * Neon.PIXEL * k
	# The frame: two posts and a rail behind the letters.
	var d := (b - a).normalized()
	var half := 0.5 * k * Neon.length_of(word) + 0.3
	for s: float in [-half, half]:
		var p := mid + d * s - o * 0.4
		_prism(_square(p, 0.15), y, y + tall + 0.6, DTC_ALU.darkened(0.3), DTC_ALU.darkened(0.3), M_STONE, M_STONE)
	var r0 := mid - d * half - o * 0.4
	var r1 := mid + d * half - o * 0.4
	_prism(PackedVector2Array([r0 - o * 0.1, r1 - o * 0.1, r1 + o * 0.1, r0 + o * 0.1]), y + 0.2, y + 0.5,
			DTC_ALU.darkened(0.3), DTC_ALU.darkened(0.3), M_STONE, M_STONE)
	signs.append([word, Vector3(mid.x, y + 0.5, mid.y), Vector3(o.x, 0.0, o.y), k, DTC_SIGN])


# --- Behind the Eastern Wall: the re-clad tower and the 1960s slabs ---------------------------

## The Mac photo check (2026-11-01, specs C and D: docs/landmarks/specs/tower75.md, slabs.md): the
## buildings the start's camera sees over the stores. C: the 75 m tower at (-819, 254), a 1970s
## point block re-clad in light horizontal metal with punched windows in bands, on a two-storey
## dark glass podium, a steel frame of big red parody letters on its roof and a small billboard
## at the roof's edge. D: the four 37 m slabs behind Junior, 1960s housing in light warm grey
## plaster, balcony bands on the long faces, plainer end walls, lift and stair houses on the
## flat roofs, and a big rooftop billboard on the slab behind Sawa. Both unnamed (no card).
const TOWER75_AT := Vector2(-819.0, 254.0)
const TOWER75_PODIUM := 7.0
const TOWER75_CLAD := Color("#d9dcdc")
const TOWER75_GLASS := Color("#3e4e5e")
## F's photos (2026-11-05): the appliance maker's red script on the tower's crown, beside the
## discount store's red box; ours a parody, PRALKA PLUS (KOKA-KOLKA moves to the Sezam corner, the
## Eastern Wall photo pass in BACKLOG).
const TOWER75_WORD := "PRALKA PLUS"
const SLAB_AT := [Vector2(-862.0, 86.0), Vector2(-853.0, 190.0), Vector2(-813.0, 207.0), Vector2(-778.0, 308.0)]
const SLAB_BILLBOARD := 1     # the slab behind Sawa (index in SLAB_AT)
## F's look check (2026-11-03): light warm grey (provisional), with clear horizontal balcony
## bands (SLAB_BAND ledges, one a storey on the long faces); the ends the same grey a shade down.
const SLAB_PLASTER := Color("#d3cfc6")
const SLAB_END := Color("#c4bfb5")
const SLAB_BAND := Color("#aaa499")
const SLAB_STOREY := 2.8
const SLAB_WORD := "ORANŻADA"


func _find_behind() -> void:
	# Zones grown 3 m: the LoD2 model of each stands a little off its OpenStreetMap outline.
	var tower := _outline_at(TOWER75_AT)
	if tower.size() >= 3:
		_add_site("tower75", [_largest(Geometry2D.offset_polygon(tower, 3.0, Geometry2D.JOIN_MITER))])
		sites[-1]["outline"] = tower
	var slabs: Array[PackedVector2Array] = []
	var outlines: Array[PackedVector2Array] = []
	for at: Vector2 in SLAB_AT:
		var q := _outline_at(at)
		if q.size() >= 3:
			slabs.append(_largest(Geometry2D.offset_polygon(q, 3.0, Geometry2D.JOIN_MITER)))
			outlines.append(q)
	_add_site("slabs", slabs)
	if not sites.is_empty() and sites[-1]["key"] == "slabs":
		sites[-1]["outlines"] = outlines


## A steel frame on a roof along edge a→b (drawn in `inset` m): two or more posts and two rails,
## the word on it facing out, lit by day and night.
func _roof_frame(poly: PackedVector2Array, i: int, y: float, inset: float, tall: float, word: String, colour: Color,
		share: float, panel := Color(0, 0, 0, 0)) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	var o := _out(poly, a, b)
	var d := (b - a).normalized()
	var mid := (a + b) * 0.5 - o * inset
	var wide := a.distance_to(b) * share
	var k := minf(0.85 * wide / Neon.length_of(word), (tall - 0.6) / (Neon.ROW_H * Neon.PIXEL))
	var steel := Color("#5b6166")
	var posts := maxi(2, ceili(wide / 8.0) + 1)
	for n in posts:
		var p := mid + d * (-0.5 * wide + wide * n / (posts - 1)) - o * 0.3
		_prism(_square(p, 0.15), y, y + tall, steel, steel, M_STONE, M_STONE)
	for ry: float in [0.4, tall - 0.3]:
		var r0 := mid - d * wide * 0.5 - o * 0.3
		var r1 := mid + d * wide * 0.5 - o * 0.3
		_prism(PackedVector2Array([r0 - o * 0.08, r1 - o * 0.08, r1 + o * 0.08, r0 + o * 0.08]), y + ry - 0.15, y + ry + 0.15,
				steel, steel, M_STONE, M_STONE)
	if panel.a > 0.0:
		var p0 := mid - d * wide * 0.5 - o * 0.12
		var p1 := mid + d * wide * 0.5 - o * 0.12
		_mode = M_STONE
		_quad(Vector3(p0.x, y + 0.6, p0.y), Vector3(p1.x, y + 0.6, p1.y), Vector3(p1.x, y + tall - 0.1, p1.y),
				Vector3(p0.x, y + tall - 0.1, p0.y), Vector3(o.x, 0, o.y), panel)
	var h := Neon.ROW_H * Neon.PIXEL * k
	signs.append([word, Vector3(mid.x, y + 0.5 * tall - 0.5 * h, mid.y), Vector3(o.x, 0.0, o.y), k, colour])


func _build_tower75(site: Dictionary) -> void:
	var outline: PackedVector2Array = _simplify(site["outline"], 0.6)
	_g = _ground_under(outline)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The podium: two storeys of dark grey-blue glass in a square grid.
	_prism(outline, g - 0.4, g + TOWER75_PODIUM, TOWER75_GLASS, Color("#6e767b"), M_SKIN + float(S_DARK) / 16.0, M_STONE)
	# The shaft, a step in from the podium, in its cladding with punched windows.
	var shaft := _largest(Geometry2D.offset_polygon(outline, -1.2, Geometry2D.JOIN_MITER))
	if shaft.size() < 3:
		shaft = outline
	var top := g + 75.0
	_prism(shaft, g + TOWER75_PODIUM, top - 0.9, TOWER75_CLAD, none, M_SKIN + float(S_PUNCHED) / 16.0)
	_prism(shaft, top - 0.9, top, TOWER75_CLAD.lightened(0.08), Color("#8b9296"), M_STONE, M_STONE)
	# The roof: a plant room, the big letters' frame facing down the street, a small billboard on
	# the edge beside it.
	var c := _centre(shaft)
	_prism(_square(c, 3.2), top, top + 3.0, Color("#b9bdbe"), Color("#8b9296"), M_STONE, M_STONE)
	var face := _edge_facing(shaft, BEHIND_FACE, 10.0)
	if face >= 0:
		_roof_frame(shaft, face, top, 1.2, 6.0, TOWER75_WORD, Color(1.0, 0.16, 0.12), 0.9)
		var side := _edge_facing(shaft, Vector2(BEHIND_FACE.y, -BEHIND_FACE.x), 8.0)
		if side >= 0 and side != face:
			# The four-floor discount store below (opened Sep 2026) put its red box up here
			# (F's photos, 2026-11-05).
			_roof_frame(shaft, side, top, 0.8, 3.2, "TAK MAKS", Color(1, 1, 1), 0.6, Color("#d0161e"))
	_collide(outline)


func _build_slabs(site: Dictionary) -> void:
	var k := 0
	for z: PackedVector2Array in site["outlines"]:
		var poly := _simplify(z, 0.6)
		if poly.size() < 3:
			k += 1
			continue
		_g = _ground_under(poly)
		var g := _g
		var top := g + 37.3
		# Walls: the long faces in plaster with their balcony bands, the ends plain.
		var longest := 0.0
		for i in poly.size():
			longest = maxf(longest, poly[i].distance_to(poly[(i + 1) % poly.size()]))
		var run := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var long_face := a.distance_to(b) > longest * 0.5
			_mode = M_SKIN + float(S_SLAB) / 16.0 if long_face else M_STONE
			var o := _out(poly, a, b)
			_wall(a, b, g - 0.4, top, o, SLAB_PLASTER if long_face else SLAB_END, run)
			run += a.distance_to(b)
			if long_face:
				var d := (b - a).normalized()
				var y := g + 4.2
				while y < top - 1.5:
					var a1 := a + d * 0.3
					var b1 := b - d * 0.3
					_prism(PackedVector2Array([a1, b1, b1 + o * 0.45, a1 + o * 0.45]), y, y + 0.25, SLAB_BAND, SLAB_BAND.lightened(0.1),
							M_STONE, M_STONE)
					y += SLAB_STOREY
		_mode = M_STONE
		_cap(poly, top, Color("#8c8a84"))
		# The roof: lift and stair houses along the slab's long axis.
		var axis := Vector2.ZERO
		for i in poly.size():
			var e := poly[(i + 1) % poly.size()] - poly[i]
			if e.length() > axis.length():
				axis = e
		axis = axis.normalized()
		var c := _centre(poly)
		var span := 0.0
		for q in poly:
			span = maxf(span, absf((q - c).dot(axis)))
		for f: float in [-0.45, 0.45]:
			var p := c + axis * span * f
			var across := Vector2(-axis.y, axis.x)
			_prism(PackedVector2Array([p - axis * 3.0 - across * 2.2, p + axis * 3.0 - across * 2.2, p + axis * 3.0 + across * 2.2,
					p - axis * 3.0 + across * 2.2]), top, top + 3.2, SLAB_PLASTER.darkened(0.06), Color("#7d7b75"), M_STONE, M_STONE)
		if k == SLAB_BILLBOARD:
			var face := _edge_facing(poly, BEHIND_FACE, 15.0)
			if face >= 0:
				_roof_frame(poly, face, top, 4.5, 5.5, SLAB_WORD, Color(1.0, 0.62, 0.15), minf(0.9, 25.0 / poly[face].distance_to(poly[(face + 1) % poly.size()])), Color("#1d3d6b"))
		_collide(poly)
		k += 1
	_mode = M_STONE


# --- I Oddział PKO: the first branch on Marszałkowska at Sienkiewicza --------------------------

## F's photo and the Google aerial (2026-11-09, thread "Rebuild the first PKO branch building";
## spec docs/landmarks/specs/pko_branch.md). OpenStreetMap maps it as ~26 overlapping building parts
## (a 38 m ring, a 34 m glass tower part, 24 m wings), LoD2 drew the courtyard as hollow walls with
## no roof, and the street-block and photo-front passes had both guessed a brick "Rotunda block"
## front over it. The model replaces all of them (their two entries are gone from
## data/street_blocks/index.json and data/photo_fronts.json): the dark red-brown granite slab on
## Marszałkowska (a two-storey base, tall glass bays between granite piers, a glass top floor), the
## plain side wings round a paved courtyard, the east wing a storey higher. The bank's name is a parody.
## Frame: u along Marszałkowska towards Sienkiewicza (south), v east, away from the street.
const PKO_O := Vector2(-984.0, -30.0)
const PKO_U := Vector2(0.337, 0.941)
const PKO_V := Vector2(0.941, -0.337)
const PKO_LEN := 56.0                   # the slab's length along the street
const PKO_SLAB := 14.0                  # the slab's depth
const PKO_DEEP := 64.0                  # the wings' reach east
const PKO_COURT := Rect2(14.0, 14.0, 26.0, 38.0)   # (u0, v0, du, dv): the courtyard
const PKO_BASE := 8.0                   # two storeys of granite and glass
const PKO_GLASS_TOP := 31.0             # the piers end under the glass top floor
const PKO_TOP := 34.5
const PKO_WING := 25.0
const PKO_EAST := 28.5
const PKO_GRANITE := Color("#64362e")   # polished dark red-brown granite (the photo)
const PKO_PIER := Color("#7a4a3d")
const PKO_WING_WALL := Color("#a07f6e") # the wings' paler pinkish-brown stone
const PKO_GLASS := Color("#5f87a3")
const PKO_ROOF := Color("#77736d")
const PKO_BLUE := Color("#1f4f8f")      # the bank's fascia
const PKO_PAVING := Color("#6f6a64")


func _pko_p(u: float, v: float) -> Vector2:
	return PKO_O + PKO_U * u + PKO_V * v


func _pko_rect(u0: float, v0: float, u1: float, v1: float) -> PackedVector2Array:
	var q := PackedVector2Array([_pko_p(u0, v0), _pko_p(u1, v0), _pko_p(u1, v1), _pko_p(u0, v1)])
	if Geometry2D.is_polygon_clockwise(q):
		q.reverse()
	return q


func _find_pko_branch() -> void:
	_add_site("pko_branch", [_pko_rect(-4.0, -3.0, PKO_LEN + 4.0, PKO_DEEP + 3.0)])


## A wall between two (u, v) points in the frame, facing `out` (plan vector).
func _pko_wall(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, col: Color, run := 0.0) -> void:
	_wall(_pko_p(a.x, a.y), _pko_p(b.x, b.y), y0, y1, out, col, run)


func _build_pko_branch(site: Dictionary) -> void:
	var g := _ground_under(site["zone"][0])
	_g = g
	var west := -PKO_V
	var east := PKO_V
	var north := -PKO_U
	var south := PKO_U
	# --- the slab on Marszałkowska: granite ends and back, then the front in bays
	_mode = M_STONE
	_pko_wall(Vector2(0, 0), Vector2(0, PKO_SLAB), g - 0.3, g + PKO_TOP, north, PKO_GRANITE)
	_pko_wall(Vector2(PKO_LEN, PKO_SLAB), Vector2(PKO_LEN, 0), g - 0.3, g + PKO_TOP, south, PKO_GRANITE)
	_pko_wall(Vector2(0, 0), Vector2(PKO_LEN, 0), g - 0.3, g + PKO_BASE, west, PKO_GRANITE)
	# the front's spandrel and the tall piers, then the glass inset between them
	_pko_wall(Vector2(0, 0), Vector2(PKO_LEN, 0), g + PKO_BASE, g + PKO_GLASS_TOP, west, PKO_PIER)
	var bays := int(PKO_LEN / 2.4)
	var bw := PKO_LEN / float(bays)
	_mode = M_GLASS
	for k in bays:
		var u0 := k * bw + 0.45
		var u1 := (k + 1) * bw - 0.45
		_pko_wall(Vector2(u0, -0.12), Vector2(u1, -0.12), g + PKO_BASE + 1.4, g + PKO_GLASS_TOP - 0.5, west, PKO_GLASS)
	# the ground floor: glass between granite piers in two bands
	var gb := int(PKO_LEN / 3.6)
	var gw := PKO_LEN / float(gb)
	for k in gb:
		var u0 := k * gw + 0.5
		var u1 := (k + 1) * gw - 0.5
		_pko_wall(Vector2(u0, -0.1), Vector2(u1, -0.1), g + 0.9, g + 4.1, west, PKO_GLASS.darkened(0.15))
		_pko_wall(Vector2(u0, -0.1), Vector2(u1, -0.1), g + 4.9, g + 7.2, west, PKO_GLASS)
	# the blue fascia over the doors and its parody name
	_mode = M_STONE
	_pko_wall(Vector2(6.0, -0.2), Vector2(24.0, -0.2), g + 4.15, g + 4.85, west, PKO_BLUE)
	_pko_wall(Vector2(34.0, -0.2), Vector2(50.0, -0.2), g + 4.15, g + 4.85, west, PKO_BLUE)
	for u: float in [15.0, 42.0]:
		var at := _pko_p(u, -0.3)
		signs.append(["BANK POLSKA", Vector3(at.x, g + 4.5, at.y), Vector3(west.x, 0.0, west.y), 0.4, Color(0.95, 0.97, 1.0)])
	# the top floor: a ledge, then raked glass leaning back from the piers' tops
	_cap(_pko_rect(0.0, -0.3, PKO_LEN, 0.5), g + PKO_GLASS_TOP, PKO_GRANITE)
	_pko_wall(Vector2(0, -0.3), Vector2(PKO_LEN, -0.3), g + PKO_GLASS_TOP - 0.6, g + PKO_GLASS_TOP, west, PKO_GRANITE)
	_mode = M_GLASS
	var a0 := _pko_p(0.0, 0.5)
	var a1 := _pko_p(PKO_LEN, 0.5)
	var b0 := _pko_p(0.0, 2.8)
	var b1 := _pko_p(PKO_LEN, 2.8)
	var n_rake := (Vector3(west.x, 0.0, west.y) * 0.8 + Vector3.UP * 0.6).normalized()
	_quad(Vector3(a0.x, g + PKO_GLASS_TOP, a0.y), Vector3(a1.x, g + PKO_GLASS_TOP, a1.y),
			Vector3(b1.x, g + PKO_TOP, b1.y), Vector3(b0.x, g + PKO_TOP, b0.y), n_rake, PKO_GLASS.lightened(0.1))
	_mode = M_STONE
	# the slab's roof and its back (the courtyard and wing sides)
	_cap(_pko_rect(0.0, 2.8, PKO_LEN, PKO_SLAB), g + PKO_TOP, PKO_ROOF)
	var cu0 := PKO_COURT.position.x
	var cu1 := PKO_COURT.end.x
	var cv0 := PKO_COURT.position.y
	var cv1 := PKO_COURT.end.y
	_mode = M_SKIN + float(S_PUNCHED) / 16.0
	_pko_wall(Vector2(0, PKO_SLAB), Vector2(cu0, PKO_SLAB), g + PKO_WING, g + PKO_TOP, east, PKO_WING_WALL)
	_pko_wall(Vector2(cu0, PKO_SLAB), Vector2(cu1, PKO_SLAB), g, g + PKO_TOP, east, PKO_WING_WALL)
	_pko_wall(Vector2(cu1, PKO_SLAB), Vector2(PKO_LEN, PKO_SLAB), g + PKO_WING, g + PKO_TOP, east, PKO_WING_WALL)
	# --- the wings: a ring round the courtyard, plain punched stone
	var outer := _pko_rect(0.0, PKO_SLAB, PKO_LEN, PKO_DEEP)
	_pko_wall(Vector2(0, PKO_SLAB), Vector2(0, PKO_DEEP), g - 0.3, g + PKO_WING, north, PKO_WING_WALL)
	_pko_wall(Vector2(PKO_LEN, PKO_DEEP), Vector2(PKO_LEN, PKO_SLAB), g - 0.3, g + PKO_WING, south, PKO_WING_WALL)
	_pko_wall(Vector2(0, PKO_DEEP), Vector2(PKO_LEN, PKO_DEEP), g - 0.3, g + PKO_EAST, east, PKO_WING_WALL)
	# the courtyard's three other faces look inwards
	_pko_wall(Vector2(cu0, cv0), Vector2(cu0, cv1), g, g + PKO_WING, south, PKO_WING_WALL)
	_pko_wall(Vector2(cu1, cv1), Vector2(cu1, cv0), g, g + PKO_WING, north, PKO_WING_WALL)
	_pko_wall(Vector2(cu1, cv1), Vector2(cu0, cv1), g, g + PKO_EAST, west, PKO_WING_WALL)
	_mode = M_STONE
	_cap_holes(outer, [_pko_rect(cu0, cv0, cu1, cv1)], g + PKO_WING, PKO_ROOF)
	# the east wing a storey higher: its roof, and the steps where it rises over the others
	var east_wing := _pko_rect(cu0, cv1, cu1, PKO_DEEP)
	_cap(east_wing, g + PKO_EAST, PKO_ROOF)
	_mode = M_SKIN + float(S_PUNCHED) / 16.0
	_pko_wall(Vector2(cu0, cv1), Vector2(cu0, PKO_DEEP), g + PKO_WING, g + PKO_EAST, north, PKO_WING_WALL)
	_pko_wall(Vector2(cu1, PKO_DEEP), Vector2(cu1, cv1), g + PKO_WING, g + PKO_EAST, south, PKO_WING_WALL)
	# the courtyard floor, paved dark
	_mode = M_STONE
	_cap(_pko_rect(cu0, cv0, cu1, cv1), g + 0.05, PKO_PAVING)
	# a blue fascia on the south wing's ground floor, the second branch door (the photo)
	_pko_wall(Vector2(PKO_LEN, 22.0), Vector2(PKO_LEN, 44.0), g + 3.6, g + 4.3, south, PKO_BLUE)
	_collide(_pko_rect(0.0, 0.0, PKO_LEN, PKO_DEEP))
	_mode = M_STONE


# --- TR Warszawa's building site, the gold scissors and the Christmas market -----------------

## F's photos of 2026-11-15 (13, Plac Defilad and Marszałkowska's side, from the pavement): the
## plot west of the museum as it stands now, not as an empty pit: a black hoarding all round with a
## navy gate and the green site board, a concrete shell (a ground floor of wall panels over scaffold
## openings, an upper block, a stair core in red climbing formwork with its working platform and
## rebar sprouting from every top edge, a scaffold cage round a rebar bundle), two red tower cranes
## numbered 1 and 2, four flagpoles with the contractors' banners (parodies), blue skips, timber
## stacks, red bins, a blue portable toilet, a yellow container, a navy concrete hopper. The same
## day, in front of the museum, the giant gold scissors on their granite plinth, and on the square
## west of the plot the Christmas market going up. All in the museum's frame (MSN, MSN_AXIS): u along
## its long side (towards the south-south-east), v out of the Plac Defilad face (towards the Palace).
const TR_U := Vector2(-62.0, 16.0)   # the plot along u
const TR_V := Vector2(46.0, 117.0)   # and across, almost to the Palace's wing (F's aerial, 2026-11-15)
const TR_BLACK := Color("#1d1e20")   # the hoarding's black boards
const TR_GATE := Color("#263a73")    # the gate's navy leaves
const TR_GREEN := Color("#1f7a52")   # the site board
const TR_YARD := Color("#74716b")    # the yard's wet grey concrete
const TR_CONCRETE := Color("#9a9c9a")
const TR_CONCRETE_L := Color("#a8a9a5")
const TR_FORM := Color("#c2302b")    # the climbing formwork
const TR_STEEL := Color("#3b3f44")   # scaffold, rails, openings
const TR_REBAR := Color("#2d2c2c")
const TR_CRANE := Color("#c8402f")   # the cranes' red lattice
const TR_SKIP := Color("#2d4f94")    # the blue skips and the toilet
const TR_TIMBER := Color("#c49a62")
const TR_YELLOW := Color("#e0b92a")
## The cranes: [u, v, mast height, jib angle (deg, from +u), jib length, counter-jib length, number].
const TR_CRANES := [[-50.0, 90.0, 36.0, 15.0, 40.0, 11.0, 1], [10.0, 74.0, 44.0, 205.0, 46.0, 12.0, 2]]


func _tr_frame() -> void:
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)


func _find_tr() -> void:
	_tr_frame()
	_add_site("tr", [_tr_rect(0.5)])


## The plot's rectangle in the museum's frame, grown by `grow` metres.
func _tr_rect(grow: float) -> PackedVector2Array:
	return _rect((TR_U.x + TR_U.y) * 0.5, (TR_V.x + TR_V.y) * 0.5,
			(TR_U.y - TR_U.x) * 0.5 + grow, (TR_V.y - TR_V.x) * 0.5 + grow)


## A world point from the current local frame.
func _tr_p(u: float, v: float, y: float) -> Vector3:
	var p := _w(u, v)
	return Vector3(p.x, y, p.y)


## A bar between two local points (a rail, a lattice member, a post).
func _tr_bar(u0: float, v0: float, y0: float, u1: float, v1: float, y1: float, w: float, col: Color) -> void:
	_beam(_tr_p(u0, v0, y0), _tr_p(u1, v1, y1), w, col)


func _build_tr(_site: Dictionary) -> void:
	_tr_frame()
	var plot := _tr_rect(0.0)
	_g = _ground_under(plot)
	var g := _g
	var cu := (TR_U.x + TR_U.y) * 0.5
	var cv := (TR_V.x + TR_V.y) * 0.5
	_mode = M_STONE
	# The yard: wet grey concrete inside the hoarding.
	_lbox(cu, cv, (TR_U.y - TR_U.x) * 0.5 - 0.3, (TR_V.y - TR_V.x) * 0.5 - 0.3, g - 0.3, g + 0.12, TR_YARD, M_STONE, TR_YARD)
	_tr_hoarding(g)
	_tr_shell(g)
	_tr_yard(g)
	_tr_far(g)
	_tr_flags(g)
	for c: Array in TR_CRANES:
		_tr_crane(c)
	_tr_frame()
	_collide(plot)


## The hoarding: black boards on all four runs, the navy gate in the museum-side run, the green
## site board beside it with the navy and yellow panels, a red-white barrier outside.
func _tr_hoarding(g: float) -> void:
	var u0 := TR_U.x
	var u1 := TR_U.y
	var v0 := TR_V.x
	var v1 := TR_V.y
	var t := 0.1
	var gate := Vector2(-8.0, 2.0)
	var top := g + 2.4
	_lbox((u0 + gate.x) * 0.5, v0 + t, (gate.x - u0) * 0.5, t, g - 0.3, top, TR_BLACK, M_STONE)
	_lbox((gate.y + u1) * 0.5, v0 + t, (u1 - gate.y) * 0.5, t, g - 0.3, top, TR_BLACK, M_STONE)
	_lbox((gate.x + gate.y) * 0.5, v0 + t, (gate.y - gate.x) * 0.5, t, g - 0.3, g + 2.6, TR_GATE, M_STONE)
	for pu: float in [gate.x, gate.y]:
		_lbox(pu, v0 + t, 0.18, 0.18, g - 0.3, g + 3.0, TR_STEEL, M_STONE)
	_lbox((u0 + u1) * 0.5, v1 - t, (u1 - u0) * 0.5, t, g - 0.3, top, TR_BLACK, M_STONE)
	_lbox(u0 + t, (v0 + v1) * 0.5, t, (v1 - v0) * 0.5 - 2.0 * t, g - 0.3, top, TR_BLACK, M_STONE)
	_lbox(u1 - t, (v0 + v1) * 0.5, t, (v1 - v0) * 0.5 - 2.0 * t, g - 0.3, top, TR_BLACK, M_STONE)
	# The site board on the museum-side run: green with its white words, the navy and yellow panels
	# beside it (the photo's corner on the pavement).
	_ubox(-36.0, -24.0, v0 - 0.08, v0 + 0.02, g + 0.3, g + 2.3, TR_GREEN, M_STONE, TR_GREEN)
	_ubox(-24.0, -17.0, v0 - 0.08, v0 + 0.02, g + 0.3, g + 2.3, Color("#27408a"), M_STONE)
	_ubox(-20.6, -19.0, v0 - 0.1, v0 - 0.08, g + 0.9, g + 1.7, TR_YELLOW, M_STONE)
	_usign("TEATR TR", -30.0, v0 - 0.1, g + 1.2, -_b, 7.0, 0.7, Color(0.95, 0.98, 0.95))
	_usign("BUDOWA", -30.0, v0 - 0.1, g + 0.5, -_b, 4.0, 0.5, Color(0.95, 0.98, 0.95))
	# The red-white barrier plank on its feet, with the pedestrian sign's post.
	_ubox(-52.0, -48.0, v0 - 0.7, v0 - 0.62, g + 0.5, g + 1.0, Color("#d4382f"), M_STONE)
	_ubox(-52.0, -48.0, v0 - 0.7, v0 - 0.62, g + 1.0, g + 1.4, Color("#ecebe6"), M_STONE)
	for fu: float in [-51.8, -48.2]:
		_ubox(fu - 0.1, fu + 0.1, v0 - 0.9, v0 - 0.4, g, g + 0.2, TR_CONCRETE, M_STONE)


## A working platform along a face: a steel deck at y with a mesh rail round three sides (posts
## every 2.4 m, the top rail), `out` the side the deck sticks out to (-1 towards -v, +1 towards +v).
func _tr_deck(u0: float, u1: float, vf: float, depth: float, out: float, y: float) -> void:
	var v_out := vf + out * depth
	_ubox(u0, u1, minf(vf, v_out), maxf(vf, v_out), y, y + 0.22, TR_STEEL, M_STONE, TR_STEEL)
	var n := maxi(int((u1 - u0) / 2.4), 1)
	for i in n + 1:
		var pu := lerpf(u0, u1, float(i) / n)
		_tr_bar(pu, v_out, y + 0.22, pu, v_out, y + 1.25, 0.08, TR_STEEL)
	_tr_bar(u0, v_out, y + 1.25, u1, v_out, y + 1.25, 0.07, TR_STEEL)
	_tr_bar(u0, v_out, y + 0.7, u1, v_out, y + 0.7, 0.05, TR_STEEL)
	for eu: float in [u0, u1]:
		_tr_bar(eu, vf, y + 1.25, eu, v_out, y + 1.25, 0.07, TR_STEEL)


## Rebar sprouting from a top edge: n thin dark sticks over the rectangle, h tall.
func _tr_rebar(u0: float, u1: float, v0: float, v1: float, y: float, h: float, n: int) -> void:
	for i in n:
		var k := float(i) / maxi(n - 1, 1)
		var pu := lerpf(u0, u1, k)
		var pv := v0 if i % 2 == 0 else v1
		_tr_bar(pu, pv, y, pu, pv, y + h * (0.75 + 0.25 * float((i * 7) % 5) / 4.0), 0.05, TR_REBAR)


## The concrete shell: the ground-floor wall with its scaffold openings, the upper block and the tall
## left block, the red stair core on climbing formwork, the platforms, the scaffold cage and the
## low east wing.
func _tr_shell(g: float) -> void:
	var v_s := 60.0   # the shell's face towards the museum
	_ubox(-54.0, -6.0, v_s, 82.0, g, g + 5.6, TR_CONCRETE, M_STONE, TR_CONCRETE_L)
	# The openings under the first slab: scaffold behind a yellow net band.
	for i in 6:
		var ou := -52.0 + i * 7.6
		_ubox(ou, ou + 5.2, v_s - 0.18, v_s, g + 0.3, g + 2.9, TR_STEEL, M_STONE)
		_ubox(ou, ou + 5.2, v_s - 0.2, v_s - 0.17, g + 0.3, g + 0.8, TR_YELLOW, M_STONE)
	# The upper block and the taller block on the west end (bigger panels, form-tie holes).
	_ubox(-54.0, -24.0, v_s, 82.0, g + 5.6, g + 13.4, TR_CONCRETE_L, M_STONE, TR_CONCRETE)
	_ubox(-54.0, -44.0, v_s, 82.0, g + 13.4, g + 17.2, TR_CONCRETE_L, M_STONE, TR_CONCRETE)
	_ubox(-33.0, -24.0, v_s + 3.0, 82.0, g + 13.4, g + 15.8, TR_CONCRETE_L, M_STONE, TR_CONCRETE)
	for pu: float in [-44.0, -34.0, -24.0]:
		_ubox(pu - 0.08, pu + 0.08, v_s - 0.06, v_s, g + 5.6, g + 13.4, TR_CONCRETE.darkened(0.15), M_STONE)
	# The stair core in red climbing formwork, with its own top platform and the ladder.
	_ubox(-42.0, -36.5, v_s - 1.1, v_s, g + 7.0, g + 19.4, TR_FORM, M_STONE, TR_FORM)
	_ubox(-42.0, -36.5, v_s - 0.9, v_s - 0.8, g + 7.0, g + 19.4, TR_FORM.darkened(0.25), M_STONE)
	_tr_deck(-43.0, -35.5, v_s - 1.1, 1.0, -1.0, g + 19.4)
	_tr_bar(-39.0, v_s - 1.15, g + 7.0, -39.0, v_s - 1.15, g + 19.4, 0.1, TR_STEEL)
	# The working platform round the first upper floor, on brackets, with a mesh rail.
	_tr_deck(-55.5, -22.0, v_s, 2.2, -1.0, g + 13.0)
	for bu in 6:
		var bx := -53.0 + bu * 5.8
		_tr_bar(bx, v_s - 2.0, g + 13.0, bx, v_s, g + 11.2, 0.09, TR_STEEL)
	# Rebar sprouting from the tops.
	_tr_rebar(-54.0, -44.0, v_s + 0.4, 81.6, g + 17.2, 1.8, 22)
	_tr_rebar(-33.0, -24.0, v_s + 3.4, 81.6, g + 15.8, 1.6, 14)
	_tr_rebar(-54.0, -45.0, v_s + 0.4, 81.6, g + 5.6, 0.0, 0)
	# Scaffold cage round a rebar bundle on the first slab: four posts, three decks, the bundle.
	var cu := -19.5
	var cv := 70.0
	for sx: float in [-1.5, 1.5]:
		for sz: float in [-1.5, 1.5]:
			_tr_bar(cu + sx, cv + sz, g + 5.6, cu + sx, cv + sz, g + 16.0, 0.12, TR_STEEL)
	for k in 3:
		var dy := g + 8.2 + k * 2.6
		_ubox(cu - 1.6, cu + 1.6, cv - 1.6, cv + 1.6, dy, dy + 0.12, Color("#8a6f46"), M_STONE)
		_tr_bar(cu - 1.5, cv - 1.5, dy + 1.0, cu + 1.5, cv - 1.5, dy + 1.0, 0.05, TR_STEEL)
		_tr_bar(cu - 1.5, cv - 1.5, dy + 1.0, cu - 1.5, cv + 1.5, dy + 1.0, 0.05, TR_STEEL)
	_ubox(cu - 0.4, cu + 0.4, cv - 0.4, cv + 0.4, g + 5.6, g + 19.0, TR_REBAR, M_STONE)
	# The low east wing: a wall to 7 m with its own platform and a red form box at its end.
	_ubox(-6.0, 6.0, v_s, 80.0, g, g + 7.0, TR_CONCRETE, M_STONE, TR_CONCRETE_L)
	for i in 3:
		var ou := -4.8 + i * 3.8
		_ubox(ou, ou + 3.0, v_s - 0.18, v_s, g + 0.3, g + 2.9, TR_STEEL, M_STONE)
	_tr_deck(-6.5, 6.5, v_s, 1.8, -1.0, g + 6.8)
	_ubox(1.0, 4.5, v_s - 0.5, v_s, g + 7.0, g + 10.5, TR_FORM, M_STONE, TR_FORM)
	_tr_rebar(-6.0, 6.0, v_s + 0.4, 79.6, g + 7.0, 1.4, 12)


## The yard along the museum-side run: timber, skips, bins, the toilet, the container, rebar,
## blue insulation pallets, the hopper and a few white big bags.
func _tr_yard(g: float) -> void:
	var y0 := g + 0.12
	# Timber stacks (long, strapped).
	_ubox(-34.0, -24.0, 49.6, 53.0, y0, y0 + 1.5, TR_TIMBER, M_STONE, TR_TIMBER.darkened(0.12))
	_ubox(-22.0, -12.0, 49.6, 52.6, y0, y0 + 1.35, TR_TIMBER.lightened(0.05), M_STONE, TR_TIMBER.darkened(0.1))
	_ubox(-58.0, -50.0, 63.0, 65.6, y0, y0 + 1.2, TR_TIMBER, M_STONE, TR_TIMBER.darkened(0.12))
	# Blue skips with rubble in them (the third filled with earth).
	for k in 3:
		var su: float = [-46.0, -39.5, 3.5][k]
		_ubox(su - 2.8, su + 2.8, 50.4, 52.6, y0, y0 + 1.6, TR_SKIP, M_STONE, TR_SKIP.darkened(0.45))
		var fill := Color("#7a6a55") if k == 2 else Color("#a9a49a")
		_ubox(su - 2.4, su + 2.4, 50.8, 52.2, y0 + 1.2, y0 + 1.95 + 0.2 * k, fill, M_STONE, fill.lightened(0.08))
	# The portable toilet and the red bins.
	_ubox(-35.4, -34.2, 54.4, 55.6, y0, y0 + 2.3, Color("#3a63b3"), M_STONE, Color("#e8eaec"))
	for k in 3:
		_ubox(-56.8 + k * 1.1, -55.9 + k * 1.1, 52.0, 52.9, y0, y0 + 1.1, Color("#b8211f"), M_STONE, Color("#3d3d3f"))
	# The yellow container in the corner.
	_ubox(9.0, 15.0, 48.6, 51.2, y0, y0 + 2.6, TR_YELLOW, M_STONE, TR_YELLOW.darkened(0.15))
	# Rebar bundles on the ground and the blue insulation pallets.
	_ubox(-31.0, -13.0, 55.0, 56.6, y0, y0 + 0.45, TR_REBAR, M_STONE)
	_ubox(-30.0, -17.0, 56.8, 57.9, y0, y0 + 0.3, Color("#3a3d41"), M_STONE)
	for k in 5:
		_ubox(-44.0 + (k % 3) * 1.9, -42.4 + (k % 3) * 1.9, 54.0 + (k / 3) * 1.8, 55.4 + (k / 3) * 1.8, y0, y0 + 1.2,
				Color("#58a4dc"), M_STONE, Color("#7bbbe8"))
	# The navy concrete hopper on four legs by the west end.
	for hx: float in [-1.2, 1.2]:
		for hz: float in [-1.2, 1.2]:
			_tr_bar(-58.5 + hx, 69.0 + hz, y0, -58.5 + hx, 69.0 + hz, y0 + 3.0, 0.14, TR_GATE)
	_ubox(-60.0, -57.0, 67.5, 70.5, y0 + 3.0, y0 + 6.2, TR_GATE, M_STONE, TR_STEEL)
	_ubox(-59.4, -57.6, 68.1, 69.9, y0 + 6.2, y0 + 7.4, TR_STEEL, M_STONE)
	# A few big bags and pallets.
	for p: Array in [[-26.0, 59.0], [-9.0, 55.0], [6.5, 55.5], [-2.0, 94.0], [-30.0, 90.0]]:
		_ubox(p[0] - 0.55, p[0] + 0.55, p[1] - 0.55, p[1] + 0.55, y0, y0 + 1.1, Color("#dcd9d2"), M_STONE, Color("#cfcbc2"))
	_ubox(-12.0, -10.8, 58.4, 59.6, y0, y0 + 0.14, Color("#8a6f46"), M_STONE)


## The plot's far end towards the Palace (F's aerial, 2026-11-15: the site runs almost to the
## Palace's wing): the foundation slab with its rebar mats, the dug earth beyond it, the site
## offices (two storeys of containers with an outside stair), a yellow excavator, pallets.
func _tr_far(g: float) -> void:
	var y0 := g + 0.12
	# The next slab: a low concrete raft with rebar mats laid on it and starter bars at its edge.
	_ubox(-52.0, -12.0, 86.0, 97.0, y0, y0 + 0.6, TR_CONCRETE, M_STONE, TR_CONCRETE_L)
	for k in 4:
		var mu := -49.0 + k * 9.0
		_ubox(mu, mu + 7.0, 87.5, 95.5, y0 + 0.6, y0 + 0.72, TR_REBAR, M_STONE)
	_tr_rebar(-52.0, -12.0, 86.2, 96.8, y0 + 0.6, 1.2, 16)
	# The dug earth: brown ground, a heap and a ramp down into it.
	_ubox(-58.0, 8.0, 99.0, 113.0, y0, y0 + 0.06, Color("#8a6a48"), M_STONE, Color("#8a6a48"))
	_frustum(_rect(-24.0, 106.0, 7.0, 4.0), y0 + 0.06, _rect(-24.5, 106.0, 2.5, 1.2), y0 + 3.2, Color("#7d5f40"), Color("#8f7050"))
	# The site offices: two storeys of white containers by the west run, the stair and its landing.
	for k in 2:
		var cy := y0 + k * 2.7
		_ubox(-59.5, -47.5, 110.0, 114.0, cy, cy + 2.6, Color("#e8e8e4"), M_STONE, Color("#b9bbbd"))
		for w in 4:
			var wu := -58.5 + w * 3.0
			_ubox(wu, wu + 1.4, 109.94, 110.0, cy + 1.0, cy + 2.0, Color("#3c4a5a"), M_STONE)
	_ubox(-47.5, -45.5, 110.5, 113.5, y0 + 2.6, y0 + 2.75, TR_STEEL, M_STONE)
	_tr_bar(-45.5, 108.0, y0, -45.5, 112.0, y0 + 2.7, 0.9, TR_STEEL)
	_tr_bar(-45.0, 110.5, y0 + 2.75, -45.0, 113.5, y0 + 2.75, 0.06, TR_STEEL)
	# The excavator on the earth: tracks, the yellow body and cab, the boom, the stick, the bucket.
	var eu := -8.0
	var ev := 104.0
	for sz: float in [-1.2, 1.2]:
		_ubox(eu - 2.0, eu + 2.0, ev + sz - 0.35, ev + sz + 0.35, y0 + 0.06, y0 + 0.9, Color("#2b2b2c"), M_STONE)
	_ubox(eu - 1.6, eu + 1.4, ev - 1.3, ev + 1.3, y0 + 0.9, y0 + 2.1, TR_YELLOW, M_STONE, TR_YELLOW.darkened(0.1))
	_ubox(eu + 0.1, eu + 1.4, ev - 1.3, ev - 0.1, y0 + 2.1, y0 + 3.4, TR_YELLOW, M_STONE, TR_YELLOW.darkened(0.1))
	_ubox(eu + 1.38, eu + 1.42, ev - 1.2, ev - 0.2, y0 + 2.4, y0 + 3.3, Color("#3c4a5a"), M_STONE)
	_tr_bar(eu + 1.2, ev + 0.4, y0 + 2.0, eu + 4.6, ev + 0.4, y0 + 4.6, 0.45, TR_YELLOW)
	_tr_bar(eu + 4.6, ev + 0.4, y0 + 4.6, eu + 6.2, ev + 0.4, y0 + 1.2, 0.32, TR_YELLOW)
	_ubox(eu + 5.7, eu + 6.9, ev - 0.2, ev + 1.0, y0 + 0.4, y0 + 1.3, TR_STEEL, M_STONE)
	# Pallets of blocks and a timber stack by the slab.
	for p: Array in [[-5.0, 88.0], [-2.6, 88.0], [-5.0, 90.4]]:
		_ubox(p[0] - 1.0, p[0] + 1.0, p[1] - 1.0, p[1] + 1.0, y0, y0 + 1.2, Color("#b7b1a6"), M_STONE, Color("#c9c3b8"))
	_ubox(2.0, 12.0, 86.0, 88.6, y0, y0 + 1.2, TR_TIMBER, M_STONE, TR_TIMBER.darkened(0.12))


## Four white flagpoles with the contractors' banners (parodies, no words): pink, black over
## yellow, two blues with a red mark.
func _tr_flags(g: float) -> void:
	var v := 47.3
	var specs := [[-18.0, Color("#c24a7e"), Color("#e9a7c5")], [-15.3, Color("#2b2b3a"), Color("#e2cf55")],
			[-12.6, Color("#3f56a8"), Color("#7f93d6")], [-9.9, Color("#2f45a0"), Color("#c2302b")]]
	for s: Array in specs:
		var u: float = s[0]
		_tr_bar(u, v, g, u, v, g + 11.0, 0.14, Color("#e8e8e6"))
		var col: Color = s[1]
		var w := 1.3
		_ubox(u + 0.1, u + 0.1 + w, v - 0.03, v + 0.03, g + 6.2, g + 10.7, col, M_STONE, col)
		_ubox(u + 0.2, u + 0.2 + w * 0.8, v - 0.045, v + 0.045, g + 8.2, g + 8.9, s[2], M_STONE)


## A tower crane at [u, v, mast h, jib deg, jib length, counter length, number]: a red lattice mast
## on a concrete foot with its number on white plates, the slewing deck, the cab, the lattice jib
## with a trolley and hook, the counter-jib with its concrete blocks, the A-frame with four ties and
## a red lamp on the top.
func _tr_crane(c: Array) -> void:
	_tr_frame()
	var g := _g
	var base := _w(c[0], c[1])
	var h: float = c[2]
	var jl: float = c[4]
	var cl: float = c[5]
	_o = base
	_a = Vector2.from_angle(deg_to_rad(c[3]) + MSN_AXIS.angle())
	_b = Vector2(-_a.y, _a.x)
	var hw := 0.8
	_ubox(-2.4, 2.4, -2.4, 2.4, g - 0.3, g + 1.0, TR_CONCRETE, M_STONE, TR_CONCRETE_L)
	# The mast: four legs, an X on every face, a rung on every other panel.
	for sx: float in [-hw, hw]:
		for sz: float in [-hw, hw]:
			_tr_bar(sx, sz, g + 1.0, sx, sz, g + h, 0.3, TR_CRANE)
	var n := int(h / 3.0)
	for k in n:
		var ya := g + 1.0 + (h - 1.0) * float(k) / n
		var yb := g + 1.0 + (h - 1.0) * float(k + 1) / n
		var flip := k % 2 == 0
		for face in 4:
			var pa := Vector2(-hw, hw if face % 2 == 0 else -hw)
			var pb := Vector2(hw, hw if face % 2 == 0 else -hw)
			if face >= 2:
				pa = Vector2(pa.y, pa.x)
				pb = Vector2(pb.y, pb.x)
			if flip:
				_tr_bar(pa.x, pa.y, ya, pb.x, pb.y, yb, 0.17, TR_CRANE)
			else:
				_tr_bar(pb.x, pb.y, ya, pa.x, pa.y, yb, 0.17, TR_CRANE)
		if k % 2 == 0:
			_tr_bar(-hw, hw, yb, hw, hw, yb, 0.08, TR_CRANE)
			_tr_bar(-hw, -hw, yb, hw, -hw, yb, 0.08, TR_CRANE)
	# The number on a white plate on two faces: 1 or 2 in black strokes.
	var num: int = c[6]
	for face_v: float in [hw, -hw]:
		_tr_digit(num, face_v, g + h * 0.42)
	# The slewing deck, the cab on the jib's side, the jib and the counter-jib.
	_ubox(-1.3, 1.3, -1.0, 1.0, g + h, g + h + 0.85, TR_CRANE.darkened(0.2), M_STONE)
	_ubox(0.5, 2.1, -2.2, -0.9, g + h - 1.5, g + h + 0.9, Color("#d9dad5"), M_STONE, Color("#c9cac5"))
	_ubox(1.9, 2.15, -2.0, -1.1, g + h - 1.0, g + h + 0.5, Color("#35505f"), M_STONE)
	var seg := 2.6
	var m := int(jl / seg)
	for i in m:
		var x0 := 0.5 + (jl - 0.5) * float(i) / m
		var x1 := 0.5 + (jl - 0.5) * float(i + 1) / m
		var top0 := g + h + 2.6 - 1.3 * float(i) / m
		var top1 := g + h + 2.6 - 1.3 * float(i + 1) / m
		var side := -0.45 if i % 2 == 0 else 0.45
		_tr_bar(x0, 0.0, top0, x1, 0.0, top1, 0.2, TR_CRANE)
		_tr_bar(x0, side, g + h + 1.0, x1, 0.0, top1, 0.13, TR_CRANE)
		_tr_bar(x0, 0.45, g + h + 1.0, x1, 0.45, g + h + 1.0, 0.2, TR_CRANE)
		_tr_bar(x0, -0.45, g + h + 1.0, x1, -0.45, g + h + 1.0, 0.2, TR_CRANE)
	var mc := int(cl / seg)
	for i in mc:
		var x0 := -cl * float(i) / mc
		var x1 := -cl * float(i + 1) / mc
		_tr_bar(x0, 0.0, g + h + 2.3, x1, 0.0, g + h + 2.0, 0.1, TR_CRANE)
		_tr_bar(x0, 0.45 if i % 2 == 0 else -0.45, g + h + 1.0, x1, 0.0, g + h + 2.0, 0.07, TR_CRANE)
		_tr_bar(x0, 0.45, g + h + 1.0, x1, 0.45, g + h + 1.0, 0.2, TR_CRANE)
		_tr_bar(x0, -0.45, g + h + 1.0, x1, -0.45, g + h + 1.0, 0.2, TR_CRANE)
	# The counterweight: stacked concrete blocks at the counter-jib's end.
	_ubox(-cl + 0.2, -cl + 3.0, -0.9, 0.9, g + h + 0.1, g + h + 1.5, Color("#8a8a86"), M_STONE, Color("#7d7d79"))
	_ubox(-cl + 0.2, -cl + 3.0, -0.9, 0.9, g + h + 1.5, g + h + 2.6, Color("#9a9a95"), M_STONE, Color("#8a8a86"))
	# The A-frame over the deck, its four ties and the trolley with its hook line.
	var apex := g + h + 8.6
	_tr_bar(0.0, 0.45, g + h + 0.3, 0.0, 0.0, apex, 0.14, TR_CRANE)
	_tr_bar(0.0, -0.45, g + h + 0.3, 0.0, 0.0, apex, 0.14, TR_CRANE)
	for sd: float in [0.2, -0.2]:
		_tr_bar(0.0, sd, apex - 0.2, jl * 0.45, sd * 0.5, g + h + 2.3, 0.04, TR_REBAR)
		_tr_bar(0.0, sd, apex - 0.2, jl * 0.9, sd * 0.2, g + h + 1.6, 0.04, TR_REBAR)
		_tr_bar(0.0, sd, apex - 0.2, -cl, sd * 0.4, g + h + 2.3, 0.04, TR_REBAR)
	_ubox(jl * 0.55 - 0.6, jl * 0.55 + 0.6, -0.4, 0.4, g + h + 0.4, g + h + 1.0, Color("#3c3f43"), M_STONE)
	_tr_bar(jl * 0.55, 0.0, g + h + 0.4, jl * 0.55, 0.0, g + h * 0.45, 0.04, TR_REBAR)
	_ubox(jl * 0.55 - 0.25, jl * 0.55 + 0.25, -0.25, 0.25, g + h * 0.45 - 0.6, g + h * 0.45, TR_YELLOW, M_STONE)
	_prism(_rect(0.0, 0.0, 0.25, 0.25), apex, apex + 0.6, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = M_STONE
	_tr_frame()


## The crane's number on a white plate on the mast's face at local v = `fv` (mirrored on the far
## face so both read right from outside): a 7-segment-ish 1 or 2 in black.
func _tr_digit(n: int, fv: float, y: float) -> void:
	var s := signf(fv)
	var v0 := fv if s > 0.0 else fv - 0.06
	var v1 := fv + 0.06 if s > 0.0 else fv
	_ubox(-0.55, 0.55, v0, v1, y, y + 1.2, Color("#ecebe6"), M_STONE)
	var vv0 := v1 if s > 0.0 else v0 - 0.03
	var vv1 := v1 + 0.03 if s > 0.0 else v0
	var segs: Array = []
	if n == 1:
		segs = [[-0.06, 0.06, 0.1, 1.1]]
	else:
		segs = [[-0.3, 0.3, 1.0, 1.1], [0.2, 0.3, 0.6, 1.1], [-0.3, 0.3, 0.55, 0.65], [-0.3, -0.2, 0.1, 0.65], [-0.3, 0.3, 0.1, 0.2]]
	for sg: Array in segs:
		var ua: float = sg[0] * s
		var ub: float = sg[1] * s
		_ubox(minf(ua, ub), maxf(ua, ub), vv0, vv1, y + sg[2], y + sg[3], Color("#1d1e20"), M_STONE)


# --- The gold scissors in front of the museum (F's photo, 2026-11-15) ----------------------------

## A giant pair of scissors in gold bronze, open, standing on their points on a low granite plinth
## on the square in front of the museum's Plac Defilad face: two long blades crossing at a pivot
## about 5 m up, each handle ending in a ring, the rings turned a little off the blades' plane.
const SCIS_C := Vector2(-24.0, 29.5)   # the plinth's centre (museum frame)
const SCIS_GOLD := Color("#c9972f")
const SCIS_GRANITE := Color("#bdb9b0")


func _find_nozyce() -> void:
	_tr_frame()
	_add_site("nozyce", [_rect(SCIS_C.x, SCIS_C.y, 4.4, 3.6)])


func _build_nozyce(_site: Dictionary) -> void:
	_tr_frame()
	_g = _ground_under(_rect(SCIS_C.x, SCIS_C.y, 3.3, 2.5))
	var g := _g
	_o = _w(SCIS_C.x, SCIS_C.y)
	var yb := g + 0.95
	_mode = M_STONE
	_lbox(0.0, 0.0, 3.3, 2.5, g - 0.3, yb, SCIS_GRANITE, M_STONE, SCIS_GRANITE.lightened(0.06))
	_lbox(0.0, 0.0, 3.3, 2.5, g - 0.3, g + 0.12, SCIS_GRANITE.darkened(0.12), M_STONE)
	# Blade A: tip on the left, over the pivot, up and to the right into its ring; blade B the mirror.
	_nz_blade(Vector2(-1.3, 0.0), Vector2(0.0, 4.9), Vector2(0.9, 6.9), 0.12, 38.0, yb)
	_nz_blade(Vector2(1.05, 0.0), Vector2(0.0, 4.9), Vector2(-1.35, 6.9), -0.12, -32.0, yb)
	# The pivot screw between the blades.
	_ubox(-0.3, 0.3, -0.26, 0.26, yb + 4.6, yb + 5.2, SCIS_GOLD.darkened(0.1), M_GOLD)
	_tr_frame()
	_collide(_rect(SCIS_C.x, SCIS_C.y, 3.3, 2.5))


## One blade: tip, pivot and ring centre in (u, y) over the plinth top, its depth `vz`, the ring
## turned `ang` degrees off the plane. The blade thickens from tip to pivot, the shank is slimmer.
func _nz_blade(tip: Vector2, pivot: Vector2, ring: Vector2, vz: float, ang: float, yb: float) -> void:
	var m1 := tip.lerp(pivot, 0.4)
	_tr_bar(tip.x, vz, yb + tip.y, m1.x, vz, yb + m1.y, 0.32, SCIS_GOLD)
	_tr_bar(m1.x, vz, yb + m1.y, pivot.x, vz, yb + pivot.y, 0.62, SCIS_GOLD)
	_tr_bar(pivot.x, vz, yb + pivot.y, ring.x, vz, yb + ring.y - 0.45, 0.34, SCIS_GOLD)
	var r := 0.78
	var pts: Array[Vector3] = []
	var ca := cos(deg_to_rad(ang))
	var sa := sin(deg_to_rad(ang))
	for k in 8:
		var t := TAU * float(k) / 8.0
		pts.append(_tr_p(ring.x + r * cos(t) * ca, vz + r * cos(t) * sa, yb + ring.y + r * sin(t)))
	for k in 8:
		_beam(pts[k], pts[(k + 1) % 8], 0.2, SCIS_GOLD, true, M_GOLD)


# --- The two obelisks on Plac Defilad (F's photos and links, 2026-11-15 and 2026-11-17) ---------

## The 1955 granite obelisks on the Palace's Marszałkowska side (F, 2026-11-17: "two stand today,
## there were four at first; each about 12 m; the exits from the Palace's underground are beside
## them"; fotopolska "Obelisk południowy PKiN"): one in each paved semicircle at the Palace's north
## and south ends, at the middle of its straight side where the lawn's edge curves round the
## obelisk (the lawns' mapped notches, centrum.json areas, give the spots; the south one beside the
## Samo Centrum bar). A stepped base, a pedestal with a carved garland swag on each face under a
## cornice, a tapering square shaft with a pyramidion, and beside each a low granite box with a
## steel hatch, the underground's emergency exit (its side and size are a guess, not mapped).
## Before: the north one stood on the park's corner by Świętokrzyska, the south one at the Patelnia,
## both 25 m; the north semicircle was a walled pit (tools/defilad_obelisk.py, map_builder.gd
## GRID_HOLD). The museum's frame (u along Marszałkowska, southwards; v westwards).
const OBELISKS := [Vector2(-109.4, 111.1), Vector2(249.8, 110.8)]
const OBELISK_STONE := Color("#a9a59c")
const OBELISK_TOP := 11.0   # the shaft's top; the pyramidion takes it to 12 m
## The exit hatch: its centre from the obelisk's (u, v; towards the semicircle's arc) and size.
const OBELISK_HATCH := Vector2(5.0, 0.0)
const OBELISK_HATCH_SIZE := Vector3(1.3, 0.95, 1.1)   # half u, height, half v
const HATCH_STEEL := Color("#5d6166")


func _find_obeliski() -> void:
	_tr_frame()
	var zones: Array = []
	for k in OBELISKS.size():
		var c: Vector2 = OBELISKS[k]
		zones.append(_rect(c.x, c.y, 2.8, 2.8))
		var hc := c + OBELISK_HATCH * _hatch_side(k)
		zones.append(_rect(hc.x, hc.y, OBELISK_HATCH_SIZE.x + 0.2, OBELISK_HATCH_SIZE.z + 0.2))
	_add_site("obeliski", zones)


## The north obelisk's semicircle opens away from the Palace northwards (-u), the south one's southwards.
func _hatch_side(k: int) -> float:
	return -1.0 if k == 0 else 1.0


func _build_obeliski(_site: Dictionary) -> void:
	for k in OBELISKS.size():
		var c: Vector2 = OBELISKS[k]
		_tr_frame()
		_g = _ground_under(_rect(c.x, c.y, 2.6, 2.6))
		var g := _g
		_o = _w(c.x, c.y)
		var st := OBELISK_STONE
		_mode = M_STONE
		# Three steps, the pedestal and its cornice.
		_lbox(0.0, 0.0, 2.6, 2.6, g - 0.3, g + 0.2, st.darkened(0.06), M_STONE, st)
		_lbox(0.0, 0.0, 2.15, 2.15, g + 0.2, g + 0.4, st.darkened(0.03), M_STONE, st.lightened(0.03))
		_lbox(0.0, 0.0, 1.7, 1.7, g + 0.4, g + 0.6, st, M_STONE, st.lightened(0.04))
		_lbox(0.0, 0.0, 1.2, 1.2, g + 0.6, g + 2.8, st.darkened(0.04), M_STONE)
		_lbox(0.0, 0.0, 1.38, 1.38, g + 2.8, g + 3.05, st.lightened(0.05), M_STONE, st.lightened(0.05))
		# The garland swag on each face: a hanging V of two carved bands.
		for f4 in 4:
			var f := Vector2.from_angle(PI * 0.5 * f4)
			var s := Vector2(-f.y, f.x)
			var off := 1.24
			var l := _o + _a * (f.x * off) + _b * (f.y * off)
			var y := g + 2.45
			var p0 := Vector3(l.x + (_a * s.x + _b * s.y).x * 0.8, y, l.y + (_a * s.x + _b * s.y).y * 0.8)
			var p1 := Vector3(l.x, y - 0.55, l.y)
			var p2 := Vector3(l.x - (_a * s.x + _b * s.y).x * 0.8, y, l.y - (_a * s.x + _b * s.y).y * 0.8)
			_beam(p0, p1, 0.18, st.darkened(0.12))
			_beam(p1, p2, 0.18, st.darkened(0.12))
		# The shaft, tapering, a band at its foot, and the pyramidion.
		_lbox(0.0, 0.0, 1.05, 1.05, g + 3.05, g + 3.35, st, M_STONE)
		_frustum(_rect(0.0, 0.0, 0.95, 0.95), g + 3.35, _rect(0.0, 0.0, 0.58, 0.58), g + OBELISK_TOP, st.lightened(0.02))
		_pyramid(_rect(0.0, 0.0, 0.58, 0.58), g + OBELISK_TOP, g + OBELISK_TOP + 1.0, st.lightened(0.06))
		_collide(_rect(0.0, 0.0, 2.6, 2.6))
		# The underground's emergency exit beside it: a low granite box under a steel hatch.
		var h := OBELISK_HATCH * _hatch_side(k)
		var hs := OBELISK_HATCH_SIZE
		_g = _ground_under(_rect(h.x, h.y, hs.x, hs.z))
		var hg := _g
		_lbox(h.x, h.y, hs.x, hs.z, hg - 0.3, hg + hs.y, st.darkened(0.08), M_STONE, st.darkened(0.02))
		_lbox(h.x, h.y, hs.x - 0.15, hs.z - 0.15, hg + hs.y, hg + hs.y + 0.08, HATCH_STEEL, M_STONE, HATCH_STEEL)
		_collide(_rect(h.x, h.y, hs.x, hs.z))
	_tr_frame()


# --- The Cepelia pavilion and Zodiak (F's photos, 2026-11-08) ---------------------------------

## Two 1960s modernist pavilions in the start area (R5 of docs/design/start-area-real.md), rebuilt
## from F's photos (/mnt/project-files/pkin-surroundings/photos/S3-cepelia, E1-zodiak; spec
## docs/landmarks/specs/pavilions.md). Cepelia (Marszałkowska by Al. Jerozolimskie, Zygmunt
## Stępiński 1966, restored 2024 as a book and vinyl store): on a granite plinth with steps, a dark
## glass ground floor set back under an upper storey that floats on it; the upper storey is a ribbed
## silver band, a ribbon of dark teal glass and a deep ribbed silver fascia; a white stair core with
## upright fins closes the south end; a teal tile mosaic on the west front; the shop's parody name on
## the roof over the north end. Zodiak (Pasaż Wiecha, the Warsaw Architecture Pavilion): a white
## frame round a glass ground floor, a white concrete slab with a glass rail and a strip of grasses,
## a glass upper room set back behind a terrace under a white slatted pergola, the white neon word
## over the back. Both frames: u along the long side (north to south), v out of the front.
const CEP_OSM := "Pawilon Cepelii"
const CEP_ALONG := Vector2(0.344, 0.939)
const CEP_FRONT := Vector2(0.939, -0.344)   # east: Marszałkowska
const CEP_PLINTH := 0.45       # the granite plinth over the pavement
const CEP_LOW := 3.6           # the ground floor's top over the plinth
const CEP_BAND := 4.9          # the ribbed band's top
const CEP_GLASS_TOP := 7.1     # the glass ribbon's top
const CEP_TOP := 8.0           # the fascia's top (OSM h 8)
const CEP_RECESS := 1.6        # the ground floor's set-back under the upper storey
const CEP_CORE := 5.5          # the stair core's length at the south end
const CEP_GLASS := Color("#3f5866")
const CEP_FRAME := Color("#33383d")
const CEP_SILVER := Color("#c3c7cb")
const CEP_RIB := Color("#a9aeb3")
const CEP_EDGE := Color("#e8e8e4")
const CEP_ROOF := Color("#e4e1d8")   # white (the city's 2026 render)
const CEP_CORE_WALL := Color("#e7e3da")
const CEP_GRANITE := Color("#b9b6ae")
const CEP_MOSAIC := Color("#2b7a86")
const CEP_WORD := "EMPIRYK"
const CEP_SIGN := Color(0.96, 0.97, 1.0)
const ZOD_OSM := "Zodiak"
const ZOD_FRONT := Vector2(-0.939, 0.344)   # west: Pasaż Wiecha's square
const ZOD_LOW := 3.4           # the ground floor's top
const ZOD_SLAB := 4.2          # the terrace slab's top
const ZOD_H := 7.1             # the upper room's top
const ZOD_ROOF := 0.45
const ZOD_TERRACE := 3.2       # the upper room's set-back from the front
const ZOD_WHITE := Color("#eceae4")
const ZOD_CONCRETE := Color("#dddad2")
const ZOD_GLASS := Color("#5f7782")
const ZOD_RAIL := Color("#a9bcc6")
const ZOD_GRASS := Color("#7d8a4e")
const ZOD_WORD := "ZODIAK"
const ZOD_COLOUR := Color(0.5, 0.72, 1.0)   # blue-white neon (F's night photo, 2026-11-19)


func _find_modern_pavilions() -> void:
	for spec: Array in [["cepelia", CEP_OSM], ["zodiak", ZOD_OSM]]:
		var q := _landmark(spec[1])
		if q.size() < 3:
			continue
		_add_site(spec[0], [_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER))])
		if not sites.is_empty() and sites[-1]["key"] == spec[0]:
			sites[-1]["outline"] = _simplify(q, 0.4)


func _build_cepelia(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var r := _pav_frame(outline, CEP_ALONG, CEP_FRONT)
	var u0 := r.position.x
	var u1 := r.end.x
	var v0 := r.position.y
	var v1 := r.end.y
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The granite plinth with its steps (F's corner photos): a metre and a half round the pavilion.
	_ubox(u0 - 1.5, u1 + 1.5, v0 - 1.5, v1 + 1.5, g - 0.4, g + CEP_PLINTH, CEP_GRANITE, M_STONE, CEP_GRANITE)
	_ubox(u0 - 2.2, u1 + 2.2, v0 - 2.2, v1 + 2.2, g - 0.4, g + CEP_PLINTH * 0.5, CEP_GRANITE.darkened(0.05), M_STONE,
			CEP_GRANITE.darkened(0.05))
	var b := g + CEP_PLINTH
	var uc := u1 - CEP_CORE   # where the stair core starts
	# The ground floor: dark glass set back under the upper storey, lit warm at night.
	var low := _urect(u0 + CEP_RECESS, uc, v0 + CEP_RECESS, v1 - CEP_RECESS)
	_prism(low, b, b + CEP_LOW, CEP_GLASS.lightened(0.1), none, M_PAVILION)
	_mullions(low, b, b + CEP_LOW, 2.4, 0.05, CEP_FRAME)
	# The teal tile mosaic on the west front's north half (the street-front photo).
	_ubox(u0 + 3.0, u0 + 10.0, v0 + CEP_RECESS - 0.25, v0 + CEP_RECESS - 0.02, b, b + CEP_LOW - 0.2, CEP_MOSAIC)
	# The white stair core with its upright fins at the south end, the full height.
	_ubox(uc, u1, v0 + 1.0, v1 - 1.0, b, g + CEP_TOP, CEP_CORE_WALL, M_STONE, CEP_ROOF)
	var core := _urect(uc, u1, v0 + 1.0, v1 - 1.0)
	_mullions(core, b + 0.3, g + CEP_TOP - 0.4, 0.55, 0.12, CEP_CORE_WALL.darkened(0.1))
	# The upper storey: the ribbed silver band, the glass ribbon, the deep fascia.
	var top := _urect(u0, uc, v0, v1)
	_mode = M_STONE
	_soffit(top, b + CEP_LOW, CEP_EDGE.darkened(0.05))
	_prism(top, b + CEP_LOW, g + CEP_BAND, CEP_SILVER, none, M_STONE)
	_mullions(top, b + CEP_LOW, g + CEP_BAND, 0.6, 0.03, CEP_RIB)
	_prism(top, g + CEP_BAND, g + CEP_GLASS_TOP, CEP_GLASS, none, M_PAVILION)
	_mullions(top, g + CEP_BAND, g + CEP_GLASS_TOP, 1.6, 0.05, CEP_FRAME)
	_prism(top, g + CEP_GLASS_TOP, g + CEP_TOP, CEP_SILVER, CEP_ROOF, M_STONE, M_STONE)
	_mullions(top, g + CEP_GLASS_TOP, g + CEP_TOP, 0.6, 0.03, CEP_RIB)
	# The glass roof light in the middle of the white roof (the city's 2026 render, F 2026-11-25).
	var um := (u0 + uc) * 0.5
	var vm := (v0 + v1) * 0.5
	_ubox(um - 5.0, um + 5.0, vm - 3.0, vm + 3.0, g + CEP_TOP, g + CEP_TOP + 0.45, CEP_FRAME, M_STONE, Color("#6d93a0"))
	# The name on the roof over the north end, facing the crossing, and on the street front.
	_usign(CEP_WORD, u0 + 0.8, (v0 + v1) * 0.5, g + CEP_TOP + 0.1, -_a, 0.6 * (v1 - v0), 1.5, CEP_SIGN)
	_usign(CEP_WORD, u0 + 6.0, v1 - 0.5, g + CEP_TOP + 0.1, _b, 9.0, 1.5, CEP_SIGN)
	_collide(_urect(u0 + CEP_RECESS, u1, v0 + 1.0, v1 - 1.0))


func _build_zodiak(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["outline"]
	_g = _ground_under(outline)
	var r := _pav_frame(outline, CEP_ALONG, ZOD_FRONT)
	var u0 := r.position.x
	var u1 := r.end.x
	var v0 := r.position.y
	var v1 := r.end.y
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The ground floor: glass in a white frame, lit warm at night.
	var low := _urect(u0, u1, v0, v1 - 0.3)
	_prism(low, g - 0.4, g + ZOD_LOW, ZOD_GLASS.lightened(0.15), none, M_PAVILION)
	_mullions(low, g, g + ZOD_LOW, 1.7, 0.05, ZOD_WHITE)
	# The white terrace slab over it, a little proud at the front.
	_ubox(u0, u1, v0, v1 + 0.5, g + ZOD_LOW, g + ZOD_SLAB, ZOD_CONCRETE, M_STONE, ZOD_CONCRETE.darkened(0.08))
	_mode = M_STONE
	_soffit(_urect(u0, u1, v1 - 0.3, v1 + 0.5), g + ZOD_LOW, ZOD_WHITE.darkened(0.1))
	# The strip of grasses and the glass rail at the terrace's front.
	_ubox(u0 + 0.6, u1 - 0.6, v1 - 0.9, v1 - 0.15, g + ZOD_SLAB, g + ZOD_SLAB + 0.45, ZOD_GRASS)
	_ubox(u0, u1, v1 + 0.3, v1 + 0.4, g + ZOD_SLAB, g + ZOD_SLAB + 1.0, ZOD_RAIL)
	# The glass upper room behind the terrace, its flat white roof.
	var up := _urect(u0, u1, v0, v1 - ZOD_TERRACE)
	_prism(up, g + ZOD_SLAB, g + ZOD_H, ZOD_GLASS.lightened(0.1), none, M_PAVILION)
	_mullions(up, g + ZOD_SLAB, g + ZOD_H, 1.7, 0.05, ZOD_WHITE)
	_prism(up, g + ZOD_H, g + ZOD_H + ZOD_ROOF, ZOD_WHITE, ZOD_CONCRETE, M_STONE, M_STONE)
	# The slatted pergola over the terrace: thin white slats across it, a beam along its front.
	var y := g + ZOD_H + 0.05
	_ubox(u0, u1, v1 + 0.15, v1 + 0.45, y, y + 0.35, ZOD_WHITE)
	var n := maxi(2, roundi((u1 - u0) / 0.8))
	for k in n + 1:
		var u := lerpf(u0 + 0.1, u1 - 0.1, float(k) / n)
		_ubox(u - 0.06, u + 0.06, v1 - ZOD_TERRACE, v1 + 0.15, y + 0.1, y + 0.3, ZOD_WHITE)
	# The white neon word over the roof's front edge, facing the square.
	# F, 2026-11-19: on the FRONT (the square's side), standing on the upper room's roof edge.
	var sv := v1 - ZOD_TERRACE - 0.25
	_usign(ZOD_WORD, (u0 + u1) * 0.5, sv, g + ZOD_H + ZOD_ROOF + 0.6, _b, 0.75 * (u1 - u0), 2.2, ZOD_COLOUR)   # a little bigger (F, 2026-11-19)
	# The little neon star over the "i" (F's night photo): a lit plus and a lit diamond.
	var su := (u0 + u1) * 0.5 + 0.08 * 0.75 * (u1 - u0)
	var sy := g + ZOD_H + ZOD_ROOF + 0.6 + 2.35
	_lbox(su, sv, 0.03, 0.03, g + ZOD_H, sy - 0.2, Color("#2b2c2f"), M_STONE)   # its stem on the roof
	_lbox(su, sv, 0.3, 0.03, sy - 0.04, sy + 0.04, ZOD_COLOUR, M_LAMP, ZOD_COLOUR)
	_lbox(su, sv, 0.04, 0.03, sy - 0.3, sy + 0.3, ZOD_COLOUR, M_LAMP, ZOD_COLOUR)
	_lbox(su, sv, 0.12, 0.03, sy - 0.12, sy + 0.12, ZOD_COLOUR, M_LAMP, ZOD_COLOUR)
	# String lights over the square (the photo): bulbs hung from the pergola's front beam out to
	# three poles in the square, one sagging fan.
	var top_y := g + ZOD_H + 0.22   # inside the pergola beam, so the string is welded to it
	for f in [0.12, 0.5, 0.88]:
		var uu := lerpf(u0, u1, f)
		var from := _w(uu, v1 + 0.3)
		var to := _w(uu + (f - 0.5) * 6.0, v1 + 12.0)
		_beam(Vector3(to.x, g - 0.2, to.y), Vector3(to.x, g + 6.6, to.y), 0.12, Color("#2b2c2f"))
		_pow_festoon(Vector3(from.x, top_y, from.y), Vector3(to.x, g + 6.5, to.y), 0.6, 7)
	_collide(low)


# --- Pasaż Wiecha's pavilions (first scene items 4-5, 2026-11-02) ------------------------------

## The low shop pavilions on Pasaż Wiecha, the walkway behind the Eastern Wall's stores, from the
## Mac photo report (docs/landmarks/photo-reports/dt_pawilony.md: three Commons photos of the
## pasaż and the 2025 GUGiK orthophoto): two-storey flat-roofed modernist boxes, a black and dark
## grey shop storey of glass in thin dark frames under a dark fascia, a white upper band with one
## strip window round it, a flat roof with a few plant boxes. Four OpenStreetMap outlines, found by
## their vertex average (two sit under or against the slabs, whose outlines hold the same
## points): north to south the podium row under the slab behind Sawa, the block by tower75, the
## pavilion on the square by Chmielna, and the podium under the south slab by Aleje
## Jerozolimskie. OSM gives them 4.3-7.6 m; the photos show two storeys, so all stand WIECHA_TOP
## high. The strip in front of Scena Relax stays in the theatre's LoD2 model (one mass with it). The pasaż's paving, lamp masts and furniture are
## first_scene.gd's; Zodiak (the glass pavilion with the overhanging roof) is its own site.
const WIECHA_AT := [Vector2(-863.2, 178.7), Vector2(-826.1, 226.8), Vector2(-827.8, 182.7),
		Vector2(-803.6, 317.4)]
const WIECHA_LOW := 3.8        # the shop storey's top
const WIECHA_FASCIA := 0.4     # the dark fascia over the shopfronts
const WIECHA_OVER := 0.9       # how far the fascia reaches out
const WIECHA_STRIP := Vector2(4.9, 6.1)   # the upper band's strip window (over the ground)
const WIECHA_TOP := 7.2
const WIECHA_SHOP := Color("#2b3035")
const WIECHA_FRAME := Color("#1b1d20")
const WIECHA_WHITE := Color("#e9e8e3")
const WIECHA_GLASS := Color("#3b4753")
const WIECHA_ROOF := Color("#8b8c89")


func _find_wiecha() -> void:
	var zones: Array[PackedVector2Array] = []
	var outlines: Array[PackedVector2Array] = []
	for at: Vector2 in WIECHA_AT:
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() >= 3 and float(bld["mh"]) < 0.5 and _centre(q).distance_to(at) < 1.5:
				outlines.append(_simplify(q, 0.4))
				zones.append(_largest(Geometry2D.offset_polygon(q, 1.0, Geometry2D.JOIN_MITER)))
				break
	_add_site("wiecha", zones)
	if not sites.is_empty() and sites[-1]["key"] == "wiecha":
		sites[-1]["outlines"] = outlines


func _build_wiecha(site: Dictionary) -> void:
	var none := Color(0, 0, 0, 0)
	var idx := -1
	for outline: PackedVector2Array in site["outlines"]:
		idx += 1
		if outline.size() < 3:
			continue
		_g = _ground_under(outline)
		var g := _g
		# The shop storey: dark glass lit warm at night, thin dark frames every 2.2 m.
		_prism(outline, g - 0.4, g + WIECHA_LOW, WIECHA_BROWN if idx == WIECHA_WIDOK else WIECHA_SHOP, none, M_PAVILION)
		_mullions(outline, g, g + WIECHA_LOW, 2.2, 0.05, WIECHA_FRAME)
		# The fascia over the shopfronts, reaching out WIECHA_OVER m: its face, its top round the
		# upper band, its underside.
		var over := _largest(Geometry2D.offset_polygon(outline, WIECHA_OVER, Geometry2D.JOIN_MITER))
		if over.size() >= 3:
			var y := g + WIECHA_LOW
			_prism(over, y, y + WIECHA_FASCIA, WIECHA_FRAME, none, M_STONE)
			_mode = M_STONE
			_cap_holes(over, [outline], y + WIECHA_FASCIA, WIECHA_FRAME.lightened(0.12))
			_soffit(over, y, WIECHA_FRAME.lightened(0.2))
		# The white upper band, and its strip window just proud of it all round.
		_prism(outline, g + WIECHA_LOW + WIECHA_FASCIA, g + WIECHA_TOP, WIECHA_WHITE, WIECHA_ROOF, M_STONE, M_STONE)
		var strip := _largest(Geometry2D.offset_polygon(outline, 0.04, Geometry2D.JOIN_MITER))
		if strip.size() >= 3:
			_prism(strip, g + WIECHA_STRIP.x, g + WIECHA_STRIP.y, WIECHA_GLASS, none, M_PAVILION + 0.5)
			_mullions(strip, g + WIECHA_STRIP.x, g + WIECHA_STRIP.y, 1.5, 0.03, WIECHA_FRAME)
		# A low parapet and two plant boxes on the roof.
		var inner := _largest(Geometry2D.offset_polygon(outline, -0.25, Geometry2D.JOIN_MITER))
		if inner.size() >= 3:
			_prism(outline, g + WIECHA_TOP, g + WIECHA_TOP + 0.35, WIECHA_WHITE.darkened(0.04), none, M_STONE)
			_mode = M_STONE
			_cap_holes(outline, [inner], g + WIECHA_TOP + 0.35, WIECHA_WHITE.darkened(0.08))
		var c := _centre(outline)
		for k in 2:
			var p := c + Vector2(2.2 * (k * 2 - 1), 0.8 * (k * 2 - 1))
			if Geometry2D.is_point_in_polygon(p, outline):
				_prism(_square(p, 0.9), g + WIECHA_TOP, g + WIECHA_TOP + 1.1, Color("#a9aaa6"), Color("#7f807c"), M_STONE, M_STONE)
		_wiecha_life(outline, idx, g)
		_collide(outline)
	_mode = M_STONE


# Night life on the shop storeys (F, 2026-11-19, the "Warsaw 3 a.m." teaser): each bay between two
# frames is a lit window display or a dark shut shopfront; some have a striped awning; the fascia
# carries a small light-box word; one pavilion has the 24 h kebab hatch with its blade sign and a
# string of bulbs. Everything is the site's one mesh (M_LAMP glows at night) and a few neon words:
# no new material, no new draw call. Parody words only (neon_signs.gd's own list).
const WIECHA_FRONT := Vector2(-0.937, 0.349)   # towards the pasaż (first_scene.gd's -FRAME_T)
const WIECHA_BAY := 2.2                        # = the mullion step above
const WIECHA_DISPLAYS := [Color("#f2c27a"), Color("#f6dcae"), Color("#9fd0e8"), Color("#f2a7b8"), Color("#b8e0a8")]
const WIECHA_AWNINGS := [Color("#7a2630"), Color("#24425f"), Color("#2f5b3f"), Color("#3a3a3e")]
const WIECHA_WORDS := ["APTEKA", "KWIATY", "KANTOR", "PIZZA", "BAR MLECZNY", "KLUB"]
const WIECHA_HATCH := Color("#ffb454")
const WIECHA_WIDOK := 3      # Widok 26, the corner of the pasaż and Aleje Jerozolimskie: a dark-brown fast-food ground floor (F's photos, 2026-11-19)
const WIECHA_BROWN := Color("#3b2b24")
const WIECHA_FOOD := ["ATOMIK 24H", "KEBAB 24H", "PIZZA", "NOCNY", "KEBAB 24H"]
const WIECHA_KEBAB_AT := 0   # the outline (in WIECHA_AT order) that carries the kebab hatch
## The pasaż's real cafés and shops on the pavilions' fronts (F, 2026-11-22: "add the cafés and signs
## that are there"), from OpenStreetMap's shops and F's and the opening night's photos, as parodies
## (warsaw-tone): outline (WIECHA_AT order) -> [s (first_scene.gd's frame: metres north along
## Marszałkowska), half width, word, tube colour, the lit display's colour, a string of bulbs]. A bay
## inside a shop's span is always lit in its colour; the fascia carries its word instead of the
## generic one. Złota 11's row, south to north: a loft restaurant, a vegan bar, a bubble-tea bar, a
## Middle-Eastern grill, the home-cooking restaurant in jars (green neon), a pierogi bar and the
## kebab hatch; Kiseki's sushi on the square at Chmielna.
const WIECHA_SHOPS := {
	0: [[-32.6, 2.4, "STRYCH", Color(1.0, 0.78, 0.4), Color("#f2c27a"), true],
		[-27.6, 2.4, "WEGE FUD", Color(0.35, 1.0, 0.45), Color("#c8e8a0"), true],
		[-22.6, 2.4, "AUREOLA TEA", Color(1.0, 0.45, 0.75), Color("#f2b8d0"), false],
		[-13.2, 3.6, "BLISKI ZACHÓD", Color(1.0, 0.72, 0.2), Color("#f6d090"), true],
		[-2.0, 4.4, "SŁOICZEK", Color(0.25, 1.0, 0.4), Color("#f6dcae"), true],
		[9.2, 3.6, "PIEROŻKARNIA", Color(1.0, 0.35, 0.3), Color("#f2c27a"), true]],
	1: [[-52.7, 7.0, "KISIEL SUSHI", Color(1.0, 0.25, 0.3), Color("#f0d8b0"), true]],
}
## The kebab hatch's place on its outline, s in the same frame (Złota 11's kebab bar, OSM).
const WIECHA_KEBAB_S := 21.4
const WIECHA_FS_O := Vector2(-937.0, 210.1)   # first_scene.gd FRAME_O / FRAME_S (read-only here)
const WIECHA_FS_S := Vector2(-0.34917, -0.93706)


## One pavilion's night life. `idx` seeds the pattern, so it never changes between builds.
func _wiecha_life(outline: PackedVector2Array, idx: int, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var front := _edge_facing(outline, WIECHA_FRONT, 4.0)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var len := a.distance_to(b)
		if len < 3.0:
			continue
		var o := _out(outline, a, b)
		var d := (b - a) / len
		var n := maxi(1, roundi(len / WIECHA_BAY))
		var bay := len / float(n)
		var on_front := i == front
		var hatch := (n - 1) / 2 if (on_front and idx == WIECHA_KEBAB_AT) else -1
		var shops: Array = WIECHA_SHOPS.get(idx, []) if on_front else []
		if hatch >= 0:
			# The hatch at the real kebab bar's bay (the nearest to WIECHA_KEBAB_S).
			var best := INF
			for k in n:
				var ds := absf((a + d * bay * (float(k) + 0.5) - WIECHA_FS_O).dot(WIECHA_FS_S) - WIECHA_KEBAB_S)
				if ds < best:
					best = ds
					hatch = k
		for k in n:
			var h := (idx * 7 + i * 5 + k * 3 + (idx ^ k) * 11) % 10
			var c := a + d * bay * (float(k) + 0.5)
			var shop: Array = []
			var bs := (c - WIECHA_FS_O).dot(WIECHA_FS_S)
			for sh: Array in shops:
				if absf(bs - float(sh[0])) <= float(sh[1]):
					shop = sh
			if not shop.is_empty() and k != hatch:
				h = 0
			var half := bay * 0.5 - 0.14
			var p0 := c - d * half + o * 0.03
			var p1 := c + d * half + o * 0.03
			var nrm := Vector3(o.x, 0.0, o.y)
			_mode = M_LAMP
			if k == hatch:
				# The serving window: a hot orange pane, a counter, the blade sign over it.
				_quad(Vector3(p0.x, g + 0.9, p0.y), Vector3(p1.x, g + 0.9, p1.y), Vector3(p1.x, g + 2.5, p1.y),
						Vector3(p0.x, g + 2.5, p0.y), nrm, WIECHA_HATCH)
				_mode = M_STONE
				var cc := c + o * 0.35
				_prism(_rect_dir(cc, d, half, 0.3), g, g + 1.0, Color("#3c3a38"), Color("#8c8a85"), M_STONE, M_STONE)
				_awning(a, d, o, c, bay, g, Color("#b0281f"))
				_blade(c - d * (half + 0.1), o, d, g + 2.6, "KEBAB 24H", Color(1.0, 0.3, 0.2))
				continue
			if h >= 7:
				continue   # shut: its dark glass stays dark
			var glow: Color = WIECHA_DISPLAYS[(idx + i + k) % WIECHA_DISPLAYS.size()] if shop.is_empty() else shop[4]
			_quad(Vector3(p0.x, g + 0.55, p0.y), Vector3(p1.x, g + 0.55, p1.y), Vector3(p1.x, g + 2.6, p1.y),
					Vector3(p0.x, g + 2.6, p0.y), nrm, glow.darkened(0.4))
			# A shelf and a dark row of goods across the lit pane.
			_mode = M_STONE
			var s0 := c - d * half + o * 0.06
			var s1 := c + d * half + o * 0.06
			_quad(Vector3(s0.x, g + 1.25, s0.y), Vector3(s1.x, g + 1.25, s1.y), Vector3(s1.x, g + 1.4, s1.y),
					Vector3(s0.x, g + 1.4, s0.y), nrm, WIECHA_FRAME)
			if h < 3 and on_front and shop.is_empty():
				_awning(a, d, o, c, bay, g, WIECHA_AWNINGS[(idx + k) % WIECHA_AWNINGS.size()])
		# The named shops: the word over its span on the fascia, a string of warm bulbs under it.
		for sh: Array in shops:
			var t0 := (float(sh[0]) - (a - WIECHA_FS_O).dot(WIECHA_FS_S)) / d.dot(WIECHA_FS_S)
			if t0 < 0.0 or t0 > len:
				continue
			var m := a + d * t0 + o * (WIECHA_OVER + 0.02)
			var word: String = sh[2]
			var kk := minf(0.42 / (Neon.ROW_H * Neon.PIXEL), float(sh[1]) * 1.7 / Neon.length_of(word))
			signs.append([word, Vector3(m.x, g + WIECHA_LOW + 0.02, m.y), Vector3(o.x, 0.0, o.y), kk, sh[3]])
			if bool(sh[5]):
				var f0 := a + d * (t0 - float(sh[1]) + 0.2) + o * (WIECHA_OVER + 0.25)
				var f1 := a + d * (t0 + float(sh[1]) - 0.2) + o * (WIECHA_OVER + 0.25)
				_pow_festoon(Vector3(f0.x, g + WIECHA_LOW - 0.05, f0.y), Vector3(f1.x, g + WIECHA_LOW - 0.05, f1.y), 0.3,
						maxi(3, roundi(float(sh[1]) * 1.6)))
		# Widok 26: a big parody fast-food name on the white band over each longer face.
		if idx == WIECHA_WIDOK and len >= 6.0:
			var fw: String = WIECHA_FOOD[i % WIECHA_FOOD.size()]
			var fm := (a + b) * 0.5 + o * 0.02
			var fk := minf(0.9 / (Neon.ROW_H * Neon.PIXEL), minf(5.0, len * 0.6) / Neon.length_of(fw))
			signs.append([fw, Vector3(fm.x, g + WIECHA_LOW + WIECHA_FASCIA + 0.45, fm.y), Vector3(o.x, 0.0, o.y), fk,
					Neon.colour_for(fw, float(i) * 0.41)])
		# A light-box word on the fascia of the longer faces (the fascia reaches out WIECHA_OVER m).
		if len >= 6.0 and not (idx == WIECHA_KEBAB_AT and on_front) and shops.is_empty():
			var word: String = WIECHA_WORDS[(idx * 3 + i) % WIECHA_WORDS.size()]
			var m := (a + b) * 0.5 + o * (WIECHA_OVER + 0.02)
			var kk := minf(0.36 / (Neon.ROW_H * Neon.PIXEL), 3.2 / Neon.length_of(word))
			signs.append([word, Vector3(m.x, g + WIECHA_LOW + 0.03, m.y), Vector3(o.x, 0.0, o.y), kk, Neon.colour_for(word, float(idx + i) * 0.37)])
		# 24 h kebab: a string of bulbs along the front, hung a little out from the fascia.
		if on_front and idx == WIECHA_KEBAB_AT:
			var q0 := a + d * 0.8 + o * (WIECHA_OVER + 0.3)
			var q1 := b - d * 0.8 + o * (WIECHA_OVER + 0.3)
			_pow_festoon(Vector3(q0.x, g + WIECHA_LOW + 0.1, q0.y), Vector3(q1.x, g + WIECHA_LOW + 0.1, q1.y), 0.35, 6)
	_mode = M_STONE


## A sloped awning over a bay: its cloth rising to the wall at 3.3 m, 0.9 m out at 2.75 m, and the front valance.
func _awning(a: Vector2, d: Vector2, o: Vector2, c: Vector2, bay: float, g: float, col: Color) -> void:
	_mode = M_STONE
	var w := bay * 0.5 - 0.1
	var w0 := c - d * w + o * 0.05
	var w1 := c + d * w + o * 0.05
	var f0 := w0 + o * 0.9
	var f1 := w1 + o * 0.9
	var up := Vector3(o.x * 0.5, 0.86, o.y * 0.5).normalized()
	_quad(Vector3(w0.x, g + 3.3, w0.y), Vector3(w1.x, g + 3.3, w1.y), Vector3(f1.x, g + 2.75, f1.y), Vector3(f0.x, g + 2.75, f0.y), up, col)
	_quad(Vector3(f0.x, g + 2.75, f0.y), Vector3(f1.x, g + 2.75, f1.y), Vector3(f1.x, g + 2.55, f1.y), Vector3(f0.x, g + 2.55, f0.y),
			Vector3(o.x, 0.0, o.y), col.darkened(0.12))


## A blade sign at right angles to the wall at the bay's edge: one neon word, readable from one side.
func _blade(at: Vector2, o: Vector2, d: Vector2, y: float, word: String, col: Color) -> void:
	var k := minf(0.7 / (Neon.ROW_H * Neon.PIXEL), 2.0 / Neon.length_of(word))
	var mid := at + o * (WIECHA_OVER + 0.2 + Neon.length_of(word) * k * 0.5)   # stands out from the fascia
	# One face only: the neon quad shows through from behind, so a second, opposite face drew the
	# word mirrored over the first (Mac night shot, 2026-11-19). Readable from the -d side (flipped 2026-11-19: the Mac shot from the pasaż still read it backwards).
	signs.append([word, Vector3(mid.x, y, mid.y), Vector3(-d.x, 0.0, -d.y), k, col])


## A rectangle on the ground plan: centre `c`, its long axis `d`, half sizes hu along and hv across.
func _rect_dir(c: Vector2, d: Vector2, hu: float, hv: float) -> PackedVector2Array:
	var e := Vector2(-d.y, d.x)
	return PackedVector2Array([c - d * hu - e * hv, c + d * hu - e * hv, c + d * hu + e * hv, c - d * hu + e * hv])


# --- Plac Centralny (F's photos, 2026-11-05; the tribune and the field's place, 2026-11-08) ---------

const PCZ_GRASS := Color("#6f9e42")
const PCZ_SLAB := Color("#c4beb3")
const PCZ_PALE := Color("#d3cbbf")
const PCZ_RED := Color("#c9242b")
const PCZ_GREEN := Color("#58a85a")

const PCZ_HEART := Rect2(-3.0, 10.4, 10.0, 25.6)

## The tribune (OSM's walls, u -14.5..10.5, v -0.4..10; the west stair's landing to v -4.5): the
## granite, its lighter coping and the bronze plaque.
const TRY_GRANITE := Color("#bab6ad")
const TRY_COPING := Color("#d4d0c6")
const TRY_SOIL := Color("#5f7d3c")
const TRY_LEAF := Color("#7fa04a")
const TRY_TRUNK := Color("#5a4a3a")
const TRY_PLAQUE := Color("#3a3833")


func _build_plac_centralny(_site: Dictionary) -> void:
	_pcz_frame()
	var g := _g
	_mode = M_STONE
	# The striped field: pale granite slabs in rows across the axis, a strip of grass between each
	# two (the render's stripes), the pale heart on it. It is part of the ground, not a podium (F,
	# 2026-11-10): every corner is draped on map.terrain_height, a few centimetres over it, so the
	# slope of the square runs through it and no wall shows at its edge. Only the trybuna is raised.
	var f := PCZ_FIELD
	var rows := 24
	var dv := f.size.y / rows
	_pcz_drape(f.position.x, f.end.x, f.position.y, f.end.y, 0.14, PCZ_GRASS.darkened(0.15), 4, rows)
	for k in rows:
		var v0 := f.position.y + k * dv + 0.22
		_pcz_drape(f.position.x + 0.15, f.end.x - 0.15, v0, v0 + dv - 0.44, 0.17,
				PCZ_SLAB.lightened(0.04 * float(k % 3)), 4, 1)
	var h := PCZ_HEART
	_pcz_drape(h.position.x, h.end.x, h.position.y, h.end.y, 0.20, PCZ_PALE, 2, 8)
	# WARSZAWA: red letters on two slim steel posts, facing east, at the heart's east end.
	var sv := h.end.y - 2.0
	for su: float in [-3.8, 3.8]:
		var pp := _w(h.get_center().x + su, sv - 0.4)
		var pg: float = map.terrain_height(pp.x, pp.y)
		_prism(_circle(pp, 0.08, 5), pg, pg + 1.3, Color("#8b8f93"), Color("#8b8f93"), M_STONE, M_STONE)
	var mid := _w(h.get_center().x, sv)
	var mg: float = map.terrain_height(mid.x, mid.y)
	signs.append(["WARSZAWA", Vector3(mid.x, mg + 1.0, mid.y), Vector3(_b.x, 0.0, _b.y), 1.3, PCZ_RED])
	# Green deckchairs scattered on the heart, facing the tribune.
	for i in 12:
		var u := h.get_center().x + (fposmod(sin(i * 12.9898) * 43758.5453, 1.0) - 0.5) * 8.0
		var v := h.position.y + 3.0 + fposmod(sin(i * 78.233) * 43758.5453, 1.0) * 16.0
		var cp := _w(u, v)
		var cg: float = map.terrain_height(cp.x, cp.y)
		_lbox(u, v, 0.28, 0.25, cg + 0.09, cg + 0.36, PCZ_GREEN, M_STONE, PCZ_GREEN.lightened(0.12))
		_lbox(u, v + 0.22, 0.28, 0.05, cg + 0.36, cg + 0.8, PCZ_GREEN.darkened(0.1), M_STONE, PCZ_GREEN)


## A flat patch of the square laid ON the ground: the local rectangle u0..u1 x v0..v1 cut into
## `cols` x `rows` quads whose corners sit `dy` over map.terrain_height, top face only (no walls).
func _pcz_drape(u0: float, u1: float, v0: float, v1: float, dy: float, col: Color, cols: int, rows: int) -> void:
	var pts: Array[Vector3] = []
	for j in rows + 1:
		for i in cols + 1:
			var w := _w(lerpf(u0, u1, float(i) / cols), lerpf(v0, v1, float(j) / rows))
			pts.append(Vector3(w.x, map.terrain_height(w.x, w.y) + dy, w.y))
	for j in rows:
		for i in cols:
			var k := j * (cols + 1) + i
			_quad(pts[k], pts[k + 1], pts[k + cols + 2], pts[k + cols + 1], Vector3.UP, col,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## Trybuna honorowa (F's photos, 2026-11-08: the south face, the planters being planted, the
## aerial render): the rebuilt remnant of the 1955 parade tribune, its old granite cladding on a new
## frame, made a garden with a view. A battered granite block 25 m along the axis's cross (u) by
## 10.4 m, its east face to Marszałkowska 4.5 m high; from the west a broad stair between two
## planters climbs to a landing at 2.4 m between two corner piers (the plaque on the south one),
## three deep sitting steps rise from it to a walk at 4.1 m, and behind the east parapet a long
## planter holds the young trees. The side cheeks step up with the seats: the zig-zag of the photo.
func _build_trybuna(site: Dictionary) -> void:
	_pcz_frame()
	_g = _ground_under((site["zone"] as Array)[0])
	var g := _g
	var none := Color(0, 0, 0, 0)
	_mode = M_STONE
	# The core, its walls leaning in a little (the photo's batter), to the landing's height.
	_frustum(_rect(-2.0, 4.8, 12.65, 5.35), g - 0.3, _rect(-2.0, 4.8, 12.5, 5.2), g + 2.4, TRY_GRANITE.darkened(0.06), TRY_COPING)
	# Three sitting steps across the block (v 1.2..4.6), the walk (v 4.6..6.4) and the east planter
	# with its coping rim (v 6.4..10).
	var tops: Array[float] = [2.8, 3.25, 3.7]
	for k in 3:
		var v0 := 1.2 + k * 1.133
		_lbox(-2.0, v0 + 0.567, 11.7, 0.567, g + 2.3, g + tops[k], TRY_GRANITE.darkened(0.12), M_STONE,
				TRY_COPING if k % 2 == 0 else TRY_GRANITE.lightened(0.05))
	_lbox(-2.0, 5.5, 11.7, 0.9, g + 2.3, g + 4.1, TRY_GRANITE, M_STONE, TRY_COPING.darkened(0.04))
	_lbox(-2.0, 8.2, 12.5, 1.8, g + 2.3, g + 4.3, TRY_GRANITE.darkened(0.04), M_STONE, TRY_SOIL)
	for rim: Array in [[-2.0, 6.6, 12.5, 0.2], [-2.0, 9.8, 12.5, 0.2], [-14.3, 8.2, 0.2, 1.8], [10.3, 8.2, 0.2, 1.8]]:
		_lbox(rim[0], rim[1], rim[2], rim[3], g + 4.3, g + 4.55, TRY_COPING, M_STONE, TRY_COPING.lightened(0.05))
	# The side cheeks, 0.8 m thick, a step above the seats: the stepped profile on the south and
	# north faces; the corner piers at the landing (3.3 m).
	for side: float in [-1.0, 1.0]:
		var cu := -2.0 + side * 12.1
		_lbox(cu, 0.4, 0.4, 0.8, g + 2.3, g + 3.3, TRY_GRANITE, M_STONE, TRY_COPING)
		for k in 3:
			_lbox(cu, 1.2 + k * 1.133 + 0.567, 0.4, 0.567, g + 2.3, g + tops[k] + 0.35, TRY_GRANITE, M_STONE, TRY_COPING)
		_lbox(cu, 5.5, 0.4, 0.9, g + 2.3, g + 4.45, TRY_GRANITE, M_STONE, TRY_COPING)
	# The plaque on the south pier's south face: a dark bronze panel, the old photo pale on it.
	_lbox(-14.55, 0.4, 0.04, 0.6, g + 1.5, g + 2.7, TRY_PLAQUE, M_STONE, TRY_PLAQUE)
	_lbox(-14.6, 0.4, 0.02, 0.5, g + 2.25, g + 2.6, Color("#9d9a92"), M_STONE, Color("#9d9a92"))
	# The west stair (v -4.5..-0.4) from the square to the landing, and the two low planters that
	# frame it (OSM's west wall, u -5.3..8.4).
	var n := 15
	var run := 4.1 / n
	for k in n:
		_lbox(1.5, -4.5 + (k + 0.5) * run, 3.0, run * 0.5, g - 0.2, g + 2.4 * (k + 1) / n, TRY_COPING.darkened(0.08),
				M_STONE, TRY_COPING)
	for pl: Array in [[-3.4, 1.9], [6.45, 1.95]]:
		_lbox(pl[0], -2.45, pl[1], 2.05, g - 0.2, g + 1.2, TRY_GRANITE, M_STONE, TRY_COPING)
		_lbox(pl[0], -2.45, pl[1] - 0.25, 1.8, g + 1.2, g + 1.25, TRY_SOIL, M_STONE, TRY_SOIL)
		for j in 3:
			var su: float = pl[0] + (j - 1) * (pl[1] - 0.8) * 0.75
			_frustum(_circle(_w(su, -2.45 + 0.6 * (j - 1)), 0.7, 6), g + 1.2, _circle(_w(su, -2.45 + 0.6 * (j - 1)), 0.3, 6), g + 1.85,
					TRY_LEAF.darkened(0.2), TRY_LEAF.darkened(0.1))
	# The young trees: five in the east planter, one in each stair planter.
	var spots := [[-11.0, 8.2, 4.3], [-6.6, 8.0, 4.3], [-2.0, 8.3, 4.3], [2.6, 8.0, 4.3], [7.0, 8.2, 4.3],
			[-3.4, -3.3, 1.25], [6.45, -1.6, 1.25]]
	for sp: Array in spots:
		var p := _w(sp[0], sp[1])
		var y: float = g + float(sp[2])
		var j := 0.85 + 0.3 * fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0)
		_prism(_square(p, 0.1), y, y + 2.6 * j, TRY_TRUNK, none, M_STONE)
		_mode = M_STONE
		_frustum(_circle(p, 0.5, 6), y + 2.0 * j, _circle(p, 1.7 * j, 6), y + 3.6 * j, TRY_LEAF.darkened(0.12))
		_frustum(_circle(p, 1.7 * j, 6), y + 3.6 * j, _circle(p, 0.6, 6), y + 5.4 * j, TRY_LEAF, TRY_LEAF.lightened(0.08))
	_collide(_rect(-2.0, 4.8, 12.6, 5.3))
	_collide(_rect(1.5, -2.45, 6.9, 2.05))


## The square's historic candelabras (F's photo of the Palace's forecourt, 2026-11-15): a square
## granite pedestal with its cornice and a dark bronze plaque, a round granite column with a base
## and a flared capital, and on it a black iron head of four curved arms round a centre stem, five
## frosted white globes lit at night. About 7.3 m tall.
func _build_plac_centralny_lamps(_site: Dictionary) -> void:
	_mode = M_STONE
	var granite := Color("#b3afa6")
	var granite_l := Color("#c4c0b7")
	var iron := Color("#25272a")
	var globe := Color("#f2efe6")
	for l: Array in PCZ_LAMPS:
		var p := _pcz_world(l[0], l[1])
		_g = map.terrain_height(p.x, p.y)
		var g := _g
		_o = p
		_a = PCZ_N
		_b = PCZ_E
		_lbox(0.0, 0.0, 0.62, 0.62, g - 0.3, g + 1.2, granite, M_STONE, granite_l)
		_lbox(0.0, 0.0, 0.72, 0.72, g + 1.2, g + 1.36, granite_l, M_STONE, granite_l)
		for fv: float in [-1.0, 1.0]:
			_lbox(0.0, fv * 0.64, 0.26, 0.02, g + 0.35, g + 0.95, Color("#2f2b25"), M_STONE)
		_frustum(_circle(p, 0.38, 8), g + 1.36, _circle(p, 0.29, 8), g + 1.75, granite)
		_prism(_circle(p, 0.26, 8), g + 1.75, g + 4.6, granite, granite, M_STONE, M_STONE)
		_frustum(_circle(p, 0.27, 8), g + 4.6, _circle(p, 0.42, 8), g + 4.95, granite_l)
		_lbox(0.0, 0.0, 0.44, 0.44, g + 4.95, g + 5.1, granite_l, M_STONE, granite_l)
		_prism(_circle(p, 0.08, 5), g + 5.1, g + 6.55, iron, iron, M_STONE, M_STONE)
		var heads: Array[Vector3] = [Vector3(p.x, g + 6.55, p.y)]
		for k in 4:
			var d := _a.rotated(TAU * (k + 0.5) / 4.0) * 0.62
			var tip := Vector3(p.x + d.x, g + 6.05, p.y + d.y)
			_beam(Vector3(p.x, g + 5.45, p.y), tip, 0.07, iron)
			heads.append(tip)
		_mode = M_LAMP
		for h: Vector3 in heads:
			var c := Vector2(h.x, h.z)
			_frustum(_circle(c, 0.09, 6), h.y, _circle(c, 0.2, 6), h.y + 0.3, globe)
			_frustum(_circle(c, 0.2, 6), h.y + 0.3, _circle(c, 0.07, 6), h.y + 0.68, globe, globe)
		_mode = M_STONE
		_a = Vector2(1.0, 0.0)
		_b = Vector2(0.0, 1.0)
		_collide(_rect(0.0, 0.0, 0.62, 0.62))


# docs/landmarks/photo-reports/poczta.md and pasta.md; specs docs/landmarks/specs/poczta.md, pasta.md)
