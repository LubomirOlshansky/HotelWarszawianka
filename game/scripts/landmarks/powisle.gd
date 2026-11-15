extends "res://scripts/landmarks/old_town.gd"
## TD-10, the landmarks split (2026-11-15): one part of landmarks.gd, Powiśle: BUW, Kopernik, the
## new flats, Flisac, Ostrogski, Wybrzeże Kościuszkowskie 41 and the Academy of Fine Arts. Moved as
## it was from the one big file. landmarks.gd is the class the game makes; every file of
## game/scripts/landmarks/ is one link of its base chain (facade_kit.gd, common.gd, then the areas
## in the order of landmarks.gd's `extends` chain), so code here may use this file, common.gd and
## the facade kit, never another area: a helper two areas need goes to common.gd.


# --- Wybrzeże Kościuszkowskie 41 and the Academy of Fine Arts (F's photos, 2026-11-13) -----------

## The power company's building (1937-39, Jabłoński and Korszyński, Wybrzeże Kościuszkowskie 41 at
## the corner of Tamka; spec docs/landmarks/specs/eon41.md): an L of two wings in sandstone round
## a courtyard, their right-angled corner turned into a quarter-round with eight metal medallions on
## it, a glass-block stair tower beside the curve that rises over the roof into a round lantern (a
## white band, an open steel lattice drum and a rim), the red company sign on the roof (the parody
## ELEKTRON). The mapped outline's corner is a zigzag chamfer: here it is the true arc. Frame:
## EON_T along the Tamka face towards the river, EON_W along the Wybrzeże face away from the
## corner; EON_C is the sharp corner the two faces would meet in.
const EON_C := Vector2(449.1, -592.5)
const EON_T := Vector2(0.7628, -0.6460)
const EON_W := Vector2(0.6234, 0.7824)
const EON_R := 9.0                  # the corner's radius
const EON_ARC := 8                  # its segments
const EON_LOW := 21.5               # the wings' eave (six storeys)
const EON_TALL := 25.5              # the corner block's eave (a storey over)
const EON_TOWER := Vector2(9.0, 14.5)  # the stair tower along the Wybrzeże face (b from the corner)
const EON_TOWER_TOP := 30.0
const EON_STONE := Color("#b3a78f")
const EON_LIGHT := Color("#c4b9a2")
const EON_BASE := Color("#625d55")
const EON_ROOF := Color("#6d6f70")
const EON_GLASS := Color("#56646c")
const EON_STEEL := Color("#3b4044")
const EON_WHITE := Color("#e9e6de")
const EON_BRONZE := Color("#5f5f52")
const EON_BRONZE_LIGHT := Color("#8a8b78")
const EON_RED := Color(0.86, 0.09, 0.14)
## Medallions on the curve: [u along the arc 0..1, height over the ground, radius].
const EON_MEDALLIONS := [[0.41, 19.8, 1.2], [0.83, 17.6, 1.0], [0.5, 15.8, 0.65], [0.12, 14.2, 1.0],
		[0.8, 13.4, 1.3], [0.38, 11.4, 0.7], [0.72, 9.4, 1.1], [0.15, 7.8, 1.0],
		[0.62, 5.6, 0.9], [0.3, 4.6, 0.8], [0.88, 6.4, 0.7], [0.2, 17.2, 0.8]]

## The Academy of Fine Arts (Wybrzeże Kościuszkowskie 37; spec docs/landmarks/specs/asp37.md): the
## 1911-14 school (Alfons Gravier) in pale plaster with its post-war storey and the new storey
## under a dark zinc roof, and JEMS's 2013 wing on the street: four storeys, sand-coloured concrete
## to the street and the side, a glass front to the courtyard.
const ASP_OLD_AT := Vector2(520.0, -485.0)
const ASP_NEW_AT := Vector2(480.0, -515.0)
const ASP_OLD_EAVE := 12.4
const ASP_OLD_TOP := 15.4
const ASP_NEW_H := 16.2
const ASP_PLASTER := Color("#e2cbae")
const ASP_CREAM := Color("#e6d8be")
const ASP_ZINC := Color("#596066")
const ASP_SAND := Color("#cdbc9a")
const ASP_GLASS := Color("#4d6670")


func _find_eon41() -> void:
	var ring := _tallest_at(Vector2(425.0, -560.0))
	if ring.size() < 3:
		return
	_add_site("eon41", [ring])
	if not sites.is_empty() and sites[-1]["key"] == "eon41":
		sites[-1]["ring"] = ring


func _find_asp37() -> void:
	var old_ring := _tallest_at(ASP_OLD_AT)
	var new_ring := _tallest_at(ASP_NEW_AT)
	if old_ring.size() < 3 or new_ring.size() < 3:
		return
	_add_site("asp37", [old_ring, new_ring])
	if not sites.is_empty() and sites[-1]["key"] == "asp37":
		sites[-1]["old"] = old_ring
		sites[-1]["new"] = new_ring


## A point of the power company's frame: a along the Tamka face, b along the Wybrzeże face.
func _eon_p(a: float, b: float) -> Vector2:
	return EON_C + EON_T.normalized() * a + EON_W.normalized() * b


## The footprint: the mapped wings with the corner's zigzag replaced by the true arc.
func _eon_ring() -> PackedVector2Array:
	var t := EON_T.normalized()
	var w := EON_W.normalized()
	var ctr := _eon_p(-EON_R, EON_R)
	var ring := PackedVector2Array([Vector2(400.8, -551.6)])
	for k in EON_ARC + 1:
		var th := PI * 0.5 * k / EON_ARC
		ring.append(ctr + (-w * cos(th) + t * sin(th)) * EON_R)
	ring.append_array(PackedVector2Array([Vector2(460.0, -578.8), Vector2(489.8, -541.4), Vector2(485.4, -537.8),
			Vector2(478.7, -532.2), Vector2(465.7, -548.8), Vector2(464.1, -547.6), Vector2(461.7, -550.7),
			Vector2(463.2, -551.9), Vector2(462.8, -552.4), Vector2(452.4, -565.6), Vector2(447.2, -571.9),
			Vector2(428.9, -556.6), Vector2(415.9, -545.7), Vector2(417.3, -544.1), Vector2(414.3, -541.5),
			Vector2(412.9, -542.9), Vector2(410.3, -540.4)]))
	return ring


## A thin sign/plaque quad on a wall: from (a0, b0) to (a1, b1) in the frame, y0..y1 over the
## ground, `out` the wall's outward normal, `proud` out of it.
func _eon_plate(p0: Vector2, p1: Vector2, y0: float, y1: float, out: Vector2, proud: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	_wall(p0 + out * proud, p1 + out * proud, _g + y0, _g + y1, out, col)
	_mode = keep


func _build_eon41(_site: Dictionary) -> void:
	var ring := _eon_ring()
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var t := EON_T.normalized()
	var w := EON_W.normalized()
	var skin := M_SKIN + float(S_PUNCHED) / 16.0
	# The wings, the plinth, the cornice and the parapet.
	_prism(ring, g - 0.6, g + EON_LOW, EON_STONE, EON_ROOF, skin, M_STONE)
	_band(ring, 0.1, g - 0.6, g + 1.3, EON_BASE)
	# The corner block a storey higher: the Tamka end and the Wybrzeże wing's first 40 m.
	var clip_a := PackedVector2Array([_eon_p(-18.0, -1.0), _eon_p(1.0, -1.0), _eon_p(1.0, 16.0), _eon_p(-18.0, 16.0)])
	var clip_b := PackedVector2Array([_eon_p(-16.0, -1.0), _eon_p(1.0, -1.0), _eon_p(1.0, 42.0), _eon_p(-16.0, 42.0)])
	var clip: PackedVector2Array = _largest(Geometry2D.merge_polygons(clip_a, clip_b))
	var tall: Array[PackedVector2Array] = []
	for q: PackedVector2Array in Geometry2D.intersect_polygons(ring, clip):
		if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
			tall.append(q)
	for q in tall:
		_prism(q, g + EON_LOW - 0.1, g + EON_TALL, EON_STONE, EON_ROOF, skin, M_STONE)
		_band(q, 0.35, g + EON_TALL - 0.7, g + EON_TALL, EON_LIGHT)
		_parapet(q, g + EON_TALL, 0.6, EON_STONE)
		_collide(q)
	_band(ring, 0.35, g + EON_LOW - 0.7, g + EON_LOW, EON_LIGHT)
	_parapet(ring, g + EON_LOW, 0.6, EON_STONE)
	_collide(ring)
	pocket_rings.append(ring)
	# The curved wall's eight bronze medallions: a dark rim, a paler star, a dark boss.
	var ctr := _eon_p(-EON_R, EON_R)
	var keep := _mode
	_mode = M_STONE
	for m: Array in EON_MEDALLIONS:
		var th := PI * 0.5 * float(m[0])
		var nrm := -w * cos(th) + t * sin(th)
		var at := ctr + nrm * (EON_R + 0.04)
		var c := Vector3(at.x, g + float(m[1]), at.y)
		var n3 := Vector3(nrm.x, 0.0, nrm.y)
		var r: float = float(m[2])
		_disc(c, n3, r, 12, EON_BRONZE)
		_disc(c + n3 * 0.03, n3, r * 0.72, 8, EON_BRONZE_LIGHT)
		_disc(c + n3 * 0.06, n3, r * 0.32, 8, EON_BRONZE)
	_mode = keep
	# The glass-block stair tower beside the curve: a rounded glass front, a stone ledge at every
	# storey, over the roof into the lantern.
	var b0 := EON_TOWER.x
	var b1 := EON_TOWER.y
	var tower := PackedVector2Array([_eon_p(-1.2, b0), _eon_p(0.45, b0), _eon_p(1.0, (b0 + b1) * 0.5), _eon_p(0.45, b1), _eon_p(-1.2, b1)])
	_prism(tower, g - 0.3, g + EON_TOWER_TOP, EON_GLASS, EON_ROOF, M_GLASS, M_STONE)
	var y := 3.6
	while y < EON_TOWER_TOP:
		_band(tower, 0.12, g + y - 0.2, g + y + 0.2, EON_LIGHT)
		y += 3.6
	_band(tower, 0.25, g + EON_TOWER_TOP - 0.5, g + EON_TOWER_TOP, EON_LIGHT)
	_collide(tower)
	var lc := _eon_p(-1.0, (b0 + b1) * 0.5)
	var drum := _circle(lc, 3.6, 16)
	_prism(drum, g + EON_TOWER_TOP, g + EON_TOWER_TOP + 1.3, EON_WHITE, EON_ROOF, M_STONE, M_STONE)
	for k in 12:
		var a0 := TAU * k / 12.0
		var a1 := TAU * (k + 1) / 12.0
		var p0 := lc + Vector2.from_angle(a0) * 3.4
		var p1 := lc + Vector2.from_angle(a1) * 3.4
		var yb := g + EON_TOWER_TOP + 1.3
		_beam(Vector3(p0.x, yb, p0.y), Vector3(p0.x, yb + 2.9, p0.y), 0.16, EON_STEEL, true, M_STEEL)
		_beam(Vector3(p0.x, yb, p0.y), Vector3(p1.x, yb + 2.9, p1.y), 0.1, EON_STEEL, true, M_STEEL)
	_prism(drum, g + EON_TOWER_TOP + 4.2, g + EON_TOWER_TOP + 5.0, EON_WHITE, EON_ROOF, M_STONE, M_STONE)
	# Doors on the Tamka face, the dark plaque by the tower, the eagle's pale plate.
	var out_t := -w   # Tamka face outward
	var out_w := t    # Wybrzeże face outward
	for a: float in [-12.0, -34.0]:
		_eon_plate(_eon_p(a - 1.9, 0.0), _eon_p(a + 1.9, 0.0), 0.0, 3.6, out_t, 0.08, EON_BASE.darkened(0.3))
		_eon_plate(_eon_p(a - 2.3, 0.0), _eon_p(a + 2.3, 0.0), 3.6, 4.0, out_t, 0.14, EON_LIGHT)
	_eon_plate(_eon_p(0.0, 17.2), _eon_p(0.0, 19.4), 1.1, 5.6, out_w, 0.06, Color("#6a5443"))
	# The roof signs (the company's red letters, a parody): one to Tamka on the corner block, one to
	# the Wybrzeże on its wing.
	var k_sign := 2.2 / (Neon.ROW_H * Neon.PIXEL)
	var top := g + EON_TALL + 0.6
	var s1 := _eon_p(-9.0, 1.2)
	signs.append(["ELEKTRON", Vector3(s1.x, top, s1.y), Vector3(out_t.x, 0.0, out_t.y), k_sign, EON_RED])
	var s2 := _eon_p(-1.2, 20.0)
	signs.append(["ELEKTRON", Vector3(s2.x, top, s2.y), Vector3(out_w.x, 0.0, out_w.y), k_sign, EON_RED])


func _build_asp37(site: Dictionary) -> void:
	var old_ring: PackedVector2Array = site["old"]
	var new_ring: PackedVector2Array = site["new"]
	_g = minf(_ground_under(old_ring), _ground_under(new_ring))
	var g := _g
	var none := Color(0, 0, 0, 0)
	var skin := M_SKIN + float(S_PUNCHED) / 16.0
	# The old school (photos): three storeys of cream-peach render with white cornices over a low
	# plinth, under a dark zinc roof that steps in twice.
	_prism(old_ring, g - 0.6, g + ASP_OLD_EAVE, ASP_PLASTER, none, skin, M_STONE)
	_band(old_ring, 0.1, g - 0.6, g + 1.0, EON_BASE)
	_band(old_ring, 0.3, g + ASP_OLD_EAVE - 0.6, g + ASP_OLD_EAVE, ASP_CREAM.lightened(0.15))
	for step: Array in [[-1.0, 0.0, 1.5], [-3.2, 1.5, 3.0]]:
		var top_ring := _largest(Geometry2D.offset_polygon(old_ring, float(step[0]), Geometry2D.JOIN_MITER))
		if top_ring.size() >= 3:
			var y0 := g + ASP_OLD_EAVE - 0.1 + float(step[1])
			_prism(top_ring, y0, g + ASP_OLD_EAVE + float(step[2]), ASP_ZINC, ASP_ZINC.lightened(0.08), M_STONE, M_STONE)
	_collide(old_ring)
	pocket_rings.append(old_ring)
	# JEMS's wing (photos): tall reflective glass strips between cream render bands at the floor
	# lines, the top floor and the roof in the same grey zinc as the old roof.
	var h := ASP_NEW_H
	_prism(new_ring, g - 0.6, g + h - 3.8, ASP_GLASS, none, M_GLASS, M_STONE)
	for y: float in [3.3, 7.4, 11.5]:
		_band(new_ring, 0.15, g + y, g + y + 0.9, ASP_CREAM)
	_band(new_ring, 0.15, g - 0.6, g + 1.0, EON_BASE)
	_prism(new_ring, g + h - 3.8, g + h, ASP_ZINC, ASP_ZINC.lightened(0.08), M_STONE, M_STONE)
	_collide(new_ring)
	pocket_rings.append(new_ring)


# --- Arkady Kubickiego and the castle gardens ---------------------------------------------------

## Piano House (Zajęcza by Topiel, Powiśle; flats of the 2010s below the music university): a model
## instead of a plain block. The mapped outline (an L with a saw-toothed west front of 1-2 m
## steps) rises to 17.8 m in white plaster with dark window strips in a piano keyboard's rhythm
## (S_KEYS), a glazed ground floor; the top floor is set back 1.6 m in dark glass under a flat
## roof. Spec docs/landmarks/specs/piano_house.md. Heights from OSM (20.8 m), the rest estimated.
const PIANO_WHITE := Color("#eeece6")
const PIANO_GLASS := Color("#3a4250")
const PIANO_ROOF := Color("#8d9094")
const PIANO_BODY := 17.8
const PIANO_TOP := 20.8


func _find_piano_house() -> void:
	var outline := _landmark("Piano House")
	if outline.size() >= 3:
		# The L's centre (both the corner mean and the box centre) falls in its open corner, outside
		# the outline, so the zone adds the hull: the plain block it replaces goes (nothing else
		# stands in the corner).
		_add_site("piano_house", [outline, Geometry2D.convex_hull(outline)])
		if not sites.is_empty() and sites[-1]["key"] == "piano_house":
			sites[-1]["ring"] = _simplify(outline, 0.35)


func _build_piano_house(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_g = _ground_under(ring)
	var g := _g
	_prism(ring, g - 1.5, g + PIANO_BODY, PIANO_WHITE, PIANO_ROOF, M_SKIN + float(S_KEYS) / 16.0, M_STONE)
	# the set-back top floor: the outline pulled in 1.6 m (the saw teeth fall away), dark glass
	var inner := Geometry2D.offset_polygon(_simplify(ring, 1.2), -1.6, Geometry2D.JOIN_MITER)
	for q: PackedVector2Array in inner:
		if q.size() >= 3 and absf(_area(q)) > 20.0:
			_prism(q, g + PIANO_BODY, g + PIANO_TOP, PIANO_GLASS, PIANO_ROOF, M_SKIN + float(S_DARK) / 16.0, M_STONE)
	_collide(ring)


## Cube House (Topiel by Leszczyńska, Powiśle): a model instead of a plain block. A white
## eight-storey cube (27.4 m, from OSM) with punched windows (S_PUNCHED), and on every face a
## staircase of boxed bays, one per floor, stepping left and right (the "cubes"). The mapped
## jog on one face (a full-height bay) is kept and carries its boxes on its front. Spec docs/landmarks/specs/cube_house.md.
const CUBE_WHITE := Color("#e9e7e1")
const CUBE_BAY := Color("#b3aca0")
const CUBE_ROOF := Color("#86898c")
const CUBE_HEIGHT := 27.4
const CUBE_FLOOR := 2.95
const CUBE_BAY_W := 2.8
const CUBE_BAY_OUT := 1.1


func _find_cube_house() -> void:
	var outline := _landmark("Cube House")
	if outline.size() >= 3:
		_add_site("cube_house", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "cube_house":
			sites[-1]["ring"] = _simplify(outline, 0.35)


func _build_cube_house(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	# the local frame: u along the longest edge, v across; the box of the outline in it
	var longest := 0.0
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > longest:
			longest = e.length()
			_a = e.normalized()
	_b = Vector2(-_a.y, _a.x)
	_o = _centre(ring)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in ring:
		var l := _local(q)
		lo = lo.min(l)
		hi = hi.max(l)
	_g = _ground_under(ring)
	var g := _g
	_prism(ring, g - 1.5, g + CUBE_HEIGHT, CUBE_WHITE, CUBE_ROOF, M_SKIN + float(S_PUNCHED) / 16.0, M_STONE)
	# a thin plain parapet band round the roof
	_prism(Geometry2D.offset_polygon(ring, 0.12, Geometry2D.JOIN_MITER)[0], g + CUBE_HEIGHT - 0.5, g + CUBE_HEIGHT + 0.6,
			CUBE_WHITE.lightened(0.04), CUBE_WHITE, M_STONE, M_STONE)
	# the bays: on each face one box per floor from the first, stepping between two spots along
	# the face (on the jogged face, the entrance bay's front, the spots close in to stay on it)
	var faces := [[Vector2(0, -1), lo.y, hi.x - lo.x], [Vector2(1, 0), hi.x, hi.y - lo.y], [Vector2(-1, 0), lo.x, hi.y - lo.y],
			[Vector2(0, 1), hi.y, hi.x - lo.x]]
	# a bay's half width, and its half depth with 0.5 m sunk into the wall (the faces lean a little
	# off the frame)
	var half := CUBE_BAY_W * 0.5
	var depth := (CUBE_BAY_OUT + 0.5) * 0.5
	for f: Array in faces:
		var n: Vector2 = f[0]
		var plane: float = f[1]
		var span: float = f[2]
		var spread := 0.25 if _cube_face_straight(ring, n, plane) else 0.15
		for k in range(1, int(CUBE_HEIGHT / CUBE_FLOOR) - 1):
			var t := span * spread * (1.0 if k % 2 == 0 else -1.0)
			var along := Vector2(n.y, n.x).abs()
			var mid := (lo + hi) * 0.5
			var c := mid * along + along * t + n * (CUBE_BAY_OUT - depth) + n.abs() * plane
			var y0 := g + k * CUBE_FLOOR + 0.15
			_lbox(c.x, c.y, half if n.y != 0.0 else depth, depth if n.y != 0.0 else half, y0, y0 + CUBE_FLOOR - 0.3,
					CUBE_BAY, M_SKIN + float(S_PUNCHED) / 16.0, CUBE_BAY.darkened(0.1))
	_collide(ring)


## Whether a face of the Cube House (normal n in its local frame, at `plane`) runs straight: every
## corner on that side of the outline lies within 0.6 m of the plane.
func _cube_face_straight(ring: PackedVector2Array, n: Vector2, plane: float) -> bool:
	var near := 0
	for q in ring:
		var l := _local(q)
		var d := l.dot(n) - plane * (n.x + n.y)
		if absf(d) < 0.6:
			near += 1
		elif l.dot(n) > 0.0 and absf(d) < 2.5:
			return false
	return near >= 2


## Hortus (Topiel 12, Powiśle; 2009-2011 by the Naj studio, on the plot of a sweet factory): a
## model instead of plain blocks. A closed block round a garden (its trees are the scanned
## ones). The mapped outline, an L along Topiel and Zajęcza, is the office: six floors to 20.8 m
## (OSM) of big glass panes in a white frame (S_GRID) over a recessed, dark-glazed ground floor
## on slim piers along the streets. The flats along Drewniana (the unnamed 20.8 m outline at
## HORTUS_FLATS_AT) are styled as a pre-war tenement: warm plaster, a cornice, a mansard floor.
## Spec docs/landmarks/specs/hortus.md; colours and pier rhythm estimated (photo check).
const HORTUS_GLASS := Color("#5c6f72")
const HORTUS_ROOF := Color("#8a8d90")
const HORTUS_PLASTER := Color("#dcc6a3")
const HORTUS_MANSARD := Color("#5f6367")
const HORTUS_TOP := 20.8
const HORTUS_LOBBY := 4.5
const HORTUS_RECESS := 1.4
const HORTUS_PIER := 7.5
const HORTUS_CORNICE := 17.9
const HORTUS_FLATS_AT := Vector2(110.0, -580.0)


func _find_hortus() -> void:
	var outline := _landmark("Hortus")
	if outline.size() < 3:
		return
	# The L's box centre is in the courtyard: the zone adds the hull (only the garden is in it).
	var hull := Geometry2D.convex_hull(outline)
	var flats := _tallest_at(HORTUS_FLATS_AT)
	var zone := [outline, hull]
	if flats.size() >= 3:
		zone.append(flats)
	_add_site("hortus", zone)
	if not sites.is_empty() and sites[-1]["key"] == "hortus":
		sites[-1]["ring"] = _simplify(outline, 0.35)
		sites[-1]["hull"] = hull
		sites[-1]["flats"] = _simplify(flats, 0.35) if flats.size() >= 3 else PackedVector2Array()


func _build_hortus(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	var hull: PackedVector2Array = site["hull"]
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_g = _ground_under(ring)
	var g := _g
	# the ground floor pulled in under the offices, dark glass (lit warm at night)
	for q: PackedVector2Array in Geometry2D.offset_polygon(ring, -HORTUS_RECESS, Geometry2D.JOIN_MITER):
		if q.size() >= 3 and absf(_area(q)) > 30.0:
			_prism(q, g - 1.5, g + HORTUS_LOBBY, HORTUS_GLASS.darkened(0.2), HORTUS_ROOF, M_SKIN + float(S_DARK) / 16.0, M_STONE)
	# the five office floors over it, glass in a white frame, a plain parapet band on top
	_prism(ring, g + HORTUS_LOBBY, g + HORTUS_TOP, HORTUS_GLASS, HORTUS_ROOF, M_SKIN + float(S_GRID) / 16.0, M_STONE)
	_prism(ring, g + HORTUS_TOP, g + HORTUS_TOP + 0.6, Color("#e6e4de"), HORTUS_ROOF, M_STONE, M_STONE)
	# slim piers under the overhang on the street sides (the edges that face out of the block)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < HORTUS_PIER:
			continue
		var n := _out(ring, a, b)
		if Geometry2D.is_point_in_polygon((a + b) * 0.5 + n * 3.0, hull):
			continue  # a courtyard side
		var d := (b - a) / length
		var count := int(length / HORTUS_PIER)
		var step := length / float(count)
		for k in range(1, count):
			var p := a + d * (step * k) - n * (HORTUS_RECESS * 0.5)
			_prism(PackedVector2Array([p + (d + n) * 0.25, p + (d - n) * 0.25, p - (d + n) * 0.25, p - (d - n) * 0.25]),
					g - 0.5, g + HORTUS_LOBBY, Color("#e6e4de"), Color(0, 0, 0, 0), M_STONE, M_STONE)
	_collide(ring)
	# the flats on Drewniana, a pre-war tenement in looks: plaster, a cornice, a mansard floor
	var flats: PackedVector2Array = site["flats"]
	if flats.size() >= 3:
		_prism(flats, g - 1.5, g + HORTUS_CORNICE, HORTUS_PLASTER, HORTUS_ROOF, M_MONUMENT, M_STONE)
		var ledge := Geometry2D.offset_polygon(flats, 0.35, Geometry2D.JOIN_MITER)
		if not ledge.is_empty():
			_prism(ledge[0], g + HORTUS_CORNICE, g + HORTUS_CORNICE + 0.55, HORTUS_PLASTER.lightened(0.12), HORTUS_ROOF, M_STONE, M_STONE)
		for q: PackedVector2Array in Geometry2D.offset_polygon(_simplify(flats, 1.0), -1.2, Geometry2D.JOIN_MITER):
			if q.size() >= 3 and absf(_area(q)) > 30.0:
				_prism(q, g + HORTUS_CORNICE + 0.55, g + HORTUS_TOP, HORTUS_MANSARD, HORTUS_ROOF, M_STONE, M_STONE)
		_collide(flats)


## Moderna Powiśle (Zajęcza 1A; shown as "Modernka", a parody of the developer's name): a model
## instead of a plain block. The developer joined a restored pre-war tenement to a new glass
## wing. The mapped outline (14.2 m, OSM) is split 13.9 m back from its long front on Zajęcza
## (where the outline's notch says the street block ends): the front is the tenement (cream
## plaster, tall windows between piers, a cornice), the back the new wing (glass in white floor
## bands, S_RIBBON) under a set-back penthouse floor in dark glass to 17.4 m (the listing's
## two-level penthouses). Spec docs/landmarks/specs/moderna.md; which part is old is a guess.
const MODERNA_PLASTER := Color("#e2d5ba")
const MODERNA_GLASS := Color("#4c5966")
const MODERNA_ROOF := Color("#8b8e90")
const MODERNA_BODY := 14.2
const MODERNA_PENT := 17.4
const MODERNA_FRONT := 13.9


func _find_moderna() -> void:
	var outline := _landmark("Moderna Powiśle")
	if outline.size() >= 3:
		_add_site("moderna", [outline, Geometry2D.convex_hull(outline)])
		if not sites.is_empty() and sites[-1]["key"] == "moderna":
			sites[-1]["ring"] = _simplify(outline, 0.35)


func _build_moderna(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	# the front: the longest edge (on Zajęcza); +v runs into the block
	var front := 0
	for i in ring.size():
		if ring[(i + 1) % ring.size()].distance_to(ring[i]) > ring[(front + 1) % ring.size()].distance_to(ring[front]):
			front = i
	var p0 := ring[front]
	var p1 := ring[(front + 1) % ring.size()]
	_o = p0
	_a = (p1 - p0).normalized()
	_b = -_out(ring, p0, p1)
	_g = _ground_under(ring)
	var g := _g
	var band := PackedVector2Array([_o - _a * 100.0 - _b * 5.0, _o + _a * 100.0 - _b * 5.0,
			_o + _a * 100.0 + _b * MODERNA_FRONT, _o - _a * 100.0 + _b * MODERNA_FRONT])
	# the tenement at the front, its cornice a little proud of the wall
	for q: PackedVector2Array in Geometry2D.intersect_polygons(ring, band):
		if q.size() < 3 or absf(_area(q)) < 20.0:
			continue
		_prism(q, g - 1.5, g + MODERNA_BODY - 0.6, MODERNA_PLASTER, MODERNA_ROOF, M_MONUMENT, M_STONE)
		var ledge := Geometry2D.offset_polygon(q, 0.3, Geometry2D.JOIN_MITER)
		if not ledge.is_empty():
			_prism(ledge[0], g + MODERNA_BODY - 0.6, g + MODERNA_BODY, MODERNA_PLASTER.lightened(0.1), MODERNA_ROOF, M_STONE, M_STONE)
	# the new wing behind, and its penthouse floor pulled in 1.5 m
	for q: PackedVector2Array in Geometry2D.clip_polygons(ring, band):
		if q.size() < 3 or absf(_area(q)) < 20.0 or Geometry2D.is_polygon_clockwise(q):
			continue
		_prism(q, g - 1.5, g + MODERNA_BODY, MODERNA_GLASS, MODERNA_ROOF, M_SKIN + float(S_RIBBON) / 16.0, M_STONE)
		for t: PackedVector2Array in Geometry2D.offset_polygon(q, -1.5, Geometry2D.JOIN_MITER):
			if t.size() >= 3 and absf(_area(t)) > 20.0:
				_prism(t, g + MODERNA_BODY, g + MODERNA_PENT, MODERNA_GLASS.darkened(0.2), MODERNA_ROOF, M_SKIN + float(S_DARK) / 16.0, M_STONE)
	_collide(ring)


## Flisac (Tamka 2, the Ghelamco apartments by the Świętokrzyski bridge, 2022; F's photos
## 2026-11-13): a model instead of the mapped 14 m block. A V of two wings round the bend of Tamka
## and Wybrzeże Kościuszkowskie, a corner chamfered where they meet. Shops on the ground floor behind
## dark glass between the stone piers (a coffee place under a white canopy at the corner, a
## grocer's and a wine shop on the sides), six floors of a light stone grid (3.6 m bays, big
## dark windows, a copper blind here and there, a few loggias), a dark coping, then two set-back
## floors behind a glass-balustraded terrace, and a green roof with a pergola of glass, planters,
## a dark lift core and air-conditioning boxes. The low 7.6 m block in the elbow (OpenStreetMap) is
## the garden podium. The shops' names are parodies (KAWOBIURKO, KAROLEK, WINOSTORY). Spec
## docs/landmarks/specs/flisac.md.
const FLISAC_AT := Vector2(470.0, -560.0)       # a point in the wings
const FLISAC_PODIUM_AT := Vector2(440.0, -562.0)  # a point in the low block
const FLISAC_CORNER := Vector2(451.3, -582.9)   # the chamfer's middle
const FLISAC_TAMKA := Vector2(421.0, -569.0)    # the Tamka front's middle
const FLISAC_WYBRZEZE := Vector2(475.0, -560.0) # the Wybrzeże front's middle
const FLISAC_STONE := Color("#e9e6df")
const FLISAC_STONE_UP := Color("#dcd8d0")
const FLISAC_GOLD := Color("#d9a83a")    # the courtyard side's fin screen
const FLISAC_PIER := Color("#c9c1b1")
const FLISAC_FRAME := Color("#33363a")
const FLISAC_GLASS := Color("#43505b")
const FLISAC_SHOP := Color("#2f3a42")
const FLISAC_COPPER := Color("#b9733f")
const FLISAC_COPING := Color("#3d4044")
const FLISAC_GREEN := Color("#7b9a55")
const FLISAC_PALE := Color("#a9bcc4")
const FLISAC_GROUND := 4.6
const FLISAC_FLOOR := 3.2
const FLISAC_FLOORS := 5
const FLISAC_BAY := 3.6
const FLISAC_SETBACK := 3.6
const FLISAC_PODIUM := 7.6


func _find_flisac() -> void:
	var main := _tallest_at(FLISAC_AT)
	if main.size() < 3 or absf(_area(main)) < 400.0:
		return
	var low := _tallest_at(FLISAC_PODIUM_AT)
	var zone: Array = [main]
	if low.size() >= 3:
		zone.append(low)
	_add_site("flisac", zone)
	if not sites.is_empty() and sites[-1]["key"] == "flisac":
		sites[-1]["ring"] = _simplify(main, 0.9)
		sites[-1]["podium"] = _simplify(low, 0.5) if low.size() >= 3 else PackedVector2Array()


## The edge of `ring` whose middle is nearest `at`.
func _edge_near(ring: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var d := INF
	for i in ring.size():
		var m := (ring[i] + ring[(i + 1) % ring.size()]) * 0.5
		if m.distance_to(at) < d:
			d = m.distance_to(at)
			best = i
	return best


## A flat panel on a wall: along-wall metres u0..u1 from `a` (direction `d`), absolute heights
## y0..y1, standing `off` metres out of the wall plane (`run`: the wall's distance along the facade).
func _fl_quad(a: Vector2, d: Vector2, n: Vector2, run: float, u0: float, u1: float, y0: float, y1: float,
		off: float, col: Color, mode: float) -> void:
	if u1 <= u0 or y1 <= y0:
		return
	var p0 := a + d * u0 + n * off
	var p1 := a + d * u1 + n * off
	var keep := _mode
	_mode = mode
	_quad(Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(p1.x, y1, p1.y), Vector3(p0.x, y1, p0.y),
			Vector3(n.x, 0.0, n.y), col, Vector2(run + u0, y0 - _g), Vector2(run + u1, y0 - _g),
			Vector2(run + u1, y1 - _g), Vector2(run + u0, y1 - _g), y1 - _g)
	_mode = keep


## The windows of a stack of floors along every edge of `ring`: a dark frame, a pane lit by chance
## at night, and now and then a copper blind or a loggia (a deep dark opening with a glass rail).
func _fl_windows(ring: PackedVector2Array, y_first: float, floors: int, floor_h: float, sill: float, win_h: float,
		win_w: float, loggias: bool) -> void:
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		if len >= 4.5:
			var n := _out(ring, a, b)
			var d := (b - a) / len
			var bays := maxi(1, roundi(len / FLISAC_BAY))
			var step := len / float(bays)
			for k in bays:
				var uc := (float(k) + 0.5) * step
				for f in floors:
					var y0 := y_first + f * floor_h + sill
					var r := fposmod(sin(float(i * 131 + k * 17 + f * 31) * 12.9898) * 43758.5453, 1.0)
					var half := win_w * 0.5
					if loggias and r < 0.14:
						_fl_quad(a, d, n, run, uc - half - 0.3, uc + half + 0.3, y0 - 0.1, y0 + win_h + 0.1, 0.03, FLISAC_FRAME.darkened(0.3), M_STONE)
						_fl_quad(a, d, n, run, uc - half - 0.15, uc + half + 0.15, y0 + 1.0, y0 + win_h, 0.06, FLISAC_FRAME, _pane_at(run + uc, y0))
						_fl_quad(a, d, n, run, uc - half - 0.3, uc + half + 0.3, y0 - 0.1, y0 + 1.0, 0.12, FLISAC_PALE, M_STONE)
						continue
					_fl_quad(a, d, n, run, uc - half - 0.08, uc + half + 0.08, y0 - 0.08, y0 + win_h + 0.08, 0.03, FLISAC_FRAME, M_STONE)
					_fl_quad(a, d, n, run, uc - half, uc + half, y0, y0 + win_h, 0.06, FLISAC_GLASS, _pane_at(run + uc, y0))
					if r > 0.8:
						_fl_quad(a, d, n, run, uc - half, uc + half, y0 + win_h * 0.45, y0 + win_h, 0.09, FLISAC_COPPER, M_STONE)
		run += len


## The ground floor: dark shop glass between the stone piers, a dark fascia over it.
func _fl_shops(ring: PackedVector2Array, g: float) -> void:
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		if len >= 4.5:
			var n := _out(ring, a, b)
			var d := (b - a) / len
			var bays := maxi(1, roundi(len / FLISAC_BAY))
			var step := len / float(bays)
			for k in bays:
				var uc := (float(k) + 0.5) * step
				var half := step * 0.5 - 0.62
				_fl_quad(a, d, n, run, uc - half - 0.06, uc + half + 0.06, g + 0.28, g + 4.0, 0.03, FLISAC_FRAME, M_STONE)
				_fl_quad(a, d, n, run, uc - half, uc + half, g + 0.35, g + 3.92, 0.06, FLISAC_SHOP, _pane_at(run + uc, g))
			_fl_quad(a, d, n, run, 0.0, len, g + 4.0, g + 4.6, 0.05, FLISAC_COPING, M_STONE)
		run += len


func _build_flisac(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	if ring.size() < 3:
		return
	_o = Vector2.ZERO
	_a = Vector2(1, 0)
	_b = Vector2(0, 1)
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var top1 := g + FLISAC_GROUND + FLISAC_FLOORS * FLISAC_FLOOR
	var top2 := top1 + 0.4 + 3.1
	var top3 := top2 + 0.4 + 3.1
	# the wings: stone walls, a dark coping, the roof terrace green, a glass balustrade round it
	_prism(ring, g - 1.5, top1 - 0.15, FLISAC_STONE, none, M_STONE, M_STONE)
	for q: PackedVector2Array in Geometry2D.offset_polygon(ring, 0.1, Geometry2D.JOIN_MITER):
		_prism(q, top1 - 0.15, top1 + 0.35, FLISAC_COPING, FLISAC_GREEN, M_STONE, M_STONE)
	_fl_shops(ring, g)
	_fl_windows(ring, g + FLISAC_GROUND, FLISAC_FLOORS, FLISAC_FLOOR, 0.55, 2.4, 2.45, true)
	_flisac_fins(ring, site["podium"], g + FLISAC_GROUND + 0.25, top1 - 0.15, g + FLISAC_PODIUM + 0.25)
	for q: PackedVector2Array in Geometry2D.offset_polygon(ring, -0.5, Geometry2D.JOIN_MITER):
		_prism(q, top1 + 0.35, top1 + 1.35, FLISAC_PALE, none, M_STONE, M_STONE)
	# two stepped floors over the five full ones: a set-back floor with a green roof all round, then
	# a smaller second step that stays clear of the corner, so the corner keeps a big terrace
	var inset := Geometry2D.offset_polygon(ring, -FLISAC_SETBACK, Geometry2D.JOIN_MITER)
	var corner := PackedVector2Array()
	for k in 8:
		corner.append(FLISAC_CORNER + Vector2.from_angle(TAU * k / 8.0) * 17.0)
	for q: PackedVector2Array in inset:
		if q.size() < 3 or absf(_area(q)) < 60.0 or Geometry2D.is_polygon_clockwise(q):
			continue
		var upper := _simplify(q, 0.5)
		_prism(upper, top1 + 0.35, top2 - 0.2, FLISAC_STONE_UP, none, M_STONE, M_STONE)
		for c: PackedVector2Array in Geometry2D.offset_polygon(upper, 0.1, Geometry2D.JOIN_MITER):
			_prism(c, top2 - 0.2, top2 + 0.3, FLISAC_COPING, FLISAC_GREEN, M_STONE, M_STONE)
		_fl_windows(upper, top1 + 0.35, 1, 3.1, 0.3, 2.5, 2.6, false)
		_collide(upper)
		for s2: PackedVector2Array in Geometry2D.offset_polygon(upper, -2.4, Geometry2D.JOIN_MITER):
			if s2.size() < 3 or Geometry2D.is_polygon_clockwise(s2):
				continue
			for top: PackedVector2Array in Geometry2D.clip_polygons(s2, corner):
				if top.size() < 3 or absf(_area(top)) < 50.0 or Geometry2D.is_polygon_clockwise(top):
					continue
				var step := _simplify(top, 0.5)
				_prism(step, top2 + 0.3, top3 - 0.2, FLISAC_STONE_UP, none, M_STONE, M_STONE)
				for c: PackedVector2Array in Geometry2D.offset_polygon(step, 0.1, Geometry2D.JOIN_MITER):
					_prism(c, top3 - 0.2, top3 + 0.3, FLISAC_COPING, FLISAC_GREEN, M_STONE, M_STONE)
				_fl_windows(step, top2 + 0.3, 1, 3.1, 0.3, 2.5, 2.6, false)
				_flisac_roof(step, top3 + 0.3)
				_collide(step)
	# the low block in the elbow: a garden podium
	var low: PackedVector2Array = site["podium"]
	if low.size() >= 3:
		_prism(low, g - 1.5, g + FLISAC_PODIUM - 0.3, FLISAC_STONE_UP, none, M_STONE, M_STONE)
		for c: PackedVector2Array in Geometry2D.offset_polygon(low, 0.1, Geometry2D.JOIN_MITER):
			_prism(c, g + FLISAC_PODIUM - 0.3, g + FLISAC_PODIUM + 0.2, FLISAC_COPING, FLISAC_GREEN.darkened(0.08), M_STONE, M_STONE)
		_fl_windows(low, g + 0.6, 2, 3.4, 0.6, 2.2, 2.3, false)
	_flisac_corner(ring, g)
	_collide(ring)
	if low.size() >= 3:
		_collide(low)


## The courtyard side's gold fin screen: a deep gold fin between every bay on the walls that face
## into the V (the street fronts stay white), up the five full floors.
func _flisac_fins(ring: PackedVector2Array, low: PackedVector2Array, y0: float, y1: float, y_low: float) -> void:
	var near_low := Geometry2D.offset_polygon(low, 1.0, Geometry2D.JOIN_MITER) if low.size() >= 3 else []
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		if len < 4.5:
			continue
		var n := _out(ring, a, b)
		var m := (a + b) * 0.5
		if n.dot(FLISAC_PODIUM_AT - m) <= 0.0 or m.distance_to(FLISAC_PODIUM_AT) > 45.0:
			continue
		var d := (b - a) / len
		var bays := maxi(1, roundi(len / FLISAC_BAY))
		var step := len / float(bays)
		for k in range(1, bays):
			var p := a + d * (step * k)
			var y := y0
			for q: PackedVector2Array in near_low:
				if Geometry2D.is_point_in_polygon(p + n * 0.4, q):
					y = y_low
			_prism(PackedVector2Array([p - d * 0.12 - n * 0.05, p + d * 0.12 - n * 0.05, p + d * 0.12 + n * 0.75, p - d * 0.12 + n * 0.75]),
					y, y1, FLISAC_GOLD, FLISAC_GOLD, M_STONE, M_STONE)


## The corner café and the shops' names: a white canopy on posts over the terrace on the chamfer,
## hedges along the Tamka front, and the parody names in neon on the fascia.
func _flisac_corner(ring: PackedVector2Array, g: float) -> void:
	var none := Color(0, 0, 0, 0)
	var e := _edge_near(ring, FLISAC_CORNER)
	var a := ring[e]
	var b := ring[(e + 1) % ring.size()]
	var len := a.distance_to(b)
	var n := _out(ring, a, b)
	var d := (b - a) / len
	var mid := len * 0.5
	var span := minf(len * 0.5 - 1.0, 5.5)
	var canopy := PackedVector2Array([a + d * (mid - span) + n * 0.4, a + d * (mid + span) + n * 0.4,
			a + d * (mid + span) + n * 4.0, a + d * (mid - span) + n * 4.0])
	_prism(canopy, g + 3.15, g + 3.45, Color("#ebe7dd"), Color("#f4f1e8"), M_STONE, M_STONE)
	for u: float in [-span + 0.2, span - 0.2]:
		_prism(PackedVector2Array([a + d * (mid + u) + n * 3.8, a + d * (mid + u + 0.12) + n * 3.8,
				a + d * (mid + u + 0.12) + n * 3.92, a + d * (mid + u) + n * 3.92]), g, g + 3.15, FLISAC_FRAME, none, M_STONE, M_STONE)
	# the terrace's low glass screen and the tables' dark tops under the canopy
	_prism(PackedVector2Array([a + d * (mid - span) + n * 4.0, a + d * (mid + span) + n * 4.0,
			a + d * (mid + span) + n * 4.06, a + d * (mid - span) + n * 4.06]), g + 0.1, g + 1.2, FLISAC_PALE, none, M_STONE, M_STONE)
	for k in 4:
		var c := a + d * (mid - span + 1.6 + k * 2.5) + n * 2.3
		_prism(PackedVector2Array([c + Vector2(-0.4, -0.4), c + Vector2(0.4, -0.4), c + Vector2(0.4, 0.4), c + Vector2(-0.4, 0.4)]),
				g, g + 0.78, Color("#3a3c40"), Color("#3a3c40"), M_STONE, M_STONE)
	# hedges: low green boxes along the Tamka front's foot
	var t := _edge_near(ring, FLISAC_TAMKA)
	var ta := ring[t]
	var tb := ring[(t + 1) % ring.size()]
	var tl := ta.distance_to(tb)
	var tn := _out(ring, ta, tb)
	var td := (tb - ta) / tl
	for k in int(tl / 6.0):
		var u := 3.0 + 6.0 * k
		if u + 4.0 > tl:
			break
		_prism(PackedVector2Array([ta + td * u + tn * 0.5, ta + td * (u + 4.0) + tn * 0.5, ta + td * (u + 4.0) + tn * 1.5, ta + td * u + tn * 1.5]),
				g, g + 0.9, Color("#5d8344"), Color("#6f9a4f"), M_STONE, M_STONE)
	# the shops' names: a coffee place at the corner, a grocer's further along Tamka, a wine shop on Wybrzeże
	var tn3 := Vector3(tn.x, 0.0, tn.y)
	var at := ta + td * (tl - 8.0) + tn * 0.05
	signs.append(["KAWOBIURKO", Vector3(at.x, g + 4.02, at.y), tn3, 0.26, Color(1.0, 0.95, 0.85)])
	var at2 := ta + td * (tl - 23.0) + tn * 0.05
	signs.append(["KAROLEK", Vector3(at2.x, g + 4.02, at2.y), tn3, 0.26, Color(0.2, 0.45, 1.0)])
	var w := _edge_near(ring, FLISAC_WYBRZEZE)
	var wa := ring[w]
	var wb := ring[(w + 1) % ring.size()]
	var wl := wa.distance_to(wb)
	var wn := _out(ring, wa, wb)
	var wd := (wb - wa) / wl
	var at3 := wa + wd * (wl * 0.5) + wn * 0.05
	signs.append(["WINOSTORY", Vector3(at3.x, g + 4.02, at3.y), Vector3(wn.x, 0.0, wn.y), 0.26, Color(1.0, 0.25, 0.25)])


## The green roof on the top floor: a lift core and air-conditioning boxes, planters of grass, and
## a glass-roofed pergola along the longest edge on posts.
func _flisac_roof(ring: PackedVector2Array, y: float) -> void:
	var none := Color(0, 0, 0, 0)
	var longest := 0
	for i in ring.size():
		if ring[i].distance_to(ring[(i + 1) % ring.size()]) > ring[longest].distance_to(ring[(longest + 1) % ring.size()]):
			longest = i
	var a := ring[longest]
	var b := ring[(longest + 1) % ring.size()]
	var len := a.distance_to(b)
	if len < 12.0:
		return
	var n := _out(ring, a, b)
	var d := (b - a) / len
	# the pergola: posts every 3.6 m, a glass roof
	var posts := int((len - 4.0) / 3.6)
	for k in posts + 1:
		var c := a + d * (2.0 + 3.6 * k) - n * 1.4
		for off: float in [0.0, -1.8]:
			var p := c + n * off
			_prism(PackedVector2Array([p + Vector2(-0.09, -0.09), p + Vector2(0.09, -0.09), p + Vector2(0.09, 0.09), p + Vector2(-0.09, 0.09)]),
					y, y + 2.9, FLISAC_FRAME, FLISAC_FRAME, M_STONE, M_STONE)
	_prism(PackedVector2Array([a + d * 1.8 - n * 0.4, a + d * (2.2 + 3.6 * posts) - n * 0.4, a + d * (2.2 + 3.6 * posts) - n * 3.4, a + d * 1.8 - n * 3.4]),
			y + 2.9, y + 3.02, FLISAC_PALE, FLISAC_PALE, M_STONE, M_STONE)
	# planters of grass behind it, dark green with pale tufts
	for k in int(len / 5.0):
		var p := a + d * (3.0 + 5.0 * k) - n * 4.3
		var q := PackedVector2Array([p, p + d * 2.4, p + d * 2.4 - n * 0.9, p - n * 0.9])
		_prism(q, y, y + 0.8, Color("#5f7a49"), Color("#a5ab62"), M_STONE, M_STONE)
	# the lift core and two air-conditioning boxes
	var c := (a + b) * 0.5 - n * 6.0
	_prism(PackedVector2Array([c + d * 3.0 - n * 2.0, c + d * 3.0 + n * 2.0, c - d * 3.0 + n * 2.0, c - d * 3.0 - n * 2.0]),
			y, y + 3.4, Color("#35383c"), Color("#4a4d52"), M_STONE, M_STONE)
	for k in 2:
		var p := c + d * (6.0 + 1.8 * k)
		_prism(PackedVector2Array([p + Vector2(-0.6, -0.6), p + Vector2(0.6, -0.6), p + Vector2(0.6, 0.6), p + Vector2(-0.6, 0.6)]),
				y, y + 1.1, Color("#51555a"), Color("#6b6f73"), M_STONE, M_STONE)


# --- Biblioteka Uniwersytecka (BUW) -------------------------------------------------------------

## The University Library on Dobra (Budzyński and Badowski, 1999; spec
## docs/landmarks/specs/buw.md, 2026-10-31): a glass block the size of its outline under the
## roof garden (2002), which OpenStreetMap maps lawn by lawn; on Dobra a screen of green copper
## plates covered in lines of old text, the entrance under two of them and four philosophers on
## columns before it; the other fronts glass behind a patina-green trellis. In the garden: the
## long glass roof over the central hall (the bare band between the mapped lawns) with its
## trusses, a second glass roof, two round lights and three copper roof houses (mapped parts).
## The cassette of the first ten minutes lies on the garden: the only flat roof here.
## Pass 3 (the Mac's LoD2, 2026-11-01): the deck at 15 m (OpenStreetMap's 10.9 is the court's
## height), the glass ridges about 17 m; the court in the south notch is the 10 m roof of
## Collegium Iuridicum II, built here as a lower garden with its own skylight.
const BUW_ROOF := 15.0                  # GUGiK LoD2: 64 % of the roof at ~15 m
const BUW_COURT := 10.0                 # LoD2's lower part, the notch's court
const BUW_FRONT := Vector2(-15.1, -965.9)  # the outline's west corner, where Dobra's plates start
const BUW_FRONT_AXIS := Vector2(0.667, 0.745)  # along Dobra, to the south-east
const BUW_HALL := Vector2(59.8, -953.95)  # the long glass roof's centre (the bare band)
const BUW_HALL_AXIS := Vector2(0.8916, -0.4529)
const BUW_HALL_SIZE := Vector2(28.2, 11.9)  # half sizes along and across
## From GUGiK's orthophoto (the Mac, 2026-11-01), in map metres: the glass field over the
## central hall (the OSM band between the lawns) and its tail sweeping along the Dobra side down
## to the south corner by the entrance; the walkway across it; the formal garden's round plaza;
## the mound round the small glass pyramid (OSM's 6 m part); the white pavilions.
const BUW_FIELD := [Vector2(7.0, -980.0), Vector2(19.0, -982.0), Vector2(33.6, -958.7), Vector2(81.0, -977.6),
		Vector2(88.8, -955.5), Vector2(39.6, -935.5), Vector2(45.0, -914.0), Vector2(40.5, -914.5),
		Vector2(35.0, -925.5), Vector2(23.8, -940.0), Vector2(14.5, -958.0)]
## the walkways over the glass: the long one from the field's west corner across to the
## pavilions by the tail, a short one over the tail by the stair house
const BUW_WALKS := [[Vector2(33.6, -958.7), Vector2(42.4, -933.5)], [Vector2(23.3, -973.0), Vector2(15.5, -952.7)]]
const BUW_PLAZA := Vector3(54.5, -989.0, 4.5)  # x, z, radius
## the hill between the glass field and the oculus: centre, half sizes across and along the
## field's short side (BUW_HALL_AXIS, its normal); the glass pyramid (a mapped part) on its top
const BUW_MOUND := Vector2(99.8, -953.0)
const BUW_MOUND_SIZE := Vector2(11.0, 17.0)
## white pavilions: x, z, half width (along BUW_HALL_AXIS), half length (across it)
const BUW_PAVILIONS := [Vector4(44.6, -927.9, 2.2, 3.6), Vector4(51.5, -933.0, 2.2, 2.8),
		Vector4(58.9, -936.0, 1.8, 2.0), Vector4(89.2, -951.0, 2.0, 3.0), Vector4(108.8, -960.0, 2.0, 3.0)]
## the small white domes on brown rings along the south lawn
const BUW_DOMES := [Vector2(64.4, -936.4), Vector2(70.2, -940.3), Vector2(77.5, -943.0), Vector2(84.1, -946.5)]
## the south garden's paths (2.5 m, the deck's paving between the beds): the main one from the
## oculus's ring west along the notch to the south-west corner, a loop round the notch's
## corner, one up to the field's east corner, one round the pavilions
const BUW_PATHS := [
	[Vector2(113.0, -942.5), Vector2(104.0, -944.5), Vector2(97.0, -943.5), Vector2(90.0, -940.5), Vector2(82.0, -938.0),
			Vector2(74.5, -935.5), Vector2(68.0, -932.5), Vector2(62.0, -928.0), Vector2(55.5, -925.0), Vector2(51.5, -921.0),
			Vector2(51.5, -915.5)],
	[Vector2(97.0, -943.5), Vector2(99.5, -936.0), Vector2(103.0, -930.0), Vector2(109.0, -927.5), Vector2(116.5, -931.0),
			Vector2(119.0, -937.5)],
	[Vector2(86.0, -939.0), Vector2(87.5, -944.5), Vector2(92.0, -948.0)],
	[Vector2(62.0, -928.0), Vector2(56.5, -929.0), Vector2(48.5, -937.0), Vector2(44.5, -941.5)],
]
const BUW_PATH_W := 2.5
const BUW_RING_W := 4.0      # the paved ring round the oculus
## the south notch over the court: the band is narrower and greener there (the Mac's check)
const BUW_NOTCH := [Vector2(56.0, -921.0), Vector2(93.5, -941.0), Vector2(101.5, -925.0), Vector2(107.0, -913.0),
		Vector2(79.0, -898.5), Vector2(64.0, -906.0)]
const BUW_NOTCH_W := 3.0
const BUW_NOTCH_BAND := Color("#4f9068")
const BUW_SHRUB := Color("#3f5e36")
const BUW_HEATHER := Color("#7b5d6a")
const BUW_HILL := Color("#456f3a")
const BUW_EARTH := Color("#7a5a44")
const BUW_FLOWERS := [Color("#d9c23e"), Color("#d9873a"), Color("#b8343f"), Color("#8b4f9e"), Color("#e07ba0")]
const BUW_WHITE := Color("#e2e0d6")
const BUW_BAND_W := 6.0     # the sloped band round the roof's edge: its width
const BUW_BAND_DROP := 2.5  # and how far under the roof its outer edge (the walls' top) is
const BUW_BAND := Color("#5f9f86")  # the vault's green glass
const BUW_PAVING := Color("#c9c4b4")
const BUW_DARK := Color("#2f3a38")
const BUW_LIGHT := Vector2(108.5, -979.3)  # a point in the second glass roof's mapped part
const BUW_GLASS := Color("#4f7f74")  # behind the copper: dark green glass (F's photos)
const BUW_COPPER := Color("#5a9a80")  # F's photos: a richer verdigris
const BUW_INK := Color("#3e6252")
const BUW_PATINA := Color("#557f6b")
const BUW_DECK := Color("#a9a799")
const BUW_PARK := Color("#5f8f4a")
const BUW_LAWN := Color("#78a85a")
const BUW_SKY := Color("#7fae9c")  # the glass roofs: green (F's photos)
const BUW_TRUSS := Color("#4c7563")
const BUW_DOOR := Color("#34423f")
const BUW_COLUMN := Color("#cfc9b8")
const BUW_BRONZE := Color("#4a4239")
## F's photos (2026-11-13): the fronts, the vault, the pink tower, the drums and the lower garden.
const BUW_COPPER_END := 76.5    # the copper screen along Dobra, metres from BUW_FRONT
const BUW_ATRIUM_END := 92.0    # the tall glass hall past it, to the white south block
const BUW_FRIEZE := 10.8        # the frieze's underside over the ground
const BUW_PAGE_PITCH := 6.375   # twelve copper pages under it
const BUW_PAGE_HALF := 2.2
const BUW_HALL_GLASS := Color("#6b9fb0")
const BUW_WALL := Color("#dad8cf")    # the off-white concrete of the other fronts
const BUW_BAY := 4.4
const BUW_FRAME := Color("#2f7a6c")   # the windows' teal frames
const BUW_PANE := Color("#3c5f60")
const BUW_IVY := [Color("#3e6233"), Color("#4b7139"), Color("#35562d"), Color("#56803f")]
const BUW_IVY_RED := Color("#7c3b2c")
const BUW_VAULT_STEPS := 4
const BUW_RIB := 2.6               # the vault's ribs apart
const BUW_RIB_COL := Color("#2e5c4a")
const BUW_RAIL := Color("#a9c9b4")     # the walkways' pale green mesh railings
const BUW_RAIL_TOP := Color("#7fa892")
const BUW_BENCH := Color("#355a45")
const BUW_DOME := Color("#a9bdb8")     # the ribbed glass dome, silver-green
const BUW_DOME_RISE := 0.72
const BUW_PINK := Color("#c34dc0")     # OSM's colour of the tower's parts
const BUW_PINK_AT := Vector2(55.0, -893.0)
const BUW_PINK_H := 11.6
const BUW_PINK_STOREY := 2.9
const BUW_DRUM_R := 1.5
const BUW_DRUM_UP := 3.0               # the drums' tops over the deck
const BUW_CONCRETE := Color("#bcb9b0")
const BUW_SLIT := Color("#3b3e3d")
const BUW_LOOKOUT := Vector2(153.34, -955.89)  # the drum by the round east corner, people on its top
const BUW_CASCADE := Vector2(70.0, -1024.5)    # the first step of the cascade by the north tip
const BUW_CASCADE_DIR := Vector2(-0.55, -0.83) # down into the stream's end
const BUW_WATER := Color("#4d7f86")
const BUW_POOL := Vector2(45.0, -1022.0)
const BUW_POOL_R := 2.6
const BUW_STEEL := Color("#8d9693")
const BUW_PANEL := Color("#3f4f5c")
## the steel trees: x, z, trunk height
const BUW_STEEL_TREES := [Vector3(35.0, -1016.0, 5.0), Vector3(52.0, -1027.0, 5.6), Vector3(39.0, -1025.0, 4.6)]
## the lower garden's flower beds: x, z, radius
const BUW_LOW_BEDS := [Vector3(30.0, -1013.0, 1.6), Vector3(49.5, -1018.0, 1.3), Vector3(42.0, -1027.0, 1.2)]
## Collegium Iuridicum IV, Wybrzeże Kościuszkowskie 47 (F's photos): the grey villa with the glass spire.
const CI4_NAME := "Wydział Prawa i Administracji UW. Collegium Iuridicum IV"
const CI4_EAVE := 10.8
const CI4_ROOF := 2.6
const CI4_TOWER := 15.0
const CI4_SPIRE_H := 11.5   # the glass spire over the tower's cornice
const CI4_RIVER := Vector2(0.745, -0.667)  # towards Wybrzeże Kościuszkowskie
const CI4_RENDER := Color("#8e9293")
const CI4_STONE := Color("#dcd8ce")
const CI4_GLASS := Color("#2d3537")
const CI4_ROOF_COL := Color("#6f777b")
const CI4_SPIRE := Color("#a7c2bb")


func _find_buw() -> void:
	var outline := _landmark("Biblioteka Uniwersytecka")
	if outline.size() < 3:
		return
	# the court in the south notch: Collegium Iuridicum II's roof, part of the library's garden
	var court := PackedVector2Array()
	# F's photos (2026-11-13): the pink tower's parts by the south corner, Collegium Iuridicum IV
	# (no. 47) by the north end and the drums standing just outside the north front
	var pink_pts := PackedVector2Array()
	var ci4 := PackedVector2Array()
	var outer_vents: Array[Vector3] = []
	var box := _box_of([outline])
	for bld in data["buildings"]:
		var nm: String = bld.get("name", "")
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		if nm == "Collegium Iuridicum II":
			court = q
		elif nm == CI4_NAME:
			ci4 = q
		elif String(bld.get("c", "")).to_upper() == "#C34DC0":
			if _centre(q).distance_to(BUW_PINK_AT) < 12.0:
				pink_pts.append_array(q)
		elif q.size() >= 10 and absf(_area(q)) < 10.0 and box.has_point(_centre(q)) \
				and not Geometry2D.is_point_in_polygon(_centre(q), outline) and _dist_to_ring(_centre(q), outline) < 4.0:
			var c := _centre(q)
			outer_vents.append(Vector3(c.x, c.y, sqrt(absf(_area(q)) / PI)))
	var pink := _hull(Geometry2D.convex_hull(pink_pts)) if pink_pts.size() >= 3 else PackedVector2Array()
	var zone: Array = [outline]
	for z: PackedVector2Array in [court, pink, ci4]:
		if z.size() >= 3:
			zone.append(z)
	for v: Vector3 in outer_vents:
		zone.append(_circle(Vector2(v.x, v.y), v.z + 0.4, 8))
	_add_site("buw", zone)
	if sites.is_empty() or sites[-1]["key"] != "buw":
		return
	var site: Dictionary = sites[-1]
	site["ring"] = outline
	site["court"] = court
	site["pink"] = pink
	site["ci4"] = ci4
	var houses: Array[Dictionary] = []
	var rounds: Array[Vector3] = []  # x, z, radius
	var vents: Array[Vector3] = []
	for bld in _parts_in(outline, func(b2: Dictionary) -> bool: return float(b2["h"]) > float(b2["mh"])):
		var q := _pts(bld["p"])
		var area := absf(_area(q))
		if float(bld["h"]) >= 13.5 or (q.size() == 4 and area < 60.0):
			houses.append(bld)  # the long roof house, the stair head (14 m), the lift head
		elif q.size() >= 19 and area < 300.0:
			var c := _centre(q)
			rounds.append(Vector3(c.x, c.y, sqrt(area / PI)))
		elif q.size() >= 10 and area < 25.0:
			var c := _centre(q)
			vents.append(Vector3(c.x, c.y, sqrt(area / PI)))  # the round ventilators on the band
		elif Geometry2D.is_point_in_polygon(BUW_LIGHT, q):
			site["light"] = q
	site["houses"] = houses
	site["rounds"] = rounds
	vents.append_array(outer_vents)
	site["vents"] = vents
	if houses.is_empty() or rounds.is_empty():
		# The streamed city has the parts only from index.json's site_parts: an index split
		# before the library joined bake_sectors.py's SITE_NAMES lacks them.
		push_warning("landmarks: the University Library's roof parts are missing (houses %d, rounds %d): re-split the map, python3 -I tools/bake_sectors.py" % [houses.size(), rounds.size()])
	site["beds"] = _buw_beds(site)


## The roof garden's footways (F, 2026-11-13: people walking up there): a mapped footway wholly
## on the deck (inside the library's outline, clear of the vault round its edge and off the glass
## field) is walked BUW_ROOF m up (pedestrians.gd through map_builder.gd `footway_lift`).
static func garden_lift(line: PackedVector2Array, outline: PackedVector2Array) -> float:
	if outline.size() < 3 or line.size() < 2:
		return 0.0
	var field := PackedVector2Array(BUW_FIELD)
	for p in line:
		if not Geometry2D.is_point_in_polygon(p, outline) or Geometry2D.is_point_in_polygon(p, field):
			return 0.0
		for i in outline.size():
			var q := Geometry2D.get_closest_point_to_segment(p, outline[i], outline[(i + 1) % outline.size()])
			if p.distance_to(q) < BUW_BAND_W - 0.5:
				return 0.0
	return BUW_ROOF


## The roof garden's beds (found once, not per sector): every mapped park or lawn on the roof,
## biggest first, each clipped to the roof and kept off the glass roofs, the round lights, the
## roof houses and the beds before it. A cut that would leave a hole (a light inside a lawn)
## splits the piece through the hole first: a hole can't be drawn, and the two would overlap.
func _buw_beds(site: Dictionary) -> Array:
	var ring := _simplify(site["ring"], 0.8)
	# inside the sloped band round the edge
	var inner := _largest(Geometry2D.offset_polygon(ring, -BUW_BAND_W))
	var keep_off: Array[PackedVector2Array] = []
	keep_off.append(_grow(PackedVector2Array(BUW_FIELD), 0.5))
	keep_off.append(_buw_ellipse(1.0, 16))
	for pv: Vector4 in BUW_PAVILIONS:
		keep_off.append(_grow(_buw_pavilion(pv), 0.6))
	for d: Vector2 in BUW_DOMES:
		keep_off.append(_circle(d, 2.8, 8))
	# the south garden's paths: the deck shows between the beds they split
	for line: Array in BUW_PATHS:
		for piece in Geometry2D.offset_polyline(PackedVector2Array(line), BUW_PATH_W * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
			if not Geometry2D.is_polygon_clockwise(piece):
				keep_off.append(_simplify(piece, 0.3))
	# the formal garden (its own grid of square beds, below) and its round plaza
	var formal := _buw_formal(inner)
	var beds: Array = []
	for f in formal:
		keep_off.append(f)
	beds.append_array(_buw_formal_beds(formal, keep_off))
	var light: PackedVector2Array = site.get("light", PackedVector2Array())
	if light.size() >= 3:
		keep_off.append(light)
	for r: Vector3 in site["rounds"]:
		keep_off.append(_circle(Vector2(r.x, r.y), r.z + (BUW_RING_W + 0.3 if r.z > 6.0 else 2.7), 16))
	for h: Dictionary in site["houses"]:
		keep_off.append(_pts(h["p"]))
	var areas: Array = []
	var box := _box_of([ring])
	for ar in data.get("areas", []):
		var k: String = ar.get("k", "")
		if k != "park" and k != "grass":
			continue
		var q := _pts(ar["p"])
		if q.size() >= 3 and box.intersects(_box_of([q])):
			areas.append([absf(_area(q)), q, BUW_PARK if k == "park" else BUW_LAWN])
	areas.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	var drawn: Array[PackedVector2Array] = keep_off.duplicate()
	for ar: Array in areas:
		for piece in Geometry2D.intersect_polygons(ar[1], inner):
			if Geometry2D.is_polygon_clockwise(piece):
				continue
			var parts: Array[PackedVector2Array] = [piece]
			for d: PackedVector2Array in drawn:
				var next: Array[PackedVector2Array] = []
				for p in parts:
					next.append_array(_clip_whole(p, d))
				parts = next
			for p in parts:
				if absf(_area(p)) < 6.0:
					continue
				var bed := _simplify(p, 0.4)
				if bed.size() >= 3:
					beds.append([bed, _buw_bed_colour(bed, ar[2])])
					drawn.append(p)
	return beds


## The south half's beds (south of the glass field and the hill, the orthophoto): dark shrubs,
## purple-brown heather or lawn, by a steady hash of the bed's centre; the rest keep the map's.
func _buw_bed_colour(bed: PackedVector2Array, mapped: Color) -> Color:
	var c := _centre(bed)
	var b := Vector2(-BUW_HALL_AXIS.y, BUW_HALL_AXIS.x)
	if (c - BUW_HALL).dot(b) < BUW_HALL_SIZE.y + 2.0 or c.x > 118.0:
		return mapped
	var h := _buw_hash(roundf(c.x), roundf(c.y))
	return BUW_SHRUB if h < 0.34 else (BUW_HEATHER if h < 0.67 else BUW_LAWN)


## The hill's outline grown by `by` (an ellipse in the field's frame).
func _buw_ellipse(by: float, n: int) -> PackedVector2Array:
	var a := BUW_HALL_AXIS
	var b := Vector2(-a.y, a.x)
	var out := PackedVector2Array()
	for k in n:
		var t := TAU * float(k) / float(n)
		out.append(BUW_MOUND + a * cos(t) * BUW_MOUND_SIZE.x * by + b * sin(t) * BUW_MOUND_SIZE.y * by)
	return out


## A pavilion's plan: a rectangle along the field's frame.
func _buw_pavilion(v: Vector4) -> PackedVector2Array:
	var a := BUW_HALL_AXIS
	var b := Vector2(-a.y, a.x)
	var c := Vector2(v.x, v.y)
	return PackedVector2Array([c - a * v.z - b * v.w, c + a * v.z - b * v.w, c + a * v.z + b * v.w, c - a * v.z + b * v.w])


## The formal north part of the garden (the orthophoto): between the glass field's north-west
## side and the band, along the field; in the field's own frame.
func _buw_formal(inner: PackedVector2Array) -> Array[PackedVector2Array]:
	var a := BUW_HALL_AXIS
	var b := Vector2(-a.y, a.x)
	var hv := BUW_HALL_SIZE.y
	var c := BUW_HALL
	var box := PackedVector2Array([c + a * -26.0 + b * (-hv - 28.0), c + a * 25.0 + b * (-hv - 28.0),
			c + a * 25.0 + b * (-hv - 1.5), c + a * -26.0 + b * (-hv - 1.5)])
	var out: Array[PackedVector2Array] = []
	for piece in Geometry2D.intersect_polygons(box, inner):
		if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
			out.append(piece)
	return out


## The formal garden's beds: 5 m squares on a 6.6 m grid of light paths along the glass field,
## about one in three in yellow or orange flowers, round the paved plaza with a flower ring.
func _buw_formal_beds(formal: Array[PackedVector2Array], keep_off: Array[PackedVector2Array]) -> Array:
	var a := BUW_HALL_AXIS
	var b := Vector2(-a.y, a.x)
	var plaza := Vector2(BUW_PLAZA.x, BUW_PLAZA.y)
	var off: Array[PackedVector2Array] = []
	for k in keep_off:
		if not formal.has(k):
			off.append(k)
	off.append(_circle(plaza, BUW_PLAZA.z + 1.0, 12))
	var beds: Array = []
	for i in range(-4, 5):
		for j in range(-5, 0):
			var cu := float(i) * 6.6
			var cv := -BUW_HALL_SIZE.y - 1.5 - 3.3 + float(j + 1) * 6.6 - 3.3
			var o := BUW_HALL + a * cu + b * cv
			var sq := PackedVector2Array([o - a * 2.5 - b * 2.5, o + a * 2.5 - b * 2.5, o + a * 2.5 + b * 2.5, o - a * 2.5 + b * 2.5])
			var h := _buw_hash(float(i) + 11.0, float(j) + 5.0)
			var col: Color = BUW_LAWN if h < 0.5 else BUW_FLOWERS[int(h * 97.0) % BUW_FLOWERS.size()]
			for f in formal:
				for piece in Geometry2D.intersect_polygons(sq, f):
					if Geometry2D.is_polygon_clockwise(piece):
						continue
					var parts: Array[PackedVector2Array] = [piece]
					for d in off:
						var next: Array[PackedVector2Array] = []
						for p in parts:
							next.append_array(_clip_whole(p, d))
						parts = next
					for p in parts:
						if absf(_area(p)) > 2.0:
							beds.append([p, col])
	beds.append([_circle(plaza, 1.8, 10), BUW_FLOWERS[0]])
	return beds


func _grow(q: PackedVector2Array, by: float) -> PackedVector2Array:
	return _largest(Geometry2D.offset_polygon(q, by))


## `p` minus `d` with no holes: where `d` lies inside `p`, `p` is cut in two through `d`'s
## centre first.
func _clip_whole(p: PackedVector2Array, d: PackedVector2Array, depth := 0) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var cut := Geometry2D.clip_polygons(p, d)
	var holed := false
	for c in cut:
		if Geometry2D.is_polygon_clockwise(c):
			holed = true
	if not holed:
		for c in cut:
			if c.size() >= 3:
				out.append(c)
		return out
	if depth > 3:
		return out  # left out rather than drawn over what is under it
	var x := _centre(d).x
	var box := _box_of([p]).grow(1.0)
	for half in [Rect2(box.position.x, box.position.y, x - box.position.x, box.size.y),
			Rect2(x, box.position.y, box.end.x - x, box.size.y)]:
		var r := PackedVector2Array([half.position, Vector2(half.end.x, half.position.y), half.end,
				Vector2(half.position.x, half.end.y)])
		for piece in Geometry2D.intersect_polygons(p, r):
			if not Geometry2D.is_polygon_clockwise(piece):
				out.append_array(_clip_whole(piece, d, depth + 1))
	return out


func _build_buw(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["ring"]
	var ring := _simplify(outline, 0.8)
	_g = _ground_under(outline)
	var g := _g
	var top := g + BUW_ROOF
	# The block (F's photos, 2026-11-13): glass behind the copper on Dobra, the tall glass hall
	# by the south corner, every other front off-white concrete with teal windows behind a
	# patina trellis and ivy; the paved deck inside the curved green glass vault all round.
	_buw_walls(ring, g, top - BUW_BAND_DROP)
	for deck in Geometry2D.offset_polygon(ring, -BUW_BAND_W + 1.0):
		if deck.size() >= 3 and not Geometry2D.is_polygon_clockwise(deck):
			_cap(deck, top, BUW_DECK)
	_buw_band(ring, top)
	_collide(outline)
	_buw_front(g, ring)
	_buw_roof(site, g)
	_buw_court(site, g)
	_buw_pink(site, g)
	_buw_drums(site, g)
	_buw_ci4(site)
	_buw_lower_garden(site, g)


## Which front an edge of the outline is (F's photos, 2026-11-13): 1 the glass behind Dobra's
## copper, 2 the tall glass hall past the copper's south end and its recess, 0 the rest (white).
func _buw_front_kind(a: Vector2, b: Vector2) -> int:
	var ax := BUW_FRONT_AXIS.normalized()
	var d := (a + b) * 0.5 - BUW_FRONT
	var u := d.dot(ax)
	var v := d.dot(Vector2(-ax.y, ax.x))
	if u > -1.0 and u < BUW_COPPER_END and absf(v) < 3.0:
		return 1
	if u >= BUW_COPPER_END and u < BUW_ATRIUM_END and v > -8.5 and v < 3.0:
		return 2
	return 0


## The walls (F's photos): on Dobra dark green glass behind the copper, the hall's taller blue
## glass, and elsewhere the off-white concrete in three storeys of teal-framed windows, a bay
## every BUW_BAY m, ivy climbing the trellis between them (and over some of them), a band of it
## reddening in autumn.
func _buw_walls(ring: PackedVector2Array, g: float, y1: float) -> void:
	var n := ring.size()
	var run := 0.0
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var out := _out(ring, a, b)
		var kind := _buw_front_kind(a, b)
		var length := a.distance_to(b)
		if kind == 1:
			_mode = M_GLASS
			_wall(a, b, g - 0.4, y1, out, BUW_GLASS, run)
		elif kind == 2:
			_mode = M_GLASS
			_wall(a, b, g - 0.4, y1, out, BUW_HALL_GLASS, run)
		else:
			_mode = M_STONE
			_wall(a, b, g - 0.4, y1, out, BUW_WALL, run)
			var bays := floori((length - 0.8) / BUW_BAY)
			if bays >= 1:
				var e := (b - a) / length
				for k in bays:
					var t := (length - bays * BUW_BAY) * 0.5 + (k + 0.5) * BUW_BAY
					var p := a + e * t
					var h := _buw_hash(roundf(p.x), roundf(p.y))
					for row in 3:
						var y := g + 1.3 + row * 3.75
						if y + 2.3 > y1 - 0.4:
							continue
						_mode = M_STONE
						_buw_face(p - e * 1.25 + out * 0.05, p + e * 1.25 + out * 0.05, y - 0.15, y + 2.45, out, BUW_FRAME)
						_mode = M_GLASS
						_buw_face(p - e * 1.05 + out * 0.08, p + e * 1.05 + out * 0.08, y, y + 2.3, out, BUW_PANE, t)
					# ivy on the trellis between this bay and the next, and now and then over a bay
					_mode = M_STONE
					var ivy: Color = BUW_IVY[int(h * 13.0) % BUW_IVY.size()]
					if h > 0.92:
						ivy = BUW_IVY_RED
					var q := p + e * BUW_BAY * 0.5
					var ih := g + 4.0 + 8.5 * _buw_hash(roundf(q.x) + 3.0, roundf(q.y))
					_buw_face(q - e * 0.95 + out * 0.62, q + e * 0.95 + out * 0.62, g - 0.2, minf(ih, y1 + 0.3), out, ivy)
					if h < 0.3:
						# a whole bay grown over, to a ragged top: two heights
						var top0 := minf(g + 6.0 + 7.0 * h * 3.3, y1 + 0.3)
						_buw_face(p - e * 1.7 + out * 0.66, p + out * 0.66, g - 0.2, top0, out, ivy.darkened(0.08))
						_buw_face(p + out * 0.66, p + e * 1.7 + out * 0.66, g - 0.2, top0 - 1.6, out, ivy.darkened(0.08))
		run += length
	_mode = M_STONE


## The vault round the roof (F's photos, 2026-11-13): patina-green glass in a barrel's quarter,
## from the walls' top (BUW_BAND_DROP under the roof) up and in to just over the deck,
## BUW_BAND_W wide (narrower over the notch's court); BUW_VAULT_STEPS facets per edge.
func _buw_band(outline: PackedVector2Array, top: float) -> void:
	var ring := _simplify(outline, 2.0)  # short jogs fold a band this wide over itself
	var y0 := top - BUW_BAND_DROP
	var rise := BUW_BAND_DROP + 0.6
	var n := ring.size()
	var notch := PackedVector2Array(BUW_NOTCH)
	# per corner: its bisector, the mitre factor and the band's width there
	var bis: Array[Vector2] = []
	var mit: Array[float] = []
	var width: Array[float] = []
	var narrow: Array[bool] = []
	for i in n:
		var p := ring[i]
		var n0 := -_out(ring, ring[(i + n - 1) % n], p)
		var n1 := -_out(ring, p, ring[(i + 1) % n])
		var bv := (n0 + n1).normalized()
		bis.append(bv)
		mit.append(maxf(bv.dot(n1), 0.05))
		narrow.append(Geometry2D.is_point_in_polygon(p, notch))
		width.append(BUW_NOTCH_W if narrow[i] else BUW_BAND_W)
	# the profile: a quarter of an ellipse, upright at the wall, flat at the deck
	var prof: Array[Vector2] = []  # (share of the width in, height over y0)
	for k in BUW_VAULT_STEPS + 1:
		var th := PI * 0.5 * float(k) / float(BUW_VAULT_STEPS)
		prof.append(Vector2(1.0 - cos(th), sin(th)))
	var at := func(i: int, k: int) -> Vector3:
		var d: float = width[i] * prof[k].x
		var p2: Vector2 = ring[i] + bis[i] * minf(d / mit[i], d * 2.0)
		return Vector3(p2.x, y0 + rise * prof[k].y, p2.y)
	# solid green panes (M_STONE: the glass roof shader's white grid is Złote Tarasy's) with the
	# dark green ribs as geometry, one every BUW_RIB m across the curve
	_mode = M_STONE
	for i in n:
		var j := (i + 1) % n
		var ii: Vector3 = at.call(i, BUW_VAULT_STEPS)
		var jj: Vector3 = at.call(j, BUW_VAULT_STEPS)
		if Vector2(jj.x - ii.x, jj.z - ii.z).dot(ring[j] - ring[i]) <= 0.0:
			# an edge shorter than the band is wide: its inner line runs backwards (a fold);
			# its neighbours' facets cover it
			continue
		var col := BUW_NOTCH_BAND if narrow[i] and narrow[j] else BUW_BAND
		for k in BUW_VAULT_STEPS:
			var pa: Vector3 = at.call(i, k)
			var pb: Vector3 = at.call(j, k)
			var qa: Vector3 = at.call(i, k + 1)
			var qb: Vector3 = at.call(j, k + 1)
			# a little lighter up the curve, where the sky shows in it
			var shade := col.lightened(0.05 * k)
			var outv := _out(ring, ring[i], ring[j])
			for tr in [[pa, pb, qb], [pa, qb, qa]]:
				var nrm: Vector3 = (tr[1] - tr[0]).cross(tr[2] - tr[0]).normalized()
				if nrm.x * outv.x + nrm.z * outv.y + nrm.y < 0.0:
					nrm = -nrm
				_tri(tr[0], tr[1], tr[2], nrm, shade, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
		# the ribs: strips 0.16 m wide following the curve, 5 cm proud of the panes
		var length := ring[i].distance_to(ring[j])
		var ribs := floori(length / BUW_RIB)
		var outv2 := _out(ring, ring[i], ring[j])
		for r in ribs:
			var t := (float(r) + 0.5) / float(ribs)
			var dt := 0.08 / length
			for k in BUW_VAULT_STEPS:
				var a0: Vector3 = (at.call(i, k) as Vector3).lerp(at.call(j, k), t - dt)
				var b0: Vector3 = (at.call(i, k) as Vector3).lerp(at.call(j, k), t + dt)
				var a1: Vector3 = (at.call(i, k + 1) as Vector3).lerp(at.call(j, k + 1), t - dt)
				var b1: Vector3 = (at.call(i, k + 1) as Vector3).lerp(at.call(j, k + 1), t + dt)
				var face: Vector3 = (b0 - a0).cross(a1 - a0).normalized()
				if face.x * outv2.x + face.z * outv2.y + face.y < 0.0:
					face = -face
				var lift := face * 0.05
				for tr in [[a0 + lift, b0 + lift, b1 + lift], [a0 + lift, b1 + lift, a1 + lift]]:
					var cr: Vector3 = (tr[1] - tr[0]).cross(tr[2] - tr[0])
					if cr.length() < 1e-5:
						continue
					var nrm := cr.normalized()
					if nrm.dot(face) < 0.0:
						nrm = -nrm
					_tri(tr[0], tr[1], tr[2], nrm, BUW_RIB_COL, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = M_STONE
	# Over the notch the band is narrower: heather between it and the deck (cut to what the deck
	# leaves bare by _cap).
	for i in n:
		var j := (i + 1) % n
		if not (narrow[i] or narrow[j]):
			continue
		var wi: float = maxf(width[i], BUW_BAND_W - 0.6)
		var wj: float = maxf(width[j], BUW_BAND_W - 0.6)
		var ia: Vector2 = ring[i] + bis[i] * minf(width[i] / mit[i], width[i] * 2.0)
		var ja: Vector2 = ring[j] + bis[j] * minf(width[j] / mit[j], width[j] * 2.0)
		var ib: Vector2 = ring[i] + bis[i] * minf(wi / mit[i], wi * 2.0)
		var jb: Vector2 = ring[j] + bis[j] * minf(wj / mit[j], wj * 2.0)
		if (ja - ia).dot(ring[j] - ring[i]) <= 0.0:
			continue
		var q := PackedVector2Array([ia, ja, jb, ib])
		if Geometry2D.is_polygon_clockwise(q):
			q.reverse()
		if absf(_area(q)) > 0.5:
			_cap(q, top, BUW_HEATHER)


## Dobra (F's photos, 2026-11-13): the green copper screen. A frieze along the whole front from
## the second floor up past the roof, BIBLIOTEKA UNIWERSYTECKA across its top in raised letters
## and lines of old text under them; below it twelve copper pages, each its own text, the doors
## under the middle two and the four philosophers on their columns before them; a pair of round
## copper columns in every gap between the pages, the glass behind. The trellis posts on the
## other fronts.
func _buw_front(g: float, ring: PackedVector2Array) -> void:
	_o = BUW_FRONT
	_a = BUW_FRONT_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # out of the front, to the south-west
	var top := g + BUW_ROOF
	var fy := g + BUW_FRIEZE  # the frieze's underside
	var span := BUW_COPPER_END
	# the frieze: one long copper box, its face at v = 1.0
	_lbox(span * 0.5, 0.65, span * 0.5 + 0.3, 0.35, fy, top + 2.6, BUW_COPPER, M_STONE, BUW_PATINA)
	_mode = M_STONE
	# the patina's streaks: darker and paler panels on the frieze's face, a hash each
	for k in 13:
		var u0 := float(k) * span / 13.0
		var h := _buw_hash(float(k), 7.0)
		if h < 0.45:
			continue
		var tint := BUW_COPPER.darkened(0.12) if h < 0.75 else BUW_COPPER.lightened(0.08)
		var y0 := fy + 0.3 + 2.0 * _buw_hash(float(k), 9.0)
		_buw_face(_w(u0 + 0.4, 1.04), _w(u0 + span / 13.0 - 0.4, 1.04), y0, minf(y0 + 3.5, top + 2.3), _b, tint)
	# BIBLIOTEKA UNIWERSYTECKA across the frieze's top (pixel letters, runs of a row as one quad)
	var words := "BIBLIOTEKA UNIWERSYTECKA"
	var px := minf(0.42, (span - 6.0) / float(PixelFont.width(words)))
	var u_start := (span - PixelFont.width(words) * px) * 0.5
	var y_top := top + 2.2
	var rows := {}
	PixelFont.each_pixel(words, 0, func(x: int, row: int) -> void:
		if not rows.has(row):
			rows[row] = []
		(rows[row] as Array).append(x))
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
			var y := y_top - float(row - PixelFont.BODY + 1) * px
			_buw_face(_w(u_start + s0 * px, 1.12), _w(u_start + (prev + 1) * px, 1.12), y - px, y, _b, BUW_INK)
			s0 = x
			prev = x
	# lines of old text under the letters, left-aligned, each its own length
	var yl := fy + 0.9
	var line_n := 0
	while yl < y_top - 7.0 * px - 0.6:
		var u := 1.0
		while u < span - 2.0:
			var length := minf(5.5 * (0.35 + 0.65 * _buw_hash(u, float(line_n))), span - 1.0 - u)
			_buw_face(_w(u, 1.08), _w(u + length, 1.08), yl, yl + 0.22, _b, BUW_INK)
			u += length + 1.2 + 2.0 * _buw_hash(float(line_n), u)
		yl += 0.85
		line_n += 1
	# the pages under the frieze, the round columns in the gaps
	for k in 12:
		var uc := BUW_PAGE_PITCH * (k + 0.5)
		var door := k == 5 or k == 6
		var y0 := g + 4.5 if door else g - 0.4
		var tint := 1.0 + 0.05 * (_buw_hash(float(k), 3.0) * 2.0 - 1.0)
		var plate := Color(BUW_COPPER.r * tint, BUW_COPPER.g * tint, BUW_COPPER.b * tint)
		_lbox(uc, 0.55, BUW_PAGE_HALF, 0.2, y0, fy, plate, M_STONE, plate.darkened(0.15))
		if not door:
			_collide(_rect(uc, 0.55, BUW_PAGE_HALF, 0.2))
		_mode = M_STONE
		var row := 0
		var y := maxf(2.0, y0 - g + 1.0)
		while g + y + 0.25 < fy - 0.4:
			var length := (BUW_PAGE_HALF * 2.0 - 0.6) * (0.45 + 0.55 * _buw_hash(float(k), float(row)))
			_buw_face(_w(uc - BUW_PAGE_HALF + 0.3, 0.79), _w(uc - BUW_PAGE_HALF + 0.3 + length, 0.79), g + y, g + y + 0.22, _b, BUW_INK)
			y += 0.9
			row += 1
		if k < 11:
			var ug := BUW_PAGE_PITCH * (k + 1)
			for du: float in [-0.55, 0.55]:
				_prism(_circle(_w(ug + du, 1.0), 0.32, 8), g - 0.4, fy, BUW_COPPER.lightened(0.04), Color(0, 0, 0, 0), M_STONE)
			_collide(_rect(ug, 1.0, 0.9, 0.35))
	_mode = M_GLASS
	_wall(_w(31.5, 0.25), _w(42.5, 0.25), g - 0.4, g + 4.2, _b, BUW_DOOR)
	_mode = M_STONE
	for u: float in [31.75, 35.25, 38.75, 42.25]:
		_column(u, 4.0, 0.35, g, g + 9.0, BUW_COLUMN)
		_lbox(u, 4.0, 0.3, 0.22, g + 9.0, g + 10.6, BUW_BRONZE, M_STONE, BUW_BRONZE)
		_lbox(u, 4.0, 0.14, 0.14, g + 10.6, g + 11.0, BUW_BRONZE, M_STONE, BUW_BRONZE)
		_collide(_rect(u, 4.0, 0.5, 0.5))
	# The trellis: a post every ~6 m 0.35 m out of every white front, to just over the walls.
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if _buw_front_kind(a, b) != 0:
			continue
		var length := a.distance_to(b)
		var count := floori((length - 1.0) / 6.0)
		if count < 1:
			continue
		var along := (b - a) / length
		var out := _out(ring, a, b)
		for n in count:
			var p := a + along * (length * (float(n) + 0.5) / float(count)) + out * 0.35
			var post := PackedVector2Array([p - along * 0.12 - out * 0.12, p + along * 0.12 - out * 0.12,
					p + along * 0.12 + out * 0.12, p - along * 0.12 + out * 0.12])
			_prism(post, g - 0.4, top - BUW_BAND_DROP + 0.3, BUW_PATINA, BUW_PATINA.darkened(0.1), M_STONE, M_STONE)


## The roof garden: the mapped lawns as low beds on the deck (kept off the glass roofs and the
## roof houses), the glass field and its railed walkways, the second glass roof, the hill with the
## glass pyramid, the ribbed glass dome in its paved ring, benches, the pavilions and the roof
## houses. Heights from GUGiK's LoD2 (pass 3): the deck at 15 m, the glass at 16-17 m.
func _buw_roof(site: Dictionary, g: float) -> void:
	var top := g + BUW_ROOF
	var none := Color(0, 0, 0, 0)
	var light: PackedVector2Array = site.get("light", PackedVector2Array())
	_mode = M_STONE
	for bed: Array in site.get("beds", []):
		_cap(bed[0], top + 0.12, bed[1])
	# The glass field over the central hall and its tail down the Dobra side (the orthophoto):
	# nearly flat green glass in a fine grid on a copper curb, the walkways' dark lines across it.
	# Out of the roof grid: a flat roof the cassette must not pick.
	var field := PackedVector2Array(BUW_FIELD)
	_prism(field, top, top + 1.6, BUW_PATINA, none, M_STONE)
	_no_roof = true
	_mode = M_GLASS_ROOF
	_cap(field, top + 1.6, BUW_SKY)
	_mode = M_STONE
	for walk: Array in BUW_WALKS:
		var w0: Vector2 = walk[0]
		var w1: Vector2 = walk[1]
		var e := (w1 - w0).normalized()
		var side := e.orthogonal() * 1.0
		_prism(PackedVector2Array([w0 - side, w1 - side, w1 + side, w0 + side]), top + 1.0, top + 1.75,
				BUW_DARK, BUW_DARK, M_STONE, M_STONE)
		# the pale green railings on both sides (F's photos): a mesh panel and its top rail,
		# seen from both sides
		for s: float in [-1.0, 1.0]:
			var o := side * s * 0.95
			var out := side.normalized() * s
			_buw_face(w0 + o, w1 + o, top + 1.75, top + 2.7, out, BUW_RAIL)
			_buw_face(w1 + o, w0 + o, top + 1.75, top + 2.7, -out, BUW_RAIL)
			_buw_face(w0 + o * 1.01, w1 + o * 1.01, top + 2.7, top + 2.85, out, BUW_RAIL_TOP)
	# The second glass roof: the same flat fine grid on its mapped part.
	if light.size() >= 3:
		var lr := _hull(light)
		_prism(lr, top, top + 1.2, BUW_PATINA, none, M_STONE)
		_mode = M_GLASS_ROOF
		_cap(lr, top + 1.2, BUW_SKY)
		_mode = M_STONE
	_no_roof = false
	# The hill between the field and the oculus (the Mac's check): a solid dark green mound, the
	# small teal glass pyramid (OSM's 6 m part) on its flat top.
	_frustum(_buw_ellipse(1.0, 16), top, _buw_ellipse(0.62, 16), top + 2.0, BUW_HILL)
	_frustum(_buw_ellipse(0.62, 16), top + 2.0, _buw_ellipse(0.32, 16), top + 3.0, BUW_HILL, BUW_HILL)
	# The white pavilions, and the small white domes on brown rings along the south lawn.
	for pv: Vector4 in BUW_PAVILIONS:
		_prism(_buw_pavilion(pv), top, top + 2.6, BUW_WHITE, BUW_WHITE.darkened(0.08), M_STONE, M_STONE)
	for d: Vector2 in BUW_DOMES:
		_cap(_circle(d, 2.4, 10), top + 0.2, BUW_EARTH)
		_frustum(_circle(d, 1.0, 8), top + 0.2, _circle(d, 0.55, 8), top + 0.9, BUW_WHITE, BUW_WHITE)
	# Benches by the paths (dark green slats on grey feet).
	# one by every other bend of the south garden's main path, 1.9 m to its side
	var main: Array = BUW_PATHS[0]
	for k in range(1, main.size() - 1, 2):
		var p: Vector2 = main[k]
		var e: Vector2 = ((main[k + 1] as Vector2) - (main[k - 1] as Vector2)).normalized()
		var s := e.orthogonal()
		var c := p + s * 1.9
		var seat := PackedVector2Array([c - e * 0.9 - s * 0.25, c + e * 0.9 - s * 0.25, c + e * 0.9 + s * 0.25, c - e * 0.9 + s * 0.25])
		_prism(seat, top + 0.12, top + 0.5, BUW_BENCH, BUW_BENCH, M_STONE, M_STONE)
	# The round lights (F's photos): the big one a ribbed glass dome, silver-green, on a low
	# copper curb in a 4 m paved ring path; the small one a glass cone in a planted hump. The
	# dome's glass stays out of the roof grid (the cassette goes to the garden).
	for r: Vector3 in site.get("rounds", []):
		var c := Vector2(r.x, r.y)
		if r.z > 6.0:
			var sides := 16
			for k in sides:
				var d0 := Vector2.from_angle(TAU * k / sides)
				var d1 := Vector2.from_angle(TAU * (k + 1) / sides)
				var i0 := c + d0 * r.z
				var i1 := c + d1 * r.z
				var o0 := c + d0 * (r.z + BUW_RING_W)
				var o1 := c + d1 * (r.z + BUW_RING_W)
				_quad(Vector3(i0.x, top + 0.14, i0.y), Vector3(o0.x, top + 0.14, o0.y), Vector3(o1.x, top + 0.14, o1.y),
						Vector3(i1.x, top + 0.14, i1.y), Vector3.UP, BUW_PAVING)
			_prism(_circle(c, r.z, sides), top, top + 0.6, BUW_PATINA, none, M_STONE)
			_no_roof = true
			_mode = M_GLASS_ROOF
			var y := top + 0.6
			var rr := r.z
			for k in 4:
				var ph := PI * 0.5 * float(k + 1) / 4.6
				var r1 := r.z * cos(ph)
				var y1 := top + 0.6 + r.z * BUW_DOME_RISE * sin(ph)
				_frustum(_circle(c, rr, sides), y, _circle(c, r1, sides), y1, BUW_DOME.lightened(0.04 * k))
				rr = r1
				y = y1
			_mode = M_STONE
			_frustum(_circle(c, rr, 8), y, _circle(c, rr * 0.6, 8), y + 0.5, BUW_PATINA, BUW_PATINA)
			_no_roof = false
		else:
			_frustum(_circle(c, r.z + 2.0, 12), top, _circle(c, 1.6, 12), top + 1.4, BUW_PARK)
			_mode = M_GLASS_ROOF
			_pyramid(_circle(c, 1.6, 12), top + 1.4, top + 2.6, BUW_SKY)
			_mode = M_STONE
	# The mapped roof parts: the 6 m one is the glass pyramid on the hill, the long one the
	# glass strip along the north-west edge, the small one by Dobra a white stair house.
	for h: Dictionary in site.get("houses", []):
		var q := _hull(_pts(h["p"]))
		var area := absf(_area(q))
		if area < 60.0 and q.size() <= 5 and Geometry2D.is_point_in_polygon(_centre(q), _buw_ellipse(0.32, 16)):
			_mode = M_GLASS_ROOF
			_pyramid(q, top + 3.0, top + 5.0, BUW_SKY.lerp(Color("#5fb3ad"), 0.5))
			_mode = M_STONE
		elif area > 120.0:
			_prism(q, top, top + 0.8, BUW_PATINA, none, M_STONE)
			_mode = M_GLASS_ROOF
			_pyramid(q, top + 0.8, top + 2.2, BUW_SKY)
			_mode = M_STONE
		else:
			var hh := g + maxf(float(h["h"]), BUW_ROOF + 3.1)
			_prism(q, top, hh, BUW_WHITE, BUW_WHITE.darkened(0.1), M_STONE, M_STONE)


## The court in the south notch (the Mac's LoD2, pass 3): Collegium Iuridicum II's 10 m roof,
## green, part of the garden, with its own small glass skylight; its walls white with teal
## windows and ivy like the library's (F's photos).
func _buw_court(site: Dictionary, g: float) -> void:
	var court: PackedVector2Array = site.get("court", PackedVector2Array())
	if court.size() < 3:
		return
	var y := g + BUW_COURT
	_buw_walls(_simplify(court, 0.8), g, y)
	_mode = M_STONE
	_cap(court, y, BUW_PARK)
	# a paved path along it and the skylight at its west end (the orthophoto)
	var inner := _largest(Geometry2D.offset_polygon(court, -1.5))
	for piece in Geometry2D.offset_polyline(PackedVector2Array([Vector2(78.0, -912.5), Vector2(99.0, -914.5)]), 0.9):
		for p in Geometry2D.intersect_polygons(piece, inner):
			if not Geometry2D.is_polygon_clockwise(p):
				_cap(p, y + 0.08, BUW_PAVING)
	var sky := _circle(Vector2(74.5, -912.2), 2.2, 4)
	_prism(sky, y, y + 0.5, BUW_PATINA, Color(0, 0, 0, 0), M_STONE)
	_mode = M_GLASS_ROOF
	_pyramid(sky, y + 0.5, y + 1.8, BUW_SKY)
	_mode = M_STONE
	_collide(court)


## The pink tower at the south corner on Dobra (F's photos, 2026-11-13): an open steel lattice
## in front of the white wall, painted magenta-pink: corner and middle posts, a ring of beams
## every storey with beams across, on the mapped pink parts' footprint (OSM paints them
## #C34DC0; their plain boxes are dropped by the site's zone).
func _buw_pink(site: Dictionary, g: float) -> void:
	var foot: PackedVector2Array = site.get("pink", PackedVector2Array())
	if foot.size() < 3:
		return
	var ax := BUW_FRONT_AXIS.normalized()
	var bx := Vector2(-ax.y, ax.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in foot:
		var l := Vector2((p - foot[0]).dot(ax), (p - foot[0]).dot(bx))
		lo = lo.min(l)
		hi = hi.max(l)
	var at := func(u: float, v: float) -> Vector2:
		return foot[0] + ax * u + bx * v
	var beam := func(p: Vector2, q: Vector2, y0: float, y1: float, half: float) -> void:
		var e := (q - p).normalized()
		var s := e.orthogonal() * half
		var pp := p - e * half
		var qq := q + e * half
		_prism(PackedVector2Array([pp - s, qq - s, qq + s, pp + s]), y0, y1, BUW_PINK, BUW_PINK.darkened(0.12), M_STONE, M_STONE)
	var us := [lo.x, (lo.x + hi.x) * 0.5, hi.x]
	var vs := [lo.y, (lo.y + hi.y) * 0.5, hi.y]
	var y_top := g + BUW_PINK_H
	for iu in 3:
		for iv in 3:
			if iu == 1 and iv == 1:
				continue
			var p: Vector2 = at.call(us[iu], vs[iv])
			var corner := iu != 1 and iv != 1
			var half := 0.32 if corner else 0.18
			_prism(_circle(p, half * 1.41, 4), g - 0.3, y_top, BUW_PINK, BUW_PINK.darkened(0.12), M_STONE, M_STONE)
			if corner:
				_collide(_circle(p, 0.45, 4))
	var y := g + 2.6
	while y < y_top + 0.1:
		var y1 := minf(y + 0.32, y_top)
		for iv in 3:
			beam.call(at.call(us[0], vs[iv]), at.call(us[2], vs[iv]), y1 - 0.32, y1, 0.13)
		for iu in 3:
			beam.call(at.call(us[iu], vs[0]), at.call(us[iu], vs[2]), y1 - 0.32, y1, 0.13)
		y += BUW_PINK_STOREY


## The round towers (F's photos): concrete drums standing out of the north-east and north
## fronts to over the roof, the top 2 m dark slits between pale ribs; the one nearest the round
## east corner carries a railed lookout (crowds.gd's `buw_lookout` deck stands people on it).
func _buw_drums(site: Dictionary, g: float) -> void:
	var top := g + BUW_ROOF
	var vents: Array = site.get("vents", [])
	for v: Vector3 in vents:
		var c := Vector2(v.x, v.y)
		var r := maxf(v.z, BUW_DRUM_R)
		var body := top + BUW_DRUM_UP - 2.2
		_prism(_circle(c, r, 14), g - 0.4, body, BUW_CONCRETE, Color(0, 0, 0, 0), M_STONE)
		_prism(_circle(c, r - 0.05, 14), body, top + BUW_DRUM_UP, BUW_SLIT, BUW_DARK, M_STONE, M_STONE)
		_mode = M_STONE
		for k in 10:
			var d := Vector2.from_angle(TAU * (k + 0.5) / 10.0)
			var t := d.orthogonal()
			var p := c + d * (r + 0.02)
			_buw_face(p - t * 0.22, p + t * 0.22, body, top + BUW_DRUM_UP, d, BUW_CONCRETE.lightened(0.05))
		_collide(_circle(c, r, 8))
		if c.distance_to(BUW_LOOKOUT) < 6.0:
			# the lookout's railing: posts and a top ring, people inside (crowds.gd)
			var y0 := top + BUW_DRUM_UP
			for k in 12:
				var d := Vector2.from_angle(TAU * (k + 0.5) / 12.0)
				var p := c + d * (r - 0.1)
				var t := d.orthogonal()
				_buw_face(p - t * 0.05, p + t * 0.05, y0, y0 + 1.1, d, BUW_RAIL_TOP)
			_frustum(_circle(c, r - 0.05, 14), y0 + 1.0, _circle(c, r - 0.05, 14), y0 + 1.12, BUW_RAIL_TOP)


## Collegium Iuridicum IV, Wybrzeże Kościuszkowskie 47 (F's photos, 2026-11-13): the 19th-century
## grey villa by the library's north end. Grey render with white stone corners, string courses
## and window surrounds, three storeys of arched windows, a grey metal hipped roof with glass
## pyramids, and on the river side a square tower carrying a tall glass spire.
func _buw_ci4(site: Dictionary) -> void:
	var outline: PackedVector2Array = site.get("ci4", PackedVector2Array())
	if outline.size() < 3:
		return
	var ring := _simplify(outline, 0.6)
	_g = _ground_under(outline)
	var g := _g
	var eave := g + CI4_EAVE
	_mode = M_STONE
	var n := ring.size()
	var run := 0.0
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var out := _out(ring, a, b)
		var length := a.distance_to(b)
		_wall(a, b, g - 0.4, eave, out, CI4_RENDER, run)
		run += length
		if length < 0.5:
			continue
		var e := (b - a) / length
		# the plinth, the string courses and the white corners
		_buw_face(a - e * 0.06 + out * 0.05, b + e * 0.06 + out * 0.05, g - 0.4, g + 1.1, out, CI4_STONE.darkened(0.06))
		for yy: float in [g + 4.0, g + 7.3]:
			_buw_face(a - e * 0.06 + out * 0.09, b + e * 0.06 + out * 0.09, yy, yy + 0.32, out, CI4_STONE)
		if length > 1.5:
			_buw_face(a + out * 0.13, a + e * 0.7 + out * 0.13, g + 1.1, eave, out, CI4_STONE)
			_buw_face(b - e * 0.7 + out * 0.13, b + out * 0.13, g + 1.1, eave, out, CI4_STONE)
		# arched windows: a white surround, the dark glass, a white round head (a short cap)
		var bays := floori((length - 1.6) / 3.0)
		for k in bays:
			var t := (length - bays * 3.0) * 0.5 + (k + 0.5) * 3.0
			var p := a + e * t
			for wy: Vector2 in [Vector2(g + 1.5, 2.2), Vector2(g + 4.7, 2.3), Vector2(g + 7.9, 1.7)]:
				_mode = M_STONE
				_buw_face(p - e * 0.8 + out * 0.17, p + e * 0.8 + out * 0.17, wy.x - 0.2, wy.x + wy.y + 0.45, out, CI4_STONE)
				_mode = M_GLASS
				_buw_face(p - e * 0.55 + out * 0.21, p + e * 0.55 + out * 0.21, wy.x, wy.x + wy.y, out, CI4_GLASS, t)
				_mode = M_STONE
				_buw_face(p - e * 0.38 + out * 0.21, p + e * 0.38 + out * 0.21, wy.x + wy.y, wy.x + wy.y + 0.22, out, CI4_GLASS)
	# the cornice and the hipped metal roof (over the hull: the outline's jogs stay under it)
	var hull := _hull(ring)
	var hc := _centre(hull)
	var grown := PackedVector2Array()
	var inner := PackedVector2Array()
	for p in hull:
		grown.append(hc + (p - hc) * 1.0 + (p - hc).normalized() * 0.45)
		inner.append(hc + (p - hc) * 0.55)
	_prism(grown, eave, eave + 0.45, CI4_STONE, Color(0, 0, 0, 0), M_STONE)
	_frustum(grown, eave + 0.45, inner, eave + CI4_ROOF, CI4_ROOF_COL, CI4_ROOF_COL.darkened(0.05))
	# two glass pyramids on the roof's flat top
	var ax := (hull[1] - hull[0]).normalized()
	for s: float in [-1.0, 1.0]:
		var pc := hc + ax * s * 3.0
		var sq := PackedVector2Array([pc + Vector2(-1.4, -1.4), pc + Vector2(1.4, -1.4), pc + Vector2(1.4, 1.4), pc + Vector2(-1.4, 1.4)])
		_mode = M_GLASS_ROOF
		_pyramid(sq, eave + CI4_ROOF, eave + CI4_ROOF + 2.2, CI4_SPIRE)
		_mode = M_STONE
	# the tower: on the front facing the river (the hull's edge whose normal points that way most)
	var best := 0
	var best_dot := -INF
	for i in hull.size():
		var a := hull[i]
		var b := hull[(i + 1) % hull.size()]
		var dd := _out(hull, a, b).dot(CI4_RIVER)
		if dd > best_dot and a.distance_to(b) > 6.0:
			best_dot = dd
			best = i
	var ta := hull[best]
	var tb := hull[(best + 1) % hull.size()]
	var te := (tb - ta).normalized()
	var tout := _out(hull, ta, tb)
	var tcentre := ta.lerp(tb, 0.38) - tout * 1.6
	var sq := PackedVector2Array([tcentre - te * 2.6 - tout * 2.6, tcentre + te * 2.6 - tout * 2.6,
			tcentre + te * 2.6 + tout * 2.6, tcentre - te * 2.6 + tout * 2.6])
	var tt := g + CI4_TOWER
	_prism(sq, g - 0.4, tt, CI4_RENDER, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	for i in 4:
		var a := sq[i]
		var b := sq[(i + 1) % 4]
		var o := _out(sq, a, b)
		var e := (b - a).normalized()
		_buw_face(a + o * 0.08, a + e * 0.6 + o * 0.08, g - 0.4, tt, o, CI4_STONE)
		_buw_face(b - e * 0.6 + o * 0.08, b + o * 0.08, g - 0.4, tt, o, CI4_STONE)
		var m := (a + b) * 0.5
		_mode = M_GLASS
		_buw_face(m - e * 0.5 + o * 0.11, m + e * 0.5 + o * 0.11, eave + 0.8, eave + 3.0, o, CI4_GLASS)
		_mode = M_STONE
	var cap := PackedVector2Array()
	for p in sq:
		cap.append(tcentre + (p - tcentre) * 1.12)
	_prism(cap, tt, tt + 0.5, CI4_STONE, CI4_STONE.darkened(0.05), M_STONE, M_STONE)
	# the glass spire: a glass lantern, then the tall glass needle in its steel frame
	var lan := PackedVector2Array()
	for p in sq:
		lan.append(tcentre + (p - tcentre) * 0.72)
	_mode = M_GLASS
	_prism(lan, tt + 0.5, tt + 3.2, CI4_SPIRE, Color(0, 0, 0, 0), M_GLASS)
	_mode = M_GLASS_ROOF
	_pyramid(lan, tt + 3.2, tt + CI4_SPIRE_H, CI4_SPIRE)
	_mode = M_STONE
	_collide(outline)


## The lower garden by the library's north tip (F's photos, 2026-11-13): the stream's pool under a
## stepped concrete cascade from the roof, a concrete rim round it, three steel "trees" with
## their square sunshades and beds of flowers by the pool.
func _buw_lower_garden(_site: Dictionary, g: float) -> void:
	_g = g
	var top := g + BUW_ROOF
	# the cascade: four concrete steps from the roof's tip down to the pool, water on each
	var e := BUW_CASCADE_DIR.normalized()
	var s := e.orthogonal()
	for k in 4:
		var c := BUW_CASCADE + e * (k * 1.6)
		var y1 := top - 1.0 - k * 3.4
		var box := PackedVector2Array([c - e * 0.8 - s * 1.3, c + e * 0.8 - s * 1.3, c + e * 0.8 + s * 1.3, c - e * 0.8 + s * 1.3])
		_prism(box, g - 0.4, y1, BUW_CONCRETE, Color(0, 0, 0, 0), M_STONE)
		var inner := PackedVector2Array([c - e * 0.6 - s * 1.05, c + e * 0.6 - s * 1.05, c + e * 0.6 + s * 1.05, c - e * 0.6 + s * 1.05])
		_cap(box, y1, BUW_CONCRETE.lightened(0.06))
		_cap(inner, y1 + 0.03, BUW_WATER)
	# the pool's concrete rim
	var pool := _circle(BUW_POOL, BUW_POOL_R, 14)
	var rim := _circle(BUW_POOL, BUW_POOL_R + 0.5, 14)
	_frustum(rim, g - 0.2, rim, g + 0.45, BUW_CONCRETE, Color(0, 0, 0, 0))
	_cap(rim, g + 0.45, BUW_CONCRETE.lightened(0.06))
	_cap(pool, g + 0.47, BUW_WATER)
	# the steel trees: a trunk, four arms up to a tilted square of panels
	for t: Vector3 in BUW_STEEL_TREES:
		var c := Vector2(t.x, t.y)
		_prism(_circle(c, 0.22, 6), g - 0.2, g + t.z, BUW_STEEL, Color(0, 0, 0, 0), M_STONE)
		var head := g + t.z
		for k in 4:
			var d := Vector2.from_angle(TAU * k / 4.0 + 0.6)
			var p := c + d * 1.6
			_frustum(_circle(c + d * 0.1, 0.12, 4), head, _circle(p, 0.08, 4), head + 1.4, BUW_STEEL)
		var sq := PackedVector2Array()
		for k in 4:
			sq.append(c + Vector2.from_angle(TAU * k / 4.0 + 0.6 + PI * 0.25) * 2.6)
		_prism(sq, head + 1.4, head + 1.6, BUW_STEEL, BUW_PANEL, M_STONE, M_STONE)
		_collide(_circle(c, 0.4, 4))
	# flower beds by the pool
	for k in BUW_LOW_BEDS.size():
		var bv: Vector3 = BUW_LOW_BEDS[k]
		_cap(_circle(Vector2(bv.x, bv.y), bv.z, 10), g + 0.12, BUW_FLOWERS[k % BUW_FLOWERS.size()])


## A polygon's convex hull, open (a pyramid over a concave ring folds over itself).
func _hull(q: PackedVector2Array) -> PackedVector2Array:
	var h := Geometry2D.convex_hull(q)
	if h.size() > 1 and h[0].is_equal_approx(h[-1]):
		h.resize(h.size() - 1)
	return h


## A steady pseudo-random number in [0, 1) for a plate and a row (the lines' lengths).
## A wall quad that is not kept for the coplanar cut (_wall's): a window, a strip of ivy, a line
## of text, each in its own plane in front of its wall; `_wall`'s list grows with every piece and
## is searched for each new one, too slow for the thousand of these.
func _buw_face(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, col: Color, run := 0.0) -> void:
	var l := a.distance_to(b)
	if l < 0.02 or y1 <= y0:
		return
	var n := Vector3(out.x, 0.0, out.y).normalized()
	var h0 := y0 - _g
	var h1 := y1 - _g
	_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), n, col,
			Vector2(run, h0), Vector2(run + l, h0), Vector2(run + l, h1), Vector2(run, h1), h1)


func _buw_hash(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


# --- Centrum Nauki Kopernik ---------------------------------------------------------------------

## The Copernicus Science Centre on Wybrzeże Kościuszkowskie (RAr-2, opened 2010; spec
## docs/landmarks/specs/kopernik.md, 2026-11-01, the Mac's photo check the same day): one long
## block over the Wisłostrada tunnel, as big as its outline and as tall as GUGiK's LoD2 roof
## (13 m over the street; OSM says 7.6). Its fronts are vertical panel strips in warm, varied
## tones (dusty rose, beige-grey, grey, a few copper-red), cut by tall slits and multi-storey
## glazed bays, some of them slanted; the south-east end is glass behind a light steel frame of
## galleries and stairs. A dark strip cantilevers over the court on the planetarium's side; the
## river corner hangs over a glazed ground floor (OSM's part from 3.3 m); the west corner and
## the link to the planetarium are low glass wings. The roof is a garden: meandering paths
## round mixed beds, seven concrete skylight craters, a teal glass strip, a glass pavilion.
## Beside it the planetarium (2011): a copper-red faceted drum with leaning walls, its roof
## edge level with the block's, a chamfered ring round a glazed clerestory and a white dome.
const KOP_ROOF := 13.0           # the roof over the street on the city side (LoD2)
const KOP_LIFT := 5.0            # the river corner's soffit over its own ground (OSM 3.3 of 7.6, scaled)
const KOP_LOW := 4.5             # the low glass wings over the street
const KOP_CANTI := 8.0           # the cantilever's soffit over the street
const KOP_CANTI_DEPTH := 12.0
const KOP_PLANET_RISE := 0.8     # the planetarium's roof edge over the block's roof
const KOP_PATH_AXIS := Vector2(0.6248, 0.7810)  # along the block, to the south-east
const KOP_STRIPS := ["#9b7d78", "#c8beb3", "#8f8984", "#a8908a", "#bdb2a6", "#87736e", "#b49f97"]

const KOP_COPPER := Color("#a24a36")
const KOP_COPPER_DARK := Color("#8e3b2c")
const KOP_FACET := Color("#6f2e24")
const KOP_PANEL := Color("#7d6f6a")  # the parapet, the soffits
const KOP_WINDOW := Color("#3b4347")
const KOP_LIT := Color("#8fa3a8")    # glass walls lit at night
const KOP_TEAL := Color("#5f9c98")
const KOP_STEEL := Color("#d9dad6")
const KOP_DARK := Color("#3f3936")   # the cantilever
const KOP_DECK := Color("#c2bfb7")   # the roof's paths
const KOP_CONCRETE := Color("#d3c9b6")
const KOP_SKYGLASS := Color("#2f3a40")
const KOP_KERB := Color("#9c968b")
const KOP_BEDS := ["#6f9a4c", "#87a659", "#b39a5a", "#4f6b3a", "#7ea052"]
const KOP_DOME := Color("#eeeeea")
## The roof's seven raised features, from the Mac's re-check against the orthophoto: (u along the
## block to the south-east, v across it to the city side, both in metres from the world origin in
## the KOP_PATH_AXIS frame; radius; kind 0 a hexagonal crater with a dark glazed centre, 1 the
## crater with the glazed pyramid, 2 a dark octagonal stair and lift head). The wide north part
## (roof inset u -528..-484, v -854..-760) holds two big craters 24 m in from the river wall and,
## 39 m further to the city, a row of three kept just clear of the planetarium notch's corner;
## the south wing (u -484..-404, v -803..-760) two more down its middle, 55 m apart.
const KOP_CRATERS := [Vector4(-518.5, -834.0, 7.8, 0), Vector4(-493.5, -834.0, 7.8, 0),
		Vector4(-519.5, -795.0, 7.0, 0), Vector4(-503.0, -795.0, 7.5, 1), Vector4(-488.0, -795.0, 4.5, 2),
		Vector4(-467.0, -781.5, 7.0, 0), Vector4(-412.0, -781.5, 6.0, 0)]


func _find_kopernik() -> void:
	var outline := _landmark("Centrum Nauki Kopernik")
	if outline.size() < 3:
		return
	var planet := _landmark("Planetarium Niebo Kopernika")
	_add_site("kopernik", [outline, planet])
	if sites.is_empty() or sites[-1]["key"] != "kopernik":
		return
	var site: Dictionary = sites[-1]
	site["ring"] = outline
	site["planet"] = planet
	var low: Array[PackedVector2Array] = []
	for bld in _parts_in(outline, func(b2: Dictionary) -> bool: return float(b2["h"]) > float(b2["mh"])):
		var q := _pts(bld["p"])
		if float(bld["h"]) < 5.0:
			low.append(q)  # the west corner's wing, the link to the planetarium
		elif float(bld["mh"]) > 1.0:
			site["lifted"] = q  # the river corner, on its glazed ground floor
	site["low"] = low


func _build_kopernik(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["ring"]
	_g = _ground_under(outline)
	var g := _g
	var street := -INF
	for q in outline:
		street = maxf(street, map.terrain_height(q.x, q.y))
	var top := street + KOP_ROOF
	# The block: the outline less its low wings, straightened.
	var body := outline
	for q: PackedVector2Array in site.get("low", []):
		var cut := _largest(Geometry2D.clip_polygons(body, q))
		if cut.size() >= 3:
			body = cut
	body = _simplify(body, 0.8)
	var planet: PackedVector2Array = site.get("planet", PackedVector2Array())
	# The river corner hangs over its ground floor: `under` stands on the ground, `hang` is the
	# corner over the soffit (the two split the block's fronts between them exactly).
	var lifted: PackedVector2Array = site.get("lifted", PackedVector2Array())
	var under := body
	var hang := PackedVector2Array()
	var soffit := top
	if lifted.size() >= 3:
		var rest := _largest(Geometry2D.clip_polygons(body, lifted))
		var over := _largest(Geometry2D.clip_polygons(body, rest)) if rest.size() >= 3 else PackedVector2Array()
		if rest.size() >= 3 and over.size() >= 3 and absf(_area(over)) > 50.0:
			under = rest
			hang = over
			soffit = minf(_ground_under(lifted) + KOP_LIFT, top - 4.0)
	_mode = M_STONE
	for i in under.size():
		var a := under[i]
		var b := under[(i + 1) % under.size()]
		var mid := (a + b) * 0.5
		var out := _out(under, a, b)
		if _kop_edge_dist(body, mid) < 0.3:
			var glass := out.dot(KOP_PATH_AXIS.normalized()) > 0.8 and a.distance_to(b) > 20.0
			_kop_front(a, b, out, g - 0.4, top, map.terrain_height(mid.x, mid.y), i, glass)
			if glass:
				_kop_frame(a, b, out, street, top)
		else:
			# set back under the overhang: the glazed ground floor, lit at night
			_mode = M_PAVILION
			_wall(a, b, g - 0.4, soffit, out, KOP_LIT)
			_mode = M_STONE
	for i in hang.size():
		var a := hang[i]
		var b := hang[(i + 1) % hang.size()]
		var mid := (a + b) * 0.5
		if _kop_edge_dist(body, mid) < 0.3:
			_kop_front(a, b, _out(hang, a, b), soffit, top, soffit, 100 + i, false)
	if hang.size() >= 3:
		_kop_soffit(hang, soffit, KOP_PANEL)
	# The low glass wings (lit at night), their roofs paved.
	for q: PackedVector2Array in site.get("low", []):
		var wing := _simplify(q, 0.4)
		_prism(wing, g - 0.4, street + KOP_LOW, KOP_LIT, KOP_DECK, M_PAVILION, M_STONE)
	_collide(outline)
	if planet.size() >= 3:
		_kop_cantilever(body, planet, street, top)
	_kop_roof(body, top)
	if planet.size() >= 3:
		_kop_planet(planet, top)


## A front in vertical panel strips 1.5 to 4 m wide, each its own warm tone (one in a dozen
## copper-red), cut by tall slits and multi-storey glazed bays (some slanted), lit at night.
## `glass`: the whole front glazed (the south-east end, behind its steel frame).
func _kop_front(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, gl: float, edge: int, glass: bool) -> void:
	var length := a.distance_to(b)
	if length < 0.05:
		return
	var e := (b - a) / length
	var n := Vector3(out.x, 0.0, out.y)
	if glass:
		_mode = M_PAVILION
		_wall(a, b, y0, y1, out, KOP_LIT)
		_mode = M_STONE
		return
	var t := 0.0
	var k := 0
	while t < length - 0.01:
		var h := _kop_hash(float(edge), float(k))
		var w := minf(1.5 + 2.5 * h, length - t)
		if length - t - w < 1.0:
			w = length - t
		var col := Color(KOP_STRIPS[floori(_kop_hash(float(k), float(edge) + 0.5) * KOP_STRIPS.size()) % KOP_STRIPS.size()])
		if _kop_hash(float(k) * 1.7, float(edge)) < 0.08:
			col = KOP_COPPER
		_mode = M_STONE
		_wall(a + e * t, a + e * (t + w), y0, y1, out, col, t)
		# openings, 7 cm out of the strip
		var pick := _kop_hash(float(edge) + float(k) * 0.31, 9.0)
		var p := a + out * 0.07
		var lo := gl + 1.2
		var hi := y1 - 1.4
		if hi - lo > 3.0:
			_mode = M_PAVILION
			if pick < 0.22 and w >= 1.5:
				var c := t + w * 0.5
				_wall(p + e * (c - 0.3), p + e * (c + 0.3), lo, hi, out, KOP_WINDOW, c)
			elif pick < 0.34 and w >= 2.6:
				# a glazed bay over several storeys, leaning when the hash says so
				var lean := 0.0
				if _kop_hash(float(k), float(edge) * 2.3) < 0.5:
					lean = (w - 1.6) * 0.5 * (1.0 if k % 2 == 0 else -1.0)
				var s0 := t + 0.4 + maxf(-lean, 0.0)
				var s1 := t + w - 0.4 - maxf(lean, 0.0)
				var q0 := p + e * s0
				var q1 := p + e * s1
				var bot := lo + 1.0 if hi - lo > 6.0 else lo
				_quad(Vector3(q0.x, bot, q0.y), Vector3(q1.x, bot, q1.y),
						Vector3(q1.x + e.x * lean, hi, q1.y + e.y * lean), Vector3(q0.x + e.x * lean, hi, q0.y + e.y * lean), n,
						KOP_WINDOW, Vector2(s0, bot - _g), Vector2(s1, bot - _g), Vector2(s1 + lean, hi - _g), Vector2(s0 + lean, hi - _g), hi - _g)
			_mode = M_STONE
		t += w
		k += 1


## The south-east end's steel frame: posts every 4 m 2.4 m out of the glass, two galleries and
## two flights of stairs between them and the ground.
func _kop_frame(a: Vector2, b: Vector2, out: Vector2, street: float, top: float) -> void:
	var length := a.distance_to(b)
	var e := (b - a) / length
	var count := floori(length / 4.0)
	var levels: Array[float] = [street + 4.6, street + 9.0]
	for i in count + 1:
		var p := a + e * (length * float(i) / float(count)) + out * 2.4
		var gp: float = map.terrain_height(p.x, p.y)
		_beam(Vector3(p.x, gp - 0.3, p.y), Vector3(p.x, top - 0.6, p.y), 0.22, KOP_STEEL)
	for y: float in levels:
		var deck := PackedVector2Array([a + out * 0.1, b + out * 0.1, b + out * 2.6, a + out * 2.6])
		_prism(deck, y - 0.25, y, KOP_STEEL, KOP_STEEL.darkened(0.08), M_STONE, M_STONE)
	# the stairs: from the lower gallery down to the ground at the near end, then up to the upper
	for f in 2:
		var u0 := length * (0.18 if f == 0 else 0.6)
		var u1 := u0 + 9.0
		var y_lo: float = map.terrain_height((a + e * u0).x, (a + e * u0).y) if f == 0 else levels[0]
		var y_hi: float = levels[0] if f == 0 else levels[1]
		var s0 := a + e * u0 + out * 3.6
		var s1 := a + e * u1 + out * 3.6
		_beam(Vector3(s0.x, y_lo, s0.y), Vector3(s1.x, y_hi, s1.y), 1.2, KOP_STEEL)


## The dark strip cantilevered over the court on the planetarium's side: KOP_CANTI_DEPTH out of
## the block's longest front facing the planetarium, from KOP_CANTI over the street to the roof,
## kept clear of the planetarium.
func _kop_cantilever(body: PackedVector2Array, planet: PackedVector2Array, street: float, top: float) -> void:
	var pc := _centre(planet)
	var best := -1
	var best_len := 25.0
	for i in body.size():
		var a := body[i]
		var b := body[(i + 1) % body.size()]
		var mid := (a + b) * 0.5
		if mid.distance_to(pc) > 90.0 or _out(body, a, b).dot((pc - mid).normalized()) < 0.4:
			continue
		if a.distance_to(b) > best_len:
			best_len = a.distance_to(b)
			best = i
	if best < 0:
		return
	var a := body[best]
	var b := body[(best + 1) % body.size()]
	var e := (b - a) / a.distance_to(b)
	var out := _out(body, a, b)
	var strip := PackedVector2Array([a + e * 3.0, b - e * 3.0, b - e * 3.0 + out * KOP_CANTI_DEPTH, a + e * 3.0 + out * KOP_CANTI_DEPTH])
	var keep_off := Geometry2D.offset_polygon(_kop_convex(planet), 3.0)
	if not keep_off.is_empty():
		strip = _largest(Geometry2D.clip_polygons(strip, keep_off[0]))
	if strip.size() < 3 or absf(_area(strip)) < 60.0:
		return
	_prism(strip, street + KOP_CANTI, top, KOP_DARK, KOP_DARK.lightened(0.12), M_STONE, M_STONE)
	_kop_soffit(strip, street + KOP_CANTI, KOP_DARK.lightened(0.1))
	# a band of glass along its face
	var far0 := strip[0]
	var far1 := strip[1]
	var best_d := -INF
	for i in strip.size():
		var p0 := strip[i]
		var p1 := strip[(i + 1) % strip.size()]
		var d := ((p0 + p1) * 0.5 - a).dot(out)
		if d > best_d and p0.distance_to(p1) > 6.0:
			best_d = d
			far0 = p0
			far1 = p1
	var o := _out(strip, far0, far1)
	_mode = M_PAVILION
	_wall(far0 + o * 0.07, far1 + o * 0.07, street + KOP_CANTI + 1.2, top - 1.6, o, KOP_WINDOW)
	_mode = M_STONE


## The distance from p to a ring's edges.
func _kop_edge_dist(ring: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in ring.size():
		var c := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
		best = minf(best, c.distance_to(p))
	return best


## A flat ceiling (faces down) over a polygon: an overhang's underside.
func _kop_soffit(poly: PackedVector2Array, y: float, col: Color) -> void:
	for q in Geometry2D.merge_polygons(poly, PackedVector2Array()):
		if q.size() < 3 or Geometry2D.is_polygon_clockwise(q):
			continue
		var idx := Geometry2D.triangulate_polygon(q)
		for i in range(0, idx.size(), 3):
			var a := q[idx[i]]
			var b := q[idx[i + 1]]
			var c := q[idx[i + 2]]
			if absf((b - a).cross(c - a)) < 0.001:
				continue
			_tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.DOWN, col,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)


## The roof garden: the deck paved, a parapet, seven skylight craters, the teal glass strip on
## the city side of the southern half, a glass pavilion near the south end, and raised beds in
## mixed greens, ochre and dark shrub between meandering paths.
func _kop_roof(body: PackedVector2Array, top: float) -> void:
	_cap(body, top, KOP_DECK)
	_parapet(body, top, 0.9, KOP_PANEL)
	var inner := _largest(Geometry2D.offset_polygon(body, -3.0, Geometry2D.JOIN_MITER))
	if inner.size() < 3:
		return
	inner = _simplify(inner, 0.8)
	_o = _centre(body)
	_a = KOP_PATH_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)  # to the city side
	var half := 0.0
	for q in body:
		half = maxf(half, absf(_local(q).x))
	var keep: Array[PackedVector2Array] = []
	for c: Vector4 in KOP_CRATERS:
		var p := _a * c.x + _b * c.y
		var kind := int(c.w)
		if not _kop_inside(_circle(p, c.z + 0.5, 8), inner):
			continue
		if kind == 2:
			var head := _circle(p, c.z, 8)
			_prism(head, top, top + 2.6, KOP_CONCRETE.darkened(0.25), KOP_SKYGLASS, M_STONE, M_STONE)
		else:
			_kop_crater(p, c.z, top, kind == 1)
		keep.append(_circle(p, c.z + 0.8, 8))
	# the teal strip: along the city side of the southern half, 3 m in from the garden's edge
	var su := half * 0.42
	var sv := minf(_kop_span(inner, su - half * 0.26).y, _kop_span(inner, su + half * 0.26).y) - 4.8
	var strip := _rect(su, sv, half * 0.26, 1.8)
	if _kop_inside(strip, inner):
		_prism(strip, top, top + 0.9, KOP_TEAL.darkened(0.15), KOP_TEAL, M_STONE, M_GLASS_ROOF)
		keep.append(_rect(su, sv, half * 0.26 + 1.0, 2.8))
	# the glass pavilion near the south end
	var pu := half * 0.8
	var pspan := _kop_span(inner, pu)
	var pav := _rect(pu, (pspan.x + pspan.y) * 0.5, 3.5, 2.5)
	var clear := true
	for k0 in keep:
		if not Geometry2D.intersect_polygons(pav, k0).is_empty():
			clear = false
	if clear and _kop_inside(pav, inner):
		_prism(pav, top, top + 3.4, KOP_LIT, KOP_PANEL, M_PAVILION, M_STONE)
		keep.append(_rect(pu, (pspan.x + pspan.y) * 0.5, 4.5, 3.5))
	# meandering paths: two along the block, six across it
	var paths: Array[PackedVector2Array] = []
	for off: float in [-9.0, 8.0]:
		var line := PackedVector2Array()
		var u := -half - 10.0
		while u <= half + 10.0:
			line.append(_w(u, off + 4.0 * sin(u / 13.0 + off)))
			u += 5.0
		paths.append(line)
	for f: float in [-0.78, -0.45, -0.12, 0.2, 0.5, 0.78]:
		var cross := PackedVector2Array()
		var v := -45.0
		while v <= 45.0:
			cross.append(_w(f * half + 4.0 * sin(v / 8.0 + f * 7.0), v))
			v += 5.0
		paths.append(cross)
	var beds: Array[PackedVector2Array] = [inner]
	for path in paths:
		for shape in Geometry2D.offset_polyline(path, 1.3, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
			var next: Array[PackedVector2Array] = []
			for bed in beds:
				for piece in Geometry2D.clip_polygons(bed, shape):
					if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
						next.append(piece)
			beds = next
	var k := 0
	for bed in beds:
		var parts: Array[PackedVector2Array] = [bed]
		for kp in keep:
			var next: Array[PackedVector2Array] = []
			for part in parts:
				var cut := Geometry2D.clip_polygons(part, kp)
				var holed := false
				for c in cut:
					if Geometry2D.is_polygon_clockwise(c):
						holed = true
				if holed:
					next.append(part)  # wholly round it: the bed stays under (hidden by) the crater
				else:
					for c in cut:
						if c.size() >= 3:
							next.append(c)
			parts = next
		for part in parts:
			if absf(_area(part)) < 15.0:
				continue
			var col := Color(KOP_BEDS[floori(_kop_hash(float(k), 4.0) * KOP_BEDS.size()) % KOP_BEDS.size()])
			_prism(_simplify(part, 0.6), top, top + 0.4, KOP_KERB, col, M_STONE, M_STONE)
			k += 1


## Across the block at `u` (the roof frame): the run of `ring` there, as (lowest v, highest v),
## the longest one when the line crosses it more than once.
func _kop_span(ring: PackedVector2Array, u: float) -> Vector2:
	var best := Vector2.ZERO
	var start := INF
	var v := -60.0
	while v <= 60.0:
		var inside := Geometry2D.is_point_in_polygon(_w(u, v), ring)
		if inside and start == INF:
			start = v
		if (not inside or v >= 60.0) and start != INF:
			var end := v - 1.0 if not inside else v
			if end - start > best.y - best.x:
				best = Vector2(start, end)
			start = INF
		v += 1.0
	return best


## Whether every corner of `r` lies inside `ring`.
func _kop_inside(r: PackedVector2Array, ring: PackedVector2Array) -> bool:
	for q in r:
		if not Geometry2D.is_point_in_polygon(q, ring):
			return false
	return true


## A skylight crater: a raised hexagon of beige concrete sloping in to a flat rim round a dark
## glazed opening (or a glazed pyramid).
func _kop_crater(c: Vector2, r: float, top: float, pyramid: bool) -> void:
	var base := _circle(c, r, 6)
	var rim := _circle(c, r * 0.72, 6)
	var hole := _circle(c, r * 0.52, 6)
	_mode = M_STONE
	_kop_band(base, top, rim, top + 1.6, KOP_CONCRETE)
	_kop_band(rim, top + 1.6, hole, top + 1.6, KOP_CONCRETE.lightened(0.06))
	_mode = M_GLASS_ROOF
	if pyramid:
		_pyramid(hole, top + 1.6, top + 1.6 + r * 0.45, KOP_SKYGLASS.lightened(0.25))
	else:
		_cap(hole, top + 1.6, KOP_SKYGLASS)
	_mode = M_STONE


## The planetarium: a faceted copper-red drum on its outline (straightened, convex), the walls
## leaning in to a roof edge just over the block's roof, a chamfer, a flat ring round a glazed
## clerestory (glowing faintly at night), and a white dome about 17 m across.
func _kop_planet(planet: PackedVector2Array, block_top: float) -> void:
	var ring := _kop_chamfer(_kop_convex(_simplify(_kop_convex(planet), 3.0)), 0.18)
	_g = _ground_under(planet)
	var g := _g
	var c := _centre(ring)
	var mean := 0.0
	for q in ring:
		mean += q.distance_to(c)
	mean /= maxf(ring.size(), 1)
	var edge := block_top + KOP_PLANET_RISE
	var lean := _kop_scaled(ring, c, 0.95)
	var n := ring.size()
	_mode = M_STONE
	for i in n:
		var j := (i + 1) % n
		var p0 := Vector3(ring[i].x, g - 0.4, ring[i].y)
		var p1 := Vector3(ring[j].x, g - 0.4, ring[j].y)
		var p2 := Vector3(lean[j].x, edge, lean[j].y)
		var p3 := Vector3(lean[i].x, edge, lean[i].y)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		if Vector2(nrm.x, nrm.z).dot((ring[i] + ring[j]) * 0.5 - c) < 0.0:
			nrm = -nrm
		var col := KOP_COPPER if i % 2 == 0 else KOP_COPPER_DARK
		var l := ring[i].distance_to(ring[j])
		_quad(p0, p1, p2, p3, nrm, col.lightened(0.05 * _kop_hash(float(i), 3.0)),
				Vector2(0, -0.4), Vector2(l, -0.4), Vector2(l, edge - g), Vector2(0, edge - g), edge - g)
	var chamfer := _kop_scaled(ring, c, 0.84)
	_kop_band(lean, edge, chamfer, edge + 0.9, KOP_FACET)
	# a flat copper ring, then the dark clerestory ring (4.5 m wide, rising to the dome's foot,
	# glowing faintly at night), then the white dome, 17 m across
	var dome_s := 8.5 / maxf(mean, 1.0)
	var clere_s := 13.0 / maxf(mean, 1.0)
	var clere := _kop_scaled(ring, c, clere_s)
	_kop_band(chamfer, edge + 0.9, clere, edge + 0.9, KOP_COPPER_DARK.darkened(0.1))
	var foot := _kop_scaled(ring, c, dome_s)
	_mode = M_PAVILION
	_kop_band(clere, edge + 0.9, foot, edge + 2.0, KOP_SKYGLASS)
	_mode = M_STONE
	var y := edge + 2.0
	var prev := foot
	var prev_y := y
	for step: Vector2 in [Vector2(0.87, 2.4), Vector2(0.6, 4.2), Vector2(0.3, 5.1)]:
		var cur := _kop_scaled(ring, c, dome_s * step.x)
		_kop_band(prev, prev_y, cur, y + step.y, KOP_DOME)
		prev = cur
		prev_y = y + step.y
	_pyramid(prev, prev_y, y + 5.5, KOP_DOME)
	_collide(planet)


## A convex ring with every corner cut: each corner becomes two, `share` of the way along its
## two edges (the planetarium's chamfered facets: five corners become ten sides).
func _kop_chamfer(ring: PackedVector2Array, share: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := ring.size()
	for i in n:
		var prev := ring[(i + n - 1) % n]
		var cur := ring[i]
		var next := ring[(i + 1) % n]
		out.append(cur.lerp(prev, share))
		out.append(cur.lerp(next, share))
	return out


## A ring scaled towards c.
func _kop_scaled(ring: PackedVector2Array, c: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in ring:
		out.append(c + (q - c) * s)
	return out


## The faces between two rings of the same corners (each facing up): a chamfer, a flat ring, a
## dome's band.
func _kop_band(r0: PackedVector2Array, y0: float, r1: PackedVector2Array, y1: float, col: Color) -> void:
	var n := r0.size()
	for i in n:
		var j := (i + 1) % n
		var a := Vector3(r0[i].x, y0, r0[i].y)
		var b := Vector3(r0[j].x, y0, r0[j].y)
		var c := Vector3(r1[j].x, y1, r1[j].y)
		var d := Vector3(r1[i].x, y1, r1[i].y)
		_kop_face(a, b, c, col)
		_kop_face(a, c, d, col)


## A triangle facing up.
func _kop_face(a: Vector3, b: Vector3, d: Vector3, col: Color) -> void:
	var nrm := (b - a).cross(d - a)
	if nrm.length_squared() < 1e-8:
		return
	nrm = nrm.normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	_tri(a, b, d, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A ring's convex hull, open and counter-clockwise like the outlines.
func _kop_convex(q: PackedVector2Array) -> PackedVector2Array:
	var h := Geometry2D.convex_hull(q)
	if h.size() > 1 and h[0].is_equal_approx(h[-1]):
		h.resize(h.size() - 1)
	return h


## A steady pseudo-random number in [0, 1) (the strips, the openings, the beds).
func _kop_hash(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


# --- Zamek Ostrogskich and the Chopin Institute (Tamka 41) -----------------------------------

## The Ostrogski Castle (Zamek Ostrogskich; a 17th-century palace complex above the Vistula
## escarpment, rebuilt after 1945) and, across its courtyard, the block of the Fryderyk Chopin
## Institute next door: a model instead of two mapped boxes. White plaster walls with grey stone
## quoins over a stone plinth, a cornice, orange tiled hipped roofs with dormers, pedimented middle
## bays with a statue, the red-brick bastion towards Tamka; the Institute a modern stone and glass
## block. Spec docs/landmarks/specs/ostrogski.md; rebuilt from F's photos 2026-11-09.
## Frames: the castle's origin is its outline's centre, u east-north-east, +v south-south-east
## (the long way); the museum's is its outline's centre, u west, +v north.
const OSTROG_O := Vector2(-70.3, -274.2)
const OSTROG_A := Vector2(0.9472, -0.3206)
const CHOPIN_O := Vector2(-112.86, -268.13)
const CHOPIN_A := Vector2(-0.9877, 0.1565)
const OSTROG_WALL := Color("#ece8dc")
const OSTROG_TRIM := Color("#f4f1ea")
const OSTROG_BASE := Color("#b9b4a8")
const OSTROG_ROOF := Color("#a8705a")
## F's photos (2026-11-09, Mac powisle/M01-M05, B13): grey stone quoins at the corners and the
## middle bays, the red-brick bastion under the castle on the Tamka side, and the Institute next
## door a modern block (a stone base and a blue-green glass tower), no turret.
const OSTROG_QUOIN := Color("#c4beb1")
const OSTROG_BRICK := Color("#a1503a")
const CHOPIN_GLASS := Color("#7fb3b0")
const CHOPIN_STONE := Color("#d8d4ca")
const CHOPIN_TOP := 26.0
const OSTROG_DARK := Color("#3a3f42")
const OSTROG_GOLD := Color("#c9a24a")
const OSTROG_EAVE := 10.0


func _find_ostrogski() -> void:
	var castle := _landmark("Zamek Ostrogskich")
	var museum := _landmark("Narodowy Instytut Fryderyka Chopina")
	if castle.size() >= 3 and museum.size() >= 3:
		_add_site("ostrogski", [castle, museum])


func _build_ostrogski(site: Dictionary) -> void:
	var zone: Array = site["zone"]
	var castle: PackedVector2Array = zone[0]
	var museum: PackedVector2Array = zone[1]
	# --- the castle
	_o = OSTROG_O
	_a = OSTROG_A.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(castle)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_body(castle, g, OSTROG_EAVE)
	_hip(0.0, 0.0, 8.2, 12.9, g + OSTROG_EAVE + 0.6, 6.0, OSTROG_ROOF)
	# cross gables on the middle bays, both faces
	for sgn: float in [-1.0, 1.0]:
		_gable(sgn * 7.95, 0.0, 0.0, 5.7, g + OSTROG_EAVE + 0.6, 4.6, OSTROG_WALL, OSTROG_ROOF, false)
		_mode = M_GLASS
		_wall(_w(sgn * 7.97, -1.4), _w(sgn * 7.97, 1.4), g + OSTROG_EAVE + 1.2, g + OSTROG_EAVE + 3.6, _a * sgn, OSTROG_DARK)
		_mode = M_STONE
	# dormers on the wings' long slopes
	for sgn: float in [-1.0, 1.0]:
		for v: float in [-9.5, -7.2, 7.2, 9.5]:
			_dormer(sgn, 5.6, v, g + OSTROG_EAVE + 0.6, 8.2, 12.9, 6.0)
	# grey stone quoins at the corners and at the middle bays' edges, a statue on each pediment
	for cu: float in [-8.0, 8.0]:
		for cv: float in [-12.7, -5.9, 5.9, 12.7]:
			_lbox(cu, cv, 0.35, 0.35, g - 1.0, g + OSTROG_EAVE, OSTROG_QUOIN, M_STONE, OSTROG_QUOIN)
		_lbox(cu * 1.02, 0.0, 0.35, 0.35, g + OSTROG_EAVE + 5.2, g + OSTROG_EAVE + 6.6, OSTROG_QUOIN, M_STONE, OSTROG_QUOIN)
	# the red-brick bastion under the castle where the ground drops to Tamka (the -v side)
	var low := _ground_under(_rect(0.0, -15.5, 12.0, 1.0))
	if g - low > 1.2:
		_lbox(0.0, -13.8, 13.0, 1.0, low - 0.5, g + 0.3, OSTROG_BRICK, M_STONE, OSTROG_TRIM)
		_lbox(0.0, -14.7, 13.0, 0.12, g + 0.3, g + 1.2, OSTROG_TRIM, M_STONE, OSTROG_TRIM)
		_collide(_rect(0.0, -13.8, 13.0, 1.0))
	# two chimneys on the ridge
	for v: float in [-3.2, 3.2]:
		_lbox(0.0, v, 0.55, 0.55, g + 15.0, g + 18.4, OSTROG_BASE.lightened(0.1), M_STONE, OSTROG_BASE)
	_collide(castle)
	# --- the Institute: a stone base, a blue-green glass tower over it, a flat roof
	_o = CHOPIN_O
	_a = CHOPIN_A.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(museum)
	g = _g
	_prism(museum, g - 1.0, g + 6.0, CHOPIN_STONE, CHOPIN_STONE.darkened(0.1), M_STONE, M_STONE)
	var tower := _largest(Geometry2D.offset_polygon(museum, -1.2, Geometry2D.JOIN_MITER))
	if tower.size() >= 3:
		_mode = M_GLASS
		_prism(tower, g + 6.0, g + CHOPIN_TOP, CHOPIN_GLASS, none, M_GLASS, M_STONE)
		_mode = M_STONE
		_parapet(tower, g + CHOPIN_TOP, 0.6, CHOPIN_STONE)
		_prism(tower, g + CHOPIN_TOP - 0.2, g + CHOPIN_TOP, CHOPIN_STONE, OSTROG_BASE, M_STONE, M_STONE)
	_collide(museum)


## The walls both blocks share: a stone plinth, the plastered storeys (M_MONUMENT draws the
## tall windows) and a cornice, round a mapped outline.
func _body(ring: PackedVector2Array, g: float, eave: float) -> void:
	_prism(ring, g - 1.0, g + 1.0, OSTROG_BASE, OSTROG_BASE, M_STONE, M_STONE)
	_prism(ring, g + 1.0, g + eave, OSTROG_WALL, Color(0, 0, 0, 0), M_MONUMENT)
	var cornice := _largest(Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER))
	_prism(cornice, g + eave, g + eave + 0.6, OSTROG_TRIM, OSTROG_ROOF.darkened(0.1), M_STONE, M_STONE)


## A dormer on a hipped roof's long slope (the slope on side `sgn` along u): a small box with a
## dark window and a gable roof. `y` is the eaves, `hu`/`hv` the roof's half sizes, `rise` its height.
func _dormer(sgn: float, u: float, v: float, y: float, hu: float, hv: float, rise: float) -> void:
	var short := minf(hu, hv) - 0.15
	var ry := y + rise * minf(hu - u, hv - absf(v)) / short
	var uf := u + 0.6
	_lbox(sgn * u, v, 0.6, 0.55, ry - 0.9, ry + 1.5, OSTROG_WALL, M_STONE, OSTROG_WALL)
	_mode = M_GLASS
	_wall(_w(sgn * (uf + 0.02), v - 0.3), _w(sgn * (uf + 0.02), v + 0.3), ry - 0.2, ry + 1.2, _a * sgn, OSTROG_DARK)
	_mode = M_STONE
	_gable(sgn * (uf + 0.05), sgn * (u - 0.6), v, 0.62, ry + 1.5, 0.8, OSTROG_WALL, OSTROG_ROOF)
