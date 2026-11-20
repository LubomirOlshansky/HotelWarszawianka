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

const ATE_AT := Vector2(581.0, -382.0)
## The Jaracza front: u runs from its south-west end to its north-east end, +v out to the street.
const ATE_P0 := Vector2(579.9, -370.5)
const ATE_P1 := Vector2(592.1, -386.2)
const ATE_CORNICE := 19.4
const ATE_TOP := 20.8
const ATE_WALL := Color("#a8a8a2")
const ATE_TRIM := Color("#d2cec2")
const ATE_PLINTH := Color("#98a7ad")
const ATE_ROOF := Color("#6e7072")
const ATE_BROWN := Color("#6a4b38")
## The portico (tamka.gd) stands on the middle of the front: windows keep out of u 4.4 to 15.5.
const ATE_PORTICO_HW := 5.4


func _find_ateneum() -> void:
	var q := _tallest_at(ATE_AT)
	if q.size() < 4:
		return
	_add_site("ateneum", [_largest(Geometry2D.offset_polygon(q, 0.4, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "ateneum":
		sites[-1]["ring"] = _simplify(q, 0.3)
		sites[-1]["raw"] = q


func _build_ateneum(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	# body: the whole house to the cornice, a flat roof; the cornice and plinth run round all faces
	_prism(ring, g - 1.5, g + ATE_CORNICE, ATE_WALL, ATE_ROOF, M_STONE, M_STONE)
	kit_cornice_ring(ring, g + ATE_CORNICE, ATE_TRIM, 0.5, 0.9)
	kit_ledge_ring(ring, g - 0.2, 1.5, ATE_PLINTH, 0.1)
	var inner := _largest(Geometry2D.offset_polygon(ring, -0.2, Geometry2D.JOIN_MITER))
	if inner.size() >= 3:
		_parapet(inner, g + ATE_CORNICE, ATE_TOP - ATE_CORNICE, ATE_WALL.lightened(0.06))
	# the Jaracza front
	var width := kit_front(ATE_P0, ATE_P1)
	kit_face(0.0)
	var mid := width * 0.5
	var side_axes: Array[float] = [2.4, width - 2.4]
	kit_ledge(0.0, width, g + 5.4, 0.3, ATE_TRIM, 0.22)
	# ground floor: a tall framed window each side of the portico
	for u: float in side_axes:
		kit_window(u, g + 1.7, 2.4, Win.FRAMED, ATE_TRIM, PAL_GLASS_DARK, 0.7)
	# first floor: a round window each side over it
	for u: float in side_axes:
		_ate_oculus(u, g + 7.3)
	# the three upper floors on five axes; the middle axis starts over the portico's crest
	var axes: Array[float] = [2.4, mid - 3.75, mid, mid + 3.75, width - 2.4]
	for k in axes.size():
		var u := axes[k]
		var middle := absf(u - mid) < ATE_PORTICO_HW
		var low := g + (10.1 if middle else 9.5)
		kit_window(u, low, 2.0, Win.SILL_HEAD, ATE_TRIM, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 13.2, 2.0, Win.SILL_HEAD, ATE_TRIM, PAL_GLASS_DARK, 0.62)
		kit_window(u, g + 16.5, 1.8, Win.SILL, ATE_TRIM, PAL_GLASS_DARK, 0.62)
	# the stage house behind, over the roof, and two plant boxes
	var keep := _mode
	_lbox(mid, -8.2, 6.0, 4.6, g + ATE_CORNICE, g + ATE_TOP + 2.4, ATE_WALL.darkened(0.04), M_STONE, ATE_ROOF)
	_lbox(mid + 2.5, -3.2, 1.3, 1.1, g + ATE_CORNICE, g + ATE_TOP + 0.9, PAL_GREY_STONE, M_STONE, ATE_ROOF)
	_lbox(mid - 6.0, -4.0, 1.1, 1.8, g + ATE_CORNICE, g + ATE_TOP + 0.6, PAL_ALUMINIUM, M_STONE, ATE_ROOF)
	_mode = keep
	_collide_raw(site)


## A round window on the front at u, its centre y (absolute): a pale surround and a lit pane.
func _ate_oculus(u: float, y: float) -> void:
	var c := _w(u, 0.0)
	var n := Vector3(_b.x, 0.0, _b.y)
	var keep := _mode
	_mode = M_STONE
	_disc(Vector3(c.x + _b.x * 0.04, y, c.y + _b.y * 0.04), n, 1.15, 14, ATE_TRIM)
	_mode = _lit(u, y)
	_disc(Vector3(c.x + _b.x * 0.09, y, c.y + _b.y * 0.09), n, 0.88, 14, PAL_GLASS_DARK)
	_mode = keep


# --- Lipowa 1A ---------------------------------------------------------------------------

const LP_AT := Vector2(111.0, -889.0)
## The front on Lipowa: u from its north-east end to its south-west end, +v out across the street.
const LP_P0 := Vector2(117.4, -900.4)
const LP_P1 := Vector2(97.2, -890.0)
const LP_BASE := 10.8     # the three white floors
const LP_BODY := 22.6     # to the roof
const LP_RIM := 0.9       # the teal rim over it
const LP_PLASTER := Color("#e4dfd0")
const LP_TEAL := Color("#4f9a94")
const LP_GLASS := Color("#34424a")
const LP_COPPER := Color("#78b5a6")
const LP_SLAB := Color("#cfcdc5")
const LP_DECK := Color("#6d6040")
const LP_ROOF_BOX := Color("#a3a5a4")


func _find_lipowa1a() -> void:
	var q := _tallest_at(LP_AT)
	if q.size() < 4:
		return
	_add_site("lipowa1a", [_largest(Geometry2D.offset_polygon(q, 0.4, Geometry2D.JOIN_MITER))])
	if not sites.is_empty() and sites[-1]["key"] == "lipowa1a":
		sites[-1]["ring"] = _simplify(q, 0.6)
		sites[-1]["raw"] = q


func _build_lipowa1a(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	_mode = M_STONE
	_prism(ring, g - 1.5, g + LP_BODY, LP_PLASTER, LP_DECK, M_STONE, M_STONE)
	# the teal rim round the roof, a slab over the white base on every face
	kit_ledge_ring(ring, g + LP_BODY, LP_RIM, LP_COPPER, 0.12)
	kit_ledge_ring(ring, g + LP_BASE - 0.15, 0.3, LP_SLAB, 0.1)
	# the other faces: small windows, a row a floor, white frames
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 3.0:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		if out.dot(Vector2(-0.458, -0.889)) > 0.85:
			continue  # the Lipowa front has its own windows
		var n := floori((length - 1.0) / 3.0)
		for j in n:
			var m := a + e * ((j + 0.5) * length / n)
			for k in 3:
				var y := g + 1.4 + 3.1 * k
				_framed(m - e * 0.55, m + e * 0.55, y, y + 1.35, out, Color("#f0eee8"), LP_GLASS, float(i) * 3.7 + float(j) * 5.3 + float(k) * 11.0)
		# the upper four floors on these faces: patina copper panels, two or three small windows
		_mode = M_STONE
		_wall(a + out * 0.1, b + out * 0.1, g + LP_BASE, g + LP_BODY, out, LP_COPPER, 0.0)
		for j in maxi(1, floori(length / 8.0)):
			var m2 := a + e * ((j + 0.5) * length / maxi(1, floori(length / 8.0)))
			_framed(m2 - e * 0.5, m2 + e * 0.5, g + LP_BASE + 3.4 + 3.0 * (j % 2), g + LP_BASE + 4.9 + 3.0 * (j % 2), out, LP_COPPER.darkened(0.25), LP_GLASS, float(i) * 3.1 + float(j) * 7.7)
	# the Lipowa front
	var width := kit_front(LP_P0, LP_P1)
	kit_face(0.0)
	# base: three floors of small windows on five axes, the entrance in the middle
	var axes := _spread(1.3, width - 1.3, 5)
	for k in 3:
		var y := g + 1.5 + 3.1 * k
		for u: float in axes:
			if k == 0 and absf(u - width * 0.5) < 1.0:
				continue
			kit_window(u, y, 1.4, Win.SILL, Color("#f0eee8"), PAL_GLASS_DARK, 0.5)
	kit_door(width * 0.5, g + 0.0, 2.5, 0.9, LP_SLAB, PAL_DARK_DOOR, false)
	# upper four floors: a dark glass wall set 0.15 m out, balcony slabs, teal fins
	var keep := _mode
	_mode = M_SKIN + float(S_RIBBON) / 16.0
	_wall(_w(0.9, 0.15), _w(width - 0.9, 0.15), g + LP_BASE, g + LP_BODY - 0.1, _b, LP_GLASS, 0.0)
	_mode = keep
	for k in 4:
		var y := g + LP_BASE + 3.0 * k
		_kbox(0.5, width - 0.5, 0.0, 1.5, y - 0.05, y + 0.2, LP_SLAB.darkened(0.3))
		_kbox(0.5, width - 0.5, 1.4, 1.5, y + 0.2, y + 1.05, Color("#9fc3c4"))
	for u: float in [0.6, width * 0.25, width * 0.5, width * 0.75, width - 0.6]:
		_kbox(u - 0.25, u + 0.25, 0.0, 1.6, g + LP_BASE - 0.1, g + LP_BODY, LP_COPPER)
	# roof terrace: plant boxes, a lift head and a small glass pavilion
	for p: Vector3 in [Vector3(4.0, -4.0, 1.6), Vector3(9.0, -5.0, 1.4), Vector3(14.0, -4.0, 1.2), Vector3(17.5, -7.0, 1.5)]:
		_lbox(p.x, p.y, 1.4, 1.0, g + LP_BODY, g + LP_BODY + p.z, LP_ROOF_BOX, M_STONE, LP_ROOF_BOX.lightened(0.05))
	_lbox(8.5, -9.5, 1.6, 1.6, g + LP_BODY, g + LP_BODY + 2.4, LP_PLASTER, M_STONE, LP_ROOF_BOX)
	_lbox(14.0, -10.5, 1.8, 1.2, g + LP_BODY, g + LP_BODY + 2.5, Color("#8fb3b0"), M_PAVILION, LP_ROOF_BOX)
	_collide_raw(site)
